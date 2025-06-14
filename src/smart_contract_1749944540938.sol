Okay, let's create an interesting and advanced smart contract concept. We'll combine ideas from conditional trading, external data dependency, and uncertainty, wrapped in a creative theme.

Introducing the **QuantumEntanglementTradingPost**.

This contract allows users to deposit assets (ERC20 or ERC721) into "entangled pairs." These pairs represent a potential swap that is in a state of "superposition" until a specific external condition is met (via an oracle). When the condition is met, the "superposition collapses," and the outcome (which asset goes to whom) is determined, potentially probabilistically, based on the oracle's input.

This is *not* a simple swap like Uniswap or OpenSea. It's about setting up trades contingent on future events, introducing speculative elements and reliance on external, verifiable data (simulated here by a mock oracle).

---

**Smart Contract: QuantumEntanglementTradingPost**

**Outline:**

1.  ** SPDX License & Pragma**
2.  ** Imports:** ERC20, ERC721 interfaces, Ownable, Pausable, Context
3.  ** Error Definitions**
4.  ** Interfaces:**
    *   `IQuantumCollapseOracle`: Interface for the external oracle providing the "collapse" data.
5.  ** Libraries:** (None strictly necessary for this structure, but could be added for complex math)
6.  ** Data Structures:**
    *   `Asset`: Struct to represent either an ERC20 (address, amount) or ERC721 (address, ID).
    *   `EntanglementState`: Enum (Pending, Active, Collapsed, Cancelled).
    *   `ResolutionMethod`: Enum (OracleDirect, OracleWeightedRandom).
    *   `EntanglementPair`: Struct containing all details of an entangled pair.
7.  ** State Variables:**
    *   `pairCounter`: Unique ID for each pair.
    *   `entanglementPairs`: Mapping from pair ID to `EntanglementPair`.
    *   `userPairs`: Mapping from user address to an array of pair IDs they are involved in.
    *   `quantumOracleAddress`: Address of the trusted oracle contract.
    *   `allowedCollapsers`: Mapping of address => bool, allowing specific entities (e.g., relayers) to trigger collapse.
    *   `protocolFeeRecipient`: Address to receive protocol fees.
    *   `protocolFeePercentage`: Fee percentage (e.g., Basis Points).
8.  ** Events:**
    *   `EntanglementCreated`
    *   `EntanglementJoined`
    *   `EntanglementConditionsSet`
    *   `EntanglementProbabilitiesSet`
    *   `EntanglementCancelled`
    *   `EntanglementDisentangled`
    *   `CollapseTriggered`
    *   `AssetClaimed`
    *   `OracleAddressSet`
    *   `CollapserAllowanceSet`
    *   `FeeRecipientSet`
    *   `FeePercentageSet`
    *   `FeesWithdrawn`
    *   `ContractPaused`
    *   `ContractUnpaused`
9.  ** Modifiers:** (None specific, but could use `whenNotPaused`, `onlyOwner`)
10. ** Constructor:** Sets initial owner, fee recipient, oracle.
11. ** Core Logic Functions (State Changes):**
    *   `createEntanglementERC20`: Create a new pair (ERC20 <-> Target Asset), can be open or specific counterparty.
    *   `createEntanglementERC721`: Create a new pair (ERC721 <-> Target Asset), can be open or specific counterparty.
    *   `joinEntanglement`: Counterparty joins an existing open pair. Handles asset deposit.
    *   `setEntanglementConditions`: Initiator/Counterparty can set/modify conditions *before* join/collapse.
    *   `setEntanglementProbabilities`: Initiator/Counterparty can set/modify probabilities *before* join/collapse (if method is OracleWeightedRandom).
    *   `cancelEntanglementByInitiator`: Initiator cancels before a counterparty joins.
    *   `disentangle`: Either party cancels *after* joining but before collapse (potentially with penalty).
    *   `triggerCollapse`: Callable by oracle or allowed collapsers to resolve the pair based on oracle data.
    *   `claimAsset`: Allows a party to claim their received asset after collapse.
12. ** Utility/Helper Functions (Internal):**
    *   `_transferAsset`: Handles sending ERC20 or ERC721.
    *   `_receiveAsset`: Handles receiving ERC20 or ERC721 (checks allowance/ownership).
    *   `_executeCollapse`: Internal function to perform the asset transfer logic based on the collapse outcome.
    *   `_isAllowedCollapser`: Checks if an address can trigger collapse.
    *   `_addPairToUserList`: Adds a pair ID to a user's list.
    *   `_removePairFromUserList`: Removes a pair ID from a user's list (less critical for gas, maybe leave stale?).
13. ** View Functions (Read-Only):**
    *   `getEntanglementState`: Get the current state of a pair.
    *   `getEntanglementPair`: Get all details of a specific pair.
    *   `getUserEntanglementPairs`: Get list of pair IDs for a user.
    *   `getQuantumOracleAddress`: Get the current oracle address.
    *   `isAllowedCollapser`: Check if an address is allowed to trigger collapse.
    *   `getProtocolFeeRecipient`: Get fee recipient.
    *   `getProtocolFeePercentage`: Get fee percentage.
14. ** Administrative Functions (Owner-Only):**
    *   `setQuantumOracleAddress`: Set the address of the trusted oracle.
    *   `addAllowedCollapser`: Grant permission to an address to trigger collapse.
    *   `removeAllowedCollapser`: Revoke permission from an address to trigger collapse.
    *   `setProtocolFeeRecipient`: Set address for protocol fees.
    *   `setProtocolFeePercentage`: Set percentage for protocol fees.
    *   `withdrawProtocolFees`: Owner withdraws accumulated protocol fees.
    *   `pauseContract`: Pause sensitive operations.
    *   `unpauseContract`: Unpause the contract.

**Function Summary:**

1.  `createEntanglementERC20(address assetAContract, uint256 assetAAmount, Asset calldata targetAssetB, address counterparty, bytes calldata activationConditions, ResolutionMethod resolutionMethod, bytes calldata resolutionData, uint48 expirationBlock)`: Initiates an entanglement pair where the creator deposits ERC20 `assetA`. Specifies the desired `targetAssetB`, optionally a specific `counterparty` (0x0 for open), `activationConditions` (data interpreted by QCO), `resolutionMethod`, associated `resolutionData`, and `expirationBlock`. Requires approval for `assetA`.
2.  `createEntanglementERC721(address assetAContract, uint256 assetAId, Asset calldata targetAssetB, address counterparty, bytes calldata activationConditions, ResolutionMethod resolutionMethod, bytes calldata resolutionData, uint48 expirationBlock)`: Similar to `createEntanglementERC20`, but for depositing an ERC721 token. Requires approval/setApprovalForAll for `assetA`.
3.  `joinEntanglement(uint256 pairId, Asset calldata assetB)`: A counterparty deposits `assetB` to join an existing open entanglement pair identified by `pairId`. Verifies `assetB` matches the target B specified by the initiator. Requires approval for `assetB`.
4.  `setEntanglementConditions(uint256 pairId, bytes calldata newConditions)`: Allows the initiator or counterparty (if allowed by pair rules) to modify the `activationConditions` before the pair becomes active or collapses. Conditions are interpreted by the QCO.
5.  `setEntanglementProbabilities(uint256 pairId, bytes calldata newResolutionData)`: Allows modifying the `resolutionData` for `OracleWeightedRandom` method before collapse. This data could encode weights for different outcomes.
6.  `cancelEntanglementByInitiator(uint256 pairId)`: The initiator can cancel a pair that is in the `Pending` state (no counterparty has joined yet). Deposits are returned.
7.  `disentangle(uint256 pairId)`: Allows either the initiator or counterparty to withdraw their deposited asset after the pair is `Active` but before it `Collapses`. This might incur a penalty fee (sent to protocol or other party).
8.  `triggerCollapse(uint256 pairId, bytes calldata oracleData)`: This function is called by the trusted `quantumOracleAddress` or an `allowedCollapser`. It checks if `activationConditions` are met based on `oracleData` and chain state. If active, it executes the `resolutionMethod` using `oracleData` to determine the outcome and transitions the pair to `Collapsed`.
9.  `claimAsset(uint256 pairId)`: Allows a user involved in a `Collapsed` pair to claim the asset they are entitled to based on the collapse outcome. Assets are transferred from the contract.
10. `getEntanglementState(uint256 pairId) view returns (EntanglementState)`: Returns the current state of a specific entanglement pair.
11. `getEntanglementPair(uint256 pairId) view returns (EntanglementPair)`: Returns all details of a specific entanglement pair.
12. `getUserEntanglementPairs(address user) view returns (uint256[] memory)`: Returns an array of pair IDs that the specified user is involved in. (Note: Simple implementation might just track initiated/joined, not all states).
13. `getQuantumOracleAddress() view returns (address)`: Returns the address of the configured Quantum Collapse Oracle.
14. `isAllowedCollapser(address collapser) view returns (bool)`: Checks if an address is explicitly allowed to trigger collapses.
15. `getProtocolFeeRecipient() view returns (address)`: Returns the address designated to receive protocol fees.
16. `getProtocolFeePercentage() view returns (uint256)`: Returns the protocol fee percentage in Basis Points.
17. `setQuantumOracleAddress(address _quantumOracleAddress)`: Owner-only. Sets the address of the trusted oracle.
18. `addAllowedCollapser(address collapser)`: Owner-only. Grants permission to an address to call `triggerCollapse`.
19. `removeAllowedCollapser(address collapser)`: Owner-only. Revokes permission from an address to call `triggerCollapse`.
20. `setProtocolFeeRecipient(address _protocolFeeRecipient)`: Owner-only. Sets the address for fee collection.
21. `setProtocolFeePercentage(uint256 _protocolFeePercentage)`: Owner-only. Sets the fee percentage (in basis points, max 10000).
22. `withdrawProtocolFees(address tokenAddress)`: Owner-only. Allows the owner to withdraw collected fees for a specific token.
23. `pauseContract()`: Owner-only. Pauses sensitive functions (creation, joining, disentangling, claiming, triggering collapse).
24. `unpauseContract()`: Owner-only. Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/token/erc721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Error Definitions
error InvalidAssetParameters();
error OnlyOneAssetTypePerSlot();
error CannotEntangleSameAssetType();
error InvalidExpiration();
error PairDoesNotExist(uint256 pairId);
error PairNotInState(uint256 pairId, EntanglementState expectedState);
error PairNotOpen(uint256 pairId);
error InvalidCounterparty(uint256 pairId, address user);
error AssetBMismatch(uint256 pairId);
error ApprovalNeeded(address token, address owner, address spender, uint256 amountOrId);
error TransferFailed(address token, address from, address to, uint256 amountOrId);
error InvalidOracleAddress();
error NotAllowedCollapser(address caller);
error ActivationConditionsNotMet(uint256 pairId);
error PairAlreadyCollapsedOrCancelled(uint256 pairId);
error NothingToClaim(uint256 pairId, address user);
error InvalidFeePercentage(uint256 percentage);
error NoFeesCollected(address tokenAddress);

// Interface for the Quantum Collapse Oracle
// This interface is a mock. A real implementation would be more complex,
// potentially based on Chainlink VRF, external adapters, etc.
interface IQuantumCollapseOracle {
    // Example function to request data - real oracle might have request patterns
    // function requestCollapseData(uint256 pairId, bytes calldata conditions, bytes calldata resolutionData) external;

    // Example function that the oracle calls back to provide data
    // This is just a concept; actual oracle integration varies greatly.
    // The data could be a random number, a price, etc.
    // function fulfillCollapse(uint256 pairId, bytes calldata oracleData) external;

    // For our simplified example, we assume the oracle (or allowed collapser)
    // *provides* the data directly when calling triggerCollapse.
    // The oracle interface serves mainly to identify the trusted caller.
}

contract QuantumEntanglementTradingPost is Ownable, Pausable, ERC721Holder { // Inherit ERC721Holder to receive NFTs

    // --- Data Structures ---

    struct Asset {
        address contractAddress;
        uint256 amountOrId; // amount for ERC20, tokenId for ERC721
        bool isERC721;
    }

    enum EntanglementState {
        Pending,    // Created, waiting for counterparty (if open) or activation
        Active,     // Joined by counterparty (if open) and/or conditions met, waiting for collapse trigger
        Collapsed,  // Resolved by oracle trigger, outcome determined, assets ready to claim
        Cancelled,  // Initiator cancelled before joined
        Disentangled // Parties cancelled after joined but before collapse
    }

    enum ResolutionMethod {
        OracleDirect,         // Oracle data directly determines outcome (e.g., 0/1 for AssetA/AssetB win)
        OracleWeightedRandom  // Oracle data provides entropy for weighted probabilistic outcome
    }

    struct EntanglementPair {
        uint256 id;
        address initiator;
        address counterparty; // 0x0 for open pairs
        Asset assetA; // Asset deposited by initiator
        Asset targetAssetB; // Asset desired by initiator / required from counterparty
        Asset receivedAssetA; // The asset initiator gets back or receives from counterparty
        Asset receivedAssetB; // The asset counterparty gets back or receives from initiator

        EntanglementState state;
        address currentHolderA; // Who is entitled to assetA's outcome after collapse
        address currentHolderB; // Who is entitled to assetB's outcome after collapse

        bytes activationConditions; // Data interpreted by QCO to see if trade becomes 'Active'
        ResolutionMethod resolutionMethod;
        bytes resolutionData; // Data interpreted by contract/QCO for collapse outcome (e.g., weights)

        uint48 expirationBlock; // Block number after which the pair cannot collapse (can be disentangled/cancelled)
        bool collapsed; // Flag set once collapse is triggered

        // Claim tracking
        bool initiatorClaimed;
        bool counterpartyClaimed;
    }

    // --- State Variables ---

    uint256 private pairCounter;
    mapping(uint256 => EntanglementPair) public entanglementPairs;
    // Simple mapping to track pairs a user is involved in. Not exhaustive of all states.
    mapping(address => uint256[] memory) private _userPairs;

    address public quantumOracleAddress;
    mapping(address => bool) public allowedCollapsers;

    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // Stored in Basis Points (100 = 1%)

    // Mapping to track accumulated fees per token
    mapping(address => uint256) private collectedFees;

    // --- Events ---

    event EntanglementCreated(uint256 indexed pairId, address indexed initiator, Asset assetA, Asset targetAssetB, address counterparty, uint48 expirationBlock);
    event EntanglementJoined(uint256 indexed pairId, address indexed counterparty, Asset assetB);
    event EntanglementConditionsSet(uint256 indexed pairId, bytes conditions);
    event EntanglementProbabilitiesSet(uint256 indexed pairId, bytes resolutionData);
    event EntanglementCancelled(uint256 indexed pairId, address indexed initiator);
    event EntanglementDisentangled(uint256 indexed pairId, address indexed user);
    event CollapseTriggered(uint256 indexed pairId, bytes oracleData, bool success);
    event AssetClaimed(uint256 indexed pairId, address indexed user, Asset claimedAsset);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event CollapserAllowanceSet(address indexed collapser, bool allowed);
    event FeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event FeePercentageSet(uint256 oldPercentage, uint256 newPercentage);
    event FeesWithdrawn(address indexed tokenAddress, uint256 amount, address indexed recipient);
    event ContractPaused(address account);
    event ContractUnpaused(address account);


    // --- Constructor ---

    constructor(address initialOracle, address initialFeeRecipient, uint256 initialFeePercentageBP) Ownable(msg.sender) {
        if (initialOracle == address(0)) revert InvalidOracleAddress();
        quantumOracleAddress = initialOracle;
        allowedCollapsers[initialOracle] = true; // Oracle is always allowed
        emit OracleAddressSet(address(0), initialOracle);

        protocolFeeRecipient = initialFeeRecipient;
        emit FeeRecipientSet(address(0), initialFeeRecipient);

        if (initialFeePercentageBP > 10000) revert InvalidFeePercentage(initialFeePercentageBP);
        protocolFeePercentage = initialFeePercentageBP;
        emit FeePercentageSet(0, initialFeePercentageBP);

        pairCounter = 0;
    }

    // --- Core Logic Functions ---

    // 1. Create Entanglement with ERC20 assetA
    function createEntanglementERC20(
        address assetAContract,
        uint256 assetAAmount,
        Asset calldata targetAssetB,
        address counterparty, // Use 0x0 for an open entanglement anyone can join
        bytes calldata activationConditions,
        ResolutionMethod resolutionMethod,
        bytes calldata resolutionData,
        uint48 expirationBlock
    ) external payable whenNotPaused returns (uint256 pairId) {
        // Basic validation
        if (assetAContract == address(0) || assetAAmount == 0) revert InvalidAssetParameters();
        if (targetAssetB.contractAddress == address(0) || targetAssetB.amountOrId == 0) revert InvalidAssetParameters();
        if (assetAContract == targetAssetB.contractAddress && assetAAmount == targetAssetB.amountOrId && assetAContract != address(0)) revert CannotEntangleSameAssetType(); // Prevent A=B swaps with same values
        if (expirationBlock <= block.number) revert InvalidExpiration();

        // Ensure only one type is set for B
        if (targetAssetB.isERC721 && targetAssetB.amountOrId == 0) revert InvalidAssetParameters(); // Must provide ID for ERC721
        if (!targetAssetB.isERC721 && targetAssetB.amountOrId == 0) revert InvalidAssetParameters(); // Must provide amount for ERC20

        pairId = pairCounter++;

        // Transfer asset A into the contract
        _receiveAsset(msg.sender, assetAContract, assetAAmount, false); // Assuming ERC20 is not ERC721

        EntanglementPair storage newPair = entanglementPairs[pairId];
        newPair.id = pairId;
        newPair.initiator = msg.sender;
        newPair.counterparty = counterparty; // 0x0 for open
        newPair.assetA = Asset(assetAContract, assetAAmount, false); // ERC20
        newPair.targetAssetB = targetAssetB;
        newPair.activationConditions = activationConditions;
        newPair.resolutionMethod = resolutionMethod;
        newPair.resolutionData = resolutionData;
        newPair.expirationBlock = expirationBlock;
        newPair.state = counterparty == address(0) ? EntanglementState.Pending : EntanglementState.Active; // Starts Active if counterparty specified

        // Initial holders are unknown until collapse, or same as depositor if cancelled/disentangled
        newPair.currentHolderA = address(0);
        newPair.currentHolderB = address(0);
        newPair.collapsed = false;
        newPair.initiatorClaimed = false;
        newPair.counterpartyClaimed = false;

        _addPairToUserList(msg.sender, pairId);
        if (counterparty != address(0)) {
             _addPairToUserList(counterparty, pairId);
        }

        emit EntanglementCreated(pairId, msg.sender, newPair.assetA, newPair.targetAssetB, counterparty, expirationBlock);
    }

    // 2. Create Entanglement with ERC721 assetA
    function createEntanglementERC721(
        address assetAContract,
        uint256 assetAId,
        Asset calldata targetAssetB,
        address counterparty, // Use 0x0 for an open entanglement anyone can join
        bytes calldata activationConditions,
        ResolutionMethod resolutionMethod,
        bytes calldata resolutionData,
        uint48 expirationBlock
    ) external payable whenNotPaused returns (uint256 pairId) {
        // Basic validation
        if (assetAContract == address(0) || assetAId == 0) revert InvalidAssetParameters();
        if (targetAssetB.contractAddress == address(0) || targetAssetB.amountOrId == 0) revert InvalidAssetParameters();
         if (assetAContract == targetAssetB.contractAddress && assetAId == targetAssetB.amountOrId && assetAContract != address(0)) revert CannotEntangleSameAssetType();
        if (expirationBlock <= block.number) revert InvalidExpiration();

        // Ensure only one type is set for B
        if (targetAssetB.isERC721 && targetAssetB.amountOrId == 0) revert InvalidAssetParameters(); // Must provide ID for ERC721
        if (!targetAssetB.isERC721 && targetAssetB.amountOrId == 0) revert InvalidAssetParameters(); // Must provide amount for ERC20


        pairId = pairCounter++;

        // Transfer asset A (ERC721) into the contract
        _receiveAsset(msg.sender, assetAContract, assetAId, true); // Assuming ERC721

        EntanglementPair storage newPair = entanglementPairs[pairId];
        newPair.id = pairId;
        newPair.initiator = msg.sender;
        newPair.counterparty = counterparty; // 0x0 for open
        newPair.assetA = Asset(assetAContract, assetAId, true); // ERC721
        newPair.targetAssetB = targetAssetB;
        newPair.activationConditions = activationConditions;
        newPair.resolutionMethod = resolutionMethod;
        newPair.resolutionData = resolutionData;
        newPair.expirationBlock = expirationBlock;
        newPair.state = counterparty == address(0) ? EntanglementState.Pending : EntanglementState.Active; // Starts Active if counterparty specified

         // Initial holders are unknown until collapse, or same as depositor if cancelled/disentangled
        newPair.currentHolderA = address(0);
        newPair.currentHolderB = address(0);
        newPair.collapsed = false;
        newPair.initiatorClaimed = false;
        newPair.counterpartyClaimed = false;

        _addPairToUserList(msg.sender, pairId);
         if (counterparty != address(0)) {
             _addPairToUserList(counterparty, pairId);
        }

        emit EntanglementCreated(pairId, msg.sender, newPair.assetA, newPair.targetAssetB, counterparty, expirationBlock);
    }

    // 3. Join an existing open entanglement
    function joinEntanglement(uint256 pairId, Asset calldata assetB) external payable whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId); // Check if pair exists (assuming pair 0 is unused)
        if (pair.state != EntanglementState.Pending) revert PairNotInState(pairId, EntanglementState.Pending); // Must be Pending (open)
        if (pair.counterparty != address(0)) revert PairNotOpen(pairId); // Must be an open pair

        // Validate asset B matches the target
        if (pair.targetAssetB.contractAddress != assetB.contractAddress ||
            pair.targetAssetB.amountOrId != assetB.amountOrId ||
            pair.targetAssetB.isERC721 != assetB.isERC721) {
            revert AssetBMismatch(pairId);
        }
         if (pair.assetA.contractAddress == assetB.contractAddress && pair.assetA.amountOrId == assetB.amountOrId && assetB.contractAddress != address(0)) revert CannotEntangleSameAssetType();


        pair.counterparty = msg.sender;

        // Transfer asset B into the contract
        _receiveAsset(msg.sender, assetB.contractAddress, assetB.amountOrId, assetB.isERC721);

        pair.state = EntanglementState.Active; // Now both assets are deposited
        _addPairToUserList(msg.sender, pairId);

        emit EntanglementJoined(pairId, msg.sender, assetB);
    }

     // 4. Set Activation Conditions (callable before Active state, or specific conditions)
    function setEntanglementConditions(uint256 pairId, bytes calldata newConditions) external whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.state != EntanglementState.Pending && pair.state != EntanglementState.Active) revert PairNotInState(pairId, pair.state); // Can set conditions if Pending or Active
        if (msg.sender != pair.initiator && msg.sender != pair.counterparty) revert InvalidCounterparty(pairId, msg.sender); // Only involved parties

        pair.activationConditions = newConditions;

        emit EntanglementConditionsSet(pairId, newConditions);
    }

    // 5. Set Resolution Probabilities (callable before Collapse, if method is WeightedRandom)
    function setEntanglementProbabilities(uint256 pairId, bytes calldata newResolutionData) external whenNotPaused {
         EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.state != EntanglementState.Pending && pair.state != EntanglementState.Active) revert PairNotInState(pairId, pair.state); // Can set data if Pending or Active
        if (pair.resolutionMethod != ResolutionMethod.OracleWeightedRandom) revert PairNotInState(pairId, pair.state); // Only applicable for weighted random
        if (msg.sender != pair.initiator && msg.sender != pair.counterparty) revert InvalidCounterparty(pairId, msg.sender); // Only involved parties

        pair.resolutionData = newResolutionData;

        emit EntanglementProbabilitiesSet(pairId, newResolutionData);
    }


    // 6. Cancel Entanglement (Initiator only, must be Pending)
    function cancelEntanglementByInitiator(uint256 pairId) external whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.initiator != msg.sender) revert InvalidCounterparty(pairId, msg.sender); // Only initiator can cancel
        if (pair.state != EntanglementState.Pending) revert PairNotInState(pairId, EntanglementState.Pending); // Must be in Pending state

        // Return Asset A to initiator
        _transferAsset(pair.initiator, pair.assetA.contractAddress, pair.assetA.amountOrId, pair.assetA.isERC721);

        pair.state = EntanglementState.Cancelled;
        // Note: We don't explicitly remove from _userPairs for gas efficiency

        emit EntanglementCancelled(pairId, msg.sender);
    }

    // 7. Disentangle (Initiator or Counterparty, must be Active, before Collapse/Expiration)
    // Could add penalty logic here if desired
    function disentangle(uint256 pairId) external payable whenNotPaused {
         EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.state != EntanglementState.Active) revert PairNotInState(pairId, EntanglementState.Active); // Must be Active
        if (msg.sender != pair.initiator && msg.sender != pair.counterparty) revert InvalidCounterparty(pairId, msg.sender); // Only involved parties
        if (block.number > pair.expirationBlock) revert PairNotInState(pairId, pair.state); // Cannot disentangle after expiration

        // Return assets to respective depositors
        _transferAsset(pair.initiator, pair.assetA.contractAddress, pair.assetA.amountOrId, pair.assetA.isERC721);
        if (pair.counterparty != address(0)) { // Should be true if state is Active
             // Counterparty asset is pair.targetAssetB, as deposited
            _transferAsset(pair.counterparty, pair.targetAssetB.contractAddress, pair.targetAssetB.amountOrId, pair.targetAssetB.isERC721);
        }

        pair.state = EntanglementState.Disentangled;
        // Note: We don't explicitly remove from _userPairs for gas efficiency

        emit EntanglementDisentangled(pairId, msg.sender);
    }

    // 8. Trigger Collapse (Called by Oracle or Allowed Collapser)
    // This is the core "quantum" event.
    // In a real system, oracleData would come from a trusted source after validation.
    function triggerCollapse(uint256 pairId, bytes calldata oracleData) external whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.state != EntanglementState.Active) revert PairNotInState(pairId, EntanglementState.Active); // Must be Active
        if (!_isAllowedCollapser(msg.sender)) revert NotAllowedCollapser(msg.sender); // Must be oracle or allowed collapser
        if (block.number > pair.expirationBlock) revert PairNotInState(pairId, pair.state); // Cannot collapse after expiration

        // --- Simulate Oracle Condition Check & Resolution ---
        // In a real system, this would interact with the oracle contract or verify a proof.
        // For this example, we use the oracleData bytes.
        // Let's assume activationConditions and oracleData are simple flags or values.

        bool conditionsMet = true; // Assume conditions are met if activationConditions is empty, otherwise requires oracle validation
        if (pair.activationConditions.length > 0) {
            // *** Dummy Condition Check Logic ***
            // A real implementation would parse pair.activationConditions and oracleData
            // and determine if the condition is met (e.g., price > X, blockhash matches pattern, etc.)
            // For demo: assume condition is met if oracleData starts with 0x01
            if (oracleData.length == 0 || oracleData[0] != 0x01) {
                 conditionsMet = false;
            }
            // *** End Dummy Logic ***
        }

        if (!conditionsMet) {
            // Conditions not met, the pair remains Active or could potentially expire later
            // We won't transition state yet, as conditions might be met by a future oracle call.
            emit CollapseTriggered(pairId, oracleData, false);
            revert ActivationConditionsNotMet(pairId);
        }

        // Conditions are met! Now determine the outcome based on resolutionMethod and oracleData.
        // *** Dummy Resolution Logic ***
        // Example: OracleDirect - if oracleData is 0x01, Initiator gets B, Counterparty gets A.
        // If oracleData is 0x00, Initiator gets A (back), Counterparty gets B (back).
        // Example: OracleWeightedRandom - Parse resolutionData for weights, use oracleData (e.g., a random number)
        // to select outcome based on weights.
        // For simplicity here: assume OracleDirect, 0x01 means swap, anything else means no swap.

        bool swapHappened = false; // Did Asset A go to counterparty and Asset B to initiator?
        if (pair.resolutionMethod == ResolutionMethod.OracleDirect) {
             if (oracleData.length > 0 && oracleData[0] == 0x01) {
                 swapHappened = true;
             }
        } else if (pair.resolutionMethod == ResolutionMethod.OracleWeightedRandom) {
             // This would require parsing pair.resolutionData (weights) and oracleData (randomness)
             // to probabilistically determine if swapHappened or maybe other outcomes.
             // *** Simplification for demo: Assume if using weighted random, any non-empty oracleData triggers a swap for demo ***
             if (oracleData.length > 0) {
                 swapHappened = true; // Simplistic: Any oracle data means swap for weighted random demo
             }
             // A real WeightedRandom would use VRF or similar to select an outcome index based on weights in resolutionData
        }
        // --- End Dummy Logic ---


        if (swapHappened) {
            pair.receivedAssetA = pair.targetAssetB; // Initiator gets Asset B
            pair.receivedAssetB = pair.assetA;      // Counterparty gets Asset A
            pair.currentHolderA = pair.counterparty; // Counterparty now owns the original Asset A
            pair.currentHolderB = pair.initiator;    // Initiator now owns the original Asset B
        } else {
            // No swap (or different outcome based on method) - assets returned to original depositors
            pair.receivedAssetA = pair.assetA;      // Initiator gets Asset A back
            pair.receivedAssetB = pair.targetAssetB; // Counterparty gets Asset B back
            pair.currentHolderA = pair.initiator;    // Initiator keeps Asset A
            pair.currentHolderB = pair.counterparty; // Counterparty keeps Asset B
        }

        pair.state = EntanglementState.Collapsed;
        pair.collapsed = true; // Ensure it can only be collapsed once

        emit CollapseTriggered(pairId, oracleData, true);
    }

    // 9. Claim Asset after Collapse
    function claimAsset(uint256 pairId) external whenNotPaused {
         EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.id == 0 && pairId != 0) revert PairDoesNotExist(pairId);
        if (pair.state != EntanglementState.Collapsed) revert PairNotInState(pairId, EntanglementState.Collapsed); // Must be Collapsed

        bool claimed = false;

        // Check if caller is initiator and hasn't claimed
        if (msg.sender == pair.initiator && !pair.initiatorClaimed) {
            if (pair.currentHolderB == msg.sender) { // Initiator is entitled to Asset B's outcome
                // Apply protocol fee to Asset B if it's ERC20
                if (!pair.receivedAssetB.isERC721 && pair.receivedAssetB.contractAddress != address(0) && pair.receivedAssetB.amountOrId > 0 && protocolFeePercentage > 0) {
                    uint256 feeAmount = (pair.receivedAssetB.amountOrId * protocolFeePercentage) / 10000;
                    uint256 transferAmount = pair.receivedAssetB.amountOrId - feeAmount;
                    if (transferAmount > 0) {
                         _transferAsset(msg.sender, pair.receivedAssetB.contractAddress, transferAmount, false);
                    }
                    if (feeAmount > 0) {
                         collectedFees[pair.receivedAssetB.contractAddress] += feeAmount;
                    }
                } else {
                   _transferAsset(msg.sender, pair.receivedAssetB.contractAddress, pair.receivedAssetB.amountOrId, pair.receivedAssetB.isERC721);
                }
                pair.initiatorClaimed = true;
                claimed = true;
                emit AssetClaimed(pairId, msg.sender, pair.receivedAssetB);
            }
        }

        // Check if caller is counterparty and hasn't claimed
        if (msg.sender == pair.counterparty && !pair.counterpartyClaimed) {
            if (pair.currentHolderA == msg.sender) { // Counterparty is entitled to Asset A's outcome
                // Apply protocol fee to Asset A if it's ERC20
                 if (!pair.receivedAssetA.isERC721 && pair.receivedAssetA.contractAddress != address(0) && pair.receivedAssetA.amountOrId > 0 && protocolFeePercentage > 0) {
                    uint256 feeAmount = (pair.receivedAssetA.amountOrId * protocolFeePercentage) / 10000;
                    uint256 transferAmount = pair.receivedAssetA.amountOrId - feeAmount;
                     if (transferAmount > 0) {
                       _transferAsset(msg.sender, pair.receivedAssetA.contractAddress, transferAmount, false);
                    }
                     if (feeAmount > 0) {
                       collectedFees[pair.receivedAssetA.contractAddress] += feeAmount;
                    }
                } else {
                   _transferAsset(msg.sender, pair.receivedAssetA.contractAddress, pair.receivedAssetA.amountOrId, pair.receivedAssetA.isERC721);
                }
                pair.counterpartyClaimed = true;
                claimed = true;
                 emit AssetClaimed(pairId, msg.sender, pair.receivedAssetA);
            }
        }

        if (!claimed) {
            revert NothingToClaim(pairId, msg.sender);
        }
    }

    // --- Utility/Helper Functions (Internal) ---

    // Handles receiving ERC20 or ERC721 from user
    function _receiveAsset(address from, address tokenAddress, uint256 amountOrId, bool isERC721) internal {
        if (tokenAddress == address(0)) {
            // Handling native token (ETH) if contract accepted payable.
            // Current functions are not payable except create, but this template allows extending.
            // If ETH was intended, need to modify create/join to be payable and check msg.value.
            // This example focuses on ERC20/ERC721.
            revert TransferFailed(address(0), from, address(this), amountOrId);
        }

        if (isERC721) {
            try IERC721(tokenAddress).transferFrom(from, address(this), amountOrId) {
                // success
            } catch {
                revert TransferFailed(tokenAddress, from, address(this), amountOrId);
            }
        } else { // ERC20
             // Check allowance first (user must approve contract before calling)
            if (IERC20(tokenAddress).allowance(from, address(this)) < amountOrId) {
                 revert ApprovalNeeded(tokenAddress, from, address(this), amountOrId);
            }
            try IERC20(tokenAddress).transferFrom(from, address(this), amountOrId) {
                // success
            } catch {
                 revert TransferFailed(tokenAddress, from, address(this), amountOrId);
            }
        }
    }

    // Handles sending ERC20 or ERC721 from contract to user
    function _transferAsset(address to, address tokenAddress, uint256 amountOrId, bool isERC721) internal {
         if (tokenAddress == address(0)) {
             // Handle Ether transfer if needed - currently not part of claim logic
             revert TransferFailed(address(0), address(this), to, amountOrId);
         }

        if (isERC721) {
             try IERC721(tokenAddress).safeTransferFrom(address(this), to, amountOrId) {
                 // success
             } catch {
                 revert TransferFailed(tokenAddress, address(this), to, amountOrId);
             }
        } else { // ERC20
             try IERC20(tokenAddress).transfer(to, amountOrId) {
                 // success
             } catch {
                 revert TransferFailed(tokenAddress, address(this), to, amountOrId);
             }
        }
    }

    // Checks if an address is allowed to call triggerCollapse
    function _isAllowedCollapser(address caller) internal view returns (bool) {
        return caller == quantumOracleAddress || allowedCollapsers[caller];
    }

     // Simple helper to add pair ID to user list (might grow large, consider alternatives for production)
    function _addPairToUserList(address user, uint256 pairId) internal {
        // In a real contract, managing dynamic arrays like this can be gas-intensive.
        // For simplicity here, we just push. A better approach might be a mapping
        // (address => mapping(uint256 => bool)) or external indexing services.
        // This implementation is functional but not gas-optimized for large user pair counts.
         uint256[] storage pairs = _userPairs[user];
         bool found = false;
         for(uint i = 0; i < pairs.length; i++) {
             if (pairs[i] == pairId) {
                 found = true;
                 break;
             }
         }
         if (!found) {
             pairs.push(pairId);
         }
    }

    // ERC721Holder receive function
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Optional: Add checks here if needed to ensure only expected transfers are accepted.
        // For this contract, we assume transfers are initiated by _receiveAsset.
        return this.onERC721Received.selector;
    }


    // --- View Functions ---

    // 10. Get Entanglement State
    function getEntanglementState(uint256 pairId) external view returns (EntanglementState) {
        if (pairId == 0 || pairId >= pairCounter) revert PairDoesNotExist(pairId);
        return entanglementPairs[pairId].state;
    }

    // 11. Get Entanglement Pair Details
    function getEntanglementPair(uint256 pairId) external view returns (EntanglementPair memory) {
        if (pairId == 0 || pairId >= pairCounter) revert PairDoesNotExist(pairId);
        return entanglementPairs[pairId];
    }

    // 12. Get User Entanglement Pairs (basic list)
    function getUserEntanglementPairs(address user) external view returns (uint256[] memory) {
        return _userPairs[user];
    }

    // 13. Get Quantum Oracle Address
    function getQuantumOracleAddress() external view returns (address) {
        return quantumOracleAddress;
    }

    // 14. Check if Address is Allowed Collapser
    function isAllowedCollapser(address collapser) external view returns (bool) {
        return _isAllowedCollapser(collapser);
    }

    // 15. Get Protocol Fee Recipient
    function getProtocolFeeRecipient() external view returns (address) {
        return protocolFeeRecipient;
    }

    // 16. Get Protocol Fee Percentage
    function getProtocolFeePercentage() external view returns (uint256) {
        return protocolFeePercentage;
    }

     // Get collected fees for a specific token
    function getCollectedFees(address tokenAddress) external view returns (uint256) {
        return collectedFees[tokenAddress];
    }


    // --- Administrative Functions (Owner-Only) ---

    // 17. Set Quantum Oracle Address
    function setQuantumOracleAddress(address _quantumOracleAddress) external onlyOwner {
        if (_quantumOracleAddress == address(0)) revert InvalidOracleAddress();
        address oldOracle = quantumOracleAddress;
        // Optionally remove old oracle from allowedCollapsers if it wasn't explicitly added
        // if(allowedCollapsers[oldOracle] && oldOracle != owner()) allowedCollapsers[oldOracle] = false;
        quantumOracleAddress = _quantumOracleAddress;
        allowedCollapsers[_quantumOracleAddress] = true; // New oracle is always allowed
        emit OracleAddressSet(oldOracle, _quantumOracleAddress);
    }

    // 18. Add Allowed Collapser
    function addAllowedCollapser(address collapser) external onlyOwner {
        if (collapser == address(0)) revert InvalidOracleAddress(); // Or specific error
        allowedCollapsers[collapser] = true;
        emit CollapserAllowanceSet(collapser, true);
    }

    // 19. Remove Allowed Collapser
    function removeAllowedCollapser(address collapser) external onlyOwner {
        if (collapser == quantumOracleAddress) revert InvalidOracleAddress(); // Cannot remove the main oracle
        allowedCollapsers[collapser] = false;
        emit CollapserAllowanceSet(collapser, false);
    }

    // 20. Set Protocol Fee Recipient
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
         emit FeeRecipientSet(protocolFeeRecipient, _protocolFeeRecipient); // Use current value for old
    }

    // 21. Set Protocol Fee Percentage
    function setProtocolFeePercentage(uint256 _protocolFeePercentage) external onlyOwner {
         if (_protocolFeePercentage > 10000) revert InvalidFeePercentage(_protocolFeePercentage); // Max 100%
        uint256 oldPercentage = protocolFeePercentage;
        protocolFeePercentage = _protocolFeePercentage;
         emit FeePercentageSet(oldPercentage, _protocolFeePercentage);
    }

    // 22. Withdraw Collected Fees
    function withdrawProtocolFees(address tokenAddress) external onlyOwner {
        uint256 amount = collectedFees[tokenAddress];
        if (amount == 0) revert NoFeesCollected(tokenAddress);

        collectedFees[tokenAddress] = 0;

        // Transfer fees
        if (tokenAddress == address(0)) {
             // Handle native token withdrawal if collected - not currently implemented in fees
             // selfdestruct(payable(protocolFeeRecipient)); // Example, but selfdestruct is risky
             // Alternative: Use withdrawal pattern for ETH
             revert TransferFailed(address(0), address(this), protocolFeeRecipient, amount); // Indicate ETH not supported for fees currently
        } else {
             try IERC20(tokenAddress).transfer(protocolFeeRecipient, amount) {
                 // success
             } catch {
                 // Revert on failure or implement rescue mechanism
                 revert TransferFailed(tokenAddress, address(this), protocolFeeRecipient, amount);
             }
        }
        emit FeesWithdrawn(tokenAddress, amount, protocolFeeRecipient);
    }

     // 23. Pause Contract
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

     // 24. Unpause Contract
    function unpauseContract() external onlyOwner {
        _unpause();
         emit ContractUnpaused(msg.sender);
    }
}
```

**Explanation of Concepts and Features:**

1.  **Quantum Entanglement Metaphor:** Assets are locked in a state where their final destination is uncertain (`Pending` or `Active` state), resolved by an external event ("collapse").
2.  **Oracle Dependency (`IQuantumCollapseOracle`, `triggerCollapse`):** The core resolution mechanism relies on an external oracle providing data. This data is used both to check activation conditions and determine the outcome. This introduces a necessary trust assumption in the oracle. The `oracleData` bytes are flexible and can encode various inputs (randomness, price, event data, etc.).
3.  **Conditional Activation (`activationConditions`, `triggerCollapse`):** Pairs can be set up to only become eligible for collapse if specific external conditions are met, making the trades contingent on real-world or complex on-chain events (e.g., "only if ETH price is above $X", "only after a certain game event"). The interpretation of `activationConditions` and `oracleData` happens within `triggerCollapse` (simplified in this example but can be complex).
4.  **Probabilistic Outcomes (`ResolutionMethod`, `resolutionData`, `triggerCollapse`):** The outcome of the "collapse" isn't necessarily a simple swap. Using `OracleWeightedRandom`, the `oracleData` (e.g., a random number from a VRF) can be used to select from multiple potential outcomes with defined probabilities encoded in `resolutionData`. This adds a speculative, almost gambling-like element.
5.  **State Machine (`EntanglementState`):** The contract carefully manages the lifecycle of each entanglement pair (Pending -> Active -> Collapsed/Cancelled/Disentangled) using an enum, ensuring functions are called in the correct sequence.
6.  **Handling ERC20 and ERC721:** The `Asset` struct and helper functions (`_receiveAsset`, `_transferAsset`) are designed to handle both token standards seamlessly within the same pair structure. ERC721Holder is used to properly receive NFTs.
7.  **Open vs. Specific Counterparties:** Users can create entanglements targeting a specific address or leave them open for anyone to join.
8.  **Disentanglement (`disentangle`):** Allows parties to gracefully exit an active entanglement *before* collapse, returning assets (potentially with defined penalties, though not explicitly coded in this version).
9.  **Claim Pattern:** After collapse, users must explicitly call `claimAsset` to withdraw their allocated assets. This is a standard pattern to manage gas costs and avoid pushing assets automatically.
10. **Role-Based Collapse Triggering:** Only the designated `quantumOracleAddress` or explicitly `allowedCollapsers` can initiate the `triggerCollapse` function, preventing arbitrary users from resolving pairs.
11. **Protocol Fees:** Includes a standard mechanism for collecting a percentage fee on successful claims (only for ERC20 in this basic implementation).
12. **Pausability:** Standard security feature allowing the owner to pause critical functions in emergencies.
13. **Extensibility:** The use of `bytes` for `activationConditions` and `resolutionData` allows for diverse and complex logic to be implemented in conjunction with the oracle or within future versions, without changing the core contract structure.
14. **Event Fullness:** Comprehensive events are emitted for state changes, crucial for off-chain monitoring and indexing.
15. **Detailed Error Handling:** Uses custom errors (Solidity 0.8+) for clearer debugging.
16. **Owner Functions:** Standard onlyOwner pattern for administrative tasks like setting oracle, fees, and pausing.
17. **Asset Struct:** A clear way to represent either an ERC20 or ERC721 within a single data type.
18. **Expiration:** Pairs have an `expirationBlock`, after which they cannot be collapsed (but can still be disentangled or cancelled if applicable).
19. **User Pair Tracking (Basic):** `_userPairs` provides a simple way to list pairs a user is involved in, though this approach has gas considerations for large numbers of pairs.

This contract pushes beyond basic swaps by introducing conditionality, uncertainty, and external data reliance as core features, governed by a state machine and a conceptual "quantum collapse" mechanism. The "non-duplication" aspect is addressed by combining these elements into a unique trading paradigm centered around probabilistic, conditional resolution via an oracle.