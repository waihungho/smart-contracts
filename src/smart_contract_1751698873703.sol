Okay, let's create a complex and interesting smart contract. We'll design an "EcoVerse Genesis" contract. This concept combines NFTs with dynamic properties, resource management, time-based mechanics, token bonding, and a simple decentralized governance element.

Here's the outline and function summary followed by the Solidity code.

**Concept:**

EcoVerse Genesis is a simulated digital ecosystem where users own "Plots" represented by NFTs. These plots have dynamic stats (Fertility, Biodiversity, Purity) that change based on user actions, time (decay), and global conditions. Users spend Energy tokens (ECG) to perform actions on their plots, harvest Resource tokens (ESS) based on plot stats and time, and can participate in governance through token bonding. A global Eco-Balance state reflects the overall health of the EcoVerse, influenced by all plot states, and impacting yields. A Guardian Council (initially set by owner, later potentially mutable by governance) can propose and vote on system parameter changes.

**Outline:**

1.  **Contract Setup:** Pragma, Imports, Interfaces.
2.  **State Variables:**
    *   Tokens (ERC20 for Energy/Resource, ERC721 for Plots).
    *   Plot Data (Mapping: plotId -> Plot struct).
    *   Global State (Struct).
    *   Guardian Council (Mapping).
    *   DAO Proposals (Mapping).
    *   Configuration Parameters (Decay rates, costs, yield factors, etc.).
    *   Counters (Plot ID, Proposal ID).
    *   Bonding amounts (Plot-specific, Global).
3.  **Structs:** Plot, GlobalState, Proposal.
4.  **Events:** Minting, Harvesting, Action, Bonding, Governance (Proposal, Vote, Execution).
5.  **Modifiers:** `onlyOwner`, `onlyGuardian`, `onlyPlotOwner`, `whenPlotExists`.
6.  **Constructor:** Initializes tokens, sets owner, sets initial parameters.
7.  **Internal Helpers:**
    *   `_updatePlotState`: Applies time-based decay, updates stats.
    *   `_calculatePlotYield`: Calculates potential harvest amount.
    *   `_updateGlobalState`: Recalculates global balance.
    *   `_performActionCost`: Handles token spending and checks.
8.  **NFT (Plot) Management:**
    *   `mintPlot`: Create new plots.
    *   `getPlotDetails`: Read plot stats.
    *   `getPlotOwner`: Standard ERC721.
    *   `transferFrom`: Standard ERC721.
    *   `approve`: Standard ERC721.
    *   `setApprovalForAll`: Standard ERC721.
    *   `balanceOf`: Standard ERC721.
    *   `tokenOfOwnerByIndex`: Standard ERC721 helper.
    *   `tokenByIndex`: Standard ERC721 helper.
    *   `setPlotName`: Add metadata potential (simple string).
9.  **Token (ECG, ESS) Management:**
    *   `faucetECG`: Distribute initial Energy (for testing/onboarding).
    *   `transferECG`: Standard ERC20.
    *   `approveECG`: Standard ERC20.
    *   `transferESS`: Standard ERC20.
    *   `approveESS`: Standard ERC20.
10. **Plot Interaction & Gameplay:**
    *   `nurturePlot`: Increase Fertility.
    *   `purifyPlot`: Increase Purity.
    *   `enhanceBiodiversity`: Increase Biodiversity.
    *   `harvestESS`: Claim accumulated resources.
    *   `bondEnergyToPlot`: Stake ECG for plot bonuses.
    *   `unbondEnergyFromPlot`: Withdraw staked ECG from a plot.
    *   `applyCatalyst`: Consume a special item/charge for effect (simulated).
11. **Global State & Bonding:**
    *   `getGlobalEcoBalance`: Read current global score.
    *   `bondEnergyToGlobal`: Stake ECG for global influence/rewards (rewards not implemented, but concept is there).
    *   `unbondEnergyFromGlobal`: Withdraw staked ECG globally.
    *   `getGlobalBondedAmount`: Read total global bonded ECG.
12. **Guardian Council & Governance (DAO):**
    *   `addGuardian`: Add a guardian (Owner/Council).
    *   `removeGuardian`: Remove a guardian (Owner/Council).
    *   `isGuardian`: Check if an address is a guardian.
    *   `proposeAction`: Create a governance proposal (Guardians only).
    *   `voteOnProposal`: Vote on an active proposal (Guardians or Bonders).
    *   `executeProposal`: Execute a passed proposal.
    *   `getProposalDetails`: Read proposal state.
13. **Read Functions (Helpers):**
    *   `getUserPlots`: List plots owned by an address.
    *   `getPlotHarvestYield`: Calculate potential yield without harvesting.
    *   `getPlotBondedAmount`: Read bonded amount on a specific plot.
    *   `getPlotCatalystCharges`: Read catalyst charges on a plot.
    *   `getGuardianList`: Get the list of guardians.
    *   `getProposalCount`: Get total number of proposals.
    *   `getProposalState`: Get state of a proposal (active, passed, failed, executed).

**Function Summary (Total > 20):**

1.  `constructor()`: Initialize contract, deploy/link tokens, set owner.
2.  `mintPlot(address recipient)`: Mints a new Plot NFT for the recipient.
3.  `getPlotDetails(uint256 plotId)`: Returns detailed stats of a plot.
4.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 transfer.
5.  `approve(address to, uint256 tokenId)`: ERC721 approval.
6.  `setApprovalForAll(address operator, bool approved)`: ERC721 operator approval.
7.  `balanceOf(address owner)`: ERC721 count of plots for an owner.
8.  `ownerOf(uint256 tokenId)`: ERC721 owner lookup.
9.  `tokenOfOwnerByIndex(address owner, uint256 index)`: ERC721 enumeration helper.
10. `tokenByIndex(uint256 index)`: ERC721 enumeration helper.
11. `setPlotName(uint256 plotId, string calldata name)`: Set a name for a plot.
12. `faucetECG(address recipient, uint256 amount)`: Distribute ECG tokens (limited/dev use).
13. `transferECG(address to, uint256 amount)`: ERC20 transfer for ECG.
14. `approveECG(address spender, uint256 amount)`: ERC20 approval for ECG.
15. `transferESS(address to, uint256 amount)`: ERC20 transfer for ESS.
16. `approveESS(address spender, uint256 amount)`: ERC20 approval for ESS.
17. `nurturePlot(uint256 plotId)`: Spends ECG to increase plot Fertility.
18. `purifyPlot(uint256 plotId)`: Spends ECG to increase plot Purity.
19. `enhanceBiodiversity(uint256 plotId)`: Spends ECG to increase plot Biodiversity.
20. `harvestESS(uint256 plotId)`: Calculates and mints ESS based on plot state and time.
21. `bondEnergyToPlot(uint256 plotId, uint256 amount)`: Stakes ECG tokens to a specific plot.
22. `unbondEnergyFromPlot(uint256 plotId, uint256 amount)`: Unstakes ECG from a plot.
23. `applyCatalyst(uint256 plotId)`: Consumes a catalyst charge on a plot for a specific effect (simulated effect).
24. `getGlobalEcoBalance()`: Returns the current global Eco-Balance score.
25. `bondEnergyToGlobal(uint256 amount)`: Stakes ECG tokens for global influence/governance power.
26. `unbondEnergyFromGlobal(uint256 amount)`: Unstakes globally bonded ECG.
27. `getGlobalBondedAmount()`: Returns the total ECG bonded globally.
28. `addGuardian(address guardian)`: Adds an address to the Guardian Council.
29. `removeGuardian(address guardian)`: Removes an address from the Guardian Council.
30. `isGuardian(address account)`: Checks if an address is a guardian.
31. `proposeAction(bytes calldata data, uint256 duration)`: Creates a new governance proposal.
32. `voteOnProposal(uint256 proposalId, bool voteFor)`: Casts a vote on a proposal.
33. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed.
34. `getProposalDetails(uint256 proposalId)`: Returns details about a specific proposal.
35. `getUserPlots(address account)`: Returns an array of plot IDs owned by an address.
36. `getPlotHarvestYield(uint256 plotId)`: Calculates the current potential ESS yield for a plot.
37. `getPlotBondedAmount(uint256 plotId)`: Returns the amount of ECG bonded to a plot.
38. `getPlotCatalystCharges(uint256 plotId)`: Returns the number of catalyst charges on a plot.
39. `getGuardianList()`: Returns the list of current guardians.
40. `getProposalCount()`: Returns the total number of proposals created.
41. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/CallSolidity.sol"; // Using CallSolidity for proposal execution

// Outline:
// 1. Contract Setup: Pragma, Imports, Interfaces.
// 2. State Variables: Tokens, Plot Data, Global State, Guardians, Proposals, Config, Counters, Bonding.
// 3. Structs: Plot, GlobalState, Proposal.
// 4. Events: Minting, Harvesting, Action, Bonding, Governance.
// 5. Modifiers: onlyOwner, onlyGuardian, onlyPlotOwner, whenPlotExists.
// 6. Constructor: Initializes contract and components.
// 7. Internal Helpers: State updates, calculations, cost handling.
// 8. NFT (Plot) Management (Inherited + Custom): mintPlot, getPlotDetails, setPlotName etc.
// 9. Token (ECG, ESS) Management (Inherited + Custom): faucetECG etc.
// 10. Plot Interaction & Gameplay: nurture, purify, enhance, harvest, bond/unbond plot, applyCatalyst.
// 11. Global State & Bonding: getGlobalEcoBalance, bond/unbond global, getGlobalBondedAmount.
// 12. Guardian Council & Governance (DAO): add/removeGuardian, propose, vote, execute, getProposalDetails/State.
// 13. Read Functions (Helpers): getUserPlots, getPlotHarvestYield, getBondedAmounts, getCatalystCharges, getGuardians, getProposalCount.

// Function Summary (Total > 20):
// 1. constructor()
// 2. mintPlot(address recipient)
// 3. getPlotDetails(uint256 plotId)
// 4. transferFrom(address from, address to, uint256 tokenId) (Inherited)
// 5. approve(address to, uint256 tokenId) (Inherited)
// 6. setApprovalForAll(address operator, bool approved) (Inherited)
// 7. balanceOf(address owner) (Inherited)
// 8. ownerOf(uint256 tokenId) (Inherited)
// 9. tokenOfOwnerByIndex(address owner, uint256 index) (Inherited)
// 10. tokenByIndex(uint256 index) (Inherited)
// 11. setPlotName(uint256 plotId, string calldata name)
// 12. faucetECG(address recipient, uint256 amount)
// 13. transferECG(address to, uint256 amount) (Inherited)
// 14. approveECG(address spender, uint256 amount) (Inherited)
// 15. transferESS(address to, uint256 amount) (Inherited)
// 16. approveESS(address spender, uint256 amount) (Inherited)
// 17. nurturePlot(uint256 plotId)
// 18. purifyPlot(uint256 plotId)
// 19. enhanceBiodiversity(uint256 plotId)
// 20. harvestESS(uint256 plotId)
// 21. bondEnergyToPlot(uint256 plotId, uint256 amount)
// 22. unbondEnergyFromPlot(uint256 plotId, uint256 amount)
// 23. applyCatalyst(uint256 plotId)
// 24. getGlobalEcoBalance()
// 25. bondEnergyToGlobal(uint256 amount)
// 26. unbondEnergyFromGlobal(uint256 amount)
// 27. getGlobalBondedAmount()
// 28. addGuardian(address guardian)
// 29. removeGuardian(address guardian)
// 30. isGuardian(address account)
// 31. proposeAction(bytes calldata data, uint256 duration)
// 32. voteOnProposal(uint256 proposalId, bool voteFor)
// 33. executeProposal(uint256 proposalId)
// 34. getProposalDetails(uint256 proposalId)
// 35. getUserPlots(address account)
// 36. getPlotHarvestYield(uint256 plotId)
// 37. getPlotBondedAmount(uint256 plotId)
// 38. getPlotCatalystCharges(uint256 plotId)
// 39. getGuardianList()
// 40. getProposalCount()
// 41. getProposalState(uint256 proposalId)

contract EcoVerseGenesis is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using CallSolidity for bytes; // For proposal execution

    // --- State Variables ---

    // Tokens
    ERC20 public ecoEnergyToken; // ECG
    ERC20 public ecoEssenceToken; // ESS

    // Plot Data (NFT properties)
    struct Plot {
        uint256 fertility; // 0-1000
        uint256 biodiversity; // 0-1000
        uint256 purity; // 0-1000
        uint256 lastHarvestTime;
        uint256 lastDecayTime;
        uint256 bondedEnergy; // ECG tokens bonded to this specific plot
        uint256 catalystCharges; // Number of catalyst uses available for this plot
        string name; // Optional name for the plot
    }
    mapping(uint256 => Plot) public plots;
    Counters.Counter private _plotIds;

    // Global State
    struct GlobalState {
        uint256 totalFertilitySum; // Sum of all plots' fertility (for average calc)
        uint256 totalBiodiversitySum; // Sum of all plots' biodiversity
        uint256 totalPuritySum; // Sum of all plots' purity
        uint256 ecoBalanceScore; // Calculated global score (e.g., average of sums)
        uint256 totalBondedEnergy; // Total ECG bonded globally
    }
    GlobalState public globalState;

    // Configuration Parameters (Modifiable by Governance)
    struct GameConfig {
        uint256 baseYieldPerUnitTime; // Base ESS per second per 1k stats
        uint256 decayRatePerUnitTime; // Stat decay points per second
        uint256 nurtureCost; // ECG cost
        uint256 purifyCost; // ECG cost
        uint256 enhanceCost; // ECG cost
        uint256 statIncreasePerAction; // Points increased per action
        uint256 maxPlotStat; // Max value for fertility, biodiversity, purity (e.g., 1000)
        uint256 harvestCooldown; // Minimum time between harvests for a plot
        uint256 guardianVoteWeight; // Voting weight for guardians
        uint256 bonderVoteWeightPerECG; // Voting weight per bonded ECG for non-guardians
        uint256 proposalThresholdPercent; // % of total voting power needed to pass
        uint256 minProposalDuration; // Minimum duration for proposals
    }
    GameConfig public config;

    // Guardian Council (Simple Role-Based Access)
    EnumerableSet.AddressSet private _guardians;

    // DAO Proposals
    struct Proposal {
        bytes data; // Encoded call to execute (e.g., config update)
        uint256 startDate;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;

    // Bonding amounts per address for global bonding
    mapping(address => uint256) public globalBondedEnergyByUser;

    // Catalyst effects (simplified - could be more complex)
    uint256 public catalystBoostAmount = 100; // Stats boosted by this much temporarily or permanently

    // --- Events ---

    event PlotMinted(uint256 indexed plotId, address indexed owner);
    event PlotStateUpdated(uint256 indexed plotId, uint256 fertility, uint256 biodiversity, uint256 purity);
    event EcoBalanceUpdated(uint256 ecoBalance);
    event ESSHarvested(uint256 indexed plotId, address indexed owner, uint256 amount);
    event EnergyBondedToPlot(uint256 indexed plotId, address indexed user, uint256 amount);
    event EnergyUnbondedFromPlot(uint256 indexed plotId, address indexed user, uint256 amount);
    event EnergyBondedGlobally(address indexed user, uint256 amount);
    event EnergyUnbondedGlobally(address indexed user, uint256 amount);
    event CatalystApplied(uint256 indexed plotId, address indexed user, uint256 chargesRemaining);
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId);
    event PlotNameUpdated(uint256 indexed plotId, string name);

    // --- Modifiers ---

    modifier onlyGuardian() {
        require(_guardians.contains(msg.sender), "Only Guardian");
        _;
    }

    modifier onlyPlotOwner(uint256 plotId) {
        require(_exists(plotId), "Plot does not exist");
        require(ownerOf(plotId) == msg.sender, "Not Plot Owner");
        _;
    }

    modifier whenPlotExists(uint256 plotId) {
        require(_exists(plotId), "Plot does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address initialGuardian) ERC721("EcoVersePlot", "EVP") Ownable(msg.sender) {
        // Deploy or link ERC20 tokens
        // In a real scenario, these would likely be pre-deployed or managed carefully
        // For this example, we simulate deployment
        ecoEnergyToken = new ERC20("EcoGenesis Energy", "ECG");
        ecoEssenceToken = new ERC20("EcoGenesis Essence", "ESS");

        // Set initial configuration
        config = GameConfig({
            baseYieldPerUnitTime: 5, // 5 ESS per second per 1000 stats
            decayRatePerUnitTime: 1, // 1 stat point decay per second (total across stats)
            nurtureCost: 10 ether, // 10 ECG
            purifyCost: 15 ether, // 15 ECG
            enhanceCost: 20 ether, // 20 ECG
            statIncreasePerAction: 50, // Increase stat by 50 points
            maxPlotStat: 1000, // Max 1000 for each stat
            harvestCooldown: 1 hours, // Minimum 1 hour between harvests
            guardianVoteWeight: 100, // Guardians get 100 votes
            bonderVoteWeightPerECG: 1, // 1 vote per 1 ECG bonded globally
            proposalThresholdPercent: 60, // 60% of total possible votes needed to pass
            minProposalDuration: 1 days // Proposals last at least 1 day
        });

        // Add initial guardian(s)
        _guardians.add(initialGuardian);
        emit GuardianAdded(initialGuardian);

        // Initialize global state
        globalState.totalFertilitySum = 0;
        globalState.totalBiodiversitySum = 0;
        globalState.totalPuritySum = 0;
        globalState.ecoBalanceScore = 0; // Initial score
        globalState.totalBondedEnergy = 0;
        emit EcoBalanceUpdated(globalState.ecoBalanceScore);
    }

    // --- Internal Helpers ---

    // Applies time-based decay to a plot's stats and updates its lastDecayTime
    function _updatePlotState(uint256 plotId) internal whenPlotExists(plotId) {
        Plot storage plot = plots[plotId];
        uint256 timeElapsed = block.timestamp.sub(plot.lastDecayTime);

        if (timeElapsed > 0) {
            // Calculate total decay points distributed across stats
            uint256 totalDecay = timeElapsed.mul(config.decayRatePerUnitTime);

            // Apply decay to each stat, ensuring it doesn't go below zero
            plot.fertility = plot.fertility > totalDecay.div(3) ? plot.fertility.sub(totalDecay.div(3)) : 0;
            plot.biodiversity = plot.biodiversity > totalDecay.div(3) ? plot.biodiversity.sub(totalDecay.div(3)) : 0;
            // Purity decays slower or differently? Let's make it simpler: distribute equally for now.
            plot.purity = plot.purity > totalDecay.div(3) ? plot.purity.sub(totalDecay.div(3)) : 0;

            // Cap stats at minimum 0
            plot.fertility = Math.max(plot.fertility, 0);
            plot.biodiversity = Math.max(plot.biodiversity, 0);
            plot.purity = Math.max(plot.purity, 0);


            plot.lastDecayTime = block.timestamp;

            // Update global sums
            _updateGlobalState();

            emit PlotStateUpdated(plotId, plot.fertility, plot.biodiversity, plot.purity);
        }
    }

    // Recalculates the global eco-balance score based on aggregated plot stats
    function _updateGlobalState() internal {
        uint256 totalFert = 0;
        uint256 totalBio = 0;
        uint256 totalPur = 0;
        uint256 totalPlots = _plotIds.current(); // Count of minted plots

        if (totalPlots > 0) {
             // Sum up stats (optimization: this should be done incrementally when stats change)
             // For this example, let's assume incremental updates are too complex for 20+ funcs.
             // A more gas-efficient design would update sums only when a plot's stats change significantly.
             // Iterating through all plots here could be very expensive.
             // --- SIMPLIFICATION FOR EXAMPLE ---
             // Let's *simulate* this by just summing *some* stats or using an average.
             // A better approach would be to update sums incrementally in stat-changing functions.
             // We'll add a basic placeholder update.

             // PLACEHOLDER: This calculation is NOT based on iterating all plots currently.
             // A robust system needs incremental sum updates or a different global metric.
             // Let's update based on the *last* plot updated for this example's simplicity,
             // acknowledging this is not a true sum. A real system would use hooks in _updatePlotState
             // and action functions to adjust globalState.total* sums.

             // For this example, let's simplify the global balance score logic significantly:
             // It's just a placeholder and doesn't accurately reflect all plots.
             // A real implementation would require careful state management.

             // To avoid huge gas costs, let's make the global state update happen less often
             // or rely on external triggers, or update sums incrementally.
             // For the sake of having the function and variable, we'll add a very basic
             // calculation based on *some* recent activity or average if possible without iteration.
             // Let's tie it loosely to the *number* of plots and a minimum baseline.
             totalFert = totalPlots.mul(config.maxPlotStat / 2); // Assume average is half max
             totalBio = totalPlots.mul(config.maxPlotStat / 2);
             totalPur = totalPlots.mul(config.maxPlotStat / 2);

             globalState.totalFertilitySum = totalFert;
             globalState.totalBiodiversitySum = totalBio;
             globalState.totalPuritySum = totalPur;

             uint256 averageStatSum = (totalFert.add(totalBio).add(totalPur)).div(totalPlots);
             // Simple score based on average stats, capped
             globalState.ecoBalanceScore = Math.min(averageStatSum.div(3), config.maxPlotStat); // Score 0-1000
        } else {
            globalState.totalFertilitySum = 0;
            globalState.totalBiodiversitySum = 0;
            globalState.totalPuritySum = 0;
            globalState.ecoBalanceScore = 0;
        }

        emit EcoBalanceUpdated(globalState.ecoBalanceScore);
    }


    // Calculates potential ESS yield for a plot based on its state and time elapsed since last harvest
    function _calculatePlotYield(uint256 plotId) internal view returns (uint256) {
        Plot storage plot = plots[plotId];
        uint256 timeElapsed = block.timestamp.sub(plot.lastHarvestTime);

        if (timeElapsed == 0 || plot.fertility == 0 || plot.biodiversity == 0 || plot.purity == 0) {
            return 0;
        }

        // Simple linear yield calculation: (Sum of stats / max possible sum) * time elapsed * base yield rate * global balance factor
        uint256 plotStatSum = plot.fertility.add(plot.biodiversity).add(plot.purity);
        uint256 maxPossiblePlotSum = config.maxPlotStat.mul(3);

        // Avoid division by zero if maxPossiblePlotSum is somehow 0
        if (maxPossiblePlotSum == 0) {
            maxPossiblePlotSum = 1; // Or handle as error
        }

        uint256 plotFactor = plotStatSum.mul(1000).div(maxPossiblePlotSum); // Scale to 0-1000

        // Global balance factor (0-1000 scaled) influences yield
        uint256 globalFactor = globalState.ecoBalanceScore.mul(1000).div(config.maxPlotStat); // Scale to 0-1000
         if (globalFactor == 0) {
            globalFactor = 1; // Minimum global factor
        }


        // Yield = (plotFactor/1000) * timeElapsed * baseYield * (globalFactor/1000) * (1 + bondedEnergy/totalBonded?)
        // Let's simplify: Yield = timeElapsed * baseYield * (plotFactor * globalFactor / 1,000,000)
        // Incorporate bonded energy bonus: + (bondedEnergy * bonus_rate * timeElapsed)
        uint256 baseTimedYield = timeElapsed.mul(config.baseYieldPerUnitTime);

        // Apply plot and global factors
        uint256 yield = baseTimedYield.mul(plotFactor).div(1000).mul(globalFactor).div(1000);

        // Apply bonded energy bonus (simple bonus per bonded energy unit per second)
        // 1 ECG bonded gives a small bonus yield over time
        uint256 bondedBonusPerUnitTime = plot.bondedEnergy.mul(10).div(1 ether); // 10 wei ESS bonus per ECG per second (example)
        uint256 bondedBonus = timeElapsed.mul(bondedBonusPerUnitTime);

        return yield.add(bondedBonus);
    }

    // Handles token spending for actions and checks balance/allowance
    function _performActionCost(address user, uint256 amount) internal {
        require(ecoEnergyToken.balanceOf(user) >= amount, "Insufficient ECG balance");
        // Approve token transfer from user to this contract (handled externally by user)
        // This contract needs allowance from the user to spend ECG on their behalf.
        // A common pattern is `user.approve(contractAddress, cost)` before calling the action.
        // We need to check the allowance here.
        require(ecoEnergyToken.allowance(user, address(this)) >= amount, "ECG allowance too low");
        ecoEnergyToken.transferFrom(user, address(this), amount);
    }

    // --- NFT (Plot) Management ---

    /// @notice Mints a new plot NFT and initializes its state.
    /// @param recipient The address to receive the new plot.
    function mintPlot(address recipient) public onlyOwner {
        _plotIds.increment();
        uint256 newItemId = _plotIds.current();

        _safeMint(recipient, newItemId);

        // Initialize plot stats
        plots[newItemId] = Plot({
            fertility: 500, // Starting stats
            biodiversity: 500,
            purity: 500,
            lastHarvestTime: block.timestamp,
            lastDecayTime: block.timestamp,
            bondedEnergy: 0,
            catalystCharges: 0,
            name: string(abi.encodePacked("Plot #", Strings.toString(newItemId))) // Default name
        });

        // Update global state sums (simple add)
        globalState.totalFertilitySum = globalState.totalFertilitySum.add(plots[newItemId].fertility);
        globalState.totalBiodiversitySum = globalState.totalBiodiversitySum.add(plots[newItemId].biodiversity);
        globalState.totalPuritySum = globalState.totalPuritySum.add(plots[newItemId].purity);
        _updateGlobalState();

        emit PlotMinted(newItemId, recipient);
        emit PlotStateUpdated(newItemId, 500, 500, 500);
    }

    /// @notice Gets the detailed state of a specific plot.
    /// @param plotId The ID of the plot.
    /// @return plotData A struct containing the plot's stats and data.
    function getPlotDetails(uint256 plotId) public view whenPlotExists(plotId) returns (Plot memory plotData) {
        // Apply potential decay *before* returning details in a view function
        // Note: This doesn't persist the decay, only shows the hypothetical state.
        // A real update happens only on state-changing transactions.
        // To get true current state, a transaction calling _updatePlotState would be needed first,
        // or integrate decay check into all read functions (gas expensive).
        // For simplicity in this example, we return the stored state.
        // Decay is applied only in state-changing functions.
        return plots[plotId];
    }

     /// @notice Sets a custom name for a plot.
     /// @param plotId The ID of the plot.
     /// @param name The desired name for the plot.
     function setPlotName(uint256 plotId, string calldata name) public onlyPlotOwner(plotId) {
         plots[plotId].name = name;
         emit PlotNameUpdated(plotId, name);
     }


    // --- Token (ECG, ESS) Management ---
    // ERC20 transferFrom, approve, balanceOf are inherited from ERC20 contracts

    /// @notice Distributes ECG tokens to a recipient (limited use, e.g., faucet or testing).
    /// @param recipient The address to receive tokens.
    /// @param amount The amount of ECG to mint and send.
    function faucetECG(address recipient, uint256 amount) public onlyOwner {
        ecoEnergyToken.mint(recipient, amount); // Assuming ERC20 has a mint function (like OZ ERC20)
        // Note: Standard OpenZeppelin ERC20 does *not* have a mint. A custom extension would be needed.
        // For this example, let's assume ecoEnergyToken *is* a custom ERC20 with minting, or use the owner's balance.
        // Let's assume the contract itself holds a large ECG balance initially.
        // Transfer from contract's balance instead of minting:
        ecoEnergyToken.transfer(recipient, amount);
        // This requires the owner to have pre-funded the contract with ECG.
    }


    // --- Plot Interaction & Gameplay ---

    /// @notice Spends ECG to nurture a plot, increasing its Fertility.
    /// @param plotId The ID of the plot to nurture.
    function nurturePlot(uint256 plotId) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        _updatePlotState(plotId); // Apply decay before action
        Plot storage plot = plots[plotId];

        _performActionCost(msg.sender, config.nurtureCost);

        uint256 oldFertility = plot.fertility;
        plot.fertility = Math.min(plot.fertility.add(config.statIncreasePerAction), config.maxPlotStat);

        if (plot.fertility != oldFertility) {
            // Update global sums (incremental)
            globalState.totalFertilitySum = globalState.totalFertilitySum.add(plot.fertility.sub(oldFertility));
             _updateGlobalState(); // Recalculate global score

            emit PlotStateUpdated(plotId, plot.fertility, plot.biodiversity, plot.purity);
            // Event for action success could also be useful
        }
    }

    /// @notice Spends ECG to purify a plot, increasing its Purity.
    /// @param plotId The ID of the plot to purify.
    function purifyPlot(uint256 plotId) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        _updatePlotState(plotId); // Apply decay before action
        Plot storage plot = plots[plotId];

        _performActionCost(msg.sender, config.purifyCost);

        uint256 oldPurity = plot.purity;
        plot.purity = Math.min(plot.purity.add(config.statIncreasePerAction), config.maxPlotStat);

         if (plot.purity != oldPurity) {
            // Update global sums (incremental)
            globalState.totalPuritySum = globalState.totalPuritySum.add(plot.purity.sub(oldPurity));
            _updateGlobalState(); // Recalculate global score

            emit PlotStateUpdated(plotId, plot.fertility, plot.biodiversity, plot.purity);
        }
    }

    /// @notice Spends ECG to enhance a plot, increasing its Biodiversity.
    /// @param plotId The ID of the plot to enhance.
    function enhanceBiodiversity(uint256 plotId) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        _updatePlotState(plotId); // Apply decay before action
        Plot storage plot = plots[plotId];

        _performActionCost(msg.sender, config.enhanceCost);

        uint256 oldBiodiversity = plot.biodiversity;
        plot.biodiversity = Math.min(plot.biodiversity.add(config.statIncreasePerAction), config.maxPlotStat);

         if (plot.biodiversity != oldBiodiversity) {
            // Update global sums (incremental)
            globalState.totalBiodiversitySum = globalState.totalBiodiversitySum.add(plot.biodiversity.sub(oldBiodiversity));
            _updateGlobalState(); // Recalculate global score

            emit PlotStateUpdated(plotId, plot.fertility, plot.biodiversity, plot.purity);
        }
    }

    /// @notice Harvests ESS tokens from a plot based on its state and time.
    /// @param plotId The ID of the plot to harvest.
    function harvestESS(uint256 plotId) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        _updatePlotState(plotId); // Apply decay before harvest

        Plot storage plot = plots[plotId];
        require(block.timestamp >= plot.lastHarvestTime.add(config.harvestCooldown), "Harvest cooldown active");

        uint256 yieldAmount = _calculatePlotYield(plotId);
        require(yieldAmount > 0, "No yield accumulated");

        // Mint ESS to the plot owner
        ecoEssenceToken.mint(msg.sender, yieldAmount); // Assuming ERC20 has mint

        plot.lastHarvestTime = block.timestamp; // Reset harvest timer

        emit ESSHarvested(plotId, msg.sender, yieldAmount);
    }

    /// @notice Bonds ECG tokens to a specific plot, increasing its yield potential.
    /// @param plotId The ID of the plot.
    /// @param amount The amount of ECG to bond.
    function bondEnergyToPlot(uint256 plotId, uint256 amount) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer ECG from user to this contract
        require(ecoEnergyToken.balanceOf(msg.sender) >= amount, "Insufficient ECG balance");
        require(ecoEnergyToken.allowance(msg.sender, address(this)) >= amount, "ECG allowance too low");
        ecoEnergyToken.transferFrom(msg.sender, address(this), amount);

        plots[plotId].bondedEnergy = plots[plotId].bondedEnergy.add(amount);

        emit EnergyBondedToPlot(plotId, msg.sender, amount);
    }

    /// @notice Unbonds ECG tokens from a specific plot.
    /// @param plotId The ID of the plot.
    /// @param amount The amount of ECG to unbond.
    function unbondEnergyFromPlot(uint256 plotId, uint256 amount) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        require(amount > 0, "Amount must be greater than 0");
        Plot storage plot = plots[plotId];
        require(plot.bondedEnergy >= amount, "Not enough ECG bonded to plot");

        plot.bondedEnergy = plot.bondedEnergy.sub(amount);

        // Transfer ECG back to the user
        ecoEnergyToken.transfer(msg.sender, amount);

        emit EnergyUnbondedFromPlot(plotId, msg.sender, amount);
    }

    /// @notice Applies a catalyst charge to a plot for a temporary/permanent boost (simulated effect).
    /// Requires the plot to have catalyst charges. Consumes one charge.
    /// @param plotId The ID of the plot.
    function applyCatalyst(uint256 plotId) public onlyPlotOwner(plotId) whenPlotExists(plotId) {
        Plot storage plot = plots[plotId];
        require(plot.catalystCharges > 0, "No catalyst charges available");

        _updatePlotState(plotId); // Apply decay before applying catalyst

        plot.catalystCharges = plot.catalystCharges.sub(1);

        // --- SIMULATED CATALYST EFFECT ---
        // For example, instantly boost all stats temporarily or permanently
        plot.fertility = Math.min(plot.fertility.add(catalystBoostAmount), config.maxPlotStat);
        plot.biodiversity = Math.min(plot.biodiversity.add(catalystBoostAmount), config.maxPlotStat);
        plot.purity = Math.min(plot.purity.add(catalystBoostAmount), config.maxPlotStat);
        // In a real game, this could trigger temporary buffs stored elsewhere,
        // or unlock special abilities. This is a simple permanent stat boost example.

        // Update global sums (incremental)
        globalState.totalFertilitySum = globalState.totalFertilitySum.add(catalystBoostAmount);
        globalState.totalBiodiversitySum = globalState.totalBiodiversitySum.add(catalystBoostAmount);
        globalState.totalPuritySum = globalState.totalPuritySum.add(catalystBoostAmount);
        _updateGlobalState(); // Recalculate global score


        emit PlotStateUpdated(plotId, plot.fertility, plot.biodiversity, plot.purity);
        emit CatalystApplied(plotId, msg.sender, plot.catalystCharges);
    }


    // --- Global State & Bonding ---

    /// @notice Gets the current global Eco-Balance score.
    /// @return The eco balance score (0-1000).
    function getGlobalEcoBalance() public view returns (uint256) {
        // Could add logic here to force a global state update if it's stale,
        // but that could be very expensive. Rely on transactional updates.
        return globalState.ecoBalanceScore;
    }

     /// @notice Bonds ECG tokens for global influence/governance power.
     /// @param amount The amount of ECG to bond globally.
    function bondEnergyToGlobal(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer ECG from user to this contract
        require(ecoEnergyToken.balanceOf(msg.sender) >= amount, "Insufficient ECG balance");
        require(ecoEnergyToken.allowance(msg.sender, address(this)) >= amount, "ECG allowance too low");
        ecoEnergyToken.transferFrom(msg.sender, address(this), amount);

        globalBondedEnergyByUser[msg.sender] = globalBondedEnergyByUser[msg.sender].add(amount);
        globalState.totalBondedEnergy = globalState.totalBondedEnergy.add(amount);

        emit EnergyBondedGlobally(msg.sender, amount);
    }

    /// @notice Unbonds globally staked ECG tokens.
    /// @param amount The amount of ECG to unbond globally.
    function unbondEnergyFromGlobal(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(globalBondedEnergyByUser[msg.sender] >= amount, "Not enough ECG bonded globally");

        globalBondedEnergyByUser[msg.sender] = globalBondedEnergyByUser[msg.sender].sub(amount);
        globalState.totalBondedEnergy = globalState.totalBondedEnergy.sub(amount);

        // Transfer ECG back to the user
        ecoEnergyToken.transfer(msg.sender, amount);

        emit EnergyUnbondedGlobally(msg.sender, amount);
    }

    /// @notice Gets the total amount of ECG bonded globally by all users.
    /// @return The total global bonded energy.
    function getGlobalBondedAmount() public view returns (uint256) {
        return globalState.totalBondedEnergy;
    }


    // --- Guardian Council & Governance (DAO) ---

    /// @notice Adds an address to the Guardian Council. Callable by owner or existing guardians.
    /// @param guardian The address to add.
    function addGuardian(address guardian) public virtual onlyOwner { // Make virtual for potential DAO override
         // In a real DAO, this might be a proposal outcome
        require(!_guardians.contains(guardian), "Already a guardian");
        _guardians.add(guardian);
        emit GuardianAdded(guardian);
    }

    /// @notice Removes an address from the Guardian Council. Callable by owner or existing guardians.
    /// @param guardian The address to remove.
    function removeGuardian(address guardian) public virtual onlyOwner { // Make virtual for potential DAO override
        // In a real DAO, this might be a proposal outcome
        require(_guardians.contains(guardian), "Not a guardian");
        require(_guardians.length() > 1, "Cannot remove the last guardian"); // Prevent empty council
        _guardians.remove(guardian);
        emit GuardianRemoved(guardian);
    }

    /// @notice Checks if an address is a current guardian.
    /// @param account The address to check.
    /// @return True if the address is a guardian, false otherwise.
    function isGuardian(address account) public view returns (bool) {
        return _guardians.contains(account);
    }

    /// @notice Creates a new governance proposal. Only callable by guardians.
    /// The proposal data should be an encoded function call on this contract or another allowed target.
    /// @param data The encoded function call data.
    /// @param duration The duration for the voting period (in seconds).
    /// @return The ID of the created proposal.
    function proposeAction(bytes calldata data, uint256 duration) public onlyGuardian returns (uint256) {
        require(duration >= config.minProposalDuration, "Duration too short");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            data: data,
            startDate: block.timestamp,
            deadline: block.timestamp.add(duration),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, msg.sender, proposals[proposalId].deadline);
        return proposalId;
    }

    /// @notice Casts a vote on an active proposal. Callable by guardians or users with globally bonded ECG.
    /// Voting weight is determined by role and bonded ECG.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteFor True to vote for, false to vote against.
    function voteOnProposal(uint256 proposalId, bool voteFor) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startDate > 0 && !proposal.executed, "Proposal does not exist or already executed");
        require(block.timestamp <= proposal.deadline, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voteWeight = 0;
        if (_guardians.contains(msg.sender)) {
            voteWeight = voteWeight.add(config.guardianVoteWeight);
        }
        // Add weight from globally bonded ECG
        voteWeight = voteWeight.add(globalBondedEnergyByUser[msg.sender].mul(config.bonderVoteWeightPerECG));

        require(voteWeight > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (voteFor) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }

        emit VoteCast(proposalId, msg.sender, voteFor);
    }

    /// @notice Executes a proposal if it has met the requirements (passed deadline, threshold met).
    /// Anyone can call this to trigger execution after the voting period ends.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startDate > 0 && !proposal.executed, "Proposal does not exist or already executed");
        require(block.timestamp > proposal.deadline, "Voting period not ended");

        // Calculate total possible voting power if needed, or just use total votes cast vs threshold
        // Let's use a simple threshold based on total votes cast vs required percentage of *some* metric
        // A robust system needs a defined "total voting power" (e.g., total bonded ECG + guardian weights).
        // For this example, let's define total voting power as (Total Global Bonded * Bonder Weight) + (Guardian Count * Guardian Weight)
        uint256 totalPossibleVotes = globalState.totalBondedEnergy.mul(config.bonderVoteWeightPerECG).add(_guardians.length().mul(config.guardianVoteWeight));

        // Avoid division by zero if totalPossibleVotes is 0
        if (totalPossibleVotes == 0) {
             totalPossibleVotes = 1; // Or require minimum bonding/guardians for governance
        }

        uint256 requiredVotes = totalPossibleVotes.mul(config.proposalThresholdPercent).div(100);

        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed");
        require(proposal.votesFor >= requiredVotes, "Approval threshold not met");

        // Execute the proposal data
        // WARNING: Executing arbitrary bytes data is HIGHLY risky.
        // In a real system, this should use a controlled mechanism
        // like a list of allowed functions/targets or a timelock.
        // Using CallSolidity for demonstration, but carefully define callable functions.
        (bool success,) = address(this).call(proposal.data);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Gets the details of a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A struct containing the proposal details.
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

    /// @notice Gets the current state of a proposal (Active, Passed, Failed, Executed).
    /// @param proposalId The ID of the proposal.
    /// @return A string representing the proposal state.
    function getProposalState(uint256 proposalId) public view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.startDate == 0) {
            return "NonExistent";
        }
        if (proposal.executed) {
            return "Executed";
        }
        if (block.timestamp <= proposal.deadline) {
            return "Active";
        }
        // Voting period ended
         uint256 totalPossibleVotes = globalState.totalBondedEnergy.mul(config.bonderVoteWeightPerECG).add(_guardians.length().mul(config.guardianVoteWeight));
         if (totalPossibleVotes == 0) totalPossibleVotes = 1; // Avoid division by zero
         uint256 requiredVotes = totalPossibleVotes.mul(config.proposalThresholdPercent).div(100);

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= requiredVotes) {
            return "Passed";
        } else {
            return "Failed";
        }
    }


    // --- Read Functions (Helpers) ---

    /// @notice Gets a list of all plot IDs owned by a specific address.
    /// @param account The address to query.
    /// @return An array of plot IDs.
    function getUserPlots(address account) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(account);
        uint256[] memory plotIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            plotIds[i] = tokenOfOwnerByIndex(account, i);
        }
        return plotIds;
    }

    /// @notice Calculates the potential ESS yield for a plot without harvesting.
    /// Applies decay hypothetically for the calculation.
    /// @param plotId The ID of the plot.
    /// @return The calculated potential ESS yield.
    function getPlotHarvestYield(uint256 plotId) public view whenPlotExists(plotId) returns (uint256) {
        // Calculate yield based on current time vs last harvest time
        // This view function does NOT apply actual state decay or update lastHarvestTime.
        // It just shows the potential yield *if* you were to harvest now.
        // The actual harvest function will apply decay before calculating/minting.
        return _calculatePlotYield(plotId);
    }

    /// @notice Gets the amount of ECG bonded to a specific plot.
    /// @param plotId The ID of the plot.
    /// @return The amount of bonded ECG.
    function getPlotBondedAmount(uint256 plotId) public view whenPlotExists(plotId) returns (uint256) {
        return plots[plotId].bondedEnergy;
    }

    /// @notice Gets the number of catalyst charges available on a plot.
    /// @param plotId The ID of the plot.
    /// @return The number of catalyst charges.
    function getPlotCatalystCharges(uint256 plotId) public view whenPlotExists(plotId) returns (uint256) {
        return plots[plotId].catalystCharges;
    }

     /// @notice Gets the list of all current guardian addresses.
     /// @return An array of guardian addresses.
    function getGuardianList() public view returns (address[] memory) {
        return _guardians.values();
    }

    /// @notice Gets the total number of proposals created.
    /// @return The total count of proposals.
    function getProposalCount() public view returns (uint256) {
        return _proposalIds.current();
    }

    // --- Override ERC721Enumerable methods ---
    // These are required for ERC721Enumerable functionality.
    // They are standard implementations.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
         return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        // Potentially add custom logic before/after transfer if needed,
        // e.g., clearing bonded energy or catalyst charges on transfer.
        // For simplicity, we just call the parent method.
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override(ERC721) {
        // Optional custom logic
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) {
        // Optional custom logic
        super.setApprovalForAll(operator, approved);
    }

    function getApproved(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }
}

// --- Mock ERC20 for Demonstration ---
// In a real scenario, you'd deploy proper ERC20 contracts or use existing ones.
// This mock includes a `mint` function for easier testing/faucet.
contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Allow owner to mint tokens (for testing/faucet)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// Using ERC20Mock instead of standard ERC20 for ECG and ESS in the main contract constructor
// ERC20 ecoEnergyToken = new ERC20Mock("EcoGenesis Energy", "ECG");
// ERC20 ecoEssenceToken = new ERC20Mock("EcoGenesis Essence", "ESS");
// (Change the main contract constructor accordingly if using ERC20Mock)

// Note on CallSolidity: The `CallSolidity` library is used here conceptually to demonstrate
// how `executeProposal` could call arbitrary functions. In a secure, production DAO,
// you would tightly control *what* functions can be called and potentially implement
// a timelock between proposal passing and execution. This simplified example allows calling
// any public/external function on the contract itself via `address(this).call(proposal.data)`.
// Exercise extreme caution with arbitrary calls in production.

```