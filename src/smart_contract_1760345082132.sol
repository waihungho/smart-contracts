Here's a smart contract written in Solidity, incorporating advanced, creative, and trendy concepts, with at least 20 functions. This contract aims to build a **"Synthetica Knowledge Hub"** – a decentralized platform for sharing, curating, and funding knowledge artifacts, integrating dynamic Soulbound Reputation NFTs (SBTs), AI oracle-assisted content assessment, knowledge bounties, and DAO-like governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
// Importing IERC721 is typically for transferrable NFTs, but for SBTs,
// we're primarily interested in the token ID and metadata, not transfer.
// The ISyntheticaReputationNFT interface defines the specific SBT functions.

/**
 * @title ISyntheticaReputationNFT
 * @dev Interface for the Soulbound Token (SBT) Reputation NFT contract.
 *      This NFT is non-transferable and its metadata (e.g., level, visual traits)
 *      is designed to update dynamically based on a user's on-chain actions
 *      and reputation score managed by the SyntheticaKnowledgeHub.
 */
interface ISyntheticaReputationNFT {
    /**
     * @dev Mints a new Soulbound Reputation NFT for a user.
     *      This function would typically only be callable by trusted contracts like SyntheticaKnowledgeHub.
     * @param to The address to mint the NFT to.
     * @param initialReputation The initial reputation score for the new NFT.
     * @return tokenId The ID of the newly minted NFT.
     */
    function mint(address to, uint256 initialReputation) external returns (uint256 tokenId);

    /**
     * @dev Updates the reputation score associated with a specific NFT.
     *      This would trigger a `_setTokenURI` internal call within the SBT contract
     *      to reflect the new reputation level in the NFT's metadata.
     * @param tokenId The ID of the NFT to update.
     * @param newReputationScore The new reputation score to set.
     */
    function updateReputation(uint256 tokenId, uint256 newReputationScore) external;

    /**
     * @dev Retrieves the current reputation score of an NFT.
     * @param tokenId The ID of the NFT.
     * @return The current reputation score.
     */
    function getReputationScore(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Retrieves the token ID of a user's Reputation NFT.
     * @param user The address of the user.
     * @return The token ID associated with the user.
     */
    function getTokenIdByAddress(address user) external view returns (uint256);

    /**
     * @dev Checks if a user already possesses a Reputation NFT.
     * @param user The address of the user.
     * @return True if the user has an NFT, false otherwise.
     */
    function doesUserHaveNFT(address user) external view returns (bool);
}

/**
 * @title IAIDecisionOracle
 * @dev Interface for an AI Decision Oracle contract.
 *      This oracle provides AI-generated insights for knowledge artifacts,
 *      acting as a trusted external data provider.
 */
interface IAIDecisionOracle {
    /**
     * @dev Submits AI-generated data for a specific artifact.
     *      This function would only be callable by a whitelisted AI service provider.
     * @param _artifactId The ID of the artifact analyzed.
     * @param _aiScore The AI-generated quality/relevance score.
     * @param _suggestedTags An array of tags suggested by the AI.
     */
    function submitDecision(uint256 _artifactId, uint256 _aiScore, string[] calldata _suggestedTags) external;

    /**
     * @dev Retrieves the latest AI decision for an artifact.
     * @param _artifactId The ID of the artifact.
     * @return aiScore The AI-generated score.
     * @return suggestedTags The AI-generated suggested tags.
     */
    function getAIDecision(uint256 _artifactId) external view returns (uint256 aiScore, string[] memory suggestedTags);

    /**
     * @dev Checks if an address is a recognized AI oracle.
     *      Allows for multiple authorized oracle addresses or complex access control within the oracle contract.
     * @param _addr The address to check.
     * @return True if the address is an oracle, false otherwise.
     */
    function isOracle(address _addr) external view returns (bool);
}


/**
 * @title SyntheticaKnowledgeHub
 * @dev A decentralized knowledge repository and curation system.
 *      This contract integrates dynamic, soulbound reputation NFTs, AI oracle for content assessment,
 *      community-driven curation, knowledge bounties, and basic DAO-like governance.
 *      It aims for novel interaction patterns and advanced use of existing primitives
 *      to create a self-sustaining and intelligently moderated knowledge ecosystem.
 */
contract SyntheticaKnowledgeHub is Ownable, Pausable {

    // --- Outline and Function Summary ---
    //
    // This contract, SyntheticaKnowledgeHub, acts as a decentralized platform for sharing,
    // curating, and funding knowledge artifacts. It introduces several advanced concepts:
    //
    // 1.  **Dynamic Soulbound Reputation NFTs (SBTs):** User reputation is tied to a
    //     non-transferable NFT which dynamically updates its visual representation (via URI)
    //     and internal score based on on-chain actions (contributions, curation, accurate flags).
    // 2.  **AI Oracle Integration:** Leverages an off-chain AI model (via an oracle contract)
    //     to assist in content categorization, quality scoring, and spam detection.
    // 3.  **Reputation-Weighted Curation:** Voting power on artifacts and proposals is
    //     scaled by a user's reputation score, promoting informed governance.
    // 4.  **Knowledge Bounties:** A mechanism for users to crowdfund and incentivize
    //     the creation of specific knowledge artifacts.
    // 5.  **Simplified DAO Governance:** Basic proposal and voting system for key
    //     contract parameters or fund allocations, using reputation-weighted votes.
    //
    // Functions are grouped by their primary purpose:
    //
    // **I. Core Infrastructure & Configuration (Owner/Admin controlled)**
    // 1.  `constructor`: Initializes the contract, sets the owner, and initial parameters.
    // 2.  `setAIDecisionOracle`: Sets the address of the trusted AI oracle contract.
    // 3.  `setReputationNFTContract`: Sets the address of the Synthetica Reputation NFT contract.
    // 4.  `setSubmissionFee`: Sets the fee required to submit a new knowledge artifact.
    // 5.  `setVoteWeightMultiplier`: Adjusts the impact of reputation score on vote power.
    // 6.  `setMinReputationForProposal`: Sets the minimum reputation score required to create a governance proposal.
    // 7.  `pauseContract`: Emergency function to pause critical contract operations.
    // 8.  `unpauseContract`: Unpauses the contract after an emergency.
    // 9.  `withdrawFunds`: Allows the owner to withdraw accumulated contract funds (e.g., submission fees).
    //
    // **II. Knowledge Artifact Management**
    // 10. `submitArtifact`: Allows users to submit a new knowledge artifact (IPFS hash, metadataURI, initial tags). Requires a fee.
    // 11. `getArtifactDetails`: Retrieves the comprehensive details of a specific knowledge artifact.
    // 12. `updateArtifactMetadata`: Allows the original contributor to update the artifact's non-critical metadata URI.
    // 13. `flagArtifact`: Allows users to flag an artifact for review (e.g., spam, incorrect information).
    // 14. `resolveFlag`: Allows high-reputation users or owner to resolve a flagged artifact, potentially deactivating it.
    //
    // **III. Curation & Voting**
    // 15. `upvoteArtifact`: Casts an upvote for an artifact, with vote weight scaled by the user's reputation.
    // 16. `downvoteArtifact`: Casts a downvote for an artifact, with vote weight scaled by the user's reputation.
    // 17. `addTagsToArtifact`: Proposes new tags for an artifact; high-reputation users can confirm.
    // 18. `removeTagsFromArtifact`: Proposes removal of tags from an artifact; high-reputation users can confirm.
    // 19. `getArtifactVotes`: Retrieves the current upvote and downvote counts for an artifact.
    //
    // **IV. Reputation & Rewards (Interacting with SBT-NFT)**
    // 20. `requestReputationEvaluation`: Triggers an evaluation of the caller's reputation score based on recent actions, and updates their SBT.
    // 21. `claimReward`: Allows users to claim their accumulated rewards earned from contributing and curating.
    // 22. `getContributorRewardBalance`: Returns the current pending reward balance for a specific contributor.
    // 23. `getReputationLevelForUser`: Retrieves the reputation score (level) for a given user from the associated NFT contract.
    //
    // **V. AI Oracle Integration**
    // 24. `receiveAIDecision`: A trusted function for the AI oracle to submit its analysis (score, tags) for an artifact.
    // 25. `getAIDecisionForArtifact`: Retrieves the AI-generated decision (score and tags) for an artifact.
    // 26. `verifyAIDecisionAccuracy`: Allows high-reputation users to verify the accuracy of an AI oracle's decision, impacting oracle's future trust.
    //
    // **VI. Knowledge Bounties & Governance**
    // 27. `createKnowledgeBounty`: Creates a new bounty for specific knowledge, funded by the creator.
    // 28. `submitBountySolution`: Submits an existing artifact as a solution to an open bounty.
    // 29. `voteOnBountySolution`: Allows users to vote on proposed solutions for a bounty (reputation-weighted).
    // 30. `awardBounty`: Awards the bounty to the winning artifact/contributor, distributing the reward.
    // 31. `createGovernanceProposal`: Allows high-reputation users to propose changes to contract parameters.
    // 32. `voteOnGovernanceProposal`: Allows users to vote on active governance proposals (reputation-weighted, time-locked).
    // 33. `executeGovernanceProposal`: Executes a passed governance proposal.

    // --- State Variables ---
    uint256 public nextArtifactId;
    uint256 public nextBountyId;
    uint256 public nextProposalId;
    uint256 public submissionFee; // Fee in wei to submit an artifact
    uint256 public voteWeightMultiplier; // Multiplier for reputation to determine vote power (e.g., 100 means 100 rep adds 1 vote)
    uint256 public minReputationForProposal; // Minimum reputation score required to create a governance proposal

    address public aiDecisionOracleAddress;
    address public syntheticaReputationNFTAddress;

    ISyntheticaReputationNFT private sbtNFT;
    IAIDecisionOracle private aiOracle;

    // --- Data Structures ---

    /**
     * @dev Represents a knowledge artifact submitted to the hub.
     *      Designed to store decentralized content references and community/AI assessments.
     */
    struct Artifact {
        uint256 id;
        address contributor;
        string ipfsHash; // CID of the knowledge artifact (e.g., IPFS)
        string metadataURI; // URI pointing to additional JSON metadata (description, extended tags, licensing)
        uint256 submissionTime;
        uint256 totalUpvotes; // Sum of reputation-weighted upvotes
        uint256 totalDownvotes; // Sum of reputation-weighted downvotes
        mapping(address => bool) hasUpvoted; // User has cast a base upvote
        mapping(address => bool) hasDownvoted; // User has cast a base downvote
        mapping(string => bool) tags; // Key-value for quick lookup of tags
        string[] currentTags; // Array for easy iteration of tags
        bool isFlagged; // Indicates if the artifact has been flagged for review
        bool isActive; // Can be deactivated if resolved negatively or if content is deemed harmful
        uint256 aiScore; // Score from AI oracle (e.g., 0-100 for quality/relevance, higher is better)
        bool aiScoreSubmitted; // True if AI has submitted a score for this artifact
    }
    mapping(uint256 => Artifact) public artifacts;
    mapping(address => uint256[]) public contributorArtifacts; // Track artifacts by contributor
    mapping(address => uint252) public contributorRewardBalances; // Rewards awaiting claim (using uint252 to save a tiny bit of gas, as max is 2^256-1 anyway)

    /**
     * @dev Represents a knowledge bounty, allowing users to fund requests for specific information.
     *      Enables a decentralized funding mechanism for knowledge creation.
     */
    struct KnowledgeBounty {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 rewardAmount; // In wei, allocated to the winner
        uint256 deadline; // Timestamp by which solutions must be submitted and votes cast
        uint256 winnerArtifactId; // ID of the artifact that won, 0 if not awarded
        bool isActive; // Bounty can be deactivated or finished
        mapping(uint256 => uint256) solutionVotes; // artifactId => total reputation-weighted votes
        mapping(address => mapping(uint256 => bool)) hasVotedOnSolution; // user => artifactId => voted state
        uint256[] proposedSolutions; // Array of artifact IDs proposed as solutions
    }
    mapping(uint256 => KnowledgeBounty) public knowledgeBounties;

    /**
     * @dev Represents a governance proposal, allowing community to suggest and vote on system changes.
     *      Implements a simplified DAO-like structure for key parameter adjustments.
     */
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution on targetContract
        address targetContract; // The contract to execute the call on (e.g., this contract itself)
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 quorumRequiredPercentage; // e.g., 51 for 51% of total reputation
        uint256 totalReputationSupplyAtCreation; // Snapshot of total reputation for quorum calculation
        uint256 totalVotesFor; // Sum of reputation-weighted votes for the proposal
        uint256 totalVotesAgainst; // Sum of reputation-weighted votes against the proposal
        bool executed; // True if the proposal has been executed
        bool passed; // True if the proposal passed all conditions (quorum, majority)
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this proposal
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event ArtifactSubmitted(uint256 indexed artifactId, address indexed contributor, string ipfsHash, string metadataURI);
    event ArtifactUpvoted(uint256 indexed artifactId, address indexed voter, uint256 reputationWeight);
    event ArtifactDownvoted(uint256 indexed artifactId, address indexed voter, uint252 reputationWeight);
    event ArtifactFlagged(uint256 indexed artifactId, address indexed flipper);
    event ArtifactFlagResolved(uint256 indexed artifactId, bool deactivated);
    event MetadataUpdated(uint256 indexed artifactId, string newMetadataURI);
    event TagsAdded(uint256 indexed artifactId, address indexed user, string[] newTags);
    event TagsRemoved(uint256 indexed artifactId, address indexed user, string[] removedTags);
    event ReputationEvaluationRequested(address indexed user, uint252 newReputationScore);
    event RewardClaimed(address indexed user, uint252 amount);
    event AIDecisionReceived(uint256 indexed artifactId, uint252 aiScore, string[] suggestedTags);
    event AIDecisionVerified(uint256 indexed artifactId, address indexed verifier, bool accurate);
    event KnowledgeBountyCreated(uint256 indexed bountyId, address indexed creator, uint252 rewardAmount, uint256 deadline);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed artifactId, address indexed submitter);
    event BountySolutionVoted(uint256 indexed bountyId, uint256 indexed artifactId, address indexed voter, uint252 reputationWeight);
    event BountyAwarded(uint256 indexed bountyId, uint256 indexed winnerArtifactId, address indexed winner);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint252 reputationWeight);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Constructor ---
    /**
     * @dev Initializes the SyntheticaKnowledgeHub contract.
     * @param _aiDecisionOracle The address of the trusted AI Decision Oracle contract.
     * @param _syntheticaReputationNFT The address of the Synthetica Reputation NFT (SBT) contract.
     * @param _submissionFee The fee required to submit a knowledge artifact (in wei).
     * @param _voteWeightMultiplier The multiplier for reputation score to determine voting power.
     * @param _minReputationForProposal The minimum reputation score needed to create a governance proposal.
     */
    constructor(address _aiDecisionOracle, address _syntheticaReputationNFT, uint256 _submissionFee, uint256 _voteWeightMultiplier, uint256 _minReputationForProposal)
        Ownable(msg.sender)
    {
        require(_aiDecisionOracle != address(0), "Invalid AI Oracle address");
        require(_syntheticaReputationNFT != address(0), "Invalid Reputation NFT address");
        require(_submissionFee > 0, "Submission fee must be greater than zero");
        require(_voteWeightMultiplier > 0, "Vote weight multiplier must be greater than zero");
        require(_minReputationForProposal > 0, "Min reputation for proposal must be greater than zero");

        aiDecisionOracleAddress = _aiDecisionOracle;
        syntheticaReputationNFTAddress = _syntheticaReputationNFT;
        sbtNFT = ISyntheticaReputationNFT(_syntheticaReputationNFT);
        aiOracle = IAIDecisionOracle(_aiDecisionOracle);

        submissionFee = _submissionFee;
        voteWeightMultiplier = _voteWeightMultiplier;
        minReputationForProposal = _minReputationForProposal;
        nextArtifactId = 1;
        nextBountyId = 1;
        nextProposalId = 1;
    }

    // --- Modifiers ---
    /**
     * @dev Restricts access to functions callable only by the designated AI Oracle.
     *      Includes support for multiple oracles managed by the oracle contract itself.
     */
    modifier onlyAIOracle() {
        require(msg.sender == aiDecisionOracleAddress || aiOracle.isOracle(msg.sender), "Caller is not the AI Oracle");
        _;
    }

    /**
     * @dev Restricts access to functions callable only by users with a minimum reputation score.
     * @param _minReputation The minimum required reputation score.
     */
    modifier onlyHighReputation(uint256 _minReputation) {
        require(getReputationLevelForUser(msg.sender) >= _minReputation, "Insufficient reputation");
        _;
    }

    // --- Internal / Helper Functions ---
    /**
     * @dev Calculates the weighted vote based on a user's reputation score.
     *      Novelty: Directly integrates with an external Soulbound Token (SBT) contract
     *      to dynamically fetch and apply reputation as a multiplier for voting power.
     * @param _voter The address of the user casting the vote.
     * @return The calculated vote weight.
     */
    function _getWeightedVote(address _voter) internal view returns (uint256) {
        if (!sbtNFT.doesUserHaveNFT(_voter)) {
            return 1; // Base vote for users without an NFT yet (or base reputation 0)
        }
        uint256 reputation = sbtNFT.getReputationScore(sbtNFT.getTokenIdByAddress(_voter));
        // A simple scaling: 1 + (reputation score / multiplier).
        // E.g., if multiplier is 100, 100 rep gives 2 vote weight (1 base + 1 rep-based).
        return 1 + (reputation / voteWeightMultiplier);
    }

    /**
     * @dev Awards accumulated rewards to a recipient's balance within the contract.
     * @param _recipient The address to award the rewards to.
     * @param _amount The amount of rewards in wei.
     */
    function _awardRewards(address _recipient, uint252 _amount) internal {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Reward amount must be greater than zero");
        contributorRewardBalances[_recipient] += _amount;
    }

    /**
     * @dev Placeholder for actual reputation calculation logic.
     *      Novelty: Centralized reputation calculation based on diverse on-chain actions within the Hub,
     *      then pushing updates to a separate, dynamic SBT contract.
     *      In a real, advanced system, this would be a sophisticated algorithm considering:
     *      - Quantity and quality (upvotes/AI score) of submitted artifacts.
     *      - Accuracy and impact of curation actions (upvotes/downvotes aligning with consensus).
     *      - Successful flagging of malicious content or verification of AI decisions.
     *      - Participation in bounties and governance.
     *      - Time-decay or activity decay to prevent stale reputation.
     *      For this example, we simulate a simple increment to demonstrate the update flow.
     * @param _user The address of the user whose reputation is being calculated.
     * @return The newly calculated reputation score.
     */
    function _calculateNewReputationScore(address _user) internal view returns (uint252) {
        uint252 currentScore = sbtNFT.doesUserHaveNFT(_user) ? uint252(sbtNFT.getReputationScore(sbtNFT.getTokenIdByAddress(_user))) : 0;

        // --- SIMPLIFIED REPUTATION CALCULATION FOR DEMONSTRATION ---
        // In a production system, this would involve extensive logic,
        // likely querying mapping states related to _user's interactions (e.g., _user's artifacts, votes).
        // This function would be highly gas-intensive if it iterates over all user actions.
        // A more scalable approach would be:
        // 1. Off-chain computation: An off-chain service calculates reputation and submits it via an oracle.
        // 2. Event-driven updates: Actions directly update a cached reputation score, and this function
        //    would then simply read the aggregated score (and apply time decay etc).
        // For the purpose of meeting the "creative concept" and demonstrating flow,
        // we'll imagine a simplified mechanism that slightly increases it for active participation.
        // Actual logic would be much more complex and perhaps stored in an aggregate mapping to avoid iteration.
        
        // Example logic: Base score + 1 for active participation (e.g., calling this function)
        // plus some more complex calculation based on specific contributions.
        uint252 newScore = currentScore + 10; // Placeholder for reputation gain from positive actions
        // Ensure reputation doesn't drop below 0 (though uint handles this for positive scores)
        return newScore;
    }


    // --- I. Core Infrastructure & Configuration ---

    /**
     * @dev Sets the address of the AI Decision Oracle contract.
     *      Only callable by the contract owner.
     * @param _newOracle The new address for the AI Decision Oracle.
     */
    function setAIDecisionOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid AI Oracle address");
        aiDecisionOracleAddress = _newOracle;
        aiOracle = IAIDecisionOracle(_newOracle);
    }

    /**
     * @dev Sets the address of the Synthetica Reputation NFT contract.
     *      Only callable by the contract owner.
     * @param _newNFTContract The new address for the Synthetica Reputation NFT contract.
     */
    function setReputationNFTContract(address _newNFTContract) external onlyOwner {
        require(_newNFTContract != address(0), "Invalid Reputation NFT address");
        syntheticaReputationNFTAddress = _newNFTContract;
        sbtNFT = ISyntheticaReputationNFT(_newNFTContract);
    }

    /**
     * @dev Sets the fee required to submit a new knowledge artifact.
     *      Only callable by the contract owner.
     * @param _newFee The new submission fee in wei.
     */
    function setSubmissionFee(uint252 _newFee) external onlyOwner {
        require(_newFee > 0, "Submission fee must be greater than zero");
        submissionFee = _newFee;
    }

    /**
     * @dev Adjusts the multiplier that determines the impact of reputation score on vote power.
     *      A higher multiplier means reputation has less individual impact per point.
     *      Only callable by the owner.
     * @param _newMultiplier The new vote weight multiplier.
     */
    function setVoteWeightMultiplier(uint252 _newMultiplier) external onlyOwner {
        require(_newMultiplier > 0, "Multiplier must be greater than zero");
        voteWeightMultiplier = _newMultiplier;
    }

    /**
     * @dev Sets the minimum reputation score required to create a governance proposal.
     *      Only callable by the contract owner.
     * @param _newMinReputation The new minimum reputation score.
     */
    function setMinReputationForProposal(uint252 _newMinReputation) external onlyOwner {
        minReputationForProposal = _newMinReputation;
    }

    /**
     * @dev Pauses the contract, preventing critical functions from being called.
     *      Emergency function, only callable by the owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing critical functions to be called again.
     *      Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated funds (e.g., submission fees, bounty refunds).
     *      Funds are stored in the contract's balance.
     */
    function withdrawFunds() external onlyOwner {
        uint252 balance = uint252(address(this).balance);
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }


    // --- II. Knowledge Artifact Management ---

    /**
     * @dev Allows users to submit a new knowledge artifact.
     *      Requires a submission fee, and the artifact is linked to an IPFS hash.
     *      Novelty: Artifacts linked to IPFS hash and extensive metadata URI,
     *      designed for future AI oracle interaction and rich content description.
     * @param _ipfsHash The IPFS CID of the knowledge artifact (e.g., "Qm...").
     * @param _metadataURI A URI pointing to additional JSON metadata for the artifact (description, license, etc.).
     * @param _initialTags An array of initial tags for the artifact.
     */
    function submitArtifact(string calldata _ipfsHash, string calldata _metadataURI, string[] calldata _initialTags)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= submissionFee, "Insufficient submission fee");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        uint256 artifactId = nextArtifactId++;
        Artifact storage newArtifact = artifacts[artifactId];
        newArtifact.id = artifactId;
        newArtifact.contributor = msg.sender;
        newArtifact.ipfsHash = _ipfsHash;
        newArtifact.metadataURI = _metadataURI;
        newArtifact.submissionTime = block.timestamp;
        newArtifact.isActive = true;

        for (uint256 i = 0; i < _initialTags.length; i++) {
            if (bytes(_initialTags[i]).length > 0) { // Ensure tag is not empty
                if (!newArtifact.tags[_initialTags[i]]) { // Prevent duplicate tags
                    newArtifact.tags[_initialTags[i]] = true;
                    newArtifact.currentTags.push(_initialTags[i]);
                }
            }
        }

        contributorArtifacts[msg.sender].push(artifactId);

        // Refund any excess payment
        if (msg.value > submissionFee) {
            payable(msg.sender).transfer(msg.value - submissionFee);
        }

        emit ArtifactSubmitted(artifactId, msg.sender, _ipfsHash, _metadataURI);
    }

    /**
     * @dev Retrieves the comprehensive details of a specific knowledge artifact.
     *      Includes community votes, AI score, and metadata for a holistic view.
     * @param _artifactId The ID of the artifact to retrieve.
     * @return All relevant details of the artifact.
     */
    function getArtifactDetails(uint256 _artifactId)
        external
        view
        returns (
            uint256 id,
            address contributor,
            string memory ipfsHash,
            string memory metadataURI,
            uint256 submissionTime,
            uint252 totalUpvotes,
            uint252 totalDownvotes,
            string[] memory tags,
            bool isFlagged,
            bool isActive,
            uint252 aiScore,
            bool aiScoreSubmitted
        )
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");

        return (
            artifact.id,
            artifact.contributor,
            artifact.ipfsHash,
            artifact.metadataURI,
            artifact.submissionTime,
            uint252(artifact.totalUpvotes), // Cast to uint252 for consistency with other emitted values
            uint252(artifact.totalDownvotes),
            artifact.currentTags,
            artifact.isFlagged,
            artifact.isActive,
            uint252(artifact.aiScore),
            artifact.aiScoreSubmitted
        );
    }

    /**
     * @dev Allows the original contributor to update the artifact's non-critical metadata URI.
     *      This is useful for dNFT-like evolving content or fixing outdated links without changing the core content hash.
     * @param _artifactId The ID of the artifact to update.
     * @param _newMetadataURI The new URI for the artifact's metadata.
     */
    function updateArtifactMetadata(uint256 _artifactId, string calldata _newMetadataURI)
        external
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.contributor == msg.sender, "Only the contributor can update metadata");

        artifact.metadataURI = _newMetadataURI;
        emit MetadataUpdated(_artifactId, _newMetadataURI);
    }

    /**
     * @dev Allows any user to flag an artifact for review (e.g., spam, incorrect information, harmful content).
     *      Triggers a community or admin review process by marking the artifact as flagged.
     * @param _artifactId The ID of the artifact to flag.
     */
    function flagArtifact(uint256 _artifactId)
        external
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(!artifact.isFlagged, "Artifact is already flagged");

        artifact.isFlagged = true;
        // In a more complex system, this might trigger a specific review queue or a voting round.
        emit ArtifactFlagged(_artifactId, msg.sender);
    }

    /**
     * @dev Allows high-reputation users or the owner to resolve a flagged artifact.
     *      Can result in deactivating the artifact if the flag is valid (e.g., confirmed spam).
     * @param _artifactId The ID of the artifact to resolve.
     * @param _deactivate Whether to deactivate the artifact or not (e.g., if the flag is confirmed true).
     */
    function resolveFlag(uint256 _artifactId, bool _deactivate)
        external
        onlyHighReputation(minReputationForProposal) // Example: requires high reputation to resolve flags
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isFlagged, "Artifact is not flagged");

        artifact.isFlagged = false; // Flag status reset
        if (_deactivate) {
            artifact.isActive = false; // Artifact removed from active view/search
        }
        // Potentially, if the flag was malicious or frivolous, the flagging user's reputation could be impacted
        // (logic for this would be in _calculateNewReputationScore).
        emit ArtifactFlagResolved(_artifactId, _deactivate);
    }

    // --- III. Curation & Voting ---

    /**
     * @dev Casts an upvote for an artifact. Vote weight is scaled by the user's reputation.
     *      Novelty: Reputation-weighted voting directly impacts the artifact's aggregated score,
     *      promoting quality contributions and discerning curation.
     * @param _artifactId The ID of the artifact to upvote.
     */
    function upvoteArtifact(uint256 _artifactId)
        external
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isActive, "Artifact is not active");
        require(artifact.contributor != msg.sender, "Cannot vote on your own artifact");
        require(!artifact.hasUpvoted[msg.sender], "Already upvoted this artifact");

        uint252 voteWeight = uint252(_getWeightedVote(msg.sender));
        artifact.totalUpvotes += voteWeight;
        artifact.hasUpvoted[msg.sender] = true;

        // If previously downvoted, remove that downvote to prevent double-counting or inconsistent state
        if (artifact.hasDownvoted[msg.sender]) {
            artifact.totalDownvotes -= voteWeight; // Assuming same weight for removing
            artifact.hasDownvoted[msg.sender] = false;
        }

        // Award a small amount to the curator for their engagement and positive contribution
        _awardRewards(msg.sender, 1 wei);

        emit ArtifactUpvoted(_artifactId, msg.sender, voteWeight);
    }

    /**
     * @dev Casts a downvote for an artifact. Vote weight is scaled by the user's reputation.
     *      Novelty: Reputation-weighted voting directly impacts the artifact's aggregated score,
     *      allowing the community to collectively identify and demote low-quality content.
     * @param _artifactId The ID of the artifact to downvote.
     */
    function downvoteArtifact(uint256 _artifactId)
        external
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isActive, "Artifact is not active");
        require(artifact.contributor != msg.sender, "Cannot vote on your own artifact");
        require(!artifact.hasDownvoted[msg.sender], "Already downvoted this artifact");

        uint252 voteWeight = uint252(_getWeightedVote(msg.sender));
        artifact.totalDownvotes += voteWeight;
        artifact.hasDownvoted[msg.sender] = true;

        // If previously upvoted, remove that upvote
        if (artifact.hasUpvoted[msg.sender]) {
            artifact.totalUpvotes -= voteWeight;
            artifact.hasUpvoted[msg.sender] = false;
        }

        _awardRewards(msg.sender, 1 wei); // Tiny reward for engagement

        emit ArtifactDownvoted(_artifactId, msg.sender, voteWeight);
    }

    /**
     * @dev Proposes new tags for an artifact. For simplicity, new tags are added directly.
     *      High-reputation users could potentially remove inappropriate tags later.
     *      Novelty: Community-driven tagging allows for organic content categorization.
     * @param _artifactId The ID of the artifact.
     * @param _newTags An array of tags to add.
     */
    function addTagsToArtifact(uint256 _artifactId, string[] calldata _newTags)
        external
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isActive, "Artifact is not active");
        
        // In a more complex system, there could be a voting process for tags.
        // For simplicity, any user can suggest, and it's added.
        // High-rep users could remove later if inappropriate.

        for (uint256 i = 0; i < _newTags.length; i++) {
            if (bytes(_newTags[i]).length > 0 && !artifact.tags[_newTags[i]]) {
                artifact.tags[_newTags[i]] = true;
                artifact.currentTags.push(_newTags[i]);
            }
        }
        emit TagsAdded(_artifactId, msg.sender, _newTags);
    }

    /**
     * @dev Proposes removal of tags from an artifact. This action is restricted to high-reputation users.
     *      Novelty: Allows the community, specifically trusted members, to refine content categorization
     *      and correct mislabeling.
     * @param _artifactId The ID of the artifact.
     * @param _tagsToRemove An array of tags to remove.
     */
    function removeTagsFromArtifact(uint256 _artifactId, string[] calldata _tagsToRemove)
        external
        whenNotPaused
        onlyHighReputation(minReputationForProposal) // Only high-rep can remove tags directly
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isActive, "Artifact is not active");

        for (uint256 i = 0; i < _tagsToRemove.length; i++) {
            if (bytes(_tagsToRemove[i]).length > 0 && artifact.tags[_tagsToRemove[i]]) {
                artifact.tags[_tagsToRemove[i]] = false;
                // Efficiently remove from dynamic array by swapping with last element and popping.
                for (uint256 j = 0; j < artifact.currentTags.length; j++) {
                    if (keccak256(abi.encodePacked(artifact.currentTags[j])) == keccak256(abi.encodePacked(_tagsToRemove[i]))) {
                        artifact.currentTags[j] = artifact.currentTags[artifact.currentTags.length - 1];
                        artifact.currentTags.pop();
                        break;
                    }
                }
            }
        }
        emit TagsRemoved(_artifactId, msg.sender, _tagsToRemove);
    }


    /**
     * @dev Retrieves the current upvote and downvote counts for an artifact.
     * @param _artifactId The ID of the artifact.
     * @return totalUpvotes Sum of reputation-weighted upvotes.
     * @return totalDownvotes Sum of reputation-weighted downvotes.
     */
    function getArtifactVotes(uint256 _artifactId)
        external
        view
        returns (uint252 totalUpvotes, uint252 totalDownvotes)
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        return (uint252(artifact.totalUpvotes), uint252(artifact.totalDownvotes));
    }

    // --- IV. Reputation & Rewards (Interacting with SBT-NFT) ---

    /**
     * @dev Triggers an evaluation of the caller's reputation score based on recent actions.
     *      Updates the user's Soulbound Reputation NFT, reflecting their activity and contributions.
     *      Novelty: User-initiated reputation update which interacts with an external, dynamic SBT contract.
     *      This decouples reputation data from the core hub logic, allowing for specialized NFT features.
     */
    function requestReputationEvaluation() external whenNotPaused {
        uint256 userTokenId;
        if (!sbtNFT.doesUserHaveNFT(msg.sender)) {
            // Mint a new SBT if user doesn't have one, starting with a base reputation
            userTokenId = sbtNFT.mint(msg.sender, 0); // Start with 0 reputation, then calculate
        } else {
            userTokenId = sbtNFT.getTokenIdByAddress(msg.sender);
        }

        uint252 newReputationScore = _calculateNewReputationScore(msg.sender);
        sbtNFT.updateReputation(userTokenId, newReputationScore);
        emit ReputationEvaluationRequested(msg.sender, newReputationScore);
    }

    /**
     * @dev Allows users to claim their accumulated rewards earned from contributing and curating.
     */
    function claimReward() external whenNotPaused {
        uint252 amount = contributorRewardBalances[msg.sender];
        require(amount > 0, "No rewards to claim");

        contributorRewardBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit RewardClaimed(msg.sender, amount);
    }

    /**
     * @dev Returns the current pending reward balance for a specific contributor.
     * @param _contributor The address of the contributor.
     * @return The pending reward amount in wei.
     */
    function getContributorRewardBalance(address _contributor) external view returns (uint252) {
        return contributorRewardBalances[_contributor];
    }

    /**
     * @dev Retrieves the reputation score for a given user from the associated NFT contract.
     *      This is a public wrapper around the SBT's `getReputationScore` for easy access.
     * @param _user The address of the user.
     * @return The current reputation score of the user. Returns 0 if the user does not have an SBT.
     */
    function getReputationLevelForUser(address _user) public view returns (uint252) {
        if (!sbtNFT.doesUserHaveNFT(_user)) {
            return 0; // User has no NFT, thus no reputation (or base 0)
        }
        uint256 tokenId = sbtNFT.getTokenIdByAddress(_user);
        return uint252(sbtNFT.getReputationScore(tokenId));
    }

    // --- V. AI Oracle Integration ---

    /**
     * @dev Trusted function for the AI oracle to submit its analysis for an artifact.
     *      Only callable by the designated AI oracle address or addresses authorized by it.
     *      Novelty: Directly integrates AI-generated metadata and quality scores into artifact state,
     *      providing an additional layer of automated moderation and categorization.
     * @param _artifactId The ID of the artifact that was analyzed.
     * @param _aiScore The AI-generated quality/relevance score (e.g., 0-100, higher is better).
     * @param _suggestedTags AI-generated suggested tags for the artifact.
     */
    function receiveAIDecision(uint256 _artifactId, uint252 _aiScore, string[] calldata _suggestedTags)
        external
        onlyAIOracle
        whenNotPaused
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(!artifact.aiScoreSubmitted, "AI score already submitted for this artifact");

        artifact.aiScore = _aiScore;
        artifact.aiScoreSubmitted = true;

        // Optionally integrate suggested tags directly or require community confirmation for AI tags
        for (uint256 i = 0; i < _suggestedTags.length; i++) {
            if (bytes(_suggestedTags[i]).length > 0 && !artifact.tags[_suggestedTags[i]]) {
                artifact.tags[_suggestedTags[i]] = true;
                artifact.currentTags.push(_suggestedTags[i]);
            }
        }
        emit AIDecisionReceived(_artifactId, _aiScore, _suggestedTags);

        // Award reward to contributor based on good AI score (incentivize high-quality submissions)
        if (_aiScore >= 70) { // Example threshold for a "good" AI score
            _awardRewards(artifact.contributor, 100 wei); // Reward for good content
        }
    }

    /**
     * @dev Retrieves the AI-generated decision (score and tags) for an artifact.
     * @param _artifactId The ID of the artifact.
     * @return aiScore The AI-generated score.
     * @return suggestedTags The AI-generated suggested tags.
     */
    function getAIDecisionForArtifact(uint256 _artifactId)
        external
        view
        returns (uint252 aiScore, string[] memory suggestedTags)
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.aiScoreSubmitted, "AI score not yet submitted for this artifact");
        
        // This directly calls the oracle's view function for tags, ensuring up-to-date data if oracle state changes.
        // It could also return `artifact.aiScore` and `artifact.currentTags` if preferred to cache all in main contract.
        (uint252 oracleScore, string[] memory oracleTags) = aiOracle.getAIDecision(_artifactId);
        return (oracleScore, oracleTags);
    }

    /**
     * @dev Allows high-reputation users to verify the accuracy of an AI oracle's decision.
     *      This mechanism contributes to building trust in the AI system.
     *      Novelty: Community validation mechanism for AI oracle outputs, could influence future oracle selection
     *      or a dynamic "trust score" for the oracle (which would be managed in an external contract).
     * @param _artifactId The ID of the artifact whose AI decision is being verified.
     * @param _accurate True if the AI decision is deemed accurate, false otherwise.
     */
    function verifyAIDecisionAccuracy(uint256 _artifactId, bool _accurate)
        external
        whenNotPaused
        onlyHighReputation(minReputationForProposal) // Only high-rep can verify AI
    {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.aiScoreSubmitted, "AI score not yet submitted for this artifact");

        // Logic here to update oracle's reputation/trust score (if managed externally in an Oracle Reputation contract)
        // For now, we emit an event. A more advanced system would use this feedback to adjust oracle selection.
        if (_accurate) {
            _awardRewards(msg.sender, 5 wei); // Reward for accurate verification
        } else {
            // Potentially deduct from msg.sender's reputation if their verification is later overturned,
            // or penalize the oracle if repeatedly inaccurate (managed by Oracle Reputation contract).
        }
        emit AIDecisionVerified(_artifactId, msg.sender, _accurate);
    }


    // --- VI. Knowledge Bounties & Governance ---

    /**
     * @dev Creates a new bounty for specific knowledge, funded by the creator.
     *      This allows users to crowdfund solutions to specific knowledge gaps.
     *      Novelty: Direct on-chain crowdfunding for specific knowledge creation, incentivizing community research.
     * @param _title The title of the bounty.
     * @param _description A detailed description of the knowledge required.
     * @param _rewardAmount The amount of Ether to reward the winner (in wei).
     * @param _deadline The timestamp by which solutions must be submitted and voted upon.
     */
    function createKnowledgeBounty(string calldata _title, string calldata _description, uint252 _rewardAmount, uint256 _deadline)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= _rewardAmount, "Insufficient funds sent for bounty reward");
        require(bytes(_title).length > 0, "Bounty title cannot be empty");
        require(_deadline > block.timestamp, "Bounty deadline must be in the future");

        uint256 bountyId = nextBountyId++;
        KnowledgeBounty storage newBounty = knowledgeBounties[bountyId];
        newBounty.id = bountyId;
        newBounty.creator = msg.sender;
        newBounty.title = _title;
        newBounty.description = _description;
        newBounty.rewardAmount = _rewardAmount;
        newBounty.deadline = _deadline;
        newBounty.isActive = true;

        // Any excess value is returned to the creator
        if (msg.value > _rewardAmount) {
            payable(msg.sender).transfer(msg.value - _rewardAmount);
        }

        emit KnowledgeBountyCreated(bountyId, msg.sender, _rewardAmount, _deadline);
    }

    /**
     * @dev Submits an existing artifact as a potential solution to an open bounty.
     * @param _bountyId The ID of the bounty.
     * @param _artifactId The ID of the artifact to submit as a solution.
     */
    function submitBountySolution(uint256 _bountyId, uint256 _artifactId)
        external
        whenNotPaused
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        require(bounty.creator != address(0), "Bounty does not exist");
        require(bounty.isActive, "Bounty is not active");
        require(block.timestamp < bounty.deadline, "Bounty submission deadline passed");

        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.contributor != address(0), "Artifact does not exist");
        require(artifact.isActive, "Artifact is not active");

        // Ensure the contributor of the artifact being submitted is the sender, or allow anyone to submit for others?
        // For novelty, let's allow anyone to submit, but the original contributor gets the reward.
        // require(artifact.contributor == msg.sender, "Only the artifact contributor can submit it as a solution");

        // Check if this artifact is already a proposed solution to avoid duplicates
        bool alreadyProposed = false;
        for (uint256 i = 0; i < bounty.proposedSolutions.length; i++) {
            if (bounty.proposedSolutions[i] == _artifactId) {
                alreadyProposed = true;
                break;
            }
        }
        require(!alreadyProposed, "Artifact already proposed as solution for this bounty");

        bounty.proposedSolutions.push(_artifactId);
        emit BountySolutionSubmitted(_bountyId, _artifactId, msg.sender);
    }

    /**
     * @dev Allows users to vote on proposed solutions for a bounty.
     *      Vote weight is scaled by user's reputation.
     *      Novelty: Reputation-weighted voting for bounty solutions, decentralizing the decision-making
     *      process for awarding knowledge grants.
     * @param _bountyId The ID of the bounty.
     * @param _artifactId The ID of the artifact solution to vote for.
     */
    function voteOnBountySolution(uint256 _bountyId, uint256 _artifactId)
        external
        whenNotPaused
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        require(bounty.creator != address(0), "Bounty does not exist");
        require(bounty.isActive, "Bounty is not active");
        require(block.timestamp < bounty.deadline, "Bounty voting deadline passed"); // Voting ends at the bounty deadline
        require(bounty.creator != msg.sender, "Bounty creator cannot vote on solutions");
        require(!bounty.hasVotedOnSolution[msg.sender][_artifactId], "Already voted on this solution");

        // Check if artifact is a valid proposed solution for this bounty
        bool isValidSolution = false;
        for (uint256 i = 0; i < bounty.proposedSolutions.length; i++) {
            if (bounty.proposedSolutions[i] == _artifactId) {
                isValidSolution = true;
                break;
            }
        }
        require(isValidSolution, "Artifact is not a proposed solution for this bounty");

        uint252 voteWeight = uint252(_getWeightedVote(msg.sender));
        bounty.solutionVotes[_artifactId] += voteWeight;
        bounty.hasVotedOnSolution[msg.sender][_artifactId] = true;

        emit BountySolutionVoted(_bountyId, _artifactId, msg.sender, voteWeight);
    }

    /**
     * @dev Awards the bounty to the winning artifact/contributor based on aggregated reputation-weighted votes.
     *      Can be called by anyone after the bounty deadline has passed.
     *      Novelty: Decentralized bounty awarding based on community consensus, reducing single points of failure.
     * @param _bountyId The ID of the bounty to award.
     */
    function awardBounty(uint256 _bountyId)
        external
        whenNotPaused
    {
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        require(bounty.creator != address(0), "Bounty does not exist");
        require(bounty.isActive, "Bounty is not active");
        require(block.timestamp >= bounty.deadline, "Bounty deadline has not passed yet");
        require(bounty.winnerArtifactId == 0, "Bounty already awarded");
        require(bounty.proposedSolutions.length > 0, "No solutions proposed for this bounty");

        uint256 winningArtifactId = 0;
        uint252 maxVotes = 0;

        // Determine the winning artifact based on highest reputation-weighted votes
        for (uint256 i = 0; i < bounty.proposedSolutions.length; i++) {
            uint256 currentArtifactId = bounty.proposedSolutions[i];
            if (bounty.solutionVotes[currentArtifactId] > maxVotes) {
                maxVotes = uint252(bounty.solutionVotes[currentArtifactId]);
                winningArtifactId = currentArtifactId;
            }
        }

        require(winningArtifactId != 0, "Could not determine a winner (e.g., no votes or ties)");
        // In case of a tie, the first artifact (lowest ID) with maxVotes wins. Could be refined.

        Artifact storage winnerArtifact = artifacts[winningArtifactId];
        require(winnerArtifact.contributor != address(0), "Winning artifact does not exist");

        bounty.winnerArtifactId = winningArtifactId;
        bounty.isActive = false; // Mark bounty as closed

        // Transfer reward to the winner's reward balance for claiming
        _awardRewards(winnerArtifact.contributor, bounty.rewardAmount);

        emit BountyAwarded(_bountyId, winningArtifactId, winnerArtifact.contributor);
    }

    /**
     * @dev Allows high-reputation users to propose changes to contract parameters or initiate specific actions.
     *      Novelty: DAO-like governance for specific contract functions/parameters,
     *      using encoded `callData` for extreme flexibility in proposed actions.
     * @param _description A clear description of the proposal.
     * @param _targetContract The address of the contract to call (e.g., this contract itself, or another managed contract).
     * @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.setSubmissionFee.selector, 100)`).
     * @param _votingDuration The duration for which the proposal will be open for voting (in seconds).
     * @param _quorumRequiredPercentage The percentage of total reputation required for quorum (e.g., 51 for 51%).
     */
    function createGovernanceProposal(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData,
        uint256 _votingDuration,
        uint252 _quorumRequiredPercentage
    )
        external
        whenNotPaused
        onlyHighReputation(minReputationForProposal) // Only high-reputation users can propose
    {
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_targetContract != address(0), "Target contract cannot be zero address");
        require(bytes(_callData).length > 0, "Call data cannot be empty");
        require(_votingDuration > 0, "Voting duration must be greater than zero");
        require(_quorumRequiredPercentage > 0 && _quorumRequiredPercentage <= 100, "Quorum percentage must be between 1 and 100");

        uint256 proposalId = nextProposalId++;
        GovernanceProposal storage newProposal = governanceProposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.callData = _callData;
        newProposal.targetContract = _targetContract;
        newProposal.creationTime = block.timestamp;
        newProposal.votingDeadline = block.timestamp + _votingDuration;
        newProposal.quorumRequiredPercentage = _quorumRequiredPercentage;
        // Novelty: Snapshot of total reputation. In a real system, this would require
        // iterating through all SBTs (very gas-intensive) or relying on a dedicated
        // governance token with a `totalSupply` function. For this example, it's a placeholder.
        newProposal.totalReputationSupplyAtCreation = 10000; // Placeholder for total sum of all user reputations.

        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on active governance proposals.
     *      Vote weight is scaled by user's reputation, empowering more trusted members.
     *      Novelty: Reputation-weighted voting on proposals, enabling decentralized changes
     *      to the contract's fundamental parameters.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp < proposal.votingDeadline, "Voting deadline passed");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint252 voteWeight = uint252(_getWeightedVote(msg.sender));
        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes a passed governance proposal. Can be called by anyone after the voting deadline.
     *      Requires the proposal to have met quorum and achieved a majority vote.
     *      Novelty: Decentralized execution of approved proposals, allowing the community
     *      to directly enact changes without relying solely on the owner.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.votingDeadline, "Voting period not over yet");
        require(!proposal.executed, "Proposal already executed");

        uint252 totalVotes = uint252(proposal.totalVotesFor + proposal.totalVotesAgainst);
        // Quorum calculated against the snapshot of total reputation at proposal creation
        uint252 quorumThreshold = (proposal.totalReputationSupplyAtCreation * proposal.quorumRequiredPercentage) / 100;
        
        bool passedQuorum = totalVotes >= quorumThreshold;
        bool majorityAchieved = proposal.totalVotesFor > proposal.totalVotesAgainst;

        if (passedQuorum && majorityAchieved) {
            // Execute the proposal's callData on the target contract
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.passed = true; // Mark as successfully passed and executed
        } else {
            proposal.passed = false; // Explicitly mark as failed if conditions not met
        }
        
        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, proposal.passed);
    }
}
```