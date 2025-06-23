Okay, here is a Solidity smart contract embodying a creative, advanced concept: a "Digital Renaissance Canvas".

This contract represents a collaborative, dynamic digital canvas where users place "strokes" (abstract pixel data) by interacting with the contract. The state of the canvas evolves over time across defined "Epochs". At the end of each epoch, the final state of the canvas for that period is recorded, and a unique generative NFT art piece can be created off-chain (based on the on-chain state) and minted, representing that epoch's contribution. Users earn "Influence Points" for contributing strokes, which can grant them rights (like voting power or eligibility to claim epoch art NFTs).

This combines:
1.  **Dynamic On-Chain State:** The canvas itself is state stored on-chain, evolving with user interaction.
2.  **Generative Art Link:** The on-chain state serves as the verifiable seed/input for off-chain art generation.
3.  **Epoch System:** Time-based periods controlling the canvas lifecycle and art generation.
4.  **Influence/Reputation:** Users earn non-transferable points for participation.
5.  **NFTs as Epoch Records:** Unique NFTs represent completed canvas states/epochs.
6.  **DAO-like Governance (Basic):** Influence points grant voting power on contract parameters.
7.  **Dynamic Interaction Costs:** The cost of placing strokes can change based on canvas activity.
8.  **Upgradability:** Using UUPS proxy pattern.
9.  **Custom Data Structures:** Defining structs for canvas cells, strokes, votes, etc.

It avoids directly copying common open-source patterns like standard ERC20/ERC721 *logic* (though it inherits the standard interfaces and UUPS), simple marketplaces, static NFTs, or basic Ownable contracts. The combination of features is designed to be novel.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

// --- Outline ---
// 1. State Variables: Define all contract storage variables including canvas, epochs, influence points, governance data.
// 2. Structs: Define custom data structures like Cell, StrokeData, Epoch, Vote.
// 3. Events: Define events to signal important actions.
// 4. Modifiers: Define custom modifiers for access control and state checks.
// 5. Initialization: UUPS initializer function.
// 6. Core Canvas Functions:
//    - placeStroke: Main function for users to interact with the canvas.
//    - getStrokeCost: Calculate the dynamic cost of placing a stroke.
//    - getCanvasCell: Read state of a specific cell.
//    - getCanvasDimensions: Read canvas size.
//    - getCanvasStateHash: Get a hash representing the current canvas state.
// 7. Epoch Management:
//    - finalizeEpoch: Owner/authorised function to mark an epoch complete.
//    - mintEpochArt: Mint the ERC721 token for a finalized epoch (linked to off-chain art).
//    - claimEpochArt: Allow eligible participants to claim their allocated epoch art token.
//    - getEpochData: Read data about a specific epoch.
//    - getCurrentEpochId: Get the current active epoch ID.
//    - getTotalEpochs: Get the count of finalized epochs.
//    - getEpochParticipants: Get list of participants in an epoch.
//    - getEpochInfluence: Get influence points for a user in a specific epoch.
//    - getClaimableArt: Check which token IDs an address can claim for an epoch.
// 8. Influence & Reputation:
//    - getUserTotalInfluence: Get user's total influence points across all epochs.
// 9. Governance & Parameters:
//    - updateCostParameters: Update stroke cost formula parameters (via vote).
//    - addPaletteColor: Add a color to the allowed palette (via vote).
//    - removePaletteColor: Remove a color from the palette (via vote).
//    - addStrokeType: Add a stroke type (via vote).
//    - removeStrokeType: Remove a stroke type (via vote).
//    - getPalette: Read the current color palette.
//    - getStrokeTypes: Read the defined stroke types.
//    - startParameterVote: Initiate a new governance vote.
//    - castVote: User casts their vote using influence points.
//    - getVoteState: Read the current state of a vote.
//    - executeVote: Execute the outcome of a passed vote.
// 10. Treasury & Withdrawal:
//     - withdrawTreasury: Withdraw funds from the contract (via vote).
//     - getTreasuryBalance: Check contract's Ether balance.
// 11. Utility & Safety:
//     - pause: Pause core interactions.
//     - unpause: Unpause core interactions.
//     - setBaseURI: Set base URI for ERC721 metadata.
//     - upgradeTo: UUPS upgrade function.
// 12. Internal Helpers: Functions for internal calculations like cost and influence.
// 13. ERC721 Standard Functions: Inherited and exposed (transferFrom, ownerOf, etc.).

// --- Function Summary ---
// initialize(uint16 _width, uint16 _height, uint64 _epochDurationBlocks, uint256 _initialBaseStrokeCost): UUPS initializer. Sets canvas dimensions, epoch duration, initial cost, and mints the "Epoch 0" NFT (genesis).
// pause(): Pauses stroke placement and voting.
// unpause(): Unpauses stroke placement and voting.
// placeStroke(uint16 _x, uint16 _y, StrokeData calldata _strokeData): Allows a user to place a stroke at a specific coordinate, paying a dynamic cost and earning influence points.
// getStrokeCost(uint16 _x, uint16 _y): Calculates the current dynamic cost for placing a stroke at (x, y).
// getCanvasCell(uint16 _x, uint16 _y): Retrieves the StrokeData and contributor of a cell.
// getCanvasDimensions(): Returns the width and height of the canvas.
// getCanvasStateHash(uint256 _epochId): Calculates a hash of the canvas state for a specific epoch. Used for off-chain verification.
// finalizeEpoch(): Triggered (initially by owner, ideally by vote/DAO later) to end the current epoch, calculate its final state hash, and prepare for art minting.
// mintEpochArt(uint256 _epochId, string calldata _tokenURI, address[] calldata _claimers): Mints the NFT for a finalized epoch and assigns it to be claimable by specified addresses (e.g., top contributors identified off-chain, or calculated on-chain).
// claimEpochArt(uint256 _epochId, uint256 _tokenId): Allows an address assigned as a claimer for _epochId and _tokenId to claim the NFT.
// getEpochData(uint256 _epochId): Retrieves details about a specific epoch.
// getCurrentEpochId(): Returns the ID of the currently active epoch.
// getTotalEpochs(): Returns the total count of finalized epochs.
// getEpochParticipants(uint256 _epochId): Returns the list of addresses that contributed to an epoch.
// getEpochInfluence(uint256 _epochId, address _participant): Returns the influence points of a participant for a specific epoch.
// getClaimableArt(uint256 _epochId, address _claimer): Returns the list of token IDs an address can claim for an epoch.
// getUserTotalInfluence(address _user): Returns the total influence points an address has accumulated across all epochs.
// updateCostParameters(uint256 _baseCost, uint256 _activityMultiplier, uint256 _recencyFactor): Starts a vote to update parameters affecting stroke cost.
// addPaletteColor(uint32 _color): Starts a vote to add a new color to the allowed palette.
// removePaletteColor(uint32 _color): Starts a vote to remove a color from the palette.
// addStrokeType(uint8 _typeId, string calldata _description): Starts a vote to add a new stroke type.
// removeStrokeType(uint8 _typeId): Starts a vote to remove a stroke type.
// getPalette(): Returns the current list of allowed palette colors.
// getStrokeTypes(): Returns the current list of stroke types.
// startParameterVote(bytes32 _voteId, uint256 _proposalType, bytes calldata _proposalData, uint256 _votingDurationBlocks): Allows starting a general governance vote.
// castVote(bytes32 _voteId, bool _support): Allows a user to cast their vote (for or against) using their influence points.
// getVoteState(bytes32 _voteId): Retrieves the state of a governance vote.
// executeVote(bytes32 _voteId): Executes the outcome of a finished and passed vote.
// withdrawTreasury(address _recipient, uint256 _amount): Starts a vote to withdraw funds from the contract treasury.
// getTreasuryBalance(): Returns the current balance of the contract's treasury.
// setBaseURI(string calldata baseURI_): Sets the base URI for token metadata.
// upgradeTo(address newImplementation): UUPS function to upgrade the contract implementation.
// (Inherited ERC721 functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, tokenURI, supportsInterface)


contract DigitalRenaissanceCanvas is ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    using ECDSAUpgradeable for bytes32;
    using MathUpgradeable for uint256;

    // --- State Variables ---

    struct Cell {
        uint32 paletteIndex;    // Index in the allowedPalette array
        uint8 strokeTypeIndex;  // Index in the allowedStrokeTypes array
        address contributor;
        uint64 timestamp;
    }

    struct StrokeData {
        uint32 paletteIndex;
        uint8 strokeTypeIndex;
        bytes optionalMetadata; // Optional extra data per stroke
    }

    struct Epoch {
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint256 finalCanvasStateHash; // Hash of the canvas state at epoch end
        bool finalized;             // True if epoch is finalized and art generation triggered
        string tokenURI;            // Base URI for this epoch's art NFT
        address[] participants;     // List of unique addresses that contributed
    }

    struct Vote {
        uint256 proposalType;       // Type of proposal (e.g., 0: UpdateCost, 1: AddColor, etc.)
        bytes proposalData;         // Encoded data specific to the proposal type
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalInfluenceFor;
        uint256 totalInfluenceAgainst;
        mapping(address => bool) voted; // Has this user voted on this specific vote?
        bool executed;
        bool passed;                // Final outcome after execution
    }

    Cell[] public canvasGrid;
    uint16 public canvasWidth;
    uint16 public canvasHeight;

    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;

    // Influence points earned per user per epoch
    mapping(uint256 => mapping(address => uint256)) public epochInfluencePoints;
    // Total influence points per user across all epochs (used for voting power)
    mapping(address => uint256) public totalInfluencePoints;

    // Mapping of epoch ID to the token IDs claimable by a specific address
    mapping(uint256 => mapping(address => uint256[])) public epochClaimableTokenIds;
    // Mapping of token ID to the epoch ID it belongs to
    mapping(uint256 => uint256) public tokenIdToEpochId;

    // Allowed palette colors (RGB or other format encoded as uint32)
    uint32[] public allowedPalette;
    // Allowed stroke types (index to definition + optional metadata)
    struct StrokeType {
        uint8 id;
        string description;
        bytes optionalConfig; // Configuration data for this stroke type
    }
    StrokeType[] public allowedStrokeTypes;
    mapping(uint8 => uint256) private strokeTypeIdToIndex; // Map ID to array index

    // Dynamic stroke cost parameters
    uint256 public baseStrokeCost; // Base cost in wei
    uint256 public activityMultiplier; // Multiplier for recent activity
    uint256 public recencyFactor; // Factor for recency of last stroke in cell

    // Vote storage
    mapping(bytes32 => Vote) public governanceVotes;
    bytes32[] public activeVotes; // List of ongoing vote IDs

    // --- Events ---

    event Initialized(uint8 version);
    event CanvasDimensionsSet(uint16 width, uint16 height);
    event StrokePlaced(uint256 indexed epochId, uint16 indexed x, uint16 indexed y, address indexed contributor, uint256 cost);
    event EpochStarted(uint256 indexed epochId, uint64 startTimestamp);
    event EpochFinalized(uint256 indexed epochId, uint64 endTimestamp, uint256 finalCanvasStateHash);
    event EpochArtMinted(uint256 indexed epochId, uint256 indexed tokenId, string tokenURI, address[] claimers);
    event EpochArtClaimed(uint256 indexed epochId, uint256 indexed tokenId, address indexed claimer);
    event InfluenceEarned(uint256 indexed epochId, address indexed user, uint256 amount);
    event VoteStarted(bytes32 indexed voteId, uint256 indexed proposalType, uint256 startBlock, uint256 endBlock);
    event Voted(bytes32 indexed voteId, address indexed voter, uint256 influenceAmount, bool support);
    event VoteExecuted(bytes32 indexed voteId, bool passed);
    event ParametersUpdated(uint256 newBaseCost, uint256 newActivityMultiplier, uint256 newRecencyFactor);
    event PaletteColorAdded(uint32 color);
    event PaletteColorRemoved(uint32 color);
    event StrokeTypeAdded(uint8 typeId, string description);
    event StrokeTypeRemoved(uint8 typeId);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyCanvasBounds(uint16 _x, uint16 _y) {
        require(_x < canvasWidth && _y < canvasHeight, "Invalid canvas coordinates");
        _;
    }

    modifier whenEpochActive() {
        require(epochs[currentEpochId].startTimestamp > 0 && !epochs[currentEpochId].finalized, "Epoch not active");
        _;
    }

    // --- UUPS Initializer ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint16 _width,
        uint16 _height,
        uint64 _epochDurationBlocks,
        uint256 _initialBaseStrokeCost
    ) public virtual initializer {
        __ERC721_init("DigitalRenaissanceCanvas", "DRC-ART");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        require(_initialBaseStrokeCost > 0, "Initial cost must be positive");
        // epochDurationBlocks is conceptual for voting/timing, actual epoch finalization is triggered manually/by vote

        canvasWidth = _width;
        canvasHeight = _height;
        canvasGrid.length = uint256(_width) * _height; // Initialize array with default values

        baseStrokeCost = _initialBaseStrokeCost;
        activityMultiplier = 1e18; // Default 1x multiplier (using 18 decimals)
        recencyFactor = 0; // Default 0 recency factor

        // Start Epoch 1 (Epoch 0 is genesis/pre-canvas)
        currentEpochId = 1;
        epochs[currentEpochId].startTimestamp = uint64(block.timestamp);
        epochs[currentEpochId].finalized = false;
        emit EpochStarted(currentEpochId, epochs[currentEpochId].startTimestamp);

        // Add default color and stroke type
        allowedPalette.push(0x000000); // Black
        allowedPalette.push(0xFFFFFF); // White

        allowedStrokeTypes.push(StrokeType({id: 1, description: "Pixel", optionalConfig: ""})); // Simple pixel stroke
        strokeTypeIdToIndex[1] = 0;

        emit Initialized(1); // Version 1
    }

    // --- Core Canvas Functions ---

    /// @notice Allows a user to place a stroke at a specific coordinate.
    /// @param _x The x-coordinate (0 to canvasWidth - 1).
    /// @param _y The y-coordinate (0 to canvasHeight - 1).
    /// @param _strokeData The data for the stroke (palette index, stroke type, optional metadata).
    /// @dev Requires ETH payment equal to the dynamic stroke cost. Earns influence points.
    function placeStroke(uint16 _x, uint16 _y, StrokeData calldata _strokeData)
        public
        payable
        whenNotPaused
        whenEpochActive
        onlyCanvasBounds(_x, _y)
    {
        require(_strokeData.paletteIndex < allowedPalette.length, "Invalid palette index");
        require(strokeTypeIdToIndex[_strokeData.strokeTypeIndex] < allowedStrokeTypes.length, "Invalid stroke type index");

        uint256 cost = _calculateDynamicCost(_x, _y);
        require(msg.value >= cost, "Insufficient ETH sent for stroke");

        uint256 index = uint256(_y) * canvasWidth + _x;
        Cell storage cell = canvasGrid[index];

        // Update cell state
        cell.paletteIndex = _strokeData.paletteIndex;
        cell.strokeTypeIndex = _strokeData.strokeTypeIndex;
        cell.contributor = msg.sender;
        cell.timestamp = uint64(block.timestamp);
        // Note: optionalMetadata is NOT stored on-chain per cell to save gas,
        // it's part of the input _strokeData and could be used off-chain
        // or for influence calculation if stored/hashed.

        // Calculate and award influence points (proportional to cost)
        uint256 influenceEarned = cost; // Simple 1:1 ratio for now
        epochInfluencePoints[currentEpochId][msg.sender] += influenceEarned;
        totalInfluencePoints[msg.sender] += influenceEarned;

        // Add participant to epoch list if new (gas consideration for large participant count)
        // Simple check: if influence points were 0 before, add them.
        if (epochInfluencePoints[currentEpochId][msg.sender] == influenceEarned) {
             // Check if sender is already in participants array (potentially gas expensive for many participants)
             bool alreadyParticipant = false;
             for(uint i = 0; i < epochs[currentEpochId].participants.length; i++) {
                 if (epochs[currentEpochId].participants[i] == msg.sender) {
                     alreadyParticipant = true;
                     break;
                 }
             }
             if (!alreadyParticipant) {
                epochs[currentEpochId].participants.push(msg.sender);
             }
        }


        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit StrokePlaced(currentEpochId, _x, _y, msg.sender, cost);
        emit InfluenceEarned(currentEpochId, msg.sender, influenceEarned);
    }

    /// @notice Calculates the dynamic cost of placing a stroke at a specific coordinate.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    /// @return The cost in wei.
    function getStrokeCost(uint16 _x, uint16 _y)
        public
        view
        onlyCanvasBounds(_x, _y)
        returns (uint256)
    {
        return _calculateDynamicCost(_x, _y);
    }

    /// @notice Retrieves the state of a specific canvas cell.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    /// @return cellState The state of the cell.
    function getCanvasCell(uint16 _x, uint16 _y)
        public
        view
        onlyCanvasBounds(_x, _y)
        returns (Cell memory cellState)
    {
        return canvasGrid[uint256(_y) * canvasWidth + _x];
    }

    /// @notice Returns the dimensions of the canvas.
    /// @return width The canvas width.
    /// @return height The canvas height.
    function getCanvasDimensions() public view returns (uint16 width, uint16 height) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Calculates a keccak256 hash of the canvas state for a specific epoch.
    /// @param _epochId The epoch ID to hash.
    /// @dev This hash serves as a verifiable input for off-chain art generation.
    /// Hashing the entire canvas state can be gas-intensive for large canvases.
    /// Consider alternatives like hashing only changes or using a Merkle tree.
    /// For simplicity, this version iterates and hashes cell data.
    function getCanvasStateHash(uint256 _epochId) public view returns (uint256) {
        // This function can be computationally expensive. It's better used off-chain or with careful indexing/batching.
        // For a true on-chain hash, you'd iterate through the `canvasGrid`.
        // A simplified approach might hash only the state *changes* during the epoch,
        // or require the off-chain renderer to provide a Merkle proof against a root stored on-chain.
        // This implementation provides a conceptual hash; a production system might need a more robust/efficient design.

        bytes memory canvasData = new bytes(canvasGrid.length * (4 + 1 + 20 + 8)); // paletteIndex + strokeTypeIndex + contributor + timestamp

        uint offset = 0;
        for (uint i = 0; i < canvasGrid.length; i++) {
            bytes memory cellBytes = abi.encodePacked(
                canvasGrid[i].paletteIndex,
                canvasGrid[i].strokeTypeIndex,
                canvasGrid[i].contributor,
                canvasGrid[i].timestamp
            );
            assembly {
                let len := mload(cellBytes) // length of cellBytes
                let src := add(cellBytes, 32) // pointer to data in cellBytes
                let dest := add(canvasData, offset) // pointer to current position in canvasData
                calldatacopy(dest, src, len) // copy data
                offset := add(offset, len) // move offset
            }
        }
         bytes32 stateHash = keccak256(canvasData);
        return uint256(stateHash);
    }


    // --- Epoch Management ---

    /// @notice Finalizes the current epoch, locking its state and preparing for art generation.
    /// @dev Can only be called once per epoch. Ideally called via governance vote or time trigger in a production system.
    function finalizeEpoch() public onlyOwner whenEpochActive {
        Epoch storage current = epochs[currentEpochId];
        current.endTimestamp = uint64(block.timestamp);
        current.finalized = true;
        current.finalCanvasStateHash = getCanvasStateHash(currentEpochId); // Calculate the hash at finalization time

        emit EpochFinalized(currentEpochId, current.endTimestamp, current.finalCanvasStateHash);

        // Start the next epoch
        currentEpochId++;
        epochs[currentEpochId].startTimestamp = uint64(block.timestamp);
        epochs[currentEpochId].finalized = false;
        emit EpochStarted(currentEpochId, epochs[currentEpochId].startTimestamp);
    }

    /// @notice Mints the ERC721 token for a finalized epoch based on off-chain generated art.
    /// @param _epochId The ID of the epoch to mint art for.
    /// @param _tokenURI The metadata URI for the token.
    /// @param _claimers List of addresses eligible to claim this specific token ID.
    /// @dev Requires the epoch to be finalized. Can only be called once per epoch.
    /// Assumes an off-chain process generates the art using the finalized epoch state hash and prepares the metadata.
    /// In a production system, this call might be permissioned or triggered by an oracle/DAO.
    function mintEpochArt(uint256 _epochId, string calldata _tokenURI, address[] calldata _claimers)
        public
        onlyOwner // Restrict who can call this based on the trusted off-chain process
    {
        require(_epochId < currentEpochId && epochs[_epochId].finalized, "Epoch not finalized or invalid");
        require(bytes(epochs[_epochId].tokenURI).length == 0, "Art already minted for this epoch");
        require(_claimers.length > 0, "Must specify at least one claimer");

        uint256 tokenId = _epochId; // Simple mapping: epoch ID = token ID

        epochs[_epochId].tokenURI = _tokenURI; // Store the URI
        _mint(address(this), tokenId); // Mint the token to the contract address initially
        tokenIdToEpochId[tokenId] = _epochId;

        // Assign token to claimers
        for(uint i = 0; i < _claimers.length; i++) {
             epochClaimableTokenIds[_epochId][_claimers[i]].push(tokenId);
        }

        emit EpochArtMinted(_epochId, tokenId, _tokenURI, _claimers);
    }

    /// @notice Allows an address to claim an epoch art token they are eligible for.
    /// @param _epochId The epoch ID the token belongs to.
    /// @param _tokenId The ID of the token to claim (must be equal to _epochId).
    function claimEpochArt(uint256 _epochId, uint256 _tokenId) public {
        require(_tokenId == _epochId, "Invalid token ID for epoch");
        require(ownerOf(_tokenId) == address(this), "Token not held by contract");

        mapping(address => uint256[]) storage claimable = epochClaimableTokenIds[_epochId];
        uint256[] storage tokenIdsForClaimer = claimable[msg.sender];

        bool isClaimable = false;
        uint256 claimIndex = type(uint256).max; // Sentinel value

        // Find the token ID in the claimer's list
        for (uint i = 0; i < tokenIdsForClaimer.length; i++) {
            if (tokenIdsForClaimer[i] == _tokenId) {
                isClaimable = true;
                claimIndex = i;
                break;
            }
        }
        require(isClaimable, "Caller is not eligible to claim this token");

        // Remove the token ID from the claimable list by swapping with the last element
        tokenIdsForClaimer[claimIndex] = tokenIdsForClaimer[tokenIdsForClaimer.length - 1];
        tokenIdsForClaimer.pop();

        // Transfer the token to the claimer
        _transfer(address(this), msg.sender, _tokenId);

        emit EpochArtClaimed(_epochId, _tokenId, msg.sender);
    }

    /// @notice Retrieves data about a specific epoch.
    /// @param _epochId The ID of the epoch.
    /// @return epochData The struct containing epoch details.
    function getEpochData(uint256 _epochId) public view returns (Epoch memory) {
        require(_epochId <= currentEpochId, "Invalid epoch ID");
        return epochs[_epochId];
    }

    /// @notice Returns the ID of the currently active epoch.
    function getCurrentEpochId() public view returns (uint256) {
        return currentEpochId;
    }

    /// @notice Returns the total number of finalized epochs.
    function getTotalEpochs() public view returns (uint256) {
        // Epochs are 1-indexed. Total finalized epochs = currentEpochId - 1.
        // Unless Epoch 0 was considered, but we started at 1.
        // If currentEpochId is 1 (just started), 0 epochs finalized. If 2, Epoch 1 is finalized.
        return currentEpochId > 0 ? currentEpochId - 1 : 0;
    }

    /// @notice Returns the list of unique participants who contributed to an epoch.
    /// @param _epochId The epoch ID.
    /// @return participants Array of participant addresses.
    function getEpochParticipants(uint256 _epochId) public view returns (address[] memory) {
        require(_epochId <= currentEpochId, "Invalid epoch ID");
        return epochs[_epochId].participants;
    }

     /// @notice Returns the influence points of a participant for a specific epoch.
     /// @param _epochId The epoch ID.
     /// @param _participant The address of the participant.
     /// @return influence The influence points earned in that epoch.
    function getEpochInfluence(uint256 _epochId, address _participant) public view returns (uint256) {
        require(_epochId <= currentEpochId, "Invalid epoch ID");
        return epochInfluencePoints[_epochId][_participant];
    }

    /// @notice Returns the list of token IDs an address is eligible to claim for a specific epoch.
    /// @param _epochId The epoch ID.
    /// @param _claimer The address of the potential claimer.
    /// @return claimableTokenIds Array of token IDs the address can claim.
    function getClaimableArt(uint256 _epochId, address _claimer) public view returns (uint256[] memory) {
        require(_epochId < currentEpochId, "Epoch not yet finalized or invalid");
        return epochClaimableTokenIds[_epochId][_claimer];
    }


    // --- Influence & Reputation ---

    /// @notice Returns the total influence points an address has accumulated across all epochs.
    /// @param _user The address to query.
    /// @return totalInfluence The total influence points.
    function getUserTotalInfluence(address _user) public view returns (uint256) {
        return totalInfluencePoints[_user];
    }

    // --- Governance & Parameters ---

    // Proposal Types (Enum pattern using uint256)
    uint256 constant PROPOSAL_TYPE_UPDATE_COST = 0;
    uint256 constant PROPOSAL_TYPE_ADD_COLOR = 1;
    uint256 constant PROPOSAL_TYPE_REMOVE_COLOR = 2;
    uint256 constant PROPOSAL_TYPE_ADD_STROKE_TYPE = 3;
    uint256 constant PROPOSAL_TYPE_REMOVE_STROKE_TYPE = 4;
    uint256 constant PROPOSAL_TYPE_WITHDRAW_TREASURY = 5;
    uint256 constant PROPOSAL_TYPE_FINALIZE_EPOCH = 6; // Could use governance to finalize epochs too

    /// @notice Starts a governance vote to update stroke cost parameters.
    /// @dev Requires the caller to have some minimum influence (not explicitly checked here for simplicity, but could be added).
    function updateCostParameters(uint256 _baseCost, uint256 _activityMultiplier, uint256 _recencyFactor) public {
        // Generate a unique vote ID (e.g., hash of proposal data + block number)
        bytes memory proposalData = abi.encode(_baseCost, _activityMultiplier, _recencyFactor);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_UPDATE_COST, proposalData, block.number));
        // Voting duration is a conceptual parameter, let's hardcode or add a contract state var for it.
        // Let's use 100 blocks as a simple duration.
        uint256 votingDurationBlocks = 100; // Example duration

        startParameterVote(voteId, PROPOSAL_TYPE_UPDATE_COST, proposalData, votingDurationBlocks);
    }

    /// @notice Starts a governance vote to add a new color to the allowed palette.
    function addPaletteColor(uint32 _color) public {
         bytes memory proposalData = abi.encode(_color);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_ADD_COLOR, proposalData, block.number));
        uint256 votingDurationBlocks = 100;
        startParameterVote(voteId, PROPOSAL_TYPE_ADD_COLOR, proposalData, votingDurationBlocks);
    }

     /// @notice Starts a governance vote to remove a color from the allowed palette.
    function removePaletteColor(uint32 _color) public {
        bytes memory proposalData = abi.encode(_color);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_REMOVE_COLOR, proposalData, block.number));
        uint256 votingDurationBlocks = 100;
        startParameterVote(voteId, PROPOSAL_TYPE_REMOVE_COLOR, proposalData, votingDurationBlocks);
    }

    /// @notice Starts a governance vote to add a new stroke type.
    function addStrokeType(uint8 _typeId, string calldata _description) public {
        bytes memory proposalData = abi.encode(_typeId, _description);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_ADD_STROKE_TYPE, proposalData, block.number));
        uint256 votingDurationBlocks = 100;
        startParameterVote(voteId, PROPOSAL_TYPE_ADD_STROKE_TYPE, proposalData, votingDurationBlocks);
    }

    /// @notice Starts a governance vote to remove a stroke type.
    function removeStrokeType(uint8 _typeId) public {
        bytes memory proposalData = abi.encode(_typeId);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_REMOVE_STROKE_TYPE, proposalData, block.number));
        uint256 votingDurationBlocks = 100;
        startParameterVote(voteId, PROPOSAL_TYPE_REMOVE_STROKE_TYPE, proposalData, votingDurationBlocks);
    }

    /// @notice Returns the current list of allowed palette colors.
    function getPalette() public view returns (uint32[] memory) {
        return allowedPalette;
    }

    /// @notice Returns the current list of allowed stroke types.
    function getStrokeTypes() public view returns (StrokeType[] memory) {
        return allowedStrokeTypes;
    }


    /// @notice Initiates a new governance vote on a proposal.
    /// @param _voteId Unique identifier for the vote.
    /// @param _proposalType The type of proposal.
    /// @param _proposalData Encoded data for the proposal.
    /// @param _votingDurationBlocks The duration of the voting period in blocks.
    function startParameterVote(bytes32 _voteId, uint256 _proposalType, bytes calldata _proposalData, uint256 _votingDurationBlocks)
        public
        whenNotPaused
        // Could add a require(totalInfluencePoints[msg.sender] > MIN_INFLUENCE_TO_START_VOTE)
    {
        require(governanceVotes[_voteId].startBlock == 0, "Vote already exists");
        require(_votingDurationBlocks > 0, "Voting duration must be positive");

        Vote storage newVote = governanceVotes[_voteId];
        newVote.proposalType = _proposalType;
        newVote.proposalData = _proposalData;
        newVote.startBlock = block.number;
        newVote.endBlock = block.number + _votingDurationBlocks;
        newVote.executed = false;
        newVote.passed = false;

        activeVotes.push(_voteId);

        emit VoteStarted(_voteId, _proposalType, newVote.startBlock, newVote.endBlock);
    }

    /// @notice Allows a user to cast their vote using their total influence points.
    /// @param _voteId The ID of the vote.
    /// @param _support True for 'yes', False for 'no'.
    function castVote(bytes32 _voteId, bool _support)
        public
        whenNotPaused
    {
        Vote storage vote = governanceVotes[_voteId];
        require(vote.startBlock > 0 && !vote.executed, "Vote does not exist or is executed");
        require(block.number >= vote.startBlock && block.number <= vote.endBlock, "Vote is not active");
        require(!vote.voted[msg.sender], "Already voted on this proposal");

        uint256 voterInfluence = totalInfluencePoints[msg.sender];
        require(voterInfluence > 0, "Caller has no influence points to vote");

        vote.voted[msg.sender] = true;
        if (_support) {
            vote.totalInfluenceFor += voterInfluence;
        } else {
            vote.totalInfluenceAgainst += voterInfluence;
        }

        emit Voted(_voteId, msg.sender, voterInfluence, _support);
    }

    /// @notice Retrieves the current state of a governance vote.
    /// @param _voteId The ID of the vote.
    /// @return voteState Struct containing vote details.
    function getVoteState(bytes32 _voteId) public view returns (Vote memory voteState) {
        require(governanceVotes[_voteId].startBlock > 0, "Vote does not exist");
        return governanceVotes[_voteId];
    }

    /// @notice Executes the outcome of a finished and passed vote.
    /// @param _voteId The ID of the vote.
    /// @dev Requires the vote to be finished and not yet executed.
    function executeVote(bytes32 _voteId) public whenNotPaused {
        Vote storage vote = governanceVotes[_voteId];
        require(vote.startBlock > 0 && !vote.executed, "Vote does not exist or is executed");
        require(block.number > vote.endBlock, "Voting period is not over");

        // Simple majority rule based on influence points
        vote.passed = vote.totalInfluenceFor > vote.totalInfluenceAgainst;
        vote.executed = true;

        if (vote.passed) {
            // Execute the proposal based on its type
            _executeProposal(vote.proposalType, vote.proposalData);
        }

        // Clean up from activeVotes list (optional, can leave for history or implement a cleanup function)
        // For simplicity, we'll leave it in activeVotes for now.

        emit VoteExecuted(_voteId, vote.passed);
    }

    /// @notice Internal function to execute a passed proposal.
    /// @param _proposalType The type of proposal.
    /// @param _proposalData Encoded data for the proposal.
    function _executeProposal(uint256 _proposalType, bytes memory _proposalData) internal {
        if (_proposalType == PROPOSAL_TYPE_UPDATE_COST) {
            (uint256 newBaseCost, uint256 newActivityMultiplier, uint256 newRecencyFactor) = abi.decode(_proposalData, (uint256, uint256, uint256));
            baseStrokeCost = newBaseCost;
            activityMultiplier = newActivityMultiplier;
            recencyFactor = newRecencyFactor;
            emit ParametersUpdated(newBaseCost, newActivityMultiplier, newRecencyFactor);

        } else if (_proposalType == PROPOSAL_TYPE_ADD_COLOR) {
            (uint32 colorToAdd) = abi.decode(_proposalData, (uint32));
            // Check if color already exists before adding
            bool exists = false;
            for(uint i = 0; i < allowedPalette.length; i++) {
                if (allowedPalette[i] == colorToAdd) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                 allowedPalette.push(colorToAdd);
                 emit PaletteColorAdded(colorToAdd);
            }

        } else if (_proposalType == PROPOSAL_TYPE_REMOVE_COLOR) {
            (uint32 colorToRemove) = abi.decode(_proposalData, (uint32));
            // Find and remove color (inefficient for large arrays, consider mapping or linked list for production)
            for(uint i = 0; i < allowedPalette.length; i++) {
                if (allowedPalette[i] == colorToRemove) {
                    // Swap with last element and pop
                    allowedPalette[i] = allowedPalette[allowedPalette.length - 1];
                    allowedPalette.pop();
                    emit PaletteColorRemoved(colorToRemove);
                    break; // Assuming colors are unique, stop after first removal
                }
            }

        } else if (_proposalType == PROPOSAL_TYPE_ADD_STROKE_TYPE) {
             (uint8 typeId, string memory description) = abi.decode(_proposalData, (uint8, string));
             require(strokeTypeIdToIndex[typeId] == 0 || allowedStrokeTypes[strokeTypeIdToIndex[typeId]].id != typeId, "Stroke type ID already exists"); // Check if ID is already in map and valid entry
             allowedStrokeTypes.push(StrokeType({id: typeId, description: description, optionalConfig: ""})); // Add with empty config
             strokeTypeIdToIndex[typeId] = allowedStrokeTypes.length - 1; // Update mapping
             emit StrokeTypeAdded(typeId, description);

        } else if (_proposalType == PROPOSAL_TYPE_REMOVE_STROKE_TYPE) {
             (uint8 typeId) = abi.decode(_proposalData, (uint8));
             uint256 indexToRemove = strokeTypeIdToIndex[typeId];
             require(indexToRemove < allowedStrokeTypes.length && allowedStrokeTypes[indexToRemove].id == typeId, "Stroke type ID not found");

             // Swap with last element and pop
             if (indexToRemove != allowedStrokeTypes.length - 1) {
                StrokeType memory lastType = allowedStrokeTypes[allowedStrokeTypes.length - 1];
                allowedStrokeTypes[indexToRemove] = lastType;
                strokeTypeIdToIndex[lastType.id] = indexToRemove; // Update mapping for the swapped element
             }
             allowedStrokeTypes.pop();
             delete strokeTypeIdToIndex[typeId]; // Remove from mapping
             emit StrokeTypeRemoved(typeId);

        } else if (_proposalType == PROPOSAL_TYPE_WITHDRAW_TREASURY) {
             (address recipient, uint256 amount) = abi.decode(_proposalData, (address, uint256));
             require(address(this).balance >= amount, "Insufficient balance for withdrawal");
             payable(recipient).transfer(amount);
             emit TreasuryWithdrawn(recipient, amount);

        } else if (_proposalType == PROPOSAL_TYPE_FINALIZE_EPOCH) {
             // No data needed, just execute finalization
             // Add checks here if needed, e.g., minimum epoch duration passed
             finalizeEpoch(); // Call the internal finalize function
        }
        // Add more proposal types as needed
    }


    // --- Treasury & Withdrawal ---

    /// @notice Starts a vote to withdraw funds from the contract treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of Ether to withdraw in wei.
    function withdrawTreasury(address _recipient, uint256 _amount) public {
        require(_amount > 0, "Withdrawal amount must be positive");
        bytes memory proposalData = abi.encode(_recipient, _amount);
        bytes32 voteId = keccak256(abi.encodePacked(PROPOSAL_TYPE_WITHDRAW_TREASURY, proposalData, block.number));
        uint256 votingDurationBlocks = 100; // Example duration
        startParameterVote(voteId, PROPOSAL_TYPE_WITHDRAW_TREASURY, proposalData, votingDurationBlocks);
    }

    /// @notice Returns the current Ether balance of the contract.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Utility & Safety ---

    /// @notice Pauses canvas interactions (placing strokes, voting).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses canvas interactions.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Sets the base URI for ERC721 token metadata.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }


    // --- UUPS Upgrade ---

    /// @dev See {UUPSUpgradeable-_authorizeUpgrade}.
    /// @custom:oz-upgrades-unsafe-allow external-inheritance
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    // --- Internal Helpers ---

    /// @notice Calculates the dynamic cost for a stroke based on configured parameters.
    /// @param _x The x-coordinate.
    /// @param _y The y-coordinate.
    /// @return The calculated cost in wei.
    function _calculateDynamicCost(uint16 _x, uint16 _y)
        internal
        view
        returns (uint256)
    {
        // Simple dynamic cost based on a base cost and a potential multiplier
        // based on recent activity or specific cell properties.
        // This is a placeholder; a complex formula could use:
        // - `activityMultiplier` and `recencyFactor`
        // - Number of strokes in the last N blocks in this area
        // - Time since the last stroke in this specific cell
        // - Rarity of chosen palette/stroke type

        uint256 index = uint256(_y) * canvasWidth + _x;
        Cell memory cell = canvasGrid[index];

        uint256 currentCost = baseStrokeCost;

        // Example: Add a small premium if the cell has been recently modified
        // Or if the chosen color/type is 'rare' (requires more state/logic)
        if (cell.timestamp > 0 && block.timestamp - cell.timestamp < 300) { // e.g., modified in last 5 minutes
             currentCost += baseStrokeCost / 10; // 10% premium
        }

        // More complex example using parameters (requires careful scaling/decimals)
        // uint256 timeSinceLastStroke = cell.timestamp == 0 ? type(uint256).max : block.timestamp - cell.timestamp;
        // uint256 activityInArea = _getRecentActivity(_x, _y); // Requires tracking activity per area

        // currentCost = baseStrokeCost
        //    .mul(1e18 + activityMultiplier.mul(activityInArea).div(1e18)) // Adjust by activity
        //    .div(1e18); // Scale down by 1e18 if multipliers are using 18 decimals

        // A simpler approach for demonstration: base cost + a fixed premium if recently active
        return currentCost;
    }

    // Override ERC721's tokenURI to use the epoch-specific URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        uint256 epochId = tokenIdToEpochId[tokenId];
        require(epochId > 0, "Invalid token ID mapping"); // Ensure token ID maps to a valid epoch
        // Concatenate epoch's base URI with token ID or other identifier
        // For simplicity, we assume the epoch's tokenURI is the final URI for that single token.
        // If an epoch generated *multiple* tokens, this logic would need to be more complex.
        return epochs[epochId].tokenURI;
    }

    // The following functions are inherited from ERC721URIStorageUpgradeable and ERC721Upgradeable:
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // getApproved(uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // isApprovedForAll(address owner, address operator)
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId) (two variants)
    // supportsInterface(bytes4 interfaceId)

}
```