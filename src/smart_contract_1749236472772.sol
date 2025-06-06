Okay, let's create a smart contract that models a decentralized, evolving chronicle of AI-generated concepts or "Fragments". This contract will manage the creation, evolution, voting, and decay of these fragments, interacting with an off-chain AI oracle and incorporating basic rule governance.

It's interesting because it blends on-chain state management with off-chain AI processing. It's advanced due to the oracle pattern, complex state evolution, and rule parameters. It's creative in how it models concepts like quality decay and evolutionary lineage. It's trendy by touching on AI and potentially serving as a base for NFTs or decentralized knowledge bases.

**Disclaimer:** This is a complex concept. A production-ready contract would require extensive testing, gas optimization, robust error handling, a more sophisticated oracle implementation (like Chainlink), potentially upgradeability patterns (Proxies), and careful consideration of griefing vectors and economic incentives. This implementation focuses on demonstrating the *logic* and function count requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EternalAIChronicles
 * @notice A smart contract for managing a decentralized, evolving chronicle of AI-generated fragments.
 * Fragments are pieces of concepts or lore. They are created and evolved via an AI Oracle.
 * Users can vote on fragment quality, which can decay over time.
 * Contract rules can be updated via a simple steward-based governance mechanism.
 * This contract acts as the state manager and rule enforcer for the chronicle.
 */

/**
 * Outline:
 * 1. License and Pragma
 * 2. Error Definitions
 * 3. Event Definitions
 * 4. Struct Definitions (Fragment)
 * 5. State Variables
 * 6. Access Control Modifiers
 * 7. Constructor
 * 8. Setup and Role Management Functions (Owner, Stewards, Oracles) - ~5 functions
 * 9. Oracle Interaction Functions (Requesting & Receiving AI results) - ~4 functions
 * 10. Fragment Management Functions (Minting, Evolution, Decay, Voting) - ~7 functions
 * 11. Query/Read Functions (Retrieving Fragment data, counts, lists) - ~5 functions
 * 12. Rule Management Functions (Updating contract parameters) - ~2 functions
 * 13. Utility Functions - ~2 functions
 * Total: ~25+ functions
 */

/**
 * Function Summary:
 *
 * Setup and Role Management:
 * - constructor(): Initializes contract owner and core roles.
 * - setOracleAddress(address newOracle): Sets the address of the trusted AI Oracle contract. (Owner only)
 * - addSteward(address steward): Adds an address to the list of stewards. (Owner only)
 * - removeSteward(address steward): Removes an address from the list of stewards. (Owner only)
 * - addOracle(address oracle): Adds an address to the list of authorized oracles. (Owner only)
 * - removeOracle(address oracle): Removes an address from the list of authorized oracles. (Owner only)
 *
 * Oracle Interaction:
 * - proposeFragmentCreation(string memory initialPromptHash): Initiates AI creation via oracle. (Any user)
 * - proposeFragmentEvolution(uint256 parentFragmentId, string memory evolutionPromptHash): Initiates AI evolution via oracle. (Any user)
 * - receiveFragmentCreationResult(uint256 requestId, address requester, string memory resultContentHash, uint256 initialQuality): Callback from Oracle to finalize creation. (Only Oracle)
 * - receiveFragmentEvolutionResult(uint256 requestId, address requester, uint256 parentFragmentId, string memory resultContentHash, uint256 evolutionStageIncrease): Callback from Oracle to finalize evolution. (Only Oracle)
 *
 * Fragment Management:
 * - voteOnFragment(uint256 fragmentId, int256 voteWeight): Allows users to vote on fragment quality (positive or negative). (Any user)
 * - processAccruedVotes(uint256 fragmentId): Processes pending votes to update quality score. (Can be called by anyone, maybe via keeper)
 * - triggerDecay(uint256[] calldata fragmentIds): Applies time-based quality decay to specified fragments. (Can be called by anyone, maybe via keeper)
 * - updateQualityScore(uint256 fragmentId, uint256 newQualityScore): Allows Stewards/Oracles to directly set quality (e.g., based on advanced AI evaluation). (Steward or Oracle)
 * - _mintFragment(address owner, string memory contentHash, uint256 quality, uint256 parentId): Internal helper to create fragment.
 * - _evolveFragment(uint256 parentFragmentId, address owner, string memory contentHash, uint256 evolutionStageIncrease): Internal helper to evolve fragment.
 * - transferFragmentOwnership(uint256 fragmentId, address newOwner): Allows fragment owner to transfer ownership. (Fragment owner)
 *
 * Query/Read Functions:
 * - getFragment(uint256 fragmentId) view: Retrieves details of a specific fragment.
 * - getFragmentCount() view: Returns the total number of fragments.
 * - getFragmentsByOwner(address owner, uint256 startIndex, uint256 count) view: Retrieves a range of fragment IDs owned by an address.
 * - getFragmentsByMinQuality(uint256 minQuality, uint256 startIndex, uint256 count) view: Retrieves a range of fragment IDs above a minimum quality.
 * - getLatestFragments(uint256 startIndex, uint256 count) view: Retrieves a range of the most recently created fragment IDs.
 *
 * Rule Management:
 * - updateRule(string memory ruleName, uint256 newValue): Updates a core contract parameter/rule. (Steward only)
 * - getCurrentRuleValue(string memory ruleName) view: Retrieves the current value of a specific rule.
 *
 * Utility:
 * - isSteward(address account) view: Checks if an address is a steward.
 * - isOracle(address account) view: Checks if an address is an authorized oracle.
 */

// --- Error Definitions ---
error NotOwner();
error NotSteward();
error NotOracle();
error FragmentNotFound(uint256 fragmentId);
error InvalidVoteWeight(int256 voteWeight);
error AlreadyVotedInPeriod(uint256 fragmentId, address voter);
error RequestNotFound(uint256 requestId);
error RuleNotFound(string ruleName);
error UnauthorizedTransfer();

// --- Event Definitions ---
event OracleRequestSent(uint256 indexed requestId, address indexed requester, string requestType, string payloadHash);
event OracleResultReceived(uint256 indexed requestId, string resultStatus); // resultStatus e.g., "success", "failure"
event FragmentMinted(uint256 indexed fragmentId, address indexed owner, uint256 indexed parentId, string contentHash, uint64 creationTimestamp);
event FragmentEvolved(uint256 indexed fragmentId, uint256 indexed parentFragmentId, string contentHash, uint256 newEvolutionStage);
event FragmentVoteRecorded(uint256 indexed fragmentId, address indexed voter, int256 voteWeight);
event FragmentQualityUpdated(uint256 indexed fragmentId, uint256 oldQuality, uint256 newQuality);
event FragmentDecayed(uint256 indexed fragmentId, uint256 oldQuality, uint256 newQuality);
event RuleUpdated(string indexed ruleName, uint256 oldValue, uint256 newValue);
event FragmentOwnershipTransferred(uint256 indexed fragmentId, address indexed oldOwner, address indexed newOwner);

// --- Struct Definitions ---
struct Fragment {
    uint256 id;
    address owner;
    uint64 creationTimestamp; // When the fragment was minted
    string ipfsHash;          // Hash pointing to the fragment content (e.g., text, link to image)
    uint256 qualityScore;     // Current quality score (can evolve and decay)
    uint256 evolutionStage;   // How many times this lineage has evolved
    uint256 parentId;         // ID of the parent fragment (0 for initial fragments)
    uint64 latestInteractionTimestamp; // Timestamp of last vote or evolution
    // Future potential: uint256[] childIds; // List of fragments that evolved FROM this one
}

// --- State Variables ---
address public owner;
address public aiOracle; // Address of the trusted oracle contract/account

mapping(address => bool) private _isSteward;
mapping(address => bool) private _isOracle;

uint256 private _nextFragmentId;
mapping(uint256 => Fragment) private _fragments;
uint256[] private _allFragmentIds; // Simple array to iterate fragments (caution: gas limit on large number)

// For vote processing:
mapping(uint256 => mapping(address => bool)) private _hasVotedOnFragment; // Simple single vote per address
mapping(uint256 => int256) private _accruedVoteWeight; // Total vote weight pending processing

// For tracking oracle requests
uint256 private _nextRequestId;
mapping(uint256 => address) private _oracleRequestRequester;
mapping(uint256 => string) private _oracleRequestType; // e.g., "create", "evolve"
// Potentially store more request-specific data if needed for validation

// Modifiable contract rules (e.g., decay rate, vote processing threshold)
mapping(string => uint256) private _rules;

// --- Access Control Modifiers ---
modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
}

modifier onlySteward() {
    if (!_isSteward[msg.sender]) revert NotSteward();
    _;
}

modifier onlyOracle() {
    if (!_isOracle[msg.sender]) revert NotOracle();
    _;
}

// --- Constructor ---
constructor(address initialOracle) {
    owner = msg.sender;
    aiOracle = initialOracle;
    _isOracle[initialOracle] = true; // Add initial oracle
    _nextFragmentId = 1; // Start IDs from 1
    _nextRequestId = 1;

    // Initialize default rules
    _rules["qualityDecayRate"] = 1; // Decay rate per time unit (e.g., 1 unit per day)
    _rules["decayTimeUnit"] = 1 days; // Time unit for decay
    _rules["minQualityForDisplay"] = 10; // Minimum quality to be easily queried
    _rules["voteProcessingThreshold"] = 10; // Number of votes before processing
    _rules["baseMintQuality"] = 50; // Starting quality for new fragments
}

// --- Setup and Role Management Functions ---

/**
 * @notice Sets the primary AI Oracle contract address.
 * @param newOracle The address of the new AI Oracle contract.
 * @dev Only callable by the contract owner.
 */
function setOracleAddress(address newOracle) external onlyOwner {
    aiOracle = newOracle;
    // Note: this assumes the *primary* oracle, but _isOracle mapping is for authorized callers.
    // It might be better to just rely on the _isOracle mapping. Let's keep both for this example.
    // The _isOracle mapping allows for multiple backup/specialized oracles.
    // Let's ensure the primary oracle is always in the authorized map.
    _isOracle[newOracle] = true;
}

/**
 * @notice Adds a steward address. Stewards can manage rules.
 * @param steward The address to add as a steward.
 * @dev Only callable by the contract owner.
 */
function addSteward(address steward) external onlyOwner {
    _isSteward[steward] = true;
}

/**
 * @notice Removes a steward address.
 * @param steward The address to remove as a steward.
 * @dev Only callable by the contract owner.
 */
function removeSteward(address steward) external onlyOwner {
    _isSteward[steward] = false;
}

/**
 * @notice Adds an address to the list of authorized oracles who can call receive functions.
 * @param oracle The address to add as an oracle.
 * @dev Only callable by the contract owner.
 */
function addOracle(address oracle) external onlyOwner {
    _isOracle[oracle] = true;
}

/**
 * @notice Removes an address from the list of authorized oracles.
 * @param oracle The address to remove as an oracle.
 * @dev Only callable by the contract owner.
 */
function removeOracle(address oracle) external onlyOwner {
    _isOracle[oracle] = false;
}

// --- Oracle Interaction Functions ---

/**
 * @notice Proposes the creation of a new fragment based on an initial prompt.
 * Sends a request to the AI Oracle.
 * @param initialPromptHash IPFS hash or identifier for the initial prompt provided by the user.
 * @return requestId The ID of the oracle request created.
 * @dev Any user can call this function. The oracle processes the request off-chain.
 */
function proposeFragmentCreation(string memory initialPromptHash) external returns (uint256 requestId) {
    requestId = _nextRequestId++;
    _oracleRequestRequester[requestId] = msg.sender;
    _oracleRequestType[requestId] = "create";

    // In a real system, this would involve sending data to the oracle, e.g., via an event
    // the oracle is listening to, or a Chainlink request.
    emit OracleRequestSent(requestId, msg.sender, "create", initialPromptHash);

    // Simulate sending request data to oracle (this part needs off-chain implementation)
    // For this example, we just log the event. The oracle simulation would need
    // to pick up this event and call receiveFragmentCreationResult later.
}

/**
 * @notice Proposes the evolution of an existing fragment based on a new prompt.
 * Sends a request to the AI Oracle.
 * @param parentFragmentId The ID of the fragment to evolve from.
 * @param evolutionPromptHash IPFS hash or identifier for the evolution prompt.
 * @return requestId The ID of the oracle request created.
 * @dev Any user can call this function. Requires the parent fragment to exist.
 */
function proposeFragmentEvolution(uint256 parentFragmentId, string memory evolutionPromptHash) external returns (uint256 requestId) {
    if (_fragments[parentFragmentId].id == 0) revert FragmentNotFound(parentFragmentId); // Check if parent exists

    requestId = _nextRequestId++;
    _oracleRequestRequester[requestId] = msg.sender;
    _oracleRequestType[requestId] = "evolve";

    // Include parent ID in the hash/payload for the oracle
    string memory payloadHash = string(abi.encodePacked(uint256(parentFragmentId), "-", evolutionPromptHash));

    emit OracleRequestSent(requestId, msg.sender, "evolve", payloadHash);

    // Simulate sending request data to oracle
}

/**
 * @notice Callback function for the AI Oracle to report the result of a fragment creation request.
 * @param requestId The ID of the original creation request.
 * @param requester The original address that proposed the creation.
 * @param resultContentHash IPFS hash or identifier for the AI-generated content.
 * @param initialQuality The initial quality score assigned by the oracle/AI.
 * @dev Only callable by an authorized oracle. Verifies request details.
 */
function receiveFragmentCreationResult(
    uint256 requestId,
    address requester,
    string memory resultContentHash,
    uint256 initialQuality
) external onlyOracle {
    // Basic validation (could be more complex)
    if (_oracleRequestRequester[requestId] == address(0)) revert RequestNotFound(requestId);
    if (_oracleRequestRequester[requestId] != requester || !compareStrings(_oracleRequestType[requestId], "create")) {
         // Log or handle mismatch - potential issue
         emit OracleResultReceived(requestId, "mismatch");
         return; // Or revert, depending on desired strictness
    }

    // Process the result and mint the fragment
    _mintFragment(requester, resultContentHash, initialQuality, 0); // 0 parentId for new fragments

    // Clean up request mapping (optional, but good practice for finite requests)
    delete _oracleRequestRequester[requestId];
    delete _oracleRequestType[requestId];

    emit OracleResultReceived(requestId, "success");
}

/**
 * @notice Callback function for the AI Oracle to report the result of a fragment evolution request.
 * @param requestId The ID of the original evolution request.
 * @param requester The original address that proposed the evolution.
 * @param parentFragmentId The ID of the fragment that was evolved from.
 * @param resultContentHash IPFS hash or identifier for the AI-generated content.
 * @param evolutionStageIncrease The number to add to the parent's evolution stage (usually 1).
 * @dev Only callable by an authorized oracle. Verifies request details and parent existence.
 */
function receiveFragmentEvolutionResult(
    uint256 requestId,
    address requester,
    uint256 parentFragmentId,
    string memory resultContentHash,
    uint256 evolutionStageIncrease
) external onlyOracle {
    // Basic validation
    if (_oracleRequestRequester[requestId] == address(0)) revert RequestNotFound(requestId);
     if (_oracleRequestRequester[requestId] != requester || !compareStrings(_oracleRequestType[requestId], "evolve")) {
         // Log or handle mismatch
         emit OracleResultReceived(requestId, "mismatch");
         return; // Or revert
    }
    if (_fragments[parentFragmentId].id == 0) {
        // Parent not found - oracle result is now irrelevant
        emit OracleResultReceived(requestId, "parentNotFound");
        delete _oracleRequestRequester[requestId];
        delete _oracleRequestType[requestId];
        return;
    }

    // Process the result and mint the evolved fragment
    _evolveFragment(parentFragmentId, requester, resultContentHash, evolutionStageIncrease);

    // Clean up request mapping
    delete _oracleRequestRequester[requestId];
    delete _oracleRequestType[requestId];

    emit OracleResultReceived(requestId, "success");
}

// --- Fragment Management Functions ---

/**
 * @notice Allows a user to vote on the quality of a fragment.
 * Each user gets one vote per fragment in a given voting period (simplified here as 'ever').
 * Vote weight is added to accrued votes for later processing.
 * @param fragmentId The ID of the fragment to vote on.
 * @param voteWeight The weight of the vote (positive or negative).
 * @dev Requires the fragment to exist. Prevents multiple votes from the same address.
 */
function voteOnFragment(uint256 fragmentId, int256 voteWeight) external {
    if (_fragments[fragmentId].id == 0) revert FragmentNotFound(fragmentId);
    // Simple check: single vote per address per fragment ever.
    // A more advanced system would use periods, quadratic voting, token weighting, etc.
    if (_hasVotedOnFragment[fragmentId][msg.sender]) revert AlreadyVotedInPeriod(fragmentId, msg.sender);
    if (voteWeight == 0) revert InvalidVoteWeight(voteWeight); // Must vote with non-zero weight

    _hasVotedOnFragment[fragmentId][msg.sender] = true;
    _accruedVoteWeight[fragmentId] += voteWeight;

    // Update latest interaction timestamp to potentially delay decay
    _fragments[fragmentId].latestInteractionTimestamp = uint64(block.timestamp);

    emit FragmentVoteRecorded(fragmentId, msg.sender, voteWeight);
}

/**
 * @notice Processes the accrued votes for a fragment and updates its quality score.
 * This separates vote recording from score calculation, allowing for batch processing or threshold triggers.
 * @param fragmentId The ID of the fragment whose votes should be processed.
 * @dev Can be called by anyone, potentially incentivized via a keeper network.
 * Requires accrued votes to exceed a threshold (rule).
 */
function processAccruedVotes(uint256 fragmentId) external {
    Fragment storage fragment = _fragments[fragmentId];
    if (fragment.id == 0) revert FragmentNotFound(fragmentId);

    int256 currentAccruedWeight = _accruedVoteWeight[fragmentId];
    uint256 voteProcessingThreshold = _rules["voteProcessingThreshold"];

    // Process if enough votes have accrued (absolute value check)
    if (uint256(currentAccruedWeight > 0 ? currentAccruedWeight : -currentAccruedWeight) < voteProcessingThreshold) {
        // Not enough votes accrued yet
        return;
    }

    // Calculate new quality score based on accrued votes.
    // Simple example: add/subtract weight. More complex models possible.
    uint256 oldQuality = fragment.qualityScore;
    int256 signedOldQuality = int256(oldQuality); // Cast for arithmetic
    int256 newSignedQuality = signedOldQuality + currentAccruedWeight;

    // Prevent quality from going below zero (or another minimum)
    fragment.qualityScore = uint256(newSignedQuality > 0 ? newSignedQuality : 0);

    // Reset accrued votes after processing
    _accruedVoteWeight[fragmentId] = 0;

    // Reset vote tracking (simplified: allow re-voting after processing)
    // A real system might manage this per period.
    delete _hasVotedOnFragment[fragmentId];

    emit FragmentQualityUpdated(fragmentId, oldQuality, fragment.qualityScore);
}


/**
 * @notice Triggers the quality decay for a list of fragments based on time elapsed since last interaction.
 * @param fragmentIds An array of fragment IDs to process for decay.
 * @dev Can be called by anyone, potentially incentivized via a keeper network.
 */
function triggerDecay(uint256[] calldata fragmentIds) external {
    uint256 decayRate = _rules["qualityDecayRate"];
    uint256 timeUnit = _rules["decayTimeUnit"];

    // Prevent division by zero if timeUnit is accidentally set to 0
    if (timeUnit == 0) return;

    for (uint i = 0; i < fragmentIds.length; i++) {
        uint256 fragmentId = fragmentIds[i];
        Fragment storage fragment = _fragments[fragmentId];

        // Only process decay for existing fragments
        if (fragment.id == 0) continue;

        uint64 lastInteraction = fragment.latestInteractionTimestamp;
        uint64 currentTime = uint64(block.timestamp);

        // Calculate elapsed time units since last interaction
        uint64 elapsedUnits = (currentTime - lastInteraction) / timeUnit;

        if (elapsedUnits > 0) {
            uint256 oldQuality = fragment.qualityScore;
            uint256 decayAmount = elapsedUnits * decayRate;

            // Apply decay, ensuring quality doesn't go below zero
            if (fragment.qualityScore > decayAmount) {
                fragment.qualityScore -= decayAmount;
            } else {
                fragment.qualityScore = 0;
            }

            // Update latest interaction timestamp *after* decay calculation
            fragment.latestInteractionTimestamp = currentTime;

            if (fragment.qualityScore != oldQuality) {
                 emit FragmentDecayed(fragmentId, oldQuality, fragment.qualityScore);
            }
        }
    }
}

/**
 * @notice Allows Stewards or Oracles to directly update a fragment's quality score.
 * Useful for manual overrides or sophisticated AI re-evaluation based on factors not captured by votes.
 * @param fragmentId The ID of the fragment to update.
 * @param newQualityScore The new quality score to set.
 * @dev Only callable by Steward or Oracle roles.
 */
function updateQualityScore(uint256 fragmentId, uint256 newQualityScore) external {
    if (!_isSteward[msg.sender] && !_isOracle[msg.sender]) revert NotSteward(); // Or NotOracle() based on role check order
    if (_fragments[fragmentId].id == 0) revert FragmentNotFound(fragmentId);

    uint256 oldQuality = _fragments[fragmentId].qualityScore;
    _fragments[fragmentId].qualityScore = newQualityScore;
     _fragments[fragmentId].latestInteractionTimestamp = uint64(block.timestamp); // Update interaction timestamp

    emit FragmentQualityUpdated(fragmentId, oldQuality, newQualityScore);
}

/**
 * @notice Transfers ownership of a fragment to a new address.
 * @param fragmentId The ID of the fragment to transfer.
 * @param newOwner The address of the new owner.
 * @dev Only callable by the current fragment owner.
 */
function transferFragmentOwnership(uint256 fragmentId, address newOwner) external {
    Fragment storage fragment = _fragments[fragmentId];
    if (fragment.id == 0) revert FragmentNotFound(fragmentId);
    if (fragment.owner != msg.sender) revert UnauthorizedTransfer();

    address oldOwner = fragment.owner;
    fragment.owner = newOwner;

    emit FragmentOwnershipTransferred(fragmentId, oldOwner, newOwner);
}

// --- Internal Helper Functions ---

/**
 * @notice Internal function to mint a new fragment.
 * @param owner The address of the initial owner.
 * @param contentHash IPFS hash of the content.
 * @param quality Initial quality score.
 * @param parentId ID of the parent fragment (0 if none).
 * @dev Called by oracle callback functions.
 */
function _mintFragment(
    address owner,
    string memory contentHash,
    uint256 quality,
    uint256 parentId
) internal {
    uint256 newId = _nextFragmentId++;
    _fragments[newId] = Fragment({
        id: newId,
        owner: owner,
        creationTimestamp: uint64(block.timestamp),
        ipfsHash: contentHash,
        qualityScore: quality,
        evolutionStage: (parentId == 0 ? 0 : _fragments[parentId].evolutionStage + 1), // Increment stage from parent
        parentId: parentId,
        latestInteractionTimestamp: uint64(block.timestamp) // Set initial interaction timestamp
    });
    _allFragmentIds.push(newId); // Add to the list (gas heavy for large counts)

    emit FragmentMinted(newId, owner, parentId, contentHash, uint64(block.timestamp));
}

/**
 * @notice Internal function to mint an evolved fragment.
 * Creates a *new* fragment linked to a parent.
 * @param parentFragmentId The ID of the fragment being evolved from.
 * @param owner The address of the new fragment's owner (usually the requester).
 * @param contentHash IPFS hash of the new content.
 * @param evolutionStageIncrease How much to increment the stage (usually 1).
 * @dev Called by the evolution oracle callback function.
 */
function _evolveFragment(
    uint256 parentFragmentId,
    address owner,
    string memory contentHash,
    uint256 evolutionStageIncrease
) internal {
    Fragment storage parentFragment = _fragments[parentFragmentId]; // Assuming parent exists (checked in caller)

    uint256 newId = _nextFragmentId++;
    _fragments[newId] = Fragment({
        id: newId,
        owner: owner,
        creationTimestamp: uint64(block.timestamp), // Creation timestamp for the new fragment
        ipfsHash: contentHash,
        qualityScore: parentFragment.qualityScore, // Inherit parent quality initially (or use oracle value)
        evolutionStage: parentFragment.evolutionStage + evolutionStageIncrease,
        parentId: parentFragmentId,
        latestInteractionTimestamp: uint64(block.timestamp) // Set initial interaction timestamp
    });
    _allFragmentIds.push(newId);

    // Future improvement: Add this newId to parentFragment.childIds array

    emit FragmentEvolved(newId, parentFragmentId, contentHash, _fragments[newId].evolutionStage);
}


/**
 * @notice Helper to compare strings. Needed because Solidity doesn't have built-in string comparison.
 * @dev Caution: This is a basic comparison, could be optimized if strings are very long.
 */
function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}

// --- Query/Read Functions ---

/**
 * @notice Retrieves the full details of a specific fragment.
 * @param fragmentId The ID of the fragment to retrieve.
 * @return The Fragment struct.
 * @dev Returns an empty struct if the fragment does not exist (check fragment.id != 0).
 */
function getFragment(uint256 fragmentId) external view returns (Fragment memory) {
    return _fragments[fragmentId];
}

/**
 * @notice Returns the total number of fragments minted.
 */
function getFragmentCount() external view returns (uint256) {
    return _nextFragmentId - 1; // IDs start from 1
}

/**
 * @notice Retrieves a paginated list of fragment IDs owned by a specific address.
 * @param owner The address whose fragments to retrieve.
 * @param startIndex The starting index in the internal list (not gas efficient for large lists).
 * @param count The maximum number of fragment IDs to return.
 * @return An array of fragment IDs.
 * @dev **Caution:** This function is inefficient for addresses owning a large number of fragments due to iteration.
 * A better design for many items would be to track token IDs per owner in a separate mapping or use a dedicated library.
 */
function getFragmentsByOwner(address owner, uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
    uint256[] memory ownerFragmentIds = new uint256[](count);
    uint256 currentCount = 0;
    uint256 totalFragments = _allFragmentIds.length;

    if (startIndex >= totalFragments) {
        return new uint256[](0); // Return empty array if start index is out of bounds
    }

    uint256 loopStart = startIndex;
    for (uint i = loopStart; i < totalFragments && currentCount < count; i++) {
        uint256 fragmentId = _allFragmentIds[i];
        if (_fragments[fragmentId].owner == owner) {
            ownerFragmentIds[currentCount] = fragmentId;
            currentCount++;
        }
    }

    // Trim the array if fewer than 'count' fragments were found
    uint256[] memory result = new uint256[](currentCount);
    for(uint i = 0; i < currentCount; i++) {
        result[i] = ownerFragmentIds[i];
    }
    return result;
}


/**
 * @notice Retrieves a paginated list of fragment IDs that have a quality score above a minimum threshold.
 * @param minQuality The minimum quality score required.
 * @param startIndex The starting index in the internal list (not gas efficient).
 * @param count The maximum number of fragment IDs to return.
 * @return An array of fragment IDs.
 * @dev **Caution:** This function is inefficient due to iteration over all fragments.
 * For large data, better to maintain sorted lists or use off-chain indexing.
 */
function getFragmentsByMinQuality(uint256 minQuality, uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
     uint256[] memory qualityFragmentIds = new uint256[](count);
    uint256 currentCount = 0;
     uint256 totalFragments = _allFragmentIds.length;

     if (startIndex >= totalFragments) {
        return new uint256[](0);
    }

    uint256 loopStart = startIndex;
    for (uint i = loopStart; i < totalFragments && currentCount < count; i++) {
         uint256 fragmentId = _allFragmentIds[i];
        if (_fragments[fragmentId].id != 0 && _fragments[fragmentId].qualityScore >= minQuality) {
            qualityFragmentIds[currentCount] = fragmentId;
            currentCount++;
        }
    }

     uint256[] memory result = new uint256[](currentCount);
    for(uint i = 0; i < currentCount; i++) {
        result[i] = qualityFragmentIds[i];
    }
    return result;
}


/**
 * @notice Retrieves a paginated list of the most recently created fragment IDs.
 * @param startIndex The starting index from the end of the creation list (0 is the latest).
 * @param count The maximum number of fragment IDs to return.
 * @return An array of fragment IDs, ordered by creation timestamp (most recent first).
 * @dev Iterates the list backwards. Still has gas implications for very large lists and deep indices.
 */
function getLatestFragments(uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
    uint256 totalFragments = _allFragmentIds.length;
    if (startIndex >= totalFragments) {
        return new uint256[](0);
    }

    uint256 actualCount = count;
    if (startIndex + count > totalFragments) {
        actualCount = totalFragments - startIndex;
    }

    uint256[] memory latestIds = new uint256[](actualCount);
    // Iterate backwards from the end of the list
    uint256 endIndex = totalFragments - startIndex; // This is the index *after* the last element we want
    uint256 loopStart = endIndex > actualCount ? endIndex - actualCount : 0;

    uint256 resultIndex = 0;
    for (uint i = loopStart; i < endIndex; i++) {
         latestIds[resultIndex] = _allFragmentIds[i];
         resultIndex++;
    }

     // Note: This returns IDs in order of creation (oldest first within the requested range),
     // not strictly 'latest first' in the return array itself without reversing.
     // Reversing on-chain is gas intensive. Users can reverse off-chain.
     // If strict 'latest first' in array is needed, a different storage approach (e.g., linked list) or off-chain sorting is better.
     // For this example, let's assume calling dApps sort off-chain.

    return latestIds;
}


// --- Rule Management Functions ---

/**
 * @notice Updates a specific rule parameter of the contract.
 * @param ruleName The name of the rule to update (e.g., "qualityDecayRate").
 * @param newValue The new value for the rule.
 * @dev Only callable by a steward. Emits a RuleUpdated event.
 */
function updateRule(string memory ruleName, uint256 newValue) external onlySteward {
    // Optional: Add checks for valid ruleName if you have a predefined list
    // if (!compareStrings(ruleName, "qualityDecayRate") && ...) revert InvalidRuleName();

    uint256 oldValue = _rules[ruleName];
    _rules[ruleName] = newValue;
    emit RuleUpdated(ruleName, oldValue, newValue);
}

/**
 * @notice Retrieves the current value of a specific rule.
 * @param ruleName The name of the rule.
 * @return The current value of the rule. Returns 0 if the rule name is not found.
 */
function getCurrentRuleValue(string memory ruleName) external view returns (uint256) {
    // Note: Reading from a mapping returns the default value (0 for uint256) if the key doesn't exist.
    // You might want to add a check and error if the rule *must* exist.
    // For simplicity, we just return 0 if not found.
    return _rules[ruleName];
}


// --- Utility Functions ---

/**
 * @notice Checks if an address is currently a steward.
 * @param account The address to check.
 * @return True if the account is a steward, false otherwise.
 */
function isSteward(address account) external view returns (bool) {
    return _isSteward[account];
}

/**
 * @notice Checks if an address is currently an authorized oracle caller.
 * @param account The address to check.
 * @return True if the account is an oracle, false otherwise.
 */
function isOracle(address account) external view returns (bool) {
    return _isOracle[account];
}
}
```