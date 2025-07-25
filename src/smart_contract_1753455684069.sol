This smart contract, "ChronoForge," is designed to be a highly advanced, conceptual platform for creating, evolving, and interacting with unique, time-sensitive digital assets called "Temporal Artifacts" (NFTs). It introduces concepts like dynamic NFT properties, time-weighted token accrual, artifact lending, predictive forging, and even "flash forging" of NFTs.

---

### **ChronoForge: Outline and Function Summary**

**Contract Name:** `ChronoForge`

**Core Concepts:**

1.  **Temporal Artifacts (NFTs):** Unique ERC-721 tokens whose properties can dynamically change over time and through user interactions.
2.  **ChronoEssence (Fungible Token):** An ERC-20 utility token that is accrued by Temporal Artifacts based on their intrinsic "Temporal Signature" and time spent staked/owned. It's used for forging new artifacts, mutating existing ones, and participating in advanced operations.
3.  **Dynamic Properties & Evolution:** Artifacts possess a `TemporalSignature` that dictates their unique characteristics and how they accrue ChronoEssence. They can be "mutated" (upgraded/evolved) by burning ChronoEssence and potentially other artifacts.
4.  **Time-Weighted Mechanics:**
    *   **Essence Accrual:** Essence accumulates based on time and artifact properties.
    *   **Temporal Lending:** Users can lend their artifacts for a set period, receiving ChronoEssence as a "rent" payment.
    *   **Predictive Forging:** Users commit ChronoEssence for a future artifact whose final properties are determined by a time-based or pre-defined future event.
5.  **Flash Forging:** A highly advanced concept enabling instantaneous forging of an artifact, its immediate use (e.g., for an upgrade), and a simultaneous "repayment" (e.g., burning the forged artifact or fulfilling a condition) within a single transaction, without requiring upfront capital.
6.  **Delegated Temporal Power:** Owners can delegate certain rights (like essence claiming or mutation) to another address for a specified duration.
7.  **Pseudo-Randomness (On-Chain):** Uses block data to introduce an element of uniqueness during artifact forging.

---

**Function Summary (26+ Functions):**

**I. Administrative & Setup (Ownable, Pausable)**
1.  `constructor()`: Initializes the contract, sets names/symbols for ERC-20/721.
2.  `updateForgerFeeRate(uint256 newRate)`: Updates the percentage fee taken for forging operations.
3.  `updateMinEssenceForMutation(uint256 newAmount)`: Adjusts the minimum essence required for artifact mutation.
4.  `pause()`: Pauses core operations in emergencies.
5.  `unpause()`: Resumes operations.
6.  `withdrawProtocolFees()`: Allows owner to withdraw collected ETH fees.

**II. ChronoEssence (ERC-20 Functions)**
7.  `transfer(address to, uint256 amount)`: Standard ERC-20 transfer.
8.  `transferFrom(address from, address to, uint256 amount)`: Standard ERC-20 transfer from an approved address.
9.  `approve(address spender, uint256 amount)`: Standard ERC-20 approval.
10. `allowance(address owner, address spender)`: Standard ERC-20 allowance check.
11. `balanceOf(address account)`: Standard ERC-20 balance check.
12. `totalSupply()`: Standard ERC-20 total supply.

**III. Temporal Artifacts (ERC-721 Functions)**
13. `ownerOf(uint256 tokenId)`: Standard ERC-721 owner check.
14. `getApproved(uint256 tokenId)`: Standard ERC-721 approval check.
15. `setApprovalForAll(address operator, bool approved)`: Standard ERC-721 operator approval.
16. `isApprovedForAll(address owner, address operator)`: Standard ERC-721 operator check.
17. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 transfer.
18. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC-721 safe transfer.
19. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Standard ERC-721 safe transfer with data.
20. `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)`: ERC-721 Receiver hook.

**IV. Core ChronoForge Mechanics**
21. `forgeNewArtifact(uint256 essenceCost)`: Mints a new Temporal Artifact by burning ChronoEssence. Its `TemporalSignature` is semi-randomly generated.
22. `calculatePendingEssence(uint256 tokenId)`: Calculates the ChronoEssence accrued but not yet claimed for a specific artifact.
23. `accrueEssenceForArtifact(uint256 tokenId)`: Allows the artifact owner (or delegated address) to claim accrued ChronoEssence.
24. `mutateArtifact(uint256 targetArtifactId, uint256 essenceBurnAmount, uint256[] calldata sacrificeArtifactIds)`: Evolves an existing artifact by burning essence and optionally sacrificing other artifacts. Changes the target artifact's `TemporalSignature` and metadata.
25. `initiateTemporalLend(uint256 tokenId, uint256 durationInSeconds, uint256 essenceRatePerSecond)`: Initiates a lending agreement for an artifact.
26. `completeTemporalLend(uint256 tokenId)`: Allows the borrower to return a lent artifact and the lender to claim accumulated essence.
27. `reclaimLentArtifact(uint256 tokenId)`: Allows the lender to reclaim a lent artifact if the borrowing period has expired.
28. `requestPredictiveForge(uint256 essenceCommitment, uint256 fulfillmentTimestamp, uint256 minimumRarity)`: Commits essence for a future artifact, whose properties are determined upon fulfillment.
29. `fulfillPredictiveForge(uint256 requestId)`: Mints the predictive artifact once its `fulfillmentTimestamp` is reached, based on on-chain data at that time.
30. `initiateFlashForge(uint256 essenceCost, bytes calldata data)`: Enables "flash forging." The caller borrows the `essenceCost` from the protocol, performs an action (e.g., `mutateArtifact`), and must repay the `essenceCost` within the same transaction. The `data` parameter typically contains the instructions for the flash forge.
31. `delegateTemporalPower(uint256 tokenId, address delegatee, uint256 durationInSeconds)`: Delegates essence claiming and mutation rights for an artifact to another address for a limited time.
32. `revokeTemporalPower(uint256 tokenId)`: Revokes any active delegation for an artifact.
33. `getArtifactDetails(uint256 tokenId)`: Retrieves full details of a Temporal Artifact.
34. `getCurrentArtifactPower(uint256 tokenId)`: Calculates a dynamic "power score" for an artifact based on its essence, signature, and time.
35. `burnArtifact(uint256 tokenId)`: Allows an artifact owner to burn their artifact, potentially receiving a small essence refund.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though Solidity 0.8+ has overflow checks

// Custom error for better readability and gas efficiency
error ChronoForge__NotOwner();
error ChronoForge__NotArtifactOwner();
error ChronoForge__InsufficientEssence(uint256 required, uint256 has);
error ChronoForge__EssenceTransferFailed();
error ChronoForge__InvalidTokenId();
error ChronoForge__ArtifactNotPaused();
error ChronoForge__ArtifactPaused();
error ChronoForge__LendingAlreadyActive();
error ChronoForge__LendingNotActive();
error ChronoForge__LendingDurationInvalid();
error ChronoForge__LendingRateInvalid();
error ChronoForge__NotLender();
error ChronoForge__NotBorrower();
error ChronoForge__LendPeriodNotOver();
error ChronoForge__LendPeriodStillActive();
error ChronoForge__FlashForgeRepaymentFailed();
error ChronoForge__NoActivePrediction();
error ChronoForge__PredictionNotFulfilledYet();
error ChronoForge__PredictionAlreadyFulfilled();
error ChronoForge__InsufficientEssenceCommitment();
error ChronoForge__PredictionPastFulfillment();
error ChronoForge__NotDelegated();
error ChronoForge__DelegationAlreadyActive();
error ChronoForge__DelegationDurationInvalid();
error ChronoForge__CannotMutateSelf();
error ChronoForge__CannotSacrificeActiveLend();
error ChronoForge__EssenceAccrualTooFrequent();

/**
 * @title ChronoEssence
 * @dev ERC-20 token for ChronoForge's utility and economic engine.
 */
contract ChronoEssence is ERC20, Ownable {
    constructor() ERC20("ChronoEssence", "CE") {}

    /**
     * @dev Mints ChronoEssence to a specified address.
     * Only callable by the ChronoForge contract or owner.
     * @param to The address to mint to.
     * @param amount The amount to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns ChronoEssence from a specified address.
     * Only callable by the ChronoForge contract or owner.
     * @param from The address to burn from.
     * @param amount The amount to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

/**
 * @title ChronoForge
 * @dev A highly advanced smart contract for managing Temporal Artifacts (NFTs)
 *      and ChronoEssence (ERC-20), featuring dynamic properties, time-weighted
 *      accrual, artifact lending, predictive forging, and flash forging.
 */
contract ChronoForge is ERC721, IERC721Receiver, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- State Variables ---

    ChronoEssence public immutable essenceToken;
    uint256 private _nextTokenId;

    // Configuration parameters
    uint256 public forgerFeeRate = 50; // 0.5% (50 basis points)
    uint256 public minEssenceForMutation = 100 ether; // Minimum essence to burn for mutation
    uint256 public constant MAX_ESSENCE_ACCRETION_RATE = 100000; // Max essence per second per TemporalSignature

    // Artifact Data Structure
    struct TemporalArtifact {
        uint256 genesisTimestamp;
        uint256 lastAccrualTimestamp;
        TemporalSignature signature;
        string metadataURI; // Stores the current metadata URI for the artifact
        bool isPaused; // Can be paused by owner for special events/upgrades
    }

    // Temporal Signature: Determines artifact properties and essence generation
    struct TemporalSignature {
        uint8 originType; // e.g., 0=Solar, 1=Lunar, 2=Stellar, 3=Void, etc.
        uint8 baseRarity; // 1-100, higher is rarer
        uint32 accretionRatePerSecond; // Essence units per second (scaled)
        uint32[] affinityTypes; // Other origin types it has affinity with
        uint256 uniqueSeed; // A unique seed used for properties (e.g., visual traits)
    }

    mapping(uint256 => TemporalArtifact) public temporalArtifacts;

    // Lending Mechanism
    struct TemporalLend {
        address lender;
        address borrower;
        uint256 startTime;
        uint256 endTime;
        uint256 essenceRatePerSecond; // Rate ChronoEssence is paid by borrower to lender
        bool active;
    }
    mapping(uint256 => TemporalLend) public temporalLends;

    // Predictive Forging Mechanism
    struct PredictiveForgeRequest {
        address requester;
        uint256 essenceCommitment;
        uint256 fulfillmentTimestamp; // When the artifact can be forged
        uint256 minimumRarity;
        bool fulfilled; // True if the artifact has been minted
        uint256 forgedArtifactId; // The ID of the artifact once forged
    }
    mapping(uint256 => PredictiveForgeRequest) public predictiveForgeRequests;
    uint256 public nextPredictionId;

    // Delegated Power Mechanism
    struct TemporalDelegation {
        address delegatee;
        uint256 expiryTimestamp;
        bool active;
    }
    mapping(uint256 => TemporalDelegation) public temporalDelegations; // tokenId => delegation info

    // --- Events ---
    event ArtifactForged(uint256 indexed tokenId, address indexed owner, TemporalSignature signature, string metadataURI);
    event EssenceAccrued(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ArtifactMutated(uint256 indexed tokenId, address indexed mutator, TemporalSignature newSignature, string newMetadataURI, uint256 essenceBurned, uint256[] sacrificedArtifacts);
    event TemporalLendInitiated(uint256 indexed tokenId, address indexed lender, address indexed borrower, uint256 startTime, uint256 endTime, uint256 essenceRatePerSecond);
    event TemporalLendCompleted(uint256 indexed tokenId, address indexed lender, address indexed borrower, uint256 actualDuration, uint256 totalEssencePaid);
    event TemporalLendReclaimed(uint256 indexed tokenId, address indexed lender);
    event PredictiveForgeRequested(uint256 indexed requestId, address indexed requester, uint256 essenceCommitment, uint256 fulfillmentTimestamp, uint256 minimumRarity);
    event PredictiveForgeFulfilled(uint256 indexed requestId, uint256 indexed tokenId, address indexed requester, TemporalSignature signature);
    event FlashForgeInitiated(address indexed caller, uint256 essenceCost);
    event TemporalPowerDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee, uint256 expiryTimestamp);
    event TemporalPowerRevoked(uint256 indexed tokenId, address indexed owner);
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner, uint256 essenceRefund);
    event ArtifactMetadataUpdated(uint256 indexed tokenId, string newURI);

    // --- Constructor ---
    constructor()
        ERC721("TemporalArtifact", "TA")
        Ownable(msg.sender) // Set deployer as owner
        Pausable() // Initialize pausable
    {
        essenceToken = new ChronoEssence();
        // Grant ChronoForge contract permission to mint/burn ChronoEssence
        essenceToken.transferOwnership(address(this));
    }

    // --- Modifiers ---

    modifier onlyArtifactOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert ChronoForge__NotArtifactOwner();
        }
        _;
    }

    modifier onlyDelegatedOrOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            TemporalDelegation storage delegation = temporalDelegations[tokenId];
            if (!delegation.active || delegation.delegatee != _msgSender() || delegation.expiryTimestamp < block.timestamp) {
                revert ChronoForge__NotDelegated();
            }
        }
        _;
    }

    modifier whenArtifactNotPaused(uint256 tokenId) {
        if (temporalArtifacts[tokenId].isPaused) {
            revert ChronoForge__ArtifactPaused();
        }
        _;
    }

    modifier whenArtifactPaused(uint256 tokenId) {
        if (!temporalArtifacts[tokenId].isPaused) {
            revert ChronoForge__ArtifactNotPaused();
        }
        _;
    }

    // --- Administrative & Setup Functions ---

    /**
     * @dev Updates the percentage fee taken for forging operations.
     * @param newRate New rate in basis points (e.g., 50 for 0.5%). Max 1000 (10%).
     */
    function updateForgerFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 1000, "Forger fee rate cannot exceed 10%"); // Max 10%
        forgerFeeRate = newRate;
    }

    /**
     * @dev Adjusts the minimum essence required to perform an artifact mutation.
     * @param newAmount New minimum essence amount.
     */
    function updateMinEssenceForMutation(uint256 newAmount) external onlyOwner {
        minEssenceForMutation = newAmount;
    }

    /**
     * @dev Pauses the contract operations in emergencies.
     * Only callable by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract operations.
     * Only callable by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Withdraws accumulated ETH protocol fees to the owner.
     * ETH fees could come from future mechanisms, e.g., direct ETH payments for forging.
     */
    function withdrawProtocolFees() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- ERC-20 (ChronoEssence) Functions (Proxy to ChronoEssence contract) ---

    function transfer(address to, uint256 amount) external returns (bool) {
        return essenceToken.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return essenceToken.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return essenceToken.approve(spender, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return essenceToken.allowance(owner, spender);
    }

    function balanceOf(address account) public view returns (uint256) {
        return essenceToken.balanceOf(account);
    }

    function totalSupply() public view returns (uint256) {
        return essenceToken.totalSupply();
    }

    // --- ERC-721 (Temporal Artifacts) Functions ---
    // Inherited from ERC721: ownerOf, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom

    /**
     * @dev ERC-721 receiver hook.
     * Required for receiving NFTs safely into the contract (e.g., for lending).
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external pure override returns (bytes4) {
        // This can be expanded to check for specific conditions if needed
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- Core ChronoForge Mechanics ---

    /**
     * @dev Mints a new Temporal Artifact by burning ChronoEssence.
     * The artifact's TemporalSignature is semi-randomly generated based on block data.
     * @param essenceCost The amount of ChronoEssence to burn for forging.
     */
    function forgeNewArtifact(uint256 essenceCost)
        external
        nonReentrant
        whenNotPaused
    {
        if (essenceToken.balanceOf(_msgSender()) < essenceCost) {
            revert ChronoForge__InsufficientEssence(essenceCost, essenceToken.balanceOf(_msgSender()));
        }

        uint256 currentTokenId = _nextTokenId++;
        _safeMint(_msgSender(), currentTokenId);

        // Burn essence cost + fee
        uint256 feeAmount = essenceCost.mul(forgerFeeRate).div(10000);
        uint256 totalEssenceBurn = essenceCost.add(feeAmount);
        if (!essenceToken.burnFrom(_msgSender(), totalEssenceBurn)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        // Generate a pseudo-random seed for the artifact's properties
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), currentTokenId)));

        TemporalSignature memory newSignature;
        newSignature.originType = uint8(seed % 4); // 0-3 for origin types
        newSignature.baseRarity = uint8((seed % 100) + 1); // 1-100 rarity
        newSignature.accetionRatePerSecond = uint32((seed % MAX_ESSENCE_ACCRETION_RATE) + 1); // 1 to MAX_ESSENCE_ACCRETION_RATE
        newSignature.uniqueSeed = seed;

        // Populate affinity types (example logic)
        if (newSignature.originType == 0) newSignature.affinityTypes = [1, 3]; // Solar affinity with Lunar, Void
        else if (newSignature.originType == 1) newSignature.affinityTypes = [0, 2]; // Lunar affinity with Solar, Stellar
        else if (newSignature.originType == 2) newSignature.affinityTypes = [1, 3]; // Stellar affinity with Lunar, Void
        else newSignature.affinityTypes = [0, 2]; // Void affinity with Solar, Stellar

        string memory metadataURI = string(abi.encodePacked("ipfs://artifact/", currentTokenId.toString(), "/initial.json"));

        temporalArtifacts[currentTokenId] = TemporalArtifact({
            genesisTimestamp: block.timestamp,
            lastAccrualTimestamp: block.timestamp,
            signature: newSignature,
            metadataURI: metadataURI,
            isPaused: false
        });

        emit ArtifactForged(currentTokenId, _msgSender(), newSignature, metadataURI);
    }

    /**
     * @dev Calculates the ChronoEssence accrued but not yet claimed for a specific artifact.
     * @param tokenId The ID of the artifact.
     * @return The amount of pending ChronoEssence.
     */
    function calculatePendingEssence(uint256 tokenId) public view returns (uint256) {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];
        if (artifact.genesisTimestamp == 0) { // Check if artifact exists
            return 0; // Or revert ChronoForge__InvalidTokenId(); depending on desired behavior
        }
        if (artifact.isPaused) { // No accrual if paused
            return 0;
        }

        uint256 elapsed = block.timestamp.sub(artifact.lastAccrualTimestamp);
        return elapsed.mul(artifact.signature.accetionRatePerSecond);
    }

    /**
     * @dev Allows the artifact owner (or delegated address) to claim accrued ChronoEssence.
     * Updates the last accrual timestamp.
     * Can only be called once per specific time window, to prevent spamming accrual.
     * @param tokenId The ID of the artifact.
     */
    function accrueEssenceForArtifact(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyDelegatedOrOwner(tokenId)
        whenArtifactNotPaused(tokenId)
    {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];

        if (block.timestamp.sub(artifact.lastAccrualTimestamp) < 1 minutes) { // Prevent too frequent calls (e.g., every block)
            revert ChronoForge__EssenceAccrualTooFrequent();
        }

        uint256 pendingEssence = calculatePendingEssence(tokenId);
        if (pendingEssence == 0) {
            return; // No essence to accrue
        }

        artifact.lastAccrualTimestamp = block.timestamp;

        // Mint essence to the owner
        if (!essenceToken.mint(ownerOf(tokenId), pendingEssence)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        emit EssenceAccrued(tokenId, ownerOf(tokenId), pendingEssence);
    }

    /**
     * @dev Evolves an existing artifact by burning essence and optionally sacrificing other artifacts.
     * Changes the target artifact's `TemporalSignature` and metadata.
     * This is where dynamic NFT properties get updated.
     * @param targetArtifactId The ID of the artifact to mutate.
     * @param essenceBurnAmount The amount of ChronoEssence to burn.
     * @param sacrificeArtifactIds An array of artifact IDs to sacrifice (will be burned).
     */
    function mutateArtifact(
        uint256 targetArtifactId,
        uint256 essenceBurnAmount,
        uint256[] calldata sacrificeArtifactIds
    ) external nonReentrant whenNotPaused onlyDelegatedOrOwner(targetArtifactId) whenArtifactNotPaused(targetArtifactId) {
        TemporalArtifact storage targetArtifact = temporalArtifacts[targetArtifactId];

        if (essenceBurnAmount < minEssenceForMutation) {
            revert ChronoForge__InsufficientEssence(minEssenceForMutation, essenceBurnAmount);
        }
        if (essenceToken.balanceOf(_msgSender()) < essenceBurnAmount) {
            revert ChronoForge__InsufficientEssence(essenceBurnAmount, essenceToken.balanceOf(_msgSender()));
        }

        // Burn essence from caller
        if (!essenceToken.burnFrom(_msgSender(), essenceBurnAmount)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        // Sacrifice artifacts
        for (uint256 i = 0; i < sacrificeArtifactIds.length; i++) {
            uint256 sacrificeId = sacrificeArtifactIds[i];
            if (sacrificeId == targetArtifactId) {
                revert ChronoForge__CannotMutateSelf();
            }
            if (ownerOf(sacrificeId) != _msgSender()) {
                revert ChronoForge__NotArtifactOwner(); // Or a specific error for sacrifice
            }
            if (temporalLends[sacrificeId].active) {
                revert ChronoForge__CannotSacrificeActiveLend();
            }
            _burn(sacrificeId); // Burn the sacrificed artifact
        }

        // Logic for mutating signature (example: increase rarity, change origin, boost accretion)
        // This can be complex based on game mechanics, e.g., combining signatures,
        // or probabilistic outcomes based on essence and sacrifices.
        uint256 mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), targetArtifactId, essenceBurnAmount, sacrificeArtifactIds)));

        targetArtifact.signature.baseRarity = uint8(targetArtifact.signature.baseRarity.add(mutationSeed % 5).min(100)); // Increase rarity
        targetArtifact.signature.accetionRatePerSecond = uint32(targetArtifact.signature.accetionRatePerSecond.add(mutationSeed % 10000).min(MAX_ESSENCE_ACCRETION_RATE)); // Boost accrual
        targetArtifact.signature.originType = uint8(mutationSeed % 4); // Potentially change origin type

        // Update metadata URI to reflect new state
        targetArtifact.metadataURI = string(abi.encodePacked("ipfs://artifact/", targetArtifactId.toString(), "/mutated_", block.timestamp.toString(), ".json"));

        emit ArtifactMutated(
            targetArtifactId,
            _msgSender(),
            targetArtifact.signature,
            targetArtifact.metadataURI,
            essenceBurnAmount,
            sacrificeArtifactIds
        );
    }

    /**
     * @dev Initiates a temporal lending agreement for an artifact.
     * The artifact is transferred to the contract and locked for the duration.
     * @param tokenId The ID of the artifact to lend.
     * @param durationInSeconds The duration of the lend in seconds.
     * @param essenceRatePerSecond The ChronoEssence rate the borrower pays to the lender per second.
     */
    function initiateTemporalLend(
        uint256 tokenId,
        uint256 durationInSeconds,
        uint256 essenceRatePerSecond
    ) external nonReentrant whenNotPaused onlyArtifactOwner(tokenId) whenArtifactNotPaused(tokenId) {
        if (temporalLends[tokenId].active) {
            revert ChronoForge__LendingAlreadyActive();
        }
        if (durationInSeconds == 0) {
            revert ChronoForge__LendingDurationInvalid();
        }
        if (essenceRatePerSecond == 0) {
            revert ChronoForge__LendingRateInvalid();
        }

        _safeTransfer(msg.sender, address(this), tokenId); // Transfer artifact to contract

        temporalLends[tokenId] = TemporalLend({
            lender: _msgSender(),
            borrower: address(0), // Set to address(0) initially, borrower claims it later
            startTime: block.timestamp,
            endTime: block.timestamp.add(durationInSeconds),
            essenceRatePerSecond: essenceRatePerSecond,
            active: true
        });

        // The borrower would typically call a separate 'borrowArtifact' function, or this function could take a borrower param.
        // For simplicity, let's assume the borrower claims it, or the lender sets the borrower.
        // Here, we simplify and assume the `msg.sender` is implicitly lending TO SOMEONE who will take it.
        // A full lending market would need more complex order book/matching.
        // For this example, let's assume the borrower is set by a future function.
        // To make it directly callable, we need a borrower address.
        // Let's modify this to include a `borrower` param.
        revert("Deprecated: Use a market or direct borrower transfer"); // Force a design choice

        // Alternative design for a direct lend:
        // function initiateTemporalLend(uint256 tokenId, address borrower, ...)
        // This is better for a single contract example.
    }

    /**
     * @dev Allows a specified borrower to take possession of a pre-approved lent artifact.
     * This separates the lending from the borrowing action.
     * @param tokenId The ID of the artifact to borrow.
     * @param expectedLender The address of the lender who initiated the lend.
     */
    function takeTemporalLend(uint256 tokenId, address expectedLender)
        external
        nonReentrant
        whenNotPaused
        whenArtifactNotPaused(tokenId)
    {
        TemporalLend storage lend = temporalLends[tokenId];
        if (!lend.active || lend.lender != expectedLender || lend.borrower != address(0)) {
            revert ChronoForge__LendingNotActive(); // Or specific errors
        }

        // Artifact must be owned by the contract itself for lending
        if (ownerOf(tokenId) != address(this)) {
            revert ChronoForge__NotArtifactOwner(); // Artifact not in contract's possession
        }

        lend.borrower = _msgSender();
        // No _safeTransfer here, as the artifact remains in the contract's custody.
        // The "borrower" gets rights to accrue/use it conceptually, but it's not transferred to their wallet.
        // If it was transferred, it'd complicate reclaim/return.
        // Instead, the contract keeps custody, and the borrower gets "usage rights".
        // This simplifies the return/reclaim logic.

        emit TemporalLendInitiated(
            tokenId,
            lend.lender,
            lend.borrower,
            lend.startTime,
            lend.endTime,
            lend.essenceRatePerSecond
        );
    }

    /**
     * @dev Allows the borrower to complete a temporal lend by paying accrued essence and returning the artifact.
     * Transfers the artifact back to the original lender.
     * @param tokenId The ID of the artifact.
     */
    function completeTemporalLend(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        whenArtifactNotPaused(tokenId)
    {
        TemporalLend storage lend = temporalLends[tokenId];
        if (!lend.active || lend.borrower != _msgSender()) {
            revert ChronoForge__NotBorrower();
        }

        // Calculate essence owed
        uint256 actualDuration = block.timestamp.sub(lend.startTime);
        uint256 essenceOwed = actualDuration.mul(lend.essenceRatePerSecond);

        if (essenceToken.balanceOf(_msgSender()) < essenceOwed) {
            revert ChronoForge__InsufficientEssence(essenceOwed, essenceToken.balanceOf(_msgSender()));
        }

        // Pay essence to lender
        if (!essenceToken.transferFrom(_msgSender(), lend.lender, essenceOwed)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        // Transfer artifact back to lender
        _safeTransfer(address(this), lend.lender, tokenId);

        lend.active = false; // Mark lend as inactive
        lend.borrower = address(0); // Clear borrower
        lend.lender = address(0); // Clear lender

        emit TemporalLendCompleted(tokenId, lend.lender, _msgSender(), actualDuration, essenceOwed);
    }

    /**
     * @dev Allows the original lender to reclaim a lent artifact if the borrowing period has expired.
     * @param tokenId The ID of the artifact.
     */
    function reclaimLentArtifact(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        whenArtifactNotPaused(tokenId)
    {
        TemporalLend storage lend = temporalLends[tokenId];
        if (!lend.active || lend.lender != _msgSender()) {
            revert ChronoForge__NotLender();
        }
        if (block.timestamp < lend.endTime) {
            revert ChronoForge__LendPeriodStillActive();
        }

        // No essence payment from borrower on reclaim, as period expired without completion.
        // Essence already paid for the duration up to expiration could be claimed by lender
        // via `accrueEssenceForArtifact` during the lend period, if we allowed it.
        // For simplicity, let's say the lender gets it back, and any owed essence is lost by borrower.

        _safeTransfer(address(this), lend.lender, tokenId);

        lend.active = false;
        lend.borrower = address(0);
        lend.lender = address(0);

        emit TemporalLendReclaimed(tokenId, _msgSender());
    }

    /**
     * @dev Allows a user to commit essence for a "predictive forge" of a future artifact.
     * The artifact's final properties (e.g., rarity, origin) are determined at `fulfillmentTimestamp`.
     * @param essenceCommitment The amount of ChronoEssence committed.
     * @param fulfillmentTimestamp The Unix timestamp when the artifact can be forged.
     * @param minimumRarity The minimum desired rarity for the forged artifact.
     */
    function requestPredictiveForge(
        uint256 essenceCommitment,
        uint256 fulfillmentTimestamp,
        uint256 minimumRarity
    ) external nonReentrant whenNotPaused {
        if (essenceCommitment == 0) {
            revert ChronoForge__InsufficientEssenceCommitment();
        }
        if (fulfillmentTimestamp <= block.timestamp) {
            revert ChronoForge__PredictionPastFulfillment();
        }
        if (essenceToken.balanceOf(_msgSender()) < essenceCommitment) {
            revert ChronoForge__InsufficientEssence(essenceCommitment, essenceToken.balanceOf(_msgSender()));
        }

        // Transfer essence to contract
        if (!essenceToken.transferFrom(_msgSender(), address(this), essenceCommitment)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        uint256 currentRequestId = nextPredictionId++;
        predictiveForgeRequests[currentRequestId] = PredictiveForgeRequest({
            requester: _msgSender(),
            essenceCommitment: essenceCommitment,
            fulfillmentTimestamp: fulfillmentTimestamp,
            minimumRarity: minimumRarity,
            fulfilled: false,
            forgedArtifactId: 0
        });

        emit PredictiveForgeRequested(
            currentRequestId,
            _msgSender(),
            essenceCommitment,
            fulfillmentTimestamp,
            minimumRity
        );
    }

    /**
     * @dev Mints the predictive artifact once its `fulfillmentTimestamp` is reached.
     * The artifact's properties are determined by on-chain data at the fulfillment time.
     * @param requestId The ID of the predictive forge request.
     */
    function fulfillPredictiveForge(uint256 requestId)
        external
        nonReentrant
        whenNotPaused
    {
        PredictiveForgeRequest storage request = predictiveForgeRequests[requestId];

        if (request.requester == address(0)) { // Check if request exists
            revert ChronoForge__NoActivePrediction();
        }
        if (request.requester != _msgSender()) { // Only requester can fulfill
            revert ChronoForge__NotOwner(); // Using this error for simplicity
        }
        if (request.fulfilled) {
            revert ChronoForge__PredictionAlreadyFulfilled();
        }
        if (block.timestamp < request.fulfillmentTimestamp) {
            revert ChronoForge__PredictionNotFulfilledYet();
        }

        uint256 currentTokenId = _nextTokenId++;
        _safeMint(request.requester, currentTokenId);

        // Generate artifact signature based on fulfillment time data
        uint256 seed = uint256(keccak256(abi.encodePacked(request.fulfillmentTimestamp, requestId, currentTokenId, blockhash(block.number - 1))));

        TemporalSignature memory newSignature;
        newSignature.originType = uint8(seed % 4);
        newSignature.baseRarity = uint8((seed % 100) + 1); // Rarity based on future seed
        // Ensure minimum rarity is met (or try to)
        if (newSignature.baseRarity < request.minimumRarity) {
            newSignature.baseRarity = uint8(request.minimumRarity);
        }
        newSignature.accetionRatePerSecond = uint32((seed % MAX_ESSENCE_ACCRETION_RATE) + 1);
        newSignature.uniqueSeed = seed;

        // Affinity types (example logic)
        if (newSignature.originType == 0) newSignature.affinityTypes = [1, 3];
        else if (newSignature.originType == 1) newSignature.affinityTypes = [0, 2];
        else if (newSignature.originType == 2) newSignature.affinityTypes = [1, 3];
        else newSignature.affinityTypes = [0, 2];

        string memory metadataURI = string(abi.encodePacked("ipfs://artifact/", currentTokenId.toString(), "/predictive_", requestId.toString(), ".json"));

        temporalArtifacts[currentTokenId] = TemporalArtifact({
            genesisTimestamp: block.timestamp,
            lastAccrualTimestamp: block.timestamp,
            signature: newSignature,
            metadataURI: metadataURI,
            isPaused: false
        });

        // Return committed essence to requester
        if (!essenceToken.transfer(request.requester, request.essenceCommitment)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        request.fulfilled = true;
        request.forgedArtifactId = currentTokenId;

        emit PredictiveForgeFulfilled(requestId, currentTokenId, request.requester, newSignature);
    }

    /**
     * @dev Enables "flash forging." The caller can effectively borrow `essenceCost` from the contract,
     * perform operations within the same transaction (e.g., mutate a just-forged artifact),
     * and must repay the `essenceCost` (plus any fees) before the transaction ends.
     * The `data` parameter will contain encoded function calls to be executed in the flash forge context.
     * @param essenceCost The amount of ChronoEssence that needs to be "borrowed" to forge.
     * @param data Arbitrary data containing instructions for the callback function.
     */
    function initiateFlashForge(uint256 essenceCost, bytes calldata data)
        external
        nonReentrant
        whenNotPaused
    {
        // Require contract to have enough essence to lend
        if (essenceToken.balanceOf(address(this)) < essenceCost) {
            revert ChronoForge__InsufficientEssence(essenceCost, essenceToken.balanceOf(address(this)));
        }

        // Temporarily send essence to the caller
        if (!essenceToken.transfer(msg.sender, essenceCost)) {
            revert ChronoForge__EssenceTransferFailed();
        }

        emit FlashForgeInitiated(_msgSender(), essenceCost);

        // Execute the flash forge callback on the caller's contract
        // The `data` should contain a function selector and arguments for the callback
        // The caller's contract must have a function like `onFlashForge` that handles the logic.
        (bool success, bytes memory result) = _msgSender().call(data);
        require(success, "Flash Forge callback failed");

        // The callback function must ensure the borrowed essence is returned to the contract,
        // typically by burning a newly forged artifact or by transferring essence back.
        // For ChronoForge, the expected repayment is *burning the newly forged artifact*
        // or a direct `essenceToken.transferFrom(msg.sender, address(this), essenceCost + fee)`.

        // The "fee" mechanism for flash forge is crucial. It's usually a small percentage.
        uint256 feeAmount = essenceCost.mul(forgerFeeRate).div(10000);
        uint256 totalRepayAmount = essenceCost.add(feeAmount);

        // Verify repayment: caller must have sent back the essence
        if (essenceToken.balanceOf(address(this)) < essenceCost) { // Check if initial balance + repayment is met
            revert ChronoForge__FlashForgeRepaymentFailed();
        }
        // More robust check: Check actual incoming transfer or specific state change expected by flash forge.
        // This is a simplification. A real flash loan requires the user to explicitly call `transferFrom` back
        // to this contract, or for the callback to handle it.
        // For ChronoForge, the `data` would likely instruct the caller's contract to `forgeNewArtifact`
        // and then immediately `mutateArtifact` (or similar) and *then* the essence token itself is returned.
        // A direct `essenceToken.transferFrom` from caller to this contract is the simplest.
        if (!essenceToken.transferFrom(_msgSender(), address(this), totalRepayAmount)) {
             revert ChronoForge__FlashForgeRepaymentFailed();
        }
    }

    /**
     * @dev Allows an owner to temporarily delegate certain rights (like essence claiming or mutation)
     * for a specific artifact to another address for a limited time.
     * @param tokenId The ID of the artifact.
     * @param delegatee The address to delegate rights to.
     * @param durationInSeconds The duration of the delegation in seconds.
     */
    function delegateTemporalPower(uint256 tokenId, address delegatee, uint256 durationInSeconds)
        external
        nonReentrant
        whenNotPaused
        onlyArtifactOwner(tokenId)
        whenArtifactNotPaused(tokenId)
    {
        if (delegatee == address(0)) {
            revert ChronoForge__DelegationDurationInvalid(); // Or specific invalid delegatee error
        }
        if (durationInSeconds == 0) {
            revert ChronoForge__DelegationDurationInvalid();
        }
        if (temporalDelegations[tokenId].active) {
            revert ChronoForge__DelegationAlreadyActive();
        }

        temporalDelegations[tokenId] = TemporalDelegation({
            delegatee: delegatee,
            expiryTimestamp: block.timestamp.add(durationInSeconds),
            active: true
        });

        emit TemporalPowerDelegated(tokenId, _msgSender(), delegatee, block.timestamp.add(durationInSeconds));
    }

    /**
     * @dev Revokes any active delegation for an artifact.
     * Only the owner can revoke.
     * @param tokenId The ID of the artifact.
     */
    function revokeTemporalPower(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyArtifactOwner(tokenId)
    {
        TemporalDelegation storage delegation = temporalDelegations[tokenId];
        if (!delegation.active) {
            revert ChronoForge__NotDelegated(); // No active delegation to revoke
        }

        delete temporalDelegations[tokenId]; // Clear the delegation
        emit TemporalPowerRevoked(tokenId, _msgSender());
    }

    /**
     * @dev Retrieves full details of a Temporal Artifact.
     * @param tokenId The ID of the artifact.
     * @return A tuple containing all artifact properties.
     */
    function getArtifactDetails(uint256 tokenId)
        public
        view
        returns (
            uint256 genesisTimestamp,
            uint256 lastAccrualTimestamp,
            TemporalSignature memory signature,
            string memory metadataURI,
            bool isPaused
        )
    {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ChronoForge__InvalidTokenId();
        }
        return (
            artifact.genesisTimestamp,
            artifact.lastAccrualTimestamp,
            artifact.signature,
            artifact.metadataURI,
            artifact.isPaused
        );
    }

    /**
     * @dev Calculates a dynamic "power score" for an artifact based on its essence,
     * signature properties, and time. This can be used for ranking or in-game mechanics.
     * @param tokenId The ID of the artifact.
     * @return The calculated power score.
     */
    function getCurrentArtifactPower(uint256 tokenId) public view returns (uint256) {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ChronoForge__InvalidTokenId();
        }

        uint256 accrued = calculatePendingEssence(tokenId); // Include pending essence
        uint256 totalEssenceValue = essenceToken.balanceOf(ownerOf(tokenId)).add(accrued); // Sum of owned + pending

        uint256 power = 0;
        // Base power from rarity
        power = power.add(artifact.signature.baseRarity.mul(100));
        // Power from essence accretion rate
        power = power.add(artifact.signature.accetionRatePerSecond.div(10));
        // Power from total essence (logarithmic or direct, depending on game design)
        power = power.add(totalEssenceValue.div(10**16)); // Scale down total essence
        // Power from age (artifacts gain power over time)
        power = power.add(block.timestamp.sub(artifact.genesisTimestamp).div(1 days)); // 1 point per day

        // Additional power from affinity matches (conceptual, needs external data/oracle)
        // For example, if originType 0 (Solar) and external "solar activity" is high, boost power.
        // This part would typically interact with an oracle. For this example, we keep it internal.
        // Example: if affinity with originType 1 (Lunar) and there's a Lunar artifact sacrificed in mutation, etc.

        return power;
    }

    /**
     * @dev Allows an artifact owner to burn their artifact, potentially receiving a small essence refund.
     * @param tokenId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyArtifactOwner(tokenId)
        whenArtifactNotPaused(tokenId)
    {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];

        // Refund a portion of accrued essence, or a fixed amount, or based on rarity etc.
        uint256 refundAmount = calculatePendingEssence(tokenId).div(2); // Example: 50% refund of pending
        if (refundAmount > 0) {
            if (!essenceToken.mint(_msgSender(), refundAmount)) { // Mint refund to owner
                revert ChronoForge__EssenceTransferFailed();
            }
        }

        _burn(tokenId); // Burn the NFT

        emit ArtifactBurned(tokenId, _msgSender(), refundAmount);
    }

    /**
     * @dev Allows the owner to update the metadata URI for a specific artifact.
     * This is useful for dynamic NFTs whose visual representation or properties change.
     * @param tokenId The ID of the artifact to update.
     * @param newURI The new metadata URI.
     */
    function setArtifactMetadataURI(uint256 tokenId, string calldata newURI)
        external
        onlyArtifactOwner(tokenId)
        whenNotPaused
    {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];
        artifact.metadataURI = newURI;
        emit ArtifactMetadataUpdated(tokenId, newURI);
    }

    /**
     * @dev Allows the owner to pause or unpause a specific artifact.
     * Paused artifacts cannot accrue essence or participate in certain operations.
     * @param tokenId The ID of the artifact to pause/unpause.
     * @param paused True to pause, false to unpause.
     */
    function toggleArtifactPause(uint256 tokenId, bool paused)
        external
        onlyArtifactOwner(tokenId)
        whenNotPaused
    {
        TemporalArtifact storage artifact = temporalArtifacts[tokenId];
        artifact.isPaused = paused;
        // Emit an event if needed
    }

    // --- View Functions (General Information) ---

    /**
     * @dev Returns the total number of Temporal Artifacts minted.
     */
    function getTotalArtifactsMinted() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Returns information about a specific predictive forge request.
     */
    function getPredictiveForgeRequest(uint256 requestId)
        public
        view
        returns (
            address requester,
            uint256 essenceCommitment,
            uint256 fulfillmentTimestamp,
            uint256 minimumRarity,
            bool fulfilled,
            uint256 forgedArtifactId
        )
    {
        PredictiveForgeRequest storage request = predictiveForgeRequests[requestId];
        return (
            request.requester,
            request.essenceCommitment,
            request.fulfillmentTimestamp,
            request.minimumRarity,
            request.fulfilled,
            request.forgedArtifactId
        );
    }

    /**
     * @dev Returns the current active delegation status for an artifact.
     */
    function getTemporalDelegation(uint256 tokenId)
        public
        view
        returns (
            address delegatee,
            uint256 expiryTimestamp,
            bool active
        )
    {
        TemporalDelegation storage delegation = temporalDelegations[tokenId];
        return (
            delegation.delegatee,
            delegation.expiryTimestamp,
            delegation.active && delegation.expiryTimestamp >= block.timestamp
        );
    }

    /**
     * @dev Returns the current active lending status for an artifact.
     */
    function getTemporalLendStatus(uint256 tokenId)
        public
        view
        returns (
            address lender,
            address borrower,
            uint256 startTime,
            uint256 endTime,
            uint256 essenceRatePerSecond,
            bool active
        )
    {
        TemporalLend storage lend = temporalLends[tokenId];
        return (
            lend.lender,
            lend.borrower,
            lend.startTime,
            lend.endTime,
            lend.essenceRatePerSecond,
            lend.active
        );
    }
}
```