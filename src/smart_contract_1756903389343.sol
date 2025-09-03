This smart contract, "The Aethelgard Protocol," is designed as a decentralized, self-regulating ecosystem that dynamically adapts to foster long-term community health and value creation. It integrates several advanced concepts:

1.  **Ecosystem Vitality:** An on-chain "health score" derived from various activity metrics and external data.
2.  **Adaptive Resource Allocation:** Treasury funds are dynamically distributed to different pools (development, grants, liquidity, preservation) based on the current Ecosystem Vitality State.
3.  **Soulbound Spheres (SBTs):** Non-transferable tokens representing individual reputation and contribution, with evolving attributes that grant access to features or weighted votes.
4.  **Prophetic Oracle Integration:** Proactive adaptation of protocol parameters based on *probabilistic forecasts* (e.g., future vitality trends, market sentiment) from a specialized oracle network.
5.  **Dynamic & Generative Assets:** ERC721 assets whose on-chain properties can evolve over time, influenced by protocol vitality and owner's reputation.

---

## The Aethelgard Protocol: Outline and Function Summary

**I. Core Infrastructure & Access Control (Initialization and System Management)**
1.  `constructor()`: Initializes the protocol, sets the initial admin roles, and links the Soulbound Sphere and Generative Assets NFT contracts.
2.  `setProtocolOracleAddress()`: Sets the address of the trusted `IPropheticOracle` contract.
3.  `setVitalityThresholds()`: Defines the score ranges that delineate different Ecosystem Vitality states (e.g., Thriving, Stagnant).
4.  `updateAdminRole()`: Manages additional administrative roles beyond the owner, allowing for multi-sig-like control.
5.  `pauseProtocol()`: An emergency function to halt critical operations in case of an exploit or unforeseen issue.
6.  `unpauseProtocol()`: Resumes protocol operations after a pause.

**II. Ecosystem Vitality Management (The "Brain" - Measuring Protocol Health)**
7.  `updateVitalityMetricWeight()`: Adjusts the influence (weight) of specific activity or external metrics on the overall Vitality Score.
8.  `recordActivityMetric()`: Records various on-chain user activities (e.g., votes, contributions, Sphere interactions) that contribute to the Vitality Score.
9.  `updateExternalMetric()`: Allows a trusted oracle or admin to submit off-chain vitality data (e.g., social sentiment analysis, external market health indicators).
10. `calculateCurrentVitalityScore()`: Computes the aggregate Vitality Score based on all tracked metrics and their assigned weights.
11. `getCurrentVitalityState()`: Returns the current Vitality State (e.g., Thriving, Stable, Stagnant, Critical) by comparing the score against predefined thresholds.
12. `triggerStateRecalibration()`: Initiates a comprehensive re-evaluation of the protocol's current state, updating the Vitality Score and triggering adaptive resource allocation.

**III. Adaptive Resource Allocation (The "Heartbeat" - Dynamic Resource Distribution)**
13. `depositFunds()`: Allows users or external contracts to deposit native currency (e.g., ETH) into the protocol's main treasury.
14. `setAllocationStrategy()`: Defines how treasury funds are proportionally distributed to various internal pools (e.g., Development, Community Grants) for each Vitality State.
15. `allocateResourcesByVitality()`: (Internal) Executes the distribution of funds from the main treasury into predefined allocation pools based on the current Vitality State.
16. `requestCommunityGrant()`: Enables community members to propose projects and request funding from the Community Grants pool.
17. `voteOnGrantRequest()`: Allows authorized entities (e.g., Soulbound Sphere holders) to cast votes for or against grant proposals.
18. `finalizeGrantRequest()`: Finalizes a grant request based on the voting outcome and disburses funds to the proposer if approved.
19. `claimAllocatedFunds()`: Allows designated recipients (e.g., core development teams, approved grant recipients) to claim their entitled share from specific allocation pools.

**IV. Reputation & Identity (Soulbound Spheres - SBTs for Contribution & Access)**
20. `mintSphere()`: Mints a non-transferable "Soulbound Sphere" NFT to an address, establishing their initial standing and identity within the ecosystem.
21. `updateSphereAttributes()`: Dynamically adjusts and evolves the attributes (e.g., contribution score, engagement level) of a user's Sphere based on their ongoing activities and interactions.
22. `getSphereDetails()`: Retrieves the current detailed attributes and status of a specific Soulbound Sphere.
23. `burnSphere()`: (High-governance/Rare) Allows for the permanent burning of a Sphere, typically reserved for severe protocol violations or collective community decision.
24. `checkSphereAccessCapability()`: Determines if a Sphere holder's attributes meet specific thresholds required for accessing privileged features or exclusive parts of the ecosystem.

**V. Prophetic Oracle Integration (The "Vision" - Future State Adaptation)**
25. `requestPropheticForecast()`: Initiates a request to the `IPropheticOracle` for a specific type of predictive forecast (e.g., future market volatility, impending community sentiment shifts).
26. `receivePropheticForecast()`: A callback function, exclusively callable by the `IPropheticOracle`, to deliver the requested forecast data back to the protocol.
27. `adjustParametersBasedOnForecast()`: (Internal) Proactively modifies internal protocol parameters (e.g., future resource allocation weights, Sphere attribute decay rates) in anticipation of future conditions, based on received forecasts.

**VI. Dynamic & Generative Elements (The "Evolution" - Evolving Digital Assets)**
28. `createGenerativeAssetClass()`: Defines a new class of digital assets whose properties are not static but can dynamically evolve over time.
29. `mintGenerativeAsset()`: Mints an instance of a generative asset to a user, with its initial state potentially influenced by the protocol's vitality or the owner's Sphere attributes.
30. `evolveGenerativeAsset()`: Triggers an evolution step for a specific generative asset, updating its on-chain properties and potentially its visual representation, based on factors like protocol vitality, owner's Sphere attributes, or specific events.
31. `getGenerativeAssetMetadataURI()`: Provides the current, potentially dynamic, metadata URI for a generative asset, which an off-chain resolver can use to render its latest state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary: The Aethelgard Protocol ---
// The Aethelgard Protocol is a decentralized, self-regulating ecosystem designed to foster long-term community health and value creation.
// It achieves this through adaptive resource allocation, reputation-based access, and dynamic incentive structures.
// The protocol dynamically responds to its "Ecosystem Vitality" score, derived from both on-chain and off-chain metrics,
// and proactively adapts its parameters based on "Prophetic Forecasts" from a specialized oracle.

// I. Core Infrastructure & Access Control (Initialization and System Management)
// 1. constructor(): Initializes the protocol, sets the initial admin roles.
// 2. setProtocolOracleAddress(): Sets the address of the trusted Prophetic Oracle.
// 3. setVitalityThresholds(): Defines the score ranges for different Ecosystem Vitality states.
// 4. updateAdminRole(): Manages administrative roles (add/remove) for multi-sig like functionality.
// 5. pauseProtocol(): Emergency pause function for critical situations.
// 6. unpauseProtocol(): Resumes protocol operations.

// II. Ecosystem Vitality Management (The "Brain" - Measuring Protocol Health)
// 7. updateVitalityMetricWeight(): Adjusts the influence of specific metrics on the overall Vitality Score.
// 8. recordActivityMetric(): Records various on-chain user activities that contribute to Vitality.
// 9. updateExternalMetric(): Allows a trusted oracle/admin to submit off-chain vitality data.
// 10. calculateCurrentVitalityScore(): Computes the aggregate Vitality Score based on all metrics and weights.
// 11. getCurrentVitalityState(): Returns the current Vitality State (e.g., Thriving, Stagnant) based on the score.
// 12. triggerStateRecalibration(): Initiates a re-evaluation of the protocol's state and resource allocation.

// III. Adaptive Resource Allocation (The "Heartbeat" - Dynamic Resource Distribution)
// 13. depositFunds(): Allows users or external contracts to fund the protocol's treasury.
// 14. setAllocationStrategy(): Defines how treasury funds are distributed across pools for each Vitality State.
// 15. allocateResourcesByVitality(): (Internal) Distributes funds to various pools based on the current Vitality State.
// 16. requestCommunityGrant(): Allows users to propose and request funding for community initiatives.
// 17. voteOnGrantRequest(): Enables authorized entities (e.g., Sphere holders) to vote on grant proposals.
// 18. finalizeGrantRequest(): Finalizes a grant request based on voting outcome and disburses funds.
// 19. claimAllocatedFunds(): Allows designated recipients (e.g., development teams, grant recipients) to claim their share from pools.

// IV. Reputation & Identity (Soulbound Spheres - SBTs for Contribution & Access)
// 20. mintSphere(): Mints a non-transferable "Sphere" SBT to an address, representing initial community standing.
// 21. updateSphereAttributes(): Dynamically adjusts attributes of a user's Sphere based on their ongoing contributions and activity.
// 22. getSphereDetails(): Retrieves the detailed attributes and status of a specific Sphere.
// 23. burnSphere(): (High-governance/Rare) Allows for the burning of a Sphere due to severe protocol violations or community consensus.
// 24. checkSphereAccessCapability(): Determines if a Sphere meets specific attribute thresholds for privileged access or features.

// V. Prophetic Oracle Integration (The "Vision" - Future State Adaptation)
// 25. requestPropheticForecast(): Requests a predictive forecast from the registered Prophetic Oracle (e.g., future vitality trend).
// 26. receivePropheticForecast(): Callback function for the oracle to deliver the requested forecast data to the protocol.
// 27. adjustParametersBasedOnForecast(): Proactively modifies internal protocol parameters (e.g., future allocation weights, Sphere decay rates) based on received forecasts.

// VI. Dynamic & Generative Elements (The "Evolution" - Evolving Digital Assets)
// 28. createGenerativeAssetClass(): Defines a new class of digital assets whose properties can dynamically evolve.
// 29. mintGenerativeAsset(): Mints a generative asset to a user, whose initial state might be tied to their Sphere.
// 30. evolveGenerativeAsset(): Triggers an evolution step for a generative asset, updating its on-chain properties based on various factors (e.g., protocol vitality, owner's Sphere attributes).
// 31. getGenerativeAssetMetadataURI(): Provides the current metadata URI for a generative asset, which may point to a dynamic resolver.

// Note: This contract assumes the existence of an external `IPropheticOracle` interface/contract for oracle interactions.
// For brevity, `ERC721` base implementation is included for `SoulboundSphere` and `GenerativeAsset`.

// --- End of Outline and Function Summary ---


// Interface for the Prophetic Oracle contract
interface IPropheticOracle {
    function requestForecast(uint256 forecastType, bytes memory parameters) external returns (bytes32 requestId);
    // This function will be called by the oracle itself to deliver the forecast
    function fulfillForecast(bytes32 requestId, int256 forecastValue, bytes memory context) external; 
}

// Forward declarations of helper ERC721 contracts
contract SoulboundSphere is ERC721, Ownable {
    constructor(address initialOwner) ERC721("Aethelgard Soulbound Sphere", "AETHEL_SBT") Ownable(initialOwner) {}
    function mint(address to) external onlyOwner returns (uint256);
    function burn(uint256 tokenId) external onlyOwner;
}

contract GenerativeAssets is ERC721, Ownable {
    constructor(address initialOwner) ERC721("Aethelgard Generative Asset", "AETHEL_GEN") Ownable(initialOwner) {}
    function mint(address to, uint256 tokenId) external onlyOwner;
    function burn(uint256 tokenId) external onlyOwner;
}


contract AethelgardProtocol is Ownable, Pausable, IERC721Receiver {
    using Counters for Counters.Counter;

    // --- Enums and Structs ---

    enum VitalityState { Thriving, Stable, Stagnant, Critical }
    enum ActivityType { ProposalVote, ResourceContribution, DisputeResolution, SphereInteraction, GenerativeAssetEvolution, ExternalMetricOffset }
    enum AllocationPool { DevelopmentPool, CommunityGrants, LiquidityIncentives, PreservationVault } // Removed 'Other' for simplicity in iteration

    struct VitalityMetric {
        uint255 value; // The current value of the metric
        uint40 lastUpdated; // Using smaller types to optimize gas
        uint16 weight; // How much this metric contributes to the overall vitality score
    }

    struct SphereAttributes {
        uint128 contributionScore; // Reflects active engagement and value-add
        uint128 engagementLevel;   // Reflects participation frequency
        uint128 loyaltyScore;      // Reflects long-term commitment
        uint40 lastUpdated;
    }

    struct GrantRequest {
        uint256 id;
        address proposer;
        uint256 amount;
        string description;
        bool finalized;
        bool approved;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // To prevent double voting
    }

    struct GenerativeAssetDetails {
        string name;
        string symbol;
        string baseURI; // Base URI for metadata, can be dynamically resolved
        string[] evolvableTraits; // Names of traits that can change
        Counters.Counter assetCounter; // Counter for token IDs within this class
    }

    struct GenerativeAssetInstance {
        uint256 classId; // Refers to the GenerativeAssetDetails
        uint32 generation; // How many times it has evolved
        mapping(string => string) currentTraits; // Current state of its evolvable traits (key: trait name, value: trait value)
        address owner; // Cached owner for quick lookup
    }

    // --- State Variables ---

    // I. Core Infrastructure & Access Control
    mapping(address => bool) public admins; // Additional admins beyond owner
    IPropheticOracle public propheticOracle;

    // II. Ecosystem Vitality Management
    mapping(uint256 => VitalityMetric) public vitalityMetrics; // Key: enum ActivityType as uint or custom external metric ID
    mapping(VitalityState => uint256) public vitalityStateThresholds; // min score for each state
    uint256 public totalVitalityScore;
    uint40 public lastVitalityRecalculation;

    // III. Adaptive Resource Allocation
    mapping(AllocationPool => uint256) public allocatedPoolBalances; // Current balance in each pool
    mapping(VitalityState => mapping(AllocationPool => uint256)) public allocationStrategy; // Percentage (out of 10000)
    Counters.Counter private _grantRequestIdCounter;
    mapping(uint256 => GrantRequest) public grantRequests;

    // IV. Reputation & Identity (Soulbound Spheres)
    SoulboundSphere public soulboundSphereNFT; // ERC721 for Spheres
    mapping(uint256 => SphereAttributes) public sphereAttributeData; // Key: tokenId of the Sphere

    // V. Prophetic Oracle Integration
    mapping(bytes32 => uint256) public pendingForecastRequests; // requestId -> forecastType
    mapping(uint256 => int256) public lastForecastValues; // forecastType -> last received value (for recent forecast)

    // VI. Dynamic & Generative Elements
    Counters.Counter private _generativeAssetClassIdCounter;
    mapping(uint256 => GenerativeAssetDetails) public generativeAssetClasses; // classId -> details
    mapping(uint256 => GenerativeAssetInstance) public generativeAssetInstances; // ERC721 tokenId -> instance details
    GenerativeAssets public generativeAssetsNFT; // ERC721 for Generative Assets

    // --- Events ---
    event AdminRoleUpdated(address indexed account, bool granted);
    event ProtocolOracleAddressUpdated(address indexed newAddress);
    event VitalityThresholdsUpdated(VitalityState indexed state, uint256 minScore);
    event VitalityMetricWeightUpdated(uint256 indexed metricType, uint256 newWeight); // Using uint256 to cover ActivityType and custom IDs
    event ActivityMetricRecorded(ActivityType indexed activityType, address indexed participant, uint256 value);
    event ExternalMetricUpdated(uint256 indexed metricId, uint256 value);
    event VitalityScoreCalculated(uint256 newScore, VitalityState newState);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event AllocationStrategyUpdated(VitalityState indexed state, AllocationPool indexed pool, uint256 percentage);
    event ResourcesAllocated(VitalityState indexed state, uint256 totalAllocated);
    event GrantRequested(uint256 indexed grantId, address indexed proposer, uint256 amount, string description);
    event GrantVoted(uint256 indexed grantId, address indexed voter, bool vote);
    event GrantFinalized(uint256 indexed grantId, bool approved, uint256 disbursedAmount);
    event FundsClaimed(AllocationPool indexed pool, address indexed recipient, uint256 amount);
    event SphereMinted(address indexed to, uint256 indexed tokenId, uint256 initialContributionScore);
    event SphereAttributesUpdated(uint256 indexed tokenId, uint256 contributionScore, uint256 engagementLevel, uint256 loyaltyScore);
    event SphereBurned(uint256 indexed tokenId);
    event PropheticForecastRequested(bytes32 indexed requestId, uint256 forecastType, bytes parameters);
    event PropheticForecastReceived(bytes32 indexed requestId, uint256 forecastType, int256 forecastValue);
    event ProtocolParametersAdjusted(uint256 indexed forecastType, int256 forecastValue);
    event GenerativeAssetClassCreated(uint256 indexed classId, string name, string symbol);
    event GenerativeAssetMinted(uint256 indexed tokenId, uint256 indexed classId, address indexed to);
    event GenerativeAssetEvolved(uint256 indexed tokenId, uint32 newGeneration, string[] updatedTraitKeys);
    event GenerativeAssetTraitsUpdated(uint256 indexed tokenId, string indexed traitKey, string traitValue);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(owner() == _msgSender() || admins[_msgSender()], "Aethelgard: Caller is not an admin");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle, address _sphereNFTAddress, address _generativeNFTAddress) Ownable(msg.sender) Pausable(false) {
        propheticOracle = IPropheticOracle(_initialOracle);
        admins[msg.sender] = true;

        // Initialize default vitality state thresholds (example values)
        vitalityStateThresholds[VitalityState.Thriving] = 80;
        vitalityStateThresholds[VitalityState.Stable] = 50;
        vitalityStateThresholds[VitalityState.Stagnant] = 20;
        vitalityStateThresholds[VitalityState.Critical] = 0; // Below 20 is critical

        // Initialize Sphere and Generative Asset NFT contracts.
        // The deployer of AethelgardProtocol should also be the owner of these ERC721s
        // and subsequently transfer their ownership to this AethelgardProtocol contract address.
        soulboundSphereNFT = SoulboundSphere(_sphereNFTAddress);
        generativeAssetsNFT = GenerativeAssets(_generativeNFTAddress);
    }

    // --- I. Core Infrastructure & Access Control ---

    // 1. (Constructor handled above)

    // 2. Set the address of the Prophetic Oracle
    function setProtocolOracleAddress(address _oracleAddress) external onlyAdmin {
        require(_oracleAddress != address(0), "Aethelgard: Invalid oracle address");
        propheticOracle = IPropheticOracle(_oracleAddress);
        emit ProtocolOracleAddressUpdated(_oracleAddress);
    }

    // 3. Define the score ranges for different Ecosystem Vitality states
    function setVitalityThresholds(VitalityState _state, uint256 _minScore) external onlyAdmin {
        vitalityStateThresholds[_state] = _minScore;
        emit VitalityThresholdsUpdated(_state, _minScore);
    }

    // 4. Manages administrative roles
    function updateAdminRole(address _account, bool _granted) external onlyAdmin {
        require(_account != address(0), "Aethelgard: Invalid account address");
        admins[_account] = _granted;
        emit AdminRoleUpdated(_account, _granted);
    }

    // 5. Emergency pause function
    function pauseProtocol() external onlyAdmin {
        _pause();
    }

    // 6. Resumes protocol operations
    function unpauseProtocol() external onlyAdmin {
        _unpause();
    }

    // --- II. Ecosystem Vitality Management ---

    // 7. Adjusts the influence of specific metrics on the overall Vitality Score
    function updateVitalityMetricWeight(uint256 _metricId, uint16 _newWeight) external onlyAdmin {
        vitalityMetrics[_metricId].weight = _newWeight;
        emit VitalityMetricWeightUpdated(_metricId, _newWeight);
    }

    // 8. Records various on-chain user activities that contribute to Vitality
    // Can be called by other internal functions or whitelisted external contracts.
    function recordActivityMetric(ActivityType _activityType, address _participant, uint255 _value) internal {
        VitalityMetric storage metric = vitalityMetrics[uint256(_activityType)];
        metric.value += _value; // Accumulate activity score
        metric.lastUpdated = uint40(block.timestamp);
        emit ActivityMetricRecorded(_activityType, _participant, _value);
    }

    // 9. Allows a trusted oracle/admin to submit off-chain vitality data
    function updateExternalMetric(uint256 _metricId, uint255 _value) external onlyAdmin {
        // Using _metricId for custom external metrics (e.g., beyond ActivityType enum range)
        require(_metricId > uint256(ActivityType.ExternalMetricOffset), "Aethelgard: Use recordActivityMetric for internal types.");
        VitalityMetric storage metric = vitalityMetrics[_metricId];
        metric.value = _value;
        metric.lastUpdated = uint40(block.timestamp);
        emit ExternalMetricUpdated(_metricId, _value);
    }

    // 10. Computes the aggregate Vitality Score based on all metrics and weights
    function calculateCurrentVitalityScore() public view returns (uint256 score) {
        uint256 weightedSum = 0;
        uint256 totalWeight = 0;

        // Iterate through all possible ActivityTypes
        for (uint256 i = 0; i < uint256(ActivityType.ExternalMetricOffset) + 1; i++) {
            VitalityMetric storage metric = vitalityMetrics[i];
            if (metric.weight > 0) {
                weightedSum += metric.value * metric.weight;
                totalWeight += metric.weight;
            }
        }
        // Potentially iterate through a predefined range of external metric IDs too, if known.

        if (totalWeight == 0) return 0; // Prevent division by zero
        return weightedSum / totalWeight; // Returns an average score
    }

    // 11. Returns the current Vitality State
    function getCurrentVitalityState() public view returns (VitalityState) {
        uint256 currentScore = calculateCurrentVitalityScore();

        if (currentScore >= vitalityStateThresholds[VitalityState.Thriving]) {
            return VitalityState.Thriving;
        } else if (currentScore >= vitalityStateThresholds[VitalityState.Stable]) {
            return VitalityState.Stable;
        } else if (currentScore >= vitalityStateThresholds[VitalityState.Stagnant]) {
            return VitalityState.Stagnant;
        } else {
            return VitalityState.Critical;
        }
    }

    // 12. Initiates a re-evaluation of the protocol's state and resource allocation
    function triggerStateRecalibration() public whenNotPaused {
        uint256 newScore = calculateCurrentVitalityScore();
        VitalityState newState = getCurrentVitalityState();
        totalVitalityScore = newScore; // Update the state variable
        lastVitalityRecalculation = uint40(block.timestamp);

        _allocateResourcesByVitality(newState); // Trigger resource allocation
        emit VitalityScoreCalculated(newScore, newState);
    }

    // --- III. Adaptive Resource Allocation ---

    // 13. Allows users or external contracts to fund the protocol's treasury
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function depositFunds() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    // 14. Defines how treasury funds are distributed across pools for each Vitality State
    // _percentages are represented as parts per 10000 (e.g., 2500 for 25%)
    function setAllocationStrategy(VitalityState _state, AllocationPool _pool, uint256 _percentage) external onlyAdmin {
        require(_percentage <= 10000, "Aethelgard: Percentage exceeds 100%");
        allocationStrategy[_state][_pool] = _percentage;
        emit AllocationStrategyUpdated(_state, _pool, _percentage);
    }

    // 15. Internal function to distribute funds to various pools based on the current Vitality State
    function _allocateResourcesByVitality(VitalityState _state) internal {
        uint256 totalAvailable = address(this).balance;
        uint256 totalAllocated = 0;

        // Iterate through all possible AllocationPools
        for (uint256 i = 0; i < uint256(AllocationPool.PreservationVault) + 1; i++) {
            AllocationPool currentPool = AllocationPool(i);
            uint256 percentage = allocationStrategy[_state][currentPool];
            if (percentage > 0) {
                uint256 amountToAllocate = (totalAvailable * percentage) / 10000;
                if (amountToAllocate > 0) {
                    allocatedPoolBalances[currentPool] += amountToAllocate;
                    totalAllocated += amountToAllocate;
                }
            }
        }
        emit ResourcesAllocated(_state, totalAllocated);
    }

    // 16. Allows users to propose and request funding for community initiatives
    function requestCommunityGrant(uint256 _amount, string memory _description) external whenNotPaused {
        _grantRequestIdCounter.increment();
        uint256 newId = _grantRequestIdCounter.current();
        grantRequests[newId] = GrantRequest({
            id: newId,
            proposer: msg.sender,
            amount: _amount,
            description: _description,
            finalized: false,
            approved: false,
            yesVotes: 0,
            noVotes: 0
        });
        emit GrantRequested(newId, msg.sender, _amount, _description);
    }

    // 17. Enables authorized entities (e.g., Sphere holders) to vote on grant proposals
    function voteOnGrantRequest(uint256 _grantId, bool _vote) external whenNotPaused {
        GrantRequest storage grant = grantRequests[_grantId];
        require(grant.proposer != address(0), "Aethelgard: Grant does not exist");
        require(!grant.finalized, "Aethelgard: Grant already finalized");
        require(!grant.hasVoted[msg.sender], "Aethelgard: Already voted on this grant");

        // Example: Only Sphere holders can vote
        require(soulboundSphereNFT.balanceOf(msg.sender) > 0, "Aethelgard: Only Sphere holders can vote");

        grant.hasVoted[msg.sender] = true;
        if (_vote) {
            grant.yesVotes++;
        } else {
            grant.noVotes++;
        }
        emit GrantVoted(_grantId, msg.sender, _vote);
        recordActivityMetric(ActivityType.ProposalVote, msg.sender, 1);
    }

    // 18. Finalizes a grant request based on voting outcome and disburses funds
    function finalizeGrantRequest(uint256 _grantId) external onlyAdmin whenNotPaused {
        GrantRequest storage grant = grantRequests[_grantId];
        require(grant.proposer != address(0), "Aethelgard: Grant does not exist");
        require(!grant.finalized, "Aethelgard: Grant already finalized");
        require(grant.yesVotes + grant.noVotes > 0, "Aethelgard: No votes cast yet"); // Ensure some votes exist

        grant.finalized = true;
        if (grant.yesVotes > grant.noVotes) {
            grant.approved = true;
            require(allocatedPoolBalances[AllocationPool.CommunityGrants] >= grant.amount, "Aethelgard: Insufficient funds in Community Grants pool");
            allocatedPoolBalances[AllocationPool.CommunityGrants] -= grant.amount;
            payable(grant.proposer).transfer(grant.amount);
            emit GrantFinalized(_grantId, true, grant.amount);
            recordActivityMetric(ActivityType.ResourceContribution, grant.proposer, grant.amount);
        } else {
            emit GrantFinalized(_grantId, false, 0);
        }
    }

    // 19. Allows designated recipients to claim their share from pools
    function claimAllocatedFunds(AllocationPool _pool, address _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        require(_recipient != address(0), "Aethelgard: Invalid recipient");
        require(allocatedPoolBalances[_pool] >= _amount, "Aethelgard: Insufficient funds in pool");

        allocatedPoolBalances[_pool] -= _amount;
        payable(_recipient).transfer(_amount);
        emit FundsClaimed(_pool, _recipient, _amount);
    }

    // --- IV. Reputation & Identity (Soulbound Spheres) ---

    // 20. Mints a non-transferable "Sphere" SBT to an address
    function mintSphere(address _to, uint128 _initialContributionScore) external onlyAdmin whenNotPaused returns (uint256 tokenId) {
        require(_to != address(0), "Aethelgard: Invalid recipient");
        tokenId = soulboundSphereNFT.mint(_to);
        sphereAttributeData[tokenId] = SphereAttributes({
            contributionScore: _initialContributionScore,
            engagementLevel: 0,
            loyaltyScore: 0,
            lastUpdated: uint40(block.timestamp)
        });
        emit SphereMinted(_to, tokenId, _initialContributionScore);
        recordActivityMetric(ActivityType.SphereInteraction, _to, 1);
    }

    // 21. Dynamically adjusts attributes of a user's Sphere based on their ongoing contributions and activity
    function updateSphereAttributes(uint256 _tokenId, uint128 _contributionDelta, uint128 _engagementDelta, uint128 _loyaltyDelta) external onlyAdmin whenNotPaused {
        // This function is callable by admin for direct adjustments, or could be internal
        // and triggered by other protocol actions.
        SphereAttributes storage attributes = sphereAttributeData[_tokenId];
        require(attributes.lastUpdated != 0, "Aethelgard: Sphere does not exist");

        attributes.contributionScore += _contributionDelta;
        attributes.engagementLevel += _engagementDelta;
        attributes.loyaltyScore += _loyaltyDelta;
        attributes.lastUpdated = uint40(block.timestamp);
        emit SphereAttributesUpdated(_tokenId, attributes.contributionScore, attributes.engagementLevel, attributes.loyaltyScore);

        recordActivityMetric(ActivityType.SphereInteraction, soulboundSphereNFT.ownerOf(_tokenId), 1);
    }

    // 22. Retrieves the detailed attributes and status of a specific Sphere
    function getSphereDetails(uint256 _tokenId) external view returns (SphereAttributes memory) {
        return sphereAttributeData[_tokenId];
    }

    // 23. (High-governance/Rare) Allows for the burning of a Sphere
    function burnSphere(uint256 _tokenId) external onlyAdmin whenNotPaused {
        require(sphereAttributeData[_tokenId].lastUpdated != 0, "Aethelgard: Sphere does not exist");
        address ownerOfSphere = soulboundSphereNFT.ownerOf(_tokenId);
        soulboundSphereNFT.burn(_tokenId);
        delete sphereAttributeData[_tokenId];
        emit SphereBurned(_tokenId);
        recordActivityMetric(ActivityType.DisputeResolution, ownerOfSphere, 10); // Log as a resolution activity
    }

    // 24. Determines if a Sphere meets specific attribute thresholds for privileged access or features
    function checkSphereAccessCapability(uint256 _tokenId, uint128 _minContribution, uint128 _minEngagement, uint128 _minLoyalty) external view returns (bool) {
        SphereAttributes storage attributes = sphereAttributeData[_tokenId];
        if (attributes.lastUpdated == 0) return false; // Sphere does not exist

        return attributes.contributionScore >= _minContribution &&
               attributes.engagementLevel >= _minEngagement &&
               attributes.loyaltyScore >= _minLoyalty;
    }

    // --- V. Prophetic Oracle Integration ---

    // 25. Requests a predictive forecast from the registered Prophetic Oracle
    function requestPropheticForecast(uint256 _forecastType, bytes memory _parameters) external onlyAdmin whenNotPaused returns (bytes32 requestId) {
        require(address(propheticOracle) != address(0), "Aethelgard: Oracle not set");
        requestId = propheticOracle.requestForecast(_forecastType, _parameters);
        pendingForecastRequests[requestId] = _forecastType;
        emit PropheticForecastRequested(requestId, _forecastType, _parameters);
    }

    // 26. Callback function for the oracle to deliver the requested forecast data
    function receivePropheticForecast(bytes32 _requestId, int256 _forecastValue, bytes memory _context) external {
        require(msg.sender == address(propheticOracle), "Aethelgard: Only the prophetic oracle can call this function");
        uint256 forecastType = pendingForecastRequests[_requestId];
        require(forecastType != 0, "Aethelgard: Unknown or fulfilled request ID");

        delete pendingForecastRequests[_requestId]; // Mark as fulfilled
        lastForecastValues[forecastType] = _forecastValue;

        _adjustParametersBasedOnForecast(forecastType, _forecastValue, _context); // Trigger parameter adjustment
        emit PropheticForecastReceived(_requestId, forecastType, _forecastValue);
    }

    // 27. Proactively modifies internal protocol parameters based on received forecasts
    function _adjustParametersBasedOnForecast(uint256 _forecastType, int256 _forecastValue, bytes memory _context) internal {
        // Example: If forecastType is 1 ("FutureVitalityTrend")
        if (_forecastType == 1) {
            if (_forecastValue < 0) { // Forecasted decline in vitality
                // Increase allocation to PreservationVault for Stagnant/Critical states
                allocationStrategy[VitalityState.Stagnant][AllocationPool.PreservationVault] = 5000; // 50%
                allocationStrategy[VitalityState.Critical][AllocationPool.PreservationVault] = 8000; // 80%
                // Potentially adjust Sphere attribute decay rates or incentive structures to counter decline
            } else if (_forecastValue > 0) { // Forecasted increase in vitality
                // Shift allocation more towards Development and Community Grants for Thriving state
                allocationStrategy[VitalityState.Thriving][AllocationPool.DevelopmentPool] = 4000;
                allocationStrategy[VitalityState.Thriving][AllocationPool.CommunityGrants] = 3000;
            }
            emit ProtocolParametersAdjusted(_forecastType, _forecastValue);
        }
        // Further complex logic for other forecast types and parameters based on `_context` (e.g., specific market data)
    }

    // --- VI. Dynamic & Generative Elements ---

    // 28. Defines a new class of digital assets whose properties can dynamically evolve
    function createGenerativeAssetClass(string memory _name, string memory _symbol, string memory _baseURI, string[] memory _evolvableTraits) external onlyAdmin whenNotPaused returns (uint256 classId) {
        _generativeAssetClassIdCounter.increment();
        classId = _generativeAssetClassIdCounter.current();
        generativeAssetClasses[classId] = GenerativeAssetDetails({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            evolvableTraits: _evolvableTraits,
            assetCounter: Counters.new()
        });
        emit GenerativeAssetClassCreated(classId, _name, _symbol);
    }

    // 29. Mints a generative asset to a user, whose initial state might be tied to their Sphere
    function mintGenerativeAsset(
        uint256 _classId,
        address _to,
        string[] memory _initialTraitKeys,
        string[] memory _initialTraitValues
    ) external onlyAdmin whenNotPaused returns (uint256 tokenId) {
        require(_to != address(0), "Aethelgard: Invalid recipient");
        GenerativeAssetDetails storage assetClass = generativeAssetClasses[_classId];
        require(bytes(assetClass.name).length > 0, "Aethelgard: Generative asset class not found");
        require(_initialTraitKeys.length == _initialTraitValues.length, "Aethelgard: Trait key and value arrays must match");

        assetClass.assetCounter.increment();
        tokenId = assetClass.assetCounter.current();

        generativeAssetsNFT.mint(_to, tokenId);

        GenerativeAssetInstance storage newInstance = generativeAssetInstances[tokenId];
        newInstance.classId = _classId;
        newInstance.generation = 0;
        newInstance.owner = _to;

        // Populate initial traits
        for (uint256 i = 0; i < _initialTraitKeys.length; i++) {
            newInstance.currentTraits[_initialTraitKeys[i]] = _initialTraitValues[i];
            emit GenerativeAssetTraitsUpdated(tokenId, _initialTraitKeys[i], _initialTraitValues[i]);
        }

        emit GenerativeAssetMinted(tokenId, _classId, _to);
    }

    // 30. Triggers an evolution step for a generative asset
    // This updates its on-chain properties based on various factors.
    function evolveGenerativeAsset(uint256 _tokenId, string[] memory _newTraitKeys, string[] memory _newTraitValues) external whenNotPaused {
        GenerativeAssetInstance storage assetInstance = generativeAssetInstances[_tokenId];
        require(assetInstance.owner == msg.sender, "Aethelgard: Not the owner of the asset");
        GenerativeAssetDetails storage assetClass = generativeAssetClasses[assetInstance.classId];
        require(bytes(assetClass.name).length > 0, "Aethelgard: Asset class not found");
        require(_newTraitKeys.length == _newTraitValues.length, "Aethelgard: Trait key and value arrays must match");

        // Example evolution logic based on current VitalityState:
        VitalityState currentState = getCurrentVitalityState();
        if (currentState == VitalityState.Thriving) {
            // Apply positive evolution
        } else if (currentState == VitalityState.Critical) {
            // Apply degradation or unique 'scar' traits
        }
        // Further logic could depend on owner's Sphere attributes (e.g., loyalty score)

        // Apply new traits
        for (uint256 i = 0; i < _newTraitKeys.length; i++) {
            bool isEvolvable = false;
            for(uint256 j = 0; j < assetClass.evolvableTraits.length; j++) {
                if (keccak256(abi.encodePacked(assetClass.evolvableTraits[j])) == keccak256(abi.encodePacked(_newTraitKeys[i]))) {
                    isEvolvable = true;
                    break;
                }
            }
            require(isEvolvable, "Aethelgard: Trait is not defined as evolvable for this asset class");
            assetInstance.currentTraits[_newTraitKeys[i]] = _newTraitValues[i];
            emit GenerativeAssetTraitsUpdated(_tokenId, _newTraitKeys[i], _newTraitValues[i]);
        }

        assetInstance.generation++;
        emit GenerativeAssetEvolved(_tokenId, assetInstance.generation, _newTraitKeys);
        recordActivityMetric(ActivityType.GenerativeAssetEvolution, msg.sender, 1);
    }

    // 31. Provides the current metadata URI for a generative asset
    function getGenerativeAssetMetadataURI(uint256 _tokenId) external view returns (string memory) {
        GenerativeAssetInstance storage assetInstance = generativeAssetInstances[_tokenId];
        require(bytes(generativeAssetClasses[assetInstance.classId].name).length > 0, "Aethelgard: Generative asset not found");

        GenerativeAssetDetails storage assetClass = generativeAssetClasses[assetInstance.classId];
        // The baseURI should point to a service that can dynamically generate metadata JSON
        // by taking the token ID, generation, and potentially current trait data.
        // For simplicity, we append token ID and generation. A real system would pass traits.
        return string(abi.encodePacked(
            assetClass.baseURI,
            Strings.toString(_tokenId),
            "/generation/",
            Strings.toString(assetInstance.generation)
            // A real system might encode all traits here, e.g., "/traits/", abi.encodePacked(trait1,trait2)
        ));
    }

    // --- ERC721 Receiver for safety (if this contract ever receives NFTs) ---
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// --- Helper ERC721 Contracts (Simplified for example) ---

// Soulbound Sphere ERC721
contract SoulboundSphere is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(address initialOwner) ERC721("Aethelgard Soulbound Sphere", "AETHEL_SBT") Ownable(initialOwner) {}

    // Only the owner (expected to be AethelgardProtocol) can mint Spheres
    function mint(address to) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        return newItemId;
    }

    // Override to make it non-transferable (soulbound)
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("AETHEL_SBT: Spheres are non-transferable");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AETHEL_SBT: Spheres are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AETHEL_SBT: Spheres are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("AETHEL_SBT: Spheres are non-transferable");
    }

    // Only the owner (expected to be AethelgardProtocol) can burn Spheres
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}

// Generative Assets ERC721
contract GenerativeAssets is ERC721, Ownable {
    constructor(address initialOwner) ERC721("Aethelgard Generative Asset", "AETHEL_GEN") Ownable(initialOwner) {}

    // Only the owner (expected to be AethelgardProtocol) can mint Generative Assets
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    // Only the owner (expected to be AethelgardProtocol) can burn Generative Assets
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
```