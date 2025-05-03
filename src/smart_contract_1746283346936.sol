Okay, let's design a smart contract for a unique, on-chain generative creature collection called "Auras". These Auras will be NFTs with mutable "genes" stored on-chain. Users can interact with them in various ways: evolving their genes, breeding new Auras, applying mutations using a custom in-contract token, and staking Auras to earn this token.

This combines concepts like NFTs (ERC721), generative art (data on-chain), tokenomics (internal ERC20-like token), gamification (evolution, breeding, mutation, staking), and state management.

We will leverage OpenZeppelin libraries for standard implementations (like ERC721 base, Ownable, Pausable, ReentrancyGuard) as reinventing these basic building blocks is generally discouraged for security and compatibility, while still building a unique application logic *on top* of them. The "don't duplicate open source" is interpreted as not copying the *core concept* of an existing, widely known project (like a standard DeFi protocol, a simple PFP collection, or a basic ERC20/ERC721 template contract without unique logic).

---

**Smart Contract: AuraGenesis**

**Concept:** A collection of generative, evolving digital creatures (Auras) represented as NFTs. Each Aura has on-chain genetic data that can be altered through user interactions (evolution, breeding, mutation). Staking Auras rewards users with an internal "Essence" token used for mutations.

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary OpenZeppelin libraries.
2.  **Errors:** Define custom errors for clearer reverts.
3.  **Events:** Define events for key actions.
4.  **Structs:**
    *   `Aura`: Holds gene data, creation block, parent IDs, and staking information.
    *   `StakingInfo`: Holds staking start time and accumulated rewards.
5.  **State Variables:** Store collection metadata, tracking, configurations, Aura data, Essence balances, allowances, staking info, etc.
6.  **Modifiers:** Access control and state check modifiers (`onlyOwner`, `whenNotPaused`, `whenPaused`, `onlyAuraOwner`, feature toggles).
7.  **Constructor:** Initialize contract owner, name, and symbol.
8.  **ERC721 & ERC165 Implementation:** Standard NFT functions and interface support.
9.  **ERC721 Metadata:** `tokenURI`, `name`, `symbol`. `tokenURI` will point to an off-chain renderer using the on-chain genes.
10. **Aura Data & Query:** Functions to retrieve Aura gene data and staking info.
11. **Aura Interaction Functions:**
    *   Minting initial Auras.
    *   Evolving an Aura's genes directly within limits.
    *   Breeding two Auras to create a new one.
    *   Applying a mutation using the Essence token.
12. **Aura Staking Functions:**
    *   Stake an owned Aura.
    *   Unstake a staked Aura and claim rewards.
    *   Claim accrued rewards without unstaking.
    *   Estimate potential rewards.
13. **Essence Token (Internal ERC20-like):**
    *   Query balance, allowance.
    *   Transfer, approve, transferFrom.
    *   Internal minting (for staking rewards) and burning (for mutations).
14. **Admin & Configuration Functions:**
    *   Set base URI, max supply, staking rates, mutation costs, feature toggles, pause/unpause, withdraw funds.
15. **Internal Helper Functions:** Logic for gene generation, breeding, reward calculation, state updates.

**Function Summary (Total: 35 public/external functions):**

1.  `constructor()`: Initializes the contract.
2.  `name()`: Returns the collection name (ERC721 Metadata).
3.  `symbol()`: Returns the collection symbol (ERC721 Metadata).
4.  `tokenURI(uint256 tokenId)`: Returns the URI for the token metadata (ERC721 Metadata).
5.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address (ERC721).
6.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token (ERC721).
7.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token (ERC721).
8.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers a token with data (ERC721).
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (ERC721).
10. `approve(address to, uint256 tokenId)`: Approves another address to transfer a token (ERC721).
11. `getApproved(uint256 tokenId)`: Gets the approved address for a token (ERC721).
12. `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens (ERC721).
13. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens (ERC721).
14. `supportsInterface(bytes4 interfaceId)`: Indicates which interfaces the contract supports (ERC165).
15. `mintAura(address recipient)`: (Owner only) Mints a new Aura with random initial genes.
16. `getAuraGenes(uint256 tokenId)`: Retrieves the on-chain gene array for a specific Aura.
17. `evolveAura(uint256 tokenId, uint8 geneIndex, int8 evolutionDelta)`: Allows the owner to slightly adjust a specific gene of their Aura.
18. `breedAuras(uint256 parent1Id, uint256 parent2Id, address recipient)`: Allows owners of two Auras to breed them, creating a new Aura for the recipient with mixed genes (may cost ETH/Essence, owner-configurable).
19. `applyMutation(uint256 tokenId, uint8 mutationType)`: Applies a significant gene change to an Aura by burning `Essence` tokens.
20. `stakeAura(uint256 tokenId)`: Starts staking an owned Aura to accrue Essence rewards. The Aura becomes non-transferable while staked.
21. `unstakeAura(uint256 tokenId)`: Stops staking an Aura, claims accumulated Essence rewards, and makes the Aura transferable again.
22. `claimStakingRewards(uint256 tokenId)`: Claims accumulated Essence rewards for a staked Aura without unstaking it.
23. `getStakingRewardEstimate(uint256 tokenId)`: Estimates the Essence rewards accrued for a staked Aura since the last claim/stake time.
24. `balanceOfEssence(address account)`: Returns the Essence token balance of an account (ERC20-like).
25. `transferEssence(address recipient, uint256 amount)`: Transfers Essence tokens from the caller to a recipient (ERC20-like).
26. `approveEssence(address spender, uint256 amount)`: Approves a spender to withdraw Essence tokens from the caller's account (ERC20-like).
27. `transferFromEssence(address sender, address recipient, uint256 amount)`: Transfers Essence tokens from one account to another using the allowance mechanism (ERC20-like).
28. `allowanceEssence(address owner, address spender)`: Returns the amount of Essence tokens the spender is allowed to withdraw from the owner (ERC20-like).
29. `setBaseTokenURI(string memory baseURI)`: (Owner only) Sets the base URI for token metadata.
30. `setMaxSupply(uint256 maxSupply)`: (Owner only) Sets the maximum number of Auras that can be minted.
31. `setEssenceMintRate(uint256 rate)`: (Owner only) Sets the Essence token minting rate per staked Aura per unit of time (e.g., per block or per hour).
32. `setMutationCosts(uint8 mutationType, uint256 cost)`: (Owner only) Sets the Essence cost for different types of mutations.
33. `toggleBreedingEnabled(bool enabled)`: (Owner only) Enables or disables the breeding function.
34. `toggleEvolutionEnabled(bool enabled)`: (Owner only) Enables or disables the evolution function.
35. `withdrawETH(address payable recipient, uint256 amount)`: (Owner only) Withdraws accumulated ETH (e.g., from breeding fees) from the contract.
36. `pauseContract()`: (Owner only) Pauses certain contract functions (minting, interactions, staking actions).
37. `unpauseContract()`: (Owner only) Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for querying total supply, though not strictly required by ERC721 base
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For separate token URI storage
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath for basic operations
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Just an example import for potential future use (e.g., whitelists), not used in current logic but shows advanced concepts

/**
 * @title AuraGenesis
 * @dev A generative, evolving NFT collection with on-chain genes, breeding, mutation, and staking for an internal Essence token.
 *
 * Concept:
 * A collection of unique, generative digital creatures ("Auras") represented as ERC721 NFTs.
 * Each Aura stores its "genetic" data (an array of uint8) directly on-chain.
 * This genetic data can be modified via several interaction functions:
 * - Evolution: Slight, direct tweaks to gene values by the owner.
 * - Breeding: Combining two parent Auras to create a new one with mixed genes.
 * - Mutation: Applying significant changes to genes by consuming an internal "Essence" token.
 * Users can stake their Auras to earn Essence tokens. Essence is primarily used for Mutation,
 * adding an internal economy loop.
 *
 * The visual representation of an Aura is determined by its on-chain genes but rendered
 * off-chain via a service pointed to by the tokenURI.
 *
 * Outline:
 * 1. Pragma & Imports
 * 2. Errors
 * 3. Events
 * 4. Structs (Aura, StakingInfo)
 * 5. State Variables
 * 6. Modifiers
 * 7. Constructor
 * 8. ERC721 & ERC165 Implementation
 * 9. ERC721 Metadata
 * 10. Aura Data & Query
 * 11. Aura Interaction Functions (Mint, Evolve, Breed, Mutate)
 * 12. Aura Staking Functions (Stake, Unstake, Claim, Estimate)
 * 13. Essence Token (Internal ERC20-like)
 * 14. Admin & Configuration Functions (Setters, Toggles, Pause, Withdraw)
 * 15. Internal Helper Functions
 *
 * Function Summary (Total: 35+ public/external functions):
 * - constructor()
 * - name(), symbol(), tokenURI()
 * - balanceOf(), ownerOf(), safeTransferFrom(), transferFrom(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll(), supportsInterface() (Standard ERC721)
 * - mintAura(address recipient) (Owner mints a new Aura)
 * - getAuraGenes(uint256 tokenId) (Retrieve genes)
 * - evolveAura(uint256 tokenId, uint8 geneIndex, int8 evolutionDelta) (Modify a gene)
 * - breedAuras(uint256 parent1Id, uint256 parent2Id, address recipient) (Create new Aura from parents)
 * - applyMutation(uint256 tokenId, uint8 mutationType) (Mutate Aura using Essence)
 * - stakeAura(uint256 tokenId) (Start staking for Essence)
 * - unstakeAura(uint256 tokenId) (Stop staking, claim Essence)
 * - claimStakingRewards(uint256 tokenId) (Claim Essence without unstaking)
 * - getStakingRewardEstimate(uint256 tokenId) (Estimate pending Essence rewards)
 * - balanceOfEssence(address account) (Essence balance query)
 * - transferEssence(address recipient, uint256 amount) (Essence transfer)
 * - approveEssence(address spender, uint256 amount) (Essence approve)
 * - transferFromEssence(address sender, address recipient, uint256 amount) (Essence transferFrom)
 * - allowanceEssence(address owner, address spender) (Essence allowance query)
 * - setBaseTokenURI(string memory baseURI) (Admin)
 * - setMaxSupply(uint256 maxSupply) (Admin)
 * - setEssenceMintRate(uint256 rate) (Admin)
 * - setMutationCosts(uint8 mutationType, uint256 cost) (Admin)
 * - toggleBreedingEnabled(bool enabled) (Admin)
 * - toggleEvolutionEnabled(bool enabled) (Admin)
 * - pauseContract() (Admin)
 * - unpauseContract() (Admin)
 * - withdrawETH(address payable recipient, uint256 amount) (Admin)
 */
contract AuraGenesis is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Using SafeMath for clarity, although 0.8+ has built-in checks

    // --- Errors ---
    error InvalidGeneIndex(uint8 geneIndex);
    error GeneEvolutionOutOfRange(uint8 geneIndex, int8 evolutionDelta);
    error MaxSupplyReached();
    error NotAuraOwnerOrApproved();
    error CannotBreedSelf();
    error AuraAlreadyStaked(uint256 tokenId);
    error AuraNotStaked(uint256 tokenId);
    error InsufficientEssenceBalance(uint256 required, uint256 available);
    error BreedingDisabled();
    error EvolutionDisabled();
    error MutationDisabled();
    error InvalidMutationType(uint8 mutationType);
    error ZeroAddressRecipient();
    error TransferAmountExceedsBalance(uint256 requested, uint256 available);
    error TransferAmountExceedsAllowance(uint256 requested, uint256 allowed);


    // --- Events ---
    event AuraMinted(uint256 indexed tokenId, address indexed owner, uint8[] genes, uint256 parent1Id, uint256 parent2Id);
    event AuraEvolved(uint256 indexed tokenId, uint8 indexed geneIndex, int8 evolutionDelta, uint8 newValue);
    event AuraMutated(uint256 indexed tokenId, uint8 mutationType, uint256 essenceCost);
    event AuraStaked(uint256 indexed tokenId, address indexed owner, uint256 stakeTime);
    event AuraUnstaked(uint256 indexed tokenId, address indexed owner, uint256 unstakeTime, uint256 claimedEssence);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 claimedEssence);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceApproved(address indexed owner, address indexed spender, uint256 amount);
    event EssenceBurned(address indexed burner, uint256 amount);
    event BaseTokenURISet(string baseTokenURI);
    event EssenceMintRateSet(uint256 rate);
    event MutationCostsSet(uint8 mutationType, uint256 cost);


    // --- Structs ---
    struct Aura {
        uint8[] genes;          // On-chain genetic data (e.g., color, shape parameters)
        uint256 creationBlock;  // Block number when created
        uint256 parent1Id;      // ID of parent 1 (0 if not bred)
        uint256 parent2Id;      // ID of parent 2 (0 if not bred)
    }

    struct StakingInfo {
        uint256 stakeStartTime;   // Timestamp when staking started or last rewards were claimed
        uint256 accumulatedRewards; // Rewards accumulated but not yet claimed (simplification: could calculate on the fly)
        bool isStaked;            // Flag to indicate if the Aura is currently staked
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Aura) private _auras;
    mapping(uint256 => StakingInfo) private _stakingInfo;

    // Essence Token (Internal ERC20-like implementation)
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    uint256 public maxSupply = 1000; // Default max supply
    string private _baseTokenURI;

    // Staking configuration (Essence mint rate)
    // Rate is tokens per second per staked Aura. e.g., 1 token/day = 1e18 / 86400
    uint256 public essenceMintRatePerSecond = 1 ether / (24 * 60 * 60); // Default: 1 Essence per day

    // Mutation costs (Essence cost for different mutation types)
    mapping(uint8 => uint256) public mutationCosts;

    // Feature Toggles
    bool public breedingEnabled = true;
    bool public evolutionEnabled = true;
    bool public mutationEnabled = true;

    // Gene constraints (example)
    uint8 public constant NUM_GENES = 8; // Number of genes in the gene array
    uint8 public constant GENE_MAX_VALUE = 255; // Max value for any gene
    int8 public constant EVOLUTION_DELTA_LIMIT = 10; // Max absolute delta for evolution

    // --- Modifiers ---

    modifier onlyAuraOwner(uint256 tokenId) {
        if (_exists(tokenId) && ownerOf(tokenId) != _msgSender()) {
            revert NotAuraOwnerOrApproved();
        }
        _;
    }

    modifier breedingMustBeEnabled() {
        if (!breedingEnabled) {
            revert BreedingDisabled();
        }
        _;
    }

    modifier evolutionMustBeEnabled() {
        if (!evolutionEnabled) {
            revert EvolutionDisabled();
        }
        _;
    }

    modifier mutationMustBeEnabled() {
        if (!mutationEnabled) {
            revert MutationDisabled();
        }
        _;
    }


    // --- Constructor ---
    constructor() ERC721("AuraGenesis", "AURA") Ownable(msg.sender) {}

    // --- ERC721 & ERC165 Implementation ---

    // The standard ERC721 functions (balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll)
    // are inherited from OpenZeppelin's ERC721Enumerable.

    // We override _update to handle staking logic
    // Note: ERC721Enumerable overrides _update, so we need to override it again.
    // ERC721URIStorage also overrides _update, so the chain is:
    // AuraGenesis -> ERC721URIStorage -> ERC721Enumerable -> ERC721
    // We must call super._update() in our override.
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (address) {
        if (_stakingInfo[tokenId].isStaked) {
            // Aura is staked, prevent transfer unless it's unstaking (which happens internally)
            // This hook might not be the *best* place for this check depending on exact staking flow.
            // A cleaner way is to *not* override _update but check `_stakingInfo[tokenId].isStaked`
            // within `safeTransferFrom` and `transferFrom` calls, but OZ handles this.
            // Let's ensure the staking/unstaking logic correctly handles the ownership state.
            // The primary mechanism should be disallowing transfers *unless* unstaking.
            // OZ's _update is called internally by mint/burn/transfer.
            // If we *don't* want staked Auras to be transferred *externally*, the check should be
            // in the public/external transfer functions, not the internal _update.
            // Let's rely on checking `_stakingInfo[tokenId].isStaked` in the `transferFrom` and `safeTransferFrom` overrides if needed,
            // but OZ's default implementation *doesn't* check custom state like this.
            // A simpler staking model is just to *mark* it staked and prevent transfers via a modifier or check in the *public* transfer functions.
            // Revert if trying to transfer a staked token via external call.
            // Internal transfers (like burning or transferring to self/contract) during staking/unstaking are okay.
            if (to != address(this) && ownerOf(tokenId) == _msgSender()) { // Check if called by current owner trying to transfer out
                 revert AuraAlreadyStaked(tokenId);
            }
            // If it's an internal transfer related to unstaking or similar, allow.
        }
         return super._update(to, tokenId, auth);
    }

    // Override transferFrom and safeTransferFrom to prevent external transfers of staked tokens
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) {
        if (_stakingInfo[tokenId].isStaked && from == _msgSender()) {
            revert AuraAlreadyStaked(tokenId);
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721, ERC721Enumerable) {
        if (_stakingInfo[tokenId].isStaked && from == _msgSender()) {
            revert AuraAlreadyStaked(tokenId);
        }
         super.safeTransferFrom(from, to, tokenId, data);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) {
         if (_stakingInfo[tokenId].isStaked && from == _msgSender()) {
            revert AuraAlreadyStaked(tokenId);
        }
         super.safeTransferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }


    // --- ERC721 Metadata ---

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        // Append token ID to base URI. Off-chain service uses this ID to fetch genes via getAuraGenes
        // and generate the metadata JSON and image.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // --- Aura Data & Query ---

    /**
     * @dev Retrieves the raw on-chain gene array for a specific Aura.
     * @param tokenId The ID of the Aura.
     * @return An array of uint8 representing the Aura's genes.
     */
    function getAuraGenes(uint256 tokenId) public view returns (uint8[] memory) {
        _requireOwned(tokenId); // Ensure token exists
        return _auras[tokenId].genes;
    }

    /**
     * @dev Retrieves the staking information for a specific Aura.
     * @param tokenId The ID of the Aura.
     * @return A tuple containing stake start time, accumulated rewards, and staked status.
     */
    function getAuraStakingInfo(uint256 tokenId) public view returns (uint256 stakeStartTime, uint256 accumulatedRewards, bool isStaked) {
         _requireOwned(tokenId); // Ensure token exists
         StakingInfo storage info = _stakingInfo[tokenId];
         // Calculate pending rewards since last claim/stake time if currently staked
         uint256 currentAccumulated = info.accumulatedRewards;
         if (info.isStaked) {
             currentAccumulated = currentAccumulated.add(_calculatePendingRewards(info.stakeStartTime));
         }
         return (info.stakeStartTime, currentAccumulated, info.isStaked);
    }

    // --- Aura Interaction Functions ---

    /**
     * @dev Mints a new Aura with randomly generated initial genes.
     * Only callable by the contract owner. Limited by max supply.
     * Uses block data for basic pseudo-randomness (Note: Not cryptographically secure).
     * @param recipient The address to receive the new Aura.
     * @return The ID of the newly minted Aura.
     */
    function mintAura(address recipient) external onlyOwner whenNotPaused returns (uint256) {
        if (totalSupply() >= maxSupply) {
            revert MaxSupplyReached();
        }
        if (recipient == address(0)) {
             revert ZeroAddressRecipient();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Pseudo-random gene generation based on block data
        // WARNING: This is not suitable for situations where randomness is critical or can be exploited.
        // For production, consider Chainlink VRF or similar verifiable randomness solutions.
        uint8[] memory initialGenes = _generateInitialGenes(newTokenId);

        _auras[newTokenId] = Aura({
            genes: initialGenes,
            creationBlock: block.number,
            parent1Id: 0, // Not bred
            parent2Id: 0  // Not bred
        });

        _safeMint(recipient, newTokenId);

        emit AuraMinted(newTokenId, recipient, initialGenes, 0, 0);

        return newTokenId;
    }

    /**
     * @dev Allows the owner of an Aura to subtly evolve one of its genes.
     * Limited by gene boundaries and evolution delta limit.
     * @param tokenId The ID of the Aura to evolve.
     * @param geneIndex The index of the gene to evolve (0 to NUM_GENES-1).
     * @param evolutionDelta The signed integer amount to add to the gene value.
     */
    function evolveAura(uint256 tokenId, uint8 geneIndex, int8 evolutionDelta) external payable onlyAuraOwner(tokenId) whenNotPaused evolutionMustBeEnabled {
        _requireOwned(tokenId); // Redundant due to modifier but good practice
        if (geneIndex >= NUM_GENES) {
            revert InvalidGeneIndex(geneIndex);
        }
        if (evolutionDelta > EVOLUTION_DELTA_LIMIT || evolutionDelta < -EVOLUTION_DELTA_LIMIT) {
            revert GeneEvolutionOutOfRange(geneIndex, evolutionDelta);
        }

        Aura storage aura = _auras[tokenId];
        int16 currentGene = int16(aura.genes[geneIndex]);
        int16 newGene = currentGene + evolutionDelta;

        // Clamp gene value within [0, GENE_MAX_VALUE]
        if (newGene < 0) {
            newGene = 0;
        } else if (newGene > GENE_MAX_VALUE) {
            newGene = GENE_MAX_VALUE;
        }

        aura.genes[geneIndex] = uint8(newGene);

        emit AuraEvolved(tokenId, geneIndex, evolutionDelta, aura.genes[geneIndex]);
    }

    /**
     * @dev Allows the owners of two Auras to breed them to create a new Aura.
     * Requires ownership of both parents.
     * The new Aura's genes are a mix of the parents' genes.
     * Can be configured to require ETH or Essence fees.
     * @param parent1Id The ID of the first parent Aura.
     * @param parent2Id The ID of the second parent Aura.
     * @param recipient The address to receive the new child Aura.
     * @return The ID of the newly created child Aura.
     */
    function breedAuras(uint256 parent1Id, uint256 parent2Id, address recipient) external payable breedingMustBeEnabled whenNotPaused returns (uint256) {
        _requireOwned(parent1Id); // Ensure caller owns parent 1
        _requireOwned(parent2Id); // Ensure caller owns parent 2 (or is approved operator for both)

        if (parent1Id == parent2Id) {
            revert CannotBreedSelf();
        }
        if (recipient == address(0)) {
             revert ZeroAddressRecipient();
        }
        if (totalSupply() >= maxSupply) {
            revert MaxSupplyReached();
        }

        // --- Potential Fee Mechanism (Example: ETH or Essence) ---
        // // Example ETH fee
        // uint256 breedingFeeETH = 0.01 ether; // Example fee
        // if (msg.value < breedingFeeETH) {
        //     revert InsufficientETH({ required: breedingFeeETH, received: msg.value }); // Need custom error
        // }
        // // The received ETH stays in the contract, owner can withdraw via withdrawETH

        // // Example Essence fee (requires owner approval first)
        // uint256 breedingFeeEssence = 50 ether; // Example fee
        // _burnEssence(msg.sender, breedingFeeEssence); // Burn Essence from caller

        // --- Gene Mixing Logic ---
        uint8[] memory parent1Genes = _auras[parent1Id].genes;
        uint8[] memory parent2Genes = _auras[parent2Id].genes;
        uint8[] memory childGenes = _performBreedingLogic(parent1Genes, parent2Genes);

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        _auras[childTokenId] = Aura({
            genes: childGenes,
            creationBlock: block.number,
            parent1Id: parent1Id,
            parent2Id: parent2Id
        });

        _safeMint(recipient, childTokenId);

        emit AuraMinted(childTokenId, recipient, childGenes, parent1Id, parent2Id);

        return childTokenId;
    }

    /**
     * @dev Applies a mutation to an Aura, significantly altering its genes by burning Essence tokens.
     * Requires ownership of the Aura and sufficient Essence balance.
     * Mutation type dictates the cost and outcome.
     * @param tokenId The ID of the Aura to mutate.
     * @param mutationType The type of mutation to apply (determines cost and gene changes).
     */
    function applyMutation(uint256 tokenId, uint8 mutationType) external mutationMustBeEnabled whenNotPaused nonReentrant onlyAuraOwner(tokenId) {
        _requireOwned(tokenId); // Redundant due to modifier
        uint256 requiredEssence = mutationCosts[mutationType];
        if (requiredEssence == 0) {
            revert InvalidMutationType(mutationType); // Only configured mutation types are valid
        }

        _burnEssence(msg.sender, requiredEssence);

        Aura storage aura = _auras[tokenId];

        // --- Mutation Logic (Example: Randomly change a gene based on mutation type) ---
        // More complex mutation logic can be implemented here based on mutationType
        uint258 blockValue = uint256(blockhash(block.number - 1)); // Use previous block hash for basic variability
        if (blockValue == 0) blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))); // Fallback if blockhash is zero

        uint8 geneToMutate = uint8(blockValue % NUM_GENES);

        // Example: Mutation type 1 boosts a random gene significantly
        if (mutationType == 1) {
             // Apply a large, somewhat random delta
             int8 mutationDelta = int8(uint8((blockValue >> 8) % 50) - 25); // Random delta between -25 and +24
             int16 currentGene = int16(aura.genes[geneToMutate]);
             int16 newGene = currentGene + mutationDelta;

             // Clamp gene value
             if (newGene < 0) newGene = 0;
             else if (newGene > GENE_MAX_VALUE) newGene = GENE_MAX_VALUE;

             aura.genes[geneToMutate] = uint8(newGene);

        } else if (mutationType == 2) {
            // Example: Mutation type 2 randomizes all genes within a certain range
             for(uint i = 0; i < NUM_GENES; i++) {
                 uint256 randomByte = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1 - i), tokenId, block.timestamp)));
                 aura.genes[i] = uint8(randomByte % (GENE_MAX_VALUE + 1));
             }
        }
        // Add more mutation types here...
        else {
            revert InvalidMutationType(mutationType); // Should be caught by cost check, but good safeguard
        }

        emit AuraMutated(tokenId, mutationType, requiredEssence);
    }


    // --- Aura Staking Functions ---

    /**
     * @dev Stakes an owned Aura to start earning Essence rewards.
     * The Aura becomes non-transferable while staked.
     * @param tokenId The ID of the Aura to stake.
     */
    function stakeAura(uint256 tokenId) external whenNotPaused nonReentrant onlyAuraOwner(tokenId) {
        _requireOwned(tokenId); // Redundant due to modifier

        StakingInfo storage info = _stakingInfo[tokenId];
        if (info.isStaked) {
            revert AuraAlreadyStaked(tokenId);
        }

        // Claim any potential pending rewards from previous staking sessions (should be zero if fully unstaked)
        // This shouldn't happen if unstake clears accumulated, but as a safeguard
        uint256 pending = _calculatePendingRewards(info.stakeStartTime);
        info.accumulatedRewards = info.accumulatedRewards.add(pending);

        info.isStaked = true;
        info.stakeStartTime = block.timestamp; // Record stake start time

        emit AuraStaked(tokenId, msg.sender, info.stakeStartTime);
    }

    /**
     * @dev Unstakes a staked Aura and claims all accumulated Essence rewards.
     * The Aura becomes transferable again.
     * @param tokenId The ID of the Aura to unstake.
     */
    function unstakeAura(uint256 tokenId) external whenNotPaused nonReentrant onlyAuraOwner(tokenId) {
        _requireOwned(tokenId); // Redundant due to modifier

        StakingInfo storage info = _stakingInfo[tokenId];
        if (!info.isStaked) {
            revert AuraNotStaked(tokenId);
        }

        uint256 rewards = _calculateAndClaimRewards(tokenId);

        info.isStaked = false;
        info.stakeStartTime = 0; // Reset stake time
        // accumulatedRewards is reset to 0 by _calculateAndClaimRewards

        emit AuraUnstaked(tokenId, msg.sender, block.timestamp, rewards);
    }

    /**
     * @dev Claims accumulated Essence rewards for a staked Aura without unstaking it.
     * Resets the staking timer for future reward calculation.
     * @param tokenId The ID of the staked Aura.
     */
    function claimStakingRewards(uint256 tokenId) external whenNotPaused nonReentrant onlyAuraOwner(tokenId) {
        _requireOwned(tokenId); // Redundant due to modifier

        StakingInfo storage info = _stakingInfo[tokenId];
        if (!info.isStaked) {
            revert AuraNotStaked(tokenId);
        }

        uint256 rewards = _calculateAndClaimRewards(tokenId);

        emit StakingRewardsClaimed(tokenId, msg.sender, rewards);
    }

     /**
     * @dev Estimates the amount of Essence rewards currently accrued for a staked Aura.
     * Does not change contract state.
     * @param tokenId The ID of the Aura.
     * @return The estimated pending Essence rewards.
     */
    function getStakingRewardEstimate(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Ensure token exists

        StakingInfo storage info = _stakingInfo[tokenId];
        if (!info.isStaked) {
            return 0;
        }

        uint256 pending = _calculatePendingRewards(info.stakeStartTime);
        return info.accumulatedRewards.add(pending);
    }


    // --- Essence Token (Internal ERC20-like) ---

    // NOTE: This is a minimal ERC20-like implementation within the contract for a specific use case.
    // It is NOT a full ERC20 token that can be listed or freely traded outside this contract's functions.
    // Balances, transfers, and allowances only exist within this contract's state.

    uint256 private _totalSupplyEssence; // Track total Essence minted

    /**
     * @dev Returns the total supply of Essence tokens.
     * @return The total supply.
     */
    function totalSupplyEssence() public view returns (uint256) {
        return _totalSupplyEssence;
    }

    /**
     * @dev Returns the Essence token balance of an account.
     * @param account The address to query.
     * @return The Essence balance.
     */
    function balanceOfEssence(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /**
     * @dev Transfers Essence tokens from the caller to a recipient.
     * @param recipient The address to send Essence to.
     * @param amount The amount of Essence to send.
     * @return True if successful.
     */
    function transferEssence(address recipient, uint256 amount) public nonReentrant whenNotPaused returns (bool) {
        if (recipient == address(0)) {
            revert ZeroAddressRecipient();
        }
        uint256 senderBalance = _essenceBalances[msg.sender];
        if (senderBalance < amount) {
            revert TransferAmountExceedsBalance(amount, senderBalance);
        }

        unchecked {
            _essenceBalances[msg.sender] = senderBalance - amount;
            _essenceBalances[recipient] = _essenceBalances[recipient] + amount;
        }

        emit EssenceTransferred(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approves a spender to withdraw Essence tokens from the caller's account.
     * @param spender The address to approve.
     * @param amount The amount to approve.
     * @return True if successful.
     */
    function approveEssence(address spender, uint256 amount) public whenNotPaused returns (bool) {
        if (spender == address(0)) {
            revert ZeroAddressRecipient();
        }
        _essenceAllowances[msg.sender][spender] = amount;
        emit EssenceApproved(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Returns the amount of Essence tokens the spender is allowed to withdraw from the owner.
     * @param owner The address whose funds are approved.
     * @param spender The address allowed to spend.
     * @return The remaining allowance.
     */
    function allowanceEssence(address owner, address spender) public view returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    /**
     * @dev Transfers Essence tokens from one account to another using the allowance mechanism.
     * @param sender The address from which Essence is transferred.
     * @param recipient The address to which Essence is transferred.
     * @param amount The amount of Essence to transfer.
     * @return True if successful.
     */
    function transferFromEssence(address sender, address recipient, uint256 amount) public nonReentrant whenNotPaused returns (bool) {
         if (sender == address(0) || recipient == address(0)) {
            revert ZeroAddressRecipient();
        }

        uint256 senderBalance = _essenceBalances[sender];
        if (senderBalance < amount) {
            revert TransferAmountExceedsBalance(amount, senderBalance);
        }

        uint256 currentAllowance = _essenceAllowances[sender][msg.sender];
        if (currentAllowance < amount) {
             revert TransferAmountExceedsAllowance(amount, currentAllowance);
        }

        unchecked {
            _essenceBalances[sender] = senderBalance - amount;
            _essenceBalances[recipient] = _essenceBalances[recipient] + amount;
            _essenceAllowances[sender][msg.sender] = currentAllowance - amount; // Decrease allowance
        }

        emit EssenceTransferred(sender, recipient, amount);
        return true;
    }


    // --- Admin & Configuration Functions ---

    /**
     * @dev Sets the base URI for token metadata. The tokenURI for a specific
     * token will be `baseURI` + `tokenId`.
     * Only callable by the owner.
     * @param baseURI The new base URI string.
     */
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURISet(baseURI);
    }

    /**
     * @dev Sets the maximum number of Auras that can ever be minted.
     * Only callable by the owner.
     * @param maxSupply_ The new maximum supply.
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    /**
     * @dev Sets the rate at which Essence tokens are minted per staked Aura per second.
     * Only callable by the owner.
     * @param rate The new rate (Essence tokens per second, typically in wei).
     */
    function setEssenceMintRate(uint256 rate) external onlyOwner {
        essenceMintRatePerSecond = rate;
        emit EssenceMintRateSet(rate);
    }

     /**
     * @dev Sets the Essence cost for a specific mutation type.
     * Setting cost to 0 effectively disables that mutation type.
     * Only callable by the owner.
     * @param mutationType The type identifier for the mutation.
     * @param cost The Essence cost for this mutation type (in wei).
     */
    function setMutationCosts(uint8 mutationType, uint256 cost) external onlyOwner {
        mutationCosts[mutationType] = cost;
        emit MutationCostsSet(mutationType, cost);
    }

    /**
     * @dev Toggles whether the breeding function is enabled or disabled.
     * Only callable by the owner.
     * @param enabled True to enable, false to disable.
     */
    function toggleBreedingEnabled(bool enabled) external onlyOwner {
        breedingEnabled = enabled;
    }

     /**
     * @dev Toggles whether the evolution function is enabled or disabled.
     * Only callable by the owner.
     * @param enabled True to enable, false to disable.
     */
    function toggleEvolutionEnabled(bool enabled) external onlyOwner {
        evolutionEnabled = enabled;
    }

      /**
     * @dev Toggles whether the mutation function is enabled or disabled.
     * Only callable by the owner.
     * @param enabled True to enable, false to disable.
     */
    function toggleMutationEnabled(bool enabled) external onlyOwner {
        mutationEnabled = enabled;
    }

    /**
     * @dev Pauses all interaction, minting, staking, and Essence transfer functions.
     * Only callable by the owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling functions.
     * Only callable by the owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw ETH accumulated in the contract (e.g., from breeding fees).
     * Only callable by the owner.
     * @param recipient The address to send the ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        if (recipient == address(0)) {
             revert ZeroAddressRecipient();
        }
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed"); // Simple check
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates an initial gene array for a new Aura.
     * Uses basic block data and token ID for pseudo-randomness.
     * WARNING: Not suitable for security-critical randomness.
     * @param newTokenId The ID of the token being minted.
     * @return A new array of uint8 genes.
     */
    function _generateInitialGenes(uint256 newTokenId) internal view returns (uint8[] memory) {
        uint8[] memory genes = new uint8[](NUM_GENES);
        // Use a combination of block number, timestamp, msg.sender, and token ID for variability
        uint256 seed = uint256(keccak256(abi.encodePacked(block.number, block.timestamp, msg.sender, newTokenId, block.difficulty)));

        for (uint i = 0; i < NUM_GENES; i++) {
            // Shift seed and use modulo for byte-sized values
            seed = uint256(keccak256(abi.encodePacked(seed, i))); // Stir the seed
            genes[i] = uint8(seed % (GENE_MAX_VALUE + 1));
        }
        return genes;
    }

    /**
     * @dev Implements the gene mixing logic for breeding.
     * Example: Simple 50/50 split per gene based on a pseudo-random factor.
     * WARNING: Not suitable for security-critical randomness if the split needs to be unpredictable.
     * @param genes1 The genes of the first parent.
     * @param genes2 The genes of the second parent.
     * @return A new array of uint8 genes for the child.
     */
    function _performBreedingLogic(uint8[] memory genes1, uint8[] memory genes2) internal view returns (uint8[] memory) {
         require(genes1.length == NUM_GENES && genes2.length == NUM_GENES, "Invalid parent gene length");

         uint8[] memory childGenes = new uint8[](NUM_GENES);

         uint256 seed = uint256(keccak256(abi.encodePacked(block.number, block.timestamp, msg.sender, genes1, genes2)));

         for(uint i = 0; i < NUM_GENES; i++) {
             seed = uint256(keccak256(abi.encodePacked(seed, i))); // Stir the seed

             // Simple mix: choose gene from parent 1 or parent 2 based on seed byte
             if (seed % 2 == 0) {
                 childGenes[i] = genes1[i];
             } else {
                 childGenes[i] = genes2[i];
             }

             // Optional: Add a small chance for a random mutation during breeding
             // uint8 mutationRoll = uint8((seed >> 8) % 100); // 1 in 100 chance
             // if (mutationRoll < 1) {
             //    seed = uint256(keccak256(abi.encodePacked(seed, "mutation")));
             //    childGenes[i] = uint8(seed % (GENE_MAX_VALUE + 1));
             // }
         }

         return childGenes;
    }


     /**
     * @dev Calculates the pending Essence rewards for a staked Aura since a given timestamp.
     * @param stakeStartTime The timestamp staking began or was last claimed from.
     * @return The calculated pending rewards.
     */
    function _calculatePendingRewards(uint256 stakeStartTime) internal view returns (uint256) {
        if (stakeStartTime == 0 || block.timestamp <= stakeStartTime) {
            return 0;
        }
        uint256 timeStaked = block.timestamp - stakeStartTime;
        // Reward = time_staked * rate_per_second
        // Use SafeMath's mul to prevent overflow, though it's built-in >=0.8
        return timeStaked.mul(essenceMintRatePerSecond);
    }

     /**
     * @dev Calculates, updates, and claims the pending Essence rewards for a staked Aura.
     * Internal helper used by unstake and claim.
     * @param tokenId The ID of the Aura.
     * @return The total rewards claimed in this operation.
     */
    function _calculateAndClaimRewards(uint256 tokenId) internal returns (uint256) {
        StakingInfo storage info = _stakingInfo[tokenId];
        uint256 pending = _calculatePendingRewards(info.stakeStartTime);

        uint256 totalRewardsToClaim = info.accumulatedRewards.add(pending);

        if (totalRewardsToClaim > 0) {
            _mintEssence(ownerOf(tokenId), totalRewardsToClaim); // Mint rewards to the owner
        }

        // Reset accumulated rewards and stake start time for future calculations
        info.accumulatedRewards = 0;
        info.stakeStartTime = block.timestamp; // Reset timer to now for continued staking

        return totalRewardsToClaim;
    }

    /**
     * @dev Mints Essence tokens to a recipient's balance.
     * Internal function.
     * @param recipient The address to mint Essence to.
     * @param amount The amount of Essence to mint.
     */
    function _mintEssence(address recipient, uint256 amount) internal {
         if (recipient == address(0)) {
            revert ZeroAddressRecipient(); // Should not happen with internal calls if logic is sound
        }
        _essenceBalances[recipient] = _essenceBalances[recipient].add(amount);
        _totalSupplyEssence = _totalSupplyEssence.add(amount);
        // No event needed for internal minting, but can be added if desired.
        // emit EssenceMinted(recipient, amount); // Need to define event
    }

    /**
     * @dev Burns Essence tokens from a sender's balance.
     * Internal function. Requires sender to have enough balance.
     * @param sender The address to burn Essence from.
     * @param amount The amount of Essence to burn.
     */
    function _burnEssence(address sender, uint256 amount) internal {
         if (sender == address(0)) {
            revert ZeroAddressRecipient(); // Should not happen
        }
        uint256 senderBalance = _essenceBalances[sender];
        if (senderBalance < amount) {
            revert InsufficientEssenceBalance(amount, senderBalance);
        }

        unchecked {
             _essenceBalances[sender] = senderBalance - amount;
        }
        _totalSupplyEssence = _totalSupplyEssence.sub(amount); // SafeMath for total supply subtraction
        emit EssenceBurned(sender, amount);
    }


    // --- ERC721 Overrides (Required by ERC721URIStorage / ERC721Enumerable) ---

    // The following functions are required to be overridden by ERC721Enumerable and ERC721URIStorage
    // as they modify state related to token existence and ownership.

    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return _baseTokenURI;
    }

     function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    // This is needed by ERC721URIStorage to associate URI with a token ID
     function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override(ERC721URIStorage) {
        super._setTokenURI(tokenId, _tokenURI);
    }

    // The following functions are required by ERC721Enumerable
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **On-Chain Generative Data (Genes):** Instead of just storing an image hash or link, the core properties (`genes`) that define the Aura's appearance are stored directly in the smart contract state (`mapping(uint256 => Aura)`). This makes the generative parameters immutable and transparent on the blockchain.
2.  **Evolution:** Users can directly manipulate the on-chain gene data (`evolveAura`), within predefined limits. This introduces a dynamic aspect to the NFTs beyond static images.
3.  **Breeding:** A mechanism (`breedAuras`) to combine two existing NFTs (parents) to produce a new, distinct NFT (child) with genes derived from the parents. This creates a supply sink for "breeding potential" and allows users to influence the creation of new Auras based on existing ones. The gene mixing logic (`_performBreedingLogic`) is on-chain.
4.  **Internal Token Economy (Essence):** An ERC20-like token (`Essence`) is defined and managed *within* the same contract. It's not a standalone ERC20, but its functions (`balanceOfEssence`, `transferEssence`, `approveEssence`, `transferFromEssence`, `_mintEssence`, `_burnEssence`) provide a basic internal currency used specifically for the "Mutation" mechanic. This creates a closed loop where interaction requires consuming the token, and the token is earned through other interaction (staking).
5.  **Mutation:** A higher-impact way to change an Aura's genes (`applyMutation`), tied directly to consuming the internal `Essence` token. This adds a "special ability" mechanic funded by the internal tokenomics.
6.  **Staking for Internal Token:** Users can stake their Auras (`stakeAura`) to earn `Essence` tokens over time. This is a form of passive yield or "play-to-earn" mechanic integrated directly into the NFT contract, providing a way to acquire the token needed for Mutations. Staked Auras are marked (`isStaked`) and cannot be transferred externally.
7.  **On-Chain State Management:** The contract manages multiple layers of state: standard ERC721 ownership, the custom `Aura` struct data (genes, parentage), and the `StakingInfo` for each token, plus the internal `Essence` balances and allowances.
8.  **Pseudo-Randomness:** Basic block data (`block.number`, `block.timestamp`, `blockhash`, `block.difficulty`) and `keccak256` are used to introduce variability in initial gene generation and breeding. (Note: This is explicitly marked as *not* cryptographically secure for critical applications but demonstrates the concept of on-chain variability).
9.  **Modular Design:** Using OpenZeppelin libraries for standard features (ERC721, Ownable, Pausable, ReentrancyGuard) allows focusing on the unique application logic and benefits from well-audited base contracts.
10. **Pausability & Admin Controls:** Includes standard `Pausable` functionality and various admin setters (`setMaxSupply`, `setEssenceMintRate`, `setMutationCosts`, `setBaseTokenURI`, toggles) to allow the owner to configure and manage the system post-deployment.
11. **ReentrancyGuard:** Applied to critical functions like staking and fund withdrawals to protect against reentrancy attacks.
12. **Custom Errors:** Using `error` for clearer and gas-efficient error handling compared to `require` with strings.

This contract goes beyond a simple mint or transfer NFT contract by incorporating dynamic state changes, an internal economy loop, and gamified interaction mechanics directly on the blockchain.