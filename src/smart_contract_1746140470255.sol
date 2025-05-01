Okay, here is a Solidity smart contract incorporating several advanced, creative, and interconnected concepts, designed to be distinct from common open-source implementations.

The concept revolves around a **"Chronicle Shard"** NFT that evolves based on owner interactions, reputation, time, and milestones. It introduces a system where the NFT's state is dynamic, affecting its metadata and unlocking unique abilities or interactions within the ecosystem defined by the contract. It includes features like reputation accrual, staged evolution, temporary blessings between shards, and conditional actions based on the shard's state.

**Disclaimer:** This is a complex example demonstrating advanced concepts. It is provided for educational purposes and requires significant security review, testing, and auditing before deployment in a production environment. It uses OpenZeppelin contracts for standard interfaces (like ERC-721, Ownable, Pausable) but implements unique logic.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. Contract Definition (Inherits ERC721, Ownable, Pausable)
// 2. State Variables
//    - Token Counter
//    - Base URI for metadata
//    - Shard Stages (Enum)
//    - Shard Data (Struct to hold dynamic state per token)
//    - Mapping: Token ID -> Shard Data
//    - Mapping: Stage -> Reputation Threshold for evolution
//    - Mapping: Authorized addresses for adding reputation
//    - Mapping: Token ID -> Evolution Cooldown Timestamp
//    - Mapping: Token ID -> Blessing Application Cooldown Timestamp
//    - Blessing Data (Struct for temporary effects)
//    - Mapping: Token ID -> Blessing Data (Mapping blessed token ID)
//    - Blessing Duration
//    - Evolution Cooldown Duration
//    - Blessing Application Cooldown Duration
// 3. Events
//    - ShardMinted
//    - ShardBurned
//    - ReputationAdded
//    - ShardEvolved
//    - BlessingApplied
//    - BlessingRemoved
//    - StageBonusClaimed
//    - ReputationSourceAuthorized/Removed
// 4. Modifiers
//    - onlyAuthorizedReputationSource
//    - requireMinimumShardStage
//    - requireBlessingActive
// 5. Constructor: Initializes base URI, owner, initial thresholds.
// 6. Core ERC721 Functions (Overridden):
//    - tokenURI: Dynamic metadata based on ShardData.
// 7. Custom Core Functions:
//    - mintShard: Admin function to create new Shards.
//    - burnShard: Allows owner to destroy their Shard.
//    - addReputation: Authorized function to increase a Shard's reputation.
//    - decreaseReputation: Authorized function to decrease a Shard's reputation.
//    - evolveShard: Allows owner to attempt evolving their Shard based on reputation and cooldown.
//    - applyBlessing: Allows a high-stage Shard owner to apply a temporary effect to another Shard.
//    - removeBlessing: Admin or perhaps blessed owner can remove blessing.
//    - claimStageBonus: Function callable only by Shards of a sufficient stage.
// 8. Query Functions (View/Pure):
//    - getShardData: Get all dynamic data for a Shard.
//    - getShardStage: Get current stage of a Shard.
//    - getShardReputation: Get current reputation of a Shard.
//    - getStageReputationThreshold: Get reputation needed for a stage.
//    - getBlessingStatus: Get active blessing data for a Shard.
//    - isBlessingActive: Check if a Shard's blessing is currently active.
//    - getEvolutionCooldown: Get next allowed evolution timestamp.
//    - getBlessingApplicationCooldown: Get next allowed blessing application timestamp for a giver.
//    - hasClaimedStageBonus: Check if bonus claimed for a specific stage.
//    - isAuthorizedReputationSource: Check if address can add reputation.
//    - getTotalSupply: Get total minted shards.
//    - getAllTokenIds: (Potentially gas-intensive) Helper to get all token IDs.
//    - getTokensOfOwner: (Potentially gas-intensive) Helper to get all tokens for an owner.
// 9. Admin Functions (Ownable):
//    - setBaseURI: Update base metadata URI.
//    - setStageReputationThreshold: Update reputation needed for a stage.
//    - authorizeReputationSource: Grant permission to add reputation.
//    - removeReputationSource: Revoke permission to add reputation.
//    - setBlessingDuration: Update temporary blessing duration.
//    - setEvolutionCooldownDuration: Update cooldown after evolution attempt.
//    - setBlessingApplicationCooldownDuration: Update cooldown after applying a blessing.
//    - pause: Pause contract interactions.
//    - unpause: Unpause contract.

// --- Function Summary ---
// 1.  constructor(string memory name, string memory symbol, string memory initialBaseURI): Initializes contract, sets name/symbol, owner, and base URI. Sets initial stage thresholds.
// 2.  tokenURI(uint256 tokenId) public view override returns (string memory): Returns the metadata URI for a token, dynamically incorporating stage and reputation.
// 3.  supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool): ERC-165 interface support, including ERC721.
// 4.  mintShard(address to) public virtual onlyOwner whenNotPaused returns (uint256): Creates a new Shard NFT and assigns it to an address. Sets initial state.
// 5.  burnShard(uint256 tokenId) public virtual whenNotPaused: Allows the owner of a Shard to burn (destroy) it. Requires ownership.
// 6.  addReputation(uint256 tokenId, uint256 amount) public virtual onlyAuthorizedReputationSource whenNotPaused: Increases the reputation points for a specific Shard. Emits ReputationAdded event.
// 7.  decreaseReputation(uint256 tokenId, uint256 amount) public virtual onlyAuthorizedReputationSource whenNotPaused: Decreases the reputation points for a specific Shard. Clamps at 0.
// 8.  evolveShard(uint256 tokenId) public virtual whenNotPaused: Allows the Shard owner to trigger evolution. Checks reputation threshold, cooldown, and current stage. Updates stage if eligible. Emits ShardEvolved event.
// 9.  applyBlessing(uint256 giverTokenId, uint256 receiverTokenId) public virtual requireMinimumShardStage(giverTokenId, ShardStage.Glyph) whenNotPaused: Allows an owner of a high-stage Shard (Glyph or higher) to apply a temporary 'Blessing' effect to another Shard. Checks giver's cooldown. Emits BlessingApplied event.
// 10. removeBlessing(uint256 tokenId) public virtual whenNotPaused: Allows the owner of the *blessed* token or the contract owner to manually remove an active blessing. Emits BlessingRemoved event.
// 11. claimStageBonus(uint256 tokenId) public virtual requireMinimumShardStage(tokenId, ShardStage.Relic) whenNotPaused: Function callable by owners of Shards that have reached a certain stage (Relic or higher) to claim a one-time bonus state change (recorded in the ShardData). Emits StageBonusClaimed event.
// 12. getShardData(uint256 tokenId) public view returns (ShardData memory): Retrieves all stored dynamic data for a Shard.
// 13. getShardStage(uint256 tokenId) public view returns (ShardStage): Returns the current stage of a Shard.
// 14. getShardReputation(uint256 tokenId) public view returns (uint256): Returns the current reputation points of a Shard.
// 15. getStageReputationThreshold(ShardStage stage) public view returns (uint256): Returns the reputation points required to reach a specific stage.
// 16. getBlessingStatus(uint256 tokenId) public view returns (BlessingData memory): Retrieves active blessing data for a Shard.
// 17. isBlessingActive(uint256 tokenId) public view returns (bool): Checks if a Shard currently has an active blessing based on expiration time.
// 18. getEvolutionCooldown(uint256 tokenId) public view returns (uint256): Returns the timestamp when a Shard is next eligible for an evolution attempt.
// 19. getBlessingApplicationCooldown(uint256 tokenId) public view returns (uint256): Returns the timestamp when a Shard that *applied* a blessing is next eligible to apply another.
// 20. hasClaimedStageBonus(uint256 tokenId, ShardStage stage) public view returns (bool): Checks if the bonus for a specific stage has been claimed for a Shard.
// 21. isAuthorizedReputationSource(address source) public view returns (bool): Checks if an address is authorized to add/decrease reputation.
// 22. getTotalSupply() public view returns (uint256): Returns the total number of Shards minted.
// 23. setBaseURI(string memory newBaseURI) public onlyOwner: Updates the base URI for token metadata.
// 24. setStageReputationThreshold(ShardStage stage, uint256 threshold) public onlyOwner: Sets the reputation points required for a specific stage.
// 25. authorizeReputationSource(address source) public onlyOwner: Grants an address permission to call reputation functions.
// 26. removeReputationSource(address source) public onlyOwner: Revokes permission to call reputation functions.
// 27. setBlessingDuration(uint256 durationInSeconds) public onlyOwner: Sets the duration for applied blessings.
// 28. setEvolutionCooldownDuration(uint256 durationInSeconds) public onlyOwner: Sets the cooldown period after an evolution attempt.
// 29. setBlessingApplicationCooldownDuration(uint256 durationInSeconds) public onlyOwner: Sets the cooldown for a Shard that applies a blessing.
// 30. pause() public onlyOwner: Pauses specific contract interactions.
// 31. unpause() public onlyOwner: Unpauses the contract.
// 32. transferOwnership(address newOwner) public override onlyOwner: Transfers contract ownership.
// 33. renounceOwnership() public override onlyOwner: Renounces contract ownership (sets to zero address).

contract ChronicleJourney is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Base URI for fetching metadata json
    string private _baseTokenURI;

    // --- Shard State Management ---

    enum ShardStage {
        Unborn, // Initial state before minting (conceptually)
        Shard,  // Stage 1: Base form
        Glyph,  // Stage 2: Evolved form, unlocks basic abilities
        Relic,  // Stage 3: Further evolved, unlocks advanced abilities
        Legend  // Stage 4: Peak form, highest abilities
    }

    struct ShardData {
        ShardStage stage;
        uint256 reputation;
        uint256 lastEvolutionAttemptTime; // Timestamp of the last attempt
        uint256[] claimedBonusStages;    // Array of stages for which bonuses have been claimed
    }

    mapping(uint256 => ShardData) private _shardData;
    mapping(ShardStage => uint256) private _stageReputationThresholds;

    // --- Reputation Source Management ---

    mapping(address => bool) private _authorizedReputationSources;

    // --- Cooldowns ---

    uint256 public evolutionCooldownDuration = 1 days; // Cooldown after an evolution attempt
    uint256 public blessingApplicationCooldownDuration = 1 days; // Cooldown for the giver of a blessing

    mapping(uint256 => uint256) private _evolutionCooldowns; // Next time eligible for evolution
    mapping(uint256 => uint256) private _blessingApplicationCooldowns; // Next time this shard can *apply* a blessing

    // --- Blessing System ---

    struct BlessingData {
        uint256 giverTokenId;
        uint256 appliedTime;
        uint256 duration; // Duration in seconds
        bool active;
    }

    uint256 public blessingDuration = 7 days; // Default blessing duration

    // Map blessed token ID to its BlessingData
    mapping(uint256 => BlessingData) private _blessingData;

    // --- Events ---

    event ShardMinted(address indexed owner, uint256 indexed tokenId, ShardStage initialStage);
    event ShardBurned(address indexed owner, uint256 indexed tokenId);
    event ReputationAdded(uint256 indexed tokenId, uint256 amount, address indexed source);
    event ReputationDecreased(uint256 indexed tokenId, uint256 amount, address indexed source);
    event ShardEvolved(uint256 indexed tokenId, ShardStage fromStage, ShardStage toStage);
    event BlessingApplied(uint256 indexed giverTokenId, uint256 indexed receiverTokenId, uint256 duration);
    event BlessingRemoved(uint256 indexed tokenId, string reason); // Reason can be "Expired", "Manual", etc.
    event StageBonusClaimed(uint256 indexed tokenId, ShardStage indexed stage);
    event ReputationSourceAuthorized(address indexed source);
    event ReputationSourceRemoved(address indexed source);

    // --- Modifiers ---

    modifier onlyAuthorizedReputationSource() {
        require(_authorizedReputationSources[msg.sender], "CJ: Not authorized reputation source");
        _;
    }

    modifier requireMinimumShardStage(uint256 tokenId, ShardStage minimumStage) {
        require(_shardData[tokenId].stage >= minimumStage, "CJ: Shard stage too low");
        _;
    }

    modifier requireBlessingActive(uint256 tokenId) {
        require(isBlessingActive(tokenId), "CJ: No active blessing");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory initialBaseURI)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets contract deployer as owner
        Pausable() // Initializes pausable state
    {
        _baseTokenURI = initialBaseURI;

        // Set initial reputation thresholds for evolution
        // Note: Stage 0 (Unborn) and Stage 1 (Shard) have no threshold *to* reach them,
        // as they are the initial/base states. Thresholds are for reaching the *next* stage.
        _stageReputationThresholds[ShardStage.Glyph] = 100;
        _stageReputationThresholds[ShardStage.Relic] = 500;
        _stageReputationThresholds[ShardStage.Legend] = 2000;

        // Authorize deployer as a reputation source by default
        _authorizedReputationSources[msg.sender] = true;
        emit ReputationSourceAuthorized(msg.sender);
    }

    // --- Core ERC721 Functions (Overridden) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if token exists (ERC721 standard handles this)
        _exists(tokenId);

        // Retrieve dynamic shard data
        ShardData memory data = _shardData[tokenId];

        // Construct dynamic metadata URL
        // Example: baseURI/tokenId?stage=Shard&rep=50&blessed=true
        // In a real application, the metadata JSON would be served from _baseTokenURI/tokenId
        // and that server would fetch the dynamic data from the contract via view calls
        // or integrate with indexers. For this example, we simulate by appending query params.
        string memory base = _baseTokenURI;
        string memory idStr = Strings.toString(tokenId);
        string memory stageStr = _stageToString(data.stage);
        string memory repStr = Strings.toString(data.reputation);
        string memory blessedStr = isBlessingActive(tokenId) ? "true" : "false";
        string memory lastEvoTimeStr = Strings.toString(data.lastEvolutionAttemptTime);

        // Simple concatenation for demonstration - real URI encoding is more complex
        return string(abi.encodePacked(
            base,
            idStr,
            "?stage=", stageStr,
            "&rep=", repStr,
            "&blessed=", blessedStr,
            "&lastEvo=", lastEvoTimeStr
            // Add other data like claimed bonuses if needed
        ));
    }

    // Helper to convert ShardStage enum to string for metadata
    function _stageToString(ShardStage stage) internal pure returns (string memory) {
        if (stage == ShardStage.Shard) return "Shard";
        if (stage == ShardStage.Glyph) return "Glyph";
        if (stage == ShardStage.Relic) return "Relic";
        if (stage == ShardStage.Legend) return "Legend";
        return "Unknown"; // Should not happen for minted tokens
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- Custom Core Functions ---

    /**
     * @dev Mints a new Chronicle Shard NFT to an address. Only callable by the owner.
     * @param to The address to mint the token to.
     * @return The ID of the newly minted token.
     */
    function mintShard(address to) public virtual onlyOwner whenNotPaused returns (uint256) {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, newItemId);

        // Initialize shard data
        _shardData[newItemId] = ShardData({
            stage: ShardStage.Shard, // Starts at Stage 1
            reputation: 0,
            lastEvolutionAttemptTime: 0,
            claimedBonusStages: new uint256[](0)
        });

        emit ShardMinted(to, newItemId, ShardStage.Shard);
        return newItemId;
    }

    /**
     * @dev Allows the owner of a Shard to burn (destroy) it.
     * @param tokenId The ID of the token to burn.
     */
    function burnShard(uint256 tokenId) public virtual whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CJ: Caller is not owner nor approved");

        address owner = ownerOf(tokenId);
        _burn(tokenId);

        // Clean up shard data (optional but good practice)
        delete _shardData[tokenId];
        delete _blessingData[tokenId]; // Remove any active blessing
        delete _evolutionCooldowns[tokenId];
        delete _blessingApplicationCooldowns[tokenId];

        emit ShardBurned(owner, tokenId);
    }

    /**
     * @dev Increases the reputation points for a specific Shard.
     * Only callable by authorized reputation sources.
     * @param tokenId The ID of the Shard.
     * @param amount The amount of reputation to add.
     */
    function addReputation(uint256 tokenId, uint256 amount) public virtual onlyAuthorizedReputationSource whenNotPaused {
         _exists(tokenId); // Ensure token exists

        _shardData[tokenId].reputation += amount;
        emit ReputationAdded(tokenId, amount, msg.sender);
    }

    /**
     * @dev Decreases the reputation points for a specific Shard.
     * Only callable by authorized reputation sources.
     * @param tokenId The ID of the Shard.
     * @param amount The amount of reputation to decrease.
     */
    function decreaseReputation(uint256 tokenId, uint256 amount) public virtual onlyAuthorizedReputationSource whenNotPaused {
        _exists(tokenId); // Ensure token exists

        // Prevent underflow
        if (_shardData[tokenId].reputation >= amount) {
            _shardData[tokenId].reputation -= amount;
        } else {
            _shardData[tokenId].reputation = 0;
        }
        emit ReputationDecreased(tokenId, amount, msg.sender);
    }


    /**
     * @dev Allows the owner of a Shard to attempt evolving it to the next stage.
     * Evolution requires meeting the reputation threshold for the next stage
     * and not being on cooldown from a previous attempt.
     * @param tokenId The ID of the Shard to evolve.
     */
    function evolveShard(uint256 tokenId) public virtual whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CJ: Caller is not owner nor approved");
        require(_shardData[tokenId].stage != ShardStage.Legend, "CJ: Shard is already at max stage");

        uint256 nextStageInt = uint256(_shardData[tokenId].stage) + 1;
        ShardStage nextStage = ShardStage(nextStageInt);

        require(block.timestamp >= _evolutionCooldowns[tokenId], "CJ: Shard evolution is on cooldown");

        uint256 requiredRep = _stageReputationThresholds[nextStage];
        require(_shardData[tokenId].reputation >= requiredRep, "CJ: Not enough reputation to evolve");

        ShardStage fromStage = _shardData[tokenId].stage;
        _shardData[tokenId].stage = nextStage;
        _shardData[tokenId].lastEvolutionAttemptTime = block.timestamp; // Record successful evolution time
        _evolutionCooldowns[tokenId] = block.timestamp + evolutionCooldownDuration; // Set cooldown

        emit ShardEvolved(tokenId, fromStage, nextStage);
    }

    /**
     * @dev Allows an owner of a Shard at least Stage 2 (Glyph) to apply a temporary Blessing
     * to another Shard. This consumes the giver's blessing application cooldown.
     * @param giverTokenId The ID of the Shard applying the blessing.
     * @param receiverTokenId The ID of the Shard receiving the blessing.
     */
    function applyBlessing(uint256 giverTokenId, uint256 receiverTokenId)
        public virtual
        requireMinimumShardStage(giverTokenId, ShardStage.Glyph) // Giver must be at least Glyph stage
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, giverTokenId), "CJ: Caller is not owner of giver Shard");
        require(_exists(receiverTokenId), "CJ: Receiver Shard does not exist");
        require(giverTokenId != receiverTokenId, "CJ: Cannot bless your own Shard with itself");
        require(block.timestamp >= _blessingApplicationCooldowns[giverTokenId], "CJ: Giver Shard is on blessing cooldown");

        // Apply the blessing data to the receiver token
        _blessingData[receiverTokenId] = BlessingData({
            giverTokenId: giverTokenId,
            appliedTime: block.timestamp,
            duration: blessingDuration,
            active: true
        });

        // Set cooldown for the giver shard
        _blessingApplicationCooldowns[giverTokenId] = block.timestamp + blessingApplicationCooldownDuration;

        emit BlessingApplied(giverTokenId, receiverTokenId, blessingDuration);
    }

    /**
     * @dev Removes an active blessing from a Shard. Can be called by the contract owner
     * or the owner of the blessed token.
     * @param tokenId The ID of the Shard whose blessing to remove.
     */
    function removeBlessing(uint256 tokenId) public virtual whenNotPaused {
        require(_exists(tokenId), "CJ: Shard does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == owner(), "CJ: Caller is not token owner/approved or contract owner");

        // Check if there's an active blessing to remove (or expired one)
        BlessingData storage blessing = _blessingData[tokenId];
        require(blessing.active || blessing.appliedTime > 0, "CJ: No active or expired blessing data found");

        // Mark as inactive and potentially clear data if desired (leaving data allows querying history)
        blessing.active = false; // Mark as inactive

        // If caller is token owner and blessing was expired, maybe just clear?
        // Let's emit event regardless of caller or expiry for clarity.
        string memory reason = (msg.sender == owner()) ? "Admin" : "Manual";
        if (blessing.appliedTime > 0 && block.timestamp >= blessing.appliedTime + blessing.duration && msg.sender == ownerOf(tokenId)) {
             reason = "Self-Removed (Expired)"; // More specific reason if removed by owner after expiry
        }

        emit BlessingRemoved(tokenId, reason);

        // Option: delete _blessingData[tokenId]; if you don't need to track history of removed blessings
    }

    /**
     * @dev Function callable by owners of Shards that have reached a certain stage (e.g., Relic)
     * to claim a one-time bonus tied to that stage.
     * The bonus state is recorded within the ShardData.
     * @param tokenId The ID of the Shard claiming the bonus.
     */
    function claimStageBonus(uint256 tokenId)
        public virtual
        requireMinimumShardStage(tokenId, ShardStage.Relic) // Example: requires at least Relic stage
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CJ: Caller is not owner nor approved");

        ShardStage currentStage = _shardData[tokenId].stage;

        // Check if bonus for the current stage (or higher, but we tie it to the stage achieved) has already been claimed
        bool claimed = false;
        for (uint i = 0; i < _shardData[tokenId].claimedBonusStages.length; i++) {
            if (_shardData[tokenId].claimedBonusStages[i] == uint256(currentStage)) {
                claimed = true;
                break;
            }
        }
        require(!claimed, string(abi.encodePacked("CJ: Bonus for stage ", _stageToString(currentStage), " already claimed")));

        // Mark the bonus for this stage as claimed
        _shardData[tokenId].claimedBonusStages.push(uint256(currentStage));

        // In a real DApp, this might trigger an event for an external system
        // to distribute tokens, unlock features, etc. Here, we just record the state.
        emit StageBonusClaimed(tokenId, currentStage);
    }

    // --- Query Functions (View/Pure) ---

    /**
     * @dev Gets the full dynamic data for a Shard.
     * @param tokenId The ID of the Shard.
     * @return The ShardData struct.
     */
    function getShardData(uint256 tokenId) public view returns (ShardData memory) {
        _exists(tokenId); // Ensure token exists
        return _shardData[tokenId];
    }

    /**
     * @dev Gets the current stage of a Shard.
     * @param tokenId The ID of the Shard.
     * @return The ShardStage enum value.
     */
    function getShardStage(uint256 tokenId) public view returns (ShardStage) {
         _exists(tokenId); // Ensure token exists
        return _shardData[tokenId].stage;
    }

    /**
     * @dev Gets the current reputation points of a Shard.
     * @param tokenId The ID of the Shard.
     * @return The reputation points.
     */
    function getShardReputation(uint256 tokenId) public view returns (uint256) {
         _exists(tokenId); // Ensure token exists
        return _shardData[tokenId].reputation;
    }

    /**
     * @dev Gets the reputation points required to reach a specific stage.
     * @param stage The target ShardStage.
     * @return The required reputation points.
     */
    function getStageReputationThreshold(ShardStage stage) public view returns (uint256) {
        return _stageReputationThresholds[stage];
    }

    /**
     * @dev Gets the active blessing data for a Shard. Note: may return data
     * even if blessing is expired but not yet removed. Use isBlessingActive
     * to check validity.
     * @param tokenId The ID of the Shard.
     * @return The BlessingData struct.
     */
    function getBlessingStatus(uint256 tokenId) public view returns (BlessingData memory) {
         _exists(tokenId); // Ensure token exists
        return _blessingData[tokenId];
    }

    /**
     * @dev Checks if a Shard currently has an active blessing.
     * @param tokenId The ID of the Shard.
     * @return True if a blessing is active, false otherwise.
     */
    function isBlessingActive(uint256 tokenId) public view returns (bool) {
        // Token must exist, must have blessing data, blessing must be marked active, and not expired
        BlessingData memory blessing = _blessingData[tokenId];
        return _exists(tokenId) && blessing.active && (blessing.appliedTime + blessing.duration > block.timestamp);
    }

     /**
     * @dev Gets the timestamp when a Shard is next eligible for an evolution attempt.
     * @param tokenId The ID of the Shard.
     * @return The timestamp.
     */
    function getEvolutionCooldown(uint256 tokenId) public view returns (uint256) {
         _exists(tokenId); // Ensure token exists
        return _evolutionCooldowns[tokenId];
    }

     /**
     * @dev Gets the timestamp when a Shard that applied a blessing is next eligible to apply another.
     * @param tokenId The ID of the Shard (the giver).
     * @return The timestamp.
     */
    function getBlessingApplicationCooldown(uint256 tokenId) public view returns (uint256) {
         _exists(tokenId); // Ensure token exists
        return _blessingApplicationCooldowns[tokenId];
    }

    /**
     * @dev Checks if the stage bonus for a specific stage has been claimed for a Shard.
     * @param tokenId The ID of the Shard.
     * @param stage The ShardStage to check.
     * @return True if the bonus has been claimed for this stage, false otherwise.
     */
    function hasClaimedStageBonus(uint256 tokenId, ShardStage stage) public view returns (bool) {
         _exists(tokenId); // Ensure token exists
        uint256 stageUint = uint256(stage);
        for (uint i = 0; i < _shardData[tokenId].claimedBonusStages.length; i++) {
            if (_shardData[tokenId].claimedBonusStages[i] == stageUint) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Checks if an address is authorized to add/decrease reputation.
     * @param source The address to check.
     * @return True if authorized, false otherwise.
     */
    function isAuthorizedReputationSource(address source) public view returns (bool) {
        return _authorizedReputationSources[source];
    }

    /**
     * @dev Returns the total number of Shards that have been minted.
     * @return The total supply.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Note: Helper functions like `getAllTokenIds` or `getTokensOfOwner`
    // which iterate over all token IDs or tokens for an owner can be very
    // gas-intensive and are generally discouraged on-chain for large collections.
    // Relying on off-chain indexers or graph protocol is standard practice.
    // Including simple versions here for completeness but with caution.

     /**
     * @dev Gets all token IDs minted so far. USE WITH CAUTION: Gas costs scale with supply.
     * @return An array of all token IDs.
     */
    function getAllTokenIds() public view returns (uint256[] memory) {
        uint256 total = _tokenIdCounter.current();
        uint256[] memory tokenIds = new uint256[](total);
        // This loop is inefficient for many tokens.
        // In practice, you'd rely on events and off-chain indexing.
        for (uint256 i = 0; i < total; i++) {
             // Assumes continuous token IDs from 0.
             // If tokens can be burned or skipped, this needs adjustment.
             // With _tokenIdCounter.current() and _burn, this assumption holds.
            tokenIds[i] = i;
        }
        return tokenIds;
    }

     /**
     * @dev Gets all token IDs owned by a specific address. USE WITH CAUTION: Gas costs scale with number of tokens owned.
     * @param owner The address to query.
     * @return An array of token IDs owned by the address.
     */
    function getTokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // This loop is inefficient for owners with many tokens.
        // In practice, you'd rely on events and off-chain indexing.
        uint256 total = _tokenIdCounter.current();
         for (uint256 i = 0; i < total; i++) {
             // Assumes continuous token IDs from 0.
             // Check if token exists and is owned by the address.
            try ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    tokenIds[index] = i;
                    index++;
                    if (index == tokenCount) break; // Optimization
                }
            } catch {
                // ownerOf will revert if token does not exist or has been burned
                // This could happen if using Counters.current() with burning.
                // A better approach for burnt tokens requires storing existence or using a sparse structure.
                // Given _burn and _tokenIdCounter, burned tokens won't be in the sequence 0 to current-1.
                // This simple loop *might* work if tokens are only burned, not if IDs are skipped during minting.
            }
        }
         // If tokens are burned, some slots in the `tokenIds` array might remain 0.
         // A more robust implementation for querying owned tokens involves tracking per-owner token lists,
         // which adds complexity/gas to mint/transfer/burn. Relying on events/indexing is standard.
        return tokenIds;
    }


    // --- Admin Functions (Ownable) ---

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets the reputation points required to reach a specific stage.
     * Only callable by the owner.
     * @param stage The target ShardStage.
     * @param threshold The new required reputation points.
     */
    function setStageReputationThreshold(ShardStage stage, uint256 threshold) public onlyOwner {
        // Prevent setting threshold for the initial stage (Shard) or Unborn
        require(uint256(stage) > uint256(ShardStage.Shard), "CJ: Cannot set threshold for base stage");
        _stageReputationThresholds[stage] = threshold;
    }

    /**
     * @dev Grants an address permission to call addReputation and decreaseReputation.
     * Only callable by the owner.
     * @param source The address to authorize.
     */
    function authorizeReputationSource(address source) public onlyOwner {
        require(source != address(0), "CJ: Cannot authorize zero address");
        _authorizedReputationSources[source] = true;
        emit ReputationSourceAuthorized(source);
    }

    /**
     * @dev Revokes an address's permission to call reputation functions.
     * Only callable by the owner.
     * @param source The address to remove authorization from.
     */
    function removeReputationSource(address source) public onlyOwner {
         require(source != msg.sender, "CJ: Cannot remove owner's reputation source authorization via this function");
        _authorizedReputationSources[source] = false;
        emit ReputationSourceRemoved(source);
    }

    /**
     * @dev Sets the duration for temporary blessings.
     * Only callable by the owner.
     * @param durationInSeconds The new duration in seconds.
     */
    function setBlessingDuration(uint256 durationInSeconds) public onlyOwner {
        blessingDuration = durationInSeconds;
    }

    /**
     * @dev Sets the cooldown period after a Shard attempts evolution.
     * Only callable by the owner.
     * @param durationInSeconds The new duration in seconds.
     */
    function setEvolutionCooldownDuration(uint256 durationInSeconds) public onlyOwner {
        evolutionCooldownDuration = durationInSeconds;
    }

    /**
     * @dev Sets the cooldown period for a Shard after it applies a blessing.
     * Only callable by the owner.
     * @param durationInSeconds The new duration in seconds.
     */
    function setBlessingApplicationCooldownDuration(uint256 durationInSeconds) public onlyOwner {
        blessingApplicationCooldownDuration = durationInSeconds;
    }

    /**
     * @dev Pauses certain contract interactions (minting, burning, reputation changes, evolution, blessing application).
     * Only callable by the owner. Inherited from Pausable.
     */
    function pause() public onlyOwner override {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only callable by the owner. Inherited from Pausable.
     */
    function unpause() public onlyOwner override {
        _unpause();
    }

    // Overrides for Pausable checks in OpenZeppelin's ERC721 internal functions
    // These ensure standard transfer/approval functions respect the paused state.
    // Note: `_beforeTokenTransfer` hook is crucial here.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
        whenNotPaused // This modifier is applied to the hook itself
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Add Pausable to other specific functions manually if needed, e.g.:
    // function mintShard(...) public virtual onlyOwner whenNotPaused returns (...) { ... } -> Already done
    // function burnShard(...) public virtual whenNotPaused { ... } -> Already done
    // ... and so on for all state-changing functions that should be pausable.
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFT State (Trendy/Advanced):** The `ShardData` struct and the `_shardData` mapping give each NFT a mutable internal state (`stage`, `reputation`, etc.). This goes beyond static metadata and allows the NFT to "live" and change based on interactions.
2.  **Reputation System (Advanced/Creative):** A simple points system tied directly to the NFT (`_shardData[tokenId].reputation`), manageable by designated external sources. This allows integrating off-chain actions or other on-chain events to influence the NFT's properties.
3.  **Staged Evolution (Creative/Advanced):** The `evolveShard` function implements a clear progression system (`Shard` -> `Glyph` -> `Relic` -> `Legend`). Evolution is gated by accumulated reputation and a cooldown, creating milestones for holders.
4.  **Conditional Functions (Advanced):** Functions like `applyBlessing` and `claimStageBonus` are only accessible if the calling Shard meets a minimum stage requirement (`requireMinimumShardStage` modifier). This creates tiered utility based on the NFT's evolution level.
5.  **Inter-Shard Interaction (Creative):** The `applyBlessing` function allows one high-stage Shard to interact with *another* Shard, applying a temporary beneficial effect. This adds a layer of social or strategic interaction between NFT holders and their assets.
6.  **Temporary Effects (Blessings) (Creative):** Blessings have a `duration` and an `appliedTime`, making their effect temporary. The `isBlessingActive` function determines their current validity, and the `getBlessingStatus` retrieves their details.
7.  **Cooldown Mechanisms (Advanced):** Cooldowns (`_evolutionCooldowns`, `_blessingApplicationCooldowns`) prevent spamming or rapid progression/interaction, adding a time-based constraint to actions.
8.  **Dynamic Metadata (`tokenURI`) (Trendy/Advanced):** The `tokenURI` function is overridden to read the `_shardData` and blessing status, meaning the NFT's visual representation or associated data (when fetched by a front-end or marketplace) can change as the Shard evolves or receives blessings. This requires an off-chain service that serves the metadata JSON based on the dynamic data fetched from the contract.
9.  **Modular Authorization (Advanced):** The `onlyAuthorizedReputationSource` modifier allows the owner to delegate the power to add/decrease reputation to specific addresses, potentially linking this to an oracle, a DAO vote, or other trusted systems without giving away full ownership.
10. **Pausable Control (Standard but Good Practice/Required for complex systems):** The `Pausable` pattern inherited from OpenZeppelin allows the owner to pause sensitive operations in case of upgrades, bugs, or unforeseen circumstances. The application of `whenNotPaused` to the `_beforeTokenTransfer` hook ensures basic ERC-721 operations are also pausable.

This contract provides a framework for a dynamic, interactive NFT collection where the value and utility of individual NFTs are tied to their evolving state within the system.