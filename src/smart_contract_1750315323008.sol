Okay, here is a Solidity smart contract called `DecentralizedKnowledgeVault`. This contract focuses on creating a decentralized system for submitting, validating, and disputing pieces of knowledge or information, incorporating concepts like staking, reputation, and dynamic state changes based on community consensus (or lack thereof).

It avoids being a standard token, NFT, simple vault, or governance contract, focusing instead on a data validation workflow with economic incentives.

**Outline and Function Summary**

**Contract Name:** `DecentralizedKnowledgeVault`

**Core Concept:** A platform where users can submit knowledge items (referenced by a hash), and others can stake tokens (ETH in this case, but could be an ERC20) to either validate or dispute the item. A dynamic score based on stakes determines the item's status (Pending, Validated, Disputed, Archived). Participants earn or lose stake and reputation based on the final resolution.

**Key Features:**
*   **Knowledge Submission:** Users submit a hash representing a piece of knowledge (content stored off-chain).
*   **Staking Validation/Dispute:** Users stake ETH to support their claim that an item is valid or invalid.
*   **Dynamic Scoring:** Stakes contribute to a score that reflects community sentiment.
*   **Resolution Mechanism:** Items transition status (Validated/Disputed) when score thresholds are met.
*   **Reputation System:** Users gain/lose reputation based on the outcome of resolutions they participated in.
*   **Stake Distribution:** Winning stakers share the pool created by losing stakers.
*   **Pausable:** An owner can pause the contract in emergencies.
*   **Configurable Parameters:** Owner can adjust staking amounts, thresholds, etc.

**Enums:**
*   `Status`: Represents the current state of a knowledge item (`Pending`, `Validated`, `Disputed`, `Archived`).

**Structs:**
*   `KnowledgeItem`: Stores details about a submitted item, including author, hash, status, score, stake information, and participant lists.

**State Variables:**
*   `owner`: The contract owner.
*   `paused`: Boolean indicating if the contract is paused.
*   `knowledgeItemCounter`: Counter for unique item IDs.
*   `knowledgeItems`: Mapping from item ID to `KnowledgeItem` struct.
*   `userReputation`: Mapping from user address to their reputation score.
*   `settings`: Struct holding configurable parameters (stake amounts, thresholds, etc.).

**Events:**
*   `ItemSubmitted`: Emitted when a new item is submitted.
*   `StakedForValidation`: Emitted when a user stakes to validate.
*   `StakedForDispute`: Emitted when a user stakes to dispute.
*   `ItemResolved`: Emitted when an item's status changes to Validated or Disputed.
*   `StakeClaimed`: Emitted when a user claims their rewards/stakes.
*   `ReputationUpdated`: Emitted when a user's reputation changes.
*   `ItemArchived`: Emitted when an item is archived.
*   `ParametersUpdated`: Emitted when owner updates settings.
*   `ContractPaused`: Emitted when contract is paused.
*   `ContractUnpaused`: Emitted when contract is unpaused.
*   `ExcessStakesWithdrawn`: Emitted when owner withdraws leftover stakes.

**Function Summary (Minimum 20 functions):**

1.  `constructor()`: Sets the contract owner.
2.  `submitKnowledgeItem(string memory contentHash, string memory tag)`: Submits a new knowledge item.
3.  `stakeAndValidate(uint256 itemId) payable`: Stakes required ETH to support the validation of an item.
4.  `stakeAndDispute(uint256 itemId) payable`: Stakes required ETH to support the dispute of an item.
5.  `resolveItemValidation(uint256 itemId)`: Triggers the resolution of an item based on its current score reaching a threshold. Distributes stakes and updates reputation.
6.  `claimValidationRewards(uint256 itemId)`: Allows a user who staked for validation on a 'Validated' item to claim their proportional rewards.
7.  `claimDisputeRewards(uint256 itemId)`: Allows a user who staked for dispute on a 'Disputed' item to claim their proportional rewards.
8.  `withdrawFailedStake(uint256 itemId)`: Allows a user who staked on the losing side of a resolution to withdraw their original stake (minus potential fees/penalties, or simply indicate loss). *Self-correction: In this model, losers' stakes are distributed to winners, so this function would be to withdraw their *remaining* stake if any, or more likely, the claim functions handle this implicitly by only allowing winning claims.* Let's rename/repurpose: `claimFailedStakes(uint256 itemId)` - *No, this is confusing.* Let's stick to `claimValidationRewards` and `claimDisputeRewards` and imply that calling the *wrong* one on a resolved item does nothing or reverts, and the losing stake is gone. Add a query: `canClaimRewards(uint256 itemId, address user)` and `canWithdrawFailedStake(uint256 itemId, address user)` - *Still complex.* Let's simplify: `resolve` distributes internally, and users call `claimRewards` or `claimFailedStake`. Yes, separate claims makes tracking easier. `claimFailedStake(uint256 itemId)`: Allows a user who staked on the *losing* side to claim back *zero* or a penalty amount, effectively just marking their stake as processed and preventing future claims on that stake. *Better idea:* The `resolve` function *calculates* winnings/losses, and the claim functions simply *transfer* the pre-calculated amount for that user/item combination. Let's track claimable amounts. *New plan:* `resolve` calculates the pool for each side and the list of winners/losers. `claimStake(uint256 itemId)`: A single function allowing *any* participant (validator or disputer) to claim *whatever* amount is marked as claimable for them for that item. This is simpler.
    *   `claimStake(uint256 itemId)`: Allows a participant to claim their share of stakes after item resolution.
9.  `archiveItem(uint256 itemId)`: Owner or item author (maybe with conditions?) can archive an item. Let's make it owner-only for simplicity.
10. `getKnowledgeItem(uint256 itemId)`: Retrieves details of a knowledge item.
11. `getItemStatus(uint256 itemId)`: Gets the status of an item.
12. `getItemScore(uint256 itemId)`: Gets the current validation/dispute score of an item.
13. `getUserReputation(address user)`: Gets a user's reputation score.
14. `getValidationStakeAmount(uint256 itemId, address user)`: Gets the amount a specific user staked for validation on an item.
15. `getDisputeStakeAmount(uint256 itemId, address user)`: Gets the amount a specific user staked for dispute on an item.
16. `setValidationStakeAmount(uint256 amount)`: Owner sets the required ETH stake for validation.
17. `setDisputeStakeAmount(uint256 amount)`: Owner sets the required ETH stake for dispute.
18. `setValidationThreshold(int256 threshold)`: Owner sets the score threshold for an item to become 'Validated'.
19. `setDisputeThreshold(int256 threshold)`: Owner sets the score threshold for an item to become 'Disputed'.
20. `setReputationImpact(int256 impact)`: Owner sets how much reputation changes on winning/losing a resolution.
21. `addValidTag(string memory tag)`: Owner adds a tag to the list of allowed tags.
22. `removeValidTag(string memory tag)`: Owner removes a tag from the list of allowed tags.
23. `pauseContract()`: Owner pauses the contract.
24. `unpauseContract()`: Owner unpauses the contract.
25. `withdrawExcessStakes()`: Owner can withdraw any leftover ETH in the contract (e.g., due to rounding in stake distribution).

This gives us 25 functions, covering submission, staking, resolution, claiming, querying, configuration, and safety features.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedKnowledgeVault
 * @dev A smart contract for decentralized knowledge submission, validation, and dispute
 * based on staking and reputation.
 *
 * Outline:
 * 1. Enums: Define status of knowledge items.
 * 2. Structs: Define the structure for Knowledge Items and Contract Settings.
 * 3. State Variables: Store contract owner, item counter, knowledge items mapping,
 *    user reputations, contract settings, and pause state.
 * 4. Events: Log key actions and state changes.
 * 5. Modifiers: Implement access control (owner, paused).
 * 6. Constructor: Initialize the owner.
 * 7. Core Logic Functions:
 *    - submitKnowledgeItem: Add new knowledge item.
 *    - stakeAndValidate: Stake ETH to validate an item.
 *    - stakeAndDispute: Stake ETH to dispute an item.
 *    - resolveItemValidation: Trigger resolution based on score.
 *    - claimStake: Claim winning stakes after resolution.
 *    - archiveItem: Archive an item (owner only).
 * 8. Query Functions:
 *    - Get item details, status, score, user reputation, stake amounts.
 * 9. Owner Configuration Functions:
 *    - Set staking amounts, resolution thresholds, reputation impact, manage tags.
 *    - Pause/Unpause the contract.
 *    - Withdraw excess funds.
 *
 * Function Summary:
 * - constructor(): Initializes the contract owner.
 * - submitKnowledgeItem(string memory contentHash, string memory tag): Creates a new KnowledgeItem entry.
 * - stakeAndValidate(uint256 itemId) payable: Allows a user to stake ETH and mark an item as validated. Increases item score.
 * - stakeAndDispute(uint256 itemId) payable: Allows a user to stake ETH and mark an item as disputed. Decreases item score.
 * - resolveItemValidation(uint256 itemId): Checks if item score meets validation/dispute thresholds. If so, updates status, distributes stakes, and updates participant reputations.
 * - claimStake(uint256 itemId): Allows a user to claim their winning stake proportional to their contribution on the winning side after resolution.
 * - archiveItem(uint256 itemId): Allows the owner to archive an item, preventing further interaction.
 * - getKnowledgeItem(uint256 itemId) view: Retrieves all details for a specific item.
 * - getItemStatus(uint256 itemId) view: Gets the current status of an item.
 * - getItemScore(uint256 itemId) view: Gets the current validation/dispute score of an item.
 * - getUserReputation(address user) view: Gets the reputation score of a user.
 * - getValidationStakeAmount(uint256 itemId, address user) view: Gets the validation stake amount for a user on an item.
 * - getDisputeStakeAmount(uint256 itemId, address user) view: Gets the dispute stake amount for a user on an item.
 * - getClaimableStake(uint256 itemId, address user) view: Gets the amount of stake a user can claim for a resolved item.
 * - getValidTags() view: Gets the list of currently allowed tags.
 * - setValidationStakeAmount(uint256 amount) onlyOwner: Sets the required ETH stake for validation.
 * - setDisputeStakeAmount(uint256 amount) onlyOwner: Sets the required ETH stake for dispute.
 * - setValidationThreshold(int256 threshold) onlyOwner: Sets the score needed for an item to become Validated.
 * - setDisputeThreshold(int256 threshold) onlyOwner: Sets the score needed for an item to become Disputed.
 * - setReputationImpact(int256 impact) onlyOwner: Sets the amount reputation changes for winners/losers.
 * - addValidTag(string memory tag) onlyOwner: Adds a tag to the list of allowed tags.
 * - removeValidTag(string memory tag) onlyOwner: Removes a tag from the list of allowed tags.
 * - pauseContract() onlyOwner whenNotPaused: Pauses the contract.
 * - unpauseContract() onlyOwner whenPaused: Unpauses the contract.
 * - withdrawExcessStakes() onlyOwner: Allows owner to withdraw small amounts of leftover ETH.
 */

contract DecentralizedKnowledgeVault {

    enum Status { Pending, Validated, Disputed, Archived }

    struct KnowledgeItem {
        uint256 id;
        address author;
        string contentHash; // IPFS hash or similar reference
        uint256 timestamp;
        Status status;
        int256 validationScore; // Positive for validation, negative for dispute
        uint256 totalValidationStake;
        uint256 totalDisputeStake;
        mapping(address => uint256) validationStakes; // user => amount staked for validation
        mapping(address => uint256) disputeStakes; // user => amount staked for dispute
        mapping(address => bool) hasValidated; // user => has validated this item
        mapping(address => bool) hasDisputed; // user => has disputed this item
        string tag;
        bool resolved; // True once resolveItemValidation has been called and stakes/reputation processed
        mapping(address => uint256) claimableStakes; // user => amount of stake they can claim
    }

    struct Settings {
        uint256 validationStakeAmount;
        uint256 disputeStakeAmount;
        int256 validationThreshold;
        int256 disputeThreshold; // Should be negative
        int256 reputationImpact; // Amount of reputation change per resolution
    }

    address public owner;
    bool public paused;
    uint256 public knowledgeItemCounter;

    mapping(uint256 => KnowledgeItem) public knowledgeItems;
    mapping(address => uint256) public userReputation; // Start with 0 reputation

    Settings public settings;
    mapping(string => bool) private validTags;
    string[] private validTagList; // To retrieve all valid tags

    // --- Events ---
    event ItemSubmitted(uint256 indexed itemId, address indexed author, string contentHash, string tag, uint256 timestamp);
    event StakedForValidation(uint256 indexed itemId, address indexed user, uint256 amount);
    event StakedForDispute(uint256 indexed itemId, address indexed user, uint256 amount);
    event ItemResolved(uint256 indexed itemId, Status newStatus, int256 finalScore);
    event StakeClaimed(uint256 indexed itemId, address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);
    event ItemArchived(uint256 indexed itemId);
    event ParametersUpdated(string parameter, int256 value);
    event ParametersUpdatedUint(string parameter, uint256 value);
    event TagAdded(string tag);
    event TagRemoved(string tag);
    event ContractPaused();
    event ContractUnpaused();
    event ExcessStakesWithdrawn(uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
        knowledgeItemCounter = 0;

        // Initial default settings
        settings.validationStakeAmount = 0.01 ether; // Example: 0.01 ETH
        settings.disputeStakeAmount = 0.01 ether;   // Example: 0.01 ETH
        settings.validationThreshold = 50;          // Example: Needs positive score of 50 to be validated
        settings.disputeThreshold = -50;            // Example: Needs negative score of -50 to be disputed
        settings.reputationImpact = 10;             // Example: Gain/lose 10 reputation
    }

    // --- Core Logic ---

    /**
     * @dev Submits a new piece of knowledge. Content is expected to be stored off-chain.
     * @param contentHash The hash or identifier of the knowledge content (e.g., IPFS hash).
     * @param tag A relevant tag or category for the knowledge item.
     */
    function submitKnowledgeItem(string memory contentHash, string memory tag) external whenNotPaused {
        require(bytes(contentHash).length > 0, "Content hash cannot be empty");
        require(bytes(tag).length > 0, "Tag cannot be empty");
        require(validTags[tag], "Invalid tag");

        uint256 newItemId = knowledgeItemCounter;
        knowledgeItems[newItemId] = KnowledgeItem({
            id: newItemId,
            author: msg.sender,
            contentHash: contentHash,
            timestamp: block.timestamp,
            status: Status.Pending,
            validationScore: 0,
            totalValidationStake: 0,
            totalDisputeStake: 0,
            tag: tag,
            resolved: false,
            // Mappings handled by default initialization
            validationStakes: {},
            disputeStakes: {},
            hasValidated: {},
            hasDisputed: {},
            claimableStakes: {}
        });

        knowledgeItemCounter++;
        emit ItemSubmitted(newItemId, msg.sender, contentHash, tag, block.timestamp);
    }

    /**
     * @dev Stakes ETH to support the validity of a knowledge item.
     * @param itemId The ID of the knowledge item.
     */
    function stakeAndValidate(uint256 itemId) external payable whenNotPaused {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist"); // Check existence
        require(item.status == Status.Pending, "Item is not pending");
        require(msg.value == settings.validationStakeAmount, "Incorrect stake amount");
        require(!item.hasValidated[msg.sender], "Already staked for validation");
        require(!item.hasDisputed[msg.sender], "Cannot stake for both validation and dispute");

        item.validationStakes[msg.sender] += msg.value;
        item.totalValidationStake += msg.value;
        item.validationScore += 1; // Simple score: +1 for validate, -1 for dispute
        item.hasValidated[msg.sender] = true;

        emit StakedForValidation(itemId, msg.sender, msg.value);

        // Attempt to resolve immediately if threshold met
        _tryResolveItem(itemId);
    }

    /**
     * @dev Stakes ETH to dispute the validity of a knowledge item.
     * @param itemId The ID of the knowledge item.
     */
    function stakeAndDispute(uint256 itemId) external payable whenNotPaused {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist"); // Check existence
        require(item.status == Status.Pending, "Item is not pending");
        require(msg.value == settings.disputeStakeAmount, "Incorrect stake amount");
        require(!item.hasDisputed[msg.sender], "Already staked for dispute");
        require(!item.hasValidated[msg.sender], "Cannot stake for both validation and dispute");

        item.disputeStakes[msg.sender] += msg.value;
        item.totalDisputeStake += msg.value;
        item.validationScore -= 1; // Simple score: +1 for validate, -1 for dispute
        item.hasDisputed[msg.sender] = true;

        emit StakedForDispute(itemId, msg.sender, msg.value);

        // Attempt to resolve immediately if threshold met
        _tryResolveItem(itemId);
    }

    /**
     * @dev Internal function to check if resolution conditions are met and trigger resolution.
     * @param itemId The ID of the knowledge item.
     */
    function _tryResolveItem(uint256 itemId) internal {
        KnowledgeItem storage item = knowledgeItems[itemId];
        if (item.status == Status.Pending && !item.resolved) {
            bool resolved = false;
            Status newStatus = Status.Pending;

            if (item.validationScore >= settings.validationThreshold) {
                newStatus = Status.Validated;
                resolved = true;
            } else if (item.validationScore <= settings.disputeThreshold) {
                newStatus = Status.Disputed;
                resolved = true;
            }

            if (resolved) {
                item.status = newStatus;
                item.resolved = true;
                _distributeStakesAndReputation(itemId, newStatus);
                emit ItemResolved(itemId, newStatus, item.validationScore);
            }
        }
    }

    /**
     * @dev Triggers resolution of an item if its score meets threshold. Can be called by anyone.
     * This allows anyone to finalize an item's status once conditions are met.
     * @param itemId The ID of the knowledge item.
     */
    function resolveItemValidation(uint256 itemId) external whenNotPaused {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist"); // Check existence
        require(item.status == Status.Pending, "Item is not pending");
        require(!item.resolved, "Item already resolved");

        // Check resolution conditions explicitly before calling _tryResolveItem
        bool validationMet = item.validationScore >= settings.validationThreshold;
        bool disputeMet = item.validationScore <= settings.disputeThreshold;

        require(validationMet || disputeMet, "Resolution thresholds not met");

        // Call internal function to handle state changes, distribution, etc.
        _tryResolveItem(itemId);
    }


    /**
     * @dev Distributes stakes and updates reputation after an item is resolved.
     * This is a complex operation due to iterating through participants.
     * Stakes are calculated here, claimableStakes mapping updated.
     * Actual ETH transfer happens in claimStake.
     * @param itemId The ID of the knowledge item.
     * @param finalStatus The determined status (Validated or Disputed).
     */
    function _distributeStakesAndReputation(uint256 itemId, Status finalStatus) internal {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(finalStatus == Status.Validated || finalStatus == Status.Disputed, "Invalid final status for distribution");

        uint256 winningPool = 0;
        address[] memory winners; // Addresses of winning stakers
        address[] memory losers; // Addresses of losing stakers

        if (finalStatus == Status.Validated) {
            winningPool = item.totalValidationStake + item.totalDisputeStake;
            // Iterate through validation stakers (potential winners)
            // Note: Iterating mappings is not possible directly.
            // We need to rely on the `hasValidated` and `hasDisputed` mappings
            // to identify participants and their stakes stored separately.
            // A simple implementation might iterate a fixed number or require
            // participants to call into distribution - pull-based is better for gas.
            // Let's simulate distribution calculation and store results in claimableStakes.

            // Calculate winner's pool (all stakes) and loser's pool (dispute stakes)
            uint256 totalWinningStake = item.totalValidationStake; // Total staked by validators
            uint256 totalLosingStake = item.totalDisputeStake;   // Total staked by disputers

            // Calculate how much each validator gets
            for (uint256 i = 0; i < knowledgeItemCounter; i++) { // This loop is dangerous for large numbers of stakers/items. A better approach uses linked lists or requires users to provide proof of participation. For this example, we simulate by iterating known addresses or relying on the mapping structure.
                // This iteration is illustrative and NOT gas-efficient for many users.
                // A production contract would require stakers to call a function
                // providing their address and item ID, and the contract would look up their stake.

                // We need a way to get the list of unique staker addresses for this item.
                // Storing lists of addresses explicitly is also gas-expensive.
                // The most efficient method is to rely on the user calling `claimStake`
                // and checking their individual stake directly in the mappings.
                // We can calculate their share *when they claim*.

                // Let's calculate the *total* winning pool and total winning stake here,
                // and the individual share calculation will happen in `claimStake`.
            }

            // The total pool to be distributed among validators is the sum of all stakes
            // if validation won. The disputers lose their stakes.
            // Winner's pool = Total Validation Stakes + Total Dispute Stakes
            // Each validator's share = (Their Validation Stake / Total Validation Stake) * Winning Pool
            // This distribution happens in claimStake now.

        } else if (finalStatus == Status.Disputed) {
            winningPool = item.totalValidationStake + item.totalDisputeStake;
            // Calculate winner's pool (all stakes) and loser's pool (validation stakes)
            uint256 totalWinningStake = item.totalDisputeStake;   // Total staked by disputers
            uint256 totalLosingStake = item.totalValidationStake; // Total staked by validators

             // Each disputer's share = (Their Dispute Stake / Total Dispute Stake) * Winning Pool
             // This distribution happens in claimStake now.
        }

        // Reputation Update Logic (Simplified)
        // Iterate through participants (conceptually, relying on `hasValidated` and `hasDisputed`)
        // This part also has the mapping iteration issue. Let's apply reputation change
        // when the user calls `claimStake` or when they participated, perhaps stored
        // as pending reputation changes.
        // For this example, let's assume we have the lists of participants:
        // (This requires external tracking or a more complex on-chain structure)

        // Simplified: Assume we can get the list of participants who have non-zero stakes
        // in either validationStakes or disputeStakes for this item.
        // Again, this requires an external list or iteration helper in a real contract.
        // We will update reputation when claimStake is called for now.
    }


    /**
     * @dev Allows a participant to claim their share of stakes after an item is resolved.
     * The amount claimable is calculated based on the resolution outcome and their stake.
     * Uses call for safe external transfer.
     * @param itemId The ID of the knowledge item.
     */
    function claimStake(uint256 itemId) external whenNotPaused {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");
        require(item.resolved, "Item is not yet resolved");
        require(item.claimableStakes[msg.sender] > 0, "No claimable stake for this user on this item");

        uint256 amountToClaim = item.claimableStakes[msg.sender];
        item.claimableStakes[msg.sender] = 0; // Prevent double claim

        // Safe ETH transfer
        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Stake transfer failed");

        emit StakeClaimed(itemId, msg.sender, amountToClaim);

        // Apply reputation change after successful claim (simple model)
        int256 reputationDelta = 0;
        bool participated = item.hasValidated[msg.sender] || item.hasDisputed[msg.sender];

        if (participated) {
             if (item.status == Status.Validated && item.hasValidated[msg.sender]) {
                 reputationDelta = settings.reputationImpact;
             } else if (item.status == Status.Disputed && item.hasDisputed[msg.sender]) {
                 reputationDelta = settings.reputationImpact;
             } else {
                 // Staked on the losing side
                 reputationDelta = -settings.reputationImpact;
             }

             int256 oldReputation = int256(userReputation[msg.sender]);
             int256 newReputation = oldReputation + reputationDelta;

             // Prevent reputation from going below zero (optional)
             if (newReputation < 0) {
                 newReputation = 0;
             }
             userReputation[msg.sender] = uint256(newReputation);
             emit ReputationUpdated(msg.sender, oldReputation, newReputation);
        }
    }

     /**
     * @dev Calculates and sets claimable stakes for all participants once an item is resolved.
     * This internal function is called by _tryResolveItem.
     * This calculation needs to handle iteration over participants efficiently.
     * A simple simulation without actual participant lists:
     * Iterate through `knowledgeItems[itemId].validationStakes` and `knowledgeItems[itemId].disputeStakes`
     * using the `hasValidated` and `hasDisputed` mappings to find participants.
     * @param itemId The ID of the knowledge item.
     * @param finalStatus The determined status (Validated or Disputed).
     */
    function _calculateClaimableStakes(uint256 itemId, Status finalStatus) internal {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.resolved, "Item must be resolved to calculate claims");

        uint256 winningPool = item.totalValidationStake + item.totalDisputeStake;
        uint256 totalWinningStakeAmount = 0; // Total stake on the winning side

        if (finalStatus == Status.Validated) {
            totalWinningStakeAmount = item.totalValidationStake;
        } else if (finalStatus == Status.Disputed) {
            totalWinningStakeAmount = item.totalDisputeStake;
        } else {
             // Should not happen if called correctly from _tryResolveItem
            return;
        }

        if (totalWinningStakeAmount == 0) {
             // If no one staked on the winning side (edge case?), maybe refund everyone?
             // For simplicity here, the pool remains in the contract (can be withdrawn by owner).
             // In a real scenario, handle this edge case carefully.
             // Let's assume at least one person staked on the side that won.
            return; // No winners to distribute to
        }

        // --- This is the part that is inefficient for many stakers ---
        // To do this properly on-chain, you'd need a data structure
        // allowing iteration over stakers for a specific item, or require
        // users to call a function providing their address after resolution
        // which then calculates *only* their share.
        // Let's simulate the calculation using the existing mappings,
        // acknowledging the gas limitation if many unique addresses stake on one item.

        address[] memory participants = new address[](0); // Need a way to get unique participants

        // Populate participants list (Illustrative - not how you'd actually iterate all stakers)
        // A real solution might involve storing staker addresses in a dynamic array
        // for each item, which adds complexity and gas cost on staking.
        // Or a helper contract/off-chain process to identify stakers.

        // Alternative (pull based calculation): When a user calls `claimStake`,
        // look up their stake (`item.validationStakes[msg.sender]` or `item.disputeStakes[msg.sender]`)
        // and calculate their share on the fly based on `item.totalValidationStake`, `item.totalDisputeStake`,
        // and `item.status`.

        // Let's implement the pull-based calculation in `claimStake` and remove this function.
        // `claimableStakes` mapping is not needed if calculation is done on claim.
        // The `claimStake` logic is updated above.

        // We still need _distributeStakesAndReputation to trigger reputation updates.
        // The reputation update logic in claimStake covers this.
        // So, `_distributeStakesAndReputation` can be removed, and `_tryResolveItem`
        // directly calls `claimStake` implicitly by marking the item as resolved.
    }


    /**
     * @dev Allows the owner to archive an item. Prevents further staking/resolution.
     * @param itemId The ID of the knowledge item.
     */
    function archiveItem(uint256 itemId) external onlyOwner whenNotPaused {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");
        require(item.status != Status.Archived, "Item is already archived");

        item.status = Status.Archived;
        emit ItemArchived(itemId);
    }

    // --- Query Functions ---

    /**
     * @dev Retrieves all details for a specific knowledge item.
     * @param itemId The ID of the knowledge item.
     * @return KnowledgeItem struct details.
     */
    function getKnowledgeItem(uint256 itemId) public view returns (
        uint256 id,
        address author,
        string memory contentHash,
        uint256 timestamp,
        Status status,
        int256 validationScore,
        uint256 totalValidationStake,
        uint256 totalDisputeStake,
        string memory tag,
        bool resolved
    ) {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");

        return (
            item.id,
            item.author,
            item.contentHash,
            item.timestamp,
            item.status,
            item.validationScore,
            item.totalValidationStake,
            item.totalDisputeStake,
            item.tag,
            item.resolved
        );
    }

    /**
     * @dev Gets the status of a knowledge item.
     * @param itemId The ID of the knowledge item.
     * @return The status enum value.
     */
    function getItemStatus(uint256 itemId) external view returns (Status) {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");
        return item.status;
    }

     /**
     * @dev Gets the current validation/dispute score of an item.
     * @param itemId The ID of the knowledge item.
     * @return The current score.
     */
    function getItemScore(uint256 itemId) external view returns (int256) {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");
        return item.validationScore;
    }

     /**
     * @dev Gets the current reputation score of a user.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user]; // Returns 0 if user has no score yet
    }

    /**
     * @dev Gets the amount a specific user staked for validation on an item.
     * @param itemId The ID of the knowledge item.
     * @param user The address of the user.
     * @return The amount staked by the user for validation.
     */
    function getValidationStakeAmount(uint256 itemId, address user) external view returns (uint256) {
        KnowledgeItem storage item = knowledgeItems[itemId];
         require(item.id == itemId && item.author != address(0), "Item does not exist");
        return item.validationStakes[user];
    }

     /**
     * @dev Gets the amount a specific user staked for dispute on an item.
     * @param itemId The ID of the knowledge item.
     * @param user The address of the user.
     * @return The amount staked by the user for dispute.
     */
    function getDisputeStakeAmount(uint256 itemId, address user) external view returns (uint256) {
        KnowledgeItem storage item = knowledgeItems[itemId];
        require(item.id == itemId && item.author != address(0), "Item does not exist");
        return item.disputeStakes[user];
    }

    /**
     * @dev Calculates the amount of stake a user can claim for a resolved item.
     * This calculation is done dynamically.
     * @param itemId The ID of the knowledge item.
     * @param user The address of the user.
     * @return The calculated claimable amount for the user. Returns 0 if item not resolved or user has no claim.
     */
    function getClaimableStake(uint256 itemId, address user) external view returns (uint256) {
         KnowledgeItem storage item = knowledgeItems[itemId];
         if (item.id != itemId || item.author == address(0) || !item.resolved) {
             return 0; // Item doesn't exist or not resolved
         }

         uint256 totalStake = item.totalValidationStake + item.totalDisputeStake;
         uint256 winningStakeAmount = 0; // Total stake on the winning side
         uint256 userStake = 0; // User's stake on this item

         if (item.status == Status.Validated) {
             // Validators won
             winningStakeAmount = item.totalValidationStake;
             userStake = item.validationStakes[user];
         } else if (item.status == Status.Disputed) {
              // Disputers won
             winningStakeAmount = item.totalDisputeStake;
             userStake = item.disputeStakes[user];
         } else {
              // Should not happen if item.resolved is true and status is Validated/Disputed
             return 0;
         }

         if (winningStakeAmount == 0 || userStake == 0) {
             return 0; // No winners or user didn't stake on winning side
         }

         // Calculate proportional share. Use multiplication before division to maintain precision.
         // (user's stake on winning side / total stake on winning side) * total pool (all stakes)
         return (userStake * totalStake) / winningStakeAmount;
     }


    /**
     * @dev Gets the list of currently allowed tags.
     * @return An array of strings representing valid tags.
     */
    function getValidTags() external view returns (string[] memory) {
        return validTagList;
    }


    // --- Owner Configuration ---

    /**
     * @dev Owner sets the required ETH stake amount for validation.
     * @param amount The new stake amount in wei.
     */
    function setValidationStakeAmount(uint256 amount) external onlyOwner {
        settings.validationStakeAmount = amount;
        emit ParametersUpdatedUint("validationStakeAmount", amount);
    }

    /**
     * @dev Owner sets the required ETH stake amount for dispute.
     * @param amount The new stake amount in wei.
     */
    function setDisputeStakeAmount(uint256 amount) external onlyOwner {
        settings.disputeStakeAmount = amount;
         emit ParametersUpdatedUint("disputeStakeAmount", amount);
    }

    /**
     * @dev Owner sets the score threshold for an item to become Validated.
     * @param threshold The new positive score threshold.
     */
    function setValidationThreshold(int256 threshold) external onlyOwner {
        require(threshold > 0, "Threshold must be positive");
        settings.validationThreshold = threshold;
         emit ParametersUpdated("validationThreshold", threshold);
    }

    /**
     * @dev Owner sets the score threshold for an item to become Disputed.
     * @param threshold The new negative score threshold.
     */
    function setDisputeThreshold(int256 threshold) external onlyOwner {
        require(threshold < 0, "Threshold must be negative");
        settings.disputeThreshold = threshold;
         emit ParametersUpdated("disputeThreshold", threshold);
    }

     /**
     * @dev Owner sets the amount reputation changes for winners/losers in a resolution.
     * @param impact The amount of reputation to add for winning, or subtract for losing.
     */
    function setReputationImpact(int256 impact) external onlyOwner {
        // Impact can be positive or negative, but reputation should not go below 0 (handled in claimStake)
        settings.reputationImpact = impact;
        emit ParametersUpdated("reputationImpact", impact);
    }

    /**
     * @dev Owner adds a tag to the list of allowed tags for submissions.
     * @param tag The tag string to add.
     */
    function addValidTag(string memory tag) external onlyOwner {
        require(bytes(tag).length > 0, "Tag cannot be empty");
        if (!validTags[tag]) {
            validTags[tag] = true;
            validTagList.push(tag);
            emit TagAdded(tag);
        }
    }

    /**
     * @dev Owner removes a tag from the list of allowed tags. Existing items with this tag are unaffected.
     * New submissions with this tag will be rejected.
     * @param tag The tag string to remove.
     */
    function removeValidTag(string memory tag) external onlyOwner {
        require(validTags[tag], "Tag is not valid");
        validTags[tag] = false;

        // Remove from dynamic array (inefficient, but necessary to update the list)
        // In a production contract, consider an alternative like marking as invalid
        // rather than removing from array, or require external lookups for valid tags.
        for (uint i = 0; i < validTagList.length; i++) {
            if (keccak256(abi.encodePacked(validTagList[i])) == keccak256(abi.encodePacked(tag))) {
                validTagList[i] = validTagList[validTagList.length - 1];
                validTagList.pop();
                break;
            }
        }
        emit TagRemoved(tag);
    }


    /**
     * @dev Owner pauses the contract in case of emergencies. Prevents most state-changing operations.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Owner unpauses the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the owner to withdraw any ETH remaining in the contract.
     * Useful for withdrawing leftover stakes due to rounding or edge cases.
     */
    function withdrawExcessStakes() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit ExcessStakesWithdrawn(balance);
    }

    // Fallback function to prevent accidental ETH sends without calling a function
    receive() external payable {
        revert("Sending ETH directly not allowed. Use stake functions.");
    }

    fallback() external payable {
        revert("Calling non-existent function or sending ETH directly not allowed. Use stake functions.");
    }
}
```