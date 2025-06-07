Okay, let's create a smart contract for a dynamic digital art ecosystem where NFTs have mutable attributes that can be influenced by staking together in "Synergy Pools," sacrificing other NFTs, and participating in on-chain governance. This combines elements of NFTs, DeFi (staking mechanics), GameFi (attribute mechanics), and DAO (governance).

We'll call it `DigitalArtSynergy`.

**Outline & Function Summary**

**Contract Name:** DigitalArtSynergy

**Core Concept:**
An ERC721 contract where digital art NFTs possess dynamic attributes (Energy, Harmony, Rarity Score). These attributes change based on interactions within the ecosystem:
1.  **Synergy Pools:** Staking NFTs together in pools earns a utility token (Harmony Shards) based on their collective attributes and duration. Attributes also decay over time but can be boosted.
2.  **Sacrifice:** Burning an NFT permanently boosts the attributes of another target NFT.
3.  **Governance:** NFT owners can propose and vote on changes to NFT attributes, introducing a community-driven evolution mechanism.

**Key Features:**
*   ERC721 Standard Compliance
*   Dynamic NFT Attributes (Energy, Harmony, Rarity Score)
*   Synergy Staking Pools with ERC20 Rewards
*   NFT Sacrifice Mechanism for Attribute Boosting
*   On-chain Governance for Attribute Modification Proposals
*   Pausable Functionality
*   Owner-controlled parameters

**Main Data Structures:**
*   `NFTAttributes`: Stores dynamic attributes and last update time for each token.
*   `SynergyPool`: Stores information about a staking pool, including staked NFTs, total energy, reward accumulation, and creator.
*   `StakingInfo`: Stores staking details for an individual NFT.
*   `AttributeBoostProposal`: Stores details about a governance proposal to boost attributes.

**Function Categories:**

1.  **NFT Management & Information (ERC721 Standard + Custom):**
    *   `constructor`: Initializes contract, owner, Harmony Token address.
    *   `mintNFT`: Mints a new NFT with initial attributes.
    *   `getNFTAttributes`: Retrieves the current dynamic attributes of a token.
    *   `tokenURI`: Standard ERC721 metadata URI getter.
    *   `balanceOf`: Standard ERC721 count of owner tokens.
    *   `ownerOf`: Standard ERC721 owner of a token.
    *   `transferFrom`: Standard ERC721 transfer.
    *   `safeTransferFrom`: Standard ERC721 safe transfer.
    *   `approve`: Standard ERC721 approval.
    *   `setApprovalForAll`: Standard ERC721 operator approval.
    *   `getApproved`: Standard ERC721 single approval getter.
    *   `isApprovedForAll`: Standard ERC721 operator approval getter.
    *   `totalSupply`: Standard ERC721 total minted tokens.

2.  **Synergy Pools & Staking:**
    *   `createSynergyPool`: Creates a new staking pool (requires ETH fee).
    *   `joinSynergyPool`: Stakes an owned NFT into a pool.
    *   `leaveSynergyPool`: Unstakes an NFT from a pool and calculates/distributes pending rewards.
    *   `claimHarmonyShards`: Claims accumulated Harmony Shard rewards for staked NFTs.
    *   `calculatePendingRewards`: Calculates potential rewards for a specific staked NFT without claiming.
    *   `getPoolInfo`: Retrieves details about a specific pool.
    *   `getPoolNFTs`: Lists the NFTs currently staked in a specific pool (be mindful of gas limits for large pools).

3.  **Attribute Mechanics:**
    *   `sacrificeNFTForBoost`: Burns a source NFT to permanently boost attributes of a target NFT.
    *   `pulseAttributes`: Internal helper to update attributes based on decay and potentially pool effects (called by other interactions).

4.  **Governance (Attribute Boost Proposals):**
    *   `proposeAttributeBoost`: Creates a proposal to boost a specific NFT's attributes (requires owning an NFT or staking power).
    *   `voteOnProposal`: Casts a vote (Yes/No) on an open proposal (requires owning an NFT or staking power).
    *   `executeProposal`: Executes a proposal if the voting period is over and it passed.
    *   `getProposalInfo`: Retrieves details about a specific proposal.
    *   `getVoterStatus`: Checks if an address has voted on a specific proposal.

5.  **Tokenomics (Harmony Shards - Interaction with ERC20):**
    *   (Interacts with a separate IERC20 contract defined via `_harmonyToken` address)
    *   Functions like `claimHarmonyShards` and `calculatePendingRewards` are the primary interaction points.

6.  **Owner & Administrative:**
    *   `pause`: Pauses core contract interactions (minting, staking, voting, etc.).
    *   `unpause`: Unpauses the contract.
    *   `setHarmonyTokenAddress`: Sets the address of the Harmony Shard ERC20 contract.
    *   `setPoolCreationFee`: Sets the required ETH fee to create a pool.
    *   `withdrawFees`: Allows the owner to withdraw collected pool creation fees.
    *   `setBaseURI`: Sets the base URI for token metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary above the code

contract DigitalArtSynergy is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---

    struct NFTAttributes {
        uint256 energy; // Influences rewards in pools, sacrifice boost value
        uint256 harmony; // Influences rewards in pools, decay rate
        uint256 rarityScore; // Influences sacrifice boost value, eligibility?
        uint256 lastUpdated; // Timestamp of last attribute update/interaction
    }

    struct SynergyPool {
        address creator;
        string name;
        uint256 creationTime;
        uint256 feeBasisPoints; // Percentage cut of distributed rewards for creator/protocol
        uint256 totalEnergy;    // Sum of energy of all staked NFTs
        uint256 lastRewardDistribution; // Timestamp of last reward calculation/distribution
        // Staked NFTs are tracked via the `tokenIdToStakingInfo` mapping and the `poolToStakedNFTs` array
    }

    struct StakingInfo {
        uint256 poolId; // 0 if not staked
        uint256 stakedTime; // Timestamp when staked or last claimed rewards
        uint256 pendingRewards; // Accumulated Harmony Shard rewards
    }

    struct AttributeBoostProposal {
        uint256 proposalId;
        address proposer;
        uint256 targetTokenId;
        uint256 energyBoost;
        uint256 harmonyBoost;
        uint256 rarityBoost;
        uint256 votingDeadline;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool executed;
        bool passed; // Result after execution
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    // --- State Variables ---

    mapping(uint256 => NFTAttributes) public idToAttributes;
    mapping(uint256 => SynergyPool) public poolIdToPool;
    mapping(uint256 => StakingInfo) public tokenIdToStakingInfo; // TokenId -> StakingInfo

    // This array tracks which NFTs are in a pool. Removing is O(n) but acceptable for this example.
    mapping(uint256 => uint256[]) private poolToStakedNFTs; // poolId -> list of tokenIds

    mapping(uint256 => AttributeBoostProposal) public proposalIdToProposal;

    Counters.Counter private _tokenIds;
    Counters.Counter private _poolCounter;
    Counters.Counter private _proposalCounter;

    IERC20 public _harmonyToken; // Address of the utility token
    uint256 public _poolCreationFee = 0.01 ether; // Fee to create a pool
    uint256 private _totalFees; // Accumulated ETH fees

    string private _baseTokenURI;

    // --- Constants ---

    uint256 public constant ATTRIBUTE_DECAY_RATE_PER_DAY = 100; // Decay points per day
    uint256 public constant HARMONY_REWARD_RATE_PER_ENERGY_PER_SECOND = 1000; // Scaling factor for rewards
    uint256 public constant PROPOSAL_VOTING_PERIOD_DAYS = 3; // Voting period duration
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 5; // % of total staked energy required to vote for validity
    uint256 public constant PROPOSAL_PASS_PERCENTAGE = 60; // % of YES votes among total votes needed to pass

    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 initialHarmony, uint256 initialRarity);
    event AttributesUpdated(uint256 indexed tokenId, uint256 energy, uint256 harmony, uint256 rarityScore, uint256 timestamp);
    event SynergyPoolCreated(uint256 indexed poolId, address indexed creator, string name);
    event JoinedPool(uint256 indexed poolId, uint256 indexed tokenId, address indexed owner);
    event LeftPool(uint256 indexed poolId, uint256 indexed tokenId, address indexed owner, uint256 claimedRewards);
    event RewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 claimedRewards);
    event NFTSacrificed(uint256 indexed sacrificedTokenId, uint256 indexed targetTokenId, address indexed sacrificer);
    event AttributeBoostProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 indexed targetTokenId, uint256 votingDeadline);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool voteYes);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Constructor ---

    constructor(address initialOwner, address harmonyTokenAddress) ERC721("DigitalSynergyArt", "DSA") Ownable(initialOwner) {
        _harmonyToken = IERC20(harmonyTokenAddress);
    }

    // --- Pausable Modifier ---
    // Applies to functions that should not be executable when paused.

    // --- NFT Management & Information ---

    /**
     * @notice Mints a new Digital Art Synergy NFT.
     * @param to The address to mint the NFT to.
     * @param initialEnergy Initial Energy attribute.
     * @param initialHarmony Initial Harmony attribute.
     * @param initialRarity Initial Rarity Score attribute.
     */
    function mintNFT(address to, uint256 initialEnergy, uint256 initialHarmony, uint256 initialRarity) external onlyOwner whenNotPaused {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);

        idToAttributes[newItemId] = NFTAttributes({
            energy: initialEnergy,
            harmony: initialHarmony,
            rarityScore: initialRarity,
            lastUpdated: block.timestamp
        });

        emit NFTMinted(newItemId, to, initialEnergy, initialHarmony, initialRarity);
        emit AttributesUpdated(newItemId, initialEnergy, initialHarmony, initialRarity, block.timestamp);
    }

    /**
     * @notice Returns the dynamic attributes for a given token ID.
     * @param tokenId The ID of the token.
     * @return attributes The NFTAttributes struct.
     */
    function getNFTAttributes(uint256 tokenId) public view returns (NFTAttributes memory attributes) {
        require(_exists(tokenId), "Token does not exist");
        // Calculate decayed attributes without state change
        return _calculateDecayedAttributes(tokenId);
    }

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: token query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /**
     * @notice Internal function to calculate attributes after applying decay.
     * @param tokenId The ID of the token.
     * @return attributes The calculated NFTAttributes after decay.
     */
    function _calculateDecayedAttributes(uint256 tokenId) internal view returns (NFTAttributes memory) {
         NFTAttributes memory currentAttributes = idToAttributes[tokenId];
         uint256 timePassed = block.timestamp - currentAttributes.lastUpdated;
         // Decay is influenced by Harmony: higher Harmony means less decay
         // Decay amount formula: (timePassed_in_days * DecayRate) / (1 + Harmony/100)
         uint256 decayAmount = (timePassed / 1 days * ATTRIBUTE_DECAY_RATE_PER_DAY * 100) / (100 + currentAttributes.harmony); // *100 /100 to maintain precision before division

         currentAttributes.energy = currentAttributes.energy > decayAmount ? currentAttributes.energy - decayAmount : 0;
         currentAttributes.harmony = currentAttributes.harmony > decayAmount ? currentAttributes.harmony - decayAmount : 0;
         // RarityScore doesn't decay for now, but could add logic here

         return currentAttributes;
    }

     /**
     * @notice Internal function to apply and store attribute updates (including decay).
     * @param tokenId The ID of the token.
     * @param energyBoost Change in Energy (can be negative for decay).
     * @param harmonyBoost Change in Harmony.
     * @param rarityBoost Change in Rarity Score.
     */
    function _updateNFTAttributes(uint256 tokenId, int256 energyBoost, int256 harmonyBoost, int256 rarityBoost) internal {
        NFTAttributes storage attributes = idToAttributes[tokenId];
        NFTAttributes memory decayedAttributes = _calculateDecayedAttributes(tokenId); // Apply decay first

        attributes.energy = decayedAttributes.energy;
        attributes.harmony = decayedAttributes.harmony;
        attributes.rarityScore = decayedAttributes.rarityScore;

        // Apply boosts
        if (energyBoost > 0) attributes.energy += uint256(energyBoost); else if (attributes.energy >= uint256(-energyBoost)) attributes.energy -= uint256(-energyBoost); else attributes.energy = 0;
        if (harmonyBoost > 0) attributes.harmony += uint256(harmonyBoost); else if (attributes.harmony >= uint256(-harmonyBoost)) attributes.harmony -= uint256(-harmonyBoost); else attributes.harmony = 0;
        if (rarityBoost > 0) attributes.rarityScore += uint256(rarityBoost); else if (attributes.rarityScore >= uint256(-rarityBoost)) attributes.rarityScore -= uint256(-rarityBoost); else attributes.rarityScore = 0;


        attributes.lastUpdated = block.timestamp; // Reset decay timer

        emit AttributesUpdated(tokenId, attributes.energy, attributes.harmony, attributes.rarityScore, attributes.lastUpdated);
    }


    // --- Synergy Pools & Staking ---

    /**
     * @notice Creates a new Synergy Pool. Requires a fee.
     * @param name The name of the pool.
     * @param feeBasisPoints The fee percentage (in basis points, e.g., 100 for 1%) for the pool creator/protocol.
     */
    function createSynergyPool(string memory name, uint256 feeBasisPoints) external payable whenNotPaused {
        require(msg.value >= _poolCreationFee, "Insufficient fee");
        require(feeBasisPoints <= 10000, "Fee basis points cannot exceed 10000 (100%)");

        _totalFees += msg.value;

        _poolCounter.increment();
        uint256 newPoolId = _poolCounter.current();

        poolIdToPool[newPoolId] = SynergyPool({
            creator: msg.sender,
            name: name,
            creationTime: block.timestamp,
            feeBasisPoints: feeBasisPoints,
            totalEnergy: 0,
            lastRewardDistribution: block.timestamp,
            accumulatedRewards: 0 // Could accumulate rewards here before distributing
        });

        emit SynergyPoolCreated(newPoolId, msg.sender, name);
    }

    /**
     * @notice Stakes an owned NFT into a Synergy Pool.
     * @param poolId The ID of the pool to join.
     * @param tokenId The ID of the NFT to stake.
     */
    function joinSynergyPool(uint256 poolId, uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(poolIdToPool[poolId].creationTime != 0, "Pool does not exist"); // Check if poolId is valid
        require(tokenIdToStakingInfo[tokenId].poolId == 0, "Token is already staked");

        // Transfer NFT custody to the contract for staking
        _transfer(msg.sender, address(this), tokenId);

        // Claim any pending rewards before restaking/joining a new pool (should be 0 if not staked)
        _claimAndResetRewards(tokenId); // This also updates lastUpdated for decay

        // Add staking info
        tokenIdToStakingInfo[tokenId] = StakingInfo({
            poolId: poolId,
            stakedTime: block.timestamp,
            pendingRewards: 0
        });

        // Add token to pool's list of staked tokens (O(n) removal later, but simple addition)
        poolToStakedNFTs[poolId].push(tokenId);

        // Update pool total energy and last distribution time
        SynergyPool storage pool = poolIdToPool[poolId];
        NFTAttributes memory attributes = idToAttributes[tokenId]; // Use stored attributes *before* potential pulse/decay logic for initial join calculation
        pool.totalEnergy += attributes.energy;
        // No need to update lastRewardDistribution here, rewards are calculated per NFT based on its staking time.

        emit JoinedPool(poolId, tokenId, msg.sender);
    }

    /**
     * @notice Unstakes an NFT from a Synergy Pool and claims rewards.
     * @param poolId The ID of the pool the NFT is staked in.
     * @param tokenId The ID of the NFT to unstake.
     */
    function leaveSynergyPool(uint256 poolId, uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Token does not exist or is not owned by this contract");
        require(ownerOf(tokenId) == address(this), "Token is not held by contract (not staked)");
        require(tokenIdToStakingInfo[tokenId].poolId == poolId, "Token is not staked in this pool");

        // Calculate and claim pending rewards first
        uint256 claimed = _claimAndResetRewards(tokenId); // This also updates lastUpdated for decay

        // Remove staking info
        delete tokenIdToStakingInfo[tokenId];

        // Update pool total energy
        SynergyPool storage pool = poolIdToPool[poolId];
         // Use stored attributes for subtraction. Decay handled in _claimAndResetRewards.
        NFTAttributes memory currentAttributes = idToAttributes[tokenId];
        pool.totalEnergy = pool.totalEnergy >= currentAttributes.energy ? pool.totalEnergy - currentAttributes.energy : 0;

        // Remove token from pool's list (O(n) operation - could optimize with mapping for larger pools)
        uint256[] storage stakedTokens = poolToStakedNFTs[poolId];
        for (uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }

        // Transfer NFT back to the original owner (who called unstake)
        _safeTransfer(address(this), msg.sender, tokenId);

        emit LeftPool(poolId, tokenId, msg.sender, claimed);
    }

    /**
     * @notice Claims accumulated Harmony Shard rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     */
    function claimHarmonyShards(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(tokenIdToStakingInfo[tokenId].poolId != 0, "Token is not staked");
        require(ownerOf(tokenId) == address(this), "Token is not held by contract (should be staked)"); // Ensure custody

        uint256 claimed = _claimAndResetRewards(tokenId);

        require(claimed > 0, "No pending rewards");

        // Transfer tokens - assuming the Harmony token contract allows minting/transfer from this contract
        // Or, this contract holds a balance and transfers from it.
        // For this example, let's assume this contract *mints* or has permission to transfer *from its own balance*.
        // A common pattern is this contract having a minter role on the ERC20.
        // Or, the ERC20 is designed such that this contract can call a minting function.
        // Let's simulate by calling a transfer from this contract's potential balance.
        // In a real scenario, `_harmonyToken.mint(msg.sender, claimed)` or `_harmonyToken.transfer(msg.sender, claimed)` might be used.
        // Assuming `_harmonyToken` has a `transfer` function and this contract holds a balance or has approval/minting rights.
        bool success = _harmonyToken.transfer(msg.sender, claimed);
        require(success, "Harmony token transfer failed");

        emit RewardsClaimed(tokenId, msg.sender, claimed);
    }

    /**
     * @notice Internal helper to calculate, transfer, and reset pending rewards for a token.
     * Also applies decay/attribute pulse logic.
     * @param tokenId The ID of the token.
     * @return claimedAmount The amount of rewards claimed.
     */
    function _claimAndResetRewards(uint256 tokenId) internal returns (uint256 claimedAmount) {
        StakingInfo storage staking = tokenIdToStakingInfo[tokenId];
        uint256 poolId = staking.poolId;
        require(poolId != 0, "Token not staked"); // Should be checked by callers

        // First, update attributes including decay
        _updateNFTAttributes(tokenId, 0, 0, 0); // Apply decay

        // Calculate rewards since last claim/stake
        uint256 timeStakedSinceLastClaim = block.timestamp - staking.stakedTime;
        NFTAttributes memory currentAttributes = idToAttributes[tokenId]; // Use updated attributes

        // Reward calculation: Based on NFT's energy, time staked, and a global rate.
        // Simple model: Energy * time * rate / 1e18 (adjust units)
        // More complex: (NFT Energy / Pool Total Energy) * Pool Accumulated Rewards (requires different pool mechanics)
        // Let's use the simple model for clarity here:
        uint256 rewardsEarned = (currentAttributes.energy * timeStakedSinceLastClaim * HARMONY_REWARD_RATE_PER_ENERGY_PER_SECOND) / (1e18); // Scale down factor

        claimedAmount = staking.pendingRewards + rewardsEarned;

        // Apply pool fee before distributing
        uint256 fee = (claimedAmount * poolIdToPool[poolId].feeBasisPoints) / 10000;
        claimedAmount -= fee;
        // The fee amount could be sent to the pool creator or accumulated elsewhere,
        // but for this simple model, it's just removed from the amount distributed.

        staking.pendingRewards = 0; // Reset pending
        staking.stakedTime = block.timestamp; // Reset staking time for next calculation

        // Accumulated rewards are transferred in claimHarmonyShards, not here.
    }


    /**
     * @notice Calculates the potential pending rewards for a specific staked NFT. Does not claim.
     * @param tokenId The ID of the staked NFT.
     * @return rewards The amount of pending Harmony Shards.
     */
    function calculatePendingRewards(uint256 tokenId) public view returns (uint256 rewards) {
        StakingInfo memory staking = tokenIdToStakingInfo[tokenId];
        require(staking.poolId != 0, "Token is not staked");

        uint256 timeStakedSinceLastClaim = block.timestamp - staking.stakedTime;
        NFTAttributes memory currentAttributes = getNFTAttributes(tokenId); // Use decayed attributes for calculation

        uint256 rewardsEarned = (currentAttributes.energy * timeStakedSinceLastClaim * HARMONY_REWARD_RATE_PER_ENERGY_PER_SECOND) / (1e18);

        rewards = staking.pendingRewards + rewardsEarned;

        // Apply potential pool fee calculation for visibility (though not actually deducted until claim)
        uint256 poolId = staking.poolId;
        uint256 fee = (rewards * poolIdToPool[poolId].feeBasisPoints) / 10000;
        rewards -= fee;
    }

    /**
     * @notice Gets information about a specific Synergy Pool.
     * @param poolId The ID of the pool.
     * @return info The SynergyPool struct.
     */
    function getPoolInfo(uint256 poolId) public view returns (SynergyPool memory info) {
        require(poolIdToPool[poolId].creationTime != 0, "Pool does not exist");
        return poolIdToPool[poolId];
    }

     /**
     * @notice Gets the list of token IDs staked in a specific Synergy Pool.
     * Warning: Can be gas-intensive for pools with many NFTs.
     * @param poolId The ID of the pool.
     * @return tokenIds_ The list of staked token IDs.
     */
    function getPoolNFTs(uint256 poolId) public view returns (uint256[] memory tokenIds_) {
        require(poolIdToPool[poolId].creationTime != 0, "Pool does not exist");
        // Note: This returns the internal array directly. Consider copying for safety if needed.
        return poolToStakedNFTs[poolId];
    }


    // --- Attribute Mechanics ---

    /**
     * @notice Sacrifices a source NFT to boost the attributes of a target NFT.
     * @param sacrificedTokenId The ID of the NFT to burn.
     * @param targetTokenId The ID of the NFT to boost.
     */
    function sacrificeNFTForBoost(uint256 sacrificedTokenId, uint256 targetTokenId) external whenNotPaused {
        require(_exists(sacrificedTokenId), "Sacrifice token does not exist");
        require(_exists(targetTokenId), "Target token does not exist");
        require(ownerOf(sacrificedTokenId) == msg.sender, "Caller does not own sacrifice token");
        require(ownerOf(targetTokenId) == msg.sender, "Caller does not own target token");
        require(sacrificedTokenId != targetTokenId, "Cannot sacrifice token to itself");
        require(tokenIdToStakingInfo[sacrificedTokenId].poolId == 0, "Sacrifice token is staked");

        // Get sacrifice attributes (decayed)
        NFTAttributes memory sacrificeAttr = getNFTAttributes(sacrificedTokenId);

        // Calculate boost amount based on sacrifice attributes
        // Example: Boost = (Sacrifice Energy + Sacrifice Harmony + Sacrifice Rarity) / Factor
        // Let's make the boost proportional to sacrifice energy and rarity
        uint256 energyBoost = (sacrificeAttr.energy * sacrificeAttr.rarityScore) / 10000; // Scale factor
        uint256 harmonyBoost = (sacrificeAttr.harmony * sacrificeAttr.rarityScore) / 10000;
        uint256 rarityBoost = sacrificeAttr.rarityScore / 10; // Direct boost based on rarity

        // Burn the sacrifice token
        _burn(sacrificedTokenId);

        // Apply boost to the target token (this includes applying decay first)
        _updateNFTAttributes(targetTokenId, int256(energyBoost), int256(harmonyBoost), int256(rarityBoost));

        emit NFTSacrificed(sacrificedTokenId, targetTokenId, msg.sender);
    }

    // --- Governance (Attribute Boost Proposals) ---

    /**
     * @notice Allows an NFT owner or staker to propose boosting a target NFT's attributes.
     * Requires owning an NFT or having tokens staked for voting power.
     * @param targetTokenId The ID of the NFT to propose boosting.
     * @param energyBoost Proposed Energy increase.
     * @param harmonyBoost Proposed Harmony increase.
     * @param rarityBoost Proposed Rarity Score increase.
     */
    function proposeAttributeBoost(
        uint256 targetTokenId,
        uint256 energyBoost,
        uint256 harmonyBoost,
        uint256 rarityBoost
    ) external whenNotPaused {
        require(_exists(targetTokenId), "Target token does not exist");
        // Check if the proposer has any voting power (e.g., owns any NFT or has staked)
        // Simple check: must own at least one NFT
        require(balanceOf(msg.sender) > 0 || tokenIdToStakingInfo[_tokenIds.current()].poolId != 0, "Proposer must own an NFT or have one staked");

        _proposalCounter.increment();
        uint256 newProposalId = _proposalCounter.current();
        uint256 votingDeadline = block.timestamp + PROPOSAL_VOTING_PERIOD_DAYS * 1 days;

        proposalIdToProposal[newProposalId] = AttributeBoostProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            targetTokenId: targetTokenId,
            energyBoost: energyBoost,
            harmonyBoost: harmonyBoost,
            rarityBoost: rarityBoost,
            votingDeadline: votingDeadline,
            voteCountYes: 0,
            voteCountNo: 0,
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit AttributeBoostProposalCreated(newProposalId, msg.sender, targetTokenId, votingDeadline);
    }

    /**
     * @notice Casts a vote on an open proposal.
     * Requires owning an NFT or having tokens staked for voting power.
     * Voting power could be 1 token = 1 vote, or based on staked energy/rarity.
     * Simple model: 1 owned/staked NFT = 1 vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteYes True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnProposal(uint256 proposalId, bool voteYes) external whenNotPaused {
        AttributeBoostProposal storage proposal = proposalIdToProposal[proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");

        // Check if the voter has voting power (e.g., owns any NFT or has staked)
        // Simple check: must own at least one NFT
        require(balanceOf(msg.sender) > 0 || tokenIdToStakingInfo[_tokenIds.current()].poolId != 0, "Voter must own an NFT or have one staked");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (voteYes) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(proposalId, msg.sender, voteYes);
    }

    /**
     * @notice Executes a proposal if its voting period has ended and it passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        AttributeBoostProposal storage proposal = proposalIdToProposal[proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "Voting period is still active");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;

        // Check quorum: Is total votes > Quorum % of total potential voting power?
        // Total potential voting power could be total supply of NFTs.
        uint256 totalNFTs = _tokenIds.current();
        uint256 requiredQuorumVotes = (totalNFTs * PROPOSAL_QUORUM_PERCENTAGE) / 100;
        bool meetsQuorum = totalVotes >= requiredQuorumVotes;

        // Check if passed: Is Yes votes > Pass % of total votes?
        bool passed = meetsQuorum && (proposal.voteCountYes * 100) / totalVotes >= PROPOSAL_PASS_PERCENTAGE;

        proposal.executed = true;
        proposal.passed = passed;

        if (passed) {
            // Apply attribute boost to the target NFT
            _updateNFTAttributes(
                proposal.targetTokenId,
                int256(proposal.energyBoost),
                int256(proposal.harmonyBoost),
                int256(proposal.rarityBoost)
            );
        }

        emit ProposalExecuted(proposalId, passed);
    }

    /**
     * @notice Gets information about a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return info The AttributeBoostProposal struct.
     */
    function getProposalInfo(uint256 proposalId) public view returns (AttributeBoostProposal memory info) {
        AttributeBoostProposal memory proposal = proposalIdToProposal[proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        // Note: cannot return the internal mapping `hasVoted` directly
        return proposal;
    }

     /**
     * @notice Checks if a specific address has voted on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address to check.
     * @return hasVoted_ True if the address has voted, false otherwise.
     */
    function getVoterStatus(uint256 proposalId, address voter) public view returns (bool hasVoted_) {
         AttributeBoostProposal storage proposal = proposalIdToProposal[proposalId];
         require(proposal.proposalId != 0, "Proposal does not exist");
         return proposal.hasVoted[voter];
     }

    // --- Owner & Administrative ---

    /**
     * @notice Pauses contract operations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract operations.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the address of the Harmony Shard ERC20 token contract.
     * Can only be called once unless resetting is allowed.
     * @param harmonyTokenAddress The address of the ERC20 token contract.
     */
    function setHarmonyTokenAddress(address harmonyTokenAddress) external onlyOwner {
        require(address(_harmonyToken) == address(0), "Harmony token address already set");
        _harmonyToken = IERC20(harmonyTokenAddress);
    }

     /**
     * @notice Sets the required ETH fee to create a new Synergy Pool.
     * @param feeInWei The fee amount in Wei.
     */
    function setPoolCreationFee(uint256 feeInWei) external onlyOwner {
        _poolCreationFee = feeInWei;
    }

    /**
     * @notice Allows the owner to withdraw accumulated ETH fees from pool creation.
     */
    function withdrawFees() external onlyOwner {
        uint256 fees = _totalFees;
        _totalFees = 0;
        payable(owner()).transfer(fees);
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @param baseURI The base URI string.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // --- ERC721 Standard Overrides ---

    // Override _beforeTokenTransfer to prevent transferring staked NFTs
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If the token is currently staked (owned by this contract), prevent external transfer.
        // Allows transfer FROM this contract (unstaking)
        if (from == address(this) && to != address(0)) {
             // Transferring out from the contract, this is allowed (unstaking)
             // No need to do anything here, leaveSynergyPool handles state removal
        } else if (from != address(0) && to == address(this)) {
             // Transferring into the contract, this is allowed (staking)
             // No need to do anything here, joinSynergyPool handles state addition
        } else if (from != address(0) && to != address(0)) {
            // Standard transfer between external addresses
             require(tokenIdToStakingInfo[tokenId].poolId == 0, "Staked tokens cannot be transferred externally");
        }
    }
}
```