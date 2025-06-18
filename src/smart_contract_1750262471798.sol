Okay, let's design a complex, creative, and non-standard NFT smart contract.

**Concept:** QuantumTunnelNFT - NFTs that can be 'tunneled' through different quantum dimensions. This process is risky, uses external randomness, might require other assets as 'catalysts', changes the NFT's properties dynamically, and can even result in a completely new NFT or transformation.

**Advanced Concepts Used:**

1.  **Dynamic NFTs:** Token metadata and properties (`dimension`, `stability`, `quantumSignature`, bonded catalysts) change based on on-chain actions (`initiateTunnel`, `reinforceStability`, `bondCatalyst`, `fulfillRandomWords`).
2.  **Composable Assets:** NFTs can have other ERC721, ERC1155, and ERC20 tokens 'bonded' to them, acting as catalysts for the tunneling process or affecting outcomes.
3.  **External Randomness:** Integration with Chainlink VRF for unpredictable tunneling outcomes.
4.  **Time-based Mechanics:** A global `quantumEpoch` that influences tunneling costs and outcomes.
5.  **Stateful Mechanics:** A global `tunnelStabilityIndex` that changes based on tunneling volume/success/failure, affecting all future tunnels.
6.  **Burning with Potential Outcome:** While not strictly 'burning with effect' in the sense of creating *new* tokens on burn, the process of tunneling can *consume* the original NFT and output something *else*, which is a form of transformative burning.
7.  **Complex Outcome Logic:** The `fulfillRandomWords` function contains sophisticated logic determining the result of a tunnel attempt based on multiple input variables (randomness, NFT state, catalysts, global state).

---

**Outline and Function Summary:**

*   **Contract Name:** `QuantumTunnelNFT`
*   **Description:** An ERC721-compliant contract where NFTs represent entities capable of "quantum tunneling" across dimensions. Tunneling is a risky process influenced by randomness, bonded catalysts, the current quantum epoch, and global tunnel stability. Outcomes can range from successful dimension shifts and property changes to instability or even transformation into a new NFT.
*   **Core Concepts:** Dynamic NFT state, composable bonding, Chainlink VRF for outcomes, time-based epochs, global state influence.
*   **Inheritances:** ERC721Enumerable, Ownable, VRFConsumerBaseV2
*   **Events:**
    *   `QuantumTunnelInitiated(uint256 indexed tokenId, uint64 indexed requestId, address indexed initiator)`: Fired when a tunnel process starts.
    *   `QuantumTunnelOutcome(uint256 indexed tokenId, uint64 indexed requestId, uint256 indexed outcomeType, string outcomeDescription)`: Fired when VRF fulfills and tunnel outcome is processed.
    *   `NFTDimensionShift(uint256 indexed tokenId, uint256 oldDimension, uint256 newDimension)`: Fired when an NFT's dimension changes.
    *   `NFTStabilityChange(uint256 indexed tokenId, int256 stabilityDelta, int256 newStability)`: Fired when an NFT's stability changes.
    *   `CatalystBonded(uint256 indexed tokenId, uint256 indexed bondId, address indexed bondAddress, uint256 bondIdentifierOrAmount, uint8 bondType)`: Fired when a catalyst is bonded.
    *   `CatalystUnbonded(uint256 indexed tokenId, uint256 indexed bondId, address indexed bondAddress, uint256 bondIdentifierOrAmount, uint8 bondType)`: Fired when a catalyst is unbonded.
    *   `QuantumEpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch)`: Fired when the global quantum epoch changes.
    *   `TunnelStabilityIndexChanged(int256 indexed oldIndex, int256 indexed newIndex)`: Fired when the global tunnel stability index changes.
    *   `NewNFTGeneratedViaTunnel(uint256 indexed parentTokenId, uint256 indexed newTokenId)`: Fired when a tunnel outcome results in a new NFT.
*   **State Variables:**
    *   `_nextTokenId`: Counter for unique token IDs.
    *   `tokenData`: Mapping from tokenId to `TokenData` struct (dimension, stability, signature, bonded catalysts list).
    *   `bondedCatalysts`: Mapping from tokenId to list of `BondedCatalyst` structs.
    *   `bondedCatalystCounter`: Counter for unique bond IDs per NFT.
    *   `vrfRequests`: Mapping from VRF `requestId` to the `tokenId` that initiated the tunnel.
    *   `s_vrfCoordinator`, `s_keyHash`, `s_subscriptionId`, `s_callbackGasLimit`, `s_requestConfirmations`, `s_numWords`: VRF configuration.
    *   `tunnelFee`: ETH cost to initiate a tunnel.
    *   `baseTokenURI`: Base URI for metadata resolution.
    *   `currentQuantumEpoch`: Global counter for the current era.
    *   `epochAdvanceThreshold`: Time duration or event count after which epoch *can* advance.
    *   `lastEpochAdvanceTime`: Timestamp of the last epoch change.
    *   `tunnelStabilityIndex`: Global index affecting tunnel outcomes (can be positive/negative).
    *   `tunnelCountInEpoch`: Counter for tunnels within the current epoch.
    *   `catalystRequirement`: Configuration for mandatory catalysts (address, type).
    *   `isTunnelingPaused`: Global pause flag for tunneling.
*   **Structs/Enums:**
    *   `BondType`: Enum { ERC20, ERC721, ERC1155 }
    *   `BondedCatalyst`: Struct { BondType bondType; address contractAddress; uint256 identifierOrAmount; uint256 bondId; }
    *   `TokenData`: Struct { uint256 dimension; int256 stability; bytes32 quantumSignature; uint256[] bondedBondIds; }
*   **Functions:**
    1.  `constructor(address vrfCoordinator, uint64 subId, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords, string memory name, string memory symbol)`: Initializes VRF, ERC721, and Ownable.
    2.  `supportsInterface(bytes4 interfaceId) view returns (bool)`: ERC165 compliance.
    3.  `tokenURI(uint256 tokenId) view returns (string memory)`: Returns dynamic metadata URI.
    4.  `balanceOf(address owner) view returns (uint256)`: ERC721 standard.
    5.  `ownerOf(uint256 tokenId) view returns (address)`: ERC721 standard.
    6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
    7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard.
    8.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
    9.  `approve(address to, uint256 tokenId)`: ERC721 standard.
    10. `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
    11. `getApproved(uint256 tokenId) view returns (address operator)`: ERC721 standard.
    12. `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC721 standard.
    13. `totalSupply() view returns (uint256)`: ERC721Enumerable standard.
    14. `tokenByIndex(uint256 index) view returns (uint256)`: ERC721Enumerable standard.
    15. `tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)`: ERC721Enumerable standard.
    16. `mintInitialBatch(address[] memory recipients, uint256 initialDimension, int256 initialStability) onlyOwner`: Mints the initial set of NFTs with starting properties.
    17. `initiateTunnel(uint256 tokenId) payable whenNotPaused`: Allows an owner to pay a fee and initiate a quantum tunnel process for their NFT, requesting VRF randomness. Requires catalyst(s) if configured. Burns bonded mandatory catalysts upon initiation.
    18. `fulfillRandomWords(uint64 requestId, uint256[] memory randomWords) internal override`: VRF callback. Processes the random outcome for the corresponding tunnel request, modifies the NFT's state, potentially mints a new NFT, and updates global state.
    19. `bondCatalyst(uint256 tokenId, BondType bondType, address catalystContract, uint256 identifierOrAmount)`: Allows an NFT owner to bond another ERC20/721/1155 token to their NFT. Requires prior approval (`approve` for ERC20/721, `setApprovalForAll` or `approve` for ERC1155).
    20. `unbondCatalyst(uint256 tokenId, uint256 bondId)`: Allows an NFT owner to unbond a catalyst they previously bonded. Transfers the catalyst back. May have conditions (e.g., cannot unbond if mandatory catalyst used in tunnel).
    21. `getTokenData(uint256 tokenId) view returns (uint256 dimension, int256 stability, bytes32 quantumSignature, BondedCatalyst[] memory bonded)`: View function to retrieve an NFT's specific dynamic data.
    22. `assessStability(uint256 tokenId) view returns (int256 currentStability)`: Simple alias/wrapper for getting stability.
    23. `reinforceStability(uint256 tokenId) payable whenNotPaused`: Allows owner to pay ETH or use specific tokens (if configured) to increase their NFT's stability score, mitigating tunnel risks.
    24. `setBaseTokenURI(string memory uri) onlyOwner`: Sets the base URI for metadata resolution.
    25. `setTunnelFee(uint256 fee) onlyOwner`: Sets the ETH cost for initiating a tunnel.
    26. `setCatalystRequirement(BondType bondType, address catalystContract, uint256 identifierOrAmount, bool isMandatory) onlyOwner`: Configures a specific catalyst requirement for tunneling (e.g., requires bonding a specific ERC20 or NFT). `isMandatory` means it's consumed on tunnel initiation.
    27. `triggerQuantumEpochAdvance() onlyOwner`: Allows the owner to manually advance the quantum epoch (perhaps based on time/event checks in a real scenario). Resets `tunnelCountInEpoch`.
    28. `getTunnelConfig() view returns (uint256 fee, address catalystAddress, uint256 catalystIdOrAmount, uint8 catalystType, bool isCatalystMandatory)`: View function for current tunneling requirements.
    29. `getBondedCatalysts(uint256 tokenId) view returns (BondedCatalyst[] memory)`: View function to list all bonded catalysts for a specific NFT.
    30. `getQuantumEpoch() view returns (uint256)`: View function for the current global epoch.
    31. `getTunnelStabilityIndex() view returns (int256)`: View function for the global tunnel stability index.
    32. `pauseTunneling() onlyOwner`: Pauses the ability to initiate tunnels.
    33. `unpauseTunneling() onlyOwner`: Unpauses tunneling.
    34. `withdrawETH() onlyOwner`: Allows the owner to withdraw accumulated ETH fees.
    35. `renounceOwnership()`: Ownable standard.
    36. `transferOwnership(address newOwner)`: Ownable standard.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, useful for explicit casting/clarity sometimes
import "@chainlink/contracts/src/v0.8/VrfConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title QuantumTunnelNFT
 * @dev An advanced ERC721 contract featuring dynamic NFTs, asset bonding,
 * Chainlink VRF for random outcomes, time-based epochs, and global state
 * affecting NFT properties through a "tunneling" mechanism.
 */
contract QuantumTunnelNFT is ERC721Enumerable, Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    // --- State Variables ---

    // Dynamic NFT Data
    enum BondType { ERC20, ERC721, ERC1155 }
    struct BondedCatalyst {
        BondType bondType;
        address contractAddress;
        uint256 identifierOrAmount; // tokenId for ERC721, id for ERC1155, amount for ERC20
        uint256 bondId; // Unique ID for this bond on this NFT
        bool isMandatoryUsed; // True if this mandatory catalyst was consumed in a tunnel
    }
    struct TokenData {
        uint256 dimension;         // Current quantum dimension the NFT is attuned to
        int256 stability;          // Stability score (affects tunnel success/risk)
        bytes32 quantumSignature;  // Unique signature derived from creation/tunneling
        uint256[] bondedBondIds;   // List of bondIds bonded to this NFT
    }
    mapping(uint256 => TokenData) private tokenData;
    mapping(uint256 => mapping(uint256 => BondedCatalyst)) private bondedCatalysts; // tokenId => bondId => Catalyst Data
    mapping(uint256 => Counters.Counter) private bondedCatalystCounter; // Counter for bondIds per NFT

    // Chainlink VRF Configuration
    mapping(uint64 => uint256) public vrfRequests; // requestId => tokenId

    uint16 private s_requestConfirmations;
    uint32 private s_callbackGasLimit;
    uint32 private s_numWords;
    bytes32 private s_keyHash;

    // Tunneling Parameters
    uint256 public tunnelFee = 0.05 ether; // ETH cost to initiate a tunnel
    string private _baseTokenURI;

    // Global Quantum State
    uint256 public currentQuantumEpoch = 1;
    uint256 public epochAdvanceThreshold = 30 days; // Time requirement for epoch advance (example)
    uint256 public lastEpochAdvanceTime;
    int256 public tunnelStabilityIndex = 0; // Global index affecting outcomes (starts neutral)
    uint256 public tunnelCountInEpoch = 0; // Count of tunnels in the current epoch

    // Catalyst Requirements
    struct CatalystConfig {
        BondType bondType;
        address catalystContract;
        uint256 identifierOrAmount;
        bool isMandatory; // If true, catalyst is consumed on tunnel initiation
        bool isConfigured; // Helper to know if a requirement is set
    }
    CatalystConfig public catalystRequirement;

    // Contract State
    bool public isTunnelingPaused = false;

    // --- Events ---
    event QuantumTunnelInitiated(uint256 indexed tokenId, uint64 indexed requestId, address indexed initiator);
    event QuantumTunnelOutcome(uint256 indexed tokenId, uint64 indexed requestId, uint256 outcomeType, string outcomeDescription); // outcomeType maps to internal logic branches
    event NFTDimensionShift(uint256 indexed tokenId, uint224 oldDimension, uint224 newDimension);
    event NFTStabilityChange(uint256 indexed tokenId, int256 stabilityDelta, int256 newStability);
    event CatalystBonded(uint256 indexed tokenId, uint256 indexed bondId, address indexed bondAddress, uint256 bondIdentifierOrAmount, uint8 bondType);
    event CatalystUnbonded(uint256 indexed tokenId, uint256 indexed bondId, address indexed bondAddress, uint256 bondIdentifierOrAmount, uint8 bondType);
    event QuantumEpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch);
    event TunnelStabilityIndexChanged(int256 indexed oldIndex, int256 indexed newIndex);
    event NewNFTGeneratedViaTunnel(uint256 indexed parentTokenId, uint256 indexed newTokenId);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!isTunnelingPaused, "Tunneling is paused");
        _;
    }

    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        uint64 subId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) {
        s_vrfCoordinator = vrfCoordinator;
        s_subscriptionId = subId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;
        lastEpochAdvanceTime = block.timestamp; // Initialize epoch time
    }

    // --- Standard ERC721 and ERC721Enumerable Functions (Inherited) ---
    // 2. supportsInterface(bytes4 interfaceId) view returns (bool)
    // 4. balanceOf(address owner) view returns (uint256)
    // 5. ownerOf(uint256 tokenId) view returns (address)
    // 6. safeTransferFrom(address from, address to, uint256 tokenId)
    // 7. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // 8. transferFrom(address from, address to, uint256 tokenId)
    // 9. approve(address to, uint256 tokenId)
    // 10. setApprovalForAll(address operator, bool approved)
    // 11. getApproved(uint256 tokenId) view returns (address operator)
    // 12. isApprovedForAll(address owner, address operator) view returns (bool)
    // 13. totalSupply() view returns (uint256)
    // 14. tokenByIndex(uint256 index) view returns (uint256)
    // 15. tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)
    // 35. renounceOwnership()
    // 36. transferOwnership(address newOwner)

    // --- Custom View Functions ---

    // 3. tokenURI(uint256 tokenId) view returns (string memory)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // Note: This is a base URI. A real dynamic NFT requires an external API
        // to fetch the tokenData struct and build JSON metadata.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // 21. getTokenData(uint256 tokenId) view returns (uint256 dimension, int256 stability, bytes32 quantumSignature, BondedCatalyst[] memory bonded)
    function getTokenData(uint256 tokenId) public view returns (uint256 dimension, int256 stability, bytes32 quantumSignature, BondedCatalyst[] memory bonded) {
        _requireMinted(tokenId);
        TokenData storage data = tokenData[tokenId];
        uint256[] storage bondIds = data.bondedBondIds;
        bonded = new BondedCatalyst[](bondIds.length);
        for (uint i = 0; i < bondIds.length; i++) {
            bonded[i] = bondedCatalysts[tokenId][bondIds[i]];
        }
        return (data.dimension, data.stability, data.quantumSignature, bonded);
    }

    // 22. assessStability(uint256 tokenId) view returns (int256 currentStability)
    function assessStability(uint256 tokenId) public view returns (int256 currentStability) {
        _requireMinted(tokenId);
        return tokenData[tokenId].stability;
    }

    // 28. getTunnelConfig() view returns (uint256 fee, address catalystAddress, uint256 catalystIdOrAmount, uint8 catalystType, bool isCatalystMandatory)
    function getTunnelConfig() public view returns (uint256 fee, address catalystAddress, uint256 catalystIdOrAmount, uint8 catalystType, bool isCatalystMandatory) {
        return (tunnelFee, catalystRequirement.catalystContract, catalystRequirement.identifierOrAmount, uint8(catalystRequirement.bondType), catalystRequirement.isMandatory);
    }

    // 29. getBondedCatalysts(uint256 tokenId) view returns (BondedCatalyst[] memory)
    function getBondedCatalysts(uint256 tokenId) public view returns (BondedCatalyst[] memory) {
        _requireMinted(tokenId);
        uint256[] storage bondIds = tokenData[tokenId].bondedBondIds;
        BondedCatalyst[] memory bonded = new BondedCatalyst[](bondIds.length);
        for (uint i = 0; i < bondIds.length; i++) {
            bonded[i] = bondedCatalysts[tokenId][bondIds[i]];
        }
        return bonded;
    }

    // 30. getQuantumEpoch() view returns (uint256)
    function getQuantumEpoch() public view returns (uint256) {
        return currentQuantumEpoch;
    }

    // 31. getTunnelStabilityIndex() view returns (int256)
    function getTunnelStabilityIndex() public view returns (int256) {
        return tunnelStabilityIndex;
    }

    // --- Custom Core Functions ---

    // 16. mintInitialBatch(address[] memory recipients, uint256 initialDimension, int256 initialStability) onlyOwner
    function mintInitialBatch(address[] memory recipients, uint256 initialDimension, int256 initialStability) public onlyOwner {
        for (uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], _nextTokenId.current());
            tokenData[_nextTokenId.current()] = TokenData({
                dimension: initialDimension,
                stability: initialStability,
                quantumSignature: keccak256(abi.encodePacked(_nextTokenId.current(), initialDimension, initialStability, block.timestamp, msg.sender, block.difficulty)), // Simple initial signature
                bondedBondIds: new uint256[](0)
            });
            _nextTokenId.increment();
        }
    }

    // 17. initiateTunnel(uint256 tokenId) payable whenNotPaused nonReentrant
    function initiateTunnel(uint256 tokenId) public payable whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not token owner");
        require(msg.value >= tunnelFee, "Insufficient tunnel fee");

        // Check and potentially consume mandatory catalyst
        if (catalystRequirement.isConfigured && catalystRequirement.isMandatory) {
            bool catalystFoundAndUsed = false;
            uint256[] storage bondIds = tokenData[tokenId].bondedBondIds;
            for (uint i = 0; i < bondIds.length; i++) {
                uint256 bondId = bondIds[i];
                BondedCatalyst storage bondedCat = bondedCatalysts[tokenId][bondId];
                if (!bondedCat.isMandatoryUsed &&
                    bondedCat.bondType == catalystRequirement.bondType &&
                    bondedCat.contractAddress == catalystRequirement.catalystContract &&
                    bondedCat.identifierOrAmount == catalystRequirement.identifierOrAmount)
                {
                    // Consume the mandatory catalyst
                    bondedCat.isMandatoryUsed = true; // Mark as used internally

                    // Transfer the actual catalyst out (to owner or zero address depending on design)
                    // Transferring to msg.sender seems reasonable, like it's "used up" by the owner
                    // If it should be burned or sent to the contract, modify here.
                    // For this example, let's say it's consumed by being sent back to the owner.
                    if (bondedCat.bondType == BondType.ERC20) {
                         IERC20(bondedCat.contractAddress).transfer(msg.sender, bondedCat.identifierOrAmount);
                    } else if (bondedCat.bondType == BondType.ERC721) {
                        IERC721(bondedCat.contractAddress).transferFrom(address(this), msg.sender, bondedCat.identifierOrAmount);
                    } else if (bondedCat.bondType == BondType.ERC1155) {
                        IERC1155(bondedCat.contractAddress).safeTransferFrom(address(this), msg.sender, bondedCat.identifierOrAmount, 1, ""); // Assuming amount is 1 for ERC1155 catalyst config
                    }
                    catalystFoundAndUsed = true;
                    break; // Only need one mandatory catalyst
                }
            }
            require(catalystFoundAndUsed, "Mandatory catalyst not bonded or already used");
        }

        // Request randomness from Chainlink VRF
        uint64 requestId = requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );

        vrfRequests[requestId] = tokenId; // Link request ID to token ID
        tunnelCountInEpoch++; // Increment tunnel count

        emit QuantumTunnelInitiated(tokenId, requestId, msg.sender);
    }

    // 18. fulfillRandomWords(uint64 requestId, uint256[] memory randomWords) internal override
    function fulfillRandomWords(uint64 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = vrfRequests[requestId];
        require(tokenId != 0, "Request Id not found");
        delete vrfRequests[requestId]; // Clean up request

        // Retrieve token data and global state
        TokenData storage data = tokenData[tokenId];
        int256 currentStability = data.stability;
        uint256 currentDimension = data.dimension;
        uint256 epoch = currentQuantumEpoch;
        int256 globalStability = tunnelStabilityIndex;
        uint256 bondedCount = data.bondedBondIds.length; // Number of bonded catalysts

        // --- Complex Outcome Logic ---
        // This is the core creative part. The outcome depends on randomWords,
        // token stats, global state, bonded catalysts, etc.
        // outcomeDecision is a value derived from randomWords, scaled to represent outcome possibilities.
        uint256 outcomeDecision = randomWords[0] % 10000; // Scale 0-9999 for probability checks

        // Influence outcomeDecision by stability and global factors
        // Higher combined stability (token + global) shifts outcomes towards 'better' results
        // Lower stability shifts towards 'worse' results
        int256 combinedStability = currentStability + globalStability;

        // Adjust outcomeDecision based on combined stability (example logic):
        // Shift the decision range slightly based on stability. +100 stability could shift by 100 points.
        int256 stabilityAdjustment = combinedStability / 10; // Divide to reduce impact
        outcomeDecision = uint256(int256(outcomeDecision) + stabilityAdjustment);
        if (int256(outcomeDecision) < 0) outcomeDecision = 0; // Prevent underflow
        if (outcomeDecision > 9999) outcomeDecision = 9999; // Prevent overflow

        // Influence outcomeDecision by epoch and bonded catalysts
        // Higher epoch might introduce new outcomes or risks.
        // Bonded catalysts can add bonuses or specific outcome biases.
        // Example: Each bonded catalyst adds a small bonus to stability influence or shifts decision slightly.
        uint256 catalystBonus = bondedCount * 10; // Example: +10 to outcomeDecision per catalyst
        outcomeDecision = outcomeDecision + catalystBonus;
         if (outcomeDecision > 9999) outcomeDecision = 9999;

        uint256 outcomeType; // Enum-like: 0=Failure, 1=Minor Shift, 2=Major Shift, 3=Transformation
        string memory outcomeDescription;
        int256 stabilityDelta = 0; // Change in stability
        uint256 newDimension = currentDimension; // New dimension if shifted

        // Probability distribution based on outcomeDecision (influenced by factors)
        if (outcomeDecision < 500) { // ~5% (adjusted) - Catastrophic Failure
            outcomeType = 0;
            outcomeDescription = "Catastrophic failure. NFT unstable.";
            stabilityDelta = -50 - int256(epoch); // Major stability loss, worse in higher epochs
            // Add logic here for severe consequences, maybe temporary disablement or partial stat reset
            // For simplicity, only affecting stability here.
        } else if (outcomeDecision < 2000) { // ~15% (adjusted) - Minor Instability
             outcomeType = 0; // Still considered a failure outcome type for grouping
             outcomeDescription = "Minor instability detected. Stability decreased.";
             stabilityDelta = -15;
        } else if (outcomeDecision < 5000) { // ~30% (adjusted) - State Fluctuation (no major change)
             outcomeType = 1;
             outcomeDescription = "State fluctuated. Stability slightly affected.";
             stabilityDelta = int256(randomWords[1] % 20) - 10; // Small random stability change (-10 to +9)
        } else if (outcomeDecision < 8000) { // ~30% (adjusted) - Dimension Shift (Moderate)
             outcomeType = 2;
             outcomeDescription = "Dimensional drift. Shifted to a nearby dimension.";
             stabilityDelta = 10; // Stability gain from successful shift
             // Shift to a nearby dimension (can be forward or backward)
             int256 dimensionShiftAmount = int256(randomWords[2] % 5) - 2; // Shift by -2 to +2
             newDimension = (currentDimension == 1 && dimensionShiftAmount < 0) ? 1 : uint256(int256(currentDimension) + dimensionShiftAmount); // Prevent dim < 1
        } else if (outcomeDecision < 9500) { // ~15% (adjusted) - Significant Dimension Shift
             outcomeType = 2;
             outcomeDescription = "Significant dimensional shift successful!";
             stabilityDelta = 25; // Larger stability gain
             // Shift to a more distant dimension
             int256 dimensionShiftAmount = int256(randomWords[2] % 10) + 3; // Shift by +3 to +12
             if (randomWords[3] % 2 == 0) dimensionShiftAmount = -dimensionShiftAmount; // 50% chance to shift backward
             newDimension = (currentDimension == 1 && dimensionShiftAmount < 0) ? 1 : uint256(int256(currentDimension) + dimensionShiftAmount);
        } else { // > 9500 // ~5% (adjusted) - Quantum Transformation (Generate New NFT)
            outcomeType = 3;
            outcomeDescription = "Quantum transformation! A new entity is generated.";
            stabilityDelta = 50; // Big stability gain for the *parent* (if it survives)
            // Note: In this model, the original NFT survives and gains stability,
            // but a NEW NFT is minted as a separate outcome.
            // An alternative could be burning the original and minting a new one.
            // Let's mint a new one and link it to the parent.

            uint256 newTokenId = _nextTokenId.current();
            _safeMint(ownerOf(tokenId), newTokenId); // Mint to the owner of the parent NFT
            tokenData[newTokenId] = TokenData({
                dimension: newDimension, // New NFT starts in the parent's new dimension
                stability: 50, // New NFT starts with decent stability
                quantumSignature: keccak256(abi.encodePacked(tokenId, newTokenId, randomWords[4], block.timestamp)), // Signature links to parent and randomness
                bondedBondIds: new uint256[](0) // New NFT starts with no bonded catalysts
            });
             _nextTokenId.increment();

             emit NewNFTGeneratedViaTunnel(tokenId, newTokenId);
        }

        // Update token data
        data.stability = data.stability + stabilityDelta;
        if (newDimension != currentDimension) {
            data.dimension = newDimension;
            emit NFTDimensionShift(tokenId, uint224(currentDimension), uint224(newDimension));
        }
        // Update quantum signature based on randomness and outcome
        data.quantumSignature = keccak256(abi.encodePacked(data.quantumSignature, randomWords[randomWords.length - 1], outcomeType, newDimension, data.stability));

        // Update global tunnel stability index (e.g., more failures decrease it, more successes increase it)
        if (outcomeType == 0) {
            tunnelStabilityIndex -= 5; // Failures decrease global stability
        } else if (outcomeType >= 1) {
             tunnelStabilityIndex += 2; // Successes increase global stability slightly
        }
        emit TunnelStabilityIndexChanged(globalStability, tunnelStabilityIndex);


        emit QuantumTunnelOutcome(tokenId, requestId, outcomeType, outcomeDescription);
         emit NFTStabilityChange(tokenId, stabilityDelta, data.stability);
    }

    // 19. bondCatalyst(uint256 tokenId, BondType bondType, address catalystContract, uint256 identifierOrAmount) nonReentrant
    function bondCatalyst(uint256 tokenId, BondType bondType, address catalystContract, uint256 identifierOrAmount) public nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not token owner");
        require(catalystContract != address(0), "Invalid catalyst contract address");

        uint256 bondId = bondedCatalystCounter[tokenId].current();
        bondedCatalystCounter[tokenId].increment();

        // Transfer the catalyst into the contract
        if (bondType == BondType.ERC20) {
            require(IERC20(catalystContract).transferFrom(msg.sender, address(this), identifierOrAmount), "ERC20 transfer failed");
        } else if (bondType == BondType.ERC721) {
            IERC721(catalystContract).transferFrom(msg.sender, address(this), identifierOrAmount);
        } else if (bondType == BondType.ERC1155) {
            // Assuming identifierOrAmount is the ID, and we are bonding 1 unit
            require(identifierOrAmount > 0, "ERC1155 ID must be non-zero");
            IERC1155(catalystContract).safeTransferFrom(msg.sender, address(this), identifierOrAmount, 1, "");
        } else {
            revert("Unsupported bond type");
        }

        // Store bond information
        bondedCatalysts[tokenId][bondId] = BondedCatalyst({
            bondType: bondType,
            contractAddress: catalystContract,
            identifierOrAmount: identifierOrAmount,
            bondId: bondId,
            isMandatoryUsed: false // Reset mandatory used status on bonding
        });

        // Add bondId to the NFT's list
        tokenData[tokenId].bondedBondIds.push(bondId);

        emit CatalystBonded(tokenId, bondId, catalystContract, identifierOrAmount, uint8(bondType));
    }

    // 20. unbondCatalyst(uint256 tokenId, uint256 bondId) nonReentrant
    function unbondCatalyst(uint256 tokenId, uint256 bondId) public nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not token owner");

        BondedCatalyst storage bondedCat = bondedCatalysts[tokenId][bondId];
        require(bondedCat.contractAddress != address(0), "Bond ID not found or already unbonded");
        // Prevent unbonding if it was a mandatory catalyst used in a tunnel attempt.
        // This prevents users from reclaiming a catalyst that was "consumed".
        require(!bondedCat.isMandatoryUsed, "Cannot unbond mandatory catalyst that was used in a tunnel");


        // Transfer the catalyst back to the owner
        if (bondedCat.bondType == BondType.ERC20) {
             IERC20(bondedCat.contractAddress).transfer(msg.sender, bondedCat.identifierOrAmount);
        } else if (bondedCat.bondType == BondType.ERC721) {
            IERC721(bondedCat.contractAddress).transferFrom(address(this), msg.sender, bondedCat.identifierOrAmount);
        } else if (bondedCat.bondType == BondType.ERC1155) {
            IERC1155(bondedCat.contractAddress).safeTransferFrom(address(this), msg.sender, bondedCat.identifierOrAmount, 1, ""); // Assuming amount was 1
        }


        // Remove bond information
        delete bondedCatalysts[tokenId][bondId];
        // Remove bondId from the NFT's list (inefficient for large lists, better solutions exist)
        uint256[] storage bondIds = tokenData[tokenId].bondedBondIds;
        for (uint i = 0; i < bondIds.length; i++) {
            if (bondIds[i] == bondId) {
                bondIds[i] = bondIds[bondIds.length - 1]; // Swap with last element
                bondIds.pop(); // Remove last element
                break;
            }
        }

        emit CatalystUnbonded(tokenId, bondId, bondedCat.contractAddress, bondedCat.identifierOrAmount, uint8(bondedCat.bondType));
    }

    // 23. reinforceStability(uint256 tokenId) payable whenNotPaused nonReentrant
    function reinforceStability(uint256 tokenId) public payable whenNotPaused nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not token owner");
        require(msg.value > 0, "Must send ETH to reinforce stability");

        // Example: 1 ETH adds 10 stability points
        int256 stabilityIncrease = int256(msg.value / (1 ether / 10));

        tokenData[tokenId].stability += stabilityIncrease;

        emit NFTStabilityChange(tokenId, stabilityIncrease, tokenData[tokenId].stability);
    }

    // --- Admin Functions ---

    // 17. mintInitialBatch (Already listed above)

    // 24. setBaseTokenURI(string memory uri) onlyOwner
    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    // 25. setTunnelFee(uint256 fee) onlyOwner
    function setTunnelFee(uint256 fee) public onlyOwner {
        tunnelFee = fee;
    }

    // 26. setCatalystRequirement(BondType bondType, address catalystContract, uint256 identifierOrAmount, bool isMandatory) onlyOwner
    function setCatalystRequirement(BondType bondType, address catalystContract, uint256 identifierOrAmount, bool isMandatory) public onlyOwner {
        // Allow setting catalystContract to address(0) to remove requirement
        if (catalystContract == address(0)) {
            delete catalystRequirement;
        } else {
             catalystRequirement = CatalystConfig({
                bondType: bondType,
                catalystContract: catalystContract,
                identifierOrAmount: identifierOrAmount,
                isMandatory: isMandatory,
                isConfigured: true
            });
             // For ERC1155 mandatory catalysts, identifierOrAmount is the token ID, require bonding amount 1
             if (isMandatory && bondType == BondType.ERC1155) {
                 require(identifierOrAmount > 0, "ERC1155 mandatory catalyst needs valid ID");
                 // identifierOrAmount stores the ID, amount is assumed 1 for mandatory bond
             }
        }
    }

    // 27. triggerQuantumEpochAdvance() onlyOwner
    function triggerQuantumEpochAdvance() public onlyOwner {
        // Add checks here if needed, e.g., require(block.timestamp >= lastEpochAdvanceTime + epochAdvanceThreshold, "Epoch threshold not met");
        currentQuantumEpoch++;
        lastEpochAdvanceTime = block.timestamp;
        uint256 oldTunnelCount = tunnelCountInEpoch;
        tunnelCountInEpoch = 0; // Reset counter for the new epoch

        // Add logic here for epoch transition effects if any
        // e.g., globalStabilityIndex might reset or shift based on epoch transition

        emit QuantumEpochAdvanced(currentQuantumEpoch - 1, currentQuantumEpoch);
         // If global stability index is affected by epoch change, emit event here too.
    }

    // 32. pauseTunneling() onlyOwner
    function pauseTunneling() public onlyOwner {
        isTunnelingPaused = true;
    }

    // 33. unpauseTunneling() onlyOwner
    function unpauseTunneling() public onlyOwner {
        isTunnelingPaused = false;
    }

    // 34. withdrawETH() onlyOwner nonReentrant
    function withdrawETH() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Internal/Helper Functions ---

    // Function to safely require a token is minted (ERC721Enumerable handles this for standard ops)
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    // Function to safely require sender is owner (ERC721 handles this for standard ops)
    function _requireOwned(uint256 tokenId) internal view {
        require(ERC721.ownerOf(tokenId) == msg.sender, "ERC721: transfer caller is not owner nor approved");
    }

    // Override _beforeTokenTransfer to potentially restrict transfers based on state (e.g., mid-tunnel)
    // Not strictly required by the prompt, but adds a layer of complexity.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Example: prevent transfer if tokenId is currently associated with an active VRF request
    //     // require(vrfRequests does not contain tokenId, "Cannot transfer token mid-tunnel");
    // }

     // Override _burn to handle bonded catalysts if the NFT is burned directly (not via tunnel transformation)
     function _burn(uint256 tokenId) internal override {
         super._burn(tokenId);
         // Logic here to handle bonded catalysts on burn.
         // Option 1: Burn bonded catalysts too (simple).
         // Option 2: Transfer bonded catalysts back to the *original* bonder (complex, requires tracking bonder address per bond).
         // Option 3: Transfer bonded catalysts to the NFT *owner* at time of burn. Let's do this for simplicity.

         uint256[] memory bondIds = tokenData[tokenId].bondedBondIds;
         address currentOwner = ownerOf(tokenId); // Get owner *before* super._burn removes it

         for (uint i = 0; i < bondIds.length; i++) {
             uint256 bondId = bondIds[i];
             BondedCatalyst storage bondedCat = bondedCatalysts[tokenId][bondId];
             if (bondedCat.contractAddress != address(0) && !bondedCat.isMandatoryUsed) { // Don't try to transfer if already used/deleted
                 if (bondedCat.bondType == BondType.ERC20) {
                      // Use low-level call for safety, as ERC20s can be tricky
                     (bool success, ) = bondedCat.contractAddress.call(abi.encodeWithSignature("transfer(address,uint256)", currentOwner, bondedCat.identifierOrAmount));
                     // Decide if failure here should revert the burn or just log
                     require(success, "Bonded ERC20 transfer failed on burn");
                 } else if (bondedCat.bondType == BondType.ERC721) {
                      IERC721(bondedCat.contractAddress).transferFrom(address(this), currentOwner, bondedCat.identifierOrAmount);
                 } else if (bondedCat.bondType == BondType.ERC1155) {
                      IERC1155(bondedCat.contractAddress).safeTransferFrom(address(this), currentOwner, bondedCat.identifierOrAmount, 1, ""); // Assuming amount was 1
                 }
             }
             delete bondedCatalysts[tokenId][bondId]; // Clean up storage
         }
         delete tokenData[tokenId].bondedBondIds; // Clear the list
         delete tokenData[tokenId]; // Clean up token data struct
         delete bondedCatalystCounter[tokenId]; // Reset counter
     }

     // Add a burn function that utilizes the internal _burn
     // Can be used by owner to destroy NFT
     function burn(uint256 tokenId) public virtual {
         address owner = ownerOf(tokenId);
         require(owner == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "ERC721: caller is not owner nor approved");
         _burn(tokenId);
     }

    // --- Fallback to receive ETH for tunneling ---
    receive() external payable {
        // Allow receiving ETH, primarily for tunnel fees
    }

    // --- ERC721 and ERC1155 Receiver Hooks ---
    // Implement these if you want the contract to be able to *receive* ERC721 or ERC1155 tokens
    // sent directly, which is necessary for the `bondCatalyst` function when tokens are transferred *to* the contract.

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        // The contract expects to receive ERC721 during the bondCatalyst function.
        // This callback must return the ERC721_RECEIVED constant.
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
         // The contract expects to receive ERC1155 during the bondCatalyst function.
        // This callback must return the ERC1155_RECEIVED constant.
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4) {
        // Implement if you expect to receive batch ERC1155 transfers for bonding
         return this.onERC1155BatchReceived.selector;
    }

}
```