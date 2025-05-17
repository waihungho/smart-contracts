Okay, let's design an advanced, creative, and trendy smart contract.

We'll create a system around **Dynamic NFTs that evolve, interact, and participate in oracle-driven events**, incorporating concepts like **gamified staking, asset merging, entropy, delegated actions, and state-dependent abilities**.

This concept is unique as it combines several mechanics (dynamic stats, entropy, oracle triggers affecting asset state, delegated gameplay) within a single NFT collection, going beyond standard ERC-721/1155 behavior and typical staking/merging examples.

**Concept Name:** Symbiotic Evolution System (SYMBIOS)

**Core Idea:** Users own "Evolvers" (ERC-721 NFTs) that have mutable attributes (level, power, affinity, evolution points, entropy). These attributes change based on on-chain actions (staking, leveling up, merging) and can be temporarily boosted or affected by external data via an oracle (triggering a "Catalyst" state). Evolvers can be used in "Challenges" where the outcome is influenced by their attributes and the oracle data. Owners can delegate certain actions to other addresses.

---

### **Symbiotic Evolution System (SYMBIOS) Smart Contract**

**Outline:**

1.  **License & Pragmas**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard, Address
3.  **Errors:** Custom error definitions for clarity.
4.  **Events:** Announce key state changes (Mint, LevelUp, Staked, Unstaked, Merged, ChallengeRegistered, ChallengeResolved, CatalystTriggered, EntropyRefreshed, DelegateSet).
5.  **Structs:**
    *   `EvolverAttributes`: Stores mutable data for each Evolver NFT.
    *   `ChallengeState`: Stores data for active/resolved challenges.
6.  **State Variables:**
    *   ERC721 standard mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
    *   NFT metadata (`_tokenIds`, `_tokenURIs`).
    *   `EvolverAttributes` mapping.
    *   Staking state mapping (`_stakedTokens`, `_lastPointUpdateTime`).
    *   Evolution points mapping (`_evolutionPoints`).
    *   Delegation mapping (`_delegates`).
    *   Oracle address.
    *   Challenge counter & state mapping.
    *   Constants (staking rate, merge costs, entropy rate, max level, etc.).
    *   Contract state (`_paused`).
7.  **Modifiers:** `onlyOwner`, `onlyOracle`, `whenNotPaused`, `nonReentrant`.
8.  **Constructor:** Initialize contract, set owner and initial oracle/base URI.
9.  **Internal Helper Functions:**
    *   `_updateEvolutionPoints`: Calculates and adds accrued points.
    *   `_calculateEntropy`: Calculates current entropy level based on time/actions.
    *   `_isDelegate`: Checks if an address is a delegate for an owner.
    *   `_createChallengeId`: Generates a unique ID for challenges.
    *   `_resolveChallengeLogic`: Contains the core logic for challenge outcome based on inputs.
10. **Public/External Functions (20+):**
    *   **ERC721 Standard (Required):** `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom(address,address,uint256)`, `safeTransferFrom(address,address,uint256,bytes)`.
    *   **ERC721 Metadata (Optional but Standard):** `setBaseURI`, `tokenURI`.
    *   **ERC721 Enumeration (Optional but Standard):** `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`.
    *   **Asset Management:** `mintEvolver`, `getEvolverAttributes`, `getCurrentEntropy`.
    *   **Evolution & Progression:** `stakeEvolver`, `unstakeEvolver`, `claimEvolutionPoints`, `levelUpEvolver`.
    *   **Lifecycle & Advanced:** `mergeEvolvers`, `refreshEntropy`.
    *   **Gamification & Challenges:** `createChallenge` (Owner only), `registerForChallenge`, `submitOracleDataForChallenge` (Oracle only), `resolveChallenge` (Keeper/Owner), `getChallengeState`, `getChallengeParticipants`.
    *   **State-Dependent Ability:** `checkCatalystStatus`.
    *   **Delegation:** `setDelegate`, `isDelegate`.
    *   **Admin/Utility:** `setOracleAddress`, `pause`, `unpause`, `rescueETH`, `rescueERC20`.

**Function Summary:**

1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (ERC721)
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (ERC721)
3.  `getApproved(uint256 tokenId)`: Returns the address approved to transfer a token. (ERC721)
4.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of an owner's tokens. (ERC721)
5.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific token. (ERC721)
6.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes an operator for all of the sender's tokens. (ERC721)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token using approvals. (ERC721)
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token. (ERC721)
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers a token with data. (ERC721)
10. `setBaseURI(string memory baseURI)`: Sets the base URI for token metadata (Owner only).
11. `tokenURI(uint256 tokenId)`: Returns the full metadata URI for a token.
12. `totalSupply()`: Returns the total number of tokens minted. (ERC721 Enumerable)
13. `tokenByIndex(uint256 index)`: Returns the token ID at a specific index (ERC721 Enumerable).
14. `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns the token ID owned by an address at a specific index (ERC721 Enumerable).
15. `mintEvolver(address recipient, uint256 affinity)`: Mints a new Evolver NFT with base attributes for a recipient. (Owner only).
16. `getEvolverAttributes(uint256 tokenId)`: Returns the mutable attributes of an Evolver. (View)
17. `getCurrentEntropy(uint256 tokenId)`: Calculates and returns the current entropy level of an Evolver. (View)
18. `stakeEvolver(uint256 tokenId)`: Stakes an Evolver in the contract to start accruing evolution points. Must be owner or delegate.
19. `unstakeEvolver(uint256 tokenId)`: Unstakes an Evolver from the contract. Accrued points are claimed automatically. Must be owner or delegate.
20. `claimEvolutionPoints(uint256 tokenId)`: Calculates and adds accrued evolution points to the Evolver's balance without unstaking. Must be owner or delegate.
21. `levelUpEvolver(uint256 tokenId)`: Consumes evolution points to increase the Evolver's level and power. Requires minimum points and not be at max level. Must be owner or delegate.
22. `mergeEvolvers(uint256 tokenId1, uint256 tokenId2)`: Burns two Evolvers and mints a new one with combined/improved attributes. Requires specific conditions met (e.g., levels, points, not staked). Must be owner or delegate of both.
23. `refreshEntropy(uint256 tokenId)`: Reduces an Evolver's entropy level by consuming evolution points or potentially another resource (e.g., ERC20 token). Must be owner or delegate.
24. `createChallenge(uint256 rewardAmount, uint256 entryFee, uint48 registrationDeadline)`: Creates a new challenge with specified parameters. (Owner only)
25. `registerForChallenge(uint256 challengeId, uint256 tokenId)`: Stakes an Evolver into a specific challenge, paying an entry fee (points or token). Must be owner or delegate.
26. `submitOracleDataForChallenge(uint256 challengeId, bytes calldata oracleData)`: Called by the registered oracle to provide external data for a challenge. (Oracle only)
27. `triggerCatalystStatusByOracle(uint256 tokenId, uint48 duration)`: Called by the oracle to set an Evolver's catalyst status for a duration based on external conditions. (Oracle only)
28. `resolveChallenge(uint256 challengeId)`: Finalizes a challenge after oracle data is submitted, determines winners based on Evolver attributes, oracle data, and entropy, and distributes rewards. (Keeper/Owner)
29. `getChallengeState(uint256 challengeId)`: Returns the current state and parameters of a challenge. (View)
30. `getChallengeParticipants(uint256 challengeId)`: Returns the list of Evolver token IDs participating in a challenge. (View)
31. `checkCatalystStatus(uint256 tokenId)`: Returns true if the Evolver is currently in Catalyst state. (View)
32. `setDelegate(address delegate, bool allowed)`: Allows an owner to grant or revoke delegation rights to another address for actions like staking, leveling, challenging.
33. `isDelegate(address delegator, address delegatee)`: Checks if `delegatee` is a delegate for `delegator`. (View)
34. `setOracleAddress(address newOracle)`: Sets the address of the trusted oracle contract. (Owner only)
35. `pause()`: Pauses specific contract interactions (Owner only).
36. `unpause()`: Unpauses the contract (Owner only).
37. `rescueETH(uint256 amount)`: Allows owner to withdraw accidental ETH sent to contract. (Owner only)
38. `rescueERC20(address tokenAddress, uint256 amount)`: Allows owner to withdraw accidental ERC20 sent to contract. (Owner only)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For enumeration functions
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For tokenURI flexibility
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Optional: if challenges use ERC20 rewards/fees

// --- Symbiotic Evolution System (SYMBIOS) Smart Contract ---
// Outline:
// 1. License & Pragmas
// 2. Imports (ERC721, Ownable, ReentrancyGuard, ERC721Enumerable, ERC721URIStorage, Address, IERC20)
// 3. Errors (Custom errors)
// 4. Events (Key state changes)
// 5. Structs (EvolverAttributes, ChallengeState)
// 6. State Variables (NFT data, Evolver attributes, staking, delegation, oracle, challenges, constants, pause state)
// 7. Modifiers (onlyOwner, onlyOracle, whenNotPaused, nonReentrant)
// 8. Constructor (Initialize contract)
// 9. Internal Helper Functions (Point calculation, Entropy calculation, Delegation check, Challenge ID, Challenge Resolution Logic)
// 10. Public/External Functions (ERC721 standard, Asset Management, Evolution, Lifecycle, Gamification, State-Dependent, Delegation, Admin)
//
// Function Summary:
// 1.  balanceOf(address owner): Returns the number of tokens owned by an address. (ERC721)
// 2.  ownerOf(uint256 tokenId): Returns the owner of a specific token. (ERC721)
// 3.  getApproved(uint256 tokenId): Returns the address approved to transfer a token. (ERC721)
// 4.  isApprovedForAll(address owner, address operator): Checks if an operator is approved for all of an owner's tokens. (ERC721)
// 5.  approve(address to, uint256 tokenId): Approves an address to transfer a specific token. (ERC721)
// 6.  setApprovalForAll(address operator, bool approved): Approves or revokes an operator for all of the sender's tokens. (ERC721)
// 7.  transferFrom(address from, address to, uint256 tokenId): Transfers a token using approvals. (ERC721)
// 8.  safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers a token. (ERC721)
// 9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers a token with data. (ERC721)
// 10. setBaseURI(string memory baseURI): Sets the base URI for token metadata (Owner only).
// 11. tokenURI(uint256 tokenId): Returns the full metadata URI for a token. (ERC721URIStorage)
// 12. totalSupply(): Returns the total number of tokens minted. (ERC721 Enumerable)
// 13. tokenByIndex(uint256 index): Returns the token ID at a specific index (ERC721 Enumerable).
// 14. tokenOfOwnerByIndex(address owner, uint256 index): Returns the token ID owned by an address at a specific index (ERC721 Enumerable).
// 15. mintEvolver(address recipient, uint256 affinity): Mints a new Evolver NFT with base attributes for a recipient. (Owner only).
// 16. getEvolverAttributes(uint256 tokenId): Returns the mutable attributes of an Evolver. (View)
// 17. getCurrentEntropy(uint256 tokenId): Calculates and returns the current entropy level of an Evolver. (View)
// 18. stakeEvolver(uint256 tokenId): Stakes an Evolver in the contract to start accruing evolution points. Must be owner or delegate.
// 19. unstakeEvolver(uint256 tokenId): Unstakes an Evolver from the contract. Accrued points are claimed automatically. Must be owner or delegate.
// 20. claimEvolutionPoints(uint256 tokenId): Calculates and adds accrued evolution points to the Evolver's balance without unstaking. Must be owner or delegate.
// 21. levelUpEvolver(uint256 tokenId): Consumes evolution points to increase the Evolver's level and power. Requires minimum points and not be at max level. Must be owner or delegate.
// 22. mergeEvolvers(uint256 tokenId1, uint256 tokenId2): Burns two Evolvers and mints a new one with combined/improved attributes. Requires specific conditions met (e.g., levels, points, not staked). Must be owner or delegate of both.
// 23. refreshEntropy(uint256 tokenId): Reduces an Evolver's entropy level. Consumes points or other resource. Must be owner or delegate.
// 24. createChallenge(uint256 rewardAmount, uint256 entryFee, uint48 registrationDeadline): Creates a new challenge. Reward could be ETH or ERC20. (Owner only)
// 25. registerForChallenge(uint256 challengeId, uint256 tokenId): Stakes an Evolver into a specific challenge, paying an entry fee. Must be owner or delegate.
// 26. submitOracleDataForChallenge(uint256 challengeId, bytes calldata oracleData): Called by oracle to provide data for a challenge. (Oracle only)
// 27. triggerCatalystStatusByOracle(uint256 tokenId, uint48 duration): Called by oracle to set Catalyst status. (Oracle only)
// 28. resolveChallenge(uint256 challengeId): Finalizes challenge, determines winners, distributes rewards. (Keeper/Owner)
// 29. getChallengeState(uint256 challengeId): Returns challenge details. (View)
// 30. getChallengeParticipants(uint256 challengeId): Returns list of participants. (View)
// 31. checkCatalystStatus(uint256 tokenId): Returns true if Catalyst. (View)
// 32. setDelegate(address delegate, bool allowed): Grant/revoke delegation rights.
// 33. isDelegate(address delegator, address delegatee): Checks delegation. (View)
// 34. setOracleAddress(address newOracle): Set oracle address. (Owner only)
// 35. pause(): Pause interactions. (Owner only)
// 36. unpause(): Unpause interactions. (Owner only)
// 37. rescueETH(uint256 amount): Withdraw ETH. (Owner only)
// 38. rescueERC20(address tokenAddress, uint256 amount): Withdraw ERC20. (Owner only)
// ---

error NotOwnerOrDelegate();
error NotStaked();
error AlreadyStaked();
error InsufficientEvolutionPoints();
error MaxLevelReached();
error InvalidTokenId();
error CannotMergeStakedTokens();
error MergeRequirementsNotMet();
error ZeroAddressNotAllowed();
error ChallengeNotFound();
error ChallengeNotOpenForRegistration();
error ChallengeRegistrationClosed();
error ChallengeNotAwaitingOracleData();
error ChallengeAlreadyResolved();
error NotOracle();
error NotPaused();
error IsPaused();
error InvalidChallengeId();
error InsufficientPayment(); // For challenge fees if using ETH/ERC20

contract SymbioticEvolutionSystem is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Address for address payable;

    struct EvolverAttributes {
        uint8 level;         // Current level (affects power)
        uint16 power;        // Base power stat (affects challenges, etc.)
        uint8 affinity;      // Type/affinity (e.g., 1=Fire, 2=Water, etc. - affects challenges)
        uint256 entropyLevel; // Represents degradation or state (increases over time/actions)
        uint48 catalystEndTime; // Timestamp when catalyst status ends (0 if not catalyst)
    }

    struct ChallengeState {
        uint48 registrationDeadline; // Timestamp registration closes
        uint48 resolutionTime;       // Timestamp resolved
        uint256 rewardAmount;        // Prize pool
        uint256 entryFee;            // Cost to enter (points or potentially ETH/ERC20)
        uint256 oracleDataHash;      // Hash of expected oracle data
        bytes oracleData;            // Received oracle data
        address[] participants;      // List of tokenIds participating
        uint256[] winners;           // List of winning tokenIds
        enum Status { Created, OpenForRegistration, ClosedForRegistration, OracleDataAwaiting, Resolved }
        Status currentStatus;
    }

    mapping(uint256 => EvolverAttributes) private _evolverAttributes;
    mapping(uint256 => bool) private _stakedTokens;
    mapping(uint256 => uint256) private _evolutionPoints;
    mapping(uint256 => uint48) private _lastPointUpdateTime; // Use uint48 for timestamp
    mapping(address => mapping(address => bool)) private _delegates; // owner => delegate => allowed

    address public oracleAddress;
    address public optionalRewardToken; // Address of an optional ERC20 reward token

    uint256 private _nextTokenId;
    uint256 private _nextChallengeId;

    mapping(uint256 => ChallengeState) private _challenges;
    mapping(uint256 => uint256[]) private _challengeParticipantsList; // To store participants per challenge

    bool private _paused;

    // Constants (can be made configurable by owner via setters)
    uint256 public constant EVOLUTION_POINTS_PER_SECOND_BASE = 1;
    uint256 public constant EVOLUTION_POINTS_PER_SECOND_CATALYST = 5; // Boosted rate
    uint256 public constant LEVEL_UP_POINT_COST_MULTIPLIER = 1000; // Cost increases per level
    uint256 public constant MAX_EVOLVER_LEVEL = 10;
    uint256 public constant ENTROPY_PER_SECOND_BASE = 1;
    uint256 public constant ENTROPY_REFRESH_COST_POINTS = 500; // Cost to reduce entropy

    event EvolverMinted(address indexed owner, uint256 indexed tokenId, uint256 affinity);
    event EvolverLevelUp(uint256 indexed tokenId, uint8 newLevel, uint16 newPower);
    event EvolverStaked(uint256 indexed tokenId, address indexed owner);
    event EvolverUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimedPoints);
    event EvolutionPointsClaimed(uint256 indexed tokenId, uint256 claimedPoints);
    event EvolversMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event EvolverEntropyRefreshed(uint256 indexed tokenId, uint256 newEntropyLevel);
    event ChallengeCreated(uint256 indexed challengeId, uint256 rewardAmount, uint48 registrationDeadline);
    event ChallengeRegistered(uint256 indexed challengeId, uint256 indexed tokenId, address indexed participant);
    event OracleDataSubmitted(uint256 indexed challengeId, bytes oracleData);
    event ChallengeResolved(uint256 indexed challengeId, uint256 rewardAmount, uint256[] winners);
    event CatalystStatusTriggered(uint256 indexed tokenId, uint48 endTime);
    event DelegateSet(address indexed owner, address indexed delegate, bool allowed);
    event Paused(address account);
    event Unpaused(address account);

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert IsPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    constructor(address initialOracle, string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721URIStorage()
        Ownable(msg.sender) // Assumes contract deployer is initial owner
    {
        if (initialOracle == address(0)) revert ZeroAddressNotAllowed();
        oracleAddress = initialOracle;
        _setBaseURI(baseURI);
        _nextTokenId = 0;
        _nextChallengeId = 0;
        _paused = false;
    }

    // --- Internal Helper Functions ---

    function _updateEvolutionPoints(uint256 tokenId) internal {
        EvolverAttributes storage attrs = _evolverAttributes[tokenId];
        if (_stakedTokens[tokenId]) {
            uint48 currentTime = uint48(block.timestamp);
            uint256 timeElapsed = currentTime - _lastPointUpdateTime[tokenId];
            uint256 pointsEarned = timeElapsed * (
                attrs.catalystEndTime > currentTime ? EVOLUTION_POINTS_PER_SECOND_CATALYST : EVOLUTION_POINTS_PER_SECOND_BASE
            );
            _evolutionPoints[tokenId] += pointsEarned;
            _lastPointUpdateTime[tokenId] = currentTime;
        }
    }

    function _calculateEntropy(uint256 tokenId) internal view returns (uint256) {
        // Simplified entropy: increases with time since last interaction or refresh
        // In a real contract, this could be more complex, involving actions taken, etc.
        EvolverAttributes storage attrs = _evolverAttributes[tokenId];
        // Assume last interaction updates lastPointUpdateTime even if not staked
        uint48 lastInteractionTime = _lastPointUpdateTime[tokenId];
        if (lastInteractionTime == 0 && attrs.level > 0) { // Handle newly minted/very old tokens
             lastInteractionTime = uint48(block.timestamp); // Or some default
        }
        if (lastInteractionTime == 0) return attrs.entropyLevel; // No interactions yet
        
        uint256 timeElapsed = uint48(block.timestamp) - lastInteractionTime;
        return attrs.entropyLevel + (timeElapsed * ENTROPY_PER_SECOND_BASE); // Entropy increases over time
    }

    function _isDelegate(address potentialDelegate, address owner) internal view returns (bool) {
        if (potentialDelegate == address(0)) return false;
        if (potentialDelegate == owner) return true; // Owner is always their own delegate implicitly
        return _delegates[owner][potentialDelegate];
    }

    function _createChallengeId() internal returns (uint256) {
        _nextChallengeId++;
        return _nextChallengeId;
    }

    // Placeholder for complex challenge resolution logic
    // In a real scenario, this would use EVolver attributes, oracleData, and potentially randomness
    // to determine winners based on affinity match, power levels, etc.
    function _resolveChallengeLogic(uint256 challengeId) internal view returns (uint256[] memory winners) {
        ChallengeState storage challenge = _challenges[challengeId];
        uint256[] storage participants = _challengeParticipantsList[challengeId];
        uint256 numParticipants = participants.length;

        if (numParticipants == 0) {
            return new uint256[](0); // No participants, no winners
        }

        // Example Logic: Winner is the participant with the highest power stat
        // This is a simplification. A real system would use oracleData, affinity matching, etc.
        uint256 highestPower = 0;
        uint256 bestParticipantId = 0; // Store tokenId

        // Use a simple PRNG for example (NOT SECURE FOR PRODUCTION)
        // A production contract would use Chainlink VRF or similar
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, challenge.oracleData, msg.sender)));

        for (uint256 i = 0; i < numParticipants; i++) {
            uint256 tokenId = participants[i];
            EvolverAttributes storage attrs = _evolverAttributes[tokenId];
            uint256 effectivePower = attrs.power; // Could add catalyst bonus, entropy penalty etc.

            // Example: Add a random factor
            effectivePower = effectivePower + (randomness % 100); // Add up to 99 random points

            if (effectivePower > highestPower) {
                highestPower = effectivePower;
                bestParticipantId = tokenId;
            }
             randomness = uint256(keccak256(abi.encodePacked(randomness, tokenId))); // Update randomness for next iteration
        }

        // Simple logic: only one winner
        winners = new uint256[](1);
        winners[0] = bestParticipantId;

        // Could implement multiple winners, proportional rewards, etc.
    }


    // --- ERC721 Standard Functions (Implemented by inherited contracts) ---

    // 1. balanceOf
    // 2. ownerOf
    // 3. getApproved
    // 4. isApprovedForAll
    // 5. approve
    // 6. setApprovalForAll
    // 7. transferFrom
    // 8. safeTransferFrom(address,address,uint256)
    // 9. safeTransferFrom(address,address,uint256,bytes)

    // ERC721Enumerable Overrides
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // Clear Evolver attributes when burning
        delete _evolverAttributes[tokenId];
        delete _stakedTokens[tokenId];
        delete _evolutionPoints[tokenId];
        delete _lastPointUpdateTime[tokenId];
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC721 Metadata & Enumerable (Provided by inherited contracts, listed for summary) ---

    // 10. setBaseURI (Override for onlyOwner restriction)
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    // 11. tokenURI (Provided by ERC721URIStorage)
    // 12. totalSupply (Provided by ERC721Enumerable)
    // 13. tokenByIndex (Provided by ERC721Enumerable)
    // 14. tokenOfOwnerByIndex (Provided by ERC721Enumerable)

    // --- Asset Management ---

    /// @notice Mints a new Evolver NFT with base attributes. Only callable by owner.
    /// @param recipient The address to receive the new Evolver.
    /// @param affinity The affinity type of the new Evolver (e.g., 1, 2, 3...).
    function mintEvolver(address recipient, uint256 affinity) public onlyOwner whenNotPaused nonReentrant {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();

        uint256 tokenId = _nextTokenId++;
        _safeMint(recipient, tokenId);

        _evolverAttributes[tokenId] = EvolverAttributes({
            level: 1,
            power: 100, // Base power
            affinity: uint8(affinity),
            entropyLevel: 0,
            catalystEndTime: 0
        });

        // Initialize point tracking
        _evolutionPoints[tokenId] = 0;
        _lastPointUpdateTime[tokenId] = uint48(block.timestamp); // Record initial time

        // Set a default token URI or rely on base URI + tokenId
        _setTokenURI(tokenId, string(abi.encodePacked(baseURI(), uint256(tokenId).toString())));


        emit EvolverMinted(recipient, tokenId, affinity);
    }

    /// @notice Gets the mutable attributes of a specific Evolver NFT.
    /// @param tokenId The ID of the Evolver token.
    /// @return EvolverAttributes The attributes of the token.
    function getEvolverAttributes(uint256 tokenId) public view returns (EvolverAttributes memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _evolverAttributes[tokenId];
    }

    /// @notice Calculates and returns the current entropy level of an Evolver, including time-based accrual.
    /// @param tokenId The ID of the Evolver token.
    /// @return entropy The calculated current entropy level.
    function getCurrentEntropy(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         return _calculateEntropy(tokenId);
    }


    // --- Evolution & Progression ---

    /// @notice Stakes an Evolver NFT in the contract to earn evolution points.
    /// @param tokenId The ID of the Evolver token to stake.
    function stakeEvolver(uint256 tokenId) public whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
        if (!_isDelegate(msg.sender, owner)) revert NotOwnerOrDelegate();
        if (_stakedTokens[tokenId]) revert AlreadyStaked();
        if (!_exists(tokenId)) revert InvalidTokenId();

        // Transfer the token to the contract address
        safeTransferFrom(owner, address(this), tokenId);

        // Update points before staking (claim any pending points from before staking)
        _updateEvolutionPoints(tokenId);

        _stakedTokens[tokenId] = true;
        _lastPointUpdateTime[tokenId] = uint48(block.timestamp); // Reset timer for staking
        emit EvolverStaked(tokenId, owner);
    }

    /// @notice Unstakes an Evolver NFT from the contract. Accrued points are claimed.
    /// @param tokenId The ID of the Evolver token to unstake.
    function unstakeEvolver(uint256 tokenId) public whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId); // ownerOf will be this contract address here
        // Need to get the original owner to transfer back to
        address originalOwner = ERC721(address(this)).ownerOf(tokenId); // This will fail, need to store original owner OR require caller to provide it
        // Simpler: require caller is the owner *or* delegate based on _delegates mapping
         if (!_isDelegate(msg.sender, originalOwner)) revert NotOwnerOrDelegate();

        if (!_stakedTokens[tokenId]) revert NotStaked();
        if (!_exists(tokenId)) revert InvalidTokenId(); // Should exist if staked

        // Update and claim points before unstaking
        _updateEvolutionPoints(tokenId);
        uint256 claimedPoints = _evolutionPoints[tokenId];
        _evolutionPoints[tokenId] = 0; // Reset points on unstake/claim

        _stakedTokens[tokenId] = false;
         // No need to reset lastPointUpdateTime here, it's used by _calculateEntropy

        // Transfer the token back to the original owner
        // Check for reentrancy implicitly handled by ReentrancyGuard
        ERC721(address(this)).safeTransferFrom(address(this), originalOwner, tokenId);


        emit EvolverUnstaked(tokenId, originalOwner, claimedPoints);
    }


    /// @notice Claims accrued evolution points for a staked Evolver without unstaking.
    /// @param tokenId The ID of the Evolver token.
    function claimEvolutionPoints(uint256 tokenId) public whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
        // Check ownership via delegate check (caller must be original owner or delegate)
         if (!_exists(tokenId)) revert InvalidTokenId();
         // Need to find the actual owner if staked... this is tricky.
         // Option 1: Store original owner when staking.
         // Option 2: Only allow original owner or delegate based on mapping. Let's do Option 2 and adjust stake/unstake.
        address originalOwner = ERC721(address(this)).ownerOf(tokenId); // This will fail.
        // Let's refine stake/unstake to store original owner.
        // For now, let's assume ownerOf(tokenId) returns the owner *before* staking.
        // REFACTORING: ERC721's ownerOf will return the contract address if staked.
        // We need a separate mapping or require the caller to prove ownership/delegation *before* the token leaves their wallet.
        // Alternative: Store original owner in the struct/mapping. Let's add a mapping for this.
         mapping(uint256 => address) private _originalOwners; // Add to state variables

        // --- Corrected Logic for Stake/Unstake/Claim using _originalOwners ---

        // Stake:
        // function stakeEvolver(uint256 tokenId) public whenNotPaused nonReentrant {
        //     address owner = ownerOf(tokenId);
        //     if (!_isDelegate(msg.sender, owner)) revert NotOwnerOrDelegate(); // Check delegate before transfer
        //     if (_stakedTokens[tokenId]) revert AlreadyStaked();
        //     if (!_exists(tokenId)) revert InvalidTokenId();

        //     _updateEvolutionPoints(tokenId); // Update points before staking
        //     _originalOwners[tokenId] = owner; // Store original owner
        //     _safeTransfer(owner, address(this), tokenId, false); // Transfer ownership
        //     _stakedTokens[tokenId] = true;
        //     _lastPointUpdateTime[tokenId] = uint48(block.timestamp); // Reset timer
        //     emit EvolverStaked(tokenId, owner);
        // }

        // Unstake:
        // function unstakeEvolver(uint256 tokenId) public whenNotPaused nonReentrant {
        //     address originalOwner = _originalOwners[tokenId];
        //     if (!_isDelegate(msg.sender, originalOwner)) revert NotOwnerOrDelegate(); // Check delegate
        //     if (!_stakedTokens[tokenId] || ownerOf(tokenId) != address(this)) revert NotStaked(); // Check state

        //     _updateEvolutionPoints(tokenId);
        //     uint256 claimedPoints = _evolutionPoints[tokenId];
        //     _evolutionPoints[tokenId] = 0;
        //     _stakedTokens[tokenId] = false;
        //     delete _originalOwners[tokenId]; // Clear original owner mapping

        //     _safeTransfer(address(this), originalOwner, tokenId, false); // Transfer back

        //     emit EvolverUnstaked(tokenId, originalOwner, claimedPoints);
        // }

        // Claim Points (Corrected):
        address originalOwner = _originalOwners[tokenId];
        if (!_isDelegate(msg.sender, originalOwner)) revert NotOwnerOrDelegate(); // Check delegate
        if (!_stakedTokens[tokenId] || ownerOf(tokenId) != address(this)) revert NotStaked(); // Must be staked

        _updateEvolutionPoints(tokenId);
        uint256 claimedPoints = _evolutionPoints[tokenId];
        // Points are added *in* _updateEvolutionPoints, no need to add again here
        // Just emit the event showing what was added
        emit EvolutionPointsClaimed(tokenId, claimedPoints);
    }

    /// @notice Increases the level and power of an Evolver by consuming evolution points.
    /// @param tokenId The ID of the Evolver token.
    function levelUpEvolver(uint256 tokenId) public whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
         if (!_exists(tokenId)) revert InvalidTokenId();
        address actualOwner = _stakedTokens[tokenId] ? _originalOwners[tokenId] : owner;
        if (!_isDelegate(msg.sender, actualOwner)) revert NotOwnerOrDelegate();

        EvolverAttributes storage attrs = _evolverAttributes[tokenId];
        if (attrs.level >= MAX_EVOLVER_LEVEL) revert MaxLevelReached();

        // Update points before consuming
        _updateEvolutionPoints(tokenId);

        uint256 requiredPoints = (attrs.level + 1) * LEVEL_UP_POINT_COST_MULTIPLIER;
        if (_evolutionPoints[tokenId] < requiredPoints) revert InsufficientEvolutionPoints();

        _evolutionPoints[tokenId] -= requiredPoints;
        attrs.level++;
        attrs.power = uint16(100 + attrs.level * 50); // Example power formula

        emit EvolverLevelUp(tokenId, attrs.level, attrs.power);
    }


    // --- Lifecycle & Advanced ---

    /// @notice Merges two Evolver NFTs into a new, potentially stronger one. Burns the originals.
    /// @param tokenId1 The ID of the first Evolver token.
    /// @param tokenId2 The ID of the second Evolver token.
    function mergeEvolvers(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert InvalidTokenId();
        if (tokenId1 == tokenId2) revert InvalidTokenId(); // Cannot merge with self

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Check if owner is the same for both, and caller is owner or delegate
        if (owner1 != owner2) revert MergeRequirementsNotMet();
        address actualOwner = _stakedTokens[tokenId1] ? _originalOwners[tokenId1] : owner1;
         if (!_isDelegate(msg.sender, actualOwner)) revert NotOwnerOrDelegate();


        if (_stakedTokens[tokenId1] || _stakedTokens[tokenId2]) revert CannotMergeStakedTokens();

        EvolverAttributes storage attrs1 = _evolverAttributes[tokenId1];
        EvolverAttributes storage attrs2 = _evolverAttributes[tokenId2];

        // Example Merge Logic: Require minimum levels, consume points from one token, average attributes + bonus
        uint256 requiredPoints = 2000; // Example cost
         _updateEvolutionPoints(tokenId1); // Update points before checking
         if (_evolutionPoints[tokenId1] < requiredPoints) revert InsufficientEvolutionPoints();
         _evolutionPoints[tokenId1] -= requiredPoints;

        uint8 newLevel = uint8((uint256(attrs1.level) + uint256(attrs2.level)) / 2 + 1); // Average level + bonus
        uint16 newPower = uint16((uint256(attrs1.power) + uint256(attrs2.power)) / 2 + 50); // Average power + bonus
        uint8 newAffinity = attrs1.affinity; // Example: Inherit affinity from first token
        uint256 newEntropy = (attrs1.entropyLevel + attrs2.entropyLevel) / 2; // Average entropy

        if (newLevel > MAX_EVOLVER_LEVEL) newLevel = MAX_EVOLVER_LEVEL; // Cap level

        // Burn the original tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint the new token
        uint256 newTokenId = _nextTokenId++;
        _safeMint(actualOwner, newTokenId);

        _evolverAttributes[newTokenId] = EvolverAttributes({
            level: newLevel,
            power: newPower,
            affinity: newAffinity,
            entropyLevel: newEntropy,
            catalystEndTime: 0
        });
         _setTokenURI(newTokenId, string(abi.encodePacked(baseURI(), uint256(newTokenId).toString())));
        _lastPointUpdateTime[newTokenId] = uint48(block.timestamp); // Initialize timer


        emit EvolversMerged(tokenId1, tokenId2, newTokenId);
    }

    /// @notice Reduces an Evolver's entropy level.
    /// @param tokenId The ID of the Evolver token.
    function refreshEntropy(uint256 tokenId) public whenNotPaused nonReentrant {
         if (!_exists(tokenId)) revert InvalidTokenId();
        address owner = ownerOf(tokenId);
        address actualOwner = _stakedTokens[tokenId] ? _originalOwners[tokenId] : owner;
        if (!_isDelegate(msg.sender, actualOwner)) revert NotOwnerOrDelegate();

        EvolverAttributes storage attrs = _evolverAttributes[tokenId];

        // Calculate current accrued entropy and add to base
        attrs.entropyLevel = _calculateEntropy(tokenId); // Update the stored value
         _lastPointUpdateTime[tokenId] = uint48(block.timestamp); // Reset timer for entropy calculation baseline

        // Consume points to reduce entropy
        uint256 cost = ENTROPY_REFRESH_COST_POINTS;
         _updateEvolutionPoints(tokenId); // Update points before checking
         if (_evolutionPoints[tokenId] < cost) revert InsufficientEvolutionPoints();
         _evolutionPoints[tokenId] -= cost;

        // Reduce entropy (example: halve it)
        attrs.entropyLevel /= 2;

        emit EvolverEntropyRefreshed(tokenId, attrs.entropyLevel);
    }


    // --- Gamification & Challenges ---

    /// @notice Creates a new challenge. Only callable by the owner.
    /// @param rewardAmount The amount of ETH or ERC20 reward for the winner(s).
    /// @param entryFee The cost for a participant to register (in evolution points or potentially another resource).
    /// @param registrationDeadline The timestamp when registration for this challenge closes.
    function createChallenge(uint256 rewardAmount, uint256 entryFee, uint48 registrationDeadline) public onlyOwner whenNotPaused nonReentrant {
        uint256 challengeId = _createChallengeId();
        _challenges[challengeId] = ChallengeState({
            registrationDeadline: registrationDeadline,
            resolutionTime: 0,
            rewardAmount: rewardAmount,
            entryFee: entryFee,
            oracleDataHash: 0, // Will be set by oracle
            oracleData: "", // Will be set by oracle
            participants: new address[](0), // Not storing tokenIds here directly due to mapping complexity
            winners: new uint256[](0),
            currentStatus: ChallengeState.Status.OpenForRegistration
        });
        // Initialize participants list mapping for this challenge
        _challengeParticipantsList[challengeId] = new uint256[](0);

        emit ChallengeCreated(challengeId, rewardAmount, registrationDeadline);
    }


    /// @notice Registers an Evolver NFT for a specific challenge. Stakes the token and deducts the entry fee.
    /// @param challengeId The ID of the challenge to register for.
    /// @param tokenId The ID of the Evolver token to register.
    function registerForChallenge(uint256 challengeId, uint256 tokenId) public payable whenNotPaused nonReentrant {
        if (!_exists(tokenId)) revert InvalidTokenId();
        address owner = ownerOf(tokenId);
        address actualOwner = _stakedTokens[tokenId] ? _originalOwners[tokenId] : owner;
        if (!_isDelegate(msg.sender, actualOwner)) revert NotOwnerOrDelegate();

        ChallengeState storage challenge = _challenges[challengeId];
        if (challenge.currentStatus != ChallengeState.Status.OpenForRegistration) revert ChallengeNotOpenForRegistration();
        if (block.timestamp > challenge.registrationDeadline) {
             challenge.currentStatus = ChallengeState.Status.ClosedForRegistration; // Auto-close registration
             revert ChallengeRegistrationClosed();
        }
        if (_stakedTokens[tokenId]) revert AlreadyStaked(); // Cannot register staked tokens

        // Handle entry fee (example using evolution points)
        // Could be modified to require ETH or ERC20 transfer
        uint256 entryFee = challenge.entryFee;
         _updateEvolutionPoints(tokenId); // Update points before checking
         if (_evolutionPoints[tokenId] < entryFee) revert InsufficientEvolutionPoints();
         _evolutionPoints[tokenId] -= entryFee;


        // Stake the token in the contract (transferred to contract address)
        _originalOwners[tokenId] = actualOwner; // Store original owner
        _safeTransfer(actualOwner, address(this), tokenId, false); // Transfer ownership

        // Mark as staked, but differently from regular staking if needed
        // For now, let's reuse _stakedTokens and add to challenge list
         _stakedTokens[tokenId] = true; // Token is now held by contract
         _lastPointUpdateTime[tokenId] = uint48(block.timestamp); // Reset timer? Decide how points work during challenge

        _challengeParticipantsList[challengeId].push(tokenId);

        emit ChallengeRegistered(challengeId, tokenId, actualOwner);
    }


    /// @notice Called by the oracle to submit external data required for challenge resolution.
    /// @param challengeId The ID of the challenge.
    /// @param oracleData The data provided by the oracle.
    function submitOracleDataForChallenge(uint256 challengeId, bytes calldata oracleData) public onlyOracle nonReentrant {
        ChallengeState storage challenge = _challenges[challengeId];
        if (challenge.currentStatus != ChallengeState.Status.ClosedForRegistration && challenge.currentStatus != ChallengeState.Status.OracleDataAwaiting) {
             revert ChallengeNotAwaitingOracleData();
        }
        if (block.timestamp <= challenge.registrationDeadline) {
             // Should not happen if called after deadline, but add check
             revert ChallengeRegistrationClosed();
        }
        if (challenge.currentStatus == ChallengeState.Status.ClosedForRegistration) {
             challenge.currentStatus = ChallengeState.Status.OracleDataAwaiting;
        }

        // In a real system, you'd hash the expected data client-side
        // and the oracle would submit the data + proof, verified here.
        // For this example, we just store the data.
        challenge.oracleData = oracleData;
        // Set status to resolved or ready for resolution by owner/keeper
        // Let's set it to Awaiting, and owner/keeper calls resolveChallenge
         challenge.currentStatus = ChallengeState.Status.OracleDataAwaiting;


        emit OracleDataSubmitted(challengeId, oracleData);
    }


    /// @notice Resolves a challenge, determines winners, and distributes rewards. Callable by owner or keeper.
    /// @param challengeId The ID of the challenge to resolve.
    function resolveChallenge(uint256 challengeId) public onlyOwner nonReentrant { // Could add a separate keeper role
        ChallengeState storage challenge = _challenges[challengeId];
        if (challenge.currentStatus != ChallengeState.Status.OracleDataAwaiting) {
             revert ChallengeNotAwaitingOracleData();
        }
        if (challenge.oracleData.length == 0) {
             // Requires oracle data to be submitted
             revert ChallengeNotAwaitingOracleData();
        }
        if (challenge.resolutionTime > 0) revert ChallengeAlreadyResolved(); // Already resolved

        // Get participants
        uint256[] storage participants = _challengeParticipantsList[challengeId];

        // Determine winners based on logic (uses Evolver attributes + oracle data)
        uint256[] memory winners = _resolveChallengeLogic(challengeId);
        challenge.winners = winners;

        // Distribute rewards (example: distribute ETH or ERC20 collected from fees/pre-funded)
        uint256 totalReward = challenge.rewardAmount;
        uint256 numWinners = winners.length;

        if (numWinners > 0 && totalReward > 0) {
             // Assuming rewards are collected in the contract balance (ETH or optionalRewardToken)
            uint256 rewardPerWinner = totalReward / numWinners;
            for (uint256 i = 0; i < numWinners; i++) {
                 uint256 winningTokenId = winners[i];
                 address originalOwner = _originalOwners[winningTokenId]; // Get owner before staking
                 if (originalOwner != address(0)) { // Ensure valid owner
                     // Send reward (ETH or ERC20)
                     if (optionalRewardToken == address(0)) {
                         // ETH reward
                         payable(originalOwner).sendValue(rewardPerWinner);
                     } else {
                         // ERC20 reward
                         IERC20(optionalRewardToken).transfer(originalOwner, rewardPerWinner);
                     }
                 }
            }
        }

        // Unstake all participating tokens and return to original owners
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 participantTokenId = participants[i];
            address originalOwner = _originalOwners[participantTokenId];
            if (originalOwner != address(0) && ownerOf(participantTokenId) == address(this)) {
                _stakedTokens[participantTokenId] = false;
                 delete _originalOwners[participantTokenId];
                 // Transfer token back
                 ERC721(address(this)).safeTransferFrom(address(this), originalOwner, participantTokenId);
            }
            // Clear points earned during challenge? Or let them keep them? Let's clear them for simplicity.
            _evolutionPoints[participantTokenId] = 0;
        }
         delete _challengeParticipantsList[challengeId]; // Clear list after resolution

        challenge.resolutionTime = uint48(block.timestamp);
        challenge.currentStatus = ChallengeState.Status.Resolved;

        emit ChallengeResolved(challengeId, totalReward, winners);
    }


    /// @notice Gets the current state and parameters of a challenge.
    /// @param challengeId The ID of the challenge.
    /// @return ChallengeState The state struct for the challenge.
    function getChallengeState(uint256 challengeId) public view returns (ChallengeState memory) {
        if (challengeId == 0 || challengeId > _nextChallengeId) revert InvalidChallengeId();
        return _challenges[challengeId];
    }

    /// @notice Gets the list of Evolver token IDs participating in a challenge.
    /// @param challengeId The ID of the challenge.
    /// @return tokenIds Array of token IDs participating.
    function getChallengeParticipants(uint256 challengeId) public view returns (uint256[] memory) {
         if (challengeId == 0 || challengeId > _nextChallengeId) revert InvalidChallengeId();
        return _challengeParticipantsList[challengeId];
    }


    // --- State-Dependent Ability (Catalyst) ---

    /// @notice Called by the oracle to trigger the Catalyst status for an Evolver.
    /// This status grants temporary bonuses (e.g., faster point gain).
    /// @param tokenId The ID of the Evolver token.
    /// @param duration The duration in seconds for which the Catalyst status is active.
    function triggerCatalystStatusByOracle(uint256 tokenId, uint48 duration) public onlyOracle whenNotPaused nonReentrant {
        if (!_exists(tokenId)) revert InvalidTokenId();
        EvolverAttributes storage attrs = _evolverAttributes[tokenId];

        uint48 endTime = uint48(block.timestamp + duration);
        attrs.catalystEndTime = endTime;

        // Update points when status changes to capture accrued points before the boost
        _updateEvolutionPoints(tokenId);

        emit CatalystStatusTriggered(tokenId, endTime);
    }


    /// @notice Checks if an Evolver is currently in its Catalyst status.
    /// @param tokenId The ID of the Evolver token.
    /// @return bool True if the Evolver is currently Catalyst, false otherwise.
    function checkCatalystStatus(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        EvolverAttributes storage attrs = _evolverAttributes[tokenId];
        return attrs.catalystEndTime > uint48(block.timestamp);
    }


    // --- Delegation ---

    /// @notice Allows an owner to set or revoke delegation rights for specific actions to another address.
    /// @param delegate The address to grant or revoke delegation rights.
    /// @param allowed True to grant delegation, false to revoke.
    function setDelegate(address delegate, bool allowed) public whenNotPaused {
        if (delegate == address(0)) revert ZeroAddressNotAllowed();
        _delegates[msg.sender][delegate] = allowed;
        emit DelegateSet(msg.sender, delegate, allowed);
    }

    /// @notice Checks if an address is a delegate for another address.
    /// @param delegator The address whose delegation rights are being checked.
    /// @param delegatee The address that may or may not be a delegate.
    /// @return bool True if delegatee is a delegate for delegator, false otherwise.
    function isDelegate(address delegator, address delegatee) public view returns (bool) {
        return _isDelegate(delegator, delegatee);
    }


    // --- Admin/Utility ---

    /// @notice Sets the address of the trusted oracle contract. Only callable by owner.
    /// @param newOracle The address of the new oracle contract.
    function setOracleAddress(address newOracle) public onlyOwner {
        if (newOracle == address(0)) revert ZeroAddressNotAllowed();
        oracleAddress = newOracle;
    }

     /// @notice Sets the optional ERC20 token address for rewards/fees. Only callable by owner.
    /// @param tokenAddress The address of the ERC20 token. Set to address(0) for ETH.
    function setOptionalRewardToken(address tokenAddress) public onlyOwner {
        optionalRewardToken = tokenAddress;
    }


    /// @notice Pauses contract functionality. Only callable by owner.
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses contract functionality. Only callable by owner.
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Allows the owner to rescue accidentally sent ETH from the contract.
    /// @param amount The amount of ETH to withdraw.
    function rescueETH(uint256 amount) public onlyOwner nonReentrant {
        payable(owner()).sendValue(amount);
    }

    /// @notice Allows the owner to rescue accidentally sent ERC20 tokens from the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    // --- Internal ERC721 Overrides for Enumerable/URIStorage ---

    function _safeTransfer(address from, address to, uint256 tokenId, bool requireReceiver) internal override(ERC721, ERC721Enumerable) {
        super._safeTransfer(from, to, tokenId, requireReceiver);
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFTs (Mutable Attributes):** Evolvers aren't static JPEGs. Their `level`, `power`, `affinity`, `evolutionPoints`, `entropyLevel`, and `catalystEndTime` are state variables tied to the token ID. This allows the NFT to change and "grow" on-chain based on interaction. (`EvolverAttributes` struct, mappings, functions like `levelUpEvolver`, `mergeEvolvers`, `refreshEntropy`).
2.  **Gamified Staking (Evolution Points):** Staking isn't just about earning governance tokens. It's about earning a resource (`evolutionPoints`) used *within* the ecosystem to improve the asset itself (leveling up, refreshing entropy, potentially paying challenge fees). The rate of earning can be state-dependent (Catalyst status). (`stakeEvolver`, `unstakeEvolver`, `claimEvolutionPoints`, `_updateEvolutionPoints`).
3.  **Asset Merging (Burning & Minting with Derived Attributes):** `mergeEvolvers` is a non-standard ERC-721 operation. It burns existing tokens and creates a new one, with attributes derived from the components, adding a layer of strategy and asset sink mechanism.
4.  **Entropy / Degradation:** The `entropyLevel` adds a unique mechanic where assets degrade over time or with actions, requiring maintenance (`refreshEntropy`). This introduces a strategic cost to ownership and usage, contrasting with typical non-depreciating digital assets.
5.  **Oracle-Driven State Changes (Catalyst Status):** The `triggerCatalystStatusByOracle` function demonstrates how external, real-world events or data (delivered via a trusted oracle) can directly impact the *on-chain state and abilities* of an NFT. This is a powerful pattern for connecting NFTs to external conditions (weather, sports scores, market data, in-game events calculated off-chain).
6.  **On-Chain Challenges/Events:** The challenge system (`createChallenge`, `registerForChallenge`, `submitOracleDataForChallenge`, `resolveChallenge`) provides a framework for structured interactions where NFT attributes and external data combine to determine outcomes and distribute rewards. This moves beyond simple ownership to active participation.
7.  **Delegated Actions:** The `setDelegate` and `_isDelegate` logic allows token owners to authorize other addresses (e.g., a gaming account, a yield farming manager, a friend) to perform specific actions *on behalf of the owner* without transferring ownership of the NFT itself. This is crucial for complex dApps or gaming where a user might not want to sign every micro-transaction with their main wallet.
8.  **Structured Data:** Using structs (`EvolverAttributes`, `ChallengeState`) organizes complex data efficiently.
9.  **Custom Errors:** Using `error` keywords provides more gas-efficient and informative error handling compared to `require` with strings.

This contract provides a foundation for a complex ecosystem centered around NFTs that are living, evolving entities rather than static collectibles.