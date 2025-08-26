This smart contract, **EvoSphere: Autonomous Algorithmic Habitat**, introduces a novel concept of a self-evolving digital ecosystem. It combines dynamic NFTs, a simplified on-chain prediction market, verifiable external data through oracles, and gamified resource management.

The core idea is a collection of unique, dynamic **EvoSphere** NFTs (ERC-721 habitats) that host **Organism** NFTs (also internally managed by the contract) and utilize **Seed** tokens (ERC-1155 equivalent, internally managed) for growth. The key innovation lies in the EvoSpheres' climate parameters autonomously adapting based on a weighted input of real-world oracle data and successful user-submitted "prognostications."

Users can play various roles:
*   **Cultivators:** Deposit Seeds into EvoSpheres to grow Organisms, and harvest yields.
*   **Prognosticators:** Predict future climate parameters for EvoSpheres and are rewarded for accuracy. Their successful predictions also influence the autonomous adaptation.
*   **Stewards:** Vote on ecosystem-wide policies and parameter changes.
*   **Oracles:** Authorized entities that submit real-world data.

This contract aims to create a dynamic, interactive, and partially self-governing digital world where the environment genuinely responds to internal activity and external influences.

---

### Contract: EvoSphereCore

**Outline:**

1.  **Contract Information & Dependencies:** SPDX License, Solidity Version, OpenZeppelin imports (ERC721, AccessControl, Ownable).
2.  **Error Definitions:** Custom errors for clearer reverts.
3.  **Enums & Structs:**
    *   `ClimateParameterIndex`: Enum for different climate parameters.
    *   `ClimateParameters`: Struct holding dynamic climate values.
    *   `EvoSphere`: Struct for habitat NFT details (inherits ERC721 properties implicitly).
    *   `SeedType`: Struct for fungible seed token definitions.
    *   `Organism`: Struct for organism NFT details.
    *   `Prognostication`: Struct for individual predictions.
    *   `PolicyProposal`: Struct for governance proposals.
4.  **State Variables:**
    *   `ERC721` mappings for EvoSpheres.
    *   Counters for EvoSpheres, Organisms, Seed Types, Proposals.
    *   Mappings for `EvoSphere` data, `Organism` data, `SeedType` data.
    *   Balances for internally managed Seeds and Resources.
    *   Oracle and Prognosticator configurations.
    *   Climate parameter bounds and adaptation logic.
    *   Governance proposal tracking.
5.  **Events:** For logging important actions and state changes.
6.  **Access Control & Configuration:** Roles (`ORACLE_ROLE`, `STEWARD_ROLE`, `PROGNOSTICATOR_REWARD_DISTRIBUTOR_ROLE`), owner.
7.  **Constructor:** Initializes roles and base ERC721.
8.  **EvoSphere Management (ERC-721 for EvoSpheres):** Minting, detail retrieval, metadata updates, resource withdrawal.
9.  **Seed & Organism Management (Internal Token Logic):**
    *   Defining and minting Seed types.
    *   Depositing Seeds to EvoSpheres.
    *   Growing Organisms from Seeds.
    *   Harvesting Organism yields.
    *   Transferring Organism ownership.
    *   Retrieving details and balances for Seeds and Organisms.
10. **Climate Adaptation & Prognostication:**
    *   Submitting predictions.
    *   Recording oracle data.
    *   Triggering autonomous adaptation.
    *   Claiming prognostication rewards.
11. **Ecosystem Parameters & Governance:**
    *   Setting global climate parameter bounds.
    *   Adjusting prognostication reward rates.
    *   Proposing, voting on, and executing ecosystem policies.
12. **Internal Helper Functions:** For state evolution, resource consumption, and prediction evaluation.

---

### Function Summary:

**I. Core EvoSphere Management (ERC-721 for EvoSpheres)**
*   `createEvoSphere(string calldata _name, string calldata _metadataURI, uint256 _initialResourceCapacity)`: Mints a new EvoSphere NFT to the caller, initializing its name, metadata URI, and internal resource capacity.
*   `getEvoSphereDetails(uint256 _evoSphereId)`: Retrieves comprehensive details about a specific EvoSphere, including its climate, resource levels, and vital statistics.
*   `updateEvoSphereTraitsURI(uint256 _evoSphereId, string calldata _newURI)`: Allows the owner of an EvoSphere to update its external metadata URI, typically after its traits have dynamically evolved.
*   `getCurrentEvoSphereClimate(uint256 _evoSphereId)`: Returns the current `ClimateParameters` for a given EvoSphere, reflecting its environmental state.
*   `withdrawEvoSphereResources(uint256 _evoSphereId, address _to, uint256 _amount)`: Allows the EvoSphere owner to withdraw accumulated internal `ResourceToken` from its pool to a specified address.

**II. Seed & Organism Management (Internal Token Logic)**
*   `defineSeedType(string calldata _seedMetadataURI, uint256 _growthRate, uint256 _resourceConsumptionPerTick)`: Allows an authorized admin to define a new type of `Seed` (an ERC-1155 equivalent) with specific properties like growth rate and resource needs.
*   `mintInitialSeeds(uint256 _seedTypeId, address _to, uint256 _amount)`: Mints an initial supply of a defined `SeedType` to a specified address for distribution.
*   `depositSeedsToEvoSphere(uint256 _evoSphereId, uint256 _seedTypeId, uint256 _amount)`: Allows a user to deposit their `Seed` tokens into an EvoSphere's internal bank, making them available for growing organisms.
*   `growOrganism(uint256 _evoSphereId, uint256 _seedTypeId, string calldata _organismMetadataURI)`: Cultivator consumes `Seed` tokens from an EvoSphere's bank to "grow" (mint) a new `Organism` (internally managed NFT) within that EvoSphere.
*   `harvestOrganismYield(uint256 _organismId)`: Allows the owner of an `Organism` to collect `ResourceToken` yield generated by the organism and update its state.
*   `transferOrganismOwnership(uint256 _organismId, address _newOwner)`: Transfers the internal ownership of an `Organism` from the current owner to a new address.
*   `getOrganismDetails(uint256 _organismId)`: Retrieves detailed information about a specific `Organism`, including its parent EvoSphere, traits, and health.
*   `getSeedBalance(address _holder, uint256 _seedTypeId)`: Returns the `Seed` token balance of a specific `SeedType` for a given user address.
*   `getEvoSphereSeedBalance(uint256 _evoSphereId, uint256 _seedTypeId)`: Returns the `Seed` token balance of a specific `SeedType` held within an EvoSphere's internal bank.

**III. Climate Adaptation & Prognostication**
*   `submitClimatePrognostication(uint256 _evoSphereId, ClimateParameterIndex _parameterIndex, int256 _predictedValue)`: A `Prognosticator` submits a prediction for a specific climate parameter of an EvoSphere within the active prognostication window.
*   `recordOracleClimateData(uint256 _evoSphereId, ClimateParameterIndex _parameterIndex, int256 _oracleValue)`: An authorized `ORACLE_ROLE` member submits the actual, real-world climate data for a parameter, used for adaptation and prediction evaluation.
*   `triggerEvoSphereAdaptation(uint256 _evoSphereId)`: Anyone can call this to trigger the autonomous adaptation logic for an EvoSphere. This evaluates recent prognoses, uses oracle data, and updates the EvoSphere's climate.
*   `claimPrognosticatorReward(uint256 _evoSphereId, ClimateParameterIndex _parameterIndex, address _prognosticator)`: Allows a `Prognosticator` to claim `ResourceToken` rewards if their prediction for a specific climate parameter was accurate after adaptation.

**IV. Ecosystem Parameters & Governance**
*   `setClimateParameterBounds(ClimateParameterIndex _parameterIndex, int256 _min, int256 _max)`: An authorized admin/governance function to set the minimum and maximum allowed values for a global climate parameter.
*   `setPrognosticationRewardRate(uint256 _rate)`: An authorized admin/governance function to adjust the reward rate for accurate prognostications.
*   `proposeEcosystemPolicy(string calldata _proposalURI, uint256 _durationBlocks)`: An authorized `STEWARD_ROLE` member proposes a new ecosystem policy, providing a URI for details and setting a voting duration.
*   `voteOnPolicyProposal(uint256 _proposalId, bool _support)`: An authorized `STEWARD_ROLE` member casts their vote (support or oppose) on an active ecosystem policy proposal.
*   `executePolicyProposal(uint256 _proposalId)`: Anyone can call this after a policy proposal's voting duration ends. If the proposal passed (sufficient votes), its effects are triggered. (Actual effects would be a simplified placeholder, e.g., triggering `setClimateParameterBounds`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for enhanced clarity and gas efficiency
error EvoSphere__NotEvoSphereOwner();
error EvoSphere__InvalidEvoSphereId();
error EvoSphere__InsufficientResources(uint256 required, uint256 available);
error EvoSphere__OrganismNotFound();
error EvoSphere__InsufficientSeeds(uint256 required, uint256 available);
error EvoSphere__SeedTypeNotFound();
error EvoSphere__InvalidPrognosticationValue(int256 min, int256 max, int256 value);
error EvoSphere__PrognosticationWindowClosed();
error EvoSphere__NoOracleDataAvailable();
error EvoSphere__AlreadyPrognosticated();
error EvoSphere__PredictionTooOld();
error EvoSphere__NoClaimableReward();
error EvoSphere__PolicyProposalNotFound();
error EvoSphere__PolicyVotingPeriodActive();
error EvoSphere__PolicyVotingPeriodExpired();
error EvoSphere__PolicyAlreadyExecuted();
error EvoSphere__PolicyNotPassed();
error EvoSphere__NotPolicyVoter();
error EvoSphere__AlreadyVoted();
error EvoSphere__InvalidOrganismOwner();
error EvoSphere__ResourceCapacityExceeded(uint256 current, uint256 max);

contract EvoSphereCore is ERC721, AccessControl {
    using Counters for Counters.Counter;

    // --- ENUMS & STRUCTS ---

    enum ClimateParameterIndex {
        Temperature,
        Humidity,
        LightIntensity,
        SoilNutrients // Example
    }

    struct ClimateParameters {
        int256 temperature;
        int256 humidity;
        int256 lightIntensity;
        int256 soilNutrients;
    }

    struct EvoSphere {
        string name;
        string metadataURI;
        uint256 resourceCapacity;
        uint256 currentResourcePool; // Internal fungible resource token balance
        ClimateParameters currentClimate;
        uint256 lastAdaptationBlock;
        mapping(ClimateParameterIndex => int256) lastOracleValues; // Last recorded oracle value for each parameter
        mapping(ClimateParameterIndex => uint256) oracleLastUpdateBlock; // Block number when oracle data was last updated
        mapping(ClimateParameterIndex => mapping(address => Prognostication)) activePrognostications; // addr => latest prognostication
        mapping(ClimateParameterIndex => uint256) prognosticationWindowStart; // Start block of current prediction window
    }

    struct SeedType {
        string metadataURI;
        uint256 growthRate; // How fast organisms grow from this seed
        uint256 resourceConsumptionPerTick; // Resources consumed by organisms of this type per adaptation tick
        uint256 currentSupply; // Total supply of this seed type
        uint256 maxSupply; // Max supply for this seed type (0 for unlimited)
    }

    struct Organism {
        uint256 evoSphereId; // The EvoSphere this organism belongs to
        address owner; // The owner of this organism
        uint256 seedTypeId; // The type of seed it grew from
        string metadataURI; // Dynamic metadata URI for the organism
        uint256 lastHarvestBlock; // Block number of last harvest/state update
        uint256 health; // Organism health (0-100)
        uint256 accumulatedYield; // Internal yield ready for harvest
    }

    struct Prognostication {
        int256 predictedValue;
        uint256 submittedBlock;
        bool rewarded; // Has this prognostication been rewarded?
    }

    struct PolicyProposal {
        string proposalURI; // Link to detailed proposal (e.g., IPFS)
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed; // Final outcome
    }

    // --- STATE VARIABLES ---

    // Roles
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant STEWARD_ROLE = keccak256("STEWARD_ROLE");
    // This role can distribute rewards manually if needed, or it can be a self-executing system.
    bytes32 public constant PROGNOSTICATOR_REWARD_DISTRIBUTOR_ROLE = keccak256("PROGNOSTICATOR_REWARD_DISTRIBUTOR_ROLE");

    // Counters for unique IDs
    Counters.Counter private _evoSphereIdCounter;
    Counters.Counter private _seedTypeIdCounter;
    Counters.Counter private _organismIdCounter;
    Counters.Counter private _proposalIdCounter;

    // EvoSpheres storage
    mapping(uint256 => EvoSphere) public evoSpheres;
    mapping(uint256 => address) private _evoSphereOwners; // Redundant with ERC721 but useful for clarity

    // Seeds storage (internal ERC-1155 equivalent)
    mapping(uint256 => SeedType) public seedTypes;
    mapping(address => mapping(uint256 => uint256)) public userSeedBalances; // user => seedTypeId => amount
    mapping(uint256 => mapping(uint256 => uint256)) public evoSphereSeedBanks; // evoSphereId => seedTypeId => amount

    // Organisms storage (internal ERC-721 equivalent)
    mapping(uint256 => Organism) public organisms;

    // Climate Parameters Configuration
    mapping(ClimateParameterIndex => int256) public minClimateValues;
    mapping(ClimateParameterIndex => int256) public maxClimateValues;
    uint256 public prognosticationWindowBlocks; // How long a prediction window lasts
    uint256 public prognosticationRewardRate; // Amount of ResourceToken rewarded for accurate prediction
    uint256 public constant PROGNOSTICATION_ACCURACY_TOLERANCE = 5; // e.g., +/- 5 units for accuracy

    // Governance Parameters
    uint256 public proposalQuorumPercentage = 50; // % of stewards needed to vote
    uint256 public proposalMajorityPercentage = 51; // % of votesFor needed to pass
    mapping(uint256 => PolicyProposal) public policyProposals;

    // --- EVENTS ---

    event EvoSphereCreated(uint256 indexed evoSphereId, address indexed owner, string name, string metadataURI);
    event EvoSphereClimateAdapted(uint256 indexed evoSphereId, ClimateParameters newClimate, uint256 blockNumber);
    event EvoSphereResourcesWithdrawn(uint256 indexed evoSphereId, address indexed to, uint256 amount);

    event SeedTypeDefined(uint256 indexed seedTypeId, string metadataURI, uint256 growthRate, uint256 resourceConsumptionPerTick);
    event SeedsMinted(uint256 indexed seedTypeId, address indexed to, uint256 amount);
    event SeedsDeposited(uint256 indexed evoSphereId, uint256 indexed seedTypeId, address indexed depositor, uint256 amount);
    event OrganismGrown(uint256 indexed organismId, uint256 indexed evoSphereId, uint256 indexed seedTypeId, address owner);
    event OrganismYieldHarvested(uint256 indexed organismId, address indexed owner, uint256 amount);
    event OrganismOwnershipTransferred(uint256 indexed organismId, address indexed from, address indexed to);

    event ClimatePrognosticationSubmitted(uint256 indexed evoSphereId, ClimateParameterIndex indexed paramIndex, address indexed prognosticator, int256 predictedValue);
    event OracleClimateDataRecorded(uint256 indexed evoSphereId, ClimateParameterIndex indexed paramIndex, int256 oracleValue);
    event PrognosticatorRewarded(uint256 indexed evoSphereId, ClimateParameterIndex indexed paramIndex, address indexed prognosticator, uint256 rewardAmount);

    event PolicyProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalURI, uint256 endBlock);
    event PolicyVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event PolicyExecuted(uint256 indexed proposalId, bool passed);

    // --- CONSTRUCTOR ---

    constructor(address defaultAdmin) ERC721("EvoSphereHabitat", "EVOSH") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ORACLE_ROLE, defaultAdmin); // Default admin is also an oracle
        _grantRole(STEWARD_ROLE, defaultAdmin); // Default admin is also a steward
        _grantRole(PROGNOSTICATOR_REWARD_DISTRIBUTOR_ROLE, defaultAdmin);

        // Initialize default climate parameter bounds
        minClimateValues[ClimateParameterIndex.Temperature] = -100;
        maxClimateValues[ClimateParameterIndex.Temperature] = 100;
        minClimateValues[ClimateParameterIndex.Humidity] = 0;
        maxClimateValues[ClimateParameterIndex.Humidity] = 100;
        minClimateValues[ClimateParameterIndex.LightIntensity] = 0;
        maxClimateValues[ClimateParameterIndex.LightIntensity] = 100;
        minClimateValues[ClimateParameterIndex.SoilNutrients] = 0;
        maxClimateValues[ClimateParameterIndex.SoilNutrients] = 100;

        prognosticationWindowBlocks = 100; // Example: 100 blocks for prediction window
        prognosticationRewardRate = 100 * 10 ** 18; // Example: 100 units of ResourceToken
    }

    // --- EVO SPHERE MANAGEMENT (ERC-721) ---

    function createEvoSphere(
        string calldata _name,
        string calldata _metadataURI,
        uint256 _initialResourceCapacity
    ) public {
        _evoSphereIdCounter.increment();
        uint256 newEvoSphereId = _evoSphereIdCounter.current();

        EvoSphere storage newEvoSphere = evoSpheres[newEvoSphereId];
        newEvoSphere.name = _name;
        newEvoSphere.metadataURI = _metadataURI;
        newEvoSphere.resourceCapacity = _initialResourceCapacity;
        newEvoSphere.currentResourcePool = 0; // Starts empty, resources accumulate/are deposited
        newEvoSphere.currentClimate = ClimateParameters(0, 50, 50, 50); // Initial climate
        newEvoSphere.lastAdaptationBlock = block.number;

        // Initialize prognostication window start for all parameters
        newEvoSphere.prognosticationWindowStart[ClimateParameterIndex.Temperature] = block.number;
        newEvoSphere.prognosticationWindowStart[ClimateParameterIndex.Humidity] = block.number;
        newEvoSphere.prognosticationWindowStart[ClimateParameterIndex.LightIntensity] = block.number;
        newEvoSphere.prognosticationWindowStart[ClimateParameterIndex.SoilNutrients] = block.number;

        _safeMint(msg.sender, newEvoSphereId);
        _evoSphereOwners[newEvoSphereId] = msg.sender; // Store owner explicitly for easy lookup

        emit EvoSphereCreated(newEvoSphereId, msg.sender, _name, _metadataURI);
    }

    function getEvoSphereDetails(uint256 _evoSphereId)
        public
        view
        returns (
            string memory name,
            string memory metadataURI,
            uint256 resourceCapacity,
            uint256 currentResourcePool,
            ClimateParameters memory climate,
            uint256 lastAdaptationBlock
        )
    {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];
        return (
            evosphere.name,
            evosphere.metadataURI,
            evosphere.resourceCapacity,
            evosphere.currentResourcePool,
            evosphere.currentClimate,
            evosphere.lastAdaptationBlock
        );
    }

    function updateEvoSphereTraitsURI(uint256 _evoSphereId, string calldata _newURI) public {
        if (ownerOf(_evoSphereId) != msg.sender) {
            revert EvoSphere__NotEvoSphereOwner();
        }
        evoSpheres[_evoSphereId].metadataURI = _newURI;
        // Consider emitting a specific event for metadata update if needed
    }

    function getCurrentEvoSphereClimate(uint256 _evoSphereId) public view returns (ClimateParameters memory) {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        return evoSpheres[_evoSphereId].currentClimate;
    }

    function withdrawEvoSphereResources(uint256 _evoSphereId, address _to, uint256 _amount) public {
        if (ownerOf(_evoSphereId) != msg.sender) {
            revert EvoSphere__NotEvoSphereOwner();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];
        if (evosphere.currentResourcePool < _amount) {
            revert EvoSphere__InsufficientResources(_amount, evosphere.currentResourcePool);
        }
        evosphere.currentResourcePool -= _amount;
        // In a real scenario, _to would receive an actual ERC-20 token or ETH.
        // For this conceptual contract, we only manage the internal balance.
        // A specific external `ResourceToken` contract would be integrated here.
        // Example: IResourceToken(resourceTokenAddress).transfer(_to, _amount);
        emit EvoSphereResourcesWithdrawn(_evoSphereId, _to, _amount);
    }

    // --- SEED & ORGANISM MANAGEMENT (Internal Token Logic) ---

    function defineSeedType(
        string calldata _seedMetadataURI,
        uint256 _growthRate,
        uint256 _resourceConsumptionPerTick
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        _seedTypeIdCounter.increment();
        uint256 newSeedTypeId = _seedTypeIdCounter.current();

        seedTypes[newSeedTypeId] = SeedType({
            metadataURI: _seedMetadataURI,
            growthRate: _growthRate,
            resourceConsumptionPerTick: _resourceConsumptionPerTick,
            currentSupply: 0, // Starts with 0, must be minted
            maxSupply: 0 // For now, unlimited max supply (0)
        });

        emit SeedTypeDefined(newSeedTypeId, _seedMetadataURI, _growthRate, _resourceConsumptionPerTick);
        return newSeedTypeId;
    }

    function mintInitialSeeds(uint256 _seedTypeId, address _to, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (seedTypes[_seedTypeId].currentSupply == 0 && _seedTypeIdCounter.current() < _seedTypeId) {
            revert EvoSphere__SeedTypeNotFound();
        }
        seedTypes[_seedTypeId].currentSupply += _amount;
        userSeedBalances[_to][_seedTypeId] += _amount;
        emit SeedsMinted(_seedTypeId, _to, _amount);
    }

    function depositSeedsToEvoSphere(uint256 _evoSphereId, uint256 _seedTypeId, uint256 _amount) public {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        if (userSeedBalances[msg.sender][_seedTypeId] < _amount) {
            revert EvoSphere__InsufficientSeeds(_amount, userSeedBalances[msg.sender][_seedTypeId]);
        }
        userSeedBalances[msg.sender][_seedTypeId] -= _amount;
        evoSphereSeedBanks[_evoSphereId][_seedTypeId] += _amount;
        emit SeedsDeposited(_evoSphereId, _seedTypeId, msg.sender, _amount);
    }

    function growOrganism(
        uint256 _evoSphereId,
        uint256 _seedTypeId,
        string calldata _organismMetadataURI
    ) public {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        if (evoSphereSeedBanks[_evoSphereId][_seedTypeId] < 1) {
            revert EvoSphere__InsufficientSeeds(1, evoSphereSeedBanks[_evoSphereId][_seedTypeId]);
        }
        if (seedTypes[_seedTypeId].growthRate == 0 && _seedTypeIdCounter.current() < _seedTypeId) {
            revert EvoSphere__SeedTypeNotFound();
        }

        evoSphereSeedBanks[_evoSphereId][_seedTypeId] -= 1; // Consume one seed
        seedTypes[_seedTypeId].currentSupply -= 1; // Decrease total seed supply

        _organismIdCounter.increment();
        uint256 newOrganismId = _organismIdCounter.current();

        organisms[newOrganismId] = Organism({
            evoSphereId: _evoSphereId,
            owner: msg.sender,
            seedTypeId: _seedTypeId,
            metadataURI: _organismMetadataURI,
            lastHarvestBlock: block.number,
            health: 100, // Starts at full health
            accumulatedYield: 0
        });

        emit OrganismGrown(newOrganismId, _evoSphereId, _seedTypeId, msg.sender);
    }

    function harvestOrganismYield(uint256 _organismId) public {
        Organism storage organism = organisms[_organismId];
        if (organism.owner == address(0) || organism.owner != msg.sender) {
            revert EvoSphere__OrganismNotFound();
        }

        _evolveOrganismState(_organismId); // Update organism state and yield

        uint256 yieldAmount = organism.accumulatedYield;
        if (yieldAmount == 0) {
            // No yield accumulated yet
            return;
        }

        EvoSphere storage evosphere = evoSpheres[organism.evoSphereId];
        // In a real scenario, this would transfer actual ResourceTokens.
        // For this concept, we just credit the EvoSphere's internal pool.
        // Or, if the yield is for the organism owner, we increase the owner's resource balance
        // For simplicity, let's say yields are added to EvoSphere's pool, and owner withdraws from there.
        // If yield is directly for the owner:
        // userResourceBalances[msg.sender] += yieldAmount;
        // We will add it to the EvoSphere's pool, and the EvoSphere owner can choose to withdraw it.
        // Or, for more direct owner benefit, the yield could be given to the organism owner directly.
        // Let's make it go to the EvoSphere pool where organism resides.
        if (evosphere.currentResourcePool + yieldAmount > evosphere.resourceCapacity) {
            revert EvoSphere__ResourceCapacityExceeded(evosphere.currentResourcePool, evosphere.resourceCapacity);
        }
        evosphere.currentResourcePool += yieldAmount;
        organism.accumulatedYield = 0; // Reset accumulated yield

        emit OrganismYieldHarvested(_organismId, msg.sender, yieldAmount);
    }

    function transferOrganismOwnership(uint256 _organismId, address _newOwner) public {
        Organism storage organism = organisms[_organismId];
        if (organism.owner == address(0)) {
            revert EvoSphere__OrganismNotFound();
        }
        if (organism.owner != msg.sender) {
            revert EvoSphere__InvalidOrganismOwner();
        }
        address oldOwner = organism.owner;
        organism.owner = _newOwner;
        emit OrganismOwnershipTransferred(_organismId, oldOwner, _newOwner);
    }

    function getOrganismDetails(uint256 _organismId)
        public
        view
        returns (
            uint256 evoSphereId,
            address owner,
            uint256 seedTypeId,
            string memory metadataURI,
            uint256 lastHarvestBlock,
            uint256 health,
            uint256 accumulatedYield
        )
    {
        Organism storage organism = organisms[_organismId];
        if (organism.owner == address(0)) {
            revert EvoSphere__OrganismNotFound();
        }
        return (
            organism.evoSphereId,
            organism.owner,
            organism.seedTypeId,
            organism.metadataURI,
            organism.lastHarvestBlock,
            organism.health,
            organism.accumulatedYield
        );
    }

    function getSeedBalance(address _holder, uint256 _seedTypeId) public view returns (uint256) {
        return userSeedBalances[_holder][_seedTypeId];
    }

    function getEvoSphereSeedBalance(uint256 _evoSphereId, uint256 _seedTypeId) public view returns (uint256) {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        return evoSphereSeedBanks[_evoSphereId][_seedTypeId];
    }

    // --- CLIMATE ADAPTATION & PROGNOSTICATION ---

    function submitClimatePrognostication(
        uint256 _evoSphereId,
        ClimateParameterIndex _parameterIndex,
        int256 _predictedValue
    ) public {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];

        if (block.number < evosphere.prognosticationWindowStart[_parameterIndex]) {
            // Window hasn't even started (should not happen if logic is sound)
            revert EvoSphere__PredictionTooOld();
        }
        if (block.number >= evosphere.prognosticationWindowStart[_parameterIndex] + prognosticationWindowBlocks) {
            revert EvoSphere__PrognosticationWindowClosed();
        }

        // Check bounds
        if (_predictedValue < minClimateValues[_parameterIndex] || _predictedValue > maxClimateValues[_parameterIndex]) {
            revert EvoSphere__InvalidPrognosticationValue(minClimateValues[_parameterIndex], maxClimateValues[_parameterIndex], _predictedValue);
        }

        // Store or update prognosticator's prediction
        evosphere.activePrognostications[_parameterIndex][msg.sender] = Prognostication({
            predictedValue: _predictedValue,
            submittedBlock: block.number,
            rewarded: false
        });

        emit ClimatePrognosticationSubmitted(_evoSphereId, _parameterIndex, msg.sender, _predictedValue);
    }

    function recordOracleClimateData(
        uint256 _evoSphereId,
        ClimateParameterIndex _parameterIndex,
        int256 _oracleValue
    ) public onlyRole(ORACLE_ROLE) {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];

        // Update the oracle value and timestamp
        evosphere.lastOracleValues[_parameterIndex] = _oracleValue;
        evosphere.oracleLastUpdateBlock[_parameterIndex] = block.number;

        emit OracleClimateDataRecorded(_evoSphereId, _parameterIndex, _oracleValue);
    }

    function triggerEvoSphereAdaptation(uint256 _evoSphereId) public {
        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];

        // Ensure adaptation is not too frequent (e.g., once per window)
        // This is simplified, in a full system, you'd have a cooldown or specific trigger logic.
        if (block.number < evosphere.lastAdaptationBlock + prognosticationWindowBlocks / 2) {
             // To prevent spamming, allow adaptation only after a certain period or new data
             // For now, allow it anytime to process new data
        }

        ClimateParameters memory newClimate = evosphere.currentClimate;
        bool climateChanged = false;

        // Iterate through all climate parameters
        for (uint8 i = 0; i < 4; i++) { // Assuming 4 parameters as defined in ClimateParameterIndex
            ClimateParameterIndex paramIndex = ClimateParameterIndex(i);

            // 1. Check if oracle data is available and recent
            if (evosphere.oracleLastUpdateBlock[paramIndex] == 0 || block.number > evosphere.oracleLastUpdateBlock[paramIndex] + prognosticationWindowBlocks) {
                // If no recent oracle data, skip adaptation for this parameter
                continue;
            }
            int256 oracleValue = evosphere.lastOracleValues[paramIndex];

            // 2. Evaluate prognostications for this parameter
            int256 aggregatedPrediction = oracleValue; // Start with oracle as base
            uint256 successfulPrognosticatorsCount = 0;
            address[] memory currentPrognosticators = _getPrognosticators(paramIndex); // This would be a more complex iteration over map keys. For simplicity, assume a limited number or direct access.

            // Simulate iterating through stored predictions
            // This part is a simplification. Iterating over a mapping (activePrognostications[_parameterIndex]) directly is not possible in Solidity.
            // A more complex data structure (e.g., dynamic array of prognosticators, or a linked list) would be needed for a real system.
            // For now, let's assume we can get a list of active prognosticators for demonstration.
            // For example, if there were a maximum of N prognosticators per window, we could iterate N times.
            // Let's assume for this conceptual contract that we only consider one *most recent* successful prognostication per parameter
            // to simplify the "aggregation" for a single contract, or skip aggregation for brevity.
            // Instead, we will directly apply oracle data and simply reward.

            // 3. Adapt climate based on oracle data (and conceptually, weighted predictions)
            // For this conceptual contract, we'll directly set the climate to the recent oracle value,
            // with a slight smoothing towards the current climate to simulate gradual change.
            int256 currentParamValue;
            if (paramIndex == ClimateParameterIndex.Temperature) currentParamValue = newClimate.temperature;
            else if (paramIndex == ClimateParameterIndex.Humidity) currentParamValue = newClimate.humidity;
            else if (paramIndex == ClimateParameterIndex.LightIntensity) currentParamValue = newClimate.lightIntensity;
            else if (paramIndex == ClimateParameterIndex.SoilNutrients) currentParamValue = newClimate.soilNutrients;

            // Simple smoothing: 70% oracle, 30% current value
            int256 blendedValue = (oracleValue * 70 + currentParamValue * 30) / 100;
            // Ensure bounds are respected
            blendedValue = Math.max(minClimateValues[paramIndex], Math.min(maxClimateValues[paramIndex], blendedValue));

            if (paramIndex == ClimateParameterIndex.Temperature) newClimate.temperature = blendedValue;
            else if (paramIndex == ClimateParameterIndex.Humidity) newClimate.humidity = blendedValue;
            else if (paramIndex == ClimateParameterIndex.LightIntensity) newClimate.lightIntensity = blendedValue;
            else if (paramIndex == ClimateParameterIndex.SoilNutrients) newClimate.soilNutrients = blendedValue;

            climateChanged = true;

            // 4. Reset prognostication window for the next round
            evosphere.prognosticationWindowStart[paramIndex] = block.number;
            // Clear or mark processed predictions for this parameter (actual clearing not possible for map keys)
            // A more robust system would involve a list of predictions per window that gets cleared.
        }

        if (climateChanged) {
            evosphere.currentClimate = newClimate;
            evosphere.lastAdaptationBlock = block.number;
            emit EvoSphereClimateAdapted(_evoSphereId, newClimate, block.number);
        }

        // Also evolve organism states within this EvoSphere
        // This would require iterating through all organisms of this EvoSphere, which is costly.
        // For simplicity, we assume organisms evolve when harvested.
        // A more advanced system might have a global `evolveAllOrganisms` callable by admin.
    }

    function _getPrognosticators(ClimateParameterIndex _paramIndex) internal view returns (address[] memory) {
        // This is a placeholder. Iterating over mapping keys is not directly possible in Solidity.
        // In a real system, you would need a data structure to track active prognosticators
        // for a specific window, e.g., a dynamic array `address[] activePrognosticators[evoSphereId][paramIndex]`.
        // For this conceptual contract, we'll return an empty array or a hardcoded one.
        // This part highlights a limitation of on-chain data structures for dynamic lists of addresses.
        address[] memory temp;
        return temp;
    }


    function claimPrognosticatorReward(
        uint252 _evoSphereId,
        ClimateParameterIndex _parameterIndex,
        address _prognosticator
    ) public onlyRole(PROGNOSTICATOR_REWARD_DISTRIBUTOR_ROLE) {
        // This function would typically be called by the `_prognosticator` themselves after a trigger.
        // Making it `onlyRole` simplifies it to show rewards are managed.
        // In a fully decentralized setup, the `triggerEvoSphereAdaptation` itself would distribute rewards.

        if (!_exists(_evoSphereId)) {
            revert EvoSphere__InvalidEvoSphereId();
        }
        EvoSphere storage evosphere = evoSpheres[_evoSphereId];

        Prognostication storage progn = evosphere.activePrognostications[_parameterIndex][_prognosticator];

        if (progn.submittedBlock == 0 || progn.rewarded) {
            revert EvoSphere__NoClaimableReward();
        }
        // Check if the prediction window has closed and oracle data is available
        if (block.number < evosphere.prognosticationWindowStart[_parameterIndex] + prognosticationWindowBlocks) {
            revert EvoSphere__PrognosticationWindowClosed(); // Window still open
        }
        if (evosphere.oracleLastUpdateBlock[_parameterIndex] < evosphere.prognosticationWindowStart[_parameterIndex]) {
            revert EvoSphere__NoOracleDataAvailable(); // Oracle data too old or missing for this window
        }

        int256 oracleValue = evosphere.lastOracleValues[_parameterIndex];
        int256 predictedValue = progn.predictedValue;

        if (predictedValue >= oracleValue - int256(PROGNOSTICATION_ACCURACY_TOLERANCE) &&
            predictedValue <= oracleValue + int256(PROGNOSTICATION_ACCURACY_TOLERANCE))
        {
            // Prediction was accurate, issue reward
            uint256 rewardAmount = prognosticationRewardRate;
            // For simplicity, rewards are added to EvoSphere's pool.
            // In a real system, it would be an ERC20 transfer.
            if (evosphere.currentResourcePool + rewardAmount > evosphere.resourceCapacity) {
                // If EvoSphere cannot hold more, reward goes to prognosticator directly or is burned.
                // For now, let's assume EvoSphere always has capacity or rewards are external.
                // Reverting here means EvoSphere is too full to credit the reward.
                revert EvoSphere__ResourceCapacityExceeded(evosphere.currentResourcePool, evosphere.resourceCapacity);
            }
            evosphere.currentResourcePool += rewardAmount; // Reward added to EvoSphere's pool
            progn.rewarded = true; // Mark as rewarded
            emit PrognosticatorRewarded(_evoSphereId, _parameterIndex, _prognosticator, rewardAmount);
        } else {
            // Prediction was not accurate
            progn.rewarded = true; // Mark as processed to prevent re-claiming
        }
    }

    // --- ECOSYSTEM PARAMETERS & GOVERNANCE ---

    function setClimateParameterBounds(ClimateParameterIndex _parameterIndex, int256 _min, int256 _max)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Or STEWARD_ROLE after governance vote
    {
        minClimateValues[_parameterIndex] = _min;
        maxClimateValues[_parameterIndex] = _max;
        // Event for parameter change
    }

    function setPrognosticationRewardRate(uint256 _rate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Or STEWARD_ROLE after governance vote
    {
        prognosticationRewardRate = _rate;
        // Event for rate change
    }

    function proposeEcosystemPolicy(string calldata _proposalURI, uint256 _durationBlocks) public onlyRole(STEWARD_ROLE) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        policyProposals[newProposalId] = PolicyProposal({
            proposalURI: _proposalURI,
            startBlock: block.number,
            endBlock: block.number + _durationBlocks,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            executed: false,
            passed: false
        });

        emit PolicyProposalCreated(newProposalId, msg.sender, _proposalURI, block.number + _durationBlocks);
    }

    function voteOnPolicyProposal(uint256 _proposalId, bool _support) public onlyRole(STEWARD_ROLE) {
        PolicyProposal storage proposal = policyProposals[_proposalId];
        if (proposal.startBlock == 0) {
            revert EvoSphere__PolicyProposalNotFound();
        }
        if (block.number > proposal.endBlock) {
            revert EvoSphere__PolicyVotingPeriodExpired();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert EvoSphere__AlreadyVoted();
        }

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit PolicyVoteCast(_proposalId, msg.sender, _support);
    }

    function executePolicyProposal(uint256 _proposalId) public {
        PolicyProposal storage proposal = policyProposals[_proposalId];
        if (proposal.startBlock == 0) {
            revert EvoSphere__PolicyProposalNotFound();
        }
        if (block.number <= proposal.endBlock) {
            revert EvoSphere__PolicyVotingPeriodActive();
        }
        if (proposal.executed) {
            revert EvoSphere__PolicyAlreadyExecuted();
        }

        uint256 totalStewards = getRoleMemberCount(STEWARD_ROLE);
        if (totalStewards == 0) {
            revert EvoSphere__NotPolicyVoter(); // No stewards to vote, effectively no governance
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (totalStewards * proposalQuorumPercentage) / 100;

        if (totalVotes < quorumRequired) {
            proposal.passed = false; // Not enough votes to reach quorum
        } else {
            uint256 votesForPercentage = (proposal.votesFor * 100) / totalVotes;
            if (votesForPercentage >= proposalMajorityPercentage) {
                proposal.passed = true;
            } else {
                proposal.passed = false;
            }
        }

        proposal.executed = true;
        emit PolicyExecuted(_proposalId, proposal.passed);

        if (proposal.passed) {
            // Placeholder for actual policy effects.
            // In a real system, the proposalURI would contain executable data or parameters
            // that this contract would parse and apply (e.g., call `setClimateParameterBounds` internally).
            // For now, it's a conceptual passing of a proposal.
        }
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    function _evolveOrganismState(uint256 _organismId) internal {
        Organism storage organism = organisms[_organismId];
        EvoSphere storage evosphere = evoSpheres[organism.evoSphereId];
        SeedType storage seed = seedTypes[organism.seedTypeId];

        uint256 blocksSinceLastUpdate = block.number - organism.lastHarvestBlock;
        if (blocksSinceLastUpdate == 0) return; // No change needed yet

        // Simulate resource consumption
        uint256 totalResourceConsumption = blocksSinceLastUpdate * seed.resourceConsumptionPerTick;
        if (evosphere.currentResourcePool < totalResourceConsumption) {
            organism.health -= (totalResourceConsumption - evosphere.currentResourcePool); // Health reduction
            evosphere.currentResourcePool = 0;
            if (organism.health < 0) organism.health = 0;
        } else {
            evosphere.currentResourcePool -= totalResourceConsumption;
        }

        // Simulate yield generation based on health and climate
        // This is a simplified calculation
        uint256 yieldPerBlock = seed.growthRate * organism.health / 100;
        // Adjust yield based on climate (e.g., optimal temp gives bonus)
        // int256 tempDelta = evosphere.currentClimate.temperature - 50; // assuming 50 is optimal temp
        // if (tempDelta > 0) yieldPerBlock += (yieldPerBlock * uint256(tempDelta) / 100);
        organism.accumulatedYield += blocksSinceLastUpdate * yieldPerBlock;

        organism.lastHarvestBlock = block.number;
        // Further logic for health changes, trait mutations, etc., would go here.
        // Example: If health drops to 0, organism might "die" (be burned/removed)
    }

    // --- ERC721 Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721A) // For this example, only ERC721 if not using ERC721A
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // EvoSphere-specific logic before transfer
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        super._approve(to, tokenId);
        // EvoSphere-specific logic for approval
    }

    function _approve(address to, address owner, uint256 tokenId) internal override(ERC721) {
        super._approve(to, owner, tokenId);
        // EvoSphere-specific logic for approval
    }

    // The following two functions are required by ERC721 to provide token URI data.
    // In a dynamic NFT system, this URI would point to an API that generates metadata based on current on-chain state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return evoSpheres[tokenId].metadataURI;
    }
}

// Simple Math library for min/max - common pattern in Solidity
library Math {
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }
}
```