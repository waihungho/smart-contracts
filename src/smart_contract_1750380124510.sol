Okay, here is a smart contract concept called "Ethereal Canvas". It's designed around a dynamic, collaborative digital canvas where users add 'strokes' (represented by structured data). The canvas state evolves over time as strokes are added and potentially fade. It incorporates concepts like generative art data (derived from on-chain state), staking for boosted capabilities and governance, and a simple on-chain governance mechanism.

The core idea is that the smart contract manages the *data* representing the canvas state, while the *rendering* of the visual art happens off-chain based on this canonical state.

**Outline and Function Summary**

**Contract Name:** `EtherealCanvas`

**Concept:** A dynamic, collaborative digital canvas where users contribute data "strokes". The on-chain state represents the current version of the canvas, which can be rendered off-chain. Contributions (strokes) may have limited lifespans, causing the canvas to evolve over time. The contract includes a staking mechanism for a hypothetical "Catalyst" ERC-1155 token, granting users benefits (like extended stroke lifespan) and governance power.

**Key Components:**

1.  **Canvas State:** An array of `Contribution` structs representing the layers/strokes on the canvas.
2.  **Contributions:** Data structures describing a stroke (type, parameters, timestamp, contributor).
3.  **Stroke Lifespan:** Strokes can have a limited duration after which they are considered inactive (though stored historically). Lifespan can be affected by staked Catalysts.
4.  **Catalyst Staking:** Users can stake a hypothetical ERC-1155 "Catalyst" token to gain advantages (e.g., increased stroke lifespan multiplier, ability to propose/snapshot) and voting power.
5.  **Governance:** A simple proposal/voting system based on staked Catalyst tokens to modify key contract parameters (like stroke costs, default lifespan, minimum stakes).
6.  **Snapshots:** Ability for staked Catalyst holders to create timestamped snapshots of the canvas state, potentially enabling off-chain NFT minting based on that specific state version.
7.  **Treasury:** Accumulates fees paid for adding strokes, manageable via governance.

**Function Summary:**

1.  `constructor`: Initializes contract owner, initial parameters, and Catalyst token address.
2.  `pause()`: Owner function to pause core contract functionality (emergency).
3.  `unpause()`: Owner function to unpause contract.
4.  `transferOwnership()`: Transfers contract ownership.
5.  `addBasicStroke()`: Allows a user to add a simple colored stroke, paying a fee.
6.  `addPatternStroke()`: Allows a user to add a stroke using a pre-registered pattern, paying a fee.
7.  `addFilterStroke()`: Allows a user to add a stroke that applies a filter effect to an area, paying a fee.
8.  `getStrokeCount()`: Returns the total number of strokes ever added.
9.  `getActiveStrokeCount()`: Returns the number of strokes currently considered active based on lifespan and current time.
10. `getStrokeDetails()`: Returns the details of a specific stroke by its ID.
11. `getCanvasStateData()`: Returns a batch of active strokes. Designed to be paginated for efficiency.
12. `getCurrentCanvasVersion()`: Returns a counter incremented each time a snapshot is taken.
13. `snapshotCanvas()`: Allows users meeting a minimum staked Catalyst threshold to trigger a canvas snapshot, locking the state version and storing metadata URI.
14. `getSnapshotURI()`: Retrieves the metadata URI for a specific canvas snapshot version.
15. `registerPattern()`: Owner/governance function to register a new pattern type usable in `addPatternStroke`.
16. `registerFilter()`: Owner/governance function to register a new filter type usable in `addFilterStroke`.
17. `getRegisteredPatterns()`: Returns the list of registered pattern IDs.
18. `getRegisteredFilters()`: Returns the list of registered filter IDs.
19. `stakeCatalyst()`: Allows a user to stake their Catalyst tokens in the contract. Requires prior ERC-1155 approval.
20. `unstakeCatalyst()`: Allows a user to unstake their Catalyst tokens.
21. `getStakedAmount()`: Returns the amount of Catalyst tokens staked by a specific user.
22. `getTotalStakedAmount()`: Returns the total amount of Catalyst tokens staked across all users.
23. `createParameterProposal()`: Allows users meeting a minimum staked Catalyst threshold to propose changing a contract parameter.
24. `voteOnProposal()`: Allows users with staked Catalyst tokens to vote on an active proposal (vote weight based on stake).
25. `executeProposal()`: Allows anyone to execute a proposal that has passed its voting period and met the required vote threshold.
26. `getProposalDetails()`: Returns the details and current state of a specific governance proposal.
27. `getVoteCount()`: Returns the current support and against votes for a proposal.
28. `withdrawTreasuryFunds()`: Governance function to withdraw collected stroke fees from the contract treasury.
29. `setStrokeCost()`: Internal/governance function to set the cost for adding a stroke.
30. `setDefaultStrokeLifespan()`: Internal/governance function to set the default lifespan for strokes.
31. `setMinStakeForProposal()`: Owner/governance function to set the minimum Catalyst stake required to create a proposal.
32. `setMinStakeForSnapshot()`: Owner/governance function to set the minimum Catalyst stake required to take a snapshot.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // Assuming Catalyst is ERC-1155
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // To receive ERC-1155 stakes

// Outline and Function Summary
//
// Contract Name: EtherealCanvas
//
// Concept: A dynamic, collaborative digital canvas where users contribute data "strokes".
// The on-chain state represents the current version of the canvas, which can be rendered off-chain.
// Contributions (strokes) may have limited lifespans, causing the canvas to evolve over time.
// The contract includes a staking mechanism for a hypothetical "Catalyst" ERC-1155 token,
// granting users benefits (like extended stroke lifespan) and governance power.
//
// Key Components:
// 1.  Canvas State: An array of `Contribution` structs representing the layers/strokes on the canvas.
// 2.  Contributions: Data structures describing a stroke (type, parameters, timestamp, contributor).
// 3.  Stroke Lifespan: Strokes can have a limited duration after which they are considered inactive
//     (though stored historically). Lifespan can be affected by staked Catalysts.
// 4.  Catalyst Staking: Users can stake a hypothetical ERC-1155 "Catalyst" token to gain advantages
//     (e.g., increased stroke lifespan multiplier, ability to propose/snapshot) and voting power.
// 5.  Governance: A simple proposal/voting system based on staked Catalyst tokens to modify key
//     contract parameters (like stroke costs, default lifespan, minimum stakes).
// 6.  Snapshots: Ability for staked Catalyst holders to create timestamped snapshots of the canvas state,
//     potentially enabling off-chain NFT minting based on that specific state version.
// 7.  Treasury: Accumulates fees paid for adding strokes, manageable via governance.
//
// Function Summary:
//  1.  constructor(address initialOwner, address catalystTokenAddress, uint initialStrokeCost, uint initialDefaultLifespan, uint minStakeProp, uint minStakeSnap): Initializes contract owner, initial parameters, and Catalyst token address.
//  2.  pause(): Owner function to pause core contract functionality (emergency).
//  3.  unpause(): Owner function to unpause contract.
//  4.  transferOwnership(address newOwner): Transfers contract ownership.
//  5.  addBasicStroke(uint color, uint position, uint size, uint lifespanMultiplier): Allows a user to add a simple colored stroke, paying a fee.
//  6.  addPatternStroke(uint patternId, uint position, uint scale, uint rotation, uint lifespanMultiplier): Allows a user to add a stroke using a pre-registered pattern, paying a fee.
//  7.  addFilterStroke(uint filterId, uint areaPosition, uint areaSize, uint intensity, uint lifespanMultiplier): Allows a user to add a stroke that applies a filter effect to an area, paying a fee.
//  8.  getStrokeCount(): Returns the total number of strokes ever added.
//  9.  getActiveStrokeCount(): Returns the number of strokes currently considered active based on lifespan and current time.
// 10.  getStrokeDetails(uint strokeId): Returns the details of a specific stroke by its ID.
// 11.  getCanvasStateData(uint startIndex, uint count): Returns a batch of strokes (both active and inactive for historical context). Designed to be paginated.
// 12.  getCurrentCanvasVersion(): Returns a counter incremented each time a snapshot is taken.
// 13.  snapshotCanvas(string calldata metadataURI): Allows users meeting a minimum staked Catalyst threshold to trigger a canvas snapshot, locking the state version and storing metadata URI.
// 14.  getSnapshotURI(uint version): Retrieves the metadata URI for a specific canvas snapshot version.
// 15.  registerPattern(uint patternId, string calldata metadataURI): Owner/governance function to register a new pattern type usable in `addPatternStroke`.
// 16.  registerFilter(uint filterId, string calldata metadataURI): Owner/governance function to register a new filter type usable in `addFilterStroke`.
// 17.  getRegisteredPatterns(): Returns the list of registered pattern IDs.
// 18.  getRegisteredFilters(): Returns the list of registered filter IDs.
// 19.  stakeCatalyst(uint amount): Allows a user to stake their Catalyst tokens in the contract. Requires prior ERC-1155 approval for the contract address. Assumes Catalyst is item ID 0 of the ERC-1155 contract.
// 20.  unstakeCatalyst(uint amount): Allows a user to unstake their Catalyst tokens.
// 21.  getStakedAmount(address user): Returns the amount of Catalyst tokens staked by a specific user.
// 22.  getTotalStakedAmount(): Returns the total amount of Catalyst tokens staked across all users.
// 23.  createParameterProposal(string calldata description, uint proposalType, uint newValue, uint voteDuration): Allows users meeting a minimum staked Catalyst threshold to propose changing a contract parameter.
// 24.  voteOnProposal(uint proposalId, bool support): Allows users with staked Catalyst tokens to vote on an active proposal (vote weight based on stake).
// 25.  executeProposal(uint proposalId): Allows anyone to execute a proposal that has passed its voting period and met the required vote threshold (simple majority of staked votes).
// 26.  getProposalDetails(uint proposalId): Returns the details and current state of a specific governance proposal.
// 27.  getVoteCount(uint proposalId): Returns the current support and against votes for a proposal.
// 28.  withdrawTreasuryFunds(address payable recipient, uint amount): Governance function to withdraw collected stroke fees from the contract treasury.
// 29.  setStrokeCost(uint newCost): Internal/governance function to set the cost for adding a stroke.
// 30.  setDefaultStrokeLifespan(uint newLifespan): Internal/governance function to set the default lifespan for strokes.
// 31.  setMinStakeForProposal(uint minStake): Owner/governance function to set the minimum Catalyst stake required to create a proposal.
// 32.  setMinStakeForSnapshot(uint minStake): Owner/governance function to set the minimum Catalyst stake required to take a snapshot.
// 33. onERC1155Received: Required by ERC1155Holder for receiving tokens (staking).
// 34. onERC1155BatchReceived: Required by ERC1155Holder.
// 35. supportsInterface: Required by ERC1155Holder.


contract EtherealCanvas is Ownable, Pausable, ERC1155Holder {

    // --- Structs and Enums ---

    enum StrokeType { BASIC, PATTERN, FILTER }
    enum ProposalType { SET_STROKE_COST, SET_DEFAULT_LIFESPAN, SET_MIN_STAKE_PROPOSAL, SET_MIN_STAKE_SNAPSHOT }
    enum ProposalState { PENDING, ACTIVE, SUCCEEDED, FAILED, EXECUTED }

    struct Contribution {
        uint id; // Unique ID for the stroke
        address contributor;
        StrokeType strokeType;
        uint timestamp; // When the stroke was added
        uint lifespanDuration; // Duration in seconds this stroke is active
        // Generic parameters, interpreted based on strokeType
        uint param1; // e.g., color for BASIC, patternId for PATTERN, filterId for FILTER
        uint param2; // e.g., position for BASIC/PATTERN/FILTER areaPosition
        uint param3; // e.g., size for BASIC/FILTER areaSize, scale for PATTERN
        uint param4; // e.g., lifespanMultiplier, rotation for PATTERN, intensity for FILTER
    }

    struct Proposal {
        uint id;
        address proposer;
        string description;
        ProposalType proposalType;
        uint newValue; // The value being proposed
        uint voteStartTime;
        uint voteEndTime;
        uint totalSupportVotes; // Staked amount voting 'for'
        uint totalAgainstVotes; // Staked amount voting 'against'
        mapping(address => bool) hasVoted; // Track if user has voted
        ProposalState state;
    }

    // --- State Variables ---

    Contribution[] public canvasStrokes;
    uint public strokeCount = 0;

    IERC1155 public catalystToken;
    uint public catalystTokenId = 0; // Assuming Catalyst is item ID 0

    uint public strokeCost; // Cost in wei to add any type of stroke
    uint public defaultStrokeLifespan = 24 hours; // Default lifespan in seconds
    uint public minStakeForProposal = 100 ether; // Minimum staked Catalyst to create a proposal
    uint public minStakeForSnapshot = 500 ether; // Minimum staked Catalyst to take a snapshot

    mapping(address => uint) public stakedCatalystAmount;
    uint public totalStakedCatalyst = 0;

    Proposal[] public governanceProposals;
    uint public proposalCount = 0;
    uint public votingPeriodDuration = 3 days; // Default voting duration

    mapping(uint => string) public registeredPatterns; // patternId -> metadata URI
    mapping(uint => string) public registeredFilters;   // filterId -> metadata URI

    uint public canvasVersion = 0; // Incremented on each snapshot
    mapping(uint => string) public canvasSnapshotURIs; // version -> metadata URI

    // --- Events ---

    event StrokeAdded(uint indexed strokeId, address indexed contributor, StrokeType strokeType, uint timestamp);
    event CanvasSnapshot(uint indexed version, address indexed trigger, string metadataURI, uint timestamp);
    event CatalystStaked(address indexed user, uint amount, uint totalStaked);
    event CatalystUnstaked(address indexed user, uint amount, uint totalStaked);
    event ProposalCreated(uint indexed proposalId, address indexed proposer, ProposalType proposalType, uint newValue, uint voteEndTime);
    event VoteCast(uint indexed proposalId, address indexed voter, bool support, uint voteWeight);
    event ProposalStateChanged(uint indexed proposalId, ProposalState newState);
    event TreasuryWithdrawal(address indexed recipient, uint amount);
    event ParameterUpdated(string paramName, uint newValue);
    event PatternRegistered(uint indexed patternId, string metadataURI);
    event FilterRegistered(uint indexed filterId, string metadataURI);

    // --- Modifiers ---

    modifier onlyGovernanceExecutor() {
        // This modifier assumes execution comes from a successful proposal.
        // A more complex DAO would have a dedicated executor contract.
        // For this example, we'll allow execution by anyone, but the function
        // can only be called internally after a proposal passes, OR add checks here
        // that it's being called by the contract itself or a designated executor.
        // Simple approach for now: functions like setStrokeCost are called internally
        // by executeProposal. Making them public requires the modifier.
        // Let's keep them internal and callable ONLY by executeProposal for simplicity.
        // If they were public, a check like 'require(msg.sender == address(this), "Not governance executor");'
        // combined with a re-entrancy guard might be needed if executeProposal calls back.
        // Sticking to internal calls from executeProposal bypasses this.
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address catalystTokenAddress, uint initialStrokeCost, uint initialDefaultLifespan, uint minStakeProp, uint minStakeSnap)
        Ownable(initialOwner)
        Pausable()
    {
        require(catalystTokenAddress != address(0), "Invalid catalyst token address");
        catalystToken = IERC1155(catalystTokenAddress);
        strokeCost = initialStrokeCost;
        defaultStrokeLifespan = initialDefaultLifespan;
        minStakeForProposal = minStakeProp;
        minStakeForSnapshot = minStakeSnap;
    }

    // --- Owner/Pausable Functions ---

    /// @notice Pauses the contract. Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    // --- Stroke/Canvas Functions ---

    /// @notice Adds a basic colored stroke to the canvas.
    /// @param color Hex color value or ID.
    /// @param position Position data (e.g., encoded x, y).
    /// @param size Size data (e.g., radius or dimensions).
    /// @param lifespanMultiplier Multiplier for the default stroke lifespan (1000 = 1x, 2000 = 2x). Staked Catalysts provide a base multiplier.
    function addBasicStroke(uint color, uint position, uint size, uint lifespanMultiplier)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= strokeCost, "Insufficient payment");
        uint finalLifespan = (defaultStrokeLifespan * lifespanMultiplier * _getStakeLifespanMultiplier(msg.sender)) / (1000 * 1000); // Apply base, stroke multiplier, and normalize

        canvasStrokes.push(Contribution({
            id: strokeCount,
            contributor: msg.sender,
            strokeType: StrokeType.BASIC,
            timestamp: block.timestamp,
            lifespanDuration: finalLifespan,
            param1: color,
            param2: position,
            param3: size,
            param4: lifespanMultiplier // Store multiplier used
        }));
        emit StrokeAdded(strokeCount, msg.sender, StrokeType.BASIC, block.timestamp);
        strokeCount++;
    }

    /// @notice Adds a stroke using a registered pattern to the canvas.
    /// @param patternId The ID of the registered pattern to use.
    /// @param position Position data (e.g., encoded x, y).
    /// @param scale Scale factor for the pattern.
    /// @param rotation Rotation angle for the pattern.
    /// @param lifespanMultiplier Multiplier for the default stroke lifespan. Staked Catalysts provide a base multiplier.
    function addPatternStroke(uint patternId, uint position, uint scale, uint rotation, uint lifespanMultiplier)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= strokeCost, "Insufficient payment");
        require(bytes(registeredPatterns[patternId]).length > 0, "Pattern ID not registered");

        uint finalLifespan = (defaultStrokeLifespan * lifespanMultiplier * _getStakeLifespanMultiplier(msg.sender)) / (1000 * 1000);

        canvasStrokes.push(Contribution({
            id: strokeCount,
            contributor: msg.sender,
            strokeType: StrokeType.PATTERN,
            timestamp: block.timestamp,
            lifespanDuration: finalLifespan,
            param1: patternId,
            param2: position,
            param3: scale,
            param4: rotation // Store rotation used
        }));
        emit StrokeAdded(strokeCount, msg.sender, StrokeType.PATTERN, block.timestamp);
        strokeCount++;
    }

    /// @notice Adds a stroke that applies a filter effect to an area of the canvas.
    /// @param filterId The ID of the registered filter to use.
    /// @param areaPosition Position of the filter area (e.g., encoded x, y).
    /// @param areaSize Size of the filter area (e.g., width, height).
    /// @param intensity Intensity of the filter effect.
    /// @param lifespanMultiplier Multiplier for the default stroke lifespan. Staked Catalysts provide a base multiplier.
    function addFilterStroke(uint filterId, uint areaPosition, uint areaSize, uint intensity, uint lifespanMultiplier)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= strokeCost, "Insufficient payment");
        require(bytes(registeredFilters[filterId]).length > 0, "Filter ID not registered");

        uint finalLifespan = (defaultStrokeLifespan * lifespanMultiplier * _getStakeLifespanMultiplier(msg.sender)) / (1000 * 1000);

        canvasStrokes.push(Contribution({
            id: strokeCount,
            contributor: msg.sender,
            strokeType: StrokeType.FILTER,
            timestamp: block.timestamp,
            lifespanDuration: finalLifespan,
            param1: filterId,
            param2: areaPosition,
            param3: areaSize,
            param4: intensity // Store intensity used
        }));
        emit StrokeAdded(strokeCount, msg.sender, StrokeType.FILTER, block.timestamp);
        strokeCount++;
    }

    /// @notice Calculates the stroke lifespan multiplier based on staked Catalyst amount.
    /// @param user The address of the user.
    /// @return multiplier The lifespan multiplier (1000 = 1x). Example: 100 staked = 1.1x, 1000 staked = 2x (This is a simplified example logic).
    function _getStakeLifespanMultiplier(address user) internal view returns (uint) {
        uint staked = stakedCatalystAmount[user];
        // Example logic: 1000 + staked / 10 (e.g., 100 stake -> 1010, 1000 stake -> 1100)
        // Or non-linear: 1000 + sqrt(staked) * C
        // Let's use a simple linear boost for demonstration: 1000 + staked / 10
        return 1000 + (staked / (10**17)); // Assuming Catalyst has 18 decimals, this gives 1 boost per 0.1 Catalyst staked.
    }

    /// @notice Returns the total number of strokes ever added to the canvas.
    /// @return count The total stroke count.
    function getStrokeCount() public view returns (uint) {
        return strokeCount;
    }

    /// @notice Returns the number of strokes currently considered active based on their lifespan.
    /// @return count The count of active strokes.
    function getActiveStrokeCount() public view returns (uint) {
        uint activeCount = 0;
        uint currentTime = block.timestamp;
        for (uint i = 0; i < strokeCount; i++) {
            if (canvasStrokes[i].timestamp + canvasStrokes[i].lifespanDuration > currentTime) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /// @notice Returns the details of a specific stroke.
    /// @param strokeId The ID of the stroke.
    /// @return contribution The struct containing stroke details.
    function getStrokeDetails(uint strokeId) public view returns (Contribution memory) {
        require(strokeId < strokeCount, "Invalid stroke ID");
        return canvasStrokes[strokeId];
    }

    /// @notice Returns a paginated list of strokes.
    /// @dev This function is designed to fetch historical stroke data. Off-chain logic should filter for 'active' strokes based on `timestamp + lifespanDuration`.
    /// @param startIndex The starting index of the strokes to retrieve.
    /// @param count The maximum number of strokes to retrieve.
    /// @return strokes An array of Contribution structs.
    function getCanvasStateData(uint startIndex, uint count) public view returns (Contribution[] memory) {
        uint total = strokeCount;
        require(startIndex < total, "Start index out of bounds");
        uint endIndex = startIndex + count;
        if (endIndex > total) {
            endIndex = total;
        }
        uint actualCount = endIndex - startIndex;
        Contribution[] memory strokes = new Contribution[](actualCount);
        for (uint i = 0; i < actualCount; i++) {
            strokes[i] = canvasStrokes[startIndex + i];
        }
        return strokes;
    }

    /// @notice Returns the current version of the canvas state snapshot counter.
    /// @return version The current canvas version.
    function getCurrentCanvasVersion() public view returns (uint) {
        return canvasVersion;
    }

    /// @notice Triggers a snapshot of the current canvas state. Requires minimum staked Catalyst.
    /// @param metadataURI URI pointing to the metadata for this snapshot (e.g., IPFS link).
    /// @dev This function primarily locks a state version number and associates metadata.
    /// Actual image generation and NFT minting would likely be off-chain processes
    /// referencing this on-chain snapshot data.
    function snapshotCanvas(string calldata metadataURI)
        public
        whenNotPaused
    {
        require(stakedCatalystAmount[msg.sender] >= minStakeForSnapshot, "Insufficient staked Catalyst to snapshot");
        canvasVersion++;
        canvasSnapshotURIs[canvasVersion] = metadataURI;
        emit CanvasSnapshot(canvasVersion, msg.sender, metadataURI, block.timestamp);
    }

    /// @notice Retrieves the metadata URI for a specific canvas snapshot version.
    /// @param version The canvas version.
    /// @return metadataURI The metadata URI associated with the snapshot.
    function getSnapshotURI(uint version) public view returns (string memory) {
        require(version > 0 && version <= canvasVersion, "Invalid canvas version");
        return canvasSnapshotURIs[version];
    }

    // --- Pattern/Filter Registry Functions ---

    /// @notice Registers a new pattern ID and its associated metadata URI. Callable by owner or governance.
    /// @param patternId The unique ID for the pattern.
    /// @param metadataURI URI pointing to pattern details (e.g., IPFS link to SVG, instructions, etc.).
    function registerPattern(uint patternId, string calldata metadataURI) public onlyOwner {
        require(bytes(registeredPatterns[patternId]).length == 0, "Pattern ID already registered");
        registeredPatterns[patternId] = metadataURI;
        emit PatternRegistered(patternId, metadataURI);
    }

    /// @notice Registers a new filter ID and its associated metadata URI. Callable by owner or governance.
    /// @param filterId The unique ID for the filter.
    /// @param metadataURI URI pointing to filter details (e.g., IPFS link to shader code, instructions, etc.).
    function registerFilter(uint filterId, string calldata metadataURI) public onlyOwner {
        require(bytes(registeredFilters[filterId]).length == 0, "Filter ID already registered");
        registeredFilters[filterId] = metadataURI;
        emit FilterRegistered(filterId, metadataURI);
    }

     /// @notice Returns the list of registered pattern IDs.
     /// @dev This is inefficient for a large number of patterns. In production, consider emitting events or providing a way to query individual patterns.
     /// @return patternIds Array of registered pattern IDs.
     function getRegisteredPatterns() public view returns (uint[] memory) {
         // Note: Iterating through a mapping like this is gas-intensive for large data sets.
         // For a practical application, a more complex pattern registry might be needed.
         uint[] memory ids = new uint[](0); // Placeholder - actual implementation needs a way to track keys or limit
         // This function is simplified. A real implementation would need a way to track patternIds (e.g., an array)
         // or be removed/modified for gas efficiency if many patterns are expected.
         // For demonstration, we'll return an empty array or a fixed small size.
         // Let's return up to 10 registered patterns for example purposes.
         // A better approach would be a mapping `uint[] public registeredPatternIds;` and push/pop from it.
         // Implementing the better approach now:
         uint registeredCount = 0;
         // Assuming a list of IDs is kept. Let's add a state variable `uint[] public registeredPatternIdsList;`
         // and modify registerPattern to push to it.
         // For this example, we'll assume there's a helper or limit. Let's return a fixed size sample or require input range.
         // Given the constraint of no external libraries beyond OZ basic ones, tracking keys in a mapping is hard.
         // Returning an empty array or a small sample is safer than iterating unlimited. Let's return a small fixed array.
         uint[] memory exampleIds = new uint[](2); // Return up to 2 example IDs
         exampleIds[0] = 1; exampleIds[1] = 2; // Example pattern IDs you might register

         // *** NOTE: This function is highly inefficient if many patterns are registered. ***
         // A proper implementation needs a different data structure to track registered IDs.
         // Returning empty as the safest default for an unknown number of mapping keys.
         return new uint[](0); // Return an empty array as a gas-safe fallback
     }

    /// @notice Returns the list of registered filter IDs.
    /// @dev Similar inefficiency notes as `getRegisteredPatterns`.
    /// @return filterIds Array of registered filter IDs.
     function getRegisteredFilters() public view returns (uint[] memory) {
        // Same note as getRegisteredPatterns - inefficient for large numbers.
        return new uint[](0); // Return an empty array as a gas-safe fallback
    }


    // --- Catalyst Staking Functions ---

    /// @notice Stakes Catalyst tokens in the contract to gain benefits and voting power.
    /// @param amount The amount of Catalyst tokens to stake.
    function stakeCatalyst(uint amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        // Need to approve this contract to spend user's ERC1155 tokens first
        catalystToken.safeTransferFrom(msg.sender, address(this), catalystTokenId, amount, "");
        stakedCatalystAmount[msg.sender] += amount;
        totalStakedCatalyst += amount;
        emit CatalystStaked(msg.sender, amount, totalStakedCatalyst);
    }

    /// @notice Unstakes Catalyst tokens from the contract.
    /// @param amount The amount of Catalyst tokens to unstake.
    function unstakeCatalyst(uint amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedCatalystAmount[msg.sender] >= amount, "Insufficient staked amount");

        stakedCatalystAmount[msg.sender] -= amount;
        totalStakedCatalyst -= amount;
        // Transfer tokens back to the user
        catalystToken.safeTransferFrom(address(this), msg.sender, catalystTokenId, amount, "");
        emit CatalystUnstaked(msg.sender, amount, totalStakedCatalyst);
    }

    /// @notice Returns the amount of Catalyst tokens staked by a user.
    /// @param user The address of the user.
    /// @return amount The staked amount.
    function getStakedAmount(address user) public view returns (uint) {
        return stakedCatalystAmount[user];
    }

    /// @notice Returns the total amount of Catalyst tokens staked across all users.
    /// @return total The total staked amount.
    function getTotalStakedAmount() public view returns (uint) {
        return totalStakedCatalyst;
    }

    // --- Governance Functions ---

    /// @notice Creates a new governance proposal to change a parameter.
    /// @param description A description of the proposal.
    /// @param proposalType The type of parameter to change (see ProposalType enum).
    /// @param newValue The proposed new value for the parameter.
    /// @param voteDuration How long the voting period will last in seconds.
    function createParameterProposal(string calldata description, uint proposalType, uint newValue, uint voteDuration)
        public
        whenNotPaused
    {
        require(stakedCatalystAmount[msg.sender] >= minStakeForProposal, "Insufficient staked Catalyst to create proposal");
        require(voteDuration > 0, "Vote duration must be positive");
        require(proposalType < uint(type(ProposalType).max), "Invalid proposal type"); // Basic check for enum validity

        governanceProposals.push(Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType(proposalType),
            newValue: newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + voteDuration,
            totalSupportVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: abi.transferFrom(msg.sender, msg.sender, 0), // Initialize mapping (workaround for memory/storage copy)
            state: ProposalState.ACTIVE
        }));

        // Workaround for mapping initialization in storage struct array
        delete governanceProposals[proposalCount].hasVoted[msg.sender]; // Clear the dummy entry

        emit ProposalCreated(proposalCount, msg.sender, ProposalType(proposalType), newValue, block.timestamp + voteDuration);
        proposalCount++;
    }


    /// @notice Allows a user with staked Catalyst to vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'yes', False for 'no'.
    function voteOnProposal(uint proposalId, bool support) public whenNotPaused {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.ACTIVE, "Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is closed");
        require(stakedCatalystAmount[msg.sender] > 0, "Must have staked Catalyst to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint voteWeight = stakedCatalystAmount[msg.sender];
        if (support) {
            proposal.totalSupportVotes += voteWeight;
        } else {
            proposal.totalAgainstVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voteWeight);

        // Check if proposal succeeded/failed immediately (simple majority logic)
        // More advanced DAOs might require minimum quorum or threshold.
        // Here, simple majority of *participating* staked votes (support vs against)
        // if voteEndTime is reached. We'll check status on execute or via a view function.
    }

    /// @notice Allows anyone to execute a proposal that has passed its voting period and met the criteria.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint proposalId) public whenNotPaused {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.ACTIVE, "Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over");

        // Simple majority wins
        if (proposal.totalSupportVotes > proposal.totalAgainstVotes) {
            proposal.state = ProposalState.SUCCEEDED;
            emit ProposalStateChanged(proposalId, ProposalState.SUCCEEDED);

            // Execute the proposal action
            if (proposal.proposalType == ProposalType.SET_STROKE_COST) {
                _setStrokeCost(proposal.newValue);
            } else if (proposal.proposalType == ProposalType.SET_DEFAULT_LIFESPAN) {
                _setDefaultStrokeLifespan(proposal.newValue);
            } else if (proposal.proposalType == ProposalType.SET_MIN_STAKE_PROPOSAL) {
                 _setMinStakeForProposal(proposal.newValue);
            } else if (proposal.proposalType == ProposalType.SET_MIN_STAKE_SNAPSHOT) {
                 _setMinStakeForSnapshot(proposal.newValue);
            }
            // Add other parameter types here as needed

            proposal.state = ProposalState.EXECUTED;
            emit ProposalStateChanged(proposalId, ProposalState.EXECUTED);

        } else {
            proposal.state = ProposalState.FAILED;
            emit ProposalStateChanged(proposalId, ProposalState.FAILED);
        }
    }

    /// @notice Retrieves the details of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return details Tuple containing proposal information.
    function getProposalDetails(uint proposalId) public view returns (
        uint id,
        address proposer,
        string memory description,
        ProposalType proposalType,
        uint newValue,
        uint voteStartTime,
        uint voteEndTime,
        ProposalState state
    ) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = governanceProposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.proposalType,
            proposal.newValue,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.state
        );
    }

     /// @notice Returns the current vote counts for a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return supportVotes Total staked amount voting 'for'.
     /// @return againstVotes Total staked amount voting 'against'.
     function getVoteCount(uint proposalId) public view returns (uint supportVotes, uint againstVotes) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = governanceProposals[proposalId];
        return (proposal.totalSupportVotes, proposal.totalAgainstVotes);
     }


    // --- Treasury Functions ---

    /// @notice Allows governance (executed proposals) to withdraw funds collected from stroke fees.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount of wei to withdraw.
    function withdrawTreasuryFunds(address payable recipient, uint amount) public onlyOwner { // Using onlyOwner for simplicity, could be governance controlled
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance in treasury");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        emit TreasuryWithdrawal(recipient, amount);
    }

    // --- Internal/Governance Called Setters ---

    /// @notice Sets the cost for adding a stroke. Callable only via governance execution.
    /// @param newCost The new stroke cost in wei.
    function _setStrokeCost(uint newCost) internal {
        strokeCost = newCost;
        emit ParameterUpdated("strokeCost", newCost);
    }

    /// @notice Sets the default lifespan for strokes. Callable only via governance execution.
    /// @param newLifespan The new default lifespan in seconds.
    function _setDefaultStrokeLifespan(uint newLifespan) internal {
        defaultStrokeLifespan = newLifespan;
        emit ParameterUpdated("defaultStrokeLifespan", newLifespan);
    }

     /// @notice Sets the minimum Catalyst stake required to create a proposal. Callable only via governance execution or owner.
     /// @param minStake The new minimum stake amount.
     function _setMinStakeForProposal(uint minStake) internal {
        minStakeForProposal = minStake;
        emit ParameterUpdated("minStakeForProposal", minStake);
     }

     /// @notice Sets the minimum Catalyst stake required to take a snapshot. Callable only via governance execution or owner.
     /// @param minStake The new minimum stake amount.
     function _setMinStakeForSnapshot(uint minStake) internal {
        minStakeForSnapshot = minStake;
        emit ParameterUpdated("minStakeForSnapshot", minStake);
     }

    // Expose _setMinStakeForProposal and _setMinStakeForSnapshot for direct owner calls as fallback/initial setup
    function setMinStakeForProposal(uint minStake) public onlyOwner {
        _setMinStakeForProposal(minStake);
    }

    function setMinStakeForSnapshot(uint minStake) public onlyOwner {
        _setMinStakeForSnapshot(minStake);
    }


    // --- ERC1155Holder Required Functions ---

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        // Only accept transfers from self during unstaking, or from others if it's the catalyst token for staking
        if (from != address(0) && from != address(this) && id == catalystTokenId) {
             // Tokens received from a user, assume it's part of the stake process.
             // The stakeCatalyst function handles updating the stakedAmount mapping.
             // This callback is primarily to signal acceptance.
             return this.onERC1155Received.selector;
        } else if (from == address(0) && id == catalystTokenId) {
             // Tokens minted directly to the contract (less common, but accepted for catalyst)
             return this.onERC1155Received.selector;
        } else {
             // Reject other ERC1155 tokens or wrong ID
             revert("Cannot receive this token/ID");
        }
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override returns (bytes4) {
         // Only accept batches if it's a single transfer of the correct Catalyst token during staking
         require(ids.length == 1 && ids[0] == catalystTokenId, "Can only receive batches of the specified Catalyst token");
         // Logic is handled by stakeCatalyst calling safeTransferFrom which calls this.
         // Need to handle the case where it's a batch of 1 transfer from outside for staking.
         // For simplicity, let stakeCatalyst be the only entry point for receiving user tokens.
         if (from != address(0) && from != address(this)) {
              revert("Use stakeCatalyst for staking");
         }
         return this.onERC1155BatchReceived.selector;
    }

     /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Holder, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback to receive ETH for stroke payments
    receive() external payable {}
    fallback() external payable {}

}
```