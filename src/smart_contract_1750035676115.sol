Okay, here is a complex, creative, and feature-rich smart contract concept called "EcoVerse Ecosystem". It combines elements of NFTs, utility tokens, resource generation, environmental simulation (via a pollution index), and game-like mechanics like nurturing and recycling.

It uses OpenZeppelin contracts for standard implementations (like ERC tokens and Access Control) but builds unique logic on top of them. The combination of dynamic yields based on a global state variable (`pollutionIndex`), the multi-stage `nurtureNode` process with pseudo-randomness, and the interaction between different token types (`EcoPillar`, `NatureNode`, `Catalyst`, `BioToken`) creates a novel system not commonly found as a single open-source template.

---

## EcoVerse Ecosystem Smart Contract

This contract manages a simulated ecological ecosystem on the blockchain. It involves multiple types of tokens representing assets and resources, interacting through various on-chain actions that influence a global "Pollution Index".

### Outline:

1.  **Licensing and Imports:** SPDX License, Solidity version, OpenZeppelin imports.
2.  **Error Definitions:** Custom errors for clarity.
3.  **Role Definitions:** Constants for AccessControl roles.
4.  **Token Definitions:** Constants for ERC1155 Catalyst types.
5.  **State Variables:**
    *   Token contract instances (implicitly managed by inheritance).
    *   Staking/Operating information for EcoPillars and NatureNodes.
    *   Global Pollution Index and related parameters.
    *   NatureNode level mapping.
    *   Ecosystem Parameters (yield rates, nurture costs/probs, recycle rewards, cleanse costs).
    *   Treasury address.
    *   Pseudo-random seed/counter.
6.  **Events:** To log significant actions.
7.  **Constructor:** Initializes tokens, roles, and initial parameters.
8.  **Access Control Functions:** Grant/revoke roles (inherited).
9.  **Pause Functions:** Pause/unpause core actions (inherited).
10. **Core Ecosystem Actions:**
    *   Staking/Unstaking/Claiming for EcoPillars.
    *   Activating/Deactivating/Claiming for NatureNodes.
    *   `nurtureNode`: Complex function to attempt creating/upgrading NatureNodes.
    *   `recycleAsset`: Burn assets for BioTokens.
    *   `pollute`: Increase Pollution Index (negative action).
    *   `cleanse`: Decrease Pollution Index (positive action).
11. **Admin/Parameter Adjustment Functions:** Set various ecosystem parameters.
12. **Minting Functions:** Controlled minting of initial/special assets.
13. **Treasury Management:** Withdraw collected BioTokens.
14. **View Functions:** Get state information, calculate potential rewards.
15. **Internal Helper Functions:** Reward calculation logic, pollution index updates, pseudo-random generation.

### Function Summary (> 20 Functions):

1.  `constructor()`: Initializes the contract, deploys ERC20, ERC721s, ERC1155, sets up roles and initial parameters.
2.  `grantRole(bytes32 role, address account)`: Admin: Grants a role to an address. (Inherited from AccessControl)
3.  `revokeRole(bytes32 role, address account)`: Admin: Revokes a role from an address. (Inherited from AccessControl)
4.  `pause()`: Pauser Role: Pauses core ecosystem actions. (Inherited from Pausable)
5.  `unpause()`: Pauser Role: Unpauses core ecosystem actions. (Inherited from Pausable)
6.  `mintEcoPillar(address to)`: Minter Role: Mints a new EcoPillar NFT to an address. Limited supply.
7.  `mintNatureNode(address to, uint256 initialLevel)`: Minter Role: Mints a new NatureNode NFT to an address at a specified level.
8.  `mintCatalyst(address to, uint256 id, uint256 amount)`: Minter Role: Mints a specific type and amount of Catalyst tokens (ERC1155) to an address.
9.  `stakeEcoPillar(uint256 tokenId)`: Stakes an owned EcoPillar NFT to earn BioTokens. Calculates and claims any pending rewards before staking.
10. `unstakeEcoPillar(uint256 tokenId)`: Unstakes an EcoPillar NFT. Claims all pending BioTokens and returns the NFT.
11. `claimPillarStakingRewards(uint256 tokenId)`: Claims pending BioToken rewards for a staked EcoPillar without unstaking.
12. `activateNatureNode(uint256 tokenId)`: Activates an owned NatureNode NFT to earn BioTokens. Calculates and claims any pending rewards before activating.
13. `deactivateNatureNode(uint256 tokenId)`: Deactivates a NatureNode NFT. Claims all pending BioTokens and returns the NFT.
14. `claimNodeOperatingRewards(uint256 tokenId)`: Claims pending BioToken rewards for an active NatureNode without deactivating.
15. `nurtureNode(uint256 nodeToBurnId, uint256 catalystId)`: Attempts to nurture a new NatureNode. Requires burning an existing NatureNode (e.g., level 1), burning a Catalyst, and spending BioTokens. Outcome (success/failure and new node level) is determined pseudo-randomly, influenced by parameters. Fails might return partial cost.
16. `recycleAsset(uint256 assetType, uint256 tokenId)`: Burns an EcoPillar (assetType=1), NatureNode (assetType=2), or Catalyst (assetType=3, tokenId is actually catalyst ID here) token in exchange for BioTokens based on predefined recycle rates.
17. `pollute()`: A user action (requires BioToken payment or other cost?) that increases the global Pollution Index. May offer a small immediate reward, but negatively impacts all BioToken yields.
18. `cleanse(uint256 catalystId, uint256 amount)`: Burns a specific amount of a Catalyst type (and/or BioTokens) to decrease the global Pollution Index.
19. `setEcoPillarYieldPerSecond(uint256 yieldPerSec)`: Manager Role: Sets the base BioToken yield rate for staked EcoPillars.
20. `setNatureNodeBaseYieldPerSecond(uint256 baseYieldPerSec)`: Manager Role: Sets the base BioToken yield rate for activated NatureNodes (before level and pollution modifiers).
21. `setNodeLevelYieldMultiplier(uint256 level, uint256 multiplier)`: Manager Role: Sets the yield multiplier for a specific NatureNode level.
22. `setPollutionImpactParameters(uint256 maxPollution, uint256 pollutionIncreaseRate, uint256 pollutionDecreaseRate)`: Manager Role: Sets parameters for how pollution changes and impacts yield.
23. `setNurtureParameters(uint256 bioTokenCost, uint256 catalystCost, uint256 minLevelToBurn, uint256[] calldata successProbabilities)`: Manager Role: Sets costs and success probabilities for the `nurtureNode` function.
24. `setRecycleRewards(uint256 ecoPillarReward, uint256 natureNodeRewardBase, uint256 catalystReward)`: Manager Role: Sets the BioToken rewards for recycling different asset types. Node reward can be level-based.
25. `getPollutionIndex()`: View: Returns the current global Pollution Index.
26. `calculatePillarRewards(uint256 tokenId)`: View: Calculates the pending BioToken rewards for a specific staked EcoPillar.
27. `calculateNodeRewards(uint256 tokenId)`: View: Calculates the pending BioToken rewards for a specific active NatureNode.
28. `getNodeLevel(uint256 tokenId)`: View: Returns the level of a specific NatureNode.
29. `getTreasuryBalance()`: View: Returns the current BioToken balance held by the contract treasury.
30. `withdrawTreasury(address tokenAddress)`: Manager Role: Withdraws tokens (intended for BioToken, but flexible) from the contract's treasury to the owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors
error EcoVerse__NotOwnerOfStakedAsset();
error EcoVerse__NotOwnerOfActiveAsset();
error EcoVerse__PillarNotStaked();
error EcoVerse__NodeNotActive();
error EcoVerse__AssetAlreadyStaked();
error EcoVerse__AssetAlreadyActive();
error EcoVerse__InvalidAssetTypeForRecycle();
error EcoVerse__CannotNurtureLevel(uint256 level);
error EcoVerse__InsufficientFundsForNurture();
error EcoVerse__NurtureFailed();
error EcoVerse__PollutionIndexBounds();
error EcoVerse__NotEnoughCatalyst();
error EcoVerse__TreasuryWithdrawFailed();


contract EcoVerseEcosystem is ERC20, ERC721URIStorage, ERC1155, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Token Identifiers (ERC1155) ---
    uint256 public constant CATALYST_GROWTH = 1;
    uint256 public constant CATALYST_CLEANSE = 2;
    // Add more catalyst types as needed

    // --- Asset Types for Recycling ---
    uint256 public constant ASSET_ECO_PILLAR = 1;
    uint256 public constant ASSET_NATURE_NODE = 2;
    uint256 public constant ASSET_CATALYST = 3;

    // --- State Variables ---

    // BioToken (ERC20) state handled by inheritance

    // EcoPillar (ERC721) state handled by inheritance
    Counters.Counter private _pillarTokenIds;

    // NatureNode (ERC721) state handled by inheritance
    Counters.Counter private _nodeTokenIds;
    mapping(uint256 => uint256) private _nodeLevels; // NatureNodeId => Level

    // Catalyst (ERC1155) state handled by inheritance

    // Staking/Operating State
    struct StakingInfo {
        address owner;
        uint66 startTime; // Using uint66 for gas efficiency, max value covers ~146 trillion years
        uint256 yieldPerSecond;
        uint256 accumulatedRewards;
    }
    mapping(uint256 => StakingInfo) private _ecoPillarStaking; // EcoPillarId => Info
    mapping(uint256 => StakingInfo) private _natureNodeOperating; // NatureNodeId => Info

    // Pollution Index
    uint256 public pollutionIndex; // Current index value
    uint256 public maxPollutionIndex; // Maximum possible pollution
    uint256 public pollutionIncreaseRate; // Amount pollution increases per 'pollute' action
    uint256 public pollutionDecreaseRate; // Amount pollution decreases per 'cleanse' action per catalyst unit

    // Ecosystem Parameters
    uint256 public ecoPillarYieldPerSecond;
    uint256 public natureNodeBaseYieldPerSecond; // Base yield before level and pollution modifier
    mapping(uint256 => uint256) public nodeLevelYieldMultiplier; // NodeLevel => Multiplier (e.g., level 2 gives 1.5x base)

    // Nurturing Parameters
    uint256 public nurtureBioTokenCost;
    uint256 public nurtureCatalystGrowthCost; // Amount of CATALYST_GROWTH needed
    uint256 public nurtureMinNodeLevelToBurn; // Minimum level of node required to burn
    uint256[] public nurtureSuccessProbabilities; // Array of probabilities for getting level N+1, N+2, etc. (e.g., [7000, 2000, 1000] for 70% Lvl+1, 20% Lvl+2, 10% Lvl+3, assuming burn Lvl N) - Sum should be <= 10000 (100%)
    uint256 public nurtureFailureReturnPercentage; // Percentage of BioTokens returned on failure (0-10000)

    // Recycling Rewards (BioToken amounts)
    uint256 public recycleEcoPillarReward;
    uint256 public recycleNatureNodeRewardBase; // Base reward before level multiplier
    uint256 public recycleCatalystReward; // Reward per catalyst unit

    // Treasury
    address public treasuryAddress;

    // Pseudo-randomness (Caution: On-chain pseudo-randomness is not truly random and can be front-run)
    uint256 private _randomSeed;

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory pillarUri,
        string memory nodeUri,
        string memory catalystUri
    ) ERC20(name, symbol) ERC721("EcoPillar", "EP") ERC1155(catalystUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(MINTER_ROLE, msg.sender); // Deployer is initial minter
        _grantRole(MANAGER_ROLE, msg.sender); // Deployer is initial manager
        _grantRole(PAUSER_ROLE, msg.sender); // Deployer is initial pauser

        // Set initial token URIs for ERC721s
        _setBaseURI(pillarUri);
        _setBaseURI(nodeUri); // Note: ERC721URIStorage only supports one base URI per contract.
                               // For different token URIs per type (Pillar/Node), you might need
                               // separate contracts or a custom metadata resolver pointing to off-chain.
                               // We'll use the ERC721 base URI for Pillars and manage Node URI off-chain based on state.

        // Initialize ERC1155 URI separately
        _setURI(catalystUri);

        // Initialize ecosystem parameters (example values)
        maxPollutionIndex = 1000;
        pollutionIndex = maxPollutionIndex / 2; // Start neutral
        pollutionIncreaseRate = 10;
        pollutionDecreaseRate = 20;

        ecoPillarYieldPerSecond = 1 ether / 1000; // Example: 0.001 BioToken per second
        natureNodeBaseYieldPerSecond = 1 ether / 500; // Example: 0.002 BioToken per second
        nodeLevelYieldMultiplier[1] = 10000; // 1x (100%)
        nodeLevelYieldMultiplier[2] = 15000; // 1.5x (150%)
        nodeLevelYieldMultiplier[3] = 20000; // 2x (200%)
        // Add more multipliers for higher levels

        nurtureBioTokenCost = 10 ether;
        nurtureCatalystGrowthCost = 1;
        nurtureMinNodeLevelToBurn = 1;
        nurtureSuccessProbabilities = [7000, 2000, 1000]; // 70% Lvl+1, 20% Lvl+2, 10% Lvl+3 (assuming burn Lvl N)
        nurtureFailureReturnPercentage = 2000; // 20% return on failure

        recycleEcoPillarReward = 50 ether;
        recycleNatureNodeRewardBase = 5 ether; // This base can be multiplied by level off-chain or via a helper view
        recycleCatalystReward = 1 ether;

        treasuryAddress = address(this); // Initially contract holds treasury funds
        // Could set a separate treasury address if needed: treasuryAddress = msg.sender;

        _randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number)));
    }

    // --- Access Control Overrides (for visibility/documentation) ---
    // These functions are inherited from AccessControl and use the defined roles.
    // AccessControl has been made internal in recent OZ versions, expose these if needed externally
    // function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _grantRole(role, account);
    // }
    // function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _revokeRole(role, account);
    // }
    // function renounceRole(bytes32 role, address account) public virtual override {
    //    _renounceRole(role, account);
    // }


    // --- Pause Overrides ---
    function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    // --- Minting Functions ---
    function mintEcoPillar(address to) public onlyRole(MINTER_ROLE) {
        _pillarTokenIds.increment();
        uint256 newPillarId = _pillarTokenIds.current();
        _safeMint(to, newPillarId);
        // ERC721URIStorage._setTokenURI(newPillarId, <specific_uri_if_needed>);
    }

    function mintNatureNode(address to, uint256 initialLevel) public onlyRole(MINTER_ROLE) {
        _nodeTokenIds.increment();
        uint256 newNodeId = _nodeTokenIds.current();
        _safeMint(to, newNodeId);
        _nodeLevels[newNodeId] = initialLevel;
        // ERC721URIStorage._setTokenURI(newNodeId, <specific_uri_if_needed>); // Metadata server should read level
    }

    function mintCatalyst(address to, uint256 id, uint256 amount) public onlyRole(MINTER_ROLE) {
         if (id != CATALYST_GROWTH && id != CATALYST_CLEANSE) revert EcoVerse__InvalidAssetTypeForRecycle(); // Basic validation
        _mint(to, id, amount, "");
    }

    // --- Core Ecosystem Actions (Pausable) ---

    function stakeEcoPillar(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        if (_ecoPillarStaking[tokenId].startTime != 0) revert EcoVerse__AssetAlreadyStaked();

        // Claim potential residual rewards if asset was previously staked and unstaked without claiming
        // This shouldn't happen if unstake claims, but good practice
        // uint256 residualRewards = _calculateBioTokenRewards(_ecoPillarStaking[tokenId]);
        // if (residualRewards > 0) _transfer(address(this), msg.sender, residualRewards); // Transfer from contract balance

        _burn(tokenId); // Burn the NFT to stake it (or transfer to contract address if not burn-to-stake)
        // Option 1: Transfer to contract address
        // safeTransferFrom(msg.sender, address(this), tokenId);
        // Option 2: Burn (simpler state management for staked assets)
        // ERC721URIStorage allows burning

        _ecoPillarStaking[tokenId] = StakingInfo({
            owner: msg.sender,
            startTime: uint64(block.timestamp),
            yieldPerSecond: ecoPillarYieldPerSecond,
            accumulatedRewards: _ecoPillarStaking[tokenId].accumulatedRewards // Keep old accumulated if not claimed on unstake
        });

        emit EcoPillarStaked(tokenId, msg.sender, block.timestamp);
    }

    function unstakeEcoPillar(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingInfo storage info = _ecoPillarStaking[tokenId];
        if (info.startTime == 0) revert EcoVerse__PillarNotStaked();
        if (info.owner != msg.sender) revert EcoVerse__NotOwnerOfStakedAsset();

        uint256 rewards = _calculateBioTokenRewards(info);
        uint256 totalRewards = rewards + info.accumulatedRewards; // Add pending and accumulated

        delete _ecoPillarStaking[tokenId]; // Clear staking info

        _safeMint(msg.sender, tokenId); // Return the NFT
        // ERC721URIStorage allows minting to return

        if (totalRewards > 0) {
            _transfer(address(this), msg.sender, totalRewards); // Transfer BioTokens
        }

        emit EcoPillarUnstaked(tokenId, msg.sender, totalRewards);
    }

    function claimPillarStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingInfo storage info = _ecoPillarStaking[tokenId];
        if (info.startTime == 0) revert EcoVerse__PillarNotStaked();
        if (info.owner != msg.sender) revert EcoVerse__NotOwnerOfStakedAsset();

        uint256 rewards = _calculateBioTokenRewards(info);
        if (rewards > 0) {
            info.accumulatedRewards += rewards; // Add to accumulated
            info.startTime = uint64(block.timestamp); // Reset timer
            _transfer(address(this), msg.sender, info.accumulatedRewards); // Transfer all accumulated
            info.accumulatedRewards = 0; // Reset accumulated after transfer
        }

        emit PillarRewardsClaimed(tokenId, msg.sender, rewards);
    }

    function activateNatureNode(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        if (_natureNodeOperating[tokenId].startTime != 0) revert EcoVerse__AssetAlreadyActive();
        uint256 nodeLevel = _nodeLevels[tokenId];
        require(nodeLevel > 0, "Node must have a level"); // Ensure it's a valid Node

        // Calculate the actual yield per second based on level and pollution
        uint256 baseYield = natureNodeBaseYieldPerSecond;
        uint256 levelMultiplier = nodeLevelYieldMultiplier[nodeLevel];
        if (levelMultiplier == 0) levelMultiplier = 10000; // Default to 1x if multiplier not set

        uint256 pollutionFactor = maxPollutionIndex > 0 ? (maxPollutionIndex - pollutionIndex) * 10000 / maxPollutionIndex : 10000; // Factor is 0-10000
        uint256 actualYield = (baseYield * levelMultiplier / 10000) * pollutionFactor / 10000;


        _burn(tokenId); // Burn to activate (or transfer to contract)

        _natureNodeOperating[tokenId] = StakingInfo({
            owner: msg.sender,
            startTime: uint64(block.timestamp),
            yieldPerSecond: actualYield,
            accumulatedRewards: _natureNodeOperating[tokenId].accumulatedRewards
        });

        emit NatureNodeActivated(tokenId, msg.sender, nodeLevel, actualYield, block.timestamp);
    }

    function deactivateNatureNode(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingInfo storage info = _natureNodeOperating[tokenId];
        if (info.startTime == 0) revert EcoVerse__NodeNotActive();
        if (info.owner != msg.sender) revert EcoVerse__NotOwnerOfActiveAsset();

        uint256 rewards = _calculateBioTokenRewards(info);
        uint256 totalRewards = rewards + info.accumulatedRewards;

        delete _natureNodeOperating[tokenId]; // Clear operating info

        _safeMint(msg.sender, tokenId); // Return the NFT

        if (totalRewards > 0) {
            _transfer(address(this), msg.sender, totalRewards); // Transfer BioTokens
        }

        emit NatureNodeDeactivated(tokenId, msg.sender, totalRewards);
    }

     function claimNodeOperatingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingInfo storage info = _natureNodeOperating[tokenId];
        if (info.startTime == 0) revert EcoVerse__NodeNotActive();
        if (info.owner != msg.sender) revert EcoVerse__NotOwnerOfActiveAsset();

        uint256 rewards = _calculateBioTokenRewards(info);
        if (rewards > 0) {
            info.accumulatedRewards += rewards;
            info.startTime = uint64(block.timestamp);
            _transfer(address(this), msg.sender, info.accumulatedRewards);
            info.accumulatedRewards = 0;
        }

        emit NodeOperatingRewardsClaimed(tokenId, msg.sender, rewards);
    }


    function nurtureNode(uint256 nodeToBurnId, uint256 catalystId) public whenNotPaused nonReentrant {
        // 1. Check requirements: Node level, Catalyst type, BioToken cost
        require(_isApprovedOrOwner(msg.sender, nodeToBurnId), "Caller does not own node to burn");
        uint256 burnNodeLevel = _nodeLevels[nodeToBurnId];
        if (burnNodeLevel < nurtureMinNodeLevelToBurn) revert EcoVerse__CannotNurtureLevel(burnNodeLevel);
        require(catalystId == CATALYST_GROWTH, "Only Growth Catalysts allowed for nurture");
        if (balanceOf(msg.sender) < nurtureBioTokenCost) revert EcoVerse__InsufficientFundsForNurture();
        require(balanceOf(msg.sender, CATALYST_GROWTH) >= nurtureCatalystGrowthCost, "Not enough Growth Catalysts");

        // 2. Burn/Transfer assets and collect costs
        _burn(nodeToBurnId); // Burn the NatureNode
        _burn(msg.sender, CATALYST_GROWTH, nurtureCatalystGrowthCost); // Burn Catalysts
        _transfer(msg.sender, treasuryAddress, nurtureBioTokenCost); // Transfer BioTokens to treasury

        // 3. Determine outcome pseudo-randomly
        uint256 randomNumber = _generateRandomNumber(); // 0 - 9999
        uint256 cumulativeProb = 0;
        uint256 newLevel = burnNodeLevel; // Default to failure outcome level or same level if failed

        bool success = false;
        for (uint i = 0; i < nurtureSuccessProbabilities.length; i++) {
            cumulativeProb += nurtureSuccessProbabilities[i];
            if (randomNumber < cumulativeProb) {
                newLevel = burnNodeLevel + 1 + i; // Success! Level is current + 1 + index (0=L+1, 1=L+2, ...)
                success = true;
                break; // Found the success tier
            }
        }

        // 4. Handle outcome
        if (success) {
            _nodeTokenIds.increment();
            uint256 newNodeId = _nodeTokenIds.current();
            _safeMint(msg.sender, newNodeId);
            _nodeLevels[newNodeId] = newLevel;
            emit NatureNodeNurtured(msg.sender, nodeToBurnId, burnNodeLevel, newNodeId, newLevel, true);
        } else {
            // Failure: Optionally return a percentage of BioToken cost
            uint256 returnAmount = nurtureBioTokenCost * nurtureFailureReturnPercentage / 10000;
            if (returnAmount > 0) {
                 IERC20(address(this)).safeTransfer(msg.sender, returnAmount); // Transfer from contract balance
            }
             emit NatureNodeNurtured(msg.sender, nodeToBurnId, burnNodeLevel, 0, 0, false);
             // Optionally revert: revert EcoVerse__NurtureFailed(); // If failure should revert
        }
    }

    function recycleAsset(uint256 assetType, uint256 tokenId) public whenNotPaused nonReentrant {
        uint256 rewardAmount = 0;

        if (assetType == ASSET_ECO_PILLAR) {
            require(_isApprovedOrOwner(msg.sender, tokenId), "Caller does not own Pillar");
             if (_ecoPillarStaking[tokenId].startTime != 0) revert EcoVerse__AssetAlreadyStaked(); // Cannot recycle if staked
            _burn(tokenId); // Burn the EcoPillar
            rewardAmount = recycleEcoPillarReward;
        } else if (assetType == ASSET_NATURE_NODE) {
             require(_isApprovedOrOwner(msg.sender, tokenId), "Caller does not own Node");
             if (_natureNodeOperating[tokenId].startTime != 0) revert EcoVerse__AssetAlreadyActive(); // Cannot recycle if active
            uint256 nodeLevel = _nodeLevels[tokenId];
            require(nodeLevel > 0, "Invalid Node");
            _burn(tokenId); // Burn the NatureNode
            // Simple reward based on base, could add level multiplier here
            rewardAmount = recycleNatureNodeRewardBase; // * nodeLevelYieldMultiplier[nodeLevel] / 10000; // Example: make reward scale with level
        } else if (assetType == ASSET_CATALYST) {
            // For catalysts, tokenId is actually the catalyst ID, and caller needs balance
            uint256 catalystId = tokenId;
            uint256 amountToBurn = 1; // Assuming recycling one unit of catalyst
            require(balanceOf(msg.sender, catalystId) >= amountToBurn, "Not enough Catalyst to recycle");
            if (catalystId != CATALYST_GROWTH && catalystId != CATALYST_CLEANSE) revert EcoVerse__InvalidAssetTypeForRecycle(); // Only specific catalysts recyclable?

            _burn(msg.sender, catalystId, amountToBurn); // Burn the Catalyst
            rewardAmount = recycleCatalystReward;
        } else {
            revert EcoVerse__InvalidAssetTypeForRecycle();
        }

        if (rewardAmount > 0) {
             _transfer(address(this), msg.sender, rewardAmount); // Transfer BioTokens from contract balance
        }

        emit AssetRecycled(msg.sender, assetType, tokenId, rewardAmount);
    }

    function pollute() public whenNotPaused nonReentrant {
         // Add cost/requirement for polluting (e.g., burn a specific NFT, pay BioTokens)
         // For simplicity, let's say anyone can pollute a small amount for free, or add a minimal cost.
         // Example: require(balanceOf(msg.sender, CATALYST_POLLUTION) >= 1, "Need Pollution Catalyst");
         // _burn(msg.sender, CATALYST_POLLUTION, 1);

        uint256 oldPollutionIndex = pollutionIndex;
        unchecked {
            pollutionIndex = pollutionIndex + pollutionIncreaseRate;
        }
        if (pollutionIndex > maxPollutionIndex) {
            pollutionIndex = maxPollutionIndex;
        }

        // Optionally reward the polluter
        // uint256 pollutionReward = 1 ether; // Example small reward
        // _transfer(address(this), msg.sender, pollutionReward);

        emit PollutionIncreased(msg.sender, oldPollutionIndex, pollutionIndex);
    }

    function cleanse(uint256 catalystId, uint256 amount) public whenNotPaused nonReentrant {
        // Add requirement for cleansing (e.g., burn specific Catalysts, pay BioTokens)
        require(catalystId == CATALYST_CLEANSE, "Only Cleanse Catalysts allowed for cleansing");
        require(balanceOf(msg.sender, CATALYST_CLEANSE) >= amount, "Not enough Cleanse Catalysts");

        uint256 oldPollutionIndex = pollutionIndex;
        uint256 decreaseAmount = pollutionDecreaseRate * amount;

        _burn(msg.sender, CATALYST_CLEANSE, amount); // Burn Catalysts
        // Add BioToken cost for cleansing?
        // _transfer(msg.sender, treasuryAddress, cleanseBioTokenCost);


        if (pollutionIndex <= decreaseAmount) {
            pollutionIndex = 0;
        } else {
             unchecked {
                pollutionIndex = pollutionIndex - decreaseAmount;
            }
        }

        emit PollutionDecreased(msg.sender, oldPollutionIndex, pollutionIndex, decreaseAmount);
    }

    // --- Admin / Parameter Adjustment Functions ---

    function setEcoPillarYieldPerSecond(uint256 yieldPerSec) public onlyRole(MANAGER_ROLE) {
        ecoPillarYieldPerSecond = yieldPerSec;
        emit EcoPillarYieldRateUpdated(yieldPerSec);
    }

    function setNatureNodeBaseYieldPerSecond(uint256 baseYieldPerSec) public onlyRole(MANAGER_ROLE) {
        natureNodeBaseYieldPerSecond = baseYieldPerSec;
         emit NatureNodeBaseYieldRateUpdated(baseYieldPerSec);
    }

    function setNodeLevelYieldMultiplier(uint256 level, uint256 multiplier) public onlyRole(MANAGER_ROLE) {
        nodeLevelYieldMultiplier[level] = multiplier; // Multiplier is percentage * 100 (e.g., 15000 for 150%)
         emit NodeLevelYieldMultiplierUpdated(level, multiplier);
    }

     function setPollutionImpactParameters(uint256 _maxPollution, uint256 _pollutionIncreaseRate, uint256 _pollutionDecreaseRate) public onlyRole(MANAGER_ROLE) {
        require(_maxPollution > 0, "Max pollution must be > 0");
        maxPollutionIndex = _maxPollution;
        pollutionIncreaseRate = _pollutionIncreaseRate;
        pollutionDecreaseRate = _pollutionDecreaseRate;
        // Ensure current index is within new bounds
        if (pollutionIndex > maxPollutionIndex) pollutionIndex = maxPollutionIndex;
        emit PollutionParametersUpdated(maxPollutionIndex, pollutionIncreaseRate, pollutionDecreaseRate);
     }


    function setNurtureParameters(
        uint256 _bioTokenCost,
        uint256 _catalystGrowthCost,
        uint256 _minLevelToBurn,
        uint256[] calldata _successProbabilities,
        uint256 _failureReturnPercentage
    ) public onlyRole(MANAGER_ROLE) {
        uint256 totalProb;
        for(uint i = 0; i < _successProbabilities.length; i++) {
            totalProb += _successProbabilities[i];
        }
        require(totalProb <= 10000, "Total success probabilities must be <= 10000 (100%)");
        require(_failureReturnPercentage <= 10000, "Failure return percentage must be <= 10000 (100%)");

        nurtureBioTokenCost = _bioTokenCost;
        nurtureCatalystGrowthCost = _catalystGrowthCost;
        nurtureMinNodeLevelToBurn = _minLevelToBurn;
        nurtureSuccessProbabilities = _successProbabilities;
        nurtureFailureReturnPercentage = _failureReturnPercentage;

        emit NurtureParametersUpdated(_bioTokenCost, _catalystGrowthCost, _minLevelToBurn, _successProbabilities, _failureReturnPercentage);
    }

    function setRecycleRewards(
        uint256 _ecoPillarReward,
        uint256 _natureNodeRewardBase,
        uint256 _catalystReward
    ) public onlyRole(MANAGER_ROLE) {
        recycleEcoPillarReward = _ecoPillarReward;
        recycleNatureNodeRewardBase = _natureNodeRewardBase;
        recycleCatalystReward = _catalystReward;
        emit RecycleRewardsUpdated(_ecoPillarReward, _natureNodeRewardBase, _catalystReward);
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyRole(MANAGER_ROLE) {
        require(_treasuryAddress != address(0), "Treasury address cannot be zero");
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressUpdated(_treasuryAddress);
    }

     // --- Treasury Management ---
    function withdrawTreasury(address tokenAddress) public onlyRole(MANAGER_ROLE) nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this)); // Contract holds the tokens
        if (balance > 0) {
            token.safeTransfer(msg.sender, balance);
             emit TreasuryWithdrawal(tokenAddress, msg.sender, balance);
        }
    }


    // --- View Functions ---

    function getPollutionIndex() public view returns (uint256) {
        return pollutionIndex;
    }

    function calculatePillarRewards(uint256 tokenId) public view returns (uint256) {
        StakingInfo memory info = _ecoPillarStaking[tokenId];
        if (info.startTime == 0) return 0;
        return _calculateBioTokenRewards(info);
    }

    function calculateNodeRewards(uint256 tokenId) public view returns (uint256) {
        StakingInfo memory info = _natureNodeOperating[tokenId];
        if (info.startTime == 0) return 0;
        return _calculateBioTokenRewards(info);
    }

    function getNodeLevel(uint256 tokenId) public view returns (uint256) {
        return _nodeLevels[tokenId];
    }

     function getTreasuryBalance() public view returns (uint256) {
        return balanceOf(address(this)); // BioToken balance held by the contract
    }

     function getEcoPillarStakingInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        return _ecoPillarStaking[tokenId];
     }

      function getNatureNodeOperatingInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        return _natureNodeOperating[tokenId];
     }

     function getNurtureParameters() public view returns (
        uint256 bioTokenCost,
        uint256 catalystGrowthCost,
        uint256 minLevelToBurn,
        uint256[] memory successProbabilities,
        uint256 failureReturnPercentage
     ) {
         return (
             nurtureBioTokenCost,
             nurtureCatalystGrowthCost,
             nurtureMinNodeLevelToBurn,
             nurtureSuccessProbabilities,
             nurtureFailureReturnPercentage
         );
     }

    // --- Internal Helper Functions ---

    function _calculateBioTokenRewards(StakingInfo memory info) internal view returns (uint256) {
        if (info.startTime == 0 || info.owner == address(0)) return 0; // Not staked/active

        uint256 elapsed = block.timestamp - info.startTime;
        return elapsed * info.yieldPerSecond;
    }

    function _generateRandomNumber() internal returns (uint256) {
         // Simple pseudo-random number generation using block data and state
         // WARNING: This is PREDICTABLE and should NOT be used for outcomes
         // with high immediate value or where predictability is a critical vulnerability.
         // For real-world randomness, use Chainlink VRF or similar oracles.
        _randomSeed = uint256(keccak256(abi.encodePacked(_randomSeed, block.timestamp, block.number, msg.sender, block.difficulty))) % 10000;
        return _randomSeed;
    }

    // --- Overrides for ERC721 and ERC1155 ---
    // Required ERC721/1155 overrides are handled by inheriting ERC721URIStorage and ERC1155
    // We need to implement _beforeTokenTransfer for ERC721 to handle staked/active assets
    // and potentially override tokenURI for NatureNodes to reflect level.

    // Override ERC721 transfer checks to prevent transferring staked/active assets via standard transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        // Prevent transfer if staked or active
        if (_ecoPillarStaking[tokenId].startTime != 0) {
            if (from != address(0) && to != address(0)) { // Allow minting (0->addr) and burning (addr->0) of staked
                 revert("EcoVerse: Staked EcoPillar cannot be transferred");
            }
        }
        if (_natureNodeOperating[tokenId].startTime != 0) {
             if (from != address(0) && to != address(0)) { // Allow minting/burning of active
                 revert("EcoVerse: Active NatureNode cannot be transferred");
            }
        }
    }

     // Override supportsInterface for ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC20, ERC721URIStorage, ERC1155, AccessControl) returns (bool) {
        return interfaceId == type(IERC20).interfaceId ||
               interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC1155).interfaceId ||
               interfaceId == type(IERC1155MetadataURI).interfaceId ||
               interfaceId == type(IAccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Events ---
    event EcoPillarStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event EcoPillarUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimedRewards);
    event PillarRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 claimedAmount);
    event NatureNodeActivated(uint256 indexed tokenId, address indexed owner, uint256 level, uint256 effectiveYieldPerSecond, uint256 timestamp);
    event NatureNodeDeactivated(uint256 indexed tokenId, address indexed owner, uint256 claimedRewards);
    event NodeOperatingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 claimedAmount);
    event NatureNodeNurtured(address indexed nurturer, uint256 indexed burnedNodeId, uint256 burnedNodeLevel, uint256 indexed newNodeId, uint256 newNodeLevel, bool success);
    event AssetRecycled(address indexed recycler, uint256 indexed assetType, uint256 indexed tokenIdOrId, uint256 recycledAmount);
    event PollutionIncreased(address indexed actor, uint256 oldIndex, uint256 newIndex);
    event PollutionDecreased(address indexed actor, uint256 oldIndex, uint256 newIndex, uint256 decreaseAmount);
    event EcoPillarYieldRateUpdated(uint256 newRate);
    event NatureNodeBaseYieldRateUpdated(uint256 newRate);
    event NodeLevelYieldMultiplierUpdated(uint256 level, uint256 multiplier);
    event PollutionParametersUpdated(uint256 maxPollution, uint256 increaseRate, uint256 decreaseRate);
    event NurtureParametersUpdated(uint256 bioTokenCost, uint256 catalystGrowthCost, uint256 minLevelToBurn, uint256[] successProbabilities, uint256 failureReturnPercentage);
    event RecycleRewardsUpdated(uint256 ecoPillarReward, uint256 natureNodeRewardBase, uint256 catalystReward);
    event TreasuryAddressUpdated(address indexed newAddress);
    event TreasuryWithdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // Note on Metadata URIs:
    // For ERC721URIStorage, _setBaseURI is for ALL ERC721s in the contract.
    // If EcoPillars and NatureNodes need truly different base URIs, they should be in separate contracts.
    // Alternatively, use a metadata server that uses token ID and potentially node level (getNodeLevel)
    // to return the correct JSON metadata from a single base URI or internal logic.
    // The ERC1155 URI is separate via _setURI.

     // Potentially override tokenURI for NatureNodes if metadata changes with level
     // function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
     //     // Check if it's a Pillar or Node based on token ID range or internal mapping
     //     // Assuming node IDs start after pillar IDs or have a separate counter
     //     uint256 pillarCount = _pillarTokenIds.current(); // This isn't accurate after minting
     //     if (tokenId <= pillarCount) { // Simplistic check, needs proper ID separation logic
     //         return super.tokenURI(tokenId); // Use ERC721URIStorage base URI for Pillars
     //     } else {
     //         // For NatureNodes, construct URI or point to a server that reads level
     //         uint256 level = _nodeLevels[tokenId];
     //         if (level == 0) return super.tokenURI(tokenId); // Or return empty/default
     //         // Example: "base/nodes/<nodeId>/level/<level>.json" - metadata server handles this structure
     //         // Or point to a single resolver URL: "resolver.com/metadata?contract=0x...&tokenId=...&level=..."
     //         return string(abi.encodePacked(_baseURI(), "nodes/", Strings.toString(tokenId), "/level/", Strings.toString(level), ".json"));
     //     }
     // }
}
```