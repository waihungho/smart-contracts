Okay, let's design an interesting, advanced, and non-duplicate smart contract. How about a "Decentralized Knowledge Vault" that combines elements of staking, curation, reputation, and token rewards? Users stake tokens to submit knowledge entries, curators (also staked) review them, approved entries live in the vault, and participants earn rewards and reputation.

Here's the plan:

**Smart Contract: DecentralizedKnowledgeVault**

**Outline:**

1.  **Metadata:** Pragma, License.
2.  **Imports:** ERC20 standard interface.
3.  **Errors:** Custom errors for specific failure conditions.
4.  **Events:** Signal important state changes.
5.  **Enums:** Define possible states for knowledge entries.
6.  **Structs:** Define data structures for Knowledge Entries, User Stakes, etc.
7.  **State Variables:** Store contract configuration, data mappings, addresses, etc.
8.  **Modifiers:** Restrict function access based on roles or contract state.
9.  **Constructor:** Initialize contract with owner and required addresses.
10. **Configuration Functions:** Functions allowing governance to set parameters.
11. **Vault Token & Rewards:** Functions related to the associated ERC20 token for staking and rewards.
12. **Knowledge Management:** Functions for submitting, viewing, curating, and interacting with entries.
13. **User Management:** Functions for staking, requesting roles, managing stakes.
14. **Reputation System:** Functions to track and retrieve user reputation.
15. **Utility/View Functions:** Read-only functions to query contract state.
16. **Governance/Admin:** Basic functions for governance role (can be extended to a full DAO).
17. **Internal/Helper Functions:** Logic encapsulated for reusability.

**Function Summary:**

1.  `constructor`: Deploys the contract, setting initial owner, governance, and token addresses.
2.  `setGovernanceAddress`: Allows the current governance address to transfer governance rights.
3.  `setVaultTokenAddress`: Allows governance to set the address of the ERC20 token used for staking/rewards.
4.  `setContributionStakeAmount`: Allows governance to set the required token stake for submitting an entry.
5.  `setCurationStakeAmount`: Allows governance to set the required token stake for being a curator.
6.  `setRewardRates`: Allows governance to set reward amounts for contributors (on approval) and curators (per successful action).
7.  `setAccessFee`: Allows governance to set an ETH fee (if any) to view approved entries (optional, kept public in code for simplicity, noted as enhancement).
8.  `pauseVault`: Allows governance to pause core functionalities (submissions, curation, withdrawals).
9.  `unpauseVault`: Allows governance to unpause the vault.
10. `submitKnowledgeEntry`: Allows a user to submit a knowledge entry hash and metadata; requires staking the contribution amount.
11. `curateEntry`: Allows an assigned curator to approve or reject a pending knowledge entry. Triggers reward distribution and reputation update.
12. `getKnowledgeEntry`: View function to retrieve details of a specific knowledge entry by its ID.
13. `getEntriesByStatus`: View function to list entry IDs based on their current status (Pending, Approved, Rejected).
14. `getEntriesByCategory`: View function to list entry IDs belonging to a specific category.
15. `getEntriesByAuthor`: View function to list entry IDs submitted by a specific user.
16. `rateKnowledgeEntry`: Allows users to submit a rating (e.g., 1-5) for an approved knowledge entry.
17. `getAverageRating`: View function to calculate and retrieve the average rating for a given entry.
18. `stakeContributionTokens`: Allows a user to stake tokens required for submitting entries (user must approve token transfer first).
19. `stakeCurationTokens`: Allows a user to stake tokens required for becoming/acting as a curator (user must approve token transfer first).
20. `requestCurationRole`: Allows a user who has staked curation tokens to request the curator role.
21. `assignCurationRole`: Allows governance to assign the curator role to a requesting user.
22. `revokeCurationRole`: Allows governance to remove the curator role from a user.
23. `withdrawContributionStake`: Allows a user to withdraw their contribution stake if certain conditions are met (e.g., no pending submissions).
24. `withdrawCurationStake`: Allows a user to withdraw their curation stake if conditions are met (e.g., no longer a curator, stake not locked).
25. `claimRewards`: Allows users (contributors, curators) to claim earned tokens from the reward pool.
26. `getUserReputation`: View function to retrieve a user's current reputation score.
27. `getUserStakeInfo`: View function to retrieve a user's currently staked token amounts.
28. `depositRewardTokens`: Allows governance to deposit tokens into the contract's reward pool.
29. `getRewardPoolBalance`: View function to check the total balance of tokens available for rewards.
30. `getTotalStakedContribution`: View function to see the total amount of tokens currently staked by contributors.
31. `getTotalStakedCuration`: View function to see the total amount of tokens currently staked by curators.
32. `withdrawVaultFees`: Allows governance to withdraw any accumulated ETH or tokens (e.g., from potential access fees or unused stakes/fees from rejected entries).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable first, then transition governance

/// @title Decentralized Knowledge Vault
/// @author Your Name/Alias
/// @notice A smart contract platform for decentralized knowledge sharing, curation, and rewarding contributors/curators based on staking and reputation.
/// @dev This contract manages knowledge entries, user stakes (ERC20), a curation process, a reputation system, and token rewards.
/// @dev Governance parameters are configurable. A basic pausing mechanism is included. A full DAO governance would be a separate, interacting contract.

// Outline:
// 1. Metadata
// 2. Imports
// 3. Errors
// 4. Events
// 5. Enums
// 6. Structs
// 7. State Variables
// 8. Modifiers
// 9. Constructor
// 10. Configuration Functions
// 11. Vault Token & Rewards
// 12. Knowledge Management
// 13. User Management
// 14. Reputation System
// 15. Utility/View Functions
// 16. Governance/Admin
// 17. Internal/Helper Functions

// Function Summary:
// 1. constructor: Initialize contract with owner, governance, and token addresses.
// 2. setGovernanceAddress: Transfer governance role.
// 3. setVaultTokenAddress: Set ERC20 token address.
// 4. setContributionStakeAmount: Set required stake for submitting entries.
// 5. setCurationStakeAmount: Set required stake for curators.
// 6. setRewardRates: Set rewards for contributors/curators.
// 7. setAccessFee: Set optional ETH fee for access (currently entries are public).
// 8. pauseVault: Pause core operations.
// 9. unpauseVault: Unpause core operations.
// 10. submitKnowledgeEntry: User submits entry, requires stake.
// 11. curateEntry: Curator approves/rejects entry, triggers rewards/reputation.
// 12. getKnowledgeEntry: View entry details by ID.
// 13. getEntriesByStatus: View entries by status.
// 14. getEntriesByCategory: View entries by category.
// 15. getEntriesByAuthor: View entries by author.
// 16. rateKnowledgeEntry: User rates approved entry.
// 17. getAverageRating: View average rating for an entry.
// 18. stakeContributionTokens: User stakes tokens for contributing.
// 19. stakeCurationTokens: User stakes tokens for curating.
// 20. requestCurationRole: User requests curator role.
// 21. assignCurationRole: Governance assigns curator role.
// 22. revokeCurationRole: Governance removes curator role.
// 23. withdrawContributionStake: User withdraws contribution stake.
// 24. withdrawCurationStake: User withdraws curation stake.
// 25. claimRewards: User claims earned tokens.
// 26. getUserReputation: View user's reputation score.
// 27. getUserStakeInfo: View user's staked token amounts.
// 28. depositRewardTokens: Governance deposits tokens into reward pool.
// 29. getRewardPoolBalance: View current reward pool balance.
// 30. getTotalStakedContribution: View total tokens staked by contributors.
// 31. getTotalStakedCuration: View total tokens staked by curators.
// 32. withdrawVaultFees: Governance withdraws accumulated fees/ETH.

contract DecentralizedKnowledgeVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error InvalidStatus();
    error EntryNotFound();
    error AlreadyCurated();
    error NotPendingEntry();
    error NotApprovedEntry();
    error NotCurator();
    error InsufficientStake(uint256 requiredStake, uint256 userStake);
    error StakeLocked(string reason);
    error NoRewardsToClaim();
    error Unauthorized();
    error NoTokensDeposited();
    error TokenAddressNotSet();
    error InvalidRating();
    error AlreadyRated();
    error VaultPaused();
    error VaultNotPaused();

    // --- Events ---
    event GovernanceAddressUpdated(address indexed newGovernance);
    event VaultTokenAddressUpdated(address indexed newTokenAddress);
    event ContributionStakeAmountUpdated(uint256 newAmount);
    event CurationStakeAmountUpdated(uint256 newAmount);
    event RewardRatesUpdated(uint256 contributorRate, uint256 curatorRate);
    event AccessFeeUpdated(uint256 newFee);
    event VaultPaused(address indexed pauser);
    event VaultUnpaused(address indexed unpauser);

    event KnowledgeEntrySubmitted(uint256 indexed entryId, address indexed author, bytes32 contentHash, string category);
    event EntryCurated(uint256 indexed entryId, address indexed curator, bool approved, string reason);
    event EntryRated(uint256 indexed entryId, address indexed rater, uint8 rating);

    event StakeDeposited(address indexed user, uint256 amount, bool isContributionStake);
    event StakeWithdrawn(address indexed user, uint256 amount, bool isContributionStake);
    event CurationRoleRequested(address indexed user);
    event CurationRoleAssigned(address indexed user, address indexed assigner);
    event CurationRoleRevoked(address indexed user, address indexed revoker);

    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardPoolDeposited(address indexed depositor, uint256 amount);

    event VaultFeesWithdrawn(address indexed recipient, uint256 ethAmount, uint256 tokenAmount);

    // --- Enums ---
    enum EntryStatus { Pending, Approved, Rejected }

    // --- Structs ---
    struct KnowledgeEntry {
        uint256 id;
        address author;
        bytes32 contentHash; // Using hash to save gas, content stored off-chain (e.g., IPFS)
        string category;
        string[] tags;
        uint64 submissionTimestamp;
        EntryStatus status;
        address curator; // Curator who made the final decision
        uint64 curationTimestamp;
        string rejectionReason; // If rejected

        // Rating system
        uint256 totalRatingSum;
        uint256 ratingCount;
        mapping(address => bool) hasRated; // Prevents multiple ratings per user
    }

    struct UserStakeInfo {
        uint256 contributionStake; // Tokens staked for submitting
        uint256 curationStake;     // Tokens staked for curating
        bool isCurator;            // Whether the user is an assigned curator
        bool hasRequestedCuration; // Whether the user has an active request for curator role
    }

    // --- State Variables ---
    address public governanceAddress; // Address with administrative control
    address public vaultTokenAddress; // Address of the ERC20 token used

    uint256 public contributionStakeAmount; // Required tokens to submit an entry
    uint256 public curationStakeAmount;     // Required tokens to be a curator

    uint256 public contributorRewardRate;   // Tokens rewarded per approved entry
    uint256 public curatorRewardRate;       // Tokens rewarded per successful curation action (approve/reject)

    uint256 public accessFee; // Potential fee (in ETH) to view entries (currently entries are public)

    uint256 private _nextEntryId = 1; // Counter for unique entry IDs

    mapping(uint256 => KnowledgeEntry) public knowledgeEntries; // Entry ID to KnowledgeEntry struct
    mapping(EntryStatus => uint256[]) public entriesByStatus;   // List of entry IDs per status
    mapping(string => uint256[]) public entriesByCategory;     // List of entry IDs per category
    mapping(address => uint256[]) public entriesByAuthor;       // List of entry IDs per author

    mapping(address => UserStakeInfo) public userStakes;        // User address to StakeInfo
    mapping(address => uint256) public userReputation;          // User address to reputation score
    mapping(address => uint256) public userRewards;             // User address to unclaimed rewards

    mapping(address => bool) public pendingCurationRequests; // Users who requested curator role

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyCurator() {
        if (!userStakes[msg.sender].isCurator) {
            revert NotCurator();
        }
        _;
    }

    // Override Pausable modifiers to use custom errors
    modifier whenNotPaused() override {
        if (_paused) {
            revert VaultPaused();
        }
        _;
    }

    modifier whenPaused() override {
        if (!_paused) {
            revert VaultNotPaused();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialGovernance) Ownable(initialGovernance) Pausable() {
        governanceAddress = initialGovernance;
        // Initial parameters should be set by governance after deployment
    }

    // --- Configuration Functions (onlyGovernance) ---
    /// @notice Allows the current governance address to transfer the governance role.
    /// @param newGovernance The address to transfer the governance role to.
    function setGovernanceAddress(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance address cannot be zero");
        governanceAddress = newGovernance;
        emit GovernanceAddressUpdated(newGovernance);
        // Note: Ownable ownership remains with the original owner.
        // A full DAO would take over these functions or be the governanceAddress.
    }

    /// @notice Sets the address of the ERC20 token used for staking and rewards.
    /// @param newTokenAddress The address of the ERC20 token contract.
    function setVaultTokenAddress(address newTokenAddress) external onlyGovernance {
        require(newTokenAddress != address(0), "Token address cannot be zero");
        vaultTokenAddress = newTokenAddress;
        emit VaultTokenAddressUpdated(newTokenAddress);
    }

    /// @notice Sets the amount of tokens required to stake for submitting a knowledge entry.
    /// @param newAmount The new required contribution stake amount.
    function setContributionStakeAmount(uint256 newAmount) external onlyGovernance {
        contributionStakeAmount = newAmount;
        emit ContributionStakeAmountUpdated(newAmount);
    }

    /// @notice Sets the amount of tokens required to stake for being a curator.
    /// @param newAmount The new required curation stake amount.
    function setCurationStakeAmount(uint256 newAmount) external onlyGovernance {
        curationStakeAmount = newAmount;
        emit CurationStakeAmountUpdated(newAmount);
    }

    /// @notice Sets the reward rates for contributors and curators.
    /// @param contributorRate_ Tokens rewarded for each approved entry.
    /// @param curatorRate_ Tokens rewarded for each successful curation action.
    function setRewardRates(uint256 contributorRate_, uint256 curatorRate_) external onlyGovernance {
        contributorRewardRate = contributorRate_;
        curatorRewardRate = curatorRate_;
        emit RewardRatesUpdated(contributorRate_, curatorRate_);
    }

    /// @notice Sets an optional ETH fee to view approved entries.
    /// @param newFee The new access fee amount in wei. (Currently, knowledge is public, this is a placeholder)
    function setAccessFee(uint256 newFee) external onlyGovernance {
        accessFee = newFee;
        emit AccessFeeUpdated(newFee);
    }

    // --- Pause Functionality ---
    /// @notice Pauses core functions of the vault.
    function pauseVault() external onlyGovernance whenNotPaused {
        _pause();
        emit VaultPaused(msg.sender);
    }

    /// @notice Unpauses core functions of the vault.
    function unpauseVault() external onlyGovernance whenPaused {
        _unpause();
        emit VaultUnpaused(msg.sender);
    }

    // --- Vault Token & Rewards (Interaction with ERC20) ---

    /// @notice Allows governance to deposit tokens into the contract's reward pool.
    /// @param amount The amount of tokens to deposit.
    function depositRewardTokens(uint256 amount) external onlyGovernance {
        if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardPoolDeposited(msg.sender, amount);
    }

    /// @notice Allows users to claim their accumulated rewards.
    function claimRewards() external whenNotPaused {
        uint256 rewards = userRewards[msg.sender];
        if (rewards == 0) revert NoRewardsToClaim();
        if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();

        userRewards[msg.sender] = 0; // Clear rewards before transfer
        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Allows governance to withdraw any accumulated ETH or tokens (e.g., from fees).
    /// @dev This is a basic function; more complex fee distribution would be needed in a full system.
    function withdrawVaultFees() external onlyGovernance {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = payable(governanceAddress).call{value: ethBalance}("");
            require(success, "ETH transfer failed");
        }

        uint256 tokenBalance = 0;
        if (vaultTokenAddress != address(0)) {
             IERC20 token = IERC20(vaultTokenAddress);
             // Exclude staked and earned rewards balances
             tokenBalance = token.balanceOf(address(this));
             uint256 totalStaked = getTotalStakedContribution() + getTotalStakedCuration();
             uint256 totalRewards = 0;
             // Calculating total unclaimed rewards is complex without iterating users.
             // Assuming rewardPoolBalance includes all unclaimed rewards for simplicity here.
             // A more robust system would track rewards separately from general balance.
             // For this function, we'll withdraw everything *not* explicitly tracked as staked.
             // This is a simplification! In production, accrued fees/unclaimed rewards would be tracked differently.
             // For this example, let's just withdraw ETH and any token balance *beyond* stakes and known reward pool balance.
             // A better approach is to track *sources* of tokens (stakes, rewards pool, fees) separately.
             // Given the constraints and complexity, let's only withdraw ETH for now and rely on depositRewardTokens for tokens.
             // If fees were collected in tokens, a separate fee balance would be needed.
             tokenBalance = 0; // Simplifying: only withdraw ETH with this function.

        }


        emit VaultFeesWithdrawn(governanceAddress, ethBalance, tokenBalance);
    }


    // --- Knowledge Management ---

    /// @notice Allows a user to submit a new knowledge entry.
    /// @dev Requires the user to have staked the `contributionStakeAmount`.
    /// @param contentHash The hash of the knowledge content (e.g., IPFS CID).
    /// @param category The category the entry belongs to.
    /// @param tags A list of relevant tags for the entry.
    function submitKnowledgeEntry(bytes32 contentHash, string calldata category, string[] calldata tags) external whenNotPaused {
        if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
        if (userStakes[msg.sender].contributionStake < contributionStakeAmount) {
            revert InsufficientStake(contributionStakeAmount, userStakes[msg.sender].contributionStake);
        }

        uint256 entryId = _nextEntryId++;
        knowledgeEntries[entryId] = KnowledgeEntry({
            id: entryId,
            author: msg.sender,
            contentHash: contentHash,
            category: category,
            tags: tags,
            submissionTimestamp: uint64(block.timestamp),
            status: EntryStatus.Pending,
            curator: address(0), // Will be set upon curation
            curationTimestamp: 0,
            rejectionReason: "",
            totalRatingSum: 0,
            ratingCount: 0,
            hasRated: new mapping(address => bool)()
        });

        entriesByStatus[EntryStatus.Pending].push(entryId);
        entriesByCategory[category].push(entryId);
        entriesByAuthor[msg.sender].push(entryId);

        emit KnowledgeEntrySubmitted(entryId, msg.sender, contentHash, category);
    }

    /// @notice Allows an assigned curator to approve or reject a pending knowledge entry.
    /// @dev Triggers reward distribution and reputation updates.
    /// @param entryId The ID of the entry to curate.
    /// @param approved True to approve, False to reject.
    /// @param reason A reason for rejection (optional, required if rejecting).
    function curateEntry(uint256 entryId, bool approved, string calldata reason) external onlyCurator whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[entryId];

        if (entry.id == 0) revert EntryNotFound(); // Check if entry exists
        if (entry.status != EntryStatus.Pending) revert NotPendingEntry();

        entry.curator = msg.sender;
        entry.curationTimestamp = uint64(block.timestamp);

        if (approved) {
            entry.status = EntryStatus.Approved;
            _distributeRewards(entry.author, contributorRewardRate);
            _updateReputation(entry.author, 10); // Example points for approved contribution
            _distributeRewards(msg.sender, curatorRewardRate);
            _updateReputation(msg.sender, 5); // Example points for curator action
            // Remove from pending list (simplified: requires iterating, or use linked list)
             _removeEntryFromStatusList(entryId, EntryStatus.Pending);
             entriesByStatus[EntryStatus.Approved].push(entryId);

        } else {
            entry.status = EntryStatus.Rejected;
            entry.rejectionReason = reason;
             _distributeRewards(msg.sender, curatorRewardRate); // Curator gets reward even for rejection? Or only approval? Let's reward action.
            _updateReputation(msg.sender, 2); // Example points for curator action (less for rejection?)
             // Remove from pending list (simplified)
             _removeEntryFromStatusList(entryId, EntryStatus.Pending);
             entriesByStatus[EntryStatus.Rejected].push(entryId);
        }

        emit EntryCurated(entryId, msg.sender, approved, reason);
    }

     /// @notice Allows users to submit a rating for an approved knowledge entry.
     /// @param entryId The ID of the entry to rate.
     /// @param rating The rating value (e.g., 1 to 5).
    function rateKnowledgeEntry(uint256 entryId, uint8 rating) external whenNotPaused {
        KnowledgeEntry storage entry = knowledgeEntries[entryId];

        if (entry.id == 0) revert EntryNotFound();
        if (entry.status != EntryStatus.Approved) revert NotApprovedEntry();
        if (rating == 0 || rating > 5) revert InvalidRating(); // Example rating range
        if (entry.hasRated[msg.sender]) revert AlreadyRated();

        entry.totalRatingSum += rating;
        entry.ratingCount++;
        entry.hasRated[msg.sender] = true;

        _updateReputation(msg.sender, 1); // Example points for rating

        emit EntryRated(entryId, msg.sender, rating);
    }

    // --- User Management (Staking and Roles) ---

    /// @notice Allows a user to stake tokens required for submitting knowledge entries.
    /// @dev User must approve the vault contract to spend tokens first.
    /// @param amount The amount of tokens to stake.
    function stakeContributionTokens(uint256 amount) external whenNotPaused {
         if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
         if (amount == 0) revert NoTokensDeposited();

         IERC20 token = IERC20(vaultTokenAddress);
         token.safeTransferFrom(msg.sender, address(this), amount);

         userStakes[msg.sender].contributionStake += amount;

         emit StakeDeposited(msg.sender, amount, true);
    }

    /// @notice Allows a user to stake tokens required for being a curator.
    /// @dev User must approve the vault contract to spend tokens first.
    /// @param amount The amount of tokens to stake.
    function stakeCurationTokens(uint256 amount) external whenNotPaused {
         if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
         if (amount == 0) revert NoTokensDeposited();

         IERC20 token = IERC20(vaultTokenAddress);
         token.safeTransferFrom(msg.sender, address(this), amount);

         userStakes[msg.sender].curationStake += amount;

         emit StakeDeposited(msg.sender, amount, false);
    }


    /// @notice Allows a user who has staked curation tokens to request the curator role.
    function requestCurationRole() external whenNotPaused {
         if (userStakes[msg.sender].curationStake < curationStakeAmount) {
            revert InsufficientStake(curationStakeAmount, userStakes[msg.sender].curationStake);
        }
        // Add checks if already a curator or request pending if needed
        pendingCurationRequests[msg.sender] = true;
        emit CurationRoleRequested(msg.sender);
    }

    /// @notice Allows governance to assign the curator role to a user who requested it and meets stake requirements.
    /// @param user The address of the user to assign the role to.
    function assignCurationRole(address user) external onlyGovernance {
        if (!pendingCurationRequests[user]) revert ("No pending request"); // Custom error better
        if (userStakes[user].curationStake < curationStakeAmount) {
             revert InsufficientStake(curationStakeAmount, userStakes[user].curationStake);
        }

        userStakes[user].isCurator = true;
        pendingCurationRequests[user] = false; // Clear request after assigning
        emit CurationRoleAssigned(user, msg.sender);
    }

     /// @notice Allows governance to remove the curator role from a user.
     /// @param user The address of the user to revoke the role from.
    function revokeCurationRole(address user) external onlyGovernance {
        if (!userStakes[user].isCurator) revert ("User is not a curator"); // Custom error better
        userStakes[user].isCurator = false;
        emit CurationRoleRevoked(user, msg.sender);
    }

    /// @notice Allows a user to withdraw their contribution stake.
    /// @dev Stake may be locked if the user has pending entries.
    function withdrawContributionStake() external whenNotPaused {
        uint256 stake = userStakes[msg.sender].contributionStake;
        if (stake == 0) revert NoTokensDeposited(); // Or similar "no stake" error

        // Simple lock: check if user has any pending entries
        // A more robust system would track which specific stakes are locked by which entries
        for(uint i = 0; i < entriesByAuthor[msg.sender].length; i++) {
            if(knowledgeEntries[entriesByAuthor[msg.sender][i]].status == EntryStatus.Pending) {
                 revert StakeLocked("User has pending entries");
            }
        }

        userStakes[msg.sender].contributionStake = 0;
        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransfer(msg.sender, stake);

        emit StakeWithdrawn(msg.sender, stake, true);
    }

    /// @notice Allows a user to withdraw their curation stake.
    /// @dev Stake may be locked if the user is currently an active curator.
    function withdrawCurationStake() external whenNotPaused {
        uint256 stake = userStakes[msg.sender].curationStake;
         if (stake == 0) revert NoTokensDeposited(); // Or similar "no stake" error

        if (userStakes[msg.sender].isCurator) {
            revert StakeLocked("User is an active curator");
        }
         if (pendingCurationRequests[msg.sender]) {
             revert StakeLocked("User has pending curation request");
         }


        userStakes[msg.sender].curationStake = 0;
        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransfer(msg.sender, stake);

        emit StakeWithdrawn(msg.sender, stake, false);
    }


    // --- Reputation System ---
     /// @notice Returns the reputation score of a user.
     /// @param user The address of the user.
     /// @return The user's reputation score.
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    // --- Utility/View Functions ---

    /// @notice Returns the details of a specific knowledge entry.
    /// @param entryId The ID of the entry.
    /// @return The KnowledgeEntry struct details. (Excluding hasRated mapping which is private)
    function getKnowledgeEntry(uint256 entryId) external view returns (
        uint256 id,
        address author,
        bytes32 contentHash,
        string memory category,
        string[] memory tags,
        uint64 submissionTimestamp,
        EntryStatus status,
        address curator,
        uint64 curationTimestamp,
        string memory rejectionReason,
        uint256 totalRatingSum,
        uint256 ratingCount
    ) {
        KnowledgeEntry storage entry = knowledgeEntries[entryId];
         if (entry.id == 0 && entryId != 0) revert EntryNotFound(); // Check only if querying non-zero ID

         id = entry.id;
         author = entry.author;
         contentHash = entry.contentHash;
         category = entry.category;
         tags = entry.tags;
         submissionTimestamp = entry.submissionTimestamp;
         status = entry.status;
         curator = entry.curator;
         curationTimestamp = entry.curationTimestamp;
         rejectionReason = entry.rejectionReason;
         totalRatingSum = entry.totalRatingSum;
         ratingCount = entry.ratingCount;
    }


    /// @notice Returns a list of entry IDs filtered by status.
    /// @param status The status to filter by (Pending, Approved, Rejected).
    /// @return An array of entry IDs.
    function getEntriesByStatus(EntryStatus status) external view returns (uint256[] memory) {
        // Basic validation
        if (uint8(status) > uint8(EntryStatus.Rejected)) revert InvalidStatus();
        return entriesByStatus[status];
    }

    /// @notice Returns a list of entry IDs filtered by category.
    /// @param category The category to filter by.
    /// @return An array of entry IDs.
    function getEntriesByCategory(string calldata category) external view returns (uint256[] memory) {
        return entriesByCategory[category];
    }

     /// @notice Returns a list of entry IDs submitted by a specific author.
     /// @param author The author's address.
     /// @return An array of entry IDs.
    function getEntriesByAuthor(address author) external view returns (uint256[] memory) {
        return entriesByAuthor[author];
    }

    /// @notice Returns the average rating for an approved knowledge entry.
    /// @param entryId The ID of the entry.
    /// @return The average rating (multiplied by 100 for precision). Returns 0 if no ratings.
    function getAverageRating(uint256 entryId) external view returns (uint256) {
        KnowledgeEntry storage entry = knowledgeEntries[entryId];
         if (entry.id == 0) revert EntryNotFound();
         if (entry.ratingCount == 0) return 0;
        return (entry.totalRatingSum * 100) / entry.ratingCount; // Return average * 100 for 2 decimal places
    }

    /// @notice Returns the staking information for a specific user.
    /// @param user The address of the user.
    /// @return contributionStake, curationStake, isCurator status, hasRequestedCuration status.
    function getUserStakeInfo(address user) external view returns (uint256 contributionStake, uint256 curationStake, bool isCurator, bool hasRequestedCuration) {
        UserStakeInfo storage info = userStakes[user];
        return (info.contributionStake, info.curationStake, info.isCurator, pendingCurationRequests[user]);
    }

     /// @notice Returns the current balance of tokens available in the reward pool.
     /// @return The balance of the VaultToken held by the contract that isn't currently staked.
     function getRewardPoolBalance() external view returns (uint256) {
         if (vaultTokenAddress == address(0)) return 0;
         IERC20 token = IERC20(vaultTokenAddress);
         uint256 totalContractBalance = token.balanceOf(address(this));
         uint256 totalStaked = getTotalStakedContribution() + getTotalStakedCuration();
         // This assumes all non-staked balance is for rewards.
         // A more accurate system would track the reward pool balance separately.
         return totalContractBalance >= totalStaked ? totalContractBalance - totalStaked : 0;
     }

     /// @notice Returns the total amount of tokens currently staked by contributors.
     /// @return The sum of all contribution stakes.
     function getTotalStakedContribution() public view returns (uint256) {
        // This is difficult to calculate accurately and efficiently without iterating
        // all users in Solidity. A common pattern is to update a global counter
        // on each stake/unstake action. Let's add a counter.
        // For now, returning 0 as placeholder or requires iterating userStakes mapping keys, which is bad practice.
        // Adding a counter is necessary for a real implementation.
        // Placeholder: Summing up requires iterating userStakes mapping, which is NOT gas-efficient.
        // For this example, let's simulate or return 0 and note this limitation.
        // Let's add state variables for totals and update them.
        return _totalStakedContribution;
     }

      /// @notice Returns the total amount of tokens currently staked by curators.
     /// @return The sum of all curation stakes.
      function getTotalStakedCuration() public view returns (uint256) {
        // Placeholder: Summing up requires iterating userStakes mapping, which is NOT gas-efficient.
        // For this example, let's simulate or return 0 and note this limitation.
         // Adding a counter is necessary for a real implementation.
         return _totalStakedCuration;
     }

    // Internal counters for total staked amounts (added for getTotalStaked functions)
    uint256 private _totalStakedContribution;
    uint256 private _totalStakedCuration;


    // --- Internal/Helper Functions ---

    /// @dev Internal function to distribute rewards to a user.
    /// @param user The recipient of the rewards.
    /// @param amount The amount of tokens to reward.
    function _distributeRewards(address user, uint256 amount) internal {
        if (amount > 0) {
            userRewards[user] += amount;
            // Note: Tokens are not transferred until claimRewards is called.
            emit RewardsDistributed(user, amount);
        }
    }

    /// @dev Internal function to update a user's reputation score.
    /// @param user The user whose reputation to update.
    /// @param points The number of points to add (can be negative).
    function _updateReputation(address user, int256 points) internal {
        // Prevent underflow if points are negative
        if (points < 0) {
            uint256 absPoints = uint256(-points);
            if (userReputation[user] < absPoints) {
                userReputation[user] = 0;
            } else {
                userReputation[user] -= absPoints;
            }
        } else {
             userReputation[user] += uint256(points);
        }
         // No event for reputation change to save gas, can be added if needed
    }

    /// @dev Internal helper to remove an entry ID from a status list.
    /// @param entryId The ID to remove.
    /// @param status The status list to remove from.
    /// @notice This is an O(N) operation. For large lists, a linked list pattern or
    ///         alternative storage (like mapping ID to index and swapping with last)
    ///         would be more efficient. Simplified here for clarity.
    function _removeEntryFromStatusList(uint256 entryId, EntryStatus status) internal {
        uint256[] storage entryList = entriesByStatus[status];
        for (uint i = 0; i < entryList.length; i++) {
            if (entryList[i] == entryId) {
                // Swap with the last element and pop
                entryList[i] = entryList[entryList.length - 1];
                entryList.pop();
                break; // Assuming entryId appears only once per status list
            }
        }
    }

    // Overrides for the added total stake counters in stake/withdraw functions
    // Adding these require modifying stake functions. Let's add them now.

    // --- Modified User Management Functions (with counters) ---

    /// @notice Allows a user to stake tokens required for submitting knowledge entries.
    /// @dev User must approve the vault contract to spend tokens first.
    /// @param amount The amount of tokens to stake.
    function stakeContributionTokens(uint256 amount) external whenNotPaused override {
         if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
         if (amount == 0) revert NoTokensDeposited();

         IERC20 token = IERC20(vaultTokenAddress);
         token.safeTransferFrom(msg.sender, address(this), amount);

         userStakes[msg.sender].contributionStake += amount;
         _totalStakedContribution += amount; // Update counter

         emit StakeDeposited(msg.sender, amount, true);
    }

    /// @notice Allows a user to stake tokens required for being a curator.
    /// @dev User must approve the vault contract to spend tokens first.
    /// @param amount The amount of tokens to stake.
    function stakeCurationTokens(uint256 amount) external whenNotPaused override {
         if (vaultTokenAddress == address(0)) revert TokenAddressNotSet();
         if (amount == 0) revert NoTokensDeposited();

         IERC20 token = IERC20(vaultTokenAddress);
         token.safeTransferFrom(msg.sender, address(this), amount);

         userStakes[msg.sender].curationStake += amount;
         _totalStakedCuration += amount; // Update counter

         emit StakeDeposited(msg.sender, amount, false);
    }

    /// @notice Allows a user to withdraw their contribution stake.
    /// @dev Stake may be locked if the user has pending entries.
    function withdrawContributionStake() external whenNotPaused override {
        uint256 stake = userStakes[msg.sender].contributionStake;
        if (stake == 0) revert NoTokensDeposited(); // Or similar "no stake" error

        // Simple lock: check if user has any pending entries
        for(uint i = 0; i < entriesByAuthor[msg.sender].length; i++) {
            if(knowledgeEntries[entriesByAuthor[msg.sender][i]].status == EntryStatus.Pending) {
                 revert StakeLocked("User has pending entries");
            }
        }

        userStakes[msg.sender].contributionStake = 0;
        _totalStakedContribution -= stake; // Update counter

        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransfer(msg.sender, stake);

        emit StakeWithdrawn(msg.sender, stake, true);
    }

    /// @notice Allows a user to withdraw their curation stake.
    /// @dev Stake may be locked if the user is currently an active curator.
    function withdrawCurationStake() external whenNotPaused override {
        uint256 stake = userStakes[msg.sender].curationStake;
         if (stake == 0) revert NoTokensDeposited(); // Or similar "no stake" error

        if (userStakes[msg.sender].isCurator) {
            revert StakeLocked("User is an active curator");
        }
         if (pendingCurationRequests[msg.sender]) {
             revert StakeLocked("User has pending curation request");
         }

        userStakes[msg.sender].curationStake = 0;
        _totalStakedCuration -= stake; // Update counter

        IERC20 token = IERC20(vaultTokenAddress);
        token.safeTransfer(msg.sender, stake);

        emit StakeWithdrawn(msg.sender, stake, false);
    }

    // Redefine getTotalStaked functions to use the new counters
     /// @notice Returns the total amount of tokens currently staked by contributors.
     function getTotalStakedContribution() public view override returns (uint256) {
        return _totalStakedContribution;
     }

      /// @notice Returns the total amount of tokens currently staked by curators.
      function getTotalStakedCuration() public view override returns (uint256) {
        return _totalStakedCuration;
     }

}
```