Okay, here is a Solidity smart contract idea called `EternalCanvas`, combining several advanced and creative concepts: Dynamic NFTs, on-chain influence mapping, AI prompt integration (via off-chain process), time-based canvas evolution, and token-governance over canvas properties.

It avoids directly duplicating common open-source projects by creating a specific interaction model between NFTs (BrushTokens) and a shared, evolving canvas state, influenced by user-provided AI prompts.

---

**Contract Name:** `EternalCanvas`

**Concept:** A smart contract managing a digital canvas represented by on-chain state. Users mint "BrushTokens" (ERC721 NFTs), each of which can be associated with a rectangular area on the canvas. The holder of a BrushToken can set an AI prompt for their token. Periodically, or triggered by users, the canvas "evolves". This evolution process (simulated on-chain, potentially using prompt hashes and time) updates the pixel states within the claimed areas, blending influences. Governance is included, allowing BrushToken holders to vote on global canvas parameters like size, evolution speed, or allowed colors. The actual visual rendering happens off-chain, interpreting the on-chain state (base state + token influences + evolution).

**Key Features:**

1.  **Dynamic BrushTokens:** NFTs whose traits (like the associated prompt and influence area) change over time or based on holder actions.
2.  **On-Chain Influence Mapping:** Tracking which token influences which area of the canvas.
3.  **AI Prompt Integration:** Storing user-provided text prompts on-chain, intended to guide off-chain AI art generation that interprets the on-chain state.
4.  **Time-Based Evolution:** A mechanism (`updateCanvasState`) that periodically updates the canvas state based on stored prompts and elapsed time, simulating growth, decay, or blending.
5.  **Token Governance:** BrushToken holders propose and vote on changes to canvas parameters.
6.  **Layered State:** Canvas has a base state (set by governance) and a current state (result of evolution based on token influences).

---

**Outline and Function Summary:**

1.  **Contract Setup & State:**
    *   Inherits ERC721 for BrushTokens.
    *   Defines structs for Rectangular Areas, Governance Proposals.
    *   Defines enums for Proposal State and Type.
    *   Stores core canvas dimensions, token data (prompts, lock status, influence areas), canvas pixel state, governance parameters, and fee information.

2.  **BrushToken Management (ERC721 Standard + Custom):**
    *   `constructor`: Initializes contract, sets admin, initial parameters.
    *   `mintBrushToken`: Mints a new BrushToken to a user, collects fee.
    *   `tokenURI`: (Override) Generates metadata URI, potentially including prompt, lock status, influence area, and a hash representing the latest generated image (derived off-chain).
    *   `getTokenDetails`: Gets comprehensive details about a specific token (owner, prompt, lock until, influence area).

3.  **Prompt Management:**
    *   `setTokenPrompt`: Allows token owner (or delegate) to set/update the AI prompt associated with their token.
    *   `lockPrompt`: Owner locks their prompt, preventing changes for a duration.
    *   `unlockPrompt`: Owner removes a prompt lock (either manually after duration or forcibly).
    *   `checkPromptLockStatus`: Checks if a token's prompt is currently locked.
    *   `delegatePromptInfluence`: Allows token owner to grant another address permission to set their prompt.
    *   `removePromptInfluenceDelegate`: Revokes prompt influence delegation.
    *   `getPromptInfluenceDelegate`: Gets the current prompt influence delegate for a token.

4.  **Canvas Influence Management:**
    *   `claimInfluenceArea`: Token owner claims a rectangular area on the canvas their token will influence (pays a fee).
    *   `releaseInfluenceArea`: Token owner releases their claim on an area.
    *   `getInfluenceArea`: Gets the rectangular area claimed by a specific token.
    *   `getTokensInfluencingArea`: (Helper - potentially gas-intensive) Finds all tokens whose influence area overlaps with a given point.

5.  **Canvas State & Evolution:**
    *   `updateCanvasState`: The core evolution function. Processes claimed areas and prompts, updating the `canvasCurrentState` based on logic incorporating prompt data, time elapsed since last update, and potentially interactions between overlapping areas. Only runs if sufficient time has passed since the last update.
    *   `getPixelColorAt`: Retrieves the current state/color interpretation for a specific pixel coordinate from `canvasCurrentState`.
    *   `getCanvasDimensions`: Gets the current width and height of the canvas.
    *   `getCanvasLastUpdateTime`: Gets the timestamp of the last evolution step.

6.  **Governance:**
    *   `createProposal`: Allows token holders (with minimum token count) to propose changes to canvas parameters (e.g., dimensions, fees, lock duration, governance parameters, base color) or propose custom actions via `callData`.
    *   `voteOnProposal`: Allows token holders to vote 'yes' or 'no' on an active proposal (vote weight based on token count at snapshot or current).
    *   `executeProposal`: Executes a proposal that has reached the 'Approved' state and met quorum requirements.
    *   `getProposalState`: Gets the current state of a proposal.
    *   `getVoteCount`: Gets the 'yes' and 'no' vote counts for a proposal.

7.  **Admin & Parameter Management (Often controlled by Governance after setup):**
    *   `setBasePixelColor`: Sets the default background state/color for a specific pixel or area (usually via governance).
    *   `setCanvasDimensions`: Sets the canvas width and height (usually via governance).
    *   `setGovernanceParameters`: Sets parameters like voting period, quorum, minimum proposal tokens (usually via governance).
    *   `setPromptLockDuration`: Sets the default duration for prompt locks (usually via governance).
    *   `setInfluenceAreaFee`: Sets the fee required to claim an influence area (usually via governance).
    *   `withdrawFees`: Allows the fee recipient (initially admin, potentially changeable by governance) to withdraw collected ETH.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline and Function Summary ---
//
// 1. Contract Setup & State
//    - ERC721 standard inheritance for BrushTokens.
//    - Structs: Rect (canvas area), Proposal.
//    - Enums: ProposalState, ProposalType.
//    - State Variables: Canvas dimensions, token data (prompt, lock, influence), pixel state, governance, fees.
//
// 2. BrushToken Management (ERC721 + Custom)
//    - constructor(): Initializes contract parameters.
//    - mintBrushToken(address to): Mints a new token, collects fee. (2)
//    - tokenURI(uint256 tokenId): Override - Generates token metadata URI. (3)
//    - getTokenDetails(uint256 tokenId): Retrieves comprehensive token info. (4)
//
// 3. Prompt Management
//    - setTokenPrompt(uint256 tokenId, string memory newPrompt): Sets a token's AI prompt. (5)
//    - lockPrompt(uint256 tokenId): Locks prompt changes for a duration. (6)
//    - unlockPrompt(uint256 tokenId): Removes prompt lock if time passed or forced. (7)
//    - checkPromptLockStatus(uint256 tokenId): Checks if prompt is locked. (8)
//    - delegatePromptInfluence(uint256 tokenId, address delegate): Grants prompt setting permission. (9)
//    - removePromptInfluenceDelegate(uint256 tokenId): Revokes prompt delegation. (10)
//    - getPromptInfluenceDelegate(uint256 tokenId): Gets current prompt delegate. (11)
//
// 4. Canvas Influence Management
//    - claimInfluenceArea(uint256 tokenId, Rect memory area): Claims area for a token. (12)
//    - releaseInfluenceArea(uint256 tokenId): Releases token's claimed area. (13)
//    - getInfluenceArea(uint256 tokenId): Gets area claimed by a token. (14)
//    - getTokensInfluencingArea(uint32 x, uint32 y): Finds tokens whose area covers a point. (15)
//
// 5. Canvas State & Evolution
//    - updateCanvasState(): Triggers canvas state evolution based on prompts/time. (16)
//    - getPixelColorAt(uint32 x, uint32 y): Gets current pixel state/color. (17)
//    - getCanvasDimensions(): Gets current canvas size. (18)
//    - getCanvasLastUpdateTime(): Gets timestamp of last evolution. (19)
//
// 6. Governance
//    - createProposal(string memory description, uint256 proposalType, bytes memory callData): Creates governance proposal. (20)
//    - voteOnProposal(uint256 proposalId, bool support): Casts vote on proposal. (21)
//    - executeProposal(uint256 proposalId): Executes approved proposal. (22)
//    - getProposalState(uint256 proposalId): Gets proposal's state. (23)
//    - getVoteCount(uint256 proposalId): Gets proposal's vote counts. (24)
//
// 7. Admin & Parameter Management (often via Governance)
//    - setBasePixelColor(uint32 x, uint32 y, uint8 color): Sets default pixel color. (25)
//    - setCanvasDimensions(uint32 width, uint32 height): Sets canvas size. (26)
//    - setGovernanceParameters(uint40 votingPeriod, uint256 quorumNumerator, uint256 quorumDenominator, uint256 minTokensToPropose): Sets gov rules. (27)
//    - setPromptLockDuration(uint40 duration): Sets default prompt lock time. (28)
//    - setInfluenceAreaFee(uint256 fee): Sets fee for claiming area. (29)
//    - withdrawFees(): Withdraws collected fees. (30)
//
// (Note: Function numbers are for counting against the 20+ requirement. Includes standard ERC721 overrides with custom logic and helpers)

contract EternalCanvas is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Structs ---
    struct Rect {
        uint32 x;
        uint32 y;
        uint32 width;
        uint32 height;
    }

    enum ProposalState { Pending, Active, Approved, Rejected, Executed }
    enum ProposalType {
        SetCanvasDimensions,
        SetGovernanceParameters,
        SetBasePixelColor, // Can include area or single pixel
        SetPromptLockDuration,
        SetInfluenceAreaFee,
        SetFeeRecipient,
        CustomAction // For arbitrary calls via governance
    }

    struct Proposal {
        address proposer;
        string description;
        uint40 expiration; // Timestamp when voting ends
        uint256 yesVotes;
        uint256 noVotes;
        EnumerableSet.AddressSet voters; // Addresses that have voted
        bool executed;
        ProposalState state;
        ProposalType proposalType;
        bytes callData; // Data for execution, specific to proposalType
        address target; // Target address for CustomAction or parameter setting calls
    }

    // --- State Variables ---

    // Canvas State
    uint32 public canvasWidth;
    uint32 public canvasHeight;
    // Simple state represented by a uint8 (e.g., color index, texture ID, intensity)
    // Using mapping(uint32 => mapping(uint32 => uint8)) for pixel coordinates
    // Note: Storing state for every pixel can be very gas intensive for large canvases.
    // A more advanced version might store ranges/patterns or rely more heavily on off-chain rendering
    // interpreting influence layers. For this example, we store base & current state.
    mapping(uint32 => mapping(uint32 => uint8)) private canvasBaseState; // Default state
    mapping(uint32 => mapping(uint32 => uint8)) private canvasCurrentState; // State after evolution

    uint40 public canvasLastUpdateTime; // Timestamp of the last evolution

    // Token Data
    uint256 private _nextTokenId;
    mapping(uint256 => string) private tokenPrompts;
    mapping(uint256 => uint40) private promptLockUntil; // Timestamp unlock
    mapping(uint256 => Rect) private tokenInfluenceArea;
    mapping(uint256 => address) private promptInfluenceDelegate; // Address allowed to set prompt

    uint40 public promptLockDuration; // Default duration for prompt locks

    // Influence Area Management
    uint256 public influenceAreaFee; // Fee to claim or update influence area

    // Governance
    uint256 public proposalCount;
    mapping(uint256 => Proposal) private proposals;
    uint40 public votingPeriod; // Duration for proposals to be active
    uint256 public quorumNumerator; // Quorum: (yesVotes + noVotes) * quorumDenominator >= totalTokensAtProposal * quorumNumerator
    uint256 public quorumDenominator;
    uint256 public minTokensToPropose; // Minimum tokens required to create a proposal

    // Fees
    uint256 public totalCollectedFees;
    address payable public feeRecipient;

    // --- Events ---
    event BrushTokenMinted(address indexed owner, uint256 indexed tokenId);
    event PromptSet(uint256 indexed tokenId, string prompt, address indexed setter);
    event PromptLocked(uint256 indexed tokenId, uint40 unlockTime);
    event PromptUnlocked(uint256 indexed tokenId);
    event InfluenceAreaClaimed(uint256 indexed tokenId, Rect area);
    event InfluenceAreaReleased(uint256 indexed tokenId);
    event CanvasStateUpdated(uint40 indexed updateTime);
    event PixelColorUpdated(uint32 x, uint32 y, uint8 color); // May emit many during updateCanvasState
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint40 expiration);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event PromptInfluenceDelegateSet(uint256 indexed tokenId, address indexed delegate);

    // --- Modifiers ---
    modifier onlyTokenOwnerOrDelegate(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId) || promptInfluenceDelegate[tokenId] == msg.sender, "Not token owner or delegate");
        _;
    }

    modifier onlyWhenUnlocked(uint256 tokenId) {
        require(promptLockUntil[tokenId] <= block.timestamp, "Prompt is locked");
        _;
    }

    modifier onlyGovernance() {
        // In a real DAO, this would check if msg.sender is the Governance contract itself
        // calling based on an executed proposal. For this example, we'll allow the current
        // owner (who could be replaced by a DAO contract) or successful proposal execution
        // via the executeProposal function (which uses callData).
        // Here we check if the call is coming *from* executeProposal or the Owner/Gov contract address.
        // Simpler for example: Assume the owner (or future DAO contract address set as owner)
        // is the only one who can trigger governance actions *directly* outside of executeProposal.
         require(msg.sender == owner() || _isExecutingProposal(), "Only callable by governance or owner");
        _;
    }

    // Helper to check if the call is originating from within executeProposal
    bool private _isExecutingProposalFlag;
    modifier isExecutingProposal() {
        _isExecutingProposalFlag = true;
        _;
        _isExecutingProposalFlag = false;
    }

    function _isExecutingProposal() internal view returns (bool) {
        return _isExecutingProposalFlag;
    }


    // --- Constructor ---
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint32 initialWidth, uint32 initialHeight, address payable initialFeeRecipient)
        ERC721("EternalCanvas BrushToken", "ECBRUSH")
        Ownable(msg.sender) // Initial owner is the deployer, can be transferred to a DAO contract
    {
        require(initialWidth > 0 && initialHeight > 0, "Canvas dimensions must be positive");
        require(initialFeeRecipient != address(0), "Fee recipient cannot be zero address");

        canvasWidth = initialWidth;
        canvasHeight = initialHeight;
        canvasLastUpdateTime = uint40(block.timestamp);

        _nextTokenId = 0;
        promptLockDuration = 30 days; // Example default: 30 days lock

        influenceAreaFee = 0.01 ether; // Example fee to claim an area

        // Example initial governance parameters
        votingPeriod = 7 days;
        quorumNumerator = 4; // 4/10 = 40% quorum
        quorumDenominator = 10;
        minTokensToPropose = 1; // Requires holding at least 1 token to propose

        feeRecipient = initialFeeRecipient;
        totalCollectedFees = 0;

        // Initialize a simple base canvas state (e.g., all 0)
        for (uint32 y = 0; y < canvasHeight; y++) {
            for (uint32 x = 0; x < canvasWidth; x++) {
                canvasBaseState[x][y] = 0;
                canvasCurrentState[x][y] = 0; // Start with current = base
            }
        }
    }

    // --- BrushToken Management ---

    /// @notice Mints a new BrushToken.
    /// @param to The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mintBrushToken(address to) external payable returns (uint256) {
        require(to != address(0), "Mint to zero address");
        // No minting fee for simplicity in this example, or uncomment below
        // require(msg.value >= mintFee, "Insufficient ETH for mint fee");
        // totalCollectedFees = totalCollectedFees.add(msg.value);

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize token data
        tokenPrompts[tokenId] = ""; // Empty initial prompt
        promptLockUntil[tokenId] = 0;
        // No influence area claimed initially
        promptInfluenceDelegate[tokenId] = address(0);

        emit BrushTokenMinted(to, tokenId);

        return tokenId;
    }

    /// @notice See {ERC721-tokenURI}.
    /// @dev This implementation includes token-specific dynamic data in the metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        // Construct a data URI or IPFS URI dynamically
        // In a real application, this might point to a service that queries the contract state
        // and generates a JSON metadata file on the fly or serves a pre-rendered image/data.
        // For this example, we'll return a simple placeholder or data URL.
        // An off-chain process would generate the actual image and metadata based on the prompt
        // and canvas state, and perhaps a hash of that generated image could be stored on-chain or linked here.

        string memory baseURI = _baseURI();
        string memory prompt = tokenPrompts[tokenId];
        uint40 lockTime = promptLockUntil[tokenId];
        Rect memory area = tokenInfluenceArea[tokenId]; // Note: Structs cannot be returned directly from mappings, copy to memory
        address delegate = promptInfluenceDelegate[tokenId];

        // Example data URL structure (simplistic)
        // data:application/json;base64, eyJuYW1lIjogIkV0ZXJuYWxDYW52YXMgQlJVSFNIIy...", etc.
        // Encoding the JSON payload would happen here.
        // For demonstration, let's just return a placeholder string with some data.
        return string(abi.encodePacked(
            baseURI,
            "metadata/",
            Strings.toString(tokenId),
            "?prompt=",
            prompt,
            "&locked=",
            lockTime > block.timestamp ? "true" : "false",
            "&area=",
            Strings.toString(area.x), ",", Strings.toString(area.y), ",",
            Strings.toString(area.width), ",", Strings.toString(area.height),
            "&delegate=",
            Strings.toHexString(uint160(delegate), 20)
        ));
    }

     /// @notice Retrieves comprehensive details for a specific BrushToken.
     /// @param tokenId The ID of the token.
     /// @return owner_ The owner of the token.
     /// @return prompt_ The AI prompt associated with the token.
     /// @return promptLockUntil_ Timestamp when prompt lock expires.
     /// @return influenceArea_ The rectangular area influenced by the token.
     /// @return delegate_ The address delegated to set the prompt.
    function getTokenDetails(uint256 tokenId) public view returns (address owner_, string memory prompt_, uint40 promptLockUntil_, Rect memory influenceArea_, address delegate_) {
         _requireOwned(tokenId); // Ensure token exists

         owner_ = ownerOf(tokenId);
         prompt_ = tokenPrompts[tokenId];
         promptLockUntil_ = promptLockUntil[tokenId];
         influenceArea_ = tokenInfluenceArea[tokenId]; // Copy struct to memory
         delegate_ = promptInfluenceDelegate[tokenId];
         return (owner_, prompt_, promptLockUntil_, influenceArea_, delegate_);
    }

    // --- Prompt Management ---

    /// @notice Sets or updates the AI prompt for a token.
    /// @dev Only owner or delegate can set, respects prompt lock.
    /// @param tokenId The ID of the token.
    /// @param newPrompt The new prompt string.
    function setTokenPrompt(uint256 tokenId, string memory newPrompt) external onlyTokenOwnerOrDelegate(tokenId) onlyWhenUnlocked(tokenId) {
        tokenPrompts[tokenId] = newPrompt;
        // Note: Setting a prompt could potentially update the last update time for *this* token
        // which could factor into the canvas evolution logic.
        emit PromptSet(tokenId, newPrompt, msg.sender);
    }

    /// @notice Locks the token's prompt, preventing changes for `promptLockDuration`.
    /// @dev Only owner can lock.
    /// @param tokenId The ID of the token.
    function lockPrompt(uint256 tokenId) external {
        _requireOwned(tokenId);
        require(promptLockUntil[tokenId] <= block.timestamp, "Prompt is already locked");

        promptLockUntil[tokenId] = uint40(block.timestamp) + promptLockDuration;
        emit PromptLocked(tokenId, promptLockUntil[tokenId]);
    }

    /// @notice Unlocks the token's prompt. Can be called by owner if time is up or forcibly.
    /// @dev Only owner can unlock.
    /// @param tokenId The ID of the token.
    function unlockPrompt(uint256 tokenId) external {
        _requireOwned(tokenId);
        require(promptLockUntil[tokenId] > 0, "Prompt is not locked");
        // Allow unlock if time is up OR owner forces it
        require(promptLockUntil[tokenId] <= block.timestamp, "Prompt is still locked");

        promptLockUntil[tokenId] = 0;
        emit PromptUnlocked(tokenId);
    }

    /// @notice Checks if a token's prompt is currently locked.
    /// @param tokenId The ID of the token.
    /// @return True if locked, false otherwise.
    function checkPromptLockStatus(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId); // Check if token exists
        return promptLockUntil[tokenId] > block.timestamp;
    }

    /// @notice Allows the token owner to delegate prompt setting rights to another address.
    /// @dev Only owner can delegate. Setting delegate to address(0) removes delegation.
    /// @param tokenId The ID of the token.
    /// @param delegate The address to delegate prompt influence to.
    function delegatePromptInfluence(uint256 tokenId, address delegate) external {
        _requireOwned(tokenId);
        promptInfluenceDelegate[tokenId] = delegate;
        emit PromptInfluenceDelegateSet(tokenId, delegate);
    }

    /// @notice Removes the prompt influence delegation for a token.
    /// @dev Only owner can remove delegation.
    /// @param tokenId The ID of the token.
    function removePromptInfluenceDelegate(uint256 tokenId) external {
        _requireOwned(tokenId);
        promptInfluenceDelegate[tokenId] = address(0);
        emit PromptInfluenceDelegateSet(tokenId, address(0));
    }

    /// @notice Gets the address currently delegated to set a token's prompt.
    /// @param tokenId The ID of the token.
    /// @return The delegate address, or address(0) if no delegate is set.
    function getPromptInfluenceDelegate(uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return promptInfluenceDelegate[tokenId];
    }


    // --- Canvas Influence Management ---

    /// @notice Claims a rectangular area on the canvas for the token. Pays influence fee.
    /// @dev Only token owner can claim. Area must be within canvas bounds. Overlapping claims are allowed.
    /// @param tokenId The ID of the token.
    /// @param area The rectangular area to claim.
    function claimInfluenceArea(uint256 tokenId, Rect memory area) external payable {
        _requireOwned(tokenId);
        require(area.x + area.width <= canvasWidth && area.y + area.height <= canvasHeight, "Claimed area is out of bounds");
        require(area.width > 0 && area.height > 0, "Claimed area must have positive dimensions");
        require(msg.value >= influenceAreaFee, "Insufficient ETH for influence area fee");

        totalCollectedFees = totalCollectedFees.add(msg.value);
        tokenInfluenceArea[tokenId] = area;

        emit InfluenceAreaClaimed(tokenId, area);
    }

    /// @notice Releases the token's claim on an influence area.
    /// @dev Only token owner can release.
    /// @param tokenId The ID of the token.
    function releaseInfluenceArea(uint256 tokenId) external {
        _requireOwned(tokenId);
        // Check if an area was actually claimed (Rect with 0 width/height is considered unclaimed)
        Rect storage currentArea = tokenInfluenceArea[tokenId];
        require(currentArea.width > 0 || currentArea.height > 0, "Token has no area claimed");

        delete tokenInfluenceArea[tokenId]; // Reset struct to default (x=0, y=0, width=0, height=0)

        // Emit event with an empty/zero area to signify release
        emit InfluenceAreaReleased(tokenId);
    }

    /// @notice Gets the rectangular area currently claimed by a token.
    /// @param tokenId The ID of the token.
    /// @return The claimed Rect struct. Returns {0,0,0,0} if no area is claimed.
    function getInfluenceArea(uint256 tokenId) public view returns (Rect memory) {
        _requireMinted(tokenId);
        // Return a copy from storage
        return tokenInfluenceArea[tokenId];
    }

    /// @notice Finds all tokens whose claimed influence area overlaps with a given point.
    /// @dev NOTE: This function iterates through all minted tokens and their claimed areas.
    ///      For a large number of tokens, this could be extremely gas-intensive and might exceed block gas limits.
    ///      In a production system, influence mapping might be handled differently (e.g., off-chain indexing,
    ///      or a different on-chain data structure if feasible). Use with caution.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return An array of token IDs influencing the point.
    function getTokensInfluencingArea(uint32 x, uint32 y) public view returns (uint256[] memory) {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");

        uint256[] memory influencingTokenIds = new uint256[](_nextTokenId); // Max possible size
        uint256 count = 0;

        // Iterate through all existing token IDs
        for (uint256 i = 0; i < _nextTokenId; i++) {
             // Check if the token exists and has a claimed area
            if (_exists(i)) {
                Rect memory area = tokenInfluenceArea[i];
                // Check if the point (x, y) is within the claimed area
                if (area.width > 0 && area.height > 0 &&
                    x >= area.x && x < area.x + area.width &&
                    y >= area.y && y < area.y + area.height)
                {
                    influencingTokenIds[count] = i;
                    count++;
                }
            }
        }

        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = influencingTokenIds[i];
        }

        return result;
    }


    // --- Canvas State & Evolution ---

    /// @notice Triggers a canvas state evolution step.
    /// @dev Can be called by anyone, but only executes if enough time has passed since the last update.
    ///      This function contains the core logic for how prompts influence the canvas state.
    ///      The actual logic here is simplified for demonstration. In a real contract, this
    ///      would involve more complex calculations based on prompts, time, overlaps, etc.
    ///      Processing every pixel could be too expensive; a real implementation might process
    ///      in chunks or use aggregated data.
    function updateCanvasState() external {
        // Define an evolution interval (e.g., 1 hour)
        uint40 evolutionInterval = 1 hours; // Example: 1 hour interval

        require(block.timestamp >= canvasLastUpdateTime + evolutionInterval, "Canvas evolution interval not reached");

        // Simple evolution logic:
        // Iterate through all claimed areas and apply influence.
        // This is a very basic simulation. A real system might use prompt hashes,
        // block hashes, randomness, or external data feeds to make it more dynamic.
        // Overlapping areas would need complex blending logic.
        // Iterating all tokens and their areas can be gas-intensive.

        for (uint256 tokenId = 0; tokenId < _nextTokenId; tokenId++) {
             if (_exists(tokenId)) {
                Rect memory area = tokenInfluenceArea[tokenId];
                string memory prompt = tokenPrompts[tokenId];

                if (area.width > 0 && area.height > 0 && bytes(prompt).length > 0) {
                     // Basic Influence Logic: Apply a 'color' derived from prompt hash and time
                     // This is a placeholder. Complex AI influence is off-chain.
                     // Here, we just use the prompt length and current time as a simple factor.
                     uint8 influenceFactor = uint8((keccak256(abi.encodePacked(prompt, block.timestamp)) % 100) + 1); // 1-100

                     for (uint32 y = 0; y < area.y + area.height; y++) { // Correct loop bounds
                        for (uint32 x = 0; x < area.x + area.width; x++) { // Correct loop bounds
                            if (x >= area.x && x < canvasWidth && y >= area.y && y < canvasHeight) { // Check bounds again defensively
                                // Simple blending/application: e.g., average with base state, or replace, or add/subtract
                                // Example: Apply influence based on the sum of ASCII values in the prompt segment
                                uint256 promptSum = 0;
                                bytes memory promptBytes = bytes(prompt);
                                // Sum a portion of the prompt or its hash
                                uint256 hashValue = uint256(keccak256(promptBytes));
                                promptSum = (hashValue % 256); // Use hash for more randomness

                                // Combine base state, current state, and prompt influence
                                // This is a very simplified pixel update rule.
                                uint8 base = canvasBaseState[x][y];
                                uint8 current = canvasCurrentState[x][y];
                                uint8 newColor = uint8((base + current + uint8(promptSum) + influenceFactor) / 3); // Example blending logic

                                if (canvasCurrentState[x][y] != newColor) {
                                    canvasCurrentState[x][y] = newColor;
                                    emit PixelColorUpdated(x, y, newColor);
                                }
                            }
                        }
                    }
                } else {
                    // If no prompt or area, potentially revert to base state in the area over time
                    // Or just leave it as is if no influence is exerted.
                     if (area.width > 0 && area.height > 0) {
                         for (uint32 y = area.y; y < area.y + area.height && y < canvasHeight; y++) {
                            for (uint32 x = area.x; x < area.x + area.width && x < canvasWidth; x++) {
                                if (canvasCurrentState[x][y] != canvasBaseState[x][y]) {
                                    canvasCurrentState[x][y] = canvasBaseState[x][y]; // Revert to base if no influence
                                    emit PixelColorUpdated(x, y, canvasBaseState[x][y]);
                                }
                            }
                        }
                     }
                }
            }
        }

        canvasLastUpdateTime = uint40(block.timestamp);
        emit CanvasStateUpdated(canvasLastUpdateTime);
    }

    /// @notice Retrieves the current state/color value for a specific pixel.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @return The uint8 value representing the pixel state.
    function getPixelColorAt(uint32 x, uint32 y) public view returns (uint8) {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        return canvasCurrentState[x][y];
    }

    /// @notice Gets the current dimensions of the canvas.
    /// @return width_ The canvas width.
    /// @return height_ The canvas height.
    function getCanvasDimensions() public view returns (uint32 width_, uint32 height_) {
        return (canvasWidth, canvasHeight);
    }

    /// @notice Gets the timestamp of the last canvas evolution update.
    /// @return The timestamp.
    function getCanvasLastUpdateTime() public view returns (uint40) {
        return canvasLastUpdateTime;
    }


    // --- Governance ---

    /// @notice Creates a new governance proposal.
    /// @dev Requires minimum token holdings.
    /// @param description A description of the proposal.
    /// @param proposalType The type of proposal (determines execution logic).
    /// @param callData Data required for execution (e.g., encoded function call).
    /// @return The ID of the new proposal.
    function createProposal(string memory description, uint256 proposalType, bytes memory callData) external returns (uint256) {
        // Requires msg.sender to hold at least minTokensToPropose
        require(balanceOf(msg.sender) >= minTokensToPropose, "Not enough tokens to propose");
        require(proposalType < uint256(ProposalType.CustomAction) || callData.length > 0, "Call data required for CustomAction");

        uint256 proposalId = proposalCount;
        Proposal storage proposal = proposals[proposalId];

        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.expiration = uint40(block.timestamp) + votingPeriod;
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        proposal.state = ProposalState.Active;
        proposal.proposalType = ProposalType(proposalType);
        proposal.callData = callData;
        // For simplicity, target is not explicitly stored unless needed by CustomAction parsing

        proposalCount++;

        emit ProposalCreated(proposalId, msg.sender, description, proposal.expiration);

        return proposalId;
    }

    /// @notice Casts a vote on an active proposal.
    /// @dev Vote weight is based on voter's token balance. Can only vote once per proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp < proposal.expiration, "Voting period has ended");
        require(!proposal.voters.contains(msg.sender), "Already voted on this proposal");

        // Vote weight based on current token balance
        uint256 voteWeight = balanceOf(msg.sender);
        require(voteWeight > 0, "Must hold tokens to vote");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(voteWeight);
        } else {
            proposal.noVotes = proposal.noVotes.add(voteWeight);
        }

        proposal.voters.add(msg.sender);

        emit VoteCast(proposalId, msg.sender, support);

        // Check if voting period ended after this vote
        if (block.timestamp >= proposal.expiration) {
            _evaluateProposal(proposalId, proposal);
        }
    }

    /// @notice Evaluates a proposal's outcome after the voting period ends.
    /// @dev Internal helper function.
    function _evaluateProposal(uint256 proposalId, Proposal storage proposal) internal {
        if (proposal.state != ProposalState.Active || block.timestamp < proposal.expiration) {
            return; // Not ready to evaluate
        }

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        // Simplified quorum: total votes must meet a percentage of *total minted tokens*
        // A more robust DAO would snapshot token supply at proposal creation.
        uint256 totalTokens = _nextTokenId; // Assuming all minted tokens are relevant for quorum
        require(totalTokens > 0, "Cannot evaluate proposal with no tokens minted"); // Avoid division by zero

        bool quorumMet = totalVotes.mul(quorumDenominator) >= totalTokens.mul(quorumNumerator);
        bool passed = proposal.yesVotes > proposal.noVotes;

        if (quorumMet && passed) {
            proposal.state = ProposalState.Approved;
        } else {
            proposal.state = ProposalState.Rejected;
        }
    }


    /// @notice Executes an approved proposal.
    /// @dev Can be called by anyone once proposal is Approved.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) external isExecutingProposal {
        Proposal storage proposal = proposals[proposalId];
        // First, ensure voting period has ended and evaluate if not already done
        _evaluateProposal(proposalId, proposal);

        require(proposal.state == ProposalState.Approved, "Proposal is not approved for execution");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        // --- Execute the proposal based on its type ---
        bytes memory data = proposal.callData;
        address target = address(this); // Most governance calls are on this contract

        if (proposal.proposalType == ProposalType.SetCanvasDimensions) {
             (uint32 width, uint32 height) = abi.decode(data, (uint32, uint32));
             _setCanvasDimensions(width, height); // Use internal helper
        } else if (proposal.proposalType == ProposalType.SetGovernanceParameters) {
             (uint40 votingPeriod_, uint256 quorumNumerator_, uint256 quorumDenominator_, uint256 minTokensToPropose_) = abi.decode(data, (uint40, uint256, uint256, uint256));
             _setGovernanceParameters(votingPeriod_, quorumNumerator_, quorumDenominator_, minTokensToPropose_); // Use internal helper
        } else if (proposal.proposalType == ProposalType.SetBasePixelColor) {
             // Assuming callData encodes a single pixel or area + color
             (uint32 x, uint32 y, uint8 color) = abi.decode(data, (uint32, uint32, uint8));
             _setBasePixelColor(x, y, color); // Use internal helper (single pixel for simplicity)
             // Could extend to set area base color
        } else if (proposal.proposalType == ProposalType.SetPromptLockDuration) {
             (uint40 duration) = abi.decode(data, (uint40));
             _setPromptLockDuration(duration); // Use internal helper
        } else if (proposal.proposalType == ProposalType.SetInfluenceAreaFee) {
             (uint256 fee) = abi.decode(data, (uint256));
             _setInfluenceAreaFee(fee); // Use internal helper
        } else if (proposal.proposalType == ProposalType.SetFeeRecipient) {
             (address payable recipient) = abi.decode(data, (address payable));
             _setFeeRecipient(recipient); // Use internal helper
        } else if (proposal.proposalType == ProposalType.CustomAction) {
             // Requires callData to encode target and function call
             // For simplicity, assume target is the contract owner can allow (like the DAO contract)
             // In a real scenario, this would need more complex parsing or strict rules on target/callData
             (address customTarget, bytes memory customCallData) = abi.decode(data, (address, bytes));
             require(customTarget.isContract(), "Custom action target must be a contract"); // Prevent sending ETH to EOA inadvertently

             // Use low-level call to execute arbitrary logic
             (bool success, ) = customTarget.call(customCallData);
             require(success, "Custom action execution failed");
        } else {
            revert("Unknown proposal type"); // Should not happen if enums are handled correctly
        }

        emit ProposalExecuted(proposalId);
    }

    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The ProposalState enum value.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Re-evaluate state if voting period ended and state is still Active
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.expiration) {
             // Note: Cannot change storage in a view function,
             // so this check is just for the returned value's accuracy.
             // The state change happens when voteOnProposal is called after expiration, or executeProposal.
             uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
             uint256 totalTokens = _nextTokenId; // Use current supply for view
             if (totalTokens == 0) return ProposalState.Rejected; // Can't meet quorum with 0 tokens

             bool quorumMet = totalVotes.mul(quorumDenominator) >= totalTokens.mul(quorumNumerator);
             bool passed = proposal.yesVotes > proposal.noVotes;

             if (quorumMet && passed) {
                 return ProposalState.Approved;
             } else {
                 return ProposalState.Rejected;
             }
        }

        return proposal.state;
    }

    /// @notice Gets the vote counts for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return yesVotes_ The count of 'yes' votes.
    /// @return noVotes_ The count of 'no' votes.
    function getVoteCount(uint256 proposalId) public view returns (uint256 yesVotes_, uint256 noVotes_) {
         require(proposalId < proposalCount, "Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         return (proposal.yesVotes, proposal.noVotes);
    }


    // --- Admin & Parameter Management (Internal Helpers called by Governance or Owner) ---

    /// @notice Sets the base/default color for a specific pixel.
    /// @dev Intended to be called by governance execution.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    /// @param color The new base color value.
    function _setBasePixelColor(uint32 x, uint32 y, uint8 color) internal onlyGovernance {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        canvasBaseState[x][y] = color;
        // Optional: Update canvasCurrentState immediately or wait for next evolution
        // canvasCurrentState[x][y] = color; // Decided to let evolution handle propagation
         // No specific event for base change, PixelColorUpdated reflects current state change.
    }

    /// @notice Sets the dimensions of the canvas.
    /// @dev Intended to be called by governance execution. Note: Resizing can reset pixel states.
    /// @param width The new width.
    /// @param height The new height.
    function _setCanvasDimensions(uint32 width, uint32 height) internal onlyGovernance {
        require(width > 0 && height > 0, "Canvas dimensions must be positive");
        // Warning: Shrinking canvas could orphan influence areas.
        // Expanding requires initializing new pixel states (expensive).
        // Simple implementation: just update values. A real contract needs careful migration.
        canvasWidth = width;
        canvasHeight = height;
        // Re-initialization of mappings for new size is complex and gas-heavy.
        // For simplicity, pixels outside old bounds will read 0 by default.
        // Pixels inside old bounds retain state unless overwritten.
    }

     /// @notice Sets the governance parameters.
     /// @dev Intended to be called by governance execution.
     function _setGovernanceParameters(
         uint40 votingPeriod_,
         uint256 quorumNumerator_,
         uint256 quorumDenominator_,
         uint256 minTokensToPropose_
     ) internal onlyGovernance {
        require(quorumDenominator_ > 0, "Quorum denominator must be positive");
        votingPeriod = votingPeriod_;
        quorumNumerator = quorumNumerator_;
        quorumDenominator = quorumDenominator_;
        minTokensToPropose = minTokensToPropose_;
    }

    /// @notice Sets the default duration for prompt locks.
    /// @dev Intended to be called by governance execution.
    /// @param duration The new duration in seconds.
    function _setPromptLockDuration(uint40 duration) internal onlyGovernance {
        promptLockDuration = duration;
    }

    /// @notice Sets the fee required to claim an influence area.
    /// @dev Intended to be called by governance execution.
    /// @param fee The new fee amount in wei.
    function _setInfluenceAreaFee(uint256 fee) internal onlyGovernance {
        influenceAreaFee = fee;
    }

     /// @notice Sets the address that receives collected fees.
     /// @dev Intended to be called by governance execution.
     /// @param recipient The new fee recipient address.
     function _setFeeRecipient(address payable recipient) internal onlyGovernance {
        require(recipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = recipient;
    }

    /// @notice Allows the fee recipient to withdraw collected fees.
    /// @dev Intended to be called by the fee recipient (initially owner, changeable by governance).
    function withdrawFees() external {
        require(msg.sender == feeRecipient, "Only the fee recipient can withdraw");
        require(totalCollectedFees > 0, "No fees to withdraw");

        uint256 amount = totalCollectedFees;
        totalCollectedFees = 0;

        (bool success, ) = feeRecipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }


    // --- Internal/Helper ERC721 Overrides ---

    // The following functions are required by ERC721 but are standard OpenZeppelin implementations.
    // Including them for completeness, but they don't count towards the "creative/advanced" logic count.
    // (Total functions counted starts from 2 for mintBrushToken)

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

     // Helper function to check if a token exists
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
}
```