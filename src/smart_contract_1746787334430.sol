Okay, here is a Solidity smart contract concept focusing on "ChronoEssence", a type of stateful, evolving, and interactive digital asset (NFT). It combines elements of dynamic NFTs, gamified mechanics, and token interaction.

It avoids duplicating standard open-source AMMs, staking contracts, or basic ERC-20/ERC-721 implementations by adding significant custom logic around asset lifecycle, state changes, decay, and interaction costs/rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice, though 0.8+ checks default for +, -, *, /

// --- ChronoEssence: Evolving Digital Assets ---
//
// Concept:
// A ChronoEssence is a unique, stateful, non-fungible token (NFT) that represents a digital entity
// which evolves over time based on interaction and internal state. It requires "nourishment"
// and "training" (paid for with a specific ERC20 token) to thrive and evolve. Lack of interaction
// leads to decay, negatively impacting its state and potential. Essences can be "extracted"
// (burned) to yield a resource (also a specific ERC20 token) based on their current state.
//
// Core Features:
// 1. Stateful NFT: Each token ID has associated, mutable state variables (nourishment, skill, evolution stage, etc.).
// 2. Interactive Lifecycle: Users pay a token cost to perform actions (feed, train) that improve state.
// 3. Time-Based Evolution: Evolution stages unlock based on age AND meeting certain state thresholds.
// 4. Decay Mechanic: State deteriorates over time if the asset is not interacted with. Decay can be triggered by anyone.
// 5. Resource Extraction: Essences can be burned for a variable yield of another token, dependent on their state.
// 6. Dynamic Metadata: tokenURI reflects the current state of the asset (requires off-chain metadata server).
// 7. Token Integration: Uses specific ERC20 tokens for interaction costs and extraction yield.
//
// Outline:
// - State Struct for ChronoEssence data
// - Mappings to store essence state and other data
// - State Variables for contract parameters (costs, thresholds, token addresses)
// - Events for key actions
// - Modifiers (Ownable, state checks)
// - ERC721 and ERC721URIStorage Inheritance
// - Custom Logic Functions:
//    - Minting & State Initialization
//    - Core Interactions (Feed, Train)
//    - Lifecycle Management (Evolution Trigger, Decay Trigger, Extraction)
//    - State Queries (Get full state, individual stats, checks)
//    - Parameter Setting (Admin functions)
//    - Token Handling (Withdrawal)
//    - Dynamic URI Generation
//    - Utility/Helper Functions
//
// Function Summary (Custom Logic - beyond standard ERC721):
// 1. constructor(): Initializes contract, sets base URI, links interaction/yield tokens, sets initial parameters.
// 2. mintEssence(): Mints a new ChronoEssence, initializes its state variables.
// 3. getEssenceState(uint256 tokenId) view: Retrieves the complete state struct for a given token ID.
// 4. feedEssence(uint256 tokenId): Increases nourishment, consumes interaction tokens from the caller, updates last interaction time.
// 5. trainEssence(uint256 tokenId): Increases skill, consumes interaction tokens from the caller, updates last interaction time.
// 6. triggerEvolution(uint256 tokenId): Attempts to evolve the essence to the next stage if conditions (age, state, decay) are met.
// 7. calculateCurrentEvolutionStage(uint256 tokenId) view: Purely calculates the *potential* evolution stage based on *current* state and age thresholds. (Does not change state).
// 8. decayEssenceState(uint256 tokenId): Public function allowing anyone to trigger decay if the essence hasn't been interacted with recently. Applies penalties to state. Rewards the caller slightly.
// 9. getEssenceDecayLevel(uint256 tokenId) view: Calculates the current accumulated decay penalty based on time since last interaction.
// 10. extractCatalyst(uint256 tokenId): Burns the ChronoEssence and transfers a calculated amount of yield tokens to the owner based on the essence's final state.
// 11. calculateCatalystYield(uint256 tokenId) view: Calculates the amount of yield tokens that would be received if the essence were extracted.
// 12. getEssenceCreationTime(uint256 tokenId) view: Returns the timestamp when the essence was minted.
// 13. getEssenceLastInteractionTime(uint256 tokenId) view: Returns the timestamp of the last feed or train interaction.
// 14. getEssenceNourishment(uint256 tokenId) view: Returns the current nourishment level.
// 15. getEssenceSkill(uint256 tokenId) view: Returns the current skill level.
// 16. getEssenceEvolutionStage(uint256 tokenId) view: Returns the current *actual* evolution stage stored in state.
// 17. canEssenceEvolveNow(uint256 tokenId) view: Checks if an essence currently meets the criteria to trigger an evolution.
// 18. setEvolutionThresholds(uint32[] memory newThresholds) onlyOwner: Sets the age thresholds (in seconds) required for each evolution stage.
// 19. setInteractionCost(uint256 newCost) onlyOwner: Sets the cost in interaction tokens for feed/train actions.
// 20. setCatalystYieldRates(uint256[] memory newRates) onlyOwner: Sets the base yield rates for catalyst extraction based on evolution stage.
// 21. setDecayRatePerSecond(uint256 rate) onlyOwner: Sets how much decay accumulates per second of inactivity.
// 22. setDecayPenaltyFactor(uint256 factor) onlyOwner: Sets the severity of the decay penalty applied to state.
// 23. setDecayReward(uint256 reward) onlyOwner: Sets the token reward for calling `decayEssenceState`.
// 24. setBaseURI(string memory baseURI_) onlyOwner: Sets the base URI for token metadata.
// 25. setInteractionToken(address tokenAddress) onlyOwner: Sets the ERC20 address used for interaction costs.
// 26. setYieldToken(address tokenAddress) onlyOwner: Sets the ERC20 address given as yield.
// 27. withdrawCollectedTokens(address tokenAddress, uint256 amount) onlyOwner: Allows owner to withdraw collected tokens (e.g., interaction fees).
// 28. tokenURI(uint256 tokenId) override view: Overrides ERC721URIStorage to dynamically return a URI based on the essence's state (requires off-chain implementation resolving the URI).
// 29. getTotalMinted() view: Returns the total number of essences minted.
// 30. _calculateStateAdjustedValue(uint256 value, uint256 decayLevel) pure: Internal helper to apply decay penalty to a value. (Exposed here for clarity)
// 31. getInteractionCost() view: Returns the current interaction cost.
// 32. getDecayRatePerSecond() view: Returns the current decay accumulation rate.
// 33. getDecayPenaltyFactor() view: Returns the current decay penalty factor.
// 34. getDecayRewardAmount() view: Returns the current decay reward amount.

contract ChronoEssence is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Using SafeMath for clarity, 0.8+ has built-in checks

    Counters.Counter private _tokenIdCounter;

    struct ChronoEssenceState {
        uint32 evolutionStage; // Current actual stage
        uint256 nourishment;   // Level of nourishment
        uint256 skill;         // Level of skill
        uint64 creationTime;    // Timestamp of minting
        uint64 lastInteractionTime; // Timestamp of last feed/train
    }

    // Mapping from token ID to ChronoEssence state
    mapping(uint256 => ChronoEssenceState) private _essences;

    // Parameters for evolution, decay, costs, and yields
    uint32[] private _evolutionAgeThresholds; // Age in seconds to unlock stages (index 0: stage 1, index 1: stage 2...)
    uint256 private _interactionCost;         // Cost per feed/train in interaction tokens
    uint256[] private _catalystYieldRates;    // Base yield rate for extraction per evolution stage
    uint256 private _decayRatePerSecond;      // How much 'decay' accumulates per second of inactivity
    uint256 private _decayPenaltyFactor;      // Factor determining how much state is reduced by decay (e.g., 100 = 1% reduction per decay unit)
    uint256 private _decayReward;             // Token reward for triggering decay
    address private _interactionToken;        // ERC20 token address for feed/train costs
    address private _yieldToken;              // ERC20 token address for extraction yield

    // --- Events ---
    event EssenceMinted(uint256 indexed tokenId, address indexed owner);
    event EssenceInteracted(uint256 indexed tokenId, address indexed caller, string action, uint256 cost);
    event EssenceEvolved(uint256 indexed tokenId, uint32 newStage, uint64 timestamp);
    event EssenceDecayed(uint256 indexed tokenId, uint256 decayApplied, uint256 rewardSent);
    event EssenceExtracted(uint256 indexed tokenId, address indexed owner, uint256 yieldAmount);
    event ParametersUpdated(string paramName, string details);

    // --- Modifiers ---
    modifier onlyEssenceOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ChronoEssence: Not owner or approved");
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address interactionToken_,
        address yieldToken_,
        uint33[] memory evolutionAgeThresholds_, // Use uint33 for slightly larger max seconds
        uint256 interactionCost_,
        uint256[] memory catalystYieldRates_,
        uint256 decayRatePerSecond_,
        uint256 decayPenaltyFactor_,
        uint256 decayReward_
    ) ERC721(name_, symbol_) ERC721URIStorage(baseURI_) Ownable(msg.sender) {
        _evolutionAgeThresholds = evolutionAgeThresholds_;
        _interactionCost = interactionCost_;
        _catalystYieldRates = catalystYieldRates_;
        _decayRatePerSecond = decayRatePerSecond_;
        _decayPenaltyFactor = decayPenaltyFactor_;
        _decayReward = decayReward_;
        _interactionToken = interactionToken_;
        _yieldToken = yieldToken_;

        // Basic validation
        require(_evolutionAgeThresholds.length > 0, "ChronoEssence: At least one evolution threshold required");
        require(_catalystYieldRates.length >= _evolutionAgeThresholds.length, "ChronoEssence: Yield rates must match evolution stages");
        require(interactionToken_ != address(0), "ChronoEssence: Interaction token address cannot be zero");
        require(yieldToken_ != address(0), "ChronoEssence: Yield token address cannot be zero");

        emit ParametersUpdated("Constructor", "Initial parameters set");
    }

    // --- Core Interaction & Lifecycle Functions ---

    /**
     * @notice Mints a new ChronoEssence token and initializes its state.
     * @dev Only owner can mint, or could add logic for public minting with cost. Keeping simple for example.
     * @param to The address to mint the token to.
     */
    function mintEssence(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        _essences[newItemId] = ChronoEssenceState({
            evolutionStage: 1, // Start at stage 1
            nourishment: 100,   // Initial state
            skill: 50,          // Initial state
            creationTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp) // Starts fresh
        });

        emit EssenceMinted(newItemId, to);
    }

    /**
     * @notice Allows the owner or approved address to feed an essence, increasing nourishment.
     * @dev Requires `_interactionCost` of interaction tokens from the caller.
     * @param tokenId The ID of the essence to feed.
     */
    function feedEssence(uint256 tokenId) public payable onlyEssenceOwner(tokenId) {
        ChronoEssenceState storage essence = _essences[tokenId];
        require(_exists(tokenId), "ChronoEssence: Token does not exist");

        // Transfer interaction token cost from caller to contract
        require(IERC20(_interactionToken).transferFrom(msg.sender, address(this), _interactionCost), "ChronoEssence: Token transfer failed");

        uint256 decayLevel = getEssenceDecayLevel(tokenId);
        uint256 nourishingIncrease = 200; // Base increase amount
        essence.nourishment = essence.nourishment.add(_calculateStateAdjustedValue(nourishingIncrease, decayLevel)); // Increase nourishment, reduced by decay

        // Cap nourishment at a max value (e.g., 1000)
        essence.nourishment = essence.nourishment > 1000 ? 1000 : essence.nourishment;

        essence.lastInteractionTime = uint64(block.timestamp); // Update interaction time

        emit EssenceInteracted(tokenId, msg.sender, "feed", _interactionCost);
    }

    /**
     * @notice Allows the owner or approved address to train an essence, increasing skill.
     * @dev Requires `_interactionCost` of interaction tokens from the caller.
     * @param tokenId The ID of the essence to train.
     */
    function trainEssence(uint256 tokenId) public payable onlyEssenceOwner(tokenId) {
        ChronoEssenceState storage essence = _essences[tokenId];
        require(_exists(tokenId), "ChronoEssence: Token does not exist");

        // Transfer interaction token cost from caller to contract
        require(IERC20(_interactionToken).transferFrom(msg.sender, address(this), _interactionCost), "ChronoEssence: Token transfer failed");

        uint256 decayLevel = getEssenceDecayLevel(tokenId);
        uint256 skillIncrease = 150; // Base increase amount
        essence.skill = essence.skill.add(_calculateStateAdjustedValue(skillIncrease, decayLevel)); // Increase skill, reduced by decay

         // Cap skill at a max value (e.g., 1000)
        essence.skill = essence.skill > 1000 ? 1000 : essence.skill;

        essence.lastInteractionTime = uint64(block.timestamp); // Update interaction time

        emit EssenceInteracted(tokenId, msg.sender, "train", _interactionCost);
    }

    /**
     * @notice Attempts to evolve the essence to the next stage.
     * @dev Evolution requires meeting age threshold, minimum nourishment, skill, and not being too decayed.
     * @param tokenId The ID of the essence to attempt evolving.
     */
    function triggerEvolution(uint256 tokenId) public onlyEssenceOwner(tokenId) {
        ChronoEssenceState storage essence = _essences[tokenId];
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        require(essence.evolutionStage < _evolutionAgeThresholds.length + 1, "ChronoEssence: Essence is already at max evolution stage");
        require(canEssenceEvolveNow(tokenId), "ChronoEssence: Essence does not meet evolution criteria");

        essence.evolutionStage += 1;
        essence.lastInteractionTime = uint64(block.timestamp); // Interaction counts as interaction

        emit EssenceEvolved(tokenId, essence.evolutionStage, block.timestamp);
    }

     /**
     * @notice Allows anyone to trigger decay if an essence is overdue.
     * @dev Applies decay penalty to state and sends a small reward to the caller.
     * @param tokenId The ID of the essence to potentially decay.
     */
    function decayEssenceState(uint256 tokenId) public {
        ChronoEssenceState storage essence = _essences[tokenId];
        require(_exists(tokenId), "ChronoEssence: Token does not exist");

        uint256 decayLevel = getEssenceDecayLevel(tokenId);
        require(decayLevel > 0, "ChronoEssence: Essence is not due for decay");

        // Apply decay penalty based on decay level
        // Penalty reduces nourishment and skill
        essence.nourishment = essence.nourishment.sub(_calculateStatePenalty(essence.nourishment, decayLevel, _decayPenaltyFactor));
        essence.skill = essence.skill.sub(_calculateStatePenalty(essence.skill, decayLevel, _decayPenaltyFactor));

        // Update last interaction time to NOW to stop further immediate decay until period passes again
        essence.lastInteractionTime = uint64(block.timestamp);

        // Reward caller (e.g., send a small amount of Yield Token from contract balance)
        if (_decayReward > 0 && IERC20(_yieldToken).balanceOf(address(this)) >= _decayReward) {
             require(IERC20(_yieldToken).transfer(msg.sender, _decayReward), "ChronoEssence: Failed to send decay reward");
        } else {
            // If reward token isn't set or balance is zero, could send small ETH, or just skip reward
            // For this example, we'll just skip if token transfer fails/not configured.
        }


        emit EssenceDecayed(tokenId, decayLevel, _decayReward);
    }

    /**
     * @notice Burns an essence, allowing its owner to extract yield tokens.
     * @dev Yield amount depends on the essence's current state.
     * @param tokenId The ID of the essence to extract.
     */
    function extractCatalyst(uint256 tokenId) public onlyEssenceOwner(tokenId) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");

        uint256 yieldAmount = calculateCatalystYield(tokenId);
        address owner = ownerOf(tokenId); // Get owner before burning

        // Burn the NFT
        _burn(tokenId);

        // Transfer yield tokens to the owner
        require(IERC20(_yieldToken).transfer(owner, yieldAmount), "ChronoEssence: Failed to transfer yield tokens");

        emit EssenceExtracted(tokenId, owner, yieldAmount);
    }

    // --- State Query Functions ---

     /**
     * @notice Gets the full state struct of an essence.
     * @param tokenId The ID of the essence.
     * @return The ChronoEssenceState struct.
     */
    function getEssenceState(uint256 tokenId) public view returns (ChronoEssenceState memory) {
         require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId];
    }

     /**
     * @notice Calculates the *potential* evolution stage based on *current* state and age.
     * @dev This is a view function and does not change the actual evolutionStage state variable.
     *      `triggerEvolution` is needed to advance the actual stage.
     * @param tokenId The ID of the essence.
     * @return The potential evolution stage (>= actual stage).
     */
    function calculateCurrentEvolutionStage(uint256 tokenId) public view returns (uint32) {
        ChronoEssenceState memory essence = _essences[tokenId];
        require(_exists(tokenId), "ChronoEssence: Token does not exist");

        uint64 currentAge = uint64(block.timestamp) - essence.creationTime;
        uint256 decayLevel = getEssenceDecayLevel(tokenId);

        // Apply decay penalty to nourishment and skill for calculation purposes
        uint256 effectiveNourishment = essence.nourishment.sub(_calculateStatePenalty(essence.nourishment, decayLevel, _decayPenaltyFactor));
        uint256 effectiveSkill = essence.skill.sub(_calculateStatePenalty(essence.skill, decayLevel, _decayPenaltyFactor));

        // Determine potential stage based on age and adjusted stats
        uint32 potentialStage = 1;
        for (uint i = 0; i < _evolutionAgeThresholds.length; i++) {
            if (currentAge >= _evolutionAgeThresholds[i] &&
                effectiveNourishment >= (i+1) * 50 && // Example thresholds based on stage
                effectiveSkill >= (i+1) * 40) {      // Example thresholds based on stage
                potentialStage = uint32(i + 2); // +1 for 0-based index, +1 because thresholds are for *next* stage
            } else {
                break; // Stop if threshold not met
            }
        }

        // Actual evolution stage cannot exceed potential stage, but potential can exceed actual
        // if triggerEvolution hasn't been called. Return the potential stage.
        return potentialStage;
    }


     /**
     * @notice Calculates the current accumulated decay level based on time since last interaction.
     * @param tokenId The ID of the essence.
     * @return The total accumulated decay units.
     */
    function getEssenceDecayLevel(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "ChronoEssence: Token does not exist");
        ChronoEssenceState memory essence = _essences[tokenId];

        uint64 timeSinceLastInteraction = uint64(block.timestamp) - essence.lastInteractionTime;
        return timeSinceLastInteraction.mul(_decayRatePerSecond);
    }

    /**
     * @notice Calculates the amount of yield tokens an essence would produce upon extraction.
     * @param tokenId The ID of the essence.
     * @return The calculated yield amount.
     */
    function calculateCatalystYield(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        ChronoEssenceState memory essence = _essences[tokenId];

        uint256 decayLevel = getEssenceDecayLevel(tokenId);

        // Calculate yield based on stage, nourishment, skill, adjusted by decay
        uint256 baseYield = 0;
        if (essence.evolutionStage > 0 && essence.evolutionStage <= _catalystYieldRates.length) {
             baseYield = _catalystYieldRates[essence.evolutionStage - 1]; // Use actual stage for base yield
        }

        // Apply decay penalty to nourishment and skill contributions
        uint256 effectiveNourishment = essence.nourishment.sub(_calculateStatePenalty(essence.nourishment, decayLevel, _decayPenaltyFactor));
        uint256 effectiveSkill = essence.skill.sub(_calculateStatePenalty(essence.skill, decayLevel, _decayPenaltyFactor));


        // Example complex yield calculation: base + nourishment_bonus + skill_bonus, adjusted by decay
        // Ensure calculations avoid overflow and division by zero if factors can be zero.
        uint256 nourishmentBonus = effectiveNourishment.mul(baseYield).div(1000); // Example: 100% of base at max effective nourishment
        uint256 skillBonus = effectiveSkill.mul(baseYield).div(1000);          // Example: 100% of base at max effective skill

        return baseYield.add(nourishmentBonus).add(skillBonus);
    }

     /**
     * @notice Checks if an essence meets the criteria to trigger evolution.
     * @param tokenId The ID of the essence.
     * @return True if ready to evolve, false otherwise.
     */
    function canEssenceEvolveNow(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        ChronoEssenceState memory essence = _essences[tokenId];

        if (essence.evolutionStage >= _evolutionAgeThresholds.length + 1) {
            return false; // Already at max stage
        }

        uint64 requiredAge = _evolutionAgeThresholds[essence.evolutionStage -1]; // Stage 1 threshold is _evolutionAgeThresholds[0], etc.
        uint64 currentAge = uint64(block.timestamp) - essence.creationTime;

        if (currentAge < requiredAge) {
            return false; // Not old enough
        }

        uint256 decayLevel = getEssenceDecayLevel(tokenId);
        uint256 effectiveNourishment = essence.nourishment.sub(_calculateStatePenalty(essence.nourishment, decayLevel, _decayPenaltyFactor));
        uint256 effectiveSkill = essence.skill.sub(_calculateStatePenalty(essence.skill, decayLevel, _decayPenaltyFactor));

        // Example evolution criteria: Check if effective stats are above a threshold for the *next* stage
        uint256 nourishmentThreshold = essence.evolutionStage.mul(50); // Example: Needs 50 for stage 2, 100 for stage 3, etc.
        uint256 skillThreshold = essence.evolutionStage.mul(40);       // Example: Needs 40 for stage 2, 80 for stage 3, etc.


        return effectiveNourishment >= nourishmentThreshold && effectiveSkill >= skillThreshold;
    }


    // --- State Variable Getters (Individual) ---

    function getEssenceCreationTime(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId].creationTime;
    }

     function getEssenceLastInteractionTime(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId].lastInteractionTime;
    }

    function getEssenceNourishment(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId].nourishment;
    }

    function getEssenceSkill(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId].skill;
    }

     function getEssenceEvolutionStage(uint256 tokenId) public view returns (uint32) {
         require(_exists(tokenId), "ChronoEssence: Token does not exist");
        return _essences[tokenId].evolutionStage;
    }

    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Admin / Parameter Setting Functions ---

    /**
     * @notice Sets the age thresholds (in seconds) required for each evolution stage.
     * @dev Array length determines number of stages after initial. Must be called by owner.
     *      `newThresholds[0]` is the age required to reach stage 2, `newThresholds[1]` for stage 3, etc.
     * @param newThresholds The array of age thresholds.
     */
    function setEvolutionThresholds(uint33[] memory newThresholds) public onlyOwner {
        require(newThresholds.length > 0, "ChronoEssence: Thresholds must not be empty");
         // Optional: Add check that thresholds are increasing
        for(uint i = 1; i < newThresholds.length; i++) {
            require(newThresholds[i] > newThresholds[i-1], "ChronoEssence: Thresholds must be increasing");
        }
        _evolutionAgeThresholds = newThresholds;
        emit ParametersUpdated("EvolutionThresholds", "Age thresholds updated");
    }

    /**
     * @notice Sets the base yield rates for catalyst extraction based on evolution stage.
     * @dev Array index corresponds to stage - 1. Must match number of evolution stages possible.
     * @param newRates The array of yield rates.
     */
    function setCatalystYieldRates(uint256[] memory newRates) public onlyOwner {
         require(newRates.length >= _evolutionAgeThresholds.length, "ChronoEssence: Yield rates must match evolution stages");
        _catalystYieldRates = newRates;
        emit ParametersUpdated("CatalystYieldRates", "Yield rates updated");
    }


    /**
     * @notice Sets the cost in interaction tokens for feed/train actions.
     * @param newCost The new cost.
     */
    function setInteractionCost(uint256 newCost) public onlyOwner {
        _interactionCost = newCost;
        emit ParametersUpdated("InteractionCost", string(abi.encodePacked("Cost updated to ", _uint256ToString(newCost))));
    }

     /**
     * @notice Sets how much 'decay' accumulates per second of inactivity.
     * @param rate The new decay rate per second.
     */
    function setDecayRatePerSecond(uint256 rate) public onlyOwner {
        _decayRatePerSecond = rate;
        emit ParametersUpdated("DecayRatePerSecond", string(abi.encodePacked("Rate updated to ", _uint256ToString(rate))));
    }

     /**
     * @notice Sets the factor determining how much state is reduced by decay.
     * @dev E.g., 100 means 1% reduction per decay unit if applied linearly.
     * @param factor The new decay penalty factor.
     */
    function setDecayPenaltyFactor(uint256 factor) public onlyOwner {
        _decayPenaltyFactor = factor;
        emit ParametersUpdated("DecayPenaltyFactor", string(abi.encodePacked("Factor updated to ", _uint256ToString(factor))));
    }

     /**
     * @notice Sets the token reward for calling `decayEssenceState`.
     * @param reward The new reward amount.
     */
    function setDecayReward(uint256 reward) public onlyOwner {
        _decayReward = reward;
        emit ParametersUpdated("DecayReward", string(abi.encodePacked("Reward updated to ", _uint256ToString(reward))));
    }

     /**
     * @notice Sets the ERC20 address used for interaction costs.
     * @param tokenAddress The address of the interaction token.
     */
    function setInteractionToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "ChronoEssence: Token address cannot be zero");
        _interactionToken = tokenAddress;
        emit ParametersUpdated("InteractionToken", string(abi.encodePacked("Address updated to ", _addressToString(tokenAddress))));
    }

     /**
     * @notice Sets the ERC20 address given as yield during extraction.
     * @param tokenAddress The address of the yield token.
     */
    function setYieldToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "ChronoEssence: Token address cannot be zero");
        _yieldToken = tokenAddress;
        emit ParametersUpdated("YieldToken", string(abi.encodePacked("Address updated to ", _addressToString(tokenAddress))));
    }

    /**
     * @notice Allows the owner to withdraw collected tokens (e.g., interaction fees).
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawCollectedTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "ChronoEssence: Token address cannot be zero");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "ChronoEssence: Insufficient contract balance");
        require(token.transfer(owner(), amount), "ChronoEssence: Failed to withdraw tokens");
        emit ParametersUpdated("Withdrawal", string(abi.encodePacked("Withdrew ", _uint256ToString(amount), " from ", _addressToString(tokenAddress))));
    }

     // --- Override ERC721URIStorage ---

    /**
     * @notice Overrides ERC721URIStorage to dynamically return a URI based on the essence's state.
     * @dev Requires an off-chain metadata server configured to handle requests at {baseURI}/{tokenId}
     *      and generate metadata JSON based on the state retrieved via contract calls (or events/subgraphs).
     * @param tokenId The ID of the essence.
     * @return The URI pointing to the dynamic metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ChronoEssence: URI query for nonexistent token");

        // The actual dynamic metadata logic resides off-chain.
        // The URI returned should point to an endpoint that fetches the essence's state
        // (evolutionStage, nourishment, skill, decay, etc.) via contract calls
        // and generates the appropriate JSON metadata.
        // Example: "https://myessencemetadata.com/api/essences/123"
        // The off-chain server for token ID 123 would query this contract for getEssenceState(123)
        // and build the JSON representing its current attributes.

        // For demonstration, we simply return the base URI + token ID string.
        // A real implementation needs the off-chain component.
         string memory base = _baseURI();
         return string(abi.encodePacked(base, _uint256ToString(tokenId)));
    }

    // --- View/Pure Helper Functions ---

    function getInteractionCost() public view returns (uint256) {
        return _interactionCost;
    }

     function getDecayRatePerSecond() public view returns (uint256) {
        return _decayRatePerSecond;
    }

     function getDecayPenaltyFactor() public view returns (uint256) {
        return _decayPenaltyFactor;
    }

    function getDecayRewardAmount() public view returns (uint256) {
        return _decayReward;
    }


    /**
     * @notice Calculates the state value adjusted by decay penalty.
     * @dev Used internally for calculations involving effective stats.
     *      Formula: value * (1000 - min(decayLevel * penaltyFactor / 10, 1000)) / 1000
     *      (Assuming penaltyFactor is per 100 units of decay, adjust formula as needed)
     *      More simply: Reduces value by `decayLevel * decayPenaltyFactor / SOME_SCALE`.
     * @param value The base value (nourishment, skill).
     * @param decayLevel The current accumulated decay units.
     * @param penaltyFactor Factor determining severity of penalty per decay unit.
     * @return The value after applying decay penalty.
     */
    function _calculateStateAdjustedValue(uint256 value, uint256 decayLevel, uint256 penaltyFactor) internal pure returns (uint256) {
        // Simple linear penalty example: reduce value by (decayLevel * penaltyFactor / 10000) percent.
        // Ensure scale factor is large enough to avoid premature truncation with integer division.
        // Eg: penaltyFactor=100 (means 1% reduction base per decay unit), SCALE=10000
        // Penalty % = decayLevel * 100 / 10000 = decayLevel / 100
        // Reduce value by value * (decayLevel / 100) / 100 = value * decayLevel / 10000
        uint256 scale = 10000; // Adjust scale based on desired penalty granularity
        uint256 penaltyAmount = value.mul(decayLevel.mul(penaltyFactor)).div(scale);

        return value.sub(penaltyAmount > value ? value : penaltyAmount); // Ensure result doesn't go below zero
    }

    // Overloaded function for clarity when adjusting increases vs penalties
     function _calculateStateAdjustedValue(uint256 value, uint256 decayLevel) internal view returns (uint256) {
        // Adjusting increase amounts based on decay: high decay = less increase
        // For simplicity, let's say effective increase is baseIncrease * (1000 - decayLevel) / 1000
        // Assuming decayLevel represents units that cap around 1000 for max decay effect.
         uint256 maxDecayEffect = 1000; // Max decay units before state stops improving from interaction
        uint256 effectiveDecay = decayLevel > maxDecayEffect ? maxDecayEffect : decayLevel;
        return value.mul(maxDecayEffect.sub(effectiveDecay)).div(maxDecayEffect);
     }


     /**
     * @dev Helper function to calculate state penalty amount.
     * @param baseValue The original state value (nourishment, skill).
     * @param decayLevel The current accumulated decay units.
     * @param penaltyFactor Factor determining severity of penalty per decay unit.
     * @return The amount to subtract from the base value.
     */
    function _calculateStatePenalty(uint256 baseValue, uint256 decayLevel, uint256 penaltyFactor) internal pure returns (uint256) {
        uint256 scale = 10000; // Same scale as in _calculateStateAdjustedValue (penalty)
        uint256 penaltyAmount = baseValue.mul(decayLevel.mul(penaltyFactor)).div(scale);
        return penaltyAmount > baseValue ? baseValue : penaltyAmount; // Cannot penalize more than the current value
    }

    // --- Internal/Helper Functions for string conversion (used in tokenURI and Events) ---
    // These are basic helpers. For production, consider more robust libraries if needed.

    function _uint256ToString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

     function _addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory _hex = "0123456789abcdef";
        bytes memory _string = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            _string[i * 2] = _hex[uint8(_bytes[i + 12] >> 4)];
            _string[i * 2 + 1] = _hex[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    // --- Standard ERC721 Functions (Inherited/Overridden) ---
    // These are standard and count towards the function count requirement.

    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool)
    // function balanceOf(address owner) public view override returns (uint256)
    // function ownerOf(uint256 tokenId) public view override returns (address)
    // function approve(address to, uint256 tokenId) public override
    // function getApproved(uint256 tokenId) public view override returns (address)
    // function setApprovalForAll(address operator, bool approved) public override
    // function isApprovedForAll(address owner, address operator) public view override returns (bool)
    // function transferFrom(address from, address to, uint256 tokenId) public override
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override
    // function name() public view override returns (string memory)
    // function symbol() public view override returns (string memory)
    // function _baseURI() internal view override returns (string memory) // Internal helper for URI

}
```

---

**Explanation of Advanced/Creative Concepts Used:**

1.  **Stateful NFTs:** Unlike typical NFTs representing static art, each ChronoEssence token has mutable state (`evolutionStage`, `nourishment`, `skill`, `creationTime`, `lastInteractionTime`) stored directly in the contract.
2.  **Interactive Mechanics with Token Sink/Source:** The `feedEssence` and `trainEssence` functions require users to spend a specific ERC20 token. This creates a token sink tied to asset interaction. The `extractCatalyst` function acts as a token source, rewarding users for burning assets, creating a potential economic loop.
3.  **Time-Based and State-Dependent Evolution:** Evolution isn't purely based on time or purely on stats. It requires both an age threshold *and* minimum state levels (nourishment, skill) to be met. The `triggerEvolution` function allows the owner to advance the *actual* stage only when these conditions (`canEssenceEvolveNow`) are satisfied.
4.  **Decay Mechanic:** The `decayEssenceState` function introduces a novel concept where inactivity leads to state deterioration. Making this function `public` allows anyone to trigger decay (and potentially earn a reward), incentivizing community maintenance and preventing permanently stalled states. This is a pattern used to externalize the gas cost of state updates triggered by time.
5.  **Dynamic Metadata (`tokenURI` Override):** The `tokenURI` function is overridden to point to an external service that will generate metadata based on the *current* state of the NFT (evolution stage, stats, decay). This makes the NFT's appearance and attributes dynamic and responsive to user interaction and the passage of time.
6.  **Variable Yield Extraction:** The `extractCatalyst` function allows burning the NFT for a token yield, but the amount isn't fixed. It's calculated dynamically based on the essence's `evolutionStage`, `nourishment`, `skill`, and `decayLevel` (`calculateCatalystYield`). This adds strategic depth – do you interact to maximize yield, or extract early?
7.  **Complexity of State Updates:** Interactions and decay use internal helper functions (`_calculateStateAdjustedValue`, `_calculateStatePenalty`) to modify state values based on multiple factors (base increase/decrease, decay level, penalty factor), creating a richer simulation.
8.  **Admin Parameterization:** The contract includes numerous `onlyOwner` functions to set parameters (`setEvolutionThresholds`, `setInteractionCost`, `setDecayRatePerSecond`, etc.). This allows the contract behavior to be tuned after deployment, introducing potential for game balance adjustments or seasonal changes.
9.  **Reward for Maintenance:** The `decayEssenceState` function optionally sends a small token reward to the caller who triggers the decay check. This is a gas-optimization pattern where users are incentivized to perform maintenance tasks.

This contract combines multiple mechanics into a single asset type, making it more complex and potentially more engaging than simpler NFT or DeFi contracts found openly. The interaction between time, state, decay, and token economics provides fertile ground for a unique application.