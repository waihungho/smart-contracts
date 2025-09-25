This smart contract, **EtherealCanvas**, proposes a novel decentralized ecosystem for AI-assisted generative art and metaverse space creation. It integrates advanced concepts such as on-chain AI agent management (registration, performance tracking, incentives, penalties), dynamic NFTs, a reputation-based curation system, and a robust challenge mechanism for art authenticity, all governed by a decentralized autonomous organization (DAO). The contract is designed to be creative, trendy, and avoid duplication of existing open-source projects by combining these elements into a unique protocol.

---

**Outline & Function Summary**

**I. Core Infrastructure & Access**
1.  **`updateGlobalParameters`**: Allows the DAO to update core system parameters like art generation fees, minimum stakes for AI agents and curators, challenge period durations, reward distribution ratios, and the addresses for the treasury and DAO itself.
2.  **`registerOracleAddress`**: Authorizes or de-authorizes specific addresses to act as trusted off-chain oracles for verifying AI outputs and other data.
3.  **`pauseContract`**: An emergency function, callable by the DAO, to temporarily halt critical contract operations in case of vulnerabilities or unforeseen issues.
4.  **`unpauseContract`**: Function, callable by the DAO, to resume contract operations after a pause.

**II. AI Agent Lifecycle & Incentives**
5.  **`registerAIAgentModel`**: Enables developers to register their AI models by providing metadata URI, defining the cost per generation, and staking a minimum amount of $CANVAS tokens. This marks the model as active.
6.  **`updateAIAgentModelMetadata`**: Allows an AI agent's owner to update the model's metadata URI or its cost per generation.
7.  **`submitAIGenerationOutput`**: AI agents call this function to submit the IPFS hash or URI of the generated art and optional proof data, fulfilling a prior art generation request. This triggers the process for art minting.
8.  **`penalizeAIAgent`**: The DAO can invoke this function to penalize (slash the stake of) an AI agent for verified misbehavior, failure to deliver, or malicious output, typically following a challenge resolution.
9.  **`claimAgentPerformanceRewards`**: AI agents (or their owners) can claim accumulated $CANVAS rewards earned from successful art generation requests and positive curation outcomes.
10. **`retireAIAgentModel`**: Allows an AI agent owner to initiate the retirement process for their model. The model enters a "pending retirement" state, with its stake locked for a cooldown period.
11. **`withdrawAIAgentStake`**: After the `retireAIAgentModel` cooldown period has passed and all pending requests are cleared, the AI agent owner can call this to withdraw their staked $CANVAS tokens.

**III. Generative Art Creation & Ownership**
12. **`requestArtGeneration`**: Users initiate an art generation request by providing a text prompt and selecting an active AI model. A fee (in $CANVAS) is paid by the user to the treasury.
13. **`finalizeArtMinting`**: An authorized oracle verifies the AI output for a fulfilled request. If valid and no active challenge exists, an ERC721 Art NFT is minted to the requester, and its metadata URI is set.
14. **`challengeArtMinting`**: Any user can challenge an art generation request before minting if they believe the AI output is fraudulent, inappropriate, or doesn't match the prompt. This requires staking $CANVAS as a bond.
15. **`resolveArtChallenge`**: The DAO reviews and resolves an initiated art challenge. Based on the resolution, stakes are distributed (challenger rewarded/penalized, requester's fee returned/forfeited), and the art's minting status is decided.
16. **`setDynamicArtAttribute`**: Art NFT owners can dynamically update certain mutable attributes (e.g., display preferences, visual effects) within their NFT's on-chain metadata.

**IV. Metaverse Space & Asset Deployment**
17. **`mintMetaverseSpaceNFT`**: Users can mint an ERC721 "Space" NFT, representing a piece of virtual real estate within the EtherealCanvas metaverse. A minting fee (in $CANVAS) is paid, and an initial tier is selected.
18. **`assignArtToSpace`**: Owners of both an Art NFT and a Space NFT can link them, effectively "displaying" the art within their metaverse space.
19. **`upgradeSpaceTier`**: Space owners can spend $CANVAS tokens to upgrade their space's tier, potentially unlocking new features, increasing capacity, or improving visibility.

**V. Curation, Reputation & Governance**
20. **`stakeForCuratorRole`**: Users can stake $CANVAS tokens to become a curator, gaining the ability to vote on art pieces and become eligible for curation rewards.
21. **`submitCurationVote`**: Active curators cast an "upvote" or "downvote" on minted art pieces. These votes contribute to the art's curation score, influencing its visibility and potential rewards.
22. **`delegateCurationPower`**: Curators can delegate their voting power to another address, allowing for delegated governance and specialized curation roles.
23. **`claimCuratorRewards`**: Curators can claim their accumulated $CANVAS rewards, which are distributed based on the positive impact of their curation votes on highly-rated and successful art.
24. **`releaseCuratorStake`**: Curators can initiate the process to unstake their $CANVAS tokens after a cooldown period, revoking their curator role and delegated voting power.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Custom errors for gas efficiency
error NotAIAgentOwner();
error NotOracleAddress();
error ArtGenerationRequestNotFound();
error ArtGenerationRequestNotFulfilled();
error ArtAlreadyMinted();
error ArtChallengePeriodNotExpired();
error ArtChallengeAlreadyResolved();
error InvalidChallenge();
error NotCurator();
error InsufficientStake();
error InvalidVote();
error NoRewardsToClaim();
error SpaceAlreadyUpgraded(); // General error, could be more specific
error SpaceUpgradeTierInvalid();
error AIModelNotRegistered();
error AIModelNotActive();
error AIModelCostMismatch();
error ArtGenerationFeeMismatch(); // Reused for other token transfers
error UnauthorizedAction();
error StakingPeriodNotOver();
error ChallengeStakeMismatch();
error ModelNotRetirable();
error CannotAssignOwnArtToSpace(); // Logic check
error NotSpaceOwner();
error InvalidTierUpgrade();
error ModelHasPendingRequests();
error ArtAlreadyAssignedToSpace();
error SpaceMintingFeeMismatch();
error SpaceUpgradeCostMismatch();
error NoArtNFTDataFound();


// Outline & Function Summary
// This contract, "EtherealCanvas," orchestrates a decentralized ecosystem for AI-assisted generative art and metaverse space creation.
// It manages AI agents, facilitates art generation, mints dynamic NFTs, provides metaverse space management, and implements
// a robust reputation-based curation and challenge system. Governance actions are handled through a designated DAO
// multisig or governance contract, whose address is configured during deployment and can be updated by the DAO itself.

// I. Core Infrastructure & Access
// 1.  updateGlobalParameters(uint256 newArtGenerationFee, uint256 newAIAgentMinStake, uint256 newCuratorMinStake, uint256 newChallengePeriodBlocks, uint256 newCuratorRewardRatio, uint256 newAgentRewardRatio, address newTreasuryAddress, address newDaoAddress): Allows the DAO to update core system parameters like fees, stakes, periods, and treasury/DAO addresses.
// 2.  registerOracleAddress(address oracleAddress, bool isAuthorised): Authorizes or de-authorizes specific addresses to act as trusted oracles for off-chain data verification.
// 3.  pauseContract(): Emergency function to pause critical contract operations (only callable by DAO or initial owner).
// 4.  unpauseContract(): Function to unpause the contract (only callable by DAO or initial owner).

// II. AI Agent Lifecycle & Incentives
// 5.  registerAIAgentModel(string calldata _modelURI, uint256 _costPerGeneration): Developers register their AI models, provide metadata URI, define cost, and stake $CANVAS tokens.
// 6.  updateAIAgentModelMetadata(uint256 _modelId, string calldata _newModelURI, uint256 _newCostPerGeneration): Allows an AI agent owner to update their model's metadata URI or cost.
// 7.  submitAIGenerationOutput(uint256 _requestId, uint256 _modelId, string calldata _artMetadataURI, string calldata _proofData): AI agent submits the generated art's metadata URI and optional proof, fulfilling a generation request.
// 8.  penalizeAIAgent(uint256 _modelId, uint256 _amount): DAO can penalize (slash stake) an AI agent for verified misbehavior or failure to deliver, based on challenge resolution.
// 9.  claimAgentPerformanceRewards(): AI agents claim accumulated rewards from successful, positively-curated art generations.
// 10. retireAIAgentModel(uint256 _modelId): Allows an AI agent owner to initiate retirement of their model, unstaking after a cooldown period.
// 11. withdrawAIAgentStake(uint256 _modelId): Allows an AI agent owner to withdraw their stake after the retirement cooldown.

// III. Generative Art Creation & Ownership
// 12. requestArtGeneration(uint256 _modelId, string calldata _prompt): Users submit a prompt to a chosen AI model, paying a fee, and initiate an art generation request.
// 13. finalizeArtMinting(uint256 _requestId, uint256 _modelId, string calldata _artMetadataURI): An authorized oracle verifies the AI output matches the request and triggers the minting of an ERC721 Art NFT to the requesting user.
// 14. challengeArtMinting(uint256 _requestId, string calldata _reason): Users can challenge the minting of an art piece if they believe it's fraudulent, inappropriate, or doesn't match the prompt. Requires a stake.
// 15. resolveArtChallenge(uint256 _requestId, bool _isChallengeValid): DAO (or designated resolver) resolves a challenged art piece, burning it, rewarding/penalizing participants.
// 16. setDynamicArtAttribute(uint256 _tokenId, string calldata _attributeKey, string calldata _attributeValue): Art NFT owner can dynamically update certain mutable attributes within their NFT's metadata, if the art design supports it.

// IV. Metaverse Space & Asset Deployment
// 17. mintMetaverseSpaceNFT(string calldata _spaceMetadataURI, uint256 _tier): Users can mint a "Space" NFT, representing virtual real estate, paying a minting fee.
// 18. assignArtToSpace(uint256 _artTokenId, uint256 _spaceTokenId): Owner of both an Art NFT and a Space NFT can assign the art to be displayed within that space.
// 19. upgradeSpaceTier(uint256 _spaceTokenId, uint256 _newTier): Space owners can spend $CANVAS tokens to upgrade their space's tier, unlocking new features or increasing capacity.

// V. Curation, Reputation & Governance
// 20. stakeForCuratorRole(): Users stake $CANVAS tokens to become a curator, gaining voting rights and eligibility for rewards.
// 21. submitCurationVote(uint256 _artTokenId, bool _isUpvote): Curators vote on art pieces (up/down), influencing visibility and reward distribution.
// 22. delegateCurationPower(address _delegatee): Curators can delegate their voting power to another address.
// 23. claimCuratorRewards(): Curators claim accumulated rewards based on the positive impact of their curation votes on successful art pieces.
// 24. releaseCuratorStake(): Curators can unstake their tokens after a cooldown period, revoking their role.

contract EtherealCanvas is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum ChallengeStatus {
        None, // No challenge
        Pending, // Challenge initiated, awaiting resolution
        ResolvedValid, // Challenge was valid, art problematic
        ResolvedInvalid // Challenge was invalid, art acceptable
    }

    enum AIAgentStatus {
        Active, // Model is active and accepting requests
        PendingRetirement, // Retirement initiated, cooldown active
        Retired // Model is fully retired, stake withdrawn
    }

    // --- Constants ---
    uint256 public constant MIN_SPACE_TIER = 1;
    uint256 public constant MAX_SPACE_TIER = 5;
    uint256 public constant BASE_SPACE_MINT_COST = 100 * (10 ** 18); // Example: 100 CANVAS per base tier
    uint256 public constant SPACE_UPGRADE_COST_PER_TIER = 500 * (10 ** 18); // Example: 500 CANVAS per tier difference

    // --- State Variables ---

    // Governance & Parameters
    address public daoAddress; // Address of the DAO multisig or governance contract
    address public treasuryAddress; // Address where protocol fees are collected
    IERC20 public canvasToken; // The ERC20 token used for fees, stakes, and rewards

    uint256 public artGenerationFee; // Fee (in CANVAS) to request art generation
    uint256 public aiAgentMinStake; // Minimum stake for an AI agent
    uint256 public curatorMinStake; // Minimum stake for a curator
    uint256 public challengePeriodBlocks; // Number of blocks for an art challenge to be open
    uint256 public stakingCooldownBlocks; // Number of blocks before stakes can be fully withdrawn after retirement/unstaking

    // Reward Ratios (per million, e.g., 50_000 for 5%)
    uint256 public curatorRewardRatio; // % of successful art revenue distributed to curators
    uint256 public agentRewardRatio; // % of successful art revenue distributed to AI agents

    // --- Counters for NFTs and Requests ---
    Counters.Counter private _artTokenIds;
    Counters.Counter private _spaceTokenIds;
    Counters.Counter private _aiModelIds;
    Counters.Counter private _requestIds;

    // --- Structs ---

    struct AIAgentModel {
        address owner;
        string modelURI;
        uint256 costPerGeneration; // In CANVAS tokens, paid to agent upon successful generation
        uint256 currentStake; // Total CANVAS staked by the agent
        AIAgentStatus status;
        uint256 lastStakeChangeBlock; // To track cooldown for retirement
        uint256 pendingRequests; // Number of pending requests for this agent
    }

    struct ArtGenerationRequest {
        address requester;
        uint256 modelId;
        string prompt;
        uint256 requestedBlock;
        string artMetadataURI; // Set after AI output submission by agent
        uint256 artTokenId; // If minted, ID of the ERC721 token
        bool fulfilled; // True if AI agent has submitted output
        bool minted; // True if Art NFT has been minted
    }

    struct ArtChallenge {
        address challenger;
        uint256 challengeStake;
        string reason;
        uint256 challengeBlock;
        ChallengeStatus status;
    }

    struct ArtNFTData {
        address creator; // Original requester of the art
        uint256 generationRequestId;
        uint256 assignedSpaceId; // 0 if not assigned to any space
        mapping(string => string) dynamicAttributes; // Mutable attributes for dynamic NFTs
    }

    struct SpaceNFTData {
        // address owner; // Redundant as ERC721 handles ownerOf
        string metadataURI;
        uint256 tier; // Tier of the space, affecting capabilities
        uint256 assignedArtCount; // Count of art pieces assigned to this space
        mapping(uint256 => bool) assignedArtPieces; // Art token IDs assigned to this space
    }

    struct Curator {
        uint256 stake; // Total CANVAS staked by the curator
        address delegatee; // Address to which voting power is delegated (self if not delegated)
        uint256 lastStakeChangeBlock; // To track cooldown for unstaking
    }

    // --- Mappings ---
    mapping(uint256 => AIAgentModel) public s_aiAgentModels; // modelId => AIAgentModel
    mapping(uint256 => ArtGenerationRequest) public s_artGenerationRequests; // requestId => ArtGenerationRequest
    mapping(uint256 => ArtChallenge) public s_artChallenges; // requestId => ArtChallenge
    mapping(address => bool) public s_oracles; // address => isAuthorized
    mapping(address => Curator) public s_curators; // curatorAddress => Curator
    mapping(uint256 => mapping(address => bool)) public s_curatorArtVotes; // artTokenId => curatorAddress => isUpvote (true) / isDownvote (false)
    mapping(uint256 => int256) public s_artCurationScore; // artTokenId => net upvotes (upvotes - downvotes)
    mapping(uint256 => ArtNFTData) public s_artNFTData; // artTokenId => ArtNFTData
    mapping(uint256 => SpaceNFTData) public s_spaceNFTData; // spaceTokenId => SpaceNFTData
    mapping(address => uint256) public s_agentRewards; // agentOwnerAddress => rewards to claim
    mapping(address => uint256) public s_curatorRewards; // curatorAddress => rewards to claim

    // --- Custom ERC721 for Art and Space ---
    ERC721URIStorage public artNFT;
    ERC721URIStorage public spaceNFT;

    // --- Events ---
    event GlobalParametersUpdated(uint256 artGenerationFee, uint256 aiAgentMinStake, uint256 curatorMinStake, uint256 challengePeriodBlocks, uint256 curatorRewardRatio, uint256 agentRewardRatio, address treasuryAddress, address daoAddress);
    event OracleRegistered(address indexed oracle, bool isAuthorised);
    event AIAgentModelRegistered(uint256 indexed modelId, address indexed owner, string modelURI, uint256 costPerGeneration, uint256 stake);
    event AIAgentModelUpdated(uint256 indexed modelId, string newModelURI, uint256 newCostPerGeneration);
    event AIAgentModelRetired(uint256 indexed modelId, address indexed owner);
    event AIAgentStakeWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);
    event AIAgentPenalized(uint256 indexed modelId, address indexed agentOwner, uint256 amount);
    event AgentRewardsClaimed(address indexed agentOwner, uint256 amount);
    event ArtGenerationRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, string prompt, uint256 feePaid);
    event AIGenerationOutputSubmitted(uint256 indexed requestId, uint256 indexed modelId, string artMetadataURI);
    event ArtNFTMinted(uint256 indexed requestId, uint256 indexed tokenId, address indexed owner, string metadataURI);
    event ArtChallengeInitiated(uint256 indexed requestId, address indexed challenger, uint256 challengeStake, string reason);
    event ArtChallengeResolved(uint256 indexed requestId, bool isChallengeValid, ChallengeStatus newStatus);
    event DynamicArtAttributeSet(uint256 indexed tokenId, string attributeKey, string attributeValue);
    event MetaverseSpaceMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, uint256 tier);
    event ArtAssignedToSpace(uint256 indexed artTokenId, uint256 indexed spaceTokenId, address indexed owner);
    event SpaceTierUpgraded(uint256 indexed spaceTokenId, address indexed owner, uint256 oldTier, uint256 newTier);
    event CuratorStaked(address indexed curator, uint256 stake);
    event CuratorVoteSubmitted(address indexed curator, uint256 indexed artTokenId, bool isUpvote);
    event CuratorDelegated(address indexed delegator, address indexed delegatee);
    event CuratorRewardsClaimed(address indexed curator, uint256 amount);
    event CuratorStakeReleased(address indexed curator, uint256 amount);


    // --- Modifiers ---
    modifier onlyDAO() {
        if (msg.sender != daoAddress) revert UnauthorizedAction();
        _;
    }

    modifier onlyOracle() {
        if (!s_oracles[msg.sender]) revert NotOracleAddress();
        _;
    }

    modifier onlyAIAgentOwner(uint256 _modelId) {
        if (s_aiAgentModels[_modelId].owner != msg.sender) revert NotAIAgentOwner();
        _;
    }

    modifier onlyCurator() {
        if (s_curators[msg.sender].stake < curatorMinStake) revert NotCurator();
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        if (artNFT.ownerOf(_tokenId) != msg.sender) revert UnauthorizedAction();
        _;
    }

    modifier onlySpaceOwner(uint256 _tokenId) {
        if (spaceNFT.ownerOf(_tokenId) != msg.sender) revert NotSpaceOwner();
        _;
    }

    // --- Constructor ---
    constructor(
        address _daoAddress,
        address _treasuryAddress,
        address _canvasTokenAddress,
        uint256 _initialArtGenerationFee,
        uint256 _initialAIAgentMinStake,
        uint256 _initialCuratorMinStake,
        uint256 _initialChallengePeriodBlocks,
        uint256 _initialStakingCooldownBlocks,
        uint256 _initialCuratorRewardRatio,
        uint256 _initialAgentRewardRatio
    ) Ownable(msg.sender) { // Initial owner is the deployer, who immediately sets DAO
        daoAddress = _daoAddress;
        treasuryAddress = _treasuryAddress;
        canvasToken = IERC20(_canvasTokenAddress);

        artNFT = new ERC721URIStorage("EtherealCanvas Art", "ECA");
        spaceNFT = new ERC721URIStorage("EtherealCanvas Space", "ECS");

        artGenerationFee = _initialArtGenerationFee;
        aiAgentMinStake = _initialAIAgentMinStake;
        curatorMinStake = _initialCuratorMinStake;
        challengePeriodBlocks = _initialChallengePeriodBlocks;
        stakingCooldownBlocks = _initialStakingCooldownBlocks;
        curatorRewardRatio = _initialCuratorRewardRatio;
        agentRewardRatio = _initialAgentRewardRatio;

        // Transfer initial ownership to DAO address if different from deployer
        // This ensures the DAO controls sensitive Ownable functions post-deployment
        if (msg.sender != daoAddress) {
            _transferOwnership(daoAddress);
        }
    }

    // --- I. Core Infrastructure & Access ---

    /**
     * @notice Allows the DAO to update core system parameters.
     * @param _newArtGenerationFee New fee for art generation.
     * @param _newAIAgentMinStake New minimum stake for AI agents.
     * @param _newCuratorMinStake New minimum stake for curators.
     * @param _newChallengePeriodBlocks New number of blocks for challenge period.
     * @param _newCuratorRewardRatio New reward ratio for curators (per million).
     * @param _newAgentRewardRatio New reward ratio for AI agents (per million).
     * @param _newTreasuryAddress New address for fee collection.
     * @param _newDaoAddress New address for the DAO.
     */
    function updateGlobalParameters(
        uint256 _newArtGenerationFee,
        uint256 _newAIAgentMinStake,
        uint256 _newCuratorMinStake,
        uint256 _newChallengePeriodBlocks,
        uint256 _newCuratorRewardRatio,
        uint256 _newAgentRewardRatio,
        address _newTreasuryAddress,
        address _newDaoAddress
    ) external onlyDAO whenNotPaused {
        artGenerationFee = _newArtGenerationFee;
        aiAgentMinStake = _newAIAgentMinStake;
        curatorMinStake = _newCuratorMinStake;
        challengePeriodBlocks = _newChallengePeriodBlocks;
        curatorRewardRatio = _newCuratorRewardRatio;
        agentRewardRatio = _newAgentRewardRatio;
        treasuryAddress = _newTreasuryAddress;
        daoAddress = _newDaoAddress; // DAO can change its own address

        emit GlobalParametersUpdated(
            artGenerationFee,
            aiAgentMinStake,
            curatorMinStake,
            challengePeriodBlocks,
            curatorRewardRatio,
            agentRewardRatio,
            treasuryAddress,
            daoAddress
        );
    }

    /**
     * @notice Authorizes or de-authorizes specific addresses to act as trusted oracles.
     * @param _oracleAddress The address to set as oracle.
     * @param _isAuthorised True to authorize, false to de-authorize.
     */
    function registerOracleAddress(address _oracleAddress, bool _isAuthorised) external onlyDAO whenNotPaused {
        s_oracles[_oracleAddress] = _isAuthorised;
        emit OracleRegistered(_oracleAddress, _isAuthorised);
    }

    /**
     * @notice Emergency function to pause critical contract operations. Callable by DAO.
     */
    function pauseContract() external onlyDAO {
        _pause();
    }

    /**
     * @notice Function to unpause the contract. Callable by DAO.
     */
    function unpauseContract() external onlyDAO {
        _unpause();
    }

    // --- II. AI Agent Lifecycle & Incentives ---

    /**
     * @notice Developers register their AI models, provide metadata URI, define cost, and stake $CANVAS tokens.
     * @param _modelURI URI pointing to model metadata (e.g., IPFS hash).
     * @param _costPerGeneration Cost in CANVAS tokens for using this model.
     */
    function registerAIAgentModel(string calldata _modelURI, uint256 _costPerGeneration) external whenNotPaused {
        if (s_aiAgentModels[_aiModelIds.current() + 1].owner != address(0) && s_aiAgentModels[_aiModelIds.current() + 1].status == AIAgentStatus.Active) {
            revert UnauthorizedAction(); // Should not be able to register existing ID if ID is based on counter
        }

        // Transfer stake from agent
        if (!canvasToken.transferFrom(msg.sender, address(this), aiAgentMinStake)) {
            revert InsufficientStake();
        }

        uint256 newModelId = _aiModelIds.current() + 1;
        _aiModelIds.increment();

        s_aiAgentModels[newModelId] = AIAgentModel({
            owner: msg.sender,
            modelURI: _modelURI,
            costPerGeneration: _costPerGeneration,
            currentStake: aiAgentMinStake,
            status: AIAgentStatus.Active,
            lastStakeChangeBlock: block.number,
            pendingRequests: 0
        });

        emit AIAgentModelRegistered(newModelId, msg.sender, _modelURI, _costPerGeneration, aiAgentMinStake);
    }

    /**
     * @notice Allows an AI agent owner to update their model's metadata URI or cost.
     * @param _modelId The ID of the AI model.
     * @param _newModelURI New URI pointing to model metadata.
     * @param _newCostPerGeneration New cost in CANVAS tokens for using this model.
     */
    function updateAIAgentModelMetadata(uint256 _modelId, string calldata _newModelURI, uint256 _newCostPerGeneration) external onlyAIAgentOwner(_modelId) whenNotPaused {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        if (model.status != AIAgentStatus.Active) revert AIModelNotActive();

        model.modelURI = _newModelURI;
        model.costPerGeneration = _newCostPerGeneration;

        emit AIAgentModelUpdated(_modelId, _newModelURI, _newCostPerGeneration);
    }

    /**
     * @notice AI agent submits the generated art's metadata URI and optional proof, fulfilling a generation request.
     * @param _requestId The ID of the art generation request.
     * @param _modelId The ID of the AI model that generated the art.
     * @param _artMetadataURI URI pointing to the generated art's metadata (e.g., IPFS hash).
     * @param _proofData Optional proof data for off-chain verification (e.g., ZKP hash).
     */
    function submitAIGenerationOutput(uint256 _requestId, uint256 _modelId, string calldata _artMetadataURI, string calldata _proofData) external onlyAIAgentOwner(_modelId) whenNotPaused {
        ArtGenerationRequest storage req = s_artGenerationRequests[_requestId];
        if (req.requester == address(0) || req.modelId != _modelId) revert ArtGenerationRequestNotFound();
        if (req.fulfilled) revert ArtGenerationRequestNotFulfilled();
        if (s_aiAgentModels[_modelId].status != AIAgentStatus.Active) revert AIModelNotActive();

        req.artMetadataURI = _artMetadataURI;
        req.fulfilled = true;

        s_aiAgentModels[_modelId].pendingRequests--; // Decrease pending requests count
        s_agentRewards[s_aiAgentModels[_modelId].owner] += s_aiAgentModels[_modelId].costPerGeneration; // Agent earns their cost

        emit AIGenerationOutputSubmitted(_requestId, _modelId, _artMetadataURI);
    }

    /**
     * @notice DAO can penalize (slash stake) an AI agent for verified misbehavior or failure to deliver.
     *         This function is typically called after a challenge resolution confirms misbehavior.
     * @param _modelId The ID of the AI model to penalize.
     * @param _amount The amount of CANVAS tokens to slash from the agent's stake.
     */
    function penalizeAIAgent(uint256 _modelId, uint256 _amount) external onlyDAO whenNotPaused {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        if (model.owner == address(0)) revert AIModelNotRegistered();
        if (model.currentStake < _amount) {
            _amount = model.currentStake; // Slash max possible if amount exceeds stake
        }

        model.currentStake -= _amount;
        // Transfer slashed amount to treasury
        if (!canvasToken.transfer(treasuryAddress, _amount)) {
            revert UnauthorizedAction(); // Should not happen if balance checked
        }
        emit AIAgentPenalized(_modelId, model.owner, _amount);
    }

    /**
     * @notice AI agents claim accumulated rewards from successful generation outputs.
     */
    function claimAgentPerformanceRewards() external whenNotPaused {
        uint256 claimable = s_agentRewards[msg.sender];
        if (claimable == 0) revert NoRewardsToClaim();

        s_agentRewards[msg.sender] = 0; // Reset rewards
        if (!canvasToken.transfer(msg.sender, claimable)) {
            revert UnauthorizedAction(); // Should not happen if balance checked
        }
        emit AgentRewardsClaimed(msg.sender, claimable);
    }

    /**
     * @notice Allows an AI agent owner to initiate retirement of their model, unstaking after a cooldown period.
     * @param _modelId The ID of the AI model to retire.
     */
    function retireAIAgentModel(uint256 _modelId) external onlyAIAgentOwner(_modelId) whenNotPaused {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        if (model.status != AIAgentStatus.Active) revert AIModelNotActive();
        if (model.pendingRequests > 0) revert ModelHasPendingRequests();

        model.status = AIAgentStatus.PendingRetirement;
        model.lastStakeChangeBlock = block.number; // Start cooldown

        emit AIAgentModelRetired(_modelId, msg.sender);
    }

    /**
     * @notice Allows an AI agent owner to withdraw their stake after the retirement cooldown.
     * @param _modelId The ID of the AI model to withdraw stake from.
     */
    function withdrawAIAgentStake(uint256 _modelId) external onlyAIAgentOwner(_modelId) whenNotPaused {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        if (model.status != AIAgentStatus.PendingRetirement) revert ModelNotRetirable();
        if (block.number < model.lastStakeChangeBlock + stakingCooldownBlocks) revert StakingPeriodNotOver();
        if (model.pendingRequests > 0) revert ModelHasPendingRequests();

        uint256 stakeToReturn = model.currentStake;
        model.currentStake = 0;
        model.status = AIAgentStatus.Retired;

        if (!canvasToken.transfer(msg.sender, stakeToReturn)) {
            revert UnauthorizedAction(); // Should not happen
        }
        emit AIAgentStakeWithdrawn(_modelId, msg.sender, stakeToReturn);
    }

    // --- III. Generative Art Creation & Ownership ---

    /**
     * @notice Users submit a prompt to a chosen AI model, paying a fee, and initiate an art generation request.
     * @param _modelId The ID of the AI model to use.
     * @param _prompt The text prompt for the AI.
     */
    function requestArtGeneration(uint256 _modelId, string calldata _prompt) external whenNotPaused {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        if (model.owner == address(0) || model.status != AIAgentStatus.Active) revert AIModelNotActive();

        // Transfer art generation fee (in CANVAS) to treasury
        // Requires msg.sender to have approved this contract to spend `artGenerationFee`
        if (!canvasToken.transferFrom(msg.sender, treasuryAddress, artGenerationFee)) {
            revert ArtGenerationFeeMismatch();
        }

        uint256 newRequestId = _requestIds.current() + 1;
        _requestIds.increment();

        s_artGenerationRequests[newRequestId] = ArtGenerationRequest({
            requester: msg.sender,
            modelId: _modelId,
            prompt: _prompt,
            requestedBlock: block.number,
            artMetadataURI: "",
            artTokenId: 0,
            fulfilled: false,
            minted: false
        });

        model.pendingRequests++; // Increment pending requests for the model

        emit ArtGenerationRequested(newRequestId, _modelId, msg.sender, _prompt, artGenerationFee);
    }

    /**
     * @notice An authorized oracle verifies the AI output matches the request and triggers the minting of an ERC721 Art NFT to the requesting user.
     * @param _requestId The ID of the art generation request.
     * @param _modelId The ID of the AI model.
     * @param _artMetadataURI The metadata URI of the generated art.
     */
    function finalizeArtMinting(uint252 _requestId, uint256 _modelId, string calldata _artMetadataURI) external onlyOracle whenNotPaused {
        ArtGenerationRequest storage req = s_artGenerationRequests[_requestId];
        if (req.requester == address(0) || req.modelId != _modelId) revert ArtGenerationRequestNotFound();
        if (!req.fulfilled) revert ArtGenerationRequestNotFulfilled();
        if (req.minted) revert ArtAlreadyMinted();
        // Check if the oracle is confirming the *correct* submitted URI
        if (keccak256(abi.encodePacked(req.artMetadataURI)) != keccak256(abi.encodePacked(_artMetadataURI))) {
            revert UnauthorizedAction();
        }

        // Check if there's an open challenge
        ArtChallenge storage challenge = s_artChallenges[_requestId];
        if (challenge.status == ChallengeStatus.Pending) {
            if (block.number < challenge.challengeBlock + challengePeriodBlocks) {
                revert ArtChallengePeriodNotExpired(); // Challenge still open
            }
            if (challenge.status == ChallengeStatus.ResolvedValid) {
                revert ArtChallengeAlreadyResolved(); // Minting blocked due to valid challenge
            }
        }
        
        req.minted = true;
        uint256 newArtTokenId = _artTokenIds.current() + 1;
        _artTokenIds.increment();
        req.artTokenId = newArtTokenId;

        artNFT._safeMint(req.requester, newArtTokenId);
        artNFT.setTokenURI(newArtTokenId, _artMetadataURI);

        s_artNFTData[newArtTokenId] = ArtNFTData({
            creator: req.requester,
            generationRequestId: _requestId,
            assignedSpaceId: 0
        });

        emit ArtNFTMinted(_requestId, newArtTokenId, req.requester, _artMetadataURI);
    }

    /**
     * @notice Users can challenge the minting of an art piece if they believe it's fraudulent, inappropriate, or doesn't match the prompt.
     * @param _requestId The ID of the art generation request.
     * @param _reason The reason for the challenge.
     */
    function challengeArtMinting(uint256 _requestId, string calldata _reason) external whenNotPaused {
        ArtGenerationRequest storage req = s_artGenerationRequests[_requestId];
        if (req.requester == address(0)) revert ArtGenerationRequestNotFound();
        if (!req.fulfilled) revert ArtGenerationRequestNotFulfilled();
        if (req.minted) revert ArtAlreadyMinted(); // Can only challenge before minting
        if (s_artChallenges[_requestId].status != ChallengeStatus.None) revert InvalidChallenge();

        // Challenger pays the same fee as art generation as a bond
        if (!canvasToken.transferFrom(msg.sender, address(this), artGenerationFee)) {
            revert ChallengeStakeMismatch();
        }

        s_artChallenges[_requestId] = ArtChallenge({
            challenger: msg.sender,
            challengeStake: artGenerationFee,
            reason: _reason,
            challengeBlock: block.number,
            status: ChallengeStatus.Pending
        });

        emit ArtChallengeInitiated(_requestId, msg.sender, artGenerationFee, _reason);
    }

    /**
     * @notice DAO (or designated resolver) resolves a challenged art piece, potentially burning it, rewarding/penalizing participants.
     * @param _requestId The ID of the art generation request.
     * @param _isChallengeValid True if the challenge is valid (art is problematic), false otherwise.
     */
    function resolveArtChallenge(uint256 _requestId, bool _isChallengeValid) external onlyDAO whenNotPaused {
        ArtGenerationRequest storage req = s_artGenerationRequests[_requestId];
        ArtChallenge storage challenge = s_artChallenges[_requestId];
        if (req.requester == address(0)) revert ArtGenerationRequestNotFound();
        if (challenge.status != ChallengeStatus.Pending) revert ArtChallengeAlreadyResolved();
        if (block.number < challenge.challengeBlock + challengePeriodBlocks) revert ArtChallengePeriodNotExpired();

        challenge.status = _isChallengeValid ? ChallengeStatus.ResolvedValid : ChallengeStatus.ResolvedInvalid;

        if (_isChallengeValid) {
            // Challenge is valid: challenger wins stake, AI agent's cost not paid, requester's fee returned.
            if (!canvasToken.transfer(challenge.challenger, challenge.challengeStake)) {
                revert UnauthorizedAction();
            }
            // Return requester's art generation fee
            if (!canvasToken.transfer(req.requester, artGenerationFee)) {
                revert UnauthorizedAction();
            }
            // AI agent does *not* get its costPerGeneration, it's effectively locked in contract or slashed by DAO
            // DAO can call penalizeAIAgent if specific punishment is needed.
        } else {
            // Challenge is invalid: challenger loses stake (goes to treasury), art can proceed to minting, AI agent gets its cost.
            if (!canvasToken.transfer(treasuryAddress, challenge.challengeStake)) {
                revert UnauthorizedAction();
            }
            // AI agent gets its costPerGeneration
            s_agentRewards[s_aiAgentModels[req.modelId].owner] += s_aiAgentModels[req.modelId].costPerGeneration;
        }

        emit ArtChallengeResolved(_requestId, _isChallengeValid, challenge.status);
    }

    /**
     * @notice Art NFT owner can dynamically update certain mutable attributes within their NFT's metadata.
     *         The specific attributes and their mutability would be defined off-chain in the art's metadata schema.
     * @param _tokenId The ID of the Art NFT.
     * @param _attributeKey The key of the attribute to set.
     * @param _attributeValue The value to set for the attribute.
     */
    function setDynamicArtAttribute(uint256 _tokenId, string calldata _attributeKey, string calldata _attributeValue) external onlyArtOwner(_tokenId) whenNotPaused {
        if (s_artNFTData[_tokenId].creator == address(0)) revert NoArtNFTDataFound();
        s_artNFTData[_tokenId].dynamicAttributes[_attributeKey] = _attributeValue;
        // To reflect in marketplaces, the tokenURI might need to be re-generated or point to a dynamic metadata service.
        emit DynamicArtAttributeSet(_tokenId, _attributeKey, _attributeValue);
    }

    // --- IV. Metaverse Space & Asset Deployment ---

    /**
     * @notice Users can mint a "Space" NFT, representing virtual real estate, paying a minting fee.
     * @param _spaceMetadataURI URI pointing to the space's metadata.
     * @param _tier The initial tier of the space.
     */
    function mintMetaverseSpaceNFT(string calldata _spaceMetadataURI, uint256 _tier) external whenNotPaused {
        if (_tier < MIN_SPACE_TIER || _tier > MAX_SPACE_TIER) revert InvalidTierUpgrade();

        uint256 spaceMintingFee = BASE_SPACE_MINT_COST * _tier; // Example: Linear increase with tier
        if (!canvasToken.transferFrom(msg.sender, treasuryAddress, spaceMintingFee)) {
            revert SpaceMintingFeeMismatch();
        }

        uint256 newSpaceTokenId = _spaceTokenIds.current() + 1;
        _spaceTokenIds.increment();

        spaceNFT._safeMint(msg.sender, newSpaceTokenId);
        spaceNFT.setTokenURI(newSpaceTokenId, _spaceMetadataURI);

        s_spaceNFTData[newSpaceTokenId] = SpaceNFTData({
            // owner: msg.sender, // Redundant, ERC721 handles it
            metadataURI: _spaceMetadataURI,
            tier: _tier,
            assignedArtCount: 0
        });

        emit MetaverseSpaceMinted(newSpaceTokenId, msg.sender, _spaceMetadataURI, _tier);
    }

    /**
     * @notice Owner of both an Art NFT and a Space NFT can assign the art to be displayed within that space.
     * @param _artTokenId The ID of the Art NFT.
     * @param _spaceTokenId The ID of the Space NFT.
     */
    function assignArtToSpace(uint256 _artTokenId, uint256 _spaceTokenId) external onlyArtOwner(_artTokenId) onlySpaceOwner(_spaceTokenId) whenNotPaused {
        ArtNFTData storage artData = s_artNFTData[_artTokenId];
        SpaceNFTData storage spaceData = s_spaceNFTData[_spaceTokenId];

        if (artData.creator == address(0)) revert NoArtNFTDataFound();
        if (artData.assignedSpaceId != 0) revert ArtAlreadyAssignedToSpace();
        // Optional: Add logic to limit assigned art pieces per space based on tier or other factors

        artData.assignedSpaceId = _spaceTokenId;
        spaceData.assignedArtPieces[_artTokenId] = true;
        spaceData.assignedArtCount++;

        emit ArtAssignedToSpace(_artTokenId, _spaceTokenId, msg.sender);
    }

    /**
     * @notice Space owners can spend $CANVAS tokens to upgrade their space's tier, unlocking new features or increasing capacity.
     * @param _spaceTokenId The ID of the Space NFT.
     * @param _newTier The desired new tier.
     */
    function upgradeSpaceTier(uint256 _spaceTokenId, uint256 _newTier) external onlySpaceOwner(_spaceTokenId) whenNotPaused {
        SpaceNFTData storage space = s_spaceNFTData[_spaceTokenId];
        if (_newTier <= space.tier || _newTier > MAX_SPACE_TIER) revert InvalidTierUpgrade();

        uint256 upgradeCost = (_newTier - space.tier) * SPACE_UPGRADE_COST_PER_TIER; // Example: 500 CANVAS per tier difference
        if (!canvasToken.transferFrom(msg.sender, treasuryAddress, upgradeCost)) {
            revert SpaceUpgradeCostMismatch();
        }

        uint256 oldTier = space.tier;
        space.tier = _newTier;

        emit SpaceTierUpgraded(_spaceTokenId, msg.sender, oldTier, _newTier);
    }

    // --- V. Curation, Reputation & Governance ---

    /**
     * @notice Users stake $CANVAS tokens to become a curator, gaining voting rights and eligibility for rewards.
     */
    function stakeForCuratorRole() external whenNotPaused {
        Curator storage curator = s_curators[msg.sender];
        if (curator.stake == 0) { // First time staking
            curator.lastStakeChangeBlock = block.number;
            curator.delegatee = msg.sender; // Delegate to self by default
        }

        // Transfer min stake from user
        if (!canvasToken.transferFrom(msg.sender, address(this), curatorMinStake)) {
            revert InsufficientStake();
        }
        curator.stake += curatorMinStake;

        emit CuratorStaked(msg.sender, curatorMinStake);
    }

    /**
     * @notice Curators vote on art pieces (up/down), influencing visibility and reward distribution.
     * @param _artTokenId The ID of the Art NFT to vote on.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function submitCurationVote(uint256 _artTokenId, bool _isUpvote) external onlyCurator whenNotPaused {
        // Prevent re-voting on the same piece (for simplicity). A more complex system might allow vote changes.
        if (s_curatorArtVotes[_artTokenId][msg.sender]) revert InvalidVote();

        // If the curator has delegated, the vote power comes from the delegatee
        address actualVoter = s_curators[msg.sender].delegatee; // Use delegatee for vote impact

        s_curatorArtVotes[_artTokenId][actualVoter] = true; // Mark as voted by the effective voter
        if (_isUpvote) {
            s_artCurationScore[_artTokenId]++;
        } else {
            s_artCurationScore[_artTokenId]--;
        }

        // Rewards for curation would be calculated off-chain or through a more complex reward distribution function.
        // For simplicity, `s_curatorRewards` is directly managed elsewhere or is subject to a batch distribution.

        emit CuratorVoteSubmitted(msg.sender, _artTokenId, _isUpvote);
    }

    /**
     * @notice Curators can delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateCurationPower(address _delegatee) external onlyCurator whenNotPaused {
        s_curators[msg.sender].delegatee = _delegatee;
        emit CuratorDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Curators claim accumulated rewards based on the positive impact of their curation votes on successful art pieces.
     */
    function claimCuratorRewards() external whenNotPaused {
        uint256 claimable = s_curatorRewards[msg.sender];
        if (claimable == 0) revert NoRewardsToClaim();

        s_curatorRewards[msg.sender] = 0; // Reset rewards
        if (!canvasToken.transfer(msg.sender, claimable)) {
            revert UnauthorizedAction(); // Should not happen if balance checked
        }
        emit CuratorRewardsClaimed(msg.sender, claimable);
    }

    /**
     * @notice Curators can unstake their tokens after a cooldown period, revoking their role.
     */
    function releaseCuratorStake() external whenNotPaused {
        Curator storage curator = s_curators[msg.sender];
        if (curator.stake < curatorMinStake) revert NotCurator(); // Must have minimum stake to be a curator
        if (block.number < curator.lastStakeChangeBlock + stakingCooldownBlocks) revert StakingPeriodNotOver();

        uint256 stakeToReturn = curator.stake;
        curator.stake = 0;
        curator.delegatee = address(0); // Remove delegation upon unstaking

        if (!canvasToken.transfer(msg.sender, stakeToReturn)) {
            revert UnauthorizedAction(); // Should not happen
        }
        emit CuratorStakeReleased(msg.sender, stakeToReturn);
    }

    // --- View Functions (Getters) ---
    function getArtNFTCount() external view returns (uint256) {
        return _artTokenIds.current();
    }

    function getSpaceNFTCount() external view returns (uint256) {
        return _spaceTokenIds.current();
    }

    function getAIAgentModelCount() external view returns (uint256) {
        return _aiModelIds.current();
    }

    function getArtGenerationRequestCount() external view returns (uint256) {
        return _requestIds.current();
    }

    function getAIAgentModel(uint256 _modelId) external view returns (address owner, string memory modelURI, uint256 costPerGeneration, uint256 currentStake, AIAgentStatus status, uint256 pendingRequests) {
        AIAgentModel storage model = s_aiAgentModels[_modelId];
        return (model.owner, model.modelURI, model.costPerGeneration, model.currentStake, model.status, model.pendingRequests);
    }

    function getArtGenerationRequest(uint256 _requestId) external view returns (address requester, uint256 modelId, string memory prompt, uint256 requestedBlock, string memory artMetadataURI, uint256 artTokenId, bool fulfilled, bool minted) {
        ArtGenerationRequest storage req = s_artGenerationRequests[_requestId];
        return (req.requester, req.modelId, req.prompt, req.requestedBlock, req.artMetadataURI, req.artTokenId, req.fulfilled, req.minted);
    }

    function getArtChallenge(uint256 _requestId) external view returns (address challenger, uint256 challengeStake, string memory reason, uint256 challengeBlock, ChallengeStatus status) {
        ArtChallenge storage challenge = s_artChallenges[_requestId];
        return (challenge.challenger, challenge.challengeStake, challenge.reason, challenge.challengeBlock, challenge.status);
    }

    function getCurator(address _curator) external view returns (uint256 stake, address delegatee, uint256 lastStakeChangeBlock) {
        Curator storage curator = s_curators[_curator];
        return (curator.stake, curator.delegatee, curator.lastStakeChangeBlock);
    }

    function getArtCurationScore(uint256 _artTokenId) external view returns (int256) {
        return s_artCurationScore[_artTokenId];
    }

    function getArtNFTData(uint256 _artTokenId) external view returns (address creator, uint256 generationRequestId, uint256 assignedSpaceId) {
        ArtNFTData storage artData = s_artNFTData[_artTokenId];
        return (artData.creator, artData.generationRequestId, artData.assignedSpaceId);
    }

    function getArtDynamicAttribute(uint256 _artTokenId, string memory _attributeKey) external view returns (string memory) {
        return s_artNFTData[_artTokenId].dynamicAttributes[_attributeKey];
    }

    function getSpaceNFTData(uint256 _spaceTokenId) external view returns (string memory metadataURI, uint256 tier, uint256 assignedArtCount) {
        SpaceNFTData storage spaceData = s_spaceNFTData[_spaceTokenId];
        return (spaceData.metadataURI, spaceData.tier, spaceData.assignedArtCount);
    }

    function isOracle(address _addr) external view returns (bool) {
        return s_oracles[_addr];
    }
}
```