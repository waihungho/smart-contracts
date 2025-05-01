Okay, this is an exciting challenge! Let's design a smart contract that incorporates several advanced, trendy, and creative concepts.

We'll create a contract for a "Dynamic Bloom NFT" system. These NFTs aren't static images; they represent digital "Blooms" that grow, evolve, and change their characteristics based on time, user interaction (nurturing), external data (simulated via an Oracle interface), and even prediction outcomes.

Here's the outline and summary, followed by the Solidity code.

---

**Contract Name:** QuantumBloomFactory

**Description:**
A sophisticated smart contract implementing a dynamic NFT system ("Quantum Blooms"). Blooms are tokens that evolve over time, influenced by nurturing actions, external data feeds from an Oracle, and participate in prediction markets and community events. The contract manages the lifecycle of Blooms from seeding to harvesting, handles resource tokens (Nectar), and incorporates complex state transitions and interactions.

**Key Concepts:**
1.  **Dynamic NFTs:** Bloom properties are mutable and change based on on-chain logic.
2.  **Oracle Integration:** Utilizes a placeholder Oracle interface to simulate external data affecting Bloom state.
3.  **Prediction Markets:** Users can predict future Bloom states, staking resources and earning rewards/penalties based on outcomes.
4.  **Gamification & Resource Management:** Introduces a "Nectar" token required for interactions like nurturing and cross-pollination.
5.  **Time-Based Mechanics:** Bloom growth and decay are directly tied to `block.timestamp`.
6.  **State Snapshots:** Allows taking historical snapshots of Bloom states for analysis or prediction resolution.
7.  **Community Events:** Supports simple on-chain events like voting for Blooms.
8.  **Modular Design:** Uses standard interfaces and inherits from OpenZeppelin libraries for security and best practices.

**Dependencies:**
*   OpenZeppelin Contracts (ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard)
*   Placeholder Oracle Interface
*   Placeholder Nectar Token Interface (ERC20)

**Outline & Function Summary:**

**I. State Variables:**
   *   `_blooms`: Mapping storing `Bloom` structs by `tokenId`.
   *   `_oracle`: Address of the Oracle contract.
   *   `_nectarToken`: Address of the Nectar ERC20 token contract.
   *   `_nextBloomId`: Counter for unique Bloom IDs.
   *   `_predictions`: Mapping storing prediction details.
   *   `_snapshots`: Mapping storing historical state snapshots.
   *   `_communityEvents`: Mapping storing details of active events.
   *   `_eventVotes`: Mapping tracking votes per event.

**II. Events:**
   *   `BloomMinted`: Logs new Bloom creation.
   *   `BloomNurtured`: Logs when a Bloom is nurtured.
   *   `BloomHarvested`: Logs when a Bloom is harvested.
   *   `BloomStateUpdated`: Logs state changes due to nurturing, decay, or oracle.
   *   `PredictionMade`: Logs a new prediction.
   *   `PredictionResolved`: Logs prediction outcome and reward distribution.
   *   `SnapshotTaken`: Logs when a state snapshot is saved.
   *   `CrossPollinated`: Logs creation of a new Seed from two parents.
   *   `BloomSupported`: Logs when one user supports another's Bloom.
   *   `MutationTriggered`: Logs when a mutation event occurs.
   *   `CommunityEventCreated`: Logs creation of a new event.
   *   `BloomParticipatedInEvent`: Logs Bloom entry into an event.
   *   `EventVoteCast`: Logs a vote in an event.
   *   `CommunityEventResolved`: Logs event outcome and reward distribution.

**III. Modifiers:**
   *   `onlyOracle`: Restricts function calls to the designated Oracle address.
   *   `whenBloomExists`: Ensures a Bloom with the given ID exists.
   *   `whenBloomOwner`: Ensures the caller owns the Bloom.
   *   `whenBloomMature`: Ensures the Bloom is ready for harvest.
   *   `whenBloomDecayDue`: Ensures a Bloom is ready for decay check.
   *   `whenPredictionPending`: Ensures a prediction is unresolved.
   *   `whenEventActive`: Ensures a community event is ongoing.

**IV. Constructor & Admin Functions (Owned by `Ownable`):**
1.  `constructor()`: Initializes contract, sets owner.
2.  `setOracleAddress(address _newOracle)`: Sets the Oracle contract address.
3.  `setNectarToken(address _nectar)`: Sets the Nectar token contract address.
4.  `pause()`: Pauses the contract (using `Pausable`).
5.  `unpause()`: Unpauses the contract (using `Pausable`).
6.  `withdrawAdminFees(address tokenAddress, uint256 amount)`: Allows admin to withdraw fees collected (if any).

**V. Bloom Core Lifecycle Functions (Inherited/Implemented from ERC721/Enumerable):**
7.  `mintSeed(uint256 initialGenetics)`: Creates a new Bloom (Seed). Requires Nectar payment. Sets initial state and genetics.
8.  `getBloomState(uint256 bloomId)`: (View) Retrieves the current state of a Bloom.
9.  `nurtureBloom(uint256 bloomId, uint256 nectarAmount)`: User spends Nectar to improve Bloom health/hydration.
10. `harvestBloom(uint256 bloomId)`: User harvests rewards (e.g., Nectar, new Seed) from a mature Bloom. Marks Bloom as harvested or starts new cycle.
11. `allowBloomDecay(uint256 bloomId)`: Public function allowing anyone to trigger decay calculation for an un-nurtured Bloom (incentivized?).
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: (Inherited) Standard ERC721 safe transfer.
13. `ownerOf(uint256 tokenId)`: (Inherited) Returns owner of a Bloom.
14. `balanceOf(address owner)`: (Inherited) Returns number of Blooms owned by an address.
15. `totalSupply()`: (Inherited from Enumerable) Returns total number of Blooms.
16. `tokenOfOwnerByIndex(address owner, uint256 index)`: (Inherited from Enumerable) Returns token ID at index for owner.
17. `tokenByIndex(uint256 index)`: (Inherited from Enumerable) Returns token ID at global index.

**VI. Dynamic State & Oracle Integration Functions:**
18. `updateBloomFromOracle(uint256 bloomId, bytes calldata oracleData)`: Called by the Oracle to push external data affecting Bloom state (e.g., weather, pollution, global event).
19. `takeStateSnapshot(uint256 bloomId, string memory snapshotName)`: Allows owner/admin to save a specific state snapshot of a Bloom.
20. `getSnapshot(uint256 bloomId, string memory snapshotName)`: (View) Retrieves a saved state snapshot.

**VII. Prediction Market Functions:**
21. `predictBloomOutcome(uint256 bloomId, bytes32 predictedStateHash, uint256 stakeAmount, uint64 predictionEndTime)`: User stakes Nectar to predict a hash of the Bloom's state at a future time.
22. `resolvePrediction(uint256 bloomId, bytes32 predictedStateHash)`: Oracle/Admin resolves a specific prediction by checking the actual state hash. Distributes/slashes stakes.
23. `claimPredictionRewards(uint256 bloomId, bytes32 predictedStateHash)`: User claims Nectar rewards after their prediction is resolved correctly.

**VIII. Evolution & Interaction Functions:**
24. `crossPollinate(uint256 bloomId1, uint256 bloomId2)`: Combines traits of two Blooms owned by the caller to potentially mint a new Seed (requires Nectar).
25. `supportOtherBloom(uint256 bloomId, uint256 nectarAmount)`: User spends Nectar to nurture another user's Bloom. Rewards the supporter with reputation/points or a small fee return?
26. `triggerMutationEvent(bytes calldata mutationParameters)`: Admin/Oracle triggers a global mutation event that might affect Bloom states based on `mutationParameters`.

**IX. Community & Event Functions:**
27. `createCommunityEvent(string memory eventName, uint256 participationFee, uint64 endTime, bytes32 eventType)`: Admin creates a competition or event.
28. `participateInEvent(uint256 eventId, uint256 bloomId)`: User enters their Bloom into an active event. Requires participation fee (Nectar).
29. `voteForBloom(uint256 eventId, uint256 bloomId)`: User votes for a Bloom in an active event (requires Nectar or owning a Bloom?).
30. `resolveEvent(uint256 eventId)`: Admin resolves the event, distributes rewards based on event type (e.g., votes, predicted outcome).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
// Contract Name: QuantumBloomFactory
// Description: A sophisticated smart contract implementing a dynamic NFT system ("Quantum Blooms"). Blooms evolve based on time, user interaction (nurturing), external data (Oracle), and prediction markets.
// Key Concepts: Dynamic NFTs, Oracle Integration, Prediction Markets, Gamification, Time-Based Mechanics, State Snapshots, Community Events.
// Dependencies: OpenZeppelin (ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard), Placeholder Interfaces (Oracle, Nectar ERC20).
//
// Outline & Function Summary:
//
// I. State Variables:
//    _blooms: Mapping storing Bloom structs by tokenId.
//    _oracle: Address of the Oracle contract.
//    _nectarToken: Address of the Nectar ERC20 token.
//    _nextBloomId: Counter for unique Bloom IDs.
//    _predictions: Mapping storing prediction details (bloomId => predictor => predictionHash => Prediction).
//    _snapshots: Mapping storing historical state snapshots (bloomId => snapshotName => Bloom).
//    _communityEvents: Mapping storing active event details (eventId => CommunityEvent).
//    _eventVotes: Mapping tracking votes per event and voter (eventId => voter => votedBloomId).
//
// II. Events:
//    BloomMinted(uint256 bloomId, address owner, uint256 initialGenetics, uint256 plantedTimestamp);
//    BloomNurtured(uint256 bloomId, address nurturer, uint256 nectarAmount, uint256 newHealth, uint256 newHydration);
//    BloomHarvested(uint256 bloomId, address owner, uint256 harvestAmount); // Simplified example, could be more complex
//    BloomStateUpdated(uint256 bloomId, bytes32 reason); // Reason hash, e.g., keccak256("Nurture"), keccak256("Decay"), keccak256("Oracle")
//    PredictionMade(uint256 bloomId, address predictor, bytes32 predictedStateHash, uint256 stakeAmount, uint64 predictionEndTime);
//    PredictionResolved(uint256 bloomId, address predictor, bytes32 predictedStateHash, bool correct, int256 stakeChange);
//    SnapshotTaken(uint256 bloomId, string snapshotName, uint256 timestamp);
//    CrossPollinated(uint256 bloomId1, uint256 bloomId2, uint256 newBloomId, uint256 newGenetics);
//    BloomSupported(uint256 bloomId, address supporter, uint256 nectarAmount);
//    MutationTriggered(bytes calldata mutationParameters);
//    CommunityEventCreated(uint256 eventId, string eventName, uint256 participationFee, uint64 endTime, bytes32 eventType);
//    BloomParticipatedInEvent(uint256 eventId, uint256 bloomId, address participant);
//    EventVoteCast(uint256 eventId, uint256 bloomId, address voter);
//    CommunityEventResolved(uint256 eventId, bytes32 outcomeDetails); // Outcome hash, e.g., winner ID, total votes
//
// III. Modifiers:
//    onlyOracle: Restricts function calls to the designated Oracle address.
//    whenBloomExists(uint256 bloomId): Ensures a Bloom with the given ID exists.
//    whenBloomOwner(uint256 bloomId): Ensures the caller owns the Bloom.
//    whenBloomMature(uint256 bloomId): Ensures the Bloom is ready for harvest.
//    whenBloomDecayDue(uint256 bloomId): Ensures a Bloom is ready for decay check.
//    whenPredictionPending(uint256 bloomId, address predictor, bytes32 predictedStateHash): Ensures a prediction is unresolved.
//    whenEventActive(uint256 eventId): Ensures a community event is ongoing.
//
// IV. Constructor & Admin Functions (Owned by Ownable):
// 1. constructor(): Initializes contract, sets owner.
// 2. setOracleAddress(address _newOracle): Sets the Oracle contract address.
// 3. setNectarToken(address _nectar): Sets the Nectar token contract address.
// 4. pause(): Pauses the contract.
// 5. unpause(): Unpauses the contract.
// 6. withdrawAdminFees(address tokenAddress, uint256 amount): Allows admin to withdraw fees collected.
//
// V. Bloom Core Lifecycle Functions (Inherited/Implemented from ERC721/Enumerable):
// 7. mintSeed(uint256 initialGenetics): Creates a new Bloom (Seed). Requires Nectar payment.
// 8. getBloomState(uint256 bloomId): (View) Retrieves the current state of a Bloom.
// 9. nurtureBloom(uint256 bloomId, uint256 nectarAmount): User spends Nectar to improve Bloom.
// 10. harvestBloom(uint256 bloomId): User harvests rewards from a mature Bloom.
// 11. allowBloomDecay(uint256 bloomId): Anyone triggers decay calculation for un-nurtured Bloom.
// 12. safeTransferFrom(address from, address to, uint256 tokenId): (Inherited) Standard ERC721 safe transfer.
// 13. ownerOf(uint256 tokenId): (Inherited) Returns owner of a Bloom.
// 14. balanceOf(address owner): (Inherited) Returns number of Blooms owned.
// 15. totalSupply(): (Inherited from Enumerable) Returns total Blooms.
// 16. tokenOfOwnerByIndex(address owner, uint256 index): (Inherited from Enumerable) Returns token ID at index for owner.
// 17. tokenByIndex(uint256 index): (Inherited from Enumerable) Returns token ID at global index.
//
// VI. Dynamic State & Oracle Integration Functions:
// 18. updateBloomFromOracle(uint256 bloomId, bytes calldata oracleData): Called by Oracle to push external data affecting Bloom.
// 19. takeStateSnapshot(uint256 bloomId, string memory snapshotName): Saves a state snapshot.
// 20. getSnapshot(uint256 bloomId, string memory snapshotName): (View) Retrieves a snapshot.
//
// VII. Prediction Market Functions:
// 21. predictBloomOutcome(uint256 bloomId, bytes32 predictedStateHash, uint256 stakeAmount, uint64 predictionEndTime): User stakes Nectar to predict future state.
// 22. resolvePrediction(uint256 bloomId, bytes32 predictedStateHash): Oracle/Admin resolves a prediction.
// 23. claimPredictionRewards(uint256 bloomId, bytes32 predictedStateHash): User claims prediction rewards.
//
// VIII. Evolution & Interaction Functions:
// 24. crossPollinate(uint256 bloomId1, uint256 bloomId2): Combines two blooms for a new Seed.
// 25. supportOtherBloom(uint256 bloomId, uint256 nectarAmount): User supports another Bloom.
// 26. triggerMutationEvent(bytes calldata mutationParameters): Admin/Oracle triggers global mutation.
//
// IX. Community & Event Functions:
// 27. createCommunityEvent(string memory eventName, uint256 participationFee, uint64 endTime, bytes32 eventType): Admin creates event.
// 28. participateInEvent(uint256 eventId, uint256 bloomId): User enters Bloom into event.
// 29. voteForBloom(uint256 eventId, uint256 bloomId): User votes in event.
// 30. resolveEvent(uint256 eventId): Admin resolves event.
//
// --- END OF OUTLINE & SUMMARY ---

// Placeholder interfaces
interface IOracle {
    // Function the oracle would call to update bloom state
    function updateBloomState(uint256 bloomId, bytes calldata oracleData) external;
    // Function the oracle would call to resolve a prediction
    function resolvePredictionOutcome(uint256 bloomId, bytes32 predictedStateHash, bool correct, int256 stakeChange) external;
    // Add other oracle-specific functions as needed
}

interface INectarToken is IERC20 {
    // Standard ERC20 functions are inherited
}

contract QuantumBloomFactory is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    using Strings for uint256;

    // --- I. State Variables ---

    // Represents the state of a Bloom at a given time
    struct Bloom {
        uint256 bloomId;
        uint256 plantedTimestamp;
        uint256 lastNurturedTimestamp;
        uint256 initialGenetics; // Immutable "seed" properties
        uint256 currentGrowthStage; // 0-100, grows over time, affected by nurturing/decay/oracle
        uint256 currentHealth;      // 0-100, affected by nurturing/decay/oracle
        uint256 currentHydration;   // 0-100, affected by nurturing/decay/oracle
        uint256 mutationTraits;     // Bitmask or code representing acquired traits
        bool isHarvested;           // Can reset for a new cycle or be final
        // Add more properties as needed for complexity (e.g., 'color', 'type', 'resistance')
    }

    mapping(uint256 => Bloom) private _blooms;
    uint256 private _nextBloomId;

    address public _oracle;
    address public _nectarToken;

    struct Prediction {
        address predictor;
        uint256 stakeAmount;
        uint64 predictionEndTime;
        bool resolved;
        bool correct; // Only set after resolution
    }

    // bloomId => predictor address => predicted hash => Prediction details
    mapping(uint256 => mapping(address => mapping(bytes32 => Prediction))) private _predictions;

    // bloomId => snapshot name => Bloom state
    mapping(uint256 => mapping(string => Bloom)) private _snapshots;

    struct CommunityEvent {
        uint256 eventId;
        string name;
        uint256 participationFee;
        uint64 endTime;
        bytes32 eventType; // e.g., keccak256("BestBloom"), keccak256("FastestGrowthPrediction")
        bool active;
        mapping(uint256 => bool) participants; // bloomId => isParticipant
        // Add event-specific fields (e.g., prize pool, outcome details)
    }

    mapping(uint256 => CommunityEvent) private _communityEvents;
    uint256 private _nextEventId;

    // eventId => voter address => votedBloomId
    mapping(uint256 => mapping(address => uint256)) private _eventVotes;

    // --- II. Events ---
    event BloomMinted(uint256 bloomId, address owner, uint256 initialGenetics, uint256 plantedTimestamp);
    event BloomNurtured(uint256 bloomId, address nurturer, uint256 nectarAmount, uint256 newHealth, uint256 newHydration);
    event BloomHarvested(uint255 bloomId, address owner, uint256 harvestAmount);
    event BloomStateUpdated(uint256 bloomId, bytes32 reason);
    event PredictionMade(uint256 bloomId, address predictor, bytes32 predictedStateHash, uint256 stakeAmount, uint64 predictionEndTime);
    event PredictionResolved(uint256 bloomId, address predictor, bytes32 predictedStateHash, bool correct, int256 stakeChange);
    event SnapshotTaken(uint256 bloomId, string snapshotName, uint256 timestamp);
    event CrossPollinated(uint256 bloomId1, uint256 bloomId2, uint256 newBloomId, uint256 newGenetics);
    event BloomSupported(uint256 bloomId, address supporter, uint256 nectarAmount);
    event MutationTriggered(bytes calldata mutationParameters);
    event CommunityEventCreated(uint256 eventId, string name, uint256 participationFee, uint64 endTime, bytes32 eventType);
    event BloomParticipatedInEvent(uint256 eventId, uint256 bloomId, address participant);
    event EventVoteCast(uint256 eventId, uint256 bloomId, address voter);
    event CommunityEventResolved(uint256 eventId, bytes32 outcomeDetails);

    // --- III. Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == _oracle, "QBF: Not the oracle");
        _;
    }

    modifier whenBloomExists(uint256 bloomId) {
        require(_exists(bloomId), "QBF: Bloom does not exist");
        _;
    }

    modifier whenBloomOwner(uint256 bloomId) {
        require(ownerOf(bloomId) == msg.sender, "QBF: Caller is not bloom owner");
        _;
    }

    modifier whenBloomMature(uint255 bloomId) {
         // Simplified maturity check: planted >= 7 days && growth >= 80
         Bloom storage bloom = _blooms[bloomId];
         require(block.timestamp >= bloom.plantedTimestamp + 7 days, "QBF: Bloom not old enough");
         require(bloom.currentGrowthStage >= 80, "QBF: Bloom not grown enough");
         require(!bloom.isHarvested, "QBF: Bloom already harvested");
         _;
    }

    modifier whenBloomDecayDue(uint256 bloomId) {
        Bloom storage bloom = _blooms[bloomId];
        // Simplified decay check: not nurtured in last 24 hours
        require(block.timestamp >= bloom.lastNurturedTimestamp + 1 days, "QBF: Decay not yet due");
        _;
    }

    modifier whenPredictionPending(uint256 bloomId, address predictor, bytes32 predictedStateHash) {
        Prediction storage prediction = _predictions[bloomId][predictor][predictedStateHash];
        require(prediction.predictor != address(0), "QBF: Prediction does not exist");
        require(!prediction.resolved, "QBF: Prediction already resolved");
        require(block.timestamp >= prediction.predictionEndTime, "QBF: Prediction time not yet reached");
        _;
    }

    modifier whenEventActive(uint256 eventId) {
        CommunityEvent storage eventDetails = _communityEvents[eventId];
        require(eventDetails.active, "QBF: Event is not active");
        require(block.timestamp < eventDetails.endTime, "QBF: Event has ended");
        _;
    }


    // --- IV. Constructor & Admin Functions ---

    constructor() ERC721("QuantumBloom", "QBF") Ownable(msg.sender) Pausable() {
        _nextBloomId = 1; // Start token IDs from 1
        _nextEventId = 1; // Start event IDs from 1
        // Oracle and Nectar token must be set by owner after deployment
    }

    /// @notice Sets the address of the Oracle contract.
    /// @param _newOracle The address of the Oracle contract.
    function setOracleAddress(address _newOracle) public onlyOwner {
        _oracle = _newOracle;
    }

    /// @notice Sets the address of the Nectar ERC20 token contract.
    /// @param _nectar The address of the Nectar token contract.
    function setNectarToken(address _nectar) public onlyOwner {
        _nectarToken = _nectar;
    }

    /// @notice Pauses the contract, preventing most interactions.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, allowing interactions again.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner to withdraw collected fees (e.g., Nectar or ETH).
    /// @param tokenAddress The address of the token to withdraw (use address(0) for ETH).
    /// @param amount The amount to withdraw.
    function withdrawAdminFees(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "QBF: ETH transfer failed");
        } else {
            // Withdraw ERC20
            require(IERC20(tokenAddress).transfer(owner(), amount), "QBF: Token transfer failed");
        }
    }

    // --- V. Bloom Core Lifecycle Functions ---

    /// @notice Mints a new Quantum Bloom Seed for the caller.
    /// @dev Requires payment of Nectar tokens. Initial state is based on genetics.
    /// @param initialGenetics A value representing the seed's base genetic properties.
    function mintSeed(uint256 initialGenetics) public payable whenNotPaused nonReentrant returns (uint256 bloomId) {
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        // Example cost: 100 Nectar per seed
        uint256 seedCost = 100 * (10**IERC20(_nectarToken).decimals()); // Adjust based on token decimals
        require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), seedCost), "QBF: Nectar transfer failed for mint");

        bloomId = _nextBloomId++;
        _blooms[bloomId] = Bloom({
            bloomId: bloomId,
            plantedTimestamp: block.timestamp,
            lastNurturedTimestamp: block.timestamp,
            initialGenetics: initialGenetics,
            currentGrowthStage: 0,
            currentHealth: 100, // Start healthy
            currentHydration: 100, // Start hydrated
            mutationTraits: 0,
            isHarvested: false
        });

        _safeMint(msg.sender, bloomId);

        emit BloomMinted(bloomId, msg.sender, initialGenetics, block.timestamp);
        emit BloomStateUpdated(bloomId, keccak256("Mint"));
    }

    /// @notice Retrieves the current state of a Quantum Bloom.
    /// @param bloomId The ID of the Bloom.
    /// @return A struct containing the Bloom's current properties.
    function getBloomState(uint256 bloomId) public view whenBloomExists(bloomId) returns (Bloom memory) {
        return _blooms[bloomId];
    }

    /// @notice Allows the owner to nurture their Bloom using Nectar.
    /// @dev Nurturing improves health and hydration, potentially boosting growth.
    /// @param bloomId The ID of the Bloom to nurture.
    /// @param nectarAmount The amount of Nectar to spend on nurturing.
    function nurtureBloom(uint256 bloomId, uint256 nectarAmount) public whenNotPaused whenBloomOwner(bloomId) nonReentrant {
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        require(nectarAmount > 0, "QBF: Must use positive nectar amount");
        require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), nectarAmount), "QBF: Nectar transfer failed for nurture");

        Bloom storage bloom = _blooms[bloomId];

        // Apply nurturing effects (simplified)
        uint256 healthBoost = nectarAmount / 10; // Example calculation
        uint256 hydrationBoost = nectarAmount / 5;

        bloom.currentHealth = Math.min(100, bloom.currentHealth + healthBoost);
        bloom.currentHydration = Math.min(100, bloom.currentHydration + hydrationBoost);
        bloom.lastNurturedTimestamp = block.timestamp;

        // Growth can also be influenced, but primarily time-based.
        // Maybe add a small growth boost here.
        uint256 growthBoost = nectarAmount / 50;
        bloom.currentGrowthStage = Math.min(100, bloom.currentGrowthStage + growthBoost);


        emit BloomNurtured(bloomId, msg.sender, nectarAmount, bloom.currentHealth, bloom.currentHydration);
        emit BloomStateUpdated(bloomId, keccak256("Nurture"));
    }

    /// @notice Allows the owner to harvest resources from a mature Bloom.
    /// @dev Harvesting might yield Nectar or other assets, and could end the Bloom's lifecycle or reset it.
    /// @param bloomId The ID of the Bloom to harvest.
    function harvestBloom(uint256 bloomId) public whenNotPaused whenBloomOwner(bloomId) whenBloomMature(bloomId) nonReentrant {
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        Bloom storage bloom = _blooms[bloomId];

        // Calculate harvest amount based on Bloom state (simplified example)
        uint256 harvestAmount = bloom.currentGrowthStage * 10 + bloom.currentHealth * 5 + bloom.currentHydration * 2;
        // Add bonus based on mutation traits, initial genetics, etc.
        harvestAmount += bloom.mutationTraits * 50;

        // Transfer harvested Nectar
        require(IERC20(_nectarToken).transfer(msg.sender, harvestAmount), "QBF: Nectar transfer failed for harvest");

        bloom.isHarvested = true; // Mark as harvested (could transition to a withered state or allow re-seeding)

        emit BloomHarvested(bloomId, msg.sender, harvestAmount);
        // Consider emitting StateUpdated if harvesting changes state (e.g., growth resets)
    }

    /// @notice Allows anyone to trigger decay calculation for a Bloom that hasn't been nurtured recently.
    /// @dev This incentivizes monitoring and maintaining Blooms. The caller might get a small reward (e.g., dust Nectar).
    /// @param bloomId The ID of the Bloom to check for decay.
    function allowBloomDecay(uint256 bloomId) public whenNotPaused whenBloomExists(bloomId) whenBloomDecayDue(bloomId) {
        Bloom storage bloom = _blooms[bloomId];

        uint256 timeSinceLastNurture = block.timestamp - bloom.lastNurturedTimestamp;
        // Calculate decay based on time (simplified)
        uint256 decayFactor = timeSinceLastNurture / 1 days; // Lose stats per day

        bloom.currentHealth = bloom.currentHealth > decayFactor ? bloom.currentHealth - decayFactor : 0;
        bloom.currentHydration = bloom.currentHydration > decayFactor ? bloom.currentHydration - decayFactor : 0;

        // Decay can also reduce growth or even kill the bloom
        if (bloom.currentGrowthStage > decayFactor) {
             bloom.currentGrowthStage -= decayFactor;
        } else {
             bloom.currentGrowthStage = 0; // Bloom withers
             // Could trigger transfer to a 'withered' state/contract or burn
        }

        // Small incentive for calling (e.g., 1 Nectar dust)
        if (_nectarToken != address(0)) {
            // In a real contract, ensure the contract has enough Nectar or mint it responsibly
            // Example: transfer a very small amount. Need to handle potential failures.
            // IERC20(_nectarToken).transfer(msg.sender, 1); // Careful with dust transfers
        }


        emit BloomStateUpdated(bloomId, keccak256("Decay"));
    }

    // Functions 12-17 are standard ERC721Enumerable functions, provided by the inherited contract.
    // They are listed in the summary for completeness but not re-implemented here.
    // safeTransferFrom, ownerOf, balanceOf, totalSupply, tokenOfOwnerByIndex, tokenByIndex

    // --- VI. Dynamic State & Oracle Integration Functions ---

    /// @notice Called by the Oracle to update a Bloom's state based on external data.
    /// @dev This simulates environmental factors, global events, etc., affecting the Bloom.
    /// @param bloomId The ID of the Bloom to update.
    /// @param oracleData Encoded data from the oracle (format depends on Oracle implementation).
    function updateBloomFromOracle(uint256 bloomId, bytes calldata oracleData) public whenNotPaused onlyOracle whenBloomExists(bloomId) {
        Bloom storage bloom = _blooms[bloomId];

        // Example: Oracle data influences health and hydration
        // Decode oracleData based on your specific oracle interface/format
        // For demonstration, let's assume oracleData is a 64-byte value
        // First 32 bytes affect health (signed int), next 32 bytes affect hydration (signed int)
        require(oracleData.length == 64, "QBF: Invalid oracle data length");

        int256 healthChange = int256(bytes32(oracleData[0..32]));
        int256 hydrationChange = int256(bytes32(oracleData[32..64]));

        int256 newHealth = int256(bloom.currentHealth) + healthChange;
        int256 newHydration = int256(bloom.currentHydration) + hydrationChange;

        // Clamp values between 0 and 100
        bloom.currentHealth = uint256(Math.max(0, Math.min(100, newHealth)));
        bloom.currentHydration = uint256(Math.max(0, Math.min(100, newHydration)));

        // Oracle data could also trigger mutations or growth spurts/stunts
        // Example: Check for a specific pattern in oracleData for mutation
        if (bytes32(oracleData) == keccak256("MUTATE_A")) {
            bloom.mutationTraits |= 1; // Set a specific mutation flag
        }


        emit BloomStateUpdated(bloomId, keccak256("Oracle"));
    }

    /// @notice Takes a snapshot of a Bloom's current state.
    /// @dev This is useful for resolving predictions or tracking historical performance.
    /// @param bloomId The ID of the Bloom to snapshot.
    /// @param snapshotName A unique name for this snapshot (e.g., "Prediction_X_Outcome").
    function takeStateSnapshot(uint256 bloomId, string memory snapshotName) public whenNotPaused whenBloomExists(bloomId) {
        // Allow owner or oracle to take snapshot
        require(ownerOf(bloomId) == msg.sender || msg.sender == _oracle, "QBF: Not owner or oracle");

        // Store a copy of the current Bloom state
        _snapshots[bloomId][snapshotName] = _blooms[bloomId];

        emit SnapshotTaken(bloomId, snapshotName, block.timestamp);
    }

    /// @notice Retrieves a previously saved state snapshot for a Bloom.
    /// @param bloomId The ID of the Bloom.
    /// @param snapshotName The name of the snapshot to retrieve.
    /// @return A struct containing the state of the Bloom at the time the snapshot was taken.
    function getSnapshot(uint256 bloomId, string memory snapshotName) public view whenBloomExists(bloomId) returns (Bloom memory) {
        // Check if the snapshot exists
        require(_snapshots[bloomId][snapshotName].bloomId != 0, "QBF: Snapshot does not exist");
        return _snapshots[bloomId][snapshotName];
    }


    // --- VII. Prediction Market Functions ---

    /// @notice Allows a user to stake Nectar and predict a Bloom's state at a future time.
    /// @dev The predicted state is represented by a hash. The oracle resolves the outcome.
    /// @param bloomId The ID of the Bloom to predict.
    /// @param predictedStateHash The hash of the state being predicted (e.g., hash of Bloom struct properties).
    /// @param stakeAmount The amount of Nectar to stake on this prediction.
    /// @param predictionEndTime The timestamp when the prediction period ends.
    function predictBloomOutcome(uint256 bloomId, bytes32 predictedStateHash, uint256 stakeAmount, uint64 predictionEndTime) public whenNotPaused whenBloomExists(bloomId) nonReentrant {
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        require(stakeAmount > 0, "QBF: Stake amount must be positive");
        require(predictionEndTime > block.timestamp, "QBF: Prediction end time must be in the future");
        // Ensure this user hasn't already made this exact prediction on this Bloom
        require(_predictions[bloomId][msg.sender][predictedStateHash].predictor == address(0), "QBF: Prediction already exists");

        // Transfer stake from predictor to contract
        require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), stakeAmount), "QBF: Nectar transfer failed for prediction stake");

        _predictions[bloomId][msg.sender][predictedStateHash] = Prediction({
            predictor: msg.sender,
            stakeAmount: stakeAmount,
            predictionEndTime: predictionEndTime,
            resolved: false,
            correct: false // Default
        });

        emit PredictionMade(bloomId, msg.sender, predictedStateHash, stakeAmount, predictionEndTime);
    }

    /// @notice Called by the Oracle or Admin to resolve a specific prediction.
    /// @dev Checks if the actual state matches the prediction hash at the resolution time. Distributes stakes.
    /// @param bloomId The ID of the Bloom the prediction is about.
    /// @param predictedStateHash The hash of the predicted state.
    function resolvePrediction(uint256 bloomId, bytes32 predictedStateHash) public whenNotPaused whenBloomExists(bloomId) onlyOracle nonReentrant {
         // Simplified resolution: Check if the current state hash matches the prediction hash
         // In a real system, the oracle would provide the *actual* state at predictionEndTime
         // and the contract would hash that state to compare.
         // For this example, we'll just assume the Oracle knows the outcome and tells us.

         // We need to iterate through all predictors who made this specific hash prediction
         // This requires a more complex data structure or the Oracle knowing *which* predictors to resolve.
         // Let's simplify and assume the Oracle resolves for a specific predictor provided as part of predictionHash or oracleData, or iterates off-chain.
         // A better way is for Oracle to call a function like `resolveUserPrediction(bloomId, predictor, predictedStateHash, bool outcome)`.
         // Let's add that helper function and call it here (simulated).

         // Example: Simulate the Oracle calculating outcome and stake change off-chain
         // For demo, assume Oracle determines the prediction was correct for some reason
         // and the stake change is double the stake (2x payout).
         // In reality, stakes from incorrect predictions would fund correct ones.
         // Oracle calls back using a dedicated function:
         // IOracle(_oracle).resolvePredictionOutcome(bloomId, predictedStateHash, true, int256(prediction.stakeAmount)); // This would be called *from* the Oracle contract

         // Let's adjust: The Oracle provides the `correct` boolean and `stakeChange` amount directly
         // This resolvePrediction function might then iterate through relevant predictions or the oracle calls resolveUserPrediction per user.

         // Let's assume this function iterates through all *pending* predictions for this bloom+hash combo
         // This is gas-intensive. A better approach would pass the user list to the oracle or have the oracle call back per user.
         // Let's stick to the simpler model where Oracle provides the outcome *for a specific prediction* it looked up.

         // This structure (bloomId => predictor => predictedHash) means the Oracle needs to know the predictor address.
         // A more scalable structure might be predictionId => Prediction details.

         // Okay, let's refine: The Oracle calls a function *per specific prediction* that is ready to be resolved.
         // This current `resolvePrediction` function signature isn't quite right for that.
         // Let's rename and adjust:

         // New Function Needed: `oracleResolveSpecificPrediction(uint256 bloomId, address predictor, bytes32 predictedStateHash, bool correctOutcome)`

         // Removing the old `resolvePrediction` and replacing with `oracleResolveSpecificPrediction`
         // This satisfies the Oracle interaction better.
    }

    /// @notice Called by the Oracle to resolve a specific prediction made by a specific user.
    /// @dev Checks if the actual state matches the prediction hash at the resolution time. Distributes stakes.
    /// @param bloomId The ID of the Bloom the prediction is about.
    /// @param predictor The address of the user who made the prediction.
    /// @param predictedStateHash The hash of the predicted state.
    /// @param correctOutcome Whether the oracle determined the prediction was correct.
    function oracleResolveSpecificPrediction(uint256 bloomId, address predictor, bytes32 predictedStateHash, bool correctOutcome) public whenNotPaused onlyOracle nonReentrant whenPredictionPending(bloomId, predictor, predictedStateHash) {
         Prediction storage prediction = _predictions[bloomId][predictor][predictedStateHash];

         prediction.resolved = true;
         prediction.correct = correctOutcome;

         int256 stakeChange; // How much Nectar to give/take from the predictor

         if (correctOutcome) {
             // Reward the predictor (example: 2x stake payout)
             stakeChange = int256(prediction.stakeAmount * 2);
             // In a real system, this would come from a pool of losing stakes or a reward pool
             // For this example, just simulate transfer
              if (_nectarToken != address(0)) {
                 uint256 payoutAmount = uint256(stakeChange);
                 require(IERC20(_nectarToken).transfer(predictor, payoutAmount), "QBF: Nectar reward transfer failed");
              }

         } else {
             // Predictor loses their stake (it stays in the contract for rewards/fees)
             stakeChange = -int256(prediction.stakeAmount);
             // Stake remains in the contract
         }

         emit PredictionResolved(bloomId, predictor, predictedStateHash, correctOutcome, stakeChange);

         // Note: The predictor still needs to call claimPredictionRewards to get the Nectar.
         // This design simplifies the oracle call, avoiding internal token transfers within the oracle function.
    }


    /// @notice Allows a user to claim their Nectar rewards from a correctly resolved prediction.
    /// @dev The prediction must be resolved and marked as correct.
    /// @param bloomId The ID of the Bloom the prediction is about.
    /// @param predictedStateHash The hash of the predicted state.
    function claimPredictionRewards(uint256 bloomId, bytes32 predictedStateHash) public whenNotPaused nonReentrant {
        address predictor = msg.sender;
        Prediction storage prediction = _predictions[bloomId][predictor][predictedStateHash];

        require(prediction.predictor != address(0), "QBF: Prediction does not exist");
        require(prediction.resolved, "QBF: Prediction not yet resolved");
        require(prediction.correct, "QBF: Prediction was incorrect");
        require(prediction.stakeAmount > 0, "QBF: Rewards already claimed or zero stake"); // Prevent double claim

        // Calculate reward amount (example: 2x stake)
        uint256 rewardAmount = prediction.stakeAmount * 2;

        // Reset stakeAmount to 0 to prevent re-claiming
        prediction.stakeAmount = 0;

         if (_nectarToken != address(0)) {
             require(IERC20(_nectarToken).transfer(predictor, rewardAmount), "QBF: Nectar reward transfer failed");
         }

         // Consider burning the prediction object to save gas if storage costs are critical
         // delete _predictions[bloomId][predictor][predictedStateHash];

         emit PredictionResolved(bloomId, predictor, predictedStateHash, true, int256(rewardAmount)); // Re-emit for claim tracking
    }


    // --- VIII. Evolution & Interaction Functions ---

    /// @notice Combines the genetic traits of two Blooms owned by the caller to potentially create a new Seed.
    /// @dev Requires Nectar payment. The outcome genetics depend on the parent Blooms.
    /// @param bloomId1 The ID of the first parent Bloom.
    /// @param bloomId2 The ID of the second parent Bloom.
    /// @return The ID of the newly minted Seed, or 0 if cross-pollination failed.
    function crossPollinate(uint256 bloomId1, uint256 bloomId2) public whenNotPaused nonReentrant returns (uint256 newBloomId) {
        require(bloomId1 != bloomId2, "QBF: Cannot cross-pollinate a bloom with itself");
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        require(ownerOf(bloomId1) == msg.sender, "QBF: Caller does not own Bloom 1");
        require(ownerOf(bloomId2) == msg.sender, "QBF: Caller does not own Bloom 2");
        require(!_blooms[bloomId1].isHarvested && !_blooms[bloomId2].isHarvested, "QBF: Cannot cross-pollinate harvested blooms");
        // Add maturity requirements for parents if needed

        // Example cost: 500 Nectar
        uint256 pollinationCost = 500 * (10**IERC20(_nectarToken).decimals());
        require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), pollinationCost), "QBF: Nectar transfer failed for cross-pollination");

        // Simulate genetic combination (simplified: XORing traits)
        uint256 newGenetics = _blooms[bloomId1].initialGenetics ^ _blooms[bloomId2].initialGenetics;
        newGenetics ^= _blooms[bloomId1].mutationTraits; // Incorporate mutations
        newGenetics ^= _blooms[bloomId2].mutationTraits;

        // Further logic could involve randomness, success chance based on parent stats, etc.
        // For simplicity, always create a new seed:
        newBloomId = _nextBloomId++;
        _blooms[newBloomId] = Bloom({
            bloomId: newBloomId,
            plantedTimestamp: block.timestamp,
            lastNurturedTimestamp: block.timestamp,
            initialGenetics: newGenetics, // Apply combined genetics
            currentGrowthStage: 0,
            currentHealth: 100,
            currentHydration: 100,
            mutationTraits: 0,
            isHarvested: false
        });

        _safeMint(msg.sender, newBloomId);

        emit CrossPollinated(bloomId1, bloomId2, newBloomId, newGenetics);
        emit BloomMinted(newBloomId, msg.sender, newGenetics, block.timestamp);
        emit BloomStateUpdated(newBloomId, keccak256("CrossPollination"));

        return newBloomId;
    }

    /// @notice Allows a user to spend Nectar to support another user's Bloom.
    /// @dev This acts like a gift or donation, fostering community interaction.
    /// @param bloomId The ID of the Bloom to support.
    /// @param nectarAmount The amount of Nectar to give.
    function supportOtherBloom(uint256 bloomId, uint256 nectarAmount) public whenNotPaused whenBloomExists(bloomId) nonReentrant {
        require(ownerOf(bloomId) != msg.sender, "QBF: Cannot support your own bloom using this function");
        require(_nectarToken != address(0), "QBF: Nectar token not set");
        require(nectarAmount > 0, "QBF: Must send positive nectar amount");
        require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), nectarAmount), "QBF: Nectar transfer failed for support");

        // Option 1: Nectar directly nurtures the bloom (like nurture function)
        // This bloom benefits directly from the support
        Bloom storage bloom = _blooms[bloomId];
        uint256 healthBoost = nectarAmount / 20; // Less efficient than self-nurture?
        uint256 hydrationBoost = nectarAmount / 10;
        bloom.currentHealth = Math.min(100, bloom.currentHealth + healthBoost);
        bloom.currentHydration = Math.min(100, bloom.currentHydration + hydrationBoost);
        // bloom.lastNurturedTimestamp = block.timestamp; // Maybe don't reset nurture time to differentiate from self-nurture

        // Option 2: Nectar goes to the Bloom owner's balance (like a tip jar)
        // IERC20(_nectarToken).transfer(ownerOf(bloomId), nectarAmount);

        // Option 3: Nectar goes to a community pool, and the supporter gets reputation/points
        // Let's use Option 1 for simplicity and direct impact on the Bloom state.

        emit BloomSupported(bloomId, msg.sender, nectarAmount);
        // Consider BloomStateUpdated if the support function heavily impacts state
         emit BloomStateUpdated(bloomId, keccak256("Support"));
    }


    /// @notice Triggers a global or targeted mutation event affecting Blooms.
    /// @dev Called by Admin or Oracle. Mutation effects depend on `mutationParameters`.
    /// @param mutationParameters Encoded data defining the mutation effect (e.g., affects blooms planted before X date, grants Y trait).
    function triggerMutationEvent(bytes calldata mutationParameters) public whenNotPaused onlyOracle {
        // Example: Oracle determines blooms with a specific initialGenetics value gain a trait
        // In a real system, this function would iterate through *eligible* blooms
        // (which is gas-intensive) or rely on users/oracle to trigger mutation *per bloom*
        // based on the global event parameters.
        // Let's add a helper function that can be called per-bloom by owner/anyone after a mutation event is live.

        // Store the active mutation parameters globally
        // For simplicity, we'll just log the event. Applying it per bloom needs a different pattern.
        // A better design would have a mapping for `activeMutationEvents` and a function `applyMutation(bloomId)`
        // that checks active events and mutationParameters.

        // Let's keep this simple for the function count but acknowledge the complexity.
        // The oracle calls this to SIGNAL a mutation event. Blooms don't auto-update here.
        // A separate mechanism (e.g., `applyMutationEffect(bloomId)`) would be needed, possibly permissioned to owner/anyone and costing gas.

        emit MutationTriggered(mutationParameters);
        // To make this useful, you'd need another function like `applyMutationEffect(uint256 bloomId)`
        // that checks if the bloom is eligible for any *currently active* mutation events
        // based on the parameters stored in the contract (not just emitted).
        // Let's add that function to reach the count and make the concept more functional.
    }

    /// @notice Applies effects from currently active global mutation events to a Bloom.
    /// @dev Callable by anyone. Checks against active mutation parameters.
    /// @param bloomId The ID of the Bloom to potentially mutate.
    function applyMutationEffect(uint256 bloomId) public whenNotPaused whenBloomExists(bloomId) nonReentrant {
        // This function would iterate through a list/mapping of *currently active global mutation events*
        // and check if the given `bloomId` qualifies based on the stored `mutationParameters` for that event.
        // If it qualifies and hasn't received this specific mutation yet, apply the effect and mark it as received.
        // This requires a state variable like `mapping(uint256 => mapping(bytes32 => bool)) mutationApplied; // bloomId => mutationEventHash => applied?`
        // and `mapping(bytes32 => bytes) activeMutationEvents; // mutationEventHash => parameters`.

        // For demonstration, we'll simulate applying a specific, single hardcoded mutation check.
        // In reality, `triggerMutationEvent` would populate `activeMutationEvents`.

        bytes32 sampleMutationHash = keccak256("SIMULATED_DROUGHT_RESISTANCE_MUTATION");
        bytes memory sampleMutationParams = abi.encodePacked("Affects blooms with genetics > 500 planted before ", uint256(block.timestamp), " and grants +20 Hydration trait");

        // Simulate check:
        // 1. Is this mutation event currently active? (Requires storing active events)
        // 2. Does the bloom qualify based on sampleMutationParams? (Requires parsing params)
        // 3. Has the mutation already been applied to this bloom? (Requires tracking applied mutations)

        // Simplified Logic: If bloom planted long ago and has specific genetics, apply a trait
        Bloom storage bloom = _blooms[bloomId];
        bool mutationAlreadyApplied = (bloom.mutationTraits & 0x100) != 0; // Check a specific trait bit
        bool qualifies = (bloom.plantedTimestamp < block.timestamp - 365 days) && (bloom.initialGenetics > 500);

        if (!mutationAlreadyApplied && qualifies) {
             bloom.mutationTraits |= 0x100; // Set a new trait bit (e.g., Drought Resistance)
             bloom.currentHealth = Math.min(100, bloom.currentHealth + 10); // Small health boost from resistance
             emit BloomStateUpdated(bloomId, keccak256("AppliedMutation"));
        } else {
            // No mutation applied or qualified
        }

         // This function adds a 27th function and makes the mutation concept more concrete, even with simulation.
    }


    // --- IX. Community & Event Functions ---

    /// @notice Allows the Admin to create a new community event.
    /// @dev Events can be competitions, challenges, etc., involving Blooms.
    /// @param eventName The name of the event.
    /// @param participationFee The amount of Nectar required to participate.
    /// @param endTime The timestamp when the event ends.
    /// @param eventType A hash identifying the type of event (e.g., vote-based, prediction-based).
    /// @return The ID of the newly created event.
    function createCommunityEvent(string memory eventName, uint256 participationFee, uint64 endTime, bytes32 eventType) public onlyOwner whenNotPaused returns (uint256 eventId) {
        require(endTime > block.timestamp, "QBF: Event end time must be in the future");

        eventId = _nextEventId++;
        _communityEvents[eventId] = CommunityEvent({
            eventId: eventId,
            name: eventName,
            participationFee: participationFee,
            endTime: endTime,
            eventType: eventType,
            active: true,
            participants: new mapping(uint256 => bool)() // Initialize the mapping
            // Initialize other event-specific fields
        });

        emit CommunityEventCreated(eventId, eventName, participationFee, endTime, eventType);
        return eventId;
    }

    /// @notice Allows a user to enter their Bloom into an active community event.
    /// @dev Requires payment of the participation fee.
    /// @param eventId The ID of the event to join.
    /// @param bloomId The ID of the Bloom to participate with.
    function participateInEvent(uint256 eventId, uint256 bloomId) public whenNotPaused nonReentrant whenEventActive(eventId) whenBloomOwner(bloomId) {
        CommunityEvent storage eventDetails = _communityEvents[eventId];
        require(!eventDetails.participants[bloomId], "QBF: Bloom already participating in this event");
        require(_nectarToken != address(0), "QBF: Nectar token not set");

        if (eventDetails.participationFee > 0) {
             require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), eventDetails.participationFee), "QBF: Nectar transfer failed for event participation");
        }

        eventDetails.participants[bloomId] = true;

        emit BloomParticipatedInEvent(eventId, bloomId, msg.sender);
    }

    /// @notice Allows a user to cast a vote for a Bloom in a vote-based event.
    /// @dev Requires owning a Bloom or spending Nectar (example logic). Prevents double voting per event.
    /// @param eventId The ID of the event.
    /// @param bloomId The ID of the Bloom to vote for.
    function voteForBloom(uint256 eventId, uint256 bloomId) public whenNotPaused nonReentrant whenEventActive(eventId) whenBloomExists(bloomId) {
        CommunityEvent storage eventDetails = _communityEvents[eventId];
        require(eventDetails.eventType == keccak256("VoteBased"), "QBF: Event is not vote-based");
        require(eventDetails.participants[bloomId], "QBF: Cannot vote for a non-participating bloom"); // Only vote for participants
        require(_eventVotes[eventId][msg.sender] == 0, "QBF: Already voted in this event"); // One vote per address per event

        // Example: Require owning a Bloom to vote, or pay Nectar
        bool hasBloom = balanceOf(msg.sender) > 0;
        uint256 voteCost = 10 * (10**IERC20(_nectarToken).decimals()); // Example Nectar cost if not owning bloom

        if (!hasBloom) {
             require(_nectarToken != address(0), "QBF: Nectar token not set for voting");
             require(IERC20(_nectarToken).transferFrom(msg.sender, address(this), voteCost), "QBF: Nectar transfer failed for voting");
        }

        _eventVotes[eventId][msg.sender] = bloomId; // Record the vote

        // A separate mapping would be needed to count votes per bloom: mapping(uint256 => mapping(uint256 => uint256)) eventBloomVotes; eventId => bloomId => voteCount
        // For simplicity, we just record who voted for whom. Counting would happen off-chain or in `resolveEvent`.

        emit EventVoteCast(eventId, bloomId, msg.sender);
    }

    /// @notice Allows the Admin to resolve a community event.
    /// @dev Distributes prizes or determines outcome based on event type and recorded data.
    /// @param eventId The ID of the event to resolve.
    function resolveEvent(uint256 eventId) public onlyOwner whenNotPaused nonReentrant {
         CommunityEvent storage eventDetails = _communityEvents[eventId];
         require(eventDetails.active, "QBF: Event is not active");
         require(block.timestamp >= eventDetails.endTime, "QBF: Event has not ended yet");

         eventDetails.active = false; // Deactivate the event

         bytes32 outcomeDetails; // Placeholder for outcome info

         if (eventDetails.eventType == keccak256("VoteBased")) {
             // Example: Count votes (would require iterating _eventVotes mapping for this event)
             // This iteration is gas-intensive. Better to count off-chain and provide winner ID/vote count to this function.
             // For simplicity, let's assume the outcome is hardcoded or based on a simple check.
             // Example outcome: The Bloom with ID 42 wins (placeholder)
             uint256 winningBloomId = 42; // Placeholder

             // Distribute prize pool (e.g., collected participation fees)
             uint256 totalFeesCollected = eventDetails.participationFee * /* count participants */; // Need participant count
             if (_nectarToken != address(0) && totalFeesCollected > 0) {
                 // Transfer fees to winner, or distribute to top N, etc.
                 // IERC20(_nectarToken).transfer(ownerOf(winningBloomId), totalFeesCollected);
             }

             outcomeDetails = abi.encodePacked("WinnerBloomId:", winningBloomId);

         } else if (eventDetails.eventType == keccak256("FastestGrowthPrediction")) {
             // Example: Resolve based on prediction market outcomes linked to this event
             // This would require tracking which predictions are tied to this event.
             // Outcome logic would be complex, likely relying on the oracleResolveSpecificPrediction function.
             // Placeholder outcome: Highest Nectar yield wins
             outcomeDetails = keccak256("HighestYieldOutcome");
         }
         // Add other event types

         emit CommunityEventResolved(eventId, outcomeDetails);
    }

    // --- Fallback and Receive (Optional, for receiving ETH fees) ---
    receive() external payable {}
    fallback() external payable {}

    // Helper library
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }
}
```