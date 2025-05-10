Okay, let's design an interesting, advanced, and creative smart contract concept. We'll build a dynamic, shared "Ethereal Canvas" where users own 'Patches' (sections) of the canvas, which evolve over time and can be influenced by owners and potentially community governance. It combines elements of NFTs, generative art principles (though rendering is off-chain), resource management, time-based mechanics (epochs), and a form of on-chain governance.

This isn't a standard ERC721/ERC1155, a simple token, or a typical DeFi protocol. It's a unique stateful application contract.

---

**EtherealCanvas Smart Contract Outline & Function Summary**

**Concept:**
EtherealCanvas is a smart contract representing a dynamic, on-chain digital canvas of fixed dimensions. Users can acquire and own "Patches" (rectangular areas) of this canvas. Patches have properties like color data and texture IDs stored on-chain. The canvas state evolves in discrete time periods called "Epochs". Users utilize a virtual, contract-native resource called "Essence" to perform actions like acquiring new patches, expanding existing ones, or updating patch properties. A basic governance system allows patch owners (weighted by patch area) to propose and vote on potential changes or future features.

**Core Mechanisms:**
1.  **Patches:** Rectangular areas owned by users. Represented by a unique ID. Store position, dimensions, color data, texture ID, and an active status.
2.  **Canvas Grid:** A mapping from (x,y) coordinates to Patch IDs, ensuring no overlap and defining the visual state.
3.  **Essence:** A non-transferable, contract-internal virtual token used for actions. Can be acquired by sending ETH to the contract. Distributed to patch owners during Epoch transitions.
4.  **Epochs:** Time periods during which canvas state evolves. At the end of an epoch, an automated effect occurs (e.g., essence distribution) and a new epoch begins.
5.  **Governance:** Users holding Patches can propose and vote on abstract ideas or parameter changes, with voting power proportional to the total area of their owned active patches.

**Function Categories & Summaries:**

1.  **Initialization & Configuration (Admin-Only):**
    *   `constructor`: Deploys the contract, sets canvas dimensions, initial parameters, and admin.
    *   `setEssenceCosts`: Sets the cost in Essence for various user actions.
    *   `setEpochDuration`: Sets the time duration of each epoch.
    *   `setMinPatchSize`: Sets the minimum allowed width/height for patches after splitting.
    *   `setEpochEssencePerArea`: Sets the amount of Essence distributed per unit of patch area during epoch advance.
    *   `grantEssence`: Allows admin to grant Essence to an address (e.g., for initial distribution or rewards).
    *   `withdrawETH`: Allows admin to withdraw ETH accumulated from Essence purchases.

2.  **Essence Management (User Interaction):**
    *   `buyEssence`: Allows any user to send ETH to the contract and receive Essence in exchange.

3.  **Patch Interaction (User Actions):**
    *   `mintInitialPatch`: Allows a user to acquire their first patch at a specific unoccupied location.
    *   `expandPatch`: Allows a user to expand an existing owned patch into adjacent unoccupied territory.
    *   `updatePatchColor`: Allows a user to change the color data associated with their patch.
    *   `updatePatchTexture`: Allows a user to change the texture ID associated with their patch.
    *   `splitPatch`: Allows a user to split an owned patch into two smaller, adjacent patches.
    *   `mergePatches`: Allows a user to merge two adjacent, owned patches into a single larger patch.
    *   `transferPatch`: Allows a patch owner to transfer ownership of a specific patch to another address.
    *   `approvePatchTransfer`: Allows a patch owner to approve another address to transfer a specific patch on their behalf.
    *   `transferPatchFrom`: Allows an approved address or the owner to transfer a specific patch.

4.  **Epoch Mechanics:**
    *   `advanceEpoch`: Can be called by anyone after the epoch duration has passed. Triggers epoch-end effects and starts the next epoch.
    *   `_applyEpochEffect`: (Internal) Distributes Essence to patch owners based on area, triggered by `advanceEpoch`.

5.  **Governance (Patch Owner Interaction):**
    *   `proposeChange`: Allows a patch owner to submit a proposal text and duration (requires Essence cost).
    *   `voteOnProposal`: Allows a patch owner to vote Yes/No on an active proposal. Voting power is based on the area of their owned patches at the time of voting.
    *   `executeProposal`: Can be called after a proposal's voting period ends. Marks the proposal as Passed/Failed based on votes (execution logic itself is external to this simplified example, it just records the outcome).
    *   `cancelProposal`: Allows the proposal creator or admin to cancel an active proposal.

6.  **Read Functions (Public View):**
    *   `getCanvasDimensions`: Returns the width and height of the canvas.
    *   `getPatchDetails`: Returns all details for a specific patch ID.
    *   `getPatchOwner`: Returns the owner of a specific patch ID.
    *   `getPatchIdAtCoord`: Returns the patch ID occupying a specific coordinate (x,y), or 0 if unoccupied.
    *   `getTotalPatches`: Returns the total number of patches ever minted (including inactive ones).
    *   `getActivePatchCount`: Returns the current number of active patches.
    *   `getEssenceBalance`: Returns the Essence balance for a given address.
    *   `getCurrentEpoch`: Returns the current epoch number.
    *   `getEpochEndTime`: Returns the timestamp when the current epoch ends.
    *   `getEssenceCosts`: Returns the current costs for actions in Essence.
    *   `getMinPatchSize`: Returns the minimum allowed patch dimension.
    *   `getProposalDetails`: Returns the details of a specific proposal ID.
    *   `getActiveProposals`: Returns a list of active proposal IDs.
    *   `getUserVotingPower`: Calculates the current total area of active patches owned by an address (used for governance).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherealCanvas
 * @dev A dynamic, on-chain digital canvas where users own and modify rectangular "Patches".
 * The canvas evolves over time through "Epochs" and actions require a contract-native
 * virtual resource called "Essence". Features a basic governance system based on patch area.
 *
 * Outline & Function Summary:
 *
 * Concept:
 * EtherealCanvas is a smart contract representing a dynamic, on-chain digital canvas of fixed dimensions.
 * Users can acquire and own "Patches" (rectangular areas) of this canvas. Patches have properties
 * like color data and texture IDs stored on-chain. The canvas state evolves in discrete time periods
 * called "Epochs". Users utilize a virtual, contract-native resource called "Essence" to perform
 * actions like acquiring new patches, expanding existing ones, or updating patch properties.
 * A basic governance system allows patch owners (weighted by patch area) to propose and vote
 * on potential changes or future features.
 *
 * Core Mechanisms:
 * 1. Patches: Rectangular areas owned by users. Represented by a unique ID. Store position, dimensions, color data, texture ID, and an active status.
 * 2. Canvas Grid: A mapping from (x,y) coordinates to Patch IDs, ensuring no overlap and defining the visual state.
 * 3. Essence: A non-transferable, contract-internal virtual token used for actions. Can be acquired by sending ETH to the contract. Distributed to patch owners during Epoch transitions.
 * 4. Epochs: Time periods during which canvas state evolves. At the end of an epoch, an automated effect occurs (e.g., essence distribution) and a new epoch begins.
 * 5. Governance: Users holding Patches can propose and vote on abstract ideas or parameter changes, with voting power proportional to the total area of their owned active patches.
 *
 * Function Categories & Summaries:
 * 1. Initialization & Configuration (Admin-Only):
 *    - constructor: Deploys the contract, sets canvas dimensions, initial parameters, and admin.
 *    - setEssenceCosts: Sets the cost in Essence for various user actions.
 *    - setEpochDuration: Sets the time duration of each epoch.
 *    - setMinPatchSize: Sets the minimum allowed width/height for patches after splitting.
 *    - setEpochEssencePerArea: Sets the amount of Essence distributed per unit of patch area during epoch advance.
 *    - grantEssence: Allows admin to grant Essence to an address.
 *    - withdrawETH: Allows admin to withdraw ETH accumulated from Essence purchases.
 *
 * 2. Essence Management (User Interaction):
 *    - buyEssence: Allows any user to send ETH to the contract and receive Essence in exchange.
 *
 * 3. Patch Interaction (User Actions):
 *    - mintInitialPatch: Allows a user to acquire their first patch at a specific unoccupied location.
 *    - expandPatch: Allows a user to expand an existing owned patch into adjacent unoccupied territory.
 *    - updatePatchColor: Allows a user to change the color data associated with their patch.
 *    - updatePatchTexture: Allows a user to change the texture ID associated with their patch.
 *    - splitPatch: Allows a user to split an owned patch into two smaller, adjacent patches.
 *    - mergePatches: Allows a user to merge two adjacent, owned patches into a single larger patch.
 *    - transferPatch: Allows a patch owner to transfer ownership of a specific patch to another address.
 *    - approvePatchTransfer: Allows a patch owner to approve another address to transfer a specific patch.
 *    - transferPatchFrom: Allows an approved address or the owner to transfer a specific patch.
 *
 * 4. Epoch Mechanics:
 *    - advanceEpoch: Can be called by anyone after the epoch duration has passed. Triggers epoch-end effects and starts the next epoch.
 *    - _applyEpochEffect: (Internal) Distributes Essence to patch owners based on area, triggered by advanceEpoch.
 *
 * 5. Governance (Patch Owner Interaction):
 *    - proposeChange: Allows a patch owner to submit a proposal text and duration (requires Essence cost).
 *    - voteOnProposal: Allows a patch owner to vote Yes/No on an active proposal. Voting power is based on the area of their owned patches.
 *    - executeProposal: Can be called after proposal voting ends. Records Passed/Failed outcome.
 *    - cancelProposal: Allows proposal creator or admin to cancel.
 *
 * 6. Read Functions (Public View):
 *    - getCanvasDimensions: Returns the width and height.
 *    - getPatchDetails: Returns details for a patch ID.
 *    - getPatchOwner: Returns owner of a patch ID.
 *    - getPatchIdAtCoord: Returns patch ID at (x,y).
 *    - getTotalPatches: Total patches ever minted.
 *    - getActivePatchCount: Current active patches.
 *    - getEssenceBalance: Essence balance for an address.
 *    - getCurrentEpoch: Current epoch number.
 *    - getEpochEndTime: Timestamp of epoch end.
 *    - getEssenceCosts: Current Essence costs.
 *    - getMinPatchSize: Minimum patch dimension.
 *    - getProposalDetails: Details of a proposal ID.
 *    - getActiveProposals: List of active proposal IDs.
 *    - getUserVotingPower: Calculates user's governance power.
 */
contract EtherealCanvas {

    address public admin;

    // --- State Variables ---
    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;

    struct Patch {
        uint256 id;
        uint256 x;
        uint256 y;
        uint256 width;
        uint256 height;
        uint32 color; // Example: ABGR or RGBA color format
        uint16 textureId;
        bool isActive; // Used to mark patches merged or split
    }

    uint256 private _patchCounter; // Starts from 1
    mapping(uint256 => Patch) private _patches;
    mapping(uint256 => address) private _patchOwners;
    mapping(uint256 => address) private _patchApprovals; // ERC721-like approval
    mapping(uint256 x => mapping(uint256 y => uint256 patchId)) private _coordToPatchId; // 0 means empty

    mapping(address => uint256) private _essenceBalances;
    uint256 public essencePerEth = 1000 ether; // Example: 1 ETH gets 1000 Essence (using ether units for simplicity)

    uint256 public essenceMintCost = 100; // Cost to mint the *first* patch
    uint256 public essenceActionCost = 10; // Base cost for expand, update, split, merge, propose

    uint256 public minPatchSize = 1; // Minimum dimension (width or height)

    uint256 public currentEpoch = 1;
    uint256 public epochStartTime;
    uint256 public epochDuration;
    uint256 public epochEssencePerArea = 1; // Essence distributed per unit of patch area during epoch advance

    struct Proposal {
        uint256 id;
        address proposer;
        string description; // Abstract description of the proposed change
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 totalYesVotesArea; // Total area of patches that voted yes
        uint256 totalNoVotesArea;  // Total area of patches that voted no
        bool executed;
        bool passed; // True if passed, false if failed
        bool cancelled;
    }

    uint256 private _proposalCounter; // Starts from 1
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _userHasVotedOnProposal; // proposalId => voter => hasVoted

    uint256 public proposalVotingPeriod = 7 days;
    // Simple majority threshold based on area participating in the vote
    uint256 public proposalVoteThresholdNumerator = 50; // 50%
    uint256 public proposalVoteThresholdDenominator = 100;

    // --- Events ---
    event PatchMinted(uint256 indexed patchId, address indexed owner, uint256 x, uint256 y, uint256 width, uint256 height);
    event PatchExpanded(uint256 indexed patchId, uint256 newWidth, uint256 newHeight);
    event PatchColorUpdated(uint256 indexed patchId, uint32 newColor);
    event PatchTextureUpdated(uint256 indexed patchId, uint16 newTextureId);
    event PatchSplit(uint256 indexed oldPatchId, uint256 indexed newPatchId1, uint256 indexed newPatchId2);
    event PatchMerged(uint256 indexed mergedPatchId1, uint256 indexed mergedPatchId2, uint256 indexed newPatchId);
    event PatchTransfer(uint256 indexed patchId, address indexed from, address indexed to);
    event PatchApproval(uint256 indexed patchId, address indexed owner, address indexed approved);

    event EssencePurchased(address indexed buyer, uint256 ethAmount, uint256 essenceAmount);
    event EssenceGranted(address indexed recipient, uint256 essenceAmount);
    event EssenceSpent(address indexed spender, uint256 amount, string action);

    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime, uint256 endTime);
    event EpochEffectApplied(uint256 indexed epoch, uint256 totalEssenceDistributed);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingEndTime);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPowerArea);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event ProposalCancelled(uint256 indexed proposalId);

    // --- Errors ---
    error NotAdmin();
    error PatchNotFound(uint256 patchId);
    error NotPatchOwner(uint256 patchId);
    error NotApprovedOrOwner(uint256 patchId);
    error InsufficientEssence(uint256 required, uint256 available);
    error InvalidCoordinates(uint256 x, uint256 y);
    error InvalidDimensions(uint256 width, uint256 height);
    error AreaOccupied(uint256 x, uint256 y, uint256 width, uint256 height);
    error AreaNotOccupiedByPatch(uint256 patchId, uint256 x, uint256 y, uint256 width, uint256 height);
    error InvalidExpansion(uint256 patchId, uint256 newX, uint256 newY, uint256 newWidth, uint256 newHeight);
    error InvalidSplit(uint256 patchId, uint256 splitCoord, bool isVerticalSplit);
    error InvalidMerge(uint256 patchId1, uint256 patchId2);
    error PatchesNotAdjacent(uint256 patchId1, uint256 patchId2);
    error PatchesNotOwnedByCaller(uint256 patchId1, uint256 patchId2);
    error CannotAdvanceEpochYet(uint256 nextEpochTime);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error ProposalVotingEnded(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId);
    error NotProposalCreatorOrAdmin();
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalAlreadyCancelled(uint256 proposalId);
    error ZeroVotingPower();
    error CannotWithdrawZeroEth();

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier whenEpochCanAdvance() {
        if (block.timestamp < epochStartTime + epochDuration) {
            revert CannotAdvanceEpochYet(epochStartTime + epochDuration);
        }
        _;
    }

    modifier costEssence(uint256 amount) {
        _spendEssence(msg.sender, amount, msg.sig); // Use msg.sig for action identifier
        _;
    }

    // --- Constructor ---
    constructor(uint256 _canvasWidth, uint256 _canvasHeight, uint256 _epochDuration) {
        admin = msg.sender;
        canvasWidth = _canvasWidth;
        canvasHeight = _canvasHeight;
        epochDuration = _epochDuration;
        epochStartTime = block.timestamp; // Start first epoch immediately
        _patchCounter = 0;
        _proposalCounter = 0;
    }

    // --- Admin Functions ---

    /// @notice Sets the cost in Essence for various user actions.
    /// @param _mintCost Cost to mint the first patch.
    /// @param _actionCost Base cost for other actions (expand, update, split, merge, propose).
    function setEssenceCosts(uint256 _mintCost, uint256 _actionCost) external onlyAdmin {
        essenceMintCost = _mintCost;
        essenceActionCost = _actionCost;
    }

    /// @notice Sets the duration of each epoch in seconds.
    /// @param _duration The new epoch duration in seconds.
    function setEpochDuration(uint256 _duration) external onlyAdmin {
        epochDuration = _duration;
    }

    /// @notice Sets the minimum allowed width and height for patches after splitting.
    /// @param _minSize The new minimum dimension.
    function setMinPatchSize(uint256 _minSize) external onlyAdmin {
        minPatchSize = _minSize;
    }

     /// @notice Sets the amount of Essence distributed per unit of patch area during epoch advance.
     /// @param _essencePerArea The new Essence per area value.
    function setEpochEssencePerArea(uint256 _essencePerArea) external onlyAdmin {
        epochEssencePerArea = _essencePerArea;
    }

    /// @notice Allows admin to grant Essence to an address.
    /// @param _recipient The address to grant Essence to.
    /// @param _amount The amount of Essence to grant.
    function grantEssence(address _recipient, uint256 _amount) external onlyAdmin {
        _essenceBalances[_recipient] += _amount;
        emit EssenceGranted(_recipient, _amount);
    }

    /// @notice Allows admin to withdraw accumulated ETH from Essence purchases.
    function withdrawETH() external onlyAdmin {
        uint256 balance = address(this).balance;
        if (balance == 0) revert CannotWithdrawZeroEth();
        (bool success, ) = payable(admin).call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    // --- Essence Management ---

    /// @notice Allows users to buy Essence by sending ETH.
    function buyEssence() external payable {
        uint256 essenceAmount = msg.value * essencePerEth / 1 ether; // Convert ETH to Essence
        require(essenceAmount > 0, "Must send enough ETH to get at least 1 Essence");
        _essenceBalances[msg.sender] += essenceAmount;
        emit EssencePurchased(msg.sender, msg.value, essenceAmount);
    }

    // --- Patch Interaction ---

    /// @notice Allows a user to mint their initial patch on the canvas.
    /// @param _x X coordinate of the patch.
    /// @param _y Y coordinate of the patch.
    /// @param _width Width of the patch.
    /// @param _height Height of the patch.
    /// @param _color Initial color data.
    /// @param _textureId Initial texture ID.
    function mintInitialPatch(
        uint256 _x,
        uint256 _y,
        uint256 _width,
        uint256 _height,
        uint32 _color,
        uint16 _textureId
    ) external costEssence(essenceMintCost) {
        _mintPatch(msg.sender, _x, _y, _width, _height, _color, _textureId);
    }

    /// @notice Allows a user to expand an existing owned patch into adjacent free space.
    /// @param _patchId The ID of the patch to expand.
    /// @param _newX The new X coordinate of the top-left corner.
    /// @param _newY The new Y coordinate of the top-left corner.
    /// @param _newWidth The new width.
    /// @param _newHeight The new height.
    function expandPatch(
        uint256 _patchId,
        uint256 _newX,
        uint256 _newY,
        uint256 _newWidth,
        uint256 _newHeight
    ) external costEssence(essenceActionCost) {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);

        // Check if the new dimensions contain the old patch perfectly
        if (_newX > patch.x || _newY > patch.y || _newX + _newWidth < patch.x + patch.width || _newY + _newHeight < patch.y + patch.height) {
             revert InvalidExpansion(_patchId, _newX, _newY, _newWidth, _newHeight);
        }

        // Check if the *newly added* area is within canvas bounds and is empty
        _checkArea(_newX, _newY, _newWidth, _newHeight); // Checks total new area for bounds
        _checkNewExpansionAreaEmpty(patch, _newX, _newY, _newWidth, _newHeight);

        // Update coordinate mappings for the newly occupied area
        for (uint256 i = _newX; i < _newX + _newWidth; ++i) {
            for (uint256 j = _newY; j < _newY + _newHeight; ++j) {
                // Only update if this coord was not part of the old patch
                if (i < patch.x || i >= patch.x + patch.width || j < patch.y || j >= patch.y + patch.height) {
                    _coordToPatchId[i][j] = _patchId;
                }
            }
        }

        // Update patch dimensions
        patch.x = _newX;
        patch.y = _newY;
        patch.width = _newWidth;
        patch.height = _newHeight;

        emit PatchExpanded(_patchId, _newWidth, _newHeight);
    }

    /// @notice Allows a user to update the color data of their patch.
    /// @param _patchId The ID of the patch.
    /// @param _newColor The new color data.
    function updatePatchColor(uint256 _patchId, uint32 _newColor) external costEssence(essenceActionCost) {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);

        patch.color = _newColor;
        emit PatchColorUpdated(_patchId, _newColor);
    }

    /// @notice Allows a user to update the texture ID of their patch.
    /// @param _patchId The ID of the patch.
    /// @param _newTextureId The new texture ID.
    function updatePatchTexture(uint256 _patchId, uint16 _newTextureId) external costEssence(essenceActionCost) {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);

        patch.textureId = _newTextureId;
        emit PatchTextureUpdated(_patchId, _newTextureId);
    }

    /// @notice Allows a user to split an owned patch into two smaller, adjacent patches.
    /// @param _patchId The ID of the patch to split.
    /// @param _splitCoord The coordinate (x or y) at which to split.
    /// @param _isVerticalSplit True for vertical split (splits width), False for horizontal (splits height).
    function splitPatch(uint256 _patchId, uint256 _splitCoord, bool _isVerticalSplit) external costEssence(essenceActionCost) {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);

        uint256 x1 = patch.x;
        uint256 y1 = patch.y;
        uint256 w1;
        uint256 h1;
        uint256 x2;
        uint256 y2;
        uint256 w2;
        uint256 h2;

        if (_isVerticalSplit) {
            // Split width
            if (_splitCoord <= x1 || _splitCoord >= x1 + patch.width) revert InvalidSplit(_patchId, _splitCoord, true);
            w1 = _splitCoord - x1;
            h1 = patch.height;
            x2 = _splitCoord;
            y2 = y1;
            w2 = (x1 + patch.width) - _splitCoord;
            h2 = patch.height;

            if (w1 < minPatchSize || w2 < minPatchSize || h1 < minPatchSize) revert InvalidSplit(_patchId, _splitCoord, true);

        } else {
            // Split height
            if (_splitCoord <= y1 || _splitCoord >= y1 + patch.height) revert InvalidSplit(_patchId, _splitCoord, false);
            w1 = patch.width;
            h1 = _splitCoord - y1;
            x2 = x1;
            y2 = _splitCoord;
            w2 = patch.width;
            h2 = (y1 + patch.height) - _splitCoord;

            if (w1 < minPatchSize || h1 < minPatchSize || h2 < minPatchSize) revert InvalidSplit(_patchId, _splitCoord, false);
        }

        // Mark the old patch as inactive
        patch.isActive = false;
        _patchOwners[_patchId] = address(0); // Clear owner for inactive patch

        // Mint the two new patches
        uint256 newPatchId1 = _mintPatch(msg.sender, x1, y1, w1, h1, patch.color, patch.textureId);
        uint256 newPatchId2 = _mintPatch(msg.sender, x2, y2, w2, h2, patch.color, patch.textureId);

        // Note: _mintPatch already updates the _coordToPatchId mapping for the new areas.
        // The old patch's coordinates are effectively overwritten by the new patches.

        emit PatchSplit(_patchId, newPatchId1, newPatchId2);
    }

    /// @notice Allows a user to merge two adjacent, owned patches into a single larger patch.
    /// @param _patchId1 The ID of the first patch.
    /// @param _patchId2 The ID of the second patch.
    function mergePatches(uint256 _patchId1, uint256 _patchId2) external costEssence(essenceActionCost) {
        Patch storage patch1 = _patches[_patchId1];
        Patch storage patch2 = _patches[_patchId2];

        if (!_isPatchActive(patch1)) revert PatchNotFound(_patchId1);
        if (!_isPatchActive(patch2)) revert PatchNotFound(_patchId2);
        if (_patchOwners[_patchId1] != msg.sender || _patchOwners[_patchId2] != msg.sender) revert PatchesNotOwnedByCaller(_patchId1, _patchId2);
        if (_patchOwners[_patchId1] != _patchOwners[_patchId2]) revert PatchesNotOwnedByCaller(_patchId1, _patchId2); // Should be same as above, but double check caller owns both

        // Check adjacency and if combined forms a valid rectangle
        bool adjacent = false;
        uint256 newX, newY, newW, newH;

        // Check if patch1 is directly left of patch2
        if (patch1.x + patch1.width == patch2.x && patch1.y == patch2.y && patch1.height == patch2.height) {
            adjacent = true;
            newX = patch1.x;
            newY = patch1.y;
            newW = patch1.width + patch2.width;
            newH = patch1.height;
        }
        // Check if patch2 is directly left of patch1
        else if (patch2.x + patch2.width == patch1.x && patch2.y == patch1.y && patch2.height == patch1.height) {
            adjacent = true;
            newX = patch2.x;
            newY = patch2.y;
            newW = patch2.width + patch1.width;
            newH = patch2.height;
        }
        // Check if patch1 is directly above patch2
        else if (patch1.y + patch1.height == patch2.y && patch1.x == patch2.x && patch1.width == patch2.width) {
            adjacent = true;
            newX = patch1.x;
            newY = patch1.y;
            newW = patch1.width;
            newH = patch1.height + patch2.height;
        }
        // Check if patch2 is directly above patch1
        else if (patch2.y + patch2.height == patch1.y && patch2.x == patch1.x && patch2.width == patch1.width) {
            adjacent = true;
            newX = patch2.x;
            newY = patch2.y;
            newW = patch2.width;
            newH = patch2.height + patch1.height;
        }

        if (!adjacent) revert PatchesNotAdjacent(_patchId1, _patchId2);

        // Mark the old patches as inactive
        patch1.isActive = false;
        _patchOwners[_patchId1] = address(0); // Clear owner for inactive patch
        patch2.isActive = false;
        _patchOwners[_patchId2] = address(0); // Clear owner for inactive patch

        // Mint the new merged patch
        // We use the color/texture of the first patch for the new merged one for simplicity
        uint256 newPatchId = _mintPatch(msg.sender, newX, newY, newW, newH, patch1.color, patch1.textureId);

        // Note: _mintPatch already updates the _coordToPatchId mapping for the new area.
        // The coordinates previously pointing to patch1 or patch2 will now point to newPatchId.

        emit PatchMerged(_patchId1, _patchId2, newPatchId);
    }

    /// @notice Transfers ownership of a patch.
    /// @param _to The recipient address.
    /// @param _patchId The ID of the patch to transfer.
    function transferPatch(address _to, uint256 _patchId) public {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);
        require(_to != address(0), "Transfer to zero address");

        _transferPatch(msg.sender, _to, _patchId);
    }

    /// @notice Approves an address to manage a patch on behalf of the owner.
    /// @param _approved The address to approve.
    /// @param _patchId The ID of the patch.
    function approvePatchTransfer(address _approved, uint256 _patchId) external {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != msg.sender) revert NotPatchOwner(_patchId);

        _patchApprovals[_patchId] = _approved;
        emit PatchApproval(_patchId, msg.sender, _approved);
    }

    /// @notice Transfers ownership of a patch from one address to another, usually by an approved address.
    /// @param _from The current owner address.
    /// @param _to The recipient address.
    /// @param _patchId The ID of the patch to transfer.
    function transferPatchFrom(address _from, address _to, uint256 _patchId) external {
        Patch storage patch = _patches[_patchId];
        if (!_isPatchActive(patch)) revert PatchNotFound(_patchId);
        if (_patchOwners[_patchId] != _from) revert NotPatchOwner(_patchId); // Check _from is the actual owner
        if (msg.sender != _from && _patchApprovals[_patchId] != msg.sender) revert NotApprovedOrOwner(_patchId);
        require(_to != address(0), "Transfer to zero address");

        _transferPatch(_from, _to, _patchId);
        _patchApprovals[_patchId] = address(0); // Clear approval after transfer
    }

    // --- Epoch Mechanics ---

    /// @notice Advances the epoch if the current epoch duration has passed.
    /// Anyone can call this to trigger the epoch transition and effects.
    function advanceEpoch() external whenEpochCanAdvance {
        uint256 elapsedEpochs = (block.timestamp - epochStartTime) / epochDuration;
        // Update start time to align with the start of the new epoch
        epochStartTime += elapsedEpochs * epochDuration;
        currentEpoch += elapsedEpochs;

        _applyEpochEffect();

        emit EpochAdvanced(currentEpoch, epochStartTime, epochStartTime + epochDuration);
    }

    // --- Governance ---

    /// @notice Allows a patch owner to propose a change or feature idea.
    /// @param _description A text description of the proposal.
    /// @param _votingDuration The duration for voting on this proposal in seconds.
    function proposeChange(string calldata _description, uint256 _votingDuration) external costEssence(essenceActionCost) {
        uint256 votingPower = getUserVotingPower(msg.sender);
        if (votingPower == 0) revert ZeroVotingPower();

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + _votingDuration,
            totalYesVotesArea: 0,
            totalNoVotesArea: 0,
            executed: false,
            passed: false, // Default to false
            cancelled: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description, block.timestamp + _votingDuration);
    }

    /// @notice Allows a patch owner to vote Yes or No on an active proposal.
    /// Voting power is based on the total area of the voter's active patches at the time of voting.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for Yes, False for No.
    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0 || proposal.cancelled || proposal.executed) revert ProposalNotFound(_proposalId);
        if (block.timestamp > proposal.votingEndTime) revert ProposalVotingEnded(_proposalId);
        if (_userHasVotedOnProposal[_proposalId][msg.sender]) revert AlreadyVoted(_proposalId);

        uint256 votingPower = getUserVotingPower(msg.sender);
        if (votingPower == 0) revert ZeroVotingPower(); // Must own patches to vote

        if (_vote) {
            proposal.totalYesVotesArea += votingPower;
        } else {
            proposal.totalNoVotesArea += votingPower;
        }

        _userHasVotedOnProposal[_proposalId][msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _vote, votingPower);
    }

    /// @notice Can be called after a proposal's voting period ends to record the outcome.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0 || proposal.cancelled || proposal.executed) revert ProposalNotFound(_proposalId);
        if (block.timestamp <= proposal.votingEndTime) revert ProposalNotActive(_proposalId); // Voting period must be over

        uint256 totalVotesArea = proposal.totalYesVotesArea + proposal.totalNoVotesArea;
        if (totalVotesArea > 0) {
            // Calculate if Yes votes meet the threshold
            proposal.passed = (proposal.totalYesVotesArea * proposalVoteThresholdDenominator >= totalVotesArea * proposalVoteThresholdNumerator);
        } else {
            // If no one voted, the proposal does not pass (or define a different rule)
            proposal.passed = false;
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /// @notice Allows the proposer or admin to cancel a proposal before voting ends or execution.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (proposal.cancelled) revert ProposalAlreadyCancelled(_proposalId);

        if (msg.sender != proposal.proposer && msg.sender != admin) revert NotProposalCreatorOrAdmin();

        proposal.cancelled = true;
        emit ProposalCancelled(_proposalId);
    }

    // --- Read Functions ---

    /// @notice Returns the canvas dimensions.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Returns details for a specific patch.
    /// @param _patchId The ID of the patch.
    /// @return patch The Patch struct details.
    function getPatchDetails(uint256 _patchId) external view returns (Patch memory patch) {
        if (_patchId == 0 || _patchId > _patchCounter) {
            // Return a default empty patch or revert
            return Patch(0, 0, 0, 0, 0, 0, 0, false);
        }
        return _patches[_patchId];
    }

    /// @notice Returns the owner of a specific patch.
    /// @param _patchId The ID of the patch.
    /// @return owner The owner's address (address(0) if inactive or not found).
    function getPatchOwner(uint256 _patchId) external view returns (address owner) {
        if (_patchId == 0 || _patchId > _patchCounter || !_patches[_patchId].isActive) {
             return address(0);
        }
        return _patchOwners[_patchId];
    }

    /// @notice Returns the patch ID at a specific coordinate.
    /// @param _x X coordinate.
    /// @param _y Y coordinate.
    /// @return patchId The ID of the patch occupying the coordinate, or 0 if empty.
    function getPatchIdAtCoord(uint256 _x, uint256 _y) external view returns (uint256 patchId) {
        if (_x >= canvasWidth || _y >= canvasHeight) {
            revert InvalidCoordinates(_x, _y);
        }
        return _coordToPatchId[_x][_y];
    }

    /// @notice Returns the total number of patches ever minted (including inactive).
    /// @return The total count.
    function getTotalPatches() external view returns (uint256) {
        return _patchCounter;
    }

    /// @notice Returns the current number of active patches.
    /// @dev This function iterates through all minted patches up to _patchCounter.
    ///      Its gas cost increases with the total number of patches minted over time.
    /// @return The count of active patches.
    function getActivePatchCount() external view returns (uint256) {
        uint256 activeCount = 0;
        // Note: Iterating through a mapping like this is only possible if keys are sequential (like _patchCounter)
        // and you stop at a known limit. Checking isActive is necessary.
        for (uint256 i = 1; i <= _patchCounter; ++i) {
            if (_patches[i].isActive) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /// @notice Returns the Essence balance for an address.
    /// @param _owner The address to check.
    /// @return balance The Essence balance.
    function getEssenceBalance(address _owner) external view returns (uint256 balance) {
        return _essenceBalances[_owner];
    }

    /// @notice Returns the current epoch number.
    /// @return The current epoch.
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the timestamp when the current epoch ends.
    /// @return The end time.
    function getEpochEndTime() external view returns (uint256) {
        return epochStartTime + epochDuration;
    }

    /// @notice Returns the current Essence costs for minting and actions.
    /// @return mintCost The cost to mint.
    /// @return actionCost The base action cost.
    function getEssenceCosts() external view returns (uint256 mintCost, uint256 actionCost) {
        return (essenceMintCost, essenceActionCost);
    }

    /// @notice Returns the minimum allowed patch dimension.
    /// @return The minimum size.
    function getMinPatchSize() external view returns (uint256) {
        return minPatchSize;
    }

    /// @notice Returns details for a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposal The Proposal struct details.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory proposal) {
        if (_proposalId == 0 || _proposalId > _proposalCounter) {
            // Return default or revert
            return Proposal(0, address(0), "", 0, 0, 0, 0, false, false, false);
        }
        return _proposals[_proposalId];
    }

    /// @notice Returns a list of IDs for active (not executed or cancelled) proposals.
    /// @dev This function iterates through all minted proposals up to _proposalCounter.
    ///      Its gas cost increases with the total number of proposals over time.
    /// @return An array of active proposal IDs.
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](_proposalCounter); // Max possible size
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= _proposalCounter; ++i) {
            if (_proposals[i].id != 0 && !_proposals[i].executed && !_proposals[i].cancelled) {
                activeIds[activeCount] = i;
                activeCount++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](activeCount);
        for (uint256 i = 0; i < activeCount; ++i) {
            result[i] = activeIds[i];
        }
        return result;
    }

    /// @notice Calculates the total area of active patches owned by an address. Used for governance voting power.
    /// @dev This function iterates through all minted patches up to _patchCounter.
    ///      Its gas cost increases with the total number of patches minted over time.
    /// @param _owner The address to check.
    /// @return The total area of active patches owned by the address.
    function getUserVotingPower(address _owner) public view returns (uint256) {
        uint256 totalArea = 0;
         for (uint256 i = 1; i <= _patchCounter; ++i) {
            if (_patches[i].isActive && _patchOwners[i] == _owner) {
                totalArea += _patches[i].width * _patches[i].height;
            }
        }
        return totalArea;
    }

    // --- Internal/Private Helper Functions ---

    /// @dev Creates a new patch and updates state. Assumes area check and cost are handled externally.
    /// @param _owner The address to assign ownership to.
    /// @param _x X coordinate.
    /// @param _y Y coordinate.
    /// @param _width Width.
    /// @param _height Height.
    /// @param _color Color.
    /// @param _textureId Texture ID.
    /// @return The ID of the newly minted patch.
    function _mintPatch(
        address _owner,
        uint256 _x,
        uint256 _y,
        uint256 _width,
        uint256 _height,
        uint32 _color,
        uint16 _textureId
    ) private returns (uint256) {
         // These checks are done in public calling functions like mintInitialPatch/splitPatch/mergePatches
        // _checkArea(_x, _y, _width, _height); // Bounds and empty check
        // require(_owner != address(0), "Mint to zero address");

        _patchCounter++;
        uint256 newPatchId = _patchCounter;

        _patches[newPatchId] = Patch({
            id: newPatchId,
            x: _x,
            y: _y,
            width: _width,
            height: _height,
            color: _color,
            textureId: _textureId,
            isActive: true // Mark as active upon creation
        });

        _patchOwners[newPatchId] = _owner;

        // Update coordinate mapping
        for (uint256 i = _x; i < _x + _width; ++i) {
            for (uint256 j = _y; j < _y + _height; ++j) {
                _coordToPatchId[i][j] = newPatchId;
            }
        }

        emit PatchMinted(newPatchId, _owner, _x, _y, _width, _height);
        return newPatchId;
    }

    /// @dev Checks if a patch is active.
    function _isPatchActive(Patch storage _patch) private view returns (bool) {
        return _patch.id != 0 && _patch.isActive;
    }


    /// @dev Transfers a patch internally. Assumes ownership/approval checks are done externally.
    /// @param _from The current owner.
    /// @param _to The recipient.
    /// @param _patchId The ID of the patch.
    function _transferPatch(address _from, address _to, uint256 _patchId) private {
        // Assumes _patchId is active and _from is the owner
        _patchOwners[_patchId] = _to;
        emit PatchTransfer(_patchId, _from, _to);
    }

    /// @dev Checks if a given rectangular area is within canvas bounds and entirely empty.
    /// @param _x X coordinate of top-left corner.
    /// @param _y Y coordinate of top-left corner.
    /// @param _width Width.
    /// @param _height Height.
    function _checkArea(uint256 _x, uint256 _y, uint256 _width, uint256 _height) private view {
        if (_width == 0 || _height == 0) revert InvalidDimensions(_width, _height);
        if (_x >= canvasWidth || _y >= canvasHeight) revert InvalidCoordinates(_x, _y);
        if (_x + _width > canvasWidth || _y + _height > canvasHeight) revert InvalidDimensions(_width, _height);

        for (uint256 i = _x; i < _x + _width; ++i) {
            for (uint256 j = _y; j < _y + _height; ++j) {
                if (_coordToPatchId[i][j] != 0) revert AreaOccupied(i, j, 1, 1);
            }
        }
    }

    /// @dev Checks if a specific area that *should* be occupied by a patch *is* occupied by that patch.
     /// Useful for validating merge/split areas before modifying state.
    function _checkAreaIsOccupiedByPatch(uint256 _patchId, uint256 _x, uint256 _y, uint256 _width, uint256 _height) private view {
        if (_width == 0 || _height == 0) revert InvalidDimensions(_width, _height);
        if (_x >= canvasWidth || _y >= canvasHeight) revert InvalidCoordinates(_x, _y);
        if (_x + _width > canvasWidth || _y + _height > canvasHeight) revert InvalidDimensions(_width, _height);

         for (uint256 i = _x; i < _x + _width; ++i) {
            for (uint256 j = _y; j < _y + _height; ++j) {
                if (_coordToPatchId[i][j] != _patchId) revert AreaNotOccupiedByPatch(_patchId, i, j, 1, 1);
            }
        }
    }

    /// @dev Checks only the *newly added* area during an expansion is empty.
    /// @param _oldPatch The patch being expanded.
    /// @param _newX New X.
    /// @param _newY New Y.
    /// @param _newWidth New Width.
    /// @param _newHeight New Height.
    function _checkNewExpansionAreaEmpty(
        Patch storage _oldPatch,
        uint256 _newX,
        uint256 _newY,
        uint256 _newWidth,
        uint256 _newHeight
    ) private view {
        for (uint256 i = _newX; i < _newX + _newWidth; ++i) {
            for (uint256 j = _newY; j < _newY + _newHeight; ++j) {
                 // Check if this coordinate is outside the bounds of the *old* patch
                if (i < _oldPatch.x || i >= _oldPatch.x + _oldPatch.width || j < _oldPatch.y || j >= _oldPatch.y + _oldPatch.height) {
                    // If it's outside the old patch, it must be empty (0)
                    if (_coordToPatchId[i][j] != 0) {
                        revert AreaOccupied(i, j, 1, 1); // This part of the new area is already taken
                    }
                }
            }
        }
    }

    /// @dev Spends Essence from a user's balance.
    /// @param _spender The address spending Essence.
    /// @param _amount The amount to spend.
    /// @param _actionIdentifier String describing the action (e.g., function signature).
    function _spendEssence(address _spender, uint256 _amount, string memory _actionIdentifier) private {
        if (_essenceBalances[_spender] < _amount) {
            revert InsufficientEssence(_amount, _essenceBalances[_spender]);
        }
        _essenceBalances[_spender] -= _amount;
        emit EssenceSpent(_spender, _amount, _actionIdentifier);
    }

    /// @dev Applies epoch-end effects. Called by advanceEpoch.
    /// Currently distributes Essence based on active patch area.
    function _applyEpochEffect() private {
        uint256 totalEssenceDistributed = 0;
        // Iterate through all patches ever minted. Check if active.
        // This loop's gas cost is proportional to _patchCounter.
        for (uint256 i = 1; i <= _patchCounter; ++i) {
            if (_patches[i].isActive) {
                uint256 patchArea = _patches[i].width * _patches[i].height;
                uint256 essenceEarned = patchArea * epochEssencePerArea;
                if (essenceEarned > 0) {
                    address owner = _patchOwners[i];
                     // Defensive check, although owner should not be address(0) for active patches
                    if (owner != address(0)) {
                         _essenceBalances[owner] += essenceEarned;
                         totalEssenceDistributed += essenceEarned;
                    }
                }
            }
        }
        emit EpochEffectApplied(currentEpoch, totalEssenceDistributed);
    }

    // Allow receiving ETH for Essence purchases
    receive() external payable {
        buyEssence();
    }

    fallback() external payable {
        // Optional: Revert if Ether is sent without calling buyEssence explicitly, or route to buyEssence
        // Reverting is safer for unexpected calls.
        revert("Fallback function not implemented/allowed. Send ETH to buyEssence.");
    }
}
```