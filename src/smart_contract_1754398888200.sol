Here's a smart contract for an **EvoMind Core**, representing an advanced, dynamic, and evolving digital entity. This contract integrates ERC-721 NFTs with a "cognitive state" and "knowledge base" that adapts based on user interactions, staked resources, and simulated environmental events. It aims to create an illusion of on-chain intelligence and adaptive behavior for a digital asset.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/abs

/**
 * @title EvoMindCore
 * @dev An advanced smart contract for dynamic, evolving digital entities represented as NFTs.
 *      Each EvoMind possesses a unique "cognitive state" and "knowledge base" that adapts
 *      based on on-chain interactions, contributions, and environmental events.
 *      EvoMinds can be "powered" by staked tokens and can simulate autonomous decision-making
 *      or delegate actions based on their evolved state.
 *
 * @outline
 * 1.  **Core NFT Management (ERC-721 Standard Functions with Dynamic URI)**
 *     - Basic minting, burning, and ownership transfer.
 *     - `tokenURI` dynamically generates metadata based on the EvoMind's current attributes.
 * 2.  **EvoMind Cognitive State & Attributes**
 *     - Definition of core attributes: `level`, `xp`, `focus`, `creativity`, `adaptability`, `resourceAffinity`, `lastActivityTimestamp`, `mutationSeed`, `knowledgeBaseHash`.
 *     - Functions to retrieve and update these attributes, primarily driven by internal logic or privileged calls.
 * 3.  **Evolution & Adaptation Mechanics**
 *     - Accruing experience points (XP) and triggering level-ups.
 *     - Mutation mechanism that alters attributes based on external triggers or internal state.
 *     - Functions to process simulated "environmental events" that influence cognitive parameters.
 * 4.  **Resource Management & Empowerment**
 *     - Users can stake ERC-20 tokens (Power Tokens) to their EvoMind, "powering" its capabilities.
 *     - EvoMinds can, under certain conditions or owner delegation, execute actions (e.g., interact with other contracts) based on their evolved state.
 * 5.  **Simulated Cognition & Decision Making**
 *     - Functions to record "successful strategies" or "knowledge" into an EvoMind's memory.
 *     - Functions that simulate a "decision-making" process or an "adaptive response" based on the EvoMind's cognitive state.
 *     - Mechanism to "challenge" an EvoMind to test its adaptive capabilities.
 * 6.  **Admin & Configuration**
 *     - Functions for the owner to set base URI, adjust XP requirements, and claim funds.
 *
 * @function_summary
 * 1.  `constructor(string memory name, string memory symbol, address powerTokenAddress_)`: Initializes the contract, sets the ERC-721 name/symbol and the address of the ERC-20 power token.
 * 2.  `mintEvoMind(address owner_) external returns (uint256)`: Mints a new EvoMind NFT for a specified owner with initial attributes. Only callable by owner or approved minter.
 * 3.  `burnEvoMind(uint256 tokenId) external`: Burns an EvoMind NFT, removing its attributes and staked tokens. Only callable by owner or approved.
 * 4.  `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates the dynamic JSON metadata for an EvoMind NFT, reflecting its current attributes.
 * 5.  `getEvoMindAttributes(uint256 tokenId) public view returns (EvoMindAttributes memory)`: Retrieves all current attributes of a given EvoMind.
 * 6.  `setBaseURI(string memory newBaseURI) external onlyOwner`: Allows the owner to update the base URI for metadata.
 * 7.  `_accrueXP(uint256 tokenId, uint256 amount) internal`: Internal helper function to add XP to an EvoMind.
 * 8.  `triggerLevelUp(uint256 tokenId) external`: Public function allowing anyone to attempt to level up an EvoMind if it meets XP requirements. Rewards the caller if successful.
 * 9.  `mutateEvoMind(uint256 tokenId, bytes32 mutationParam) external`: Triggers a mutation event for an EvoMind, altering its cognitive parameters based on `mutationParam`. Can be called by anyone, but its effect is randomized based on `mutationParam` and EvoMind's `adaptability`.
 * 10. `updateCognitiveParameter(uint256 tokenId, string memory paramName, int256 delta) external onlyOwner`: Allows the contract owner to adjust a specific cognitive parameter of an EvoMind (e.g., for balancing or specific events).
 * 11. `getEvoMindCognitiveState(uint256 tokenId) public view returns (int256 focus, int256 creativity, int256 adaptability, int256 resourceAffinity)`: Returns the current values of an EvoMind's core cognitive parameters.
 * 12. `queryEvoMindKnowledge(uint256 tokenId, bytes32 knowledgeKey) public view returns (uint256)`: Queries the EvoMind's internal knowledge base for a specific key.
 * 13. `stakePowerTokens(uint256 tokenId, uint256 amount) external`: Allows an owner to stake `powerToken` to their EvoMind, increasing its `resourceAffinity`.
 * 14. `unstakePowerTokens(uint256 tokenId, uint256 amount) external`: Allows an owner to unstake `powerToken` from their EvoMind.
 * 15. `getEvoMindStakedBalance(uint256 tokenId) public view returns (uint256)`: Returns the amount of `powerToken` staked to a given EvoMind.
 * 16. `delegateEvoMindAction(uint256 tokenId, address targetContract, bytes memory callData) external returns (bool success, bytes memory result)`: Allows the owner to instruct their EvoMind to perform a delegated action on another contract. EvoMind's `adaptability` can influence its success.
 * 17. `setDelegatedRecipient(uint256 tokenId, address recipient) external`: Sets an approved recipient for delegated actions from the EvoMind, allowing a specific address to trigger `delegateEvoMindAction` without direct owner call (e.g., a DAO or protocol).
 * 18. `processEnvironmentalEvent(uint256 tokenId, bytes32 eventHash, uint256 eventValue) external onlyOwner`: Simulates an external environmental event affecting an EvoMind's attributes. Event value can represent severity or impact.
 * 19. `initiateAdaptiveResponse(uint256 tokenId, bytes32 contextHash) public view returns (uint256 suggestedActionValue)`: Simulates an EvoMind's adaptive response based on its current cognitive state and a given context. Returns a weighted "suggestion".
 * 20. `recordSuccessfulStrategy(uint256 tokenId, bytes32 strategyHash, uint256 value) external`: Records a successful strategy or piece of knowledge for an EvoMind, influencing its future responses. Can only be set by owner or through successful challenge.
 * 21. `challengeEvoMind(uint256 tokenId, bytes32 challengeInput) external returns (bool success)`: A public challenge that an EvoMind can attempt. Success depends on its attributes and the challenge input, and rewards XP.
 * 22. `claimEvoMindRewards(uint256 tokenId) external`: Allows EvoMind owners to claim any accrued rewards (simulated or actual) based on their EvoMind's activities. Rewards are based on `resourceAffinity` and activity.
 * 23. `simulateDecisionMaking(uint256 tokenId, uint256 decisionBias) public view returns (uint256 decisionOutcome)`: Provides a simulated decision outcome based on the EvoMind's attributes and an input bias, reflecting its "cognitive" preference.
 * 24. `getEvoMindTraitScore(uint256 tokenId, string memory traitName) public view returns (int256 score)`: Returns a calculated "score" for a given abstract trait (e.g., 'Innovation', 'Resilience') derived from the EvoMind's cognitive parameters.
 * 25. `refreshActivityTimestamp(uint256 tokenId) external`: Updates the last activity timestamp for an EvoMind, potentially preventing inactivity decay or enabling time-based rewards.
 * 26. `setXpForLevel(uint256 level, uint256 xpRequired) external onlyOwner`: Sets the XP required for a specific level by the contract owner.
 * 27. `setMinter(address minterAddress, bool allowed) external onlyOwner`: Grants or revokes permission for an address to mint EvoMinds.
 * 28. `withdrawERC20(address tokenAddress, address recipient, uint256 amount) external onlyOwner`: Allows the contract owner to withdraw any stuck ERC20 tokens from the contract.
 */
contract EvoMindCore is ERC721, Ownable {
    using Strings for uint256;
    using Math for uint256;
    using Math for int256;

    // --- Events ---
    event EvoMindMinted(uint256 indexed tokenId, address indexed owner);
    event EvoMindLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event EvoMindMutated(uint256 indexed tokenId, bytes32 indexed mutationParam);
    event EvoMindXPAccrued(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event CognitiveParameterUpdated(uint256 indexed tokenId, string paramName, int256 delta, int256 newValue);
    event PowerTokensStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event PowerTokensUnstaked(uint256 indexed tokenId, address indexed unstaker, uint256 amount);
    event EvoMindActionDelegated(uint256 indexed tokenId, address indexed targetContract, bool success);
    event EnvironmentalEventProcessed(uint256 indexed tokenId, bytes32 eventHash, uint256 eventValue);
    event StrategyRecorded(uint256 indexed tokenId, bytes32 strategyHash, uint256 value);
    event EvoMindChallenged(uint256 indexed tokenId, bool success);
    event EvoMindRewardsClaimed(uint256 indexed tokenId, uint256 amount);
    event DelegatedRecipientSet(uint256 indexed tokenId, address indexed recipient);

    // --- Structures ---
    struct EvoMindAttributes {
        uint256 level;
        uint256 xp;
        int256 focus; // Affects precision in adaptive response
        int256 creativity; // Affects range of mutation and decision making
        int256 adaptability; // Affects success rate of challenges and delegated actions
        int256 resourceAffinity; // Affects yield from staked tokens and reward claiming
        uint256 lastActivityTimestamp;
        uint256 mutationSeed; // Seed for random-like mutations
        // A simple on-chain knowledge base, mapping hash of 'fact' to its 'value'
        mapping(bytes32 => uint256) knowledgeBase;
        // Track unique knowledge keys for gas efficiency during iteration (optional for MVP)
        // bytes32[] knowledgeKeys;
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => EvoMindAttributes) private _evoMindAttributes;
    mapping(uint256 => uint256) private _stakedPowerTokens; // tokenId => amount of power tokens
    mapping(uint256 => address) private _delegatedRecipients; // tokenId => address allowed to trigger delegated actions
    mapping(uint256 => uint256) private _xpRequiredForLevel; // level => xp required
    mapping(address => bool) private _minters; // Addresses allowed to mint EvoMinds

    IERC20 public immutable powerToken; // The ERC-20 token used to "power" EvoMinds

    string private _baseURI;

    // --- Modifiers ---
    modifier onlyEvoMindOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EvoMindCore: Caller is not owner nor approved");
        _;
    }

    modifier onlyMinter() {
        require(_minters[_msgSender()], "EvoMindCore: Caller is not a minter");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address powerTokenAddress_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        powerToken = IERC20(powerTokenAddress_);
        _minters[msg.sender] = true; // Owner is a default minter

        // Set initial XP requirements (can be configured later)
        _xpRequiredForLevel[1] = 0;
        _xpRequiredForLevel[2] = 100;
        _xpRequiredForLevel[3] = 250;
        _xpRequiredForLevel[4] = 500;
        _xpRequiredForLevel[5] = 1000;
        // ... more levels can be pre-set or dynamically added
    }

    // --- I. Core NFT Management ---

    /**
     * @dev Mints a new EvoMind NFT to a specified owner with initial attributes.
     * Only callable by the contract owner or an approved minter.
     * @param owner_ The address to mint the EvoMind to.
     * @return The tokenId of the newly minted EvoMind.
     */
    function mintEvoMind(address owner_) external onlyMinter returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(owner_, newTokenId);

        // Initialize EvoMind attributes
        EvoMindAttributes storage attrs = _evoMindAttributes[newTokenId];
        attrs.level = 1;
        attrs.xp = 0;
        attrs.focus = 50; // Initial cognitive parameters
        attrs.creativity = 50;
        attrs.adaptability = 50;
        attrs.resourceAffinity = 0; // Starts with no affinity (needs staking)
        attrs.lastActivityTimestamp = block.timestamp;
        attrs.mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId)));

        emit EvoMindMinted(newTokenId, owner_);
        return newTokenId;
    }

    /**
     * @dev Burns an EvoMind NFT, removing its attributes and unstaking any power tokens.
     * Callable by the owner of the EvoMind or an approved address.
     * @param tokenId The ID of the EvoMind to burn.
     */
    function burnEvoMind(uint256 tokenId) external {
        address ownerOfEvoMind = ownerOf(tokenId);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EvoMindCore: Not owner or approved to burn");
        
        if (_stakedPowerTokens[tokenId] > 0) {
            uint256 amountToUnstake = _stakedPowerTokens[tokenId];
            _stakedPowerTokens[tokenId] = 0;
            // Transfer back to the original owner of the EvoMind
            powerToken.transfer(ownerOfEvoMind, amountToUnstake);
            emit PowerTokensUnstaked(tokenId, ownerOfEvoMind, amountToUnstake);
        }

        delete _evoMindAttributes[tokenId];
        delete _delegatedRecipients[tokenId]; // Clear delegated recipient on burn
        _burn(tokenId);
    }

    /**
     * @dev Generates the dynamic JSON metadata for an EvoMind NFT.
     * @param tokenId The ID of the EvoMind.
     * @return A Base64 encoded JSON string representing the NFT metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        EvoMindAttributes memory attrs = _evoMindAttributes[tokenId];

        string memory name = string(abi.encodePacked("EvoMind #", tokenId.toString(), " (Level ", attrs.level.toString(), ")"));
        string memory description = string(abi.encodePacked(
            "An evolving digital entity. Focus: ", attrs.focus.toString(),
            ", Creativity: ", attrs.creativity.toString(),
            ", Adaptability: ", attrs.adaptability.toString(),
            ", Resource Affinity: ", attrs.resourceAffinity.toString(),
            ". XP: ", attrs.xp.toString()
        ));

        // Generate a simple, abstract SVG based on attributes
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinyMin meet' viewBox='0 0 350 350'>",
            "<style>.base { fill: white; font-family: sans-serif; font-size: 14px; }</style>",
            "<rect width='100%' height='100%' fill='", _getColor(attrs.level, attrs.focus, attrs.creativity), "' />",
            "<circle cx='175' cy='175' r='", (100 + attrs.adaptability).toString(), "' fill='", _getInnerColor(attrs.resourceAffinity), "' />",
            "<text x='175' y='175' class='base' text-anchor='middle'>EvoMind #", tokenId.toString(), "</text>",
            "<text x='175' y='195' class='base' text-anchor='middle'>Level ", attrs.level.toString(), "</text>",
            "</svg>"
        ));

        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"', name,
                        '","description":"', description,
                        '","image":"', image,
                        '","attributes": [',
                            '{"trait_type": "Level", "value": ', attrs.level.toString(), '}',
                            ',{"trait_type": "XP", "value": ', attrs.xp.toString(), '}',
                            ',{"trait_type": "Focus", "value": ', attrs.focus.toString(), '}',
                            ',{"trait_type": "Creativity", "value": ', attrs.creativity.toString(), '}',
                            ',{"trait_type": "Adaptability", "value": ', attrs.adaptability.toString(), '}',
                            ',{"trait_type": "Resource Affinity", "value": ', attrs.resourceAffinity.toString(), '}',
                            ',{"trait_type": "Last Active", "value": ', attrs.lastActivityTimestamp.toString(), '}'
                        ']}'
                    )
                )
            )
        ));
    }

    /**
     * @dev Helper for tokenURI: gets background color based on level, focus, creativity.
     */
    function _getColor(uint256 level, int256 focus, int256 creativity) private pure returns (string memory) {
        // Simple color logic, can be expanded
        if (level >= 5) return "#FF00FF"; // Magenta for high level
        if (focus > 75 && creativity > 75) return "#00FFFF"; // Cyan for high focus/creativity
        if (focus > 60) return "#00FF00"; // Greenish for focus
        if (creativity > 60) return "#FFFF00"; // Yellowish for creativity
        return "#444444"; // Default dark grey
    }

    /**
     * @dev Helper for tokenURI: gets inner circle color based on resource affinity.
     */
    function _getInnerColor(int256 resourceAffinity) private pure returns (string memory) {
        if (resourceAffinity > 75) return "#FFD700"; // Gold for high resource affinity
        if (resourceAffinity > 50) return "#C0C0C0"; // Silver
        if (resourceAffinity > 25) return "#CD7F32"; // Bronze
        return "#AAAAAA"; // Default light grey
    }

    /**
     * @dev Retrieves all current attributes of a given EvoMind.
     * @param tokenId The ID of the EvoMind.
     * @return A struct containing all EvoMindAttributes.
     */
    function getEvoMindAttributes(uint256 tokenId) public view returns (EvoMindAttributes memory) {
        _requireOwned(tokenId);
        return _evoMindAttributes[tokenId];
    }

    /**
     * @dev Allows the contract owner to update the base URI for metadata.
     * Useful if metadata is hosted off-chain initially or for batch updates.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    // --- II. EvoMind Cognitive State & Attributes ---

    /**
     * @dev Internal function to add XP to an EvoMind.
     * @param tokenId The ID of the EvoMind.
     * @param amount The amount of XP to add.
     */
    function _accrueXP(uint256 tokenId, uint256 amount) internal {
        _evoMindAttributes[tokenId].xp += amount;
        emit EvoMindXPAccrued(tokenId, amount, _evoMindAttributes[tokenId].xp);
    }

    /**
     * @dev Public function allowing anyone to attempt to level up an EvoMind if it meets XP requirements.
     * Rewards the caller with a small amount of XP to encourage participation.
     * @param tokenId The ID of the EvoMind to attempt to level up.
     */
    function triggerLevelUp(uint256 tokenId) external {
        _requireOwned(tokenId); // Ensure EvoMind exists

        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];
        uint256 nextLevel = attrs.level + 1;
        uint256 requiredXP = _xpRequiredForLevel[nextLevel];

        if (requiredXP == 0) { // No XP requirement set for this level yet
            revert("EvoMindCore: No XP requirement set for next level");
        }

        require(attrs.xp >= requiredXP, "EvoMindCore: Not enough XP to level up");

        attrs.level = nextLevel;
        // Optionally reset XP or carry over remainder
        attrs.xp -= requiredXP;

        // Apply attribute bonuses on level up (example logic)
        attrs.focus = (attrs.focus + 5).min(100);
        attrs.creativity = (attrs.creativity + 5).min(100);
        attrs.adaptability = (attrs.adaptability + 5).min(100);

        // Reward the caller for triggering the level up
        _accrueXP(tokenId, 10); // Small XP reward for caller's EvoMind

        emit EvoMindLeveledUp(tokenId, nextLevel);
    }

    /**
     * @dev Triggers a mutation event for an EvoMind, altering its cognitive parameters.
     * The effect is randomized based on `mutationParam` (e.g., hash of external data, blockhash)
     * and the EvoMind's `adaptability` and `creativity`. Can be called by anyone.
     * @param tokenId The ID of the EvoMind to mutate.
     * @param mutationParam A bytes32 parameter influencing the mutation outcome (e.g., `blockhash(block.number - 1)`).
     */
    function mutateEvoMind(uint256 tokenId, bytes32 mutationParam) external {
        _requireOwned(tokenId);
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];

        // Combine mutationParam, current attributes, and block.timestamp for a unique seed
        uint256 seed = uint256(keccak256(abi.encodePacked(
            mutationParam,
            attrs.focus, attrs.creativity, attrs.adaptability,
            block.timestamp,
            attrs.mutationSeed // Incorporate prior mutation seed for continuity
        )));

        // Update the mutation seed for future mutations
        attrs.mutationSeed = seed;

        // Apply changes based on the seed and EvoMind's attributes
        // More adaptable/creative EvoMinds have different (potentially more beneficial) mutations
        int256 focusDelta = int256(seed % 21) - 10; // -10 to +10
        int256 creativityDelta = int256((seed >> 8) % 21) - 10;
        int256 adaptabilityDelta = int256((seed >> 16) % 21) - 10;

        // Scale deltas based on creativity and adaptability
        focusDelta = (focusDelta * (attrs.creativity + attrs.adaptability) / 100);
        creativityDelta = (creativityDelta * (attrs.creativity + attrs.focus) / 100);
        adaptabilityDelta = (adaptabilityDelta * (attrs.adaptability + attrs.focus) / 100);

        // Apply deltas, keeping parameters within a reasonable range (e.g., 0-100)
        attrs.focus = (attrs.focus + focusDelta).max(0).min(100);
        attrs.creativity = (attrs.creativity + creativityDelta).max(0).min(100);
        attrs.adaptability = (attrs.adaptability + adaptabilityDelta).max(0).min(100);

        _accrueXP(tokenId, 5); // Small XP for participating in mutation

        emit EvoMindMutated(tokenId, mutationParam);
        emit CognitiveParameterUpdated(tokenId, "Focus", focusDelta, attrs.focus);
        emit CognitiveParameterUpdated(tokenId, "Creativity", creativityDelta, attrs.creativity);
        emit CognitiveParameterUpdated(tokenId, "Adaptability", adaptabilityDelta, attrs.adaptability);
    }

    /**
     * @dev Allows the contract owner to adjust a specific cognitive parameter of an EvoMind.
     * This is useful for balancing, special events, or administrative adjustments.
     * @param tokenId The ID of the EvoMind.
     * @param paramName The name of the parameter ("focus", "creativity", "adaptability", "resourceAffinity").
     * @param delta The amount to change the parameter by (can be negative).
     */
    function updateCognitiveParameter(uint256 tokenId, string memory paramName, int256 delta) external onlyOwner {
        _requireOwned(tokenId); // Ensure EvoMind exists

        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];
        int256 oldValue;
        int256 newValue;

        if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("focus"))) {
            oldValue = attrs.focus;
            attrs.focus = (attrs.focus + delta).max(0).min(100);
            newValue = attrs.focus;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("creativity"))) {
            oldValue = attrs.creativity;
            attrs.creativity = (attrs.creativity + delta).max(0).min(100);
            newValue = attrs.creativity;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("adaptability"))) {
            oldValue = attrs.adaptability;
            attrs.adaptability = (attrs.adaptability + delta).max(0).min(100);
            newValue = attrs.adaptability;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("resourceAffinity"))) {
            oldValue = attrs.resourceAffinity;
            attrs.resourceAffinity = (attrs.resourceAffinity + delta).max(0).min(100);
            newValue = attrs.resourceAffinity;
        } else {
            revert("EvoMindCore: Invalid parameter name");
        }
        emit CognitiveParameterUpdated(tokenId, paramName, delta, newValue);
    }

    /**
     * @dev Returns the current values of an EvoMind's core cognitive parameters.
     * @param tokenId The ID of the EvoMind.
     * @return focus, creativity, adaptability, resourceAffinity
     */
    function getEvoMindCognitiveState(uint256 tokenId) public view returns (int256 focus, int256 creativity, int256 adaptability, int256 resourceAffinity) {
        _requireOwned(tokenId);
        EvoMindAttributes memory attrs = _evoMindAttributes[tokenId];
        return (attrs.focus, attrs.creativity, attrs.adaptability, attrs.resourceAffinity);
    }

    /**
     * @dev Queries the EvoMind's internal knowledge base for a specific key.
     * @param tokenId The ID of the EvoMind.
     * @param knowledgeKey The bytes32 hash representing the knowledge item.
     * @return The uint256 value associated with the knowledge key (0 if not found).
     */
    function queryEvoMindKnowledge(uint256 tokenId, bytes32 knowledgeKey) public view returns (uint256) {
        _requireOwned(tokenId);
        return _evoMindAttributes[tokenId].knowledgeBase[knowledgeKey];
    }

    // --- III. Resource Management & Empowerment ---

    /**
     * @dev Allows an owner to stake `powerToken` to their EvoMind, increasing its `resourceAffinity`.
     * The staked tokens are held by the contract.
     * @param tokenId The ID of the EvoMind to stake tokens to.
     * @param amount The amount of power tokens to stake.
     */
    function stakePowerTokens(uint256 tokenId, uint256 amount) external onlyEvoMindOwner(tokenId) {
        require(amount > 0, "EvoMindCore: Stake amount must be greater than 0");

        // Transfer tokens from staker to this contract
        powerToken.transferFrom(msg.sender, address(this), amount);

        _stakedPowerTokens[tokenId] += amount;

        // Increase resourceAffinity based on staked amount
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];
        int256 delta = int256(amount / 1e18); // Example scaling: 1e18 tokens = 1 point affinity
        attrs.resourceAffinity = (attrs.resourceAffinity + delta).min(100);

        emit PowerTokensStaked(tokenId, msg.sender, amount);
        emit CognitiveParameterUpdated(tokenId, "Resource Affinity", delta, attrs.resourceAffinity);
    }

    /**
     * @dev Allows an owner to unstake `powerToken` from their EvoMind.
     * @param tokenId The ID of the EvoMind to unstake tokens from.
     * @param amount The amount of power tokens to unstake.
     */
    function unstakePowerTokens(uint256 tokenId, uint256 amount) external onlyEvoMindOwner(tokenId) {
        require(amount > 0, "EvoMindCore: Unstake amount must be greater than 0");
        require(_stakedPowerTokens[tokenId] >= amount, "EvoMindCore: Not enough staked tokens");

        _stakedPowerTokens[tokenId] -= amount;
        powerToken.transfer(msg.sender, amount);

        // Decrease resourceAffinity based on unstaked amount
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];
        int256 delta = -int256(amount / 1e18); // Example scaling
        attrs.resourceAffinity = (attrs.resourceAffinity + delta).max(0);

        emit PowerTokensUnstaked(tokenId, msg.sender, amount);
        emit CognitiveParameterUpdated(tokenId, "Resource Affinity", delta, attrs.resourceAffinity);
    }

    /**
     * @dev Returns the amount of `powerToken` staked to a given EvoMind.
     * @param tokenId The ID of the EvoMind.
     * @return The amount of staked power tokens.
     */
    function getEvoMindStakedBalance(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _stakedPowerTokens[tokenId];
    }

    /**
     * @dev Allows the owner (or delegated recipient) to instruct their EvoMind to perform a delegated action on another contract.
     * The EvoMind's `adaptability` can influence the success of the delegated call, simulating a "chance of failure"
     * for less adaptable entities.
     * @param tokenId The ID of the EvoMind.
     * @param targetContract The address of the contract to call.
     * @param callData The encoded function call data.
     * @return success True if the call was successful, false otherwise.
     * @return result The raw return data from the call.
     */
    function delegateEvoMindAction(uint256 tokenId, address targetContract, bytes memory callData) external returns (bool success, bytes memory result) {
        // Can be called by owner OR the designated delegated recipient
        require(_isApprovedOrOwner(_msgSender(), tokenId) || _delegatedRecipients[tokenId] == _msgSender(),
                "EvoMindCore: Caller is not owner, approved, or delegated recipient");
        
        _requireOwned(tokenId); // Ensure EvoMind exists
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];

        // Simulate success probability based on adaptability
        uint256 successRoll = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, tokenId, callData))) % 100;
        bool simulatedSuccess = (successRoll < uint256(attrs.adaptability)); // Higher adaptability = higher chance of success

        if (!simulatedSuccess) {
            _accrueXP(tokenId, 2); // Small XP even on "simulated" failure for trying
            emit EvoMindActionDelegated(tokenId, targetContract, false);
            return (false, abi.encodePacked("Simulated failure due to low adaptability."));
        }

        // Execute the delegated call
        (success, result) = targetContract.call(callData);

        if (success) {
            _accrueXP(tokenId, 20); // More XP for successful delegation
        } else {
            _accrueXP(tokenId, 5); // Some XP even on actual failure
        }
        emit EvoMindActionDelegated(tokenId, targetContract, success);
    }

    /**
     * @dev Sets an approved recipient for delegated actions from the EvoMind.
     * This allows a specific address (e.g., a multi-sig, a DAO contract, or an automation bot)
     * to trigger `delegateEvoMindAction` without requiring the direct owner's signature for each call.
     * @param tokenId The ID of the EvoMind.
     * @param recipient The address to allow delegated actions. Set to address(0) to remove.
     */
    function setDelegatedRecipient(uint256 tokenId, address recipient) external onlyEvoMindOwner(tokenId) {
        _delegatedRecipients[tokenId] = recipient;
        emit DelegatedRecipientSet(tokenId, recipient);
    }

    // --- IV. Interaction & "Cognition" Simulation ---

    /**
     * @dev Simulates an external environmental event affecting an EvoMind's attributes.
     * The contract owner can use this to inject 'world' events.
     * @param tokenId The ID of the EvoMind.
     * @param eventHash A unique identifier for the event (e.g., hash of "market_crash").
     * @param eventValue A value associated with the event (e.g., severity, opportunity).
     */
    function processEnvironmentalEvent(uint256 tokenId, bytes32 eventHash, uint256 eventValue) external onlyOwner {
        _requireOwned(tokenId);
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];

        // Example logic:
        // A "positive" event (higher value) might increase creativity and adaptability
        // A "negative" event (lower value) might increase focus, but decrease creativity

        int256 deltaFocus = 0;
        int256 deltaCreativity = 0;
        int256 deltaAdaptability = 0;

        if (eventValue > 50) { // Positive event
            deltaCreativity = int256(eventValue / 10); // Scaled
            deltaAdaptability = int256(eventValue / 10);
            _accrueXP(tokenId, 15);
        } else { // Neutral/Negative event
            deltaFocus = int256(50 - eventValue); // Inverse scaling
            _accrueXP(tokenId, 5);
        }

        attrs.focus = (attrs.focus + deltaFocus).max(0).min(100);
        attrs.creativity = (attrs.creativity + deltaCreativity).max(0).min(100);
        attrs.adaptability = (attrs.adaptability + deltaAdaptability).max(0).min(100);

        emit EnvironmentalEventProcessed(tokenId, eventHash, eventValue);
        emit CognitiveParameterUpdated(tokenId, "Focus", deltaFocus, attrs.focus);
        emit CognitiveParameterUpdated(tokenId, "Creativity", deltaCreativity, attrs.creativity);
        emit CognitiveParameterUpdated(tokenId, "Adaptability", deltaAdaptability, attrs.adaptability);
    }

    /**
     * @dev Simulates an EvoMind's adaptive response based on its current cognitive state and a given context.
     * Returns a weighted "suggestion" or "action value" that represents its 'cognitive output'.
     * This function is purely for simulation/data and doesn't trigger on-chain actions.
     * @param tokenId The ID of the EvoMind.
     * @param contextHash A bytes32 hash representing the specific problem or scenario.
     * @return A uint256 representing the suggested action value, influenced by cognitive parameters.
     */
    function initiateAdaptiveResponse(uint256 tokenId, bytes32 contextHash) public view returns (uint256 suggestedActionValue) {
        _requireOwned(tokenId);
        EvoMindAttributes memory attrs = _evoMindAttributes[tokenId];

        // Combine context and EvoMind's attributes to simulate a unique response
        uint256 seed = uint256(keccak256(abi.encodePacked(contextHash, attrs.focus, attrs.creativity, attrs.adaptability, attrs.resourceAffinity)));

        // Example adaptive response logic:
        // Higher focus -> more precise/lower variance in response
        // Higher creativity -> wider range of potential responses
        // Higher adaptability -> better at handling novel contexts (higher base value)

        uint256 baseValue = (uint256(attrs.adaptability) * 100); // Max 10000
        uint256 creativityInfluence = (seed % (uint256(attrs.creativity) * 100)); // Range up to 100 * 100 = 10000
        uint256 focusInfluence = (seed % 100) / (uint256(attrs.focus).max(1)); // Smaller variance for high focus

        suggestedActionValue = baseValue + creativityInfluence - focusInfluence;
        return suggestedActionValue;
    }

    /**
     * @dev Records a successful strategy or piece of knowledge for an EvoMind.
     * This can influence its future `simulateDecisionMaking` or `initiateAdaptiveResponse`.
     * Can be called by the EvoMind owner, or by the contract itself upon successful challenges/delegations.
     * @param tokenId The ID of the EvoMind.
     * @param strategyHash A bytes32 hash representing the successful strategy or knowledge.
     * @param value A uint256 value associated with the strategy's success/importance.
     */
    function recordSuccessfulStrategy(uint256 tokenId, bytes32 strategyHash, uint256 value) external onlyEvoMindOwner(tokenId) {
        _requireOwned(tokenId);
        _evoMindAttributes[tokenId].knowledgeBase[strategyHash] = value;
        _accrueXP(tokenId, 10); // Reward for learning
        emit StrategyRecorded(tokenId, strategyHash, value);
    }

    /**
     * @dev A public function to "challenge" an EvoMind. Success depends on its attributes
     * (e.g., adaptability, focus) and the `challengeInput`. Successful challenges reward XP.
     * @param tokenId The ID of the EvoMind to challenge.
     * @param challengeInput A bytes32 input representing the challenge.
     * @return success True if the EvoMind successfully overcomes the challenge.
     */
    function challengeEvoMind(uint256 tokenId, bytes32 challengeInput) external returns (bool success) {
        _requireOwned(tokenId);
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];

        // Simple challenge logic:
        // Success depends on adaptability and a pseudo-random factor influenced by focus and challengeInput
        uint256 challengeDifficulty = uint256(challengeInput) % 100; // Represents difficulty 0-99

        uint256 successChance = uint256(attrs.adaptability) + (uint256(attrs.focus) / 2); // Combine attributes

        // Add a random element
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, challengeInput))) % 50;
        successChance += randomFactor;

        if (successChance >= challengeDifficulty) {
            _accrueXP(tokenId, 50); // Significant XP for success
            attrs.adaptability = (attrs.adaptability + 3).min(100); // Adaptability boost
            success = true;
        } else {
            _accrueXP(tokenId, 10); // Small XP even for failure
            attrs.focus = (attrs.focus + 1).min(100); // Small focus boost from learning from failure
            success = false;
        }

        emit EvoMindChallenged(tokenId, success);
        return success;
    }

    /**
     * @dev Allows EvoMind owners to claim any accrued rewards.
     * Rewards are simulated here based on `resourceAffinity` and activity,
     * and paid out from the contract's held power tokens.
     * @param tokenId The ID of the EvoMind.
     */
    function claimEvoMindRewards(uint256 tokenId) external onlyEvoMindOwner(tokenId) {
        EvoMindAttributes storage attrs = _evoMindAttributes[tokenId];
        uint256 timeSinceLastActivity = block.timestamp - attrs.lastActivityTimestamp;

        // Example reward calculation: Based on resource affinity and activity time
        // This is a simplified model; a real system might use complex yield farming mechanics
        uint256 rewardAmount = (uint256(attrs.resourceAffinity) * timeSinceLastActivity * 100) / (1e18); // Example: (affinity * seconds * constant) / scaling factor

        if (rewardAmount == 0) {
            revert("EvoMindCore: No rewards accrued yet or insufficient affinity");
        }
        
        // Ensure contract has enough tokens to pay out
        require(powerToken.balanceOf(address(this)) >= rewardAmount, "EvoMindCore: Insufficient contract balance for rewards");

        attrs.lastActivityTimestamp = block.timestamp; // Reset activity timestamp
        powerToken.transfer(msg.sender, rewardAmount);
        _accrueXP(tokenId, 30); // Reward XP for claiming

        emit EvoMindRewardsClaimed(tokenId, rewardAmount);
    }

    /**
     * @dev Provides a simulated decision outcome based on the EvoMind's attributes and an input bias.
     * This function is purely for simulation and returns a 'cognitive preference'.
     * @param tokenId The ID of the EvoMind.
     * @param decisionBias A uint256 input representing a bias towards one decision outcome or another.
     * @return The uint256 representing the simulated decision outcome.
     */
    function simulateDecisionMaking(uint256 tokenId, uint256 decisionBias) public view returns (uint256 decisionOutcome) {
        _requireOwned(tokenId);
        EvoMindAttributes memory attrs = _evoMindAttributes[tokenId];

        // Seed for decision randomness, influenced by attributes
        uint256 decisionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, decisionBias, attrs.focus, attrs.creativity, attrs.adaptability)));

        // Example: Decision outcome leans towards high/low based on bias, adjusted by EvoMind's creativity/focus
        uint256 rawOutcome = decisionSeed % 1000; // 0-999

        // Influence by creativity: wider range of possibilities
        rawOutcome = rawOutcome + (uint256(attrs.creativity) * 10);

        // Influence by focus: more precise/less erratic outcome
        if (attrs.focus > 0) {
            rawOutcome = rawOutcome / uint256(attrs.focus.max(1));
        }
        
        // Apply bias
        decisionOutcome = (rawOutcome + decisionBias) % 1000; // Keep in range 0-999 for example

        return decisionOutcome;
    }

    /**
     * @dev Returns a calculated "score" for a given abstract trait (e.g., 'Innovation', 'Resilience')
     * derived from the EvoMind's cognitive parameters. This allows for qualitative assessment.
     * @param tokenId The ID of the EvoMind.
     * @param traitName The name of the abstract trait to score (e.g., "Innovation", "Resilience", "Efficiency").
     * @return The calculated int256 score for the trait.
     */
    function getEvoMindTraitScore(uint256 tokenId, string memory traitName) public view returns (int256 score) {
        _requireOwned(tokenId);
        EvoMindAttributes memory attrs = _evoMindAttributes[tokenId];

        if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("Innovation"))) {
            // Innovation = Creativity * (1 + (Focus / 100))
            score = attrs.creativity + (attrs.creativity * attrs.focus / 100);
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("Resilience"))) {
            // Resilience = Adaptability * (1 + (Resource Affinity / 100))
            score = attrs.adaptability + (attrs.adaptability * attrs.resourceAffinity / 100);
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("Efficiency"))) {
            // Efficiency = Focus * (1 + (Resource Affinity / 100)) - (Creativity / 2)
            score = attrs.focus + (attrs.focus * attrs.resourceAffinity / 100) - (attrs.creativity / 2);
        } else {
            revert("EvoMindCore: Unknown trait name");
        }
        return score;
    }

    /**
     * @dev Updates the last activity timestamp for an EvoMind.
     * This can be used to prevent inactivity decay (if implemented) or enable time-based rewards.
     * @param tokenId The ID of the EvoMind.
     */
    function refreshActivityTimestamp(uint256 tokenId) external onlyEvoMindOwner(tokenId) {
        _evoMindAttributes[tokenId].lastActivityTimestamp = block.timestamp;
        _accrueXP(tokenId, 1); // Small XP for staying active
    }

    // --- V. Admin & Configuration ---

    /**
     * @dev Sets the XP required for a specific level. Only callable by the contract owner.
     * @param level The level for which to set the XP requirement.
     * @param xpRequired The amount of XP needed to reach this level.
     */
    function setXpForLevel(uint256 level, uint256 xpRequired) external onlyOwner {
        require(level > 0, "EvoMindCore: Level must be greater than 0");
        _xpRequiredForLevel[level] = xpRequired;
    }

    /**
     * @dev Grants or revokes permission for an address to mint EvoMinds.
     * @param minterAddress The address to set/unset minter status.
     * @param allowed True to allow, false to revoke.
     */
    function setMinter(address minterAddress, bool allowed) external onlyOwner {
        _minters[minterAddress] = allowed;
    }

    /**
     * @dev Allows the contract owner to withdraw any stuck ERC20 tokens from the contract.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "EvoMindCore: ERC20 transfer failed");
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Overrides _baseURI() to return the custom base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Ensures that the EvoMind exists before proceeding.
     */
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "EvoMindCore: ERC721 token does not exist");
    }
}
```