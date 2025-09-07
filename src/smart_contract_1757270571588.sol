Here's an advanced, creative, and trendy smart contract in Solidity called `SyntheticaEvoAgent`. It represents an ERC721 NFT that functions as an evolving, AI-enhanced digital agent. Owners can interact with their Synthetica to influence its on-chain "personality," trigger AI-assisted content generation (via oracles), and even delegate on-chain actions to their agent.

---

**Outline: SyntheticaEvoAgent - An Advanced, Evolving AI-Enhanced NFT Agent**

`SyntheticaEvoAgent` is an ERC721 token that represents a unique, evolving digital entity. Owners can interact with their Synthetica to influence its on-chain personality traits, trigger AI-assisted content generation (via oracles), and enable the Synthetica to perform delegated actions on the owner's behalf using delegated funds. It incorporates dynamic metadata, an internal energy system, a reputation/experience system, and a utility token (`SPARK`) for enhanced interactions.

**I. Core NFT & Ownership**
    - Standard ERC721 functionalities for minting, burning, and ownership management.
    - Dynamic `tokenURI` that reflects the Synthetica's evolving state.

**II. Synthetica Evolution & Interaction**
    - Functions for owners to influence their Synthetica, triggering off-chain AI processing.
    - Oracle-called functions to record AI results, update traits, and award experience.
    - A `SPARK` utility token integration for claiming rewards and powering actions.
    - Mechanisms for time-based energy decay and experience accumulation.
    - On-chain storage for "memory fragments" and dynamic traits.

**III. System & Configuration**
    - Access control using OpenZeppelin's `AccessControl` for managing roles (Admin, Oracle Agent).
    - Pausability for emergency stops or maintenance.
    - Admin functions for setting core contract parameters and managing funds.

**IV. Agent Capabilities & Advanced Utility**
    - Functions allowing Syntheticas to hold and manage funds (ETH and ERC20) on behalf of their owners.
    - The ability for Syntheticas to execute delegated, programmable actions on-chain.
    - View functions for querying Synthetica's state, memories, and calculated influence score.
    - A mechanism for recording interactions between different Synthetica agents.

**Function Summary:**

**I. Core NFT & Ownership**
1.  `constructor(address defaultAdmin)`: Initializes the contract, setting up ERC721 and AccessControl.
2.  `mintSynthetica(address _to, string memory _initialPrompt)`: Mints a new Synthetica NFT to an address, initializing its core state and triggering initial AI personality generation.
3.  `burnSynthetica(uint256 tokenId)`: Burns a Synthetica NFT and clears its associated on-chain data.
4.  `tokenURI(uint256 tokenId)`: Returns the URI for a Synthetica's metadata, dynamically generated based on its evolving on-chain state.
5.  `setBaseURI(string memory _newBaseURI)`: Sets the base URI for constructing `tokenURI` links.
6.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.

**II. Synthetica Evolution & Interaction**
7.  `influenceSynthetica(uint256 tokenId, string memory _influenceVector)`: Owner provides input to influence their Synthetica, triggering an off-chain AI processing event.
8.  `recordAIResult(uint256 tokenId, bytes32 requestId, string memory _generatedContentURI, uint256 _newEnergyLevel, uint256 _xpGained, string memory _newTrait)`: Oracle-only function to update Synthetica's state (energy, XP, traits, memories) after AI processing.
9.  `claimSparkTokens(uint256 tokenId)`: Allows Synthetica owners to claim accumulated `SPARK` utility tokens.
10. `spendSparkForAction(uint256 tokenId, uint256 _amount)`: Owners can spend `SPARK` to fund specific actions or boost Synthetica's state.
11. `updateSyntheticaStatus(uint256 tokenId)`: Public function to trigger time-based energy decay and regeneration for a Synthetica.
12. `recordExperience(uint256 tokenId, uint256 _xpAmount, string memory _experienceType)`: Oracle-only function to add experience points to a Synthetica, e.g., for off-chain achievements.
13. `querySyntheticaInsight(uint256 tokenId, string memory _queryPrompt)`: Triggers a more specific oracle request for AI-generated insight based on Synthetica's state.
14. `storeMemoryFragment(uint256 tokenId, bytes32 _memoryHash, string memory _memoryType)`: Allows owners to store references to off-chain "memory fragments" (e.g., IPFS hashes) for their Synthetica.

**III. System & Configuration**
15. `setSparkTokenAddress(address _sparkAddress)`: Admin function to set the address of the `SPARK` ERC20 token.
16. `grantRole(bytes32 role, address account)`: Admin function to grant roles (e.g., ORACLE_AGENT_ROLE).
17. `revokeRole(bytes32 role, address account)`: Admin function to revoke roles.
18. `pause()`: Admin function to pause critical contract operations.
19. `unpause()`: Admin function to unpause the contract.
20. `withdrawContractFunds(address tokenAddress, address recipient, uint256 amount)`: Admin function to withdraw accidental ETH or ERC20 transfers from the contract.

**IV. Agent Capabilities & Advanced Utility**
21. `depositFundsForSynthetica(uint256 tokenId, address tokenAddress, uint256 amount)`: Allows owners to deposit ETH or ERC20 tokens into the contract, to be managed by a specific Synthetica.
22. `delegateAction(uint256 tokenId, address target, bytes memory callData, uint256 ethValue)`: Allows a Synthetica to perform an arbitrary call to an external contract using its delegated funds.
23. `withdrawFundsFromSynthetica(uint256 tokenId, address tokenAddress, uint256 amount, address recipient)`: Allows owners to withdraw previously delegated funds from their Synthetica.
24. `syntheticaBalance(uint256 tokenId, address tokenAddress)`: View function to check the balance of a specific token delegated to a Synthetica.
25. `getAllMemories(uint256 tokenId)`: View function to retrieve all stored memory fragment hashes for a Synthetica.
26. `calculateSyntheticaInfluence(uint256 tokenId)`: View function to calculate a derived "influence score" based on Synthetica's XP, energy, and activity.
27. `registerInterSyntheticaEvent(uint256 tokenIdSender, uint256 tokenIdReceiver, string memory _eventType, string memory _dataHash)`: Oracle-only function to record an on-chain interaction event between two Syntheticas.
28. `getSyntheticaDynamicTraits(uint256 tokenId)`: View function to retrieve some key dynamic traits stored on-chain for a Synthetica.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
    Outline: SyntheticaEvoAgent - An Advanced, Evolving AI-Enhanced NFT Agent

    SyntheticaEvoAgent is a unique ERC721 token representing an evolving digital entity.
    Owners can interact with their Synthetica to influence its on-chain personality traits,
    trigger AI-assisted content generation (via oracles), and enable the Synthetica to
    perform delegated actions on the owner's behalf using delegated funds. It incorporates
    dynamic metadata, an internal energy system, a reputation/experience system, and a
    utility token (`SPARK`) for enhanced interactions.

    I. Core NFT & Ownership
    II. Synthetica Evolution & Interaction
    III. System & Configuration
    IV. Agent Capabilities & Advanced Utility

    Function Summary:

    I. Core NFT & Ownership
    1.  constructor(address defaultAdmin): Initializes the contract, setting up ERC721 and AccessControl.
    2.  mintSynthetica(address _to, string memory _initialPrompt): Mints a new Synthetica NFT, initializing its state and triggering initial AI.
    3.  burnSynthetica(uint256 tokenId): Burns a Synthetica NFT and clears its associated on-chain data.
    4.  tokenURI(uint256 tokenId): Returns the URI for a Synthetica's metadata, dynamically generated.
    5.  setBaseURI(string memory _newBaseURI): Sets the base URI for constructing tokenURI links.
    6.  supportsInterface(bytes4 interfaceId): Standard ERC165 interface support.

    II. Synthetica Evolution & Interaction
    7.  influenceSynthetica(uint256 tokenId, string memory _influenceVector): Owner provides input to influence Synthetica, triggering off-chain AI.
    8.  recordAIResult(uint256 tokenId, bytes32 requestId, string memory _generatedContentURI, uint256 _newEnergyLevel, uint256 _xpGained, string memory _newTrait): Oracle-only: updates Synthetica state after AI processing.
    9.  claimSparkTokens(uint256 tokenId): Allows Synthetica owners to claim accumulated SPARK utility tokens.
    10. spendSparkForAction(uint256 tokenId, uint256 _amount): Owners can spend SPARK to fund specific actions or boosts.
    11. updateSyntheticaStatus(uint256 tokenId): Public function to trigger time-based energy decay and regeneration.
    12. recordExperience(uint256 tokenId, uint256 _xpAmount, string memory _experienceType): Oracle-only: adds experience points for achievements.
    13. querySyntheticaInsight(uint256 tokenId, string memory _queryPrompt): Triggers a specific oracle request for AI-generated insight.
    14. storeMemoryFragment(uint256 tokenId, bytes32 _memoryHash, string memory _memoryType): Owners can store references to off-chain "memory fragments."

    III. System & Configuration
    15. setSparkTokenAddress(address _sparkAddress): Admin function to set the SPARK ERC20 token address.
    16. grantRole(bytes32 role, address account): Admin function to grant roles.
    17. revokeRole(bytes32 role, address account): Admin function to revoke roles.
    18. pause(): Admin function to pause critical contract operations.
    19. unpause(): Admin function to unpause the contract.
    20. withdrawContractFunds(address tokenAddress, address recipient, uint256 amount): Admin function to withdraw accidental transfers.

    IV. Agent Capabilities & Advanced Utility
    21. depositFundsForSynthetica(uint256 tokenId, address tokenAddress, uint256 amount): Allows owners to deposit funds for their Synthetica to manage.
    22. delegateAction(uint256 tokenId, address target, bytes memory callData, uint256 ethValue): Allows Synthetica to perform arbitrary calls using its delegated funds.
    23. withdrawFundsFromSynthetica(uint256 tokenId, address tokenAddress, uint256 amount, address recipient): Allows owners to withdraw delegated funds from their Synthetica.
    24. syntheticaBalance(uint256 tokenId, address tokenAddress): View function to check a Synthetica's delegated token balance.
    25. getAllMemories(uint256 tokenId): View function to retrieve all stored memory fragment hashes.
    26. calculateSyntheticaInfluence(uint256 tokenId): View function to calculate a derived "influence score."
    27. registerInterSyntheticaEvent(uint256 tokenIdSender, uint256 tokenIdReceiver, string memory _eventType, string memory _dataHash): Oracle-only: records an on-chain interaction event between Syntheticas.
    28. getSyntheticaDynamicTraits(uint256 tokenId): View function to retrieve dynamic traits stored on-chain.
*/

/**
 * @title SyntheticaEvoAgent
 * @dev ERC721 token for AI-enhanced, evolving digital agents.
 *      Leverages oracles for AI interaction, dynamic state updates, and delegated agent actions.
 */
contract SyntheticaEvoAgent is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- State Variables & Roles ---

    bytes32 public constant ORACLE_AGENT_ROLE = keccak256("ORACLE_AGENT_ROLE");
    bytes32 public constant AI_TRAINER_ROLE = keccak256("AI_TRAINER_ROLE"); // Reserved for future specialized training features

    Counters.Counter private _tokenIdCounter;

    // Struct to hold the core evolving properties of each Synthetica
    struct SyntheticaCore {
        uint256 lastInteractionTime; // Timestamp of the last significant owner interaction
        uint256 experiencePoints;    // Accumulates through interactions and events
        uint256 energyLevel;         // Decays over time, consumed by actions, regenerated by SPARK/interaction
        string personalityTraitURI;  // Base URI pointing to off-chain data for its core personality
        string currentMood;          // Simple on-chain string, changes based on interactions
        uint256 generationCount;     // How many AI-assisted content generations it has prompted
        uint256 sparkAccumulated;    // Amount of SPARK tokens earned by this Synthetica
    }

    // Main mapping for Synthetica core data
    mapping(uint256 => SyntheticaCore) public syntheticas;

    // Dynamic traits stored as key-value pairs for each Synthetica (e.g., specific attributes, temporary buffs)
    mapping(uint256 => mapping(bytes32 => string)) public syntheticaDynamicTraits;

    // Array of hashes referring to off-chain memory fragments (e.g., IPFS CIDs of generated content, owner notes)
    mapping(uint256 => bytes32[]) public syntheticaMemoryFragments;

    // Balances of various tokens (ETH = address(0), ERC20) held by the contract *on behalf of* specific Syntheticas for delegated actions
    mapping(uint256 => mapping(address => uint256)) public syntheticaTokenBalances;

    // Address of the SPARK utility token
    IERC20 public sparkToken;

    // Base URI for external metadata service. tokenURI will point to `_baseURI/tokenId`.
    string private _baseURI;

    // --- Events ---

    event SyntheticaMinted(uint256 indexed tokenId, address indexed owner, string initialPrompt);
    event SyntheticaInfluenced(uint256 indexed tokenId, address indexed influencer, string influenceVector, bytes32 requestId);
    event AIResultRecorded(uint256 indexed tokenId, bytes32 indexed requestId, string generatedContentURI, uint256 newEnergyLevel, uint256 xpGained, string newTrait);
    event SparkClaimed(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event SparkSpentForAction(uint256 indexed tokenId, uint256 amount, string actionType);
    event ActionDelegated(uint256 indexed tokenId, address indexed delegator, address target, bytes callData, uint256 ethValue);
    event ExperienceRecorded(uint256 indexed tokenId, uint256 xpAmount, string experienceType);
    event MemoryFragmentStored(uint256 indexed tokenId, bytes32 memoryHash, string memoryType);
    event SyntheticaInteracted(uint256 indexed tokenIdSender, uint256 indexed tokenIdReceiver, string eventType, string dataHash);
    event FundsDepositedForSynthetica(uint256 indexed tokenId, address indexed depositor, address tokenAddress, uint256 amount);
    event FundsWithdrawalFromSynthetica(uint256 indexed tokenId, address indexed recipient, address tokenAddress, uint256 amount);


    // --- Constructor ---

    /**
     * @dev Initializes the contract, setting the deployer and `defaultAdmin` as admin roles.
     * @param defaultAdmin Address to be granted the DEFAULT_ADMIN_ROLE (in addition to msg.sender).
     */
    constructor(address defaultAdmin) ERC721("SyntheticaEvoAgent", "SYNTH") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant to deployer as well
    }

    // --- Modifiers ---

    /**
     * @dev Checks if the caller is either the owner of the Synthetica or an approved operator.
     */
    modifier onlySyntheticaOwnerOrApproved(uint256 tokenId) {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved operator of Synthetica");
        _;
    }

    // --- I. Core NFT & Ownership ---

    /**
     * @dev Mints a new Synthetica, initializing its core properties.
     *      Triggers an off-chain AI process via an event to set initial personality traits.
     * @param _to The address to mint the Synthetica to.
     * @param _initialPrompt A text prompt to guide the Synthetica's initial personality generation.
     */
    function mintSynthetica(address _to, string memory _initialPrompt) public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        syntheticas[newItemId].lastInteractionTime = block.timestamp;
        syntheticas[newItemId].experiencePoints = 0;
        syntheticas[newItemId].energyLevel = 100; // Initial energy
        syntheticas[newItemId].personalityTraitURI = ""; // Will be set by oracle after initial AI processing
        syntheticas[newItemId].currentMood = "Neutral";
        syntheticas[newItemId].generationCount = 0;
        syntheticas[newItemId].sparkAccumulated = 0;

        // Emit an event for an off-chain oracle to pick up and process the initial prompt.
        // A requestId would be generated off-chain or by a Chainlink Function call for a robust system.
        bytes32 initialRequestId = keccak256(abi.encodePacked(newItemId, _initialPrompt, block.timestamp));
        emit SyntheticaMinted(newItemId, _to, _initialPrompt);
        emit SyntheticaInfluenced(newItemId, _to, _initialPrompt, initialRequestId); // Reuse event for initial AI generation trigger

        return newItemId;
    }

    /**
     * @dev Burns a Synthetica. Only callable by admin.
     *      Associated state data is also cleared to save storage.
     * @param tokenId The ID of the Synthetica to burn.
     */
    function burnSynthetica(uint256 tokenId) public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _requireMinted(tokenId);
        _burn(tokenId);
        // Clear all associated state data to free up storage
        delete syntheticas[tokenId];
        delete syntheticaDynamicTraits[tokenId];
        delete syntheticaMemoryFragments[tokenId];
        delete syntheticaTokenBalances[tokenId];
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for a given Synthetica.
     *      This URI points to a JSON metadata file, dynamically generated by an off-chain service
     *      that queries the on-chain state of the Synthetica, ensuring real-time reflection of evolution.
     * @param tokenId The ID of the Synthetica.
     * @return A URI pointing to the Synthetica's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return ""; // Or revert with an error if base URI is mandatory
        }
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /**
     * @dev Sets the base URI for all Synthetica NFTs. This URI is used by `tokenURI` to
     *      construct the full metadata URL (e.g., `baseURI/tokenId`).
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI = _newBaseURI;
    }

    // --- II. Synthetica Evolution & Interaction ---

    /**
     * @dev Allows the owner to influence their Synthetica's personality or actions.
     *      This function emits an event for an off-chain AI oracle to process the influence.
     *      Requires energy from the Synthetica.
     * @param tokenId The ID of the Synthetica to influence.
     * @param _influenceVector A text string describing the desired influence or prompt for the AI.
     */
    function influenceSynthetica(uint256 tokenId, string memory _influenceVector) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _updateSyntheticaEnergyAndXP(tokenId); // Apply decay/updates before interaction
        require(syntheticas[tokenId].energyLevel >= 5, "Synthetica has insufficient energy for interaction (min 5)");

        // Decrement energy for interaction
        syntheticas[tokenId].energyLevel -= 5; // Example cost

        // Emit event for oracle processing (requestId can be generated off-chain by the oracle, or a simple hash here)
        bytes32 requestId = keccak256(abi.encodePacked(tokenId, _influenceVector, block.timestamp));
        emit SyntheticaInfluenced(tokenId, msg.sender, _influenceVector, requestId);
        syntheticas[tokenId].lastInteractionTime = block.timestamp;
        syntheticas[tokenId].generationCount++; // Increment count of AI prompts

        syntheticas[tokenId].experiencePoints += 1; // Small XP gain for initiating interaction
    }

    /**
     * @dev Called by the trusted oracle (`ORACLE_AGENT_ROLE`) after an off-chain AI process completes.
     *      Updates the Synthetica's state based on the AI's output, allowing for dynamic evolution.
     * @param tokenId The ID of the Synthetica.
     * @param requestId The ID of the request that triggered this AI processing.
     * @param _generatedContentURI URI pointing to the AI-generated content (e.g., text, image hash on IPFS).
     * @param _newEnergyLevel The new energy level suggested by the AI/oracle (can be a regeneration).
     * @param _xpGained Experience points gained from this AI interaction.
     * @param _newTrait A specific new dynamic trait (can be a key:value string for off-chain parsing or a simple mood).
     */
    function recordAIResult(
        uint256 tokenId,
        bytes32 requestId,
        string memory _generatedContentURI,
        uint256 _newEnergyLevel,
        uint256 _xpGained,
        string memory _newTrait
    ) public virtual onlyRole(ORACLE_AGENT_ROLE) whenNotPaused {
        _requireMinted(tokenId);

        // Update core Synthetica properties
        syntheticas[tokenId].energyLevel = _newEnergyLevel;
        syntheticas[tokenId].experiencePoints += _xpGained;
        syntheticas[tokenId].currentMood = "Reflective"; // Placeholder, could be AI-determined

        // Store the generated content URI hash as a memory fragment
        syntheticaMemoryFragments[tokenId].push(keccak256(abi.encodePacked(_generatedContentURI)));

        // Store specific dynamic traits. A more complex system might parse `_newTrait` into key/value.
        bytes32 traitKeyLastContent = keccak256(abi.encodePacked("lastGeneratedContent"));
        syntheticaDynamicTraits[tokenId][traitKeyLastContent] = _generatedContentURI;
        bytes32 traitKeyLastAIResult = keccak256(abi.encodePacked("lastAIInteractionResult"));
        syntheticaDynamicTraits[tokenId][traitKeyLastAIResult] = _newTrait;

        // Reward SPARK based on XP gained or complexity of interaction
        syntheticas[tokenId].sparkAccumulated += _xpGained / 10; // Example calculation

        emit AIResultRecorded(tokenId, requestId, _generatedContentURI, _newEnergyLevel, _xpGained, _newTrait);
    }

    /**
     * @dev Allows a Synthetica owner to claim `SPARK` tokens that their Synthetica has accumulated
     *      through activity and experiences.
     * @param tokenId The ID of the Synthetica.
     */
    function claimSparkTokens(uint256 tokenId) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(address(sparkToken) != address(0), "SPARK token address not set");

        uint256 amountToClaim = syntheticas[tokenId].sparkAccumulated;
        require(amountToClaim > 0, "No SPARK to claim");

        syntheticas[tokenId].sparkAccumulated = 0; // Reset accumulated SPARK after claiming
        sparkToken.safeTransfer(ownerOf(tokenId), amountToClaim);

        emit SparkClaimed(tokenId, ownerOf(tokenId), amountToClaim);
    }

    /**
     * @dev Allows the owner to spend `SPARK` tokens to enable special actions or premium AI interactions
     *      for their Synthetica. The SPARK is transferred to the contract and associated with the Synthetica.
     * @param tokenId The ID of the Synthetica.
     * @param _amount The amount of SPARK to spend.
     */
    function spendSparkForAction(uint256 tokenId, uint256 _amount) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(address(sparkToken) != address(0), "SPARK token address not set");
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer SPARK from the owner to the contract for this Synthetica's delegated use
        sparkToken.safeTransferFrom(msg.sender, address(this), _amount);
        syntheticaTokenBalances[tokenId][address(sparkToken)] += _amount;

        emit SparkSpentForAction(tokenId, _amount, "GenericAction");

        // Example: Small energy boost for spending SPARK
        syntheticas[tokenId].energyLevel += (_amount / 100);
        if (syntheticas[tokenId].energyLevel > 100) { // Cap energy at max
            syntheticas[tokenId].energyLevel = 100;
        }
    }

    /**
     * @dev Triggers the internal energy and experience decay/regeneration logic for a Synthetica.
     *      Can be called by anyone to update the state, encouraging external calls for state updates.
     * @param tokenId The ID of the Synthetica to update.
     */
    function updateSyntheticaStatus(uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        _updateSyntheticaEnergyAndXP(tokenId);
    }

    /**
     * @dev Allows an `ORACLE_AGENT_ROLE` to record specific experience points for a Synthetica.
     *      Useful for rewarding participation in external events, achievements, or complex AI tasks.
     * @param tokenId The ID of the Synthetica.
     * @param _xpAmount The amount of experience points to add.
     * @param _experienceType A string describing the type of experience (e.g., "DAO_Vote", "Quest_Completion").
     */
    function recordExperience(uint256 tokenId, uint256 _xpAmount, string memory _experienceType) public virtual onlyRole(ORACLE_AGENT_ROLE) whenNotPaused {
        _requireMinted(tokenId);
        require(_xpAmount > 0, "Experience amount must be positive");

        syntheticas[tokenId].experiencePoints += _xpAmount;
        syntheticas[tokenId].sparkAccumulated += _xpAmount / 5; // Earn SPARK for experiences

        emit ExperienceRecorded(tokenId, _xpAmount, _experienceType);
    }

    /**
     * @dev Triggers an oracle request for AI-generated insight based on the Synthetica's current state and memories.
     *      This is a more advanced influence, requesting a specific output. Requires more energy.
     * @param tokenId The ID of the Synthetica.
     * @param _queryPrompt A specific prompt for the AI to generate insight.
     */
    function querySyntheticaInsight(uint256 tokenId, string memory _queryPrompt) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _updateSyntheticaEnergyAndXP(tokenId);
        require(syntheticas[tokenId].energyLevel >= 10, "Not enough energy for insight query (min 10)"); // Higher energy cost

        syntheticas[tokenId].energyLevel -= 10;
        syntheticas[tokenId].lastInteractionTime = block.timestamp;
        syntheticas[tokenId].generationCount++;
        syntheticas[tokenId].experiencePoints += 2; // Small XP gain for querying

        bytes32 requestId = keccak256(abi.encodePacked(tokenId, _queryPrompt, "insight", block.timestamp));
        emit SyntheticaInfluenced(tokenId, msg.sender, _queryPrompt, requestId); // Re-use event, oracle interprets context
    }

    /**
     * @dev Allows the owner to store a reference to an off-chain "memory fragment" (e.g., IPFS hash of a generated text/image,
     *      or a hash of a significant event). These fragments contribute to the Synthetica's evolving identity
     *      and can be used by AI oracles for context.
     * @param tokenId The ID of the Synthetica.
     * @param _memoryHash A bytes32 hash (e.g., IPFS CID, or a hash of content) of the memory fragment.
     * @param _memoryType A string describing the type of memory (e.g., "AI_Output", "Owner_Note", "Event_Log").
     */
    function storeMemoryFragment(uint256 tokenId, bytes32 _memoryHash, string memory _memoryType) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(_memoryHash != bytes32(0), "Memory hash cannot be zero");

        syntheticaMemoryFragments[tokenId].push(_memoryHash);
        syntheticas[tokenId].experiencePoints += 1; // Small XP gain for adding memory

        emit MemoryFragmentStored(tokenId, _memoryHash, _memoryType);
    }

    // --- III. System & Configuration ---

    /**
     * @dev Sets the address of the ERC20 `SPARK` utility token.
     *      Only callable by an admin.
     * @param _sparkAddress The address of the SPARK token contract.
     */
    function setSparkTokenAddress(address _sparkAddress) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_sparkAddress != address(0), "SPARK token address cannot be zero");
        sparkToken = IERC20(_sparkAddress);
    }

    /**
     * @dev Grants a role to an account.
     *      Overrides AccessControl. Admin actions typically bypass pause.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an account.
     *      Overrides AccessControl. Admin actions typically bypass pause.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Pauses all operations that are marked `whenNotPaused`.
     *      Only callable by an admin. Useful for upgrades or emergency stops.
     */
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming all operations.
     *      Only callable by an admin.
     */
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows an admin to withdraw accidental transfers of ETH or other ERC20 tokens
     *      that are not intended for Synthetica agent balances or for the contract's own use (e.g., fees).
     * @param tokenAddress The address of the ERC20 token to withdraw, or address(0) for ETH.
     * @param recipient The address to send the funds to.
     * @param amount The amount to withdraw.
     */
    function withdrawContractFunds(address tokenAddress, address recipient, uint256 amount) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "Recipient cannot be zero address");
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH balance in contract");
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw ERC20 token
            IERC20(tokenAddress).safeTransfer(recipient, amount);
        }
    }

    // --- IV. Agent Capabilities & Advanced Utility ---

    /**
     * @dev Transfers ETH or ERC20 tokens to the contract to be held and managed by a specific Synthetica agent.
     *      These funds can then be used by `delegateAction`.
     * @param tokenId The ID of the Synthetica that will manage these funds.
     * @param tokenAddress The address of the ERC20 token to deposit, or address(0) for ETH.
     * @param amount The amount to deposit.
     */
    function depositFundsForSynthetica(uint256 tokenId, address tokenAddress, uint256 amount) public payable virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(amount > 0, "Deposit amount must be greater than zero");

        if (tokenAddress == address(0)) {
            require(msg.value == amount, "ETH value sent must match amount parameter");
            syntheticaTokenBalances[tokenId][address(0)] += amount;
        } else {
            require(msg.value == 0, "Do not send ETH for ERC20 deposit");
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            syntheticaTokenBalances[tokenId][tokenAddress] += amount;
        }
        emit FundsDepositedForSynthetica(tokenId, msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Allows a Synthetica owner to delegate an action to be performed by the Synthetica (contract itself).
     *      The Synthetica (contract) must hold sufficient funds (ETH or specific ERC20) for the call in its delegated balance.
     *      This turns the Synthetica into a rudimentary programmable sub-agent within the contract.
     * @param tokenId The ID of the Synthetica acting as the agent.
     * @param target The address of the contract to call.
     * @param callData The encoded function call data.
     * @param ethValue The amount of ETH to send with the call (from Synthetica's delegated ETH balance).
     */
    function delegateAction(uint256 tokenId, address target, bytes memory callData, uint256 ethValue) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(target != address(0), "Target cannot be zero address");

        // Ensure Synthetica has enough delegated ETH for the call
        require(syntheticaTokenBalances[tokenId][address(0)] >= ethValue, "Insufficient delegated ETH for Synthetica to perform action");

        // Deduct ETH from Synthetica's delegated balance
        syntheticaTokenBalances[tokenId][address(0)] -= ethValue;

        // Execute the delegated call
        (bool success, ) = target.call{value: ethValue}(callData);
        require(success, "Delegated action failed");

        emit ActionDelegated(tokenId, msg.sender, target, callData, ethValue);

        // Optionally, reward XP or energy for performing a delegated action
        syntheticas[tokenId].experiencePoints += 5;
        syntheticas[tokenId].energyLevel = syntheticas[tokenId].energyLevel >= 5 ? syntheticas[tokenId].energyLevel - 5 : 0; // Cost for action
        syntheticas[tokenId].lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Withdraws ETH or ERC20 tokens that were previously deposited for a Synthetica.
     *      Only the Synthetica's owner or approved operator can withdraw these funds.
     * @param tokenId The ID of the Synthetica whose funds are to be withdrawn.
     * @param tokenAddress The address of the ERC20 token to withdraw, or address(0) for ETH.
     * @param amount The amount to withdraw.
     * @param recipient The address to send the funds to.
     */
    function withdrawFundsFromSynthetica(uint256 tokenId, address tokenAddress, uint256 amount, address recipient) public virtual onlySyntheticaOwnerOrApproved(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        require(recipient != address(0), "Recipient cannot be zero address");
        require(syntheticaTokenBalances[tokenId][tokenAddress] >= amount, "Insufficient delegated funds for withdrawal");

        syntheticaTokenBalances[tokenId][tokenAddress] -= amount;

        if (tokenAddress == address(0)) {
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            IERC20(tokenAddress).safeTransfer(recipient, amount);
        }
        emit FundsWithdrawalFromSynthetica(tokenId, recipient, tokenAddress, amount);
    }

    /**
     * @dev Returns the balance of a specific token held by the contract on behalf of a Synthetica.
     * @param tokenId The ID of the Synthetica.
     * @param tokenAddress The address of the token (address(0) for ETH).
     * @return The balance of the token.
     */
    function syntheticaBalance(uint256 tokenId, address tokenAddress) public view virtual returns (uint256) {
        _requireMinted(tokenId);
        return syntheticaTokenBalances[tokenId][tokenAddress];
    }

    /**
     * @dev Retrieves all stored memory fragment hashes for a given Synthetica.
     *      Note: This could be gas-intensive for Syntheticas with many memories.
     *      Consider pagination or returning only recent memories for large arrays.
     * @param tokenId The ID of the Synthetica.
     * @return An array of bytes32 hashes representing memory fragments.
     */
    function getAllMemories(uint256 tokenId) public view virtual returns (bytes32[] memory) {
        _requireMinted(tokenId);
        return syntheticaMemoryFragments[tokenId];
    }

    /**
     * @dev Calculates and returns a derived "influence score" for a Synthetica based on its XP, activity, etc.
     *      This is a simple example; a real-world calculation could be much more complex, potentially
     *      involving dynamic trait values and external data.
     * @param tokenId The ID of the Synthetica.
     * @return The calculated influence score.
     */
    function calculateSyntheticaInfluence(uint256 tokenId) public view virtual returns (uint256) {
        _requireMinted(tokenId);
        SyntheticaCore storage s = syntheticas[tokenId];

        // Simple linear calculation: XP + (energy/10) + (generations * 5)
        uint256 influence = s.experiencePoints + (s.energyLevel / 10) + (s.generationCount * 5);

        // Add a bonus for recent activity (e.g., interacted within the last week)
        if (block.timestamp - s.lastInteractionTime < 7 days) {
            influence += 50;
        }
        return influence;
    }

    /**
     * @dev Registers an on-chain event between two Syntheticas, potentially influencing both.
     *      Callable by `ORACLE_AGENT_ROLE`, signifying a processed interaction or observation.
     * @param tokenIdSender The ID of the initiating or primary Synthetica in the event.
     * @param tokenIdReceiver The ID of the receiving or secondary Synthetica in the event.
     * @param _eventType A string describing the type of interaction (e.g., "Trade_Proposal", "Shared_Insight").
     * @param _dataHash A hash referencing off-chain data related to the interaction.
     */
    function registerInterSyntheticaEvent(
        uint256 tokenIdSender,
        uint256 tokenIdReceiver,
        string memory _eventType,
        string memory _dataHash
    ) public virtual onlyRole(ORACLE_AGENT_ROLE) whenNotPaused {
        _requireMinted(tokenIdSender);
        _requireMinted(tokenIdReceiver);

        // Update both Syntheticas based on the interaction
        syntheticas[tokenIdSender].experiencePoints += 3;
        syntheticas[tokenIdSender].lastInteractionTime = block.timestamp;
        syntheticas[tokenIdSender].currentMood = "Engaged"; // Example mood change

        syntheticas[tokenIdReceiver].experiencePoints += 3;
        syntheticas[tokenIdReceiver].lastInteractionTime = block.timestamp;
        syntheticas[tokenIdReceiver].currentMood = "Curious"; // Example mood change

        // Optionally, store _dataHash as a memory fragment for both
        syntheticaMemoryFragments[tokenIdSender].push(keccak256(abi.encodePacked("InterSyntheticaEvent_", _dataHash)));
        syntheticaMemoryFragments[tokenIdReceiver].push(keccak256(abi.encodePacked("InterSyntheticaEvent_", _dataHash)));

        emit SyntheticaInteracted(tokenIdSender, tokenIdReceiver, _eventType, _dataHash);
    }

    /**
     * @dev Retrieves some common dynamic traits stored for a given Synthetica.
     *      This function explicitly returns a few predefined dynamic traits for demonstration.
     *      For a truly generic system with many dynamic traits, an off-chain indexer
     *      or more complex on-chain mapping would be required.
     * @param tokenId The ID of the Synthetica.
     * @return An array of trait keys (bytes32) and an array of trait values (string).
     */
    function getSyntheticaDynamicTraits(uint256 tokenId) public view virtual returns (bytes32[] memory keys, string[] memory values) {
        _requireMinted(tokenId);
        
        // For demonstration, we explicitly define a few dynamic trait keys.
        // In a complex system, these might be iterated from a stored list of keys.
        keys = new bytes32[](2);
        values = new string[](2);

        keys[0] = keccak256(abi.encodePacked("lastGeneratedContent"));
        values[0] = syntheticaDynamicTraits[tokenId][keys[0]];

        keys[1] = keccak256(abi.encodePacked("lastAIInteractionResult"));
        values[1] = syntheticaDynamicTraits[tokenId][keys[1]];

        return (keys, values);
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to update a Synthetica's energy and experience based on time decay and regeneration.
     *      This function calculates and applies changes based on `lastInteractionTime`.
     * @param tokenId The ID of the Synthetica.
     */
    function _updateSyntheticaEnergyAndXP(uint256 tokenId) internal {
        SyntheticaCore storage s = syntheticas[tokenId];
        uint256 timePassed = block.timestamp - s.lastInteractionTime;

        // Energy decay: lose 1 energy per day (86400 seconds), up to 50% of current energy for gradual effect.
        uint256 dailyDecayRate = 1; // 1 energy per day
        uint256 maxEnergy = 100;
        uint256 energyDecay = (timePassed / 86400) * dailyDecayRate;
        
        if (s.energyLevel > 0) {
            uint256 decayLimit = s.energyLevel / 2; // Decay up to half of current energy per update cycle
            if (energyDecay > decayLimit) {
                energyDecay = decayLimit;
            }
            s.energyLevel = s.energyLevel >= energyDecay ? s.energyLevel - energyDecay : 0;
        }

        // Energy regeneration (passive): gain 1 energy per 2 days up to 50% max energy
        uint256 regenRate = 1; // 1 energy per 2 days
        uint256 energyRegen = (timePassed / (86400 * 2)) * regenRate;
        
        if (s.energyLevel < maxEnergy / 2) { // Only regenerate if below 50% max
            s.energyLevel += energyRegen;
            if (s.energyLevel > maxEnergy / 2) {
                s.energyLevel = maxEnergy / 2; // Cap regeneration at 50% of max energy
            }
        }
        
        // Update last interaction time for subsequent calculations,
        // but only if a significant amount of time has passed to prevent spamming updates.
        if (timePassed > 1 hours) {
             s.lastInteractionTime = block.timestamp; 
        }
    }

    /**
     * @dev Internal helper to check if a Synthetica with the given ID has been minted.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "Synthetica does not exist");
    }

    // --- ERC165 and AccessControl Hooks ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback function to receive ETH for delegated balances
    receive() external payable {
        // ETH received directly here is not associated with any specific Synthetica
        // and can only be withdrawn by the DEFAULT_ADMIN_ROLE via withdrawContractFunds.
        // Owners should use depositFundsForSynthetica to assign ETH to a Synthetica.
    }
}
```