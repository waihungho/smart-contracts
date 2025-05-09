Okay, let's design a smart contract that combines several advanced and trendy concepts:

1.  **Dynamic NFTs:** NFTs that can change their properties based on certain conditions or interactions.
2.  **Reputation System:** Users earn reputation based on their participation and actions within the contract.
3.  **NFT Staking with Variable Yield:** Stake your dynamic NFTs to earn rewards, where the reward rate can depend on the NFT's dynamic attributes and your reputation.
4.  **Community-Influenced Evolution ("Catalysts"):** A simplified governance mechanism where users with sufficient reputation can propose and vote on "catalyst" parameters that influence how the dynamic NFTs evolve during mutations and potentially affect staking yield.
5.  **Treasury Management:** A simple treasury funded by interactions, used to pay staking rewards.

This contract won't duplicate a single well-known open-source project entirely, but will use standard building blocks (like ERC721 from OpenZeppelin for safety and interoperability) and combine concepts in a specific, hopefully novel way.

**Disclaimer:** This is a complex example for educational purposes. It covers many concepts but simplifies implementation details (e.g., using blockhash for pseudo-randomness, which is insecure for production; a real system might use Chainlink VRF). Security audits and robust random sources are crucial for production systems.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Required for tokensOfOwner (part of the 20+ function req)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max potentially

// --- Outline and Function Summary ---
/*
Contract: AdaptiveDigitalArtifacts (ADA) DAO

Core Concepts:
1.  Dynamic NFTs (Artifacts) with evolving on-chain state.
2.  User Reputation system earned through participation.
3.  NFT Staking with rewards influenced by NFT state and reputation.
4.  Community Governance via "Catalyst" proposals affecting mutation/staking params.
5.  Treasury for rewards and funding.

Structs:
- ArtifactState: Defines the dynamic attributes of an NFT.
- StakingInfo: Tracks staking start time and status for an artifact.
- CatalystParams: Current global parameters influencing evolution and staking.
- Proposal: Defines a community proposal to change CatalystParams.

Enums:
- ProposalState: Lifecycle states of a proposal.

State Variables:
- Artifact states mapping.
- User reputation mapping.
- Staked artifact info mapping.
- Current catalyst parameters.
- Proposal tracking mappings and counter.
- Treasury balance.
- Staking reward rates, mutation costs, etc.

Functions (Total: 37+):

// Standard ERC721 & Enumerable (9 functions + constructor)
1.  constructor(string memory name, string memory symbol, string memory baseURI)
2.  balanceOf(address owner) view
3.  ownerOf(uint256 tokenId) view
4.  safeTransferFrom(address from, address to, uint256 tokenId)
5.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
6.  transferFrom(address from, address to, uint256 tokenId)
7.  approve(address to, uint256 tokenId)
8.  getApproved(uint256 tokenId) view
9.  setApprovalForAll(address operator, bool approved)
10. isApprovedForAll(address owner, address operator) view
11. tokensOfOwner(address owner) view - (From ERC721Enumerable)
12. totalSupply() view - (From ERC721Enumerable)
13. tokenByIndex(uint256 index) view - (From ERC721Enumerable)
14. tokenOfOwnerByIndex(address owner, uint256 index) view - (From ERC721Enumerable)

// Artifact Management (7 functions)
15. mintArtifact(address to) payable - Mints a new artifact, setting initial state.
16. getArtifactState(uint256 tokenId) view - Retrieves the current dynamic state of an artifact.
17. getArtifactMetadataURI(uint256 tokenId) view - Generates or retrieves the metadata URI (abstracts dynamic metadata).
18. initiateMutation(uint256 tokenId) - Allows owner to attempt to mutate an artifact (costs reputation, has cooldown).
19. getMutationCooldown(uint256 tokenId) view - Gets time remaining until mutation is possible.
20. getMutationCost() view - Gets the reputation cost for mutation.
21. isArtifactStaked(uint256 tokenId) view - Checks if an artifact is currently staked.

// Reputation System (4 functions)
22. getReputation(address user) view - Gets a user's current reputation points.
23. claimReputationReward() - Allows users to claim pending reputation rewards (e.g., from staking).
24. getPendingReputationReward(address user) view - Calculates reputation earned but not claimed.
25. getReputationRequiredForAction(uint8 actionType) view - Gets reputation thresholds for specific actions (e.g., mutation, proposing).

// Staking System (5 functions)
26. stakeArtifact(uint256 tokenId) - Stakes an owned artifact.
27. unstakeArtifact(uint256 tokenId) - Unstakes a staked artifact.
28. getStakedArtifactInfo(uint256 tokenId) view - Gets staking details for an artifact.
29. calculatePendingStakingReward(address user) view - Calculates total pending ETH reward for a user's staked artifacts.
30. claimStakingRewards() - Claims accumulated ETH staking rewards and associated reputation.

// Governance (Catalyst Proposals) (11 functions)
31. createCatalystProposal(uint256 proposalId, string memory description, CatalystParams memory newParams) - Creates a new proposal to change catalyst parameters (requires reputation).
32. voteOnCatalystProposal(uint256 proposalId, bool voteYes) - Casts a vote on a proposal (weighted by reputation/stake).
33. getProposalState(uint256 proposalId) view - Gets the current state of a proposal.
34. getProposalVoteCount(uint256 proposalId) view - Gets the total vote weight cast on a proposal.
35. getProposalDetails(uint256 proposalId) view - Gets description and proposed parameters.
36. getProposalVoteYes(uint256 proposalId) view - Gets the total 'Yes' vote weight.
37. getProposalVoteNo(uint256 proposalId) view - Gets the total 'No' vote weight.
38. getProposalEndTime(uint256 proposalId) view - Gets the voting period end time.
39. getUserVote(uint256 proposalId, address user) view - Gets how a user voted.
40. queueExecution(uint256 proposalId) - Queues a successful proposal for execution after a timelock.
41. executeProposal(uint256 proposalId) - Executes a queued proposal, updating CatalystParams.

// Treasury & Parameters (3 functions)
42. getTreasuryBalance() view - Gets the current balance available for rewards.
43. getCurrentCatalystParameters() view - Gets the currently active catalyst parameters.
44. getStakingRewardRate() view - Gets the current base staking reward rate per second per artifact unit.

// Potential Admin (if needed, not counted in 20+)
// setMetadataServiceURI(string memory newURI)
// pause/unpause etc.
*/


contract AdaptiveDigitalArtifacts is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Constants & Parameters ---
    uint256 public constant MUTATION_COOLDOWN = 1 days;
    uint256 public constant BASE_MUTATION_REPUTATION_COST = 50;
    uint256 public constant REPUTATION_PER_STAKE_HOUR = 1; // Reputation earned per hour staked (example)
    uint256 public constant MIN_REPUTATION_FOR_MUTATION = 100;
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 500;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_TIMELOCK = 1 days; // Time after successful vote before execution
    uint256 public constant MIN_PROPOSAL_VOTE_WEIGHT = 1000; // Minimum total vote weight required

    // Base reward rate in Wei per second per 'value unit' of artifact
    // A value unit could be artifact level, rarity, etc.
    uint256 public constant BASE_STAKING_REWARD_RATE_PER_UNIT_PER_SEC = 1e14; // 0.0001 ETH per unit per second (example)

    // --- Structs ---
    struct ArtifactState {
        uint8 level; // Affects staking yield, mutation chance/effect
        uint8 rarity; // Affects staking yield, visual metadata
        uint16 elementalAffinity; // Bitmask or value representing affinities (e.g., 0x01 fire, 0x02 water, etc.)
        uint64 lastMutateTime; // Timestamp of the last mutation
        uint64 creationTime; // Timestamp of creation
        // Add more dynamic attributes here as needed
    }

    struct StakingInfo {
        uint64 stakeStartTime; // 0 if not staked
        address user; // Owner when staked
        uint256 tokenId; // Token ID being staked
        uint256 unclaimedReputation; // Reputation earned but not claimed
    }

    // Global parameters influencing artifact dynamics, set by governance
    struct CatalystParams {
        uint16 fireMutationChance; // 0-1000 (e.g., 100 = 10%)
        uint16 waterMutationChance;
        uint16 earthMutationChance;
        uint16 airMutationChance;
        uint8 levelUpChanceMultiplier; // Multiplier for level up chance during mutation
        uint8 rarityBoostChance; // Chance to slightly increase rarity
        uint16 stakingYieldBonusFactor; // Factor influencing staking rewards (e.g., 100 = 1x, 150 = 1.5x)
    }

    enum ProposalState {
        Pending, // Created, voting hasn't started (or starts immediately)
        Active, // Voting is open
        Defeated, // Voting ended, failed
        Succeeded, // Voting ended, passed
        Queued, // Passed and queued for execution
        Executed, // Executed successfully
        Expired, // Failed to be queued/executed in time
        Canceled // Manually canceled (e.g., by admin or specific rules)
    }

    struct Proposal {
        uint256 proposalId;
        string description;
        CatalystParams proposedParams;
        uint64 votingEndTime;
        uint64 executionTime; // Time after timelock
        ProposalState state;
        uint256 totalVotesWeight; // Total vote weight cast
        uint256 yesVotesWeight; // Total 'Yes' vote weight
        uint256 noVotesWeight; // Total 'No' vote weight
        mapping(address => bool) hasVoted; // User vote status
    }

    // --- State Variables ---
    mapping(uint256 => ArtifactState) private _artifactStates;
    mapping(address => uint256) private _reputationPoints;
    mapping(uint256 => StakingInfo) private _stakedArtifacts; // tokenId => StakingInfo

    // Mapping from user address to list/array of staked tokenIds
    // This helps calculate total rewards for a user without iterating all tokens
    mapping(address => uint256[] ) private _userStakedTokenIds;
    // Helper mapping to quickly check if a token is in _userStakedTokenIds array
    mapping(uint256 => int256) private _userStakedTokenIndex; // tokenId => index in array (-1 if not in array)

    CatalystParams public currentCatalystParams;

    mapping(uint256 => Proposal) private _proposals;
    uint256 public proposalCounter;

    string private _baseTokenURI;

    // --- Events ---
    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, ArtifactState initialState);
    event ArtifactMutated(uint256 indexed tokenId, ArtifactState newState, uint256 reputationCost);
    event ArtifactStaked(uint256 indexed tokenId, address indexed owner, uint256 stakeTime);
    event ArtifactUnstaked(uint256 indexed tokenId, address indexed owner, uint256 unstakeTime, uint256 ethReward, uint256 reputationEarned);
    event ReputationClaimed(address indexed user, uint256 reputationAmount);
    event StakingRewardClaimed(address indexed user, uint256 ethAmount, uint256 reputationAmount);
    event CatalystProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event CatalystParamsUpdated(uint256 indexed proposalId, CatalystParams newParams);
    event TreasuryFunded(address indexed contributor, uint256 amount);
    event TreasurySpent(address indexed recipient, uint256 amount);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender) // Initializes contract owner
    {
        _baseTokenURI = baseURI;
        _tokenIdCounter.increment(); // Start from 1 or adjust logic if starting from 0
        proposalCounter = 0; // Start proposal IDs from 0
        // Set initial catalyst parameters (example values)
        currentCatalystParams = CatalystParams({
            fireMutationChance: 200, // 20%
            waterMutationChance: 200,
            earthMutationChance: 200,
            airMutationChance: 200,
            levelUpChanceMultiplier: 100, // 1x multiplier
            rarityBoostChance: 5,       // 5%
            stakingYieldBonusFactor: 100 // 1x factor
        });
    }

    // --- ERC721 & Enumerable Overrides ---
    // Functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
    // Standard OpenZeppelin implementations inherited.
    // Added ERC721Enumerable for tokensOfOwner, totalSupply, tokenByIndex, tokenOfOwnerByIndex

    // --- Receive ETH ---
    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    // --- Artifact Management ---

    /// @notice Mints a new artifact and sets its initial state.
    /// @param to The address to mint the artifact to.
    /// @dev Initial state is simple; could be more complex based on minting price/params.
    function mintArtifact(address to) public payable returns (uint256) {
        // Optional: Add mint cost check or other conditions
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, newItemId);

        // Set initial state (can be pseudo-random based on blockhash/timestamp)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, newItemId, to)));
        ArtifactState memory initialState = ArtifactState({
            level: 1,
            rarity: uint8((seed % 10) + 1), // Rarity 1-10
            elementalAffinity: uint16(seed % 4), // Simple affinity 0-3
            lastMutateTime: uint64(block.timestamp),
            creationTime: uint64(block.timestamp)
        });
        _artifactStates[newItemId] = initialState;

        emit ArtifactMinted(newItemId, to, initialState);

        return newItemId;
    }

    /// @notice Gets the current dynamic state of a specific artifact.
    /// @param tokenId The ID of the artifact.
    /// @return The ArtifactState struct.
    function getArtifactState(uint256 tokenId) public view returns (ArtifactState memory) {
        require(_exists(tokenId), "ADA: Artifact does not exist");
        return _artifactStates[tokenId];
    }

    /// @notice Generates the metadata URI for an artifact based on its state.
    /// @param tokenId The ID of the artifact.
    /// @return The metadata URI.
    /// @dev This function is typically off-chain, but the smart contract provides the base URI
    ///      and potentially embeds dynamic data that the off-chain service uses.
    ///      For simplicity here, it just appends the ID. A real dynamic URI would
    ///      include state hash or link to a service endpoint + token ID.
    function getArtifactMetadataURI(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "ADA: Artifact does not exist");
         // In a real dynamic NFT, this URI would point to a service
         // that reads the artifact state from the contract and generates
         // the JSON metadata and potentially image URLs dynamically.
         // Example: ipfs://[base_cid]/metadata/{tokenId} -> Service retrieves state
         // or: https://api.myservice.com/metadata/{tokenId} -> Service retrieves state

         return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /// @notice Allows the artifact owner to initiate a mutation attempt.
    /// @param tokenId The ID of the artifact to mutate.
    /// @dev Requires reputation, pays cost, respects cooldown. State changes based on catalyst params.
    function initiateMutation(uint256 tokenId) public {
        require(_exists(tokenId), "ADA: Artifact does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "ADA: Only owner can mutate");
        require(!isArtifactStaked(tokenId), "ADA: Cannot mutate staked artifact");

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        require(currentTime >= artifact.lastMutateTime + MUTATION_COOLDOWN, "ADA: Mutation is on cooldown");
        uint256 mutationCost = BASE_MUTATION_REPUTATION_COST; // Could be dynamic
        require(_reputationPoints[msg.sender] >= mutationCost, "ADA: Not enough reputation to mutate");
        require(_reputationPoints[msg.sender] >= MIN_REPUTATION_FOR_MUTATION, "ADA: Does not meet minimum reputation threshold for mutation");

        _spendReputation(msg.sender, mutationCost);

        // Apply mutation effects based on current catalyst parameters and pseudo-randomness
        _applyMutationEffects(tokenId);

        artifact.lastMutateTime = currentTime;

        emit ArtifactMutated(tokenId, artifact, mutationCost);
    }

    /// @notice Internal function to apply mutation effects to an artifact.
    /// @param tokenId The ID of the artifact to mutate.
    /// @dev State changes are influenced by currentCatalystParams and blockhash/timestamp (pseudo-random).
    ///      **WARNING: block.prevrandao is deprecated and blockhash is not secure for high-value randomness.**
    ///      Use Chainlink VRF or similar in production.
    function _applyMutationEffects(uint256 tokenId) internal {
        ArtifactState storage artifact = _artifactStates[tokenId];
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId, artifact.lastMutateTime)));
        uint256 rand = seed;

        // Simulate state changes based on catalysts and pseudo-randomness
        uint16 totalAffinityChance = currentCatalystParams.fireMutationChance +
                                     currentCatalystParams.waterMutationChance +
                                     currentCatalystParams.earthMutationChance +
                                     currentCatalystParams.airMutationChance;

        if (totalAffinityChance > 0) {
             uint256 affinityRoll = rand % totalAffinityChance;
             rand = uint256(keccak256(abi.encodePacked(rand))); // New seed for next roll

             if (affinityRoll < currentCatalystParams.fireMutationChance) {
                 artifact.elementalAffinity = 0; // Fire
             } else if (affinityRoll < currentCatalystParams.fireMutationChance + currentCatalystParams.waterMutationChance) {
                 artifact.elementalAffinity = 1; // Water
             } else if (affinityRoll < currentCatalystParams.fireMutationChance + currentCatalystParams.waterMutationChance + currentCatalystParams.earthMutationChance) {
                 artifact.elementalAffinity = 2; // Earth
             } else {
                 artifact.elementalAffinity = 3; // Air
             }
        }

        // Level up chance influenced by catalyst multiplier
        uint256 levelUpRoll = rand % 1000; // Roll 0-999
        rand = uint256(keccak256(abi.encodePacked(rand))); // New seed

        uint256 effectiveLevelUpChance = 50 * currentCatalystParams.levelUpChanceMultiplier / 100; // Base 5% chance * multiplier
        if (levelUpRoll < effectiveLevelUpChance && artifact.level < 255) { // Cap level at 255
             artifact.level++;
        }

        // Rarity boost chance
        uint256 rarityBoostRoll = rand % 1000; // Roll 0-999
        rand = uint256(keccak256(abi.encodePacked(rand))); // New seed

        if (rarityBoostRoll < currentCatalystParams.rarityBoostChance * 10 && artifact.rarity < 10) { // Rarity max 10
            artifact.rarity++;
        }

        // More complex state changes based on previous state, affinities, etc. can be added here
        // E.g., elementalAffinity could be a bitmask allowing multiple affinities that shift
        // artifact.elementalAffinity |= (1 << (rand % 4)); // Example: add a random affinity
        // artifact.elementalAffinity &= ~(1 << (rand % 4)); // Example: remove a random affinity

    }


    /// @notice Gets the time remaining until an artifact can be mutated again.
    /// @param tokenId The ID of the artifact.
    /// @return Time in seconds remaining. Returns 0 if cooldown is over.
    function getMutationCooldown(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ADA: Artifact does not exist");
        ArtifactState storage artifact = _artifactStates[tokenId];
        uint64 timePassed = uint64(block.timestamp) - artifact.lastMutateTime;
        if (timePassed >= MUTATION_COOLDOWN) {
            return 0;
        } else {
            return MUTATION_COOLDOWN - timePassed;
        }
    }

    /// @notice Gets the current reputation cost to initiate a mutation.
    /// @return The reputation cost.
    function getMutationCost() public view returns (uint256) {
        // Could be dynamic based on level, rarity, etc.
        return BASE_MUTATION_REPUTATION_COST;
    }

     /// @notice Checks if an artifact is currently staked.
    /// @param tokenId The ID of the artifact.
    /// @return True if staked, false otherwise.
    function isArtifactStaked(uint256 tokenId) public view returns (bool) {
        return _stakedArtifacts[tokenId].stakeStartTime > 0;
    }

    // --- Reputation System ---

    /// @notice Gets the current reputation points for a user.
    /// @param user The address of the user.
    /// @return The user's reputation points.
    function getReputation(address user) public view returns (uint256) {
        return _reputationPoints[user] + getPendingReputationReward(user); // Include pending reputation from staking
    }

    /// @notice Internal function to add reputation points.
    /// @param user The address to add reputation to.
    /// @param amount The amount of reputation to add.
    function _addReputation(address user, uint256 amount) internal {
        _reputationPoints[user] += amount;
    }

    /// @notice Internal function to spend reputation points.
    /// @param user The address to spend reputation from.
    /// @param amount The amount of reputation to spend.
    function _spendReputation(address user, uint256 amount) internal {
        require(_reputationPoints[user] >= amount, "ADA: Insufficient reputation");
        _reputationPoints[user] -= amount;
    }

    /// @notice Calculates reputation earned from staking but not yet claimed.
    /// @param user The user address.
    /// @return Total pending reputation reward.
    function getPendingReputationReward(address user) public view returns (uint256) {
        uint256 totalPendingReputation = 0;
        for (uint i = 0; i < _userStakedTokenIds[user].length; i++) {
            uint256 tokenId = _userStakedTokenIds[user][i];
            StakingInfo storage staking = _stakedArtifacts[tokenId];
            uint256 duration = uint64(block.timestamp) - staking.stakeStartTime;
            // Simple calculation: reputation per hour staked
            uint256 earnedThisStake = (duration * REPUTATION_PER_STAKE_HOUR) / 3600;
            totalPendingReputation += staking.unclaimedReputation + earnedThisStake;
        }
        return totalPendingReputation;
    }

    /// @notice Allows users to claim pending reputation rewards from staking.
    /// @dev This is called internally by `claimStakingRewards`, but could potentially be separate.
    ///      Let's integrate it into `claimStakingRewards` for simplicity.
    function claimReputationReward() public {
        // Logic moved to claimStakingRewards
        revert("ADA: Claim reputation via claimStakingRewards");
    }


     /// @notice Gets the reputation required for a specific action type.
    /// @param actionType 0: Mutation, 1: Create Proposal, etc.
    /// @return The required reputation amount.
    function getReputationRequiredForAction(uint8 actionType) public pure returns (uint256) {
        if (actionType == 0) return MIN_REPUTATION_FOR_MUTATION;
        if (actionType == 1) return MIN_REPUTATION_FOR_PROPOSAL;
        // Add more action types as needed
        return 0; // Default
    }


    // --- Staking System ---

    /// @notice Stakes an owned artifact. Transfers token to contract.
    /// @param tokenId The ID of the artifact to stake.
    function stakeArtifact(uint256 tokenId) public {
        require(_exists(tokenId), "ADA: Artifact does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "ADA: Only owner can stake their artifact");
        require(!isArtifactStaked(tokenId), "ADA: Artifact is already staked");

        // Transfer the token to the contract address
        _transfer(owner, address(this), tokenId);

        // Store staking info
        _stakedArtifacts[tokenId] = StakingInfo({
            stakeStartTime: uint64(block.timestamp),
            user: owner,
            tokenId: tokenId,
            unclaimedReputation: 0 // Starts with 0 unclaimed reputation
        });

        // Add to user's staked tokens list
        _userStakedTokenIds[owner].push(tokenId);
        _userStakedTokenIndex[tokenId] = int256(_userStakedTokenIds[owner].length - 1);

        emit ArtifactStaked(tokenId, owner, block.timestamp);
    }

    /// @notice Unstakes a previously staked artifact. Transfers token back to owner.
    /// @param tokenId The ID of the artifact to unstake.
    /// @dev Automatically claims pending rewards and reputation.
    function unstakeArtifact(uint256 tokenId) public {
        require(_exists(tokenId), "ADA: Artifact does not exist (potentially unstaked)");
        require(ownerOf(tokenId) == address(this), "ADA: Artifact is not staked here"); // Double check it's held by contract
        require(isArtifactStaked(tokenId), "ADA: Artifact is not currently staked");

        StakingInfo storage staking = _stakedArtifacts[tokenId];
        require(staking.user == msg.sender, "ADA: Only original staker can unstake");

        // Calculate rewards and reputation before clearing stake info
        uint256 pendingEthReward = calculatePendingStakingReward(msg.sender);
        uint256 pendingReputation = getPendingReputationReward(msg.sender); // Includes all staked tokens

        // Transfer the token back to the original staker
        _transfer(address(this), msg.sender, tokenId);

        // Remove from user's staked tokens list
        int256 indexToRemove = _userStakedTokenIndex[tokenId];
        uint256 lastIndex = _userStakedTokenIds[msg.sender].length - 1;
        if (indexToRemove != lastIndex) {
            uint256 lastTokenId = _userStakedTokenIds[msg.sender][lastIndex];
            _userStakedTokenIds[msg.sender][uint256(indexToRemove)] = lastTokenId;
            _userStakedTokenIndex[lastTokenId] = indexToRemove;
        }
        _userStakedTokenIds[msg.sender].pop();
        delete _userStakedTokenIndex[tokenId]; // Remove index mapping

        // Clear staking info for this token
        delete _stakedArtifacts[tokenId];

        // Distribute rewards and reputation (for ALL of user's staked tokens)
        // Note: This unstakes one token but claims rewards for all. A cleaner design might claim per token.
        // Or, the user must explicitly call claimStakingRewards BEFORE unstaking if they want per-token claim.
        // Let's make unstaking one token claim *all* rewards/reputation for that user for simplicity here.
        // This design requires recalculating total rewards/reputation. Let's refine: unstaking *only* claims for *that specific token*.
        // Recalculate rewards for *this* token:
        uint256 duration = uint64(block.timestamp) - staking.stakeStartTime;
        uint256 thisEthReward = _calculateStakingRewardForToken(tokenId, duration);
        uint256 thisReputationEarned = (duration * REPUTATION_PER_STAKE_HOUR) / 3600;
        thisReputationEarned += staking.unclaimedReputation; // Add any previously unclaimed reputation

        // Add earned reputation to user's total *claimable* reputation
        _addReputation(msg.sender, thisReputationEarned);

        // Send ETH reward from treasury
        if (thisEthReward > 0) {
             require(address(this).balance >= thisEthReward, "ADA: Treasury insufficient for reward");
             (bool success, ) = payable(msg.sender).call{value: thisEthReward}("");
             require(success, "ADA: ETH transfer failed");
             emit TreasurySpent(msg.sender, thisEthReward);
        }

        emit ArtifactUnstaked(tokenId, msg.sender, block.timestamp, thisEthReward, thisReputationEarned);
    }

     /// @notice Gets staking information for a specific artifact.
    /// @param tokenId The ID of the artifact.
    /// @return StakingInfo struct.
    function getStakedArtifactInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        require(isArtifactStaked(tokenId), "ADA: Artifact is not staked");
        return _stakedArtifacts[tokenId];
    }


    /// @notice Calculates the total pending staking reward (ETH) for a user.
    /// @param user The user address.
    /// @return Total pending ETH reward in Wei.
    function calculatePendingStakingReward(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        uint256[] memory stakedTokenIds = _userStakedTokenIds[user];
        uint64 currentTime = uint64(block.timestamp);

        for (uint i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];
            StakingInfo storage staking = _stakedArtifacts[tokenId]; // Read from storage
            uint64 duration = currentTime - staking.stakeStartTime;
            totalReward += _calculateStakingRewardForToken(tokenId, duration);
        }
        return totalReward;
    }

    /// @dev Internal helper to calculate reward for a single token over a duration.
    function _calculateStakingRewardForToken(uint256 tokenId, uint256 duration) internal view returns (uint256) {
        if (duration == 0) return 0;

        ArtifactState storage artifact = _artifactStates[tokenId]; // Read from storage

        // Example calculation: Reward based on level, rarity, and catalyst bonus
        uint256 artifactValueUnits = artifact.level + artifact.rarity; // Simple unit calculation
        if (artifactValueUnits == 0) return 0;

        uint256 baseReward = artifactValueUnits * BASE_STAKING_REWARD_RATE_PER_UNIT_PER_SEC;
        uint256 bonusReward = (baseReward * currentCatalystParams.stakingYieldBonusFactor) / 100; // Apply catalyst bonus

        // Apply user reputation bonus? (Optional, adds complexity)
        // uint256 userReputation = getReputation(staking.user); // Might include pending reputation, be careful of re-calculation
        // uint256 reputationBonusFactor = 100 + (userReputation / 100); // Example: 1% bonus per 100 rep
        // bonusReward = (bonusReward * reputationBonusFactor) / 100;

        uint256 totalRatePerSec = baseReward + bonusReward;

        return totalRatePerSec * duration;
    }

     /// @notice Claims accumulated ETH staking rewards and pending reputation.
    /// @dev Resets stakeStartTime for claimed periods and adds reputation.
    function claimStakingRewards() public {
        uint256 totalEthReward = 0;
        uint256 totalReputationEarned = 0;
        uint64 currentTime = uint64(block.timestamp);

        uint256[] memory stakedTokenIds = _userStakedTokenIds[msg.sender]; // Read list once
        for (uint i = 0; i < stakedTokenIds.length; i++) {
            uint256 tokenId = stakedTokenIds[i];
            StakingInfo storage staking = _stakedArtifacts[tokenId]; // Access storage directly

            uint64 duration = currentTime - staking.stakeStartTime;
            if (duration > 0) {
                // Calculate ETH reward for this token over this duration
                uint256 ethReward = _calculateStakingRewardForToken(tokenId, duration);
                totalEthReward += ethReward;

                // Calculate Reputation earned for this token over this duration
                uint256 reputationEarned = (duration * REPUTATION_PER_STAKE_HOUR) / 3600;
                totalReputationEarned += reputationEarned + staking.unclaimedReputation;

                // Update stakeStartTime to now for future calculations and reset unclaimed reputation
                staking.stakeStartTime = currentTime;
                staking.unclaimedReputation = 0; // Reset unclaimed reputation for this specific stake entry
            }
        }

        // Add claimed reputation to the user's total points
         if (totalReputationEarned > 0) {
            _addReputation(msg.sender, totalReputationEarned);
            emit ReputationClaimed(msg.sender, totalReputationEarned);
         }


        // Send total ETH reward from treasury
        if (totalEthReward > 0) {
            require(address(this).balance >= totalEthReward, "ADA: Treasury insufficient for reward");
            (bool success, ) = payable(msg.sender).call{value: totalEthReward}("");
            require(success, "ADA: ETH transfer failed");
            emit TreasurySpent(msg.sender, totalEthReward);
        }

        if (totalEthReward > 0 || totalReputationEarned > 0) {
             emit StakingRewardClaimed(msg.sender, totalEthReward, totalReputationEarned);
        }
    }

    /// @notice Gets the current base staking reward rate per second per artifact unit.
    /// @return The rate in Wei per second per unit.
    function getStakingRewardRate() public pure returns (uint256) {
        return BASE_STAKING_REWARD_RATE_PER_UNIT_PER_SEC;
    }


    // --- Governance (Catalyst Proposals) ---

    /// @notice Creates a new proposal to change catalyst parameters.
    /// @param proposalId The unique ID for the proposal.
    /// @param description A description of the proposed change.
    /// @param newParams The proposed new CatalystParams values.
    /// @dev Requires minimum reputation to create a proposal. Proposal ID must be sequential.
    function createCatalystProposal(uint256 proposalId, string memory description, CatalystParams memory newParams) public {
        require(_reputationPoints[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL, "ADA: Not enough reputation to create proposal");
        require(proposalId == proposalCounter, "ADA: Invalid proposal ID sequence");
        require(_proposals[proposalId].state == ProposalState.Pending, "ADA: Proposal ID already used"); // Should be true if ID is sequential

        _proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            proposedParams: newParams,
            votingEndTime: uint64(block.timestamp) + uint64(PROPOSAL_VOTING_PERIOD),
            executionTime: 0, // Not set until queued
            state: ProposalState.Active, // Starts Active immediately
            totalVotesWeight: 0,
            yesVotesWeight: 0,
            noVotesWeight: 0,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        proposalCounter++; // Increment for the next proposal

        emit CatalystProposalCreated(proposalId, msg.sender, description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /// @notice Casts a vote on an active proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voteYes True for a 'Yes' vote, false for a 'No' vote.
    /// @dev Vote weight is based on user's reputation + potentially staked NFTs (simplified here to reputation only).
    function voteOnCatalystProposal(uint256 proposalId, bool voteYes) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "ADA: Proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "ADA: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ADA: User has already voted");

        uint256 voteWeight = getReputation(msg.sender); // Simple weight = reputation
        // Could add staked NFT weight: voteWeight += _userStakedTokenIds[msg.sender].length * 100; // Example: 100 weight per staked NFT
        require(voteWeight > 0, "ADA: User has no voting weight");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalVotesWeight += voteWeight;

        if (voteYes) {
            proposal.yesVotesWeight += voteWeight;
        } else {
            proposal.noVotesWeight += voteWeight;
        }

        emit VoteCast(proposalId, msg.sender, voteYes, voteWeight);
    }

    /// @notice Updates the state of a proposal based on time and vote counts.
    /// @param proposalId The ID of the proposal.
    /// @dev Can be called by anyone to update the state after voting ends.
    function updateProposalState(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingEndTime) {
            if (proposal.totalVotesWeight >= MIN_PROPOSAL_VOTE_WEIGHT && proposal.yesVotesWeight > proposal.noVotesWeight) {
                 proposal.state = ProposalState.Succeeded;
                 emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
            } else {
                 proposal.state = ProposalState.Defeated;
                 emit ProposalStateChanged(proposalId, ProposalState.Defeated);
            }
        }
         // Add logic for other state transitions if needed (e.g., Expired)
    }

    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The state of the proposal.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        // Call internal update logic in view? No, pure view. User must trigger updateProposalState indirectly or helper function.
        // Or, just check time here, but acknowledge state might be stale if update was not called.
        // Let's allow calling update internally first if needed, but for getter, just return stored state.
        return _proposals[proposalId].state;
    }

    /// @notice Gets the total vote weight cast on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Total vote weight.
    function getProposalVoteCount(uint256 proposalId) public view returns (uint256) {
         return _proposals[proposalId].totalVotesWeight;
    }

    /// @notice Gets the description and proposed parameters of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return description, proposedParams struct.
    function getProposalDetails(uint256 proposalId) public view returns (string memory description, CatalystParams memory proposedParams) {
         return (_proposals[proposalId].description, _proposals[proposalId].proposedParams);
    }

     /// @notice Gets the total 'Yes' vote weight for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Total 'Yes' vote weight.
    function getProposalVoteYes(uint256 proposalId) public view returns (uint256) {
         return _proposals[proposalId].yesVotesWeight;
    }

    /// @notice Gets the total 'No' vote weight for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Total 'No' vote weight.
    function getProposalVoteNo(uint256 proposalId) public view returns (uint256) {
         return _proposals[proposalId].noVotesWeight;
    }

    /// @notice Gets the voting period end time for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return End time timestamp.
    function getProposalEndTime(uint256 proposalId) public view returns (uint64) {
         return _proposals[proposalId].votingEndTime;
    }

     /// @notice Gets whether a user has voted on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param user The user address.
    /// @return True if the user has voted, false otherwise.
    function getUserVote(uint256 proposalId, address user) public view returns (bool) {
         // Cannot return the vote itself (yes/no) from a mapping like this.
         // Can only check existence. A separate mapping could store the vote choice.
         // For simplicity, this just confirms *if* they voted.
         return _proposals[proposalId].hasVoted[user];
    }


    /// @notice Queues a successfully voted proposal for execution after a timelock.
    /// @param proposalId The ID of the proposal.
    /// @dev Can be called by anyone after the voting period ends and proposal succeeded.
    function queueExecution(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        updateProposalState(proposalId); // Ensure state is updated

        require(proposal.state == ProposalState.Succeeded, "ADA: Proposal must be in Succeeded state");
        require(proposal.executionTime == 0, "ADA: Proposal already queued or executed");

        proposal.executionTime = uint64(block.timestamp) + uint64(PROPOSAL_TIMELOCK);
        proposal.state = ProposalState.Queued;

        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    /// @notice Executes a queued proposal after its timelock.
    /// @param proposalId The ID of the proposal.
    /// @dev Can be called by anyone after the timelock expires. Updates CatalystParams.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Queued, "ADA: Proposal must be in Queued state");
        require(block.timestamp >= proposal.executionTime, "ADA: Timelock has not expired");

        // Apply the proposed catalyst parameters
        currentCatalystParams = proposal.proposedParams;
        proposal.state = ProposalState.Executed;

        emit CatalystParamsUpdated(proposalId, currentCatalystParams);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        // Potential: Add reputation gain for successful execution caller or voters?
    }

    /// @notice Gets the estimated execution time for a queued proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The execution time timestamp, or 0 if not queued.
    function getProposalEta(uint256 proposalId) public view returns (uint64) {
         return _proposals[proposalId].executionTime;
    }


    // --- Treasury & Parameters ---

    /// @notice Gets the current ETH balance of the contract treasury.
    /// @return The treasury balance in Wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the currently active catalyst parameters influencing artifact dynamics.
    /// @return The current CatalystParams struct.
    function getCurrentCatalystParameters() public view returns (CatalystParams memory) {
        return currentCatalystParams;
    }


    // --- Base URI for Metadata (Standard ERC721 extension) ---

     /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // This relies on an off-chain service to interpret the dynamic state (getArtifactState)
        // and provide the full JSON metadata including image, description etc.
        return getArtifactMetadataURI(tokenId);
    }

    // --- Internal helper overrides for ERC721Enumerable ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring *from* this contract (unstaking or manual admin transfer)
        // ensure the artifact is removed from the staked list/mapping
         if (from == address(this)) {
            // Check if it was a staked token being transferred out
            if (_stakedArtifacts[tokenId].user != address(0)) { // Check if staking info exists (implies it was staked)
                 // This transfer logic conflicts with the unstake logic which handles _userStakedTokenIds removal.
                 // If unstake is the *only* way to transfer out, this check isn't strictly necessary here.
                 // If admin can transfer out, this might need adjustment to handle the user's staked list.
                 // For this example, assume unstake() is the path out of staking.
            }
         }
    }

    // --- Owner/Admin Functions (Optional, not strictly part of 20+ core concept functions) ---
     /// @notice Allows the owner to set the base URI for metadata.
    function setMetadataServiceURI(string memory newURI) public onlyOwner {
        _baseTokenURI = newURI;
    }

    /// @notice Allows the owner to withdraw excess ETH from the treasury.
    /// @dev Care must be taken not to drain funds needed for staking rewards.
    function withdrawTreasury(address payable recipient, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "ADA: Insufficient treasury balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ADA: ETH withdrawal failed");
        emit TreasurySpent(recipient, amount);
    }

    // Fallback function to receive ETH
    // fallback() external payable {
    //    emit TreasuryFunded(msg.sender, msg.value);
    // }
     // `receive()` is preferred over `fallback()` for plain ETH transfers
}
```

---

**Explanation of Concepts and Implementation Details:**

1.  **Dynamic NFTs (`ArtifactState`):**
    *   Each ERC721 token has a corresponding `ArtifactState` struct stored in a mapping.
    *   This struct holds dynamic attributes like `level`, `rarity`, `elementalAffinity`, and timestamps.
    *   `getArtifactState` allows reading this state on-chain.
    *   `getArtifactMetadataURI` is designed to work with an off-chain service that would read this state and generate dynamic metadata (image, JSON) reflecting the artifact's current attributes.
    *   `initiateMutation` is the core function that changes this state.

2.  **Reputation System:**
    *   A simple `mapping(address => uint256)` tracks reputation points.
    *   Reputation is primarily earned by claiming staking rewards (`claimStakingRewards`). This incentivizes active participation (staking) over just holding.
    *   Reputation is spent by initiating mutations (`initiateMutation`) and is required to create governance proposals (`createCatalystProposal`).
    *   `getReputation` includes pending reputation from staking.

3.  **NFT Staking with Variable Yield:**
    *   `stakeArtifact` transfers the token to the contract and records the staking start time and owner in `_stakedArtifacts`. It also updates `_userStakedTokenIds` for efficient lookups.
    *   `unstakeArtifact` transfers the token back and removes staking info. Critically, it triggers the claiming of rewards and reputation *for that specific unstaked token*.
    *   `calculatePendingStakingReward` iterates over a user's staked tokens to sum up their potential ETH rewards based on staking duration.
    *   `_calculateStakingRewardForToken` calculates the reward for a single token. The logic (`artifact.level + artifact.rarity` influencing `artifactValueUnits`) makes the yield *variable* based on the artifact's dynamic state. The `currentCatalystParams.stakingYieldBonusFactor` adds another layer of variability based on community governance.
    *   `claimStakingRewards` allows users to claim rewards and reputation without unstaking. It calculates pending rewards for *all* their staked tokens, transfers ETH from the treasury, adds reputation, and resets the reward calculation start point for the staked tokens.

4.  **Community-Influenced Evolution (`Catalysts`) & Governance:**
    *   `CatalystParams` struct holds global parameters (like mutation chances, yield bonuses). These are the "catalysts" that shape the ecosystem.
    *   These parameters can *only* be changed via a governance process.
    *   `Proposal` struct tracks governance proposals to change `CatalystParams`.
    *   `createCatalystProposal` allows users with enough reputation to propose new `CatalystParams`.
    *   `voteOnCatalystProposal` allows users (with voting weight, defined as reputation here) to vote Yes/No.
    *   `updateProposalState` (internal helper, could be public) transitions the proposal state based on voting time and results.
    *   `queueExecution` moves a successful proposal to a queued state, adding a `PROPOSAL_TIMELOCK` before it can be enacted. This gives users time to react if a harmful proposal passed.
    *   `executeProposal` enacts the changes by updating `currentCatalystParams`, provided the timelock has passed.
    *   Several getter functions expose proposal state and details.

5.  **Treasury Management:**
    *   The `receive()` payable function allows anyone to send ETH to the contract, funding the treasury (intended for rewards).
    *   Staking rewards are paid out from this balance.
    *   `getTreasuryBalance` allows viewing the balance.
    *   A basic `withdrawTreasury` for the owner is included (use with caution in a DAO context).

**Advanced Concepts Used:**

*   **State-Dependent Logic:** Staking yield and mutation outcomes directly depend on the NFT's `ArtifactState` and the global `CatalystParams`.
*   **Reputation as a Resource/Voting Weight:** Reputation is earned, spent, required for actions, and used for voting weight.
*   **Token-Weighted Governance (Simplified):** Voting weight is based on reputation (a form of soft stake/participation weight).
*   **Time-Based Mechanics:** Cooldowns (mutation), staking duration (rewards, reputation), voting periods, and timelocks are integral.
*   **Internal Accounting:** Tracking staked tokens per user (`_userStakedTokenIds`, `_userStakedTokenIndex`) to efficiently calculate user-specific rewards.
*   **Pseudorandomness Influenced by Parameters:** Mutation effects are randomly determined but biased by the `currentCatalystParams`. (Again, acknowledging the security weakness of `block.prevrandao`/`blockhash`).

This contract provides a framework for a dynamic NFT ecosystem where artifact properties evolve, participation builds reputation, and the community can collectively steer the direction of the evolution and reward mechanisms through a basic governance process.