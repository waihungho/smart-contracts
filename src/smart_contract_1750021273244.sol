Okay, let's design a smart contract that manages a "Decentralized Evolutionary Garden" (DEG). This concept involves digital entities (Fractals) that users can cultivate, interact with, and influence through governance, exhibiting dynamic properties based on time, nourishment, and interaction.

It incorporates:
1.  **Dynamic State:** Fractals aren't static; their properties evolve.
2.  **On-Chain Simulation:** Basic growth/decay logic is calculated based on time and resources.
3.  **Inter-User Interaction:** Fractals owned by different users can interact (cross-pollinate).
4.  **Resource Management:** Staking/depositing tokens ("Nourishment") affects evolution.
5.  **NFTs:** Seeds and mature Fractals could be represented as NFTs (ERC721).
6.  **Governance:** Users can propose and vote on changes to global parameters affecting the garden's evolution.
7.  **Basic Oracle Integration (Conceptual):** Could potentially use an oracle for external factors, though simplified for this example.

This is a complex concept for a single contract, so we'll make assumptions and simplify some mechanics to keep it manageable and demonstrate the core ideas. We'll use ERC721 for the Fractals themselves and ERC20 for Nourishment/Harvest tokens.

---

**Smart Contract Outline and Function Summary: Decentralized Evolutionary Garden (DEG)**

**Concept:** A digital ecosystem where users cultivate dynamic, evolving "Fractals". Fractals grow, decay, branch, and can cross-pollinate. Evolution is influenced by user "Nourishment" (staking ERC20 tokens) and global parameters adjustable via decentralized governance.

**Core Entities:**
*   **Seed:** An initial state, potentially an ERC721, waiting to be planted and grow into a Fractal. (Implicit in planting)
*   **Fractal:** A dynamic digital entity represented by state variables (complexity, energy, resilience, etc.). An ERC721 token.
*   **Nourishment:** An ERC20 token staked by users to boost Fractal growth.
*   **Harvest:** An ERC20 token or new Seeds generated from mature Fractals.
*   **Parameters:** Global variables affecting growth, decay, branching, etc.
*   **Proposal:** A governance request to change a global parameter.

**Key Mechanisms:**
*   **Planting:** Creating a new Fractal from a (conceptual) Seed.
*   **Nourishing:** Staking ERC20 tokens on a Fractal to increase its energy/growth rate.
*   **Evolution (`growFractal` trigger):** Recalculating a Fractal's state based on time, nourishment, and global parameters. This happens when a user interacts with the fractal.
*   **Branching:** A mature Fractal can create a new Seed (mint a new NFT/represent a new potential Fractal).
*   **Cross-Pollination:** Interacting two Fractals to influence each other's state or create new Seeds.
*   **Harvesting:** Extracting value (tokens or seeds) from a mature Fractal, potentially reducing its state.
*   **Governance:** Proposing, voting on, and executing changes to core garden parameters.

**Function Summary (20+ Functions):**

1.  `constructor`: Initializes contract owner, key token addresses, and initial global parameters.
2.  `plantSeed()`: Mints a new ERC721 Fractal token for the caller, initializing its state (low complexity, energy, etc.). Represents planting a conceptual seed.
3.  `nourishFractal(uint256 fractalId, uint256 amount)`: Allows a user to stake `amount` of the Nourishment token on a specific `fractalId`. Updates fractal's nourishment balance.
4.  `growFractal(uint256 fractalId)`: Triggers the evolution calculation for a specific fractal. Updates complexity, energy, and resilience based on time elapsed, nourishment, and global parameters. Requires calling `_calculateEvolution`.
5.  `branchFractal(uint256 fractalId)`: Allows the owner of a sufficiently mature/energetic fractal to create a new Seed (mint a new Fractal NFT with initial state). Consumes some fractal energy/complexity. Requires calling `growFractal` first.
6.  `crossPollinate(uint256 fractalId1, uint256 fractalId2)`: Allows owners (or anyone, depending on rules) to interact two fractals. Calculates influence based on fractal properties and updates their states. Requires calling `growFractal` for both first.
7.  `harvestFractal(uint256 fractalId)`: Allows the owner to harvest tokens or seeds from a fractal based on its current state (e.g., energy, complexity). Consumes harvested properties. Requires calling `growFractal` first.
8.  `withdrawNourishment(uint256 fractalId, uint256 amount)`: Allows the staker to withdraw Nourishment tokens from a fractal. May incur penalties or only be possible under certain conditions.
9.  `proposeParameterChange(string memory parameterName, int256 newValue, string memory description)`: Allows a qualified user (e.g., minimum fractal ownership) to propose a change to a global parameter. Creates a new `Proposal`.
10. `voteOnProposal(uint256 proposalId, bool support)`: Allows users with voting power (e.g., based on fractal ownership or staked nourishment) to vote Yes/No on a proposal.
11. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed the voting period and threshold. Updates the relevant global parameter.
12. `getFractalInfo(uint256 fractalId)`: View function returning details about a specific fractal (owner, state, nourishment, last updated time).
13. `getUserFractals(address user)`: View function returning a list of fractal IDs owned by a user.
14. `getGlobalParameters()`: View function returning the current values of all global parameters.
15. `getProposalInfo(uint256 proposalId)`: View function returning details about a specific governance proposal (state, votes, target parameter).
16. `getProposalCount()`: View function returning the total number of proposals created.
17. `setNourishmentToken(address _token)`: Admin/Governance function to set the ERC20 nourishment token address.
18. `setHarvestToken(address _token)`: Admin/Governance function to set the ERC20 harvest token address (if harvest is a token).
19. `setOracleAddress(address _oracle)`: Admin/Governance function to potentially set an oracle address for external data influence (e.g., random seeds, environmental factors). (Conceptual)
20. `withdrawAdminFees(address tokenAddress)`: Owner function to withdraw collected fees (e.g., small percentage from harvesting or branching).
21. `tokenURI(uint256 tokenId)`: ERC721 metadata function, could potentially generate dynamic URI based on fractal state.
22. `supportsInterface(bytes4 interfaceId)`: ERC721 standard function.
23. `balanceOf(address owner)`: ERC721 standard function.
24. `ownerOf(uint256 tokenId)`: ERC721 standard function.
25. `getApproved(uint256 tokenId)`: ERC721 standard function.
26. `isApprovedForAll(address owner, address operator)`: ERC721 standard function.

*(Note: ERC721 standard functions count towards the function total but are necessary boilerplate for the NFT aspect).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- Smart Contract Outline and Function Summary ---
// See extensive summary above code block.

// --- Concept Summary ---
// Decentralized Evolutionary Garden (DEG): Manages dynamic digital entities (Fractals)
// represented as ERC721 NFTs. Users can cultivate (nourish), evolve, interact,
// branch, and harvest fractals. Global garden parameters are controlled
// by decentralized governance proposals and voting.
// Integrates ERC20 for nourishment/harvest and ERC721 for fractals.

// --- Function Summary (20+ functions) ---
// constructor(): Initializes contract, tokens, and parameters.
// plantSeed(): Mints a new Fractal NFT (ERC721) with initial state.
// nourishFractal(uint256 fractalId, uint256 amount): Stakes ERC20 nourishment tokens on a fractal.
// growFractal(uint256 fractalId): Triggers on-chain fractal evolution calculation.
// branchFractal(uint256 fractalId): Creates a new Seed (Fractal NFT) from a mature fractal.
// crossPollinate(uint256 fractalId1, uint256 fractalId2): Interacts two fractals, influencing their state.
// harvestFractal(uint256 fractalId): Extracts tokens/seeds from a fractal based on state.
// withdrawNourishment(uint256 fractalId, uint256 amount): Allows withdrawing staked nourishment.
// proposeParameterChange(string memory parameterName, int256 newValue, string memory description): Creates a governance proposal.
// voteOnProposal(uint256 proposalId, bool support): Votes on an active proposal.
// executeProposal(uint256 proposalId): Executes a successful proposal.
// getFractalInfo(uint256 fractalId): View: Gets state details for a fractal.
// getUserFractals(address user): View: Gets list of fractal IDs owned by a user.
// getGlobalParameters(): View: Gets current global garden parameters.
// getProposalInfo(uint256 proposalId): View: Gets details for a proposal.
// getProposalCount(): View: Gets total number of proposals.
// setNourishmentToken(address _token): Admin/Governance: Sets nourishment token address.
// setHarvestToken(address _token): Admin/Governance: Sets harvest token address.
// setOracleAddress(address _oracle): Admin/Governance: Sets potential oracle address.
// withdrawAdminFees(address tokenAddress): Owner: Withdraws collected fees.
// tokenURI(uint256 tokenId): ERC721: Returns token metadata URI (dynamic).
// supportsInterface(bytes4 interfaceId): ERC721 standard.
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.

// Note: Simplifications are made for complexity calculation and on-chain logic.
// Production system would require more robust calculations and potential off-chain
// computation with on-chain verification.

contract DecentralizedEvolutionaryGarden is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _fractalIds;
    Counters.Counter private _proposalIds;

    // --- State Variables ---

    IERC20 public nourishmentToken;
    IERC20 public harvestToken; // Could be the same as nourishment, or different
    address public feeReceiver;
    address public oracleAddress; // Placeholder for potential future use

    struct Fractal {
        uint256 id;
        uint256 seedDNA; // Base properties from planting/branching
        uint256 complexity; // Grows with nourishment and time
        uint256 energy;     // Grows with nourishment, decays with time/actions
        uint256 resilience; // Influenced by cross-pollination, resists decay
        uint256 nourishmentStaked; // Amount of nourishment token staked on this fractal
        uint48 lastUpdated; // Timestamp of last evolution calculation (using uint48 for gas)
    }

    mapping(uint256 => Fractal) public fractals;
    mapping(address => uint256[]) private userFractals; // Track fractals per user
    mapping(uint256 => uint256) private fractalNourishmentBalance; // Explicitly track balance separate from struct for staking

    // Global Garden Parameters (Governance Controlled)
    struct GlobalParameters {
        uint256 baseGrowthRate; // Per second complexity/energy growth multiplier (scaled)
        uint256 baseDecayRate;  // Per second energy/resilience decay multiplier (scaled)
        uint256 nourishmentMultiplier; // How much nourishment boosts growth (scaled)
        uint256 branchingCostEnergy; // Energy required to branch
        uint256 branchingCostComplexity; // Complexity required to branch
        uint256 crossPollinationBoost; // How much CP boosts energy/resilience (scaled)
        uint256 harvestRateEnergy; // How much energy converts to harvest tokens (scaled)
        uint256 harvestRateComplexity; // How much complexity converts to harvest tokens (scaled)
        uint256 minimumVotingStake; // Minimum nourishment stake or fractal count for voting
        uint256 proposalThreshold; // Percentage of total voting power required to pass (e.g., 5000 for 50%)
        uint48 votingPeriod;       // Duration of voting in seconds
        uint256 minFractalForProposal; // Minimum complexity/energy/count to create proposal
        uint256 plantingFee; // Fee to plant a seed (in native token, for simplicity)
    }

    GlobalParameters public params;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        string parameterName; // Name of the parameter to change
        int256 newValue;      // The proposed new value
        string description;   // Description of the proposal
        uint256 proposerFractalId; // Fractal ID of the proposer (for eligibility checks)
        uint48 votingDeadline;
        uint256 yeas;         // Total voting power in support
        uint256 nays;         // Total voting power against
        bool executed;
        ProposalState state;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted

    // --- Events ---

    event FractalPlanted(uint256 indexed fractalId, address indexed owner, uint256 seedDNA);
    event FractalNourished(uint256 indexed fractalId, address indexed nourisher, uint256 amount);
    event FractalGrown(uint256 indexed fractalId, uint256 newComplexity, uint256 newEnergy, uint256 newResilience);
    event BranchCreated(uint256 indexed parentFractalId, uint256 indexed newFractalId, uint256 newSeedDNA);
    event FractalsCrossPollinated(uint256 indexed fractalId1, uint256 indexed fractalId2, uint256 boostAmount);
    event FractalHarvested(uint256 indexed fractalId, address indexed harvester, uint256 harvestAmount);
    event NourishmentWithdrawn(uint256 indexed fractalId, address indexed withdrawer, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string parameterName, int256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, string parameterName, int256 newValue);
    event ParameterChanged(string parameterName, int256 newValue);
    event AdminFeesWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);

    // --- Access Control & Constructor ---

    constructor(
        address _nourishmentToken,
        address _harvestToken,
        address _feeReceiver,
        // Initial parameters (simplified)
        uint256 _baseGrowthRate,
        uint256 _baseDecayRate,
        uint256 _nourishmentMultiplier,
        uint256 _branchingCostEnergy,
        uint256 _branchingCostComplexity,
        uint256 _crossPollinationBoost,
        uint256 _harvestRateEnergy,
        uint256 _harvestRateComplexity,
        uint256 _minimumVotingStake,
        uint256 _proposalThreshold,
        uint48 _votingPeriod,
        uint256 _minFractalForProposal,
        uint256 _plantingFee
    )
        ERC721("EvolutionaryGardenFractal", "DEG-F")
        Ownable(msg.sender)
    {
        require(_nourishmentToken != address(0), "Invalid nourishment token address");
        require(_harvestToken != address(0), "Invalid harvest token address");
        require(_feeReceiver != address(0), "Invalid fee receiver address");
        // Basic sanity checks for initial parameters
        require(_baseGrowthRate > 0, "Growth rate must be positive");
         // Add more checks for other parameters as needed

        nourishmentToken = IERC20(_nourishmentToken);
        harvestToken = IERC20(_harvestToken);
        feeReceiver = _feeReceiver;

        params = GlobalParameters({
            baseGrowthRate: _baseGrowthRate,
            baseDecayRate: _baseDecayRate,
            nourishmentMultiplier: _nourishmentMultiplier,
            branchingCostEnergy: _branchingCostEnergy,
            branchingCostComplexity: _branchingCostComplexity,
            crossPollinationBoost: _crossPollinationBoost,
            harvestRateEnergy: _harvestRateEnergy,
            harvestRateComplexity: _harvestRateComplexity,
            minimumVotingStake: _minimumVotingStake,
            proposalThreshold: _proposalThreshold,
            votingPeriod: _votingPeriod,
            minFractalForProposal: _minFractalForProposal,
            plantingFee: _plantingFee
        });
    }

    // --- Core Logic: Planting, Nourishing, Evolution Trigger ---

    /**
     * @dev Mints a new Fractal NFT for the caller. Requires a fee.
     * Represents planting a seed in the garden.
     * @param seedDNA Basic properties encoded in a number.
     */
    function plantSeed(uint256 seedDNA) external payable nonReentrant {
        require(msg.value >= params.plantingFee, "Insufficient planting fee");

        _fractalIds.increment();
        uint256 newFractalId = _fractalIds.current();
        address newOwner = msg.sender;

        // Transfer fee to fee receiver
        if (params.plantingFee > 0) {
            (bool success, ) = payable(feeReceiver).call{value: params.plantingFee}("");
            require(success, "Fee transfer failed");
        }

        // Mint the NFT
        _mint(newOwner, newFractalId);

        // Initialize Fractal state (minimal starting values)
        fractals[newFractalId] = Fractal({
            id: newFractalId,
            seedDNA: seedDNA,
            complexity: (seedDNA % 100) + 1, // Basic initial complexity from DNA
            energy: (seedDNA % 50) + 1,     // Basic initial energy from DNA
            resilience: (seedDNA % 20) + 1, // Basic initial resilience from DNA
            nourishmentStaked: 0,
            lastUpdated: uint48(block.timestamp)
        });
        fractalNourishmentBalance[newFractalId] = 0;

        // Track user's fractals
        userFractals[newOwner].push(newFractalId);

        emit FractalPlanted(newFractalId, newOwner, seedDNA);
    }

    /**
     * @dev Stakes nourishment tokens on a fractal to boost its growth.
     * @param fractalId The ID of the fractal to nourish.
     * @param amount The amount of nourishment tokens to stake.
     */
    function nourishFractal(uint256 fractalId, uint256 amount) external nonReentrant {
        require(amount > 0, "Nourishment amount must be positive");
        require(_exists(fractalId), "Fractal does not exist");
        // require(ownerOf(fractalId) == msg.sender || isApprovedForAll(ownerOf(fractalId), msg.sender), "Not authorized to nourish this fractal"); // Optional: restrict nourishment to owner/approved

        // Ensure fractal state is up-to-date before adding nourishment
        growFractal(fractalId);

        // Transfer tokens from sender to this contract
        require(nourishmentToken.transferFrom(msg.sender, address(this), amount), "Nourishment transfer failed");

        // Update state
        fractals[fractalId].nourishmentStaked += amount;
        fractalNourishmentBalance[fractalId] += amount; // Keep separate balance tracking

        emit FractalNourished(fractalId, msg.sender, amount);
    }

    /**
     * @dev Withdraws staked nourishment tokens from a fractal.
     * Owner must initiate withdrawal.
     * @param fractalId The ID of the fractal.
     * @param amount The amount to withdraw.
     */
    function withdrawNourishment(uint256 fractalId, uint256 amount) external nonReentrant {
        require(_exists(fractalId), "Fractal does not exist");
        require(ownerOf(fractalId) == msg.sender, "Only owner can withdraw nourishment");
        require(amount > 0, "Withdrawal amount must be positive");
        require(fractalNourishmentBalance[fractalId] >= amount, "Insufficient staked nourishment");

        // Ensure fractal state is up-to-date before withdrawing
        growFractal(fractalId);

        // Update state before transfer
        fractals[fractalId].nourishmentStaked -= amount;
        fractalNourishmentBalance[fractalId] -= amount;

        // Transfer tokens to sender
        require(nourishmentToken.transfer(msg.sender, amount), "Nourishment withdrawal failed");

        emit NourishmentWithdrawn(fractalId, msg.sender, amount);
    }

    /**
     * @dev Triggers the evolution calculation for a fractal.
     * This updates its state based on time passed and nourishment.
     * Can be called by anyone to help a fractal evolve.
     * @param fractalId The ID of the fractal to grow.
     */
    function growFractal(uint256 fractalId) public nonReentrant {
        require(_exists(fractalId), "Fractal does not exist");

        Fractal storage fractal = fractals[fractalId];
        uint48 currentTime = uint48(block.timestamp);
        uint256 timeElapsed = currentTime - fractal.lastUpdated;

        if (timeElapsed == 0) {
            return; // Already up-to-date
        }

        // Calculate evolution based on time, nourishment, parameters
        // Simplified calculation:
        // Growth = (timeElapsed * baseGrowthRate + nourishmentStaked * nourishmentMultiplier) / SCALE_FACTOR
        // Decay = (timeElapsed * baseDecayRate) / SCALE_FACTOR
        // Resilience reduces decay proportionally

        // Use larger scale factor for calculations
        uint256 SCALE_FACTOR = 1e18;

        uint256 growth = (timeElapsed * params.baseGrowthRate + fractal.nourishmentStaked * params.nourishmentMultiplier) / SCALE_FACTOR;
        uint256 decay = (timeElapsed * params.baseDecayRate * (SCALE_FACTOR - Math.min(fractal.resilience, SCALE_FACTOR))) / (SCALE_FACTOR * SCALE_FACTOR); // Decay reduced by resilience

        // Apply changes, preventing underflow
        fractal.complexity = fractal.complexity + growth; // Complexity only grows for simplicity
        fractal.energy = fractal.energy > decay ? fractal.energy - decay : 0;
        fractal.resilience = fractal.resilience > decay ? fractal.resilience - decay : 0; // Resilience also decays

        fractal.lastUpdated = currentTime;

        emit FractalGrown(fractalId, fractal.complexity, fractal.energy, fractal.resilience);
    }

    /**
     * @dev Allows a mature fractal to create a new Seed (Fractal NFT).
     * Consumes fractal energy and complexity. Only owner can branch.
     * @param fractalId The ID of the fractal to branch.
     */
    function branchFractal(uint256 fractalId) external nonReentrant {
        require(_exists(fractalId), "Fractal does not exist");
        require(ownerOf(fractalId) == msg.sender, "Only owner can branch fractal");

        growFractal(fractalId); // Ensure state is current

        Fractal storage fractal = fractals[fractalId];

        require(fractal.energy >= params.branchingCostEnergy, "Not enough energy to branch");
        require(fractal.complexity >= params.branchingCostComplexity, "Not enough complexity to branch");

        // Deduct cost
        fractal.energy -= params.branchingCostEnergy;
        fractal.complexity -= params.branchingCostComplexity;

        // Create new seed DNA based on parent (example: simple combination/derivation)
        uint256 newSeedDNA = (fractal.seedDNA + fractal.complexity + fractal.resilience) % 10000;

        // Mint the new fractal (seed state)
        _fractalIds.increment();
        uint256 newFractalId = _fractalIds.current();
        address newOwner = msg.sender; // New fractal owned by the brancher

         _mint(newOwner, newFractalId);

        fractals[newFractalId] = Fractal({
            id: newFractalId,
            seedDNA: newSeedDNA,
            complexity: (newSeedDNA % 100) + 1, // Basic initial complexity from DNA
            energy: (newSeedDNA % 50) + 1,     // Basic initial energy from DNA
            resilience: (newSeedDNA % 20) + 1, // Basic initial resilience from DNA
            nourishmentStaked: 0,
            lastUpdated: uint48(block.timestamp)
        });
        fractalNourishmentBalance[newFractalId] = 0;
        userFractals[newOwner].push(newFractalId);


        emit BranchCreated(fractalId, newFractalId, newSeedDNA);
    }

    /**
     * @dev Allows two fractals to interact, influencing each other's state.
     * This simulates cross-pollination or beneficial symbiosis.
     * Can be called by anyone holding or approved for the fractals.
     * @param fractalId1 The ID of the first fractal.
     * @param fractalId2 The ID of the second fractal.
     */
    function crossPollinate(uint256 fractalId1, uint256 fractalId2) external nonReentrant {
        require(_exists(fractalId1), "Fractal 1 does not exist");
        require(_exists(fractalId2), "Fractal 2 does not exist");
        require(fractalId1 != fractalId2, "Cannot cross-pollinate a fractal with itself");

        // Optional: require caller authorization for both fractals
        // require(ownerOf(fractalId1) == msg.sender || isApprovedForAll(ownerOf(fractalId1), msg.sender), "Not authorized for fractal 1");
        // require(ownerOf(fractalId2) == msg.sender || isApprovedForAll(ownerOf(fractalId2), msg.sender), "Not authorized for fractal 2");

        growFractal(fractalId1); // Ensure states are current
        growFractal(fractalId2);

        Fractal storage fractal1 = fractals[fractalId1];
        Fractal storage fractal2 = fractals[fractalId2];

        // Simplified interaction logic: boost energy and resilience based on partner's complexity
        uint256 boostAmount1 = (fractal2.complexity * params.crossPollinationBoost) / 1e18;
        uint256 boostAmount2 = (fractal1.complexity * params.crossPollinationBoost) / 1e18;

        fractal1.energy += boostAmount1;
        fractal1.resilience += boostAmount1; // Boost resilience too
        fractal2.energy += boostAmount2;
        fractal2.resilience += boostAmount2; // Boost resilience too

        emit FractalsCrossPollinated(fractalId1, fractalId2, boostAmount1 + boostAmount2); // Emit total boost
    }

    /**
     * @dev Allows the owner to harvest value from a fractal.
     * Converts fractal energy/complexity into harvest tokens or new seeds.
     * Consumes the harvested properties.
     * @param fractalId The ID of the fractal to harvest.
     */
    function harvestFractal(uint256 fractalId) external nonReentrant {
        require(_exists(fractalId), "Fractal does not exist");
        require(ownerOf(fractalId) == msg.sender, "Only owner can harvest");

        growFractal(fractalId); // Ensure state is current

        Fractal storage fractal = fractals[fractalId];

        // Calculate harvest amount based on current state
        uint256 SCALE_FACTOR = 1e18;
        uint256 harvestAmount = (fractal.energy * params.harvestRateEnergy + fractal.complexity * params.harvestRateComplexity) / SCALE_FACTOR;

        require(harvestAmount > 0, "Fractal not ready for harvest (low energy/complexity)");

        // Deduct harvested properties (simplified: harvest consumes all energy/complexity)
        fractal.energy = 0;
        fractal.complexity = 0;
        // Resilience is unaffected by this type of harvest? Or decays heavily? Let's decay it.
        fractal.resilience = fractal.resilience > harvestAmount ? fractal.resilience - harvestAmount : 0;


        // Transfer harvest tokens
        // Note: Assumes the contract holds enough harvest tokens. A real system
        // might mint/distribute from a pool or require external top-up.
        require(harvestToken.transfer(msg.sender, harvestAmount), "Harvest token transfer failed");

        emit FractalHarvested(fractalId, msg.sender, harvestAmount);
    }

    // --- Governance Logic ---

    /**
     * @dev Proposes a change to a global garden parameter.
     * Requires meeting the minimum stake/fractal requirement.
     * @param parameterName The exact name of the parameter struct field (e.g., "baseGrowthRate").
     * @param newValue The proposed new value (use int256 to allow decreasing values).
     * @param description A description of the proposal.
     */
    function proposeParameterChange(string memory parameterName, int255 newValue, string memory description) external nonReentrant {
        // Check proposer eligibility (e.g., minimum complexity/energy across owned fractals)
        // Simplified check: require a certain number of owned fractals above a complexity threshold
        uint256 eligibleFractals = 0;
        uint256[] storage ownedFractals = userFractals[msg.sender];
        for (uint i = 0; i < ownedFractals.length; i++) {
             growFractal(ownedFractals[i]); // Update fractal state before checking
             if (fractals[ownedFractals[i]].complexity >= params.minFractalForProposal) {
                 eligibleFractals++;
             }
        }
        require(eligibleFractals >= params.minFractalForProposal, "Proposer does not meet minimum fractal requirement");

        // Basic check for valid parameter name (can extend with a mapping or list)
        bool validParam = false;
        bytes32 paramNameHash = keccak256(abi.encodePacked(parameterName));
        if (paramNameHash == keccak256(abi.encodePacked("baseGrowthRate")) ||
            paramNameHash == keccak256(abi.encodePacked("baseDecayRate")) ||
            paramNameHash == keccak256(abi.encodePacked("nourishmentMultiplier")) ||
            paramNameHash == keccak256(abi.encodePacked("branchingCostEnergy")) ||
            paramNameHash == keccak256(abi.encodePacked("branchingCostComplexity")) ||
            paramNameHash == keccak256(abi.encodePacked("crossPollinationBoost")) ||
            paramNameHash == keccak256(abi.encodePacked("harvestRateEnergy")) ||
            paramNameHash == keccak256(abi.encodePacked("harvestRateComplexity")) ||
            paramNameHash == keccak256(abi.encodePacked("minimumVotingStake")) ||
            paramNameHash == keccak256(abi.encodePacked("proposalThreshold")) ||
            paramNameHash == keccak256(abi.encodePacked("votingPeriod")) ||
            paramNameHash == keccak256(abi.encodePacked("minFractalForProposal")) ||
            paramNameHash == keccak256(abi.encodePacked("plantingFee"))
            ) {
            validParam = true;
        }
        require(validParam, "Invalid parameter name");


        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        // Find one of the proposer's eligible fractals to link the proposal to
        uint256 proposerEligibleFractalId = 0;
         for (uint i = 0; i < ownedFractals.length; i++) {
             if (fractals[ownedFractals[i]].complexity >= params.minFractalForProposal) {
                 proposerEligibleFractalId = ownedFractals[i];
                 break;
             }
        }


        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterName: parameterName,
            newValue: newValue,
            description: description,
            proposerFractalId: proposerEligibleFractalId,
            votingDeadline: uint48(block.timestamp + params.votingPeriod),
            yeas: 0,
            nays: 0,
            executed: false,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender, parameterName, newValue);
    }

    /**
     * @dev Casts a vote on an active proposal. Voting power could be based on staked nourishment.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'Yes', False for 'No'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        // Determine voting power (e.g., total nourishment staked across all user's fractals)
        uint256 userVotingPower = 0;
        uint256[] storage ownedFractals = userFractals[msg.sender];
        for (uint i = 0; i < ownedFractals.length; i++) {
             // No need to call growFractal here, just use the nourishment balance
             userVotingPower += fractalNourishmentBalance[ownedFractals[i]];
        }

        // Simplified: require minimum *total* nourishment stake OR min fractals for voting power
        // This example uses minimum stake for voting power calculation
        require(userVotingPower >= params.minimumVotingStake, "Does not meet minimum voting stake");


        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yeas += userVotingPower;
        } else {
            proposal.nays += userVotingPower;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal if it has passed the voting period and threshold.
     * Anyone can call this after the voting deadline.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        // Check if proposal passed (e.g., yeas > nays and yeas meet threshold percentage of total voting power)
        // Simplified threshold check: yeas must be > nays and yeas >= a percentage of (yeas + nays)
        uint256 totalVotes = proposal.yeas + proposal.nays;
        bool passed = proposal.yeas > proposal.nays &&
                      (proposal.yeas * 10000) / (totalVotes == 0 ? 1 : totalVotes) >= params.proposalThreshold; // Use 10000 for percentage scaled to 4 decimals

        if (!passed) {
            proposal.state = ProposalState.Failed;
            return;
        }

        // --- Execute the parameter change ---
        bytes32 paramNameHash = keccak256(abi.encodePacked(proposal.parameterName));
        int256 newValue = proposal.newValue; // Use int256 for assignment

        if (paramNameHash == keccak256(abi.encodePacked("baseGrowthRate"))) {
            params.baseGrowthRate = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("baseDecayRate"))) {
             params.baseDecayRate = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("nourishmentMultiplier"))) {
             params.nourishmentMultiplier = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("branchingCostEnergy"))) {
             params.branchingCostEnergy = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("branchingCostComplexity"))) {
             params.branchingCostComplexity = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("crossPollinationBoost"))) {
             params.crossPollinationBoost = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("harvestRateEnergy"))) {
             params.harvestRateEnergy = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("harvestRateComplexity"))) {
             params.harvestRateComplexity = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("minimumVotingStake"))) {
             params.minimumVotingStake = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalThreshold"))) {
             params.proposalThreshold = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("votingPeriod"))) {
             params.votingPeriod = uint48(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("minFractalForProposal"))) {
             params.minFractalForProposal = uint256(newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("plantingFee"))) {
             params.plantingFee = uint256(newValue);
        } else {
            // Should not happen if proposeParameterChange validates names
            revert("Unknown parameter");
        }
        // --- End Execution ---


        proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution
        proposal.executed = true;
        proposal.state = ProposalState.Executed; // Mark as executed

        emit ProposalExecuted(proposalId, proposal.parameterName, proposal.newValue);
        emit ParameterChanged(proposal.parameterName, proposal.newValue);
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the address of the ERC20 token used for nourishment.
     * Should likely be under governance control in a production system.
     */
    function setNourishmentToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        nourishmentToken = IERC20(_token);
    }

    /**
     * @dev Sets the address of the ERC20 token used for harvesting.
     * Should likely be under governance control in a production system.
     */
    function setHarvestToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        harvestToken = IERC20(_token);
    }

    /**
     * @dev Sets the address of an oracle contract for potential external data.
     * (Conceptual - the oracle is not integrated into logic in this example)
     * Should likely be under governance control in a production system.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        oracleAddress = _oracle;
    }

    /**
     * @dev Allows the owner to withdraw collected native currency fees (e.g., planting fees).
     * @param tokenAddress Address of the token to withdraw (currently only supports native token).
     */
    function withdrawAdminFees(address tokenAddress) external onlyOwner nonReentrant {
        // In this simplified example, only native token fees (from planting) are collected.
        // If other tokens were collected (e.g., % of harvest), logic would need to handle them.
        require(tokenAddress == address(0), "Only native token withdrawal supported currently"); // Use address(0) for ETH

        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");

        (bool success, ) = payable(feeReceiver).call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit AdminFeesWithdrawn(tokenAddress, feeReceiver, balance);
    }


    // --- View Functions ---

    /**
     * @dev Gets detailed information about a specific fractal.
     * @param fractalId The ID of the fractal.
     * @return Fractal struct containing state details.
     */
    function getFractalInfo(uint256 fractalId) public view returns (Fractal memory) {
        require(_exists(fractalId), "Fractal does not exist");
        return fractals[fractalId];
    }

    /**
     * @dev Gets the list of fractal IDs owned by a specific user.
     * @param user The address of the user.
     * @return An array of fractal IDs.
     */
    function getUserFractals(address user) public view returns (uint256[] memory) {
        return userFractals[user];
    }

    /**
     * @dev Gets the current values of all global garden parameters.
     * @return GlobalParameters struct.
     */
    function getGlobalParameters() public view returns (GlobalParameters memory) {
        return params;
    }

    /**
     * @dev Gets detailed information about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct.
     */
    function getProposalInfo(uint256 proposalId) public view returns (Proposal memory) {
        require(proposalId > 0 && proposalId <= _proposalIds.current(), "Proposal does not exist");
        return proposals[proposalId];
    }

     /**
     * @dev Gets the total number of governance proposals created.
     * @return The total count.
     */
    function getProposalCount() public view returns (uint256) {
        return _proposalIds.current();
    }

    /**
     * @dev Gets the current staked nourishment balance for a specific fractal.
     * @param fractalId The ID of the fractal.
     * @return The amount of nourishment tokens staked.
     */
    function getFractalNourishmentBalance(uint256 fractalId) public view returns (uint256) {
        require(_exists(fractalId), "Fractal does not exist");
        return fractalNourishmentBalance[fractalId];
    }


    // --- ERC721 Standard Overrides ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        // Example: Generate a simple base64 encoded JSON URI dynamically
        // In a real dapp, this would likely fetch complex metadata from IPFS
        // and potentially include fractal state properties.
        Fractal storage fractal = fractals[tokenId];
        string memory baseURI = "data:application/json;base64,";
        string memory json = string(abi.encodePacked(
            '{"name": "Fractal #', uint256ToString(tokenId), '",',
            '"description": "An evolving digital entity in the Decentralized Evolutionary Garden.",',
            '"attributes": [',
                '{"trait_type": "Complexity", "value": ', uint256ToString(fractal.complexity), '},',
                '{"trait_type": "Energy", "value": ', uint256ToString(fractal.energy), '},',
                '{"trait_type": "Resilience", "value": ', uint256ToString(fractal.resilience), '}',
            ']}'
        ));
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    // Helper function for tokenURI (basic uint256 to string)
    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    // Required by ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Override _beforeTokenTransfer to update userFractals mapping
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) {
            // Minting - add to userFractals
            // This assumes plantSeed mints one at a time. If batch minting was added, this needs adjustment.
             // userFractals[to].push(tokenId); // This line would be here IF plantSeed didn't handle it already
        } else if (to == address(0)) {
            // Burning - remove from userFractals
            // This logic for removing from a dynamic array is inefficient.
            // A better approach for user tracking would be a linked list or a mapping
            // from fractalId to its index in the user's array, updated on moves/removes.
            // For this example, we'll leave it simplified. Removing elements from the middle
            // of a Solidity array is gas-expensive.
        } else {
             // Transfer - remove from sender, add to receiver
             // This also requires array manipulation logic.

             // Given the inefficiency, the userFractals mapping might be better generated
             // by iterating all fractals client-side, or using a different data structure.
             // For demonstration, we'll just acknowledge this limitation here and *not*
             // add complex array removal/addition logic in _beforeTokenTransfer, as
             // it significantly adds complexity and gas cost for basic transfers.
             // The current implementation relies on `plantSeed` adding to the array.
             // A robust implementation would need to handle removes/adds on transfers/burns.
        }
    }


    // Re-expose ERC721 functions manually if needed (often not required due to public/external visibility)
    // function balanceOf(address owner) public view override returns (uint256) { return super.balanceOf(owner); }
    // function ownerOf(uint256 tokenId) public view override returns (address) { return super.ownerOf(tokenId); }
    // function getApproved(uint256 tokenId) public view override returns (address) { return super.getApproved(tokenId); }
    // function isApprovedForAll(address owner, address operator) public view override returns (bool) { return super.isApprovedForAll(owner, operator); }


}

// Simple Base64 library for data URI (taken from Solady or similar common sources)
// Provides basic encoding for the tokenURI function.
library Base64 {
    string internal constant base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // The maximum length of the encoded data is 4/3 times the length of the input, rounded up.
        // So, a 3-byte input yields a 4-byte output.
        uint256 encodedLen = (data.length + 2) / 3 * 4;
        bytes memory result = new bytes(encodedLen);

        // Encode all but the last 0, 1, or 2 bytes of the input.
        uint256 inputPtr = 0;
        uint256 outputPtr = 0;
        while (inputPtr < data.length - 2) {
            uint256 input = (uint256(data[inputPtr]) << 16) | (uint256(data[inputPtr + 1]) << 8) | uint256(data[inputPtr + 2]);
            result[outputPtr++] = bytes1(base64Chars[input >> 18]);
            result[outputPtr++] = bytes1(base64Chars[(input >> 12) & 0x3F]);
            result[outputPtr++] = bytes1(base64Chars[(input >> 6) & 0x3F]);
            result[outputPtr++] = bytes1(base64Chars[input & 0x3F]);
            inputPtr += 3;
        }

        // Handle the remaining 0, 1, or 2 bytes.
        uint256 remaining = data.length - inputPtr;
        if (remaining == 1) {
            uint256 input = uint256(data[inputPtr]);
            result[outputPtr++] = bytes1(base64Chars[input >> 2]);
            result[outputPtr++] = bytes1(base64Chars[(input & 0x03) << 4]);
            result[outputPtr++] = "=";
            result[outputPtr++] = "=";
        } else if (remaining == 2) {
            uint256 input = (uint256(data[inputPtr]) << 8) | uint256(data[inputPtr + 1]);
            result[outputPtr++] = bytes1(base64Chars[input >> 10]);
            result[outputPtr++] = bytes1(base64Chars[(input >> 4) & 0x3F]);
            result[outputPtr++] = bytes1(base64Chars[(input & 0x0F) << 2]);
            result[outputPtr++] = "=";
        }

        return string(result);
    }
}
```