Okay, let's design a smart contract called `CryptoCanvas`.

**Concept:** `CryptoCanvas` is a dynamic, collaborative on-chain art piece represented by a single unique NFT. Users can apply "brush strokes" or "patterns" to specific coordinates on the canvas, paying a fee. The canvas data evolves over time as strokes can decay. Staking tokens (or Ether) grants users voting power for governance decisions, such as modifying canvas parameters, adding new brush types, or withdrawing accumulated fees. Users can also define and share their own patterns.

**Advanced/Creative Concepts:**
1.  **Dynamic State:** The canvas state isn't static; brush strokes can decay over time unless refreshed.
2.  **Complex Interactions:** More than simple pixel setting; users apply "strokes" with type, intensity, color, and optional patterns.
3.  **On-Chain Patterns:** Users can define complex patterns on-chain for others to use.
4.  **Staking for Influence:** Users stake funds to gain governance rights. Voting power might decay or grow based on stake duration.
5.  **Governance over Art Parameters:** The community (stakers/NFT owner) can vote on how the canvas evolves (fees, decay rates, allowed colors/brushes).
6.  **Single Evolving NFT:** The contract manages a single ERC721 token that represents the *current state* of the entire canvas. Transferring the NFT transfers ownership of this evolving piece and associated privileges (like fee withdrawal).
7.  **Layered Brush Strokes:** Multiple strokes can exist at a single location, applied by different users or at different times, creating depth (though rendering would happen off-chain based on the ordered list of strokes).
8.  **Brush Types & Config:** Different brush types can have different costs, effects, or require configuration data interpreted off-chain.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoCanvas
 * @dev A dynamic, collaborative on-chain art piece represented by a single evolving NFT.
 * Users apply brush strokes and patterns, stake for governance, and vote on canvas parameters.
 * The canvas state decays over time, encouraging active participation.
 */
contract CryptoCanvas {

    // --- Libraries and Interfaces ---
    // (Assuming ERC721 interface import)
    // import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
    // import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; // If needed for token supply, but only 1 token
    // import "@openzeppelin/contracts/utils/math/Math.sol"; // Potentially for complex calculations (voting power)
    // import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // If using a specific staking token

    // --- State Variables ---
    // (See implementation below)

    // --- Structs ---
    // BrushStrokeData: Represents a single stroke applied to a location.
    // BrushType: Defines properties of a brush type.
    // Pattern: Defines a reusable pattern created by a user.
    // Proposal: Represents a governance proposal.
    // (See implementation below)

    // --- Events ---
    // StrokeApplied: Emitted when a new brush stroke or pattern is applied.
    // StrokeRefreshed: Emitted when a brush stroke is refreshed.
    // PatternDefined: Emitted when a user defines a new pattern.
    // StakeIncreased: Emitted when a user stakes Ether.
    // Unstaked: Emitted when a user unstakes Ether.
    // ProposalCreated: Emitted when a governance proposal is created.
    // Voted: Emitted when a user votes on a proposal.
    // ProposalExecuted: Emitted when a proposal is successfully executed.
    // FeesWithdrawn: Emitted when fees are withdrawn.
    // CanvasTransferred: Emitted when the Canvas NFT (token ID 0) is transferred.
    // (See implementation below)

    // --- Function Summary ---

    // --- ERC721 Core (for the single Canvas NFT) ---
    // 1.  tokenURI(uint256 tokenId) public view virtual override returns (string memory): Returns the metadata URI for the canvas NFT (token ID 0).
    // 2.  ownerOf(uint256 tokenId) public view virtual override returns (address): Returns the owner of the canvas NFT (token ID 0).
    // 3.  transferFrom(address from, address to, uint256 tokenId) public virtual override: Allows transfer of the canvas NFT (token ID 0).
    // 4.  safeTransferFrom(address from, address to, uint256 tokenId) public virtual override: Safely transfers the canvas NFT (token ID 0).
    // 5.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override: Safely transfers with data.
    // 6.  approve(address to, uint256 tokenId) public virtual override: Approves an address to transfer the canvas NFT.
    // 7.  setApprovalForAll(address operator, bool approved) public virtual override: Sets approval for an operator for all tokens (only token 0 applies).
    // 8.  getApproved(uint256 tokenId) public view virtual override returns (address): Gets the approved address for the canvas NFT.
    // 9.  isApprovedForAll(address owner, address operator) public view virtual override returns (bool): Checks if an operator is approved for all tokens.
    // 10. supportsInterface(bytes4 interfaceId) public view virtual override returns (bool): ERC165 support check.

    // --- Canvas Interaction Functions ---
    // 11. applyBrushStroke(uint256 x, uint256 y, uint8 brushTypeId, bytes32 color, uint8 intensity) payable public: Applies a brush stroke at (x,y). Requires payment based on brush type and location.
    // 12. applyPatternStroke(uint256 x, uint256 y, uint40 patternId, uint8 intensity) payable public: Applies a predefined pattern at (x,y). Requires payment.
    // 13. refreshStroke(uint256 x, uint256 y, uint256 strokeIndex) payable public: Refreshes an existing stroke at (x,y) by index, resetting its decay timer. Requires payment.
    // 14. getBrushStrokesAt(uint256 x, uint256 y) public view returns (BrushStrokeData[] memory): Retrieves all brush strokes at a specific canvas location (x,y), including decayed ones for visualization.
    // 15. getCanvasDimensions() public view returns (uint256 width, uint256 height): Returns the dimensions of the canvas grid.
    // 16. calculateStrokeCost(uint256 x, uint256 y, uint8 brushTypeId, bool isPattern) public view returns (uint256): Calculates the required payment for applying a stroke or pattern.

    // --- Brush & Pattern Management Functions ---
    // 17. addBrushType(string memory name, uint256 costMultiplier, bytes memory configData) onlyOwnerOrGovernance public: Adds a new brush type definition.
    // 18. getBrushType(uint8 brushTypeId) public view returns (BrushType memory): Retrieves details of a specific brush type.
    // 19. definePattern(string memory name, bytes32[] memory relativePixels) payable public returns (uint40 patternId): Allows a user to define a new reusable pattern. Requires payment.
    // 20. getPattern(uint40 patternId) public view returns (Pattern memory): Retrieves details of a specific pattern.
    // 21. getUserPatterns(address user) public view returns (uint40[] memory): Gets a list of pattern IDs defined by a specific user.

    // --- Staking & Governance Functions ---
    // 22. stake() payable public: Stakes Ether to gain voting power.
    // 23. unstake(uint256 amount) public: Unstakes Ether.
    // 24. getVotingPower(address user) public view returns (uint256): Calculates the current voting power of a user.
    // 25. createProposal(string memory description, bytes memory callData, uint256 voteDuration) public returns (uint256 proposalId): Creates a new governance proposal. Requires voting power.
    // 26. voteOnProposal(uint256 proposalId, bool support) public: Casts a vote on a proposal. Requires voting power.
    // 27. executeProposal(uint256 proposalId) public: Executes a proposal if it has passed and the voting period is over.
    // 28. getProposal(uint256 proposalId) public view returns (Proposal memory): Retrieves details of a specific proposal.

    // --- Fees & Withdrawal Functions ---
    // 29. getAccumulatedFees() public view returns (uint256): Returns the total Ether fees collected by the contract.
    // 30. withdrawFees(address recipient) onlyOwnerOrGovernance public: Withdraws accumulated fees to a specified recipient.

    // --- Canvas State & Metadata Functions ---
    // 31. getCurrentCanvasStateHash() public view returns (bytes32): Generates a hash representing the current core state parameters of the canvas (dimensions, fee rates, brush types hash, latest interaction timestamp). Useful for off-chain verification.
    // 32. generateMetadata() public view returns (string memory): Generates the dynamic JSON metadata string for the canvas NFT (token ID 0).

    // --- Internal/Helper Functions (Not exposed directly) ---
    // _getCoordinatesKey(uint256 x, uint256 y) internal pure returns (uint256): Maps 2D coordinates to a single key for storage.
    // _calculateDecayMultiplier(uint256 timestamp) internal view returns (uint8): Calculates a decay multiplier based on stroke timestamp and current decay rate.
    // _safeMint(address to, uint256 tokenId) internal: Mints the ERC721 token.
    // _safeTransfer(address from, address to, uint256 tokenId) internal: Internal transfer logic for ERC721.
    // _generateInitialBrushTypes() internal: Sets up initial brush types in the constructor.
    // _calculateVotingPower(address user) internal view returns (uint256): Internal logic for voting power calculation.
    // _canExecuteProposal(Proposal memory proposal) internal view returns (bool): Checks if a proposal can be executed.
    // _executeProposalCall(bytes memory callData) internal: Executes the payload of a successful proposal.

    // --- Modifiers ---
    // onlyOwnerOrGovernance: Requires the caller to be the canvas NFT owner OR have successfully voted on a proposal to gain temporary governance power (example implementation - could be complex).
    // hasVotingPower(uint256 requiredPower): Requires the caller to have a minimum amount of voting power.
    // (See implementation below for concrete modifier logic - might simplify for example)

    // Note: This summary lists over 30 potential functions. The final implementation will select and detail at least 20.
}
```

Here's the Solidity smart contract code implementing these concepts, ensuring at least 20 unique functions:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; // Not strictly needed for 1 token, but included for completeness example
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max etc.
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract CryptoCanvas is ERC721, IERC721Enumerable, IERC721Metadata {
    using Math for uint256;
    using Strings for uint256;

    // --- State Variables ---
    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 public constant CANVAS_TOKEN_ID = 0; // The single NFT represents the canvas

    // Mapping from coordinate key (y * width + x) to a list of brush strokes applied there
    mapping(uint256 => BrushStrokeData[]) public canvasGrid;

    // ERC721 token owner mapping (Overridden from ERC721 standard for the single token)
    address private _canvasOwner;

    // ERC721 approval mapping (Overridden)
    mapping(address => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Brush types
    struct BrushType {
        string name;
        uint256 costMultiplier; // Multiplier for the base stroke cost
        bytes configData;       // Configurable data for brush effects (interpreted off-chain)
    }
    BrushType[] public brushTypes; // brushTypeIds are indices in this array

    // Patterns
    struct Pattern {
        address creator;
        string name;
        bytes32[] relativePixels; // Array of encoded pixel changes (dx << 24 | dy << 16 | color)
                                  // color is bytes3: 0xRRGGBB padded to 32 bytes
    }
    Pattern[] public patterns; // patternIds are indices in this array
    mapping(address => uint40[]) public userPatterns; // List of patternIds for a user

    // Fees
    uint256 public baseStrokeFee = 0.001 ether;
    uint256 public refreshFee = 0.0005 ether;
    uint256 public patternDefineFee = 0.01 ether;
    uint256 public patternUseFeeMultiplier = 2; // Pattern use cost = baseStrokeFee * patternUseFeeMultiplier * numPixelsInPattern

    // Decay
    uint256 public decayRateMillisPerDay = 50000; // How many milliseconds it takes for intensity to halve (example rate)
                                                 // Intensity 255->0 takes ~ 8 * decayRate (log2(255))
    uint8 public constant MAX_INTENSITY = 255;

    // Staking (using Ether)
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeStartTime; // Timestamp when stake was first or last increased
    uint256 public totalStaked;

    // Governance
    struct Proposal {
        uint256 id;
        string description;
        bytes callData; // The function call to execute if the proposal passes
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) voted; // Whether an address has already voted
        bool executed;
    }
    Proposal[] public proposals;
    uint256 public nextProposalId = 0;
    uint256 public proposalVoteDuration = 3 days; // Duration for voting
    uint256 public minVotingPowerToCreateProposal = 1 ether; // Minimum staked amount required to propose

    // Accumulated fees from interactions
    uint256 private _accumulatedFees;

    // Metadata Base URI
    string public baseTokenURI;

    // --- Structs ---
    struct BrushStrokeData {
        address user;
        uint40 timestamp; // Timestamp of application or refresh
        uint8 brushTypeId;
        bytes32 color; // Packed color + maybe other flags
        uint8 intensity; // 0-255
        uint40 patternId; // 0 if not from a pattern
        uint16 patternStrokeIndex; // Index within the applied pattern (for identification)
    }

    // --- Events ---
    event StrokeApplied(uint256 indexed x, uint256 indexed y, address indexed user, uint8 brushTypeId, uint40 patternId, uint256 cost);
    event StrokeRefreshed(uint256 indexed x, uint256 indexed y, uint256 indexed strokeIndex, address user, uint256 cost);
    event PatternDefined(uint40 indexed patternId, address indexed creator, string name, uint256 cost);
    event StakeIncreased(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event CanvasTransferred(address indexed from, address indexed to); // For the single token ID 0

    // --- Modifiers ---
    modifier onlyCanvasOwner() {
        require(msg.sender == _canvasOwner, "CryptoCanvas: Not canvas owner");
        _;
    }

    // This modifier is complex. Let's simplify for the example.
    // In a real governance system, this would check if the caller has voting power
    // and the proposal to grant them executive power passed and is active.
    // For this example, we'll make it simpler: only the canvas owner OR successful proposal execution grants this.
    // A real implementation would need careful state management of who has temporary governance power.
    // Let's stick to onlyCanvasOwner for simplicity in this example, but the concept is there.
    // modifier onlyOwnerOrGovernance() { ... }

    modifier hasVotingPower(uint256 requiredPower) {
        require(_calculateVotingPower(msg.sender) >= requiredPower, "CryptoCanvas: Insufficient voting power");
        _;
    }

    // --- Constructor ---
    constructor(uint256 width, uint256 height, string memory name, string memory symbol, string memory _baseTokenURI)
        ERC721(name, symbol) // Initialize ERC721 with canvas name and symbol
    {
        require(width > 0 && height > 0, "CryptoCanvas: Invalid dimensions");
        canvasWidth = width;
        canvasHeight = height;
        baseTokenURI = _baseTokenURI;

        // Mint the single canvas NFT to the contract deployer
        _canvasOwner = msg.sender;
        _safeMint(msg.sender, CANVAS_TOKEN_ID);

        // Initialize some default brush types
        _generateInitialBrushTypes();
    }

    // --- ERC721 Core Implementations (for the single token) ---
    // ERC721 token id 0 represents the entire canvas
    // We override standard functions to manage the single token within the contract

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
        // Base URI + token ID is standard, but we can make it dynamic
        // pointing to a service that renders the current state and provides metadata
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), "/", getCurrentCanvasStateHash().toHexString()));
        // The hash allows off-chain renderers/metadata services to verify the state they are displaying matches the hash
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
        return _canvasOwner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
        _safeTransfer(from, to, tokenId); // Internal logic handles state update
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner or approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
        _safeTransfer(from, to, tokenId); // Internal logic handles state update
        require(
            // Check receiver is smart contract and accepts ERC721
            (to.code.length == 0) ||
            ERC721(address(this)).onERC721Received(msg.sender, from, tokenId, data) == IERC721Receiver.onERC721Received.selector,
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    function approve(address to, uint256 tokenId) public override {
         require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
         address owner = ownerOf(tokenId);
         require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
         _tokenApprovals[tokenId] = to;
         emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Only token 0 exists");
        return _tokenApprovals[tokenId];
    }

     function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // ERC165 Support (required by ERC721)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId || // Even for 1 token, helps tools
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Required by IERC721Enumerable
    function totalSupply() public view override returns (uint256) { return 1; }
    function tokenByIndex(uint256 index) public view override returns (uint256) { require(index == 0, "CryptoCanvas: Invalid index"); return CANVAS_TOKEN_ID; }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) { require(index == 0 && ownerOf(CANVAS_TOKEN_ID) == owner, "CryptoCanvas: Invalid index or owner"); return CANVAS_TOKEN_ID; }


    // --- Internal ERC721 Overrides ---
     function _exists(uint256 tokenId) internal view override returns (bool) {
        return tokenId == CANVAS_TOKEN_ID; // Only token 0 exists
    }

     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
         address owner = ownerOf(tokenId);
         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
     }

    function _safeMint(address to, uint256 tokenId) internal override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Can only mint token 0");

        _canvasOwner = to; // Set the internal owner state variable
        // No _balances or _ownedTokens mapping to update for a single token contract

        emit Transfer(address(0), to, tokenId);
    }

     function _safeTransfer(address from, address to, uint256 tokenId) internal override {
        require(to != address(0), "ERC721: transfer to the zero address");
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(tokenId == CANVAS_TOKEN_ID, "CryptoCanvas: Can only transfer token 0");

        // Clear approvals for the token
        _approve(address(0), tokenId);

        _canvasOwner = to; // Update the internal owner state variable

        emit Transfer(from, to, tokenId);
        emit CanvasTransferred(from, to); // Custom event for clarity
     }

     // Helper to override _approve and clear approvals
    function _approve(address to, uint256 tokenId) internal override {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }


    // --- Canvas Interaction Functions ---
    function applyBrushStroke(uint256 x, uint256 y, uint8 brushTypeId, bytes32 color, uint8 intensity) payable public {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");
        require(brushTypeId < brushTypes.length, "CryptoCanvas: Invalid brush type ID");
        require(intensity <= MAX_INTENSITY, "CryptoCanvas: Invalid intensity");

        uint256 cost = calculateStrokeCost(x, y, brushTypeId, false);
        require(msg.value >= cost, "CryptoCanvas: Insufficient payment");

        BrushStrokeData memory newStroke = BrushStrokeData({
            user: msg.sender,
            timestamp: uint40(block.timestamp),
            brushTypeId: brushTypeId,
            color: color,
            intensity: intensity,
            patternId: 0, // Not from a pattern
            patternStrokeIndex: 0 // Not applicable
        });

        uint256 key = _getCoordinatesKey(x, y);
        canvasGrid[key].push(newStroke);

        _accumulatedFees += msg.value;

        emit StrokeApplied(x, y, msg.sender, brushTypeId, 0, msg.value);
    }

    function applyPatternStroke(uint256 x, uint256 y, uint40 patternId, uint8 intensity) payable public {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");
        require(patternId < patterns.length, "CryptoCanvas: Invalid pattern ID");
        require(intensity <= MAX_INTENSITY, "CryptoCanvas: Invalid intensity");

        Pattern storage pattern = patterns[patternId];
        uint256 cost = calculateStrokeCost(x, y, 0, true); // Cost calculation includes pattern logic
        require(msg.value >= cost, "CryptoCanvas: Insufficient payment");

        uint256 numPixels = pattern.relativePixels.length;
        // To avoid hitting block gas limit for very large patterns, we might need limits
        // or batching mechanisms in a real implementation. Let's assume a reasonable pattern size limit here.

        for (uint i = 0; i < numPixels; i++) {
             bytes32 pixelData = pattern.relativePixels[i];
             // Decode pixelData: (dx << 24 | dy << 16 | color)
             int16 dx = int16(int32(pixelData << 8) >> 16); // Extract signed dx (16 bits)
             int16 dy = int16(int32(pixelData << 16) >> 16); // Extract signed dy (16 bits)
             bytes32 pixelColor = (pixelData << 24); // Extract color (last 3 bytes)

             int256 targetX = int256(x) + dx;
             int256 targetY = int256(y) + dy;

             require(targetX >= 0 && targetX < int256(canvasWidth) && targetY >= 0 && targetY < int256(canvasHeight), "CryptoCanvas: Pattern stroke out of bounds");

             BrushStrokeData memory newStroke = BrushStrokeData({
                user: msg.sender,
                timestamp: uint40(block.timestamp),
                brushTypeId: 0, // Pattern strokes use brush type 0 (default)
                color: pixelColor,
                intensity: intensity,
                patternId: patternId,
                patternStrokeIndex: uint16(i) // Index within this pattern application
             });

             uint256 key = _getCoordinatesKey(uint256(targetX), uint256(targetY));
             canvasGrid[key].push(newStroke);
        }

        _accumulatedFees += msg.value;
        // A small royalty could be sent to the pattern creator here

        emit StrokeApplied(x, y, msg.sender, 0, patternId, msg.value);
    }

    function refreshStroke(uint256 x, uint256 y, uint256 strokeIndex) payable public {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");
        uint256 key = _getCoordinatesKey(x, y);
        require(strokeIndex < canvasGrid[key].length, "CryptoCanvas: Invalid stroke index");

        BrushStrokeData storage stroke = canvasGrid[key][strokeIndex];
        require(msg.value >= refreshFee, "CryptoCanvas: Insufficient payment for refresh");

        stroke.timestamp = uint40(block.timestamp); // Reset decay timer
        // Optional: Increase intensity slightly, up to MAX_INTENSITY
        // stroke.intensity = Math.min(stroke.intensity + 10, MAX_INTENSITY); // Example

        _accumulatedFees += msg.value;

        emit StrokeRefreshed(x, y, strokeIndex, msg.sender, msg.value);
    }

    function getBrushStrokesAt(uint256 x, uint256 y) public view returns (BrushStrokeData[] memory) {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");
        uint256 key = _getCoordinatesKey(x, y);
        BrushStrokeData[] memory strokes = new BrushStrokeData[](canvasGrid[key].length);
        uint256 validCount = 0;
        uint256 currentTime = block.timestamp;

        // Return all strokes, including decayed ones, for off-chain rendering logic
        // Off-chain renderer will apply decay based on the timestamp
        for(uint i = 0; i < canvasGrid[key].length; i++) {
             strokes[validCount] = canvasGrid[key][i];
             validCount++; // All strokes are returned, renderer handles decay
        }

        // If we only wanted non-decayed strokes:
        // for(uint i = 0; i < canvasGrid[key].length; i++) {
        //      if (_calculateDecayMultiplier(canvasGrid[key][i].timestamp) < 255) { // If intensity hasn't decayed to 0
        //           strokes[validCount] = canvasGrid[key][i];
        //           validCount++;
        //      }
        // }
        // // Resize array if needed
        // BrushStrokeData[] memory activeStrokes = new BrushStrokeData[](validCount);
        // for(uint i = 0; i < validCount; i++) {
        //     activeStrokes[i] = strokes[i];
        // }
        // return activeStrokes;

        return strokes; // Returning all strokes; off-chain renderer handles decay logic
    }


    function getCanvasDimensions() public view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    function calculateStrokeCost(uint256 x, uint256 y, uint8 brushTypeId, bool isPattern) public view returns (uint256) {
        require(x < canvasWidth && y < canvasHeight, "CryptoCanvas: Coordinates out of bounds");

        uint256 baseCost = baseStrokeFee;
        if (isPattern) {
            // Pattern cost is based on the complexity (number of pixels) and multiplier
            uint40 patternId = uint40(brushTypeId); // Misused brushTypeId to pass patternId
            require(patternId < patterns.length, "CryptoCanvas: Invalid pattern ID for cost calculation");
            baseCost = baseStrokeFee * patternUseFeeMultiplier * patterns[patternId].relativePixels.length;
        } else {
             require(brushTypeId < brushTypes.length, "CryptoCanvas: Invalid brush type ID for cost calculation");
             baseCost = baseStrokeFee * brushTypes[brushTypeId].costMultiplier;
        }

        // Future: Add logic based on location (more expensive in center?), recent activity, etc.
        return baseCost;
    }

    // --- Brush & Pattern Management Functions ---
    function addBrushType(string memory name, uint256 costMultiplier, bytes memory configData) onlyCanvasOwner public {
        // In a real system, this would be via governance
        brushTypes.push(BrushType(name, costMultiplier, configData));
        // Consider emitting an event
    }

    function getBrushType(uint8 brushTypeId) public view returns (BrushType memory) {
        require(brushTypeId < brushTypes.length, "CryptoCanvas: Invalid brush type ID");
        return brushTypes[brushTypeId];
    }

    function definePattern(string memory name, bytes32[] memory relativePixels) payable public returns (uint40 patternId) {
        // relativePixels format: (dx << 24 | dy << 16 | color). color is bytes3: 0xRRGGBB
        // dx, dy are int16 offsets from the pattern origin point
        // Example: bytes32(int16(1) << 24 | int16(0) << 16 | 0xFF000000) // Red pixel at (1, 0) relative

        require(relativePixels.length > 0, "CryptoCanvas: Pattern cannot be empty");
        // Add limits on pattern size to avoid excessive cost
        require(relativePixels.length <= 64, "CryptoCanvas: Pattern size limit exceeded (max 64 pixels)");

        require(msg.value >= patternDefineFee, "CryptoCanvas: Insufficient payment to define pattern");

        patterns.push(Pattern(msg.sender, name, relativePixels));
        uint40 newPatternId = uint40(patterns.length - 1);
        userPatterns[msg.sender].push(newPatternId);

        _accumulatedFees += msg.value;

        emit PatternDefined(newPatternId, msg.sender, name, msg.value);
        return newPatternId;
    }

    function getPattern(uint40 patternId) public view returns (Pattern memory) {
        require(patternId < patterns.length, "CryptoCanvas: Invalid pattern ID");
        return patterns[patternId];
    }

    function getUserPatterns(address user) public view returns (uint40[] memory) {
        return userPatterns[user];
    }

    // --- Staking & Governance Functions ---
    function stake() payable public {
        require(msg.value > 0, "CryptoCanvas: Stake amount must be greater than 0");
        uint256 currentStake = stakedBalance[msg.sender];
        uint256 currentTotalStake = totalStaked;

        stakedBalance[msg.sender] += msg.value;
        totalStaked += msg.value;

        // Update start time if this is the first stake or significantly increases stake (simplification)
        // More complex systems track average stake duration
        if (currentStake == 0) {
            stakeStartTime[msg.sender] = block.timestamp;
        } // else: Could add logic to average/weighted average timestamp

        emit StakeIncreased(msg.sender, msg.value, totalStaked);
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "CryptoCanvas: Unstake amount must be greater than 0");
        require(stakedBalance[msg.sender] >= amount, "CryptoCanvas: Insufficient staked balance");
        require(totalStaked >= amount, "CryptoCanvas: Total staked amount insufficient");

        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        // Consider resetting stakeStartTime if balance becomes 0

        // Send Ether back
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "CryptoCanvas: Failed to send Ether");

        emit Unstaked(msg.sender, amount, totalStaked);
    }

    function getVotingPower(address user) public view returns (uint256) {
        return _calculateVotingPower(user);
    }

    function createProposal(string memory description, bytes memory callData, uint256 voteDuration) public hasVotingPower(minVotingPowerToCreateProposal) returns (uint256 proposalId) {
        require(voteDuration > 0, "CryptoCanvas: Vote duration must be greater than 0");

        proposalId = nextProposalId++;
        proposals.push(Proposal({
            id: proposalId,
            description: description,
            callData: callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + voteDuration,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            voted: new mapping(address => bool), // Initialize nested mapping
            executed: false
        }));

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].voteEndTime);
        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) public {
        require(proposalId < proposals.length, "CryptoCanvas: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "CryptoCanvas: Proposal already executed");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "CryptoCanvas: Voting period not active");
        require(!proposal.voted[msg.sender], "CryptoCanvas: Already voted on this proposal");

        uint256 power = _calculateVotingPower(msg.sender);
        require(power > 0, "CryptoCanvas: No voting power");

        proposal.voted[msg.sender] = true;
        if (support) {
            proposal.totalVotesFor += power;
        } else {
            proposal.totalVotesAgainst += power;
        }

        emit Voted(proposalId, msg.sender, support, power);
    }

    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposals.length, "CryptoCanvas: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "CryptoCanvas: Proposal already executed");
        require(block.timestamp >= proposal.voteEndTime, "CryptoCanvas: Voting period not over");
        require(_canExecuteProposal(proposal), "CryptoCanvas: Proposal did not pass");

        proposal.executed = true;
        _executeProposalCall(proposal.callData);

        emit ProposalExecuted(proposalId);
    }

    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
         require(proposalId < proposals.length, "CryptoCanvas: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         // Return struct members individually or define a return struct without the nested mapping
         return Proposal({
             id: proposal.id,
             description: proposal.description,
             callData: proposal.callData, // Note: callData can be large
             voteStartTime: proposal.voteStartTime,
             voteEndTime: proposal.voteEndTime,
             totalVotesFor: proposal.totalVotesFor,
             totalVotesAgainst: proposal.totalVotesAgainst,
             voted: new mapping(address => bool), // Cannot return mappings from external calls directly, return empty/default
             executed: proposal.executed
         });
    }

    // --- Fees & Withdrawal Functions ---
    function getAccumulatedFees() public view returns (uint256) {
        return _accumulatedFees;
    }

    function withdrawFees(address recipient) onlyCanvasOwner public {
         // In a real system, this should be a governance action or proportional to ownership/stake
         // For simplicity, only the canvas owner can withdraw all fees
         require(recipient != address(0), "CryptoCanvas: Invalid recipient");
         uint256 amount = _accumulatedFees;
         require(amount > 0, "CryptoCanvas: No fees to withdraw");

         _accumulatedFees = 0; // Reset before sending

         (bool success, ) = payable(recipient).call{value: amount}("");
         require(success, "CryptoCanvas: Fee withdrawal failed");

         emit FeesWithdrawn(recipient, amount);
    }

    // Example Governance Function: Setting Fees (would be called via executeProposal)
    function setFeeRates(uint256 _baseStrokeFee, uint256 _refreshFee, uint256 _patternDefineFee, uint256 _patternUseFeeMultiplier) public onlyCanvasOwner {
        // Again, this would be governance in a real system
        baseStrokeFee = _baseStrokeFee;
        refreshFee = _refreshFee;
        patternDefineFee = _patternDefineFee;
        patternUseFeeMultiplier = _patternUseFeeMultiplier;
        // Consider emitting an event
    }

    // Example Governance Function: Setting Decay Rate
     function setDecayRate(uint256 _decayRateMillisPerDay) public onlyCanvasOwner {
        decayRateMillisPerDay = _decayRateMillisPerDay;
        // Consider emitting an event
    }

    // Example Governance Function: Setting Metadata Base URI
     function setBaseTokenURI(string memory _baseTokenURI) public onlyCanvasOwner {
        baseTokenURI = _baseTokenURI;
        // Consider emitting an event
    }


    // --- Canvas State & Metadata Functions ---
    function getCurrentCanvasStateHash() public view returns (bytes32) {
        // This hash needs to summarize the state relevant for rendering/verification.
        // Hashing the entire grid is too expensive. Hash core parameters and activity indicators.
        // Example: hash dimensions, fees, brush types hash, patterns count, total strokes count, last interaction timestamp.
        bytes32 brushTypesHash = keccak256(abi.encodePacked(brushTypes)); // Hash of brush types data
        uint256 totalStrokes = 0;
        // This loop could be expensive if canvasGrid is large/sparse
        // for(uint i = 0; i < canvasWidth * canvasHeight; i++) {
        //    totalStrokes += canvasGrid[i].length;
        // }
        // Better to track total strokes in a state variable if needed for hash

        // Simplification: Hash core parameters and the latest block timestamp
        return keccak256(abi.encodePacked(
            canvasWidth,
            canvasHeight,
            baseStrokeFee,
            refreshFee,
            patternDefineFee,
            patternUseFeeMultiplier,
            decayRateMillisPerDay,
            brushTypesHash,
            patterns.length,
            nextProposalId,
            block.timestamp // Include a changing element to reflect state updates
        ));
    }


    function generateMetadata() public view returns (string memory) {
        // This generates the dynamic JSON metadata for the single NFT.
        // In a real dApp, this would likely point to an off-chain service URL
        // that fetches on-chain data (via getBrushStrokesAt etc.) and renders/formats the JSON.
        // Generating complex JSON on-chain is very gas-intensive.
        // This implementation provides a minimal example, likely pointing to the off-chain renderer.

        string memory name = string(abi.encodePacked("CryptoCanvas (", this.name(), ")"));
        string memory description = "The dynamic, collaborative on-chain art piece. Its state evolves with user interaction and decays over time.";
        // The image URL should point to a service that renders the canvas based on the current state
        string memory imageUrl = string(abi.encodePacked(
             baseTokenURI,
             CANVAS_TOKEN_ID.toString(),
             "/render?hash=",
             getCurrentCanvasStateHash().toHexString() // Pass the state hash for verification/caching
        ));

        // Add some attributes reflecting the canvas state
        string memory attributes = string(abi.encodePacked(
            "[",
            '{"trait_type": "Width", "value": "', canvasWidth.toString(), '"},',
            '{"trait_type": "Height", "value": "', canvasHeight.toString(), '"},',
            '{"trait_type": "Total Strokes", "value": "Dynamic (Query getBrushStrokesAt)"},', // Placeholder, expensive to count on-chain
            '{"trait_type": "Defined Patterns", "value": "', patterns.length.toString(), '"},',
            '{"trait_type": "Active Brush Types", "value": "', brushTypes.length.toString(), '"},',
             '{"trait_type": "Current State Hash", "value": "0x', getCurrentCanvasStateHash().toHexString(), '"}',
            "]"
        ));


        string memory json = string(abi.encodePacked(
            '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', imageUrl, '",',
                '"attributes": ', attributes,
            '}'
        ));

        // Encode the JSON to Base64 data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }


    // --- Internal/Helper Functions ---
    function _getCoordinatesKey(uint256 x, uint256 y) internal view returns (uint256) {
        return y * canvasWidth + x;
    }

    function _calculateDecayMultiplier(uint256 timestamp) internal view returns (uint8) {
        if (timestamp == 0) return MAX_INTENSITY; // Should not happen for valid strokes
        uint256 timeElapsed = block.timestamp - timestamp;
        if (decayRateMillisPerDay == 0 || timeElapsed == 0) return MAX_INTENSITY;

        // Simple linear decay example: Intensity reduces by 1 per `decayRateMillisPerDay` / 255
        // More advanced: exponential decay
        // intensity = initial_intensity * 0.5 ^ (time_elapsed / half_life_period)
        // Here, half_life_period is decayRateMillisPerDay.
        // log2(intensity/initial_intensity) = -(time_elapsed / decayRateMillisPerDay)
        // We want the multiplier (0 to 255)
        // Multiplier = 255 * 0.5 ^ (time_elapsed / decayRateMillisPerDay)
        // Using shifting for approximate power of 0.5
        // This is complex and potentially gas-heavy on chain. Let's use a simpler linear approximation or require off-chain calculation.
        // Simpler: time_elapsed / decay_unit -> 1 unit decay. Total decay steps = 255. Decay unit = decayRateMillisPerDay / 255
        uint256 decayUnit = decayRateMillisPerDay / MAX_INTENSITY;
        if (decayUnit == 0) return MAX_INTENSITY; // Avoid division by zero

        uint256 decaySteps = timeElapsed / decayUnit;
        if (decaySteps >= MAX_INTENSITY) return 0; // Fully decayed

        return uint8(MAX_INTENSITY - decaySteps); // Linear decay example
    }

    function _calculateVotingPower(address user) internal view returns (uint256) {
        uint256 staked = stakedBalance[user];
        if (staked == 0) return 0;

        uint256 timeStaked = block.timestamp - stakeStartTime[user];
        // Example power calculation: staked amount + (staked amount * time_staked / a_constant)
        // This encourages longer staking. Let's use a simple linear bonus based on time.
        uint256 timeBonus = staked * timeStaked / (365 days); // 100% bonus if staked for a year (example)
        return staked + timeBonus;
    }

     function _canExecuteProposal(Proposal memory proposal) internal view returns (bool) {
        // Simple majority rule based on voting power
        return proposal.totalVotesFor > proposal.totalVotesAgainst;
        // Could add: minimum participation threshold, quorum, etc.
    }

    // --- Governance Proposal Execution ---
    // This function is critical and must be called ONLY from executeProposal.
    // It allows the contract to call arbitrary functions on itself or other contracts
    // as voted on by the community. Requires careful security review in a real scenario.
    function _executeProposalCall(bytes memory callData) internal {
        // The callData should be abi encoded data for a function call
        // e.g., abi.encodeWithSelector(this.setFeeRates.selector, newBaseFee, newRefreshFee, ...)
        (bool success, ) = address(this).call(callData);
        require(success, "CryptoCanvas: Proposal execution failed");
        // Potentially add re-entrancy guards if calling external contracts
    }


    // --- Initial Setup ---
    function _generateInitialBrushTypes() internal {
        // Default brush (cost multiplier 1, empty config)
        brushTypes.push(BrushType("Default", 1, ""));
        // Add more initial brush types here if desired
        // brushTypes.push(BrushType("Large", 2, ""));
        // brushTypes.push(BrushType("Spray", 1.5, ""));
    }

    // Fallback to receive Ether for staking or direct payment (though specific functions are better)
    receive() external payable {
        // Could allow direct Ether contributions here, e.g., as a general donation
        // or direct staking without calling the stake() function explicitly.
        // Let's require stake() to ensure stakeStartTime is tracked.
        revert("CryptoCanvas: Please call specific functions (stake or applyBrushStroke) to send Ether");
    }

    fallback() external payable {
        revert("CryptoCanvas: Call to non-existent function or unauthorized Ether reception");
    }
}
```

**Explanation of Advanced/Creative Elements in the Code:**

1.  **Dynamic State (Decay):** The `BrushStrokeData` struct includes a `timestamp`. The `_calculateDecayMultiplier` function (and the `getBrushStrokesAt` function's design to return *all* strokes) allows an off-chain renderer to apply a visual decay effect based on how much time has passed since the stroke was applied or refreshed. The `refreshStroke` function lets users pay to reset this timer.
2.  **Complex Interactions (Brush Strokes & Patterns):** `applyBrushStroke` takes brush type, color, and intensity. `applyPatternStroke` uses a `patternId` referencing on-chain pattern data (`relativePixels`). This moves beyond simple 1-in-1 pixel mapping.
3.  **On-Chain Patterns:** The `Pattern` struct and the `definePattern`, `getPattern`, `getUserPatterns` functions allow users to create and query reusable patterns. The `relativePixels` array stores the pattern's structure directly on-chain.
4.  **Staking for Influence:** `stake`, `unstake`, `stakedBalance`, `stakeStartTime`, and `getVotingPower` implement a basic staking mechanism using Ether. Voting power is calculated based on the staked amount and the duration of the stake (`_calculateVotingPower`).
5.  **Governance over Art Parameters:** The `Proposal` struct and functions (`createProposal`, `voteOnProposal`, `executeProposal`, `getProposal`) create a simple governance system. Users with sufficient voting power (`hasVotingPower` modifier) can create proposals whose `callData` represents a function call to be executed if the proposal passes (`_executeProposalCall`). Example functions like `setFeeRates` and `setDecayRate` are included, designed to be called via governance.
6.  **Single Evolving NFT:** The contract *is* the art. It inherits from `ERC721` but manages only `CANVAS_TOKEN_ID = 0`. All standard ERC721 functions are overridden to interact with this single, contract-managed token. Transferring this NFT transfers ownership of the entire project.
7.  **Layered Brush Strokes:** The `canvasGrid` mapping stores an *array* of `BrushStrokeData` for each location (`BrushStrokeData[] public canvasGrid`). This means multiple strokes can overlap at the same pixel, creating depth or history, which an off-chain renderer can interpret (e.g., drawing them in the order they appear in the array).
8.  **Brush Types & Config:** The `BrushType` struct allows defining different types of brushes with varying `costMultiplier` and arbitrary `configData`. This `configData` is interpreted off-chain by rendering clients, allowing for flexible brush behaviors without complex on-chain rendering logic.
9.  **On-Chain State Hashing & Dynamic Metadata:** `getCurrentCanvasStateHash` provides a verifiable summary of the canvas state parameters. `generateMetadata` creates a dynamic metadata URI that points to an off-chain renderer, passing the state hash. This ensures the metadata and the displayed image accurately reflect the on-chain state and its evolution.

This contract is significantly more complex than a standard token or simple art NFT, incorporating elements from DeFi (staking), governance, dynamic state, and complex on-chain data structures (patterns, layered strokes) tied to a single evolving NFT. It meets the requirements for being interesting, advanced, creative, trendy (NFTs, governance, dynamic art), and having over 20 functions, while not being a direct copy of common open-source implementations.

Remember that deploying and interacting with such a complex contract can be gas-intensive. Storing large patterns or having locations with many strokes will consume significant gas. Real-world implementations might involve off-chain storage solutions (like IPFS) referenced by the contract for large data, or further state optimization techniques. The governance execution (`_executeProposalCall`) is a powerful pattern but requires rigorous testing and security review.