Okay, let's design a smart contract for a collaborative art project on the blockchain, incorporating advanced concepts like on-chain contribution data, reputation systems, different contribution types, lifecycle phases, and potential dynamic elements.

This contract, tentatively called `CryptoArtCollaborativeCanvas`, allows multiple users to contribute various artistic elements (pixels, shapes, text, potentially even programmable patterns) to a shared digital canvas. Contributions require a fee, and users build reputation based on their contributions and community feedback (flagging/curation). The canvas progresses through different phases, and the final state could potentially be tokenized or used for generating unique NFTs.

**Disclaimer:** This contract is complex and involves storing potentially large amounts of data on-chain, which can be expensive. The rendering of the actual art would happen *off-chain* using the data stored in the contract. This is a conceptual design; real-world implementation would require careful gas optimization and consideration of data storage limits.

---

**Outline & Function Summary**

**Contract Name:** `CryptoArtCollaborativeCanvas`

**Concept:** A decentralized, collaborative digital canvas where users pay to add artistic elements. Features include a reputation system, multiple contribution types, canvas lifecycle phases, and curator moderation.

**Core Data Structures:**
*   `Contribution`: Stores details of a single artistic contribution (type, position, color/data, layer, contributor, status).
*   `Reputation`: Stores a user's reputation score and moderation flags.

**Enums:**
*   `CanvasPhase`: `Creation`, `Review`, `Finalized`.
*   `ContributionType`: `Pixel`, `Line`, `Rectangle`, `Circle`, `Text`, `PatternRef`, `DynamicElement`.
*   `ContributionStatus`: `Pending`, `Approved`, `Rejected`, `Flagged`.

**Key Features & Function Groups:**

1.  **Initialization & Administration:**
    *   `constructor`: Initializes canvas dimensions, fee, owner, and initial curators.
    *   `setContributionFee`: Sets the fee required to add a contribution.
    *   `addCurator`: Grants curator role.
    *   `removeCurator`: Revokes curator role.
    *   `setCanvasPhase`: Advances or changes the canvas phase (Creation, Review, Finalized).
    *   `setReputationThreshold`: Sets the minimum reputation required for specific contribution types.
    *   `withdrawFees`: Allows owner/governance to withdraw collected fees.

2.  **Contribution Functions (Diverse Types):**
    *   `addPixel`: Adds a single pixel contribution.
    *   `addLine`: Adds a line segment.
    *   `addRectangle`: Adds a rectangle.
    *   `addCircle`: Adds a circle.
    *   `addText`: Adds a text string (or reference).
    *   `addPatternRef`: Adds a reference to a pre-defined on-chain or off-chain pattern.
    *   `addDynamicElement`: Adds an element whose rendering changes based on external factors or contract state (requires off-chain interpretation).
    *   `getContributionData`: Retrieves details of a specific contribution by ID.

3.  **Reputation & Moderation:**
    *   `flagContribution`: Allows users to flag a contribution.
    *   `reviewFlaggedContribution`: Curators review flagged contributions (approve/reject).
    *   `approveContribution`: Curators approve a pending contribution.
    *   `rejectContribution`: Curators reject a pending contribution.
    *   `getUserReputation`: Gets a user's current reputation score.
    *   `getTopContributors`: Gets a list of contributors sorted by reputation (simplified in contract, might return IDs).
    *   `canAddContributionType`: Checks if a user meets the reputation threshold for a type.

4.  **Canvas State & Information:**
    *   `getCanvasDimensions`: Returns the width and height.
    *   `getContributionCount`: Returns the total number of contributions added.
    *   `getContributionsByContributor`: Returns IDs of contributions made by a specific address.
    *   `getCanvasDataHash`: Provides a hash of the current contribution data (for verification of off-chain rendering).
    *   `getCanvasMetadataURI`: Returns a URI for off-chain metadata and rendering instructions.

5.  **Finalization & Potential Value (Conceptual):**
    *   `finalizeCanvas`: Transitions to `Finalized` phase, locking contributions.
    *   `setRoyaltyInfo`: Sets royalty percentages for contributors if the final art is sold externally (e.g., as an NFT).
    *   `distributeRoyalties`: Distributes received royalties based on contribution weight/reputation (requires external call).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoArtCollaborativeCanvas
 * @dev A smart contract for a decentralized, collaborative digital art canvas.
 * Users pay to add different types of artistic elements (pixels, shapes, etc.).
 * Includes a reputation system, curator moderation, and lifecycle phases.
 * The actual rendering of the art happens off-chain based on the stored data.
 */
contract CryptoArtCollaborativeCanvas {

    // --- Enums ---

    /**
     * @dev Represents the current phase of the canvas lifecycle.
     * Creation: Users can add contributions.
     * Review: Contributions are reviewed (especially flagged ones), adding is paused.
     * Finalized: The canvas is complete, no more contributions can be added.
     */
    enum CanvasPhase { Creation, Review, Finalized }

    /**
     * @dev Represents the type of artistic contribution.
     * Pixel: A single colored point.
     * Line: A line segment between two points.
     * Rectangle: A rectangle defined by two corner points.
     * Circle: A circle defined by center and radius.
     * Text: A string of text (or reference to off-chain text).
     * PatternRef: A reference to a complex pattern or pre-defined element.
     * DynamicElement: An element whose appearance is dynamic (e.g., changes over time, based on external data - requires off-chain rendering logic).
     */
    enum ContributionType { Pixel, Line, Rectangle, Circle, Text, PatternRef, DynamicElement }

    /**
     * @dev Represents the status of a contribution regarding moderation.
     * Pending: Waiting for review (optional, depending on flow).
     * Approved: Accepted contribution.
     * Rejected: Not accepted.
     * Flagged: Marked by users for review.
     */
    enum ContributionStatus { Approved, Rejected, Flagged } // Simplified: Assume contributions are Approved by default unless flagged

    // --- Structs ---

    /**
     * @dev Stores data for a single artistic contribution.
     * Unique ID is the index in the contributions array.
     * Data encoding depends on type: e.g., Pixel=bytes3 (color), Line=bytes6 (x1,y1,x2,y2), Text=bytes (string or hash/ref), DynamicElement=bytes (params).
     */
    struct Contribution {
        address contributor;
        ContributionType cType;
        uint256 layer; // For layering elements
        bytes data; // Encoded data for the specific type (e.g., color for pixel, coordinates for shapes)
        uint256 timestamp;
        ContributionStatus status;
        uint256 flags; // Number of flags
        uint256 x; // Primary coordinate (e.g., for pixels, top-left for shapes, center for circle/dynamic)
        uint256 y; // Primary coordinate
    }

    /**
     * @dev Stores user reputation and moderation status.
     * score: A measure of positive contribution (e.g., approved contributions).
     * negativeScore: A measure of negative actions (e.g., rejected/flagged contributions).
     */
    struct Reputation {
        uint256 score;
        uint256 negativeScore; // Could lead to decreased score or temporary bans
    }

    // --- State Variables ---

    address public owner; // Contract owner/deployer, potentially replaced by governance later
    uint256 public canvasWidth;
    uint256 public canvasHeight;
    uint256 public contributionFee; // Fee (in native token, e.g., wei) per contribution
    CanvasPhase public currentPhase;

    Contribution[] public contributions; // Array to store all contributions

    // Mapping from contribution ID to contributor's address (redundant but useful for lookup)
    mapping(uint256 => address) private contributionIdToContributor;

    // Mapping from contributor address to their reputation data
    mapping(address => Reputation) public userReputation;

    // Set of addresses with curator role
    mapping(address => bool) public isCurator;
    address[] private curators; // Dynamic array to list curators (less efficient for checks, good for listing)

    // Mapping from ContributionType to minimum required reputation score
    mapping(ContributionType => uint256) public reputationThresholds;

    // For future royalty distribution (conceptual)
    struct RoyaltyInfo {
        address recipient;
        uint256 percentage; // Scaled, e.g., 100 = 1%
    }
    RoyaltyInfo[] public royaltyRecipients; // How royalties are shared (could be based on contribution weight)

    // --- Events ---

    event ContributionAdded(uint256 indexed contributionId, address indexed contributor, ContributionType cType, uint256 x, uint256 y);
    event ContributionFlagged(uint256 indexed contributionId, address indexed flagger, uint256 currentFlags);
    event ContributionStatusChanged(uint256 indexed contributionId, ContributionStatus newStatus, string reason);
    event UserReputationUpdated(address indexed user, uint256 newScore, uint256 newNegativeScore);
    event CanvasPhaseChanged(CanvasPhase indexed oldPhase, CanvasPhase indexed newPhase);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event ContributionFeeUpdated(uint256 newFee);
    event RoyaltyInfoSet(address indexed recipient, uint256 percentage);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only a curator can call this function");
        _;
    }

    modifier inPhase(CanvasPhase phase) {
        require(currentPhase == phase, "Function not available in this phase");
        _;
    }

    modifier notInPhase(CanvasPhase phase) {
        require(currentPhase != phase, "Function not available in this phase");
        _;
    }

    modifier requiresFee(uint256 feeAmount) {
        require(msg.value >= feeAmount, "Insufficient fee provided");
        _;
        // Refund excess Ether
        if (msg.value > feeAmount) {
            payable(msg.sender).transfer(msg.value - feeAmount);
        }
    }

    // --- Constructor ---

    constructor(uint256 _width, uint256 _height, uint256 _initialFee, address[] memory _initialCurators) {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        owner = msg.sender;
        canvasWidth = _width;
        canvasHeight = _height;
        contributionFee = _initialFee;
        currentPhase = CanvasPhase.Creation;

        for (uint i = 0; i < _initialCurators.length; i++) {
            addCurator(_initialCurators[i]); // Use the internal function or adjust access
        }
    }

    // --- 1. Initialization & Administration ---

    /**
     * @dev Sets the fee required for adding any contribution.
     * @param _newFee The new contribution fee in wei.
     */
    function setContributionFee(uint256 _newFee) external onlyOwner notInPhase(CanvasPhase.Finalized) {
        contributionFee = _newFee;
        emit ContributionFeeUpdated(_newFee);
    }

    /**
     * @dev Grants the curator role to an address. Curators can review flagged contributions.
     * @param _curator The address to add as a curator.
     */
    function addCurator(address _curator) public onlyOwner { // Made public for constructor
        require(_curator != address(0), "Invalid address");
        require(!isCurator[_curator], "Address is already a curator");
        isCurator[_curator] = true;
        curators.push(_curator);
        emit CuratorAdded(_curator);
    }

    /**
     * @dev Revokes the curator role from an address.
     * @param _curator The address to remove from curators.
     */
    function removeCurator(address _curator) external onlyOwner {
        require(_curator != address(0), "Invalid address");
        require(isCurator[_curator], "Address is not a curator");
        isCurator[_curator] = false;
        // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                curators[i] = curators[curators.length - 1];
                curators.pop();
                break;
            }
        }
        emit CuratorRemoved(_curator);
    }

    /**
     * @dev Advances or changes the canvas phase. Only allowed by owner and not backwards (except from Review to Creation).
     * @param _newPhase The phase to transition to.
     */
    function setCanvasPhase(CanvasPhase _newPhase) external onlyOwner {
        require(_newPhase != currentPhase, "Already in this phase");
        // Basic phase transition logic:
        // Creation -> Review
        // Review -> Creation (to allow more contributions after review)
        // Review -> Finalized
        // Finalized -> (None)
        if (currentPhase == CanvasPhase.Creation) {
            require(_newPhase == CanvasPhase.Review, "Invalid phase transition from Creation");
        } else if (currentPhase == CanvasPhase.Review) {
            require(_newPhase == CanvasPhase.Creation || _newPhase == CanvasPhase.Finalized, "Invalid phase transition from Review");
        } else if (currentPhase == CanvasPhase.Finalized) {
            revert("Cannot change phase from Finalized");
        }
        currentPhase = _newPhase;
        emit CanvasPhaseChanged(currentPhase, _newPhase); // oldPhase is implicitly the currentPhase before assignment
    }

     /**
     * @dev Sets the minimum reputation score required for a specific contribution type.
     * @param _cType The contribution type.
     * @param _minReputation The minimum reputation score required.
     */
    function setReputationThreshold(ContributionType _cType, uint256 _minReputation) external onlyOwner {
        reputationThresholds[_cType] = _minReputation;
    }


    /**
     * @dev Allows the owner/governance to withdraw accumulated fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner).transfer(balance);
        emit FeesWithdrawn(owner, balance);
    }


    // --- 2. Contribution Functions ---

    /**
     * @dev Internal helper to add a generic contribution.
     */
    function _addContribution(ContributionType _cType, uint256 _x, uint256 _y, uint256 _layer, bytes memory _data)
        internal
        inPhase(CanvasPhase.Creation)
        requiresFee(contributionFee)
    {
        // Basic boundary check (specific shape checks would be more complex)
        require(_x < canvasWidth && _y < canvasHeight, "Coordinates out of bounds");

        // Check reputation threshold
        require(userReputation[msg.sender].score >= reputationThresholds[_cType], "Insufficient reputation for this contribution type");

        uint256 contributionId = contributions.length;
        contributions.push(Contribution({
            contributor: msg.sender,
            cType: _cType,
            layer: _layer,
            data: _data,
            timestamp: block.timestamp,
            status: ContributionStatus.Approved, // By default, assume approved unless flagged later
            flags: 0,
            x: _x,
            y: _y
        }));

        contributionIdToContributor[contributionId] = msg.sender; // Store contributor address for easy lookup
        // No reputation change on adding, only on approval/rejection/flag review

        emit ContributionAdded(contributionId, msg.sender, _cType, _x, _y);
    }

    /**
     * @dev Adds a single pixel contribution.
     * @param _x X coordinate.
     * @param _y Y coordinate.
     * @param _layer Layer of the pixel.
     * @param _color RGB color encoded as bytes3 (e.g., 0xFF0000 for red).
     */
    function addPixel(uint256 _x, uint256 _y, uint256 _layer, bytes3 _color) external payable {
        // Encode color data as bytes
        bytes memory data = new bytes(3);
        data[0] = bytes1(_color[0]);
        data[1] = bytes1(_color[1]);
        data[2] = bytes1(_color[2]);
        _addContribution(ContributionType.Pixel, _x, _y, _layer, data);
    }

    /**
     * @dev Adds a line segment contribution.
     * @param _x1 Start X coordinate.
     * @param _y1 Start Y coordinate.
     * @param _x2 End X coordinate.
     * @param _y2 End Y coordinate.
     * @param _layer Layer of the line.
     * @param _color RGB color encoded as bytes3.
     */
    function addLine(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2, uint256 _layer, bytes3 _color) external payable {
         // More complex validation needed for coordinates within bounds for shapes/lines
        require(_x1 < canvasWidth && _y1 < canvasHeight && _x2 < canvasWidth && _y2 < canvasHeight, "Coordinates out of bounds");
        // Encode coordinates and color
        bytes memory data = new bytes(9); // 4 uint16 for coords + 3 bytes for color + 2 bytes padding for alignment (optional but good practice)
        assembly {
             mstore(add(data, 32), _x1) // Store _x1 starting at data[0] (relative to bytes start)
             mstore(add(data, 34), _y1) // Store _y1 starting at data[2]
             mstore(add(data, 36), _x2) // Store _x2 starting at data[4]
             mstore(add(data, 38), _y2) // Store _y2 starting at data[6]
             mstore(add(data, 40), _color) // Store _color bytes3 starting at data[8]
        }
        _addContribution(ContributionType.Line, _x1, _y1, _layer, data); // Use start point as primary coord
    }

    /**
     * @dev Adds a rectangle contribution.
     * @param _x1 Top-left X coordinate.
     * @param _y1 Top-left Y coordinate.
     * @param _x2 Bottom-right X coordinate.
     * @param _y2 Bottom-right Y coordinate.
     * @param _layer Layer of the rectangle.
     * @param _color RGB color encoded as bytes3.
     */
    function addRectangle(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2, uint256 _layer, bytes3 _color) external payable {
         // More complex validation needed
        require(_x1 < canvasWidth && _y1 < canvasHeight && _x2 < canvasWidth && _y2 < canvasHeight && _x1 < _x2 && _y1 < _y2, "Invalid rectangle coordinates");
        bytes memory data = new bytes(9); // Similar encoding as line
         assembly {
             mstore(add(data, 32), _x1)
             mstore(add(data, 34), _y1)
             mstore(add(data, 36), _x2)
             mstore(add(data, 38), _y2)
             mstore(add(data, 40), _color)
        }
        _addContribution(ContributionType.Rectangle, _x1, _y1, _layer, data); // Use top-left as primary coord
    }

    /**
     * @dev Adds a circle contribution.
     * @param _cx Center X coordinate.
     * @param _cy Center Y coordinate.
     * @param _r Radius.
     * @param _layer Layer of the circle.
     * @param _color RGB color encoded as bytes3.
     */
    function addCircle(uint256 _cx, uint256 _cy, uint256 _r, uint256 _layer, bytes3 _color) external payable {
        // Basic bounds check - a full circle might exceed bounds
         require(_cx < canvasWidth && _cy < canvasHeight, "Center coordinates out of bounds");
        bytes memory data = new bytes(7); // 2 uint16 for center + 1 uint16 for radius + 3 bytes color
        assembly {
             mstore(add(data, 32), _cx)
             mstore(add(data, 34), _cy)
             mstore(add(data, 36), _r)
             mstore(add(data, 38), _color)
        }
        _addContribution(ContributionType.Circle, _cx, _cy, _layer, data); // Use center as primary coord
    }

    /**
     * @dev Adds a text contribution.
     * @param _x Start X coordinate.
     * @param _y Start Y coordinate.
     * @param _layer Layer of the text.
     * @param _text The text string (consider length limits due to gas).
     * @param _color RGB color encoded as bytes3.
     */
    function addText(uint256 _x, uint256 _y, uint256 _layer, string calldata _text, bytes3 _color) external payable {
         require(_x < canvasWidth && _y < canvasHeight, "Coordinates out of bounds");
        // Encoding: color + text string bytes
        bytes memory textBytes = bytes(_text);
        bytes memory data = new bytes(3 + textBytes.length);
        assembly {
            mstore(add(data, 32), _color) // Store color first
        }
        uint textDataOffset = 3; // Offset after color
        for(uint i = 0; i < textBytes.length; i++) {
            data[textDataOffset + i] = textBytes[i];
        }
        _addContribution(ContributionType.Text, _x, _y, _layer, data); // Use start point as primary coord
    }

     /**
     * @dev Adds a reference to a pre-defined pattern.
     * @param _x Anchor X coordinate for the pattern.
     * @param _y Anchor Y coordinate for the pattern.
     * @param _layer Layer of the pattern.
     * @param _patternId ID of the pattern (could reference an enum, mapping, or another contract).
     * @param _params Optional parameters for the pattern (e.g., scale, rotation).
     */
    function addPatternRef(uint256 _x, uint256 _y, uint256 _layer, uint256 _patternId, bytes memory _params) external payable {
        require(_x < canvasWidth && _y < canvasHeight, "Anchor coordinates out of bounds");
        // Encoding: patternId + params
        bytes memory data = new bytes(32 + _params.length); // 32 for uint256 patternId
         assembly {
            mstore(add(data, 32), _patternId) // Store pattern ID
        }
        uint paramsDataOffset = 32;
        for(uint i = 0; i < _params.length; i++) {
            data[paramsDataOffset + i] = _params[i];
        }
        _addContribution(ContributionType.PatternRef, _x, _y, _layer, data); // Use anchor as primary coord
    }

     /**
     * @dev Adds a dynamic element whose appearance depends on state (e.g., time, block number, external oracle).
     * Requires off-chain renderer to interpret the dynamic logic.
     * @param _x Anchor X coordinate.
     * @param _y Anchor Y coordinate.
     * @param _layer Layer of the element.
     * @param _elementType ID/type of the dynamic element logic.
     * @param _params Parameters for the dynamic element logic.
     */
    function addDynamicElement(uint256 _x, uint256 _y, uint256 _layer, uint256 _elementType, bytes memory _params) external payable {
        require(_x < canvasWidth && _y < canvasHeight, "Anchor coordinates out of bounds");
         // Encoding: elementType + params
        bytes memory data = new bytes(32 + _params.length); // 32 for uint256 elementType
         assembly {
            mstore(add(data, 32), _elementType) // Store element Type ID
        }
        uint paramsDataOffset = 32;
        for(uint i = 0; i < _params.length; i++) {
            data[paramsDataOffset + i] = _params[i];
        }
        _addContribution(ContributionType.DynamicElement, _x, _y, _layer, data); // Use anchor as primary coord
    }

    /**
     * @dev Retrieves the data for a specific contribution by its ID.
     * @param _contributionId The ID of the contribution.
     * @return contribution struct data.
     */
    function getContributionData(uint256 _contributionId) external view returns (Contribution memory) {
        require(_contributionId < contributions.length, "Invalid contribution ID");
        return contributions[_contributionId];
    }

    // --- 3. Reputation & Moderation ---

    /**
     * @dev Allows any user to flag a contribution they deem inappropriate.
     * Repeated flags increase the flag count. Curators review flagged contributions.
     * @param _contributionId The ID of the contribution to flag.
     */
    function flagContribution(uint256 _contributionId) external {
        require(_contributionId < contributions.length, "Invalid contribution ID");
        // Prevent flagging already rejected/finalized contributions
        require(contributions[_contributionId].status != ContributionStatus.Rejected, "Contribution is already rejected");
        // Optional: Prevent flagging in Finalized phase? Or only allow flagging before Finalized?
        require(currentPhase != CanvasPhase.Finalized, "Cannot flag contributions in Finalized phase");

        contributions[_contributionId].flags++;
        contributions[_contributionId].status = ContributionStatus.Flagged; // Set status to Flagged

        // Optional: Decrease flagger's reputation if they flag too much or flags are dismissed?
        // Or require a small fee to flag to prevent spam?

        emit ContributionFlagged(_contributionId, msg.sender, contributions[_contributionId].flags);
    }

    /**
     * @dev Allows a curator to review a flagged contribution.
     * @param _contributionId The ID of the contribution to review.
     * @param _approve True to approve, False to reject.
     * @param _reason Optional reason for the decision.
     */
    function reviewFlaggedContribution(uint256 _contributionId, bool _approve, string calldata _reason) external onlyCurator {
        require(_contributionId < contributions.length, "Invalid contribution ID");
        require(contributions[_contributionId].status == ContributionStatus.Flagged, "Contribution is not flagged");
        require(currentPhase == CanvasPhase.Review, "Can only review flagged contributions in Review phase");

        address contributor = contributions[_contributionId].contributor;

        if (_approve) {
            contributions[_contributionId].status = ContributionStatus.Approved;
            // Increase contributor's reputation for having their contribution upheld
            userReputation[contributor].score++;
        } else {
            contributions[_contributionId].status = ContributionStatus.Rejected;
            // Decrease contributor's reputation for having their contribution rejected after flagging
            userReputation[contributor].negativeScore++; // Or decrease score directly
        }

        // Reset flags after review
        contributions[_contributionId].flags = 0;

        emit ContributionStatusChanged(_contributionId, contributions[_contributionId].status, _reason);
        emit UserReputationUpdated(contributor, userReputation[contributor].score, userReputation[contributor].negativeScore);

        // Optional: Logic to penalize users whose flags were consistently wrong?
    }

    /**
     * @dev Allows a curator to manually approve a contribution if a 'Pending' status was used (currently contributions are Approved by default).
     * Could be used if contributions require explicit curator approval instead of being auto-approved.
     * @param _contributionId The ID of the contribution to approve.
     */
    function approveContribution(uint256 _contributionId) external onlyCurator {
        require(_contributionId < contributions.length, "Invalid contribution ID");
        // Assuming contributions start as Approved unless flagged. This function might be for a different workflow.
        // If contributions started as Pending, you'd check that here.
        revert("Function not currently used as contributions are auto-approved unless flagged");
        // If used:
        // require(contributions[_contributionId].status == ContributionStatus.Pending, "Contribution is not pending");
        // contributions[_contributionId].status = ContributionStatus.Approved;
        // userReputation[contributions[_contributionId].contributor].score++;
        // emit ContributionStatusChanged(_contributionId, ContributionStatus.Approved, "Manually approved by curator");
        // emit UserReputationUpdated(...);
    }

    /**
     * @dev Allows a curator to manually reject a contribution (e.g., if not flagged but clearly spam).
     * @param _contributionId The ID of the contribution to reject.
     * @param _reason Optional reason for rejection.
     */
    function rejectContribution(uint256 _contributionId, string calldata _reason) external onlyCurator {
         require(_contributionId < contributions.length, "Invalid contribution ID");
         // Prevent rejecting already rejected/finalized contributions
         require(contributions[_contributionId].status != ContributionStatus.Rejected, "Contribution is already rejected");
         require(currentPhase != CanvasPhase.Finalized, "Cannot reject contributions in Finalized phase");

         address contributor = contributions[_contributionId].contributor;

         contributions[_contributionId].status = ContributionStatus.Rejected;
         contributions[_contributionId].flags = 0; // Clear flags if any

         // Decrease contributor's reputation
         userReputation[contributor].negativeScore++;

         emit ContributionStatusChanged(_contributionId, ContributionStatus.Rejected, _reason);
         emit UserReputationUpdated(contributor, userReputation[contributor].score, userReputation[contributor].negativeScore);
    }

    /**
     * @dev Gets the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score and negative score.
     */
    function getUserReputation(address _user) external view returns (uint256 score, uint256 negativeScore) {
        Reputation storage rep = userReputation[_user];
        return (rep.score, rep.negativeScore);
    }

    /**
     * @dev (Conceptual/Helper) Returns a list of curator addresses.
     * Note: Iterating over a mapping is not possible. This returns the list maintained manually.
     */
    function getCurators() external view returns (address[] memory) {
        return curators;
    }

    // --- 4. Canvas State & Information ---

    /**
     * @dev Returns the dimensions of the canvas.
     */
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /**
     * @dev Returns the total number of contributions added to the canvas (including rejected/flagged).
     */
    function getContributionCount() external view returns (uint256) {
        return contributions.length;
    }

     /**
     * @dev Returns the IDs of contributions made by a specific contributor.
     * Note: This requires iterating through all contributions, which can be gas-expensive for many contributions.
     * A more efficient way would be to store a mapping `address => uint256[] contributionIds`.
     * This implementation is for conceptual clarity, demonstrating the query.
     * @param _contributor The address of the contributor.
     * @return An array of contribution IDs.
     */
    function getContributionsByContributor(address _contributor) external view returns (uint256[] memory) {
        uint256[] memory contributorIds = new uint256[](contributions.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < contributions.length; i++) {
            // Use contributionIdToContributor mapping for efficiency if available,
            // but the primary `contributions` array stores it too.
            if (contributions[i].contributor == _contributor) {
                contributorIds[count] = i;
                count++;
            }
        }
        // Trim the array to actual size
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = contributorIds[i];
        }
        return result;
    }

    /**
     * @dev Checks if a user's current reputation allows them to add a specific contribution type.
     * Useful for front-end display.
     * @param _user The address of the user.
     * @param _cType The contribution type to check.
     * @return True if the user meets the reputation threshold, false otherwise.
     */
    function canAddContributionType(address _user, ContributionType _cType) external view returns (bool) {
        return userReputation[_user].score >= reputationThresholds[_cType];
    }

    /**
     * @dev Gets the current fee required to add a contribution.
     */
    function getContributionFee() external view returns (uint256) {
        return contributionFee;
    }

    /**
     * @dev Generates a hash of the current state of the contribution data.
     * This can be used by off-chain renderers to verify they are using the correct data snapshot.
     * Note: Hashing a large dynamic array is complex and gas-intensive on-chain.
     * This function is conceptual; a real implementation might hash a root of a Merkle Tree
     * representing contributions, or hash segments of data.
     */
    function getCanvasDataHash() external view returns (bytes32) {
         // This is a simplified placeholder. Hashing a dynamic array like this is not practical/possible in Solidity.
         // A real implementation would use a Merkle tree over contributions, or require off-chain hashing of fetched data.
        if (contributions.length == 0) {
            return bytes32(0);
        }
        // Example (NON-FUNCTIONAL/HIGHLY GASEY conceptual idea if it were possible):
        // bytes memory allData;
        // for(uint i = 0; i < contributions.length; i++) {
        //     allData = abi.encodePacked(allData, abi.encode(contributions[i]));
        // }
        // return keccak256(allData);

        // Returning a hash of the *last* contribution as a simplistic placeholder for demonstration
        // A production system needs a robust data integrity approach (e.g., Merkle Tree root)
        return keccak256(abi.encodePacked(contributions[contributions.length - 1], contributions.length, currentPhase));
    }

    /**
     * @dev Returns a URI pointing to off-chain metadata about the canvas and potential rendering instructions.
     * Can be used for NFT metadata if the canvas is tokenized.
     */
    function getCanvasMetadataURI() external view returns (string memory) {
        // This would typically return a URI pointing to a JSON file on IPFS or a web server
        // that describes the canvas, links to the rendering engine, etc.
        // Example: return "ipfs://QmVaultHash/metadata.json";
        // For demonstration, return a placeholder.
        return "https://your-art-renderer.com/metadata/canvas_1";
    }


    // --- 5. Finalization & Potential Value (Conceptual) ---

    /**
     * @dev Finalizes the canvas. Stops all contribution activity.
     * Sets the phase to `Finalized`. Can only be done from `Review`.
     */
    function finalizeCanvas() external onlyOwner inPhase(CanvasPhase.Review) {
        currentPhase = CanvasPhase.Finalized;
        emit CanvasPhaseChanged(CanvasPhase.Review, CanvasPhase.Finalized);
    }

    /**
     * @dev Sets the royalty recipients and their percentages. This is conceptual,
     * actual royalty distribution happens off-chain or via external NFT marketplaces.
     * This function merely records the intended distribution.
     * Called by owner/governance in `Finalized` phase.
     * @param _recipients Array of recipient addresses.
     * @param _percentages Array of percentages (scaled, e.g., 100 = 1%). Must sum to <= 10000 (100%).
     * Note: A real system might calculate percentages based on contributor reputation/number of contributions etc.
     */
    function setRoyaltyInfo(address[] calldata _recipients, uint256[] calldata _percentages) external onlyOwner inPhase(CanvasPhase.Finalized) {
         require(_recipients.length == _percentages.length, "Array length mismatch");
         uint256 totalPercentage = 0;
         // Clear existing royalty info (if any)
         delete royaltyRecipients;
         for (uint i = 0; i < _recipients.length; i++) {
             require(_recipients[i] != address(0), "Invalid recipient address");
             require(_percentages[i] <= 10000, "Percentage exceeds 100%"); // Max 100%
             royaltyRecipients.push(RoyaltyInfo(_recipients[i], _percentages[i]));
             totalPercentage += _percentages[i];
             emit RoyaltyInfoSet(_recipients[i], _percentages[i]);
         }
         require(totalPercentage <= 10000, "Total percentage exceeds 100%");
         // Remaining percentage can go to the contract owner or burn
    }

    /**
     * @dev (Conceptual) Represents receiving royalties from an external source (e.g., NFT marketplace sale).
     * This function would typically be called by a trusted oracle or linked NFT contract.
     * It then distributes the received amount based on the `royaltyRecipients` info.
     * @param _amount The amount of currency (e.g., ETH/WETH) received as royalty.
     * Note: This is a simplified example; handling tokens vs native currency, precision, and gas costs for many recipients is complex.
     */
     function distributeRoyalties(uint256 _amount) external {
        // This function would likely be called by a specific authorized address (e.g., the NFT contract owner or an oracle)
        // require(msg.sender == authorized_distributor, "Unauthorized caller");
        // For this example, let's make it callable but highlight it's conceptual
        require(currentPhase == CanvasPhase.Finalized, "Canvas must be finalized to distribute royalties");
        require(_amount > 0, "Amount must be greater than zero");

        uint256 totalDistributed = 0;
        uint256 totalBasisPoints = 10000; // 100%

        for (uint i = 0; i < royaltyRecipients.length; i++) {
            uint256 recipientShare = (_amount * royaltyRecipients[i].percentage) / totalBasisPoints;
            if (recipientShare > 0) {
                 // In a real scenario, use payable(recipient).transfer or .call.
                 // Transfer is safer against reentrancy for simple transfers.
                 // .call might be needed for token transfers or if recipient is a smart contract expecting gas.
                 // Using payable(recipient).transfer(recipientShare);
                 // However, for a conceptual demo, we'll just track totalDistributed.
                 // Reverting here to show this is a placeholder implementation.
                revert("Royalty distribution is conceptual and not fully implemented for transfers");
                // payable(royaltyRecipients[i].recipient).transfer(recipientShare); // This line is illustrative, would need careful reentrancy checks if implemented.
                totalDistributed += recipientShare;
            }
        }
        // Remaining amount (_amount - totalDistributed) could be sent to owner, burned, etc.
     }

    /**
     * @dev Returns a list of top contributors based on their reputation score.
     * Note: Iterating through all users in a mapping is not possible on-chain.
     * This function is a conceptual placeholder. A real implementation might
     * store contributors in a list and sort/filter off-chain, or use a
     * more complex on-chain data structure (like a balanced tree) which is very gas-expensive.
     * This version returns the first N contributors encountered in the `curators` list as a simple demo.
     */
    function getTopContributors(uint256 _count) external view returns (address[] memory) {
        // Cannot efficiently get top N from mapping.
        // Returning the list of curators as a placeholder for demonstrating returning an array of addresses.
        // A real system would need a different data structure or off-chain processing.
         uint256 numCurators = curators.length;
         uint256 returnCount = _count > numCurators ? numCurators : _count;
         address[] memory top = new address[](returnCount);
         for(uint i = 0; i < returnCount; i++) {
             top[i] = curators[i]; // Just returning first N curators as a stand-in
             // In a real scenario, you'd iterate through users and sort by reputation
         }
         return top;
    }
}
```