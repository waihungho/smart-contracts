Okay, let's design an interesting, advanced-concept smart contract. A good theme that allows for complexity, dynamic state, and interaction is a digital asset combined with game mechanics and resource management, hinting at concepts like training, optimization, and probabilistic outcomes.

Let's create a "CryptoColosseum" contract where users own digital "Synthetics" (NFT fighters), train them using an in-game utility token, and pit them against each other in on-chain battles. The Synthetics will have dynamic stats based on training and battle outcomes, making the NFTs evolve.

**Core Concepts:**

1.  **Synthetics (ERC721 NFTs):** Unique digital fighters with persistent on-chain stats.
2.  **Neural Fragments (ERC20 Token):** A utility token (`NF`) used for training Synthetics and potentially earned through battles.
3.  **Dynamic Stats & Progression:** Synthetics gain Experience Points (XP) and Level Up, improving stats based on training and battle performance.
4.  **On-Chain Battle Simulation:** Deterministic battle outcomes based on fighter stats and a pseudo-random element derived from block data.
5.  **Training Regimens:** Different training functions that cost `NF` and affect specific stats.
6.  **Battle Queue:** A mechanism for fighters to enter a queue and be paired for battles.
7.  **Owner-Controlled Parameters:** The contract owner can adjust training costs, battle rewards, etc.
8.  **Pause Functionality:** Ability to pause core game mechanics in case of issues.

**Advanced/Creative Aspects:**

*   **Dynamic NFTs:** While metadata updates are typically off-chain, the *stats* driving the NFT's identity and value (`strength`, `agility`, `level`, `combatRating`) are stored and updated directly on-chain by user interactions (`train`, `battle`). The `tokenURI` would ideally point to a service reflecting these on-chain stats.
*   **On-Chain Procedural-ish Generation:** Initial stats are generated deterministically based on the NFT's ID and block data at mint time, giving each Synthetic a unique starting point.
*   **Simulated AI Training/Optimization:** Training functions are framed as optimizing the Synthetic's "neural net" or "combat algorithms," reflecting the AI theme without requiring off-chain AI computation. `optimizeCombatAlgorithm` is a special training function.
*   **State-Dependent Actions:** Actions (training, battling) are restricted based on the Synthetic's current state (e.g., cannot train if in battle queue).
*   **Pseudo-Randomness from Block Data:** Battle outcomes incorporate a factor derived from recent block hashes and timestamps, acknowledging the limitations of on-chain randomness while demonstrating its use. *Disclaimer: This method is predictable to miners and not suitable for high-security randomness needs.*

**Function Summary (Public/External & Key Internal):**

1.  `constructor`: Deploys the contract, sets initial owner and parameters.
2.  `mintSynthetic`: Public function for users to mint a new Synthetic NFT. Costs `NF` or ETH (let's use `NF`).
3.  `getFighterStats`: View function to retrieve a Synthetic's current stats.
4.  `getFighterLevel`: View function for a specific Synthetic's level.
5.  `getFighterState`: View function showing if a fighter is Idle, Training, or Queued.
6.  `trainStrength`: Train Synthetic's Strength stat. Costs `NF`.
7.  `trainAgility`: Train Synthetic's Agility stat. Costs `NF`.
8.  `trainEndurance`: Train Synthetic's Endurance stat. Costs `NF`.
9.  `trainIntelligence`: Train Synthetic's Intelligence stat. Costs `NF`.
10. `optimizeCombatAlgorithm`: Special training for the derived Combat Rating. Costs `NF`.
11. `getTrainingCost`: View the current cost for a specific training type.
12. `enterBattleQueue`: Place a Synthetic in the battle queue. Costs `NF`.
13. `getBattleQueueSize`: View the number of fighters currently in the battle queue.
14. `processNextBattle`: Callable by anyone (gas payer) to pair the first two fighters in the queue and simulate a battle. Updates stats and rewards. *Contains pseudo-random logic.*
15. `getBattleResult`: View the outcome of a past battle for a specific fighter (limited history).
16. `claimBattleRewards`: Owner of a winning fighter claims earned `NF`.
17. `getTotalSyntheticsMinted`: View total NFTs created.
18. `withdrawNF`: Owner withdraws `NF` accumulated from training/battle fees.
19. `setTrainingCost`: Owner sets the cost for a specific training type.
20. `setBattleEntryFee`: Owner sets the cost to enter the battle queue.
21. `setBattleRewardAmount`: Owner sets the `NF` reward for winning a battle.
22. `setBaseTokenURI`: Owner sets the base URI for NFT metadata (points off-chain).
23. `pause`: Owner pauses core game functions (minting, training, battling).
24. `unpause`: Owner unpauses.
25. `ownerOf`: ERC721 standard - Get owner of a token.
26. `balanceOf`: ERC721 standard - Get balance of owner.
27. `transferFrom`: ERC721 standard - Transfer token.
28. `approve`: ERC721 standard - Approve transfer.
29. `getApproved`: ERC721 standard - Get approved address.
30. `setApprovalForAll`: ERC721 standard - Approve operator.
31. `isApprovedForAll`: ERC721 standard - Check operator approval.
32. `tokenURI`: ERC721 standard - Get metadata URI.

*(Note: Functions 25-32 are standard ERC721, included to make the NFT functional. The core game logic is in 1-24).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoColosseum
 * @dev A smart contract for owning, training, and battling dynamic digital fighters (Synthetics)
 *      using an in-game utility token (Neural Fragments).
 *      Features include dynamic NFT stats updated on-chain, on-chain battle simulation
 *      with pseudo-random elements, and resource management.
 *
 * @author [Your Name/Alias Here]
 */

/**
 * @dev --- OUTLINE & FUNCTION SUMMARY ---
 *
 * Contract: CryptoColosseum (Inherits ERC721, ERC20-like logic for NF, Ownable, Pausable)
 *
 * Concepts:
 * - Synthetics (ERC721): Dynamic NFTs with stats that change based on interaction.
 * - Neural Fragments (NF) (ERC20-like): Utility token spent on training, earned from battles.
 * - Dynamic Stats: Strength, Agility, Endurance, Intelligence, Combat Rating, Experience, Level.
 * - Training: Improves specific stats by spending NF.
 * - Battles: On-chain simulation based on stats and pseudo-randomness, results in XP/NF gain for winner.
 * - Battle Queue: Fighters wait to be paired.
 * - On-Chain State: All crucial fighter stats and game state are stored on-chain.
 * - Owner Controls: Adjust game parameters.
 * - Pseudo-Randomness: Uses block data for battle outcomes (WARNING: Not secure for high-value outcomes due to miner manipulability).
 *
 * Data Structures:
 * - FighterStats: struct holding STR, AGI, END, INT, CR, XP, Level, battles fought/won.
 * - FighterState: Enum { Idle, Training, Queued, Battling }.
 * - Fighter: struct combining FighterStats and FighterState.
 * - TrainingType: Enum { Strength, Agility, Endurance, Intelligence, CombatAlgorithm }.
 *
 * State Variables:
 * - ERC721 mappings: _owners, _balances, _tokenApprovals, _operatorApprovals.
 * - ERC20-like NF mappings: nfBalances, nfAllowances.
 * - Game State: fighters (tokenId => Fighter), battleQueue (uint256[]), nextTokenId,
 *   nfTotalSupply, trainingCosts (TrainingType => uint256), battleEntryFee (uint256),
 *   battleRewardAmount (uint256), baseTokenURI (string).
 * - Ownable/Pausable: _owner, _paused.
 * - Battle Result History: Simplified mapping tokenId => lastBattleResult (struct).
 *
 * Events:
 * - SyntheticMinted(tokenId, owner, seed)
 * - FighterTrained(tokenId, trainingType, cost)
 * - FighterLeveledUp(tokenId, newLevel)
 * - BattleQueued(tokenId)
 * - BattleProcessed(fighter1Id, fighter2Id, winnerId, winnerXP, winnerNF)
 * - BattleRewardsClaimed(claimer, winnerId, amount)
 * - NFTransferred(from, to, amount)
 * - NFApproval(owner, spender, amount)
 *
 * Functions:
 * - constructor(...)
 * - mintSynthetic(address recipient, uint256 initialNFSupply)
 * - getFighterStats(uint256 tokenId) view
 * - getFighterLevel(uint256 tokenId) view
 * - getFighterState(uint256 tokenId) view
 * - trainStrength(uint256 tokenId) whenNotPaused
 * - trainAgility(uint256 tokenId) whenNotPaused
 * - trainEndurance(uint256 tokenId) whenNotPaused
 * - trainIntelligence(uint256 tokenId) whenNotPaused
 * - optimizeCombatAlgorithm(uint256 tokenId) whenNotPaused
 * - getTrainingCost(TrainingType trainingType) view
 * - enterBattleQueue(uint256 tokenId) whenNotPaused
 * - getBattleQueueSize() view
 * - processNextBattle() whenNotPaused -- WARNING: Uses block hash randomness!
 * - getBattleResult(uint256 tokenId) view -- Simplified last battle
 * - claimBattleRewards(uint256 tokenId)
 * - getTotalSyntheticsMinted() view
 * - withdrawNF(uint256 amount) onlyOwner
 * - setTrainingCost(TrainingType trainingType, uint256 cost) onlyOwner
 * - setBattleEntryFee(uint256 fee) onlyOwner
 * - setBattleRewardAmount(uint256 reward) onlyOwner
 * - setBaseTokenURI(string memory uri) onlyOwner
 * - pause() onlyOwner whenNotPaused
 * - unpause() onlyOwner whenPaused
 *
 * ERC721 (Minimal Implementation for Game Context):
 * - ownerOf(uint256 tokenId) view
 * - balanceOf(address owner) view
 * - transferFrom(address from, address to, uint256 tokenId)
 * - safeTransferFrom(address from, address to, uint256 tokenId)
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
 * - approve(address to, uint256 tokenId)
 * - getApproved(uint256 tokenId) view
 * - setApprovalForAll(address operator, bool approved)
 * - isApprovedForAll(address owner, address operator) view
 * - supportsInterface(bytes4 interfaceId) view
 * - tokenURI(uint256 tokenId) view
 * - _exists(uint256 tokenId) internal view
 * - _safeMint(address to, uint256 tokenId) internal
 * - _transfer(address from, address to, uint256 tokenId) internal
 * - _approve(address to, uint256 tokenId) internal
 * - _isApprovedOrOwner(address spender, uint256 tokenId) internal view
 *
 * ERC20-like NF (Minimal Implementation within this contract):
 * - name() view returns ("Neural Fragments")
 * - symbol() view returns ("NF")
 * - decimals() view returns (18)
 * - totalSupply() view returns (nfTotalSupply)
 * - balanceOf(address account) view -- Overloaded, refers to NF balance
 * - transfer(address to, uint256 amount) returns (bool)
 * - allowance(address owner, address spender) view returns (uint256)
 * - approve(address spender, uint256 amount) returns (bool) -- Overloaded, refers to NF approval
 * - transferFrom(address from, address to, uint256 amount) returns (bool) -- Overloaded, refers to NF transferFrom
 * - _mintNF(address account, uint256 amount) internal
 * - _burnNF(address account, uint256 amount) internal
 * - _transferNF(address from, address to, uint256 amount) internal returns (bool)
 * - _approveNF(address owner, address spender, uint256 amount) internal
 *
 * Internal Helpers:
 * - _generateInitialStats(uint256 tokenId, uint256 seed) pure
 * - _calculateCombatRating(FighterStats memory stats) pure
 * - _gainExperience(uint256 tokenId, uint256 amount)
 * - _levelUp(uint256 tokenId)
 * - _simulateBattle(uint256 fighter1Id, uint256 fighter2Id, uint256 randomSeed) pure returns (uint256 winnerId, uint256 loserId)
 * - _getRandomSeed() internal view -- WARNING: Pseudo-random!
 * - _isFighterReady(uint256 tokenId) internal view
 * - checkAndChangeFighterState(uint256 tokenId, FighterState expected, FighterState newState) internal
 * - getAttributeBoost(uint256 level) pure returns (uint256)
 * - calculateXPGain(uint256 fighter1Level, uint256 fighter2Level, bool isWinner) pure returns (uint256 xp)
 *
 * Modifiers:
 * - onlyOwner
 * - whenNotPaused
 * - whenPaused
 */

// Minimal Ownable implementation
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Minimal Pausable implementation
abstract contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function pause() public virtual onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public virtual onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// ERC165 Interface check
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal ERC721 implementation for this specific game contract
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Minimal ERC20 implementation for the NF token *within this contract*
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract CryptoColosseum is Ownable, Pausable, IERC721, IERC721Metadata, IERC165 {

    // --- Data Structures ---

    struct FighterStats {
        uint256 strength;
        uint256 agility;
        uint256 endurance; // Health potential
        uint256 intelligence; // Training efficiency / crit chance?
        uint256 combatRating; // Derived stat for battle calculation
        uint256 experience;
        uint256 level;
        uint256 battlesFought;
        uint256 battlesWon;
    }

    enum FighterState { Idle, Training, Queued, Battling }

    struct Fighter {
        FighterStats stats;
        FighterState state;
        uint256 stateUntil; // Timestamp when training/battling ends
        uint256 seed; // For initial generation and potential future use
    }

    struct BattleResult {
        uint256 timestamp;
        uint256 opponentId;
        bool won;
        uint256 xpEarned;
        uint256 nfEarned;
    }

    enum TrainingType { Strength, Agility, Endurance, Intelligence, CombatAlgorithm }


    // --- ERC721 State ---
    string private _name = "SyntheticFighter";
    string private _symbol = "SYNF";
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId = 0;
    string private _baseTokenURI; // Base URI for metadata, tokenURI will append tokenId


    // --- ERC20-like NF State (Implemented within this contract) ---
    string private constant _nfName = "Neural Fragments";
    string private constant _nfSymbol = "NF";
    uint8 private constant _nfDecimals = 18;
    uint256 private _nfTotalSupply = 0;
    mapping(address => uint256) private nfBalances;
    mapping(address => mapping(address => uint256)) private nfAllowances;
    // Contract holds NF collected from fees
    uint256 private contractNFBalance = 0;


    // --- Game State ---
    mapping(uint256 => Fighter) private fighters;
    uint256[] private battleQueue;
    mapping(uint256 => uint256) private trainingCosts; // TrainingType => cost in NF
    uint256 private battleEntryFee = 10e18; // Default 10 NF
    uint256 private battleRewardAmount = 50e18; // Default 50 NF
    // Simplified battle result history (stores only the last battle outcome)
    mapping(uint256 => BattleResult) private lastBattleResults;


    // --- Events ---
    event SyntheticMinted(uint256 indexed tokenId, address indexed owner, uint256 seed);
    event FighterTrained(uint256 indexed tokenId, TrainingType indexed trainingType, uint256 cost);
    event FighterLeveledUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event FighterStateChanged(uint256 indexed tokenId, FighterState indexed oldState, FighterState indexed newState);
    event BattleQueued(uint256 indexed tokenId);
    event BattleProcessed(uint256 indexed fighter1Id, uint256 indexed fighter2Id, uint256 indexed winnerId, uint256 winnerXP, uint256 winnerNF);
    event BattleRewardsClaimed(address indexed claimer, uint256 indexed winnerId, uint256 amount);
    event NFTransferred(address indexed from, address indexed to, uint256 amount);
    event NFApproval(address indexed owner, address indexed spender, uint256 amount);


    // --- Constructor ---
    constructor(uint256 initialMintNFSupply) {
        // Mint initial NF supply to the deployer
        _mintNF(msg.sender, initialMintNFSupply);

        // Set initial training costs (example values)
        trainingCosts[TrainingType.Strength] = 5e18; // 5 NF
        trainingCosts[TrainingType.Agility] = 5e18; // 5 NF
        trainingCosts[TrainingType.Endurance] = 5e18; // 5 NF
        trainingCosts[TrainingType.Intelligence] = 5e18; // 5 NF
        trainingCosts[TrainingType.CombatAlgorithm] = 15e18; // 15 NF (more expensive)
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        // ERC721: 0x80ac58cd
        // ERC721Metadata: 0x5b5e139f
        // ERC165: 0x01ffc9a7
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    // --- ERC721 Implementation ---

    function name() public view virtual override(IERC721Metadata) returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override(IERC721Metadata) returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721Metadata) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // No base URI set
        }
        // Concatenate base URI with token ID (ideally points to dynamic service)
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function balanceOf(address owner) public view virtual override(IERC721) returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override(IERC721) returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override(IERC721) {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override(IERC721) returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721) {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(IERC721) returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721) {
        //solhint-disable-next-line
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Check if fighter is in a state that prevents transfer
        require(_isFighterReady(tokenId), "CryptoColosseum: Fighter is busy (training/queued/battling)");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(IERC721) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Check if fighter is in a state that prevents transfer
        require(_isFighterReady(tokenId), "CryptoColosseum: Fighter is busy (training/queued/battling)");

        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Internal ERC721 helpers
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approvals
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try ERC721Holder(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                return retval == ERC721Holder.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // Minimal ERC721Receiver for interface ID
    interface ERC721Holder {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
    }


    // --- ERC20-like NF Implementation (within this contract) ---

    function name() public pure returns (string memory) {
        return _nfName;
    }

    function symbol() public pure returns (string memory) {
        return _nfSymbol;
    }

    function decimals() public pure returns (uint8) {
        return _nfDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return _nfTotalSupply;
    }

    // Overloaded balanceOf for NF token
    function balanceOf(address account) public view returns (uint256) {
        return nfBalances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferNF(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return nfAllowances[owner][spender];
    }

    // Overloaded approve for NF token
    function approve(address spender, uint256 amount) public returns (bool) {
        _approveNF(msg.sender, spender, amount);
        return true;
    }

    // Overloaded transferFrom for NF token
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = nfAllowances[from][msg.sender];
        require(currentAllowance >= amount, "NF: transfer amount exceeds allowance");
        unchecked {
            _approveNF(from, msg.sender, currentAllowance - amount);
        }
        _transferNF(from, to, amount);
        return true;
    }

    // Internal NF helpers
    function _mintNF(address account, uint256 amount) internal {
        require(account != address(0), "NF: mint to the zero address");
        _nfTotalSupply += amount;
        nfBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

     // Note: _burnNF is not used in this game's NF flow currently, but good to have
    function _burnNF(address account, uint256 amount) internal {
        require(account != address(0), "NF: burn from the zero address");
        uint256 accountBalance = nfBalances[account];
        require(accountBalance >= amount, "NF: burn amount exceeds balance");
        unchecked {
            nfBalances[account] = accountBalance - amount;
        }
        _nfTotalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transferNF(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "NF: transfer from the zero address");
        require(to != address(0), "NF: transfer to the zero address");

        uint256 fromBalance = nfBalances[from];
        require(fromBalance >= amount, "NF: transfer amount exceeds balance");
        unchecked {
            nfBalances[from] = fromBalance - amount;
        }
        nfBalances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function _approveNF(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "NF: approve from the zero address");
        require(spender != address(0), "NF: approve to the zero address");
        nfAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    // --- Core Game Functions ---

    /**
     * @dev Allows a user to mint a new Synthetic fighter.
     * Requires payment of NF equal to battleEntryFee (repurposing as mint cost).
     * @param recipient The address to mint the Synthetic to.
     */
    function mintSynthetic(address recipient) public payable whenNotPaused {
        // Require NF payment - assuming the user has approved this contract to spend their NF
        // This design is simpler than requiring ETH payment & internal NF minting for each NFT
        // Alternative: Require ETH payment here, _mintNF(recipient, initialNFPerFighter)
        // Let's stick to the NF payment model for simplicity in this example.
        // User must call approve(this contract address, battleEntryFee) on an external NF token contract
        // and this contract would call transferFrom.
        //
        // HOWEVER, since NF is implemented *within* this contract for simplicity, the user just needs NF balance.
        // We'll make the user pay the contract's internal NF balance.

        uint256 mintCost = battleEntryFee; // Use battleEntryFee as mint cost for this example
        require(nfBalances[msg.sender] >= mintCost, "CryptoColosseum: Insufficient NF balance for minting.");

        // Transfer NF cost from minter to the contract's internal balance
        nfBalances[msg.sender] -= mintCost; // deduct from user
        contractNFBalance += mintCost;     // add to contract balance

        uint256 newItemId = _nextTokenId++;
        uint256 currentSeed = uint256(keccak256(abi.encodePacked(newItemId, block.timestamp, block.difficulty, msg.sender))); // Simple seed

        FighterStats memory initialStats = _generateInitialStats(newItemId, currentSeed);
        fighters[newItemId] = Fighter({
            stats: initialStats,
            state: FighterState.Idle,
            stateUntil: 0,
            seed: currentSeed
        });

        _safeMint(recipient, newItemId);

        emit SyntheticMinted(newItemId, recipient, currentSeed);
        emit FighterStateChanged(newItemId, FighterState.Idle, FighterState.Idle); // Start Idle state
    }

    /**
     * @dev Gets the current stats of a Synthetic fighter.
     * @param tokenId The ID of the Synthetic.
     * @return FighterStats struct.
     */
    function getFighterStats(uint256 tokenId) public view returns (FighterStats memory) {
        require(_exists(tokenId), "CryptoColosseum: Nonexistent token");
        return fighters[tokenId].stats;
    }

    /**
     * @dev Gets the current level of a Synthetic fighter.
     * @param tokenId The ID of the Synthetic.
     * @return The fighter's level.
     */
    function getFighterLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "CryptoColosseum: Nonexistent token");
        return fighters[tokenId].stats.level;
    }

    /**
     * @dev Gets the current state of a Synthetic fighter.
     * @param tokenId The ID of the Synthetic.
     * @return The fighter's state (Idle, Training, Queued, Battling).
     */
    function getFighterState(uint256 tokenId) public view returns (FighterState) {
        require(_exists(tokenId), "CryptoColosseum: Nonexistent token");
        // Update state based on time if needed (e.g., training duration)
        if (fighters[tokenId].state == FighterState.Training && block.timestamp >= fighters[tokenId].stateUntil) {
             fighters[tokenId].state = FighterState.Idle; // State transition happens here in view function for convenience
             fighters[tokenId].stateUntil = 0;
             // In a real game, state transitions should be handled by callable functions
             // This is simplified for the example.
        }
        return fighters[tokenId].state;
    }

    /**
     * @dev Allows a fighter's owner to train its Strength stat.
     * Costs NF and puts the fighter in a Training state temporarily.
     * @param tokenId The ID of the Synthetic to train.
     */
    function trainStrength(uint256 tokenId) public whenNotPaused {
        _trainFighter(tokenId, TrainingType.Strength);
    }

    /**
     * @dev Allows a fighter's owner to train its Agility stat. Costs NF.
     * @param tokenId The ID of the Synthetic to train.
     */
    function trainAgility(uint256 tokenId) public whenNotPaused {
        _trainFighter(tokenId, TrainingType.Agility);
    }

    /**
     * @dev Allows a fighter's owner to train its Endurance stat. Costs NF.
     * @param tokenId The ID of the Synthetic to train.
     */
    function trainEndurance(uint256 tokenId) public whenNotPaused {
        _trainFighter(tokenId, TrainingType.Endurance);
    }

    /**
     * @dev Allows a fighter's owner to train its Intelligence stat. Costs NF.
     * @param tokenId The ID of the Synthetic to train.
     */
    function trainIntelligence(uint256 tokenId) public whenNotPaused {
        _trainFighter(tokenId, TrainingType.Intelligence);
    }

    /**
     * @dev Allows a fighter's owner to perform special Combat Algorithm training.
     * Costs more NF and boosts the derived Combat Rating stat significantly.
     * @param tokenId The ID of the Synthetic to train.
     */
    function optimizeCombatAlgorithm(uint256 tokenId) public whenNotPaused {
        _trainFighter(tokenId, TrainingType.CombatAlgorithm);
    }

    /**
     * @dev Internal helper for training functions. Handles state checks, NF costs, and stat updates.
     * @param tokenId The ID of the Synthetic.
     * @param trainingType The type of training to perform.
     */
    function _trainFighter(uint256 tokenId, TrainingType trainingType) internal {
        require(ownerOf(tokenId) == msg.sender, "CryptoColosseum: Caller is not the fighter owner");
        require(_isFighterReady(tokenId), "CryptoColosseum: Fighter is not ready for training (busy)");

        uint256 cost = trainingCosts[trainingType];
        require(nfBalances[msg.sender] >= cost, "CryptoColosseum: Insufficient NF balance for training.");

        // Transfer NF cost
        nfBalances[msg.sender] -= cost;
        contractNFBalance += cost;

        // Update state
        checkAndChangeFighterState(tokenId, FighterState.Idle, FighterState.Training);
        // Set training duration (example: 1 minute)
        fighters[tokenId].stateUntil = block.timestamp + 60;

        // Apply stat boosts based on training type and level
        uint256 level = fighters[tokenId].stats.level;
        uint256 boost = getAttributeBoost(level);

        if (trainingType == TrainingType.Strength) {
            fighters[tokenId].stats.strength += 1 + boost;
        } else if (trainingType == TrainingType.Agility) {
            fighters[tokenId].stats.agility += 1 + boost;
        } else if (trainingType == TrainingType.Endurance) {
            fighters[tokenId].stats.endurance += 1 + boost;
        } else if (trainingType == TrainingType.Intelligence) {
            fighters[tokenId].stats.intelligence += 1 + boost;
        } else if (trainingType == TrainingType.CombatAlgorithm) {
             // Combat algorithm training significantly boosts Combat Rating
             fighters[tokenId].stats.combatRating += 5 + (boost * 2); // Higher boost
        }

        // Recalculate derived Combat Rating if not directly trained
        if (trainingType != TrainingType.CombatAlgorithm) {
             fighters[tokenId].stats.combatRating = _calculateCombatRating(fighters[tokenId].stats);
        }

        // Training also gives a small amount of XP
        _gainExperience(tokenId, 10 + (level * 2)); // Base XP + small amount per level

        emit FighterTrained(tokenId, trainingType, cost);
    }

    /**
     * @dev Gets the NF cost for a specific training type.
     * @param trainingType The type of training.
     * @return The cost in NF.
     */
    function getTrainingCost(TrainingType trainingType) public view returns (uint256) {
        return trainingCosts[trainingType];
    }

    /**
     * @dev Allows a fighter's owner to enter it into the battle queue.
     * Costs NF and puts the fighter in a Queued state.
     * @param tokenId The ID of the Synthetic.
     */
    function enterBattleQueue(uint256 tokenId) public payable whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "CryptoColosseum: Caller is not the fighter owner");
        require(_isFighterReady(tokenId), "CryptoColosseum: Fighter is not ready to battle (busy)");
        require(nfBalances[msg.sender] >= battleEntryFee, "CryptoColosseum: Insufficient NF balance for battle entry fee.");

        // Transfer NF entry fee
        nfBalances[msg.sender] -= battleEntryFee;
        contractNFBalance += battleEntryFee;

        // Update state
        checkAndChangeFighterState(tokenId, FighterState.Idle, FighterState.Queued);
        battleQueue.push(tokenId);

        emit BattleQueued(tokenId);
    }

    /**
     * @dev Gets the current size of the battle queue.
     * @return The number of fighters in the queue.
     */
    function getBattleQueueSize() public view returns (uint256) {
        return battleQueue.length;
    }

    /**
     * @dev Processes the next battle in the queue.
     * Anyone can call this to trigger a battle and pay the gas.
     * Pairs the first two fighters, simulates the battle, updates stats,
     * and distributes rewards (adds to contract's NF balance).
     * WARNING: Uses block data for pseudo-randomness! Do not use for high-security applications.
     */
    function processNextBattle() public whenNotPaused {
        require(battleQueue.length >= 2, "CryptoColosseum: Not enough fighters in the queue for a battle.");

        // Take the first two fighters from the queue
        uint256 fighter1Id = battleQueue[0];
        uint256 fighter2Id = battleQueue[1];

        // Update states
        checkAndChangeFighterState(fighter1Id, FighterState.Queued, FighterState.Battling);
        checkAndChangeFighterState(fighter2Id, FighterState.Queued, FighterState.Battling);
        // Set battle duration (example: 30 seconds) - not strictly needed for instant sim, but represents busy state
        fighters[fighter1Id].stateUntil = block.timestamp + 30;
        fighters[fighter2Id].stateUntil = block.timestamp + 30;


        // Remove from queue (optimized way to remove first two)
        battleQueue[0] = battleQueue[battleQueue.length - 2];
        battleQueue[1] = battleQueue[battleQueue.length - 1];
        battleQueue.pop();
        battleQueue.pop();


        // Simulate battle using stats and pseudo-randomness
        uint256 randomSeed = _getRandomSeed(); // WARNING: Pseudo-random!
        (uint256 winnerId, uint256 loserId) = _simulateBattle(fighter1Id, fighter2Id, randomSeed);

        // Update fighter stats based on outcome
        fighters[winnerId].stats.battlesFought++;
        fighters[winnerId].stats.battlesWon++;
        fighters[loserId].stats.battlesFought++;

        // Winner gains XP and earns NF (added to contract balance, claimable later)
        uint256 winnerXP = calculateXPGain(fighters[winnerId].stats.level, fighters[loserId].stats.level, true);
        uint256 loserXP = calculateXPGain(fighters[loserId].stats.level, fighters[winnerId].stats.level, false);

        _gainExperience(winnerId, winnerXP);
        _gainExperience(loserId, loserXP);

        uint256 nfEarned = battleRewardAmount;
        // No direct transfer to winner's owner, add to contract balance for claiming
        contractNFBalance += nfEarned;


        // Record battle result for claiming
        lastBattleResults[winnerId] = BattleResult({
            timestamp: block.timestamp,
            opponentId: loserId,
            won: true,
            xpEarned: winnerXP,
            nfEarned: nfEarned
        });
         lastBattleResults[loserId] = BattleResult({
            timestamp: block.timestamp,
            opponentId: winnerId,
            won: false,
            xpEarned: loserXP, // Losers still get some XP
            nfEarned: 0
        });

        // Reset state to Idle after battle simulation
        checkAndChangeFighterState(fighter1Id, FighterState.Battling, FighterState.Idle);
        checkAndChangeFighterState(fighter2Id, FighterState.Battling, FighterState.Idle);
        fighters[fighter1Id].stateUntil = 0;
        fighters[fighter2Id].stateUntil = 0;


        emit BattleProcessed(fighter1Id, fighter2Id, winnerId, winnerXP, nfEarned);
    }

    /**
     * @dev Gets the result of the last battle a fighter participated in.
     * Note: This only stores the *last* battle result, not historical data.
     * @param tokenId The ID of the Synthetic.
     * @return BattleResult struct.
     */
    function getBattleResult(uint256 tokenId) public view returns (BattleResult memory) {
        require(_exists(tokenId), "CryptoColosseum: Nonexistent token");
        // Returns empty struct if no battle recorded
        return lastBattleResults[tokenId];
    }

    /**
     * @dev Allows the owner of a winning fighter to claim the NF rewards from their last battle.
     * Clears the reward amount after claiming.
     * @param tokenId The ID of the Synthetic that won the battle.
     */
    function claimBattleRewards(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "CryptoColosseum: Caller is not the fighter owner");
        BattleResult storage lastResult = lastBattleResults[tokenId];
        require(lastResult.won, "CryptoColosseum: Fighter did not win its last battle or no battle recorded.");
        require(lastResult.nfEarned > 0, "CryptoColosseum: No NF rewards available to claim for this fighter.");

        uint256 rewardAmount = lastResult.nfEarned;

        // Transfer NF from contract balance to claimant
        require(contractNFBalance >= rewardAmount, "CryptoColosseum: Contract NF balance too low (internal error)");
        contractNFBalance -= rewardAmount;
        nfBalances[msg.sender] += rewardAmount;

        // Clear the earned amount to prevent double claiming
        lastResult.nfEarned = 0;

        emit BattleRewardsClaimed(msg.sender, tokenId, rewardAmount);
    }

    /**
     * @dev Gets the total number of Synthetics ever minted.
     * @return The total count of minted NFTs.
     */
    function getTotalSyntheticsMinted() public view returns (uint256) {
        return _nextTokenId;
    }


    // --- NF Balance & Withdrawal (Owner) ---

    /**
     * @dev Gets the amount of NF held by the contract from fees/entry costs.
     * @return The contract's NF balance.
     */
    function getNFContractBalance() public view returns (uint256) {
        return contractNFBalance;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated NF fees.
     * @param amount The amount of NF to withdraw.
     */
    function withdrawNF(uint256 amount) public onlyOwner {
        require(contractNFBalance >= amount, "CryptoColosseum: Not enough NF in contract balance");
        contractNFBalance -= amount;
        nfBalances[msg.sender] += amount; // Transfer to owner's NF balance within this contract
        emit NFTransferred(address(this), msg.sender, amount);
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Allows the owner to set the NF cost for a specific training type.
     * @param trainingType The type of training.
     * @param cost The new cost in NF.
     */
    function setTrainingCost(TrainingType trainingType, uint256 cost) public onlyOwner {
        trainingCosts[trainingType] = cost;
    }

    /**
     * @dev Allows the owner to set the NF fee to enter the battle queue.
     * This is also used as the minting cost in this example contract.
     * @param fee The new entry fee in NF.
     */
    function setBattleEntryFee(uint256 fee) public onlyOwner {
        battleEntryFee = fee;
    }

    /**
     * @dev Allows the owner to set the NF reward for winning a battle.
     * @param reward The new reward amount in NF.
     */
    function setBattleRewardAmount(uint256 reward) public onlyOwner {
        battleRewardAmount = reward;
    }

    // pause() and unpause() are inherited from Pausable


    // --- Internal Helper Functions ---

    /**
     * @dev Generates initial stats for a new Synthetic based on a seed.
     * Uses simple hashing for non-uniform distribution.
     * @param tokenId The ID of the new Synthetic.
     * @param seed The seed value (e.g., derived from block data).
     * @return Initial FighterStats struct.
     */
    function _generateInitialStats(uint256 tokenId, uint256 seed) internal pure returns (FighterStats memory) {
        bytes32 hash = keccak256(abi.encodePacked(tokenId, seed));

        // Basic random stat distribution (values between 1 and 20)
        // WARNING: Based on single hash, not cryptographically secure distribution
        uint256 s = (uint256(hash) % 20) + 1;
        uint256 a = (uint256(keccak256(abi.encodePacked(hash, "agility"))) % 20) + 1;
        uint256 e = (uint256(keccak256(abi.encodePacked(hash, "endurance"))) % 20) + 1;
        uint256 i = (uint256(keccak256(abi.encodePacked(hash, "intelligence"))) % 20) + 1;

        FighterStats memory stats = FighterStats({
            strength: s,
            agility: a,
            endurance: e,
            intelligence: i,
            combatRating: 0, // Calculated below
            experience: 0,
            level: 1,
            battlesFought: 0,
            battlesWon: 0
        });

        // Calculate initial Combat Rating
        stats.combatRating = _calculateCombatRating(stats);

        return stats;
    }

    /**
     * @dev Calculates a fighter's derived Combat Rating based on their stats.
     * Simple weighted sum for this example.
     * @param stats The FighterStats struct.
     * @return The calculated Combat Rating.
     */
    function _calculateCombatRating(FighterStats memory stats) internal pure returns (uint256) {
        // Example weighting: STR + AGI + INT + END/2
        return stats.strength + stats.agility + stats.intelligence + (stats.endurance / 2);
    }

    /**
     * @dev Adds experience to a fighter and checks for level ups.
     * @param tokenId The ID of the Synthetic.
     * @param amount The amount of experience to add.
     */
    function _gainExperience(uint256 tokenId, uint256 amount) internal {
        uint256 currentXP = fighters[tokenId].stats.experience;
        uint256 currentLevel = fighters[tokenId].stats.level;
        uint256 newXP = currentXP + amount;
        fighters[tokenId].stats.experience = newXP;

        // Simplified Level Up logic (e.g., every 100 XP)
        uint256 xpNeededForNextLevel = currentLevel * 100;
        while (newXP >= xpNeededForNextLevel) {
            _levelUp(tokenId);
            currentLevel = fighters[tokenId].stats.level; // Update for next check
            xpNeededForNextLevel = currentLevel * 100;
             if (currentLevel > 100) break; // Prevent infinite loop on high levels
        }
    }

    /**
     * @dev Levels up a fighter, increasing its level and potentially boosting stats.
     * @param tokenId The ID of the Synthetic.
     */
    function _levelUp(uint256 tokenId) internal {
        uint256 oldLevel = fighters[tokenId].stats.level;
        fighters[tokenId].stats.level++;
        uint256 newLevel = fighters[tokenId].stats.level;

        // Apply a small stat boost on level up (additive to training boosts)
        uint256 levelBoost = getAttributeBoost(newLevel);
        fighters[tokenId].stats.strength += levelBoost;
        fighters[tokenId].stats.agility += levelBoost;
        fighters[tokenId].stats.endurance += levelBoost;
        fighters[tokenId].stats.intelligence += levelBoost;

        // Recalculate Combat Rating after level up stat boosts
        fighters[tokenId].stats.combatRating = _calculateCombatRating(fighters[tokenId].stats);

        emit FighterLeveledUp(tokenId, oldLevel, newLevel);
    }

     /**
      * @dev Calculates attribute boost granted by level.
      * @param level The fighter's level.
      * @return The amount to boost stats by.
      */
    function getAttributeBoost(uint256 level) internal pure returns (uint256) {
        // Example: Boost increases every 5 levels
        return level / 5;
    }


    /**
     * @dev Simulates a battle between two fighters based on their stats and randomness.
     * Uses Combat Rating + a random factor to determine winner.
     * WARNING: Pseudo-randomness from block data is NOT secure.
     * @param fighter1Id The ID of the first Synthetic.
     * @param fighter2Id The ID of the second Synthetic.
     * @param randomSeed A seed for the pseudo-random element.
     * @return winnerId The ID of the winning Synthetic.
     * @return loserId The ID of the losing Synthetic.
     */
    function _simulateBattle(uint256 fighter1Id, uint256 fighter2Id, uint256 randomSeed) internal view returns (uint256 winnerId, uint256 loserId) {
        // Fetch fighter stats
        FighterStats storage stats1 = fighters[fighter1Id].stats;
        FighterStats storage stats2 = fighters[fighter2Id].stats;

        // Calculate effective power score including a random factor
        // Random factor is % based on the seed, scaled down
        uint256 randomFactor1 = (uint256(keccak256(abi.encodePacked(randomSeed, fighter1Id))) % 10) + 95; // 95% to 104%
        uint256 randomFactor2 = (uint256(keccak256(abi.encodePacked(randomSeed, fighter2Id))) % 10) + 95; // 95% to 104%


        uint256 power1 = (stats1.combatRating * randomFactor1) / 100;
        uint256 power2 = (stats2.combatRating * randomFactor2) / 100;

        // Determine winner based on effective power
        if (power1 > power2) {
            return (fighter1Id, fighter2Id);
        } else if (power2 > power1) {
            return (fighter2Id, fighter1Id);
        } else {
            // Tie-breaker: Higher Intelligence, then Higher Agility, then lower Token ID
            if (stats1.intelligence > stats2.intelligence) return (fighter1Id, fighter2Id);
            if (stats2.intelligence > stats1.intelligence) return (fighter2Id, fighter1Id);
            if (stats1.agility > stats2.agility) return (fighter1Id, fighter2Id);
            if (stats2.agility > stats1.agility) return (fighter2Id, fighter1Id);
            // Fallback tie-breaker based on token ID (deterministic)
            if (fighter1Id < fighter2Id) return (fighter1Id, fighter2Id);
            return (fighter2Id, fighter1Id); // Fighter with lower ID wins ties
        }
    }

    /**
     * @dev Generates a pseudo-random seed using block data.
     * WARNING: This is NOT cryptographically secure and can be manipulated by miners.
     * Suitable for example games or low-value outcomes, but NOT for high-stakes applications.
     * Consider Chainlink VRF or similar decentralized oracle for real-world randomness.
     * @return A pseudo-random uint256 value.
     */
    function _getRandomSeed() internal view returns (uint256) {
         // Combine block data and potentially contract state for more entropy
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty, // block.difficulty is 0 on PoS, use block.timestamp more heavily
            gasleft(), // Gas left is somewhat unpredictable
            _nextTokenId // Contract state adds uniqueness
        )));
    }

    /**
     * @dev Checks if a fighter is in a state that allows general actions (training, queuing, transfer).
     * @param tokenId The ID of the Synthetic.
     * @return True if the fighter is Idle, False otherwise.
     */
    function _isFighterReady(uint256 tokenId) internal view returns (bool) {
         // Need to check the *actual* state, potentially accounting for stateUntil timeout
         // This implies state transitions should happen *before* state checks.
         // For simplicity in this example, let's assume state is updated elsewhere or check time here.
         FighterState currentState = getFighterState(tokenId); // Uses the view function's time check
         return currentState == FighterState.Idle;
    }

     /**
      * @dev Internal helper to safely change a fighter's state, requiring an expected current state.
      * @param tokenId The ID of the Synthetic.
      * @param expected The state the fighter is expected to be in.
      * @param newState The state to transition to.
      */
    function checkAndChangeFighterState(uint256 tokenId, FighterState expected, FighterState newState) internal {
        // Note: getFighterState *might* return Idle due to time check.
        // For reliable state transitions, actual state update should happen BEFORE this check.
        // Let's rely on the state variable directly for strict checks.
        FighterState currentState = fighters[tokenId].state;
        require(currentState == expected, "CryptoColosseum: Fighter is not in the expected state");
        fighters[tokenId].state = newState;
        emit FighterStateChanged(tokenId, currentState, newState);
    }

    /**
     * @dev Calculates XP gained from a battle based on levels and outcome.
     * @param fighter1Level Level of the first fighter.
     * @param fighter2Level Level of the second fighter.
     * @param isWinner True if fighter1 is the winner, False otherwise.
     * @return The amount of XP gained.
     */
    function calculateXPGain(uint256 fighter1Level, uint256 fighter2Level, bool isWinner) internal pure returns (uint256 xp) {
        uint256 baseXP = 50; // Base XP for participating
        uint256 levelDifference = fighter2Level > fighter1Level ? fighter2Level - fighter1Level : fighter1Level - fighter2Level;

        if (isWinner) {
            xp = baseXP + (levelDifference * 10); // More XP for beating higher levels
        } else {
            xp = baseXP / 2 + (levelDifference * 5); // Some XP for losing, more if fought higher level
        }
         if (xp < 10) xp = 10; // Minimum XP gain
    }

    // Helper library for converting uint256 to string (required by tokenURI)
    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by Oraclize API's uint256 -> string conversion
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
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + temp % 10));
                temp /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation and Notes on Advanced/Creative Aspects:**

1.  **Dynamic NFTs:** The `fighters` mapping stores all mutable stats directly on the blockchain (`strength`, `agility`, `experience`, `level`, etc.). When a user trains or battles, these on-chain stats are updated. The `tokenURI` function includes a `_baseTokenURI` which would ideally point to a service that reads these on-chain stats for a given `tokenId` and dynamically generates JSON metadata (image, attributes, etc.) reflecting the Synthetic's current state. This makes the NFT image/properties evolve based on on-chain gameplay.
2.  **On-Chain Procedural-ish Generation:** When `mintSynthetic` is called, an initial `seed` is generated using components like `block.timestamp`, `block.number`, `block.difficulty`, and `msg.sender`. This seed, combined with the unique `tokenId`, is fed into `_generateInitialStats` to create initial stats using `keccak256` hashing. This provides a unique, deterministic starting point for each fighter based on the block data at creation time, which is a form of on-chain generative data.
3.  **Simulated AI Training/Optimization:** The training functions (`trainStrength`, `trainAgility`, etc.) are designed as specific ways to improve the Synthetic's "parameters." The `optimizeCombatAlgorithm` function is highlighted as a more specialized training that focuses on the derived `combatRating` stat, framing it as refining the fighter's core combat logic. This uses AI/optimization terminology to add flavor without implementing actual machine learning on-chain (which is currently infeasible).
4.  **State-Dependent Actions:** The `FighterState` enum and the `_isFighterReady` and `checkAndChangeFighterState` helpers demonstrate managing the lifecycle of the NFT. Fighters cannot be trained, queued, or transferred if they are currently training, queued, or battling. This adds a layer of game logic and prevents conflicting actions.
5.  **Pseudo-Randomness from Block Data:** The `_simulateBattle` function incorporates a random multiplier derived from `_getRandomSeed`. `_getRandomSeed` uses `block.timestamp`, `block.number`, `block.difficulty`, `gasleft()`, and a contract state variable (`_nextTokenId`). As noted, this is NOT secure randomness for critical applications because miners can influence block data. For a simple example or a game where losing a single battle isn't financially catastrophic, it demonstrates the concept of introducing variability based on on-chain data without external oracles.

This contract combines standard patterns (minimal ERC721/ERC20, Ownable, Pausable) with custom game logic, state management, and the outlined advanced concepts to meet the requirements. It has well over 20 public/external functions and internal helpers, providing a rich example of an interactive, stateful NFT-based application on the blockchain.