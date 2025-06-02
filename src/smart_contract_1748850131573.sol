Okay, here is a Solidity smart contract concept for a "Sentient Artifact Protocol". This contract manages unique NFTs (the "Artifacts") that have dynamic traits and energy levels, evolving based on user interactions and time. It incorporates concepts like dynamic metadata, timed state decay, user challenges with probabilistic outcomes, role-based access control, and controlled evolution triggers, aiming for a unique and somewhat complex on-chain system.

It avoids direct duplication of standard OpenZeppelin contracts beyond inheriting core ERC721, Ownable, and Pausable for foundational safety and standards compliance, focusing on custom logic for the "sentient" behavior.

---

## Sentient Artifact Protocol - Outline

**Purpose:** To manage unique, non-fungible tokens (Artifacts) that possess dynamic traits and energy levels. Artifacts evolve over time and through user interactions, reflecting their on-chain history.

**Key Concepts:**
*   **ERC-721 Standard:** Artifacts are represented as NFTs.
*   **Dynamic State:** Each Artifact has a state struct containing energy level, traits, generation, last interaction time, last decay time, etc.
*   **Energy Mechanism:** Artifacts gain energy from deposits and lose it over time (decay). Energy fuels evolution and certain interactions.
*   **Traits:** Numerical or categorical attributes that define an Artifact's characteristics and can change based on interactions, energy, and evolution.
*   **Evolution:** Artifacts can advance through "Generations" when specific criteria (energy, traits, time) are met, potentially unlocking new features or changing metadata significantly.
*   **User Interactions:** Users can deposit energy, withdraw deposits, challenge Artifacts (probabilistic outcomes), and 'influence' traits.
*   **Dynamic Metadata:** `tokenURI` reflects the current state and traits of an Artifact, changing as it evolves or state updates.
*   **Access Control:** Ownership for core management functions, plus a custom role for certain interaction types (e.g., 'Influencers').
*   **Pausable:** Ability to pause interactions in case of issues.

**Modules:**
1.  **ERC721 Core:** Standard NFT functionality (minting, transfer, ownership).
2.  **Artifact State Management:** Structs and mappings to store artifact data.
3.  **Energy & Time:** Logic for energy deposit, withdrawal, decay, and time tracking.
4.  **Traits & Evolution:** Logic for trait storage, updates, influence mechanics, and evolution trigger checks.
5.  **Interactions:** Functions for user actions like challenging.
6.  **Metadata:** Dynamic `tokenURI` generation.
7.  **Access Control & Governance:** Owner functions, Pausable, Custom Roles.
8.  **Fees & Rewards:** Handling protocol fees and distributing interaction rewards.

---

## Function Summary (26 Public/External Functions)

1.  `constructor`: Initializes the contract, setting name, symbol, base URI, owner, and initial parameters.
2.  `pauseInteractions`: Owner can pause user interactions (deposit, challenge, influence).
3.  `unpauseInteractions`: Owner can unpause interactions.
4.  `mintArtifact`: Mints a new Artifact NFT, initializing its state and traits. Callable by owner or authorized minter role (simplified to owner for this example).
5.  `depositEnergy`: Allows a user to deposit ETH into an Artifact, increasing its energy level. Staked ETH is tracked per user per artifact.
6.  `withdrawEnergy`: Allows a user to withdraw their staked ETH from an Artifact, decreasing its energy.
7.  `decayEnergy`: Anyone can call this to trigger energy decay for a specific Artifact if enough time has passed since the last decay.
8.  `influenceArtifact`: Allows a user (possibly with a specific role or cost) to attempt to influence a specific trait of an Artifact. Outcome might be probabilistic.
9.  `challengeArtifact`: A user pays a fee to challenge an Artifact. Outcome depends on Artifact traits and randomness. Can result in winning a reward or losing the fee. Increases artifact energy upon challenge.
10. `claimInteractionReward`: Users can claim rewards they have earned from successful challenges or other interactions.
11. `triggerEvolutionCheck`: Anyone can call this to check if an Artifact meets the criteria (energy, traits, time) to evolve to the next generation. If criteria met, triggers internal evolution logic.
12. `reactToExternalEvent`: Allows an authorized address (e.g., an oracle or admin) to feed simulated external data that can influence an Artifact's traits or energy.
13. `setTraitWeights`: Owner sets the influence weights for different actions on different traits.
14. `setEnergyDecayRate`: Owner sets how much energy decays per unit of time.
15. `setEvolutionThresholds`: Owner sets the energy/trait thresholds required for evolution.
16. `setBaseMetadataURI`: Owner sets the base URI for the dynamic `tokenURI`.
17. `withdrawProtocolFees`: Owner collects accumulated protocol fees (e.g., from challenge losses).
18. `grantInfluencerRole`: Owner grants the INFLUENCER_ROLE to an address.
19. `revokeInfluencerRole`: Owner revokes the INFLUENCER_ROLE from an address.
20. `isInfluencer`: Public view function to check if an address has the INFLUENCER_ROLE.
21. `getArtifactState`: Public view function to retrieve the full current state of a specific Artifact.
22. `getArtifactTraits`: Public view function to retrieve just the traits of a specific Artifact.
23. `getArtifactEnergy`: Public view function to retrieve just the energy of a specific Artifact.
24. `getTraitDefinition`: Public view function mapping a trait index to its description.
25. `getPossibleTraitOutcomes`: Public view function mapping a trait index to its possible value range or categories.
26. `tokenURI`: (Override ERC721) Public view function to get the dynamic metadata URI for an Artifact, based on its current state.

*(Note: Standard ERC721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., are also public/external but are part of the inherited standard and not counted towards the 20+ custom functions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- Sentient Artifact Protocol - Outline & Function Summary Above ---

contract SentientArtifactProtocol is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Constants & Configuration ---
    uint256 public constant MAX_ENERGY = 100000 ether; // Cap artifact energy level
    uint256 public constant MIN_ENERGY_FOR_EVOLUTION = 100 ether; // Minimum energy needed to trigger evolution check
    uint256 public constant ENERGY_DECAY_RATE_PER_SECOND = 1 ether / (30 days); // Decay 1 ether per 30 days
    uint256 public constant EVOLUTION_COOLDOWN = 7 days; // Time required between evolutions
    uint256 public constant CHALLENGE_PROTOCOL_FEE_BPS = 500; // 5% protocol fee on challenge stake (Basis Points)

    // --- Custom Roles (Simplified for example) ---
    bytes32 public constant INFLUENCER_ROLE = keccak256("INFLUENCER_ROLE");
    mapping(address => bool) private _hasInfluencerRole;

    // --- Structs ---

    // Represents the dynamic state of an individual artifact NFT
    struct ArtifactState {
        uint256 energy;
        uint256 lastEnergyUpdateTimestamp; // Timestamp when energy was last increased or decreased (decay/deposit)
        uint256 lastEvolutionTimestamp;
        uint256 generation;
        uint256[] traits; // Array of trait values (e.g., [strength, intelligence, agility])
        mapping(address => uint256) stakedEnergy; // Energy deposited by specific users
        uint256 totalStakedEnergy; // Sum of all user staked energy (should equal 'energy' if no decay/burning)
    }

    // Defines a specific trait
    struct TraitDefinition {
        string name;
        string description;
        uint256 minValue;
        uint256 maxValue; // For numerical traits
        string[] possibleCategories; // For categorical traits
        bool isCategorical;
    }

    // Defines how different actions influence traits
    struct TraitInfluenceWeight {
        uint256 energyCost; // Cost in energy to influence
        uint256 ethCost; // Cost in ETH to influence
        int256 baseInfluenceAmount; // Base change amount (can be positive or negative)
        uint256 randomInfluenceRange; // Max random variance +/-
        uint256 influencerRoleBonus; // Bonus influence if caller has the role
    }

    // --- State Variables ---
    mapping(uint256 => ArtifactState) private _artifactStates;
    string private _baseMetadataURI;
    mapping(uint256 => TraitDefinition) public traitDefinitions; // Mapping trait index to definition
    mapping(uint256 => TraitInfluenceWeight) public traitInfluenceWeights; // Mapping trait index to influence weights
    uint256 private _nextTraitIndex = 0;
    uint256 public protocolFeesCollected;

    // --- Events ---
    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event EnergyDeposited(uint256 indexed tokenId, address indexed depositor, uint256 amount, uint256 newEnergy);
    event EnergyWithdrawn(uint256 indexed tokenId, address indexed withdrawer, uint256 amount, uint256 newEnergy);
    event EnergyDecayed(uint256 indexed tokenId, uint256 decayedAmount, uint256 newEnergy);
    event TraitsInfluenced(uint256 indexed tokenId, address indexed influencer, uint256 traitIndex, int256 influenceAmount, uint256 newTraitValue);
    event ArtifactChallenged(uint256 indexed tokenId, address indexed challenger, uint256 stake, bool won, uint256 reward);
    event InteractionRewardClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);
    event ArtifactEvolved(uint256 indexed tokenId, uint256 newGeneration, uint256 energyAtEvolution);
    event ExternalEventReacted(uint256 indexed tokenId, bytes dataIdentifier); // Simplified event
    event InfluencerRoleGranted(address indexed account);
    event InfluencerRoleRevoked(address indexed account);
    event ProtocolFeesWithdrawn(address indexed recipient, uint252 amount);

    // --- Modifiers ---
    modifier onlyInfluencer() {
        require(_hasInfluencerRole[msg.sender], "SAP: Caller is not an influencer");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets initial owner to deployer
        Pausable()
    {
        _baseMetadataURI = baseURI;

        // --- Define initial traits (Example Traits) ---
        // Add Trait 0: Resilience (Numerical)
        _nextTraitIndex = 0;
        traitDefinitions[_nextTraitIndex] = TraitDefinition({
            name: "Resilience",
            description: "Resistance to external influence and decay.",
            minValue: 0,
            maxValue: 1000,
            possibleCategories: new string[](0), // Not categorical
            isCategorical: false
        });
        traitInfluenceWeights[_nextTraitIndex] = TraitInfluenceWeight({
            energyCost: 10 ether,
            ethCost: 0.01 ether,
            baseInfluenceAmount: 5,
            randomInfluenceRange: 10,
            influencerRoleBonus: 2 // Bonus points if influencer
        });
        _nextTraitIndex++;

        // Add Trait 1: Affinity (Numerical)
        traitDefinitions[_nextTraitIndex] = TraitDefinition({
            name: "Affinity",
            description: "Attractiveness for positive interactions.",
            minValue: 0,
            maxValue: 1000,
            possibleCategories: new string[](0),
            isCategorical: false
        });
         traitInfluenceWeights[_nextTraitIndex] = TraitInfluenceWeight({
            energyCost: 5 ether,
            ethCost: 0.005 ether,
            baseInfluenceAmount: 10,
            randomInfluenceRange: 15,
            influencerRoleBonus: 5
        });
        _nextTraitIndex++;

         // Add Trait 2: Aura (Categorical)
        traitDefinitions[_nextTraitIndex] = TraitDefinition({
            name: "Aura",
            description: "Mystical energy signature.",
            minValue: 0, // Index of category
            maxValue: 2, // Index of category
            possibleCategories: new string[]("Neutral", "Positive", "Negative"),
            isCategorical: true
        });
        traitInfluenceWeights[_nextTraitIndex] = TraitInfluenceWeight({
            energyCost: 20 ether,
            ethCost: 0.02 ether,
            baseInfluenceAmount: 0, // Categorical change needs specific logic
            randomInfluenceRange: 0,
            influencerRoleBonus: 0
        });
        _nextTraitIndex++;
         // Add more traits as needed...
    }

    // --- Core ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        ArtifactState storage artifact = _artifactStates[tokenId];
        // Construct dynamic URI based on artifact state
        // Example: baseURI + generation + / + tokenId + .json
        // A separate service/gateway would serve the actual JSON metadata based on this URI structure
        return string(abi.encodePacked(
            _baseMetadataURI,
            Strings.toString(artifact.generation),
            "/",
            Strings.toString(tokenId),
            ".json"
        ));
    }

    // The following ERC721 functions are inherited:
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // transferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // supportsInterface(bytes4 interfaceId) - Handled by ERC721

    // --- Custom Protocol Functions ---

    /// @notice Owner function to pause interaction features
    function pauseInteractions() public onlyOwner {
        _pause();
    }

    /// @notice Owner function to unpause interaction features
    function unpauseInteractions() public onlyOwner {
        _unpause();
    }

    /// @notice Mints a new Artifact NFT and initializes its state
    /// @param initialTraits Initial values for the artifact's traits. Must match the number of defined traits.
    function mintArtifact(uint256[] memory initialTraits) public onlyOwner { // Simplified to onlyOwner, could be an address with a minter role
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        require(initialTraits.length == _nextTraitIndex, "SAP: Initial traits count mismatch");

        // Validate initial trait values against definitions
        for (uint256 i = 0; i < initialTraits.length; i++) {
            TraitDefinition storage traitDef = traitDefinitions[i];
             if (traitDef.isCategorical) {
                 require(initialTraits[i] < traitDef.possibleCategories.length, "SAP: Invalid initial categorical trait value");
             } else {
                 require(initialTraits[i] >= traitDef.minValue && initialTraits[i] <= traitDef.maxValue, "SAP: Invalid initial numerical trait value");
             }
        }

        _safeMint(msg.sender, newTokenId); // Mints to the owner
        _artifactStates[newTokenId] = ArtifactState({
            energy: 0,
            lastEnergyUpdateTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp, // Can evolve immediately after mint if criteria met (unlikely)
            generation: 0,
            traits: initialTraits,
            totalStakedEnergy: 0
        });
        // stakedEnergy mapping is initialized to empty

        emit ArtifactMinted(newTokenId, msg.sender, 0);
    }

    /// @notice Allows a user to deposit ETH into an Artifact to increase its energy
    /// @param tokenId The ID of the artifact to deposit into.
    function depositEnergy(uint256 tokenId) external payable nonReentrant whenNotPaused {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        require(msg.value > 0, "SAP: Must deposit non-zero ETH");

        ArtifactState storage artifact = _artifactStates[tokenId];

        // Apply decay before adding new energy
        _applyEnergyDecay(tokenId);

        uint256 energyToAdd = msg.value; // Simple 1:1 ETH to Energy conversion (example)
        uint256 oldEnergy = artifact.energy;
        artifact.energy = Math.min(oldEnergy + energyToAdd, MAX_ENERGY);
        artifact.lastEnergyUpdateTimestamp = block.timestamp;

        artifact.stakedEnergy[msg.sender] += msg.value;
        artifact.totalStakedEnergy += msg.value;

        emit EnergyDeposited(tokenId, msg.sender, msg.value, artifact.energy);
    }

    /// @notice Allows a user to withdraw their staked ETH from an Artifact
    /// @param tokenId The ID of the artifact to withdraw from.
    /// @param amount The amount of ETH to withdraw.
    function withdrawEnergy(uint256 tokenId, uint256 amount) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        ArtifactState storage artifact = _artifactStates[tokenId];
        require(amount > 0, "SAP: Must withdraw non-zero ETH");
        require(artifact.stakedEnergy[msg.sender] >= amount, "SAP: Not enough staked energy");

        // Apply decay before withdrawal to get accurate current energy state
        _applyEnergyDecay(tokenId);

        // Decrease user's staked amount
        artifact.stakedEnergy[msg.sender] -= amount;
        artifact.totalStakedEnergy -= amount;

        // Decrease artifact energy. Note: This assumes staked energy directly maps to artifact energy.
        // If decay happens *before* withdrawal calculation, the artifact's energy might be less than totalStakedEnergy.
        // We only decrease the artifact's energy by the *withdrawn* amount relative to the *current* energy level.
        // A more complex model might adjust based on the *proportion* withdrawn vs total staked.
        // For simplicity, we'll just decrease the artifact's energy by the requested ETH amount if there's enough.
        uint256 energyToSubtract = amount;
        artifact.energy = artifact.energy > energyToSubtract ? artifact.energy - energyToSubtract : 0;
        artifact.lastEnergyUpdateTimestamp = block.timestamp; // Update timestamp after withdrawal affecting energy

        // Send ETH back to the user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "SAP: ETH withdrawal failed");

        emit EnergyWithdrawn(tokenId, msg.sender, amount, artifact.energy);
    }

    /// @notice Triggers energy decay for an Artifact if enough time has passed. Can be called by anyone.
    /// @param tokenId The ID of the artifact to decay.
    function decayEnergy(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        _applyEnergyDecay(tokenId);
    }

    /// @notice Allows a user (potentially with INFLUENCER_ROLE) to attempt to influence a trait.
    /// @param tokenId The ID of the artifact.
    /// @param traitIndex The index of the trait to influence.
    /// @param influenceDirection For numerical traits: +1 to increase, -1 to decrease. For categorical: the target category index.
    function influenceArtifact(uint256 tokenId, uint256 traitIndex, int256 influenceDirection) external payable nonReentrant whenNotPaused {
         require(_exists(tokenId), "SAP: Artifact does not exist");
         require(traitIndex < _nextTraitIndex, "SAP: Invalid trait index");
         ArtifactState storage artifact = _artifactStates[tokenId];
         TraitDefinition storage traitDef = traitDefinitions[traitIndex];
         TraitInfluenceWeight storage weights = traitInfluenceWeights[traitIndex];

         // Apply decay before interaction
         _applyEnergyDecay(tokenId);

         require(artifact.energy >= weights.energyCost, "SAP: Artifact does not have enough energy to be influenced");
         require(msg.value >= weights.ethCost, "SAP: Not enough ETH sent for influence cost");

         // Deduct costs
         artifact.energy -= weights.energyCost;
         protocolFeesCollected += msg.value; // ETH cost goes to protocol fees

         // Determine influence amount (for numerical traits)
         int256 influenceAmount = weights.baseInfluenceAmount;
         if (weights.randomInfluenceRange > 0) {
             // Simple randomness based on block hash - acknowledge limitations
             uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, block.number)));
             uint256 randomValue = randomSeed % (weights.randomInfluenceRange * 2 + 1); // Range 0 to 2*range
             influenceAmount += int256(randomValue) - int256(weights.randomInfluenceRange); // Shifts range to +/- range
         }

         // Add influencer bonus if applicable
         if (_hasInfluencerRole[msg.sender]) {
             influenceAmount += weights.influencerRoleBonus;
         }

         // Apply influence based on trait type and direction
         int256 oldTraitValue = int256(artifact.traits[traitIndex]);
         int256 newTraitValue = oldTraitValue;

         if (traitDef.isCategorical) {
             require(influenceDirection >= traitDef.minValue && influenceDirection <= traitDef.maxValue, "SAP: Invalid categorical influence target");
             // For categorical, influenceDirection is the target category index
             newTraitValue = influenceDirection; // Direct change (can add complex logic later)
         } else {
            // For numerical, apply calculated influence amount and direction
            if (influenceDirection > 0) {
                 newTraitValue = oldTraitValue + influenceAmount;
            } else if (influenceDirection < 0) {
                 newTraitValue = oldTraitValue - influenceAmount;
            }
            // Clamp numerical trait within min/max bounds
            newTraitValue = Math.max(newTraitValue, int256(traitDef.minValue));
            newTraitValue = Math.min(newTraitValue, int256(traitDef.maxValue));
         }

         artifact.traits[traitIndex] = uint256(newTraitValue);
         artifact.lastEnergyUpdateTimestamp = block.timestamp; // Energy changed

         emit TraitsInfluenced(tokenId, msg.sender, traitIndex, influenceAmount, uint256(newTraitValue));
    }

    /// @notice Allows a user to challenge an Artifact. Outcome is probabilistic.
    /// @param tokenId The ID of the artifact to challenge.
    function challengeArtifact(uint256 tokenId) external payable nonReentrant whenNotPaused {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        require(msg.value > 0, "SAP: Challenge stake must be non-zero");
        ArtifactState storage artifact = _artifactStates[tokenId];

        // Apply decay before challenge
        _applyEnergyDecay(tokenId);

        // Simple win/loss logic based on a trait (e.g., Affinity) and randomness
        // This is a placeholder; complex challenge logic would go here.
        uint256 affinityTraitIndex = 1; // Assuming Affinity is trait 1
        require(affinityTraitIndex < _nextTraitIndex, "SAP: Affinity trait not defined");
        uint256 affinityValue = artifact.traits[affinityTraitIndex];
        uint256 challengeRandomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, block.number)));

        bool won = (challengeRandomness % 1000) < affinityValue; // Higher affinity = higher chance to 'win' against the challenger

        uint256 protocolFee = (msg.value * CHALLENGE_PROTOCOL_FEE_BPS) / 10000;
        uint256 netStake = msg.value - protocolFee;
        protocolFeesCollected += protocolFee;

        uint256 reward = 0;
        if (won) {
            // Artifact 'wins' the challenge, challenger loses stake (minus fee)
            // The netStake can potentially be added to artifact energy or distributed
            // For this example, it just goes to protocol fees implicitly by not being returned.
            // Let's make the artifact gain some energy from *any* challenge attempt
            uint256 energyGain = msg.value / 10; // Example: 10% of stake becomes energy
             artifact.energy = Math.min(artifact.energy + energyGain, MAX_ENERGY);
             artifact.lastEnergyUpdateTimestamp = block.timestamp;
            emit ArtifactChallenged(tokenId, msg.sender, msg.value, true, 0); // Reward is 0 for challenger if artifact wins
        } else {
            // Artifact 'loses' the challenge, challenger gets reward
            // Reward could be based on netStake, or be a fixed amount, or come from a reward pool.
            // For simplicity, challenger gets their net stake back + a potential bonus (e.g., half the protocol fee)
            reward = netStake + (protocolFee / 2); // Example reward mechanism
            protocolFeesCollected -= (protocolFee / 2); // Reduce collected fees to pay reward
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "SAP: Challenge reward transfer failed");
            emit ArtifactChallenged(tokenId, msg.sender, msg.value, false, reward);
        }
    }

     /// @notice Allows users to claim rewards accumulated from interactions (e.g., challenge wins, future features)
     /// This function is a placeholder. A real implementation would track specific earned rewards per user.
     function claimInteractionReward(uint256 tokenId) external nonReentrant whenNotPaused {
         require(_exists(tokenId), "SAP: Artifact does not exist");
         // Placeholder: In a real system, you'd have a mapping tracking rewards:
         // mapping(uint256 => mapping(address => uint256)) public earnedRewards;
         // Here we'd check earnedRewards[tokenId][msg.sender], transfer ETH, and set to 0.
         // For this example, we'll just emit an event as the reward logic isn't fully implemented.
         // Imagine a small, fixed reward is claimable once per period or per interaction type.
         uint256 rewardAmount = 0.001 ether; // Example small reward

         // Check if user is eligible for a reward (e.g., based on a separate state or event)
         // This requires more state than the basic example has.
         // For demonstration, let's just allow claiming a small amount if the artifact has energy.
         // This is NOT secure reward logic, just a placeholder.
         ArtifactState storage artifact = _artifactStates[tokenId];
         require(artifact.energy > rewardAmount, "SAP: Artifact doesn't have enough energy for reward");

         // Deduct reward from artifact energy (example)
         artifact.energy -= rewardAmount;
         artifact.lastEnergyUpdateTimestamp = block.timestamp;

         (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
         require(success, "SAP: Reward transfer failed");

         emit InteractionRewardClaimed(tokenId, msg.sender, rewardAmount);
     }


    /// @notice Triggers a check to see if the Artifact can evolve to the next generation. Can be called by anyone.
    /// @param tokenId The ID of the artifact to check for evolution.
    function triggerEvolutionCheck(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        ArtifactState storage artifact = _artifactStates[tokenId];

        // Apply decay before checking criteria
        _applyEnergyDecay(tokenId);

        // Check evolution criteria
        bool energyCriteriaMet = artifact.energy >= MIN_ENERGY_FOR_EVOLUTION;
        bool cooldownPassed = block.timestamp >= artifact.lastEvolutionTimestamp + EVOLUTION_COOLDOWN;

        // Placeholder for trait-based criteria - e.g., trait[0] > 500
        bool traitCriteriaMet = true;
        if (_nextTraitIndex > 0) { // Example: Require Resilience > 500
             if (traitDefinitions[0].minValue <= 500 && traitDefinitions[0].maxValue >= 500 && !traitDefinitions[0].isCategorical) {
                  traitCriteriaMet = artifact.traits[0] > 500;
             }
        }


        if (energyCriteriaMet && cooldownPassed && traitCriteriaMet) {
            // --- Trigger Evolution ---
            artifact.generation++;
            artifact.lastEvolutionTimestamp = block.timestamp;
            // Optionally burn energy or reset some traits upon evolution
            artifact.energy = artifact.energy / 2; // Example: Halve energy upon evolution
            artifact.lastEnergyUpdateTimestamp = block.timestamp;

            // Example: Slightly boost a trait upon evolution
            if (_nextTraitIndex > 0 && !traitDefinitions[0].isCategorical && artifact.traits[0] < traitDefinitions[0].maxValue) {
                 artifact.traits[0] = Math.min(artifact.traits[0] + 50, traitDefinitions[0].maxValue);
            }


            emit ArtifactEvolved(tokenId, artifact.generation, artifact.energy);
        }
        // If criteria not met, nothing happens
    }

    /// @notice Allows an authorized role (Owner/Admin) to react to external events that influence artifacts.
    /// @param tokenId The ID of the artifact.
    /// @param dataIdentifier A bytes identifier for the type of external event.
    /// @param eventData Specific data influencing traits/energy (example: [traitIndex, changeAmount]).
    function reactToExternalEvent(uint256 tokenId, bytes memory dataIdentifier, int256[] memory eventData) external onlyOwner { // Could be limited to specific role
        require(_exists(tokenId), "SAP: Artifact does not exist");
        ArtifactState storage artifact = _artifactStates[tokenId];

        // Apply decay before applying external influence
        _applyEnergyDecay(tokenId);

        // Example logic: If dataIdentifier is "TRAIT_BOOST", apply eventData[1] to trait eventData[0]
        bytes32 traitBoostIdentifier = keccak256("TRAIT_BOOST");

        if (keccak256(dataIdentifier) == traitBoostIdentifier && eventData.length == 2) {
            uint256 traitIndex = uint256(eventData[0]);
            int256 changeAmount = eventData[1];

            require(traitIndex < _nextTraitIndex, "SAP: Invalid trait index for external event");
             TraitDefinition storage traitDef = traitDefinitions[traitIndex];
             require(!traitDef.isCategorical, "SAP: Cannot apply numerical change to categorical trait");


            int256 oldTraitValue = int256(artifact.traits[traitIndex]);
            int256 newTraitValue = oldTraitValue + changeAmount;

             // Clamp numerical trait within min/max bounds
            newTraitValue = Math.max(newTraitValue, int256(traitDef.minValue));
            newTraitValue = Math.min(newTraitValue, int256(traitDef.maxValue));

            artifact.traits[traitIndex] = uint256(newTraitValue);
             emit TraitsInfluenced(tokenId, msg.sender, traitIndex, changeAmount, uint256(newTraitValue)); // Re-use event
        }
        // Add other event handlers here

        artifact.lastEnergyUpdateTimestamp = block.timestamp; // State changed

        emit ExternalEventReacted(tokenId, dataIdentifier);
    }

    /// @notice Owner sets the weights for how different actions influence traits.
    /// @param traitIndex The index of the trait.
    /// @param weights The new influence weights for this trait.
    function setTraitWeights(uint256 traitIndex, TraitInfluenceWeight memory weights) external onlyOwner {
        require(traitIndex < _nextTraitIndex, "SAP: Invalid trait index");
        traitInfluenceWeights[traitIndex] = weights;
    }

     /// @notice Owner sets the energy decay rate per second.
    function setEnergyDecayRate(uint256 ratePerSecond) external onlyOwner {
        ENERGY_DECAY_RATE_PER_SECOND = ratePerSecond;
    }

     /// @notice Owner sets the thresholds required for evolution.
     /// @param minEnergy The minimum energy required.
     /// @param evolutionCooldownSeconds The time required between evolutions.
    function setEvolutionThresholds(uint256 minEnergy, uint256 evolutionCooldownSeconds) external onlyOwner {
        MIN_ENERGY_FOR_EVOLUTION = minEnergy;
        EVOLUTION_COOLDOWN = evolutionCooldownSeconds;
    }

     /// @notice Owner sets the base URI for metadata.
     function setBaseMetadataURI(string memory baseURI) external onlyOwner {
        _baseMetadataURI = baseURI;
    }

     /// @notice Owner withdraws accumulated protocol fees.
    /// @param recipient The address to send fees to.
    function withdrawProtocolFees(address payable recipient) external onlyOwner nonReentrant {
        uint256 amount = protocolFeesCollected;
        protocolFeesCollected = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "SAP: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /// @notice Owner grants the INFLUENCER_ROLE to an address.
    /// @param account The address to grant the role to.
    function grantInfluencerRole(address account) external onlyOwner {
        require(account != address(0), "SAP: Cannot grant role to zero address");
        _hasInfluencerRole[account] = true;
        emit InfluencerRoleGranted(account);
    }

    /// @notice Owner revokes the INFLUENCER_ROLE from an address.
    /// @param account The address to revoke the role from.
    function revokeInfluencerRole(address account) external onlyOwner {
        require(account != address(0), "SAP: Cannot revoke role from zero address");
        _hasInfluencerRole[account] = false;
        emit InfluencerRoleRevoked(account);
    }

     /// @notice Checks if an address has the INFLUENCER_ROLE.
    function isInfluencer(address account) public view returns (bool) {
        return _hasInfluencerRole[account];
    }

    // --- View Functions ---

    /// @notice Gets the full current state of an Artifact.
    function getArtifactState(uint256 tokenId) public view returns (ArtifactState memory) {
         require(_exists(tokenId), "SAP: Artifact does not exist");
        // Need to return a memory copy to avoid modifying storage
        ArtifactState storage artifact = _artifactStates[tokenId];
        ArtifactState memory state = ArtifactState({
             energy: artifact.energy,
             lastEnergyUpdateTimestamp: artifact.lastEnergyUpdateTimestamp,
             lastEvolutionTimestamp: artifact.lastEvolutionTimestamp,
             generation: artifact.generation,
             traits: new uint256[](artifact.traits.length), // Copy traits array
             totalStakedEnergy: artifact.totalStakedEnergy
        });
        for(uint i = 0; i < artifact.traits.length; i++){
            state.traits[i] = artifact.traits[i];
        }
        // Note: stakedEnergy mapping is not returned directly from view functions
        return state;
    }

     /// @notice Gets just the traits of an Artifact.
    function getArtifactTraits(uint256 tokenId) public view returns (uint256[] memory) {
         require(_exists(tokenId), "SAP: Artifact does not exist");
        return _artifactStates[tokenId].traits;
    }

    /// @notice Gets just the energy of an Artifact.
    function getArtifactEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "SAP: Artifact does not exist");
        // Return energy *after* potential decay calculation for a more current view
        ArtifactState storage artifact = _artifactStates[tokenId];
        uint256 timeElapsed = block.timestamp - artifact.lastEnergyUpdateTimestamp;
        uint256 decayAmount = timeElapsed * ENERGY_DECAY_RATE_PER_SECOND;
        return artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
    }

     /// @notice Gets the definition of a specific trait.
    function getTraitDefinition(uint256 traitIndex) public view returns (TraitDefinition memory) {
        require(traitIndex < _nextTraitIndex, "SAP: Invalid trait index");
        return traitDefinitions[traitIndex];
    }

    /// @notice Gets the possible outcomes for a specific trait (min/max or categories).
     function getPossibleTraitOutcomes(uint256 traitIndex) public view returns (uint256 minValue, uint256 maxValue, string[] memory possibleCategories, bool isCategorical) {
         require(traitIndex < _nextTraitIndex, "SAP: Invalid trait index");
         TraitDefinition storage traitDef = traitDefinitions[traitIndex];
         return (traitDef.minValue, traitDef.maxValue, traitDef.possibleCategories, traitDef.isCategorical);
     }


    // --- Internal Helper Functions ---

    /// @dev Internal function to apply energy decay based on time passed.
    function _applyEnergyDecay(uint256 tokenId) internal {
        ArtifactState storage artifact = _artifactStates[tokenId];
        uint256 timeElapsed = block.timestamp - artifact.lastEnergyUpdateTimestamp;
        uint256 decayAmount = timeElapsed * ENERGY_DECAY_RATE_PER_SECOND;

        if (decayAmount > 0) {
            uint256 oldEnergy = artifact.energy;
            artifact.energy = artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
            artifact.lastEnergyUpdateTimestamp = block.timestamp; // Update timestamp even if energy hits 0
            if (artifact.energy != oldEnergy) {
                 emit EnergyDecayed(tokenId, oldEnergy - artifact.energy, artifact.energy);
            }
        }
    }

    // The following internal functions are standard ERC721 helpers, not custom:
    // _exists(uint256 tokenId)
    // _safeMint(address to, uint256 tokenId)
    // _mint(address to, uint256 tokenId)
    // _burn(uint256 tokenId)
    // _transfer(address from, address to, uint256 tokenId)
    // _isApprovedOrOwner(address spender, uint256 tokenId)
    // _approve(address to, uint256 tokenId)
    // _setApprovalForAll(address operator, address owner, bool approved)
    // _context standardize bytes data for safeTransferFrom

}
```