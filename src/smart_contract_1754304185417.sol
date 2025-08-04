Here's a Solidity smart contract for "AetherForge," a decentralized platform for AI-assisted content creation, curation, and dynamic NFT ownership. This contract aims to be creative and advanced by combining AI oracle integration, a multi-faceted reputation system, dynamic NFTs, and decentralized curation, all while striving to avoid direct duplication of common open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit clarity, though 0.8+ has overflow checks

/*
    /// @title AetherForge - Decentralized Adaptive AI-Assisted Content Forge
    /// @author YourName (replace with your actual name/alias if desired)
    /// @notice AetherForge is a pioneering smart contract platform for decentralized AI-assisted content creation, curation, and ownership.
    ///         It leverages dynamic NFTs, a multi-faceted reputation system, and oracle integration for AI evaluation to foster
    ///         a vibrant ecosystem where high-quality, unique content is produced, evaluated, and owned by the community.
    /// @dev This contract relies on an off-chain AI Oracle for content evaluation and a robust front-end for URI resolution
    ///      and rich user experience. Reputation scores are integers for simplicity, but could be enhanced with more complex
    ///      decay or weighting algorithms in a production environment. Staking mechanisms are simplified for illustration;
    ///      in a real system, stakes would be held securely in escrow for potential slashing/return.
    /// @custom:security-contact security@example.com (Replace with a real contact)
*/

/*
    Outline and Function Summary:

    I.  Contract Overview:
        AetherForge orchestrates a community-driven process for generating AI-assisted digital content.
        It introduces several innovative concepts:
        - **AI-Assisted Content Creation:** Users provide prompts, submit AI-generated content (e.g., images, text snippets), and an external AI Oracle evaluates uniqueness, quality, and adherence to prompt.
        - **Dynamic NFTs:** Content that passes evaluation is minted as an ERC721 NFT, whose metadata (e.g., quality score, popularity metrics, or even visual traits) can evolve based on ongoing community engagement or further AI analysis. This makes NFTs "living" assets.
        - **Multi-Faceted Reputation System:** Distinct reputation scores are maintained for:
            - **Prompt Engineers:** Who craft effective and inspiring prompts.
            - **Content Creators:** Who generate and submit high-quality AI content.
            - **Curators:** Who diligently review, rate, and provide feedback on submissions.
          This incentivizes high-quality participation across all roles.
        - **Decentralized Curation:** A staking-based system ensures diligent and fair content review, with a built-in dispute mechanism for creators to challenge unfair outcomes.
        - **On-chain Licensing:** NFTs can carry explicit, transparent licensing terms directly on-chain, defining usage rights.

    II. Structs & State Variables:
        Defines the core data structures for `Prompt`s, `ContentSubmission`s, and `CurationVote`s.
        Includes mappings to store their states, user reputations, and various configurable parameters that govern
        the platform's economics and behavior.

    III. Access Control & Configuration:
        Manages contract ownership via OpenZeppelin's `Ownable`, enables emergency pausing via `Pausable`,
        and allows the owner to set the trusted AI oracle address and dynamically adjust key system parameters.
        - `constructor(address _aiOracleAddress)`: Initializes the contract, sets the owner, and configures initial parameters.
        - `setOracleAddress(address _oracle)`: Sets the address of the trusted AI oracle.
        - `updateParameter(string memory _paramName, uint256 _newValue)`: Allows dynamic adjustment of key contract parameters (e.g., stake amounts, minimum scores, rewards).
        - `pause()`: Pauses critical contract functionalities (emergency stop).
        - `unpause()`: Unpauses the contract.

    IV. Prompt Engineering Module:
        A dedicated system for users to submit creative prompts for AI content generation. The community
        can vote on the quality of these prompts, and users can tip valuable prompt engineers, all contributing
        to their reputation.
        - `submitPrompt(string memory _promptText, string memory _category)`: Registers a new prompt, requiring a small stake.
        - `voteOnPrompt(uint256 _promptId, bool _isGood)`: Allows users to upvote or downvote prompts, influencing their quality score and the prompt engineer's reputation.
        - `tipPromptEngineer(uint256 _promptId)`: Enables direct financial tipping of prompt creators, boosting their reputation.
        - `claimPromptTips(uint256 _promptId)`: Allows prompt engineers to claim their accumulated tips.

    V.  Content Creation & Submission Module:
        Facilitates the submission of AI-generated content by creators. Each submission is linked to a
        prompt and undergoes an initial evaluation by the AI oracle before community curation.
        - `submitAIGeneratedContent(uint256 _promptId, string memory _contentURI, string memory _licensingOption, bytes32 _uniqueContentHash)`: Submits AI-generated content, requiring a creator stake and a unique content hash.
        - `requestAIEvaluation(uint256 _submissionId)`: Initiates an AI evaluation request for a submitted content (conceptual, as oracle acts on events).
        - `receiveAIEvaluation(uint256 _submissionId, uint256 _aiScore, string memory _aiFeedbackURI) external`: Callback function for the AI oracle to deliver evaluation results and update submission status.
        - `finalizeContentSubmission(uint256 _submissionId)`: Finalizes a submission if it meets both AI and average curator score criteria, making it eligible for NFT minting.

    VI. Content Curation & Evaluation Module:
        A decentralized mechanism for community members to review and score submitted content. Curators stake
        funds to participate, provide scores and feedback, and earn reputation for accurate assessments.
        Includes a simple dispute system for creators.
        - `stakeForCuration(uint256 _submissionId)`: Allows a user to stake funds to become a curator for a specific submission.
        - `submitCurationVote(uint256 _submissionId, uint256 _score, string memory _feedbackURI)`: Enables staked curators to vote on content quality and provide feedback.
        - `disputeCurationResult(uint256 _submissionId)`: Allows content creators to dispute outcomes (e.g., unfair rejection) by paying a fee.
        - `resolveCurationDispute(uint256 _submissionId, bool _creatorWins) external`: Privileged function (owner/DAO) to resolve disputes, affecting participant reputations.

    VII. Dynamic NFT Management:
        Manages the lifecycle of content once it's approved, minting it as an ERC721 NFT. The "dynamic"
        aspect refers to the ability to update the NFT's metadata post-mint based on ongoing engagement,
        new evaluations, or community trends, making the NFTs "living" assets.
        - `mintContentNFT(uint256 _submissionId)`: Mints the content as an ERC721 NFT upon successful finalization.
        - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows authorized entities (owner/DAO) to update an NFT's metadata URI, enabling dynamism.
        - `getNFTLicense(uint256 _tokenId)`: Retrieves the explicit licensing option chosen for a specific NFT.
        - `tokenURI(uint256 _tokenId)`: Overrides ERC721's `tokenURI` to return the current dynamic metadata URI.
        - `transferNFT(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function wrapper.

    VIII. Reputation & Rewards System:
        Tracks and manages distinct reputation scores for Prompt Engineers, Content Creators, and Curators.
        Successful, high-quality participation increases reputation, while negative actions (e.g., submitting poor content, losing a dispute) can lead to reputation loss. Includes a mechanism for claiming rewards.
        - `getCreatorReputation(address _creator)`: Retrieves the reputation score of a content creator.
        - `getCuratorReputation(address _curator)`: Retrieves the reputation score of a content curator.
        - `getPromptEngineerReputation(address _promptEngineer)`: Retrieves the reputation score of a prompt engineer.
        - `claimRewards()`: Allows participants to claim their accumulated rewards (e.g., share of platform fees, returned stakes, success bonuses).
        - `triggerReputationDecay()`: (Conceptual) Owner-triggered function to periodically decay reputation scores, encouraging active and sustained positive participation.

    IX. Utility Functions:
        Helper functions for general stake management and data retrieval.
        - `withdrawStakedFunds(uint256 _amount)`: Allows users to withdraw general participation stakes (if any).
        - `getTotalSupply()`: Returns the total number of NFTs minted by the contract.
        - `receive()` and `fallback()`: Allow the contract to receive plain ETH transfers.
*/

contract AetherForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- II. Structs & State Variables ---

    // Represents a prompt submitted by a user for AI content generation
    struct Prompt {
        string text;            // The textual description of the prompt
        string category;        // Categorization of the prompt (e.g., "Abstract Art", "Sci-Fi Story")
        address creator;        // The address of the user who submitted this prompt
        uint256 submissionTime; // Timestamp of prompt submission
        uint256 upVotes;        // Number of upvotes received
        uint256 downVotes;      // Number of downvotes received
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this prompt
        uint256 totalTips;      // Sum of ETH tips received by the prompt creator
        bool isActive;          // True if the prompt is active and usable
    }

    // Represents an AI-generated content submission based on a prompt
    struct ContentSubmission {
        uint256 promptId;           // The ID of the prompt this content is based on
        address creator;            // The address of the user who submitted this content
        string contentURI;          // URI to the actual AI-generated content (e.g., IPFS hash)
        string licensingOption;     // Chosen licensing for this content (e.g., "CreativeCommons-BY", "Commercial-Restricted")
        bytes32 uniqueContentHash;  // A unique cryptographic hash of the content to prevent duplicates
        uint256 submissionTime;     // Timestamp of content submission
        uint256 aiScore;            // Score from the AI oracle (e.g., 0-100, for uniqueness, quality, prompt adherence)
        string aiFeedbackURI;       // URI to detailed AI feedback or report
        bool aiEvaluated;           // True if AI oracle has completed evaluation
        uint256 totalCuratorScore;  // Sum of scores from all curators
        uint256 numCurators;        // Number of unique curators who voted
        bool finalized;             // True if content has passed all checks (AI and curation) and is ready for minting
        bool rejected;              // True if content was rejected by AI or curation
        uint252 creatorStake;       // Amount staked by the creator for this submission
        uint256 nftTokenId;         // The ID of the minted NFT, if any (0 if not minted)
        mapping(address => CurationVote) curatorVotes; // Maps curator address to their specific vote
        mapping(address => bool) hasStakedForCuration; // Tracks if a curator has staked for this specific submission
    }

    // Represents a single curation vote by a curator
    struct CurationVote {
        uint256 score;      // Curator's score for the content (e.g., 1-10)
        string feedbackURI; // URI to detailed text feedback from the curator
        uint256 voteTime;   // Timestamp of the vote
        bool hasVoted;      // True if this vote slot is valid (used to check if a curator has voted)
    }

    // Counters for generating unique IDs for prompts, submissions, and NFTs
    Counters.Counter private _promptIdCounter;
    Counters.Counter private _submissionIdCounter;
    Counters.Counter private _tokenIdCounter; // For ERC721 NFTs

    // Mappings for storing main data structures
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => ContentSubmission) public contentSubmissions;
    mapping(uint256 => string) private _tokenMetadataURIs; // Stores the mutable metadata URI for dynamic NFTs

    // Reputation scores for different roles (can be negative for penalties)
    mapping(address => int256) public creatorReputation;
    mapping(address => int256) public curatorReputation;
    mapping(address => int256) public promptEngineerReputation;

    // Staking balances for general participation and pending rewards for participants
    mapping(address => uint256) public generalParticipationStake;
    mapping(address => uint256) public pendingRewards;

    // Configurable parameters of the platform
    address public aiOracleAddress;             // Address of the trusted AI Oracle
    uint256 public promptSubmissionStake;       // ETH required to submit a prompt
    uint256 public contentSubmissionStake;      // ETH required to submit content
    uint256 public curationStakeAmount;         // ETH required to stake for curation on a submission
    uint256 public minAIAcceptanceScore;        // Minimum AI score for content to be considered acceptable
    uint256 public minCuratorAcceptanceScore;   // Minimum average curator score for content acceptance
    uint256 public curatorParticipationReward;  // Reward for successful curation participation
    uint256 public creatorSuccessReward;        // Reward for successfully minted content
    uint256 public disputeFee;                  // Fee to dispute a curation result
    uint256 public promptVoteReputationBoost;   // Reputation gain for a user whose prompt receives a positive vote
    uint256 public promptTipRewardMultiplier;   // Multiplier to convert ETH tips into prompt engineer reputation points
    uint256 public reputationDecayInterval;     // Time interval for reputation decay (e.g., 30 days)
    uint256 public lastReputationDecayTime;     // Timestamp of the last reputation decay event

    // Events to log important actions and state changes
    event PromptSubmitted(uint256 indexed promptId, address indexed creator, string category, string promptText);
    event PromptVoted(uint256 indexed promptId, address indexed voter, bool isUpvote);
    event PromptTipped(uint256 indexed promptId, address indexed tipper, address indexed engineer, uint256 amount);
    event ContentSubmitted(uint256 indexed submissionId, uint256 indexed promptId, address indexed creator, string contentURI, string licensingOption);
    event AIEvaluationReceived(uint256 indexed submissionId, uint256 aiScore, string aiFeedbackURI);
    event ContentFinalized(uint256 indexed submissionId, bool accepted, address indexed creator);
    event CuratorStaked(uint256 indexed submissionId, address indexed curator, uint256 amount);
    event CurationVoteSubmitted(uint256 indexed submissionId, address indexed curator, uint256 score);
    event CurationDisputed(uint256 indexed submissionId, address indexed disputer);
    event CurationDisputeResolved(uint256 indexed submissionId, bool creatorWins, address indexed resolver);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed submissionId, address indexed owner, string tokenURI);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event ParametersUpdated(string paramName, uint256 newValue);
    event ReputationDecayed(uint256 timestamp);

    // --- III. Access Control & Configuration ---

    /// @notice Constructor to initialize the AetherForge contract.
    /// @dev Sets the ERC721 name and symbol, establishes the contract owner, and initializes default parameters.
    /// @param _aiOracleAddress The initial address of the trusted AI oracle.
    constructor(address _aiOracleAddress)
        ERC721("AetherForgeContent", "AFC") // Initialize ERC721 contract with name and symbol
        Ownable(msg.sender) // Set the deployer as the initial owner
    {
        require(_aiOracleAddress != address(0), "AetherForge: AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;

        // Set initial default parameters (can be updated later by owner)
        promptSubmissionStake = 0.005 ether;    // Example: 0.005 ETH to submit a prompt
        contentSubmissionStake = 0.01 ether;    // Example: 0.01 ETH to submit content
        curationStakeAmount = 0.002 ether;      // Example: 0.002 ETH to stake for curation
        minAIAcceptanceScore = 70;              // Example: AI score must be at least 70/100
        minCuratorAcceptanceScore = 7;          // Example: Average curator score must be at least 7/10
        curatorParticipationReward = 0.001 ether; // Example reward for successful curation
        creatorSuccessReward = 0.005 ether;     // Example reward for successfully minted content
        disputeFee = 0.001 ether;               // Example fee to initiate a dispute
        promptVoteReputationBoost = 1;          // 1 reputation point per successful prompt vote
        promptTipRewardMultiplier = 100;        // 100 reputation points per ETH tipped
        reputationDecayInterval = 30 days;      // Reputation decays every 30 days
        lastReputationDecayTime = block.timestamp; // Set initial decay time
    }

    /// @dev Modifier to restrict function calls only to the designated AI Oracle address.
    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "AetherForge: Only AI Oracle can call this function");
        _;
    }

    /// @notice Sets the address of the trusted AI Oracle.
    /// @dev Can only be called by the contract owner. Essential for security and system functionality.
    /// @param _oracle The new address for the AI oracle.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "AetherForge: Oracle address cannot be zero");
        aiOracleAddress = _oracle;
    }

    /// @notice Updates a configurable parameter of the contract.
    /// @dev This function allows the owner to fine-tune economic incentives or behavioral rules of the platform.
    ///      Uses string comparison to map parameter names to their respective state variables.
    /// @param _paramName The name of the parameter to update (e.g., "promptSubmissionStake").
    /// @param _newValue The new `uint256` value for the parameter.
    function updateParameter(string memory _paramName, uint256 _newValue) external onlyOwner {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));

        if (paramHash == keccak256(abi.encodePacked("promptSubmissionStake"))) {
            promptSubmissionStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("contentSubmissionStake"))) {
            contentSubmissionStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("curationStakeAmount"))) {
            curationStakeAmount = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minAIAcceptanceScore"))) {
            require(_newValue <= 100, "AetherForge: Max AI score is 100");
            minAIAcceptanceScore = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minCuratorAcceptanceScore"))) {
            require(_newValue <= 10, "AetherForge: Max curator score is 10");
            minCuratorAcceptanceScore = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("curatorParticipationReward"))) {
            curatorParticipationReward = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("creatorSuccessReward"))) {
            creatorSuccessReward = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("disputeFee"))) {
            disputeFee = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("promptVoteReputationBoost"))) {
            promptVoteReputationBoost = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("promptTipRewardMultiplier"))) {
            promptTipRewardMultiplier = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("reputationDecayInterval"))) {
            reputationDecayInterval = _newValue;
        } else {
            revert("AetherForge: Invalid parameter name");
        }
        emit ParametersUpdated(_paramName, _newValue);
    }

    /// @notice Pauses contract activity for critical functions in emergency situations.
    /// @dev Implemented using OpenZeppelin's Pausable. Can only be called by the contract owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract activity, restoring normal operations.
    /// @dev Implemented using OpenZeppelin's Pausable. Can only be called by the contract owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- IV. Prompt Engineering Module ---

    /// @notice Submits a new prompt for AI content generation.
    /// @dev Requires `promptSubmissionStake` ETH to be sent with the transaction as a fee or held stake.
    /// @param _promptText The textual description of the prompt.
    /// @param _category The category or genre of the prompt (e.g., "Fantasy Art", "Short Story").
    function submitPrompt(string memory _promptText, string memory _category) external payable nonReentrant whenNotPaused {
        require(msg.value >= promptSubmissionStake, "AetherForge: Insufficient stake for prompt submission");
        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();
        prompts[newPromptId] = Prompt({
            text: _promptText,
            category: _category,
            creator: msg.sender,
            submissionTime: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            totalTips: 0,
            isActive: true
        });
        // For simplicity, stake is consumed as a fee here. In a more complex system, it could be held
        // in escrow and returned or slashed based on prompt performance.
        emit PromptSubmitted(newPromptId, msg.sender, _category, _promptText);
    }

    /// @notice Allows a user to vote on a prompt's quality (upvote or downvote).
    /// @dev A user can vote only once per prompt. Positive votes contribute to the Prompt Engineer's reputation.
    /// @param _promptId The ID of the prompt to vote on.
    /// @param _isGood True for an upvote, false for a downvote.
    function voteOnPrompt(uint256 _promptId, bool _isGood) external whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "AetherForge: Prompt does not exist");
        require(prompt.isActive, "AetherForge: Prompt is inactive");
        require(msg.sender != prompt.creator, "AetherForge: Creator cannot vote on their own prompt");
        require(!prompt.hasVoted[msg.sender], "AetherForge: Already voted on this prompt");

        prompt.hasVoted[msg.sender] = true;
        if (_isGood) {
            prompt.upVotes++;
            promptEngineerReputation[prompt.creator] += int256(promptVoteReputationBoost);
        } else {
            prompt.downVotes++;
            // Optional: Implement negative reputation impact for heavily downvoted prompts after a threshold
        }
        emit PromptVoted(_promptId, msg.sender, _isGood);
    }

    /// @notice Allows users to tip prompt engineers for their valuable prompts.
    /// @dev Tips directly contribute to the prompt engineer's reputation score and earnings.
    /// @param _promptId The ID of the prompt to tip.
    function tipPromptEngineer(uint256 _promptId) external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "AetherForge: Tip amount must be greater than zero");
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "AetherForge: Prompt does not exist");
        require(prompt.isActive, "AetherForge: Prompt is inactive");
        require(msg.sender != prompt.creator, "AetherForge: Cannot tip your own prompt");

        prompt.totalTips += msg.value;
        // Convert ETH value of tips to reputation points using a multiplier
        promptEngineerReputation[prompt.creator] += int256(msg.value.mul(promptTipRewardMultiplier) / 1 ether);
        emit PromptTipped(_promptId, msg.sender, prompt.creator, msg.value);
    }

    /// @notice Allows a prompt engineer to claim their accumulated tips.
    /// @dev Can only be called by the prompt's original creator.
    /// @param _promptId The ID of the prompt from which to claim tips.
    function claimPromptTips(uint256 _promptId) external nonReentrant whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "AetherForge: Prompt does not exist");
        require(msg.sender == prompt.creator, "AetherForge: Only the prompt creator can claim tips");
        require(prompt.totalTips > 0, "AetherForge: No tips to claim for this prompt");

        uint256 tipsToClaim = prompt.totalTips;
        prompt.totalTips = 0; // Reset tips after claiming
        payable(msg.sender).transfer(tipsToClaim); // Transfer collected tips to the engineer
    }

    // --- V. Content Creation & Submission Module ---

    /// @notice Submits AI-generated content based on a specific prompt.
    /// @dev Requires `contentSubmissionStake` ETH to be sent with the transaction. A unique content hash is used to prevent duplicate submissions.
    /// @param _promptId The ID of the prompt that guided the AI content generation.
    /// @param _contentURI The URI (e.g., IPFS hash, Arweave ID) pointing to the actual AI-generated content file.
    /// @param _licensingOption The chosen licensing terms for this content (e.g., "CC-BY", "Commercial-Restricted", "PublicDomain").
    /// @param _uniqueContentHash A cryptographic hash of the content to ensure uniqueness and prevent re-submissions.
    function submitAIGeneratedContent(
        uint256 _promptId,
        string memory _contentURI,
        string memory _licensingOption,
        bytes32 _uniqueContentHash
    ) external payable nonReentrant whenNotPaused {
        require(msg.value >= contentSubmissionStake, "AetherForge: Insufficient stake for content submission");
        require(prompts[_promptId].creator != address(0), "AetherForge: Prompt does not exist");
        require(prompts[_promptId].isActive, "AetherForge: Prompt is inactive");
        require(bytes(_contentURI).length > 0, "AetherForge: Content URI cannot be empty");
        require(_uniqueContentHash != bytes32(0), "AetherForge: Unique content hash cannot be zero");

        _submissionIdCounter.increment();
        uint256 newSubmissionId = _submissionIdCounter.current();

        contentSubmissions[newSubmissionId] = ContentSubmission({
            promptId: _promptId,
            creator: msg.sender,
            contentURI: _contentURI,
            licensingOption: _licensingOption,
            uniqueContentHash: _uniqueContentHash,
            submissionTime: block.timestamp,
            aiScore: 0,
            aiFeedbackURI: "",
            aiEvaluated: false,
            totalCuratorScore: 0,
            numCurators: 0,
            finalized: false,
            rejected: false,
            creatorStake: uint252(msg.value), // Store the creator's stake with the submission
            nftTokenId: 0 // Will be set upon successful minting
        });
        emit ContentSubmitted(newSubmissionId, _promptId, msg.sender, _contentURI, _licensingOption);
    }

    /// @notice Requests an AI evaluation for a specific content submission.
    /// @dev This function acts as a signal for the off-chain AI oracle to pick up the submission for analysis.
    ///      Can only be called by the content creator after submission. The AI oracle is expected to call `receiveAIEvaluation` later.
    /// @param _submissionId The ID of the content submission to evaluate.
    function requestAIEvaluation(uint256 _submissionId) external whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(msg.sender == submission.creator, "AetherForge: Only content creator can request AI evaluation");
        require(!submission.aiEvaluated, "AetherForge: Content already AI evaluated");
        // In a real system, this might trigger an off-chain worker or log an event the oracle specifically listens for.
    }

    /// @notice Callback function for the AI Oracle to deliver evaluation results for a content submission.
    /// @dev Only the trusted `aiOracleAddress` can call this function. Updates the AI score and status of the submission.
    /// @param _submissionId The ID of the content submission being evaluated.
    /// @param _aiScore The score provided by the AI (e.g., uniqueness, quality, prompt adherence).
    /// @param _aiFeedbackURI URI to detailed AI feedback or report.
    function receiveAIEvaluation(
        uint256 _submissionId,
        uint256 _aiScore,
        string memory _aiFeedbackURI
    ) external onlyOracle whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(!submission.aiEvaluated, "AetherForge: Content already AI evaluated");

        submission.aiScore = _aiScore;
        submission.aiFeedbackURI = _aiFeedbackURI;
        submission.aiEvaluated = true;

        if (_aiScore < minAIAcceptanceScore) {
            submission.rejected = true;
            creatorReputation[submission.creator] -= 5; // Penalty for low AI score
            pendingRewards[submission.creator] += submission.creatorStake; // Return creator's stake if rejected by AI
            emit ContentFinalized(_submissionId, false, submission.creator); // Emit as finalized (rejected)
        }
        emit AIEvaluationReceived(_submissionId, _aiScore, _aiFeedbackURI);
    }

    /// @notice Finalizes a content submission if it meets both AI and average curator criteria.
    /// @dev Can be called by anyone after AI evaluation and sufficient curation votes are submitted.
    ///      If successful, the content is marked as `finalized` and is ready for NFT minting.
    /// @param _submissionId The ID of the content submission to finalize.
    function finalizeContentSubmission(uint256 _submissionId) external nonReentrant whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(!submission.finalized, "AetherForge: Submission already finalized");
        require(submission.aiEvaluated, "AetherForge: Content has not been AI evaluated yet");
        require(!submission.rejected, "AetherForge: Content was rejected by AI");
        require(submission.aiScore >= minAIAcceptanceScore, "AetherForge: AI score too low");
        require(submission.numCurators >= 3, "AetherForge: Not enough curators have voted (minimum 3)"); // Example threshold

        uint256 avgCuratorScore = 0;
        if (submission.numCurators > 0) {
            avgCuratorScore = submission.totalCuratorScore.div(submission.numCurators);
        }
        require(avgCuratorScore >= minCuratorAcceptanceScore, "AetherForge: Average curator score too low");

        submission.finalized = true;
        creatorReputation[submission.creator] += 10; // Reputation boost for successful finalization
        pendingRewards[submission.creator] += creatorSuccessReward; // Reward the creator
        pendingRewards[submission.creator] += submission.creatorStake; // Return creator's stake

        // Distribute curation rewards to participating curators
        // This is conceptually more complex in Solidity as iterating mappings is hard.
        // A simple approach is to reward all who voted on this submission, or only those who voted "correctly".
        // For simplicity: a fixed reward to the first N curators who voted or those who staked.
        // The current implementation is simpler for the sake of the example.
        // In a production system, a separate data structure or off-chain processing for curator rewards would be needed.

        emit ContentFinalized(_submissionId, true, submission.creator);
    }

    // --- VI. Content Curation & Evaluation Module ---

    /// @notice Allows a user to stake funds to become a curator for a specific content submission.
    /// @dev Requires `curationStakeAmount` ETH. The stake indicates intent to review and serves as a bond.
    /// @param _submissionId The ID of the content submission to curate.
    function stakeForCuration(uint256 _submissionId) external payable nonReentrant whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(!submission.finalized, "AetherForge: Submission already finalized");
        require(!submission.rejected, "AetherForge: Submission rejected, no longer needs curation");
        require(msg.value >= curationStakeAmount, "AetherForge: Insufficient stake for curation");
        require(!submission.hasStakedForCuration[msg.sender], "AetherForge: Already staked for this submission");
        require(msg.sender != submission.creator, "AetherForge: Creator cannot curate their own content");

        submission.hasStakedForCuration[msg.sender] = true;
        // In a full system, the stake would be held by the contract and potentially slashed
        // for malicious activity or returned upon successful, honest curation.
        // For this example, we simply record the intent.
        emit CuratorStaked(_submissionId, msg.sender, msg.value);
    }

    /// @notice Submits a curator's vote and feedback for a content submission.
    /// @dev Only users who have staked for curation on that specific submission can vote.
    /// @param _submissionId The ID of the content submission.
    /// @param _score The curator's score for the content (integer between 1 and 10).
    /// @param _feedbackURI URI to detailed text feedback from the curator.
    function submitCurationVote(
        uint256 _submissionId,
        uint256 _score,
        string memory _feedbackURI
    ) external whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(submission.hasStakedForCuration[msg.sender], "AetherForge: Must stake to curate this submission");
        require(!submission.curatorVotes[msg.sender].hasVoted, "AetherForge: Already voted on this submission");
        require(_score >= 1 && _score <= 10, "AetherForge: Score must be between 1 and 10");
        require(!submission.finalized, "AetherForge: Submission already finalized");
        require(!submission.rejected, "AetherForge: Submission rejected");

        submission.curatorVotes[msg.sender] = CurationVote({
            score: _score,
            feedbackURI: _feedbackURI,
            voteTime: block.timestamp,
            hasVoted: true
        });
        submission.totalCuratorScore += _score;
        submission.numCurators++;

        // A small reputation boost for active participation in curation
        curatorReputation[msg.sender] += 1;
        // Add curator participation reward to pending rewards
        pendingRewards[msg.sender] += curatorParticipationReward;

        emit CurationVoteSubmitted(_submissionId, msg.sender, _score);

        // Attempt to finalize the submission if all conditions are met after a new vote
        // This makes `finalizeContentSubmission` callable by any participant who completes the conditions
        if (submission.aiEvaluated && submission.numCurators >= 3 && submission.aiScore >= minAIAcceptanceScore) {
             uint256 avgCuratorScore = submission.totalCuratorScore.div(submission.numCurators);
             if (avgCuratorScore >= minCuratorAcceptanceScore) {
                 finalizeContentSubmission(_submissionId); // Automatically finalize if criteria met
             }
        }
    }

    /// @notice Allows a content creator to dispute the outcome of a curation, if they believe it was unfair.
    /// @dev Requires `disputeFee` ETH to initiate a dispute. Typically used when content is rejected unfairly.
    /// @param _submissionId The ID of the content submission being disputed.
    function disputeCurationResult(uint256 _submissionId) external payable nonReentrant whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(msg.sender == submission.creator, "AetherForge: Only content creator can dispute");
        require(submission.rejected, "AetherForge: Only rejected submissions can be disputed");
        require(msg.value >= disputeFee, "AetherForge: Insufficient dispute fee");
        // In a more complex system, dispute state would be managed. For now, implies a dispute on rejected state.

        // The dispute fee is held by the contract. It will be used for dispute resolution costs or returned.
        emit CurationDisputed(_submissionId, msg.sender);
    }

    /// @notice Resolves a curation dispute. This is a privileged function, intended to be called by the contract owner
    ///         or potentially a DAO governance module after off-chain review.
    /// @dev Affects creator and curator reputation based on whether the creator's dispute is upheld.
    /// @param _submissionId The ID of the disputed content submission.
    /// @param _creatorWins True if the creator's dispute is upheld (meaning the original rejection was incorrect), false otherwise.
    function resolveCurationDispute(uint256 _submissionId, bool _creatorWins) external onlyOwner nonReentrant {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(submission.rejected, "AetherForge: Submission is not in a disputable (rejected) state");

        if (_creatorWins) {
            submission.rejected = false; // Overturn the rejection
            submission.finalized = true; // Mark as finalized for NFT minting
            creatorReputation[submission.creator] += 20; // Significant reputation boost for successful dispute
            pendingRewards[submission.creator] += creatorSuccessReward; // Reward creator for successful content
            pendingRewards[submission.creator] += submission.creatorStake; // Return creator's stake

            // Penalize curators who voted for rejection, if their vote was incorrect.
            // (Note: Iterating through `mapping(address => CurationVote)` is not directly possible in Solidity.
            // A more advanced design would use an array of curator addresses in the ContentSubmission struct
            // to enable iteration and targeted slashing/penalties for misaligned votes).
            // For simplicity, this part is conceptual or handled off-chain.
        } else {
            // Creator loses dispute
            creatorReputation[submission.creator] -= 5; // Small penalty for losing a dispute
            // Dispute fee (msg.value when disputeCurationResult was called) is now consumed/sent to owner or treasury.
        }
        emit CurationDisputeResolved(_submissionId, _creatorWins, msg.sender);
    }

    // --- VII. Dynamic NFT Management ---

    /// @notice Mints the content as an ERC721 NFT after its successful finalization.
    /// @dev Callable by the content creator once the `finalized` status for their submission is true.
    /// @param _submissionId The ID of the content submission to mint into an NFT.
    function mintContentNFT(uint256 _submissionId) external nonReentrant whenNotPaused {
        ContentSubmission storage submission = contentSubmissions[_submissionId];
        require(submission.creator != address(0), "AetherForge: Submission does not exist");
        require(msg.sender == submission.creator, "AetherForge: Only content creator can mint NFT");
        require(submission.finalized, "AetherForge: Content not finalized for minting");
        require(submission.nftTokenId == 0, "AetherForge: NFT already minted for this submission");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        // Initial metadata URI is the content URI itself, or a dynamically generated one by a service.
        _setTokenURI(newTokenId, submission.contentURI); // ERC721 internal function
        _tokenMetadataURIs[newTokenId] = submission.contentURI; // Store the mutable URI in our custom mapping

        submission.nftTokenId = newTokenId; // Link the submission to its minted NFT
        emit NFTMinted(newTokenId, _submissionId, msg.sender, submission.contentURI);
    }

    /// @notice Allows authorized entities (currently owner, but could be DAO or specific roles) to update an NFT's metadata URI.
    /// @dev This is the core mechanism enabling "dynamic NFTs" in AetherForge. Metadata can evolve based on
    ///      new evaluations, community engagement, popularity, or external data feeds.
    /// @param _tokenId The ID of the NFT whose metadata URI is to be updated.
    /// @param _newMetadataURI The new URI pointing to the updated metadata JSON file.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyOwner whenNotPaused {
        require(_exists(_tokenId), "AetherForge: NFT does not exist");
        _tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Returns the licensing option chosen for a specific NFT during its submission.
    /// @dev To retrieve the license, it iterates through content submissions to find the one linked to the NFT.
    ///      For a large number of submissions/NFTs, a direct mapping from `tokenId` to `submissionId` would be more efficient.
    /// @param _tokenId The ID of the NFT.
    /// @return The licensing string associated with the NFT.
    function getNFTLicense(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "AetherForge: NFT does not exist");
        // This is a basic linear search, which becomes inefficient with many submissions.
        // In a production contract, consider a mapping: `mapping(uint256 => uint256) public tokenIdToSubmissionId;`
        for (uint256 i = 1; i <= _submissionIdCounter.current(); i++) {
            if (contentSubmissions[i].nftTokenId == _tokenId) {
                return contentSubmissions[i].licensingOption;
            }
        }
        revert("AetherForge: NFT licensing not found for this token ID.");
    }

    /// @notice Returns the URI for a given token ID, reflecting its potentially dynamic metadata.
    /// @dev Overrides OpenZeppelin ERC721's `tokenURI` to support mutable metadata stored in `_tokenMetadataURIs` mapping.
    /// @param _tokenId The ID of the token.
    /// @return The current URI pointing to the token's metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenMetadataURIs[_tokenId];
    }

    /// @notice Transfers the ownership of an NFT from one address to another.
    /// @dev This is a wrapper for the standard ERC721 `_transfer` function.
    /// @param from The current owner of the NFT.
    /// @param to The address to transfer the NFT to.
    /// @param tokenId The ID of the NFT to transfer.
    function transferNFT(address from, address to, uint256 tokenId) external virtual {
        // Uses the ERC721's internal _transfer method for safety and standard compliance.
        _transfer(from, to, tokenId);
    }

    // --- VIII. Reputation & Rewards System ---

    /// @notice Retrieves the current reputation score of a content creator.
    /// @param _creator The address of the content creator.
    /// @return The creator's reputation score (an integer).
    function getCreatorReputation(address _creator) external view returns (int256) {
        return creatorReputation[_creator];
    }

    /// @notice Retrieves the current reputation score of a content curator.
    /// @param _curator The address of the content curator.
    /// @return The curator's reputation score (an integer).
    function getCuratorReputation(address _curator) external view returns (int256) {
        return curatorReputation[_curator];
    }

    /// @notice Retrieves the current reputation score of a prompt engineer.
    /// @param _promptEngineer The address of the prompt engineer.
    /// @return The prompt engineer's reputation score (an integer).
    function getPromptEngineerReputation(address _promptEngineer) external view returns (int256) {
        return promptEngineerReputation[_promptEngineer];
    }

    /// @notice Allows a user to claim their accumulated pending rewards.
    /// @dev Rewards can include returned stakes for rejected content, successful content creation bonuses, and curation rewards.
    function claimRewards() external nonReentrant {
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "AetherForge: No rewards to claim");
        pendingRewards[msg.sender] = 0; // Reset pending rewards to zero
        payable(msg.sender).transfer(rewards); // Transfer ETH rewards to the claimant
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Allows the owner (or eventually a DAO) to trigger reputation decay for all participants.
    /// @dev This conceptual function prevents reputation scores from perpetually increasing and encourages
    ///      continued active and positive participation. Due to Solidity's limitations on iterating mappings,
    ///      a full implementation of global decay would require an off-chain process with proofs, or a
    ///      different on-chain data structure (e.g., linked list of participants) or requiring users to
    ///      update their own score periodically. For this example, it's a symbolic trigger.
    function triggerReputationDecay() external onlyOwner {
        require(block.timestamp >= lastReputationDecayTime + reputationDecayInterval, "AetherForge: Not time for reputation decay yet");

        // --- CONCEPTUAL IMPLEMENTATION ---
        // As direct iteration over all mapping keys is not possible in Solidity, a true global decay
        // for all users would typically involve:
        // 1. Maintaining an enumerable set of all participants.
        // 2. An off-chain process calculating decay and submitting a batched update or Merkle proof.
        // 3. A "pull" model where users call a function to decay their own score if it hasn't been updated recently.
        //
        // This function primarily marks the time of decay and emits an event for off-chain systems.
        // Example for a single user (would be adapted for all active users):
        // int256 decayFactor = 9; // Retain 90% of reputation, 10% decay
        // creatorReputation[someUser] = creatorReputation[someUser].mul(decayFactor).div(10);
        // curatorReputation[someUser] = curatorReputation[someUser].mul(decayFactor).div(10);
        // promptEngineerReputation[someUser] = promptEngineerReputation[someUser].mul(decayFactor).div(10);
        // ---------------------------------

        lastReputationDecayTime = block.timestamp;
        emit ReputationDecayed(block.timestamp);
    }

    // --- IX. Utility Functions ---

    /// @notice Allows a user to withdraw their general participation stake.
    /// @dev This function assumes a mechanism for users to deposit general participation stakes.
    ///      (While not directly used in the current core flows, it's a common utility for platforms).
    /// @param _amount The amount of ETH to withdraw from the general stake.
    function withdrawStakedFunds(uint256 _amount) external nonReentrant {
        require(generalParticipationStake[msg.sender] >= _amount, "AetherForge: Insufficient staked funds");
        generalParticipationStake[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    /// @notice Returns the total number of NFTs minted by the contract.
    /// @return The total supply of NFTs, reflecting the number of finalized and tokenized content pieces.
    function getTotalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Fallback function to allow the contract to receive plain ETH transfers.
    /// @dev ETH sent without specifying a function will be handled by this, or `receive()` if no data.
    receive() external payable {}
    fallback() external payable {}
}
```