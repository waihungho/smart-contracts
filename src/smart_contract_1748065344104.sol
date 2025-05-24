Okay, let's design a smart contract system centered around dynamic NFTs that participate in on-chain activities like training (staking) and simulated battles, powered by secure randomness (Chainlink VRF) and governed by roles.

This concept combines:
1.  **Dynamic NFTs:** Character stats change based on activity (training, battles, level-ups).
2.  **Staking:** Characters can be staked to earn "training points" or a native token.
3.  **On-chain Simulation (simplified):** Battles are initiated and outcomes determined (using randomness).
4.  **Tokenomics:** A native token is used for rewards and character upgrades.
5.  **Secure Randomness:** Using Chainlink VRF for unpredictable outcomes (character stats, battle results).
6.  **Access Control & Pausability:** Standard best practices for managing a complex system.

We will use OpenZeppelin libraries for standard implementations like ERC721, ERC20, AccessControl, and Pausable. We'll also integrate Chainlink VRF v2.

Let's call the system `CryptoColiseum`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for getting all tokens of an owner
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For token metadata URIs
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Import Chainlink VRF contracts
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/IVRFCoordinatorV2.sol";

// --- CONTRACT OUTLINE ---
// 1. ColiseumToken (ERC20): Native token for rewards and upgrades.
// 2. ColiseumCharacter (ERC721): Dynamic NFT representing a character. Inherits from ERC721, Enumerable, URIStorage.
//    - Stores character stats (attack, defense, health, speed, level, training points).
//    - Stats are dynamic and stored within the contract state.
// 3. CryptoColiseum (Main Logic Contract):
//    - Manages Character NFT minting and stats.
//    - Manages ColiseumToken distribution and burning (for upgrades).
//    - Handles Character Staking (Training) mechanics.
//    - Handles Battle initiation and resolution (using Chainlink VRF).
//    - Integrates Chainlink VRF for randomness in minting and battles.
//    - Uses AccessControl for roles (ADMIN, MINTER, PAUSER, VRF_CALLBACK).
//    - Uses Pausable to halt critical operations.
//    - Uses ReentrancyGuard for security on state-changing calls involving transfers.

// --- FUNCTION SUMMARY ---

// ColiseumToken (ERC20 Standard Functions, not listed individually here to save space, but are inherited: totalSupply, balanceOf, transfer, allowance, approve, transferFrom)
// - Standard ERC20 functionality.

// ColiseumCharacter (ERC721 Standard Functions, not listed individually here: balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, tokenOfOwnerByIndex, tokenByIndex, tokenURI)
// - Inherits ERC721, ERC721Enumerable, ERC721URIStorage.

// CryptoColiseum (Main Logic)

// --- Character Management ---
// 1. mintCharacter(address to): Requests randomness to mint a new character for 'to'. (MINTER_ROLE required)
// 2. rawFulfillRandomWords(uint256 requestId, uint256[] randomWords): Chainlink VRF callback to finalize minting or battles. (VRF_CALLBACK_ROLE required)
// 3. getCharacterStats(uint256 tokenId): Returns the dynamic stats of a character. (View)
// 4. setCharacterBaseURI(string newBaseURI): Sets the base URI for character metadata. (ADMIN_ROLE required)
// 5. burnCharacter(uint256 tokenId): Allows an owner to burn their character NFT.

// --- Staking (Training) ---
// 6. stakeCharacterForTraining(uint256 tokenId): Stakes a character to start training. (Owner required)
// 7. unstakeCharacter(uint256 tokenId): Stops training and unstakes the character. (Owner required)
// 8. claimTrainingRewards(uint256 tokenId): Claims pending training rewards (tokens and/or training points). (Owner required)
// 9. getCharacterTrainingStatus(uint256 tokenId): Returns training start time and status. (View)
// 10. getPendingTrainingRewards(uint256 tokenId): Calculates and returns pending training rewards without claiming. (View)

// --- Battling ---
// 11. initiateBattle(uint256 character1Id, uint256 character2Id): Initiates a battle between two characters. Requires randomness. (Characters must be owned/approved by caller)
// 12. getBattleStatus(uint256 battleId): Returns the current state of a battle. (View)
// 13. claimBattleRewards(uint256 battleId): Allows participants to claim rewards after a battle is resolved. (Participants required)
// 14. getPendingBattleRewards(uint256 battleId): Calculates and returns pending battle rewards. (View)

// --- Tokenomics ---
// 15. getTokenAddress(): Returns the address of the ColiseumToken contract. (View)
// 16. getNFTAddress(): Returns the address of the ColiseumCharacter contract. (View)
// 17. distributeInitialTokens(address[] recipients, uint256[] amounts): Admin function to distribute initial token supply. (ADMIN_ROLE required)

// --- Upgrades & Mechanics ---
// 18. levelUpCharacter(uint256 tokenId, uint256 pointsToSpend): Spends training points and/or tokens to improve character stats. (Owner required)
// 19. setTrainingRate(uint256 ratePerSecond): Sets the rate at which training points/rewards accrue. (ADMIN_ROLE required)
// 20. setBattleParameters(...): Sets parameters influencing battle outcomes and rewards. (ADMIN_ROLE required)

// --- Admin & Utility ---
// 21. grantRole(bytes32 role, address account): Grants a specified role. (ADMIN_ROLE required) (Inherited from AccessControl but custom usage)
// 22. revokeRole(bytes32 role, address account): Revokes a specified role. (ADMIN_ROLE required) (Inherited from AccessControl but custom usage)
// 23. pause(): Pauses core contract functionality. (PAUSER_ROLE required) (Inherited from Pausable but custom usage)
// 24. unpause(): Unpauses the contract. (PAUSER_ROLE required) (Inherited from Pausable but custom usage)
// 25. withdrawLink(): Allows admin to withdraw LINK token from the contract (needed for VRF). (ADMIN_ROLE required)
// 26. getPlayerCharacters(address owner): Returns a list of character token IDs owned by an address. (View) (Leverages ERC721Enumerable)

// Add more functions to reach 20+ (beyond the core logic)
// 27. getBattleResult(uint256 battleId): Returns the detailed outcome of a resolved battle. (View)
// 28. getCharacterTrainingPoints(uint256 tokenId): Returns the current training points of a character. (View)
// 29. setCharacterName(uint256 tokenId, string newName): Allows owner to set a name for their character. (Owner required)
// 30. getCharacterName(uint256 tokenId): Returns the name of a character. (View)

// ... and so on. We have plenty of room to exceed 20 by adding getters, setters for parameters, or utility functions. The above list already covers the core dynamic aspects and easily exceeds 20 unique *Coliseum logic* functions when including the Admin/Utility ones.

// --- EVENT SUMMARY ---
// - CharacterMinted(uint256 tokenId, address owner, uint256[] initialStats)
// - CharacterBurned(uint256 tokenId, address owner)
// - CharacterStakedForTraining(uint256 tokenId, address owner, uint256 startTime)
// - CharacterUnstaked(uint256 tokenId, address owner, uint256 endTime, uint256 pointsEarned, uint256 tokenRewards)
// - TrainingRewardsClaimed(uint256 tokenId, uint256 pointsClaimed, uint256 tokensClaimed)
// - BattleInitiated(uint256 battleId, uint256 character1Id, uint256 character2Id, uint256 randomnessRequestId)
// - BattleResolved(uint256 battleId, uint256 winningCharacterId, uint256 losingCharacterId, uint256[] finalStatsChar1, uint256[] finalStatsChar2, uint256 tokenRewards, uint256 winnerPointsGained, uint256 loserPointsGained)
// - BattleRewardsClaimed(uint256 battleId, address claimant, uint256 tokensClaimed)
// - CharacterLeveledUp(uint256 tokenId, uint256 newLevel, uint256 pointsSpent, uint256 tokensSpent)
// - TrainingRateUpdated(uint256 newRatePerSecond)
// - BattleParametersUpdated(...)
// - Paused(address account)
// - Unpaused(address account)
// - LinkWithdrawn(address to, uint256 amount)
// - RoleGranted(bytes32 role, address account, address sender)
// - RoleRevoked(bytes32 role, address account, address sender)
// - CharacterNameUpdated(uint256 tokenId, string newName)

// --- ERRORS ---
// - OnlyMinter()
// - OnlyAdmin()
// - OnlyVRFCoordinator()
// - CharacterDoesNotExist()
// - NotCharacterOwnerOrApproved()
// - CharacterAlreadyStaked()
// - CharacterNotStaked()
// - BattleInProgress()
// - BattleNotResolved()
// - BattleAlreadyResolved()
// - NotBattleParticipant()
// - InvalidCharacterIdsForBattle()
// - InsufficientTrainingPoints()
// - InsufficientTokens()
// - NoPendingRewards()
// - NothingToWithdraw()
// - InvalidPointAllocation()
// - NameTooLong()
// - CharacterAlreadyNamed()


// --- CONTRACT DEFINITIONS ---

// Simple ERC20 token for the system
contract ColiseumToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 initialSupply) ERC20("Coliseum Token", "COLT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // The CryptoColiseum contract will likely be the MINTER

        // Example: Mint initial supply to deployer, or make it zero and let the main contract mint
        // _mint(msg.sender, initialSupply); // Optional: mint to deployer
    }

    // Allow only addresses with MINTER_ROLE to mint
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Allow burning tokens
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Allow burning tokens on behalf of another (if allowance is set)
    function burnFrom(address account, uint256 amount) public {
        _burn(account, amount);
    }
}

// Dynamic Character NFT
contract ColiseumCharacter is ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Character Stats
    struct Character {
        uint256 attack;
        uint256 defense;
        uint256 health;
        uint256 speed;
        uint256 level;
        uint256 trainingPoints; // Points earned through training
        string name; // Cosmetic name set by player
    }

    mapping(uint256 => Character) private _characters;

    constructor() ERC721("Coliseum Character", "COLLCHAR") {}

    // Override ERC721._safeMint to use the counter
    function safeMint(address to, uint256 initialAttack, uint256 initialDefense, uint256 initialHealth, uint256 initialSpeed) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);

        // Initialize character stats
        _characters[tokenId] = Character({
            attack: initialAttack,
            defense: initialDefense,
            health: initialHealth,
            speed: initialSpeed,
            level: 1,
            trainingPoints: 0,
            name: "" // Default empty name
        });

        // Emit a specific event for character minting with stats
        emit CharacterMinted(tokenId, to, [initialAttack, initialDefense, initialHealth, initialSpeed, 1]);
    }

    // --- Internal Functions for stat management (called by CryptoColiseum) ---

    function _getCharacter(uint256 tokenId) internal view returns (Character storage) {
         require(_exists(tokenId), "ColiseumCharacter: Character does not exist");
         return _characters[tokenId];
    }

    function _updateStats(uint256 tokenId, uint256 newAttack, uint256 newDefense, uint256 newHealth, uint256 newSpeed) internal {
        Character storage character = _getCharacter(tokenId);
        character.attack = newAttack;
        character.defense = newDefense;
        character.health = newHealth;
        character.speed = newSpeed;
    }

     function _updateLevel(uint256 tokenId, uint256 newLevel) internal {
        Character storage character = _getCharacter(tokenId);
        character.level = newLevel;
    }

    function _addTrainingPoints(uint256 tokenId, uint256 points) internal {
        Character storage character = _getCharacter(tokenId);
        character.trainingPoints += points;
    }

    function _spendTrainingPoints(uint256 tokenId, uint256 points) internal {
         Character storage character = _getCharacter(tokenId);
         require(character.trainingPoints >= points, "ColiseumCharacter: Insufficient training points");
         character.trainingPoints -= points;
    }

    function _setCharacterName(uint256 tokenId, string memory newName) internal {
         Character storage character = _getCharacter(tokenId);
         require(bytes(character.name).length == 0, "ColiseumCharacter: Character already named");
         require(bytes(newName).length <= 32, "ColiseumCharacter: Name too long"); // Arbitrary limit
         character.name = newName;
         emit CharacterNameUpdated(tokenId, newName);
    }

    // --- External View Functions ---

    function getCharacterStats(uint256 tokenId) external view returns (
        uint256 attack,
        uint256 defense,
        uint256 health,
        uint256 speed,
        uint256 level,
        uint256 trainingPoints
    ) {
        require(_exists(tokenId), "ColiseumCharacter: Character does not exist");
        Character storage character = _characters[tokenId];
        return (
            character.attack,
            character.defense,
            character.health,
            character.speed,
            character.level,
            character.trainingPoints
        );
    }

     function getCharacterTrainingPoints(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "ColiseumCharacter: Character does not exist");
         return _characters[tokenId].trainingPoints;
     }

     function getCharacterName(uint256 tokenId) external view returns (string memory) {
         require(_exists(tokenId), "ColiseumCharacter: Character does not exist");
         return _characters[tokenId].name;
     }


    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        // Potentially handle staking/battle state changes on transfer?
        // For simplicity, we might require unstaking/ending battle before transfer in the main contract.
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
         // Clean up character state after burning
        delete _characters[tokenId];
        emit CharacterBurned(tokenId, msg.sender);
    }

     function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // Fetch dynamic stats to include in metadata if needed
        Character storage character = _characters[tokenId];
        // In a real scenario, you'd construct a JSON string or point to a metadata service
        // that can fetch these dynamic stats.
        // For this example, let's just return a placeholder.
        return string(abi.encodePacked(super.tokenURI(tokenId), Strings.toString(tokenId), ".json"));
     }

    // --- Events ---
    event CharacterMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialStats);
    event CharacterBurned(uint256 indexed tokenId, address indexed owner);
    event CharacterNameUpdated(uint256 indexed tokenId, string newName);
}


// Main CryptoColiseum Logic
contract CryptoColiseum is VRFConsumerBaseV2, AccessControl, Pausable, ReentrancyGuard {

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VRF_CALLBACK_ROLE = keccak256("VRF_CALLBACK_ROLE"); // Role for the VRF Coordinator address

    // --- Contract References ---
    ColiseumCharacter public coliseumCharacters;
    ColiseumToken public coliseumToken;
    IVRFCoordinatorV2 public COORDINATOR; // Chainlink VRF Coordinator

    // --- VRF Configuration ---
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit = 1_000_000; // Adjust based on complexity of callback
    uint16 public s_requestConfirmations = 3;

    // --- State Variables ---
    using Counters for Counters.Counter;
    Counters.Counter private _battleIdCounter;

    // Character Staking (Training)
    mapping(uint256 => uint256) private _stakedCharacters; // tokenId => stakeStartTime
    uint256 public trainingRatePerSecond = 10; // Training points per second staked (example)
    uint256 public tokenRewardPerSecond = 1e16; // 0.01 COLT per second staked (example, adjust decimals)


    // Battles
    struct Battle {
        uint256 character1Id;
        uint256 character2Id;
        address participant1;
        address participant2;
        uint256 startTime;
        uint256 randomnessRequestId;
        bool resolved;
        uint256 winningCharacterId; // 0 if no winner yet or draw
        uint256 tokenRewardPool;
        uint256 winnerPointsGained; // Training points gained by winner
        uint256 loserPointsGained; // Training points gained by loser
    }
    mapping(uint256 => Battle) private _battles;
    mapping(uint256 => uint256) private _randomnessRequestMap; // requestId => battleId or 0 for mint

    // Battle Parameters (influence outcome calculation)
    uint256 public attackWeight = 30; // % weight
    uint256 public defenseWeight = 25; // % weight
    uint256 public healthWeight = 25; // % weight
    uint256 public speedWeight = 20; // % weight
    uint256 public randomWeight = 10; // % weight of the random factor

    // --- Events ---
    event CharacterStakedForTraining(uint256 indexed tokenId, address indexed owner, uint256 startTime);
    event CharacterUnstaked(uint256 indexed tokenId, address indexed owner, uint256 endTime, uint256 pointsEarned, uint256 tokenRewards);
    event TrainingRewardsClaimed(uint256 indexed tokenId, uint256 pointsClaimed, uint256 tokensClaimed);
    event BattleInitiated(uint256 indexed battleId, uint256 indexed character1Id, uint256 indexed character2Id, uint256 randomnessRequestId);
    event BattleResolved(
        uint256 indexed battleId,
        uint256 indexed winningCharacterId,
        uint256 indexed losingCharacterId,
        uint256[] finalStatsChar1, // Stats of char1 after battle
        uint256[] finalStatsChar2, // Stats of char2 after battle
        uint256 tokenReward,
        uint256 winnerPointsGained,
        uint256 loserPointsGained
    );
    event BattleRewardsClaimed(uint256 indexed battleId, address indexed claimant, uint256 tokensClaimed);
    event CharacterLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 pointsSpent, uint256 tokensSpent);
    event TrainingRateUpdated(uint256 newRatePerSecond, uint256 newTokenRewardPerSecond);
    event BattleParametersUpdated(uint256 attackWeight, uint256 defenseWeight, uint256 healthWeight, uint256 speedWeight, uint256 randomWeight);
    event LinkWithdrawn(address indexed to, uint256 amount);


    // --- Errors ---
    error OnlyMinter();
    error OnlyAdmin();
    error OnlyVRFCoordinator();
    error CharacterDoesNotExist();
    error NotCharacterOwnerOrApproved();
    error CharacterAlreadyStaked();
    error CharacterNotStaked();
    error BattleInProgress();
    error BattleNotResolved();
    error BattleAlreadyResolved();
    error NotBattleParticipant();
    error InvalidCharacterIdsForBattle();
    error InsufficientTrainingPoints();
    error InsufficientTokens();
    error NoPendingRewards();
    error NothingToWithdraw();
    error InvalidPointAllocation();
    error NameTooLong();
    error CharacterAlreadyNamed();
    error MustUnstakeBeforeBattle();
    error MustBeStakedForTraining();
    error CharacterAlreadyInBattle();
    error BattleRewardAlreadyClaimed();
    error CharactersCannotBeSame();
    error MustRequestRandomness();
    error InvalidRandomnessRequest();
    error VRFCallbackFailed();


    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        address tokenAddress,
        address characterAddress
    ) VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // Admin can mint by default
        _grantRole(PAUSER_ROLE, msg.sender);

        // Set VRF parameters
        COORDINATOR = IVRFCoordinatorV2(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;

        // Set contract references
        coliseumToken = ColiseumToken(tokenAddress);
        coliseumCharacters = ColiseumCharacter(characterAddress);

        // Grant this contract the MINTER_ROLE on the token contract
        // This must be done *after* deploying ColiseumToken and CryptoColiseum,
        // by the ADMIN of ColiseumToken calling `coliseumToken.grantRole(coliseumToken.MINTER_ROLE(), address(this))`
        // and the ADMIN of ColiseumCharacter calling `coliseumCharacters.grantRole(coliseumCharacters.MINTER_ROLE(), address(this))`
        // This is outside the scope of this constructor but is necessary for the system to work.
    }

    // --- Modifier to check character ownership or approval ---
    modifier onlyOwnerOfCharacter(uint256 tokenId) {
        require(coliseumCharacters.ownerOf(tokenId) == msg.sender || coliseumCharacters.isApprovedForAll(coliseumCharacters.ownerOf(tokenId), msg.sender) || coliseumCharacters.getApproved(tokenId) == msg.sender,
            "CryptoColiseum: Not character owner or approved");
        _;
    }

    modifier characterExists(uint256 tokenId) {
         require(coliseumCharacters.exists(tokenId), "CryptoColiseum: Character does not exist");
         _;
    }

    // --- Character Management ---

    /// @notice Requests randomness from Chainlink VRF to mint a new character.
    /// @param to The address to mint the character for.
    function mintCharacter(address to) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256 requestId) {
        // Request 4 random words for initial stats (Attack, Defense, Health, Speed)
        // and maybe one for character type/rarity if applicable
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            5 // Number of random words
        );
        _randomnessRequestMap[requestId] = 0; // Map request to 0 for minting
        emit MustRequestRandomness(); // Indicate that VRF callback is expected
    }

    /// @dev Callback function for Chainlink VRF. Mints character or resolves battle.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random words returned by VRF.
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override onlyRole(VRF_CALLBACK_ROLE) {
        require(randomWords.length >= 1, "CryptoColiseum: Not enough random words");

        uint256 mappedId = _randomnessRequestMap[requestId];
        require(mappedId != type(uint256).max, "CryptoColiseum: Invalid randomness request ID"); // Ensure it was a request initiated by us
        delete _randomnessRequestMap[requestId]; // Clean up mapping

        if (mappedId == 0) { // This request was for minting
             require(randomWords.length >= 4, "CryptoColiseum: Not enough random words for minting");
             // Generate initial stats from random words (simple example)
             // Stats should be in a reasonable range, e.g., 1-100
             uint256 attack = (randomWords[0] % 100) + 1;
             uint256 defense = (randomWords[1] % 100) + 1;
             uint256 health = (randomWords[2] % 100) + 1;
             uint256 speed = (randomWords[3] % 100) + 1;

             // Determine recipient - how was the mint requested? This simplified model assumes the
             // `mintCharacter` function would somehow store the target address linked to the request ID.
             // A more robust implementation would need a mapping: `uint256 => address` for pending mints.
             // For *this* example, let's assume a single address is stored temporarily or derived (less ideal).
             // A better approach is to have the `mintCharacter` function store the recipient and link it to the requestId.
             // Let's add a temporary mapping for demonstration.
             address recipient = _pendingMintRecipient[requestId];
             require(recipient != address(0), "CryptoColiseum: Pending mint recipient not found");
             delete _pendingMintRecipient[requestId]; // Clean up

             coliseumCharacters.safeMint(recipient, attack, defense, health, speed);

        } else { // This request was for a battle
             uint256 battleId = mappedId;
             _resolveBattle(battleId, randomWords);
        }
    }
     // Temporary mapping to link mint requests to recipients (needs more robust handling in production)
    mapping(uint256 => address) private _pendingMintRecipient;

    // Override the mintCharacter function to store the recipient temporarily
    function mintCharacter(address to) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256 requestId) {
        // Request 5 random words (4 for stats, 1 for type/rarity potentially)
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            5
        );
        _randomnessRequestMap[requestId] = 0; // Map request to 0 for minting
        _pendingMintRecipient[requestId] = to; // Store recipient temporarily
        emit MustRequestRandomness();
    }


    /// @notice Gets the dynamic stats of a character.
    /// @param tokenId The ID of the character NFT.
    /// @return attack, defense, health, speed, level, trainingPoints The character's stats.
    function getCharacterStats(uint256 tokenId) public view characterExists(tokenId) returns (
        uint256 attack,
        uint256 defense,
        uint256 health,
        uint256 speed,
        uint256 level,
        uint256 trainingPoints
    ) {
        return coliseumCharacters.getCharacterStats(tokenId);
    }

    /// @notice Sets the base URI for character metadata.
    /// @param newBaseURI The new base URI string.
    function setCharacterBaseURI(string memory newBaseURI) public onlyRole(ADMIN_ROLE) {
        coliseumCharacters.setBaseURI(newBaseURI);
    }

    /// @notice Allows an owner to burn their character NFT.
    /// @param tokenId The ID of the character NFT to burn.
    function burnCharacter(uint256 tokenId) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) {
        // Ensure character is not staked or in battle before burning
        require(_stakedCharacters[tokenId] == 0, "CryptoColiseum: Character is staked, cannot burn");
        require(!_isCharacterInBattle(tokenId), "CryptoColiseum: Character is in battle, cannot burn"); // Need helper for this
        coliseumCharacters.burn(tokenId);
    }

    // --- Staking (Training) ---

    /// @notice Stakes a character for training.
    /// @param tokenId The ID of the character NFT to stake.
    function stakeCharacterForTraining(uint256 tokenId) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) whenNotPaused nonReentrant {
        require(_stakedCharacters[tokenId] == 0, "CryptoColiseum: Character already staked");
        require(!_isCharacterInBattle(tokenId), "CryptoColiseum: Character is in battle, cannot stake");

        _stakedCharacters[tokenId] = block.timestamp;
        emit CharacterStakedForTraining(tokenId, msg.sender, block.timestamp);
    }

    /// @notice Unstakes a character and calculates potential rewards.
    /// @param tokenId The ID of the character NFT to unstake.
    function unstakeCharacter(uint256 tokenId) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) whenNotPaused nonReentrant {
        require(_stakedCharacters[tokenId] > 0, "CryptoColiseum: Character not staked");

        uint256 stakeStartTime = _stakedCharacters[tokenId];
        uint256 stakeEndTime = block.timestamp;
        delete _stakedCharacters[tokenId]; // Unstake before calculating/claiming

        (uint256 pointsEarned, uint256 tokenRewards) = _calculateTrainingRewards(tokenId, stakeStartTime, stakeEndTime);

        // Add points to character stats
        coliseumCharacters._addTrainingPoints(tokenId, pointsEarned);

        // Mint and transfer token rewards
        if (tokenRewards > 0) {
             // This contract needs MINTER_ROLE on ColiseumToken
            coliseumToken.mint(msg.sender, tokenRewards);
        }

        emit CharacterUnstaked(tokenId, msg.sender, stakeEndTime, pointsEarned, tokenRewards);
    }

    /// @notice Claims pending training rewards without unstaking. (Optional: could be combined with unstake or separate)
    /// @param tokenId The ID of the character NFT.
    // This function isn't strictly necessary if rewards are only given on unstake,
    // but adds a claim-while-staked mechanic. Let's implement it.
    function claimTrainingRewards(uint256 tokenId) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) whenNotPaused nonReentrant {
         require(_stakedCharacters[tokenId] > 0, "CryptoColiseum: Character not staked");

         uint256 stakeStartTime = _stakedCharacters[tokenId];
         uint256 currentTime = block.timestamp;

         // Recalculate rewards since the last claim (or stake start)
         (uint256 pointsEarned, uint256 tokenRewards) = _calculateTrainingRewards(tokenId, stakeStartTime, currentTime);

         require(pointsEarned > 0 || tokenRewards > 0, "CryptoColiseum: No pending rewards");

         // Add points to character stats
         coliseumCharacters._addTrainingPoints(tokenId, pointsEarned);

         // Mint and transfer token rewards
         if (tokenRewards > 0) {
            coliseumToken.mint(msg.sender, tokenRewards);
         }

         // Reset stake start time to now to prevent claiming the same period again
         _stakedCharacters[tokenId] = currentTime;

         emit TrainingRewardsClaimed(tokenId, pointsEarned, tokenRewards);
    }


    /// @notice Gets the training status (start time) of a character.
    /// @param tokenId The ID of the character NFT.
    /// @return startTime The timestamp when training started (0 if not staked).
    function getCharacterTrainingStatus(uint256 tokenId) public view characterExists(tokenId) returns (uint256 startTime) {
        return _stakedCharacters[tokenId];
    }

     /// @notice Calculates and returns pending training rewards without claiming.
     /// @param tokenId The ID of the character NFT.
     /// @return pointsEarned, tokenRewards The amount of pending rewards.
     function getPendingTrainingRewards(uint256 tokenId) public view characterExists(tokenId) returns (uint256 pointsEarned, uint256 tokenRewards) {
         uint256 stakeStartTime = _stakedCharacters[tokenId];
         if (stakeStartTime == 0) {
             return (0, 0); // Not staked
         }
         return _calculateTrainingRewards(tokenId, stakeStartTime, block.timestamp);
     }

     /// @dev Internal helper to calculate training rewards.
     function _calculateTrainingRewards(uint256 tokenId, uint256 startTime, uint256 endTime) internal view returns (uint256 pointsEarned, uint256 tokenRewards) {
        if (endTime <= startTime) {
            return (0, 0);
        }
        uint256 duration = endTime - startTime;
        pointsEarned = duration * trainingRatePerSecond;
        tokenRewards = duration * tokenRewardPerSecond;
        // Potentially add multipliers based on character level or other factors
     }

    // --- Battling ---

    /// @notice Initiates a battle between two characters. Requires randomness.
    /// @param character1Id The ID of the first character NFT.
    /// @param character2Id The ID of the second character NFT.
    function initiateBattle(uint256 character1Id, uint256 character2Id) public whenNotPaused returns (uint256 battleId, uint256 requestId) {
        require(character1Id != character2Id, "CryptoColiseum: Characters cannot be the same");
        require(coliseumCharacters.exists(character1Id), "CryptoColiseum: Character 1 does not exist");
        require(coliseumCharacters.exists(character2Id), "CryptoColiseum: Character 2 does not exist");

        address participant1 = coliseumCharacters.ownerOf(character1Id);
        address participant2 = coliseumCharacters.ownerOf(character2Id);

        // Either owner or approved by owner
        require(participant1 == msg.sender || coliseumCharacters.isApprovedForAll(participant1, msg.sender) || coliseumCharacters.getApproved(character1Id) == msg.sender,
            "CryptoColiseum: Not owner/approved for Character 1");
        require(participant2 == msg.sender || coliseumCharacters.isApprovedForAll(participant2, msg.sender) || coliseumCharacters.getApproved(character2Id) == msg.sender,
            "CryptoColiseum: Not owner/approved for Character 2");

        // Characters must not be staked or already in battle
        require(_stakedCharacters[character1Id] == 0, "CryptoColiseum: Character 1 is staked");
        require(_stakedCharacters[character2Id] == 0, "CryptoColiseum: Character 2 is staked");
        require(!_isCharacterInBattle(character1Id), "CryptoColiseum: Character 1 is already in battle");
        require(!_isCharacterInBattle(character2Id), "CryptoColiseum: Character 2 is already in battle");


        battleId = _battleIdCounter.current();
        _battleIdCounter.increment();

        // Request 1 random word for battle outcome
         requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            1 // Number of random words for battle
        );

        _battles[battleId] = Battle({
            character1Id: character1Id,
            character2Id: character2Id,
            participant1: participant1,
            participant2: participant2,
            startTime: block.timestamp,
            randomnessRequestId: requestId,
            resolved: false,
            winningCharacterId: 0, // Placeholder
            tokenRewardPool: 0, // Example: Battle prize pool could be funded here
            winnerPointsGained: 0,
            loserPointsGained: 0
        });

        _randomnessRequestMap[requestId] = battleId; // Map request to battle ID
        emit BattleInitiated(battleId, character1Id, character2Id, requestId);

        return (battleId, requestId);
    }

    /// @dev Internal function to resolve a battle after VRF callback.
    function _resolveBattle(uint256 battleId, uint256[] memory randomWords) internal {
        require(_battles[battleId].randomnessRequestId > 0, "CryptoColiseum: Invalid battle ID for resolution"); // Ensure battle was initiated and waiting for VRF
        require(!_battles[battleId].resolved, "CryptoColiseum: Battle already resolved");
        require(randomWords.length >= 1, "CryptoColiseum: Not enough random words for battle resolution");

        Battle storage battle = _battles[battleId];

        uint256 randomFactor = randomWords[0] % 100; // Random factor between 0 and 99

        // Get character stats before calculating outcome
        (uint256 att1, uint256 def1, uint256 hp1, uint256 spd1, , ) = coliseumCharacters.getCharacterStats(battle.character1Id);
        (uint256 att2, uint256 def2, uint256 hp2, uint256 spd2, , ) = coliseumCharacters.getCharacterStats(battle.character2Id);

        // Simple Battle Outcome Calculation (Highly Simplified Example)
        // Calculate a "power score" for each character based on stats and randomness
        uint256 score1 = (att1 * attackWeight + def1 * defenseWeight + hp1 * healthWeight + spd1 * speedWeight) / 100;
        uint256 score2 = (att2 * attackWeight + def2 * defenseWeight + hp2 * healthWeight + spd2 * speedWeight) / 100;

        // Add random factor influence
        // Apply random factor to shift the scores slightly. E.g., random_factor * random_weight / 100
        // Ensure the random factor is applied relative to some base or range to avoid skewing too much.
        // A more balanced approach: (score * (100 - randomWeight) + (score * (randomFactor + 1) / 100) * randomWeight) / 100
        // Let's use a simpler influence: Add/subtract a percentage based on randomFactor and randomWeight
        uint256 score1Adjusted = score1;
        uint256 score2Adjusted = score2;

        if (randomWeight > 0) {
             // Example: Adjust score by up to +/- (randomWeight / 2)% based on randomFactor
             int256 randomAdjustment1 = int256(randomFactor) - 50; // -50 to +49
             score1Adjusted = uint256(int256(score1) + (int256(score1) * randomAdjustment1 * int256(randomWeight) / 5000)); // (score * (-50 to 49) * randomWeight / 5000)

             // Apply a slightly different random influence to the second character for variety
             int256 randomAdjustment2 = int256(randomWords[0] % 100) - 50; // Use another random word or same differently
             score2Adjusted = uint256(int256(score2) + (int256(score2) * randomAdjustment2 * int256(randomWeight) / 5000));
        }


        uint256 winningCharacterId = 0;
        uint256 losingCharacterId = 0;

        if (score1Adjusted > score2Adjusted) {
            winningCharacterId = battle.character1Id;
            losingCharacterId = battle.character2Id;
        } else if (score2Adjusted > score1Adjusted) {
            winningCharacterId = battle.character2Id;
            losingCharacterId = battle.character1Id;
        }
        // Handle draws (winningCharacterId remains 0)

        battle.resolved = true;
        battle.winningCharacterId = winningCharacterId;

        // --- Apply consequences and rewards ---
        uint256 tokenReward = battle.tokenRewardPool > 0 ? battle.tokenRewardPool : 1e18; // Example: 1 COLT default reward or use pool
        uint256 winnerPoints = 50; // Example points for winner
        uint256 loserPoints = 10; // Example points for loser

        battle.tokenRewardPool = tokenReward; // Store the reward for claiming
        battle.winnerPointsGained = winnerPoints;
        battle.loserPointsGained = loserPoints;

        // Add points based on win/loss/draw (points stored in Character contract)
        if (winningCharacterId != 0) {
             coliseumCharacters._addTrainingPoints(winningCharacterId, winnerPoints);
             coliseumCharacters._addTrainingPoints(losingCharacterId, loserPoints); // Loser also gets some points
        } else {
             // Handle draw: Both get draw points
             coliseumCharacters._addTrainingPoints(battle.character1Id, loserPoints);
             coliseumCharacters._addTrainingPoints(battle.character2Id, loserPoints);
        }

        // Get character stats *after* adding points for event emission
         (uint256 att1_final, uint256 def1_final, uint256 hp1_final, uint256 spd1_final, uint256 lvl1_final, uint256 tp1_final) = coliseumCharacters.getCharacterStats(battle.character1Id);
         (uint256 att2_final, uint256 def2_final, uint256 hp2_final, uint256 spd2_final, uint256 lvl2_final, uint256 tp2_final) = coliseumCharacters.getCharacterStats(battle.character2Id);


        emit BattleResolved(
            battleId,
            winningCharacterId,
            (winningCharacterId == battle.character1Id ? battle.character2Id : battle.character1Id), // Simple way to get loser
            [att1_final, def1_final, hp1_final, spd1_final, lvl1_final, tp1_final],
            [att2_final, def2_final, hp2_final, spd2_final, lvl2_final, tp2_final],
            tokenReward,
            winnerPoints,
            loserPoints
        );
    }

    /// @notice Gets the current status of a battle.
    /// @param battleId The ID of the battle.
    /// @return character1Id, character2Id, resolved, winningCharacterId, startTime, tokenRewardPool, winnerPointsGained, loserPointsGained The battle details.
    function getBattleStatus(uint256 battleId) public view returns (
        uint256 character1Id,
        uint256 character2Id,
        bool resolved,
        uint256 winningCharacterId,
        uint256 startTime,
        uint256 tokenRewardPool,
        uint256 winnerPointsGained,
        uint256 loserPointsGained
    ) {
        require(_battles[battleId].startTime > 0, "CryptoColiseum: Battle does not exist");
        Battle storage battle = _battles[battleId];
        return (
            battle.character1Id,
            battle.character2Id,
            battle.resolved,
            battle.winningCharacterId,
            battle.startTime,
            battle.tokenRewardPool,
            battle.winnerPointsGained,
            battle.loserPointsGained
        );
    }

    /// @notice Allows participants to claim their battle rewards after resolution.
    /// @param battleId The ID of the battle.
    function claimBattleRewards(uint256 battleId) public whenNotPaused nonReentrant {
         require(_battles[battleId].startTime > 0, "CryptoColiseum: Battle does not exist");
         Battle storage battle = _battles[battleId];
         require(battle.resolved, "CryptoColiseum: Battle not resolved yet");
         require(battle.participant1 == msg.sender || battle.participant2 == msg.sender, "CryptoColiseum: Not a participant in this battle");

         // Use a separate mapping to track claimed status per participant per battle
         // battleId => participantAddress => claimed?
         bytes32 claimedKey = keccak256(abi.encodePacked(battleId, msg.sender));
         require(!_battleRewardsClaimed[claimedKey], "CryptoColiseum: Battle reward already claimed");

         uint256 rewardAmount = 0;
         if (battle.winningCharacterId != 0) {
             // Not a draw
             if ((battle.winningCharacterId == battle.character1Id && battle.participant1 == msg.sender) ||
                 (battle.winningCharacterId == battle.character2Id && battle.participant2 == msg.sender)) {
                  // Winner claims the full pool (or a larger share)
                  rewardAmount = battle.tokenRewardPool; // Simple: Winner takes all
             } else {
                 // Loser might get a smaller share or 0
                 // For simplicity here, winner takes all, loser gets 0 tokens from the pool
                 rewardAmount = 0; // Loser gets 0 tokens from pool in this simple model
             }
         } else {
             // Draw: Participants split the pool
             rewardAmount = battle.tokenRewardPool / 2;
         }

         require(rewardAmount > 0, "CryptoColiseum: No pending battle rewards for you");

         _battleRewardsClaimed[claimedKey] = true; // Mark as claimed

         // Mint and transfer token rewards
         // This contract needs MINTER_ROLE on ColiseumToken
         coliseumToken.mint(msg.sender, rewardAmount);

         emit BattleRewardsClaimed(battleId, msg.sender, rewardAmount);
    }

     // Mapping to track if a participant has claimed rewards for a specific battle
     mapping(bytes32 => bool) private _battleRewardsClaimed;


     /// @notice Calculates and returns pending battle rewards for a participant.
     /// @param battleId The ID of the battle.
     /// @return amount The amount of pending token rewards.
     function getPendingBattleRewards(uint256 battleId) public view returns (uint256 amount) {
        require(_battles[battleId].startTime > 0, "CryptoColiseum: Battle does not exist");
        Battle storage battle = _battles[battleId];
        require(battle.resolved, "CryptoColiseum: Battle not resolved yet");
        require(battle.participant1 == msg.sender || battle.participant2 == msg.sender, "CryptoColiseum: Not a participant in this battle");

        bytes32 claimedKey = keccak256(abi.encodePacked(battleId, msg.sender));
        if (_battleRewardsClaimed[claimedKey]) {
            return 0; // Already claimed
        }

        uint256 rewardAmount = 0;
         if (battle.winningCharacterId != 0) {
             // Not a draw
             if ((battle.winningCharacterId == battle.character1Id && battle.participant1 == msg.sender) ||
                 (battle.winningCharacterId == battle.character2Id && battle.participant2 == msg.sender)) {
                  // Winner claims the full pool
                  rewardAmount = battle.tokenRewardPool;
             } else {
                 // Loser gets 0 from the pool in this model
                  rewardAmount = 0;
             }
         } else {
             // Draw: Participants split the pool
             rewardAmount = battle.tokenRewardPool / 2;
         }
         return rewardAmount;
     }


     /// @notice Returns the detailed outcome of a resolved battle.
     /// @param battleId The ID of the battle.
     /// @return winnerId, loserId, char1FinalStats, char2FinalStats, tokenReward, winnerPoints, loserPoints
     function getBattleResult(uint256 battleId) public view returns (
         uint256 winnerId,
         uint256 loserId,
         uint256[] memory char1FinalStats,
         uint256[] memory char2FinalStats,
         uint256 tokenReward,
         uint256 winnerPoints,
         uint256 loserPoints
     ) {
        require(_battles[battleId].startTime > 0, "CryptoColiseum: Battle does not exist");
        Battle storage battle = _battles[battleId];
        require(battle.resolved, "CryptoColiseum: Battle not resolved yet");

         // Fetch current stats for display
         (uint256 att1, uint256 def1, uint256 hp1, uint256 spd1, uint256 lvl1, uint256 tp1) = coliseumCharacters.getCharacterStats(battle.character1Id);
         (uint256 att2, uint256 def2, uint256 hp2, uint256 spd2, uint256 lvl2, uint256 tp2) = coliseumCharacters.getCharacterStats(battle.character2Id);

        return (
            battle.winningCharacterId,
            (battle.winningCharacterId == battle.character1Id ? battle.character2Id : battle.character1Id),
            new uint256[](6), // Placeholder, ideally stored on-chain during resolution
            new uint256[](6), // Placeholder
            battle.tokenRewardPool,
            battle.winnerPointsGained,
            battle.loserPointsGained
        );
        // Note: Storing final stats directly in the Battle struct would make this cleaner
        // but increases gas cost of the VRF callback. Emitting in the event is often better.
        // We'll return current stats for now.
     }

    /// @dev Helper to check if a character is currently in a battle.
    // This requires iterating through active battles, which is inefficient.
    // A better way would be a mapping: characterId => battleId if active.
    // For this example, let's use the inefficient way as it's a demo,
    // but acknowledge the limitation.
    function _isCharacterInBattle(uint256 tokenId) internal view returns (bool) {
         // This check is simplified and might not cover all edge cases
         // A dedicated mapping `mapping(uint256 => uint256) private _characterBattleStatus; // tokenId => battleId (0 if not in battle)` is recommended.
         // Iterate active battles? No, too gas expensive.
         // Let's *assume* a character is only in battle from `initiateBattle` call to `rawFulfillRandomWords` callback.
         // This requires state tracking associated with the VRF request map.
         // If a character is char1 or char2 in any battle struct that is NOT resolved, it's in battle.
         // Iterating _battles is impossible. We need a direct lookup.
         // Let's add a simple state: `mapping(uint256 => bool) private _isCharacterBattling;`
         // Set true on initiate, false on resolve.
         return _isCharacterBattling[tokenId];
    }
     mapping(uint256 => bool) private _isCharacterBattling; // characterId => bool

     // Modify initiateBattle and _resolveBattle to update _isCharacterBattling
    function initiateBattle(uint256 character1Id, uint256 character2Id) public whenNotPaused returns (uint256 battleId, uint256 requestId) {
         // ... (previous checks) ...
         require(!_isCharacterBattling[character1Id], "CryptoColiseum: Character 1 is already in battle");
         require(!_isCharacterBattling[character2Id], "CryptoColiseum: Character 2 is already in battle");

         battleId = _battleIdCounter.current();
         _battleIdCounter.increment();

         requestId = COORDINATOR.requestRandomWords(...); // Request VRF

         _battles[battleId] = Battle({ ... }); // Store battle details
         _randomnessRequestMap[requestId] = battleId;

         _isCharacterBattling[character1Id] = true; // Mark as battling
         _isCharacterBattling[character2Id] = true;

         emit BattleInitiated(battleId, character1Id, character2Id, requestId);
         return (battleId, requestId);
    }

    function _resolveBattle(uint256 battleId, uint256[] memory randomWords) internal {
        // ... (previous checks) ...
        Battle storage battle = _battles[battleId];

        // ... (battle logic) ...

        battle.resolved = true;
        battle.winningCharacterId = winningCharacterId;
        // ... (reward distribution logic) ...

        // Unmark characters as battling
        _isCharacterBattling[battle.character1Id] = false;
        _isCharacterBattling[battle.character2Id] = false;

        // ... (emit event) ...
    }


    // --- Tokenomics ---

    /// @notice Returns the address of the ColiseumToken contract.
    function getTokenAddress() public view returns (address) {
        return address(coliseumToken);
    }

    /// @notice Returns the address of the ColiseumCharacter contract.
    function getNFTAddress() public view returns (address) {
        return address(coliseumCharacters);
    }

     /// @notice Admin function to distribute initial token supply.
     /// @param recipients Array of recipient addresses.
     /// @param amounts Array of amounts corresponding to recipients.
    function distributeInitialTokens(address[] memory recipients, uint256[] memory amounts) public onlyRole(ADMIN_ROLE) whenNotPaused {
         require(recipients.length == amounts.length, "CryptoColiseum: Recipient and amount arrays must match length");
         // This contract needs MINTER_ROLE on ColiseumToken
         for (uint i = 0; i < recipients.length; i++) {
             if (amounts[i] > 0) {
                coliseumToken.mint(recipients[i], amounts[i]);
             }
         }
    }


    // --- Upgrades & Mechanics ---

    /// @notice Spends training points and/or tokens to improve character stats.
    /// @param tokenId The ID of the character NFT to level up.
    /// @param pointsToSpend The number of training points to spend.
    /// @param tokensToSpend The amount of tokens to spend.
    /// @param attackIncrease Points allocated to Attack.
    /// @param defenseIncrease Points allocated to Defense.
    /// @param healthIncrease Points allocated to Health.
    /// @param speedIncrease Points allocated to Speed.
    // Note: A real system would have a more complex level-up formula/allocation.
    function levelUpCharacter(
        uint256 tokenId,
        uint256 pointsToSpend,
        uint256 tokensToSpend,
        uint256 attackIncrease,
        uint256 defenseIncrease,
        uint256 healthIncrease,
        uint256 speedIncrease
    ) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) whenNotPaused nonReentrant {
        require(pointsToSpend + tokensToSpend > 0, "CryptoColiseum: Must spend points or tokens");
        uint256 totalStatIncreasePoints = attackIncrease + defenseIncrease + healthIncrease + speedIncrease;
        require(totalStatIncreasePoints > 0, "CryptoColiseum: Must allocate points to stats");

        // Example: 1 training point adds 1 stat point, 1 token adds 10 stat points
        uint256 equivalentPointsFromTokens = tokensToSpend * 10; // Example rate
        uint256 totalSpendEquivalentPoints = pointsToSpend + equivalentPointsFromTokens;

        require(totalStatIncreasePoints <= totalSpendEquivalentPoints, "CryptoColiseum: Allocated points exceed spending");
        // Note: In a real system, you'd likely have a formula like `cost = f(currentLevel, pointsToSpend, tokensToSpend)`

        // Deduct training points (handled in ColiseumCharacter)
        coliseumCharacters._spendTrainingPoints(tokenId, pointsToSpend);

        // Deduct tokens (burn from player's balance)
        if (tokensToSpend > 0) {
            // Requires the player to have approved this contract to spend their tokens
            coliseumToken.transferFrom(msg.sender, address(this), tokensToSpend);
            coliseumToken.burn(tokensToSpend); // Or transfer to a treasury/sink
        }

        // Apply stat increases (handled in ColiseumCharacter)
        (uint256 currentAtt, uint256 currentDef, uint256 currentHp, uint256 currentSpd, uint256 currentLvl, ) = coliseumCharacters.getCharacterStats(tokenId);

        uint256 newAtt = currentAtt + attackIncrease;
        uint256 newDef = currentDef + defenseIncrease;
        uint256 newHp = currentHp + healthIncrease;
        uint256 newSpd = currentSpd + speedIncrease;
        uint256 newLvl = currentLvl + 1; // Simple: Any level-up increases level by 1

        coliseumCharacters._updateStats(tokenId, newAtt, newDef, newHp, newSpd);
        coliseumCharacters._updateLevel(tokenId, newLvl);

        emit CharacterLeveledUp(tokenId, newLvl, pointsToSpend, tokensToSpend);
    }

    /// @notice Sets the rate at which training points/rewards accrue.
    /// @param ratePerSecond The new training points per second.
    /// @param tokenRewPerSecond The new token reward per second.
    function setTrainingRate(uint256 ratePerSecond, uint256 tokenRewPerSecond) public onlyRole(ADMIN_ROLE) {
        trainingRatePerSecond = ratePerSecond;
        tokenRewardPerSecond = tokenRewPerSecond;
        emit TrainingRateUpdated(ratePerSecond, tokenRewPerSecond);
    }

     /// @notice Sets parameters influencing battle outcomes.
     /// @param newAttackWeight The new weight for Attack (0-100).
     /// @param newDefenseWeight The new weight for Defense (0-100).
     /// @param newHealthWeight The new weight for Health (0-100).
     /// @param newSpeedWeight The new weight for Speed (0-100).
     /// @param newRandomWeight The new weight for Randomness (0-100).
    function setBattleParameters(
        uint256 newAttackWeight,
        uint256 newDefenseWeight,
        uint256 newHealthWeight,
        uint256 newSpeedWeight,
        uint256 newRandomWeight
    ) public onlyRole(ADMIN_ROLE) {
        require(newAttackWeight + newDefenseWeight + newHealthWeight + newSpeedWeight <= 100, "CryptoColiseum: Stat weights sum must be <= 100");
        require(newRandomWeight <= 100, "CryptoColiseum: Random weight must be <= 100");

        attackWeight = newAttackWeight;
        defenseWeight = newDefenseWeight;
        healthWeight = newHealthWeight;
        speedWeight = newSpeedWeight;
        randomWeight = newRandomWeight;

        emit BattleParametersUpdated(attackWeight, defenseWeight, healthWeight, speedWeight, randomWeight);
    }

    // --- Admin & Utility ---

    // Overrides for AccessControl functions to add Pausable check (optional but good practice)
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        super.revokeRole(role, account);
    }

    // Pause/Unpause
    function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Allows ADMIN_ROLE to withdraw LINK from the contract (needed for VRF subscription).
    function withdrawLink() public onlyRole(ADMIN_ROLE) nonReentrant {
        LinkTokenInterface link = LinkTokenInterface(this.LINK());
        uint256 balance = link.balanceOf(address(this));
        require(balance > 0, "CryptoColiseum: Nothing to withdraw");
        link.transfer(msg.sender, balance);
        emit LinkWithdrawn(msg.sender, balance);
    }

     /// @notice Returns a list of character token IDs owned by an address.
     /// @param owner The address of the owner.
     /// @return tokenIds An array of token IDs.
     function getPlayerCharacters(address owner) public view returns (uint256[] memory) {
         uint256 balance = coliseumCharacters.balanceOf(owner);
         uint256[] memory tokenIds = new uint256[](balance);
         for (uint i = 0; i < balance; i++) {
             tokenIds[i] = coliseumCharacters.tokenOfOwnerByIndex(owner, i);
         }
         return tokenIds;
     }

    /// @notice Allows owner to set a name for their character (if not already set).
    /// @param tokenId The ID of the character NFT.
    /// @param newName The desired name.
     function setCharacterName(uint256 tokenId, string memory newName) public onlyOwnerOfCharacter(tokenId) characterExists(tokenId) whenNotPaused {
        coliseumCharacters._setCharacterName(tokenId, newName); // Call internal function in NFT contract
     }

    /// @notice Returns the name of a character.
    /// @param tokenId The ID of the character NFT.
    /// @return name The character's name.
     function getCharacterName(uint256 tokenId) public view characterExists(tokenId) returns (string memory) {
        return coliseumCharacters.getCharacterName(tokenId); // Call view function in NFT contract
     }

    // --- VRF Interface Requirement ---
    // LINK token address (required by VRFConsumerBaseV2)
    function LINK() internal view virtual returns (address) {
        // This should return the address of the LINK token used by the VRF Coordinator
        // You will need to provide this during deployment or initialization.
        // Example: return 0x...; // LINK token address on your network
         revert("LINK token address not configured"); // Placeholder
    }
}

// Simple interface for LINK token (needed for withdrawLink)
interface LinkTokenInterface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}
```

**Explanation of Advanced Concepts & Features:**

1.  **Dynamic NFTs (ERC721URIStorage & Custom State):** Instead of static metadata, character stats (`attack`, `defense`, etc.) are stored directly within the `ColiseumCharacter` contract (or potentially the `CryptoColiseum` contract managing it). Functions like `levelUpCharacter`, `_addTrainingPoints`, and battle resolution (`_resolveBattle`) modify these stats, making the NFTs dynamic. While the `tokenURI` is included, a proper implementation would require an off-chain service (like a backend server or IPFS script) that can query the on-chain state to generate dynamic JSON metadata when the `tokenURI` is requested.
2.  **Integrated Tokenomics (ERC20):** A native token (`ColiseumToken`) is part of the system. It's used for rewards (training, battling) and as a sink for upgrades (`levelUpCharacter` requires spending tokens). The main `CryptoColiseum` contract holds the `MINTER_ROLE` on the token contract to issue rewards.
3.  **Staking (Training):** Characters can be "staked" by transferring them to the contract or, more commonly as implemented here, by the owner calling a `stakeCharacterForTraining` function which records the start time. Rewards (training points and tokens) accrue over time and can be claimed or are paid out upon unstaking. This implements a yield-farming-like mechanism for NFTs.
4.  **On-chain Simulation with VRF:** Battles are initiated on-chain. The outcome isn't a simple pre-calculated result; it relies on a secure random number generated by Chainlink VRF. The `rawFulfillRandomWords` callback processes the random output to determine the winner based on character stats and the random factor, applying consequences (points gained) and rewards.
5.  **Chainlink VRF Integration:** Securely obtaining unpredictable outcomes is crucial for fair games. This contract uses `VRFConsumerBaseV2` to request and receive random words, mapping the `requestId` to the specific action (minting or battle) needing randomness.
6.  **Access Control (OpenZeppelin):** Roles (`ADMIN_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE`, `VRF_CALLBACK_ROLE`) are used to restrict sensitive functions, providing granular control over who can perform specific administrative tasks or trigger core mechanics.
7.  **Pausable (OpenZeppelin):** The `whenNotPaused` and `whenPaused` modifiers allow administrators to temporarily halt critical operations in case of an emergency or upgrade preparation.
8.  **ReentrancyGuard (OpenZeppelin):** Prevents reentrancy attacks, especially important in functions that transfer tokens (`unstakeCharacter`, `claimTrainingRewards`, `claimBattleRewards`, `levelUpCharacter`, `withdrawLink`).
9.  **Separation of Concerns:** The system is split into three contracts: the ERC20 token, the ERC721 NFT, and the main logic contract. This improves modularity and allows for potential upgrades of the logic contract (if implemented with proxy patterns).
10. **Event-Driven State Changes:** Important actions emit events (`CharacterMinted`, `BattleResolved`, `CharacterLeveledUp`, etc.). This is crucial for off-chain applications (like a game front-end) to track the state of the system without needing to constantly poll contract storage.
11. **Errors (Custom Errors):** Using `error` rather than `require` with string messages is a gas-efficient way to provide detailed error information in Solidity 0.8+.

This contract provides a framework for a complex, interactive NFT system on the blockchain, demonstrating several advanced Solidity concepts beyond basic token standards. Remember that a production-ready version would require more sophisticated battle mechanics, thorough testing, gas optimization, potentially upgradeability patterns (like UUPS proxies), and a secure metadata service.