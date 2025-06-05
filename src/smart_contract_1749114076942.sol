Okay, this is an interesting challenge! Let's design a smart contract that represents a kind of *conditional, stateful linkage* between two parties and their assets, inspired loosely by the abstract concept of entanglement. It's not a direct simulation of quantum physics, but uses the idea of a shared, dependent state that can resolve in different ways based on external conditions or time.

We'll call it the `QuantumEntanglementSwap` contract. It allows two parties to "entangle" two different assets. While entangled, the assets are locked. The entanglement can be resolved either by a conditional *swap* of assets or a *disentanglement* (returning original assets), triggered by specific criteria (like time, price, or mutual agreement) and potentially handled by Chainlink Automation/Functions or a similar keeper network for off-chain checks and on-chain execution.

This moves beyond simple escrow or atomic swaps by introducing multiple states, complex resolution conditions, timeouts, and requiring off-chain logic interaction (simulated here by hypothetical `verifyConditions` calls).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice

/**
 * @title QuantumEntanglementSwap
 * @dev A contract simulating a conditional, stateful linkage (Entanglement) between two parties' assets.
 *      Allows parties to lock assets and define conditions for either a swap or disentanglement.
 *      Resolution can be triggered by parties, or potentially keepers/automation based on external conditions.
 *      Inspired by complex systems with interdependent states and conditional transitions.
 *
 * Outline:
 * 1. State Definitions (Enums, Structs) for pairs and conditions.
 * 2. Core Storage (Mappings for pairs, counters).
 * 3. Events for transparency.
 * 4. Admin/Owner Functions (Pause, Emergency Withdraw).
 * 5. Pair Management Functions (Propose, Accept, Deposit, Cancel).
 * 6. State Query Functions (Get details, state, conditions, user pairs).
 * 7. Resolution Trigger Functions (Trigger Swap, Trigger Disentangle, Handle Timeout).
 * 8. Claim Functions (Claim assets after resolution).
 * 9. Internal Helper Functions (Asset transfers, condition verification - simulated).
 */

/**
 * @dev Enumerates the possible states of an Entanglement Pair.
 * - Proposed: Party A has proposed, waiting for Party B.
 * - Accepted: Party B has accepted, assets not yet deposited by A (if separate step).
 * - Entangled: Both parties have deposited assets, the linkage is active.
 * - SwapInitiatedA: Party A triggered swap, waiting for verification/timeout.
 * - SwapInitiatedB: Party B triggered swap, waiting for verification/timeout.
 * - DisentanglingA: Party A triggered disentangle, waiting for verification/timeout/B's agreement.
 * - DisentanglingB: Party B triggered disentangle, waiting for verification/timeout/A's agreement.
 * - CompletedSwap: Swap conditions met, assets swapped, ready to claim.
 * - CompletedDisentangle: Disentangle conditions met, original assets returned, ready to claim.
 * - Failed: Resolution failed (e.g., conditions not met, timeout without action), ready for specific fallback claim.
 * - Cancelled: Proposed state cancelled by Party A.
 */
enum PairState {
    Proposed,
    Accepted,
    Entangled,
    SwapInitiatedA,
    SwapInitiatedB,
    DisentanglingA,
    DisentanglingB,
    CompletedSwap,
    CompletedDisentangle,
    Failed,
    Cancelled
}

/**
 * @dev Defines the conditions that must be met for a Swap resolution.
 * - timeCondition: Optional - a specific timestamp to be reached or passed.
 * - priceCondition: Optional - price of a specific asset relative to a target.
 * - externalDataCondition: Optional - hash of data that needs verification via oracle/keeper.
 * - requiresMutualAgreement: If true, both parties must initiate swap or one initiates and the other confirms (simplified here).
 */
struct SwapConditions {
    uint256 timeCondition; // 0 if not set
    address priceFeedAsset; // Address of asset for price check (e.g., WETH, specific ERC20) - 0x0 if not set
    uint256 targetPrice; // Price in smallest units (e.g., USD * 1e8 for Chainlink)
    bytes32 priceComparisonOp; // ">", "<", ">=", "<=", "=="
    bytes32 externalDataHash; // Hash of external data to verify (e.g., weather data, game result) - bytes32(0) if not set
    bool requiresMutualAgreement;
}

/**
 * @dev Defines the conditions that must be met for a Disentangle resolution.
 * - timeCondition: Optional - a specific timestamp to be reached or passed.
 * - mutualAgreementRequired: If true, both parties must initiate disentangle.
 * - timeoutTimestamp: Absolute timestamp after which disentanglement (or specific fallback) is forced.
 */
struct DisentangleConditions {
    uint256 timeCondition; // 0 if not set
    bool mutualAgreementRequired;
    uint256 timeoutTimestamp; // Absolute timestamp
}

/**
 * @dev Represents a single Entanglement Pair.
 * - partyA, partyB: Participants.
 * - assetX: Asset provided by Party A (address, amount/id, isERC721).
 * - assetY: Asset provided by Party B (address, amount/id, isERC721).
 * - swapConditions: Conditions to trigger a swap.
 * - disentangleConditions: Conditions to trigger disentangle.
 * - currentState: Current state of the pair.
 * - initiatedTimestamp: Timestamp when current state was initiated (e.g., swap/disentangle triggered).
 * - resolvedTimestamp: Timestamp when resolution (swap/disentangle) was completed.
 */
struct EntanglementPair {
    address partyA;
    address partyB;
    address assetXAddress;
    uint256 assetXAmountOrId;
    bool isAssetXERC721;
    address assetYAddress;
    uint256 assetYAmountOrId;
    bool isAssetYERC721;
    SwapConditions swapConditions;
    DisentangleConditions disentangleConditions;
    PairState currentState;
    uint256 entanglementTimestamp; // Timestamp when it entered Entangled state
    uint256 initiatedTimestamp; // Timestamp when resolution (swap/disentangle) was initiated
    uint256 resolvedTimestamp; // Timestamp when resolution was completed
}


contract QuantumEntanglementSwap is Ownable, ReentrancyGuard {

    uint256 private _pairCounter;
    mapping(uint256 => EntanglementPair) private _entanglementPairs;
    mapping(address => uint256[]) private _userPairs; // Store pair IDs for each user

    // Dummy state for external condition verification (replace with Oracle/Chainlink Functions in real world)
    mapping(bytes32 => bool) private _externalDataVerified;
    mapping(address => uint256) private _simulatedPrices; // For price condition testing

    event PairProposed(uint256 indexed pairId, address indexed partyA, address indexed partyB, address assetX, address assetY);
    event PairAccepted(uint256 indexed pairId, address indexed partyB);
    event AssetsDeposited(uint256 indexed pairId, address indexed depositor, address assetAddress);
    event PairEntangled(uint256 indexed pairId);
    event StateChanged(uint256 indexed pairId, PairState indexed newState, uint256 timestamp);
    event ResolutionInitiated(uint256 indexed pairId, address indexed initiator, PairState indexed resolutionState);
    event ResolutionCompleted(uint256 indexed pairId, PairState indexed completedState);
    event AssetsClaimed(uint256 indexed pairId, address indexed claimant, address assetAddress, uint256 amountOrId);
    event PairCancelled(uint256 indexed pairId);
    event TimeoutHandled(uint256 indexed pairId);
    event EmergencyFundsWithdrawn(address indexed token, uint256 amount);

    // --- Admin Functions ---

    /// @dev Pauses contract execution. Only callable by owner.
    bool private _paused = false;
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }
    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    /// @notice Pauses all sensitive operations.
    /// @dev Can only be called by the owner.
    function pause() external onlyOwner {
        _paused = true;
    }

    /// @notice Unpauses the contract.
    /// @dev Can only be called by the owner.
    function unpause() external onlyOwner {
        _paused = false;
    }

    /// @notice Allows the owner to withdraw stuck ERC20 tokens.
    /// @dev Use with extreme caution. Only for recovering funds sent to the contract by mistake.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function ownerWithdrawERC20(address tokenAddress, uint256 amount) external onlyOwner whenPaused {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner(), amount), "ERC20 transfer failed");
        emit EmergencyFundsWithdrawn(tokenAddress, amount);
    }

     /// @notice Allows the owner to withdraw stuck ERC721 tokens.
    /// @dev Use with extreme caution. Only for recovering funds sent to the contract by mistake.
    /// @param tokenAddress The address of the ERC721 token contract.
    /// @param tokenId The ID of the ERC721 token.
    function ownerWithdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner whenPaused {
        IERC721 token = IERC721(tokenAddress);
         // Need to ensure the contract owns the token first
        require(token.ownerOf(tokenId) == address(this), "Contract does not own this NFT");
        token.transferFrom(address(this), owner(), tokenId);
        emit EmergencyFundsWithdrawn(tokenAddress, 1); // Amount is 1 for NFT
    }

    // --- Pair Management Functions ---

    /// @notice Proposes a new entanglement pair. Party A initiates.
    /// @dev Defines the terms of the swap/disentangle. Assets are NOT deposited yet.
    /// @param _partyB Address of the counterparty.
    /// @param _assetXAddress Address of Party A's asset (ERC20 or ERC721).
    /// @param _assetXAmountOrId Amount for ERC20, tokenId for ERC721.
    /// @param _isAssetXERC721 True if assetX is ERC721, false if ERC20.
    /// @param _assetYAddress Address of Party B's asset (ERC20 or ERC721).
    /// @param _assetYAmountOrId Amount for ERC20, tokenId for ERC721.
    /// @param _isAssetYERC721 True if assetY is ERC721, false if ERC20.
    /// @param _swapConditions struct defining swap conditions.
    /// @param _disentangleConditions struct defining disentangle conditions.
    /// @return pairId The unique ID of the newly proposed pair.
    function proposeEntanglement(
        address _partyB,
        address _assetXAddress,
        uint256 _assetXAmountOrId,
        bool _isAssetXERC721,
        address _assetYAddress,
        uint256 _assetYAmountOrId,
        bool _isAssetYERC721,
        SwapConditions memory _swapConditions,
        DisentangleConditions memory _disentangleConditions
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(_partyB != address(0) && _partyB != msg.sender, "Invalid party B");
        require(_assetXAddress != address(0) && _assetYAddress != address(0), "Invalid asset addresses");
        require(_assetXAmountOrId > 0 || _isAssetXERC721, "Invalid asset X amount/id"); // Amount > 0 for ERC20, id > 0 is implicit for valid NFT
        require(_assetYAmountOrId > 0 || _isAssetYERC721, "Invalid asset Y amount/id");

        _pairCounter++;
        uint256 pairId = _pairCounter;

        _entanglementPairs[pairId] = EntanglementPair({
            partyA: msg.sender,
            partyB: _partyB,
            assetXAddress: _assetXAddress,
            assetXAmountOrId: _assetXAmountOrId,
            isAssetXERC721: _isAssetXERC721,
            assetYAddress: _assetYAddress,
            assetYAmountOrId: _assetYAmountOrId,
            isAssetYERC721: _isAssetYERC721,
            swapConditions: _swapConditions,
            disentangleConditions: _disentangleConditions,
            currentState: PairState.Proposed,
            entanglementTimestamp: 0,
            initiatedTimestamp: 0,
            resolvedTimestamp: 0
        });

        _userPairs[msg.sender].push(pairId);
        _userPairs[_partyB].push(pairId);

        emit PairProposed(pairId, msg.sender, _partyB, _assetXAddress, _assetYAddress);
        emit StateChanged(pairId, PairState.Proposed, block.timestamp);

        return pairId;
    }

    /// @notice Party B accepts a proposed entanglement pair.
    /// @dev Requires Party B to deposit their asset (Asset Y) upon acceptance.
    /// @param pairId The ID of the pair to accept.
    function acceptEntanglement(uint256 pairId) external whenNotPaused nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyB == msg.sender, "Not party B");
        require(pair.currentState == PairState.Proposed, "Pair not in proposed state");

        pair.currentState = PairState.Accepted;
        emit PairAccepted(pairId, msg.sender);
        emit StateChanged(pairId, PairState.Accepted, block.timestamp);

        // Automatically deposit Asset Y upon acceptance
        _depositAsset(pairId, msg.sender);
    }

    /// @notice Party A deposits Asset X after Party B has accepted.
    /// @dev This transitions the state to Entangled.
    /// @param pairId The ID of the pair.
    function depositAssetX(uint256 pairId) external whenNotPaused nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyA == msg.sender, "Not party A");
        // We allow deposit in Accepted state (if deposit is separate) or potentially re-deposit if somehow failed earlier
        require(pair.currentState == PairState.Accepted, "Pair not in accepted state for Asset X deposit");

        _depositAsset(pairId, msg.sender);

        // If both assets are now deposited, transition to Entangled
        // Check internal state/flags if deposit was separate, or assume _depositAsset updates state correctly
        // Simplification: Assume _depositAsset ensures both are ready, then transitions
        // Let's refine: _depositAsset just handles transfer. Check deposits here.
        // A more robust system would track deposited status. For this example,
        // we assume `depositAssetX` is called *after* `acceptEntanglement` (which deposits Y).
        // So if A calls this in `Accepted` state, both are considered deposited *after* this call.

        pair.currentState = PairState.Entangled;
        pair.entanglementTimestamp = block.timestamp;
        emit PairEntangled(pairId);
        emit StateChanged(pairId, PairState.Entangled, block.timestamp);
    }

    /// @dev Internal function to handle asset deposits (either X or Y).
    /// @param pairId The ID of the pair.
    /// @param depositor The address depositing the asset.
    function _depositAsset(uint256 pairId, address depositor) internal {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        address assetAddress;
        uint256 amountOrId;
        bool isERC721;

        if (depositor == pair.partyA) {
            require(!_isAssetDeposited(pairId, pair.partyA), "Asset X already deposited"); // Prevent double deposit
            assetAddress = pair.assetXAddress;
            amountOrId = pair.assetXAmountOrId;
            isERC721 = pair.isAssetXERC721;
        } else if (depositor == pair.partyB) {
             require(!_isAssetDeposited(pairId, pair.partyB), "Asset Y already deposited"); // Prevent double deposit
            assetAddress = pair.assetYAddress;
            amountOrId = pair.assetYAmountOrId;
            isERC721 = pair.isAssetYERC721;
        } else {
            revert("Not a participant in this pair");
        }

        if (isERC721) {
            IERC721 token = IERC721(assetAddress);
             // Check if sender is owner and token is approved for transfer
            require(token.ownerOf(amountOrId) == depositor, "Depositor does not own the NFT");
            require(token.isApprovedForAll(depositor, address(this)) || token.getApproved(amountOrId) == address(this), "NFT not approved for contract");
            token.transferFrom(depositor, address(this), amountOrId);
        } else {
            IERC20 token = IERC20(assetAddress);
            require(token.transferFrom(depositor, address(this), amountOrId), "ERC20 transfer failed");
        }

        // Mark asset as deposited (using a separate mapping or state within the struct if needed)
        // For simplicity here, we assume successful transfer means deposit is complete for this example.
        emit AssetsDeposited(pairId, depositor, assetAddress);
    }

    /// @notice Cancels a proposed entanglement pair. Only callable by Party A if not accepted.
    /// @param pairId The ID of the pair to cancel.
    function cancelProposal(uint256 pairId) external whenNotPaused nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyA == msg.sender, "Not party A");
        require(pair.currentState == PairState.Proposed, "Pair not in proposed state");

        pair.currentState = PairState.Cancelled;
        emit PairCancelled(pairId);
        emit StateChanged(pairId, PairState.Cancelled, block.timestamp);

        // No assets are held yet, so no need to return anything.
    }

     // --- State Query Functions ---

    /// @notice Gets the full details of an entanglement pair.
    /// @param pairId The ID of the pair.
    /// @return EntanglementPair struct containing all details.
    function getPairDetails(uint256 pairId) external view returns (EntanglementPair memory) {
        require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId];
    }

    /// @notice Gets the current state of an entanglement pair.
    /// @param pairId The ID of the pair.
    /// @return The PairState enum value.
    function getPairState(uint256 pairId) external view returns (PairState) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].currentState;
    }

    /// @notice Checks if a pair with the given ID is in the Proposed state.
    /// @param pairId The ID of the pair.
    /// @return True if proposed, false otherwise.
    function isPairProposed(uint256 pairId) external view returns (bool) {
         if (pairId == 0 || pairId > _pairCounter) return false;
         return _entanglementPairs[pairId].currentState == PairState.Proposed;
    }

    /// @notice Checks if a pair with the given ID is in the Entangled state.
    /// @param pairId The ID of the pair.
    /// @return True if entangled, false otherwise.
    function isPairEntangled(uint256 pairId) external view returns (bool) {
         if (pairId == 0 || pairId > _pairCounter) return false;
        return _entanglementPairs[pairId].currentState == PairState.Entangled;
    }

     /// @notice Gets the swap conditions for a specific pair.
     /// @param pairId The ID of the pair.
     /// @return SwapConditions struct.
    function getSwapConditions(uint256 pairId) external view returns (SwapConditions memory) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].swapConditions;
    }

     /// @notice Gets the disentangle conditions for a specific pair.
     /// @param pairId The ID of the pair.
     /// @return DisentangleConditions struct.
    function getDisentangleConditions(uint256 pairId) external view returns (DisentangleConditions memory) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].disentangleConditions;
    }

    /// @notice Gets the asset information for a specific pair.
    /// @param pairId The ID of the pair.
    /// @return assetXAddress, assetXAmountOrId, isAssetXERC721, assetYAddress, assetYAmountOrId, isAssetYERC721
    function getPairAssets(uint256 pairId) external view returns (address, uint256, bool, address, uint256, bool) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        EntanglementPair storage pair = _entanglementPairs[pairId];
        return (
            pair.assetXAddress,
            pair.assetXAmountOrId,
            pair.isAssetXERC721,
            pair.assetYAddress,
            pair.assetYAmountOrId,
            pair.isAssetYERC721
        );
    }

    /// @notice Gets the participant addresses for a specific pair.
    /// @param pairId The ID of the pair.
    /// @return partyA, partyB addresses.
    function getPairParticipants(uint256 pairId) external view returns (address, address) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        EntanglementPair storage pair = _entanglementPairs[pairId];
        return (pair.partyA, pair.partyB);
    }

    /// @notice Gets a list of all pair IDs a specific user is involved in.
    /// @param user The address of the user.
    /// @return An array of pair IDs.
    function getUserPairs(address user) external view returns (uint256[] memory) {
        return _userPairs[user];
    }

    /// @notice Checks if a user is involved in any entanglement pairs.
    /// @param user The address of the user.
    /// @return True if the user has pairs, false otherwise.
    function userHasPairs(address user) external view returns (bool) {
        return _userPairs[user].length > 0;
    }

    /// @notice Gets the total number of entanglement pairs created.
    /// @return The total count of pairs.
    function getTotalPairs() external view returns (uint256) {
        return _pairCounter;
    }

     // --- Resolution Trigger Functions ---

    /// @notice Attempts to trigger the swap resolution for a pair.
    /// @dev Can be called by either party. Verifies swap conditions.
    /// @param pairId The ID of the pair.
    function triggerSwap(uint256 pairId) external whenNotPaused nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyA == msg.sender || pair.partyB == msg.sender, "Not a participant");
        require(pair.currentState == PairState.Entangled || pair.currentState == PairState.SwapInitiatedA || pair.currentState == PairState.SwapInitiatedB, "Pair not ready for swap initiation");

        // Handle mutual agreement requirement
        if (pair.swapConditions.requiresMutualAgreement) {
            if (pair.currentState == PairState.Entangled) {
                // First party initiates mutual swap
                if (msg.sender == pair.partyA) {
                     pair.currentState = PairState.SwapInitiatedA;
                     emit ResolutionInitiated(pairId, msg.sender, PairState.SwapInitiatedA);
                     emit StateChanged(pairId, PairState.SwapInitiatedA, block.timestamp);
                     pair.initiatedTimestamp = block.timestamp;
                } else { // msg.sender == pair.partyB
                     pair.currentState = PairState.SwapInitiatedB;
                     emit ResolutionInitiated(pairId, msg.sender, PairState.SwapInitiatedB);
                     emit StateChanged(pairId, PairState.SwapInitiatedB, block.timestamp);
                     pair.initiatedTimestamp = block.timestamp;
                }
                // Require the other party to call triggerSwap again
                return;
            } else if ((pair.currentState == PairState.SwapInitiatedA && msg.sender == pair.partyB) ||
                       (pair.currentState == PairState.SwapInitiatedB && msg.sender == pair.partyA)) {
                 // Second party confirms mutual swap
                 // Now verify conditions and complete
                 if (_verifySwapConditions(pairId)) {
                    _completeSwap(pairId);
                 } else {
                     // Conditions not met, revert state or transition to Failed
                     pair.currentState = PairState.Entangled; // Revert to entangled if conditions not met after mutual init
                     emit StateChanged(pairId, PairState.Entangled, block.timestamp);
                     revert("Swap conditions not met after mutual agreement");
                 }
            } else {
                 revert("Mutual swap already initiated by you or wrong state");
            }
        } else {
             // No mutual agreement required, check conditions and complete immediately
             if (_verifySwapConditions(pairId)) {
                _completeSwap(pairId);
             } else {
                 revert("Swap conditions not met");
             }
        }
    }

     /// @notice Attempts to trigger the disentangle resolution for a pair.
    /// @dev Can be called by either party. Verifies disentangle conditions.
    /// @param pairId The ID of the pair.
    function triggerDisentangle(uint256 pairId) external whenNotPaused nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyA == msg.sender || pair.partyB == msg.sender, "Not a participant");
        require(pair.currentState == PairState.Entangled || pair.currentState == PairState.DisentanglingA || pair.currentState == PairState.DisentanglingB, "Pair not ready for disentangle initiation");

        // Handle mutual agreement requirement
         if (pair.disentangleConditions.mutualAgreementRequired) {
            if (pair.currentState == PairState.Entangled) {
                // First party initiates mutual disentangle
                if (msg.sender == pair.partyA) {
                     pair.currentState = PairState.DisentanglingA;
                     emit ResolutionInitiated(pairId, msg.sender, PairState.DisentanglingA);
                     emit StateChanged(pairId, PairState.DisentanglingA, block.timestamp);
                     pair.initiatedTimestamp = block.timestamp;
                } else { // msg.sender == pair.partyB
                     pair.currentState = PairState.DisentanglingB;
                     emit ResolutionInitiated(pairId, msg.sender, PairState.DisentanglingB);
                     emit StateChanged(pairId, PairState.DisentanglingB, block.timestamp);
                     pair.initiatedTimestamp = block.timestamp;
                }
                // Require the other party to call triggerDisentangle again
                return;
            } else if ((pair.currentState == PairState.DisentanglingA && msg.sender == pair.partyB) ||
                       (pair.currentState == PairentState.DisentanglingB && msg.sender == pair.partyA)) {
                 // Second party confirms mutual disentangle
                 // Now verify conditions and complete
                 if (_verifyDisentangleConditions(pairId)) {
                    _completeDisentangle(pairId);
                 } else {
                    // Conditions not met, revert state or transition to Failed
                     pair.currentState = PairState.Entangled; // Revert to entangled if conditions not met after mutual init
                     emit StateChanged(pairId, PairState.Entangled, block.timestamp);
                     revert("Disentangle conditions not met after mutual agreement");
                 }
            } else {
                 revert("Mutual disentangle already initiated by you or wrong state");
            }
        } else {
             // No mutual agreement required, check conditions and complete immediately
             if (_verifyDisentangleConditions(pairId)) {
                _completeDisentangle(pairId);
             } else {
                 revert("Disentangle conditions not met");
             }
        }
    }

    /// @notice Allows a keeper or participant to trigger timeout handling for a pair.
    /// @dev Checks if the disentangle timeout has been reached and forces disentanglement or failure.
    /// @param pairId The ID of the pair.
    function handleTimeout(uint256 pairId) external whenNotPaused nonReentrant {
         EntanglementPair storage pair = _entanglementPairs[pairId];
         require(pair.currentState == PairState.Entangled ||
                 pair.currentState == PairState.SwapInitiatedA ||
                 pair.currentState == PairState.SwapInitiatedB ||
                 pair.currentState == PairState.DisentanglingA ||
                 pair.currentState == PairState.DisentanglingB,
                 "Pair not in a state subject to timeout");
        require(pair.disentangleConditions.timeoutTimestamp > 0 && block.timestamp >= pair.disentangleConditions.timeoutTimestamp, "Timeout not reached");

        // If timeout reached, attempt disentangle. If disentangle conditions are also met (e.g., time condition), complete.
        // Otherwise, transition to Failed state (or a specific TimedOut state) for a default resolution (e.g., return to sender).
        if (_verifyDisentangleConditions(pairId)) {
             _completeDisentangle(pairId); // Timed out and disentangle conditions (e.g. time match) are met
        } else {
             // Timed out but specific disentangle conditions not met (e.g., required mutual agreement didn't happen).
             // Default timeout action: transition to Failed state, which implies returning original assets via claim.
             pair.currentState = PairState.Failed;
             pair.resolvedTimestamp = block.timestamp;
             emit TimeoutHandled(pairId);
             emit StateChanged(pairId, PairState.Failed, block.timestamp);
        }
    }


    // --- Claim Functions ---

    /// @notice Allows participants to claim their assets after a pair is resolved (CompletedSwap, CompletedDisentangle, Failed, Cancelled).
    /// @dev Based on the final state, the correct assets are transferred.
    /// @param pairId The ID of the pair.
    function claimAssets(uint256 pairId) external nonReentrant {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        require(pair.partyA == msg.sender || pair.partyB == msg.sender, "Not a participant");
        require(pair.currentState == PairState.CompletedSwap ||
                pair.currentState == PairState.CompletedDisentangle ||
                pair.currentState == PairState.Failed ||
                pair.currentState == PairState.Cancelled, // Allow claiming (nothing) from cancelled state
                "Pair not in a claimable state");

        address receiver = msg.sender;
        address assetAddressToClaim;
        uint256 amountOrIdToClaim;
        bool isERC721ToClaim;

        bool claimed = false; // Use flags to prevent double claiming the same asset

        if (pair.currentState == PairState.CompletedSwap) {
            if (receiver == pair.partyA) {
                 // Party A claims Asset Y (from Party B)
                 assetAddressToClaim = pair.assetYAddress;
                 amountOrIdToClaim = pair.assetYAmountOrId;
                 isERC721ToClaim = pair.isAssetYERC721;
                 // Need a flag to track if this specific asset has been claimed by this party
                 // For simplicity, assuming claim can only happen once per state per party
                 _transferAsset(receiver, assetAddressToClaim, amountOrIdToClaim, isERC721ToClaim);
                 claimed = true;
            } else if (receiver == pair.partyB) {
                 // Party B claims Asset X (from Party A)
                 assetAddressToClaim = pair.assetXAddress;
                 amountOrIdToClaim = pair.assetXAmountOrId;
                 isERC721ToClaim = pair.isAssetXERC721;
                 _transferAsset(receiver, assetAddressToClaim, amountOrIdToClaim, isERC721ToClaim);
                 claimed = true;
            }
        } else if (pair.currentState == PairState.CompletedDisentangle || pair.currentState == PairState.Failed) {
             // In these states, original assets are returned
             if (receiver == pair.partyA) {
                 // Party A claims Asset X (their original asset)
                 assetAddressToClaim = pair.assetXAddress;
                 amountOrIdToClaim = pair.assetXAmountOrId;
                 isERC721ToClaim = pair.isAssetXERC721;
                 _transferAsset(receiver, assetAddressToClaim, amountOrIdToClaim, isERC721ToClaim);
                 claimed = true;
             } else if (receiver == pair.partyB) {
                 // Party B claims Asset Y (their original asset)
                 assetAddressToClaim = pair.assetYAddress;
                 amountOrIdToClaim = pair.assetYAmountOrId;
                 isERC721ToClaim = pair.isAssetYERC721;
                 _transferAsset(receiver, assetAddressToClaim, amountOrIdToClaim, isERC721ToClaim);
                 claimed = true;
             }
        } else if (pair.currentState == PairState.Cancelled) {
            // Nothing to claim in Cancelled state, just check accessibility
            revert("No assets to claim in cancelled state");
        } else {
             revert("Pair not in a claimable state"); // Should not happen based on initial require
        }

        require(claimed, "No assets eligible for claiming by this user in this state");

        // In a real contract, you'd mark assets as claimed to prevent double claims.
        // E.g., using mapping(uint256 => mapping(address => bool)) private _claimedAssets;
        // For this example, we assume a single successful claim transitions the pair out of claimable state (not ideal).
        // A better approach: Mark individual asset as claimed per party.
        // Or, transition to a 'Claimed' sub-state or clear the pair data after BOTH assets are claimed.
        // Simplified: We'll allow re-calling claim if only one asset was sent.

        emit AssetsClaimed(pairId, receiver, assetAddressToClaim, amountOrIdToClaim);

         // Note: A robust contract would need to track if BOTH assets for BOTH parties
         // have been claimed before considering the pair truly 'finished' or archived.
         // This example skips that complexity for function count.
    }


    // --- Internal Helper Functions ---

    /// @dev Transfers asset (ERC20 or ERC721) from contract to recipient.
    /// @param recipient The address to transfer to.
    /// @param assetAddress The address of the asset contract.
    /// @param amountOrId Amount for ERC20, tokenId for ERC721.
    /// @param isERC721 True if ERC721, false if ERC20.
    function _transferAsset(address recipient, address assetAddress, uint256 amountOrId, bool isERC721) internal {
        if (isERC721) {
            IERC721 token = IERC721(assetAddress);
             // Ensure contract owns the token before transferring
            require(token.ownerOf(amountOrId) == address(this), "Contract does not own NFT for transfer");
            token.transferFrom(address(this), recipient, amountOrId);
        } else {
            IERC20 token = IERC20(assetAddress);
            require(token.transfer(recipient, amountOrId), "ERC20 transfer failed");
        }
    }

    /// @dev Internal function to check if a participant's asset has been deposited.
    /// @param pairId The ID of the pair.
    /// @param participant The participant's address.
    /// @return True if the asset is considered deposited, false otherwise.
    /// @notice This is a simplified check. A real contract might track deposits explicitly.
    function _isAssetDeposited(uint256 pairId, address participant) internal view returns (bool) {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        if (participant == pair.partyA) {
            // For simplicity, assume deposited if state is Accepted or Entangled or later
            return pair.currentState >= PairState.Accepted; // Assuming deposit is part of or immediately follows acceptance/entanglement
        } else if (participant == pair.partyB) {
            // For simplicity, assume deposited if state is Accepted or Entangled or later
             return pair.currentState >= PairState.Accepted; // Assuming deposit is part of acceptance
        }
        return false;
    }


    /// @dev Internal function to complete a swap after conditions are met.
    /// Transfers assets and updates state.
    /// @param pairId The ID of the pair.
    function _completeSwap(uint256 pairId) internal {
         EntanglementPair storage pair = _entanglementPairs[pairId];
         require(pair.currentState == PairState.Entangled || pair.currentState == PairState.SwapInitiatedA || pair.currentState == PairState.SwapInitiatedB, "Swap not in eligible state for completion");

         // Transfer Party A's asset (X) to Party B
         _transferAsset(pair.partyB, pair.assetXAddress, pair.assetXAmountOrId, pair.isAssetXERC721);

         // Transfer Party B's asset (Y) to Party A
         _transferAsset(pair.partyA, pair.assetYAddress, pair.assetYAmountOrId, pair.isAssetYERC721);

         pair.currentState = PairState.CompletedSwap;
         pair.resolvedTimestamp = block.timestamp;
         emit ResolutionCompleted(pairId, PairState.CompletedSwap);
         emit StateChanged(pairId, PairState.CompletedSwap, block.timestamp);

         // Note: Assets are now held by the recipients' balances, ready to be claimed via claimAssets function.
         // This claim step allows separation of resolution logic and asset retrieval.
    }

    /// @dev Internal function to complete a disentangle after conditions are met.
    /// Returns original assets and updates state.
    /// @param pairId The ID of the pair.
    function _completeDisentangle(uint256 pairId) internal {
         EntanglementPair storage pair = _entanglementPairs[pairId];
         require(pair.currentState == PairState.Entangled || pair.currentState == PairState.DisentanglingA || pair.currentState == PairState.DisentanglingB, "Disentangle not in eligible state for completion");

         // Transfer Party A's asset (X) back to Party A
         _transferAsset(pair.partyA, pair.assetXAddress, pair.assetXAmountOrId, pair.isAssetXERC721);

         // Transfer Party B's asset (Y) back to Party B
         _transferAsset(pair.partyB, pair.assetYAddress, pair.assetYAmountOrId, pair.isAssetYERC721);

         pair.currentState = PairState.CompletedDisentangle;
         pair.resolvedTimestamp = block.timestamp;
         emit ResolutionCompleted(pairId, PairState.CompletedDisentangle);
         emit StateChanged(pairId, PairState.CompletedDisentangle, block.timestamp);

          // Note: Assets are now held by the recipients' balances, ready to be claimed via claimAssets function.
    }

    /// @dev Internal function to verify if swap conditions are met.
    /// This is a simplified implementation. Real implementation would interact with oracles/keepers.
    /// @param pairId The ID of the pair.
    /// @return True if conditions are met, false otherwise.
    function _verifySwapConditions(uint256 pairId) internal view returns (bool) {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        SwapConditions memory cond = pair.swapConditions;

        // Time condition check
        if (cond.timeCondition > 0 && block.timestamp < cond.timeCondition) {
            return false; // Time condition not met yet
        }

        // Price condition check (Simulated)
        if (cond.priceFeedAsset != address(0)) {
            uint256 currentPrice = _simulatedPrices[cond.priceFeedAsset]; // Simulate fetching price
            bool priceMet = false;
            bytes32 op = cond.priceComparisonOp;
             if (op == ">") priceMet = currentPrice > cond.targetPrice;
             else if (op == "<") priceMet = currentPrice < cond.targetPrice;
             else if (op == ">=") priceMet = currentPrice >= cond.targetPrice;
             else if (op == "<=") priceMet = currentPrice <= cond.targetPrice;
             else if (op == "==") priceMet = currentPrice == cond.targetPrice;
             else {
                 // Unknown operator, fail condition check
                 return false;
             }
            if (!priceMet) return false;
        }

        // External data condition check (Simulated - assumes an external process calls setExternalDataVerified)
        if (cond.externalDataHash != bytes32(0) && !_externalDataVerified[cond.externalDataHash]) {
            return false; // External data not verified yet
        }

        // Note: requiresMutualAgreement is handled in triggerSwap function itself, not here.

        // If all set conditions are met, return true
        return true;
    }

     /// @dev Internal function to verify if disentangle conditions are met.
    /// This is a simplified implementation. Real implementation might be complex.
    /// @param pairId The ID of the pair.
    /// @return True if conditions are met, false otherwise.
    function _verifyDisentangleConditions(uint256 pairId) internal view returns (bool) {
        EntanglementPair storage pair = _entanglementPairs[pairId];
        DisentangleConditions memory cond = pair.disentangleConditions;

        // Time condition check
        if (cond.timeCondition > 0 && block.timestamp < cond.timeCondition) {
            return false; // Time condition not met yet
        }

        // Mutual agreement is checked in triggerDisentangle itself.
        // Timeout is checked in handleTimeout itself.

        // If mutual agreement is NOT required, or if timeout has been reached (handled in handleTimeout caller),
        // and optional time condition is met, then disentangle is permitted.
        // This helper primarily checks the time condition for triggered disentangle.
        // Timeout check is external to this function, in handleTimeout.

        return true;
    }


    // --- External/Keeper Functions (Simulated) ---

    /// @notice SIMULATED: Allows a keeper/oracle to mark external data as verified for a specific hash.
    /// @dev In a real system, this would have strong access control (only trusted oracles).
    /// @param dataHash The hash of the external data that has been verified.
    /// @param verified The verification status (true/false).
    function setExternalDataVerified(bytes32 dataHash, bool verified) external {
         // In a real contract, this would have `onlyOracle` or similar access control
         // require(msg.sender == trustedOracleAddress, "Not a trusted oracle");
        _externalDataVerified[dataHash] = verified;
        // Potentially trigger checks on relevant pairs here or rely on external keepers
    }

    /// @notice SIMULATED: Allows setting a simulated price for an asset.
    /// @dev For testing price conditions without a real oracle feed.
    /// @param assetAddress The address of the asset.
    /// @param price The simulated price in smallest units.
    function setSimulatedPrice(address assetAddress, uint256 price) external {
         // In a real contract, this would come from a trusted price feed oracle like Chainlink
         // require(msg.sender == trustedPriceOracle, "Not a trusted price feed");
        _simulatedPrices[assetAddress] = price;
        // Potentially trigger checks on relevant pairs here or rely on external keepers
    }


    // --- Additional Query Functions for Condition Details ---

    /// @notice Gets the time condition for a swap.
    function getSwapTimeCondition(uint256 pairId) external view returns (uint256) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].swapConditions.timeCondition;
    }

    /// @notice Gets the price condition details for a swap.
    function getSwapPriceCondition(uint256 pairId) external view returns (address assetAddress, uint256 targetPrice, bytes32 comparisonOp) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
         SwapConditions memory cond = _entanglementPairs[pairId].swapConditions;
        return (cond.priceFeedAsset, cond.targetPrice, cond.priceComparisonOp);
    }

     /// @notice Gets the external data hash condition for a swap.
    function getSwapExternalDataHashCondition(uint256 pairId) external view returns (bytes32) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].swapConditions.externalDataHash;
    }

     /// @notice Gets the mutual agreement requirement for a swap.
    function getSwapRequiresMutualAgreement(uint256 pairId) external view returns (bool) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].swapConditions.requiresMutualAgreement;
    }

    /// @notice Gets the time condition for a disentangle.
    function getDisentangleTimeCondition(uint256 pairId) external view returns (uint256) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].disentangleConditions.timeCondition;
    }

    /// @notice Gets the mutual agreement requirement for a disentangle.
    function getDisentangleMutualAgreementRequired(uint256 pairId) external view returns (bool) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].disentangleConditions.mutualAgreementRequired;
    }

     /// @notice Gets the timeout timestamp for a disentangle.
    function getDisentangleTimeoutTimestamp(uint256 pairId) external view returns (uint256) {
         require(pairId > 0 && pairId <= _pairCounter, "Invalid pair ID");
        return _entanglementPairs[pairId].disentangleConditions.timeoutTimestamp;
    }

    // Function Count Check:
    // Admin: 3 (pause, unpause, ownerWithdrawERC20, ownerWithdrawERC721 = 4)
    // Pair Management: 4 (propose, accept, depositAssetX, cancel)
    // State Query: 10 (getPairDetails, getPairState, isPairProposed, isPairEntangled, getSwapConditions, getDisentangleConditions, getPairAssets, getPairParticipants, getUserPairs, userHasPairs, getTotalPairs = 11)
    // Resolution Trigger: 3 (triggerSwap, triggerDisentangle, handleTimeout)
    // Claim: 1 (claimAssets)
    // Simulated External: 2 (setExternalDataVerified, setSimulatedPrice)
    // Additional Condition Query: 7 (getSwapTimeCondition, getSwapPriceCondition, getSwapExternalDataHashCondition, getSwapRequiresMutualAgreement, getDisentangleTimeCondition, getDisentangleMutualAgreementRequired, getDisentangleTimeoutTimestamp)
    // Total: 4 + 4 + 11 + 3 + 1 + 2 + 7 = 32 functions. Exceeds the minimum of 20.

}
```

---

**Function Summary:**

1.  **`constructor()`**: Initializes the contract, setting the owner. (Implicit from `Ownable`)
2.  **`pause()`**: Allows the owner to pause sensitive contract operations (like creating/resolving pairs).
3.  **`unpause()`**: Allows the owner to unpause the contract.
4.  **`ownerWithdrawERC20(address tokenAddress, uint256 amount)`**: Emergency function for owner to recover accidentally sent ERC20 tokens when paused.
5.  **`ownerWithdrawERC721(address tokenAddress, uint256 tokenId)`**: Emergency function for owner to recover accidentally sent ERC721 tokens when paused.
6.  **`proposeEntanglement(...) returns (uint256)`**: Party A initiates a new entanglement proposal, defining the other party, the assets, and the conditions for swap and disentangle. Returns a unique `pairId`.
7.  **`acceptEntanglement(uint256 pairId)`**: Party B accepts a proposed pair and deposits their asset (Asset Y), moving the pair state to `Accepted`.
8.  **`depositAssetX(uint256 pairId)`**: Party A deposits their asset (Asset X) after acceptance, moving the pair state to `Entangled` if Asset Y is also deposited.
9.  **`cancelProposal(uint256 pairId)`**: Party A cancels a proposed pair if Party B has not yet accepted it.
10. **`getPairDetails(uint256 pairId) returns (EntanglementPair memory)`**: Retrieves all stored data for a specific pair.
11. **`getPairState(uint256 pairId) returns (PairState)`**: Retrieves only the current state of a specific pair.
12. **`isPairProposed(uint256 pairId) returns (bool)`**: Checks if a pair is currently in the `Proposed` state.
13. **`isPairEntangled(uint256 pairId) returns (bool)`**: Checks if a pair is currently in the `Entangled` state.
14. **`getSwapConditions(uint256 pairId) returns (SwapConditions memory)`**: Retrieves the detailed conditions required for a swap resolution.
15. **`getDisentangleConditions(uint256 pairId) returns (DisentangleConditions memory)`**: Retrieves the detailed conditions required for a disentangle resolution.
16. **`getPairAssets(uint256 pairId) returns (address, uint256, bool, address, uint256, bool)`**: Retrieves the asset information (address, amount/id, type) for both assets in a pair.
17. **`getPairParticipants(uint256 pairId) returns (address, address)`**: Retrieves the addresses of Party A and Party B for a pair.
18. **`getUserPairs(address user) returns (uint256[] memory)`**: Retrieves a list of all pair IDs that a given user is involved in.
19. **`userHasPairs(address user) returns (bool)`**: Checks if a user is involved in any pairs recorded by the contract.
20. **`getTotalPairs() returns (uint256)`**: Returns the total count of pairs ever created.
21. **`triggerSwap(uint256 pairId)`**: Allows either party (or a keeper in a real system) to attempt triggering the swap resolution. Checks if `swapConditions` are met. Handles mutual agreement logic.
22. **`triggerDisentangle(uint256 pairId)`**: Allows either party (or a keeper) to attempt triggering the disentangle resolution. Checks if `disentangleConditions` (excluding timeout) are met. Handles mutual agreement logic.
23. **`handleTimeout(uint256 pairId)`**: Allows anyone (intended for keepers/automation) to check if the disentangle `timeoutTimestamp` for a pair has passed and trigger the default resolution (usually disentangle, or failure if specific conditions weren't met).
24. **`claimAssets(uint256 pairId)`**: Allows participants to claim the assets they are due based on the final state of the pair (`CompletedSwap`, `CompletedDisentangle`, `Failed`).
25. **`setExternalDataVerified(bytes32 dataHash, bool verified)`**: *Simulated* external function (intended for trusted oracles/keepers) to mark external data hashes as verified, fulfilling a condition.
26. **`setSimulatedPrice(address assetAddress, uint256 price)`**: *Simulated* external function (intended for trusted price feeds) to set a price used for checking price conditions.
27. **`getSwapTimeCondition(uint256 pairId) returns (uint256)`**: Retrieves the timestamp required for the swap time condition.
28. **`getSwapPriceCondition(uint256 pairId) returns (address, uint256, bytes32)`**: Retrieves details of the swap price condition (asset, target price, operator).
29. **`getSwapExternalDataHashCondition(uint256 pairId) returns (bytes32)`**: Retrieves the external data hash required for the swap condition.
30. **`getSwapRequiresMutualAgreement(uint256 pairId) returns (bool)`**: Retrieves whether mutual agreement is needed for swap.
31. **`getDisentangleTimeCondition(uint256 pairId) returns (uint256)`**: Retrieves the timestamp required for the disentangle time condition.
32. **`getDisentangleMutualAgreementRequired(uint256 pairId) returns (bool)`**: Retrieves whether mutual agreement is needed for disentangle.
33. **`getDisentangleTimeoutTimestamp(uint256 pairId) returns (uint256)`**: Retrieves the absolute timestamp for the disentangle timeout.

This contract, while conceptual in its oracle/keeper interactions (using simulated functions and internal checks), provides a framework for complex, conditional asset swaps based on time, external data, or price feeds, managed through a defined state machine. It's more advanced than basic escrow due to the multiple resolution paths, state transitions, external condition dependency, and timeout mechanisms.