Okay, let's create a unique smart contract concept combining dynamic asset properties, a reputation system, fractional pooled ownership, and some governance elements. We'll call it "The Chronoforge Nexus".

**Concept:** Users contribute a special resource (`Spark`) to power the Chronoforge. The Chronoforge has dynamic "Temporal Stability" traits that change based on the total Spark contributed and potentially historical events. Contributing Spark earns users "Resonance" (reputation). Resonance can be used for governance votes or to mint unique "Epoch Shard" NFTs, which capture the Chronoforge's traits at that moment.

**Advanced/Creative/Trendy Elements:**
1.  **Dynamic State:** The contract's core state (`TemporalStabilityTraits`) changes based on external factors (contributions) and internal logic.
2.  **Reputation System (Resonance):** An on-chain, non-transferable score influencing user capabilities (voting, special actions).
3.  **Reputation Decay/Activity Check:** Resonance might decay if a user is inactive, incentivizing participation.
4.  **Spark Pooling:** A shared pool of value (Spark) influences the state.
5.  **State-Bound NFTs (Epoch Shards):** NFTs minted that permanently store the dynamic state of the Chronoforge at the time of minting.
6.  **Delegated Resonance:** Users can delegate their voting/influence power without transferring Resonance itself.
7.  **Catalyst Burn:** Burning Spark for a temporary, strong influence on Temporal Stability.
8.  **Basic On-Chain Governance:** Proposals and voting based on Resonance.
9.  **Time-Based Logic:** Decay, proposal deadlines, cooldowns.

---

**Outline & Function Summary**

**Contract Name:** ChronoforgeNexus

**Purpose:** Manages a dynamic digital artifact (Chronoforge) powered by user contributions (Spark). Tracks user reputation (Resonance), allows minting state-bound NFTs (Epoch Shards), and includes basic governance.

**Key Data Structures:**
*   `TemporalStabilityTraits`: Struct holding the dynamic state of the Chronoforge.
*   `EpochShardData`: Struct holding static data for each minted NFT.
*   `Proposal`: Struct for governance proposals.

**State Variables:**
*   `owner`: Contract deployer.
*   `totalSparkPooled`: Total Spark contributed.
*   `sparkBalances`: Mapping user -> Spark balance (if withdrawal/transfer is allowed, simplified here as pooled).
*   `resonanceScores`: Mapping user -> Resonance score.
*   `lastInteractionTime`: Mapping user -> Timestamp of last relevant interaction (for decay).
*   `temporalStability`: Instance of `TemporalStabilityTraits`.
*   `epochShardData`: Mapping token ID -> `EpochShardData`.
*   `_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`: Mappings for basic ERC721 implementation.
*   `nextEpochShardId`: Counter for NFT token IDs.
*   `proposals`: Mapping proposal ID -> `Proposal`.
*   `nextProposalId`: Counter for proposals.
*   `resonanceDelegates`: Mapping user -> delegatee address.

**Functions (>= 20):**

**Core Interaction & State Management:**
1.  `contributeSpark(amount)`: User contributes Spark, increases `totalSparkPooled`, gains Resonance, updates `lastInteractionTime`.
2.  `viewTotalSparkPooled()`: Returns the total pooled Spark.
3.  `viewResonance(user)`: Returns the Resonance score for a user.
4.  `decayInactiveResonance(user)`: Callable function (by anyone) to trigger potential Resonance decay for an inactive user.
5.  `getTemporalStability()`: Returns the current dynamic `TemporalStabilityTraits`.
6.  `_updateTemporalStability()`: Internal function to recalculate `temporalStability` based on `totalSparkPooled` and potentially other factors. Called after contributions or specific events. (Will make it public/callable for demonstration).
7.  `burnSparkForTemporalBoost(amount)`: User burns Spark for a temporary boost effect on traits. (Requires more complex state/timing, simplify for demo as just burning).

**Epoch Shard NFTs (Custom ERC721 Implementation):**
8.  `mintEpochShard(user)`: Mints an Epoch Shard NFT to `user`, capturing the current `temporalStability` traits. Requires certain Resonance.
9.  `getEpochShardTraits(tokenId)`: Returns the captured `TemporalStabilityTraits` for a specific Epoch Shard.
10. `tokenURI(tokenId)`: Returns the metadata URI for an Epoch Shard (required for ERC721 metadata standard).
    *   *Standard ERC721 functions (minimal implementation for demonstration):*
11. `balanceOf(owner)`: Returns the number of NFTs owned by `owner`.
12. `ownerOf(tokenId)`: Returns the owner of a specific NFT.
13. `transferFrom(from, to, tokenId)`: Transfers NFT (authorized).
14. `safeTransferFrom(from, to, tokenId, data)`: Transfers NFT (safe version).
15. `approve(to, tokenId)`: Approves an address to transfer a specific NFT.
16. `getApproved(tokenId)`: Returns the approved address for an NFT.
17. `setApprovalForAll(operator, approved)`: Sets approval for an operator for all of sender's NFTs.
18. `isApprovedForAll(owner, operator)`: Checks if an operator is approved for all of owner's NFTs.

**Resonance Delegation & Governance:**
19. `delegateResonance(delegatee)`: Delegates voting/influence power to another address.
20. `getResonanceDelegate(user)`: Returns the address a user has delegated to.
21. `createProposal(description, target, value, calldata, votingPeriodSeconds)`: Creates a new governance proposal (requires minimum Resonance).
22. `voteOnProposal(proposalId, support)`: Casts a vote (up/down) on a proposal using effective Resonance (self or delegated).
23. `executeProposal(proposalId)`: Executes a successfully voted-on proposal.
24. `getProposalState(proposalId)`: Returns the current state (votes, active, etc.) of a proposal.
25. `getEffectiveResonance(user)`: Internal helper (exposed publicly for view) returning user's Resonance plus delegated Resonance.

**Admin/Utility:**
26. `withdrawSpark(amount)`: Owner can withdraw Spark from the pool (e.g., for maintenance, development). Needs to be handled carefully or removed depending on desired contract trustlessness.
27. `setResonanceDecayRate(rate)`: Owner sets the rate at which inactive Resonance decays.
28. `setEpochShardMintCost(requiredResonance, requiredSpark)`: Owner sets the cost (in Resonance and/or Spark) to mint an Epoch Shard.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Interface for safe transfer

// --- Outline & Function Summary ---
// Contract Name: ChronoforgeNexus
// Purpose: Manages a dynamic digital artifact (Chronoforge) powered by user contributions (Spark). Tracks user reputation (Resonance), allows minting state-bound NFTs (Epoch Shards), and includes basic governance.
//
// Key Data Structures:
// - TemporalStabilityTraits: Struct holding the dynamic state of the Chronoforge.
// - EpochShardData: Struct holding static data for each minted NFT.
// - Proposal: Struct for governance proposals.
//
// State Variables:
// - owner: Contract deployer.
// - totalSparkPooled: Total Spark contributed (uint256).
// - resonanceScores: Mapping user -> Resonance score (uint256).
// - lastInteractionTime: Mapping user -> Timestamp of last relevant interaction (uint64).
// - temporalStability: Instance of TemporalStabilityTraits.
// - epochShardData: Mapping token ID -> EpochShardData.
// - _owners, _balances, _tokenApprovals, _operatorApprovals: Mappings for basic ERC721 implementation.
// - nextEpochShardId: Counter for NFT token IDs (uint256).
// - proposals: Mapping proposal ID -> Proposal.
// - nextProposalId: Counter for proposals (uint256).
// - resonanceDelegates: Mapping user -> delegatee address.
// - resonanceDecayRate: Rate for reputation decay (uint256, e.g., points per second/day).
// - epochShardMintResonanceCost: Minimum Resonance required to mint an Epoch Shard (uint256).
// - epochShardMintSparkCost: Spark burned to mint an Epoch Shard (uint256).
// - proposalCreationResonanceCost: Minimum Resonance to create a proposal (uint256).
//
// Functions (>= 20):
// Core Interaction & State Management:
// 1. contributeSpark(amount): User contributes Spark, gains Resonance, updates lastInteractionTime.
// 2. viewTotalSparkPooled(): Returns the total pooled Spark.
// 3. viewResonance(user): Returns the Resonance score for a user.
// 4. decayInactiveResonance(user): Triggers potential Resonance decay for an inactive user.
// 5. getTemporalStability(): Returns the current dynamic TemporalStabilityTraits.
// 6. updateTemporalStability(): Recalculates temporalStability based on totalSparkPooled (Exposed for demo).
// 7. burnSparkForTemporalBoost(amount): Burns Spark for potential boost (simplified logic).
//
// Epoch Shard NFTs (Custom ERC721 Implementation):
// 8. mintEpochShard(): Mints an Epoch Shard NFT to msg.sender, capturing current state.
// 9. getEpochShardTraits(tokenId): Returns the captured TemporalStabilityTraits for an Epoch Shard.
// 10. tokenURI(tokenId): Returns the metadata URI for an Epoch Shard.
// 11. balanceOf(owner): ERC721 standard.
// 12. ownerOf(tokenId): ERC721 standard.
// 13. transferFrom(from, to, tokenId): ERC721 standard.
// 14. safeTransferFrom(from, to, tokenId, data): ERC721 standard.
// 15. approve(to, tokenId): ERC721 standard.
// 16. getApproved(tokenId): ERC721 standard.
// 17. setApprovalForAll(operator, approved): ERC721 standard.
// 18. isApprovedForAll(owner, operator): ERC721 standard.
//
// Resonance Delegation & Governance:
// 19. delegateResonance(delegatee): Delegates voting/influence power.
// 20. getResonanceDelegate(user): Returns the delegatee address.
// 21. createProposal(description, target, value, calldata, votingPeriodSeconds): Creates a proposal (requires min Resonance).
// 22. voteOnProposal(proposalId, support): Casts a vote (up/down) using effective Resonance.
// 23. executeProposal(proposalId): Executes a passed proposal.
// 24. getProposalState(proposalId): Returns state of a proposal.
// 25. getEffectiveResonance(user): Returns user's Resonance + delegated.
//
// Admin/Utility:
// 26. withdrawSpark(amount): Owner withdraws Spark from the pool.
// 27. setResonanceDecayRate(rate): Owner sets decay rate.
// 28. setEpochShardMintCost(requiredResonance, requiredSpark): Owner sets mint costs.
// 29. setProposalCreationCost(requiredResonance): Owner sets proposal cost.
// 30. getCurrentTimestamp(): Helper to get block.timestamp.

contract ChronoforgeNexus is IERC721Receiver { // Implement receiver interface for safeTransferFrom

    address public immutable owner;

    // --- State Variables ---
    uint256 public totalSparkPooled;
    mapping(address => uint256) private resonanceScores;
    mapping(address => uint64) private lastInteractionTime; // Using uint64 for timestamps

    // Dynamic Chronoforge Traits
    struct TemporalStabilityTraits {
        uint256 harmonyLevel; // Influenced positively by Spark
        uint256 fluxLevel;    // Influenced by recent activity/burns, potentially time
        uint256 complexity;   // Influenced by cumulative contributions/events
        uint256 temporalSync; // State reflecting alignment, maybe randomness or specific events
    }
    TemporalStabilityTraits public temporalStability;

    // Epoch Shard NFT Data
    struct EpochShardData {
        uint256 tokenId;
        address creator;
        TemporalStabilityTraits capturedTraits;
        uint64 mintTimestamp;
        string metadataURI;
    }
    mapping(uint256 => EpochShardData) private epochShardData;
    uint256 private nextEpochShardId = 1; // Start token IDs from 1

    // Basic ERC721 Implementation mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Governance
    struct Proposal {
        string description;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) voted; // Track if address (or its delegatee) has voted
        bool executed;
        bool active;
        uint64 creationTimestamp;
        uint64 votingDeadline;
        address target;
        bytes calldata;
        uint256 value; // ETH to potentially send with execution
    }
    mapping(uint256 => Proposal) private proposals;
    uint256 private nextProposalId = 1; // Start proposal IDs from 1

    mapping(address => address) public resonanceDelegates; // User -> Delegatee

    // Parameters
    uint256 public resonanceDecayRate = 1; // Example: 1 point per day (adjust units)
    uint256 public epochShardMintResonanceCost = 100; // Example cost
    uint256 public epochShardMintSparkCost = 50; // Example cost to burn
    uint256 public proposalCreationResonanceCost = 500; // Example cost

    // --- Events ---
    event SparkContributed(address indexed user, uint256 amount, uint256 newTotalSpark);
    event ResonanceGained(address indexed user, uint256 amount, uint256 newResonance);
    event ResonanceDecayed(address indexed user, uint256 amount, uint256 newResonance);
    event NexusTraitsUpdated(TemporalStabilityTraits newTraits);
    event EpochShardMinted(address indexed owner, uint256 indexed tokenId, TemporalStabilityTraits traits);
    event ResonanceDelegated(address indexed delegator, address indexed delegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint64 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support); // support: true=upvote, false=downvote
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyEpochShardOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].creationTimestamp > 0, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(proposals[proposalId].active, "Proposal not active");
        require(block.timestamp <= proposals[proposalId].votingDeadline, "Voting period ended");
        _;
    }

    modifier proposalNotExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Initialize traits
        temporalStability = TemporalStabilityTraits(100, 50, 20, 0);
    }

    receive() external payable {} // Allow receiving Ether

    // --- Core Interaction & State Management ---

    /**
     * @notice Users contribute Spark to the Chronoforge.
     * @param amount The amount of Spark to contribute. Assumed to be transferred externally or pre-approved.
     *               Simplification: In a real scenario, this would involve an ERC20 transferFrom.
     *               Here, we just assume the Spark 'arrives' and update internal state.
     *               Realistically, this function might receive ETH which is converted to 'Spark power'.
     */
    function contributeSpark(uint256 amount) external {
        require(amount > 0, "Must contribute more than 0");

        // In a real scenario, call ERC20 transferFrom or handle received ETH
        // Example: ISparkToken(sparkTokenAddress).transferFrom(msg.sender, address(this), amount);

        totalSparkPooled += amount;

        // Gain Resonance based on contribution (simple linear example)
        uint256 resonanceGain = amount / 10; // Example: 10 Spark per 1 Resonance
        resonanceScores[msg.sender] += resonanceGain;

        // Update last interaction time for decay calculation
        lastInteractionTime[msg.sender] = uint64(block.timestamp);

        // Recalculate dynamic traits (can be optimized to run less frequently)
        _updateTemporalStability();

        emit SparkContributed(msg.sender, amount, totalSparkPooled);
        emit ResonanceGained(msg.sender, resonanceGain, resonanceScores[msg.sender]);
    }

    /**
     * @notice Returns the total amount of Spark currently pooled in the Chronoforge.
     */
    function viewTotalSparkPooled() external view returns (uint256) {
        return totalSparkPooled;
    }

    /**
     * @notice Returns the current Resonance score for a user.
     * @param user The address of the user.
     */
    function viewResonance(address user) external view returns (uint256) {
        // Return potentially decayed resonance
        return _calculateDecayedResonance(user);
    }

     /**
     * @notice Calculates and returns the effective Resonance for a user (self + delegated).
     * @param user The address of the user.
     */
    function getEffectiveResonance(address user) public view returns (uint256) {
        uint256 userResonance = _calculateDecayedResonance(user);
        uint256 delegatedResonance = 0;
        // This is a simplified delegation where delegatee just *uses* delegator's power.
        // A more complex system would track who delegated *to* whom.
        // For this function, we just return the user's own potentially decayed resonance.
        // Effective resonance is mostly used internally for voting/proposal checks.
        // Let's refine: This function should return the voting power *of* `user`.
        // If `user` has delegated, their own power is 0 for voting, but they might still have Resonance for minting.
        // If someone delegated *to* `user`, their power is user's own + delegated.
        // Let's implement a simple model: getEffectiveResonance(user) returns the power user *can* vote with.
        // If user has delegated, their voting power is 0 via this path. The delegatee uses getEffectiveResonance(delegatee).
        // To calculate total power *delegated TO* a user would require iterating or a different mapping.
        // Let's use the simple model: `getEffectiveResonance(user)` returns the power `user` has *for themselves* (non-delegated).
        // For voting, we will check if they have delegated and use their own power if not.
         if (resonanceDelegates[user] != address(0)) {
             // If user has delegated, their direct voting power via this check is zero
             return 0;
         }
        return userResonance;
    }


    /**
     * @notice Calculates the current resonance score including decay.
     * @param user The address of the user.
     * @return The decayed Resonance score.
     */
    function _calculateDecayedResonance(address user) private view returns (uint256) {
        uint256 currentResonance = resonanceScores[user];
        uint64 lastInteraction = lastInteractionTime[user];
        uint64 currentTime = uint64(block.timestamp);

        if (currentResonance == 0 || lastInteraction == 0 || currentTime <= lastInteraction) {
            return currentResonance;
        }

        uint64 timeElapsed = currentTime - lastInteraction;
        uint256 decayAmount = timeElapsed * resonanceDecayRate; // Simple linear decay

        return currentResonance > decayAmount ? currentResonance - decayAmount : 0;
    }

    /**
     * @notice Allows anyone to trigger Resonance decay calculation and update for a specific user.
     *         This pattern avoids needing active processes and relies on users/bots to poke.
     * @param user The address of the user whose Resonance should be checked for decay.
     */
    function decayInactiveResonance(address user) external {
        uint256 currentResonance = resonanceScores[user];
        uint64 lastInteraction = lastInteractionTime[user];
        uint64 currentTime = uint64(block.timestamp);

        if (currentResonance == 0 || lastInteraction == 0 || currentTime <= lastInteraction) {
            // No decay needed or possible
            return;
        }

        uint64 timeElapsed = currentTime - lastInteraction;
        uint256 decayAmount = timeElapsed * resonanceDecayRate;

        uint256 newResonance = currentResonance > decayAmount ? currentResonance - decayAmount : 0;
        resonanceScores[user] = newResonance;
        lastInteractionTime[user] = currentTime; // Update interaction time *after* decay

        emit ResonanceDecayed(user, currentResonance - newResonance, newResonance);
    }


    /**
     * @notice Returns the current dynamic traits of the Chronoforge.
     */
    function getTemporalStability() external view returns (TemporalStabilityTraits memory) {
        return temporalStability;
    }

    /**
     * @notice Recalculates the Chronoforge's dynamic traits.
     *         This would ideally be triggered internally by state changes or time.
     *         Exposed publicly for easier demonstration/interaction.
     */
    function updateTemporalStability() public { // Can be public/internal/onlyOwner depending on logic
        // Simple trait update logic based on total Spark pooled
        temporalStability.harmonyLevel = 100 + (totalSparkPooled / 100); // More Spark = Higher Harmony
        temporalStability.fluxLevel = 50 + (totalSparkPooled % 50); // Fluctuation based on modulo
        temporalStability.complexity = 20 + (totalSparkPooled / 500); // Cumulative effect
        temporalStability.temporalSync = uint256(uint160(address(this))) % 100; // Example: Based on contract address or block data

        // More advanced logic could involve:
        // - Time elapsed since last update
        // - Number of recent interactions/contributions
        // - Outcome of governance votes
        // - Pseudo-randomness based on block hash (careful with predictability)
        // - Oracles for external data (e.g., market volatility, weather - less common for this type of contract)

        emit NexusTraitsUpdated(temporalStability);
    }

    /**
     * @notice Allows a user to burn Spark for a temporary or specific boost to traits.
     * @param amount The amount of Spark to burn.
     *         Simplification: In a real scenario, check user's Spark balance if tracked internally.
     *         Here, we just deduct from totalSparkPooled and apply a simple effect.
     */
    function burnSparkForTemporalBoost(uint256 amount) external {
         require(amount > 0, "Must burn more than 0");
         require(totalSparkPooled >= amount, "Not enough pooled Spark to burn");

        totalSparkPooled -= amount;

        // Apply boost effect (example)
        temporalStability.fluxLevel += amount / 5; // Burning increases flux temporarily?
        temporalStability.temporalSync += amount / 20; // Burning influences sync?
        // This effect would ideally be time-limited or require more complex state variables.

        lastInteractionTime[msg.sender] = uint64(block.timestamp); // Counts as interaction

        // Recalculate dynamic traits after burn
        _updateTemporalStability();

        // No specific burn event, maybe log as part of SparkContributed or a new event
        emit SparkContributed(msg.sender, amount, totalSparkPooled); // Could reuse, negative implies burning/reduction conceptually
        emit NexusTraitsUpdated(temporalStability);
    }


    // --- Epoch Shard NFTs (Custom ERC721 Implementation) ---

    /**
     * @notice Mints a new Epoch Shard NFT to the caller, capturing the current Chronoforge state.
     * @dev Requires minimum Resonance and burns Spark.
     */
    function mintEpochShard() external {
        address minter = msg.sender;
        uint256 currentResonance = _calculateDecayedResonance(minter);

        require(currentResonance >= epochShardMintResonanceCost, "Not enough Resonance to mint");
        require(totalSparkPooled >= epochShardMintSparkCost, "Not enough pooled Spark to mint");

        // Deduct Resonance (optional, but adds cost)
        resonanceScores[minter] -= epochShardMintResonanceCost;
         // Ensure decay is calculated *before* deduction if decay is significant
        resonanceScores[minter] = _calculateDecayedResonance(minter); // Recalculate before deducting
        resonanceScores[minter] -= epochShardMintResonanceCost;

        // Burn Spark
        totalSparkPooled -= epochShardMintSparkCost;

        // Update interaction time
        lastInteractionTime[minter] = uint64(block.timestamp);


        uint256 tokenId = nextEpochShardId++;
        EpochShardData memory newShard = EpochShardData({
            tokenId: tokenId,
            creator: minter,
            capturedTraits: temporalStability, // Capture the *current* state
            mintTimestamp: uint64(block.timestamp),
            metadataURI: string(abi.encodePacked("ipfs://some_placeholder_uri/", Strings.toString(tokenId))) // Placeholder URI
        });

        epochShardData[tokenId] = newShard;

        // ERC721 standard minting
        _safeMint(minter, tokenId);

        // Update dynamic traits after minting costs (Spark burn)
        _updateTemporalStability();

        emit EpochShardMinted(minter, tokenId, newShard.capturedTraits);
    }

    /**
     * @notice Returns the captured TemporalStabilityTraits for a specific Epoch Shard NFT.
     * @param tokenId The ID of the Epoch Shard NFT.
     */
    function getEpochShardTraits(uint256 tokenId) external view returns (TemporalStabilityTraits memory) {
        require(epochShardData[tokenId].mintTimestamp > 0, "Invalid Token ID"); // Check if token exists
        return epochShardData[tokenId].capturedTraits;
    }

    /**
     * @notice Returns the metadata URI for a specific Epoch Shard NFT. (ERC721 standard)
     * @param tokenId The ID of the Epoch Shard NFT.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
         require(epochShardData[tokenId].mintTimestamp > 0, "Invalid Token ID");
        return epochShardData[tokenId].metadataURI;
    }

    // --- Basic ERC721 Implementation ---

    // Internal mint helper (assumes ERC721 _safeMint logic)
    function _safeMint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to zero address");
        require(_owners[tokenId] == address(0), "Token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        // Check if 'to' is a contract and implements ERC721Receiver.onERC721Received
        // This is a simplified check, a full implementation needs IERC721Receiver
        uint size;
        assembly { size := extcodesize(to) }
        if (size > 0) {
             try IERC721Receiver(to).onERC721Received(msg.sender, address(0), tokenId, "") returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "ERC721: transfer to non ERC721Receiver implementer");
            } catch {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }

        emit Transfer(address(0), to, tokenId); // ERC721 Transfer event (from zero address for minting)
    }


    // Required ERC721 functions
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Balance query for zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for non-existent token");
        return owner_;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
         _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }


    function approve(address to, uint256 tokenId) public virtual {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");

        require(
            _msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    // Internal ERC721 helpers
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

     function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

     function _setApprovalForAll(address owner_, address operator, bool approved) internal virtual {
        require(owner_ != operator, "ERC721: approve to caller");
        _operatorApprovals[owner_][operator] = approved;
        emit ApprovalForAll(owner_, operator, approved);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approval for the token being transferred
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true; // Transfer to non-contract address is always safe from receiver perspective
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner_, spender));
    }


    // ERC721 Events (required by standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Resonance Delegation & Governance ---

    /**
     * @notice Delegates the caller's Resonance voting power to another address.
     * @param delegatee The address to delegate Resonance to. Address(0) to undelelegate.
     */
    function delegateResonance(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to self");
        resonanceDelegates[msg.sender] = delegatee;
        emit ResonanceDelegated(msg.sender, delegatee);
    }

    /**
     * @notice Returns the address a user has delegated their Resonance to.
     * @param user The address to check delegation for.
     */
    function getResonanceDelegate(address user) external view returns (address) {
        return resonanceDelegates[user];
    }

    /**
     * @notice Creates a new governance proposal.
     * @dev Requires minimum Resonance.
     * @param description A brief description of the proposal.
     * @param target The address of the contract to call if the proposal passes.
     * @param value The amount of Ether (in wei) to send with the execution call.
     * @param calldata The data to send with the execution call (function call).
     * @param votingPeriodSeconds The duration of the voting period in seconds.
     */
    function createProposal(string memory description, address target, uint256 value, bytes memory calldata, uint64 votingPeriodSeconds) external returns (uint256 proposalId) {
        uint256 effectiveResonance = _calculateDecayedResonance(msg.sender); // Check personal resonance for creation
        require(effectiveResonance >= proposalCreationResonanceCost, "Not enough Resonance to create proposal");
         require(target != address(0), "Target address cannot be zero");

        proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.description = description;
        proposal.creationTimestamp = uint64(block.timestamp);
        proposal.votingDeadline = uint64(block.timestamp) + votingPeriodSeconds;
        proposal.target = target;
        proposal.value = value;
        proposal.calldata = calldata;
        proposal.active = true;
        proposal.executed = false; // Redundant due to default, but explicit

        // Update interaction time for creator
        lastInteractionTime[msg.sender] = uint64(block.timestamp);


        emit ProposalCreated(proposalId, msg.sender, description, proposal.votingDeadline);
    }

    /**
     * @notice Casts a vote on an active proposal.
     * @dev Uses effective Resonance (self or delegated).
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for upvote, false for downvote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external proposalExists(proposalId) proposalActive(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        address voter = msg.sender;
        // Resolve delegatee: If user delegated, their vote comes from the delegatee's address
        address effectiveVoter = resonanceDelegates[voter] != address(0) ? resonanceDelegates[voter] : voter;

        require(!proposal.voted[effectiveVoter], "Already voted on this proposal");

        // Get the voting power of the effective voter
        uint256 votingPower = _calculateDecayedResonance(effectiveVoter); // Use delegatee's resonance if delegated

        require(votingPower > 0, "No voting power (0 Resonance)");

        if (support) {
            proposal.upvotes += votingPower;
        } else {
            proposal.downvotes += votingPower;
        }

        proposal.voted[effectiveVoter] = true; // Mark the *effective* voter as having voted

        // Update interaction time for the *original* voter (the msg.sender)
        lastInteractionTime[msg.sender] = uint64(block.timestamp);

        emit Voted(proposalId, voter, support);
    }

    /**
     * @notice Executes a proposal that has passed its voting period and hasn't been executed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external proposalExists(proposalId) proposalNotExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.votingDeadline, "Voting period is not over");
        require(proposal.active, "Proposal is not active"); // Should be active if not executed and period over? Recheck logic or state.
        proposal.active = false; // Mark as inactive once execution is attempted

        // Simple majority requirement: More upvotes than downvotes
        // More complex logic could require a minimum quorum or percentage
        bool passed = proposal.upvotes > proposal.downvotes;

        if (passed) {
            // Execute the proposal call
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldata);

            proposal.executed = true;
             emit ProposalExecuted(proposalId, success);
             require(success, "Proposal execution failed");

        } else {
             // Proposal failed, just mark as inactive/executed (failed)
             proposal.executed = true; // Mark as executed (failed execution) or use a separate flag
             emit ProposalExecuted(proposalId, false);
        }

        // Update interaction time for executor (optional, but encourages participation)
         lastInteractionTime[msg.sender] = uint64(block.timestamp);
    }

     /**
     * @notice Returns the state of a governance proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalState(uint256 proposalId) external view proposalExists(proposalId) returns (
        string memory description,
        uint256 upvotes,
        uint256 downvotes,
        bool executed,
        bool active,
        uint64 creationTimestamp,
        uint64 votingDeadline,
        address target,
        uint256 value // Exclude calldata for gas/complexity
    ) {
        Proposal storage proposal = proposals[proposalId];
        active = proposal.active && block.timestamp <= proposal.votingDeadline && !proposal.executed; // Calculate current active status

        return (
            proposal.description,
            proposal.upvotes,
            proposal.downvotes,
            proposal.executed,
            active,
            proposal.creationTimestamp,
            proposal.votingDeadline,
            proposal.target,
            proposal.value
        );
    }

    // --- Admin/Utility ---

    /**
     * @notice Owner can withdraw pooled Spark.
     *         NOTE: This centralizes control. In a truly decentralized system,
     *         pooled Spark might be locked, burned, or managed by governance.
     * @param amount The amount of Spark to withdraw.
     */
    function withdrawSpark(uint256 amount) external onlyOwner {
        require(totalSparkPooled >= amount, "Not enough Spark to withdraw");
        totalSparkPooled -= amount;
        // In a real scenario, this would involve transferring Spark ERC20 tokens or ETH
        // Example: ISparkToken(sparkTokenAddress).transfer(owner, amount);
        // If ETH was contributed, this would be payable and transfer ETH: payable(owner).transfer(amount);
         // Assuming ETH was contributed and 'Spark' is just an internal unit:
         // payable(owner).transfer(amount); // Requires 'amount' to be in wei
         // Let's assume Spark is an internal balance for now, withdrawal implies sending ETH.
         // Need to track ETH received vs Spark internally. Or just assume this means Spark ERC20.
         // Let's simplify and assume this function simulates releasing value associated with Spark.
         // It deducts from totalSparkPooled but doesn't actually send ETH/tokens here to keep it simple.
         // A real version needs a token contract address and transfer logic or ETH accounting.

         // For this example, we'll just deduct the internal representation.
         // A more complete contract would need to track 'available ETH' or 'available Spark token balance'.
         // For demonstration, let's just deduct the internal 'Spark' count.
    }


    /**
     * @notice Owner sets the rate at which inactive Resonance decays.
     * @param rate The new decay rate (e.g., points per second).
     */
    function setResonanceDecayRate(uint256 rate) external onlyOwner {
        resonanceDecayRate = rate;
    }

    /**
     * @notice Owner sets the Resonance and Spark cost to mint an Epoch Shard NFT.
     * @param requiredResonance The minimum Resonance required.
     * @param requiredSpark The amount of Spark burned.
     */
    function setEpochShardMintCost(uint256 requiredResonance, uint256 requiredSpark) external onlyOwner {
        epochShardMintResonanceCost = requiredResonance;
        epochShardMintSparkCost = requiredSpark;
    }

     /**
     * @notice Owner sets the Resonance cost to create a governance proposal.
     * @param requiredResonance The minimum Resonance required.
     */
    function setProposalCreationCost(uint256 requiredResonance) external onlyOwner {
        proposalCreationResonanceCost = requiredResonance;
    }

    /**
     * @notice Helper function to get the current block timestamp.
     *         Useful for external tools to check timing against contract state.
     */
    function getCurrentTimestamp() external view returns (uint64) {
        return uint64(block.timestamp);
    }

    // --- IERC721Receiver implementation ---
    // Needed for safeTransferFrom to contract addresses
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        // Optional: Add logic here if this contract should receive NFTs (e.g., for wrapping, burning, etc.)
        // For this contract's concept, it primarily mints and holds its own NFTs,
        // but implementing this makes it compatible with safeTransferFrom *to* this contract.
        // By default, we allow receiving, but reject specific tokens if needed.
        // Returning the selector bytes confirms acceptance.
        return this.onERC721Received.selector;
    }
}

// Helper library for uint to string conversion (minimal implementation or use OpenZeppelin's)
// This is needed for a basic tokenURI placeholder.
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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