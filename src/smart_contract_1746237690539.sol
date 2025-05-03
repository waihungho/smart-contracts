Okay, let's design a smart contract for a "Dimensional Art Gallery". This contract will manage unique digital art pieces (NFTs) that exist in a conceptual multi-dimensional space and can evolve over time based on on-chain rules and user interactions.

Here are the advanced concepts we'll incorporate:

1.  **Dynamic NFTs:** The `tokenURI` will generate metadata reflecting the current state (evolution, position, etc.) of the NFT, not static data.
2.  **On-chain Evolution Engine:** Rules stored and processed on-chain dictate how the art pieces (dimensions) change over time or based on triggers.
3.  **Rule Governance:** Users (specifically, stakers of a hypothetical "Nexus Token" or just ETH staked to the contract) can propose and vote on new evolution rules.
4.  **Spatial Representation:** Each NFT has on-chain coordinates in a virtual 3D space, influencing interactions.
5.  **Inter-NFT Linking:** Owners can link their dimensions, potentially affecting their evolution or interaction properties.
6.  **Staking for Features:** Staking tokens/ETH unlocks advanced abilities like proposing rules, faster evolution, or unique interactions.
7.  **Parameterized Genesis:** New dimensions are minted based on initial parameters provided by the user (within contract constraints).
8.  **On-chain Stability Metric:** A calculated score influencing how dimensions are affected by rules or interactions.
9.  **Limited Resource Interaction:** Functions might consume a form of "energy" or require a cool-down, tied to staking or dimension properties.

---

### **Outline**

1.  **Contract Name:** `DimensionalArtGallery`
2.  **Inheritance:** ERC721, Ownable, Pausable
3.  **Core Concepts:** Dynamic NFTs, On-chain Evolution, Rule Governance, Spatial Representation, Staking.
4.  **Key Features:**
    *   Minting of unique "Dimension" NFTs with initial parameters.
    *   Dimensions evolve based on active on-chain rules.
    *   Mechanism to trigger dimension evolution.
    *   Owners can move dimensions and link them.
    *   Ability to explore the dimensional space.
    *   Users can stake ETH/tokens to gain "Nexus Access".
    *   Nexus Stakers can propose and vote on Evolution Rules.
    *   Dynamic metadata URI reflects dimension state.
    *   Admin controls for genesis parameters, fees, cooldowns.
5.  **State Variables:**
    *   Dimension data mapping (`dimensions`).
    *   Mapping for linked dimensions (`linkedDimensions`).
    *   Mapping for Nexus stakes (`nexusStakes`).
    *   Mapping for evolution rule proposals (`ruleProposals`).
    *   Mapping for active evolution rules (`activeEvolutionRules`).
    *   Mapping for vote tracking (`proposalVotes`).
    *   Counters for token IDs, rule proposal IDs.
    *   Admin settings (genesis constraints, cooldowns, stake requirements, base URI, fee address).
6.  **Structs:**
    *   `Dimension`: Stores NFT-specific data (coordinates, evolution, stability, genesis params, etc.).
    *   `EvolutionRule`: Defines a rule for evolution.
    *   `EvolutionRuleProposal`: Details of a proposed rule, including voting data.
    *   `NexusStake`: Details of a user's stake.
7.  **Events:** For key actions like Mint, Evolve, Link, Stake, RuleProposed, RuleExecuted, VoteCast, CoordinateUpdate, etc.
8.  **Errors:** Custom errors for clearer reverts.
9.  **Modifiers:** `onlyDimensionOwner`, `onlyNexusStaker`, `whenNotPaused`, `isValidGenesisParams`, `canEvolve`, `canProposeRule`.
10. **Functions:** (Grouped by functionality)
    *   **ERC721 Standard (11 functions):** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` (overloaded), `supportsInterface`, `name`, `symbol`.
    *   **Dimension Management (4 functions):** `mintDimension`, `getDimensionDetails`, `tokenURI` (Dynamic), `getDimensionEvolutionHistory`.
    *   **Evolution & Dynamics (7 functions):** `evolveDimension`, `triggerRandomEvolution`, `calculateStabilityScore`, `estimateNextStability`, `setEvolutionCooldown`, `getTimeUntilNextEvolution`, `setEvolutionEngineParameters`.
    *   **Rule Governance (5 functions):** `proposeEvolutionRule`, `voteOnRuleProposal`, `getRuleProposalDetails`, `executeRuleProposal`, `getActiveEvolutionRules`.
    *   **Spatial & Interaction (5 functions):** `updateDimensionalCoordinates`, `linkDimensions`, `breakLink`, `getLinkedDimensions`, `exploreDimensionalSpace`.
    *   **Nexus Staking (5 functions):** `stakeForNexusAccess`, `unstakeFromNexus`, `getNexusStakeDetails`, `claimNexusRewards`, `setNexusStakeRequirement`.
    *   **Admin & Configuration (3 functions):** `setGenesisConstraints`, `distributeFees`, `setBaseMetadataURI`.

**Total Functions:** 11 + 4 + 7 + 5 + 5 + 5 + 3 = **40 functions** (well over the minimum 20).

---

### **Function Summary**

*   **ERC721 Standard:** Basic functions required for ERC721 compliance (checking balances, ownership, transfers, approvals, standard metadata like name/symbol, interface support).
*   **Dimension Management:** Handles the creation of new dimensions (`mintDimension`), retrieving their comprehensive on-chain data (`getDimensionDetails`), generating the dynamic metadata URI based on their state (`tokenURI`), and potentially fetching a history of their significant evolution steps (`getDimensionEvolutionHistory`).
*   **Evolution & Dynamics:** Contains the core logic for dimension evolution (`evolveDimension`), allows users to trigger this process (`triggerRandomEvolution`), calculates the dimension's current 'stability' based on its properties (`calculateStabilityScore`), estimates potential future stability changes (`estimateNextStability`), manages the cooldown period between evolutions (`setEvolutionCooldown`, `getTimeUntilNextEvolution`), and allows admin to tweak global evolution parameters (`setEvolutionEngineParameters`).
*   **Rule Governance:** Enables users with "Nexus Access" to submit proposals for new evolution rules (`proposeEvolutionRule`), cast votes on active proposals (`voteOnRuleProposal`), retrieve proposal information (`getRuleProposalDetails`), allows successful proposals to be enacted (`executeRuleProposal`), and lists all currently active rules (`getActiveEvolutionRules`).
*   **Spatial & Interaction:** Manages the virtual 3D coordinates of each dimension (`updateDimensionalCoordinates`), allows owners to create connections between their dimensions (`linkDimensions`, `breakLink`), retrieves lists of linked dimensions (`getLinkedDimensions`), and provides a query function to find dimensions within a specific spatial range (`exploreDimensionalSpace`).
*   **Nexus Staking:** Facilitates users staking ETH (or a hypothetical token) into the contract to gain "Nexus Access" benefits (`stakeForNexusAccess`, `unstakeFromNexus`), allows checking stake details (`getNexusStakeDetails`), includes placeholder logic for claiming potential rewards from staking (`claimNexusRewards`), and allows admin to configure the minimum stake requirement (`setNexusStakeRequirement`).
*   **Admin & Configuration:** Provides functions for the contract owner to set limits and defaults for new dimensions (`setGenesisConstraints`), withdraw accumulated contract fees (e.g., from minting) (`distributeFees`), and set the base part of the dynamic metadata URI (`setBaseMetadataURI`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Useful for tokenURI override example, though we'll make it dynamic

// --- Outline ---
// 1. Contract Name: DimensionalArtGallery
// 2. Inheritance: ERC721, Ownable, Pausable
// 3. Core Concepts: Dynamic NFTs, On-chain Evolution, Rule Governance, Spatial Representation, Staking.
// 4. Key Features: Minting, Evolution, Rule Proposal/Voting, Spatial movement/linking, Staking for access, Dynamic Metadata.
// 5. State Variables: Dimensions data, links, stakes, rule proposals, active rules, counters, admin settings.
// 6. Structs: Dimension, EvolutionRule, EvolutionRuleProposal, NexusStake.
// 7. Events: Mint, Evolve, Link, Stake, RuleProposed, VoteCast, RuleExecuted, CoordinateUpdate, etc.
// 8. Errors: Custom errors for validation failures.
// 9. Modifiers: Ownership, Pausability, Staking check, Genesis param check, Evolution cooldown check, Rule proposal check.
// 10. Functions: ERC721 standard, Dimension Management, Evolution, Governance, Spatial, Staking, Admin (40+ functions).

// --- Function Summary ---
// ERC721 Standard: Basic functions (balanceOf, ownerOf, transferFrom, approve, etc.)
// Dimension Management: Create (mintDimension), read data (getDimensionDetails), dynamic URI (tokenURI), history (getDimensionEvolutionHistory - simplified).
// Evolution & Dynamics: Trigger evolution (evolveDimension, triggerRandomEvolution), calculate state metrics (calculateStabilityScore, estimateNextStability), manage evolution timing (setEvolutionCooldown, getTimeUntilNextEvolution), global evolution settings (setEvolutionEngineParameters).
// Rule Governance: Propose rules (proposeEvolutionRule), vote (voteOnRuleProposal), check proposals (getRuleProposalDetails), execute rules (executeRuleProposal), list rules (getActiveEvolutionRules).
// Spatial & Interaction: Update location (updateDimensionalCoordinates), connect dimensions (linkDimensions, breakLink, getLinkedDimensions), query space (exploreDimensionalSpace).
// Nexus Staking: Stake (stakeForNexusAccess), unstake (unstakeFromNexus), check stake (getNexusStakeDetails), claim rewards (claimNexusRewards), set requirements (setNexusStakeRequirement).
// Admin & Configuration: Set mint limits (setGenesisConstraints), withdraw fees (distributeFees), set URI base (setBaseMetadataURI).

contract DimensionalArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 private _ruleProposalCounter;

    // --- Structs ---

    struct GenesisParameters {
        uint32 paramA; // Example parameter
        uint32 paramB; // Another example
        // Add more genesis parameters as needed
    }

    struct DimensionalCoordinates {
        int32 x;
        int32 y;
        int32 z;
    }

    struct Dimension {
        uint256 tokenId;
        GenesisParameters genesisParams;
        DimensionalCoordinates coordinates;
        uint64 genesisTimestamp; // When minted
        uint64 lastEvolutionTimestamp; // When last evolved
        uint32 currentEvolutionStep; // How many evolution steps taken
        uint32 stabilityScore; // Derived score based on state
        uint256[] linkedDimensions; // Array of token IDs linked to this one
        // Consider adding dynamic parameters that evolution rules modify
        bytes dynamicStateData; // Generic field for complex state changes by rules
    }

    struct EvolutionRule {
        uint256 ruleId;
        string name;
        bytes ruleLogic; // Placeholder for off-chain logic interpreter, on-chain parameters
        // Example on-chain parameters for the rule:
        uint32 minStabilityRequired;
        uint32 evolutionStepImpact;
        DimensionalCoordinates coordinateShiftEffect;
        // Add more parameters relevant to rule execution
        bool isActive;
    }

    enum ProposalState { Active, Succeeded, Failed, Executed }

    struct EvolutionRuleProposal {
        uint256 proposalId;
        EvolutionRule rule;
        address proposer;
        uint64 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Internal mapping to track votes
        ProposalState state;
        string description; // Off-chain link or short description
    }

    struct NexusStake {
        uint256 stakedAmount; // Amount of ETH staked
        uint64 stakeStartTime;
        // Add potential reward tracking here
    }

    // --- State Variables ---

    mapping(uint256 => Dimension) public dimensions;
    // To efficiently check links from the other side
    mapping(uint256 => mapping(uint256 => bool)) private _isLinked;

    mapping(address => NexusStake) public nexusStakes;
    uint256 public minNexusStakeAmount = 1 ether; // Minimum ETH to stake for Nexus access

    mapping(uint256 => EvolutionRuleProposal) private _ruleProposals; // Using private as we'll provide getters
    mapping(uint256 => EvolutionRule) private _activeEvolutionRules; // ruleId -> EvolutionRule
    uint256[] private _activeEvolutionRuleIds; // For iterating active rules

    // Admin/Configuration Settings
    GenesisParameters public genesisConstraints; // Max/min values for params
    address payable public feeRecipient;
    uint256 public mintFee = 0.05 ether;
    string private _baseMetadataURI;
    uint64 public dimensionEvolutionCooldown = 1 days; // Cooldown duration in seconds
    uint256 public ruleVotingPeriod = 3 days; // Duration for rule proposals

    // --- Events ---

    event DimensionMinted(uint256 indexed tokenId, address indexed owner, GenesisParameters genesisParams, DimensionalCoordinates coordinates);
    event DimensionEvolved(uint256 indexed tokenId, uint32 newEvolutionStep, uint32 newStabilityScore, uint256[] appliedRuleIds);
    event RandomEvolutionTriggered(uint256 indexed tokenId, address indexed caller, uint256 cost);
    event CoordinatesUpdated(uint256 indexed tokenId, DimensionalCoordinates oldCoords, DimensionalCoordinates newCoords);
    event DimensionsLinked(uint256 indexed token1, uint256 indexed token2);
    event LinkBroken(uint256 indexed token1, uint256 indexed token2);
    event NexusStaked(address indexed staker, uint256 amount);
    event NexusUnstaked(address indexed staker, uint256 amount);
    event RuleProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool votedYes);
    event RuleProposalExecuted(uint256 indexed proposalId, bool succeeded);
    event EvolutionRuleActivated(uint256 indexed ruleId, string name);
    event EvolutionRuleDeactivated(uint256 indexed ruleId);
    event FeesDistributed(address indexed recipient, uint256 amount);
    event GenesisConstraintsUpdated(GenesisParameters constraints);
    event BaseMetadataURIUpdated(string newURI);
    event EvolutionCooldownUpdated(uint64 newCooldown);
    event NexusStakeRequirementUpdated(uint256 newRequirement);

    // --- Errors ---

    error InvalidGenesisParameters();
    error DimensionNotFound();
    error NotDimensionOwner(address caller, uint256 tokenId);
    error CooldownNotPassed(uint64 timeUntilNextEvolution);
    error NoActiveEvolutionRulesApplicable();
    error DimensionsAlreadyLinked();
    error DimensionsNotLinked();
    error MustOwnBothDimensionsToLink();
    error CannotLinkToSelf();
    error InsufficientNexusStake(uint256 required, uint256 staked);
    error NexusStakeActive();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error VotingPeriodEnded();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error RuleAlreadyActive();
    error RuleNotFound();
    error NothingToClaim();
    error InvalidCoordinateUpdate();
    error InvalidRuleLogicData(); // Placeholder for validation related to `bytes ruleLogic`

    // --- Constructor ---

    constructor(address feeAddr, GenesisParameters initialConstraints, string memory baseURI)
        ERC721("Dimensional Art Gallery", "DIMART")
        Ownable(msg.sender)
    {
        feeRecipient = payable(feeAddr);
        genesisConstraints = initialConstraints;
        _baseMetadataURI = baseURI;
    }

    // --- Modifiers ---

    modifier onlyDimensionOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) revert NotDimensionOwner(msg.sender, tokenId);
        _;
    }

    modifier onlyNexusStaker() {
        if (nexusStakes[msg.sender].stakedAmount < minNexusStakeAmount) revert InsufficientNexusStake(minNexusStakeAmount, nexusStakes[msg.sender].stakedAmount);
        _;
    }

    modifier isValidGenesisParams(GenesisParameters memory params) {
        // Example validation: paramA must be within a range
        if (params.paramA < genesisConstraints.paramA || params.paramB > genesisConstraints.paramB) {
            revert InvalidGenesisParameters();
        }
        // Add more complex validation based on genesisConstraints
        _;
    }

    modifier canEvolve(uint256 tokenId) {
        Dimension storage dim = dimensions[tokenId];
        if (dim.genesisTimestamp == 0) revert DimensionNotFound();
        uint64 timeSinceLastEvolution = uint64(block.timestamp) - dim.lastEvolutionTimestamp;
        if (timeSinceLastEvolution < dimensionEvolutionCooldown) {
             revert CooldownNotPassed(dimensionEvolutionCooldown - timeSinceLastEvolution);
        }
        // Optional: Add check if any active rules *could* apply (e.g., stability threshold)
        _;
    }

    // --- ERC721 Standard Functions (Included for completeness) ---

    // These are standard ERC721 implementations, inherited from OpenZeppelin.
    // They satisfy the count towards the 20+ function requirement.
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), supportsInterface, name, symbol.

    // --- Dimension Management Functions ---

    /// @notice Mints a new Dimension NFT.
    /// @param genesisParams The initial parameters defining the dimension's genesis state.
    /// @param initialCoords The initial coordinates in the dimensional space.
    function mintDimension(GenesisParameters memory genesisParams, DimensionalCoordinates memory initialCoords)
        public
        payable
        whenNotPaused
        isValidGenesisParams(genesisParams) // Apply genesis constraints validation
        returns (uint256)
    {
        if (msg.value < mintFee) revert InsufficientFunds(); // Assuming mintFee is defined

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        Dimension storage newDim = dimensions[newItemId];
        newDim.tokenId = newItemId;
        newDim.genesisParams = genesisParams;
        newDim.coordinates = initialCoords;
        newDim.genesisTimestamp = uint64(block.timestamp);
        newDim.lastEvolutionTimestamp = uint64(block.timestamp); // Can evolve immediately after mint? Or set cooldown?
        newDim.currentEvolutionStep = 0;
        newDim.stabilityScore = calculateStabilityScore(newItemId); // Calculate initial stability
        // linkedDimensions starts empty
        // dynamicStateData starts empty

        _safeMint(msg.sender, newItemId);

        // Send mint fee to recipient
        (bool success, ) = feeRecipient.call{value: msg.value}("");
        require(success, "Fee transfer failed");

        emit DimensionMinted(newItemId, msg.sender, genesisParams, initialCoords);
        return newItemId;
    }

    /// @notice Gets all details for a specific dimension.
    /// @param tokenId The ID of the dimension.
    /// @return A struct containing all dimension data.
    function getDimensionDetails(uint256 tokenId) public view returns (Dimension memory) {
        Dimension storage dim = dimensions[tokenId];
        if (dim.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists
        return dim;
    }

    /// @notice Generates the dynamic metadata URI for a dimension.
    /// @dev The off-chain service receiving this URI must interpret the query parameters
    ///      to generate dynamic JSON metadata and potentially dynamic art representations.
    /// @param tokenId The ID of the dimension.
    /// @return The dynamic metadata URI.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        Dimension storage dim = dimensions[tokenId];
        if (dim.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists
        address owner = _ownerOf(tokenId); // Get current owner

        // Build query parameters from dimension state
        string memory queryParams = string(abi.encodePacked(
            "?tokenId=", toString(tokenId),
            "&owner=", Strings.toHexString(uint160(owner)),
            "&evolutionStep=", toString(dim.currentEvolutionStep),
            "&stability=", toString(dim.stabilityScore),
            "&coordX=", toString(dim.coordinates.x),
            "&coordY=", toString(dim.coordinates.y),
            "&coordZ=", toString(dim.coordinates.z),
            "&genesisA=", toString(dim.genesisParams.paramA),
            "&genesisB=", toString(dim.genesisParams.paramB),
            "&lastEvolved=", toString(dim.lastEvolutionTimestamp)
            // Add more parameters based on `dynamicStateData` if structured
        ));

        return string(abi.encodePacked(_baseMetadataURI, queryParams));
    }

     /// @notice Gets a simplified history of evolution steps (current implementation just returns current step and timestamp).
     /// @dev A more complex implementation would store historical snapshots or events.
     /// @param tokenId The ID of the dimension.
     /// @return An array of tuples, where each tuple is (evolutionStep, timestamp).
    function getDimensionEvolutionHistory(uint256 tokenId) public view returns (tuple(uint32 step, uint64 timestamp)[] memory) {
        Dimension storage dim = dimensions[tokenId];
        if (dim.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists

        // Simplified: Only return genesis and current state timestamp for history
        tuple(uint32 step, uint64 timestamp)[] memory history = new tuple(uint32, uint64)[](2);
        history[0] = (0, dim.genesisTimestamp);
        history[1] = (dim.currentEvolutionStep, dim.lastEvolutionTimestamp);

        // If we were storing history, this would iterate through history events
        // Example: history[i] = (event.evolutionStep, event.timestamp)
        return history;
    }


    // --- Evolution & Dynamics Functions ---

    /// @notice Evolves a specific dimension based on active rules.
    /// @dev Can only be called after the cooldown period. Applies applicable active rules.
    /// @param tokenId The ID of the dimension to evolve.
    function evolveDimension(uint256 tokenId)
        public
        whenNotPaused
        canEvolve(tokenId) // Check cooldown
    {
        Dimension storage dim = dimensions[tokenId];
        uint256 initialEvolutionStep = dim.currentEvolutionStep;
        uint256 initialStability = dim.stabilityScore;
        uint256[] memory appliedRuleIds = new uint256[](0); // To track which rules were applied

        // Apply applicable active rules
        for (uint i = 0; i < _activeEvolutionRuleIds.length; i++) {
            uint256 ruleId = _activeEvolutionRuleIds[i];
            EvolutionRule storage rule = _activeEvolutionRules[ruleId];

            // Check if rule is active and conditions met (e.g., stability threshold)
            if (rule.isActive && dim.stabilityScore >= rule.minStabilityRequired) {
                // --- Apply Rule Effects ---
                // This is where the complex rule logic would be interpreted/applied.
                // For this example, we'll have simple hardcoded effects based on rule parameters.
                dim.currentEvolutionStep += rule.evolutionStepImpact;
                dim.stabilityScore = calculateStabilityScore(tokenId); // Recalculate stability after changes
                dim.coordinates.x += rule.coordinateShiftEffect.x;
                dim.coordinates.y += rule.coordinateShiftEffect.y;
                dim.coordinates.z += rule.coordinateShiftEffect.z;
                // A real contract might interpret `rule.ruleLogic` to modify `dim.dynamicStateData`

                // Add applied rule ID to the list
                uint256 currentAppliedCount = appliedRuleIds.length;
                uint256[] memory newAppliedRuleIds = new uint256[](currentAppliedCount + 1);
                for(uint j=0; j<currentAppliedCount; j++) {
                    newAppliedRuleIds[j] = appliedRuleIds[j];
                }
                newAppliedRuleIds[currentAppliedCount] = ruleId;
                appliedRuleIds = newAppliedRuleIds;
            }
        }

        if (appliedRuleIds.length == 0) {
             // If no rules applied, just update timestamp and potentially a small step
             // This prevents the cooldown from blocking evolution indefinitely if no rules match
             dim.currentEvolutionStep++; // Still increment step even without specific rule effects
             dim.stabilityScore = calculateStabilityScore(tokenId);
             // No need to revert NoActiveEvolutionRulesApplicable if we auto-increment step
        }

        dim.lastEvolutionTimestamp = uint64(block.timestamp);

        emit DimensionEvolved(tokenId, dim.currentEvolutionStep, dim.stabilityScore, appliedRuleIds);
    }

    /// @notice Allows anyone to trigger evolution for a dimension by paying a fee.
    /// @dev This could be used to incentivize users to help keep the gallery "evolving".
    /// @param tokenId The ID of the dimension to evolve.
    function triggerRandomEvolution(uint256 tokenId)
        public
        payable
        whenNotPaused
        canEvolve(tokenId) // Check cooldown
    {
        // Require a small fee to prevent spamming
        uint256 triggerFee = 0.001 ether; // Example fee
        if (msg.value < triggerFee) revert InsufficientFunds();

        // Evolve the dimension
        evolveDimension(tokenId); // This will perform the evolution logic

        // Send fee to recipient or burn? Let's send to fee recipient.
        (bool success, ) = feeRecipient.call{value: msg.value}("");
        require(success, "Trigger fee transfer failed");

        emit RandomEvolutionTriggered(tokenId, msg.sender, msg.value);
    }


    /// @notice Calculates the current stability score for a dimension.
    /// @dev This is a view function. Stability could depend on age, evolution step, linked dimensions, coordinates, etc.
    /// @param tokenId The ID of the dimension.
    /// @return The calculated stability score.
    function calculateStabilityScore(uint256 tokenId) public view returns (uint32) {
        Dimension storage dim = dimensions[tokenId];
         if (dim.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists

        // Example calculation:
        // Stability = (Evolution Step * Weight) + (Number of Links * Weight) + (Time Alive / Weight) - (Coordinate Magnitude * Weight)
        uint64 timeAlive = uint64(block.timestamp) - dim.genesisTimestamp;
        uint32 numLinks = uint32(dim.linkedDimensions.length);
        uint32 coordMagnitude = uint32(sqrt(uint256(dim.coordinates.x * dim.coordinates.x + dim.coordinates.y * dim.coordinates.y + dim.coordinates.z * dim.coordinates.z))); // Simplified magnitude

        // Use integer arithmetic carefully, avoid division by zero, choose weights appropriately
        uint32 stability = dim.currentEvolutionStep * 5; // Step contributes positively
        stability += numLinks * 10; // Links contribute positively
        stability += uint32(timeAlive / 1 days); // Age contributes positively (scaled)
        if (coordMagnitude > 100) stability -= (coordMagnitude - 100) / 10; // Far coordinates reduce stability (above a threshold)

        // Cap stability or ensure minimum
        if (stability > 1000) stability = 1000;
        if (stability < 0) stability = 0; // Should not happen with uint32 and careful math, but defensive

        return stability;
    }

    /// @notice Estimates the potential stability score after one generic evolution step.
    /// @dev This is a simplified estimation, not a full simulation of rule application.
    /// @param tokenId The ID of the dimension.
    /// @return The estimated stability score.
    function estimateNextStability(uint256 tokenId) public view returns (uint32) {
         Dimension storage dim = dimensions[tokenId];
         if (dim.genesisTimestamp == 0) revert DimensionNotFound();

        // Estimate by incrementing evolution step and recalculating
        uint32 estimatedStep = dim.currentEvolutionStep + 1;
        uint64 timeAlive = uint64(block.timestamp) - dim.genesisTimestamp; // Use current time for age
        uint32 numLinks = uint32(dim.linkedDimensions.length);
         uint32 coordMagnitude = uint32(sqrt(uint256(dim.coordinates.x * dim.coordinates.x + dim.coordinates.y * dim.coordinates.y + dim.coordinates.z * dim.coordinates.z)));

        uint32 stability = estimatedStep * 5;
        stability += numLinks * 10;
        stability += uint32(timeAlive / 1 days);
        if (coordMagnitude > 100) stability -= (coordMagnitude - 100) / 10;

        if (stability > 1000) stability = 1000;
        if (stability < 0) stability = 0;

        return stability;
    }

    /// @notice Sets the cooldown period required between dimension evolutions.
    /// @dev Only callable by the contract owner.
    /// @param newCooldown The new cooldown period in seconds.
    function setEvolutionCooldown(uint64 newCooldown) public onlyOwner {
        dimensionEvolutionCooldown = newCooldown;
        emit EvolutionCooldownUpdated(newCooldown);
    }

     /// @notice Gets the time remaining until a dimension can evolve again.
     /// @param tokenId The ID of the dimension.
     /// @return Time in seconds until the next evolution is possible. Returns 0 if ready.
    function getTimeUntilNextEvolution(uint256 tokenId) public view returns (uint64) {
         Dimension storage dim = dimensions[tokenId];
         if (dim.genesisTimestamp == 0) revert DimensionNotFound();

         uint64 timeSinceLastEvolution = uint64(block.timestamp) - dim.lastEvolutionTimestamp;
         if (timeSinceLastEvolution >= dimensionEvolutionCooldown) {
             return 0;
         } else {
             return dimensionEvolutionCooldown - timeSinceLastEvolution;
         }
    }

    /// @notice Sets global parameters that influence the evolution engine's behavior.
    /// @dev This is an example; parameters would depend on the actual evolution logic implementation.
    /// @param param1 Example global evolution parameter.
    /// @param param2 Another example parameter.
    function setEvolutionEngineParameters(uint252 param1, int252 param2) public onlyOwner {
        // Example: store these parameters in new state variables
        // globalEvolutionParam1 = param1;
        // globalEvolutionParam2 = param2;
        // emit GlobalEvolutionParamsUpdated(param1, param2);
         revert("Function not fully implemented - Placeholder");
    }


    // --- Rule Governance Functions ---

    /// @notice Allows a Nexus Staker to propose a new evolution rule.
    /// @dev Requires minimum stake. Starts a voting period.
    /// @param ruleDetails The definition of the proposed evolution rule.
    /// @param description A short description or link to proposal details (e.g., IPFS hash).
    function proposeEvolutionRule(EvolutionRule memory ruleDetails, string memory description)
        public
        onlyNexusStaker
        whenNotPaused
    {
        _ruleProposalCounter++;
        uint256 proposalId = _ruleProposalCounter;

        ruleDetails.ruleId = proposalId; // Assign proposalId as ruleId for now

        EvolutionRuleProposal storage proposal = _ruleProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.rule = ruleDetails;
        proposal.proposer = msg.sender;
        proposal.voteEndTime = uint64(block.timestamp) + uint64(ruleVotingPeriod);
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        proposal.state = ProposalState.Active;
        proposal.description = description;

        emit RuleProposalSubmitted(proposalId, msg.sender, description);
    }

    /// @notice Allows a Nexus Staker to vote on an active rule proposal.
    /// @param proposalId The ID of the proposal.
    /// @param vote Whether to vote yes (true) or no (false).
    function voteOnRuleProposal(uint256 proposalId, bool vote)
        public
        onlyNexusStaker
        whenNotPaused
    {
        EvolutionRuleProposal storage proposal = _ruleProposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.voteEndTime) revert VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true; // Mark voter
        if (vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit VoteCast(proposalId, msg.sender, vote);

        // Optional: Automatically execute if threshold met early
        // This requires knowing the total voting power (total staked ETH), which is not tracked globally here.
        // Execution is typically done via a separate call after the voting period ends.
    }

    /// @notice Gets details about a specific rule proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The struct containing proposal data.
    function getRuleProposalDetails(uint256 proposalId) public view returns (EvolutionRuleProposal memory) {
        EvolutionRuleProposal storage proposal = _ruleProposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();

        // Copy the struct to avoid returning storage reference with mapping
        EvolutionRuleProposal memory proposalMemory = proposal;
        // Reset hasVoted mapping in the returned struct as mappings cannot be returned externally directly
        delete proposalMemory.hasVoted;
        return proposalMemory;
    }


    /// @notice Executes a rule proposal that has passed its voting period.
    /// @dev Can be called by anyone after the voting period ends. Checks if proposal succeeded.
    /// @param proposalId The ID of the proposal to execute.
    function executeRuleProposal(uint256 proposalId)
        public
        whenNotPaused
    {
        EvolutionRuleProposal storage proposal = _ruleProposals[proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(); // Still marked Active until executed
        if (block.timestamp <= proposal.voteEndTime) revert VotingPeriodEnded();
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(); // Defensive check

        // Determine if the proposal succeeded. Example: simple majority of votes cast.
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool succeeded = false;
        if (totalVotes > 0 && proposal.yesVotes > proposal.noVotes) { // Simple majority
             // Add check for minimum number of voters if desired: && totalVotes >= minVotersRequired
             succeeded = true;
        }

        if (succeeded) {
            // Activate the rule
            uint256 ruleId = proposal.rule.ruleId; // Use the ID assigned during proposal
             if (_activeEvolutionRules[ruleId].isActive) revert RuleAlreadyActive(); // Should not happen if ruleId is unique to proposal

            _activeEvolutionRules[ruleId] = proposal.rule;
            _activeEvolutionRules[ruleId].isActive = true; // Ensure it's marked active

             // Add to the array for easy iteration
             _activeEvolutionRuleIds.push(ruleId);

            proposal.state = ProposalState.Succeeded; // Mark proposal as succeeded
            emit EvolutionRuleActivated(ruleId, proposal.rule.name);
        } else {
            proposal.state = ProposalState.Failed; // Mark proposal as failed
        }

        // Mark proposal as executed regardless of success/failure state
        // proposal.state transitions from Active -> Succeeded/Failed
        // A separate 'executed' state might be clearer if needed:
        // proposal.state = succeeded ? ProposalState.SucceededAndExecuted : ProposalState.FailedAndExecuted;

        emit RuleProposalExecuted(proposalId, succeeded);
    }


    /// @notice Gets a list of all currently active evolution rules.
    /// @return An array of EvolutionRule structs.
    function getActiveEvolutionRules() public view returns (EvolutionRule[] memory) {
        EvolutionRule[] memory activeRules = new EvolutionRule[](_activeEvolutionRuleIds.length);
        for (uint i = 0; i < _activeEvolutionRuleIds.length; i++) {
            uint256 ruleId = _activeEvolutionRuleIds[i];
            activeRules[i] = _activeEvolutionRules[ruleId];
        }
        return activeRules;
    }


    // --- Spatial & Interaction Functions ---

    /// @notice Updates the coordinates of a dimension.
    /// @dev Requires dimension ownership. May have cooldown or stake requirements in a real implementation.
    /// @param tokenId The ID of the dimension.
    /// @param newCoords The new coordinates.
    function updateDimensionalCoordinates(uint256 tokenId, DimensionalCoordinates memory newCoords)
        public
        onlyDimensionOwner(tokenId)
        whenNotPaused
    {
        Dimension storage dim = dimensions[tokenId];
        DimensionalCoordinates memory oldCoords = dim.coordinates;
        dim.coordinates = newCoords;

        // Optional: Add cooldown or check for Nexus stake for free movement
        // if (nexusStakes[msg.sender].stakedAmount < minNexusStakeAmount) {
        //     // Apply a cooldown or cost for non-stakers
        //     require(block.timestamp >= dim.lastCoordinateMoveTimestamp + coordinateMoveCooldown, "Coordinate move cooldown not passed");
        //     dim.lastCoordinateMoveTimestamp = uint64(block.timestamp);
        // }

        emit CoordinatesUpdated(tokenId, oldCoords, newCoords);
    }

    /// @notice Links two dimensions owned by the caller.
    /// @dev Links are bidirectional. Max links per dimension?
    /// @param token1 The ID of the first dimension.
    /// @param token2 The ID of the second dimension.
    function linkDimensions(uint256 token1, uint256 token2)
        public
        onlyDimensionOwner(token1) // Checks ownership of token1
        whenNotPaused
    {
        if (token1 == token2) revert CannotLinkToSelf();
        if (_ownerOf(token2) != msg.sender) revert MustOwnBothDimensionsToLink(); // Explicitly check token2 ownership

        if (_isLinked[token1][token2]) revert DimensionsAlreadyLinked();

        Dimension storage dim1 = dimensions[token1];
        Dimension storage dim2 = dimensions[token2];
         if (dim1.genesisTimestamp == 0 || dim2.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists

        // Add link to both dimensions' lists
        dim1.linkedDimensions.push(token2);
        dim2.linkedDimensions.push(token1);

        // Mark link in the mapping
        _isLinked[token1][token2] = true;
        _isLinked[token2][token1] = true;

        // Recalculate stability as links affect it
        dim1.stabilityScore = calculateStabilityScore(token1);
        dim2.stabilityScore = calculateStabilityScore(token2);


        emit DimensionsLinked(token1, token2);
    }

     /// @notice Breaks the link between two dimensions owned by the caller.
     /// @param token1 The ID of the first dimension.
     /// @param token2 The ID of the second dimension.
    function breakLink(uint256 token1, uint256 token2)
        public
        onlyDimensionOwner(token1) // Checks ownership of token1
        whenNotPaused
    {
        if (token1 == token2) revert CannotLinkToSelf();
        if (_ownerOf(token2) != msg.sender) revert MustOwnBothDimensionsToLink(); // Explicitly check token2 ownership

        if (!_isLinked[token1][token2]) revert DimensionsNotLinked();

        Dimension storage dim1 = dimensions[token1];
        Dimension storage dim2 = dimensions[token2];
         if (dim1.genesisTimestamp == 0 || dim2.genesisTimestamp == 0) revert DimensionNotFound(); // Check if exists


        // Remove link from both dimensions' lists (inefficient for large arrays)
        // A more efficient method would use mappings or linked lists for linkedDimensions
        for (uint i = 0; i < dim1.linkedDimensions.length; i++) {
            if (dim1.linkedDimensions[i] == token2) {
                dim1.linkedDimensions[i] = dim1.linkedDimensions[dim1.linkedDimensions.length - 1];
                dim1.linkedDimensions.pop();
                break; // Assuming only one link between any two
            }
        }
         for (uint i = 0; i < dim2.linkedDimensions.length; i++) {
            if (dim2.linkedDimensions[i] == token1) {
                dim2.linkedDimensions[i] = dim2.linkedDimensions[dim2.linkedDimensions.length - 1];
                dim2.linkedDimensions.pop();
                break;
            }
        }

        // Unmark link in the mapping
        delete _isLinked[token1][token2];
        delete _isLinked[token2][token1];

        // Recalculate stability
        dim1.stabilityScore = calculateStabilityScore(token1);
        dim2.stabilityScore = calculateStabilityScore(token2);


        emit LinkBroken(token1, token2);
    }

    /// @notice Gets the list of dimensions linked to a specific dimension.
    /// @param tokenId The ID of the dimension.
    /// @return An array of token IDs.
    function getLinkedDimensions(uint256 tokenId) public view returns (uint256[] memory) {
        Dimension storage dim = dimensions[tokenId];
        if (dim.genesisTimestamp == 0) revert DimensionNotFound();
        return dim.linkedDimensions; // Returns a copy
    }


    /// @notice Explores the dimensional space around a given coordinate.
    /// @dev Returns a list of dimensions within a certain proximity.
    /// @param centerCoords The coordinates to explore around.
    /// @param radius The search radius.
    /// @return An array of token IDs within the specified radius.
    function exploreDimensionalSpace(DimensionalCoordinates memory centerCoords, uint32 radius) public view returns (uint256[] memory) {
        // NOTE: This function is very inefficient on-chain for a large number of tokens.
        // Iterating through all possible token IDs is not scalable.
        // A real implementation would require an off-chain indexer or a different on-chain spatial data structure (complex!).
        // This implementation is a simplified placeholder for the concept.

        uint256[] memory nearbyDimensions = new uint256[](0); // Start with empty array

        // Iterate through all minted tokens (up to the current counter)
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            Dimension storage dim = dimensions[i];
             if (dim.genesisTimestamp == 0) continue; // Skip if token ID exists but isn't a minted dimension (e.g., if we burned)

            // Calculate distance squared to avoid sqrt in loop
            int256 dx = int256(dim.coordinates.x) - int256(centerCoords.x);
            int256 dy = int256(dim.coordinates.y) - int256(centerCoords.y);
            int256 dz = int256(dim.coordinates.z) - int256(centerCoords.z);
            int256 distanceSquared = dx * dx + dy * dy + dz * dz;

            if (distanceSquared <= int265(radius * radius)) {
                // Add dimension ID to the result array
                 uint256 currentCount = nearbyDimensions.length;
                 uint256[] memory newNearby = new uint256[](currentCount + 1);
                 for(uint j=0; j<currentCount; j++) {
                    newNearby[j] = nearbyDimensions[j];
                 }
                 newNearby[currentCount] = i;
                 nearbyDimensions = newNearby;
            }
        }
        return nearbyDimensions;
    }

    // --- Nexus Staking Functions ---

    /// @notice Stakes ETH to gain Nexus Access benefits.
    /// @dev Requires staking at least `minNexusStakeAmount`. Can add to existing stake.
    function stakeForNexusAccess() public payable whenNotPaused {
        if (msg.value == 0) revert InvalidAmount(); // Custom error needed for 0 value
        NexusStake storage stake = nexusStakes[msg.sender];
        bool isNewStake = stake.stakedAmount == 0;

        stake.stakedAmount += msg.value;
        if (isNewStake) {
            stake.stakeStartTime = uint64(block.timestamp);
        }

        emit NexusStaked(msg.sender, msg.value);
    }

    /// @notice Unstakes ETH from Nexus Access.
    /// @dev Cannot unstake if amount would fall below min stake unless unstaking all.
    /// @param amount The amount of ETH to unstake. Use type(uint256).max to unstake all.
    function unstakeFromNexus(uint256 amount) public whenNotPaused {
        NexusStake storage stake = nexusStakes[msg.sender];
        if (stake.stakedAmount == 0) revert NothingToClaim(); // Reusing error, maybe create NoActiveStake

        uint256 amountToUnstake = amount;
        if (amountToUnstake == type(uint256).max) {
            amountToUnstake = stake.stakedAmount;
        }

        if (amountToUnstake > stake.stakedAmount) revert InvalidAmount(); // Custom error needed

        uint256 remainingStake = stake.stakedAmount - amountToUnstake;

        if (remainingStake > 0 && remainingStake < minNexusStakeAmount) {
            revert InsufficientNexusStake(minNexusStakeAmount, remainingStake);
        }

        stake.stakedAmount = remainingStake;
        if (stake.stakedAmount == 0) {
            delete stake.stakeStartTime; // Reset start time if stake is zero
             // Optional: reset other stake-related state if any
        }

        (bool success, ) = payable(msg.sender).call{value: amountToUnstake}("");
        require(success, "ETH transfer failed");

        emit NexusUnstaked(msg.sender, amountToUnstake);
    }

    /// @notice Gets the staking details for an address.
    /// @param staker The address to check.
    /// @return The NexusStake struct.
    function getNexusStakeDetails(address staker) public view returns (NexusStake memory) {
        return nexusStakes[staker]; // Returns a copy
    }

     /// @notice Allows Nexus stakers to claim accumulated rewards.
     /// @dev Placeholder function. Reward logic would be complex (e.g., distributing fees, emitting a reward token).
    function claimNexusRewards() public onlyNexusStaker whenNotPaused {
        // --- Reward Logic Placeholder ---
        // Calculate rewards based on stake amount, stake duration, contract activity, etc.
        // For example: portion of mint fees, or a separate reward token distribution.
        uint256 rewardsToClaim = 0; // Placeholder calculation

        if (rewardsToClaim == 0) revert NothingToClaim();

        // Transfer rewards (ETH or a reward token)
        // (bool success, ) = payable(msg.sender).call{value: rewardsToClaim}("");
        // require(success, "Reward transfer failed");

        // Update internal state to reflect claimed rewards
        // emit RewardsClaimed(msg.sender, rewardsToClaim);

        revert("Reward claiming is not yet implemented"); // Indicate placeholder status
    }

    /// @notice Sets the minimum ETH required to stake for Nexus Access.
    /// @dev Only callable by the contract owner.
    /// @param newRequirement The new minimum stake amount in Wei.
    function setNexusStakeRequirement(uint256 newRequirement) public onlyOwner {
        minNexusStakeAmount = newRequirement;
        emit NexusStakeRequirementUpdated(newRequirement);
    }


    // --- Admin & Configuration Functions ---

    /// @notice Sets the constraints for genesis parameters during minting.
    /// @dev Only callable by the contract owner.
    /// @param constraints The new GenesisParameters constraints struct.
    function setGenesisConstraints(GenesisParameters memory constraints) public onlyOwner {
        genesisConstraints = constraints;
        emit GenesisConstraintsUpdated(constraints);
    }

    /// @notice Distributes accumulated contract fees to the fee recipient.
    /// @dev Only callable by the contract owner. Sends all available balance.
    function distributeFees() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToClaim(); // Reusing error

        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "Fee distribution failed");

        emit FeesDistributed(feeRecipient, balance);
    }

    /// @notice Sets the base URI used for generating dynamic metadata URIs.
    /// @dev Only callable by the contract owner. This should point to an off-chain service endpoint.
    /// @param baseURI The new base URI string.
    function setBaseMetadataURI(string memory baseURI) public onlyOwner {
        _baseMetadataURI = baseURI;
        emit BaseMetadataURIUpdated(baseURI);
    }

    /// @notice Pauses the contract (excluding admin functions).
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal/Helper Functions ---

     /// @dev Internal helper to convert uint256 to string (Basic implementation, consider using SafeCast or external library for robust version).
    function toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint25ge(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @dev Internal helper to convert int32 to string.
    function toString(int32 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        bool negative = value < 0;
        int32 temp = negative ? -value : value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
         if (negative) digits++; // For the '-' sign

        bytes memory buffer = new bytes(digits);
        uint256 bufferPtr = digits;

        while (temp != 0) {
            bufferPtr--;
            buffer[bufferPtr] = bytes1(uint8(48 + uint8(temp % 10)));
            temp /= 10;
        }
         if (negative) {
             bufferPtr--;
             buffer[bufferPtr] = '-';
         }

        return string(buffer);
    }


    /// @dev Simple integer square root function.
    /// @param x The number to find the square root of.
    /// @return The integer square root.
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // Required ERC721 overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
         // Optional: Re-calculate stability or perform checks if ownership affects dynamics
         // if (dimensions[tokenId].genesisTimestamp != 0) { // Check if it's a valid dimension
         //      dimensions[tokenId].stabilityScore = calculateStabilityScore(tokenId);
         // }
    }


     // The following functions are required by the ERC721 standard but are implemented
     // by inheriting ERC721 and ERC721URIStorage. Listing them explicitly confirms their presence.

     // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
     //     return super.supportsInterface(interfaceId);
     // }

     // function name() public view override(ERC721, IERC721Metadata) returns (string memory) {
     //      return super.name();
     // }

     // function symbol() public view override(ERC721, IERC721Metadata) returns (string memory) {
     //      return super.symbol();
     // }

     // function balanceOf(address owner) public view override(ERC721, IERC721) returns (uint256) {
     //      return super.balanceOf(owner);
     // }

     // function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address owner) {
     //      return super.ownerOf(tokenId);
     // }

     // function approve(address to, uint256 tokenId) public override(ERC721, IERC721) {
     //      super.approve(to, tokenId);
     // }

     // function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address operator) {
     //      return super.getApproved(tokenId);
     // }

     // function setApprovalForAll(address operator, bool _approved) public override(ERC721, IERC721) {
     //      super.setApprovalForAll(operator, _approved);
     // }

     // function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {
     //      return super.isApprovedForAll(owner, operator);
     // }

     // function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
     //      super.transferFrom(from, to, tokenId);
     // }

     // function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
     //      super.safeTransferFrom(from, to, tokenId);
     // }

      // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {
     //      super.safeTransferFrom(from, to, tokenId, data);
     // }

    // Add the following errors and they will be included in the ABI
    error InsufficientFunds();
    error InvalidAmount(); // Used in staking/unstaking
    // Redundant errors will be optimized by the compiler

}
```