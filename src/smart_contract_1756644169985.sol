Okay, this smart contract, `DynamicReputationAccessControl (DRAC)`, is designed to implement a sophisticated and adaptable access control system based on a multi-faceted, dynamic user reputation score. It integrates on-chain activity, off-chain data via trusted oracles, and decentralized governance.

---

# DynamicReputationAccessControl (DRAC) Smart Contract

**Core Idea:**
Manages adaptive access to resources based on a dynamically calculated, multi-faceted user reputation score. Reputation is influenced by various on-chain activities, off-chain data (via oracles), and community governance. Access tiers and privileges automatically adjust based on a user's evolving reputation.

**Key Concepts:**
1.  **Multi-Factor Reputation:** Reputation is not a single, static number but a composite score derived from multiple weighted factors (e.g., activity, trust, contribution, behavior, verification).
2.  **Adaptive Access Control:** Instead of fixed roles, access tiers and associated privileges are dynamically assigned and change based on a user's current reputation score.
3.  **Reputation Decay:** Reputation scores can naturally decay over time to encourage continued positive engagement and prevent "set-it-and-forget-it" behavior.
4.  **Oracle Integration:** Trusted, registered oracles can submit signed off-chain data to influence specific reputation factors, bridging the real world with the blockchain.
5.  **Community Governance:** Users (with sufficient reputation) can propose and vote on key parameter changes (e.g., decay rate, voting quorum), fostering decentralization and community ownership.

---

## Contract Outline:

**I. State Variables & Data Structures:**
*   `ReputationFactorType`: Enum for different types of reputation factors (e.g., `ACTIVITY_SCORE`, `TRUST_SCORE`).
*   `UserProfile`: Stores a user's individual factor scores, last decay timestamp, and optional metadata URI.
*   `ReputationSource`: Defines external entities (contracts/oracles) contributing to a factor and their weight.
*   `AccessTier`: Defines tiers with minimum reputation requirements, names, and assigned privileges.
*   `Proposal` & `ProposalState`: Structures and enum for decentralized governance proposals (parameter changes).
*   Mappings for `userProfiles`, `reputationFactorSources`, `accessTiers`, `oracles`, and `proposals`.
*   Global parameters for reputation decay, voting quorum, and voting period.

**II. Modifiers:**
*   `onlyOwner()`: Restricts access to the contract owner.
*   `onlyOracle()`: Restricts access to registered oracle addresses.
*   `onlyGovernanceApproved(uint256 proposalId)`: (Placeholder) For functions requiring prior governance approval.

**III. Reputation Management Functions:**
*   Handle the calculation, updates, and decay of user reputation scores based on various factors and sources.

**IV. Access & Privilege Management Functions:**
*   Define access tiers, assign specific privileges to them, and check a user's qualification for a tier or privilege.

**V. Oracle & External Data Integration Functions:**
*   Register and revoke trusted oracles, and process signed data submissions from them to update reputation factors.

**VI. Governance & Parameter Tuning Functions:**
*   Allow eligible users to propose changes to contract parameters, vote on active proposals, and execute successful ones.

**VII. User Management & Utilities:**
*   Functions for users to register and update their metadata, owner/governance to adjust global parameters, withdraw funds, and retrieve contract metrics.

---

## Function Summary (27 Functions):

**I. Reputation Management:**
1.  `_calculateReputationScore(address user)`: Internal helper to compute a user's total aggregate reputation score.
2.  `getUserReputation(address user)`: Retrieves a user's current aggregate reputation score.
3.  `_updateReputationFactor(address user, ReputationFactorType factor, int256 valueChange)`: Internal function to adjust a specific reputation factor for a user.
4.  `addReputationFactorSource(ReputationFactorType factorType, address sourceContract, uint256 weight)`: Registers a new contract/address as a source for a specific reputation factor with a defined weight. (Owner)
5.  `updateReputationFactorSourceWeight(ReputationFactorType factorType, address sourceContract, uint256 newWeight)`: Modifies the weight of an existing reputation factor source. (Owner)
6.  `triggerReputationDecay(address user)`: Applies the reputation decay mechanism to a user's score based on time elapsed. (Callable by anyone)
7.  `getReputationFactorSources(ReputationFactorType factorType)`: (View) Placeholder to view registered sources and their weights for a given factor type.

**II. Access & Privilege Management:**
8.  `getAccessTier(address user)`: (View) Returns the current access tier ID and name for a user based on their reputation.
9.  `hasAccessPrivilege(address user, bytes32 privilegeKey)`: (View) Checks if a user possesses a specific privilege based on their access tier.
10. `defineAccessTier(uint256 tierId, uint256 minReputation, string memory tierName)`: Defines or updates an access tier, specifying its minimum reputation requirement and name. (Owner)
11. `assignPrivilegeToTier(uint256 tierId, bytes32 privilegeKey)`: Grants a specific privilege to an existing access tier. (Owner)
12. `revokePrivilegeFromTier(uint256 tierId, bytes32 privilegeKey)`: Removes a privilege from an existing access tier. (Owner)
13. `requestAccess(bytes32 resourceId)`: Simulates a user requesting access to a resource, checking their privileges internally.

**III. Oracle & External Data Integration:**
14. `submitReputationData(address user, ReputationFactorType factorType, int256 valueChange, bytes32 signature, uint256 timestamp)`: Trusted oracles submit signed data to update specific reputation factors for a user. (Only Oracle)
15. `registerOracle(address oracleAddress, string memory name)`: Adds a new address to the list of trusted oracles. (Owner)
16. `revokeOracle(address oracleAddress)`: Removes an address from the list of trusted oracles. (Owner)
17. `isOracle(address _address)`: (View) Checks if an address is a registered oracle.

**IV. Governance & Parameter Tuning:**
18. `proposeParameterChange(bytes32 paramKey, bytes memory newValue, string memory description)`: Initiates a proposal to change a key contract parameter. (Min. reputation required)
19. `voteOnProposal(uint256 proposalId, bool support)`: Allows eligible users to vote on an active proposal.
20. `executeProposal(uint256 proposalId)`: Executes a successfully voted-on proposal, applying the parameter change. (Callable by anyone)
21. `getProposalState(uint256 proposalId)`: (View) Retrieves the current state and details of a specific proposal.

**V. User Management & Utilities:**
22. `registerUser(string memory metadataURI)`: Allows a user to register themselves and associate optional metadata.
23. `updateUserMetadata(string memory newMetadataURI)`: Allows a registered user to update their associated metadata.
24. `setDecayRate(uint256 newDecayRateBasisPoints)`: Sets the global reputation decay rate. (Owner)
25. `withdrawFunds(address tokenAddress, uint256 amount)`: Allows the owner to withdraw funds (ETH or ERC20). (Owner)
26. `getContractMetrics()`: (View) Returns various high-level statistics about the contract.
27. `getAccessTierDetails(uint256 tierId)`: (View) Returns basic details of a specific access tier.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline and Function Summary
// Contract Name: DynamicReputationAccessControl (DRAC)

// Core Idea:
// Manages adaptive access to resources based on a dynamically calculated, multi-faceted user reputation score.
// Reputation is influenced by on-chain activities, off-chain data (via oracles), and community governance.
// Access tiers and privileges automatically adjust based on reputation.

// Key Concepts:
// 1. Multi-Factor Reputation: Reputation is a composite score from various weighted factors (e.g., activity, trust, contribution, verification).
// 2. Adaptive Access Control: Access tiers and associated privileges are dynamically assigned based on a user's current reputation.
// 3. Reputation Decay: Scores can decay over time to encourage continued positive engagement.
// 4. Oracle Integration: Trusted oracles submit signed off-chain data to influence specific reputation factors.
// 5. Community Governance: Users (with sufficient reputation) propose and vote on key parameter changes.

// Outline:
// I. State Variables & Data Structures: Enums, structs for users, reputation factors, access tiers, governance proposals.
// II. Modifiers: Access control for owner, oracles, and governance.
// III. Reputation Core Functions: Internal/external for calculating, updating, and managing reputation factors.
// IV. Access Control Functions: Define tiers, assign privileges, and check user access.
// V. Oracle Management: Register, revoke, and process data from trusted oracles.
// VI. Governance & Parameter Tuning: Proposing, voting, and executing parameter changes.
// VII. User Management & Utilities: User registration, metadata, contract metrics, fund withdrawal.

// Function Summary (27 Functions):

// I. Reputation Management:
// 1. _calculateReputationScore(address user): Internal helper to compute a user's total reputation.
// 2. getUserReputation(address user): Retrieves a user's current aggregate reputation score.
// 3. _updateReputationFactor(address user, ReputationFactorType factor, int256 valueChange): Internal function to adjust a specific reputation factor.
// 4. addReputationFactorSource(ReputationFactorType factorType, address sourceContract, uint256 weight): Registers a new contract as a source for a specific reputation factor, with a defined weight.
// 5. updateReputationFactorSourceWeight(ReputationFactorType factorType, address sourceContract, uint256 newWeight): Modifies the weight of an existing reputation factor source.
// 6. triggerReputationDecay(address user): Applies the reputation decay mechanism to a user's score based on time elapsed.
// 7. getReputationFactorSources(ReputationFactorType factorType): Views all registered sources and their weights for a given factor type. (Note: returns empty array, see comment in implementation)

// II. Access & Privilege Management:
// 8. getAccessTier(address user): Returns the current access tier ID and name for a user based on their reputation.
// 9. hasAccessPrivilege(address user, bytes32 privilegeKey): Checks if a user possesses a specific privilege based on their access tier.
// 10. defineAccessTier(uint256 tierId, uint256 minReputation, string memory tierName): Defines or updates an access tier, specifying its minimum reputation requirement and name.
// 11. assignPrivilegeToTier(uint256 tierId, bytes32 privilegeKey): Grants a specific privilege to an existing access tier.
// 12. revokePrivilegeFromTier(uint256 tierId, bytes32 privilegeKey): Removes a privilege from an existing access tier.
// 13. requestAccess(bytes32 resourceId): Simulates a user requesting access to a resource, which internally checks their privileges.

// III. Oracle & External Data Integration:
// 14. submitReputationData(address user, ReputationFactorType factorType, int256 valueChange, bytes32 signature, uint256 timestamp): Trusted oracles submit signed data to update specific reputation factors for a user.
// 15. registerOracle(address oracleAddress, string memory name): Adds a new address to the list of trusted oracles.
// 16. revokeOracle(address oracleAddress): Removes an address from the list of trusted oracles.
// 17. isOracle(address _address): Checks if an address is a registered oracle.

// IV. Governance & Parameter Tuning:
// 18. proposeParameterChange(bytes32 paramKey, bytes memory newValue, string memory description): Initiates a proposal to change a key contract parameter.
// 19. voteOnProposal(uint256 proposalId, bool support): Allows eligible users to vote on an active proposal.
// 20. executeProposal(uint256 proposalId): Executes a successfully voted-on proposal, applying the parameter change.
// 21. getProposalState(uint256 proposalId): Retrieves the current state and details of a specific proposal.

// V. User Management & Utilities:
// 22. registerUser(string memory metadataURI): Allows a user to register themselves and associate optional metadata.
// 23. updateUserMetadata(string memory newMetadataURI): Allows a registered user to update their associated metadata.
// 24. setDecayRate(uint256 newDecayRateBasisPoints): Sets the global reputation decay rate (basis points per unit time).
// 25. withdrawFunds(address tokenAddress, uint256 amount): Allows the owner or governance to withdraw funds (e.g., collected fees) from the contract.
// 26. getContractMetrics(): Returns various high-level statistics about the contract. (Note: some metrics are approximated, see comment)
// 27. getAccessTierDetails(uint256 tierId): Returns the details (minReputation, name, privileges) of a specific access tier. (Note: cannot return map directly, see comment)


contract DynamicReputationAccessControl {
    address public owner;

    // --- I. State Variables & Data Structures ---

    // Enum for different types of reputation factors
    enum ReputationFactorType {
        ACTIVITY_SCORE,       // On-chain activity level, e.g., using DApp, transactions
        TRUST_SCORE,          // Trust from verified entities/oracles, e.g., KYC, attestation
        CONTRIBUTION_SCORE,   // Contribution to shared resources/DAOs, e.g., project commits, moderation
        BEHAVIOR_SCORE,       // Positive/negative behaviors, e.g., good actor, spamming reports
        VERIFICATION_SCORE    // Off-chain identity verification, e.g., proof of humanity
    }

    // Struct for a user's detailed profile
    struct UserProfile {
        mapping(ReputationFactorType => int256) factors; // Individual reputation factor scores (can be negative)
        uint256 lastDecayTimestamp;                     // Timestamp of last reputation decay for this user
        string metadataURI;                             // URI to off-chain metadata (e.g., IPFS hash for profile picture, bio)
        bool registered;                                // True if the user has actively registered
    }

    // Struct for defining a source that contributes to a reputation factor
    struct ReputationSource {
        address sourceContract; // The address of the contract/entity reporting this factor (e.g., an Oracle, another DApp)
        uint256 weight;         // The weight of this source's contribution to the total factor score (basis points: 0-10000)
        bool exists;            // To distinguish from uninitialized structs in mappings
    }

    // Struct for defining access tiers
    struct AccessTier {
        uint256 minReputation;               // Minimum total reputation required for this tier
        string name;                         // Name of the tier (e.g., "Bronze", "Silver")
        mapping(bytes32 => bool) privileges; // Specific privileges assigned to this tier (keccak256 hash of privilege string)
        bool exists;                         // To distinguish from uninitialized structs
    }

    // Struct for governance proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        address proposer;               // Address that initiated the proposal
        bytes32 paramKey;               // Key identifying the parameter to change (e.g., keccak256("DECAY_RATE"))
        bytes newValue;                 // New value for the parameter, encoded as bytes
        string description;             // Description of the proposal
        uint256 startBlock;             // Block number when voting starts
        uint256 endBlock;               // Block number when voting ends
        uint256 supportVotes;           // Votes in favor
        uint256 againstVotes;           // Votes against
        mapping(address => bool) hasVoted; // Tracks who has voted on this specific proposal
        ProposalState state;            // Current state of the proposal
        uint256 minReputationToVote;    // Minimum reputation required to cast a vote on this proposal
    }

    // --- Mappings & Arrays ---
    mapping(address => UserProfile) public userProfiles;
    // (factorType => sourceAddress => ReputationSource) Stores detailed info about reputation factor contributors
    mapping(ReputationFactorType => mapping(address => ReputationSource)) public reputationFactorSources;
    mapping(uint256 => AccessTier) public accessTiers; // Tier ID => AccessTier details
    uint256[] public sortedAccessTierIds; // To efficiently retrieve access tiers by iterating in order of minReputation

    mapping(address => bool) public oracles;       // Registered oracle addresses
    mapping(address => string) public oracleNames; // Names for registered oracles
    uint256 public totalOracles;                  // Counter for registered oracles

    Proposal[] public proposals;                      // Array of all governance proposals
    uint256 public proposalVoteQuorumBasisPoints = 5000; // 50% quorum for proposals (basis points: 0-10000)
    uint256 public proposalVotingPeriodBlocks = 1000;    // Approx. 4 hours at 14s/block

    // Global parameters affecting reputation calculation
    uint256 public reputationDecayRateBasisPoints = 10; // 0.1% decay per reputationDecayIntervalSeconds (10/10000)
    uint256 public reputationDecayIntervalSeconds = 1 days; // Decay is calculated per this interval (e.g., every day)

    // --- Events ---
    event ReputationUpdated(address indexed user, ReputationFactorType indexed factor, int256 change, int256 newTotalFactorScore);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation);
    event AccessTierDefined(uint256 indexed tierId, uint256 minReputation, string name);
    event PrivilegeAssigned(uint256 indexed tierId, bytes32 privilegeKey);
    event PrivilegeRevoked(uint256 indexed tierId, bytes32 privilegeKey);
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleRevoked(address indexed oracleAddress);
    event UserRegistered(address indexed user, string metadataURI);
    event UserMetadataUpdated(address indexed user, string newMetadataURI);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(bytes32 indexed paramKey, bytes newValue);

    // --- II. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOracle() {
        require(oracles[msg.sender], "DRAC: caller is not a registered oracle");
        _;
    }

    // Modifier for functions requiring governance approval (e.g., via a successful proposal).
    // The specific logic would depend on what the proposal approved. For simplicity, this is illustrative.
    modifier onlyGovernanceApproved(uint256 proposalId) {
        require(proposals[proposalId].state == ProposalState.Executed, "DRAC: Proposal not executed");
        // Additional checks would be needed to ensure the proposal corresponds to the action being performed.
        _;
    }

    constructor() {
        owner = msg.sender;
        // Initialize with some default tiers (e.g., Guest, Member, Elite)
        // Tier 0 is the default/base tier.
        defineAccessTier(0, 0, "Guest");
        defineAccessTier(1, 1000, "Member");
        defineAccessTier(2, 5000, "Elite");
        // Assign some basic privileges to these default tiers
        assignPrivilegeToTier(1, keccak256(abi.encodePacked("basic_access")));
        assignPrivilegeToTier(2, keccak256(abi.encodePacked("basic_access")));
        assignPrivilegeToTier(2, keccak256(abi.encodePacked("premium_access")));
    }

    // --- III. Reputation Management ---

    /// @notice Internal helper to compute a user's total aggregate reputation score from all factors.
    /// @dev This function sums the current values of all reputation factors for a user. It does NOT trigger decay.
    /// @param user The address of the user.
    /// @return The total reputation score (uint256, clamped at 0 if negative).
    function _calculateReputationScore(address user) internal view returns (uint256) {
        UserProfile storage profile = userProfiles[user];
        if (!profile.registered) return 0; // Unregistered users have 0 reputation for now.

        int256 totalRep = 0;
        // Iterate through all possible reputation factor types defined in the enum
        for (uint256 i = 0; i < uint256(ReputationFactorType.VERIFICATION_SCORE) + 1; i++) {
            totalRep += profile.factors[ReputationFactorType(i)];
        }
        return totalRep > 0 ? uint256(totalRep) : 0; // Reputation cannot be negative externally
    }

    /// @notice Retrieves a user's current aggregate reputation score.
    /// @param user The address of the user.
    /// @return The total reputation score.
    function getUserReputation(address user) public view returns (uint256) {
        return _calculateReputationScore(user);
    }

    /// @notice Internal function to adjust a specific reputation factor for a user.
    /// @dev This function should be called by trusted sources (oracles, other contracts, or internal logic).
    /// @param user The address of the user whose reputation factor is being updated.
    /// @param factor The type of reputation factor to adjust.
    /// @param valueChange The amount to add to or subtract from the factor.
    function _updateReputationFactor(address user, ReputationFactorType factor, int252 valueChange) internal {
        // Ensure user has a profile; if not, implicitly register them.
        if (!userProfiles[user].registered) {
            userProfiles[user].registered = true;
            userProfiles[user].lastDecayTimestamp = block.timestamp;
            emit UserRegistered(user, ""); // Emit an event for implicit registration
        }

        UserProfile storage profile = userProfiles[user];
        profile.factors[factor] += valueChange;
        emit ReputationUpdated(user, factor, valueChange, profile.factors[factor]);
    }

    /// @notice Registers a new contract/address as a source for a specific reputation factor, with a defined weight.
    /// @dev Only the owner can call this. `sourceContract` can be `address(0)` if `msg.sender` is the implicit source.
    /// @param factorType The type of reputation factor this source contributes to.
    /// @param sourceContract The address of the contract or entity that will report for this factor.
    /// @param weight The weight (in basis points, 0-10000) for this source's contribution.
    function addReputationFactorSource(ReputationFactorType factorType, address sourceContract, uint256 weight)
        public onlyOwner
    {
        require(weight <= 10000, "DRAC: Weight cannot exceed 10000 (100%)");
        require(!reputationFactorSources[factorType][sourceContract].exists, "DRAC: Source already registered for this factor");

        reputationFactorSources[factorType][sourceContract] = ReputationSource({
            sourceContract: sourceContract,
            weight: weight,
            exists: true
        });
        // A more complex system might have an event here for auditing source changes.
    }

    /// @notice Modifies the weight of an existing reputation factor source.
    /// @dev Only the owner can call this.
    /// @param factorType The type of reputation factor.
    /// @param sourceContract The address of the source.
    /// @param newWeight The new weight (in basis points, 0-10000).
    function updateReputationFactorSourceWeight(ReputationFactorType factorType, address sourceContract, uint256 newWeight)
        public onlyOwner
    {
        require(newWeight <= 10000, "DRAC: Weight cannot exceed 10000 (100%)");
        require(reputationFactorSources[factorType][sourceContract].exists, "DRAC: Source not found for this factor");

        reputationFactorSources[factorType][sourceContract].weight = newWeight;
        // Event for updating source weight
    }

    /// @notice Applies the reputation decay mechanism to a user's score based on time elapsed.
    /// @dev Can be called by anyone to update a user's score to its current decayed value.
    ///      This incentivizes calling it, as user reputation needs to be current for access checks.
    /// @param user The address of the user.
    function triggerReputationDecay(address user) public {
        UserProfile storage profile = userProfiles[user];
        if (!profile.registered || profile.lastDecayTimestamp == 0) return; // No profile or decay never started

        uint256 currentTime = block.timestamp;
        uint256 intervalsPassed = (currentTime - profile.lastDecayTimestamp) / reputationDecayIntervalSeconds;

        if (intervalsPassed > 0) {
            uint256 oldTotalReputation = _calculateReputationScore(user);
            int256 decayMultiplier = int256(10000 - reputationDecayRateBasisPoints); // e.g., 9990 for 0.1% decay

            // Apply decay to each individual factor
            for (uint256 i = 0; i < uint256(ReputationFactorType.VERIFICATION_SCORE) + 1; i++) {
                ReputationFactorType factor = ReputationFactorType(i);
                int256 currentFactorScore = profile.factors[factor];

                // Apply decay for each interval passed
                for (uint256 j = 0; j < intervalsPassed; j++) {
                    currentFactorScore = (currentFactorScore * decayMultiplier) / 10000;
                }
                profile.factors[factor] = currentFactorScore;
            }
            profile.lastDecayTimestamp = currentTime; // Update last decay timestamp
            uint256 newTotalReputation = _calculateReputationScore(user);
            emit ReputationDecayed(user, oldTotalReputation, newTotalReputation);
        }
    }

    /// @notice Views all registered sources and their weights for a given factor type.
    /// @dev This function cannot efficiently return all sources from a nested mapping.
    ///      A more robust solution would track sources in a separate dynamic array when added/removed.
    ///      For demonstration purposes, it returns empty arrays.
    /// @param factorType The type of reputation factor.
    /// @return An empty array of source addresses and an empty array of their corresponding weights.
    function getReputationFactorSources(ReputationFactorType factorType)
        public view
        returns (address[] memory sources, uint256[] memory weights)
    {
        // Due to Solidity's limitations with iterating mappings, a comprehensive list cannot be returned easily.
        // A dApp frontend would typically query specific sources or there would be an auxiliary array to track them.
        return (new address[](0), new uint256[](0));
    }


    // --- II. Access & Privilege Management ---

    /// @notice Returns the current access tier ID and name for a user based on their reputation.
    /// @dev Iterates through `sortedAccessTierIds` from highest reputation requirement downwards to find the highest tier a user qualifies for.
    /// @param user The address of the user.
    /// @return tierId The ID of the highest tier the user qualifies for.
    /// @return tierName The name of the highest tier.
    function getAccessTier(address user) public view returns (uint256 tierId, string memory tierName) {
        uint256 userReputation = getUserReputation(user);
        uint256 highestTierId = 0; // Default to Guest tier (assuming ID 0 is the base/lowest tier)
        string memory highestTierName = accessTiers[0].name;

        // Iterate through sorted tiers from highest requirement to lowest
        for (uint256 i = sortedAccessTierIds.length > 0 ? sortedAccessTierIds.length - 1 : 0; i > 0; i--) {
            uint256 currentTierId = sortedAccessTierIds[i];
            AccessTier storage tier = accessTiers[currentTierId];
            if (tier.exists && userReputation >= tier.minReputation) {
                highestTierId = currentTierId;
                highestTierName = tier.name;
                break; // Found the highest tier the user qualifies for
            }
        }
        // Ensure that even if no higher tiers are met, the base tier (0) is considered if reputation permits
        if (accessTiers[0].exists && userReputation >= accessTiers[0].minReputation) {
            return (highestTierId, highestTierName);
        } else {
            // Fallback: If for some reason tier 0 doesn't exist or user doesn't meet its (0) minReputation, return default.
            // This scenario should ideally not happen if tier 0 is defined with minReputation 0.
            return (0, accessTiers[0].exists ? accessTiers[0].name : "Undefined");
        }
    }


    /// @notice Checks if a user possesses a specific privilege based on their access tier.
    /// @param user The address of the user.
    /// @param privilegeKey A keccak256 hash representing the privilege (e.g., `keccak256(abi.encodePacked("can_post_articles"))`).
    /// @return True if the user has the privilege, false otherwise.
    function hasAccessPrivilege(address user, bytes32 privilegeKey) public view returns (bool) {
        (uint256 userTierId, ) = getAccessTier(user); // Get the highest tier the user qualifies for
        return accessTiers[userTierId].privileges[privilegeKey];
    }

    /// @notice Defines or updates an access tier, specifying its minimum reputation requirement and name.
    /// @dev Only the owner can call this. Ensures `sortedAccessTierIds` remains sorted by `minReputation`.
    /// @param tierId The unique ID for the tier.
    /// @param minReputation Minimum reputation score required for this tier.
    /// @param tierName The human-readable name of the tier.
    function defineAccessTier(uint256 tierId, uint256 minReputation, string memory tierName)
        public onlyOwner
    {
        bool isNewTier = !accessTiers[tierId].exists;
        accessTiers[tierId].minReputation = minReputation;
        accessTiers[tierId].name = tierName;
        accessTiers[tierId].exists = true;

        if (isNewTier) {
            // Insert tierId into sortedAccessTierIds maintaining sorted order by minReputation ascending.
            // This ensures `getAccessTier` can efficiently find the highest tier.
            bool inserted = false;
            for (uint256 i = 0; i < sortedAccessTierIds.length; i++) {
                if (accessTiers[sortedAccessTierIds[i]].minReputation > minReputation) {
                    // Shift elements to the right and insert
                    for (uint256 j = sortedAccessTierIds.length; j > i; j--) {
                        sortedAccessTierIds[j] = sortedAccessTierIds[j - 1];
                    }
                    sortedAccessTierIds[i] = tierId;
                    inserted = true;
                    break;
                }
            }
            if (!inserted) {
                sortedAccessTierIds.push(tierId); // Append if it's the highest minReputation
            }
        } else {
            // If an existing tier is updated, its minReputation might change,
            // which could break the sorted order of `sortedAccessTierIds`.
            // For a robust solution, if `minReputation` changes for an existing tier:
            // 1. Remove it from `sortedAccessTierIds`.
            // 2. Re-insert it at the correct position.
            // For simplicity, we assume `minReputation` changes are rare or handled manually by owner.
            // `getAccessTier` iterates through `sortedAccessTierIds` in reverse order,
            // so if an element is out of place due to an update, it might still function
            // correctly if the new value logically keeps it in the correct "search path".
            // However, explicit re-sorting on update is ideal for production.
        }
        emit AccessTierDefined(tierId, minReputation, tierName);
    }

    /// @notice Grants a specific privilege to an existing access tier.
    /// @dev Only the owner can call this.
    /// @param tierId The ID of the tier.
    /// @param privilegeKey A keccak256 hash representing the privilege.
    function assignPrivilegeToTier(uint256 tierId, bytes32 privilegeKey)
        public onlyOwner
    {
        require(accessTiers[tierId].exists, "DRAC: Tier does not exist");
        accessTiers[tierId].privileges[privilegeKey] = true;
        emit PrivilegeAssigned(tierId, privilegeKey);
    }

    /// @notice Removes a privilege from an existing access tier.
    /// @dev Only the owner can call this.
    /// @param tierId The ID of the tier.
    /// @param privilegeKey A keccak256 hash representing the privilege.
    function revokePrivilegeFromTier(uint256 tierId, bytes32 privilegeKey)
        public onlyOwner
    {
        require(accessTiers[tierId].exists, "DRAC: Tier does not exist");
        accessTiers[tierId].privileges[privilegeKey] = false;
        emit PrivilegeRevoked(tierId, privilegeKey);
    }

    /// @notice Simulates a user requesting access to a resource, which internally checks their privileges.
    /// @dev This function acts as an example interface. Other contracts or DApps would typically
    ///      call `hasAccessPrivilege` directly. It also provides a small reputation boost for successful access.
    /// @param resourceId A unique identifier for the resource being accessed.
    /// @return True if access is granted, false otherwise.
    function requestAccess(bytes32 resourceId) public returns (bool) {
        // Example: Assume a specific privilege `access_resource_[resourceId]` is needed
        bytes32 requiredPrivilege = keccak256(abi.encodePacked("access_resource_", resourceId));
        bool granted = hasAccessPrivilege(msg.sender, requiredPrivilege);

        if (granted) {
            // Incentivize usage: small boost to activity score for successful access
            _updateReputationFactor(msg.sender, ReputationFactorType.ACTIVITY_SCORE, 10);
            return true;
        } else {
            // Optional: penalize for trying to access without permission, or just return false
            return false;
        }
    }


    // --- III. Oracle & External Data Integration ---

    /// @notice Trusted oracles submit signed data to update specific reputation factors for a user.
    /// @dev The oracle is expected to sign a message containing `contract_address`, `user`, `factorType`,
    ///      `valueChange`, and `timestamp`. This provides authenticity and replay protection.
    ///      For simplicity, `msg.sender` must be a registered oracle. The `signature` is a proof of data integrity
    ///      from an external system that the oracle validates before submitting.
    ///      **NOTE:** A robust `ecrecover` implementation would typically use OpenZeppelin's `ECDSA` library.
    ///      Here, we're assuming the oracle itself submits via `msg.sender` and the `signature` is an *internal*
    ///      proof for the oracle's own audit trail, rather than an `ecrecover` from an arbitrary signer.
    ///      If `signature` were from an arbitrary *data source*, the oracle would verify it and then call this function.
    /// @param user The user whose reputation is affected.
    /// @param factorType The type of reputation factor.
    /// @param valueChange The change in reputation score.
    /// @param signature The ECDSA signature from the data source (not necessarily the oracle itself).
    /// @param timestamp The timestamp included in the signed message (for replay protection and freshness).
    function submitReputationData(
        address user,
        ReputationFactorType factorType,
        int256 valueChange,
        bytes32 signature, // Placeholder, requires full ECDSA implementation
        uint256 timestamp // Placeholder for replay protection
    ) public onlyOracle {
        // Here, we assume the `onlyOracle` modifier handles the trust.
        // The `signature` and `timestamp` could be used for advanced oracle-specific checks,
        // such as verifying data origin or preventing replay attacks if the data itself is signed.
        // For this example, the `signature` is not actively verified against an `ecrecover` here,
        // relying on the `onlyOracle` modifier for trust in the submitter.
        // A full implementation would likely:
        // 1. Recover `signer` from `signature`, `messageHash`
        // 2. Verify `signer` is a trusted external data source.
        // 3. Check `timestamp` for freshness and replay.
        _updateReputationFactor(user, factorType, valueChange);
    }

    /// @notice Adds a new address to the list of trusted oracles.
    /// @dev Only the owner can call this.
    /// @param oracleAddress The address of the new oracle.
    /// @param name A human-readable name for the oracle.
    function registerOracle(address oracleAddress, string memory name) public onlyOwner {
        require(oracleAddress != address(0), "DRAC: Invalid oracle address");
        require(!oracles[oracleAddress], "DRAC: Oracle already registered");
        oracles[oracleAddress] = true;
        oracleNames[oracleAddress] = name;
        totalOracles++;
        emit OracleRegistered(oracleAddress, name);
    }

    /// @notice Removes an address from the list of trusted oracles.
    /// @dev Only the owner can call this.
    /// @param oracleAddress The address of the oracle to revoke.
    function revokeOracle(address oracleAddress) public onlyOwner {
        require(oracles[oracleAddress], "DRAC: Oracle not registered");
        oracles[oracleAddress] = false;
        delete oracleNames[oracleAddress]; // Clear name too
        totalOracles--;
        emit OracleRevoked(oracleAddress);
    }

    /// @notice Checks if an address is a registered oracle.
    /// @param _address The address to check.
    /// @return True if the address is a registered oracle, false otherwise.
    function isOracle(address _address) public view returns (bool) {
        return oracles[_address];
    }


    // --- IV. Governance & Parameter Tuning ---

    /// @notice Initiates a proposal to change a key contract parameter.
    /// @dev Requires a minimum reputation to propose (e.g., a "Member" tier or higher).
    /// @param paramKey A bytes32 identifier for the parameter (e.g., `keccak256(abi.encodePacked("DECAY_RATE"))`).
    /// @param newValue The new value for the parameter, encoded as bytes.
    /// @param description A descriptive string explaining the proposal.
    function proposeParameterChange(bytes32 paramKey, bytes memory newValue, string memory description)
        public
    {
        // Require a minimum reputation to propose (e.g., 1000 reputation for Member tier)
        require(getUserReputation(msg.sender) >= 1000, "DRAC: Insufficient reputation to propose");

        proposals.push(Proposal({
            proposer: msg.sender,
            paramKey: paramKey,
            newValue: newValue,
            description: description,
            startBlock: block.number, // Voting starts immediately
            endBlock: block.number + proposalVotingPeriodBlocks,
            supportVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize an empty mapping for votes
            state: ProposalState.Active,
            minReputationToVote: 100 // Example: A lower reputation (e.g., 100) might be enough to vote
        }));

        emit ProposalCreated(proposals.length - 1, msg.sender, paramKey, description);
    }

    /// @notice Allows eligible users to vote on an active proposal.
    /// @dev Users must meet the `minReputationToVote` criteria for the specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "DRAC: Proposal not active for voting");
        require(block.number <= proposal.endBlock, "DRAC: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DRAC: Already voted on this proposal");
        require(getUserReputation(msg.sender) >= proposal.minReputationToVote, "DRAC: Insufficient reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    /// @notice Executes a successfully voted-on proposal, applying the parameter change.
    /// @dev Can be called by anyone after the voting period ends and quorum/majority conditions are met.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "DRAC: Proposal not active");
        require(block.number > proposal.endBlock, "DRAC: Voting period not ended");
        require(proposal.state != ProposalState.Executed, "DRAC: Proposal already executed");

        uint256 totalVotes = proposal.supportVotes + proposal.againstVotes;
        // Quorum check: total votes must meet a percentage of active voters.
        // For simplicity, we use `totalOracles` as a proxy for "governance participants".
        // A more advanced system would track total eligible voters dynamically.
        uint256 minVotesForQuorum = (totalOracles > 0 ? totalOracles : 1) * proposalVoteQuorumBasisPoints / 10000;
        if (totalVotes < minVotesForQuorum) {
            proposal.state = ProposalState.Failed;
            return;
        }

        // Majority rule: more support votes than against votes
        if (proposal.supportVotes > proposal.againstVotes) {
            // Execute the parameter change based on `paramKey`
            if (proposal.paramKey == keccak256(abi.encodePacked("DECAY_RATE"))) {
                reputationDecayRateBasisPoints = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramKey == keccak256(abi.encodePacked("DECAY_INTERVAL"))) {
                reputationDecayIntervalSeconds = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramKey == keccak256(abi.encodePacked("VOTING_QUORUM"))) {
                proposalVoteQuorumBasisPoints = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramKey == keccak256(abi.encodePacked("VOTING_PERIOD"))) {
                proposalVotingPeriodBlocks = abi.decode(proposal.newValue, (uint256));
            } else {
                revert("DRAC: Unknown parameter key for execution");
            }
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);
            emit ParameterChanged(proposal.paramKey, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed; // Proposal failed due to insufficient support
        }
    }

    /// @notice Retrieves the current state and details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposer The address of the proposal initiator.
    /// @return paramKey The parameter key.
    /// @return newValue The new value for the parameter.
    /// @return description Description of the proposal.
    /// @return startBlock Block when voting started.
    /// @return endBlock Block when voting ends.
    /// @return supportVotes Votes in favor.
    /// @return againstVotes Votes against.
    /// @return state Current state of the proposal.
    function getProposalState(uint256 proposalId)
        public view
        returns (
            address proposer,
            bytes32 paramKey,
            bytes memory newValue,
            string memory description,
            uint256 startBlock,
            uint256 endBlock,
            uint256 supportVotes,
            uint256 againstVotes,
            ProposalState state
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.paramKey,
            proposal.newValue,
            proposal.description,
            proposal.startBlock,
            proposal.endBlock,
            proposal.supportVotes,
            proposal.againstVotes,
            proposal.state
        );
    }


    // --- V. User Management & Utilities ---

    /// @notice Allows a user to register themselves and associate optional metadata.
    /// @dev Users who haven't explicitly registered might still have reputation updated by oracles,
    ///      but explicit registration allows them to control their `metadataURI`.
    /// @param metadataURI A URI pointing to off-chain user metadata (e.g., IPFS hash).
    function registerUser(string memory metadataURI) public {
        require(!userProfiles[msg.sender].registered, "DRAC: User already registered");
        userProfiles[msg.sender].registered = true;
        userProfiles[msg.sender].metadataURI = metadataURI;
        userProfiles[msg.sender].lastDecayTimestamp = block.timestamp;
        emit UserRegistered(msg.sender, metadataURI);
    }

    /// @notice Allows a registered user to update their associated metadata.
    /// @param newMetadataURI The new URI pointing to off-chain user metadata.
    function updateUserMetadata(string memory newMetadataURI) public {
        require(userProfiles[msg.sender].registered, "DRAC: User not registered");
        userProfiles[msg.sender].metadataURI = newMetadataURI;
        emit UserMetadataUpdated(msg.sender, newMetadataURI);
    }

    /// @notice Sets the global reputation decay rate (basis points per unit time).
    /// @dev Only the owner can call this, or it can be changed via governance proposal.
    /// @param newDecayRateBasisPoints The new decay rate in basis points (e.g., 10 for 0.1%).
    function setDecayRate(uint256 newDecayRateBasisPoints) public onlyOwner {
        require(newDecayRateBasisPoints <= 10000, "DRAC: Decay rate cannot exceed 100%");
        reputationDecayRateBasisPoints = newDecayRateBasisPoints;
        emit ParameterChanged(keccak256(abi.encodePacked("DECAY_RATE")), abi.encode(newDecayRateBasisPoints));
    }

    /// @notice Allows the owner or governance to withdraw funds (e.g., collected fees) from the contract.
    /// @dev This contract itself doesn't define fees, but could be extended to.
    /// @param tokenAddress The address of the ERC20 token to withdraw. Use `address(0)` for native ETH.
    /// @param amount The amount to withdraw.
    function withdrawFunds(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == address(0)) {
            payable(owner).transfer(amount);
        } else {
            // Assume ERC20 interface, using low-level call for flexibility
            // In a production environment, import IERC20 and use `IERC20(tokenAddress).transfer(owner, amount);`
            (bool success, bytes memory data) = tokenAddress.call(abi.encodeWithSelector(0xa9059cbb, owner, amount));
            require(success, "DRAC: Failed to withdraw ERC20 tokens");
            // Also check `data` for revert reasons if the token implements custom errors on transfer.
        }
    }

    /// @notice Returns various high-level statistics about the contract.
    /// @dev `totalRegisteredUsers` cannot be accurately determined from a mapping without an auxiliary counter.
    ///      `currentProposals` returns the total number of proposals ever created.
    /// @return totalRegisteredUsers A count of explicitly registered users (0 if not explicitly tracked).
    /// @return activeOracles Number of currently registered oracles.
    /// @return totalProposals Number of proposals created (active/past).
    /// @return decayRate Current reputation decay rate in basis points.
    function getContractMetrics()
        public view
        returns (uint256 totalRegisteredUsers, uint256 activeOracles, uint256 totalProposals, uint256 decayRate)
    {
        // `totalRegisteredUsers` is currently 0 as a mapping cannot be iterated,
        // an explicit counter would be needed on `registerUser`.
        return (0, totalOracles, proposals.length, reputationDecayRateBasisPoints);
    }

    /// @notice Returns the details (minReputation, name) of a specific access tier.
    /// @dev Cannot return the `privileges` mapping directly. A dApp would query `hasAccessPrivilege` for specific privileges.
    /// @param tierId The ID of the tier.
    /// @return minReputation Minimum reputation for the tier.
    /// @return name Name of the tier.
    function getAccessTierDetails(uint256 tierId)
        public view
        returns (uint256 minReputation, string memory name)
    {
        AccessTier storage tier = accessTiers[tierId];
        require(tier.exists, "DRAC: Tier does not exist");

        return (tier.minReputation, tier.name);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```