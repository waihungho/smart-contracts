Okay, let's create a smart contract that incorporates several advanced concepts, focusing on managing assets within dynamic "Quantum States" that collapse based on defined conditions. It's a metaphorical use of "quantum" concepts like superposition (multiple potential owners) and collapse.

This contract is complex and gas-intensive due to managing multiple states, token types, shares, and complex collapse conditions. It serves as an exploration of advanced Solidity patterns rather than a production-ready template without extensive audits and optimization.

**Concept:** **Quantum Vault**

Assets (ERC20 and ERC721 tokens) are deposited into "Quantum States". Each state can have multiple "Potential Owners" assigned shares. A state remains in a 'superposition' until a specific 'Collapse Condition' is met (like a timestamp, an oracle value, or the collapse of another entangled state). Once collapsed, the potential owners can claim their proportional share of the assets based on their assigned shares. States can also be 'entangled', meaning the collapse of one state can trigger a collapse check on another.

**Outline & Function Summary**

*   **Contract:** `QuantumVault`
*   **Purpose:** Manages deposits of ERC20 and ERC721 tokens within dynamic "Quantum States" that collapse based on configurable conditions, allowing potential owners to claim proportional shares post-collapse.
*   **Key Concepts:** Quantum States, Potential Owners, Shares, Collapse Conditions (Timestamp, Oracle, Entanglement, Manual), State Entanglement, Proportional Claiming.
*   **Dependencies:** ERC20/ERC721 interfaces, SafeERC20/Address libraries, Mock Oracle interface.

**Function Summary:**

1.  **`constructor()`**: Initializes the contract owner.
2.  **`transferOwnership(address newOwner)`**: Transfers contract ownership (Admin).
3.  **`rescueTokens(address tokenAddress, uint256 amount)`**: Allows owner to rescue supported ERC20 tokens trapped in the contract (Admin).
4.  **`rescueERC721(address tokenAddress, uint256 tokenId)`**: Allows owner to rescue supported ERC721 tokens trapped in the contract (Admin).
5.  **`createQuantumState()`**: Creates a new, empty Quantum State and returns its unique ID.
6.  **`setPotentialOwnerShares(uint256 stateId, address[] potentialOwners, uint256[] sharesBasisPoints)`**: Sets or updates the proportional shares (in basis points, 0-10000) for multiple potential owners in a non-collapsed state.
7.  **`setCollapseCondition(uint256 stateId, CollapseCondition calldata condition)`**: Defines or updates the condition that will cause a non-collapsed state to collapse.
8.  **`depositERC20IntoState(uint256 stateId, address tokenAddress, uint256 amount)`**: Deposits a specified amount of an ERC20 token into a non-collapsed state. Requires prior approval.
9.  **`depositERC721IntoState(uint256 stateId, address tokenAddress, uint256 tokenId)`**: Deposits a specific ERC721 token into a non-collapsed state. Requires prior approval (approve token to this contract).
10. **`depositMultipleERC20IntoState(uint256 stateId, address[] tokenAddresses, uint256[] amounts)`**: Deposits multiple ERC20 tokens/amounts into a state.
11. **`depositMultipleERC721IntoState(uint256 stateId, address tokenAddress, uint256[] tokenIds)`**: Deposits multiple ERC721 tokens of the same type into a state.
12. **`entangleStates(uint256 stateId1, uint256 stateId2)`**: Creates a reciprocal entanglement link between two non-collapsed states.
13. **`disentangleStates(uint256 stateId1, uint256 stateId2)`**: Removes the entanglement link between two states (Owner only).
14. **`checkAndCollapseState(uint256 stateId)`**: Triggers a check to see if the collapse condition for a specific state is met. If so, collapses the state.
15. **`checkAndCollapseEntangledStates(uint256 stateId)`**: Triggers a collapse check for a state and recursively checks its entangled states (careful of gas limits and cycles in real-world).
16. **`triggerManualCollapse(uint256 stateId)`**: Allows the state creator or a designated address to trigger collapse if the condition type is manual.
17. **`claimProportionalERC20(uint256 stateId, address tokenAddress)`**: Allows a potential owner of a collapsed state to claim their eligible proportional share of a specific ERC20 token.
18. **`claimProportionalERC721(uint256 stateId, address tokenAddress, uint256[] calldata tokenIdsToClaim)`**: Allows a potential owner of a collapsed state to claim specific ERC721 token IDs they are eligible for.
19. **`getQuantumStateInfo(uint256 stateId)`**: Retrieves basic information about a state (creator, collapsed status, total shares).
20. **`getStateERC20Balance(uint256 stateId, address tokenAddress)`**: Gets the balance of a specific ERC20 token held in a state.
21. **`getStateERC721Status(uint256 stateId, address tokenAddress, uint256 tokenId)`**: Checks if a specific ERC721 token is held within a state.
22. **`getPotentialOwnerShare(uint256 stateId, address potentialOwner)`**: Gets the share percentage (basis points) for a specific potential owner in a state.
23. **`getTotalPotentialShares(uint256 stateId)`**: Gets the total sum of all potential owner shares for a state.
24. **`getClaimedAmountERC20(uint256 stateId, address claimant, address tokenAddress)`**: Gets the total amount of a specific ERC20 token claimed by an address from a state.
25. **`getClaimedCountERC721(uint256 stateId, address claimant, address tokenAddress)`**: Gets the total count of a specific ERC721 token type claimed by an address from a state.
26. **`isERC721TokenClaimed(uint256 stateId, address tokenAddress, uint256 tokenId)`**: Checks if a specific ERC721 token ID has been claimed by *any* potential owner from a state.
27. **`getEntangledStatesDirect(uint256 stateId)`**: Gets the list of states directly entangled with a given state.
28. **`getCollapseConditionDetails(uint256 stateId)`**: Retrieves the full details of a state's collapse condition.
29. **`isStateCollapsed(uint256 stateId)`**: Checks if a state has collapsed.
30. **`getNextStateId()`**: Returns the ID that will be assigned to the next created state.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Outline & Function Summary ---
// Contract: QuantumVault
// Purpose: Manages deposits of ERC20 and ERC721 tokens within dynamic "Quantum States" that collapse based on configurable conditions, allowing potential owners to claim proportional shares post-collapse.
// Key Concepts: Quantum States, Potential Owners, Shares, Collapse Conditions (Timestamp, Oracle, Entanglement, Manual), State Entanglement, Proportional Claiming.
// Dependencies: ERC20/ERC721 interfaces, SafeERC20/Address libraries, Mock Oracle interface.

// Function Summary:
// 1. constructor(): Initializes the contract owner.
// 2. transferOwnership(address newOwner): Transfers contract ownership (Admin).
// 3. rescueTokens(address tokenAddress, uint256 amount): Allows owner to rescue supported ERC20 tokens trapped in the contract (Admin).
// 4. rescueERC721(address tokenAddress, uint256 tokenId): Allows owner to rescue supported ERC721 tokens trapped in the contract (Admin).
// 5. createQuantumState(): Creates a new, empty Quantum State and returns its unique ID.
// 6. setPotentialOwnerShares(uint256 stateId, address[] potentialOwners, uint256[] sharesBasisPoints): Sets or updates the proportional shares (in basis points, 0-10000) for multiple potential owners in a non-collapsed state.
// 7. setCollapseCondition(uint256 stateId, CollapseCondition calldata condition): Defines or updates the condition that will cause a non-collapsed state to collapse.
// 8. depositERC20IntoState(uint256 stateId, address tokenAddress, uint256 amount): Deposits a specified amount of an ERC20 token into a non-collapsed state. Requires prior approval.
// 9. depositERC721IntoState(uint256 stateId, address tokenAddress, uint256 tokenId): Deposits a specific ERC721 token into a non-collapsed state. Requires prior approval (approve token to this contract).
// 10. depositMultipleERC20IntoState(uint256 stateId, address[] tokenAddresses, uint256[] amounts): Deposits multiple ERC20 tokens/amounts into a state.
// 11. depositMultipleERC721IntoState(uint256 stateId, address tokenAddress, uint256[] tokenIds): Deposits multiple ERC721 tokens of the same type into a state.
// 12. entangleStates(uint256 stateId1, uint256 stateId2): Creates a reciprocal entanglement link between two non-collapsed states.
// 13. disentangleStates(uint256 stateId1, uint256 stateId2): Removes the entanglement link between two states (Owner only).
// 14. checkAndCollapseState(uint256 stateId): Triggers a check to see if the collapse condition for a specific state is met. If so, collapses the state.
// 15. checkAndCollapseEntangledStates(uint256 stateId): Triggers a collapse check for a state and recursively checks its entangled states (careful of gas limits and cycles in real-world).
// 16. triggerManualCollapse(uint256 stateId): Allows the state creator or a designated address to trigger collapse if the condition type is manual.
// 17. claimProportionalERC20(uint256 stateId, address tokenAddress): Allows a potential owner of a collapsed state to claim their eligible proportional share of a specific ERC20 token.
// 18. claimProportionalERC721(uint256 stateId, address tokenAddress, uint256[] calldata tokenIdsToClaim): Allows a potential owner of a collapsed state to claim specific ERC721 token IDs they are eligible for.
// 19. getQuantumStateInfo(uint256 stateId): Retrieves basic information about a state (creator, collapsed status, total shares).
// 20. getStateERC20Balance(uint256 stateId, address tokenAddress): Gets the balance of a specific ERC20 token held in a state.
// 21. getStateERC721Status(uint256 stateId, address tokenAddress, uint256 tokenId): Checks if a specific ERC721 token is held within a state.
// 22. getPotentialOwnerShare(uint256 stateId, address potentialOwner): Gets the share percentage (basis points) for a specific potential owner in a state.
// 23. getTotalPotentialShares(uint256 stateId): Gets the total sum of all potential owner shares for a state.
// 24. getClaimedAmountERC20(uint256 stateId, address claimant, address tokenAddress): Gets the total amount of a specific ERC20 token claimed by an address from a state.
// 25. getClaimedCountERC721(uint256 stateId, address claimant, address tokenAddress): Gets the total count of a specific ERC721 token type claimed by an address from a state.
// 26. isERC721TokenClaimed(uint256 stateId, address tokenAddress, uint256 tokenId): Checks if a specific ERC721 token ID has been claimed by *any* potential owner from a state.
// 27. getEntangledStatesDirect(uint256 stateId): Gets the list of states directly entangled with a given state.
// 28. getCollapseConditionDetails(uint256 stateId): Retrieves the full details of a state's collapse condition.
// 29. isStateCollapsed(uint256 stateId): Checks if a state has collapsed.
// 30. getNextStateId(): Returns the ID that will be assigned to the next created state.


// Mock Interface for an Oracle - In a real scenario, use a robust oracle like Chainlink.
interface IMockOracle {
    function getValue(bytes calldata data) external view returns (uint256);
}

contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct CollapseCondition {
        uint8 conditionType; // 0: None, 1: Timestamp, 2: Oracle Threshold, 3: Entangled State Collapsed, 4: Manual Trigger by Creator, 5: Manual Trigger by Specific Address
        uint256 timestamp; // For type 1
        address oracleAddress; // For type 2
        bytes oracleQueryData; // For type 2
        uint256 oracleThreshold; // For type 2
        uint256 entangledStateId; // For type 3
        address triggerAddress; // For type 5
    }

    struct QuantumState {
        uint256 id;
        address creator;
        CollapseCondition condition;
        bool isCollapsed;
        bool exists; // To check if stateId is valid
    }

    mapping(uint256 => QuantumState) public quantumStates;
    uint256 private nextStateId = 1;

    // Token Holdings - Store what each state holds
    mapping(uint256 => mapping(address => uint256)) public stateERC20Balances; // stateId => tokenAddress => amount
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public stateHoldsERC721; // stateId => tokenAddress => tokenId => bool

    // Helper lists to iterate over tokens held by a state (can be gas intensive for many tokens)
    mapping(uint256 => address[]) private stateERC20TokensList; // stateId => list of ERC20 addresses
    mapping(uint256 => address[]) private stateERC721TokensList; // stateId => list of ERC721 addresses (types)

    // Potential Owners & Shares
    mapping(uint256 => mapping(address => uint256)) public statePotentialOwnerShares; // stateId => potentialOwner => shares (basis points, 0-10000)
    mapping(uint256 => uint256) public stateTotalShares; // stateId => total shares sum

    // Entanglement
    mapping(uint256 => uint256[]) public entangledStates; // stateId => list of entangled stateIds

    // Claim Tracking - Prevent double claiming
    mapping(uint256 => mapping(address => mapping(address => uint256))) public claimedAmountsERC20; // stateId => claimant => tokenAddress => amount claimed
    mapping(uint256 => mapping(address => mapping(address => uint256))) public claimedCountForTokenERC721; // stateId => claimant => tokenAddress => count claimed for this type
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public claimedERC721Tokens; // stateId => tokenAddress => tokenId => true if claimed by ANYONE

    // Recursive check tracker for collapse propagation in a single transaction
    mapping(uint256 => bool) private _checkedInTx;

    // --- Events ---
    event QuantumStateCreated(uint256 indexed stateId, address indexed creator);
    event TokensDeposited(uint256 indexed stateId, address indexed depositor, address tokenAddress, uint256 amountOrId, bool isERC721);
    event PotentialOwnerSharesSet(uint256 indexed stateId, address indexed caller, address[] potentialOwners, uint256[] shares);
    event CollapseConditionSet(uint256 indexed stateId, uint8 conditionType);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StatesDisentangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event QuantumStateCollapsed(uint256 indexed stateId, uint8 conditionMetType);
    event TokensClaimedERC20(uint256 indexed stateId, address indexed claimant, address tokenAddress, uint256 amount);
    event TokensClaimedERC721(uint256 indexed stateId, address indexed claimant, address tokenAddress, uint256[] tokenIds);

    // --- Errors ---
    error StateDoesNotExist(uint256 stateId);
    error StateAlreadyCollapsed(uint256 stateId);
    error StateNotCollapsed(uint256 stateId);
    error InvalidSharesInput();
    error TotalSharesCannotBeZero(); // For claiming calculation
    error PotentialOwnerHasNoShares(uint256 stateId, address potentialOwner);
    error OracleCallFailed(address oracleAddress);
    error EntangledStateNotCollapsed(uint256 entangledStateId);
    error ManualTriggerConditionNotMet(uint256 stateId);
    error CollapseConditionNotMet(uint256 stateId);
    error NothingToClaim(uint256 stateId, address tokenAddress, uint256 tokenId); // Use tokenId=0 for ERC20
    error InsufficientClaimableAmount(uint256 requested, uint256 available); // For ERC20
    error InsufficientClaimableCount(uint256 requested, uint256 available); // For ERC721
    error ERC721TokenNotInState(uint256 stateId, address tokenAddress, uint256 tokenId);
    error ERC721TokenAlreadyClaimed(uint256 stateId, address tokenAddress, uint256 tokenId);
    error ERC20AlreadyListed(uint256 stateId, address tokenAddress); // Helper for list management
    error ERC721AlreadyListed(uint256 stateId, address tokenAddress); // Helper for list management

    // --- Modifiers ---
    modifier stateExists(uint256 stateId) {
        if (!quantumStates[stateId].exists) revert StateDoesNotExist(stateId);
        _;
    }

    modifier stateNotCollapsed(uint256 stateId) {
        if (quantumStates[stateId].isCollapsed) revert StateAlreadyCollapsed(stateId);
        _;
    }

    modifier stateCollapsed(uint256 stateId) {
        if (!quantumStates[stateId].isCollapsed) revert StateNotCollapsed(stateId);
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Admin Functions ---

    /// @notice Allows the owner to rescue ERC20 tokens accidentally sent to the contract, not intended for a specific state.
    /// @dev Use with caution. Should not be used to drain tokens held within valid states.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to rescue.
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }

    /// @notice Allows the owner to rescue ERC721 tokens accidentally sent to the contract, not intended for a specific state.
    /// @dev Use with caution. Should not be used to drain tokens held within valid states.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the ERC721 token to rescue.
    function rescueERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).safeTransferFrom(address(this), owner(), tokenId);
    }

    // --- State Creation & Configuration ---

    /// @notice Creates a new, empty quantum state.
    /// @return stateId The ID of the newly created state.
    function createQuantumState() external returns (uint256 stateId) {
        stateId = nextStateId++;
        quantumStates[stateId] = QuantumState({
            id: stateId,
            creator: msg.sender,
            condition: CollapseCondition(0, 0, address(0), "", 0, 0, address(0)), // Default: None
            isCollapsed: false,
            exists: true
        });
        emit QuantumStateCreated(stateId, msg.sender);
    }

    /// @notice Sets or updates the proportional shares for potential owners in a state.
    /// @dev Can be called multiple times before collapse. Shares are in basis points (0-10000).
    /// @param stateId The ID of the state.
    /// @param potentialOwners The addresses of the potential owners.
    /// @param sharesBasisPoints The shares for each owner (in basis points). Must match length of potentialOwners.
    function setPotentialOwnerShares(
        uint256 stateId,
        address[] calldata potentialOwners,
        uint256[] calldata sharesBasisPoints
    ) external stateExists(stateId) stateNotCollapsed(stateId) {
        if (potentialOwners.length != sharesBasisPoints.length) revert InvalidSharesInput();

        uint256 currentTotalShares = stateTotalShares[stateId];

        for (uint i = 0; i < potentialOwners.length; i++) {
            address ownerAddr = potentialOwners[i];
            uint256 newShare = sharesBasisPoints[i];
            uint256 currentShare = statePotentialOwnerShares[stateId][ownerAddr];

            // Update share
            statePotentialOwnerShares[stateId][ownerAddr] = newShare;

            // Update total shares sum
            currentTotalShares = currentTotalShares - currentShare + newShare;
        }

        stateTotalShares[stateId] = currentTotalShares;

        emit PotentialOwnerSharesSet(stateId, msg.sender, potentialOwners, sharesBasisPoints);
    }

    /// @notice Sets or updates the collapse condition for a state.
    /// @param stateId The ID of the state.
    /// @param condition The new collapse condition.
    function setCollapseCondition(uint256 stateId, CollapseCondition calldata condition)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        // Basic validation for condition types
        if (condition.conditionType == 3 && !quantumStates[condition.entangledStateId].exists) {
             // Cannot depend on non-existent state (though state might be created later)
             // More robust check might be needed depending on desired behavior
        }
        // Could add more validation for oracle address, threshold etc.

        quantumStates[stateId].condition = condition;

        emit CollapseConditionSet(stateId, condition.conditionType);
    }

    // --- Depositing Functions ---

    /// @notice Deposits ERC20 tokens into a specific state.
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to deposit.
    function depositERC20IntoState(uint256 stateId, address tokenAddress, uint256 amount)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        if (stateERC20Balances[stateId][tokenAddress] == 0) {
            // Add token to the list for this state if it's the first deposit of this token type
            // Avoid duplicates by checking if already in the list (gas consideration)
            bool found = false;
            address[] storage tokenList = stateERC20TokensList[stateId];
            for(uint i=0; i<tokenList.length; i++){
                if(tokenList[i] == tokenAddress){
                    found = true;
                    break;
                }
            }
            if(!found) {
                 stateERC20TokensList[stateId].push(tokenAddress);
            }
        }

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        stateERC20Balances[stateId][tokenAddress] += amount;

        emit TokensDeposited(stateId, msg.sender, tokenAddress, amount, false);
    }

    /// @notice Deposits an ERC721 token into a specific state.
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the ERC721 token.
    function depositERC721IntoState(uint256 stateId, address tokenAddress, uint256 tokenId)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        // Prevent depositing the same NFT into the same state multiple times
        if (stateHoldsERC721[stateId][tokenAddress][tokenId]) {
            revert("ERC721 already in state");
        }

         if (stateERC721TokensList[stateId].length == 0 || !isERC721TokenAddressListed(stateId, tokenAddress)) {
             stateERC721TokensList[stateId].push(tokenAddress);
         }


        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        stateHoldsERC721[stateId][tokenAddress][tokenId] = true; // Mark as held by state

        emit TokensDeposited(stateId, msg.sender, tokenAddress, tokenId, true);
    }

     /// @notice Deposits multiple ERC20 tokens/amounts into a state.
     /// @param stateId The ID of the state.
     /// @param tokenAddresses The addresses of the ERC20 tokens.
     /// @param amounts The amounts to deposit for each token. Must match length of tokenAddresses.
    function depositMultipleERC20IntoState(uint256 stateId, address[] calldata tokenAddresses, uint256[] calldata amounts)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        if (tokenAddresses.length != amounts.length) revert InvalidSharesInput(); // Reusing error for length mismatch

        for(uint i = 0; i < tokenAddresses.length; i++){
            address tokenAddress = tokenAddresses[i];
            uint256 amount = amounts[i];

             if (stateERC20Balances[stateId][tokenAddress] == 0) {
                 bool found = false;
                 address[] storage tokenList = stateERC20TokensList[stateId];
                 for(uint j=0; j<tokenList.length; j++){
                     if(tokenList[j] == tokenAddress){
                         found = true;
                         break;
                     }
                 }
                 if(!found) {
                      stateERC20TokensList[stateId].push(tokenAddress);
                 }
             }

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            stateERC20Balances[stateId][tokenAddress] += amount;
             emit TokensDeposited(stateId, msg.sender, tokenAddress, amount, false);
        }
    }

     /// @notice Deposits multiple ERC721 tokens of the same type into a state.
     /// @param stateId The ID of the state.
     /// @param tokenAddress The address of the ERC721 token type.
     /// @param tokenIds The IDs of the ERC721 tokens to deposit.
    function depositMultipleERC721IntoState(uint256 stateId, address tokenAddress, uint256[] calldata tokenIds)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
         if (stateERC721TokensList[stateId].length == 0 || !isERC721TokenAddressListed(stateId, tokenAddress)) {
              stateERC721TokensList[stateId].push(tokenAddress);
         }

        for(uint i = 0; i < tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            if (stateHoldsERC721[stateId][tokenAddress][tokenId]) {
                revert("ERC721 already in state"); // Revert if any token is a duplicate
            }
            IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
            stateHoldsERC721[stateId][tokenAddress][tokenId] = true;
             emit TokensDeposited(stateId, msg.sender, tokenAddress, tokenId, true);
        }
    }


    // --- Entanglement Functions ---

    /// @notice Entangles two non-collapsed states. Creates a reciprocal link.
    /// @param stateId1 The ID of the first state.
    /// @param stateId2 The ID of the second state.
    function entangleStates(uint256 stateId1, uint256 stateId2)
        external
        stateExists(stateId1)
        stateExists(stateId2)
        stateNotCollapsed(stateId1)
        stateNotCollapsed(stateId2)
    {
        if (stateId1 == stateId2) return; // Cannot entangle a state with itself

        // Add stateId2 to stateId1's entangled list if not already present
        bool alreadyEntangled1 = false;
        uint256[] storage entangledList1 = entangledStates[stateId1];
        for(uint i = 0; i < entangledList1.length; i++){
            if(entangledList1[i] == stateId2){
                alreadyEntangled1 = true;
                break;
            }
        }
        if(!alreadyEntangled1) entangledList1.push(stateId2);

        // Add stateId1 to stateId2's entangled list if not already present
        bool alreadyEntangled2 = false;
        uint256[] storage entangledList2 = entangledStates[stateId2];
         for(uint i = 0; i < entangledList2.length; i++){
            if(entangledList2[i] == stateId1){
                alreadyEntangled2 = true;
                break;
            }
        }
        if(!alreadyEntangled2) entangledList2.push(stateId1);

        if (!alreadyEntangled1 || !alreadyEntangled2) {
            emit StatesEntangled(stateId1, stateId2);
        }
    }

    /// @notice Disentangles two states. Removes the reciprocal link.
    /// @dev Only owner can disentangle.
    /// @param stateId1 The ID of the first state.
    /// @param stateId2 The ID of the second state.
    function disentangleStates(uint256 stateId1, uint256 stateId2)
        external
        onlyOwner // Restriction added for complexity, could be state creator or permissioned
        stateExists(stateId1)
        stateExists(stateId2)
    {
         if (stateId1 == stateId2) return;

        // Remove stateId2 from stateId1's list
        uint256[] storage entangledList1 = entangledStates[stateId1];
        for(uint i = 0; i < entangledList1.length; i++){
            if(entangledList1[i] == stateId2){
                entangledList1[i] = entangledList1[entangledList1.length - 1];
                entangledList1.pop();
                break;
            }
        }

        // Remove stateId1 from stateId2's list
        uint256[] storage entangledList2 = entangledStates[stateId2];
         for(uint i = 0; i < entangledList2.length; i++){
            if(entangledList2[i] == stateId1){
                entangledList2[i] = entangledList2[entangledList2.length - 1];
                entangledList2.pop();
                break;
            }
        }

        emit StatesDisentangled(stateId1, stateId2);
    }

    // --- Collapse & Measurement Functions ---

    /// @notice Triggers a check to see if a state's collapse condition is met and collapses it if true.
    /// @param stateId The ID of the state to check.
    function checkAndCollapseState(uint256 stateId)
        public // Public so anyone can trigger a check
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        if (_evaluateCollapseCondition(stateId)) {
            _handleStateCollapse(stateId, quantumStates[stateId].condition.conditionType);
        } else {
            revert CollapseConditionNotMet(stateId);
        }
    }

    /// @notice Triggers a collapse check for a state and recursively checks its entangled states.
    /// @dev Be mindful of potential gas limits if entanglement chains/graphs are large.
    /// @param stateId The starting state ID for the check.
    function checkAndCollapseEntangledStates(uint256 stateId)
        external // External so anyone can trigger the propagation
        stateExists(stateId)
    {
        // Reset check tracker for this transaction
        // Note: This simple approach doesn't guarantee avoiding stack depth limits
        // or infinite loops if entanglement forms cycles in a very deep chain within one transaction.
        // A more complex system might use a queue or off-chain process.
        delete _checkedInTx; // Clears the entire mapping for a new transaction

        _recursiveCheckAndCollapse(stateId);
    }

    /// @notice Allows the creator or designated address to trigger manual collapse if the condition allows.
    /// @param stateId The ID of the state.
    function triggerManualCollapse(uint256 stateId)
        external
        stateExists(stateId)
        stateNotCollapsed(stateId)
    {
        QuantumState storage state = quantumStates[stateId];
        uint8 conditionType = state.condition.conditionType;

        bool authorized = false;
        if (conditionType == 4 && msg.sender == state.creator) {
            authorized = true;
        } else if (conditionType == 5 && msg.sender == state.condition.triggerAddress) {
            authorized = true;
        }

        if (!authorized) revert ManualTriggerConditionNotMet(stateId);

        _handleStateCollapse(stateId, conditionType);
    }


    /// @dev Internal function to evaluate if a state's collapse condition is met.
    /// @param stateId The ID of the state.
    /// @return bool True if the condition is met, false otherwise.
    function _evaluateCollapseCondition(uint256 stateId) internal view returns (bool) {
        QuantumState storage state = quantumStates[stateId];
        CollapseCondition storage condition = state.condition;

        if (state.isCollapsed) return true; // Already collapsed

        uint8 conditionType = condition.conditionType;

        if (conditionType == 1) { // Timestamp
            return block.timestamp >= condition.timestamp;
        } else if (conditionType == 2) { // Oracle Threshold
            // Mock Oracle Call - Replace with real oracle interaction (e.g., Chainlink)
            if (condition.oracleAddress == address(0)) return false;
            try IMockOracle(condition.oracleAddress).getValue(condition.oracleQueryData) returns (uint256 value) {
                return value >= condition.oracleThreshold;
            } catch {
                revert OracleCallFailed(condition.oracleAddress);
            }
        } else if (conditionType == 3) { // Entangled State Collapsed
             // Check if the entangled state exists and is collapsed
             if (!quantumStates[condition.entangledStateId].exists) return false; // Can't collapse if entangled state doesn't exist
             return quantumStates[condition.entangledStateId].isCollapsed;
        } else if (conditionType == 4 || conditionType == 5) { // Manual Trigger (requires specific function call)
             // Condition is met if triggerManualCollapse is called by the correct party.
             // This function only checks if the *potential* is there, not if the call happened *now*.
             // The actual collapse is handled by triggerManualCollapse calling _handleStateCollapse.
             // So, this type should return false here, unless called internally from triggerManualCollapse.
             // However, checkAndCollapseState calls this. Let's simplify: these types cannot be met by just this check.
             // They *require* the dedicated trigger function.
             return false;
        }
        // Add other condition types here

        return false; // Condition type 0 (None) or unknown type never met automatically
    }

    /// @dev Internal recursive function to check and collapse a state and its entangled counterparts.
    /// @param stateId The state ID to check.
    function _recursiveCheckAndCollapse(uint256 stateId) internal {
        if (_checkedInTx[stateId]) {
            return; // Already checked in this transaction
        }
        _checkedInTx[stateId] = true; // Mark as checked

        if (!quantumStates[stateId].exists || quantumStates[stateId].isCollapsed) {
             // State doesn't exist or is already collapsed, no need to process
            return;
        }

        // Attempt to collapse this state
        bool collapsedThisCall = false;
        if (_evaluateCollapseCondition(stateId)) {
            _handleStateCollapse(stateId, quantumStates[stateId].condition.conditionType);
            collapsedThisCall = true;
        }

        // Recursively check entangled states if this state collapsed OR if we just want to propagate checks
        // Decided to propagate checks regardless of whether *this* state collapsed in *this* call,
        // as entanglement might mean condition depends on something external.
        // If only propagate on collapse: `if (collapsedThisCall)`
        uint256[] storage entangledList = entangledStates[stateId];
        for (uint i = 0; i < entangledList.length; i++) {
            _recursiveCheckAndCollapse(entangledList[i]);
        }
    }


    /// @dev Internal function to perform actions when a state collapses.
    /// @param stateId The ID of the state.
    /// @param conditionMetType The type of condition that triggered collapse.
    function _handleStateCollapse(uint256 stateId, uint8 conditionMetType) internal {
        QuantumState storage state = quantumStates[stateId];
        require(!state.isCollapsed, "State already collapsed"); // Should be caught by modifier, but safety first

        state.isCollapsed = true;

        // Tokens remain in the contract, claimable proportionally by potential owners.
        // No tokens are moved automatically upon collapse to save gas during collapse event.

        emit QuantumStateCollapsed(stateId, conditionMetType);
    }

    // --- Claiming Functions ---

    /// @notice Allows a potential owner of a collapsed state to claim their proportional share of an ERC20 token.
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC20 token.
    function claimProportionalERC20(uint256 stateId, address tokenAddress)
        external
        stateExists(stateId)
        stateCollapsed(stateId)
    {
        uint256 claimantShare = statePotentialOwnerShares[stateId][msg.sender];
        uint256 totalShares = stateTotalShares[stateId];

        if (claimantShare == 0) revert PotentialOwnerHasNoShares(stateId, msg.sender);
        if (totalShares == 0) revert TotalSharesCannotBeZero(); // Should not happen if shares were set, but safety check

        uint256 totalHeldAmount = stateERC20Balances[stateId][tokenAddress];
        if (totalHeldAmount == 0) revert NothingToClaim(stateId, tokenAddress, 0);

        uint256 alreadyClaimed = claimedAmountsERC20[stateId][msg.sender][tokenAddress];

        // Calculate the eligible amount: (total * share) / totalShares
        // Using multiplication first might overflow, careful with large numbers.
        // A safer way for fractional calculation: (a * b) / c
        uint256 eligibleAmount = (totalHeldAmount * claimantShare) / totalShares;

        uint256 claimableNow = eligibleAmount > alreadyClaimed ? eligibleAmount - alreadyClaimed : 0;

        if (claimableNow == 0) revert NothingToClaim(stateId, tokenAddress, 0);

        claimedAmountsERC20[stateId][msg.sender][tokenAddress] += claimableNow; // Record claim *before* transfer (Checks-Effects-Interactions)
        IERC20(tokenAddress).safeTransfer(msg.sender, claimableNow);

        emit TokensClaimedERC20(stateId, msg.sender, tokenAddress, claimableNow);
    }

    /// @notice Allows a potential owner of a collapsed state to claim specific ERC721 token IDs they are eligible for.
    /// @dev Eligibility is based on proportional count, but actual tokens claimed are first-come, first-served amongst eligible owners.
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC721 token type.
    /// @param tokenIdsToClaim The specific token IDs the claimant wishes to claim.
    function claimProportionalERC721(uint256 stateId, address tokenAddress, uint256[] calldata tokenIdsToClaim)
        external
        stateExists(stateId)
        stateCollapsed(stateId)
    {
        uint256 claimantShare = statePotentialOwnerShares[stateId][msg.sender];
        uint256 totalShares = stateTotalShares[stateId];

        if (claimantShare == 0) revert PotentialOwnerHasNoShares(stateId, msg.sender);
        if (totalShares == 0) revert TotalSharesCannotBeZero();

        // Calculate total count of this token type remaining in the state
        uint256 totalHeldCount = 0;
        // This requires iterating through all potential tokenIds ever associated with this state/token type
        // Or maintaining a separate count. Let's maintain a separate count.
        // Need to add/remove from stateHoldsERC721 and manage a total count mapping.
        // Added `stateHoldsERC721` mapping during deposits. Now need total count.
        // Let's iterate through the list of *claimed* tokens to find the *remaining* total count.
        // This is inefficient. A better way is to track total deposited count vs total claimed count.

        // Let's refine ERC721 state tracking:
        // mapping(uint256 => mapping(address => mapping(uint256 => bool))) public stateHoldsERC721; // Deposited into state
        // mapping(uint256 => mapping(address => mapping(uint256 => bool))) public claimedERC721Tokens; // Claimed by ANYONE

        // To get the total count currently *in* the state, we need to iterate over stateHoldsERC721 and check if !claimedERC721Tokens.
        // This is very expensive for many tokens.
        // Alternative: Store the *list* of tokenIds in the state.
        // mapping(uint256 => mapping(address => uint256[])) public stateHeldERC721IdsList; // stateId => tokenAddress => list of tokenIds
        // This array becomes unmanageable for removal.

        // Let's revert to the simpler, though potentially slower for audits, stateHoldsERC721 + claimedERC721Tokens.
        // To get total held count without iterating stateHoldsERC721: requires storing the initial count
        // and decrementing? Yes, let's add `mapping(uint256 => mapping(address => uint256)) public initialHeldERC721Count;`
        // and `mapping(uint256 => mapping(address => uint256)) public totalClaimedERC721Count;`
        // Total currently in state = initialHeldERC721Count - totalClaimedERC721Count.

        // Adding state variables:
        // mapping(uint256 => mapping(address => uint256)) private initialHeldERC721Count; // stateId => tokenAddress => count at collapse or initial deposit? Let's do total ever deposited.
        // mapping(uint256 => mapping(address => uint256)) private totalClaimedERC721Count; // stateId => tokenAddress => count claimed by anyone

        // Update depositERC721IntoState and depositMultipleERC721IntoState to increment initialHeldERC721Count.

        uint256 initialCount = initialHeldERC721Count[stateId][tokenAddress];
        uint256 totalClaimedByAnyone = totalClaimedERC721Count[stateId][tokenAddress];
        uint256 remainingTotalCount = initialCount > totalClaimedByAnyone ? initialCount - totalClaimedByAnyone : 0;

        if (remainingTotalCount == 0) revert NothingToClaim(stateId, tokenAddress, 0);

        uint256 claimantAlreadyClaimedCount = claimedCountForTokenERC721[stateId][msg.sender][tokenAddress];

        // Calculate eligible count: (total_remaining * share) / totalShares
        uint256 eligibleCount = (remainingTotalCount * claimantShare) / totalShares;

        uint256 claimableNowCount = eligibleCount > claimantAlreadyClaimedCount ? eligibleCount - claimantAlreadyClaimedCount : 0;

        if (tokenIdsToClaim.length == 0) revert NothingToClaim(stateId, tokenAddress, 0);
        if (tokenIdsToClaim.length > claimableNowCount) revert InsufficientClaimableCount(tokenIdsToClaim.length, claimableNowCount);

        uint256 successfullyClaimedCount = 0;
        uint256[] memory claimedTokenIdsInCall = new uint256[](tokenIdsToClaim.length); // Temp array for event

        for (uint i = 0; i < tokenIdsToClaim.length; i++) {
            uint256 tokenId = tokenIdsToClaim[i];

            // Check if the state actually holds this specific token AND it hasn't been claimed by ANYONE yet
            if (!stateHoldsERC721[stateId][tokenAddress][tokenId]) revert ERC721TokenNotInState(stateId, tokenAddress, tokenId);
            if (claimedERC721Tokens[stateId][tokenAddress][tokenId]) revert ERC721TokenAlreadyClaimed(stateId, tokenAddress, tokenId);

            // Record claim *before* transfer (Checks-Effects-Interactions)
            claimedERC721Tokens[stateId][tokenAddress][tokenId] = true; // Mark as claimed globally
            claimedCountForTokenERC721[stateId][msg.sender][tokenAddress]++; // Increment claimant's count for this token type
            totalClaimedERC721Count[stateId][tokenAddress]++; // Increment total claimed for this token type/state
            successfullyClaimedCount++;
            claimedTokenIdsInCall[successfullyClaimedCount - 1] = tokenId; // Add to event list

            IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        }

        if (successfullyClaimedCount > 0) {
            // Resize the event array if needed
            uint256[] memory finalClaimedTokenIds = new uint256[](successfullyClaimedCount);
            for(uint i = 0; i < successfullyClaimedCount; i++){
                finalClaimedTokenIds[i] = claimedTokenIdsInCall[i];
            }
            emit TokensClaimedERC721(stateId, msg.sender, tokenAddress, finalClaimedTokenIds);
        }
    }

    // --- Internal Helper Functions ---

    /// @dev Checks if an ERC721 token address is already listed in the state's list of token types.
    function isERC721TokenAddressListed(uint256 stateId, address tokenAddress) internal view returns (bool) {
        address[] storage tokenList = stateERC721TokensList[stateId];
        for(uint i=0; i<tokenList.length; i++){
            if(tokenList[i] == tokenAddress){
                return true;
            }
        }
        return false;
    }


    // --- Query/Information Functions ---

    /// @notice Gets basic information about a quantum state.
    /// @param stateId The ID of the state.
    /// @return id The state ID.
    /// @return creator The address that created the state.
    /// @return isCollapsed Whether the state has collapsed.
    /// @return totalShares The sum of all potential owner shares (basis points).
    function getQuantumStateInfo(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256 id, address creator, bool isCollapsed, uint256 totalShares)
    {
        QuantumState storage state = quantumStates[stateId];
        return (state.id, state.creator, state.isCollapsed, stateTotalShares[stateId]);
    }

    /// @notice Gets the balance of a specific ERC20 token held in a state.
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return balance The amount of tokens held.
    function getStateERC20Balance(uint256 stateId, address tokenAddress)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return stateERC20Balances[stateId][tokenAddress];
    }

    /// @notice Checks if a specific ERC721 token is held within a state (was deposited and not yet claimed).
    /// @param stateId The ID of the state.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the ERC721 token.
    /// @return bool True if the token is held and not claimed, false otherwise.
    function getStateERC721Status(uint256 stateId, address tokenAddress, uint256 tokenId)
        external
        view
        stateExists(stateId)
        returns (bool)
    {
        // It's held if it was deposited and hasn't been claimed by anyone
        return stateHoldsERC721[stateId][tokenAddress][tokenId] && !claimedERC721Tokens[stateId][tokenAddress][tokenId];
    }


    /// @notice Gets the share percentage (basis points) for a specific potential owner in a state.
    /// @param stateId The ID of the state.
    /// @param potentialOwner The address of the potential owner.
    /// @return sharesBasisPoints The shares in basis points.
    function getPotentialOwnerShare(uint256 stateId, address potentialOwner)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return statePotentialOwnerShares[stateId][potentialOwner];
    }

    /// @notice Gets the total sum of all potential owner shares for a state.
    /// @param stateId The ID of the state.
    /// @return totalSharesBasisPoints The total shares in basis points.
    function getTotalPotentialShares(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return stateTotalShares[stateId];
    }

    /// @notice Gets the total amount of a specific ERC20 token claimed by an address from a state.
    /// @param stateId The ID of the state.
    /// @param claimant The address of the claimant.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return amountClaimed The total amount claimed.
    function getClaimedAmountERC20(uint256 stateId, address claimant, address tokenAddress)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return claimedAmountsERC20[stateId][claimant][tokenAddress];
    }

    /// @notice Gets the total count of a specific ERC721 token type claimed by an address from a state.
    /// @param stateId The ID of the state.
    /// @param claimant The address of the claimant.
    /// @param tokenAddress The address of the ERC721 token type.
    /// @return countClaimed The total count claimed.
    function getClaimedCountERC721(uint256 stateId, address claimant, address tokenAddress)
        external
        view
        stateExists(stateId)
        returns (uint256)
    {
        return claimedCountForTokenERC721[stateId][claimant][tokenAddress];
    }


     /// @notice Checks if a specific ERC721 token ID has been claimed by *any* potential owner from a state.
     /// @param stateId The ID of the state.
     /// @param tokenAddress The address of the ERC721 token type.
     /// @param tokenId The ID of the specific token.
     /// @return bool True if the token ID has been claimed, false otherwise.
    function isERC721TokenClaimed(uint256 stateId, address tokenAddress, uint256 tokenId)
        external
        view
        stateExists(stateId)
        returns (bool)
    {
        return claimedERC721Tokens[stateId][tokenAddress][tokenId];
    }

    /// @notice Gets the list of states directly entangled with a given state.
    /// @param stateId The ID of the state.
    /// @return entangledStateIds The list of entangled state IDs.
    function getEntangledStatesDirect(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (uint256[] memory)
    {
        return entangledStates[stateId];
    }

    /// @notice Retrieves the full details of a state's collapse condition.
    /// @param stateId The ID of the state.
    /// @return conditionDetails The full CollapseCondition struct.
    function getCollapseConditionDetails(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (CollapseCondition memory)
    {
        return quantumStates[stateId].condition;
    }

    /// @notice Checks if a state has collapsed.
    /// @param stateId The ID of the state.
    /// @return bool True if collapsed, false otherwise.
    function isStateCollapsed(uint256 stateId)
        external
        view
        stateExists(stateId)
        returns (bool)
    {
        return quantumStates[stateId].isCollapsed;
    }

     /// @notice Returns the ID that will be assigned to the next created state.
     /// @return The next state ID.
    function getNextStateId() external view returns (uint256) {
        return nextStateId;
    }

    // Internal helper function for ERC721 deposit tracking update
    // This is called *after* a successful transfer in deposit ERC721 functions
    function _updateInitialHeldERC721Count(uint256 stateId, address tokenAddress, uint256 count) internal {
        initialHeldERC721Count[stateId][tokenAddress] += count;
    }

    // --- Receive/Fallback (Optional but good practice) ---
    receive() external payable {}
    fallback() external payable {}
}
```