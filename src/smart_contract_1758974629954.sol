This smart contract, `AIGenesisHub`, introduces a novel platform for decentralized, AI-powered content generation, focusing on verifiable outputs, reputation-gated access to AI models, and a community-driven approach to model refinement. It aims to create a vibrant ecosystem where users can generate unique digital assets (NFTs), monetize their prompt engineering skills, and collectively improve AI models.

### `AIGenesisHub` Contract

**Outline:**

1.  **Core Infrastructure & Access:** Manages global settings, trusted oracle address, and the ERC20 payment token.
2.  **User Identity & Reputation:** Manages user profiles and non-transferable reputation scores (akin to Soulbound Tokens or SBTs) through skill attestations.
3.  **AI Model Registry & Management:** Allows anyone to register AI models (pointing to off-chain APIs), sets access costs and reputation thresholds, and facilitates staking for premium access.
4.  **Content Generation & NFT Minting:** Orchestrates the process of requesting AI generation, verifies the output via a trusted oracle, and mints dynamic ERC721 NFTs that can be further "evolved."
5.  **Prompt Engineering & Market:** Provides a marketplace for users to submit, purchase, and manage their engineered prompts, which are crucial inputs for AI generation.
6.  **Decentralized AI Model Refinement:** Enables community members to propose datasets for AI model improvement and vote on their inclusion, fostering collective intelligence.
7.  **Royalty & Payouts:** Manages the distribution of fees and earnings to model owners, prompt creators, and the protocol.

**Function Summary:**

**I. Core Infrastructure & Access**
1.  `constructor(uint256 _protocolFeeBps, IERC20 _erc20PaymentToken)`: Initializes the contract, deploys its internal `AIGenesisNFT` contract, sets the initial protocol fee, and specifies the ERC20 token for all transactions.
2.  `updateOracleAddress(address _newOracle)`: Allows the contract owner to update the address of the trusted oracle responsible for verifying AI output.
3.  `setProtocolFee(uint256 _newFeeBps)`: Allows the contract owner to adjust the platform's transaction fee in basis points.
4.  `setERC20PaymentToken(IERC20 _token)`: Allows the contract owner to set/update the ERC20 token used for payments and staking (careful use recommended after initial setup).

**II. User & Reputation Management (SBT-like)**
5.  `registerUserProfile(string memory _username, string memory _metadataURI)`: Users can create or update their on-chain profile, including a username and metadata URI.
6.  `attestSkill(address _recipient, bytes32 _skillHash, string memory _verifierURI)`: Allows users to attest specific skills for others, which contributes to the recipient's non-transferable `reputationScore`.
7.  `_updateReputationScore(address _user, int256 _change)`: An internal helper function to modify a user's reputation score, called by other internal logic (e.g., successful generations, governance participation).
8.  `getReputationScore(address _user)`: A public view function to retrieve any user's current reputation score.

**III. AI Model Registry & Management**
9.  `registerAIModel(string memory _name, string memory _description, string memory _endpointURI, uint256 _accessCost, uint256 _reputationThreshold, address _payoutAddress)`: Allows anyone to register a new AI model, specifying its off-chain endpoint, access cost, required user reputation, and payout address.
10. `updateAIModel(uint256 _modelId, string memory _name, string memory _description, string memory _endpointURI, uint256 _accessCost, uint256 _reputationThreshold, address _payoutAddress)`: Enables the model owner (or protocol owner) to update details of an existing registered AI model.
11. `stakeForModelAccess(uint256 _modelId, uint256 _amount)`: Users can stake ERC20 tokens for a specific model to gain premium access, potentially bypassing reputation thresholds or unlocking special features.
12. `withdrawModelStake(uint256 _modelId)`: Allows users to withdraw their staked tokens after a defined cooldown period.
13. `voteOnModelQuality(uint256 _modelId, bool _isGood)`: Users with sufficient reputation can vote on the quality of an AI model, influencing its visibility or ranking within the hub.

**IV. Content Generation & NFT Minting**
14. `requestContentGeneration(uint256 _modelId, uint256 _promptId, string memory _customPromptText, string memory _additionalParams, uint256 _desiredQuantity)`: Initiates an off-chain AI content generation request using a specified model and prompt (either from the marketplace or custom). Funds are paid upfront.
15. `receiveGeneratedContent(uint256 _requestId, string memory _outputURI, string memory _verificationHash, string memory _metadataURI)`: Callable *only* by the trusted oracle. This function confirms the successful off-chain AI generation, processes payments, updates reputation, and mints a new `AIGenesisNFT` with the generated content URI.
16. `evolveContentNFT(uint256 _tokenId, uint256 _newModelId, string memory _evolutionPrompt, string memory _additionalParams)`: Allows an existing NFT owner to use another AI model to "evolve" or modify their NFT. This triggers a new generation request and would conceptually update the NFT's metadata/URI upon verification.
17. `_mintGeneratedNFT(address _to, uint256 _tokenId, string memory _tokenURI, string memory _metadataURI)`: An internal helper function to mint new NFTs using the deployed `AIGenesisNFT` contract.

**V. Prompt Management & Marketplace**
18. `submitPrompt(string memory _promptText, string memory _description, uint256 _price)`: Users can submit their expertly crafted prompts to the marketplace, optionally setting a price for others to use them.
19. `purchasePrompt(uint256 _promptId)`: Allows a user to purchase a premium prompt, granting them indefinite access to use it in generation requests.
20. `updatePromptPrice(uint256 _promptId, uint256 _newPrice)`: The owner of a prompt can adjust its price in the marketplace.
21. `getPromptDetails(uint256 _promptId)`: A public view function to retrieve the details of a specific prompt.

**VI. Decentralized AI Model Refinement**
22. `proposeDatasetInclusion(string memory _datasetHash, string memory _datasetURI, string memory _description, uint256 _modelIdTarget)`: Users can propose datasets for potential inclusion in the training or refinement of specific AI models, contributing to their improvement.
23. `voteOnDatasetInclusion(uint256 _proposalId, bool _approve)`: Reputation-gated voting allows eligible users to cast their vote on proposed datasets. Sufficient approval can lead to the dataset being flagged for off-chain model integration.

**VII. Royalty & Payouts**
24. `claimProceeds()`: Allows model owners, prompt creators, and the protocol owner to claim their accumulated earnings from content generation fees and prompt sales.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For payment/staking

// Custom error definitions for gas efficiency and clarity
error Unauthorized();
error InvalidId(uint256 _id);
error InsufficientFunds();
error ReputationTooLow(uint256 required, uint256 current);
error ModelNotActive();
error PromptNotAvailable();
error AlreadyStaked();
error NoStakeFound();
error CooldownActive(uint256 remainingTime);
error VerificationFailed(string reason);
error AlreadyClaimed();
error NotYourPrompt();
error SelfAttestationNotAllowed();
error DatasetAlreadyProposed();
error AlreadyVoted();
error ModelDoesNotExist();


/**
 * @title IAIGenesisNFT
 * @dev Interface for the AIGenesisNFT contract to allow the hub to mint and update NFTs.
 *      This pattern decouples the hub logic from the specific NFT implementation.
 */
interface IAIGenesisNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external;
    function exists(uint256 tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}


/**
 * @title AIGenesisHub
 * @dev A smart contract platform for AI-powered generative content creation,
 *      featuring reputation-gated access to AI models, a prompt marketplace,
 *      dynamic NFTs, and a decentralized dataset curation system.
 *
 * Outline:
 * 1.  Core Infrastructure & Access: Manages global settings, oracle.
 * 2.  User Identity & Reputation: Manages user profiles and non-transferable reputation scores (SBT-like).
 * 3.  AI Model Registry & Management: Registers, updates, and controls access to AI models.
 * 4.  Content Generation & NFT Minting: Orchestrates AI generation requests and mints dynamic NFTs.
 * 5.  Prompt Engineering & Market: Allows users to submit, buy, and sell engineered prompts.
 * 6.  Staking & Economic Model: Handles staking for model access and royalty distribution.
 * 7.  Decentralized AI Model Refinement: Enables community-driven dataset proposals and voting.
 * 8.  Royalty & Payouts: Facilitates claiming of accumulated earnings.
 *
 * Function Summary:
 *
 * I. Core Infrastructure & Access
 *    1.  constructor(uint256 _protocolFeeBps, IERC20 _erc20PaymentToken): Initializes contract, deploys AIGenesisNFT, sets owner and fees.
 *    2.  updateOracleAddress(address _newOracle): Updates the trusted oracle address for AI output verification.
 *    3.  setProtocolFee(uint256 _newFeeBps): Sets the platform's cut in basis points (e.g., 100 = 1%).
 *    4.  setERC20PaymentToken(IERC20 _token): Sets the ERC20 token used for payments and staking.
 *
 * II. User & Reputation Management (SBT-like)
 *    5.  registerUserProfile(string memory _username, string memory _metadataURI): Creates/updates a user's on-chain profile.
 *    6.  attestSkill(address _recipient, bytes32 _skillHash, string memory _verifierURI): Allows users to attest skills for others, influencing reputation.
 *    7.  _updateReputationScore(address _user, int256 _change): Internal: Adjusts a user's reputation score.
 *    8.  getReputationScore(address _user): Views a user's current reputation score.
 *
 * III. AI Model Registry & Management
 *    9.  registerAIModel(string memory _name, string memory _description, string memory _endpointURI, uint256 _accessCost, uint256 _reputationThreshold, address _payoutAddress): Registers a new AI model with its parameters.
 *    10. updateAIModel(uint256 _modelId, string memory _name, string memory _description, string memory _endpointURI, uint256 _accessCost, uint256 _reputationThreshold, address _payoutAddress): Allows model owners to update their registered model details.
 *    11. stakeForModelAccess(uint256 _modelId, uint256 _amount): Users stake tokens to gain premium access or features for a model.
 *    12. withdrawModelStake(uint256 _modelId): Users can withdraw their stake after a cooldown period.
 *    13. voteOnModelQuality(uint256 _modelId, bool _isGood): Reputation-gated voting on model quality, affecting its visibility/ranking.
 *
 * IV. Content Generation & NFT Minting
 *    14. requestContentGeneration(uint256 _modelId, uint256 _promptId, string memory _customPromptText, string memory _additionalParams, uint256 _desiredQuantity): Initiates an off-chain AI generation process.
 *    15. receiveGeneratedContent(uint256 _requestId, string memory _outputURI, string memory _verificationHash, string memory _metadataURI): Callable by the trusted oracle to confirm generation and mint NFT.
 *    16. evolveContentNFT(uint256 _tokenId, uint256 _newModelId, string memory _evolutionPrompt, string memory _additionalParams): Allows an NFT owner to update/evolve their NFT using another AI model.
 *    17. _mintGeneratedNFT(address _to, uint256 _tokenId, string memory _tokenURI, string memory _metadataURI): Internal: Mints an NFT via the deployed IAIGenesisNFT contract.
 *
 * V. Prompt Management & Marketplace
 *    18. submitPrompt(string memory _promptText, string memory _description, uint256 _price): Users can submit and optionally sell their engineered prompts.
 *    19. purchasePrompt(uint256 _promptId): Buys access to a premium prompt.
 *    20. updatePromptPrice(uint256 _promptId, uint256 _newPrice): Prompt owner can adjust its price.
 *    21. getPromptDetails(uint256 _promptId): Views prompt information.
 *
 * VI. Decentralized AI Model Refinement
 *    22. proposeDatasetInclusion(string memory _datasetHash, string memory _datasetURI, string memory _description, uint256 _modelIdTarget): Allows users to propose datasets for AI model training/refinement.
 *    23. voteOnDatasetInclusion(uint256 _proposalId, bool _approve): Reputation-gated voting on dataset proposals.
 *
 * VII. Royalty & Payouts
 *    24. claimProceeds(): Allows users (model owners, prompt creators, protocol) to claim their accumulated earnings.
 */
contract AIGenesisHub is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Core Infrastructure
    address public oracleAddress;
    uint256 public protocolFeeBps; // Basis points, e.g., 100 = 1% (1%)
    IERC20 public paymentToken;
    IAIGenesisNFT public aigNFT; // The NFT contract for generated assets

    // Counters for unique IDs
    Counters.Counter private _nextRequestId;
    Counters.Counter private _nextModelId;
    Counters.Counter private _nextPromptId;
    Counters.Counter private _nextDatasetProposalId;
    Counters.Counter private _nextNFTTokenId;

    // User & Reputation Management
    struct UserProfile {
        string username;
        string metadataURI; // IPFS hash or similar for additional profile data
        uint256 reputationScore;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(bytes32 => bool)) public attestedSkills; // user => skillHash => bool (simple unique attestation)

    // AI Model Management
    struct AIModel {
        string name;
        string description;
        string endpointURI; // Off-chain API endpoint for the AI model
        uint256 accessCost; // Cost per generation request (in paymentToken)
        uint256 reputationThreshold; // Minimum reputation to use this model
        address owner; // Address of the model provider
        address payoutAddress; // Where model owner's earnings go
        bool isActive;
        uint256 totalGenerations;
        uint256 totalVotesPositive;
        uint256 totalVotesNegative;
    }
    mapping(uint256 => AIModel) public aiModels;

    // Model Staking
    struct ModelStake {
        uint256 amount;
        uint256 lastStakeTime; // Timestamp of the last stake/update, for cooldown
    }
    mapping(uint256 => mapping(address => ModelStake)) public modelStakes; // modelId => staker => ModelStake
    uint256 public constant MODEL_STAKE_COOLDOWN = 7 days; // Cooldown period for withdrawing stakes

    // Content Generation Requests
    struct GenerationRequest {
        address requester;
        uint256 modelId;
        uint256 promptId; // 0 if custom prompt
        string customPromptText;
        string additionalParams;
        uint256 desiredQuantity;
        uint256 costPaid;
        bool fulfilled;
        uint256 timestamp;
        // The tokenId will be stored when fulfilled or can be deduced from events
    }
    mapping(uint256 => GenerationRequest) public generationRequests;

    // Prompt Management
    struct Prompt {
        address owner;
        string promptText;
        string description;
        uint256 price; // Price in paymentToken to use this prompt
        bool isActive;
    }
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => mapping(address => bool)) public purchasedPrompts; // promptId => user => hasAccess

    // Dataset Proposals
    struct DatasetProposal {
        address proposer;
        string datasetHash; // Unique hash of the dataset content (e.g., IPFS CID)
        string datasetURI;  // URI to the dataset (e.g., IPFS gateway link)
        string description;
        uint256 modelIdTarget; // Model this dataset is proposed for
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true
        bool approved; // True if approved by governance criteria
        bool exists;
    }
    mapping(uint256 => DatasetProposal) public datasetProposals;
    uint256 public constant DATASET_VOTE_THRESHOLD_REPUTATION = 100; // Min reputation to vote on datasets
    uint256 public constant DATASET_APPROVAL_VOTES_REQUIRED = 20; // Example: Minimum positive votes
    uint256 public constant DATASET_APPROVAL_DIFF_REQUIRED = 10; // Example: Positive votes must exceed negative by this much

    // Royalty & Payouts
    mapping(address => uint256) public accruedEarnings; // Address => amount in paymentToken

    // --- Events ---
    event ProfileRegistered(address indexed user, string username, string metadataURI);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event SkillAttested(address indexed recipient, address indexed attester, bytes32 skillHash, string verifierURI);

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 accessCost);
    event ModelUpdated(uint256 indexed modelId, string name, uint256 accessCost);
    event ModelStakeChanged(uint256 indexed modelId, address indexed staker, uint256 amount, bool isStake);
    event ModelQualityVoted(uint256 indexed modelId, address indexed voter, bool isGood);

    event ContentGenerationRequested(uint252 indexed requestId, address indexed requester, uint252 modelId, uint252 promptId, uint252 cost);
    event ContentGenerated(uint252 indexed requestId, uint252 indexed tokenId, address indexed recipient, string outputURI, string metadataURI);
    event NFTMetadataUpdated(uint252 indexed tokenId, string newTokenURI);

    event PromptSubmitted(uint252 indexed promptId, address indexed owner, string description, uint252 price);
    event PromptPurchased(uint252 indexed promptId, address indexed purchaser, uint252 price);
    event PromptPriceUpdated(uint252 indexed promptId, uint252 newPrice);

    event DatasetProposed(uint252 indexed proposalId, address indexed proposer, uint252 modelIdTarget, string datasetHash);
    event DatasetVoteCast(uint252 indexed proposalId, address indexed voter, bool approved);
    event DatasetApproved(uint252 indexed proposalId, uint252 modelIdTarget, string datasetHash);

    event FundsClaimed(address indexed beneficiary, uint252 amount);

    /**
     * @dev Constructor initializes the contract, deploys the AIGenesisNFT, and sets initial parameters.
     * @param _protocolFeeBps The initial protocol fee in basis points (e.g., 100 for 1%).
     * @param _erc20PaymentToken The address of the ERC20 token used for payments and staking.
     */
    constructor(uint256 _protocolFeeBps, IERC20 _erc20PaymentToken) Ownable(msg.sender) {
        protocolFeeBps = _protocolFeeBps;
        paymentToken = _erc20PaymentToken;

        // Deploy the internal NFT contract
        aigNFT = new AIGenesisNFT(address(this)); // The hub is the minter
    }

    // --- I. Core Infrastructure & Access ---

    /**
     * @dev Updates the trusted oracle address. Only callable by the contract owner.
     *      The oracle is responsible for verifying off-chain AI generation outputs.
     * @param _newOracle The new address of the trusted oracle.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
    }

    /**
     * @dev Sets the protocol fee in basis points. Only callable by the contract owner.
     * @param _newFeeBps The new fee in basis points (e.g., 100 for 1%).
     */
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        if (_newFeeBps > 10000) revert InsufficientFunds(); // "Fee cannot exceed 100%" - using InsufficientFunds as a generic economic error
        protocolFeeBps = _newFeeBps;
    }

    /**
     * @dev Sets the ERC20 token used for all payments and staking within the hub.
     *      Can only be called once, during initialization or by owner if no transactions have happened.
     * @param _token The address of the new ERC20 payment token.
     */
    function setERC20PaymentToken(IERC20 _token) external onlyOwner {
        // Potentially add more robust checks for changing token after operations
        paymentToken = _token;
    }

    // --- II. User & Reputation Management (SBT-like) ---

    /**
     * @dev Registers or updates a user's on-chain profile. This is self-service.
     * @param _username The desired username.
     * @param _metadataURI URI pointing to off-chain profile metadata (e.g., IPFS).
     */
    function registerUserProfile(string memory _username, string memory _metadataURI) external {
        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].metadataURI = _metadataURI;
        userProfiles[msg.sender].exists = true;
        emit ProfileRegistered(msg.sender, _username, _metadataURI);
    }

    /**
     * @dev Allows a user to attest a skill for another user. This contributes to the recipient's reputation.
     *      This is a basic attestation, a more complex system could involve token-gated attesters or slashing.
     * @param _recipient The address of the user receiving the skill attestation.
     * @param _skillHash A unique hash representing the skill (e.g., keccak256("Solidity Developer")).
     * @param _verifierURI URI pointing to the attester's proof/context for the skill.
     */
    function attestSkill(address _recipient, bytes32 _skillHash, string memory _verifierURI) external {
        if (_recipient == msg.sender) revert SelfAttestationNotAllowed();
        if (attestedSkills[_recipient][_skillHash]) {
            // Skill already attested by this person for this recipient.
            // For simplicity, we prevent double counting for reputation from the same attester-recipient-skill tuple.
            return;
        }

        userProfiles[_recipient].reputationScore += 5; // Example: +5 reputation per attestation
        attestedSkills[_recipient][_skillHash] = true;
        emit SkillAttested(_recipient, msg.sender, _skillHash, _verifierURI);
        emit ReputationUpdated(_recipient, userProfiles[_recipient].reputationScore);
    }

    /**
     * @dev Internal function to update a user's reputation score.
     *      Called by other internal logic, e.g., successful generations, dispute resolutions.
     * @param _user The address of the user whose reputation is being updated.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function _updateReputationScore(address _user, int256 _change) internal {
        // Ensure reputation doesn't go below zero
        if (_change < 0 && uint256(-_change) > userProfiles[_user].reputationScore) {
            userProfiles[_user].reputationScore = 0;
        } else {
            userProfiles[_user].reputationScore = uint256(int256(userProfiles[_user].reputationScore) + _change);
        }
        emit ReputationUpdated(_user, userProfiles[_user].reputationScore);
    }

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    // --- III. AI Model Registry & Management ---

    /**
     * @dev Registers a new AI model with the platform. Callable by any user.
     * @param _name The name of the AI model.
     * @param _description A description of the model.
     * @param _endpointURI The off-chain API endpoint for the AI model.
     * @param _accessCost The cost per generation request (in paymentToken).
     * @param _reputationThreshold The minimum reputation to use this model.
     * @param _payoutAddress The address where the model owner's earnings go.
     * @return The ID of the newly registered model.
     */
    function registerAIModel(
        string memory _name,
        string memory _description,
        string memory _endpointURI,
        uint256 _accessCost,
        uint256 _reputationThreshold,
        address _payoutAddress
    ) external returns (uint256) {
        _nextModelId.increment();
        uint256 modelId = _nextModelId.current();
        aiModels[modelId] = AIModel({
            name: _name,
            description: _description,
            endpointURI: _endpointURI,
            accessCost: _accessCost,
            reputationThreshold: _reputationThreshold,
            owner: msg.sender,
            payoutAddress: _payoutAddress,
            isActive: true,
            totalGenerations: 0,
            totalVotesPositive: 0,
            totalVotesNegative: 0
        });
        emit ModelRegistered(modelId, msg.sender, _name, _accessCost);
        return modelId;
    }

    /**
     * @dev Allows the model owner (or contract owner) to update an existing AI model's details.
     * @param _modelId The ID of the model to update.
     * @param _name The new name of the AI model.
     * @param _description A new description of the model.
     * @param _endpointURI The new off-chain API endpoint for the AI model.
     * @param _accessCost The new cost (in paymentToken) to use this model.
     * @param _reputationThreshold The new minimum reputation required.
     * @param _payoutAddress The new address for model owner's earnings.
     */
    function updateAIModel(
        uint256 _modelId,
        string memory _name,
        string memory _description,
        string memory _endpointURI,
        uint256 _accessCost,
        uint256 _reputationThreshold,
        address _payoutAddress
    ) external {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert ModelDoesNotExist(); // Check if model exists
        if (model.owner != msg.sender && owner() != msg.sender) revert Unauthorized();

        model.name = _name;
        model.description = _description;
        model.endpointURI = _endpointURI;
        model.accessCost = _accessCost;
        model.reputationThreshold = _reputationThreshold;
        model.payoutAddress = _payoutAddress;
        emit ModelUpdated(_modelId, _name, _accessCost);
    }

    /**
     * @dev Users can stake `paymentToken` to gain special access to certain models
     *      (e.g., bypass reputation, early access to new features, higher request limits).
     * @param _modelId The ID of the model to stake for.
     * @param _amount The amount of `paymentToken` to stake.
     */
    function stakeForModelAccess(uint256 _modelId, uint256 _amount) external {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert ModelDoesNotExist(); // Check if model exists

        if (_amount == 0) revert InsufficientFunds();

        paymentToken.transferFrom(msg.sender, address(this), _amount);

        modelStakes[_modelId][msg.sender].amount += _amount;
        modelStakes[_modelId][msg.sender].lastStakeTime = block.timestamp;
        emit ModelStakeChanged(_modelId, msg.sender, _amount, true);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens for a specific model after a cooldown period.
     * @param _modelId The ID of the model the user staked for.
     */
    function withdrawModelStake(uint256 _modelId) external {
        ModelStake storage stake = modelStakes[_modelId][msg.sender];
        if (stake.amount == 0) revert NoStakeFound();
        if (block.timestamp < stake.lastStakeTime + MODEL_STAKE_COOLDOWN) {
            revert CooldownActive(stake.lastStakeTime + MODEL_STAKE_COOLDOWN - block.timestamp);
        }

        uint256 amountToWithdraw = stake.amount;
        stake.amount = 0;
        stake.lastStakeTime = 0; // Reset
        paymentToken.transfer(msg.sender, amountToWithdraw);
        emit ModelStakeChanged(_modelId, msg.sender, amountToWithdraw, false);
    }

    /**
     * @dev Allows users with sufficient reputation to vote on the quality of an AI model.
     *      This influences the model's perceived quality/ranking.
     * @param _modelId The ID of the AI model being voted on.
     * @param _isGood True if the vote is positive, false for negative.
     */
    function voteOnModelQuality(uint256 _modelId, bool _isGood) external {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert ModelDoesNotExist();
        if (userProfiles[msg.sender].reputationScore < 50) revert ReputationTooLow(50, userProfiles[msg.sender].reputationScore); // Example: Min rep for voting

        // A more advanced system might prevent re-voting or have vote decay
        if (_isGood) {
            model.totalVotesPositive++;
            _updateReputationScore(msg.sender, 1); // Reward for contributing to quality assessment
        } else {
            model.totalVotesNegative++;
            // Small penalty for negative contribution, or only reward positive.
            // For now, no negative rep for voting 'bad' to encourage honest feedback.
        }
        emit ModelQualityVoted(_modelId, msg.sender, _isGood);
    }

    // --- IV. Content Generation & NFT Minting ---

    /**
     * @dev Requests the generation of content using a specified AI model and prompt.
     *      Funds are transferred to the contract, awaiting oracle verification and NFT minting.
     * @param _modelId The ID of the AI model to use.
     * @param _promptId The ID of a registered prompt to use (0 if using a custom prompt).
     * @param _customPromptText Custom prompt text if _promptId is 0.
     * @param _additionalParams Additional parameters for the AI model (e.g., style, resolution).
     * @param _desiredQuantity How many variations/items to generate (future expansion, currently defaults to 1).
     * @return The ID of the generation request.
     */
    function requestContentGeneration(
        uint256 _modelId,
        uint256 _promptId,
        string memory _customPromptText,
        string memory _additionalParams,
        uint256 _desiredQuantity
    ) external returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0) || !model.isActive) revert ModelNotActive();
        if (userProfiles[msg.sender].reputationScore < model.reputationThreshold) {
            // Check for staked access bypass
            if (modelStakes[_modelId][msg.sender].amount == 0) {
                revert ReputationTooLow(model.reputationThreshold, userProfiles[msg.sender].reputationScore);
            }
        }

        uint256 totalCost = model.accessCost;
        if (_promptId != 0) {
            Prompt storage prompt = prompts[_promptId];
            if (prompt.owner == address(0) || !prompt.isActive) revert PromptNotAvailable();
            // If prompt is priced and not owned/purchased, user needs to buy it.
            if (prompt.price > 0 && prompt.owner != msg.sender && !purchasedPrompts[_promptId][msg.sender]) {
                revert PromptNotAvailable(); // User must purchase prompt first
            }
            // For generation, we add the prompt price to total cost for payout
            totalCost += prompt.price;
        }

        if (_desiredQuantity == 0) _desiredQuantity = 1; // Default to 1 for simplicity in this version
        totalCost *= _desiredQuantity;

        // Ensure user has enough allowance for the contract to pull tokens
        paymentToken.transferFrom(msg.sender, address(this), totalCost);

        _nextRequestId.increment();
        uint256 requestId = _nextRequestId.current();

        generationRequests[requestId] = GenerationRequest({
            requester: msg.sender,
            modelId: _modelId,
            promptId: _promptId,
            customPromptText: _customPromptText,
            additionalParams: _additionalParams,
            desiredQuantity: _desiredQuantity,
            costPaid: totalCost,
            fulfilled: false,
            timestamp: block.timestamp
        });

        emit ContentGenerationRequested(requestId, msg.sender, _modelId, _promptId, totalCost);
        return requestId;
    }

    /**
     * @dev Callable by the trusted oracle to confirm off-chain AI generation and mint the NFT.
     *      The oracle provides a verification hash to ensure integrity.
     * @param _requestId The ID of the original generation request.
     * @param _outputURI URI of the generated content (e.g., IPFS link to image/audio).
     * @param _verificationHash A cryptographic hash (e.g., signed hash by oracle) proving content origin/validity.
     * @param _metadataURI URI for the NFT metadata (could contain attributes, prompt used, model, etc.).
     */
    function receiveGeneratedContent(
        uint256 _requestId,
        string memory _outputURI,
        string memory _verificationHash, // This would be an attestation from the oracle
        string memory _metadataURI
    ) external {
        if (msg.sender != oracleAddress) revert Unauthorized(); // Only the trusted oracle can call this

        GenerationRequest storage req = generationRequests[_requestId];
        if (req.requester == address(0) || req.fulfilled) revert InvalidId(_requestId); // Check if request exists and not fulfilled

        // TODO: Implement actual verification logic using _verificationHash.
        // For instance, hash _outputURI, _requestId, etc. and check if _verificationHash is a valid signature from oracle.
        // For this example, we trust the oracle's call, but a real system would have robust on-chain validation of the proof.
        if (bytes(_verificationHash).length == 0) revert VerificationFailed("Missing verification hash");

        req.fulfilled = true;

        // Calculate fees and distribute earnings
        uint256 totalPaid = req.costPaid;
        uint256 protocolShare = (totalPaid * protocolFeeBps) / 10000;
        uint256 remainingForCreators = totalPaid - protocolShare;

        accruedEarnings[owner()] += protocolShare; // Protocol earnings

        // Distribute remaining to model owner and prompt creator
        AIModel storage model = aiModels[req.modelId];
        uint256 modelPayout = 0;
        uint256 promptPayout = 0;

        if (req.promptId != 0) {
            Prompt storage prompt = prompts[req.promptId];
            if (prompt.price > 0) {
                // If the prompt had an explicit price, the prompt creator gets it directly (multiplied by quantity requested)
                promptPayout = prompt.price * req.desiredQuantity;
                if (promptPayout > remainingForCreators) promptPayout = remainingForCreators; // Cap to avoid over-payout
                accruedEarnings[prompt.owner] += promptPayout;
                remainingForCreators -= promptPayout;
            }
        }
        
        // Model owner gets what's left
        modelPayout = remainingForCreators;
        accruedEarnings[model.payoutAddress] += modelPayout;

        model.totalGenerations += req.desiredQuantity;
        _updateReputationScore(req.requester, 10); // Reward requester for successful generation

        // Mint NFT for each desired quantity (for simplicity, only 1 for now, but loop could be added)
        _nextNFTTokenId.increment();
        uint256 newTokenId = _nextNFTTokenId.current();
        _mintGeneratedNFT(req.requester, newTokenId, _outputURI, _metadataURI);

        emit ContentGenerated(req.requestId, newTokenId, req.requester, _outputURI, _metadataURI);
    }

    /**
     * @dev Internal function to mint a new NFT using the deployed IAIGenesisNFT contract.
     * @param _to The recipient of the NFT.
     * @param _tokenId The unique ID for the NFT.
     * @param _tokenURI URI for the NFT content (e.g., IPFS link to the image/media).
     * @param _metadataURI URI for the NFT metadata. (Note: In ERC721, tokenURI usually points to metadata JSON)
     */
    function _mintGeneratedNFT(address _to, uint256 _tokenId, string memory _tokenURI, string memory _metadataURI) internal {
        aigNFT.mint(_to, _tokenId, _tokenURI);
        // We'll use updateTokenURI to set the metadata URI for dynamic updates
        aigNFT.updateTokenURI(_tokenId, _metadataURI);
    }

    /**
     * @dev Allows an NFT owner to "evolve" or modify their existing NFT using another AI model.
     *      This triggers a new generation request and upon verification, updates the NFT's metadata/URI.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _newModelId The ID of the new AI model to use for evolution.
     * @param _evolutionPrompt The prompt for the evolution process.
     * @param _additionalParams Additional parameters for the AI model.
     */
    function evolveContentNFT(
        uint256 _tokenId,
        uint256 _newModelId,
        string memory _evolutionPrompt,
        string memory _additionalParams
    ) external {
        if (!aigNFT.exists(_tokenId)) revert InvalidId(_tokenId);
        if (aigNFT.ownerOf(_tokenId) != msg.sender) revert Unauthorized();

        AIModel storage model = aiModels[_newModelId];
        if (model.owner == address(0) || !model.isActive) revert ModelNotActive();
        if (userProfiles[msg.sender].reputationScore < model.reputationThreshold) {
            if (modelStakes[_newModelId][msg.sender].amount == 0) {
                revert ReputationTooLow(model.reputationThreshold, userProfiles[msg.sender].reputationScore);
            }
        }

        uint256 totalCost = model.accessCost;
        paymentToken.transferFrom(msg.sender, address(this), totalCost);

        // This would typically trigger an off-chain process similar to requestContentGeneration,
        // which then calls back with a new URI to update the existing NFT.
        // For simplicity, we just process the fee and emit a request event.
        // A dedicated `receiveEvolvedContent(uint256 _originalTokenId, string memory _newOutputURI, string memory _newMetadataURI)`
        // would be needed, callable by oracle, to actually update the NFT.
        
        uint256 protocolShare = (totalCost * protocolFeeBps) / 10000;
        accruedEarnings[owner()] += protocolShare;
        accruedEarnings[model.payoutAddress] += totalCost - protocolShare;
        _updateReputationScore(msg.sender, 5); // Reward for evolving content

        // Emit an event signaling an evolution request, the actual update happens once verified.
        // We'll use a special request ID (e.g., `type(uint256).max` or a separate counter) for evolution requests
        // to differentiate from initial generation requests if needed. For now, use a new generation request ID.
        _nextRequestId.increment();
        uint256 evolutionRequestId = _nextRequestId.current();

        generationRequests[evolutionRequestId] = GenerationRequest({
            requester: msg.sender,
            modelId: _newModelId,
            promptId: 0, // Evolution prompt is custom, not from market
            customPromptText: _evolutionPrompt,
            additionalParams: _additionalParams,
            desiredQuantity: 1, // Always 1 for evolving an existing NFT
            costPaid: totalCost,
            fulfilled: false,
            timestamp: block.timestamp
        });

        // The oracle would then pick up this request, perform the off-chain evolution,
        // and call a hypothetical `receiveEvolvedContent(evolutionRequestId, _tokenId, new_output_uri, new_metadata_uri)`
        // For now, let's update the existing tokenURI directly within the hub for simplicity, 
        // assuming the `_evolutionPrompt` instantly leads to a new `_outputURI` & `_metadataURI` (not ideal for real dApp).
        // A more robust system uses the oracle to call a separate 'updateNFTContent' function.
        // For this example, we skip the immediate update, and rely on the oracle's callback logic.
        emit ContentGenerationRequested(
            evolutionRequestId,
            msg.sender,
            _newModelId,
            0,
            totalCost
        );
    }


    // --- V. Prompt Management & Marketplace ---

    /**
     * @dev Allows users to submit their engineered prompts for others to use or purchase.
     * @param _promptText The actual prompt string.
     * @param _description A description of the prompt.
     * @param _price The price (in paymentToken) to use this prompt. 0 for free.
     * @return The ID of the newly submitted prompt.
     */
    function submitPrompt(string memory _promptText, string memory _description, uint256 _price) external returns (uint256) {
        _nextPromptId.increment();
        uint256 promptId = _nextPromptId.current();
        prompts[promptId] = Prompt({
            owner: msg.sender,
            promptText: _promptText,
            description: _description,
            price: _price,
            isActive: true
        });
        emit PromptSubmitted(promptId, msg.sender, _description, _price);
        return promptId;
    }

    /**
     * @dev Allows a user to purchase a premium prompt. After purchase, they get indefinite access.
     * @param _promptId The ID of the prompt to purchase.
     */
    function purchasePrompt(uint256 _promptId) external {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.owner == address(0) || !prompt.isActive) revert InvalidId(_promptId);
        if (prompt.owner == msg.sender) return; // Owner doesn't need to purchase
        if (purchasedPrompts[_promptId][msg.sender]) return; // Already purchased

        if (paymentToken.balanceOf(msg.sender) < prompt.price) revert InsufficientFunds();
        paymentToken.transferFrom(msg.sender, address(this), prompt.price);

        accruedEarnings[prompt.owner] += prompt.price; // Prompt owner gets the full price
        purchasedPrompts[_promptId][msg.sender] = true;
        _updateReputationScore(msg.sender, 2); // Small rep gain for prompt purchasing

        emit PromptPurchased(_promptId, msg.sender, prompt.price);
    }

    /**
     * @dev Allows the prompt owner to update the price of their prompt.
     * @param _promptId The ID of the prompt to update.
     * @param _newPrice The new price in paymentToken.
     */
    function updatePromptPrice(uint256 _promptId, uint256 _newPrice) external {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.owner == address(0)) revert InvalidId(_promptId); // Check if prompt exists
        if (prompt.owner != msg.sender) revert NotYourPrompt();

        prompt.price = _newPrice;
        emit PromptPriceUpdated(_promptId, _newPrice);
    }

    /**
     * @dev Retrieves details of a specific prompt.
     * @param _promptId The ID of the prompt.
     * @return promptText, description, price, owner, isActive
     */
    function getPromptDetails(uint256 _promptId) external view returns (string memory, string memory, uint256, address, bool) {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.owner == address(0)) revert InvalidId(_promptId);
        return (prompt.promptText, prompt.description, prompt.price, prompt.owner, prompt.isActive);
    }

    // --- VI. Decentralized AI Model Refinement ---

    /**
     * @dev Allows users to propose datasets for potential inclusion in AI model training or refinement.
     *      This is a community-driven approach to improving models.
     * @param _datasetHash A unique identifier/hash of the dataset.
     * @param _datasetURI URI pointing to the dataset (e.g., IPFS link).
     * @param _description A description of the dataset and its relevance.
     * @param _modelIdTarget The ID of the AI model this dataset is intended for.
     * @return The ID of the newly created dataset proposal.
     */
    function proposeDatasetInclusion(
        string memory _datasetHash,
        string memory _datasetURI,
        string memory _description,
        uint256 _modelIdTarget
    ) external returns (uint256) {
        // Basic check if a model exists
        if (aiModels[_modelIdTarget].owner == address(0)) revert ModelDoesNotExist();

        // Check for existing proposals with the same hash for the same model
        // This is a simple O(N) check; for many proposals, a mapping (modelId => datasetHash => proposalId) would be better.
        for (uint256 i = 1; i <= _nextDatasetProposalId.current(); i++) {
            DatasetProposal storage existingProposal = datasetProposals[i];
            if (existingProposal.exists && keccak256(abi.encodePacked(existingProposal.datasetHash)) == keccak256(abi.encodePacked(_datasetHash)) && existingProposal.modelIdTarget == _modelIdTarget) {
                revert DatasetAlreadyProposed();
            }
        }

        _nextDatasetProposalId.increment();
        uint256 proposalId = _nextDatasetProposalId.current();

        datasetProposals[proposalId] = DatasetProposal({
            proposer: msg.sender,
            datasetHash: _datasetHash,
            datasetURI: _datasetURI,
            description: _description,
            modelIdTarget: _modelIdTarget,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            approved: false,
            exists: true
        });

        _updateReputationScore(msg.sender, 5); // Reward for proposing a dataset
        emit DatasetProposed(proposalId, msg.sender, _modelIdTarget, _datasetHash);
        return proposalId;
    }

    /**
     * @dev Allows users with sufficient reputation to vote on dataset inclusion proposals.
     *      Approved datasets could lead to off-chain model updates.
     * @param _proposalId The ID of the dataset proposal to vote on.
     * @param _approve True for a positive vote, false for a negative vote.
     */
    function voteOnDatasetInclusion(uint256 _proposalId, bool _approve) external {
        DatasetProposal storage proposal = datasetProposals[_proposalId];
        if (!proposal.exists) revert InvalidId(_proposalId);
        if (userProfiles[msg.sender].reputationScore < DATASET_VOTE_THRESHOLD_REPUTATION) {
            revert ReputationTooLow(DATASET_VOTE_THRESHOLD_REPUTATION, userProfiles[msg.sender].reputationScore);
        }
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        proposal.hasVoted[msg.sender] = true;

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Simple approval logic: if votesFor are significantly higher and meet a minimum count
        if (proposal.votesFor >= DATASET_APPROVAL_VOTES_REQUIRED &&
            proposal.votesFor > proposal.votesAgainst + DATASET_APPROVAL_DIFF_REQUIRED) {
            proposal.approved = true;
            emit DatasetApproved(_proposalId, proposal.modelIdTarget, proposal.datasetHash);
            _updateReputationScore(proposal.proposer, 20); // Reward proposer for successful approval
        }

        _updateReputationScore(msg.sender, 1); // Reward for participating in governance
        emit DatasetVoteCast(_proposalId, msg.sender, _approve);
    }

    // --- VII. Royalty & Payouts ---

    /**
     * @dev Allows users to claim their accumulated earnings from model usage, prompt sales, etc.
     */
    function claimProceeds() external {
        uint256 amount = accruedEarnings[msg.sender];
        if (amount == 0) revert AlreadyClaimed(); // No earnings to claim
        accruedEarnings[msg.sender] = 0;
        paymentToken.transfer(msg.sender, amount);
        emit FundsClaimed(msg.sender, amount);
    }
}

/**
 * @title AIGenesisNFT
 * @dev An ERC721 contract specifically for NFTs generated through the AIGenesisHub.
 *      Minting and URI updates are restricted to the AIGenesisHub contract,
 *      making these NFTs "dynamic" as their appearance can evolve via AI.
 */
contract AIGenesisNFT is ERC721 {
    address public immutable aigGenesisHub; // Address of the AIGenesisHub contract

    constructor(address _aigGenesisHub) ERC721("AIGenesis Content", "AIGEN") {
        aigGenesisHub = _aigGenesisHub;
    }

    modifier onlyHub() {
        if (msg.sender != aigGenesisHub) revert Unauthorized();
        _;
    }

    /**
     * @dev Mints a new NFT. Only callable by the AIGenesisHub contract.
     * @param to The address to mint the NFT to.
     * @param tokenId The ID of the NFT to mint.
     * @param tokenURI The URI for the NFT's metadata/content. (This should be the metadata JSON URI)
     */
    function mint(address to, uint256 tokenId, string calldata tokenURI) external onlyHub {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    /**
     * @dev Updates the URI of an existing NFT. Only callable by the AIGenesisHub contract.
     *      This is crucial for "evolving" dynamic NFTs, as it changes what the NFT represents.
     * @param tokenId The ID of the NFT to update.
     * @param newTokenURI The new URI for the NFT's metadata/content.
     */
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external onlyHub {
        if (!_exists(tokenId)) revert InvalidId(tokenId);
        _setTokenURI(tokenId, newTokenURI);
    }

    /**
     * @dev Returns whether the given token ID exists.
     *      Override ERC721's _exists to use in `IAIGenesisNFT`.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidId(tokenId);
        return _tokenURIs[tokenId];
    }
}
```