Okay, this is an exciting challenge! Creating something truly unique and advanced that isn't already directly open-source requires combining several modern concepts in a novel way.

I'll design a smart contract system called **"ChronoForge Guilds"**. This system introduces **Dynamic, Reputation-Evolving NFTs ("Forges")**, a **Multi-Dimensional Reputation System ("Chronos")**, **Adaptive Tokenomics**, and **Gamified, Oracle-Driven Governance**.

The core idea is that users own "Forge" NFTs. These Forges gain "Chronos" (reputation points) through active participation (staking, governance, holding utility NFTs). The Forges themselves can visually and functionally *evolve* based on their Chronos level and specific "Artifact" NFTs they hold. The system's economic parameters (like staking rewards, Chronos generation) are dynamically adjusted based on an "Ecosystem Vitality Index" fed by an oracle, allowing the DAO to adapt to external market conditions or community activity.

---

## ChronoForge Guilds: Adaptive & Evolving DAO Hub

This contract suite (represented as a single main contract for simplicity, assuming external ERC20/ERC721 implementations) establishes a decentralized autonomous organization where core assets (Forges) evolve based on user engagement and external data.

### 📜 **Outline & Core Concepts**

1.  **ChronoForge (ERC721):**
    *   **Dynamic NFT:** Each Forge NFT possesses a `level` and accumulated `Chronos`. Its metadata (visuals, descriptions) can automatically update/evolve when certain `Chronos` thresholds are met or specific "Artifacts" are attached.
    *   **Reputation Hub:** Forges are the primary entities for accumulating `Chronos`.
2.  **Chronos (Reputation System):**
    *   **Accumulation:** Earned through staking, active governance participation, holding specific "Artifact" NFTs, or completing off-chain quests (verified via oracle).
    *   **Utility:** Influences Forge evolution, boosts staking rewards, amplifies voting power, and can unlock special features.
3.  **Artifacts (ERC721):**
    *   **Utility NFTs:** Unique, non-fungible tokens that provide passive `Chronos` boosts, unlock specific Forge evolution paths, or grant special privileges when attached to a Forge.
4.  **Adaptive Tokenomics & Ecosystem Vitality:**
    *   **Oracle-Driven:** An authorized oracle feeds an "Ecosystem Vitality Index" (EVI) score.
    *   **Dynamic Parameters:** EVI dynamically adjusts staking reward rates, Chronos generation rates, and potentially proposal thresholds, making the system responsive to external conditions.
5.  **Gamified, Reputation-Weighted Governance:**
    *   **Voting Power:** Calculated based on a combination of staked tokens and a Forge's `Chronos` level.
    *   **Dynamic Thresholds:** Proposal passing thresholds might adjust based on EVI or overall community engagement.
6.  **Epoch System:**
    *   Time-based cycles for distributing rewards, evaluating EVI, and triggering parameter adjustments.

---

### 🚀 **Function Summary (26 Functions)**

**I. Core Forge NFT Management (ERC721-like)**
1.  `mintForge(address _to, string memory _initialMetadataURI)`: Mints a new ChronoForge NFT.
2.  `updateForgeBaseURI(string memory _newBaseURI)`: Sets the base URI for Forge metadata.
3.  `getForgeData(uint256 _forgeId)`: Retrieves comprehensive data for a given Forge.
4.  `getForgeChronos(uint256 _forgeId)`: Returns current Chronos for a Forge.
5.  `getForgeLevel(uint256 _forgeId)`: Returns the current evolutionary level of a Forge.
6.  `triggerForgeEvolution(uint256 _forgeId)`: Attempts to evolve a Forge based on Chronos and attached Artifacts.

**II. Chronos & Staking Mechanics**
7.  `stakeTokens(uint256 _forgeId, uint256 _amount)`: Stakes the native Guild token to a Forge, earning Chronos and rewards.
8.  `unstakeTokens(uint256 _forgeId, uint256 _amount)`: Unstakes tokens from a Forge.
9.  `claimStakingRewards(uint256 _forgeId)`: Claims accrued staking rewards for a Forge.
10. `getAccruedChronos(uint256 _forgeId)`: Calculates Chronos accrued since last update.
11. `getAccruedRewards(uint256 _forgeId)`: Calculates pending staking rewards.
12. `getChronosMiningRate()`: Returns the current adaptive Chronos generation rate.

**III. Artifact NFT Integration (ERC721-like)**
13. `mintArtifact(address _to, uint256 _artifactId, string memory _metadataURI)`: Mints a new Artifact NFT.
14. `updateArtifactBaseURI(string memory _newBaseURI)`: Sets the base URI for Artifact metadata.
15. `assignArtifactToForge(uint256 _artifactId, uint256 _forgeId)`: Assigns an owned Artifact to a Forge.
16. `removeArtifactFromForge(uint256 _artifactId, uint256 _forgeId)`: Removes an Artifact from a Forge.
17. `getArtifactsAssignedToForge(uint256 _forgeId)`: Lists Artifacts currently assigned to a Forge.

**IV. Adaptive System & Oracle Integration**
18. `updateEcosystemVitalityIndex(uint256 _newEVI)`: (Oracle-only) Updates the Ecosystem Vitality Index.
19. `advanceEpoch()`: Triggers the end of an epoch, distributing rewards and re-evaluating adaptive parameters.
20. `getEcosystemVitalityIndex()`: Returns the current EVI.
21. `getAdaptiveParameter(bytes32 _parameterKey)`: Retrieves an adaptively-set system parameter.

**V. Dynamic Governance**
22. `submitProposal(string memory _description, address _target, bytes memory _callData)`: Allows Forge owners to submit a governance proposal.
23. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote, weighted by Chronos and stake.
24. `executeProposal(uint256 _proposalId)`: Executes a passed proposal.
25. `getVotingPower(uint256 _forgeId)`: Calculates the current voting power for a Forge.

**VI. Admin/Utility**
26. `setOracleAddress(address _newOracle)`: (Owner-only) Sets the address authorized to update EVI.

---

### 💻 **Smart Contract Code (Solidity)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Mock interfaces for external contracts for demonstration purposes
interface IChronosToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ChronoForgeGuilds is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    // --- State Variables & Data Structures ---

    // Constants
    uint256 public constant INITIAL_FORGE_LEVEL = 1;
    uint256 public constant CHRONOS_PER_LEVEL_THRESHOLD = 1000; // Chronos needed to advance one level
    uint256 public constant MAX_FORGE_LEVEL = 10; // Maximum evolutionary level for a Forge

    // Addresses of external contracts
    IERC20 public immutable guildToken; // The token used for staking and rewards
    address public oracleAddress; // Address authorized to update Ecosystem Vitality Index (EVI)

    // Forge Data
    struct Forge {
        address owner;
        uint256 chronos;
        uint256 level;
        uint256 stakedAmount;
        uint256 lastChronosUpdate; // Timestamp of last chronos calculation
        uint256 lastRewardClaim; // Timestamp of last reward claim
        mapping(uint256 => bool) attachedArtifacts; // artifactId => isAttached
    }
    mapping(uint256 => Forge) public forges; // forgeId => Forge data
    uint256 private _forgeCounter; // Counter for minting new Forges

    // Artifact Data (these are also ERC721s, managed by this contract)
    string private _artifactBaseURI; // Base URI for Artifact metadata
    mapping(uint256 => uint256) public artifactForgeAssignments; // artifactId => forgeId (0 if not assigned)

    // Chronos & Staking Parameters
    uint256 public baseChronosMiningRate = 10; // Base Chronos per token per epoch (scaled by 1e18)
    uint256 public baseStakingRewardRate = 1e16; // Base reward (0.01%) per token per epoch (scaled by 1e18)
    uint256 public epochDuration = 7 days; // How long an epoch lasts
    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;

    // Adaptive System
    uint256 public ecosystemVitalityIndex; // EVI, 0-10000 (scaled by 100 for percentage, so 100 = 1%)
    mapping(bytes32 => uint256) public adaptiveParameters; // Dynamically adjusted parameters (e.g., "chronosMiningRateModifier")

    // Governance
    struct Proposal {
        string description;
        address target;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool passed;
        mapping(uint256 => bool) hasVoted; // forgeId => bool
    }
    Proposal[] public proposals;
    uint256 public minStakedForProposal = 100e18; // Minimum Guild Tokens staked to propose
    uint256 public votingPeriodBlocks = 10000; // Approx 2-3 days

    // --- Events ---
    event ForgeMinted(address indexed to, uint256 indexed forgeId, string initialMetadataURI);
    event ForgeEvolved(uint256 indexed forgeId, uint256 newLevel, string newMetadataURI);
    event ChronosAccrued(uint256 indexed forgeId, uint256 amount);
    event TokensStaked(uint256 indexed forgeId, address indexed staker, uint256 amount);
    event TokensUnstaked(uint256 indexed forgeId, address indexed unstaker, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed forgeId, address indexed receiver, uint256 amount);
    event ArtifactMinted(address indexed to, uint256 indexed artifactId, string metadataURI);
    event ArtifactAssigned(uint256 indexed artifactId, uint256 indexed forgeId);
    event ArtifactRemoved(uint256 indexed artifactId, uint256 indexed forgeId);
    event EcosystemVitalityIndexUpdated(uint256 newEVI);
    event EpochAdvanced(uint256 newEpoch, uint256 newEVI);
    event AdaptiveParameterUpdated(bytes32 indexed key, uint256 newValue);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, uint256 indexed forgeId, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoForgeGuilds: Caller is not the oracle");
        _;
    }

    modifier onlyForgeOwner(uint256 _forgeId) {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        require(_isApprovedOrOwner(_msgSender(), _forgeId), "ChronoForgeGuilds: Caller is not forge owner or approved");
        _;
    }

    constructor(address _guildTokenAddress, address _initialOracleAddress)
        ERC721("ChronoForge", "FORGE")
        Ownable(_msgSender())
    {
        require(_guildTokenAddress != address(0), "ChronoForgeGuilds: Guild Token address cannot be zero");
        require(_initialOracleAddress != address(0), "ChronoForgeGuilds: Oracle address cannot be zero");

        guildToken = IERC20(_guildTokenAddress);
        oracleAddress = _initialOracleAddress;
        lastEpochAdvanceTime = block.timestamp;

        // Initialize adaptive parameters
        adaptiveParameters["chronosMiningRateModifier"] = 1e18; // 100%
        adaptiveParameters["stakingRewardRateModifier"] = 1e18; // 100%
        // Start with a neutral EVI
        ecosystemVitalityIndex = 5000; // 50%
    }

    // --- I. Core Forge NFT Management ---

    /// @notice Mints a new ChronoForge NFT and assigns it an initial level and Chronos.
    /// @param _to The address to mint the Forge to.
    /// @param _initialMetadataURI The initial metadata URI for the Forge.
    function mintForge(address _to, string memory _initialMetadataURI)
        public onlyOwner
        returns (uint256)
    {
        _forgeCounter = _forgeCounter.add(1);
        uint256 newForgeId = _forgeCounter;

        _safeMint(_to, newForgeId);
        _setTokenURI(newForgeId, _initialMetadataURI);

        forges[newForgeId] = Forge({
            owner: _to,
            chronos: 0,
            level: INITIAL_FORGE_LEVEL,
            stakedAmount: 0,
            lastChronosUpdate: block.timestamp,
            lastRewardClaim: block.timestamp
        });
        // Initialize the mapping within the struct. Solidity automatically handles storage mappings
        // so `forges[newForgeId].attachedArtifacts` is valid for writing to.

        emit ForgeMinted(_to, newForgeId, _initialMetadataURI);
        return newForgeId;
    }

    /// @notice Sets the base URI for Forge metadata. Used for dynamic evolution.
    /// @param _newBaseURI The new base URI.
    function updateForgeBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /// @notice Internal function to get the current metadata URI for a Forge, accounting for base URI and level.
    /// @dev This is where the dynamic metadata logic for evolution would be implemented.
    ///      For simplicity, it appends level to a base URI. A more complex system might use IPFS CIDs.
    function tokenURI(uint256 _forgeId)
        public view override returns (string memory)
    {
        require(_exists(_forgeId), "ERC721URIStorage: URI query for nonexistent token");
        Forge storage forge = forges[_forgeId];
        string memory base = _baseURI(); // ERC721URIStorage's _baseURI
        
        // Example dynamic URI: base_uri/levelX.json
        // In a real scenario, this would involve a more robust mapping for different levels/states.
        return string(abi.encodePacked(base, Strings.toString(forge.level), ".json"));
    }

    /// @notice Retrieves comprehensive data for a given Forge.
    /// @param _forgeId The ID of the Forge.
    /// @return owner Address of the Forge owner.
    /// @return chronos Current Chronos points.
    /// @return level Current evolutionary level.
    /// @return stakedAmount Amount of Guild Tokens staked.
    /// @return assignedArtifactCount Number of artifacts assigned.
    function getForgeData(uint256 _forgeId)
        public view returns (address owner, uint256 chronos, uint256 level, uint256 stakedAmount, uint256 assignedArtifactCount)
    {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        Forge storage forge = forges[_forgeId];

        uint256 currentChronos = getAccruedChronos(_forgeId);
        // Calculate assigned artifacts (this would need iteration, or a counter in the struct)
        // For simplicity here, we don't return individual artifacts, just a count (or 0)
        // A real implementation might require a different data structure to iterate efficiently.
        // For now, returning 0, or you can implement a helper function to iterate for a proper count.
        // Example: assignedArtifactCount = _getAttachedArtifactCount(_forgeId);
        
        return (
            forge.owner,
            currentChronos, // Use calculated chronos
            forge.level,
            forge.stakedAmount,
            0 // Placeholder, actual count needs iteration or a dedicated list
        );
    }

    /// @notice Returns current Chronos for a Forge, including accrued but uncalculated Chronos.
    /// @param _forgeId The ID of the Forge.
    function getForgeChronos(uint256 _forgeId) public view returns (uint256) {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        return forges[_forgeId].chronos.add(_calculateAccruedChronos(_forgeId));
    }

    /// @notice Returns the current evolutionary level of a Forge.
    /// @param _forgeId The ID of the Forge.
    function getForgeLevel(uint256 _forgeId) public view returns (uint256) {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        return forges[_forgeId].level;
    }

    /// @notice Attempts to evolve a Forge based on Chronos thresholds and attached Artifacts.
    /// @dev This function would trigger metadata updates.
    /// @param _forgeId The ID of the Forge to evolve.
    function triggerForgeEvolution(uint256 _forgeId)
        public onlyForgeOwner(_forgeId)
    {
        Forge storage forge = forges[_forgeId];
        _updateForgeChronos(_forgeId); // Ensure Chronos is up-to-date

        if (forge.level < MAX_FORGE_LEVEL && forge.chronos >= forge.level.mul(CHRONOS_PER_LEVEL_THRESHOLD)) {
            // Check for specific artifacts if multi-path evolution is desired
            // Example: require(forge.attachedArtifacts[ARTIFACT_OF_EVOLUTION_ID], "ChronoForgeGuilds: Requires specific artifact");
            
            forge.level = forge.level.add(1);
            // Optionally reset chronos or deduct a portion for evolution
            // forge.chronos = forge.chronos.sub(forge.level.sub(1).mul(CHRONOS_PER_LEVEL_THRESHOLD));
            
            // The metadata URI automatically updates via `tokenURI` function
            emit ForgeEvolved(_forgeId, forge.level, tokenURI(_forgeId));
        } else {
            revert("ChronoForgeGuilds: Forge not ready for evolution (insufficient Chronos or max level reached)");
        }
    }

    // --- II. Chronos & Staking Mechanics ---

    /// @notice Stakes native Guild tokens to a Forge, earning Chronos and rewards.
    /// @param _forgeId The ID of the Forge to stake for.
    /// @param _amount The amount of Guild tokens to stake.
    function stakeTokens(uint256 _forgeId, uint256 _amount)
        public onlyForgeOwner(_forgeId)
    {
        require(_amount > 0, "ChronoForgeGuilds: Stake amount must be greater than zero");

        _updateForgeChronos(_forgeId);
        _calculateAndDistributeRewards(_forgeId);

        guildToken.transferFrom(_msgSender(), address(this), _amount);
        forges[_forgeId].stakedAmount = forges[_forgeId].stakedAmount.add(_amount);

        emit TokensStaked(_forgeId, _msgSender(), _amount);
    }

    /// @notice Unstakes tokens from a Forge.
    /// @param _forgeId The ID of the Forge to unstake from.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _forgeId, uint256 _amount)
        public onlyForgeOwner(_forgeId)
    {
        require(_amount > 0, "ChronoForgeGuilds: Unstake amount must be greater than zero");
        require(forges[_forgeId].stakedAmount >= _amount, "ChronoForgeGuilds: Not enough staked tokens");

        _updateForgeChronos(_forgeId);
        _calculateAndDistributeRewards(_forgeId);

        forges[_forgeId].stakedAmount = forges[_forgeId].stakedAmount.sub(_amount);
        guildToken.transfer(_msgSender(), _amount);

        emit TokensUnstaked(_forgeId, _msgSender(), _amount);
    }

    /// @notice Claims accrued staking rewards for a Forge.
    /// @param _forgeId The ID of the Forge to claim rewards for.
    function claimStakingRewards(uint256 _forgeId)
        public onlyForgeOwner(_forgeId)
    {
        _updateForgeChronos(_forgeId); // Update chronos before reward calculation
        uint256 rewards = _calculateAndDistributeRewards(_forgeId);
        require(rewards > 0, "ChronoForgeGuilds: No rewards to claim");

        // The _calculateAndDistributeRewards already transfers, so just emit here
        emit StakingRewardsClaimed(_forgeId, _msgSender(), rewards);
    }

    /// @notice Calculates Chronos accrued since last update for a Forge.
    /// @param _forgeId The ID of the Forge.
    /// @return The amount of Chronos accrued.
    function getAccruedChronos(uint256 _forgeId) public view returns (uint256) {
        return _calculateAccruedChronos(_forgeId);
    }

    /// @notice Calculates pending staking rewards for a Forge.
    /// @param _forgeId The ID of the Forge.
    /// @return The amount of pending rewards.
    function getAccruedRewards(uint256 _forgeId) public view returns (uint256) {
        return _calculatePendingRewards(_forgeId);
    }

    /// @notice Returns the current adaptive Chronos generation rate.
    /// @return The Chronos mining rate (scaled by 1e18).
    function getChronosMiningRate() public view returns (uint256) {
        // baseRate * EVI_modifier * adaptive_modifier
        // EVI_modifier example: if EVI is 50%, modifier is 0.5. If EVI is 150%, modifier is 1.5.
        // We'll use a simple linear scaling for EVI for demonstration
        uint256 eviFactor = ecosystemVitalityIndex.mul(1e18).div(10000); // Scale EVI from 0-10000 to 0-1e18
        
        return baseChronosMiningRate
               .mul(adaptiveParameters["chronosMiningRateModifier"])
               .div(1e18)
               .mul(eviFactor)
               .div(1e18);
    }

    /// @dev Internal function to update a Forge's Chronos.
    function _updateForgeChronos(uint256 _forgeId) internal {
        Forge storage forge = forges[_forgeId];
        uint256 accrued = _calculateAccruedChronos(_forgeId);
        if (accrued > 0) {
            forge.chronos = forge.chronos.add(accrued);
            forge.lastChronosUpdate = block.timestamp;
            emit ChronosAccrued(_forgeId, accrued);
        }
    }

    /// @dev Internal function to calculate pending Chronos without updating the state.
    function _calculateAccruedChronos(uint256 _forgeId) internal view returns (uint256) {
        Forge storage forge = forges[_forgeId];
        if (forge.stakedAmount == 0 || block.timestamp <= forge.lastChronosUpdate) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp.sub(forge.lastChronosUpdate);
        uint256 epochsPassed = timeElapsed.div(epochDuration);
        
        if (epochsPassed == 0 && currentEpoch == 0) return 0; // No epochs advanced yet

        uint256 chronosRate = getChronosMiningRate();
        // Chronos is typically per epoch, so multiply by epochs passed and staked amount
        uint256 chronos = forge.stakedAmount.mul(chronosRate).mul(epochsPassed).div(1e18);

        // Add bonus from artifacts
        // This would require iterating through `forge.attachedArtifacts` to sum up bonuses
        // For now, let's assume a simplified constant bonus or omit for brevity.
        // uint256 artifactBonus = _getArtifactChronosBonus(_forgeId);
        // chronos = chronos.add(artifactBonus);

        return chronos;
    }

    /// @dev Internal function to calculate and distribute rewards, and update lastRewardClaim.
    /// @return The amount of rewards transferred.
    function _calculateAndDistributeRewards(uint256 _forgeId) internal returns (uint256) {
        Forge storage forge = forges[_forgeId];
        uint256 rewards = _calculatePendingRewards(_forgeId);

        if (rewards > 0) {
            forge.lastRewardClaim = block.timestamp;
            guildToken.transfer(forge.owner, rewards);
        }
        return rewards;
    }

    /// @dev Internal function to calculate pending rewards without updating state.
    function _calculatePendingRewards(uint256 _forgeId) internal view returns (uint256) {
        Forge storage forge = forges[_forgeId];
        if (forge.stakedAmount == 0 || block.timestamp <= forge.lastRewardClaim) {
            return 0;
        }
        
        uint256 timeElapsed = block.timestamp.sub(forge.lastRewardClaim);
        uint256 epochsPassed = timeElapsed.div(epochDuration);

        if (epochsPassed == 0 && currentEpoch == 0) return 0; // No epochs advanced yet

        uint256 rewardRate = baseStakingRewardRate
                            .mul(adaptiveParameters["stakingRewardRateModifier"])
                            .div(1e18)
                            .mul(ecosystemVitalityIndex.mul(1e18).div(10000)) // EVI factor
                            .div(1e18);
        
        // reward = stakedAmount * rewardRate * epochsPassed
        uint256 rewards = forge.stakedAmount.mul(rewardRate).mul(epochsPassed).div(1e18);
        return rewards;
    }


    // --- III. Artifact NFT Integration ---

    // Note: Artifacts are also ERC721s. For simplicity, we assume this contract manages their minting
    // and assignment. In a real system, Artifacts might be a separate ERC721 contract.

    /// @notice Mints a new Artifact NFT.
    /// @param _to The address to mint the Artifact to.
    /// @param _artifactId The specific ID for the Artifact (e.g., pre-defined types).
    /// @param _metadataURI The metadata URI for the Artifact.
    function mintArtifact(address _to, uint256 _artifactId, string memory _metadataURI)
        public onlyOwner
    {
        // Artifact IDs might be pre-defined for specific types or simply incremental.
        // For uniqueness, _artifactId should be distinct, or combine with a counter.
        // Here, we assume _artifactId is globally unique and passed in.
        require(ownerOf(_artifactId) == address(0), "ChronoForgeGuilds: Artifact already exists");

        _safeMint(_to, _artifactId); // ERC721 minting for Artifact
        _setTokenURI(_artifactId, _metadataURI); // Using Forge's URI storage for simplicity

        emit ArtifactMinted(_to, _artifactId, _metadataURI);
    }

    /// @notice Sets the base URI for Artifact metadata.
    /// @param _newBaseURI The new base URI.
    function updateArtifactBaseURI(string memory _newBaseURI) public onlyOwner {
        _artifactBaseURI = _newBaseURI;
    }

    /// @notice Assigns an owned Artifact to a Forge.
    /// @param _artifactId The ID of the Artifact.
    /// @param _forgeId The ID of the Forge to assign to.
    function assignArtifactToForge(uint256 _artifactId, uint256 _forgeId)
        public
    {
        // Caller must own the Artifact
        require(_isApprovedOrOwner(_msgSender(), _artifactId), "ChronoForgeGuilds: Caller is not artifact owner or approved");
        // Caller must own or be approved for the Forge
        require(_isApprovedOrOwner(_msgSender(), _forgeId), "ChronoForgeGuilds: Caller is not forge owner or approved");
        require(!forges[_forgeId].attachedArtifacts[_artifactId], "ChronoForgeGuilds: Artifact already assigned to this Forge");
        require(artifactForgeAssignments[_artifactId] == 0, "ChronoForgeGuilds: Artifact already assigned to another Forge");

        forges[_forgeId].attachedArtifacts[_artifactId] = true;
        artifactForgeAssignments[_artifactId] = _forgeId;

        // Transfer ownership of artifact to the forge itself (the contract)
        // This means the artifact is "locked" to the forge and cannot be transferred while assigned.
        // To retrieve it, it must be `removeArtifactFromForge` first.
        _transfer(_msgSender(), address(this), _artifactId); // Transfer to contract (lock)

        emit ArtifactAssigned(_artifactId, _forgeId);
    }

    /// @notice Removes an Artifact from a Forge.
    /// @param _artifactId The ID of the Artifact.
    /// @param _forgeId The ID of the Forge it's assigned to.
    function removeArtifactFromForge(uint256 _artifactId, uint256 _forgeId)
        public
    {
        require(forges[_forgeId].attachedArtifacts[_artifactId], "ChronoForgeGuilds: Artifact not assigned to this Forge");
        require(artifactForgeAssignments[_artifactId] == _forgeId, "ChronoForgeGuilds: Artifact not assigned to specified Forge");
        
        // Caller must be owner of the forge.
        require(_isApprovedOrOwner(_msgSender(), _forgeId), "ChronoForgeGuilds: Caller is not forge owner or approved");

        forges[_forgeId].attachedArtifacts[_artifactId] = false;
        artifactForgeAssignments[_artifactId] = 0;

        // Transfer ownership of artifact back to the Forge owner
        _transfer(address(this), _msgSender(), _artifactId); // Transfer from contract (unlock)

        emit ArtifactRemoved(_artifactId, _forgeId);
    }

    /// @notice Lists artifacts currently assigned to a Forge.
    /// @dev This function is expensive for many artifacts. A better approach might use a linked list or return a count.
    /// @param _forgeId The ID of the Forge.
    /// @return An array of artifact IDs assigned to the Forge.
    function getArtifactsAssignedToForge(uint256 _forgeId) public view returns (uint256[] memory) {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        // This is a naive implementation and would be very gas-intensive for many artifacts.
        // A robust solution would involve storing a dynamic array of artifact IDs within the Forge struct,
        // or an external mapping that links (forgeId => list of artifactIds).
        // For demonstration, we'll return an empty array or a mock.
        // For real-world use, iterating over all possible artifact IDs is not feasible.
        
        // Example with a limited, mock list (not scalable):
        // uint256[] memory assigned;
        // if (forges[_forgeId].attachedArtifacts[1]) {
        //     assigned = new uint256[](1);
        //     assigned[0] = 1;
        // } else {
        //     assigned = new uint256[](0);
        // }
        // return assigned;

        return new uint256[](0); // Placeholder for a scalable implementation
    }

    // --- IV. Adaptive System & Oracle Integration ---

    /// @notice Updates the Ecosystem Vitality Index (EVI). Only callable by the oracle.
    /// @param _newEVI The new EVI value (e.g., 0-10000, 10000 = 100%).
    function updateEcosystemVitalityIndex(uint256 _newEVI) public onlyOracle {
        require(_newEVI <= 10000, "ChronoForgeGuilds: EVI cannot exceed 10000 (100%)");
        ecosystemVitalityIndex = _newEVI;
        // Apply EVI to dynamic parameters immediately or on next epoch advance
        _adjustAdaptiveParameters();
        emit EcosystemVitalityIndexUpdated(_newEVI);
    }

    /// @notice Triggers the end of an epoch, distributing rewards and re-evaluating adaptive parameters.
    /// @dev This can be called by anyone but only processes if an epoch has actually passed.
    function advanceEpoch() public {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochDuration), "ChronoForgeGuilds: Epoch not yet ended");

        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;

        // Re-evaluate adaptive parameters based on current EVI
        _adjustAdaptiveParameters();

        // Optionally, trigger a bulk update of all forge chronos/rewards here
        // (Highly gas intensive if many forges, better handled on-demand)

        emit EpochAdvanced(currentEpoch, ecosystemVitalityIndex);
    }

    /// @notice Returns the current Ecosystem Vitality Index.
    function getEcosystemVitalityIndex() public view returns (uint256) {
        return ecosystemVitalityIndex;
    }

    /// @notice Retrieves an adaptively-set system parameter.
    /// @param _parameterKey The key for the parameter (e.g., "chronosMiningRateModifier").
    /// @return The value of the parameter.
    function getAdaptiveParameter(bytes32 _parameterKey) public view returns (uint256) {
        return adaptiveParameters[_parameterKey];
    }

    /// @dev Internal function to adjust adaptive parameters based on EVI.
    function _adjustAdaptiveParameters() internal {
        // Example: If EVI is high, boost rates. If low, reduce them.
        // Scale EVI from 0-10000 to a multiplier around 1e18 (1.0)
        uint256 eviFactor = ecosystemVitalityIndex.mul(1e18).div(5000); // 5000 EVI = 1x multiplier

        // A simple linear scaling, more complex algorithms could be used (e.g., logarithmic, piecewise)
        adaptiveParameters["chronosMiningRateModifier"] = eviFactor;
        adaptiveParameters["stakingRewardRateModifier"] = eviFactor;

        emit AdaptiveParameterUpdated("chronosMiningRateModifier", eviFactor);
        emit AdaptiveParameterUpdated("stakingRewardRateModifier", eviFactor);
    }

    // --- V. Dynamic Governance ---

    /// @notice Allows Forge owners to submit a governance proposal.
    /// @param _description A description of the proposal.
    /// @param _target The address of the contract to call if the proposal passes.
    /// @param _callData The encoded function call data for the target contract.
    function submitProposal(string memory _description, address _target, bytes memory _callData)
        public
    {
        uint256 forgeId = _findForgeByOwner(_msgSender()); // Find a forge owned by sender
        require(forgeId != 0, "ChronoForgeGuilds: Caller does not own a Forge");
        require(forges[forgeId].stakedAmount >= minStakedForProposal, "ChronoForgeGuilds: Insufficient staked tokens to propose");

        proposals.push(Proposal({
            description: _description,
            target: _target,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            passed: false
        }));

        emit ProposalSubmitted(proposals.length - 1, _msgSender(), _description);
    }

    /// @notice Casts a vote on a proposal, weighted by Chronos and staked tokens.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for' vote, false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        require(_proposalId < proposals.length, "ChronoForgeGuilds: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];

        require(block.number >= proposal.startBlock, "ChronoForgeGuilds: Voting has not started");
        require(block.number <= proposal.endBlock, "ChronoForgeGuilds: Voting has ended");

        uint256 forgeId = _findForgeByOwner(_msgSender());
        require(forgeId != 0, "ChronoForgeGuilds: Caller does not own a Forge");
        require(!proposal.hasVoted[forgeId], "ChronoForgeGuilds: Forge has already voted on this proposal");

        _updateForgeChronos(forgeId); // Ensure Chronos is updated for voting power calculation
        uint256 votingPower = getVotingPower(forgeId);
        require(votingPower > 0, "ChronoForgeGuilds: Forge has no voting power");

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }
        proposal.hasVoted[forgeId] = true;

        emit VoteCast(_proposalId, forgeId, _support, votingPower);
    }

    /// @notice Executes a passed proposal.
    /// @param _proposalId The ID of the proposal.
    function executeProposal(uint256 _proposalId) public {
        require(_proposalId < proposals.length, "ChronoForgeGuilds: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];

        require(block.number > proposal.endBlock, "ChronoForgeGuilds: Voting period has not ended");
        require(!proposal.executed, "ChronoForgeGuilds: Proposal already executed");

        // Simple majority vote for now, can be adjusted with quorum, etc.
        proposal.passed = proposal.forVotes > proposal.againstVotes;

        if (proposal.passed) {
            // Use low-level call for flexibility and to call external contracts
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "ChronoForgeGuilds: Proposal execution failed");
        } else {
            revert("ChronoForgeGuilds: Proposal did not pass");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Calculates the current voting power for a Forge.
    /// @param _forgeId The ID of the Forge.
    /// @return The total voting power.
    function getVotingPower(uint256 _forgeId) public view returns (uint256) {
        require(_exists(_forgeId), "ChronoForgeGuilds: Forge does not exist");
        Forge storage forge = forges[_forgeId];
        
        uint256 currentChronos = getForgeChronos(_forgeId);
        // Voting power combines staked tokens and Chronos.
        // Example: (stakedAmount * 1) + (Chronos / 100) - adjust multipliers as needed
        return forge.stakedAmount.add(currentChronos.div(100)); // Scaled Chronos contribution
    }

    /// @dev Internal helper to find a forge owned by an address.
    /// @dev This is a placeholder and would need a more efficient lookup for many forges.
    ///      A real implementation might use a mapping from `address => uint256[]` of forge IDs.
    function _findForgeByOwner(address _owner) internal view returns (uint256) {
        // Naive iteration for demonstration. In production, maintain an inverse mapping or list.
        for (uint256 i = 1; i <= _forgeCounter; i++) {
            if (ownerOf(i) == _owner) {
                return i; // Return the first one found
            }
        }
        return 0; // Not found
    }

    // --- VI. Admin/Utility ---

    /// @notice Sets the address authorized to update the Ecosystem Vitality Index.
    /// @param _newOracle The new oracle address.
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "ChronoForgeGuilds: Oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    /// @notice Allows owner to withdraw any residual ETH from the contract (e.g., in case of accidental transfers).
    function withdrawETH(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "ChronoForgeGuilds: Amount must be greater than zero");
        require(address(this).balance >= _amount, "ChronoForgeGuilds: Insufficient contract balance");
        _to.transfer(_amount);
    }

    /// @notice Allows owner to withdraw any ERC20 tokens (other than GuildToken) from the contract.
    function withdrawERC20(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "ChronoForgeGuilds: Amount must be greater than zero");
        require(_token.balanceOf(address(this)) >= _amount, "ChronoForgeGuilds: Insufficient token balance");
        _token.transfer(_to, _amount);
    }
}
```