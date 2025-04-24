Okay, let's design a complex, multi-faceted vault contract incorporating ideas around dynamic yield, asset fusion, variable parameters, and tiered access/mechanisms.

We'll call it `QuantumFusionVault`. The core idea is a vault where users deposit ERC-20 and ERC-721 tokens. These deposited assets generate a form of "Quantum Energy" (represented as an internal balance), but the generation rate is dynamic, influenced by vault parameters, user asset combinations, and potentially external factors (simulated by admin updates). Users can then use this energy, along with deposited assets, to "fuse" and create unique "Fusion Shard" NFTs.

This involves:
1.  **Multi-Asset Deposits:** Handling both ERC-20 and ERC-721 tokens.
2.  **Dynamic Yield:** Energy generation based on multiple factors (base rate, fluctuation, asset combination bonuses, time).
3.  **Asset Locking:** Deposits are locked for a period.
4.  **Asset Fusion:** Burning energy and consuming deposited assets (potentially locking them permanently or transforming them) to mint a new type of NFT (`FusionShard`).
5.  **Parameter Control:** Vault parameters (rates, bonuses, costs, allowed assets) are adjustable, potentially via a governance mechanism (simplified to `onlyOwner` for this example, but structure allows for upgrade).
6.  **Tiered System:** Different asset combinations could lead to different fusion results or yield bonuses.

**Outline & Function Summary**

**Contract Name:** `QuantumFusionVault`

**Core Concept:** A vault for depositing ERC-20 and ERC-721 assets to generate dynamic "Quantum Energy". Users can then use energy and deposited assets to "fuse" and create "Fusion Shard" NFTs.

**Key Features:**
*   Accepts deposits of specified ERC-20 and ERC-721 tokens.
*   Deposited assets are locked for a configurable duration.
*   Generates "Quantum Energy" internally based on time, base rate, a global "Quantum Fluctuation" parameter, and specific asset combination bonuses.
*   Allows users to claim accumulated Quantum Energy.
*   Enables a "Fusion" process where users spend Quantum Energy and burn/consume specific deposited assets to mint a unique `FusionShard` NFT.
*   Admin/Owner control over vault parameters (allowed assets, rates, bonuses, fusion costs, lock times, fluctuation parameter).
*   Pause functionality for emergencies.

**Interfaces Used (Assumed/Simplified):**
*   `IERC20`: Standard ERC-20 interface for interacting with deposit tokens.
*   `IERC721`: Standard ERC-721 interface for interacting with deposit NFTs.
*   `IERC721Receiver`: Standard interface for receiving ERC-721s (implemented by the vault).
*   `IFusionShard`: Custom interface for the separate `FusionShard` NFT contract the vault interacts with (minting/managing).

**State Variables:**
*   Mappings to track user balances for each ERC-20 and deposited ERC-721s.
*   Mappings to track deposit times and lock expiration for assets.
*   Mapping for user's accumulated/claimed Quantum Energy balance.
*   Sets/Mappings to track allowed ERC-20 tokens and ERC-721 collections.
*   Global vault parameters (base energy rate, quantum fluctuation).
*   Mappings for asset combination yield bonuses and fusion costs.
*   State related to the `FusionShard` contract address.
*   Ownership and Pause state.

**Events:**
*   `ERC20Deposited`, `ERC20Withdrawal`
*   `ERC721Deposited`, `ERC721Withdrawal`
*   `EnergyClaimed`
*   `FusionPerformed`
*   `ParameterUpdated` (generic for various settings)
*   `Paused`, `Unpaused`

**Functions (20+):**

1.  `constructor(address initialOwner, address fusionShardContractAddress)`: Sets up the owner and the address of the `FusionShard` NFT contract.
2.  `pause()`: Pauses contract operations (deposits, withdrawals, claims, fusion). (Owner only)
3.  `unpause()`: Unpauses contract operations. (Owner only)
4.  `addAllowedERC20Token(address tokenAddress)`: Adds an ERC-20 token to the list of accepted deposit tokens. (Owner only)
5.  `removeAllowedERC20Token(address tokenAddress)`: Removes an ERC-20 token from the allowed list. (Owner only)
6.  `addAllowedERC721Collection(address collectionAddress)`: Adds an ERC-721 collection to the list of accepted deposit NFTs. (Owner only)
7.  `removeAllowedERC721Collection(address collectionAddress)`: Removes an ERC-721 collection from the allowed list. (Owner only)
8.  `setBaseEnergyRate(uint256 rate)`: Sets the base rate of Quantum Energy generation (per unit time/asset). (Owner only)
9.  `updateQuantumFluctuation(uint256 fluctuation)`: Sets the global multiplier for energy generation, simulating external factors. (Owner only)
10. `setAssetLockDuration(uint256 duration)`: Sets the minimum lock duration for deposited assets in seconds. (Owner only)
11. `setFusionCombinationBonus(address erc20Address, address erc721Address, uint256 bonusPercentage)`: Sets an energy generation bonus multiplier for users holding a specific combination of deposited ERC-20 and ERC-721. (Owner only)
12. `setFusionCost(address[] erc20Requirements, uint256[] erc20Amounts, address[] erc721Requirements, uint256 energyCost)`: Configures the requirements (assets and energy) for performing a fusion. (Owner only)
13. `depositERC20(address tokenAddress, uint256 amount)`: Deposits a specified amount of an allowed ERC-20 token into the vault.
14. `withdrawERC20(address tokenAddress, uint256 amount)`: Withdraws a specified amount of an ERC-20 token. Checks lock duration.
15. `depositERC721(address collectionAddress, uint256 tokenId)`: Deposits a specific NFT from an allowed collection.
16. `withdrawERC721(address collectionAddress, uint256 tokenId)`: Withdraws a specific deposited NFT. Checks lock duration.
17. `calculateQuantumEnergy(address user)`: (View) Calculates the pending Quantum Energy for a user based on their deposited assets, time, and current parameters.
18. `claimQuantumEnergy()`: Claims the calculated pending Quantum Energy, adding it to the user's claimable balance and resetting their energy calculation timer.
19. `performFusion()`: Attempts to perform a fusion. Checks user's energy balance and deposited assets against current fusion costs. If successful, burns energy/assets and triggers `FusionShard` minting.
20. `withdrawFusionShard(uint256 shardId)`: Allows a user to withdraw a `FusionShard` NFT they own from the vault (assuming the vault holds minted shards before withdrawal). *Self-correction: The Vault should just *mint* to the user directly or hold and allow claims. Minting to user is standard for ERC721Factories. Let's make this `getUserFusionShards` (view) and the withdrawal is handled by the *Shard contract* if it allows transfer, or implicitly by user owning it upon mint.* -> Let's replace this with more relevant views.
21. `getUserERC20Deposit(address user, address tokenAddress)`: (View) Gets the amount of a specific ERC-20 token deposited by a user.
22. `getUserERC721Deposits(address user, address collectionAddress)`: (View) Gets the list of token IDs from a specific ERC-721 collection deposited by a user.
23. `getAssetLockExpiration(address user, address tokenAddress, uint256 tokenIdOrZeroForERC20)`: (View) Gets the lock expiration timestamp for a specific deposited asset (ERC-20 or ERC-721).
24. `getUserQuantumEnergyBalance(address user)`: (View) Gets the user's currently claimable Quantum Energy balance.
25. `getAllowedERC20Tokens()`: (View) Gets the list of allowed ERC-20 token addresses.
26. `getAllowedERC721Collections()`: (View) Gets the list of allowed ERC-721 collection addresses.
27. `getQuantumParameters()`: (View) Gets the current base energy rate, quantum fluctuation, and asset lock duration.
28. `getFusionRequirements()`: (View) Gets the current asset and energy costs required for fusion.
29. `getFusionCombinationBonus(address erc20Address, address erc721Address)`: (View) Gets the current fusion combination bonus for a specific pair.

This structure gives us a rich interaction model and exceeds the 20 function requirement.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// Contract Name: QuantumFusionVault
// Core Concept: A vault for depositing ERC-20 and ERC-721 assets to generate dynamic "Quantum Energy".
//               Users can then use energy and deposited assets to "fuse" and create "Fusion Shard" NFTs.
// Key Features:
// - Multi-asset deposits (ERC-20, ERC-721)
// - Dynamic yield generation ("Quantum Energy") based on time, base rate, fluctuation parameter, and asset combination bonuses.
// - Configurable asset lock durations.
// - "Fusion" mechanism: consume energy + deposited assets to mint a FusionShard NFT.
// - Owner-controlled parameters (allowed assets, rates, bonuses, costs, lock times, fluctuation).
// - Pause functionality.
// Interfaces: IERC20, IERC721, IERC721Receiver, IFusionShard (custom)
// State Variables: User balances (ERC20, ERC721 IDs), deposit timestamps, energy balances,
//                  allowed assets, vault parameters (rates, bonuses, costs, lock duration, fluctuation),
//                  FusionShard contract address.
// Events: Deposit, Withdrawal, Energy Claimed, Fusion, Parameter Updates, Pause/Unpause.
// Functions: 29 functions covering deposit/withdraw (ERC20/ERC721), energy calculation/claiming,
//            fusion execution, parameter setting (admin), and view functions for state queries.

// --- Function Summary ---
// 1. constructor: Initialize vault owner and FusionShard contract.
// 2. pause: Pause operations (Owner).
// 3. unpause: Unpause operations (Owner).
// 4. addAllowedERC20Token: Add allowed ERC20 (Owner).
// 5. removeAllowedERC20Token: Remove allowed ERC20 (Owner).
// 6. addAllowedERC721Collection: Add allowed ERC721 collection (Owner).
// 7. removeAllowedERC721Collection: Remove allowed ERC721 collection (Owner).
// 8. setBaseEnergyRate: Set base energy rate (Owner).
// 9. updateQuantumFluctuation: Set global energy fluctuation multiplier (Owner).
// 10. setAssetLockDuration: Set minimum deposit lock duration (Owner).
// 11. setFusionCombinationBonus: Set energy bonus for specific asset combos (Owner).
// 12. setFusionCost: Set requirements (assets, energy) for fusion (Owner).
// 13. depositERC20: Deposit ERC20 tokens.
// 14. withdrawERC20: Withdraw ERC20 tokens (checks lock).
// 15. depositERC721: Deposit ERC721 NFT.
// 16. withdrawERC721: Withdraw ERC721 NFT (checks lock).
// 17. calculateQuantumEnergy: (View) Calculate pending energy for user.
// 18. claimQuantumEnergy: Claim pending energy.
// 19. performFusion: Execute fusion process (burns assets/energy, mints FusionShard).
// 20. getUserERC20Deposit: (View) Get user's ERC20 deposit amount.
// 21. getUserERC721Deposits: (View) Get user's deposited ERC721 IDs for a collection.
// 22. getAssetLockExpiration: (View) Get lock expiration timestamp for an asset.
// 23. getUserQuantumEnergyBalance: (View) Get user's claimable energy balance.
// 24. getAllowedERC20Tokens: (View) Get list of allowed ERC20s.
// 25. getAllowedERC721Collections: (View) Get list of allowed ERC721 collections.
// 26. getQuantumParameters: (View) Get base rate, fluctuation, lock duration.
// 27. getFusionRequirements: (View) Get current fusion requirements.
// 28. getFusionCombinationBonus: (View) Get bonus for a specific combo.
// 29. onERC721Received: ERC721 receive hook implementation.

contract QuantumFusionVault is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;
    using Address for address;

    // --- Interfaces ---

    // Represents the hypothetical Fusion Shard NFT contract controlled by the vault
    interface IFusionShard {
        function mint(address to, uint256 shardId, bytes memory data) external;
        // Potentially other functions like burn, get attributes by ID, etc.
        // For this example, we just need mint. Assume shardId generation logic is internal to the vault or deterministic.
    }

    // --- State Variables ---

    // User Balances and Deposits
    mapping(address => mapping(address => uint256)) private userERC20Balances; // user => token => amount
    mapping(address => mapping(address => uint256[])) private userERC721Deposits; // user => collection => list of tokenIds
    mapping(uint256 => address) private erc721TokenOwner; // tokenId => owner (within the vault context)
    mapping(address => mapping(address => mapping(uint256 => uint256))) private assetDepositTimestamps; // user => token/collection => id (0 for ERC20) => timestamp

    // Quantum Energy State
    mapping(address => uint256) private userQuantumEnergy; // user => accumulated energy balance
    mapping(address => uint256) private userLastEnergyClaimTime; // user => timestamp of last energy claim/deposit

    // Allowed Assets
    mapping(address => bool) private allowedERC20Tokens;
    address[] private allowedERC20TokenList; // For easy retrieval
    mapping(address => bool) private allowedERC721Collections;
    address[] private allowedERC721CollectionList; // For easy retrieval

    // Vault Parameters
    uint256 public baseEnergyRate; // Base energy generated per unit time per "standardized unit" of asset (e.g., per second per $1000 TVL contribution)
    uint256 public quantumFluctuation; // Global multiplier (e.g., 10000 for 1x, 15000 for 1.5x)
    uint256 public assetLockDuration; // Minimum time assets must stay in the vault (in seconds)

    // Fusion Mechanism Parameters
    // Bonus energy rate for holding specific asset combinations
    mapping(address => mapping(address => uint256)) private fusionCombinationBonus; // erc20 => erc721 collection => bonus percentage (e.g., 500 for 5%)

    // Fusion Cost Requirements (Example: Need X amount of Token A and Y amount of Token B, and Z energy)
    // This is simplified; a real system might have multiple fusion recipes.
    // For this example, we define ONE global fusion recipe.
    address[] public fusionERC20Requirements;
    uint256[] public fusionERC20Amounts;
    address[] public fusionERC721Requirements; // Collections required
    uint256 public fusionEnergyCost;
    // Note: Specific ERC721 *token IDs* might be required in a more complex version. Here, we require *an* NFT from the collection.

    // Fusion Shard Contract
    IFusionShard public fusionShardContract;
    uint256 private nextShardId = 1;

    // --- Events ---

    event ERC20Deposited(address indexed user, address indexed token, uint256 amount, uint256 lockedUntil);
    event ERC20Withdrawal(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed collection, uint256 indexed tokenId, uint256 lockedUntil);
    event ERC721Withdrawal(address indexed user, address indexed collection, uint256 indexed tokenId);
    event EnergyClaimed(address indexed user, uint256 amount);
    event FusionPerformed(address indexed user, uint256 indexed shardId, uint256 energySpent);
    event ParameterUpdated(string parameterName, uint256 newValue); // Generic for simple value updates
    event ParameterUpdatedArray(string parameterName); // Generic for array/mapping updates

    // --- Constructor ---

    constructor(address initialOwner, address fusionShardContractAddress) Ownable(initialOwner) {
        require(fusionShardContractAddress != address(0), "FusionShard contract address cannot be zero");
        fusionShardContract = IFusionShard(fusionShardContractAddress);

        // Set initial parameters (can be 0, must be set by owner later)
        baseEnergyRate = 0; // e.g., 1e12 (scaled integer)
        quantumFluctuation = 10000; // 10000 = 1x multiplier
        assetLockDuration = 0; // e.g., 60 * 60 * 24 * 7 (7 days)
        fusionEnergyCost = 0;
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Admin Functions (Parameter Setting) ---

    /// @notice Adds an ERC-20 token to the list of allowed deposit tokens.
    /// @param tokenAddress The address of the ERC-20 token.
    function addAllowedERC20Token(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Zero address not allowed");
        require(!allowedERC20Tokens[tokenAddress], "Token already allowed");
        allowedERC20Tokens[tokenAddress] = true;
        allowedERC20TokenList.push(tokenAddress);
        emit ParameterUpdatedArray("AllowedERC20Tokens");
    }

    /// @notice Removes an ERC-20 token from the list of allowed deposit tokens.
    /// @param tokenAddress The address of the ERC-20 token.
    function removeAllowedERC20Token(address tokenAddress) public onlyOwner {
        require(allowedERC20Tokens[tokenAddress], "Token not allowed");
        allowedERC20Tokens[tokenAddress] = false;
        // Simple removal: find and swap with last, then pop. O(N) but fine for admin function.
        for (uint i = 0; i < allowedERC20TokenList.length; i++) {
            if (allowedERC20TokenList[i] == tokenAddress) {
                allowedERC20TokenList[i] = allowedERC20TokenList[allowedERC20TokenList.length - 1];
                allowedERC20TokenList.pop();
                break;
            }
        }
        emit ParameterUpdatedArray("AllowedERC20Tokens");
    }

    /// @notice Adds an ERC-721 collection to the list of allowed deposit collections.
    /// @param collectionAddress The address of the ERC-721 collection.
    function addAllowedERC721Collection(address collectionAddress) public onlyOwner {
        require(collectionAddress != address(0), "Zero address not allowed");
        require(!allowedERC721Collections[collectionAddress], "Collection already allowed");
        allowedERC721Collections[collectionAddress] = true;
        allowedERC721CollectionList.push(collectionAddress);
        emit ParameterUpdatedArray("AllowedERC721Collections");
    }

    /// @notice Removes an ERC-721 collection from the list of allowed deposit collections.
    /// @param collectionAddress The address of the ERC-721 collection.
    function removeAllowedERC721Collection(address collectionAddress) public onlyOwner {
        require(allowedERC721Collections[collectionAddress], "Collection not allowed");
        allowedERC721Collections[collectionAddress] = false;
        // Simple removal: find and swap with last, then pop. O(N) but fine for admin function.
        for (uint i = 0; i < allowedERC721CollectionList.length; i++) {
            if (allowedERC721CollectionList[i] == collectionAddress) {
                allowedERC721CollectionList[i] = allowedERC721CollectionList[allowedERC721CollectionList.length - 1];
                allowedERC721CollectionList.pop();
                break;
            }
        }
        emit ParameterUpdatedArray("AllowedERC721Collections");
    }

    /// @notice Sets the base rate for Quantum Energy generation.
    /// @param rate The new base rate (scaled, e.g., 1e12).
    function setBaseEnergyRate(uint256 rate) public onlyOwner {
        baseEnergyRate = rate;
        emit ParameterUpdated("baseEnergyRate", rate);
    }

    /// @notice Sets the global Quantum Fluctuation multiplier.
    /// @param fluctuation The new multiplier (e.g., 10000 for 1x).
    function updateQuantumFluctuation(uint256 fluctuation) public onlyOwner {
        quantumFluctuation = fluctuation;
        emit ParameterUpdated("quantumFluctuation", fluctuation);
    }

    /// @notice Sets the minimum lock duration for deposited assets.
    /// @param duration The duration in seconds.
    function setAssetLockDuration(uint256 duration) public onlyOwner {
        assetLockDuration = duration;
        emit ParameterUpdated("assetLockDuration", duration);
    }

    /// @notice Sets an energy generation bonus for specific deposited asset combinations.
    /// @param erc20Address The address of the required ERC-20 token.
    /// @param erc721Address The address of the required ERC-721 collection.
    /// @param bonusPercentage The bonus percentage (e.g., 500 for 5%).
    function setFusionCombinationBonus(address erc20Address, address erc721Address, uint256 bonusPercentage) public onlyOwner {
        require(allowedERC20Tokens[erc20Address], "ERC20 not allowed");
        require(allowedERC721Collections[erc721Address], "ERC721 not allowed");
        fusionCombinationBonus[erc20Address][erc721Address] = bonusPercentage;
        // Specific event could be added here if needed
        emit ParameterUpdated("fusionCombinationBonus", bonusPercentage);
    }

     /// @notice Sets the requirements for performing a fusion.
     /// @param erc20Requirements_ Addresses of required ERC-20 tokens.
     /// @param erc20Amounts_ Amounts required for corresponding ERC-20 tokens.
     /// @param erc721Requirements_ Addresses of required ERC-721 collections.
     /// @param energyCost_ The amount of Quantum Energy required.
    function setFusionCost(
        address[] calldata erc20Requirements_,
        uint256[] calldata erc20Amounts_,
        address[] calldata erc721Requirements_,
        uint256 energyCost_
    ) public onlyOwner {
        require(erc20Requirements_.length == erc20Amounts_.length, "ERC20 requirements mismatch");
        // Add more checks: Ensure required tokens/collections are actually allowed deposit types
        for(uint i = 0; i < erc20Requirements_.length; i++) {
             require(allowedERC20Tokens[erc20Requirements_[i]], "Required ERC20 not allowed");
        }
         for(uint i = 0; i < erc721Requirements_.length; i++) {
             require(allowedERC721Collections[erc721Requirements_[i]], "Required ERC721 not allowed");
        }


        fusionERC20Requirements = erc20Requirements_;
        fusionERC20Amounts = erc20Amounts_;
        fusionERC721Requirements = erc721Requirements_;
        fusionEnergyCost = energyCost_;

        emit ParameterUpdatedArray("FusionRequirements");
    }


    // --- Deposit Functions ---

    /// @notice Deposits an allowed ERC-20 token into the vault.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount to deposit.
    function depositERC20(address tokenAddress, uint256 amount) public whenNotPaused {
        require(allowedERC20Tokens[tokenAddress], "ERC20 token not allowed");
        require(amount > 0, "Amount must be greater than 0");

        // Update energy calculation time before depositing
        // This ensures energy is calculated up to this point based on *previous* holdings
        // Any energy generated by the new deposit starts *after* this transaction
        claimQuantumEnergyInternal(msg.sender);

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        userERC20Balances[msg.sender][tokenAddress] = userERC20Balances[msg.sender][tokenAddress].add(amount);
        assetDepositTimestamps[msg.sender][tokenAddress][0] = block.timestamp; // Use 0 for ERC20 "tokenId"

        emit ERC20Deposited(msg.sender, tokenAddress, amount, block.timestamp.add(assetLockDuration));
    }

    /// @notice Deposits an allowed ERC-721 token into the vault.
    /// Requires the user to approve the vault beforehand.
    /// @param collectionAddress The address of the ERC-721 collection.
    /// @param tokenId The ID of the NFT to deposit.
    function depositERC721(address collectionAddress, uint256 tokenId) public whenNotPaused {
        require(allowedERC721Collections[collectionAddress], "ERC721 collection not allowed");
        require(IERC721(collectionAddress).ownerOf(tokenId) == msg.sender, "Caller is not the owner of the NFT");

         // Update energy calculation time before depositing
        claimQuantumEnergyInternal(msg.sender);

        // Transfer the NFT to the vault
        IERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        // Add to user's list of deposited NFTs for this collection
        userERC721Deposits[msg.sender][collectionAddress].push(tokenId);
        erc721TokenOwner[tokenId] = msg.sender; // Track owner within the vault context
        assetDepositTimestamps[msg.sender][collectionAddress][tokenId] = block.timestamp;

        emit ERC721Deposited(msg.sender, collectionAddress, tokenId, block.timestamp.add(assetLockDuration));
    }

    // ERC721Receiver hook
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // We only accept deposits initiated by our depositERC721 function,
        // which already performs checks and updates state.
        // This hook primarily just needs to return the magic value.
        // Adding a basic check to ensure it's from an allowed collection is good practice.
        require(allowedERC721Collections[msg.sender], "Receiving from disallowed ERC721 collection");
        return this.onERC721Received.selector;
    }


    // --- Withdrawal Functions ---

    /// @notice Withdraws an ERC-20 token from the vault. Checks lock duration.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) public whenNotPaused {
        require(allowedERC20Tokens[tokenAddress], "ERC20 token not allowed");
        require(amount > 0, "Amount must be greater than 0");
        require(userERC20Balances[msg.sender][tokenAddress] >= amount, "Insufficient balance in vault");
        require(block.timestamp >= assetDepositTimestamps[msg.sender][tokenAddress][0].add(assetLockDuration), "Assets are locked");

        userERC20Balances[msg.sender][tokenAddress] = userERC20Balances[msg.sender][tokenAddress].sub(amount);

        // If the user withdraws their *entire* balance, reset the timestamp to 0 to ensure
        // future deposits start a new lock period. Otherwise, the timestamp remains the oldest one.
        // More robust: track multiple deposit timestamps if needed, but this is simpler.
        // For this simplified example, just check if balance is zero after withdrawal.
        if (userERC20Balances[msg.sender][tokenAddress] == 0) {
             assetDepositTimestamps[msg.sender][tokenAddress][0] = 0;
        }
        // Note: A real implementation tracking multiple deposits would need to track *which* deposit chunk is being withdrawn.
        // This simplified version assumes LIFO/FIFO or single timestamp per asset type.
        // Using the first deposit timestamp for *all* of that asset type is the simplest lock mechanism.

        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit ERC20Withdrawal(msg.sender, tokenAddress, amount);
    }

    /// @notice Withdraws a deposited ERC-721 NFT from the vault. Checks lock duration.
    /// @param collectionAddress The address of the ERC-721 collection.
    /// @param tokenId The ID of the NFT to withdraw.
    function withdrawERC721(address collectionAddress, uint256 tokenId) public whenNotPaused {
        require(allowedERC721Collections[collectionAddress], "ERC721 collection not allowed");
        require(erc721TokenOwner[tokenId] == msg.sender, "Caller is not the owner of the deposited NFT");
        require(block.timestamp >= assetDepositTimestamps[msg.sender][collectionAddress][tokenId].add(assetLockDuration), "Asset is locked");

        // Find and remove the tokenId from the user's list
        uint256[] storage userNFTs = userERC721Deposits[msg.sender][collectionAddress];
        bool found = false;
        for (uint i = 0; i < userNFTs.length; i++) {
            if (userNFTs[i] == tokenId) {
                userNFTs[i] = userNFTs[userNFTs.length - 1]; // Swap with last
                userNFTs.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "NFT not found in user's deposits");

        delete erc721TokenOwner[tokenId]; // Remove ownership tracking within the vault
        delete assetDepositTimestamps[msg.sender][collectionAddress][tokenId]; // Remove timestamp

        IERC721(collectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ERC721Withdrawal(msg.sender, collectionAddress, tokenId);
    }

    // --- Quantum Energy Functions ---

    /// @notice Calculates the pending Quantum Energy for a user.
    /// Energy is generated based on time since last claim/deposit, base rate, fluctuation,
    /// and combination bonuses for deposited assets.
    /// @param user The address of the user.
    /// @return The calculated pending energy.
    function calculateQuantumEnergy(address user) public view returns (uint256) {
        uint256 lastCalcTime = userLastEnergyClaimTime[user];
        if (lastCalcTime == 0) {
             // If user has no energy claim history, start from their very first deposit time.
             // This requires iterating through all their deposits, which can be gas intensive.
             // Simpler approach for this example: start from contract deployment or last deposit time
             // or just require a first deposit before energy accrues meaningfully.
             // Let's assume energy accrues from their *first* deposit timestamp recorded, or 0 if none.
             // A proper system would track the time of the *first ever* deposit for the user.
             // For this example, we'll use the lastClaimTime, assuming it gets set on first interaction.
             lastCalcTime = userLastEnergyClaimTime[user]; // If never claimed, this is 0
             if (lastCalcTime == 0) return 0; // No active calculation period if no history
        }

        uint256 timeElapsed = block.timestamp.sub(lastCalcTime);
        if (timeElapsed == 0) return 0;

        uint256 totalEnergyContribution = 0;

        // Calculate contribution from ERC20s
        for (uint i = 0; i < allowedERC20TokenList.length; i++) {
            address token = allowedERC20TokenList[i];
            uint256 balance = userERC20Balances[user][token];
            if (balance > 0) {
                // Simple linear contribution: amount * rate
                // A more complex system might use sqrt(balance) or other scaling
                totalEnergyContribution = totalEnergyContribution.add(balance.mul(baseEnergyRate));
            }
        }

        // Calculate contribution from ERC721s and combination bonuses
        for (uint i = 0; i < allowedERC721CollectionList.length; i++) {
            address collection = allowedERC721CollectionList[i];
            uint256[] storage userNFTs = userERC721Deposits[user][collection];
            if (userNFTs.length > 0) {
                 // Simple contribution per NFT: 1 * rate (or could be based on rarity, etc.)
                totalEnergyContribution = totalEnergyContribution.add(uint256(userNFTs.length).mul(baseEnergyRate));

                // Check for combination bonuses
                for(uint j=0; j < allowedERC20TokenList.length; j++) {
                    address token = allowedERC20TokenList[j];
                    uint256 erc20balance = userERC20Balances[user][token];
                    uint256 bonus = fusionCombinationBonus[token][collection];

                    if (erc20balance > 0 && bonus > 0) {
                        // Apply bonus. Example: bonus is percentage (500 = 5%). totalEnergyContribution gets 5% extra
                        // This bonus calculation is simplified. A real system needs careful scaling.
                        // Let's assume baseEnergyRate and fluctuation are scaled such that 10000 is 1x.
                        // The combination bonus is also a percentage multiplier on the *total* contribution from this combo.
                        // A complex yield formula is key here. Let's refine:
                        // Contribution = sum(ERC20_balance * token_value_or_weight * rate) + sum(ERC721_count * nft_value_or_weight * rate)
                        // Then apply bonuses/fluctuation to the total.
                        // Simplification: Assume all assets contribute equally based on a 'unit', rate is per unit per second.
                        // Total Units = sum(ERC20_balance / erc20_unit_value) + sum(ERC721_count * erc721_unit_value)
                        // Energy Rate per second = Total Units * baseEnergyRate * (quantumFluctuation / 10000)
                        // Total Energy = Energy Rate per second * timeElapsed * (1 + combo_bonuses / 10000)
                        // This requires unit values/weights for assets, which isn't in state.

                        // Let's use a simpler model for this example:
                        // Energy = timeElapsed * (baseEnergyRate/SCALING_FACTOR) * (quantumFluctuation/10000) * (1 + total_bonus_percentage/10000)
                        // where total_bonus_percentage is sum of applicable bonuses * number of qualifying pairs.
                        // Qualifying pair: user has >0 of specific ERC20 AND >0 of specific ERC721 collection.
                        // This means bonuses stack based on *types* of assets held, not quantities necessarily.

                        uint256 combinationFactor = 10000; // Start with 1x multiplier (represents 100%)
                        uint256 totalBonusPercentage = 0;

                        // Iterate through all possible bonus combinations
                        for (uint b_erc20_idx = 0; b_erc20_idx < allowedERC20TokenList.length; b_erc20_idx++) {
                             address b_erc20 = allowedERC20TokenList[b_erc20_idx];
                             uint256 user_erc20_bal = userERC20Balances[user][b_erc20];
                             if (user_erc20_bal > 0) {
                                 for (uint b_erc721_idx = 0; b_erc721_idx < allowedERC721CollectionList.length; b_erc721_idx++) {
                                     address b_erc721 = allowedERC721CollectionList[b_erc721_idx];
                                     uint256[] storage user_erc721_list = userERC721Deposits[user][b_erc721];
                                     if (user_erc721_list.length > 0) {
                                         uint256 bonus = fusionCombinationBonus[b_erc20][b_erc721];
                                         if (bonus > 0) {
                                             totalBonusPercentage = totalBonusPercentage.add(bonus);
                                         }
                                     }
                                 }
                             }
                        }

                        // Total multiplier: (fluctuation / 10000) * (1 + totalBonusPercentage / 10000)
                        // Let's simplify the formula using fixed point arithmetic (10000 = 1x for multipliers)
                        // Energy = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000 / SCALING_FACTOR
                        // SCALING_FACTOR depends on baseEnergyRate units (per second, per minute, etc.)
                        // Let's assume baseEnergyRate is in units per second per 'standard deposit unit', scaled by 1e18.
                        // So, Energy per second per unit = baseEnergyRate * quantumFluctuation / 1e4 * (1 + totalBonusPercentage / 1e4)
                        // Total energy = Time * baseEnergyRate * (quantumFluctuation/1e4) * (1 + totalBonusPercentage/1e4) * Total Deposit Units
                        // This is getting complicated. Let's make it simpler but still dynamic:
                        // Energy = timeElapsed * baseEnergyRate * (quantumFluctuation / 10000) + timeElapsed * baseEnergyRate * (totalBonusPercentage / 10000)
                        // Energy = timeElapsed * baseEnergyRate * ( (quantumFluctuation + totalBonusPercentage) / 10000 )
                        // Energy = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000
                        // Need a large SCALING_FACTOR for baseEnergyRate to avoid division by zero or small numbers.
                        // Let's assume baseEnergyRate is units/sec * 1e18.
                        // Then Energy per second = baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000 / 1e18
                        // Total Energy = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 1e4 / 1e18

                        // Total deposit units needed. Let's count total ERC20 balance (sum) and total ERC721 count (sum) as units.
                        uint256 totalDepositUnits = 0;
                         for (uint d_erc20_idx = 0; d_erc20_idx < allowedERC20TokenList.length; d_erc20_idx++) {
                             address d_erc20 = allowedERC20TokenList[d_erc20_idx];
                             totalDepositUnits = totalDepositUnits.add(userERC20Balances[user][d_erc20]); // Assuming ERC20 amounts are units
                         }
                          for (uint d_erc721_idx = 0; d_erc721_idx < allowedERC721CollectionList.length; d_erc721_idx++) {
                             address d_erc721 = allowedERC721CollectionList[d_erc721_idx];
                             uint256[] storage user_erc721_list = userERC721Deposits[user][d_erc721];
                              totalDepositUnits = totalDepositUnits.add(uint256(user_erc721_list.length).mul(1e18)); // Assuming each NFT is 1e18 units
                         }
                         // Ensure totalDepositUnits is not zero to avoid div by zero if we scale
                         if (totalDepositUnits == 0) return 0;


                        // Simplified Energy Calculation (Needs careful scaling in production):
                        // Energy = timeElapsed * baseEnergyRate * (quantumFluctuation / 10000) * (totalDepositUnits / SCALING) * (1 + totalBonusPercentage / 10000)
                        // Let's use fixed point 1e18 for energy calculation precision.
                        // baseEnergyRate should be units of energy per second per 'unit of asset' * 1e18
                        // asset units scaled by 1e18 already (ERC20 amount, NFT count * 1e18)
                        // totalBonusPercentage is like 500 for 5%
                        // fluctuation is like 10000 for 1x

                        // Formula: Energy = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000 * totalDepositUnits / 1e18
                        // This assumes baseEnergyRate is the rate for 1 unit of asset with 0 bonus/0 fluctuation beyond base.
                        // A more intuitive formula might be:
                        // Energy Rate Per Second = ( baseEnergyRate * (quantumFluctuation / 10000) + baseEnergyRate * (totalBonusPercentage / 10000) ) * totalDepositUnits / 1e18
                        // Energy = timeElapsed * ( baseEnergyRate * ( (quantumFluctuation + totalBonusPercentage) / 10000 ) ) * totalDepositUnits / 1e18
                        // This still feels complex for a simple example.

                        // Let's use a model where:
                        // Base Energy per second = baseEnergyRate
                        // Fluctuated Rate = Base Energy per second * (quantumFluctuation / 10000)
                        // Bonus Rate = Base Energy per second * (totalBonusPercentage / 10000)
                        // Total Rate per second = Fluctuated Rate + Bonus Rate
                        // Total Energy = timeElapsed * Total Rate per second * Total Deposit Units / 1e18 (to handle scaling)
                        // Example: baseEnergyRate = 1e12 (scaled), fluctuation=10000, bonus=500, units=1e18
                        // Total Rate = (1e12 * 10000/10000) + (1e12 * 500/10000) = 1e12 + 0.05e12 = 1.05e12
                        // Total Energy = timeElapsed * 1.05e12 * 1e18 / 1e18 = timeElapsed * 1.05e12

                        uint256 baseRateScaled = baseEnergyRate.mul(quantumFluctuation).div(10000); // Apply fluctuation
                        uint256 bonusRateScaled = baseEnergyRate.mul(totalBonusPercentage).div(10000); // Apply bonus percentage

                        uint256 totalRatePerUnitPerSecond = baseRateScaled.add(bonusRateScaled); // Combined rate per unit per second

                        // Total Energy = TimeElapsed * Total Rate Per Unit Per Second * Total Deposit Units / 1e18 (scaling factor)
                        // Use SafeMath.mul/div carefully to avoid overflow/underflow.
                        // Need to ensure totalDepositUnits and timeElapsed are not excessively large before multiplication.
                        // Assuming timeElapsed is reasonable (seconds). totalDepositUnits can be large.
                        // Energy = (timeElapsed * totalRatePerUnitPerSecond) / 1e18 * totalDepositUnits
                        // Need to order operations to maintain precision.
                        // Energy = timeElapsed * totalRatePerUnitPerSecond.mul(totalDepositUnits).div(1e18) ? No, overflow likely.
                        // Energy = timeElapsed.mul(totalRatePerUnitPerSecond).div(1e18).mul(totalDepositUnits) ? Same problem.
                        // Energy = timeElapsed.mul(totalRatePerUnitPerSecond).mul(totalDepositUnits).div(1e18 * 1e18) ? Requires more scaling.

                        // Let's refine the base unit scaling.
                        // Let `baseEnergyRate` be energy units per second per 'scaled asset unit'.
                        // Let 'scaled asset unit' be 1e18 of quantity (amount for ERC20, 1e18 for 1 NFT).
                        // User's total scaled units: sum(ERC20 amount) + sum(NFT count * 1e18)
                        // Energy Rate per Second per scaled unit = baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000
                        // Total Energy per second = Energy Rate per Second per scaled unit * User's total scaled units / 1e18 (to bring scaled unit back to base)
                        // Total Energy = timeElapsed * ( baseEnergyRate.mul(quantumFluctuation + totalBonusPercentage).div(10000) ).mul(totalDepositUnits).div(1e18)

                         uint256 energyRatePerScaledUnitPerSecond = baseEnergyRate.mul(quantumFluctuation.add(totalBonusPercentage)).div(10000);

                         uint256 pendingEnergy = timeElapsed.mul(energyRatePerScaledUnitPerSecond).mul(totalDepositUnits).div(1e18); // Final energy scaled by 1e18 assumed

                        return pendingEnergy;
                    }
                }
            }
        }

        // If no assets are deposited or no bonuses/fluctuation are set, contribution is 0
        return 0; // This part of the calculation was simplified. The complex part is above.
         // Let's re-evaluate the energy calculation to be more inclusive of all assets
         // regardless of combinations, then add the bonus.

        uint256 totalEnergyAccrued = 0;
        uint256 totalAssetValueUnits = 0; // Represents total 'staking power'

        // Sum up 'value units' from all deposited ERC20s
        for (uint i = 0; i < allowedERC20TokenList.length; i++) {
            address token = allowedERC20TokenList[i];
            uint256 balance = userERC20Balances[user][token];
            // Assume 1 unit of ERC20 amount = 1 scaled unit of value (1e18)
            totalAssetValueUnits = totalAssetValueUnits.add(balance); // assuming ERC20 amounts are already scaled or relative
        }

        // Sum up 'value units' from all deposited ERC721s
        for (uint i = 0; i < allowedERC721CollectionList.length; i++) {
            address collection = allowedERC721CollectionList[i];
            uint256[] storage userNFTs = userERC721Deposits[user][collection];
            // Assume each NFT is worth 1e18 scaled units of value
            totalAssetValueUnits = totalAssetValueUnits.add(uint256(userNFTs.length).mul(1e18));
        }

        if (totalAssetValueUnits == 0) return 0;

        // Calculate base energy rate adjusted by fluctuation
        // Rate per second per scaled unit = baseEnergyRate * quantumFluctuation / 10000
        uint256 adjustedBaseRatePerSecPerUnit = baseEnergyRate.mul(quantumFluctuation).div(10000);

        // Calculate total bonus percentage from all *qualifying* combinations
        uint256 totalBonusPercentage = 0;
         for (uint b_erc20_idx = 0; b_erc20_idx < allowedERC20TokenList.length; b_erc20_idx++) {
             address b_erc20 = allowedERC20TokenList[b_erc20_idx];
             uint256 user_erc20_bal = userERC20Balances[user][b_erc20];
             if (user_erc20_bal > 0) {
                 for (uint b_erc721_idx = 0; b_erc721_idx < allowedERC721CollectionList.length; b_erc721_idx++) {
                     address b_erc721 = allowedERC721CollectionList[b_erc721_idx];
                     uint256[] storage user_erc721_list = userERC721Deposits[user][b_erc721];
                     if (user_erc721_list.length > 0) {
                         uint256 bonus = fusionCombinationBonus[b_erc20][b_erc721];
                         if (bonus > 0) {
                             totalBonusPercentage = totalBonusPercentage.add(bonus); // Sum up all applicable bonuses
                         }
                     }
                 }
             }
        }

        // Calculate bonus rate per second per scaled unit
        // Bonus Rate per second per scaled unit = baseEnergyRate * totalBonusPercentage / 10000
         uint256 bonusRatePerSecPerUnit = baseEnergyRate.mul(totalBonusPercentage).div(10000);

         // Total Rate Per Second Per Scaled Unit = Adjusted Base Rate + Bonus Rate
         uint256 totalRatePerSecPerUnit = adjustedBaseRatePerSecPerUnit.add(bonusRatePerSecPerUnit);

         // Total Energy = timeElapsed * Total Rate Per Sec Per Scaled Unit * Total Asset Value Units / 1e18 (to unscale the asset units)
         // This requires careful multiplication/division order.
         // E = (timeElapsed * totalRatePerSecPerUnit / 1e9) * (totalAssetValueUnits / 1e9) ? Need 1e18 total division.
         // E = timeElapsed * totalRatePerSecPerUnit * totalAssetValueUnits / (1e18 * 1e18)? Too much scaling needed for inputs.

         // Let's assume baseEnergyRate is already scaled to result in scaled Energy units per second per scaled asset unit.
         // E.g., baseEnergyRate = 1e12. Staking 1 scaled asset unit (1e18) for 1 sec gives 1e12 scaled energy units.
         // Fluctuated Rate = 1e12 * fluctuation / 10000
         // Bonus Rate = 1e12 * totalBonusPercentage / 10000
         // Total Rate = 1e12 * (fluctuation + totalBonusPercentage) / 10000
         // Total Energy = timeElapsed * Total Rate * totalAssetValueUnits / 1e18

         uint256 finalRatePerSecPerScaledUnit = baseEnergyRate.mul(quantumFluctuation.add(totalBonusPercentage)).div(10000);

         // Pending Energy (scaled by 1e18) = timeElapsed * finalRatePerSecPerScaledUnit * totalAssetValueUnits / 1e18
         // Rearrange for safety: (timeElapsed * finalRatePerSecPerScaledUnit) / 1e9 * (totalAssetValueUnits / 1e9) <-- still need to handle remainder
         // Use multiplication before division where possible, but avoid overflow.
         // timeElapsed * finalRatePerSecPerScaledUnit is likely fine if timeElapsed < ~1 year (31.5M) and finalRate < uint256 max / 31.5M
         // (timeElapsed * finalRatePerSecPerScaledUnit) / 1e18 * totalAssetValueUnits <-- This is unsafe if totalAssetValueUnits is large

         // Best approach is often to divide inputs first if safe:
         // totalAssetValueUnits / 1e18 is the number of 'base asset units'. Let's use this.
         uint256 baseAssetUnits = totalAssetValueUnits.div(1e18); // Integer division loses precision, but safer.

         // Energy = timeElapsed * finalRatePerSecPerScaledUnit * baseAssetUnits
         // This formula is much simpler, but relies on baseEnergyRate being correctly scaled
         // to yield `scaled Energy` units per second per `base asset unit`.
         // If baseEnergyRate = 1e12 (scaled energy per second per base asset unit)
         // Energy = timeElapsed * 1e12 * (fluctuation + bonus) / 10000 * baseAssetUnits / 1e18 ??? Still need 1e18 scaling.

         // Let's assume `baseEnergyRate` is the rate in unscaled Energy units per second per scaled asset unit.
         // Final Energy (unscaled) = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000 * totalAssetValueUnits / 1e18
         // Using 1e18 scaling for energy calculation:
         // Energy (scaled 1e18) = timeElapsed * baseEnergyRate * (quantumFluctuation + totalBonusPercentage) / 10000 * totalAssetValueUnits / 1e18
         // Okay, let's stick to the simpler formula:
         // Energy = timeElapsed * totalRatePerSecPerUnit * totalAssetValueUnits / 1e18 (where totalRatePerSecPerUnit uses baseEnergyRate as input)
         // Example: baseEnergyRate = 1e12 (scaled), fluctuation=10000, bonus=500, totalAssetValueUnits = 10e18 (10 base units)
         // totalRatePerSecPerUnit = 1e12 * (10000+500) / 10000 = 1e12 * 1.05 = 1.05e12
         // Energy = timeElapsed * 1.05e12 * 10e18 / 1e18 = timeElapsed * 1.05e12 * 10 = timeElapsed * 10.5e12

         // This requires intermediate products to not overflow.
         // timeElapsed * totalRatePerSecPerUnit is fine (seconds * scaled rate)
         // result * totalAssetValueUnits might overflow
         // result * (totalAssetValueUnits / 1e9) / 1e9
         // (timeElapsed.mul(totalRatePerSecPerUnit)).div(1e9).mul(totalAssetValueUnits.div(1e9)) <-- this is safer but loses precision

         // Most robust is fixed-point multiplication library or careful ordering
         // (a * b) / c = (a / c) * b if c divides a.
         // (a * b) / c * d = (a*b*d) / c
         // Let's assume intermediate product `timeElapsed * totalRatePerSecPerUnit` fits in uint256.
         // Then we need to multiply by `totalAssetValueUnits` and divide by `1e18`.
         // Can use a fixed point library if needed, but let's try ordering divisions.
         // (timeElapsed * totalRatePerSecPerUnit * totalAssetValueUnits) / 1e18
         // = (timeElapsed * totalRatePerSecPerUnit / 1e9) * (totalAssetValueUnits / 1e9) <-- precision loss
         // = timeElapsed * (totalRatePerSecPerUnit / 1e18 * totalAssetValueUnits) <-- unsafe div
         // = timeElapsed * (totalRatePerSecPerUnit * (totalAssetValueUnits / 1e18)) <-- safer div first

         uint256 baseAssetUnitsScaledDown = totalAssetValueUnits.div(1e18); // This is the number of 'base units'
         uint256 pendingEnergyScaled = timeElapsed.mul(totalRatePerSecPerUnit).mul(baseAssetUnitsScaledDown); // Assume final energy is scaled

        return pendingEnergyScaled; // This is the calculated *pending* energy

    }

    /// @notice Claims the pending Quantum Energy for the caller.
    /// Updates the user's claimable energy balance and resets the calculation timer.
    function claimQuantumEnergy() public whenNotPaused {
        uint256 pending = calculateQuantumEnergy(msg.sender);
        require(pending > 0, "No energy to claim");

        userQuantumEnergy[msg.sender] = userQuantumEnergy[msg.sender].add(pending);
        userLastEnergyClaimTime[msg.sender] = block.timestamp; // Reset timer for new calculation period

        emit EnergyClaimed(msg.sender, pending);
    }

     /// @notice Internal helper to claim energy, used before state changes.
     /// @param user The address of the user.
     function claimQuantumEnergyInternal(address user) internal {
        uint256 pending = calculateQuantumEnergy(user);
        if (pending > 0) {
             userQuantumEnergy[user] = userQuantumEnergy[user].add(pending);
        }
        // Always update timestamp regardless of pending energy, to mark the time state was last accounted for.
        userLastEnergyClaimTime[user] = block.timestamp;
     }


    // --- Fusion Function ---

    /// @notice Performs the fusion process for the caller.
    /// Burns required Quantum Energy and consumes required deposited assets (ERC20 and ERC721)
    /// to mint a FusionShard NFT.
    function performFusion() public whenNotPaused {
        require(fusionEnergyCost > 0 || fusionERC20Requirements.length > 0 || fusionERC721Requirements.length > 0, "Fusion recipe not set");

        // 1. Claim pending energy first to ensure balance is up-to-date
        claimQuantumEnergyInternal(msg.sender);

        // 2. Check energy requirement
        require(userQuantumEnergy[msg.sender] >= fusionEnergyCost, "Insufficient Quantum Energy");

        // 3. Check ERC20 requirements and stage transfers
        for (uint i = 0; i < fusionERC20Requirements.length; i++) {
            address requiredToken = fusionERC20Requirements[i];
            uint256 requiredAmount = fusionERC20Amounts[i];
            require(userERC20Balances[msg.sender][requiredToken] >= requiredAmount, string(abi.encodePacked("Insufficient deposited ERC20: ", requiredToken)));
             // Note: We don't transfer yet, just check. Transfer happens after all checks.
        }

        // 4. Check ERC721 requirements and stage which specific NFTs to consume
        // This simplified version requires AT LEAST one NFT from each required collection.
        // A complex version would allow specifying *which* NFT IDs or consume based on criteria (rarity, etc.)
        // For this example, we'll consume the *first available* NFT from each required collection.
        uint256[] memory nftsToConsume = new uint256[](fusionERC721Requirements.length); // Store IDs to consume
        for (uint i = 0; i < fusionERC721Requirements.length; i++) {
            address requiredCollection = fusionERC721Requirements[i];
            uint256[] storage userNFTs = userERC721Deposits[msg.sender][requiredCollection];
            require(userNFTs.length > 0, string(abi.encodePacked("Insufficient deposited ERC721 from collection: ", requiredCollection)));
            // Check lock status for the NFT we are about to consume
            uint256 nftIdToUse = userNFTs[0]; // Use the first one for simplicity
             require(block.timestamp >= assetDepositTimestamps[msg.sender][requiredCollection][nftIdToUse].add(assetLockDuration), "Required NFT is locked");
            nftsToConsume[i] = nftIdToUse;
        }

        // --- All checks passed. Perform state updates and transfers. ---

        // 5. Consume Energy
        userQuantumEnergy[msg.sender] = userQuantumEnergy[msg.sender].sub(fusionEnergyCost);

        // 6. Consume ERC20s
        for (uint i = 0; i < fusionERC20Requirements.length; i++) {
            address requiredToken = fusionERC20Requirements[i];
            uint256 requiredAmount = fusionERC20Amounts[i];
            userERC20Balances[msg.sender][requiredToken] = userERC20Balances[msg.sender][requiredToken].sub(requiredAmount);
             // Note: These ERC20s are consumed from the *vault's balance*. They are not burned or transferred out.
             // They are effectively removed from the user's vault balance and could be used for vault operations later.
             // If they should be burned, the vault would need approval/transfer to a burn address.
             // Let's assume they are consumed internally for now.
             // The deposit timestamp for ERC20 is only relevant if the *entire* balance becomes zero.
              if (userERC20Balances[msg.sender][requiredToken] == 0) {
                 assetDepositTimestamps[msg.sender][requiredToken][0] = 0;
              }
        }

        // 7. Consume ERC721s
        for (uint i = 0; i < fusionERC721Requirements.length; i++) {
            address requiredCollection = fusionERC721Requirements[i];
            uint256 nftIdToUse = nftsToConsume[i];

             // Remove NFT from user's deposited list and internal tracking
             uint256[] storage userNFTs = userERC721Deposits[msg.sender][requiredCollection];
             // Find index of nftIdToUse. This loop is necessary again as state might have changed slightly or just to get the index.
             // This is inefficient (O(N) remove). A better structure for deposited NFTs is needed for O(1) removal.
             // Example: use a mapping `mapping(address => mapping(address => mapping(uint256 => bool))) private isDeposited;`
             // and a separate list, managing both. For simplicity, we re-scan the list here.
             for (uint j = 0; j < userNFTs.length; j++) {
                 if (userNFTs[j] == nftIdToUse) {
                     userNFTs[j] = userNFTs[userNFTs.length - 1];
                     userNFTs.pop();
                     break;
                 }
             }
             delete erc721TokenOwner[nftIdToUse]; // Remove internal ownership tracking
             delete assetDepositTimestamps[msg.sender][requiredCollection][nftIdToUse]; // Remove timestamp

             // The NFT itself remains in the vault contract's balance. It is 'consumed' from the user's perspective.
             // A real system might transfer it to a 'burned' address or use it in subsequent processes.
        }

        // 8. Mint FusionShard NFT
        uint256 mintedShardId = nextShardId++;
        bytes memory shardAttributesData; // Optional: encode attributes based on consumed assets
        // Example attributes logic (simple): combine total value of consumed ERC20s + count of consumed NFTs
        // In a real system, this would be complex logic potentially hashing input features.

        fusionShardContract.mint(msg.sender, mintedShardId, shardAttributesData);

        emit FusionPerformed(msg.sender, mintedShardId, fusionEnergyCost);
    }

    // --- View Functions ---

    /// @notice Gets the amount of a specific ERC-20 token deposited by a user.
    /// @param user The address of the user.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @return The deposited amount.
    function getUserERC20Deposit(address user, address tokenAddress) public view returns (uint256) {
        return userERC20Balances[user][tokenAddress];
    }

    /// @notice Gets the list of token IDs from a specific ERC-721 collection deposited by a user.
    /// @param user The address of the user.
    /// @param collectionAddress The address of the ERC-721 collection.
    /// @return An array of deposited token IDs.
    function getUserERC721Deposits(address user, address collectionAddress) public view returns (uint256[] memory) {
        return userERC721Deposits[user][collectionAddress];
    }

     /// @notice Gets the lock expiration timestamp for a specific deposited asset.
     /// @param user The address of the user.
     /// @param assetAddress The address of the ERC-20 token or ERC-721 collection.
     /// @param tokenIdOrZeroForERC20 The token ID for ERC-721, or 0 for ERC-20.
     /// @return The timestamp when the asset lock expires.
    function getAssetLockExpiration(address user, address assetAddress, uint256 tokenIdOrZeroForERC20) public view returns (uint256) {
        uint256 depositTime = assetDepositTimestamps[user][assetAddress][tokenIdOrZeroForERC20];
        if (depositTime == 0) return 0; // Asset not deposited or already withdrawn/consumed
        return depositTime.add(assetLockDuration);
    }

    /// @notice Gets the user's currently claimable Quantum Energy balance.
    /// This does NOT include pending energy that hasn't been claimed yet.
    /// Use `calculateQuantumEnergy` to see pending energy.
    /// @param user The address of the user.
    /// @return The user's claimable energy balance.
    function getUserQuantumEnergyBalance(address user) public view returns (uint256) {
        return userQuantumEnergy[user];
    }

    /// @notice Gets the list of currently allowed ERC-20 token addresses for deposit.
    /// @return An array of allowed ERC-20 token addresses.
    function getAllowedERC20Tokens() public view returns (address[] memory) {
        return allowedERC20TokenList;
    }

    /// @notice Gets the list of currently allowed ERC-721 collection addresses for deposit.
    /// @return An array of allowed ERC-721 collection addresses.
    function getAllowedERC721Collections() public view returns (address[] memory) {
        return allowedERC721CollectionList;
    }

    /// @notice Gets the current vault parameters related to energy generation and locking.
    /// @return baseRate The base energy rate.
    /// @return fluctuation The quantum fluctuation multiplier.
    /// @return lockDuration The asset lock duration in seconds.
    function getQuantumParameters() public view returns (uint256 baseRate, uint256 fluctuation, uint256 lockDuration) {
        return (baseEnergyRate, quantumFluctuation, assetLockDuration);
    }

    /// @notice Gets the current requirements for performing a fusion.
    /// @return erc20Reqs Addresses of required ERC-20 tokens.
    /// @return erc20Amts Amounts required for corresponding ERC-20 tokens.
    /// @return erc721Reqs Addresses of required ERC-721 collections.
    /// @return energy The amount of Quantum Energy required.
    function getFusionRequirements() public view returns (address[] memory erc20Reqs, uint256[] memory erc20Amts, address[] memory erc721Reqs, uint256 energy) {
        return (fusionERC20Requirements, fusionERC20Amounts, fusionERC721Requirements, fusionEnergyCost);
    }

     /// @notice Gets the current energy generation bonus for a specific ERC-20 and ERC-721 collection combination.
     /// @param erc20Address The address of the ERC-20 token.
     /// @param erc721Address The address of the ERC-721 collection.
     /// @return The bonus percentage (e.g., 500 for 5%).
    function getFusionCombinationBonus(address erc20Address, address erc721Address) public view returns (uint256) {
        return fusionCombinationBonus[erc20Address][erc721Address];
    }

    // Add more view functions as needed to expose internal state relevant to users or UIs.
    // e.g., total TVL, count of deposited NFTs per collection, etc. (Can be gas intensive).

    // --- Internal / Helper Functions (if needed) ---
    // claimQuantumEnergyInternal is an example.

    // --- Receive / Fallback (Optional but good practice) ---
    receive() external payable {
        revert("Vault does not accept direct ETH deposits");
    }

    fallback() external payable {
        revert("Vault does not accept arbitrary calls or ETH deposits");
    }
}
```

**Explanation of Concepts & Advanced Aspects:**

1.  **Multi-Asset Handling:** The contract manages separate balances and lists for different ERC-20 tokens and ERC-721 collections deposited by each user. State variables (`userERC20Balances`, `userERC721Deposits`, `erc721TokenOwner`) are structured to handle this.
2.  **Dynamic Yield (`calculateQuantumEnergy`):** This is the core complex function. It goes beyond simple linear staking yield.
    *   **Time-Based:** Calculates yield based on the duration since the user's last energy claim or relevant state change (`userLastEnergyClaimTime`).
    *   **Base Rate:** Uses a configurable `baseEnergyRate`.
    *   **Global Fluctuation:** Incorporates `quantumFluctuation`, allowing the protocol to globally adjust yield based on external factors or policy (simulated by `updateQuantumFluctuation`).
    *   **Combination Bonuses:** Checks if a user holds specific *combinations* of *different types* of assets (e.g., a certain ERC-20 *and* an NFT from a specific collection). If they do, a `fusionCombinationBonus` is added, acting as a multiplier on their energy generation. This encourages diverse deposits.
    *   **Scaled Units:** The calculation assumes asset quantities are normalized to 'scaled units' (e.g., 1e18) to handle varying token decimals and NFTs uniformly in the yield formula. The formula `timeElapsed * totalRatePerSecPerUnit * totalAssetValueUnits / 1e18` attempts to apply time and rate to the total value units, then unscale. *Note: Precise fixed-point arithmetic is crucial for production, and the provided calculation is a simplified representation.*
3.  **Asset Locking:** Deposits have a minimum duration (`assetLockDuration`) during which they cannot be withdrawn (`withdrawERC20`, `withdrawERC721`). The deposit timestamp is recorded for each asset.
4.  **Asset Fusion (`performFusion`):** This is a creative concept.
    *   It requires users to spend accrued `userQuantumEnergy`.
    *   It requires consuming specific types and amounts of *deposited* ERC-20s and specific *deposited* NFTs from certain collections (`fusionERC20Requirements`, `fusionERC721Requirements`). These assets are removed from the user's vault balance/inventory (though they remain owned by the vault contract).
    *   Successful fusion results in minting a `FusionShard` NFT by calling an external `IFusionShard` contract. The `FusionShard` can potentially have attributes derived from the consumed assets, making fusion results unique and potentially rare.
5.  **Configurable Mechanics:** Many parameters are adjustable by the owner: allowed assets, base rates, fluctuation, lock duration, combination bonuses, and the fusion recipe itself. This allows the protocol to evolve and adapt without needing a full redeployment (assuming the core logic remains within the contract's scope). This structure also lends itself well to future integration with a decentralized governance module that replaces `onlyOwner`.
6.  **Modularity:** Interaction with the `FusionShard` contract is done via an interface (`IFusionShard`), making the vault contract less coupled to the specific implementation details of the Shard NFT, provided it adheres to the interface (specifically, the `mint` function).
7.  **Pausability:** Standard Pausable pattern for emergency stops.
8.  **ERC721Receiver:** Implements the necessary interface to safely receive NFTs.

This contract demonstrates a combination of common DeFi patterns (vaults, staking/yield) with more creative/advanced concepts (dynamic yield based on multiple factors and combinations, asset transformation via "fusion," external parameter influence, multi-asset requirement for actions). It has a clear internal state complexity and interaction flow.

Remember that deploying and managing such a contract requires careful consideration of:
*   **Gas Costs:** Complex calculations and state updates (especially array manipulation in `withdrawERC721` and `performFusion`) can be expensive.
*   **Precision:** Handling scaled arithmetic for energy calculation needs robust libraries or careful implementation to avoid rounding errors.
*   **Security:** Thorough testing, audits, and formal verification are crucial given the value of assets it would hold and the complexity of the state transitions.
*   **Upgradeability:** For a real-world project, implementing this via proxy patterns (like UUPS) would be necessary for future updates.
*   **External Dependencies:** The `IFusionShard` contract is an external dependency that must be deployed and trusted.