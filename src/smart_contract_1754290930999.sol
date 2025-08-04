This smart contract, `AetherialCanvasDAO`, is designed as a decentralized platform for AI-assisted generative art creation, curation, and evolution, integrating a dynamic NFT marketplace, a reputation system, and on-chain governance. It aims to create a self-sustaining ecosystem where community members drive the artistic process and benefit from successful creations.

**Core Concepts:**
1.  **AI Integration (Simulated Oracle):** The contract provides interfaces for an off-chain AI agent (via the `AI_AGENT_ROLE`) to mint new art NFTs based on community prompts and update their metadata during "evolution."
2.  **Dynamic NFTs (`AetherArtNFT`):** Art pieces are represented as ERC-721 NFTs whose metadata (e.g., quality score, visual representation, evolution history) can change based on community evaluation and further AI processing.
3.  **Reputation System:** Users earn reputation points for positive contributions like submitting successful prompts and providing insightful art evaluations. Reputation influences voting power and reward distribution.
4.  **Adaptive Royalties:** Royalties for original prompt creators are not fixed but dynamically adjust based on their accumulated reputation and the aggregated quality score of their art.
5.  **Community-Driven Curation & Evolution:** DAO members vote on prompt suitability, evaluate generated art, and propose/vote on "art evolutions" that trigger further AI enhancements.
6.  **Decentralized Governance:** A basic DAO structure allows members with reputation to propose and vote on significant platform changes.

---

### **Outline and Function Summary**

**I. Contract Core & Roles**
*   **`constructor()`**: Initializes the DAO, deploys the native utility token (`AETHCToken`) and the dynamic NFT contract (`AetherArtNFT`), and sets up initial roles.
*   **`grantRole(bytes32 role, address account)`**: Grants a specified role (e.g., `OPERATOR_ROLE`, `AI_AGENT_ROLE`) to an account. Only callable by an admin. (Inherited from OpenZeppelin `AccessControl`).
*   **`revokeRole(bytes32 role, address account)`**: Revokes a specified role from an account. Only callable by an admin. (Inherited from OpenZeppelin `AccessControl`).
*   **`setDaoVotingThreshold(uint256 newThreshold)`**: Sets the minimum aggregated reputation (voting power) required for a governance proposal to pass.

**II. Token & NFT Interaction**
*   **`depositAETHC(uint256 amount)`**: Allows users to deposit `AETHC` tokens into the contract to stake for prompts, participate in governance, or purchase NFTs.
*   **`withdrawAETHC(uint256 amount)`**: Allows users to withdraw their available (unstaked/unlocked) `AETHC` tokens held within the contract.
*   **`getArtDetails(uint256 tokenId)`**: Retrieves comprehensive details about a specific `AetherArtNFT`, including its metadata, prompt, and evolution history.
*   **`listArtForSale(uint256 tokenId, uint256 price)`**: Allows the owner of an `AetherArtNFT` to list it for sale on the platform's internal marketplace at a specified `AETHC` price.
*   **`buyArt(uint256 tokenId)`**: Enables users to purchase a listed `AetherArtNFT`, automatically handling `AETHC` transfers and ownership, including dynamic royalty distribution.

**III. Prompt Submission & AI Generation Lifecycle**
*   **`submitArtPrompt(string memory _promptText, uint256 _stakeAmount)`**: Users submit a textual prompt for AI art generation, staking `AETHC` tokens as a commitment.
*   **`voteOnPromptSuitability(uint256 _promptId, bool _isSuitable)`**: DAO members vote on the artistic and ethical suitability of a submitted prompt, using their reputation as voting power.
*   **`approvePromptForGeneration(uint256 _promptId)`**: Called by an `OPERATOR_ROLE` to officially approve a prompt for AI generation, typically after a successful community vote.
*   **`requestAIGeneration(uint256 _promptId)`**: Called by an `OPERATOR_ROLE` after prompt approval, simulating a request to an external AI service to generate art based on the prompt.
*   **`recordAIGenerationResult(uint256 _promptId, string memory _uri, uint256 _initialQualityScore, bool _success)`**: Called by an `AI_AGENT_ROLE` to record the outcome of an AI generation. If successful, it mints a new `AetherArtNFT` and attaches initial metadata.

**IV. Art Curation & Evolution**
*   **`submitArtEvaluation(uint256 _tokenId, uint8 _scoreVisuals, uint8 _scoreConcept, uint8 _scorePromptAdherence)`**: Curators submit detailed evaluations of generated art pieces, influencing the art's aggregated quality score and their own reputation.
*   **`proposeArtEvolution(uint256 _tokenId, string memory _evolutionPrompt)`**: DAO members can propose an "evolution" for an existing art piece, providing a new prompt for potential further AI processing or metadata updates.
*   **`voteOnArtEvolutionProposal(uint256 _proposalId, bool _forEvolution)`**: DAO members cast votes on proposed art evolutions. (Uses internal `_voteOnProposal` helper).
*   **`triggerArtEvolution(uint256 _proposalId)`**: Called by an `OPERATOR_ROLE` if an art evolution proposal passes, initiating the next AI phase for the art piece based on the evolution prompt.
*   **`updateArtMetadata(uint256 _tokenId, string memory _newUri, uint256 _newQualityScore, string memory _newEvolutionHistory)`**: Called by an `AI_AGENT_ROLE` to update an `AetherArtNFT`'s metadata (e.g., URI, quality score, evolution history) after an evolution or re-evaluation process.

**V. Reputation & Dynamic Rewards**
*   **`getUserReputation(address _user)`**: Retrieves the current reputation score of a user, reflecting their positive contributions to the platform.
*   **`claimPromptCreatorRewards(uint256 _promptId)`**: Allows the original prompt creator to claim their staked `AETHC` back plus a bonus based on the generated art's quality.
*   **`claimCuratorRewards(uint256 _evaluationId)`**: Allows curators to claim `AETHC` rewards for impactful and accurate art evaluations, scaled by their reputation and the evaluation's score.
*   **`getDynamicRoyalty(uint256 _tokenId)`**: Public view function that calculates and returns the current dynamic royalty percentage (in basis points) for an art piece, based on its creator's reputation and the art's aggregated quality score.

**VI. DAO Governance**
*   **`createGovernanceProposal(string memory _description, address _targetContract, bytes memory _calldata)`**: Allows eligible users to create a generic governance proposal (e.g., adjust contract parameters, transfer treasury funds) to be voted on by the DAO.
*   **`voteOnGovernanceProposal(uint256 _proposalId, bool _support)`**: DAO members cast votes on active generic governance proposals. (Uses internal `_voteOnProposal` helper).
*   **`executeGovernanceProposal(uint256 _proposalId)`**: Called by an `OPERATOR_ROLE` to execute a generic governance proposal that has met the voting threshold and grace period, triggering the specified target contract call.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom Errors for Gas Efficiency and Clarity ---
error AetherialCanvas__InvalidAmount();
error AetherialCanvas__NotEnoughStaked();
error AetherialCanvas__TransferFailed();
error AetherialCanvas__PromptNotFound(uint256 promptId);
error AetherialCanvas__PromptNotApproved(uint256 promptId);
error AetherialCanvas__PromptAlreadyProcessed(uint256 promptId);
error AetherialCanvas__AlreadyVoted();
error AetherialCanvas__ArtNotFound(uint256 tokenId);
error AetherialCanvas__NotArtOwner();
error AetherialCanvas__ContractNotApprovedForTransfer();
error AetherialCanvas__ArtNotForSale(uint256 tokenId);
error AetherialCanvas__InsufficientPayment(uint256 required, uint256 provided);
error AetherialCanvas__InvalidScore();
error AetherialCanvas__EvaluationNotFound(uint256 evaluationId);
error AetherialCanvas__AlreadyClaimed();
error AetherialCanvas__NotEnoughVotingPower();
error AetherialCanvas__ProposalNotFound(uint256 proposalId);
error AetherialCanvas__ProposalNotActive();
error AetherialCanvas__ProposalExpired();
error AetherialCanvas__ProposalNotPassed();
error AetherialCanvas__ProposalAlreadyExecuted();
error AetherialCanvas__UnauthorizedCall(address caller);
error AetherialCanvas__InvalidProposalType();
error AetherialCanvas__SelfEvaluationForbidden();

// --- AETHCToken: A simple ERC20 for the DAO's native currency ---
contract AETHCToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Aether Canvas Token", "AETHC") {
        _mint(msg.sender, initialSupply); // Mints initial supply to the deployer
    }
}

// --- AetherArtNFT: A dynamic ERC721 for AI-generated art ---
contract AetherArtNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Role that can update NFT metadata (granted to the main DAO contract)
    bytes32 public constant METADATA_UPDATER_ROLE = keccak256("METADATA_UPDATER_ROLE");

    // Mapping to store evolution history for each token
    mapping(uint256 => string[]) public evolutionHistory;

    constructor(address _daoAddress) ERC721("Aether Art", "AART") {
        // Grant the DAO contract `DEFAULT_ADMIN_ROLE` to manage this contract (minting, setting base URI etc.)
        _grantRole(DEFAULT_ADMIN_ROLE, _daoAddress);
        // Grant the DAO contract the `METADATA_UPDATER_ROLE` so it can trigger metadata updates via AI_AGENT_ROLE
        _grantRole(METADATA_UPDATER_ROLE, _daoAddress);
    }

    /// @notice Allows the contract admin to set the base URI for NFT metadata.
    /// @param newBaseURI The new base URI (e.g., IPFS gateway).
    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    /// @notice Mints a new Aether Art NFT. Only callable by the DAO contract.
    /// @param to The recipient of the new NFT.
    /// @param _tokenURI The URI pointing to the NFT's metadata.
    /// @param _initialEvolutionStep A description of the initial creation step.
    /// @return The ID of the newly minted token.
    function mint(address to, string memory _tokenURI, string memory _initialEvolutionStep)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Only the DAO contract (as admin) can mint
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        evolutionHistory[newItemId].push(_initialEvolutionStep); // Record initial state

        emit TokenMinted(newItemId, to, _tokenURI);
        return newItemId;
    }

    /// @notice Allows an authorized `METADATA_UPDATER_ROLE` to update a token's URI and add to its evolution history.
    /// @param tokenId The ID of the NFT to update.
    /// @param newTokenURI The new URI for the updated metadata.
    /// @param newEvolutionStep A description of the latest evolution step.
    function updateTokenURIAndEvolution(uint256 tokenId, string memory newTokenURI, string memory newEvolutionStep)
        public
        onlyRole(METADATA_UPDATER_ROLE)
    {
        if (! _exists(tokenId)) {
            revert AetherialCanvas__ArtNotFound(tokenId);
        }
        _setTokenURI(tokenId, newTokenURI);
        evolutionHistory[tokenId].push(newEvolutionStep);

        emit TokenUpdated(tokenId, newTokenURI);
    }

    // Events specific to AetherArtNFT
    event TokenMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event TokenUpdated(uint256 indexed tokenId, string newTokenURI);
}


// --- Main AetherialCanvasDAO Contract ---
contract AetherialCanvasDAO is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Roles ---
    // OPERATOR_ROLE: For triggering AI requests, approving prompts, and executing governance proposals.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    // AI_AGENT_ROLE: For recording AI generation results and updating NFT metadata based on AI output.
    bytes32 public constant AI_AGENT_ROLE = keccak256("AI_AGENT_ROLE");

    // --- Contract References ---
    AETHCToken public immutable AETHC;
    AetherArtNFT public immutable AetherArt;

    // --- Counters for unique IDs ---
    Counters.Counter private _promptIdCounter;
    Counters.Counter private _evaluationIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public daoVotingThreshold; // Minimum aggregated reputation required for a proposal to pass

    // --- Enums ---
    enum ProposalType {
        Generic,      // For general DAO governance actions
        ArtEvolution  // For proposals specifically to evolve an art piece
    }

    // --- Structs ---
    struct Prompt {
        uint256 id;
        address creator;
        string promptText;
        uint256 stakeAmount; // AETHC staked by the creator
        bool approved;       // True if DAO approved for AI generation
        bool generated;      // True if AI generation was attempted
        uint256 generatedTokenId; // ID of the minted NFT if successful (0 if not)
        uint256 timestamp;
        uint256 votesForSuitability;
        uint256 votesAgainstSuitability;
        mapping(address => bool) hasVotedOnSuitability; // Track who voted on prompt suitability
    }

    struct ArtEvaluation {
        uint256 id;
        uint256 tokenId;
        address curator;
        uint8 scoreVisuals;         // 0-100
        uint8 scoreConcept;         // 0-100
        uint8 scorePromptAdherence; // 0-100
        uint256 timestamp;
        bool claimed;               // True if curator has claimed their rewards
    }

    struct ArtMetaData {
        uint256 qualityScore;       // Aggregated score from evaluations (0-100, can exceed 100 with evolution)
        uint256 lastEvaluatedTimestamp;
        uint256 timesEvolved;       // How many times this art piece has evolved
        uint256 promptId;           // Link back to the original prompt
        uint256 listedPrice;        // If listed for sale, 0 if not
        address listedBy;           // Address that listed it for sale (0x0 if not listed)
    }

    struct GovernanceProposal {
        uint256 id;
        string description;
        address proposer;
        address targetContract;     // For Generic proposals, the contract to call
        bytes calldataPayload;      // For Generic proposals, the data to send
        ProposalType proposalType;  // Type of the proposal
        uint256 associatedTokenId;  // For ArtEvolution proposals, the NFT ID
        string evolutionPrompt;     // For ArtEvolution proposals, the new prompt
        uint256 startBlock;         // Block number when voting starts
        uint256 endBlock;           // Block number when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;              // True if the proposal has been executed
        bool passed;                // True if the proposal passed the vote (after voting ends)
        mapping(address => bool) hasVoted; // Track who voted on this proposal
    }

    // --- Mappings ---
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => ArtEvaluation) public evaluations;
    mapping(uint256 => ArtMetaData) public artMetadata; // tokenId => ArtMetaData
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    mapping(address => uint256) public userReputation; // Address => Reputation Score (influences voting power, rewards)
    mapping(address => uint256) public stakedBalances; // User's AETHC held by the contract for staking/payments

    // --- Events ---
    event PromptSubmitted(uint256 indexed promptId, address indexed creator, string promptText, uint256 stakeAmount);
    event PromptSuitabilityVoted(uint256 indexed promptId, address indexed voter, bool isSuitable);
    event PromptApproved(uint256 indexed promptId);
    event AIGenerationRequested(uint256 indexed promptId);
    event AIGenerationResult(uint256 indexed promptId, uint256 indexed tokenId, string uri, uint256 initialQualityScore, bool success);

    event ArtEvaluationSubmitted(uint256 indexed evaluationId, uint256 indexed tokenId, address indexed curator, uint8 scoreVisuals, uint8 scoreConcept, uint8 scorePromptAdherence);
    event ArtMetadataUpdated(uint256 indexed tokenId, uint256 newQualityScore);
    event ArtEvolutionProposed(uint256 indexed proposalId, uint256 indexed tokenId, string evolutionPrompt, address proposer);
    event ArtEvolutionVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ArtEvolutionTriggered(uint256 indexed proposalId, uint256 indexed tokenId);

    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event PromptCreatorRewardsClaimed(uint256 indexed promptId, address indexed creator, uint256 rewardAmount);
    event CuratorRewardsClaimed(uint256 indexed evaluationId, address indexed curator, uint256 rewardAmount);

    event ArtListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 creatorRoyalty);

    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address indexed proposer, address targetContract, bytes calldataPayload, ProposalType proposalType);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event DaoVotingThresholdSet(uint256 newThreshold);

    // --- Constructor ---
    constructor(uint256 initialAETHCSupply) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is the initial admin
        _grantRole(OPERATOR_ROLE, msg.sender); // Deployer is also an initial operator
        _grantRole(AI_AGENT_ROLE, msg.sender); // Deployer is also an initial AI agent

        AETHC = new AETHCToken(initialAETHCSupply);
        AetherArt = new AetherArtNFT(address(this)); // DAO contract is the admin & metadata updater of the NFT contract

        daoVotingThreshold = 10; // Initial threshold for governance proposals (e.g., 10 reputation points)
    }

    // --- I. Contract Core & Roles ---
    // `grantRole` and `revokeRole` are inherited from OpenZeppelin's `AccessControl`

    /// @notice Sets the minimum aggregated reputation (voting power) required for a governance proposal to pass.
    /// @param newThreshold The new threshold value in reputation points.
    function setDaoVotingThreshold(uint256 newThreshold) public onlyRole(OPERATOR_ROLE) {
        daoVotingThreshold = newThreshold;
        emit DaoVotingThresholdSet(newThreshold);
    }

    // --- II. Token & NFT Interaction ---

    /// @notice Allows users to deposit AETHC tokens into the contract for staking or other activities.
    /// @param amount The amount of AETHC to deposit.
    function depositAETHC(uint256 amount) public nonReentrant {
        if (amount == 0) revert AetherialCanvas__InvalidAmount();
        AETHC.transferFrom(msg.sender, address(this), amount); // Requires caller to have approved this contract
        stakedBalances[msg.sender] += amount;
    }

    /// @notice Allows users to withdraw their available (unstaked/unlocked) AETHC tokens.
    /// @param amount The amount of AETHC to withdraw.
    function withdrawAETHC(uint256 amount) public nonReentrant {
        if (amount == 0 || stakedBalances[msg.sender] < amount) {
            revert AetherialCanvas__NotEnoughStaked();
        }
        stakedBalances[msg.sender] -= amount;
        AETHC.transfer(msg.sender, amount);
    }

    /// @notice Retrieves comprehensive details about a specific AetherArt NFT.
    /// @param tokenId The ID of the AetherArt NFT.
    /// @return ArtMetaData struct containing quality, evolution, price, etc.
    /// @return promptText The original prompt text that generated this art.
    function getArtDetails(uint256 tokenId) public view returns (ArtMetaData memory, string memory) {
        if (!AetherArt.exists(tokenId)) {
            revert AetherialCanvas__ArtNotFound(tokenId);
        }
        return (artMetadata[tokenId], prompts[artMetadata[tokenId].promptId].promptText);
    }

    /// @notice Allows the owner of an AetherArt NFT to list it for sale on the platform's internal marketplace.
    /// The contract must be approved to transfer the NFT.
    /// @param tokenId The ID of the AetherArt NFT to list.
    /// @param price The price in AETHC tokens.
    function listArtForSale(uint256 tokenId, uint256 price) public nonReentrant {
        if (AetherArt.ownerOf(tokenId) != msg.sender) {
            revert AetherialCanvas__NotArtOwner();
        }
        // Ensure the DAO contract has approval to transfer the NFT
        if (AetherArt.getApproved(tokenId) != address(this) && !AetherArt.isApprovedForAll(msg.sender, address(this))) {
             revert AetherialCanvas__ContractNotApprovedForTransfer();
        }
        artMetadata[tokenId].listedPrice = price;
        artMetadata[tokenId].listedBy = msg.sender;
        emit ArtListedForSale(tokenId, msg.sender, price);
    }

    /// @notice Enables users to purchase a listed AetherArt NFT.
    /// Requires the buyer to have enough AETHC deposited into the contract.
    /// @param tokenId The ID of the AetherArt NFT to purchase.
    function buyArt(uint256 tokenId) public nonReentrant {
        if (!AetherArt.exists(tokenId) || artMetadata[tokenId].listedPrice == 0) {
            revert AetherialCanvas__ArtNotForSale(tokenId);
        }

        uint256 price = artMetadata[tokenId].listedPrice;
        address seller = artMetadata[tokenId].listedBy;
        address creator = prompts[artMetadata[tokenId].promptId].creator;

        if (stakedBalances[msg.sender] < price) { // Check if buyer has enough AETHC staked
            revert AetherialCanvas__InsufficientPayment(price, stakedBalances[msg.sender]);
        }

        uint256 creatorRoyalty = (price * calculateDynamicRoyalty(tokenId)) / 10000; // Royalty in basis points (e.g., 500 = 5%)
        uint256 sellerProceeds = price - creatorRoyalty;

        // Transfer funds internally
        stakedBalances[msg.sender] -= price;
        stakedBalances[seller] += sellerProceeds;
        stakedBalances[creator] += creatorRoyalty; // Royalty to original creator

        // Transfer NFT ownership
        AetherArt.safeTransferFrom(seller, msg.sender, tokenId);

        // Clear listing
        artMetadata[tokenId].listedPrice = 0;
        artMetadata[tokenId].listedBy = address(0);

        emit ArtSold(tokenId, seller, msg.sender, price, creatorRoyalty);
    }

    // --- III. Prompt Submission & AI Generation Lifecycle ---

    /// @notice Users submit a textual prompt for AI art generation, staking AETHC tokens as a commitment.
    /// The stake serves as a bond and a potential reward pool.
    /// @param _promptText The creative text prompt for the AI.
    /// @param _stakeAmount The amount of AETHC to stake for this prompt.
    function submitArtPrompt(string memory _promptText, uint256 _stakeAmount) public nonReentrant {
        if (_stakeAmount == 0 || stakedBalances[msg.sender] < _stakeAmount) {
            revert AetherialCanvas__InvalidAmount();
        }

        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();

        prompts[newPromptId] = Prompt({
            id: newPromptId,
            creator: msg.sender,
            promptText: _promptText,
            stakeAmount: _stakeAmount,
            approved: false,
            generated: false,
            generatedTokenId: 0,
            timestamp: block.timestamp,
            votesForSuitability: 0,
            votesAgainstSuitability: 0
        });

        stakedBalances[msg.sender] -= _stakeAmount; // Lock staked amount
        // The _stakeAmount will be released or used for rewards/penalties later

        emit PromptSubmitted(newPromptId, msg.sender, _promptText, _stakeAmount);
    }

    /// @notice DAO members vote on the artistic and ethical suitability of a submitted prompt.
    /// Voting power is based on the voter's reputation.
    /// @param _promptId The ID of the prompt to vote on.
    /// @param _isSuitable True if the prompt is deemed suitable, false otherwise.
    function voteOnPromptSuitability(uint256 _promptId, bool _isSuitable) public {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.id == 0) revert AetherialCanvas__PromptNotFound(_promptId);
        if (prompt.approved || prompt.generated) revert AetherialCanvas__PromptAlreadyProcessed(_promptId); // Cannot vote on processed prompts
        if (prompt.hasVotedOnSuitability[msg.sender]) revert AetherialCanvas__AlreadyVoted();

        uint256 voterReputation = userReputation[msg.sender];
        if (voterReputation == 0) revert AetherialCanvas__NotEnoughVotingPower(); // Must have reputation to vote

        if (_isSuitable) {
            prompt.votesForSuitability += voterReputation;
        } else {
            prompt.votesAgainstSuitability += voterReputation;
        }
        prompt.hasVotedOnSuitability[msg.sender] = true;

        emit PromptSuitabilityVoted(_promptId, msg.sender, _isSuitable);
    }

    /// @notice Called by an `OPERATOR_ROLE` to approve a prompt for AI generation based on community votes.
    /// @param _promptId The ID of the prompt to approve.
    function approvePromptForGeneration(uint256 _promptId) public onlyRole(OPERATOR_ROLE) {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.id == 0) revert AetherialCanvas__PromptNotFound(_promptId);
        if (prompt.approved) revert AetherialCanvas__PromptAlreadyProcessed(_promptId); // Already approved

        // Simplified logic: If total positive votes exceed negative and a minimum threshold
        if (prompt.votesForSuitability > prompt.votesAgainstSuitability && prompt.votesForSuitability >= daoVotingThreshold) {
            prompt.approved = true;
            emit PromptApproved(_promptId);
        } else {
             revert AetherialCanvas__ProposalNotPassed(); // Prompt did not meet approval criteria
        }
    }

    /// @notice Called by an `OPERATOR_ROLE` after a prompt is approved, triggering an external AI service request.
    /// This function simulates requesting an off-chain AI computation via an oracle.
    /// @param _promptId The ID of the prompt to generate art for.
    function requestAIGeneration(uint256 _promptId) public onlyRole(OPERATOR_ROLE) {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.id == 0) revert AetherialCanvas__PromptNotFound(_promptId);
        if (!prompt.approved) revert AetherialCanvas__PromptNotApproved(_promptId);
        if (prompt.generated) revert AetherialCanvas__PromptAlreadyProcessed(_promptId); // Already requested/generated

        // In a real system, this would interact with an oracle (e.g., Chainlink)
        // to send the prompt off-chain for AI processing.
        // For this example, we just mark it as requested.

        emit AIGenerationRequested(_promptId);
    }

    /// @notice Called by an `AI_AGENT_ROLE` to record the outcome of an AI generation.
    /// If successful, it mints an NFT and attaches initial metadata.
    /// @param _promptId The ID of the prompt that was generated.
    /// @param _uri The URI of the generated art (e.g., IPFS hash).
    /// @param _initialQualityScore An initial quality score provided by the AI agent (0-100).
    /// @param _success True if generation was successful, false otherwise.
    function recordAIGenerationResult(uint256 _promptId, string memory _uri, uint256 _initialQualityScore, bool _success)
        public
        onlyRole(AI_AGENT_ROLE)
        nonReentrant
    {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.id == 0) revert AetherialCanvas__PromptNotFound(_promptId);
        if (prompt.generated) revert AetherialCanvas__PromptAlreadyProcessed(_promptId); // Already recorded

        prompt.generated = true; // Mark as attempted
        if (_success) {
            uint256 tokenId = AetherArt.mint(prompt.creator, _uri, "Initial AI Generation");
            prompt.generatedTokenId = tokenId;

            artMetadata[tokenId] = ArtMetaData({
                qualityScore: _initialQualityScore,
                lastEvaluatedTimestamp: block.timestamp,
                timesEvolved: 0,
                promptId: _promptId,
                listedPrice: 0,
                listedBy: address(0)
            });

            // Reward prompt creator with reputation for successful generation
            _updateUserReputation(prompt.creator, _initialQualityScore / 10);
        }

        emit AIGenerationResult(_promptId, prompt.generatedTokenId, _uri, _initialQualityScore, _success);
    }

    // --- IV. Art Curation & Evolution ---

    /// @notice Curators submit detailed evaluations of generated art pieces.
    /// @param _tokenId The ID of the art piece.
    /// @param _scoreVisuals Score for visual appeal (0-100).
    /// @param _scoreConcept Score for conceptual depth (0-100).
    /// @param _scorePromptAdherence Score for how well it matches the prompt (0-100).
    function submitArtEvaluation(uint256 _tokenId, uint8 _scoreVisuals, uint8 _scoreConcept, uint8 _scorePromptAdherence)
        public
        nonReentrant
    {
        if (!AetherArt.exists(_tokenId)) revert AetherialCanvas__ArtNotFound(_tokenId);
        if (_scoreVisuals > 100 || _scoreConcept > 100 || _scorePromptAdherence > 100) revert AetherialCanvas__InvalidScore();

        // Prevent creator from evaluating their own art
        uint256 promptId = artMetadata[_tokenId].promptId;
        if (prompts[promptId].creator == msg.sender) revert AetherialCanvas__SelfEvaluationForbidden();

        // Check if user has already evaluated this specific art piece.
        // This example does not track per-user evaluations on purpose.
        // In a real system, you would need a mapping like `mapping(uint256 => mapping(address => bool)) hasEvaluated;`

        _evaluationIdCounter.increment();
        uint256 newEvaluationId = _evaluationIdCounter.current();

        evaluations[newEvaluationId] = ArtEvaluation({
            id: newEvaluationId,
            tokenId: _tokenId,
            curator: msg.sender,
            scoreVisuals: _scoreVisuals,
            scoreConcept: _scoreConcept,
            scorePromptAdherence: _scorePromptAdherence,
            timestamp: block.timestamp,
            claimed: false
        });

        // Update the art's quality score (simple average for now, could be weighted based on curator reputation)
        ArtMetaData storage artMeta = artMetadata[_tokenId];
        uint256 newAggregateScore = (_scoreVisuals + _scoreConcept + _scorePromptAdherence) / 3;
        // Simple moving average: (old_score + new_score) / 2
        artMeta.qualityScore = (artMeta.qualityScore + newAggregateScore) / 2;
        artMeta.lastEvaluatedTimestamp = block.timestamp;

        _updateUserReputation(msg.sender, newAggregateScore / 10); // Reward curator reputation

        emit ArtEvaluationSubmitted(newEvaluationId, _tokenId, msg.sender, _scoreVisuals, _scoreConcept, _scorePromptAdherence);
        emit ArtMetadataUpdated(_tokenId, artMeta.qualityScore);
    }

    /// @notice DAO members can propose an "evolution" for an existing art piece.
    /// This might trigger further AI processing or metadata updates based on new prompts.
    /// @param _tokenId The ID of the art piece to propose evolution for.
    /// @param _evolutionPrompt An additional text prompt for the evolution.
    function proposeArtEvolution(uint256 _tokenId, string memory _evolutionPrompt) public {
        if (!AetherArt.exists(_tokenId)) revert AetherialCanvas__ArtNotFound(_tokenId);
        if (userReputation[msg.sender] == 0) revert AetherialCanvas__NotEnoughVotingPower(); // Must have reputation to propose

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            description: string.concat("Evolve art #", Strings.toString(_tokenId), " with prompt: ", _evolutionPrompt),
            proposer: msg.sender,
            targetContract: address(this), // Self-call reference (execution is via specific logic in triggerArtEvolution)
            calldataPayload: bytes(""), // Not applicable for ArtEvolution type
            proposalType: ProposalType.ArtEvolution,
            associatedTokenId: _tokenId,
            evolutionPrompt: _evolutionPrompt,
            startBlock: block.number,
            endBlock: block.number + 100, // 100 blocks voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        _voteOnProposal(newProposalId, true); // Proposer automatically votes for

        emit ArtEvolutionProposed(newProposalId, _tokenId, _evolutionPrompt, msg.sender);
    }

    /// @notice DAO members vote on proposed art evolutions or other governance proposals.
    /// This function acts as a wrapper for the internal `_voteOnProposal`.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnArtEvolutionProposal(uint256 _proposalId, bool _support) public {
        _voteOnProposal(_proposalId, _support);
    }

    /// @dev Internal helper function to cast a vote on any type of proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'yes', false for 'no'.
    function _voteOnProposal(uint256 _proposalId, bool _support) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert AetherialCanvas__ProposalNotFound(_proposalId);
        if (block.number < proposal.startBlock) revert AetherialCanvas__ProposalNotActive();
        if (block.number > proposal.endBlock) revert AetherialCanvas__ProposalExpired();
        if (proposal.hasVoted[msg.sender]) revert AetherialCanvas__AlreadyVoted();

        uint256 voterReputation = userReputation[msg.sender];
        if (voterReputation == 0) revert AetherialCanvas__NotEnoughVotingPower();

        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
        if (proposal.proposalType == ProposalType.ArtEvolution) {
            emit ArtEvolutionVoted(_proposalId, msg.sender, _support);
        }
    }

    /// @notice Called by an `OPERATOR_ROLE` if an art evolution proposal passes, initiating the next AI phase for the art.
    /// This function does not perform AI processing directly, but signals for it.
    /// @param _proposalId The ID of the evolution proposal.
    function triggerArtEvolution(uint256 _proposalId) public onlyRole(OPERATOR_ROLE) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert AetherialCanvas__ProposalNotFound(_proposalId);
        if (proposal.proposalType != ProposalType.ArtEvolution) revert AetherialCanvas__InvalidProposalType();
        if (block.number <= proposal.endBlock) revert AetherialCanvas__ProposalExpired(); // Must wait for voting to end
        if (proposal.executed) revert AetherialCanvas__ProposalAlreadyExecuted();

        // Check if the proposal passed the threshold
        if (proposal.votesFor <= proposal.votesAgainst || proposal.votesFor < daoVotingThreshold) {
            proposal.passed = false;
            revert AetherialCanvas__ProposalNotPassed();
        }
        proposal.passed = true; // Mark as passed

        uint256 tokenId = proposal.associatedTokenId;
        string memory evolutionPrompt = proposal.evolutionPrompt;

        if (!AetherArt.exists(tokenId)) revert AetherialCanvas__ArtNotFound(tokenId);

        artMetadata[tokenId].timesEvolved++;
        // The actual new URI and quality score will be updated by AI_AGENT_ROLE calling updateArtMetadata
        // This function just signifies the *initiation* of evolution, potentially triggering an off-chain AI service.
        proposal.executed = true; // Mark proposal as executed
        emit ArtEvolutionTriggered(_proposalId, tokenId);
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Called by `AI_AGENT_ROLE` to update an NFT's metadata after evolution or re-evaluation.
    /// This function interacts with the `AetherArtNFT` contract to perform the update.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newUri The new URI for the evolved art (e.g., new IPFS hash).
    /// @param _newQualityScore The updated quality score for the art.
    /// @param _newEvolutionHistory A description of the new evolution step.
    function updateArtMetadata(uint256 _tokenId, string memory _newUri, uint256 _newQualityScore, string memory _newEvolutionHistory)
        public
        onlyRole(AI_AGENT_ROLE)
    {
        if (!AetherArt.exists(_tokenId)) revert AetherialCanvas__ArtNotFound(_tokenId);

        // AetherArt contract is set up to allow this DAO contract (as METADATA_UPDATER_ROLE) to update metadata
        AetherArt.updateTokenURIAndEvolution(_tokenId, _newUri, _newEvolutionHistory);
        artMetadata[_tokenId].qualityScore = _newQualityScore;
        artMetadata[_tokenId].lastEvaluatedTimestamp = block.timestamp;

        emit ArtMetadataUpdated(_tokenId, _newQualityScore);
    }

    // --- V. Reputation & Dynamic Rewards ---

    /// @dev Internal function to update a user's reputation score.
    /// Reputation is accumulated based on positive contributions (successful prompts, good evaluations).
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _points The number of reputation points to add.
    function _updateUserReputation(address _user, uint256 _points) internal {
        userReputation[_user] += _points;
        emit UserReputationUpdated(_user, userReputation[_user]);
    }

    /// @notice Retrieves the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Allows the original prompt creator to claim rewards based on the generated art's quality.
    /// Rewards include their initial stake back plus a bonus. Royalties are streamed upon sales.
    /// @param _promptId The ID of the prompt.
    function claimPromptCreatorRewards(uint256 _promptId) public nonReentrant {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.id == 0 || prompt.creator != msg.sender) revert AetherialCanvas__PromptNotFound(_promptId);
        if (!prompt.generated || prompt.generatedTokenId == 0) revert AetherialCanvas__PromptNotApproved(_promptId); // Not generated yet
        if (prompt.stakeAmount == 0) revert AetherialCanvas__AlreadyClaimed(); // Simple check, implies stake is zeroed out after claim

        uint256 rewardAmount = prompt.stakeAmount; // Return initial stake
        // Add a bonus based on art quality score, e.g., 0.1% of stake per quality point (max 10% for 100 quality)
        rewardAmount += (prompt.stakeAmount * artMetadata[prompt.generatedTokenId].qualityScore) / 1000;

        prompt.stakeAmount = 0; // Mark stake as claimed to prevent re-claiming

        stakedBalances[msg.sender] += rewardAmount;
        emit PromptCreatorRewardsClaimed(_promptId, msg.sender, rewardAmount);
    }

    /// @notice Allows curators to claim rewards for impactful and accurate art evaluations.
    /// Rewards are based on the average score given and curator's reputation.
    /// @param _evaluationId The ID of the evaluation.
    function claimCuratorRewards(uint256 _evaluationId) public nonReentrant {
        ArtEvaluation storage evaluation = evaluations[_evaluationId];
        if (evaluation.id == 0 || evaluation.curator != msg.sender) revert AetherialCanvas__EvaluationNotFound(_evaluationId);
        if (evaluation.claimed) revert AetherialCanvas__AlreadyClaimed();

        // Calculate reward based on average score and curator's reputation
        uint256 averageScore = (evaluation.scoreVisuals + evaluation.scoreConcept + evaluation.scorePromptAdherence) / 3;
        // Example: reward is (averageScore * curatorReputation) / a scaling factor (e.g., 500)
        // Adjust scaling factor to balance rewards. Max 100 avg score * 1000 rep = 100,000 / 500 = 200 AETHC
        uint256 rewardAmount = (averageScore * userReputation[msg.sender]) / 500;

        evaluation.claimed = true; // Mark as claimed

        stakedBalances[msg.sender] += rewardAmount;
        emit CuratorRewardsClaimed(_evaluationId, msg.sender, rewardAmount);
    }

    /// @notice Calculates the dynamic royalty percentage for an art piece.
    /// Royalty is based on the creator's reputation and the art's aggregated quality score.
    /// A higher reputation and higher quality art yield higher royalties.
    /// @param _tokenId The ID of the art piece.
    /// @return The royalty percentage in basis points (e.g., 500 = 5%).
    function getDynamicRoyalty(uint256 _tokenId) public view returns (uint256) {
        if (!AetherArt.exists(_tokenId)) {
            revert AetherialCanvas__ArtNotFound(_tokenId);
        }
        uint256 promptId = artMetadata[_tokenId].promptId;
        address creator = prompts[promptId].creator;
        uint256 creatorReputation = userReputation[creator];
        uint256 artQualityScore = artMetadata[_tokenId].qualityScore;

        // Dynamic royalty calculation example:
        // Base royalty: 2% (200 basis points)
        // Plus a component based on creator's reputation (e.g., reputation / 200 => max 50% for 10,000 rep)
        // Plus a component based on art quality (e.g., quality / 2 => max 50% for 100 quality)
        uint256 royalty = 200; // 2% base royalty
        royalty += (creatorReputation / 200); // Max 50% for very high reputation
        royalty += (artQualityScore / 2); // Max 50% for perfect quality (100)

        // Cap royalty at a reasonable maximum, e.g., 20% (2000 basis points)
        if (royalty > 2000) {
            royalty = 2000;
        }
        return royalty;
    }

    // --- VI. DAO Governance ---

    /// @notice Allows eligible users to create a generic governance proposal.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract to call if the proposal passes.
    /// @param _calldata The calldata to send to the target contract.
    function createGovernanceProposal(string memory _description, address _targetContract, bytes memory _calldata) public {
        // Only users with some reputation can propose
        if (userReputation[msg.sender] < 1) revert AetherialCanvas__NotEnoughVotingPower();

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            description: _description,
            proposer: msg.sender,
            targetContract: _targetContract,
            calldataPayload: _calldata,
            proposalType: ProposalType.Generic, // Mark as generic type
            associatedTokenId: 0, // Not applicable
            evolutionPrompt: "", // Not applicable
            startBlock: block.number,
            endBlock: block.number + 100, // Fixed voting period of 100 blocks
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        _voteOnProposal(newProposalId, true); // Proposer automatically votes for

        emit GovernanceProposalCreated(newProposalId, _description, msg.sender, _targetContract, _calldata, ProposalType.Generic);
    }

    /// @notice DAO members cast votes on active generic governance proposals.
    /// This function acts as a wrapper for the internal `_voteOnProposal`.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public {
        _voteOnProposal(_proposalId, _support);
    }

    /// @notice Executes a governance proposal that has met the voting threshold and grace period.
    /// This is typically called by an `OPERATOR_ROLE` after the voting period concludes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) public onlyRole(OPERATOR_ROLE) nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert AetherialCanvas__ProposalNotFound(_proposalId);
        if (proposal.proposalType != ProposalType.Generic) revert AetherialCanvas__InvalidProposalType(); // Only generic proposals are executed this way
        if (block.number <= proposal.endBlock) revert AetherialCanvas__ProposalExpired(); // Voting period must be over
        if (proposal.executed) revert AetherialCanvas__ProposalAlreadyExecuted();

        // Check if the proposal passed the threshold
        if (proposal.votesFor <= proposal.votesAgainst || proposal.votesFor < daoVotingThreshold) {
            proposal.passed = false;
            revert AetherialCanvas__ProposalNotPassed();
        }
        proposal.passed = true; // Mark as passed

        // Execute the call defined by the proposal
        (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
        if (!success) {
            revert AetherialCanvas__TransferFailed(); // Generic error for call failures during execution
        }

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }
}
```