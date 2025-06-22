Okay, let's design an interesting, advanced, and non-standard smart contract.

**Concept:** A "Chronicle Shard" - a non-transferable (Soulbound-like) or conditionally-transferable NFT that represents a user's reputation, activity history, and progressive standing within a specific protocol or ecosystem. It gains "Experience Points" (XP) and "Attunements" through verifiable on-chain/off-chain activities, which in turn unlock "Levels" and grant dynamic benefits like weighted voting power, access to gated features, or eligibility for rewards. The Shard state can also decay over time if inactive, encouraging participation.

**Advanced Concepts Involved:**
1.  **Dynamic State NFTs:** NFT metadata and utility change based on interaction and time.
2.  **Reputation/Progressive System:** Tracking user engagement and achievements on-chain.
3.  **Attestation/Oracle Integration:** Relying on a trusted source (or a decentralized network of sources) to verify off-chain or complex on-chain events.
4.  **Permissioned Functions:** Gating access to certain smart contract functions based on the NFT's state (level, attunement).
5.  **Decay Mechanism:** Introducing time-based degradation of state to incentivize continuous engagement.
6.  **Conditional Transferability:** Making the NFT primarily bound to the owner but allowing transformation or 'forging' into a transferable asset under specific high-achievement conditions.
7.  **Programmable Benefits:** Tying in-protocol benefits directly to the NFT's attributes.

---

## Contract Outline: `ChronicleShard`

This contract implements a dynamic, reputation-based NFT system. It extends ERC-721 but adds significant custom logic for state management, progression, decay, attestation, and utility.

1.  **Interfaces & Imports:** ERC721, Ownable, potentially ERC721URIStorage, Counters.
2.  **Structs:**
    *   `ShardState`: Holds the dynamic attributes of a single shard (level, xp, attunements, last activity time, status).
    *   `Challenge`: Defines a challenge that grants XP/Attunement.
3.  **State Variables:** Mappings for shard states, XP thresholds per level, decay rates, attunement types, oracle address, challenge definitions, completed challenges, system pause flags, benefit configurations.
4.  **Events:** To signal key state changes (mint, burn, xp gain, level up, decay, attunement, challenge completion, configuration updates, pausing).
5.  **Modifiers:** `onlyOracle`, `whenNotPaused`, `onlyShardOwner`, `requiresShardState`.
6.  **Constructor:** Sets up initial state, oracle address, owner.
7.  **ERC721 Overrides:** Mostly using OpenZeppelin implementations, but override `_beforeTokenTransfer` to enforce non-transferability logic, handle `forgeArtifact`.
8.  **Core State Management Functions:**
    *   Getters (`getShardState`, `getLevel`, `getXP`, etc.)
    *   Internal helpers (`_applyDecayInternal`, `_calculateDecay`, `_addXP`, `_addAttunement`)
9.  **Progression & Earning Functions:**
    *   `attestActivity`: Called by Oracle to grant state based on external events.
    *   `completeChallenge`: Called by user to claim reward for a predefined challenge.
    *   `grantBlessing`: Called by Owner for direct grants.
    *   `levelUp`: Called by user to advance level if sufficient XP.
    *   `attuneShard`: Called by user to set/change primary attunement.
10. **Decay Functions:**
    *   `applyDecay`: Callable by anyone (or keeper) to apply decay based on time.
    *   `checkPendingDecay`: Calculate potential decay amount.
11. **Utility & Gated Functions:**
    *   `getVotingPower`: Calculates dynamic voting power.
    *   `isAccessGranted`: Checks if a shard meets criteria for gated access.
    *   `claimBenefits`: Placeholder for claiming dynamic rewards/benefits.
    *   `forgeArtifact`: Burns Shard to mint a transferable asset (e.g., ERC1155 legacy token).
12. **Configuration Functions (Owner Only):**
    *   Set XP thresholds, decay rate, oracle address.
    *   Add/Remove attunement types.
    *   Define/Update challenges.
    *   Configure level benefits.
13. **Management Functions (Owner Only):**
    *   `mintShard`: Issue new shards.
    *   `burnShard`: Remove shards.
    *   Pause/Unpause mechanisms.

---

## Function Summary:

This section lists the key functions and their purpose.

*   **View Functions (Read-only):**
    1.  `getShardState(uint256 tokenId)`: Retrieves all dynamic state parameters for a shard.
    2.  `getLevel(uint256 tokenId)`: Gets the current level of a shard.
    3.  `getXP(uint256 tokenId)`: Gets the current XP of a shard.
    4.  `getAttunement(uint256 tokenId, string memory attunementType)`: Gets the attunement level for a specific type.
    5.  `getStatus(uint256 tokenId)`: Gets the current status (e.g., Active, Dormant).
    6.  `getLastActivityTime(uint256 tokenId)`: Gets the timestamp of the last state-changing activity.
    7.  `getXPThresholds()`: Returns the mapping of levels to required XP.
    8.  `getDecayRate()`: Returns the current decay rate per second.
    9.  `getOracleAddress()`: Returns the address authorized as the oracle.
    10. `getAttunementTypes()`: Returns a list of registered attunement types.
    11. `getChallengeDefinition(string memory challengeId)`: Returns details for a specific challenge.
    12. `hasCompletedChallenge(uint256 tokenId, string memory challengeId)`: Checks if a shard owner has completed a specific challenge.
    13. `checkPendingDecay(uint256 tokenId)`: Calculates and returns the amount of XP/Attunement lost if decay were applied now.
    14. `getVotingPower(uint256 tokenId)`: Calculates a dynamic voting power based on shard state.
    15. `isAccessGranted(uint256 tokenId, uint256 requiredLevel, string memory requiredAttunementType, uint256 requiredAttunementLevel)`: Checks if a shard meets criteria for a gated function.
    16. `getBenefits(uint256 level, string memory benefitType)`: Returns the configured benefit value for a given level and type.
    17. `isAttestationPaused(string memory attestationType)`: Checks if a specific attestation type is paused.
    18. `isDecayPaused()`: Checks if the decay system is paused.

*   **State-Changing Functions:**
    19. `attestActivity(uint256 tokenId, string memory attestationType, uint256 xpAmount, mapping(string => uint256) memory attunementGains)`: Called by Oracle to add state based on activity.
    20. `completeChallenge(uint256 tokenId, string memory challengeId)`: Called by user to claim rewards for a challenge.
    21. `grantBlessing(uint256 tokenId, uint256 xpAmount, mapping(string => uint256) memory attunementGains)`: Called by Owner for direct grants.
    22. `levelUp(uint256 tokenId)`: Called by user to consume XP and advance level.
    23. `attuneShard(uint256 tokenId, string memory attunementType)`: Called by user to set their primary attunement.
    24. `applyDecay(uint256 tokenId)`: Applies decay to a shard's state based on time since last activity. Can be called by anyone or a keeper.
    25. `claimBenefits(uint256 tokenId, string memory benefitType)`: Placeholder function for claiming level/attunement based benefits. Needs specific implementation details for what benefits are claimed.
    26. `forgeArtifact(uint256 tokenId, address artifactRecipient)`: Burns the Shard and potentially mints a different, transferable token to the recipient.

*   **Configuration Functions (Owner Only):**
    27. `setXPThresholds(uint256[] memory levels, uint256[] memory thresholds)`: Sets the XP required for multiple levels.
    28. `setDecayRate(uint256 ratePerSecond)`: Sets the rate at which XP/Attunement decays per second.
    29. `setOracleAddress(address oracle)`: Sets the address allowed to call `attestActivity`.
    30. `addAttunementType(string memory attunementType)`: Adds a new valid type for attunement.
    31. `removeAttunementType(string memory attunementType)`: Removes an attunement type (caution needed if shards already have this attunement).
    32. `defineChallenge(string memory challengeId, uint256 xpReward, mapping(string => uint256) memory attunementRewards, mapping(string => uint256) memory requiredState)`: Defines or updates a challenge.
    33. `configureBenefits(uint256 level, string memory benefitType, uint256 value)`: Configures a specific benefit value for a given level and benefit type.

*   **Management Functions (Owner Only):**
    34. `mintShard(address owner)`: Mints a new Chronicle Shard for an address.
    35. `burnShard(uint256 tokenId)`: Burns a Chronicle Shard.
    36. `pauseAttestation(string memory attestationType)`: Pauses gaining state from a specific attestation type.
    37. `unpauseAttestation(string memory attestationType)`: Unpauses gaining state from a specific attestation type.
    38. `pauseDecay()`: Pauses the decay system for all shards.
    39. `unpauseDecay()`: Unpauses the decay system.

Total custom functions listed above: **39**. This meets the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks by default, good practice or needed for complex calculations.
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // Example dependency if forging creates ERC1155

// --- Contract Outline: Chronicle Shard ---
// This contract implements a dynamic, reputation-based NFT system.
// It represents a user's progressive standing within an ecosystem,
// gaining state (XP, Attunement, Level) through verifiable activities
// and potentially decaying over time. The state grants dynamic benefits
// like weighted voting power or access to gated functions.
// It extends ERC-721 but adds significant custom logic for state management,
// progression, decay, attestation, and utility.

// --- Function Summary ---
// View Functions (Read-only):
// 1.  getShardState(uint256 tokenId) - Retrieve all dynamic state.
// 2.  getLevel(uint256 tokenId) - Get current level.
// 3.  getXP(uint256 tokenId) - Get current XP.
// 4.  getAttunement(uint256 tokenId, string memory attunementType) - Get attunement level for a type.
// 5.  getStatus(uint256 tokenId) - Get current status (Active/Dormant).
// 6.  getLastActivityTime(uint256 tokenId) - Get timestamp of last state change.
// 7.  getXPThresholds() - Return level to XP mapping.
// 8.  getDecayRate() - Return current decay rate.
// 9.  getOracleAddress() - Return authorized oracle address.
// 10. getAttunementTypes() - Return list of valid attunement types.
// 11. getChallengeDefinition(string memory challengeId) - Return details for a challenge.
// 12. hasCompletedChallenge(uint256 tokenId, string memory challengeId) - Check if challenge completed.
// 13. checkPendingDecay(uint256 tokenId) - Calculate potential decay loss.
// 14. getVotingPower(uint256 tokenId) - Calculate dynamic voting power.
// 15. isAccessGranted(uint256 tokenId, uint256 requiredLevel, string memory requiredAttunementType, uint256 requiredAttunementLevel) - Check access criteria.
// 16. getBenefits(uint256 level, string memory benefitType) - Get configured benefit value.
// 17. isAttestationPaused(string memory attestationType) - Check if attestation type is paused.
// 18. isDecayPaused() - Check if decay is paused.

// State-Changing Functions:
// 19. attestActivity(uint256 tokenId, string memory attestationType, uint256 xpAmount, mapping(string => uint256) memory attunementGains) - Oracle grants state.
// 20. completeChallenge(uint256 tokenId, string memory challengeId) - User claims challenge reward.
// 21. grantBlessing(uint256 tokenId, uint256 xpAmount, mapping(string => uint256) memory attunementGains) - Owner grants state.
// 22. levelUp(uint256 tokenId) - User consumes XP to level up.
// 23. attuneShard(uint256 tokenId, string memory attunementType) - User sets primary attunement.
// 24. applyDecay(uint256 tokenId) - Applies decay to a shard.
// 25. claimBenefits(uint256 tokenId, string memory benefitType) - Placeholder for claiming benefits.
// 26. forgeArtifact(uint256 tokenId, address artifactRecipient) - Burns Shard to potentially mint a transferable token.

// Configuration Functions (Owner Only):
// 27. setXPThresholds(uint256[] memory levels, uint256[] memory thresholds) - Set XP needed for levels.
// 28. setDecayRate(uint256 ratePerSecond) - Set decay rate.
// 29. setOracleAddress(address oracle) - Set authorized oracle address.
// 30. addAttunementType(string memory attunementType) - Add new attunement type.
// 31. removeAttunementType(string memory attunementType) - Remove attunement type.
// 32. defineChallenge(string memory challengeId, uint256 xpReward, mapping(string => uint256) memory attunementRewards, mapping(string => uint256) memory requiredState) - Define/update a challenge.
// 33. configureBenefits(uint256 level, string memory benefitType, uint256 value) - Configure benefit value per level/type.

// Management Functions (Owner Only):
// 34. mintShard(address owner) - Mint a new shard.
// 35. burnShard(uint256 tokenId) - Burn a shard.
// 36. pauseAttestation(string memory attestationType) - Pause state gain from type.
// 37. unpauseAttestation(string memory attestationType) - Unpause state gain from type.
// 38. pauseDecay() - Pause decay for all shards.
// 39. unpauseDecay() - Unpause decay for all shards.

contract ChronicleShard is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Using SafeMath just in case complex calculations need explicit overflow checks, though 0.8+ is generally safe.

    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    enum ShardStatus { Active, Dormant, Attuned, Forged }

    struct ShardState {
        uint256 level;
        uint256 xp;
        string primaryAttunementType; // The type the user wants to prioritize
        mapping(string => uint256) attunements; // Specific attunement levels by type
        uint256 lastActivityTime; // Timestamp of last state-changing event
        ShardStatus status;
        bool exists; // To check if the state struct is initialized for a token
    }

    struct Challenge {
        uint256 xpReward;
        mapping(string => uint256) attunementRewards; // Rewards per attunement type
        mapping(string => uint256) requiredState; // State params required to complete (e.g., level, specific attunement level)
        bool defined; // To check if challenge exists
    }

    // --- State Variables ---

    mapping(uint256 => ShardState) private _shardStates;
    mapping(uint256 => uint256) private _xpThresholds; // level => xpRequired
    uint256 private _decayRatePerSecond; // XP/Attunement decay per second per unit time inactive
    address private _oracleAddress;

    mapping(string => bool) private _attunementTypes; // Valid attunement types
    string[] private _attunementTypesList; // For enumeration

    mapping(string => Challenge) private _challenges;
    mapping(uint256 => mapping(string => bool)) private _userChallengeCompletion; // tokenId => challengeId => completed

    mapping(string => bool) private _attestationPaused; // attestationType => paused
    bool private _decayPaused;

    // Generic benefits mapping: level => benefitType => value
    mapping(uint256 => mapping(string => uint256)) private _benefits;

    // Address of a potential ERC1155 artifact contract for forging (Example)
    address private _artifactContract;
    uint256 private _artifactTypeId; // Example type ID for the forged artifact

    // --- Events ---

    event ShardMinted(uint256 indexed tokenId, address indexed owner);
    event ShardBurned(uint256 indexed tokenId);
    event XPEarned(uint256 indexed tokenId, uint256 amount, string source);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 xpConsumed);
    event AttunementGained(uint256 indexed tokenId, string indexed attunementType, uint256 amount, string source);
    event AttunementSet(uint256 indexed tokenId, string indexed attunementType);
    event ShardDecayed(uint256 indexed tokenId, uint256 xpLost, mapping(string => uint256) attunementLost);
    event ChallengeCompleted(uint256 indexed tokenId, string indexed challengeId);
    event BenefitsClaimed(uint256 indexed tokenId, string indexed benefitType, uint256 value);
    event ArtifactForged(uint256 indexed oldTokenId, address indexed recipient, address indexed artifactContract, uint256 artifactTypeId);
    event XPThresholdsUpdated();
    event DecayRateUpdated(uint256 rate);
    event OracleAddressUpdated(address indexed oracle);
    event AttunementTypeAdded(string indexed attunementType);
    event AttunementTypeRemoved(string indexed attunementType);
    event ChallengeDefined(string indexed challengeId);
    event BenefitsConfigured(uint256 level, string indexed benefitType, uint256 value);
    event AttestationPaused(string indexed attestationType);
    event AttestationUnpaused(string indexed attestationType);
    event DecayPaused();
    event DecayUnpaused();
    event PrimaryAttunementChanged(uint256 indexed tokenId, string indexed newAttunementType);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "CS: Only oracle");
        _;
    }

    modifier whenNotPaused(string memory attestationType) {
        require(!_attestationPaused[attestationType], "CS: Attestation type paused");
        _;
    }

    modifier onlyShardOwner(uint256 tokenId) {
        require(_exists(tokenId), "CS: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "CS: Not shard owner");
        _;
    }

    modifier requiresShardState(uint256 tokenId, uint256 requiredLevel, string memory requiredAttunementType, uint256 requiredAttunementLevel) {
        require(_exists(tokenId), "CS: Token does not exist");
        ShardState storage state = _shardStates[tokenId];
        _applyDecayInternal(tokenId); // Apply potential decay before checking requirements
        require(state.level >= requiredLevel, "CS: Level requirement not met");
        if (bytes(requiredAttunementType).length > 0) {
            require(state.attunements[requiredAttunementType] >= requiredAttunementLevel, "CS: Attunement requirement not met");
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address oracle) ERC721(name, symbol) Ownable(msg.sender) {
        _oracleAddress = oracle;
        _decayRatePerSecond = 1; // Default decay rate
        _decayPaused = false;
    }

    // --- ERC721 Overrides ---

    // Prevent standard transfers to make them Soulbound-like
    // Allow forging via forgeArtifact function
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        // Allow minting (from == address(0)) and burning (to == address(0))
        if (from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, tokenId, batchSize);
            return;
        }

        // Only allow transfers initiated by the forgeArtifact function (handled by burning the old token)
        // Standard transfers are blocked.
        revert("CS: Chronicle Shards are non-transferable");
        // If we wanted *some* transferability (e.g., only by owner, only if level > X),
        // we would add logic here, e.g., `if (from != address(0) && to != address(0) && msg.sender != ownerOf(tokenId)) revert(...)`
        // or add a state check like `require(getShardState(tokenId).status == ShardStatus.Forged, "CS: Shards are non-transferable");`
        // but the current concept is non-transferable unless forged.
        // The forging process *burns* the old token, so a standard transfer won't happen from -> to for the shard itself.
    }

    // The following functions are needed for ERC721Enumerable and ERC721URIStorage
    // to work correctly with OpenZeppelin's implementations.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        // This can point to a metadata server that generates metadata based on the shard's on-chain state
        // Example: return "https://your-metadata-server.com/shard/";
        // The server would need to query the contract state for a given tokenId to return dynamic metadata.
        return "ipfs://YOUR_METADATA_CID/"; // Placeholder
    }

    // We override tokenURI to potentially fetch from a dynamic source if needed,
    // though the baseURI combined with token ID is the standard way.
    // If metadata is *strictly* dynamic based on state, the metadata server would handle it.
    // If metadata contains base traits *plus* dynamic parts, the baseURI might point to a base JSON,
    // and the server injects dynamic fields.
    // For simplicity here, we just use the inherited baseURI.
    // function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    //     require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    //     string memory base = _baseURI();
    //     // Example: if base ends with '/', append tokenId, otherwise append '/tokenId'
    //     if (bytes(base).length == 0) {
    //         return "";
    //     }
    //     if (bytes(base).length > 0 && bytes(base)[bytes(base).length - 1] == "/") {
    //         return string(abi.encodePacked(base, _toString(tokenId)));
    //     }
    //     return string(abi.encodePacked(base, "/", _toString(tokenId)));
    // }


    // --- Internal Helpers ---

    // Internal function to apply decay based on time passed
    function _applyDecayInternal(uint256 tokenId) internal {
        ShardState storage state = _shardStates[tokenId];
        if (_decayPaused || state.status != ShardStatus.Active || state.lastActivityTime == 0) {
            return;
        }

        uint256 timeElapsed = block.timestamp - state.lastActivityTime;
        if (timeElapsed == 0) {
            return;
        }

        uint256 potentialDecayXP = timeElapsed.mul(_decayRatePerSecond);
        uint256 xpLost = 0;
        if (state.xp > potentialDecayXP) {
            xpLost = potentialDecayXP;
            state.xp = state.xp.sub(xpLost);
        } else {
            xpLost = state.xp;
            state.xp = 0;
        }

        // Decay attunements - maybe proportional to decay rate or a separate rate
        // Example: Simple proportional decay
        mapping(string => uint256) memory attunementLost = new mapping(string => uint256);
        for (uint i = 0; i < _attunementTypesList.length; i++) {
            string memory attunementType = _attunementTypesList[i];
            uint256 potentialDecayAttunement = (timeElapsed.mul(_decayRatePerSecond)).div(10); // Example: attunement decays slower
            if (state.attunements[attunementType] > potentialDecayAttunement) {
                attunementLost[attunementType] = potentialDecayAttunement;
                state.attunements[attunementType] = state.attunements[attunementType].sub(attunementLost[attunementType]);
            } else {
                 attunementLost[attunementType] = state.attunements[attunementType];
                state.attunements[attunementType] = 0;
            }
        }

        state.lastActivityTime = block.timestamp; // Update activity time after applying decay

        if (xpLost > 0 || _attunementTypesList.length > 0) {
            emit ShardDecayed(tokenId, xpLost, attunementLost);
        }

        // Re-check status or level down logic if needed after decay
        // This would require comparing current XP to levels below the current one
    }

     // Internal function to add XP and update activity time
    function _addXP(uint256 tokenId, uint256 amount, string memory source) internal {
        require(_exists(tokenId), "CS: Token does not exist");
         ShardState storage state = _shardStates[tokenId];
        require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        _applyDecayInternal(tokenId); // Apply decay before adding XP
        state.xp = state.xp.add(amount);
        state.lastActivityTime = block.timestamp;
        emit XPEarned(tokenId, amount, source);
    }

    // Internal function to add Attunement and update activity time
    function _addAttunement(uint256 tokenId, string memory attunementType, uint256 amount, string memory source) internal {
         require(_exists(tokenId), "CS: Token does not exist");
         require(_attunementTypes[attunementType], "CS: Invalid attunement type");
         ShardState storage state = _shardStates[tokenId];
         require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        _applyDecayInternal(tokenId); // Apply decay before adding Attunement
        state.attunements[attunementType] = state.attunements[attunementType].add(amount);
        state.lastActivityTime = block.timestamp;
        emit AttunementGained(tokenId, attunementType, amount, source);
    }

    // Internal function to update activity time without adding state
    function _updateActivityTime(uint256 tokenId) internal {
        require(_exists(tokenId), "CS: Token does not exist");
        ShardState storage state = _shardStates[tokenId];
        state.lastActivityTime = block.timestamp;
    }

    // --- View Functions ---

    function getShardState(uint256 tokenId) public view returns (ShardState memory) {
        require(_shardStates[tokenId].exists, "CS: Token state does not exist");
         // Note: view functions cannot modify state, so decay is *not* applied here.
         // Use checkPendingDecay if you need to see the potential decay.
        return _shardStates[tokenId];
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        return _shardStates[tokenId].level;
    }

     function getXP(uint256 tokenId) public view returns (uint256) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        return _shardStates[tokenId].xp;
    }

    function getAttunement(uint256 tokenId, string memory attunementType) public view returns (uint256) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
         require(_attunementTypes[attunementType], "CS: Invalid attunement type");
        return _shardStates[tokenId].attunements[attunementType];
    }

    function getStatus(uint256 tokenId) public view returns (ShardStatus) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        return _shardStates[tokenId].status;
    }

    function getLastActivityTime(uint256 tokenId) public view returns (uint256) {
        require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        return _shardStates[tokenId].lastActivityTime;
    }

    function getXPThresholds() public view returns (uint256[] memory levels, uint256[] memory thresholds) {
         uint256 count = 0;
         // This iteration is inefficient. A better approach for production is
         // to store levels with thresholds in an array/struct and iterate that.
         // For this example, we iterate up to a reasonable max level.
         uint256 maxLevel = 100; // Example limit
         for(uint i = 1; i <= maxLevel; i++) {
             if(_xpThresholds[i] > 0) { // Assuming 0 means threshold not set
                 count++;
             }
         }

         levels = new uint256[](count);
         thresholds = new uint256[](count);
         uint256 index = 0;
         for(uint i = 1; i <= maxLevel; i++) {
             if(_xpThresholds[i] > 0) {
                 levels[index] = i;
                 thresholds[index] = _xpThresholds[i];
                 index++;
             }
         }
         return (levels, thresholds);
    }

    function getDecayRate() public view returns (uint256) {
        return _decayRatePerSecond;
    }

    function getOracleAddress() public view returns (address) {
        return _oracleAddress;
    }

    function getAttunementTypes() public view returns (string[] memory) {
        return _attunementTypesList;
    }

    function getChallengeDefinition(string memory challengeId) public view returns (uint256 xpReward, mapping(string => uint256) memory attunementRewards, mapping(string => uint256) memory requiredState) {
        require(_challenges[challengeId].defined, "CS: Challenge not defined");
        Challenge storage challenge = _challenges[challengeId];
        return (challenge.xpReward, challenge.attunementRewards, challenge.requiredState);
    }

    function hasCompletedChallenge(uint256 tokenId, string memory challengeId) public view returns (bool) {
         require(_exists(tokenId), "CS: Token does not exist");
         require(_challenges[challengeId].defined, "CS: Challenge not defined");
        return _userChallengeCompletion[tokenId][challengeId];
    }

    // Calculates potential decay without applying it
    function checkPendingDecay(uint256 tokenId) public view returns (uint256 potentialDecayXP, mapping(string => uint256) memory potentialDecayAttunement) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        ShardState storage state = _shardStates[tokenId];
        potentialDecayAttunement = new mapping(string => uint256); // Initialize memory mapping

        if (_decayPaused || state.status != ShardStatus.Active || state.lastActivityTime == 0) {
            return (0, potentialDecayAttunement);
        }

        uint256 timeElapsed = block.timestamp - state.lastActivityTime;
        if (timeElapsed == 0) {
             return (0, potentialDecayAttunement);
        }

        potentialDecayXP = timeElapsed.mul(_decayRatePerSecond);

        for (uint i = 0; i < _attunementTypesList.length; i++) {
            string memory attunementType = _attunementTypesList[i];
            potentialDecayAttunement[attunementType] = (timeElapsed.mul(_decayRatePerSecond)).div(10); // Example: attunement decays slower
        }

         return (potentialDecayXP, potentialDecayAttunement);
    }

    // Example dynamic voting power calculation
    // This is a simplified example, real logic would be complex
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        ShardState storage state = _shardStates[tokenId];
         // Note: decay isn't applied in view function, so power might be higher than it would be after applying decay.
        uint256 basePower = state.level.mul(10); // Base power from level
        uint256 attunementBonus = 0;
        // Sum attunement levels, maybe weighted by primary attunement
         for (uint i = 0; i < _attunementTypesList.length; i++) {
            string memory attunementType = _attunementTypesList[i];
             uint256 attunementLevel = state.attunements[attunementType];
             if (state.primaryAttunementType == attunementType) {
                 attunementBonus = attunementBonus.add(attunementLevel.mul(2)); // Double bonus for primary
             } else {
                 attunementBonus = attunementBonus.add(attunementLevel);
             }
        }
        return basePower.add(attunementBonus).add(state.xp.div(100)); // Add some power from XP
    }

     // Checks if a shard meets criteria for a gated function/action
     function isAccessGranted(uint256 tokenId, uint256 requiredLevel, string memory requiredAttunementType, uint256 requiredAttunementLevel) public view returns (bool) {
         require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        ShardState storage state = _shardStates[tokenId];
        // Note: decay isn't applied in view function. For critical access, apply decay first.
        if (state.level < requiredLevel) return false;
        if (bytes(requiredAttunementType).length > 0) {
             if (!_attunementTypes[requiredAttunementType]) return false; // Requirement for non-existent type always fails
             if (state.attunements[requiredAttunementType] < requiredAttunementLevel) return false;
        }
        return true;
     }

    function getBenefits(uint256 level, string memory benefitType) public view returns (uint256) {
        return _benefits[level][benefitType];
    }

    function isAttestationPaused(string memory attestationType) public view returns (bool) {
        return _attestationPaused[attestationType];
    }

    function isDecayPaused() public view returns (bool) {
        return _decayPaused;
    }


    // --- State-Changing Functions ---

    // Called by the authorized oracle to record an activity or event
    function attestActivity(uint256 tokenId, string memory attestationType, uint256 xpAmount, mapping(string => uint256) memory attunementGains) external onlyOracle whenNotPaused(attestationType) {
        require(_exists(tokenId), "CS: Token does not exist");
        ShardState storage state = _shardStates[tokenId];
        require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        _applyDecayInternal(tokenId); // Apply decay before granting new state

        if (xpAmount > 0) {
             state.xp = state.xp.add(xpAmount);
            emit XPEarned(tokenId, xpAmount, string(abi.encodePacked("Attestation-", attestationType)));
        }

        string[] memory attunementTypes = _attunementTypesList; // Get list to iterate
        for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             uint256 gain = attunementGains[currentType]; // Get gain for this specific type
             if (gain > 0) {
                 state.attunements[currentType] = state.attunements[currentType].add(gain);
                 emit AttunementGained(tokenId, currentType, gain, string(abi.encodePacked("Attestation-", attestationType)));
             }
        }

        state.lastActivityTime = block.timestamp;
    }

    // Allows a user to claim rewards for completing a predefined challenge
    function completeChallenge(uint256 tokenId, string memory challengeId) external onlyShardOwner(tokenId) {
        require(_challenges[challengeId].defined, "CS: Challenge not defined");
        require(!_userChallengeCompletion[tokenId][challengeId], "CS: Challenge already completed");
        ShardState storage state = _shardStates[tokenId];
        require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        // Check if the shard meets the required state for the challenge (optional)
        Challenge storage challenge = _challenges[challengeId];
        string[] memory attunementTypes = _attunementTypesList; // Get list to iterate
         for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             uint256 requiredAtt = challenge.requiredState[currentType];
             if (requiredAtt > 0) {
                 require(state.attunements[currentType] >= requiredAtt, string(abi.encodePacked("CS: Challenge requirement not met for attunement ", currentType)));
             }
         }
         // Add other requiredState checks here (e.g., level, XP)
         if(challenge.requiredState["level"] > 0) {
             require(state.level >= challenge.requiredState["level"], "CS: Challenge level requirement not met");
         }


        _applyDecayInternal(tokenId); // Apply decay before granting rewards

        if (challenge.xpReward > 0) {
            state.xp = state.xp.add(challenge.xpReward);
            emit XPEarned(tokenId, challenge.xpReward, string(abi.encodePacked("Challenge-", challengeId)));
        }

        for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             uint256 gain = challenge.attunementRewards[currentType];
             if (gain > 0) {
                 state.attunements[currentType] = state.attunements[currentType].add(gain);
                 emit AttunementGained(tokenId, currentType, gain, string(abi.encodePacked("Challenge-", challengeId)));
             }
        }

        _userChallengeCompletion[tokenId][challengeId] = true;
        state.lastActivityTime = block.timestamp;
        emit ChallengeCompleted(tokenId, challengeId);
    }

     // Allows the contract owner to directly grant state (e.g., for special events)
    function grantBlessing(uint256 tokenId, uint256 xpAmount, mapping(string => uint256) memory attunementGains) external onlyOwner {
         require(_exists(tokenId), "CS: Token does not exist");
        ShardState storage state = _shardStates[tokenId];
        require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        _applyDecayInternal(tokenId); // Apply decay before granting blessing

        if (xpAmount > 0) {
            state.xp = state.xp.add(xpAmount);
            emit XPEarned(tokenId, xpAmount, "Blessing");
        }

        string[] memory attunementTypes = _attunementTypesList; // Get list to iterate
         for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             uint256 gain = attunementGains[currentType];
             if (gain > 0) {
                 require(_attunementTypes[currentType], "CS: Invalid attunement type in blessing");
                 state.attunements[currentType] = state.attunements[currentType].add(gain);
                 emit AttunementGained(tokenId, currentType, gain, "Blessing");
             }
        }

        state.lastActivityTime = block.timestamp;
    }


    // Allows a shard owner to level up if they have enough XP
    function levelUp(uint256 tokenId) external onlyShardOwner(tokenId) {
        ShardState storage state = _shardStates[tokenId];
         require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        _applyDecayInternal(tokenId); // Apply decay before checking XP threshold

        uint256 nextLevel = state.level.add(1);
        uint256 requiredXP = _xpThresholds[nextLevel];

        require(requiredXP > 0, "CS: No XP threshold defined for next level");
        require(state.xp >= requiredXP, "CS: Insufficient XP for level up");

        state.xp = state.xp.sub(requiredXP); // Consume required XP
        state.level = nextLevel;
        state.lastActivityTime = block.timestamp; // Level up counts as activity

        emit LevelUp(tokenId, nextLevel, requiredXP);
    }

    // Allows a shard owner to set their primary attunement type
    // This might influence decay rates or benefit calculations
    function attuneShard(uint256 tokenId, string memory attunementType) external onlyShardOwner(tokenId) {
         require(_exists(tokenId), "CS: Token does not exist");
         require(_attunementTypes[attunementType], "CS: Invalid attunement type");
        ShardState storage state = _shardStates[tokenId];
         require(state.status == ShardStatus.Active, "CS: Shard not active"); // Can only attune from Active state

        state.primaryAttunementType = attunementType;
        state.status = ShardStatus.Attuned;
        state.lastActivityTime = block.timestamp; // Attuning counts as activity

        emit PrimaryAttunementChanged(tokenId, attunementType);
        // Potentially emit AttunementSet if we track attunement *level* change here too, but the prompt is just setting the *type*.
    }

    // Applies decay to a specific shard. Can be called by anyone (incentivize keepers).
    // Applying decay updates the lastActivityTime.
    function applyDecay(uint256 tokenId) external {
        require(_shardStates[tokenId].exists, "CS: Token state does not exist");
        _applyDecayInternal(tokenId);
        // _applyDecayInternal already updates lastActivityTime
    }

    // Placeholder for claiming benefits tied to level/attunement
    // This function would need to interact with other parts of the ecosystem
    // (e.g., send tokens, grant roles elsewhere).
    // The actual logic depends heavily on what the benefits are.
    function claimBenefits(uint256 tokenId, string memory benefitType) external onlyShardOwner(tokenId) {
         require(_exists(tokenId), "CS: Token does not exist");
         ShardState storage state = _shardStates[tokenId];
         require(state.status == ShardStatus.Active || state.status == ShardStatus.Attuned, "CS: Shard not active/attuned");

        // Example logic: Claim a token amount based on level and a benefit type
        // This requires a corresponding configureBenefits call to define the benefitType and its value per level.
        uint256 benefitValue = _benefits[state.level][benefitType];
        require(benefitValue > 0, "CS: No benefits configured for this level/type");

        // --- Placeholder Logic ---
        // Example: Transfer ERC20 tokens (need ERC20 interface imported and token address stored)
        // IERC20 rewardToken = IERC20(address(0x...)); // Replace with actual token address
        // require(rewardToken.transfer(msg.sender, benefitValue), "CS: Token transfer failed");
        // --- End Placeholder ---

        // Mark as claimed or adjust state if needed (e.g., a one-time claim per level)
        // This requires additional state like mapping(uint256 => mapping(string => bool)) claimedBenefits;

        _updateActivityTime(tokenId); // Claiming benefits counts as activity
        emit BenefitsClaimed(tokenId, benefitType, benefitValue);
    }

    // Allows high-level shards to be 'forged' into a transferable artifact, burning the original shard
    function forgeArtifact(uint256 tokenId, address artifactRecipient) external onlyShardOwner(tokenId) {
         require(_exists(tokenId), "CS: Token does not exist");
         ShardState storage state = _shardStates[tokenId];

         // --- Define Forging Requirements ---
         uint256 minLevelToForge = 50; // Example requirement
         require(state.level >= minLevelToForge, "CS: Level requirement not met for forging");
         // Add other requirements (e.g., minimum XP, specific attunement levels)
         // require(state.xp >= MIN_XP_TO_FORGE, "CS: XP requirement not met");
         // require(state.attunements["mastery"] >= MIN_MASTERY_TO_FORGE, "CS: Mastery requirement not met");
         require(state.status != ShardStatus.Forged, "CS: Shard already forged");
         // --- End Requirements ---

        _applyDecayInternal(tokenId); // Apply decay before forging

        // Set shard status to Forged (prevents further state changes/interactions with the shard)
        state.status = ShardStatus.Forged;

        // --- Mint the Artifact Token (Placeholder) ---
        // This assumes you have another contract (e.g., an ERC1155 factory)
        // responsible for minting the transferable artifact.
        // Example: ERC1155 artifact contract at _artifactContract, using _artifactTypeId
        // IERC1155 artifactContract = IERC1155(_artifactContract);
        // require(artifactContract.mint(artifactRecipient, _artifactTypeId, 1, ""), "CS: Artifact mint failed");
        // --- End Placeholder ---

        // Burn the original shard NFT
        uint256 oldTokenId = tokenId; // Keep the ID before burning invalidates it
        _burn(tokenId); // This calls _beforeTokenTransfer internally

        // Clean up shard state (optional, but good practice)
        delete _shardStates[oldTokenId]; // Remove the state data

        emit ArtifactForged(oldTokenId, artifactRecipient, _artifactContract, _artifactTypeId); // Emit event about the forging

    }

     // Function example for a gated function call
     // This function can only be called if the sender owns a shard meeting criteria
     // The actual logic of this function would be specific to the protocol
     function performGatedAction(uint256 tokenId, bytes memory actionData) external onlyShardOwner(tokenId) requiresShardState(tokenId, 10, "governance", 5) {
         // Example: Requires Level 10 and "governance" Attunement Level 5
         // This function body would contain the privileged logic

         _updateActivityTime(tokenId); // Performing a gated action counts as activity

         // --- Placeholder Gated Action Logic ---
         // Example: Allow sending a proposal to a DAO contract
         // DAO_CONTRACT.createProposal(actionData);
         // --- End Placeholder ---

     }


    // --- Configuration Functions (Owner Only) ---

    function setXPThresholds(uint256[] memory levels, uint256[] memory thresholds) external onlyOwner {
        require(levels.length == thresholds.length, "CS: Mismatched array lengths");
        for (uint i = 0; i < levels.length; i++) {
            require(levels[i] > 0, "CS: Level must be greater than 0");
            _xpThresholds[levels[i]] = thresholds[i];
        }
        emit XPThresholdsUpdated();
    }

    function setDecayRate(uint256 ratePerSecond) external onlyOwner {
        _decayRatePerSecond = ratePerSecond;
        emit DecayRateUpdated(ratePerSecond);
    }

    function setOracleAddress(address oracle) external onlyOwner {
        require(oracle != address(0), "CS: Oracle address cannot be zero");
        _oracleAddress = oracle;
        emit OracleAddressUpdated(oracle);
    }

     function addAttunementType(string memory attunementType) external onlyOwner {
         require(bytes(attunementType).length > 0, "CS: Attunement type cannot be empty");
         require(!_attunementTypes[attunementType], "CS: Attunement type already exists");
        _attunementTypes[attunementType] = true;
        _attunementTypesList.push(attunementType); // Keep list updated
        emit AttunementTypeAdded(attunementType);
     }

     function removeAttunementType(string memory attunementType) external onlyOwner {
         require(_attunementTypes[attunementType], "CS: Attunement type does not exist");
         require(bytes(attunementType).length > 0, "CS: Attunement type cannot be empty"); // Should be covered by exists check, but safety

        // Caution: Removing a type doesn't remove it from existing shards' state.
        // These values will just no longer be earnable or configurable via this type string.
        // If state cleanup is needed, a separate function is required.
        _attunementTypes[attunementType] = false;
        // Remove from _attunementTypesList - this is inefficient in Solidity arrays
        // For production, consider a mapping to index for list management or a different list structure.
        for(uint i = 0; i < _attunementTypesList.length; i++) {
            if (keccak256(abi.encodePacked(_attunementTypesList[i])) == keccak256(abi.encodePacked(attunementType))) {
                // Shift elements to remove the item - inefficient for large arrays
                for(uint j = i; j < _attunementTypesList.length - 1; j++) {
                    _attunementTypesList[j] = _attunementTypesList[j+1];
                }
                _attunementTypesList.pop();
                break; // Found and removed
            }
        }
        emit AttunementTypeRemoved(attunementType);
     }

     // Defines or updates a challenge that users can complete
     function defineChallenge(string memory challengeId, uint256 xpReward, mapping(string => uint256) memory attunementRewards, mapping(string => uint256) memory requiredState) external onlyOwner {
         require(bytes(challengeId).length > 0, "CS: Challenge ID cannot be empty");
         // Basic validation for attunement types in rewards/requirements
         string[] memory attunementTypes = _attunementTypesList;
         for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             // Just check for existence, detailed value validation might be too complex here
             if (attunementRewards[currentType] > 0 && !_attunementTypes[currentType]) revert("CS: Invalid attunement type in rewards");
             if (requiredState[currentType] > 0 && !_attunementTypes[currentType]) revert("CS: Invalid attunement type in requirements");
         }
         // Add checks for other requiredState keys if used (e.g., "level")

        Challenge storage challenge = _challenges[challengeId];
        challenge.xpReward = xpReward;

         // Copy attunement rewards - manual copying needed for memory->storage mapping
         for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             challenge.attunementRewards[currentType] = attunementRewards[currentType];
         }

         // Copy required state - manual copying needed
         // This assumes specific keys like "level" or attunement type strings
         challenge.requiredState["level"] = requiredState["level"]; // Example key
         for (uint i = 0; i < attunementTypes.length; i++) {
             string memory currentType = attunementTypes[i];
             challenge.requiredState[currentType] = requiredState[currentType]; // Example key based on attunement type
         }


        challenge.defined = true;
        emit ChallengeDefined(challengeId);
     }

    // Configures a specific benefit type and value for a given level
     function configureBenefits(uint256 level, string memory benefitType, uint256 value) external onlyOwner {
        require(level > 0, "CS: Level must be positive");
        require(bytes(benefitType).length > 0, "CS: Benefit type cannot be empty");
        _benefits[level][benefitType] = value;
        emit BenefitsConfigured(level, benefitType, value);
     }

     // Set the artifact contract address and type ID for forging
     function setArtifactConfig(address artifactContract, uint256 artifactTypeId) external onlyOwner {
        require(artifactContract != address(0), "CS: Artifact contract cannot be zero");
        _artifactContract = artifactContract;
        _artifactTypeId = artifactTypeId;
     }

    // --- Management Functions (Owner Only) ---

    // Mints a new shard for a given address
    function mintShard(address owner) external onlyOwner {
        require(owner != address(0), "CS: Cannot mint to zero address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(owner, newTokenId);

        // Initialize the shard state
        ShardState storage newState = _shardStates[newTokenId];
        newState.level = 1; // Start at level 1
        newState.xp = 0;
        newState.primaryAttunementType = ""; // No primary attunement initially
        // attunements mapping is implicitly initialized to 0
        newState.lastActivityTime = block.timestamp;
        newState.status = ShardStatus.Active;
        newState.exists = true;

        emit ShardMinted(newTokenId, owner);
    }

    // Burns a shard
    function burnShard(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "CS: Token does not exist");
         // Optionally add checks like require(ownerOf(tokenId) == msg.sender, "CS: Must own shard to burn"); if allowing user burn

        _burn(tokenId);

        // Clean up shard state
        delete _shardStates[tokenId];

        emit ShardBurned(tokenId);
    }

    // Pauses gaining state from a specific attestation type
    function pauseAttestation(string memory attestationType) external onlyOwner {
         require(_attunementTypes[attestationType], "CS: Attunement type does not exist"); // Assuming attestation types map to attunement types
        _attestationPaused[attestationType] = true;
        emit AttestationPaused(attestationType);
    }

    // Unpauses gaining state from a specific attestation type
    function unpauseAttestation(string memory attestationType) external onlyOwner {
        // Allow unpausing even if type wasn't explicitly added, though unlikely
        _attestationPaused[attestationType] = false;
        emit AttestationUnpaused(attestationType);
    }

    // Pauses the decay system entirely
    function pauseDecay() external onlyOwner {
        _decayPaused = true;
        emit DecayPaused();
    }

    // Unpauses the decay system
    function unpauseDecay() external onlyOwner {
        _decayPaused = false;
        emit DecayUnpaused();
    }


    // The rest of the ERC721Enumerable functions are inherited and functional
    // despite the transfer restriction because _beforeTokenTransfer allows mint/burn.
    // For example: totalSupply(), tokenByIndex(), tokenOfOwnerByIndex() will work.

    // Example using ERC721Enumerable:
    // function getAllShardTokens() public view returns (uint256[] memory) {
    //     uint256 total = totalSupply();
    //     uint256[] memory tokenIds = new uint256[](total);
    //     for (uint256 i = 0; i < total; i++) {
    //         tokenIds[i] = tokenByIndex(i);
    //     }
    //     return tokenIds;
    // }
}
```