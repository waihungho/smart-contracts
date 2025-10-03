Here's a Solidity smart contract named `ChronoForge` that implements an advanced, dynamic NFT (dNFT) system. It combines concepts of evolving digital identities, a predictive reputation score, gamification through DAO-governed quests, resource management, and external token staking for attribute boosts. The goal is to provide a unique blend of these features, distinct from existing open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic SVG/JSON generation
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // For Catalyst items

// Custom Errors
error ChronoForge__NotGovernance();
error ChronoForge__EpochMarkNotFound();
error ChronoForge__AlreadyMinted(); // Although _nextTokenId handles this, good for custom checks if needed
error ChronoForge__QuestNotFound();
error ChronoForge__QuestNotApproved();
error ChronoForge__QuestAlreadyCompleted();
error ChronoForge__InsufficientTemporalEnergy();
error ChronoForge__EpochMarkNotStaked();
error ChronoForge__EpochMarkAlreadyStaked();
error ChronoForge__InvalidOracle(); // More specific: unauthorized oracle
error ChronoForge__UnauthorizedOracleUpdate();
error ChronoForge__AttributeNotFound(); // For catalysts/generic attribute checks
error ChronoForge__InvalidAttributeType(); // If we had strict type enforcement per key
error ChronoForge__TransferRestricted(); // For Soulbound state
error ChronoForge__InsufficientExternalTokenStake();
error ChronoForge__NoExternalTokenStakeFound();
error ChronoForge__QuestAttributeMismatch(); // For proposeEpochQuest
error ChronoForge__AlreadyBoostingAttribute(); // For external token stake
error ChronoForge__NotOwnerOrGovernance(); // For generic attribute updates

/**
 * @title ChronoForge: Evolving Digital Identities
 * @author Your Name/Alias
 * @notice This contract implements a unique dynamic NFT (dNFT) system called "EpochMarks."
 *         EpochMarks are digital identities that evolve based on on-chain activity, oracle
 *         data, user participation in "Epoch Quests," and interaction with "Catalyst" items.
 *         It features a dynamic attribute system, a predictive "Prophecy Score,"
 *         and a resource management layer ("Temporal Energy") generated via staking.
 *         The system is designed to be governed by a DAO (represented by the governanceAddress).
 *
 * @dev This contract uses OpenZeppelin libraries for ERC721Enumerable, Ownable, Pausable, Strings, and Base64.
 *      It integrates custom logic for dynamic attributes, gamification, and resource management.
 *      The `tokenURI` generates rich, dynamic SVG/JSON metadata based on the EpochMark's current state.
 */
contract ChronoForge is ERC721Enumerable, Pausable, Ownable {

    using Strings for uint256;
    using Strings for int256;

    // --- Outline and Function Summary ---
    //
    // I. Core EpochMark NFT Management
    //    1. `constructor` - Initializes the contract with name, symbol, and sets the initial governance address.
    //    2. `mintEpochMark(address to, string memory name_)` - Mints a new EpochMark NFT, assigning it a unique name and initializing core attributes.
    //    3. `tokenURI(uint256 tokenId)` - Generates a dynamic SVG/JSON metadata URI based on the EpochMark's current attributes, providing a visual representation.
    //    4. `getEpochMarkAttributes(uint256 tokenId)` - Retrieves all current attributes (numeric and string) for a given EpochMark.
    //    5. `transferFrom(address from, address to, uint256 tokenId)` - Overrides ERC721 transfer to enforce Soulbound-like restrictions when an EpochMark is staked.
    //    6. `setEpochMarkName(uint256 tokenId, string memory newName)` - Allows the EpochMark owner to rename their digital identity.
    //
    // II. Dynamic Attribute Evolution
    //    7. `updateAttributeNumeric(uint256 tokenId, string memory attributeKey, int256 valueChange, bool absoluteSet)` - Updates a numeric attribute, either by adding/subtracting or setting absolutely. Restricted to owner/governance/oracles.
    //    8. `updateAttributeString(uint256 tokenId, string memory attributeKey, string memory newValue)` - Updates a string attribute. Restricted to owner/governance/oracles.
    //    9. `triggerEvolutionCycle(uint256 tokenId)` - Initiates a re-evaluation and potential update of an EpochMark's attributes (e.g., Level-ups based on Insight). Callable by owner.
    //   10. `registerOracleFeed(address oracleAddress, string memory feedId)` - Registers an external oracle address and its unique feed ID. Only governance can register.
    //   11. `receiveOracleData(string memory feedId, uint256 tokenId, bytes memory data)` - Callback for registered oracles to push external data that influences EpochMark attributes (e.g., market sentiment, L2 activity).
    //
    // III. Reputation & Insight System
    //   12. `accrueInsight(uint256 tokenId, uint256 amount)` - Awards "Insight" points to an EpochMark, reflecting engagement and contributions.
    //   13. `decayInsight(uint256 tokenId)` - Periodically reduces an EpochMark's Insight score to reflect ongoing relevance and prevent stagnation. Callable by anyone (permissionless trigger).
    //   14. `getInsightScore(uint256 tokenId)` - Retrieves the current Insight score of an EpochMark.
    //   15. `updateProphecyScore(uint256 tokenId)` - Calculates and updates a predictive "Prophecy Score" based on Insight, Level, quest completions, and other factors, representing future potential. Callable by governance.
    //
    // IV. Gamification & Quests (Epoch Quests)
    //   16. `proposeEpochQuest(string memory title, string memory description, uint256 insightReward, string[] memory affectedAttributeKeys, int256[] memory affectedAttributeValues)` - Allows anyone to propose new quests with specific rewards and attribute changes.
    //   17. `approveEpochQuest(uint256 questId)` - Governance approves a proposed quest, making it active and available for completion.
    //   18. `completeEpochQuest(uint256 tokenId, uint256 questId)` - Allows an EpochMark holder to claim completion of an approved quest, receiving rewards and attribute changes.
    //   19. `getCurrentEpochQuests()` - Returns a list of all currently active (approved) Epoch Quest IDs.
    //   20. `getQuestDetails(uint256 questId)` - Retrieves the full details of a specific quest.
    //
    // V. Temporal Energy & Resource Management
    //   21. `generateTemporalEnergy(uint256 tokenId)` - Generates "Temporal Energy" for a staked EpochMark based on time elapsed. Callable by anyone (permissionless trigger).
    //   22. `spendTemporalEnergy(uint256 tokenId, uint256 amount)` - Consumes Temporal Energy from an EpochMark to perform specific actions or activate boosts.
    //   23. `getTemporalEnergyBalance(uint256 tokenId)` - Retrieves the current Temporal Energy balance of an EpochMark.
    //
    // VI. Staking & Catalysts
    //   24. `stakeEpochMarkForEnergy(uint256 tokenId)` - Stakes an EpochMark to passively generate Temporal Energy, making it temporarily Soulbound.
    //   25. `unstakeEpochMarkFromEnergy(uint256 tokenId)` - Unstakes an EpochMark, releasing its Soulbound state and allowing transfers.
    //   26. `useCatalyst(uint256 tokenId, address catalystCollection, uint256 catalystId, uint256 amount)` - Consumes an ERC1155 "Catalyst" item to directly influence EpochMark attributes (e.g., Strength, AuraColor).
    //   27. `depositExternalTokenForBoost(uint256 tokenId, address tokenAddress, uint256 amount, string memory attributeKey)` - Stakes an external ERC20 token to temporarily boost a specific EpochMark attribute.
    //   28. `withdrawExternalTokenBoost(uint256 tokenId, address tokenAddress)` - Withdraws staked external ERC20 tokens and removes the associated attribute boost.
    //
    // VII. Governance (DAO Interaction)
    //   29. `setGovernanceAddress(address newGovernanceAddress)` - Transfers ownership/governance control to a new DAO address. Only callable by current governance.
    //   30. `executeGovernanceProposal(bytes memory callData)` - Allows the governing DAO to execute arbitrary proposals, enabling flexible contract upgrades and parameter changes.
    //
    // VIII. Admin/Utility
    //   31. `pause()` - Pauses critical contract functions (only by governance).
    //   32. `unpause()` - Unpauses critical contract functions (only by governance).
    //   33. `emergencyWithdraw(address tokenAddress, uint256 amount)` - Allows governance to withdraw accidentally sent ERC20 tokens.
    //   34. `emergencyWithdrawETH(uint256 amount)` - Allows governance to withdraw accidentally sent ETH.
    //
    // --- End of Outline ---

    // Structs
    struct EpochMarkAttributes {
        string name;
        uint256 creationTime;
        mapping(string => int256) numericAttributes; // e.g., "Level", "Strength", "Wisdom", "Insight", "ProphecyScore", "TemporalEnergy"
        string[] numericAttributeKeys; // To iterate over numericAttributes
        mapping(string => string) stringAttributes;  // e.g., "Title", "AuraColor", "Faction"
        string[] stringAttributeKeys; // To iterate over stringAttributes
        uint256 lastEvolutionTime;
        uint256 lastInsightDecayTime;
        uint256 lastEnergyGenerationTime;
        bool isSoulbound; // If true, cannot be transferred (can be temporary, e.g., while staked)
    }

    struct EpochQuest {
        string title;
        string description;
        uint256 insightReward;
        string[] affectedAttributeKeys; // Keys of attributes modified by quest
        int256[] affectedAttributeValues; // Corresponding values (added/subtracted)
        bool isApproved;
        uint256 creationTime;
    }

    struct OracleFeed {
        address oracleAddress;
        bool registered;
    }

    struct ExternalTokenStake {
        address tokenAddress;
        uint256 amount;
        string attributeKey; // The specific attribute this stake is boosting
        uint256 stakeTime;
    }

    // State Variables
    uint256 private _nextTokenId;
    address public governanceAddress; // Address of the DAO or governing entity

    mapping(uint256 => EpochMarkAttributes) public epochMarks;

    uint256 private _nextQuestId;
    mapping(uint256 => EpochQuest) public epochQuests;
    mapping(uint256 => mapping(uint256 => bool)) public epochQuestCompletions; // tokenId => questId => completed

    mapping(string => OracleFeed) public registeredOracles; // feedId => OracleFeed

    mapping(uint256 => bool) public epochMarkStakedForEnergy; // tokenId => isStaked
    mapping(uint256 => ExternalTokenStake) public externalTokenStakes; // tokenId => ExternalTokenStake (simplified for 1 stake per token per NFT per attribute)

    // Configuration parameters (can be changed by governance)
    uint256 public INSIGHT_DECAY_INTERVAL = 30 days; // How often Insight decays
    uint256 public INSIGHT_DECAY_RATE = 10; // Percentage of Insight lost per decay cycle (e.g., 10 for 10%)
    uint256 public TEMPORAL_ENERGY_GENERATION_RATE = 100; // Energy generated per epochMark per cycle
    uint256 public ENERGY_GENERATION_INTERVAL = 1 days; // How often Temporal Energy is generated
    uint256 public PROPHECY_SCORE_CALCULATION_INTERVAL = 7 days; // How often prophecy score is recalculated

    // Events
    event EpochMarkMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 timestamp);
    event EpochMarkAttributeUpdated(uint256 indexed tokenId, string attributeKey, int256 numericValue, string stringValue, bool isNumeric);
    event EpochMarkEvolved(uint252 indexed tokenId, uint256 newLastEvolutionTime);
    event InsightAccrued(uint256 indexed tokenId, uint256 amount, uint256 newInsightScore);
    event InsightDecayed(uint256 indexed tokenId, uint256 amount, uint256 newInsightScore);
    event ProphecyScoreUpdated(uint256 indexed tokenId, int256 newProphecyScore);
    event EpochQuestProposed(uint256 indexed questId, string title, address proposer);
    event EpochQuestApproved(uint256 indexed questId);
    event EpochQuestCompleted(uint256 indexed tokenId, uint256 indexed questId);
    event TemporalEnergyGenerated(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event TemporalEnergySpent(uint255 indexed tokenId, uint256 amount, uint256 newBalance);
    event EpochMarkStaked(uint256 indexed tokenId, address indexed owner);
    event EpochMarkUnstaked(uint256 indexed tokenId, address indexed owner);
    event CatalystUsed(uint256 indexed tokenId, address indexed catalystCollection, uint256 catalystId, uint256 amount);
    event ExternalTokenBoostDeposited(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount, string attributeKey);
    event ExternalTokenBoostWithdrawn(uint256 indexed tokenId, address indexed tokenAddress);
    event OracleRegistered(string indexed feedId, address indexed oracleAddress);
    event OracleDataReceived(string indexed feedId, uint256 indexed tokenId);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);
    event GovernanceProposalExecuted(bytes callData);

    // Modifiers
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) revert ChronoForge__NotGovernance();
        _;
    }

    modifier onlyOracle(string memory feedId) {
        if (!registeredOracles[feedId].registered || registeredOracles[feedId].oracleAddress != msg.sender) {
            revert ChronoForge__UnauthorizedOracleUpdate();
        }
        _;
    }

    modifier onlyOwnerOrGovernance() {
        if (msg.sender != owner() && msg.sender != governanceAddress) revert ChronoForge__NotOwnerOrGovernance();
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the contract with a name, symbol, and sets the initial governance address.
    /// @param initialGovernance The address that will initially control governance functions (e.g., a DAO contract).
    constructor(address initialGovernance) ERC721("ChronoForge EpochMark", "CFEM") Ownable(initialGovernance) {
        governanceAddress = initialGovernance;
    }

    // --- I. Core EpochMark NFT Management ---

    /// @notice Mints a new EpochMark NFT, assigning it a unique name.
    /// @param to The address to mint the EpochMark to.
    /// @param name_ The initial name for the EpochMark.
    /// @return The tokenId of the newly minted EpochMark.
    function mintEpochMark(address to, string memory name_) public virtual whenNotPaused returns (uint256) {
        _nextTokenId++;
        uint256 newTokenId = _nextTokenId;

        _safeMint(to, newTokenId);

        EpochMarkAttributes storage em = epochMarks[newTokenId];
        em.name = name_;
        em.creationTime = block.timestamp;
        em.lastEvolutionTime = block.timestamp;
        em.lastInsightDecayTime = block.timestamp;
        em.lastEnergyGenerationTime = block.timestamp;

        // Initialize core numeric attributes and track their keys
        em.numericAttributes["Insight"] = 0;
        em.numericAttributeKeys.push("Insight");
        em.numericAttributes["Level"] = 1;
        em.numericAttributeKeys.push("Level");
        em.numericAttributes["ProphecyScore"] = 0;
        em.numericAttributeKeys.push("ProphecyScore");
        em.numericAttributes["TemporalEnergy"] = 0;
        em.numericAttributeKeys.push("TemporalEnergy");
        
        // Initialize core string attributes and track their keys
        em.stringAttributes["AuraColor"] = "#FFD700"; // Default Gold Aura
        em.stringAttributeKeys.push("AuraColor");


        emit EpochMarkMinted(newTokenId, to, name_, block.timestamp);
        return newTokenId;
    }

    /// @notice Generates a dynamic SVG/JSON metadata URI based on the EpochMark's current attributes.
    /// @dev This function creates a data URI for both the JSON metadata and an embedded SVG image,
    ///      allowing for evolving visual and textual representation.
    /// @param tokenId The ID of the EpochMark.
    /// @return A data URI containing the EpochMark's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        EpochMarkAttributes storage em = epochMarks[tokenId];

        string memory name = em.name;
        int256 level = em.numericAttributes["Level"];
        int256 insight = em.numericAttributes["Insight"];
        int256 prophecy = em.numericAttributes["ProphecyScore"];
        int256 energy = em.numericAttributes["TemporalEnergy"];
        string memory auraColor = em.stringAttributes["AuraColor"];
        if (bytes(auraColor).length == 0) { // Fallback if no aura set
            auraColor = "#FFD700";
        }

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style>.base { fill: white; font-family: sans-serif; font-size: 14px; }</style>',
                '<rect width="100%" height="100%" fill="', auraColor, '" />',
                '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', name, '</text>',
                '<text x="50%" y="55%" class="base" dominant-baseline="middle" text-anchor="middle">Level: ', level.toString(), '</text>',
                '<text x="50%" y="65%" class="base" dominant-baseline="middle" text-anchor="middle">Insight: ', insight.toString(), '</text>',
                '<text x="50%" y="75%" class="base" dominant-baseline="middle" text-anchor="middle">Prophecy: ', prophecy.toString(), '</text>',
                '</svg>'
            )
        );
        string memory imageURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg)))
        );

        // Construct attributes array dynamically
        string memory attributesJson = "[";
        bool firstAttribute = true;

        // Add numeric attributes
        for (uint i = 0; i < em.numericAttributeKeys.length; i++) {
            if (!firstAttribute) attributesJson = string(abi.encodePacked(attributesJson, ","));
            attributesJson = string(abi.encodePacked(
                attributesJson,
                '{"trait_type": "', em.numericAttributeKeys[i], '", "value": ', em.numericAttributes[em.numericAttributeKeys[i]].toString(), '}'
            ));
            firstAttribute = false;
        }

        // Add string attributes
        for (uint i = 0; i < em.stringAttributeKeys.length; i++) {
            if (!firstAttribute) attributesJson = string(abi.encodePacked(attributesJson, ","));
            attributesJson = string(abi.encodePacked(
                attributesJson,
                '{"trait_type": "', em.stringAttributeKeys[i], '", "value": "', em.stringAttributes[em.stringAttributeKeys[i]], '"}'
            ));
            firstAttribute = false;
        }
        attributesJson = string(abi.encodePacked(attributesJson, "]"));


        string memory json = string(
            abi.encodePacked(
                '{"name": "', name, '", "description": "An evolving digital identity within ChronoForge.", "image": "', imageURI, '", "attributes": ', attributesJson, '}'
            )
        );

        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json)))
        );
    }

    /// @notice Retrieves all current attributes for a given EpochMark.
    /// @param tokenId The ID of the EpochMark.
    /// @return name_ The EpochMark's name.
    /// @return creationTime_ The creation timestamp.
    /// @return lastEvolutionTime_ The last evolution timestamp.
    /// @return lastInsightDecayTime_ The last Insight decay timestamp.
    /// @return lastEnergyGenerationTime_ The last Temporal Energy generation timestamp.
    /// @return isSoulbound_ Whether the EpochMark is Soulbound.
    /// @return numericAttributeKeys All keys of numeric attributes.
    /// @return numericAttributeValues All values of numeric attributes (in the same order as keys).
    /// @return stringAttributeKeys All keys of string attributes.
    /// @return stringAttributeValues All values of string attributes (in the same order as keys).
    function getEpochMarkAttributes(uint256 tokenId)
        public view
        returns (
            string memory name_,
            uint256 creationTime_,
            uint256 lastEvolutionTime_,
            uint256 lastInsightDecayTime_,
            uint256 lastEnergyGenerationTime_,
            bool isSoulbound_,
            string[] memory numericAttributeKeys,
            int256[] memory numericAttributeValues,
            string[] memory stringAttributeKeys,
            string[] memory stringAttributeValues
        )
    {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        name_ = em.name;
        creationTime_ = em.creationTime;
        lastEvolutionTime_ = em.lastEvolutionTime;
        lastInsightDecayTime_ = em.lastInsightDecayTime;
        lastEnergyGenerationTime_ = em.lastEnergyGenerationTime;
        isSoulbound_ = em.isSoulbound;

        // Populate numeric attributes
        numericAttributeKeys = em.numericAttributeKeys;
        numericAttributeValues = new int256[](numericAttributeKeys.length);
        for (uint i = 0; i < numericAttributeKeys.length; i++) {
            numericAttributeValues[i] = em.numericAttributes[numericAttributeKeys[i]];
        }

        // Populate string attributes
        stringAttributeKeys = em.stringAttributeKeys;
        stringAttributeValues = new string[](stringAttributeKeys.length);
        for (uint i = 0; i < stringAttributeKeys.length; i++) {
            stringAttributeValues[i] = em.stringAttributes[stringAttributeKeys[i]];
        }
    }

    /// @notice Overrides ERC721 transfer to enforce Soulbound-like restrictions.
    /// @dev An EpochMark marked as `isSoulbound` (e.g., when staked) cannot be transferred.
    /// @param from The current owner of the EpochMark.
    /// @param to The address to transfer the EpochMark to.
    /// @param tokenId The ID of the EpochMark.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        if (epochMarks[tokenId].isSoulbound) {
            revert ChronoForge__TransferRestricted();
        }
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Allows the owner to rename their EpochMark.
    /// @param tokenId The ID of the EpochMark.
    /// @param newName The new name for the EpochMark.
    function setEpochMarkName(uint256 tokenId, string memory newName) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        epochMarks[tokenId].name = newName;
        emit EpochMarkAttributeUpdated(tokenId, "Name", 0, newName, false); // 0 for numeric value as it's a string update
    }

    // --- II. Dynamic Attribute Evolution ---

    /// @notice Updates a numeric attribute of an EpochMark.
    /// @dev Can be called by the EpochMark owner, governance, or internally (e.g., by quest completion, catalyst).
    ///      For oracles, `receiveOracleData` should be used.
    /// @param tokenId The ID of the EpochMark.
    /// @param attributeKey The key of the numeric attribute to update (e.g., "Level", "Strength").
    /// @param valueChange The amount to change the attribute by.
    /// @param absoluteSet If true, `valueChange` is set as the new absolute value; otherwise, it's added/subtracted.
    function updateAttributeNumeric(uint256 tokenId, string memory attributeKey, int256 valueChange, bool absoluteSet) public whenNotPaused {
        // Allow owner for their own NFT, governance for any. Oracles use a dedicated function.
        if (ownerOf(tokenId) != msg.sender && msg.sender != governanceAddress) revert ChronoForge__NotOwnerOrGovernance();
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        if (absoluteSet) {
            em.numericAttributes[attributeKey] = valueChange;
        } else {
            em.numericAttributes[attributeKey] += valueChange;
        }

        // Add key to list if it's new
        bool found = false;
        for(uint i = 0; i < em.numericAttributeKeys.length; i++) {
            if (keccak256(abi.encodePacked(em.numericAttributeKeys[i])) == keccak256(abi.encodePacked(attributeKey))) {
                found = true;
                break;
            }
        }
        if (!found) {
            em.numericAttributeKeys.push(attributeKey);
        }

        emit EpochMarkAttributeUpdated(tokenId, attributeKey, em.numericAttributes[attributeKey], "", true);
    }

    /// @notice Updates a string attribute of an EpochMark.
    /// @dev Can be called by the EpochMark owner, governance, or internally.
    /// @param tokenId The ID of the EpochMark.
    /// @param attributeKey The key of the string attribute to update (e.g., "Title", "AuraColor").
    /// @param newValue The new string value for the attribute.
    function updateAttributeString(uint256 tokenId, string memory attributeKey, string memory newValue) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender && msg.sender != governanceAddress) revert ChronoForge__NotOwnerOrGovernance();
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        em.stringAttributes[attributeKey] = newValue;
        
        // Add key to list if it's new
        bool found = false;
        for(uint i = 0; i < em.stringAttributeKeys.length; i++) {
            if (keccak256(abi.encodePacked(em.stringAttributeKeys[i])) == keccak256(abi.encodePacked(attributeKey))) {
                found = true;
                break;
            }
        }
        if (!found) {
            em.stringAttributeKeys.push(attributeKey);
        }

        emit EpochMarkAttributeUpdated(tokenId, attributeKey, 0, newValue, false);
    }

    /// @notice Initiates a re-evaluation of an EpochMark's attributes based on various triggers.
    /// @dev This can include applying time-based effects, checking for level-ups, etc. Callable by owner.
    /// @param tokenId The ID of the EpochMark to evolve.
    function triggerEvolutionCycle(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        require(ownerOf(tokenId) == msg.sender, "ChronoForge: Only owner can trigger evolution");

        EpochMarkAttributes storage em = epochMarks[tokenId];

        // Example: If Insight reaches a threshold, increase Level
        int256 currentInsight = em.numericAttributes["Insight"];
        int256 currentLevel = em.numericAttributes["Level"];

        // Level-up logic
        // Level 1: 1000 Insight, Level 2: 2000, Level 3: 3000...
        // This is simplified; real dApps might use exponential curves.
        uint256 nextLevelThreshold = currentLevel.toUint256() * 1000;
        if (currentInsight >= int256(nextLevelThreshold) && currentLevel < 100) { // Cap level at 100 for example
            em.numericAttributes["Level"]++;
            em.numericAttributes["Insight"] = currentInsight - int256(nextLevelThreshold); // Consume Insight for level up
            // No need to push keys, they are core attributes
        }
        
        // Call passive generation functions if due
        generateTemporalEnergy(tokenId); // Might generate energy if interval passed
        decayInsight(tokenId); // Might decay insight if interval passed

        em.lastEvolutionTime = block.timestamp;
        emit EpochMarkEvolved(tokenId, block.timestamp);
    }

    /// @notice Registers an external oracle address allowed to push specific data.
    /// @dev Only governance can register oracles. A `feedId` uniquely identifies the type of data.
    /// @param oracleAddress The address of the oracle contract or EOA.
    /// @param feedId A unique identifier for the data feed this oracle provides (e.g., "market_sentiment").
    function registerOracleFeed(address oracleAddress, string memory feedId) public onlyGovernance whenNotPaused {
        require(oracleAddress != address(0), "ChronoForge: Oracle address cannot be zero");
        registeredOracles[feedId] = OracleFeed(oracleAddress, true);
        emit OracleRegistered(feedId, oracleAddress);
    }

    /// @notice Callback for registered oracles to push data that influences EpochMark attributes.
    /// @dev The `data` parameter should be decoded by the contract based on `feedId`.
    ///      Example: `feedId` "market_sentiment" could influence "AuraColor" or "ProphecyScore".
    /// @param feedId The ID of the registered oracle feed.
    /// @param tokenId The ID of the EpochMark to update.
    /// @param data Arbitrary data provided by the oracle (e.g., encoded values, strings).
    function receiveOracleData(string memory feedId, uint256 tokenId, bytes memory data) public onlyOracle(feedId) whenNotPaused {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        // Example decoding logic based on feedId
        if (keccak256(abi.encodePacked(feedId)) == keccak256(abi.encodePacked("market_sentiment"))) {
            // Assume data is a uint8 representing sentiment (0-2: bearish, 3-7: neutral, 8-10: bullish)
            uint8 sentiment = abi.decode(data, (uint8));
            string memory newAuraColor;
            if (sentiment <= 2) newAuraColor = "#FF0000"; // Red
            else if (sentiment >= 8) newAuraColor = "#00FF00"; // Green
            else newAuraColor = "#FFFF00"; // Yellow
            updateAttributeString(tokenId, "AuraColor", newAuraColor); // Internal call
        } else if (keccak256(abi.encodePacked(feedId)) == keccak256(abi.encodePacked("l2_activity_summary"))) {
            // Assume data is int256 representing "L2ActivityScore"
            int256 activityScore = abi.decode(data, (int256));
            updateAttributeNumeric(tokenId, "L2ActivityScore", activityScore, true); // Set absolutely
        }
        // Add more oracle data processing logic here for other feedIds

        emit OracleDataReceived(feedId, tokenId);
    }

    // --- III. Reputation & Insight System ---

    /// @notice Awards "Insight" points to an EpochMark, reflecting engagement.
    /// @dev Can be called by governance, oracles (via receiveOracleData), or implicitly by other contract actions (e.g., quest completion).
    /// @param tokenId The ID of the EpochMark.
    /// @param amount The amount of Insight to accrue.
    function accrueInsight(uint256 tokenId, uint256 amount) public whenNotPaused {
        // Only owner or governance can directly accrue (or via internal calls)
        if (ownerOf(tokenId) != msg.sender && msg.sender != governanceAddress) revert ChronoForge__NotOwnerOrGovernance();
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        em.numericAttributes["Insight"] += int256(amount);
        emit InsightAccrued(tokenId, amount, em.numericAttributes["Insight"].toUint256());
    }

    /// @notice Periodically reduces an EpochMark's Insight score to reflect ongoing relevance.
    /// @dev This function is designed to be permissionless; anyone can call it for any NFT,
    ///      but the decay only occurs if the `INSIGHT_DECAY_INTERVAL` has passed.
    /// @param tokenId The ID of the EpochMark.
    function decayInsight(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        if (block.timestamp < em.lastInsightDecayTime + INSIGHT_DECAY_INTERVAL) {
            return; // Not yet time for decay
        }

        int256 currentInsight = em.numericAttributes["Insight"];
        if (currentInsight > 0) {
            // Calculate decay amount ensuring it doesn't go below zero
            uint256 decayAmount = (currentInsight.toUint256() * INSIGHT_DECAY_RATE) / 100;
            if (decayAmount == 0 && currentInsight > 0) decayAmount = 1; // Ensure at least 1 point decays if insight > 0
            
            em.numericAttributes["Insight"] -= int256(decayAmount);
            if (em.numericAttributes["Insight"] < 0) em.numericAttributes["Insight"] = 0; // Cap at 0
            emit InsightDecayed(tokenId, decayAmount, em.numericAttributes["Insight"].toUint256());
        }

        em.lastInsightDecayTime = block.timestamp;
    }

    /// @notice Retrieves the current Insight score of an EpochMark.
    /// @param tokenId The ID of the EpochMark.
    /// @return The current Insight score.
    function getInsightScore(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        return epochMarks[tokenId].numericAttributes["Insight"].toUint256();
    }

    /// @notice Calculates and updates a predictive "Prophecy Score" based on Insight, Level, and activity patterns.
    /// @dev This score could reflect future potential, community impact, or predicted behavior.
    ///      Complex logic might involve historical data, staked tokens, quest completions, etc.
    ///      Only callable by governance or time-based trigger.
    /// @param tokenId The ID of the EpochMark.
    function updateProphecyScore(uint256 tokenId) public whenNotPaused {
        require(msg.sender == governanceAddress, "ChronoForge: Only governance can update prophecy score");
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        // For simplicity, using lastEvolutionTime as a cooldown, but a dedicated timestamp could be used.
        if (block.timestamp < em.lastEvolutionTime + PROPHECY_SCORE_CALCULATION_INTERVAL) {
            return;
        }

        // Example Prophecy Score Calculation (highly simplified):
        // (Insight / 100) + (Level * 5) + (number of quests completed) + (TemporalEnergy / 50) + (external stake boost) - (age-based decay)
        int256 currentInsight = em.numericAttributes["Insight"];
        int256 currentLevel = em.numericAttributes["Level"];
        uint256 completedQuestsCount = 0;
        for (uint256 i = 1; i <= _nextQuestId; i++) { // Iterate all possible quest IDs
            if (epochQuests[i].isApproved && epochQuestCompletions[tokenId][i]) {
                completedQuestsCount++;
            }
        }

        int256 newProphecyScore = (currentInsight / 100) + (currentLevel * 5) + int256(completedQuestsCount * 10);
        
        if (em.numericAttributes["TemporalEnergy"] > 0) {
            newProphecyScore += (em.numericAttributes["TemporalEnergy"] / 50);
        }
        if (externalTokenStakes[tokenId].amount > 0) {
            newProphecyScore += (int256(externalTokenStakes[tokenId].amount) / 1000); // Small boost from external stake
        }

        // Apply some "decay" for very old EpochMarks to prevent stagnation
        if (block.timestamp > em.creationTime + (365 days * 2)) { // After 2 years
            newProphecyScore -= (newProphecyScore / 10); // 10% decay
        }
        if (newProphecyScore < 0) newProphecyScore = 0; // Cap at 0

        em.numericAttributes["ProphecyScore"] = newProphecyScore;
        emit ProphecyScoreUpdated(tokenId, newProphecyScore);
    }

    // --- IV. Gamification & Quests (Epoch Quests) ---

    /// @notice Allows anyone to propose new quests with specific rewards and attribute changes.
    /// @dev Proposed quests require governance approval to become active.
    /// @param title The title of the quest.
    /// @param description The description of the quest.
    /// @param insightReward The amount of Insight awarded upon completion.
    /// @param affectedAttributeKeys An array of attribute keys to be modified.
    /// @param affectedAttributeValues An array of corresponding value changes for the attributes.
    function proposeEpochQuest(
        string memory title,
        string memory description,
        uint256 insightReward,
        string[] memory affectedAttributeKeys,
        int256[] memory affectedAttributeValues
    ) public whenNotPaused {
        if (affectedAttributeKeys.length != affectedAttributeValues.length) {
            revert ChronoForge__QuestAttributeMismatch();
        }

        _nextQuestId++;
        uint256 newQuestId = _nextQuestId;

        EpochQuest storage eq = epochQuests[newQuestId];
        eq.title = title;
        eq.description = description;
        eq.insightReward = insightReward;
        eq.affectedAttributeKeys = affectedAttributeKeys;
        eq.affectedAttributeValues = affectedAttributeValues;
        eq.isApproved = false; // Requires governance approval
        eq.creationTime = block.timestamp;

        emit EpochQuestProposed(newQuestId, title, msg.sender);
    }

    /// @notice Governance approves a proposed quest, making it active.
    /// @dev Only callable by the governance address.
    /// @param questId The ID of the quest to approve.
    function approveEpochQuest(uint256 questId) public onlyGovernance whenNotPaused {
        EpochQuest storage eq = epochQuests[questId];
        if (bytes(eq.title).length == 0) revert ChronoForge__QuestNotFound();
        require(!eq.isApproved, "ChronoForge: Quest already approved");

        eq.isApproved = true;
        emit EpochQuestApproved(questId);
    }

    /// @notice Allows an EpochMark holder to claim completion of an approved quest.
    /// @dev This function currently allows direct claim; in a real dApp, it would include
    ///      verification logic (e.g., proof of holding, external contract interaction).
    /// @param tokenId The ID of the EpochMark completing the quest.
    /// @param questId The ID of the quest being completed.
    function completeEpochQuest(uint256 tokenId, uint256 questId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochQuest storage eq = epochQuests[questId];
        if (bytes(eq.title).length == 0) revert ChronoForge__QuestNotFound();
        if (!eq.isApproved) revert ChronoForge__QuestNotApproved();
        if (epochQuestCompletions[tokenId][questId]) revert ChronoForge__QuestAlreadyCompleted();

        // Award Insight
        accrueInsight(tokenId, eq.insightReward); // Use internal accrual function

        // Apply attribute changes defined by the quest
        for (uint i = 0; i < eq.affectedAttributeKeys.length; i++) {
            updateAttributeNumeric(tokenId, eq.affectedAttributeKeys[i], eq.affectedAttributeValues[i], false); // Add/subtract
        }

        epochQuestCompletions[tokenId][questId] = true;
        emit EpochQuestCompleted(tokenId, questId);
    }

    /// @notice Returns a list of all currently active (approved) Epoch Quests.
    /// @return An array of quest IDs for active quests.
    function getCurrentEpochQuests() public view returns (uint256[] memory) {
        uint256[] memory tempQuestIds = new uint256[](_nextQuestId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _nextQuestId; i++) {
            if (epochQuests[i].isApproved) {
                tempQuestIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = tempQuestIds[i];
        }
        return result;
    }

    /// @notice Retrieves the full details of a specific quest.
    /// @param questId The ID of the quest.
    /// @return title_, description_, insightReward_, affectedAttributeKeys_, affectedAttributeValues_, isApproved_, creationTime_
    function getQuestDetails(uint256 questId)
        public view
        returns (
            string memory title_,
            string memory description_,
            uint256 insightReward_,
            string[] memory affectedAttributeKeys_,
            int256[] memory affectedAttributeValues_,
            bool isApproved_,
            uint256 creationTime_
        )
    {
        EpochQuest storage eq = epochQuests[questId];
        if (bytes(eq.title).length == 0) revert ChronoForge__QuestNotFound();

        title_ = eq.title;
        description_ = eq.description;
        insightReward_ = eq.insightReward;
        affectedAttributeKeys_ = eq.affectedAttributeKeys;
        affectedAttributeValues_ = eq.affectedAttributeValues;
        isApproved_ = eq.isApproved;
        creationTime_ = eq.creationTime;
    }

    // --- V. Temporal Energy & Resource Management ---

    /// @notice Generates "Temporal Energy" for a staked EpochMark.
    /// @dev This function is permissionless; anyone can call it, but energy is only generated if the EpochMark is staked
    ///      and the `ENERGY_GENERATION_INTERVAL` has passed.
    /// @param tokenId The ID of the EpochMark.
    function generateTemporalEnergy(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        if (!epochMarkStakedForEnergy[tokenId]) return; // Only staked EpochMarks generate energy

        EpochMarkAttributes storage em = epochMarks[tokenId];
        if (block.timestamp < em.lastEnergyGenerationTime + ENERGY_GENERATION_INTERVAL) {
            return; // Not yet time for energy generation
        }

        uint256 timeElapsed = block.timestamp - em.lastEnergyGenerationTime;
        uint256 intervals = timeElapsed / ENERGY_GENERATION_INTERVAL;
        if (intervals == 0) return;

        uint256 generatedAmount = intervals * TEMPORAL_ENERGY_GENERATION_RATE;
        em.numericAttributes["TemporalEnergy"] += int256(generatedAmount);
        em.lastEnergyGenerationTime = block.timestamp;

        emit TemporalEnergyGenerated(tokenId, generatedAmount, em.numericAttributes["TemporalEnergy"].toUint256());
    }

    /// @notice Consumes Temporal Energy from an EpochMark for specific actions.
    /// @dev Callable by the EpochMark owner.
    /// @param tokenId The ID of the EpochMark.
    /// @param amount The amount of Temporal Energy to spend.
    function spendTemporalEnergy(uint256 tokenId, uint256 amount) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        EpochMarkAttributes storage em = epochMarks[tokenId];
        if (em.numericAttributes["TemporalEnergy"].toUint256() < amount) {
            revert ChronoForge__InsufficientTemporalEnergy();
        }

        em.numericAttributes["TemporalEnergy"] -= int256(amount);
        emit TemporalEnergySpent(tokenId, amount, em.numericAttributes["TemporalEnergy"].toUint256());
    }

    /// @notice Retrieves the current Temporal Energy balance of an EpochMark.
    /// @param tokenId The ID of the EpochMark.
    /// @return The current Temporal Energy balance.
    function getTemporalEnergyBalance(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        return epochMarks[tokenId].numericAttributes["TemporalEnergy"].toUint256();
    }

    // --- VI. Staking & Catalysts ---

    /// @notice Stakes an EpochMark to passively generate Temporal Energy.
    /// @dev A staked EpochMark becomes temporarily Soulbound (non-transferable). Callable by owner.
    /// @param tokenId The ID of the EpochMark to stake.
    function stakeEpochMarkForEnergy(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        if (epochMarkStakedForEnergy[tokenId]) revert ChronoForge__EpochMarkAlreadyStaked();

        // Mark as staked and prevent transfers
        epochMarkStakedForEnergy[tokenId] = true;
        epochMarks[tokenId].isSoulbound = true; // A temporary Soulbound state while staked.
        epochMarks[tokenId].lastEnergyGenerationTime = block.timestamp; // Reset generation timer

        emit EpochMarkStaked(tokenId, msg.sender);
    }

    /// @notice Unstakes an EpochMark.
    /// @dev Callable by owner. Automatically triggers energy generation before unstaking.
    /// @param tokenId The ID of the EpochMark to unstake.
    function unstakeEpochMarkFromEnergy(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        if (!epochMarkStakedForEnergy[tokenId]) revert ChronoForge__EpochMarkNotStaked();

        // Allow owner to claim generated energy immediately before unstaking.
        generateTemporalEnergy(tokenId);

        // Mark as unstaked and remove temporary Soulbound state.
        epochMarkStakedForEnergy[tokenId] = false;
        epochMarks[tokenId].isSoulbound = false;

        emit EpochMarkUnstaked(tokenId, msg.sender);
    }

    /// @notice Consumes an ERC1155 "Catalyst" item to influence EpochMark attributes.
    /// @dev The effect of the catalyst (which attribute it changes and by how much) is determined
    ///      by the `catalystId` and potentially the `catalystCollection`. Requires ERC1155 approval.
    /// @param tokenId The ID of the EpochMark to apply the catalyst to.
    /// @param catalystCollection The address of the ERC1155 contract holding the catalyst.
    /// @param catalystId The ID of the specific catalyst item within the collection.
    /// @param amount The quantity of the catalyst to consume.
    function useCatalyst(uint256 tokenId, address catalystCollection, uint256 catalystId, uint256 amount) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        require(amount > 0, "ChronoForge: Catalyst amount must be greater than zero");

        IERC1155(catalystCollection).safeTransferFrom(msg.sender, address(this), catalystId, amount, "");

        // Apply catalyst effect based on catalystId. This is example logic.
        // In a real system, this might be a configurable mapping or an oracle-fed system.
        if (catalystId == 1) { // Catalyst of Strength
            updateAttributeNumeric(tokenId, "Strength", int256(10 * amount), false); // Add strength
        } else if (catalystId == 2) { // Catalyst of Wisdom
            updateAttributeNumeric(tokenId, "Wisdom", int256(5 * amount), false); // Add wisdom
        } else if (catalystId == 3) { // Catalyst of Resurgence
            updateAttributeNumeric(tokenId, "Insight", int256(100 * amount), false); // Boost Insight
        } else if (catalystId == 4) { // Catalyst of Aura Change
            if (amount > 0) updateAttributeString(tokenId, "AuraColor", "#9932CC"); // Example: Purple aura
        } else {
            revert ChronoForge__AttributeNotFound(); // Or a more specific catalyst error if ID is unknown
        }

        emit CatalystUsed(tokenId, catalystCollection, catalystId, amount);
    }

    /// @notice Stakes an external ERC20 token to temporarily boost a specific attribute of an EpochMark.
    /// @dev Allows users to leverage other assets to influence their dNFTs.
    ///      Only one external token can boost a specific attribute per EpochMark at a time (simplification).
    /// @param tokenId The ID of the EpochMark.
    /// @param tokenAddress The address of the ERC20 token to stake.
    /// @param amount The amount of ERC20 tokens to stake.
    /// @param attributeKey The attribute this stake will temporarily boost.
    function depositExternalTokenForBoost(uint256 tokenId, address tokenAddress, uint256 amount, string memory attributeKey) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();
        require(amount > 0, "ChronoForge: Stake amount must be greater than zero");
        require(tokenAddress != address(0), "ChronoForge: Token address cannot be zero");

        // Ensure no existing stake for this EpochMark's attribute
        if (externalTokenStakes[tokenId].tokenAddress != address(0) && keccak256(abi.encodePacked(externalTokenStakes[tokenId].attributeKey)) == keccak256(abi.encodePacked(attributeKey))) {
            revert ChronoForge__AlreadyBoostingAttribute();
        }

        // Transfer tokens to the contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        externalTokenStakes[tokenId] = ExternalTokenStake({
            tokenAddress: tokenAddress,
            amount: amount,
            attributeKey: attributeKey,
            stakeTime: block.timestamp
        });

        // Apply temporary boost (example: 1 boost point per 1000 tokens)
        int256 boostValue = int256(amount / 1000); // Customize boost logic
        if (boostValue > 0) {
            updateAttributeNumeric(tokenId, attributeKey, boostValue, false);
        }

        emit ExternalTokenBoostDeposited(tokenId, tokenAddress, amount, attributeKey);
    }

    /// @notice Withdraws staked external ERC20 tokens and removes the associated attribute boost.
    /// @param tokenId The ID of the EpochMark.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    function withdrawExternalTokenBoost(uint256 tokenId, address tokenAddress) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, tokenId);
        if (!_exists(tokenId)) revert ChronoForge__EpochMarkNotFound();

        ExternalTokenStake storage stake = externalTokenStakes[tokenId];
        if (stake.tokenAddress == address(0) || stake.tokenAddress != tokenAddress) {
            revert ChronoForge__NoExternalTokenStakeFound();
        }

        uint256 amount = stake.amount;
        string memory attributeKey = stake.attributeKey;

        // Remove the boost
        int256 boostValue = int256(amount / 1000);
        if (boostValue > 0) {
            updateAttributeNumeric(tokenId, attributeKey, -boostValue, false); // Subtract the boost
        }

        // Transfer tokens back to the owner
        IERC20(tokenAddress).transfer(msg.sender, amount);

        // Clear the stake record
        delete externalTokenStakes[tokenId];

        emit ExternalTokenBoostWithdrawn(tokenId, tokenAddress);
    }

    // --- VII. Governance (DAO Interaction) ---

    /// @notice Transfers ownership/governance control to a new DAO address.
    /// @dev Callable only by the current governance address.
    /// @param newGovernanceAddress The address of the new governing entity.
    function setGovernanceAddress(address newGovernanceAddress) public onlyGovernance {
        require(newGovernanceAddress != address(0), "ChronoForge: New governance address cannot be zero");
        emit GovernanceTransferred(governanceAddress, newGovernanceAddress);
        governanceAddress = newGovernanceAddress;
    }

    /// @notice Allows the governing DAO to execute arbitrary proposals.
    /// @dev This is a powerful function, typically restricted to a robust DAO contract
    ///      that has voting mechanisms in place before calling this.
    /// @param callData The encoded function call (target address, function selector, arguments) to execute.
    function executeGovernanceProposal(bytes memory callData) public onlyGovernance {
        (bool success, ) = address(this).call(callData);
        require(success, "ChronoForge: Governance proposal execution failed");
        emit GovernanceProposalExecuted(callData);
    }

    // --- VIII. Admin/Utility ---

    /// @notice Pauses critical contract functions.
    /// @dev Only callable by the governance address. Inherited from OpenZeppelin Pausable.
    function pause() public onlyGovernance {
        _pause();
    }

    /// @notice Unpauses critical contract functions.
    /// @dev Only callable by the governance address. Inherited from OpenZeppelin Pausable.
    function unpause() public onlyGovernance {
        _unpause();
    }

    /// @notice Allows governance to withdraw accidentally sent ERC20 tokens.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address tokenAddress, uint256 amount) public onlyGovernance {
        IERC20(tokenAddress).transfer(governanceAddress, amount);
    }

    /// @notice Allows governance to withdraw accidentally sent ETH.
    /// @param amount The amount of ETH to withdraw.
    function emergencyWithdrawETH(uint256 amount) public onlyGovernance {
        payable(governanceAddress).transfer(amount);
    }
}

// Minimal IERC20 and IERC1155 interfaces for external token interaction
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
}
```