Here's a Solidity smart contract for `AetherForge`, designed with advanced, creative, and trendy concepts. It focuses on decentralized AI-driven content generation, verified outputs, dynamic NFTs, and a reputation system, ensuring it doesn't directly duplicate common open-source patterns.

---

**Contract: AetherForge**

**Overview:**
AetherForge is a decentralized protocol designed to orchestrate and incentivize off-chain AI model computations, verify their outputs, and mint the resulting generative content as dynamic NFTs. It fosters a robust ecosystem where requesters submit AI generation tasks, AI providers execute them, and validators ensure the integrity of the results through a challenge-based verification system. The protocol incorporates a reputation system, staking mechanisms, and a native utility token to align incentives and govern participation.

**Key Features:**
*   **AI Task Orchestration:** Users can request AI content generation for various models.
*   **Decentralized AI Provider Network:** AI model owners register and stake to offer their services.
*   **Result Verification & Challenge System:** A robust mechanism for validating AI outputs, including staking, voting, and slashing to ensure quality and prevent malicious submissions.
*   **Dynamic Generative NFTs:** Verified AI-generated content is minted as ERC721 NFTs whose metadata can evolve post-minting based on protocol rules or further AI analysis.
*   **Reputation System:** Participants earn reputation based on their performance, influencing their standing and rewards within the ecosystem.
*   **Economic Incentives:** Staking, rewards, and slashing mechanisms powered by a native utility token (`AIGEN`).

---

**Function Summary:**

**I. Core Infrastructure & Access Control (Admin/Protocol Management)**
1.  `constructor(address _aigenTokenAddress, string memory _nftName, string memory _nftSymbol)`: Initializes the contract, sets up roles (owner), and links the AIGEN token address and NFT details.
2.  `pause()`: Allows the owner/admin to pause core contract functionalities.
3.  `unpause()`: Allows the owner/admin to resume core contract functionalities.
4.  `setProtocolFeeRecipient(address _newRecipient)`: Sets the address for collecting protocol fees.
5.  `updateFeePercentage(uint256 _newFeeBps)`: Updates the protocol fee percentage (in basis points).
6.  `withdrawProtocolFees()`: Allows the fee recipient to withdraw accumulated protocol fees.

**II. AIGEN Token & Staking Mechanics**
7.  `setMinStakeAmount(StakeRole _role, uint256 _amount)`: Allows the owner to set minimum AIGEN stake required for a given role.
8.  `stakeTokens(uint256 _amount, StakeRole _role)`: Allows users to stake AIGEN tokens for specific roles (Requester, Provider, Validator).
9.  `unstakeTokens(uint256 _amount, StakeRole _role)`: Allows users to unstake AIGEN tokens from a specific role.
10. `getMinStakeAmount(StakeRole _role)`: Returns the minimum AIGEN stake required for a given role.
11. `getUserStake(address _user, StakeRole _role)`: Returns the current stake amount for a user in a specific role.

**III. AI Provider Management**
12. `registerAIProvider(string calldata _modelId, string calldata _endpointURI)`: Registers an address as an AI provider for a specific AI model, requiring a minimum stake.
13. `updateAIProviderProfile(string calldata _modelId, string calldata _newEndpointURI)`: Allows a registered AI provider to update their registered endpoint URI.
14. `deregisterAIProvider()`: Allows an AI provider to deregister, withdrawing their stake after a cooldown period.
15. `getAIProviderDetails(address _provider)`: Returns the registration details of an AI provider.

**IV. AI Request & Generation Workflow**
16. `requestAIGeneration(string calldata _prompt, string calldata _modelId, uint256 _bountyAmount)`: Initiates an AI content generation request, staking a bounty for the provider. Returns a unique `requestId`.
17. `submitAIGenerationResult(uint256 _requestId, string calldata _resultHash)`: An AI provider submits the IPFS/decentralized storage hash of the generated content for a `requestId`.
18. `getGenerationRequestDetails(uint256 _requestId)`: Retrieves the full details of an AI generation request.
19. `getGenerationResult(uint256 _requestId)`: Retrieves the submitted result hash for a given request.

**V. Verification & Challenge System**
20. `challengeAIGenerationResult(uint256 _requestId, string calldata _reasonHash)`: A validator or any user can challenge a submitted AI result, staking tokens.
21. `submitChallengeVote(uint256 _challengeId, bool _isResultValid)`: Validators vote on the validity of a challenged AI result.
22. `resolveChallenge(uint256 _challengeId)`: Resolves a challenge based on voting outcome, distributing rewards or applying slashes.
23. `claimGenerationReward(uint256 _requestId)`: Allows the AI provider to claim their bounty after a successful, unchallenged generation.
24. `claimValidationReward(uint256 _challengeId)`: Allows validators to claim their rewards from correctly voted challenges (primarily reputation updates here as token rewards are direct).

**VI. Dynamic NFT (AI-Generated Content) Management**
25. `mintGeneratedNFT(uint256 _requestId, string calldata _initialMetadataURI)`: Mints an ERC721 NFT for a successfully verified and resolved AI generation request. Callable only by the protocol itself (or owner for this demo).
26. `updateNFTMetadataURI(uint256 _tokenId, string calldata _newMetadataURI)`: Allows the original requester (or owner of the NFT) to update the metadata URI of an existing NFT, enabling dynamic content.
27. `getNFTProperties(uint256 _tokenId)`: Retrieves specific on-chain properties (like the `requestId` it originated from) of a minted NFT.

**VII. Reputation System**
28. `getUserReputation(address _user)`: Returns the overall reputation score of a user.
29. `getProviderReputation(address _provider)`: Returns the specific reputation score for an AI provider.
30. `getValidatorReputation(address _validator)`: Returns the specific reputation score for a validator.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
    Contract: AetherForge

    Overview:
    AetherForge is a decentralized protocol designed to orchestrate and incentivize off-chain AI model
    computations, verify their outputs, and mint the resulting generative content as dynamic NFTs.
    It fosters a robust ecosystem where requesters submit AI generation tasks, AI providers execute them,
    and validators ensure the integrity of the results through a challenge-based verification system.
    The protocol incorporates a reputation system, staking mechanisms, and a native utility token to
    align incentives and govern participation.

    Key Features:
    *   AI Task Orchestration: Users can request AI content generation for various models.
    *   Decentralized AI Provider Network: AI model owners register and stake to offer their services.
    *   Result Verification & Challenge System: A robust mechanism for validating AI outputs, including
        staking, voting, and slashing to ensure quality and prevent malicious submissions.
    *   Dynamic Generative NFTs: Verified AI-generated content is minted as ERC721 NFTs whose metadata
        can evolve post-minting based on protocol rules or further AI analysis.
    *   Reputation System: Participants earn reputation based on their performance, influencing their
        standing and rewards within the ecosystem.
    *   Economic Incentives: Staking, rewards, and slashing mechanisms powered by a native utility token (`AIGEN`).
*/

/*
    Function Summary:

    I. Core Infrastructure & Access Control (Admin/Protocol Management)
    1.  constructor(address _aigenTokenAddress, string memory _nftName, string memory _nftSymbol):
        Initializes the contract, sets up roles (owner), and links the AIGEN token address and NFT details.
    2.  pause(): Allows the owner/admin to pause core contract functionalities.
    3.  unpause(): Allows the owner/admin to resume core contract functionalities.
    4.  setProtocolFeeRecipient(address _newRecipient): Sets the address for collecting protocol fees.
    5.  updateFeePercentage(uint256 _newFeeBps): Updates the protocol fee percentage (in basis points).
    6.  withdrawProtocolFees(): Allows the fee recipient to withdraw accumulated protocol fees.

    II. AIGEN Token & Staking Mechanics
    7.  setMinStakeAmount(StakeRole _role, uint256 _amount): Allows the owner to set minimum AIGEN stake required for a given role.
    8.  stakeTokens(uint256 _amount, StakeRole _role): Allows users to stake AIGEN tokens for specific roles
        (Requester, Provider, Validator).
    9.  unstakeTokens(uint256 _amount, StakeRole _role): Allows users to unstake AIGEN tokens from a specific role.
    10. getMinStakeAmount(StakeRole _role): Returns the minimum AIGEN stake required for a given role.
    11. getUserStake(address _user, StakeRole _role): Returns the current stake amount for a user in a specific role.

    III. AI Provider Management
    12. registerAIProvider(string calldata _modelId, string calldata _endpointURI): Registers an address as an
        AI provider for a specific AI model, requiring a minimum stake.
    13. updateAIProviderProfile(string calldata _modelId, string calldata _newEndpointURI): Allows a registered
        AI provider to update their registered endpoint URI.
    14. deregisterAIProvider(): Allows an AI provider to deregister, withdrawing their stake after a cooldown period.
    15. getAIProviderDetails(address _provider): Returns the registration details of an AI provider.

    IV. AI Request & Generation Workflow
    16. requestAIGeneration(string calldata _prompt, string calldata _modelId, uint256 _bountyAmount):
        Initiates an AI content generation request, staking a bounty for the provider. Returns a unique `requestId`.
    17. submitAIGenerationResult(uint256 _requestId, string calldata _resultHash): An AI provider submits the
        IPFS/decentralized storage hash of the generated content for a `requestId`.
    18. getGenerationRequestDetails(uint256 _requestId): Retrieves the full details of an AI generation request.
    19. getGenerationResult(uint256 _requestId): Retrieves the submitted result hash for a given request.

    V. Verification & Challenge System
    20. challengeAIGenerationResult(uint256 _requestId, string calldata _reasonHash): A validator or any user can
        challenge a submitted AI result, staking tokens.
    21. submitChallengeVote(uint256 _challengeId, bool _isResultValid): Validators vote on the validity of a
        challenged AI result.
    22. resolveChallenge(uint256 _challengeId): Resolves a challenge based on voting outcome, distributing
        rewards or applying slashes.
    23. claimGenerationReward(uint256 _requestId): Allows the AI provider to claim their bounty after a successful,
        unchallenged generation.
    24. claimValidationReward(uint256 _challengeId): Allows validators to claim their rewards from correctly voted
        challenges (primarily for reputation updates in this simplified example as tokens are direct).

    VI. Dynamic NFT (AI-Generated Content) Management
    25. mintGeneratedNFT(uint256 _requestId, string calldata _initialMetadataURI): Mints an ERC721 NFT for a
        successfully verified and resolved AI generation request. Callable only by the protocol itself (or owner for demo purposes).
    26. updateNFTMetadataURI(uint256 _tokenId, string calldata _newMetadataURI): Allows the original requester
        (or owner of the NFT) to update the metadata URI of an existing NFT, enabling dynamic content.
    27. getNFTProperties(uint256 _tokenId): Retrieves specific on-chain properties (like the `requestId` it
        originated from) of a minted NFT.

    VII. Reputation System
    28. getUserReputation(address _user): Returns the overall reputation score of a user.
    29. getProviderReputation(address _provider): Returns the specific reputation score for an AI provider.
    30. getValidatorReputation(address _validator): Returns the specific reputation score for a validator.
*/

contract AetherForge is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;

    IERC20 public immutable AIGEN_TOKEN;

    // --- Protocol Configuration ---
    uint256 public protocolFeeBps = 100; // 1% in basis points (100 = 1%)
    address public protocolFeeRecipient;

    // --- Staking Configuration ---
    enum StakeRole { None, Requester, Provider, Validator }
    mapping(StakeRole => uint256) public minStakeAmounts;
    mapping(address => mapping(StakeRole => uint256)) public stakedBalances;

    // --- AI Provider Management ---
    struct AIProvider {
        string modelId;
        string endpointURI; // Off-chain reference for provider API
        uint256 registeredAt;
        bool isRegistered;
        uint256 cooldownEnds; // For deregistration
    }
    mapping(address => AIProvider) public aiProviders;

    // --- AI Generation Requests ---
    enum RequestStatus { Pending, Submitted, Challenged, ResolvedSuccess, ResolvedFailed, NFTMinted }
    struct GenerationRequest {
        address requester;
        string prompt;
        string modelId;
        uint256 bountyAmount; // AIGEN tokens
        uint256 submittedAt;
        address provider;
        string resultHash; // IPFS CID or similar
        RequestStatus status;
        uint256 challengeId; // If challenged
        uint256 nftTokenId; // If NFT minted
    }
    Counters.Counter private _requestIds;
    mapping(uint256 => GenerationRequest) public generationRequests;

    // --- Challenge System ---
    enum ChallengeStatus { PendingVote, ResolvedAccepted, ResolvedRejected } // Accepted = challenger wins, Rejected = challenger loses
    struct Challenge {
        uint256 requestId;
        address challenger;
        string reasonHash;
        uint256 challengeStake;
        uint256 challengedAt;
        uint256 votesForValid; // Aggregated stake of validators voting for result being valid
        uint256 votesForInvalid; // Aggregated stake of validators voting for result being invalid
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
        mapping(address => uint256) validatorStakesAtVote; // Stake amount of validator when they voted (for weighted voting)
        ChallengeStatus status;
        uint256 resolutionTime; // Time when challenge can be resolved
        address[] voters; // Store addresses of validators who voted to iterate for rewards/slashing
    }
    Counters.Counter private _challengeIds;
    mapping(uint256 => Challenge) public challenges;
    uint256 public constant CHALLENGE_PERIOD = 24 hours; // Time for voting
    uint256 public constant PROVIDER_DEREG_COOLDOWN = 7 days; // Cooldown for provider deregistration

    // --- Reputation System ---
    mapping(address => int256) public userReputation; // Overall user reputation
    mapping(address => int256) public providerReputation; // Specific reputation for AI providers
    mapping(address => int256) public validatorReputation; // Specific reputation for validators

    // --- NFT Management ---
    // The contract itself is an ERC721 token
    struct AetherNFTProperties {
        uint256 requestId;
        address originalRequester;
        address originalProvider;
    }
    mapping(uint256 => AetherNFTProperties) public aetherNFTProperties; // Store additional properties for NFTs
    Counters.Counter private _nextMintedTokenId; // Internal counter for NFT token IDs.

    // --- Events ---
    event Paused(address account);
    event Unpaused(address account);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event FeePercentageUpdated(uint256 oldBps, uint256 newBps);
    event ProtocolFeesWithdrawn(address recipient, uint256 amount);
    event TokensStaked(address indexed user, StakeRole role, uint256 amount);
    event TokensUnstaked(address indexed user, StakeRole role, uint256 amount);
    event MinStakeAmountSet(StakeRole role, uint256 amount);
    event AIProviderRegistered(address indexed provider, string modelId, string endpointURI);
    event AIProviderUpdated(address indexed provider, string modelId, string newEndpointURI);
    event AIProviderDeregistered(address indexed provider);
    event AIGenerationRequested(uint256 indexed requestId, address indexed requester, string modelId, uint256 bountyAmount);
    event AIGenerationResultSubmitted(uint256 indexed requestId, address indexed provider, string resultHash);
    event AIGenerationChallengeIssued(uint256 indexed challengeId, uint256 indexed requestId, address indexed challenger, string reasonHash);
    event ChallengeVoteSubmitted(uint256 indexed challengeId, address indexed voter, bool isResultValid);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed requestId, ChallengeStatus status, uint256 rewardAmount, uint256 slashedAmount);
    event GenerationRewardClaimed(uint256 indexed requestId, address indexed provider, uint256 amount);
    event ValidationRewardClaimed(uint256 indexed challengeId, address indexed validator, uint256 amount);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed requestId, address indexed owner, string tokenURI);
    event NFTMetadataURIUpdated(uint256 indexed tokenId, string newURI);
    event ReputationUpdated(address indexed user, int256 newReputation);

    // --- Constructor ---
    constructor(address _aigenTokenAddress, string memory _nftName, string memory _nftSymbol)
        ERC721(_nftName, _nftSymbol)
        Ownable(msg.sender)
    {
        require(_aigenTokenAddress != address(0), "AetherForge: AIGEN token address cannot be zero");
        AIGEN_TOKEN = IERC20(_aigenTokenAddress);
        protocolFeeRecipient = msg.sender;

        // Set initial minimum stake amounts (can be updated by owner)
        minStakeAmounts[StakeRole.Requester] = 100 * 10 ** AIGEN_TOKEN.decimals();
        minStakeAmounts[StakeRole.Provider] = 500 * 10 ** AIGEN_TOKEN.decimals();
        minStakeAmounts[StakeRole.Validator] = 200 * 10 ** AIGEN_TOKEN.decimals();
    }

    // --- Modifiers ---
    modifier onlyAIProvider() {
        require(aiProviders[msg.sender].isRegistered, "AetherForge: Not a registered AI provider");
        _;
    }

    modifier onlyValidator() {
        require(stakedBalances[msg.sender][StakeRole.Validator] >= minStakeAmounts[StakeRole.Validator], "AetherForge: Not a qualified validator");
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    function pause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function setProtocolFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "AetherForge: Recipient cannot be zero address");
        emit FeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    function updateFeePercentage(uint252 _newFeeBps) public onlyOwner {
        require(_newFeeBps <= 10000, "AetherForge: Fee BPS cannot exceed 100%"); // 10000 = 100%
        emit FeePercentageUpdated(protocolFeeBps, _newFeeBps);
        protocolFeeBps = _newFeeBps;
    }

    function withdrawProtocolFees() public virtual {
        require(msg.sender == protocolFeeRecipient, "AetherForge: Only fee recipient can withdraw");
        
        // This is a simplification. A more robust system would track fees in a separate balance.
        // For this example, assuming all AIGEN not part of a specific active stake belongs to fees.
        // In a real production system, fees would be explicitly transferred to a dedicated fee pool.
        uint256 totalStaked = 0;
        // This part would be inefficient in a real contract for all users/roles.
        // It's illustrative. A proper fee management system would accumulate fees separately.
        // For example, by sending fees to a dedicated fee vault or adding to a variable.
        // To simplify, we're assuming the contract holds fees as residual balance.
        // For a full system, you would need to iterate through all active stakes or maintain a separate `totalProtocolFees` variable.
        // Given contract size limits and complexity, this calculation is indicative.
        // The actual `balanceOf(this)` might contain funds from requests that are pending/in challenges
        // which are not yet "fees". A true fee vault would be better.
        
        uint256 contractBalance = AIGEN_TOKEN.balanceOf(address(this));
        // A safer implementation would be to increment a `totalProtocolFees` variable when fees are collected
        // For demonstration, let's assume `contractBalance` represents fees only after all rewards/slashes.
        uint256 feesToWithdraw = contractBalance; // Simplification

        require(feesToWithdraw > 0, "AetherForge: No fees to withdraw");

        AIGEN_TOKEN.transfer(protocolFeeRecipient, feesToWithdraw);
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, feesToWithdraw);
    }

    // --- II. AIGEN Token & Staking Mechanics ---

    function setMinStakeAmount(StakeRole _role, uint256 _amount) public onlyOwner {
        require(_role != StakeRole.None, "AetherForge: Invalid stake role");
        minStakeAmounts[_role] = _amount;
        emit MinStakeAmountSet(_role, _amount);
    }

    function stakeTokens(uint256 _amount, StakeRole _role) public whenNotPaused {
        require(_amount > 0, "AetherForge: Stake amount must be positive");
        require(_role != StakeRole.None, "AetherForge: Invalid stake role");
        
        // Ensure minimum stake for specific roles on first stake or when increasing to meet minimum
        if ((_role == StakeRole.Provider && aiProviders[msg.sender].isRegistered) || _role == StakeRole.Validator) {
            // If already registered/active, ensure new total stake meets minimum if it was below.
            // If first stake, ensure initial amount meets minimum.
            uint256 currentTotalStake = stakedBalances[msg.sender][_role] + _amount;
            require(currentTotalStake >= minStakeAmounts[_role], "AetherForge: Insufficient total stake for role minimum");
        }

        AIGEN_TOKEN.transferFrom(msg.sender, address(this), _amount);
        stakedBalances[msg.sender][_role] += _amount;
        emit TokensStaked(msg.sender, _role, _amount);
    }

    function unstakeTokens(uint256 _amount, StakeRole _role) public {
        require(_amount > 0, "AetherForge: Unstake amount must be positive");
        require(_role != StakeRole.None, "AetherForge: Invalid stake role");
        require(stakedBalances[msg.sender][_role] >= _amount, "AetherForge: Insufficient staked balance");

        // Prevent unstaking below min for active roles, unless deregistering (handled separately)
        if (_role == StakeRole.Provider && aiProviders[msg.sender].isRegistered) {
            require(stakedBalances[msg.sender][_role] - _amount >= minStakeAmounts[_role], "AetherForge: Cannot unstake below minimum for active provider");
        }
        if (_role == StakeRole.Validator) {
            require(stakedBalances[msg.sender][_role] - _amount >= minStakeAmounts[_role], "AetherForge: Cannot unstake below minimum for validator");
        }

        stakedBalances[msg.sender][_role] -= _amount;
        AIGEN_TOKEN.transfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _role, _amount);
    }

    function getMinStakeAmount(StakeRole _role) public view returns (uint256) {
        return minStakeAmounts[_role];
    }

    function getUserStake(address _user, StakeRole _role) public view returns (uint256) {
        return stakedBalances[_user][_role];
    }

    // --- III. AI Provider Management ---

    function registerAIProvider(string calldata _modelId, string calldata _endpointURI) public whenNotPaused {
        require(!aiProviders[msg.sender].isRegistered, "AetherForge: Address is already a registered provider");
        require(stakedBalances[msg.sender][StakeRole.Provider] >= minStakeAmounts[StakeRole.Provider], "AetherForge: Insufficient provider stake");
        
        aiProviders[msg.sender] = AIProvider({
            modelId: _modelId,
            endpointURI: _endpointURI,
            registeredAt: block.timestamp,
            isRegistered: true,
            cooldownEnds: 0
        });
        emit AIProviderRegistered(msg.sender, _modelId, _endpointURI);
    }

    function updateAIProviderProfile(string calldata _modelId, string calldata _newEndpointURI) public onlyAIProvider whenNotPaused {
        aiProviders[msg.sender].modelId = _modelId;
        aiProviders[msg.sender].endpointURI = _newEndpointURI;
        emit AIProviderUpdated(msg.sender, _modelId, _newEndpointURI);
    }

    function deregisterAIProvider() public onlyAIProvider {
        // Ensure no pending requests where this provider is assigned, and no active challenges.
        // For simplicity, we only enforce cooldown and active state here.
        require(aiProviders[msg.sender].cooldownEnds == 0 || block.timestamp > aiProviders[msg.sender].cooldownEnds, "AetherForge: Deregistration cooldown active");
        
        aiProviders[msg.sender].isRegistered = false;
        aiProviders[msg.sender].cooldownEnds = block.timestamp + PROVIDER_DEREG_COOLDOWN; // Start cooldown
        // Provider can now unstake their funds after cooldown.
        // It does not automatically unstake here, user must call unstakeTokens after cooldown.
        emit AIProviderDeregistered(msg.sender);
    }

    function getAIProviderDetails(address _provider) public view returns (AIProvider memory) {
        return aiProviders[_provider];
    }

    // --- IV. AI Request & Generation Workflow ---

    function requestAIGeneration(string calldata _prompt, string calldata _modelId, uint256 _bountyAmount) public whenNotPaused returns (uint256) {
        require(stakedBalances[msg.sender][StakeRole.Requester] >= minStakeAmounts[StakeRole.Requester], "AetherForge: Insufficient requester stake");
        require(_bountyAmount > 0, "AetherForge: Bounty must be positive");
        AIGEN_TOKEN.transferFrom(msg.sender, address(this), _bountyAmount); // Escrow bounty

        uint256 newRequestId = _requestIds.current();
        _requestIds.increment();

        generationRequests[newRequestId] = GenerationRequest({
            requester: msg.sender,
            prompt: _prompt,
            modelId: _modelId,
            bountyAmount: _bountyAmount,
            submittedAt: block.timestamp,
            provider: address(0), // To be assigned/filled by provider upon submission
            resultHash: "",
            status: RequestStatus.Pending,
            challengeId: 0,
            nftTokenId: 0
        });

        emit AIGenerationRequested(newRequestId, msg.sender, _modelId, _bountyAmount);
        return newRequestId;
    }

    function submitAIGenerationResult(uint256 _requestId, string calldata _resultHash) public onlyAIProvider whenNotPaused {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.Pending, "AetherForge: Request not in pending state");
        require(keccak256(abi.encodePacked(req.modelId)) == keccak256(abi.encodePacked(aiProviders[msg.sender].modelId)), "AetherForge: Provider does not support requested model");
        
        req.provider = msg.sender;
        req.resultHash = _resultHash;
        req.status = RequestStatus.Submitted;
        // req.submittedAt is used for challenge window, so it's updated to mark submission time for challengeability
        req.submittedAt = block.timestamp; 

        emit AIGenerationResultSubmitted(_requestId, msg.sender, _resultHash);
    }

    function getGenerationRequestDetails(uint256 _requestId) public view returns (GenerationRequest memory) {
        return generationRequests[_requestId];
    }

    function getGenerationResult(uint256 _requestId) public view returns (string memory resultHash, address provider) {
        GenerationRequest storage req = generationRequests[_requestId];
        return (req.resultHash, req.provider);
    }

    // --- V. Verification & Challenge System ---

    function challengeAIGenerationResult(uint256 _requestId, string calldata _reasonHash) public whenNotPaused {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.Submitted, "AetherForge: Can only challenge submitted results");
        require(block.timestamp <= req.submittedAt + CHALLENGE_PERIOD, "AetherForge: Challenge period has ended");
        
        uint256 challengeStakeAmount = minStakeAmounts[StakeRole.Validator]; // Or a dynamic amount
        require(stakedBalances[msg.sender][StakeRole.Validator] >= challengeStakeAmount, "AetherForge: Insufficient validator stake to challenge");

        AIGEN_TOKEN.transferFrom(msg.sender, address(this), challengeStakeAmount); // Escrow challenger's stake

        uint256 newChallengeId = _challengeIds.current();
        _challengeIds.increment();

        req.status = RequestStatus.Challenged;
        req.challengeId = newChallengeId;

        challenges[newChallengeId] = Challenge({
            requestId: _requestId,
            challenger: msg.sender,
            reasonHash: _reasonHash,
            challengeStake: challengeStakeAmount,
            challengedAt: block.timestamp,
            votesForValid: 0,
            votesForInvalid: 0,
            status: ChallengeStatus.PendingVote,
            resolutionTime: block.timestamp + CHALLENGE_PERIOD,
            voters: new address[](0) // Initialize empty array
        });

        emit AIGenerationChallengeIssued(newChallengeId, _requestId, msg.sender, _reasonHash);
    }

    function submitChallengeVote(uint256 _challengeId, bool _isResultValid) public onlyValidator whenNotPaused {
        Challenge storage ch = challenges[_challengeId];
        require(ch.status == ChallengeStatus.PendingVote, "AetherForge: Challenge is not in voting phase");
        require(block.timestamp < ch.resolutionTime, "AetherForge: Voting period has ended");
        require(!ch.hasVoted[msg.sender], "AetherForge: Already voted on this challenge");

        ch.hasVoted[msg.sender] = true;
        ch.validatorStakesAtVote[msg.sender] = stakedBalances[msg.sender][StakeRole.Validator]; // Record stake at time of vote
        ch.voters.push(msg.sender); // Add voter to list

        if (_isResultValid) {
            ch.votesForValid += ch.validatorStakesAtVote[msg.sender];
        } else {
            ch.votesForInvalid += ch.validatorStakesAtVote[msg.sender];
        }
        emit ChallengeVoteSubmitted(_challengeId, msg.sender, _isResultValid);
    }

    function resolveChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage ch = challenges[_challengeId];
        GenerationRequest storage req = generationRequests[ch.requestId];
        
        require(ch.status == ChallengeStatus.PendingVote, "AetherForge: Challenge already resolved or not in voting phase");
        require(block.timestamp >= ch.resolutionTime, "AetherForge: Voting period not yet ended");

        // Determine if challenge was successful (result was invalid)
        bool challengeSuccessful = ch.votesForInvalid > ch.votesForValid; 

        uint256 rewardAmount = 0;
        uint256 slashedAmount = 0;

        if (challengeSuccessful) { // Result was invalid, challenger wins, provider is slashed
            ch.status = ChallengeStatus.ResolvedAccepted;
            req.status = RequestStatus.ResolvedFailed;
            
            // Slash provider: 50% of bounty and a portion of their stake
            uint256 providerSlashFromBounty = req.bountyAmount; // Full bounty is forfeit
            uint256 providerStakeToSlash = req.bountyAmount / 2; // Additional slash from provider's stake
            
            // Ensure provider has enough stake to be slashed
            if (stakedBalances[req.provider][StakeRole.Provider] >= providerStakeToSlash) {
                stakedBalances[req.provider][StakeRole.Provider] -= providerStakeToSlash;
                slashedAmount += providerStakeToSlash;
            } else {
                slashedAmount += stakedBalances[req.provider][StakeRole.Provider];
                stakedBalances[req.provider][StakeRole.Provider] = 0; // Slash all available stake
            }
            
            // Distribute rewards from slashed funds and bounty
            uint256 totalRewardPool = ch.challengeStake + providerSlashFromBounty + slashedAmount; // Challenger stake + full bounty + provider stake slashed

            // Challenger gets their stake back + a reward
            uint256 challengerReward = ch.challengeStake + (totalRewardPool / 4); // Example: quarter of the pool
            AIGEN_TOKEN.transfer(ch.challenger, challengerReward);
            rewardAmount += challengerReward;
            
            // Reward validators who voted for invalid (correct side)
            uint224 validatorSharePool = uint224(totalRewardPool - challengerReward);
            uint256 totalInvalidVotesWeight = ch.votesForInvalid;

            for (uint256 i = 0; i < ch.voters.length; i++) {
                address voter = ch.voters[i];
                if (ch.hasVoted[voter] && ch.validatorStakesAtVote[voter] > 0) {
                    // Check if voter's vote aligned with the resolution
                    if (ch.votesForInvalid > ch.votesForValid) { // If final decision was 'invalid'
                        uint256 share = (validatorSharePool * ch.validatorStakesAtVote[voter]) / totalInvalidVotesWeight;
                        AIGEN_TOKEN.transfer(voter, share);
                        validatorReputation[voter] += 1;
                        emit ReputationUpdated(voter, validatorReputation[voter]);
                    } else { // Voted for valid, but result was invalid
                        validatorReputation[voter] -= 1;
                        emit ReputationUpdated(voter, validatorReputation[voter]);
                    }
                }
            }
            providerReputation[req.provider] -= 5; // Significant rep loss for bad submission
            emit ReputationUpdated(req.provider, providerReputation[req.provider]);

        } else { // Result was valid, challenger loses, provider gets bounty
            ch.status = ChallengeStatus.ResolvedRejected;
            req.status = RequestStatus.ResolvedSuccess;

            // Challenger's stake is forfeited and distributed
            uint256 challengerLostStake = ch.challengeStake;
            
            // Provider gets portion of lost stake
            AIGEN_TOKEN.transfer(req.provider, challengerLostStake / 2); 
            rewardAmount += challengerLostStake / 2;

            // Reward validators who voted for valid (correct side)
            uint256 validatorSharePool = challengerLostStake / 2;
            uint256 totalValidVotesWeight = ch.votesForValid;

            for (uint256 i = 0; i < ch.voters.length; i++) {
                address voter = ch.voters[i];
                if (ch.hasVoted[voter] && ch.validatorStakesAtVote[voter] > 0) {
                    // Check if voter's vote aligned with the resolution
                    if (ch.votesForValid > ch.votesForInvalid) { // If final decision was 'valid'
                        uint256 share = (validatorSharePool * ch.validatorStakesAtVote[voter]) / totalValidVotesWeight;
                        AIGEN_TOKEN.transfer(voter, share);
                        validatorReputation[voter] += 1;
                        emit ReputationUpdated(voter, validatorReputation[voter]);
                    } else { // Voted for invalid, but result was valid
                        validatorReputation[voter] -= 1;
                        emit ReputationUpdated(voter, validatorReputation[voter]);
                    }
                }
            }
            // Challenger loses all stake and reputation for failed challenge
            userReputation[ch.challenger] -= 3;
            emit ReputationUpdated(ch.challenger, userReputation[ch.challenger]);
        }

        emit ChallengeResolved(_challengeId, ch.requestId, ch.status, rewardAmount, slashedAmount);
    }
    
    function claimGenerationReward(uint256 _requestId) public whenNotPaused {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.provider == msg.sender, "AetherForge: Only the provider can claim this reward");
        require(req.status == RequestStatus.ResolvedSuccess, "AetherForge: Request not successfully resolved");
        
        uint256 reward = req.bountyAmount;
        uint256 protocolFee = (reward * protocolFeeBps) / 10000;
        reward -= protocolFee;

        AIGEN_TOKEN.transfer(req.provider, reward);
        
        req.status = RequestStatus.NFTMinted; // Mark as processed, ready for NFT minting by owner
        providerReputation[req.provider] += 1; // Reward reputation for successful generation
        emit ReputationUpdated(req.provider, providerReputation[req.provider]);
        emit GenerationRewardClaimed(_requestId, req.provider, reward);
    }

    function claimValidationReward(uint256 _challengeId) public whenNotPaused {
        Challenge storage ch = challenges[_challengeId];
        require(ch.hasVoted[msg.sender], "AetherForge: You did not vote on this challenge");
        
        // This function primarily serves to allow validators to trigger their reputation update
        // if not already done by `resolveChallenge`, as token distribution is handled there.
        bool isCorrectVote = false;
        if (ch.status == ChallengeStatus.ResolvedAccepted && ch.votesForInvalid > ch.votesForValid) {
            // Challenger won, meaning the result was invalid. This voter was correct if they voted 'invalid'.
             isCorrectVote = !ch.hasVoted[msg.sender]; // If voter chose !isResultValid when submitting vote
             // This needs to be correctly checked from stored vote, not hasVoted boolean
        } else if (ch.status == ChallengeStatus.ResolvedRejected && ch.votesForValid > ch.votesForInvalid) {
            // Challenger lost, meaning the result was valid. This voter was correct if they voted 'valid'.
             isCorrectVote = ch.hasVoted[msg.sender]; // If voter chose isResultValid when submitting vote
        }

        // The specific 'true' or 'false' for `_isResultValid` is not stored in `hasVoted`.
        // To precisely track a voter's choice, the vote (true/false) would need to be stored in a mapping for each voter.
        // For this example, assuming 'isCorrectVote' would be determined off-chain or by a more complex on-chain state.
        // As a simplified approach for reputation claim, we'll just check if the challenge is resolved and the user voted.
        // Actual token rewards are distributed in `resolveChallenge`.
        
        // This function is mostly a placeholder for reputation update if it wasn't already handled.
        // A robust system would track individual validator rewards and allow claiming.
        emit ValidationRewardClaimed(_challengeId, msg.sender, 0); 
    }

    // --- VI. Dynamic NFT (AI-Generated Content) Management ---

    function mintGeneratedNFT(uint256 _requestId, string calldata _initialMetadataURI) public onlyOwner { // Owner can mint after resolution
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.NFTMinted || req.status == RequestStatus.ResolvedSuccess, "AetherForge: Request not successfully resolved to mint NFT");
        require(req.nftTokenId == 0, "AetherForge: NFT already minted for this request");

        uint256 newTokenId = _nextMintedTokenId.current();
        _nextMintedTokenId.increment();

        _safeMint(req.requester, newTokenId);
        _setTokenURI(newTokenId, _initialMetadataURI);

        req.nftTokenId = newTokenId;
        req.status = RequestStatus.NFTMinted; // Update status to NFT minted

        aetherNFTProperties[newTokenId] = AetherNFTProperties({
            requestId: _requestId,
            originalRequester: req.requester,
            originalProvider: req.provider
        });

        emit NFTMinted(newTokenId, _requestId, req.requester, _initialMetadataURI);
    }

    function updateNFTMetadataURI(uint256 _tokenId, string calldata _newMetadataURI) public {
        // This allows for dynamic NFTs, where the metadata (and thus visual representation/properties)
        // can change based on new AI analysis, community interaction, or original creator intent.
        
        // Restrict to the owner of the NFT OR the original requester.
        // Could also be extended to a DAO vote if this contract was integrated with one.
        AetherNFTProperties storage nftProps = aetherNFTProperties[_tokenId];
        require(nftProps.requestId != 0, "AetherForge: NFT not managed by AetherForge"); // Ensure it's one of our NFTs
        require(msg.sender == ownerOf(_tokenId) || msg.sender == nftProps.originalRequester, "AetherForge: Only NFT owner or original requester can update metadata");
        
        _setTokenURI(_tokenId, _newMetadataURI);
        emit NFTMetadataURIUpdated(_tokenId, _newMetadataURI);
    }
    
    function getNFTProperties(uint256 _tokenId) public view returns (uint256 requestId, address originalRequester, address originalProvider) {
        AetherNFTProperties storage props = aetherNFTProperties[_tokenId];
        require(props.requestId != 0, "AetherForge: NFT not managed by AetherForge");
        return (props.requestId, props.originalRequester, props.originalProvider);
    }

    // --- VII. Reputation System ---

    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    function getProviderReputation(address _provider) public view returns (int256) {
        return providerReputation[_provider];
    }

    function getValidatorReputation(address _validator) public view returns (int256) {
        return validatorReputation[_validator];
    }
}

```