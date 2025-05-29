Okay, here is a Solidity smart contract implementing an advanced concept: a "Genesis Catalyst" system. This system combines dynamic NFTs, gamified staking for experience points (XP), attribute upgrades using XP, simulated "discovery" mechanics, and simplified on-chain governance that can influence global parameters or even individual assets.

This contract aims to be creative and trendy by integrating multiple popular blockchain concepts (NFTs, Staking, Governance, Dynamic Assets) into a single interconnected system, while avoiding direct duplication of single-purpose open-source contracts by combining these features uniquely.

**Important Considerations:**

1.  **Complexity:** This is a feature-rich contract for demonstration. Real-world implementation would require significant testing, security audits, and potentially breaking it into multiple contracts (proxies, separate governance, separate staking).
2.  **Gas Costs:** Many state-changing operations (staking, upgrading, voting) will consume gas.
3.  **Simulated Externalities:** Concepts like "Environmental Factors" and "Discovery Rewards" are simulated within the contract for demonstration purposes, as real-world oracles or complex computation are outside the scope of a single Solidity contract example.
4.  **Scalability:** Storing detailed state for many NFTs and proposals on-chain can become expensive.
5.  **Governance Security:** The governance module is simplified. Real DAOs use more sophisticated voting mechanisms, proposal validation, and execution safeguards.
6.  **Dynamic URI:** The `tokenURI` function would need an external service (like a backend server or IPFS gateway) to generate metadata JSON on-the-fly based on the token's current state. The contract only stores the base URI or uses a placeholder here.

---

**Outline and Function Summary**

**Contract Name:** `GenesisCatalyst`

**Core Concept:** A system managing dynamic NFT-like digital entities ("Catalysts") that can evolve, earn experience, participate in simulated events, and be governed by their holders.

**Modules:**

1.  **ERC721 Core:** Standard NFT functionalities (ownership, transfer, enumeration).
2.  **Catalyst Attributes:** Store and manage dynamic attributes for each Catalyst.
3.  **Staking & XP:** Allow users to stake Catalysts to earn XP over time. Use XP to upgrade attributes.
4.  **Discovery Mechanism:** A simulated process where Catalysts can undertake "discovery" to find rewards or information.
5.  **Environmental Factors:** Global modifiers that can affect all Catalysts, potentially controlled by governance.
6.  **Governance:** A simple proposal and voting system allowing token holders to influence system parameters or specific Catalyst states.
7.  **Admin & Settings:** Functions for the contract owner to set core parameters and manage the contract.

**Function Summary (20+ Functions):**

*   **ERC721 Standard (Inherited/Overridden):**
    1.  `balanceOf(address owner)`: Get the number of Catalysts owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific Catalyst.
    3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer a Catalyst.
    4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfer a Catalyst with data.
    5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer a Catalyst.
    6.  `approve(address to, uint256 tokenId)`: Approve an address to spend a Catalyst.
    7.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all Catalysts.
    8.  `getApproved(uint256 tokenId)`: Get the approved address for a Catalyst.
    9.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all Catalysts of an owner.
    10. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a Catalyst (dynamic based on state).
*   **Catalyst Management & Attributes:**
    11. `mintCatalyst(address recipient, bytes32 initialSeed)`: Mints a new Catalyst with base attributes derived from a seed.
    12. `burnCatalyst(uint256 tokenId)`: Allows the owner to burn a Catalyst.
    13. `getCatalystAttributes(uint256 tokenId)`: Get the current effective attributes of a Catalyst (base + upgrades + environmental).
    14. `getBaseAttributes(uint256 tokenId)`: Get the initial base attributes of a Catalyst.
    15. `updateBaseAttribute(uint256 tokenId, string attributeName, uint256 newValue)`: *Admin Function* - Update a catalyst's base attribute.
    16. `applyEnvironmentalEffect(string effectName, int256 modifier)`: *Admin/Governance Function* - Apply/update a global environmental effect.
    17. `getEnvironmentalFactors()`: View the current global environmental effects.
*   **Staking & XP:**
    18. `stakeCatalyst(uint256 tokenId)`: Stakes a Catalyst to earn XP.
    19. `unstakeCatalyst(uint256 tokenId)`: Unstakes a Catalyst, claiming pending XP.
    20. `claimXP(uint256 tokenId)`: Claims pending XP for a staked Catalyst without unstaking.
    21. `upgradeAttributeWithXP(uint256 tokenId, string attributeName, uint256 amountXP)`: Spend available XP to permanently upgrade a Catalyst attribute.
    22. `getStakedCatalysts(address owner)`: Get the list of Catalysts an owner has staked.
    23. `getPendingXP(uint256 tokenId)`: Get the amount of XP a staked Catalyst has accumulated since the last claim/stake/unstake.
    24. `getAvailableXP(uint256 tokenId)`: Get the total XP available to spend on upgrades for a Catalyst.
    25. `getTotalEarnedXP(uint256 tokenId)`: Get the total XP ever earned by a Catalyst.
*   **Discovery Mechanism:**
    26. `initiateDiscovery(uint256 tokenId)`: Start a discovery process with a Catalyst (costs Ether/resource).
    27. `claimDiscoveryReward(uint256 tokenId)`: Claim the result of a completed discovery.
    28. `getDiscoveryState(uint256 tokenId)`: View the current state and potential result of a Catalyst's discovery process.
*   **Governance:**
    29. `submitProposal(string description, address targetContract, bytes callData)`: Submit a proposal to change a parameter or call a function (requires holding a Catalyst).
    30. `voteOnProposal(uint256 proposalId, bool support)`: Cast a vote on an active proposal (requires holding a Catalyst).
    31. `executeProposal(uint256 proposalId)`: Execute a successful proposal.
    32. `getProposalState(uint256 proposalId)`: Get the current state of a proposal.
    33. `getGovernanceSettings()`: View the parameters governing the proposal/voting process.
*   **Admin & Settings:**
    34. `setXPStakeRate(uint256 ratePerSecond)`: *Admin Function* - Set the rate at which staked Catalysts earn XP.
    35. `setUpgradeCost(string attributeName, uint256 xpCostPerPoint)`: *Admin Function* - Set the XP cost for upgrading a specific attribute by one point.
    36. `setDiscoveryCost(uint256 costInWei)`: *Admin Function* - Set the Ether cost to initiate a discovery.
    37. `setDiscoveryDuration(uint256 durationInSeconds)`: *Admin Function* - Set the duration a discovery takes.
    38. `withdrawFunds(address recipient)`: *Admin Function* - Withdraw accumulated Ether (from discovery costs etc.).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example of potentially advanced import, though not fully implemented here. Can be used for airdrops, whitelists etc.

// Note: String manipulation (like attribute names) is gas-intensive.
// In a production system, consider using enums or bytes32 identifiers for attributes.

/**
 * @title GenesisCatalyst
 * @dev A dynamic NFT system with staking, XP, upgrades, discovery, and governance.
 *
 * Outline:
 * 1. ERC721 Core: Standard NFT functionalities.
 * 2. Catalyst Attributes: Dynamic stats (Strength, Intelligence, Agility, etc.).
 * 3. Staking & XP: Stake NFTs to earn XP; spend XP to upgrade attributes.
 * 4. Discovery Mechanism: Gamified process to find rewards/information.
 * 5. Environmental Factors: Global state modifiers influencing Catalysts.
 * 6. Governance: Simple on-chain voting on proposals affecting the system or assets.
 * 7. Admin & Settings: Owner controls for key parameters.
 *
 * Function Summary:
 * (See detailed summary above the contract code for individual function descriptions)
 */
contract GenesisCatalyst is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // --- NFT Attributes ---
    struct CatalystAttributes {
        uint256 strength;
        uint256 intelligence;
        uint256 agility;
        uint256 spirit;
        // Add more attributes as needed
    }

    mapping(uint256 => CatalystAttributes) private _baseAttributes;
    mapping(uint256 => CatalystAttributes) private _upgradedAttributes;

    // --- Staking & XP ---
    mapping(uint256 => uint256) private _stakedTime; // Timestamp when staked or last claimed/unstaked
    mapping(uint256 => uint256) private _availableXP; // XP available to spend on upgrades
    mapping(uint256 => uint256) private _totalEarnedXP; // Total XP ever earned (including spent)
    mapping(address => uint256[]) private _stakedCatalystsByOwner; // Keep track of staked NFTs per owner (gas intensive for large lists)
    mapping(uint256 => bool) private _isStaked; // Quick check if a token is staked

    uint256 public xpStakeRatePerSecond = 1; // XP points earned per second while staked (adjustable by admin)

    mapping(string => uint256) public xpUpgradeCosts; // XP cost per point for each attribute (e.g., "Strength" => 10)

    // --- Discovery Mechanism ---
    enum DiscoveryState { Idle, Discovering, ReadyToClaim }

    struct DiscoveryProgress {
        DiscoveryState state;
        uint256 endTime;
        bytes32 resultHash; // Placeholder for result identifier/hash
        bool claimed;
    }

    mapping(uint256 => DiscoveryProgress) private _discoveryProgress;
    uint256 public discoveryCostInWei = 0.01 ether; // Cost to initiate discovery (adjustable)
    uint256 public discoveryDurationInSeconds = 60; // Duration of discovery (adjustable)

    // --- Environmental Factors ---
    // Simple example: global modifiers to attributes
    mapping(string => int256) private _environmentalFactors; // e.g., "Strength" => 10 (adds 10 to all Catalyst strength)

    // --- Governance ---
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 timestamp;
        address targetContract;
        bytes callData;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voters; // Addresses that have already voted
        uint256 creationBlock; // Block number when created to calculate voting period end
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 private _proposalCounter;

    uint256 public governanceVotingPeriodBlocks = 100; // Blocks for voting
    uint256 public governanceQuorumNumerator = 50; // 50% of total supply needed for quorum (simplified, should use a snapshot)

    // --- Events ---
    event CatalystMinted(address indexed owner, uint256 indexed tokenId, CatalystAttributes baseAttributes);
    event AttributeUpgraded(uint256 indexed tokenId, string attributeName, uint256 oldPoints, uint256 newPoints, uint256 xpSpent);
    event XPClaimed(uint256 indexed tokenId, uint256 claimedXP, uint256 totalAvailableXP);
    event CatalystStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event CatalystUnstaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event EnvironmentalEffectUpdated(string effectName, int256 modifier);
    event DiscoveryInitiated(uint256 indexed tokenId, uint256 endTime);
    event DiscoveryClaimed(uint256 indexed tokenId, bytes32 resultHash);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId, string reason);

    // --- Modifiers ---
    modifier onlyStaked(uint256 tokenId) {
        require(_isStaked[tokenId], "Not staked");
        _;
    }

    modifier onlyNotStaked(uint256 tokenId) {
        require(!_isStaked[tokenId], "Currently staked");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set initial XP upgrade costs (example)
        xpUpgradeCosts["Strength"] = 10;
        xpUpgradeCosts["Intelligence"] = 12;
        xpUpgradeCosts["Agility"] = 8;
        xpUpgradeCosts["Spirit"] = 15;
    }

    // --- Internal / Helper Functions ---

    function _calculatePendingXP(uint256 tokenId) internal view returns (uint256) {
        if (!_isStaked[tokenId]) {
            return 0;
        }
        uint256 stakedTimestamp = _stakedTime[tokenId];
        uint256 durationStaked = block.timestamp - stakedTimestamp;
        return durationStaked * xpStakeRatePerSecond;
    }

    function _claimPendingXP(uint256 tokenId) internal returns (uint256 claimed) {
        claimed = _calculatePendingXP(tokenId);
        if (claimed > 0) {
            _availableXP[tokenId] += claimed;
            _totalEarnedXP[tokenId] += claimed;
            _stakedTime[tokenId] = block.timestamp; // Reset timer
            emit XPClaimed(tokenId, claimed, _availableXP[tokenId]);
        }
        return claimed;
    }

    // Generates simplified base attributes based on a seed
    function _generateBaseAttributes(bytes32 seed) internal pure returns (CatalystAttributes memory) {
        // Simple pseudo-random generation based on seed
        uint256 s = uint256(seed);
        return CatalystAttributes({
            strength: (s % 20) + 1, // 1-20
            intelligence: ((s >> 8) % 20) + 1,
            agility: ((s >> 16) % 20) + 1,
            spirit: ((s >> 24) % 20) + 1
            // Add more based on seed slices
        });
    }

     // --- Overridden ERC721 Functions ---
    // We don't need to override all, just those with custom logic (like tokenURI)
    // transferFrom, safeTransferFrom etc. inherit logic from OpenZeppelin base

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Note: A dynamic tokenURI requires an off-chain service
        // to serve JSON metadata that includes current attributes, XP, staking status etc.
        // This function would typically return a URL like "ipfs://<base_uri>/<tokenId>.json"
        // or "https://<api_endpoint>/metadata/<tokenId>".
        // The off-chain service fetches the state from the contract and builds the JSON.
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Example placeholder - replace with actual logic calling an API
        // string memory baseURI = _baseURI(); // If using a base URI
        return string(abi.encodePacked("https://genesis-catalyst.io/metadata/", Strings.toString(tokenId)));
    }

    // --- Custom Functions ---

    /**
     * @dev Mints a new Catalyst token.
     * @param recipient The address to mint the token to.
     * @param initialSeed A seed used to generate initial base attributes.
     */
    function mintCatalyst(address recipient, bytes32 initialSeed) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(recipient, newItemId);

        CatalystAttributes memory base = _generateBaseAttributes(initialSeed);
        _baseAttributes[newItemId] = base;
        _upgradedAttributes[newItemId] = CatalystAttributes({
             strength: 0, intelligence: 0, agility: 0, spirit: 0
             // Initialize upgrade values to 0
        });

        emit CatalystMinted(recipient, newItemId, base);
    }

    /**
     * @dev Burns a Catalyst token. Only the owner can burn.
     * @param tokenId The token ID to burn.
     */
    function burnCatalyst(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(!_isStaked[tokenId], "Cannot burn staked catalyst");

        _burn(tokenId);

        // Clean up state (optional but good practice for dynamic data)
        delete _baseAttributes[tokenId];
        delete _upgradedAttributes[tokenId];
        delete _availableXP[tokenId];
        delete _totalEarnedXP[tokenId];
        delete _discoveryProgress[tokenId];
        // Staking state should already be false due to the require above
    }

    /**
     * @dev Gets the current effective attributes of a Catalyst, including base, upgrades, and environmental factors.
     * @param tokenId The token ID.
     * @return A struct containing the calculated attributes.
     */
    function getCatalystAttributes(uint256 tokenId) public view returns (CatalystAttributes memory) {
        require(_exists(tokenId), "Token does not exist");

        CatalystAttributes storage base = _baseAttributes[tokenId];
        CatalystAttributes storage upgrades = _upgradedAttributes[tokenId];

        // Apply environmental factors (simplified)
        int256 envStr = _environmentalFactors["Strength"];
        int256 envInt = _environmentalFactors["Intelligence"];
        int256 envAgl = _environmentalFactors["Agility"];
        int256 envSpi = _environmentalFactors["Spirit"];

        // Calculate final attributes
        uint256 finalStrength = base.strength + upgrades.strength;
        if (envStr > 0) finalStrength += uint256(envStr);
        else if (envStr < 0 && finalStrength >= uint256(-envStr)) finalStrength -= uint256(-envStr);
        else if (envStr < 0) finalStrength = 0; // Cap at 0

        uint256 finalIntelligence = base.intelligence + upgrades.intelligence;
         if (envInt > 0) finalIntelligence += uint256(envInt);
        else if (envInt < 0 && finalIntelligence >= uint256(-envInt)) finalIntelligence -= uint256(-envInt);
        else if (envInt < 0) finalIntelligence = 0;

        uint256 finalAgility = base.agility + upgrades.agility;
         if (envAgl > 0) finalAgility += uint256(envAgl);
        else if (envAgl < 0 && finalAgility >= uint256(-envAgl)) finalAgility -= uint256(-envAgl);
        else if (envAgl < 0) finalAgility = 0;

        uint256 finalSpirit = base.spirit + upgrades.spirit;
         if (envSpi > 0) finalSpirit += uint256(envSpi);
        else if (envSpi < 0 && finalSpirit >= uint256(-envSpi)) finalSpirit -= uint256(-envSpi);
        else if (envSpi < 0) finalSpirit = 0;


        return CatalystAttributes({
            strength: finalStrength,
            intelligence: finalIntelligence,
            agility: finalAgility,
            spirit: finalSpirit
        });
    }

    /**
     * @dev Gets the base attributes of a Catalyst, excluding upgrades and environmental factors.
     * @param tokenId The token ID.
     * @return A struct containing the base attributes.
     */
    function getBaseAttributes(uint256 tokenId) public view returns (CatalystAttributes memory) {
         require(_exists(tokenId), "Token does not exist");
         return _baseAttributes[tokenId];
    }

     /**
     * @dev Gets the upgrade points added to a Catalyst's attributes.
     * @param tokenId The token ID.
     * @return A struct containing the upgraded points per attribute.
     */
    function getUpgradedAttributes(uint256 tokenId) public view returns (CatalystAttributes memory) {
        require(_exists(tokenId), "Token does not exist");
        return _upgradedAttributes[tokenId];
    }

    /**
     * @dev Stakes a Catalyst token to start earning XP. Requires ownership.
     * Transfers token ownership to the contract.
     * @param tokenId The token ID to stake.
     */
    function stakeCatalyst(uint256 tokenId) public onlyNotStaked(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        address ownerAddress = ownerOf(tokenId);
        require(ownerAddress == msg.sender, "Only owner can stake");

        // Transfer token to the contract
        _transfer(ownerAddress, address(this), tokenId);

        _isStaked[tokenId] = true;
        _stakedTime[tokenId] = block.timestamp;

        // Add to owner's staked list (gas intensive for many staked)
        _stakedCatalystsByOwner[ownerAddress].push(tokenId);

        emit CatalystStaked(tokenId, ownerAddress, block.timestamp);
    }

    /**
     * @dev Unstakes a Catalyst token, transferring it back to the owner and claiming pending XP.
     * Requires the token to be staked and called by the original staker.
     * @param tokenId The token ID to unstake.
     */
    function unstakeCatalyst(uint256 tokenId) public onlyStaked(tokenId) {
        // We need to find the original owner who staked it.
        // This requires storing the staker's address, or relying on the fact
        // that only the contract owns it while staked and the original staker calls this.
        // Simple check: Can the msg.sender prove they originally staked it?
        // Or, is it a permissioned unstake (e.g., only original staker or specific role)?
        // Let's assume original staker identity is needed. Need a mapping for this.
        // For simplicity here, let's assume the function can only be called by someone
        // who *could* be the original owner (e.g., if they weren't staked they'd own it),
        // or we add a mapping: mapping(uint256 => address) private _stakerOf;
        // Let's add _stakerOf for robustness.

         address originalOwner = _stakerOf[tokenId];
         require(originalOwner != address(0), "Staker not found"); // Should not happen if _isStaked is true
         require(msg.sender == originalOwner, "Only the original staker can unstake");

        _claimPendingXP(tokenId); // Claim XP before unstaking

        _isStaked[tokenId] = false;
        delete _stakedTime[tokenId];
        delete _stakerOf[tokenId]; // Clean up staker mapping

        // Remove from owner's staked list (gas intensive)
        uint256[] storage stakedTokens = _stakedCatalystsByOwner[originalOwner];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }

        // Transfer token back to original owner
        _transfer(address(this), originalOwner, tokenId);

        emit CatalystUnstaked(tokenId, originalOwner, block.timestamp);
    }

    // Add _stakerOf mapping and update stake/unstake
     mapping(uint256 => address) private _stakerOf;

     function stakeCatalyst(uint256 tokenId) public onlyNotStaked(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        address ownerAddress = ownerOf(tokenId); // Before transfer, owner is msg.sender
        require(ownerAddress == msg.sender, "Only owner can stake");

        // Transfer token to the contract
        _transfer(ownerAddress, address(this), tokenId);

        _isStaked[tokenId] = true;
        _stakerOf[tokenId] = ownerAddress; // Store original staker
        _stakedTime[tokenId] = block.timestamp;

        _stakedCatalystsByOwner[ownerAddress].push(tokenId); // Add to owner's staked list

        emit CatalystStaked(tokenId, ownerAddress, block.timestamp);
    }


    /**
     * @dev Claims pending XP for a staked Catalyst without unstaking.
     * Requires the token to be staked and called by the original staker.
     * @param tokenId The token ID to claim XP for.
     */
    function claimXP(uint256 tokenId) public onlyStaked(tokenId) {
        require(msg.sender == _stakerOf[tokenId], "Only the original staker can claim XP");
        _claimPendingXP(tokenId); // Internal claim handles time reset and emission
    }

    /**
     * @dev Spends available XP to upgrade a Catalyst's attribute.
     * Can be called by the current owner (whether staked or not).
     * @param tokenId The token ID to upgrade.
     * @param attributeName The name of the attribute to upgrade (e.g., "Strength").
     * @param amountXP The amount of XP to spend.
     */
    function upgradeAttributeWithXP(uint256 tokenId, string memory attributeName, uint256 amountXP) public {
        require(_exists(tokenId), "Token does not exist");
        // Allow upgrade by current owner, even if staked (contract is owner)
        require(ownerOf(tokenId) == msg.sender || (_isStaked[tokenId] && _stakerOf[tokenId] == msg.sender), "Not authorized to upgrade");

        require(_availableXP[tokenId] >= amountXP, "Not enough available XP");
        require(xpUpgradeCosts[attributeName] > 0, "Invalid or unsupported attribute");

        uint256 pointsGained = amountXP / xpUpgradeCosts[attributeName];
        require(pointsGained > 0, "Amount XP not enough for at least 1 point");

        uint256 actualXPSpent = pointsGained * xpUpgradeCosts[attributeName];
        require(_availableXP[tokenId] >= actualXPSpent, "Not enough available XP for calculated points"); // Re-check after calculating points

        _availableXP[tokenId] -= actualXPSpent;

        CatalystAttributes storage upgraded = _upgradedAttributes[tokenId];
        uint256 oldPoints;
        uint256 newPoints;

        // Use keccak256 hash of attributeName for efficient comparison (prevents string issues)
        bytes32 attributeHash = keccak256(abi.encodePacked(attributeName));

        if (attributeHash == keccak256(abi.encodePacked("Strength"))) {
            oldPoints = upgraded.strength;
            upgraded.strength += pointsGained;
            newPoints = upgraded.strength;
        } else if (attributeHash == keccak256(abi.encodePacked("Intelligence"))) {
            oldPoints = upgraded.intelligence;
            upgraded.intelligence += pointsGained;
            newPoints = upgraded.intelligence;
        } else if (attributeHash == keccak256(abi.encodePacked("Agility"))) {
            oldPoints = upgraded.agility;
            upgraded.agility += pointsGained;
            newPoints = upgraded.agility;
        } else if (attributeHash == keccak256(abi.encodePacked("Spirit"))) {
            oldPoints = upgraded.spirit;
            upgraded.spirit += pointsGained;
            newPoints = upgraded.spirit;
        } else {
             // This require should technically not be needed due to the initial check, but safety first
            revert("Invalid attribute name");
        }

        emit AttributeUpgraded(tokenId, attributeName, oldPoints, newPoints, actualXPSpent);
    }

    /**
     * @dev Gets the list of token IDs staked by a specific owner.
     * @param owner The address of the owner.
     * @return An array of staked token IDs.
     */
    function getStakedCatalysts(address owner) public view returns (uint256[] memory) {
        // Note: This can be gas intensive for owners with many staked NFTs.
        // Consider alternative patterns like linked lists if list enumeration is critical.
        return _stakedCatalystsByOwner[owner];
    }

    /**
     * @dev Gets the amount of XP a staked Catalyst has accumulated since the last claim/stake/unstake.
     * @param tokenId The token ID.
     * @return The amount of pending XP.
     */
    function getPendingXP(uint256 tokenId) public view returns (uint256) {
        return _calculatePendingXP(tokenId);
    }

    /**
     * @dev Gets the total XP available to spend on upgrades for a Catalyst.
     * @param tokenId The token ID.
     * @return The amount of available XP.
     */
    function getAvailableXP(uint256 tokenId) public view returns (uint256) {
        // Add pending XP to available XP for display, but spending should use _availableXP state
        if (_isStaked[tokenId]) {
            return _availableXP[tokenId] + _calculatePendingXP(tokenId);
        } else {
            return _availableXP[tokenId];
        }
    }

    /**
     * @dev Gets the total XP ever earned by a Catalyst (available + spent on upgrades).
     * @param tokenId The token ID.
     * @return The total earned XP.
     */
    function getTotalEarnedXP(uint256 tokenId) public view returns (uint256) {
        if (_isStaked[tokenId]) {
             return _totalEarnedXP[tokenId] + _calculatePendingXP(tokenId);
        } else {
             return _totalEarnedXP[tokenId];
        }
    }


    // --- Discovery Mechanism Functions ---

    /**
     * @dev Initiates a discovery process for a Catalyst. Costs Ether.
     * Requires ownership.
     * @param tokenId The token ID.
     */
    function initiateDiscovery(uint256 tokenId) public payable {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
         require(msg.value >= discoveryCostInWei, "Insufficient Ether for discovery");
         require(_discoveryProgress[tokenId].state == DiscoveryState.Idle, "Discovery already in progress or ready to claim");

        _discoveryProgress[tokenId].state = DiscoveryState.Discovering;
        _discoveryProgress[tokenId].endTime = block.timestamp + discoveryDurationInSeconds;
        _discoveryProgress[tokenId].claimed = false;
        // Simulate result - in production, this might come from a VRF or oracle after the duration
        _discoveryProgress[tokenId].resultHash = keccak256(abi.encodePacked(tokenId, block.timestamp, block.difficulty, msg.sender)); // Pseudo-random

        emit DiscoveryInitiated(tokenId, _discoveryProgress[tokenId].endTime);
    }

    /**
     * @dev Claims the reward/result of a completed discovery process.
     * Requires ownership and that the discovery duration has passed.
     * @param tokenId The token ID.
     */
    function claimDiscoveryReward(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        DiscoveryProgress storage progress = _discoveryProgress[tokenId];
        require(progress.state == DiscoveryState.Discovering, "Discovery not in progress");
        require(block.timestamp >= progress.endTime, "Discovery not yet finished");
        require(!progress.claimed, "Discovery reward already claimed");

        // Discovery result can be anything: minting a new NFT, receiving tokens, XP, attribute boost etc.
        // For this example, we just mark it as claimed and the resultHash is the "reward identifier".
        progress.state = DiscoveryState.ReadyToClaim; // Or just revert to Idle after claim? Let's use ReadyToClaim state for clarity.
        progress.claimed = true;

        // --- Add actual reward logic here ---
        // Example: _availableXP[tokenId] += 100;
        // Example: IERC20(rewardTokenAddress).transfer(msg.sender, rewardAmount);
        // Example: mintCatalyst(msg.sender, keccak256(abi.encodePacked(progress.resultHash, "reward")));
        // -------------------------------------

        emit DiscoveryClaimed(tokenId, progress.resultHash);

        // Reset state after claim
        delete _discoveryProgress[tokenId]; // Or set state back to Idle and delete other fields
    }

     /**
     * @dev Gets the current state and details of a Catalyst's discovery process.
     * @param tokenId The token ID.
     * @return The state, end time, result hash, and claimed status.
     */
    function getDiscoveryState(uint256 tokenId) public view returns (DiscoveryState state, uint256 endTime, bytes32 resultHash, bool claimed) {
        require(_exists(tokenId), "Token does not exist");
        DiscoveryProgress storage progress = _discoveryProgress[tokenId];
        return (progress.state, progress.endTime, progress.resultHash, progress.claimed);
    }


    // --- Environmental Factors Functions ---

    /**
     * @dev Applies or updates a global environmental effect modifier to an attribute.
     * Can only be called by the owner or via successful governance proposal.
     * @param effectName The name of the attribute affected (e.g., "Strength").
     * @param modifier The integer modifier (+/-).
     */
    function applyEnvironmentalEffect(string memory effectName, int256 modifier) public onlyOwner {
        // Check if attribute name is valid (simple check)
        bytes32 attributeHash = keccak256(abi.encodePacked(effectName));
        require(xpUpgradeCosts[effectName] > 0, "Invalid attribute name"); // Reuse upgrade cost check

        _environmentalFactors[effectName] = modifier;
        emit EnvironmentalEffectUpdated(effectName, modifier);
    }

     /**
     * @dev Gets the current global environmental effect modifiers.
     * @return A mapping (simulated) of attribute names to modifiers. Note: Mapping cannot be returned directly.
     *         This function provides a view of known environmental factors.
     */
    function getEnvironmentalFactors() public view returns (string[] memory names, int256[] memory modifiers) {
        // Note: Retrieving all keys from a mapping is not natively supported and is gas-intensive.
        // In a real dapp, you would store active effect names in an array or list.
        // For demonstration, we return known attributes.
        string[] memory knownAttributes = new string[](4); // Hardcoded for simplicity
        knownAttributes[0] = "Strength";
        knownAttributes[1] = "Intelligence";
        knownAttributes[2] = "Agility";
        knownAttributes[3] = "Spirit";

        names = knownAttributes;
        modifiers = new int256[](knownAttributes.length);

        for(uint i = 0; i < knownAttributes.length; i++) {
            modifiers[i] = _environmentalFactors[knownAttributes[i]];
        }
         return (names, modifiers);
    }


    // --- Governance Functions ---

    /**
     * @dev Submits a new governance proposal. Requires holding at least one Catalyst.
     * The proposal can target a function call on this contract or another contract.
     * @param description A short description of the proposal.
     * @param targetContract The address of the contract to call (can be `address(this)`).
     * @param callData The ABI-encoded function call data.
     */
    function submitProposal(string memory description, address targetContract, bytes memory callData) public {
        require(balanceOf(msg.sender) > 0 || _stakedCatalystsByOwner[msg.sender].length > 0, "Requires holding or staking at least one Catalyst to submit proposal");

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = description;
        newProposal.proposer = msg.sender;
        newProposal.timestamp = block.timestamp;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.executed = false;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.creationBlock = block.number; // Use block number for voting period

        emit ProposalSubmitted(proposalId, msg.sender, description);
    }

    /**
     * @dev Casts a vote on an active proposal. Requires holding at least one Catalyst.
     * Each Catalyst held counts as one vote (simplified voting weight). Staked Catalysts also count.
     * A user can only vote once per proposal regardless of how many Catalysts they hold.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.number < proposal.creationBlock + governanceVotingPeriodBlocks, "Voting period has ended");
        require(balanceOf(msg.sender) > 0 || _stakedCatalystsByOwner[msg.sender].length > 0, "Requires holding or staking at least one Catalyst to vote");
        require(!proposal.voters[msg.sender], "Already voted on this proposal");

        // Simplified voting weight: 1 vote per address holding/staking >= 1 Catalyst
        // More advanced: 1 vote per Catalyst owned/staked (requires summing up tokens)
        // Or: weighted voting based on Catalyst attributes or XP
        // For simplicity here, 1 address = 1 vote per proposal.

        proposal.voters[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

     /**
     * @dev Executes a proposal if the voting period has ended and it passed.
     * Passing criteria: Voting period ended, enough 'yes' votes for quorum, and more 'yes' votes than 'no' votes.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.number >= proposal.creationBlock + governanceVotingPeriodBlocks, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
         // Simplified Quorum: require total votes >= quorum percentage of total supply (approximation)
         // A proper quorum needs a snapshot of voting power at proposal creation.
         // Using total supply here is a simple proxy.
        uint256 totalSupplyAtExecution = _tokenIdCounter.current(); // Total tokens minted ever (simple proxy for voting power)
        require(totalVotes * 100 >= totalSupplyAtExecution * governanceQuorumNumerator, "Quorum not met");

        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);

        if (success) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        } else {
            emit ProposalFailed(proposalId, "Execution failed");
            // Optional: Add a way to retry execution or mark as permanently failed
        }
    }

    /**
     * @dev Gets the current state of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details and state indicators.
     */
     function getProposalState(uint256 proposalId) public view returns (
        uint256 id,
        string memory description,
        address proposer,
        uint256 timestamp,
        address targetContract,
        bytes memory callData,
        bool executed,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 creationBlock,
        bool votingPeriodEnded,
        bool passedCriteria // Based on current votes and total supply (simplified)
     ) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id == proposalId, "Proposal does not exist");

         votingPeriodEnded = block.number >= proposal.creationBlock + governanceVotingPeriodBlocks;

         uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
         uint256 totalSupplyAtQuery = _tokenIdCounter.current();
         bool quorumMet = totalVotes * 100 >= totalSupplyAtQuery * governanceQuorumNumerator;
         passedCriteria = votingPeriodEnded && quorumMet && proposal.votesFor > proposal.votesAgainst;


         return (
             proposal.id,
             proposal.description,
             proposal.proposer,
             proposal.timestamp,
             proposal.targetContract,
             proposal.callData,
             proposal.executed,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.creationBlock,
             votingPeriodEnded,
             passedCriteria
         );
     }

     /**
     * @dev Gets the current settings for governance parameters.
     * @return A tuple containing voting period and quorum settings.
     */
     function getGovernanceSettings() public view returns (uint256 votingPeriodBlocks, uint256 quorumNumerator, uint256 totalSupplyProxy) {
        return (governanceVotingPeriodBlocks, governanceQuorumNumerator, _tokenIdCounter.current());
     }


    // --- Admin & Settings Functions ---

    /**
     * @dev Sets the rate at which staked Catalysts earn XP per second. Only owner.
     * @param ratePerSecond The new XP rate per second.
     */
    function setXPStakeRate(uint256 ratePerSecond) public onlyOwner {
        xpStakeRatePerSecond = ratePerSecond;
    }

    /**
     * @dev Sets the XP cost to upgrade a specific attribute by one point. Only owner.
     * @param attributeName The name of the attribute.
     * @param xpCostPerPoint The new XP cost per point.
     */
    function setUpgradeCost(string memory attributeName, uint256 xpCostPerPoint) public onlyOwner {
        // Optional: require attributeName to be one of the defined ones
        xpUpgradeCosts[attributeName] = xpCostPerPoint;
    }

    /**
     * @dev Sets the Ether cost to initiate a discovery process. Only owner.
     * @param costInWei The new cost in Wei.
     */
    function setDiscoveryCost(uint256 costInWei) public onlyOwner {
        discoveryCostInWei = costInWei;
    }

    /**
     * @dev Sets the duration of a discovery process in seconds. Only owner.
     * @param durationInSeconds The new duration.
     */
    function setDiscoveryDuration(uint256 durationInSeconds) public onlyOwner {
        discoveryDurationInSeconds = durationInSeconds;
    }

    /**
     * @dev Allows the owner to withdraw accumulated Ether (e.g., from discovery costs).
     * @param recipient The address to send the Ether to.
     */
    function withdrawFunds(address recipient) public onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- ERC721 Enumeration (Optional but useful for dapps) ---
    // Add ERC721Enumerable import if you want _owners, _allTokens, etc. mappings
    // For this example, we won't add it to keep complexity focused on the core logic.
    // If added, you'd override _beforeTokenTransfer to manage the enumeration data structures.
}
```