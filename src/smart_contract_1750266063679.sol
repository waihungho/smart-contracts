Okay, let's design a smart contract concept that's a bit different from standard tokens or simple NFTs.

How about a "Symbiotic Growth Vault" contract? It combines aspects of ERC721 (for unique digital assets), resource management (using an ERC20 token), and dynamic state evolution based on deposited resources and time. It's not a simple staking contract, not a standard ERC721 with static metadata, and not a generic ERC20 pool.

The core idea: Users "cultivate" unique NFTs by depositing a specific resource token into a vault linked to the NFT. The NFT's attributes and appearance (via metadata) dynamically change or "evolve" based on the amount of resources staked and the time elapsed, or upon triggered actions that consume resources.

Let's outline the concept and then implement it.

---

## Symbiotic Growth Vault Smart Contract Outline

**Contract Name:** `SymbioticGrowthVault`

**Description:** This contract manages unique, evolving digital assets (Symbiotic NFTs) linked to resource vaults. Users deposit a designated ERC20 `ResourceToken` into a vault associated with a specific NFT they own. The NFT's attributes dynamically change or "evolve" based on the resources held in its vault and triggered actions. The contract integrates ERC721 functionality for managing the NFTs themselves.

**Key Concepts:**
1.  **Dynamic NFTs:** NFT attributes are not static; they change based on on-chain state (`resourceBalance`, `growthPoints`, triggered evolution).
2.  **Resource Vaults:** Each NFT is associated with a dedicated internal vault holding `ResourceToken`.
3.  **Growth Mechanism:** Resources in the vault generate "Growth Points" over time or based on quantity.
4.  **Triggered Evolution:** Users can consume accumulated `Growth Points` and potentially some `ResourceToken` to trigger an evolution event, permanently changing the NFT's attributes.
5.  **Merging:** Two Symbiotic NFTs can be merged, combining their resources and potentially creating a new, more powerful NFT.
6.  **Delegated Management:** Owners can delegate deposit/withdrawal rights for their vault without transferring NFT ownership.
7.  **Evolution Permissions:** Owners can grant specific addresses permission to trigger evolution on their behalf.

**Inheritance:**
*   `ERC721` (from OpenZeppelin) for standard NFT functionality.
*   `Ownable` (from OpenZeppelin) for administrative control.
*   `Pausable` (from OpenZeppelin) for emergency pausing.
*   `ReentrancyGuard` (from OpenZeppelin) for secure withdrawals.

**State Variables Summary:**
*   `resourceToken`: Address of the ERC20 resource token.
*   `evolutionEssenceToken`: Address of an optional ERC20 essence token generated during evolution.
*   `evolutionParameters`: Struct defining constants for growth and evolution logic.
*   `_growthStates`: Mapping from NFT ID to its `NFTGrowthState` struct (resource balance, growth points, attributes, last update time).
*   `_growthDelegates`: Mapping from NFT ID to address allowed to manage its vault.
*   `_evolutionPermissions`: Mapping from NFT ID to addresses allowed to trigger evolution.
*   `_baseTokenURI`: Base URI for NFT metadata.
*   Standard ERC721 state variables (`_owners`, `_balances`, etc.).

**Events Summary:**
*   `NFTMinted`: When a new NFT is minted.
*   `ResourceDeposited`: When resources are deposited into a vault.
*   `ResourceWithdrawn`: When resources are withdrawn from a vault.
*   `GrowthPointsHarvested`: When growth points are added to `currentGrowthPoints`.
*   `EvolutionTriggered`: When an NFT evolves.
*   `NFTMerged`: When two NFTs are merged.
*   `GrowthDelegateSet`: When a growth delegate is set or revoked.
*   `EvolutionPermissionSet`: When evolution permission is granted or revoked.
*   `ParametersUpdated`: When admin updates evolution parameters.
*   Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`).
*   Standard Ownable events (`TransferOwnership`).
*   Standard Pausable events (`Paused`, `Unpaused`).

**Function Categories:**

1.  **Setup & Admin (Inherited & Custom):**
    *   `constructor`
    *   `transferOwnership`
    *   `renounceOwnership`
    *   `pause`
    *   `unpause`
    *   `setEvolutionParameters`
    *   `setBaseTokenURI`
    *   `withdrawAdminFees` (if fees implemented)
    *   `getResourceTokenAddress`
    *   `getEvolutionEssenceAddress`

2.  **ERC721 Standard (Overridden/Implemented):**
    *   `balanceOf`
    *   `ownerOf`
    *   `safeTransferFrom` (ERC721 standard overloads)
    *   `transferFrom`
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
    *   `tokenURI` (Dynamic implementation)
    *   `supportsInterface` (ERC165)
    *   `totalSupply`
    *   `tokenOfOwnerByIndex`

3.  **NFT Creation & Core Vault Management:**
    *   `mintNFT`
    *   `depositResource`
    *   `withdrawResource`
    *   `getVaultBalance`

4.  **Growth & Evolution:**
    *   `harvestGrowthPoints` (Internal helper, triggered by deposits, withdrawals, evolution)
    *   `calculatePendingGrowthPoints` (View function)
    *   `getGrowthStatus` (View function, includes current points)
    *   `getNFTAttributes` (View function)
    *   `triggerEvolution`

5.  **Advanced Mechanics:**
    *   `mergeNFTs`
    *   `delegateGrowthManagement`
    *   `revokeGrowthManagement`
    *   `grantEvolutionPermission`
    *   `revokeEvolutionPermission`
    *   `hasGrowthDelegate` (View)
    *   `getGrowthDelegate` (View)
    *   `hasEvolutionPermission` (View)

---

## Function Summary (Guaranteed 20+ Functions)

1.  `constructor(address _resourceToken, address _evolutionEssenceToken, string memory _baseTokenURI)`: Initializes the contract, setting token addresses and base URI. Sets initial evolution parameters.
2.  `setEvolutionParameters(uint256 _tokensPerGrowthPoint, uint256 _pointsPerLevel, uint256 _essencePerPoint, uint256 _resourceConsumptionRate, uint256 _adminFeeRate)`: Allows owner to update the constants governing growth and evolution.
3.  `setBaseTokenURI(string memory _baseTokenURI)`: Allows owner to set the base URI for NFT metadata.
4.  `withdrawAdminFees(address _tokenAddress, address _recipient)`: Allows owner to withdraw accumulated fees (if any mechanism sends fees to owner, e.g., a small cut of consumed resources). *Requires a fee mechanism to be built into `triggerEvolution`.*
5.  `getResourceTokenAddress() public view returns (address)`: Returns the address of the resource token.
6.  `getEvolutionEssenceAddress() public view returns (address)`: Returns the address of the evolution essence token.
7.  `balanceOf(address owner) public view override returns (uint256)`: ERC721 standard - Returns the number of NFTs owned by `owner`.
8.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721 standard - Returns the owner of the NFT with `tokenId`.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override`: ERC721 standard - Safely transfers NFT ownership.
10. `safeTransferFrom(address from, address to, uint256 tokenId) public override`: ERC721 standard - Safely transfers NFT ownership.
11. `transferFrom(address from, address to, uint256 tokenId) public override`: ERC721 standard - Transfers NFT ownership.
12. `approve(address to, uint256 tokenId) public override`: ERC721 standard - Approves an address to manage an NFT.
13. `setApprovalForAll(address operator, bool approved) public override`: ERC721 standard - Sets approval for an operator for all owner's NFTs.
14. `getApproved(uint256 tokenId) public view override returns (address)`: ERC721 standard - Returns the approved address for an NFT.
15. `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721 standard - Returns if an operator is approved for all owner's NFTs.
16. `tokenURI(uint256 tokenId) public view override returns (string memory)`: ERC721 standard (dynamic) - Returns the metadata URI for an NFT, incorporating its dynamic state.
17. `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: ERC165 standard - Indicates supported interfaces (ERC721, ERC165).
18. `totalSupply() public view returns (uint256)`: ERC721 standard - Returns the total number of NFTs minted.
19. `tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256)`: ERC721 standard (Enumerable extension helper) - Returns token ID by index for an owner. (Note: Enumerable is resource intensive, might skip full inheritance but implement this for basic enumeration).
20. `mintNFT(address to)`: Mints a new Symbiotic NFT and creates its associated growth vault.
21. `depositResource(uint256 tokenId, uint256 amount)`: Deposits `amount` of `ResourceToken` into the vault for `tokenId`. Only owner or delegate can call.
22. `withdrawResource(uint256 tokenId, uint256 amount)`: Withdraws `amount` of `ResourceToken` from the vault for `tokenId`. Only owner or delegate can call.
23. `getVaultBalance(uint256 tokenId) public view returns (uint256)`: Returns the current `ResourceToken` balance in the vault for `tokenId`.
24. `calculatePendingGrowthPoints(uint256 tokenId) public view returns (uint256)`: Calculates the theoretical growth points accrued based on the current resource balance *since* the last harvest/update, *without* modifying state.
25. `getGrowthStatus(uint256 tokenId) public view returns (uint256 currentGrowthPoints, uint256 lastUpdateTime, uint256 vaultBalance)`: Returns current state relevant to growth for an NFT.
26. `getNFTAttributes(uint256 tokenId) public view returns (uint256 level, uint256 power, uint256 defense, string memory appearanceKey)`: Returns the current dynamic attributes of the NFT.
27. `triggerEvolution(uint256 tokenId)`: Allows the owner or an approved address to consume `GrowthPoints` and potentially `ResourceToken` to evolve the NFT's attributes.
28. `mergeNFTs(uint256 primaryTokenId, uint256 secondaryTokenId)`: Merges `secondaryTokenId` into `primaryTokenId`. Requires calling address to own both. Transfers resources and burns `secondaryTokenId`. Attributes are combined based on defined logic.
29. `delegateGrowthManagement(uint256 tokenId, address delegatee)`: Sets or revokes the growth delegate for an NFT vault. Only owner can call.
30. `revokeGrowthManagement(uint256 tokenId)`: Revokes the current growth delegate. Only owner can call.
31. `hasGrowthDelegate(uint256 tokenId) public view returns (bool)`: Checks if an NFT has a growth delegate set.
32. `getGrowthDelegate(uint256 tokenId) public view returns (address)`: Returns the current growth delegate address.
33. `grantEvolutionPermission(uint256 tokenId, address permissionedAddress)`: Grants `permissionedAddress` the right to call `triggerEvolution` for `tokenId`. Only owner can call.
34. `revokeEvolutionPermission(uint256 tokenId)`: Revokes evolution permission for the previously granted address. Only owner can call.
35. `hasEvolutionPermission(uint256 tokenId, address potentialGranter) public view returns (bool)`: Checks if `potentialGranter` has evolution permission for `tokenId`.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Included for tokenOfOwnerByIndex
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Note: ERC721Enumerable adds complexity and gas cost. For a production system
// with potentially many NFTs, consider if tokenOfOwnerByIndex is truly needed
// or if off-chain indexing is preferable. Included here to meet function count
// and provide a standard ERC721 enumeration helper.

contract SymbioticGrowthVault is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---

    struct Attributes {
        uint256 level; // Represents overall evolution level
        uint256 power;
        uint256 defense;
        string appearanceKey; // Key to reference off-chain appearance data (e.g., IPFS hash suffix)
    }

    struct EvolutionParameters {
        uint256 tokensPerGrowthPoint; // How many resource tokens yield 1 growth point per second/unit time (simplified: total tokens yield points)
        uint256 pointsPerLevel;       // How many growth points are needed to level up attributes
        uint256 essencePerPoint;      // How much essence token is generated per growth point consumed (scaled)
        uint256 resourceConsumptionRate; // Percentage (scaled, e.g., 100 = 1%) of vault resources consumed during evolution
        uint256 adminFeeRate;         // Percentage (scaled) of consumed resources sent to admin
    }

    struct NFTGrowthState {
        uint256 resourceBalance;      // Total ResourceToken in the vault for this NFT
        uint256 lastGrowthUpdateTime; // Timestamp of the last deposit/withdrawal/evolution/harvest
        uint256 currentGrowthPoints;  // Growth points accumulated and harvested
        Attributes attributes;        // Dynamic attributes of the NFT
    }

    // --- State Variables ---

    IERC20 public immutable resourceToken;
    IERC20 public immutable evolutionEssenceToken; // Optional token generated on evolution

    EvolutionParameters public evolutionParameters;

    mapping(uint256 => NFTGrowthState) private _growthStates;
    mapping(uint256 => address) private _growthDelegates; // tokenId -> delegate address for vault management
    mapping(uint256 => address) private _evolutionPermissions; // tokenId -> address granted permission to trigger evolution

    string private _baseTokenURI;

    Counters.Counter private _tokenIdCounter;

    // --- Events ---

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event ResourceDeposited(uint256 indexed tokenId, address indexed account, uint256 amount, uint256 newBalance);
    event ResourceWithdrawn(uint256 indexed tokenId, address indexed account, uint256 amount, uint256 newBalance);
    event GrowthPointsHarvested(uint256 indexed tokenId, uint256 harvestedPoints, uint256 totalGrowthPoints);
    event EvolutionTriggered(uint256 indexed tokenId, address indexed triggerer, uint256 pointsConsumed, uint256 resourcesConsumed, uint256 essenceGenerated, Attributes newAttributes);
    event NFTMerged(uint256 indexed primaryTokenId, uint256 indexed secondaryTokenId, address indexed merger);
    event GrowthDelegateSet(uint256 indexed tokenId, address indexed delegatee);
    event EvolutionPermissionSet(uint256 indexed tokenId, address indexed permissionedAddress);
    event ParametersUpdated(EvolutionParameters params);
    event AdminFeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyNFTOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "SymbioticGrowthVault: Caller is not owner nor approved");
        _;
    }

    modifier onlyVaultManager(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        address delegatee = _growthDelegates[tokenId];
        require(msg.sender == owner || msg.sender == delegatee, "SymbioticGrowthVault: Caller is not owner or delegate");
        _;
    }

    modifier onlyEvolutionTriggerAllowed(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        address permissioned = _evolutionPermissions[tokenId];
        require(msg.sender == owner || msg.sender == permissioned, "SymbioticGrowthVault: Caller not allowed to trigger evolution");
        _;
    }

    // --- Constructor ---

    constructor(address _resourceTokenAddress, address _evolutionEssenceAddress, string memory baseURI)
        ERC721("SymbioticGrowthVault", "EVOGEM")
        Ownable(msg.sender) // Sets the deployer as the initial owner
        Pausable()
        ReentrancyGuard()
    {
        resourceToken = IERC20(_resourceTokenAddress);
        evolutionEssenceToken = IERC20(_evolutionEssenceAddress);
        _baseTokenURI = baseURI;

        // Set initial default evolution parameters
        evolutionParameters = EvolutionParameters({
            tokensPerGrowthPoint: 1 ether, // Example: 1 ResourceToken per point (scaled)
            pointsPerLevel: 100,           // Example: 100 points to increase a core attribute level by 1
            essencePerPoint: 10**15,       // Example: 0.001 EvolutionEssence per point consumed (scaled)
            resourceConsumptionRate: 100,  // Example: 1% of vault resources consumed on evolution (scaled by 10000) -> should be scaled by 10000 for percentage
            adminFeeRate: 100             // Example: 1% of consumed resources go to admin (scaled by 10000)
        });
        evolutionParameters.resourceConsumptionRate = 100; // 1% scaled by 10000
        evolutionParameters.adminFeeRate = 100; // 1% scaled by 10000

         emit ParametersUpdated(evolutionParameters);
    }

    // --- Admin Functions ---

    /// @notice Allows the owner to update the parameters governing growth and evolution.
    /// @param _tokensPerGrowthPoint The number of resource tokens equivalent to one growth point (scaled by 1e18).
    /// @param _pointsPerLevel The number of growth points required to increase one attribute level.
    /// @param _essencePerPoint The amount of evolution essence generated per growth point consumed (scaled by 1e18).
    /// @param _resourceConsumptionRate The percentage of vault resources consumed during evolution (scaled by 10000, e.g., 100 = 1%).
    /// @param _adminFeeRate The percentage of consumed resources sent to the admin (scaled by 10000, e.g., 100 = 1%).
    function setEvolutionParameters(
        uint256 _tokensPerGrowthPoint,
        uint256 _pointsPerLevel,
        uint256 _essencePerPoint,
        uint256 _resourceConsumptionRate,
        uint256 _adminFeeRate
    ) public onlyOwner {
        require(_tokensPerGrowthPoint > 0, "SymbioticGrowthVault: tokensPerGrowthPoint must be positive");
        require(_pointsPerLevel > 0, "SymbioticGrowthVault: pointsPerLevel must be positive");
         require(_resourceConsumptionRate <= 10000, "SymbioticGrowthVault: resourceConsumptionRate exceeds 100%");
         require(_adminFeeRate <= 10000, "SymbioticGrowthVault: adminFeeRate exceeds 100%");
         require(_adminFeeRate <= _resourceConsumptionRate, "SymbioticGrowthVault: adminFeeRate cannot exceed consumption rate");


        evolutionParameters = EvolutionParameters({
            tokensPerGrowthPoint: _tokensPerGrowthPoint,
            pointsPerLevel: _pointsPerLevel,
            essencePerPoint: _essencePerPoint,
            resourceConsumptionRate: _resourceConsumptionRate,
            adminFeeRate: _adminFeeRate
        });
        emit ParametersUpdated(evolutionParameters);
    }

    /// @notice Allows the owner to set the base URI for NFT metadata.
    /// @param baseURI The new base URI string.
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

     /// @notice Allows the owner to withdraw collected admin fees from this contract.
    /// @param _tokenAddress The address of the token to withdraw (should primarily be the resource token).
    /// @param _recipient The address to send the withdrawn tokens to.
    function withdrawAdminFees(address _tokenAddress, address _recipient) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "SymbioticGrowthVault: No balance to withdraw");
        require(_recipient != address(0), "SymbioticGrowthVault: Cannot withdraw to zero address");

        token.transfer(_recipient, balance);
        emit AdminFeesWithdrawn(_tokenAddress, _recipient, balance);
    }

    /// @notice Returns the address of the Resource Token used by this contract.
    function getResourceTokenAddress() public view returns (address) {
        return address(resourceToken);
    }

    /// @notice Returns the address of the Evolution Essence Token used by this contract.
    function getEvolutionEssenceAddress() public view returns (address) {
        return address(evolutionEssenceToken);
    }


    // --- Pausable Overrides ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- ERC721 Overrides & Extensions ---

    /// @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /// @dev See {ERC721-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-tokenURI}. This implementation dynamically generates the URI
    /// based on the NFT's current attributes.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        NFTGrowthState storage state = _growthStates[tokenId];

        // In a real application, this would build a JSON string or point to an API
        // that generates the JSON based on the state variables (level, power, etc.).
        // For demonstration, we just append some key attributes to the base URI.

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // Or return a default structure indicating missing URI
        }

        // Append token ID and attributes (simplified)
        string memory dynamicPart = string(abi.encodePacked(
            tokenId.toString(),
            "/level/", state.attributes.level.toString(),
            "/power/", state.attributes.power.toString(),
            "/defense/", state.attributes.defense.toString(),
            "/appearance/", state.attributes.appearanceKey // Use the appearance key
        ));


        if (bytes(base).length > 0 && bytes(dynamicPart).length > 0) {
            // Add a separator if base URI doesn't end with '/'
             if (bytes(base)[bytes(base).length - 1] != bytes("/") [0] ) {
                 return string(abi.encodePacked(base, "/", dynamicPart));
             } else {
                 return string(abi.encodePacked(base, dynamicPart));
             }
        }
         return base; // Should not happen if base is non-empty
    }


    // --- NFT Creation & Core Vault Management ---

    /// @notice Mints a new Symbiotic NFT to the specified address and initializes its growth vault.
    /// @param to The address to mint the NFT to.
    /// @return The ID of the newly minted NFT.
    function mintNFT(address to) public whenNotPaused returns (uint256) {
        require(to != address(0), "SymbioticGrowthVault: mint to the zero address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        // Initialize growth state
        _growthStates[newTokenId] = NFTGrowthState({
            resourceBalance: 0,
            lastGrowthUpdateTime: block.timestamp,
            currentGrowthPoints: 0,
            attributes: Attributes({
                level: 1, // Start at level 1
                power: 1,
                defense: 1,
                appearanceKey: "seed-001" // Initial appearance
            })
        });

        emit NFTMinted(to, newTokenId);
        return newTokenId;
    }

    /// @notice Deposits ResourceToken into the vault associated with an NFT.
    /// @dev The caller must approve this contract to spend the tokens first.
    /// @param tokenId The ID of the NFT.
    /// @param amount The amount of ResourceToken to deposit.
    function depositResource(uint256 tokenId, uint256 amount) public whenNotPaused onlyVaultManager(tokenId) nonReentrant {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        require(amount > 0, "SymbioticGrowthVault: Deposit amount must be greater than 0");

        // Harvest pending growth points before changing balance
        _harvestGrowthPoints(tokenId);

        // Transfer resources into the contract's balance for the vault
        resourceToken.transferFrom(msg.sender, address(this), amount);

        _growthStates[tokenId].resourceBalance += amount;
        _growthStates[tokenId].lastGrowthUpdateTime = block.timestamp; // Update time on deposit

        emit ResourceDeposited(tokenId, msg.sender, amount, _growthStates[tokenId].resourceBalance);
    }

    /// @notice Withdraws ResourceToken from the vault associated with an NFT.
    /// @dev Only the owner or the designated growth delegate can withdraw.
    /// @param tokenId The ID of the NFT.
    /// @param amount The amount of ResourceToken to withdraw.
    function withdrawResource(uint256 tokenId, uint256 amount) public whenNotPaused onlyVaultManager(tokenId) nonReentrant {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        NFTGrowthState storage state = _growthStates[tokenId];
        require(amount > 0, "SymbioticGrowthVault: Withdraw amount must be greater than 0");
        require(state.resourceBalance >= amount, "SymbioticGrowthVault: Insufficient resources in vault");

         // Harvest pending growth points before changing balance
        _harvestGrowthPoints(tokenId);

        state.resourceBalance -= amount;
         state.lastGrowthUpdateTime = block.timestamp; // Update time on withdrawal


        // Transfer resources out of the contract's balance to the caller
        resourceToken.transfer(msg.sender, amount);

        emit ResourceWithdrawn(tokenId, msg.sender, amount, state.resourceBalance);
    }

    /// @notice Returns the current resource balance in the vault for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The amount of ResourceToken in the vault.
    function getVaultBalance(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        return _growthStates[tokenId].resourceBalance;
    }


    // --- Growth & Evolution ---

    /// @dev Internal helper to calculate and add pending growth points to the current total.
    /// Updates lastGrowthUpdateTime. Should be called before any action that affects
    /// the balance or consumes points (deposit, withdraw, evolution, merge).
    function _harvestGrowthPoints(uint256 tokenId) internal {
        NFTGrowthState storage state = _growthStates[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - state.lastGrowthUpdateTime;

        if (state.resourceBalance > 0 && timeElapsed > 0 && evolutionParameters.tokensPerGrowthPoint > 0) {
            // Simplistic linear growth based on balance and time
            // A more complex model could involve decay, diminishing returns, etc.
            uint256 pendingPoints = (state.resourceBalance * timeElapsed) / evolutionParameters.tokensPerGrowthPoint;

            state.currentGrowthPoints += pendingPoints;
            state.lastGrowthUpdateTime = currentTime;

            emit GrowthPointsHarvested(tokenId, pendingPoints, state.currentGrowthPoints);
        } else {
             // If no balance or no time elapsed, just update the time without adding points
             state.lastGrowthUpdateTime = currentTime;
        }
    }

    /// @notice Calculates the theoretical growth points accrued since the last harvest/update.
    /// @dev Does NOT modify contract state. Call `_harvestGrowthPoints` to actually add points.
    /// @param tokenId The ID of the NFT.
    /// @return The number of growth points that would be harvested.
    function calculatePendingGrowthPoints(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
         NFTGrowthState storage state = _growthStates[tokenId];
         uint256 currentTime = block.timestamp;
         uint256 timeElapsed = currentTime - state.lastGrowthUpdateTime;

         if (state.resourceBalance > 0 && timeElapsed > 0 && evolutionParameters.tokensPerGrowthPoint > 0) {
             return (state.resourceBalance * timeElapsed) / evolutionParameters.tokensPerGrowthPoint;
         }
         return 0;
    }


    /// @notice Returns the current growth status of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return currentGrowthPoints The total accumulated growth points.
    /// @return lastUpdateTime The timestamp of the last state update.
    /// @return vaultBalance The current resource token balance.
    function getGrowthStatus(uint256 tokenId) public view returns (uint256 currentGrowthPoints, uint256 lastUpdateTime, uint256 vaultBalance) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        NFTGrowthState storage state = _growthStates[tokenId];
        return (state.currentGrowthPoints, state.lastGrowthUpdateTime, state.resourceBalance);
    }

    /// @notice Returns the current dynamic attributes of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return level The current level.
    /// @return power The current power attribute.
    /// @return defense The current defense attribute.
    /// @return appearanceKey The key for off-chain appearance data.
    function getNFTAttributes(uint256 tokenId) public view returns (uint256 level, uint256 power, uint256 defense, string memory appearanceKey) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        Attributes storage attr = _growthStates[tokenId].attributes;
        return (attr.level, attr.power, attr.defense, attr.appearanceKey);
    }

    /// @notice Allows the owner or a permissioned address to trigger the NFT's evolution.
    /// This consumes growth points and potentially resources, and updates attributes.
    /// @param tokenId The ID of the NFT to evolve.
    function triggerEvolution(uint256 tokenId) public whenNotPaused onlyEvolutionTriggerAllowed(tokenId) nonReentrant {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        NFTGrowthState storage state = _growthStates[tokenId];
        EvolutionParameters memory params = evolutionParameters;

        // Harvest any pending growth points first
        _harvestGrowthPoints(tokenId);

        uint256 pointsAvailable = state.currentGrowthPoints;
        require(pointsAvailable >= params.pointsPerLevel, "SymbioticGrowthVault: Not enough growth points to evolve");

        // Calculate consumption and generation
        uint256 pointsToConsume = pointsAvailable; // Could allow partial evolution, but let's consume all available for simplicity
        uint256 resourcesToConsume = (state.resourceBalance * params.resourceConsumptionRate) / 10000; // Apply rate
        uint256 adminFeeAmount = (resourcesToConsume * params.adminFeeRate) / 10000; // Calculate admin cut
        uint256 resourcesBurnedForGrowth = resourcesToConsume - adminFeeAmount; // Rest is 'burned' for growth
        uint256 essenceGenerated = (pointsToConsume * params.essencePerPoint) / 1 ether; // Scale essence generation

        // Update state based on consumption
        state.currentGrowthPoints = 0; // Consume all available points (or partial if implemented)
        state.resourceBalance -= resourcesToConsume;

        // Update attributes based on points consumed (simplified: level up based on points / pointsPerLevel)
        uint256 levelsGained = pointsToConsume / params.pointsPerLevel;
        state.attributes.level += levelsGained;
        state.attributes.power += levelsGained * 2; // Example attribute scaling
        state.attributes.defense += levelsGained;   // Example attribute scaling

        // Update appearance key based on level (simplified)
        state.attributes.appearanceKey = string(abi.encodePacked("evolved-", state.attributes.level.toString()));

        // Transfer resources to admin (if any)
        if (adminFeeAmount > 0) {
            resourceToken.transfer(owner(), adminFeeAmount);
        }

        // Mint or transfer essence tokens (if evolution essence token is set)
        if (address(evolutionEssenceToken) != address(0) && essenceGenerated > 0) {
             evolutionEssenceToken.transfer(ownerOf(tokenId), essenceGenerated); // Send essence to NFT owner
        }

        emit EvolutionTriggered(
            tokenId,
            msg.sender,
            pointsToConsume,
            resourcesToConsume,
            essenceGenerated,
            state.attributes
        );
    }

    // --- Advanced Mechanics ---

    /// @notice Merges two Symbiotic NFTs. Resources and attributes from the secondary are combined into the primary.
    /// The secondary NFT is burned. Requires caller to own both NFTs.
    /// @param primaryTokenId The ID of the NFT that will remain and absorb the secondary.
    /// @param secondaryTokenId The ID of the NFT that will be burned.
    function mergeNFTs(uint256 primaryTokenId, uint256 secondaryTokenId) public whenNotPaused nonReentrant {
        address caller = msg.sender;
        require(caller == ownerOf(primaryTokenId), "SymbioticGrowthVault: Caller must own primary NFT");
        require(caller == ownerOf(secondaryTokenId), "SymbioticGrowthVault: Caller must own secondary NFT");
        require(primaryTokenId != secondaryTokenId, "SymbioticGrowthVault: Cannot merge an NFT with itself");

        // Harvest growth points for both before merging
        _harvestGrowthPoints(primaryTokenId);
        _harvestGrowthPoints(secondaryTokenId);

        NFTGrowthState storage primaryState = _growthStates[primaryTokenId];
        NFTGrowthState storage secondaryState = _growthStates[secondaryTokenId];

        // Transfer resources from secondary vault to primary vault
        primaryState.resourceBalance += secondaryState.resourceBalance;

        // Combine growth points
        primaryState.currentGrowthPoints += secondaryState.currentGrowthPoints;

        // Combine attributes (Example: Sum attributes, average level/power, etc.)
        // This is a simplified example. Complex logic might be needed here.
        primaryState.attributes.level = primaryState.attributes.level > secondaryState.attributes.level ? primaryState.attributes.level : secondaryState.attributes.level; // Keep higher level
        primaryState.attributes.power += secondaryState.attributes.power; // Sum power
        primaryState.attributes.defense += secondaryState.attributes.defense; // Sum defense
        // Appearance key logic for merge is complex, leave it unchanged for primary or set a new one based on combined state
         // primaryState.attributes.appearanceKey = "merged-form"; // Example

        // Clear the secondary NFT's state
        delete _growthStates[secondaryTokenId];
        delete _growthDelegates[secondaryTokenId];
        delete _evolutionPermissions[secondaryTokenId];


        // Burn the secondary NFT
        _burn(secondaryTokenId);

        emit NFTMerged(primaryTokenId, secondaryTokenId, caller);
    }

    /// @notice Sets an address that can manage (deposit/withdraw) resources for a specific NFT's vault.
    /// Does NOT grant ownership or evolution rights.
    /// @param tokenId The ID of the NFT.
    /// @param delegatee The address to delegate management to. Use address(0) to revoke.
    function delegateGrowthManagement(uint256 tokenId, address delegatee) public whenNotPaused onlyNFTOwner(tokenId) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
         require(delegatee != ownerOf(tokenId), "SymbioticGrowthVault: Cannot delegate to self");
        _growthDelegates[tokenId] = delegatee;
        emit GrowthDelegateSet(tokenId, delegatee);
    }

    /// @notice Revokes the current growth delegate for an NFT's vault.
    /// @param tokenId The ID of the NFT.
    function revokeGrowthManagement(uint256 tokenId) public whenNotPaused onlyNFTOwner(tokenId) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        _growthDelegates[tokenId] = address(0);
        emit GrowthDelegateSet(tokenId, address(0));
    }

     /// @notice Checks if an NFT has a growth delegate set.
    /// @param tokenId The ID of the NFT.
    /// @return True if a delegate is set, false otherwise.
    function hasGrowthDelegate(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        return _growthDelegates[tokenId] != address(0);
    }

     /// @notice Gets the current growth delegate for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The delegate address, or address(0) if none is set.
    function getGrowthDelegate(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        return _growthDelegates[tokenId];
    }


    /// @notice Grants a specific address permission to trigger evolution for an NFT.
    /// Does NOT grant ownership or vault management rights. Only one address can have permission at a time.
    /// @param tokenId The ID of the NFT.
    /// @param permissionedAddress The address to grant permission to. Use address(0) to revoke.
    function grantEvolutionPermission(uint256 tokenId, address permissionedAddress) public whenNotPaused onlyNFTOwner(tokenId) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        require(permissionedAddress != ownerOf(tokenId), "SymbioticGrowthVault: Cannot grant permission to self");
        _evolutionPermissions[tokenId] = permissionedAddress;
        emit EvolutionPermissionSet(tokenId, permissionedAddress);
    }

    /// @notice Revokes the current evolution permission for an NFT.
    /// @param tokenId The ID of the NFT.
    function revokeEvolutionPermission(uint256 tokenId) public whenNotPaused onlyNFTOwner(tokenId) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
         _evolutionPermissions[tokenId] = address(0);
        emit EvolutionPermissionSet(tokenId, address(0));
    }

     /// @notice Checks if a specific address has evolution permission for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @param potentialGranter The address to check.
    /// @return True if the address has permission, false otherwise.
    function hasEvolutionPermission(uint256 tokenId, address potentialGranter) public view returns (bool) {
        require(_exists(tokenId), "SymbioticGrowthVault: NFT does not exist");
        return _evolutionPermissions[tokenId] == potentialGranter && potentialGranter != address(0);
    }

    // --- Internal ERC721 Hooks (for state consistency during transfers/burns) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When an NFT is transferred, clear delegates and permissions associated with it.
        // This prevents lingering access rights with the old owner or for the old owner.
        if (from != address(0)) { // Not a mint
            _growthDelegates[tokenId] = address(0);
             _evolutionPermissions[tokenId] = address(0);
            emit GrowthDelegateSet(tokenId, address(0)); // Explicitly emit revoke events
             emit EvolutionPermissionSet(tokenId, address(0));
        }
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        // When an NFT is burned, clean up its associated state
        delete _growthStates[tokenId];
         delete _growthDelegates[tokenId];
         delete _evolutionPermissions[tokenId];
    }
}
```