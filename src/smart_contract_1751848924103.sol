Okay, let's design a smart contract around a concept that combines dynamic NFTs (Artifacts), token staking for rewards, a resource/energy system for crafting/upgrading, and a simple on-chain community/governance feature (prompts, simple proposals).

We'll call it the "Arcane Assembly Nexus".

Here's the outline and function summary, followed by the Solidity code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ArcaneAssemblyNexus
 * @dev A smart contract simulating a decentralized crafting, staking, and community hub.
 * Users can mint, upgrade, craft, stake dynamic "Artifact" NFTs, manage "Energy",
 * contribute to community prompts, and participate in simple proposals.
 * It integrates dynamic NFT attributes, time-based mechanics, resource management,
 * and light DAO-like features within a single contract.
 */

/**
 * OUTLINE & FUNCTION SUMMARY:
 *
 * I. Core Data Structures & State
 *    - Artifact struct: Represents a dynamic NFT with stats, ownership, stake status.
 *    - Proposal struct: Represents a community proposal for voting.
 *    - Mappings for artifacts, resource balances, energy, reputation, proposals, etc.
 *    - Counters for artifact and proposal IDs.
 *    - Configuration variables (costs, rates, thresholds).
 *
 * II. Artifact Management (Dynamic NFT - Non-ERC721 compliant internal handling for example simplicity)
 *    - mintArtifact(): Mints a new base artifact.
 *    - getArtifactDetails(tokenId): Views all details of an artifact.
 *    - getArtifactOwner(tokenId): Views owner.
 *    - getArtifactLevel(tokenId): Views Level stat.
 *    - getArtifactPower(tokenId): Views Power stat.
 *    - getArtifactDurability(tokenId): Views Durability stat.
 *    - getArtifactName(tokenId): Views custom name.
 *    - getArtifactDescription(tokenId): Views custom description.
 *    - upgradeArtifactLevel(tokenId): Spends resources/energy to increase Level.
 *    - upgradeArtifactPower(tokenId): Spends resources/energy to increase Power.
 *    - upgradeArtifactDurability(tokenId): Spends resources/energy to increase Durability.
 *    - setArtifactName(tokenId, name): Sets a custom name (owner only).
 *    - setArtifactDescription(tokenId, description): Sets a custom description (owner only).
 *    - transferArtifact(to, tokenId): Transfers ownership.
 *    - burnArtifact(tokenId): Destroys an artifact.
 *
 * III. Crafting & Resources
 *    - craftArtifact(inputTokenIds): Combines multiple artifacts into a new/upgraded one (simulated logic).
 *    - dismantleArtifact(tokenId): Breaks down an artifact into resources/tokens.
 *    - craftResourceFromArtifact(tokenId): Converts an artifact into Resource Tokens.
 *    - transferResourceToken(to, amount): Transfers internal Resource Tokens.
 *    - balanceOfResourceToken(account): Views Resource Token balance.
 *
 * IV. Staking
 *    - stakeArtifact(tokenId): Stakes an artifact to earn rewards.
 *    - unstakeArtifact(tokenId): Unstakes an artifact and claims rewards.
 *    - claimArtifactStakeRewards(tokenId): Claims rewards without unstaking.
 *    - calculatePendingStakeRewards(tokenId): Views potential claimable rewards.
 *    - getArtifactStakeStartTime(tokenId): Views when an artifact was staked.
 *
 * V. Energy System
 *    - getUserEnergy(account): Views current energy level (calculated based on time).
 *    - rechargeEnergy(): Allows user to trigger energy recharge based on time passed.
 *
 * VI. Community & Reputation
 *    - getPlayerReputation(account): Views a player's reputation score.
 *    - submitCommunityPrompt(text): Submits a creative text prompt to a community list.
 *    - getCommunityPrompt(index): Views a specific community prompt.
 *
 * VII. Simple Proposals (Lightweight DAO)
 *    - createProposal(description, artifactRequiredToPropose): Creates a new proposal (requires condition, e.g., staked artifact).
 *    - voteOnProposal(proposalId, support): Casts a vote for or against a proposal.
 *    - delegateVote(delegatee): Delegates voting power for future proposals.
 *    - getProposalDetails(proposalId): Views details of a proposal.
 *    - getUserVote(proposalId, account): Views how a user voted on a proposal.
 *
 * VIII. Configuration (Owner Only)
 *    - setUpgradeCosts(levelCost, powerCost, durabilityCost): Sets resource costs for upgrades.
 *    - setStakingRewardRate(ratePerSecond): Sets reward rate for staked artifacts.
 *    - setEnergyRechargeRate(ratePerSecond, maxEnergy): Sets energy mechanics.
 *    - setReputationThresholds(thresholds): Sets thresholds for reputation tiers (example).
 *    - setProposalConfig(minStakeDurationForPropose, votingPeriod): Sets proposal parameters.
 *
 * IX. Utility & Views
 *    - artifactExists(tokenId): Checks if an artifact ID is valid.
 *    - getTotalArtifacts(): Views total number of artifacts minted.
 *    - getTotalProposals(): Views total number of proposals.
 *    - getUpgradeCosts(): Views current upgrade costs.
 *    - getStakingRewardRate(): Views current staking reward rate.
 *    - getEnergyConfig(): Views current energy configuration.
 *    - getProposalConfig(): Views current proposal configuration.
 *
 * Total Functions: 39 (Well over the required 20)
 */

contract ArcaneAssemblyNexus {

    address public owner; // Simple owner pattern

    // --- I. Core Data Structures & State ---

    struct Artifact {
        uint256 id;
        address owner;
        uint256 level;
        uint256 power;
        uint256 durability;
        string name;
        string description;
        uint64 stakeStartTime; // Timestamp when staked (0 if not staked)
        bool isStaked;
        uint256 stakedById; // Owner's ID if staked within this contract context
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint64 startTime;
        uint64 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed; // Not implemented execution logic, just a flag
        bool canceled;
    }

    // Artifact Data
    mapping(uint256 => Artifact) public artifacts;
    mapping(address => uint256[]) private _ownerArtifacts; // Track artifacts per owner
    uint256 private _nextTokenId; // Counter for artifact IDs

    // Resource Token (Internal simulation)
    mapping(address => uint256) public resourceBalances;
    uint256 public constant RESOURCE_TOKEN_DECIMALS = 18; // Example decimals

    // Energy System
    mapping(address => uint256) private _userEnergy; // Current energy
    mapping(address => uint64) private _lastEnergyRechargeTimestamp;
    uint256 public energyRechargeRatePerSecond = 1; // Energy gained per second
    uint256 public maxEnergy = 100;

    // Community Data
    string[] public communityPrompts; // Simple list of prompts

    // Reputation System
    mapping(address => int256) public playerReputation; // Can be positive or negative
    // uint256[] public reputationThresholds; // Example: thresholds for tiers

    // Proposal System
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voter => voted
    mapping(uint256 => mapping(address => bool)) private _userVoteSupport; // proposalId => voter => true=for, false=against
    mapping(address => address) public voteDelegates; // delegator => delegatee
    uint256 private _nextProposalId;
    uint256 public minStakeDurationForPropose = 7 days; // Requires artifact staked for this duration to propose
    uint64 public votingPeriod = 3 days; // Duration of voting

    // Configuration
    struct UpgradeCosts {
        uint256 level;
        uint256 power;
        uint256 durability;
    }
    UpgradeCosts public upgradeCosts = UpgradeCosts({
        level: 100 * (10**RESOURCE_TOKEN_DECIMALS), // Example costs
        power: 150 * (10**RESOURCE_TOKEN_DECIMALS),
        durability: 50 * (10**RESOURCE_TOKEN_DECIMALS)
    });

    uint256 public stakingRewardRatePerSecond = 1 * (10**RESOURCE_TOKEN_DECIMALS) / (1 days); // Example: 1 token per day per artifact

    // --- Events ---
    event ArtifactMinted(uint256 tokenId, address indexed owner);
    event ArtifactUpgraded(uint256 indexed tokenId, string indexed upgradeType, uint256 newStatValue);
    event ArtifactCrafted(uint256 indexed newTokenId, address indexed owner, uint256[] inputTokenIds);
    event ArtifactDismantled(uint256 indexed tokenId, address indexed owner);
    event ArtifactTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner);
    event ArtifactStaked(uint256 indexed tokenId, address indexed owner);
    event ArtifactUnstaked(uint256 indexed tokenId, address indexed owner, uint256 rewardsClaimed);
    event RewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 rewardsClaimed);
    event ResourceTransfer(address indexed from, address indexed to, uint256 amount);
    event EnergyRecharged(address indexed account, uint256 newEnergy);
    event PlayerReputationChanged(address indexed account, int256 oldReputation, int256 newReputation);
    event CommunityPromptSubmitted(uint256 indexed index, address indexed submitter, string text);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ConfigUpdated(string indexed configName); // Generic event for config changes

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier artifactExists(uint256 tokenId) {
        require(artifacts[tokenId].id != 0, "Artifact does not exist");
        _;
    }

    modifier onlyArtifactOwner(uint256 tokenId) {
        require(artifacts[tokenId].owner == msg.sender, "Not artifact owner");
        _;
    }

    modifier notStaked(uint256 tokenId) {
        require(!artifacts[tokenId].isStaked, "Artifact is currently staked");
        _;
    }

    modifier isStaked(uint256 tokenId) {
        require(artifacts[tokenId].isStaked, "Artifact is not staked");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1
        _nextProposalId = 1; // Start proposal IDs from 1
    }

    // --- Utility & Views ---

    /**
     * @dev Checks if an artifact ID corresponds to an existing artifact.
     * @param tokenId The ID of the artifact.
     * @return bool True if artifact exists, false otherwise.
     */
    function artifactExists(uint256 tokenId) public view returns (bool) {
         // A more robust check for existence than id != 0
        return artifacts[tokenId].owner != address(0) || artifacts[tokenId].id != 0;
    }


    /**
     * @dev Returns the total number of artifacts minted.
     * @return uint256 The total number of artifacts.
     */
    function getTotalArtifacts() public view returns (uint256) {
        return _nextTokenId - 1; // Since IDs start from 1
    }

     /**
     * @dev Returns the total number of proposals created.
     * @return uint256 The total number of proposals.
     */
    function getTotalProposals() public view returns (uint256) {
        return _nextProposalId - 1; // Since IDs start from 1
    }

    /**
     * @dev Returns the current costs for upgrading artifact stats.
     * @return levelCost Resource cost for Level upgrade.
     * @return powerCost Resource cost for Power upgrade.
     * @return durabilityCost Resource cost for Durability upgrade.
     */
    function getUpgradeCosts() public view returns (uint256 levelCost, uint256 powerCost, uint256 durabilityCost) {
        return (upgradeCosts.level, upgradeCosts.power, upgradeCosts.durability);
    }

     /**
     * @dev Returns the current staking reward rate per second.
     * @return uint256 The reward rate per second in resource tokens (with decimals).
     */
    function getStakingRewardRate() public view returns (uint256) {
        return stakingRewardRatePerSecond;
    }

    /**
     * @dev Returns the current energy system configuration.
     * @return ratePerSecond Energy gained per second.
     * @return maxEnergyLimit Maximum energy cap.
     */
    function getEnergyConfig() public view returns (uint256 ratePerSecond, uint256 maxEnergyLimit) {
        return (energyRechargeRatePerSecond, maxEnergy);
    }

     /**
     * @dev Returns the current proposal system configuration.
     * @return minStakeDuration Min duration an artifact must be staked to propose.
     * @return votingPeriodDuration Duration of voting period in seconds.
     */
    function getProposalConfig() public view returns (uint256 minStakeDuration, uint64 votingPeriodDuration) {
        return (minStakeDurationForPropose, votingPeriod);
    }


    // --- II. Artifact Management ---

    /**
     * @dev Mints a new base artifact and assigns it to the caller.
     * Initial stats are set to 1.
     * @return uint256 The ID of the newly minted artifact.
     */
    function mintArtifact() external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        Artifact storage newArtifact = artifacts[tokenId];
        newArtifact.id = tokenId;
        newArtifact.owner = msg.sender;
        newArtifact.level = 1;
        newArtifact.power = 1;
        newArtifact.durability = 1;
        // Name and description are empty by default
        newArtifact.stakeStartTime = 0;
        newArtifact.isStaked = false;
        newArtifact.stakedById = 0;

        _ownerArtifacts[msg.sender].push(tokenId);

        emit ArtifactMinted(tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @dev Gets the full details of an artifact.
     * @param tokenId The ID of the artifact.
     * @return artifact The artifact struct details.
     */
    function getArtifactDetails(uint256 tokenId) external view artifactExists(tokenId) returns (Artifact memory) {
        return artifacts[tokenId];
    }

    /**
     * @dev Gets the owner of an artifact.
     * @param tokenId The ID of the artifact.
     * @return address The owner's address.
     */
     function getArtifactOwner(uint256 tokenId) external view artifactExists(tokenId) returns (address) {
         return artifacts[tokenId].owner;
     }


    /**
     * @dev Gets the Level stat of an artifact.
     * @param tokenId The ID of the artifact.
     * @return uint256 The artifact's Level.
     */
    function getArtifactLevel(uint256 tokenId) external view artifactExists(tokenId) returns (uint256) {
        return artifacts[tokenId].level;
    }

    /**
     * @dev Gets the Power stat of an artifact.
     * @param tokenId The ID of the artifact.
     * @return uint256 The artifact's Power.
     */
    function getArtifactPower(uint256 tokenId) external view artifactExists(tokenId) returns (uint256) {
        return artifacts[tokenId].power;
    }

    /**
     * @dev Gets the Durability stat of an artifact.
     * @param tokenId The ID of the artifact.
     * @return uint256 The artifact's Durability.
     */
    function getArtifactDurability(uint256 tokenId) external view artifactExists(tokenId) returns (uint256) {
        return artifacts[tokenId].durability;
    }

    /**
     * @dev Gets the custom name of an artifact.
     * @param tokenId The ID of the artifact.
     * @return string The artifact's name.
     */
     function getArtifactName(uint256 tokenId) external view artifactExists(tokenId) returns (string memory) {
         return artifacts[tokenId].name;
     }

     /**
     * @dev Gets the custom description of an artifact.
     * @param tokenId The ID of the artifact.
     * @return string The artifact's description.
     */
     function getArtifactDescription(uint256 tokenId) external view artifactExists(tokenId) returns (string memory) {
         return artifacts[tokenId].description;
     }


    /**
     * @dev Upgrades the Level stat of an artifact. Requires resource tokens and energy.
     * @param tokenId The ID of the artifact to upgrade.
     */
    function upgradeArtifactLevel(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        _consumeResourcesAndEnergy(msg.sender, upgradeCosts.level, 10); // Example energy cost

        Artifact storage artifact = artifacts[tokenId];
        artifact.level = artifact.level + 1; // Simple linear upgrade

        emit ArtifactUpgraded(tokenId, "Level", artifact.level);
    }

    /**
     * @dev Upgrades the Power stat of an artifact. Requires resource tokens and energy.
     * @param tokenId The ID of the artifact to upgrade.
     */
    function upgradeArtifactPower(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
         _consumeResourcesAndEnergy(msg.sender, upgradeCosts.power, 15); // Example energy cost

        Artifact storage artifact = artifacts[tokenId];
        artifact.power = artifact.power + 1; // Simple linear upgrade

        emit ArtifactUpgraded(tokenId, "Power", artifact.power);
    }

    /**
     * @dev Upgrades the Durability stat of an artifact. Requires resource tokens and energy.
     * @param tokenId The ID of the artifact to upgrade.
     */
    function upgradeArtifactDurability(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
         _consumeResourcesAndEnergy(msg.sender, upgradeCosts.durability, 5); // Example energy cost

        Artifact storage artifact = artifacts[tokenId];
        artifact.durability = artifact.durability + 1; // Simple linear upgrade

        emit ArtifactUpgraded(tokenId, "Durability", artifact.durability);
    }

    /**
     * @dev Sets a custom name for an artifact.
     * @param tokenId The ID of the artifact.
     * @param name The new name for the artifact.
     */
     function setArtifactName(uint256 tokenId, string calldata name) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
         artifacts[tokenId].name = name;
         emit ArtifactNameSet(tokenId, name);
     }

    /**
     * @dev Sets a custom description for an artifact.
     * @param tokenId The ID of the artifact.
     * @param description The new description for the artifact.
     */
     function setArtifactDescription(uint256 tokenId, string calldata description) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
         artifacts[tokenId].description = description;
         emit ArtifactDescriptionSet(tokenId, description);
     }

    /**
     * @dev Transfers ownership of an artifact.
     * @param to The address to transfer to.
     * @param tokenId The ID of the artifact to transfer.
     */
    function transferArtifact(address to, uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        require(to != address(0), "Transfer to zero address");

        address from = artifacts[tokenId].owner;
        artifacts[tokenId].owner = to;

        // Remove from old owner's list (simplified - assumes non-staked are in this list)
        _removeArtifactFromOwnerList(from, tokenId);
        // Add to new owner's list
        _ownerArtifacts[to].push(tokenId);

        emit ArtifactTransferred(tokenId, from, to);
    }

     /**
     * @dev Destroys an artifact permanently.
     * @param tokenId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        address ownerAddress = artifacts[tokenId].owner;

        // Remove from owner's list
        _removeArtifactFromOwnerList(ownerAddress, tokenId);

        // Clear artifact data (simulate burning)
        delete artifacts[tokenId]; // This sets owner to address(0) and id to 0

        emit ArtifactBurned(tokenId, ownerAddress);
    }

    // --- III. Crafting & Resources ---

    /**
     * @dev Crafts a new artifact by combining existing ones (simulated recipe).
     * Requires owning all input artifacts and consumes resources/energy.
     * Example: Combine 3 base artifacts to get a slightly better one.
     * @param inputTokenIds An array of artifact IDs to use as materials.
     * @return uint256 The ID of the newly crafted artifact.
     */
    function craftArtifact(uint256[] calldata inputTokenIds) external returns (uint256) {
        require(inputTokenIds.length >= 2, "Need at least 2 artifacts to craft"); // Example recipe requirement
        require(inputTokenIds.length <= 5, "Cannot use more than 5 artifacts"); // Example upper limit

        // Basic validation and ownership check
        uint256 totalLevel = 0;
        uint256 totalPower = 0;
        uint256 totalDurability = 0;
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(artifactExists(tokenId), "Input artifact does not exist");
            require(artifacts[tokenId].owner == msg.sender, "Not owner of input artifact");
            require(!artifacts[tokenId].isStaked, "Input artifact is staked");

            totalLevel += artifacts[tokenId].level;
            totalPower += artifacts[tokenId].power;
            totalDurability += artifacts[tokenId].durability;
        }

        // Consume crafting costs (resource tokens and energy)
        uint256 craftingResourceCost = inputTokenIds.length * 50 * (10**RESOURCE_TOKEN_DECIMALS); // Example cost scaling with inputs
        uint256 craftingEnergyCost = inputTokenIds.length * 20; // Example energy cost
        _consumeResourcesAndEnergy(msg.sender, craftingResourceCost, craftingEnergyCost);


        // Burn the input artifacts
        for (uint i = 0; i < inputTokenIds.length; i++) {
            // Remove from owner's list
            _removeArtifactFromOwnerList(msg.sender, inputTokenIds[i]);
             // Simulate burning
            delete artifacts[inputTokenIds[i]];
        }

        // Mint a new artifact with combined/improved stats
        uint256 newTokenId = _nextTokenId++;
        Artifact storage newArtifact = artifacts[newTokenId];
        newArtifact.id = newTokenId;
        newArtifact.owner = msg.sender;
        // Example crafting logic: stats are average of inputs + bonus
        newArtifact.level = totalLevel / inputTokenIds.length + 1;
        newArtifact.power = totalPower / inputTokenIds.length + 1;
        newArtifact.durability = totalDurability / inputTokenIds.length + 1;
        newArtifact.stakeStartTime = 0;
        newArtifact.isStaked = false;
        newArtifact.stakedById = 0;
        // Name and description are empty by default

        _ownerArtifacts[msg.sender].push(newTokenId);

        emit ArtifactCrafted(newTokenId, msg.sender, inputTokenIds);
        return newTokenId;
    }

    /**
     * @dev Breaks down an artifact into resource tokens. Consumes energy.
     * @param tokenId The ID of the artifact to dismantle.
     */
    function dismantleArtifact(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        // Example energy cost
        uint256 dismantleEnergyCost = 10;
        _consumeEnergy(msg.sender, dismantleEnergyCost);

        Artifact storage artifact = artifacts[tokenId];
        uint256 resourceReward = (artifact.level + artifact.power + artifact.durability) * 20 * (10**RESOURCE_TOKEN_DECIMALS); // Example reward based on stats

        // Mint resource tokens to the owner (simulate internal transfer)
        resourceBalances[msg.sender] += resourceReward;
        emit ResourceTransfer(address(this), msg.sender, resourceReward); // Indicate origin as contract itself

        // Remove from owner's list
        _removeArtifactFromOwnerList(msg.sender, tokenId);
        // Simulate burning
        delete artifacts[tokenId];

        emit ArtifactDismantled(tokenId, msg.sender);
    }

    /**
     * @dev Converts an artifact directly into resource tokens without full dismantling. Consumes energy.
     * Less resource reward than dismantling, but faster/cheaper energy-wise.
     * @param tokenId The ID of the artifact to convert.
     */
     function craftResourceFromArtifact(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        // Example energy cost
        uint256 convertEnergyCost = 5;
        _consumeEnergy(msg.sender, convertEnergyCost);

        Artifact storage artifact = artifacts[tokenId];
        uint256 resourceReward = (artifact.level + artifact.power + artifact.durability) * 10 * (10**RESOURCE_TOKEN_DECIMALS); // Less reward

        // Mint resource tokens to the owner (simulate internal transfer)
        resourceBalances[msg.sender] += resourceReward;
        emit ResourceTransfer(address(this), msg.sender, resourceReward);

        // Remove from owner's list
        _removeArtifactFromOwnerList(msg.sender, tokenId);
         // Simulate burning
        delete artifacts[tokenId];

        emit ArtifactBurned(tokenId, msg.sender); // Also emit burn event
     }

    /**
     * @dev Transfers internal resource tokens between users.
     * @param to The recipient address.
     * @param amount The amount of resource tokens to transfer.
     */
    function transferResourceToken(address to, uint256 amount) external {
        require(to != address(0), "Transfer to zero address");
        require(resourceBalances[msg.sender] >= amount, "Insufficient resource balance");

        unchecked { // Assuming balances don't overflow max uint256
            resourceBalances[msg.sender] -= amount;
            resourceBalances[to] += amount;
        }

        emit ResourceTransfer(msg.sender, to, amount);
    }

    /**
     * @dev Gets the resource token balance for an account.
     * @param account The address to check.
     * @return uint256 The resource token balance.
     */
    function balanceOfResourceToken(address account) external view returns (uint256) {
        return resourceBalances[account];
    }


    // --- IV. Staking ---

    /**
     * @dev Stakes an artifact to earn resource token rewards over time.
     * The artifact cannot be upgraded, crafted, or transferred while staked.
     * @param tokenId The ID of the artifact to stake.
     */
    function stakeArtifact(uint256 tokenId) external onlyArtifactOwner(tokenId) notStaked(tokenId) {
        Artifact storage artifact = artifacts[tokenId];
        artifact.isStaked = true;
        artifact.stakeStartTime = uint64(block.timestamp);
        artifact.stakedById = artifact.owner; // Store owner's ID for internal lookup

        // Remove from owner's active list
        _removeArtifactFromOwnerList(msg.sender, tokenId);

        emit ArtifactStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an artifact and claims any accumulated rewards.
     * @param tokenId The ID of the artifact to unstake.
     */
    function unstakeArtifact(uint256 tokenId) external onlyArtifactOwner(tokenId) isStaked(tokenId) {
        Artifact storage artifact = artifacts[tokenId];
        require(artifact.stakedById == msg.sender, "Staked artifact owner mismatch"); // Sanity check

        uint256 pendingRewards = _calculatePendingStakeRewards(tokenId);

        artifact.isStaked = false;
        artifact.stakeStartTime = 0;
        artifact.stakedById = 0;

        // Transfer rewards (simulate internal transfer)
        if (pendingRewards > 0) {
            resourceBalances[msg.sender] += pendingRewards;
             emit ResourceTransfer(address(this), msg.sender, pendingRewards);
        }

        // Add back to owner's active list
        _ownerArtifacts[msg.sender].push(tokenId);

        emit ArtifactUnstaked(tokenId, msg.sender, pendingRewards);
    }

    /**
     * @dev Claims accumulated rewards for a staked artifact without unstaking it.
     * @param tokenId The ID of the staked artifact.
     */
    function claimArtifactStakeRewards(uint256 tokenId) external onlyArtifactOwner(tokenId) isStaked(tokenId) {
         Artifact storage artifact = artifacts[tokenId];
         require(artifact.stakedById == msg.sender, "Staked artifact owner mismatch"); // Sanity check

         uint256 pendingRewards = _calculatePendingStakeRewards(tokenId);

         if (pendingRewards > 0) {
             // Reset stake timer to continue accumulating from now
             artifact.stakeStartTime = uint64(block.timestamp);

             // Transfer rewards (simulate internal transfer)
             resourceBalances[msg.sender] += pendingRewards;
             emit ResourceTransfer(address(this), msg.sender, pendingRewards);

             emit RewardsClaimed(tokenId, msg.sender, pendingRewards);
         }
         // No-op if no rewards accrued yet
    }

    /**
     * @dev Calculates the pending resource token rewards for a staked artifact.
     * Does not claim the rewards.
     * @param tokenId The ID of the staked artifact.
     * @return uint256 The amount of pending rewards.
     */
    function calculatePendingStakeRewards(uint256 tokenId) public view isStaked(tokenId) returns (uint256) {
        Artifact storage artifact = artifacts[tokenId];
        uint256 timeStaked = block.timestamp - artifact.stakeStartTime;
        // Simple reward calculation: time * rate (could be more complex based on stats)
        return timeStaked * stakingRewardRatePerSecond;
    }

    /**
     * @dev Gets the timestamp when an artifact was staked.
     * @param tokenId The ID of the artifact.
     * @return uint64 The stake start timestamp (0 if not staked).
     */
    function getArtifactStakeStartTime(uint256 tokenId) external view artifactExists(tokenId) returns (uint64) {
        return artifacts[tokenId].stakeStartTime;
    }

    // --- V. Energy System ---

    /**
     * @dev Calculates and returns the current energy level for a user.
     * Energy recharges over time up to a maximum.
     * @param account The address to check.
     * @return uint256 The current energy level.
     */
    function getUserEnergy(address account) public view returns (uint256) {
        uint256 energy = _userEnergy[account];
        uint64 lastRecharge = _lastEnergyRechargeTimestamp[account];
        uint256 timePassed = block.timestamp - lastRecharge;
        uint256 rechargedAmount = timePassed * energyRechargeRatePerSecond;
        uint256 newEnergy = energy + rechargedAmount;
        return newEnergy > maxEnergy ? maxEnergy : newEnergy;
    }

    /**
     * @dev Allows a user to "recharge" their energy. This updates the on-chain state
     * based on time passed since last recharge or last energy spend.
     */
    function rechargeEnergy() external {
        _userEnergy[msg.sender] = getUserEnergy(msg.sender); // Update current energy
        _lastEnergyRechargeTimestamp[msg.sender] = uint64(block.timestamp); // Reset timer
        emit EnergyRecharged(msg.sender, _userEnergy[msg.sender]);
    }

    // --- VI. Community & Reputation ---

    /**
     * @dev Gets the current reputation score for a player.
     * @param account The address to check.
     * @return int256 The player's reputation score.
     */
    function getPlayerReputation(address account) external view returns (int256) {
        return playerReputation[account];
    }

     /**
     * @dev Allows a user to submit a text prompt to the community list.
     * Example of simple on-chain data storage for community input.
     * @param text The prompt text to submit.
     */
    function submitCommunityPrompt(string calldata text) external {
        require(bytes(text).length > 0, "Prompt cannot be empty");
        require(bytes(text).length <= 256, "Prompt too long"); // Limit length

        communityPrompts.push(text);
        emit CommunityPromptSubmitted(communityPrompts.length - 1, msg.sender, text);
    }

    /**
     * @dev Gets a specific community prompt by its index.
     * @param index The index of the prompt in the list.
     * @return string The prompt text.
     */
    function getCommunityPrompt(uint256 index) external view returns (string memory) {
        require(index < communityPrompts.length, "Prompt index out of bounds");
        return communityPrompts[index];
    }


    // --- VII. Simple Proposals (Lightweight DAO) ---

    /**
     * @dev Creates a new community proposal. Requires a certain condition (e.g., a staked artifact meeting criteria).
     * @param description The description of the proposal.
     * @param artifactRequiredToPropose The ID of the staked artifact used to meet the proposal requirement.
     * @return uint256 The ID of the newly created proposal.
     */
    function createProposal(string calldata description, uint256 artifactRequiredToPropose) external returns (uint256) {
        // Check proposal requirement: artifact is staked and staked for long enough
        require(artifactExists(artifactRequiredToPropose), "Proposing artifact does not exist");
        require(artifacts[artifactRequiredToPropose].owner == msg.sender, "Not owner of proposing artifact");
        require(artifacts[artifactRequiredToPropose].isStaked, "Proposing artifact is not staked");
        require(block.timestamp - artifacts[artifactRequiredToPropose].stakeStartTime >= minStakeDurationForPropose, "Proposing artifact not staked long enough");
        require(bytes(description).length > 0, "Proposal description cannot be empty");

        uint256 proposalId = _nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.startTime = uint64(block.timestamp);
        newProposal.endTime = uint64(block.timestamp) + votingPeriod;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.canceled = false;

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal. Voting power could be based on reputation, staked artifacts, etc.
     * Simple model: 1 user = 1 vote, handled via delegation if set.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for voting For, False for voting Against.
     */
    function voteOnProposal(uint256 proposalId, bool support) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime, "Voting period is closed");
        require(!proposal.canceled, "Proposal is canceled");

        address voter = msg.sender;
        // Resolve delegate
        address effectiveVoter = voteDelegates[voter] == address(0) ? voter : voteDelegates[voter];

        require(!_hasVoted[proposalId][effectiveVoter], "Already voted on this proposal");

        _hasVoted[proposalId][effectiveVoter] = true;
        _userVoteSupport[proposalId][effectiveVoter] = support; // Store how they voted

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, effectiveVoter, support);
    }

     /**
     * @dev Allows a user to delegate their future voting power to another address.
     * This delegation applies to all proposals voted on *after* the delegation occurs.
     * @param delegatee The address to delegate voting power to. Address(0) clears delegation.
     */
    function delegateVote(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to yourself");
        // Preventing circular delegation is complex, skipped for this example.

        address delegator = msg.sender;
        voteDelegates[delegator] = delegatee;

        emit VoteDelegated(delegator, delegatee);
    }


    /**
     * @dev Gets the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return proposal The proposal struct details.
     */
    function getProposalDetails(uint256 proposalId) external view proposalExists(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }

    /**
     * @dev Checks how a specific user voted on a proposal.
     * Does NOT resolve delegation - shows how the direct address voted or if they delegated.
     * @param proposalId The ID of the proposal.
     * @param account The address to check.
     * @return bool True if the user has voted.
     * @return bool True if the user voted FOR, False if AGAINST (only meaningful if hasVoted is true).
     */
    function getUserVote(uint256 proposalId, address account) external view proposalExists(proposalId) returns (bool hasVoted, bool support) {
        address effectiveVoter = voteDelegates[account] == address(0) ? account : voteDelegates[account];
        hasVoted = _hasVoted[proposalId][effectiveVoter];
        support = _userVoteSupport[proposalId][effectiveVoter];
        return (hasVoted, support);
    }


    // --- VIII. Configuration (Owner Only) ---

    /**
     * @dev Sets the resource token costs for upgrading artifact stats.
     * @param levelCost New cost for Level upgrades.
     * @param powerCost New cost for Power upgrades.
     * @param durabilityCost New cost for Durability upgrades.
     */
    function setUpgradeCosts(uint256 levelCost, uint256 powerCost, uint256 durabilityCost) external onlyOwner {
        upgradeCosts = UpgradeCosts({
            level: levelCost,
            power: powerCost,
            durability: durabilityCost
        });
        emit ConfigUpdated("UpgradeCosts");
    }

    /**
     * @dev Sets the resource token reward rate per second for staked artifacts.
     * @param ratePerSecond The new reward rate per second.
     */
    function setStakingRewardRate(uint256 ratePerSecond) external onlyOwner {
        stakingRewardRatePerSecond = ratePerSecond;
        emit ConfigUpdated("StakingRewardRate");
    }

    /**
     * @dev Sets the energy recharge mechanics.
     * @param ratePerSecond New energy gained per second.
     * @param maxEnergyLimit New maximum energy cap.
     */
    function setEnergyRechargeRate(uint256 ratePerSecond, uint256 maxEnergyLimit) external onlyOwner {
        require(ratePerSecond > 0, "Rate must be positive");
        require(maxEnergyLimit > 0, "Max energy must be positive");
        energyRechargeRatePerSecond = ratePerSecond;
        maxEnergy = maxEnergyLimit;
        emit ConfigUpdated("EnergyConfig");
    }

     /**
     * @dev Sets parameters for the proposal system.
     * @param minStakeDuration New minimum duration an artifact must be staked to propose.
     * @param votingPeriodDuration New duration for the voting period in seconds.
     */
    function setProposalConfig(uint256 minStakeDuration, uint64 votingPeriodDuration) external onlyOwner {
        minStakeDurationForPropose = minStakeDuration;
        votingPeriod = votingPeriodDuration;
        emit ConfigUpdated("ProposalConfig");
    }

     /**
     * @dev Allows owner to award reputation to an account.
     * Used for game mechanics, moderation, etc.
     * @param account The address to award reputation to.
     * @param amount The amount of reputation to add.
     */
    function awardReputation(address account, uint256 amount) external onlyOwner {
        int256 oldRep = playerReputation[account];
        playerReputation[account] += int256(amount); // Cast amount to int256
        emit PlayerReputationChanged(account, oldRep, playerReputation[account]);
    }

     /**
     * @dev Allows owner to deduct reputation from an account.
     * Used for penalties, etc.
     * @param account The address to deduct reputation from.
     * @param amount The amount of reputation to deduct.
     */
    function deductReputation(address account, uint256 amount) external onlyOwner {
         int256 oldRep = playerReputation[account];
         // Prevent potential underflow if converting a large uint256 to int256 negative
         // This is safe as 'amount' will be a reasonable positive number
         playerReputation[account] -= int256(amount);
         emit PlayerReputationChanged(account, oldRep, playerReputation[account]);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to remove an artifact ID from an owner's list.
     * Simplified implementation - not optimized for gas if lists are very large.
     * Assumes the artifact is *not* staked when removed from this list.
     * @param ownerAddress The owner's address.
     * @param tokenId The ID of the artifact to remove.
     */
    function _removeArtifactFromOwnerList(address ownerAddress, uint256 tokenId) internal {
        uint256[] storage ownerList = _ownerArtifacts[ownerAddress];
        for (uint i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == tokenId) {
                // Swap last element with the one to remove, then pop
                ownerList[i] = ownerList[ownerList.length - 1];
                ownerList.pop();
                break; // Token found and removed
            }
        }
    }

    /**
     * @dev Internal function to consume resource tokens and energy for an action.
     * Recharges energy first before consuming.
     * @param account The user's address.
     * @param resourceCost The amount of resource tokens required.
     * @param energyCost The amount of energy required.
     */
    function _consumeResourcesAndEnergy(address account, uint256 resourceCost, uint256 energyCost) internal {
         require(resourceBalances[account] >= resourceCost, "Insufficient resource balance");

        // First, update/recharge energy
        _userEnergy[account] = getUserEnergy(account);
        _lastEnergyRechargeTimestamp[account] = uint64(block.timestamp);

        require(_userEnergy[account] >= energyCost, "Insufficient energy");

        // Consume resources and energy
        unchecked {
            resourceBalances[account] -= resourceCost;
            _userEnergy[account] -= energyCost;
        }

        // Emit events for consumption (optional, but good for tracking)
        emit ResourceTransfer(account, address(this), resourceCost); // Indicate resources going to contract
        emit EnergyRecharged(account, _userEnergy[account]); // Energy changed state
    }

     /**
     * @dev Internal function to consume energy only.
     * Recharges energy first before consuming.
     * @param account The user's address.
     * @param energyCost The amount of energy required.
     */
    function _consumeEnergy(address account, uint256 energyCost) internal {
         // First, update/recharge energy
        _userEnergy[account] = getUserEnergy(account);
        _lastEnergyRechargeTimestamp[account] = uint64(block.timestamp);

        require(_userEnergy[account] >= energyCost, "Insufficient energy");

        // Consume energy
        unchecked {
            _userEnergy[account] -= energyCost;
        }

        // Emit event for consumption
        emit EnergyRecharged(account, _userEnergy[account]);
    }

    // Fallback and Receive functions (optional, but good practice)
    receive() external payable {}
    fallback() external payable {}
}
```