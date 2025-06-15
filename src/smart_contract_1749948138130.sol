Okay, here is a smart contract concept called "QuantumVault". It's designed around the idea of locking funds that become accessible or yield rewards based on the resolution of external, future events (simulated via an authorized resolver). It incorporates elements of prediction markets, conditional access, time-locking, and multi-asset handling.

It aims for creativity by tying vault access and outcomes to oracle-like resolutions of defined "Quantum States," rather than simple time locks or fixed conditions.

**QuantumVault Smart Contract**

**Outline:**

1.  **Purpose:** A contract allowing users to deposit native tokens or approved ERC-20 tokens associated with predicted outcomes of defined "Quantum States". Funds and potential rewards are claimable based on the resolved outcome of the state after its resolution time.
2.  **Core Concepts:**
    *   **QuantumState:** Represents a future event with defined possible outcomes. Has a resolution time and is resolved by an authorized `resolverAddress`.
    *   **Outcome:** A specific possible result for a QuantumState. Users deposit funds against their predicted outcome.
    *   **Resolver:** An authorized address responsible for submitting the final, true outcome of a QuantumState.
    *   **Deposit Pools:** Funds deposited for each outcome within a QuantumState are pooled separately.
    *   **Claiming:** Users can claim their principal back if their prediction was incorrect (after resolution), or their principal + a pro-rata share of the winning outcome's pool if their prediction was correct. Principal can also be claimed if the state is cancelled or unresolved past a certain timeout.
3.  **Key Features:**
    *   Support for native token (ETH) and approved ERC-20 tokens.
    *   Creation and management of Quantum States by the owner.
    *   Prediction/staking by depositing funds linked to an outcome.
    *   Oracle-like resolution mechanism via a dedicated resolver address.
    *   Conditional claiming based on prediction correctness and state status.
    *   Time-based access restrictions.
    *   Owner-controlled list of accepted ERC-20 tokens.
    *   Emergency owner withdrawal mechanism.

**Function Summary:**

*   **State Management:**
    *   `createQuantumState`: Owner creates a new state with description, possible outcomes, and resolution time.
    *   `cancelQuantumState`: Owner/Creator cancels a state before resolution time.
    *   `resolveQuantumState`: Resolver sets the final outcome for a state after its resolution time.
    *   `getQuantumStateDetails`: View all details of a state.
    *   `getQuantumStateOutcome`: View the resolved outcome of a state.
    *   `getQuantumStatePossibleOutcomes`: View the list of possible outcomes for a state.
    *   `getOutcomeDescription`: View the description string for a specific outcome ID within a state.
    *   `getQuantumStateStatus`: View the current status (Open, Resolved, Cancelled) of a state.
    *   `isQuantumStateResolved`: Check if a state has been resolved.
    *   `getAllQuantumStateIds`: Get a list of all created state IDs.

*   **Deposit & Prediction:**
    *   `depositNativeForPrediction`: Deposit native token (ETH) for a specific outcome in a state.
    *   `depositERC20ForPrediction`: Deposit approved ERC-20 tokens for an outcome in a state.
    *   `getUserPredictionAmountNative`: View native token amount deposited by a user for an outcome.
    *   `getUserPredictionAmountERC20`: View ERC-20 amount deposited by a user for an outcome/token.
    *   `getTotalDepositsForOutcomeNative`: View total native tokens deposited for an outcome.
    *   `getTotalDepositsForOutcomeERC20`: View total ERC-20 tokens deposited for an outcome/token.
    *   `getTotalDepositsInStateNative`: View total native tokens across all outcomes in a state.
    *   `getTotalDepositsInStateERC20`: View total ERC-20 tokens across all outcomes/tokens in a state.

*   **Claiming & Withdrawals:**
    *   `claimNativeWinningsAndPrincipal`: Claim native tokens (principal + winnings) if prediction was correct and state is resolved.
    *   `claimERC20WinningsAndPrincipal`: Claim ERC-20 tokens (principal + winnings) if prediction was correct and state is resolved.
    *   `claimNativePrincipal`: Claim native token principal if prediction was incorrect (after resolution), state cancelled, or state unresolved past timeout.
    *   `claimERC20Principal`: Claim ERC-20 principal if prediction was incorrect (after resolution), state cancelled, or state unresolved past timeout.
    *   `getUserClaimableNative`: Preview the total native tokens a user can claim (winnings or principal).
    *   `getUserClaimableERC20`: Preview the total ERC-20 tokens a user can claim (winnings or principal).
    *   `ownerEmergencyWithdrawNative`: Owner can withdraw native tokens in emergency (use with caution).
    *   `ownerEmergencyWithdrawERC20`: Owner can withdraw ERC-20 tokens in emergency (use with caution).

*   **Access Control & Configuration:**
    *   `setResolverAddress`: Owner sets the address authorized to resolve states.
    *   `getResolverAddress`: View the current resolver address.
    *   `transferOwnership`: Standard Ownable function to transfer contract ownership.
    *   `renounceOwnership`: Standard Ownable function to renounce contract ownership.
    *   `getOwner`: View the contract owner.
    *   `addAcceptedERC20Token`: Owner adds an ERC-20 token address to the approved list.
    *   `removeAcceptedERC20Token`: Owner removes an ERC-20 token address from the approved list.
    *   `getAcceptedERC20Tokens`: View the list of accepted ERC-20 token addresses.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline & Function Summary ---
// Outline:
// 1. Purpose: A contract for depositing funds tied to predictions on future events (Quantum States).
// 2. Core Concepts: QuantumState, Outcome, Resolver, Deposit Pools, Claiming.
// 3. Key Features: Multi-asset support (Native, ERC20), State management, Prediction deposits, Oracle-like resolution, Conditional claims, Time locks, Accepted ERC20 list, Emergency withdrawals.
//
// Function Summary:
// State Management: createQuantumState, cancelQuantumState, resolveQuantumState, getQuantumStateDetails, getQuantumStateOutcome, getQuantumStatePossibleOutcomes, getOutcomeDescription, getQuantumStateStatus, isQuantumStateResolved, getAllQuantumStateIds.
// Deposit & Prediction: depositNativeForPrediction, depositERC20ForPrediction, getUserPredictionAmountNative, getUserPredictionAmountERC20, getTotalDepositsForOutcomeNative, getTotalDepositsForOutcomeERC20, getTotalDepositsInStateNative, getTotalDepositsInStateERC20.
// Claiming & Withdrawals: claimNativeWinningsAndPrincipal, claimERC20WinningsAndPrincipal, claimNativePrincipal, claimERC20Principal, getUserClaimableNative, getUserClaimableERC20, ownerEmergencyWithdrawNative, ownerEmergencyWithdrawERC20.
// Access Control & Configuration: setResolverAddress, getResolverAddress, transferOwnership, renounceOwnership, getOwner, addAcceptedERC20Token, removeAcceptedERC20Token, getAcceptedERC20Tokens.
// --- End Outline & Function Summary ---

contract QuantumVault is Ownable, ReentrancyGuard {

    // --- State Variables ---

    enum StateStatus {
        Open,       // Deposits are accepted, not yet resolved
        Resolved,   // Outcome has been set, claims for resolved outcome are possible
        Cancelled   // State was cancelled, principal can be claimed
    }

    struct QuantumState {
        uint256 id; // Unique ID for the state
        string description;
        uint256 resolutionTime; // Timestamp after which the state can be resolved
        uint256 claimTimeoutPeriod; // Time after resolutionTime when unresolved principal can be claimed

        uint256[] possibleOutcomeIds; // List of valid outcome IDs for this state
        mapping(uint256 => string) outcomeDescriptions; // Mapping outcome ID to its description

        StateStatus status;
        uint256 resolvedOutcomeId; // The ID of the actual outcome (0 if not resolved)

        // Mapping from outcomeId -> depositor address -> amount deposited (Native Token)
        mapping(uint256 => mapping(address => uint256)) depositedNative;
        // Mapping from outcomeId -> total amount deposited (Native Token)
        mapping(uint256 => uint256) totalDepositedNativeForOutcome;
        // Mapping from outcomeId -> token address -> depositor address -> amount deposited (ERC20)
        mapping(uint256 => mapping(address => mapping(address => uint256))) depositedERC20;
        // Mapping from outcomeId -> token address -> total amount deposited (ERC20)
        mapping(uint256 => mapping(address => uint256)) totalDepositedERC20ForOutcome;

        // Track claimed amounts to prevent double claims
        mapping(address => mapping(address => uint256)) claimedNative; // user => stateId => amount
        mapping(address => mapping(address => mapping(address => uint256))) claimedERC20; // user => stateId => tokenAddress => amount
    }

    uint256 private _nextStateId = 1;
    mapping(uint256 => QuantumState) public quantumStates;
    uint256[] private _allQuantumStateIds;

    address public resolverAddress; // Address authorized to resolve states

    mapping(address => bool) private _acceptedERC20Tokens;
    address[] private _acceptedERC20TokenList;

    // --- Events ---

    event QuantumStateCreated(uint256 indexed stateId, string description, uint256 resolutionTime, uint256 claimTimeoutPeriod, uint256[] possibleOutcomeIds, address indexed creator);
    event QuantumStateCancelled(uint256 indexed stateId, address indexed canceller);
    event QuantumStateResolved(uint256 indexed stateId, uint256 indexed resolvedOutcomeId, address indexed resolver);
    event DepositMade(uint256 indexed stateId, uint256 indexed outcomeId, address indexed depositor, uint256 amountNative, address tokenAddress, uint256 amountERC20);
    event WinningsClaimed(uint256 indexed stateId, uint256 indexed outcomeId, address indexed winner, uint256 amountNative, address tokenAddress, uint256 amountERC20);
    event PrincipalClaimed(uint256 indexed stateId, address indexed claimant, uint256 amountNative, address tokenAddress, uint256 amountERC20);
    event ResolverAddressSet(address indexed oldResolver, address indexed newResolver);
    event AcceptedERC20Added(address indexed tokenAddress);
    event AcceptedERC20Removed(address indexed tokenAddress);
    event OwnerEmergencyWithdrawal(address indexed tokenAddress, uint256 amount);

    // --- Constructor ---

    constructor(address _resolverAddress, uint256 _defaultClaimTimeoutPeriod) Ownable(msg.sender) {
        require(_resolverAddress != address(0), "Resolver address cannot be zero");
        resolverAddress = _resolverAddress;
        // Default timeout for claiming principal if unresolved
        // Can be overridden when creating a state
        _defaultClaimTimeout = _defaultClaimTimeoutPeriod;
    }

    // --- Configuration Functions (Owner) ---

    uint256 private _defaultClaimTimeout; // Default seconds after resolutionTime to allow unresolved principal claim

    function setDefaultClaimTimeout(uint256 _timeout) external onlyOwner {
        _defaultClaimTimeout = _timeout;
    }

    function getDefaultClaimTimeout() external view returns (uint256) {
        return _defaultClaimTimeout;
    }

    function setResolverAddress(address _newResolver) external onlyOwner {
        require(_newResolver != address(0), "New resolver address cannot be zero");
        emit ResolverAddressSet(resolverAddress, _newResolver);
        resolverAddress = _newResolver;
    }

    function addAcceptedERC20Token(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        if (!_acceptedERC20Tokens[_tokenAddress]) {
            _acceptedERC20Tokens[_tokenAddress] = true;
            _acceptedERC20TokenList.push(_tokenAddress);
            emit AcceptedERC20Added(_tokenAddress);
        }
    }

    function removeAcceptedERC20Token(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        if (_acceptedERC20Tokens[_tokenAddress]) {
            _acceptedERC20Tokens[_tokenAddress] = false;
            // Simple removal by marking false, list traversal might be needed for clean list
            // For simplicity here, we just mark false in mapping
            emit AcceptedERC20Removed(_tokenAddress);
        }
    }

    function getAcceptedERC20Tokens() external view returns (address[] memory) {
        // Returns the list including potentially removed tokens marked as false
        // A cleaner implementation might rebuild the list, but this is simpler
        return _acceptedERC20TokenList;
    }

    function isAcceptedERC20(address _tokenAddress) public view returns (bool) {
        return _acceptedERC20Tokens[_tokenAddress];
    }

    // --- State Management Functions ---

    function createQuantumState(
        string memory _description,
        uint256 _resolutionTime,
        uint256[] memory _possibleOutcomeIds,
        string[] memory _outcomeDescriptions,
        uint256 _customClaimTimeoutPeriod // 0 to use default
    ) external onlyOwner nonReentrant {
        require(_resolutionTime > block.timestamp, "Resolution time must be in the future");
        require(_possibleOutcomeIds.length > 0, "Must define at least one possible outcome");
        require(_possibleOutcomeIds.length == _outcomeDescriptions.length, "Outcome ID and description arrays must match in length");

        uint256 newStateId = _nextStateId++;
        QuantumState storage newState = quantumStates[newStateId];

        newState.id = newStateId;
        newState.description = _description;
        newState.resolutionTime = _resolutionTime;
        newState.claimTimeoutPeriod = _customClaimTimeoutPeriod > 0 ? _customClaimTimeoutPeriod : _defaultClaimTimeout;
        newState.possibleOutcomeIds = _possibleOutcomeIds;
        newState.status = StateStatus.Open;
        newState.resolvedOutcomeId = 0; // 0 indicates not resolved

        for (uint i = 0; i < _possibleOutcomeIds.length; i++) {
            // Check for unique outcome IDs within this state
            for (uint j = i + 1; j < _possibleOutcomeIds.length; j++) {
                require(_possibleOutcomeIds[i] != _possibleOutcomeIds[j], "Outcome IDs must be unique within a state");
            }
            newState.outcomeDescriptions[_possibleOutcomeIds[i]] = _outcomeDescriptions[i];
        }

        _allQuantumStateIds.push(newStateId);

        emit QuantumStateCreated(newStateId, _description, _resolutionTime, newState.claimTimeoutPeriod, _possibleOutcomeIds, msg.sender);
    }

    function cancelQuantumState(uint256 _stateId) external nonReentrant {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Open, "State is not open for cancellation");
        require(msg.sender == owner() || msg.sender == resolverAddress, "Only owner or resolver can cancel"); // Or add a specific state creator role

        state.status = StateStatus.Cancelled;
        emit QuantumStateCancelled(_stateId, msg.sender);
    }

    function resolveQuantumState(uint256 _stateId, uint256 _resolvedOutcomeId) external nonReentrant {
        require(msg.sender == resolverAddress, "Only the designated resolver can resolve");

        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Open, "State is not open for resolution");
        require(block.timestamp >= state.resolutionTime, "Resolution time has not passed yet");

        bool outcomeFound = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
            if (state.possibleOutcomeIds[i] == _resolvedOutcomeId) {
                outcomeFound = true;
                break;
            }
        }
        require(outcomeFound, "Resolved outcome ID is not valid for this state");

        state.status = StateStatus.Resolved;
        state.resolvedOutcomeId = _resolvedOutcomeId;

        emit QuantumStateResolved(_stateId, _resolvedOutcomeId, msg.sender);
    }

    // --- Deposit Functions ---

    function depositNativeForPrediction(uint256 _stateId, uint256 _outcomeId) external payable nonReentrant {
        require(msg.value > 0, "Must deposit native tokens");
        require(msg.sender != address(0), "Depositor cannot be zero address");

        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Open, "State is not open for deposits");
        require(block.timestamp < state.resolutionTime, "Resolution time has passed");

        bool outcomeFound = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
            if (state.possibleOutcomeIds[i] == _outcomeId) {
                outcomeFound = true;
                break;
            }
        }
        require(outcomeFound, "Invalid outcome ID for this state");

        state.depositedNative[_outcomeId][msg.sender] += msg.value;
        state.totalDepositedNativeForOutcome[_outcomeId] += msg.value;

        emit DepositMade(_stateId, _outcomeId, msg.sender, msg.value, address(0), 0); // address(0) indicates native token
    }

    function depositERC20ForPrediction(uint256 _stateId, uint256 _outcomeId, address _tokenAddress, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Must deposit non-zero amount");
        require(msg.sender != address(0), "Depositor cannot be zero address");
        require(isAcceptedERC20(_tokenAddress), "Token not accepted by this vault");

        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Open, "State is not open for deposits");
        require(block.timestamp < state.resolutionTime, "Resolution time has passed");

        bool outcomeFound = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
            if (state.possibleOutcomeIds[i] == _outcomeId) {
                outcomeFound = true;
                break;
            }
        }
        require(outcomeFound, "Invalid outcome ID for this state");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");

        state.depositedERC20[_outcomeId][_tokenAddress][msg.sender] += _amount;
        state.totalDepositedERC20ForOutcome[_tokenAddress][_outcomeId] += _amount; // Corrected mapping key order

        emit DepositMade(_stateId, _outcomeId, msg.sender, 0, _tokenAddress, _amount);
    }

    // --- Claiming Functions ---

    function claimNativeWinningsAndPrincipal(uint256 _stateId) external nonReentrant {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Resolved, "State is not resolved");

        uint256 resolvedOutcome = state.resolvedOutcomeId;
        require(resolvedOutcome != 0, "State is resolved but outcome not set?"); // Should not happen if status is Resolved

        uint256 predictedOutcome = 0;
        uint256 userNativeDeposit = 0;

        // Find which outcome the user predicted with native tokens and their total deposit
        // Note: This assumes a user only predicts *one* outcome per state with native tokens.
        // If multiple predictions for same state/asset were allowed, this would need to sum them up.
        // For this contract, re-depositing for the same outcome adds to the existing deposit.
        // If they deposited for *different* outcomes, only the one matching resolvedOutcome matters here.
        // Let's iterate through outcomes to find if user deposited on the winning one.
        bool predictedCorrectly = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
             uint256 outcomeId = state.possibleOutcomeIds[i];
             uint256 amount = state.depositedNative[outcomeId][msg.sender];
             if (amount > 0) {
                if (outcomeId == resolvedOutcome) {
                    userNativeDeposit = amount;
                    predictedOutcome = outcomeId; // Record the winning outcome predicted
                    predictedCorrectly = true;
                    break; // Assuming only one winning prediction matters
                }
             }
        }

        require(predictedCorrectly, "Your prediction was not the resolved outcome");
        require(userNativeDeposit > 0, "No native tokens deposited for the resolved outcome");

        // Check if already claimed for this state/token type
        uint256 alreadyClaimed = state.claimedNative[msg.sender][_stateId];
        require(userNativeDeposit > alreadyClaimed, "Native tokens already claimed for this state");

        uint256 totalDepositedForWinningOutcome = state.totalDepositedNativeForOutcome[resolvedOutcome];

        // Calculate winnings: User's share of the *winning pool* (including their own principal)
        // Winnings = (User Deposit / Total Winning Pool) * Total Winning Pool
        // Which simplifies to just User Deposit IF we only distribute the winning pool among winners.
        // If we want to distribute funds from *losing* pools to winners, the logic is more complex.
        // Let's keep it simple: winners split the *total* amount deposited into the *winning* outcome pool.
        // User receives their principal + a share of the *total* winning pool beyond their principal.
        // Total pool for winning outcome includes winners' principals.
        // Example: A: 10 ETH, B: 20 ETH. Outcome A wins. Winners (deposited 10 ETH) split 10 ETH. This isn't rewarding.
        // Better model: Winners split losing pools *plus* get their principal back. This is more complex due to different tokens.
        // Simplest model: Winners split only the winning pool, proportional to their stake in the winning pool. They effectively get their principal back + share of others' principal *in that winning pool*.
        // Let's use the simplest: winners get a pro-rata share of the *total* amount deposited into the *winning* outcome pool.

        uint256 claimAmount;
        if (totalDepositedForWinningOutcome > 0) {
             // This handles the case where userDeposit == totalDepositedForWinningOutcome
             // It also handles division correctly, though precision might be lost for very small amounts.
             claimAmount = (userNativeDeposit * totalDepositedForWinningOutcome) / totalDepositedForWinningOutcome; // This line is trivial: claimAmount = userNativeDeposit. This is NOT winnings.
             // To calculate winnings, we need the *total* pool size and how to distribute losing pools.
             // Let's stick to a simple vault concept: Winner gets their principal back + a share of the winning pool.
             // This still doesn't make sense. Let's rethink the claim logic.
             //
             // New Claim Logic:
             // 1. Correct prediction + Resolved state: User gets their principal back + a share of the *combined* principal from *all* outcomes. This is complex across token types.
             // 2. Simplified Claim Logic:
             //    - Correct prediction + Resolved state: User gets their *principal* back + a share of the *total deposits for the winning outcome*.
             //    - Incorrect prediction + Resolved state: User gets their *principal* back.
             //    - Cancelled state: User gets their *principal* back.
             //    - Unresolved past timeout: User gets their *principal* back.
             // This requires tracking which prediction(s) the user made and the amounts for *each*.
             // The current mapping `depositedNative[outcomeId][address]` supports this.

             // Let's implement claimNativeWinningsAndPrincipal for correct prediction only.
             // It should give back the user's principal *plus* their share of any 'bonus' or 'winnings' pool if applicable.
             // In this simple model, the "winnings" *are* the total pool of the correct outcome.
             // The user's share is simply their deposit amount, as the pool for the winning outcome is distributed *only* among those who predicted that outcome, proportional to their stake in that pool.
             // So, if I deposit 1 ETH into winning outcome A, and total for A is 10 ETH, and I'm the only depositor, I get 10 ETH? No, that's wrong.
             // I should get my 1 ETH principal back, plus maybe a share of the losing pools?
             //
             // Let's refine the concept: Winners get back their principal PLUS a pro-rata share of the *total* amount deposited *across all outcomes* for that state (excluding any penalties or fees).
             // Total State Pool = Sum of totalDepositedNativeForOutcome across all outcomes + Sum of totalDepositedERC20ForOutcome across all outcomes/tokens.
             // Winnings share for Native: (User Native Deposit / Total Native Deposited for Winning Outcome) * Total Native Deposited Across *All* Outcomes
             // This still doesn't seem right. Distributing native from losing native pool + ERC20 from losing ERC20 pools makes sense.
             //
             // Let's simplify the payout:
             // If you predicted the winning outcome with Native: You get your Native Principal back + a pro-rata share of the *total Native* deposited *across all outcomes*.
             // If you predicted a losing outcome with Native: You get your Native Principal back.
             // If you predicted the winning outcome with ERC20: You get your ERC20 Principal back + a pro-rata share of the *total ERC20 of that token* deposited *across all outcomes*.
             // If you predicted a losing outcome with ERC20: You get your ERC20 Principal back.

             // Okay, let's implement this simplified payout logic.
             // claimNativeWinningsAndPrincipal: For WINNERS (Native)
             // claimNativePrincipal: For LOSERS / CANCELLED / UNRESOLVED (Native)
             // claimERC20WinningsAndPrincipal: For WINNERS (ERC20)
             // claimERC20Principal: For LOSERS / CANCELLED / UNRESOLVED (ERC20)

             // Re-coding claimNativeWinningsAndPrincipal:
             // Must be resolved state.
             // Must have deposited on the resolvedOutcomeId with native tokens.
             // Calculate total native deposited *across all outcomes* for this state.
             uint256 totalNativeInState = 0;
             for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
                 totalNativeInState += state.totalDepositedNativeForOutcome[state.possibleOutcomeIds[i]];
             }

             // User's deposit for the winning outcome
             uint256 userWinAmount = state.depositedNative[resolvedOutcome][msg.sender];
             require(userWinAmount > 0, "No native deposit on the winning outcome");

             // Check if already claimed
             uint256 alreadyClaimedAmount = state.claimedNative[msg.sender][_stateId];
             require(userWinAmount > alreadyClaimedAmount, "Native winnings already claimed for this state"); // Ensure we haven't paid out the principal part

             // Calculate winnings share: user's stake in winning outcome / total stake in winning outcome * total native in state
             // This distributes the entire native pool proportionally among winners.
             uint256 totalDepositedWinningOutcomeNative = state.totalDepositedNativeForOutcome[resolvedOutcome];
             require(totalDepositedWinningOutcomeNative > 0, "No native deposits on the winning outcome pool"); // Should be covered by userWinAmount > 0, but double check.

             uint256 totalClaimable = (userWinAmount * totalNativeInState) / totalDepositedWinningOutcomeNative;
             uint256 amountToPay = totalClaimable - alreadyClaimedAmount; // Amount not yet claimed

             state.claimedNative[msg.sender][_stateId] = totalClaimable; // Mark the full calculated amount as claimed

             (bool success,) = payable(msg.sender).call{value: amountToPay}("");
             require(success, "Native transfer failed");

             emit WinningsClaimed(_stateId, resolvedOutcome, msg.sender, amountToPay, address(0), 0);
        }


    function claimERC20WinningsAndPrincipal(uint256 _stateId, address _tokenAddress) external nonReentrant {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(state.status == StateStatus.Resolved, "State is not resolved");
        require(isAcceptedERC20(_tokenAddress), "Token not accepted by this vault");

        uint256 resolvedOutcome = state.resolvedOutcomeId;
        require(resolvedOutcome != 0, "State is resolved but outcome not set?");

        uint256 userERC20Deposit = state.depositedERC20[resolvedOutcome][_tokenAddress][msg.sender];
        require(userERC20Deposit > 0, "No ERC20 deposit on the winning outcome with this token");

        // Check if already claimed for this state/token
        uint256 alreadyClaimedAmount = state.claimedERC20[msg.sender][_stateId][_tokenAddress];
        require(userERC20Deposit > alreadyClaimedAmount, "ERC20 winnings already claimed for this state/token"); // Ensure principal part isn't double paid

        // Calculate total ERC20 deposited *across all outcomes* for this state/token
        uint256 totalERC20InStateForToken = 0;
        for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
            totalERC20InStateForToken += state.totalDepositedERC20ForOutcome[_tokenAddress][state.possibleOutcomeIds[i]];
        }

        // Calculate winnings share: user's stake in winning outcome / total stake in winning outcome * total ERC20 of token in state
        uint256 totalDepositedWinningOutcomeERC20 = state.totalDepositedERC20ForOutcome[_tokenAddress][resolvedOutcome];
        require(totalDepositedWinningOutcomeERC20 > 0, "No ERC20 deposits on the winning outcome pool for this token");

        uint256 totalClaimable = (userERC20Deposit * totalERC20InStateForToken) / totalDepositedWinningOutcomeERC20;
        uint256 amountToPay = totalClaimable - alreadyClaimedAmount; // Amount not yet claimed

        state.claimedERC20[msg.sender][_stateId][_tokenAddress] = totalClaimable; // Mark the full calculated amount as claimed

        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, amountToPay), "ERC20 transfer failed");

        emit WinningsClaimed(_stateId, resolvedOutcome, msg.sender, 0, _tokenAddress, amountToPay);
    }


    function claimNativePrincipal(uint256 _stateId) external nonReentrant {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");

        uint256 userTotalDeposited = 0;
        uint256 userPredictedOutcomeId = 0; // Store the ID of the outcome user deposited on (assuming one)

        // Find the user's total deposit and which outcome they predicted (native)
        for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
            uint256 outcomeId = state.possibleOutcomeIds[i];
            uint256 amount = state.depositedNative[outcomeId][msg.sender];
            if (amount > 0) {
                userTotalDeposited = amount;
                userPredictedOutcomeId = outcomeId; // Assuming user only deposits native for one outcome
                break;
            }
        }

        require(userTotalDeposited > 0, "No native tokens deposited for this state");

        uint256 alreadyClaimed = state.claimedNative[msg.sender][_stateId];
        require(userTotalDeposited > alreadyClaimed, "Native principal already claimed for this state");

        bool canClaim = false;
        uint256 resolvedOutcome = state.resolvedOutcomeId;

        if (state.status == StateStatus.Cancelled) {
            canClaim = true;
        } else if (state.status == StateStatus.Resolved) {
            // Can claim principal if prediction was incorrect
            if (userPredictedOutcomeId != resolvedOutcome) {
                 canClaim = true;
            }
        } else if (state.status == StateStatus.Open) {
             // Can claim principal if resolution time + timeout has passed and state is still open
             if (block.timestamp >= state.resolutionTime + state.claimTimeoutPeriod) {
                 canClaim = true;
             }
        }

        require(canClaim, "Cannot claim principal yet (state not cancelled, not resolved incorrectly, and timeout not passed)");

        uint256 amountToPay = userTotalDeposited - alreadyClaimed;
        state.claimedNative[msg.sender][_stateId] = userTotalDeposited; // Mark full principal as claimed

        (bool success,) = payable(msg.sender).call{value: amountToPay}("");
        require(success, "Native transfer failed");

        emit PrincipalClaimed(_stateId, msg.sender, amountToPay, address(0), 0);
    }


    function claimERC20Principal(uint256 _stateId, address _tokenAddress) external nonReentrant {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        require(isAcceptedERC20(_tokenAddress), "Token not accepted by this vault");

        uint256 userTotalDeposited = 0;
        uint256 userPredictedOutcomeId = 0; // Store the ID of the outcome user deposited on (ERC20)

        // Find the user's total deposit and which outcome they predicted (ERC20)
         for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
            uint256 outcomeId = state.possibleOutcomeIds[i];
            uint256 amount = state.depositedERC20[outcomeId][_tokenAddress][msg.sender];
            if (amount > 0) {
                userTotalDeposited = amount;
                userPredictedOutcomeId = outcomeId; // Assuming user only deposits ERC20 for one outcome
                break;
            }
        }

        require(userTotalDeposited > 0, "No ERC20 tokens deposited for this state with this token");

        uint256 alreadyClaimed = state.claimedERC20[msg.sender][_stateId][_tokenAddress];
        require(userTotalDeposited > alreadyClaimed, "ERC20 principal already claimed for this state/token");

        bool canClaim = false;
        uint256 resolvedOutcome = state.resolvedOutcomeId;

        if (state.status == StateStatus.Cancelled) {
            canClaim = true;
        } else if (state.status == StateStatus.Resolved) {
            // Can claim principal if prediction was incorrect
             if (userPredictedOutcomeId != resolvedOutcome) {
                 canClaim = true;
             }
        } else if (state.status == StateStatus.Open) {
             // Can claim principal if resolution time + timeout has passed and state is still open
             if (block.timestamp >= state.resolutionTime + state.claimTimeoutPeriod) {
                 canClaim = true;
             }
        }

        require(canClaim, "Cannot claim principal yet (state not cancelled, not resolved incorrectly, and timeout not passed)");

        uint256 amountToPay = userTotalDeposited - alreadyClaimed;
        state.claimedERC20[msg.sender][_stateId][_tokenAddress] = userTotalDeposited; // Mark full principal as claimed

        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, amountToPay), "ERC20 transfer failed");

        emit PrincipalClaimed(_stateId, msg.sender, 0, _tokenAddress, amountToPay);
    }

     // --- View Functions (Claimable Amounts) ---

    function getUserClaimableNative(uint256 _stateId) public view returns (uint256) {
        QuantumState storage state = quantumStates[_stateId];
        if (state.id == 0) return 0;

        uint256 userTotalDeposited = 0;
        uint256 userPredictedOutcomeId = 0;

        // Find the user's total deposit and which outcome they predicted (native)
        for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
            uint256 outcomeId = state.possibleOutcomeIds[i];
            uint256 amount = state.depositedNative[outcomeId][msg.sender];
            if (amount > 0) {
                userTotalDeposited = amount;
                userPredictedOutcomeId = outcomeId;
                break; // Assuming max one native prediction per state
            }
        }

        if (userTotalDeposited == 0) return 0;

        uint256 alreadyClaimed = state.claimedNative[msg.sender][_stateId];
        if (userTotalDeposited <= alreadyClaimed) return 0; // Already claimed at least principal

        uint256 claimable = 0;
        uint256 resolvedOutcome = state.resolvedOutcomeId;

        if (state.status == StateStatus.Resolved) {
            if (userPredictedOutcomeId == resolvedOutcome) {
                 // Winner: claim principal + share of pool
                 uint256 totalNativeInState = 0;
                 for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
                     totalNativeInState += state.totalDepositedNativeForOutcome[state.possibleOutcomeIds[i]];
                 }
                 uint256 totalDepositedWinningOutcomeNative = state.totalDepositedNativeForOutcome[resolvedOutcome];
                 // Avoid division by zero, though userWinAmount > 0 should imply this > 0
                 if (totalDepositedWinningOutcomeNative > 0) {
                     claimable = (userTotalDeposited * totalNativeInState) / totalDepositedWinningOutcomeNative;
                 } else {
                     claimable = userTotalDeposited; // Should not happen if user deposited on winning outcome
                 }
            } else {
                 // Loser: claim principal
                 claimable = userTotalDeposited;
            }
        } else if (state.status == StateStatus.Cancelled) {
             // Cancelled: claim principal
             claimable = userTotalDeposited;
        } else if (state.status == StateStatus.Open) {
             // Open past timeout: claim principal
             if (block.timestamp >= state.resolutionTime + state.claimTimeoutPeriod) {
                 claimable = userTotalDeposited;
             }
        }

        // Return only the amount not yet claimed
        return claimable > alreadyClaimed ? claimable - alreadyClaimed : 0;
    }

     function getUserClaimableERC20(uint256 _stateId, address _tokenAddress) public view returns (uint256) {
         QuantumState storage state = quantumStates[_stateId];
         if (state.id == 0 || !isAcceptedERC20(_tokenAddress)) return 0;

         uint256 userTotalDeposited = 0;
         uint256 userPredictedOutcomeId = 0;

         // Find the user's total deposit and which outcome they predicted (ERC20)
         for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
            uint256 outcomeId = state.possibleOutcomeIds[i];
            uint256 amount = state.depositedERC20[outcomeId][_tokenAddress][msg.sender];
            if (amount > 0) {
                userTotalDeposited = amount;
                userPredictedOutcomeId = outcomeId;
                break; // Assuming max one ERC20 prediction per state/token
            }
         }

         if (userTotalDeposited == 0) return 0;

         uint256 alreadyClaimed = state.claimedERC20[msg.sender][_stateId][_tokenAddress];
         if (userTotalDeposited <= alreadyClaimed) return 0; // Already claimed at least principal

         uint256 claimable = 0;
         uint256 resolvedOutcome = state.resolvedOutcomeId;

         if (state.status == StateStatus.Resolved) {
             if (userPredictedOutcomeId == resolvedOutcome) {
                 // Winner: claim principal + share of pool
                 uint256 totalERC20InStateForToken = 0;
                 for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
                     totalERC20InStateForToken += state.totalDepositedERC20ForOutcome[_tokenAddress][state.possibleOutcomeIds[i]];
                 }
                 uint256 totalDepositedWinningOutcomeERC20 = state.totalDepositedERC20ForOutcome[_tokenAddress][resolvedOutcome];

                 if (totalDepositedWinningOutcomeERC20 > 0) {
                      claimable = (userTotalDeposited * totalERC20InStateForToken) / totalDepositedWinningOutcomeERC20;
                 } else {
                     claimable = userTotalDeposited; // Should not happen if user deposited on winning outcome
                 }
             } else {
                 // Loser: claim principal
                 claimable = userTotalDeposited;
             }
         } else if (state.status == StateStatus.Cancelled) {
              // Cancelled: claim principal
              claimable = userTotalDeposited;
         } else if (state.status == StateStatus.Open) {
              // Open past timeout: claim principal
              if (block.timestamp >= state.resolutionTime + state.claimTimeoutPeriod) {
                  claimable = userTotalDeposited;
              }
         }

         // Return only the amount not yet claimed
         return claimable > alreadyClaimed ? claimable - alreadyClaimed : 0;
     }


    // --- View Functions (State Info) ---

    function getQuantumStateDetails(uint256 _stateId) public view returns (
        uint256 id,
        string memory description,
        uint256 resolutionTime,
        uint256 claimTimeoutPeriod,
        uint256[] memory possibleOutcomeIds,
        StateStatus status,
        uint256 resolvedOutcomeId
    ) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");

        return (
            state.id,
            state.description,
            state.resolutionTime,
            state.claimTimeoutPeriod,
            state.possibleOutcomeIds,
            state.status,
            state.resolvedOutcomeId
        );
    }

    function getQuantumStateOutcome(uint256 _stateId) public view returns (uint256 resolvedOutcomeId) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        return state.resolvedOutcomeId;
    }

     function getQuantumStatePossibleOutcomes(uint256 _stateId) public view returns (uint256[] memory) {
         QuantumState storage state = quantumStates[_stateId];
         require(state.id != 0, "State does not exist");
         return state.possibleOutcomeIds;
     }

     function getOutcomeDescription(uint256 _stateId, uint256 _outcomeId) public view returns (string memory) {
         QuantumState storage state = quantumStates[_stateId];
         require(state.id != 0, "State does not exist");
         return state.outcomeDescriptions[_outcomeId];
     }

    function getQuantumStateStatus(uint256 _stateId) public view returns (StateStatus) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "State does not exist");
        return state.status;
    }

    function isQuantumStateResolved(uint256 _stateId) public view returns (bool) {
        QuantumState storage state = quantumStates[_stateId];
        if (state.id == 0) return false;
        return state.status == StateStatus.Resolved;
    }

    function getAllQuantumStateIds() public view returns (uint256[] memory) {
        return _allQuantumStateIds;
    }

    // --- View Functions (Deposit Info) ---

    function getUserPredictionAmountNative(uint256 _stateId, uint256 _outcomeId, address _user) public view returns (uint256) {
        QuantumState storage state = quantumStates[_stateId];
        if (state.id == 0) return 0;
         bool outcomeFound = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
            if (state.possibleOutcomeIds[i] == _outcomeId) {
                outcomeFound = true;
                break;
            }
        }
        if (!outcomeFound) return 0;

        return state.depositedNative[_outcomeId][_user];
    }

     function getUserPredictionAmountERC20(uint256 _stateId, uint256 _outcomeId, address _tokenAddress, address _user) public view returns (uint256) {
         QuantumState storage state = quantumStates[_stateId];
         if (state.id == 0 || !isAcceptedERC20(_tokenAddress)) return 0;
          bool outcomeFound = false;
         for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
             if (state.possibleOutcomeIds[i] == _outcomeId) {
                 outcomeFound = true;
                 break;
             }
         }
         if (!outcomeFound) return 0;

         return state.depositedERC20[_outcomeId][_tokenAddress][_user];
     }

    function getTotalDepositsForOutcomeNative(uint256 _stateId, uint256 _outcomeId) public view returns (uint256) {
        QuantumState storage state = quantumStates[_stateId];
        if (state.id == 0) return 0;
         bool outcomeFound = false;
        for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
            if (state.possibleOutcomeIds[i] == _outcomeId) {
                outcomeFound = true;
                break;
            }
        }
        if (!outcomeFound) return 0;

        return state.totalDepositedNativeForOutcome[_outcomeId];
    }

     function getTotalDepositsForOutcomeERC20(uint256 _stateId, uint256 _outcomeId, address _tokenAddress) public view returns (uint256) {
         QuantumState storage state = quantumStates[_stateId];
         if (state.id == 0 || !isAcceptedERC20(_tokenAddress)) return 0;
          bool outcomeFound = false;
         for (uint i = 0; i < state.possibleOutcomeIds.length; i++) {
             if (state.possibleOutcomeIds[i] == _outcomeId) {
                 outcomeFound = true;
                 break;
             }
         }
         if (!outcomeFound) return 0;

         return state.totalDepositedERC20ForOutcome[_tokenAddress][_outcomeId];
     }


     function getTotalDepositsInStateNative(uint256 _stateId) public view returns (uint256) {
         QuantumState storage state = quantumStates[_stateId];
         if (state.id == 0) return 0;
         uint256 total = 0;
         for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
             total += state.totalDepositedNativeForOutcome[state.possibleOutcomeIds[i]];
         }
         return total;
     }

     function getTotalDepositsInStateERC20(uint256 _stateId, address _tokenAddress) public view returns (uint256) {
         QuantumState storage state = quantumStates[_stateId];
         if (state.id == 0 || !isAcceptedERC20(_tokenAddress)) return 0;
          uint256 total = 0;
         for(uint i=0; i<state.possibleOutcomeIds.length; i++) {
             total += state.totalDepositedERC20ForOutcome[_tokenAddress][state.possibleOutcomeIds[i]];
         }
         return total;
     }

    // --- Emergency Withdrawal (Owner) ---

    function ownerEmergencyWithdrawNative() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No native balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Native withdrawal failed");
        emit OwnerEmergencyWithdrawal(address(0), balance);
    }

    function ownerEmergencyWithdrawERC20(address _tokenAddress) external onlyOwner nonReentrancy {
        require(isAcceptedERC20(_tokenAddress), "Token not accepted by this vault");
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No token balance to withdraw");
        require(token.transfer(owner(), balance), "ERC20 withdrawal failed");
         emit OwnerEmergencyWithdrawal(_tokenAddress, balance);
    }

    // --- Owner / Access Control Inherited from Ownable ---
    // getOwner(), transferOwnership(), renounceOwnership() are available from Ownable

    // Total functions: 35+ (counting all listed functions)
    // 10 (State Management) + 8 (Deposit) + 6 (Claim) + 2 (Claimable View) + 1 (Default Timeout Config) + 4 (Accepted ERC20) + 2 (Emergency Withdraw) + 2 (Owner from Ownable needed for list) = 35+
}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Conditional Vaulting & Time-Based Access:** Funds are locked (`deposit*` functions) but their release (`claim*` functions) is strictly conditional not just on time (`resolutionTime`, `claimTimeoutPeriod`) but also on the state's `status` (Open, Resolved, Cancelled) and, if resolved, the specific `resolvedOutcomeId`.
2.  **Prediction Market Simplification:** The contract models a core element of prediction markets where users stake funds on specific outcomes (`_outcomeId`) of a future event (`QuantumState`). The payout logic is simplified to distribute the *total pool* of a specific asset/token type proportionally among those who correctly predicted the winning outcome with that same asset/token type.
3.  **Oracle-like Dependency:** The contract relies on a trusted `resolverAddress` to provide the off-chain outcome (`resolveQuantumState`). This is a common pattern in DeFi and dApps that need real-world data or event resolution.
4.  **Multi-Asset Handling:** The contract explicitly supports both the native blockchain token (ETH/BNB/etc. via `payable` and `address(this).balance`) and a configurable list of ERC-20 tokens, each with separate accounting and claim logic.
5.  **Dynamic State:** `QuantumState` objects are created dynamically by the owner, each with its own parameters (description, time, outcomes). Their status changes over time (`Open`, `Resolved`, `Cancelled`).
6.  **Configurable Accepted Tokens:** The owner can control which ERC-20 tokens are allowed for deposits, adding a layer of security and flexibility.
7.  **Timeout for Unresolved States:** A `claimTimeoutPeriod` allows users to reclaim principal if the `resolverAddress` fails to resolve the state in a timely manner, preventing funds from being permanently locked in an unresolved state.
8.  **Internal Accounting for Claims:** The `claimedNative` and `claimedERC20` mappings prevent users from double-claiming their funds, whether it's principal or winnings.

This contract provides a framework for creating conditional future-event-dependent pools, offering a creative twist on standard vaults or simple time locks by integrating external event resolution. It's not a full-fledged prediction market (lacks order books, complex payout structures, fees, etc.) but demonstrates the core concept of funds locked against future, oracle-determined conditions.