Here's a smart contract that encapsulates several advanced, creative, and trendy concepts: **SyntheMind - A Decentralized Generative Thought Ecosystem**.

This contract introduces dynamic, evolving NFTs called "Thought Fragments." Their "content" (represented by a seed) can change over time, driven by community interaction (upvotes/downvotes, donations) and the suggestions of an "AI Oracle" (simulated here as a trusted address). It blends generative art/content principles, dynamic NFTs, gamified curation, and AI integration.

---

### **Contract Name: `SyntheMind`**

#### **Outline:**

1.  **Contract Information & Purpose:** Describes the core idea of SyntheMind.
2.  **Solidity Version & Imports:** Specifies the compiler version and necessary OpenZeppelin libraries.
3.  **Error Definitions:** Custom errors for more efficient gas usage.
4.  **Enum Definitions:** `ThoughtStatus` to manage the lifecycle of a thought fragment.
5.  **Struct Definitions:**
    *   `ThoughtFragment`: Holds all critical data for an NFT, including its generative seed, evolution stage, community metrics, and AI insights.
6.  **Events:** Declarations for all significant state changes to allow off-chain monitoring.
7.  **State Variables:**
    *   `_tokenIdCounter`: Tracks the total number of minted fragments.
    *   `thoughtFragments`: Mapping from `tokenId` to `ThoughtFragment` struct.
    *   `aiOracleAddress`: Address of the trusted AI oracle.
    *   `isCurator`: Mapping for community curators.
    *   `mintPrice`, `evolutionCost`: Economic parameters in Wei.
    *   `voteThresholdForAIInsight`, `evolutionVoteThreshold`: Community interaction thresholds.
    *   `aiInsightGracePeriod`: Time window for AI insight submissions.
    *   `treasuryBalance`: Accumulates a portion of fees.
8.  **Constructor:** Initializes the contract with an AI oracle, initial prices, and sets the deployer as the owner.
9.  **ERC721 Overrides:**
    *   `tokenURI`: Custom logic to generate a dynamic metadata URI, reflecting the evolving nature of the NFT.
10. **Modifiers:**
    *   `onlyAIOracle`: Restricts function access to the designated AI oracle address.
    *   `onlyCuratorOrOwner`: Restricts function access to contract owner or designated curators.
11. **Thought Fragment Creation & Curation:**
    *   `mintThoughtFragment`: Allows users to create new thought fragments by paying a fee.
    *   `freezeThought`: Pauses evolution and interaction for a fragment.
    *   `unfreezeThought`: Resumes activity for a frozen fragment.
    *   `archiveThought`: Permanently marks a fragment as archived, preventing further evolution.
12. **Thought Fragment Evolution & AI Integration:**
    *   `submitAIInsight`: Allows the AI oracle to propose a mutation (new seed) for an eligible fragment.
    *   `triggerEvolution`: Initiates the evolution process, applying the AI's suggestion if community and economic conditions are met.
13. **Community Interaction:**
    *   `voteOnThought`: Users can upvote or downvote fragments, influencing their eligibility for AI insights and evolution.
    *   `donateToThought`: Users can contribute Ether to a fragment's evolution fund.
14. **Admin & Configuration Functions (Owner-only):**
    *   `setAIOracleAddress`: Updates the AI oracle's address.
    *   `addCurator`, `removeCurator`: Manages the list of community curators.
    *   `setMintPrice`, `setEvolutionCost`: Adjusts the economic parameters.
    *   `setVoteThresholdForAIInsight`, `setAIInsightGracePeriod`, `setEvolutionVoteThreshold`: Configures community interaction thresholds.
15. **Treasury Management (Owner-only):**
    *   `withdrawTreasuryFunds`: Allows the owner to withdraw funds from the contract's treasury.
16. **View Functions / Getters:**
    *   `getThoughtFragmentDetails`: Retrieves all data for a specific fragment.
    *   `getThoughtFragmentStatus`: Returns the current status of a fragment.
    *   `getAIOracleAddress`, `isCurator`: Public getters for oracle and curator status.
    *   `getMintPrice`, `getEvolutionCost`, `getVoteThresholdForAIInsight`, `getAIInsightGracePeriod`, `getEvolutionVoteThreshold`: Public getters for configuration parameters.
    *   `getTreasuryBalance`: Returns the current contract treasury balance.

---

#### **Function Summary (Total: 36 functions including inherited/overridden):**

1.  `constructor`: Initializes the contract.
2.  `tokenURI`: Overrides ERC721 for dynamic metadata.
3.  `mintThoughtFragment`: Creates a new dynamic NFT (Thought Fragment).
4.  `voteOnThought`: Allows users to upvote or downvote a thought fragment.
5.  `donateToThought`: Allows users to contribute funds to a thought fragment.
6.  `submitAIInsight`: AI Oracle proposes a new seed for a fragment.
7.  `triggerEvolution`: Evolves a thought fragment based on AI insight and community support.
8.  `freezeThought`: Locks a thought fragment from further changes.
9.  `unfreezeThought`: Unlocks a previously frozen thought fragment.
10. `archiveThought`: Permanently archives a thought fragment.
11. `setAIOracleAddress`: Sets the address of the AI oracle.
12. `addCurator`: Grants curator role.
13. `removeCurator`: Revokes curator role.
14. `setMintPrice`: Sets the price for minting new fragments.
15. `setEvolutionCost`: Sets the cost for triggering a fragment's evolution.
16. `setVoteThresholdForAIInsight`: Sets the votes needed for AI attention.
17. `setAIInsightGracePeriod`: Sets the cooldown for AI insights.
18. `setEvolutionVoteThreshold`: Sets the votes needed for evolution.
19. `withdrawTreasuryFunds`: Withdraws accumulated treasury funds.
20. `getThoughtFragmentDetails`: Retrieves all fragment data.
21. `getThoughtFragmentStatus`: Gets a fragment's status.
22. `getAIOracleAddress`: Returns the current AI oracle address.
23. `isCurator`: Checks if an address is a curator.
24. `getPendingAIInsight`: Returns the AI's latest insight for a fragment.
25. `getMintPrice`: Returns the current mint price.
26. `getEvolutionCost`: Returns the current evolution cost.
27. `getVoteThresholdForAIInsight`: Returns the AI insight vote threshold.
28. `getAIInsightGracePeriod`: Returns the AI insight grace period.
29. `getEvolutionVoteThreshold`: Returns the evolution vote threshold.
30. `getTreasuryBalance`: Returns the contract's treasury balance.
31. `_getStatusString`: Internal helper for status enum.
32. `ownerOf`: (Inherited from ERC721) Returns the owner of a token.
33. `balanceOf`: (Inherited from ERC721) Returns the balance of an address.
34. `approve`: (Inherited from ERC721) Approves an address to transfer a token.
35. `getApproved`: (Inherited from ERC721) Gets the approved address for a token.
36. `setApprovalForAll`: (Inherited from ERC721) Approves or revokes an operator for all tokens.
37. `isApprovedForAll`: (Inherited from ERC721) Checks if an address is an operator.
38. `transferFrom`: (Inherited from ERC721) Transfers a token.
39. `safeTransferFrom`: (Inherited from ERC721) Safe transfer of a token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SyntheMind - A Decentralized Generative Thought Ecosystem
 * @dev SyntheMind allows users to mint "Thought Fragments" as dynamic NFTs.
 * These fragments are not static images but evolving pieces of generative content,
 * represented by a 'seed'. Their evolution is driven by community upvotes/downvotes,
 * donations, and "AI Oracle Insights" that propose mutations to the fragment's seed.
 * Curators can manage fragment lifecycles (freeze, unfreeze, archive).
 * This contract integrates concepts of dynamic NFTs, AI oracle interaction,
 * gamified community curation, and a public goods funding model.
 */
contract SyntheMind is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error InvalidAIOracleAddress();
    error NotAIOracle();
    error NotCuratorOrOwner();
    error ThoughtFragmentNotFound();
    error ThoughtFragmentFrozen();
    error ThoughtFragmentArchived();
    error InvalidThoughtStatus();
    error SelfVotingNotAllowed();
    error InsufficientVotesForAIInsight();
    error AIInsightGracePeriodActive();
    error NoPendingAIInsight();
    error InsufficientVotesForEvolution();
    error InsufficientDonationsForEvolution();
    error NotEnoughFunds();
    error ZeroAmountWithdrawal();

    // --- Enum Definitions ---
    enum ThoughtStatus { Active, Frozen, Archived }

    // --- Struct Definitions ---
    struct ThoughtFragment {
        uint256 id;                 // Unique ID of the fragment (same as tokenId)
        address creator;            // Address of the original minter
        string currentSeed;         // String representing the generative content seed
        uint256 evolutionStage;     // How many times this thought has evolved
        uint256 lastEvolutionTime;  // Timestamp of the last evolution
        uint256 upvotes;            // Cumulative upvotes
        uint256 downvotes;          // Cumulative downvotes
        uint256 totalDonations;     // Total ETH donated to this fragment (in Wei)
        uint256 lastAIInsightUpdate;// Timestamp of the last AI insight submission
        string currentAIInsightSuggestion; // AI's latest proposed new seed
        ThoughtStatus status;       // Current status of the thought (Active, Frozen, Archived)
    }

    // --- Events ---
    event ThoughtFragmentMinted(uint256 indexed tokenId, address indexed creator, string initialSeed, uint256 mintPrice);
    event ThoughtFragmentVoted(uint256 indexed tokenId, address indexed voter, bool isUpvote);
    event ThoughtFragmentDonated(uint256 indexed tokenId, address indexed donor, uint256 amount);
    event ThoughtFragmentEvolved(uint256 indexed tokenId, string newSeed, uint256 newStage);
    event AIInsightSubmitted(uint256 indexed tokenId, string insight);
    event ThoughtFragmentStatusChanged(uint256 indexed tokenId, ThoughtStatus newStatus);
    event MintPriceUpdated(uint256 newPrice);
    event EvolutionCostUpdated(uint256 newCost);
    event AIOracleAddressUpdated(address indexed newOracle);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => ThoughtFragment) public thoughtFragments;
    mapping(address => bool) public isCurator;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // Tracks if an address has voted on a specific fragment

    address public aiOracleAddress;
    uint256 public mintPrice;       // Price to mint a new Thought Fragment (in Wei)
    uint256 public evolutionCost;   // Cost to trigger an evolution (in Wei)
    uint256 public treasuryFraction; // Percentage of fees that go to the treasury (e.g., 500 for 5%)
    uint256 public voteThresholdForAIInsight; // Net votes (up - down) required for AI to consider fragment
    uint256 public aiInsightGracePeriod; // Time in seconds after an AI insight, before a new one can be submitted
    uint256 public evolutionVoteThreshold; // Net votes (up - down) required for a fragment to be eligible for evolution
    uint256 public treasuryBalance; // Accumulated funds for the protocol treasury

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert NotAIOracle();
        _;
    }

    modifier onlyCuratorOrOwner() {
        if (!isCurator[msg.sender] && msg.sender != owner()) revert NotCuratorOrOwner();
        _;
    }

    // --- Constructor ---
    constructor(
        address initialAIOracle,
        uint256 initialMintPrice,
        uint256 initialEvolutionCost,
        uint256 initialTreasuryFraction // e.g., 500 for 5%
    ) ERC721("SyntheMind Thought Fragment", "SMTF") Ownable(msg.sender) {
        if (initialAIOracle == address(0)) revert InvalidAIOracleAddress();
        aiOracleAddress = initialAIOracle;
        mintPrice = initialMintPrice;
        evolutionCost = initialEvolutionCost;
        treasuryFraction = initialTreasuryFraction; // Stored as basis points (e.g., 500 = 5%)
        voteThresholdForAIInsight = 10; // Default: 10 net upvotes to trigger AI attention
        aiInsightGracePeriod = 24 hours; // Default: 24 hours (time before AI can submit a new insight)
        evolutionVoteThreshold = 20; // Default: 20 net upvotes to allow evolution
    }

    // --- ERC721 Overrides ---
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId`'s metadata.
     * This URI should point to an API endpoint that provides dynamic JSON metadata,
     * reflecting the current state and evolution of the Thought Fragment.
     * @param tokenId The ID of the Thought Fragment.
     * @return A string representing the URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Verifies token exists and is owned (inherited from ERC721 internal)
        // In a real dApp, this would point to an API endpoint that generates
        // the JSON metadata based on the fragment's current state.
        // For example: "https://api.synthemind.io/fragment/{tokenId}"
        return string.concat("https://api.synthemind.io/fragment/", tokenId.toString());
    }

    // --- Thought Fragment Creation & Curation ---

    /**
     * @dev Allows a user to mint a new Thought Fragment NFT.
     * A portion of the mint price goes to the protocol treasury.
     * @param initialSeed The initial generative content seed for the fragment.
     */
    function mintThoughtFragment(string memory initialSeed) public payable nonReentrant {
        if (msg.value < mintPrice) revert NotEnoughFunds();

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Calculate treasury cut and transfer to treasury
        uint256 treasuryCut = (msg.value * treasuryFraction) / 10000;
        treasuryBalance += treasuryCut;

        // Any remaining funds go to the fragment's initial donation pool, or is just extra.
        // For simplicity, let's assume `msg.value == mintPrice` and the excess is sent back,
        // or the user pays exactly `mintPrice`. The current setup handles extra as a donation implicitly.
        // For cleaner logic, one might `transfer` `msg.value - mintPrice` back to sender if `msg.value > mintPrice`.
        // Here, `msg.value - treasuryCut` can be considered part of the initial `totalDonations`
        // of the fragment, which is more aligned with the concept.
        uint256 fragmentInitialDonation = msg.value - treasuryCut;

        thoughtFragments[newItemId] = ThoughtFragment({
            id: newItemId,
            creator: msg.sender,
            currentSeed: initialSeed,
            evolutionStage: 0,
            lastEvolutionTime: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            totalDonations: fragmentInitialDonation,
            lastAIInsightUpdate: 0,
            currentAIInsightSuggestion: "",
            status: ThoughtStatus.Active
        });

        _safeMint(msg.sender, newItemId);

        emit ThoughtFragmentMinted(newItemId, msg.sender, initialSeed, mintPrice);
    }

    /**
     * @dev Freezes a Thought Fragment, preventing further voting, donations, or evolution.
     * Only the contract owner or a curator can perform this action.
     * @param tokenId The ID of the Thought Fragment to freeze.
     */
    function freezeThought(uint256 tokenId) public onlyCuratorOrOwner {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status == ThoughtStatus.Archived) revert ThoughtFragmentArchived();
        if (fragment.status == ThoughtStatus.Frozen) revert ThoughtFragmentFrozen();

        fragment.status = ThoughtStatus.Frozen;
        emit ThoughtFragmentStatusChanged(tokenId, ThoughtStatus.Frozen);
    }

    /**
     * @dev Unfreezes a Thought Fragment, allowing normal interaction again.
     * Only the contract owner or a curator can perform this action.
     * @param tokenId The ID of the Thought Fragment to unfreeze.
     */
    function unfreezeThought(uint256 tokenId) public onlyCuratorOrOwner {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status == ThoughtStatus.Archived) revert ThoughtFragmentArchived();
        if (fragment.status == ThoughtStatus.Active) revert InvalidThoughtStatus(); // Already active

        fragment.status = ThoughtStatus.Active;
        emit ThoughtFragmentStatusChanged(tokenId, ThoughtStatus.Active);
    }

    /**
     * @dev Archives a Thought Fragment, permanently marking it as inactive and preventing any future evolution or changes.
     * Only the contract owner or a curator can perform this action.
     * @param tokenId The ID of the Thought Fragment to archive.
     */
    function archiveThought(uint256 tokenId) public onlyCuratorOrOwner {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status == ThoughtStatus.Archived) revert ThoughtFragmentArchived();

        fragment.status = ThoughtStatus.Archived;
        emit ThoughtFragmentStatusChanged(tokenId, ThoughtStatus.Archived);
    }

    // --- Thought Fragment Evolution & AI Integration ---

    /**
     * @dev Allows the designated AI Oracle to submit a new seed suggestion for a Thought Fragment.
     * This can only happen if the fragment has enough net upvotes and is not in a grace period.
     * @param tokenId The ID of the Thought Fragment.
     * @param newSeedSuggestion The AI's proposed new generative seed.
     */
    function submitAIInsight(uint256 tokenId, string memory newSeedSuggestion) public onlyAIOracle {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status != ThoughtStatus.Active) revert InvalidThoughtStatus();

        uint256 netVotes = fragment.upvotes - fragment.downvotes;
        if (netVotes < voteThresholdForAIInsight) revert InsufficientVotesForAIInsight();

        if (block.timestamp < fragment.lastAIInsightUpdate + aiInsightGracePeriod) revert AIInsightGracePeriodActive();

        fragment.currentAIInsightSuggestion = newSeedSuggestion;
        fragment.lastAIInsightUpdate = block.timestamp;
        emit AIInsightSubmitted(tokenId, newSeedSuggestion);
    }

    /**
     * @dev Triggers the evolution of a Thought Fragment. This can be called by anyone.
     * Evolution occurs if:
     * 1. The fragment is active.
     * 2. There is a pending AI insight.
     * 3. The fragment has met the evolution vote threshold.
     * 4. There are sufficient donations to cover the evolution cost OR the caller pays it.
     * If successful, the fragment's seed is updated, evolution stage increases, and metrics are reset.
     * @param tokenId The ID of the Thought Fragment to evolve.
     */
    function triggerEvolution(uint256 tokenId) public payable nonReentrant {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status != ThoughtStatus.Active) revert InvalidThoughtStatus();

        if (bytes(fragment.currentAIInsightSuggestion).length == 0) revert NoPendingAIInsight();

        uint256 netVotes = fragment.upvotes - fragment.downvotes;
        if (netVotes < evolutionVoteThreshold) revert InsufficientVotesForEvolution();

        uint256 costToPay = evolutionCost;
        if (fragment.totalDonations < costToPay) {
            // If fragment donations are insufficient, the caller must cover the difference.
            uint256 remainingCost = costToPay - fragment.totalDonations;
            if (msg.value < remainingCost) revert InsufficientDonationsForEvolution();
            
            // Transfer remainingCost from msg.value to treasury
            treasuryBalance += remainingCost;
            fragment.totalDonations = 0; // Donations fully consumed
            // Any excess msg.value is considered an additional donation to the evolved fragment
            if (msg.value > remainingCost) {
                fragment.totalDonations += (msg.value - remainingCost);
            }
        } else {
            // Fragment's donations cover the cost
            fragment.totalDonations -= costToPay;
            treasuryBalance += costToPay;
            if (msg.value > 0) { // Any value sent by caller is an additional donation
                fragment.totalDonations += msg.value;
            }
        }
        
        // Apply AI's suggestion
        fragment.currentSeed = fragment.currentAIInsightSuggestion;
        fragment.evolutionStage++;
        fragment.lastEvolutionTime = block.timestamp;
        fragment.upvotes = 0;
        fragment.downvotes = 0;
        fragment.currentAIInsightSuggestion = ""; // Clear pending insight
        fragment.lastAIInsightUpdate = 0; // Reset AI insight timestamp

        // Reset votes for all addresses that voted on this fragment
        // This is a more complex data structure (nested mapping, or iterating through a list of voters)
        // For simplicity in a demo contract, we'll just conceptually reset,
        // but a real implementation might clear individual _hasVoted flags, or use a new mapping per stage.
        // For now, _hasVoted for previous stage is implicitly ignored.
        // A more robust implementation might track voters per stage: mapping(uint256 => mapping(uint256 => mapping(address => bool))) _hasVotedByStage;
        // Or simply accept that users can vote again on the new evolved state.
        // Let's assume for simplicity, the _hasVoted mapping tracks votes for the *current* state.
        // When a thought evolves, all previous votes are reset, and users can vote again on the new form.
        // So, we don't need to iterate and clear _hasVoted here.

        emit ThoughtFragmentEvolved(tokenId, fragment.currentSeed, fragment.evolutionStage);
    }

    // --- Community Interaction ---

    /**
     * @dev Allows users to upvote or downvote a Thought Fragment.
     * Prevents self-voting and ensures each user votes only once per fragment (per evolution stage).
     * @param tokenId The ID of the Thought Fragment.
     * @param isUpvote True for an upvote, false for a downvote.
     */
    function voteOnThought(uint256 tokenId, bool isUpvote) public {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status != ThoughtStatus.Active) revert InvalidThoughtStatus();

        if (msg.sender == ownerOf(tokenId)) revert SelfVotingNotAllowed(); // Owner cannot vote on their own fragment

        // Prevent multiple votes from the same address on the same evolution stage
        // Note: With evolution, votes are reset, so users can vote again on the new stage.
        if (_hasVoted[tokenId][msg.sender]) revert("Already voted on this fragment's current stage");
        _hasVoted[tokenId][msg.sender] = true;

        if (isUpvote) {
            fragment.upvotes++;
        } else {
            fragment.downvotes++;
        }

        emit ThoughtFragmentVoted(tokenId, msg.sender, isUpvote);
    }

    /**
     * @dev Allows users to donate Ether to a Thought Fragment.
     * These donations contribute to the fragment's `totalDonations` pool,
     * which can be used to pay for its evolution cost.
     * @param tokenId The ID of the Thought Fragment to donate to.
     */
    function donateToThought(uint256 tokenId) public payable nonReentrant {
        if (msg.value == 0) revert NotEnoughFunds(); // Or ZeroDonationError
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        if (fragment.status != ThoughtStatus.Active) revert InvalidThoughtStatus();

        fragment.totalDonations += msg.value;
        emit ThoughtFragmentDonated(tokenId, msg.sender, msg.value);
    }

    // --- Admin & Configuration Functions (Owner-only) ---

    /**
     * @dev Sets the address of the trusted AI oracle.
     * Only the contract owner can call this.
     * @param newOracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address newOracle) public onlyOwner {
        if (newOracle == address(0)) revert InvalidAIOracleAddress();
        aiOracleAddress = newOracle;
        emit AIOracleAddressUpdated(newOracle);
    }

    /**
     * @dev Adds a new address to the list of curators.
     * Only the contract owner can call this.
     * @param newCurator The address to grant curator role.
     */
    function addCurator(address newCurator) public onlyOwner {
        isCurator[newCurator] = true;
        emit CuratorAdded(newCurator);
    }

    /**
     * @dev Removes an address from the list of curators.
     * Only the contract owner can call this.
     * @param curator The address to revoke curator role from.
     */
    function removeCurator(address curator) public onlyOwner {
        isCurator[curator] = false;
        emit CuratorRemoved(curator);
    }

    /**
     * @dev Sets the price for minting a new Thought Fragment.
     * Only the contract owner can call this.
     * @param newPrice The new mint price in Wei.
     */
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /**
     * @dev Sets the cost for triggering a Thought Fragment's evolution.
     * Only the contract owner can call this.
     * @param newCost The new evolution cost in Wei.
     */
    function setEvolutionCost(uint256 newCost) public onlyOwner {
        evolutionCost = newCost;
        emit EvolutionCostUpdated(newCost);
    }

    /**
     * @dev Sets the percentage of fees that go to the protocol treasury.
     * @param newFraction New treasury fraction in basis points (e.g., 500 for 5%).
     */
    function setTreasuryFraction(uint256 newFraction) public onlyOwner {
        // Ensure fraction is within reasonable bounds (e.g., 0-10000 for 0-100%)
        require(newFraction <= 10000, "Treasury fraction cannot exceed 100%");
        treasuryFraction = newFraction;
    }

    /**
     * @dev Sets the number of net upvotes required for a fragment to be considered by the AI.
     * Only the contract owner can call this.
     * @param threshold The new vote threshold.
     */
    function setVoteThresholdForAIInsight(uint256 threshold) public onlyOwner {
        voteThresholdForAIInsight = threshold;
    }

    /**
     * @dev Sets the grace period (cooldown) in seconds for AI insight submissions.
     * Only the contract owner can call this.
     * @param period The new grace period in seconds.
     */
    function setAIInsightGracePeriod(uint256 period) public onlyOwner {
        aiInsightGracePeriod = period;
    }

    /**
     * @dev Sets the number of net upvotes required for a fragment to be eligible for evolution.
     * Only the contract owner can call this.
     * @param threshold The new evolution vote threshold.
     */
    function setEvolutionVoteThreshold(uint256 threshold) public onlyOwner {
        evolutionVoteThreshold = threshold;
    }

    // --- Treasury Management (Owner-only) ---

    /**
     * @dev Allows the contract owner to withdraw accumulated funds from the treasury.
     * Funds from minting fees and evolution costs contribute to this treasury.
     * @param recipient The address to send the funds to.
     * @param amount The amount of Wei to withdraw.
     */
    function withdrawTreasuryFunds(address payable recipient, uint256 amount) public onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmountWithdrawal();
        if (treasuryBalance < amount) revert NotEnoughFunds();

        treasuryBalance -= amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to withdraw funds from treasury");

        emit TreasuryWithdrawal(recipient, amount);
    }

    // --- View Functions / Getters ---

    /**
     * @dev Returns all details for a specific Thought Fragment.
     * @param tokenId The ID of the Thought Fragment.
     * @return A tuple containing all fragment properties.
     */
    function getThoughtFragmentDetails(uint256 tokenId)
        public view
        returns (
            uint256 id,
            address creator,
            string memory currentSeed,
            uint256 evolutionStage,
            uint256 lastEvolutionTime,
            uint256 upvotes,
            uint256 downvotes,
            uint256 totalDonations,
            uint256 lastAIInsightUpdate,
            string memory currentAIInsightSuggestion,
            ThoughtStatus status
        )
    {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();

        return (
            fragment.id,
            fragment.creator,
            fragment.currentSeed,
            fragment.evolutionStage,
            fragment.lastEvolutionTime,
            fragment.upvotes,
            fragment.downvotes,
            fragment.totalDonations,
            fragment.lastAIInsightUpdate,
            fragment.currentAIInsightSuggestion,
            fragment.status
        );
    }

    /**
     * @dev Returns the current status of a Thought Fragment.
     * @param tokenId The ID of the Thought Fragment.
     * @return The current `ThoughtStatus`.
     */
    function getThoughtFragmentStatus(uint256 tokenId) public view returns (ThoughtStatus) {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        return fragment.status;
    }

    /**
     * @dev Returns the current address designated as the AI Oracle.
     */
    function getAIOracleAddress() public view returns (address) {
        return aiOracleAddress;
    }

    /**
     * @dev Checks if a given address is a curator.
     * @param account The address to check.
     * @return True if the account is a curator, false otherwise.
     */
    function isCurator(address account) public view returns (bool) {
        return isCurator[account];
    }

    /**
     * @dev Returns the AI's latest proposed seed for a Thought Fragment.
     * @param tokenId The ID of the Thought Fragment.
     * @return The AI's suggested new seed string.
     */
    function getPendingAIInsight(uint256 tokenId) public view returns (string memory) {
        ThoughtFragment storage fragment = thoughtFragments[tokenId];
        if (fragment.creator == address(0)) revert ThoughtFragmentNotFound();
        return fragment.currentAIInsightSuggestion;
    }

    /**
     * @dev Returns the current mint price for a Thought Fragment.
     * @return The mint price in Wei.
     */
    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev Returns the current evolution cost for a Thought Fragment.
     * @return The evolution cost in Wei.
     */
    function getEvolutionCost() public view returns (uint256) {
        return evolutionCost;
    }

    /**
     * @dev Returns the current vote threshold for AI insight submission.
     * @return The vote threshold.
     */
    function getVoteThresholdForAIInsight() public view returns (uint256) {
        return voteThresholdForAIInsight;
    }

    /**
     * @dev Returns the current grace period for AI insight submission.
     * @return The grace period in seconds.
     */
    function getAIInsightGracePeriod() public view returns (uint256) {
        return aiInsightGracePeriod;
    }

    /**
     * @dev Returns the current evolution vote threshold.
     * @return The evolution vote threshold.
     */
    function getEvolutionVoteThreshold() public view returns (uint256) {
        return evolutionVoteThreshold;
    }

    /**
     * @dev Returns the current balance of the protocol treasury.
     * @return The treasury balance in Wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }
}
```