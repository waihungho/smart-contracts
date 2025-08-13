This smart contract, **SynapseNexus**, presents a novel platform for AI-augmented knowledge creation and curation. It combines several advanced concepts: AI integration (via oracle), dynamic NFTs, an on-chain reputation system, decentralized curation, programmable NFT licensing, and a research bounty system. The goal is to create a decentralized ecosystem where raw data can be synthesized into structured knowledge, validated by a community, and incentivized through token rewards.

The contract avoids direct duplication of existing open-source projects by combining these elements into a unique workflow and purpose, focusing on information synthesis and peer-reviewed knowledge modules rather than generic art or finance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
    Outline and Function Summary for SynapseNexus Smart Contract

    The SynapseNexus protocol is a Decentralized AI-Augmented Creative & Research Synthesis Platform.
    It enables users to contribute raw "Data Fragments" (as NFTs), propose their synthesis by an
    off-chain AI oracle, and then collectively curate and validate the resulting "Knowledge Modules" (also NFTs).
    The platform incorporates a reputation system, on-chain licensing for Knowledge Modules, and
    a bounty system to incentivize specific research and knowledge creation.

    I. Core Platform Management (Admin/Governance)
        1.  constructor(address _synapseTokenAddress, address _initialOracleAddress): Initializes the contract with the SynapseToken address and the trusted AI oracle address. Sets up initial ownership.
        2.  updateOracleAddress(address newOracleAddress): Allows the current owner/governance to update the address of the trusted AI oracle.
        3.  setPlatformFee(uint256 newFee): Sets the fee (in SynapseTokens) for submitting Data Fragments and requesting synthesis.
        4.  withdrawPlatformFees(address recipient): Allows the owner/governance to withdraw accumulated platform fees.
        5.  setMinimumStakeForCuration(uint256 newMinStake): Sets the minimum SynapseToken stake required to participate in Knowledge Module curation.
        6.  setSynthesisCost(uint256 cost): Sets the cost (in SynapseTokens) to request AI synthesis for a Knowledge Module.

    II. Token & NFT Operations
        7.  submitDataFragment(string calldata fragmentURI, bytes32 _fragmentHash): Allows users to mint a new DataFragment NFT, representing a piece of raw data or research. Requires a fee.
        8.  proposeKnowledgeSynthesis(uint256[] calldata fragmentIds, string calldata proposedTitle, string calldata proposedDescription): Proposes the creation of a new KnowledgeModule from a set of existing DataFragments. This is the first step before AI synthesis.
        9.  requestAISynthesis(uint256 proposalId): Triggers a request to the off-chain AI oracle to synthesize the DataFragments linked to a specific proposal. Requires a fee. Only callable for an active proposal.
        10. finalizeAISynthesis(uint256 proposalId, string calldata moduleURI, uint256 estimatedQualityScore): Oracle callback to mint the KnowledgeModule NFT once AI synthesis is complete. Updates reputation.
        11. licenseKnowledgeModule(uint256 knowledgeModuleId, uint256 royaltyBasisPoints, uint256 usageFlags): Allows the owner of a Knowledge Module to define its on-chain licensing terms (e.g., royalties, usage permissions).
        12. transferDataFragment(address from, address to, uint256 tokenId): Standard ERC721 transfer for DataFragments (wrapper).
        13. transferKnowledgeModule(address from, address to, uint256 tokenId): Standard ERC721 transfer for KnowledgeModules (wrapper).
        14. stakeForCuration(uint256 amount): Allows users to stake SynapseTokens to become eligible curators and earn rewards.
        15. unstakeFromCuration(): Allows staked users to initiate an unstake request, subject to a cooldown.

    III. Curation & Reputation
        16. voteOnKnowledgeModule(uint256 knowledgeModuleId, bool upvote): Allows staked curators to vote on the quality of a Knowledge Module. Affects the module's reputation score and the voter's reputation.
        17. challengeKnowledgeModule(uint256 knowledgeModuleId, string calldata reasonURI): Initiates a dispute over a Knowledge Module's accuracy or quality. Requires a stake from the challenger.
        18. resolveChallenge(uint256 challengeId, bool challengeSuccessful): Owner/governance/dispute system resolves a challenge, affecting reputations and potentially modifying/burning the module.
        19. getReputation(address user): Returns the current reputation score of a given user.
        20. proposeKnowledgeModuleImprovement(uint256 knowledgeModuleId, string calldata newModuleURI, string calldata improvementRationaleURI): Allows a curator to propose an improved version (new URI) for an existing Knowledge Module. Triggers a vote or review (conceptually).

    IV. Research Bounties
        21. createResearchBounty(string calldata title, string calldata descriptionURI, uint256 rewardAmount): Creates a new research bounty, specifying a topic and initial reward.
        22. fundResearchBounty(uint256 bountyId, uint256 amount): Allows anyone to contribute additional funds to an existing research bounty.
        23. claimResearchBounty(uint256 bountyId, uint256 knowledgeModuleId): Allows a Knowledge Module creator to claim a bounty if their module fulfills the bounty's requirements (subject to owner/governance review).

    V. Query Functions (Getters)
        24. getKnowledgeModuleData(uint256 knowledgeModuleId): Returns detailed information about a specific Knowledge Module.
        25. getDataFragmentData(uint256 fragmentId): Returns detailed information about a specific Data Fragment.
        26. getBountyDetails(uint256 bountyId): Returns detailed information about a specific Research Bounty.
        27. getOracleAddress(): Returns the current address of the trusted AI oracle.
*/

contract SynapseNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // External dependencies
    IERC20 public immutable synapseToken;
    address public aiOracleAddress; // Address of the trusted AI oracle

    // NFT Counters
    Counters.Counter private _dataFragmentTokenIds;
    Counters.Counter private _knowledgeModuleTokenIds;
    Counters.Counter private _knowledgeSynthesisProposalIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _bountyIds;

    // Platform settings
    uint256 public platformFee; // Fee in SynapseTokens for various operations
    uint256 public minimumStakeForCuration; // Min stake required to vote/curate
    uint256 public synthesisCost; // Cost to request AI synthesis
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 3 days; // Cooldown period for unstaking

    // Fee accumulator
    uint256 public totalPlatformFeesCollected;

    // NFT Definitions (Instances of our InternalERC721)
    InternalERC721 public immutable DataFragments;
    InternalERC721 public immutable KnowledgeModules;

    // Structs for various data types
    struct DataFragment {
        address owner;
        string fragmentURI;
        bytes32 fragmentHash; // Hashing the content to detect duplicates or verify integrity
        uint256 timestamp;
    }

    struct KnowledgeSynthesisProposal {
        uint256[] fragmentIds;
        address proposer;
        string proposedTitle;
        string proposedDescription;
        bool synthesized; // True once AI has processed it
        uint256 knowledgeModuleId; // ID of the resulting KM, if synthesized
        uint256 timestamp;
    }

    enum KnowledgeModuleStatus { Proposed, Synthesized, Challenged, Active, Improved }

    struct KnowledgeModule {
        address owner;
        uint256 creatorProposalId; // The proposal that led to this KM
        string moduleURI;
        uint256 version; // Tracks improvements/updates
        int256 reputationScore; // Quality score, influenced by votes and challenges
        KnowledgeModuleStatus status;
        uint256 royaltyBasisPoints; // For licensing, e.g., 500 for 5% (500/10000 = 5%)
        uint256 usageFlags; // Bitmask for licensing terms (e.g., 1=Commercial, 2=Derivative, 4=Attribution)
        uint256 timestamp;
        uint256 estimatedQualityScore; // Score from the AI Oracle at synthesis
    }

    struct UserReputation {
        int256 score; // Can be positive or negative
        uint256 lastActivity;
    }

    struct CuratorStake {
        uint256 amount;
        uint256 stakeTime;
        bool hasUnstakeRequest;
        uint256 unstakeRequestTime;
    }

    struct Challenge {
        uint256 knowledgeModuleId;
        address challenger;
        string reasonURI; // URI to off-chain explanation of the challenge
        uint256 challengeStake; // Stake amount by challenger
        bool resolved;
        bool challengeSuccessful; // True if challenger wins the challenge
        uint256 timestamp;
    }

    enum BountyStatus { Active, Claimed, Cancelled }

    struct ResearchBounty {
        string title;
        string descriptionURI;
        address creator;
        uint256 rewardAmount; // Total funds currently in the bounty
        BountyStatus status;
        uint256 awardedKnowledgeModuleId; // The KM that claimed this bounty, if any
        uint256 timestamp;
    }

    // Mappings
    mapping(uint256 => DataFragment) public dataFragments;
    mapping(uint256 => KnowledgeSynthesisProposal) public synthesisProposals;
    mapping(uint256 => KnowledgeModule) public knowledgeModules;
    mapping(address => UserReputation) public userReputations;
    mapping(address => CuratorStake) public curatorStakes;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => ResearchBounty) public researchBounties;

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracleAddress);
    event PlatformFeeSet(uint256 newFee);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event MinimumStakeForCurationSet(uint256 newMinStake);
    event SynthesisCostSet(uint256 newCost);

    event DataFragmentSubmitted(uint256 indexed tokenId, address indexed owner, string fragmentURI);
    event KnowledgeSynthesisProposed(uint256 indexed proposalId, address indexed proposer, uint256[] fragmentIds);
    event AISynthesisRequested(uint256 indexed proposalId, address indexed requester);
    event AISynthesisFinalized(uint256 indexed proposalId, uint256 indexed knowledgeModuleId, string moduleURI, uint256 estimatedQualityScore);
    event KnowledgeModuleLicensed(uint256 indexed knowledgeModuleId, uint256 royaltyBasisPoints, uint256 usageFlags);

    event StakedForCuration(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    event KnowledgeModuleVoted(uint256 indexed knowledgeModuleId, address indexed voter, bool upvote, int256 newModuleReputationScore);
    event KnowledgeModuleChallenged(uint256 indexed challengeId, uint256 indexed knowledgeModuleId, address indexed challenger);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed knowledgeModuleId, bool challengeSuccessful);
    event KnowledgeModuleImprovementProposed(uint256 indexed knowledgeModuleId, address indexed proposer, string newModuleURI);

    event ResearchBountyCreated(uint256 indexed bountyId, address indexed creator, uint256 initialReward);
    event ResearchBountyFunded(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event ResearchBountyClaimed(uint256 indexed bountyId, uint256 indexed knowledgeModuleId, address indexed claimant);

    // --- Constructor ---

    /// @notice Initializes the contract with the SynapseToken address and the trusted AI oracle address.
    /// @param _synapseTokenAddress The address of the ERC20 Synapse Token contract.
    /// @param _initialOracleAddress The address of the trusted off-chain AI oracle.
    constructor(address _synapseTokenAddress, address _initialOracleAddress)
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        require(_synapseTokenAddress != address(0), "SynapseNexus: Invalid SynapseToken address");
        require(_initialOracleAddress != address(0), "SynapseNexus: Invalid AI Oracle address");

        synapseToken = IERC20(_synapseTokenAddress);
        aiOracleAddress = _initialOracleAddress;

        // Initialize NFT contracts
        DataFragments = new InternalERC721("Synapse Data Fragment", "SDF");
        KnowledgeModules = new InternalERC721("Synapse Knowledge Module", "SKM");

        platformFee = 1e18; // Default 1 SYN token
        minimumStakeForCuration = 100e18; // Default 100 SYN tokens
        synthesisCost = 10e18; // Default 10 SYN tokens

        emit OracleAddressUpdated(_initialOracleAddress);
        emit PlatformFeeSet(platformFee);
        emit MinimumStakeForCurationSet(minimumStakeForCuration);
        emit SynthesisCostSet(synthesisCost);
    }

    // --- I. Core Platform Management (Admin/Governance) ---

    /// @notice Allows the current owner/governance to update the address of the trusted AI oracle.
    /// @param newOracleAddress The new address for the AI oracle.
    function updateOracleAddress(address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "SynapseNexus: Invalid new oracle address");
        aiOracleAddress = newOracleAddress;
        emit OracleAddressUpdated(newOracleAddress);
    }

    /// @notice Sets the fee (in SynapseTokens) for submitting Data Fragments and requesting synthesis.
    /// @param newFee The new platform fee in smallest token units (e.g., wei for ERC20).
    function setPlatformFee(uint256 newFee) external onlyOwner {
        platformFee = newFee;
        emit PlatformFeeSet(newFee);
    }

    /// @notice Allows the owner/governance to withdraw accumulated platform fees.
    /// @param recipient The address to send the withdrawn fees to.
    function withdrawPlatformFees(address recipient) external onlyOwner nonReentrant {
        require(recipient != address(0), "SynapseNexus: Invalid recipient address");
        uint256 amount = totalPlatformFeesCollected;
        require(amount > 0, "SynapseNexus: No fees to withdraw");
        totalPlatformFeesCollected = 0;
        require(synapseToken.transfer(recipient, amount), "SynapseNexus: Fee transfer failed");
        emit PlatformFeesWithdrawn(recipient, amount);
    }

    /// @notice Sets the minimum SynapseToken stake required to participate in Knowledge Module curation.
    /// @param newMinStake The new minimum stake amount.
    function setMinimumStakeForCuration(uint256 newMinStake) external onlyOwner {
        minimumStakeForCuration = newMinStake;
        emit MinimumStakeForCurationSet(newMinStake);
    }

    /// @notice Sets the cost (in SynapseTokens) to request AI synthesis for a Knowledge Module.
    /// @param cost The new synthesis cost.
    function setSynthesisCost(uint256 cost) external onlyOwner {
        synthesisCost = cost;
        emit SynthesisCostSet(cost);
    }

    // --- II. Token & NFT Operations ---

    /// @notice Allows users to mint a new DataFragment NFT, representing a piece of raw data or research.
    /// @param fragmentURI URI pointing to the off-chain data content.
    /// @param _fragmentHash Cryptographic hash of the fragment content for integrity/deduplication.
    /// @dev Requires the sender to approve and transfer platformFee to this contract.
    /// @return The ID of the newly minted DataFragment NFT.
    function submitDataFragment(string calldata fragmentURI, bytes32 _fragmentHash) external nonReentrant returns (uint256) {
        require(bytes(fragmentURI).length > 0, "SynapseNexus: Fragment URI cannot be empty");
        require(synapseToken.transferFrom(msg.sender, address(this), platformFee), "SynapseNexus: Fee payment failed");
        totalPlatformFeesCollected += platformFee;

        _dataFragmentTokenIds.increment();
        uint256 newId = _dataFragmentTokenIds.current();

        dataFragments[newId] = DataFragment({
            owner: msg.sender,
            fragmentURI: fragmentURI,
            fragmentHash: _fragmentHash,
            timestamp: block.timestamp
        });

        DataFragments.mint(msg.sender, newId);
        DataFragments.setTokenURI(newId, fragmentURI); // Set URI for the NFT

        emit DataFragmentSubmitted(newId, msg.sender, fragmentURI);
        return newId;
    }

    /// @notice Proposes the creation of a new KnowledgeModule from a set of existing DataFragments.
    /// @param fragmentIds An array of DataFragment IDs to be synthesized.
    /// @param proposedTitle A short title for the proposed Knowledge Module.
    /// @param proposedDescription A brief description of the proposed Knowledge Module.
    /// @dev This doesn't trigger synthesis, only creates a proposal.
    /// @return The ID of the newly created synthesis proposal.
    function proposeKnowledgeSynthesis(uint256[] calldata fragmentIds, string calldata proposedTitle, string calldata proposedDescription) external returns (uint256) {
        require(fragmentIds.length > 0, "SynapseNexus: At least one fragment ID required");
        for (uint256 i = 0; i < fragmentIds.length; i++) {
            require(dataFragments[fragmentIds[i]].owner != address(0), "SynapseNexus: Fragment ID does not exist");
        }
        require(bytes(proposedTitle).length > 0, "SynapseNexus: Title cannot be empty");

        _knowledgeSynthesisProposalIds.increment();
        uint256 newProposalId = _knowledgeSynthesisProposalIds.current();

        synthesisProposals[newProposalId] = KnowledgeSynthesisProposal({
            fragmentIds: fragmentIds,
            proposer: msg.sender,
            proposedTitle: proposedTitle,
            proposedDescription: proposedDescription,
            synthesized: false,
            knowledgeModuleId: 0, // Will be set upon finalization
            timestamp: block.timestamp
        });

        emit KnowledgeSynthesisProposed(newProposalId, msg.sender, fragmentIds);
        return newProposalId;
    }

    /// @notice Triggers a request to the off-chain AI oracle to synthesize the DataFragments linked to a specific proposal.
    /// @param proposalId The ID of the knowledge synthesis proposal.
    /// @dev Only the proposer or owner can request synthesis. Requires payment of synthesisCost.
    function requestAISynthesis(uint256 proposalId) external nonReentrant {
        KnowledgeSynthesisProposal storage proposal = synthesisProposals[proposalId];
        require(proposal.proposer != address(0), "SynapseNexus: Proposal does not exist");
        require(!proposal.synthesized, "SynapseNexus: Proposal already synthesized");
        require(msg.sender == proposal.proposer || msg.sender == owner(), "SynapseNexus: Only proposer or owner can request synthesis");

        require(synapseToken.transferFrom(msg.sender, address(this), synthesisCost), "SynapseNexus: Synthesis cost payment failed");
        totalPlatformFeesCollected += synthesisCost;

        // In a real system, this would emit an event for the oracle to pick up,
        // or directly call an oracle interface if it's on-chain (e.g., Chainlink external adapter).
        // For simplicity, we assume the oracle monitors events or has another trigger.
        emit AISynthesisRequested(proposalId, msg.sender);
    }

    /// @notice Oracle callback to mint the KnowledgeModule NFT once AI synthesis is complete.
    /// @param proposalId The ID of the knowledge synthesis proposal.
    /// @param moduleURI URI pointing to the off-chain AI-synthesized content.
    /// @param estimatedQualityScore An initial quality score provided by the AI/oracle.
    /// @dev This function can ONLY be called by the trusted AI Oracle address.
    function finalizeAISynthesis(uint256 proposalId, string calldata moduleURI, uint256 estimatedQualityScore) external {
        require(msg.sender == aiOracleAddress, "SynapseNexus: Only AI oracle can call this function");
        KnowledgeSynthesisProposal storage proposal = synthesisProposals[proposalId];
        require(proposal.proposer != address(0), "SynapseNexus: Proposal does not exist");
        require(!proposal.synthesized, "SynapseNexus: Proposal already synthesized");
        require(bytes(moduleURI).length > 0, "SynapseNexus: Module URI cannot be empty");

        _knowledgeModuleTokenIds.increment();
        uint256 newKnowledgeModuleId = _knowledgeModuleTokenIds.current();

        proposal.synthesized = true;
        proposal.knowledgeModuleId = newKnowledgeModuleId;

        knowledgeModules[newKnowledgeModuleId] = KnowledgeModule({
            owner: proposal.proposer, // The proposer is the initial owner of the KM
            creatorProposalId: proposalId,
            moduleURI: moduleURI,
            version: 1,
            reputationScore: int256(estimatedQualityScore), // Initial score from AI
            status: KnowledgeModuleStatus.Synthesized,
            royaltyBasisPoints: 0,
            usageFlags: 0,
            timestamp: block.timestamp,
            estimatedQualityScore: estimatedQualityScore
        });

        KnowledgeModules.mint(proposal.proposer, newKnowledgeModuleId);
        KnowledgeModules.setTokenURI(newKnowledgeModuleId, moduleURI);

        // Initial reputation boost for the proposer
        _adjustReputation(proposal.proposer, 50); // Small boost for successful synthesis
        _adjustReputation(aiOracleAddress, int256(estimatedQualityScore / 10)); // Reward AI based on its estimated quality

        emit AISynthesisFinalized(proposalId, newKnowledgeModuleId, moduleURI, estimatedQualityScore);
    }

    /// @notice Allows the owner of a Knowledge Module to define its on-chain licensing terms.
    /// @param knowledgeModuleId The ID of the Knowledge Module.
    /// @param royaltyBasisPoints Royalty percentage (e.g., 500 for 5% of 10000 basis points) to be paid on future uses/sales.
    /// @param usageFlags Bitmask for usage permissions (e.g., 1=Commercial, 2=Derivative, 4=Attribution).
    function licenseKnowledgeModule(uint256 knowledgeModuleId, uint256 royaltyBasisPoints, uint256 usageFlags) external {
        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist");
        require(KnowledgeModules.ownerOf(knowledgeModuleId) == msg.sender, "SynapseNexus: Only KM owner can set license");
        require(royaltyBasisPoints <= 10000, "SynapseNexus: Royalty basis points cannot exceed 10000 (100%)");

        km.royaltyBasisPoints = royaltyBasisPoints;
        km.usageFlags = usageFlags;
        emit KnowledgeModuleLicensed(knowledgeModuleId, royaltyBasisPoints, usageFlags);
    }

    /// @notice Standard ERC721 transfer for DataFragments.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the DataFragment NFT.
    function transferDataFragment(address from, address to, uint256 tokenId) external {
        DataFragments.transferFrom(from, to, tokenId);
    }

    /// @notice Standard ERC721 transfer for KnowledgeModules.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the KnowledgeModule NFT.
    function transferKnowledgeModule(address from, address to, uint256 tokenId) external {
        KnowledgeModules.transferFrom(from, to, tokenId);
    }

    /// @notice Allows users to stake SynapseTokens to become eligible curators and earn rewards.
    /// @param amount The amount of SynapseTokens to stake.
    function stakeForCuration(uint256 amount) external nonReentrant {
        require(amount > 0, "SynapseNexus: Stake amount must be greater than zero");
        require(curatorStakes[msg.sender].hasUnstakeRequest == false, "SynapseNexus: Pending unstake request exists");
        require(synapseToken.transferFrom(msg.sender, address(this), amount), "SynapseNexus: Token transfer failed");

        curatorStakes[msg.sender].amount += amount;
        curatorStakes[msg.sender].stakeTime = block.timestamp; // Update stake time on new stake
        emit StakedForCuration(msg.sender, amount);
    }

    /// @notice Allows staked users to initiate an unstake request, subject to a cooldown period.
    function unstakeFromCuration() external nonReentrant {
        CuratorStake storage stake = curatorStakes[msg.sender];
        require(stake.amount > 0, "SynapseNexus: No active stake found");

        if (stake.hasUnstakeRequest) {
            // If there's an existing request, check cooldown and execute or revert.
            _executeUnstake(); // Attempts to complete previous unstake if cooldown is over
            require(!stake.hasUnstakeRequest, "SynapseNexus: Unstake cooldown not over yet for pending request");
        }
        
        // Initiate new unstake request
        stake.hasUnstakeRequest = true;
        stake.unstakeRequestTime = block.timestamp;
        emit UnstakeRequested(msg.sender, stake.amount);
    }

    /// @notice Executes the actual unstaking after the cooldown period. Can be called by anyone.
    function executeUnstake(address user) external nonReentrant {
        CuratorStake storage stake = curatorStakes[user];
        require(stake.hasUnstakeRequest, "SynapseNexus: No pending unstake request for user");
        require(block.timestamp >= stake.unstakeRequestTime + UNSTAKE_COOLDOWN_PERIOD, "SynapseNexus: Unstake cooldown not over");

        uint256 amount = stake.amount;
        stake.amount = 0;
        stake.hasUnstakeRequest = false;
        stake.unstakeRequestTime = 0;

        require(synapseToken.transfer(user, amount), "SynapseNexus: Unstake transfer failed");
        emit Unstaked(user, amount);
    }

    // --- III. Curation & Reputation ---

    /// @notice Allows staked curators to vote on the quality of a Knowledge Module.
    /// @param knowledgeModuleId The ID of the Knowledge Module being voted on.
    /// @param upvote True for upvote, false for downvote.
    /// @dev Affects the module's reputation score and the voter's reputation.
    function voteOnKnowledgeModule(uint256 knowledgeModuleId, bool upvote) external {
        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist");
        require(curatorStakes[msg.sender].amount >= minimumStakeForCuration, "SynapseNexus: Insufficient stake to curate");
        require(km.status != KnowledgeModuleStatus.Challenged, "SynapseNexus: Cannot vote on challenged module");

        int256 reputationChange = upvote ? 1 : -1;
        km.reputationScore += reputationChange;
        _adjustReputation(msg.sender, reputationChange * 5); // Voter gets larger reputation change

        emit KnowledgeModuleVoted(knowledgeModuleId, msg.sender, upvote, km.reputationScore);
    }

    /// @notice Initiates a dispute over a Knowledge Module's accuracy or quality.
    /// @param knowledgeModuleId The ID of the Knowledge Module being challenged.
    /// @param reasonURI URI pointing to off-chain detailed reasoning for the challenge.
    /// @dev Requires a stake from the challenger which is locked until resolution.
    /// @return The ID of the newly created challenge.
    function challengeKnowledgeModule(uint256 knowledgeModuleId, string calldata reasonURI) external nonReentrant returns (uint256) {
        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist");
        require(km.status != KnowledgeModuleStatus.Challenged, "SynapseNexus: Knowledge Module already under challenge");
        require(bytes(reasonURI).length > 0, "SynapseNexus: Reason URI cannot be empty");
        require(curatorStakes[msg.sender].amount >= minimumStakeForCuration, "SynapseNexus: Insufficient stake to challenge");

        uint256 challengeStakeAmount = minimumStakeForCuration * 2; // Double the curation stake
        require(synapseToken.transferFrom(msg.sender, address(this), challengeStakeAmount), "SynapseNexus: Challenge stake payment failed");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            knowledgeModuleId: knowledgeModuleId,
            challenger: msg.sender,
            reasonURI: reasonURI,
            challengeStake: challengeStakeAmount,
            resolved: false,
            challengeSuccessful: false,
            timestamp: block.timestamp
        });

        km.status = KnowledgeModuleStatus.Challenged;
        emit KnowledgeModuleChallenged(newChallengeId, knowledgeModuleId, msg.sender);
        return newChallengeId;
    }

    /// @notice Owner/governance/dispute system resolves a challenge.
    /// @param challengeId The ID of the challenge to resolve.
    /// @param challengeSuccessful True if the challenger's claim is valid and the KM is indeed flawed.
    /// @dev Affects reputations of challenger, KM owner, and potentially burns or modifies the module.
    function resolveChallenge(uint256 challengeId, bool challengeSuccessful) external onlyOwner nonReentrant {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.challenger != address(0), "SynapseNexus: Challenge does not exist");
        require(!challenge.resolved, "SynapseNexus: Challenge already resolved");

        KnowledgeModule storage km = knowledgeModules[challenge.knowledgeModuleId];

        challenge.resolved = true;
        challenge.challengeSuccessful = challengeSuccessful;

        if (challengeSuccessful) {
            // Challenger wins: Repay stake + reward, KM owner loses reputation, KM reputation drops
            require(synapseToken.transfer(challenge.challenger, challenge.challengeStake + (challenge.challengeStake / 2)), "SynapseNexus: Challenger reward transfer failed");
            _adjustReputation(challenge.challenger, 100); // Significant reputation gain for successful challenge
            _adjustReputation(km.owner, -100); // Significant reputation loss for KM owner
            km.reputationScore -= 200; // KM takes a big hit
            km.status = KnowledgeModuleStatus.Proposed; // Revert to proposed for re-synthesis or improvement
            KnowledgeModules.burn(challenge.knowledgeModuleId); // Consider burning the flawed KM
        } else {
            // Challenger loses: Stake is lost, KM owner gains reputation, KM reputation recovers
            totalPlatformFeesCollected += challenge.challengeStake; // Challenger's stake goes to platform
            _adjustReputation(challenge.challenger, -50); // Reputation loss for failed challenge
            _adjustReputation(km.owner, 50); // Reputation gain for KM owner
            km.reputationScore += 50; // KM reputation partially recovers
            km.status = KnowledgeModuleStatus.Active; // Resume active status
        }
        emit ChallengeResolved(challengeId, challenge.knowledgeModuleId, challengeSuccessful);
    }

    /// @notice Returns the current reputation score of a given user.
    /// @param user The address of the user.
    /// @return The reputation score (can be positive or negative).
    function getReputation(address user) external view returns (int256) {
        return userReputations[user].score;
    }

    /// @notice Allows a curator to propose an improved version (new URI) for an existing Knowledge Module.
    /// @param knowledgeModuleId The ID of the Knowledge Module to improve.
    /// @param newModuleURI The URI for the improved content.
    /// @param improvementRationaleURI URI pointing to off-chain explanation of the improvements.
    /// @dev This could trigger a new vote or a lightweight review process for acceptance. For now, it just records the proposal.
    function proposeKnowledgeModuleImprovement(uint256 knowledgeModuleId, string calldata newModuleURI, string calldata improvementRationaleURI) external {
        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist");
        require(curatorStakes[msg.sender].amount >= minimumStakeForCuration, "SynapseNexus: Insufficient stake to propose improvement");
        require(bytes(newModuleURI).length > 0, "SynapseNexus: New Module URI cannot be empty");
        require(bytes(improvementRationaleURI).length > 0, "SynapseNexus: Improvement rationale URI cannot be empty");


        // In a more complex system, this would lead to a governance vote or a review queue.
        // For simplicity, we directly update the URI and version, but a real system would need consensus.
        km.moduleURI = newModuleURI;
        km.version += 1;
        km.status = KnowledgeModuleStatus.Improved;
        KnowledgeModules.setTokenURI(knowledgeModuleId, newModuleURI); // Update NFT metadata

        _adjustReputation(msg.sender, 20); // Reward for proposing an improvement
        emit KnowledgeModuleImprovementProposed(knowledgeModuleId, msg.sender, newModuleURI);
    }

    /// @notice Internal helper for adjusting a user's reputation score.
    /// @param user The address whose reputation to adjust.
    /// @param amount The amount to add to their reputation (can be negative).
    function _adjustReputation(address user, int256 amount) internal {
        userReputations[user].score += amount;
        userReputations[user].lastActivity = block.timestamp;
    }

    // --- IV. Research Bounties ---

    /// @notice Creates a new research bounty, specifying a topic and initial reward.
    /// @param title The title of the bounty.
    /// @param descriptionURI URI pointing to a detailed description of the bounty requirements.
    /// @param rewardAmount The initial amount of SynapseTokens to fund the bounty.
    /// @dev Requires the sender to transfer the initial reward amount.
    /// @return The ID of the newly created bounty.
    function createResearchBounty(string calldata title, string calldata descriptionURI, uint256 rewardAmount) external nonReentrant returns (uint256) {
        require(bytes(title).length > 0, "SynapseNexus: Bounty title cannot be empty");
        require(bytes(descriptionURI).length > 0, "SynapseNexus: Description URI cannot be empty");
        require(rewardAmount > 0, "SynapseNexus: Reward amount must be greater than zero");
        require(synapseToken.transferFrom(msg.sender, address(this), rewardAmount), "SynapseNexus: Bounty funding failed");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        researchBounties[newBountyId] = ResearchBounty({
            title: title,
            descriptionURI: descriptionURI,
            creator: msg.sender,
            rewardAmount: rewardAmount,
            status: BountyStatus.Active,
            awardedKnowledgeModuleId: 0,
            timestamp: block.timestamp
        });

        emit ResearchBountyCreated(newBountyId, msg.sender, rewardAmount);
        return newBountyId;
    }

    /// @notice Allows anyone to contribute additional funds to an existing research bounty.
    /// @param bountyId The ID of the bounty to fund.
    /// @param amount The amount of SynapseTokens to add to the bounty.
    /// @dev Requires the sender to transfer the amount.
    function fundResearchBounty(uint256 bountyId, uint256 amount) external nonReentrant {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.creator != address(0), "SynapseNexus: Bounty does not exist");
        require(bounty.status == BountyStatus.Active, "SynapseNexus: Bounty is not active");
        require(amount > 0, "SynapseNexus: Fund amount must be greater than zero");
        require(synapseToken.transferFrom(msg.sender, address(this), amount), "SynapseNexus: Bounty funding failed");

        bounty.rewardAmount += amount;
        emit ResearchBountyFunded(bountyId, msg.sender, amount);
    }

    /// @notice Allows a Knowledge Module creator to claim a bounty if their module fulfills the bounty's requirements.
    /// @param bountyId The ID of the bounty to claim.
    /// @param knowledgeModuleId The ID of the Knowledge Module proposed for the bounty.
    /// @dev This would typically involve a review process (e.g., curator vote, or owner decision).
    /// @dev For simplicity, we'll assume the owner of the contract resolves claims.
    function claimResearchBounty(uint256 bountyId, uint256 knowledgeModuleId) external onlyOwner nonReentrant {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.creator != address(0), "SynapseNexus: Bounty does not exist");
        require(bounty.status == BountyStatus.Active, "SynapseNexus: Bounty is not active");

        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist");
        require(km.status != KnowledgeModuleStatus.Challenged && km.status != KnowledgeModuleStatus.Proposed, "SynapseNexus: Knowledge Module not in claimable state");

        // In a real system, there would be a process (e.g., voting by curators, or specific bounty rules)
        // to verify if the KM truly fulfills the bounty. For this example, we assume owner can decide.
        bounty.status = BountyStatus.Claimed;
        bounty.awardedKnowledgeModuleId = knowledgeModuleId;

        // Reputation boost for successful bounty claim. Adjusted to be relative to the reward amount (e.g., 100 SYN -> 100 rep points)
        _adjustReputation(km.owner, int256(bounty.rewardAmount / (10**synapseToken.decimals())));

        require(synapseToken.transfer(km.owner, bounty.rewardAmount), "SynapseNexus: Bounty reward transfer failed");
        bounty.rewardAmount = 0; // Clear bounty funds

        emit ResearchBountyClaimed(bountyId, knowledgeModuleId, km.owner);
    }

    // --- V. Query Functions (Getters) ---

    /// @notice Returns detailed information about a specific Knowledge Module.
    /// @param knowledgeModuleId The ID of the Knowledge Module.
    /// @return owner_ The owner of the KM.
    /// @return creatorProposalId_ The proposal ID that created this KM.
    /// @return moduleURI_ The URI to the KM content.
    /// @return version_ The version number of the KM.
    /// @return reputationScore_ The current reputation score of the KM.
    /// @return status_ The current status of the KM.
    /// @return royaltyBasisPoints_ The defined royalty percentage.
    /// @return usageFlags_ The defined usage permissions.
    /// @return timestamp_ The creation timestamp.
    /// @return estimatedQualityScore_ The initial quality score from the AI.
    function getKnowledgeModuleData(uint256 knowledgeModuleId)
        external
        view
        returns (
            address owner_,
            uint256 creatorProposalId_,
            string memory moduleURI_,
            uint256 version_,
            int256 reputationScore_,
            KnowledgeModuleStatus status_,
            uint256 royaltyBasisPoints_,
            uint256 usageFlags_,
            uint256 timestamp_,
            uint256 estimatedQualityScore_
        )
    {
        KnowledgeModule storage km = knowledgeModules[knowledgeModuleId];
        require(km.owner != address(0), "SynapseNexus: Knowledge Module does not exist"); // Check if KM exists
        return (
            km.owner,
            km.creatorProposalId,
            km.moduleURI,
            km.version,
            km.reputationScore,
            km.status,
            km.royaltyBasisPoints,
            km.usageFlags,
            km.timestamp,
            km.estimatedQualityScore
        );
    }

    /// @notice Returns detailed information about a specific Data Fragment.
    /// @param fragmentId The ID of the Data Fragment.
    /// @return owner_ The owner of the Data Fragment.
    /// @return fragmentURI_ The URI to the fragment content.
    /// @return fragmentHash_ The hash of the fragment content.
    /// @return timestamp_ The creation timestamp.
    function getDataFragmentData(uint256 fragmentId)
        external
        view
        returns (
            address owner_,
            string memory fragmentURI_,
            bytes32 fragmentHash_,
            uint256 timestamp_
        )
    {
        DataFragment storage df = dataFragments[fragmentId];
        require(df.owner != address(0), "SynapseNexus: Data Fragment does not exist"); // Check if DF exists
        return (df.owner, df.fragmentURI, df.fragmentHash, df.timestamp);
    }

    /// @notice Returns detailed information about a specific Research Bounty.
    /// @param bountyId The ID of the Research Bounty.
    /// @return title_ The title of the bounty.
    /// @return descriptionURI_ The URI to the bounty description.
    /// @return creator_ The creator of the bounty.
    /// @return rewardAmount_ The current total reward amount.
    /// @return status_ The current status of the bounty.
    /// @return awardedKnowledgeModuleId_ The KM ID that claimed this bounty (if any).
    /// @return timestamp_ The creation timestamp.
    function getBountyDetails(uint256 bountyId)
        external
        view
        returns (
            string memory title_,
            string memory descriptionURI_,
            address creator_,
            uint256 rewardAmount_,
            BountyStatus status_,
            uint256 awardedKnowledgeModuleId_,
            uint256 timestamp_
        )
    {
        ResearchBounty storage bounty = researchBounties[bountyId];
        require(bounty.creator != address(0), "SynapseNexus: Research Bounty does not exist"); // Check if bounty exists
        return (
            bounty.title,
            bounty.descriptionURI,
            bounty.creator,
            bounty.rewardAmount,
            bounty.status,
            bounty.awardedKnowledgeModuleId,
            bounty.timestamp
        );
    }

    /// @notice Returns the current address of the trusted AI oracle.
    /// @return The AI oracle's address.
    function getOracleAddress() external view returns (address) {
        return aiOracleAddress;
    }

    // Fallback and Receive functions (optional but good practice)
    receive() external payable {
        // Allows the contract to receive native currency (e.g., ETH) if ever needed for other purposes.
        // Currently, all fee/stake payments are expected in SynapseToken (ERC20).
    }
    fallback() external payable {
        // Fallback for calls to non-existent functions. Can be used for introspection or error handling.
    }
}

// Helper contract to instantiate ERC721 tokens internally.
// This simplifies the example by keeping all code in one file,
// rather than requiring separate deployments for DataFragment and KnowledgeModule ERC721s.
contract InternalERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Internal mint function to be called by SynapseNexus
    function mint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    // Internal setTokenURI function to be called by SynapseNexus
    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        _setTokenURI(tokenId, _tokenURI);
    }

    // Internal burn function to be called by SynapseNexus (e.g., for challenged KMs)
    function burn(uint256 tokenId) internal {
        _burn(tokenId);
    }
}
```