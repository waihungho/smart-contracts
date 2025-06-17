Okay, let's design a smart contract concept that is somewhat advanced and creative, focusing on dynamic assets and conditional access to data/features based on on-chain interactions and conditions.

**Concept: The "Chronicle Node"**

This smart contract will manage a type of ERC-721 NFT called a "Chronicle Node". Each Node is a unique digital asset that acts as a container for different "Segments" of data or potential features. These Segments are initially locked. They can only be unlocked when specific, predefined on-chain conditions are met by the NFT holder or through interactions involving the NFT. Once a Segment is unlocked for a specific Node, the holder gains access to the data associated with that Segment (which could be stored on-chain or referenced off-chain via IPFS hashes) or potentially unlocks a new property/trait for the Node.

This creates a dynamic, evolving asset where its value and utility increase as conditions are met, reflecting the owner's journey or the NFT's history within the ecosystem.

**Advanced Concepts Used:**

1.  **Dynamic/Conditional State:** The NFT's 'state' (which segments are unlocked) changes based on external conditions and user actions, not just simple transfers.
2.  **On-Chain Condition Evaluation:** The contract itself verifies complex conditions (time elapsed, interaction proofs, token holding duration, potentially checking external contract states or token balances/transfers).
3.  **Conditional Data Access:** Using `require` statements to gate access to sensitive or unlockable data/hashes associated with the NFT segments.
4.  **Proof-of-X Mechanics:** Implementing logic for "Proof-of-Interaction", "Proof-of-Holding Duration", "Proof-of-Contribution" (e.g., sending a token) tied to NFT ownership.
5.  **Epoch System:** Utilizing a time-based epoch system as one type of unlock condition.
6.  **Role-Based Access Control (Basic):** Using `onlyMinter` and `onlyOwner` (from Ownable).
7.  **Pausable Contract:** Adding a safety mechanism.

**Novelty Attempt:** While individual concepts like dynamic NFTs, timelocks, or interaction tracking exist, combining them into a single ERC-721 asset where the NFT itself acts as a key to *unlockable data segments* based on a variety of on-chain proofs and conditions, creating an evolving 'chronicle' of the asset's life, is a less common pattern compared to typical PFP or gaming NFTs whose dynamism is purely metadata/visuals. This focuses on *utility* and *information* unlock.

---

**Outline and Function Summary**

**Contract Name:** ChronicleNode

**Inherits:** ERC721, Ownable, Pausable

**Core Concept:** An ERC-721 NFT (`ChronicleNode`) that contains lockable data/feature `Segments`. These `Segments` are unlocked based on specific on-chain `Conditions` being met by the NFT holder or through interactions.

**State Variables:**

*   ERC721 standard state (name, symbol, token data).
*   Minter role management (`isMinter`).
*   Pausable state.
*   Epoch parameters (`epochStartTime`, `epochDuration`).
*   Counter for total defined segments (`segmentCounter`).
*   Mapping for segment definitions (`segmentDefinitions[segmentId] -> SegmentDefinition`).
*   Mapping for token's assigned segments (`tokenSegments[tokenId][segmentId] -> bool` - assigned or not).
*   Mapping for unlocked segments (`unlockedSegments[tokenId][segmentId] -> bool`).
*   Mapping to track interaction proofs (`interactionProofs[tokenId][contractAddress] -> bool`).
*   Mapping to track holding start time for `TokenHoldingDuration` condition (`tokenHoldingStartTime[tokenId] -> uint256`).
*   Mapping to define required ERC20 tokens for `ERC20Contribution` condition (`requiredERC20Tokens[tokenAddress] -> bool`).
*   Base URI for metadata.

**Enums:**

*   `ConditionType`: Defines the type of condition for segment unlock (e.g., `None`, `TimeElapsed`, `InteractionProven`, `TokenHoldingDuration`, `ERC20Contribution`).

**Structs:**

*   `SegmentCondition`: Defines the requirement to unlock a segment (`conditionType`, `value`, `targetAddress` - usage depends on type).
*   `SegmentDefinition`: Defines a type of segment (`condition`, `dataHash`, `description`).

**Events:**

*   `SegmentDefinitionAdded(uint256 indexed segmentId, ConditionType conditionType)`
*   `SegmentAddedToToken(uint256 indexed tokenId, uint256 indexed segmentId)`
*   `SegmentUnlocked(uint256 indexed tokenId, uint256 indexed segmentId, address indexed owner)`
*   `InteractionProven(uint256 indexed tokenId, address indexed contractAddress, address indexed prover)`
*   `EpochParametersSet(uint256 epochStartTime, uint256 epochDuration)`

**Function Summary (Min 20 total, including standard ERC721):**

**ERC-721 Standard (Public/External):**

1.  `balanceOf(address owner) view`: Get the balance of an owner.
2.  `ownerOf(uint256 tokenId) view`: Get the owner of a token.
3.  `approve(address to, uint256 tokenId)`: Approve an address to transfer a token.
4.  `getApproved(uint256 tokenId) view`: Get the approved address for a token.
5.  `setApprovalForAll(address operator, bool approved)`: Approve or revoke operator for all tokens.
6.  `isApprovedForAll(address owner, address operator) view`: Check if operator is approved for all tokens.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (unsafe).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer token (safe).
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
10. `tokenURI(uint256 tokenId) view override`: Get the metadata URI for a token. *Custom implementation to hint at unlocked segments.*

**Admin / Owner Functions (External):**

11. `addMinter(address minter)`: Add an address to the minter role. (Requires `onlyOwner`)
12. `removeMinter(address minter)`: Remove an address from the minter role. (Requires `onlyOwner`)
13. `setBaseURI(string memory baseURI_)`: Set the base URI for token metadata. (Requires `onlyOwner`)
14. `setEpochParameters(uint256 startTime, uint256 duration)`: Set the start time and duration of epochs. (Requires `onlyOwner`)
15. `pause()`: Pause the contract. (Requires `onlyOwner`, inherits from Pausable)
16. `unpause()`: Unpause the contract. (Requires `onlyOwner`, inherits from Pausable)
17. `addRequiredERC20Token(address tokenAddress)`: Designate an ERC20 token as valid for `ERC20Contribution` condition types. (Requires `onlyOwner`)
18. `removeRequiredERC20Token(address tokenAddress)`: Remove an ERC20 token from the list of required tokens. (Requires `onlyOwner`)
19. `withdrawERC20(address tokenAddress, address recipient, uint256 amount)`: Withdraw ERC20 tokens potentially sent for `ERC20Contribution`. (Requires `onlyOwner`)

**Core Logic Functions (External):**

20. `addSegmentDefinition(ConditionType conditionType, uint256 value, address targetAddress, string memory dataHash, string memory description)`: Define a new type of segment and its unlock condition. Returns the new segment ID. (Requires `onlyOwner`)
21. `addSegmentToExistingToken(uint256 tokenId, uint256 segmentId)`: Assign a pre-defined segment type to a specific existing token. (Requires `onlyOwner`)
22. `mintWithSegments(address to, uint256[] calldata initialSegmentIds)`: Mint a new Node token and assign a list of predefined segments to it initially. (Requires `onlyMinter`, `whenNotPaused`)
23. `attemptUnlockSegment(uint256 tokenId, uint256 segmentId)`: Callable by the token owner to attempt unlocking a specific segment. Checks if conditions are met. (Requires `onlyOwnerOfToken`, `whenNotPaused`)
24. `proveInteraction(uint256 tokenId, address contractAddress)`: Callable by the token owner or a designated contract to register an interaction proof for a token with a specific external contract. (Requires `onlyOwnerOfToken` or potentially a specific caller check if designed for external contracts, `whenNotPaused`)

**View Functions (Public/External):**

25. `checkSegmentUnlockStatus(uint256 tokenId, uint256 segmentId) view`: Check if a specific segment is currently unlocked for a token. (Public)
26. `getSegmentDataHash(uint256 segmentId) view`: Get the data hash associated with a segment definition (unlocked or not). (Public)
27. `getSegmentCondition(uint256 segmentId) view`: Get the unlock condition details for a segment definition. (Public)
28. `getUnlockedSegments(uint256 tokenId) view`: Get a list of all segment IDs currently unlocked for a token. (Requires `onlyOwnerOfToken` - *or make public to allow external verification? Let's make it public for broader utility.*)
29. `getTotalSegmentDefinitions() view`: Get the total number of defined segments. (Public)
30. `getEpochInfo() view`: Get the epoch start time and duration. (Public)
31. `getCurrentEpoch() view`: Calculate and return the current epoch number. (Public)
32. `getInteractionProof(uint256 tokenId, address contractAddress) view`: Check if an interaction proof exists for a token and contract. (Public)
33. `getHoldingStartTime(uint256 tokenId) view`: Get the timestamp when the current owner acquired the token. (Public)
34. `isMinter(address account) view`: Check if an address has the minter role. (Public)
35. `getSegmentData(uint256 tokenId, uint256 segmentId) view`: Get the actual data hash for a segment, *only if unlocked*. (Requires `onlyOwnerOfToken`, checks unlock status)

**Internal/Override Functions:**

*   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal override to track token holding start time.
*   Helper function(s) to evaluate different condition types within `attemptUnlockSegment`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For ERC20Contribution proof
import "@openzeppelin/contracts/utils/Address.sol"; // For isContract check if needed

// Outline and Function Summary:
// Contract Name: ChronicleNode
// Inherits: ERC721, Ownable, Pausable
// Core Concept: An ERC-721 NFT (`ChronicleNode`) that contains lockable data/feature `Segments`.
//               These `Segments` are unlocked based on specific on-chain `Conditions`
//               being met by the NFT holder or through interactions.
//
// State Variables:
// - ERC721 standard state.
// - Minter role management (`isMinter`).
// - Pausable state.
// - Epoch parameters (`epochStartTime`, `epochDuration`).
// - Counter for total defined segments (`segmentCounter`).
// - Mapping for segment definitions (`segmentDefinitions`).
// - Mapping for token's assigned segments (`tokenSegments`).
// - Mapping for unlocked segments (`unlockedSegments`).
// - Mapping to track interaction proofs (`interactionProofs`).
// - Mapping to track holding start time (`tokenHoldingStartTime`).
// - Mapping to define required ERC20 tokens for `ERC20Contribution` (`requiredERC20Tokens`).
// - Base URI for metadata.
//
// Enums:
// - ConditionType: Defines segment unlock requirement (None, TimeElapsed, InteractionProven, TokenHoldingDuration, ERC20Contribution).
//
// Structs:
// - SegmentCondition: Defines unlock condition (conditionType, value, targetAddress).
// - SegmentDefinition: Defines a segment type (condition, dataHash, description).
//
// Events:
// - SegmentDefinitionAdded, SegmentAddedToToken, SegmentUnlocked, InteractionProven, EpochParametersSet.
//
// Function Summary (35+ functions listed):
// - ERC-721 Standard (Public/External): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), tokenURI (override).
// - Admin / Owner Functions (External): addMinter, removeMinter, setBaseURI, setEpochParameters, pause, unpause, addRequiredERC20Token, removeRequiredERC20Token, withdrawERC20.
// - Core Logic Functions (External): addSegmentDefinition, addSegmentToExistingToken, mintWithSegments, attemptUnlockSegment, proveInteraction.
// - View Functions (Public/External): checkSegmentUnlockStatus, getSegmentDataHash, getSegmentCondition, getUnlockedSegments, getTotalSegmentDefinitions, getEpochInfo, getCurrentEpoch, getInteractionProof, getHoldingStartTime, isMinter, getSegmentData.
// - Internal/Override Functions: _beforeTokenTransfer (to track holding time), helper functions for condition evaluation.

contract ChronicleNode is ERC721, Ownable, Pausable {
    using Address for address;

    // --- State Variables ---

    // Role Management
    mapping(address => bool) private _isMinter;

    // Epoch System
    uint256 public epochStartTime;
    uint256 public epochDuration;

    // Segment Definitions
    enum ConditionType {
        None, // Segment is unlocked immediately upon assignment
        TimeElapsed, // Unlock after a certain number of epochs from mint/assignment time
        InteractionProven, // Unlock after proving interaction with a specific contract address
        TokenHoldingDuration, // Unlock after holding the token for a minimum duration
        ERC20Contribution // Unlock after sending a specific amount of a specific ERC20 token to this contract
    }

    struct SegmentCondition {
        ConditionType conditionType;
        uint256 value; // e.g., epoch count, duration in seconds, amount
        address targetAddress; // e.g., contract address, ERC20 token address
    }

    struct SegmentDefinition {
        SegmentCondition condition;
        string dataHash; // e.g., IPFS hash or link to off-chain data
        string description; // Human-readable description of the segment
    }

    SegmentDefinition[] private segmentDefinitions; // Using array for iteration, mapping for lookup is also an option but array fits definition flow
    uint256 private segmentCounter; // Acts as segment ID

    // Token State
    mapping(uint256 => mapping(uint256 => bool)) private tokenSegments; // tokenId -> segmentId -> assigned?
    mapping(uint256 => mapping(uint256 => bool)) private unlockedSegments; // tokenId -> segmentId -> unlocked?
    mapping(uint256 => mapping(address => bool)) private interactionProofs; // tokenId -> contractAddress -> proven?
    mapping(uint256 => uint256) private tokenHoldingStartTime; // tokenId -> timestamp of last owner change

    // ERC20 Contribution Proof
    mapping(address => bool) private requiredERC20Tokens; // List of approved ERC20s for the condition

    // Metadata
    string private _baseURI;

    // --- Events ---

    event SegmentDefinitionAdded(uint256 indexed segmentId, ConditionType conditionType);
    event SegmentAddedToToken(uint256 indexed tokenId, uint256 indexed segmentId);
    event SegmentUnlocked(uint256 indexed tokenId, uint256 indexed segmentId, address indexed owner);
    event InteractionProven(uint256 indexed tokenId, address indexed contractAddress, address indexed prover);
    event EpochParametersSet(uint256 epochStartTime, uint256 epochDuration);

    // --- Modifiers ---

    modifier onlyMinter() {
        require(_isMinter[msg.sender], "Not authorized as minter");
        _;
    }

    modifier onlyOwnerOfToken(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI_, address initialMinter)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseURI = baseURI_;
        _isMinter[initialMinter] = true;
        segmentCounter = 0; // Segment IDs start from 0
        epochStartTime = block.timestamp; // Default: start epoch 0 now
        epochDuration = 7 days; // Default: 7-day epochs
    }

    // --- ERC721 Standard Functions (Overrides) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // ERC721 standard check
        // This implementation is basic. A dynamic URI usually points to a service
        // that generates metadata based on on-chain state (like unlockedSegments).
        // This just provides the base URI + token ID. The off-chain service
        // would query the contract for unlock status etc.
        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return "";
        }
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // Internal override to track token holding time
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When a token is transferred, record the time the new owner (to) received it
        if (to != address(0)) { // Check needed for burning (to == address(0))
             // For batch transfers, we'd ideally track each, but standard ERC721 doesn't have batch
             // transfer hook with individual tokenIds usually. This is for single transfers.
            if (batchSize == 1) {
                 tokenHoldingStartTime[tokenId] = block.timestamp;
            }
            // Note: This simple tracking assumes single transfers. Batched transfers
            // would require a different approach or accepting this limitation.
        } else if (from != address(0)) {
            // Token is being burned, clear holding time
             delete tokenHoldingStartTime[tokenId];
        }
    }

    // --- Admin / Owner Functions ---

    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "Minter address cannot be zero");
        _isMinter[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        require(minter != address(0), "Minter address cannot be zero");
        _isMinter[minter] = false;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function setEpochParameters(uint256 startTime, uint256 duration) external onlyOwner {
        require(duration > 0, "Epoch duration must be positive");
        epochStartTime = startTime;
        epochDuration = duration;
        emit EpochParametersSet(startTime, duration);
    }

    function addRequiredERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress.isContract(), "Address is not a contract");
        requiredERC20Tokens[tokenAddress] = true;
    }

    function removeRequiredERC20Token(address tokenAddress) external onlyOwner {
        requiredERC20Tokens[tokenAddress] = false;
    }

    // Allows owner to sweep ERC20s sent for contributions
    function withdrawERC20(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(tokenAddress.isContract(), "Address is not a contract");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "Insufficient contract balance");
        require(recipient != address(0), "Recipient address cannot be zero");

        token.transfer(recipient, amount);
    }

    // --- Core Logic Functions ---

    function addSegmentDefinition(
        ConditionType conditionType,
        uint256 value,
        address targetAddress,
        string memory dataHash,
        string memory description
    ) external onlyOwner returns (uint256) {
        // Basic validation based on type
        if (conditionType == ConditionType.TimeElapsed && value == 0) revert("TimeElapsed requires value > 0");
        if (conditionType == ConditionType.InteractionProven && targetAddress == address(0)) revert("InteractionProven requires target address");
        if (conditionType == ConditionType.TokenHoldingDuration && value == 0) revert("TokenHoldingDuration requires value > 0");
        if (conditionType == ConditionType.ERC20Contribution) {
             require(value > 0, "ERC20Contribution requires value > 0");
             require(targetAddress.isContract() && requiredERC20Tokens[targetAddress], "ERC20Contribution requires valid & allowed token address");
        }

        segmentDefinitions.push(SegmentDefinition({
            condition: SegmentCondition({
                conditionType: conditionType,
                value: value,
                targetAddress: targetAddress
            }),
            dataHash: dataHash,
            description: description
        }));

        uint256 newSegmentId = segmentCounter;
        segmentCounter++;

        emit SegmentDefinitionAdded(newSegmentId, conditionType);

        return newSegmentId;
    }

    function addSegmentToExistingToken(uint256 tokenId, uint256 segmentId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(segmentId < segmentCounter, "Invalid segment ID");
        require(!tokenSegments[tokenId][segmentId], "Segment already assigned to token");

        tokenSegments[tokenId][segmentId] = true;

        // If condition is None, unlock immediately upon assignment
        if (segmentDefinitions[segmentId].condition.conditionType == ConditionType.None) {
            unlockedSegments[tokenId][segmentId] = true;
            emit SegmentUnlocked(tokenId, segmentId, ownerOf(tokenId));
        }

        emit SegmentAddedToToken(tokenId, segmentId);
    }

    function mintWithSegments(address to, uint256[] calldata initialSegmentIds) external onlyMinter whenNotPaused returns (uint256) {
        require(to != address(0), "Mint to address zero");

        uint256 newTokenId = totalSupply() + 1; // Simple ID assignment
        _safeMint(to, newTokenId);

        tokenHoldingStartTime[newTokenId] = block.timestamp; // Record initial holding time

        for (uint i = 0; i < initialSegmentIds.length; i++) {
            uint256 segmentId = initialSegmentIds[i];
            require(segmentId < segmentCounter, "Invalid initial segment ID");
            require(!tokenSegments[newTokenId][segmentId], "Duplicate initial segment ID"); // Should not happen with unique IDs

            tokenSegments[newTokenId][segmentId] = true;

            // Unlock segments with ConditionType.None immediately
            if (segmentDefinitions[segmentId].condition.conditionType == ConditionType.None) {
                unlockedSegments[newTokenId][segmentId] = true;
                emit SegmentUnlocked(newTokenId, segmentId, to);
            }

             emit SegmentAddedToToken(newTokenId, segmentId);
        }

        return newTokenId;
    }

    function attemptUnlockSegment(uint256 tokenId, uint256 segmentId) external onlyOwnerOfToken(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist"); // Should be covered by onlyOwnerOfToken but good practice
        require(segmentId < segmentCounter, "Invalid segment ID");
        require(tokenSegments[tokenId][segmentId], "Segment not assigned to token");
        require(!unlockedSegments[tokenId][segmentId], "Segment already unlocked");

        SegmentDefinition storage segmentDef = segmentDefinitions[segmentId];
        bool conditionsMet = false;

        if (segmentDef.condition.conditionType == ConditionType.TimeElapsed) {
            // Unlock after a specific number of epochs have passed since epoch 0 start
            uint256 requiredEpoch = segmentDef.condition.value;
            uint256 currentEpoch = getCurrentEpoch();
            if (currentEpoch >= requiredEpoch) {
                conditionsMet = true;
            }
        } else if (segmentDef.condition.conditionType == ConditionType.InteractionProven) {
            // Unlock if interaction with targetAddress is proven for this token
            address targetContract = segmentDef.condition.targetAddress;
            if (interactionProofs[tokenId][targetContract]) {
                conditionsMet = true;
            }
        } else if (segmentDef.condition.conditionType == ConditionType.TokenHoldingDuration) {
            // Unlock if the current owner has held the token for the required duration
            uint256 requiredDuration = segmentDef.condition.value;
            uint256 holdingStartTime = tokenHoldingStartTime[tokenId];
            if (holdingStartTime > 0 && block.timestamp >= holdingStartTime + requiredDuration) {
                conditionsMet = true;
            }
        } else if (segmentDef.condition.conditionType == ConditionType.ERC20Contribution) {
             // Unlock if the required amount of the specific ERC20 token has been sent to this contract
             // Note: This proof mechanism assumes the user sends the token *before* or *during*
             // this call. A more robust mechanism might use approve/transferFrom or
             // a separate 'contribute' function that updates a balance mapped to the token ID.
             // For this example, we'll assume the tokens are simply expected to be *in* the contract.
             // A better pattern would be:
             // 1. User calls `approve` on the ERC20 for this contract.
             // 2. User calls `attemptUnlockSegment` with `ERC20Contribution` type.
             // 3. Contract uses `transferFrom` to pull the required tokens.
             // We will implement the `transferFrom` pattern as it's more secure.

             address requiredTokenAddress = segmentDef.condition.targetAddress;
             uint256 requiredAmount = segmentDef.condition.value;
             IERC20 requiredToken = IERC20(requiredTokenAddress);

             // Require the user to have approved this contract to spend the tokens
             // And then transfer them from the user to the contract.
             // This ensures the contribution happens atomically with the unlock attempt.
             if (requiredToken.transferFrom(msg.sender, address(this), requiredAmount)) {
                 conditionsMet = true;
             } else {
                 revert("ERC20 contribution failed (check allowance/balance)");
             }

        } else if (segmentDef.condition.conditionType == ConditionType.None) {
            // Should have been unlocked on assignment, but handle defensively
            conditionsMet = true;
        }
        // Add more ConditionTypes here as needed

        if (conditionsMet) {
            unlockedSegments[tokenId][segmentId] = true;
            emit SegmentUnlocked(tokenId, segmentId, msg.sender);
        } else {
            // Optionally revert or emit an event for failed attempt
            revert("Conditions not met to unlock segment");
        }
    }

    function proveInteraction(uint256 tokenId, address contractAddress) external onlyOwnerOfToken(tokenId) whenNotPaused {
        require(contractAddress != address(0), "Contract address cannot be zero");
        // Prevent re-proving the same interaction? Depends on design. Let's allow it but only set the flag once.
        if (!interactionProofs[tokenId][contractAddress]) {
            interactionProofs[tokenId][contractAddress] = true;
            emit InteractionProven(tokenId, contractAddress, msg.sender);
        }
        // Note: This function *only* sets the proof flag. The actual unlocking
        // using this proof happens when `attemptUnlockSegment` is called
        // for a segment with `ConditionType.InteractionProven`.
    }

    // --- View Functions ---

    function checkSegmentUnlockStatus(uint256 tokenId, uint256 segmentId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        require(segmentId < segmentCounter, "Invalid segment ID");
        return unlockedSegments[tokenId][segmentId];
    }

    function getSegmentDataHash(uint256 segmentId) public view returns (string memory) {
        require(segmentId < segmentCounter, "Invalid segment ID");
        return segmentDefinitions[segmentId].dataHash;
    }

     // Conditional access to segment data hash
    function getSegmentData(uint256 tokenId, uint256 segmentId) public view onlyOwnerOfToken(tokenId) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        require(segmentId < segmentCounter, "Invalid segment ID");
        require(unlockedSegments[tokenId][segmentId], "Segment is not unlocked");

        return segmentDefinitions[segmentId].dataHash;
    }


    function getSegmentCondition(uint256 segmentId) public view returns (SegmentCondition memory) {
        require(segmentId < segmentCounter, "Invalid segment ID");
        return segmentDefinitions[segmentId].condition;
    }

    function getUnlockedSegments(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Token does not exist");

        uint256[] memory unlocked;
        uint256 count = 0;

        // Count unlocked segments
        for (uint256 i = 0; i < segmentCounter; i++) {
            if (tokenSegments[tokenId][i] && unlockedSegments[tokenId][i]) {
                count++;
            }
        }

        // Populate array
        unlocked = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < segmentCounter; i++) {
             if (tokenSegments[tokenId][i] && unlockedSegments[tokenId][i]) {
                unlocked[index] = i;
                index++;
            }
        }

        return unlocked;
    }

    function getTotalSegmentDefinitions() public view returns (uint256) {
        return segmentCounter;
    }

    function getEpochInfo() public view returns (uint256 startTime, uint256 duration) {
        return (epochStartTime, epochDuration);
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (epochDuration == 0) return 0; // Prevent division by zero
        if (block.timestamp < epochStartTime) return 0;
        return (block.timestamp - epochStartTime) / epochDuration;
    }

    function getInteractionProof(uint256 tokenId, address contractAddress) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
         require(contractAddress != address(0), "Contract address cannot be zero");
        return interactionProofs[tokenId][contractAddress];
    }

    function getHoldingStartTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenHoldingStartTime[tokenId];
    }

    function isMinter(address account) public view returns (bool) {
        return _isMinter[account];
    }

     function isRequiredERC20Token(address tokenAddress) public view returns (bool) {
        return requiredERC20Tokens[tokenAddress];
    }

    // --- Pausable Overrides ---
    function _update(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._update(from, to, tokenId);
    }

     // Need to override some ERC721 functions to add Pausable checks
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         super.safeTransferFrom(from, to, tokenId, data);
    }
}
```