The `SyntheLink Protocol` is designed as a decentralized platform for AI-assisted research and innovation. It combines concepts of dynamic NFTs, a decentralized knowledge marketplace, and a bounty system, aiming to foster collaboration and incentivize the creation and sharing of valuable research and AI-generated outputs.

The contract is structured to avoid direct duplication of existing open-source projects by combining several advanced concepts into a unique use case: a reputation-based AI/research agent system, and a marketplace specifically for licensed research data and AI model outputs.

---

**Outline:**

1.  **Core Concepts:** Defines structs and enums for `ResearchQuest` (a problem/bounty), `ResearchAgentNFT` (a dynamic ERC-721 token representing a researcher or AI agent), and `KnowledgeDataUnit` (an ERC-1155 token representing licensed access to research data or AI model outputs).
2.  **Access Control:** Leverages OpenZeppelin's `Ownable` for protocol-level administration and `Pausable` for emergency halts.
3.  **Research Quest Management:** Functions for proposing, funding, submitting solutions, accepting/rejecting, and resolving research quests.
4.  **Research Agent NFT (RANFT) Management:** ERC-721 based dynamic NFTs for researchers/AI agents. These NFTs track accumulated reputation points and automatically derive tiers based on successful contributions. Their metadata can be dynamically resolved off-chain based on their on-chain state (reputation, solved quests).
5.  **Knowledge Data Unit (KDU) Marketplace:** ERC-1155 tokens representing licensed research data or AI models. Includes functions for minting, purchasing, updating prices, and withdrawing proceeds.
6.  **Peer Review & Reputation System:** A community-driven mechanism for validating submitted solutions and reviewing the quality of Knowledge Data Units, influencing the reputation of associated agents.
7.  **Internal Oracle / AI Result Simulation:** A conceptual hook (simulated) for agents to submit verifiable proofs of off-chain AI computations or research findings, integrated into quest solutions.
8.  **Protocol Configuration & Fees:** Administrative functions for setting protocol parameters, fees, and recipients.

---

**Function Summary:**

**Administration & Core Settings:**
1.  `constructor()`: Initializes the contract with the deployer as owner, and sets initial base URIs for Agent NFTs and KDU NFTs.
2.  `setProtocolFeeRecipient(address _recipient)`: Sets the address to receive protocol fees. Only callable by the owner.
3.  `setProtocolFeeRate(uint256 _rateBPS)`: Sets the protocol fee rate in basis points (e.g., 250 for 2.5%). Only callable by the owner.
4.  `pauseContract()`: Pauses core contract functionalities (e.g., new quests, minting) by the owner. Inherited from `Pausable`.
5.  `unpauseContract()`: Unpauses core contract functionalities by the owner. Inherited from `Pausable`.
6.  `setAgentNFTBaseURI(string memory _newBaseURI)`: Sets the base URI for Research Agent NFTs metadata. This URI is used by off-chain resolvers to fetch dynamic metadata. Callable by the owner.
7.  `setKDUBaseURI(string memory _newBaseURI)`: Sets the base URI for Knowledge Data Unit NFTs metadata. Callable by the owner.
8.  `updateKDUMintPrice(uint256 _newPrice)`: Updates the base minting price for Knowledge Data Units. Callable by the owner.
9.  `updateAgentNFTMintFee(uint256 _newFee)`: Updates the fee required to mint a Research Agent NFT. Callable by the owner.

**Research Quest (RQ) Management:**
10. `proposeResearchQuest(string memory _title, string memory _descriptionURI, uint256 _requiredStake)`: Proposes a new research quest, requiring an initial stake from the proposer. Emits `QuestProposed`.
11. `fundResearchQuest(uint256 _questId)`: Allows anyone to add funds to an existing research quest's bounty. Emits `QuestFunded`.
12. `submitQuestSolution(uint256 _questId, uint256 _agentTokenId, string memory _solutionURI, string memory _aiDecisionProofHash)`: Submits a solution to a quest by a Research Agent NFT holder. Includes a conceptual AI decision proof hash. Emits `SolutionSubmitted`.
13. `acceptQuestSolution(uint256 _questId, uint256 _solutionIndex)`: The quest proposer accepts a submitted solution, distributing bounty and reputation to the agent. Emits `SolutionAccepted`.
14. `rejectQuestSolution(uint256 _questId, uint256 _solutionIndex, string memory _reasonURI)`: The quest proposer rejects a solution. Emits `SolutionRejected`.
15. `cancelResearchQuest(uint256 _questId)`: Allows the proposer to cancel an unfunded or unsolved quest, reclaiming their initial stake. Emits `QuestCancelled`.
16. `getTotalQuestFunds(uint256 _questId)`: View function to get the total funds accumulated for a specific quest.

**Research Agent NFT (RANFT) Management (ERC-721 based, dynamic):**
17. `mintResearchAgentNFT(string memory _agentName)`: Mints a new Research Agent NFT for the caller, requiring a fee. Stores agent name and sets initial tokenURI. Emits `Transfer` (ERC721).
18. `updateAgentProfileURI(uint256 _tokenId, string memory _newCustomMetadataURI)`: Allows the owner of an Agent NFT to set a custom metadata URI for their token, potentially overriding the default generated one. Emits `AgentProfileUpdated`.
19. `getAgentReputation(uint256 _tokenId)`: View function to retrieve the current reputation points of a specific Research Agent NFT.
20. `getAgentTier(uint256 _tokenId)`: View function to determine the current reputation tier of an Agent NFT based on its reputation points.
21. `agentNames(uint256)`: Public mapping getter function to retrieve the name of a Research Agent NFT by its token ID.

**Knowledge Data Unit (KDU) Marketplace (ERC-1155 based):**
22. `mintKnowledgeDataUnit(string memory _dataURI, uint256 _price, uint256 _totalSupply, bool _isAILicensed)`: Mints a new KDU, representing a piece of data or an AI model, setting its initial price and total supply. Specifies if it's specifically licensed for AI training/use. Emits `TransferSingle` (ERC1155).
23. `purchaseKnowledgeDataUnit(uint256 _kduId, uint256 _amount)`: Purchases a specified amount of KDU tokens, granting access to the data. Handles fee distribution. Emits `TransferSingle` (ERC1155).
24. `updateKDUPrice(uint256 _kduId, uint256 _newPrice)`: Allows the creator/owner of a KDU to update its individual unit price. Emits `KDUPriceUpdated`.
25. `withdrawKDUProceeds(uint256 _kduId)`: Allows the creator of a KDU to withdraw their share of proceeds from sales, after protocol fees.

**Peer Review & Reputation System:**
26. `upvoteSolution(uint256 _questId, uint256 _solutionIndex)`: Allows community members to upvote a submitted solution, contributing minor reputation to the submitting agent. Emits `SolutionUpvoted`.
27. `downvoteSolution(uint256 _questId, uint256 _solutionIndex)`: Allows community members to downvote a submitted solution. Emits `SolutionDownvoted`.
28. `reviewKDUQuality(uint256 _kduId, int256 _rating)`: Submits a numeric rating for a KDU's quality, affecting its trust score and potentially influencing its discoverability. Emits `KDUReviewed`.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For custom token URIs per token
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion

// Outline:
// 1. Core Concepts: Defines structs and enums for Research Quests, Agent NFTs, and Knowledge Data Units.
// 2. Access Control: Leverages Ownable for protocol-level administration and Pausable for emergency halts.
// 3. Research Quest Management: Functions for proposing, funding, submitting solutions, accepting/rejecting, and resolving quests.
// 4. Research Agent NFT (RANFT) Management: ERC-721 based dynamic NFTs for researchers/AI agents, tracks reputation points and tiers based on contributions.
// 5. Knowledge Data Unit (KDU) Marketplace: ERC-1155 tokens representing licensed research data or AI model outputs with buy/sell mechanisms.
// 6. Peer Review & Reputation System: Community-driven validation of solutions and KDU quality, impacting agent reputation.
// 7. Internal Oracle / AI Result Simulation: A conceptual mechanism for agents to submit verifiable proofs of off-chain AI computations or research findings.
// 8. Protocol Configuration & Fees: Admin functions for setting protocol parameters, fees, and recipients.

// Function Summary:
// Administration & Core Settings:
// 1.  constructor(): Initializes the contract with deployer as owner, and sets initial base URI for Agent NFTs and KDU NFTs.
// 2.  setProtocolFeeRecipient(address _recipient): Sets the address to receive protocol fees. Only callable by owner.
// 3.  setProtocolFeeRate(uint256 _rateBPS): Sets the protocol fee rate in basis points (e.g., 500 = 5%). Only callable by owner.
// 4.  pauseContract(): Pauses core contract functionalities (e.g., new quests, minting) by the owner. Inherited from Pausable.
// 5.  unpauseContract(): Unpauses core contract functionalities by the owner. Inherited from Pausable.
// 6.  setAgentNFTBaseURI(string memory _newBaseURI): Sets the base URI for Research Agent NFTs metadata. This URI is used by off-chain resolvers to fetch dynamic metadata. Callable by owner.
// 7.  setKDUBaseURI(string memory _newBaseURI): Sets the base URI for Knowledge Data Unit NFTs metadata. Callable by owner.
// 8.  updateKDUMintPrice(uint256 _newPrice): Updates the base minting price for Knowledge Data Units. Callable by owner.
// 9.  updateAgentNFTMintFee(uint256 _newFee): Updates the fee required to mint a Research Agent NFT. Callable by owner.

// Research Quest (RQ) Management:
// 10. proposeResearchQuest(string memory _title, string memory _descriptionURI, uint256 _requiredStake): Proposes a new research quest, requiring an initial stake from the proposer. Emits QuestProposed.
// 11. fundResearchQuest(uint256 _questId): Allows anyone to add funds to an existing research quest's bounty. Emits QuestFunded.
// 12. submitQuestSolution(uint256 _questId, uint256 _agentTokenId, string memory _solutionURI, string memory _aiDecisionProofHash): Submits a solution to a quest by a Research Agent NFT holder. Includes a conceptual AI decision proof hash. Emits SolutionSubmitted.
// 13. acceptQuestSolution(uint256 _questId, uint256 _solutionIndex): The quest proposer accepts a submitted solution, distributing bounty and reputation to the agent. Emits SolutionAccepted.
// 14. rejectQuestSolution(uint256 _questId, uint256 _solutionIndex, string memory _reasonURI): The quest proposer rejects a solution. Emits SolutionRejected.
// 15. cancelResearchQuest(uint256 _questId): Allows the proposer to cancel an unfunded or unsolved quest, reclaiming their initial stake. Emits QuestCancelled.
// 16. getTotalQuestFunds(uint256 _questId): View function to get the total funds accumulated for a specific quest.

// Research Agent NFT (RANFT) Management (ERC-721 based, dynamic):
// 17. mintResearchAgentNFT(string memory _agentName): Mints a new Research Agent NFT for the caller, requiring a fee. Stores agent name and sets initial tokenURI. Emits Transfer (ERC721).
// 18. updateAgentProfileURI(uint256 _tokenId, string memory _newCustomMetadataURI): Allows the owner of an Agent NFT to set a custom metadata URI for their token, potentially overriding the default generated one. Emits AgentProfileUpdated.
// 19. getAgentReputation(uint256 _tokenId): View function to retrieve the current reputation points of a specific Research Agent NFT.
// 20. getAgentTier(uint256 _tokenId): View function to determine the current reputation tier of an Agent NFT based on its reputation points.
// 21. agentNames(uint256): Public mapping getter function to retrieve the name of a Research Agent NFT by its token ID.

// Knowledge Data Unit (KDU) Marketplace (ERC-1155 based):
// 22. mintKnowledgeDataUnit(string memory _dataURI, uint256 _price, uint256 _totalSupply, bool _isAILicensed): Mints a new KDU, representing a piece of data or an AI model, setting its initial price and total supply. Specifies if it's specifically licensed for AI training/use. Emits TransferSingle (ERC1155).
// 23. purchaseKnowledgeDataUnit(uint256 _kduId, uint256 _amount): Purchases a specified amount of KDU tokens, granting access to the data. Handles fee distribution. Emits TransferSingle (ERC1155).
// 24. updateKDUPrice(uint256 _kduId, uint256 _newPrice): Allows the creator/owner of a KDU to update its individual unit price. Emits KDUPriceUpdated.
// 25. withdrawKDUProceeds(uint256 _kduId): Allows the creator of a KDU to withdraw their share of proceeds from sales, after protocol fees.

// Peer Review & Reputation System:
// 26. upvoteSolution(uint256 _questId, uint256 _solutionIndex): Allows community members to upvote a submitted solution, contributing minor reputation to the submitting agent. Emits SolutionUpvoted.
// 27. downvoteSolution(uint256 _questId, uint256 _solutionIndex): Allows community members to downvote a submitted solution. Emits SolutionDownvoted.
// 28. reviewKDUQuality(uint256 _kduId, int256 _rating): Submits a numeric rating for a KDU's quality, affecting its trust score and potentially influencing its discoverability. Emits KDUReviewed.


contract SyntheLinkProtocol is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Protocol Fees & Recipients
    address public protocolFeeRecipient;
    uint256 public protocolFeeRateBPS; // Basis points, e.g., 250 for 2.5%

    // --- Research Quest Management ---
    enum QuestStatus { Proposed, Funded, Solved, Cancelled }

    struct QuestSolution {
        uint256 agentTokenId;
        string solutionURI;         // IPFS hash or URL to the solution details
        string aiDecisionProofHash; // Conceptual proof of AI involvement or a verifiable claim hash
        address submitter;
        uint256 submittedAt;
        uint256 upvotes;
        uint256 downvotes;
        bool accepted;
        bool rejected;
    }

    struct ResearchQuest {
        string title;
        string descriptionURI;      // IPFS hash or URL to detailed quest description
        address proposer;
        uint256 requiredStake;
        uint256 currentBounty;
        QuestStatus status;
        uint256 proposedAt;
        QuestSolution[] solutions;
        uint256 acceptedSolutionIndex; // type(uint256).max if no solution accepted
    }

    Counters.Counter private _questIds;
    mapping(uint256 => ResearchQuest) public researchQuests;

    // --- Research Agent NFT (RANFT) Management ---
    ERC721URIStorage public researchAgentNFT; // ERC-721 contract instance
    string private _agentNFTBaseURI; // Base URI for metadata resolver, e.g., "https://api.synthelink.xyz/ranft/"
    uint256 public agentNFTMintFee;

    Counters.Counter private _agentTokenIds; // To track next available agent NFT ID.
    mapping(uint256 => string) public agentNames; // tokenId => agentName

    struct AgentReputation {
        uint256 points; // Accumulated reputation points
        uint256 solutionsAccepted;
        uint256 kduPublished;
    }

    mapping(uint256 => AgentReputation) public agentReputations; // tokenId => AgentReputation

    // Reputation tiers (example, can be more complex and managed by governance)
    uint256[] public reputationTiers = [0, 100, 500, 2000, 10000]; // Points thresholds for tiers 0, 1, 2, 3, 4

    // --- Knowledge Data Unit (KDU) Marketplace ---
    ERC1155 public knowledgeDataUnit; // ERC-1155 contract instance
    string private _kduBaseURI; // Base URI for KDU metadata resolver, e.g., "https://api.synthelink.xyz/kdu/"
    uint256 public kduMintPrice; // Base price to mint a KDU type

    struct KDUDetails {
        address creator;
        string dataURI;             // IPFS hash or URL to the data/model
        uint256 price;              // Price per unit of this KDU type
        uint256 totalProceeds;      // Total ETH accumulated from sales (before creator withdrawal)
        int256 trustScore;          // Average review rating for quality (e.g., from -5 to +5)
        uint256 totalReviews;
        bool isAILicensed;          // True if data is explicitly licensed for AI training/use
    }

    Counters.Counter private _kduIds;
    mapping(uint256 => KDUDetails) public kduDetails;

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeeRateUpdated(uint256 newRateBPS);
    event AgentNFTBaseURIUpdated(string newBaseURI);
    event KDUBaseURIUpdated(string newBaseURI);
    event KDUMintPriceUpdated(uint256 newPrice);
    event AgentNFTMintFeeUpdated(uint256 newFee);

    event QuestProposed(uint256 indexed questId, address indexed proposer, uint256 requiredStake, string descriptionURI);
    event QuestFunded(uint256 indexed questId, address indexed funder, uint256 amount, uint256 totalBounty);
    event SolutionSubmitted(uint256 indexed questId, uint256 indexed solutionIndex, uint256 indexed agentTokenId, string solutionURI);
    event SolutionAccepted(uint256 indexed questId, uint256 indexed solutionIndex, uint256 indexed agentTokenId, uint256 bountyAwarded, uint256 reputationAwarded);
    event SolutionRejected(uint256 indexed questId, uint256 indexed solutionIndex, string reasonURI);
    event QuestCancelled(uint256 indexed questId, address indexed proposer, uint256 returnedStake);

    event AgentProfileUpdated(uint256 indexed tokenId, string newCustomMetadataURI);
    event AgentReputationUpdated(uint256 indexed tokenId, uint256 newReputationPoints);

    event KDUMinted(uint256 indexed kduId, address indexed creator, string dataURI, uint256 price, uint256 totalSupply, bool isAILicensed);
    event KDUPurchased(uint256 indexed kduId, address indexed buyer, uint256 amount, uint256 totalPrice);
    event KDUPriceUpdated(uint256 indexed kduId, uint256 newPrice);
    event KDUProceedsWithdrawn(uint256 indexed kduId, address indexed creator, uint256 amount);
    event KDUReviewed(uint256 indexed kduId, address indexed reviewer, int256 rating);

    event SolutionUpvoted(uint256 indexed questId, uint256 indexed solutionIndex, address indexed voter);
    event SolutionDownvoted(uint256 indexed questId, uint256 indexed solutionIndex, address indexed voter);

    // --- Constructor ---
    constructor(string memory initialAgentNFTBaseURI, string memory initialKDUBaseURI)
        Ownable(msg.sender)
    {
        researchAgentNFT = new ERC721URIStorage("Research Agent NFT", "RANFT");
        knowledgeDataUnit = new ERC1155(initialKDUBaseURI); // ERC1155 constructor takes a URI
        _agentNFTBaseURI = initialAgentNFTBaseURI;
        _kduBaseURI = initialKDUBaseURI;
        protocolFeeRecipient = msg.sender;
        protocolFeeRateBPS = 250; // 2.5% default fee
        agentNFTMintFee = 0.05 ether; // Example fee
        kduMintPrice = 0.01 ether; // Example fee
    }

    // --- Modifiers ---
    modifier onlyQuestProposer(uint256 _questId) {
        require(researchQuests[_questId].proposer == msg.sender, "SyntheLink: Only quest proposer can call this function.");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentTokenId) {
        require(researchAgentNFT.ownerOf(_agentTokenId) == msg.sender, "SyntheLink: Only agent owner can call this function.");
        _;
    }

    modifier onlyKDUCreator(uint256 _kduId) {
        require(kduDetails[_kduId].creator == msg.sender, "SyntheLink: Only KDU creator can call this function.");
        _;
    }

    // --- Administration & Core Settings ---

    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "SyntheLink: Invalid address for fee recipient.");
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientUpdated(_recipient);
    }

    function setProtocolFeeRate(uint256 _rateBPS) external onlyOwner {
        require(_rateBPS <= 10000, "SyntheLink: Fee rate cannot exceed 100%");
        protocolFeeRateBPS = _rateBPS;
        emit ProtocolFeeRateUpdated(_rateBPS);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function setAgentNFTBaseURI(string memory _newBaseURI) external onlyOwner {
        _agentNFTBaseURI = _newBaseURI;
        emit AgentNFTBaseURIUpdated(_newBaseURI);
    }

    function setKDUBaseURI(string memory _newBaseURI) external onlyOwner {
        _kduBaseURI = _newBaseURI;
        // This updates the base URI used by the ERC1155 contract's uri() function.
        knowledgeDataUnit.setURI(_newBaseURI);
        emit KDUBaseURIUpdated(_newBaseURI);
    }

    function updateKDUMintPrice(uint256 _newPrice) external onlyOwner {
        kduMintPrice = _newPrice;
        emit KDUMintPriceUpdated(_newPrice);
    }

    function updateAgentNFTMintFee(uint256 _newFee) external onlyOwner {
        agentNFTMintFee = _newFee;
        emit AgentNFTMintFeeUpdated(_newFee);
    }

    // --- Research Quest (RQ) Management ---

    function proposeResearchQuest(
        string memory _title,
        string memory _descriptionURI,
        uint256 _requiredStake
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= _requiredStake, "SyntheLink: Insufficient stake provided.");
        require(bytes(_title).length > 0, "SyntheLink: Title cannot be empty.");
        require(bytes(_descriptionURI).length > 0, "SyntheLink: Description URI cannot be empty.");

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        researchQuests[newQuestId] = ResearchQuest({
            title: _title,
            descriptionURI: _descriptionURI,
            proposer: msg.sender,
            requiredStake: _requiredStake,
            currentBounty: _requiredStake, // Initial stake contributes to bounty
            status: QuestStatus.Proposed,
            proposedAt: block.timestamp,
            solutions: new QuestSolution[](0),
            acceptedSolutionIndex: type(uint256).max // Indicates no solution accepted
        });

        emit QuestProposed(newQuestId, msg.sender, _requiredStake, _descriptionURI);
        return newQuestId;
    }

    function fundResearchQuest(uint256 _questId) external payable whenNotPaused nonReentrant {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.proposer != address(0), "SyntheLink: Quest does not exist.");
        require(quest.status == QuestStatus.Proposed || quest.status == QuestStatus.Funded, "SyntheLink: Quest is not open for funding.");
        require(msg.value > 0, "SyntheLink: Amount must be greater than zero.");

        quest.currentBounty += msg.value;
        quest.status = QuestStatus.Funded; // Update status if it was just proposed

        emit QuestFunded(_questId, msg.sender, msg.value, quest.currentBounty);
    }

    function submitQuestSolution(
        uint256 _questId,
        uint256 _agentTokenId,
        string memory _solutionURI,
        string memory _aiDecisionProofHash // Placeholder for ZK proof hash or verifiable claim
    ) external whenNotPaused nonReentrant {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.proposer != address(0), "SyntheLink: Quest does not exist.");
        require(quest.status == QuestStatus.Funded || quest.status == QuestStatus.Proposed, "SyntheLink: Quest is not open for solutions.");
        require(researchAgentNFT.ownerOf(_agentTokenId) == msg.sender, "SyntheLink: Caller must own the agent NFT.");
        require(bytes(_solutionURI).length > 0, "SyntheLink: Solution URI cannot be empty.");

        quest.solutions.push(QuestSolution({
            agentTokenId: _agentTokenId,
            solutionURI: _solutionURI,
            aiDecisionProofHash: _aiDecisionProofHash,
            submitter: msg.sender,
            submittedAt: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            accepted: false,
            rejected: false
        }));

        emit SolutionSubmitted(_questId, quest.solutions.length - 1, _agentTokenId, _solutionURI);
    }

    function acceptQuestSolution(uint256 _questId, uint256 _solutionIndex) external onlyQuestProposer(_questId) nonReentrant {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.status == QuestStatus.Funded || quest.status == QuestStatus.Proposed, "SyntheLink: Quest is not in a state to accept solutions.");
        require(_solutionIndex < quest.solutions.length, "SyntheLink: Invalid solution index.");
        require(!quest.solutions[_solutionIndex].accepted, "SyntheLink: Solution already accepted.");
        require(!quest.solutions[_solutionIndex].rejected, "SyntheLink: Solution already rejected.");

        quest.solutions[_solutionIndex].accepted = true;
        quest.acceptedSolutionIndex = _solutionIndex;
        quest.status = QuestStatus.Solved;

        // Calculate fees and distribute bounty
        uint256 totalBounty = quest.currentBounty;
        uint256 protocolFee = (totalBounty * protocolFeeRateBPS) / 10000;
        uint256 netBounty = totalBounty - protocolFee;

        // Send funds to agent's owner
        address agentOwner = researchAgentNFT.ownerOf(quest.solutions[_solutionIndex].agentTokenId);
        (bool successAgent,) = payable(agentOwner).call{value: netBounty}("");
        require(successAgent, "SyntheLink: Failed to transfer bounty to agent owner.");

        // Send protocol fee
        if (protocolFee > 0) {
            (bool successFee,) = payable(protocolFeeRecipient).call{value: protocolFee}("");
            require(successFee, "SyntheLink: Failed to transfer protocol fee.");
        }

        // Update agent reputation
        uint256 reputationAward = 100; // Base reputation for accepting a solution
        _updateAgentReputation(quest.solutions[_solutionIndex].agentTokenId, int256(reputationAward));
        agentReputations[quest.solutions[_solutionIndex].agentTokenId].solutionsAccepted++;

        emit SolutionAccepted(_questId, _solutionIndex, quest.solutions[_solutionIndex].agentTokenId, netBounty, reputationAward);
    }

    function rejectQuestSolution(uint256 _questId, uint256 _solutionIndex, string memory _reasonURI) external onlyQuestProposer(_questId) {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.status == QuestStatus.Funded || quest.status == QuestStatus.Proposed, "SyntheLink: Quest is not in a state to reject solutions.");
        require(_solutionIndex < quest.solutions.length, "SyntheLink: Invalid solution index.");
        require(!quest.solutions[_solutionIndex].accepted, "SyntheLink: Solution already accepted.");
        require(!quest.solutions[_solutionIndex].rejected, "SyntheLink: Solution already rejected.");

        quest.solutions[_solutionIndex].rejected = true;
        // Optionally: Implement reputation penalty for clearly rejected/malicious solutions
        // _updateAgentReputation(quest.solutions[_solutionIndex].agentTokenId, -50); // Example penalty for bad solutions
        emit SolutionRejected(_questId, _solutionIndex, _reasonURI);
    }

    function cancelResearchQuest(uint256 _questId) external onlyQuestProposer(_questId) nonReentrant {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.proposer != address(0), "SyntheLink: Quest does not exist.");
        require(quest.status == QuestStatus.Proposed || quest.status == QuestStatus.Funded, "SyntheLink: Quest must be Proposed or Funded to be cancelled.");
        require(quest.acceptedSolutionIndex == type(uint256).max, "SyntheLink: Cannot cancel a quest with an accepted solution.");

        uint256 returnedStake = quest.currentBounty; // Return all current funds to proposer

        quest.status = QuestStatus.Cancelled;
        quest.currentBounty = 0; // Clear bounty

        (bool success,) = payable(msg.sender).call{value: returnedStake}("");
        require(success, "SyntheLink: Failed to return stake.");

        emit QuestCancelled(_questId, msg.sender, returnedStake);
    }

    function getTotalQuestFunds(uint256 _questId) external view returns (uint256) {
        require(researchQuests[_questId].proposer != address(0), "SyntheLink: Quest does not exist.");
        return researchQuests[_questId].currentBounty;
    }

    // --- Research Agent NFT (RANFT) Management ---

    function mintResearchAgentNFT(string memory _agentName) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= agentNFTMintFee, "SyntheLink: Insufficient mint fee.");
        require(bytes(_agentName).length > 0, "SyntheLink: Agent name cannot be empty.");

        _agentTokenIds.increment();
        uint256 newAgentTokenId = _agentTokenIds.current();

        researchAgentNFT._safeMint(msg.sender, newAgentTokenId);
        // Store agent name on-chain
        agentNames[newAgentTokenId] = _agentName;
        // Set the tokenURI to point to a resolver that can generate dynamic metadata based on `_agentNFTBaseURI`
        researchAgentNFT.setTokenURI(newAgentTokenId, string(abi.encodePacked(_agentNFTBaseURI, newAgentTokenId.toString())));

        agentReputations[newAgentTokenId].points = 0; // Initialize reputation

        // Transfer fee to recipient
        if (agentNFTMintFee > 0) {
            (bool successFee,) = payable(protocolFeeRecipient).call{value: agentNFTMintFee}("");
            require(successFee, "SyntheLink: Failed to transfer mint fee.");
        }
        return newAgentTokenId;
    }

    function updateAgentProfileURI(uint256 _tokenId, string memory _newCustomMetadataURI) external onlyAgentOwner(_tokenId) {
        // This allows the owner to set a completely custom metadata URI for their token,
        // potentially pointing to a unique art piece or a different metadata resolver.
        researchAgentNFT.setTokenURI(_tokenId, _newCustomMetadataURI);
        emit AgentProfileUpdated(_tokenId, _newCustomMetadataURI);
    }

    function getAgentReputation(uint256 _tokenId) external view returns (uint256) {
        require(researchAgentNFT.ownerOf(_tokenId) != address(0), "SyntheLink: Agent NFT does not exist.");
        return agentReputations[_tokenId].points;
    }

    function getAgentTier(uint256 _tokenId) external view returns (uint256) {
        require(researchAgentNFT.ownerOf(_tokenId) != address(0), "SyntheLink: Agent NFT does not exist.");
        uint256 currentReputation = agentReputations[_tokenId].points;
        // Iterate from highest tier threshold downwards
        for (uint256 i = reputationTiers.length - 1; i > 0; i--) { // Start from second last to avoid underflow if reputationTiers[0] is 0
            if (currentReputation >= reputationTiers[i]) {
                return i; // Return the tier index
            }
        }
        return 0; // Default tier (0)
    }

    function _updateAgentReputation(uint256 _tokenId, int256 _reputationChange) internal {
        // Ensure the token exists before updating
        require(researchAgentNFT.ownerOf(_tokenId) != address(0), "SyntheLink: Agent NFT does not exist for reputation update.");

        if (_reputationChange > 0) {
            agentReputations[_tokenId].points += uint256(_reputationChange);
        } else if (_reputationChange < 0) {
            uint256 absChange = uint256(-_reputationChange);
            agentReputations[_tokenId].points = agentReputations[_tokenId].points > absChange ? agentReputations[_tokenId].points - absChange : 0;
        }
        emit AgentReputationUpdated(_tokenId, agentReputations[_tokenId].points);
    }

    // --- Knowledge Data Unit (KDU) Marketplace ---

    function mintKnowledgeDataUnit(
        string memory _dataURI,
        uint256 _price,
        uint256 _totalSupply,
        bool _isAILicensed
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= kduMintPrice, "SyntheLink: Insufficient mint fee.");
        require(_price > 0, "SyntheLink: KDU price must be greater than zero.");
        require(_totalSupply > 0, "SyntheLink: KDU total supply must be greater than zero.");
        require(bytes(_dataURI).length > 0, "SyntheLink: Data URI cannot be empty.");

        _kduIds.increment();
        uint256 newKduId = _kduIds.current();

        kduDetails[newKduId] = KDUDetails({
            creator: msg.sender,
            dataURI: _dataURI,
            price: _price,
            totalProceeds: 0,
            trustScore: 0, // Initial average rating
            totalReviews: 0,
            isAILicensed: _isAILicensed
        });

        // Mint the ERC1155 tokens to the protocol contract itself, which will manage inventory for sale.
        knowledgeDataUnit._mint(address(this), newKduId, _totalSupply, "");
        
        // Optionally update agent reputation for KDU publication if `msg.sender` owns an agent NFT.
        // This logic is simplified; a more robust system might require passing `_agentTokenId` explicitly.
        // For now, it's a manual process or assumed to be handled off-chain.

        // Transfer mint fee
        if (kduMintPrice > 0) {
            (bool successFee,) = payable(protocolFeeRecipient).call{value: kduMintPrice}("");
            require(successFee, "SyntheLink: Failed to transfer mint fee.");
        }

        emit KDUMinted(newKduId, msg.sender, _dataURI, _price, _totalSupply, _isAILicensed);
        return newKduId;
    }

    function purchaseKnowledgeDataUnit(uint256 _kduId, uint256 _amount) external payable whenNotPaused nonReentrant {
        KDUDetails storage kdu = kduDetails[_kduId];
        require(kdu.creator != address(0), "SyntheLink: KDU does not exist.");
        require(_amount > 0, "SyntheLink: Amount must be greater than zero.");
        // Check if the protocol contract holds enough KDU tokens to sell.
        require(knowledgeDataUnit.balanceOf(address(this), _kduId) >= _amount, "SyntheLink: Insufficient KDU supply in protocol.");

        uint256 totalPrice = kdu.price * _amount;
        require(msg.value >= totalPrice, "SyntheLink: Insufficient ETH provided.");

        uint256 protocolShare = (totalPrice * protocolFeeRateBPS) / 10000;
        uint256 creatorShare = totalPrice - protocolShare;

        // Transfer KDU tokens from protocol inventory to buyer
        knowledgeDataUnit._transfer(address(this), msg.sender, _kduId, _amount, "");

        // Distribute funds
        kdu.totalProceeds += creatorShare; // Store creator's share for later withdrawal
        if (protocolShare > 0) {
            (bool successFee,) = payable(protocolFeeRecipient).call{value: protocolShare}("");
            require(successFee, "SyntheLink: Failed to transfer protocol fee.");
        }

        // Return any excess ETH to buyer
        if (msg.value > totalPrice) {
            (bool successRefund,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(successRefund, "SyntheLink: Failed to refund excess ETH.");
        }

        emit KDUPurchased(_kduId, msg.sender, _amount, totalPrice);
    }

    function updateKDUPrice(uint256 _kduId, uint256 _newPrice) external onlyKDUCreator(_kduId) {
        require(_newPrice > 0, "SyntheLink: New price must be greater than zero.");
        kduDetails[_kduId].price = _newPrice;
        emit KDUPriceUpdated(_kduId, _newPrice);
    }

    function withdrawKDUProceeds(uint256 _kduId) external onlyKDUCreator(_kduId) nonReentrant {
        KDUDetails storage kdu = kduDetails[_kduId];
        uint256 amountToWithdraw = kdu.totalProceeds;
        require(amountToWithdraw > 0, "SyntheLink: No proceeds to withdraw.");

        kdu.totalProceeds = 0; // Reset
        (bool success,) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "SyntheLink: Failed to withdraw proceeds.");

        emit KDUProceedsWithdrawn(_kduId, msg.sender, amountToWithdraw);
    }

    // --- Peer Review & Reputation System ---

    function upvoteSolution(uint256 _questId, uint256 _solutionIndex) external whenNotPaused {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.proposer != address(0), "SyntheLink: Quest does not exist.");
        require(_solutionIndex < quest.solutions.length, "SyntheLink: Invalid solution index.");
        require(msg.sender != quest.solutions[_solutionIndex].submitter, "SyntheLink: Cannot upvote your own solution.");

        quest.solutions[_solutionIndex].upvotes++;
        // Minor reputation boost for the agent for community positive feedback
        _updateAgentReputation(quest.solutions[_solutionIndex].agentTokenId, 1);
        emit SolutionUpvoted(_questId, _solutionIndex, msg.sender);
    }

    function downvoteSolution(uint256 _questId, uint256 _solutionIndex) external whenNotPaused {
        ResearchQuest storage quest = researchQuests[_questId];
        require(quest.proposer != address(0), "SyntheLink: Quest does not exist.");
        require(_solutionIndex < quest.solutions.length, "SyntheLink: Invalid solution index.");
        require(msg.sender != quest.solutions[_solutionIndex].submitter, "SyntheLink: Cannot downvote your own solution.");

        quest.solutions[_solutionIndex].downvotes++;
        // Downvoting might flag for review or small reputation penalty if consistently low quality.
        // For this example, no automatic reputation penalty on downvote directly.
        emit SolutionDownvoted(_questId, _solutionIndex, msg.sender);
    }

    function reviewKDUQuality(uint256 _kduId, int256 _rating) external whenNotPaused {
        KDUDetails storage kdu = kduDetails[_kduId];
        require(kdu.creator != address(0), "SyntheLink: KDU does not exist.");
        require(msg.sender != kdu.creator, "SyntheLink: Cannot review your own KDU.");
        require(_rating >= -5 && _rating <= 5, "SyntheLink: Rating must be between -5 and 5.");

        // Simple average rating calculation
        int256 currentTotalScore = kdu.trustScore * int256(kdu.totalReviews);
        kdu.totalReviews++;
        kdu.trustScore = (currentTotalScore + _rating) / int256(kdu.totalReviews);

        emit KDUReviewed(_kduId, msg.sender, _rating);
    }

    // --- Fallback & Receive Functions ---
    receive() external payable {
        // Allows direct ETH deposits to the contract. These funds are not explicitly assigned to
        // any quest and would require an administrative action to repurpose or refund.
        // For a production system, this would typically be restricted or used for specific purposes.
    }
}
```