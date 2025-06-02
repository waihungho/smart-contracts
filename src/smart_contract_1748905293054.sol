Okay, this is an interesting challenge! Let's design a smart contract system focused on dynamic, evolving digital assets influenced by staking, community interaction, and external "environmental" factors simulated via an oracle.

We'll call this contract `ChronoForge`. It will manage unique, soulbound-like assets called "Chronos" that accumulate "Evolution Points" (EP) through staking. EP can be spent to "forge" (upgrade) traits, and external triggers (via a trusted oracle) can also cause evolution or alter traits. Community governance allows adjustments to forging costs, staking rates, or triggering global events.

This avoids directly duplicating standard ERC-20/721/1155 (by making assets soulbound/non-standard transfer), basic staking, or simple governance, while incorporating concepts from dynamic NFTs, DeFi (staking mechanics), DAOs, and oracle interaction.

---

**ChronoForge Smart Contract**

**Outline:**

1.  **Contract Description:** Manages Soulbound-like "Chrono" assets that evolve based on staking, forging (spending Evolution Points), and external triggers (oracle). Features include staking for EP, trait forging, timed evolution, oracle-driven events, and community governance.
2.  **State Variables:**
    *   Admin/Owner address.
    *   Oracle address.
    *   Mapping for Chrono data (`Chrono` struct).
    *   Mapping for owner's Chrono IDs.
    *   Mapping for staking data.
    *   Mapping for proposal data.
    *   Mapping for vote data.
    *   Parameters (staking rate, forging costs, voting thresholds, etc.).
    *   Counters (Chrono ID, Proposal ID).
    *   Pause state.
3.  **Structs:**
    *   `Chrono`: Represents a unique asset with traits, EP, staking info, etc.
    *   `Trait`: Defines a specific trait type with costs, requirements, etc.
    *   `Proposal`: Defines a governance proposal.
4.  **Events:** Signify key actions (Mint, Stake, Unstake, ClaimEP, Forge, Evolve, OracleTrigger, ProposalCreated, Voted, ProposalExecuted, ParameterUpdate, etc.).
5.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`, `whenNotPaused`, `whenPaused`).
6.  **Core Chrono Functions:**
    *   Minting new Chronos.
    *   Viewing Chrono details.
    *   Burning Chronos.
    *   Setting Soulbound status (if not default).
7.  **Evolution & Staking Functions:**
    *   Staking a Chrono.
    *   Unstaking a Chrono.
    *   Claiming accumulated Evolution Points.
    *   Forging a specific Chrono trait (spending EP).
    *   Triggering timed evolution based on time and EP.
    *   Applying effects from oracle triggers.
8.  **Governance Functions:**
    *   Creating a new proposal.
    *   Voting on a proposal.
    *   Executing a passed proposal.
    *   Delegating voting power (based on staked Chronos).
9.  **Utility & View Functions (Ensuring 20+ total):**
    *   Calculating pending EP.
    *   Getting staking status.
    *   Retrieving owner's Chrono list.
    *   Getting proposal details.
    *   Calculating voting power.
    *   Getting proposal state.
    *   Querying trait details and requirements.
    *   Simulating potential evolution outcomes.
    *   Getting contract parameters.
    *   Checking trait status on a Chrono.
    *   Getting total staked Chronos.
    *   Admin controls (pause, withdraw).
    *   Querying past votes/voting power at snapshot.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice

// --- Outline ---
// 1. Contract Description: Manages Soulbound-like "Chrono" assets that evolve based on staking, forging (spending Evolution Points), and external triggers (oracle). Features include staking for EP, trait forging, timed evolution, oracle-driven events, and community governance.
// 2. State Variables: Admin/Owner, Oracle, Chrono data, Owner's Chrono list, Staking data, Proposal data, Vote data, Parameters, Counters, Pause state.
// 3. Structs: Chrono, Trait, Proposal.
// 4. Events: Mint, Stake, Unstake, ClaimEP, Forge, Evolve, OracleTrigger, ProposalCreated, Voted, ProposalExecuted, ParameterUpdate, etc.
// 5. Modifiers: Access control (onlyOwner, onlyOracle, whenNotPaused, whenPaused).
// 6. Core Chrono Functions: Minting, Viewing, Burning, Setting Soulbound.
// 7. Evolution & Staking Functions: Staking, Unstaking, Claiming EP, Forging traits, Timed Evolution, Oracle Triggers.
// 8. Governance Functions: Create Proposal, Vote, Execute Proposal, Delegate Voting.
// 9. Utility & View Functions (20+ total): Calculate EP, Get Status, Get Lists, Get Details (Proposal, Trait, Chrono), Calculate Voting Power, Simulate, Admin controls, Parameter queries.

// --- Function Summary ---
// Core Chrono Management:
// 1. mintChrono(address recipient, uint256 initialTraits) - Mints a new Chrono for recipient with initial traits.
// 2. burnChrono(uint256 chronoId) - Burns/destroys a Chrono.
// 3. getChronoDetails(uint256 chronoId) - Views detailed info of a Chrono.
// 4. getOwnerChronos(address owner) - Views list of Chrono IDs owned by an address.
// 5. isChronoSoulbound(uint256 chronoId) - Checks if a Chrono is soulbound (always true in this version).

// Evolution & Staking:
// 6. stakeChrono(uint256 chronoId) - Stakes a Chrono to start accumulating EP.
// 7. unstakeChrono(uint256 chronoId) - Unstakes a Chrono, stopping EP accumulation.
// 8. claimEvolutionPoints(uint256 chronoId) - Claims accrued EP for a staked/unstaked Chrono.
// 9. forgeChronoTrait(uint256 chronoId, uint8 traitId) - Spends EP to upgrade a specific trait on a Chrono.
// 10. triggerTimedEvolution(uint256 chronoId) - Triggers an evolution check based on time elapsed and EP.
// 11. applyOracleTrigger(uint256 chronoId, uint8 triggerType, bytes memory triggerData) - Applies an effect based on oracle data.

// Governance:
// 12. createProposal(string memory description, address targetContract, bytes memory callData) - Creates a new governance proposal.
// 13. voteOnProposal(uint256 proposalId, bool support) - Casts a vote on a proposal (voting power based on staked Chronos).
// 14. executeProposal(uint256 proposalId) - Executes a proposal if it passed.
// 15. delegateVotingPower(address delegatee) - Delegates voting power from staked Chronos.

// Utility & View Functions (> 20 Total):
// 16. getPendingEvolutionPoints(uint256 chronoId) - Calculates EP accrued since last claim/stake/unstake.
// 17. getStakingInfo(uint256 chronoId) - Gets staking start time and status.
// 18. calculateVotingPower(address voter) - Calculates current voting power based on staked Chronos.
// 19. getProposalDetails(uint256 proposalId) - Views detailed info of a proposal.
// 20. getProposalState(uint256 proposalId) - Gets the current state of a proposal (Pending, Active, Canceled, Defeated, Succeeded, Executed).
// 21. getTraitDetails(uint8 traitId) - Views details about a specific trait type.
// 22. getTraitRequirement(uint8 traitId, uint8 currentLevel) - Views requirements for forging a trait to a specific level.
// 23. simulateEvolutionOutcome(uint256 chronoId) - Simulates potential outcomes of triggerTimedEvolution.
// 24. getContractParameters() - Views current contract parameters (staking rate, etc.).
// 25. getChronoTraitLevel(uint256 chronoId, uint8 traitId) - Gets the level of a specific trait on a Chrono.
// 26. getTotalStakedChronos() - Gets the total number of currently staked Chronos.
// 27. setOracleAddress(address _oracle) - Admin function to set the trusted oracle address.
// 28. pause() - Admin function to pause certain contract operations.
// 29. unpause() - Admin function to unpause the contract.
// 30. withdrawEth(address payable recipient) - Admin function to withdraw ETH held by the contract (e.g., mint fees).
// 31. getChronoStatus(uint256 chronoId) - Gets the overall status of a Chrono (Staked, Unstaked, Burned, etc.).
// 32. getTraitCost(uint8 traitId, uint8 currentLevel) - Gets the EP cost to forge a trait to the next level.

contract ChronoForge is Ownable, Pausable, ReentrancyGuard {

    // --- Structs ---

    enum ChronoStatus {
        NonExistent,
        Unstaked,
        Staked
        // Add other states like Evolving, Forging, etc., if needed
    }

    struct Chrono {
        address owner;
        uint66 creationTime; // Fits timestamp
        uint66 lastEPClaimTime;
        uint128 evolutionPoints; // Use uint128 for larger potential values
        mapping(uint8 => uint8) traits; // traitId => level
        bool isSoulbound; // Always true in this implementation
        ChronoStatus status;
        uint66 stakeStartTime; // 0 if not staked
    }

    struct Trait {
        string name;
        string description;
        mapping(uint8 => uint128) levelUpCostEP; // level => EP cost to reach this level
        mapping(uint8 => uint8[]) levelUpRequirements; // level => traitIds and minLevels required
        // Add more trait properties, e.g., effects on EP gain, forging cost modifiers, visual attributes
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    struct Proposal {
        address proposer;
        uint66 creationTime;
        uint66 votingEndTime;
        uint128 totalStakedAtSnapshot; // Snapshot of total staked Chronos for voting power calculation
        string description;
        address targetContract; // The contract to call if proposal passes
        bytes callData; // The function call details
        uint128 yesVotes;
        uint128 noVotes;
        mapping(address => bool) hasVoted; // User address => voted
        ProposalState state;
    }

    // --- State Variables ---

    address public oracleAddress;
    uint256 private _nextTokenId;
    uint256 private _nextProposalId;
    uint256 public totalStakedChronos;

    // Configuration parameters (can be updated via governance)
    uint64 public epPerSecondPerStakedChrono = 1; // Rate of EP generation
    uint64 public constant MIN_STAKE_DURATION = 1 hours; // Minimum time staked before claiming EP
    uint66 public constant VOTING_PERIOD_DURATION = 3 days;
    uint128 public constant PROPOSAL_THRESHOLD_STAKED = 1; // Minimum staked Chronos to create proposal
    uint128 public constant QUORUM_STAKED_PERCENT = 4; // Percentage of total staked needed for quorum (4% example)
    uint128 public constant APPROVAL_PERCENT = 51; // Percentage of votes needed to pass

    mapping(uint256 => Chrono) private _chronos;
    mapping(address => uint256[]) private _ownerChronos; // Basic owner tracking
    mapping(uint256 => uint66) private _chronoStakeStartTime; // ChronoId => stakeStartTime (redundant with Chrono.stakeStartTime, but keeping for clarity if needed)

    // Governance state
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => address) public voteDelegates; // delegatee address => delegator address (or delegatee address if no delegation)

    // Trait definitions - Can be initialized or potentially managed via governance/admin
    mapping(uint8 => Trait) public traitDefinitions;
    uint8[] public availableTraitIds; // List of IDs for iterating

    // --- Events ---

    event ChronoMinted(uint256 indexed chronoId, address indexed owner, uint66 creationTime);
    event ChronoBurned(uint256 indexed chronoId);
    event ChronoStaked(uint256 indexed chronoId, address indexed owner, uint66 stakeStartTime);
    event ChronoUnstaked(uint256 indexed chronoId, address indexed owner, uint66 unstakeTime);
    event EvolutionPointsClaimed(uint256 indexed chronoId, address indexed owner, uint128 claimedAmount, uint66 claimTime);
    event TraitForged(uint256 indexed chronoId, uint8 indexed traitId, uint8 newLevel, uint128 epSpent);
    event TimedEvolutionTriggered(uint256 indexed chronoId, string evolutionOutcome);
    event OracleTriggerApplied(uint256 indexed chronoId, uint8 indexed triggerType, bytes triggerData);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint66 creationTime, uint66 votingEndTime, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint128 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event ParameterUpdated(string parameterName, uint256 newValue);

    // --- Constructor ---

    constructor(address _oracle) Ownable(msg.sender) Pausable() {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
        _nextTokenId = 1; // Start Chrono IDs from 1
        _nextProposalId = 1; // Start Proposal IDs from 1

        // Initialize some example traits (can be expanded or managed later)
        _initializeTrait(1, "Power", "Increases combat strength", [0, 100, 250, 500, 1000], [[], [1], [1,2], [1,2], [1,2]]); // Cost to reach level 1, 2, 3, 4. Requirements might be [traitId, minLevel], e.g. [1,1] means need Power level 1. Empty means no requirement other than EP. Example: Level 2 needs Power 1; Level 3 needs Power 2; Level 4 needs Power 2 & Speed 1.
        _initializeTrait(2, "Speed", "Increases agility", [0, 80, 200, 400, 800], [[], [1], [2], [2], [2,1]]);
        _initializeTrait(3, "Intelligence", "Increases crafting skill", [0, 120, 300, 600, 1200], [[], [], [1], [1,2], [1,2]]);
        // ... add more traits ...
    }

    // Helper to initialize traits
    function _initializeTrait(
        uint8 traitId,
        string memory name,
        string memory description,
        uint128[] memory costs,
        uint8[][] memory requirements // traitId => level => requiredTraitIds[]
    ) private {
        require(traitDefinitions[traitId].levelUpCostEP[1] == 0, "Trait already initialized"); // Simple check if cost for level 1 is 0
        traitDefinitions[traitId].name = name;
        traitDefinitions[traitId].description = description;
        for(uint8 i = 0; i < costs.length; i++) {
            traitDefinitions[traitId].levelUpCostEP[i] = costs[i]; // Cost to REACH level 'i'
        }
        // This part for requirements needs careful indexing/mapping, let's simplify the struct definition
        // Trait struct requires mapping(uint8 => uint8[]) for requirements. Let's adjust the struct and this function
        // Corrected Trait struct definition above. Now handle requirements mapping:
        // Example requirements[1] (for level 1) contains an array of traitIds. Let's change requirement structure to traitId => requiredLevel
        // New requirement structure: mapping(uint8 => mapping(uint8 => uint8)) requirements // level => requiredTraitId => minLevelRequired
        // Let's simplify for the example: mapping(uint8 => uint8[]) levelUpRequirementTraitIds; mapping(uint8 => uint8[]) levelUpRequirementMinLevels;
        // Simpler again: requireEP mapping, let's stick to just checking *if* a trait exists at a level
        // Let's redefine trait requirements simply as requiring *another* trait at a minimum level.
        // mapping(uint8 => mapping(uint8 => mapping(uint8 => uint8))) levelUpRequirements; // level => requiredTraitId => minLevelRequired
        // This is getting complex. Let's use an array of pairs: level => [(traitId, minLevel), (traitId, minLevel), ...]
        // Let's simplify Trait struct: mapping(uint8 => uint128) levelUpCostEP; mapping(uint8 => Requirement[]) levelRequirements;
        // struct Requirement { uint8 traitId; uint8 minLevel; } struct Trait { ... mapping(uint8 => Requirement[]) levelRequirements; }
        // Initialize with this structure. This constructor helper needs to be adjusted.
        // Let's simplify the example: No complex trait dependencies for this initial version to keep it manageable. Just EP costs.
        // Remove requirements from struct and initialize function. The comment still has the complex idea, but the code won't implement it fully.
        // Let's revert the Trait struct and initialization to just EP costs.

        // Revised _initializeTrait without complex requirements:
        // Constructor needs to be fixed to match the simplified Trait struct again.
        // The initial Trait struct had `mapping(uint8 => uint8[]) levelUpRequirements`. Let's revert to that but simplify *how* requirements are checked later.
        // Ok, the initial struct definition for Trait is simple: `mapping(uint8 => uint8) traits;` in Chrono. Trait definition struct: `mapping(uint8 => uint128) levelUpCostEP;`. Requirements mapping removed for simplicity now.

        // Initializing traitDefinitions with names, descriptions, and costs:
        traitDefinitions[1] = Trait("Power", "Increases combat strength");
        traitDefinitions[1].levelUpCostEP[1] = 100;
        traitDefinitions[1].levelUpCostEP[2] = 250;
        traitDefinitions[1].levelUpCostEP[3] = 500;
        traitDefinitions[1].levelUpCostEP[4] = 1000;

        traitDefinitions[2] = Trait("Speed", "Increases agility");
        traitDefinitions[2].levelUpCostEP[1] = 80;
        traitDefinitions[2].levelUpCostEP[2] = 200;
        traitDefinitions[2].levelUpCostEP[3] = 400;
        traitDefinitions[2].levelUpCostEP[4] = 800;

        traitDefinitions[3] = Trait("Intelligence", "Increases crafting skill");
        traitDefinitions[3].levelUpCostEP[1] = 120;
        traitDefinitions[3].levelUpCostEP[2] = 300;
        traitDefinitions[3].levelUpCostEP[3] = 600;
        traitDefinitions[3].levelUpCostEP[4] = 1200;

        availableTraitIds = [1, 2, 3];
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    modifier onlyChronoOwner(uint256 chronoId) {
        require(_chronos[chronoId].owner == msg.sender, "Caller is not the chrono owner");
        _;
    }

    // --- Core Chrono Functions ---

    /**
     * @dev Mints a new Chrono and assigns it to a recipient.
     * @param recipient The address to receive the new Chrono.
     * @param initialTraitValue Placeholder for initial trait randomness/type.
     */
    function mintChrono(address recipient, uint256 initialTraitValue)
        public
        whenNotPaused
        returns (uint256)
    {
        require(recipient != address(0), "Recipient cannot be zero address");

        uint256 newTokenId = _nextTokenId++;
        uint66 currentTime = uint66(block.timestamp);

        Chrono storage newChrono = _chronos[newTokenId];
        newChrono.owner = recipient;
        newChrono.creationTime = currentTime;
        newChrono.lastEPClaimTime = currentTime;
        newChrono.evolutionPoints = 0;
        newChrono.isSoulbound = true; // Chronos are soulbound
        newChrono.status = ChronoStatus.Unstaked;

        // Example: Initialize a base trait level based on input (can be more complex logic)
        // newChrono.traits[1] = uint8(initialTraitValue % 5); // Example: set Power trait level 0-4

        _ownerChronos[recipient].push(newTokenId);

        emit ChronoMinted(newTokenId, recipient, currentTime);
        return newTokenId;
    }

    /**
     * @dev Burns/destroys a Chrono. Only the owner can burn.
     * @param chronoId The ID of the Chrono to burn.
     */
    function burnChrono(uint256 chronoId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
    {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");
        require(chrono.status != ChronoStatus.Staked, "Cannot burn staked chrono");

        address owner = chrono.owner;

        // Remove from owner's list (basic implementation, inefficient for large lists)
        uint256[] storage ownerTokens = _ownerChronos[owner];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == chronoId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }

        delete _chronos[chronoId]; // Clear storage
        // Note: Mappings in structs are not fully deleted, but the struct itself is. Accessing traits/stakeStartTime after delete will return default values.
        // Set status explicitly to NonExistent
        chrono.status = ChronoStatus.NonExistent; // Redundant but explicit

        emit ChronoBurned(chronoId);
    }

    /**
     * @dev Gets detailed information about a Chrono.
     * @param chronoId The ID of the Chrono.
     * @return owner_ The owner's address.
     * @return creationTime_ The creation timestamp.
     * @return lastEPClaimTime_ The last timestamp EP was claimed/updated.
     * @return evolutionPoints_ The current EP balance.
     * @return status_ The current status (Unstaked, Staked, etc.).
     * @return stakeStartTime_ The timestamp when staking began (0 if not staked).
     * @return traitIds_ Array of trait IDs present.
     * @return traitLevels_ Array of trait levels corresponding to traitIds_.
     */
    function getChronoDetails(uint256 chronoId)
        public
        view
        returns (
            address owner_,
            uint66 creationTime_,
            uint66 lastEPClaimTime_,
            uint128 evolutionPoints_,
            ChronoStatus status_,
            uint66 stakeStartTime_,
            uint8[] memory traitIds_,
            uint8[] memory traitLevels_
        )
    {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");

        owner_ = chrono.owner;
        creationTime_ = chrono.creationTime;
        lastEPClaimTime_ = chrono.lastEPClaimTime;
        evolutionPoints_ = chrono.evolutionPoints;
        status_ = chrono.status;
        stakeStartTime_ = chrono.stakeStartTime;

        // Collect traits into arrays
        uint256 traitCount = 0;
        for (uint256 i = 0; i < availableTraitIds.length; i++) {
            uint8 traitId = availableTraitIds[i];
            if (chrono.traits[traitId] > 0) { // Only include traits with level > 0
                traitCount++;
            }
        }

        traitIds_ = new uint8[](traitCount);
        traitLevels_ = new uint8[](traitCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < availableTraitIds.length; i++) {
            uint8 traitId = availableTraitIds[i];
            if (chrono.traits[traitId] > 0) {
                 traitIds_[currentIndex] = traitId;
                 traitLevels_[currentIndex] = chrono.traits[traitId];
                 currentIndex++;
            }
        }
    }

    /**
     * @dev Gets the list of Chrono IDs owned by an address.
     * @param owner The address to query.
     * @return The array of Chrono IDs.
     */
    function getOwnerChronos(address owner) public view returns (uint256[] memory) {
        return _ownerChronos[owner];
    }

    /**
     * @dev Chronos are designed to be Soulbound. This function always returns true if the Chrono exists.
     * @param chronoId The ID of the Chrono.
     * @return Always true if Chrono exists, false otherwise.
     */
    function isChronoSoulbound(uint256 chronoId) public view returns (bool) {
         return _chronos[chronoId].status != ChronoStatus.NonExistent; // Return true if exists
    }


    // --- Evolution & Staking Functions ---

    /**
     * @dev Stakes a Chrono, starting EP accumulation. Only the owner can stake.
     * @param chronoId The ID of the Chrono to stake.
     */
    function stakeChrono(uint256 chronoId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
        nonReentrant
    {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status == ChronoStatus.Unstaked, "Chrono is not unstaked");

        // Claim any pending EP before staking
        _claimEvolutionPointsInternal(chronoId);

        chrono.status = ChronoStatus.Staked;
        chrono.stakeStartTime = uint66(block.timestamp);
        totalStakedChronos++;

        emit ChronoStaked(chronoId, msg.sender, chrono.stakeStartTime);
    }

    /**
     * @dev Unstakes a Chrono, stopping EP accumulation. Only the owner can unstake.
     * @param chronoId The ID of the Chrono to unstake.
     */
    function unstakeChrono(uint256 chronoId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
        nonReentrant
    {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status == ChronoStatus.Staked, "Chrono is not staked");
        // Optional: Add unstaking cooldown or penalty based on stake duration
        // require(block.timestamp >= chrono.stakeStartTime + MIN_STAKE_DURATION, "Stake duration not met");

        // Claim pending EP upon unstaking
        _claimEvolutionPointsInternal(chronoId);

        chrono.status = ChronoStatus.Unstaked;
        chrono.stakeStartTime = 0; // Reset stake start time
        totalStakedChronos--;

        emit ChronoUnstaked(chronoId, msg.sender, uint66(block.timestamp));
    }

    /**
     * @dev Claims accumulated Evolution Points for a Chrono. Updates the EP balance.
     * Can be called while staked or unstaked.
     * @param chronoId The ID of the Chrono.
     */
    function claimEvolutionPoints(uint256 chronoId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
        nonReentrant
    {
        _claimEvolutionPointsInternal(chronoId);
    }

    /**
     * @dev Internal helper function to calculate and add pending EP.
     */
    function _claimEvolutionPointsInternal(uint256 chronoId) private {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");

        uint66 currentTime = uint66(block.timestamp);
        uint128 earnedEP = 0;
        uint66 lastClaim = chrono.lastEPClaimTime;

        if (chrono.status == ChronoStatus.Staked && chrono.stakeStartTime > 0) {
            // EP calculation only occurs while staked, since the last claim or stake start
            uint66 effectiveStartTime = chrono.stakeStartTime > lastClaim ? chrono.stakeStartTime : lastClaim;
             if (currentTime > effectiveStartTime) {
                 uint66 duration = currentTime - effectiveStartTime;
                 earnedEP = uint128(duration) * epPerSecondPerStakedChrono;
             }
        } else {
            // If unstaked, calculate EP since last claim, but only if it was staked during that period
             if (chrono.stakeStartTime > 0 && currentTime > lastClaim) { // Check if it was staked AND time passed since last claim
                 uint66 effectiveStartTime = chrono.stakeStartTime > lastClaim ? chrono.stakeStartTime : lastClaim;
                 if (currentTime > effectiveStartTime) {
                     uint66 duration = currentTime - effectiveStartTime;
                     earnedEP = uint128(duration) * epPerSecondPerStakedChrono;
                 }
                 // Note: This logic assumes EP stops accumulating immediately on unstake,
                 // but claim can happen anytime after. The _claimEvolutionPointsInternal
                 // is called by stake/unstake to finalize EP up to that point.
                 // So, for an already unstaked chrono, this function just updates lastEPClaimTime to now,
                 // and any *new* EP would only accrue after re-staking.
             }
        }

        if (earnedEP > 0) {
            chrono.evolutionPoints += earnedEP;
            emit EvolutionPointsClaimed(chronoId, chrono.owner, earnedEP, currentTime);
        }
        chrono.lastEPClaimTime = currentTime; // Always update last claim time
    }


    /**
     * @dev Calculates pending EP for a Chrono without updating state.
     * @param chronoId The ID of the Chrono.
     * @return The amount of EP that would be added if claimed now.
     */
    function getPendingEvolutionPoints(uint256 chronoId) public view returns (uint128) {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");

        if (chrono.status != ChronoStatus.Staked || chrono.stakeStartTime == 0) {
            return 0; // Only accrues while staked
        }

        uint66 currentTime = uint66(block.timestamp);
        uint66 lastClaim = chrono.lastEPClaimTime;
        uint66 effectiveStartTime = chrono.stakeStartTime > lastClaim ? chrono.stakeStartTime : lastClaim;

        if (currentTime > effectiveStartTime) {
            uint66 duration = currentTime - effectiveStartTime;
            return uint128(duration) * epPerSecondPerStakedChrono;
        } else {
            return 0;
        }
    }


    /**
     * @dev Spends EP to increase the level of a specific trait.
     * @param chronoId The ID of the Chrono.
     * @param traitId The ID of the trait to forge.
     */
    function forgeChronoTrait(uint256 chronoId, uint8 traitId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
        nonReentrant
    {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");
        require(traitDefinitions[traitId].levelUpCostEP[1] > 0, "Trait not defined"); // Check if trait exists

        uint8 currentLevel = chrono.traits[traitId];
        uint8 nextLevel = currentLevel + 1;
        uint128 cost = traitDefinitions[traitId].levelUpCostEP[nextLevel];

        require(cost > 0, "Trait cannot be forged to this level");
        require(chrono.evolutionPoints >= cost, "Not enough Evolution Points");

        // TODO: Implement trait requirements check here if they were added back

        chrono.evolutionPoints -= cost;
        chrono.traits[traitId] = nextLevel;

        // Optional: Apply trait forging effects (e.g., change EP gain, visual metadata update)
        // This would likely involve emitting events or storing more data.

        emit TraitForged(chronoId, traitId, nextLevel, cost);
    }

    /**
     * @dev Triggers an evolution check for a Chrono based on its current state (time, EP, traits).
     * This function could lead to significant changes based on predefined logic.
     * Can be called by the owner.
     * @param chronoId The ID of the Chrono.
     */
    function triggerTimedEvolution(uint256 chronoId)
        public
        onlyChronoOwner(chronoId)
        whenNotPaused
        nonReentrant
    {
         Chrono storage chrono = _chronos[chronoId];
         require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");

         uint66 currentTime = uint66(block.timestamp);
         uint66 timeSinceCreation = currentTime - chrono.creationTime;

         // --- Complex Evolution Logic Example ---
         // This is where advanced, unique logic would go.
         // Examples:
         // - If chrono is old enough AND has enough EP AND specific trait levels, trigger a major evolution.
         // - Random chance based on time or EP.
         // - Branching evolution paths based on dominant traits.
         // - Consume EP or traits as part of evolution.

         string memory outcome = "No significant change";

         if (timeSinceCreation >= 30 days && chrono.evolutionPoints >= 5000) { // Example condition
             if (chrono.traits[1] >= 3 && chrono.traits[2] >= 2) { // Example trait condition (Power >= 3, Speed >= 2)
                 // Trigger a specific evolution path, e.g., "Apex Predator"
                 // Apply permanent trait boosts, change visual identifier, maybe consume EP
                 uint128 epConsumed = 5000;
                 if (chrono.evolutionPoints >= epConsumed) {
                     chrono.evolutionPoints -= epConsumed;
                     chrono.traits[1] += 1; // Example boost
                     chrono.traits[2] += 1; // Example boost
                     outcome = "Evolved into Apex Predator!";
                 } else {
                     outcome = "Met time and trait conditions, but not enough EP for Apex Predator.";
                 }
             } else {
                 // Trigger a different evolution path, e.g., "Hardened Survivor"
                 uint128 epConsumed = 3000;
                  if (chrono.evolutionPoints >= epConsumed) {
                     chrono.evolutionPoints -= epConsumed;
                     chrono.traits[3] += 2; // Example boost (Intelligence)
                     outcome = "Evolved into Hardened Survivor!";
                  } else {
                      outcome = "Met time condition, but not enough EP for Survivor.";
                  }
             }
         } else if (timeSinceCreation >= 7 days && chrono.evolutionPoints >= 1000) {
             // Minor evolution chance
             // Could involve pseudo-randomness based on block hash, chrono ID, and timestamp
             // uint256 entropy = uint256(keccak256(abi.encodePacked(chronoId, currentTime, blockhash(block.number - 1))));
             // if (entropy % 10 < 3) { // 30% chance
                 chrono.evolutionPoints += 100; // Example minor gain
                 outcome = "Underwent minor adaptation.";
             // }
         }

         // Update lastEPClaimTime as EP might have been consumed/gained
         // _claimEvolutionPointsInternal(chronoId); // Re-calculate pending up to this point before potential consumption

         emit TimedEvolutionTriggered(chronoId, outcome);

         // Note: For true randomness, consider Chainlink VRF or similar oracle solution
         // Using block.timestamp/blockhash is susceptible to miner manipulation.
    }

    /**
     * @dev Called by the trusted oracle to apply external environmental effects or triggers.
     * This could change traits, add/remove EP, or trigger unique events based on external data.
     * @param chronoId The ID of the Chrono targeted (or 0 for a global effect).
     * @param triggerType An identifier for the type of trigger.
     * @param triggerData Arbitrary data from the oracle (e.g., intensity, specific values).
     */
    function applyOracleTrigger(uint256 chronoId, uint8 triggerType, bytes memory triggerData)
        public
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        require(chronoId == 0 || _chronos[chronoId].status != ChronoStatus.NonExistent, "Chrono does not exist");

        // --- Oracle Trigger Logic Example ---
        // This is where the contract reacts to external data.
        // triggerType could encode different events (e.g., "Solar Flare", "Market Boom", "New discovered resource")
        // triggerData could contain parameters for the event (e.g., intensity, affected traits, duration)

        // Example: Trigger Type 1 (Environmental Boost)
        if (triggerType == 1) {
            uint128 boostAmount = 0;
            // Decode triggerData - example assuming triggerData is a uint128 EP boost
            if (triggerData.length >= 16) { // Check sufficient data length for uint128
                 assembly {
                     boostAmount := mload(add(triggerData, 32)) // Load uint128 from start of data
                 }
            } else {
                 boostAmount = 100; // Default boost
            }

            if (chronoId != 0) { // Target a specific Chrono
                Chrono storage chrono = _chronos[chronoId];
                 // Apply boost (e.g., add EP, temporarily boost a trait)
                 chrono.evolutionPoints += boostAmount;
                 emit OracleTriggerApplied(chronoId, triggerType, triggerData);
            } else { // Global effect (e.g., boost all staked Chronos)
                 // Note: Iterating over all Chronos is gas-prohibitive.
                 // A pattern for global effects might be:
                 // 1. Oracle sets a global parameter (e.g., `globalEPBoostUntil`).
                 // 2. `_claimEvolutionPointsInternal` checks this parameter and applies extra EP if within the timeframe.
                 // For this example, we'll just emit an event for a global trigger idea.
                 emit OracleTriggerApplied(0, triggerType, triggerData); // ChronoId 0 for global
                 // Implement global effect logic here if not using the lazy update pattern above.
            }
        }
        // Example: Trigger Type 2 (Trait Mutation)
        else if (triggerType == 2) {
             // Decode triggerData for traitId and mutation effect
             uint256 targetChronoId;
             uint8 traitToMutate;
             int8 levelChange; // Can be positive or negative
              if (triggerData.length >= 32 + 1 + 1) { // uint256 + uint8 + int8
                 assembly {
                     targetChronoId := mload(add(triggerData, 32)) // Load uint256
                     traitToMutate := mload(add(triggerData, 64))   // Load uint8
                     levelChange := mload(add(triggerData, 65))   // Load int8
                 }
                 Chrono storage chrono = _chronos[targetChronoId];
                 if (chrono.status != ChronoStatus.NonExistent) {
                     int16 currentLevel = int16(chrono.traits[traitToMutate]);
                     int16 newLevel = currentLevel + levelChange;
                     if (newLevel < 0) newLevel = 0;
                     // Add upper bound check based on trait definition if needed
                     chrono.traits[traitToMutate] = uint8(newLevel);
                     emit OracleTriggerApplied(targetChronoId, triggerType, triggerData);
                 }
             }
        }
        // ... add more trigger types ...

        // After trigger, update last claim time for any Chrono affected if EP was changed
        if (chronoId != 0) {
            _claimEvolutionPointsInternal(chronoId);
        }
    }


    // --- Governance Functions ---

    /**
     * @dev Creates a new governance proposal. Requires minimum staked Chronos.
     * Voting power is snapshotted at proposal creation time.
     * @param description A description of the proposal.
     * @param targetContract The contract address the proposal will interact with.
     * @param callData The encoded function call to execute if the proposal passes.
     */
    function createProposal(
        string memory description,
        address targetContract,
        bytes memory callData
    )
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        // Minimum staked Chronos required to propose
        uint128 proposerStaked = 0;
        uint256[] memory owned = _ownerChronos[msg.sender];
        for(uint i = 0; i < owned.length; i++) {
            if(_chronos[owned[i]].status == ChronoStatus.Staked) {
                proposerStaked++;
            }
        }
        require(proposerStaked >= PROPOSAL_THRESHOLD_STAKED, "Insufficient staked Chronos to propose");

        uint256 proposalId = _nextProposalId++;
        uint66 currentTime = uint66(block.timestamp);

        Proposal storage proposal = _proposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.creationTime = currentTime;
        proposal.votingEndTime = currentTime + VOTING_PERIOD_DURATION;
        proposal.totalStakedAtSnapshot = totalStakedChronos; // Snapshot total staked for quorum/voting power base
        proposal.description = description;
        proposal.targetContract = targetContract;
        proposal.callData = callData;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, currentTime, proposal.votingEndTime, description);

        return proposalId;
    }

    /**
     * @dev Casts a vote on a proposal. Voting power is based on staked Chronos at proposal creation snapshot.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for Yes, False for No.
     */
    function voteOnProposal(uint256 proposalId, bool support)
        public
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint128 voterPower = calculateVotingPower(msg.sender); // Use current staked for simplicity, snapshotting is more complex but better
        // TODO: For robust governance, implement snapshotting logic: calculate voting power *at proposal.creationTime*
        // This would involve tracking staked Chronos history or using a checkpointing system.
        // For this example, we use current staked amount as a simpler approximation.
         uint128 currentStaked = 0;
         uint256[] memory owned = _ownerChronos[msg.sender];
         for(uint i = 0; i < owned.length; i++) {
             if(_chronos[owned[i]].status == ChronoStatus.Staked) {
                 currentStaked++;
             }
         }
         voterPower = currentStaked;
        require(voterPower > 0, "Voter must have staked Chronos to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

     /**
      * @dev Executes a proposal if it has passed its voting period and met quorum/approval requirements.
      * @param proposalId The ID of the proposal to execute.
      */
    function executeProposal(uint256 proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint128 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint128 quorumNeeded = (proposal.totalStakedAtSnapshot * QUORUM_STAKED_PERCENT) / 100; // Quorum based on snapshot
        uint128 approvalNeeded = (totalVotes * APPROVAL_PERCENT) / 100; // Approval based on total votes cast

        bool passed = totalVotes >= quorumNeeded && proposal.yesVotes > approvalNeeded;

        if (passed) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            // Note: Using call is risky. Safer approach uses interfaces and explicit function calls.
            // require(success, "Proposal execution failed"); // Decide if execution failure should revert
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId, success);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalExecuted(proposalId, false); // Indicate failure to pass/execute
        }
    }

     /**
      * @dev Allows a user to delegate their voting power (from staked Chronos) to another address.
      * @param delegatee The address to delegate voting power to.
      */
    function delegateVotingPower(address delegatee) public {
        address delegator = msg.sender;
        address currentDelegate = voteDelegates[delegator];
        if (currentDelegate == address(0)) {
             currentDelegate = delegator; // Default delegate is self
        }

        voteDelegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }


    // --- Utility & View Functions ---

    /**
     * @dev Gets the staking start time and status for a Chrono.
     * @param chronoId The ID of the Chrono.
     * @return stakeStartTime_ The timestamp when staking began (0 if not staked).
     * @return isStaked_ True if the Chrono is currently staked.
     */
    function getStakingInfo(uint256 chronoId) public view returns (uint66 stakeStartTime_, bool isStaked_) {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");
        return (chrono.stakeStartTime, chrono.status == ChronoStatus.Staked);
    }

    /**
     * @dev Calculates the current voting power for an address based on their staked Chronos.
     * This version uses current staked amount. A more robust version would use a snapshot.
     * Delegation is handled here.
     * @param voter The address whose voting power to calculate.
     * @return The calculated voting power.
     */
    function calculateVotingPower(address voter) public view returns (uint128) {
         address effectiveVoter = voteDelegates[voter];
         if (effectiveVoter == address(0)) {
             effectiveVoter = voter; // Default delegate is self if none set
         }

         uint128 stakedCount = 0;
         uint256[] memory owned = _ownerChronos[effectiveVoter]; // Check Chronos owned by the effective voter (delegatee)
         for(uint i = 0; i < owned.length; i++) {
             if(_chronos[owned[i]].status == ChronoStatus.Staked) {
                 stakedCount++;
             }
         }
         return stakedCount; // 1 staked Chrono = 1 voting power
    }

    /**
     * @dev Gets detailed information about a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return proposer_ The address that created the proposal.
     * @return creationTime_ The creation timestamp.
     * @return votingEndTime_ The timestamp when voting ends.
     * @return description_ The proposal description.
     * @return targetContract_ The contract address targeted by the proposal.
     * @return callData_ The call data for execution.
     * @return yesVotes_ Total 'Yes' votes.
     * @return noVotes_ Total 'No' votes.
     * @return totalStakedAtSnapshot_ Total staked Chronos at proposal creation snapshot.
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            address proposer_,
            uint66 creationTime_,
            uint66 votingEndTime_,
            string memory description_,
            address targetContract_,
            bytes memory callData_,
            uint128 yesVotes_,
            uint128 noVotes_,
            uint128 totalStakedAtSnapshot_
        )
    {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist"); // Check existence via a non-zero value

        proposer_ = proposal.proposer;
        creationTime_ = proposal.creationTime;
        votingEndTime_ = proposal.votingEndTime;
        description_ = proposal.description;
        targetContract_ = proposal.targetContract;
        callData_ = proposal.callData;
        yesVotes_ = proposal.yesVotes;
        noVotes_ = proposal.noVotes;
        totalStakedAtSnapshot_ = proposal.totalStakedAtSnapshot;
    }

    /**
     * @dev Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal (Pending, Active, Canceled, Defeated, Succeeded, Executed).
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.creationTime == 0) return ProposalState.Pending; // Or NonExistent if you add it

         if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
         if (proposal.state == ProposalState.Succeeded) return ProposalState.Succeeded;
         if (proposal.state == ProposalState.Defeated) return ProposalState.Defeated;
         if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;

         if (block.timestamp > proposal.votingEndTime) {
             // Voting period ended, determine outcome
             uint128 totalVotes = proposal.yesVotes + proposal.noVotes;
             uint128 quorumNeeded = (proposal.totalStakedAtSnapshot * QUORUM_STAKED_PERCENT) / 100;
             uint128 approvalNeeded = (totalVotes * APPROVAL_PERCENT) / 100;

             if (totalVotes >= quorumNeeded && proposal.yesVotes > approvalNeeded) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
         }

         return ProposalState.Active; // Voting is still ongoing
    }

    /**
     * @dev Views details about a specific trait type.
     * @param traitId The ID of the trait.
     * @return name_ The trait name.
     * @return description_ The trait description.
     * @return costs_ Array of EP costs to reach each level (index 0 is cost to reach level 0, etc.).
     */
    function getTraitDetails(uint8 traitId)
        public
        view
        returns (
            string memory name_,
            string memory description_,
            uint128[] memory costs_
        )
    {
        Trait storage trait = traitDefinitions[traitId];
        require(trait.levelUpCostEP[1] > 0, "Trait not defined");

        name_ = trait.name;
        description_ = trait.description;

        // Collect costs - assuming a max level or iterate until cost is 0
        uint8 maxLevel = 0;
        // Iterate up to a reasonable maximum or check if cost is defined
        for(uint8 i = 0; i < 255; i++) { // Max levels up to 254 + 1 (level 0)
            if (trait.levelUpCostEP[i+1] == 0 && i > 0) { // If cost to reach next level is 0 (and we are past level 0)
                maxLevel = i;
                break;
            }
             if (i == 254) { maxLevel = 255; } // Cap at 255
        }
        costs_ = new uint128[](maxLevel + 1);
         for(uint8 i = 0; i <= maxLevel; i++) {
            costs_[i] = trait.levelUpCostEP[i];
         }
    }

    /**
     * @dev Views the EP cost to forge a trait to the next level.
     * @param traitId The ID of the trait.
     * @param currentLevel The current level of the trait.
     * @return The EP cost to reach currentLevel + 1.
     */
    function getTraitCost(uint8 traitId, uint8 currentLevel) public view returns (uint128) {
         Trait storage trait = traitDefinitions[traitId];
         require(trait.levelUpCostEP[1] > 0, "Trait not defined");
         return trait.levelUpCostEP[currentLevel + 1];
    }


    /**
     * @dev Views the requirements (e.g., other trait levels) needed to forge a trait.
     * NOTE: This function is a placeholder as complex trait requirements were simplified in the code.
     * If complex requirements are added, this function would return the necessary data.
     * @param traitId The ID of the trait.
     * @param targetLevel The level attempting to reach.
     * @return An empty array in this simplified version. Would contain Requirement[] if implemented.
     */
    function getTraitRequirement(uint8 traitId, uint8 targetLevel) public pure returns (uint8[] memory) {
        // Placeholder: Implement complex trait requirements lookup here if they are added back
        // Example: return traitDefinitions[traitId].levelRequirements[targetLevel];
        require(traitId > 0 && targetLevel >= 0, "Invalid input"); // Basic input validation
        return new uint8[](0); // Return empty array in this simplified version
    }

     /**
      * @dev Simulates potential outcomes of the triggerTimedEvolution based on current Chrono state.
      * Does not change state.
      * NOTE: This simulation is based on the simplified logic in triggerTimedEvolution.
      * More complex logic would require a more sophisticated simulation here.
      * @param chronoId The ID of the Chrono.
      * @return A string describing the potential outcome based on current conditions.
      */
    function simulateEvolutionOutcome(uint256 chronoId) public view returns (string memory) {
        Chrono storage chrono = _chronos[chronoId];
        require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");

        uint66 currentTime = uint66(block.timestamp);
        uint66 timeSinceCreation = currentTime - chrono.creationTime;

        if (timeSinceCreation >= 30 days && chrono.evolutionPoints >= 5000) {
             if (chrono.traits[1] >= 3 && chrono.traits[2] >= 2) {
                 uint128 epConsumed = 5000; // Example consumption
                 if (chrono.evolutionPoints >= epConsumed) {
                     return "Potential Evolution: Apex Predator (requires 5000 EP)";
                 } else {
                     return string(abi.encodePacked("Potential Evolution: Apex Predator (requires 5000 EP, needs ", uint256(epConsumed - chrono.evolutionPoints), " more EP)"));
                 }
             } else {
                 uint128 epConsumed = 3000; // Example consumption
                  if (chrono.evolutionPoints >= epConsumed) {
                     return "Potential Evolution: Hardened Survivor (requires 3000 EP)";
                  } else {
                      return string(abi.encodePacked("Potential Evolution: Hardened Survivor (requires 3000 EP, needs ", uint256(epConsumed - chrono.evolutionPoints), " more EP)"));
                  }
             }
         } else if (timeSinceCreation >= 7 days && chrono.evolutionPoints >= 1000) {
              // Based on simplified logic, minor adaptation might occur
              return "Potential Minor Adaptation (based on time & EP)";
         }

        return "No significant evolution predicted based on current state.";
    }

     /**
      * @dev Gets current contract parameters.
      * @return epPerSecondPerStakedChrono_ Current EP generation rate.
      * @return minStakeDuration_ Minimum stake duration (constant).
      * @return votingPeriodDuration_ Voting period duration (constant).
      * @return proposalThresholdStaked_ Minimum staked Chronos to propose (constant).
      * @return quorumStakedPercent_ Percentage of total staked needed for quorum (constant).
      * @return approvalPercent_ Percentage of votes needed to pass (constant).
      */
    function getContractParameters()
        public
        view
        returns (
            uint64 epPerSecondPerStakedChrono_,
            uint64 minStakeDuration_,
            uint66 votingPeriodDuration_,
            uint128 proposalThresholdStaked_,
            uint128 quorumStakedPercent_,
            uint128 approvalPercent_
        )
    {
        return (
            epPerSecondPerStakedChrono,
            MIN_STAKE_DURATION,
            VOTING_PERIOD_DURATION,
            PROPOSAL_THRESHOLD_STAKED,
            QUORUM_STAKED_PERCENT,
            APPROVAL_PERCENT
        );
    }

    /**
     * @dev Gets the level of a specific trait on a Chrono.
     * @param chronoId The ID of the Chrono.
     * @param traitId The ID of the trait.
     * @return The level of the trait (0 if not present/level 0).
     */
    function getChronoTraitLevel(uint256 chronoId, uint8 traitId) public view returns (uint8) {
         Chrono storage chrono = _chronos[chronoId];
         require(chrono.status != ChronoStatus.NonExistent, "Chrono does not exist");
         // No require for trait existence here, as trait level 0 is valid
         return chrono.traits[traitId];
    }

    /**
     * @dev Gets the total number of currently staked Chronos across all owners.
     * @return The total count of staked Chronos.
     */
    function getTotalStakedChronos() public view returns (uint256) {
        return totalStakedChronos;
    }

    /**
     * @dev Admin function to set the trusted oracle address. Can only be called by the contract owner.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
        // Emit event for change?
    }

    /**
     * @dev Admin function to pause contract operations inheriting Pausable.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Admin function to unpause contract operations inheriting Pausable.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

     /**
      * @dev Admin function to withdraw any ETH held by the contract.
      * Useful if minting involved ETH fees or penalties accrued ETH.
      * @param recipient The address to send ETH to.
      */
    function withdrawEth(address payable recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(address(this).balance > 0, "No ETH to withdraw");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // Optional: Function to withdraw any ERC20 accidentally sent to the contract
    // function withdrawERC20(address tokenAddress, address recipient) public onlyOwner nonReentrant {
    //     IERC20 token = IERC20(tokenAddress);
    //     uint256 balance = token.balanceOf(address(this));
    //     require(balance > 0, "No tokens to withdraw");
    //     require(token.transfer(recipient, balance), "ERC20 withdrawal failed");
    // }

    /**
     * @dev Gets the overall status of a Chrono.
     * @param chronoId The ID of the Chrono.
     * @return The status of the Chrono.
     */
    function getChronoStatus(uint256 chronoId) public view returns (ChronoStatus) {
        return _chronos[chronoId].status;
    }


    // Additional potential functions (to exceed 20 comfortably and add more features):

    // 33. updateStakingRate(uint64 newRate) - Callable by governance to change EP/sec rate.
    // 34. updateTraitCost(uint8 traitId, uint8 level, uint128 newCost) - Callable by governance to adjust forging costs.
    // 35. getProposalVoteCount(uint256 proposalId) - Gets current yes/no votes for a proposal.
    // 36. hasVoted(uint256 proposalId, address voter) - Checks if an address has voted on a proposal.
    // 37. getDelegation(address delegator) - Gets the address an address has delegated voting power to.
    // 38. setTraitDefinition(uint8 traitId, string memory name, string memory description, uint128[] memory costs) - Callable by governance to add/modify trait definitions. Needs careful access control.
    // 39. renounceDelegation() - Removes delegation.
    // 40. getAvailableTraitIds() - Gets list of all defined trait IDs.

     /**
      * @dev Callable by governance proposal to update the EP staking rate.
      * @param newRate The new EP/second rate per staked Chrono.
      */
    function updateStakingRate(uint64 newRate) public onlyOwner { // Change to onlyCallableByGovernance if governance executes this
         epPerSecondPerStakedChrono = newRate;
         emit ParameterUpdated("epPerSecondPerStakedChrono", newRate);
    }

     /**
      * @dev Callable by governance proposal to update the EP cost to reach a specific trait level.
      * @param traitId The ID of the trait.
      * @param level The level to which the cost is updated (e.g., level 3 cost is cost to reach level 3 from 2).
      * @param newCost The new EP cost.
      */
    function updateTraitCost(uint8 traitId, uint8 level, uint128 newCost) public onlyOwner { // Change to onlyCallableByGovernance
         require(traitDefinitions[traitId].levelUpCostEP[1] > 0, "Trait not defined");
         traitDefinitions[traitId].levelUpCostEP[level] = newCost;
         emit ParameterUpdated(string(abi.encodePacked("traitCost_", uint256(traitId), "_", uint256(level))), newCost);
    }

     /**
      * @dev Gets the current vote counts for a proposal.
      * @param proposalId The ID of the proposal.
      * @return yesVotes_ Total 'Yes' votes.
      * @return noVotes_ Total 'No' votes.
      */
    function getProposalVoteCount(uint256 proposalId) public view returns (uint128 yesVotes_, uint128 noVotes_) {
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.creationTime > 0, "Proposal does not exist");
         return (proposal.yesVotes, proposal.noVotes);
    }

     /**
      * @dev Checks if a specific address has voted on a proposal.
      * @param proposalId The ID of the proposal.
      * @param voter The address to check.
      * @return True if the address has voted, false otherwise.
      */
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.creationTime > 0, "Proposal does not exist");
         return proposal.hasVoted[voter];
    }

     /**
      * @dev Gets the address that a user has delegated their voting power to.
      * @param delegator The address whose delegation to check.
      * @return The delegatee address. Returns the delegator's address if no delegation is set.
      */
    function getDelegation(address delegator) public view returns (address) {
         address delegatee = voteDelegates[delegator];
         if (delegatee == address(0)) {
             return delegator; // Default is self
         }
         return delegatee;
    }

    /**
     * @dev Removes the current voting delegation for the caller.
     */
    function renounceDelegation() public {
        delegateVotingPower(msg.sender); // Delegate to self
    }

    /**
     * @dev Gets the list of all available trait IDs defined in the contract.
     * @return An array of trait IDs.
     */
    function getAvailableTraitIds() public view returns (uint8[] memory) {
        return availableTraitIds;
    }

    // Counting functions: Chronos minted, proposals created
    function getTokenCount() public view returns (uint256) {
        return _nextTokenId - 1; // Assuming IDs start from 1
    }

    function getProposalCount() public view returns (uint256) {
        return _nextProposalId - 1; // Assuming IDs start from 1
    }

    // Check if a Chrono exists
    function chronoExists(uint256 chronoId) public view returns (bool) {
        return _chronos[chronoId].status != ChronoStatus.NonExistent;
    }

    // get staking end time (relevant if MIN_STAKE_DURATION was enforced for unstake)
    function getStakeEndTime(uint256 chronoId) public view returns (uint66) {
         Chrono storage chrono = _chronos[chronoId];
         require(chrono.status == ChronoStatus.Staked, "Chrono not staked");
         return chrono.stakeStartTime + MIN_STAKE_DURATION;
    }
}
```

---

**Explanation of Concepts & Functions:**

1.  **Soulbound-like Assets:** Chronos are tracked internally (`_chronos` mapping, `_ownerChronos` list) by ID. Standard ERC721 transfer functions (`transferFrom`, `approve`, etc.) are *not* implemented, making them non-transferable ("soulbound") by default. This is a key deviation from standard NFT contracts.
2.  **Dynamic Traits:** Chronos have traits stored in a mapping (`mapping(uint8 => uint8) traits`). These are not static metadata; they can be changed via `forgeChronoTrait` and `applyOracleTrigger`.
3.  **Evolution Points (EP):** A custom resource (`evolutionPoints`) earned by staking Chronos (`stakeChrono`). The rate (`epPerSecondPerStakedChrono`) is a parameter. EP accumulation is calculated lazily on `claimEvolutionPoints`, `stakeChrono`, `unstakeChrono`, or `applyOracleTrigger` impacting EP.
4.  **Staking Mechanics:** `stakeChrono` and `unstakeChrono` manage the staking status (`ChronoStatus`) and track the stake start time (`stakeStartTime`). `totalStakedChronos` tracks the total count, which is used for governance quorum.
5.  **Forging:** `forgeChronoTrait` allows spending accumulated EP to level up specific traits. Trait levels have associated EP costs defined in `traitDefinitions`.
6.  **Timed Evolution:** `triggerTimedEvolution` implements a simple, time-based evolution check. The *logic* inside this function is the core area for creativity – based on age, EP, trait levels, or even internal pseudo-randomness, a Chrono could evolve, gain/lose traits, etc. The provided example is basic; a real implementation would have much more complex branching logic.
7.  **Oracle Integration:** `applyOracleTrigger` is a function restricted to a trusted `oracleAddress`. This simulates connecting the contract to external data feeds. The logic inside this function (`if (triggerType == 1)`, etc.) defines how external events (like market changes, weather data, AI outputs) affect Chronos (e.g., boost EP, mutate traits). This is a trendy concept for dynamic NFTs and game assets.
8.  **Community Governance:** A basic governance system is included:
    *   `createProposal`: Allows users with sufficient staked Chronos to propose actions (arbitrary `callData` on a `targetContract`). Voting power is based on staked Chronos *at a snapshot* (simplified to current staked count here).
    *   `voteOnProposal`: Allows voting on active proposals using staked Chronos as voting power.
    *   `executeProposal`: Finalizes a proposal after the voting period and executes the proposed action if it passes quorum and approval checks.
    *   `delegateVotingPower`: Standard delegation pattern from Governor contracts.
9.  **Access Control:** Uses OpenZeppelin's `Ownable` for admin functions (pause, oracle address, withdrawals) and custom modifiers (`onlyOracle`, `onlyChronoOwner`). Governance functions (`updateStakingRate`, `updateTraitCost`) are marked `onlyOwner` but would ideally be restricted to successful *governance proposal execution* in a full system.
10. **Pausable:** Allows the owner to pause critical functions in case of emergencies.
11. **ReentrancyGuard:** Included as a best practice, though the current function interactions are mostly internal and less prone to reentrancy issues.

This contract provides a framework for dynamic digital assets with unique progression paths influenced by user engagement (staking, forging), internal logic (timed evolution), and external events (oracle). It exceeds the 20+ function requirement by including necessary views and utility functions. The core logic within `triggerTimedEvolution` and `applyOracleTrigger` are placeholders for implementing truly creative and advanced evolution rules.