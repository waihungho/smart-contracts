Here's a smart contract in Solidity called `AethelForge`, designed around dynamic, evolving NFTs ("Aethels") that double as governance tokens, powered by an internal fungible token ("Essence"), and supported by protocol-owned liquidity. It incorporates gamified evolution, reputation systems, and epoch-based progression, aiming for a creative and advanced blend of DeFi, NFTs, and GameFi concepts without direct duplication of existing large open-source projects.

---

## Contract Outline and Function Summary:

**Contract Name:** `AethelForge`

**Core Idea:** `AethelForge` is a protocol that issues `Aethels` – dynamic, evolving NFTs representing a user's influence and engagement. These Aethels possess unique attributes that change based on user interactions, "Forging" actions, and protocol events, driven by an internal `Essence` token. The protocol manages its own liquidity (POL) to fund operations, reward participants, and stabilize the ecosystem. It integrates a gamified reputation system and epoch-based progression for a dynamic user experience and adaptive governance.

---

### **I. Core Aethel NFT Management (ERC721-Like)**

1.  **`mintAethel(address to)`:**
    *   **Summary:** Mints a new Aethel NFT to the specified address. This is the entry point for users to acquire an Aethel, which comes with initial base attributes.
    *   **Concept:** Initial asset generation, similar to a genesis NFT or character creation.
2.  **`burnAethel(uint256 aethelId)`:**
    *   **Summary:** Allows the owner of an Aethel to irrevocably burn it. Burning might provide a partial `Essence` refund or serve as a strategic decision.
    *   **Concept:** Supply control, exit mechanism, or strategic asset management.
3.  **`getAethelDetails(uint256 aethelId)`:**
    *   **Summary:** Retrieves all current attributes (Essence, traits, reputation link) of a given Aethel NFT.
    *   **Concept:** On-chain data accessibility for dynamic NFTs.
4.  **`setAethelBaseURI(string memory newBaseURI)`:**
    *   **Summary:** An admin/DAO function to update the base URI used for generating Aethel NFT metadata.
    *   **Concept:** Flexible metadata management, allowing updates to the metadata server.
5.  **`tokenURI(uint256 aethelId)`:**
    *   **Summary:** Generates the dynamic metadata URI (following ERC721 standards) for a specific Aethel, reflecting its current on-chain attributes.
    *   **Concept:** Dynamic NFTs where metadata changes based on on-chain state.

### **II. Aethel Evolution & Gamification**

6.  **`forgeEssenceIntoAethel(uint256 aethelId, uint256 amount)`:**
    *   **Summary:** Allows an Aethel owner to consume `Essence` tokens to permanently increase their Aethel's core `Essence` attribute, boosting its power and value.
    *   **Concept:** "Staking" or "feeding" fungible tokens into an NFT to enhance its properties, a form of value accrual.
7.  **`evolveAethelTrait(uint256 aethelId, uint8 traitIndex)`:**
    *   **Summary:** Triggers a random evolution of a specified Aethel trait using Chainlink VRF. This action might cost `Essence` and could result in a positive, negative, or neutral change.
    *   **Concept:** Gamified, probabilistic attribute modification, leveraging verifiable randomness for fairness.
8.  **`mergeAethels(uint256 aethelId1, uint256 aethelId2)`:**
    *   **Summary:** Allows an owner to combine two of their Aethels. One Aethel is burned, and its attributes (Essence, traits) are merged (e.g., averaged, added, or randomly selected) into the surviving Aethel.
    *   **Concept:** NFT breeding/fusion mechanics, creating more powerful or unique NFTs from existing ones.
9.  **`mutateAethelRandomly()`:**
    *   **Summary:** A protocol-triggered function (e.g., during `advanceEpoch`) that applies a subtle, random mutation to a randomly selected *staked* Aethel, adding an element of ongoing unpredictability. Requires VRF.
    *   **Concept:** Global, background evolution mechanic for engaged NFTs, adding long-term dynamism.
10. **`setAethelAura(uint256 aethelId, string memory newAuraDescription)`:**
    *   **Summary:** Allows the owner to set a cosmetic, non-functional "aura" (a short description or flavor text) for their Aethel, purely for personalization.
    *   **Concept:** Personalization and narrative building for NFTs.

### **III. Essence Token & Protocol-Owned Liquidity (POL)**

11. **`distributeEssence(address[] calldata recipients, uint256[] calldata amounts)`:**
    *   **Summary:** An admin/DAO function to distribute `Essence` tokens to multiple recipients, typically for rewards, grants, or operational expenses.
    *   **Concept:** Protocol-level token distribution, treasury management.
12. **`claimEssenceRewards()`:**
    *   **Summary:** Allows users to claim accrued `Essence` rewards from various protocol activities (e.g., staking Aethels, completing challenges).
    *   **Concept:** Reward distribution mechanism, yield farming for active participation.
13. **`bondExternalAssetsForEssence(address asset, uint256 amount)`:**
    *   **Summary:** Users can deposit approved external assets (e.g., WETH, USDC) into the Protocol-Owned Liquidity in exchange for `Essence` tokens at a discounted, vested rate.
    *   **Concept:** OlympusDAO-style bonding for POL acquisition, incentivizing liquidity depth.
14. **`redeemBondedAssets(uint256 bondId)`:**
    *   **Summary:** Allows users to claim their vested `Essence` or withdraw any remaining bonded external assets based on their bond agreement.
    *   **Concept:** Vesting and claim mechanism for bonded assets.
15. **`manageProtocolLiquidity(address asset, uint256 amount, bool isDeposit)`:**
    *   **Summary:** A DAO-governed function to strategically deposit or withdraw external assets from the Protocol-Owned Liquidity.
    *   **Concept:** Active treasury management for POL, allowing strategic asset allocation and rebalancing.

### **IV. Epochs & Reputation System**

16. **`completeEpochChallenge(bytes32 challengeId, bytes calldata proof)`:**
    *   **Summary:** Users can submit proof (e.g., a hash, a signed message, or ZK-proof reference) to complete an epoch-specific challenge, earning `Reputation` points or specific Aethel trait bonuses.
    *   **Concept:** Gamified "quests" or tasks, verifiable on-chain, contributing to user reputation and NFT evolution.
17. **`advanceEpoch()`:**
    *   **Summary:** A DAO-controlled function to transition the protocol to the next epoch. This triggers global events, new challenges, and potentially subtle changes in game mechanics.
    *   **Concept:** Time-based, dynamic protocol progression, enabling new content and evolving rules.
18. **`updateReputationScore(address user, int256 delta)`:**
    *   **Summary:** An internal or protocol-triggered function to adjust a user's global `Reputation` score based on their actions (e.g., active governance, challenge completion, or penalties).
    *   **Concept:** On-chain reputation system influencing privileges or power, dynamic and adaptable.

### **V. Aethel-Based Governance**

19. **`stakeAethelForGovernance(uint256 aethelId)`:**
    *   **Summary:** Allows an Aethel owner to stake their Aethel NFT into the governance module, granting them voting power.
    *   **Concept:** NFT-as-governance, locking utility for influence.
20. **`unstakeAethelFromGovernance(uint256 aethelId)`:**
    *   **Summary:** Allows an owner to unstake their Aethel from governance, potentially with a cooldown period before it's fully transferable/usable.
    *   **Concept:** Exit mechanism for governance staking, managing voter commitment.
21. **`proposeProtocolChange(string memory description, address target, bytes calldata callData)`:**
    *   **Summary:** Users with sufficient staked Aethel power can create a new governance proposal, which includes a description and potential executable payload.
    *   **Concept:** Decentralized decision-making, direct on-chain governance.
22. **`voteOnProposal(uint256 proposalId, bool support)`:**
    *   **Summary:** Allows users to vote on active proposals using their calculated voting power, which is derived from their staked Aethels, `Essence` holdings, and `Reputation` score.
    *   **Concept:** Adaptive voting power, where influence is multifactorial and dynamic.

### **VI. VRF Integration (for randomness)**

23. **`requestRandomAethelMutation(uint256 aethelId)`:**
    *   **Summary:** Internal function to request a random number from Chainlink VRF for Aethel trait evolution or mutation.
    *   **Concept:** Secure and verifiable randomness source for in-game mechanics.
24. **`fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`:**
    *   **Summary:** The callback function invoked by the Chainlink VRF coordinator to deliver the requested random numbers, triggering the Aethel mutation logic.
    *   **Concept:** Asynchronous callback handling for off-chain randomness.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/*
*
* Contract Name: AethelForge
* Core Idea: AethelForge is a protocol that issues Aethels – dynamic, evolving NFTs representing a user's
*            influence and engagement. These Aethels possess unique attributes that change based on
*            user interactions, "Forging" actions, and protocol events, driven by an internal Essence token.
*            The protocol manages its own liquidity (POL) to fund operations, reward participants, and
*            stabilize the ecosystem. It integrates a gamified reputation system and epoch-based progression
*            for a dynamic user experience and adaptive governance.
*
*
*
* Contract Outline and Function Summary:
*
* I. Core Aethel NFT Management (ERC721-Like)
* 1.  mintAethel(address to):
*     Summary: Mints a new Aethel NFT to the specified address. This is the entry point for users to acquire an Aethel, which comes with initial base attributes.
*     Concept: Initial asset generation, similar to a genesis NFT or character creation.
* 2.  burnAethel(uint256 aethelId):
*     Summary: Allows the owner of an Aethel to irrevocably burn it. Burning might provide a partial Essence refund or serve as a strategic decision.
*     Concept: Supply control, exit mechanism, or strategic asset management.
* 3.  getAethelDetails(uint256 aethelId):
*     Summary: Retrieves all current attributes (Essence, traits, reputation link) of a given Aethel NFT.
*     Concept: On-chain data accessibility for dynamic NFTs.
* 4.  setAethelBaseURI(string memory newBaseURI):
*     Summary: An admin/DAO function to update the base URI used for generating Aethel NFT metadata.
*     Concept: Flexible metadata management, allowing updates to the metadata server.
* 5.  tokenURI(uint256 aethelId):
*     Summary: Generates the dynamic metadata URI (following ERC721 standards) for a specific Aethel, reflecting its current on-chain attributes.
*     Concept: Dynamic NFTs where metadata changes based on on-chain state.
*
* II. Aethel Evolution & Gamification
* 6.  forgeEssenceIntoAethel(uint256 aethelId, uint256 amount):
*     Summary: Allows an Aethel owner to consume Essence tokens to permanently increase their Aethel's core Essence attribute, boosting its power and value.
*     Concept: "Staking" or "feeding" fungible tokens into an NFT to enhance its properties, a form of value accrual.
* 7.  evolveAethelTrait(uint256 aethelId, uint8 traitIndex):
*     Summary: Triggers a random evolution of a specified Aethel trait using Chainlink VRF. This action might cost Essence and could result in a positive, negative, or neutral change.
*     Concept: Gamified, probabilistic attribute modification, leveraging verifiable randomness for fairness.
* 8.  mergeAethels(uint256 aethelId1, uint256 aethelId2):
*     Summary: Allows an owner to combine two of their Aethels. One Aethel is burned, and its attributes (Essence, traits) are merged (e.g., averaged, added, or randomly selected) into the surviving Aethel.
*     Concept: NFT breeding/fusion mechanics, creating more powerful or unique NFTs from existing ones.
* 9.  mutateAethelRandomly():
*     Summary: A protocol-triggered function (e.g., during advanceEpoch) that applies a subtle, random mutation to a randomly selected *staked* Aethel, adding an element of ongoing unpredictability. Requires VRF.
*     Concept: Global, background evolution mechanic for engaged NFTs, adding long-term dynamism.
* 10. setAethelAura(uint256 aethelId, string memory newAuraDescription):
*     Summary: Allows the owner to set a cosmetic, non-functional "aura" (a short description or flavor text) for their Aethel, purely for personalization.
*     Concept: Personalization and narrative building for NFTs.
*
* III. Essence Token & Protocol-Owned Liquidity (POL)
* 11. distributeEssence(address[] calldata recipients, uint256[] calldata amounts):
*     Summary: An admin/DAO function to distribute Essence tokens to multiple recipients, typically for rewards, grants, or operational expenses.
*     Concept: Protocol-level token distribution, treasury management.
* 12. claimEssenceRewards():
*     Summary: Allows users to claim accrued Essence rewards from various protocol activities (e.g., staking Aethels, completing challenges).
*     Concept: Reward distribution mechanism, yield farming for active participation.
* 13. bondExternalAssetsForEssence(address asset, uint256 amount):
*     Summary: Users can deposit approved external assets (e.g., WETH, USDC) into the Protocol-Owned Liquidity in exchange for Essence tokens at a discounted, vested rate.
*     Concept: OlympusDAO-style bonding for POL acquisition, incentivizing liquidity depth.
* 14. redeemBondedAssets(uint256 bondId):
*     Summary: Allows users to claim their vested Essence or withdraw any remaining bonded external assets based on their bond agreement.
*     Concept: Vesting and claim mechanism for bonded assets.
* 15. manageProtocolLiquidity(address asset, uint256 amount, bool isDeposit):
*     Summary: A DAO-governed function to strategically deposit or withdraw external assets from the Protocol-Owned Liquidity.
*     Concept: Active treasury management for POL, allowing strategic asset allocation and rebalancing.
*
* IV. Epochs & Reputation System
* 16. completeEpochChallenge(bytes32 challengeId, bytes calldata proof):
*     Summary: Users can submit proof (e.g., a hash, a signed message, or ZK-proof reference) to complete an epoch-specific challenge, earning Reputation points or specific Aethel trait bonuses.
*     Concept: Gamified "quests" or tasks, verifiable on-chain, contributing to user reputation and NFT evolution.
* 17. advanceEpoch():
*     Summary: A DAO-controlled function to transition the protocol to the next epoch. This triggers global events, new challenges, and potentially subtle changes in game mechanics.
*     Concept: Time-based, dynamic protocol progression, enabling new content and evolving rules.
* 18. updateReputationScore(address user, int256 delta):
*     Summary: An internal or protocol-triggered function to adjust a user's global Reputation score based on their actions (e.g., active governance, challenge completion, or penalties).
*     Concept: On-chain reputation system influencing privileges or power, dynamic and adaptable.
*
* V. Aethel-Based Governance
* 19. stakeAethelForGovernance(uint256 aethelId):
*     Summary: Allows an Aethel owner to stake their Aethel NFT into the governance module, granting them voting power.
*     Concept: NFT-as-governance, locking utility for influence.
* 20. unstakeAethelFromGovernance(uint256 aethelId):
*     Summary: Allows an owner to unstake their Aethel from governance, potentially with a cooldown period before it's fully transferable/usable.
*     Concept: Exit mechanism for governance staking, managing voter commitment.
* 21. proposeProtocolChange(string memory description, address target, bytes calldata callData):
*     Summary: Users with sufficient staked Aethel power can create a new governance proposal, which includes a description and potential executable payload.
*     Concept: Decentralized decision-making, direct on-chain governance.
* 22. voteOnProposal(uint256 proposalId, bool support):
*     Summary: Users vote on active proposals, with power modified by Essence and Reputation.
*     Concept: Adaptive voting power, where influence is multifactorial and dynamic.
*
* VI. VRF Integration (for randomness)
* 23. requestRandomAethelMutation(uint256 aethelId):
*     Summary: Internal function to request a random number from Chainlink VRF for Aethel trait evolution or mutation.
*     Concept: Secure and verifiable randomness source for in-game mechanics.
* 24. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords):
*     Summary: The callback function invoked by the Chainlink VRF coordinator to deliver the requested random numbers, triggering the Aethel mutation logic.
*     Concept: Asynchronous callback handling for off-chain randomness.
*/


// --- External Interfaces & Dummy Contracts for demonstration ---
interface IEssenceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function currentSupply() external view returns (uint256);
}

// Minimal ERC20 for Essence token if not deploying a separate one
contract EssenceToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private constant _name = "Essence";
    string private constant _symbol = "ESS";
    uint8 private constant _decimals = 18;

    constructor() {
        // Mint initial supply to deployer for testing
        _mint(msg.sender, 1_000_000_000 * (10 ** _decimals));
    }

    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(from, msg.sender, currentAllowance - amount); }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Custom AethelForge specific mint/burn for protocol control
    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public virtual onlyOwner {
        _burn(from, amount);
    }

    function currentSupply() public view returns (uint256) {
        return _totalSupply;
    }
}


// --- Main AethelForge Contract ---
contract AethelForge is ERC721, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // --- State Variables ---
    Counters.Counter private _aethelIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _bondIds;

    // Aethel Attributes
    struct Aethel {
        uint256 essenceValue; // Core power/value of the Aethel
        uint8[5] traits;      // Example traits: [Strength, Agility, Intellect, Spirit, Luck]
        uint256 mintedEpoch;  // Epoch when the Aethel was minted
        address owner;        // Current owner (redundant with ERC721 but useful for internal lookup)
        string auraDescription; // Cosmetic description
    }
    mapping(uint256 => Aethel) public aethels;

    // Aethel Governance Staking
    mapping(uint256 => bool) public isAethelStakedForGovernance;
    mapping(uint256 => uint256) public aethelUnstakeCooldown; // Cooldown end time for unstaking
    uint256 public constant UNSTAKE_COOLDOWN_DURATION = 7 days; // Example cooldown

    // Reputation System
    mapping(address => int256) public userReputation; // Can be positive or negative

    // Epoch System
    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;
    uint256 public constant EPOCH_DURATION = 30 days; // Example epoch duration

    // Essence Token & Protocol Owned Liquidity (POL)
    IEssenceToken public essenceToken;
    address public immutable DAO_ADDRESS; // Placeholder for a DAO multisig or governance contract
    mapping(address => uint256) public essenceRewardsAccrued;

    struct Bond {
        address user;
        address asset;
        uint256 amount;        // Amount of external asset bonded
        uint256 essenceAmount; // Amount of essence to be received
        uint256 startTime;
        uint256 vestingEnd;
        bool claimed;
    }
    mapping(uint256 => Bond) public bonds;
    uint256 public bondDiscountRate = 500; // 5% discount (500 basis points)
    uint256 public bondVestingDuration = 7 days; // Vesting for essence rewards

    mapping(address => uint256) public protocolLiquidity; // ERC20 -> balance in POL

    // Governance Proposals
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        address target;       // Contract to call if proposal passes
        bytes callData;       // Data to pass to the target contract
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Check if an address has voted
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant MIN_VOTING_POWER_TO_PROPOSE = 100 * 10**18; // Example: 100 ESS equivalent
    uint256 public constant VOTING_PERIOD_BLOCKS = 10000; // Approx 2 days at 13s/block

    // Chainlink VRF
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit = 100_000;
    uint16 public s_requestConfirmations = 3;
    uint32 public s_numWords = 1; // Number of random words to request

    mapping(uint256 => uint256) public requestIdToAethelId; // Map VRF request ID to Aethel ID
    mapping(uint256 => uint8) public requestIdToTraitIndex; // Map VRF request ID to trait index

    // --- Events ---
    event AethelMinted(uint256 indexed aethelId, address indexed owner, uint256 initialEssence, uint256 epoch);
    event AethelBurned(uint256 indexed aethelId, address indexed owner);
    event EssenceForged(uint256 indexed aethelId, address indexed forger, uint256 amount, uint256 newEssenceValue);
    event AethelTraitEvolved(uint256 indexed aethelId, uint8 traitIndex, int8 change, uint256 requestId);
    event AethelMerged(uint256 indexed baseAethelId, uint256 indexed sacrificedAethelId, address indexed owner);
    event AethelMutated(uint256 indexed aethelId, uint256 requestId);
    event AethelAuraSet(uint256 indexed aethelId, string newAura);

    event EssenceDistributed(address indexed distributor, address indexed recipient, uint256 amount);
    event EssenceRewardsClaimed(address indexed claimant, uint256 amount);
    event ExternalAssetsBonded(uint256 indexed bondId, address indexed user, address asset, uint256 amount, uint256 essenceAmount);
    event BondRedeemed(uint256 indexed bondId, address indexed user, uint256 essenceClaimed, uint256 assetsReturned);
    event ProtocolLiquidityManaged(address indexed manager, address asset, uint256 amount, bool isDeposit);

    event EpochAdvanced(uint256 newEpoch, uint256 timestamp);
    event ChallengeCompleted(address indexed user, bytes32 indexed challengeId, int256 reputationGained);
    event ReputationUpdated(address indexed user, int256 newReputation);

    event AethelStaked(uint256 indexed aethelId, address indexed staker);
    event AethelUnstaked(uint256 indexed aethelId, address indexed unstaker);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Errors ---
    error NotAethelOwner(uint256 aethelId, address caller);
    error AethelAlreadyStaked(uint256 aethelId);
    error AethelNotStaked(uint256 aethelId);
    error AethelUnstakeCooldownActive(uint256 aethelId, uint256 cooldownEnds);
    error InsufficientEssence(address owner, uint256 required, uint256 has);
    error InsufficientVotingPower(uint256 required, uint256 has);
    error ProposalNotActive(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotYetExecutable(uint256 proposalId);
    error ProposalExpired(uint256 proposalId);
    error InvalidAethelId(uint256 aethelId);
    error MaxTraitsReached();
    error BondNotRedeemable(uint256 bondId);
    error Unauthorized();
    error RandomRequestFailed();

    // --- Constructor ---
    constructor(
        address _essenceTokenAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _daoAddress
    )
        ERC721("Aethel", "AETHEL")
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        require(_essenceTokenAddress != address(0), "Essence Token cannot be zero address");
        require(_daoAddress != address(0), "DAO address cannot be zero address");
        essenceToken = IEssenceToken(_essenceTokenAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        DAO_ADDRESS = _daoAddress;
        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;
    }

    // --- Modifiers ---
    modifier onlyAethelOwner(uint256 aethelId) {
        if (ownerOf(aethelId) != msg.sender) revert NotAethelOwner(aethelId, msg.sender);
        _;
    }

    modifier onlyDAO() {
        if (msg.sender != DAO_ADDRESS && msg.sender != owner()) revert Unauthorized();
        _;
    }

    // --- I. Core Aethel NFT Management ---

    /// @notice Mints a new Aethel NFT to the specified address.
    /// @param to The address to mint the Aethel to.
    function mintAethel(address to) public onlyOwner returns (uint256) {
        _aethelIds.increment();
        uint256 newAethelId = _aethelIds.current();

        // Initial Aethel attributes
        Aethel memory newAethel = Aethel({
            essenceValue: 10 * 10**essenceToken.decimals(), // Starting Essence value
            traits: [1, 1, 1, 1, 1], // Base traits
            mintedEpoch: currentEpoch,
            owner: to,
            auraDescription: "A newly forged Aethel, full of potential."
        });

        aethels[newAethelId] = newAethel;
        _safeMint(to, newAethelId);

        emit AethelMinted(newAethelId, to, newAethel.essenceValue, currentEpoch);
        return newAethelId;
    }

    /// @notice Allows the owner of an Aethel to irrevocably burn it.
    /// @param aethelId The ID of the Aethel to burn.
    function burnAethel(uint256 aethelId) public onlyAethelOwner(aethelId) {
        require(aethels[aethelId].owner != address(0), "Aethel does not exist");
        if (isAethelStakedForGovernance[aethelId]) revert AethelAlreadyStaked(aethelId);

        // Optional: Provide a partial Essence refund for burning
        uint256 burnRefund = aethels[aethelId].essenceValue / 2;
        if (burnRefund > 0) {
            essenceToken.mint(msg.sender, burnRefund);
            emit EssenceDistributed(address(this), msg.sender, burnRefund);
        }

        delete aethels[aethelId]; // Clear aethel data
        _burn(aethelId);         // Burn the ERC721 token

        emit AethelBurned(aethelId, msg.sender);
    }

    /// @notice Retrieves all current attributes of a given Aethel NFT.
    /// @param aethelId The ID of the Aethel.
    /// @return Aethel struct containing its attributes.
    function getAethelDetails(uint256 aethelId) public view returns (Aethel memory) {
        require(ownerOf(aethelId) != address(0), "Aethel does not exist");
        return aethels[aethelId];
    }

    /// @notice Admin function to update the base URI for metadata.
    /// @param newBaseURI The new base URI string.
    function setAethelBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Generates the dynamic metadata URI for a specific Aethel.
    /// @param aethelId The ID of the Aethel.
    /// @return The base64 encoded JSON metadata URI.
    function tokenURI(uint256 aethelId) public view override returns (string memory) {
        require(_exists(aethelId), "ERC721Metadata: URI query for nonexistent token");
        Aethel memory aethel = aethels[aethelId];
        address aethelOwner = ownerOf(aethelId);

        // Example dynamic metadata structure
        string memory json = string(
            abi.encodePacked(
                '{"name": "Aethel #', aethelId.toString(),
                '", "description": "', aethel.auraDescription,
                '", "image": "ipfs://QmbzGZqV7QhX2fXg1Z0v8B5p8p9mX3e4f5p6r7s8t9u0/aethel_base.png', // Placeholder image
                '", "attributes": [',
                '{"trait_type": "Essence Value", "value": "', (aethel.essenceValue / (10**essenceToken.decimals())).toString(), '"},',
                '{"trait_type": "Strength", "value": "', aethel.traits[0].toString(), '"},',
                '{"trait_type": "Agility", "value": "', aethel.traits[1].toString(), '"},',
                '{"trait_type": "Intellect", "value": "', aethel.traits[2].toString(), '"},',
                '{"trait_type": "Spirit", "value": "', aethel.traits[3].toString(), '"},',
                '{"trait_type": "Luck", "value": "', aethel.traits[4].toString(), '"},',
                '{"trait_type": "Minted Epoch", "value": "', aethel.mintedEpoch.toString(), '"},',
                '{"trait_type": "Owner", "value": "', Strings.toHexString(uint160(aethelOwner), 20), '"},',
                '{"trait_type": "Reputation", "value": "', userReputation[aethelOwner].toString(), '"}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- II. Aethel Evolution & Gamification ---

    /// @notice Allows an Aethel owner to consume Essence tokens to permanently increase their Aethel's core Essence attribute.
    /// @param aethelId The ID of the Aethel to forge.
    /// @param amount The amount of Essence to consume.
    function forgeEssenceIntoAethel(uint256 aethelId, uint256 amount) public onlyAethelOwner(aethelId) {
        require(amount > 0, "Amount must be greater than zero");
        require(aethels[aethelId].owner != address(0), "Aethel does not exist");
        if (essenceToken.balanceOf(msg.sender) < amount) revert InsufficientEssence(msg.sender, amount, essenceToken.balanceOf(msg.sender));

        essenceToken.safeTransferFrom(msg.sender, address(this), amount); // Transfer Essence to protocol
        aethels[aethelId].essenceValue += amount; // Increase Aethel's internal Essence value

        emit EssenceForged(aethelId, msg.sender, amount, aethels[aethelId].essenceValue);
    }

    /// @notice Triggers a random evolution of a specified Aethel trait using Chainlink VRF.
    /// @param aethelId The ID of the Aethel to evolve.
    /// @param traitIndex The index of the trait to evolve (0-4 for Strength, Agility, Intellect, Spirit, Luck).
    function evolveAethelTrait(uint256 aethelId, uint8 traitIndex) public onlyAethelOwner(aethelId) {
        require(aethels[aethelId].owner != address(0), "Aethel does not exist");
        require(traitIndex < 5, "Invalid trait index");

        // Example cost: 10 ESS to evolve a trait
        uint256 evolutionCost = 10 * 10**essenceToken.decimals();
        if (essenceToken.balanceOf(msg.sender) < evolutionCost) revert InsufficientEssence(msg.sender, evolutionCost, essenceToken.balanceOf(msg.sender));

        essenceToken.safeTransferFrom(msg.sender, address(this), evolutionCost);

        // Request randomness for trait evolution
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        requestIdToAethelId[requestId] = aethelId;
        requestIdToTraitIndex[requestId] = traitIndex;

        emit AethelTraitEvolved(aethelId, traitIndex, 0, requestId); // Change will be 0 until VRF callback
    }

    /// @notice Allows an owner to combine two of their Aethels. One is burned, attributes merged.
    /// @param aethelId1 The ID of the primary Aethel (surviving).
    /// @param aethelId2 The ID of the sacrificed Aethel (burned).
    function mergeAethels(uint256 aethelId1, uint256 aethelId2) public onlyAethelOwner(aethelId1) onlyAethelOwner(aethelId2) {
        require(aethelId1 != aethelId2, "Cannot merge an Aethel with itself");
        require(aethels[aethelId1].owner != address(0) && aethels[aethelId2].owner != address(0), "One or both Aethels do not exist");
        if (isAethelStakedForGovernance[aethelId1] || isAethelStakedForGovernance[aethelId2]) {
             revert AethelAlreadyStaked(isAethelStakedForGovernance[aethelId1] ? aethelId1 : aethelId2);
        }

        Aethel storage baseAethel = aethels[aethelId1];
        Aethel storage sacrificedAethel = aethels[aethelId2];

        // Merge logic: Sum essence, average traits
        baseAethel.essenceValue += sacrificedAethel.essenceValue;
        for (uint8 i = 0; i < 5; i++) {
            baseAethel.traits[i] = uint8((uint256(baseAethel.traits[i]) + uint256(sacrificedAethel.traits[i])) / 2);
        }
        // Optionally update aura, or randomly pick one, or combine
        baseAethel.auraDescription = string(abi.encodePacked("Merged: ", baseAethel.auraDescription, " + ", sacrificedAethel.auraDescription));

        // Burn the sacrificed Aethel
        delete aethels[aethelId2];
        _burn(aethelId2);

        emit AethelMerged(aethelId1, aethelId2, msg.sender);
    }

    /// @notice Protocol-triggered function that applies a subtle, random mutation to a randomly selected *staked* Aethel.
    /// @dev This function should ideally be called by the DAO or Timelock on epoch advancement.
    function mutateAethelRandomly() public onlyDAO {
        // Find a random staked Aethel. (More complex logic for selection in a real system)
        // For demonstration, let's assume we randomly pick an Aethel ID that's staked.
        // A more robust system might use VRF to pick *which* staked Aethel gets mutated.
        // Or iterate through staked Aethels (if count is small).
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        // We'll use the requestId to store a placeholder for "global mutation" and then pick an Aethel in fulfillRandomWords
        // This is a simplification; a production system would need a more robust way to select *which* Aethel
        // or a list of staked Aethels to iterate over, potentially picking based on VRF.
        requestIdToAethelId[requestId] = type(uint256).max; // Sentinel value for "global mutation"
        emit AethelMutated(0, requestId); // AethelId 0 for global mutation event
    }

    /// @notice Allows the owner to set a cosmetic "aura" for their Aethel.
    /// @param aethelId The ID of the Aethel.
    /// @param newAuraDescription The new aura text.
    function setAethelAura(uint256 aethelId, string memory newAuraDescription) public onlyAethelOwner(aethelId) {
        require(aethels[aethelId].owner != address(0), "Aethel does not exist");
        aethels[aethelId].auraDescription = newAuraDescription;
        emit AethelAuraSet(aethelId, newAuraDescription);
    }


    // --- III. Essence Token & Protocol-Owned Liquidity (POL) ---

    /// @notice Admin/DAO function to distribute Essence tokens.
    /// @param recipients Array of recipient addresses.
    /// @param amounts Array of corresponding amounts.
    function distributeEssence(address[] calldata recipients, uint256[] calldata amounts) public onlyDAO {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            essenceToken.mint(recipients[i], amounts[i]);
            emit EssenceDistributed(msg.sender, recipients[i], amounts[i]);
        }
    }

    /// @notice Allows users to claim accrued Essence rewards.
    function claimEssenceRewards() public {
        uint256 rewards = essenceRewardsAccrued[msg.sender];
        require(rewards > 0, "No rewards to claim");

        essenceRewardsAccrued[msg.sender] = 0; // Reset rewards
        essenceToken.mint(msg.sender, rewards);
        emit EssenceRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Users can bond approved external assets for Essence tokens at a discounted, vested rate.
    /// @param asset The address of the external ERC20 asset (e.g., WETH, USDC).
    /// @param amount The amount of the external asset to bond.
    function bondExternalAssetsForEssence(address asset, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        IERC20 externalAsset = IERC20(asset);
        
        externalAsset.safeTransferFrom(msg.sender, address(this), amount); // Transfer to POL
        protocolLiquidity[asset] += amount;

        // Calculate Essence reward (e.g., current ESS price * amount / (1 - discount rate))
        // Simplified: Fixed ESS per external asset, with a discount.
        // A real system would use an oracle for current price, this is a placeholder.
        uint256 essenceRewardAmount = (amount * (10000 - bondDiscountRate)) / 10000; // Apply discount
        essenceRewardAmount = essenceRewardAmount * (10 ** essenceToken.decimals()) / (10 ** externalAsset.decimals()); // Adjust for decimals

        _bondIds.increment();
        uint256 bondId = _bondIds.current();

        bonds[bondId] = Bond({
            user: msg.sender,
            asset: asset,
            amount: amount,
            essenceAmount: essenceRewardAmount,
            startTime: block.timestamp,
            vestingEnd: block.timestamp + bondVestingDuration,
            claimed: false
        });

        emit ExternalAssetsBonded(bondId, msg.sender, asset, amount, essenceRewardAmount);
    }

    /// @notice Allows users to claim their vested Essence or withdraw any remaining bonded external assets.
    /// @param bondId The ID of the bond to redeem.
    function redeemBondedAssets(uint256 bondId) public {
        Bond storage bond = bonds[bondId];
        require(bond.user == msg.sender, "Not your bond");
        require(!bond.claimed, "Bond already claimed");
        require(block.timestamp >= bond.vestingEnd, "Bond is not yet fully vested");

        bond.claimed = true;
        essenceToken.mint(msg.sender, bond.essenceAmount); // Mint and transfer Essence
        // No assets are returned directly here; they remain in POL to be managed by DAO.
        // The return type is for consistency; actual implementation only awards essence here.

        emit BondRedeemed(bondId, msg.sender, bond.essenceAmount, 0); // 0 assets returned as they stay in POL
    }

    /// @notice A DAO-governed function to strategically deposit or withdraw external assets from the Protocol-Owned Liquidity.
    /// @param asset The address of the external ERC20 asset.
    /// @param amount The amount to deposit/withdraw.
    /// @param isDeposit True for deposit, false for withdrawal.
    function manageProtocolLiquidity(address asset, uint256 amount, bool isDeposit) public onlyDAO {
        require(amount > 0, "Amount must be greater than zero");
        IERC20 externalAsset = IERC20(asset);

        if (isDeposit) {
            externalAsset.safeTransferFrom(msg.sender, address(this), amount);
            protocolLiquidity[asset] += amount;
        } else {
            require(protocolLiquidity[asset] >= amount, "Insufficient protocol liquidity");
            protocolLiquidity[asset] -= amount;
            externalAsset.safeTransfer(msg.sender, amount); // DAO can withdraw to itself or another specified address
        }
        emit ProtocolLiquidityManaged(msg.sender, asset, amount, isDeposit);
    }

    // --- IV. Epochs & Reputation System ---

    /// @notice Users can submit proof to complete an epoch-specific challenge.
    /// @param challengeId Identifier for the challenge.
    /// @param proof Verifiable proof for challenge completion (e.g., hash, signed data).
    function completeEpochChallenge(bytes32 challengeId, bytes calldata proof) public {
        // Placeholder for challenge verification logic.
        // A real system would have specific logic to verify 'proof' for 'challengeId'.
        // For example: `require(verifyChallengeProof(challengeId, proof, msg.sender), "Invalid proof");`
        // For demonstration, we assume proof is always valid.

        int256 reputationGain = 10; // Example reputation gain
        updateReputationScore(msg.sender, reputationGain);
        essenceRewardsAccrued[msg.sender] += 5 * 10**essenceToken.decimals(); // Example Essence reward

        // Optional: Grant a temporary or permanent trait bonus to user's Aethel (if they have one)
        // This would involve finding the user's Aethels and applying logic.

        emit ChallengeCompleted(msg.sender, challengeId, reputationGain);
    }

    /// @notice DAO-controlled function to transition to the next epoch.
    function advanceEpoch() public onlyDAO {
        require(block.timestamp >= lastEpochAdvanceTime + EPOCH_DURATION, "Epoch duration not yet passed");

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // Trigger global events:
        // - Distribute general epoch rewards
        // - Potentially initiate Aethel mutations (call mutateAethelRandomly)
        // - Introduce new challenges
        // - Adjust protocol parameters
        
        // Example: Request random mutation for one staked Aethel globally (simplified)
        // mutateAethelRandomly(); // Uncomment to enable background mutation every epoch

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /// @notice Internal or protocol-triggered function to adjust a user's global Reputation score.
    /// @param user The address whose reputation to update.
    /// @param delta The change in reputation (positive for gain, negative for loss).
    function updateReputationScore(address user, int256 delta) internal {
        int256 newRep = userReputation[user] + delta;
        // Optional: Cap reputation min/max values
        if (newRep < -100) newRep = -100;
        if (newRep > 1000) newRep = 1000;
        userReputation[user] = newRep;
        emit ReputationUpdated(user, newRep);
    }

    // --- V. Aethel-Based Governance ---

    /// @notice Allows an Aethel owner to stake their Aethel NFT for governance.
    /// @param aethelId The ID of the Aethel to stake.
    function stakeAethelForGovernance(uint256 aethelId) public onlyAethelOwner(aethelId) {
        require(!isAethelStakedForGovernance[aethelId], "Aethel is already staked");
        require(aethels[aethelId].owner != address(0), "Aethel does not exist");

        // Transfer NFT to contract for staking
        _transfer(msg.sender, address(this), aethelId);
        isAethelStakedForGovernance[aethelId] = true;
        delete aethelUnstakeCooldown[aethelId]; // Clear any pending cooldown

        emit AethelStaked(aethelId, msg.sender);
    }

    /// @notice Allows an owner to unstake their Aethel from governance.
    /// @param aethelId The ID of the Aethel to unstake.
    function unstakeAethelFromGovernance(uint256 aethelId) public {
        require(ownerOf(aethelId) == address(this), "Aethel not staked in governance");
        require(isAethelStakedForGovernance[aethelId], "Aethel is not marked as staked");
        
        // Ensure cooldown has passed if one was active
        if (aethelUnstakeCooldown[aethelId] > block.timestamp) {
            revert AethelUnstakeCooldownActive(aethelId, aethelUnstakeCooldown[aethelId]);
        }

        // Apply a cooldown for unstaking (starts only *after* request)
        aethelUnstakeCooldown[aethelId] = block.timestamp + UNSTAKE_COOLDOWN_DURATION;

        // Transfer NFT back to original staker (msg.sender who initially staked it)
        // NOTE: In a more complex system, this might track original staker, not just current msg.sender
        address originalStaker = msg.sender; // Simplified: assumes current caller is original staker
        _transfer(address(this), originalStaker, aethelId);
        isAethelStakedForGovernance[aethelId] = false;

        emit AethelUnstaked(aethelId, originalStaker);
    }


    /// @notice Users with sufficient staked Aethel power can create a new governance proposal.
    /// @param description Text description of the proposal.
    /// @param target The address of the contract the proposal will call.
    /// @param callData The data to be sent with the call (encoded function call).
    function proposeProtocolChange(string memory description, address target, bytes calldata callData) public {
        // Calculate voting power of proposer
        uint256 proposerPower = _getVotingPower(msg.sender);
        if (proposerPower < MIN_VOTING_POWER_TO_PROPOSE) revert InsufficientVotingPower(MIN_VOTING_POWER_TO_PROPOSE, proposerPower);

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            proposer: msg.sender,
            target: target,
            callData: callData,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD_BLOCKS,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].startBlock, proposals[proposalId].endBlock);
    }

    /// @notice Users vote on active proposals, with power modified by Essence and Reputation.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Proposal not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.forVotes += voterPower;
        } else {
            proposal.againstVotes += voterPower;
        }

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /// @notice Executes a passed proposal. Only callable after voting period ends and if quorum is met.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public onlyDAO {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.number > proposal.endBlock, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");
        
        // Simple majority vote: For > Against
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass (more 'against' or tied)");

        // Execute the payload
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /// @dev Calculates the total voting power for a user based on staked Aethels, Essence, and Reputation.
    function _getVotingPower(address user) internal view returns (uint256) {
        uint256 power = 0;
        // Power from staked Aethels (simplified: sum of essence values of staked Aethels)
        uint256 aethelCount = balanceOf(user);
        for (uint256 i = 0; i < aethelCount; i++) {
            uint256 aethelId = tokenOfOwnerByIndex(user, i); // Gets Aethel owned by user
            if (isAethelStakedForGovernance[aethelId]) { // Check if *this* Aethel is staked
                power += aethels[aethelId].essenceValue;
            }
        }
        // Power from raw Essence holdings (e.g., 1:1)
        power += essenceToken.balanceOf(user);

        // Power modification by Reputation (e.g., 1% bonus per 100 reputation)
        int256 reputation = userReputation[user];
        if (reputation > 0) {
            power = (power * (10000 + uint256(reputation))) / 10000; // +1% per 100 reputation points (basis points)
        } else if (reputation < 0) {
            // Penalize negative reputation
            power = (power * (10000 - uint256(-reputation) * 10)) / 10000; // -10% per 100 negative reputation
        }
        return power;
    }

    // --- VI. VRF Integration (for randomness) ---

    /// @notice Internal function to request a random number from Chainlink VRF for Aethel trait evolution or mutation.
    /// @param aethelId The ID of the Aethel to which the randomness applies (or type(uint256).max for global).
    /// @return requestId The ID of the VRF request.
    function requestRandomAethelMutation(uint256 aethelId) internal returns (uint256 requestId) {
         requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        requestIdToAethelId[requestId] = aethelId;
        // traitIndex will be stored directly if specific trait evolution (evolveAethelTrait), otherwise defaults
        return requestId;
    }

    /// @notice The callback function invoked by the Chainlink VRF coordinator to deliver the requested random numbers.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords An array of random words.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 aethelId = requestIdToAethelId[requestId];
        require(aethelId != 0, "Unknown request ID or Aethel already processed");

        uint256 randomNumber = randomWords[0];
        
        if (aethelId == type(uint256).max) {
            // Handle global mutation: find a random *staked* Aethel
            // This is a simplified way to pick one. A real system might maintain a list
            // of staked Aethels or use more sophisticated on-chain selection.
            uint256 totalStaked = 0;
            // Iterate through all possible Aethels (up to max minted ID), check if staked.
            // This is inefficient for large numbers of Aethels.
            // Better: Keep a list/array of staked Aethel IDs.
            for (uint256 i = 1; i <= _aethelIds.current(); i++) {
                if (isAethelStakedForGovernance[i]) {
                    totalStaked++;
                }
            }
            if (totalStaked > 0) {
                uint256 targetIndex = randomNumber % totalStaked;
                uint256 currentCount = 0;
                for (uint256 i = 1; i <= _aethelIds.current(); i++) {
                    if (isAethelStakedForGovernance[i]) {
                        if (currentCount == targetIndex) {
                            aethelId = i; // This is our randomly selected staked Aethel
                            break;
                        }
                        currentCount++;
                    }
                }
            } else {
                return; // No staked Aethels to mutate
            }
        }

        // Apply mutation to the Aethel
        if (aethels[aethelId].owner == address(0)) {
            // Aethel might have been burned between request and fulfill
            return; 
        }

        int8 traitChange = int8((randomNumber % 7) - 3); // Random change between -3 and +3
        uint8 traitToModify = requestIdToTraitIndex[requestId]; // Specific trait for evolveAethelTrait
        
        if (traitToModify == 0 && aethelId != type(uint256).max) { // If it was a generic mutation request (not specific trait evo)
             traitToModify = uint8(randomNumber % 5); // Pick a random trait for global mutation
        }

        aethels[aethelId].traits[traitToModify] = uint8(int8(aethels[aethelId].traits[traitToModify]) + traitChange);
        
        // Ensure traits don't go below 1 or above 10 (example limits)
        if (aethels[aethelId].traits[traitToModify] < 1) aethels[aethelId].traits[traitToModify] = 1;
        if (aethels[aethelId].traits[traitToModify] > 10) aethels[aethelId].traits[traitToModify] = 10;

        emit AethelTraitEvolved(aethelId, traitToModify, traitChange, requestId);

        // Clear mapping entries
        delete requestIdToAethelId[requestId];
        delete requestIdToTraitIndex[requestId];
    }
}

// Minimal Base64 library from OpenZeppelin for on-chain metadata
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = _TABLE;

        // allocate output buffer with space for base64 encoded data
        uint256 lastElementLength = data.length % 3;
        uint256 padding = lastElementLength == 0 ? 0 : (3 - lastElementLength);
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory hs = new string(encodedLen);
        uint256 ptr = 0;
        uint256 idx = 0;

        while (idx < data.length) {
            uint256 input;
            uint256 have = data.length - idx;
            if (have < 3) {
                input = uint256(data[idx++]) << 16;
                if (have == 2) {
                    input |= uint256(data[idx++]) << 8;
                }
            } else {
                input = (uint256(data[idx]) << 16) | (uint256(data[idx + 1]) << 8) | uint256(data[idx + 2]);
                idx += 3;
            }

            bytes(hs)[ptr++] = bytes1(table[(input >> 18) & 0x3F]);
            bytes(hs)[ptr++] = bytes1(table[(input >> 12) & 0x3F]);
            if (have > 1) {
                bytes(hs)[ptr++] = bytes1(table[(input >> 6) & 0x3F]);
            } else {
                bytes(hs)[ptr++] = "=";
            }
            if (have > 2) {
                bytes(hs)[ptr++] = bytes1(table[input & 0x3F]);
            } else {
                bytes(hs)[ptr++] = "=";
            }
        }
        return hs;
    }
}
```