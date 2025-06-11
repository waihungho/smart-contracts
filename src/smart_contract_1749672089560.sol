Okay, this sounds like a fun challenge! Let's design a smart contract around a creative, advanced concept that isn't a direct copy of standard open-source patterns.

Let's build a contract called "Quantum Vault" that allows users to deposit ETH, ERC-20, and ERC-721 tokens. The twist is that the assets held within the vault exist in different "quantum states" that affect their unlockability and potential interactions.

**Concept:**

Assets deposited into the vault enter a complex state machine simulating (metaphorically) quantum states like Superposition, Entanglement, and Decoherence. Unlocking assets depends on their current state, time elapsed, potential interactions with other assets (entanglement), and even probabilistic "observation" effects.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A multi-asset vault with state-dependent and probabilistic unlocking mechanisms,
 *      simulating (metaphorically) quantum states like Superposition, Entanglement,
 *      and Decoherence. Allows depositing ETH, ERC-20, and ERC-721 tokens.
 *      Assets have states that change over time and through interactions,
 *      affecting withdrawal conditions. Includes concepts like asset entanglement.
 *
 * Outline:
 * 1. State Definitions (Enums)
 * 2. Data Structures (Structs) for Deposited Assets
 * 3. Contract State Variables (Owner, Asset Registry, User Vaults, Configurations)
 * 4. Events for State Changes and Actions
 * 5. Modifiers for Access Control and State Checks
 * 6. Core Deposit Functions (ETH, ERC20, ERC721)
 * 7. Core Withdrawal/Interaction Functions (Attempt Observation & Withdraw, Collapse Superposition)
 * 8. State Management Functions (Process Decay, Attempt Superposition)
 * 9. Entanglement Functions (Propose, Accept, Break, Trigger Effects, Strength)
 * 10. View Functions (Get Asset Details, Vault Summary, State History, Eligibility, Possible States)
 * 11. Configuration Functions (Owner-only settings)
 * 12. Helper Functions (Internal logic)
 *
 * Function Summary:
 * - Constructor: Sets contract owner.
 * - depositETH: Deposits ETH into the user's vault, creates a Superposed asset entry.
 * - depositERC20: Deposits ERC20 tokens, creates a Superposed asset entry.
 * - depositERC721: Deposits ERC721 token, creates a Superposed asset entry.
 * - attemptObservationAndWithdraw: The primary function to attempt unlocking/withdrawing an asset.
 *   Checks state, time, probabilistic factors, and entanglement before allowing withdrawal.
 *   May trigger an 'observation effect' state change if withdrawal fails.
 * - collapseSuperposition: Allows user to force an asset out of Superposed state towards Collapsed,
 *   potentially requiring a cost or time.
 * - processAssetDecay: Can be called (potentially by anyone) to advance the state
 *   of an asset (e.g., Decohering over time).
 * - attemptStateSuperposition: Allows user to try and revert a Decohering/Collapsed asset back
 *   towards a Superposed state, maybe for re-locking or re-entanglement. Probabilistic chance.
 * - proposeEntanglement: User proposes to entangle one of their assets with another user's asset.
 * - acceptEntanglement: Target user accepts an entanglement proposal. Links assets, sets state to Entangled.
 * - breakEntanglement: Either party can break an existing entanglement. Assets transition to Decohering.
 * - triggerEntangledEffect: Internal/called function. When an entangled asset changes state or is withdrawn,
 *   this function might apply an effect to its entangled partner.
 * - getEntanglementStrength: View function returning a metric/status about an entanglement link.
 * - getUserVaultSummary: View function providing an overview of all assets held by a user.
 * - getAssetDetails: View function for detailed info about a specific deposited asset ID.
 * - getEntanglementStatus: View function for the status of a specific entanglement proposal/link.
 * - getAssetCurrentState: View function returning the current quantum state of an asset.
 * - checkAssetUnlockEligibility: View function predicting if an asset is likely unlockable *without*
 *   triggering the observation effect. Useful for UI.
 * - getPossibleNextStates: View function suggesting possible future states for an asset based on rules.
 * - getAllUserAssetIds: View function listing all asset IDs owned by a user.
 * - setDecoherenceRate: Owner function to adjust the time duration for Decohering state.
 * - setObservationEffectProbability: Owner function to adjust the chance of state change on failed withdrawal attempt.
 * - setEntanglementCost: Owner function to set a potential cost for proposing/breaking entanglement.
 * - pauseVaultOperation: Owner function to pause critical vault operations (deposits/withdrawals).
 * - unpauseVaultOperation: Owner function to unpause operations.
 * - withdrawContractBalance: Owner function to withdraw accidental ETH sent to the contract (excluding vaulted ETH).
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract QuantumVault is Ownable, ERC721Holder, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // 1. State Definitions
    enum AssetType { ETH, ERC20, ERC721 }
    enum QuantumState {
        Superposed,     // Difficult to unlock, time decay begins
        Entangled,      // Linked to another asset, unlock depends on partner
        Decohering,     // State is collapsing over time, getting easier to unlock
        Collapsed,      // Fully decohered, easily unlockable after minimal time
        Withdrawn       // Asset has been successfully withdrawn
    }

    // 2. Data Structures
    struct DepositedAsset {
        uint256 assetId;
        AssetType assetType;
        address tokenAddress; // Zero address for ETH
        uint256 tokenId;      // Zero for ETH/ERC20
        uint256 amountOrId;   // Amount for ETH/ERC20, TokenId for ERC721 (duplicate of tokenId for ERC721 for clarity/usage)
        address owner;
        uint48 depositTimestamp;
        QuantumState currentState;
        uint48 stateEntryTimestamp;
        uint256 entangledAssetId; // 0 if not entangled
        bool exists;          // To check if an assetId is valid
    }

    // 3. Contract State Variables
    uint256 private _nextAssetId = 1;
    mapping(uint256 => DepositedAsset) public depositedAssets; // Global registry of all assets
    mapping(address => uint256[]) private _userAssetIds;       // Map user to their asset IDs

    // Entanglement proposals: Proposer's assetId => Target's assetId
    mapping(uint256 => uint256) public entanglementProposals;

    // Configuration parameters (Owner settable)
    uint256 public superpositionDecayDuration = 30 days; // Time for Superposed to decay towards Decohering
    uint224 public decoherenceDuration = 60 days;       // Time for Decohering to reach Collapsed state
    uint16 public observationEffectProbability = 10;    // Probability (out of 100) of state change on failed withdrawal attempt
    uint256 public entanglementCost = 0;                 // Cost to propose/break entanglement (in wei)
    uint24 public minSuperpositionTime = 7 days;        // Minimum time before Superposed can potentially be unlocked/decay
    uint24 public minDecoherenceTime = 1 days;          // Minimum time before Decohering can potentially be unlocked
    uint24 public minCollapsedTime = 0 days;            // Minimum time for Collapsed state (effectively instant after state reached)


    // 4. Events
    event AssetDeposited(uint256 indexed assetId, AssetType indexed assetType, address indexed owner, address tokenAddress, uint256 amountOrId, QuantumState initialState);
    event AssetWithdrawn(uint256 indexed assetId, address indexed owner, QuantumState finalState);
    event AssetStateChanged(uint256 indexed assetId, QuantumState indexed oldState, QuantumState indexed newState, string reason);
    event EntanglementProposed(uint256 indexed proposerAssetId, uint256 indexed targetAssetId);
    event EntanglementAccepted(uint256 indexed asset1Id, uint256 indexed asset2Id);
    event EntanglementBroken(uint256 indexed asset1Id, uint256 indexed asset2Id, string reason);
    event ObservationEffectTriggered(uint256 indexed assetId, QuantumState indexed newState);
    event AssetDecayProcessed(uint256 indexed assetId, QuantumState indexed newState);

    // 5. Modifiers
    modifier onlyAssetOwner(uint256 _assetId) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        require(depositedAssets[_assetId].owner == msg.sender, "QV: Not asset owner");
        _;
    }

    modifier assetNotWithdrawn(uint256 _assetId) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        require(depositedAssets[_assetId].currentState != QuantumState.Withdrawn, "QV: Asset already withdrawn");
        _;
    }

    modifier assetsExist(uint256 _assetId1, uint256 _assetId2) {
        require(depositedAssets[_assetId1].exists, "QV: Asset 1 does not exist");
        require(depositedAssets[_assetId2].exists, "QV: Asset 2 does not exist");
        _;
    }

    // 6. Core Deposit Functions
    constructor() Ownable(msg.sender) {}

    receive() external payable {
        // Optional: Allow direct ETH deposits without specifying a vault.
        // Could create a 'default' vault entry or require depositETH explicitly.
        // For now, require depositETH. Add a check to prevent accidental sends if desired.
         require(msg.sender == address(this), "QV: Direct ETH sends not supported, use depositETH");
         // Reaching here means it's a self-call (e.g. transfer back to self) or withdrawal
         // Let's explicitly disable receive for unauthorized calls.
    }

    fallback() external payable {
        revert("QV: Fallback not supported");
    }


    /**
     * @dev Deposits ETH into the vault, creating a new asset entry in Superposed state.
     */
    function depositETH() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "QV: ETH amount must be greater than zero");

        uint256 newAssetId = _nextAssetId++;
        _userAssetIds[msg.sender].push(newAssetId);

        depositedAssets[newAssetId] = DepositedAsset({
            assetId: newAssetId,
            assetType: AssetType.ETH,
            tokenAddress: address(0),
            tokenId: 0,
            amountOrId: msg.value,
            owner: msg.sender,
            depositTimestamp: uint48(block.timestamp),
            currentState: QuantumState.Superposed,
            stateEntryTimestamp: uint48(block.timestamp),
            entangledAssetId: 0,
            exists: true
        });

        emit AssetDeposited(newAssetId, AssetType.ETH, msg.sender, address(0), msg.value, QuantumState.Superposed);
        emit AssetStateChanged(newAssetId, QuantumState.Superposed, QuantumState.Superposed, "Initial Deposit"); // Log initial state
    }

    /**
     * @dev Deposits ERC20 tokens into the vault, creating a new asset entry in Superposed state.
     * @param _tokenAddress Address of the ERC20 token.
     * @param _amount Amount of tokens to deposit.
     */
    function depositERC20(address _tokenAddress, uint256 _amount) external whenNotPaused nonReentrant {
        require(_tokenAddress != address(0), "QV: Token address cannot be zero");
        require(_amount > 0, "QV: Amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 transferredAmount = balanceAfter.sub(balanceBefore); // Handle potential transfer fees/amounts

        require(transferredAmount == _amount, "QV: Transfer amount mismatch or failed");

        uint256 newAssetId = _nextAssetId++;
        _userAssetIds[msg.sender].push(newAssetId);

        depositedAssets[newAssetId] = DepositedAsset({
            assetId: newAssetId,
            assetType: AssetType.ERC20,
            tokenAddress: _tokenAddress,
            tokenId: 0,
            amountOrId: transferredAmount,
            owner: msg.sender,
            depositTimestamp: uint48(block.timestamp),
            currentState: QuantumState.Superposed,
            stateEntryTimestamp: uint48(block.timestamp),
            entangledAssetId: 0,
            exists: true
        });

        emit AssetDeposited(newAssetId, AssetType.ERC20, msg.sender, _tokenAddress, transferredAmount, QuantumState.Superposed);
         emit AssetStateChanged(newAssetId, QuantumState.Superposed, QuantumState.Superposed, "Initial Deposit"); // Log initial state
    }

    /**
     * @dev Deposits ERC721 token into the vault, creating a new asset entry in Superposed state.
     * @param _tokenAddress Address of the ERC721 token.
     * @param _tokenId ID of the token to deposit.
     */
    function depositERC721(address _tokenAddress, uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_tokenAddress != address(0), "QV: Token address cannot be zero");

        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "QV: Not token owner");
        token.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 newAssetId = _nextAssetId++;
        _userAssetIds[msg.sender].push(newAssetId);

        depositedAssets[newAssetId] = DepositedAsset({
            assetId: newAssetId,
            assetType: AssetType.ERC721,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amountOrId: _tokenId, // Store tokenId here for consistent amountOrId field usage
            owner: msg.sender,
            depositTimestamp: uint48(block.timestamp),
            currentState: QuantumState.Superposed,
            stateEntryTimestamp: uint48(block.timestamp),
            entangledAssetId: 0,
            exists: true
        });

        emit AssetDeposited(newAssetId, AssetType.ERC721, msg.sender, _tokenAddress, _tokenId, QuantumState.Superposed);
        emit AssetStateChanged(newAssetId, QuantumState.Superposed, QuantumState.Superposed, "Initial Deposit"); // Log initial state
    }

    // 7. Core Withdrawal/Interaction Functions

    /**
     * @dev Attempts to unlock and withdraw an asset based on its current quantum state and conditions.
     *      May trigger a probabilistic 'observation effect' state change if withdrawal fails.
     * @param _assetId The ID of the asset to attempt withdrawal for.
     */
    function attemptObservationAndWithdraw(uint256 _assetId) external onlyAssetOwner(_assetId) assetNotWithdrawn(_assetId) nonReentrant {
        DepositedAsset storage asset = depositedAssets[_assetId];
        bool withdrawSuccessful = false;
        string memory reason = "Withdrawal Attempt Failed";

        uint256 timeInState = block.timestamp - asset.stateEntryTimestamp;
        uint256 timeSinceDeposit = block.timestamp - asset.depositTimestamp;

        if (asset.currentState == QuantumState.Collapsed) {
            // Collapsed state: Simple time check
            if (timeInState >= minCollapsedTime && timeSinceDeposit >= minCollapsedTime) {
                 withdrawSuccessful = true;
                 reason = "Collapsed State Unlocked";
            }
        } else if (asset.currentState == QuantumState.Decohering) {
            // Decohering state: Unlock probability increases with time in state
            uint256 unlockProbability = (timeInState * 100) / decoherenceDuration; // Max 100% after full decoherenceDuration
            if (timeInState >= minDecoherenceTime && _getDynamicRandomness(block.timestamp, _assetId, uint64(block.difficulty)) % 100 < unlockProbability) {
                 withdrawSuccessful = true;
                 reason = "Decohering State Probabilistic Unlock";
            } else {
                // Even if not unlocked, the state might progress based on time, handled by processAssetDecay
            }
        } else if (asset.currentState == QuantumState.Superposed) {
            // Superposed state: Requires minimum time and a specific probabilistic event
            if (timeSinceDeposit >= minSuperpositionTime) {
                 // Lower probability unlock from Superposed directly
                 uint256 directUnlockChance = 5; // Example: 5% chance after min time
                 if (_getDynamicRandomness(block.timestamp, _assetId, uint64(block.gasleft())) % 100 < directUnlockChance) {
                    withdrawSuccessful = true;
                    reason = "Superposed State Direct Probabilistic Unlock";
                 }
            }
             // Superposed state also decays towards Decohering over time, handled by processAssetDecay
        } else if (asset.currentState == QuantumState.Entangled) {
            // Entangled state: Unlocks if entangled partner is Collapsed or Withdrawn, AND THIS asset is Collapsed or meets conditions
            uint256 entangledId = asset.entangledAssetId;
            if (entangledId != 0 && depositedAssets[entangledId].exists) {
                QuantumState partnerState = depositedAssets[entangledId].currentState;
                // Example condition: Both must be in or reach Collapsed state
                if (asset.currentState == QuantumState.Collapsed && (partnerState == QuantumState.Collapsed || partnerState == QuantumState.Withdrawn)) {
                     withdrawSuccessful = true;
                     reason = "Entangled State Partner Collapsed";
                }
                // More complex entangled conditions could be added here
            } else {
                 // Should not happen if entanglement was set up correctly, but handle broken links
                 asset.currentState = QuantumState.Decohering;
                 asset.stateEntryTimestamp = uint48(block.timestamp);
                 emit AssetStateChanged(_assetId, QuantumState.Entangled, QuantumState.Decohering, "Entanglement Link Broken Unexpectedly");
            }
        }

        if (withdrawSuccessful) {
            _performWithdrawal(_assetId);
            // Trigger entangled effect IF it was Entangled before withdrawal
            if (asset.currentState == QuantumState.Entangled && asset.entangledAssetId != 0) { // Use asset.currentState as it was *before* setting to Withdrawn
                 _triggerEntangledEffect(asset.entangledAssetId, _assetId);
            }
        } else {
            // Observation Effect: Chance of changing state on failed attempt
            if (_getDynamicRandomness(block.timestamp, _assetId, uint64(block.gasprice())) % 100 < observationEffectProbability) {
                 _applyObservationEffect(_assetId);
                 emit ObservationEffectTriggered(_assetId, depositedAssets[_assetId].currentState);
            }
        }
    }

    /**
     * @dev Allows the owner of a Superposed asset to force it towards the Collapsed state sooner.
     *      Requires the asset to be in the Superposed state.
     * @param _assetId The ID of the asset to collapse.
     */
    function collapseSuperposition(uint256 _assetId) external onlyAssetOwner(_assetId) assetNotWithdrawn(_assetId) whenNotPaused {
        DepositedAsset storage asset = depositedAssets[_assetId];
        require(asset.currentState == QuantumState.Superposed, "QV: Asset is not in Superposed state");

        // Optionally require a payment or burn mechanism here
        // require(msg.value >= collapseCost, "QV: Insufficient funds to collapse superposition");

        _updateAssetState(_assetId, QuantumState.Collapsed, "Superposition Collapsed by Owner");
        // The asset is now in Collapsed state, subject to minCollapsedTime before withdrawal
    }


    // 8. State Management Functions

    /**
     * @dev Processes the time-based decay of an asset's state (e.g., Superposed -> Decohering, Decohering -> Collapsed).
     *      Can be called by anyone to help advance the state of a specific asset.
     *      Includes basic state transitions based on time elapsed in the current state.
     * @param _assetId The ID of the asset to process decay for.
     */
    function processAssetDecay(uint256 _assetId) external assetNotWithdrawn(_assetId) {
        DepositedAsset storage asset = depositedAssets[_assetId];
        uint256 timeInState = block.timestamp - asset.stateEntryTimestamp;
        QuantumState oldState = asset.currentState;

        if (asset.currentState == QuantumState.Superposed) {
            if (timeInState >= superpositionDecayDuration) {
                _updateAssetState(_assetId, QuantumState.Decohering, "Superposed Decay");
            }
        } else if (asset.currentState == QuantumState.Decohering) {
            if (timeInState >= decoherenceDuration) {
                _updateAssetState(_assetId, QuantumState.Collapsed, "Decohering to Collapsed");
            }
        }
        // Entangled state decay could be linked to partner or time
        // Collapsed state does not decay further

        if (asset.currentState != oldState) {
             emit AssetDecayProcessed(_assetId, asset.currentState);
             // Trigger entangled effect if state changed and it was entangled
             if (oldState == QuantumState.Entangled && asset.entangledAssetId != 0) {
                  _triggerEntangledEffect(asset.entangledAssetId, _assetId);
             }
        }
    }

    /**
     * @dev Allows a user to attempt to revert a Decohering or Collapsed asset back towards a Superposed state.
     *      This could be used to re-lock assets or make them eligible for new entanglement.
     *      This action is probabilistic.
     * @param _assetId The ID of the asset to attempt superposition for.
     */
    function attemptStateSuperposition(uint256 _assetId) external onlyAssetOwner(_assetId) assetNotWithdrawn(_assetId) whenNotPaused {
        DepositedAsset storage asset = depositedAssets[_assetId];
        require(asset.currentState == QuantumState.Decohering || asset.currentState == QuantumState.Collapsed,
                "QV: Asset is not in Decohering or Collapsed state");

        // Example: 30% chance to revert to Superposed, otherwise stays in current state
        uint256 superpositionChance = 30;
        if (_getDynamicRandomness(block.timestamp, _assetId, uint64(msg.sender % 1000)) % 100 < superpositionChance) {
             _updateAssetState(_assetId, QuantumState.Superposed, "Attempted Superposition Success");
        }
         // No explicit failure event if it stays the same state
    }


    // 9. Entanglement Functions

    /**
     * @dev Proposes to entangle one of the caller's assets with another user's asset.
     *      Requires assets to be in Superposed or Decohering state (cannot entangle Collapsed or already Entangled).
     * @param _proposerAssetId The caller's asset ID.
     * @param _targetAssetId The target user's asset ID.
     */
    function proposeEntanglement(uint256 _proposerAssetId, uint256 _targetAssetId) external payable onlyAssetOwner(_proposerAssetId) assetsExist(_proposerAssetId, _targetAssetId) whenNotPaused {
        require(msg.value >= entanglementCost, "QV: Insufficient entanglement cost");

        DepositedAsset storage proposerAsset = depositedAssets[_proposerAssetId];
        DepositedAsset storage targetAsset = depositedAssets[_targetAssetId];

        require(proposerAsset.owner != targetAsset.owner, "QV: Cannot entangle with own asset");
        require(proposerAsset.currentState == QuantumState.Superposed || proposerAsset.currentState == QuantumState.Decohering,
                "QV: Proposer asset must be Superposed or Decohering");
        require(targetAsset.currentState == QuantumState.Superposed || targetAsset.currentState == QuantumState.Decohering,
                "QV: Target asset must be Superposed or Decohering");
        require(proposerAsset.entangledAssetId == 0, "QV: Proposer asset already entangled");
        require(targetAsset.entangledAssetId == 0, "QV: Target asset already entangled");

        entanglementProposals[_proposerAssetId] = _targetAssetId;

        emit EntanglementProposed(_proposerAssetId, _targetAssetId);
    }

    /**
     * @dev Accepts an entanglement proposal made by another user for one of their assets.
     *      Requires the target asset owner to call this function.
     * @param _proposerAssetId The ID of the asset initiating the proposal.
     * @param _targetAssetId The ID of the caller's asset targeted by the proposal.
     */
    function acceptEntanglement(uint256 _proposerAssetId, uint256 _targetAssetId) external onlyAssetOwner(_targetAssetId) assetsExist(_proposerAssetId, _targetAssetId) whenNotPaused nonReentrant {
        require(entanglementProposals[_proposerAssetId] == _targetAssetId, "QV: No such entanglement proposal exists");

        DepositedAsset storage proposerAsset = depositedAssets[_proposerAssetId];
        DepositedAsset storage targetAsset = depositedAssets[_targetAssetId];

        require(proposerAsset.owner != targetAsset.owner, "QV: Cannot entangle with own asset"); // Double check
        require(proposerAsset.currentState == QuantumState.Superposed || proposerAsset.currentState == QuantumState.Decohering,
                "QV: Proposer asset must be Superposed or Decohering"); // State might have changed
        require(targetAsset.currentState == QuantumState.Superposed || targetAsset.currentState == QuantumState.Decohering,
                "QV: Target asset must be Superposed or Decohering"); // State might have changed
        require(proposerAsset.entangledAssetId == 0, "QV: Proposer asset already entangled"); // Double check
        require(targetAsset.entangledAssetId == 0, "QV: Target asset already entangled"); // Double check

        // Establish entanglement link in both directions
        proposerAsset.entangledAssetId = _targetAssetId;
        targetAsset.entangledAssetId = _proposerAssetId;

        // Set both assets to Entangled state
        _updateAssetState(_proposerAssetId, QuantumState.Entangled, "Entanglement Accepted");
        _updateAssetState(_targetAssetId, QuantumState.Entangled, "Entanglement Accepted");

        // Clear the proposal
        delete entanglementProposals[_proposerAssetId];

        emit EntanglementAccepted(_proposerAssetId, _targetAssetId);
    }

    /**
     * @dev Breaks an existing entanglement between two assets. Can be called by either owner.
     *      Assets transition to Decohering state upon breaking.
     * @param _asset1Id The ID of the first asset in the entangled pair.
     * @param _asset2Id The ID of the second asset in the entangled pair.
     */
    function breakEntanglement(uint256 _asset1Id, uint256 _asset2Id) external assetsExist(_asset1Id, _asset2Id) whenNotPaused {
        DepositedAsset storage asset1 = depositedAssets[_asset1Id];
        DepositedAsset storage asset2 = depositedAssets[_asset2Id];

        // Require caller owns one of the assets
        require(asset1.owner == msg.sender || asset2.owner == msg.sender, "QV: Caller must own one of the entangled assets");

        // Require they are actually entangled with each other
        require(asset1.entangledAssetId == _asset2Id && asset2.entangledAssetId == _asset1Id, "QV: Assets are not entangled with each other");
        require(asset1.currentState == QuantumState.Entangled && asset2.currentState == QuantumState.Entangled, "QV: Assets are not in Entangled state");
        require(asset1.currentState != QuantumState.Withdrawn && asset2.currentState != QuantumState.Withdrawn, "QV: One or both assets already withdrawn");

        // Clear entanglement link
        asset1.entangledAssetId = 0;
        asset2.entangledAssetId = 0;

        // Transition states to Decohering
        _updateAssetState(_asset1Id, QuantumState.Decohering, "Entanglement Broken");
        _updateAssetState(_asset2Id, QuantumState.Decohering, "Entanglement Broken");

        // Optional: Require cost here as well
        // require(msg.value >= entanglementCost, "QV: Insufficient entanglement cost");

        emit EntanglementBroken(_asset1Id, _asset2Id, "Requested by owner");
    }

     /**
      * @dev Internal function triggered when an entangled asset changes state or is withdrawn.
      *      Applies a potential effect to the entangled partner.
      *      Example: If partner is withdrawn, force this asset to Collapsed state.
      * @param _partnerAssetId The ID of the entangled partner asset.
      * @param _triggeringAssetId The ID of the asset whose state changed/was withdrawn.
      */
    function _triggerEntangledEffect(uint256 _partnerAssetId, uint256 _triggeringAssetId) internal assetNotWithdrawn(_partnerAssetId) {
         DepositedAsset storage partnerAsset = depositedAssets[_partnerAssetId];
         DepositedAsset storage triggeringAsset = depositedAssets[_triggeringAssetId];

         // Check if they are still entangled with each other (could have been broken concurrently)
         if (partnerAsset.entangledAssetId == _triggeringAssetId) {
             // Example Effect: If triggering asset is withdrawn, partner collapses
             if (triggeringAsset.currentState == QuantumState.Withdrawn) {
                 if (partnerAsset.currentState != QuantumState.Collapsed && partnerAsset.currentState != QuantumState.Withdrawn) {
                     _updateAssetState(_partnerAssetId, QuantumState.Collapsed, "Entangled Partner Withdrawn");
                     // Also break the link since partner is gone
                      partnerAsset.entangledAssetId = 0;
                     emit EntanglementBroken(_partnerAssetId, _triggeringAssetId, "Partner Withdrawn");
                 }
             }
             // Add more complex effects here based on state transitions
             // Example: If partner enters Superposed, this one might have a chance to revert too
         }
     }

    /**
     * @dev View function to get the status of an entanglement link or proposal.
     * @param _asset1Id The ID of the first asset.
     * @param _asset2Id The ID of the second asset.
     * @return status A string indicating the entanglement status (e.g., "Not Entangled", "Proposed By 1", "Entangled").
     */
    function getEntanglementStatus(uint256 _asset1Id, uint256 _asset2Id) external view returns (string memory status) {
         require(depositedAssets[_asset1Id].exists && depositedAssets[_asset2Id].exists, "QV: One or both assets do not exist");

         if (depositedAssets[_asset1Id].entangledAssetId == _asset2Id && depositedAssets[_asset2Id].entangledAssetId == _asset1Id && depositedAssets[_asset1Id].currentState == QuantumState.Entangled) {
             return "Entangled";
         } else if (entanglementProposals[_asset1Id] == _asset2Id) {
             return "Proposed By Asset 1 Owner";
         } else if (entanglementProposals[_asset2Id] == _asset1Id) {
             return "Proposed By Asset 2 Owner";
         } else {
             return "Not Entangled";
         }
     }

    /**
     * @dev View function to get a numerical representation of entanglement 'strength' or duration.
     *      Example: time since entanglement was accepted.
     * @param _assetId The ID of an entangled asset.
     * @return strength A uint representing entanglement strength (e.g., seconds entangled), or 0 if not entangled.
     */
    function getEntanglementStrength(uint256 _assetId) external view returns (uint256 strength) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        if (depositedAssets[_assetId].currentState == QuantumState.Entangled) {
            return block.timestamp - depositedAssets[_assetId].stateEntryTimestamp;
        }
        return 0;
    }


    // 10. View Functions

    /**
     * @dev Gets a summary of all assets held by a specific user.
     * @param _user The address of the user.
     * @return assetIds Array of asset IDs.
     * @return states Array of corresponding QuantumStates.
     */
    function getUserVaultSummary(address _user) external view returns (uint256[] memory assetIds, QuantumState[] memory states) {
         uint256[] memory ids = _userAssetIds[_user];
         assetIds = new uint256[](ids.length);
         states = new QuantumState[](ids.length);

         for (uint i = 0; i < ids.length; i++) {
             uint256 assetId = ids[i];
             if (depositedAssets[assetId].exists) { // Ensure asset still exists (not deleted, though we use 'Withdrawn' state)
                 assetIds[i] = assetId;
                 states[i] = depositedAssets[assetId].currentState;
             } else {
                 // Handle cases where an asset might be removed (e.g., if using deletion instead of Withdrawn state)
                 assetIds[i] = 0; // Placeholder for non-existent
                 states[i] = QuantumState.Withdrawn; // Assume withdrawn if not found
             }
         }
         return (assetIds, states);
     }

     /**
      * @dev Gets detailed information about a specific deposited asset.
      * @param _assetId The ID of the asset.
      * @return asset The DepositedAsset struct.
      */
     function getAssetDetails(uint256 _assetId) external view returns (DepositedAsset memory asset) {
         require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
         return depositedAssets[_assetId];
     }

    /**
     * @dev View function returning the current quantum state of a specific asset.
     * @param _assetId The ID of the asset.
     * @return state The current QuantumState.
     */
    function getAssetCurrentState(uint256 _assetId) external view returns (QuantumState state) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        return depositedAssets[_assetId].currentState;
    }

    /**
     * @dev View function that checks the likely unlock eligibility of an asset based on current rules and time,
     *      *without* triggering the observation effect.
     *      Provides an estimate, not a guarantee, especially for probabilistic states.
     * @param _assetId The ID of the asset.
     * @return eligible True if likely eligible, false otherwise.
     * @return reason A string explaining the eligibility status.
     */
    function checkAssetUnlockEligibility(uint256 _assetId) external view returns (bool eligible, string memory reason) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        DepositedAsset memory asset = depositedAssets[_assetId];

        if (asset.currentState == QuantumState.Withdrawn) {
            return (false, "Asset already withdrawn");
        }

        uint256 timeInState = block.timestamp - asset.stateEntryTimestamp;
        uint256 timeSinceDeposit = block.timestamp - asset.depositTimestamp;

        if (asset.currentState == QuantumState.Collapsed) {
             if (timeInState >= minCollapsedTime && timeSinceDeposit >= minCollapsedTime) {
                 return (true, "Collapsed: Time requirements met");
             } else {
                 return (false, "Collapsed: Time requirements not met");
             }
        } else if (asset.currentState == QuantumState.Decohering) {
             // Check if minimum time met, cannot guarantee probabilistic success
             if (timeInState >= minDecoherenceTime) {
                 return (true, "Decohering: Min time met, unlock is probabilistic");
             } else {
                 return (false, "Decohering: Min time not met");
             }
        } else if (asset.currentState == QuantumState.Superposed) {
             // Check if minimum time met, direct unlock is low probability
             if (timeSinceDeposit >= minSuperpositionTime) {
                 return (true, "Superposed: Min time met, direct unlock is low probability. Also decaying towards Decohering.");
             } else {
                 return (false, "Superposed: Min time not met. Decay in progress.");
             }
        } else if (asset.currentState == QuantumState.Entangled) {
            if (asset.entangledAssetId != 0 && depositedAssets[asset.entangledAssetId].exists) {
                 QuantumState partnerState = depositedAssets[asset.entangledAssetId].currentState;
                 if (asset.currentState == QuantumState.Collapsed && (partnerState == QuantumState.Collapsed || partnerState == QuantumState.Withdrawn)) {
                      return (true, "Entangled: Partner Collapsed/Withdrawn and this asset Collapsed");
                 } else {
                      return (false, string(abi.encodePacked("Entangled: Depends on partner state (Partner is ", _stateToString(partnerState), ")")));
                 }
             } else {
                 return (false, "Entangled: Partner asset does not exist or link broken");
             }
        }

        return (false, "Unknown state or conditions not met");
    }

    /**
     * @dev View function suggesting possible future states for an asset based on current state and time.
     *      Does not account for external interactions (like entanglement breaking).
     * @param _assetId The ID of the asset.
     * @return possibleStates Array of potential next states.
     */
    function getPossibleNextStates(uint256 _assetId) external view returns (QuantumState[] memory possibleStates) {
        require(depositedAssets[_assetId].exists, "QV: Asset does not exist");
        DepositedAsset memory asset = depositedAssets[_assetId];
        uint256 timeInState = block.timestamp - asset.stateEntryTimestamp;

        if (asset.currentState == QuantumState.Withdrawn) {
            return new QuantumState[](0); // No next state
        }

        QuantumState[] memory nextStates;

        if (asset.currentState == QuantumState.Superposed) {
            if (timeInState >= superpositionDecayDuration) {
                nextStates = new QuantumState[](2);
                nextStates[0] = QuantumState.Decohering; // Time decay
                nextStates[1] = QuantumState.Withdrawn;  // Direct probabilistic unlock
            } else if (block.timestamp - asset.depositTimestamp >= minSuperpositionTime) {
                 nextStates = new QuantumState[](2);
                 nextStates[0] = QuantumState.Superposed; // Remains Superposed (most likely)
                 nextStates[1] = QuantumState.Withdrawn;  // Direct probabilistic unlock (low chance)
            } else {
                 nextStates = new QuantumState[](1);
                 nextStates[0] = QuantumState.Superposed; // Remains Superposed
            }
            // Add Entangled if proposal exists? No, keep it state-transition based.
        } else if (asset.currentState == QuantumState.Decohering) {
             if (timeInState >= decoherenceDuration) {
                nextStates = new QuantumState[](2);
                nextStates[0] = QuantumState.Collapsed; // Time decay
                nextStates[1] = QuantumState.Withdrawn;  // Probabilistic unlock (high chance)
             } else if (timeInState >= minDecoherenceTime) {
                nextStates = new QuantumState[](2);
                nextStates[0] = QuantumState.Decohering; // Remains Decohering (most likely)
                nextStates[1] = QuantumState.Withdrawn; // Probabilistic unlock
             } else {
                 nextStates = new QuantumState[](1);
                 nextStates[0] = QuantumState.Decohering; // Remains Decohering
             }
        } else if (asset.currentState == QuantumState.Collapsed) {
             if (block.timestamp - asset.depositTimestamp >= minCollapsedTime) {
                 nextStates = new QuantumState[](1);
                 nextStates[0] = QuantumState.Withdrawn; // Time met, easily withdrawable
             } else {
                 nextStates = new QuantumState[](1);
                 nextStates[0] = QuantumState.Collapsed; // Remains Collapsed
             }
        } else if (asset.currentState == QuantumState.Entangled) {
            // Entangled state transitions are less time-deterministic, more event-driven
            // Possibilities include: remains Entangled, transitions to Decohering (if broken), transitions to Collapsed (if partner collapses/withdrawn)
            uint256 count = 1;
            if (asset.entangledAssetId == 0 || !depositedAssets[asset.entangledAssetId].exists) count++; // Broken link possibility
            if (asset.currentState == QuantumState.Collapsed && asset.entangledAssetId != 0 && depositedAssets[asset.entangledAssetId].exists && depositedAssets[asset.entangledAssetId].currentState >= QuantumState.Decohering) count++; // Partner nearing/at collapse

            nextStates = new QuantumState[](count);
            uint2 i = 0;
            nextStates[i++] = QuantumState.Entangled; // Can remain Entangled

            if (asset.entangledAssetId == 0 || !depositedAssets[asset.entangledAssetId].exists) {
                 nextStates[i++] = QuantumState.Decohering; // If link is broken/invalid
            }

             if (asset.currentState == QuantumState.Collapsed && asset.entangledAssetId != 0 && depositedAssets[asset.entangledAssetId].exists && depositedAssets[asset.entangledAssetId].currentState >= QuantumState.Decohering) {
                  nextStates[i++] = QuantumState.Withdrawn; // If conditions align with partner
             }


        } else {
            nextStates = new QuantumState[](0); // Should not happen
        }

        return nextStates;
    }

    /**
     * @dev Gets all asset IDs currently associated with a user.
     * @param _user The address of the user.
     * @return assetIds Array of asset IDs.
     */
    function getAllUserAssetIds(address _user) external view returns (uint256[] memory assetIds) {
         uint256[] storage userAssets = _userAssetIds[_user];
         uint256 count = 0;
         // Count non-withdrawn assets
         for (uint i = 0; i < userAssets.length; i++) {
             if (depositedAssets[userAssets[i]].exists && depositedAssets[userAssets[i]].currentState != QuantumState.Withdrawn) {
                 count++;
             }
         }

         assetIds = new uint256[](count);
         uint256 current = 0;
         for (uint i = 0; i < userAssets.length; i++) {
              if (depositedAssets[userAssets[i]].exists && depositedAssets[userAssets[i]].currentState != QuantumState.Withdrawn) {
                 assetIds[current++] = userAssets[i];
             }
         }
         return assetIds;
     }


    // 11. Configuration Functions (Owner-only)

    /**
     * @dev Owner function to set the duration for the Superposed state to decay.
     * @param _duration The new duration in seconds.
     */
    function setSuperpositionDecayDuration(uint256 _duration) external onlyOwner {
         superpositionDecayDuration = _duration;
    }

    /**
     * @dev Owner function to set the duration for the Decohering state.
     * @param _duration The new duration in seconds.
     */
    function setDecoherenceDuration(uint224 _duration) external onlyOwner {
         decoherenceDuration = _duration;
    }

    /**
     * @dev Owner function to set the probability (out of 100) of an observation effect state change on failed withdrawal.
     * @param _probability The new probability (0-100).
     */
    function setObservationEffectProbability(uint16 _probability) external onlyOwner {
         require(_probability <= 100, "QV: Probability cannot exceed 100");
         observationEffectProbability = _probability;
    }

    /**
     * @dev Owner function to set the cost (in wei) to propose or break entanglement.
     * @param _cost The new cost in wei.
     */
    function setEntanglementCost(uint256 _cost) external onlyOwner {
        entanglementCost = _cost;
    }

    /**
     * @dev Owner function to pause deposits and withdrawals.
     */
    function pauseVaultOperation() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner function to unpause deposits and withdrawals.
     */
    function unpauseVaultOperation() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner function to withdraw accidental ETH sent directly to the contract,
     *      excluding ETH held within specific user vault entries.
     */
    function withdrawContractBalance() external onlyOwner {
        // Calculate balance that isn't part of vaulted ETH entries
        uint256 vaultedETH = 0;
        // This requires iterating all assets - potentially gas intensive!
        // A better approach in a real system would be to track total vaulted ETH separately.
        // For demonstration, we'll iterate (be mindful of gas limits).
        // A better, but more complex, approach would be to only allow ETH withdrawals
        // of amounts >= total vaulted ETH + a buffer, OR only ETH sent *after* deposit functions were removed/disabled.
        // Given the constraint of avoiding exact open-source copies and complexity,
        // a simple owner withdrawal *is* common, but the 'excluding vaulted ETH' part is tricky.
        // Let's make this function only withdraw any *excess* ETH beyond what's currently marked as vaulted.
        // This isn't perfectly safe if vaulted ETH entries are wrong, but aligns with "accidental" sends.

        uint256 currentTotalVaultedETH = _calculateTotalVaultedETH(); // Helper function (can be gas heavy)
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableBalance = contractBalance > currentTotalVaultedETH ? contractBalance - currentTotalVaultedETH : 0;

        require(withdrawableBalance > 0, "QV: No excess ETH balance to withdraw");

        (bool success, ) = payable(owner()).call{value: withdrawableBalance}("");
        require(success, "QV: ETH withdrawal failed");
    }


    // 12. Helper Functions (Internal logic)

    /**
     * @dev Internal function to update an asset's state and log the change.
     * @param _assetId The ID of the asset.
     * @param _newState The state to transition to.
     * @param _reason A string explaining why the state changed.
     */
    function _updateAssetState(uint256 _assetId, QuantumState _newState, string memory _reason) internal {
        DepositedAsset storage asset = depositedAssets[_assetId];
        require(asset.exists, "QV: Cannot update non-existent asset");
        require(asset.currentState != QuantumState.Withdrawn, "QV: Cannot update withdrawn asset");

        QuantumState oldState = asset.currentState;
        if (oldState != _newState) {
            asset.currentState = _newState;
            asset.stateEntryTimestamp = uint48(block.timestamp);
            emit AssetStateChanged(_assetId, oldState, _newState, _reason);
        }
    }

    /**
     * @dev Internal function to perform the actual asset transfer out of the vault.
     *      Marks the asset as Withdrawn.
     * @param _assetId The ID of the asset to withdraw.
     */
    function _performWithdrawal(uint256 _assetId) internal {
        DepositedAsset storage asset = depositedAssets[_assetId];
        require(asset.exists, "QV: Cannot withdraw non-existent asset");
        require(asset.currentState != QuantumState.Withdrawn, "QV: Asset already marked as withdrawn");

        QuantumState finalState = asset.currentState; // Capture state before changing

        asset.currentState = QuantumState.Withdrawn;
        asset.stateEntryTimestamp = uint48(block.timestamp); // Mark withdrawal time

        if (asset.assetType == AssetType.ETH) {
            (bool success, ) = payable(asset.owner).call{value: asset.amountOrId}("");
            require(success, "QV: ETH transfer failed");
        } else if (asset.assetType == AssetType.ERC20) {
            IERC20(asset.tokenAddress).transfer(asset.owner, asset.amountOrId);
        } else if (asset.assetType == AssetType.ERC721) {
            IERC721(asset.tokenAddress).safeTransferFrom(address(this), asset.owner, asset.amountOrId);
        }

        emit AssetWithdrawn(_assetId, asset.owner, finalState);
        emit AssetStateChanged(_assetId, finalState, QuantumState.Withdrawn, "Asset Withdrawn");

        // Note: We don't delete the asset struct to keep history tied to the ID,
        // but the `exists` flag and `Withdrawn` state mark it as inactive.
        // For `_userAssetIds`, we could potentially remove the ID, but keeping it
        // and filtering on `currentState != Withdrawn` is simpler for this example.
    }

    /**
     * @dev Internal function to apply an observation effect - a probabilistic state change
     *      when a withdrawal attempt fails.
     *      Example: Superposed might jump to Collapsed or revert to Superposed with different parameters.
     *      Decohering might revert to Superposed or jump to Collapsed.
     * @param _assetId The ID of the asset.
     */
    function _applyObservationEffect(uint256 _assetId) internal assetNotWithdrawn(_assetId) {
        DepositedAsset storage asset = depositedAssets[_assetId];
        QuantumState oldState = asset.currentState;
        QuantumState newState = oldState; // Default: no change

        uint256 randomness = _getDynamicRandomness(block.timestamp, _assetId, uint64(tx.gasprice));

        if (oldState == QuantumState.Superposed) {
             // ~50% chance to go Decohering, ~50% stay Superposed but reset timer? Or small chance jump to Collapsed?
             if (randomness % 10 < 5) { // 50% chance roughly
                 newState = QuantumState.Decohering;
             } else {
                 // Stay Superposed, perhaps reset state entry timer to simulate re-entanglement/stabilization
                 asset.stateEntryTimestamp = uint48(block.timestamp); // Reset timer
                 // No state change event if state is the same
             }
        } else if (oldState == QuantumState.Decohering) {
             // ~50% jump to Collapsed, ~50% revert to Superposed?
             if (randomness % 10 < 5) { // 50% chance roughly
                 newState = QuantumState.Collapsed;
             } else {
                 newState = QuantumState.Superposed; // Revert! Makes Decohering riskier
             }
        } else if (oldState == QuantumState.Entangled) {
             // Observation on Entangled: potentially trigger effect on partner, or break entanglement
             if (randomness % 100 < 30) { // 30% chance to break entanglement
                 if (asset.entangledAssetId != 0 && depositedAssets[asset.entangledAssetId].exists) {
                     uint256 partnerId = asset.entangledAssetId;
                     // Break entanglement link directly (without calling breakEntanglement to avoid reentrancy/checks)
                     DepositedAsset storage partnerAsset = depositedAssets[partnerId];
                     asset.entangledAssetId = 0;
                     partnerAsset.entangledAssetId = 0;
                     // Both go to Decohering
                     _updateAssetState(_assetId, QuantumState.Decohering, "Observation Effect: Entanglement Broken");
                     _updateAssetState(partnerId, QuantumState.Decohering, "Observation Effect: Entanglement Broken by Partner");
                     return; // State changes already emitted
                 }
             } else {
                 // No change, maybe just trigger partner effect? Or small chance partner state changes?
                 if (asset.entangledAssetId != 0 && depositedAssets[asset.entangledAssetId].exists) {
                      _triggerEntangledEffect(asset.entangledAssetId, _assetId); // Trigger effect without state change here
                 }
             }
             // If entanglement was broken above, newState would be Decohering. If not, it remains Entangled.
             newState = asset.currentState; // Keep current state unless changed above
        }
        // Collapsed state: Observation effect less likely or different outcome? Maybe slight delay added?
        // For now, let's say Collapsed is stable to observation.

        if (newState != oldState) {
             _updateAssetState(_assetId, newState, "Observation Effect Triggered");
        }
    }


    /**
     * @dev Provides a pseudo-random number based on block data and input parameters.
     *      WARNING: Block hash/difficulty are susceptible to miner manipulation,
     *      especially for high-value or time-sensitive operations. DO NOT rely on this
     *      for true unpredictability in a high-stakes production environment.
     *      This is for conceptual demonstration of probabilistic states.
     * @param _timestamp Current block timestamp.
     * @param _assetId ID of the asset involved.
     * @param _additionalEntropy Extra data for hashing (e.g., tx.origin, gasleft, difficulty, gasprice).
     * @return pseudoRandomNumber A pseudo-random uint256.
     */
    function _getDynamicRandomness(uint256 _timestamp, uint256 _assetId, uint64 _additionalEntropy) internal view returns (uint256 pseudoRandomNumber) {
        // Combine block data and input parameters for a seed
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty, // Use block.prevrandao after The Merge
                block.gaslimit,
                block.number,
                _timestamp, // Redundant but adds mix
                _assetId,
                _additionalEntropy,
                msg.sender, // Add sender for more variation
                tx.origin // Caution with tx.origin
            )
        );
        return uint256(seed);
    }

    /**
     * @dev Helper function to convert QuantumState enum to string for readability (e.g., in logs).
     *      Note: Storing/returning strings on-chain is gas-expensive. Use primarily for events/debugging.
     */
    function _stateToString(QuantumState _state) internal pure returns (string memory) {
        if (_state == QuantumState.Superposed) return "Superposed";
        if (_state == QuantumState.Entangled) return "Entangled";
        if (_state == QuantumState.Decohering) return "Decohering";
        if (_state == QuantumState.Collapsed) return "Collapsed";
        if (_state == QuantumState.Withdrawn) return "Withdrawn";
        return "Unknown";
    }

     /**
      * @dev Calculates the total amount of ETH currently held within DepositedAsset entries.
      *      Note: This function can be gas intensive as it iterates through all asset IDs.
      *      Not suitable for frequent calls in production, mainly for owner withdrawal helper.
      */
     function _calculateTotalVaultedETH() internal view returns (uint256) {
         uint256 totalETH = 0;
         // Iterating through mapping values directly is not possible.
         // Need to iterate through stored asset IDs or maintain a separate list.
         // Iterating through _userAssetIds is still complex if users have many assets.
         // Simplest for this example: assume asset IDs are somewhat sequential and iterate up to the max ID.
         // This is INEFFICIENT and might exceed block gas limit in a real contract with many deposits.
         // Proper solution involves tracking total vaulted ETH state variable updated on deposit/withdrawal.
         // For this demonstration, we'll use the inefficient iteration.
         // Consider this a known limitation for the sake of avoiding standard patterns.

         uint256 maxAssetId = _nextAssetId; // Iterate up to the next potential ID (means 1 to maxAssetId - 1)
         for (uint256 i = 1; i < maxAssetId; i++) {
             if (depositedAssets[i].exists && depositedAssets[i].assetType == AssetType.ETH && depositedAssets[i].currentState != QuantumState.Withdrawn) {
                 totalETH = totalETH.add(depositedAssets[i].amountOrId);
             }
         }
         return totalETH;
     }

     // Override to receive ERC721 tokens
     // From ERC721Holder
     // function onERC721Received(...) is defined in ERC721Holder and automatically handles receiving ERC721.


     // Need 20+ functions total. Let's count:
     // 1. Constructor
     // 2. depositETH
     // 3. depositERC20
     // 4. depositERC721
     // 5. attemptObservationAndWithdraw
     // 6. collapseSuperposition
     // 7. processAssetDecay
     // 8. attemptStateSuperposition
     // 9. proposeEntanglement
     // 10. acceptEntanglement
     // 11. breakEntanglement
     // 12. _triggerEntangledEffect (internal - doesn't count towards public function count)
     // 13. getEntanglementStatus (view)
     // 14. getEntanglementStrength (view)
     // 15. getUserVaultSummary (view)
     // 16. getAssetDetails (view)
     // 17. getAssetCurrentState (view)
     // 18. checkAssetUnlockEligibility (view)
     // 19. getPossibleNextStates (view)
     // 20. getAllUserAssetIds (view)
     // 21. setSuperpositionDecayDuration (owner)
     // 22. setDecoherenceDuration (owner)
     // 23. setObservationEffectProbability (owner)
     // 24. setEntanglementCost (owner)
     // 25. pauseVaultOperation (owner)
     // 26. unpauseVaultOperation (owner)
     // 27. withdrawContractBalance (owner)
     // 28. _updateAssetState (internal)
     // 29. _performWithdrawal (internal)
     // 30. _applyObservationEffect (internal)
     // 31. _getDynamicRandomness (internal)
     // 32. _stateToString (internal view)
     // 33. _calculateTotalVaultedETH (internal view)

     // Public/External functions count: 27 (1-11, 13-27). This meets the requirement of 20+.

}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Quantum States (Metaphorical):** The core concept is the state machine (`QuantumState` enum). Instead of simple time locks, assets traverse states (`Superposed`, `Entangled`, `Decohering`, `Collapsed`), each with distinct (and sometimes complex) rules for transition and unlocking.
2.  **State Transitions:** States change not just by time (`processAssetDecay`) but potentially by user actions (`collapseSuperposition`, `attemptStateSuperposition`) and even failed withdrawal attempts (`attemptObservationAndWithdraw` -> `_applyObservationEffect`).
3.  **Probabilistic Unlocking:** The `Decohering` state's unlock success is probabilistic, increasing with time. The `Superposed` state has a low chance of direct probabilistic unlock. This adds an element of unpredictability, like a quantum measurement.
4.  **Observation Effect:** Attempting to interact (withdraw) with certain states (`Superposed`, `Decohering`, `Entangled`) has a chance (`observationEffectProbability`) of triggering a state change (`_applyObservationEffect`), mimicking how observation affects quantum systems. This makes interaction itself a factor in the asset's state evolution.
5.  **Entanglement:** Two assets (potentially owned by different users) can be linked. Their states become correlated, and unlocking one might depend on or affect the state of the other (`Entangled` state, `_triggerEntangledEffect`). Breaking entanglement also has a defined outcome.
6.  **Dynamic Randomness (Pseudo):** Uses block data (`block.timestamp`, `block.difficulty`/`prevrandao`, etc.) combined with input parameters (`_assetId`, `gasleft`/`gasprice`, `msg.sender`) to create a seed for pseudo-random outcomes in probabilistic events and observation effects. *Crucially, the code includes a warning about the limitations of on-chain randomness.* This is for conceptual illustration.
7.  **Multi-Asset Vault:** Handles ETH, ERC-20, and ERC-721 within the same state machine and asset tracking system.
8.  **Complex State Logic:** The `attemptObservationAndWithdraw` function is the core of the state machine, checking various conditions (`timeInState`, `timeSinceDeposit`, `currentState`, `entangledAssetId`, randomness) to determine if a withdrawal is possible and what happens otherwise.
9.  **State Reversion/Manipulation:** `attemptStateSuperposition` allows users to *try* and revert assets back to a harder-to-unlock state, adding strategic depth. `collapseSuperposition` allows forcing a move towards the easily unlockable state.
10. **View Functions for State Insight:** Includes detailed view functions (`checkAssetUnlockEligibility`, `getPossibleNextStates`, `getEntanglementStatus`) to help users understand the complex state and predict potential outcomes *without* triggering state-changing side effects (except where explicitly part of the simulation, like the observation effect in the *attempt* function, not the *check* function).

This contract uses standard OpenZeppelin libraries for safety (`Ownable`, `ReentrancyGuard`, `Pausable`, `SafeMath`, `ERC721Holder`) but implements a novel core logic around the "quantum" state machine and entanglement, making it distinct from typical time-locks, vesting contracts, or simple multi-asset wallets. The numerous functions cover depositing, interacting with the state, managing entanglement, withdrawing, and querying the complex state.