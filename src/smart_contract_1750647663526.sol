Okay, let's design a complex, advanced, and creative smart contract. We'll call it `QuantumVault`.

The core concept revolves around assets held in "Quantum States". Instead of belonging to a single owner, assets in a state are designated to a *set* of potential resolvers, each with a weighted probability. At a specific trigger (like a time lock expiry or manual activation), the state undergoes a "Resolution" process using verifiable randomness (Chainlink VRF). This "collapses" the quantum state, selecting a single winner among the potential resolvers based on their weights. Only the selected winner can then claim the assets from that state.

This introduces concepts like:
1.  **Probabilistic Ownership:** Assets don't have a single owner until a random process determines one.
2.  **Delayed/Conditional Access:** Assets are locked until resolution occurs.
3.  **Verifiable Randomness:** Ensures fairness in the selection process.
4.  **State Management:** Tracking different phases of an asset's lifecycle within the contract (Creation, Pending Resolution, Resolved, Claimed).
5.  **Multi-Asset Handling:** Supporting ETH, ERC20, and ERC721 within the same state structure.

Let's outline and summarize the contract.

---

## QuantumVault Smart Contract

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** OpenZeppelin (Ownable, ERC20, ERC721), Chainlink VRF (VRFConsumerBaseV2)
3.  **Custom Errors:** For various failure conditions (e.g., invalid state, unauthorized caller, not resolved).
4.  **Events:** To signal key state changes (StateCreated, AssetDeposited, ResolutionTriggered, StateResolved, AssetClaimed, ConfigUpdated).
5.  **Enums:** To define the status of a Quantum State.
6.  **Structs:**
    *   `Resolver`: Represents a potential winner with their address and weight.
    *   `QuantumState`: Holds all information for a state, including assets, resolvers, status, and resolution details.
7.  **State Variables:**
    *   Owner address.
    *   Mapping for `QuantumState`s by ID.
    *   Counter for unique State IDs.
    *   Mappings to track assets within each state (ETH, ERC20, ERC721).
    *   Chainlink VRF configuration details (keyHash, subscriptionId).
    *   Mapping to link VRF request IDs back to State IDs.
8.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `onlyStateCreatorOrOwner`: Restricts access to the state creator or contract owner. (Let's assume owner-only for state management simplicity initially, or add creator field to struct). Let's stick to owner-only for configuration and state creation/triggering resolution for complexity control, making resolvers purely passive until resolution.
    *   `onlyResolvedResolver`: Restricts access to the address determined by resolution.
    *   `onlyStateStatus`: Ensures a function is only called when a state is in a specific status.
9.  **Functions:**
    *   **Configuration (Owner Only):**
        *   `constructor`: Initializes the contract and owner.
        *   `setVrfConfig`: Sets Chainlink VRF parameters.
        *   `transferOwnership`, `renounceOwnership` (from Ownable).
    *   **Quantum State Management (Owner Only):**
        *   `createQuantumState`: Creates a new state with initial resolvers and weights.
        *   `addResolverToState`: Adds a resolver to an existing state.
        *   `removeResolverFromState`: Removes a resolver from a state.
        *   `updateResolverWeight`: Modifies a resolver's weight.
        *   `triggerResolution`: Initiates the random resolution process via Chainlink VRF.
        *   `cancelResolutionRequest`: Cancels a pending VRF request before fulfillment.
    *   **Asset Deposit (Anyone):**
        *   `depositEthToState`: Deposits ETH into a specific state.
        *   `depositErc20ToState`: Deposits ERC20 tokens into a specific state (requires approval).
        *   `depositErc721ToState`: Deposits ERC721 tokens into a specific state (requires approval/safeTransferFrom).
    *   **Chainlink VRF Integration (VRF Coordinator Only):**
        *   `fulfillRandomWords`: VRF callback function to receive randomness and trigger resolution logic.
    *   **Resolution Logic (Internal):**
        *   `_resolveState`: Internal function to select the winner based on weights and randomness.
    *   **Asset Claim (Resolved Resolver Only):**
        *   `claimResolvedEth`: Allows the resolved resolver to claim ETH.
        *   `claimResolvedErc20`: Allows the resolved resolver to claim ERC20 tokens.
        *   `claimResolvedErc721`: Allows the resolved resolver to claim ERC721 tokens.
    *   **Query Functions (Anyone):**
        *   `getQuantumStateDetails`: Get all details for a state.
        *   `getResolvedResolver`: Get the winner address after resolution.
        *   `getStateStatus`: Get the current status of a state.
        *   `getEthInState`: Get the amount of ETH currently held *for* a state.
        *   `getErc20InState`: Get the amount of a specific ERC20 token held *for* a state.
        *   `getErc721InState`: Get the list of ERC721 token IDs of a specific contract held *for* a state.
        *   `getClaimableEth`: Check if ETH is claimable for a resolved state by the caller.
        *   `getClaimableErc20`: Check if specific ERC20 is claimable for a resolved state by the caller.
        *   `getClaimableErc721`: Check if specific ERC721s are claimable for a resolved state by the caller.

**Function Summary (Total: 26 Functions):**

1.  `constructor(address initialOwner, address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)`: Deploys the contract, sets owner and initial VRF configuration.
2.  `setVrfConfig(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)`: (Owner) Updates the VRF coordinator, subscription ID, and key hash.
3.  `transferOwnership(address newOwner)`: (Owner) Transfers contract ownership.
4.  `renounceOwnership()`: (Owner) Renounces contract ownership.
5.  `createQuantumState(Resolver[] calldata initialResolvers)`: (Owner) Creates a new `QuantumState` with a unique ID and initial potential resolvers and their weights. State starts as `Created`.
6.  `addResolverToState(uint256 stateId, address resolverAddress, uint256 weight)`: (Owner) Adds a new resolver with a weight to an existing state that is in `Created` status.
7.  `removeResolverFromState(uint256 stateId, address resolverAddress)`: (Owner) Removes a resolver from a state in `Created` status. Fails if the state would end up with no resolvers.
8.  `updateResolverWeight(uint256 stateId, address resolverAddress, uint256 newWeight)`: (Owner) Updates the weight of an existing resolver in a state in `Created` status.
9.  `triggerResolution(uint256 stateId)`: (Owner) Initiates the resolution process for a state in `Created` status by requesting randomness from Chainlink VRF. Updates state status to `ResolutionPending`. Requires a VRF subscription balance.
10. `cancelResolutionRequest(uint256 stateId)`: (Owner) Cancels a pending VRF randomness request if the state is in `ResolutionPending` status and the request hasn't been fulfilled yet. Resets state status to `Created`. (Note: VRF fees for the request might not be refunded by Chainlink depending on their policy/system, this just stops the callback logic).
11. `depositEthToState(uint256 stateId) payable`: (Anyone) Sends ETH to the contract, associating it with a specific `QuantumState`. Only allowed in `Created` status.
12. `depositErc20ToState(uint256 stateId, address tokenAddress, uint256 amount)`: (Anyone) Transfers a specified amount of an ERC20 token from the caller to the contract, associating it with a `QuantumState`. Requires prior approval. Only allowed in `Created` status.
13. `depositErc721ToState(uint256 stateId, address tokenAddress, uint256 tokenId)`: (Anyone) Transfers a specific ERC721 token from the caller to the contract, associating it with a `QuantumState`. Requires prior approval or using `safeTransferFrom`. Only allowed in `Created` status.
14. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: (VRF Coordinator Only) The Chainlink VRF callback function. Receives the random number(s) and triggers the internal `_resolveState` function for the state linked to `requestId`.
15. `_resolveState(uint256 stateId, uint256 randomNumber)`: (Internal) Selects the winning resolver for a state based on their weights and the provided random number. Updates the state status to `Resolved` and sets the `resolvedResolver`.
16. `claimResolvedEth(uint256 stateId)`: (Resolved Resolver) Allows the winning resolver of a `Resolved` state to withdraw all ETH deposited for that state.
17. `claimResolvedErc20(uint256 stateId, address tokenAddress)`: (Resolved Resolver) Allows the winning resolver of a `Resolved` state to withdraw all deposited amount of a specific ERC20 token for that state.
18. `claimResolvedErc721(uint256 stateId, address tokenAddress, uint256 tokenId)`: (Resolved Resolver) Allows the winning resolver of a `Resolved` state to withdraw a specific ERC721 token deposited for that state.
19. `getQuantumStateDetails(uint256 stateId) view`: (Anyone) Returns the full details of a `QuantumState`.
20. `getResolvedResolver(uint256 stateId) view`: (Anyone) Returns the address of the winning resolver if the state is `Resolved`, otherwise returns the zero address.
21. `getStateStatus(uint256 stateId) view`: (Anyone) Returns the current status (enum) of a `QuantumState`.
22. `getEthInState(uint256 stateId) view`: (Anyone) Returns the total ETH deposited for a specific state before resolution.
23. `getErc20InState(uint256 stateId, address tokenAddress) view`: (Anyone) Returns the total amount of a specific ERC20 token deposited for a state before resolution.
24. `getErc721InState(uint256 stateId, address tokenAddress) view`: (Anyone) Returns the list of ERC721 token IDs of a specific contract deposited for a state before resolution.
25. `getClaimableEth(uint256 stateId, address claimant) view`: (Anyone) Checks if the given address can claim ETH from a `Resolved` state.
26. `getClaimableErc20(uint256 stateId, address tokenAddress, address claimant) view`: (Anyone) Checks if the given address can claim a specific ERC20 token from a `Resolved` state.
27. `getClaimableErc721(uint256 stateId, address tokenAddress, uint256 tokenId, address claimant) view`: (Anyone) Checks if the given address can claim a specific ERC721 token from a `Resolved` state.

---

Now, let's write the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Outline:
// 1. SPDX-License-Identifier & Pragma
// 2. Imports (Ownable, ERC20, ERC721, ERC721Holder, VRF)
// 3. Custom Errors
// 4. Events
// 5. Enums (QuantumStateStatus)
// 6. Structs (Resolver, QuantumState)
// 7. State Variables (owner, s_states, s_stateCount, s_vrfCoordinator, s_subscriptionId, s_keyHash, s_requestToStateId)
// 8. Modifiers (onlyOwner, onlyStateStatus)
// 9. Functions:
//    - Configuration (constructor, setVrfConfig, transferOwnership, renounceOwnership)
//    - Quantum State Management (createQuantumState, addResolverToState, removeResolverFromState, updateResolverWeight, triggerResolution, cancelResolutionRequest)
//    - Asset Deposit (depositEthToState, depositErc20ToState, depositErc721ToState)
//    - Chainlink VRF Integration (fulfillRandomWords)
//    - Resolution Logic (internal _resolveState)
//    - Asset Claim (claimResolvedEth, claimResolvedErc20, claimResolvedErc721)
//    - Query Functions (getQuantumStateDetails, getResolvedResolver, getStateStatus, getEthInState, getErc20InState, getErc721InState, getClaimableEth, getClaimableErc20, getClaimableErc721)

// Function Summary (Total: 27 Functions - Added ERC721Holder onERC721Received requirement)
// 1. constructor(address initialOwner, address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)
// 2. setVrfConfig(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash) (Owner)
// 3. transferOwnership(address newOwner) (Owner)
// 4. renounceOwnership() (Owner)
// 5. createQuantumState(Resolver[] calldata initialResolvers) (Owner)
// 6. addResolverToState(uint256 stateId, address resolverAddress, uint256 weight) (Owner, State: Created)
// 7. removeResolverFromState(uint256 stateId, address resolverAddress) (Owner, State: Created)
// 8. updateResolverWeight(uint256 stateId, address resolverAddress, uint256 newWeight) (Owner, State: Created)
// 9. triggerResolution(uint256 stateId) (Owner, State: Created)
// 10. cancelResolutionRequest(uint256 stateId) (Owner, State: ResolutionPending)
// 11. depositEthToState(uint256 stateId) payable (Anyone, State: Created)
// 12. depositErc20ToState(uint256 stateId, address tokenAddress, uint256 amount) (Anyone, State: Created)
// 13. depositErc721ToState(uint256 stateId, address tokenAddress, uint256 tokenId) (Anyone, State: Created)
// 14. onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) (ERC721Holder)
// 15. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) (VRF Coordinator Only)
// 16. _resolveState(uint256 stateId, uint256 randomNumber) (Internal)
// 17. claimResolvedEth(uint256 stateId) (Resolved Resolver, State: Resolved)
// 18. claimResolvedErc20(uint256 stateId, address tokenAddress) (Resolved Resolver, State: Resolved)
// 19. claimResolvedErc721(uint256 stateId, address tokenAddress, uint256 tokenId) (Resolved Resolver, State: Resolved)
// 20. getQuantumStateDetails(uint256 stateId) view (Anyone)
// 21. getResolvedResolver(uint256 stateId) view (Anyone)
// 22. getStateStatus(uint256 stateId) view (Anyone)
// 23. getEthInState(uint256 stateId) view (Anyone)
// 24. getErc20InState(uint256 stateId, address tokenAddress) view (Anyone)
// 25. getErc721InState(uint256 stateId, address tokenAddress) view (Anyone)
// 26. getClaimableEth(uint256 stateId, address claimant) view (Anyone)
// 27. getClaimableErc20(uint256 stateId, address tokenAddress, address claimant) view (Anyone)
// 28. getClaimableErc721(uint256 stateId, address tokenAddress, uint256 tokenId, address claimant) view (Anyone)
// Total: 28 functions (including onERC721Received and extra view functions) - Plenty over 20.

contract QuantumVault is Ownable, VRFConsumerBaseV2, ERC721Holder {

    // --- 3. Custom Errors ---
    error QuantumVault__InvalidStateStatus(uint256 stateId, QuantumStateStatus expectedStatus, QuantumStateStatus currentStatus);
    error QuantumVault__StateNotFound(uint256 stateId);
    error QuantumVault__ResolverNotFound(uint256 stateId, address resolverAddress);
    error QuantumVault__NoResolvers(uint256 stateId);
    error QuantumVault__ResolutionNotPending(uint256 stateId);
    error QuantumVault__RandomnessNotReceived(uint256 stateId);
    error QuantumVault__NotResolvedResolver(uint256 stateId, address caller);
    error QuantumVault__EthClaimFailed(address receiver);
    error QuantumVault__NothingToClaim(uint256 stateId);
    error QuantumVault__Erc721NotHeldForState(uint256 stateId, address tokenAddress, uint256 tokenId);
    error QuantumVault__VrfConfigNotSet();
    error QuantumVault__ResolverAlreadyExists(uint256 stateId, address resolverAddress);


    // --- 4. Events ---
    event StateCreated(uint256 indexed stateId, address indexed creator);
    event AssetDeposited(uint256 indexed stateId, address indexed depositor, address tokenAddress, uint256 amountOrId, bytes4 assetType); // assetType: 'ETH', 'ERC20', 'ERC721' bytes4
    event ResolutionTriggered(uint256 indexed stateId, uint256 indexed requestId);
    event StateResolved(uint256 indexed stateId, address indexed winningResolver);
    event AssetClaimed(uint256 indexed stateId, address indexed claimant, address tokenAddress, uint256 amountOrId, bytes4 assetType); // assetType: 'ETH', 'ERC20', 'ERC721' bytes4
    event VrfConfigUpdated(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash);
    event ResolutionRequestCancelled(uint256 indexed stateId, uint256 indexed requestId);


    // --- 5. Enums ---
    enum QuantumStateStatus {
        Created,            // State is open for adding assets and resolvers
        ResolutionPending,  // Randomness requested from VRF, waiting for fulfillment
        Resolved            // Randomness received, winner determined, assets claimable by winner
    }

    // --- 6. Structs ---
    struct Resolver {
        address resolverAddress;
        uint256 weight; // Represents probability weight
    }

    struct QuantumState {
        QuantumStateStatus status;
        Resolver[] resolvers; // List of potential winners and their weights
        uint256 totalWeight; // Sum of all resolver weights
        address resolvedResolver; // The determined winner after resolution
        uint256 resolvedTime; // Timestamp of resolution
        uint256 randomnessRequestId; // Chainlink VRF request ID for this state
    }

    // --- 7. State Variables ---
    mapping(uint256 => QuantumState) private s_states;
    uint256 private s_stateCount; // Starts at 0, state IDs will be 1-indexed

    // Asset Holdings per State
    mapping(uint256 => uint256) private s_ethAmounts; // stateId => ETH amount
    mapping(uint256 => mapping(address => uint256)) private s_erc20Amounts; // stateId => tokenAddress => amount
    mapping(uint256 => mapping(address => uint256[])) private s_erc721Tokens; // stateId => tokenAddress => list of tokenIds

    // Chainlink VRF configuration
    VRFCoordinatorV2Interface private s_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private constant NUM_WORDS = 1; // We only need one random number

    // Mapping Chainlink VRF request IDs to our State IDs
    mapping(uint256 => uint256) private s_requestToStateId;


    // --- 8. Modifiers ---
    modifier onlyStateStatus(uint256 _stateId, QuantumStateStatus _expectedStatus) {
        if (s_states[_stateId].status != _expectedStatus) {
             revert QuantumVault__InvalidStateStatus(_stateId, _expectedStatus, s_states[_stateId].status);
        }
        _;
    }

    modifier onlyResolvedResolver(uint256 _stateId) {
        if (s_states[_stateId].resolvedResolver != msg.sender) {
            revert QuantumVault__NotResolvedResolver(_stateId, msg.sender);
        }
        _;
    }


    // --- 9. Functions ---

    // --- Configuration ---

    // 1. constructor
    constructor(address initialOwner, address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)
        Ownable(initialOwner)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        emit VrfConfigUpdated(vrfCoordinator, subscriptionId, keyHash);
    }

    // 2. setVrfConfig
    function setVrfConfig(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash) external onlyOwner {
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        emit VrfConfigUpdated(vrfCoordinator, subscriptionId, keyHash);
    }

    // 3. transferOwnership - inherited from Ownable
    // 4. renounceOwnership - inherited from Ownable


    // --- Quantum State Management ---

    // 5. createQuantumState
    function createQuantumState(Resolver[] calldata initialResolvers) external onlyOwner returns (uint256 newStateId) {
        require(s_vrfCoordinator != address(0), "VRF config not set"); // Ensure VRF is configured

        s_stateCount++;
        newStateId = s_stateCount;
        QuantumState storage newState = s_states[newStateId];

        newState.status = QuantumStateStatus.Created;
        newState.resolvers = new Resolver[](0); // Initialize dynamic array
        newState.totalWeight = 0;
        // resolvedResolver and resolvedTime will be zero/unset initially

        uint256 currentTotalWeight = 0;
        for (uint i = 0; i < initialResolvers.length; i++) {
            require(initialResolvers[i].resolverAddress != address(0), "Zero address not allowed");
            require(initialResolvers[i].weight > 0, "Weight must be positive");

            // Check for duplicate resolvers (basic check, could be optimized)
            bool found = false;
            for(uint j = 0; j < newState.resolvers.length; j++) {
                if (newState.resolvers[j].resolverAddress == initialResolvers[i].resolverAddress) {
                    found = true;
                    break;
                }
            }
            if (found) revert QuantumVault__ResolverAlreadyExists(newStateId, initialResolvers[i].resolverAddress);

            newState.resolvers.push(initialResolvers[i]);
            currentTotalWeight += initialResolvers[i].weight;
        }
        newState.totalWeight = currentTotalWeight;
        require(newState.totalWeight > 0, "Must have at least one resolver with positive weight");

        emit StateCreated(newStateId, msg.sender);
    }

    // 6. addResolverToState
    function addResolverToState(uint256 stateId, address resolverAddress, uint256 weight)
        external
        onlyOwner
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        QuantumState storage state = s_states[stateId];
        require(resolverAddress != address(0), "Zero address not allowed");
        require(weight > 0, "Weight must be positive");

        // Check if resolver already exists
        for (uint i = 0; i < state.resolvers.length; i++) {
            if (state.resolvers[i].resolverAddress == resolverAddress) {
                 revert QuantumVault__ResolverAlreadyExists(stateId, resolverAddress);
            }
        }

        state.resolvers.push(Resolver({resolverAddress: resolverAddress, weight: weight}));
        state.totalWeight += weight;
    }

    // 7. removeResolverFromState
    function removeResolverFromState(uint256 stateId, address resolverAddress)
        external
        onlyOwner
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        QuantumState storage state = s_states[stateId];
        bool found = false;
        uint256 indexToRemove = state.resolvers.length; // Use length as a sentinel value

        for (uint i = 0; i < state.resolvers.length; i++) {
            if (state.resolvers[i].resolverAddress == resolverAddress) {
                state.totalWeight -= state.resolvers[i].weight;
                indexToRemove = i;
                found = true;
                break;
            }
        }

        if (!found) {
            revert QuantumVault__ResolverNotFound(stateId, resolverAddress);
        }

        // Remove by swapping with last element and popping
        if (indexToRemove < state.resolvers.length - 1) {
            state.resolvers[indexToRemove] = state.resolvers[state.resolvers.length - 1];
        }
        state.resolvers.pop();

        if (state.resolvers.length == 0) {
             revert QuantumVault__NoResolvers(stateId); // Prevent state with no resolvers
        }
    }

    // 8. updateResolverWeight
     function updateResolverWeight(uint256 stateId, address resolverAddress, uint256 newWeight)
        external
        onlyOwner
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        QuantumState storage state = s_states[stateId];
        require(newWeight > 0, "Weight must be positive");

        bool found = false;
        for (uint i = 0; i < state.resolvers.length; i++) {
            if (state.resolvers[i].resolverAddress == resolverAddress) {
                state.totalWeight = state.totalWeight - state.resolvers[i].weight + newWeight;
                state.resolvers[i].weight = newWeight;
                found = true;
                break;
            }
        }

        if (!found) {
            revert QuantumVault__ResolverNotFound(stateId, resolverAddress);
        }
    }


    // 9. triggerResolution
    function triggerResolution(uint256 stateId)
        external
        onlyOwner
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        QuantumState storage state = s_states[stateId];
        require(state.resolvers.length > 0 && state.totalWeight > 0, "State has no valid resolvers");
        if (s_vrfCoordinator == address(0)) revert QuantumVault__VrfConfigNotSet();


        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS, // Use default value from VRFConsumerBaseV2
            CALLBACK_GAS_LIMIT,    // Use default value from VRFConsumerBaseV2
            NUM_WORDS
        );

        state.status = QuantumStateStatus.ResolutionPending;
        state.randomnessRequestId = requestId; // Store the request ID
        s_requestToStateId[requestId] = stateId; // Map request ID back to state ID

        emit ResolutionTriggered(stateId, requestId);
    }

    // 10. cancelResolutionRequest
     function cancelResolutionRequest(uint256 stateId)
        external
        onlyOwner
        onlyStateStatus(stateId, QuantumStateStatus.ResolutionPending)
    {
        QuantumState storage state = s_states[stateId];
        uint256 requestId = state.randomnessRequestId;

        // Check if the request is still pending (might be simplistic, Chainlink node side tracking is complex)
        // A more robust check would require keeper integration or off-chain monitoring.
        // For this example, we assume if fulfillRandomWords hasn't been called, it's pending.
        // In a real system, you'd need to be careful about race conditions.

        // Reset state
        state.status = QuantumStateStatus.Created;
        state.randomnessRequestId = 0; // Reset request ID
        delete s_requestToStateId[requestId]; // Remove mapping

        emit ResolutionRequestCancelled(stateId, requestId);
    }


    // --- Asset Deposit ---

    // 11. depositEthToState
    function depositEthToState(uint256 stateId)
        external
        payable
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        require(msg.value > 0, "Must deposit non-zero ETH");
        s_ethAmounts[stateId] += msg.value;
        emit AssetDeposited(stateId, msg.sender, address(0), msg.value, bytes4('ETH'));
    }

    // 12. depositErc20ToState
    function depositErc20ToState(uint256 stateId, address tokenAddress, uint256 amount)
        external
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        require(amount > 0, "Must deposit non-zero amount");
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        uint256 initialBalance = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 transferredAmount = token.balanceOf(address(this)) - initialBalance;
        require(transferredAmount == amount, "ERC20 transfer failed"); // Ensure transfer happened

        s_erc20Amounts[stateId][tokenAddress] += amount;
        emit AssetDeposited(stateId, msg.sender, tokenAddress, amount, bytes4('ERC20'));
    }

    // 13. depositErc721ToState
    function depositErc721ToState(uint256 stateId, address tokenAddress, uint256 tokenId)
        external
        onlyStateStatus(stateId, QuantumStateStatus.Created)
    {
        require(tokenAddress != address(0), "Invalid token address");
        IERC721 token = IERC721(tokenAddress);

        // The ERC721Holder base contract includes onERC721Received.
        // The depositor should use safeTransferFrom to trigger the callback.
        // We don't call transferFrom directly here, but instruct users to use safeTransferFrom
        // or handle approvals and owner calling transferFrom explicitly if needed.
        // A simple way is to require the caller to be the owner and have approved THIS contract.
        // Or even better, instruct users to call safeTransferFrom directly *to* this contract.
        // Let's use the latter - user calls safeTransferFrom to the contract.
        // The onERC721Received function will handle associating the token ID with the state ID.

        // Store the state ID temporarily before the transfer is expected to call onERC721Received
        // A more robust mapping would be needed for multiple concurrent deposits
        // For simplicity, we'll rely on the user calling safeTransferFrom *with* the state ID in the data.
        // User must call: IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, abi.encode(stateId));

        // So, this function's primary purpose becomes validation and user instruction,
        // or alternatively, it handles the transfer if user approves first.
        // Let's assume the user approves this contract and calls this function which executes transferFrom.
        // This is simpler for the function count requirement.

         token.transferFrom(msg.sender, address(this), tokenId); // Requires prior approval
         s_erc721Tokens[stateId][tokenAddress].push(tokenId);
         emit AssetDeposited(stateId, msg.sender, tokenAddress, tokenId, bytes4('ERC721'));
    }

    // 14. onERC721Received
    // This function is required by ERC721Holder.
    // We override it *but* we expect deposits via depositErc721ToState for state association.
    // We could potentially use the `data` field in safeTransferFrom to pass the stateId,
    // making direct safeTransferFrom calls possible, but the current depositErc721ToState
    // function handles the state association after a transferFrom.
    // This override is mainly to satisfy the ERC721Holder interface.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Check if the sender is an expected token contract
        // Optional: Check if `from` is not address(0) and not address(this)
        // We don't do state association here because depositErc721ToState handles it.
        // This function is mainly a safety check for receiving ERC721s.
        // If the intention was to use data to pass state ID, this logic would be here.
        // Since we push to s_erc721Tokens in depositErc721ToState, this override is just compliance.
        // Returning the magic value signals successful reception.
        return this.onERC721Received.selector;
    }


    // --- Chainlink VRF Integration ---

    // 15. fulfillRandomWords
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 stateId = s_requestToStateId[requestId];
        if (stateId == 0) {
            // This VRF request was not initiated by our contract, or stateId was reset.
            // Log this or handle silently.
            return;
        }

        QuantumState storage state = s_states[stateId];

        // Check if the state is actually pending this specific request
        if (state.status != QuantumStateStatus.ResolutionPending || state.randomnessRequestId != requestId) {
            // This could happen if cancelResolutionRequest was called or fulfillment is duplicated.
            // Ignore or log.
            return;
        }

        // We requested only one word
        require(randomWords.length > 0, "Not enough random words");
        uint256 randomNumber = randomWords[0];

        // Execute the internal resolution logic
        _resolveState(stateId, randomNumber);

        // Clean up the request mapping
        delete s_requestToStateId[requestId];
    }


    // --- Resolution Logic (Internal) ---

    // 16. _resolveState
    function _resolveState(uint256 stateId, uint256 randomNumber) internal {
        QuantumState storage state = s_states[stateId];
        require(state.status == QuantumStateStatus.ResolutionPending, "State must be ResolutionPending"); // Double-check
        require(state.totalWeight > 0, "State must have total weight > 0 for resolution");

        uint256 selectionValue = randomNumber % state.totalWeight;
        uint256 cumulativeWeight = 0;
        address winningResolver = address(0);

        // Iterate through resolvers to find the winner based on weights
        for (uint i = 0; i < state.resolvers.length; i++) {
            cumulativeWeight += state.resolvers[i].weight;
            if (selectionValue < cumulativeWeight) {
                winningResolver = state.resolvers[i].resolverAddress;
                break; // Found the winner
            }
        }

        // Update state status and winner
        state.status = QuantumStateStatus.Resolved;
        state.resolvedResolver = winningResolver;
        state.resolvedTime = block.timestamp;

        emit StateResolved(stateId, winningResolver);
    }


    // --- Asset Claim ---

    // 17. claimResolvedEth
    function claimResolvedEth(uint256 stateId)
        external
        onlyResolvedResolver(stateId)
        onlyStateStatus(stateId, QuantumStateStatus.Resolved)
    {
        uint256 amount = s_ethAmounts[stateId];
        if (amount == 0) revert QuantumVault__NothingToClaim(stateId);

        delete s_ethAmounts[stateId]; // Clear the state's ETH balance

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // Revert the state change if ETH transfer fails
            s_ethAmounts[stateId] = amount; // Restore the balance
            revert QuantumVault__EthClaimFailed(msg.sender);
        }

        emit AssetClaimed(stateId, msg.sender, address(0), amount, bytes4('ETH'));
    }

    // 18. claimResolvedErc20
    function claimResolvedErc20(uint256 stateId, address tokenAddress)
        external
        onlyResolvedResolver(stateId)
        onlyStateStatus(stateId, QuantumStateStatus.Resolved)
    {
        require(tokenAddress != address(0), "Invalid token address");
        uint256 amount = s_erc20Amounts[stateId][tokenAddress];
        if (amount == 0) revert QuantumVault__NothingToClaim(stateId);

        delete s_erc20Amounts[stateId][tokenAddress]; // Clear the state's ERC20 balance for this token

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);

        emit AssetClaimed(stateId, msg.sender, tokenAddress, amount, bytes4('ERC20'));
    }

    // 19. claimResolvedErc721
    function claimResolvedErc721(uint256 stateId, address tokenAddress, uint256 tokenId)
        external
        onlyResolvedResolver(stateId)
        onlyStateStatus(stateId, QuantumStateStatus.Resolved)
    {
        require(tokenAddress != address(0), "Invalid token address");
        IERC721 token = IERC721(tokenAddress);

        // Check if this specific token ID is associated with this state
        // Note: Storing token IDs in a dynamic array per state/token makes lookup O(N).
        // For a large number of tokens per state, a mapping(tokenId => bool) would be better,
        // but claiming would need to iterate or claim one by one.
        // Let's implement the one-by-one claim for simplicity based on the current storage.

        uint256[] storage tokenIdsForState = s_erc721Tokens[stateId][tokenAddress];
        bool found = false;
        uint256 indexToClaim = tokenIdsForState.length;

        for(uint i = 0; i < tokenIdsForState.length; i++) {
            if (tokenIdsForState[i] == tokenId) {
                indexToClaim = i;
                found = true;
                break;
            }
        }

        if (!found) {
            revert QuantumVault__Erc721NotHeldForState(stateId, tokenAddress, tokenId);
        }

        // Remove the token ID from the list for this state
        if (indexToClaim < tokenIdsForState.length - 1) {
            tokenIdsForState[indexToClaim] = tokenIdsForState[tokenIdsForState.length - 1];
        }
        tokenIdsForState.pop();

        token.transferFrom(address(this), msg.sender, tokenId);

        emit AssetClaimed(stateId, msg.sender, tokenAddress, tokenId, bytes4('ERC721'));
    }


    // --- Query Functions ---

    // 20. getQuantumStateDetails
    function getQuantumStateDetails(uint256 stateId)
        external
        view
        returns (
            QuantumStateStatus status,
            Resolver[] memory resolvers,
            uint256 totalWeight,
            address resolvedResolver,
            uint256 resolvedTime,
            uint256 randomnessRequestId
        )
    {
        require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist"); // Check existence
        QuantumState storage state = s_states[stateId];
        return (
            state.status,
            state.resolvers,
            state.totalWeight,
            state.resolvedResolver,
            state.resolvedTime,
            state.randomnessRequestId
        );
    }

    // 21. getResolvedResolver
    function getResolvedResolver(uint256 stateId) external view returns (address) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
        return s_states[stateId].resolvedResolver;
    }

    // 22. getStateStatus
     function getStateStatus(uint256 stateId) external view returns (QuantumStateStatus) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
        return s_states[stateId].status;
    }

    // 23. getEthInState
    function getEthInState(uint256 stateId) external view returns (uint256) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
        return s_ethAmounts[stateId];
    }

    // 24. getErc20InState
     function getErc20InState(uint256 stateId, address tokenAddress) external view returns (uint256) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
         require(tokenAddress != address(0), "Invalid token address");
        return s_erc20Amounts[stateId][tokenAddress];
    }

    // 25. getErc721InState
     function getErc721InState(uint256 stateId, address tokenAddress) external view returns (uint256[] memory) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
         require(tokenAddress != address(0), "Invalid token address");
        return s_erc721Tokens[stateId][tokenAddress];
    }

    // 26. getClaimableEth
     function getClaimableEth(uint256 stateId, address claimant) external view returns (bool) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
        return s_states[stateId].status == QuantumStateStatus.Resolved
               && s_states[stateId].resolvedResolver == claimant
               && s_ethAmounts[stateId] > 0;
    }

    // 27. getClaimableErc20
    function getClaimableErc20(uint256 stateId, address tokenAddress, address claimant) external view returns (bool) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
         require(tokenAddress != address(0), "Invalid token address");
        return s_states[stateId].status == QuantumStateStatus.Resolved
               && s_states[stateId].resolvedResolver == claimant
               && s_erc20Amounts[stateId][tokenAddress] > 0;
    }

    // 28. getClaimableErc721
    function getClaimableErc721(uint256 stateId, address tokenAddress, uint256 tokenId, address claimant) external view returns (bool) {
         require(s_states[stateId].status != QuantumStateStatus(0) || stateId == s_stateCount, "State does not exist");
         require(tokenAddress != address(0), "Invalid token address");
        if (s_states[stateId].status != QuantumStateStatus.Resolved || s_states[stateId].resolvedResolver != claimant) {
            return false;
        }

        // Check if the specific token ID exists for this state
        uint256[] storage tokenIdsForState = s_erc721Tokens[stateId][tokenAddress];
         for(uint i = 0; i < tokenIdsForState.length; i++) {
            if (tokenIdsForState[i] == tokenId) {
                return true; // Found it, and claimant is the resolved resolver
            }
        }
        return false; // Token ID not found for this state or claimant isn't winner
    }

    // Fallback to receive ETH not associated with a state (optional, but good practice for vaults)
    // receive() external payable {
    //     // ETH sent without calling depositEthToState function is just held by the contract.
    //     // Consider adding a mechanism for the owner to withdraw this general balance if needed.
    // }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Quantum States & Resolution:** The core idea of assets being in a probabilistic state (`Created`) that collapses (`Resolved`) based on randomness is a creative interpretation of quantum mechanics principles (superposition, observation) applied to asset ownership logic on the blockchain.
2.  **Weighted Probabilistic Access:** Using resolver weights with Chainlink VRF allows for non-uniform probability distribution in determining the asset winner, enabling use cases like tiered rewards or proportional chances based on contributions/factors determined off-chain.
3.  **Verifiable Randomness:** Reliance on Chainlink VRF makes the resolution process transparent and resistant to manipulation, a crucial feature for any probabilistic or game-like contract.
4.  **Multi-Asset Vault:** Handling ETH, ERC20, and ERC721 within the same state structure provides flexibility for managing diverse digital assets under the same complex access rules.
5.  **Explicit State Management:** The `QuantumStateStatus` enum and the logic transitions (`Created` -> `ResolutionPending` -> `Resolved`) create a clear, enforced state machine for the lifecycle of assets within the vault.
6.  **Separation of Concerns:** Deposit functions allow anyone to add assets to a state (if `Created`), while state management and resolution triggering are restricted to the owner, and claiming is restricted to the randomly determined winner.
7.  **ERC721Holder Integration:** Using `ERC721Holder` demonstrates best practices for receiving NFTs securely. (Although the current implementation primarily uses `transferFrom` in `depositErc721ToState` and relies on prior approval for simplicity, the `onERC721Received` override is still part of the interface compliance).

This contract goes beyond standard token or simple escrow patterns by introducing a novel access control mechanism driven by probabilistic resolution and verifiable randomness, managed through distinct states. The inclusion of multiple asset types and Chainlink VRF integration adds layers of complexity and real-world applicability for scenarios requiring fair, random distribution of diverse assets.