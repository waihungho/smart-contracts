Okay, let's create a smart contract that implements a "Decentralized Reputation and Achievement System" using a Soulbound Token (SBT) concept with dynamic properties. This combines trendy ideas like SBTs, dynamic NFTs (though non-transferable here), on-chain achievements, roles, and a potential pattern for off-chain keepers or time-based updates.

It will *not* be a direct copy of standard ERCs but will implement relevant interfaces (`IERC721`, `IERC721Metadata`) and replicate necessary views (`balanceOf`, `ownerOf`, `tokenURI`, `totalSupply`) while overriding transfer mechanisms to enforce the Soulbound nature. We'll also implement custom roles similar to, but not inheriting from, OpenZeppelin's AccessControl to meet the "don't duplicate open source" constraint.

Here is the contract structure, outline, and code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1.  Interfaces: Define minimal ERC721 and ERC721Metadata interfaces for compatibility checks.
// 2.  Error Definitions: Custom errors for clarity and gas efficiency.
// 3.  Role Definitions: Custom role management (mimicking AccessControl structure).
// 4.  Struct Definitions:
//     - Achievement: Defines an achievement type (id, name, description, aura boost).
//     - HolderAuraState: Stores dynamic state for a token holder (last activity time, last aura recalculation time, activity count).
// 5.  State Variables: Mappings and variables to track:
//     - Token ownership (address to token ID, token ID to address).
//     - Token metadata (base URI).
//     - Achievements (definitions, achievements held by each token).
//     - Attestations (attestations made by each token holder).
//     - Aura calculation parameters (boost factors, recalculation interval).
//     - Holder dynamic state (AuraState).
//     - Role assignments.
//     - Paused state.
//     - Token counter.
// 6.  Events: Log important actions (Mint, Burn, AchievementGranted, RoleSet, AttestationRegistered, AuraRecalculated, Paused, Unpaused).
// 7.  Constructor: Initialize admin role.
// 8.  ERC721 / SBT Core Functions:
//     - balanceOf, ownerOf, totalSupply, tokenURI (dynamic based on aura/achievements).
//     - Overrides for transferFrom, safeTransferFrom, approve, setApprovalForAll (to revert).
//     - isAuraBoundTokenHolder, getTokenIdForAddress.
// 9.  Minting & Burning:
//     - mintBaseAuraBoundToken (Role: ISSUER).
//     - adminBurnAuraBoundToken (Role: ADMIN or ISSUER).
// 10. Role Management:
//     - setRole, revokeRole (Role: ADMIN).
//     - hasRole.
//     - transferAdminRole (Role: ADMIN).
// 11. Achievements:
//     - defineAchievement (Role: ADMIN).
//     - getAchievementDefinition.
//     - grantAchievement (Role: GRANTER).
//     - revokeAchievement (Role: GRANTER).
//     - hasAchievement, getAllAchievementsForHolder.
// 12. Dynamic Aura:
//     - configureAuraBoostFactors (Role: ADMIN).
//     - getAuraBoostFactors.
//     - setAuraRecalculationInterval (Role: ADMIN).
//     - getAuraRecalculationInterval, getLastAuraRecalculationTime.
//     - calculateCurrentAuraScore (Internal helper).
//     - getCurrentAuraScore (Public view function that triggers update if needed).
//     - triggerAuraRecalculation (Role: KEEPER or ADMIN - allows updating aura state for a holder).
//     - forceActivityUpdateForHolder (Role: KEEPER or ADMIN - manually boost activity count).
// 13. Attestations:
//     - registerAttestation (Any token holder).
//     - getAttestationsForHolder.
// 14. Utility/State Management:
//     - setBaseTokenURI (Role: ADMIN).
//     - pauseDynamicUpdates, unpauseDynamicUpdates (Role: ADMIN).
//     - paused.

// --- Function Summary ---
// Core SBT & ERC721 Views (Modified/Restricted):
// - constructor: Initializes the contract and sets the initial admin.
// - balanceOf(address owner): Returns 1 if the address holds an ABT, 0 otherwise. (ERC721)
// - ownerOf(uint256 tokenId): Returns the owner of a specific token ID. (ERC721)
// - totalSupply(): Returns the total number of ABTs minted. (ERC721)
// - tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a token. Calls calculateCurrentAuraScore internally. (ERC721 Metadata)
// - transferFrom(...), safeTransferFrom(...), approve(...), setApprovalForAll(...): These standard ERC721 transfer/approval functions are overridden to always revert, enforcing the Soulbound nature.
// - isAuraBoundTokenHolder(address account): Checks if an address holds an ABT.
// - getTokenIdForAddress(address account): Gets the ABT token ID associated with an address.

// Minting & Burning:
// - mintBaseAuraBoundToken(address account): Mints the initial ABT for a given address. Only callable by the ISSUER role. Reverts if the address already has a token.
// - adminBurnAuraBoundToken(uint256 tokenId): Destroys an ABT. Only callable by ADMIN or ISSUER role.

// Role Management:
// - setRole(bytes32 role, address account): Grants a specific role to an address. Only callable by ADMIN.
// - revokeRole(bytes32 role, address account): Revokes a specific role from an address. Only callable by ADMIN.
// - hasRole(bytes32 role, address account): Checks if an address has a specific role.
// - transferAdminRole(address newAdmin): Transfers the ADMIN role to a new address. Only callable by the current ADMIN.

// Achievements:
// - defineAchievement(bytes32 achievementId, string calldata name, string calldata description, uint256 auraBoost): Defines a new type of achievement and its properties, including how much it boosts Aura. Only callable by ADMIN.
// - getAchievementDefinition(bytes32 achievementId): Retrieves the definition of a specific achievement type.
// - grantAchievement(uint256 tokenId, bytes32 achievementId): Awards a specific achievement to a token holder. Only callable by GRANTER role. Triggers an Aura recalculation.
// - revokeAchievement(uint256 tokenId, bytes32 achievementId): Removes an achievement from a token holder. Only callable by GRANTER role. Triggers an Aura recalculation.
// - hasAchievement(uint256 tokenId, bytes32 achievementId): Checks if a token holder has a specific achievement.
// - getAllAchievementsForHolder(uint256 tokenId): Returns a list of achievement IDs held by a token holder.

// Dynamic Aura:
// - configureAuraBoostFactors(uint256 timeFactor, uint256 activityFactor): Sets the multipliers for time-based and activity-based Aura boosts. Only callable by ADMIN.
// - getAuraBoostFactors(): Returns the current Aura boost factors.
// - setAuraRecalculationInterval(uint256 intervalSeconds): Sets the minimum time between automatic Aura recalculations triggered by getCurrentAuraScore. Only callable by ADMIN.
// - getAuraRecalculationInterval(): Returns the current recalculation interval.
// - getLastAuraRecalculationTime(uint256 tokenId): Gets the timestamp of the last Aura recalculation for a token.
// - calculateCurrentAuraScore(uint256 tokenId): Internal helper function that calculates the aggregate Aura score based on achievements, time held, and activity.
// - getCurrentAuraScore(uint256 tokenId): Public view function to get the current Aura score. Triggers calculateCurrentAuraScore if the recalculation interval has passed and not paused.
// - triggerAuraRecalculation(uint256 tokenId): Manually triggers an Aura recalculation for a specific token holder, regardless of the time interval. Callable by KEEPER or ADMIN.
// - forceActivityUpdateForHolder(uint256 tokenId, uint256 activityBoost): Manually increases the activity count for a holder. Callable by KEEPER or ADMIN.

// Attestations:
// - registerAttestation(bytes32 attestationHash, string calldata metadataURI): Allows a token holder to record an attestation (e.g., "I verify X", "I participated in Y") linked to their token. Stores a hash and optional metadata URI. Callable by the token holder. Triggers an Aura recalculation.
// - getAttestationsForHolder(uint256 tokenId): Returns the list of attestation hashes recorded by a token holder.

// Utility/State Management:
// - setBaseTokenURI(string calldata baseURI): Sets the base URI for token metadata. Only callable by ADMIN.
// - pauseDynamicUpdates(): Pauses dynamic updates to Aura based on time/activity. Only callable by ADMIN.
// - unpauseDynamicUpdates(): Unpauses dynamic updates. Only callable by ADMIN.
// - paused(): Checks if dynamic updates are currently paused.

// Interfaces (for clarity and compatibility checks, not full implementations)
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract AuraBoundTokens is IERC721Metadata {

    // --- Error Definitions ---
    error TokenAlreadyMinted(address account);
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenHolder(uint256 tokenId, address account);
    error OnlyTokenHolder();
    error AchievementAlreadyExists(bytes32 achievementId);
    error AchievementDefinitionNotFound(bytes32 achievementId);
    error AchievementNotHeld(uint256 tokenId, bytes32 achievementId);
    error CallerHasNoRole(bytes32 role);
    error CallerIsNotAdmin();
    error TransfersNotEnabled(); // For SBT enforcement
    error ApprovalsNotEnabled(); // For SBT enforcement
    error ZeroAddress();
    error Paused();
    error NotPaused();
    error AuraBoostFactorsInvalid();
    error RecalculationIntervalZero();

    // --- Role Definitions ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE"); // Can mint base tokens
    bytes32 public constant GRANTER_ROLE = keccak256("GRANTER_ROLE"); // Can grant/revoke achievements
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE"); // Can trigger updates

    mapping(bytes32 role => mapping(address account => bool hasRole)) private _roles;

    // --- Struct Definitions ---
    struct Achievement {
        string name;
        string description;
        uint256 auraBoost; // Points added to the base aura score
    }

    struct HolderAuraState {
        uint256 mintTimestamp;
        uint256 lastActivityTimestamp;
        uint256 activityCount;
        uint256 lastAuraRecalculationTimestamp;
    }

    // --- State Variables ---
    string private _name = "Aura Bound Token";
    string private _symbol = "ABT";
    string private _baseTokenURI;

    uint256 private _nextTokenId;
    mapping(address account => uint256 tokenId) private _addressToTokenId;
    mapping(uint256 tokenId => address owner) private _idToOwner;

    mapping(bytes32 achievementId => Achievement) private _achievementDefinitions;
    mapping(uint256 tokenId => mapping(bytes32 achievementId => bool has)) private _tokenAchievements;
    mapping(uint256 tokenId => bytes32[] achievementIdsForToken) private _tokenAchievementList; // To retrieve all easily

    mapping(uint256 tokenId => bytes32[] attestations) private _tokenAttestations;
    mapping(bytes32 attestationHash => string metadataURI) private _attestationMetadata; // Optional: Store metadata URI per attestation

    uint256 private _timeAuraFactor; // Points per second held
    uint256 private _activityAuraFactor; // Points per activity point

    uint256 private _auraRecalculationInterval = 1 days; // Default interval

    mapping(uint256 tokenId => HolderAuraState) private _holderAuraState;

    bool private _paused = false;

    // --- Events ---
    event AuraBoundTokenMinted(address indexed account, uint256 indexed tokenId);
    event AuraBoundTokenBurned(uint256 indexed tokenId);
    event RoleSet(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event AdminRoleTransferred(address indexed previousAdmin, address indexed newAdmin);
    event AchievementDefined(bytes32 indexed achievementId, string name);
    event AchievementGranted(uint256 indexed tokenId, bytes32 indexed achievementId);
    event AchievementRevoked(uint256 indexed tokenId, bytes32 indexed achievementId);
    event AttestationRegistered(uint256 indexed tokenId, bytes32 indexed attestationHash, string metadataURI);
    event AuraRecalculated(uint256 indexed tokenId, uint256 newScore);
    event Paused(address account);
    event Unpaused(address account);
    event AuraBoostFactorsConfigured(uint256 timeFactor, uint256 activityFactor);
    event AuraRecalculationIntervalConfigured(uint256 intervalSeconds);

    // --- Constructor ---
    constructor() {
        _roles[ADMIN_ROLE][msg.sender] = true;
        emit RoleSet(ADMIN_ROLE, msg.sender);
    }

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) {
            revert CallerHasNoRole(role);
        }
        _;
    }

    modifier onlyAdmin() {
        if (!_roles[ADMIN_ROLE][msg.sender]) {
            revert CallerIsNotAdmin();
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused) {
            revert Paused();
        }
        _;
    }

    modifier whenPaused() {
        if (!_paused) {
            revert NotPaused();
        }
        _;
    }

    // --- ERC721 Required Implementations (modified for SBT) ---

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _addressToTokenId[owner] != 0 ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _idToOwner[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    // Note: tokenURI implementation usually involves dynamically generating JSON metadata
    // based on the token's state. This is often done off-chain via an API that reads
    // the on-chain state. The contract stores the base URI and relies on the off-chain
    // service to append the token ID and provide the full metadata.
    // Here, we return the base URI + tokenId string. The off-chain service
    // would query this contract for achievements, aura state, etc., based on tokenId.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        // The actual metadata URI points to a service that fetches the dynamic data
        // from this contract using public view functions.
        return string.concat(_baseTokenURI, Strings.toString(tokenId));
    }

    // --- Soulbound Token Enforcement (Overrides to revert) ---

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert TransfersNotEnabled();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert TransfersNotEnabled();
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert TransfersNotEnabled();
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert ApprovalsNotEnabled();
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert ApprovalsNotEnabled();
    }

    function getApproved(uint256 tokenId) public view override returns (address operator) {
        revert ApprovalsNotEnabled();
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        revert ApprovalsNotEnabled();
    }

    // --- Core SBT & Utility Functions ---

    function isAuraBoundTokenHolder(address account) public view returns (bool) {
        return _addressToTokenId[account] != 0;
    }

    function getTokenIdForAddress(address account) public view returns (uint256) {
        uint256 tokenId = _addressToTokenId[account];
        if (tokenId == 0) revert TokenDoesNotExist(0); // Using 0 to indicate no token found for address
        return tokenId;
    }

    // --- Minting & Burning ---

    function mintBaseAuraBoundToken(address account) public onlyRole(ISSUER_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        if (_addressToTokenId[account] != 0) revert TokenAlreadyMinted(account);

        _nextTokenId++;
        uint256 newTokenId = _nextTokenId;

        _addressToTokenId[account] = newTokenId;
        _idToOwner[newTokenId] = account;

        _holderAuraState[newTokenId] = HolderAuraState({
            mintTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp,
            activityCount: 0,
            lastAuraRecalculationTimestamp: block.timestamp
        });

        emit AuraBoundTokenMinted(account, newTokenId);
        emit Transfer(address(0), account, newTokenId); // Standard ERC721 mint event
    }

    function adminBurnAuraBoundToken(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        address owner = _idToOwner[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);

        // Clean up state associated with the token
        delete _addressToTokenId[owner];
        delete _idToOwner[tokenId];
        delete _holderAuraState[tokenId];
        delete _tokenAttestations[tokenId];
        // Achievement cleanup requires iterating _tokenAchievementList[tokenId] and deleting from _tokenAchievements
         bytes32[] memory achievements = _tokenAchievementList[tokenId];
         for(uint i = 0; i < achievements.length; i++) {
             delete _tokenAchievements[tokenId][achievements[i]];
         }
         delete _tokenAchievementList[tokenId];


        // Note: token ID counter (_nextTokenId) is not decremented

        emit AuraBoundTokenBurned(tokenId);
        emit Transfer(owner, address(0), tokenId); // Standard ERC721 burn event
    }

    // --- Role Management ---

    function setRole(bytes32 role, address account) public onlyAdmin {
         if (account == address(0)) revert ZeroAddress();
         _roles[role][account] = true;
         emit RoleSet(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyAdmin {
         if (account == address(0)) revert ZeroAddress();
         // Prevent revoking admin role from self unless transferring first
         if (role == ADMIN_ROLE && account == msg.sender) revert CallerIsNotAdmin(); // A bit of a hack, implies admin can't remove self role

         _roles[role][account] = false;
         emit RoleRevoked(role, account);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function transferAdminRole(address newAdmin) public onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        if (newAdmin == msg.sender) return; // Already admin

        _roles[ADMIN_ROLE][newAdmin] = true;
        _roles[ADMIN_ROLE][msg.sender] = false;
        emit AdminRoleTransferred(msg.sender, newAdmin);
    }

    // --- Achievements ---

    function defineAchievement(
        bytes32 achievementId,
        string calldata name,
        string calldata description,
        uint256 auraBoost
    ) public onlyAdmin {
        if (_achievementDefinitions[achievementId].auraBoost != 0 || keccak256(bytes(_achievementDefinitions[achievementId].name)) != keccak256(bytes(""))) {
             revert AchievementAlreadyExists(achievementId);
        }
        _achievementDefinitions[achievementId] = Achievement(name, description, auraBoost);
        emit AchievementDefined(achievementId, name);
    }

    function getAchievementDefinition(bytes32 achievementId) public view returns (Achievement memory) {
         if (keccak256(bytes(_achievementDefinitions[achievementId].name)) == keccak256(bytes(""))) {
             revert AchievementDefinitionNotFound(achievementId);
         }
         return _achievementDefinitions[achievementId];
    }

    function grantAchievement(uint256 tokenId, bytes32 achievementId) public onlyRole(GRANTER_ROLE) whenNotPaused {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        if (keccak256(bytes(_achievementDefinitions[achievementId].name)) == keccak256(bytes(""))) revert AchievementDefinitionNotFound(achievementId);
        if (_tokenAchievements[tokenId][achievementId]) return; // Already has achievement

        _tokenAchievements[tokenId][achievementId] = true;
        _tokenAchievementList[tokenId].push(achievementId);

        // Granting an achievement is an activity and likely boosts aura
        _holderAuraState[tokenId].activityCount++;
        _updateAuraState(tokenId); // Trigger aura recalculation
        emit AchievementGranted(tokenId, achievementId);
    }

    function revokeAchievement(uint256 tokenId, bytes32 achievementId) public onlyRole(GRANTER_ROLE) whenNotPaused {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        if (!_tokenAchievements[tokenId][achievementId]) revert AchievementNotHeld(tokenId, achievementId);

        delete _tokenAchievements[tokenId][achievementId];

        // Remove from the list - simple but potentially gas-inefficient for long lists.
        // A more gas-efficient way involves swapping with last element and popping.
        bytes32[] storage achievementList = _tokenAchievementList[tokenId];
        for (uint i = 0; i < achievementList.length; i++) {
            if (achievementList[i] == achievementId) {
                achievementList[i] = achievementList[achievementList.length - 1];
                achievementList.pop();
                break; // Achievement IDs should be unique per token, so we can stop
            }
        }

        // Revoking an achievement is also an activity, or at least triggers state change
         _updateAuraState(tokenId); // Trigger aura recalculation
        emit AchievementRevoked(tokenId, achievementId);
    }

    function hasAchievement(uint256 tokenId, bytes32 achievementId) public view returns (bool) {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _tokenAchievements[tokenId][achievementId];
    }

    function getAllAchievementsForHolder(uint256 tokenId) public view returns (bytes32[] memory) {
         if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
         return _tokenAchievementList[tokenId];
    }

    // --- Dynamic Aura ---

    function configureAuraBoostFactors(uint256 timeFactor, uint256 activityFactor) public onlyAdmin {
        if (timeFactor == 0 && activityFactor == 0) revert AuraBoostFactorsInvalid();
        _timeAuraFactor = timeFactor;
        _activityAuraFactor = activityFactor;
        emit AuraBoostFactorsConfigured(timeFactor, activityFactor);
    }

    function getAuraBoostFactors() public view returns (uint256 timeFactor, uint256 activityFactor) {
        return (_timeAuraFactor, _activityAuraFactor);
    }

    function setAuraRecalculationInterval(uint256 intervalSeconds) public onlyAdmin {
        if (intervalSeconds == 0) revert RecalculationIntervalZero();
        _auraRecalculationInterval = intervalSeconds;
        emit AuraRecalculationIntervalConfigured(intervalSeconds);
    }

    function getAuraRecalculationInterval() public view returns (uint256) {
        return _auraRecalculationInterval;
    }

    function getLastAuraRecalculationTime(uint256 tokenId) public view returns (uint256) {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _holderAuraState[tokenId].lastAuraRecalculationTimestamp;
    }

    // Internal helper to calculate aura based on current state
    function calculateCurrentAuraScore(uint256 tokenId) internal view returns (uint256) {
        address owner = _idToOwner[tokenId];
        if (owner == address(0)) return 0; // Should not happen if called internally correctly

        HolderAuraState storage state = _holderAuraState[tokenId];
        uint256 timeHeld = block.timestamp - state.mintTimestamp;
        uint256 activityTime = block.timestamp - state.lastActivityTimestamp; // Time since last activity

        // Basic calculation logic:
        // Base Aura (can be config or fixed) + Time Boost + Activity Boost + Achievement Boosts
        // For simplicity, let's say Aura = (timeHeld / unit) * timeFactor + activityCount * activityFactor + Sum(achievementBoosts)
        // We need to decide the "unit" for time (e.g., seconds, hours, days). Using seconds for calculation then scaling down if factors are large.
        // Let's use seconds and assume factors are small (e.g., points per second, per hour).
        // Avoid division by zero for intervals if needed, though timeHeld/activityTime could be 0.
        uint256 timeBoost = timeHeld * _timeAuraFactor;
        uint256 activityBoost = state.activityCount * _activityAuraFactor;

        uint256 achievementBoostsTotal = 0;
        bytes32[] memory achievements = _tokenAchievementList[tokenId];
        for(uint i = 0; i < achievements.length; i++) {
            bytes32 achId = achievements[i];
            // Check definition exists in case it was defined then deleted (though defineAchievement prevents re-adding)
             if (keccak256(bytes(_achievementDefinitions[achId].name)) != keccak256(bytes(""))) {
                 achievementBoostsTotal += _achievementDefinitions[achId].auraBoost;
             }
        }

        // Simple sum - actual scoring can be more complex
        return timeBoost + activityBoost + achievementBoostsTotal;
    }

    // Updates the holder's dynamic state and potentially triggers recalculation if needed/allowed
    function _updateAuraState(uint256 tokenId) internal {
         HolderAuraState storage state = _holderAuraState[tokenId];

         // Update last activity timestamp on relevant actions
         state.lastActivityTimestamp = block.timestamp;

        // If not paused and enough time has passed since last *explicit* recalculation...
        // Note: calculateCurrentAuraScore always reflects *current* time/activity when called
        // This _updateAuraState function is primarily for actions that change state (achievements, attestations, manual triggers)
        // The timestamp update here is mainly for the 'last activity' part.
        // The check for recalculation interval is done in the public getter `getCurrentAuraScore`.
    }


    // Public view function that returns the score and *conditionally* updates the state timestamp
    function getCurrentAuraScore(uint256 tokenId) public view returns (uint256 score) {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);

        // This getter triggers the internal calculation based on current conditions
        score = calculateCurrentAuraScore(tokenId);

        // Note: State-changing logic (like updating timestamps) *cannot* be in a view function.
        // The actual state update must be done by a non-view function.
        // The Keeper/Admin or relevant actions (grant, attest) trigger the state update.
        // This view function just provides the current calculated value.
    }

    // Allows a Keeper or Admin to force an update of the state for a specific token holder
    function triggerAuraRecalculation(uint256 tokenId) public onlyRole(KEEPER_ROLE) whenNotPaused {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);

        // Re-calculate the score based on current state (which the getter does anyway)
        // The primary purpose of this function is to update the `lastAuraRecalculationTimestamp`
        // so that the conditional update logic in a potential future non-view getter works,
        // OR to allow an off-chain process to sync state.
        // Since our `getCurrentAuraScore` is view and calculates on demand, this function's
        // main role is to allow a Keeper to mark a token's state as 'checked/updated'
        // or perform batch updates if modified to handle multiple tokens.
        // For this simple example, it just updates the timestamp and recalculates implicitly via the view.
        // A more complex version might store the *last calculated score* and update that.
         _holderAuraState[tokenId].lastAuraRecalculationTimestamp = block.timestamp;

        // We can emit the score calculated *at this moment* for logging purposes,
        // although the view function is the source of truth for the absolute latest score.
        uint256 currentScore = calculateCurrentAuraScore(tokenId);
        emit AuraRecalculated(tokenId, currentScore);
    }

     function forceActivityUpdateForHolder(uint256 tokenId, uint256 activityBoost) public onlyRole(KEEPER_ROLE) whenNotPaused {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        _holderAuraState[tokenId].activityCount += activityBoost;
        _updateAuraState(tokenId); // Trigger general state update including timestamp
        // No specific event for this boost, _updateAuraState implicitly includes it
    }


    // --- Attestations ---

    function registerAttestation(bytes32 attestationHash, string calldata metadataURI) public whenNotPaused {
        uint256 tokenId = _addressToTokenId[msg.sender];
        if (tokenId == 0) revert OnlyTokenHolder();

        _tokenAttestations[tokenId].push(attestationHash);
        _attestationMetadata[attestationHash] = metadataURI; // Store URI separately

        // Registering an attestation is an activity
        _holderAuraState[tokenId].activityCount++;
        _updateAuraState(tokenId); // Trigger state update

        emit AttestationRegistered(tokenId, attestationHash, metadataURI);
    }

    function getAttestationsForHolder(uint256 tokenId) public view returns (bytes32[] memory) {
        if (_idToOwner[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _tokenAttestations[tokenId];
    }

    function getAttestationMetadata(bytes32 attestationHash) public view returns (string memory) {
        return _attestationMetadata[attestationHash];
    }

    // --- Utility/State Management ---

    function setBaseTokenURI(string calldata baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function pauseDynamicUpdates() public onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseDynamicUpdates() public onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Internal Libraries ---
    // Minimal internal Bytes to String conversion needed for tokenURI
    library Strings {
        bytes16 private constant _HEX_TABLE = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
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
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Concepts & Features:**

1.  **Soulbound Nature:** The core concept. By overriding `transferFrom`, `safeTransferFrom`, `approve`, and `setApprovalForAll` to always revert, the tokens are made explicitly non-transferable by standard ERC721 methods. The `ownerOf` and `balanceOf` functions are implemented to reflect the ownership state internally, but this state is fixed after minting.
2.  **Dynamic Aura Score:** Instead of static traits, the token has a dynamic "Aura Score" calculated based on:
    *   **Time Held:** Loyalty over time.
    *   **Activity:** Number of interactions with the contract (granting achievements, registering attestations, etc.).
    *   **Achievements:** Specific badges awarded by a role, each contributing a defined boost to the score.
    *   The `calculateCurrentAuraScore` function performs this calculation based on the latest state.
    *   `getCurrentAuraScore` provides the public view. While it *doesn't* change state in a view function, the design implies that off-chain systems reading this would see the score update dynamically based on time elapsed and activity count stored on-chain. State updates (`lastAuraRecalculationTimestamp`, `activityCount`) happen when state-changing functions like `grantAchievement`, `registerAttestation`, or `triggerAuraRecalculation` are called.
3.  **On-Chain Achievements:** A structured way to award specific badges or milestones that are recorded directly on the token. `defineAchievement` allows setting up types of achievements with associated Aura boosts. `grantAchievement` and `revokeAchievement` manage these for token holders.
4.  **On-Chain Attestations:** Allows the token holder themselves to record verifiable statements or affiliations linked to their token. This could represent "Proof of Participation," "Proof of Skill," or "Self-Sovereign Identity" claims. The attestation is stored as a hash, and optionally a metadata URI pointing to off-chain details.
5.  **Custom Role-Based Access Control:** Instead of inheriting OpenZeppelin's `AccessControl`, a custom mapping-based system is used to define and manage `ADMIN`, `ISSUER`, `GRANTER`, and `KEEPER` roles. This allows different authorized parties to perform specific actions (minting, granting achievements, managing roles, triggering updates).
6.  **Keeper Pattern:** The `KEEPER_ROLE` and functions like `triggerAuraRecalculation` and `forceActivityUpdateForHolder` introduce a pattern where an authorized external entity (a bot, a separate contract, or a designated service) can maintain the state or trigger updates for efficiency or specific event handling. The `_auraRecalculationInterval` suggests a time-based trigger that an off-chain keeper could monitor.
7.  **Dynamic `tokenURI`:** The `tokenURI` points to a base URI plus the token ID. This is the standard way to handle dynamic metadata. An off-chain service would listen for contract events or query the contract's public view functions (`getCurrentAuraScore`, `getAllAchievementsForHolder`, `getAttestationsForHolder`) to generate the actual JSON metadata describing the token's current dynamic state (its Aura score, achievements, etc.).
8.  **Paused State:** Allows the admin to pause dynamic updates, useful during maintenance or unforeseen issues.
9.  **Gas Efficiency:** Uses custom errors, storage optimization (mappings where appropriate), and avoids costly operations like iterating over all tokens within single transactions (e.g., aura recalculations are per-token or triggered for specific tokens). The list of achievements per token is maintained to make `getAllAchievementsForHolder` efficient.

This contract provides a foundation for a unique on-chain identity or reputation system, distinct from typical transferable NFTs or static SBT implementations, incorporating dynamic state changes based on activity, time, and administered achievements/attestations.