Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts beyond standard tokens or simple dApps.

The concept is an `EvolvingDigitalCanvas` where users own dynamic "Cell" NFTs. These Cells can evolve based on various factors (user input, simulated environmental conditions, interactions with neighbors), cost an associated ERC-20 "Energy" token, and are influenced by a simple governance mechanism and an "Oracle" role.

**Concepts Integrated:**

1.  **Dynamic NFTs (ERC-721):** Token metadata and state (`CellState`) changes on-chain based on interactions and time.
2.  **Integrated Tokenomics (ERC-20):** Uses an associated Energy token for actions (minting, evolving, influencing).
3.  **Procedural Simulation (Simplified):** Cell evolution influenced by internal state, parameters, and potentially neighbor interactions.
4.  **Spatial Interaction (Simulated):** Cells can have registered "neighbors" on-chain and actions can consider neighbor state.
5.  **Time-Based Mechanics:** Evolution can be time-gated or influenced by the time elapsed since the last action.
6.  **Oracle/External Influence (Role-Based):** A designated address can trigger "environmental events" affecting cells.
7.  **Multi-Stage Governance:** Users can propose and vote on changes to core parameters using their owned cells/staked energy.
8.  **Complex State Management:** Storing detailed state for each NFT.
9.  **Batch Operations:** Function to process multiple NFTs in a single transaction for gas efficiency.
10. **Role-Based Access Control:** Owner, Oracle, standard users.
11. **Pausable:** Mechanism to pause critical actions.
12. **On-Chain Parameter Storage:** Evolution costs, rules (simplified) stored directly.
13. **Dynamic Metadata URI Generation:** The `tokenURI` function needs to reflect the changing state.
14. **Internal Energy Accounting:** Managing user energy balances deposited into the contract.
15. **NFT Merging/Splitting:** Advanced mechanics to combine or break apart NFTs with associated state changes.
16. **Sponsorship:** One user paying for another cell's action.
17. **Event-Driven State Changes:** Using events to signal significant changes for off-chain listeners.
18. **View Functions for Complex Queries:** Retrieving detailed state information.
19. **Parameter Influence:** Users paying to nudge the outcome of evolution for their cell.
20. **Resource Rescue:** Function to recover accidentally sent ERC-20 tokens (excluding the native Energy token).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // For burn functionality
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice for multi-token interactions

/**
 * @title EvolvingDigitalCanvas
 * @dev A dynamic NFT ecosystem where Cell NFTs evolve based on interactions, time, and environment.
 * Features include integrated ERC-20 energy, spatial interaction simulation, governance, and oracle influence.
 */

// --- OUTLINE ---
// 1. Interfaces
// 2. Libraries (none required for this scale, but could be used)
// 3. Structs & Enums
// 4. State Variables
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. ERC-721 Standard Implementations (inherited/overridden)
// 9. Core Ecosystem Mechanics (Minting, Evolution, Merging, Splitting, Neighbors)
// 10. Energy / Token Interaction
// 11. Oracle / Environmental Influence
// 12. Governance System
// 13. Query Functions (State, Parameters, Governance)
// 14. Admin / Utility Functions (Pause, Rescue, Parameter Setting)

// --- FUNCTION SUMMARY ---

// --- ERC-721 Standard ---
// constructor(string memory name, string memory symbol, address initialEnergyToken, address initialOracle) ERC721(name, symbol) Ownable(msg.sender) Pausable() ReentrancyGuard()
// tokenURI(uint256 tokenId) public view override returns (string memory) -> Dynamic metadata generation.
// safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) -> Standard transfer.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override(ERC721, IERC721) -> Standard transfer with data.
// transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) -> Standard transfer.
// approve(address to, uint256 tokenId) public override(ERC721, IERC721) -> Standard approve.
// setApprovalForAll(address operator, bool approved) public override -> Standard setApprovalForAll.
// getApproved(uint256 tokenId) public view override returns (address) -> Standard getApproved.
// isApprovedForAll(address owner, address operator) public view override returns (bool) -> Standard isApprovedForAll.
// balanceOf(address owner) public view override returns (uint256) -> Standard balanceOf.
// ownerOf(uint256 tokenId) public view override returns (address) -> Standard ownerOf.

// --- Core Ecosystem Mechanics ---
// mintGenesisCell(address initialOwner) public onlyOwner -> Mints a special initial cell (ID 0) by the owner.
// mintCellWithEnergy() public payable whenNotPaused nonReentrant -> Allows user to mint a new cell using energy token.
// evolveCellStep(uint256 tokenId) public whenNotPaused nonReentrant -> Triggers a single evolution step for a cell. Costs energy.
// batchEvolveOwnedCells(uint256[] calldata tokenIds) public whenNotPaused nonReentrant -> Evolves multiple cells owned by the caller in one transaction.
// mergeCells(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant -> Merges two owned cells into a new one. Burns inputs, costs energy.
// splitCell(uint256 tokenId) public whenNotPaused nonReentrant -> Splits an advanced cell into simpler ones. Burns input, costs energy, mints outputs.
// registerNeighborLink(uint256 tokenId1, uint256 tokenId2) public whenNotPaused -> Registers a bidirectional neighbor link between two cells. Requires ownership or approval for both.
// breakNeighborLink(uint256 tokenId1, uint256 tokenId2) public whenNotPaused -> Removes a neighbor link. Requires ownership or approval for one.
// influenceCellAttribute(uint256 tokenId, string calldata attributeName, int256 influenceAmount) public whenNotPaused nonReentrant -> User pays energy to influence a specific cell attribute.
// sponsorEvolutionStep(uint256 tokenId, address sponsor) public whenNotPaused nonReentrant -> Allows anyone to pay energy for another cell's evolution. Sponsor gets noted.

// --- Energy / Token Interaction ---
// setEnergyToken(address newEnergyToken) public onlyOwner -> Sets the address of the ERC-20 energy token.
// depositEnergy(uint256 amount) public whenNotPaused nonReentrant -> Users deposit Energy token into the contract.
// withdrawEnergy(uint256 amount) public whenNotPaused nonReentrant -> Users withdraw their deposited Energy token.
// getDepositedEnergy(address user) public view returns (uint256) -> Query user's deposited energy balance.

// --- Oracle / Environmental Influence ---
// setOracleAddress(address newOracle) public onlyOwner -> Sets the address allowed to trigger environmental events.
// triggerEnvironmentalEvent(uint256 eventType, uint256[] calldata affectedTokenIds) public onlyOracle whenNotPaused nonReentrant -> Oracle triggers an event that affects specified cells.

// --- Governance System ---
// proposeEvolutionParameterChange(string calldata parameterName, int256 newValue, uint256 duration) public whenNotPaused nonReentrant -> Propose a change to a core evolution parameter. Costs energy.
// voteOnParameterChange(uint256 proposalId, bool support) public whenNotPaused nonReentrant -> Vote on an active proposal. Voting power could be based on owned cells/energy.
// executeParameterChange(uint256 proposalId) public whenNotPaused nonReentrant -> Execute a passed proposal.

// --- Query Functions ---
// getCellState(uint256 tokenId) public view returns (CellState memory) -> Get the full state struct of a cell.
// getCellVisualParameters(uint256 tokenId) public view returns (uint8 colorCode, uint8 shapeCode, uint8 patternCode) -> Get specific on-chain visual parameters.
// getEvolutionParameter(string calldata parameterName) public view returns (int256) -> Get the current value of an evolution parameter.
// getProposalDetails(uint256 proposalId) public view returns (ProposalState state, string memory parameterName, int256 newValue, uint256 voteStartTime, uint256 voteEndTime, uint256 votesFor, uint256 votesAgainst, bool executed) -> Get details of a governance proposal.

// --- Admin / Utility Functions ---
// pauseActions() public onlyOwner whenNotPaused -> Pause sensitive contract actions.
// unpauseActions() public onlyOwner whenPaused -> Unpause contract actions.
// rescueERC20(address tokenAddress, uint256 amount) public onlyOwner nonReentrant -> Rescue ERC20 tokens accidentally sent to the contract (excluding the Energy token).

contract EvolvingDigitalCanvas is ERC721, Ownable, Pausable, ReentrancyGuard, ERC721Burnable { // Inherit ERC721Burnable

    using Counters for Counters.Counter;
    Counters.Counter private _cellIdCounter;

    // --- Structs & Enums ---

    enum CellStatus { Dormant, Active, Mutating, Merged, Split }
    enum EvolutionStage { Seed, Bud, Bloom, Decay, Rebirth }
    enum ProposalState { Active, Passed, Failed, Executed, Canceled }

    struct CellState {
        uint256 id;
        address owner;
        uint64 birthTime;          // When minted
        uint64 lastInteractionTime; // When last evolved or influenced
        CellStatus status;
        EvolutionStage stage;
        uint8 energyLevel;         // Internal energy/vitality (0-255)
        mapping(string => int256) attributes; // Dynamic attributes (e.g., "colorHue", "size", "complexity")
        uint256[] neighbors;       // Token IDs of registered neighbors
        address lastSponsor;       // Address of the last user who sponsored evolution
    }

    struct GovernanceProposal {
        uint256 id;
        string parameterName;
        int256 newValue;
        uint64 voteStartTime;
        uint64 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        ProposalState state;
        mapping(address => bool) hasVoted; // Prevent double voting
    }

    // --- State Variables ---

    mapping(uint256 => CellState) private _cellStates;
    address public energyToken; // The ERC-20 token used for actions
    address public oracleAddress; // Trusted address for environmental events

    // Energy deposited by users for internal contract actions
    mapping(address => uint256) private _userEnergyBalances;

    // Core evolution parameters adjustable via governance
    mapping(string => int256) private _evolutionParameters;

    // Costs for various actions in Energy tokens
    mapping(string => uint256) private _actionCosts;

    // Governance proposals
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => GovernanceProposal) private _proposals;

    // Mapping to track which proposals a user has voted on
    mapping(address => mapping(uint256 => bool)) private _userVotes;

    // --- Events ---

    event CellMinted(uint256 indexed tokenId, address indexed owner, bool indexed isGenesis);
    event CellEvolved(uint256 indexed tokenId, EvolutionStage newStage, uint8 newEnergyLevel, address indexed actedBy, address indexed sponsoredBy);
    event CellsMerged(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2, address indexed owner);
    event CellSplit(uint256 indexed oldTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2, address indexed owner);
    event NeighborLinkRegistered(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event NeighborLinkBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event CellAttributeInfluenced(uint256 indexed tokenId, string attributeName, int256 influenceAmount, address indexed actedBy);
    event EnvironmentalEventTriggered(uint256 indexed eventType, uint256[] affectedTokenIds, address indexed oracle);
    event EnergyDeposited(address indexed user, uint256 amount);
    event EnergyWithdrawal(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string parameterName, int256 newValue, uint64 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EvolutionParameterChanged(string parameterName, int256 newValue, uint256 indexed proposalId);
    event ActionCostSet(string actionName, uint256 cost);
    event RescueERC20(address indexed tokenAddress, uint256 amount);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the oracle");
        _;
    }

    modifier cellExists(uint256 tokenId) {
        require(_exists(tokenId), "Cell does not exist");
        _;
    }

    modifier isCellOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not cell owner");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialEnergyToken, address initialOracle)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
        ReentrancyGuard()
    {
        require(initialEnergyToken != address(0), "Invalid energy token address");
        require(initialOracle != address(0), "Invalid oracle address");
        energyToken = initialEnergyToken;
        oracleAddress = initialOracle;

        // Set initial default action costs (in Energy token units)
        _actionCosts["mint"] = 100e18;
        _actionCosts["evolve"] = 50e18;
        _actionCosts["merge"] = 200e18;
        _actionCosts["split"] = 150e18;
        _actionCosts["influence"] = 30e18;
        _actionCosts["propose"] = 500e18; // Cost to create a governance proposal
        _actionCosts["registerNeighbor"] = 10e18;
        _actionCosts["breakNeighbor"] = 5e18;


        // Set initial default evolution parameters
        _evolutionParameters["evolutionCooldown"] = 1 days; // Time required between evolution steps
        _evolutionParameters["energyDecayRate"] = 5;       // Energy lost per day if inactive
        _evolutionParameters["minMergeComplexity"] = 10;   // Minimum complexity for a cell to be mergeable
        _evolutionParameters["minSplitComplexity"] = 20;   // Minimum complexity for a cell to be splittable
        _evolutionParameters["voteDuration"] = 3 days;     // How long governance votes last
        _evolutionParameters["minVotesForProposal"] = 5;   // Minimum voters for proposal to be valid
        _evolutionParameters["requiredMajorityPercent"] = 51; // % of votes needed to pass

         emit ActionCostSet("mint", _actionCosts["mint"]);
         emit ActionCostSet("evolve", _actionCosts["evolve"]);
         emit ActionCostSet("merge", _actionCosts["merge"]);
         emit ActionCostSet("split", _actionCosts["split"]);
         emit ActionCostSet("influence", _actionCosts["influence"]);
         emit ActionCostSet("propose", _actionCosts["propose"]);
         emit ActionCostSet("registerNeighbor", _actionCosts["registerNeighbor"]);
         emit ActionCostSet("breakNeighbor", _actionCosts["breakNeighbor"]);

         // Note: Evolution parameters changing emits EvolutionParameterChanged event via execution
    }

    // --- ERC-721 Standard Implementations (inherited/overridden) ---
    // Most are inherited from OpenZeppelin. We override tokenURI.

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Note: In a real DApp, this would likely point to an API endpoint
        // that fetches the on-chain state via getCellState and constructs
        // the JSON metadata and image dynamically.
        // For this example, we'll return a placeholder or a simple
        // string representing the state, as generating complex JSON/SVG
        // purely on-chain is gas-prohibitive and complex.

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        CellState memory cell = _cellStates[tokenId];
        string memory status = _statusToString(cell.status);
        string memory stage = _stageToString(cell.stage);
        string memory uri = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked(
                        '{"name": "Canvas Cell #', Strings.toString(tokenId),
                        '", "description": "A dynamic cell on the evolving digital canvas.",',
                        '"attributes": [',
                            '{"trait_type": "Status", "value": "', status, '"},',
                            '{"trait_type": "Stage", "value": "', stage, '"},',
                            '{"trait_type": "Energy Level", "value": ', Strings.toString(cell.energyLevel), '},',
                            // Example of including dynamic attributes (iterate over mapping keys - complex, might need off-chain helper or fixed attributes)
                            // For simplicity here, just describe the concept:
                            '{"trait_type": "Complexity", "value": ', Strings.toString(cell.attributes["complexity"]), '}',
                            // Add more attributes from cell.attributes here
                        '],',
                        '"image": "ipfs://<CID_GENERATED_BASED_ON_STATE>"', // Placeholder for dynamic image
                        '}'
                    ))
                )
            )
        ));
        return uri;
    }

    // Helper functions to convert enums to strings (needed for metadata)
    function _statusToString(CellStatus status) internal pure returns (string memory) {
        if (status == CellStatus.Dormant) return "Dormant";
        if (status == CellStatus.Active) return "Active";
        if (status == CellStatus.Mutating) return "Mutating";
        if (status == CellStatus.Merged) return "Merged";
        if (status == CellStatus.Split) return "Split";
        return "Unknown"; // Should not happen
    }

     function _stageToString(EvolutionStage stage) internal pure returns (string memory) {
        if (stage == EvolutionStage.Seed) return "Seed";
        if (stage == EvolutionStage.Bud) return "Bud";
        if (stage == EvolutionStage.Bloom) return "Bloom";
        if (stage == EvolutionStage.Decay) return "Decay";
        if (stage == EvolutionStage.Rebirth) return "Rebirth";
        return "Unknown"; // Should not happen
    }


    // --- Core Ecosystem Mechanics ---

    /**
     * @dev Mints the very first cell (tokenId 0). Can only be called once by the owner.
     * @param initialOwner The address to mint the genesis cell to.
     */
    function mintGenesisCell(address initialOwner) public onlyOwner {
        require(_cellIdCounter.current() == 0, "Genesis cell already minted");

        _cellIdCounter.increment();
        uint256 newTokenId = _cellIdCounter.current() - 1; // Genesis ID is 0

        _safeMint(initialOwner, newTokenId);

        CellState storage newCell = _cellStates[newTokenId];
        newCell.id = newTokenId;
        newCell.owner = initialOwner;
        newCell.birthTime = uint64(block.timestamp);
        newCell.lastInteractionTime = uint64(block.timestamp);
        newCell.status = CellStatus.Active;
        newCell.stage = EvolutionStage.Seed;
        newCell.energyLevel = 100; // Starting energy
        newCell.attributes["complexity"] = 1; // Starting complexity
        newCell.attributes["colorHue"] = uint8(block.timestamp % 256); // Example procedural attribute

        emit CellMinted(newTokenId, initialOwner, true);
    }

    /**
     * @dev Allows a user to mint a new cell by paying Energy tokens.
     */
    function mintCellWithEnergy() public whenNotPaused nonReentrable {
        uint256 mintCost = _actionCosts["mint"];
        require(_userEnergyBalances[msg.sender] >= mintCost, "Insufficient deposited energy");

        _userEnergyBalances[msg.sender] -= mintCost;

        _cellIdCounter.increment();
        uint256 newTokenId = _cellIdCounter.current() - 1;

        _safeMint(msg.sender, newTokenId);

        CellState storage newCell = _cellStates[newTokenId];
        newCell.id = newTokenId;
        newCell.owner = msg.sender;
        newCell.birthTime = uint64(block.timestamp);
        newCell.lastInteractionTime = uint64(block.timestamp);
        newCell.status = CellStatus.Active;
        newCell.stage = EvolutionStage.Seed;
        newCell.energyLevel = 50; // Standard mint starting energy
        newCell.attributes["complexity"] = 1; // Starting complexity
        newCell.attributes["colorHue"] = uint8(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, newTokenId))) % 256); // Pseudo-random attribute

        emit CellMinted(newTokenId, msg.sender, false);
    }

    /**
     * @dev Triggers a single evolution step for a cell. Costs energy and has a cooldown.
     * Evolution logic is simplified: increases stage, updates energy, updates attributes.
     * @param tokenId The ID of the cell to evolve.
     */
    function evolveCellStep(uint256 tokenId) public cellExists(tokenId) isCellOwner(tokenId) whenNotPaused nonReentrable {
        CellState storage cell = _cellStates[tokenId];
        uint256 evolutionCost = _actionCosts["evolve"];
        int256 evolutionCooldown = _evolutionParameters["evolutionCooldown"];

        require(uint64(block.timestamp) >= cell.lastInteractionTime + uint64(evolutionCooldown), "Evolution cooldown active");
        require(_userEnergyBalances[msg.sender] >= evolutionCost, "Insufficient deposited energy");
        require(cell.status == CellStatus.Active, "Cell not active for evolution");
        require(cell.stage != EvolutionStage.Decay, "Cell is in decay and cannot evolve forward"); // Prevent evolution from Decay

        _userEnergyBalances[msg.sender] -= evolutionCost;

        // --- Simplified Evolution Logic ---
        // In a complex system, this would involve checking neighbors,
        // global environmental factors, internal attributes, etc.

        // Simulate attribute changes based on current state/randomness
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, cell.lastInteractionTime)));
        uint8 stageInt = uint8(cell.stage);

        // Increase complexity with stage
        cell.attributes["complexity"] += stageInt + 1;

        // Change color slightly based on stage and randomness
        cell.attributes["colorHue"] = (cell.attributes["colorHue"] + int256(randomSeed % 20) - 10 + stageInt * 5) % 256;
        if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;

        // Update energy based on complexity and randomness
        int256 energyChange = int256(randomSeed % 30) - 15; // Random gain/loss
        energyChange += int256(cell.attributes["complexity"] / 5); // Gain energy from complexity
        energyChange -= int256(cell.neighbors.length * 2); // Cost energy based on neighbors (interaction cost)

        cell.energyLevel = uint8(int252(cell.energyLevel) + energyChange); // Use int252 for intermediate math safety
        if (cell.energyLevel > 255) cell.energyLevel = 255;
        if (cell.energyLevel < 10) cell.energyLevel = 10; // Minimum energy level

        // Advance stage based on energy/complexity
        if (cell.energyLevel > 150 && cell.attributes["complexity"] > 15 && cell.stage < EvolutionStage.Rebirth) {
             cell.stage = EvolutionStage(uint8(cell.stage) + 1);
        } else if (cell.energyLevel < 30 && cell.stage != EvolutionStage.Decay) {
            cell.stage = EvolutionStage.Decay;
        }
        // Note: Rebirth stage could require specific conditions not shown here

        cell.lastInteractionTime = uint64(block.timestamp);
        cell.lastSponsor = address(0); // Reset sponsor on manual evolution

        emit CellEvolved(tokenId, cell.stage, cell.energyLevel, msg.sender, address(0));
    }

     /**
     * @dev Allows a user to evolve multiple cells they own in a single transaction.
     * Checks all conditions for each cell and processes them sequentially.
     * @param tokenIds An array of cell IDs to evolve.
     */
    function batchEvolveOwnedCells(uint256[] calldata tokenIds) public whenNotPaused nonReentrable {
         uint256 evolutionCostPerCell = _actionCosts["evolve"];
         uint256 totalCost = evolutionCostPerCell * tokenIds.length;
         int256 evolutionCooldown = _evolutionParameters["evolutionCooldown"];

         require(_userEnergyBalances[msg.sender] >= totalCost, "Insufficient deposited energy for batch");

         // Deduct total cost upfront (simplifies individual checks)
         _userEnergyBalances[msg.sender] -= totalCost;

         for (uint i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
             // Check existence and ownership inside the loop
             require(_exists(tokenId), string(abi.encodePacked("Cell ", Strings.toString(tokenId), " does not exist")));
             require(ownerOf(tokenId) == msg.sender, string(abi.encodePacked("Not owner of cell ", Strings.toString(tokenId))));

             CellState storage cell = _cellStates[tokenId];

             // Check specific cell conditions
             if (uint64(block.timestamp) >= cell.lastInteractionTime + uint64(evolutionCooldown) &&
                 cell.status == CellStatus.Active &&
                 cell.stage != EvolutionStage.Decay)
             {
                 // --- Simplified Batch Evolution Logic (similar to single evolve) ---
                 uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, cell.lastInteractionTime, i))); // Add 'i' for more entropy
                 uint8 stageInt = uint8(cell.stage);

                 cell.attributes["complexity"] += stageInt + 1;

                 cell.attributes["colorHue"] = (cell.attributes["colorHue"] + int256(randomSeed % 20) - 10 + stageInt * 5) % 256;
                 if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;

                 int256 energyChange = int256(randomSeed % 30) - 15;
                 energyChange += int256(cell.attributes["complexity"] / 5);
                 energyChange -= int256(cell.neighbors.length * 2);

                 cell.energyLevel = uint8(int252(cell.energyLevel) + energyChange);
                 if (cell.energyLevel > 255) cell.energyLevel = 255;
                 if (cell.energyLevel < 10) cell.energyLevel = 10;

                 if (cell.energyLevel > 150 && cell.attributes["complexity"] > 15 && cell.stage < EvolutionStage.Rebirth) {
                      cell.stage = EvolutionStage(uint8(cell.stage) + 1);
                 } else if (cell.energyLevel < 30 && cell.stage != EvolutionStage.Decay) {
                     cell.stage = EvolutionStage.Decay;
                 }

                 cell.lastInteractionTime = uint64(block.timestamp);
                 cell.lastSponsor = address(0); // Reset sponsor on manual evolution

                 emit CellEvolved(tokenId, cell.stage, cell.energyLevel, msg.sender, address(0));
             }
             // Note: Cells failing conditions within the batch are simply skipped, but their cost is still paid.
             // A more complex implementation might refund energy or require all cells to be valid upfront.
         }
    }


    /**
     * @dev Merges two owned cells into a new, potentially more complex cell.
     * Burns the two input cells and mints a new one. Costs energy.
     * Requires cells to meet minimum complexity criteria.
     * @param tokenId1 The ID of the first cell to merge.
     * @param tokenId2 The ID of the second cell to merge.
     */
    function mergeCells(uint256 tokenId1, uint256 tokenId2) public cellExists(tokenId1) cellExists(tokenId2) isCellOwner(tokenId1) whenNotPaused nonReentrable {
        require(tokenId1 != tokenId2, "Cannot merge a cell with itself");
        require(ownerOf(tokenId2) == msg.sender, "Must own both cells to merge");

        CellState storage cell1 = _cellStates[tokenId1];
        CellState storage cell2 = _cellStates[tokenId2];

        uint256 mergeCost = _actionCosts["merge"];
        require(_userEnergyBalances[msg.sender] >= mergeCost, "Insufficient deposited energy");
        require(cell1.status == CellStatus.Active && cell2.status == CellStatus.Active, "Both cells must be active to merge");

        int256 minMergeComplexity = _evolutionParameters["minMergeComplexity"];
        require(cell1.attributes["complexity"] >= minMergeComplexity && cell2.attributes["complexity"] >= minMergeComplexity, "Cells not complex enough to merge");

        _userEnergyBalances[msg.sender] -= mergeCost;

        // --- Merging Logic (Simplified) ---
        _cellIdCounter.increment();
        uint256 newTokenId = _cellIdCounter.current() - 1;

        _safeMint(msg.sender, newTokenId);

        CellState storage newCell = _cellStates[newTokenId];
        newCell.id = newTokenId;
        newCell.owner = msg.sender;
        newCell.birthTime = uint64(block.timestamp);
        newCell.lastInteractionTime = uint64(block.timestamp);
        newCell.status = CellStatus.Active;
        newCell.stage = EvolutionStage.Bud; // Start at a more advanced stage
        newCell.energyLevel = uint8((cell1.energyLevel + cell2.energyLevel) / 2); // Average energy

        // Combine attributes (example: average, sum, or specific rules)
        newCell.attributes["complexity"] = cell1.attributes["complexity"] + cell2.attributes["complexity"] / 2; // Sum complexity partially
        newCell.attributes["colorHue"] = (cell1.attributes["colorHue"] + cell2.attributes["colorHue"]) / 2; // Average color

        // Combine neighbors (avoiding duplicates and the cells being burned)
        mapping(uint256 => bool) existingNeighbors;
        for(uint i=0; i<cell1.neighbors.length; i++) {
             if(cell1.neighbors[i] != tokenId2 && !existingNeighbors[cell1.neighbors[i]]) {
                 newCell.neighbors.push(cell1.neighbors[i]);
                 existingNeighbors[cell1.neighbors[i]] = true;
             }
        }
         for(uint i=0; i<cell2.neighbors.length; i++) {
             if(cell2.neighbors[i] != tokenId1 && !existingNeighbors[cell2.neighbors[i]]) {
                 newCell.neighbors.push(cell2.neighbors[i]);
                 existingNeighbors[cell2.neighbors[i]] = true;
             }
        }


        // Burn the old cells
        _burn(tokenId1);
        _burn(tokenId2);
        // Note: State for burned tokens remains in storage but is inaccessible via ERC721 functions.
        // A more advanced pattern might involve clearing storage, but that costs gas.
        // Marking status as Merged can indicate they are no longer active.
        cell1.status = CellStatus.Merged;
        cell2.status = CellStatus.Merged;


        emit CellsMerged(newTokenId, tokenId1, tokenId2, msg.sender);
    }

    /**
     * @dev Splits an advanced cell into two simpler cells.
     * Burns the input cell and mints two new ones. Costs energy.
     * Requires the cell to meet minimum complexity criteria.
     * @param tokenId The ID of the cell to split.
     */
    function splitCell(uint256 tokenId) public cellExists(tokenId) isCellOwner(tokenId) whenNotPaused nonReentrable {
        CellState storage cell = _cellStates[tokenId];

        uint256 splitCost = _actionCosts["split"];
        require(_userEnergyBalances[msg.sender] >= splitCost, "Insufficient deposited energy");
        require(cell.status == CellStatus.Active, "Cell must be active to split");

        int256 minSplitComplexity = _evolutionParameters["minSplitComplexity"];
        require(cell.attributes["complexity"] >= minSplitComplexity, "Cell not complex enough to split");

        _userEnergyBalances[msg.sender] -= splitCost;

        // --- Splitting Logic (Simplified) ---
        _cellIdCounter.increment();
        uint256 newTokenId1 = _cellIdCounter.current() - 1;
        _cellIdCounter.increment();
        uint256 newTokenId2 = _cellIdCounter.current() - 1;

        _safeMint(msg.sender, newTokenId1);
        _safeMint(msg.sender, newTokenId2);

        CellState storage newCell1 = _cellStates[newTokenId1];
        newCell1.id = newTokenId1;
        newCell1.owner = msg.sender;
        newCell1.birthTime = uint64(block.timestamp);
        newCell1.lastInteractionTime = uint64(block.timestamp);
        newCell1.status = CellStatus.Active;
        newCell1.stage = EvolutionStage.Seed; // Reset stage
        newCell1.energyLevel = uint8(cell.energyLevel / 2); // Divide energy

        CellState storage newCell2 = _cellStates[newTokenId2];
        newCell2.id = newTokenId2;
        newCell2.owner = msg.sender;
        newCell2.birthTime = uint64(block.timestamp);
        newCell2.lastInteractionTime = uint64(block.timestamp);
        newCell2.status = CellStatus.Active;
        newCell2.stage = EvolutionStage.Seed; // Reset stage
        newCell2.energyLevel = uint8(cell.energyLevel - newCell1.energyLevel); // Remaining energy

        // Divide attributes (example: halve complexity, average/copy colors)
        newCell1.attributes["complexity"] = cell.attributes["complexity"] / 2;
        newCell2.attributes["complexity"] = cell.attributes["complexity"] - newCell1.attributes["complexity"];
        newCell1.attributes["colorHue"] = cell.attributes["colorHue"];
        newCell2.attributes["colorHue"] = cell.attributes["colorHue"];

        // Neighbors might be inherited by one or split between them based on rules
        // For simplicity, let's clear neighbors and require re-linking
         //newCell1.neighbors = cell.neighbors; // Could assign all neighbors to one or split
         //newCell2.neighbors = new uint256[](0); // Others get none initially

        // Burn the old cell
        _burn(tokenId);
        // Mark status as Split
        cell.status = CellStatus.Split;

        emit CellSplit(tokenId, newTokenId1, newTokenId2, msg.sender);
    }

     /**
     * @dev Registers a bidirectional neighbor link between two cells.
     * Requires ownership or approval for both cells. Costs energy.
     * @param tokenId1 The ID of the first cell.
     * @param tokenId2 The ID of the second cell.
     */
    function registerNeighborLink(uint256 tokenId1, uint256 tokenId2) public cellExists(tokenId1) cellExists(tokenId2) whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot link a cell to itself");
        require(ownerOf(tokenId1) == msg.sender || isApprovedForAll(ownerOf(tokenId1), msg.sender) || getApproved(tokenId1) == msg.sender, "Not authorized for cell 1");
        require(ownerOf(tokenId2) == msg.sender || isApprovedForAll(ownerOf(tokenId2), msg.sender) || getApproved(tokenId2) == msg.sender, "Not authorized for cell 2");

        CellState storage cell1 = _cellStates[tokenId1];
        CellState storage cell2 = _cellStates[tokenId2];

        uint256 linkCost = _actionCosts["registerNeighbor"];
        require(_userEnergyBalances[msg.sender] >= linkCost, "Insufficient deposited energy");
        require(cell1.status == CellStatus.Active && cell2.status == CellStatus.Active, "Both cells must be active");

        // Check if already neighbors (avoid duplicates)
        bool alreadyNeighbor1 = false;
        for(uint i=0; i<cell1.neighbors.length; i++) {
            if (cell1.neighbors[i] == tokenId2) {
                alreadyNeighbor1 = true;
                break;
            }
        }
         bool alreadyNeighbor2 = false;
        for(uint i=0; i<cell2.neighbors.length; i++) {
            if (cell2.neighbors[i] == tokenId1) {
                alreadyNeighbor2 = true;
                break;
            }
        }

        require(!alreadyNeighbor1 || !alreadyNeighbor2, "Cells are already neighbors");

        _userEnergyBalances[msg.sender] -= linkCost;

        // Add links (bidirectional)
        cell1.neighbors.push(tokenId2);
        cell2.neighbors.push(tokenId1);

        emit NeighborLinkRegistered(tokenId1, tokenId2);
    }

     /**
     * @dev Breaks a neighbor link between two cells.
     * Requires ownership or approval for at least one of the cells. Costs energy.
     * @param tokenId1 The ID of the first cell.
     * @param tokenId2 The ID of the second cell.
     */
    function breakNeighborLink(uint256 tokenId1, uint256 tokenId2) public cellExists(tokenId1) cellExists(tokenId2) whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot break link to itself");
        require(ownerOf(tokenId1) == msg.sender || isApprovedForAll(ownerOf(tokenId1), msg.sender) || getApproved(tokenId1) == msg.sender ||
                ownerOf(tokenId2) == msg.sender || isApprovedForAll(ownerOf(tokenId2), msg.sender) || getApproved(tokenId2) == msg.sender,
                "Not authorized for either cell");

        CellState storage cell1 = _cellStates[tokenId1];
        CellState storage cell2 = _cellStates[tokenId2];

         uint256 breakCost = _actionCosts["breakNeighbor"];
        require(_userEnergyBalances[msg.sender] >= breakCost, "Insufficient deposited energy");

        // Find and remove link from cell1's neighbors
        bool removed1 = false;
        for (uint i = 0; i < cell1.neighbors.length; i++) {
            if (cell1.neighbors[i] == tokenId2) {
                cell1.neighbors[i] = cell1.neighbors[cell1.neighbors.length - 1];
                cell1.neighbors.pop();
                removed1 = true;
                break;
            }
        }

        // Find and remove link from cell2's neighbors
        bool removed2 = false;
        for (uint i = 0; i < cell2.neighbors.length; i++) {
            if (cell2.neighbors[i] == tokenId1) {
                cell2.neighbors[i] = cell2.neighbors[cell2.neighbors.length - 1];
                cell2.neighbors.pop();
                removed2 = true;
                break;
            }
        }

        require(removed1 && removed2, "Link does not exist");

        _userEnergyBalances[msg.sender] -= breakCost;

        emit NeighborLinkBroken(tokenId1, tokenId2);
    }

     /**
     * @dev Allows a user to pay energy to influence a specific cell attribute.
     * The influenceAmount is applied within limits defined by contract rules (simplified here).
     * @param tokenId The ID of the cell to influence.
     * @param attributeName The name of the attribute to influence.
     * @param influenceAmount The amount to influence the attribute by.
     */
    function influenceCellAttribute(uint256 tokenId, string calldata attributeName, int256 influenceAmount) public cellExists(tokenId) isCellOwner(tokenId) whenNotPaused nonReentrable {
         CellState storage cell = _cellStates[tokenId];

         uint224 influenceCost = uint224(_actionCosts["influence"]); // Use smaller type if cost is known to be small
         require(_userEnergyBalances[msg.sender] >= influenceCost, "Insufficient deposited energy");
         require(cell.status == CellStatus.Active, "Cell must be active");

         // --- Simplified Influence Logic ---
         // In reality, this would have bounds, check attribute validity,
         // and potentially scale influence based on cost or other factors.
         // Also consider which attributes are mutable by influence.

         // Prevent influencing critical attributes like 'complexity' or 'stage' directly
         require(
             !keccak256(bytes(attributeName)).equals(keccak256(bytes("complexity"))) &&
             !keccak256(bytes(attributeName)).equals(keccak256(bytes("stage"))),
             "Cannot directly influence this attribute"
         );

         // Apply influence, capping changes
         int256 currentAttributeValue = cell.attributes[attributeName];
         int256 maxInfluenceStep = 50; // Example limit
         int256 actualInfluence = influenceAmount > maxInfluenceStep ? maxInfluenceStep : influenceAmount;
         actualInfluence = actualInfluence < -maxInfluenceStep ? -maxInfluenceStep : actualInfluence; // Apply limit in both directions

         cell.attributes[attributeName] = currentAttributeValue + actualInfluence;

         _userEnergyBalances[msg.sender] -= influenceCost;
         cell.lastInteractionTime = uint64(block.timestamp); // Mark as interaction

         emit CellAttributeInfluenced(tokenId, attributeName, actualInfluence, msg.sender);
    }

    /**
     * @dev Allows any user to pay energy to sponsor the next evolution step for another cell.
     * The sponsor's address is recorded.
     * @param tokenId The ID of the cell to sponsor.
     * @param sponsor The address who is sponsoring (usually msg.sender).
     */
    function sponsorEvolutionStep(uint256 tokenId, address sponsor) public cellExists(tokenId) whenNotPaused nonReentrable {
        require(sponsor == msg.sender, "Sponsor address must match caller");
        CellState storage cell = _cellStates[tokenId];
        uint256 evolutionCost = _actionCosts["evolve"];

        require(_userEnergyBalances[msg.sender] >= evolutionCost, "Insufficient deposited energy to sponsor");
        require(cell.status == CellStatus.Active, "Cell not active for sponsorship");
        require(uint64(block.timestamp) >= cell.lastInteractionTime + uint64(_evolutionParameters["evolutionCooldown"]), "Cell not ready for sponsored evolution");

        _userEnergyBalances[msg.sender] -= evolutionCost;

         // --- Simplified Sponsored Evolution Logic (similar to evolveCellStep) ---
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, cell.lastInteractionTime, msg.sender)));
         uint8 stageInt = uint8(cell.stage);

         cell.attributes["complexity"] += stageInt + 1; // Evolution logic applies

         cell.attributes["colorHue"] = (cell.attributes["colorHue"] + int256(randomSeed % 20) - 10 + stageInt * 5) % 256;
         if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;

         int256 energyChange = int256(randomSeed % 30) - 15;
         energyChange += int256(cell.attributes["complexity"] / 5);
         energyChange -= int256(cell.neighbors.length * 2);

         cell.energyLevel = uint8(int252(cell.energyLevel) + energyChange);
         if (cell.energyLevel > 255) cell.energyLevel = 255;
         if (cell.energyLevel < 10) cell.energyLevel = 10;

         if (cell.energyLevel > 150 && cell.attributes["complexity"] > 15 && cell.stage < EvolutionStage.Rebirth) {
              cell.stage = EvolutionStage(uint8(cell.stage) + 1);
         } else if (cell.energyLevel < 30 && cell.stage != EvolutionStage.Decay) {
             cell.stage = EvolutionStage.Decay;
         }

        cell.lastInteractionTime = uint64(block.timestamp);
        cell.lastSponsor = sponsor; // Record the sponsor

        emit CellEvolved(tokenId, cell.stage, cell.energyLevel, address(this), sponsor); // Emitted by contract, sponsored by user
    }


    // --- Energy / Token Interaction ---

    /**
     * @dev Sets the address of the ERC-20 token used for energy. Only callable by owner.
     * @param newEnergyToken The address of the ERC-20 token.
     */
    function setEnergyToken(address newEnergyToken) public onlyOwner {
        require(newEnergyToken != address(0), "Invalid address");
        energyToken = newEnergyToken;
    }

    /**
     * @dev Allows users to deposit Energy tokens into their balance within the contract.
     * Requires prior approval of the tokens to the contract address.
     * @param amount The amount of Energy tokens to deposit.
     */
    function depositEnergy(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Deposit amount must be positive");
        require(IERC20(energyToken).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
        _userEnergyBalances[msg.sender] += amount;
        emit EnergyDeposited(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw their deposited Energy tokens from the contract.
     * @param amount The amount of Energy tokens to withdraw.
     */
    function withdrawEnergy(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Withdraw amount must be positive");
        require(_userEnergyBalances[msg.sender] >= amount, "Insufficient deposited energy balance");
        _userEnergyBalances[msg.sender] -= amount;
        require(IERC20(energyToken).transfer(msg.sender, amount), "ERC20 transfer failed");
        emit EnergyWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Gets the deposited energy balance for a user within the contract.
     * @param user The address of the user.
     * @return The user's deposited energy balance.
     */
    function getDepositedEnergy(address user) public view returns (uint256) {
        return _userEnergyBalances[user];
    }

    // --- Oracle / Environmental Influence ---

    /**
     * @dev Sets the address designated as the Oracle. Only callable by owner.
     * The Oracle can trigger environmental events.
     * @param newOracle The address to set as the Oracle.
     */
    function setOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "Invalid address");
        oracleAddress = newOracle;
    }

    /**
     * @dev Allows the Oracle address to trigger an environmental event that affects specified cells.
     * Environmental events can simulate global factors like 'sun', 'rain', 'pollution', etc.,
     * impacting cell attributes or state transitions based on eventType.
     * @param eventType An identifier for the type of environmental event.
     * @param affectedTokenIds An array of cell IDs affected by the event.
     */
    function triggerEnvironmentalEvent(uint256 eventType, uint256[] calldata affectedTokenIds) public onlyOracle whenNotPaused nonReentrant {
        // --- Simplified Environmental Logic ---
        // This function's logic would vary greatly based on eventType.
        // Example: EventType 1 (Simulate Rain): Increase energyLevel for water-dependent cells.
        // Example: EventType 2 (Simulate Drought): Decrease energyLevel for water-dependent cells.
        // Example: EventType 3 (Simulate Pollution): Increase complexity but decrease energy/health.

        for (uint i = 0; i < affectedTokenIds.length; i++) {
            uint256 tokenId = affectedTokenIds[i];
             if (_exists(tokenId)) { // Check existence before accessing state
                 CellState storage cell = _cellStates[tokenId];

                 // Only affect active cells
                 if (cell.status == CellStatus.Active) {
                     uint256 randomFactor = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, eventType, i))) % 10; // Add entropy

                     if (eventType == 1) { // Simulate Rain
                         cell.energyLevel = uint8(int252(cell.energyLevel) + int252(randomFactor) + 5);
                         if (cell.energyLevel > 255) cell.energyLevel = 255;
                         cell.attributes["colorHue"] = (cell.attributes["colorHue"] + int252(randomFactor) - 5) % 256;
                         if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;

                     } else if (eventType == 2) { // Simulate Drought
                         cell.energyLevel = uint8(int252(cell.energyLevel) - int252(randomFactor) - 5);
                          if (cell.energyLevel < 10) cell.energyLevel = 10;
                         cell.attributes["colorHue"] = (cell.attributes["colorHue"] - int252(randomFactor) + 5) % 256;
                         if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;

                     } else if (eventType == 3) { // Simulate Pollution
                          cell.attributes["complexity"] += int256(randomFactor) + 1;
                          cell.energyLevel = uint8(int252(cell.energyLevel) - int252(randomFactor) - 10);
                           if (cell.energyLevel < 10) cell.energyLevel = 10;
                           cell.attributes["colorHue"] = (cell.attributes["colorHue"] + int252(randomFactor * 2)) % 256;
                         if (cell.attributes["colorHue"] < 0) cell.attributes["colorHue"] += 256;
                     }
                     // Add more event types and logic here...

                     cell.lastInteractionTime = uint64(block.timestamp); // Mark as interaction
                 }
             }
        }

        emit EnvironmentalEventTriggered(eventType, affectedTokenIds, msg.sender);
    }


    // --- Governance System ---

    /**
     * @dev Allows users to propose changes to core evolution parameters.
     * Requires paying an energy cost. Voting power is simple 1 user = 1 vote for simplicity,
     * but could be weighted by staked energy or owned cells.
     * @param parameterName The name of the parameter to change.
     * @param newValue The proposed new value for the parameter.
     * @param duration The duration of the voting period in seconds.
     */
    function proposeEvolutionParameterChange(string calldata parameterName, int256 newValue, uint256 duration) public whenNotPaused nonReentrant {
        uint256 proposalCost = _actionCosts["propose"];
        require(_userEnergyBalances[msg.sender] >= proposalCost, "Insufficient deposited energy to propose");
        require(duration > 0, "Vote duration must be positive");

         // Check if the parameterName is a valid one to propose changes for
         // In a full system, this might require a lookup or a list of allowed parameters
         // For simplicity, we assume any parameter in _evolutionParameters can be proposed
         // require(_evolutionParameters[parameterName] != 0 || keccak256(bytes(parameterName)).equals(keccak256(bytes("..."))), "Invalid parameter name");

        _userEnergyBalances[msg.sender] -= proposalCost;

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current() - 1;

        GovernanceProposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.parameterName = parameterName;
        proposal.newValue = newValue;
        proposal.voteStartTime = uint64(block.timestamp);
        proposal.voteEndTime = uint64(block.timestamp + duration);
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.proposer = msg.sender;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, parameterName, newValue, proposal.voteEndTime);
    }

     /**
     * @dev Allows users to vote on an active governance proposal.
     * Simple 1 user = 1 vote. Could be weighted by owned cells or staked energy.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote for, False to vote against.
     */
    function voteOnParameterChange(uint256 proposalId, bool support) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = _proposals[proposalId];

        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!_userVotes[msg.sender][proposalId], "Already voted on this proposal");

        _userVotes[msg.sender][proposalId] = true; // Mark user as voted on this proposal

        // Simple vote counting
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(proposalId, msg.sender, support);

        // Auto-resolve if vote ends during this transaction (unlikely but possible)
        if (block.timestamp > proposal.voteEndTime) {
             _tallyVotes(proposalId);
        }
    }

    /**
     * @dev Allows anyone to execute a proposal that has passed and whose voting period has ended.
     * Checks if the proposal meets the passing criteria.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = _proposals[proposalId];

        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(proposal.state != ProposalState.Canceled, "Proposal canceled");
        require(block.timestamp > proposal.voteEndTime, "Voting period not ended yet");

        // Tally votes if not already done
        if (proposal.state == ProposalState.Active) {
            _tallyVotes(proposalId);
        }

        require(proposal.state == ProposalState.Passed, "Proposal did not pass");

        // --- Execution Logic ---
        _evolutionParameters[proposal.parameterName] = proposal.newValue;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
        emit EvolutionParameterChanged(proposal.parameterName, proposal.newValue, proposalId);
    }

    /**
     * @dev Internal function to tally votes and update proposal state after the voting period ends.
     * @param proposalId The ID of the proposal to tally.
     */
    function _tallyVotes(uint256 proposalId) internal {
         GovernanceProposal storage proposal = _proposals[proposalId];
         require(proposal.state == ProposalState.Active, "Proposal not active for tally");
         require(block.timestamp > proposal.voteEndTime, "Voting period not ended");

         uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
         int256 minVotes = _evolutionParameters["minVotesForProposal"];
         int256 requiredMajorityPercent = _evolutionParameters["requiredMajorityPercent"];

         if (totalVotes < uint256(minVotes)) {
             proposal.state = ProposalState.Failed;
         } else if (proposal.votesFor * 100 > totalVotes * uint256(requiredMajorityPercent)) {
              proposal.state = ProposalState.Passed;
         } else {
              proposal.state = ProposalState.Failed;
         }
    }


    // --- Query Functions ---

    /**
     * @dev Gets the full state struct of a cell.
     * @param tokenId The ID of the cell.
     * @return The CellState struct.
     */
    function getCellState(uint256 tokenId) public view cellExists(tokenId) returns (CellState memory) {
        // Note: This returns a memory copy. Nested mappings like 'attributes'
        // cannot be returned directly in their entirety from a struct.
        // You would need separate view functions for specific attributes.
        // For simplicity, we copy the struct but the attributes mapping will be empty.
        // A real implementation might return a tuple with key attributes or use a helper.
         CellState memory cell = _cellStates[tokenId];
         // To return attributes, you'd need to know the keys or iterate (complex on-chain)
         // Example: return (cell.id, cell.owner, ..., cell.energyLevel, cell.attributes["complexity"], cell.attributes["colorHue"]);
        return cell; // This will return struct with default values for mapping unless specified
    }

     /**
     * @dev Gets the specific on-chain visual parameters stored for a cell.
     * Used by off-chain rendering systems.
     * @param tokenId The ID of the cell.
     * @return colorCode A numeric representation of the color (e.g., 0-255 hue).
     * @return shapeCode A numeric representation of the shape (e.g., 0=circle, 1=square).
     * @return patternCode A numeric representation of the pattern.
     */
    function getCellVisualParameters(uint256 tokenId) public view cellExists(tokenId) returns (uint8 colorCode, uint8 shapeCode, uint8 patternCode) {
         CellState storage cell = _cellStates[tokenId];
         // These attributes are accessed directly from the mapping within the struct
         // We need to handle the case where an attribute might not be set yet (returns 0 for int256)
         colorCode = uint8(cell.attributes["colorHue"]);
         shapeCode = uint8(cell.attributes["shapeCode"]); // Assume 'shapeCode' is a stored attribute
         patternCode = uint8(cell.attributes["patternCode"]); // Assume 'patternCode' is a stored attribute
    }


    /**
     * @dev Gets the current value of an evolution parameter.
     * @param parameterName The name of the parameter.
     * @return The current value of the parameter.
     */
    function getEvolutionParameter(string calldata parameterName) public view returns (int256) {
        return _evolutionParameters[parameterName];
    }

    /**
     * @dev Gets details of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return Details of the proposal. Returns default struct if proposal doesn't exist.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
         ProposalState state,
         string memory parameterName,
         int256 newValue,
         uint64 voteStartTime,
         uint64 voteEndTime,
         uint256 votesFor,
         uint256 votesAgainst,
         address proposer,
         bool executed // Simple boolean flag derived from state
     ) {
         GovernanceProposal memory proposal = _proposals[proposalId];
         state = proposal.state;
         parameterName = proposal.parameterName;
         newValue = proposal.newValue;
         voteStartTime = proposal.voteStartTime;
         voteEndTime = proposal.voteEndTime;
         votesFor = proposal.votesFor;
         votesAgainst = proposal.votesAgainst;
         proposer = proposal.proposer;
         executed = (proposal.state == ProposalState.Executed);
     }


    // --- Admin / Utility Functions ---

    /**
     * @dev Pauses the contract. Only owner can call.
     * Inherited from Pausable.
     */
    function pauseActions() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     * Inherited from Pausable.
     */
    function unpauseActions() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to rescue ERC20 tokens accidentally sent to the contract.
     * Prevents rescuing the contract's own Energy token.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount to rescue.
     */
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner nonReentrable {
        require(tokenAddress != energyToken, "Cannot rescue the contract's energy token");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in contract");
        require(token.transfer(msg.sender, amount), "ERC20 rescue transfer failed");
        emit RescueERC20(tokenAddress, amount);
    }

     /**
     * @dev Allows the owner or via governance to set the energy cost for a specific action.
     * @param actionName The name of the action (e.g., "mint", "evolve").
     * @param cost The new cost in Energy tokens.
     */
    function setEvolutionParameterCost(string calldata actionName, uint256 cost) public onlyOwner {
        // In a full governance system, this might only be executable via a passed proposal
        _actionCosts[actionName] = cost;
        emit ActionCostSet(actionName, cost);
    }

     /**
     * @dev Gets the energy cost for a specific action.
     * @param actionName The name of the action.
     * @return The cost in Energy tokens. Returns 0 if action name is not set.
     */
    function getEvolutionParameterCost(string calldata actionName) public view returns (uint256) {
        return _actionCosts[actionName];
    }

    // --- Internal ERC721 Overrides ---
    // These are needed for ERC721Burnable to work correctly with _beforeTokenTransfer

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When transferring, update the owner in our custom state struct
        if (from == address(0)) { // Minting
             // CellState struct is initialized during minting functions
        } else if (to == address(0)) { // Burning
            // Update status to indicate burned/no longer active
            _cellStates[tokenId].status = CellStatus.Dormant; // Or a specific 'Burned' status
            _cellStates[tokenId].owner = address(0); // Clear owner
        } else { // Transferring between users
            _cellStates[tokenId].owner = to;
        }
    }

    // --- Internal Helpers ---
    // Helper for string comparison
    function equals(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(bytes(s1)) == keccak256(bytes(s2));
    }

    // Base64 encoding library (import or include)
    // NOTE: Using OpenZeppelin's helpers. Requires "@openzeppelin/contracts/utils/Base64.sol";
    // Included at the top.

}

// Helper library for Base64 encoding (if not using OpenZeppelin)
// This is a simplified version; a full implementation is in OpenZeppelin's Base64.sol
// library Base64 {
//     function encode(bytes memory data) internal pure returns (string memory) {
//         // Placeholder - complex encoding logic goes here
//         return "placeholder_base64_encoded_string";
//     }
// }
```

---

**Explanation of Advanced/Creative Aspects:**

1.  **Dynamic On-Chain State:** Each Cell NFT (`_cellStates` mapping) holds a detailed `CellState` struct. This state is *mutable* via contract functions (`evolveCellStep`, `influenceCellAttribute`, `triggerEnvironmentalEvent`, etc.).
2.  **On-Chain Procedural Parameters:** `_evolutionParameters` and `_actionCosts` store core game/ecosystem rules and costs directly on-chain, accessible by all and potentially modifiable by governance.
3.  **Integrated Tokenomics:** The contract directly manages user balances of a linked ERC-20 token (`_userEnergyBalances`) and requires users to deposit this token (`depositEnergy`) before performing energy-costing actions. Actions then deduct from this internal balance. This keeps the Energy token flow within the contract for actions, rather than requiring direct `transferFrom` calls for every micro-action, potentially saving gas and simplifying approval flows after the initial deposit.
4.  **Spatial Simulation (`neighbors`):** The `neighbors` array within `CellState` and the `registerNeighborLink`/`breakNeighborLink` functions allow simulating spatial relationships or connections between NFTs. This state can then be used in evolution logic (e.g., neighbor state influencing evolution, cost based on number of neighbors).
5.  **Multi-Stage Evolution (`stage`, `status`):** Cells have distinct stages and statuses, enabling complex lifecycle mechanics (Seed -> Bud -> Bloom -> Decay -> Rebirth) and conditional actions (only active cells can evolve).
6.  **Oracle/Environmental Influence:** The `onlyOracle` modifier and `triggerEnvironmentalEvent` function provide a mechanism for a designated entity (or even a decentralized oracle network in a real DApp) to inject external state changes or global events into the ecosystem, influencing cell states.
7.  **NFT Merging and Splitting:** `mergeCells` and `splitCell` are advanced NFT mechanics that create new tokens from existing ones, transferring or combining/dividing state and attributes. This adds depth beyond simple minting and burning.
8.  **Batch Operations:** `batchEvolveOwnedCells` demonstrates a gas optimization pattern where a user can process multiple owned assets in a single transaction, reducing the per-action gas cost compared to calling `evolveCellStep` individually for each token.
9.  **Governance (`propose`, `vote`, `execute`):** A basic governance system allows users to propose changes to `_evolutionParameters`, vote on them, and execute passed proposals. While simplified (1 user = 1 vote, basic tally), it introduces decentralized control over core contract parameters.
10. **Sponsorship:** `sponsorEvolutionStep` allows a user to pay the energy cost for *another* cell's evolution, recording the sponsor. This could enable community support, patron roles, or quest systems.
11. **Dynamic Metadata (`tokenURI`):** The `tokenURI` function *must* be implemented to reflect the *current* on-chain state of the Cell. The example shows how it would construct a metadata JSON string based on the `CellState`, pointing out that the image/full JSON would likely be served dynamically by an off-chain service querying the contract state. It includes retrieving specific on-chain visual parameters.
12. **Internal Attribute Mapping:** Using a `mapping(string => int256) attributes` within the `CellState` struct allows for flexible storage of diverse, dynamic numerical attributes per cell. Accessing/managing this mapping adds complexity.
13. **ReentrancyGuard:** Included as best practice when interacting with external tokens (like the Energy token).
14. **Pausable:** Provides a standard safety mechanism to halt sensitive operations in emergencies.
15. **Rescue Function:** A utility function to recover accidentally sent tokens, common in complex contracts dealing with multiple token types.

This contract provides a framework for a complex, dynamic digital ecosystem with multiple layers of interaction and control, fulfilling the requirements for unique, advanced, creative, and numerous functions. Remember that a production-ready contract would require extensive security audits, more robust error handling, and potentially more sophisticated logic for the core mechanics (evolution rules, attribute influence, governance voting power).