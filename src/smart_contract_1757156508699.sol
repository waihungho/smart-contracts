This smart contract, named **AetherSculpt**, is designed as a decentralized platform for AI-generated and dynamically evolving art NFTs. It introduces a unique combination of on-chain governance, off-chain AI integration via oracles, and dynamic NFT mechanics to create a rich and interactive ecosystem for digital art.

---

**Outline:**

The AetherSculpt contract is a decentralized platform for AI-generated and dynamically evolving art NFTs. Users submit text prompts, which are then processed by off-chain AI models via a Chainlink oracle. The resulting art is minted as a Dynamic NFT, whose metadata and even visual representation can change over time based on community votes and "evolution prompts." A curation system, powered by a staked ERC20 token (CuratorToken), governs the art generation, evolution, and platform parameters, including adaptive royalty fees.

**Core Concepts:**

1.  **AI Art Generation on Demand:** Users submit prompts, AI generates art off-chain via Chainlink oracle.
2.  **Dynamic NFTs (dNFTs):** Art NFTs whose attributes, metadata, and even visuals can evolve post-mint.
3.  **Evolutionary Art:** Existing NFTs can be "remixed" or updated with new AI generations based on community proposals.
4.  **Decentralized Curation:** Stake-based governance for approving prompts, rating art, and voting on evolutions and protocol parameters.
5.  **Adaptive Royalties:** Royalty fees for secondary sales can change based on an NFT's popularity or evolution status.
6.  **AI Model Governance:** Curators can vote on which off-chain AI model the oracle should prioritize.

---

**Function Summary (24 Functions):**

**I. Core Art Generation & NFT Management:**
1.  `submitArtPrompt(string memory _promptText)`: Allows users to submit a text prompt for AI art generation.
2.  `triggerAIGeneration(uint256 _promptId, string memory _aiModel, uint256 _linkFee)`: Initiates an off-chain AI generation request via Chainlink for an approved prompt, requiring LINK.
3.  `fulfillAIGeneration(uint256 _promptId, string memory _ipfsHash, string memory _aiModelUsed)`: Oracle callback to update with generated art details and mint the dNFT. Callable only by the designated oracle address.
4.  `tokenURI(uint256 tokenId)`: Overrides ERC721's `tokenURI` to return a dynamic metadata URI for an NFT, reflecting its current state.
5.  `updateNFTDynamicAttribute(uint256 _tokenId, string memory _attributeKey, string memory _newValue)`: Allows governance to update a specific non-visual dynamic attribute of an NFT (e.g., 'rarity', 'mood').
6.  `getNFTCustomAttribute(uint256 _tokenId, string memory _attributeKey)`: Helper function to retrieve a specific custom dynamic attribute of an NFT.

**II. Dynamic NFT Evolution & Remixing:**
7.  `submitEvolutionPrompt(uint256 _baseTokenId, string memory _evolutionPromptText)`: Proposes an evolution (remix) for an existing NFT, typically by its owner.
8.  `voteForEvolution(uint256 _evolutionProposalId, bool _approve)`: Curators vote on proposed NFT evolutions.
9.  `triggerEvolution(uint256 _evolutionProposalId, string memory _aiModel, uint256 _linkFee)`: Initiates an off-chain AI request to generate an evolved version of an NFT, requiring LINK.
10. `fulfillEvolution(uint256 _evolutionProposalId, uint256 _baseTokenId, string memory _newIpfsHash)`: Oracle callback to update an NFT's visual hash after a successful evolution. Callable only by the designated oracle address.
11. `freezeNFTEvolution(uint256 _tokenId)`: Allows the NFT owner to lock an NFT, preventing further evolutions.

**III. Curation & Governance:**
12. `stakeForCuratorRole(uint256 _amount)`: Users stake CuratorTokens to gain curator voting rights.
13. `unstakeFromCuratorRole(uint256 _amount)`: Users unstake CuratorTokens.
14. `castPromptVote(uint256 _promptId, bool _approve)`: Curators vote on the quality/suitability of submitted prompts.
15. `castArtVote(uint256 _tokenId, uint8 _score)`: Curators (or community) rate generated art (e.g., 1-5 score), impacting its dynamic attributes.
16. `proposeAIGovernanceChange(bytes memory _callData, string memory _description)`: Curators can propose changes to contract parameters, including AI model selection or fee adjustments.
17. `voteOnProposal(uint256 _proposalId, bool _approve)`: Curators vote on governance proposals.
18. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on governance proposal that has met the approval threshold.

**IV. Oracle & Configuration (Owner-only):**
19. `setOracleAddress(address _oracle)`: Sets the trusted Chainlink oracle address.
20. `setJobId(bytes32 _jobId)`: Sets the Chainlink Job ID for AI generation requests.
21. `setLinkTokenAddress(address _link)`: Sets the LINK token address for oracle payments.
22. `setCuratorTokenAddress(address _curatorToken)`: Sets the CuratorToken ERC20 contract address.
23. `withdrawLink(address _to, uint256 _amount)`: Owner can withdraw LINK tokens from the contract.
24. `depositLink(uint256 _amount)`: Allows anyone to send LINK tokens to the contract to fund oracle calls.

**V. Financials & Rewards:**
25. `setDynamicRoyaltyRate(uint256 _tokenId, uint96 _newRate)`: Callable via governance proposal execution, this adjusts the royalty rate for specific NFTs based on performance or community sentiment.
26. `claimCuratorRewards()`: Allows curators to claim accumulated rewards (e.g., a share of LINK fees) based on their participation and accurate votes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol"; // For ERC2981
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string

// Interfaces for Chainlink LINK token and our custom Oracle proxy
interface ILinkToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Simplified Oracle Interface for AI integration
// In a real Chainlink setup, this would be a ChainlinkClient wrapper or similar,
// handling request/fulfill pattern and LINK payments.
interface IOracle {
    function requestAIArtGeneration(
        address _callbackContract,
        uint256 _promptId,
        string memory _promptText,
        string memory _aiModel,
        bytes32 _jobId,
        uint256 _linkFee
    ) external returns (bytes32 requestId);

    function requestNFTEvolution(
        address _callbackContract,
        uint256 _evolutionProposalId,
        uint256 _baseTokenId,
        string memory _evolutionPromptText,
        string memory _aiModel,
        bytes32 _jobId,
        uint256 _linkFee
    ) external returns (bytes32 requestId);
}

// Outline:
// The AetherSculpt contract is a decentralized platform for AI-generated and dynamically evolving art NFTs. Users submit text prompts, which are then processed by off-chain AI models via a Chainlink oracle. The resulting art is minted as a Dynamic NFT, whose metadata and even visual representation can change over time based on community votes and "evolution prompts." A curation system, powered by a staked ERC20 token (CuratorToken), governs the art generation, evolution, and platform parameters, including adaptive royalty fees.

// Core Concepts:
// 1.  AI Art Generation on Demand: Users submit prompts, AI generates art off-chain via Chainlink oracle.
// 2.  Dynamic NFTs (dNFTs): Art NFTs whose attributes, metadata, and even visuals can evolve post-mint.
// 3.  Evolutionary Art: Existing NFTs can be "remixed" or updated with new AI generations based on community proposals.
// 4.  Decentralized Curation: Stake-based governance for approving prompts, rating art, and voting on evolutions and protocol parameters.
// 5.  Adaptive Royalties: Royalty fees for secondary sales can change based on an NFT's popularity or evolution status.
// 6.  AI Model Governance: Curators can vote on which off-chain AI model the oracle should prioritize.

// Function Summary (26 Functions):

// I. Core Art Generation & NFT Management:
// 1.  `submitArtPrompt(string memory _promptText)`: Allows users to submit a text prompt for AI art generation.
// 2.  `triggerAIGeneration(uint256 _promptId, string memory _aiModel, uint256 _linkFee)`: Initiates an off-chain AI generation request via Chainlink for an approved prompt, requiring LINK.
// 3.  `fulfillAIGeneration(uint256 _promptId, string memory _ipfsHash, string memory _aiModelUsed)`: Oracle callback to update with generated art details and mint the dNFT. Callable only by the designated oracle address.
// 4.  `tokenURI(uint256 tokenId)`: Overrides ERC721's `tokenURI` to return a dynamic metadata URI for an NFT, reflecting its current state.
// 5.  `updateNFTDynamicAttribute(uint256 _tokenId, string memory _attributeKey, string memory _newValue)`: Allows governance to update a specific non-visual dynamic attribute of an NFT (e.g., 'rarity', 'mood').
// 6.  `getNFTCustomAttribute(uint256 _tokenId, string memory _attributeKey)`: Helper function to retrieve a specific custom dynamic attribute of an NFT.

// II. Dynamic NFT Evolution & Remixing:
// 7.  `submitEvolutionPrompt(uint256 _baseTokenId, string memory _evolutionPromptText)`: Proposes an evolution (remix) for an existing NFT, typically by its owner.
// 8.  `voteForEvolution(uint256 _evolutionProposalId, bool _approve)`: Curators vote on proposed NFT evolutions.
// 9.  `triggerEvolution(uint256 _evolutionProposalId, string memory _aiModel, uint256 _linkFee)`: Initiates an off-chain AI request to generate an evolved version of an NFT, requiring LINK.
// 10. `fulfillEvolution(uint256 _evolutionProposalId, uint256 _baseTokenId, string memory _newIpfsHash)`: Oracle callback to update an NFT's visual hash after a successful evolution. Callable only by the designated oracle address.
// 11. `freezeNFTEvolution(uint256 _tokenId)`: Allows the NFT owner to lock an NFT, preventing further evolutions.

// III. Curation & Governance:
// 12. `stakeForCuratorRole(uint256 _amount)`: Users stake CuratorTokens to gain curator voting rights.
// 13. `unstakeFromCuratorRole(uint256 _amount)`: Users unstake CuratorTokens.
// 14. `castPromptVote(uint256 _promptId, bool _approve)`: Curators vote on the quality/suitability of submitted prompts.
// 15. `castArtVote(uint256 _tokenId, uint8 _score)`: Curators (or community) rate generated art (e.g., 1-5 score), impacting its dynamic attributes.
// 16. `proposeAIGovernanceChange(bytes memory _callData, string memory _description)`: Curators can propose changes to contract parameters, including AI model selection or fee adjustments.
// 17. `voteOnProposal(uint256 _proposalId, bool _approve)`: Curators vote on governance proposals.
// 18. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on governance proposal that has met the approval threshold.

// IV. Oracle & Configuration (Owner-only):
// 19. `setOracleAddress(address _oracle)`: Sets the trusted Chainlink oracle address.
// 20. `setJobId(bytes32 _jobId)`: Sets the Chainlink Job ID for AI generation requests.
// 21. `setLinkTokenAddress(address _link)`: Sets the LINK token address for oracle payments.
// 22. `setCuratorTokenAddress(address _curatorToken)`: Sets the CuratorToken ERC20 contract address.
// 23. `withdrawLink(address _to, uint256 _amount)`: Owner can withdraw LINK tokens from the contract.
24. `depositLink(uint256 _amount)`: Allows anyone to send LINK tokens to the contract to fund oracle calls.

// V. Financials & Rewards:
25. `setDynamicRoyaltyRate(uint256 _tokenId, uint96 _newRate)`: Callable via governance proposal execution, this adjusts the royalty rate for specific NFTs based on performance or community sentiment.
26. `claimCuratorRewards()`: Allows curators to claim accumulated rewards (e.g., a share of LINK fees) based on their participation and accurate votes.

contract AetherSculpt is ERC721URIStorage, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // NFT Counters
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _promptIdCounter;
    Counters.Counter private _evolutionProposalIdCounter;
    Counters.Counter private _governanceProposalIdCounter;

    // Configuration
    address public oracleAddress;
    bytes32 public aiJobId; // Job ID for AI art generation
    address public linkTokenAddress;
    address public curatorTokenAddress;
    uint256 public minCuratorStake = 100 * (10**18); // Example: 100 CuratorTokens (assuming 18 decimals)
    uint256 public constant PROMPT_VOTE_THRESHOLD_PERCENT = 51; // 51% approval needed for a prompt
    uint256 public constant EVOLUTION_VOTE_THRESHOLD_PERCENT = 60; // 60% approval needed for an evolution
    uint256 public constant GOVERNANCE_VOTE_THRESHOLD_PERCENT = 66; // 66% approval needed for governance proposals

    // Base URI for NFT metadata - will be dynamically constructed
    string public baseMetadataURI = "https://aethersculpt.com/api/metadata/"; // Placeholder for a dynamic metadata service

    // --- Structs ---

    struct Prompt {
        uint256 id;
        address creator;
        string promptText;
        string aiModelChosen; // AI model requested by the triggerer
        uint256 createdTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        bool isGenerated;
        uint256 tokenId; // If generated, points to the NFT
        mapping(address => bool) hasVoted; // Curators who voted on this prompt
    }

    struct NFTDynamicAttributes {
        string ipfsHash; // Current IPFS hash of the art image
        uint256 evolutionCount; // How many times this NFT has evolved
        uint256 communityScoreSum; // Sum of all community scores (e.g., 1-5)
        uint256 communityScoreCount; // Number of votes for community score
        bool isFrozen; // If true, NFT cannot evolve further
        mapping(string => string) customAttributes; // For `updateNFTDynamicAttribute` (e.g., 'rarity', 'mood')
    }

    struct EvolutionProposal {
        uint256 id;
        uint256 baseTokenId; // The NFT token ID to be evolved
        address proposer;
        string evolutionPromptText;
        string aiModelChosen; // AI model requested by the triggerer
        uint256 createdTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        mapping(address => bool) hasVoted; // Curators who voted on this proposal
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute (e.g., `updateNFTDynamicAttribute`)
        address target; // Target contract for the call (this contract's address)
        uint256 createdTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        mapping(address => bool) hasVoted; // Curators who voted on this proposal
    }

    // --- Mappings ---

    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => NFTDynamicAttributes) public nftAttributes;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    mapping(address => uint256) public curatorStakes; // CuratorToken stake for each address
    mapping(address => uint256) public curatorRewardBalance; // LINK rewards for curators

    // --- Events ---

    event PromptSubmitted(uint256 indexed promptId, address indexed creator, string promptText);
    event AIGenerationRequested(uint256 indexed promptId, bytes32 indexed requestId, string aiModel);
    event AIGenerationFulfilled(uint256 indexed promptId, uint256 indexed tokenId, string ipfsHash);
    event NFTAttributesUpdated(uint256 indexed tokenId, string attributeKey, string newValue);
    event EvolutionProposalSubmitted(uint252 indexed proposalId, uint256 indexed baseTokenId, string evolutionPromptText);
    event EvolutionRequested(uint256 indexed proposalId, uint256 indexed baseTokenId, bytes32 indexed requestId, string aiModel);
    event EvolutionFulfilled(uint256 indexed proposalId, uint256 indexed baseTokenId, string newIpfsHash);
    event NFTFrozen(uint256 indexed tokenId);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event PromptVoted(uint256 indexed promptId, address indexed voter, bool vote);
    event ArtVoted(uint256 indexed tokenId, address indexed voter, uint8 score);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event RoyaltyRateUpdated(uint256 indexed tokenId, uint96 newRate);
    event CuratorRewardsClaimed(address indexed curator, uint256 amount);
    event LinkWithdrawn(address indexed to, uint256 amount);
    event LinkDeposited(address indexed from, uint256 amount);


    // --- Constructor ---

    constructor(
        address _linkToken,
        address _oracleAddress,
        bytes32 _aiJobId,
        address _curatorToken
    ) ERC721("Aether Sculpt", "ASNFT") Ownable(msg.sender) {
        require(_linkToken != address(0), "Link token address cannot be zero");
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        require(_curatorToken != address(0), "Curator token address cannot be zero");
        linkTokenAddress = _linkToken;
        oracleAddress = _oracleAddress;
        aiJobId = _aiJobId;
        curatorTokenAddress = _curatorToken;
    }

    // --- Modifiers ---

    modifier onlyCurator() {
        require(curatorStakes[msg.sender] >= minCuratorStake, "Not a curator or stake too low");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    // --- IV. Oracle & Configuration (Owner-only) ---

    // 19. setOracleAddress
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
    }

    // 20. setJobId
    function setJobId(bytes32 _jobId) external onlyOwner {
        require(_jobId != bytes32(0), "Job ID cannot be zero");
        aiJobId = _jobId;
    }

    // 21. setLinkTokenAddress
    function setLinkTokenAddress(address _link) external onlyOwner {
        require(_link != address(0), "LINK token address cannot be zero");
        linkTokenAddress = _link;
    }

    // 22. setCuratorTokenAddress
    function setCuratorTokenAddress(address _curatorToken) external onlyOwner {
        require(_curatorToken != address(0), "Curator token address cannot be zero");
        curatorTokenAddress = _curatorToken;
    }

    // 23. withdrawLink
    function withdrawLink(address _to, uint256 _amount) external onlyOwner {
        require(ILinkToken(linkTokenAddress).transfer(_to, _amount), "LINK transfer failed");
        emit LinkWithdrawn(_to, _amount);
    }

    // 24. depositLink
    function depositLink(uint256 _amount) external {
        require(ILinkToken(linkTokenAddress).transferFrom(msg.sender, address(this), _amount), "LINK deposit failed");
        emit LinkDeposited(msg.sender, _amount);
    }

    // Fallback function to receive ETH (not explicitly in summary, but good practice)
    receive() external payable {}

    // --- I. Core Art Generation & NFT Management ---

    // 1. submitArtPrompt
    function submitArtPrompt(string memory _promptText) external {
        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();
        prompts[newPromptId] = Prompt({
            id: newPromptId,
            creator: msg.sender,
            promptText: _promptText,
            aiModelChosen: "", // Will be set by triggerAIGeneration
            createdTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            isGenerated: false,
            tokenId: 0
        });
        // Clear mapping state for new struct entry
        // No explicit need to clear, default values are fine.
        // For 'hasVoted', it's a new mapping instance.
        emit PromptSubmitted(newPromptId, msg.sender, _promptText);
    }

    // 2. triggerAIGeneration (callable by anyone if prompt is approved by curators, or by owner directly)
    // Requires LINK payment for the oracle call.
    function triggerAIGeneration(uint256 _promptId, string memory _aiModel, uint256 _linkFee) external {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(!prompt.isGenerated, "Art already generated for this prompt");

        uint256 totalVotes = prompt.yesVotes + prompt.noVotes;
        bool isApprovedByCurators = (totalVotes > 0 && (prompt.yesVotes * 100) / totalVotes >= PROMPT_VOTE_THRESHOLD_PERCENT);
        require(msg.sender == owner() || isApprovedByCurators, "Not authorized: prompt not approved by curators or not owner");

        require(ILinkToken(linkTokenAddress).balanceOf(address(this)) >= _linkFee, "Insufficient LINK balance in contract for the oracle call");

        prompt.aiModelChosen = _aiModel;

        bytes32 requestId = IOracle(oracleAddress).requestAIArtGeneration(
            address(this),
            _promptId,
            prompt.promptText,
            _aiModel,
            aiJobId,
            _linkFee
        );
        emit AIGenerationRequested(_promptId, requestId, _aiModel);
    }

    // 3. fulfillAIGeneration (Oracle callback)
    function fulfillAIGeneration(uint256 _promptId, string memory _ipfsHash, string memory _aiModelUsed) external onlyOracle {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(!prompt.isGenerated, "Art already generated for this prompt");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Mint the NFT
        _mint(prompt.creator, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(baseMetadataURI, Strings.toString(newTokenId))));

        // Set initial dynamic attributes and IPFS hash
        nftAttributes[newTokenId].ipfsHash = _ipfsHash;
        nftAttributes[newTokenId].evolutionCount = 0;
        nftAttributes[newTokenId].isFrozen = false;
        nftAttributes[newTokenId].customAttributes["aiModelUsed"] = _aiModelUsed;
        nftAttributes[newTokenId].customAttributes["originalPrompt"] = prompt.promptText;
        nftAttributes[newTokenId].communityScoreSum = 0;
        nftAttributes[newTokenId].communityScoreCount = 0;

        // Set default royalty for the newly minted NFT (10% to the creator)
        _setTokenRoyalty(newTokenId, prompt.creator, 1000); // 1000 basis points = 10%

        prompt.isGenerated = true;
        prompt.tokenId = newTokenId;

        emit AIGenerationFulfilled(_promptId, newTokenId, _ipfsHash);
    }

    // Overriding the base tokenURI function to provide dynamic URLs
    // 4. tokenURI (from ERC721URIStorage)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(tokenId)));
    }

    // 5. updateNFTDynamicAttribute (callable by governance only after successful proposal)
    function updateNFTDynamicAttribute(uint256 _tokenId, string memory _attributeKey, string memory _newValue) external {
        // This function is intended to be called by `executeProposal` after a governance vote.
        require(msg.sender == address(this), "This function can only be called via governance proposal execution");
        require(_exists(_tokenId), "NFT does not exist");

        nftAttributes[_tokenId].customAttributes[_attributeKey] = _newValue;
        emit NFTAttributesUpdated(_tokenId, _attributeKey, _newValue);
    }

    // 6. getNFTCustomAttribute (Helper to retrieve custom attributes)
    function getNFTCustomAttribute(uint256 _tokenId, string memory _attributeKey) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftAttributes[_tokenId].customAttributes[_attributeKey];
    }

    // --- II. Dynamic NFT Evolution & Remixing ---

    // 7. submitEvolutionPrompt
    function submitEvolutionPrompt(uint256 _baseTokenId, string memory _evolutionPromptText) external {
        require(_exists(_baseTokenId), "Base NFT does not exist");
        require(ownerOf(_baseTokenId) == msg.sender, "Only NFT owner can propose evolution");
        require(!nftAttributes[_baseTokenId].isFrozen, "NFT evolution is frozen");

        _evolutionProposalIdCounter.increment();
        uint256 newProposalId = _evolutionProposalIdCounter.current();

        evolutionProposals[newProposalId] = EvolutionProposal({
            id: newProposalId,
            baseTokenId: _baseTokenId,
            proposer: msg.sender,
            evolutionPromptText: _evolutionPromptText,
            aiModelChosen: "",
            createdTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false
        });
        emit EvolutionProposalSubmitted(newProposalId, _baseTokenId, _evolutionPromptText);
    }

    // 8. voteForEvolution
    function voteForEvolution(uint256 _evolutionProposalId, bool _approve) external onlyCurator {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.proposer != address(0), "Evolution proposal does not exist");
        require(!proposal.hasVoted[msg.sender], "Curator already voted on this proposal");
        require(!proposal.isExecuted, "Evolution proposal already executed");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;
    }

    // 9. triggerEvolution (callable by anyone if approved, or by owner directly)
    // Requires LINK payment for the oracle call.
    function triggerEvolution(uint256 _evolutionProposalId, string memory _aiModel, uint256 _linkFee) external {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.proposer != address(0), "Evolution proposal does not exist");
        require(!proposal.isExecuted, "Evolution proposal already executed");
        require(!nftAttributes[proposal.baseTokenId].isFrozen, "NFT evolution is frozen");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        bool isApprovedByCurators = (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= EVOLUTION_VOTE_THRESHOLD_PERCENT);
        require(msg.sender == owner() || isApprovedByCurators, "Not authorized: evolution not approved by curators or not owner");

        require(ILinkToken(linkTokenAddress).balanceOf(address(this)) >= _linkFee, "Insufficient LINK balance in contract for the oracle call");

        proposal.aiModelChosen = _aiModel;

        bytes32 requestId = IOracle(oracleAddress).requestNFTEvolution(
            address(this),
            _evolutionProposalId,
            proposal.baseTokenId,
            proposal.evolutionPromptText,
            _aiModel,
            aiJobId,
            _linkFee
        );
        emit EvolutionRequested(_evolutionProposalId, proposal.baseTokenId, requestId, _aiModel);
    }

    // 10. fulfillEvolution (Oracle callback)
    function fulfillEvolution(uint256 _evolutionProposalId, uint256 _baseTokenId, string memory _newIpfsHash) external onlyOracle {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.proposer != address(0), "Evolution proposal does not exist");
        require(proposal.baseTokenId == _baseTokenId, "Token ID mismatch for evolution");
        require(!proposal.isExecuted, "Evolution already fulfilled");
        require(!nftAttributes[_baseTokenId].isFrozen, "NFT evolution is frozen");

        nftAttributes[_baseTokenId].ipfsHash = _newIpfsHash;
        nftAttributes[_baseTokenId].evolutionCount++;
        // Update tokenURI to reflect new IPFS hash. This typically points to an external metadata service
        // that fetches the latest IPFS hash from the contract. No direct _setTokenURI call needed here
        // if the service dynamically constructs the metadata.

        proposal.isExecuted = true;
        emit EvolutionFulfilled(_evolutionProposalId, _baseTokenId, _newIpfsHash);
    }

    // 11. freezeNFTEvolution
    function freezeNFTEvolution(uint256 _tokenId) external {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only NFT owner can freeze evolution");
        require(!nftAttributes[_tokenId].isFrozen, "NFT already frozen");

        nftAttributes[_tokenId].isFrozen = true;
        emit NFTFrozen(_tokenId);
    }

    // --- III. Curation & Governance ---

    // 12. stakeForCuratorRole
    function stakeForCuratorRole(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be greater than zero");
        IERC20(curatorTokenAddress).transferFrom(msg.sender, address(this), _amount);
        curatorStakes[msg.sender] += _amount;
        emit CuratorStaked(msg.sender, _amount);
    }

    // 13. unstakeFromCuratorRole
    function unstakeFromCuratorRole(uint256 _amount) external {
        require(curatorStakes[msg.sender] >= _amount, "Insufficient staked amount");
        // In a more complex system, checks for active votes/proposals might be added here.
        curatorStakes[msg.sender] -= _amount;
        require(IERC20(curatorTokenAddress).transfer(msg.sender, _amount), "CuratorToken transfer failed during unstake");
        emit CuratorUnstaked(msg.sender, _amount);
    }

    // 14. castPromptVote
    function castPromptVote(uint256 _promptId, bool _approve) external onlyCurator {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(!prompt.hasVoted[msg.sender], "Curator already voted on this prompt");
        require(!prompt.isGenerated, "Cannot vote on generated prompts");

        if (_approve) {
            prompt.yesVotes++;
        } else {
            prompt.noVotes++;
        }
        prompt.hasVoted[msg.sender] = true;
        emit PromptVoted(_promptId, msg.sender, _approve);
    }

    // 15. castArtVote
    function castArtVote(uint256 _tokenId, uint8 _score) external onlyCurator {
        require(_exists(_tokenId), "NFT does not exist");
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");

        // Allowing multiple votes from the same curator will average out,
        // but a real system might track votes per curator per token to prevent spam/double voting.
        nftAttributes[_tokenId].communityScoreSum += _score;
        nftAttributes[_tokenId].communityScoreCount++;
        emit ArtVoted(_tokenId, msg.sender, _score);
    }

    // 16. proposeAIGovernanceChange
    function proposeAIGovernanceChange(bytes memory _callData, string memory _description) external onlyCurator {
        _governanceProposalIdCounter.increment();
        uint256 newProposalId = _governanceProposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            target: address(this), // Proposals will target this contract directly
            createdTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false
        });
        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    // 17. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _approve) external onlyCurator {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist");
        require(!proposal.hasVoted[msg.sender], "Curator already voted on this proposal");
        require(!proposal.isExecuted, "Proposal already executed");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    // 18. executeProposal
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist");
        require(!proposal.isExecuted, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast for this proposal");
        require((proposal.yesVotes * 100) / totalVotes >= GOVERNANCE_VOTE_THRESHOLD_PERCENT, "Proposal did not reach approval threshold");

        proposal.isExecuted = true;
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- V. Financials & Rewards ---

    // 25. setDynamicRoyaltyRate (callable via governance proposal)
    function setDynamicRoyaltyRate(uint256 _tokenId, uint96 _newRate) external {
        // This function is intended to be called by `executeProposal` after a governance vote.
        require(msg.sender == address(this), "This function can only be called via governance proposal execution");
        require(_exists(_tokenId), "NFT does not exist");
        require(_newRate <= 10000, "Royalty rate cannot exceed 100% (10000 basis points)"); // 10000 basis points = 100%

        // Sets royalty to the current owner of the NFT. Can be adapted to always pay original creator.
        _setTokenRoyalty(_tokenId, ownerOf(_tokenId), _newRate);
        emit RoyaltyRateUpdated(_tokenId, _newRate);
    }

    // 26. claimCuratorRewards
    // Simplified reward logic: this function assumes `curatorRewardBalance` is populated
    // by other mechanisms (e.g., a portion of LINK fees from oracle calls, or external grants).
    // A more complex system would have explicit logic for reward calculation here.
    function claimCuratorRewards() external {
        uint256 rewards = curatorRewardBalance[msg.sender];
        require(rewards > 0, "No rewards to claim");
        curatorRewardBalance[msg.sender] = 0;
        require(ILinkToken(linkTokenAddress).transfer(msg.sender, rewards), "Failed to transfer LINK rewards");
        emit CuratorRewardsClaimed(msg.sender, rewards);
    }

    // --- ERC721 and ERC2981 Overrides ---

    // ERC2981: Supports Royalty Standard
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```