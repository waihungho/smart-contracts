Okay, let's design a smart contract system focused on a "Decentralized Autonomous Ecosystem" – an on-chain simulation where digital entities ("Glyphs") evolve, interact, and are governed by token holders.

This system will involve:
1.  **Glyphs (ERC721):** Unique digital entities with on-chain "gene" data.
2.  **Energy (ERC20):** A utility token required for actions within the ecosystem (breeding, mutating, evolving).
3.  **Evolution Mechanics:** Glyphs can breed, mutate, and evolve based on rules and spending Energy.
4.  **Environmental Factors:** Simple on-chain global parameters that influence Glyph traits or outcomes.
5.  **Governance:** Holders of the Energy token (or specific governance tokens/roles) can propose and vote on changes to ecosystem parameters.
6.  **Achievements:** On-chain badges or rewards for participating in the ecosystem.
7.  **Marketplace:** Basic functionality to trade Glyphs.

This combines dynamic NFTs, an internal economy, on-chain data manipulation, basic simulation elements, and governance. While using standard ERC and AccessControl patterns from OpenZeppelin (which are open source building blocks), the *specific gene logic, evolution rules, environmental interaction, achievement system, and governance parameters* create a unique combination.

---

## GeneForge Protocol: Autonomous Ecosystem Contract (GlyphCore)

### Outline

1.  **Licenses and Pragma**
2.  **Imports:** ERC721, ERC20 (interaction), AccessControl, Pausable, ReentrancyGuard, Math (for gene logic).
3.  **Errors:** Custom error definitions for clarity.
4.  **Events:** Key actions logged for transparency.
5.  **Structs:** `GeneData`, `EnvironmentalFactors`, `Proposal`.
6.  **Roles:** Define `MINTER_ROLE`, `GOVERNOR_ROLE`, `DEFAULT_ADMIN_ROLE`.
7.  **State Variables:**
    *   ERC721 details (`_name`, `_symbol`, `_tokenIdCounter`).
    *   Mapping `_genes`: `tokenId => GeneData`.
    *   Address of the `GeneEssence` (ERC20) contract.
    *   Ecosystem parameters: `breedingCost`, `mutationCost`, `evolutionCost`, `cooldownDuration`, `mutationChance`, `evolutionSuccessRate`.
    *   Environmental factors: `currentEnvironmentalFactors`.
    *   Cooldowns: `lastActionTime[tokenId]`.
    *   Marketplace listings: `listings[tokenId] => price`.
    *   Achievements: `achievements[achievementId] => AchievementData`, `userAchievements[account][achievementId] => bool`.
    *   Governance: `proposals[proposalId]`, `proposalCounter`, `votes[proposalId][account] => bool`.
8.  **Constructor:** Initializes roles and sets initial parameters.
9.  **Modifiers:** `onlyGovernor`, `onlyMinter`, `whenNotPaused`, `nonReentrant`, `canPerformAction`.
10. **ERC721 Implementations/Overrides:** Standard ERC721 functions.
11. **Core Ecosystem Functions:**
    *   `mintGenesisCreature`: Create initial Glyphs.
    *   `breedCreatures`: Combine two Glyphs to create a new one.
    *   `mutateCreature`: Randomly alter a Glyph's genes.
    *   `evolveCreature`: Attempt to improve a specific gene.
    *   `getGeneData`: Retrieve a Glyph's genes.
    *   `getCooldownRemaining`: Check time left before next action.
    *   `updateEnvironmentalFactors`: (Admin/Governor) Change global factors.
    *   `getEnvironmentalFactors`: Retrieve global factors.
    *   `claimEnergyReward` (Placeholder/Concept): Mechanism for distributing Energy (e.g., via external system, or for reaching achievements).
12. **Marketplace Functions:**
    *   `listCreatureForSale`: Put a Glyph up for sale.
    *   `cancelListing`: Remove a listing.
    *   `buyCreature`: Purchase a listed Glyph.
    *   `getListingPrice`: Check the price of a listing.
13. **Achievement Functions:**
    *   `defineAchievement`: (Admin) Define a new achievement.
    *   `checkAndGrantAchievement`: (Internal/Admin) Check conditions and grant if met.
    *   `isAchievementGranted`: Check if a user has an achievement.
    *   `claimAchievementReward`: Claim Energy/other rewards for achievements.
14. **Governance Functions:**
    *   `createParameterChangeProposal`: Propose changing an ecosystem parameter.
    *   `voteOnProposal`: Cast a vote (Yes/No).
    *   `getProposalState`: Check status (Pending, Active, Succeeded, Failed, Executed).
    *   `executeProposal`: Apply changes if proposal succeeded.
    *   `getProposalVoteCounts`: Get vote results.
15. **Admin/Role Management Functions:**
    *   `grantRole`, `revokeRole`, `renounceRole`, `hasRole`, `getRoleAdmin`.
    *   `pause`, `unpause`.
    *   `setGeometryEssenceAddress`: Set the ERC20 address.
    *   `setBaseCosts`: Set breeding, mutation, evolution costs.
    *   `setBaseRates`: Set mutation chance, evolution success rate.
16. **View/Pure Helper Functions:**
    *   `_generateRandomGenes`: Internal pseudo-random gene generation.
    *   `_inheritGenes`: Internal gene blending logic for breeding.
    *   `_calculateGeneMutation`: Internal mutation logic.
    *   `_attemptEvolution`: Internal evolution attempt logic.
    *   `_getCurrentTimestamp`: Get block timestamp.

### Function Summary

Here's a summary of the planned functions (aiming for 20+):

1.  `constructor()`: Initialize contract, roles, and parameters.
2.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: ERC165 interface support.
3.  `balanceOf(address owner) public view override returns (uint256)`: ERC721: Get owner's Glyph count.
4.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721: Get owner of a Glyph.
5.  `approve(address to, uint256 tokenId) public override` : ERC721: Approve address for one Glyph.
6.  `getApproved(uint256 tokenId) public view override returns (address)`: ERC721: Get approved address for one Glyph.
7.  `setApprovalForAll(address operator, bool approved) public override`: ERC721: Approve/disapprove operator for all Glyphs.
8.  `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721: Check if operator is approved for all.
9.  `transferFrom(address from, address to, uint256 tokenId) public override`: ERC721: Transfer Glyph (requires approval).
10. `safeTransferFrom(address from, address to, uint256 tokenId) public override`: ERC721: Safe transfer.
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override`: ERC721: Safe transfer with data.
12. `getEssenceBalance(address account) public view returns (uint256)`: Query user's GeneEssence balance.
13. `mintGenesisCreature(address recipient) public onlyMinter whenNotPaused nonReentrant`: Mint a new Glyph.
14. `breedCreatures(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant`: Breed two Glyphs.
15. `mutateCreature(uint256 tokenId) public whenNotPaused nonReentrant`: Mutate a Glyph.
16. `evolveCreature(uint256 tokenId, uint8 geneIndex) public whenNotPaused nonReentrant`: Attempt to evolve a specific gene.
17. `getGeneData(uint256 tokenId) public view returns (GeneData memory)`: Get gene data for a Glyph.
18. `getCooldownRemaining(uint256 tokenId) public view returns (uint256)`: Check action cooldown remaining.
19. `updateEnvironmentalFactors(EnvironmentalFactors memory newFactors) public onlyGovernor whenNotPaused nonReentrant`: Update global environment.
20. `getEnvironmentalFactors() public view returns (EnvironmentalFactors memory)`: Get global environment.
21. `claimEnergyReward(uint256 achievementId) public whenNotPaused nonReentrant`: Claim reward for achievement.
22. `listCreatureForSale(uint256 tokenId, uint256 price) public whenNotPaused nonReentrant`: List a Glyph for sale.
23. `cancelListing(uint256 tokenId) public whenNotPaused nonReentrant`: Cancel Glyph listing.
24. `buyCreature(uint256 tokenId) public whenNotPaused nonReentrant`: Buy a listed Glyph.
25. `getListingPrice(uint256 tokenId) public view returns (uint256)`: Get Glyph listing price.
26. `defineAchievement(uint256 achievementId, uint256 requiredValue, uint256 rewardAmount) public onlyGovernor whenNotPaused nonReentrant`: Define a new achievement rule.
27. `isAchievementGranted(address account, uint256 achievementId) public view returns (bool)`: Check if achievement is granted.
28. `createParameterChangeProposal(string memory description, string memory parameterName, uint256 newValue) public onlyGovernor whenNotPaused nonReentrant`: Create governance proposal.
29. `voteOnProposal(uint256 proposalId, bool support) public whenNotPaused nonReentrant`: Vote on a proposal.
30. `getProposalState(uint256 proposalId) public view returns (ProposalState)`: Get proposal state.
31. `executeProposal(uint256 proposalId) public onlyGovernor whenNotPaused nonReentrant`: Execute successful proposal.
32. `getProposalVoteCounts(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes)`: Get vote counts.
33. `grantRole(bytes32 role, address account) public virtual override`: Grant role.
34. `revokeRole(bytes32 role, address account) public virtual override`: Revoke role.
35. `renounceRole(bytes32 role) public virtual override`: Renounce role.
36. `hasRole(bytes32 role, address account) public view virtual override returns (bool)`: Check role.
37. `getRoleAdmin(bytes32 role) public view virtual override returns (bytes32)`: Get role admin.
38. `pause() public onlyDefaultAdmin whenNotPaused`: Pause contract.
39. `unpause() public onlyDefaultAdmin whenPaused`: Unpause contract.
40. `setGeometryEssenceAddress(address _essenceAddress) public onlyDefaultAdmin`: Set Energy token address.
41. `setBaseCosts(uint256 _breedingCost, uint256 _mutationCost, uint256 _evolutionCost) public onlyGovernor whenNotPaused nonReentrant`: Set action costs.
42. `setBaseRates(uint256 _mutationChance, uint256 _evolutionSuccessRate) public onlyGovernor whenNotPaused nonReentrant`: Set action rates.

*Note: Functions inherited from OpenZeppelin contracts like `_mint`, `_burn`, `_beforeTokenTransfer`, `_approve` etc., exist but are typically internal helpers and not exposed public/external functions callable by users, so they aren't counted in the 40+ list above, but are part of the contract's implementation.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title GeneForge Protocol: Autonomous Ecosystem Contract (GlyphCore)
/// @author [Your Name/Pseudonym]
/// @notice This contract manages a decentralized autonomous ecosystem of digital entities called Glyphs.
/// Glyphs are ERC721 tokens with on-chain "gene" data. Users can breed, mutate, and evolve Glyphs
/// using an ERC20 "GeneEssence" token. The ecosystem's rules are influenced by environmental factors
/// and governed by token holder proposals. Achievements provide gamification. A basic marketplace allows trading.

// --- Outline ---
// 1. Licenses and Pragma
// 2. Imports
// 3. Errors
// 4. Events
// 5. Enums and Structs
// 6. Roles
// 7. State Variables
// 8. Constructor
// 9. Modifiers
// 10. ERC721 Implementations/Overrides
// 11. Core Ecosystem Functions (Minting, Breeding, Mutating, Evolving, Environment)
// 12. Marketplace Functions
// 13. Achievement Functions
// 14. Governance Functions
// 15. Admin/Role Management Functions
// 16. View/Pure Helper Functions (Internal logic like gene generation, inheritance, randomness - pseudo in this example)

// --- Function Summary ---
// (See Summary listed above the contract code)

contract GlyphCore is ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error GlyphCore__TokenIdDoesNotExist(uint256 tokenId);
    error GlyphCore__InvalidGeneIndex();
    error GlyphCore__InsufficientEssence(uint256 required, uint256 has);
    error GlyphCore__CooldownNotElapsed(uint256 remaining);
    error GlyphCore__Unauthorized();
    error GlyphCore__AlreadyListed(uint256 tokenId);
    error GlyphCore__NotListed(uint256 tokenId);
    error GlyphCore__ListingPriceZero();
    error GlyphCore__SelfTransferForbidden();
    error GlyphCore__AlreadyVoted();
    error GlyphCore__ProposalNotFound(uint256 proposalId);
    error GlyphCore__ProposalNotInState(ProposalState currentState, ProposalState requiredState);
    error GlyphCore__ProposalExecuteFailed();
    error GlyphCore__AchievementNotFound(uint256 achievementId);
    error GlyphCore__AchievementNotGranted();
    error GlyphCore__AchievementAlreadyClaimed();
    error GlyphCore__CannotBreedWithSelf();
    error GlyphCore__BothTokensRequiredForBreeding();
    error GlyphCore__OnlyTokenOwnerCanInteract(uint256 tokenId);
    error GlyphCore__MarketplacePriceMismatch(uint256 sentAmount, uint256 requiredPrice);

    // --- Events ---
    event GlyphMinted(uint256 indexed tokenId, address indexed owner, GeneData genes);
    event GlyphBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, GeneData childGenes);
    event GlyphMutated(uint256 indexed tokenId, GeneData newGenes);
    event GlyphEvolved(uint256 indexed tokenId, uint8 indexed geneIndex, GeneData newGenes);
    event EnvironmentalFactorsUpdated(EnvironmentalFactors newFactors);
    event CreatureListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event CreatureSaleCancelled(uint256 indexed tokenId);
    event CreatureSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event AchievementDefined(uint256 indexed achievementId, uint256 requiredValue, uint256 rewardAmount);
    event AchievementGranted(address indexed account, uint256 indexed achievementId);
    event AchievementClaimed(address indexed account, uint256 indexed achievementId, uint256 rewardAmount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EssenceAddressUpdated(address indexed newAddress);
    event BaseCostsUpdated(uint256 breedingCost, uint256 mutationCost, uint256 evolutionCost);
    event BaseRatesUpdated(uint256 mutationChance, uint256 evolutionSuccessRate);

    // --- Enums and Structs ---

    /// @dev Represents the genetic data of a Glyph. Max 256 genes (uint8 index).
    struct GeneData {
        uint16[] values; // Example genes: speed, strength, color_param, resistance, etc.
        uint256 createdTimestamp;
    }

    /// @dev Represents global environmental factors influencing the ecosystem.
    struct EnvironmentalFactors {
        uint256 temperature; // Example factor
        uint256 radiationLevel; // Example factor
        // Add more factors as needed
    }

    /// @dev States for a governance proposal.
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    /// @dev Represents a governance proposal to change a single parameter.
    struct Proposal {
        uint256 id;
        address creator;
        string description;
        string parameterName; // Name of the parameter to change (e.g., "breedingCost")
        uint256 newValue;      // The proposed new value
        uint256 creationBlock; // Block when active period starts
        uint256 votingPeriodBlocks; // How long voting is active
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        bool executed;
    }

    /// @dev Represents an achievement definition.
    struct AchievementData {
        uint256 requiredValue; // E.g., number of breeds, mutations
        uint256 rewardAmount;  // Essence reward
        bool isDefined;        // To check if the ID is valid
    }

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- State Variables ---
    IERC20 public geneEssence;

    mapping(uint256 => GeneData) private _genes;
    mapping(uint256 => uint256) private _lastActionTime; // Cooldown tracker

    // Ecosystem Parameters (can be changed via governance)
    uint256 public breedingCost; // In GeneEssence tokens
    uint256 public mutationCost; // In GeneEssence tokens
    uint256 public evolutionCost; // In GeneEssence tokens
    uint256 public cooldownDuration; // In seconds

    uint256 public mutationChance; // Percentage (0-10000 for 0-100%)
    uint256 public evolutionSuccessRate; // Percentage (0-10000 for 0-100%)

    EnvironmentalFactors public currentEnvironmentalFactors;

    // Marketplace
    mapping(uint256 => uint256) public listings; // tokenId => price (in GeneEssence)

    // Achievements
    mapping(uint256 => AchievementData) private _achievements;
    mapping(address => mapping(uint256 => bool)) private _userAchievements; // user => achievementId => granted
    mapping(address => mapping(uint256 => bool)) private _achievementClaimed; // user => achievementId => claimed

    // Governance
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _proposalCounter;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => user => voted

    // Governance parameters
    uint256 public minVotingPeriodBlocks = 100; // Minimum blocks for voting
    uint256 public proposalThresholdEssence = 100e18; // Minimum Essence balance to create proposal (Example)
    uint256 public voteSupportRequired = 5001; // Percentage (0-10000), > 50%

    // Pseudo-randomness seed (WARNING: INSECURE FOR PRODUCTION)
    // A production contract would use Chainlink VRF or similar secure randomness.
    uint256 private _randomSeed;

    // --- Constructor ---
    constructor(
        address defaultAdmin,
        address initialMinter,
        address initialGovernor,
        address essenceTokenAddress
    ) ERC721("GeneForge Glyph", "GLYPH") Pausable(defaultAdmin) nonReentrant(defaultAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, initialMinter);
        _grantRole(GOVERNOR_ROLE, initialGovernor);

        geneEssence = IERC20(essenceTokenAddress);

        // Set initial parameters (can be changed via governance)
        breedingCost = 5e18; // 5 GeneEssence
        mutationCost = 2e18; // 2 GeneEssence
        evolutionCost = 3e18; // 3 GeneEssence
        cooldownDuration = 1 days; // 1 day cooldown

        mutationChance = 1000; // 10% chance
        evolutionSuccessRate = 7500; // 75% success rate

        currentEnvironmentalFactors = EnvironmentalFactors(100, 50); // Initial environment

        _randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    // --- Modifiers ---
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    modifier onlyGovernor() {
        _checkRole(GOVERNOR_ROLE);
        _;
    }

    /// @dev Requires sufficient time has passed since the last action on the token.
    modifier canPerformAction(uint256 tokenId) {
        if (_lastActionTime[tokenId] > 0 && block.timestamp < _lastActionTime[tokenId] + cooldownDuration) {
            revert GlyphCore__CooldownNotElapsed(_lastActionTime[tokenId] + cooldownDuration - block.timestamp);
        }
        _;
    }

    // --- ERC721 Implementations/Overrides ---

    // The ERC721Enumerable base contract provides implementations for
    // tokenOfOwnerByIndex and tokenByIndex, which requires overriding
    // _beforeTokenTransfer and _afterTokenTransfer hooks.
    // ERC721, AccessControl, Pausable, ReentrancyGuard are base classes.

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://YOUR_METADATA_BASE_URI/"; // Replace with your actual base URI
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Enumerable__NonexistentToken();
        }
        string memory base = _baseURI();
        // Append token-specific path, maybe include genes in hash for dynamic data?
        return string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    // Override _beforeTokenTransfer and _afterTokenTransfer for ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Clear marketplace listing if transferred
        if (listings[tokenId] > 0) {
            delete listings[tokenId];
            emit CreatureSaleCancelled(tokenId);
        }

        // Remove cooldown on transfer? Or persist? Decided to persist for gameplay.
        // _lastActionTime[tokenId] = 0; // Option to reset cooldown on transfer
    }

    // --- Core Ecosystem Functions ---

    /// @notice Mints a new genesis Glyph. Only callable by the minter role.
    /// @param recipient The address to receive the new Glyph.
    function mintGenesisCreature(address recipient) public onlyMinter whenNotPaused nonReentrant returns (uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        GeneData memory newGenes = _generateRandomGenes();
        _genes[newTokenId] = newGenes;

        _safeMint(recipient, newTokenId); // Uses internal _safeMint
        _lastActionTime[newTokenId] = block.timestamp; // Set initial cooldown

        emit GlyphMinted(newTokenId, recipient, newGenes);

        // Check for any achievement grants on minting
        // Example: Grant "First Glyph" achievement if defined
        // _checkAndGrantAchievement(recipient, 1); // Placeholder achievement ID

        return newTokenId;
    }

    /// @notice Breeds two Glyphs to create a new one. Requires owning both parents and paying Essence cost.
    /// @param tokenId1 The ID of the first parent Glyph.
    /// @param tokenId2 The ID of the second parent Glyph.
    function breedCreatures(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant {
        if (tokenId1 == tokenId2) revert GlyphCore__CannotBreedWithSelf();
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert GlyphCore__BothTokensRequiredForBreeding();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Require caller owns both tokens OR is approved for all for both
        if (msg.sender != owner1 && !isApprovedForAll(owner1, msg.sender)) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId1);
        if (msg.sender != owner2 && !isApprovedForAll(owner2, msg.sender)) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId2);

        // Apply cooldown to both parents
        if (_lastActionTime[tokenId1] > 0 && block.timestamp < _lastActionTime[tokenId1] + cooldownDuration) {
             revert GlyphCore__CooldownNotElapsed(_lastActionTime[tokenId1] + cooldownDuration - block.timestamp);
        }
         if (_lastActionTime[tokenId2] > 0 && block.timestamp < _lastActionTime[tokenId2] + cooldownDuration) {
             revert GlyphCore__CooldownNotElapsed(_lastActionTime[tokenId2] + cooldownDuration - block.timestamp);
        }

        // Check GeneEssence balance and transfer
        if (geneEssence.balanceOf(msg.sender) < breedingCost) {
            revert GlyphCore__InsufficientEssence(breedingCost, geneEssence.balanceOf(msg.sender));
        }
        // Note: Assumes the caller has approved this contract to spend breedingCost Essence.
        // A separate `approveEssence` function or reliance on user approval is needed beforehand.
        bool success = geneEssence.transferFrom(msg.sender, address(this), breedingCost);
        if (!success) revert GlyphCore__InsufficientEssence(breedingCost, geneEssence.balanceOf(msg.sender)); // Should not happen if balance check passed, but good practice.


        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Generate child genes based on parents and environment
        GeneData memory childGenes = _inheritGenes(_genes[tokenId1], _genes[tokenId2], currentEnvironmentalFactors);
         _genes[newTokenId] = childGenes;

        _safeMint(msg.sender, newTokenId); // Mint to the caller (owner of parents)

        // Update cooldowns for parents
        _lastActionTime[tokenId1] = block.timestamp;
        _lastActionTime[tokenId2] = block.timestamp;
        _lastActionTime[newTokenId] = block.timestamp; // New creature also gets cooldown

        emit GlyphBred(tokenId1, tokenId2, newTokenId, childGenes);

        // Check for breeding achievements
        // _checkAndGrantAchievement(msg.sender, 2); // Placeholder achievement ID for breeding

    }

    /// @notice Attempts to mutate a Glyph's genes. Requires owning the Glyph and paying Essence cost.
    /// @param tokenId The ID of the Glyph to mutate.
    function mutateCreature(uint256 tokenId) public whenNotPaused nonReentrant canPerformAction(tokenId) {
        if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId);
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId);

        if (geneEssence.balanceOf(msg.sender) < mutationCost) {
            revert GlyphCore__InsufficientEssence(mutationCost, geneEssence.balanceOf(msg.sender));
        }
         bool success = geneEssence.transferFrom(msg.sender, address(this), mutationCost);
        if (!success) revert GlyphCore__InsufficientEssence(mutationCost, geneEssence.balanceOf(msg.sender));


        // Generate a new pseudo-random number
        uint256 randomNumber = _generatePseudoRandom(block.number, tx.origin, tokenId, block.timestamp);

        // Check if mutation occurs based on mutationChance and environment
        // Example: Environment might influence mutation chance
        uint256 effectiveMutationChance = mutationChance; // Simplified: environment doesn't affect chance yet
        if (randomNumber % 10001 < effectiveMutationChance) { // 0-10000 range

            GeneData memory currentGenes = _genes[tokenId];
            _genes[tokenId] = _calculateGeneMutation(currentGenes, currentEnvironmentalFactors, randomNumber);

            _lastActionTime[tokenId] = block.timestamp; // Update cooldown
            emit GlyphMutated(tokenId, _genes[tokenId]);

            // Check for mutation achievements
            // _checkAndGrantAchievement(msg.sender, 3); // Placeholder achievement ID for mutation
        } else {
             // Mutation failed, still update cooldown and potentially emit event
             _lastActionTime[tokenId] = block.timestamp; // Update cooldown
             // Optional: Emit a "MutationAttemptFailed" event
        }
    }

    /// @notice Attempts to evolve a specific gene of a Glyph. Requires owning the Glyph and paying Essence cost.
    /// Evolution might require specific environmental conditions or achievement status in a more complex version.
    /// @param tokenId The ID of the Glyph to evolve.
    /// @param geneIndex The index of the gene to attempt to evolve.
    function evolveCreature(uint256 tokenId, uint8 geneIndex) public whenNotPaused nonReentrant canPerformAction(tokenId) {
        if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId);
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId);

        if (geneIndex >= _genes[tokenId].values.length) revert GlyphCore__InvalidGeneIndex();

        if (geneEssence.balanceOf(msg.sender) < evolutionCost) {
            revert GlyphCore__InsufficientEssence(evolutionCost, geneEssence.balanceOf(msg.sender));
        }
         bool success = geneEssence.transferFrom(msg.sender, address(this), evolutionCost);
        if (!success) revert GlyphCore__InsufficientEssence(evolutionCost, geneEssence.balanceOf(msg.sender));


        // Generate a new pseudo-random number
        uint256 randomNumber = _generatePseudoRandom(block.number, tx.origin, tokenId, geneIndex);

        // Check if evolution is successful based on evolutionSuccessRate and environment
        // Example: Environment might boost success rate for certain genes
        uint256 effectiveSuccessRate = evolutionSuccessRate; // Simplified: environment doesn't affect rate yet
        if (randomNumber % 10001 < effectiveSuccessRate) { // 0-10000 range

            GeneData memory currentGenes = _genes[tokenId];
             _genes[tokenId] = _attemptEvolution(currentGenes, geneIndex, currentEnvironmentalFactors, randomNumber); // Apply evolution

            _lastActionTime[tokenId] = block.timestamp; // Update cooldown
            emit GlyphEvolved(tokenId, geneIndex, _genes[tokenId]);

            // Check for evolution achievements
            // _checkAndGrantAchievement(msg.sender, 4); // Placeholder achievement ID for evolution
        } else {
            // Evolution failed, still update cooldown and potentially emit event
             _lastActionTime[tokenId] = block.timestamp; // Update cooldown
             // Optional: Emit an "EvolutionAttemptFailed" event
        }
    }

    /// @notice Gets the gene data for a specific Glyph.
    /// @param tokenId The ID of the Glyph.
    /// @return GeneData struct containing the Glyph's genes.
    function getGeneData(uint256 tokenId) public view returns (GeneData memory) {
        if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId);
        return _genes[tokenId];
    }

    /// @notice Gets the remaining cooldown time for a Glyph in seconds.
    /// @param tokenId The ID of the Glyph.
    /// @return The number of seconds remaining until the cooldown is over. Returns 0 if no cooldown active.
    function getCooldownRemaining(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0; // Or revert? Let's allow checking for non-existent.
        uint256 lastAction = _lastActionTime[tokenId];
        if (lastAction == 0 || block.timestamp >= lastAction + cooldownDuration) {
            return 0;
        } else {
            return lastAction + cooldownDuration - block.timestamp;
        }
    }

    /// @notice Updates the global environmental factors. Only callable by the governor role.
    /// @param newFactors The new EnvironmentalFactors struct.
    function updateEnvironmentalFactors(EnvironmentalFactors memory newFactors) public onlyGovernor whenNotPaused nonReentrant {
        currentEnvironmentalFactors = newFactors;
        emit EnvironmentalFactorsUpdated(newFactors);
    }

    /// @notice Gets the current global environmental factors.
    /// @return The current EnvironmentalFactors struct.
    function getEnvironmentalFactors() public view returns (EnvironmentalFactors memory) {
        return currentEnvironmentalFactors;
    }

    /// @notice Allows claiming Essence reward for a completed achievement.
    /// @param achievementId The ID of the achievement to claim.
    function claimEnergyReward(uint256 achievementId) public whenNotPaused nonReentrant {
        if (!_achievements[achievementId].isDefined) revert GlyphCore__AchievementNotFound(achievementId);
        if (!_userAchievements[msg.sender][achievementId]) revert GlyphCore__AchievementNotGranted();
        if (_achievementClaimed[msg.sender][achievementId]) revert GlyphCore__AchievementAlreadyClaimed();

        uint256 rewardAmount = _achievements[achievementId].rewardAmount;
        if (rewardAmount > 0) {
            // Transfer reward from contract balance (assumes contract holds Essence for rewards)
            // In a real system, contract might need a dedicated fund or minting rights for rewards.
            // Here, we assume contract has a balance from costs paid.
            bool success = geneEssence.transfer(msg.sender, rewardAmount);
            require(success, "GlyphCore: Essence transfer failed"); // Should not fail if balance exists
        }

        _achievementClaimed[msg.sender][achievementId] = true;
        emit AchievementClaimed(msg.sender, achievementId, rewardAmount);
    }


    // --- Marketplace Functions ---

    /// @notice Lists a Glyph for sale on the internal marketplace. Requires owning the Glyph.
    /// Price is in GeneEssence.
    /// @param tokenId The ID of the Glyph to list.
    /// @param price The price in GeneEssence tokens.
    function listCreatureForSale(uint256 tokenId, uint256 price) public whenNotPaused nonReentrant {
        if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId); // Must own to list
        if (listings[tokenId] > 0) revert GlyphCore__AlreadyListed(tokenId);
        if (price == 0) revert GlyphCore__ListingPriceZero();

        listings[tokenId] = price;
        emit CreatureListed(tokenId, msg.sender, price);
    }

    /// @notice Cancels a Glyph listing. Requires owning the Glyph or being the seller.
    /// @param tokenId The ID of the listed Glyph.
    function cancelListing(uint256 tokenId) public whenNotPaused nonReentrant {
         if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId); // Check if token exists
        if (listings[tokenId] == 0) revert GlyphCore__NotListed(tokenId);

        address currentOwner = ownerOf(tokenId);
        // Allow either the current owner OR the original seller to cancel (though listing maps tokenId to price, not seller)
        // A more robust marketplace would store the seller's address in the listing struct.
        // For this example, we require current owner or approved.
         if (currentOwner != msg.sender && !isApprovedForAll(currentOwner, msg.sender)) revert GlyphCore__OnlyTokenOwnerCanInteract(tokenId);


        delete listings[tokenId];
        emit CreatureSaleCancelled(tokenId);
    }

    /// @notice Buys a listed Glyph. Pays price in GeneEssence.
    /// @param tokenId The ID of the Glyph to buy.
    function buyCreature(uint256 tokenId) public payable whenNotPaused nonReentrant {
        if (!_exists(tokenId)) revert GlyphCore__TokenIdDoesNotExist(tokenId);
        if (listings[tokenId] == 0) revert GlyphCore__NotListed(tokenId);
        if (ownerOf(tokenId) == msg.sender) revert GlyphCore__SelfTransferForbidden();

        uint256 price = listings[tokenId];
        address seller = ownerOf(tokenId); // Seller is the current owner at time of purchase

        // Check and transfer Essence
        // Assumes msg.sender has pre-approved this contract to spend the required Essence.
        if (geneEssence.balanceOf(msg.sender) < price) {
             revert GlyphCore__InsufficientEssence(price, geneEssence.balanceOf(msg.sender));
        }
        bool success = geneEssence.transferFrom(msg.sender, seller, price);
        if (!success) revert GlyphCore__MarketplacePriceMismatch(geneEssence.balanceOf(msg.sender), price); // More specific error needed if transfer fails for other reasons

        // Transfer the Glyph
        _safeTransfer(seller, msg.sender, tokenId); // Uses internal _safeTransfer

        // Clean up listing (done in _beforeTokenTransfer hook)
        // delete listings[tokenId]; // Not needed due to hook

        emit CreatureSold(tokenId, msg.sender, seller, price);
    }

    /// @notice Gets the listing price for a Glyph.
    /// @param tokenId The ID of the Glyph.
    /// @return The price in GeneEssence, or 0 if not listed.
    function getListingPrice(uint256 tokenId) public view returns (uint256) {
        return listings[tokenId];
    }

    // --- Achievement Functions ---

    /// @notice Defines a new achievement. Only callable by the governor role.
    /// Achievement logic itself (how requiredValue is met) is implemented implicitly
    /// in other functions (e.g., mintGenesis, breedCreatures checking conditions).
    /// @param achievementId A unique ID for the achievement.
    /// @param requiredValue A value representing the condition to meet (e.g., number of actions). Interpretation depends on achievement logic.
    /// @param rewardAmount The amount of GeneEssence rewarded for claiming.
    function defineAchievement(uint256 achievementId, uint256 requiredValue, uint256 rewardAmount) public onlyGovernor whenNotPaused nonReentrant {
         _achievements[achievementId] = AchievementData(requiredValue, rewardAmount, true);
         emit AchievementDefined(achievementId, requiredValue, rewardAmount);
    }

    /// @notice Internal helper to check and grant an achievement to a user.
    /// This would be called from relevant functions like `breedCreatures`, `mutateCreature`, etc.
    /// It's a simplified example; real achievements might require complex checks.
    /// @param account The address to check/grant for.
    /// @param achievementId The ID of the achievement to check.
    function _checkAndGrantAchievement(address account, uint256 achievementId) internal {
        // Example placeholder logic:
        // if (!_achievements[achievementId].isDefined) return;
        // if (_userAchievements[account][achievementId]) return; // Already granted

        // // Replace with actual logic based on achievementId and user's state
        // bool conditionsMet = false;
        // if (achievementId == 1) { // Example: First Glyph Minted (Checked in mint function)
        //     conditionsMet = true; // Assuming this is only called once per user in mint
        // } else if (achievementId == 2) { // Example: First Breed
        //     // Check user's breed count vs requiredValue? Need to track user breed counts.
        //     // This example is simplified and doesn't track counts globally per user.
        //     // A real implementation needs user stats: mapping(address => UserStats)
        // }


        // if (conditionsMet) {
        //     _userAchievements[account][achievementId] = true;
        //     emit AchievementGranted(account, achievementId);
        // }
         // --- End Example Placeholder ---
         // A robust system needs dedicated storage and logic to track achievement progress per user.
    }

    /// @notice Checks if a user has been granted a specific achievement.
    /// @param account The user's address.
    /// @param achievementId The ID of the achievement.
    /// @return True if the achievement has been granted, false otherwise.
    function isAchievementGranted(address account, uint256 achievementId) public view returns (bool) {
        return _userAchievements[account][achievementId];
    }

    /// @notice Checks if a user has claimed the reward for a specific achievement.
    /// @param account The user's address.
    /// @param achievementId The ID of the achievement.
    /// @return True if the reward has been claimed, false otherwise.
     function isAchievementClaimed(address account, uint256 achievementId) public view returns (bool) {
        return _achievementClaimed[account][achievementId];
    }


    // --- Governance Functions ---

    /// @notice Creates a proposal to change a specific ecosystem parameter. Only callable by the governor role.
    /// Requires the creator to hold a minimum balance of GeneEssence (proposalThresholdEssence).
    /// @param description A description of the proposal.
    /// @param parameterName The name of the parameter state variable to change (e.g., "breedingCost", "mutationChance"). Must match exactly.
    /// @param newValue The proposed new value for the parameter.
    function createParameterChangeProposal(string memory description, string memory parameterName, uint256 newValue) public onlyGovernor whenNotPaused nonReentrant {
        // Basic check for minimum essence balance
        if (geneEssence.balanceOf(msg.sender) < proposalThresholdEssence) {
            revert GlyphCore__InsufficientEssence(proposalThresholdEssence, geneEssence.balanceOf(msg.sender));
        }

        uint256 proposalId = _proposalCounter++;
        _proposals[proposalId] = Proposal({
            id: proposalId,
            creator: msg.sender,
            description: description,
            parameterName: parameterName,
            newValue: newValue,
            creationBlock: block.number,
            votingPeriodBlocks: minVotingPeriodBlocks, // Simple fixed voting period
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active, // Proposals are active immediately
            executed: false
        });
        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Votes on an active proposal. Requires not having voted already.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a "Yes" vote, False for a "No" vote.
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId && proposal.creator == address(0)) revert GlyphCore__ProposalNotFound(proposalId);
        if (proposal.state != ProposalState.Active) revert GlyphCore__ProposalNotInState(proposal.state, ProposalState.Active);
        if (_hasVoted[proposalId][msg.sender]) revert GlyphCore__AlreadyVoted();
        if (block.number >= proposal.creationBlock + proposal.votingPeriodBlocks) revert GlyphCore__ProposalNotInState(ProposalState.Active, ProposalState.Pending); // Voting period ended

        _hasVoted[proposalId][msg.sender] = true;
        if (support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit Voted(proposalId, msg.sender, support);

        // Update proposal state if voting period ended (can be done by anyone calling this or getProposalState/executeProposal)
        if (block.number >= proposal.creationBlock + proposal.votingPeriodBlocks) {
             _updateProposalState(proposalId);
         }
    }

    /// @notice Gets the current state of a proposal. Also updates state if voting period is over.
    /// @param proposalId The ID of the proposal.
    /// @return The current state of the proposal.
    function getProposalState(uint256 proposalId) public returns (ProposalState) {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.id != proposalId && proposal.creator == address(0)) revert GlyphCore__ProposalNotFound(proposalId);

        _updateProposalState(proposalId); // Ensure state is current
        return proposal.state;
    }

     /// @notice Internal helper to update the state of a proposal based on block number and votes.
     /// @param proposalId The ID of the proposal.
     function _updateProposalState(uint256 proposalId) internal {
         Proposal storage proposal = _proposals[proposalId];

         if (proposal.state == ProposalState.Active && block.number >= proposal.creationBlock + proposal.votingPeriodBlocks) {
             // Voting period ended, determine outcome
             uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

             // Check if enough votes were cast and if support threshold is met
             // Simplified: Just check support % against total votes cast
             if (totalVotes > 0 && (proposal.yesVotes * 10000 / totalVotes) >= voteSupportRequired) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
         }
     }


    /// @notice Executes a successful proposal. Only callable by the governor role.
    /// Applies the proposed parameter change.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public onlyGovernor whenNotPaused nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId && proposal.creator == address(0)) revert GlyphCore__ProposalNotFound(proposalId);

        _updateProposalState(proposalId); // Ensure state is current

        if (proposal.state != ProposalState.Succeeded) revert GlyphCore__ProposalNotInState(proposal.state, ProposalState.Succeeded);
        if (proposal.executed) revert GlyphCore__ProposalNotInState(ProposalState.Succeeded, ProposalState.Succeeded); // Already executed

        // Apply the parameter change based on parameterName
        // This uses if/else if chain. A more advanced system might use a map or delegatecall (with security risks).
        bytes32 paramHash = keccak256(abi.encodePacked(proposal.parameterName));

        if (paramHash == keccak256(abi.encodePacked("breedingCost"))) {
            breedingCost = proposal.newValue;
            emit BaseCostsUpdated(breedingCost, mutationCost, evolutionCost);
        } else if (paramHash == keccak256(abi.encodePacked("mutationCost"))) {
             mutationCost = proposal.newValue;
             emit BaseCostsUpdated(breedingCost, mutationCost, evolutionCost);
        } else if (paramHash == keccak256(abi.encodePacked("evolutionCost"))) {
             evolutionCost = proposal.newValue;
             emit BaseCostsUpdated(breedingCost, mutationCost, evolutionCost);
        } else if (paramHash == keccak256(abi.encodePacked("cooldownDuration"))) {
             cooldownDuration = proposal.newValue;
             // Consider adding an event for cooldown change
        } else if (paramHash == keccak256(abi.encodePacked("mutationChance"))) {
             if (proposal.newValue > 10000) revert GlyphCore__ProposalExecuteFailed(); // Cap percentage
             mutationChance = proposal.newValue;
             emit BaseRatesUpdated(mutationChance, evolutionSuccessRate);
        } else if (paramHash == keccak256(abi.encodePacked("evolutionSuccessRate"))) {
             if (proposal.newValue > 10000) revert GlyphCore__ProposalExecuteFailed(); // Cap percentage
             evolutionSuccessRate = proposal.newValue;
             emit BaseRatesUpdated(mutationChance, evolutionSuccessRate);
        } else {
            // Parameter name not recognized
             revert GlyphCore__ProposalExecuteFailed();
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Gets the current vote counts for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return yesVotes The count of "Yes" votes.
    /// @return noVotes The count of "No" votes.
    function getProposalVoteCounts(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id != proposalId && proposal.creator == address(0)) revert GlyphCore__ProposalNotFound(proposalId);
        return (proposal.yesVotes, proposal.noVotes);
    }

    // --- Admin/Role Management Functions ---

    /// @dev See {AccessControl-grantRole}.
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @dev See {AccessControl-revokeRole}.
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /// @dev See {AccessControl-renounceRole}.
    function renounceRole(bytes32 role) public virtual override {
        super.renounceRole(role);
    }

    /// @dev See {AccessControl-hasRole}.
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return super.hasRole(role, account);
    }

    /// @dev See {AccessControl-getRoleAdmin}.
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
         return super.getRoleAdmin(role);
     }

    /// @dev See {Pausable-pause}.
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /// @dev See {Pausable-unpause}.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Sets the address of the GeneEssence ERC20 token contract. Only callable by the default admin role.
    /// Should be called once during setup.
    /// @param _essenceAddress The address of the GeneEssence contract.
    function setGeometryEssenceAddress(address _essenceAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        geneEssence = IERC20(_essenceAddress);
        emit EssenceAddressUpdated(_essenceAddress);
    }

    /// @notice Sets the base costs for breeding, mutation, and evolution. Only callable by the governor role (or via governance).
    /// @param _breedingCost The new cost for breeding in Essence.
    /// @param _mutationCost The new cost for mutation in Essence.
    /// @param _evolutionCost The new cost for evolution in Essence.
     function setBaseCosts(uint256 _breedingCost, uint256 _mutationCost, uint256 _evolutionCost) public onlyGovernor whenNotPaused nonReentrant {
        breedingCost = _breedingCost;
        mutationCost = _mutationCost;
        evolutionCost = _evolutionCost;
        emit BaseCostsUpdated(breedingCost, mutationCost, evolutionCost);
    }

    /// @notice Sets the base rates for mutation chance and evolution success. Only callable by the governor role (or via governance).
    /// Rates are in percentage points * 100 (e.g., 1000 for 10%). Max 10000.
    /// @param _mutationChance The new mutation chance (0-10000).
    /// @param _evolutionSuccessRate The new evolution success rate (0-10000).
     function setBaseRates(uint256 _mutationChance, uint256 _evolutionSuccessRate) public onlyGovernor whenNotPaused nonReentrant {
        if (_mutationChance > 10000 || _evolutionSuccessRate > 10000) revert GlyphCore__ProposalExecuteFailed(); // Prevent setting > 100%
        mutationChance = _mutationChance;
        evolutionSuccessRate = _evolutionSuccessRate;
        emit BaseRatesUpdated(mutationChance, evolutionSuccessRate);
    }

    // --- View/Pure Helper Functions (Internal logic) ---

    /// @notice Generates a set of random genes for a new creature (genesis or child).
    /// WARNING: Uses insecure pseudo-randomness. Replace with VRF for production.
    /// @return A GeneData struct with generated gene values.
    function _generateRandomGenes() internal returns (GeneData memory) {
         // Pseudo-random seed update (insecure)
        _randomSeed = uint256(keccak256(abi.encodePacked(_randomSeed, block.timestamp, msg.sender, tx.gasprice, block.difficulty)));

        uint16[] memory newValues = new uint16[](5); // Example: 5 genes

        // Generate random values for each gene (example: 0-1000 range)
        for (uint i = 0; i < newValues.length; i++) {
             _randomSeed = uint256(keccak256(abi.encodePacked(_randomSeed, i, block.timestamp, block.number)));
             newValues[i] = uint16(_randomSeed % 1001); // Example gene value range
        }

        return GeneData(newValues, block.timestamp);
    }

    /// @notice Inherits genes from two parents to create a child.
    /// Simple example: Averages parent genes with some random variation influenced by environment.
    /// WARNING: Uses insecure pseudo-randomness. Replace with VRF for production.
    /// @param parent1Genes Genes of the first parent.
    /// @param parent2Genes Genes of the second parent.
    /// @param environment Current environmental factors.
    /// @return A GeneData struct for the child Glyph.
    function _inheritGenes(GeneData memory parent1Genes, GeneData memory parent2Genes, EnvironmentalFactors memory environment) internal returns (GeneData memory) {
        // Assume parent genes have the same length
        uint8 geneCount = uint8(parent1Genes.values.length);
        uint16[] memory childValues = new uint16[](geneCount);

         // Pseudo-random seed update (insecure)
        _randomSeed = uint256(keccak256(abi.encodePacked(_randomSeed, block.timestamp, msg.sender, parent1Genes.createdTimestamp, parent2Genes.createdTimestamp)));


        for (uint8 i = 0; i < geneCount; i++) {
            // Simple average inheritance + random variation influenced by environment
             _randomSeed = uint256(keccak256(abi.encodePacked(_randomSeed, i, block.number)));
            uint16 avgGene = uint16((uint256(parent1Genes.values[i]) + uint256(parent2Genes.values[i])) / 2);

            // Add some randomness (e.g., +/- 10% of average, influenced by radiationLevel)
            uint256 variation = (_randomSeed % (avgGene * 20 / 100 + 1)); // Max 10% of avg (+/-)
            if (_randomSeed % 2 == 0) {
                 // Add variation
                 childValues[i] = avgGene + uint16(variation);
            } else {
                 // Subtract variation (ensure no underflow for uint16)
                 if (avgGene > variation) {
                     childValues[i] = avgGene - uint16(variation);
                 } else {
                     childValues[i] = 0; // Clamp at 0
                 }
            }

            // Optional: Environmental influence - e.g., temperature shifts a gene
            if (environment.temperature > 150) { // Example threshold
                childValues[i] = childValues[i] + uint16(environment.temperature / 20); // Add value based on temp
            }
             // Ensure gene values stay within a reasonable range if needed
             childValues[i] = Math.min(childValues[i], 2000); // Example max value
        }

        return GeneData(childValues, block.timestamp);
    }

    /// @notice Applies a mutation to a Glyph's genes.
    /// WARNING: Uses insecure pseudo-randomness. Replace with VRF for production.
    /// @param currentGenes The Glyph's current genes.
    /// @param environment Current environmental factors.
    /// @param baseRandom The pseudo-random number generated for the mutation attempt.
    /// @return A new GeneData struct with mutated genes.
     function _calculateGeneMutation(GeneData memory currentGenes, EnvironmentalFactors memory environment, uint256 baseRandom) internal pure returns (GeneData memory) {
         uint8 geneCount = uint8(currentGenes.values.length);
         uint16[] memory newValues = new uint16[](geneCount);

         // Copy existing genes
         for (uint8 i = 0; i < geneCount; i++) {
             newValues[i] = currentGenes.values[i];
         }

         // Select a random gene to mutate (or multiple)
         uint8 geneToMutateIndex = uint8(baseRandom % geneCount);

         // Apply mutation (e.g., significant change, influenced by radiation)
         uint256 mutationMagnitude = (baseRandom % 500) + 1; // Random magnitude 1-500
         mutationMagnitude = mutationMagnitude + environment.radiationLevel; // Increase magnitude based on radiation

         if (baseRandom % 2 == 0) {
            // Increase gene value
             newValues[geneToMutateIndex] = newValues[geneToMutateIndex] + uint16(mutationMagnitude);
         } else {
             // Decrease gene value (ensure no underflow)
             if (newValues[geneToMutateIndex] > mutationMagnitude) {
                 newValues[geneToMutateIndex] = newValues[geneToMutateIndex] - uint16(mutationMagnitude);
             } else {
                 newValues[geneToMutateIndex] = 0; // Clamp at 0
             }
         }

         // Ensure gene values stay within a reasonable range
         newValues[geneToMutateIndex] = Math.min(newValues[geneToMutateIndex], 2000); // Example max value

         return GeneData(newValues, block.timestamp);
     }

     /// @notice Attempts to evolve a specific gene.
     /// WARNING: Uses insecure pseudo-randomness for success check. Replace with VRF for production.
     /// @param currentGenes The Glyph's current genes.
     /// @param geneIndex The index of the gene to evolve.
     /// @param environment Current environmental factors.
     /// @param baseRandom The pseudo-random number generated for the evolution attempt.
     /// @return A new GeneData struct with potentially evolved genes.
      function _attemptEvolution(GeneData memory currentGenes, uint8 geneIndex, EnvironmentalFactors memory environment, uint256 baseRandom) internal pure returns (GeneData memory) {
         uint8 geneCount = uint8(currentGenes.values.length);
         if (geneIndex >= geneCount) revert GlyphCore__InvalidGeneIndex(); // Should be caught by calling function

         uint16[] memory newValues = new uint16[](geneCount);

         // Copy existing genes
         for (uint8 i = 0; i < geneCount; i++) {
             newValues[i] = currentGenes.values[i];
         }

         // Evolution logic: Significantly increase the target gene value
         // Magnitude might depend on current gene value, environment, etc.
         uint256 evolutionMagnitude = (baseRandom % 200) + 100; // Example: Increase by 100-300

         // Optional: Environment boosts evolution magnitude for specific genes or in certain conditions
         if (environment.temperature < 50) { // Example: Cold environment boosts evolution
             evolutionMagnitude += environment.temperature; // Add some value based on temp
         }


         newValues[geneIndex] = newValues[geneIndex] + uint16(evolutionMagnitude);

          // Ensure gene values stay within a reasonable range
         newValues[geneIndex] = Math.min(newValues[geneIndex], 3000); // Example higher max for evolved genes

         return GeneData(newValues, block.timestamp);
      }

    /// @notice Provides a pseudo-random number. Highly insecure and predictable on chain.
    /// USE CHAINLINK VRF or similar secure oracle for production systems.
    /// @dev Based on block data and mix of inputs. Subject to miner manipulation.
    /// @param input1 A variable input.
    /// @param input2 Another variable input.
    /// @param input3 Another variable input.
    /// @param input4 Another variable input.
    /// @return A pseudo-random uint256.
    function _generatePseudoRandom(uint256 input1, address input2, uint256 input3, uint256 input4) internal returns (uint256) {
         _randomSeed = uint256(keccak256(abi.encodePacked(
            _randomSeed,
            block.timestamp,
            block.difficulty,
            block.number,
            input1,
            input2,
            input3,
            input4,
            gasleft()
        )));
        return _randomSeed;
    }


    /// @dev Returns the current block timestamp. Use for cooldowns etc.
    function _getCurrentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}
```