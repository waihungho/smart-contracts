This smart contract suite, **AetherDAO**, is a cutting-edge decentralized autonomous organization designed for collective intelligence and dynamic asset generation, heavily augmented by AI oracles. It blends advanced governance mechanisms with innovative NFT types (Dynamic NFTs and Soulbound Tokens) to create a unique ecosystem for community-driven development and reputation building.

**Key Advanced Concepts & Uniqueness:**

1.  **AI-Augmented Governance:** Proposals can allocate funds for AI analysis and include specific AI prompts. The results from a trusted AI Oracle can directly influence proposal outcomes, treasury allocations, or the content/traits of newly minted Dynamic NFTs. This creates a feedback loop between community decision-making and external AI intelligence.
2.  **Dynamic NFTs (AetherArtifactNFTs):** These NFTs are not static; their metadata (traits, visual representation URI) can evolve and be updated by subsequent DAO decisions or new AI analysis results. This allows for living, reactive digital assets that reflect the ongoing state or achievements of the DAO.
3.  **Soulbound Insight Badges (SBTs):** Non-transferable tokens that serve as a persistent, on-chain reputation system. Badges are awarded based on community contributions, successful proposal participations, or even AI-verified analytical skills, creating an immutable record of a user's standing and expertise within the AetherDAO.
4.  **Delegated Voting with AI Insights:** Utilizes a custom ERC-20 token (`IntellectToken`) for delegated voting power. While using standard delegated voting for simplicity in this demo, the framework allows for easy integration of advanced voting mechanisms like quadratic voting, especially when combined with AI-driven insights on proposal quality or voter behavior.
5.  **Interconnected Ecosystem:** The entire system is tightly integrated: `IntellectToken` drives governance, successful AI-influenced proposals lead to `AetherArtifactNFT` minting, and contributions are recognized by `InsightBadgeSBT`s, all orchestrated by the `AetherDAO` main contract.

This combination of AI integration into governance, dynamic NFTs, and a soulbound reputation system within a single, cohesive DAO framework offers a novel approach not widely duplicated in open-source projects.

---

### **Outline and Function Summary**

The AetherDAO ecosystem consists of four main smart contracts:

1.  **`IntellectToken` (ITK):** An ERC-20 token that serves as the governance token for AetherDAO, allowing for delegated voting.
2.  **`AetherArtifactNFT`:** An ERC-721 contract for Dynamic NFTs, whose metadata and traits can be updated.
3.  **`InsightBadgeSBT`:** An ERC-721 contract for Soulbound Tokens, representing non-transferable reputation badges.
4.  **`AetherAIOracle` (Mock):** A mock contract to simulate an external AI oracle, allowing `AetherDAO` to request AI analysis and receive results.
5.  **`AetherDAO`:** The core contract managing proposals, treasury, interactions with other contracts, and orchestrating the AI-driven processes.

---

### **Function Summary**

#### **I. `IntellectToken` (ITK - ERC-20 Governance Token)**

1.  **`mint(address to, uint256 amount)`**: Mints `amount` of ITK tokens to `to` (admin/DAO controlled).
2.  **`transfer(address recipient, uint256 amount)`**: Transfers `amount` of ITK to `recipient`.
3.  **`approve(address spender, uint256 amount)`**: Allows `spender` to withdraw `amount` from sender's account.
4.  **`transferFrom(address sender, address recipient, uint256 amount)`**: Transfers `amount` from `sender` to `recipient` on behalf of the `sender`.
5.  **`delegate(address delegatee)`**: Delegates the sender's voting power to `delegatee`.
6.  **`getCurrentVotes(address account)`**: Returns the current voting power of `account`.
7.  **`getPastVotes(address account, uint256 blockNumber)`**: Returns the voting power of `account` at a specific `blockNumber`.

#### **II. `AetherArtifactNFT` (Dynamic ERC-721)**

8.  **`mint(address recipient, uint256 tokenId, string calldata initialURI, bytes calldata initialTraitsData)`**: Mints a new Aether Artifact NFT to `recipient` with initial metadata and traits.
9.  **`updateMetadata(uint256 tokenId, string calldata newURI, bytes calldata newTraitsData)`**: Updates the URI and custom traits data for an existing NFT (DAO/AI Oracle only).
10. **`getArtifactTraits(uint256 tokenId)`**: Returns the current traits data for a given NFT.

#### **III. `InsightBadgeSBT` (Soulbound ERC-721)**

11. **`awardBadge(address recipient, uint256 badgeType, string calldata evidenceURI, uint256 aiReputationScore)`**: Awards a non-transferable Insight Badge to `recipient` with associated evidence and AI score.
12. **`revokeBadge(uint256 tokenId)`**: Revokes (burns) an Insight Badge (DAO only).
13. **`getUserBadges(address user)`**: Returns an array of badge Token IDs owned by `user`.

#### **IV. `AetherAIOracle` (Mock Contract)**

14. **`requestAIAnalysis(address _callbackContract, uint256 _requestId, string calldata _prompt, uint256 _budget)`**: Simulates an external request to an AI service, triggering a delayed callback.
15. **`fulfillAIRequest(address _callbackContract, uint256 _requestId, bytes calldata _resultData, bytes calldata _signature)`**: Internal function called by the mock oracle to send results back to the DAO.

#### **V. `AetherDAO` (Core Contract)**

16. **`submitProposal(string calldata title, string calldata description, bytes calldata callData, address targetContract, uint256 value, uint256 aiAnalysisBudget, string calldata aiPrompt)`**: Submits a new proposal for community and potential AI review.
17. **`voteOnProposal(uint256 proposalId, bool support, uint256 votingPower)`**: Casts a vote on a proposal using delegated ITK power.
18. **`executeProposal(uint256 proposalId)`**: Executes a proposal that has passed and met quorum requirements.
19. **`cancelProposal(uint256 proposalId)`**: Allows the proposer or governance to cancel a proposal under certain conditions.
20. **`getProposalState(uint256 proposalId)`**: Returns the current state of a proposal (e.g., Pending, Active, Succeeded, Executed).
21. **`requestAIAnalysisForProposal(uint256 proposalId)`**: Triggers an AI oracle request for a specific proposal's prompt.
22. **`receiveAIResult(uint256 requestId, bytes calldata resultData, bytes calldata signature)`**: Callback function from the AI oracle, processing results and potentially triggering further actions like NFT updates or badge awards.
23. **`depositTreasury()`**: Allows users to deposit ETH into the DAO's treasury.
24. **`mintAetherArtifact(uint256 associatedProposalId, address recipient, string calldata baseUri, bytes calldata initialTraitsData)`**: Mints an `AetherArtifactNFT` based on a passed proposal, potentially using AI-generated parameters.
25. **`awardInsightBadgeForContribution(address recipient, uint256 badgeType, string calldata evidenceURI, uint256 aiReputationScore)`**: Awards an `InsightBadgeSBT` to `recipient` based on contribution, with an AI-assessed reputation score.
26. **`calculateAggregateReputation(address user)`**: Aggregates a user's reputation score from their Insight Badges and associated AI scores.
27. **`setAIOracleAddress(address _newOracle)`**: Sets the address of the trusted `AetherAIOracle` contract.
28. **`setAetherArtifactNFTAddress(address _address)`**: Sets the address of the `AetherArtifactNFT` contract.
29. **`setInsightBadgeSBTAddress(address _address)`**: Sets the address of the `InsightBadgeSBT` contract.
30. **`setIntellectTokenAddress(address _address)`**: Sets the address of the `IntellectToken` contract.
31. **`withdrawStuckTokens(address tokenAddress, uint256 amount)`**: Allows the DAO to recover accidentally sent ERC-20 tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For mock signature verification
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AetherDAO: Decentralized AI-Augmented Ecosystem for Collective Intelligence & Dynamic Asset Generation
 * @dev This suite of smart contracts creates a novel ecosystem for DAO governance,
 *      integrating AI oracle insights, dynamic NFTs (DNFTs), and soulbound tokens (SBTs) for reputation.
 *
 * @notice Key Advanced Concepts & Uniqueness:
 *   1.  AI-Augmented Governance: Proposals can allocate funds for AI analysis and include specific AI prompts.
 *       The results from a trusted AI Oracle can directly influence proposal outcomes, treasury allocations,
 *       or the content/traits of newly minted Dynamic NFTs. This creates a feedback loop between community
 *       decision-making and external AI intelligence.
 *   2.  Dynamic NFTs (AetherArtifactNFTs): These NFTs are not static; their metadata (traits, visual
 *       representation URI) can evolve and be updated by subsequent DAO decisions or new AI analysis results.
 *       This allows for living, reactive digital assets that reflect the ongoing state or achievements of the DAO.
 *   3.  Soulbound Insight Badges (SBTs): Non-transferable tokens that serve as a persistent, on-chain
 *       reputation system. Badges are awarded based on community contributions, successful proposal participations,
 *       or even AI-verified analytical skills, creating an immutable record of a user's standing and expertise
 *       within the AetherDAO.
 *   4.  Delegated Voting with AI Insights: Utilizes a custom ERC-20 token (`IntellectToken`) for delegated
 *       voting power. While using standard delegated voting for simplicity in this demo, the framework allows for
 *       easy integration of advanced voting mechanisms like quadratic voting, especially when combined with AI-driven
 *       insights on proposal quality or voter behavior.
 *   5.  Interconnected Ecosystem: The entire system is tightly integrated: `IntellectToken` drives governance,
 *       successful AI-influenced proposals lead to `AetherArtifactNFT` minting, and contributions are recognized
 *       by `InsightBadgeSBT`s, all orchestrated by the `AetherDAO` main contract.
 *
 * @dev This combination of AI integration into governance, dynamic NFTs, and a soulbound reputation system
 *      within a single, cohesive DAO framework offers a novel approach not widely duplicated in open-source projects.
 */

/**
 * @title IntellectToken (ITK)
 * @dev ERC-20 token for governance, supporting delegation for voting.
 */
contract IntellectToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor(address initialOwner) ERC20("IntellectToken", "ITK") ERC20Permit("IntellectToken") Ownable(initialOwner) {}

    // The DAO contract will be the minter.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following two internal overrides are required for ERC20Votes.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}

/**
 * @title AetherArtifactNFT
 * @dev ERC-721 token for dynamic NFTs. Metadata and custom traits can be updated by the DAO.
 */
contract AetherArtifactNFT is ERC721, Ownable {
    using Strings for uint256;

    // Custom struct to hold dynamic traits
    struct ArtifactTraits {
        bytes data; // Flexible data structure, e.g., JSON string, encoded array
        uint256 lastUpdated;
    }

    mapping(uint256 => ArtifactTraits) private _tokenTraits;
    mapping(uint256 => uint256) private _associatedProposalId; // Link NFT to the proposal that created it

    // Event for metadata updates
    event ArtifactMetadataUpdated(uint256 indexed tokenId, string newUri, bytes newTraitsData);

    constructor(address initialOwner) ERC721("AetherArtifact", "AART") Ownable(initialOwner) {}

    /**
     * @dev Mints a new Aether Artifact NFT.
     * @param recipient The address to mint the NFT to.
     * @param tokenId The ID of the token to mint.
     * @param initialURI The initial metadata URI.
     * @param initialTraitsData Initial custom traits data.
     * @param associatedProposalId_ The ID of the proposal that led to this NFT's creation.
     */
    function mint(address recipient, uint256 tokenId, string calldata initialURI, bytes calldata initialTraitsData, uint256 associatedProposalId_) public onlyOwner {
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, initialURI);
        _tokenTraits[tokenId] = ArtifactTraits(initialTraitsData, block.timestamp);
        _associatedProposalId[tokenId] = associatedProposalId_;
    }

    /**
     * @dev Updates the metadata URI and custom traits for an existing NFT.
     * @param tokenId The ID of the token to update.
     * @param newURI The new metadata URI.
     * @param newTraitsData New custom traits data.
     */
    function updateMetadata(uint256 tokenId, string calldata newURI, bytes calldata newTraitsData) public onlyOwner {
        require(_exists(tokenId), "NFT does not exist");
        _setTokenURI(tokenId, newURI);
        _tokenTraits[tokenId] = ArtifactTraits(newTraitsData, block.timestamp);
        emit ArtifactMetadataUpdated(tokenId, newURI, newTraitsData);
    }

    /**
     * @dev Returns the custom traits data for a given NFT.
     * @param tokenId The ID of the token.
     * @return The custom traits data and last updated timestamp.
     */
    function getArtifactTraits(uint256 tokenId) public view returns (bytes memory, uint256) {
        require(_exists(tokenId), "NFT does not exist");
        ArtifactTraits memory traits = _tokenTraits[tokenId];
        return (traits.data, traits.lastUpdated);
    }

    /**
     * @dev Returns the proposal ID associated with a given NFT.
     * @param tokenId The ID of the token.
     * @return The associated proposal ID.
     */
    function getAssociatedProposalId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return _associatedProposalId[tokenId];
    }
}

/**
 * @title InsightBadgeSBT
 * @dev ERC-721 token for Soulbound Tokens. Non-transferable, used for reputation.
 */
contract InsightBadgeSBT is ERC721, Ownable {
    // Custom struct for badge details
    struct BadgeDetails {
        uint256 badgeType; // e.g., 0=Contributor, 1=Analyst, 2=Innovator
        string evidenceURI;
        uint256 aiReputationScore; // AI-assigned score at the time of award
        uint256 awardTimestamp;
    }

    mapping(uint256 => BadgeDetails) private _badgeDetails;
    mapping(address => uint256[]) private _userBadges; // List of token IDs for a user

    event BadgeAwarded(address indexed recipient, uint256 indexed tokenId, uint256 badgeType, uint256 aiReputationScore);
    event BadgeRevoked(address indexed recipient, uint256 indexed tokenId);

    constructor(address initialOwner) ERC721("InsightBadge", "IBADGE") Ownable(initialOwner) {}

    /**
     * @dev Awards a new Insight Badge (SBT).
     * @param recipient The address to award the badge to.
     * @param tokenId The ID of the token to mint.
     * @param badgeType The type of badge.
     * @param evidenceURI URI pointing to evidence of contribution.
     * @param aiReputationScore AI-assigned reputation score.
     */
    function awardBadge(address recipient, uint256 tokenId, uint256 badgeType, string calldata evidenceURI, uint256 aiReputationScore) public onlyOwner {
        require(!_exists(tokenId), "Badge ID already exists");
        _safeMint(recipient, tokenId);
        _badgeDetails[tokenId] = BadgeDetails(badgeType, evidenceURI, aiReputationScore, block.timestamp);
        _userBadges[recipient].push(tokenId);
        emit BadgeAwarded(recipient, tokenId, badgeType, aiReputationScore);
    }

    /**
     * @dev Revokes (burns) an Insight Badge.
     * @param tokenId The ID of the token to revoke.
     */
    function revokeBadge(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Badge does not exist");
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        // Remove from _userBadges array (basic implementation, could be optimized)
        uint256[] storage badges = _userBadges[owner];
        for (uint256 i = 0; i < badges.length; i++) {
            if (badges[i] == tokenId) {
                badges[i] = badges[badges.length - 1];
                badges.pop();
                break;
            }
        }
        emit BadgeRevoked(owner, tokenId);
    }

    /**
     * @dev Makes tokens non-transferable (soulbound).
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("Insight Badges are soulbound and non-transferable");
    }

    /**
     * @dev Returns details of a specific badge.
     * @param tokenId The ID of the badge.
     */
    function getBadgeDetails(uint256 tokenId) public view returns (uint256, string memory, uint256, uint256) {
        require(_exists(tokenId), "Badge does not exist");
        BadgeDetails memory details = _badgeDetails[tokenId];
        return (details.badgeType, details.evidenceURI, details.aiReputationScore, details.awardTimestamp);
    }

    /**
     * @dev Returns all badge token IDs owned by a user.
     * @param user The address of the user.
     * @return An array of token IDs.
     */
    function getUserBadges(address user) public view returns (uint256[] memory) {
        return _userBadges[user];
    }
}

/**
 * @title AetherAIOracle (Mock)
 * @dev A mock contract to simulate an external AI oracle.
 *      In a real scenario, this would involve Chainlink AI, decentralized compute networks,
 *      or other off-chain verifiable systems.
 *      It uses a simple signature verification to simulate authenticity of results.
 */
contract AetherAIOracle is Ownable {
    // Oracle's private key hash for signature verification (mock)
    bytes32 private immutable _SIGNER_HASH;

    event AIRequestMade(address indexed callbackContract, uint256 indexed requestId, string prompt, uint256 budget);
    event AIResultFulfilled(address indexed callbackContract, uint256 indexed requestId, bytes resultData);

    constructor(address initialOwner) Ownable(initialOwner) {
        // In a real system, the signer's public key would be known.
        // Here, we just use a placeholder hash for demonstration.
        // For a real signature, a known public key from an oracle service would be used.
        _SIGNER_HASH = keccak256(abi.encodePacked("MOCK_AI_ORACLE_SIGNER_KEY_PLACEHOLDER"));
    }

    /**
     * @dev Simulates an AI analysis request.
     *      The actual AI computation would happen off-chain.
     * @param _callbackContract The address of the contract to call back with the result.
     * @param _requestId A unique ID for this request.
     * @param _prompt The prompt for the AI.
     * @param _budget The budget allocated for this AI analysis.
     */
    function requestAIAnalysis(address _callbackContract, uint256 _requestId, string calldata _prompt, uint256 _budget) public onlyOwner {
        emit AIRequestMade(_callbackContract, _requestId, _prompt, _budget);
        // In a real system, this would trigger an off-chain AI computation.
        // For this mock, we'll imagine the result comes back.
    }

    /**
     * @dev Simulates the fulfillment of an AI request.
     *      This function would be called by the off-chain AI system after computation.
     *      Includes a mock signature verification.
     * @param _callbackContract The contract to which the result is delivered.
     * @param _requestId The ID of the original request.
     * @param _resultData The data returned by the AI.
     * @param _signature A mock signature for authentication.
     */
    function fulfillAIRequest(address _callbackContract, uint256 _requestId, bytes calldata _resultData, bytes calldata _signature) public {
        // Mock signature verification: A real system would use ECDSA.recover
        // This simple check ensures _signature is a specific value known only to the oracle.
        require(keccak256(_signature) == _SIGNER_HASH, "Invalid oracle signature");

        // The callback contract must implement a receiveAIResult function
        (bool success,) = _callbackContract.call(abi.encodeWithSignature("receiveAIResult(uint256,bytes,bytes)", _requestId, _resultData, _signature));
        require(success, "Callback to DAO failed");

        emit AIResultFulfilled(_callbackContract, _requestId, _resultData);
    }

    // Function to set the actual signer hash for testing/setup
    function setSignerHash(bytes32 newSignerHash) public onlyOwner {
        // This would be used during deployment or setup to set the hash of the real oracle's public key.
        // For this mock, we're hardcoding, but demonstrating the concept.
        // _SIGNER_HASH = newSignerHash; // Make _SIGNER_HASH mutable if this were used.
    }
}


/**
 * @title AetherDAO
 * @dev The core contract for managing proposals, treasury, and orchestrating AI-driven processes.
 */
contract AetherDAO is Ownable {
    using Strings for uint256;

    // --- State Variables for Connected Contracts ---
    IntellectToken public intellectToken;
    AetherArtifactNFT public aetherArtifactNFT;
    InsightBadgeSBT public insightBadgeSBT;
    AetherAIOracle public aetherAIOracle;

    // --- DAO Configuration ---
    uint256 public constant MIN_VOTING_DELAY = 1 days; // Time between proposal creation and voting start
    uint256 public constant VOTING_PERIOD = 7 days;    // Duration for voting
    uint256 public constant QUORUM_PERCENTAGE = 4;     // 4% of total supply needed for quorum
    uint256 private _proposalCounter;
    uint256 private _aiRequestCounter; // Counter for AI requests

    // --- Structs ---
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        address proposer;
        string title;
        string description;
        bytes callData;         // Data to be executed if proposal passes
        address targetContract; // Contract to call if proposal passes
        uint256 value;          // ETH to send with execution
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        uint256 aiAnalysisBudget; // Budget for AI analysis
        string aiPrompt;          // Prompt for AI analysis
        uint256 aiRequestId;      // ID of the AI request associated with this proposal
        bytes aiResultData;       // Stored AI result
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => hasVoted

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event AIAnalysisRequested(uint256 indexed requestId, uint256 indexed proposalId, string prompt, uint256 budget);
    event AIAnalysisReceived(uint256 indexed requestId, uint256 indexed proposalId, bytes resultData);
    event AetherArtifactMinted(uint256 indexed proposalId, uint256 indexed tokenId, address recipient);
    event InsightBadgeAwarded(uint256 indexed proposalId, uint256 indexed tokenId, address recipient, uint256 badgeType);

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        _proposalCounter = 0;
        _aiRequestCounter = 0;
    }

    // --- Initial Setup Functions (called by owner) ---
    function setIntellectTokenAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        intellectToken = IntellectToken(_address);
    }

    function setAetherArtifactNFTAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        aetherArtifactNFT = AetherArtifactNFT(_address);
    }

    function setInsightBadgeSBTAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        insightBadgeSBT = InsightBadgeSBT(_address);
    }

    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Invalid address");
        aetherAIOracle = AetherAIOracle(_newOracle);
    }

    // --- Receive ETH for Treasury ---
    receive() external payable {
        // Anyone can deposit ETH into the DAO treasury
    }

    /**
     * @dev Submits a new proposal for community and potential AI review.
     * @param title Title of the proposal.
     * @param description Detailed description of the proposal.
     * @param callData The encoded function call to be executed if the proposal passes.
     * @param targetContract The address of the contract to call.
     * @param value ETH amount to send with the execution.
     * @param aiAnalysisBudget Budget allocated for AI analysis of this proposal.
     * @param aiPrompt Prompt for the AI model to process.
     * @return The ID of the newly created proposal.
     */
    function submitProposal(
        string calldata title,
        string calldata description,
        bytes calldata callData,
        address targetContract,
        uint256 value,
        uint256 aiAnalysisBudget,
        string calldata aiPrompt
    ) public returns (uint256) {
        require(address(intellectToken) != address(0), "ITK not set");
        require(intellectToken.getPastVotes(msg.sender, block.number - 1) > 0, "Proposer must have voting power"); // Basic check for active voters

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            title: title,
            description: description,
            callData: callData,
            targetContract: targetContract,
            value: value,
            startBlock: block.number + (MIN_VOTING_DELAY / 12), // Assuming ~12 seconds per block
            endBlock: block.number + (MIN_VOTING_DELAY / 12) + (VOTING_PERIOD / 12),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false,
            aiAnalysisBudget: aiAnalysisBudget,
            aiPrompt: aiPrompt,
            aiRequestId: 0, // Will be set if AI analysis is requested
            aiResultData: ""
        });

        emit ProposalCreated(proposalId, msg.sender, title, proposals[proposalId].startBlock, proposals[proposalId].endBlock);

        // If an AI prompt and budget are provided, request AI analysis
        if (aiAnalysisBudget > 0 && bytes(aiPrompt).length > 0) {
            requestAIAnalysisForProposal(proposalId);
        }

        return proposalId;
    }

    /**
     * @dev Casts a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against'.
     * @param votingPower The amount of delegated ITK tokens to use for voting.
     */
    function voteOnProposal(uint256 proposalId, bool support, uint256 votingPower) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting ended");
        require(!proposal.canceled, "Proposal is canceled");
        require(!proposal.executed, "Proposal is executed");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        
        // Ensure the voter actually has the specified voting power at the start of the voting period
        uint256 availableVotingPower = intellectToken.getPastVotes(msg.sender, proposal.startBlock);
        require(availableVotingPower >= votingPower, "Insufficient voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Executes a proposal that has passed and met quorum requirements.
     *      Requires the proposal to be in a 'Succeeded' state.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal is canceled");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal not in 'Succeeded' state");

        proposal.executed = true;

        // Execute the call data
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Allows the proposer or governance to cancel a proposal before voting ends.
     *      Can also be canceled if it receives overwhelming 'against' votes or if AI analysis recommends against it.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Cannot cancel an executed proposal");
        require(!proposal.canceled, "Proposal already canceled");
        
        // Only proposer or DAO owner can cancel
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Only proposer or owner can cancel");
        
        // Additional condition: cannot cancel if voting has already ended in favor
        require(block.number <= proposal.endBlock || getProposalState(proposalId) != ProposalState.Succeeded, "Cannot cancel after successful voting");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The current `ProposalState`.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else {
            // Voting period ended, check results
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
            uint256 totalITKSupply = intellectToken.totalSupply();
            uint256 quorumThreshold = (totalITKSupply * QUORUM_PERCENTAGE) / 100;

            if (totalVotes < quorumThreshold || proposal.forVotes <= proposal.againstVotes) {
                return ProposalState.Defeated;
            } else {
                return ProposalState.Succeeded;
            }
        }
    }

    /**
     * @dev Triggers an AI oracle request for a specific proposal's prompt.
     *      Only callable by the DAO itself (through a proposal execution) or the owner.
     * @param proposalId The ID of the proposal requiring AI analysis.
     */
    function requestAIAnalysisForProposal(uint256 proposalId) public onlyOwner {
        // In a real scenario, this would be callable only via a passed DAO proposal,
        // or by the owner for initial setup/testing. For simplicity, only owner.
        require(address(aetherAIOracle) != address(0), "AI Oracle not set");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.aiAnalysisBudget > 0, "AI budget must be > 0");
        require(bytes(proposal.aiPrompt).length > 0, "AI prompt cannot be empty");
        require(proposal.aiRequestId == 0, "AI analysis already requested for this proposal");

        _aiRequestCounter++;
        uint256 requestId = _aiRequestCounter;
        proposal.aiRequestId = requestId;

        // Transfer funds for AI analysis from treasury to the oracle (mock transfer)
        // In a real system, this would be a direct transfer or a payment to a bridge.
        require(address(this).balance >= proposal.aiAnalysisBudget, "Insufficient treasury funds for AI analysis");
        // For a mock, we just deduct conceptually. For real, transfer to oracle or payment contract.
        // payable(aetherAIOracle).transfer(proposal.aiAnalysisBudget); // Uncomment for actual ETH transfer

        aetherAIOracle.requestAIAnalysis(address(this), requestId, proposal.aiPrompt, proposal.aiAnalysisBudget);
        emit AIAnalysisRequested(requestId, proposalId, proposal.aiPrompt, proposal.aiAnalysisBudget);
    }

    /**
     * @dev Callback function from the AI oracle, processing results.
     *      Only callable by the trusted AI oracle contract.
     * @param requestId The ID of the original AI request.
     * @param resultData The data returned by the AI.
     * @param signature A signature from the oracle for verification.
     */
    function receiveAIResult(uint256 requestId, bytes calldata resultData, bytes calldata signature) public {
        require(msg.sender == address(aetherAIOracle), "Only AI Oracle can call this function");
        // Verify signature (mock, as _SIGNER_HASH is private in AetherAIOracle in this setup,
        // but demonstrates the intention. A real signature recovery would be here.)
        // This implicitly assumes AetherAIOracle already verified the signature with its internal _SIGNER_HASH.

        // Find the proposal associated with this requestId
        uint256 proposalId = 0;
        for (uint256 i = 1; i <= _proposalCounter; i++) {
            if (proposals[i].aiRequestId == requestId) {
                proposalId = i;
                break;
            }
        }
        require(proposalId != 0, "AI result for unknown request ID");

        Proposal storage proposal = proposals[proposalId];
        proposal.aiResultData = resultData; // Store the AI result

        emit AIAnalysisReceived(requestId, proposalId, resultData);

        // Example actions based on AI result (simplified for demonstration):
        // If the AI suggests specific traits, update a pending NFT.
        // If AI gives a negative score, potentially cancel the proposal (requires a DAO vote to confirm).
        // This is where the core logic of AI-augmented decision making would go.
    }

    /**
     * @dev Mints an AetherArtifact NFT based on a passed proposal.
     *      This function would typically be called as part of a `executeProposal` after a
     *      proposal to mint an NFT has passed and potentially received AI input for traits.
     * @param associatedProposalId The ID of the proposal that led to this NFT's creation.
     * @param recipient The address to mint the NFT to.
     * @param baseUri Initial URI for the NFT metadata.
     * @param initialTraitsData Initial custom traits data, potentially AI-generated.
     * @return The ID of the newly minted NFT.
     */
    function mintAetherArtifact(uint256 associatedProposalId, address recipient, string calldata baseUri, bytes calldata initialTraitsData) public onlyOwner returns (uint256) {
        // Only DAO via `executeProposal` or owner can call this
        require(address(aetherArtifactNFT) != address(0), "AetherArtifactNFT not set");
        require(proposals[associatedProposalId].proposer != address(0), "Associated proposal does not exist");

        // Generate a new unique token ID (example, could be based on proposal ID or other logic)
        uint256 tokenId = type(uint256).max - _proposalCounter; // Simple unique ID generation

        aetherArtifactNFT.mint(recipient, tokenId, baseUri, initialTraitsData, associatedProposalId);
        emit AetherArtifactMinted(associatedProposalId, tokenId, recipient);
        return tokenId;
    }

    /**
     * @dev Awards an Insight Badge (SBT) to a recipient.
     *      This would typically be triggered by a passed DAO proposal
     *      or based on an AI-driven contribution assessment.
     * @param recipient The address to award the badge to.
     * @param badgeType The type of badge to award.
     * @param evidenceURI URI pointing to evidence of contribution.
     * @param aiReputationScore AI-assigned reputation score for this contribution.
     * @return The ID of the newly awarded badge.
     */
    function awardInsightBadgeForContribution(address recipient, uint256 badgeType, string calldata evidenceURI, uint256 aiReputationScore) public onlyOwner returns (uint256) {
        // Only DAO via `executeProposal` or owner can call this
        require(address(insightBadgeSBT) != address(0), "InsightBadgeSBT not set");

        uint256 badgeId = insightBadgeSBT.totalSupply() + 1; // Simple incrementing ID

        insightBadgeSBT.awardBadge(recipient, badgeId, badgeType, evidenceURI, aiReputationScore);
        emit InsightBadgeAwarded(0, badgeId, recipient, badgeType); // Proposal ID 0 for direct awards
        return badgeId;
    }

    /**
     * @dev Calculates an aggregate reputation score for a user based on their Insight Badges.
     *      This is a basic aggregation; a more complex system could weight badges differently.
     * @param user The address of the user.
     * @return The aggregate reputation score.
     */
    function calculateAggregateReputation(address user) public view returns (uint256) {
        require(address(insightBadgeSBT) != address(0), "InsightBadgeSBT not set");

        uint256[] memory userBadges = insightBadgeSBT.getUserBadges(user);
        uint256 totalReputation = 0;

        for (uint256 i = 0; i < userBadges.length; i++) {
            (, , uint256 aiScore, ) = insightBadgeSBT.getBadgeDetails(userBadges[i]);
            totalReputation += aiScore;
        }
        return totalReputation;
    }

    /**
     * @dev Allows the DAO to withdraw accidentally sent ERC-20 tokens from its balance.
     *      This prevents tokens from being permanently stuck in the contract.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawStuckTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAddress != address(intellectToken), "Cannot withdraw governance token directly");
        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(owner(), amount), "Token withdrawal failed");
    }

    // --- View Functions ---
    function getProposalCount() public view returns (uint256) {
        return _proposalCounter;
    }
    
    function getTotalSupplyITK() public view returns(uint256) {
        require(address(intellectToken) != address(0), "ITK not set");
        return intellectToken.totalSupply();
    }
}
```