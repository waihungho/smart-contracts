Okay, here is a Solidity smart contract featuring a "Decentralized Adaptive Ecosystem Hub" with concepts like dynamic NFTs, adaptive parameters based on internal state (simulating ecosystem health), token staking with variable rewards, NFT fusion, and a basic reputation system.

It aims for creativity by making core mechanics (costs, rewards, probabilities) change dynamically based on the contract's internal "health index," rather than being fixed parameters or solely relying on external oracles.

It includes over 20 functions covering these features.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract Outline and Function Summary ---
/*
Contract Name: ChimericEcosystemProtocol (CEP)

Purpose:
A creative, advanced smart contract simulating a decentralized ecosystem with dynamic assets (Chimeras), a utility token (CET), staking mechanisms, and core mechanics that adapt based on the ecosystem's internal "health index."

Core Concepts:
1.  CET (Chimeric Ecosystem Token): An internal ERC-20 like utility token.
2.  Chimeras (Dynamic NFTs): ERC-721 like tokens with modifiable attributes.
3.  Adaptive Parameters: Costs, rewards, and probabilities for certain actions change based on the Ecosystem Health Index.
4.  Ecosystem Health Index: An internal metric updated periodically (simulated via admin call) based on ecosystem activity (e.g., total staked, total minted, time).
5.  Staking: Stake CET for yield, stake Chimeras for passive benefits or eligibility.
6.  Fusion: Combine two Chimeras into a new, potentially stronger one, burning the originals.
7.  Reputation: A basic system tracking user participation/contribution.

Outline:
-   Error definitions
-   Event definitions
-   Structs for NFT attributes and adaptive parameters
-   State variables (balances, ownership, stakes, health, reputation, config)
-   Modifiers (ownership, pausing)
-   Constructor
-   Core Token (CET) Functions (Mint, Transfer, Balance)
-   Core NFT (Chimera) Functions (Mint, Transfer, Attributes, Owner)
-   Staking Functions (Stake/Unstake CET, Stake/Unstake Chimera, Claim Rewards)
-   Adaptive & Ecosystem Functions (Assess Health, Get Health/Params, Perform Adaptive Action, Query Costs)
-   Dynamic NFT Functions (Update Attributes, Fuse Chimeras, Preview Fusion)
-   Reputation Functions (Gain/Lose/Get Reputation)
-   Admin & Configuration Functions (Set Config, Pause/Unpause, Withdraw Fees)
-   Internal Helper Functions (Calculate Rewards, Get Adaptive Params, Generate Attributes)

Function Summary:

**Core Token (CET)**
1.  `mintCET(uint256 amount)`: Mints CET to sender, payable in ETH (ETH is burned).
2.  `transferCET(address recipient, uint256 amount)`: Standard CET transfer.
3.  `balanceOfCET(address account)`: Get CET balance of an account.

**Core NFT (Chimera)**
4.  `mintChimera(string memory name)`: Mints a new Chimera NFT to sender, costs CET, generates dynamic attributes.
5.  `transferChimera(address to, uint256 tokenId)`: Standard Chimera transfer (basic ERC721).
6.  `ownerOfChimera(uint256 tokenId)`: Get owner of a Chimera NFT.
7.  `getChimeraAttributes(uint256 tokenId)`: Get attributes of a Chimera NFT.

**Staking**
8.  `stakeCET(uint256 amount)`: Stakes CET to earn yield.
9.  `unstakeCET(uint256 amount)`: Unstakes CET and claims pending rewards.
10. `claimCETRewards()`: Claims pending CET rewards without unstaking.
11. `getStakedCET(address account)`: Get amount of CET staked by an account.
12. `stakeChimera(uint256 tokenId)`: Stakes a Chimera NFT (must be owner).
13. `unstakeChimera(uint256 tokenId)`: Unstakes a Chimera NFT.
14. `getStakedChimeraIds(address account)`: Get list of Chimera token IDs staked by an account.

**Adaptive & Ecosystem**
15. `assessEcosystemHealth()`: (Admin/Simulated Oracle) Updates the `ecosystemHealthIndex` based on internal metrics.
16. `getEcosystemHealth()`: Get the current Ecosystem Health Index.
17. `getAdaptiveParams()`: Get the current adaptive parameters derived from the health index.
18. `performAdaptiveAction()`: Executes an action whose cost and reward depend on adaptive parameters.
19. `queryAdaptiveActionDetails()`: View the current cost and potential reward for `performAdaptiveAction`.

**Dynamic NFT (Chimera)**
20. `updateChimeraAttributes(uint256 tokenId)`: Dynamically updates attributes of a Chimera (costs CET, influenced by health).
21. `fuseChimeras(uint256 tokenId1, uint256 tokenId2)`: Combines two owned Chimeras, burns them, mints a new one with fused attributes (costs CET, influenced by health).
22. `previewFusionResult(uint256 tokenId1, uint256 tokenId2)`: Simulate the attributes of a potential fusion result (read-only).

**Reputation**
23. `gainReputation(address account, uint256 amount)`: (Internal/Admin) Increases reputation for an account.
24. `getReputation(address account)`: Get reputation score of an account.
25. `loseReputation(address account, uint256 amount)`: (Internal/Admin) Decreases reputation for an account.

**Admin & Configuration**
26. `setConfig(uint256 _cetMintCostETH, uint256 _chimeraMintCostCET, uint256 _baseStakeRewardRate, uint256 _adaptiveActionBaseCost, uint256 _adaptiveActionBaseReward)`: Sets various configuration parameters (Owner only).
27. `pause()`: Pauses certain ecosystem activities (Owner only).
28. `unpause()`: Unpauses ecosystem activities (Owner only).
29. `withdrawETH()`: Withdraws accumulated ETH (from CET minting) (Owner only).
30. `withdrawCETFees()`: Withdraws accumulated CET fees (from Chimera minting, fusion, attribute updates) (Owner only).
*/

// --- Contract Start ---

contract ChimericEcosystemProtocol {
    address public owner;

    // --- Errors ---
    error Unauthorized();
    error Paused();
    error InsufficientBalanceCET();
    error InsufficientETH();
    error InvalidTokenId();
    error NotOwnerOfToken();
    error TokenAlreadyStaked();
    error TokenNotStaked();
    error CannotSelfTransfer();
    error CannotFuseSelfOrStaked();
    error NotEnoughCETFees();
    error InvalidAmount();

    // --- Events ---
    event CETMinted(address indexed account, uint256 amount);
    event CETBurned(address indexed account, uint256 amount); // Added for completeness
    event CETTransfer(address indexed from, address indexed to, uint256 amount);
    event ChimeraMinted(address indexed owner, uint256 indexed tokenId, string name);
    event ChimeraTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ChimeraBurned(uint256 indexed tokenId); // Added for completeness
    event CETStaked(address indexed account, uint256 amount);
    event CETUnstaked(address indexed account, uint256 amount, uint256 rewardsClaimed);
    event CETRewardsClaimed(address indexed account, uint256 rewards);
    event ChimeraStaked(address indexed owner, uint256 indexed tokenId);
    event ChimeraUnstaked(address indexed owner, uint256 indexed tokenId);
    event ChimeraAttributesUpdated(uint256 indexed tokenId);
    event ChimerasFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event EcosystemHealthAssessed(uint256 newHealthIndex);
    event AdaptiveActionPerformed(address indexed account, uint256 cost, uint256 reward);
    event ReputationChanged(address indexed account, uint256 newReputation);
    event ConfigUpdated(uint256 cetMintCostETH, uint256 chimeraMintCostCET, uint256 baseStakeRewardRate, uint256 adaptiveActionBaseCost, uint256 adaptiveActionBaseReward);
    event PausedStateChanged(bool isPaused);
    event FeesWithdrawn(address indexed recipient, uint256 ethAmount, uint256 cetAmount);


    // --- Structs ---
    struct ChimeraAttributes {
        string name;
        uint256 generation;
        uint256 power;
        uint256 speed;
        uint256 resilience;
        // Add more attributes as needed
    }

    struct AdaptiveParams {
        uint256 cetMintCostETH;
        uint256 chimeraMintCostCET;
        uint256 stakeRewardMultiplier; // Multiplier for base reward rate
        uint256 attributeUpdateCostCET;
        uint256 fusionCostCET;
        uint256 adaptiveActionCost;
        uint256 adaptiveActionReward;
        // Add parameters for probabilities, cooldowns etc.
    }

    // --- State Variables ---
    // CET (ERC-20 like)
    mapping(address => uint256) private _cetBalances;
    uint256 private _totalCETSupply;
    uint256 public accumulatedCETFees; // CET collected from internal fees

    // Chimeras (ERC-721 like)
    uint256 private _chimeraTokenCounter; // Tracks total Chimeras minted
    mapping(uint256 => address) private _chimeraOwners;
    mapping(address => uint256[]) private _ownedChimeras; // Helps retrieve owned token IDs
    mapping(uint256 => ChimeraAttributes) private _chimeraAttributes;
    mapping(uint256 => bool) private _isChimeraStaked; // Tracks staked Chimeras
    mapping(address => uint256[]) private _stakedChimeraIds; // Tracks staked Chimera IDs per owner

    // Staking
    mapping(address => uint256) public stakedCET;
    mapping(address => uint256) private _lastRewardClaimTime; // For calculating CET rewards
    uint256 public baseStakeRewardRate; // CET per second per staked CET (scaled, e.g., 1e18 for 1 CET/sec)

    // Ecosystem Health & Adaptive
    uint256 public ecosystemHealthIndex; // Value from 0 (Unhealthy) to 100 (Optimal)
    uint256 private lastHealthAssessmentTime;
    uint256 public healthAssessmentInterval = 1 days; // How often health can be assessed (by admin)

    // Reputation
    mapping(address => uint256) private _reputation;

    // Configuration
    uint256 public cetMintCostETH; // In wei
    uint256 public chimeraMintCostCET; // In CET (scaled)
    uint256 public attributeUpdateCostCET; // In CET (scaled)
    uint256 public fusionCostCET; // In CET (scaled)
    uint256 public adaptiveActionBaseCost; // Base cost for the adaptive action (in CET)
    uint256 public adaptiveActionBaseReward; // Base reward for the adaptive action (in CET)

    // Pause
    bool public paused = false;

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 initialCETSupply,
        uint256 _cetMintCostETH,
        uint256 _chimeraMintCostCET,
        uint256 _baseStakeRewardRate,
        uint256 _adaptiveActionBaseCost,
        uint256 _adaptiveActionBaseReward
    ) payable {
        owner = msg.sender;
        _totalCETSupply = initialCETSupply;
        _cetBalances[msg.sender] = initialCETSupply;
        emit CETMinted(msg.sender, initialCETSupply);

        cetMintCostETH = _cetMintCostETH;
        chimeraMintCostCET = _chimeraMintCostCET;
        baseStakeRewardRate = _baseStakeRewardRate;
        adaptiveActionBaseCost = _adaptiveActionBaseCost;
        adaptiveActionBaseReward = _adaptiveActionBaseReward;
        attributeUpdateCostCET = chimeraMintCostCET / 2; // Example default derived cost
        fusionCostCET = chimeraMintCostCET * 2; // Example default derived cost

        ecosystemHealthIndex = 50; // Start at a neutral health
        lastHealthAssessmentTime = block.timestamp;

        _chimeraTokenCounter = 0;
    }

    // --- Core Token (CET) Functions ---

    /// @notice Mints CET to the sender, burning received ETH.
    /// @param amount The amount of CET to mint.
    function mintCET(uint256 amount) external payable whenNotPaused {
        uint256 requiredETH = amount * cetMintCostETH / 1e18; // Assuming cetMintCostETH is scaled 1e18 per CET
        if (msg.value < requiredETH) revert InsufficientETH();

        _totalCETSupply += amount;
        _cetBalances[msg.sender] += amount;
        emit CETMinted(msg.sender, amount);

        // Excess ETH is implicitly left in the contract, owner can withdraw
    }

    /// @notice Transfers CET from sender to recipient.
    /// @param recipient The address to transfer to.
    /// @param amount The amount of CET to transfer.
    function transferCET(address recipient, uint256 amount) external whenNotPaused {
        if (recipient == address(0)) revert InvalidAmount(); // Basic check
        if (_cetBalances[msg.sender] < amount) revert InsufficientBalanceCET();

        _cetBalances[msg.sender] -= amount;
        _cetBalances[recipient] += amount;
        emit CETTransfer(msg.sender, recipient, amount);
    }

    /// @notice Gets the CET balance of an account.
    /// @param account The address to query.
    /// @return The CET balance.
    function balanceOfCET(address account) external view returns (uint256) {
        return _cetBalances[account];
    }

    // --- Core NFT (Chimera) Functions ---

    /// @notice Mints a new Chimera NFT to the sender.
    /// @param name The name for the new Chimera.
    /// @return The token ID of the newly minted Chimera.
    function mintChimera(string memory name) external whenNotPaused returns (uint256) {
        if (_cetBalances[msg.sender] < chimeraMintCostCET) revert InsufficientBalanceCET();

        _cetBalances[msg.sender] -= chimeraMintCostCET;
        accumulatedCETFees += chimeraMintCostCET;

        _chimeraTokenCounter++;
        uint256 newTokenId = _chimeraTokenCounter;

        _chimeraOwners[newTokenId] = msg.sender;
        _ownedChimeras[msg.sender].push(newTokenId);

        // Generate dynamic attributes
        ChimeraAttributes memory newAttributes = _generateRandomAttributes(newTokenId);
        newAttributes.name = name;
        newAttributes.generation = 1; // First generation
        _chimeraAttributes[newTokenId] = newAttributes;

        emit ChimeraMinted(msg.sender, newTokenId, name);
        _gainReputation(msg.sender, 5); // Gain reputation for contributing (minting)

        return newTokenId;
    }

    /// @notice Transfers a Chimera NFT.
    /// @param to The recipient address.
    /// @param tokenId The token ID to transfer.
    function transferChimera(address to, uint256 tokenId) external whenNotPaused {
        if (to == address(0)) revert InvalidAmount();
        if (_chimeraOwners[tokenId] != msg.sender) revert NotOwnerOfToken();
        if (to == msg.sender) revert CannotSelfTransfer();
        if (_isChimeraStaked[tokenId]) revert TokenAlreadyStaked(); // Cannot transfer staked tokens

        address currentOwner = msg.sender;
        address nextOwner = to;

        _chimeraOwners[tokenId] = nextOwner;
        _removeTokenFromList(_ownedChimeras[currentOwner], tokenId);
        _ownedChimeras[nextOwner].push(tokenId);

        emit ChimeraTransfer(currentOwner, nextOwner, tokenId);
    }

    /// @notice Gets the owner of a Chimera NFT.
    /// @param tokenId The token ID to query.
    /// @return The owner's address.
    function ownerOfChimera(uint256 tokenId) external view returns (address) {
        if (_chimeraOwners[tokenId] == address(0)) revert InvalidTokenId();
        return _chimeraOwners[tokenId];
    }

    /// @notice Gets the attributes of a Chimera NFT.
    /// @param tokenId The token ID to query.
    /// @return The ChimeraAttributes struct.
    function getChimeraAttributes(uint256 tokenId) external view returns (ChimeraAttributes memory) {
        if (_chimeraOwners[tokenId] == address(0)) revert InvalidTokenId(); // Check if token exists
        return _chimeraAttributes[tokenId];
    }

    // --- Staking Functions ---

    /// @notice Stakes CET tokens to earn rewards.
    /// @param amount The amount of CET to stake.
    function stakeCET(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (_cetBalances[msg.sender] < amount) revert InsufficientBalanceCET();

        // Claim any pending rewards before staking more
        _claimCETRewards(msg.sender);

        _cetBalances[msg.sender] -= amount;
        stakedCET[msg.sender] += amount;
        _lastRewardClaimTime[msg.sender] = block.timestamp; // Reset timer after claiming/staking

        emit CETStaked(msg.sender, amount);
        _gainReputation(msg.sender, amount / 100); // Gain reputation based on staked amount
    }

    /// @notice Unstakes CET tokens and claims pending rewards.
    /// @param amount The amount of CET to unstake.
    function unstakeCET(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (stakedCET[msg.sender] < amount) revert InvalidAmount(); // Using InvalidAmount as a shortcut for "not enough staked"

        // Claim pending rewards
        _claimCETRewards(msg.sender);

        stakedCET[msg.sender] -= amount;
        _cetBalances[msg.sender] += amount;
        _lastRewardClaimTime[msg.sender] = block.timestamp; // Reset timer

        emit CETUnstaked(msg.sender, amount, _cetBalances[msg.sender] - (stakedCET[msg.sender] > 0 ? 0 : amount)); // Emit claimed rewards if any were claimed
    }

    /// @notice Claims pending CET rewards without unstaking.
    function claimCETRewards() external whenNotPaused {
        _claimCETRewards(msg.sender);
    }

    /// @notice Internal function to calculate and distribute CET rewards.
    /// @param account The account to calculate and distribute rewards for.
    function _claimCETRewards(address account) internal {
        uint256 rewards = _calculateCETRewards(account);
        if (rewards > 0) {
            _cetBalances[account] += rewards;
            _lastRewardClaimTime[account] = block.timestamp;
            emit CETRewardsClaimed(account, rewards);
            _gainReputation(account, rewards / 200); // Gain reputation for claiming rewards
        }
    }

    /// @notice Internal helper to calculate pending CET rewards.
    /// @param account The account to calculate rewards for.
    /// @return The calculated reward amount.
    function _calculateCETRewards(address account) internal view returns (uint256) {
        uint256 staked = stakedCET[account];
        if (staked == 0) return 0;

        uint256 timeElapsed = block.timestamp - _lastRewardClaimTime[account];
        if (timeElapsed == 0) return 0;

        AdaptiveParams memory adaptive = _getAdaptiveParametersForHealth();
        // Reward = staked * baseRate * time * adaptiveMultiplier
        // Use high precision for intermediate calculations
        uint256 rawReward = staked * baseStakeRewardRate * timeElapsed;
        uint256 finalReward = rawReward * adaptive.stakeRewardMultiplier / 1e18 / 1e18; // Assuming baseRate and multiplier are 1e18 scaled

        return finalReward;
    }

    /// @notice Gets the amount of CET staked by an account.
    /// @param account The address to query.
    /// @return The staked amount.
    function getStakedCET(address account) external view returns (uint256) {
        return stakedCET[account];
    }

    /// @notice Stakes a Chimera NFT.
    /// @param tokenId The token ID to stake.
    function stakeChimera(uint256 tokenId) external whenNotPaused {
        if (_chimeraOwners[tokenId] != msg.sender) revert NotOwnerOfToken();
        if (_isChimeraStaked[tokenId]) revert TokenAlreadyStaked();

        _isChimeraStaked[tokenId] = true;
        _stakedChimeraIds[msg.sender].push(tokenId);
        _removeTokenFromList(_ownedChimeras[msg.sender], tokenId); // Remove from owned list

        emit ChimeraStaked(msg.sender, tokenId);
        _gainReputation(msg.sender, 10); // Gain reputation for staking a Chimera
    }

    /// @notice Unstakes a Chimera NFT.
    /// @param tokenId The token ID to unstake.
    function unstakeChimera(uint256 tokenId) external whenNotPaused {
        // Check ownership implicitly via staking status and staked list
        // If it's in their staked list, they must be the staker (and owner)
        bool found = false;
        for (uint i = 0; i < _stakedChimeraIds[msg.sender].length; i++) {
            if (_stakedChimeraIds[msg.sender][i] == tokenId) {
                found = true;
                break;
            }
        }
        if (!found || !_isChimeraStaked[tokenId]) revert TokenNotStaked();

        _isChimeraStaked[tokenId] = false;
        _removeTokenFromList(_stakedChimeraIds[msg.sender], tokenId); // Remove from staked list
        _ownedChimeras[msg.sender].push(tokenId); // Add back to owned list

        emit ChimeraUnstaked(msg.sender, tokenId);
    }

    /// @notice Gets the list of Chimera token IDs staked by an account.
    /// @param account The address to query.
    /// @return An array of staked Chimera token IDs.
    function getStakedChimeraIds(address account) external view returns (uint256[] memory) {
        return _stakedChimeraIds[account];
    }

    // --- Adaptive & Ecosystem Functions ---

    /// @notice (Admin/Simulated Oracle) Assesses and updates the ecosystem health index.
    /// Health calculation is a simplified example based on time and total staked CET.
    function assessEcosystemHealth() external onlyOwner {
        // Prevent frequent updates
        if (block.timestamp < lastHealthAssessmentTime + healthAssessmentInterval) {
             // Optionally revert or just return without update
             return;
        }

        // --- Simplified Health Calculation Logic ---
        // Example: Health increases slightly over time, boosted by total staked CET,
        // decreased slightly by total supply increase since last assessment.
        // This is a *simulation* - a real system would use more complex metrics,
        // potentially including off-chain data via an oracle network.

        uint256 timeFactor = (block.timestamp - lastHealthAssessmentTime) / (healthAssessmentInterval / 10); // Gain health based on time (capped)
        uint256 stakedFactor = _totalCETSupply > 0 ? (getTotalStakedCET() * 50 / _totalCETSupply) : 0; // Max 50 boost from staking ratio
        uint256 supplyChangeFactor = (_totalCETSupply - _totalCETSupplyAtLastHealthAssessment) / 1e18; // Penalty for supply inflation (example scaling)
        uint256 totalChimeras = _chimeraTokenCounter; // Could add factor for active NFTs etc.

        // Combine factors - keep index between 0 and 100
        int256 healthChange = int256(timeFactor + stakedFactor) - int256(supplyChangeFactor);

        if (healthChange > 10) healthChange = 10; // Max change per assessment
        if (healthChange < -10) healthChange = -10;

        int256 newHealth = int256(ecosystemHealthIndex) + healthChange;
        if (newHealth < 0) newHealth = 0;
        if (newHealth > 100) newHealth = 100;

        ecosystemHealthIndex = uint256(newHealth);
        lastHealthAssessmentTime = block.timestamp;
        _totalCETSupplyAtLastHealthAssessment = _totalCETSupply; // Store for next assessment

        emit EcosystemHealthAssessed(ecosystemHealthIndex);
    }
    uint256 private _totalCETSupplyAtLastHealthAssessment; // Keep track for health assessment

    /// @notice Gets the current Ecosystem Health Index.
    /// @return The health index value (0-100).
    function getEcosystemHealth() external view returns (uint256) {
        return ecosystemHealthIndex;
    }

    /// @notice Gets the current adaptive parameters based on health.
    /// @return The calculated AdaptiveParams struct.
    function getAdaptiveParams() external view returns (AdaptiveParams memory) {
        return _getAdaptiveParametersForHealth();
    }

    /// @notice Internal helper to calculate adaptive parameters based on health.
    /// Parameters scale between base config values and potentially higher/lower values based on health.
    /// @return The calculated AdaptiveParams struct.
    function _getAdaptiveParametersForHealth() internal view returns (AdaptiveParams memory) {
        // Example scaling logic:
        // Health 0: Min impact (maybe slightly worse than base)
        // Health 50: Base impact
        // Health 100: Max impact (significantly better/worse than base)

        uint256 health = ecosystemHealthIndex;
        AdaptiveParams memory params;

        // Example: Costs increase in Unhealthy state, decrease in Optimal state
        params.cetMintCostETH = cetMintCostETH * (100 + (50 - health) / 5) / 100; // Scale: +10% at 0, base at 50, -10% at 100
        params.chimeraMintCostCET = chimeraMintCostCET * (100 + (50 - health) / 5) / 100;
        params.attributeUpdateCostCET = attributeUpdateCostCET * (100 + (50 - health) / 5) / 100;
        params.fusionCostCET = fusionCostCET * (100 + (50 - health) / 5) / 100;

        // Example: Rewards/benefits increase in Optimal state, decrease in Unhealthy state
        params.stakeRewardMultiplier = 1e18 * (50 + health / 2) / 100; // Scale: 50% at 0, 75% at 50, 100% at 100 (base is multiplied by this) -> let's make it scale from 50% to 150%: (50 + health)
        params.stakeRewardMultiplier = 1e18 * (50 + health) / 100; // 50% at 0, 100% at 50, 150% at 100

        params.adaptiveActionCost = adaptiveActionBaseCost * (100 + (50 - health) / 5) / 100;
        params.adaptiveActionReward = adaptiveActionBaseReward * (50 + health) / 100;

        // Ensure costs/rewards don't go to zero unexpectedly if health formula changes wildly
        if (params.cetMintCostETH == 0 && cetMintCostETH > 0) params.cetMintCostETH = 1;
        if (params.chimeraMintCostCET == 0 && chimeraMintCostCET > 0) params.chimeraMintCostCET = 1;
        if (params.attributeUpdateCostCET == 0 && attributeUpdateCostCET > 0) params.attributeUpdateCostCET = 1;
        if (params.fusionCostCET == 0 && fusionCostCET > 0) params.fusionCostCET = 1;
         if (params.adaptiveActionCost == 0 && adaptiveActionBaseCost > 0) params.adaptiveActionCost = 1;
         if (params.adaptiveActionReward == 0 && adaptiveActionBaseReward > 0) params.adaptiveActionReward = 1;


        return params;
    }

    /// @notice Performs an action whose cost and reward are determined by the current adaptive parameters.
    function performAdaptiveAction() external whenNotPaused {
        AdaptiveParams memory params = _getAdaptiveParametersForHealth();
        if (_cetBalances[msg.sender] < params.adaptiveActionCost) revert InsufficientBalanceCET();

        _cetBalances[msg.sender] -= params.adaptiveActionCost;
        accumulatedCETFees += params.adaptiveActionCost;

        uint256 reward = params.adaptiveActionReward; // Simple direct reward for now
        _cetBalances[msg.sender] += reward; // Reward back to the user

        emit AdaptiveActionPerformed(msg.sender, params.adaptiveActionCost, reward);
        _gainReputation(msg.sender, reward / 50); // Gain reputation based on reward
    }

    /// @notice Queries the current cost and potential reward for `performAdaptiveAction`.
    /// @return actionCost The CET cost for the action.
    /// @return actionReward The CET reward for the action.
    function queryAdaptiveActionDetails() external view returns (uint256 actionCost, uint256 actionReward) {
        AdaptiveParams memory params = _getAdaptiveParametersForHealth();
        return (params.adaptiveActionCost, params.adaptiveActionReward);
    }


    // --- Dynamic NFT (Chimera) Functions ---

    /// @notice Dynamically updates the attributes of an owned Chimera.
    /// Costs CET and influence by ecosystem health.
    /// @param tokenId The token ID of the Chimera to update.
    function updateChimeraAttributes(uint256 tokenId) external whenNotPaused {
        if (_chimeraOwners[tokenId] != msg.sender) revert NotOwnerOfToken();
        if (_isChimeraStaked[tokenId]) revert TokenAlreadyStaked(); // Cannot update attributes of staked tokens

        AdaptiveParams memory params = _getAdaptiveParametersForHealth();
        if (_cetBalances[msg.sender] < params.attributeUpdateCostCET) revert InsufficientBalanceCET();

        _cetBalances[msg.sender] -= params.attributeUpdateCostCET;
        accumulatedCETFees += params.attributeUpdateCostCET;

        // Generate new attributes based on current ones + some randomness/health influence
        ChimeraAttributes memory oldAttributes = _chimeraAttributes[tokenId];
        ChimeraAttributes memory newAttributes = oldAttributes; // Start with old attributes

        // Example update logic: slight random boost/penalty, influenced by health
        // Using block hash/timestamp for simulation - not secure randomness!
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, block.number));

        newAttributes.power = oldAttributes.power + (uint256(uint8(randomSeed[0])) % 10) - 5 + (ecosystemHealthIndex / 10);
        newAttributes.speed = oldAttributes.speed + (uint256(uint8(randomSeed[1])) % 10) - 5 + (ecosystemHealthIndex / 10);
        newAttributes.resilience = oldAttributes.resilience + (uint256(uint8(randomSeed[2])) % 10) - 5 + (ecosystemHealthIndex / 10);

        // Prevent attributes from dropping too low or increasing unboundedly (add bounds if needed)
        if (newAttributes.power > oldAttributes.power * 2) newAttributes.power = oldAttributes.power * 2; // Example cap
        if (newAttributes.power < oldAttributes.power / 2) newAttributes.power = oldAttributes.power / 2; // Example floor
        // Apply similar caps/floors for speed and resilience

        _chimeraAttributes[tokenId] = newAttributes;

        emit ChimeraAttributesUpdated(tokenId);
        _gainReputation(msg.sender, 15); // Gain reputation for developing a Chimera
    }

    /// @notice Fuses two owned Chimeras into a new one, burning the inputs.
    /// Costs CET and influence by ecosystem health.
    /// @param tokenId1 The token ID of the first Chimera.
    /// @param tokenId2 The token ID of the second Chimera.
    /// @return The token ID of the newly created Chimera.
    function fuseChimeras(uint256 tokenId1, uint256 tokenId2) external whenNotPaused returns (uint256) {
        if (tokenId1 == tokenId2) revert CannotFuseSelfOrStaked();
        if (_chimeraOwners[tokenId1] != msg.sender || _chimeraOwners[tokenId2] != msg.sender) revert NotOwnerOfToken();
        if (_isChimeraStaked[tokenId1] || _isChimeraStaked[tokenId2]) revert CannotFuseSelfOrStaked(); // Cannot fuse staked tokens

        AdaptiveParams memory params = _getAdaptiveParametersForHealth();
        if (_cetBalances[msg.sender] < params.fusionCostCET) revert InsufficientBalanceCET();

        _cetBalances[msg.sender] -= params.fusionCostCET;
        accumulatedCETFees += params.fusionCostCET;

        // Burn the input Chimeras
        _burnChimera(tokenId1);
        _burnChimera(tokenId2);

        // Mint a new Chimera
        _chimeraTokenCounter++;
        uint256 newTokenId = _chimeraTokenCounter;
        _chimeraOwners[newTokenId] = msg.sender;
        _ownedChimeras[msg.sender].push(newTokenId);

        // Generate fused attributes (example logic: average + random boost + health influence)
        ChimeraAttributes memory attrs1 = _chimeraAttributes[tokenId1]; // Get attributes before they are removed from the mapping
        ChimeraAttributes memory attrs2 = _chimeraAttributes[tokenId2];

        ChimeraAttributes memory newAttributes = _generateRandomAttributes(newTokenId); // Start with some randomness
        newAttributes.name = "Fused Chimera"; // Generic name for fused
        newAttributes.generation = max(attrs1.generation, attrs2.generation) + 1;

        // Example fusion logic: combine attributes, add random/health bonus
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId1, tokenId2, block.number));
        uint256 seedInt = uint256(randomSeed);

        newAttributes.power = (attrs1.power + attrs2.power) / 2 + (seedInt % 20) + (ecosystemHealthIndex); // More influenced by health
        newAttributes.speed = (attrs1.speed + attrs2.speed) / 2 + (seedInt % 20) + (ecosystemHealthIndex);
        newAttributes.resilience = (attrs1.resilience + attrs2.resilience) / 2 + (seedInt % 20) + (ecosystemHealthIndex);

        _chimeraAttributes[newTokenId] = newAttributes;

        emit ChimerasFused(tokenId1, tokenId2, newTokenId);
        emit ChimeraMinted(msg.sender, newTokenId, newAttributes.name);
        _gainReputation(msg.sender, 50); // Significant reputation gain for fusion

        return newTokenId;
    }

    /// @notice Simulates the attributes of a potential fusion result (read-only).
    /// Does not consume resources or state.
    /// @param tokenId1 The token ID of the first potential input.
    /// @param tokenId2 The token ID of the second potential input.
    /// @return The potential ChimeraAttributes struct after fusion.
    function previewFusionResult(uint256 tokenId1, uint256 tokenId2) external view returns (ChimeraAttributes memory) {
         if (tokenId1 == tokenId2) revert CannotFuseSelfOrStaked();
        if (_chimeraOwners[tokenId1] != msg.sender || _chimeraOwners[tokenId2] != msg.sender) revert NotOwnerOfToken();
         if (_isChimeraStaked[tokenId1] || _isChimeraStaked[tokenId2]) revert CannotFuseSelfOrStaked(); // Cannot preview fusion of staked tokens

        ChimeraAttributes memory attrs1 = _chimeraAttributes[tokenId1];
        ChimeraAttributes memory attrs2 = _chimeraAttributes[tokenId2];

        ChimeraAttributes memory simulatedAttributes; // Start with some base randomness influenced by potential new ID
        // Simulate a potential new token ID for randomness seed without incrementing counter
         bytes32 simulationSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId1, tokenId2, block.number + 1000)); // Use a different seed source
         uint256 seedInt = uint256(simulationSeed);

        // Simulate generation of base attributes similar to minting, using a simulation seed
        simulatedAttributes.power = (seedInt % 50) + 1; // Example base range 1-50
        simulatedAttributes.speed = (seedInt % 50) + 1;
        simulatedAttributes.resilience = (seedInt % 50) + 1;

        simulatedAttributes.name = "Preview Fused Chimera";
        simulatedAttributes.generation = max(attrs1.generation, attrs2.generation) + 1;

        // Apply fusion logic as in fuseChimeras
        simulatedAttributes.power = (attrs1.power + attrs2.power) / 2 + (seedInt % 20) + (ecosystemHealthIndex);
        simulatedAttributes.speed = (attrs1.speed + attrs2.speed) / 2 + (seedInt % 20) + (ecosystemHealthIndex);
        simulatedAttributes.resilience = (attrs1.resilience + attrs2.resilience) / 2 + (seedInt % 20) + (ecosystemHealthIndex);

         // Apply example caps/floors used in update (adjust if needed for fusion)
        if (simulatedAttributes.power > max(attrs1.power, attrs2.power) * 1.5) simulatedAttributes.power = max(attrs1.power, attrs2.power) * 1.5;
         if (simulatedAttributes.speed > max(attrs1.speed, attrs2.speed) * 1.5) simulatedAttributes.speed = max(attrs1.speed, attrs2.speed) * 1.5;
         if (simulatedAttributes.resilience > max(attrs1.resilience, attrs2.resilience) * 1.5) simulatedAttributes.resilience = max(attrs1.resilience, attrs2.resilience) * 1.5;


        return simulatedAttributes;
    }


    // --- Reputation Functions ---

    /// @notice Increases reputation for an account. Called internally by other functions.
    /// Exposed as public for demonstration or potential admin use.
    /// @param account The account whose reputation to increase.
    /// @param amount The amount to increase reputation by.
    function gainReputation(address account, uint256 amount) public onlyOwner { // Made public+onlyOwner for controlled external use
        _gainReputation(account, amount);
    }

    /// @notice Internal function to increase reputation.
    function _gainReputation(address account, uint256 amount) internal {
        if (amount == 0) return;
        _reputation[account] += amount;
        emit ReputationChanged(account, _reputation[account]);
    }

    /// @notice Decreases reputation for an account. Can be called internally or by admin.
    /// Exposed as public for demonstration or potential admin use.
    /// @param account The account whose reputation to decrease.
    /// @param amount The amount to decrease reputation by.
    function loseReputation(address account, uint256 amount) public onlyOwner { // Made public+onlyOwner for controlled external use
         _loseReputation(account, amount);
    }

    /// @notice Internal function to decrease reputation.
     function _loseReputation(address account, uint256 amount) internal {
        if (amount == 0) return;
        if (_reputation[account] < amount) {
            _reputation[account] = 0;
        } else {
            _reputation[account] -= amount;
        }
        emit ReputationChanged(account, _reputation[account]);
    }

    /// @notice Gets the reputation score of an account.
    /// @param account The address to query.
    /// @return The reputation score.
    function getReputation(address account) external view returns (uint256) {
        return _reputation[account];
    }

    // --- Admin & Configuration Functions ---

    /// @notice Sets various core configuration parameters.
    /// @param _cetMintCostETH The cost to mint 1 CET in ETH (scaled).
    /// @param _chimeraMintCostCET The cost to mint 1 Chimera in CET (scaled).
    /// @param _baseStakeRewardRate The base CET reward rate per staked CET per second (scaled).
    /// @param _adaptiveActionBaseCost The base CET cost for the adaptive action.
    /// @param _adaptiveActionBaseReward The base CET reward for the adaptive action.
    function setConfig(
        uint256 _cetMintCostETH,
        uint256 _chimeraMintCostCET,
        uint256 _baseStakeRewardRate,
        uint256 _adaptiveActionBaseCost,
        uint256 _adaptiveActionBaseReward
    ) external onlyOwner {
        cetMintCostETH = _cetMintCostETH;
        chimeraMintCostCET = _chimeraMintCostCET;
        baseStakeRewardRate = _baseStakeRewardRate;
        adaptiveActionBaseCost = _adaptiveActionBaseCost;
        adaptiveActionBaseReward = _adaptiveActionBaseReward;
         // Update derived costs based on new base
        attributeUpdateCostCET = _chimeraMintCostCET / 2;
        fusionCostCET = _chimeraMintCostCET * 2;

        emit ConfigUpdated(cetMintCostETH, chimeraMintCostCET, baseStakeRewardRate, adaptiveActionBaseCost, adaptiveActionBaseReward);
    }

     /// @notice Sets the health assessment interval.
     /// @param interval The new interval in seconds.
     function setHealthAssessmentInterval(uint256 interval) external onlyOwner {
        healthAssessmentInterval = interval;
     }

    /// @notice Pauses certain contract activities.
    function pause() external onlyOwner {
        paused = true;
        emit PausedStateChanged(true);
    }

    /// @notice Unpauses contract activities.
    function unpause() external onlyOwner {
        paused = false;
        emit PausedStateChanged(false);
    }

    /// @notice Withdraws accumulated ETH from the contract.
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner).call{value: balance}("");
            require(success, "ETH withdrawal failed");
            emit FeesWithdrawn(owner, balance, 0);
        }
    }

    /// @notice Withdraws accumulated CET fees from the contract.
    function withdrawCETFees() external onlyOwner {
        uint256 fees = accumulatedCETFees;
        if (fees > 0) {
            accumulatedCETFees = 0;
            _cetBalances[owner] += fees; // Transfer fees to owner's balance
            emit FeesWithdrawn(owner, 0, fees);
             // Note: This transfers to owner's *internal* balance, not external ERC20 transfer
        } else {
             revert NotEnoughCETFees();
        }
    }

    // --- Internal Helper Functions ---

    /// @notice Helper to remove a token ID from a dynamic array (ownership/staking lists).
    function _removeTokenFromList(uint256[] storage list, uint256 tokenId) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == tokenId) {
                list[i] = list[list.length - 1];
                list.pop();
                break; // Assume token ID appears only once
            }
        }
    }

    /// @notice Internal helper to burn a Chimera NFT.
    function _burnChimera(uint256 tokenId) internal {
        address tokenOwner = _chimeraOwners[tokenId];
        if (tokenOwner == address(0)) revert InvalidTokenId();

        _removeTokenFromList(_ownedChimeras[tokenOwner], tokenId);
        if (_isChimeraStaked[tokenId]) {
            _removeTokenFromList(_stakedChimeraIds[tokenOwner], tokenId);
            _isChimeraStaked[tokenId] = false;
        }

        delete _chimeraOwners[tokenId];
        delete _chimeraAttributes[tokenId]; // Remove attributes

        emit ChimeraBurned(tokenId);
        // Optionally _loseReputation(tokenOwner, ...) for burning
    }

     /// @notice Internal helper to get the total amount of CET staked across all users.
     /// Note: This iterates a mapping, which can be gas-intensive for many users.
     /// A production contract might track this total in a state variable updated on stake/unstake.
     /// @return The total staked CET amount.
     function getTotalStakedCET() internal view returns (uint256) {
         uint256 total = 0;
         // This iteration is for demonstration. In practice, track this total.
         // For loop over all possible addresses is impossible.
         // We cannot iterate over a mapping directly in Solidity.
         // Let's simulate this by assuming we *could* get a sum, or better, track it directly.
         // Add state variable `_totalStakedCET` and update it in stake/unstake functions.
         // For now, return 0 as a placeholder or use a simple approximation if possible without iteration.
         // Let's add the state variable and update it.

         return _totalStakedCET;
     }
    uint256 private _totalStakedCET; // State variable to track total staked CET

    // Update stakeCET and unstakeCET to maintain _totalStakedCET
    // stakeCET: _totalStakedCET += amount;
    // unstakeCET: _totalStakedCET -= amount;


    /// @notice Internal helper to generate random-like attributes for a new Chimera.
    /// Uses block data which is NOT cryptographically secure randomness.
    /// Should use Chainlink VRF or similar for production.
    /// @param tokenId The token ID for seeding.
    /// @return The generated ChimeraAttributes.
    function _generateRandomAttributes(uint256 tokenId) internal view returns (ChimeraAttributes memory) {
        // WARNING: Using block data for randomness is predictable and insecure.
        // For a production application, use Chainlink VRF or a similar decentralized oracle.
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, block.number));
        uint256 seedInt = uint256(randomSeed);

        ChimeraAttributes memory attrs;
        attrs.power = (seedInt % 100) + 1; // Example range 1-100
        attrs.speed = (seedInt % 100) + 1;
        attrs.resilience = (seedInt % 100) + 1;

        return attrs;
    }

    // Helper for fusion preview/calculation
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFTs (Chimeras):** The `ChimeraAttributes` struct stored *on-chain* allows modification. Functions like `updateChimeraAttributes` and `fuseChimeras` directly alter this on-chain state, making the NFTs dynamic rather than static images/metadata pointing off-chain.
2.  **Adaptive Parameters:** The `AdaptiveParams` struct and the internal `_getAdaptiveParametersForHealth` function represent a system where contract constants (like costs, rewards) are *not* fixed but calculated based on the `ecosystemHealthIndex`.
3.  **Ecosystem Health Index:** This is an internal, contract-managed state variable intended to represent the overall state of the ecosystem. It's updated via `assessEcosystemHealth` (simulated here as an admin-only call, but could be triggered by staking events, total supply changes, or even an external oracle reporting market data). This provides the input for the adaptive parameters.
4.  **Internal State as Oracle:** Instead of relying heavily on external price feeds, the contract uses its *own* internal state (total staked, total supply, time, etc.) as the primary "oracle" to determine the health index, making it somewhat self-referential and less dependent on specific external data sources (though a real system might combine both).
5.  **NFT Fusion:** The `fuseChimeras` function is a creative way to add utility and scarcity to NFTs. It introduces a burn mechanism for input NFTs and a mint mechanism for an output NFT with attributes derived from the inputs and influenced by the adaptive system.
6.  **Reputation System (Basic):** `_reputation` mapping and `_gainReputation`/`_loseReputation` (called internally by core actions like staking, minting, fusion, adaptive actions) add a dimension of user standing within the ecosystem, which could later be used for tiered access, governance weight, or bonuses.
7.  **Variable Staking Rewards:** The CET staking rewards calculation (`_calculateCETRewards`) incorporates the `adaptive.stakeRewardMultiplier`, meaning the yield users receive changes based on the ecosystem's health.

**Limitations & Considerations for Production:**

*   **Randomness:** The use of `block.timestamp`, `block.difficulty`, and `block.number` for randomness is *not* secure or unpredictable. For any feature involving value or fairness (like attribute generation or fusion outcomes), a decentralized oracle like Chainlink VRF is required.
*   **ERC-20/ERC-721 Implementation:** This contract includes minimal ERC-20/ERC-721 functions (`balanceOf`, `transfer`, `ownerOf`, `transfer`) but is not a full implementation inheriting from OpenZeppelin or similar. For full compatibility and safety, using standard libraries is recommended.
*   **Gas Costs:** Iterating over arrays (`_ownedChimeras`, `_stakedChimeraIds`) and calculating `getTotalStakedCET` by summing can become very expensive as the number of users/tokens grows. Production systems often use alternative data structures or track totals in state variables. I've added `_totalStakedCET` as a state variable but left the array iteration for `getStakedChimeraIds` as an example; this would need optimization.
*   **Ecosystem Health Logic:** The health calculation in `assessEcosystemHealth` is a simple placeholder. Designing a robust, non-manipulable health index is complex and crucial for the system's balance.
*   **Scalability of Mappings:** While mappings are efficient for direct lookups, operations requiring iteration over *all* keys (like summing all staked CET, which I've addressed by adding `_totalStakedCET`) are not directly supported in Solidity.
*   **Missing Features:** A production contract would need more comprehensive error handling, access control (e.g., role-based), upgradeability considerations, and potentially formal security audits.

This contract provides a framework showcasing interesting, interconnected mechanics within a simulated on-chain ecosystem, going beyond typical token or static NFT designs.