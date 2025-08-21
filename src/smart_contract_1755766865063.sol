This smart contract, "Chronicle of Epochs," introduces a novel concept around **decentralized identity, evolving digital assets, and on-chain narrative progression**. It combines elements of Soulbound Tokens (SBTs), dynamic NFTs, time-gated challenges, and a reputation-based attestation system, all powered by an internal utility token.

The core idea is that users possess a unique, non-transferable "Essence" representing their on-chain identity and reputation. This Essence evolves through participation in "Chronicles" (multi-stage, time-gated challenges) and through "Attestations" from verified entities. As their Essence grows, users can "manifest" dynamic "Echoes"—NFTs whose metadata and characteristics evolve based on the user's Essence level and completed achievements.

---

## Chronicle of Epochs: Outline and Function Summary

This contract represents a sophisticated on-chain ecosystem designed for progressive digital identity and evolving digital assets.

### I. Core Components

1.  **Essence (Soulbound Token - SBT):** A non-transferable ERC-721 token representing a user's fundamental on-chain identity and reputation. It cannot be sold or transferred.
2.  **Echoes (Dynamic NFTs):** ERC-721 tokens that are mutable. Their appearance, traits, and utility evolve based on the owner's `Essence` level and completed `Chronicles`.
3.  **Chronicles (Time-Gated Challenges):** Multi-stage quests or challenges that users can participate in to earn rewards, increase their `Essence` level, and unlock `Echo` evolutions.
4.  **Aether (ERC-20 Utility Token):** An fungible token used for various ecosystem interactions, such as paying for `Echo` evolutions, staking for boosts, or earning as rewards.
5.  **Attestation System:** A mechanism for verified `Verifiers` (e.g., reputable DAOs, identity providers, specific event organizers) to attest to specific qualities or achievements of an `Essence` holder, further impacting their reputation and `Essence` level.
6.  **Protocol Governance:** A basic multi-sig or timelock mechanism for critical updates and parameter changes.

### II. Function Summary (25+ Functions)

#### A. Essence Management (Soulbound Identity)

1.  `attuneEssence(string memory _initialMetadataURI)`: Mints a new Essence token for the calling address if they don't already have one. This is their foundational on-chain identity.
2.  `updateEssenceProfile(string memory _newMetadataURI)`: Allows an Essence holder to update their associated metadata (e.g., profile picture, description).
3.  `getEssenceDetails(address _owner) view`: Retrieves the current level, XP, and metadata URI of a user's Essence.
4.  `burnEssence()`: Allows an Essence holder to irreversibly destroy their Essence (a drastic, high-consequence action).
5.  `getEssenceTokenId(address _owner) view`: Returns the tokenId of an Essence owned by an address.

#### B. Echoes Management (Dynamic NFTs)

6.  `manifestEcho(string memory _initialMetadataURI)`: Mints a new Echo token. Requires a minimum Essence level and potentially Aether payment. The Echo's initial state is influenced by the current Essence level.
7.  `evolveEcho(uint256 _echoId, string memory _newMetadataURI)`: Triggers an evolution of an existing Echo token. This can be unlocked by achieving specific Essence levels or completing certain Chronicles. May require Aether.
8.  `mergeEchoes(uint256 _echoId1, uint256 _echoId2, string memory _newMetadataURI)`: Allows combining two Echoes into a single, potentially more powerful/rare Echo. This operation is complex and likely has specific rules and Aether costs.
9.  `shatterEcho(uint256 _echoId)`: Destroys an Echo token and rewards the owner with a certain amount of Aether, potentially based on the Echo's evolved state.
10. `getEchoDetails(uint256 _echoId) view`: Retrieves the current metadata URI, evolution stage, and owner of an Echo.
11. `getCurrentEchoEvolutionRequirements(uint256 _echoId) view`: Returns the Essence level or Chronicle completion required for the next evolution stage of a given Echo.

#### C. Chronicles (Time-Gated Challenges)

12. `createChronicle(string memory _name, string memory _description, uint256 _aetherReward, uint256 _essenceXPBoost, uint256 _requiredEssenceLevel, uint256 _durationPerStage, uint256 _totalStages)`: Admin function to define a new multi-stage Chronicle.
13. `joinChronicle(uint256 _chronicleId)`: Allows an Essence holder to opt into a specific Chronicle. Requires meeting the Chronicle's Essence level prerequisites.
14. `submitChronicleStageProof(uint256 _chronicleId, uint256 _stageIndex, bytes32 _proofHash)`: User submits proof (e.g., a hash of an off-chain action, or a specific on-chain transaction hash) for a Chronicle stage. Verifiers might confirm this.
15. `completeChronicle(uint256 _chronicleId)`: Finalizes a Chronicle for a user after all stages are submitted and verified. Distributes Aether and Essence XP rewards.
16. `getChronicleProgress(uint256 _chronicleId, address _participant) view`: Retrieves the current stage and completion status for a participant in a Chronicle.
17. `getChronicleDetails(uint256 _chronicleId) view`: Returns the full details of a Chronicle, including its stages, rewards, and requirements.

#### D. Attestation System

18. `registerVerifier(address _verifierAddress, string memory _name)`: Admin/governance function to register a new authorized attester entity.
19. `attestToEssence(address _essenceOwner, uint256 _essenceXPGain, string memory _attestationURI)`: A registered `Verifier` grants an Essence owner specific XP and provides an attestation URI (e.g., link to evidence).
20. `revokeAttestation(address _essenceOwner, uint256 _attestationIndex)`: A `Verifier` can revoke a previously issued attestation, potentially reducing Essence XP.
21. `getEssenceAttestations(address _essenceOwner) view`: Retrieves a list of all attestations received by an Essence owner.

#### E. Aether (ERC-20 Utility Token)

22. `distributeAether(address _to, uint256 _amount)`: Internal function called to distribute Aether rewards (e.g., from Chronicle completion, Echo shattering).
23. `stakeAetherForBoost(uint256 _amount)`: Users can stake Aether to gain temporary boosts (e.g., faster Chronicle progression, reduced Echo evolution costs).
24. `redeemStakedAether()`: Allows users to withdraw their staked Aether after a cooldown period.
25. `getAetherBalance(address _account) view`: Standard ERC-20 balance check. (Inherited from ERC20).

#### F. Protocol Governance & Administration

26. `setProtocolFee(uint256 _newFee)`: Sets the percentage fee for certain operations (e.g., Echo minting, evolution) that goes to the protocol treasury.
27. `setEssenceLevelThresholds(uint256[] memory _thresholds)`: Admin function to define the XP thresholds required for each Essence level.
28. `pauseContract()`: Emergency function to pause critical contract functionalities.
29. `unpauseContract()`: Unpauses the contract.
30. `withdrawProtocolFees(address _to)`: Allows the protocol owner/treasury to withdraw accumulated Aether fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Custom Error Definitions ---
error NotEssenceHolder(address caller);
error EssenceAlreadyExists(address owner);
error InvalidEssenceTokenId(uint256 tokenId);
error EssenceDoesNotExist(address owner);
error CannotTransferEssence();
error CallerNotVerifier(address caller);
error VerifierAlreadyRegistered(address verifier);
error InvalidChronicleId(uint256 chronicleId);
error ChronicleAlreadyJoined(address participant, uint256 chronicleId);
error NotParticipantInChronicle(address participant, uint256 chronicleId);
error ChronicleStageNotActive(uint256 chronicleId, uint256 stageIndex);
error ChronicleStageAlreadyCompleted(uint256 chronicleId, uint256 stageIndex);
error ChronicleNotReadyForCompletion(uint256 chronicleId);
error EchoDoesNotExist(uint256 echoId);
error NotEchoOwner(address caller, uint256 echoId);
error InsufficientEssenceLevel(uint256 currentLevel, uint256 requiredLevel);
error InsufficientAether(uint256 currentBalance, uint256 requiredAmount);
error EchoAlreadyAtMaxEvolution(uint256 echoId);
error ChronicleRequirementsNotMet(string reason);
error NoStakedAether(address staker);
error StakingLockupActive(uint256 unlockTime);
error NotEnoughStakedAether(uint256 current, uint256 requested);
error NotAuthorized();

// --- SoulboundERC721: A non-transferable ERC721 token for Essence ---
contract SoulboundERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Override _approve to prevent transfers
    function _approve(address to, uint256 tokenId) internal override {
        revert CannotTransferEssence();
    }

    // Override transferFrom to prevent transfers
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert CannotTransferEssence();
    }

    // Override safeTransferFrom to prevent transfers
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert CannotTransferEssence();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert CannotTransferEssence();
    }

    // Custom internal mint function
    function _mintEssence(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    // Custom internal burn function
    function _burnEssence(uint256 tokenId) internal {
        _burn(tokenId);
    }
}

// --- DynamicERC721: An ERC721 token whose metadata can be evolved ---
contract DynamicERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Mapping to store mutable token URIs
    mapping(uint256 => string) private _tokenUris;

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenUris[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenUris[tokenId];
    }
}


contract ChronicleOfEpochs is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Contracts
    SoulboundERC721 public essenceContract;
    DynamicERC721 public echoesContract;
    ERC20 public aetherToken;

    // Counters for unique IDs
    Counters.Counter private _essenceTokenIds;
    Counters.Counter private _echoTokenIds;
    Counters.Counter private _chronicleIds;

    // --- Essence (Soulbound Token) ---
    struct EssenceProfile {
        uint256 tokenId;
        uint256 level;
        uint256 xp;
        string metadataURI;
        uint256 lastAttestationTime; // For potential cooldowns or decay
    }
    mapping(address => EssenceProfile) public essenceProfiles;
    mapping(address => uint256) public essenceAddressToTokenId; // Quick lookup
    mapping(uint256 => address) public essenceTokenIdToAddress; // Quick lookup

    uint256[] public essenceLevelThresholds; // XP needed for each level
    uint256 public constant MAX_ESSENCE_LEVEL = 100;

    // --- Echoes (Dynamic NFTs) ---
    struct EchoDetails {
        uint256 currentEvolutionStage;
        uint256 lastEvolutionTime;
        // Add more evolution-specific data if needed
    }
    mapping(uint256 => EchoDetails) public echoDetails; // echoId => details

    uint256 public echoMintCostAether;
    uint256 public echoEvolutionCostAether;

    // --- Chronicles (Time-Gated Challenges) ---
    struct Chronicle {
        string name;
        string description;
        uint256 aetherReward;
        uint256 essenceXPBoost;
        uint256 requiredEssenceLevel;
        uint256 durationPerStage; // in seconds
        uint256 totalStages;
        bool active;
    }
    mapping(uint256 => Chronicle) public chronicles; // chronicleId => Chronicle details

    struct ChronicleParticipation {
        uint256 currentStage; // 0-indexed
        uint256 lastStageCompletionTime;
        bool completed;
        bool[] stageProofsSubmitted; // Tracks if proof for each stage is submitted
    }
    mapping(uint256 => mapping(address => ChronicleParticipation)) public chronicleParticipations; // chronicleId => participantAddress => participation details

    // --- Attestation System ---
    struct Attestation {
        address verifier;
        uint256 xpGain;
        string attestationURI;
        uint256 timestamp;
    }
    mapping(address => Attestation[]) public essenceAttestations; // essenceOwner => array of attestations
    mapping(address => bool) public registeredVerifiers; // address => isVerifier?

    // --- Aether (ERC-20 Utility Token) ---
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500/10000)
    address public protocolTreasury;

    // Aether Staking for Boosts
    struct StakedAether {
        uint256 amount;
        uint256 stakeTime;
        uint256 unlockTime;
    }
    mapping(address => StakedAether) public stakedAether;
    uint256 public stakingLockupDuration = 30 days; // Default lockup period

    // --- Pause functionality ---
    bool public paused = false;

    // --- Events ---
    event EssenceAttuned(address indexed owner, uint256 tokenId, string initialMetadataURI);
    event EssenceProfileUpdated(address indexed owner, uint256 tokenId, string newMetadataURI);
    event EssenceBurned(address indexed owner, uint256 tokenId);
    event EssenceLeveledUp(address indexed owner, uint256 newLevel, uint256 totalXP);

    event EchoManifested(address indexed owner, uint256 echoId, string initialMetadataURI);
    event EchoEvolved(address indexed owner, uint256 echoId, uint256 newEvolutionStage, string newMetadataURI);
    event EchoMerged(address indexed owner, uint256 newEchoId, uint256 mergedEchoId1, uint256 mergedEchoId2);
    event EchoShattered(address indexed owner, uint256 echoId, uint256 aetherRefunded);

    event ChronicleCreated(uint256 indexed chronicleId, string name, address indexed creator);
    event ChronicleJoined(uint256 indexed chronicleId, address indexed participant);
    event ChronicleStageProgressed(uint256 indexed chronicleId, address indexed participant, uint256 stageIndex, bytes32 proofHash);
    event ChronicleCompleted(uint256 indexed chronicleId, address indexed participant, uint256 aetherReward, uint256 essenceXPBoost);

    event VerifierRegistered(address indexed verifierAddress, string name);
    event AttestationGranted(address indexed verifier, address indexed essenceOwner, uint256 xpGain, string attestationURI);
    event AttestationRevoked(address indexed verifier, address indexed essenceOwner, uint256 attestationIndex);

    event AetherStaked(address indexed staker, uint256 amount, uint256 unlockTime);
    event AetherRedeemed(address indexed staker, uint256 amount);

    event ProtocolFeeSet(uint256 newFeePercentage);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event EssenceLevelThresholdsSet(uint256[] thresholds);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyEssenceHolder(address _addr) {
        require(essenceAddressToTokenId[_addr] != 0, "Not an Essence holder");
        _;
    }

    modifier onlyVerifier() {
        require(registeredVerifiers[msg.sender], "Caller is not a registered Verifier");
        _;
    }

    modifier onlyAdmin() {
        require(owner() == msg.sender, "Only owner can call this function");
        _;
    }

    // --- Constructor ---
    constructor(
        address _essenceContractAddress,
        address _echoesContractAddress,
        address _aetherTokenAddress,
        uint256 _initialEchoMintCostAether,
        uint256 _initialEchoEvolutionCostAether,
        uint256 _initialProtocolFeePercentage,
        address _initialProtocolTreasury
    ) Ownable(msg.sender) {
        essenceContract = SoulboundERC721(_essenceContractAddress);
        echoesContract = DynamicERC721(_echoesContractAddress);
        aetherToken = ERC20(_aetherTokenAddress);

        echoMintCostAether = _initialEchoMintCostAether;
        echoEvolutionCostAether = _initialEchoEvolutionCostAether;
        protocolFeePercentage = _initialProtocolFeePercentage;
        protocolTreasury = _initialProtocolTreasury;

        // Initialize essence level thresholds (example values)
        // Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, etc.
        essenceLevelThresholds = [0, 100, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000];
    }

    // --- A. Essence Management (Soulbound Identity) ---

    /**
     * @dev Mints a new Essence token for the calling address.
     *      A user can only have one Essence.
     * @param _initialMetadataURI The initial URI for the Essence token's metadata.
     */
    function attuneEssence(string memory _initialMetadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        if (essenceAddressToTokenId[msg.sender] != 0) {
            revert EssenceAlreadyExists(msg.sender);
        }

        _essenceTokenIds.increment();
        uint256 newTokenId = _essenceTokenIds.current();

        essenceContract._mintEssence(msg.sender, newTokenId);

        essenceProfiles[msg.sender] = EssenceProfile({
            tokenId: newTokenId,
            level: 1, // Start at level 1
            xp: 0,
            metadataURI: _initialMetadataURI,
            lastAttestationTime: block.timestamp
        });
        essenceAddressToTokenId[msg.sender] = newTokenId;
        essenceTokenIdToAddress[newTokenId] = msg.sender;

        emit EssenceAttuned(msg.sender, newTokenId, _initialMetadataURI);
    }

    /**
     * @dev Allows an Essence holder to update their associated metadata URI.
     * @param _newMetadataURI The new URI for the Essence token's metadata.
     */
    function updateEssenceProfile(string memory _newMetadataURI)
        external
        whenNotPaused
        onlyEssenceHolder(msg.sender)
    {
        EssenceProfile storage profile = essenceProfiles[msg.sender];
        profile.metadataURI = _newMetadataURI;

        emit EssenceProfileUpdated(msg.sender, profile.tokenId, _newMetadataURI);
    }

    /**
     * @dev Allows an Essence holder to irreversibly destroy their Essence.
     *      This is a high-consequence action.
     */
    function burnEssence()
        external
        whenNotPaused
        nonReentrant
        onlyEssenceHolder(msg.sender)
    {
        EssenceProfile storage profile = essenceProfiles[msg.sender];
        uint256 tokenId = profile.tokenId;

        essenceContract._burnEssence(tokenId);

        delete essenceProfiles[msg.sender];
        delete essenceAddressToTokenId[msg.sender];
        delete essenceTokenIdToAddress[tokenId];

        emit EssenceBurned(msg.sender, tokenId);
    }

    /**
     * @dev Retrieves the current details of an Essence.
     * @param _owner The address of the Essence holder.
     * @return tokenId, level, xp, metadataURI
     */
    function getEssenceDetails(address _owner)
        external
        view
        returns (uint256 tokenId, uint256 level, uint256 xp, string memory metadataURI)
    {
        if (essenceAddressToTokenId[_owner] == 0) {
            revert EssenceDoesNotExist(_owner);
        }
        EssenceProfile storage profile = essenceProfiles[_owner];
        return (profile.tokenId, profile.level, profile.xp, profile.metadataURI);
    }

    /**
     * @dev Returns the tokenId of an Essence owned by an address.
     * @param _owner The address to query.
     * @return The tokenId, or 0 if no Essence exists.
     */
    function getEssenceTokenId(address _owner) external view returns (uint256) {
        return essenceAddressToTokenId[_owner];
    }

    /**
     * @dev Checks if an address has an Essence.
     * @param _owner The address to check.
     * @return True if the address has an Essence, false otherwise.
     */
    function hasEssence(address _owner) public view returns (bool) {
        return essenceAddressToTokenId[_owner] != 0;
    }

    /**
     * @dev Internal function to update Essence XP and level.
     */
    function _updateEssenceXP(address _essenceOwner, uint256 _xpGain) internal {
        EssenceProfile storage profile = essenceProfiles[_essenceOwner];
        profile.xp += _xpGain;

        uint256 newLevel = profile.level;
        while (newLevel < MAX_ESSENCE_LEVEL && profile.xp >= essenceLevelThresholds[newLevel]) {
            newLevel++;
        }

        if (newLevel > profile.level) {
            profile.level = newLevel;
            emit EssenceLeveledUp(_essenceOwner, newLevel, profile.xp);
        }
        profile.lastAttestationTime = block.timestamp;
    }

    // --- B. Echoes Management (Dynamic NFTs) ---

    /**
     * @dev Mints a new Echo token for the calling address.
     * Requires a minimum Essence level and Aether payment.
     * The Echo's initial state is influenced by the current Essence level.
     * @param _initialMetadataURI The initial URI for the Echo token's metadata.
     */
    function manifestEcho(string memory _initialMetadataURI)
        external
        whenNotPaused
        nonReentrant
        onlyEssenceHolder(msg.sender)
    {
        EssenceProfile storage essence = essenceProfiles[msg.sender];
        require(essence.level >= 1, "Essence level must be at least 1 to manifest Echo"); // Or a higher specific level

        uint256 fee = (echoMintCostAether * protocolFeePercentage) / 10000;
        require(aetherToken.balanceOf(msg.sender) >= echoMintCostAether, InsufficientAether(aetherToken.balanceOf(msg.sender), echoMintCostAether));
        aetherToken.transferFrom(msg.sender, protocolTreasury, fee);
        aetherToken.transferFrom(msg.sender, address(this), echoMintCostAether - fee); // Aether is burned or used internally

        _echoTokenIds.increment();
        uint256 newEchoId = _echoTokenIds.current();

        echoesContract._safeMint(msg.sender, newEchoId);
        echoesContract._setTokenURI(newEchoId, _initialMetadataURI); // Set initial URI

        echoDetails[newEchoId] = EchoDetails({
            currentEvolutionStage: 1, // Start at stage 1
            lastEvolutionTime: block.timestamp
        });

        emit EchoManifested(msg.sender, newEchoId, _initialMetadataURI);
    }

    /**
     * @dev Triggers an evolution of an existing Echo token.
     * This can be unlocked by achieving specific Essence levels or completing certain Chronicles.
     * May require Aether.
     * @param _echoId The ID of the Echo to evolve.
     * @param _newMetadataURI The new URI for the Echo token's metadata after evolution.
     */
    function evolveEcho(uint256 _echoId, string memory _newMetadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        require(echoesContract.ownerOf(_echoId) == msg.sender, NotEchoOwner(msg.sender, _echoId));
        require(echoDetails[_echoId].currentEvolutionStage < 5, EchoAlreadyAtMaxEvolution(_echoId)); // Example max stages

        // Example logic: Requires certain Essence level and Aether
        EssenceProfile storage essence = essenceProfiles[msg.sender];
        uint256 requiredEssenceLevel = echoDetails[_echoId].currentEvolutionStage * 5; // Example: Level 5 for stage 2, 10 for stage 3 etc.
        require(essence.level >= requiredEssenceLevel, InsufficientEssenceLevel(essence.level, requiredEssenceLevel));

        uint256 fee = (echoEvolutionCostAether * protocolFeePercentage) / 10000;
        require(aetherToken.balanceOf(msg.sender) >= echoEvolutionCostAether, InsufficientAether(aetherToken.balanceOf(msg.sender), echoEvolutionCostAether));
        aetherToken.transferFrom(msg.sender, protocolTreasury, fee);
        aetherToken.transferFrom(msg.sender, address(this), echoEvolutionCostAether - fee); // Aether is burned or used internally

        echoDetails[_echoId].currentEvolutionStage++;
        echoDetails[_echoId].lastEvolutionTime = block.timestamp;
        echoesContract._setTokenURI(_echoId, _newMetadataURI);

        emit EchoEvolved(msg.sender, _echoId, echoDetails[_echoId].currentEvolutionStage, _newMetadataURI);
    }

    /**
     * @dev Allows combining two Echoes into a single, potentially more powerful/rare Echo.
     * This operation is complex and likely has specific rules and Aether costs.
     * For this example, it's a placeholder for complex on-chain logic.
     * @param _echoId1 The ID of the first Echo to merge.
     * @param _echoId2 The ID of the second Echo to merge.
     * @param _newMetadataURI The metadata URI for the resulting merged Echo.
     */
    function mergeEchoes(uint256 _echoId1, uint256 _echoId2, string memory _newMetadataURI)
        external
        whenNotPaused
        nonReentrant
    {
        require(echoesContract.ownerOf(_echoId1) == msg.sender, NotEchoOwner(msg.sender, _echoId1));
        require(echoesContract.ownerOf(_echoId2) == msg.sender, NotEchoOwner(msg.sender, _echoId2));
        require(_echoId1 != _echoId2, "Cannot merge an Echo with itself");

        // --- Complex merge logic would go here ---
        // Example: Check specific evolution stages, traits, etc.
        // uint256 cost = calculateMergeCost(_echoId1, _echoId2);
        // require(aetherToken.transferFrom(msg.sender, address(this), cost), "Aether transfer failed for merge");

        // Burn the two input Echoes
        echoesContract.burn(_echoId1);
        echoesContract.burn(_echoId2);
        delete echoDetails[_echoId1];
        delete echoDetails[_echoId2];


        _echoTokenIds.increment();
        uint256 newEchoId = _echoTokenIds.current();

        echoesContract._safeMint(msg.sender, newEchoId);
        echoesContract._setTokenURI(newEchoId, _newMetadataURI);

        echoDetails[newEchoId] = EchoDetails({
            currentEvolutionStage: 1, // Start at stage 1 or derived from merge
            lastEvolutionTime: block.timestamp
        });

        emit EchoMerged(msg.sender, newEchoId, _echoId1, _echoId2);
    }

    /**
     * @dev Destroys an Echo token and rewards the owner with a certain amount of Aether,
     * potentially based on the Echo's evolved state.
     * @param _echoId The ID of the Echo to shatter.
     */
    function shatterEcho(uint256 _echoId)
        external
        whenNotPaused
        nonReentrant
    {
        require(echoesContract.ownerOf(_echoId) == msg.sender, NotEchoOwner(msg.sender, _echoId));

        uint256 aetherRefund = echoDetails[_echoId].currentEvolutionStage * 100; // Example: more Aether for higher evolution
        echoesContract.burn(_echoId);
        delete echoDetails[_echoId];

        _distributeAether(msg.sender, aetherRefund);

        emit EchoShattered(msg.sender, _echoId, aetherRefund);
    }

    /**
     * @dev Retrieves the current metadata URI, evolution stage, and owner of an Echo.
     * @param _echoId The ID of the Echo.
     * @return owner, currentEvolutionStage, lastEvolutionTime, metadataURI
     */
    function getEchoDetails(uint256 _echoId)
        external
        view
        returns (address owner, uint256 currentEvolutionStage, uint256 lastEvolutionTime, string memory metadataURI)
    {
        require(echoesContract.exists(_echoId), EchoDoesNotExist(_echoId));
        EchoDetails storage details = echoDetails[_echoId];
        return (echoesContract.ownerOf(_echoId), details.currentEvolutionStage, details.lastEvolutionTime, echoesContract.tokenURI(_echoId));
    }

    /**
     * @dev Returns the Essence level or Chronicle completion required for the next evolution stage of a given Echo.
     * @param _echoId The ID of the Echo.
     * @return requiredEssenceLevel, requiredChronicleId (0 if none)
     */
    function getCurrentEchoEvolutionRequirements(uint256 _echoId)
        external
        view
        returns (uint256 requiredEssenceLevel, uint256 requiredChronicleId)
    {
        require(echoesContract.exists(_echoId), EchoDoesNotExist(_echoId));
        uint256 nextStage = echoDetails[_echoId].currentEvolutionStage + 1;

        if (nextStage > 5) { // Example: Max stages
            return (0, 0); // Already at max evolution
        }

        // Example logic for requirements
        requiredEssenceLevel = nextStage * 5; // e.g., Stage 2 needs Essence L10, Stage 3 needs L15
        requiredChronicleId = 0; // Placeholder: could return a specific chronicle ID

        return (requiredEssenceLevel, requiredChronicleId);
    }


    // --- C. Chronicles (Time-Gated Challenges) ---

    /**
     * @dev Creates a new multi-stage Chronicle. Only callable by the contract owner.
     * @param _name Name of the Chronicle.
     * @param _description Description of the Chronicle.
     * @param _aetherReward Aether rewarded upon completion.
     * @param _essenceXPBoost Essence XP awarded upon completion.
     * @param _requiredEssenceLevel Minimum Essence level to join.
     * @param _durationPerStage Duration in seconds for each stage.
     * @param _totalStages Total number of stages in the Chronicle.
     */
    function createChronicle(
        string memory _name,
        string memory _description,
        uint256 _aetherReward,
        uint256 _essenceXPBoost,
        uint256 _requiredEssenceLevel,
        uint256 _durationPerStage,
        uint256 _totalStages
    ) external onlyOwner whenNotPaused {
        _chronicleIds.increment();
        uint256 newChronicleId = _chronicleIds.current();

        chronicles[newChronicleId] = Chronicle({
            name: _name,
            description: _description,
            aetherReward: _aetherReward,
            essenceXPBoost: _essenceXPBoost,
            requiredEssenceLevel: _requiredEssenceLevel,
            durationPerStage: _durationPerStage,
            totalStages: _totalStages,
            active: true
        });

        emit ChronicleCreated(newChronicleId, _name, msg.sender);
    }

    /**
     * @dev Allows an Essence holder to opt into a specific Chronicle.
     * Requires meeting the Chronicle's Essence level prerequisites.
     * @param _chronicleId The ID of the Chronicle to join.
     */
    function joinChronicle(uint256 _chronicleId)
        external
        whenNotPaused
        nonReentrant
        onlyEssenceHolder(msg.sender)
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.active, InvalidChronicleId(_chronicleId)); // Use active status to validate ID
        require(chronicleParticipations[_chronicleId][msg.sender].currentStage == 0 &&
                !chronicleParticipations[_chronicleId][msg.sender].completed,
                ChronicleAlreadyJoined(msg.sender, _chronicleId));

        EssenceProfile storage essence = essenceProfiles[msg.sender];
        require(essence.level >= chronicle.requiredEssenceLevel,
                ChronicleRequirementsNotMet("Insufficient Essence level to join this Chronicle"));

        chronicleParticipations[_chronicleId][msg.sender] = ChronicleParticipation({
            currentStage: 0,
            lastStageCompletionTime: block.timestamp, // Start time for stage 0
            completed: false,
            stageProofsSubmitted: new bool[](chronicle.totalStages)
        });

        emit ChronicleJoined(_chronicleId, msg.sender);
    }

    /**
     * @dev User submits proof for a Chronicle stage.
     * This proof might be a hash of an off-chain action, or a specific on-chain transaction hash.
     * @param _chronicleId The ID of the Chronicle.
     * @param _stageIndex The 0-indexed stage number for which proof is being submitted.
     * @param _proofHash A hash representing the proof of completion for the stage.
     */
    function submitChronicleStageProof(uint256 _chronicleId, uint256 _stageIndex, bytes32 _proofHash)
        external
        whenNotPaused
        nonReentrant
        onlyEssenceHolder(msg.sender)
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.active, InvalidChronicleId(_chronicleId));

        ChronicleParticipation storage participant = chronicleParticipations[_chronicleId][msg.sender];
        require(participant.currentStage == _stageIndex, ChronicleStageNotActive(_chronicleId, _stageIndex));
        require(!participant.completed, "Chronicle already completed");
        require(_stageIndex < chronicle.totalStages, "Invalid stage index");
        require(!participant.stageProofsSubmitted[_stageIndex], ChronicleStageAlreadyCompleted(_chronicleId, _stageIndex));

        // Time gate for current stage completion
        require(block.timestamp >= participant.lastStageCompletionTime + chronicle.durationPerStage, "Time lock for stage not elapsed");

        // In a real scenario, _proofHash might be verified against some oracle or internal state.
        // For this example, we just mark it as submitted.

        participant.stageProofsSubmitted[_stageIndex] = true;
        participant.currentStage++; // Move to the next stage
        participant.lastStageCompletionTime = block.timestamp; // Reset timer for next stage

        emit ChronicleStageProgressed(_chronicleId, msg.sender, _stageIndex, _proofHash);
    }

    /**
     * @dev Finalizes a Chronicle for a user after all stages are submitted.
     * Distributes Aether and Essence XP rewards.
     * @param _chronicleId The ID of the Chronicle to complete.
     */
    function completeChronicle(uint256 _chronicleId)
        external
        whenNotPaused
        nonReentrant
        onlyEssenceHolder(msg.sender)
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.active, InvalidChronicleId(_chronicleId));

        ChronicleParticipation storage participant = chronicleParticipations[_chronicleId][msg.sender];
        require(participant.currentStage == chronicle.totalStages, ChronicleNotReadyForCompletion(_chronicleId));
        require(!participant.completed, "Chronicle already completed");

        participant.completed = true;

        _distributeAether(msg.sender, chronicle.aetherReward);
        _updateEssenceXP(msg.sender, chronicle.essenceXPBoost);

        emit ChronicleCompleted(_chronicleId, msg.sender, chronicle.aetherReward, chronicle.essenceXPBoost);
    }

    /**
     * @dev Retrieves the current stage and completion status for a participant in a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @param _participant The address of the participant.
     * @return currentStage, completed, totalStages, lastStageCompletionTime, stageProofsSubmitted (array of bool)
     */
    function getChronicleProgress(uint256 _chronicleId, address _participant)
        external
        view
        returns (uint256 currentStage, bool completed, uint256 totalStages, uint256 lastStageCompletionTime, bool[] memory stageProofsSubmitted)
    {
        require(chronicles[_chronicleId].active, InvalidChronicleId(_chronicleId));
        require(chronicleParticipations[_chronicleId][_participant].lastStageCompletionTime != 0, NotParticipantInChronicle(_participant, _chronicleId));

        ChronicleParticipation storage participant = chronicleParticipations[_chronicleId][_participant];
        return (participant.currentStage, participant.completed, chronicles[_chronicleId].totalStages, participant.lastStageCompletionTime, participant.stageProofsSubmitted);
    }

    /**
     * @dev Returns the full details of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return name, description, aetherReward, essenceXPBoost, requiredEssenceLevel, durationPerStage, totalStages, active
     */
    function getChronicleDetails(uint256 _chronicleId)
        external
        view
        returns (string memory name, string memory description, uint256 aetherReward, uint256 essenceXPBoost, uint256 requiredEssenceLevel, uint256 durationPerStage, uint256 totalStages, bool active)
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.active, InvalidChronicleId(_chronicleId)); // Check if Chronicle exists by active status
        return (chronicle.name, chronicle.description, chronicle.aetherReward, chronicle.essenceXPBoost, chronicle.requiredEssenceLevel, chronicle.durationPerStage, chronicle.totalStages, chronicle.active);
    }

    // --- D. Attestation System ---

    /**
     * @dev Registers a new authorized attester entity. Only callable by the contract owner.
     * @param _verifierAddress The address to register as a Verifier.
     * @param _name A descriptive name for the Verifier.
     */
    function registerVerifier(address _verifierAddress, string memory _name) external onlyOwner whenNotPaused {
        require(!registeredVerifiers[_verifierAddress], VerifierAlreadyRegistered(_verifierAddress));
        registeredVerifiers[_verifierAddress] = true;
        emit VerifierRegistered(_verifierAddress, _name);
    }

    /**
     * @dev A registered Verifier grants an Essence owner specific XP and provides an attestation URI.
     * @param _essenceOwner The address of the Essence holder to attest to.
     * @param _xpGain The amount of Essence XP to grant.
     * @param _attestationURI A URI linking to evidence or details of the attestation.
     */
    function attestToEssence(address _essenceOwner, uint256 _xpGain, string memory _attestationURI)
        external
        whenNotPaused
        nonReentrant
        onlyVerifier
        onlyEssenceHolder(_essenceOwner)
    {
        Attestation memory newAttestation = Attestation({
            verifier: msg.sender,
            xpGain: _xpGain,
            attestationURI: _attestationURI,
            timestamp: block.timestamp
        });

        essenceAttestations[_essenceOwner].push(newAttestation);
        _updateEssenceXP(_essenceOwner, _xpGain);

        emit AttestationGranted(msg.sender, _essenceOwner, _xpGain, _attestationURI);
    }

    /**
     * @dev A Verifier can revoke a previously issued attestation, potentially reducing Essence XP.
     * For simplicity, this example just marks it, a real system might remove XP.
     * @param _essenceOwner The address of the Essence holder.
     * @param _attestationIndex The index of the attestation to revoke in the array.
     */
    function revokeAttestation(address _essenceOwner, uint256 _attestationIndex)
        external
        whenNotPaused
        nonReentrant
        onlyVerifier
        onlyEssenceHolder(_essenceOwner)
    {
        require(_attestationIndex < essenceAttestations[_essenceOwner].length, "Invalid attestation index");
        require(essenceAttestations[_essenceOwner][_attestationIndex].verifier == msg.sender, "Caller not the original verifier");

        // In a more complex system, this would also deduct XP
        // For simplicity, we just mark it as revoked (by zeroing XP and URI)
        Attestation storage attestation = essenceAttestations[_essenceOwner][_attestationIndex];
        attestation.xpGain = 0; // Effectively remove the XP
        attestation.attestationURI = ""; // Clear the URI

        emit AttestationRevoked(msg.sender, _essenceOwner, _attestationIndex);
    }

    /**
     * @dev Retrieves a list of all attestations received by an Essence owner.
     * @param _essenceOwner The address of the Essence holder.
     * @return An array of Attestation structs.
     */
    function getEssenceAttestations(address _essenceOwner)
        external
        view
        returns (Attestation[] memory)
    {
        return essenceAttestations[_essenceOwner];
    }

    // --- E. Aether (ERC-20 Utility Token) ---

    /**
     * @dev Internal function to distribute Aether rewards.
     * @param _to The recipient of the Aether.
     * @param _amount The amount of Aether to distribute.
     */
    function _distributeAether(address _to, uint256 _amount) internal {
        require(aetherToken.transfer(_to, _amount), "Aether distribution failed");
    }

    /**
     * @dev Allows users to stake Aether to gain temporary boosts.
     * @param _amount The amount of Aether to stake.
     */
    function stakeAetherForBoost(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(aetherToken.balanceOf(msg.sender) >= _amount, InsufficientAether(aetherToken.balanceOf(msg.sender), _amount));

        // Transfer Aether to this contract
        aetherToken.transferFrom(msg.sender, address(this), _amount);

        // Update staked amount and set unlock time
        stakedAether[msg.sender].amount += _amount;
        stakedAether[msg.sender].stakeTime = block.timestamp;
        stakedAether[msg.sender].unlockTime = block.timestamp + stakingLockupDuration;

        emit AetherStaked(msg.sender, _amount, stakedAether[msg.sender].unlockTime);
    }

    /**
     * @dev Allows users to withdraw their staked Aether after a cooldown period.
     */
    function redeemStakedAether() external whenNotPaused nonReentrant {
        StakedAether storage stake = stakedAether[msg.sender];
        require(stake.amount > 0, NoStakedAether(msg.sender));
        require(block.timestamp >= stake.unlockTime, StakingLockupActive(stake.unlockTime));

        uint256 amountToRedeem = stake.amount;
        delete stakedAether[msg.sender]; // Clear staking record

        _distributeAether(msg.sender, amountToRedeem); // Transfer Aether back to user

        emit AetherRedeemed(msg.sender, amountToRedeem);
    }

    /**
     * @dev Returns the current Aether balance of an account. (Standard ERC-20)
     * @param _account The address to query.
     * @return The balance of the account.
     */
    function getAetherBalance(address _account) external view returns (uint256) {
        return aetherToken.balanceOf(_account);
    }


    // --- F. Protocol Governance & Administration ---

    /**
     * @dev Sets the percentage fee for certain operations (e.g., Echo minting, evolution) that goes to the protocol treasury.
     * @param _newFee The new fee percentage (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setProtocolFee(uint256 _newFee) external onlyOwner whenNotPaused {
        require(_newFee <= 10000, "Fee percentage cannot exceed 10000 (100%)");
        protocolFeePercentage = _newFee;
        emit ProtocolFeeSet(_newFee);
    }

    /**
     * @dev Sets the XP thresholds required for each Essence level.
     * Must be an ordered array starting with 0 XP for Level 1.
     * @param _thresholds An array of XP thresholds for each level.
     */
    function setEssenceLevelThresholds(uint256[] memory _thresholds) external onlyOwner whenNotPaused {
        require(_thresholds.length > 0, "Thresholds array cannot be empty");
        require(_thresholds[0] == 0, "First threshold must be 0 for Level 1");
        for (uint256 i = 0; i < _thresholds.length - 1; i++) {
            require(_thresholds[i] < _thresholds[i+1], "Thresholds must be strictly increasing");
        }
        essenceLevelThresholds = _thresholds;
        emit EssenceLevelThresholdsSet(_thresholds);
    }

    /**
     * @dev Pauses the contract in case of emergency. Only callable by the owner.
     */
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the protocol owner/treasury to withdraw accumulated Aether fees.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) external onlyOwner nonReentrant {
        uint256 balance = aetherToken.balanceOf(address(this));
        require(balance > 0, "No Aether fees to withdraw");
        require(aetherToken.transfer(_to, balance), "Failed to withdraw Aether fees");
        emit ProtocolFeesWithdrawn(_to, balance);
    }
}
```