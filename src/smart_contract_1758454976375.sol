This smart contract, `ChronosNexus`, introduces a unique ecosystem centered around "ChronosUnit" (CU) NFTs. These NFTs are dynamic, evolving their attributes based on on-chain predictive models, the owner's reputation, and their active participation in a "Predictive Staking" mechanism. The protocol features a deterministic "AI" (simulation) engine that processes time-series user forecasts to generate future predictions, which in turn influence CU evolution and yield distribution.

---

**Contract Name:** `ChronosNexus`

**Core Concept:** A sophisticated, self-evolving ecosystem built around `ChronosUnit` (CU) NFTs. These NFTs dynamically change based on on-chain predictive models, user reputation, and their participation in a unique "Predictive Staking" mechanism. The protocol features a deterministic, time-series "AI" (simulation) engine that processes user-contributed data to generate future predictions, influencing NFT evolution and yield distribution. The "AI" is a set of on-chain, deterministic rules rather than an external ML model.

**Function Categories & Summaries:**

**I. ChronosUnit (Dynamic NFT) Management**
1.  `mintChronosUnit(address to, string memory initialMetadataURI)`: Mints a new ChronosUnit (ERC721 NFT) to a specified address with initial metadata, owned by the contract deployer (or a designated minter).
2.  `burnChronosUnit(uint256 tokenId)`: Burns a ChronosUnit, removing it from circulation. Requires the caller to be the owner or approved.
3.  `_updateUnitAttributes(uint256 tokenId, ChronosUnitAttributes memory newAttributes)`: **(Internal)** Updates a CU's on-chain attributes, designed to be called by internal logic like `evolveChronosUnit`.
4.  `getUnitAttributes(uint256 tokenId) view returns (ChronosUnitAttributes memory)`: Retrieves the current dynamic attributes of a specified ChronosUnit.
5.  `tokenURI(uint256 tokenId) view returns (string memory)`: Overrides ERC721's `tokenURI` to provide a dynamic metadata URI, reflecting the CU's current generation, accuracy score, and owner.
6.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function for transferring a token.
7.  `approve(address to, uint256 tokenId)`: Standard ERC721 function for approving an address to manage a specific token.
8.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function for approving an operator to manage all tokens.
9.  `balanceOf(address owner) view returns (uint256)`: Standard ERC721 function to get the number of tokens an address owns.
10. `ownerOf(uint256 tokenId) view returns (address)`: Standard ERC721 function to get the owner of a token.

**II. Time-Series Prediction Engine**
11. `submitTimeSeriesForecast(uint256 cycleId, int256 forecastValue)`: Allows users to submit their numerical forecast for a specific future prediction cycle. Each user can submit only one forecast per cycle.
12. `processPredictionCycle(uint256 cycleId)`: Initiates the on-chain calculation of the "official" prediction for a given cycle, based on aggregated user forecasts. This deterministic calculation (e.g., a simple average) can be triggered by anyone.
13. `getPredictionResult(uint256 cycleId) view returns (int256 officialPrediction)`: Retrieves the officially calculated prediction for a past or current cycle.
14. `registerActualOutcome(uint256 cycleId, int256 actualValue)`: A privileged function (e.g., by the contract owner or a trusted oracle) to record the true outcome for a past prediction cycle, crucial for evaluating accuracy and reputation.
15. `_updateReputationBasedOnOutcome(uint256 cycleId, int256 actualOutcome)`: **(Internal)** Adjusts user reputation scores based on the accuracy of their forecasts compared to the actual outcome and the official prediction.

**III. Predictive Staking & Yield**
16. `stakeChronosUnit(uint256 tokenId)`: Locks a ChronosUnit into the staking pool, making it eligible for predictive yield.
17. `unstakeChronosUnit(uint256 tokenId)`: Unlocks a previously staked ChronosUnit. Automatically claims any pending yield before unstaking.
18. `claimPredictiveYield(uint256 tokenId)`: Allows a user to publicly claim accrued yield for their staked ChronosUnit.
19. `_claimPredictiveYield(uint256 tokenId)`: **(Internal)** Calculates and accrues yield for a staked ChronosUnit. Yield is adjusted by the unit's performance during prediction cycles and the owner's reputation.
20. `setYieldMultipliers(uint256 _baseMultiplier, uint256 _reputationMultiplier, uint256 _predictionAccuracyMultiplier)`: Privileged function (e.g., by owner or DAO) to adjust parameters influencing yield calculation.

**IV. Reputation & Evolution System**
21. `_updateUserReputation(address user, int256 change)`: **(Internal)** Adjusts a user's reputation score based on their activities (e.g., accurate forecasts, participation).
22. `evolveChronosUnit(uint256 tokenId)`: Triggers an evolution of a ChronosUnit. Its attributes change (e.g., generation increases) based on its accumulated evolution progress, which is boosted by successful staking and accurate predictions.
23. `getUserReputation(address user) view returns (uint256)`: Retrieves the current reputation score of a user.
24. `getUnitEvolutionProgress(uint256 tokenId) view returns (uint256)`: Shows how close a ChronosUnit is to its next evolution stage by returning its current evolution progress score.

**V. Governance & System Maintenance**
25. `proposeSystemParameterChange(bytes32 parameterName, bytes memory newValue)`: Allows users with sufficient reputation to propose changes to system parameters (e.g., yield rates, quorum percentage).
26. `voteOnProposal(uint256 proposalId, bool support)`: Allows eligible users (based on reputation) to vote on active proposals. Voting power is proportional to reputation.
27. `executeProposal(uint256 proposalId)`: Executes a successfully passed proposal after its voting period has ended and quorum requirements are met.
28. `getProposal(uint256 proposalId) view returns (...)`: Retrieves a proposal's details.
29. `getPredictionCycleDetails(uint256 cycleId) view returns (...)`: Helper getter to retrieve comprehensive details about a specific prediction cycle.
30. `getUnitStakingStatus(uint256 tokenId) view returns (bool, uint256)`: Helper getter to check if a unit is staked and its `stakedCycleId`.
31. `getUnitAccruedYield(uint256 tokenId) view returns (uint256)`: Helper getter to retrieve the current accrued yield for a specific unit.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Define custom errors for better debugging and gas efficiency
error InvalidTokenId();
error NotOwnerOrApproved();
error TokenNotStaked();
error TokenAlreadyStaked();
error NoYieldToClaim();
error ForecastAlreadySubmitted();
error PredictionCycleNotProcessed();
error PredictionOutcomeNotRegistered();
error InvalidCycleId();
error NoForecastsSubmitted();
error UnauthorizedAction();
error InsufficientReputation();
error ProposalNotFound();
error AlreadyVoted();
error CannotVoteOnEndedProposal();
error ProposalNotExecutable();
error TransferFailed(); // Added for potential yield token transfer failure

/**
 * @title ChronosNexus
 * @dev A self-evolving, dynamic, and AI-augmented NFT ecosystem with on-chain reputation and predictive yield.
 *      ChronosUnits (CUs) are dynamic NFTs whose attributes evolve based on their owner's reputation,
 *      their participation in a predictive staking mechanism, and the accuracy of on-chain predictions.
 *      The protocol features a deterministic "AI" (simulation) engine that processes time-series
 *      user forecasts to generate official predictions, which in turn influence CU evolution and yield.
 *      The "AI" is a set of on-chain, deterministic rules rather than an external ML model.
 */
contract ChronosNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Data Structures ---

    /**
     * @dev Struct to hold the dynamic attributes of a ChronosUnit NFT.
     */
    struct ChronosUnitAttributes {
        uint256 generation; // How many times it has evolved, impacting rarity/utility
        uint256 predictionAccuracyScore; // Aggregated score based on past staking performance and prediction accuracy
        uint256 evolutionProgress; // Progress towards the next evolution stage
        uint256 lastEvolutionCycle; // The cycle ID when the unit last evolved
        uint256 stakedCycleId; // The cycle ID when the unit was last staked (0 if not staked)
        uint256 lastClaimCycleId; // The last cycle ID for which yield was claimed
    }

    /**
     * @dev Struct to store data for a specific prediction cycle.
     */
    struct PredictionCycle {
        bool processed; // True if the official prediction has been calculated
        bool outcomeRegistered; // True if the actual outcome has been registered
        int256 officialPrediction;
        int256 actualOutcome; // The true value observed for this cycle
        uint256 totalForecasts; // Number of forecasts submitted by users
        int256 aggregatedForecastSum; // Sum of all submitted forecasts for average calculation
        mapping(address => bool) hasForecasted; // To prevent multiple forecasts per user per cycle
    }

    /**
     * @dev Struct to store an individual user's forecast for a cycle.
     */
    struct UserForecast {
        address user;
        int256 forecastValue;
    }

    /**
     * @dev Struct to define a governance proposal for system parameter changes.
     */
    struct Proposal {
        bytes32 parameterName; // Identifier for the parameter to be changed (e.g., keccak256("baseYieldPerCycle"))
        bytes newValue; // The new value for the parameter, ABI encoded
        uint256 creationBlock;
        uint256 votingDeadlineBlock;
        uint256 forVotes; // Total voting power (reputation) for the proposal
        uint256 againstVotes; // Total voting power (reputation) against the proposal
        bool executed;
        mapping(address => bool) hasVoted; // To track if an address has voted on this proposal
    }

    // --- State Variables ---

    mapping(uint256 => ChronosUnitAttributes) private _chronosUnitAttributes; // tokenId => CU's dynamic attributes
    mapping(uint256 => bool) private _isStaked; // tokenId => true if staked
    // mapping(uint256 => address) private _stakedByOwner; // tokenId => owner address (redundant with ERC721 but kept for clarity/potential future uses)

    mapping(uint256 => PredictionCycle) private _predictionCycles; // cycleId => PredictionCycle data
    mapping(uint256 => UserForecast[]) private _cycleUserForecasts; // cycleId => array of user forecasts

    mapping(address => uint256) private _userReputation; // address => reputation score
    mapping(uint256 => uint256) private _unitAccruedYield; // tokenId => amount of yield accrued (in internal units, simulated)

    // Governance parameters
    mapping(uint256 => Proposal) private _proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 1000; // Roughly 4 hours on Ethereum (adjust for desired duration)
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation to create a proposal
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 10; // Minimum reputation to vote on a proposal
    uint256 public proposalQuorumPercentage = 51; // Percentage of total 'for' votes needed relative to total votes

    // Yield parameters (adjustable by governance)
    uint256 public baseYieldPerCycle = 1 ether / 100; // 0.01 tokens per cycle per unit (simulated yield)
    uint256 public reputationYieldMultiplier = 100; // Multiplier (out of 1000) for reputation bonus (e.g., 100 = 0.1x)
    uint256 public predictionAccuracyYieldMultiplier = 200; // Multiplier (out of 1000) for accuracy bonus

    // Evolution parameters
    uint256 public constant EVOLUTION_SCORE_THRESHOLD = 500; // Evolution progress score needed to evolve
    uint256 public constant EVOLUTION_REPUTATION_BOOST_FACTOR = 5; // Reputation points per accuracy score for evolution

    // --- Events ---

    event ChronosUnitMinted(address indexed to, uint256 indexed tokenId, string initialMetadataURI);
    event ChronosUnitBurned(uint256 indexed tokenId);
    event UnitAttributesUpdated(uint256 indexed tokenId, ChronosUnitAttributes newAttributes);
    event ChronosUnitStaked(uint256 indexed tokenId, address indexed owner, uint256 cycleId);
    event ChronosUnitUnstaked(uint256 indexed tokenId, address indexed owner);
    event PredictiveYieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);

    event TimeSeriesForecastSubmitted(uint256 indexed cycleId, address indexed user, int256 forecastValue);
    event PredictionCycleProcessed(uint256 indexed cycleId, int256 officialPrediction);
    event ActualOutcomeRegistered(uint256 indexed cycleId, int256 actualOutcome);

    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event ChronosUnitEvolved(uint256 indexed tokenId, uint256 newGeneration);

    event ProposalCreated(uint256 indexed proposalId, bytes32 parameterName, bytes newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event SystemParameterChanged(bytes32 parameterName, bytes newValue);

    // --- Constructor ---

    /**
     * @dev Initializes the ERC721 token and sets the contract owner.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     */
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Modifiers ---

    /**
     * @dev Throws if `_msgSender()` is not the owner or an approved operator for `tokenId`.
     */
    modifier onlyChronosUnitOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    /**
     * @dev Throws if `tokenId` is not staked.
     */
    modifier onlyStaked(uint256 tokenId) {
        if (!_isStaked[tokenId]) {
            revert TokenNotStaked();
        }
        _;
    }

    /**
     * @dev Throws if `tokenId` is already staked.
     */
    modifier onlyNotStaked(uint256 tokenId) {
        if (_isStaked[tokenId]) {
            revert TokenAlreadyStaked();
        }
        _;
    }

    // --- I. ChronosUnit (Dynamic NFT) Management ---

    /**
     * @dev Mints a new ChronosUnit (ERC721 NFT) to a specified address with initial metadata.
     *      Only callable by the contract owner (e.g., for initial distribution or specific events).
     * @param to The address to mint the NFT to.
     * @param initialMetadataURI The initial URI pointing to the NFT's base metadata.
     * @return The tokenId of the newly minted ChronosUnit.
     */
    function mintChronosUnit(address to, string memory initialMetadataURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        _chronosUnitAttributes[newTokenId] = ChronosUnitAttributes({
            generation: 1,
            predictionAccuracyScore: 0,
            evolutionProgress: 0,
            lastEvolutionCycle: 0,
            stakedCycleId: 0,
            lastClaimCycleId: 0
        });

        // The base URI might point to a generic base or a placeholder.
        // The `tokenURI` function dynamically generates the full URI.
        _setTokenURI(newTokenId, initialMetadataURI);

        emit ChronosUnitMinted(to, newTokenId, initialMetadataURI);
        return newTokenId;
    }

    /**
     * @dev Burns a ChronosUnit, removing it from circulation.
     *      Only callable by the token owner or an approved operator. Cannot burn a staked token.
     * @param tokenId The ID of the ChronosUnit to burn.
     */
    function burnChronosUnit(uint256 tokenId)
        public
    {
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender())) {
            revert NotOwnerOrApproved();
        }
        if (_isStaked[tokenId]) {
            revert TokenAlreadyStaked(); // Cannot burn a staked token
        }
        _burn(tokenId);
        delete _chronosUnitAttributes[tokenId]; // Clean up associated attributes
        emit ChronosUnitBurned(tokenId);
    }

    /**
     * @dev Internal function to update a CU's on-chain attributes, triggering potential metadata changes.
     *      This is primarily called by `evolveChronosUnit` or other internal logic affecting CU state.
     * @param tokenId The ID of the ChronosUnit.
     * @param newAttributes The new attributes for the ChronosUnit.
     */
    function _updateUnitAttributes(uint256 tokenId, ChronosUnitAttributes memory newAttributes) internal {
        _chronosUnitAttributes[tokenId] = newAttributes;
        // In a real dynamic NFT, this might trigger an off-chain service to re-generate metadata or update a pointer.
        // For this example, `tokenURI` will simply reflect the new state upon request.
        emit UnitAttributesUpdated(tokenId, newAttributes);
    }

    /**
     * @dev Retrieves the current dynamic attributes of a specified ChronosUnit.
     * @param tokenId The ID of the ChronosUnit.
     * @return The ChronosUnitAttributes struct.
     */
    function getUnitAttributes(uint256 tokenId)
        public view returns (ChronosUnitAttributes memory)
    {
        _exists(tokenId); // ERC721 internal check
        return _chronosUnitAttributes[tokenId];
    }

    /**
     * @dev Overrides ERC721's `tokenURI` to provide dynamic metadata based on ChronosUnit attributes.
     *      In a real application, this URI would point to an API endpoint that serves JSON metadata
     *      based on the on-chain attributes of the token, ensuring the NFT visual/data representation
     *      evolves with its on-chain state.
     * @param tokenId The ID of the ChronosUnit.
     * @return The dynamic URI for a ChronosUnit.
     */
    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        _exists(tokenId); // ERC721 internal check

        ChronosUnitAttributes memory attrs = _chronosUnitAttributes[tokenId];
        address owner = _ownerOf(tokenId);

        // Example of a dynamically constructed URI based on attributes.
        // This simulates how an off-chain metadata service would generate metadata.
        // The `_baseURI` (set by `_setTokenURI` during mint) could be a constant IPFS CID for a base image.
        // The actual metadata JSON would likely be hosted on an external service.
        return string(abi.encodePacked(
            _baseURI(), // Base URI from _setTokenURI (could be a generic IPFS gateway)
            tokenId.toString(),
            "/gen", attrs.generation.toString(),
            "/accScore", attrs.predictionAccuracyScore.toString(),
            "/evolProgress", attrs.evolutionProgress.toString(),
            "/owner", Strings.toHexString(uint160(owner), 20),
            ".json" // Specifies a JSON metadata file
        ));
    }

    // Standard ERC721 functions (transferFrom, approve, setApprovalForAll, balanceOf, ownerOf)
    // are inherited from OpenZeppelin's ERC721 contract and used as-is.

    // --- II. Time-Series Prediction Engine ---

    /**
     * @dev Allows users to submit their numerical forecast for a specific future prediction cycle.
     *      Each user can submit only one forecast per cycle. Cycle IDs can be block numbers or time-based.
     * @param cycleId The ID of the prediction cycle.
     * @param forecastValue The user's forecast as an integer.
     */
    function submitTimeSeriesForecast(uint256 cycleId, int256 forecastValue) public {
        if (_predictionCycles[cycleId].hasForecasted[_msgSender()]) {
            revert ForecastAlreadySubmitted();
        }
        if (_predictionCycles[cycleId].outcomeRegistered) {
            revert InvalidCycleId(); // Cannot forecast for a cycle whose outcome is already known
        }

        _predictionCycles[cycleId].hasForecasted[_msgSender()] = true;
        _predictionCycles[cycleId].totalForecasts++;
        _predictionCycles[cycleId].aggregatedForecastSum += forecastValue;
        _cycleUserForecasts[cycleId].push(UserForecast({ user: _msgSender(), forecastValue: forecastValue }));

        emit TimeSeriesForecastSubmitted(cycleId, _msgSender(), forecastValue);
    }

    /**
     * @dev Initiates the on-chain calculation of the "official" prediction for a given cycle.
     *      This function aggregates all submitted user forecasts for the cycle and uses a deterministic algorithm.
     *      Can be called by anyone, incentivizing network activity to process predictions.
     * @param cycleId The ID of the prediction cycle.
     */
    function processPredictionCycle(uint256 cycleId) public {
        if (_predictionCycles[cycleId].processed) {
            revert PredictionCycleNotProcessed(); // Already processed
        }
        if (_predictionCycles[cycleId].totalForecasts == 0) {
            revert NoForecastsSubmitted(); // No forecasts to process
        }

        // Deterministic "AI" model: Simple average of all submitted forecasts.
        // This can be extended to more complex, but still deterministic, on-chain models.
        int256 officialPrediction = _predictionCycles[cycleId].aggregatedForecastSum / int256(_predictionCycles[cycleId].totalForecasts);

        _predictionCycles[cycleId].officialPrediction = officialPrediction;
        _predictionCycles[cycleId].processed = true;

        emit PredictionCycleProcessed(cycleId, officialPrediction);
    }

    /**
     * @dev Retrieves the officially calculated prediction for a past or current cycle.
     * @param cycleId The ID of the prediction cycle.
     * @return The officially calculated prediction.
     */
    function getPredictionResult(uint256 cycleId) public view returns (int256 officialPrediction) {
        if (!_predictionCycles[cycleId].processed) {
            revert PredictionCycleNotProcessed(); // Prediction not yet processed
        }
        return _predictionCycles[cycleId].officialPrediction;
    }

    /**
     * @dev A privileged function (e.g., by the contract owner, a trusted keeper, or through DAO vote)
     *      to record the true outcome for a past prediction cycle. This is crucial for evaluating
     *      forecast accuracy and user reputation.
     * @param cycleId The ID of the prediction cycle.
     * @param actualValue The actual observed outcome for that cycle.
     */
    function registerActualOutcome(uint256 cycleId, int256 actualValue) public onlyOwner { // Access control can be changed to DAO
        if (_predictionCycles[cycleId].outcomeRegistered) {
            revert PredictionOutcomeNotRegistered(); // Outcome already registered
        }
        if (!_predictionCycles[cycleId].processed) {
            revert PredictionCycleNotProcessed(); // Cannot register outcome before prediction is processed
        }

        _predictionCycles[cycleId].actualOutcome = actualValue;
        _predictionCycles[cycleId].outcomeRegistered = true;

        // Immediately update user reputations based on their forecast accuracy for this cycle
        _updateReputationBasedOnOutcome(cycleId, actualValue);

        emit ActualOutcomeRegistered(cycleId, actualValue);
    }

    /**
     * @dev Internal function to update user reputation based on their forecast accuracy for a given cycle.
     *      Compares individual forecasts to the actual outcome and the official prediction.
     * @param cycleId The ID of the prediction cycle.
     * @param actualOutcome The actual outcome for that cycle.
     */
    function _updateReputationBasedOnOutcome(uint256 cycleId, int256 actualOutcome) internal {
        UserForecast[] storage forecasts = _cycleUserForecasts[cycleId];
        int256 officialPrediction = _predictionCycles[cycleId].officialPrediction;

        // Calculate absolute error for the official prediction
        int256 officialPredictionError = actualOutcome > officialPrediction ? actualOutcome - officialPrediction : officialPrediction - actualOutcome;

        // Iterate through all user forecasts for the cycle to update individual reputations.
        for (uint i = 0; i < forecasts.length; i++) {
            UserForecast memory f = forecasts[i];
            int256 userForecastError = actualOutcome > f.forecastValue ? actualOutcome - f.forecastValue : f.forecastValue - actualOutcome;

            int256 reputationChange = 0;
            if (userForecastError == 0) { // Perfect forecast
                reputationChange = 50;
            } else if (userForecastError < officialPredictionError) { // More accurate than official prediction
                reputationChange = 20;
            } else if (userForecastError == officialPredictionError) { // Same accuracy as official
                reputationChange = 5;
            } else { // Less accurate than official or bad forecast
                reputationChange = -10;
            }

            _updateUserReputation(f.user, reputationChange);
        }
    }

    // --- III. Predictive Staking & Yield ---

    /**
     * @dev Locks a ChronosUnit into the staking pool, making it eligible for predictive yield.
     *      Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the ChronosUnit to stake.
     */
    function stakeChronosUnit(uint256 tokenId)
        public onlyChronosUnitOwner(tokenId) onlyNotStaked(tokenId)
    {
        _isStaked[tokenId] = true;
        _chronosUnitAttributes[tokenId].stakedCycleId = block.number; // Use block.number as a simple cycle ID for staking start
        emit ChronosUnitStaked(tokenId, _msgSender(), block.number);
    }

    /**
     * @dev Unlocks a previously staked ChronosUnit.
     *      Only callable by the token owner or an approved operator. Claims any pending yield before unstaking.
     * @param tokenId The ID of the ChronosUnit to unstake.
     */
    function unstakeChronosUnit(uint256 tokenId)
        public onlyChronosUnitOwner(tokenId) onlyStaked(tokenId)
    {
        // Claim any pending yield before unstaking to ensure all rewards are processed.
        _claimPredictiveYield(tokenId);
        
        _isStaked[tokenId] = false;
        _chronosUnitAttributes[tokenId].stakedCycleId = 0; // Reset staked cycle ID
        emit ChronosUnitUnstaked(tokenId, _msgSender());
    }

    /**
     * @dev Allows a user to claim accrued yield for their staked ChronosUnit.
     *      Yield is calculated and adjusted by the unit's performance during prediction cycles.
     *      This is the public wrapper function.
     * @param tokenId The ID of the ChronosUnit.
     */
    function claimPredictiveYield(uint256 tokenId)
        public onlyChronosUnitOwner(tokenId) onlyStaked(tokenId)
    {
        _claimPredictiveYield(tokenId);
    }

    /**
     * @dev Internal function to calculate and disburse yield for a ChronosUnit.
     *      Iterates through cycles since the last claim/stake to calculate yield.
     *      The actual yield token transfer logic is simulated here.
     * @param tokenId The ID of the ChronosUnit.
     */
    function _claimPredictiveYield(uint256 tokenId) internal {
        ChronosUnitAttributes storage attrs = _chronosUnitAttributes[tokenId];
        uint256 currentCycleId = block.number; // Using block.number as a simple cycle ID for calculations

        // Determine the starting cycle for yield calculation. If first claim, start from stakedCycleId.
        uint256 startCycle = (attrs.lastClaimCycleId == 0) ? attrs.stakedCycleId : attrs.lastClaimCycleId;

        if (startCycle >= currentCycleId) {
            revert NoYieldToClaim();
        }

        uint256 calculatedYield = 0;
        address tokenOwner = _ownerOf(tokenId); // Get current owner for reputation check

        // Iterate through each cycle since the last claim/stake
        for (uint256 i = startCycle; i < currentCycleId; i++) {
            PredictionCycle storage cycle = _predictionCycles[i];
            
            uint256 cycleYield = baseYieldPerCycle; // Start with base yield

            // Only apply bonuses if the prediction cycle has been fully processed and its outcome registered
            if (cycle.processed && cycle.outcomeRegistered) {
                int256 officialPrediction = cycle.officialPrediction;
                int256 actualOutcome = cycle.actualOutcome;
                int256 officialPredictionError = actualOutcome > officialPrediction ? actualOutcome - officialPrediction : officialPrediction - actualPrediction;

                // Example logic: if the official prediction error is within a certain threshold, apply bonuses.
                // This simulates the CU "performing well" during accurate prediction periods.
                if (officialPredictionError >= 0 && officialPredictionError < 10) { // A low error indicates a good prediction
                    cycleYield += (baseYieldPerCycle * predictionAccuracyYieldMultiplier / 1000); // Bonus for good prediction cycle
                    
                    // Apply bonus based on the owner's current reputation
                    cycleYield += (baseYieldPerCycle * _userReputation[tokenOwner] / reputationYieldMultiplier / 1000); 
                }

                // Boost CU's evolution progress for active participation during verified cycles
                attrs.evolutionProgress += EVOLUTION_REPUTATION_BOOST_FACTOR;
            } else {
                // For cycles where prediction/outcome is not yet verified, provide a reduced yield.
                cycleYield = baseYieldPerCycle / 2;
            }
            calculatedYield += cycleYield;
        }

        if (calculatedYield == 0) {
             revert NoYieldToClaim();
        }

        // Simulate yield token transfer. In a real contract, this would involve an actual ERC20 token.
        // E.g.: IERC20(yieldTokenAddress).transfer(tokenOwner, calculatedYield);
        // For this example, we simply accrue it and log the event.
        _unitAccruedYield[tokenId] += calculatedYield; 

        attrs.lastClaimCycleId = currentCycleId; // Update last claim cycle to current block

        emit PredictiveYieldClaimed(tokenId, tokenOwner, calculatedYield);
    }

    /**
     * @dev Privileged function (e.g., by the contract owner or through DAO governance)
     *      to adjust parameters influencing yield calculation.
     * @param _baseMultiplier The new base yield awarded per cycle.
     * @param _reputationMultiplier The new multiplier for reputation bonus.
     * @param _predictionAccuracyMultiplier The new multiplier for prediction accuracy bonus.
     */
    function setYieldMultipliers(
        uint256 _baseMultiplier,
        uint256 _reputationMultiplier,
        uint256 _predictionAccuracyMultiplier
    ) public onlyOwner { // Access control can be changed to DAO
        baseYieldPerCycle = _baseMultiplier;
        reputationYieldMultiplier = _reputationMultiplier;
        predictionAccuracyYieldMultiplier = _predictionAccuracyMultiplier;
        emit SystemParameterChanged("baseYieldPerCycle", abi.encode(baseYieldPerCycle));
        emit SystemParameterChanged("reputationYieldMultiplier", abi.encode(reputationYieldMultiplier));
        emit SystemParameterChanged("predictionAccuracyYieldMultiplier", abi.encode(predictionAccuracyYieldMultiplier));
    }

    // --- IV. Reputation & Evolution System ---

    /**
     * @dev Internal function to adjust a user's reputation score.
     *      Reputation can increase or decrease based on activity. Floor at 0.
     * @param user The address of the user whose reputation is being updated.
     * @param change The amount to change the reputation by (can be negative).
     */
    function _updateUserReputation(address user, int256 change) internal {
        unchecked { // Use unchecked to handle potential underflow for _userReputation, then floor it.
            if (change < 0) {
                // Ensure reputation doesn't go below zero
                _userReputation[user] = _userReputation[user] > uint256(-change) ? _userReputation[user] - uint256(-change) : 0;
            } else {
                _userReputation[user] += uint256(change);
            }
        }
        emit UserReputationUpdated(user, _userReputation[user]);
    }

    /**
     * @dev Triggers an evolution of a ChronosUnit. Its attributes change based on its accumulated evolution progress,
     *      which is boosted by successful staking periods and contribution to accurate predictions.
     *      Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the ChronosUnit to evolve.
     */
    function evolveChronosUnit(uint256 tokenId) public onlyChronosUnitOwner(tokenId) {
        ChronosUnitAttributes storage attrs = _chronosUnitAttributes[tokenId];

        if (attrs.evolutionProgress < EVOLUTION_SCORE_THRESHOLD) {
            revert InvalidTokenId(); // Not enough evolution progress to evolve
        }

        attrs.generation++; // Increment generation
        attrs.predictionAccuracyScore += attrs.evolutionProgress / EVOLUTION_REPUTATION_BOOST_FACTOR; // Accumulate accuracy score
        attrs.evolutionProgress = 0; // Reset progress for the next evolution
        attrs.lastEvolutionCycle = block.number; // Record last evolution cycle

        _updateUnitAttributes(tokenId, attrs); // Update attributes and emit event
        emit ChronosUnitEvolved(tokenId, attrs.generation);
    }

    /**
     * @dev Retrieves the current reputation score of a user.
     * @param user The address of the user.
     * @return The user's current reputation score.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return _userReputation[user];
    }

    /**
     * @dev Shows how close a ChronosUnit is to its next evolution stage.
     * @param tokenId The ID of the ChronosUnit.
     * @return The current evolution progress score.
     */
    function getUnitEvolutionProgress(uint256 tokenId) public view returns (uint256) {
        _exists(tokenId);
        return _chronosUnitAttributes[tokenId].evolutionProgress;
    }

    // --- V. Governance & System Maintenance ---

    /**
     * @dev Allows users with sufficient reputation to propose changes to system parameters.
     *      The parameter name is identified by its keccak256 hash.
     * @param parameterName A bytes32 hash identifying the parameter (e.g., `keccak256("baseYieldPerCycle")`).
     * @param newValue The new value for the parameter, ABI encoded into bytes.
     */
    function proposeSystemParameterChange(bytes32 parameterName, bytes memory newValue) public {
        if (_userReputation[_msgSender()] < MIN_REPUTATION_FOR_PROPOSAL) {
            revert InsufficientReputation();
        }

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        // Initialize a new Proposal struct
        _proposals[proposalId] = Proposal({
            parameterName: parameterName,
            newValue: newValue,
            creationBlock: block.number,
            votingDeadlineBlock: block.number + PROPOSAL_VOTING_PERIOD_BLOCKS,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping for voters
        });

        emit ProposalCreated(proposalId, parameterName, newValue, _msgSender());
    }

    /**
     * @dev Allows eligible users to vote on active proposals.
     *      Voting power is tied to the voter's current reputation score.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.creationBlock == 0) {
            revert ProposalNotFound();
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert AlreadyVoted();
        }
        if (block.number > proposal.votingDeadlineBlock) {
            revert CannotVoteOnEndedProposal();
        }
        uint256 voterReputation = _userReputation[_msgSender()];
        if (voterReputation < MIN_REPUTATION_FOR_VOTE) {
            revert InsufficientReputation();
        }

        proposal.hasVoted[_msgSender()] = true;
        if (support) {
            proposal.forVotes += voterReputation; // Voting power scaled by reputation
        } else {
            proposal.againstVotes += voterReputation;
        }

        emit ProposalVoted(proposalId, _msgSender(), support);
    }

    /**
     * @dev Executes a successfully passed proposal.
     *      Requires the voting period to have ended and the 'for' votes to meet quorum.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.creationBlock == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed) {
            revert ProposalNotExecutable(); // Already executed
        }
        if (block.number <= proposal.votingDeadlineBlock) {
            revert ProposalNotExecutable(); // Voting period not ended
        }

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        // Check for quorum: total votes must be non-zero and 'for' votes must meet percentage.
        if (totalVotes == 0 || proposal.forVotes * 100 / totalVotes < proposalQuorumPercentage) {
            revert ProposalNotExecutable(); // Quorum not met or proposal failed
        }

        // --- Execute the parameter change based on `parameterName` ---
        if (proposal.parameterName == keccak256("baseYieldPerCycle")) {
            baseYieldPerCycle = abi.decode(proposal.newValue, (uint256));
        } else if (proposal.parameterName == keccak256("reputationYieldMultiplier")) {
            reputationYieldMultiplier = abi.decode(proposal.newValue, (uint256));
        } else if (proposal.parameterName == keccak256("predictionAccuracyYieldMultiplier")) {
            predictionAccuracyYieldMultiplier = abi.decode(proposal.newValue, (uint256));
        } else if (proposal.parameterName == keccak256("proposalQuorumPercentage")) {
            proposalQuorumPercentage = abi.decode(proposal.newValue, (uint256));
        }
        // Add more parameters here for future governance expansions

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
        emit SystemParameterChanged(proposal.parameterName, proposal.newValue);
    }

    /**
     * @dev Retrieves a proposal's details.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposal(uint256 proposalId) public view returns (
        bytes32 parameterName,
        bytes memory newValue,
        uint256 creationBlock,
        uint256 votingDeadlineBlock,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed
    ) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.creationBlock == 0) {
            revert ProposalNotFound();
        }
        return (
            proposal.parameterName,
            proposal.newValue,
            proposal.creationBlock,
            proposal.votingDeadlineBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed
        );
    }

    // --- Helper Getters (to retrieve internal state for off-chain applications or debugging) ---

    /**
     * @dev Retrieves comprehensive details for a specific prediction cycle.
     * @param cycleId The ID of the prediction cycle.
     * @return A tuple containing prediction cycle details.
     */
    function getPredictionCycleDetails(uint256 cycleId) public view returns (
        bool processed,
        bool outcomeRegistered,
        int256 officialPrediction,
        int256 actualOutcome,
        uint256 totalForecasts,
        int256 aggregatedForecastSum
    ) {
        PredictionCycle storage cycle = _predictionCycles[cycleId];
        return (
            cycle.processed,
            cycle.outcomeRegistered,
            cycle.officialPrediction,
            cycle.actualOutcome,
            cycle.totalForecasts,
            cycle.aggregatedForecastSum
        );
    }

    /**
     * @dev Checks the staking status of a ChronosUnit.
     * @param tokenId The ID of the ChronosUnit.
     * @return A tuple: (isStaked, stakedCycleId).
     */
    function getUnitStakingStatus(uint256 tokenId) public view returns (bool, uint256) {
        _exists(tokenId);
        return (_isStaked[tokenId], _chronosUnitAttributes[tokenId].stakedCycleId);
    }

    /**
     * @dev Retrieves the total simulated yield accrued for a ChronosUnit that is yet to be claimed.
     * @param tokenId The ID of the ChronosUnit.
     * @return The accrued yield amount in internal units.
     */
    function getUnitAccruedYield(uint256 tokenId) public view returns (uint256) {
        _exists(tokenId);
        return _unitAccruedYield[tokenId];
    }
}
```