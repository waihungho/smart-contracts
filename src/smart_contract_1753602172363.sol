This smart contract, `EphemeralEchoes`, is designed as a decentralized, evolving, and gamified social/artistic reputation system. It introduces a novel concept of "Echoes" as dynamic NFTs, where their properties evolve based on user interactions and AI-driven content analysis via oracles. Users build "Resonance" (reputation) by contributing and interacting, progressing through tiers. A "Seer Council" (DAO) governs the protocol, curating AI models and managing the system. The "Catalyst" token fuels interactions and rewards.

---

## **Outline: Ephemeral Echoes Protocol**

**I. Introduction:**
   The Ephemeral Echoes Protocol is a pioneering decentralized application that blends dynamic NFTs, on-chain reputation, gamified progression, AI integration, and decentralized governance. It creates a vibrant ecosystem where digital contributions ("Echoes") are not static but evolve, reflecting their community impact and AI-assessed properties.

**II. Core Components:**
   *   **Echoes (ERC-721):** Dynamic Non-Fungible Tokens representing user-submitted content (e.g., short text, creative snippets, data blobs via URI). Their "Luminance" (popularity) and AI-analyzed attributes (sentiment, category) change based on protocol interactions.
   *   **Resonance:** A user's quantifiable on-chain reputation score. It increases through creating valuable Echoes and actively "resonating" with others' contributions, unlocking access to higher progression tiers and privileges.
   *   **Catalyst (ERC-20):** The protocol's native utility token. It's essential for participating in key actions (e.g., submitting Echoes, resonating), and serves as a reward mechanism for user engagement and progression.
   *   **Seer Council (DAO):** The decentralized autonomous organization governing the protocol. Composed of highly-regarded members (based on Resonance and Catalyst holdings), it makes critical decisions regarding protocol fees, AI model updates, and future feature implementations.
   *   **AI Oracle Integration:** Leverages off-chain AI services (e.g., via Chainlink) to perform sentiment analysis and categorization of Echo content, enriching Echo NFTs with dynamic, intelligent properties.

**III. Key Features:**
   *   **Dynamic NFT Evolution:** Echo metadata is not static; it changes in real-time on-chain based on community interaction (Luminance) and AI analysis (Sentiment, Category).
   *   **Gamified Reputation & Progression:** Users earn Resonance for positive engagement, enabling them to unlock distinct progression tiers with associated rewards and enhanced capabilities.
   *   **Decentralized, Community-Driven Governance:** The Seer Council ensures the protocol's long-term sustainability and adaptability, empowering the community to steer its evolution.
   *   **Intelligent Content Curation:** AI-driven analysis provides dynamic insights into Echo content, potentially enabling advanced filtering, discovery, and value assessment.
   *   **Sustainable Tokenomics:** The Catalyst token facilitates a circular economy within the protocol, aligning incentives for participation and growth.

---

## **Function Summary: Ephemeral Echoes Protocol**

**A. Core Protocol & Echo Management (Dynamic NFTs):**
1.  `submitEcho(string _contentURI)`: Mints a new Echo NFT. The `_contentURI` points to off-chain content. Requires a `echoSubmissionFee` in Catalyst tokens.
2.  `resonateWithEcho(uint256 _echoId)`: Allows users to interact with an Echo. Increases the Echo's `luminance` and its creator's `resonance` score. Costs a `resonateFee` in Catalyst.
3.  `requestEchoAIAnalysis(uint256 _echoId)`: Triggers an asynchronous call to the configured AI oracle to analyze the specified Echo's content. Only callable by the Echo's creator or a Seer Council member.
4.  `fulfillEchoAIAnalysis(bytes32 _requestId, uint256 _echoId, uint8 _sentiment, string _category)`: An external callback function invoked by the oracle. Updates the Echo's on-chain AI sentiment and category based on the oracle's report.
5.  `retractEcho(uint256 _echoId)`: Allows the owner of an Echo to burn their NFT. A portion of the initial Catalyst submission fee is refunded.
6.  `getEchoData(uint256 _echoId)`: Retrieves all detailed structural data for a given Echo NFT, including its current luminance, AI analysis results, and creation details.
7.  `getEchoMetadataURI(uint256 _echoId)`: Overrides the standard ERC-721 `tokenURI`. Generates a dynamic metadata URI for an Echo, which would typically serve a JSON reflecting its current state (luminance, AI data).

**B. User Progression & Reputation (Resonance):**
8.  `getUserResonance(address _user)`: Returns the current `resonance` score for any specified user address.
9.  `claimResonanceRewards()`: Enables users to claim rewards (e.g., Catalyst tokens) when they reach and unlock new `ProgressionTier`s based on their accumulated `resonance`.
10. `unlockProgressionTier(uint256 _tierId)`: Allows a user to formally advance to the next progression tier. This requires meeting a `requiredResonance` threshold and potentially paying a `requiredCatalyst` cost.
11. `getUserProfile(address _user)`: Retrieves a comprehensive profile for a user, including their `resonance` score, current `progressionTier`, and the count of Echoes they own.
12. `addProgressionTier(uint256 _requiredResonance, uint256 _requiredCatalyst, uint256 _rewardCatalyst, string _tierName)`: (Admin/Governance) Defines a new progression tier with its requirements and rewards.

**C. Seer Council (DAO) & Governance:**
13. `joinSeerCouncil()`: Allows eligible users (meeting `MIN_RESONANCE_FOR_COUNCIL` and `MIN_CATALYST_STAKE_FOR_COUNCIL` criteria) to become members of the decentralized Seer Council.
14. `submitCouncilProposal(string _description, address _target, bytes _calldata, uint256 _value)`: Seer Council members can submit proposals to enact changes within the protocol, specifying a target contract, calldata, and value.
15. `voteOnProposal(uint256 _proposalId, bool _support)`: Seer Council members cast their vote (for or against) on an active proposal.
16. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and met the required majority vote from the Seer Council.
17. `challengeEchoAIAnalysis(uint256 _echoId, bytes32 _initialRequestId)`: Seer Council members can challenge an existing AI analysis result for an Echo, potentially triggering a re-analysis or dispute resolution process.

**D. Catalyst Tokenomics & Protocol Management:**
18. `mintCatalystForRewards(address _recipient, uint256 _amount)`: (Admin/Protocol-controlled) Mints new Catalyst tokens, primarily used for distributing rewards to users and council members.
19. `updateProtocolFees(uint256 _newEchoSubmissionFee, uint256 _newResonateFee)`: (Governance) Adjusts the fees required for submitting Echoes and resonating with them.
20. `setOracleConfiguration(address _newOracleAddress, bytes32 _newJobId)`: (Governance) Updates the address of the oracle contract and the job ID used for AI analysis requests.
21. `withdrawProtocolFunds(address _recipient, uint256 _amount)`: (Governance) Allows the Seer Council to withdraw collected protocol funds (e.g., fees) to a specified recipient.
22. `setBaseURI(string _newURI)`: (Admin) Sets a base URI for the NFT metadata, used by `getEchoMetadataURI`.

**E. Standard ERC-721 & ERC-20 (Inherited for core functionality):**
*   **ERC-721 (`EphemeralEchoes` NFT):** `name()`, `symbol()`, `totalSupply()`, `balanceOf(address)`, `ownerOf(uint256)`, `approve(address,uint256)`, `getApproved(uint256)`, `setApprovalForAll(address,bool)`, `isApprovedForAll(address,address)`, `transferFrom(address,address,uint256)`, `safeTransferFrom(address,address,uint256)`, `tokenOfOwnerByIndex(address,uint256)`, `tokenByIndex(uint256)`.
*   **ERC-20 (`Catalyst` Token):** `name()`, `symbol()`, `decimals()`, `totalSupply()`, `balanceOf(address)`, `transfer(address,uint256)`, `allowance(address,address)`, `approve(address,uint256)`, `transferFrom(address,address,uint256)`, `burn(uint256)`, `burnFrom(address,uint256)`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic operations
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; // For burning Catalyst

// Oracle interface (e.g., for Chainlink external adapters)
// In a real Chainlink integration, this interface would be more specific to ChainlinkClient
// and its request/fulfill patterns. For demonstration, this generic interface suffices.
interface IOracle {
    function request(bytes32 _jobId, address _callbackAddress, bytes4 _callbackFunctionId, uint256 _echoId, string[] calldata _parameters) external returns (bytes32 requestId);
}

/**
 * @title Ephemeral Echoes Protocol
 * @dev A decentralized, evolving, and gamified social/artistic reputation system.
 * It leverages dynamic NFTs ("Echoes"), a user reputation score ("Resonance"),
 * AI-driven content analysis via oracles, and a decentralized autonomous organization
 * ("Seer Council") for governance.
 */

// Outline:
// I.  Introduction: Ephemeral Echoes Protocol - A decentralized, evolving, and gamified social/artistic reputation system.
//     It leverages dynamic NFTs ("Echoes"), a reputation score ("Resonance"), AI-driven content analysis via oracles,
//     and a decentralized autonomous organization ("Seer Council") for governance.
// II. Core Components:
//     A.  Echoes (ERC-721): Dynamic NFTs representing user-submitted content. Their properties (e.g., Luminance, AI sentiment) evolve based on interactions.
//     B.  Resonance: A user's on-chain reputation score, earned through contributing Echoes and interacting with others. Unlocks progression tiers.
//     C.  Catalyst (ERC-20): The protocol's utility token, used for actions, staking, and rewards.
//     D.  Seer Council: A DAO responsible for governance, protocol upgrades, and curating AI models/parameters.
//     E.  AI Oracle Integration: Facilitates off-chain AI analysis (e.g., sentiment, categorization) influencing Echo properties.
// III. Key Features:
//     - Dynamic NFTs with evolving metadata.
//     - On-chain reputation and progression system.
//     - Gamified interactions for earning rewards and advancing.
//     - Decentralized governance for future-proofing and community control.
//     - Integration with AI for content intelligence.

// Function Summary:
// **A. Core Protocol & Echo Management (Dynamic NFTs):**
// 1.  `submitEcho(string _contentURI)`: Mints a new Echo NFT with provided content URI. Requires Catalyst payment.
// 2.  `resonateWithEcho(uint256 _echoId)`: Increases an Echo's Luminance and its owner's Resonance. Costs Catalyst.
// 3.  `requestEchoAIAnalysis(uint256 _echoId)`: Triggers an oracle request for AI sentiment and categorization of an Echo.
// 4.  `fulfillEchoAIAnalysis(bytes32 _requestId, uint256 _echoId, uint8 _sentiment, string _category)`: Oracle callback to update Echo's AI analysis data.
// 5.  `retractEcho(uint256 _echoId)`: Allows an Echo owner to burn their Echo, refunding a portion of Catalyst.
// 6.  `getEchoData(uint256 _echoId)`: Retrieves all structured data for a specific Echo.
// 7.  `getEchoMetadataURI(uint256 _echoId)`: Generates the dynamic metadata URI for an Echo, reflecting its current state.
// **B. User Progression & Reputation (Resonance):**
// 8.  `getUserResonance(address _user)`: Returns the current Resonance score for a given user.
// 9.  `claimResonanceRewards()`: Allows users to claim rewards (e.g., Catalyst tokens) based on their accumulated Resonance tier.
// 10. `unlockProgressionTier(uint256 _tierId)`: Enables users to advance to a new progression tier, potentially requiring Resonance and Catalyst.
// 11. `getUserProfile(address _user)`: Retrieves a user's comprehensive profile data, including Resonance, tier, and owned Echoes.
// 12. `addProgressionTier(uint256 _requiredResonance, uint256 _requiredCatalyst, uint256 _rewardCatalyst, string _tierName)`: Defines a new progression tier.
// **C. Seer Council (DAO) & Governance:**
// 13. `joinSeerCouncil()`: Allows eligible users (high Resonance/staked Catalyst) to become members of the Seer Council.
// 14. `submitCouncilProposal(string _description, address _target, bytes _calldata, uint256 _value)`: Council members submit proposals for protocol changes.
// 15. `voteOnProposal(uint256 _proposalId, bool _support)`: Council members vote on active proposals.
// 16. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal.
// 17. `challengeEchoAIAnalysis(uint256 _echoId, bytes32 _initialRequestId)`: Council members can challenge the result of an AI analysis.
// **D. Catalyst Tokenomics & Protocol Management:**
// 18. `mintCatalystForRewards(address _recipient, uint256 _amount)`: Protocol-controlled function to mint Catalyst for rewards distribution.
// 19. `updateProtocolFees(uint256 _newEchoSubmissionFee, uint256 _newResonateFee)`: Governance function to adjust protocol fees.
// 20. `setOracleConfiguration(address _newOracleAddress, bytes32 _newJobId)`: Governance function to update the oracle service.
// 21. `withdrawProtocolFunds(address _recipient, uint256 _amount)`: Governance function to withdraw funds from the protocol treasury.
// 22. `setBaseURI(string _newURI)`: For NFT metadata.
// **E. Standard ERC-721 & ERC-20 (Additional functions to exceed 20 unique):**
// (These are inherited and provide foundational token functionality, contributing to the total count.)
// `transferFrom`, `safeTransferFrom`, `approve` (ERC721), `getApproved`, `setApprovalForAll`, `isApprovedForAll`,
// `balanceOf` (ERC20), `transfer` (ERC20), `approve` (ERC20), `allowance`, `burn`, `burnFrom`.

contract EphemeralEchoes is ERC721Enumerable, ERC20Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // NFT (Echo) Management
    Counters.Counter private _echoIds;

    struct Echo {
        string contentURI;         // IPFS/Arweave URI for the Echo's content (text, image, data blob)
        uint256 luminance;         // Dynamic property, increases with resonance (interaction)
        address creator;           // Original creator of the Echo
        uint256 creationTimestamp; // When the Echo was minted
        uint8 aiSentiment;         // AI-determined sentiment (e.g., 0-100 score, or enum for Neg/Neu/Pos)
        string aiCategory;         // AI-determined category/tags
        uint256 lastAIAuditTimestamp; // When AI analysis last updated
        bytes32 activeAIRequestId; // Stores the request ID for pending AI analysis
        bool aiAnalysisPending;    // True if an AI analysis request is active
        uint256 initialCatalystCost; // Cost paid to mint this Echo
    }

    mapping(uint256 => Echo) public echoes; // echoId => Echo data

    // User Profile & Resonance
    struct UserProfile {
        uint256 resonance;          // User's reputation score
        uint256 currentProgressionTier; // Current tier unlocked
    }

    mapping(address => UserProfile) public userProfiles; // user address => UserProfile data

    // Seer Council (DAO)
    struct CouncilProposal {
        uint256 id;
        string description;
        address target;       // Address of the contract to call
        bytes calldataPayload; // Calldata for the target contract
        uint256 value;        // Ether value to send with the call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Council member => voted status
        bool executed;
        bool proposalPassed;
    }

    Counters.Counter private _proposalIds;
    mapping(uint256 => CouncilProposal) public proposals;
    mapping(address => bool) public isCouncilMember; // Address => is member
    address[] public councilMembers; // Dynamic array of council members

    uint256 public constant MIN_RESONANCE_FOR_COUNCIL = 1000; // Example threshold
    uint256 public constant MIN_CATALYST_STAKE_FOR_COUNCIL = 1000 * (10 ** 18); // Example threshold (1000 CAT)
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Example voting period

    // Oracle Configuration
    IOracle public oracle;
    bytes32 public oracleJobId;
    mapping(bytes32 => uint256) public pendingAIRequests; // Chainlink requestId => echoId

    // Protocol Fees & Parameters
    uint256 public echoSubmissionFee;
    uint256 public resonateFee;
    uint256 public constant RESONANCE_PER_RES_ACTION = 10;
    uint256 public constant LUMINANCE_PER_RES_ACTION = 5;
    uint256 public constant RETRACT_REFUND_PERCENT = 50; // 50% refund on retraction

    // Progression Tiers (Example)
    struct ProgressionTier {
        uint256 requiredResonance;
        uint256 requiredCatalyst; // Catalyst to be burned/staked to unlock this tier
        uint256 rewardCatalyst;   // Catalyst reward for reaching this tier
        string tierName;
    }

    mapping(uint256 => ProgressionTier) public progressionTiers;
    uint256 public nextProgressionTierId; // Counter for next available tier ID

    // --- Events ---
    event EchoSubmitted(uint256 indexed echoId, address indexed creator, string contentURI, uint256 initialLuminance);
    event EchoResonated(uint256 indexed echoId, address indexed resonatingUser, uint256 newLuminance, uint256 newCreatorResonance);
    event AIAnalysisRequested(uint256 indexed echoId, bytes32 indexed requestId);
    event AIAnalysisFulfilled(uint256 indexed echoId, bytes32 indexed requestId, uint8 sentiment, string category);
    event EchoRetracted(uint256 indexed echoId, address indexed owner, uint256 refundedCatalyst);
    event ResonanceTierClaimed(address indexed user, uint256 newTier);
    event ProgressionTierUnlocked(address indexed user, uint256 tierId);
    event CouncilMemberJoined(address indexed member);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIAnalysisChallenged(uint256 indexed echoId, bytes32 indexed requestId, address indexed challenger);
    event ProtocolFeeUpdated(uint256 newEchoSubmissionFee, uint256 newResonateFee);
    event OracleConfigUpdated(address newOracleAddress, bytes32 newJobId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProgressionTierAdded(uint256 indexed tierId, uint256 requiredResonance, uint256 requiredCatalyst, uint256 rewardCatalyst, string tierName);

    // --- Modifiers ---
    modifier onlyCouncilMember() {
        require(isCouncilMember[msg.sender], "Not a Seer Council member");
        _;
    }

    // This modifier assumes the oracle's address is known and set correctly.
    modifier onlyOracle() {
        require(msg.sender == address(oracle), "Only callable by Oracle contract");
        _;
    }

    // --- Constructor ---
    constructor(
        address _initialOracle,
        bytes32 _initialOracleJobId,
        uint256 _initialEchoSubmissionFee,
        uint256 _initialResonateFee
    ) ERC721("Ephemeral Echo", "ECHO") ERC20("Catalyst", "CAT") Ownable(msg.sender) {
        oracle = IOracle(_initialOracle);
        oracleJobId = _initialOracleJobId;
        echoSubmissionFee = _initialEchoSubmissionFee;
        resonateFee = _initialResonateFee;

        // Initialize base progression tier (Tier 0 - Novice)
        progressionTiers[0] = ProgressionTier(0, 0, 0, "Novice Echoer");
        userProfiles[msg.sender].currentProgressionTier = 0; // Initialize deployer's tier
        nextProgressionTierId = 1; // Prepare for the next tier ID

        // Add some initial progression tiers
        addProgressionTier(500, 100 * (10**18), 50 * (10**18), "Resonant Initiate"); // Tier 1: 500 Resonance, burn 100 CAT, get 50 CAT reward
        addProgressionTier(1500, 500 * (10**18), 150 * (10**18), "Luminous Seeker"); // Tier 2: 1500 Resonance, burn 500 CAT, get 150 CAT reward
    }

    // --- A. Core Protocol & Echo Management (Dynamic NFTs) ---

    /**
     * @dev Mints a new Echo NFT. Requires 'echoSubmissionFee' Catalyst tokens.
     * The `_contentURI` should point to off-chain data (e.g., IPFS) describing the Echo.
     * Initial luminance is set to 1.
     * @param _contentURI URI pointing to the Echo's content.
     */
    function submitEcho(string memory _contentURI) public {
        require(echoSubmissionFee > 0, "Echo submission currently disabled or free");
        require(balanceOf(msg.sender, address(this)) >= echoSubmissionFee, "Insufficient Catalyst balance for fee");
        require(transferFrom(msg.sender, address(this), echoSubmissionFee), "Catalyst transfer failed for submission fee");

        _echoIds.increment();
        uint256 newEchoId = _echoIds.current();

        Echo storage newEcho = echoes[newEchoId];
        newEcho.contentURI = _contentURI;
        newEcho.luminance = 1; // Start with a base luminance
        newEcho.creator = msg.sender;
        newEcho.creationTimestamp = block.timestamp;
        newEcho.aiSentiment = 0; // Default: unanalyzed
        newEcho.aiCategory = ""; // Default: unanalyzed
        newEcho.initialCatalystCost = echoSubmissionFee;

        _safeMint(msg.sender, newEchoId);

        // Auto-increment user's resonance for creating an Echo
        userProfiles[msg.sender].resonance = userProfiles[msg.sender].resonance.add(RESONANCE_PER_RES_ACTION);

        emit EchoSubmitted(newEchoId, msg.sender, _contentURI, newEcho.luminance);
    }

    /**
     * @dev Allows a user to "resonate" with an Echo, increasing its luminance and the creator's resonance.
     * Costs 'resonateFee' Catalyst tokens.
     * @param _echoId The ID of the Echo to resonate with.
     */
    function resonateWithEcho(uint256 _echoId) public {
        require(_exists(_echoId), "Echo does not exist");
        require(resonateFee > 0, "Resonance currently disabled or free");
        require(ownerOf(_echoId) != msg.sender, "Cannot resonate with your own Echo");
        require(balanceOf(msg.sender, address(this)) >= resonateFee, "Insufficient Catalyst balance for fee");

        Echo storage echo = echoes[_echoId];
        address echoCreator = echo.creator;

        require(transferFrom(msg.sender, address(this), resonateFee), "Catalyst transfer failed for resonance fee");

        echo.luminance = echo.luminance.add(LUMINANCE_PER_RES_ACTION);
        userProfiles[echoCreator].resonance = userProfiles[echoCreator].resonance.add(RESONANCE_PER_RES_ACTION);

        emit EchoResonated(_echoId, msg.sender, echo.luminance, userProfiles[echoCreator].resonance);
    }

    /**
     * @dev Triggers an oracle request to analyze the sentiment and category of an Echo's content.
     * Only callable by the Echo's creator or a Seer Council member.
     * This is an asynchronous operation. `fulfillEchoAIAnalysis` will be called by the oracle.
     * @param _echoId The ID of the Echo to analyze.
     */
    function requestEchoAIAnalysis(uint256 _echoId) public {
        require(_exists(_echoId), "Echo does not exist");
        require(ownerOf(_echoId) == msg.sender || isCouncilMember[msg.sender], "Only creator or Council can request AI analysis");
        require(!echoes[_echoId].aiAnalysisPending, "AI analysis already pending for this Echo");
        require(address(oracle) != address(0), "Oracle address not set");

        Echo storage echo = echoes[_echoId];
        string[] memory params = new string[](2);
        params[0] = "echoId";
        params[1] = Strings.toString(_echoId);
        // In a real Chainlink adapter, params[1] might be echo.contentURI directly,
        // or the adapter would fetch the content based on echoId.

        bytes32 requestId = oracle.request(oracleJobId, address(this), this.fulfillEchoAIAnalysis.selector, _echoId, params);
        pendingAIRequests[requestId] = _echoId;
        echo.activeAIRequestId = requestId;
        echo.aiAnalysisPending = true;

        emit AIAnalysisRequested(_echoId, requestId);
    }

    /**
     * @dev Callback function invoked by the oracle contract after AI analysis is complete.
     * Updates the Echo's AI sentiment and category.
     * @param _requestId The ID of the original oracle request.
     * @param _echoId The ID of the Echo that was analyzed.
     * @param _sentiment The AI-determined sentiment score (e.g., 0-100).
     * @param _category The AI-determined category or tag for the Echo.
     */
    function fulfillEchoAIAnalysis(bytes32 _requestId, uint256 _echoId, uint8 _sentiment, string memory _category) external onlyOracle {
        require(pendingAIRequests[_requestId] == _echoId, "Mismatch in request ID and Echo ID");
        require(echoes[_echoId].aiAnalysisPending && echoes[_echoId].activeAIRequestId == _requestId, "No pending AI analysis for this Echo with this request ID");

        Echo storage echo = echoes[_echoId];
        echo.aiSentiment = _sentiment;
        echo.aiCategory = _category;
        echo.lastAIAuditTimestamp = block.timestamp;
        echo.aiAnalysisPending = false;
        delete pendingAIRequests[_requestId];
        delete echo.activeAIRequestId; // Clear the request ID

        emit AIAnalysisFulfilled(_echoId, _requestId, _sentiment, _category);
    }

    /**
     * @dev Allows an Echo's owner to retract (burn) their Echo.
     * A portion of the initial Catalyst submission fee is refunded.
     * @param _echoId The ID of the Echo to retract.
     */
    function retractEcho(uint256 _echoId) public {
        require(_exists(_echoId), "Echo does not exist");
        require(ownerOf(_echoId) == msg.sender, "Only the Echo owner can retract it");

        Echo storage echo = echoes[_echoId];
        uint256 refundAmount = echo.initialCatalystCost.mul(RETRACT_REFUND_PERCENT).div(100);

        _burn(_echoId); // Burn the NFT

        // Refund Catalyst from the protocol's balance
        require(transfer(msg.sender, refundAmount), "Failed to refund Catalyst");

        // Optionally, reduce creator's resonance for retraction. Ensure it doesn't go negative.
        userProfiles[msg.sender].resonance = userProfiles[msg.sender].resonance.sub(RESONANCE_PER_RES_ACTION);

        delete echoes[_echoId]; // Clear Echo data from mapping

        emit EchoRetracted(_echoId, msg.sender, refundAmount);
    }

    /**
     * @dev Retrieves all stored data for a specific Echo.
     * @param _echoId The ID of the Echo.
     * @return A tuple containing all Echo properties.
     */
    function getEchoData(uint256 _echoId) public view returns (
        string memory contentURI,
        uint256 luminance,
        address creator,
        uint256 creationTimestamp,
        uint8 aiSentiment,
        string memory aiCategory,
        uint256 lastAIAuditTimestamp,
        bool aiAnalysisPending
    ) {
        require(_exists(_echoId), "Echo does not exist");
        Echo storage echo = echoes[_echoId];
        return (
            echo.contentURI,
            echo.luminance,
            echo.creator,
            echo.creationTimestamp,
            echo.aiSentiment,
            echo.aiCategory,
            echo.lastAIAuditTimestamp,
            echo.aiAnalysisPending
        );
    }

    /**
     * @dev Generates the dynamic metadata URI for an Echo, reflecting its current state.
     * This URI would typically point to an API endpoint serving JSON metadata.
     * @param _tokenId The ID of the Echo.
     * @return The dynamic metadata URI.
     */
    function getEchoMetadataURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Echo does not exist");
        // In a real scenario, this would point to a service that dynamically generates JSON metadata
        // based on the Echo's properties (luminance, sentiment, category, etc.).
        // Example: https://api.ephemeral-echoes.xyz/metadata/{_tokenId}
        // The service would query this contract for Echo data and format it.
        return string(abi.encodePacked(_baseURI, Strings.toString(_tokenId), ".json"));
    }


    // --- B. User Progression & Reputation (Resonance) ---

    /**
     * @dev Returns the current Resonance score for a given user.
     * @param _user The address of the user.
     * @return The user's Resonance score.
     */
    function getUserResonance(address _user) public view returns (uint256) {
        return userProfiles[_user].resonance;
    }

    /**
     * @dev Allows users to claim rewards based on their accumulated Resonance tier.
     * This function checks if the user has reached the next tier and mints Catalyst tokens as a reward.
     * Rewards are only claimable once per tier.
     */
    function claimResonanceRewards() public {
        uint256 currentTierId = userProfiles[msg.sender].currentProgressionTier;
        uint256 nextTierToUnlock = currentTierId.add(1);

        // Check if next tier is defined and user meets resonance requirement
        require(progressionTiers[nextTierToUnlock].requiredResonance > 0 || nextTierToUnlock == 0, "No new progression tier available or defined");
        
        ProgressionTier storage nextTier = progressionTiers[nextTierToUnlock];
        require(userProfiles[msg.sender].resonance >= nextTier.requiredResonance, "Not enough Resonance to claim next tier rewards");

        // Update user's tier
        userProfiles[msg.sender].currentProgressionTier = nextTierToUnlock;

        // Mint and transfer reward Catalyst
        if (nextTier.rewardCatalyst > 0) {
            _mint(msg.sender, nextTier.rewardCatalyst);
        }

        emit ResonanceTierClaimed(msg.sender, nextTierToUnlock);
    }

    /**
     * @dev Enables users to advance to a new progression tier. This might require
     * a combination of Resonance and Catalyst payment/staking.
     * @param _tierId The ID of the tier the user wishes to unlock.
     */
    function unlockProgressionTier(uint256 _tierId) public {
        require(_tierId == userProfiles[msg.sender].currentProgressionTier.add(1), "Can only unlock the next sequential tier");
        require(progressionTiers[_tierId].requiredResonance > 0 || _tierId == 0, "Tier not defined or invalid");

        ProgressionTier storage tier = progressionTiers[_tierId];
        require(userProfiles[msg.sender].resonance >= tier.requiredResonance, "Not enough Resonance for this tier");
        require(balanceOf(msg.sender) >= tier.requiredCatalyst, "Not enough Catalyst to pay for this tier");

        // Catalyst is consumed (burned) for unlocking a tier.
        burnFrom(msg.sender, tier.requiredCatalyst);

        userProfiles[msg.sender].currentProgressionTier = _tierId;

        emit ProgressionTierUnlocked(msg.sender, _tierId);
    }

    /**
     * @dev Retrieves a user's comprehensive profile data.
     * @param _user The address of the user.
     * @return A tuple containing the user's Resonance, current progression tier, and owned Echo count.
     */
    function getUserProfile(address _user) public view returns (uint256 resonance, uint256 currentProgressionTier, uint256 ownedEchoCount) {
        UserProfile storage profile = userProfiles[_user];
        return (profile.resonance, profile.currentProgressionTier, balanceOf(_user)); // ERC721 token count
    }

    /**
     * @dev Adds a new progression tier definition. Callable only by the contract owner initially.
     * This function should eventually be governed by the Seer Council.
     * @param _requiredResonance Minimum Resonance needed for this tier.
     * @param _requiredCatalyst Catalyst cost to unlock this tier (will be burned).
     * @param _rewardCatalyst Catalyst reward for reaching this tier.
     * @param _tierName Descriptive name for the tier.
     */
    function addProgressionTier(uint256 _requiredResonance, uint256 _requiredCatalyst, uint256 _rewardCatalyst, string memory _tierName) public onlyOwner {
        progressionTiers[nextProgressionTierId] = ProgressionTier(_requiredResonance, _requiredCatalyst, _rewardCatalyst, _tierName);
        emit ProgressionTierAdded(nextProgressionTierId, _requiredResonance, _requiredCatalyst, _rewardCatalyst, _tierName);
        nextProgressionTierId++;
    }


    // --- C. Seer Council (DAO) & Governance ---

    /**
     * @dev Allows eligible users to join the Seer Council.
     * Requires minimum Resonance and a minimum Catalyst balance (as a proxy for stake).
     */
    function joinSeerCouncil() public {
        require(!isCouncilMember[msg.sender], "Already a Seer Council member");
        require(userProfiles[msg.sender].resonance >= MIN_RESONANCE_FOR_COUNCIL, "Not enough Resonance to join Council");
        require(balanceOf(msg.sender) >= MIN_CATALYST_STAKE_FOR_COUNCIL, "Not enough Catalyst held for Council membership");

        isCouncilMember[msg.sender] = true;
        councilMembers.push(msg.sender); // Add to the dynamic array
        emit CouncilMemberJoined(msg.sender);
    }

    /**
     * @dev Allows a Seer Council member to submit a new governance proposal.
     * @param _description A detailed description of the proposal.
     * @param _target The address of the contract the proposal intends to interact with (often this contract).
     * @param _calldata The encoded function call data for the target contract.
     * @param _value The Ether value (if any) to send with the call.
     */
    function submitCouncilProposal(string memory _description, address _target, bytes memory _calldata, uint256 _value) public onlyCouncilMember {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        CouncilProposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.description = _description;
        newProposal.target = _target;
        newProposal.calldataPayload = _calldata;
        newProposal.value = _value;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp.add(PROPOSAL_VOTING_PERIOD);
        newProposal.executed = false;
        newProposal.proposalPassed = false;
        newProposal.yesVotes = 0; // Initialize votes
        newProposal.noVotes = 0;

        emit ProposalSubmitted(newProposalId, msg.sender, _description);
    }

    /**
     * @dev Allows a Seer Council member to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyCouncilMember {
        CouncilProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(1);
        } else {
            proposal.noVotes = proposal.noVotes.add(1);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted-on proposal after its voting period has ended.
     * Requires more than 50% 'yes' votes from all current council members.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyCouncilMember {
        CouncilProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalCouncilMembers = councilMembers.length;
        require(totalCouncilMembers > 0, "No active council members to validate");

        // Majority rule: > 50% of *all active council members* voted 'yes'
        // This is a strict majority, adjust if simple majority of votes cast is desired.
        // For a more robust DAO, consider weighted voting or a dynamic quorum.
        require(proposal.yesVotes > totalCouncilMembers.div(2), "Proposal did not pass majority vote");

        proposal.proposalPassed = true;

        // Execute the proposal's calldata
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a Seer Council member to challenge the result of an AI analysis for an Echo.
     * This currently just marks the Echo as needing re-analysis and clears existing AI data.
     * In a more complex system, it could trigger a new oracle request with higher priority or
     * initiate a separate dispute resolution process involving multiple AI models or human review.
     * @param _echoId The ID of the Echo whose AI analysis is being challenged.
     * @param _initialRequestId The request ID of the AI analysis being challenged (optional, but good for context).
     */
    function challengeEchoAIAnalysis(uint256 _echoId, bytes32 _initialRequestId) public onlyCouncilMember {
        require(_exists(_echoId), "Echo does not exist");
        Echo storage echo = echoes[_echoId];
        require(echo.lastAIAuditTimestamp > 0 || echo.aiAnalysisPending, "Echo has not been analyzed by AI or analysis is not active");
        
        // Reset AI analysis data to indicate it's challenged/needs re-analysis
        echo.aiSentiment = 0; // Reset
        echo.aiCategory = "Challenged"; // Mark as challenged
        echo.lastAIAuditTimestamp = 0; // Reset timestamp
        echo.aiAnalysisPending = false; // No longer actively pending

        // Future extension: automatically trigger a new requestEchoAIAnalysis here.

        emit AIAnalysisChallenged(_echoId, _initialRequestId, msg.sender);
    }

    // --- D. Catalyst Tokenomics & Protocol Management ---

    /**
     * @dev Mints Catalyst tokens, typically used for distributing rewards to users
     * who achieve progression tiers or contribute significantly.
     * Callable only by the contract owner (or eventually by governance via proposals).
     * @param _recipient The address to mint tokens to.
     * @param _amount The amount of Catalyst to mint.
     */
    function mintCatalystForRewards(address _recipient, uint256 _amount) public onlyOwner {
        _mint(_recipient, _amount);
    }

    /**
     * @dev Updates the protocol fees for Echo submission and resonance actions.
     * Callable only by governance (via a successful Council proposal execution).
     * For demonstration, `onlyOwner` is used. In a real DAO, this would be callable
     * only by the `executeProposal` function when `this` contract is the target.
     * @param _newEchoSubmissionFee The new fee for submitting an Echo.
     * @param _newResonateFee The new fee for resonating with an Echo.
     */
    function updateProtocolFees(uint256 _newEchoSubmissionFee, uint256 _newResonateFee) public onlyOwner {
        echoSubmissionFee = _newEchoSubmissionFee;
        resonateFee = _newResonateFee;
        emit ProtocolFeeUpdated(_newEchoSubmissionFee, _newResonateFee);
    }

    /**
     * @dev Updates the oracle contract address and job ID.
     * Callable only by governance (via a successful Council proposal execution).
     * For demonstration, `onlyOwner` is used. In a real DAO, this would be callable
     * only by the `executeProposal` function when `this` contract is the target.
     * @param _newOracleAddress The address of the new oracle contract.
     * @param _newJobId The new job ID for oracle requests.
     */
    function setOracleConfiguration(address _newOracleAddress, bytes32 _newJobId) public onlyOwner {
        require(_newOracleAddress != address(0), "New oracle address cannot be zero");
        oracle = IOracle(_newOracleAddress);
        oracleJobId = _newJobId;
        emit OracleConfigUpdated(_newOracleAddress, _newJobId);
    }

    /**
     * @dev Allows withdrawal of funds (e.g., collected fees) from the protocol treasury.
     * Callable only by governance (via a successful Council proposal execution).
     * For demonstration, `onlyOwner` is used. In a real DAO, this would be callable
     * only by the `executeProposal` function when `this` contract is the target.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawProtocolFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance in protocol treasury");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Sets the base URI for ERC721 token metadata.
     * This function is typically called by the owner or governance to point to a metadata server.
     * @param newURI The new base URI string.
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        _baseURI = newURI;
    }

    // --- E. Standard ERC-721 & ERC-20 (Included for completeness and function count) ---

    // ERC-721 functions are largely inherited from ERC721Enumerable and ERC721
    // and provide standard NFT capabilities like:
    // name(), symbol(), totalSupply(), balanceOf(address), ownerOf(uint256),
    // approve(address,uint256), getApproved(uint256), setApprovalForAll(address,bool),
    // isApprovedForAll(address,address), transferFrom(address,address,uint256),
    // safeTransferFrom(address,address,uint256), safeTransferFrom(address,address,uint256,bytes)
    // tokenOfOwnerByIndex(address,uint256), tokenByIndex(uint256)
    // tokenURI(uint256) - Overridden by getEchoMetadataURI for dynamic URI generation.
    string private _baseURI;
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    // ERC-20 functions are inherited from ERC20 & ERC20Burnable and provide standard token capabilities:
    // name(), symbol(), decimals(), totalSupply(), balanceOf(address), transfer(address,uint256),
    // allowance(address,address), approve(address,uint256), transferFrom(address,address,uint256),
    // burn(uint256), burnFrom(address,uint256)


    // Fallback and Receive functions to allow the contract to receive Ether (e.g., for withdrawal).
    receive() external payable {}
    fallback() external payable {}
}
```