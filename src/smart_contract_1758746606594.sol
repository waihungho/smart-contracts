```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Mock AI Oracle Interface (could be a more complex system like Chainlink AI Oracle)
interface IAIOracle {
    // This function would typically trigger an off-chain computation and callback.
    // The requestId helps link the external request to the internal state.
    // targetContract is the address where the fulfillment callback should be sent.
    // data is the specific input for the AI model.
    function requestAssessment(uint256 requestId, address targetContract, bytes calldata data) external returns (bytes32 jobId);
    // fulfillAssessment would be called by the oracle network after computation.
    // It's conceptually an external call, but the contract allows only authorized operators to simulate it.
    function fulfillAssessment(bytes32 jobId, bytes calldata result) external; 
}

// Mock Governance Token Interface (e.g., STUDIO token)
interface IGovernanceToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool); // Added for clarity
}


/**
 * @title AetherForge
 * @dev A Decentralized AI-Augmented Creative Studio for evolving dynamic NFTs (Aether Artifacts).
 *      This contract enables users to submit creative prompts, mint dynamic NFTs,
 *      which evolve based on AI assessments and community governance. It incorporates
 *      AI oracle integration, a reputation system, and advanced governance features.
 *
 * @notice This contract is designed for conceptual exploration of advanced Web3 patterns.
 *         It combines elements of dynamic NFTs, AI oracle integration, reputation systems,
 *         and nuanced governance. Some external components (like a real AI Oracle or a robust
 *         governance token) are represented by interfaces or simplified logic for focus.
 *         For production use, robust error handling, gas optimizations, and comprehensive
 *         security audits would be essential.
 */
contract AetherForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline & Function Summary ---

    // I. Core Infrastructure & Access Control (7 functions)
    // 1.  constructor(string memory name, string memory symbol, address initialOwner, address governanceTokenAddress_)
    //        Initializes the contract, ERC721, Ownable, Pausable. Sets governance token and initial parameters.
    // 2.  updateOracleAddress(address newOracleAddress_)
    //        Updates the address of the AI Oracle contract. Only callable by owner.
    // 3.  updateOperator(address operator, bool isAIOracle, bool isGovCouncil)
    //        Manages roles for AI oracles and governance council members. Only callable by owner.
    // 4.  pause()
    //        Pauses all mutable functions of the contract, callable by owner.
    // 5.  unpause()
    //        Unpauses the contract, callable by owner.
    // 6.  emergencyWithdrawERC20(address tokenAddress, uint256 amount)
    //        Allows owner to withdraw accidentally sent ERC20 tokens.
    // 7.  withdrawETH(uint256 amount)
    //        Allows owner to withdraw ETH from the contract.

    // II. AI Oracle & Feedback System (3 functions)
    // 8.  requestAIAssessment(uint256 artifactId, bytes calldata promptData)
    //        Requests an AI assessment for an Aether Artifact or a raw creative prompt, requires ETH fee.
    // 9.  reportAIAssessment(bytes32 jobId, uint256 artifactId, uint256 score, string calldata feedbackHash, bool success)
    //        AI Oracle reports the assessment result. Triggers potential artifact evolution logic internally.
    // 10. updateAIAssessmentFee(uint256 newFee)
    //        Sets the fee required to request an AI assessment. Callable by owner.

    // III. Dynamic NFT (dNFT) Management - "Aether Artifacts" (6 functions)
    // 11. mintAetherArtifact(string calldata initialMetadataURI, bytes calldata initialPromptData)
    //        Mints a new Aether Artifact NFT with initial metadata and prompt data.
    // 12. updateArtifactMetadata(uint256 artifactId, string calldata newMetadataURI)
    //        Allows owner of dNFT to propose or update metadata (simplified, actual system would require approval).
    // 13. evolveArtifactState(uint256 artifactId, bytes calldata evolutionPayload)
    //        Triggers an artifact's evolution based on AI assessment score and cooldown period.
    // 14. claimEvolutionRewards(uint256 artifactId)
    //        Allows the original minter/contributor to claim rewards for successful artifact evolution.
    // 15. burnAetherArtifact(uint256 artifactId)
    //        Allows the owner to burn their Aether Artifact.
    // 16. setEvolutionCriteria(uint256 minAIScore, uint256 minUpvotes, uint256 timeLockSeconds)
    //        Sets the on-chain criteria for artifact evolution and prompt selection. Callable by Gov Council.

    // IV. Creative Prompt & Project Submission (4 functions)
    // 17. submitCreativePrompt(string calldata promptURI, uint256 rewardShareBasisPoints)
    //        Users submit a creative idea/prompt for community/AI consideration.
    // 18. upvoteCreativePrompt(uint256 promptId)
    //        Community members upvote prompts using governance tokens, increasing its funding/visibility.
    // 19. selectPromptForDevelopment(uint256 promptId)
    //        Governance council/AI selects a prompt to be developed into an artifact, based on criteria.
    // 20. fundCreativeProject(uint256 promptId)
    //        Allows users to contribute ETH to fund a selected creative prompt's development.

    // V. Reputation & Rewards (3 functions)
    // 21. updateContributorReputation(address contributor, uint256 amount, bool isPositive)
    //        Updates a contributor's reputation score based on actions. Callable by Gov Council.
    // 22. claimReputationReward(uint256 reputationTier)
    //        Allows high-reputation contributors to claim specific rewards (e.g., ETH) for reaching a tier.
    // 23. setReputationThresholds(uint256[] calldata newThresholds, uint256[] calldata newRewardAmounts)
    //        Defines the score thresholds for different reputation tiers and their associated ETH rewards. Callable by Gov Council.

    // VI. Advanced Concepts & Utility (6 functions)
    // 24. delegateAIVotingPower(address delegatee)
    //        Users can delegate their AI-influence (based on reputation/stake) to another address.
    // 25. proposeAIGovernanceAction(string calldata description, bytes calldata callData, address target)
    //        Users can propose governance actions related to AI parameters or contract upgrades.
    // 26. castAIGovernanceVote(uint256 proposalId, bool support)
    //        Users cast a vote on an active AI governance proposal, weighted by their AI affinity (reputation + token).
    // 27. executeAIGovernanceProposal(uint256 proposalId)
    //        Executes a passed AI governance proposal if voting period ended and it met conditions.
    // 28. snapshotAIAffinity(address user)
    //        Calculates and returns a user's "AI affinity" score, useful for weighted voting.
    // 29. tokenURI(uint256 tokenId)
    //        Overrides ERC721 tokenURI to return the current metadata URI for an artifact.

    // --- State Variables ---

    IAIOracle public aiOracle;
    IGovernanceToken public STUDIO_TOKEN; // The governance token for voting, staking, and fees.

    Counters.Counter private _artifactIds;
    Counters.Counter private _promptIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _assessmentRequestIds;

    uint256 public aiAssessmentFee; // Fee in ETH for requesting AI assessment
    uint256 public constant MAX_REWARD_SHARE_BPS = 10000; // 100% in basis points

    // Struct for Aether Artifacts (Dynamic NFTs)
    struct AetherArtifact {
        string metadataURI;
        address minterAddress; // Address of the NFT minter
        uint256 currentAIScore; // Current AI score, influences evolution
        uint256 lastEvolutionTime; // Timestamp of the last successful evolution
        bytes lastEvolutionPayload; // Data associated with the last evolution trigger
        bool hasPendingEvolutionReward; // True if a reward is due for the last evolution
    }
    mapping(uint256 => AetherArtifact) public artifacts;

    // Struct for Creative Prompts
    struct CreativePrompt {
        string promptURI;
        address submitter;
        uint256 upvotes; // Weighted upvotes (e.g., in STUDIO tokens)
        uint256 fundingAmount; // In ETH
        bool isSelected; // If selected for development into an artifact
        uint256 rewardShareBasisPoints; // Basis points of future revenue for prompt submitter
    }
    mapping(uint256 => CreativePrompt) public creativePrompts;

    // Struct for AI Assessment Requests
    struct AIAssessmentRequest {
        uint256 artifactId; // 0 if for a raw prompt, otherwise artifact ID
        address requester;
        bytes32 jobId; // ID provided by the AI Oracle
        uint256 requestTime;
        bool fulfilled;
    }
    mapping(uint256 => AIAssessmentRequest) public aiAssessmentRequests; // requestId => request details
    mapping(bytes32 => uint256) public jobIdToRequestId; // For linking fulfillment to request

    // Struct for Contributor Reputation
    mapping(address => uint256) public contributorReputation;
    uint256[] public reputationThresholds; // e.g., [100, 500, 1000] reputation points
    uint256[] public reputationRewardAmounts; // e.g., [0.01e18, 0.05e18, 0.1e18] ETH rewards
    mapping(address => mapping(uint256 => bool)) public hasClaimedReputationReward; // user => tier => claimed

    // Struct for AI Governance Proposals
    struct AIGovernanceProposal {
        string description;
        address target; // Target contract for execution
        bytes callData; // Encoded function call data
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => AIGovernanceProposal) public aiGovernanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnAIGov; // proposalId => voter => voted

    // AI Affinity Delegation
    mapping(address => address) public delegatedAIVotingPower; // delegator => delegatee

    // Evolution Criteria
    uint256 public minAIScoreForEvolution;
    uint256 public minUpvotesForSelection; // In STUDIO tokens, for selecting prompts
    uint256 public evolutionCooldownSeconds; // Cooldown for artifact evolution

    // Access Control Roles
    mapping(address => bool) public isAIOracleOperator;
    mapping(address => bool) public isGovCouncilMember;

    // --- Events ---
    event OracleAddressUpdated(address indexed newAddress);
    event OperatorRoleUpdated(address indexed operator, bool isAIOracle, bool isGovCouncil);
    event AIAssessmentRequested(uint256 indexed requestId, uint256 indexed artifactId, address indexed requester, bytes32 jobId);
    event AIAssessmentReported(bytes32 indexed jobId, uint256 indexed artifactId, uint256 score, string feedbackHash, bool success);
    event AIAssessmentFeeUpdated(uint256 newFee);
    event ArtifactMinted(uint256 indexed artifactId, address indexed minter, string metadataURI);
    event ArtifactMetadataUpdated(uint256 indexed artifactId, string newMetadataURI);
    event ArtifactEvolved(uint256 indexed artifactId, uint256 newAIScore, bytes evolutionPayload);
    event EvolutionRewardsClaimed(uint256 indexed artifactId, address indexed claimant, uint256 amount);
    event ArtifactBurned(uint256 indexed artifactId, address indexed burner);
    event EvolutionCriteriaSet(uint256 minAIScore, uint256 minUpvotes, uint256 cooldown);
    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string promptURI, uint256 rewardShareBPS);
    event PromptUpvoted(uint256 indexed promptId, address indexed voter, uint256 amount);
    event PromptSelectedForDevelopment(uint256 indexed promptId, address indexed selector);
    event CreativeProjectFunded(uint256 indexed promptId, address indexed funder, uint256 amount);
    event ReputationUpdated(address indexed contributor, uint256 newReputation);
    event ReputationRewardClaimed(address indexed claimant, uint256 tier, uint256 amount);
    event ReputationThresholdsSet(uint256[] thresholds, uint256[] rewardAmounts);
    event AIVotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event AIGovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event AIGovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event AIGovernanceProposalExecuted(uint256 indexed proposalId);


    // --- Modifiers ---
    modifier onlyAIOracleOperator() {
        require(isAIOracleOperator[msg.sender], "AetherForge: Only AI Oracle operator");
        _;
    }

    modifier onlyGovCouncilMember() {
        require(isGovCouncilMember[msg.sender], "AetherForge: Only Governance Council member");
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Initializes the contract. Sets the ERC721 name and symbol,
     *      initializes Pausable, Ownable, and sets up the governance token.
     * @param name_ ERC721 token name.
     * @param symbol_ ERC721 token symbol.
     * @param initialOwner_ The initial owner of the contract.
     * @param governanceTokenAddress_ Address of the governance (STUDIO) token.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_,
        address governanceTokenAddress_
    ) ERC721(name_, symbol_) Ownable(initialOwner_) {
        STUDIO_TOKEN = IGovernanceToken(governanceTokenAddress_);
        aiAssessmentFee = 0.001 ether; // Initial fee for AI assessment (0.001 ETH)
        minAIScoreForEvolution = 70; // Initial AI score (out of 100) for evolution eligibility
        minUpvotesForSelection = 1000 ether; // Initial upvotes (in STUDIO tokens) for prompt selection
        evolutionCooldownSeconds = 1 days; // Initial cooldown period between artifact evolutions

        // Initialize reputation thresholds and rewards (example ETH rewards)
        reputationThresholds = [100, 500, 1000];
        reputationRewardAmounts = [0.01 ether, 0.05 ether, 0.1 ether]; // Example ETH rewards
    }

    /**
     * @dev Updates the address of the AI Oracle contract.
     *      Only callable by the contract owner.
     * @param newOracleAddress_ The new address for the AI Oracle.
     */
    function updateOracleAddress(address newOracleAddress_) external onlyOwner {
        require(newOracleAddress_ != address(0), "AetherForge: Invalid oracle address");
        aiOracle = IAIOracle(newOracleAddress_);
        emit OracleAddressUpdated(newOracleAddress_);
    }

    /**
     * @dev Manages roles for AI oracles and governance council members.
     *      Only callable by the contract owner.
     * @param operator The address to grant/revoke role.
     * @param isAIOracle True to grant/False to revoke AI Oracle operator role.
     * @param isGovCouncil True to grant/False to revoke Governance Council member role.
     */
    function updateOperator(address operator, bool isAIOracle, bool isGovCouncil) external onlyOwner {
        require(operator != address(0), "AetherForge: Invalid operator address");
        isAIOracleOperator[operator] = isAIOracle;
        isGovCouncilMember[operator] = isGovCouncil;
        emit OperatorRoleUpdated(operator, isAIOracle, isGovCouncil);
    }

    /**
     * @dev Pauses all mutable functions of the contract.
     *      Callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ERC20 tokens.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(IERC20(tokenAddress).transfer(owner(), amount), "AetherForge: ERC20 withdrawal failed");
    }

    /**
     * @dev Allows the owner to withdraw ETH from the contract.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "AetherForge: Insufficient contract ETH balance");
        payable(owner()).transfer(amount);
    }

    // --- II. AI Oracle & Feedback System ---

    /**
     * @dev Requests an AI assessment for an Aether Artifact or a raw creative prompt.
     *      Requires a fee paid in ETH.
     * @param artifactId The ID of the Aether Artifact (0 if for a raw prompt).
     * @param promptData Arbitrary data representing the prompt/artifact for AI assessment.
     */
    function requestAIAssessment(uint256 artifactId, bytes calldata promptData) external payable whenNotPaused {
        require(address(aiOracle) != address(0), "AetherForge: AI Oracle not set");
        require(msg.value >= aiAssessmentFee, "AetherForge: Insufficient ETH for assessment fee");
        if (artifactId != 0) {
            require(_exists(artifactId), "AetherForge: Artifact does not exist");
            require(_isApprovedOrOwner(msg.sender, artifactId), "AetherForge: Not artifact owner or approved for assessment");
        }

        _assessmentRequestIds.increment();
        uint256 requestId = _assessmentRequestIds.current();

        bytes32 jobId = aiOracle.requestAssessment(requestId, address(this), promptData);

        aiAssessmentRequests[requestId] = AIAssessmentRequest({
            artifactId: artifactId,
            requester: msg.sender,
            jobId: jobId,
            requestTime: block.timestamp,
            fulfilled: false
        });
        jobIdToRequestId[jobId] = requestId;

        emit AIAssessmentRequested(requestId, artifactId, msg.sender, jobId);
    }

    /**
     * @dev AI Oracle reports the assessment result.
     *      Only callable by an authorized AI Oracle operator.
     * @param jobId The job ID provided by the AI Oracle during request.
     * @param artifactId The ID of the Aether Artifact (0 if for a raw prompt).
     * @param score The AI-generated score for the artifact/prompt (e.g., 0-100).
     * @param feedbackHash A hash of the detailed AI feedback (stored off-chain).
     * @param success True if the assessment was successful, false otherwise.
     */
    function reportAIAssessment(
        bytes32 jobId,
        uint256 artifactId,
        uint256 score,
        string calldata feedbackHash,
        bool success
    ) external onlyAIOracleOperator whenNotPaused {
        uint256 requestId = jobIdToRequestId[jobId];
        require(requestId != 0, "AetherForge: Invalid job ID or request not found");
        AIAssessmentRequest storage req = aiAssessmentRequests[requestId];
        require(!req.fulfilled, "AetherForge: Assessment already fulfilled");

        req.fulfilled = true;

        if (success) {
            // Update artifact's AI score if it's an artifact assessment
            if (artifactId != 0) {
                require(_exists(artifactId), "AetherForge: Target artifact for assessment does not exist");
                artifacts[artifactId].currentAIScore = score;
            }
            // Logic for triggering evolution could be here, or a separate call.
            // For now, we update score and evolution is triggered manually via `evolveArtifactState`.
        }

        emit AIAssessmentReported(jobId, artifactId, score, feedbackHash, success);
    }

    /**
     * @dev Sets the fee required to request an AI assessment.
     *      Callable by the contract owner.
     * @param newFee The new fee amount in ETH.
     */
    function updateAIAssessmentFee(uint256 newFee) external onlyOwner {
        aiAssessmentFee = newFee;
        emit AIAssessmentFeeUpdated(newFee);
    }

    // --- III. Dynamic NFT (dNFT) Management - "Aether Artifacts" ---

    /**
     * @dev Mints a new Aether Artifact NFT.
     *      The minter becomes the owner and the initial contributor.
     * @param initialMetadataURI IPFS/Arweave URI for the initial NFT metadata.
     * @param initialPromptData Arbitrary data representing the initial creative prompt/seed.
     */
    function mintAetherArtifact(string calldata initialMetadataURI, bytes calldata initialPromptData) external whenNotPaused {
        _artifactIds.increment();
        uint256 newArtifactId = _artifactIds.current();

        _safeMint(msg.sender, newArtifactId);

        artifacts[newArtifactId] = AetherArtifact({
            metadataURI: initialMetadataURI,
            minterAddress: msg.sender,
            currentAIScore: 0, // Starts at 0, needs AI assessment to gain score
            lastEvolutionTime: block.timestamp,
            lastEvolutionPayload: initialPromptData,
            hasPendingEvolutionReward: false
        });

        emit ArtifactMinted(newArtifactId, msg.sender, initialMetadataURI);
    }

    /**
     * @dev Proposes an update to an artifact's metadata.
     *      Callable by the artifact owner. In a more complex system, this might initiate a governance
     *      vote or require a new AI assessment for approval. For simplicity, it updates directly here.
     * @param artifactId The ID of the artifact to update.
     * @param newMetadataURI The new IPFS/Arweave URI for the metadata.
     */
    function updateArtifactMetadata(uint256 artifactId, string calldata newMetadataURI) external whenNotPaused {
        require(_exists(artifactId), "AetherForge: Artifact does not exist");
        require(_isApprovedOrOwner(msg.sender, artifactId), "AetherForge: Not artifact owner or approved");

        artifacts[artifactId].metadataURI = newMetadataURI;

        emit ArtifactMetadataUpdated(artifactId, newMetadataURI);
    }

    /**
     * @dev Triggers an artifact's evolution based on AI assessment and other criteria.
     *      This function encapsulates the core dNFT logic.
     *      Requires the artifact to meet certain AI scores and respect a cooldown period.
     * @param artifactId The ID of the artifact to evolve.
     * @param evolutionPayload Arbitrary data representing the new state or evolution trigger.
     */
    function evolveArtifactState(uint256 artifactId, bytes calldata evolutionPayload) external whenNotPaused {
        require(_exists(artifactId), "AetherForge: Artifact does not exist");
        AetherArtifact storage artifact = artifacts[artifactId];
        require(_isApprovedOrOwner(msg.sender, artifactId), "AetherForge: Not artifact owner or approved to evolve");

        // Check evolution criteria
        require(artifact.currentAIScore >= minAIScoreForEvolution, "AetherForge: AI score too low for evolution");
        require(block.timestamp >= artifact.lastEvolutionTime + evolutionCooldownSeconds, "AetherForge: Evolution cooldown not over");
        require(!artifact.hasPendingEvolutionReward, "AetherForge: Previous evolution reward not claimed");


        // Perform evolution logic (e.g., update metadata based on new hash or AI output)
        // A real system would have richer logic here, possibly generating a new `metadataURI`
        // based on the `evolutionPayload` and AI score.
        // For simplicity, we update the metadata URI with a conceptual new version.
        artifact.metadataURI = string(abi.encodePacked("ipfs://evolving_metadata_for_artifact_", artifactId.toString(), "_at_Evo-", block.timestamp.toString()));
        artifact.lastEvolutionTime = block.timestamp;
        artifact.lastEvolutionPayload = evolutionPayload;
        artifact.currentAIScore = 0; // Reset AI score for next assessment cycle
        artifact.hasPendingEvolutionReward = true; // Mark reward as pending

        emit ArtifactEvolved(artifactId, artifact.currentAIScore, evolutionPayload);
    }

    /**
     * @dev Allows the original minter/contributor to claim rewards for successful artifact evolution.
     *      Rewards could be in STUDIO tokens, ETH, or other forms.
     * @param artifactId The ID of the artifact for which to claim rewards.
     */
    function claimEvolutionRewards(uint256 artifactId) external whenNotPaused {
        require(_exists(artifactId), "AetherForge: Artifact does not exist");
        AetherArtifact storage artifact = artifacts[artifactId];
        require(msg.sender == artifact.minterAddress, "AetherForge: Only minter can claim evolution rewards");
        require(artifact.hasPendingEvolutionReward, "AetherForge: No pending evolution reward for this artifact");

        // Reward calculation logic (example: fixed ETH reward per evolution)
        uint256 rewardAmount = 0.005 ether; // Example ETH reward

        require(address(this).balance >= rewardAmount, "AetherForge: Insufficient contract balance for rewards");
        payable(msg.sender).transfer(rewardAmount);

        artifact.hasPendingEvolutionReward = false; // Mark reward as claimed

        emit EvolutionRewardsClaimed(artifactId, msg.sender, rewardAmount);
    }

    /**
     * @dev Allows the owner to burn their Aether Artifact.
     *      Useful for disposing of failed experiments or unwanted assets.
     * @param artifactId The ID of the artifact to burn.
     */
    function burnAetherArtifact(uint256 artifactId) external whenNotPaused {
        require(_exists(artifactId), "AetherForge: Artifact does not exist");
        require(_isApprovedOrOwner(msg.sender, artifactId), "AetherForge: Not artifact owner or approved");

        _burn(artifactId);
        delete artifacts[artifactId]; // Clear storage for the artifact

        emit ArtifactBurned(artifactId, msg.sender);
    }

    /**
     * @dev Sets the on-chain criteria for artifact evolution and prompt selection.
     *      Callable by the Governance Council or owner.
     * @param minAIScore The minimum AI score required for an artifact to be eligible for evolution.
     * @param minUpvotes The minimum cumulative upvotes (in STUDIO token value) a prompt needs for selection.
     * @param timeLockSeconds The minimum cooldown period between evolutions in seconds.
     */
    function setEvolutionCriteria(
        uint256 minAIScore,
        uint256 minUpvotes,
        uint256 timeLockSeconds
    ) external onlyGovCouncilMember whenNotPaused {
        minAIScoreForEvolution = minAIScore;
        minUpvotesForSelection = minUpvotes;
        evolutionCooldownSeconds = timeLockSeconds;

        emit EvolutionCriteriaSet(minAIScore, minUpvotes, timeLockSeconds);
    }

    // --- IV. Creative Prompt & Project Submission ---

    /**
     * @dev Users submit a creative idea/prompt for the community/AI to consider.
     * @param promptURI IPFS/Arweave URI pointing to the detailed prompt description.
     * @param rewardShareBasisPoints The percentage of future revenue (in basis points) the submitter requests.
     */
    function submitCreativePrompt(string calldata promptURI, uint256 rewardShareBasisPoints) external whenNotPaused {
        require(rewardShareBasisPoints <= MAX_REWARD_SHARE_BPS, "AetherForge: Reward share too high");

        _promptIds.increment();
        uint256 newPromptId = _promptIds.current();

        creativePrompts[newPromptId] = CreativePrompt({
            promptURI: promptURI,
            submitter: msg.sender,
            upvotes: 0,
            fundingAmount: 0,
            isSelected: false,
            rewardShareBasisPoints: rewardShareBasisPoints
        });

        emit PromptSubmitted(newPromptId, msg.sender, promptURI, rewardShareBasisPoints);
    }

    /**
     * @dev Community members can upvote submitted prompts using governance tokens.
     *      The amount of STUDIO tokens transferred represents the weight of the upvote.
     *      Requires the caller to have approved this contract to spend their STUDIO tokens.
     * @param promptId The ID of the prompt to upvote.
     */
    function upvoteCreativePrompt(uint256 promptId) external whenNotPaused {
        require(creativePrompts[promptId].submitter != address(0), "AetherForge: Prompt does not exist");
        require(msg.sender != creativePrompts[promptId].submitter, "AetherForge: Cannot upvote your own prompt");

        // Example: a fixed amount of 1 STUDIO token per upvote, or dynamic.
        // For actual transfer, user must have called STUDIO_TOKEN.approve(address(this), amount) prior.
        uint256 upvoteAmount = 1 ether; // Assuming 1 STUDIO token = 1e18, adjust as needed

        require(STUDIO_TOKEN.transferFrom(msg.sender, address(this), upvoteAmount), "AetherForge: STUDIO token transfer failed for upvote");

        creativePrompts[promptId].upvotes += upvoteAmount; // Upvotes are weighted by token amount
        emit PromptUpvoted(promptId, msg.sender, upvoteAmount);
    }

    /**
     * @dev Governance council/AI selects a prompt to be developed into an artifact.
     * @param promptId The ID of the prompt to select.
     */
    function selectPromptForDevelopment(uint256 promptId) external onlyGovCouncilMember whenNotPaused {
        require(creativePrompts[promptId].submitter != address(0), "AetherForge: Prompt does not exist");
        require(!creativePrompts[promptId].isSelected, "AetherForge: Prompt already selected");
        require(creativePrompts[promptId].upvotes >= minUpvotesForSelection, "AetherForge: Prompt has insufficient upvotes for selection");

        creativePrompts[promptId].isSelected = true;
        // Optionally, mint an initial artifact here or trigger funding
        emit PromptSelectedForDevelopment(promptId, msg.sender);
    }

    /**
     * @dev Allows users to contribute ETH to fund a selected creative prompt's development.
     * @param promptId The ID of the prompt to fund.
     */
    function fundCreativeProject(uint256 promptId) external payable whenNotPaused {
        require(creativePrompts[promptId].submitter != address(0), "AetherForge: Prompt does not exist");
        require(creativePrompts[promptId].isSelected, "AetherForge: Prompt not selected for development");
        require(msg.value > 0, "AetherForge: Must send ETH to fund project");

        creativePrompts[promptId].fundingAmount += msg.value;
        emit CreativeProjectFunded(promptId, msg.sender, msg.value);
    }

    // --- V. Reputation & Rewards ---

    /**
     * @dev Updates a contributor's reputation score.
     *      Callable by Governance Council (e.g., for moderating quality, rewarding specific actions).
     * @param contributor The address of the contributor.
     * @param amount The amount to add/subtract from reputation.
     * @param isPositive True for positive, false for negative reputation change.
     */
    function updateContributorReputation(address contributor, uint256 amount, bool isPositive) external onlyGovCouncilMember whenNotPaused {
        require(contributor != address(0), "AetherForge: Invalid contributor address");

        if (isPositive) {
            contributorReputation[contributor] += amount;
        } else {
            if (contributorReputation[contributor] < amount) {
                contributorReputation[contributor] = 0;
            } else {
                contributorReputation[contributor] -= amount;
            }
        }
        emit ReputationUpdated(contributor, contributorReputation[contributor]);
    }

    /**
     * @dev Allows high-reputation contributors to claim specific rewards based on their tier.
     *      This assumes a one-time claim per tier, tracked by `hasClaimedReputationReward`.
     * @param reputationTier The tier index (0-based) for which to claim rewards.
     */
    function claimReputationReward(uint256 reputationTier) external whenNotPaused {
        require(reputationTier < reputationThresholds.length, "AetherForge: Invalid reputation tier");
        require(contributorReputation[msg.sender] >= reputationThresholds[reputationTier], "AetherForge: Insufficient reputation for this tier");
        require(!hasClaimedReputationReward[msg.sender][reputationTier], "AetherForge: Reward for this tier already claimed");

        uint256 rewardAmount = reputationRewardAmounts[reputationTier];
        require(address(this).balance >= rewardAmount, "AetherForge: Insufficient contract balance for reward");
        
        hasClaimedReputationReward[msg.sender][reputationTier] = true;
        payable(msg.sender).transfer(rewardAmount);

        emit ReputationRewardClaimed(msg.sender, reputationTier, rewardAmount);
    }

    /**
     * @dev Defines the score thresholds for different reputation tiers and their associated ETH rewards.
     *      Arrays must be of the same length and sorted by threshold.
     *      Callable by Governance Council or owner.
     * @param newThresholds An array of reputation score thresholds.
     * @param newRewardAmounts An array of ETH reward amounts corresponding to each tier.
     */
    function setReputationThresholds(uint256[] calldata newThresholds, uint256[] calldata newRewardAmounts) external onlyGovCouncilMember {
        require(newThresholds.length == newRewardAmounts.length, "AetherForge: Thresholds and rewards length mismatch");
        for (uint i = 0; i < newThresholds.length; i++) {
            if (i > 0) {
                require(newThresholds[i] > newThresholds[i-1], "AetherForge: Thresholds must be strictly increasing");
            }
        }
        reputationThresholds = newThresholds;
        reputationRewardAmounts = newRewardAmounts;

        emit ReputationThresholdsSet(newThresholds, newRewardAmounts);
    }

    // --- VI. Advanced Concepts & Utility ---

    /**
     * @dev Users can delegate their AI-influence (based on reputation/stake) to another address.
     *      This delegatee can then vote on AI governance proposals on behalf of the delegator.
     * @param delegatee The address to which to delegate voting power. Set to address(0) to undelegate.
     */
    function delegateAIVotingPower(address delegatee) external whenNotPaused {
        require(delegatee != msg.sender, "AetherForge: Cannot delegate to self");

        delegatedAIVotingPower[msg.sender] = delegatee;
        emit AIVotingPowerDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Users can propose governance actions related to AI parameters or contract upgrades.
     *      Requires a certain reputation or token stake to propose.
     * @param description A brief description of the proposal.
     * @param callData The encoded function call data for execution if the proposal passes.
     * @param target The target contract address for the callData.
     */
    function proposeAIGovernanceAction(string calldata description, bytes calldata callData, address target) external whenNotPaused {
        // Require a minimum reputation or staked tokens to create a proposal
        require(contributorReputation[msg.sender] >= reputationThresholds[0], "AetherForge: Insufficient reputation to propose");
        // Or require a minimum STUDIO_TOKEN balance:
        // require(STUDIO_TOKEN.balanceOf(msg.sender) >= minProposalStake, "AetherForge: Insufficient token stake to propose");
        require(target != address(0), "AetherForge: Target address cannot be zero");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        aiGovernanceProposals[proposalId] = AIGovernanceProposal({
            description: description,
            target: target,
            callData: callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 3 days, // 3-day voting period example
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            cancelled: false
        });

        emit AIGovernanceProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Users cast a vote on an active AI governance proposal, weighted by their AI affinity.
     *      AI affinity is based on reputation and delegated power.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function castAIGovernanceVote(uint256 proposalId, bool support) external whenNotPaused {
        AIGovernanceProposal storage proposal = aiGovernanceProposals[proposalId];
        require(proposal.target != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "AetherForge: Voting not active or has ended");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(!proposal.cancelled, "AetherForge: Proposal cancelled");

        address voter = msg.sender;
        // Resolve delegated voting power: if msg.sender has delegated, use their delegatee.
        // If msg.sender is a delegatee, their actual voting power comes from their own plus those delegated to them.
        // For simplicity, we directly use msg.sender and if msg.sender had delegated their power,
        // they wouldn't directly vote. The delegatee would vote on their behalf.
        // A more complex system would aggregate delegated power for a delegatee.
        address actualVotingAddress = delegatedAIVotingPower[msg.sender] != address(0) ? delegatedAIVotingPower[msg.sender] : msg.sender;
        
        require(!hasVotedOnAIGov[proposalId][actualVotingAddress], "AetherForge: Already voted on this proposal");

        // Calculate vote weight based on AI Affinity (reputation + token balance)
        // Divide token balance by 1e18 to get whole token count if it has 18 decimals
        uint256 voteWeight = contributorReputation[actualVotingAddress] + (STUDIO_TOKEN.balanceOf(actualVotingAddress) / (1 ether));

        require(voteWeight > 0, "AetherForge: No voting power. Increase reputation or acquire STUDIO tokens.");

        if (support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }

        hasVotedOnAIGov[proposalId][actualVotingAddress] = true;
        emit AIGovernanceVoteCast(proposalId, actualVotingAddress, support, voteWeight);
    }

    /**
     * @dev Executes a passed AI governance proposal.
     *      Callable by anyone after the voting period ends and if the proposal has enough votes.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeAIGovernanceProposal(uint256 proposalId) external whenNotPaused {
        AIGovernanceProposal storage proposal = aiGovernanceProposals[proposalId];
        require(proposal.target != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "AetherForge: Voting period not ended");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(!proposal.cancelled, "AetherForge: Proposal cancelled");

        // Simple majority rule for execution
        require(proposal.forVotes > proposal.againstVotes, "AetherForge: Proposal did not pass");
        // Could also add a minimum quorum requirement:
        // require(proposal.forVotes + proposal.againstVotes >= minQuorum, "AetherForge: Quorum not met");

        proposal.executed = true;

        // Execute the proposed action
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "AetherForge: Proposal execution failed");

        emit AIGovernanceProposalExecuted(proposalId);
    }

    /**
     * @dev Takes a snapshot of a user's "AI affinity" at the current block.
     *      AI affinity is derived from reputation, staked tokens, and possibly other metrics.
     *      This is useful for off-chain voting systems or complex on-chain calculations
     *      where the state needs to be fixed at a certain point.
     *      For this contract, it merely calculates and returns the current affinity.
     *      A more advanced version would store snapshots by block number.
     * @param user The address of the user for whom to calculate affinity.
     * @return The calculated AI affinity score.
     */
    function snapshotAIAffinity(address user) external view returns (uint256) {
        // AI affinity is a combination of on-chain reputation and governance token balance
        // This function will return the affinity of the actual user, not their delegatee.
        uint256 affinity = contributorReputation[user] + (STUDIO_TOKEN.balanceOf(user) / (1 ether)); // 1 token = 1 affinity unit
        // Could also include delegated power *from* others, or other factors.
        return affinity;
    }

    // --- ERC721 Overrides ---

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *      This function is an override of the standard ERC721 `tokenURI`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return artifacts[tokenId].metadataURI;
    }
}
```