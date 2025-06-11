Okay, here is a Solidity smart contract incorporating several interesting and advanced concepts. The theme is a "Reputation-Bound Dynamic Genesis Stone" system – a blend of Soulbound Tokens (SBT), a dynamic on-chain state based on activity and "reputation," a yield-like mechanism ("Essence"), and conditional feature unlocking.

It aims to be distinct from standard ERC-721/ERC-20 implementations by focusing on non-transferability (initially), state changes triggered by user actions, and integrated game-like mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Required for ERC721 inheritance safety
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // Required for ERC721 inheritance safety

/**
 * @title GenesisStones
 * @dev A Reputation-Bound Dynamic Genesis Stone system.
 *
 * This contract implements a novel non-transferable token (SBT-like) called a Genesis Stone.
 * Each Stone is bound to a user address and cannot be traded (unless explicitly unbound via a mechanism).
 * Stones are dynamic, accumulating 'Essence' over time and evolving based on a 'Reputation' score.
 * Users interact with the system and other users to earn Reputation and spend Essence to unlock
 * features or perform 'Rites of Passage'.
 *
 * Outline:
 * 1. Core Structure: Soulbound-like token (ERC721 base, but transfer disabled).
 * 2. Dynamic State: Each stone has evolving Reputation, Essence, and status flags.
 * 3. Essence Yield: Stones passively generate 'Essence' token (virtual within this contract).
 * 4. Reputation System: Earned via attestation from other stone owners or other actions.
 * 5. Conditional Features: Status flags unlock based on Reputation, Essence spent, or Rites.
 * 6. Interaction Layer: Simple 'Whispers' and 'Delegation' features.
 * 7. Admin Controls: Parameter setting and initial minting.
 * 8. Rites of Passage: Mechanism to burn Essence and potentially Reputation to unlock higher tiers/features.
 */

/**
 * @dev Function Summary:
 *
 * Admin/Core Functions:
 * - constructor: Initializes contract with owner and initial parameters.
 * - mintStone: Owner mints a new Genesis Stone for an address. (1 stone per address max)
 * - setEssenceRatePerSecond: Owner sets the rate at which essence is generated.
 * - setAttestationParams: Owner sets reputation gain/cost for attestation.
 * - setRiteCost: Owner sets the essence cost for a specific Rite of Passage.
 * - setLevelThresholds: Owner sets the reputation thresholds for different stone levels.
 * - setFeatureCost: Owner sets the essence cost to unlock a specific feature flag.
 * - getStoneCount: Returns the total number of stones minted.
 *
 * User Actions (Requires Owning a Stone):
 * - claimEssence: Claims accumulated essence for the caller's stone.
 * - attestReputation: Attests to another stone owner's reputation (costs attester rep, gives target rep).
 * - performRiteOfPassage: Burns essence to potentially increase level/unlock features based on current rep/level.
 * - sendWhisper: Attaches a small message (whisper) to the caller's stone.
 * - redeemEssenceForFeature: Spends essence to unlock a specific status flag/feature on the stone.
 * - delegatePower: Delegates certain rights (like attestation power or future voting) to another address.
 * - undelegatePower: Removes delegation.
 * - checkFeatureUnlocked: Checks if a specific feature flag is set for the caller's stone.
 *
 * View Functions:
 * - getStone: Retrieves all details for a specific stone ID.
 * - getStoneByOwner: Retrieves the stone ID owned by a given address.
 * - getPendingEssence: Calculates and returns the pending essence for a stone ID.
 * - getStoneLevel: Calculates and returns the current level of a stone ID based on its reputation.
 * - getLastWhisper: Retrieves the last whisper associated with a stone ID.
 * - getDelegatedAddress: Gets the address currently delegated for a stone ID.
 * - getStoneStatusFlags: Gets the raw status flags for a stone ID.
 *
 * ERC721 Compliance (Mostly Reverted):
 * - ownerOf: Returns owner of a stone ID (reverts if non-existent).
 * - balanceOf: Returns 1 if address owns a stone, 0 otherwise.
 * - transferFrom, safeTransferFrom, approve, setApprovalForAll: All revert as stones are non-transferable.
 * - tokenURI: Returns a metadata URI for a stone ID (can be dynamic based on state).
 * - supportsInterface: Indicates support for ERC165 and ERC721 interfaces.
 */

contract GenesisStones is Ownable, ERC165, IERC721, IERC721Metadata, IERC721Receiver {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Data Structures ---

    // Packed struct for gas efficiency
    struct Stone {
        address owner;
        uint256 tokenId; // Store ID for easy lookup within struct
        uint48 mintTimestamp;
        uint48 lastEssenceClaimTimestamp;
        uint16 reputation; // Max rep 65535
        uint256 essence;
        uint32 statusFlags; // Packed boolean flags for features
        address delegatedTo;
        string lastWhisper; // Simple state variable for last message
    }

    // Mapping stone ID to stone data
    mapping(uint256 => Stone) private _stones;
    // Mapping owner address to stone ID (ensures 1 stone per owner)
    mapping(address => uint256) private _ownerToTokenId;
    // Mapping stone ID to owner address (standard ERC721 requires this)
    mapping(uint256 => address) private _tokenToOwner; // Redundant storage but necessary for ERC721

    // --- Configuration & Constants ---

    uint256 public essenceRatePerSecond = 100; // Essence units per second
    uint16 public attestationReputationGain = 50; // Reputation gain for the attested
    uint16 public attestationReputationCost = 10; // Reputation cost for the attester
    uint16 public constant MAX_REPUTATION = type(uint16).max; // Maximum possible reputation

    // Rites of Passage Costs & Effects (Example)
    mapping(uint8 => uint256) public riteEssenceCost; // level => cost
    mapping(uint8 => uint16) public riteReputationCost; // level => cost (optional)

    // Reputation Thresholds for Levels (Example: Level 0: 0-99, Level 1: 100-499, Level 2: 500+)
    uint16[] public levelReputationThresholds; // Sorted list of min rep for each level beyond 0

    // Status Flags / Features (Example using bitmasks)
    uint32 public constant STATUS_UNLOCKED_FEATURE_A = 1 << 0; // 0x01
    uint32 public constant STATUS_UNLOCKED_FEATURE_B = 1 << 1; // 0x02
    uint32 public constant STATUS_UNLOCKED_FEATURE_C = 1 << 2; // 0x04
    uint32 public constant STATUS_UNLOCKED_TRANSFER_UNBIND = 1 << 3; // 0x08 - Example of unbinding
    // Add more flags as needed up to 32 total

    mapping(uint32 => uint256) public featureEssenceCost; // statusFlag => cost

    // --- Events ---

    event StoneMinted(address indexed owner, uint256 indexed tokenId, uint48 timestamp);
    event EssenceClaimed(uint256 indexed tokenId, uint256 amount, uint48 timestamp);
    event ReputationAttested(uint256 indexed attesterTokenId, uint256 indexed targetTokenId, int16 attesterDelta, uint16 targetGain, uint48 timestamp);
    event RitePerformed(uint256 indexed tokenId, uint8 indexed levelBefore, uint8 indexed levelAfter, uint256 essenceSpent, uint48 timestamp);
    event WhisperSent(uint256 indexed tokenId, string message, uint48 timestamp);
    event FeatureUnlocked(uint256 indexed tokenId, uint32 indexed featureFlag, uint256 essenceSpent, uint48 timestamp);
    event DelegationUpdated(uint256 indexed tokenId, address indexed oldDelegate, address indexed newDelegate, uint48 timestamp);

    // ERC721 events (required by interface, but functionality blocked)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Errors ---

    error InvalidTokenId(uint256 tokenId);
    error StoneNotOwnedByUser(uint256 tokenId, address user);
    error AlreadyOwnsStone(address user);
    error InsufficientEssence(uint256 required, uint256 available);
    error MaxReputationReached(uint256 tokenId);
    error CannotAttestYourself();
    error InsufficientReputationForAttestation(uint16 required, uint16 available);
    error FeatureAlreadyUnlocked(uint32 featureFlag);
    error FeatureNotUnlocked(uint32 featureFlag);
    error CannotTransferSBT();
    error InvalidRiteLevel(uint8 level);
    error CannotPerformRiteAtCurrentLevel(uint8 currentLevel, uint8 targetLevel);


    // --- Constructor ---

    constructor(uint16[] memory _levelThresholds) Ownable(msg.sender) {
        // Set initial configuration (can be updated by owner later)
        // Example levels: {100, 500, 1000} -> Level 0: 0-99, Lvl 1: 100-499, Lvl 2: 500-999, Lvl 3: 1000+
        levelReputationThresholds = _levelThresholds;

        // Set example costs for Rites and Features
        riteEssenceCost[1] = 1e18; // Cost for Rite to level 1
        riteEssenceCost[2] = 5e18; // Cost for Rite to level 2
        // Add more levels...

        featureEssenceCost[STATUS_UNLOCKED_FEATURE_A] = 0.5e18;
        featureEssenceCost[STATUS_UNLOCKED_FEATURE_B] = 2e18;
        featureEssenceCost[STATUS_UNLOCKED_TRANSFER_UNBIND] = 10e18; // High cost to unbind
    }

    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId(bytes4(0x150b7a02)) // ERC721Receiver interfaceId
            || super.supportsInterface(interfaceId);
    }

    // --- Admin Functions ---

    /**
     * @dev Mints a new Genesis Stone for a recipient. Only callable by the owner.
     * Prevents minting if the address already owns a stone.
     * @param recipient The address to mint the stone for.
     */
    function mintStone(address recipient) external onlyOwner {
        require(recipient != address(0), "Mint to zero address");
        if (_ownerToTokenId[recipient] != 0) {
             revert AlreadyOwnsStone(recipient);
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        uint48 currentTimestamp = uint48(block.timestamp);

        _tokenToOwner[newTokenId] = recipient; // Required for ERC721
        _ownerToTokenId[recipient] = newTokenId;

        _stones[newTokenId] = Stone({
            owner: recipient,
            tokenId: newTokenId,
            mintTimestamp: currentTimestamp,
            lastEssenceClaimTimestamp: currentTimestamp,
            reputation: 0,
            essence: 0,
            statusFlags: 0,
            delegatedTo: address(0),
            lastWhisper: ""
        });

        emit StoneMinted(recipient, newTokenId, currentTimestamp);
        emit Transfer(address(0), recipient, newTokenId); // ERC721 event
    }

    /**
     * @dev Sets the rate at which essence is generated per second. Only callable by the owner.
     * @param rate The new essence rate.
     */
    function setEssenceRatePerSecond(uint256 rate) external onlyOwner {
        essenceRatePerSecond = rate;
    }

    /**
     * @dev Sets the reputation gain for the attested and cost for the attester. Only callable by the owner.
     * @param gain The amount of reputation gained by the attested.
     * @param cost The amount of reputation lost by the attester.
     */
    function setAttestationParams(uint16 gain, uint16 cost) external onlyOwner {
        attestationReputationGain = gain;
        attestationReputationCost = cost;
    }

    /**
     * @dev Sets the essence cost for a specific Rite of Passage level. Only callable by the owner.
     * Requires the level to be achievable (within bounds of level thresholds).
     * @param level The level the rite is for (e.g., 1 for Rite to Level 1).
     * @param cost The required essence cost.
     * @param repCost Optional reputation cost (0 if none).
     */
    function setRiteCost(uint8 level, uint256 cost, uint16 repCost) external onlyOwner {
        // Validate level against defined thresholds + 1 (for the max level)
        if (level == 0 || level > levelReputationThresholds.length + 1) {
             revert InvalidRiteLevel(level);
        }
        riteEssenceCost[level] = cost;
        riteReputationCost[level] = repCost;
    }

     /**
     * @dev Sets the reputation thresholds for stone levels. Only callable by the owner.
     * Must be sorted in ascending order.
     * @param _levelThresholds Sorted array of minimum reputation for levels 1 onwards.
     */
    function setLevelThresholds(uint16[] memory _levelThresholds) external onlyOwner {
        // Basic check: Ensure thresholds are sorted
        for (uint i = 0; i < _levelThresholds.length; i++) {
            if (i > 0 && _levelThresholds[i] < _levelThresholds[i-1]) {
                 revert("Thresholds must be sorted ascending");
            }
        }
        levelReputationThresholds = _levelThresholds;
    }

    /**
     * @dev Sets the essence cost to unlock a specific feature flag. Only callable by the owner.
     * @param featureFlag The bitmask for the feature (e.g., STATUS_UNLOCKED_FEATURE_A).
     * @param cost The required essence cost.
     */
    function setFeatureCost(uint32 featureFlag, uint256 cost) external onlyOwner {
        // Basic validation: check if flag is a single bit
        require(featureFlag != 0 && (featureFlag & (featureFlag - 1)) == 0, "Feature flag must be a single bit");
        featureEssenceCost[featureFlag] = cost;
    }


    // --- User Actions ---

    /**
     * @dev Claims the accumulated essence for the caller's stone.
     * Calculates essence based on time since last claim or mint.
     */
    function claimEssence() external {
        uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender); // 0 indicates no stone found
        }

        Stone storage stone = _stones[tokenId];
        uint256 pending = calculatePendingEssence(tokenId);

        if (pending > 0) {
            stone.essence += pending;
            stone.lastEssenceClaimTimestamp = uint48(block.timestamp);
            emit EssenceClaimed(tokenId, pending, uint48(block.timestamp));
        }
    }

    /**
     * @dev Allows a stone owner to attest to the reputation of another stone owner.
     * Decreases the attester's reputation and increases the target's reputation.
     * Requires the attester to have sufficient reputation to attest.
     * @param targetAddress The address of the stone owner to attest for.
     */
    function attestReputation(address targetAddress) external {
        uint256 attesterTokenId = _ownerToTokenId[msg.sender];
        if (attesterTokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }
        uint256 targetTokenId = _ownerToTokenId[targetAddress];
        if (targetTokenId == 0) {
             revert InvalidTokenId(0); // Target has no stone
        }
        if (attesterTokenId == targetTokenId) {
             revert CannotAttestYourself();
        }

        Stone storage attesterStone = _stones[attesterTokenId];
        Stone storage targetStone = _stones[targetTokenId];

        // Ensure attester has minimum reputation to attest
        if (attesterStone.reputation < attestationReputationCost) {
             revert InsufficientReputationForAttestation(attestationReputationCost, attesterStone.reputation);
        }

        // Decrease attester reputation (ensure no underflow)
        int16 attesterRepDelta = 0;
        if (attesterStone.reputation >= attestationReputationCost) {
             attesterStone.reputation -= attestationReputationCost;
             attesterRepDelta = -int16(attestationReputationCost);
        }


        // Increase target reputation (cap at MAX_REPUTATION)
        uint16 targetGain = attestationReputationGain;
        if (targetStone.reputation > MAX_REPUTATION - targetGain) {
            targetGain = MAX_REPUTATION - targetStone.reputation;
            targetStone.reputation = MAX_REPUTATION;
        } else {
            targetStone.reputation += targetGain;
        }

        emit ReputationAttested(attesterTokenId, targetTokenId, attesterRepDelta, targetGain, uint48(block.timestamp));
    }

    /**
     * @dev Allows a stone owner to perform a 'Rite of Passage'.
     * This typically costs essence and might have a reputation requirement.
     * Successful rites can unlock higher levels or specific features.
     * @param riteLevel The level of the rite being performed (e.g., 1 for the first rite).
     */
    function performRiteOfPassage(uint8 riteLevel) external {
        uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }

        Stone storage stone = _stones[tokenId];
        uint8 currentLevel = calculateStoneLevel(tokenId);

        // Check if the requested rite level is the next one or valid
        if (riteLevel == 0 || riteLevel <= currentLevel) {
             revert CannotPerformRiteAtCurrentLevel(currentLevel, riteLevel);
        }
         if (riteLevel > levelReputationThresholds.length + 1) {
             revert InvalidRiteLevel(riteLevel);
         }


        uint256 requiredEssence = riteEssenceCost[riteLevel];
        if (stone.essence < requiredEssence) {
             revert InsufficientEssence(requiredEssence, stone.essence);
        }

        uint16 requiredReputation = 0;
        if (riteLevel > 0 && riteLevel <= levelReputationThresholds.length) {
             requiredReputation = levelReputationThresholds[riteLevel - 1]; // Rep threshold for level riteLevel
        } else if (riteLevel == levelReputationThresholds.length + 1) {
             requiredReputation = levelReputationThresholds[levelReputationThresholds.length - 1]; // Rep threshold for highest level
        }


         if (stone.reputation < requiredReputation) {
             revert("Insufficient reputation for this rite"); // More specific error needed
         }

        // Burn essence
        stone.essence -= requiredEssence;

        // Optionally reduce reputation for the rite
        uint16 repCost = riteReputationCost[riteLevel];
        if (stone.reputation >= repCost) {
            stone.reputation -= repCost;
        } else {
            stone.reputation = 0;
        }

        // Success! The stone owner has performed the rite.
        // The effect (e.g., reaching the next level threshold) is inherent
        // in the reputation/level calculation. Additional status flags could be set here.

        emit RitePerformed(tokenId, currentLevel, calculateStoneLevel(tokenId), requiredEssence, uint48(block.timestamp));
    }


    /**
     * @dev Attaches a small string message ('whisper') to the caller's stone.
     * Overwrites the previous whisper. Could potentially cost essence/rep.
     * @param message The whisper string (limited length).
     */
    function sendWhisper(string memory message) external {
         uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }
        // Basic sanity check on message length to prevent excessive gas costs
        require(bytes(message).length <= 256, "Whisper too long");

        Stone storage stone = _stones[tokenId];
        stone.lastWhisper = message;

        emit WhisperSent(tokenId, message, uint48(block.timestamp));
    }

     /**
     * @dev Allows a stone owner to spend essence to unlock a specific status flag/feature.
     * @param featureFlag The bitmask corresponding to the feature to unlock.
     */
    function redeemEssenceForFeature(uint32 featureFlag) external {
        uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }

        Stone storage stone = _stones[tokenId];

        // Check if feature is already unlocked
        if ((stone.statusFlags & featureFlag) == featureFlag) {
             revert FeatureAlreadyUnlocked(featureFlag);
        }

        uint256 requiredEssence = featureEssenceCost[featureFlag];
        if (requiredEssence == 0) {
             revert("Feature has no defined cost"); // Or allow 0 cost features?
        }

        if (stone.essence < requiredEssence) {
             revert InsufficientEssence(requiredEssence, stone.essence);
        }

        // Burn essence
        stone.essence -= requiredEssence;

        // Unlock feature
        stone.statusFlags |= featureFlag;

        emit FeatureUnlocked(tokenId, featureFlag, requiredEssence, uint48(block.timestamp));
    }

    /**
     * @dev Delegates certain powers/rights associated with the stone to another address.
     * The delegate could perform actions like attestation or participate in governance on behalf of the owner.
     * @param delegatee The address to delegate power to.
     */
    function delegatePower(address delegatee) external {
        uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }

        Stone storage stone = _stones[tokenId];
        address oldDelegate = stone.delegatedTo;
        stone.delegatedTo = delegatee;

        emit DelegationUpdated(tokenId, oldDelegate, delegatee, uint48(block.timestamp));
    }

    /**
     * @dev Removes the delegation from the caller's stone.
     */
    function undelegatePower() external {
         uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }

        Stone storage stone = _stones[tokenId];
        address oldDelegate = stone.delegatedTo;
        stone.delegatedTo = address(0);

         emit DelegationUpdated(tokenId, oldDelegate, address(0), uint48(block.timestamp));
    }

     /**
     * @dev Checks if a specific feature flag is set for the caller's stone.
     * @param featureFlag The bitmask for the feature to check.
     * @return True if the feature is unlocked, false otherwise.
     */
    function checkFeatureUnlocked(uint32 featureFlag) external view returns (bool) {
         uint256 tokenId = _ownerToTokenId[msg.sender];
        if (tokenId == 0) {
             revert StoneNotOwnedByUser(0, msg.sender);
        }
        Stone storage stone = _stones[tokenId];
        return (stone.statusFlags & featureFlag) == featureFlag;
    }


    // --- View Functions ---

    /**
     * @dev Gets the details of a specific stone by its ID.
     * @param tokenId The ID of the stone.
     * @return A tuple containing stone details.
     */
    function getStone(uint256 tokenId) external view returns (
        address owner,
        uint256 id,
        uint48 mintTimestamp,
        uint48 lastClaimTimestamp,
        uint16 reputation,
        uint256 essence,
        uint32 statusFlags,
        address delegatedTo,
        string memory lastWhisper
    ) {
        Stone storage stone = _stones[tokenId];
        if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) { // Check both mappings for existence
            revert InvalidTokenId(tokenId);
        }

        return (
            stone.owner,
            stone.tokenId,
            stone.mintTimestamp,
            stone.lastEssenceClaimTimestamp,
            stone.reputation,
            stone.essence,
            stone.statusFlags,
            stone.delegatedTo,
            stone.lastWhisper
        );
    }

    /**
     * @dev Gets the stone ID owned by a specific address.
     * @param owner The address to check.
     * @return The stone ID, or 0 if no stone is owned by this address.
     */
    function getStoneByOwner(address owner) external view returns (uint256) {
        return _ownerToTokenId[owner];
    }

    /**
     * @dev Calculates the pending essence for a stone ID that hasn't been claimed yet.
     * @param tokenId The ID of the stone.
     * @return The amount of pending essence.
     */
    function getPendingEssence(uint256 tokenId) public view returns (uint256) {
        Stone storage stone = _stones[tokenId];
        if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) {
            revert InvalidTokenId(tokenId);
        }
        uint256 lastClaim = stone.lastEssenceClaimTimestamp;
        uint256 currentTime = block.timestamp;

        if (currentTime <= lastClaim) {
            return 0;
        }

        uint256 timeElapsed = currentTime - lastClaim;
        return timeElapsed * essenceRatePerSecond;
    }

    /**
     * @dev Gets the current calculated level of a stone based on its reputation.
     * Levels are defined by the `levelReputationThresholds`.
     * @param tokenId The ID of the stone.
     * @return The calculated level (0-indexed).
     */
    function getStoneLevel(uint256 tokenId) public view returns (uint8) {
        Stone storage stone = _stones[tokenId];
         if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) {
            revert InvalidTokenId(tokenId);
        }
        return calculateStoneLevel(tokenId);
    }

    /**
     * @dev Gets the last whisper associated with a stone ID.
     * @param tokenId The ID of the stone.
     * @return The last whisper string.
     */
    function getLastWhisper(uint256 tokenId) external view returns (string memory) {
         Stone storage stone = _stones[tokenId];
         if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) {
            revert InvalidTokenId(tokenId);
        }
        return stone.lastWhisper;
    }

     /**
     * @dev Gets the address currently delegated power for a stone ID.
     * @param tokenId The ID of the stone.
     * @return The delegated address, or address(0) if no delegation.
     */
    function getDelegatedAddress(uint256 tokenId) external view returns (address) {
         Stone storage stone = _stones[tokenId];
         if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) {
            revert InvalidTokenId(tokenId);
        }
        return stone.delegatedTo;
    }

     /**
     * @dev Gets the raw status flags uint32 for a stone ID.
     * Use this to check multiple flags efficiently off-chain.
     * @param tokenId The ID of the stone.
     * @return The uint32 containing all status flags.
     */
    function getStoneStatusFlags(uint256 tokenId) external view returns (uint32) {
         Stone storage stone = _stones[tokenId];
         if (stone.tokenId == 0 && _tokenToOwner[tokenId] == address(0)) {
            revert InvalidTokenId(tokenId);
        }
        return stone.statusFlags;
    }

    /**
     * @dev Gets the total number of stones minted.
     */
    function getStoneCount() external view returns (uint256) {
        return _tokenIds.current();
    }


    // --- Internal / Pure Helpers ---

    /**
     * @dev Internal function to calculate a stone's level based on reputation.
     * @param tokenId The ID of the stone.
     * @return The calculated level.
     */
    function calculateStoneLevel(uint256 tokenId) internal view returns (uint8) {
        Stone storage stone = _stones[tokenId];
        uint16 reputation = stone.reputation;
        uint8 level = 0;
        for (uint i = 0; i < levelReputationThresholds.length; i++) {
            if (reputation >= levelReputationThresholds[i]) {
                level = uint8(i) + 1;
            } else {
                break; // Thresholds are sorted, can stop early
            }
        }
        return level;
    }

    // --- ERC721 Standard Implementations (with SBT Modifications) ---

    /**
     * @dev Returns the number of tokens in `owner`'s account. Should be 0 or 1.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownerToTokenId[owner] != 0 ? 1 : 0;
    }

    /**
     * @dev Returns the owner of the `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenToOwner[tokenId];
        if (owner == address(0)) {
             revert InvalidTokenId(tokenId);
        }
        return owner;
    }

    // --- SBT Modifications: Disable Transfer/Approval ---

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check if the transfer unbind feature is unlocked for the token
        Stone storage stone = _stones[tokenId];
        if ((stone.statusFlags & STATUS_UNLOCKED_TRANSFER_UNBIND) == 0) {
             revert CannotTransferSBT(); // Stones are non-transferable by default
        }

        // If unbinding *is* allowed, implement ERC721 transfer logic.
        // NOTE: This would require careful consideration of how state (rep, essence)
        // is handled on transfer. Does it reset? Is it partially transferred?
        // For this example, we'll keep it simple and assume unbinding just allows transfer
        // but the state *might* reset or decay significantly in a real system.
        // Let's add a simplified transfer that resets state for demonstration.

        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Custom logic for SBT unbinding/transfer: reset dynamic state
        delete _stones[tokenId]; // Remove dynamic state
        _tokenToOwner[tokenId] = to;
        delete _ownerToTokenId[from];
        _ownerToTokenId[to] = tokenId; // Assign to new owner

        // Re-initialize basic stone data for the new owner (or leave as is, depends on design)
        // Leaving as is means the state (rep, essence) might be inherited but makes less sense for SBT.
        // A full re-initialization or decay is more common. Let's partially reset for demo.
        _stones[tokenId] = Stone({
             owner: to,
             tokenId: tokenId,
             mintTimestamp: uint48(block.timestamp), // New mint time for essence
             lastEssenceClaimTimestamp: uint48(block.timestamp),
             reputation: stone.reputation / 2, // Example: reputation decay on transfer
             essence: stone.essence / 2, // Example: essence decay on transfer
             statusFlags: stone.statusFlags & ~STATUS_UNLOCKED_TRANSFER_UNBIND, // Remove unbind flag
             delegatedTo: address(0), // Reset delegation
             lastWhisper: "" // Reset whisper
        });


        emit Transfer(from, to, tokenId);

         // Standard ERC721 requires clearing approval, even if not used for transfer
        delete _approved[tokenId];

        // If `to` is a contract, check if it accepts ERC721 tokens (optional but good practice)
        // This requires implementing ERC721Receiver or similar check
        if (to.code.length > 0 && !_checkOnERC721Received(address(0), from, to, tokenId, "")) {
             revert("ERC721: transfer to non ERC721Receiver implementer");
        }
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         // Check if the transfer unbind feature is unlocked
        Stone storage stone = _stones[tokenId];
        if ((stone.statusFlags & STATUS_UNLOCKED_TRANSFER_UNBIND) == 0) {
             revert CannotTransferSBT();
        }
        // Call the transfer logic
        transferFrom(from, to, tokenId);
         // Perform the safety check for receiver contract
         if (to.code.length > 0) {
            require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
         }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         safeTransferFrom(from, to, tokenId, "");
    }

    // Overrides for approval functions to make them revert
    mapping(uint256 => address) private _approved; // Needed for ERC721, but access restricted

    function approve(address to, uint256 tokenId) public override {
        revert CannotTransferSBT(); // Approvals not supported for SBT
        // Required by ERC721, but revert:
        // address owner = ownerOf(tokenId);
        // require(to != owner, "ERC721: approval to current owner");
        // require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        // _approved[tokenId] = to;
        // emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert CannotTransferSBT(); // Approvals not supported for SBT
         // Required by ERC721, but revert:
        // _operatorApprovals[msg.sender][operator] = approved;
        // emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
         // Return address(0) as approvals are not supported
        require(_exists(tokenId), "ERC721: approval query for non-existent token");
        return address(0); // Always return 0 for SBT
    }

    mapping(address => mapping(address => bool)) private _operatorApprovals; // Needed for ERC721, but access restricted
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Always return false as approvals are not supported
        return false; // Always return false for SBT
        // Standard: return _operatorApprovals[owner][operator];
    }

     // ERC721Receiver: Return this magic value from onERC721Received to accept the token
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        // Since transfer is restricted, this function might only be called if the unbind feature is used.
        // Returning the magic value indicates willingness to receive.
        return this.onERC721Received.selector;
    }


    // Internal helper to check if a token ID exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenToOwner[tokenId] != address(0);
    }

    // Internal helper for the onERC721Received check
     function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true; // Not a contract, no callback needed
        }
        try IERC721Receiver(to).onERC721Received(operator, from, to, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length != 0) {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }
    }


    // --- ERC721 Metadata ---

    string private _name = "Genesis Stone";
    string private _symbol = "GSTONE";
    string private _baseTokenURI = "ipfs://YOUR_IPFS_GATEWAY_BASE_URI/"; // Base URI for metadata

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the metadata URI for a given token ID.
     * This implementation can be dynamic, reflecting the stone's state.
     * It constructs a URI that a metadata service can interpret.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert InvalidTokenId(tokenId);
        }

        Stone storage stone = _stones[tokenId];
        uint256 pendingEssence = getPendingEssence(tokenId);
        uint8 currentLevel = calculateStoneLevel(tokenId);

        // Example: Construct a dynamic URI like baseURI/tokenId?rep=X&essence=Y&level=Z&flags=F
        // A metadata service would read these query parameters and generate an image/JSON.
        string memory base = _baseTokenURI;
        string memory tokenIdStr = _toString(tokenId);
        string memory repStr = _toString(stone.reputation);
        string memory essenceStr = _toString(stone.essence + pendingEssence); // Include pending
        string memory levelStr = _toString(currentLevel);
        string memory flagsStr = _toString(stone.statusFlags);


        return string(abi.encodePacked(
            base,
            tokenIdStr,
            "?rep=", repStr,
            "&essence=", essenceStr,
            "&level=", levelStr,
            "&flags=", flagsStr
            // Add more parameters if needed, e.g., lastClaimTimestamp, mintTimestamp
        ));
    }

    // Helper function to convert uint256 to string (standard utility)
    function _toString(uint256 value) internal pure returns (string memory) {
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

}
```

---

**Explanation of Concepts Used:**

1.  **Soulbound Tokens (SBT-like):** Inherits ERC721 but overrides `transferFrom`, `safeTransferFrom`, `approve`, and `setApprovalForAll` to `revert` by default. This makes the tokens non-transferable, binding them to the owner's address.
2.  **Dynamic State:** The `Stone` struct holds evolving state variables (`reputation`, `essence`, `statusFlags`). This state changes based on interactions within the contract, not just ownership.
3.  **Passive Yield (Essence):** The `claimEssence` function implements a time-based accumulation mechanism. Essence increases passively based on `essenceRatePerSecond` and time elapsed since the last claim or mint.
4.  **On-Chain Reputation System:** `reputation` is a core state variable. The `attestReputation` function allows users to affect each other's reputation, creating a network effect. There's a cost for the attester to incentivize thoughtful attestations.
5.  **Packed Structs & `uint48`:** Using `uint48` for timestamps and packing multiple booleans into `uint32` (`statusFlags`) helps optimize gas usage by reducing storage slot writes.
6.  **Conditional Feature Unlocking (`statusFlags`):** Features are represented by bitmasks within the `statusFlags` uint32. Users can `redeemEssenceForFeature` to set these bits, enabling new capabilities or indicating progression. The `checkFeatureUnlocked` function allows verifying if a feature is active.
7.  **Rites of Passage:** `performRiteOfPassage` is a distinct action that costs essence (and potentially reputation) to signify achieving a new tier or "level," which is derived from reputation thresholds.
8.  **Simple On-Chain Interaction (`lastWhisper`):** The `sendWhisper` function adds a basic, persistent message tied to the stone, demonstrating how limited social features can exist on-chain (though storing strings is gas-intensive, limited size/count is key).
9.  **Delegation:** `delegatePower` and `undelegatePower` allow a stone owner to designate another address to act on their behalf for certain future actions (e.g., governance voting if implemented, or potentially attestation).
10. **Dynamic `tokenURI`:** The `tokenURI` function constructs a URI including the stone's current state (reputation, essence, level, flags). A metadata server could use these parameters to generate dynamic images or JSON metadata, reflecting the stone's evolution off-chain.
11. **Custom Errors:** Uses `error` definitions (EIP-3156) for more gas-efficient and informative error messages compared to `require` strings.
12. **ERC721 Unbinding Mechanism (Conditional Transfer):** While the stone is *initially* soulbound, the `STATUS_UNLOCKED_TRANSFER_UNBIND` flag allows the owner to unlock transferability by paying a high essence cost. When transferred, the stone's state (rep, essence) is decayed/reset, emphasizing the "rebinding" aspect to the new owner.
13. **ERC165 & ERC721Receiver Compliance:** Includes standard implementations for `supportsInterface` and `onERC721Received` for better interoperability, even though transfer is restricted.
14. **Level Calculation:** `calculateStoneLevel` is a view function that derives the stone's level purely from its reputation and the defined thresholds, making the level dynamic without needing dedicated storage.

This contract goes beyond standard token/NFT examples by embedding game-like progression, social signaling (reputation, whispers), and dynamic state changes directly into the token logic. Remember that deploying complex contracts like this requires careful consideration of gas costs and extensive security auditing.