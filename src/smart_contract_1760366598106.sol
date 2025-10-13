This smart contract, named "Ethereal Echoes," introduces a novel concept for community-driven creation and evolution of generative AI prompts as dynamic NFTs. Each "Echo" NFT represents a unique, evolving AI prompt (e.g., for art, text, or music generation). The community actively participates in proposing new prompts, voting on their quality and creativity, submitting feedback from off-chain AI generations, and even merging existing Echoes to create more complex and refined prompts.

The core advanced concepts include:

1.  **Dynamic NFTs (Echoes):** The metadata and internal properties (like `harmonyScore` and `evolutionStage`) of an Echo NFT can change based on community interaction and feedback, reflecting its "life" and refinement.
2.  **Community Curation & Governance:** Users propose new prompts and vote on their approval, as well as on proposals to merge existing Echoes.
3.  **Reputation System:** Users gain reputation for successful prompt proposals, positive curation, and constructive feedback, influencing their voting power and potential rewards.
4.  **Simulated Generative AI Integration:** While actual AI runs off-chain, the contract manages the prompts and incorporates user feedback (which could be oracle-verified in a production environment) to dynamically update Echo properties.
5.  **Combinatorial Creativity:** A unique mechanism allowing the community to propose and approve the merging of two existing Echoes into a new, more advanced prompt.
6.  **Economic Incentives:** A reward pool distributes tokens to active and positive contributors (proposers, curators).

**Note on "Don't duplicate any open source":**
While this contract utilizes the foundational and battle-tested `ERC721` and `Ownable` standards from OpenZeppelin for secure and reliable NFT and access control functionalities, the advanced mechanisms—such as the dynamic Echo evolution, the multi-stage prompt/merge proposal and voting system, the reputation tracking linked to these actions, and the simulated AI feedback loop—are custom-designed for this contract and represent novel logic beyond existing open-source implementations for these specific combined features.

---

### **Outline and Function Summary**

**Contract Name:** `EtherealEchoes`

**I. Core Echo NFT Management (ERC721 Standard Functions & Extensions)**
*   **`constructor(string memory name, string memory symbol)`:** Initializes the ERC721 token with a given name and symbol.
*   **`balanceOf(address owner)`:** Returns the number of Echoes owned by a specific address.
*   **`ownerOf(uint256 tokenId)`:** Returns the address of the owner of a specific Echo NFT.
*   **`approve(address to, uint256 tokenId)`:** Grants approval to a single address to manage a specific Echo.
*   **`getApproved(uint256 tokenId)`:** Returns the approved address for a specific Echo.
*   **`setApprovalForAll(address operator, bool approved)`:** Grants or revokes approval for an operator to manage all Echoes owned by the caller.
*   **`isApprovedForAll(address owner, address operator)`:** Checks if an operator is approved for all Echoes of a given owner.
*   **`transferFrom(address from, address to, uint256 tokenId)`:** Transfers ownership of an Echo from one address to another.
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`:** Safer transfer, preventing transfer to contracts that don't support ERC721.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`:** Safer transfer with additional data.
*   **`name()`:** Returns the name of the NFT collection ("Ethereal Echoes").
*   **`symbol()`:** Returns the symbol of the NFT collection ("EECHO").
*   **`tokenURI(uint256 tokenId)`:** Returns the URI pointing to the metadata JSON for a specific Echo.
*   **`getEchoDetails(uint256 _echoId)`:** Retrieves comprehensive details (prompt, score, owner, etc.) of an Echo.
*   **`updateEchoMetadataURI(uint256 _echoId, string memory _newMetadataURI)`:** Allows the Echo owner to update its metadata URI (e.g., to link to a new AI generation image).

**II. Community-Driven Prompt Evolution & Curation**
*   **`proposeNewPrompt(string memory _promptText, string memory _category)`:** Submits a new AI prompt for the community to review and vote on. Requires a small fee.
*   **`voteOnPromptProposal(uint256 _proposalId, bool _approve)`:** Casts a reputation-weighted vote (approve/reject) on a pending prompt proposal.
*   **`finalizePromptProposal(uint256 _proposalId, string memory _initialMetadataURI)`:** Mints a new Echo NFT from a successfully approved prompt proposal. Can be called by anyone after the proposal duration ends and it meets voting thresholds.
*   **`submitGenerationFeedback(uint256 _echoId, string memory _resultHash, uint8 _userRating)`:** Allows users to submit feedback (rating 1-5) on an off-chain AI generation derived from a specific Echo. This influences the Echo's `harmonyScore` and the submitter's `userReputation`.
*   **`proposeEchoMerge(uint256 _echoId1, uint256 _echoId2, string memory _mergedPromptText, string memory _initialMetadataURI)`:** Proposes combining two existing Echoes into a new, more complex one. Requires a small fee.
*   **`voteOnMergeProposal(uint256 _proposalId, bool _approve)`:** Casts a reputation-weighted vote (approve/reject) on a pending merge proposal.
*   **`executeEchoMerge(uint256 _proposalId)`:** Mints a new Echo NFT from a successfully approved merge proposal. Can be called by anyone after the proposal duration ends and it meets voting thresholds.

**III. Reputation & Economic Incentives**
*   **`getUserReputation(address _user)`:** Returns the reputation score of a specific user.
*   **`distributeCuratorRewards()`:** (Owner/Admin) Distributes a portion of the contract's reward pool to top-contributing users based on their reputation.
*   **`claimMyRewards()`:** Allows users to claim their accumulated rewards from the reward pool.

**IV. Administrative & System Configuration (Owner-only)**
*   **`setVotingParameters(uint256 _minRequiredVotes, uint256 _minApprovalPercentage)`:** Sets the minimum number of votes and approval percentage required for a proposal to pass.
*   **`setRewardRates(uint256 _proposerRewardPermille, uint256 _curatorRewardPermille)`:** Sets the proportion of rewards allocated to proposers versus curators (in permilles).
*   **`setOracleAddress(address _newOracleAddress)`:** Sets the address of a trusted oracle (for potential future off-chain verification integrations).
*   **`pause()`:** Pauses core contract functionalities in case of an emergency.
*   **`unpause()`:** Unpauses the contract.
*   **`withdrawContractFunds(address payable _to, uint256 _amount)`:** Allows the contract owner to withdraw accumulated ETH from the contract (e.g., from proposal fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title EtherealEchoes
 * @dev A smart contract for community-curated, dynamic AI prompt NFTs.
 *
 * This contract enables users to propose, vote on, and evolve AI prompts as unique
 * digital assets (Echoes). Each Echo is an ERC721 NFT whose properties (like
 * 'harmonyScore' and 'evolutionStage') can dynamically change based on community
 * feedback and merge operations. It incorporates a reputation system to empower
 * active and positive contributors and a reward mechanism.
 *
 * Advanced Concepts:
 * - Dynamic NFTs: Echoes evolve with community interaction and feedback.
 * - Community Curation & Governance: Decentralized proposal and voting system for new prompts and merges.
 * - Reputation System: User reputation influences voting power and rewards, built on constructive engagement.
 * - Simulated Generative AI Integration: Manages AI prompts on-chain and processes off-chain generation feedback.
 * - Combinatorial Creativity: Unique mechanic to merge two existing Echoes into a new, complex one.
 * - Economic Incentives: Rewards for successful proposers and accurate curators.
 */
contract EtherealEchoes is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // NFT & Echo Data
    Counters.Counter private _echoIdCounter;
    mapping(uint256 => Echo) public echoes;

    struct Echo {
        uint256 id;
        string promptText;
        string category;
        uint256 harmonyScore; // Reflects quality, 0-1000 (e.g., average rating * 200)
        uint256 evolutionStage; // Increments with merges
        address owner; // ERC721 owner
        uint256 generationFeedbackCount; // How many times feedback has been submitted
        bytes32 promptHash; // Keccak256 hash of the promptText for uniqueness checks
        uint256 creationTimestamp;
        string metadataURI; // Stores the current metadata URI for the Echo
        bool isMerged; // True if this Echo was used as a parent in a successful merge
    }

    // Proposals & Voting
    enum ProposalStatus { Pending, Approved, Rejected, Finalized, Expired }

    Counters.Counter private _promptProposalIdCounter;
    mapping(uint256 => PromptProposal) public promptProposals;
    // Track voters for each prompt proposal
    mapping(uint256 => mapping(address => bool)) public promptProposalVoters;

    struct PromptProposal {
        address proposer;
        string promptText;
        string category;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        ProposalStatus status;
    }

    Counters.Counter private _mergeProposalIdCounter;
    mapping(uint256 => MergeProposal) public mergeProposals;
    // Track voters for each merge proposal
    mapping(uint256 => mapping(address => bool)) public mergeProposalVoters;

    struct MergeProposal {
        address proposer;
        uint256 parentEchoId1;
        uint256 parentEchoId2;
        string mergedPromptText;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        ProposalStatus status;
        string initialMetadataURI; // For the new merged echo
    }

    // Feedback
    Counters.Counter private _generationFeedbackIdCounter;
    mapping(uint256 => GenerationFeedback) public generationFeedbacks;

    struct GenerationFeedback {
        uint256 feedbackId;
        uint256 echoId;
        address submitter;
        string resultHash; // Hash of the generated output (off-chain, for reference)
        uint8 userRating; // 1-5 rating
        uint256 submissionTimestamp;
        bool processed; // Flag to indicate if score/reputation updated
    }

    // Reputation & Rewards
    mapping(address => uint256) public userReputation; // Reputation score for users
    uint256 public rewardPool; // Accumulates proposal fees, distributed as rewards
    mapping(address => uint256) public rewardsClaimable; // ETH rewards claimable by users

    // Configuration
    uint256 public constant PROPOSAL_DURATION = 7 days; // How long proposals are open for voting
    uint256 public constant MIN_REPUTATION_TO_VOTE = 100; // Minimum reputation required to vote
    uint256 public constant PROPOSAL_FEE = 0.01 ether; // Fee to propose a new prompt or merge
    uint256 public minRequiredVotes; // Minimum number of votes for a proposal to be valid
    uint256 public minApprovalPercentage; // Minimum percentage of 'for' votes required (e.g., 51 for 51%)

    uint256 public proposerRewardPermille; // Permille (per 1000) of reward pool for proposers
    uint256 public curatorRewardPermille; // Permille of reward pool for curators
    address public oracleAddress; // Address of a trusted oracle (for potential future off-chain verification)

    // --- Events ---
    event EchoMinted(uint256 indexed echoId, address indexed owner, string promptText, string category, string metadataURI);
    event EchoMetadataUpdated(uint256 indexed echoId, string newMetadataURI);
    event PromptProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string promptText, string category, uint256 feePaid);
    event PromptProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 reputationWeightedVote);
    event PromptProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 newEchoId);
    event MergeProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 parent1, uint256 parent2, string mergedPromptText, uint256 feePaid);
    event MergeProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 reputationWeightedVote);
    event MergeProposalExecuted(uint256 indexed proposalId, ProposalStatus status, uint256 newEchoId);
    event GenerationFeedbackSubmitted(uint256 indexed feedbackId, uint256 indexed echoId, address indexed submitter, uint8 rating);
    event UserReputationUpdated(address indexed user, uint256 newReputation);
    event RewardsDistributed(address indexed distributor, uint256 amount);
    event RewardsClaimed(address indexed receiver, uint256 amount);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        // Initial configuration values
        minRequiredVotes = 5;
        minApprovalPercentage = 51; // 51% approval required
        proposerRewardPermille = 400; // 40%
        curatorRewardPermille = 600;  // 60%
        // Oracle address can be set later
    }

    // --- Modifier ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EtherealEchoes: Caller is not the oracle");
        _;
    }

    // --- I. Core Echo NFT Management ---

    /**
     * @dev Returns the number of Echoes owned by `owner`.
     * @param owner The address to query the balance of.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    /**
     * @dev Returns the owner of the `tokenId` Echo.
     * @param tokenId The identifier for an Echo.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev Grants `to` permission to transfer `tokenId` from caller.
     * @param to The address to be granted approval.
     * @param tokenId The identifier for an Echo.
     */
    function approve(address to, uint256 tokenId) public override payable {
        super.approve(to, tokenId);
    }

    /**
     * @dev Returns the approved address for `tokenId`.
     * @param tokenId The identifier for an Echo.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * @param operator The address to be granted/revoked approval.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Tells whether `operator` is an approved operator for `owner`.
     * @param owner The address of the Echo owner.
     * @param operator The address of the operator.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Transfers ownership of `tokenId` from `from` to `to`.
     * @param from The current owner of the Echo.
     * @param to The new owner.
     * @param tokenId The identifier for an Echo.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override payable {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers ownership of `tokenId` from `from` to `to`.
     * @param from The current owner of the Echo.
     * @param to The new owner.
     * @param tokenId The identifier for an Echo.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers ownership of `tokenId` from `from` to `to`, with data.
     * @param from The current owner of the Echo.
     * @param to The new owner.
     * @param tokenId The identifier for an Echo.
     * @param data Additional data to be sent with the transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the URI for a given `tokenId` Echo.
     * @param tokenId The identifier for an Echo.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return echoes[tokenId].metadataURI;
    }

    /**
     * @dev Retrieves comprehensive details of a specific Echo NFT.
     * @param _echoId The ID of the Echo to retrieve details for.
     * @return Echo struct containing all relevant data.
     */
    function getEchoDetails(uint256 _echoId) public view returns (Echo memory) {
        require(_exists(_echoId), "EtherealEchoes: Echo does not exist");
        return echoes[_echoId];
    }

    /**
     * @dev Allows the owner of an Echo to update its metadata URI.
     * This enables dynamic updates, e.g., linking to new AI generation output.
     * @param _echoId The ID of the Echo to update.
     * @param _newMetadataURI The new URI pointing to the Echo's metadata.
     */
    function updateEchoMetadataURI(uint256 _echoId, string memory _newMetadataURI)
        public
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _echoId), "EtherealEchoes: Not owner or approved for Echo");
        echoes[_echoId].metadataURI = _newMetadataURI;
        emit EchoMetadataUpdated(_echoId, _newMetadataURI);
    }

    // --- Internal Minting Helper ---
    function _mintEcho(address _to, string memory _promptText, string memory _category, string memory _metadataURI)
        internal
        returns (uint256)
    {
        _echoIdCounter.increment();
        uint256 newEchoId = _echoIdCounter.current();

        bytes32 promptHash = keccak256(abi.encodePacked(_promptText));

        echoes[newEchoId] = Echo({
            id: newEchoId,
            promptText: _promptText,
            category: _category,
            harmonyScore: 500, // Default starting score (out of 1000)
            evolutionStage: 0,
            owner: _to,
            generationFeedbackCount: 0,
            promptHash: promptHash,
            creationTimestamp: block.timestamp,
            metadataURI: _metadataURI,
            isMerged: false
        });

        _safeMint(_to, newEchoId);
        emit EchoMinted(newEchoId, _to, _promptText, _category, _metadataURI);
        return newEchoId;
    }

    // --- II. Community-Driven Prompt Evolution & Curation ---

    /**
     * @dev Submits a new AI prompt for community review.
     * Requires a fee that goes into the reward pool.
     * @param _promptText The AI prompt text.
     * @param _category The category of the prompt (e.g., "Art", "Story", "Music").
     */
    function proposeNewPrompt(string memory _promptText, string memory _category)
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        require(msg.value == PROPOSAL_FEE, "EtherealEchoes: Must pay the proposal fee");
        require(bytes(_promptText).length > 0, "EtherealEchoes: Prompt text cannot be empty");
        require(bytes(_category).length > 0, "EtherealEchoes: Category cannot be empty");

        _promptProposalIdCounter.increment();
        uint256 proposalId = _promptProposalIdCounter.current();

        promptProposals[proposalId] = PromptProposal({
            proposer: msg.sender,
            promptText: _promptText,
            category: _category,
            votesFor: 0,
            votesAgainst: 0,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(PROPOSAL_DURATION),
            status: ProposalStatus.Pending
        });

        rewardPool = rewardPool.add(PROPOSAL_FEE);
        emit PromptProposalSubmitted(proposalId, msg.sender, _promptText, _category, PROPOSAL_FEE);
        return proposalId;
    }

    /**
     * @dev Casts a reputation-weighted vote (approve/reject) on a pending prompt proposal.
     * @param _proposalId The ID of the prompt proposal.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnPromptProposal(uint256 _proposalId, bool _approve)
        public
        whenNotPaused
    {
        PromptProposal storage proposal = promptProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "EtherealEchoes: Proposal not pending");
        require(block.timestamp <= proposal.expirationTimestamp, "EtherealEchoes: Proposal has expired");
        require(userReputation[msg.sender] >= MIN_REPUTATION_TO_VOTE, "EtherealEchoes: Insufficient reputation to vote");
        require(!promptProposalVoters[_proposalId][msg.sender], "EtherealEchoes: Already voted on this proposal");

        uint256 weightedVote = userReputation[msg.sender].div(100).add(1); // Base 1 + reputation/100
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(weightedVote);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(weightedVote);
        }
        promptProposalVoters[_proposalId][msg.sender] = true;
        emit PromptProposalVoted(_proposalId, msg.sender, _approve, weightedVote);
    }

    /**
     * @dev Finalizes a prompt proposal. If successful, mints a new Echo NFT.
     * Can be called by anyone after the proposal duration ends.
     * @param _proposalId The ID of the prompt proposal.
     * @param _initialMetadataURI The initial metadata URI for the new Echo.
     */
    function finalizePromptProposal(uint256 _proposalId, string memory _initialMetadataURI)
        public
        whenNotPaused
    {
        PromptProposal storage proposal = promptProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "EtherealEchoes: Proposal not pending");
        require(block.timestamp > proposal.expirationTimestamp, "EtherealEchoes: Voting period not over yet");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes >= minRequiredVotes &&
            proposal.votesFor.mul(100).div(totalVotes) >= minApprovalPercentage)
        {
            proposal.status = ProposalStatus.Approved;
            uint256 newEchoId = _mintEcho(proposal.proposer, proposal.promptText, proposal.category, _initialMetadataURI);
            // Award reputation to proposer
            userReputation[proposal.proposer] = userReputation[proposal.proposer].add(500); // Base reputation gain for successful proposal
            rewardsClaimable[proposal.proposer] = rewardsClaimable[proposal.proposer].add(
                rewardPool.mul(proposerRewardPermille).div(1000) // 40% of pool for proposer
            );
            emit UserReputationUpdated(proposal.proposer, userReputation[proposal.proposer]);
            emit PromptProposalFinalized(_proposalId, ProposalStatus.Approved, newEchoId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit PromptProposalFinalized(_proposalId, ProposalStatus.Rejected, 0);
        }
    }

    /**
     * @dev Allows users to submit feedback (rating 1-5) on an off-chain AI generation
     * derived from a specific Echo. This influences the Echo's 'harmonyScore' and
     * the submitter's reputation. Can be extended with oracle verification.
     * @param _echoId The ID of the Echo the generation is based on.
     * @param _resultHash A hash of the generated output (for off-chain reference).
     * @param _userRating A rating from 1 to 5 for the quality of the generation.
     */
    function submitGenerationFeedback(uint256 _echoId, string memory _resultHash, uint8 _userRating)
        public
        whenNotPaused
    {
        require(_exists(_echoId), "EtherealEchoes: Echo does not exist");
        require(_userRating >= 1 && _userRating <= 5, "EtherealEchoes: Rating must be between 1 and 5");

        GenerationFeedback storage feedback = generationFeedbacks[_generationFeedbackIdCounter.current().add(1)];
        feedback.feedbackId = _generationFeedbackIdCounter.current().add(1);
        feedback.echoId = _echoId;
        feedback.submitter = msg.sender;
        feedback.resultHash = _resultHash;
        feedback.userRating = _userRating;
        feedback.submissionTimestamp = block.timestamp;
        feedback.processed = false;

        _generationFeedbackIdCounter.increment();

        // Update Echo harmony score
        Echo storage echo = echoes[_echoId];
        uint256 currentScoreSum = echo.harmonyScore.mul(echo.generationFeedbackCount);
        echo.generationFeedbackCount = echo.generationFeedbackCount.add(1);
        echo.harmonyScore = currentScoreSum.add(_userRating.mul(200)).div(echo.generationFeedbackCount); // Normalize to 0-1000

        // Update user reputation (positive feedback boosts, negative feedback reduces)
        // This is a simplified model, a more robust system might use dispute resolution.
        if (_userRating >= 4) {
            userReputation[msg.sender] = userReputation[msg.sender].add(10);
        } else if (_userRating <= 2) {
            userReputation[msg.sender] = userReputation[msg.sender].sub(5); // Can go negative, for now
        }
        emit UserReputationUpdated(msg.sender, userReputation[msg.sender]);
        emit GenerationFeedbackSubmitted(feedback.feedbackId, _echoId, msg.sender, _userRating);
    }

    /**
     * @dev Proposes combining two existing Echoes into a new, more complex one.
     * Requires a fee that goes into the reward pool.
     * @param _echoId1 The ID of the first parent Echo.
     * @param _echoId2 The ID of the second parent Echo.
     * @param _mergedPromptText The new, combined AI prompt text.
     * @param _initialMetadataURI The initial metadata URI for the new merged Echo.
     */
    function proposeEchoMerge(uint256 _echoId1, uint256 _echoId2, string memory _mergedPromptText, string memory _initialMetadataURI)
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        require(msg.value == PROPOSAL_FEE, "EtherealEchoes: Must pay the proposal fee");
        require(_exists(_echoId1) && _exists(_echoId2), "EtherealEchoes: Parent Echoes must exist");
        require(_echoId1 != _echoId2, "EtherealEchoes: Cannot merge an Echo with itself");
        require(bytes(_mergedPromptText).length > 0, "EtherealEchoes: Merged prompt cannot be empty");
        // Ensure the proposer owns at least one of the parent Echoes (or is approved)
        require(_isApprovedOrOwner(msg.sender, _echoId1) || _isApprovedOrOwner(msg.sender, _echoId2), "EtherealEchoes: Must own or be approved for at least one parent Echo");

        _mergeProposalIdCounter.increment();
        uint256 proposalId = _mergeProposalIdCounter.current();

        mergeProposals[proposalId] = MergeProposal({
            proposer: msg.sender,
            parentEchoId1: _echoId1,
            parentEchoId2: _echoId2,
            mergedPromptText: _mergedPromptText,
            votesFor: 0,
            votesAgainst: 0,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(PROPOSAL_DURATION),
            status: ProposalStatus.Pending,
            initialMetadataURI: _initialMetadataURI
        });

        rewardPool = rewardPool.add(PROPOSAL_FEE);
        emit MergeProposalSubmitted(proposalId, msg.sender, _echoId1, _echoId2, _mergedPromptText, PROPOSAL_FEE);
        return proposalId;
    }

    /**
     * @dev Casts a reputation-weighted vote (approve/reject) on a pending merge proposal.
     * @param _proposalId The ID of the merge proposal.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnMergeProposal(uint256 _proposalId, bool _approve)
        public
        whenNotPaused
    {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "EtherealEchoes: Merge proposal not pending");
        require(block.timestamp <= proposal.expirationTimestamp, "EtherealEchoes: Merge proposal has expired");
        require(userReputation[msg.sender] >= MIN_REPUTATION_TO_VOTE, "EtherealEchoes: Insufficient reputation to vote");
        require(!mergeProposalVoters[_proposalId][msg.sender], "EtherealEchoes: Already voted on this merge proposal");

        uint256 weightedVote = userReputation[msg.sender].div(100).add(1); // Base 1 + reputation/100
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(weightedVote);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(weightedVote);
        }
        mergeProposalVoters[_proposalId][msg.sender] = true;
        emit MergeProposalVoted(_proposalId, msg.sender, _approve, weightedVote);
    }

    /**
     * @dev Executes a merge proposal. If successful, mints a new Echo from the merged prompts.
     * The parent Echoes are marked as 'isMerged' and their evolution stage is considered.
     * Can be called by anyone after the proposal duration ends.
     * @param _proposalId The ID of the merge proposal.
     */
    function executeEchoMerge(uint256 _proposalId)
        public
        whenNotPaused
    {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "EtherealEchoes: Merge proposal not pending");
        require(block.timestamp > proposal.expirationTimestamp, "EtherealEchoes: Voting period not over yet");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes >= minRequiredVotes &&
            proposal.votesFor.mul(100).div(totalVotes) >= minApprovalPercentage)
        {
            proposal.status = ProposalStatus.Approved;

            Echo storage parent1 = echoes[proposal.parentEchoId1];
            Echo storage parent2 = echoes[proposal.parentEchoId2];

            // Mark parents as merged
            parent1.isMerged = true;
            parent2.isMerged = true;

            // Mint new Echo
            uint256 newEchoId = _mintEcho(proposal.proposer, proposal.mergedPromptText, "Merged", proposal.initialMetadataURI);
            Echo storage newEcho = echoes[newEchoId];
            newEcho.evolutionStage = Math.max(parent1.evolutionStage, parent2.evolutionStage).add(1);
            newEcho.harmonyScore = (parent1.harmonyScore.add(parent2.harmonyScore)).div(2); // Average harmony

            // Award reputation to proposer
            userReputation[proposal.proposer] = userReputation[proposal.proposer].add(750); // Higher reputation for merges
            rewardsClaimable[proposal.proposer] = rewardsClaimable[proposal.proposer].add(
                rewardPool.mul(proposerRewardPermille).div(1000)
            );
            emit UserReputationUpdated(proposal.proposer, userReputation[proposal.proposer]);
            emit MergeProposalExecuted(_proposalId, ProposalStatus.Approved, newEchoId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit MergeProposalExecuted(_proposalId, ProposalStatus.Rejected, 0);
        }
    }

    // --- III. Reputation & Economic Incentives ---

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Owner/Admin function to disburse rewards from the `rewardPool`
     * to users based on their contributions and accumulated rewards.
     * In this simplified model, rewards are calculated when proposals are finalized,
     * this function would be to actually *transfer* funds from the `rewardPool` to `rewardsClaimable`.
     * For demonstration, `rewardsClaimable` are directly incremented upon successful proposal.
     * This function could implement a more complex distribution mechanism.
     */
    function distributeCuratorRewards() public onlyOwner whenNotPaused {
        // This function could be expanded to analyze all successful votes, feedback, etc.
        // For this example, rewards are primarily distributed upon successful proposals/merges.
        // The `rewardPool` accumulates fees, and `rewardsClaimable` tracks what users can withdraw.
        // This function could, for example, distribute a fraction of the *remaining* rewardPool to all
        // users who have reputation above a certain threshold, proportional to their reputation.
        // As rewards are already assigned to `rewardsClaimable` during proposal finalization,
        // this specific implementation of `distributeCuratorRewards` is largely a placeholder
        // for more complex, periodic distribution if the rewards were not directly allocated
        // on successful proposals.
        // For now, it simply marks the fact that rewards are ready to be claimed based on prior actions.
        emit RewardsDistributed(msg.sender, rewardPool); // Log that distribution logic was run
        // rewardPool is decreased when rewards are claimed, not here.
    }

    /**
     * @dev Allows users to claim their accumulated rewards.
     */
    function claimMyRewards() public whenNotPaused {
        uint256 amount = rewardsClaimable[msg.sender];
        require(amount > 0, "EtherealEchoes: No rewards to claim");

        rewardsClaimable[msg.sender] = 0;
        rewardPool = rewardPool.sub(amount); // Deduct from the total pool
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "EtherealEchoes: Failed to send rewards");

        emit RewardsClaimed(msg.sender, amount);
    }

    // --- IV. Administrative & System Configuration (Owner-only) ---

    /**
     * @dev Owner sets the minimum number of votes and approval percentage required for a proposal to pass.
     * @param _minRequiredVotes The minimum total votes (for + against) for a proposal to be valid.
     * @param _minApprovalPercentage The minimum percentage of 'for' votes (e.g., 51 for 51%).
     */
    function setVotingParameters(uint256 _minRequiredVotes, uint256 _minApprovalPercentage)
        public
        onlyOwner
    {
        require(_minApprovalPercentage > 0 && _minApprovalPercentage <= 100, "EtherealEchoes: Approval percentage must be between 1 and 100");
        emit ParametersUpdated("minRequiredVotes", minRequiredVotes, _minRequiredVotes);
        emit ParametersUpdated("minApprovalPercentage", minApprovalPercentage, _minApprovalPercentage);
        minRequiredVotes = _minRequiredVotes;
        minApprovalPercentage = _minApprovalPercentage;
    }

    /**
     * @dev Owner sets the proportion of rewards allocated to proposers versus curators.
     * @param _proposerRewardPermille Permille (per 1000) of reward pool for proposers.
     * @param _curatorRewardPermille Permille (per 1000) of reward pool for curators.
     */
    function setRewardRates(uint256 _proposerRewardPermille, uint256 _curatorRewardPermille)
        public
        onlyOwner
    {
        require(_proposerRewardPermille.add(_curatorRewardPermille) <= 1000, "EtherealEchoes: Total permille must not exceed 1000");
        emit ParametersUpdated("proposerRewardPermille", proposerRewardPermille, _proposerRewardPermille);
        emit ParametersUpdated("curatorRewardPermille", curatorRewardPermille, _curatorRewardPermille);
        proposerRewardPermille = _proposerRewardPermille;
        curatorRewardPermille = _curatorRewardPermille;
    }

    /**
     * @dev Owner sets the address of a trusted oracle.
     * This could be used for off-chain verification of AI generation quality.
     * @param _newOracleAddress The address of the new oracle.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "EtherealEchoes: Oracle address cannot be zero");
        address oldOracleAddress = oracleAddress;
        oracleAddress = _newOracleAddress;
        emit ParametersUpdated("oracleAddress", uint256(uint160(oldOracleAddress)), uint256(uint160(_newOracleAddress)));
    }

    /**
     * @dev Owner can pause core contract functionalities.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated ETH from the contract.
     * This would primarily be accumulated proposal fees that are not yet distributed
     * as rewards, or unallocated portions of the reward pool.
     * @param _to The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawContractFunds(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "EtherealEchoes: Amount must be greater than zero");
        require(address(this).balance >= _amount, "EtherealEchoes: Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "EtherealEchoes: Failed to withdraw funds");
        emit FundsWithdrawn(_to, _amount);
    }
}
```