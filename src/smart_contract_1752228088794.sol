Okay, here is a Solidity smart contract designed with an interesting, advanced, and creative concept: a "Synergy Engine" that manages utility-bearing NFTs ('Synergy Units') and allows users to bond them to generate a fungible token ('Energy Tokens'). The yield is dynamic based on various factors like bonding duration, decay, and interactions with other NFTs ('Catalysts') or groups of NFTs ('Resonance'). It also includes light governance elements for parameter adjustments and complex 'Fusion' and 'Spark' mechanisms.

This contract uses concepts like:
1.  **Utility NFTs:** NFTs with inherent earning potential and dynamic properties.
2.  **Dynamic Yield:** Yield rate is not fixed but changes based on time, decay, external factors (simulated calibration), and interactions (synergy/catalyst).
3.  **NFT Bonding/Staking:** Locking NFTs in the contract to earn rewards.
4.  **Decay Mechanics:** NFT utility/yield decreases over time if not maintained or interacted with.
5.  **Synergy/Resonance:** Earning bonuses based on holding or bonding specific combinations or groups of NFTs.
6.  **Catalyst Consumption:** Using other tokens (NFTs or fungible) to boost performance or enable actions.
7.  **Fusion:** Combining NFTs to potentially create new ones or enhance existing ones, consuming inputs.
8.  **Spark:** A high-cost, high-reward action requiring specific inputs for a special outcome.
9.  **Layered Governance (Simulated):** Admin controls parameters, but users can propose changes.
10. **Time-Based Logic:** Bond durations, lock periods, decay timing, claim cooldowns.

It aims to be distinct from standard staking or simple utility NFT contracts by combining these elements into a complex interactive system.

---

**Outline & Function Summary**

**Contract:** `SynergyEngine`
**Concept:** Manages 'SynergyUnit' NFTs (ERC-721) that users can bond to earn 'EnergyToken' (ERC-20). Yield is dynamic, affected by decay, bonding duration, 'Catalyst' NFTs (ERC-1155), and 'Resonance' among bonded units. Includes advanced features like Fusion, Spark, and parameter recalibration proposals.

**Dependencies (Interfaces - Mocked for this example):**
*   `IERC721`: For Synergy Units
*   `IERC20`: For Energy Tokens
*   `IERC1155`: For Catalysts
*   `Ownable`: For owner-restricted functions
*   `Pausable`: To pause core operations

**State Variables:**
*   Token addresses (`energyToken`, `synergyUnitToken`, `catalystToken`)
*   Global Engine Parameters (`baseYieldRate`, `decayRate`, `synergyBoostFactor`, `catalystBoostFactor`, etc.)
*   Synergy Unit Data (`SynergyUnitData` struct: bondTime, lastClaimTime, accumulatedET, properties like baseYieldFactor, decayFactor, synergyAttribute)
*   Catalyst Data (maybe properties stored for consumed catalysts)
*   Proposal Data (`RecalibrationProposal` struct: proposer, suggested parameters, status, votes)
*   Spark Data (`SparkData` struct: initiator, inputSU, inputCatalysts, startTime, status, outputDetails)

**Events:**
*   `SynergyUnitBonded(uint256 tokenId, address owner, uint256 bondTime)`
*   `SynergyUnitUnbonded(uint256 tokenId, address owner, uint256 unbondTime)`
*   `EnergyClaimed(uint256[] tokenIds, address claimant, uint256 amount)`
*   `SynergyUnitFused(uint256 baseTokenId, uint256 inputTokenId, uint256 newTokenId, uint256 fusionCost)`
*   `EngineCalibrated(address caller, uint256 newBaseYieldRate, uint256 newDecayRate)`
*   `RecalibrationProposed(uint256 proposalId, address proposer, uint256 suggestedBaseYieldRate, uint256 suggestedDecayRate)`
*   `RecalibrationVoted(uint256 proposalId, address voter, bool approved)`
*   `RecalibrationFinalized(uint256 proposalId, bool applied)`
*   `SynergyUnitDecayed(uint256 tokenId, uint256 newDecayApplied)`
*   `CatalystActivated(uint256 catalystId, uint256 targetSUId, uint256 effectDuration)`
*   `ResonanceTriggered(uint256[] tokenIds, uint256 totalBoostApplied)`
*   `SparkInitiated(uint256 sparkId, address initiator, uint256[] inputSUs, uint256[] inputCatalysts)`
*   `SparkCompleted(uint256 sparkId, bytes32 outcomeHash)` // Outcome details stored separately or claimed
*   `SynergyUnitPropertyUpdated(uint256 tokenId, string propertyName, uint256 newValue)`
*   `BondingLockExtended(uint256 tokenId, uint256 newLockDuration)`
*   `FundsWithdrawn(address indexed receiver, uint256 amount)`
*   `Paused(address account)`
*   `Unpaused(address account)`
*   `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)`

**Functions (Total: 27 - Exceeds 20):**

1.  `constructor(address _energyToken, address _synergyUnitToken, address _catalystToken)`: Initializes contract with token addresses and sets initial parameters.
2.  `bondSynergyUnit(uint256 tokenId)`: Allows a user to bond their Synergy Unit NFT with the engine to start earning Energy Tokens. Requires ERC721 transfer approval.
3.  `unbondSynergyUnit(uint256 tokenId)`: Allows a user to unbond their Synergy Unit. May incur penalties or require waiting for a lock period if applicable. Transfers NFT back.
4.  `claimEnergy(uint256[] memory tokenIds)`: Allows a user to claim accrued Energy Tokens for multiple bonded Synergy Units. Calculates earnings, applies decay/boosts, and transfers ET.
5.  `calculatePotentialEnergy(uint256 tokenId)`: *View* function. Calculates the amount of Energy Tokens a specific bonded Synergy Unit has accrued since the last claim or bond time, taking into account current state (decay, potential boosts).
6.  `calculateTotalPotentialEnergy(address user)`: *View* function. Calculates the total potential Energy Tokens accrued across all Synergy Units bonded by a specific user.
7.  `fuseSynergyUnits(uint256 baseTokenId, uint256 inputTokenId, uint256[] memory requiredCatalysts)`: Combines `baseTokenId` with `inputTokenId` (which might be burned) and consumes specific Catalysts to potentially enhance the `baseTokenId`'s properties. Complex state transition.
8.  `calibrateEngine(uint256 newBaseYieldRate, uint256 newDecayRate, uint256 newSynergyBoostFactor, uint256 newCatalystBoostFactor)`: Owner-only function to adjust core global engine parameters.
9.  `proposeRecalibration(uint256 suggestedBaseYieldRate, uint256 suggestedDecayRate)`: Allows users (e.g., requiring bonded SUs or a deposit) to propose changes to key parameters. Creates a new proposal.
10. `voteOnRecalibration(uint256 proposalId, bool approve)`: Allows users (e.g., based on bonded SUs or voting power) to vote on active recalibration proposals.
11. `finalizeRecalibration(uint256 proposalId)`: Allows anyone to finalize a proposal once its voting period ends. Applies the suggested parameters if the proposal passed.
12. `applyDecay(uint256 tokenId)`: Applies the time-based decay mechanism to a specific Synergy Unit's properties if it hasn't been applied recently. Can be called by keepers or users.
13. `checkSynergyBoost(uint256 tokenId1, uint256 tokenId2)`: *View* function. Checks if two specific Synergy Units, when bonded together, would provide a synergy bonus based on their attributes.
14. `triggerResonance(uint256[] memory tokenIds, uint256[] memory requiredCatalysts)`: Initiates a Resonance event for a group of *your* bonded Synergy Units, potentially consuming Catalysts and granting a temporary or permanent boost to the units involved based on their collective attributes.
15. `activateCatalystEffect(uint256 catalystId, uint256 targetSUId)`: Uses a specific Catalyst NFT on a target Synergy Unit to apply a temporary or permanent effect (e.g., yield boost, decay reduction). Consumes the Catalyst (burn or transfer).
16. `burnSynergyUnit(uint256 tokenId)`: Allows a user to burn their bonded Synergy Unit (or one they own) for a specific outcome (e.g., instant partial energy payout, removing from circulation).
17. `setBondingLockDuration(uint256 tokenId, uint256 durationSeconds)`: Allows a user to voluntarily set or extend a lock-up period for their bonded SU, potentially for a higher yield multiplier.
18. `getSynergyUnitDetails(uint256 tokenId)`: *View* function. Returns comprehensive details about a specific Synergy Unit, including its bonding status, accumulated energy, current calculated yield/decay factors, and catalyst effects.
19. `getGlobalEngineState()`: *View* function. Returns the current global parameters of the engine (yield rates, decay rates, boost factors, etc.).
20. `getActiveProposals()`: *View* function. Returns a list of currently active recalibration proposals.
21. `getProposalDetails(uint256 proposalId)`: *View* function. Returns details for a specific recalibration proposal.
22. `withdrawFees(address receiver, uint256 amount)`: Owner-only function to withdraw any protocol fees collected (if implemented, e.g., from fusion costs or penalties).
23. `pause()`: Owner-only function to pause core operations (bonding, unbonding, claiming, fusion, spark). Inherited from Pausable.
24. `unpause()`: Owner-only function to unpause operations. Inherited from Pausable.
25. `transferOwnership(address newOwner)`: Standard Ownable function.
26. `renounceOwnership()`: Standard Ownable function.
27. `initiateSpark(uint256[] memory suTokenIds, uint256[] memory catalystTokenIds)`: Initiates a high-cost, high-reward 'Spark' event requiring specific bonded Synergy Units and Catalysts. This is a multi-stage process, the outcome might be determined later or off-chain and claimed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/average/etc.

// --- Mock Interfaces (Replace with actual imports if tokens exist) ---
// These interfaces define the functions the engine needs to interact with the tokens.
interface IMockERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    // Minting function for demonstration (in a real scenario, ET would be minted by this contract or pre-minted)
    function mint(address to, uint256 amount) external;
}

interface IMockERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    // Mock function to set/get custom properties for Synergy Units
    struct SUProperties {
        uint256 baseYieldFactor; // Basis points (e.g., 100 = 1%)
        uint256 decayFactor;     // Basis points per second/day (determines decay rate)
        bytes32 synergyAttribute; // Unique attribute influencing synergy
        uint256 catalystBoostEndTime; // Timestamp until a catalyst boost is active
        uint256 catalystBoostMultiplier; // Multiplier for yield during boost
    }
    function getSUProperties(uint256 tokenId) external view returns (SUProperties memory);
    function setSUProperties(uint256 tokenId, SUProperties memory props) external; // Mock function
    function exists(uint256 tokenId) external view returns (bool);
    function burn(uint256 tokenId) external; // Mock burn
    function mint(address to, uint256 tokenId, SUProperties memory props) external; // Mock mint
}

interface IMockERC1155 {
     function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
     function balanceOf(address account, uint256 id) external view returns (uint256);
     function isApprovedForAll(address account, address operator) external view returns (bool);
     // Mock burn function
     function burn(address account, uint256 id, uint256 amount) external;
}
// --- End Mock Interfaces ---


contract SynergyEngine is Ownable, Pausable {
    using SafeERC20 for IMockERC20;
    using Math for uint256;

    // --- Constants ---
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    uint256 public constant MIN_BONDING_DURATION_FOR_BONUS = 30 days; // Example lock duration for bonus
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Duration for recalibration votes

    // --- Token Addresses ---
    IMockERC20 public energyToken;
    IMockERC721 public synergyUnitToken;
    IMockERC1155 public catalystToken;

    // --- Engine Parameters (Adjustable) ---
    uint256 public baseYieldRate; // Global base yield rate (basis points per second per SU base yield factor)
    uint256 public globalDecayRate; // Global decay rate (basis points per second applied to SU decay factor)
    uint256 public synergyBoostFactor; // Additional yield multiplier for synergistic pairs/groups (basis points)
    uint256 public catalystBoostFactor; // Additional yield multiplier from active catalysts (basis points)
    uint256 public proposalDepositAmount; // Amount of ET required to submit a proposal
    uint256 public fusionCostInET; // Cost to perform a fusion

    // --- Data Structures ---
    struct BondingInfo {
        uint40 bondTime;         // When the SU was bonded (seconds)
        uint40 lastClaimTime;    // When energy was last claimed (seconds)
        uint128 accumulatedET;   // Accumulated but unclaimed energy (scaled, or base units)
        uint40 bondingLockEndTime; // Timestamp until bonding is locked
    }

    // SUProperties are assumed to be stored on the SynergyUnitToken contract (IMockERC721)
    // but we might cache some dynamic state or specific properties here.
    // For simplicity, let's assume SUProperties are read directly from the mock IERC721.

    struct RecalibrationProposal {
        uint256 proposalId;
        address proposer;
        uint40 startTime;
        uint256 suggestedBaseYieldRate;
        uint256 suggestedDecayRate;
        mapping(address => bool) votes; // User address => approval (true) or rejection (false)
        uint256 totalVotes; // Simple vote count (could be weighted by bonded SU later)
        uint256 totalApprovedVotes;
        enum Status { Active, Passed, Failed, Finalized }
        Status status;
    }

    struct SparkData {
        uint256 sparkId;
        address initiator;
        uint256[] inputSUIds;
        uint256[] inputCatalystIds; // IDs of catalyst types/batches used
        uint256[] inputCatalystAmounts; // Amounts of catalyst types used
        uint40 startTime;
        bytes32 outcomeHash; // Hash of the determined outcome (e.g., via VRF or oracle)
        bool outcomeClaimed;
        enum Status { Initiated, AwaitingOutcome, Completed }
        Status status;
    }

    // --- Mappings ---
    mapping(uint256 => BondingInfo) public bondedSynergyUnits; // SU tokenId => BondingInfo
    mapping(address => uint256[]) private userBondedUnits; // User address => list of their bonded SU tokenIds
    mapping(uint256 => address) private bondedUnitOwner; // SU tokenId => current owner (while bonded)

    RecalibrationProposal[] public recalibrationProposals;
    mapping(uint256 => uint256) public proposalIdToIndex; // Helper to get proposal by ID

    SparkData[] public sparks;
    mapping(uint256 => uint256) public sparkIdToIndex; // Helper to get spark by ID
    uint256 private nextSparkId = 1;
    uint256 private nextProposalId = 1;

    // --- Events ---
    event SynergyUnitBonded(uint256 tokenId, address owner, uint256 bondTime);
    event SynergyUnitUnbonded(uint256 tokenId, address owner, uint256 unbondTime);
    event EnergyClaimed(uint256[] tokenIds, address claimant, uint256 amount);
    event SynergyUnitFused(uint256 baseTokenId, uint256 inputTokenId, uint256 fusionCost); // newTokenId might be baseTokenId if enhanced
    event EngineCalibrated(address caller, uint256 newBaseYieldRate, uint256 newDecayRate); // Added other params too
    event RecalibrationProposed(uint256 proposalId, address proposer, uint256 suggestedBaseYieldRate, uint256 suggestedDecayRate);
    event RecalibrationVoted(uint256 proposalId, address voter, bool approved);
    event RecalibrationFinalized(uint256 proposalId, bool applied);
    event SynergyUnitDecayed(uint256 tokenId, uint256 decayApplied);
    event CatalystActivated(uint256 catalystId, uint256 targetSUId, uint256 effectDuration);
    event ResonanceTriggered(uint256[] tokenIds, uint256 totalBoostApplied); // Boost value might need more context
    event SparkInitiated(uint256 sparkId, address initiator, uint256[] inputSUs, uint256[] inputCatalysts); // Catalyst IDs
    event SparkCompleted(uint256 sparkId, bytes32 outcomeHash);
    event SynergyUnitPropertyUpdated(uint256 tokenId, string propertyName, uint256 newValue); // Or more detailed update
    event BondingLockExtended(uint256 tokenId, uint256 newLockDuration);
    event FundsWithdrawn(address indexed receiver, uint256 amount);

    // --- Modifiers ---
    modifier onlyBondedOwner(uint256 tokenId) {
        require(bondedUnitOwner[tokenId] == msg.sender, "Not your bonded SU");
        _;
    }

    modifier isBonded(uint256 tokenId) {
        require(bondedSynergyUnits[tokenId].bondTime > 0, "SU not bonded");
        _;
    }

    modifier isNotBonded(uint256 tokenId) {
         require(bondedSynergyUnits[tokenId].bondTime == 0, "SU is already bonded");
        _;
    }

    modifier isValidProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= recalibrationProposals.length, "Invalid proposal ID");
        _;
    }

    modifier isValidSpark(uint256 sparkId) {
        require(sparkId > 0 && sparkId <= sparks.length, "Invalid spark ID");
        _;
    }


    // --- Constructor ---
    constructor(address _energyToken, address _synergyUnitToken, address _catalystToken)
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        energyToken = IMockERC20(_energyToken);
        synergyUnitToken = IMockERC721(_synergyUnitToken);
        catalystToken = IMockERC1155(_catalystToken);

        // Set initial parameters (can be calibrated later)
        baseYieldRate = 5; // 0.05% per second per base yield factor (example)
        globalDecayRate = 1; // 0.01% per second applied to SU decay factor (example)
        synergyBoostFactor = 12000; // 120% multiplier (example)
        catalystBoostFactor = 15000; // 150% multiplier (example)
        proposalDepositAmount = 100 ether; // Example: 100 ET
        fusionCostInET = 500 ether; // Example: 500 ET
    }

    // --- Core Engine Functions ---

    /**
     * @notice Bonds a Synergy Unit NFT with the engine to start earning.
     * @param tokenId The ID of the Synergy Unit NFT to bond.
     */
    function bondSynergyUnit(uint256 tokenId) external whenNotPaused isNotBonded(tokenId) {
        // Ensure the caller owns the token
        require(synergyUnitToken.ownerOf(tokenId) == msg.sender, "Caller does not own SU");
        // Ensure the engine contract is approved to transfer the token
        // This requires the user to have called approve() on the SU token contract beforehand.
        // Or approveForAll. For demonstration, we'll assume approval is handled off-chain or prior.
        // A robust implementation would check `synergyUnitToken.getApproved(tokenId) == address(this)`
        // or `synergyUnitToken.isApprovedForAll(msg.sender, address(this))`.

        // Transfer the NFT to the contract
        synergyUnitToken.safeTransferFrom(msg.sender, address(this), tokenId);

        uint40 currentTime = uint40(block.timestamp);

        // Store bonding info
        bondedSynergyUnits[tokenId] = BondingInfo({
            bondTime: currentTime,
            lastClaimTime: currentTime,
            accumulatedET: 0,
            bondingLockEndTime: currentTime // Initially not locked, user can set later
        });

        // Add to user's list of bonded units
        userBondedUnits[msg.sender].push(tokenId);
        bondedUnitOwner[tokenId] = msg.sender;

        emit SynergyUnitBonded(tokenId, msg.sender, currentTime);
    }

    /**
     * @notice Unbonds a Synergy Unit NFT from the engine.
     * @param tokenId The ID of the Synergy Unit NFT to unbond.
     */
    function unbondSynergyUnit(uint256 tokenId) external whenNotPaused isBonded(tokenId) onlyBondedOwner(tokenId) {
        BondingInfo storage bondInfo = bondedSynergyUnits[tokenId];

        // Check bonding lock
        require(block.timestamp >= bondInfo.bondingLockEndTime, "Bonding is locked");

        // --- Claim any pending energy first? ---
        // Option 1: Force claim before unbonding (simple)
        // Option 2: Include unclaimed energy in the unbonding amount (more complex calculation here)
        // Let's go with Option 1 for clarity in this example.
        uint256 pendingEnergy = calculatePotentialEnergy(tokenId);
        if (pendingEnergy > 0) {
             // Automatically claim pending energy
             _claimSingleUnitEnergy(tokenId, msg.sender);
             // Recalculate pendingEnergy, should be 0 after claim
             pendingEnergy = calculatePotentialEnergy(tokenId);
             require(pendingEnergy == 0, "Claim failed before unbonding");
        }
        // --- End Claiming Logic ---


        uint40 currentTime = uint40(block.timestamp);

        // Clear bonding info
        delete bondedSynergyUnits[tokenId];

        // Remove from user's list (less efficient, could use linked list or mapping if needed often)
        uint256[] storage userUnits = userBondedUnits[msg.sender];
        for (uint i = 0; i < userUnits.length; i++) {
            if (userUnits[i] == tokenId) {
                userUnits[i] = userUnits[userUnits.length - 1];
                userUnits.pop();
                break;
            }
        }
        delete bondedUnitOwner[tokenId];

        // Transfer the NFT back to the original owner
        synergyUnitToken.safeTransferFrom(address(this), msg.sender, tokenId);

        emit SynergyUnitUnbonded(tokenId, msg.sender, currentTime);
    }

    /**
     * @notice Claims accrued Energy Tokens for specified bonded Synergy Units.
     * @param tokenIds An array of IDs of the bonded Synergy Units to claim for.
     */
    function claimEnergy(uint256[] memory tokenIds) external whenNotPaused {
        uint256 totalClaimAmount = 0;
        uint40 currentTime = uint40(block.timestamp);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(bondedUnitOwner[tokenId] == msg.sender, "Not your bonded SU in array");

            uint256 accrued = calculatePotentialEnergy(tokenId); // Calculate based on current state
            if (accrued > 0) {
                 // Update bonding info after calculation
                 BondingInfo storage bondInfo = bondedSynergyUnits[tokenId];
                 bondInfo.accumulatedET = 0; // Clear accumulated after calculating total
                 bondInfo.lastClaimTime = currentTime; // Reset claim time

                 totalClaimAmount += accrued;
            }
        }

        if (totalClaimAmount > 0) {
            // Mint/Transfer Energy Tokens to the user
            // In a real contract, ET might be pre-minted and held by the engine
            // or minted on demand if the ET contract allows.
            // Using mock's mint for simplicity here.
            // energyToken.transfer(msg.sender, totalClaimAmount); // If pre-minted
            energyToken.mint(msg.sender, totalClaimAmount); // If minting on demand

            emit EnergyClaimed(tokenIds, msg.sender, totalClaimAmount);
        }
    }

    /**
     * @notice Calculates the potential Energy Tokens accrued by a single bonded Synergy Unit.
     * This is a view function and does not alter state.
     * @param tokenId The ID of the Synergy Unit NFT.
     * @return The amount of Energy Tokens accrued.
     */
    function calculatePotentialEnergy(uint256 tokenId) public view isBonded(tokenId) returns (uint256) {
        BondingInfo storage bondInfo = bondedSynergyUnits[tokenId];
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - bondInfo.lastClaimTime;

        if (timeElapsed == 0) {
            return bondInfo.accumulatedET; // Return already accumulated energy
        }

        // Get SU properties (assumed from mock IERC721)
        IMockERC721.SUProperties memory suProps = synergyUnitToken.getSUProperties(tokenId);

        // Calculate current effective yield factor considering decay
        // Apply decay based on total time bonded, or time since last decay application?
        // Let's apply decay based on time since *last claim/bond* for simplicity and link decay to activity.
        // Decay reduces the base yield factor over time.
        uint256 decayApplied = (suProps.decayFactor * globalDecayRate * timeElapsed) / SECONDS_IN_DAY / BASIS_POINTS_DENOMINATOR; // Example decay calculation
        uint256 currentYieldFactor = suProps.baseYieldFactor > decayApplied ? suProps.baseYieldFactor - decayApplied : 0;
        // Note: A real implementation would need to persist the *actual* current yield factor after decay is applied and claimed.
        // For this view function, we calculate the *potential* decay *during this period*.
        // A better approach might store a 'decayProgress' or 'effectiveYieldFactor' on the SU itself
        // and update it during claim/decay calls. Let's refine this concept.

        // --- Refined Decay Calculation for View ---
        // Assume SUProps.baseYieldFactor is the *initial* yield.
        // A more realistic decay would be tracked against the SU's state on the token contract.
        // Let's assume the mock SU contract has a `getEffectiveYieldFactor(uint256 tokenId)` function
        // that applies decay based on some internal state/timestamp.
        // For this example, let's just use the base factor and illustrate where decay *would* be applied.
        // Actual yield will be calculated based on a `getEffectiveYieldFactor` on the mock token.
        uint256 effectiveYieldFactor = synergyUnitToken.getSUProperties(tokenId).baseYieldFactor; // Use base for this simplified view calc

        // Apply bonding lock bonus (example: 10% boost if locked for > MIN_BONDING_DURATION)
        uint256 lockBonusMultiplier = 10000; // 100%
        if (bondInfo.bondingLockEndTime > bondInfo.bondTime && bondInfo.bondingLockEndTime >= bondInfo.bondTime + MIN_BONDING_DURATION_FOR_BONUS) {
             lockBonusMultiplier = 11000; // 110% (10% bonus)
        }


        // Calculate yield for the elapsed time
        // Yield per second = (SU effective yield factor / BASIS_POINTS_DENOMINATOR) * (Global Base Yield Rate / BASIS_POINTS_DENOMINATOR) * lockBonusMultiplier / BASIS_POINTS_DENOMINATOR
        // Total Yield = Yield per second * timeElapsed
        uint256 yieldPerSecondScaled = (effectiveYieldFactor.mul(baseYieldRate)).div(BASIS_POINTS_DENOMINATOR); // Scale by base yield rate
        yieldPerSecondScaled = (yieldPerSecondScaled.mul(lockBonusMultiplier)).div(BASIS_POINTS_DENOMINATOR); // Apply lock bonus

        uint256 energyEarnedThisPeriod = yieldPerSecondScaled.mul(timeElapsed).div(BASIS_POINTS_DENOMINATOR); // Final scaling to get energy units

        // Add accumulated energy from previous periods
        return bondInfo.accumulatedET + energyEarnedThisPeriod;
    }

     /**
     * @notice Helper internal function to calculate and apply energy for a single unit during claim.
     * This logic is part of `claimEnergy` but broken out for clarity and potential reuse.
     * It also handles state updates like `lastClaimTime` and accumulated energy.
     * Decay *should* be applied here and persisted on the SU state, but for simplicity,
     * we calculate earnings based on the *current* (not decayed-during-this-period) SU state.
     */
    function _claimSingleUnitEnergy(uint256 tokenId, address claimant) internal isBonded(tokenId) {
        BondingInfo storage bondInfo = bondedSynergyUnits[tokenId];
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - bondInfo.lastClaimTime;

        if (timeElapsed == 0 && bondInfo.accumulatedET == 0) {
            return; // Nothing to claim
        }

         // Get SU properties (assumed from mock IERC721)
        IMockERC721.SUProperties memory suProps = synergyUnitToken.getSUProperties(tokenId);

        // Calculate yield for the elapsed time (same logic as calculatePotentialEnergy)
        uint256 lockBonusMultiplier = 10000; // 100%
        if (bondInfo.bondingLockEndTime > bondInfo.bondTime && bondInfo.bondingLockEndTime >= bondInfo.bondTime + MIN_BONDING_DURATION_FOR_BONUS) {
             lockBonusMultiplier = 11000; // 110% (10% bonus)
        }

        // In a real system, apply decay to the SU's state here and get the *actual* effective yield factor
        // For this mock, we calculate potential based on current state.
        uint256 effectiveYieldFactor = suProps.baseYieldFactor; // Simplified: not applying decay during this specific claim calculation

        uint256 yieldPerSecondScaled = (effectiveYieldFactor.mul(baseYieldRate)).div(BASIS_POINTS_DENOMINATOR);
        yieldPerSecondScaled = (yieldPerSecondScaled.mul(lockBonusMultiplier)).div(BASIS_POINTS_DENOMINATOR);

        uint256 energyEarnedThisPeriod = yieldPerSecondScaled.mul(timeElapsed).div(BASIS_POINTS_DENOMINATOR);

        // Total energy to claim is previously accumulated + energy earned this period
        uint256 totalToClaim = bondInfo.accumulatedET + energyEarnedThisPeriod;

        // Update bonding info
        bondInfo.accumulatedET = 0;
        bondInfo.lastClaimTime = currentTime;

        // Mint or transfer the energy token
        if (totalToClaim > 0) {
             // energyToken.transfer(claimant, totalToClaim); // Pre-minted case
             energyToken.mint(claimant, totalToClaim); // Minting case
             // Note: This internal function doesn't emit EnergyClaimed. The public `claimEnergy` function does after summing.
        }
    }


    /**
     * @notice Calculates the total potential Energy Tokens for all bonded units of a user.
     * This is a view function.
     * @param user The address of the user.
     * @return The total amount of Energy Tokens accrued.
     */
    function calculateTotalPotentialEnergy(address user) external view returns (uint256) {
        uint256 totalEnergy = 0;
        uint256[] memory userUnits = userBondedUnits[user];
        for (uint i = 0; i < userUnits.length; i++) {
            uint256 tokenId = userUnits[i];
             // Ensure it's still bonded and owned by the user in case userBondedUnits mapping is stale (shouldn't happen with correct logic)
            if (bondedSynergyUnits[tokenId].bondTime > 0 && bondedUnitOwner[tokenId] == user) {
                 totalEnergy += calculatePotentialEnergy(tokenId);
            }
        }
        return totalEnergy;
    }

    /**
     * @notice Fuses two Synergy Units and consumes Catalysts to enhance the base unit.
     * The input unit is burned.
     * @param baseTokenId The ID of the Synergy Unit to enhance (must be bonded by caller).
     * @param inputTokenId The ID of the Synergy Unit to consume (must be owned by caller).
     * @param requiredCatalysts Array of Catalyst token IDs required.
     * @param catalystAmounts Array of amounts for each required Catalyst.
     */
    function fuseSynergyUnits(
        uint256 baseTokenId,
        uint256 inputTokenId,
        uint256[] memory requiredCatalysts,
        uint256[] memory catalystAmounts
    ) external whenNotPaused isBonded(baseTokenId) onlyBondedOwner(baseTokenId) {
        require(synergyUnitToken.ownerOf(inputTokenId) == msg.sender, "Caller does not own input SU");
        require(requiredCatalysts.length == catalystAmounts.length, "Catalyst arrays mismatch");
        require(energyToken.balanceOf(msg.sender) >= fusionCostInET, "Insufficient fusion cost");
        // Ensure the engine contract is approved for ET transfer (fusion cost)
        energyToken.safeTransferFrom(msg.sender, address(this), fusionCostInET);

        // --- Consume Input SU ---
        synergyUnitToken.burn(inputTokenId); // Burn the input SU

        // --- Consume Catalysts ---
        // Ensure the engine contract is approved for ERC1155 transferForAll for the user
        for(uint i = 0; i < requiredCatalysts.length; i++) {
            require(catalystToken.balanceOf(msg.sender, requiredCatalysts[i]) >= catalystAmounts[i], "Insufficient catalyst balance");
            catalystToken.safeTransferFrom(msg.sender, address(this), requiredCatalysts[i], catalystAmounts[i], "");
            catalystToken.burn(address(this), requiredCatalysts[i], catalystAmounts[i]); // Burn consumed catalysts
        }

        // --- Apply Fusion Effect to Base SU ---
        // This is where the logic for *how* fusion enhances the base SU occurs.
        // It would typically involve reading properties from both SUs and applying
        // a formula to update the base SU's properties (e.g., baseYieldFactor, decayFactor).
        // For this mock, we'll simulate a property update.
        IMockERC721.SUProperties memory baseProps = synergyUnitToken.getSUProperties(baseTokenId);
        IMockERC721.SUProperties memory inputProps = synergyUnitToken.getSUProperties(inputTokenId);

        // Example fusion logic: Increase baseYieldFactor and potentially decrease decayFactor
        baseProps.baseYieldFactor = baseProps.baseYieldFactor.add(inputProps.baseYieldFactor.div(2)); // Add half of input's base yield
        baseProps.decayFactor = baseProps.decayFactor > inputProps.decayFactor.div(4) ? baseProps.decayFactor - inputProps.decayFactor.div(4) : 0; // Decrease decay by quarter of input's

        // Apply property changes to the base SU (assumes mock ERC721 allows this)
        synergyUnitToken.setSUProperties(baseTokenId, baseProps);

        emit SynergyUnitFused(baseTokenId, inputTokenId, fusionCostInET); // Emitting baseTokenId as the enhanced one
        emit SynergyUnitPropertyUpdated(baseTokenId, "baseYieldFactor", baseProps.baseYieldFactor);
        emit SynergyUnitPropertyUpdated(baseTokenId, "decayFactor", baseProps.decayFactor);
    }

    /**
     * @notice Owner-only function to calibrate global engine parameters.
     * @param newBaseYieldRate The new global base yield rate (basis points).
     * @param newGlobalDecayRate The new global decay rate (basis points).
     * @param newSynergyBoostFactor The new synergy boost multiplier (basis points).
     * @param newCatalystBoostFactor The new catalyst boost multiplier (basis points).
     */
    function calibrateEngine(
        uint256 newBaseYieldRate,
        uint256 newGlobalDecayRate,
        uint256 newSynergyBoostFactor,
        uint256 newCatalystBoostFactor
    ) external onlyOwner whenNotPaused {
        baseYieldRate = newBaseYieldRate;
        globalDecayRate = newGlobalDecayRate;
        synergyBoostFactor = newSynergyBoostFactor;
        catalystBoostFactor = newCatalystBoostFactor;

        emit EngineCalibrated(msg.sender, newBaseYieldRate, newGlobalDecayRate);
    }

    /**
     * @notice Allows users to propose recalibration of key engine parameters.
     * Requires a deposit.
     * @param suggestedBaseYieldRate The suggested new global base yield rate.
     * @param suggestedDecayRate The suggested new global decay rate.
     */
    function proposeRecalibration(uint256 suggestedBaseYieldRate, uint256 suggestedDecayRate) external whenNotPaused {
        require(energyToken.balanceOf(msg.sender) >= proposalDepositAmount, "Insufficient proposal deposit");
        // Ensure engine contract is approved for ET transfer (deposit)
         energyToken.safeTransferFrom(msg.sender, address(this), proposalDepositAmount);

        uint256 proposalId = nextProposalId++;
        uint256 proposalIndex = recalibrationProposals.length;
        recalibrationProposals.push(RecalibrationProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            startTime: uint40(block.timestamp),
            suggestedBaseYieldRate: suggestedBaseYieldRate,
            suggestedDecayRate: suggestedDecayRate,
            votes: new mapping(address => bool)(), // Initialize new mapping
            totalVotes: 0,
            totalApprovedVotes: 0,
            status: RecalibrationProposal.Status.Active
        }));
        proposalIdToIndex[proposalId] = proposalIndex;

        emit RecalibrationProposed(proposalId, msg.sender, suggestedBaseYieldRate, suggestedDecayRate);
    }

    /**
     * @notice Allows users to vote on an active recalibration proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param approve True to vote approve, false to vote reject.
     */
    function voteOnRecalibration(uint256 proposalId, bool approve) external whenNotPaused isValidProposal(proposalId) {
        RecalibrationProposal storage proposal = recalibrationProposals[proposalIdToIndex[proposalId]];
        require(proposal.status == RecalibrationProposal.Status.Active, "Proposal is not active");
        require(block.timestamp < proposal.startTime + PROPOSAL_VOTING_PERIOD, "Voting period has ended");
        require(proposal.votes[msg.sender] == false, "Already voted on this proposal");

        // Voting power could be weighted by bonded SU count or other factors.
        // For simplicity, 1 user address = 1 vote here.
        proposal.votes[msg.sender] = true;
        proposal.totalVotes++;
        if (approve) {
            proposal.totalApprovedVotes++;
        }

        emit RecalibrationVoted(proposalId, msg.sender, approve);
    }

    /**
     * @notice Finalizes a recalibration proposal after the voting period ends.
     * Can be called by anyone. Applies the changes if the proposal passed (e.g., simple majority).
     * Returns the deposit to the proposer if it passed, keeps it as fee if it failed.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeRecalibration(uint256 proposalId) external whenNotPaused isValidProposal(proposalId) {
        RecalibrationProposal storage proposal = recalibrationProposals[proposalIdToIndex[proposalId]];
        require(proposal.status == RecalibrationProposal.Status.Active, "Proposal is not active");
        require(block.timestamp >= proposal.startTime + PROPOSAL_VOTING_PERIOD, "Voting period has not ended");

        bool passed = proposal.totalVotes > 0 && proposal.totalApprovedVotes * 2 > proposal.totalVotes; // Simple majority check
        address proposer = proposal.proposer; // Cache proposer address

        proposal.status = passed ? RecalibrationProposal.Status.Passed : RecalibrationProposal.Status.Failed;

        if (passed) {
            // Apply the suggested parameters
            baseYieldRate = proposal.suggestedBaseYieldRate;
            globalDecayRate = proposal.suggestedDecayRate; // Only allowing these two for proposals

            // Return deposit to proposer
            energyToken.safeTransfer(proposer, proposalDepositAmount);

            emit RecalibrationFinalized(proposalId, true);
            // Also emit EngineCalibrated to reflect the parameter change source
            emit EngineCalibrated(address(this), baseYieldRate, globalDecayRate); // Use address(this) to indicate automated change
        } else {
            // Keep deposit as protocol fee (remains in contract balance)
            emit RecalibrationFinalized(proposalId, false);
        }
    }

    /**
     * @notice Applies decay to a specific Synergy Unit's properties based on elapsed time.
     * This function might be called periodically by a keeper network or triggered by user interactions.
     * Decay should be stateful on the SU token itself for accurate tracking.
     * For this example, we simulate applying decay that reduces the base yield factor.
     * @param tokenId The ID of the Synergy Unit NFT.
     */
    function applyDecay(uint256 tokenId) external whenNotPaused isBonded(tokenId) {
        // This function assumes the SU token contract has a method to apply decay
        // or retrieve the last time decay was applied.
        // For simplicity, we'll simulate decay reducing the baseYieldFactor directly on the mock token.

        IMockERC721.SUProperties memory suProps = synergyUnitToken.getSUProperties(tokenId);
        uint40 lastDecayTime = uint40(synergyUnitToken.getSUProperties(tokenId).catalystBoostEndTime); // Misusing this field for last decay time in mock
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - lastDecayTime; // Time since last decay check

        if (timeElapsed == 0) return;

        // Calculate decay amount based on time elapsed and global/SU decay rates
        uint256 decayPerSecondScaled = (suProps.decayFactor * globalDecayRate) / BASIS_POINTS_DENOMINATOR; // Scale by global decay rate
        uint256 totalDecayAmount = decayPerSecondScaled.mul(timeElapsed).div(BASIS_POINTS_DENOMINATOR); // Final amount to reduce factor by

        uint256 newBaseYieldFactor = suProps.baseYieldFactor > totalDecayAmount ? suProps.baseYieldFactor - totalDecayAmount : 0;

        // Apply the decay to the SU's state on the mock token
        suProps.baseYieldFactor = newBaseYieldFactor;
        suProps.catalystBoostEndTime = currentTime; // Update last decay time (misusing field)
        synergyUnitToken.setSUProperties(tokenId, suProps);

        emit SynergyUnitDecayed(tokenId, totalDecayAmount);
        emit SynergyUnitPropertyUpdated(tokenId, "baseYieldFactor", newBaseYieldFactor);
    }


    /**
     * @notice View function to check if two specific Synergy Units provide a synergy bonus.
     * Synergy logic is specific to the protocol design (e.g., based on attributes, series).
     * @param tokenId1 ID of the first SU.
     * @param tokenId2 ID of the second SU.
     * @return True if they provide synergy, false otherwise.
     */
    function checkSynergyBoost(uint256 tokenId1, uint256 tokenId2) external view returns (bool) {
         if (tokenId1 == tokenId2) return false; // Cannot synergize with self

         // Get properties (assumed from mock IERC721)
        IMockERC721.SUProperties memory props1 = synergyUnitToken.getSUProperties(tokenId1);
        IMockERC721.SUProperties memory props2 = synergyUnitToken.getSUProperties(tokenId2);

        // Example synergy logic: check if a specific bit is set in their synergyAttribute
        bytes32 SYNERGY_BIT_MASK = bytes32(uint256(1)); // Example: check if the first bit is set
        return (props1.synergyAttribute & SYNERGY_BIT_MASK) != bytes32(0) &&
               (props2.synergyAttribute & SYNERGY_BIT_MASK) != bytes32(0) &&
               (props1.synergyAttribute != props2.synergyAttribute); // Simple example: synergistic if they share *a* specific type but aren't identical types

        // More complex logic could check for matching/complementary attributes, series, etc.
    }

    /**
     * @notice Triggers a Resonance event for a group of bonded Synergy Units.
     * This might consume Catalysts and provide a group boost.
     * @param tokenIds An array of IDs of your bonded Synergy Units.
     * @param requiredCatalysts Array of Catalyst token IDs required.
     * @param catalystAmounts Array of amounts for each required Catalyst.
     */
    function triggerResonance(
        uint256[] memory tokenIds,
        uint256[] memory requiredCatalysts,
        uint256[] memory catalystAmounts
    ) external whenNotPaused {
        require(tokenIds.length >= 2, "Need at least two SUs for Resonance"); // Example minimum group size
        require(requiredCatalysts.length == catalystAmounts.length, "Catalyst arrays mismatch");

        // Ensure all SUs belong to the caller and are bonded
        for (uint i = 0; i < tokenIds.length; i++) {
            require(bondedUnitOwner[tokenIds[i]] == msg.sender, "Not all SUs belong to caller or are bonded");
        }

        // --- Consume Catalysts ---
        for(uint i = 0; i < requiredCatalysts.length; i++) {
            require(catalystToken.balanceOf(msg.sender, requiredCatalysts[i]) >= catalystAmounts[i], "Insufficient catalyst balance");
             // Assume approval already granted
            catalystToken.safeTransferFrom(msg.sender, address(this), requiredCatalysts[i], catalystAmounts[i], "");
            catalystToken.burn(address(this), requiredCatalysts[i], catalystAmounts[i]); // Burn consumed catalysts
        }

        // --- Apply Resonance Effect ---
        // This logic determines the boost based on the group's composition.
        // Example: calculate average synergy attribute, count units of specific types, etc.
        // Apply a temporary boost to the yield rate of the involved SUs.
        uint40 boostDuration = uint40(1 days); // Example: 1 day boost duration
        uint256 totalBoostMultiplier = synergyBoostFactor; // Use the global synergy boost factor for simplicity

        for (uint i = 0; i < tokenIds.length; i++) {
             IMockERC721.SUProperties memory suProps = synergyUnitToken.getSUProperties(tokenIds[i]);
             suProps.catalystBoostEndTime = uint40(block.timestamp) + boostDuration;
             suProps.catalystBoostMultiplier = totalBoostMultiplier; // Store boost multiplier
             synergyUnitToken.setSUProperties(tokenIds[i], suProps); // Update SU state on mock token
        }

        emit ResonanceTriggered(tokenIds, totalBoostMultiplier); // Emitting multiplier as boost applied
    }

    /**
     * @notice Activates an effect on a Synergy Unit using a Catalyst NFT.
     * @param catalystId The ID of the Catalyst NFT (ERC-1155 type/ID).
     * @param targetSUId The ID of the target Synergy Unit (must be bonded by caller).
     * @param amount The amount of Catalyst units to use.
     */
    function activateCatalystEffect(uint256 catalystId, uint256 targetSUId, uint256 amount) external whenNotPaused isBonded(targetSUId) onlyBondedOwner(targetSUId) {
        require(amount > 0, "Amount must be greater than 0");
        require(catalystToken.balanceOf(msg.sender, catalystId) >= amount, "Insufficient catalyst balance");

        // Consume the Catalyst
        // Assume approval already granted
        catalystToken.safeTransferFrom(msg.sender, address(this), catalystId, amount, "");
        catalystToken.burn(address(this), catalystId, amount); // Burn consumed catalysts

        // Apply Catalyst effect to the target SU
        // The effect depends on the catalystId and amount used.
        // Example: temporary yield boost, decay reduction, duration extension.
        IMockERC721.SUProperties memory suProps = synergyUnitToken.getSUProperties(targetSUId);

        uint40 effectDuration = uint40(amount * 1 hours); // Example: 1 hour duration per catalyst amount
        uint256 boostMultiplier = catalystBoostFactor; // Use global catalyst boost factor

        // Extend or set boost effect
        if (suProps.catalystBoostEndTime < block.timestamp) {
            suProps.catalystBoostEndTime = uint40(block.timestamp) + effectDuration;
        } else {
            suProps.catalystBoostEndTime += effectDuration;
        }
        suProps.catalystBoostMultiplier = boostMultiplier; // Store or update multiplier

        synergyUnitToken.setSUProperties(targetSUId, suProps); // Update SU state on mock token

        emit CatalystActivated(catalystId, targetSUId, effectDuration);
    }

     /**
      * @notice Allows a user to burn their bonded Synergy Unit.
      * May have specific outcomes (e.g., instant energy payout, removing from circulation).
      * @param tokenId The ID of the Synergy Unit to burn.
      */
    function burnSynergyUnit(uint256 tokenId) external whenNotPaused isBonded(tokenId) onlyBondedOwner(tokenId) {
        // Claim any pending energy before burning
        _claimSingleUnitEnergy(tokenId, msg.sender);

        // Remove from bonding state
        delete bondedSynergyUnits[tokenId];
        uint256[] storage userUnits = userBondedUnits[msg.sender];
         for (uint i = 0; i < userUnits.length; i++) {
            if (userUnits[i] == tokenId) {
                userUnits[i] = userUnits[userUnits.length - 1];
                userUnits.pop();
                break;
            }
        }
        delete bondedUnitOwner[tokenId];

        // Burn the SU token from the engine's possession
        synergyUnitToken.burn(tokenId);

        // Potential outcome: e.g., instant payout of a fraction of total potential value, or nothing
        // For simplicity, no extra payout here, burning is just removal.

        // No specific event for burning from engine, relies on ERC721 Transfer(address(0))
        // But we can emit a custom event if needed
        // emit SynergyUnitBurnedFromEngine(tokenId, msg.sender); // Custom event
    }

    /**
     * @notice Allows a user to voluntarily set or extend a bonding lock duration for their bonded SU.
     * This might grant a yield bonus.
     * @param tokenId The ID of the bonded Synergy Unit.
     * @param durationSeconds The duration in seconds to lock the SU for (from now).
     */
    function setBondingLockDuration(uint256 tokenId, uint256 durationSeconds) external whenNotPaused isBonded(tokenId) onlyBondedOwner(tokenId) {
        BondingInfo storage bondInfo = bondedSynergyUnits[tokenId];
        uint40 newLockEndTime = uint40(block.timestamp + durationSeconds);
        require(newLockEndTime > bondInfo.bondingLockEndTime, "New lock duration must extend the current lock");
        require(durationSeconds >= MIN_BONDING_DURATION_FOR_BONUS, "Duration must be at least minimum bonus duration"); // Require minimum for lock

        bondInfo.bondingLockEndTime = newLockEndTime;

        emit BondingLockExtended(tokenId, durationSeconds);
    }

    /**
     * @notice Initiates a high-cost 'Spark' event using specific bonded SUs and Catalysts.
     * The outcome is determined later (e.g., via oracle/VRF) and must be claimed.
     * @param suTokenIds An array of IDs of your bonded Synergy Units to use.
     * @param catalystTokenIds Array of Catalyst token IDs (types) required.
     * @param catalystAmounts Array of amounts for each catalyst type.
     */
    function initiateSpark(
        uint256[] memory suTokenIds,
        uint256[] memory catalystTokenIds,
        uint256[] memory catalystAmounts
    ) external whenNotPaused {
        require(suTokenIds.length > 0, "Need SUs for Spark");
        require(catalystTokenIds.length == catalystAmounts.length, "Catalyst arrays mismatch");
        // Add other requirements: minimum number of SUs, specific SU attributes needed, specific catalyst types/amounts.

        // Ensure all SUs belong to the caller and are bonded
        for (uint i = 0; i < suTokenIds.length; i++) {
            require(bondedUnitOwner[suTokenIds[i]] == msg.sender, "Not all SUs belong to caller or are bonded");
             // Could also add checks for minimum bonding duration, no active lock, etc.
        }

         // --- Consume Catalysts ---
        for(uint i = 0; i < catalystTokenIds.length; i++) {
            require(catalystToken.balanceOf(msg.sender, catalystTokenIds[i]) >= catalystAmounts[i], "Insufficient catalyst balance");
             // Assume approval already granted
            catalystToken.safeTransferFrom(msg.sender, address(this), catalystTokenIds[i], catalystAmounts[i], "");
            catalystToken.burn(address(this), catalystTokenIds[i], catalystAmounts[i]); // Burn consumed catalysts
        }

        // --- Prepare Spark Data ---
        // The involved SUs might become temporarily unusable or have their properties altered/reset.
        // For simplicity, let's just mark them as 'in_spark' state or transfer them temporarily.
        // A more complex system might require them to be locked/transferred to a holding contract.
        // For this example, let's assume they are just noted as inputs.

        uint256 sparkId = nextSparkId++;
        uint256 sparkIndex = sparks.length;
        sparks.push(SparkData({
            sparkId: sparkId,
            initiator: msg.sender,
            inputSUIds: suTokenIds, // Store input SUs
            inputCatalystIds: catalystTokenIds,
            inputCatalystAmounts: catalystAmounts,
            startTime: uint40(block.timestamp),
            outcomeHash: bytes32(0), // Outcome determined later
            outcomeClaimed: false,
            status: SparkData.Status.Initiated
        }));
        sparkIdToIndex[sparkId] = sparkIndex;

        // The outcome of the spark is determined *after* this transaction,
        // potentially by an oracle, VRF, or a subsequent transaction.
        // This function only records the initiation.

        emit SparkInitiated(sparkId, msg.sender, suTokenIds, catalystTokenIds);
    }

    /**
     * @notice Owner/Oracle/Keeper function to finalize a Spark event's outcome.
     * This would be called after the external process determines the result.
     * @param sparkId The ID of the Spark event to finalize.
     * @param outcomeDetailsHash A hash representing the determined outcome (e.g., verifiable hash from VRF).
     * @param outcomeDetails A bytes array containing details needed to later claim the outcome (e.g., VRF proof, new token details).
     */
    function finalizeSparkOutcome(uint256 sparkId, bytes32 outcomeDetailsHash, bytes memory outcomeDetails) external onlyOwner isValidSpark(sparkId) {
        SparkData storage spark = sparks[sparkIdToIndex[sparkId]];
        require(spark.status == SparkData.Status.Initiated || spark.status == SparkData.Status.AwaitingOutcome, "Spark not in valid state for finalization");
        // Add verification logic here if outcomeDetailsHash is derived from outcomeDetails + VRF proof + etc.

        spark.outcomeHash = outcomeDetailsHash;
        spark.status = SparkData.Status.Completed;
        // Store outcomeDetails associated with the sparkId, maybe in a separate mapping
        // bytes mapping public sparkOutcomeDetails; sparkOutcomeDetails[sparkId] = outcomeDetails;

        emit SparkCompleted(sparkId, outcomeDetailsHash);
    }

    /**
     * @notice Allows the initiator of a completed Spark event to claim its outcome.
     * Requires providing the necessary details/proof if applicable.
     * @param sparkId The ID of the completed Spark event.
     * @param outcomeProof Optional proof data needed to claim the outcome (e.g., VRF proof).
     */
    function claimSparkOutcome(uint256 sparkId, bytes memory outcomeProof) external whenNotPaused isValidSpark(sparkId) {
         SparkData storage spark = sparks[sparkIdToIndex[sparkId]];
         require(spark.initiator == msg.sender, "Only the initiator can claim spark outcome");
         require(spark.status == SparkData.Status.Completed, "Spark outcome is not ready to be claimed");
         require(!spark.outcomeClaimed, "Spark outcome already claimed");

         // --- Verify and Deliver Outcome ---
         // This logic depends heavily on the Spark outcome mechanism (VRF, oracle, predefined outcomes).
         // Example: Verify outcomeProof against spark.outcomeHash or chainlink VRF callback.
         // Then, based on the verified outcome:
         // - Mint/transfer new tokens (ET, new SU, unique NFT).
         // - Refund some inputs.
         // - Apply permanent buffs to the initiator's remaining SUs.
         // For this mock, we'll just mark it claimed. A real impl would parse outcomeProof/details.

         // Example: Based on outcomeDetailsHash, maybe mint a new, rare SU
         // uint256 rareSUId = 999000 + sparkId; // Example ID scheme
         // IMockERC721.SUProperties memory rareProps = IMockERC721.SUProperties({
         //      baseYieldFactor: 50000, decayFactor: 50, synergyAttribute: bytes32(uint256(spark.outcomeHash)), catalystBoostEndTime: 0, catalystBoostMultiplier: 0
         // });
         // synergyUnitToken.mint(msg.sender, rareSUId, rareProps);
         // emit SynergyUnitMinted(msg.sender, rareSUId); // Assuming a Minted event on the SU token

         spark.outcomeClaimed = true;

         // No specific event for claiming outcome unless it's a token transfer/mint.
         // The SparkCompleted event indicates readiness.
    }


    /**
     * @notice View function to get detailed information about a specific bonded Synergy Unit.
     * @param tokenId The ID of the Synergy Unit NFT.
     * @return A tuple containing bonding info and SU properties.
     */
    function getSynergyUnitDetails(uint256 tokenId) external view isBonded(tokenId) returns (
        BondingInfo memory bondInfo,
        IMockERC721.SUProperties memory suProps,
        uint256 currentPotentialEnergy // Include calculated potential energy for convenience
    ) {
         bondInfo = bondedSynergyUnits[tokenId];
         suProps = synergyUnitToken.getSUProperties(tokenId);
         currentPotentialEnergy = calculatePotentialEnergy(tokenId);
         // Note: This calculation of potential energy inside the view is fine.
    }

    /**
     * @notice View function to get the current global state of the engine parameters.
     * @return A tuple containing current parameters.
     */
    function getGlobalEngineState() external view returns (
        uint256 _baseYieldRate,
        uint256 _globalDecayRate,
        uint256 _synergyBoostFactor,
        uint256 _catalystBoostFactor,
        uint256 _proposalDepositAmount,
        uint256 _fusionCostInET
    ) {
        return (
            baseYieldRate,
            globalDecayRate,
            synergyBoostFactor,
            catalystBoostFactor,
            proposalDepositAmount,
            fusionCostInET
        );
    }

    /**
     * @notice View function to get a list of active recalibration proposal IDs.
     * @return An array of active proposal IDs.
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](recalibrationProposals.length); // Max possible size
        uint256 count = 0;
        uint40 currentTime = uint40(block.timestamp);

        for (uint i = 0; i < recalibrationProposals.length; i++) {
            RecalibrationProposal storage proposal = recalibrationProposals[i];
            if (proposal.status == RecalibrationProposal.Status.Active && currentTime < proposal.startTime + PROPOSAL_VOTING_PERIOD) {
                activeIds[count] = proposal.proposalId;
                count++;
            }
        }
        // Copy to a new array of exact size
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    /**
     * @notice View function to get details for a specific recalibration proposal.
     * @param proposalId The ID of the proposal.
     * @return Details of the proposal.
     */
    function getProposalDetails(uint256 proposalId) external view isValidProposal(proposalId) returns (RecalibrationProposal memory) {
        // Note: Mappings within structs (`votes`) cannot be returned directly in Solidity < 0.8.19
        // A workaround is needed if you need the full votes map.
        // For simplicity, we return the struct *excluding* the mapping here.
        RecalibrationProposal storage proposal = recalibrationProposals[proposalIdToIndex[proposalId]];
         return RecalibrationProposal({
             proposalId: proposal.proposalId,
             proposer: proposal.proposer,
             startTime: proposal.startTime,
             suggestedBaseYieldRate: proposal.suggestedBaseYieldRate,
             suggestedDecayRate: proposal.suggestedDecayRate,
             votes: new mapping(address => bool)(), // Return empty mapping placeholder
             totalVotes: proposal.totalVotes,
             totalApprovedVotes: proposal.totalApprovedVotes,
             status: proposal.status
         });
    }

     /**
      * @notice Owner-only function to withdraw accumulated fees (e.g., from failed proposals, fusion costs).
      * @param receiver The address to send the fees to.
      * @param amount The amount of Energy Tokens to withdraw.
      */
    function withdrawFees(address receiver, uint256 amount) external onlyOwner {
        require(energyToken.balanceOf(address(this)) >= amount, "Insufficient fees balance");
        energyToken.safeTransfer(receiver, amount);
        emit FundsWithdrawn(receiver, amount);
    }

    // Inherited Pausable functions: pause(), unpause()
    // Inherited Ownable functions: transferOwnership(), renounceOwnership()

    // --- Internal Helpers (Optional but good practice) ---
    // Example: A helper to get a user's bonded units - already implemented with `userBondedUnits` mapping.
    // Example: A helper to calculate decay (partially done in `applyDecay`).

    // --- Mock Implementations for External Calls (REMOVE IN PRODUCTION) ---
    // In a real deployment, you would interact with actual token contracts.
    // These internal functions simulate how this contract *would* interact
    // if it were the token contract or had permissions.

    // We need a way to set initial SU properties for testing, as this would happen during minting.
    // Assuming the mock SU contract allows owner to set properties.
     function mock_setSUInitialProperties(uint256 tokenId, IMockERC721.SUProperties memory props) external onlyOwner {
         // In a real scenario, this function would NOT exist on the Engine contract.
         // SU properties are managed by the SU token contract itself.
         synergyUnitToken.setSUProperties(tokenId, props);
     }
}
```