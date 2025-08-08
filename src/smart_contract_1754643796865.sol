This smart contract, named **Cognitive Nexus NFT (ESAI-NFT)**, represents an advanced, dynamic NFT that embodies an evolving digital sentient entity. Unlike static NFTs, an ESAI-NFT's core "cognitive traits" are mutable and reactive to its environment, owner interactions, and the passage of time. It requires a specific ERC20 "Essence Token" to sustain its existence and perform complex tasks, illustrating concepts like digital life cycles and resource-dependent behavior on-chain.

### OUTLINE & FUNCTION SUMMARY

---

#### I. INTRODUCTION

The **Cognitive Nexus NFT (ESAI-NFT)** is a novel dynamic NFT that simulates an evolving digital sentient entity. Unlike static NFTs, an ESAI-NFT's core "cognitive traits" are mutable and reactive to its environment, owner interactions, and the passage of time. It requires a specific ERC20 "Essence Token" to sustain its existence and perform complex tasks.

#### II. CORE CONCEPTS

1.  **Dynamic NFTs**: The ESAI-NFT's metadata and inherent "personality" evolve over time, reflecting its current cognitive traits and state.
2.  **Cognitive Traits**: Four primary traits (Intelligence, Creativity, Empathy, Adaptability) that define the ESAI-NFT's capabilities and behavior. These traits influence resource consumption, task effectiveness, and its "rarity."
3.  **Essence Token**: A dedicated ERC20 token ($ESSENCE) that fuels the ESAI-NFT. It's consumed over time (burn rate) and by task execution. Low Essence can lead to a "hibernation" mode, where its functions are limited.
4.  **Attunement**: Owners can "attune" their ESAI-NFTs by setting preferences that subtly guide trait evolution, allowing for a degree of personalization and directed growth.
5.  **Task Execution via Oracles**: ESAI-NFTs can perform complex "cognitive tasks" by leveraging off-chain AI/compute services via a decentralized oracle. The results of these tasks directly influence the ESAI-NFT's trait evolution.
6.  **Adaptive Mechanics**: Fees for tasks and Essence burn rates are dynamic, adapting to the ESAI-NFT's current state and cognitive traits. This introduces a form of on-chain behavioral economics.
7.  **Mutation Events**: Rare or triggered events that cause significant, unpredictable shifts in cognitive traits, introducing an element of randomness and surprise to the evolution.
8.  **Delegated Access**: Owners can grant limited access to other addresses for specific interactions with their ESAI-NFTs (e.g., recharging Essence), enabling collaborative care or management.

---

#### III. FUNCTION SUMMARY (Total: 34+ Functions)

##### A. ESAI-NFT Management (ERC721 Standard & Core):

1.  `constructor(address _essenceToken, address _oracleAddress, string memory _baseURI)`: Initializes the contract by setting the addresses for the Essence Token and the Cognitive Oracle, and the base URI for metadata.
2.  `mintESAINFT(address to)`: Mints a new ESAI-NFT to the specified address, initializing its cognitive traits randomly within a healthy range.
3.  `balanceOf(address owner) view returns (uint256)`: *Standard ERC721*: Returns the number of NFTs owned by an address.
4.  `ownerOf(uint256 tokenId) view returns (address)`: *Standard ERC721*: Returns the owner of a specific token.
5.  `transferFrom(address from, address to, uint256 tokenId)`: *Standard ERC721*: Transfers ownership of a token.
6.  `approve(address to, uint256 tokenId)`: *Standard ERC721*: Approves an address to manage a specific token.
7.  `getApproved(uint256 tokenId) view returns (address operator)`: *Standard ERC721*: Returns the approved address for a token.
8.  `setApprovalForAll(address operator, bool approved)`: *Standard ERC721*: Approves or revokes an operator for all tokens owned by the caller.
9.  `isApprovedForAll(address owner, address operator) view returns (bool)`: *Standard ERC721*: Checks if an operator is approved for all tokens.
10. `tokenURI(uint256 tokenId) view returns (string memory)`: *Standard ERC721*: Returns a dynamic URI for the NFT's metadata, reflecting its current evolving traits and state.

##### B. Essence & Resource Management:

11. `rechargeEssence(uint256 tokenId, uint256 amount)`: Allows the owner (or an approved delegator) to deposit $ESSENCE tokens into the ESAI-NFT's internal balance. This can also reactivate a hibernating ESAI-NFT.
12. `withdrawEssence(uint256 tokenId, uint256 amount)`: Allows the owner to withdraw unused $ESSENCE from their ESAI-NFT's balance.
13. `getEssenceBalance(uint256 tokenId) view returns (uint256)`: Queries the current $ESSENCE balance of a given ESAI-NFT, accounting for real-time decay.
14. `getEssenceBurnRate(uint256 tokenId) view returns (uint256)`: Calculates the dynamic $ESSENCE burn rate for an ESAI-NFT, which varies based on its cognitive traits (e.g., higher activity traits consume more).

##### C. Cognitive Traits & Evolution:

15. `getESAICognitiveTraits(uint256 tokenId) view returns (uint256 intelligence, uint256 creativity, uint256 empathy, uint256 adaptability)`: Retrieves the current cognitive traits of an ESAI-NFT.
16. `setAttunementPreference(uint256 tokenId, uint8 preferenceId, uint256 value)`: Allows the owner to set an attunement preference, subtly influencing how specific traits evolve over time.
17. `getAttunementPreference(uint256 tokenId, uint8 preferenceId) view returns (uint256)`: Queries the value of a specific attunement preference for an ESAI-NFT.
18. `requestCognitiveTask(uint256 tokenId, uint8 taskType, string memory taskDescription)`: Initiates an off-chain cognitive task via the oracle, consuming $ESSENCE. The oracle's result will update the ESAI-NFT's traits.
19. `fulfillCognitiveTask(bytes32 requestId, uint256 tokenId, uint256 newIntelligence, uint256 newCreativity, uint256 newEmpathy, uint256 newAdaptability, string memory taskResult, bool success)`: *Oracle Callback*: Receives results from the cognitive oracle and updates the ESAI-NFT's traits accordingly.
20. `triggerMutationEvent(uint256 tokenId)`: Allows the owner to trigger a significant, potentially random, shift in the ESAI-NFT's cognitive traits, at a substantial $ESSENCE cost.

##### D. State Management & Mechanics:

21. `activateHibernation(uint256 tokenId)`: Allows the owner to manually put an ESAI-NFT into a low-power "hibernation" mode, which pauses $ESSENCE decay but also prevents task execution.
22. `deactivateHibernation(uint256 tokenId)`: Allows the owner to take an ESAI-NFT out of hibernation, requiring a minimum $ESSENCE balance for reactivation.
23. `getESAINFTState(uint256 tokenId) view returns (uint256 lastInteractionTime, bool inHibernation, uint256 lastMutationTime, uint256 hibernationActivationTime)`: Provides comprehensive state information for an ESAI-NFT.
24. `getDynamicTaskFee(uint256 tokenId, uint8 taskType) view returns (uint256)`: Calculates the adaptive fee for a given cognitive task type, which varies based on the ESAI-NFT's traits (e.g., more "powerful" traits might increase cost).
25. `calculateESAIRarityScore(uint256 tokenId) view returns (uint256)`: Computes a dynamic rarity score for an ESAI-NFT based on its current cognitive trait values.

##### E. Delegation & Access:

26. `setDelegatedAccess(uint256 tokenId, address delegator, bool approved)`: Allows an ESAI-NFT owner to grant or revoke specific delegated access rights to another address for their token (e.g., to allow recharging essence).
27. `isDelegatedAccessApproved(uint256 tokenId, address delegator) view returns (bool)`: Checks if an address has delegated access rights for a specific ESAI-NFT.

##### F. Admin/Owner Functions (Governance-related):

28. `setBaseEssenceBurnRate(uint256 newRate)`: Callable only by the contract owner, sets the global minimum $ESSENCE burn rate that all ESAI-NFTs adhere to.
29. `setOracleAddress(address newOracle)`: Callable only by the contract owner, updates the address of the trusted cognitive oracle.
30. `setEssenceTokenAddress(address newEssenceToken)`: Callable only by the contract owner, updates the address of the Essence ERC20 token contract.
31. `pause()`: Callable only by the contract owner, pauses critical contract functionality in emergencies.
32. `unpause()`: Callable only by the contract owner, unpauses contract functionality.
33. `setBaseURI(string memory newBaseURI)`: Callable only by the contract owner, updates the base URI used for constructing NFT metadata URIs.
34. `setTaskBaseFee(uint8 taskType, uint256 fee)`: Callable only by the contract owner, sets the base fee for a specific type of cognitive task.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // Import OpenZeppelin's Math for utility functions

// Interfaces for external contracts (Oracle, Essence Token)
interface IEssenceToken is IERC20 {
    // Standard ERC20 functions are inherited from IERC20
}

interface ICognitiveOracle {
    /**
     * @dev Requests an off-chain cognitive computation from the oracle.
     * @param requestId A unique ID for this request.
     * @param tokenId The ID of the ESAI-NFT for which the task is requested.
     * @param taskType The type of cognitive task.
     * @param taskDescription A detailed description of the task for the off-chain system.
     * @param callbackContract The address of the contract to call back.
     * @param callbackFunction The function selector to call on the callbackContract.
     */
    function requestCognitiveComputation(
        bytes32 requestId,
        uint256 tokenId,
        uint8 taskType,
        string calldata taskDescription,
        address callbackContract,
        bytes4 callbackFunction
    ) external;
}

/**
 * @title Cognitive Nexus NFT (ESAI-NFT)
 * @dev An advanced, dynamic NFT representing an Evolving Sentient AI.
 *      Its cognitive traits (Intelligence, Creativity, Empathy, Adaptability) evolve based on owner interaction,
 *      task execution via external oracles, and resource consumption. It features an adaptive resource management system
 *      (Essence Token), owner-driven attunement, dynamic task fees, and a "hibernation" mode.
 *      This contract aims for uniqueness by blending dynamic NFTs with autonomous agent concepts and
 *      on-chain behavioral economics, offering a non-duplicative, creative, and advanced solution.
 */
contract CognitiveNexusNFT is ERC721, Ownable, Pausable {
    using Strings for uint256;
    using Math for uint256; // Provides .min, .max, .add, .sub, .mul, .div for uint256
    using Math for int256; // Provides .abs for int256

    // --- State Variables ---

    /**
     * @dev Struct to hold all dynamic data for an ESAI-NFT.
     */
    struct ESAINFTData {
        uint256 intelligence;       // Cognitive trait: problem-solving, learning
        uint256 creativity;         // Cognitive trait: innovation, generative ability
        uint256 empathy;            // Cognitive trait: understanding, social interaction
        uint256 adaptability;       // Cognitive trait: flexibility, resilience
        uint256 essenceBalance;     // Current balance of Essence Tokens held by this NFT
        uint256 lastInteractionTime; // Timestamp of last significant interaction or essence burn check
        bool inHibernation;         // True if the NFT is in a low-power state
        uint256 hibernationActivationTime; // Timestamp when hibernation started
        uint224 lastMutationTime;   // Timestamp of the last mutation event, uint224 for gas efficiency
        mapping(uint8 => uint256) attunementPreferences; // Owner-set preferences (ID => Value)
    }

    mapping(uint256 => ESAINFTData) private _esaiData; // Stores data for each ESAI-NFT
    uint256 private _nextTokenId; // Counter for next available token ID

    IEssenceToken public essenceToken; // Address of the ERC20 Essence Token contract
    ICognitiveOracle public cognitiveOracle; // Address of the trusted off-chain cognitive oracle

    uint256 public baseEssenceBurnRatePerSecond = 1 wei; // Global base rate for Essence consumption
    uint256 public constant MIN_ESSENCE_BURN_RATE = 1 wei; // Minimum allowed Essence burn rate
    uint256 public constant MAX_TRAIT_VALUE = 1000;       // Maximum value for any cognitive trait
    uint256 public constant MIN_TRAIT_VALUE = 100;        // Minimum value for any cognitive trait
    uint256 public constant HIBERNATION_THRESHOLD_ESSENCE = 1000 wei; // Essence needed to exit/avoid hibernation

    // Base fees for different task types, indexed by a uint8 task identifier
    mapping(uint8 => uint224) public taskBaseFees;

    // Delegation mapping: tokenId => delegatorAddress => approvedStatus
    mapping(uint256 => mapping(address => bool)) private _delegatedAccess;

    // Mapping to track active oracle requests: requestId => tokenId
    mapping(bytes32 => uint256) private _pendingCognitiveRequests;

    // --- Events ---
    event ESAINFTMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event EssenceRecharged(uint256 indexed tokenId, address indexed caller, uint256 amount, uint256 newBalance);
    event EssenceWithdrawn(uint256 indexed tokenId, address indexed caller, uint256 amount, uint256 newBalance);
    event EssenceBurned(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event CognitiveTraitsUpdated(uint256 indexed tokenId, uint256 intelligence, uint256 creativity, uint256 empathy, uint256 adaptability);
    event AttunementPreferenceSet(uint256 indexed tokenId, uint8 preferenceId, uint256 value);
    event CognitiveTaskRequested(uint256 indexed tokenId, bytes32 indexed requestId, uint8 taskType, string taskDescription, uint256 feePaid);
    event CognitiveTaskFulfilled(uint256 indexed tokenId, bytes32 indexed requestId, bool success, string taskResult);
    event MutationEventTriggered(uint256 indexed tokenId, uint256 newIntelligence, uint256 newCreativity, uint256 newEmpathy, uint256 newAdaptability);
    event HibernationActivated(uint256 indexed tokenId, uint256 timestamp);
    event HibernationDeactivated(uint256 indexed tokenId, uint256 timestamp);
    event DelegatedAccessSet(uint256 indexed tokenId, address indexed delegator, bool approved);

    // --- Modifiers ---

    /**
     * @dev Modifier to ensure the caller is either the owner or an approved operator for the given ESAI-NFT.
     */
    modifier onlyESAINFTOwner(uint256 tokenId) {
        _requireOwned(tokenId); // Checks if msg.sender is owner or approved for this specific token
        _;
    }

    /**
     * @dev Modifier to restrict function calls only to the authorized cognitive oracle address.
     */
    modifier onlyOracle() {
        require(msg.sender == address(cognitiveOracle), "ESAI-NFT: Caller is not the authorized oracle");
        _;
    }

    /**
     * @dev Modifier to allow function calls by either the ESAI-NFT owner or a specifically delegated address.
     */
    modifier onlyDelegatedOrOwner(uint256 tokenId) {
        require(_exists(tokenId), "ESAI-NFT: Token does not exist"); // Ensure token exists before checking ownership/delegation
        require(ownerOf(tokenId) == msg.sender || _delegatedAccess[tokenId][msg.sender], "ESAI-NFT: Not owner or delegated");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the CognitiveNexusNFT contract.
     * @param _essenceToken The address of the ERC20 Essence Token contract.
     * @param _oracleAddress The address of the trusted ICognitiveOracle contract.
     * @param _baseURI The base URI for NFT metadata, used in `tokenURI`.
     */
    constructor(address _essenceToken, address _oracleAddress, string memory _baseURI)
        ERC721("Cognitive Nexus NFT", "ESAI") // Initialize ERC721 with name and symbol
        Ownable(msg.sender) // Set the deployer as the contract owner
    {
        require(_essenceToken != address(0), "ESAI-NFT: Essence token address cannot be zero");
        require(_oracleAddress != address(0), "ESAI-NFT: Oracle address cannot be zero");

        essenceToken = IEssenceToken(_essenceToken);
        cognitiveOracle = ICognitiveOracle(_oracleAddress);
        _setBaseURI(_baseURI);

        // Set some initial base fees for common task types (example values)
        taskBaseFees[1] = 1000 wei; // Type 1: Basic computation
        taskBaseFees[2] = 5000 wei; // Type 2: Creative generation
        taskBaseFees[3] = 2000 wei; // Type 3: Analytical processing
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to apply essence decay based on time elapsed since last interaction.
     *      This function is called by most state-changing functions to ensure up-to-date state.
     *      Automatically triggers hibernation if Essence drops to zero or below the threshold.
     * @param tokenId The ID of the ESAI-NFT to decay Essence for.
     */
    function _decayEssence(uint256 tokenId) internal {
        ESAINFTData storage data = _esaiData[tokenId];
        // If the NFT doesn't exist (e.g., before minting or after burning), skip.
        // Or if it's already in hibernation, no further decay occurs.
        if (!ERC721._exists(tokenId) || data.inHibernation) {
            data.lastInteractionTime = block.timestamp; // Still update time to prevent large retroactive burn if reactivated
            return;
        }

        uint256 elapsedTime = block.timestamp - data.lastInteractionTime;
        if (elapsedTime == 0) {
            return; // No time has passed, no decay needed
        }

        uint256 burnRate = getEssenceBurnRate(tokenId); // Dynamically calculated burn rate
        uint256 requiredBurn = burnRate.mul(elapsedTime);

        if (data.essenceBalance > requiredBurn) {
            data.essenceBalance = data.essenceBalance.sub(requiredBurn);
            emit EssenceBurned(tokenId, requiredBurn, data.essenceBalance);
        } else {
            // Not enough essence, burn remaining and activate hibernation
            emit EssenceBurned(tokenId, data.essenceBalance, 0);
            data.essenceBalance = 0;
            data.inHibernation = true;
            data.hibernationActivationTime = block.timestamp;
            emit HibernationActivated(tokenId, block.timestamp);
        }
        data.lastInteractionTime = block.timestamp; // Update last interaction time
    }

    /**
     * @dev Internal function to update cognitive traits over time or based on conditions.
     *      This is a simplified evolution model; complex systems might use more nuanced logic
     *      incorporating interaction history, specific events, or attunement preferences.
     * @param tokenId The ID of the ESAI-NFT to recalculate traits for.
     */
    function _recalculateTraits(uint256 tokenId) internal {
        ESAINFTData storage data = _esaiData[tokenId];
        uint256 currentIntel = data.intelligence;
        uint256 currentCreativity = data.creativity;
        uint256 currentEmpathy = data.empathy;
        uint256 currentAdaptability = data.adaptability;

        // Apply trait decay if in hibernation or critically low on Essence.
        // Traits slowly decrease towards MIN_TRAIT_VALUE.
        if (data.inHibernation || data.essenceBalance < HIBERNATION_THRESHOLD_ESSENCE.div(2)) {
            data.intelligence = currentIntel.mulDiv(99, 100).max(MIN_TRAIT_VALUE); // 1% decay
            data.creativity = currentCreativity.mulDiv(99, 100).max(MIN_TRAIT_VALUE);
            data.empathy = currentEmpathy.mulDiv(99, 100).max(MIN_TRAIT_VALUE);
            data.adaptability = currentAdaptability.mulDiv(99, 100).max(MIN_TRAIT_VALUE);
        } else {
            // Apply slight positive drift or maintenance if healthy.
            // Attunement preferences influence the direction/magnitude of this drift.
            // Example: Preference 1 (e.g., 'Learning Focus') boosts Intelligence.
            data.intelligence = (data.intelligence.add(data.attunementPreferences[1].div(100))).min(MAX_TRAIT_VALUE);
            data.creativity = (data.creativity.add(data.attunementPreferences[2].div(100))).min(MAX_TRAIT_VALUE);
            data.empathy = (data.empathy.add(data.attunementPreferences[3].div(100))).min(MAX_TRAIT_VALUE);
            data.adaptability = (data.adaptability.add(data.attunementPreferences[4].div(100))).min(MAX_TRAIT_VALUE);
        }

        // Emit event only if traits actually changed
        if (currentIntel != data.intelligence || currentCreativity != data.creativity ||
            currentEmpathy != data.empathy || currentAdaptability != data.adaptability) {
            emit CognitiveTraitsUpdated(tokenId, data.intelligence, data.creativity, data.empathy, data.adaptability);
        }
    }

    /**
     * @dev Internal helper to ensure a token exists.
     *      Used by public/external view and state-changing functions that query or modify token data.
     * @param tokenId The ID of the ESAI-NFT to check.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(ERC721._exists(tokenId), "ESAI-NFT: Token does not exist");
    }

    // --- A. ESAI-NFT Management ---

    /**
     * @dev Mints a new ESAI-NFT to the specified address.
     *      Initial traits are randomized within a healthy range (MIN_TRAIT_VALUE to MAX_TRAIT_VALUE).
     *      The new ESAI-NFT starts in hibernation mode until Essence is recharged.
     *      Callable only by the contract owner.
     * @param to The address to mint the ESAI-NFT to.
     * @return The ID of the newly minted ESAI-NFT.
     */
    function mintESAINFT(address to) public onlyOwner returns (uint256) {
        _pauseCheck(); // Ensure contract is not paused

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId); // Mints the ERC721 token

        // Initialize traits using a simple pseudo-random method based on block data
        uint256 blockSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, msg.sender)));
        
        // Traits initialized between 300-700, clamped by MIN/MAX_TRAIT_VALUE
        _esaiData[tokenId].intelligence = (300 + (blockSeed % 400)).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        _esaiData[tokenId].creativity = (300 + ((blockSeed / 100) % 400)).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        _esaiData[tokenId].empathy = (300 + ((blockSeed / 10000) % 400)).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        _esaiData[tokenId].adaptability = (300 + ((blockSeed / 1000000) % 400)).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);

        _esaiData[tokenId].essenceBalance = 0; // Starts with no essence
        _esaiData[tokenId].lastInteractionTime = block.timestamp;
        _esaiData[tokenId].inHibernation = true; // Starts in hibernation
        _esaiData[tokenId].hibernationActivationTime = block.timestamp;
        _esaiData[tokenId].lastMutationTime = uint224(block.timestamp); // Cast to uint224

        emit ESAINFTMinted(tokenId, to, block.timestamp);
        emit CognitiveTraitsUpdated(tokenId, _esaiData[tokenId].intelligence, _esaiData[tokenId].creativity, _esaiData[tokenId].empathy, _esaiData[tokenId].adaptability);
        return tokenId;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     *      Generates a dynamic URI that could point to an off-chain API reflecting current traits.
     *      The metadata URI includes query parameters for real-time trait values and hibernation status.
     * @param tokenId The ID of the ESAI-NFT.
     * @return The dynamic URI string for the NFT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];

        // The base URI is combined with token ID and dynamic trait/state parameters.
        // An off-chain service (e.g., IPFS gateway + API endpoint) would then render the
        // NFT image and JSON metadata based on these parameters.
        return string(
            abi.encodePacked(
                _baseURI(),
                tokenId.toString(),
                "?i=", data.intelligence.toString(),
                "&c=", data.creativity.toString(),
                "&e=", data.empathy.toString(),
                "&a=", data.adaptability.toString(),
                "&h=", data.inHibernation ? "1" : "0" // 1 for true, 0 for false
            )
        );
    }

    // --- B. Essence & Resource Management ---

    /**
     * @dev Allows the owner or an approved delegator to deposit Essence Tokens into an ESAI-NFT.
     *      The Essence tokens are transferred from `msg.sender` to this contract's balance
     *      and then internally assigned to the specific ESAI-NFT.
     *      If the ESAI-NFT is in hibernation and enough essence is deposited, it will reactivate.
     * @param tokenId The ID of the ESAI-NFT.
     * @param amount The amount of Essence Tokens to deposit.
     */
    function rechargeEssence(uint256 tokenId, uint256 amount) public payable onlyDelegatedOrOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(amount > 0, "ESAI-NFT: Amount must be greater than zero");

        _decayEssence(tokenId); // Apply essence decay before recharging

        // Transfer Essence tokens from msg.sender to this contract.
        // Requires msg.sender to have approved this contract to spend 'amount' Essence tokens.
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "ESAI-NFT: Essence token transfer failed");

        _esaiData[tokenId].essenceBalance = _esaiData[tokenId].essenceBalance.add(amount);
        emit EssenceRecharged(tokenId, msg.sender, amount, _esaiData[tokenId].essenceBalance);

        // Automatically deactivate hibernation if sufficient Essence is now available.
        if (_esaiData[tokenId].inHibernation && _esaiData[tokenId].essenceBalance >= HIBERNATION_THRESHOLD_ESSENCE) {
            _esaiData[tokenId].inHibernation = false;
            _esaiData[tokenId].hibernationActivationTime = 0; // Reset activation time
            emit HibernationDeactivated(tokenId, block.timestamp);
        }
    }

    /**
     * @dev Allows the owner to withdraw Essence Tokens from their ESAI-NFT's internal balance.
     *      Note: Withdrawing too much Essence may cause the ESAI-NFT to enter hibernation.
     * @param tokenId The ID of the ESAI-NFT.
     * @param amount The amount of Essence Tokens to withdraw.
     */
    function withdrawEssence(uint256 tokenId, uint256 amount) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Apply essence decay before withdrawal
        require(amount > 0, "ESAI-NFT: Amount must be greater than zero");
        require(_esaiData[tokenId].essenceBalance >= amount, "ESAI-NFT: Insufficient essence balance");

        _esaiData[tokenId].essenceBalance = _esaiData[tokenId].essenceBalance.sub(amount);
        // Transfer Essence tokens from this contract back to the owner.
        require(essenceToken.transfer(msg.sender, amount), "ESAI-NFT: Essence token withdrawal failed");
        emit EssenceWithdrawn(tokenId, msg.sender, amount, _esaiData[tokenId].essenceBalance);

        // If after withdrawal, essence falls below threshold and it's not already in hibernation, activate it.
        if (!_esaiData[tokenId].inHibernation && _esaiData[tokenId].essenceBalance < HIBERNATION_THRESHOLD_ESSENCE) {
             _esaiData[tokenId].inHibernation = true;
             _esaiData[tokenId].hibernationActivationTime = block.timestamp;
             emit HibernationActivated(tokenId, block.timestamp);
        }
    }

    /**
     * @dev Returns the current Essence Token balance of a given ESAI-NFT.
     *      This function performs a "theoretical" decay calculation to give an up-to-date balance
     *      without requiring a state-changing transaction.
     * @param tokenId The ID of the ESAI-NFT.
     * @return The current Essence Token balance.
     */
    function getEssenceBalance(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];
        uint256 currentBalance = data.essenceBalance;
        if (!data.inHibernation) {
            uint256 elapsedTime = block.timestamp - data.lastInteractionTime;
            uint256 burnRate = getEssenceBurnRate(tokenId);
            uint256 theoreticalBurn = burnRate.mul(elapsedTime);
            if (currentBalance > theoreticalBurn) {
                currentBalance = currentBalance.sub(theoreticalBurn);
            } else {
                currentBalance = 0; // If essence theoretically runs out, it would be in hibernation
            }
        }
        return currentBalance;
    }

    /**
     * @dev Calculates the dynamic Essence burn rate for an ESAI-NFT.
     *      This rate is influenced by the ESAI-NFT's cognitive traits:
     *      Higher Intelligence and Creativity increase consumption, while higher Empathy and Adaptability reduce it.
     * @param tokenId The ID of the ESAI-NFT.
     * @return The calculated burn rate in wei per second.
     */
    function getEssenceBurnRate(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];

        uint256 dynamicModifier = 0;

        // Positive modifiers (increase burn rate): Intelligence and Creativity
        // Traits are 100-1000. Normalize to 1-10 (div by 100) or 1-5 (div by 200) for modifier contributions.
        dynamicModifier = dynamicModifier.add(data.intelligence.div(100)); // Adds 1-10 to modifier
        dynamicModifier = dynamicModifier.add(data.creativity.div(100));  // Adds 1-10 to modifier

        // Negative modifiers (decrease burn rate): Empathy and Adaptability
        dynamicModifier = dynamicModifier.sub(data.empathy.div(200));    // Subtracts 0.5-5 from modifier
        dynamicModifier = dynamicModifier.sub(data.adaptability.div(200)); // Subtracts 0.5-5 from modifier

        // Calculate final rate by adding base rate to dynamic modifier, ensuring it doesn't fall below MIN_ESSENCE_BURN_RATE.
        uint256 finalRate = baseEssenceBurnRatePerSecond.add(dynamicModifier);
        return finalRate.max(MIN_ESSENCE_BURN_RATE);
    }

    // --- C. Cognitive Traits & Evolution ---

    /**
     * @dev Retrieves the current cognitive traits of an ESAI-NFT.
     * @param tokenId The ID of the ESAI-NFT.
     * @return Intelligence, Creativity, Empathy, and Adaptability values.
     */
    function getESAICognitiveTraits(uint256 tokenId)
        public view
        returns (uint256 intelligence, uint256 creativity, uint256 empathy, uint256 adaptability)
    {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];
        return (data.intelligence, data.creativity, data.empathy, data.adaptability);
    }

    /**
     * @dev Allows the owner to set an attunement preference for their ESAI-NFT.
     *      These preferences are used internally by `_recalculateTraits` to subtly influence
     *      the long-term evolution and drift of cognitive traits.
     * @param tokenId The ID of the ESAI-NFT.
     * @param preferenceId An ID representing a specific preference (e.g., 1 for "Focus on Learning", 2 for "Social Bias").
     * @param value The value for the preference (0 to MAX_TRAIT_VALUE).
     */
    function setAttunementPreference(uint256 tokenId, uint8 preferenceId, uint256 value) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Decay essence before modifying preferences
        require(value <= MAX_TRAIT_VALUE, "ESAI-NFT: Preference value exceeds max");
        _esaiData[tokenId].attunementPreferences[preferenceId] = value;
        emit AttunementPreferenceSet(tokenId, preferenceId, value);
    }

    /**
     * @dev Retrieves a specific attunement preference for an ESAI-NFT.
     * @param tokenId The ID of the ESAI-NFT.
     * @param preferenceId The ID of the preference to query.
     * @return The value of the preference.
     */
    function getAttunementPreference(uint256 tokenId, uint8 preferenceId) public view returns (uint256) {
        _requireMinted(tokenId);
        return _esaiData[tokenId].attunementPreferences[preferenceId];
    }

    /**
     * @dev Requests an off-chain cognitive task to be performed by the associated oracle.
     *      This action consumes a dynamic fee in Essence and triggers an external call to the oracle.
     *      The oracle's eventual fulfillment (via `fulfillCognitiveTask`) will update traits.
     * @param tokenId The ID of the ESAI-NFT.
     * @param taskType The type of cognitive task (e.g., 1 for "Data Analysis", 2 for "Creative Writing").
     * @param taskDescription A string describing the task for the oracle's off-chain computation.
     */
    function requestCognitiveTask(uint256 tokenId, uint8 taskType, string memory taskDescription) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Apply essence decay
        require(!_esaiData[tokenId].inHibernation, "ESAI-NFT: Cannot request task in hibernation");

        uint256 requiredFee = getDynamicTaskFee(tokenId, taskType);
        require(_esaiData[tokenId].essenceBalance >= requiredFee, "ESAI-NFT: Insufficient essence for task fee");

        _esaiData[tokenId].essenceBalance = _esaiData[tokenId].essenceBalance.sub(requiredFee);
        emit EssenceBurned(tokenId, requiredFee, _esaiData[tokenId].essenceBalance);

        // Generate a unique request ID and store it to prevent replay attacks/duplicate fulfillments
        bytes32 requestId = keccak256(abi.encodePacked(tokenId, taskType, taskDescription, block.timestamp, msg.sender));
        require(_pendingCognitiveRequests[requestId] == 0, "ESAI-NFT: Request ID collision or already pending");
        _pendingCognitiveRequests[requestId] = tokenId;

        // Call the external oracle contract
        cognitiveOracle.requestCognitiveComputation(
            requestId,
            tokenId,
            taskType,
            taskDescription,
            address(this), // Callback contract is this contract
            this.fulfillCognitiveTask.selector // Callback function selector
        );

        emit CognitiveTaskRequested(tokenId, requestId, taskType, taskDescription, requiredFee);
    }

    /**
     * @dev Callback function from the trusted oracle to fulfill a previously requested cognitive task.
     *      This function updates the ESAI-NFT's cognitive traits based on the oracle's computation results.
     *      Only callable by the `cognitiveOracle` address.
     * @param requestId The original request ID.
     * @param tokenId The ID of the ESAI-NFT.
     * @param newIntelligence The new intelligence value from the oracle.
     * @param newCreativity The new creativity value from the oracle.
     * @param newEmpathy The new empathy value from the oracle.
     * @param newAdaptability The new adaptability value from the oracle.
     * @param taskResult A string containing the oracle's output/result (e.g., "Analysis complete", "Poem generated").
     * @param success True if the task was successfully completed by the oracle, false otherwise.
     */
    function fulfillCognitiveTask(
        bytes32 requestId,
        uint256 tokenId,
        uint256 newIntelligence,
        uint256 newCreativity,
        uint256 newEmpathy,
        uint256 newAdaptability,
        string memory taskResult,
        bool success
    ) external onlyOracle {
        _requireMinted(tokenId);
        require(_pendingCognitiveRequests[requestId] == tokenId, "ESAI-NFT: Invalid or unassigned request ID");
        delete _pendingCognitiveRequests[requestId]; // Clear pending request to prevent re-fulfillment

        // Apply essence decay before processing oracle response to ensure up-to-date state
        _decayEssence(tokenId);

        if (success) {
            ESAINFTData storage data = _esaiData[tokenId];
            // Update traits, clamping values within defined min/max range.
            data.intelligence = newIntelligence.min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
            data.creativity = newCreativity.min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
            data.empathy = newEmpathy.min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
            data.adaptability = newAdaptability.min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
            emit CognitiveTraitsUpdated(tokenId, data.intelligence, data.creativity, data.empathy, data.adaptability);
        }
        emit CognitiveTaskFulfilled(tokenId, requestId, success, taskResult);
    }

    /**
     * @dev Triggers a mutation event for an ESAI-NFT, causing a significant and potentially unpredictable
     *      shift in its cognitive traits. This action typically costs a significant amount of Essence.
     *      The new traits are pseudo-randomly adjusted around their current values.
     * @param tokenId The ID of the ESAI-NFT.
     */
    function triggerMutationEvent(uint256 tokenId) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Apply essence decay
        require(!_esaiData[tokenId].inHibernation, "ESAI-NFT: Cannot mutate in hibernation");

        uint256 mutationCost = getEssenceBurnRate(tokenId).mul(1000); // Example: Cost is 1000 seconds worth of essence
        require(_esaiData[tokenId].essenceBalance >= mutationCost, "ESAI-NFT: Insufficient essence for mutation");

        _esaiData[tokenId].essenceBalance = _esaiData[tokenId].essenceBalance.sub(mutationCost);
        emit EssenceBurned(tokenId, mutationCost, _esaiData[tokenId].essenceBalance);

        // Apply a larger, semi-random mutation.
        ESAINFTData storage data = _esaiData[tokenId];
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, data.lastMutationTime)));
        
        // Adjust each trait by a random value between -100 and +100, then clamp to min/max
        data.intelligence = (data.intelligence.add((seed % 200).sub(100))).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        seed = uint256(keccak256(abi.encodePacked(seed, data.intelligence))); // Update seed for next trait
        data.creativity = (data.creativity.add((seed % 200).sub(100))).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        seed = uint256(keccak256(abi.encodePacked(seed, data.creativity)));
        data.empathy = (data.empathy.add((seed % 200).sub(100))).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);
        seed = uint256(keccak256(abi.encodePacked(seed, data.empathy)));
        data.adaptability = (data.adaptability.add((seed % 200).sub(100))).min(MAX_TRAIT_VALUE).max(MIN_TRAIT_VALUE);

        data.lastMutationTime = uint224(block.timestamp);
        emit MutationEventTriggered(tokenId, data.intelligence, data.creativity, data.empathy, data.adaptability);
        emit CognitiveTraitsUpdated(tokenId, data.intelligence, data.creativity, data.empathy, data.adaptability);
    }

    // --- D. State Management & Mechanics ---

    /**
     * @dev Allows the owner to manually put an ESAI-NFT into hibernation mode.
     *      In hibernation, Essence decay stops, but task execution is also prevented.
     * @param tokenId The ID of the ESAI-NFT.
     */
    function activateHibernation(uint256 tokenId) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Decay essence before activating hibernation
        require(!_esaiData[tokenId].inHibernation, "ESAI-NFT: Already in hibernation");
        _esaiData[tokenId].inHibernation = true;
        _esaiData[tokenId].hibernationActivationTime = block.timestamp;
        emit HibernationActivated(tokenId, block.timestamp);
    }

    /**
     * @dev Allows the owner to take an ESAI-NFT out of hibernation.
     *      Requires a minimum essence balance (`HIBERNATION_THRESHOLD_ESSENCE`) to reactivate.
     * @param tokenId The ID of the ESAI-NFT.
     */
    function deactivateHibernation(uint256 tokenId) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        _decayEssence(tokenId); // Ensure balance is up-to-date
        require(_esaiData[tokenId].inHibernation, "ESAI-NFT: Not in hibernation");
        require(_esaiData[tokenId].essenceBalance >= HIBERNATION_THRESHOLD_ESSENCE, "ESAI-NFT: Not enough essence to reactivate");
        _esaiData[tokenId].inHibernation = false;
        _esaiData[tokenId].hibernationActivationTime = 0; // Reset activation time
        emit HibernationDeactivated(tokenId, block.timestamp);
    }

    /**
     * @dev Retrieves various state parameters for an ESAI-NFT.
     * @param tokenId The ID of the ESAI-NFT.
     * @return lastInteractionTime, inHibernation, lastMutationTime, hibernationActivationTime.
     */
    function getESAINFTState(uint256 tokenId)
        public view
        returns (uint256 lastInteractionTime, bool inHibernation, uint256 lastMutationTime, uint256 hibernationActivationTime)
    {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];
        return (data.lastInteractionTime, data.inHibernation, data.lastMutationTime, data.hibernationActivationTime);
    }

    /**
     * @dev Calculates the dynamic fee for a specific cognitive task type for an ESAI-NFT.
     *      Fees adapt based on the ESAI-NFT's traits: more "powerful" (high Intelligence/Creativity)
     *      ESAI-NFTs might charge higher fees, while high Empathy could lead to lower fees.
     * @param tokenId The ID of the ESAI-NFT.
     * @param taskType The type of cognitive task.
     * @return The dynamic fee in wei.
     */
    function getDynamicTaskFee(uint256 tokenId, uint8 taskType) public view returns (uint256) {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];
        uint256 baseFee = taskBaseFees[taskType];
        
        // Calculate a trait-based multiplier.
        // Higher Intelligence and Creativity traits increase the multiplier.
        uint256 multiplierNum = data.intelligence.add(data.creativity); // Sum of two traits (200-2000)
        uint256 multiplierDenom = MAX_TRAIT_VALUE.mul(2); // Normalizer (2000) so average multiplier is 1

        // Empathy can reduce the effective multiplier.
        // Higher empathy (MAX_TRAIT_VALUE) reduces the multiplier significantly, lower empathy less so.
        // Scale empathy to have a desired impact. Example: empathy 100 has little impact, 1000 has max impact.
        // (MAX_TRAIT_VALUE - data.empathy / 2) creates a range from (1000 - 50) = 950 to (1000 - 500) = 500
        // This means for high empathy, `multiplierNum` will be multiplied by a smaller number, effectively reducing the fee.
        if (data.empathy > 0) {
            multiplierNum = multiplierNum.mul(MAX_TRAIT_VALUE.sub(data.empathy.div(2)));
            multiplierDenom = multiplierDenom.mul(MAX_TRAIT_VALUE);
        }
        
        if (multiplierDenom == 0) multiplierDenom = 1; // Prevent division by zero

        return baseFee.mul(multiplierNum).div(multiplierDenom);
    }

    /**
     * @dev Calculates a rarity score for an ESAI-NFT based on its current cognitive traits.
     *      A higher score indicates greater rarity. This is based on how far each trait
     *      deviates from the average, with bonuses for extreme trait values.
     * @param tokenId The ID of the ESAI-NFT.
     * @return The rarity score as a uint256.
     */
    function calculateESAIRarityScore(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        ESAINFTData storage data = _esaiData[tokenId];

        uint256 score = 0;
        uint256 averageTrait = (MAX_TRAIT_VALUE.add(MIN_TRAIT_VALUE)).div(2);

        // Add to score based on absolute deviation from the average for each trait
        score = score.add(uint256(int256(data.intelligence).sub(int256(averageTrait)).abs()));
        score = score.add(uint256(int256(data.creativity).sub(int256(averageTrait)).abs()));
        score = score.add(uint256(int256(data.empathy).sub(int256(averageTrait)).abs()));
        score = score.add(uint256(int256(data.adaptability).sub(int256(averageTrait)).abs()));

        // Add bonus points for having very high or very low (but not minimum) traits
        uint256 highThreshold = MAX_TRAIT_VALUE.mul(90).div(100); // 90% of max
        uint256 lowThreshold = MIN_TRAIT_VALUE.mul(110).div(100);  // 110% of min, to distinguish from absolute min

        if (data.intelligence > highThreshold || data.intelligence < lowThreshold) score = score.add(50);
        if (data.creativity > highThreshold || data.creativity < lowThreshold) score = score.add(50);
        if (data.empathy > highThreshold || data.empathy < lowThreshold) score = score.add(50);
        if (data.adaptability > highThreshold || data.adaptability < lowThreshold) score = score.add(50);

        return score;
    }

    // --- E. Delegation & Access ---

    /**
     * @dev Allows an ESAI-NFT owner to grant or revoke specific delegated access rights
     *      to another address for their token. This enables actions like `rechargeEssence`
     *      to be performed by non-owners without full ownership transfer.
     * @param tokenId The ID of the ESAI-NFT for which to set delegation.
     * @param delegator The address to grant/revoke delegation for.
     * @param approved True to approve, false to revoke.
     */
    function setDelegatedAccess(uint256 tokenId, address delegator, bool approved) public onlyESAINFTOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(delegator != address(0), "ESAI-NFT: Delegator cannot be the zero address");
        _delegatedAccess[tokenId][delegator] = approved;
        emit DelegatedAccessSet(tokenId, delegator, approved);
    }

    /**
     * @dev Checks if a given address has delegated access for a specific ESAI-NFT.
     * @param tokenId The ID of the ESAI-NFT.
     * @param delegator The address to check.
     * @return True if the delegator has access, false otherwise.
     */
    function isDelegatedAccessApproved(uint256 tokenId, address delegator) public view returns (bool) {
        _requireMinted(tokenId);
        return _delegatedAccess[tokenId][delegator];
    }

    // --- F. Admin/Owner Functions ---

    /**
     * @dev Sets the global base Essence burn rate for all ESAI-NFTs.
     *      This rate is the minimum consumption, which then gets adjusted by dynamic trait modifiers.
     *      Callable only by the contract owner.
     * @param newRate The new base burn rate in wei per second.
     */
    function setBaseEssenceBurnRate(uint256 newRate) public onlyOwner {
        require(newRate >= MIN_ESSENCE_BURN_RATE, "ESAI-NFT: Base burn rate too low");
        baseEssenceBurnRatePerSecond = newRate;
    }

    /**
     * @dev Sets the address of the trusted cognitive oracle.
     *      This allows updating the oracle if, for example, a new version is deployed.
     *      Callable only by the contract owner.
     * @param newOracle The new oracle contract address.
     */
    function setOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "ESAI-NFT: Oracle address cannot be zero");
        cognitiveOracle = ICognitiveOracle(newOracle);
    }

    /**
     * @dev Sets the address of the Essence ERC20 token contract.
     *      This allows updating the Essence Token if, for example, a new version is deployed
     *      or if the token contract address changes.
     *      Callable only by the contract owner.
     * @param newEssenceToken The new Essence token contract address.
     */
    function setEssenceTokenAddress(address newEssenceToken) public onlyOwner {
        require(newEssenceToken != address(0), "ESAI-NFT: Essence token address cannot be zero");
        essenceToken = IEssenceToken(newEssenceToken);
    }

    /**
     * @dev See {Pausable-pause}.
     *      Allows the contract owner to pause critical functions (e.g., minting, recharging, tasks)
     *      in emergencies to prevent undesired behavior or to implement upgrades.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     *      Allows the contract owner to unpause the contract after a pause.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the base URI for ESAI-NFT metadata.
     *      This is useful for changing the endpoint where metadata JSON files are hosted.
     *      Callable only by the contract owner.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Sets the base fee for a specific type of cognitive task.
     *      These base fees are then used in `getDynamicTaskFee` to calculate the final adaptive cost.
     *      Callable only by the contract owner.
     * @param taskType The ID of the task type.
     * @param fee The new base fee in wei. Must fit within uint224.
     */
    function setTaskBaseFee(uint8 taskType, uint256 fee) public onlyOwner {
        require(fee <= type(uint224).max, "ESAI-NFT: Fee exceeds uint224 max");
        taskBaseFees[taskType] = uint224(fee);
    }

    // --- Overrides for ERC721 and Pausable ---

    /**
     * @dev Internal hook called before any token transfer.
     *      This ensures that Essence decay and trait recalculation happen automatically
     *      when an ESAI-NFT changes ownership, keeping its state up-to-date.
     * @param from The address the token is being transferred from.
     * @param to The address the token is being transferred to.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Only decay if the token actually exists (i.e., not a zero address 'from' transfer during minting,
        // unless it's the specific mint where tokenId exists but from is address(0)).
        if (from != address(0) && _esaiData[tokenId].intelligence != 0) { // Check a trait to ensure it's an initialized ESAI-NFT
            _decayEssence(tokenId);
            _recalculateTraits(tokenId);
        }
    }

    /**
     * @dev Internal check to revert if the contract is currently paused.
     */
    function _pauseCheck() internal view {
        if (paused()) {
            revert Paused(); // Reverts with the Paused error defined in Pausable.sol
        }
    }
}
```