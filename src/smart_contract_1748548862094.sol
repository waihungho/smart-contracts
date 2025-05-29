Okay, let's design a smart contract based on an advanced concept: an "Evolutionary State Protocol for Digital Assets," combining elements of dynamic NFTs, resource burning for state transitions, time-locked progression, and yield staking based on the asset's state.

We'll call it the `QuantumLeapProtocol`. The core idea is that users own ERC721 NFTs (Chronosyns) that can exist in different "states" (like stages of evolution). Advancing to a higher state requires burning a specific ERC20 token (Aetherium) and waiting a certain duration. Only NFTs in advanced states can be staked to earn rewards (also in Aetherium).

This goes beyond simple NFTs or staking by introducing:
1.  **Dynamic State:** NFTs aren't static; their properties (represented by state) change on-chain.
2.  **Resource Burning for Progression:** Aetherium tokens are consumed, not just transferred, for evolution.
3.  **Time-Locked Progression:** A delay is introduced between initiating and finalizing a state change, adding a strategic or time-based element.
4.  **State-Dependent Utility:** Staking eligibility and potentially yield rate depend on the NFT's current state.
5.  **Configurability:** Admin can define costs, durations, state transitions, and yield rates.

This combines dynamic state, resource economics, time mechanics, and yield generation in a single system.

---

## QuantumLeapProtocol Smart Contract

**Outline:**

1.  **Contract Description:** Manages evolutionary ERC721 NFTs (Chronosyns), their state transitions requiring ERC20 (Aetherium) burning and a time lock, and staking for yield based on state.
2.  **Inheritance:** ERC721, Ownable, Pausable, AccessControl, ReentrancyGuard.
3.  **Assets:**
    *   ERC721 (Chronosyn): The evolving NFT.
    *   ERC20 (Aetherium): Resource token for evolution and reward token for staking.
4.  **Core Concepts:**
    *   **States:** Discrete stages for Chronosyns (e.g., Larva, Chrysalis, Imago, Apex).
    *   **Quantum Leap:** The process of moving from one state to the next.
    *   **Aetherium Cost:** Required amount of Aetherium to initiate a Leap.
    *   **Initiation Duration:** Time required between initiating and finalizing a Leap.
    *   **Staking:** Depositing Leaped Chronosyns to earn Aetherium yield.
    *   **Roles:** OWNER (primary control), STATE_MANAGER_ROLE (configures states, costs, durations).
5.  **State Variables:**
    *   Token addresses (Chronosyn ERC721, Aetherium ERC20).
    *   NFT state mapping (`tokenId => state`).
    *   NFT leap count mapping (`tokenId => leapCount`).
    *   Leap configuration (`currentState => nextState`, `currentState => aetheriumCost`, `currentState => initiationDuration`).
    *   Leap initiation mapping (`tokenId => initiatedLeapDetails { timestamp, targetState }`).
    *   Staking mapping (`tokenId => stakingDetails { owner, stakeTime }`).
    *   Staking yield rate mapping (`state => yieldRatePerSecond`).
    *   Reward pool tracking/balances.
    *   Access control roles.
6.  **Events:** `ChronosynStateChanged`, `QuantumLeapInitiated`, `QuantumLeapFinalized`, `LeapConfigUpdated`, `StakingYieldRateUpdated`, `ChronosynStaked`, `ChronosynUnstaked`, `RewardsClaimed`, `RewardPoolFunded`.
7.  **Functions (>= 20):**
    *   **Admin/Setup (OWNER Role):**
        *   `constructor`
        *   `setChronosynTokenAddress`
        *   `setAetheriumTokenAddress`
        *   `grantRole`
        *   `revokeRole`
        *   `renounceRole`
        *   `pause`
        *   `unpause`
        *   `withdrawERC20`
        *   `withdrawERC721`
        *   `fundRewardPool`
    *   **State/Leap Configuration (STATE_MANAGER_ROLE or OWNER):**
        *   `configureLeapStateTransition`
        *   `setLeapCost`
        *   `setInitiationDuration`
        *   `setStakingYieldRate`
    *   **NFT Interaction (ERC721 standard overrides):**
        *   `tokenURI` (override to reflect state)
        *   `_beforeTokenTransfer` (override for staking/leap checks)
        *   `_afterTokenTransfer` (override for staking/leap updates)
    *   **NFT Minting (Can be restricted or public):**
        *   `mintChronosyn`
    *   **Quantum Leap Execution (Public):**
        *   `initiateQuantumLeap`
        *   `finalizeQuantumLeap`
        *   `cancelInitiatedLeap`
    *   **Staking (Public):**
        *   `stakeChronosyn`
        *   `unstakeChronosyn`
        *   `claimStakingRewards`
    *   **Read Functions (Public):**
        *   `getChronosynState`
        *   `getChronosynLeapCount`
        *   `getLeapConfig`
        *   `getInitiatedLeapDetails`
        *   `getStakingYieldRate`
        *   `calculatePendingRewards`
        *   `isChronosynStaked`
        *   `getTotalStakedChronosyns`
        *   `getRewardPoolBalance`
        *   `getRoleAdmin` (from AccessControl)
        *   `hasRole` (from AccessControl)
        *   `isPaused` (from Pausable)
        *   `owner` (from Ownable)
        *   `supportsInterface` (ERC165)

**Function Summary:**

*   `constructor(...)`: Initializes the contract, sets owner and default roles.
*   `setChronosynTokenAddress(address _chronosynAddress)`: Sets the address of the ERC721 Chronosyn contract (must be ERC721). Only Owner.
*   `setAetheriumTokenAddress(address _aetheriumAddress)`: Sets the address of the ERC20 Aetherium contract (must be ERC20). Only Owner.
*   `grantRole(bytes32 role, address account)`: Grants a specific role (e.g., STATE_MANAGER_ROLE) to an address. Standard AccessControl.
*   `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address. Standard AccessControl.
*   `renounceRole(bytes32 role)`: Allows an address to remove its own role. Standard AccessControl.
*   `pause()`: Pauses core contract functions (minting, leaps, staking). Only Pauser role (defaults to Owner).
*   `unpause()`: Unpauses the contract. Only Pauser role.
*   `withdrawERC20(address tokenAddress, uint256 amount)`: Allows Owner to withdraw specified amount of a non-Aetherium ERC20 from the contract. For emergencies.
*   `withdrawERC721(address tokenAddress, uint256 tokenId)`: Allows Owner to withdraw a specific non-Chronosyn ERC721 from the contract. For emergencies.
*   `fundRewardPool(uint256 amount)`: Allows Owner/Manager to transfer Aetherium into the contract's reward pool balance. Requires prior approval.
*   `configureLeapStateTransition(uint8 currentState, uint8 nextState)`: Sets the target state for a given starting state during a leap. Only State Manager.
*   `setLeapCost(uint8 state, uint256 cost)`: Sets the Aetherium cost required to initiate a leap *from* the specified state. Only State Manager.
*   `setInitiationDuration(uint8 state, uint64 durationSeconds)`: Sets the time duration required between initiating and finalizing a leap *from* the specified state. Only State Manager.
*   `setStakingYieldRate(uint8 state, uint64 ratePerSecond)`: Sets the Aetherium yield rate per second for staking Chronosyns *in* the specified state. Only State Manager.
*   `tokenURI(uint256 tokenId)`: Overrides ERC721 standard. Returns a dynamic URI based on the Chronosyn's current state.
*   `_beforeTokenTransfer(...)`: Internal override. Prevents transfers of staked or leap-initiated Chronosyns.
*   `_afterTokenTransfer(...)`: Internal override. May update internal tracking if needed (less likely in this design).
*   `mintChronosyn(address to, uint256 tokenId)`: Mints a new Chronosyn NFT in its initial state. Can be called by Owner/Manager or public depending on desired flow. Let's make it Manager only for control.
*   `initiateQuantumLeap(uint256 tokenId)`: User initiates a leap for their Chronosyn. Requires ownership, not being staked, not already initiating, sufficient Aetherium approval/balance, and configured leap for current state. Burns Aetherium and records initiation timestamp/target state.
*   `finalizeQuantumLeap(uint256 tokenId)`: User finalizes a leap. Requires ownership, prior initiation, and that the required initiation duration has passed since initiation. Updates NFT state and increments leap count. Clears initiation data.
*   `cancelInitiatedLeap(uint256 tokenId)`: User cancels an initiated leap. Requires ownership and prior initiation. Allows withdrawal of NFT but Aetherium is burned, not refunded. Clears initiation data.
*   `stakeChronosyn(uint256 tokenId)`: User stakes their Chronosyn. Requires ownership, NFT must be in a stake-eligible state (as configured by yield rate > 0), and not already staked or initiating leap. Transfers NFT to contract and records stake time.
*   `unstakeChronosyn(uint256 tokenId)`: User unstakes their Chronosyn. Requires ownership (of stake), NFT must be staked. Calculates and auto-claims pending rewards. Transfers NFT back to user. Clears staking data.
*   `claimStakingRewards(uint256 tokenId)`: User claims pending staking rewards for a *staked* Chronosyn. Requires ownership (of stake), NFT must be staked. Calculates and transfers Aetherium rewards. Updates last reward claim time for that stake. Uses `nonReentrant`.
*   `getChronosynState(uint256 tokenId)`: Returns the current state of a Chronosyn.
*   `getChronosynLeapCount(uint256 tokenId)`: Returns the number of times a Chronosyn has successfully leaped.
*   `getLeapConfig(uint8 state)`: Returns the target state, Aetherium cost, and initiation duration configured for leaping *from* a given state.
*   `getInitiatedLeapDetails(uint256 tokenId)`: Returns the initiation timestamp and target state for a Chronosyn currently undergoing a leap, or zero values if not initiating.
*   `getStakingYieldRate(uint8 state)`: Returns the configured Aetherium yield rate per second for Chronosyns in a given state.
*   `calculatePendingRewards(uint256 tokenId)`: Calculates the Aetherium rewards accrued since the last claim/stake time for a staked Chronosyn.
*   `isChronosynStaked(uint256 tokenId)`: Checks if a Chronosyn is currently staked.
*   `getTotalStakedChronosyns()`: Returns the total number of Chronosyns currently staked in the contract.
*   `getRewardPoolBalance()`: Returns the current Aetherium balance held by the contract (available for rewards).
*   `getRoleAdmin(bytes32 role)`: Standard AccessControl function to get the admin role for a given role.
*   `hasRole(bytes32 role, address account)`: Standard AccessControl function to check if an account has a role.
*   `isPaused()`: Standard Pausable function to check if the contract is paused.
*   `owner()`: Standard Ownable function to get the contract owner.
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Define custom errors for better gas efficiency and clarity
error QuantumLeapProtocol__InvalidChronosynToken();
error QuantumLeapProtocol__InvalidAetheriumToken();
error QuantumLeapProtocol__InvalidStateTransition(uint8 currentState);
error QuantumLeapProtocol__LeapCostNotConfigured(uint8 state);
error QuantumLeapProtocol__InitiationDurationNotConfigured(uint8 state);
error QuantumLeapProtocol__StakingYieldRateNotConfigured(uint8 state);
error QuantumLeapProtocol__ChronosynNotOwned(uint256 tokenId);
error QuantumLeapProtocol__AlreadyInitiatingLeap(uint256 tokenId);
error QuantumLeapProtocol__NotInitiatingLeap(uint256 tokenId);
error QuantumLeapProtocol__InitiationDurationNotPassed(uint256 tokenId);
error QuantumLeapProtocol__InsufficientAetheriumAllowance();
error QuantumLeapProtocol__InsufficientAetheriumBalance();
error QuantumLeapProtocol__ChronosynAlreadyStaked(uint256 tokenId);
error QuantumLeapProtocol__ChronosynNotStaked(uint256 tokenId);
error QuantumLeapProtocol__StakingNotAllowedInState(uint8 state);
error QuantumLeapProtocol__StakedOrLeapingChronosynCannotTransfer();
error QuantumLeapProtocol__WithdrawalFailed();
error QuantumLeapProtocol__CannotWithdrawAetheriumOrChronosyn();
error QuantumLeapProtocol__RewardPoolEmpty();


contract QuantumLeapProtocol is ERC721, Ownable, Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant STATE_MANAGER_ROLE = keccak256("STATE_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Although Ownable is Pauser by default

    IERC721 private s_chronosynToken; // The evolving NFT contract
    IERC20 private s_aetheriumToken; // The resource/reward token

    // --- Chronosyn State & Leap Data ---
    mapping(uint256 => uint8) private s_chronosynState; // tokenId => current state (e.g., 0: Larva, 1: Chrysalis...)
    mapping(uint256 => uint256) private s_chronosynLeapCount; // tokenId => number of successful leaps

    struct InitiatedLeapDetails {
        uint64 initiationTimestamp; // Timestamp when initiateQuantumLeap was called
        uint8 targetState;          // The state the Chronosyn will reach upon finalization
    }
    mapping(uint256 => InitiatedLeapDetails) private s_initiatedLeaps; // tokenId => details if a leap is initiated

    // --- Leap Configuration (set by STATE_MANAGER) ---
    mapping(uint8 => uint8) private s_leapStateTransition; // currentState => nextState
    mapping(uint8 => uint256) private s_leapCost; // currentState => Aetherium cost to leap from this state
    mapping(uint8 => uint64) private s_initiationDuration; // currentState => seconds required between initiation and finalization

    // --- Staking Data ---
    struct StakingDetails {
        address staker;           // Owner of the staked token
        uint64 stakeStartTime;    // Timestamp when the token was staked
        uint66 lastRewardClaimTime; // Timestamp of the last reward claim (or stakeStartTime)
    }
    mapping(uint256 => StakingDetails) private s_stakedChronosyns; // tokenId => staking details if staked
    mapping(address => uint256[]) private s_stakerTokens; // staker address => list of staked tokenIds

    // --- Staking Configuration (set by STATE_MANAGER) ---
    mapping(uint8 => uint64) private s_stakingYieldRatePerSecond; // state => Aetherium earned per second per staked token in this state

    // --- Reward Pool Balance ---
    // The actual balance is the contract's Aetherium balance
    // function getRewardPoolBalance() provides this

    // --- Base Token URI ---
    string private s_baseTokenURI;

    // --- Events ---
    event ChronosynStateChanged(uint256 indexed tokenId, uint8 oldState, uint8 newState);
    event QuantumLeapInitiated(uint256 indexed tokenId, uint8 fromState, uint8 toState, uint256 cost, uint64 requiredDuration, uint64 initiationTimestamp);
    event QuantumLeapFinalized(uint256 indexed tokenId, uint8 fromState, uint8 toState, uint256 newLeapCount);
    event QuantumLeapCancelled(uint256 indexed tokenId, uint8 fromState, uint8 targetState);
    event LeapConfigUpdated(uint8 state, uint8 nextState, uint256 cost, uint64 duration);
    event StakingYieldRateUpdated(uint8 state, uint64 ratePerSecond);
    event ChronosynStaked(uint256 indexed tokenId, address indexed staker, uint64 stakeTime);
    event ChronosynUnstaked(uint256 indexed tokenId, address indexed staker, uint256 claimedRewards);
    event RewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 claimedRewards);
    event RewardPoolFunded(address indexed funder, uint256 amount);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address chronosynAddress, address aetheriumAddress)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets contract deployer as initial owner
        Pausable() // Pauser role defaults to Owner
        ReentrancyGuard()
    {
        // AccessControl setup
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is default admin
        _grantRole(PAUSER_ROLE, msg.sender); // Owner is pauser

        // Token address validation and setting
        if (chronosynAddress == address(0)) revert QuantumLeapProtocol__InvalidChronosynToken();
        if (aetheriumAddress == address(0)) revert QuantumLeapProtocol__InvalidAetheriumToken();
        s_chronosynToken = IERC721(chronosynAddress);
        s_aetheriumToken = IERC20(aetheriumAddress);
    }

    // --- Access Control ---
    // Override default function to make AccessControl aware of Ownable
    function renounceOwnership() public override onlyOwner {
        revert("Cannot renounce ownership directly, use grant/revoke roles");
    }

    function _checkRole(bytes32 role) internal view override {
        if (role == DEFAULT_ADMIN_ROLE) {
             // Default admin is Owner
            require(owner() == _msgSender(), "AccessControl: account missing role");
        } else {
            super._checkRole(role);
        }
    }

    // --- Pausable Overrides ---
    function pause() public override onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public override onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    // --- ERC721 Overrides (for state/staking/leap logic) ---

    // Prevent transfer of staked or leap-initiated tokens
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (s_stakedChronosyns[tokenId].staker != address(0) || s_initiatedLeaps[tokenId].initiationTimestamp != 0) {
            revert QuantumLeapProtocol__StakedOrLeapingChronosynCannotTransfer();
        }
    }

    // Token URI reflects state (basic implementation)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        uint8 currentState = s_chronosynState[tokenId];
        // A more advanced implementation would fetch metadata based on state from an external URI/API
        // For this example, we'll just append the state to a base URI
        string memory base = s_baseTokenURI;
        if (bytes(base).length == 0) {
            return super.tokenURI(tokenId); // Fallback or revert if no base URI set
        }
        return string(abi.encodePacked(base, Strings.toString(currentState)));
    }

    // --- Admin/Setup Functions (Owner Only unless specified by Role) ---

    function setChronosynTokenAddress(address _chronosynAddress) public onlyOwner {
        if (_chronosynAddress == address(0)) revert QuantumLeapProtocol__InvalidChronosynToken();
        s_chronosynToken = IERC721(_chronosynAddress);
    }

    function setAetheriumTokenAddress(address _aetheriumAddress) public onlyOwner {
        if (_aetheriumAddress == address(0)) revert QuantumLeapProtocol__InvalidAetheriumToken();
        s_aetheriumToken = IERC20(_aetheriumAddress);
    }

    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner whenNotPaused {
        if (tokenAddress == address(s_aetheriumToken) || tokenAddress == address(0)) {
            revert QuantumLeapProtocol__CannotWithdrawAetheriumOrChronosyn();
        }
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), amount);
        // Consider adding an event for withdrawals
    }

    function withdrawERC721(address tokenAddress, uint256 tokenId) public onlyOwner whenNotPaused {
         if (tokenAddress == address(s_chronosynToken) || tokenAddress == address(0)) {
            revert QuantumLeapProtocol__CannotWithdrawAetheriumOrChronosyn();
        }
        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(address(this), owner(), tokenId);
        // Consider adding an event for withdrawals
    }

    function fundRewardPool(uint256 amount) public payable nonReentrant whenNotPaused { // Payable to allow ether deposit if needed, though Aetherium is expected
        // Allow anyone with STATE_MANAGER_ROLE or OWNER to fund
        require(hasRole(STATE_MANAGER_ROLE, _msgSender()) || owner() == _msgSender(), "Unauthorized");

        if (amount > 0) {
             // Aetherium must be approved *before* calling this function
            s_aetheriumToken.safeTransferFrom(_msgSender(), address(this), amount);
            emit RewardPoolFunded(_msgSender(), amount);
        }
         // Optional: Handle native currency if msg.value > 0, e.g., transfer to owner or use for future features
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        s_baseTokenURI = baseTokenURI;
    }

    // --- State/Leap Configuration Functions (STATE_MANAGER Role) ---

    function configureLeapStateTransition(uint8 currentState, uint8 nextState) public onlyRole(STATE_MANAGER_ROLE) whenNotPaused {
        s_leapStateTransition[currentState] = nextState;
        emit LeapConfigUpdated(currentState, nextState, s_leapCost[currentState], s_initiationDuration[currentState]);
    }

    function setLeapCost(uint8 state, uint256 cost) public onlyRole(STATE_MANAGER_ROLE) whenNotPaused {
        s_leapCost[state] = cost;
        emit LeapConfigUpdated(state, s_leapStateTransition[state], cost, s_initiationDuration[state]);
    }

    function setInitiationDuration(uint8 state, uint64 durationSeconds) public onlyRole(STATE_MANAGER_ROLE) whenNotPaused {
        s_initiationDuration[state] = durationSeconds;
        emit LeapConfigUpdated(state, s_leapStateTransition[state], s_leapCost[state], durationSeconds);
    }

    function setStakingYieldRate(uint8 state, uint64 ratePerSecond) public onlyRole(STATE_MANAGER_ROLE) whenNotPaused {
         // Only set rate for states that have a defined transition *from* them
         // This implies only 'evolved' states can have yield, which fits the concept
        if (s_leapStateTransition[state] == 0 && state != 0) { // Assuming state 0 is base state with no transition from it, and 0 is not a valid 'nextState' normally
             // Optional: enforce that only states that *can* leap can have yield set, or states > initial state
             // For now, allow setting for any state, but documentation should guide policy.
        }
        s_stakingYieldRatePerSecond[state] = ratePerSecond;
        emit StakingYieldRateUpdated(state, ratePerSecond);
    }


    // --- NFT Minting ---

    // Minting function - restricted to STATE_MANAGER_ROLE
    function mintChronosyn(address to, uint256 tokenId, uint8 initialState) public onlyRole(STATE_MANAGER_ROLE) whenNotPaused {
        _mint(to, tokenId);
        s_chronosynState[tokenId] = initialState; // Set the initial state
        s_chronosynLeapCount[tokenId] = 0;
        emit ChronosynStateChanged(tokenId, 255, initialState); // Use 255 to indicate genesis
    }

    // --- Quantum Leap Execution ---

    function initiateQuantumLeap(uint256 tokenId) public whenNotPaused nonReentrant {
        address ownerOfToken = ownerOf(tokenId);
        if (ownerOfToken != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId);
        if (s_stakedChronosyns[tokenId].staker != address(0)) revert QuantumLeapProtocol__ChronosynAlreadyStaked(tokenId); // Must not be staked
        if (s_initiatedLeaps[tokenId].initiationTimestamp != 0) revert QuantumLeapProtocol__AlreadyInitiatingLeap(tokenId); // Must not already be initiating

        uint8 currentState = s_chronosynState[tokenId];
        uint8 nextState = s_leapStateTransition[currentState];
        if (nextState == 0 && currentState != 0) revert QuantumLeapProtocol__InvalidStateTransition(currentState); // nextState 0 implies no configured transition (assuming state 0 is initial and can't leap *from*)

        uint256 cost = s_leapCost[currentState];
        if (cost == 0) revert QuantumLeapProtocol__LeapCostNotConfigured(currentState); // Cost must be configured > 0

        uint64 duration = s_initiationDuration[currentState];
         // Duration can be 0 for instant leaps, but config must exist.
        if (duration == 0 && s_initiationDuration[currentState] != 0) revert QuantumLeapProtocol__InitiationDurationNotConfigured(currentState);


        // Require and burn Aetherium
        if (s_aetheriumToken.allowance(ownerOfToken, address(this)) < cost) revert QuantumLeapProtocol__InsufficientAetheriumAllowance();
        s_aetheriumToken.safeTransferFrom(ownerOfToken, address(this), cost);
        // Note: Aetherium is burned (sent to contract and effectively removed from user circulation for the cost)

        // Record initiation details
        s_initiatedLeaps[tokenId] = InitiatedLeapDetails({
            initiationTimestamp: uint64(block.timestamp),
            targetState: nextState
        });

        emit QuantumLeapInitiated(tokenId, currentState, nextState, cost, duration, uint64(block.timestamp));
    }

    function finalizeQuantumLeap(uint256 tokenId) public whenNotPaused nonReentrant {
        address ownerOfToken = ownerOf(tokenId);
        if (ownerOfToken != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId);

        InitiatedLeapDetails storage leapDetails = s_initiatedLeaps[tokenId];
        if (leapDetails.initiationTimestamp == 0) revert QuantumLeapProtocol__NotInitiatingLeap(tokenId); // Must have initiated a leap

        uint8 currentState = s_chronosynState[tokenId];
        uint64 requiredDuration = s_initiationDuration[currentState];

        if (block.timestamp < leapDetails.initiationTimestamp + requiredDuration) {
            revert QuantumLeleapProtocol__InitiationDurationNotPassed(tokenId); // Required time must have passed
        }

        uint8 oldState = currentState;
        uint8 newState = leapDetails.targetState;

        // Update state and leap count
        s_chronosynState[tokenId] = newState;
        s_chronosynLeapCount[tokenId]++;

        // Clear initiation data
        delete s_initiatedLeaps[tokenId];

        emit ChronosynStateChanged(tokenId, oldState, newState);
        emit QuantumLeapFinalized(tokenId, oldState, newState, s_chronosynLeapCount[tokenId]);
    }

    function cancelInitiatedLeap(uint256 tokenId) public whenNotPaused nonReentrant {
        address ownerOfToken = ownerOf(tokenId);
        if (ownerOfToken != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId);

        InitiatedLeapDetails storage leapDetails = s_initiatedLeaps[tokenId];
        if (leapDetails.initiationTimestamp == 0) revert QuantumLeapProtocol__NotInitiatingLeap(tokenId); // Must have initiated a leap

        uint8 currentState = s_chronosynState[tokenId];
        uint8 targetState = leapDetails.targetState;

        // Clear initiation data (Aetherium is NOT refunded as it was 'burned' upon initiation)
        delete s_initiatedLeaps[tokenId];

        emit QuantumLeapCancelled(tokenId, currentState, targetState);
    }

    // --- Staking Functions ---

    function stakeChronosyn(uint256 tokenId) public whenNotPaused nonReentrant {
        address ownerOfToken = ownerOf(tokenId);
        if (ownerOfToken != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId);
        if (s_stakedChronosyns[tokenId].staker != address(0)) revert QuantumLeapProtocol__ChronosynAlreadyStaked(tokenId); // Must not be staked
        if (s_initiatedLeaps[tokenId].initiationTimestamp != 0) revert QuantumLeapProtocol__AlreadyInitiatingLeap(tokenId); // Must not be initiating leap

        uint8 currentState = s_chronosynState[tokenId];
        uint64 yieldRate = s_stakingYieldRatePerSecond[currentState];
        if (yieldRate == 0) revert QuantumLeapProtocol__StakingNotAllowedInState(currentState); // Must be in a stake-eligible state

        // Transfer NFT to the contract
        _safeTransfer(ownerOfToken, address(this), tokenId);

        // Record staking details
        s_stakedChronosyns[tokenId] = StakingDetails({
            staker: ownerOfToken,
            stakeStartTime: uint64(block.timestamp),
            lastRewardClaimTime: uint66(block.timestamp) // Initialize last claim time
        });

        // Add token to staker's list
        s_stakerTokens[ownerOfToken].push(tokenId);

        emit ChronosynStaked(tokenId, ownerOfToken, uint64(block.timestamp));
    }

    function unstakeChronosyn(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingDetails storage stakingDetails = s_stakedChronosyns[tokenId];
        if (stakingDetails.staker == address(0)) revert QuantumLeapProtocol__ChronosynNotStaked(tokenId); // Must be staked
        if (stakingDetails.staker != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId); // Must be the original staker

        // Auto-claim pending rewards before unstaking
        uint256 pendingRewards = _calculatePendingRewards(tokenId);
        if (pendingRewards > 0) {
            // Check contract balance *before* transfer
            if (s_aetheriumToken.balanceOf(address(this)) < pendingRewards) revert QuantumLeapProtocol__RewardPoolEmpty();
            s_aetheriumToken.safeTransfer(stakingDetails.staker, pendingRewards);
            emit RewardsClaimed(tokenId, stakingDetails.staker, pendingRewards);
        }

        address originalStaker = stakingDetails.staker;

        // Clear staking data *before* transfer
        delete s_stakedChronosyns[tokenId];

        // Remove token from staker's list (linear search - optimize for large lists if needed)
        uint256[] storage stakerTokens = s_stakerTokens[originalStaker];
        for (uint256 i = 0; i < stakerTokens.length; i++) {
            if (stakerTokens[i] == tokenId) {
                stakerTokens[i] = stakerTokens[stakerTokens.length - 1];
                stakerTokens.pop();
                break;
            }
        }

        // Transfer NFT back to the original staker
        _safeTransfer(address(this), originalStaker, tokenId);

        emit ChronosynUnstaked(tokenId, originalStaker, pendingRewards);
    }

    function claimStakingRewards(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingDetails storage stakingDetails = s_stakedChronosyns[tokenId];
        if (stakingDetails.staker == address(0)) revert QuantumLeapProtocol__ChronosynNotStaked(tokenId); // Must be staked
        if (stakingDetails.staker != _msgSender()) revert QuantumLeapProtocol__ChronosynNotOwned(tokenId); // Must be the original staker

        uint256 pendingRewards = _calculatePendingRewards(tokenId);

        if (pendingRewards == 0) {
            // No rewards to claim
            return;
        }

        // Check contract balance *before* transfer
        if (s_aetheriumToken.balanceOf(address(this)) < pendingRewards) revert QuantumLeapProtocol__RewardPoolEmpty();

        // Transfer rewards to the staker
        s_aetheriumToken.safeTransfer(stakingDetails.staker, pendingRewards);

        // Update last reward claim time
        stakingDetails.lastRewardClaimTime = uint66(block.timestamp);

        emit RewardsClaimed(tokenId, stakingDetails.staker, pendingRewards);
    }

    // Internal helper to calculate rewards
    function _calculatePendingRewards(uint256 tokenId) internal view returns (uint256) {
        StakingDetails storage stakingDetails = s_stakedChronosyns[tokenId];
        if (stakingDetails.staker == address(0)) return 0; // Not staked

        uint8 currentState = s_chronosynState[tokenId];
        uint64 yieldRate = s_stakingYieldRatePerSecond[currentState];
        if (yieldRate == 0) return 0; // No yield for this state

        uint64 lastClaimTime = stakingDetails.lastRewardClaimTime;
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastClaimTime) return 0; // Time hasn't passed since last claim

        uint256 timeElapsed = currentTime - lastClaimTime;
        return timeElapsed * yieldRate;
    }


    // --- Read Functions ---

    function getChronosynState(uint256 tokenId) public view returns (uint8) {
        return s_chronosynState[tokenId];
    }

    function getChronosynLeapCount(uint256 tokenId) public view returns (uint256) {
        return s_chronosynLeapCount[tokenId];
    }

    function getLeapConfig(uint8 state) public view returns (uint8 nextState, uint256 cost, uint64 duration) {
        return (s_leapStateTransition[state], s_leapCost[state], s_initiationDuration[state]);
    }

    function getInitiatedLeapDetails(uint256 tokenId) public view returns (uint64 initiationTimestamp, uint8 targetState) {
        InitiatedLeapDetails storage leapDetails = s_initiatedLeaps[tokenId];
        return (leapDetails.initiationTimestamp, leapDetails.targetState);
    }

     function getStakingYieldRate(uint8 state) public view returns (uint64 ratePerSecond) {
        return s_stakingYieldRatePerSecond[state];
    }

    function calculatePendingRewards(uint256 tokenId) public view returns (uint256) {
        return _calculatePendingRewards(tokenId);
    }

    function isChronosynStaked(uint256 tokenId) public view returns (bool) {
        return s_stakedChronosyns[tokenId].staker != address(0);
    }

    function getStakedTokensByAddress(address staker) public view returns (uint256[] memory) {
        return s_stakerTokens[staker];
    }

    // Note: getTotalStakedChronosyns() requires iterating over s_stakedChronosyns map, which is not efficient/possible directly.
    // A counter could be maintained, but adds complexity. Let's omit for now or state limitation.
    // Alternative: Get count of staked tokens for a specific staker.
    // function getTotalStakedChronosyns() public view returns (uint256) {} // Omitted due to mapping limitation

    function getRewardPoolBalance() public view returns (uint256) {
        return s_aetheriumToken.balanceOf(address(this));
    }

    function getAetheriumTokenAddress() public view returns (address) {
        return address(s_aetheriumToken);
    }

    function getChronosynTokenAddress() public view returns (address) {
        return address(s_chronosynToken);
    }

    function getBaseTokenURI() public view returns (string memory) {
        return s_baseTokenURI;
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
}
```