```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- QuantumVault Outline and Function Summary ---
//
// This smart contract, QuantumVault, introduces a novel vault mechanism inspired by abstract concepts of quantum mechanics.
// Users deposit ERC-20 tokens into 'Positions'. These Positions can exist in different 'States' analogous
// to quantum superposition and measurement. Key features include:
//
// 1. Position States: Positions can be in `Initial`, `QuantumFlux`, `Measured`, or `Decohered` states.
//    - `Initial`: The default state after deposit.
//    - `QuantumFlux`: An active state where the position might experience probabilistic outcomes
//                     via `performQuantumAction`. Requires active management.
//    - `Measured`: The state required for safe withdrawal or transferring. Reached by successfully
//                  completing `performQuantumAction` or breaking entanglement.
//    - `Decohered`: A state resulting from neglecting a `QuantumFlux` position (time-based) or
//                   failure during `performQuantumAction`. May incur penalties upon withdrawal.
//
// 2. Quantum Flux Mechanics:
//    - Users can transition a position into `QuantumFlux` state for potential benefits (not explicitly
//      implemented as yield here, but could be integrated via oracle or future logic) but with risks.
//    - `performQuantumAction` attempts a probabilistic operation on a `QuantumFlux` position. Outcome
//      depends on an internal 'quantum state factor' and pseudo-randomness, leading to Success (-> Measured),
//      Failure (-> Decohered), or retaining QuantumFlux (less likely).
//    - Positions automatically transition to `Decohered` if they remain in `QuantumFlux` longer than `quantumFluxDuration`.
//
// 3. Entanglement:
//    - Users can 'entangle' two positions they own or request entanglement with another user's position.
//    - Entangled positions are linked; actions on one might affect the state of the other.
//    - Breaking entanglement might incur a cost or state change.
//
// 4. Dynamic Parameters:
//    - Certain parameters (`quantumFluxDuration`, `decoherencePenaltyRate`, `quantumStateFactor`)
//      can be adjusted, potentially via a simple governance mechanism.
//
// 5. Governance (Basic):
//    - A simple proposal and voting system allows token holders (or specific addresses) to propose
//      changes to vault parameters.
//
// 6. Penalty System:
//    - `Decohered` positions may incur a penalty on withdrawal, which can be claimed by the owner/governance.
//
// --- Function Summary ---
//
// Vault Core Functions:
// 1.  `constructor`: Initializes the contract owner and ERC-20 token address.
// 2.  `deposit`: Allows users to deposit tokens and create a new Position in `Initial` state.
// 3.  `withdraw`: Allows users to withdraw tokens from a `Measured` or `Decohered` Position, applying penalty if Decohered.
// 4.  `getVaultBalance`: Returns the total balance of the ERC-20 token held by the vault.
// 5.  `getUserPositionCount`: Returns the total number of positions owned by a specific user.
// 6.  `getUserPositionIdAtIndex`: Returns the ID of a user's position at a given index.
// 7.  `getUserPosition`: Returns the detailed struct data for a specific position ID.
// 8.  `getPositionState`: Returns the current State enum of a position.
//
// Quantum Mechanics Functions:
// 9.  `enterQuantumFlux`: Transitions a Position from `Initial` or `Measured` to `QuantumFlux`.
// 10. `performQuantumAction`: Attempts a probabilistic action on a `QuantumFlux` position. Outcome affects its state.
// 11. `checkDecoherence`: Checks if a `QuantumFlux` position has exceeded its duration and transitions it to `Decohered` if so.
// 12. `requestEntanglement`: Requests to entangle two positions (either both user's or one user's and another's).
// 13. `acceptEntanglement`: Accepts a pending entanglement request.
// 14. `breakEntanglement`: Breaks an existing entanglement link between two positions.
// 15. `viewEntangledPosition`: Returns the ID of the position entangled with a given position.
// 16. `getPendingEntanglements`: Returns a list of pending entanglement requests for a user.
//
// Parameter & Governance Functions:
// 17. `setQuantumFluxDuration`: Owner sets the duration for the Quantum Flux state.
// 18. `setDecoherencePenaltyRate`: Owner sets the penalty percentage for Decohered positions upon withdrawal.
// 19. `adjustQuantumStateFactor`: Owner can slightly adjust the factor influencing `performQuantumAction` outcomes.
// 20. `proposeParameterChange`: Allows a proposer to submit a parameter change proposal.
// 21. `voteOnProposal`: Allows eligible voters to vote on an active proposal.
// 22. `executeProposal`: Executes a passed proposal to change a parameter.
// 23. `claimDecoherencePenaltyFunds`: Allows owner/governance to withdraw collected penalties.
//
// Utility & Management Functions:
// 24. `reorganizePositions`: Combines multiple `Measured` positions of a user into a single new position.
// 25. `transferPosition`: Allows the owner of a position to transfer its ownership to another address.
// 26. `pauseContract`: Owner can pause contract operations.
// 27. `unpauseContract`: Owner can unpause contract operations.
// 28. `getQuantumStateFactor`: View the current quantum state factor.
// 29. `getDecoherencePenaltyRate`: View the current decoherence penalty rate.
// 30. `getQuantumFluxDuration`: View the current quantum flux duration.
//
// (Note: Some functions like `unpauseContract` are inherited from Pausable. The count includes explicitly defined ones and key inherited/standard patterns).

contract QuantumVault is Ownable, Pausable {
    IERC20 public immutable vaultToken;

    enum PositionState {
        Initial,
        QuantumFlux,
        Measured,
        Decohered
    }

    struct Position {
        address owner;
        uint256 amount;
        PositionState state;
        uint64 stateChangeTimestamp; // Timestamp when state last changed
        uint256 entangledPositionId; // 0 if not entangled
        bool isEntangledSource;      // If true, this position initiated the entanglement
    }

    struct ParameterChangeProposal {
        enum ParameterType {
            QuantumFluxDuration,
            DecoherencePenaltyRate,
            QuantumStateFactor
        }
        ParameterType parameterType;
        uint256 newValue;
        uint256 voteThreshold; // e.g., required percentage / amount of votes
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active; // To prevent re-voting or execution after resolution
        mapping(address => bool) hasVoted;
    }

    uint256 private _nextPositionId;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) private _userPositionIds; // List of position IDs for each user

    // Entanglement requests: requester position ID => requested position ID => request details
    mapping(uint256 => mapping(uint256 => bool)) private _pendingEntanglementRequests;

    // --- Parameters (adjustable) ---
    uint64 public quantumFluxDuration; // Time limit in seconds for QuantumFlux state before decoherence
    uint256 public decoherencePenaltyRate; // Penalty percentage (0-10000 for 0-100%)
    uint256 public quantumStateFactor; // Factor influencing the outcome probability of performQuantumAction (e.g., 0-100)

    // --- Governance ---
    uint256 private _nextProposalId;
    mapping(uint256 => ParameterChangeProposal) public proposals;
    // Simple voting power: 1 token = 1 vote, or could be fixed addresses, or based on vault stake.
    // For simplicity, let's assume owner initiates and a set of authorized voters vote (or simple token stake if using ERC20 votes)
    // Let's make it simple: only owner can propose, voting power is based on total vault deposit *amount* across all their positions.
    mapping(address => bool) public isAuthorizedVoter;

    uint256 public totalDecoherencePenaltiesCollected;

    // --- Events ---
    event PositionCreated(uint256 indexed positionId, address indexed owner, uint256 amount, PositionState initialState);
    event PositionStateChanged(uint256 indexed positionId, PositionState oldState, PositionState newState, uint256 amount);
    event TokensWithdrawn(uint256 indexed positionId, address indexed owner, uint256 amount, uint256 penaltyAmount);
    event QuantumActionOutcome(uint256 indexed positionId, bool success, uint256 outcomeFactor);
    event EntanglementRequested(uint256 indexed sourcePositionId, uint256 indexed targetPositionId);
    event EntanglementAccepted(uint256 indexed position1Id, uint256 indexed position2Id);
    event EntanglementBroken(uint256 indexed position1Id, uint256 indexed position2Id);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, ParameterChangeProposal.ParameterType parameterType, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId);
    event DecoherencePenaltyClaimed(address indexed receiver, uint256 amount);
    event PositionTransferred(uint256 indexed positionId, address indexed from, address indexed to);

    // --- Modifiers ---
    modifier positionExists(uint256 _positionId) {
        require(_positionId > 0 && positions[_positionId].owner != address(0), "Position does not exist");
        _;
    }

    modifier isPositionOwner(uint256 _positionId) {
        require(positions[_positionId].owner == msg.sender, "Not position owner");
        _;
    }

    modifier isAuthorizedVoter() {
        require(isAuthorizedVoter[msg.sender] || owner() == msg.sender, "Not an authorized voter or owner");
        _;
    }

    modifier onlyAuthorizedProposer() {
         // For this simple example, only owner can propose. Can extend to others.
        require(owner() == msg.sender, "Only owner can propose");
        _;
    }

    // --- Constructor ---
    constructor(address _vaultTokenAddress, uint64 _quantumFluxDuration, uint256 _decoherencePenaltyRate, uint256 _initialQuantumStateFactor) Ownable(msg.sender) Pausable(msg.sender) {
        vaultToken = IERC20(_vaultTokenAddress);
        quantumFluxDuration = _quantumFluxDuration;
        decoherencePenaltyRate = _decoherencePenaltyRate;
        quantumStateFactor = _initialQuantumStateFactor;
        _nextPositionId = 1; // Start position IDs from 1
        _nextProposalId = 1; // Start proposal IDs from 1

        // Add owner as an initial authorized voter
        isAuthorizedVoter[msg.sender] = true;
    }

    // --- Vault Core Implementations ---

    /**
     * @notice Allows users to deposit tokens and create a new Position.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than 0");

        uint256 positionId = _nextPositionId++;
        positions[positionId] = Position({
            owner: msg.sender,
            amount: _amount,
            state: PositionState.Initial,
            stateChangeTimestamp: uint64(block.timestamp),
            entangledPositionId: 0,
            isEntangledSource: false
        });
        _userPositionIds[msg.sender].push(positionId);

        require(vaultToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        emit PositionCreated(positionId, msg.sender, _amount, PositionState.Initial);
    }

    /**
     * @notice Allows users to withdraw tokens from a Measured or Decohered Position.
     * @param _positionId The ID of the position to withdraw from.
     */
    function withdraw(uint256 _positionId) external whenNotPaused positionExists(_positionId) isPositionOwner(_positionId) {
        Position storage position = positions[_positionId];
        require(position.state == PositionState.Measured || position.state == PositionState.Decohered, "Position must be Measured or Decohered to withdraw");
        require(position.entangledPositionId == 0, "Cannot withdraw entangled position");

        uint256 amountToWithdraw = position.amount;
        uint256 penaltyAmount = 0;

        if (position.state == PositionState.Decohered) {
            penaltyAmount = (amountToWithdraw * decoherencePenaltyRate) / 10000;
            amountToWithdraw -= penaltyAmount;
            totalDecoherencePenaltiesCollected += penaltyAmount;
        }

        // Mark position as withdrawn/deleted by clearing data
        delete positions[_positionId];
        // Efficiently remove the position ID from the user's list (order doesn't matter)
        uint256[] storage userPositionIds = _userPositionIds[msg.sender];
        for (uint i = 0; i < userPositionIds.length; i++) {
            if (userPositionIds[i] == _positionId) {
                userPositionIds[i] = userPositionIds[userPositionIds.length - 1];
                userPositionIds.pop();
                break;
            }
        }

        require(vaultToken.transfer(msg.sender, amountToWithdraw), "Token withdrawal failed");

        emit TokensWithdrawn(_positionId, msg.sender, amountToWithdraw, penaltyAmount);
        emit PositionStateChanged(_positionId, position.state, PositionState.Measured, 0); // Indicate final state conceptually
    }

    /**
     * @notice Returns the total balance of the ERC-20 token held by the vault.
     */
    function getVaultBalance() external view returns (uint256) {
        return vaultToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the total number of positions owned by a specific user.
     * @param _user The address of the user.
     */
    function getUserPositionCount(address _user) external view returns (uint256) {
        return _userPositionIds[_user].length;
    }

     /**
     * @notice Returns the ID of a user's position at a given index in their list.
     * @param _user The address of the user.
     * @param _index The index in the user's position list.
     */
    function getUserPositionIdAtIndex(address _user, uint256 _index) external view returns (uint256) {
        require(_index < _userPositionIds[_user].length, "Index out of bounds");
        return _userPositionIds[_user][_index];
    }

    /**
     * @notice Returns the detailed struct data for a specific position ID.
     * @param _positionId The ID of the position.
     */
    function getUserPosition(uint256 _positionId) external view positionExists(_positionId) returns (Position memory) {
        return positions[_positionId];
    }

    /**
     * @notice Returns the current State enum of a position.
     * @param _positionId The ID of the position.
     */
    function getPositionState(uint256 _positionId) external view positionExists(_positionId) returns (PositionState) {
        // Automatically check for decoherence on view, though state change only happens on call
        if (positions[_positionId].state == PositionState.QuantumFlux && block.timestamp >= positions[_positionId].stateChangeTimestamp + quantumFluxDuration) {
             return PositionState.Decohered;
        }
        return positions[_positionId].state;
    }


    // --- Quantum Mechanics Implementations ---

    /**
     * @notice Transitions a Position from Initial or Measured to QuantumFlux.
     *         Starts the timer for potential decoherence.
     * @param _positionId The ID of the position to transition.
     */
    function enterQuantumFlux(uint256 _positionId) external whenNotPaused positionExists(_positionId) isPositionOwner(_positionId) {
        Position storage position = positions[_positionId];
        require(position.state == PositionState.Initial || position.state == PositionState.Measured, "Position must be Initial or Measured to enter QuantumFlux");
        require(position.entangledPositionId == 0, "Cannot change state of entangled position directly"); // Entangled state changes might be linked

        PositionState oldState = position.state;
        position.state = PositionState.QuantumFlux;
        position.stateChangeTimestamp = uint64(block.timestamp);

        emit PositionStateChanged(_positionId, oldState, PositionState.QuantumFlux, position.amount);
    }

    /**
     * @notice Attempts a probabilistic action on a QuantumFlux position.
     *         Measures the position, collapsing its state based on probabilistic outcome.
     * @param _positionId The ID of the position in QuantumFlux.
     */
    function performQuantumAction(uint256 _positionId) external whenNotPaused positionExists(_positionId) isPositionOwner(_positionId) {
        Position storage position = positions[_positionId];
        require(position.state == PositionState.QuantumFlux, "Position must be in QuantumFlux state");
        require(position.entangledPositionId == 0, "Cannot measure entangled position individually"); // Measurement might affect both

        // Check for passive decoherence before performing action
        checkDecoherence(_positionId);
        if (position.state != PositionState.QuantumFlux) {
             // State changed to Decohered by checkDecoherence
             return;
        }

        PositionState oldState = position.state;

        // --- Pseudo-random outcome based on blockhash, timestamp, and quantumStateFactor ---
        // WARNING: blockhash is predictable to miners. This is for illustrative purposes only.
        // For real-world use, Chainlink VRF or similar is required for secure randomness.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, position.amount, quantumStateFactor))) % 100; // Result 0-99

        // Define outcome probabilities (example logic)
        // Lower quantumStateFactor -> higher chance of Failure/Decoherence
        // Higher quantumStateFactor -> higher chance of Success/Measured
        // Example: Success if random number < quantumStateFactor (scaled 0-100)
        // Failure if random number is >= quantumStateFactor but below a higher threshold
        // Decoherence if random number above higher threshold (rare spontaneous collapse)

        uint256 successThreshold = quantumStateFactor; // e.g., 60
        uint256 failureThreshold = 90; // e.g., 90

        bool success = false;
        uint256 outcomeFactor = randomNumber; // For logging the random result

        if (randomNumber < successThreshold) {
            // Success: Transition to Measured state
            position.state = PositionState.Measured;
            success = true;
        } else if (randomNumber < failureThreshold) {
            // Failure: Transition to Decohered state
            position.state = PositionState.Decohered;
        } else {
            // Spontaneous Decoherence (less likely): Transition to Decohered state
            position.state = PositionState.Decohered;
        }

        position.stateChangeTimestamp = uint64(block.timestamp); // Record measurement time

        emit QuantumActionOutcome(_positionId, success, outcomeFactor);
        emit PositionStateChanged(_positionId, oldState, position.state, position.amount);
    }

    /**
     * @notice Checks if a QuantumFlux position has exceeded its duration and transitions it to Decohered if so.
     *         Callable by anyone, beneficial for the user or potentially a keeper system.
     * @param _positionId The ID of the position to check.
     */
    function checkDecoherence(uint256 _positionId) public whenNotPaused positionExists(_positionId) {
        Position storage position = positions[_positionId];

        if (position.state == PositionState.QuantumFlux && block.timestamp >= position.stateChangeTimestamp + quantumFluxDuration) {
            PositionState oldState = position.state;
            position.state = PositionState.Decohered;
            position.stateChangeTimestamp = uint64(block.timestamp);
             emit PositionStateChanged(_positionId, oldState, PositionState.Decohered, position.amount);
        }
    }

    // --- Entanglement Implementations ---

    /**
     * @notice Requests to entangle two positions. Can be two of the caller's positions or one with another user's.
     * @param _sourcePositionId The ID of the position initiating the request.
     * @param _targetPositionId The ID of the position being requested for entanglement.
     */
    function requestEntanglement(uint256 _sourcePositionId, uint256 _targetPositionId) external whenNotPaused positionExists(_sourcePositionId) positionExists(_targetPositionId) isPositionOwner(_sourcePositionId) {
        require(_sourcePositionId != _targetPositionId, "Cannot entangle a position with itself");

        Position storage sourcePos = positions[_sourcePositionId];
        Position storage targetPos = positions[_targetPositionId];

        require(sourcePos.entangledPositionId == 0, "Source position is already entangled");
        require(targetPos.entangledPositionId == 0, "Target position is already entangled");
        // Can only request entanglement for positions in Initial or Measured state for simplicity
        require(sourcePos.state == PositionState.Initial || sourcePos.state == PositionState.Measured, "Source position state not compatible for entanglement");
        require(targetPos.state == PositionState.Initial || targetPos.state == PositionState.Measured, "Target position state not compatible for entanglement");


        if (sourcePos.owner == targetPos.owner) {
            // Entangling two of the same user's positions - auto-accept
            _entanglePositions(_sourcePositionId, _targetPositionId, true); // true means source initiated
        } else {
            // Requesting entanglement with another user's position
            _pendingEntanglementRequests[_sourcePositionId][_targetPositionId] = true;
            emit EntanglementRequested(_sourcePositionId, _targetPositionId);
        }
    }

    /**
     * @notice Accepts a pending entanglement request.
     * @param _sourcePositionId The ID of the position that initiated the request.
     * @param _targetPositionId The ID of the caller's position that was requested.
     */
    function acceptEntanglement(uint256 _sourcePositionId, uint256 _targetPositionId) external whenNotPaused positionExists(_sourcePositionId) positionExists(_targetPositionId) isPositionOwner(_targetPositionId) {
        require(_pendingEntanglementRequests[_sourcePositionId][_targetPositionId], "No pending entanglement request found for these positions");

        Position storage sourcePos = positions[_sourcePositionId];
        Position storage targetPos = positions[_targetPositionId];

        require(sourcePos.owner != msg.sender, "Cannot accept your own request");
        require(sourcePos.entangledPositionId == 0, "Source position is already entangled");
        require(targetPos.entangledPositionId == 0, "Your target position is already entangled");
        // Can only accept entanglement for positions in Initial or Measured state for simplicity
        require(sourcePos.state == PositionState.Initial || sourcePos.state == PositionState.Measured, "Source position state not compatible for entanglement");
        require(targetPos.state == PositionState.Initial || targetPos.state == PositionState.Measured, "Your target position state not compatible for entanglement");


        delete _pendingEntanglementRequests[_sourcePositionId][_targetPositionId];
        _entanglePositions(_sourcePositionId, _targetPositionId, true); // true means source initiated (from request)
    }

    /**
     * @notice Breaks an existing entanglement link between two positions.
     *         Either owner of the entangled pair can call this.
     *         May reset positions to Measured state.
     * @param _position1Id The ID of one of the entangled positions.
     * @param _position2Id The ID of the other entangled position.
     */
    function breakEntanglement(uint256 _position1Id, uint256 _position2Id) external whenNotPaused positionExists(_position1Id) positionExists(_position2Id) {
        Position storage pos1 = positions[_position1Id];
        Position storage pos2 = positions[_position2Id];

        require(pos1.entangledPositionId == _position2Id && pos2.entangledPositionId == _position1Id, "Positions are not entangled with each other");
        require(pos1.owner == msg.sender || pos2.owner == msg.sender, "Must own one of the entangled positions");

        // Remove entanglement link
        pos1.entangledPositionId = 0;
        pos2.entangledPositionId = 0;
        pos1.isEntangledSource = false; // Reset source status
        pos2.isEntangledSource = false;

        // Optional: Add a cost or state change penalty for breaking entanglement
        // For simplicity here, we just break the link and reset state to Measured
        if (pos1.state != PositionState.Decohered) {
            pos1.state = PositionState.Measured;
             emit PositionStateChanged(_position1Id, pos1.state, PositionState.Measured, pos1.amount);
        }
         if (pos2.state != PositionState.Decohered) {
            pos2.state = PositionState.Measured;
            emit PositionStateChanged(_position2Id, pos2.state, PositionState.Measured, pos2.amount);
        }

        emit EntanglementBroken(_position1Id, _position2Id);
    }

     /**
     * @notice Helper internal function to link two positions as entangled.
     * @param _pos1Id The ID of the first position.
     * @param _pos2Id The ID of the second position.
     * @param _pos1IsSource Whether position 1 is considered the "source" initiating the entanglement.
     */
    function _entanglePositions(uint256 _pos1Id, uint256 _pos2Id, bool _pos1IsSource) internal {
        positions[_pos1Id].entangledPositionId = _pos2Id;
        positions[_pos2Id].entangledPositionId = _pos1Id;
        positions[_pos1Id].isEntangledSource = _pos1IsSource;
        positions[_pos2Id].isEntangledSource = !_pos1IsSource; // The other is not the source

        // Entangling might reset state to Measured (or keep Initial)
         if (positions[_pos1Id].state != PositionState.Decohered) {
            positions[_pos1Id].state = PositionState.Measured;
             emit PositionStateChanged(_pos1Id, positions[_pos1Id].state, PositionState.Measured, positions[_pos1Id].amount);
         }
         if (positions[_pos2Id].state != PositionState.Decohered) {
            positions[_pos2Id].state = PositionState.Measured;
             emit PositionStateChanged(_pos2Id, positions[_pos2Id].state, PositionState.Measured, positions[_pos2Id].amount);
         }

        emit EntanglementAccepted(_pos1Id, _pos2Id);
    }

    /**
     * @notice Returns the ID of the position entangled with a given position.
     * @param _positionId The ID of the position to check.
     */
    function viewEntangledPosition(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
        return positions[_positionId].entangledPositionId;
    }

     /**
     * @notice Returns a list of position IDs that have requested entanglement with the caller's positions.
     *         (Requires iterating through all positions, can be gas-intensive if many).
     *         A more efficient approach would use a dedicated mapping for requests *by target*.
     *         For this example, we'll use the simpler approach.
     */
    function getPendingEntanglements() external view returns (uint256[] memory) {
        uint256[] memory userPositions = _userPositionIds[msg.sender];
        uint256[] memory pendingRequests; // Dynamically sized array
        uint256 count = 0;

        // Count pending requests targeting user's positions
        for (uint i = 0; i < userPositions.length; i++) {
            uint256 targetPosId = userPositions[i];
             // Iterate through *all* possible source position IDs (inefficient for mainnet scale)
             // A better way: maintain a mapping like mapping(uint256 targetPosId => uint256[] sourcePosIds)
             // For this example, demonstrating the concept: check requests *to* the user's positions
             // This requires knowing all potential source IDs, which isn't feasible without iterating all _nextPositionId.
             // Let's simplify: Just return requests *initiated by* the user to *other* users (already stored).
             // Or, let's check requests *targeting* this user's positions from any *other* position ID encountered so far.
             // This is still inefficient. Let's refactor the request storage for efficient lookup by target.
             // New approach: mapping(uint256 targetPosId => uint256[] sourceRequestingPosIds)
        }

        // --- Refactoring needed here for efficient lookup ---
        // As the current structure maps source => target => bool, getting requests *to* a target
        // without knowing the source requires iterating all potential sources.
        // Let's assume for this example we only need to check if a *specific known* request exists,
        // or refactor the request mapping (which adds complexity).
        // Let's just return the list of *potential* requesters targeting the user's positions, limited by recent IDs.
        // This is still inefficient and won't scale.

        // --- Simplified approach for example: just return the list of the user's own positions that *have* pending outgoing requests ---
        // This still doesn't show requests *to* the user.

        // Let's change the function signature slightly or simplify the return.
        // We will return a list of {sourcePositionId, targetPositionId} pairs where target is msg.sender's position.

        uint256 potentialMaxRequests = _nextPositionId; // Rough upper bound on potential requesters
        uint256[] memory tempRequests = new uint256[](potentialMaxRequests * userPositions.length * 2); // Stores [source1, target1, source2, target2, ...]
        uint256 tempCount = 0;

        // Iterate through potential sources (limited scope for example)
        for(uint256 srcId = 1; srcId < _nextPositionId; srcId++) {
             if(positions[srcId].owner != address(0) && positions[srcId].owner != msg.sender) { // Source is a valid position owned by someone else
                 for(uint i = 0; i < userPositions.length; i++) {
                     uint256 targetId = userPositions[i];
                     if (_pendingEntanglementRequests[srcId][targetId]) {
                         tempRequests[tempCount++] = srcId;
                         tempRequests[tempCount++] = targetId;
                     }
                 }
             }
        }

        uint256[] memory finalRequests = new uint256[](tempCount);
        for(uint i = 0; i < tempCount; i++) {
            finalRequests[i] = tempRequests[i];
        }

        // Result is an array where elements at index 2*i is the source ID, and 2*i+1 is the target ID (owned by msg.sender)
        return finalRequests;
        // This is still not great for gas on mainnet with many positions. Real implementation needs better mapping.
    }


    // --- Parameter & Governance Implementations ---

    /**
     * @notice Sets the duration for the Quantum Flux state. Only callable by owner.
     * @param _duration New duration in seconds.
     */
    function setQuantumFluxDuration(uint64 _duration) external onlyOwner whenNotPaused {
        require(_duration > 0, "Duration must be greater than 0");
        quantumFluxDuration = _duration;
    }

    /**
     * @notice Sets the penalty percentage for Decohered positions upon withdrawal. Only callable by owner.
     * @param _rate New penalty percentage (0-10000 for 0-100%).
     */
    function setDecoherencePenaltyRate(uint256 _rate) external onlyOwner whenNotPaused {
        require(_rate <= 10000, "Rate cannot exceed 10000 (100%)");
        decoherencePenaltyRate = _rate;
    }

     /**
     * @notice Owner can slightly adjust the factor influencing `performQuantumAction` outcomes.
     *         Represents external influence on the "quantum state" of the vault.
     * @param _factor New quantum state factor (e.g., 0-100).
     */
    function adjustQuantumStateFactor(uint256 _factor) external onlyOwner whenNotPaused {
        require(_factor <= 100, "Factor cannot exceed 100");
        quantumStateFactor = _factor;
        // Could add an event here if needed
    }

    /**
     * @notice Allows an authorized proposer to submit a parameter change proposal.
     * @param _parameterType The type of parameter to change.
     * @param _newValue The new value for the parameter.
     * @param _voteThreshold The required total vote weight to pass the proposal.
     */
    function proposeParameterChange(ParameterChangeProposal.ParameterType _parameterType, uint256 _newValue, uint256 _voteThreshold) external onlyAuthorizedProposer whenNotPaused returns (uint256 proposalId) {
         proposalId = _nextProposalId++;
         ParameterChangeProposal storage proposal = proposals[proposalId];

         proposal.parameterType = _parameterType;
         proposal.newValue = _newValue;
         proposal.voteThreshold = _voteThreshold;
         proposal.votesFor = 0;
         proposal.votesAgainst = 0;
         proposal.executed = false;
         proposal.active = true;

         // Require initial voter weight threshold
         // Example: Vote threshold is based on total amount deposited by voters
         // This requires a way to calculate vote weight (e.g., based on user's total deposited amount)
         // For this simple version, let's assume voteThreshold is just a target number of votes from authorized voters.
         require(_voteThreshold > 0, "Vote threshold must be greater than 0");


         emit ParameterChangeProposed(proposalId, msg.sender, _parameterType, _newValue);
    }

    /**
     * @notice Allows eligible voters to vote on an active proposal.
     *         Voting power for this example is simply 1 vote per authorized voter.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True for 'yes', False for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteFor) external isAuthorizedVoter whenNotPaused {
        ParameterChangeProposal storage proposal = proposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _voteFor);
    }

    /**
     * @notice Executes a passed proposal if it has met the vote threshold.
     *         Callable by anyone once conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
         ParameterChangeProposal storage proposal = proposals[_proposalId];
         require(proposal.active, "Proposal is not active");
         require(!proposal.executed, "Proposal already executed");
         require(proposal.votesFor >= proposal.voteThreshold, "Vote threshold not met");
         // Could add a time lock or voting period check here

         // Execute the change
         if (proposal.parameterType == ParameterChangeProposal.ParameterType.QuantumFluxDuration) {
             quantumFluxDuration = uint64(proposal.newValue);
         } else if (proposal.parameterType == ParameterChangeProposal.ParameterType.DecoherencePenaltyRate) {
             require(proposal.newValue <= 10000, "New rate invalid");
             decoherencePenaltyRate = proposal.newValue;
         } else if (proposal.parameterType == ParameterChangeProposal.ParameterType.QuantumStateFactor) {
             require(proposal.newValue <= 100, "New factor invalid");
             quantumStateFactor = proposal.newValue;
         } else {
             revert("Unknown parameter type");
         }

         proposal.executed = true;
         proposal.active = false; // Deactivate after execution

         emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows the owner/governance to claim collected penalties from Decohered position withdrawals.
     * @param _amount The amount of penalties to claim.
     */
    function claimDecoherencePenaltyFunds(uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0, "Claim amount must be greater than 0");
        require(_amount <= totalDecoherencePenaltiesCollected, "Amount exceeds collected penalties");

        totalDecoherencePenaltiesCollected -= _amount;
        require(vaultToken.transfer(owner(), _amount), "Penalty transfer failed");

        emit DecoherencePenaltyClaimed(owner(), _amount);
    }

    // --- Utility & Management Implementations ---

    /**
     * @notice Combines multiple `Measured` positions of a user into a single new position.
     *         Can help users manage fewer position IDs.
     * @param _positionIds The IDs of the user's Measured positions to combine.
     */
    function reorganizePositions(uint256[] calldata _positionIds) external whenNotPaused {
        uint256 totalAmount = 0;
        uint256[] storage userPositionIds = _userPositionIds[msg.sender];
        uint256 userPositionsCount = userPositionIds.length;
        uint256[] memory positionsToRemove = new uint256[](_positionIds.length);
        uint256 removeCount = 0;

        // Track which indices in the user's main array need to be removed
        mapping(uint256 => bool) isMarkedForRemoval;


        for (uint i = 0; i < _positionIds.length; i++) {
            uint256 posId = _positionIds[i];
            Position storage position = positions[posId];

            require(position.owner == msg.sender, "Not owner of position");
            require(position.state == PositionState.Measured, "Position must be Measured to reorganize");
            require(position.entangledPositionId == 0, "Cannot reorganize entangled position");

            totalAmount += position.amount;

            // Mark for removal
            delete positions[posId]; // Delete the old position data
            positionsToRemove[removeCount++] = posId; // Store ID to remove from user's array
        }

        require(totalAmount > 0, "No valid positions to reorganize");


        // Efficiently remove marked positions from the user's list
        uint265 writeIdx = 0;
        for(uint i = 0; i < userPositionsCount; i++) {
             bool found = false;
             for(uint j = 0; j < removeCount; j++) {
                 if (userPositionIds[i] == positionsToRemove[j]) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                  userPositionIds[writeIdx++] = userPositionIds[i];
             }
        }
        userPositionIds.pop(userPositionsCount - writeIdx); // Resize array


        // Create the new combined position
        uint256 newPositionId = _nextPositionId++;
        positions[newPositionId] = Position({
            owner: msg.sender,
            amount: totalAmount,
            state: PositionState.Measured, // New position starts as Measured
            stateChangeTimestamp: uint64(block.timestamp),
            entangledPositionId: 0,
            isEntangledSource: false
        });
        _userPositionIds[msg.sender].push(newPositionId);

        emit PositionCreated(newPositionId, msg.sender, totalAmount, PositionState.Measured);
        // Could emit events for deleted positions too, if needed
    }

    /**
     * @notice Allows the owner of a position to transfer its ownership to another address.
     *         Position must be in Initial or Measured state and not entangled.
     * @param _positionId The ID of the position to transfer.
     * @param _to The recipient address.
     */
    function transferPosition(uint256 _positionId, address _to) external whenNotPaused positionExists(_positionId) isPositionOwner(_positionId) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to self");

        Position storage position = positions[_positionId];
        require(position.state == PositionState.Initial || position.state == PositionState.Measured, "Position must be Initial or Measured to transfer");
        require(position.entangledPositionId == 0, "Cannot transfer entangled position");

        address oldOwner = position.owner;
        position.owner = _to;

        // Remove from old owner's list (inefficient, see reorganizePositions for better removal)
        uint256[] storage oldOwnerPositionIds = _userPositionIds[oldOwner];
         uint256 oldOwnerCount = oldOwnerPositionIds.length;
         for(uint i = 0; i < oldOwnerCount; i++) {
             if (oldOwnerPositionIds[i] == _positionId) {
                 oldOwnerPositionIds[i] = oldOwnerPositionIds[oldOwnerCount - 1];
                 oldOwnerPositionIds.pop();
                 break;
             }
         }

        // Add to new owner's list
        _userPositionIds[_to].push(_positionId);

        emit PositionTransferred(_positionId, oldOwner, _to);
    }

    // --- Pausable inherited functions ---
    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Getter functions for parameters ---
    function getQuantumStateFactor() external view returns (uint256) {
        return quantumStateFactor;
    }

    function getDecoherencePenaltyRate() external view returns (uint256) {
        return decoherencePenaltyRate;
    }

    function getQuantumFluxDuration() external view returns (uint64) {
        return quantumFluxDuration;
    }

    // --- Owner functions for managing authorized voters (optional, depends on governance model) ---
    /**
     * @notice Adds or removes an address from the list of authorized voters.
     * @param _voter The address to manage.
     * @param _isAuthorized True to authorize, False to deauthorize.
     */
    function setAuthorizedVoter(address _voter, bool _isAuthorized) external onlyOwner {
        require(_voter != address(0), "Invalid address");
        isAuthorizedVoter[_voter] = _isAuthorized;
    }

    // --- Further Ideas (Not implemented to keep size reasonable, but could add) ---
    // - Integrate Chainlink VRF for better randomness in performQuantumAction
    // - Allow users to 'Observer' a QuantumFlux position (read its internal outcome before state collapse?) - complex state management
    // - Implement rewards/yield based on QuantumFlux state or successful QuantumActions
    // - More complex entanglement effects (e.g., actions on one position affect amount/state of the other)
    // - Time-decaying vote power in governance
    // - Liquid democracy: delegate voting power
    // - Prediction market integration for proposal outcomes
    // - NFT representation of Positions

}
```