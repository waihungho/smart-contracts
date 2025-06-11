Okay, let's design a smart contract that implements a decentralized, dynamic pixel canvas with ownership, pricing, referral, and governance features.

This concept combines elements of digital art ownership (though not a traditional ERC721 of the whole canvas), dynamic economics, and community interaction.

**Concept:**

"CryptoCanvas" is a fixed-size digital grid where users can buy, own, and color individual pixels (or small predefined blocks of pixels). The price of a pixel increases slightly with demand in its area. Owners can set a message or link for their pixels and transfer/sell them. A referral system rewards users who bring new buyers. The contract incorporates a simple governance mechanism where pixel owners can propose and vote on changes to contract parameters (like base price, referral percentage, or even triggering specific functions).

This is not a simple ERC721, ERC20, or standard marketplace. It's a unique state-changing contract with complex interactions.

---

**Outline and Function Summary:**

**I. Core Concept & Data Structures**
*   Represents a grid of pixels.
*   Each pixel has an owner, color, message, purchase history, and last update time.
*   Dynamic pricing based on pixel ID or area activity (simplified: based on total pixels bought).
*   Governance proposals affect contract parameters.

**II. State Variables**
*   `width`, `height`, `totalPixels`: Canvas dimensions and total pixel count.
*   `pixels`: Mapping storing data for each pixel ID (`uint256` key, `Pixel` struct value).
*   `basePixelPrice`, `priceIncreasePerPixel`: Economic parameters.
*   `referralPercentage`: Percentage of purchase price paid to referrer.
*   `referralEarnings`: Mapping to track pending earnings for referrers.
*   `proposals`, `proposalCount`: Governance state.
*   `proposalVoteWeight`: How vote weight is calculated (e.g., 1 pixel = 1 vote).
*   `canvasPaused`: Emergency pause switch.

**III. Structs**
*   `Pixel`: Data structure for each pixel (owner, color, message, purchasePrice, lastUpdated, referrer).
*   `Proposal`: Data structure for governance proposals (creator, description, callData, votesFor, votesAgainst, endTime, state).

**IV. Enums**
*   `ProposalState`: States a proposal can be in (Pending, Active, Succeeded, Failed, Executed, Defeated).

**V. Events**
*   `PixelPurchased`: Log pixel purchase.
*   `PixelColorChanged`: Log color update.
*   `PixelMessageChanged`: Log message update.
*   `PixelTransferred`: Log ownership transfer.
*   `PixelSoldBack`: Log pixel being sold back to the contract.
*   `ReferralClaimed`: Log referral earnings claim.
*   `ProposalCreated`: Log new governance proposal.
*   `Voted`: Log a vote on a proposal.
*   `ProposalExecuted`: Log successful execution of a proposal.
*   `CanvasPaused`, `CanvasUnpaused`: Log pause status changes.

**VI. Modifiers**
*   `whenNotPaused`: Function can only be called when canvas is not paused.
*   `isPixelOwner(uint256 pixelId)`: Checks if caller owns the pixel.
*   `pixelExists(uint256 pixelId)`: Checks if pixel ID is valid.
*   `onlyPixelOwnerVote`: Restricts governance voting to pixel owners.

**VII. Core Canvas Functions (Interacting with Pixels)**
1.  `constructor(uint256 _width, uint256 _height, uint256 _basePixelPrice, uint256 _priceIncreasePerPixel, uint256 _referralPercentage)`: Initializes canvas size, base price, price increase, and referral percentage.
2.  `buyPixel(uint256 pixelId, bytes3 color, string memory message, address referrer)`: Allows purchasing a specific pixel. Handles payment, price calculation, referrer rewards, updates pixel state.
3.  `buyPixels(uint256[] memory pixelIds, bytes3[] memory colors, string[] memory messages, address referrer)`: Allows purchasing multiple pixels in one transaction. (Requires matching array lengths).
4.  `changePixelColor(uint256 pixelId, bytes3 newColor)`: Allows an owner to change their pixel's color.
5.  `changePixelMessage(uint256 pixelId, string memory newMessage)`: Allows an owner to change their pixel's message.
6.  `transferPixel(uint256 pixelId, address recipient)`: Allows an owner to transfer pixel ownership to another address.
7.  `sellPixel(uint256 pixelId)`: Allows an owner to sell a pixel back to the contract (at a predetermined price or percentage of purchase price, e.g., 50%).
8.  `getPixelInfo(uint256 pixelId)`: Reads and returns the state of a specific pixel.
9.  `getPixelPrice(uint256 pixelId)`: Calculates and returns the current purchase price for a pixel. Price increases with `pixelsBoughtCount`.
10. `getPixelId(uint256 x, uint256 y)`: Helper function to get pixel ID from (x, y) coordinates.
11. `getCoordinates(uint256 pixelId)`: Helper function to get (x, y) coordinates from pixel ID.

**VIII. Referral System Functions**
12. `claimReferralEarnings()`: Allows a referrer to withdraw their accumulated earnings.
13. `getReferralEarnings(address user)`: Returns the pending referral earnings for a user.

**IX. Governance System Functions**
14. `createProposal(string memory description, address targetContract, bytes memory callData, uint256 votingPeriodSeconds)`: Allows pixel owners to create a governance proposal (description, target address, function call data, voting duration). Requires a minimum pixel ownership threshold (implied by `onlyPixelOwnerVote` or checked internally).
15. `voteOnProposal(uint256 proposalId, bool support)`: Allows pixel owners to cast votes on an active proposal. Vote weight is based on the number of pixels owned at the time of voting.
16. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal.
17. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal if it has passed the voting period and succeeded. Uses `call` to interact with the target contract (can be `address(this)` for contract parameter changes).
18. `getProposalInfo(uint256 proposalId)`: Returns detailed information about a proposal.
19. `getVoterVoteWeight(uint256 proposalId, address voter)`: Returns the vote weight an address cast on a proposal.
20. `getVoteCount(uint256 proposalId)`: Returns the current tally of votes for and against a proposal.

**X. Admin/Utility Functions (Initially Owner-only, potentially governance controlled)**
21. `setBasePixelPrice(uint256 newPrice)`: Updates the base price of a pixel. (Can be called via governance).
22. `setPriceIncreasePerPixel(uint256 newFactor)`: Updates the factor by which price increases. (Can be called via governance).
23. `setReferralPercentage(uint256 newPercentage)`: Updates the referral percentage. (Can be called via governance).
24. `pauseCanvasInteractions(bool paused)`: Pauses/unpauses core canvas interactions (`buyPixel`, `changeColor`, etc.) in emergency. (Initially owner, potentially governance).
25. `withdrawContractBalance(address recipient, uint256 amount)`: Allows withdrawing contract ETH. (Initially owner, potentially governance).
26. `getOwnedPixelCount(address owner)`: Returns the number of pixels owned by an address. (Requires iterating or maintaining a counter - let's maintain a counter for efficiency).
27. `getCanvasWidth()`: Returns the canvas width.
28. `getCanvasHeight()`: Returns the canvas height.
29. `getTotalPixels()`: Returns the total number of pixels.
30. `getContractBalance()`: Returns the contract's current Ether balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
// I. Core Concept & Data Structures: Decentralized pixel grid ownership with dynamic pricing, referrals, and governance.
//    - Each pixel has an owner, color, message, purchase history, last update, and referrer.
//    - Price increases based on total pixels bought.
//    - Governance proposals affect contract parameters via voting based on pixel ownership.
// II. State Variables: width, height, totalPixels, pixels, basePixelPrice, priceIncreasePerPixel,
//    referralPercentage, referralEarnings, proposals, proposalCount, proposalVoteWeight, canvasPaused.
// III. Structs: Pixel, Proposal.
// IV. Enums: ProposalState.
// V. Events: PixelPurchased, PixelColorChanged, PixelMessageChanged, PixelTransferred, PixelSoldBack,
//    ReferralClaimed, ProposalCreated, Voted, ProposalExecuted, CanvasPaused, CanvasUnpaused.
// VI. Modifiers: whenNotPaused, isPixelOwner, pixelExists, onlyPixelOwnerVote.
// VII. Core Canvas Functions (Interacting with Pixels):
//    1. constructor: Initializes canvas dimensions and parameters.
//    2. buyPixel: Purchase a single pixel. Handles payment, price, referrer.
//    3. buyPixels: Purchase multiple pixels in a batch.
//    4. changePixelColor: Change color of owned pixel.
//    5. changePixelMessage: Change message of owned pixel.
//    6. transferPixel: Transfer pixel ownership.
//    7. sellPixel: Sell pixel back to the contract.
//    8. getPixelInfo: Get data for a specific pixel.
//    9. getPixelPrice: Get current calculated price for a pixel.
//    10. getPixelId: Helper: (x, y) to ID.
//    11. getCoordinates: Helper: ID to (x, y).
// VIII. Referral System Functions:
//    12. claimReferralEarnings: Withdraw accumulated referral rewards.
//    13. getReferralEarnings: Check pending referral earnings.
// IX. Governance System Functions:
//    14. createProposal: Create a new governance proposal (executable call).
//    15. voteOnProposal: Vote on an active proposal (weighted by owned pixels).
//    16. getProposalState: Get the current state of a proposal.
//    17. executeProposal: Execute a successful proposal.
//    18. getProposalInfo: Get full details of a proposal.
//    19. getVoterVoteWeight: Get vote weight cast by a voter on a proposal.
//    20. getVoteCount: Get current tally of votes for/against a proposal.
// X. Admin/Utility Functions:
//    21. setBasePixelPrice: Update base price (via governance).
//    22. setPriceIncreasePerPixel: Update price increase factor (via governance).
//    23. setReferralPercentage: Update referral percentage (via governance).
//    24. pauseCanvasInteractions: Emergency pause (owner/governance).
//    25. withdrawContractBalance: Withdraw contract ETH (owner/governance).
//    26. getOwnedPixelCount: Get number of pixels owned by an address.
//    27. getCanvasWidth: Get canvas width.
//    28. getCanvasHeight: Get canvas height.
//    29. getTotalPixels: Get total pixels on canvas.
//    30. getContractBalance: Get contract's ETH balance.

contract CryptoCanvas is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---
    uint256 public immutable canvasWidth;
    uint256 public immutable canvasHeight;
    uint256 public immutable totalPixels;
    uint256 private pixelsBoughtCount; // Counter for dynamic pricing

    struct Pixel {
        address owner;
        bytes3 color; // Stored as 3 bytes (R, G, B)
        string message;
        uint256 purchasePrice; // Price paid in wei
        uint256 lastUpdated;
        address referrer; // Address that referred the buyer
    }

    mapping(uint256 => Pixel) public pixels; // pixelId => Pixel

    uint256 public basePixelPrice; // wei
    uint256 public priceIncreasePerPixel; // wei increase per pixel bought
    uint256 public referralPercentage; // percentage * 100 (e.g., 500 for 5%)

    mapping(address => uint256) public referralEarnings; // referrer => pending earnings in wei

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Defeated }

    struct Proposal {
        address creator;
        string description;
        address targetContract; // Contract to call (can be address(this))
        bytes callData;       // Data for the call (function selector + arguments)
        uint256 votingPeriodEnd; // Unix timestamp
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted; // Address => Has Voted? (1 address = 1 vote currently)
        mapping(address => uint256) voterPixelCount; // Snapshot of pixels owned at vote time
        ProposalState state;
        uint256 creationTime;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public minPixelsForProposal; // Minimum owned pixels to create a proposal
    uint256 public votingPeriodDuration; // Default voting period duration in seconds
    uint256 public proposalExecutionDelay; // Delay after voting ends before execution is possible
    uint256 public quorumPercentage; // Percentage of total possible vote weight required for quorum * 100

    bool public canvasPaused = false; // Emergency pause

    mapping(address => uint256) private ownedPixelCount; // Track pixel count per owner

    // --- Events ---
    event PixelPurchased(uint256 indexed pixelId, address indexed owner, bytes3 color, string message, uint256 price, address referrer);
    event PixelColorChanged(uint256 indexed pixelId, bytes3 newColor);
    event PixelMessageChanged(uint256 indexed pixelId, string newMessage);
    event PixelTransferred(uint256 indexed pixelId, address indexed from, address indexed to);
    event PixelSoldBack(uint256 indexed pixelId, address indexed owner, uint256 priceReceived);
    event ReferralClaimed(address indexed referrer, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 votingPeriodEnd);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event CanvasPaused(address indexed by);
    event CanvasUnpaused(address indexed by);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!canvasPaused, "Canvas is paused");
        _;
    }

    modifier isPixelOwner(uint256 pixelId) {
        require(pixels[pixelId].owner == msg.sender, "Not pixel owner");
        _;
    }

    modifier pixelExists(uint256 pixelId) {
        require(pixelId < totalPixels, "Pixel ID out of bounds");
        _;
    }

     modifier onlyPixelOwnerVote() {
        require(ownedPixelCount[msg.sender] > 0, "Must own pixels to vote");
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _width,
        uint256 _height,
        uint256 _basePixelPrice,
        uint256 _priceIncreasePerPixel,
        uint256 _referralPercentage,
        uint256 _minPixelsForProposal,
        uint256 _votingPeriodDuration,
        uint256 _proposalExecutionDelay,
        uint256 _quorumPercentage
    )
        Ownable(msg.sender)
    {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        require(_referralPercentage <= 10000, "Referral percentage too high (max 100%)"); // 100 * 100 = 10000
        require(_quorumPercentage <= 10000, "Quorum percentage too high (max 100%)"); // 100 * 100 = 10000

        canvasWidth = _width;
        canvasHeight = _height;
        totalPixels = _width.mul(_height);

        basePixelPrice = _basePixelPrice;
        priceIncreasePerPixel = _priceIncreasePerPixel;
        referralPercentage = _referralPercentage; // e.g., 500 for 5%

        minPixelsForProposal = _minPixelsForProposal;
        votingPeriodDuration = _votingPeriodDuration;
        proposalExecutionDelay = _proposalExecutionDelay;
        quorumPercentage = _quorumPercentage; // e.g., 4000 for 40%
    }

    // --- Core Canvas Functions ---

    // 2. buyPixel
    function buyPixel(uint256 pixelId, bytes3 color, string memory message, address referrer)
        public
        payable
        whenNotPaused
        pixelExists(pixelId)
    {
        Pixel storage pixel = pixels[pixelId];
        require(pixel.owner == address(0), "Pixel already owned"); // Only buy unowned pixels

        uint256 currentPrice = getPixelPrice(pixelId);
        require(msg.value >= currentPrice, "Insufficient ETH sent");

        // Handle payment and refund excess
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        // Handle referral
        address actualReferrer = address(0);
        if (referrer != address(0) && referrer != msg.sender) {
             // Basic check: referrer must own at least 1 pixel? Or just any address?
             // Let's allow any address as referrer for simplicity, but earnings only accrue here.
            uint256 referralAmount = currentPrice.mul(referralPercentage).div(10000);
            if (referralAmount > 0) {
                 referralEarnings[referrer] = referralEarnings[referrer].add(referralAmount);
                 actualReferrer = referrer; // Record actual referrer if valid
            }
        }

        // Update pixel state
        pixel.owner = msg.sender;
        pixel.color = color;
        pixel.message = message;
        pixel.purchasePrice = currentPrice; // Record price paid
        pixel.lastUpdated = block.timestamp;
        pixel.referrer = actualReferrer; // Store the actual referrer

        pixelsBoughtCount = pixelsBoughtCount.add(1);
        ownedPixelCount[msg.sender] = ownedPixelCount[msg.sender].add(1);

        emit PixelPurchased(pixelId, msg.sender, color, message, currentPrice, actualReferrer);
    }

    // 3. buyPixels (Batch Purchase)
    function buyPixels(uint256[] memory pixelIds, bytes3[] memory colors, string[] memory messages, address referrer)
        public
        payable
        whenNotPaused
    {
        require(pixelIds.length > 0, "No pixels provided");
        require(pixelIds.length == colors.length, "Pixel ID and color array length mismatch");
        require(pixelIds.length == messages.length, "Pixel ID and message array length mismatch");

        uint256 totalPrice = 0;
        uint256[] memory purchasedIds = new uint256[](pixelIds.length);
        bytes3[] memory purchasedColors = new bytes3[](pixelIds.length);
        string[] memory purchasedMessages = new string[](pixelIds.length);
        uint256 purchasedCount = 0;

        for (uint i = 0; i < pixelIds.length; i++) {
             uint256 pixelId = pixelIds[i];
             require(pixelId < totalPixels, "Pixel ID out of bounds in batch");
             Pixel storage pixel = pixels[pixelId];
             require(pixel.owner == address(0), string(abi.encodePacked("Pixel ", uint2str(pixelId), " already owned"))); // Fail entire batch if any pixel is owned

             uint256 currentPrice = getPixelPrice(pixelId);
             totalPrice = totalPrice.add(currentPrice);

             purchasedIds[purchasedCount] = pixelId;
             purchasedColors[purchasedCount] = colors[i];
             purchasedMessages[purchasedCount] = messages[i];
             purchasedCount++;
        }

        require(msg.value >= totalPrice, "Insufficient ETH sent for batch purchase");

        // Handle payment and refund excess
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

         // Handle referral for the batch's total price
        address actualReferrer = address(0);
        if (referrer != address(0) && referrer != msg.sender) {
            uint256 referralAmount = totalPrice.mul(referralPercentage).div(10000);
            if (referralAmount > 0) {
                 referralEarnings[referrer] = referralEarnings[referrer].add(referralAmount);
                 actualReferrer = referrer; // Record actual referrer if valid
            }
        }

        // Update pixel states and emit events
        for (uint i = 0; i < purchasedCount; i++) {
            uint256 pixelId = purchasedIds[i];
            Pixel storage pixel = pixels[pixelId];

            pixel.owner = msg.sender;
            pixel.color = purchasedColors[i];
            pixel.message = purchasedMessages[i];
            pixel.purchasePrice = getPixelPrice(pixelId); // Recalculate price just before setting, or use the total batch price proportionally?
                                                          // Using the price calculated *before* the batch purchase is simpler.
            pixel.lastUpdated = block.timestamp;
            pixel.referrer = actualReferrer;

            pixelsBoughtCount = pixelsBoughtCount.add(1); // Increment for each pixel
            ownedPixelCount[msg.sender] = ownedPixelCount[msg.sender].add(1);

            emit PixelPurchased(pixelId, msg.sender, pixel.color, pixel.message, pixel.purchasePrice, actualReferrer); // Note: Emitting individual price here, not total share.
        }
    }


    // 4. changePixelColor
    function changePixelColor(uint256 pixelId, bytes3 newColor)
        public
        whenNotPaused
        pixelExists(pixelId)
        isPixelOwner(pixelId)
    {
        Pixel storage pixel = pixels[pixelId];
        pixel.color = newColor;
        pixel.lastUpdated = block.timestamp;
        emit PixelColorChanged(pixelId, newColor);
    }

    // 5. changePixelMessage
    function changePixelMessage(uint256 pixelId, string memory newMessage)
        public
        whenNotPaused
        pixelExists(pixelId)
        isPixelOwner(pixelId)
    {
        Pixel storage pixel = pixels[pixelId];
        pixel.message = newMessage;
        pixel.lastUpdated = block.timestamp;
        emit PixelMessageChanged(pixelId, newMessage);
    }

    // 6. transferPixel
    function transferPixel(uint256 pixelId, address recipient)
        public
        whenNotPaused
        pixelExists(pixelId)
        isPixelOwner(pixelId)
    {
        require(recipient != address(0), "Cannot transfer to zero address");

        Pixel storage pixel = pixels[pixelId];
        address previousOwner = pixel.owner;

        pixel.owner = recipient;
        ownedPixelCount[previousOwner] = ownedPixelCount[previousOwner].sub(1);
        ownedPixelCount[recipient] = ownedPixelCount[recipient].add(1);
        pixel.lastUpdated = block.timestamp; // Transfer counts as an update

        emit PixelTransferred(pixelId, previousOwner, recipient);
    }

    // 7. sellPixel
    // Simple sell back: receive a fixed percentage of purchase price or a fixed amount
    function sellPixel(uint256 pixelId)
        public
        whenNotPaused
        pixelExists(pixelId)
        isPixelOwner(pixelId)
    {
        Pixel storage pixel = pixels[pixelId];
        address currentOwner = pixel.owner;

        // Example: Sell back for 50% of original purchase price
        uint256 refundAmount = pixel.purchasePrice.div(2);

        // Clear pixel state
        pixel.owner = address(0); // Mark as unowned
        pixel.color = bytes3(0);   // Reset color
        pixel.message = "";        // Reset message
        pixel.purchasePrice = 0;   // Reset price
        pixel.lastUpdated = block.timestamp; // Update timestamp
        pixel.referrer = address(0); // Clear referrer

        ownedPixelCount[currentOwner] = ownedPixelCount[currentOwner].sub(1);

        // Transfer ETH back to the seller
        if (refundAmount > 0) {
            payable(currentOwner).transfer(refundAmount);
        }

        // Note: pixelsBoughtCount is NOT decreased, price continues to rise based on total history
        emit PixelSoldBack(pixelId, currentOwner, refundAmount);
    }

    // 8. getPixelInfo
    function getPixelInfo(uint256 pixelId)
        public
        view
        pixelExists(pixelId)
        returns (address owner, bytes3 color, string memory message, uint256 purchasePrice, uint256 lastUpdated, address referrer)
    {
        Pixel storage pixel = pixels[pixelId];
        return (pixel.owner, pixel.color, pixel.message, pixel.purchasePrice, pixel.lastUpdated, pixel.referrer);
    }

    // 9. getPixelPrice - Dynamic pricing based on total pixels ever bought
    function getPixelPrice(uint256 pixelId)
        public
        view
        pixelExists(pixelId)
        returns (uint256)
    {
         // Prevent issues if called before any pixels are bought, or on an owned pixel.
         // The dynamic part is based on the history of the canvas, not the pixel itself.
        return basePixelPrice.add(pixelsBoughtCount.mul(priceIncreasePerPixel));
    }

    // 10. getPixelId - Helper
    function getPixelId(uint256 x, uint256 y)
        public
        view
        returns (uint256)
    {
        require(x < canvasWidth && y < canvasHeight, "Coordinates out of bounds");
        return y.mul(canvasWidth).add(x);
    }

    // 11. getCoordinates - Helper
    function getCoordinates(uint256 pixelId)
        public
        view
        pixelExists(pixelId)
        returns (uint256 x, uint256 y)
    {
        y = pixelId.div(canvasWidth);
        x = pixelId.mod(canvasWidth);
        return (x, y);
    }

    // --- Referral System Functions ---

    // 12. claimReferralEarnings
    function claimReferralEarnings() public {
        uint256 earnings = referralEarnings[msg.sender];
        require(earnings > 0, "No referral earnings to claim");

        referralEarnings[msg.sender] = 0; // Reset earnings BEFORE transfer to prevent reentrancy
        payable(msg.sender).transfer(earnings);

        emit ReferralClaimed(msg.sender, earnings);
    }

    // 13. getReferralEarnings
    function getReferralEarnings(address user) public view returns (uint256) {
        return referralEarnings[user];
    }

    // --- Governance System Functions ---

    // 14. createProposal
    function createProposal(
        string memory description,
        address targetContract,
        bytes memory callData,
        uint256 votingPeriodSeconds
    ) public onlyPixelOwnerVote returns (uint256 proposalId) {
        require(ownedPixelCount[msg.sender] >= minPixelsForProposal, "Insufficient pixels to create proposal");
        require(votingPeriodSeconds > 0, "Voting period must be positive");

        proposalId = proposalCount;
        proposals[proposalId].creator = msg.sender;
        proposals[proposalId].description = description;
        proposals[proposalId].targetContract = targetContract;
        proposals[proposalId].callData = callData;
        proposals[proposalId].creationTime = block.timestamp;
        proposals[proposalId].votingPeriodEnd = block.timestamp.add(votingPeriodSeconds);
        proposals[proposalId].state = ProposalState.Active;

        proposalCount++;

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].votingPeriodEnd);
    }

    // 15. voteOnProposal
    function voteOnProposal(uint256 proposalId, bool support) public onlyPixelOwnerVote {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        uint256 voterWeight = ownedPixelCount[msg.sender];
        require(voterWeight > 0, "Voter must own pixels"); // Redundant due to modifier, but safe

        proposal.voted[msg.sender] = true;
        proposal.voterPixelCount[msg.sender] = voterWeight; // Store vote weight snapshot

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterWeight);
        }

        emit Voted(proposalId, msg.sender, support, voterWeight);
    }

    // 16. getProposalState
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check if voting period ended for Active proposals and update state if needed
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingPeriodEnd) {
            uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
             // Quorum is based on total *possible* vote weight (total pixels)
            uint256 requiredQuorumVotes = totalPixels.mul(quorumPercentage).div(10000);

            if (totalVotes < requiredQuorumVotes) {
                return ProposalState.Defeated; // Did not meet quorum
            } else if (proposal.votesFor > proposal.votesAgainst) {
                 // Check execution delay
                if (block.timestamp >= proposal.votingPeriodEnd.add(proposalExecutionDelay)) {
                    return ProposalState.Succeeded; // Passed and ready for execution
                } else {
                    return ProposalState.Active; // Passed, but still in execution delay
                }
            } else {
                return ProposalState.Defeated; // Did not get more votes For than Against
            }
        }
        return proposal.state; // Return current state or Active if still voting
    }

    // 17. executeProposal
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal is not in Succeeded state or not ready for execution");

        proposal.state = ProposalState.Executing; // Prevent re-execution

        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);

        if (success) {
            proposal.state = ProposalState.Executed;
        } else {
            proposal.state = ProposalState.Failed;
        }

        emit ProposalExecuted(proposalId, success, result);
        require(success, "Proposal execution failed");
    }

    // 18. getProposalInfo
    function getProposalInfo(uint256 proposalId)
        public
        view
        returns (
            address creator,
            string memory description,
            address targetContract,
            bytes memory callData,
            uint256 creationTime,
            uint256 votingPeriodEnd,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state
        )
    {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.creator,
            proposal.description,
            proposal.targetContract,
            proposal.callData,
            proposal.creationTime,
            proposal.votingPeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            getProposalState(proposalId) // Get calculated state
        );
    }

    // 19. getVoterVoteWeight
    function getVoterVoteWeight(uint256 proposalId, address voter) public view returns (uint256) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        return proposals[proposalId].voterPixelCount[voter];
    }

    // 20. getVoteCount
     function getVoteCount(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }


    // --- Admin/Utility Functions ---

    // 21. setBasePixelPrice (Intended to be called via governance)
    function setBasePixelPrice(uint256 newPrice) public onlyOwner {
        basePixelPrice = newPrice;
    }

    // 22. setPriceIncreasePerPixel (Intended to be called via governance)
    function setPriceIncreasePerPixel(uint256 newFactor) public onlyOwner {
        priceIncreasePerPixel = newFactor;
    }

    // 23. setReferralPercentage (Intended to be called via governance)
    function setReferralPercentage(uint256 newPercentage) public onlyOwner {
         require(newPercentage <= 10000, "Referral percentage too high (max 100%)");
        referralPercentage = newPercentage;
    }

    // 24. pauseCanvasInteractions (Emergency, owner callable)
    function pauseCanvasInteractions(bool paused) public onlyOwner {
        canvasPaused = paused;
        if (paused) {
            emit CanvasPaused(msg.sender);
        } else {
            emit CanvasUnpaused(msg.sender);
        }
    }

    // 25. withdrawContractBalance (Owner callable, potentially governance)
    function withdrawContractBalance(address recipient, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(recipient).transfer(amount);
    }

    // 26. getOwnedPixelCount
    function getOwnedPixelCount(address owner) public view returns (uint256) {
        return ownedPixelCount[owner];
    }

    // 27. getCanvasWidth
    function getCanvasWidth() public view returns (uint256) {
        return canvasWidth;
    }

    // 28. getCanvasHeight
     function getCanvasHeight() public view returns (uint256) {
        return canvasHeight;
    }

    // 29. getTotalPixels
    function getTotalPixels() public view returns (uint256) {
        return totalPixels;
    }

    // 30. getContractBalance
     function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal/Helper Functions ---

    // Simple int to string conversion for error messages (can be replaced by library)
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // Fallback/Receive to accept ETH (e.g., direct transfers)
    receive() external payable {
        // Optional: Log direct transfers or add logic if direct deposits are meaningful
    }

    fallback() external payable {
        // Optional: Handle calls to undefined functions
    }
}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Pixel Ownership & State:** Instead of minting standard tokens (like ERC721 for each pixel), the contract manages the state (owner, color, message) of a fixed set of "virtual" pixels on a grid. Ownership is recorded directly in the pixel struct. This is a different paradigm than typical token standards.
2.  **Dynamic Pricing:** The price of buying a new pixel isn't fixed or set by the owner. It increases incrementally based on the *total number of pixels ever bought* on the canvas. This creates a scarcity/demand curve for new placements on the canvas itself.
3.  **Referral System:** A built-in mechanism rewards users who introduce new buyers to the canvas by giving them a percentage of the purchase price. Earnings accumulate and can be claimed. This encourages growth and community building directly through the contract's economics.
4.  **On-chain Governance:** Pixel owners gain voting power proportional to the number of pixels they own. They can propose changes to contract parameters (base price, referral percentage, etc.) and vote on them. Successful proposals can execute arbitrary calls (with the power to even call functions within the contract itself via `address(this)`), making the contract potentially upgradeable or configurable by its users over time (within the defined proposal execution logic). This moves away from absolute owner control towards decentralized decision-making.
5.  **State Storage:** The contract stores a significant amount of state (`pixels` mapping with structs) directly on-chain, representing the canvas. While impractical for extremely large canvases (due to gas costs for read/write and storage limits), it's a core part of the concept. Getting the *entire* canvas state would require external tools, but reading individual pixels or small batches is supported.
6.  **Batching:** The `buyPixels` function allows for purchasing multiple pixels in a single transaction, which is more gas-efficient than buying them one by one on chains like Ethereum L1.
7.  **Vote Weight Snapshot:** In the `voteOnProposal` function, the voter's pixel count is snapshotted (`voterPixelCount`). This is crucial so that selling pixels *after* voting doesn't decrease their vote weight for that specific proposal.

This contract is a unique blend of NFT-like ownership (of digital property), DeFi economics (dynamic pricing, yield/referrals), and DAO governance. It's more complex than a simple token or marketplace and incorporates several advanced concepts not typically found together in standard open-source templates.

**Note:** This is a complex contract. Deploying and running this on a live network requires thorough testing, security audits, and consideration of gas costs, especially for larger canvases or batch operations. The governance `callData` feature is powerful and needs careful design regarding what functions can be targeted and executed for security. The current implementation allows calling *any* function on the target contract, which is flexible but risky; in a production system, you'd likely want a whitelist of approved functions or contract addresses callable via governance.