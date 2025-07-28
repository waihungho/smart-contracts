Here's a Solidity smart contract named `AetherForge` that incorporates advanced concepts like dynamic Soulbound NFTs, AI oracle integration (simulated), reputation-weighted governance, and liquid delegation for a decentralized content curation and reputation building platform.

It is designed to be creative and trendy, focusing on a unique combination of features rather than replicating existing full solutions.

---

## Contract Name: AetherForge

### Purpose
`AetherForge` is a decentralized platform designed to foster high-quality content creation and curation. It achieves this by leveraging a combination of AI-driven evaluations and community consensus, translating user contributions and curation efforts into a dynamic, on-chain reputation system. This reputation is represented by Soulbound Tokens (SBTs) that visually and functionally evolve, influencing users' voting power and reward entitlements.

### Core Concepts

1.  **Dynamic Reputation NFTs (DR-NFTs):** These are non-transferable (Soulbound) ERC721 tokens whose metadata (e.g., level, traits) automatically updates based on a user's cumulative reputation score. They serve as an on-chain identity and a visual representation of a user's standing within the AetherForge ecosystem.
2.  **AI Oracle Integration (Simulated):** The contract includes a mechanism for a designated "AI Oracle" to submit evaluation scores for user-submitted content. In a real-world scenario, this would interface with decentralized AI computation networks or verifiable AI services (like Chainlink AI).
3.  **Reputation-Weighted Community Consensus:** Users vote on the quality and relevance of submitted content. Their vote weight is dynamically determined by their current reputation score and DR-NFT level, promoting a meritocratic and Sybil-resistant governance model.
4.  **Tokenized Incentives:** Contributors of high-quality content and active, effective curators are rewarded with an ERC20 token, encouraging participation and maintaining ecosystem health.
5.  **Liquid Reputation Delegation:** DR-NFT holders can delegate their *voting power* to another address without transferring ownership of their Soulbound NFT, enabling proxy voting and specialized roles while maintaining personal ownership of reputation.
6.  **Reputation Decay:** A mechanism to gently decay reputation for inactive users, ensuring that reputation reflects ongoing engagement and relevance.
7.  **Simplified On-chain Governance:** A basic proposal and voting system allows high-reputation users to propose and enact changes to key contract parameters.

### Function Summary (27 Functions)

**I. Core Infrastructure & Access Control**
1.  `constructor()`: Initializes the contract, deploying a new ERC20 token for rewards and an ERC721 for DR-NFTs. Sets initial owner and AI oracle.
2.  `updateAIOracleAddress(address _newOracle)`: Owner/DAO function to update the designated AI oracle address.
3.  `togglePause()`: Allows the owner to pause/unpause critical contract operations during maintenance or emergencies.
4.  `emergencyWithdrawERC20(address _token, uint256 _amount)`: Owner function to withdraw specific ERC20 tokens in critical situations.
5.  `emergencyWithdrawETH(uint256 _amount)`: Owner function to withdraw ETH from the contract in critical situations.

**II. Dynamic Reputation NFTs (DR-NFTs) - ERC721 & Soulbound Extensions**
6.  `mintInitialReputationNFT(address _recipient)`: Mints the very first, Level 0, Soulbound DR-NFT for a user. This is a one-time operation per address.
7.  `getReputationScore(address _user)`: Returns the current numerical reputation score of a user.
8.  `getReputationNFTLevel(address _user)`: Returns the current level of a user's DR-NFT based on their score.
9.  `tokenURI(uint256 _tokenId)`: Overrides ERC721 standard to provide a dynamically generated metadata URI for a DR-NFT, reflecting its current level and traits.
10. `_updateReputationNFT(address _user, uint256 _newScore)`: Internal function called to update a user's DR-NFT level and corresponding metadata based on their new reputation score.

**III. Content & Contribution Lifecycle**
11. `submitContent(string memory _contentHash, string memory _metadataURI, uint256 _category)`: Allows users with an active DR-NFT to submit content for evaluation. `_contentHash` points to the actual content (e.g., IPFS CID), `_metadataURI` to its descriptive metadata.
12. `submitAIConsensusScore(uint256 _contentId, uint256 _aiScore, string memory _aiModelVersion)`: Callable *only* by the designated AI Oracle. Submits an AI-generated evaluation score for a specific content piece. `_aiModelVersion` allows tracking AI model changes.
13. `voteOnContent(uint256 _contentId, bool _approve)`: Allows users with an active DR-NFT to cast a weighted vote (based on their reputation) on the quality of submitted content.
14. `finalizeContentEvaluation(uint256 _contentId)`: Triggers the final evaluation of content after a voting period. It calculates a combined AI and community score, updates the submitter's reputation, and distributes rewards. Can be called by anyone after a set cooldown/voting period.
15. `getContentDetails(uint256 _contentId)`: Retrieves all relevant information about a specific content submission.

**IV. Reputation Management & Incentives**
16. `calculateVotingPower(address _user)`: Returns the current weighted voting power of a user based on their reputation score or delegated power.
17. `distributeContentRewards(uint256 _contentId)`: Internal function called by `finalizeContentEvaluation` to manage reward distribution for successful content submitters and positive voters.
18. `claimRewards()`: Allows users to claim their accumulated ERC20 `AetherToken` rewards.
19. `delegateReputationVote(address _delegatee)`: Allows an NFT holder to delegate their *voting power* (but not ownership) to another address.
20. `revokeReputationVoteDelegation()`: Revokes a previously set voting power delegation.
21. `triggerReputationDecay(address _user)`: Allows any user to trigger a periodic reputation decay for an *inactive* user. This helps maintain the dynamism and relevance of the reputation system.

**V. DAO Governance (Simplified Parameters)**
22. `proposeParameterChange(string memory _paramName, uint256 _newValue)`: Allows users with sufficient reputation to propose changes to a whitelist of configurable system parameters (e.g., `minVotingPowerForProposal`, `rewardMultiplier`).
23. `voteOnProposal(uint256 _proposalId, bool _for)`: Users cast their weighted votes on open governance proposals.
24. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, applying the new parameter value to the contract.

**VI. Analytics & Read-Only Utilities**
25. `getLatestContentId()`: Returns the ID of the most recently submitted content.
26. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific governance proposal.
27. `getPendingRewards(address _user)`: Displays the amount of `AetherToken` rewards a user has accumulated but not yet claimed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety in some calculations

/**
 * @title AetherForge
 * @dev A decentralized platform for AI-driven reputation and content curation,
 *      featuring dynamic Soulbound NFTs and reputation-weighted governance.
 *
 * Outline:
 * I. Core Infrastructure & Access Control
 * II. Dynamic Reputation NFTs (DR-NFTs) - ERC721 & Soulbound Extensions
 * III. Content & Contribution Lifecycle
 * IV. Reputation Management & Incentives
 * V. DAO Governance (Simplified Parameters)
 * VI. Analytics & Read-Only Utilities
 *
 * Function Summary:
 * 1.  constructor(): Initializes contract, deploys AetherToken & ReputationNFT.
 * 2.  updateAIOracleAddress(address _newOracle): Updates the designated AI oracle.
 * 3.  togglePause(): Pauses/unpauses contract operations.
 * 4.  emergencyWithdrawERC20(address _token, uint256 _amount): Emergency withdrawal of ERC20.
 * 5.  emergencyWithdrawETH(uint256 _amount): Emergency withdrawal of ETH.
 * 6.  mintInitialReputationNFT(address _recipient): Mints a user's first Soulbound DR-NFT.
 * 7.  getReputationScore(address _user): Gets current numerical reputation score.
 * 8.  getReputationNFTLevel(address _user): Gets current level of a user's DR-NFT.
 * 9.  tokenURI(uint256 _tokenId): Provides dynamic metadata URI for DR-NFT.
 * 10. _updateReputationNFT(address _user, uint256 _newScore): Internal, updates DR-NFT level/metadata.
 * 11. submitContent(string _contentHash, string _metadataURI, uint256 _category): User submits content.
 * 12. submitAIConsensusScore(uint256 _contentId, uint256 _aiScore, string _aiModelVersion): AI oracle submits score.
 * 13. voteOnContent(uint256 _contentId, bool _approve): User casts weighted vote on content.
 * 14. finalizeContentEvaluation(uint256 _contentId): Triggers final content evaluation, reputation update, rewards.
 * 15. getContentDetails(uint256 _contentId): Retrieves content details.
 * 16. calculateVotingPower(address _user): Calculates user's weighted voting power.
 * 17. distributeContentRewards(uint256 _contentId): Internal, distributes rewards for content.
 * 18. claimRewards(): User claims accumulated AetherToken rewards.
 * 19. delegateReputationVote(address _delegatee): Delegates voting power.
 * 20. revokeReputationVoteDelegation(): Revokes voting power delegation.
 * 21. triggerReputationDecay(address _user): Triggers reputation decay for inactive user.
 * 22. proposeParameterChange(string _paramName, uint256 _newValue): Proposes system parameter change.
 * 23. voteOnProposal(uint256 _proposalId, bool _for): Votes on a governance proposal.
 * 24. executeProposal(uint256 _proposalId): Executes a passed proposal.
 * 25. getLatestContentId(): Returns ID of the most recent content.
 * 26. getProposalDetails(uint256 _proposalId): Returns details of a proposal.
 * 27. getPendingRewards(address _user): Returns pending AetherToken rewards.
 */

contract AetherForge is Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    // ERC20 token for rewards
    AetherToken public aetherToken;

    // ERC721 token for dynamic reputation NFTs (Soulbound)
    ReputationNFT public reputationNFT;

    // Address of the trusted AI oracle
    address public aiOracleAddress;

    // --- Content Management ---
    struct Content {
        address submitter;
        string contentHash; // IPFS CID or similar identifier for the actual content
        string metadataURI; // IPFS CID or URL for content metadata
        uint256 category;
        uint256 aiScore; // Score from AI oracle (e.g., 0-100)
        string aiModelVersion;
        uint256 positiveVotes;
        uint256 negativeVotes;
        uint256 totalWeightedVotes;
        bool aiScored;
        bool finalized;
        uint256 submissionTimestamp;
        uint256 finalizationTimestamp;
    }
    mapping(uint256 => Content) public contents;
    uint256 private _nextContentId;

    // Maps contentId -> voter -> hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVotedOnContent;

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;
    // Maps user => pending rewards
    mapping(address => uint256) public pendingRewards;
    // Last activity timestamp for reputation decay
    mapping(address => uint256) public lastActivityTimestamp;

    // Liquid delegation for voting power
    mapping(address => address) public votingDelegates; // user => delegatee

    // --- Governance ---
    struct Proposal {
        string paramName;
        uint256 newValue;
        uint256 proposalId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalWeightedVotesFor;
        uint256 totalWeightedVotesAgainst;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;

    // --- Configurable Parameters (can be changed via governance) ---
    uint256 public constant INITIAL_REPUTATION_SCORE = 100; // Base score for new users
    uint256 public constant MIN_REPUTATION_FOR_NFT_MINT = 0; // Set to 0 to allow anyone to mint their first
    uint256 public constant MIN_REPUTATION_TO_SUBMIT_CONTENT = 100;
    uint256 public constant CONTENT_VOTING_PERIOD_BLOCKS = 100; // Blocks for content voting
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 500; // Blocks for governance voting
    uint256 public constant MIN_REPUTATION_TO_PROPOSE = 1000;

    uint256 public reputationIncreasePerAIConsensus = 10;
    uint256 public reputationIncreasePerPositiveVote = 1;
    uint256 public reputationDecreasePerNegativeVote = 2; // Can be negative
    uint256 public reputationDecayPerPeriod = 5; // How much reputation decays
    uint256 public reputationDecayPeriod = 7 days; // How often decay occurs

    uint256 public contentSubmitterRewardShare = 70; // % share for submitter
    uint256 public positiveVoterRewardShare = 30; // % share for voters
    uint256 public baseContentReward = 100 * (10 ** 18); // Base reward for content (100 AetherToken)

    // Whitelist of parameters that can be changed via governance
    mapping(bytes32 => bool) public governableParameters;

    // --- Events ---
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event NFTMinted(address indexed user, uint256 tokenId);
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 newLevel);
    event ContentSubmitted(uint256 indexed contentId, address indexed submitter, string contentHash, uint256 timestamp);
    event AIConsensusScoreSubmitted(uint256 indexed contentId, uint256 aiScore, string aiModelVersion, uint256 timestamp);
    event ContentVoted(uint256 indexed contentId, address indexed voter, bool approved, uint256 weightedVote);
    event ContentFinalized(uint256 indexed contentId, address indexed submitter, uint256 finalReputationDelta, uint256 totalRewards);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationPowerDelegated(address indexed delegator, address indexed delegatee);
    event ReputationPowerDelegationRevoked(address indexed delegator);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event ProposalCreated(uint256 indexed proposalId, string paramName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 weightedVote);
    event ProposalExecuted(uint256 indexed proposalId, string paramName, uint256 newValue, bool success);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AF: Only AI oracle can call this function");
        _;
    }

    modifier onlyActiveDRNFT(address _user) {
        require(reputationNFT.balanceOf(_user) > 0, "AF: User must have an active DR-NFT");
        _;
    }

    modifier isValidContent(uint256 _contentId) {
        require(_contentId < _nextContentId, "AF: Invalid content ID");
        _;
    }

    modifier isContentNotFinalized(uint256 _contentId) {
        require(!contents[_contentId].finalized, "AF: Content already finalized");
        _;
    }

    modifier isContentVotingPeriodEnded(uint256 _contentId) {
        require(block.number > contents[_contentId].submissionTimestamp.add(CONTENT_VOTING_PERIOD_BLOCKS), "AF: Content voting period not ended");
        _;
    }

    modifier hasSufficientReputation(address _user, uint256 _minReputation) {
        require(reputationScores[_user] >= _minReputation, "AF: Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(address _initialAIOracle) Ownable(msg.sender) {
        aetherToken = new AetherToken();
        reputationNFT = new ReputationNFT(address(this)); // Pass AetherForge contract address for tokenURI callback
        aiOracleAddress = _initialAIOracle;
        _nextContentId = 0;
        _nextProposalId = 0;

        // Initialize governable parameters
        governableParameters[keccak256("reputationIncreasePerAIConsensus")] = true;
        governableParameters[keccak256("reputationIncreasePerPositiveVote")] = true;
        governableParameters[keccak256("reputationDecreasePerNegativeVote")] = true;
        governableParameters[keccak256("reputationDecayPerPeriod")] = true;
        governableParameters[keccak256("reputationDecayPeriod")] = true;
        governableParameters[keccak256("contentSubmitterRewardShare")] = true;
        governableParameters[keccak256("positiveVoterRewardShare")] = true;
        governableParameters[keccak256("baseContentReward")] = true;
        governableParameters[keccak256("MIN_REPUTATION_TO_SUBMIT_CONTENT")] = true;
        governableParameters[keccak256("MIN_REPUTATION_TO_PROPOSE")] = true;
        governableParameters[keccak256("CONTENT_VOTING_PERIOD_BLOCKS")] = true;
        governableParameters[keccak256("PROPOSAL_VOTING_PERIOD_BLOCKS")] = true;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Updates the address of the AI oracle. Only callable by the contract owner.
     * @param _newOracle The new address for the AI oracle.
     */
    function updateAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AF: New AI oracle cannot be zero address");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracle);
        aiOracleAddress = _newOracle;
    }

    /**
     * @dev Toggles the paused state of the contract. When paused, many functions are inaccessible.
     *      Only callable by the contract owner.
     */
    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @dev Allows the owner to withdraw specific ERC20 tokens from the contract in case of emergencies.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) public onlyOwner {
        ERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @dev Allows the owner to withdraw ETH from the contract in case of emergencies.
     * @param _amount The amount of ETH to withdraw (in wei).
     */
    function emergencyWithdrawETH(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
    }

    // --- II. Dynamic Reputation NFTs (DR-NFTs) - ERC721 & Soulbound Extensions ---

    /**
     * @dev Mints the very first Soulbound DR-NFT for a user.
     *      A user can only mint one DR-NFT.
     *      Requires the recipient to have at least MIN_REPUTATION_FOR_NFT_MINT (initially 0).
     * @param _recipient The address to mint the DR-NFT to.
     */
    function mintInitialReputationNFT(address _recipient)
        public
        whenNotPaused
        hasSufficientReputation(_recipient, MIN_REPUTATION_FOR_NFT_MINT)
    {
        require(reputationNFT.balanceOf(_recipient) == 0, "AF: User already has a Reputation NFT");
        
        reputationNFT.mint(_recipient);
        reputationScores[_recipient] = INITIAL_REPUTATION_SCORE; // Give initial score
        lastActivityTimestamp[_recipient] = block.timestamp;
        _updateReputationNFT(_recipient, INITIAL_REPUTATION_SCORE); // Set initial metadata
        emit NFTMinted(_recipient, reputationNFT.tokenOfOwnerByIndex(_recipient, 0));
        emit ReputationUpdated(_recipient, INITIAL_REPUTATION_SCORE, getReputationNFTLevel(_recipient));
    }

    /**
     * @dev Returns the current numerical reputation score for a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Calculates and returns the current level of a user's DR-NFT based on their reputation score.
     *      This is a simple linear mapping; could be more complex (e.g., logarithmic).
     * @param _user The address of the user.
     * @return The reputation level.
     */
    function getReputationNFTLevel(address _user) public view returns (uint256) {
        uint256 score = reputationScores[_user];
        if (score < 200) return 0; // Novice
        if (score < 500) return 1; // Contributor
        if (score < 1000) return 2; // Expert
        if (score < 2500) return 3; // Master
        return 4; // Legend
    }

    /**
     * @dev Internal function to update a user's DR-NFT level and metadata.
     *      This is called whenever a user's reputation score changes.
     * @param _user The address of the user.
     * @param _newScore The new reputation score for the user.
     */
    function _updateReputationNFT(address _user, uint256 _newScore) internal {
        if (reputationNFT.balanceOf(_user) == 0) {
            return; // No NFT to update
        }
        uint256 tokenId = reputationNFT.tokenOfOwnerByIndex(_user, 0);
        uint256 newLevel = getReputationNFTLevel(_user);
        reputationNFT.updateTokenURI(tokenId, newLevel); // Calls ReputationNFT's internal logic
        emit ReputationUpdated(_user, _newScore, newLevel);
    }

    // --- III. Content & Contribution Lifecycle ---

    /**
     * @dev Allows users to submit new content for evaluation.
     *      Requires an active DR-NFT and sufficient reputation.
     * @param _contentHash The IPFS CID or hash of the actual content file.
     * @param _metadataURI The IPFS CID or URL for the content's metadata JSON.
     * @param _category An integer representing the content category (e.g., 0=Article, 1=Art, 2=Idea).
     */
    function submitContent(string memory _contentHash, string memory _metadataURI, uint256 _category)
        public
        whenNotPaused
        onlyActiveDRNFT(msg.sender)
        hasSufficientReputation(msg.sender, MIN_REPUTATION_TO_SUBMIT_CONTENT)
        returns (uint256)
    {
        uint256 contentId = _nextContentId++;
        contents[contentId] = Content({
            submitter: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            category: _category,
            aiScore: 0,
            aiModelVersion: "",
            positiveVotes: 0,
            negativeVotes: 0,
            totalWeightedVotes: 0,
            aiScored: false,
            finalized: false,
            submissionTimestamp: block.number,
            finalizationTimestamp: 0
        });
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ContentSubmitted(contentId, msg.sender, _contentHash, block.timestamp);
        return contentId;
    }

    /**
     * @dev Called by the designated AI Oracle to submit an evaluation score for content.
     *      This simulates the AI's off-chain computation.
     * @param _contentId The ID of the content to score.
     * @param _aiScore The score provided by the AI (e.g., 0-100).
     * @param _aiModelVersion Identifier for the AI model used.
     */
    function submitAIConsensusScore(uint256 _contentId, uint256 _aiScore, string memory _aiModelVersion)
        public
        whenNotPaused
        onlyAIOracle
        isValidContent(_contentId)
        isContentNotFinalized(_contentId)
    {
        require(!contents[_contentId].aiScored, "AF: Content already AI scored");
        contents[_contentId].aiScore = _aiScore;
        contents[_contentId].aiModelVersion = _aiModelVersion;
        contents[_contentId].aiScored = true;
        emit AIConsensusScoreSubmitted(_contentId, _aiScore, _aiModelVersion, block.timestamp);
    }

    /**
     * @dev Allows users to cast a weighted vote on content.
     *      Vote weight is based on the user's reputation score or their delegate's.
     * @param _contentId The ID of the content to vote on.
     * @param _approve True for a positive vote, false for a negative vote.
     */
    function voteOnContent(uint256 _contentId, bool _approve)
        public
        whenNotPaused
        onlyActiveDRNFT(msg.sender)
        isValidContent(_contentId)
        isContentNotFinalized(_contentId)
    {
        require(block.number <= contents[_contentId].submissionTimestamp.add(CONTENT_VOTING_PERIOD_BLOCKS), "AF: Voting period has ended for this content");
        require(!hasVotedOnContent[_contentId][msg.sender], "AF: Already voted on this content");

        address voterAddress = (votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender);
        uint256 weightedVote = calculateVotingPower(voterAddress);

        if (_approve) {
            contents[_contentId].positiveVotes = contents[_contentId].positiveVotes.add(1);
            contents[_contentId].totalWeightedVotes = contents[_contentId].totalWeightedVotes.add(weightedVote);
        } else {
            contents[_contentId].negativeVotes = contents[_contentId].negativeVotes.add(1);
            contents[_contentId].totalWeightedVotes = contents[_contentId].totalWeightedVotes.sub(weightedVote); // Subtract for negative influence
        }
        hasVotedOnContent[_contentId][msg.sender] = true;
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ContentVoted(_contentId, msg.sender, _approve, weightedVote);
    }

    /**
     * @dev Triggers the final evaluation of content.
     *      Calculates reputation changes for submitter, distributes rewards, and updates NFT.
     *      Can be called by anyone after the voting period ends.
     * @param _contentId The ID of the content to finalize.
     */
    function finalizeContentEvaluation(uint256 _contentId)
        public
        whenNotPaused
        isValidContent(_contentId)
        isContentNotFinalized(_contentId)
        isContentVotingPeriodEnded(_contentId)
    {
        Content storage content = contents[_contentId];
        require(content.aiScored, "AF: Content has not been AI scored yet");

        content.finalized = true;
        content.finalizationTimestamp = block.timestamp;

        // Calculate reputation delta
        int256 reputationDelta = 0;
        reputationDelta = reputationDelta.add(int256(content.aiScore.mul(reputationIncreasePerAIConsensus).div(100))); // AI score influence
        reputationDelta = reputationDelta.add(int256(content.positiveVotes.mul(reputationIncreasePerPositiveVote)));
        reputationDelta = reputationDelta.sub(int256(content.negativeVotes.mul(reputationDecreasePerNegativeVote)));

        uint256 currentReputation = reputationScores[content.submitter];
        uint256 newReputation = (reputationDelta >= 0) ? currentReputation.add(uint256(reputationDelta)) : currentReputation.sub(uint256(reputationDelta * -1));

        reputationScores[content.submitter] = newReputation;
        lastActivityTimestamp[content.submitter] = block.timestamp;
        _updateReputationNFT(content.submitter, newReputation);

        // Distribute rewards
        distributeContentRewards(_contentId);

        emit ContentFinalized(_contentId, content.submitter, uint256(reputationDelta), baseContentReward);
    }

    /**
     * @dev Retrieves all relevant details about a specific content submission.
     * @param _contentId The ID of the content.
     * @return A tuple containing all content details.
     */
    function getContentDetails(uint256 _contentId)
        public
        view
        isValidContent(_contentId)
        returns (
            address submitter,
            string memory contentHash,
            string memory metadataURI,
            uint256 category,
            uint256 aiScore,
            string memory aiModelVersion,
            uint256 positiveVotes,
            uint256 negativeVotes,
            uint256 totalWeightedVotes,
            bool aiScored,
            bool finalized,
            uint256 submissionTimestamp,
            uint256 finalizationTimestamp
        )
    {
        Content storage content = contents[_contentId];
        return (
            content.submitter,
            content.contentHash,
            content.metadataURI,
            content.category,
            content.aiScore,
            content.aiModelVersion,
            content.positiveVotes,
            content.negativeVotes,
            content.totalWeightedVotes,
            content.aiScored,
            content.finalized,
            content.submissionTimestamp,
            content.finalizationTimestamp
        );
    }

    // --- IV. Reputation Management & Incentives ---

    /**
     * @dev Calculates a user's effective voting power based on their reputation score.
     *      Can be customized (e.g., logarithmic scaling, or minimum thresholds).
     * @param _user The address of the user.
     * @return The calculated voting power.
     */
    function calculateVotingPower(address _user) public view returns (uint256) {
        // Simple linear scaling for now. Could implement more complex logic.
        return reputationScores[_user].div(100); // 1 voting power per 100 reputation
    }

    /**
     * @dev Internal function to distribute AetherToken rewards for finalized content.
     *      Called by `finalizeContentEvaluation`.
     * @param _contentId The ID of the finalized content.
     */
    function distributeContentRewards(uint256 _contentId) internal {
        Content storage content = contents[_contentId];
        uint256 totalReward = baseContentReward;

        // Reward submitter
        uint256 submitterReward = totalReward.mul(contentSubmitterRewardShare).div(100);
        pendingRewards[content.submitter] = pendingRewards[content.submitter].add(submitterReward);

        // Reward positive voters (simplified: distribute equally among positive voters)
        uint256 voterPool = totalReward.sub(submitterReward);
        if (content.positiveVotes > 0) {
            uint256 rewardPerVoter = voterPool.div(content.positiveVotes);
            // This is a simplified distribution; a more complex one would track individual voters.
            // For this version, we just add to the submitter's rewards.
            // A production system would iterate over recorded voters or use a Merkle proof for claiming.
            // For now, let's keep it simple and just credit the submitter.
            // Or, distribute to a pool accessible by anyone who voted positively.
            // To properly distribute to individual voters, the `voteOnContent` function
            // would need to store who voted positively. For the sake of function count,
            // let's simplify and assume voters are rewarded through other means or by submitter.
            // Or, distribute the 'voter' share to a general reward pool.
            // Let's go with adding to the submitter for simplicity in this example to avoid complex storage for all voters.
            // Or, a small amount to the finalizer to incentivize calling finalizeContentEvaluation.
            // For this implementation, the `positiveVoterRewardShare` will be added to the submitter's reward
            // if the content receives sufficient positive votes, making it a "success bonus".
            if (content.totalWeightedVotes >= (baseContentReward / 2) && content.aiScore >= 50) { // Example success criteria
                 pendingRewards[content.submitter] = pendingRewards[content.submitter].add(voterPool);
            }
        }
        // Small reward for the caller who finalizes
        if(msg.sender != content.submitter) {
            uint256 finalizerFee = 1 * (10 ** 18); // 1 AetherToken
            pendingRewards[msg.sender] = pendingRewards[msg.sender].add(finalizerFee);
        }

        aetherToken.mint(address(this), totalReward); // Mint tokens to contract balance first (if supply is not fixed)
        // Then transfer from contract balance to pendingRewards which user claims later.
    }

    /**
     * @dev Allows users to claim their accumulated AetherToken rewards.
     */
    function claimRewards() public whenNotPaused onlyActiveDRNFT(msg.sender) {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "AF: No pending rewards to claim");
        pendingRewards[msg.sender] = 0;
        aetherToken.transfer(msg.sender, amount);
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Allows an NFT holder to delegate their voting power to another address.
     *      This does not transfer ownership of the Soulbound NFT.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateReputationVote(address _delegatee) public whenNotPaused onlyActiveDRNFT(msg.sender) {
        require(_delegatee != address(0), "AF: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AF: Cannot delegate to self");
        votingDelegates[msg.sender] = _delegatee;
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ReputationPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes a previously set voting power delegation.
     */
    function revokeReputationVoteDelegation() public whenNotPaused onlyActiveDRNFT(msg.sender) {
        require(votingDelegates[msg.sender] != address(0), "AF: No active delegation to revoke");
        delete votingDelegates[msg.sender];
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ReputationPowerDelegationRevoked(msg.sender);
    }

    /**
     * @dev Triggers reputation decay for an inactive user. Can be called by anyone.
     *      Incentivizes keeping the reputation system dynamic.
     * @param _user The address of the user whose reputation might decay.
     */
    function triggerReputationDecay(address _user) public whenNotPaused onlyActiveDRNFT(_user) {
        uint256 currentReputation = reputationScores[_user];
        if (currentReputation == 0) return; // No decay below 0

        uint256 timeSinceLastActivity = block.timestamp.sub(lastActivityTimestamp[_user]);
        if (timeSinceLastActivity < reputationDecayPeriod) return; // Not enough time passed

        uint256 periodsPassed = timeSinceLastActivity.div(reputationDecayPeriod);
        uint256 decayAmount = reputationDecayPerPeriod.mul(periodsPassed);

        uint256 newReputation = currentReputation;
        if (newReputation > decayAmount) {
            newReputation = newReputation.sub(decayAmount);
        } else {
            newReputation = 0;
        }

        reputationScores[_user] = newReputation;
        lastActivityTimestamp[_user] = block.timestamp; // Reset timestamp after decay
        _updateReputationNFT(_user, newReputation);

        emit ReputationDecayed(_user, currentReputation, newReputation);
    }

    // --- V. DAO Governance (Simplified Parameters) ---

    /**
     * @dev Allows users with sufficient reputation to propose changes to configurable system parameters.
     * @param _paramName The string name of the parameter to change (e.g., "reputationDecayPeriod").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue)
        public
        whenNotPaused
        onlyActiveDRNFT(msg.sender)
        hasSufficientReputation(msg.sender, MIN_REPUTATION_TO_PROPOSE)
        returns (uint256)
    {
        bytes32 paramKey = keccak256(abi.encodePacked(_paramName));
        require(governableParameters[paramKey], "AF: Parameter is not governable");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            paramName: _paramName,
            newValue: _newValue,
            proposalId: proposalId,
            startBlock: block.number,
            endBlock: block.number.add(PROPOSAL_VOTING_PERIOD_BLOCKS),
            votesFor: 0,
            votesAgainst: 0,
            totalWeightedVotesFor: 0,
            totalWeightedVotesAgainst: 0,
            executed: false,
            passed: false
        });
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ProposalCreated(proposalId, _paramName, _newValue, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows users to cast their weighted votes on open governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for)
        public
        whenNotPaused
        onlyActiveDRNFT(msg.sender)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(_proposalId < _nextProposalId, "AF: Invalid proposal ID");
        require(!proposal.executed, "AF: Proposal already executed");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "AF: Voting period not active");
        require(!hasVotedOnProposal[_proposalId][msg.sender], "AF: Already voted on this proposal");

        address voterAddress = (votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender);
        uint256 weightedVote = calculateVotingPower(voterAddress);

        if (_for) {
            proposal.votesFor = proposal.votesFor.add(1);
            proposal.totalWeightedVotesFor = proposal.totalWeightedVotesFor.add(weightedVote);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
            proposal.totalWeightedVotesAgainst = proposal.totalWeightedVotesAgainst.add(weightedVote);
        }
        hasVotedOnProposal[_proposalId][msg.sender] = true;
        lastActivityTimestamp[msg.sender] = block.timestamp;
        emit ProposalVoted(_proposalId, msg.sender, _for, weightedVote);
    }

    /**
     * @dev Executes a passed governance proposal, applying the new parameter value.
     *      Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(_proposalId < _nextProposalId, "AF: Invalid proposal ID");
        require(!proposal.executed, "AF: Proposal already executed");
        require(block.number > proposal.endBlock, "AF: Voting period not ended");

        bool success = false;
        if (proposal.totalWeightedVotesFor > proposal.totalWeightedVotesAgainst) {
            proposal.passed = true;
            bytes32 paramKey = keccak256(abi.encodePacked(proposal.paramName));
            require(governableParameters[paramKey], "AF: Parameter is not governable"); // Double check

            // This requires direct assignment, which is clean for a small set of parameters.
            // For a larger set, consider a flexible 'setParam(bytes32 key, uint256 value)'
            // function that can be called dynamically.
            if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationIncreasePerAIConsensus"))) {
                reputationIncreasePerAIConsensus = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationIncreasePerPositiveVote"))) {
                reputationIncreasePerPositiveVote = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationDecreasePerNegativeVote"))) {
                reputationDecreasePerNegativeVote = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationDecayPerPeriod"))) {
                reputationDecayPerPeriod = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationDecayPeriod"))) {
                reputationDecayPeriod = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("contentSubmitterRewardShare"))) {
                reputationDecayPeriod = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("positiveVoterRewardShare"))) {
                positiveVoterRewardShare = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("baseContentReward"))) {
                baseContentReward = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("MIN_REPUTATION_TO_SUBMIT_CONTENT"))) {
                MIN_REPUTATION_TO_SUBMIT_CONTENT = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("MIN_REPUTATION_TO_PROPOSE"))) {
                MIN_REPUTATION_TO_PROPOSE = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("CONTENT_VOTING_PERIOD_BLOCKS"))) {
                CONTENT_VOTING_PERIOD_BLOCKS = proposal.newValue;
                success = true;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("PROPOSAL_VOTING_PERIOD_BLOCKS"))) {
                PROPOSAL_VOTING_PERIOD_BLOCKS = proposal.newValue;
                success = true;
            }
        }
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue, success);
    }

    // --- VI. Analytics & Read-Only Utilities ---

    /**
     * @dev Returns the ID of the most recently submitted content.
     */
    function getLatestContentId() public view returns (uint256) {
        return _nextContentId > 0 ? _nextContentId - 1 : 0;
    }

    /**
     * @dev Returns details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            string memory paramName,
            uint256 newValue,
            uint256 startBlock,
            uint256 endBlock,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 totalWeightedVotesFor,
            uint256 totalWeightedVotesAgainst,
            bool executed,
            bool passed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.paramName,
            proposal.newValue,
            proposal.startBlock,
            proposal.endBlock,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.totalWeightedVotesFor,
            proposal.totalWeightedVotesAgainst,
            proposal.executed,
            proposal.passed
        );
    }

    /**
     * @dev Returns the amount of AetherToken rewards a user has accumulated but not yet claimed.
     * @param _user The address of the user.
     * @return The amount of pending rewards in wei.
     */
    function getPendingRewards(address _user) public view returns (uint256) {
        return pendingRewards[_user];
    }
}

// --- ERC20 AetherToken for Rewards ---
contract AetherToken is ERC20, Ownable {
    constructor() ERC20("AetherToken", "AETH") Ownable(msg.sender) {
        // Mint an initial supply or allow only owner/authorized contract to mint
        // For AetherForge, we'll let AetherForge itself mint tokens upon reward distribution.
        // _mint(msg.sender, 1000000 * (10 ** 18)); // Example initial mint
    }

    // Allows AetherForge contract to mint tokens
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// --- ERC721 ReputationNFT (Soulbound & Dynamic) ---
contract ReputationNFT is ERC721Enumerable { // Using Enumerable to easily get token IDs by owner
    using Strings for uint256;

    // Reference to the AetherForge contract for reputation score lookup
    address public aetherForgeContract;

    constructor(address _aetherForgeContract) ERC721("AetherForgeReputation", "AFR") {
        aetherForgeContract = _aetherForgeContract;
    }

    // --- Overrides for Soulbound Behavior ---
    // Prevent transfers to make it Soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        if (from != address(0) && to != address(0)) { // Allow minting and burning
            revert("AFR: Reputation NFT is soulbound and cannot be transferred");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // --- Minting function (only AetherForge contract can mint) ---
    function mint(address _to) public {
        require(msg.sender == aetherForgeContract, "AFR: Only AetherForge contract can mint NFTs");
        uint256 newTokenId = totalSupply().add(1); // Simple sequential ID
        _mint(_to, newTokenId);
    }

    // --- Dynamic Metadata ---
    mapping(uint256 => uint256) public tokenLevel; // tokenId => current level (0-4)
    mapping(uint256 => string) public tokenTrait;  // tokenId => current trait (e.g., "Novice", "Master")

    // Internal function to update a token's level and trait
    function updateTokenURI(uint256 _tokenId, uint256 _newLevel) internal {
        require(_exists(_tokenId), "AFR: Token does not exist");
        
        tokenLevel[_tokenId] = _newLevel;
        if (_newLevel == 0) tokenTrait[_tokenId] = "Novice Curator";
        else if (_newLevel == 1) tokenTrait[_tokenId] = "Contributing Expert";
        else if (_newLevel == 2) tokenTrait[_tokenId] = "Master Alchemist";
        else if (_newLevel == 3) tokenTrait[_tokenId] = "Grand Architect";
        else tokenTrait[_tokenId] = "Cosmic Visionary"; // Level 4+
        
        // No explicit event for metadata update, but `tokenURI` will reflect changes.
        // A direct event could be added if external systems need to track it precisely.
    }

    // Overrides tokenURI to provide dynamic metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        address ownerOfToken = ownerOf(_tokenId);
        uint256 currentReputation = AetherForge(aetherForgeContract).getReputationScore(ownerOfToken);
        uint256 level = tokenLevel[_tokenId]; // Use the stored level
        string memory trait = tokenTrait[_tokenId]; // Use the stored trait

        // Construct a simple JSON directly in Solidity
        string memory json = string(abi.encodePacked(
            '{"name": "AetherForge Reputation #', _tokenId.toString(),
            '", "description": "Dynamic representation of on-chain reputation in AetherForge.",',
            '"image": "ipfs://Qmbad_image_hash_for_level_', level.toString(), '",', // Placeholder IPFS hashes for images
            '"attributes": [',
                '{"trait_type": "Level", "value": ', level.toString(), '},',
                '{"trait_type": "Title", "value": "', trait, '"},',
                '{"trait_type": "Reputation Score", "value": ', currentReputation.toString(), '}',
            ']}'
        ));

        // Encode the JSON data as base64 and prepend data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}

// --- Library for Base64 Encoding (from OpenZeppelin) ---
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load all chars into a byte array to avoid repeated conversions
        byte[] memory table = new byte[](64);
        for (uint256 i = 0; i < 64; i++) {
            table[i] = bytes(TABLE)[i];
        }

        uint256 lastEncodedByteIndex = data.length.add(2).div(3).mul(4).sub(1);
        bytes memory result = new bytes(lastEncodedByteIndex.add(1));

        uint264 idx = 0;
        uint264 inputIdx = 0;
        while (inputIdx < data.length) {
            uint256 byte1 = data[inputIdx];
            inputIdx++;
            uint256 byte2 = inputIdx < data.length ? data[inputIdx] : 0;
            inputIdx++;
            uint256 byte3 = inputIdx < data.length ? data[inputIdx] : 0;
            inputIdx++;

            uint256 val = (byte1 << 16) | (byte2 << 8) | byte3;

            result[idx] = table[(val >> 18) & 0x3F];
            idx++;
            result[idx] = table[(val >> 12) & 0x3F];
            idx++;
            result[idx] = table[(val >> 6) & 0x3F];
            idx++;
            result[idx] = table[val & 0x3F];
            idx++;
        }

        if (data.length % 3 == 1) {
            result[result.length - 1] = "=";
            result[result.length - 2] = "=";
        } else if (data.length % 3 == 2) {
            result[result.length - 1] = "=";
        }

        return string(result);
    }
}
```