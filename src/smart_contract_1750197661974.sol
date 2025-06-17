Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts centered around dynamic, evolving NFTs (Proto-Assets) managed within a staking and interaction platform ("ChronoForge") powered by a custom token ($CATALYST).

The concept is that users mint NFTs (Proto-Assets) with on-chain parameters. These NFTs can be staked in the contract to accrue "Evolution Potential". Users then spend a custom $CATALYST token and consume Evolution Potential to trigger an "evolution" event for their staked NFT, which deterministically (or pseudo-deterministically based on inputs/state) modifies the NFT's on-chain parameters, making it dynamic and unique based on its history and interactions within the system. There's also a discovery mechanism for finding rare parameter combinations.

This avoids directly copying standard AMM, lending, or simple staking contracts by focusing on dynamic on-chain asset state transformation controlled by user interaction and a custom tokenomic loop.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. Contract Definition & Inheritances
// 2. Custom Error Definitions
// 3. State Variables:
//    - Token metadata & counters (ERC721)
//    - CATALYST token (ERC20 instance)
//    - Proto-Asset Parameters mapping
//    - Staking information mapping
//    - Global ChronoForge parameters mapping
//    - Discovery patterns mapping
//    - Collected Fees
// 4. Structs:
//    - ProtoAssetParameters: Defines the mutable on-chain state of an NFT.
//    - StakeInfo: Tracks staking details for an NFT.
// 5. Enums:
//    - GlobalParamType: Defines types of configurable parameters.
//    - TraitType (Example): Defines types of parameters within ProtoAssetParameters.
// 6. Events: Crucial for off-chain monitoring and interaction.
// 7. Constructor: Initializes contracts, minters, etc.
// 8. ERC721 Standard Functions (inherited/implemented): balanceOf, ownerOf, safeTransferFrom, etc.
// 9. ERC20 Standard Functions (internal management or inherited): transfer, approve, transferFrom, balanceOf, etc.
// 10. Core ChronoForge/Proto-Asset Functions (Custom Logic):
//     - Minting Proto-Assets
//     - Staking/Unstaking Proto-Assets
//     - Calculating Evolution Potential
//     - Triggering Proto-Asset Evolution
//     - Querying Proto-Asset state
//     - Managing Global ChronoForge Parameters
//     - Discovery Mechanism
//     - CATALYST Token Management (Minting, Burning, Fee Collection)
// 11. Helper Functions

// Function Summary:
// --- ERC721 & Core ---
// constructor(): Initializes the contract, ERC20 token, and ownership.
// supportsInterface(bytes4 interfaceId): ERC165 standard for interface detection.
// balanceOf(address owner): ERC721 standard - returns number of tokens owned by address.
// ownerOf(uint256 tokenId): ERC721 standard - returns owner of a specific token.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard - safe transfer.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721 standard - safe transfer with data.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard - transfer token.
// approve(address to, uint256 tokenId): ERC721 standard - grants approval for one token.
// setApprovalForAll(address operator, bool approved): ERC721 standard - grants approval for all tokens.
// getApproved(uint256 tokenId): ERC721 standard - returns the approved address for a token.
// isApprovedForAll(address owner, address operator): ERC721 standard - checks if operator has approval for all tokens.
// tokenURI(uint256 tokenId): ERC721 standard - returns the metadata URI for a token. (Placeholder logic).
// getTokenParameters(uint256 tokenId): Gets the current on-chain parameters of a Proto-Asset.
// --- CATALYST Token (Managed Internally/Via Instance) ---
// getCatalystBalance(address account): Returns CATALYST balance of an account.
// mintCatalystTo(address to, uint256 amount): Owner function to mint CATALYST.
// burnCatalystFrom(address account, uint256 amount): Owner function to burn CATALYST from an account.
// transferCatalyst(address to, uint256 amount): User function to transfer CATALYST. (Requires `approve` if contract calls).
// --- Staking & Evolution ---
// mintProtoAsset(uint256 initialTraitA, uint256 initialTraitB, uint256 initialTraitC): Mints a new Proto-Asset with initial parameters. Costs CATALYST.
// stakeProtoAsset(uint256 tokenId): Stakes an owned Proto-Asset in the contract to accrue potential.
// unstakeProtoAsset(uint256 tokenId): Unstakes a Proto-Asset. Consumes/decays potential based on stake duration.
// getProtoAssetStakeInfo(uint256 tokenId): Gets detailed staking information for a Proto-Asset.
// calculateCurrentEvolutionPotential(uint256 tokenId): Calculates the accrued Evolution Potential for a staked asset.
// evolveProtoAsset(uint256 tokenId, bytes32 evolutionSeed): Triggers evolution. Costs CATALYST and potential. Modifies on-chain parameters.
// canEvolve(uint256 tokenId): Checks if a token meets basic requirements for evolution (staked, potential, CATALYST allowance).
// getTotalStakedAssets(): Returns the total number of staked Proto-Assets.
// --- ChronoForge Management ---
// setGlobalEvolutionParameter(GlobalParamType paramType, uint256 value): Owner function to set global rules affecting potential accrual, costs, etc.
// getGlobalEvolutionParameter(GlobalParamType paramType): Gets the value of a global parameter.
// getMinEvolutionPotential(): Convenience getter for minimum potential required for evolution.
// getEvolutionCatalystCost(): Convenience getter for CATALYST cost of evolution.
// --- Discovery Mechanism ---
// registerDiscoveryPattern(bytes32 patternHash, string memory discoveryName, uint256 catalystReward): Owner function to register a pattern that grants a reward.
// triggerDiscoveryCheck(uint256 tokenId): Checks if an asset's current parameters match a registered pattern and awards reward if applicable. Costs CATALYST to check.
// --- Protocol Fees ---
// withdrawProtocolFees(): Owner function to withdraw collected CATALYST fees.
// getCollectedFees(): Returns the amount of CATALYST fees collected.

contract ChronoForge is ERC721, IERC721Receiver, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Custom Errors
    error NotStaked(uint256 tokenId);
    error AlreadyStaked(uint256 tokenId);
    error NotOriginalOwnerOrApproved(uint256 tokenId);
    error InsufficientEvolutionPotential(uint256 tokenId, uint256 required, uint256 available);
    error InsufficientCatalystAllowance(address owner, uint256 required, uint256 available);
    error InvalidParameterType(uint256 paramType);
    error DiscoveryPatternAlreadyRegistered(bytes32 patternHash);
    error DiscoveryPatternNotFound(bytes32 patternHash);
    error NotEnoughCatalystToMint(uint256 required, uint256 available);
    error NotEnoughCatalystToBurn(uint256 required, uint256 available);
    error NotEnoughCatalystForEvolution(uint256 required, uint256 available);
    error NotEnoughCatalystForDiscoveryCheck(uint256 required, uint256 available);
    error NothingToWithdraw();

    // State Variables
    Counters.Counter private _tokenIdCounter;

    // Custom ERC20 implementation/instance for CATALYST
    // Option 1: Inherit ERC20 (simpler, standard)
    // Option 2: Manual management (more complex, but shows interaction)
    // Let's use Option 1 for better standard compliance and security.
    // But we need a name/symbol. Let's define them here and pass to constructor.
    string public constant CATALYST_TOKEN_NAME = "ChronoForge Catalyst";
    string public constant CATALYST_TOKEN_SYMBOL = "CATALYST";
    ERC20 private _catalystToken;

    // On-chain parameters for each Proto-Asset
    struct ProtoAssetParameters {
        uint256 traitA; // Example parameter 1 (e.g., color hue)
        uint256 traitB; // Example parameter 2 (e.g., shape complexity)
        uint256 traitC; // Example parameter 3 (e.g., energy level)
        // Add more parameters as needed for complexity...
        uint256 lastEvolutionTime; // Timestamp of the last evolution
        uint256 evolutionCount; // How many times this asset evolved
    }
    mapping(uint256 => ProtoAssetParameters) private _tokenParameters;

    // Staking information for staked Proto-Assets
    struct StakeInfo {
        address originalOwner; // The address that staked the token
        uint64 stakeStartTime; // Timestamp when the token was staked
        uint256 potentialAccrued; // Accumulated potential at last update/calculation
        uint64 lastPotentialUpdateTime; // Timestamp of last potential update
        bool isStaked;
    }
    mapping(uint256 => StakeInfo) private _stakeInfo;
    mapping(address => uint256) private _stakedAssetCount; // Track staked assets per owner
    uint256 private _totalStakedAssets; // Total number of staked assets

    // Global configurable parameters affecting ChronoForge mechanics
    enum GlobalParamType {
        PotentialAccrualRate,       // How much potential accrues per second
        EvolutionCatalystCost,      // CATALYST required per evolution
        MinEvolutionPotential,      // Minimum potential needed to evolve
        UnstakePotentialDecayFactor,// Factor for potential decay if unstaked early (e.g., basis points)
        UnstakeDecayStakeDuration,  // Minimum stake duration to avoid decay (seconds)
        EvolutionParameterMagnitude // How much parameters change during evolution
    }
    mapping(uint256 => uint256) private _globalParams; // Uses uint256(GlobalParamType) as key

    // Discovery mechanism: Map pattern hash to Discovery details
    struct DiscoveryPattern {
        string name;
        uint256 catalystReward;
        bool found; // Has this pattern been found by anyone? (Optional: make it per-user or global)
    }
    mapping(bytes32 => DiscoveryPattern) private _discoveryPatterns;

    // Collected CATALYST fees from evolutions and discovery checks
    uint256 private _collectedCatalystFees;

    // Events
    event ProtoAssetMinted(uint256 indexed tokenId, address indexed owner, ProtoAssetParameters initialParams);
    event ProtoAssetStaked(uint256 indexed tokenId, address indexed owner, uint64 stakeTime);
    event ProtoAssetUnstaked(uint256 indexed tokenId, address indexed owner, uint256 potentialUsed);
    event EvolutionTriggered(uint256 indexed tokenId, address indexed caller, uint256 potentialConsumed, uint256 catalystBurned, ProtoAssetParameters newParams);
    event GlobalParameterSet(GlobalParamType indexed paramType, uint256 indexed newValue);
    event DiscoveryPatternRegistered(bytes32 indexed patternHash, string name, uint256 catalystReward);
    event DiscoveryFound(uint256 indexed tokenId, address indexed finder, bytes32 indexed patternHash, uint256 rewardAmount);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialCatalystSupply)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        // Deploy the ERC20 CATALYST token
        _catalystToken = new ERC20(CATALYST_TOKEN_NAME, CATALYST_TOKEN_SYMBOL);

        // Mint initial supply to the contract owner or a designated address
        _catalystToken.mint(msg.sender, initialCatalystSupply); // Assuming ERC20 has a mint function accessible by deployer

        // Set initial global parameters (example values)
        _globalParams[uint256(GlobalParamType.PotentialAccrualRate)] = 10; // 10 potential per second
        _globalParams[uint256(GlobalParamType.EvolutionCatalystCost)] = 100 * (10**_catalystToken.decimals()); // 100 CATALYST per evolution
        _globalParams[uint256(GlobalParamType.MinEvolutionPotential)] = 6000; // Need 6000 potential (10 mins staked @ rate 10)
        _globalParams[uint256(GlobalParamType.UnstakePotentialDecayFactor)] = 5000; // 50% decay (5000 out of 10000 basis points)
        _globalParams[uint256(GlobalParamType.UnstakeDecayStakeDuration)] = 1 days; // Decay applies if staked for less than 1 day
        _globalParams[uint256(GlobalParamType.EvolutionParameterMagnitude)] = 100; // Max change magnitude for params
    }

    // --- ERC721 Standard Implementations & Overrides ---
    // ERC721 from OpenZeppelin provides most of these.
    // We just need to override `tokenURI` and potentially `_update`/`_burn` if we add complex state changes there.
    // For this example, we focus on the custom logic functions.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Standard check

        // Placeholder logic for metadata URI.
        // In a real app, this would point to an API returning a JSON based on on-chain parameters.
        // Example: "ipfs://[metadata_base_uri]/[tokenId]" or an API gateway URL.
        // The API would read the parameters via web3 and generate the metadata/image.
        string memory baseURI = "ipfs://placeholder_base_uri/"; // Replace with actual URI base
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // Required for `safeTransferFrom` into this contract
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        // When staking, the user calls `approve` on the NFT, then calls `stakeProtoAsset`.
        // The `stakeProtoAsset` function calls `safeTransferFrom` internally.
        // This function is the receiving hook. We just return the selector to indicate acceptance.
        return this.onERC721Received.selector;
    }

    // --- CATALYST Token Interaction Functions ---
    // Note: Standard ERC20 functions like `transfer`, `approve`, `transferFrom`, `balanceOf` are handled
    // by the internal `_catalystToken` instance which users interact with directly
    // using the address returned by `catalystTokenAddress()`.
    // We expose helper getters and owner functions here.

    function catalystTokenAddress() public view returns (address) {
        return address(_catalystToken);
    }

    function getCatalystBalance(address account) public view returns (uint256) {
        return _catalystToken.balanceOf(account);
    }

    function mintCatalystTo(address to, uint256 amount) public onlyOwner {
        _catalystToken.mint(to, amount); // Assumes _catalystToken is an ERC20 with minting
    }

    function burnCatalystFrom(address account, uint256 amount) public onlyOwner {
        _catalystToken.burn(account, amount); // Assumes _catalystToken is an ERC20 with burning
    }

    // --- Staking & Evolution Functions ---

    /**
     * @notice Mints a new Proto-Asset NFT with initial parameters.
     * @param initialTraitA Initial value for trait A.
     * @param initialTraitB Initial value for trait B.
     * @param initialTraitC Initial value for trait C.
     * @dev Requires the caller to have and approve ChronoForge contract to spend the CATALYST minting cost.
     */
    function mintProtoAsset(uint256 initialTraitA, uint256 initialTraitB, uint256 initialTraitC) public {
        uint256 mintCost = 10 * (10**_catalystToken.decimals()); // Example: 10 CATALYST to mint
        if (_catalystToken.balanceOf(msg.sender) < mintCost) {
            revert NotEnoughCatalystToMint(mintCost, _catalystToken.balanceOf(msg.sender));
        }
        // Use transferFrom pattern: user approves contract to spend, contract spends
        _catalystToken.transferFrom(msg.sender, address(this), mintCost);

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        _tokenParameters[newItemId] = ProtoAssetParameters({
            traitA: initialTraitA,
            traitB: initialTraitB,
            traitC: initialTraitC,
            lastEvolutionTime: uint256(block.timestamp), // Initialize this
            evolutionCount: 0
        });

        // Add mint cost to collected fees
        _collectedCatalystFees = _collectedCatalystFees.add(mintCost);

        emit ProtoAssetMinted(newItemId, msg.sender, _tokenParameters[newItemId]);
    }

    /**
     * @notice Stakes an owned Proto-Asset in the ChronoForge.
     * @param tokenId The ID of the Proto-Asset to stake.
     * @dev Transfers the NFT to the contract. Requires caller to own the token and approve the contract.
     */
    function stakeProtoAsset(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Caller must own the token to stake");
        if (_stakeInfo[tokenId].isStaked) {
            revert AlreadyStaked(tokenId);
        }

        // Standard ERC721 transfer to the contract address
        _transfer(msg.sender, address(this), tokenId);

        _stakeInfo[tokenId] = StakeInfo({
            originalOwner: msg.sender,
            stakeStartTime: uint64(block.timestamp),
            potentialAccrued: 0, // Potential starts accruing from now
            lastPotentialUpdateTime: uint64(block.timestamp),
            isStaked: true
        });

        _stakedAssetCount[msg.sender] = _stakedAssetCount[msg.sender].add(1);
        _totalStakedAssets = _totalStakedAssets.add(1);

        emit ProtoAssetStaked(tokenId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Unstakes a Proto-Asset from the ChronoForge.
     * @param tokenId The ID of the Proto-Asset to unstake.
     * @dev Transfers the NFT back to the original staker. Potential may decay if staked for a short duration.
     */
    function unstakeProtoAsset(uint256 tokenId) public {
        StakeInfo storage stake = _stakeInfo[tokenId];
        if (!stake.isStaked) {
            revert NotStaked(tokenId);
        }

        // Only original staker or someone approved by them can unstake
        require(msg.sender == stake.originalOwner || isApprovedForAll(stake.originalOwner, msg.sender), "Caller not original owner or approved");

        // Calculate potential earned up to this point
        uint256 currentPotential = calculateCurrentEvolutionPotential(tokenId);

        // Apply decay if staked for less than the decay duration
        uint256 effectivePotential = currentPotential;
        uint256 stakeDuration = uint256(block.timestamp) - stake.stakeStartTime;
        uint256 decayDuration = _globalParams[uint256(GlobalParamType.UnstakeDecayStakeDuration)];
        uint256 decayFactor = _globalParams[uint256(GlobalParamType.UnstakePotentialDecayFactor)];

        if (stakeDuration < decayDuration && decayFactor > 0) {
             // Simple linear decay for demonstration
             // Max decay at 0 duration, 0 decay at decayDuration
             uint256 decayMultiplier = stakeDuration.mul(10000).div(decayDuration); // Basis points
             effectivePotential = effectivePotential.mul(decayMultiplier).div(10000);
        }

        // Transfer NFT back to the original owner
        _safeTransfer(address(this), stake.originalOwner, tokenId, ""); // Use _safeTransfer for safety

        // Clear staking info
        delete _stakeInfo[tokenId];

        _stakedAssetCount[stake.originalOwner] = _stakedAssetCount[stake.originalOwner].sub(1);
        _totalStakedAssets = _totalStakedAssets.sub(1);

        emit ProtoAssetUnstaked(tokenId, stake.originalOwner, currentPotential - effectivePotential); // Emit lost potential
    }

    /**
     * @notice Gets detailed staking information for a Proto-Asset.
     * @param tokenId The ID of the Proto-Asset.
     * @return StakeInfo struct containing staking details.
     */
    function getProtoAssetStakeInfo(uint256 tokenId) public view returns (StakeInfo memory) {
         if (!_stakeInfo[tokenId].isStaked) {
            // Return a zeroed struct or revert, reverting is clearer.
            // If returning, check .isStaked to know if it's valid.
            // Let's just return the struct, caller checks isStaked.
            // revert NotStaked(tokenId); // Or handle gracefully
         }
         return _stakeInfo[tokenId];
    }

    /**
     * @notice Calculates the current accrued Evolution Potential for a staked asset.
     * @param tokenId The ID of the staked Proto-Asset.
     * @return The current calculated Evolution Potential.
     */
    function calculateCurrentEvolutionPotential(uint256 tokenId) public view returns (uint256) {
        StakeInfo storage stake = _stakeInfo[tokenId];
        if (!stake.isStaked) {
             return 0; // Not staked, no potential accrual
        }

        uint256 timeSinceLastUpdate = uint256(block.timestamp) - stake.lastPotentialUpdateTime;
        uint256 potentialRate = _globalParams[uint256(GlobalParamType.PotentialAccrualRate)];

        // Potential = Potential accrued at last update + (time elapsed * rate)
        return stake.potentialAccrued.add(timeSinceLastUpdate.mul(potentialRate));
    }

    /**
     * @notice Triggers the evolution process for a staked Proto-Asset.
     * @param tokenId The ID of the Proto-Asset to evolve.
     * @param evolutionSeed A unique seed provided by the caller (e.g., a hash of their desired input).
     * @dev Consumes Evolution Potential and CATALYST. Modifies the asset's on-chain parameters.
     */
    function evolveProtoAsset(uint256 tokenId, bytes32 evolutionSeed) public {
        StakeInfo storage stake = _stakeInfo[tokenId];
         if (!stake.isStaked) {
            revert NotStaked(tokenId);
        }

        // Check if caller is the original staker or approved by them
        require(msg.sender == stake.originalOwner || isApprovedForAll(stake.originalOwner, msg.sender), "Caller not original owner or approved");

        uint256 minPotential = _globalParams[uint256(GlobalParamType.MinEvolutionPotential)];
        uint256 currentPotential = calculateCurrentEvolutionPotential(tokenId);

        if (currentPotential < minPotential) {
            revert InsufficientEvolutionPotential(tokenId, minPotential, currentPotential);
        }

        uint256 evolutionCost = _globalParams[uint256(GlobalParamType.EvolutionCatalystCost)];
        if (_catalystToken.allowance(msg.sender, address(this)) < evolutionCost) {
             revert InsufficientCatalystAllowance(msg.sender, evolutionCost, _catalystToken.allowance(msg.sender, address(this)));
        }

         // Consume CATALYST fee - use transferFrom as user approved this contract
        _catalystToken.transferFrom(msg.sender, address(this), evolutionCost);
        _collectedCatalystFees = _collectedCatalystFees.add(evolutionCost); // Add cost to fee pool

        // --- Evolution Logic ---
        ProtoAssetParameters storage params = _tokenParameters[tokenId];
        uint256 potentialConsumed = currentPotential; // Consume all available potential for max effect? Or a fixed amount? Let's consume required minimum + small bonus? Or just the minimum.
        uint256 potentialToUse = minPotential; // Let's consume just the minimum required

        // Update stake info: reduce potential by amount consumed, update last potential update time
        stake.potentialAccrued = currentPotential.sub(potentialToUse); // Subtract potential used
        stake.lastPotentialUpdateTime = uint64(block.timestamp);

        // Simple pseudo-deterministic parameter modification based on:
        // 1. Current block data (timestamp, number) - Caution: miners can influence!
        // 2. The provided evolutionSeed
        // 3. The current parameters
        // 4. Global magnitude parameter
        // This is simplified on-chain logic. For real-world, consider oracles or commit/reveal for randomness.
        bytes32 mix = keccak256(abi.encodePacked(block.timestamp, block.number, evolutionSeed, params.traitA, params.traitB, params.traitC));
        uint265 randomValue = uint256(mix);

        uint256 magnitude = _globalParams[uint256(GlobalParamType.EvolutionParameterMagnitude)];

        // Example parameter updates (replace with more complex/meaningful logic)
        params.traitA = (params.traitA + (randomValue % magnitude) + 1) % 256; // Example trait value range 0-255
        params.traitB = (params.traitB + ((randomValue >> 8) % magnitude) + 1) % 256;
        params.traitC = (params.traitC + ((randomValue >> 16) % magnitude) + 1) % 256;

        params.lastEvolutionTime = uint256(block.timestamp);
        params.evolutionCount = params.evolutionCount.add(1);

        // --- End Evolution Logic ---

        emit EvolutionTriggered(tokenId, msg.sender, potentialToUse, evolutionCost, params);
    }

    /**
     * @notice Checks if a staked token meets the basic requirements to attempt evolution.
     * @param tokenId The ID of the Proto-Asset.
     * @return bool indicating if evolution is possible.
     */
    function canEvolve(uint256 tokenId) public view returns (bool) {
        StakeInfo storage stake = _stakeInfo[tokenId];
        if (!stake.isStaked) {
            return false;
        }
        uint256 minPotential = _globalParams[uint256(GlobalParamType.MinEvolutionPotential)];
        uint256 currentPotential = calculateCurrentEvolutionPotential(tokenId);
        if (currentPotential < minPotential) {
            return false;
        }
        uint256 evolutionCost = _globalParams[uint256(GlobalParamType.EvolutionCatalystCost)];
        // Check original owner's allowance or balance if contract pulls
        // Assuming contract pulls via transferFrom, check allowance
        if (_catalystToken.allowance(stake.originalOwner, address(this)) < evolutionCost) {
             return false;
        }
        return true;
    }


     /**
      * @notice Gets the current on-chain parameters of a Proto-Asset.
      * @param tokenId The ID of the Proto-Asset.
      * @return ProtoAssetParameters struct.
      */
    function getProtoAssetParameters(uint256 tokenId) public view returns (ProtoAssetParameters memory) {
        // Check if token exists (implicitly done by _exists in OZ ERC721, but explicit check is clearer)
        if (!_exists(tokenId)) {
             // Return a zeroed struct or revert. Returning zeroed is okay here.
             return ProtoAssetParameters(0,0,0,0,0);
        }
        return _tokenParameters[tokenId];
    }

    /**
     * @notice Gets the total number of Proto-Assets currently staked in the contract.
     * @return Total number of staked assets.
     */
    function getTotalStakedAssets() public view returns (uint256) {
        return _totalStakedAssets;
    }

    // --- ChronoForge Management Functions (Owner Only) ---

    /**
     * @notice Sets a global parameter that influences ChronoForge mechanics.
     * @param paramType The type of parameter to set (from GlobalParamType enum).
     * @param value The new value for the parameter.
     */
    function setGlobalEvolutionParameter(GlobalParamType paramType, uint256 value) public onlyOwner {
        // Optional: Add validation based on paramType (e.g., rates shouldn't be astronomically high)
        _globalParams[uint256(paramType)] = value;
        emit GlobalParameterSet(paramType, value);
    }

    /**
     * @notice Gets the value of a global ChronoForge parameter.
     * @param paramType The type of parameter to get.
     * @return The value of the parameter.
     */
    function getGlobalEvolutionParameter(GlobalParamType paramType) public view returns (uint256) {
        // Simple getter, no validation needed unless paramType is invalid (which map handles)
        return _globalParams[uint256(paramType)];
    }

    /**
     * @notice Convenience getter for the minimum potential required for evolution.
     */
    function getMinEvolutionPotential() public view returns (uint256) {
        return _globalParams[uint256(GlobalParamType.MinEvolutionPotential)];
    }

    /**
     * @notice Convenience getter for the CATALYST cost of evolution.
     */
    function getEvolutionCatalystCost() public view returns (uint256) {
        return _globalParams[uint256(GlobalParamType.EvolutionCatalystCost)];
    }

    // --- Discovery Mechanism Functions ---

    /**
     * @notice Registers a new discovery pattern and associated reward.
     * @param patternHash A hash representing the target parameter combination.
     * @param discoveryName A human-readable name for the discovery.
     * @param catalystReward The amount of CATALYST rewarded upon discovery.
     */
    function registerDiscoveryPattern(bytes32 patternHash, string memory discoveryName, uint256 catalystReward) public onlyOwner {
        if (_discoveryPatterns[patternHash].catalystReward > 0) { // Check if reward is set, implying pattern exists
            revert DiscoveryPatternAlreadyRegistered(patternHash);
        }
        _discoveryPatterns[patternHash] = DiscoveryPattern(discoveryName, catalystReward, false); // Mark as not found yet
        emit DiscoveryPatternRegistered(patternHash, discoveryName, catalystReward);
    }

    /**
     * @notice Triggers a check to see if a Proto-Asset's parameters match a discovery pattern.
     * @param tokenId The ID of the Proto-Asset to check.
     * @dev Costs CATALYST to perform the check. Rewards if a matching, unfound pattern is discovered.
     */
    function triggerDiscoveryCheck(uint256 tokenId) public {
        // Caller must be the owner or approved
        _requireOwned(tokenId); // This check covers staked tokens too as contract is owner
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Caller not owner or approved");

        uint256 checkCost = 5 * (10**_catalystToken.decimals()); // Example: 5 CATALYST to check
        if (_catalystToken.allowance(msg.sender, address(this)) < checkCost) {
             revert InsufficientCatalystAllowance(msg.sender, checkCost, _catalystToken.allowance(msg.sender, address(this)));
        }

         // Consume CATALYST fee for the check
        _catalystToken.transferFrom(msg.sender, address(this), checkCost);
        _collectedCatalystFees = _collectedCatalystFees.add(checkCost); // Add cost to fee pool

        // Calculate the hash of the current parameters
        ProtoAssetParameters memory params = _tokenParameters[tokenId];
        bytes32 currentPatternHash = keccak256(abi.encodePacked(params.traitA, params.traitB, params.traitC)); // Hash based on relevant traits

        // Check if this hash matches any registered pattern that hasn't been found globally
        DiscoveryPattern storage pattern = _discoveryPatterns[currentPatternHash];

        if (pattern.catalystReward > 0 && !pattern.found) {
            // Discovery found!
            pattern.found = true; // Mark as found (globally)
            uint256 reward = pattern.catalystReward;

            // Mint/Transfer reward to the discoverer (the original owner if staked, or current owner if not staked)
            // Let's reward the *caller* for simplicity, as they paid the check cost.
            _catalystToken.mint(msg.sender, reward); // Assuming minting is allowed for rewards

            emit DiscoveryFound(tokenId, msg.sender, currentPatternHash, reward);
        } else {
             // No discovery or already found. No reward.
             // Could emit a "DiscoveryChecked" event even if not found.
        }
    }

    // --- Protocol Fee Management ---

    /**
     * @notice Allows the contract owner to withdraw collected CATALYST fees.
     */
    function withdrawProtocolFees() public onlyOwner {
        uint256 fees = _collectedCatalystFees;
        if (fees == 0) {
            revert NothingToWithdraw();
        }
        _collectedCatalystFees = 0;
        // Transfer fees to the owner
        _catalystToken.transfer(msg.sender, fees);
        emit FeesWithdrawn(msg.sender, fees);
    }

     /**
      * @notice Gets the total amount of CATALYST fees collected by the contract.
      */
    function getCollectedFees() public view returns (uint256) {
        return _collectedCatalystFees;
    }

    // --- Helper Functions (Example) ---
    // Could add functions like:
    // - getTraitDescription(uint256 traitType, uint256 traitValue) view returns (string memory)
    // - hashParameters(ProtoAssetParameters memory params) pure returns (bytes32)

    // Fallback/Receive - good practice to include if you expect ETH transfers
    // receive() external payable {}
    // fallback() external payable {}

    // Add any additional internal or external functions as needed...
}
```

**Explanation of Concepts:**

1.  **Dynamic On-Chain State (Proto-Asset Parameters):** Instead of NFTs just pointing to external metadata, key attributes (`traitA`, `traitB`, `traitC`, etc.) are stored directly on the blockchain within the `_tokenParameters` mapping.
2.  **Staking for Potential Accrual (ChronoForge):** NFTs can be locked within the contract (`stakeProtoAsset`). While staked, they accumulate "Evolution Potential" over time based on a global rate (`PotentialAccrualRate`). This potential is stored and calculated dynamically.
3.  **Custom Token ($CATALYST):** A dedicated ERC20 token (`_catalystToken`) is created and managed by the contract. This token is central to interactions – required for minting, evolution, and discovery checks.
4.  **Controlled On-Chain Evolution:** The `evolveProtoAsset` function is the core mechanic.
    *   It requires the staked NFT to have accumulated sufficient `EvolutionPotential`.
    *   It requires the caller to pay a fee in $CATALYST (using the standard ERC20 `approve`/`transferFrom` pattern).
    *   It consumes the potential and the CATALYST.
    *   It *modifies* the NFT's on-chain `ProtoAssetParameters` based on a calculation involving current parameters, global settings, consumed potential, and a user-provided `evolutionSeed`. This makes the evolution process influenced by both system state and user input, and permanently changes the NFT's state.
5.  **Configurable Global Parameters:** The `_globalParams` mapping allows the owner (or a future governance mechanism) to adjust key system variables like potential accrual rate, evolution costs, minimum potential, etc., introducing economic and gameplay balancing levers.
6.  **Discovery Mechanism:** The `triggerDiscoveryCheck` function adds a unique layer. Users can pay $CATALYST to check if their NFT's *current* parameter combination matches a predefined, rare pattern (`_discoveryPatterns`). If a match is found for a pattern that hasn't been discovered before, the user receives a $CATALYST reward. This encourages users to evolve their assets in search of rare states.
7.  **Protocol Fees:** CATALYST spent on minting, evolution, and discovery checks is collected by the contract (`_collectedCatalystFees`) and can be withdrawn by the owner. This creates a potential revenue stream for the protocol, which could later be directed to a DAO treasury or stakers.
8.  **Safe ERC721 Handling:** Uses OpenZeppelin's battle-tested ERC721 implementation and `IERC721Receiver` for secure token transfers.
9.  **Standard ERC20 Interaction:** Interacts with the CATALYST token using standard ERC20 functions, requiring users to `approve` the ChronoForge contract to spend tokens on their behalf for actions like minting, evolving, or checking discovery.

This contract goes beyond simple tokenization or static NFTs by implementing a core loop of staking, potential accrual, token spending, and on-chain state transformation driven by user action and protocol parameters, while adding a unique discovery game layer.

To deploy this, you would need the OpenZeppelin contracts library installed in your development environment (`npm install @openzeppelin/contracts`).