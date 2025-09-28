This smart contract, named `AetherForge`, creates a decentralized platform for collaborative art and creativity. It leverages several advanced concepts:

1.  **Dynamic NFTs (dNFTs):** NFTs whose metadata (and conceptually, their visual representation) changes and evolves based on user-contributed "layers" and external data.
2.  **AI Integration (via Oracle):** Uses a designated oracle to provide AI-generated quality scores for creative contributions, influencing their acceptance and impact.
3.  **Reputation System:** Users earn reputation for successful contributions, unlocking privileges like submitting new ideas or having more influence in voting.
4.  **Collaborative Creation Workflow:** A structured process from initial "prompts" to "Seed NFTs" and their subsequent "evolution" through community-curated layers.
5.  **On-chain Voting & Governance (Simplified):** Community voting plays a role in accepting prompts and evaluating layer contributions, alongside the AI oracle.

The contract is designed to be interesting, advanced, creative, and avoids duplicating standard open-source contract functionalities by combining these concepts into a unique workflow for evolving digital art.

---

**Contract Name:** `AetherForge`

**Description:** A decentralized platform for collaborative art and creativity, powered by dynamic NFTs and a reputation system. Users propose creative prompts, which can lead to the minting of "Seed NFTs." These NFTs evolve into "Dynamic NFTs" through community-contributed "layers," evaluated by a trusted AI oracle and community votes. User reputation grows with quality contributions, unlocking further privileges and shaping the NFT's evolution.

---

### **Outline & Function Summary:**

**I. Core Infrastructure & Admin**
1.  **`constructor()`**: Initializes the contract, setting the deployer as owner, name, symbol, and initial configurations.
2.  **`updateOracleAddress(address _newOracle)`**: Allows the owner to update the address of the trusted AI oracle.
3.  **`pause()`**: Owner can pause the contract, preventing most state-changing operations.
4.  **`unpause()`**: Owner can unpause the contract.
5.  **`withdrawFunds(address _recipient, uint256 _amount)`**: Allows the owner to withdraw collected contract fees.
6.  **`setContributionFee(uint256 _newFee)`**: Owner sets the fee required to propose a layer contribution.
7.  **`setMinReputationForPrompt(uint256 _minReputation)`**: Owner sets the minimum reputation required to submit a creative prompt.
8.  **`setPromptSubmissionFee(uint256 _fee)`**: Owner sets the fee required to submit a creative prompt.
9.  **`setVotingThresholds(uint256 _promptMinVotes, uint256 _layerMinVotes, uint256 _promptApprovalRatio, uint256 _layerApprovalRatio, uint256 _minAiScoreForLayer)`**: Owner sets parameters for voting on prompts and layers, and a minimum AI score for layers.

**II. Prompt Management**
10. **`submitCreativePrompt(string calldata _promptContent)`**: Users submit a text-based creative idea, paying a fee, provided they meet the minimum reputation.
11. **`voteOnPrompt(uint256 _promptId, bool _approve)`**: Users (with reputation) can vote to approve or reject submitted prompts.
12. **`finalizePromptEvaluation(uint256 _promptId, uint256 _aiScore)`**: The oracle (or owner in a simplified setup) finalizes a prompt's status based on community votes and an AI-generated score, potentially accepting it.
13. **`getPromptDetails(uint256 _promptId)`**: View function to retrieve details of a specific prompt.

**III. SeedNFT Generation**
14. **`mintSeedNFTFromAcceptedPrompt(uint256 _promptId, string calldata _baseImageURI)`**: The creator of an accepted prompt can mint a unique "Seed NFT" representing the initial concept. This consumes the prompt.
15. **`getSeedNFTDetails(uint256 _tokenId)`**: View function to retrieve details of a specific Seed NFT, including its base metadata.

**IV. Dynamic NFT Evolution & Layer Contribution**
16. **`proposeLayerContribution(uint256 _tokenId, string calldata _layerMetadataURI, string calldata _description)`**: Users propose a new "layer" or "trait" for an existing dNFT, paying a fee. This layer's metadata points to an external resource (e.g., IPFS) for the actual layer data.
17. **`submitOracleLayerEvaluation(uint256 _layerId, uint256 _aiQualityScore)`**: The trusted AI oracle provides a quality score for a proposed layer (e.g., 0-100).
18. **`voteOnLayerContribution(uint256 _layerId, bool _approve)`**: Community members vote on the quality and relevance of a proposed layer.
19. **`applyLayerContribution(uint256 _layerId)`**: A layer is officially added to a dNFT if it meets certain criteria (e.g., high AI score, sufficient positive votes), dynamically changing the NFT's characteristics.
20. **`getDynamicNFTMetadata(uint256 _tokenId)`**: Dynamically generates and returns the full JSON metadata for a dNFT, aggregating all its applied layers and their properties.
21. **`getAppliedLayers(uint256 _tokenId)`**: View function to retrieve a list of all layer contributions applied to a specific dNFT.

**V. Reputation System**
22. **`getReputation(address _user)`**: View function to check a user's current reputation score.
23. **`claimReputationBonus()`**: Users can claim a symbolic reward (e.g., reduced fees, bonus tokens - simplified here as an event emission) once they reach certain reputation thresholds.

**VI. NFT Standard Functions (ERC721)**
24. **`tokenURI(uint256 _tokenId)`**: Returns the URI for the token's metadata, overriding the base ERC721 implementation to call `getDynamicNFTMetadata`.
25. **`balanceOf(address owner)`**: Returns the number of tokens in owner's account.
26. **`ownerOf(uint256 tokenId)`**: Returns the owner of the tokenId.
27. **`safeTransferFrom(address from, address to, uint256 tokenId)`**: Transfers the ownership of a given token ID to another address.
28. **`safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`**: Transfers the ownership of a given token ID to another address, with data.
29. **`transferFrom(address from, address to, uint256 tokenId)`**: Transfers the ownership of a given token ID to another address.
30. **`approve(address to, uint256 tokenId)`**: Approves another address to transfer ownership of the given token ID.
31. **`setApprovalForAll(address operator, bool approved)`**: Enables or disables an operator to manage all of `msg.sender`'s assets.
32. **`getApproved(uint256 tokenId)`**: Returns the address approved to transfer the given token ID.
33. **`isApprovedForAll(address owner, address operator)`**: Returns if the operator is approved to manage all of the assets of owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// Outline & Function Summary:
// Contract Name: AetherForge
// Description: A decentralized platform for collaborative art and creativity, powered by dynamic NFTs and a reputation system.
//              Users propose creative prompts, which can lead to the minting of "Seed NFTs." These NFTs evolve into "Dynamic NFTs"
//              through community-contributed "layers," evaluated by a trusted AI oracle and community votes. User reputation
//              grows with quality contributions, unlocking further privileges and shaping the NFT's evolution.

// I. Core Infrastructure & Admin
// 1.  constructor(): Initializes the contract, setting the deployer as owner, name, symbol, and initial configurations.
// 2.  updateOracleAddress(address _newOracle): Allows the owner to update the address of the trusted AI oracle.
// 3.  pause(): Owner can pause the contract, preventing most state-changing operations.
// 4.  unpause(): Owner can unpause the contract.
// 5.  withdrawFunds(address _recipient, uint256 _amount): Allows the owner to withdraw collected contract fees.
// 6.  setContributionFee(uint256 _newFee): Owner sets the fee required to propose a layer contribution.
// 7.  setMinReputationForPrompt(uint256 _minReputation): Owner sets the minimum reputation required to submit a creative prompt.
// 8.  setPromptSubmissionFee(uint256 _fee): Owner sets the fee required to submit a creative prompt.
// 9.  setVotingThresholds(uint256 _promptMinVotes, uint256 _layerMinVotes, uint256 _promptApprovalRatio, uint256 _layerApprovalRatio, uint256 _minAiScoreForLayer): Owner sets parameters for voting on prompts and layers, and a minimum AI score for layers.

// II. Prompt Management
// 10. submitCreativePrompt(string calldata _promptContent): Users submit a text-based creative idea, paying a fee, provided they meet the minimum reputation.
// 11. voteOnPrompt(uint256 _promptId, bool _approve): Users (with reputation) can vote to approve or reject submitted prompts.
// 12. finalizePromptEvaluation(uint256 _promptId, uint256 _aiScore): The oracle (or owner in a simplified setup) finalizes a prompt's status based on community votes and an AI-generated score, potentially accepting it.
// 13. getPromptDetails(uint256 _promptId): View function to retrieve details of a specific prompt.

// III. SeedNFT Generation
// 14. mintSeedNFTFromAcceptedPrompt(uint256 _promptId, string calldata _baseImageURI): The creator of an accepted prompt can mint a unique "Seed NFT" representing the initial concept. This consumes the prompt.
// 15. getSeedNFTDetails(uint256 _tokenId): View function to retrieve details of a specific Seed NFT, including its base metadata.

// IV. Dynamic NFT Evolution & Layer Contribution
// 16. proposeLayerContribution(uint256 _tokenId, string calldata _layerMetadataURI, string calldata _description): Users propose a new "layer" or "trait" for an existing dNFT, paying a fee. This layer's metadata points to an external resource (e.g., IPFS) for the actual layer data.
// 17. submitOracleLayerEvaluation(uint256 _layerId, uint256 _aiQualityScore): The trusted AI oracle provides a quality score for a proposed layer (e.g., 0-100).
// 18. voteOnLayerContribution(uint256 _layerId, bool _approve): Community members vote on the quality and relevance of a proposed layer.
// 19. applyLayerContribution(uint256 _layerId): A layer is officially added to a dNFT if it meets certain criteria (e.g., high AI score, sufficient positive votes), dynamically changing the NFT's characteristics.
// 20. getDynamicNFTMetadata(uint256 _tokenId): Dynamically generates and returns the full JSON metadata for a dNFT, aggregating all its applied layers and their properties.
// 21. getAppliedLayers(uint256 _tokenId): View function to retrieve a list of all layer contributions applied to a specific dNFT.

// V. Reputation System
// 22. getReputation(address _user): View function to check a user's current reputation score.
// 23. claimReputationBonus(): Users can claim a symbolic reward (e.g., reduced fees, bonus tokens - simplified here as an event emission) once they reach certain reputation thresholds.

// VI. NFT Standard Functions (ERC721)
// 24. tokenURI(uint256 _tokenId): Returns the URI for the token's metadata, overriding the base ERC721 implementation to call getDynamicNFTMetadata.
// 25. balanceOf(address owner): Returns the number of tokens in owner's account.
// 26. ownerOf(uint256 tokenId): Returns the owner of the tokenId.
// 27. safeTransferFrom(address from, address to, uint256 tokenId): Transfers the ownership of a given token ID to another address.
// 28. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Transfers the ownership of a given token ID to another address, with data.
// 29. transferFrom(address from, address to, uint256 tokenId): Transfers the ownership of a given token ID to another address.
// 30. approve(address to, uint256 tokenId): Approves another address to transfer ownership of the given token ID.
// 31. setApprovalForAll(address operator, bool approved): Enables or disables an operator to manage all of msg.sender's assets.
// 32. getApproved(uint256 tokenId): Returns the address approved to transfer the given token ID.
// 33. isApprovedForAll(address owner, address operator): Returns if the operator is approved to manage all of the assets of owner.


contract AetherForge is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    address public oracleAddress;
    uint256 public nextTokenId;
    uint256 public nextPromptId;
    uint256 public nextLayerId;

    // Configuration
    uint256 public promptSubmissionFee;
    uint256 public contributionFee;
    uint256 public minReputationForPrompt; // Min reputation to submit prompts and vote

    // Voting thresholds
    uint256 public promptMinTotalVotes;
    uint256 public layerMinTotalVotes;
    uint256 public promptApprovalRatio; // Percentage, e.g., 70 for 70%
    uint256 public layerApprovalRatio;  // Percentage, e.g., 60 for 60%
    uint256 public minAiScoreForLayer;  // Minimum AI score a layer needs to be considered

    // Reputation System
    mapping(address => uint256) public userReputation;
    uint256 public constant REPUTATION_PROMPT_ACCEPTED = 50;
    uint256 public constant REPUTATION_LAYER_APPLIED_BASE = 10;
    uint256 public constant REPUTATION_THRESHOLD_BONUS = 500; // Example threshold for a bonus

    // --- Structs ---

    enum PromptStatus { Pending, Accepted, Rejected, Used }

    struct Prompt {
        uint256 id;
        address creator;
        string content;
        PromptStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotes;
        mapping(address => bool) hasVoted;
        uint256 aiScore; // AI score from oracle
        uint256 timestamp;
    }

    struct SeedNFTBase {
        uint256 promptId;
        address creator;
        string baseImageURI; // Initial image URI for the NFT
        string name;
        string description;
    }

    enum LayerStatus { Proposed, EvaluatedByOracle, Voted, Applied, Rejected }

    struct LayerContribution {
        uint256 id;
        uint256 tokenId; // NFT this layer is proposed for
        address contributor;
        string metadataURI; // IPFS hash or URL for layer data (e.g., image, trait JSON)
        string description;
        LayerStatus status;
        uint256 aiQualityScore; // AI score from oracle (0-100)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotes;
        mapping(address => bool) hasVoted;
        uint256 timestamp;
    }

    // --- Mappings ---

    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => SeedNFTBase) public nftBases; // TokenId -> Base metadata
    mapping(uint256 => LayerContribution) public layers; // LayerId -> LayerContribution
    mapping(uint256 => uint256[]) public nftAppliedLayers; // TokenId -> Array of LayerIds applied

    // --- Events ---

    event OracleAddressUpdated(address indexed newOracle);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event PromptSubmitted(uint256 indexed promptId, address indexed creator, string content);
    event PromptVoted(uint256 indexed promptId, address indexed voter, bool approved);
    event PromptFinalized(uint256 indexed promptId, PromptStatus newStatus, uint256 aiScore);
    event SeedNFTMinted(uint256 indexed tokenId, uint256 indexed promptId, address indexed minter);
    event LayerProposed(uint256 indexed layerId, uint256 indexed tokenId, address indexed contributor, string metadataURI);
    event LayerOracleEvaluated(uint256 indexed layerId, uint256 aiQualityScore);
    event LayerVoted(uint256 indexed layerId, address indexed voter, bool approved);
    event LayerApplied(uint256 indexed layerId, uint256 indexed tokenId);
    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event ReputationBonusClaimed(address indexed user, uint256 reputationAmount);
    event ContributionFeeSet(uint256 newFee);
    event MinReputationForPromptSet(uint256 newMinReputation);
    event PromptSubmissionFeeSet(uint256 newFee);
    event VotingThresholdsSet(uint256 promptMinVotes, uint256 layerMinVotes, uint256 promptApprovalRatio, uint256 layerApprovalRatio, uint256 minAiScoreForLayer);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "AetherForge: Only oracle can call this function");
        _;
    }

    modifier onlyReputableUser() {
        require(userReputation[_msgSender()] >= minReputationForPrompt, "AetherForge: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle) ERC721("AetherForge dNFT", "AFDN") Ownable(_msgSender()) Pausable() {
        require(_initialOracle != address(0), "AetherForge: Initial oracle address cannot be zero");
        oracleAddress = _initialOracle;
        nextTokenId = 1;
        nextPromptId = 1;
        nextLayerId = 1;

        promptSubmissionFee = 0.01 ether; // Example fee
        contributionFee = 0.005 ether;    // Example fee
        minReputationForPrompt = 100;     // Example minimum reputation

        promptMinTotalVotes = 5;
        layerMinTotalVotes = 3;
        promptApprovalRatio = 70; // 70% approval
        layerApprovalRatio = 60;  // 60% approval
        minAiScoreForLayer = 60;  // Min AI score of 60 out of 100
    }

    // --- I. Core Infrastructure & Admin ---

    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetherForge: New oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "AetherForge: Recipient cannot be zero address");
        require(address(this).balance >= _amount, "AetherForge: Insufficient balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AetherForge: Failed to withdraw funds");
        emit FundsWithdrawn(_recipient, _amount);
    }

    function setContributionFee(uint256 _newFee) external onlyOwner {
        contributionFee = _newFee;
        emit ContributionFeeSet(_newFee);
    }

    function setMinReputationForPrompt(uint256 _minReputation) external onlyOwner {
        minReputationForPrompt = _minReputation;
        emit MinReputationForPromptSet(_minReputation);
    }

    function setPromptSubmissionFee(uint256 _fee) external onlyOwner {
        promptSubmissionFee = _fee;
        emit PromptSubmissionFeeSet(_fee);
    }

    function setVotingThresholds(
        uint256 _promptMinVotes,
        uint256 _layerMinVotes,
        uint256 _promptApprovalRatio,
        uint256 _layerApprovalRatio,
        uint256 _minAiScoreForLayer
    ) external onlyOwner {
        require(_promptApprovalRatio <= 100 && _layerApprovalRatio <= 100, "AetherForge: Approval ratio must be <= 100");
        require(_minAiScoreForLayer <= 100, "AetherForge: AI score must be <= 100");

        promptMinTotalVotes = _promptMinVotes;
        layerMinTotalVotes = _layerMinVotes;
        promptApprovalRatio = _promptApprovalRatio;
        layerApprovalRatio = _layerApprovalRatio;
        minAiScoreForLayer = _minAiScoreForLayer;

        emit VotingThresholdsSet(_promptMinVotes, _layerMinVotes, _promptApprovalRatio, _layerApprovalRatio, _minAiScoreForLayer);
    }

    // --- II. Prompt Management ---

    function submitCreativePrompt(string calldata _promptContent) external payable whenNotPaused onlyReputableUser {
        require(msg.value >= promptSubmissionFee, "AetherForge: Insufficient prompt submission fee");
        require(bytes(_promptContent).length > 0, "AetherForge: Prompt content cannot be empty");

        uint256 currentPromptId = nextPromptId++;
        Prompt storage newPrompt = prompts[currentPromptId];
        newPrompt.id = currentPromptId;
        newPrompt.creator = _msgSender();
        newPrompt.content = _promptContent;
        newPrompt.status = PromptStatus.Pending;
        newPrompt.timestamp = block.timestamp;

        emit PromptSubmitted(currentPromptId, _msgSender(), _promptContent);
    }

    function voteOnPrompt(uint256 _promptId, bool _approve) external whenNotPaused onlyReputableUser {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id != 0, "AetherForge: Prompt does not exist");
        require(prompt.status == PromptStatus.Pending, "AetherForge: Prompt is not in pending status");
        require(!prompt.hasVoted[_msgSender()], "AetherForge: Already voted on this prompt");

        prompt.hasVoted[_msgSender()] = true;
        prompt.totalVotes++;
        if (_approve) {
            prompt.votesFor++;
        } else {
            prompt.votesAgainst++;
        }

        emit PromptVoted(_promptId, _msgSender(), _approve);
    }

    function finalizePromptEvaluation(uint256 _promptId, uint256 _aiScore) external whenNotPaused onlyOracle {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id != 0, "AetherForge: Prompt does not exist");
        require(prompt.status == PromptStatus.Pending, "AetherForge: Prompt is not in pending status");
        require(_aiScore <= 100, "AetherForge: AI score must be <= 100");
        require(prompt.totalVotes >= promptMinTotalVotes, "AetherForge: Not enough total votes to finalize prompt");

        prompt.aiScore = _aiScore;

        uint256 approvalPercentage = (prompt.votesFor * 100) / prompt.totalVotes;

        if (approvalPercentage >= promptApprovalRatio && _aiScore >= minAiScoreForLayer) { // Simplified AI score usage for prompt
            prompt.status = PromptStatus.Accepted;
            _updateUserReputation(prompt.creator, REPUTATION_PROMPT_ACCEPTED);
        } else {
            prompt.status = PromptStatus.Rejected;
        }

        emit PromptFinalized(_promptId, prompt.status, _aiScore);
    }

    function getPromptDetails(uint256 _promptId)
        external
        view
        returns (uint256 id, address creator, string memory content, PromptStatus status, uint256 votesFor, uint256 votesAgainst, uint256 totalVotes, uint256 aiScore, uint256 timestamp)
    {
        Prompt storage prompt = prompts[_promptId];
        return (prompt.id, prompt.creator, prompt.content, prompt.status, prompt.votesFor, prompt.votesAgainst, prompt.totalVotes, prompt.aiScore, prompt.timestamp);
    }

    // --- III. SeedNFT Generation ---

    function mintSeedNFTFromAcceptedPrompt(uint256 _promptId, string calldata _baseImageURI) external whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id != 0, "AetherForge: Prompt does not exist");
        require(prompt.status == PromptStatus.Accepted, "AetherForge: Prompt is not accepted");
        require(prompt.creator == _msgSender(), "AetherForge: Only prompt creator can mint NFT");
        require(bytes(_baseImageURI).length > 0, "AetherForge: Base image URI cannot be empty");

        prompt.status = PromptStatus.Used; // Mark prompt as used

        uint256 currentTokenId = nextTokenId++;
        _safeMint(_msgSender(), currentTokenId);

        nftBases[currentTokenId] = SeedNFTBase({
            promptId: _promptId,
            creator: _msgSender(),
            baseImageURI: _baseImageURI,
            name: string(abi.encodePacked("AetherForge Seed #", currentTokenId.toString())),
            description: prompt.content
        });

        emit SeedNFTMinted(currentTokenId, _promptId, _msgSender());
    }

    function getSeedNFTDetails(uint256 _tokenId)
        external
        view
        returns (uint256 promptId, address creator, string memory baseImageURI, string memory name, string memory description)
    {
        SeedNFTBase storage nftBase = nftBases[_tokenId];
        require(nftBase.promptId != 0, "AetherForge: NFT does not exist or is not a SeedNFT");
        return (nftBase.promptId, nftBase.creator, nftBase.baseImageURI, nftBase.name, nftBase.description);
    }

    // --- IV. Dynamic NFT Evolution & Layer Contribution ---

    function proposeLayerContribution(uint256 _tokenId, string calldata _layerMetadataURI, string calldata _description) external payable whenNotPaused onlyReputableUser {
        require(ownerOf(_tokenId) != address(0), "AetherForge: Token does not exist");
        require(msg.value >= contributionFee, "AetherForge: Insufficient contribution fee");
        require(bytes(_layerMetadataURI).length > 0, "AetherForge: Layer metadata URI cannot be empty");
        require(bytes(_description).length > 0, "AetherForge: Description cannot be empty");

        uint256 currentLayerId = nextLayerId++;
        LayerContribution storage newLayer = layers[currentLayerId];
        newLayer.id = currentLayerId;
        newLayer.tokenId = _tokenId;
        newLayer.contributor = _msgSender();
        newLayer.metadataURI = _layerMetadataURI;
        newLayer.description = _description;
        newLayer.status = LayerStatus.Proposed;
        newLayer.timestamp = block.timestamp;

        emit LayerProposed(currentLayerId, _tokenId, _msgSender(), _layerMetadataURI);
    }

    function submitOracleLayerEvaluation(uint256 _layerId, uint256 _aiQualityScore) external whenNotPaused onlyOracle {
        LayerContribution storage layer = layers[_layerId];
        require(layer.id != 0, "AetherForge: Layer does not exist");
        require(layer.status == LayerStatus.Proposed, "AetherForge: Layer is not in proposed status");
        require(_aiQualityScore <= 100, "AetherForge: AI quality score must be <= 100");

        layer.aiQualityScore = _aiQualityScore;
        layer.status = LayerStatus.EvaluatedByOracle;
        emit LayerOracleEvaluated(_layerId, _aiQualityScore);
    }

    function voteOnLayerContribution(uint256 _layerId, bool _approve) external whenNotPaused onlyReputableUser {
        LayerContribution storage layer = layers[_layerId];
        require(layer.id != 0, "AetherForge: Layer does not exist");
        require(layer.status == LayerStatus.EvaluatedByOracle || layer.status == LayerStatus.Voted, "AetherForge: Layer is not ready for voting");
        require(!layer.hasVoted[_msgSender()], "AetherForge: Already voted on this layer");

        layer.hasVoted[_msgSender()] = true;
        layer.totalVotes++;
        if (_approve) {
            layer.votesFor++;
        } else {
            layer.votesAgainst++;
        }
        layer.status = LayerStatus.Voted; // Status can transition here as more votes come in
        emit LayerVoted(_layerId, _msgSender(), _approve);
    }

    function applyLayerContribution(uint256 _layerId) external whenNotPaused {
        LayerContribution storage layer = layers[_layerId];
        require(layer.id != 0, "AetherForge: Layer does not exist");
        require(layer.status == LayerStatus.Voted, "AetherForge: Layer has not been voted on");
        require(ownerOf(layer.tokenId) == _msgSender(), "AetherForge: Only NFT owner can apply layers");
        require(layer.totalVotes >= layerMinTotalVotes, "AetherForge: Not enough total votes to apply layer");

        uint256 approvalPercentage = (layer.votesFor * 100) / layer.totalVotes;

        if (approvalPercentage >= layerApprovalRatio && layer.aiQualityScore >= minAiScoreForLayer) {
            layer.status = LayerStatus.Applied;
            nftAppliedLayers[layer.tokenId].push(_layerId);
            _updateUserReputation(layer.contributor, REPUTATION_LAYER_APPLIED_BASE + (layer.aiQualityScore / 10)); // Higher AI score, more reputation
            emit LayerApplied(_layerId, layer.tokenId);
        } else {
            layer.status = LayerStatus.Rejected;
            // Optionally, refund fee or penalize contributor
        }
    }

    function getDynamicNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "AetherForge: ERC721 metadata for nonexistent token");
        SeedNFTBase storage nftBase = nftBases[_tokenId];
        require(nftBase.promptId != 0, "AetherForge: NFT not initialized as SeedNFT");

        // Start JSON construction
        string memory json = string(abi.encodePacked(
            '{"name":"', nftBase.name, '",',
            '"description":"', nftBase.description, '",',
            '"image":"', nftBase.baseImageURI, '",', // Base image, for dNFTs this might be dynamically generated off-chain
            '"attributes":[',
                '{"trait_type":"Prompt ID", "value":"', nftBase.promptId.toString(), '"},',
                '{"trait_type":"Creator", "value":"', Strings.toHexString(uint160(nftBase.creator), 20), '"}',
            '],'
        ));

        // Add applied layers to a 'layers' array in JSON
        if (nftAppliedLayers[_tokenId].length > 0) {
            json = string(abi.encodePacked(json, '"layers": ['));
            for (uint256 i = 0; i < nftAppliedLayers[_tokenId].length; i++) {
                uint256 layerId = nftAppliedLayers[_tokenId][i];
                LayerContribution storage layer = layers[layerId];

                json = string(abi.encodePacked(json,
                    '{"layer_id":"', layer.id.toString(), '",',
                    '"contributor":"', Strings.toHexString(uint160(layer.contributor), 20), '",',
                    '"description":"', layer.description, '",',
                    '"metadata_uri":"', layer.metadataURI, '",',
                    '"ai_score":"', layer.aiQualityScore.toString(), '"}'
                ));
                if (i < nftAppliedLayers[_tokenId].length - 1) {
                    json = string(abi.encodePacked(json, ','));
                }
            }
            json = string(abi.encodePacked(json, ']'));
        }

        json = string(abi.encodePacked(json, '}'));

        // Encode JSON to Base64
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getAppliedLayers(uint256 _tokenId) external view returns (uint256[] memory) {
        require(_exists(_tokenId), "AetherForge: Token does not exist");
        return nftAppliedLayers[_tokenId];
    }


    // --- V. Reputation System ---

    function _updateUserReputation(address _user, uint256 _delta) internal {
        userReputation[_user] += _delta;
        emit UserReputationUpdated(_user, userReputation[_user]);
    }

    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function claimReputationBonus() external whenNotPaused {
        require(userReputation[_msgSender()] >= REPUTATION_THRESHOLD_BONUS, "AetherForge: Insufficient reputation for bonus");
        // In a real scenario, this might mint a governance token, reduce fees, or grant special access.
        // For this example, we'll just emit an event and deduct some reputation (or not, depending on design).
        // userReputation[_msgSender()] -= REPUTATION_THRESHOLD_BONUS; // Optionally deduct reputation after claiming
        emit ReputationBonusClaimed(_msgSender(), REPUTATION_THRESHOLD_BONUS);
    }

    // --- VI. NFT Standard Functions (ERC721) ---

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        return getDynamicNFTMetadata(_tokenId);
    }
}
```