Okay, let's design a smart contract concept that combines several interesting, advanced, and creative ideas beyond typical token or NFT contracts.

We'll create a contract for "Adaptive Chronicle Assets" (ACAs). These are ERC-721 tokens, but with dynamic, on-chain traits that evolve based on owner interactions, time, interactions with other ACAs, and a unique "Chronos Energy" resource (an integrated ERC-20 token). The system will have a simple, flexible governance mechanism to adjust core parameters.

This concept involves:
1.  **Dynamic, On-Chain Traits:** Traits stored directly in the contract state, not just metadata.
2.  **Chronos Energy (CHR):** A native ERC-20 token within the same contract, consumed for actions and potentially generated.
3.  **ACA Interactions:** ACAs can interact with each other, influencing both participants' traits.
4.  **Mutation/Evolution:** A mechanism for ACAs to undergo significant, potentially probabilistic trait changes.
5.  **Time-Based Effects:** Traits can decay or grow based on the time since the last interaction.
6.  **Parameter Governance:** A simple voting system to adjust action costs, trait bounds, mutation rates, etc.
7.  **Integrated Design:** ERC-721 and ERC-20 functionalities coexist and interact within a single contract.

---

**Outline and Function Summary**

**Contract Name:** `AdaptiveChronicleAssets`

**Description:** A smart contract implementing dynamic, evolving ERC-721 tokens (Adaptive Chronicle Assets - ACAs) that consume and generate an integrated ERC-20 token (Chronos Energy - CHR). ACAs have on-chain traits that change based on owner actions, time, interaction with other ACAs, and mutation events. The system parameters are adjustable via a simple governance mechanism.

**Core Concepts:**
*   **ERC-721 Assets:** Ownable, transferable digital assets representing ACAs.
*   **ERC-20 Energy:** A fungible token (CHR) used as fuel for ACA actions and interactions.
*   **Dynamic Traits:** On-chain attributes for each ACA, changing over time and through actions.
*   **Action System:** Owner-initiated actions (consuming CHR) that affect an ACA's traits.
*   **Interaction System:** Protocol for two ACAs to interact, affecting both.
*   **Mutation System:** A process for drastic, semi-random trait changes.
*   **Time-Based Decay/Growth:** Traits can passively change based on inactivity or time elapsed.
*   **Parameter Governance:** A simple on-chain voting mechanism for ACA/CHR holders to adjust system configs.
*   **Treasury:** A pool of CHR tokens managed by governance.

**Function Summary:**

*   **ERC-721 Standard Functions (9):**
    1.  `balanceOf(address owner)`: Get the number of ACAs owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific ACA.
    3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer an ACA.
    4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer an ACA (less safe).
    5.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a specific ACA.
    6.  `getApproved(uint256 tokenId)`: Get the approved address for an ACA.
    7.  `setApprovalForAll(address operator, bool approved)`: Set approval for an operator for all owner's ACAs.
    8.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.
    9.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.

*   **ERC-20 Standard Functions (Chronos Energy - CHR) (10):**
    10. `name()`: Get the name of the CHR token.
    11. `symbol()`: Get the symbol of the CHR token.
    12. `decimals()`: Get the decimals of the CHR token.
    13. `totalSupply()`: Get the total supply of CHR.
    14. `balanceOf(address owner)`: Get the CHR balance of an address.
    15. `transfer(address to, uint256 amount)`: Transfer CHR.
    16. `transferFrom(address from, address to, uint256 amount)`: Transfer CHR via allowance.
    17. `approve(address spender, uint256 amount)`: Approve a spender for CHR.
    18. `allowance(address owner, address spender)`: Get the allowance for a spender.
    19. `mintCHR(address recipient, uint256 amount)`: Admin/Internal function to mint CHR (initially, could be removed later). *Making this public admin for setup counts it.*

*   **ACA & Chronos Energy Core Logic (Custom) (15):**
    20. `mintNewACA(address recipient)`: Mints a new ACA with initial traits.
    21. `getStoredACATraits(uint256 tokenId)`: Get the raw stored traits of an ACA.
    22. `getEffectiveACATraits(uint256 tokenId)`: Calculate and get the traits considering time-based effects.
    23. `performAction(uint256 tokenId, bytes32 actionType)`: Owner triggers an action for their ACA, consuming CHR and modifying traits.
    24. `interactWithACA(uint256 tokenId1, uint256 tokenId2, bytes32 interactionType)`: Owners initiate interaction between two ACAs, consuming CHR and modifying both sets of traits.
    25. `claimGeneratedEnergy(uint256 tokenId)`: Allows an ACA owner to claim CHR passively generated by their ACA based on its properties/time.
    26. `triggerMutation(uint256 tokenId)`: Attempts to mutate an ACA, potentially costing CHR and randomly/semi-deterministically changing traits.
    27. `donateEnergy(uint256 amount)`: Allows anyone to send CHR to the governance treasury.
    28. `getEnergyCostForAction(bytes32 actionType)`: View the CHR cost for a specific action type.
    29. `getEnergyCostForInteraction(bytes32 interactionType)`: View the CHR cost for a specific interaction type.
    30. `getActionConfig(bytes32 actionType)`: View configuration details for an action type.
    31. `getInteractionConfig(bytes32 interactionType)`: View configuration details for an interaction type.
    32. `getTraitParams(bytes32 traitType)`: View configuration parameters for a specific trait type (e.g., decay rate, bounds).
    33. `getTreasuryBalance()`: View the current CHR balance of the governance treasury.
    34. `getTotalACAs()`: Get the total number of minted ACAs.

*   **Governance Functions (6):**
    35. `proposeParameterChange(bytes32 paramName, uint256 newValue)`: Propose a specific system parameter change (e.g., action cost, mutation chance).
    36. `voteOnProposal(uint256 proposalId, bool support)`: Cast a vote on an active proposal (weighted by ACA ownership or CHR balance).
    37. `getProposalState(uint256 proposalId)`: Get the current state of a proposal (Pending, Active, Succeeded, Failed, Executed).
    38. `getProposalDetails(uint256 proposalId)`: Get details of a proposal.
    39. `queueProposal(uint256 proposalId)`: Moves a successful proposal into a timelock queue.
    40. `executeProposal(uint256 proposalId)`: Executes a proposal after the timelock expires.

*   **Admin/Configuration (4):**
    41. `registerActionType(bytes32 actionType, uint256 energyCost, bytes data)`: Admin/Governance function to define a new action type and its config.
    42. `registerInteractionType(bytes32 interactionType, uint256 energyCost, bytes data)`: Admin/Governance function to define a new interaction type and its config.
    43. `setTraitParams(bytes32 traitType, uint256 decayRate, uint256 growthRate, uint256 min, uint256 max, int256 influence)`: Admin/Governance function to set parameters for how traits change over time and via actions.
    44. `setBaseMutationChance(uint256 basisPoints)`: Admin/Governance function to set the base probability for mutation.

Total Functions: 9 (ERC721) + 10 (ERC20) + 15 (Core Logic) + 6 (Governance) + 4 (Admin) = 44 functions. This easily exceeds the requirement of 20 and covers diverse advanced concepts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath still useful for explicit checks in 0.8+ for clarity sometimes, but native checks are fine.

// Outline and Function Summary provided above the code block.

contract AdaptiveChronicleAssets is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // ERC721 State (Handled by ERC721 base)
    Counters.Counter private _acaTokenIds;

    // ERC20 State (Chronos Energy - CHR)
    string private _chrName = "Chronos Energy";
    string private _chrSymbol = "CHR";
    uint8 private _chrDecimals = 18;
    uint256 private _chrTotalSupply;
    mapping(address => uint256) private _chrBalances;
    mapping(address => mapping(address => uint256)) private _chrAllowances;

    // ACA Dynamic Traits
    struct ACATraits {
        // Example traits - could be many more
        int256 power;
        int256 resilience;
        int256 affinity; // Maybe affinity to certain action types
        uint256 mutationStage;
        uint256 lastInteractionTime; // For time-based effects
        uint256 accumulatedEnergyGenerated; // Energy generated by this specific ACA
        bytes traitsData; // Generic field for future traits or complex data
    }
    mapping(uint256 => ACATraits) private _acaTraits; // tokenId => traits

    // Trait Parameters (Governable)
    struct TraitParams {
        uint256 decayRatePerSecond; // How much trait decays per second of inactivity
        uint256 growthRatePerSecond; // How much trait grows per second of activity/certain state
        int256 min;
        int256 max;
        int256 actionInfluenceMultiplier; // Multiplier for how much actions affect this trait
        int256 interactionInfluenceMultiplier; // Multiplier for how much interactions affect this trait
    }
    mapping(bytes32 => TraitParams) private _traitParams; // traitType => params (e.g., "power" => params)

    // Action Configuration (Governable)
    struct ActionConfig {
        uint256 energyCost;
        bytes effectData; // Data defining how this action affects traits
    }
    mapping(bytes32 => ActionConfig) private _actionConfigs; // actionType => config

    // Interaction Configuration (Governable)
    struct InteractionConfig {
        uint256 energyCost;
        bytes effectData; // Data defining how this interaction affects traits (for both participants)
    }
    mapping(bytes32 => InteractionConfig) private _interactionConfigs; // interactionType => config

    // Mutation Parameters (Governable)
    uint256 private _baseMutationChanceBasisPoints; // Chance * 100 (e.g., 100 = 1%)
    uint256 private _mutationEnergyCost;

    // Governance
    struct Proposal {
        uint256 id;
        address proposer;
        bytes data; // Encodes the proposed change(s)
        uint256 voteCount; // Could be ACA count, CHR balance, or delegated votes
        uint256 minimumVotesRequired; // Quorum threshold
        uint256 votingDeadline;
        uint256 executionTimestamp; // Timelock for execution
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) private _proposals;
    enum ProposalState { Pending, Active, Succeeded, Failed, Queued, Expired, Executed, Canceled }
    uint256 public constant VOTING_PERIOD = 3 days; // Example period
    uint256 public constant QUORUM_BASIS_POINTS = 500; // 5% of total voting power needed for quorum
    uint256 public constant EXECUTION_TIMELOCK = 1 days; // Timelock after proposal success

    // Treasury
    address public immutable governanceTreasury; // Address receiving CHR from donations, actions, interactions

    // Pause Mechanism
    bool public paused = false;

    // Allowed Minters for ACA (initial setup, could be removed or set to governance)
    mapping(address => bool) private _allowedMinters;

    // --- Events ---

    event ACAMinted(address indexed owner, uint256 indexed tokenId, ACATraits initialTraits);
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitType, int256 oldValue, int256 newValue);
    event ActionPerformed(uint256 indexed tokenId, bytes32 indexed actionType, uint256 energyCost);
    event InteractionPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2, bytes32 indexed interactionType, uint256 energyCost);
    event EnergyClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event MutationTriggered(uint256 indexed tokenId, uint256 energyCost, bool mutated);
    event EnergyDonated(address indexed donator, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes data);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ParameterChanged(bytes32 indexed paramName, uint256 indexed proposalId, uint256 newValue); // More specific event for executable proposals

    // ERC20 standard events Transfer, Approval handled by internal functions/OZ

    // --- Constructor ---

    constructor(address initialOwner, address _governanceTreasury)
        ERC721("Adaptive Chronicle Asset", "ACA")
        Ownable(initialOwner)
    {
        require(_governanceTreasury != address(0), "Treasury cannot be zero address");
        governanceTreasury = _governanceTreasury;

        // Initial minting allowance for owner (example)
        _allowedMinters[initialOwner] = true;

        // Set some initial default trait parameters (Governable later)
        _setTraitParams("power", 1, 0, 0, 100, 1); // decay 1/sec, growth 0, min 0, max 100, influence 1x
        _setTraitParams("resilience", 0, 1, 0, 100, 1); // decay 0, growth 1/sec, min 0, max 100, influence 1x
        _setTraitParams("affinity", 2, 0, -50, 50, 2); // decay 2/sec, growth 0, min -50, max 50, influence 2x

        // Set some initial default mutation parameters (Governable later)
        _baseMutationChanceBasisPoints = 500; // 5% base chance
        _mutationEnergyCost = 100 ether; // Example cost
    }

    // --- Modifier ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAllowedMinter() {
        require(_allowedMinters[_msgSender()], "Not an allowed minter");
        _;
    }

    // --- ERC-721 Standard Functions (Mostly inherited/handled by OZ) ---
    // Implementations are handled by ERC721 base contract, only override if adding logic.
    // We count these as they are part of the public interface.

    // 1. balanceOf - Inherited
    // 2. ownerOf - Inherited
    // 3. safeTransferFrom - Inherited
    // 4. transferFrom - Inherited
    // 5. approve - Inherited
    // 6. getApproved - Inherited
    // 7. setApprovalForAll - Inherited
    // 8. isApprovedForAll - Inherited
    // 9. supportsInterface - Inherited

    // Override needed for potential trait decay/sync on transfer - Keeping it simple, decay calculated on trait access
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721) // Use batchSize in 0.8+ override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Optional: Could update traits here based on time elapsed for the token
        // _updateTraitsBasedOnTime(tokenId); // Or do this only when traits are fetched/modified
        if (from != address(0)) {
             // If transferring from a non-zero address, calculate and claim any accumulated energy
             uint256 generated = _calculateGeneratedEnergy(tokenId);
             if (generated > 0) {
                _issueCHR(from, generated); // Give generated energy to the *sender*
                _acaTraits[tokenId].accumulatedEnergyGenerated = 0; // Reset accumulator
             }
        }
    }

    // --- ERC-20 Standard Functions (Chronos Energy - CHR) ---
    // Implementing standard ERC20 functions for the internal CHR token.

    // 10. name()
    function name() public view returns (string memory) {
        // This returns the ERC721 name, need CHR name separately
        // Let's create a separate function for CHR details or make the internal state public
        return _chrName;
    }

    // 11. symbol()
    function symbol() public view returns (string memory) {
        // This returns the ERC721 symbol, need CHR symbol separately
        return _chrSymbol;
    }

    // 12. decimals()
    function decimals() public view returns (uint8) {
         return _chrDecimals;
    }

    // 13. totalSupply()
    function totalSupply() public view returns (uint256) {
        return _chrTotalSupply;
    }

    // 14. balanceOf(address account)
    function balanceOf(address account) public view returns (uint256) {
        return _chrBalances[account];
    }

    // 15. transfer(address recipient, uint256 amount)
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // 16. transferFrom(address sender, address recipient, uint256 amount)
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _chrAllowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _safeApprove(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    // 17. approve(address spender, uint256 amount)
    function approve(address spender, uint256 amount) public returns (bool) {
        _safeApprove(_msgSender(), spender, amount);
        return true;
    }

    // 18. allowance(address owner, address spender)
    function allowance(address owner, address spender) public view returns (uint256) {
        return _chrAllowances[owner][spender];
    }

    // Internal CHR transfer/mint/burn functions
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _chrBalances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _chrBalances[sender] = senderBalance - amount;
        }
        _chrBalances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // 19. mintCHR(address recipient, uint256 amount) - Admin/Owner function for initial supply or emergencies
    function mintCHR(address recipient, uint256 amount) public onlyOwner {
        _issueCHR(recipient, amount);
    }

    function _issueCHR(address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: mint to the zero address");
        _chrTotalSupply += amount;
        _chrBalances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function _burnCHR(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _chrBalances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _chrBalances[account] = accountBalance - amount;
        }
        _chrTotalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _safeApprove(address owner, address spender, uint256 amount) internal {
        _chrAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- ACA & Chronos Energy Core Logic ---

    // 20. mintNewACA(address recipient)
    function mintNewACA(address recipient) public whenNotPaused onlyAllowedMinter returns (uint256) {
        uint256 newItemId = _acaTokenIds.current();
        _acaTokenIds.increment();
        _safeMint(recipient, newItemId);

        // Initialize traits - Example with base values
        _acaTraits[newItemId] = ACATraits({
            power: int256(uint256(keccak256(abi.encodePacked(newItemId, block.timestamp, "power"))) % 50) + 25, // Randomish initial power
            resilience: int256(uint256(keccak256(abi.encodePacked(newItemId, block.timestamp, "res"))) % 50) + 25, // Randomish initial resilience
            affinity: 0, // Start neutral affinity
            mutationStage: 0,
            lastInteractionTime: block.timestamp,
            accumulatedEnergyGenerated: 0,
            traitsData: "" // Empty initial data
        });

        emit ACAMinted(recipient, newItemId, _acaTraits[newItemId]);
        return newItemId;
    }

    // 21. getStoredACATraits(uint256 tokenId)
    function getStoredACATraits(uint256 tokenId) public view returns (ACATraits memory) {
         _requireOwnedOrApproved(tokenId);
        return _acaTraits[tokenId];
    }

    // 22. getEffectiveACATraits(uint256 tokenId) - Calculates traits including time effects
    function getEffectiveACATraits(uint256 tokenId) public view returns (ACATraits memory effectiveTraits) {
         _requireOwnedOrApproved(tokenId); // Only owner or approved can view effective traits? Or public view? Public view is more transparent.
        ACATraits storage storedTraits = _acaTraits[tokenId];
        effectiveTraits = storedTraits; // Start with stored values

        uint256 timeElapsed = block.timestamp - storedTraits.lastInteractionTime;

        // Apply time-based decay/growth (Example logic)
        // Ensure traits stay within bounds
        if (_traitParams["power"].decayRatePerSecond > 0) {
            effectiveTraits.power = effectiveTraits.power - int256(timeElapsed * _traitParams["power"].decayRatePerSecond);
        }
         if (_traitParams["resilience"].growthRatePerSecond > 0) {
            effectiveTraits.resilience = effectiveTraits.resilience + int256(timeElapsed * _traitParams["resilience"].growthRatePerSecond);
        }
         if (_traitParams["affinity"].decayRatePerSecond > 0) {
             effectiveTraits.affinity = effectiveTraits.affinity - int256(timeElapsed * _traitParams["affinity"].decayRatePerSecond);
         }

        // Clamp traits within min/max bounds
        effectiveTraits.power = effectiveTraits.power > _traitParams["power"].max ? _traitParams["power"].max : effectiveTraits.power;
        effectiveTraits.power = effectiveTraits.power < _traitParams["power"].min ? _traitParams["power"].min : effectiveTraits.power;
        effectiveTraits.resilience = effectiveTraits.resilience > _traitParams["resilience"].max ? _traitParams["resilience"].max : effectiveTraits.resilience;
        effectiveTraits.resilience = effectiveTraits.resilience < _traitParams["resilience"].min ? _traitParams["resilience"].min : effectiveTraits.resilience;
        effectiveTraits.affinity = effectiveTraits.affinity > _traitParams["affinity"].max ? _traitParams["affinity"].max : effectiveTraits.affinity;
        effectiveTraits.affinity = effectiveTraits.affinity < _traitParams["affinity"].min ? _traitParams["affinity"].min : effectiveTraits.affinity;

        // Note: This calculation doesn't save the effective traits, they are calculated on demand.
        // The stored traits are updated only on actions, interactions, mutations, or claims.
    }

    // Internal function to update stored traits based on time effects
    function _updateTraitsBasedOnTime(uint256 tokenId) internal {
        ACATraits storage traits = _acaTraits[tokenId];
        uint256 timeElapsed = block.timestamp - traits.lastInteractionTime;

        if (timeElapsed == 0) return; // No time elapsed, no change

        // Calculate decay/growth amounts
        int256 powerChange = 0;
        if (_traitParams["power"].decayRatePerSecond > 0) {
             powerChange = -int256(timeElapsed * _traitParams["power"].decayRatePerSecond);
        }
        int256 resilienceChange = 0;
         if (_traitParams["resilience"].growthRatePerSecond > 0) {
             resilienceChange = int256(timeElapsed * _traitParams["resilience"].growthRatePerSecond);
         }
        int256 affinityChange = 0;
         if (_traitParams["affinity"].decayRatePerSecond > 0) {
              affinityChange = -int256(timeElapsed * _traitParams["affinity"].decayRatePerSecond);
         }

        // Apply changes and clamp
        _applyTraitChange(tokenId, "power", powerChange);
        _applyTraitChange(tokenId, "resilience", resilienceChange);
        _applyTraitChange(tokenId, "affinity", affinityChange);

        traits.lastInteractionTime = block.timestamp; // Update time marker
    }

    // Internal helper to apply trait changes with bounds checking and events
    function _applyTraitChange(uint256 tokenId, bytes32 traitType, int256 change) internal {
        ACATraits storage traits = _acaTraits[tokenId];
        TraitParams storage params = _traitParams[traitType];

        int256 oldValue;
        int256 newValue;

        // Use a simple mapping or if-else for trait type application
        if (traitType == "power") {
            oldValue = traits.power;
            newValue = oldValue + change;
            // Clamp
            newValue = newValue > params.max ? params.max : newValue;
            newValue = newValue < params.min ? params.min : newValue;
            traits.power = newValue;
        } else if (traitType == "resilience") {
            oldValue = traits.resilience;
            newValue = oldValue + change;
             // Clamp
            newValue = newValue > params.max ? params.max : newValue;
            newValue = newValue < params.min ? params.min : newValue;
            traits.resilience = newValue;
        } else if (traitType == "affinity") {
             oldValue = traits.affinity;
            newValue = oldValue + change;
             // Clamp
            newValue = newValue > params.max ? params.max : newValue;
            newValue = newValue < params.min ? params.min : newValue;
            traits.affinity = newValue;
        }
        // Add more trait types here as needed

        if (oldValue != newValue) {
            emit TraitUpdated(tokenId, traitType, oldValue, newValue);
        }
    }

    // 23. performAction(uint256 tokenId, bytes32 actionType)
    function performAction(uint256 tokenId, bytes32 actionType) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to perform action for this ACA");
        ActionConfig storage config = _actionConfigs[actionType];
        require(config.energyCost > 0 || actionType != bytes32(0), "Invalid or unregistered action type");

        // Ensure owner has enough energy
        require(_chrBalances[_msgSender()] >= config.energyCost, "Insufficient Chronos Energy");

        // Update traits based on time elapsed since last activity
        _updateTraitsBasedOnTime(tokenId);

        // Apply action effects based on config.effectData (Simplified example)
        // In a real system, parsing `effectData` would involve complex abi.decode and logic.
        // Here, we'll just simulate a generic trait change based on `actionType`.
        // Example: "train_power" action increases power, "rest" increases resilience.

        if (actionType == "train_power") {
            _applyTraitChange(tokenId, "power", 5 * _traitParams["power"].actionInfluenceMultiplier); // Example: +5 power * multiplier
        } else if (actionType == "rest") {
            _applyTraitChange(tokenId, "resilience", 3 * _traitParams["resilience"].actionInfluenceMultiplier); // Example: +3 resilience * multiplier
        } else if (actionType == "explore") {
             _applyTraitChange(tokenId, "affinity", 1 * _traitParams["affinity"].actionInfluenceMultiplier); // Example: +1 affinity * multiplier
             // Explore might also generate energy
             uint256 generated = uint256(int256(10) + _acaTraits[tokenId].affinity / 2); // Base + half affinity
             _acaTraits[tokenId].accumulatedEnergyGenerated += generated;
        }
        // Add more action types and effects based on `actionType` and `config.effectData`

        // Consume energy
        _transfer(_msgSender(), governanceTreasury, config.energyCost);

        // Update last interaction time (already done in _updateTraitsBasedOnTime)
        // _acaTraits[tokenId].lastInteractionTime = block.timestamp;

        emit ActionPerformed(tokenId, actionType, config.energyCost);
    }

    // 24. interactWithACA(uint256 tokenId1, uint256 tokenId2, bytes32 interactionType)
    function interactWithACA(uint256 tokenId1, uint256 tokenId2, bytes32 interactionType) public whenNotPaused {
        // Require authorization for both tokens
        require(_isApprovedOrOwner(_msgSender(), tokenId1), "Not authorized for ACA 1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "Not authorized for ACA 2");
        require(tokenId1 != tokenId2, "ACAs cannot interact with themselves");

        InteractionConfig storage config = _interactionConfigs[interactionType];
        require(config.energyCost > 0 || interactionType != bytes32(0), "Invalid or unregistered interaction type");

        // Decide who pays the energy cost (e.g., only initiator, split, or depends on interaction type)
        // Let's make the initiator pay for simplicity
        require(_chrBalances[_msgSender()] >= config.energyCost, "Insufficient Chronos Energy");

        // Update traits based on time for both ACAs
        _updateTraitsBasedOnTime(tokenId1);
        _updateTraitsBasedOnTime(tokenId2);

        // Apply interaction effects based on `interactionType` and `config.effectData` (Simplified example)
        // Example: "spar" reduces resilience of both, increases power slightly.
        // "bond" increases resilience and affinity of both.

         if (interactionType == "spar") {
            _applyTraitChange(tokenId1, "resilience", int256(-3) * _traitParams["resilience"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId2, "resilience", int256(-3) * _traitParams["resilience"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId1, "power", int256(1) * _traitParams["power"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId2, "power", int256(1) * _traitParams["power"].interactionInfluenceMultiplier);
        } else if (interactionType == "bond") {
            _applyTraitChange(tokenId1, "resilience", int256(2) * _traitParams["resilience"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId2, "resilience", int256(2) * _traitParams["resilience"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId1, "affinity", int256(3) * _traitParams["affinity"].interactionInfluenceMultiplier);
            _applyTraitChange(tokenId2, "affinity", int256(3) * _traitParams["affinity"].interactionInfluenceMultiplier);
        }
        // Add more interaction types and effects

        // Consume energy
        _transfer(_msgSender(), governanceTreasury, config.energyCost);

        // Update last interaction time for both (already done by _updateTraitsBasedOnTime)
        // _acaTraits[tokenId1].lastInteractionTime = block.timestamp;
        // _acaTraits[tokenId2].lastInteractionTime = block.timestamp;

        emit InteractionPerformed(tokenId1, tokenId2, interactionType, config.energyCost);
    }

    // Internal helper to calculate energy generated by an ACA
    function _calculateGeneratedEnergy(uint256 tokenId) internal view returns (uint256) {
        ACATraits storage traits = _acaTraits[tokenId];
        // Simple example: Base generation + small amount based on power + accumulated from actions
        // In a real system, this could be complex and time-based.
        // For this example, let's just return the accumulated amount from actions like "explore".
        return traits.accumulatedEnergyGenerated;
    }

    // 25. claimGeneratedEnergy(uint256 tokenId)
    function claimGeneratedEnergy(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to claim energy for this ACA");
        uint256 generated = _calculateGeneratedEnergy(tokenId);

        if (generated > 0) {
            _issueCHR(_msgSender(), generated);
            _acaTraits[tokenId].accumulatedEnergyGenerated = 0; // Reset accumulator

            // Maybe update traits slightly on claiming? E.g., increase resilience from "resting"
            // _updateTraitsBasedOnTime(tokenId); // This is already done implicitly if needed before trait checks
            // _applyTraitChange(tokenId, "resilience", 1); // Small bonus?

            emit EnergyClaimed(tokenId, _msgSender(), generated);
        }
    }

    // 26. triggerMutation(uint256 tokenId)
    function triggerMutation(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to mutate this ACA");
        require(_chrBalances[_msgSender()] >= _mutationEnergyCost, "Insufficient Chronos Energy for mutation");

         _updateTraitsBasedOnTime(tokenId); // Ensure traits are up-to-date before mutation check

        // Consume energy first
        _transfer(_msgSender(), governanceTreasury, _mutationEnergyCost);

        // Determine if mutation occurs (Example based on base chance + traits)
        // Pseudo-randomness on chain is tricky; block.timestamp/block.difficulty are bad.
        // Using blockhash is slightly better but deprecated/limited. VRF is ideal but complex.
        // Simple example using block.timestamp and trait values for pseudo-randomness.
        uint256 randFactor = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, tx.origin, _acaTraits[tokenId].power, _acaTraits[tokenId].mutationStage)));
        uint256 totalChance = _baseMutationChanceBasisPoints + uint256(int256(_acaTraits[tokenId].affinity)); // Affinity could increase chance
        if (totalChance > 10000) totalChance = 10000; // Max 100% chance

        bool mutated = (randFactor % 10000) < totalChance;

        if (mutated) {
            // Apply mutation effects (Example: large random changes within bounds)
            _applyTraitChange(tokenId, "power", int256(randFactor % (_traitParams["power"].max - _traitParams["power"].min)) + _traitParams["power"].min - _acaTraits[tokenId].power);
            _applyTraitChange(tokenId, "resilience", int256((randFactor / 100) % (_traitParams["resilience"].max - _traitParams["resilience"].min)) + _traitParams["resilience"].min - _acaTraits[tokenId].resilience);
            _applyTraitChange(tokenId, "affinity", int256((randFactor / 1000) % (_traitParams["affinity"].max - _traitParams["affinity"].min)) + _traitParams["affinity"].min - _acaTraits[tokenId].affinity);

            _acaTraits[tokenId].mutationStage++; // Increment mutation stage
            // Reset accumulated energy on mutation? Or keep it? Let's reset for simplicity.
            _acaTraits[tokenId].accumulatedEnergyGenerated = 0;
        }

        // Update last interaction time
        _acaTraits[tokenId].lastInteractionTime = block.timestamp;

        emit MutationTriggered(tokenId, _mutationEnergyCost, mutated);
    }

    // 27. donateEnergy(uint256 amount)
    function donateEnergy(uint256 amount) public whenNotPaused {
        require(_chrBalances[_msgSender()] >= amount, "Insufficient Chronos Energy balance to donate");
        _transfer(_msgSender(), governanceTreasury, amount);
        emit EnergyDonated(_msgSender(), amount);
    }

    // 28. getEnergyCostForAction(bytes32 actionType)
    function getEnergyCostForAction(bytes32 actionType) public view returns (uint256) {
        return _actionConfigs[actionType].energyCost;
    }

    // 29. getEnergyCostForInteraction(bytes32 interactionType)
    function getEnergyCostForInteraction(bytes32 interactionType) public view returns (uint256) {
        return _interactionConfigs[interactionType].energyCost;
    }

    // 30. getActionConfig(bytes32 actionType)
    function getActionConfig(bytes32 actionType) public view returns (ActionConfig memory) {
        return _actionConfigs[actionType];
    }

    // 31. getInteractionConfig(bytes32 interactionType)
    function getInteractionConfig(bytes32 interactionType) public view returns (InteractionConfig memory) {
        return _interactionConfigs[interactionType];
    }

    // 32. getTraitParams(bytes32 traitType)
    function getTraitParams(bytes32 traitType) public view returns (TraitParams memory) {
        return _traitParams[traitType];
    }

    // 33. getTreasuryBalance()
    function getTreasuryBalance() public view returns (uint256) {
        return _chrBalances[governanceTreasury];
    }

     // 34. getTotalACAs() - Helper view function for ERC721 count
    function getTotalACAs() public view returns (uint256) {
        return _acaTokenIds.current();
    }


    // --- Governance Functions ---
    // Simple governance: Propose parameter change -> Vote (ACA or CHR weighted) -> Queue -> Execute
    // Voting power: Let's use 1 vote per ACA owned for simplicity in this example.
    // A more complex system would track delegated votes or use CHR balance/staking.

    function _getVotingPower(address account) internal view returns (uint256) {
        // Example: 1 vote per ACA owned
        return balanceOf(account); // Using ERC721 balanceOf
        // Alternative: return balanceOf(account); // Using CHR balanceOf
    }

    // 35. proposeParameterChange(bytes32 paramName, uint256 newValue)
    function proposeParameterChange(bytes data) public whenNotPaused returns (uint256 proposalId) {
        // Data should encode the specific function call and parameters to be executed
        // Example: data = abi.encodeCall(this.setBaseMutationChance, (newValue))
        require(data.length > 0, "Proposal data cannot be empty");
        require(_getVotingPower(_msgSender()) > 0, "Proposer must have voting power");

        proposalId = _proposalIds.current();
        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            data: data,
            voteCount: 0, // Votes start at 0
            minimumVotesRequired: _acaTokenIds.current().mul(QUORUM_BASIS_POINTS).div(10000), // Quorum based on total ACAs
            votingDeadline: block.timestamp + VOTING_PERIOD,
            executionTimestamp: 0, // Not queued yet
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        _proposalIds.increment();

        emit ProposalCreated(proposalId, _msgSender(), data);
        return proposalId;
    }

    // 36. voteOnProposal(uint256 proposalId, bool support)
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id == proposalId, "Invalid proposal ID");
        require(getProposalState(proposalId) == ProposalState.Active, "Proposal not active");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        uint256 voterVotes = _getVotingPower(_msgSender());
        require(voterVotes > 0, "Voter must have voting power");

        proposal.voteCount += voterVotes; // Simplified: only counting 'support' votes towards threshold

        proposal.hasVoted[_msgSender()] = true;

        emit Voted(proposalId, _msgSender(), support, voterVotes);
    }

    // 37. getProposalState(uint256 proposalId)
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId || proposal.proposer == address(0)) {
             return ProposalState.Pending; // Or Undefined, indicating it doesn't exist
        }
        if (proposal.canceled) return ProposalState.Canceled;
        if (proposal.executed) return ProposalState.Executed;
        if (proposal.votingDeadline == 0 || block.timestamp <= proposal.votingDeadline) return ProposalState.Active; // Active includes Pending before deadline
        if (proposal.executionTimestamp > 0 && block.timestamp < proposal.executionTimestamp) return ProposalState.Queued; // Succeeded and waiting
        if (proposal.voteCount >= proposal.minimumVotesRequired) return ProposalState.Succeeded;
        if (block.timestamp > proposal.votingDeadline) return ProposalState.Expired; // Passed deadline, not executed/succeeded

        return ProposalState.Failed; // Default failed if conditions not met
    }

    // 38. getProposalDetails(uint256 proposalId)
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        bytes memory data,
        uint256 voteCount,
        uint256 minimumVotesRequired,
        uint256 votingDeadline,
        uint256 executionTimestamp,
        bool executed,
        bool canceled,
        ProposalState state
    ) {
        Proposal storage proposal = _proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.data,
            proposal.voteCount,
            proposal.minimumVotesRequired,
            proposal.votingDeadline,
            proposal.executionTimestamp,
            proposal.executed,
            proposal.canceled,
            getProposalState(proposalId)
        );
    }


    // 39. queueProposal(uint256 proposalId)
    function queueProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal must be in Succeeded state");
        require(proposal.executionTimestamp == 0, "Proposal already queued or executed");

        proposal.executionTimestamp = block.timestamp + EXECUTION_TIMELOCK;
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    // 40. executeProposal(uint256 proposalId)
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Queued, "Proposal not in Queued state");
        require(block.timestamp >= proposal.executionTimestamp, "Execution timelock has not expired");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        // --- Execute the proposal data ---
        // WARNING: This is a simplified example. Executing arbitrary bytes can be dangerous!
        // In a real DAO, you'd have safe whitelisted functions or a more structured proposal data format.
        // Here, we assume proposal.data is abi.encodeCall(targetContract.function, (params...))
        // For simplicity, let's assume it calls a function on *this* contract (self-calling)
        (bool success, ) = address(this).call(proposal.data);
        require(success, "Proposal execution failed");
        // --- End Execution ---

        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        // Emit a more specific event about what was changed, if possible to decode from data
        // This requires knowing the structure of `proposal.data`
         bytes memory callData = proposal.data;
         bytes4 selector;
         assembly { selector := mload(add(callData, 0x20)) } // Read first 4 bytes after length prefix
         // Example: If selector matches setBaseMutationChance, try to decode
         bytes4 setMutationChanceSelector = this.setBaseMutationChance.selector;
         if (selector == setMutationChanceSelector && callData.length >= 36) { // selector (4) + uint256 (32)
            uint256 newValue;
             assembly { newValue := mload(add(callData, 0x24)) } // Read uint256 after selector
             emit ParameterChanged("baseMutationChance", proposalId, newValue);
         }
         // Add decoding logic for other specific governenace functions called by proposals
         // e.g., registerActionType, setTraitParams, transferEnergyFromTreasury etc.
         // This is complex and often handled off-chain for display, or requires a structured proposal type.

    }

    // 41. cancelProposal(uint256 proposalId) - Can be called by proposer if not Active/Succeeded/Queued/Executed
    function cancelProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id == proposalId, "Invalid proposal ID");
        require(proposal.proposer == _msgSender(), "Only proposer can cancel");
        ProposalState currentState = getProposalState(proposalId);
        require(currentState != ProposalState.Succeeded && currentState != ProposalState.Queued && currentState != ProposalState.Executed, "Cannot cancel proposal in Succeeded, Queued, or Executed state");
        require(!proposal.canceled, "Proposal already canceled");

        proposal.canceled = true;
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }


    // --- Admin/Configuration Functions ---
    // These are initially onlyOwner, but can be called via successful governance proposals

    // 42. registerActionType(bytes32 actionType, uint256 energyCost, bytes data)
    function registerActionType(bytes32 actionType, uint256 energyCost, bytes memory data) public onlyOwnerOrGovernance {
        _actionConfigs[actionType] = ActionConfig({
            energyCost: energyCost,
            effectData: data
        });
        // Emit event?
    }

    // 43. registerInteractionType(bytes32 interactionType, uint256 energyCost, bytes memory data)
    function registerInteractionType(bytes32 interactionType, uint256 energyCost, bytes memory data) public onlyOwnerOrGovernance {
        _interactionConfigs[interactionType] = InteractionConfig({
            energyCost: energyCost,
            effectData: data
        });
        // Emit event?
    }

    // 44. setTraitParams(bytes32 traitType, uint256 decayRate, uint256 growthRate, int256 min, int256 max, int256 influence)
    function setTraitParams(bytes32 traitType, uint256 decayRate, uint256 growthRate, int256 min, int256 max, int256 influence) public onlyOwnerOrGovernance {
         _traitParams[traitType] = TraitParams({
             decayRatePerSecond: decayRate,
             growthRatePerSecond: growthRate,
             min: min,
             max: max,
             actionInfluenceMultiplier: influence, // Using influence for action
             interactionInfluenceMultiplier: influence // Using influence for interaction - could be separate fields
         });
        // Emit event?
    }

    // 45. setBaseMutationChance(uint256 basisPoints)
    function setBaseMutationChance(uint256 basisPoints) public onlyOwnerOrGovernance {
        _baseMutationChanceBasisPoints = basisPoints;
        // Emit event? (Handled by ParameterChanged if called via governance)
    }

     // 46. setMutationEnergyCost(uint256 cost)
    function setMutationEnergyCost(uint256 cost) public onlyOwnerOrGovernance {
        _mutationEnergyCost = cost;
        // Emit event? (Handled by ParameterChanged if called via governance)
    }

    // Helper modifier to allow owner or execution via governance
    modifier onlyOwnerOrGovernance() {
        // Check if called by the owner or by the contract itself (implying governance execution)
        require(owner() == _msgSender() || _isExecutingGovernanceProposal(), "Not authorized (Owner or Governance)");
        _;
    }

    // Internal check to see if the current call is originating from a governance proposal execution call
    function _isExecutingGovernanceProposal() internal view returns (bool) {
        // This is a simplified check. A robust DAO execution would use specific flags or context.
        // Here, we check if the caller is *this contract's* address, which is true when `address(this).call(...)` is used.
        return _msgSender() == address(this);
    }

    // Additional helper function to allow governance to transfer energy from the treasury
    // This function itself would be called by `executeProposal`
    function transferEnergyFromTreasury(address recipient, uint256 amount) public onlyOwnerOrGovernance {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(_chrBalances[governanceTreasury] >= amount, "Treasury has insufficient energy");
        _transfer(governanceTreasury, recipient, amount);
        // Emit specific event for treasury withdrawal if needed
    }

     // Admin function to add/remove allowed minters (can also be governed)
     function addAllowedMinter(address minter) public onlyOwnerOrGovernance {
         _allowedMinters[minter] = true;
         // Emit event?
     }

     function removeAllowedMinter(address minter) public onlyOwnerOrGovernance {
         _allowedMinters[minter] = false;
         // Emit event?
     }

     // View function to check if an address is an allowed minter
     function isAllowedMinter(address minter) public view returns (bool) {
         return _allowedMinters[minter];
     }

     // Internal helper to require ownership or approval (used in multiple places)
     function _requireOwnedOrApproved(uint256 tokenId) internal view {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized for this ACA");
     }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic On-Chain Traits:** Instead of static metadata, `ACATraits` are stored directly in contract storage (`_acaTraits`). These can be read and modified by contract functions.
2.  **Time-Based Evolution:** `getEffectiveACATraits` and `_updateTraitsBasedOnTime` demonstrate how traits can change passively based on the time elapsed since the `lastInteractionTime`. This adds a layer of state complexity and incentivizes/disincentivizes inactivity depending on the trait parameters (decay/growth rates).
3.  **Integrated ERC-20 Energy:** The `Chronos Energy (CHR)` token is managed *within* the same contract using internal ERC-20 logic (`_chrBalances`, `_transfer`, `_issueCHR`, `_burnCHR`). This tightly couples the asset (ACA) and its resource (CHR), enabling actions to directly consume/generate CHR from/to user balances.
4.  **Action & Interaction Systems:** `performAction` and `interactWithACA` are core functions allowing owners to spend CHR to influence their ACA's traits or facilitate interactions between two ACAs, affecting both. The `bytes data` in `ActionConfig` and `InteractionConfig` allows for flexible, data-driven effects that can be defined via governance without changing core logic (though the *interpretation* of this data within the function still needs logic).
5.  **Mutation System:** `triggerMutation` introduces a probabilistic element (`_baseMutationChanceBasisPoints` + trait influence) and potentially drastic, semi-random trait changes, adding unpredictability and an evolutionary aspect.
6.  **Parameter Governance:** A basic DAO structure (`Proposal`, `voteOnProposal`, `executeProposal`, `queueProposal`, `cancelProposal`) allows holders with voting power (e.g., ACA owners) to propose and vote on changes to system parameters (`setTraitParams`, `setBaseMutationChance`, `registerActionType`, etc.). This moves control away from a single admin and makes the system adaptive. The `bytes data` for proposals and the `executeProposal` function allow calling specific, pre-approved functions on the contract, enabling parameter tuning or even adding new action/interaction types via governance. The `onlyOwnerOrGovernance` modifier enforces that certain sensitive functions can only be called by the initial owner OR by the contract itself *during* a governance execution.
7.  **Treasury Management:** CHR consumed by actions/interactions goes into a `governanceTreasury` address, which can then be managed (e.g., distributed) via governance proposals (`transferEnergyFromTreasury`).
8.  **Accumulated Energy:** The `accumulatedEnergyGenerated` field and `claimGeneratedEnergy` function allow ACAs to "generate" energy over time or through specific actions (like 'explore' in the example), which the owner can claim, creating a feedback loop.

This contract provides a framework for dynamic, interactive, and community-governed digital assets that are far more complex than standard static NFTs or simple tokens. It integrates multiple token standards and introduces novel mechanics for state change and system evolution.

*Note: A production-ready contract would require significant additions, including more robust error handling, comprehensive event emissions, gas optimizations, potentially a more sophisticated governance implementation (e.g., weighted voting, delegation, off-chain voting with on-chain execution), more detailed data structures for action/interaction effects, and thorough security audits.*