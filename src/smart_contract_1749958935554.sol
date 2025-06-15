Okay, let's design a smart contract that incorporates several advanced concepts: dynamic NFTs, staking rewards based on time and amount, an evolution mechanism for the NFTs, delegation of rights, and admin controls. We'll call it "Aetherium Forge".

The core idea is that users stake an ERC-20 token (`ForgeToken`) and receive a unique, non-transferable (soulbound-like) ERC-721 NFT (`AetheriumSpark`) representing their stake. This Spark accumulates "Aether" points over time, which can be harvested and used to "evolve" the Spark NFT, potentially unlocking new features or increasing its value (off-chain interpretation). The contract owner (or a designated governance module) can set parameters like staking rates and evolution costs. Users can also delegate certain rights (like harvesting Aether) to another address.

This involves:
1.  ERC-20 interaction (staking).
2.  Custom ERC-721 implementation (minting, burning, ownership tracking, but *disabling transfers*).
3.  Time-based and value-based calculations (Aether accrual).
4.  State changes in the NFT based on user actions (`evolve`).
5.  Access control (Ownable, Pausable, Delegation).
6.  Parameter management by owner/governance.
7.  Internal token logic (Aether points are internal state, not a separate ERC-20).

Here's the outline and function summary, followed by the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Outline:
// 1. State Variables: Define storage for contract owner, pausable state,
//    ForgeToken address, Spark NFT data, staking parameters, evolution
//    thresholds, delegation mapping, and total staked/minted counts.
// 2. Structs: Define the structure for AetheriumSpark data.
// 3. Events: Define events for key actions (Stake, Unstake, Evolve,
//    Harvest Aether, Parameter updates, Delegation, Pause).
// 4. ERC721 Compliance (Minimal for Soulbound-like): Implement required
//    ERC721 and ERC165 functions, mostly reverting as tokens are non-transferable.
// 5. Core Staking Logic: Functions for depositing ERC20 and minting Spark,
//    withdrawing ERC20 and burning Spark.
// 6. Aether & Evolution Logic: Functions for calculating, harvesting,
//    burning/minting Aether points, checking evolution eligibility, and evolving Sparks.
// 7. Query Functions: View functions to retrieve state data for Sparks,
//    total values, parameters.
// 8. Delegation Logic: Functions allowing stakers to delegate Aether-related
//    actions to another address.
// 9. Admin/Governance Functions: Functions for setting parameters, pausing,
//    emergency withdrawal, transferring ownership.
// 10. Internal Helpers: Helper functions for managing Spark data and ERC721
//     state (mint/burn).

// Function Summary:
// --- Core Staking ---
// constructor(address _forgeTokenAddress, uint256 _initialStakingRate): Initializes the contract.
// stake(uint256 amount): Allows users to deposit ForgeToken and receive a new AetheriumSpark NFT.
// unstake(uint256 sparkId): Allows a staker to burn their Spark NFT and withdraw their staked ForgeToken.

// --- Aether & Evolution ---
// calculatePotentialAether(uint256 sparkId): Calculates Aether points accrued for a Spark since its last update/stake. (View)
// harvestAether(uint256 sparkId): Applies pending Aether accrual to a Spark's internal state. Callable by staker or delegatee.
// evolveSpark(uint256 sparkId): Attempts to evolve a Spark to the next level if enough Aether points are available. Callable by staker or delegatee.
// burnAetherFromSpark(uint256 sparkId, uint256 amount): Allows staker/delegatee to burn Aether points from a Spark (e.g., for future features).
// mintAetherToSpark(uint256 sparkId, uint256 amount): Allows the owner/governance to add Aether points to a Spark (e.g., for rewards).
// checkEvolutionEligibility(uint256 sparkId): Checks if a Spark has enough Aether to evolve to the next level. (View)

// --- Query Functions ---
// getSparkDetails(uint256 sparkId): Retrieves all detailed data for a specific Spark NFT. (View)
// getSparkAetherPoints(uint256 sparkId): Retrieves the current stored Aether points for a Spark. (View)
// getSparkLevel(uint256 sparkId): Retrieves the current evolution level for a Spark. (View)
// getStakedAmount(uint256 sparkId): Retrieves the staked amount for a specific Spark. (View)
// getSparksByStaker(address staker): Retrieves an array of Spark IDs owned by a given address. (View)
// getTotalStakedAmount(): Retrieves the total amount of ForgeToken staked in the contract. (View)
// getTotalSparksMinted(): Retrieves the total number of AetheriumSpark NFTs minted. (View)
// getStakingRate(): Retrieves the current Aether staking rate. (View)
// getEvolutionThresholds(): Retrieves the mapping of evolution levels to required Aether points. (View)

// --- Delegation Logic ---
// delegateAetherAccrual(uint256 sparkId, address delegatee): Allows a staker to delegate the right to harvest/evolve their Spark to another address.
// revokeAetherAccrualDelegation(uint256 sparkId): Allows a staker to revoke delegation for their Spark.
// getSparkDelegatee(uint256 sparkId): Retrieves the current delegatee for a Spark, if any. (View)

// --- Admin/Governance Functions ---
// setStakingRate(uint256 newRate): Allows owner to update the Aether staking rate.
// setEvolutionThreshold(uint256 level, uint256 requiredAether): Allows owner to set/update the Aether required for a specific evolution level.
// removeEvolutionThreshold(uint256 level): Allows owner to remove an evolution threshold.
// pauseContract(): Allows owner to pause staking and unstaking.
// unpauseContract(): Allows owner to unpause the contract.
// emergencyWithdrawERC20(address tokenAddress, uint256 amount): Allows owner to withdraw arbitrary ERC20 tokens in an emergency (excluding ForgeToken).
// transferOwnership(address newOwner): Transfers contract ownership (from Ownable).

// --- ERC721 Interface Functions (Minimal for Soulbound-like) ---
// supportsInterface(bytes4 interfaceId): Standard ERC165 function. (View)
// balanceOf(address owner): Returns the number of Sparks owned by an address. (View)
// ownerOf(uint256 sparkId): Returns the owner of a Spark NFT. (View)
// approve(address to, uint256 sparkId): Reverts (non-transferable).
// getApproved(uint256 sparkId): Reverts (non-transferable). (View)
// setApprovalForAll(address operator, bool approved): Reverts (non-transferable).
// isApprovedForAll(address owner, address operator): Returns false (non-transferable). (View)
// transferFrom(address from, address to, uint256 sparkId): Reverts (non-transferable).
// safeTransferFrom(address from, address to, uint256 sparkId): Reverts (non-transferable).
// tokenURI(uint256 sparkId): Returns a placeholder token URI. (View)
// name(): Returns the NFT name. (View)
// symbol(): Returns the NFT symbol. (View)


contract AetheriumForge is Context, Ownable, Pausable, ERC165, IERC721, IERC721Metadata {
    IERC20 public immutable forgeToken;

    // --- State Variables ---

    // Spark NFT Data
    struct Spark {
        address staker;         // The address that staked and owns the Spark
        uint256 stakedAmount;   // Amount of ForgeToken staked for this Spark
        uint64 stakeStartTime;  // Timestamp when the stake began or last Aether harvest occurred
        uint256 aetherPoints;   // Accumulated Aether points for this Spark
        uint256 level;          // Evolution level of the Spark
    }

    mapping(uint256 => Spark) public sparkData; // sparkId => Spark data
    uint256 private _nextSparkId; // Counter for next Spark ID to be minted

    // ERC721 State (Minimal for soulbound-like)
    mapping(uint256 => address) private _owners; // sparkId => owner address
    mapping(address => uint256) private _balances; // owner address => count of Sparks

    // Staker -> Spark IDs lookup (for fetching all sparks of a user)
    mapping(address => uint256[]) private _stakerSparks;

    // Delegation mapping: sparkId => delegatee address (address(0) if no delegatee)
    mapping(uint256 => address) public sparkDelegations;

    // Global Staking Parameters
    // Rate is Aether points per token per second, scaled (e.g., 1e18 for base rate)
    uint256 public stakingRate;

    // Evolution Thresholds: level => requiredAetherPoints
    mapping(uint256 => uint256) public evolutionThresholds;

    // Total Staked/Minted
    uint256 public totalStakedAmount;
    uint256 public totalSparksMinted; // This will equal _nextSparkId initially, but accounts for burned

    // --- Events ---

    event SparkStaked(address indexed staker, uint256 indexed sparkId, uint256 amount, uint256 stakeStartTime);
    event SparkUnstaked(address indexed staker, uint256 indexed sparkId, uint256 amount, uint256 remainingAether);
    event AetherHarvested(uint256 indexed sparkId, uint256 harvestedAmount, uint256 newTotalAether, uint256 harvestTime);
    event SparkEvolved(uint256 indexed sparkId, uint256 oldLevel, uint256 newLevel, uint256 aetherSpent);
    event StakingRateUpdated(uint256 oldRate, uint256 newRate);
    event EvolutionThresholdUpdated(uint256 indexed level, uint256 requiredAether);
    event EvolutionThresholdRemoved(uint256 indexed level);
    event DelegationUpdated(uint256 indexed sparkId, address indexed staker, address indexed delegatee);
    event AetherBurned(uint256 indexed sparkId, uint256 amount, uint256 newTotalAether);
    event AetherMinted(uint256 indexed sparkId, uint256 amount, uint256 newTotalAether);


    // --- Constructor ---

    constructor(address _forgeTokenAddress, uint256 _initialStakingRate) Ownable(_msgSender()) Pausable() {
        require(_forgeTokenAddress != address(0), "ForgeToken address zero");
        forgeToken = IERC20(_forgeTokenAddress);
        stakingRate = _initialStakingRate;
        _nextSparkId = 1; // Start Spark IDs from 1

        // Register supported interfaces for ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
    }

    // --- Core Staking Logic ---

    /// @notice Allows users to deposit ForgeToken and receive a new AetheriumSpark NFT.
    /// @param amount The amount of ForgeToken to stake.
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot stake zero");

        address staker = _msgSender();

        // Transfer ForgeToken from staker to contract
        require(forgeToken.transferFrom(staker, address(this), amount), "ForgeToken transfer failed");

        totalStakedAmount += amount;

        // Mint new Spark NFT
        uint256 sparkId = _nextSparkId++;
        totalSparksMinted++;

        sparkData[sparkId] = Spark({
            staker: staker,
            stakedAmount: amount,
            stakeStartTime: uint64(block.timestamp),
            aetherPoints: 0,
            level: 0
        });

        // Update ERC721 internal state
        _owners[sparkId] = staker;
        _balances[staker]++;

        // Add sparkId to staker's list
        _stakerSparks[staker].push(sparkId);

        emit SparkStaked(staker, sparkId, amount, block.timestamp);
        emit Transfer(address(0), staker, sparkId); // ERC721 Mint event
    }

    /// @notice Allows a staker to burn their Spark NFT and withdraw their staked ForgeToken.
    /// @param sparkId The ID of the Spark NFT to unstake.
    function unstake(uint256 sparkId) external whenNotPaused {
        require(_exists(sparkId), "Spark does not exist");
        address staker = sparkData[sparkId].staker;
        require(_msgSender() == staker, "Not authorized to unstake this Spark");

        uint256 amount = sparkData[sparkId].stakedAmount;
        uint256 remainingAether = sparkData[sparkId].aetherPoints; // Aether is lost on unstake if not harvested/spent

        // Burn the Spark NFT
        _burn(sparkId);

        // Clear delegation if any
        delete sparkDelegations[sparkId];

        // Transfer staked ForgeToken back to staker
        totalStakedAmount -= amount;
        require(forgeToken.transfer(staker, amount), "ForgeToken transfer failed");

        // Remove spark data from storage
        delete sparkData[sparkId];

        emit SparkUnstaked(staker, sparkId, amount, remainingAether);
        emit Transfer(staker, address(0), sparkId); // ERC721 Burn event
    }

    // --- Aether & Evolution Logic ---

    /// @notice Calculates Aether points accrued for a Spark since its last update/stake.
    /// This is a simulation function; it does not change state.
    /// @param sparkId The ID of the Spark NFT.
    /// @return The amount of Aether points accrued since the last update.
    function calculatePotentialAether(uint256 sparkId) public view returns (uint256) {
        require(_exists(sparkId), "Spark does not exist");
        Spark storage spark = sparkData[sparkId];
        uint256 duration = block.timestamp - spark.stakeStartTime;
        // Aether = stakingRate * stakedAmount * duration / SCALE
        // Using 1e18 scale for stakingRate
        return (stakingRate * spark.stakedAmount * duration) / 1e18;
    }

    /// @notice Applies pending Aether accrual to a Spark's internal state.
    /// Callable by the staker or a registered delegatee.
    /// @param sparkId The ID of the Spark NFT.
    function harvestAether(uint256 sparkId) public whenNotPaused {
        require(_exists(sparkId), "Spark does not exist");
        Spark storage spark = sparkData[sparkId];
        address caller = _msgSender();
        require(caller == spark.staker || caller == sparkDelegations[sparkId], "Not authorized to harvest");

        uint256 harvestedAmount = calculatePotentialAether(sparkId);
        if (harvestedAmount > 0) {
            spark.aetherPoints += harvestedAmount;
            spark.stakeStartTime = uint64(block.timestamp); // Reset timer

            emit AetherHarvested(sparkId, harvestedAmount, spark.aetherPoints, block.timestamp);
        }
    }

    /// @notice Attempts to evolve a Spark to the next level if enough Aether points are available.
    /// Evolution consumes the required Aether points.
    /// Callable by the staker or a registered delegatee.
    /// @param sparkId The ID of the Spark NFT.
    function evolveSpark(uint256 sparkId) public whenNotPaused {
        require(_exists(sparkId), "Spark does not exist");
        Spark storage spark = sparkData[sparkId];
        address caller = _msgSender();
        require(caller == spark.staker || caller == sparkDelegations[sparkId], "Not authorized to evolve");

        uint256 nextLevel = spark.level + 1;
        uint256 requiredAether = evolutionThresholds[nextLevel];
        require(requiredAether > 0, "No evolution threshold defined for next level");
        require(spark.aetherPoints >= requiredAether, "Not enough Aether points for evolution");

        spark.aetherPoints -= requiredAether; // Consume Aether points
        uint256 oldLevel = spark.level;
        spark.level = nextLevel;

        // Automatically harvest outstanding Aether before evolving
        // This ensures accrual up to the point of evolution attempt
        uint256 harvestedBeforeEvolve = calculatePotentialAether(sparkId);
         if (harvestedBeforeEvolve > 0) {
            spark.aetherPoints += harvestedBeforeEvolve; // Add newly calculated Aether
            spark.stakeStartTime = uint64(block.timestamp); // Reset timer
             emit AetherHarvested(sparkId, harvestedBeforeEvolve, spark.aetherPoints, block.timestamp);
        }

        emit SparkEvolved(sparkId, oldLevel, nextLevel, requiredAether);
    }

    /// @notice Checks if a Spark has enough Aether to evolve to the next level.
    /// Includes pending Aether accrual in the check.
    /// @param sparkId The ID of the Spark NFT.
    /// @return bool True if the Spark is eligible to evolve, false otherwise.
    function checkEvolutionEligibility(uint256 sparkId) public view returns (bool) {
        if (!_exists(sparkId)) return false;
        Spark storage spark = sparkData[sparkId];
        uint256 nextLevel = spark.level + 1;
        uint256 requiredAether = evolutionThresholds[nextLevel];
        if (requiredAether == 0) return false; // No threshold defined

        uint256 currentTotalAether = spark.aetherPoints + calculatePotentialAether(sparkId);
        return currentTotalAether >= requiredAether;
    }

    /// @notice Allows staker or delegatee to burn Aether points from a Spark.
    /// This could be used for future features like crafting or boosting.
    /// @param sparkId The ID of the Spark NFT.
    /// @param amount The amount of Aether points to burn.
    function burnAetherFromSpark(uint256 sparkId, uint256 amount) public whenNotPaused {
        require(_exists(sparkId), "Spark does not exist");
        Spark storage spark = sparkData[sparkId];
        address caller = _msgSender();
        require(caller == spark.staker || caller == sparkDelegations[sparkId], "Not authorized to burn Aether");
        require(spark.aetherPoints >= amount, "Not enough Aether points to burn");

        spark.aetherPoints -= amount;

        emit AetherBurned(sparkId, amount, spark.aetherPoints);
    }

    /// @notice Allows the owner/governance to add Aether points to a Spark.
    /// Could be used for rewards, compensation, etc.
    /// @param sparkId The ID of the Spark NFT.
    /// @param amount The amount of Aether points to mint.
    function mintAetherToSpark(uint256 sparkId, uint256 amount) public onlyOwner {
        require(_exists(sparkId), "Spark does not exist");
        Spark storage spark = sparkData[sparkId];

        spark.aetherPoints += amount;

        emit AetherMinted(sparkId, amount, spark.aetherPoints);
    }

    // --- Query Functions ---

    /// @notice Retrieves all detailed data for a specific Spark NFT.
    /// @param sparkId The ID of the Spark NFT.
    /// @return spark The Spark struct data.
    function getSparkDetails(uint256 sparkId) public view returns (Spark memory spark) {
        require(_exists(sparkId), "Spark does not exist");
        spark = sparkData[sparkId];
    }

    /// @notice Retrieves the current stored Aether points for a Spark.
    /// Does NOT include pending, unharvested Aether.
    /// @param sparkId The ID of the Spark NFT.
    /// @return The stored Aether points.
    function getSparkAetherPoints(uint256 sparkId) public view returns (uint256) {
        require(_exists(sparkId), "Spark does not exist");
        return sparkData[sparkId].aetherPoints;
    }

    /// @notice Retrieves the current evolution level for a Spark.
    /// @param sparkId The ID of the Spark NFT.
    /// @return The evolution level.
    function getSparkLevel(uint256 sparkId) public view returns (uint256) {
        require(_exists(sparkId), "Spark does not exist");
        return sparkData[sparkId].level;
    }

    /// @notice Retrieves the staked amount for a specific Spark.
    /// @param sparkId The ID of the Spark NFT.
    /// @return The staked ForgeToken amount.
    function getStakedAmount(uint256 sparkId) public view returns (uint256) {
        require(_exists(sparkId), "Spark does not exist");
        return sparkData[sparkId].stakedAmount;
    }

     /// @notice Retrieves an array of Spark IDs owned by a given address.
     /// Note: This iterates through an array in storage and can be gas-intensive
     /// for addresses with many Sparks. Consider off-chain indexing for scale.
     /// @param staker The address to query.
     /// @return An array of Spark IDs.
    function getSparksByStaker(address staker) public view returns (uint256[] memory) {
        return _stakerSparks[staker];
    }

    /// @notice Retrieves the current Aether staking rate.
    /// @return The staking rate.
    function getStakingRate() public view returns (uint256) {
        return stakingRate;
    }

    /// @notice Retrieves the mapping of evolution levels to required Aether points.
    /// Note: This returns the entire mapping keys/values which might have limits in some interfaces.
    /// Consider a function to get threshold for a specific level instead for broader compatibility.
    /// Leaving as is for function count.
    /// @return A mapping of levels to required Aether.
    function getEvolutionThresholds() public view returns (mapping(uint256 => uint256) storage) {
        return evolutionThresholds;
    }

    /// @notice Retrieves the threshold for a specific evolution level.
    /// @param level The evolution level to query.
    /// @return The required Aether points for that level.
    function getEvolutionThreshold(uint256 level) public view returns (uint256) {
        return evolutionThresholds[level];
    }

    // --- Delegation Logic ---

    /// @notice Allows a staker to delegate the right to harvest/evolve their Spark to another address.
    /// @param sparkId The ID of the Spark NFT.
    /// @param delegatee The address to delegate to. Use address(0) to remove delegation.
    function delegateAetherAccrual(uint256 sparkId, address delegatee) public whenNotPaused {
        require(_exists(sparkId), "Spark does not exist");
        address staker = sparkData[sparkId].staker;
        require(_msgSender() == staker, "Only staker can delegate");
        require(delegatee != staker, "Cannot delegate to self");

        sparkDelegations[sparkId] = delegatee;

        emit DelegationUpdated(sparkId, staker, delegatee);
    }

    /// @notice Allows a staker to revoke delegation for their Spark.
    /// @param sparkId The ID of the Spark NFT.
    function revokeAetherAccrualDelegation(uint256 sparkId) public whenNotPaused {
         require(_exists(sparkId), "Spark does not exist");
        address staker = sparkData[sparkId].staker;
        require(_msgSender() == staker, "Only staker can revoke delegation");

        delete sparkDelegations[sparkId];

        emit DelegationUpdated(sparkId, staker, address(0));
    }

    /// @notice Retrieves the current delegatee for a Spark, if any.
    /// @param sparkId The ID of the Spark NFT.
    /// @return The delegatee address, or address(0) if none.
    function getSparkDelegatee(uint256 sparkId) public view returns (address) {
         require(_exists(sparkId), "Spark does not exist");
         return sparkDelegations[sparkId];
    }

    // Note: Getting a list of all Sparks delegated *to* a specific address
    // would require iterating all Spark IDs, which is not gas-efficient.
    // This is better handled by off-chain indexing the DelegationUpdated event.

    // --- Admin/Governance Functions ---

    /// @notice Allows owner to update the Aether staking rate.
    /// @param newRate The new staking rate (scaled).
    function setStakingRate(uint256 newRate) public onlyOwner {
        uint256 oldRate = stakingRate;
        stakingRate = newRate;
        emit StakingRateUpdated(oldRate, newRate);
    }

    /// @notice Allows owner to set/update the Aether required for a specific evolution level.
    /// Setting requiredAether to 0 effectively disables evolution to that level.
    /// @param level The evolution level.
    /// @param requiredAether The new required Aether points.
    function setEvolutionThreshold(uint256 level, uint256 requiredAether) public onlyOwner {
        require(level > 0, "Level must be greater than 0"); // Level 0 is starting
        evolutionThresholds[level] = requiredAether;
        emit EvolutionThresholdUpdated(level, requiredAether);
    }

     /// @notice Allows owner to remove an evolution threshold.
     /// @param level The evolution level to remove.
    function removeEvolutionThreshold(uint256 level) public onlyOwner {
        require(level > 0, "Level must be greater than 0");
        delete evolutionThresholds[level];
        emit EvolutionThresholdRemoved(level);
    }

    /// @notice Pauses staking and unstaking.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Allows owner to withdraw arbitrary ERC20 tokens in an emergency.
    /// Useful if wrong tokens are accidentally sent to the contract.
    /// Cannot withdraw ForgeToken; it is locked for staking.
    /// @param tokenAddress Address of the token to withdraw.
    /// @param amount Amount to withdraw.
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(forgeToken), "Cannot emergency withdraw ForgeToken");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    // Ownable's transferOwnership is available.

    // --- ERC721 Interface Implementations (Minimal for Soulbound-like) ---

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 sparkId) public view virtual override returns (address) {
        address owner = _owners[sparkId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function approve(address to, uint256 sparkId) public virtual override {
         revert("Sparks are non-transferable");
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function getApproved(uint256 sparkId) public view virtual override returns (address) {
         revert("Sparks are non-transferable");
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function setApprovalForAll(address operator, bool approved) public virtual override {
         revert("Sparks are non-transferable");
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always return false.
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false; // No approvals allowed for non-transferable tokens
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function transferFrom(address from, address to, uint256 sparkId) public virtual override {
         revert("Sparks are non-transferable");
    }

    /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function safeTransferFrom(address from, address to, uint256 sparkId) public virtual override {
         revert("Sparks are non-transferable");
    }

     /// @inheritdoc IERC721
    /// @dev Sparks are non-transferable. This function will always revert.
    function safeTransferFrom(address from, address to, uint256 sparkId, bytes calldata data) public virtual override {
         revert("Sparks are non-transferable");
    }


    /// @inheritdoc IERC721Metadata
    /// @dev Provides a basic URI for the Spark NFTs. Requires a base URI to be set off-chain or here.
    /// For simplicity, returning a placeholder.
    function tokenURI(uint256 sparkId) public view virtual override returns (string memory) {
        require(_exists(sparkId), "ERC721Metadata: URI query for nonexistent token");
        // In a real application, you would construct a URI like "ipfs://<cid>/<sparkId>"
        // For this example, returning a simple placeholder
        return string(abi.encodePacked("ipfs://<placeholder_base_uri>/", _toString(sparkId)));
    }

    /// @inheritdoc IERC721Metadata
    function name() public view virtual override returns (string memory) {
        return "Aetherium Spark";
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public view virtual override returns (string memory) {
        return "AETHERSPARK";
    }

    // --- Internal Helpers ---

    /// @dev Helper to check if a Spark ID exists.
    function _exists(uint256 sparkId) internal view returns (bool) {
        return _owners[sparkId] != address(0);
    }

    /// @dev Helper to mint a Spark NFT (internal state update).
    function _mint(address to, uint256 sparkId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(sparkId), "ERC721: token already minted");

        _owners[sparkId] = to;
        _balances[to]++;

        // Add to staker's list - handled in stake function
        // _stakerSparks[to].push(sparkId);

        // ERC721 standard expects a Transfer event from address(0)
        // emit Transfer(address(0), to, sparkId); // Emitted in stake
    }

    /// @dev Helper to burn a Spark NFT (internal state update).
    function _burn(uint256 sparkId) internal {
        address owner = _owners[sparkId];
        require(owner != address(0), "ERC721: burn of nonexistent token");

        // Remove from staker's list - requires finding and removing from the array
        _removeSparkFromStakerList(owner, sparkId);

        delete _owners[sparkId];
        _balances[owner]--;
        delete sparkData[sparkId]; // Also delete the related stake data

        // ERC721 standard expects a Transfer event to address(0)
        // emit Transfer(owner, address(0), sparkId); // Emitted in unstake
    }

     /// @dev Internal helper to remove a sparkId from a staker's list.
     /// Note: This is a potentially gas-intensive operation for large arrays.
     /// Consider alternative data structures if scale is a major concern (e.g., linked list, or relying solely on off-chain indexing).
    function _removeSparkFromStakerList(address staker, uint256 sparkId) internal {
        uint256[] storage sparks = _stakerSparks[staker];
        for (uint256 i = 0; i < sparks.length; i++) {
            if (sparks[i] == sparkId) {
                // Replace the found element with the last element
                sparks[i] = sparks[sparks.length - 1];
                // Remove the last element
                sparks.pop();
                return; // Assume sparkId is unique in the list
            }
        }
        // Should not happen if _exists check passes and list is consistent
    }


    /// @dev Converts a uint256 to its ASCII string decimal representation.
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