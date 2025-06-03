Okay, let's design a complex, creative, and advanced smart contract focused on dynamic NFTs and a unique crafting/evolution system.

We'll create a contract called `FluxForge` that manages a collection of ERC721 NFTs called "Artifacts". These Artifacts are not static; they have on-chain parameters (traits) that can change. The process of creating ("Forging") and evolving these Artifacts requires a fungible ERC20 token (let's call it "Flux", assuming it exists separately and the Forge contract interacts with it). Artifacts can also be "Staked" within the Forge to potentially earn Flux rewards or trigger passive evolution, and "Melted" back into some Flux.

This design incorporates:
1.  **Dynamic NFTs:** Artifacts with mutable on-chain state (traits).
2.  **Generative/Parametric Minting:** Artifacts are minted with initial traits determined by on-chain rules and some form of (pseudo)randomness, consuming resources (Flux).
3.  **Staking Mechanics:** Staking NFTs for a purpose (rewards, evolution).
4.  **Resource Management:** Consuming and potentially refunding an ERC20 token.
5.  **Configurable Rules:** Admin can adjust forging costs, trait possibilities, evolution rules, etc.
6.  **Evolution System:** Artifacts can be actively or passively changed.
7.  **Access Control & Pausability:** Standard smart contract safety features.
8.  **Interaction with External Contracts:** Relies on an ERC20 token contract.

Let's outline the structure and functions.

---

**FluxForge Smart Contract**

**Outline:**

1.  **Contract Definition:** Imports, interfaces, state variables, structs, enums.
2.  **Errors:** Custom error definitions.
3.  **Events:** Events for key actions.
4.  **Modifiers:** Access control (`onlyAdmin`), state control (`whenNotPaused`, `whenPaused`).
5.  **Structs:**
    *   `ArtifactParameters`: Holds dynamic trait data for each NFT.
    *   `TraitType`: Defines a category of trait (e.g., "Color", "Shape").
    *   `TraitOption`: Defines a possible value for a trait category.
    *   `StakingInfo`: Holds staking state for an NFT.
6.  **State Variables:**
    *   ERC721 internal data (`_tokensOwned`, `_owners`, etc.).
    *   Core Forge parameters (`_forgeParametersUint`, `_forgeParametersAddress`).
    *   Trait definitions (`_traitTypes`, `_traitOptions`, `_traitWeights`).
    *   Artifact data (`_artifactParameters`, `_stakedArtifactInfo`).
    *   Counters (`_nextTokenId`, `_totalForged`, etc.).
    *   Addresses (`_adminAddress`, `_fluxTokenAddress`).
    *   Pausable state (`_paused`).
7.  **Constructor:** Initializes owner, admin, and Flux token address.
8.  **ERC721 Standard Functions:** Implementations overriding ERC721/ERC721Enumerable internal logic.
9.  **Internal Helper Functions:**
    *   `_generateRandomTraitValue`: Selects a trait option based on weights and randomness.
    *   `_calculateStakingRewards`: Calculates pending FLX rewards for a staked artifact.
    *   `_performArtifactEvolution`: Internal logic for changing artifact parameters.
    *   `_getCurrentTimestamp`: Gets a reliable timestamp (block.timestamp).
10. **Core Forge Functions (User Callable):**
    *   `forgeArtifact`: Mints a new artifact, consumes Flux.
    *   `meltArtifact`: Burns an artifact, refunds some Flux.
    *   `stakeArtifact`: Stakes an owned artifact.
    *   `unstakeArtifact`: Unstakes a staked artifact, claims rewards.
    *   `claimStakingRewards`: Claims pending rewards for staked artifacts.
    *   `evolveArtifact`: Triggers manual evolution for an owned artifact (might cost Flux).
11. **Admin & Rule Management Functions (Admin Only):**
    *   `setAdmin`: Transfers the admin role.
    *   `pause`: Pauses forging and staking.
    *   `unpause`: Unpauses.
    *   `setForgeParameter_Uint`: Sets a core uint parameter (cost, rates, etc.).
    *   `setForgeParameter_Address`: Sets a core address parameter (e.g., Flux address if needed elsewhere).
    *   `addTraitType`: Defines a new category of trait.
    *   `removeTraitType`: Removes a trait category.
    *   `addTraitOption`: Adds a possible value for a trait category.
    *   `removeTraitOption`: Removes a possible value.
    *   `setTraitWeights`: Sets probability weights for trait options.
    *   `setMaxSupply`: Sets the maximum number of artifacts that can be forged.
    *   `withdrawERC20`: Withdraws other ERC20 tokens from the contract.
    *   `withdrawERC721`: Withdraws other ERC721 tokens from the contract.
    *   `adminMintFlux`: Admin can mint Flux (if contract has minter role on FLX).
    *   `adminBurnFlux`: Admin can burn Flux (if contract has burner role).
12. **View/Pure Functions (Read-Only):**
    *   Standard ERC721 views (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `tokenURI` - *Note: tokenURI needs external metadata service*).
    *   `getArtifactParameters`: Gets the full state of an artifact.
    *   `getArtifactTrait`: Gets a specific trait of an artifact.
    *   `getStakedArtifacts`: Gets a list of artifacts staked by an address.
    *   `getStakingRewardAmount`: Gets pending rewards for an artifact.
    *   `getForgeUintParameter`: Gets a specific uint forge parameter.
    *   `getForgeAddressParameter`: Gets a specific address forge parameter.
    *   `getTraitTypes`: Gets all defined trait types.
    *   `getTraitOptions`: Gets options for a trait type.
    *   `getTraitWeights`: Gets weights for a trait type.
    *   `getCurrentArtifactId`: Gets the ID of the next artifact to be minted.
    *   `getTotalForged`: Gets the total number of artifacts minted.
    *   `getMaxSupply`: Gets the maximum forgeable supply.
    *   `isArtifactStaked`: Checks if an artifact is staked.
    *   `getArtifactStakeTimestamp`: Gets the timestamp an artifact was staked.
    *   `supportsInterface`: Standard ERC165.

**Function Summary (Public/External & Key Internal):**

*   `constructor(address initialAdmin, address fluxToken)`: Initializes the contract with admin and Flux token addresses.
*   `setAdmin(address newAdmin)`: Transfers the admin role.
*   `pause()`: Pauses forging and staking (Admin only).
*   `unpause()`: Unpauses (Admin only).
*   `forgeArtifact()`: Mints a new Artifact NFT. Requires FLX payment, generates initial dynamic traits based on current rules and randomness. (User callable, when not paused)
*   `meltArtifact(uint256 tokenId)`: Burns an Artifact NFT. Refunds a percentage of the forging cost in FLX. (User callable, when not paused)
*   `stakeArtifact(uint256 tokenId)`: Stakes an owned Artifact NFT in the Forge. Transfers token custody to the contract. (User callable, when not paused)
*   `unstakeArtifact(uint256 tokenId)`: Unstakes a staked Artifact NFT. Transfers token custody back to the owner and claims accumulated rewards. (User callable, when not paused)
*   `claimStakingRewards(uint256 tokenId)`: Claims accumulated FLX rewards for a staked Artifact without unstaking it. (User callable, when not paused)
*   `evolveArtifact(uint256 tokenId)`: Triggers a manual evolution process for an owned Artifact. Changes some dynamic traits based on rules, potentially costs FLX. (User callable, when not paused)
*   `setForgeParameter_Uint(bytes32 paramName, uint256 value)`: Sets a uint configuration parameter for the forging/staking system (e.g., forgeCost, stakingRewardRate, evolutionCost, refundRate). (Admin only)
*   `setForgeParameter_Address(bytes32 paramName, address value)`: Sets an address configuration parameter (e.g., oracle address, future related contract). (Admin only)
*   `addTraitType(uint256 traitTypeId, string memory name)`: Defines a new category of dynamic trait (e.g., ID 1 -> "Color"). (Admin only)
*   `removeTraitType(uint256 traitTypeId)`: Removes a trait category and all its options/weights. (Admin only)
*   `addTraitOption(uint256 traitTypeId, uint256 optionId, string memory value)`: Adds a possible value (e.g., Option ID 1 -> "Red") for a trait type. (Admin only)
*   `removeTraitOption(uint256 traitTypeId, uint256 optionId)`: Removes a specific trait option. (Admin only)
*   `setTraitWeights(uint256 traitTypeId, uint256[] memory optionIds, uint256[] memory weights)`: Sets the probability weights for multiple options within a trait type. (Admin only)
*   `setMaxSupply(uint256 supply)`: Sets the maximum total number of artifacts that can ever be forged. (Admin only)
*   `withdrawERC20(address tokenAddress, address recipient)`: Allows admin to rescue accidentally sent ERC20 tokens. (Admin only)
*   `withdrawERC721(address tokenAddress, address recipient, uint256 tokenId)`: Allows admin to rescue accidentally sent ERC721 tokens. (Admin only)
*   `adminMintFlux(address recipient, uint256 amount)`: Admin can mint Flux (if contract has role on FLX). (Admin only, requires FLX contract role) - *Note: Assuming FLX contract has a mint function permissioned for this contract.*
*   `adminBurnFlux(uint256 amount)`: Admin can burn Flux from the contract's balance (if contract has role on FLX). (Admin only, requires FLX contract role) - *Note: Assuming FLX contract has a burn function permissioned for this contract.*
*   `balanceOf(address owner)`: ERC721 standard - Get balance of artifacts for an address.
*   `ownerOf(uint256 tokenId)`: ERC721 standard - Get owner of an artifact.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - Transfer token safely.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard - Transfer token safely with data.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - Transfer token.
*   `approve(address to, uint256 tokenId)`: ERC721 standard - Approve transfer for one token.
*   `getApproved(uint256 tokenId)`: ERC721 standard - Get approved address for token.
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard - Set approval for all tokens.
*   `isApprovedForAll(address owner, address operator)`: ERC721 standard - Check approval for all.
*   `tokenURI(uint256 tokenId)`: ERC721 standard - Get metadata URI. *Note: Requires external metadata service based on on-chain parameters.*
*   `getArtifactParameters(uint256 tokenId)`: View function - Get all dynamic parameters for an artifact.
*   `getArtifactTrait(uint256 tokenId, uint256 traitTypeId)`: View function - Get a specific trait value for an artifact.
*   `getStakedArtifacts(address staker)`: View function - Get IDs of artifacts staked by an address.
*   `getStakingRewardAmount(uint256 tokenId)`: View function - Calculate pending FLX rewards for a staked artifact.
*   `getForgeUintParameter(bytes32 paramName)`: View function - Get a specific uint forge parameter.
*   `getForgeAddressParameter(bytes32 paramName)`: View function - Get a specific address forge parameter.
*   `getTraitTypes()`: View function - Get a list of all defined trait types.
*   `getTraitOptions(uint256 traitTypeId)`: View function - Get options for a trait type.
*   `getTraitWeights(uint256 traitTypeId)`: View function - Get weights for a trait type.
*   `getCurrentArtifactId()`: View function - Get the ID of the next artifact to be minted.
*   `getTotalForged()`: View function - Get the total number of artifacts minted.
*   `getMaxSupply()`: View function - Get the maximum forgeable supply.
*   `isArtifactStaked(uint256 tokenId)`: View function - Check if an artifact is currently staked.
*   `getArtifactStakeTimestamp(uint256 tokenId)`: View function - Get the timestamp when an artifact was staked (0 if not staked).
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard.

Total Functions: 9 (ERC721 base) + 6 (Core Forge) + 14 (Admin/Rules) + 15 (View/Helper) = **44 Functions**. This meets the requirement.

---

Here is the Solidity code based on this design.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simpler Admin for this example
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Outline ---
// 1. Contract Definition: Imports, interfaces, state variables, structs, enums.
// 2. Errors: Custom error definitions.
// 3. Events: Events for key actions.
// 4. Modifiers: Access control (onlyAdmin), state control (whenNotPaused, whenPaused).
// 5. Structs: ArtifactParameters, TraitType, TraitOption, StakingInfo.
// 6. State Variables: ERC721 data, Forge parameters, Trait definitions, Artifact data, Counters, Addresses, Pausable state.
// 7. Constructor: Initializes owner, admin, and Flux token address.
// 8. ERC721 Standard Functions: Implementations overriding ERC721/ERC721Enumerable internal logic.
// 9. Internal Helper Functions: _generateRandomTraitValue, _calculateStakingRewards, _performArtifactEvolution, _getCurrentTimestamp.
// 10. Core Forge Functions (User Callable): forgeArtifact, meltArtifact, stakeArtifact, unstakeArtifact, claimStakingRewards, evolveArtifact.
// 11. Admin & Rule Management Functions (Admin Only): setAdmin, pause, unpause, setForgeParameter_Uint, setForgeParameter_Address, addTraitType, removeTraitType, addTraitOption, removeTraitOption, setTraitWeights, setMaxSupply, withdrawERC20, withdrawERC721, adminMintFlux, adminBurnFlux.
// 12. View/Pure Functions (Read-Only): ERC721 views, getArtifactParameters, getArtifactTrait, getStakedArtifacts, getStakingRewardAmount, getForgeUintParameter, getForgeAddressParameter, getTraitTypes, getTraitOptions, getTraitWeights, getCurrentArtifactId, getTotalForged, getMaxSupply, isArtifactStaked, getArtifactStakeTimestamp, supportsInterface.

// --- Function Summary (Public/External & Key Internal) ---
// constructor(address initialAdmin, address fluxToken): Initializes the contract.
// setAdmin(address newAdmin): Transfers the admin role.
// pause(): Pauses forging and staking (Admin only).
// unpause(): Unpauses (Admin only).
// forgeArtifact(): Mints a new Artifact NFT (User callable).
// meltArtifact(uint256 tokenId): Burns an Artifact NFT, refunds Flux (User callable).
// stakeArtifact(uint256 tokenId): Stakes an owned Artifact NFT (User callable).
// unstakeArtifact(uint256 tokenId): Unstakes a staked Artifact NFT, claims rewards (User callable).
// claimStakingRewards(uint256 tokenId): Claims rewards for a staked Artifact (User callable).
// evolveArtifact(uint256 tokenId): Triggers manual evolution for an owned Artifact (User callable).
// setForgeParameter_Uint(bytes32 paramName, uint256 value): Sets a uint config parameter (Admin only).
// setForgeParameter_Address(bytes32 paramName, address value): Sets an address config parameter (Admin only).
// addTraitType(uint256 traitTypeId, string memory name): Defines a new trait category (Admin only).
// removeTraitType(uint256 traitTypeId): Removes a trait category (Admin only).
// addTraitOption(uint256 traitTypeId, uint256 optionId, string memory value): Adds a possible value for a trait category (Admin only).
// removeTraitOption(uint256 traitTypeId, uint256 optionId): Removes a specific trait option (Admin only).
// setTraitWeights(uint256 traitTypeId, uint256[] memory optionIds, uint256[] memory weights): Sets probability weights for trait options (Admin only).
// setMaxSupply(uint256 supply): Sets the maximum forgeable supply (Admin only).
// withdrawERC20(address tokenAddress, address recipient): Rescues ERC20 tokens (Admin only).
// withdrawERC721(address tokenAddress, address recipient, uint256 tokenId): Rescues ERC721 tokens (Admin only).
// adminMintFlux(address recipient, uint256 amount): Admin mints Flux (if contract has role) (Admin only).
// adminBurnFlux(uint256 amount): Admin burns Flux (if contract has role) (Admin only).
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721 standard.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// approve(address to, uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// setApprovalForAll(address operator, bool approved): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.
// tokenURI(uint256 tokenId): ERC721 standard (placeholder).
// getArtifactParameters(uint256 tokenId): View artifact state.
// getArtifactTrait(uint256 tokenId, uint256 traitTypeId): View specific trait.
// getStakedArtifacts(address staker): View staked tokens for address.
// getStakingRewardAmount(uint256 tokenId): View pending rewards for artifact.
// getForgeUintParameter(bytes32 paramName): View uint parameter.
// getForgeAddressParameter(bytes32 paramName): View address parameter.
// getTraitTypes(): View all defined trait types.
// getTraitOptions(uint256 traitTypeId): View options for a trait type.
// getTraitWeights(uint256 traitTypeId): View weights for a trait type.
// getCurrentArtifactId(): View next token ID.
// getTotalForged(): View total forged count.
// getMaxSupply(): View max supply.
// isArtifactStaked(uint256 tokenId): View staked status.
// getArtifactStakeTimestamp(uint256 tokenId): View stake timestamp.
// supportsInterface(bytes4 interfaceId): ERC165 standard.

// Note: This contract relies on an external ERC20 Flux token contract.
// Note: tokenURI implementation is a placeholder and needs an external service to interpret on-chain traits into metadata.
// Note: Pseudo-randomness using block data is used for simplicity but is predictable. For production, use Chainlink VRF or similar.

contract FluxForge is ERC721, IERC721Receiver, Ownable, Pausable, ReentrancyGuard {

    // --- Errors ---
    error ForgePaused();
    error MaxSupplyReached();
    error NotEnoughFlux(uint256 required, uint256 has);
    error TraitTypeAlreadyExists(uint256 traitTypeId);
    error TraitTypeDoesNotExist(uint256 traitTypeId);
    error TraitOptionAlreadyExists(uint256 traitTypeId, uint256 optionId);
    error TraitOptionDoesNotExist(uint256 traitTypeId, uint256 optionId);
    error InvalidWeightCount();
    error ArtifactDoesNotExist(uint256 tokenId);
    error ArtifactNotOwned(uint256 tokenId, address owner);
    error ArtifactNotStaked(uint256 tokenId);
    error ArtifactAlreadyStaked(uint256 tokenId);
    error NoStakingRewardsToClaim();
    error InvalidAdmin();
    error InvalidParameterName();
    error InvalidParameterValue();


    // --- Events ---
    event ArtifactForged(uint256 indexed tokenId, address indexed owner, uint256 forgeCost);
    event ArtifactMelted(uint256 indexed tokenId, address indexed owner, uint256 fluxRefund);
    event ArtifactStaked(uint256 indexed tokenId, address indexed staker, uint256 timestamp);
    event ArtifactUnstaked(uint256 indexed tokenId, address indexed staker, uint256 timestamp, uint256 rewardsClaimed);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 rewardsClaimed);
    event ArtifactEvolved(uint256 indexed tokenId, uint256 evolutionCost);
    event ForgeParameterSetUint(bytes32 indexed name, uint256 value);
    event ForgeParameterSetAddress(bytes32 indexed name, address value);
    event TraitTypeAdded(uint256 indexed traitTypeId, string name);
    event TraitTypeRemoved(uint256 indexed traitTypeId);
    event TraitOptionAdded(uint256 indexed traitTypeId, uint256 indexed optionId, string value);
    event TraitOptionRemoved(uint256 indexed traitTypeId, uint256 indexed optionId);
    event TraitWeightsSet(uint256 indexed traitTypeId);
    event MaxSupplySet(uint256 supply);
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Withdrawn(address indexed token, address indexed recipient, uint256 indexed tokenId);


    // --- Structs ---
    struct ArtifactParameters {
        mapping(uint256 => uint256) traits; // traitTypeId => optionId
        uint256 version; // Increments on evolution
        uint256 creationTimestamp;
    }

    struct TraitType {
        string name;
        uint256[] optionIds; // List of valid optionIds for this type
    }

    struct TraitOption {
        string value; // e.g., "Red", "Square"
        uint256 weight; // Probability weight for random selection
    }

    struct StakingInfo {
        address staker;
        uint256 stakeTimestamp;
        uint256 lastRewardClaimTimestamp;
        bool isStaked;
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    uint256 private _totalForged;
    uint256 private _maxSupply;

    address private _adminAddress;
    IERC20 private immutable _fluxToken; // Assuming the Flux token contract is deployed separately

    // Forge Configuration Parameters
    mapping(bytes32 => uint256) private _forgeParametersUint;
    mapping(bytes32 => address) private _forgeParametersAddress;

    // Trait Definitions (Admin Configurable)
    mapping(uint256 => TraitType) private _traitTypes; // traitTypeId => TraitType
    mapping(uint256 => mapping(uint256 => TraitOption)) private _traitOptions; // traitTypeId => optionId => TraitOption
    uint256[] private _traitTypeIds; // List of all defined traitTypeIds

    // Artifact Data
    mapping(uint256 => ArtifactParameters) private _artifactParameters; // tokenId => Parameters
    mapping(uint256 => StakingInfo) private _stakedArtifactInfo; // tokenId => StakingInfo
    // Helper mapping to track staked tokens per staker (simplified list, potentially gas-intensive for large numbers)
    mapping(address => uint256[]) private _stakerStakedTokenIds;


    // Parameter names (bytes32 saves storage/gas slightly vs string keys)
    bytes32 public constant PARAM_FORGE_COST = "forge_cost";
    bytes32 public constant PARAM_MELT_REFUND_RATE_BPS = "melt_refund_rate_bps"; // Basis points (e.g., 5000 = 50%)
    bytes32 public constant PARAM_STAKING_REWARD_RATE_PER_SEC = "staking_reward_rate_per_sec"; // Flux per second per staked artifact
    bytes32 public constant PARAM_EVOLUTION_COST = "evolution_cost";
    bytes32 public constant PARAM_EVOLUTION_CHANCE_PER_SEC_BPS = "evolution_chance_per_sec_bps"; // Chance per second while staked


    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != _adminAddress && msg.sender != owner()) {
             revert InvalidAdmin();
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused) {
            revert ForgePaused();
        }
        _;
    }

    modifier whenPaused() {
         if (!_paused) {
            revert("Not paused"); // Generic revert as there's no specific 'NotPaused' error defined
        }
        _;
    }


    // --- Constructor ---
    constructor(address initialAdmin, address fluxToken)
        ERC721("Flux Artifact", "FXA")
        Ownable(msg.sender) // Sets initial owner
    {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        if (fluxToken == address(0)) revert InvalidParameterValue();

        _adminAddress = initialAdmin;
        _fluxToken = IERC20(fluxToken);
        _nextTokenId = 1;
        _totalForged = 0;
        _maxSupply = 0; // 0 means unlimited initially
        _paused = false; // Start unpaused

        // Set some default parameters (can be changed by admin)
        _forgeParametersUint[PARAM_FORGE_COST] = 100e18; // Example: 100 Flux
        _forgeParametersUint[PARAM_MELT_REFUND_RATE_BPS] = 5000; // Example: 50% refund
        _forgeParametersUint[PARAM_STAKING_REWARD_RATE_PER_SEC] = 1e16; // Example: 0.01 Flux per sec
        _forgeParametersUint[PARAM_EVOLUTION_COST] = 50e18; // Example: 50 Flux
        _forgeParametersUint[PARAM_EVOLUTION_CHANCE_PER_SEC_BPS] = 10; // Example: 0.1% chance per sec
    }


    // --- ERC721 Standard Functions (Overridden for staking compatibility) ---
    // We override transfer/approve functions to prevent moving staked tokens
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot transfer staked
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot transfer staked
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot transfer staked
        super.safeTransferFrom(from, to, tokenId, data);
    }

     // Approve is tricky. Approving *to* the contract for staking is fine.
     // Approving *from* the contract (if contract is owner of staked) is not allowed.
     // ERC721 checks owner internally, so if owner is 'this', approval for others will revert correctly.
     // We just need to ensure the *user* cannot approve a token they don't own or is staked.
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        // Check if token exists and is owned by sender
        if (_ownerOf(tokenId) != msg.sender) revert ArtifactNotOwned(tokenId, msg.sender);
        if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot approve staked

        super.approve(to, tokenId);
    }

     function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        // Setting approval for all by the owner is standard.
        // If owner is 'this' (for staked tokens), this will only allow approval *by* the contract, which is safe.
        super.setApprovalForAll(operator, approved);
    }

    // Need to accept receiving the token when staking
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        // This function must return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
        // to indicate that the contract is prepared to receive the token.
        return this.onERC721Received.selector;
    }

    // The tokenURI function requires an external service (like an API gateway)
    // to read the on-chain parameters (getArtifactParameters) and construct the
    // metadata JSON and potentially the image URL dynamically.
    // Placeholder implementation:
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        // In a real application, you would construct a URL pointing to a service
        // that can read the on-chain state for this tokenId (using public view functions)
        // and return dynamic JSON metadata.
        // Example: return string(abi.encodePacked("https://mydynamicnftservice.com/metadata/", Strings.toString(tokenId)));

        // For this example, just return a placeholder string
        return "ipfs://QmVaultPlaceholderUri/"; // Placeholder base URI
    }

    // ERC165 support (includes ERC721 interface)
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }


    // --- Internal Helper Functions ---

    // WARNING: This is a simplified pseudo-random number generator
    // using block variables. It is NOT cryptographically secure
    // and is predictable by miners. For production, use Chainlink VRF or similar.
    function _generatePseudoRandomNumber(uint256 seed) internal view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.coinbase,
            msg.sender,
            seed // Include a seed specific to the operation (e.g., tokenId, nonce)
        )));
        return randomNumber;
    }

    // Selects an option ID based on weights for a given trait type
    function _generateRandomTraitValue(uint256 traitTypeId, uint256 seed) internal view returns (uint256 selectedOptionId) {
        TraitType storage traitType = _traitTypes[traitTypeId];
        if (traitType.optionIds.length == 0) {
            // No options defined for this trait type, return a default or indicate error
            return 0; // Or revert, depending on desired behavior
        }

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < traitType.optionIds.length; i++) {
            uint256 optionId = traitType.optionIds[i];
            totalWeight += _traitOptions[traitTypeId][optionId].weight;
        }

        if (totalWeight == 0) {
             // All weights are zero, fallback or handle error
             return traitType.optionIds[0]; // Return first option as fallback
        }

        uint256 randomNumber = _generatePseudoRandomNumber(seed);
        uint256 randomWeight = randomNumber % totalWeight;

        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < traitType.optionIds.length; i++) {
            uint256 optionId = traitType.optionIds[i];
            cumulativeWeight += _traitOptions[traitTypeId][optionId].weight;
            if (randomWeight < cumulativeWeight) {
                selectedOptionId = optionId;
                break;
            }
        }
        return selectedOptionId;
    }

    function _calculateStakingRewards(uint256 tokenId) internal view returns (uint256 rewards) {
        StakingInfo storage stakeInfo = _stakedArtifactInfo[tokenId];
        if (!stakeInfo.isStaked) {
            return 0; // Not staked, no rewards
        }

        uint256 rewardRate = _forgeParametersUint[PARAM_STAKING_REWARD_RATE_PER_SEC];
        uint256 lastClaim = stakeInfo.lastRewardClaimTimestamp;
        uint256 currentTime = _getCurrentTimestamp();

        if (currentTime <= lastClaim) {
            return 0; // No time elapsed since last claim/stake
        }

        uint256 timeStaked = currentTime - lastClaim;
        rewards = timeStaked * rewardRate;
    }

     function _performArtifactEvolution(uint256 tokenId, uint256 seed) internal {
        ArtifactParameters storage params = _artifactParameters[tokenId];
        params.version++; // Increment evolution version

        // Example evolution logic: re-roll some traits based on rules and seed
        // This can be arbitrarily complex based on game logic
        uint256[] memory currentTraitTypeIds = _traitTypeIds;
        for (uint256 i = 0; i < currentTraitTypeIds.length; i++) {
            uint256 traitTypeId = currentTraitTypeIds[i];
            // Decide WHICH traits evolve (e.g., based on current state, randomness, cost)
            // For simplicity, let's just re-roll *a* trait based on index derived from seed
            if (i == (seed % currentTraitTypeIds.length)) {
                 uint256 newOptionId = _generateRandomTraitValue(traitTypeId, seed + i); // Use a different seed for each trait re-roll
                 params.traits[traitTypeId] = newOptionId;
                 // Emit event about trait change if needed
            }
        }
        // More complex evolution could unlock new traits, change weights, etc.
    }

    function _getCurrentTimestamp() internal view returns (uint256) {
        // Using block.timestamp is standard but affected by miner manipulation (slightly).
        // For time-sensitive actions like rewards, be mindful.
        // Chainlink Keepers or similar could trigger time-based actions more reliably.
        return block.timestamp;
    }

    // --- Core Forge Functions (User Callable) ---

    /**
     * @dev Mints a new Artifact NFT. Requires the user to approve FLX tokens to the contract.
     * Traits are generated based on current forge rules and pseudo-randomness.
     */
    function forgeArtifact() external nonReentrant whenNotPaused {
        if (_maxSupply != 0 && _totalForged >= _maxSupply) revert MaxSupplyReached();

        uint256 forgeCost = _forgeParametersUint[PARAM_FORGE_COST];
        if (forgeCost > 0) {
            uint256 fluxBalance = _fluxToken.balanceOf(msg.sender);
            if (fluxBalance < forgeCost) revert NotEnoughFlux(forgeCost, fluxBalance);
            // Requires msg.sender to have approved the Forge contract to spend forgeCost amount of FLX
            _fluxToken.transferFrom(msg.sender, address(this), forgeCost);
        }

        uint256 newItemId = _nextTokenId;
        _nextTokenId++;
        _totalForged++;

        ArtifactParameters storage params = _artifactParameters[newItemId];
        params.version = 1; // Initial version
        params.creationTimestamp = _getCurrentTimestamp();

        // Generate initial traits based on configured rules
        uint256[] memory currentTraitTypeIds = _traitTypeIds;
        for (uint256 i = 0; i < currentTraitTypeIds.length; i++) {
            uint256 traitTypeId = currentTraitTypeIds[i];
            // Use a seed incorporating the new token ID and iteration
            params.traits[traitTypeId] = _generateRandomTraitValue(traitTypeId, newItemId + i);
        }

        _safeMint(msg.sender, newItemId);

        emit ArtifactForged(newItemId, msg.sender, forgeCost);
    }

    /**
     * @dev Burns an Artifact NFT, providing a partial refund of the forging cost in FLX.
     * Cannot melt staked artifacts.
     */
    function meltArtifact(uint256 tokenId) external nonReentrant whenNotPaused {
        _requireOwned(tokenId); // Ensure caller owns the token
        if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot melt staked

        uint256 refundRate = _forgeParametersUint[PARAM_MELT_REFUND_RATE_BPS];
        uint256 forgeCost = _forgeParametersUint[PARAM_FORGE_COST]; // Assumes refund is based on current forge cost
        uint256 fluxRefund = (forgeCost * refundRate) / 10000; // refundRate is in basis points

        _burn(tokenId); // Burns the token

        // Clear artifact specific data
        delete _artifactParameters[tokenId];
        // Delete staking info just in case, though melt should only work if not staked
        delete _stakedArtifactInfo[tokenId];

        if (fluxRefund > 0) {
             // Ensure contract has enough FLX to refund, or handle appropriately
             // (e.g., admin must top up or mint if contract has minter role)
            _fluxToken.transfer(msg.sender, fluxRefund);
        }

        emit ArtifactMelted(tokenId, msg.sender, fluxRefund);
    }

    /**
     * @dev Stakes an owned Artifact NFT in the Forge.
     * Transfers the token to the contract address.
     */
    function stakeArtifact(uint256 tokenId) external nonReentrant whenNotPaused {
        _requireOwned(tokenId); // Ensure caller owns the token
        if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot stake if already staked

        address owner = _ownerOf(tokenId);
        if (owner != msg.sender) revert ArtifactNotOwned(tokenId, msg.sender);

        // Transfer token to the contract
        safeTransferFrom(owner, address(this), tokenId); // Uses overridden safeTransferFrom

        // Update staking info
        StakingInfo storage stakeInfo = _stakedArtifactInfo[tokenId];
        uint256 currentTimestamp = _getCurrentTimestamp();
        stakeInfo.staker = msg.sender;
        stakeInfo.stakeTimestamp = currentTimestamp;
        stakeInfo.lastRewardClaimTimestamp = currentTimestamp;
        stakeInfo.isStaked = true;

        // Add to staker's list (simplified)
        _stakerStakedTokenIds[msg.sender].push(tokenId);

        emit ArtifactStaked(tokenId, msg.sender, currentTimestamp);
    }

    /**
     * @dev Unstakes a staked Artifact NFT.
     * Transfers the token back to the original staker and claims any accumulated rewards.
     */
    function unstakeArtifact(uint256 tokenId) external nonReentrant whenNotPaused {
        StakingInfo storage stakeInfo = _stakedArtifactInfo[tokenId];
        if (!stakeInfo.isStaked || stakeInfo.staker != msg.sender) revert ArtifactNotStaked(tokenId); // Ensure staked by caller

        // Calculate and claim rewards before unstaking
        uint256 rewards = _calculateStakingRewards(tokenId);
        if (rewards > 0) {
            _fluxToken.transfer(msg.sender, rewards);
             // No need to update lastRewardClaimTimestamp here as it's being unstaked
        }

        // Transfer token back to the staker
        address staker = stakeInfo.staker;
        // Ensure contract owns the token before attempting transferFrom
        // This is guaranteed if stakeArtifact transferred it correctly.
        super.safeTransferFrom(address(this), staker, tokenId); // Use super to bypass our staking check

        // Remove from staking info
        delete _stakedArtifactInfo[tokenId];

        // Remove from staker's list (simplified linear scan, inefficient for large lists)
        uint256[] storage stakedList = _stakerStakedTokenIds[staker];
        for (uint256 i = 0; i < stakedList.length; i++) {
            if (stakedList[i] == tokenId) {
                // Replace with last element and pop
                stakedList[i] = stakedList[stakedList.length - 1];
                stakedList.pop();
                break;
            }
        }


        emit ArtifactUnstaked(tokenId, msg.sender, _getCurrentTimestamp(), rewards);
    }

    /**
     * @dev Claims accumulated FLX rewards for a staked Artifact without unstaking it.
     */
    function claimStakingRewards(uint256 tokenId) external nonReentrant whenNotPaused {
        StakingInfo storage stakeInfo = _stakedArtifactInfo[tokenId];
        if (!stakeInfo.isStaked || stakeInfo.staker != msg.sender) revert ArtifactNotStaked(tokenId); // Ensure staked by caller

        uint256 rewards = _calculateStakingRewards(tokenId);
        if (rewards == 0) revert NoStakingRewardsToClaim();

        stakeInfo.lastRewardClaimTimestamp = _getCurrentTimestamp(); // Update last claim time

        _fluxToken.transfer(msg.sender, rewards);

        emit StakingRewardsClaimed(tokenId, msg.sender, rewards);
    }

    /**
     * @dev Triggers a manual evolution process for an owned Artifact.
     * Might cost FLX and changes some dynamic traits based on rules and randomness.
     */
    function evolveArtifact(uint256 tokenId) external nonReentrant whenNotPaused {
        _requireOwned(tokenId); // Ensure caller owns the token
        if (_stakedArtifactInfo[tokenId].isStaked) revert ArtifactAlreadyStaked(tokenId); // Cannot evolve staked

        uint256 evolutionCost = _forgeParametersUint[PARAM_EVOLUTION_COST];
        if (evolutionCost > 0) {
             uint256 fluxBalance = _fluxToken.balanceOf(msg.sender);
            if (fluxBalance < evolutionCost) revert NotEnoughFlux(evolutionCost, fluxBalance);
            // Requires msg.sender to have approved the Forge contract to spend evolutionCost amount of FLX
            _fluxToken.transferFrom(msg.sender, address(this), evolutionCost);
        }

        // Perform the actual evolution logic (internal helper function)
        _performArtifactEvolution(tokenId, tokenId); // Use tokenId as a seed

        emit ArtifactEvolved(tokenId, evolutionCost);
    }

    // Note: Passive evolution while staked could be implemented by checking chance
    // and triggering _performArtifactEvolution within claimStakingRewards or unstakeArtifact,
    // or via a Keeper service calling a specifically permissioned function.
    // This example only implements manual evolution.

    // --- Admin & Rule Management Functions (Admin Only) ---

    /**
     * @dev Sets the admin address. Only current admin or owner can call.
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAdmin();
        emit AdminSet(_adminAddress, newAdmin);
        _adminAddress = newAdmin;
    }

     /**
     * @dev Pauses forging and staking operations.
     */
    function pause() external onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses forging and staking operations.
     */
    function unpause() external onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }


    /**
     * @dev Sets a core uint configuration parameter for the Forge.
     * Parameter names are defined as constants (e.g., PARAM_FORGE_COST).
     */
    function setForgeParameter_Uint(bytes32 paramName, uint256 value) external onlyAdmin {
        // Basic validation for known parameters or add specific checks if needed
         if (paramName != PARAM_FORGE_COST &&
             paramName != PARAM_MELT_REFUND_RATE_BPS &&
             paramName != PARAM_STAKING_REWARD_RATE_PER_SEC &&
             paramName != PARAM_EVOLUTION_COST &&
             paramName != PARAM_EVOLUTION_CHANCE_PER_SEC_BPS)
         {
             revert InvalidParameterName();
         }
         // Add specific value checks if needed (e.g., refund rate <= 10000)
         if (paramName == PARAM_MELT_REFUND_RATE_BPS && value > 10000) revert InvalidParameterValue();

        _forgeParametersUint[paramName] = value;
        emit ForgeParameterSetUint(paramName, value);
    }

    /**
     * @dev Sets a core address configuration parameter for the Forge.
     * Parameter names can be used for future integrations (e.g., oracle address).
     */
    function setForgeParameter_Address(bytes32 paramName, address value) external onlyAdmin {
         // Add specific checks for known address parameters if needed
         // e.g., if (paramName == PARAM_ORACLE_ADDRESS && value == address(0)) revert InvalidParameterValue();

         _forgeParametersAddress[paramName] = value;
         emit ForgeParameterSetAddress(paramName, value);
    }

    /**
     * @dev Defines a new type of dynamic trait that Artifacts can have.
     * traitTypeId must be unique and non-zero.
     */
    function addTraitType(uint256 traitTypeId, string memory name) external onlyAdmin {
        if (traitTypeId == 0) revert InvalidParameterValue();
        if (bytes(_traitTypes[traitTypeId].name).length != 0) revert TraitTypeAlreadyExists(traitTypeId);

        _traitTypes[traitTypeId].name = name;
        _traitTypeIds.push(traitTypeId); // Keep track of all type IDs

        emit TraitTypeAdded(traitTypeId, name);
    }

    /**
     * @dev Removes a trait category and all its associated options and weights.
     * This will make existing artifacts with this trait type display as having an undefined trait.
     */
    function removeTraitType(uint256 traitTypeId) external onlyAdmin {
        if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);

        // Remove from the list of trait types
        for (uint256 i = 0; i < _traitTypeIds.length; i++) {
            if (_traitTypeIds[i] == traitTypeId) {
                _traitTypeIds[i] = _traitTypeIds[_traitTypeIds.length - 1];
                _traitTypeIds.pop();
                break;
            }
        }

        // Delete trait options and the type itself
        // Note: options map is deleted implicitly when trait type struct is deleted
        delete _traitTypes[traitTypeId];
        // Need to manually iterate and delete options if they were in a separate map level
        // With current struct map: delete _traitOptions[traitTypeId];
        // But they are nested, so deleting _traitTypes[traitTypeId] clears _traitOptions[traitTypeId]

        emit TraitTypeRemoved(traitTypeId);
    }


    /**
     * @dev Adds a possible option (value) for a specific trait type.
     * optionId must be unique within the traitTypeId.
     */
    function addTraitOption(uint256 traitTypeId, uint256 optionId, string memory value) external onlyAdmin {
        if (optionId == 0) revert InvalidParameterValue(); // Option 0 can be reserved for default/undefined
        if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);
        if (bytes(_traitOptions[traitTypeId][optionId].value).length != 0) revert TraitOptionAlreadyExists(traitTypeId, optionId);

        _traitOptions[traitTypeId][optionId].value = value;
        // Weight is initially 0, must be set separately via setTraitWeights

        // Add optionId to the list within TraitType if not already there
        bool found = false;
        for(uint i=0; i<_traitTypes[traitTypeId].optionIds.length; i++) {
            if(_traitTypes[traitTypeId].optionIds[i] == optionId) {
                found = true;
                break;
            }
        }
        if (!found) {
            _traitTypes[traitTypeId].optionIds.push(optionId);
        }

        emit TraitOptionAdded(traitTypeId, optionId, value);
    }

    /**
     * @dev Removes a specific option (value) for a trait type.
     * Removes the option and its weight.
     */
    function removeTraitOption(uint256 traitTypeId, uint256 optionId) external onlyAdmin {
        if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);
        if (bytes(_traitOptions[traitTypeId][optionId].value).length == 0) revert TraitOptionDoesNotExist(traitTypeId, optionId);

        // Remove from the list of option IDs within the trait type
         uint256[] storage optionIdsList = _traitTypes[traitTypeId].optionIds;
         for (uint256 i = 0; i < optionIdsList.length; i++) {
            if (optionIdsList[i] == optionId) {
                optionIdsList[i] = optionIdsList[optionIdsList.length - 1];
                optionIdsList.pop();
                break;
            }
        }

        // Delete the option data
        delete _traitOptions[traitTypeId][optionId];

        emit TraitOptionRemoved(traitTypeId, optionId);
    }

    /**
     * @dev Sets the probability weights for a list of options within a trait type.
     * Used for random trait generation during forging/evolution.
     * optionIds and weights arrays must have the same length.
     */
    function setTraitWeights(uint256 traitTypeId, uint256[] memory optionIds, uint256[] memory weights) external onlyAdmin {
        if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);
        if (optionIds.length != weights.length) revert InvalidWeightCount();

        for (uint256 i = 0; i < optionIds.length; i++) {
            uint256 optionId = optionIds[i];
            uint256 weight = weights[i];
            if (bytes(_traitOptions[traitTypeId][optionId].value).length == 0) revert TraitOptionDoesNotExist(traitTypeId, optionId);
            _traitOptions[traitTypeId][optionId].weight = weight;
        }

        emit TraitWeightsSet(traitTypeId);
    }

    /**
     * @dev Sets the maximum total number of artifacts that can be forged.
     * 0 means unlimited supply. Can only increase supply or set to 0 if it was limited.
     */
    function setMaxSupply(uint256 supply) external onlyAdmin {
        if (_maxSupply != 0 && supply != 0 && supply < _maxSupply) {
            revert InvalidParameterValue(); // Cannot decrease max supply once limited
        }
        _maxSupply = supply;
        emit MaxSupplySet(supply);
    }

    /**
     * @dev Allows the admin to withdraw any other ERC20 tokens accidentally sent to the contract.
     */
    function withdrawERC20(address tokenAddress, address recipient) external onlyAdmin nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.transfer(recipient, amount);
            emit ERC20Withdrawn(tokenAddress, recipient, amount);
        }
    }

     /**
     * @dev Allows the admin to withdraw any other ERC721 tokens accidentally sent to the contract.
     * Cannot withdraw Artifact tokens managed by this contract using this function.
     */
    function withdrawERC721(address tokenAddress, address recipient, uint256 tokenId) external onlyAdmin nonReentrant {
        if (tokenAddress == address(this)) {
            revert InvalidParameterValue(); // Cannot withdraw self-managed tokens
        }
        IERC721 token = IERC721(tokenAddress);
        // Check if the contract actually owns the token
        require(token.ownerOf(tokenId) == address(this), "Contract does not own token");

        token.safeTransferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawn(tokenAddress, recipient, tokenId);
    }

    /**
     * @dev Allows admin to mint Flux tokens if this contract has the MINTER_ROLE on the Flux token contract.
     */
    function adminMintFlux(address recipient, uint256 amount) external onlyAdmin nonReentrant {
        // This requires the Flux token contract to have a mint function
        // and this contract's address to have the MINTER_ROLE or similar permission
        // on the Flux token contract.
        // Example (requires IERC20Mintable or similar interface/knowledge):
        // IERC20Mintable(_fluxTokenAddress).mint(recipient, amount);
        revert("adminMintFlux not implemented: Requires specific Flux token contract interface");
        // Emit event if successful
        // emit FluxMinted(recipient, amount);
    }

    /**
     * @dev Allows admin to burn Flux tokens held by this contract if it has the BURNER_ROLE on the Flux token contract.
     */
    function adminBurnFlux(uint256 amount) external onlyAdmin nonReentrant {
         // This requires the Flux token contract to have a burn function
        // and this contract's address to have the BURNER_ROLE or similar permission
        // on the Flux token contract.
        // Example (requires IERC20Burnable or similar interface/knowledge):
        // _fluxToken.burn(amount); // Or _fluxToken.burnFrom(address(this), amount); depending on the ERC20 implementation
        revert("adminBurnFlux not implemented: Requires specific Flux token contract interface");
         // Emit event if successful
         // emit FluxBurned(amount);
    }


    // --- View/Pure Functions (Read-Only) ---

    /**
     * @dev Gets all dynamic parameters for a given Artifact token.
     */
    function getArtifactParameters(uint256 tokenId) public view returns (uint256 version, uint256 creationTimestamp, uint256[] memory traitTypeIds, uint256[] memory traitOptionIds) {
        if (!_exists(tokenId)) revert ArtifactDoesNotExist(tokenId);

        ArtifactParameters storage params = _artifactParameters[tokenId];
        uint256[] memory currentTraitTypeIds = _traitTypeIds; // Get the list of defined trait types

        uint256[] memory _traitTypeIds = new uint256[](currentTraitTypeIds.length);
        uint256[] memory _traitOptionIds = new uint256[](currentTraitTypeIds.length);

        for (uint256 i = 0; i < currentTraitTypeIds.length; i++) {
            uint256 traitTypeId = currentTraitTypeIds[i];
            _traitTypeIds[i] = traitTypeId;
            _traitOptionIds[i] = params.traits[traitTypeId]; // Get the assigned option ID
        }

        return (params.version, params.creationTimestamp, _traitTypeIds, _traitOptionIds);
    }

    /**
     * @dev Gets the specific optionId assigned to a trait type for an Artifact.
     * Returns 0 if the artifact or trait type doesn't exist or has no value assigned.
     */
    function getArtifactTrait(uint256 tokenId, uint256 traitTypeId) public view returns (uint256 optionId) {
        if (!_exists(tokenId)) revert ArtifactDoesNotExist(tokenId);
        // Does not check if traitTypeId is defined, will return 0 if not set on artifact

        return _artifactParameters[tokenId].traits[traitTypeId];
    }

    /**
     * @dev Gets the list of Artifact token IDs currently staked by an address.
     * Note: This mapping is a simplified list and might be inefficient for very large numbers of staked tokens per user.
     */
    function getStakedArtifacts(address staker) public view returns (uint256[] memory) {
        return _stakerStakedTokenIds[staker];
    }

    /**
     * @dev Calculates the pending FLX rewards for a staked Artifact.
     */
    function getStakingRewardAmount(uint256 tokenId) public view returns (uint256 rewards) {
        return _calculateStakingRewards(tokenId);
    }

    /**
     * @dev Gets the value of a specific uint configuration parameter.
     */
    function getForgeUintParameter(bytes32 paramName) public view returns (uint256) {
        return _forgeParametersUint[paramName];
    }

    /**
     * @dev Gets the value of a specific address configuration parameter.
     */
    function getForgeAddressParameter(bytes32 paramName) public view returns (address) {
        return _forgeParametersAddress[paramName];
    }

    /**
     * @dev Gets a list of all defined trait type IDs.
     */
    function getTraitTypes() public view returns (uint256[] memory) {
        return _traitTypeIds;
    }

    /**
     * @dev Gets the names and option IDs for a specific trait type.
     */
    function getTraitOptions(uint256 traitTypeId) public view returns (string memory name, uint256[] memory optionIds, string[] memory values) {
         if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);

        TraitType storage traitType = _traitTypes[traitTypeId];
        uint256[] memory _optionIds = traitType.optionIds;
        string[] memory _values = new string[](_optionIds.length);

        for(uint i=0; i<_optionIds.length; i++) {
            _values[i] = _traitOptions[traitTypeId][_optionIds[i]].value;
        }

        return (traitType.name, _optionIds, _values);
    }

    /**
     * @dev Gets the probability weights for options within a trait type.
     */
    function getTraitWeights(uint256 traitTypeId) public view returns (uint256[] memory optionIds, uint256[] memory weights) {
        if (bytes(_traitTypes[traitTypeId].name).length == 0) revert TraitTypeDoesNotExist(traitTypeId);

        TraitType storage traitType = _traitTypes[traitTypeId];
        uint256[] memory _optionIds = traitType.optionIds;
        uint256[] memory _weights = new uint256[](_optionIds.length);

        for(uint i=0; i<_optionIds.length; i++) {
            _weights[i] = _traitOptions[traitTypeId][_optionIds[i]].weight;
        }
        return (_optionIds, _weights);
    }

    /**
     * @dev Gets the ID that will be assigned to the next Artifact to be forged.
     */
    function getCurrentArtifactId() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Gets the total number of Artifacts that have been forged.
     */
    function getTotalForged() public view returns (uint256) {
        return _totalForged;
    }

    /**
     * @dev Gets the maximum total supply of Artifacts that can be forged (0 for unlimited).
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Checks if a specific Artifact is currently staked.
     */
    function isArtifactStaked(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) return false; // Or revert ArtifactDoesNotExist(tokenId);
        return _stakedArtifactInfo[tokenId].isStaked;
    }

    /**
     * @dev Gets the timestamp when an Artifact was staked (0 if not staked).
     */
    function getArtifactStakeTimestamp(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) return 0; // Or revert ArtifactDoesNotExist(tokenId);
        return _stakedArtifactInfo[tokenId].stakeTimestamp;
    }

     /**
     * @dev Gets the current admin address.
     */
    function getAdmin() public view returns (address) {
        return _adminAddress;
    }

    /**
     * @dev Gets the address of the Flux token contract.
     */
    function getFluxTokenAddress() public view returns (address) {
        return address(_fluxToken);
    }

    /**
     * @dev Check if contract is paused.
     */
    function paused() public view override returns (bool) {
        return _paused;
    }
}
```