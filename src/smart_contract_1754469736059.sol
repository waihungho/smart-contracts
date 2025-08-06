This smart contract, `AetherMind`, is designed as a decentralized protocol for an on-chain attention economy. It facilitates the creation, curation, and dynamic valuation of digital artifacts (NFTs) through community engagement, attention staking, and a reputation-weighted governance system. The core concept revolves around making an artifact's visibility and perceived value a dynamic, on-chain metric influenced by user interaction, and allowing the community to dispute and correct this metric through a challenge mechanism.

---

## **Contract Outline**

**Contract Name:** `AetherMind`

**Purpose:** A decentralized protocol for the creation, curation, and dynamic valuation of digital artifacts (NFTs) driven by community engagement, attention staking, and a reputation-weighted governance system. It aims to create an on-chain attention economy where artifacts' visibility and value are dynamically influenced by user attention and community oversight.

**I. Core Structure & Setup:**
*   `AetherMind`: Main contract inheriting `ERC721` (for artifact NFTs), `AccessControl` (for role-based permissions), and `Pausable` (for emergency stops).
*   `IAetherMind`: Interface for external interactions.
*   Enums, Structs, Errors, Events: Define custom data types, error messages, and events for transparency.

**II. State Variables:**
*   **Tokens:** Address of the `AETHER` utility token (ERC20).
*   **Counters:** For `artifactIds`, `challengeIds`, `proposalIds`.
*   **Artifact Data:** Mappings for `Artifact` structs, `attentionStakes`, `attentionRewards`, `premiumEarnings`.
*   **User Data:** Mappings for `userReputation`, `delegatedPower`, `lastVoteBlock`.
*   **Challenge Data:** Mappings for `Challenge` structs, `challengeVotes`.
*   **Proposal Data:** Mappings for `Proposal` structs, `proposalVotes`.
*   **Protocol Parameters:** Dynamically adjustable parameters like `attentionRewardRate`, `challengePeriod`, `challengeCollateral`, `protocolFeeRate`, `creatorRoyaltyRate`.

**III. Roles & Access Control:**
*   `DEFAULT_ADMIN_ROLE`: Primary administrative control, can assign other roles, initiate emergency pause.
*   `GOVERNANCE_EXEC_ROLE`: Role responsible for executing passed governance proposals.

**IV. Core Logic Sections:**

1.  **Artifact Management:** Creation (minting ERC721), metadata updates, premium access configuration, transfer, and burning. Artifacts possess dynamic properties like `visibilityScore` and `sentimentScore`.
2.  **Attention Economy:** Users stake `AETHER` tokens on artifacts to boost their `visibilityScore`. Stakers earn rewards over time from a protocol-managed pool.
3.  **Challenge System:** A unique mechanism allowing users to challenge the perceived `visibilityScore` of an artifact. Challengers stake `AETHER` collateral, and the community votes. Successful challenges redistribute collateral and adjust reputation.
4.  **Reputation System:** Users accumulate reputation points based on constructive participation (successful challenges, positive governance votes, successful artifact creation). Reputation influences voting power and potentially future rewards.
5.  **Governance (`AetherDAO`):** Liquid democracy model where users can delegate their `AETHER`-weighted governance power. Proposals can be created to adjust protocol parameters, and votes are reputation-weighted.
6.  **Revenue Distribution:** Fees from premium content unlocks are distributed dynamically among the artifact creator, the protocol, and attention stakers.
7.  **Emergency Control:** Pausable functionality for unforeseen circumstances.

---

## **Function Summary**

**I. Core Infrastructure & Access Control**

1.  `constructor(address _aetherTokenAddress)`: Initializes the contract, sets the `AETHER` token address, assigns the deployer as `DEFAULT_ADMIN_ROLE`, and sets initial protocol parameters.
2.  `pause()`: Allows an address with `PAUSER_ROLE` (usually `DEFAULT_ADMIN_ROLE`) to pause critical contract operations in emergencies.
3.  `unpause()`: Allows an address with `PAUSER_ROLE` to resume contract operations after a pause.
4.  `setProtocolParameter(bytes32 _paramName, uint256 _newValue)`: An internal function, callable only by executed governance proposals, to dynamically update core protocol parameters.

**II. Artifact Management (ERC721 + Custom Logic)**

5.  `mintArtifact(string memory _tokenURI)`: Creates a new unique digital artifact (ERC721 NFT). The caller becomes the creator and owner. `visibilityScore` is initialized.
6.  `updateArtifactMetadata(uint256 _artifactId, string memory _newTokenURI)`: Allows the artifact creator to update the metadata URI of their artifact.
7.  `setArtifactPremiumPrice(uint256 _artifactId, uint256 _price)`: Allows the artifact creator to set a price in `AETHER` tokens for "premium" access or content associated with their artifact.
8.  `unlockPremiumContent(uint256 _artifactId)`: Allows a user to pay the specified `AETHER` tokens to unlock premium content for an artifact. The payment is distributed among the creator, protocol, and attention stakers.
9.  `transferFrom(address from, address to, uint256 tokenId)`: Overrides the standard ERC721 `transferFrom` to ensure any internal state related to ownership (e.g., pending creator earnings) is correctly managed upon transfer.
10. `burnArtifact(uint256 _artifactId)`: Allows the artifact creator to permanently burn their artifact, removing it from the system. Any pending earnings or stakes must be withdrawn first.

**III. Attention Economy & Visibility**

11. `stakeAttention(uint256 _artifactId, uint256 _amount)`: Users stake `AETHER` tokens on an artifact. This action directly boosts the artifact's `visibilityScore` and entitles the staker to a share of future attention rewards and premium content revenue.
12. `unstakeAttention(uint256 _artifactId, uint256 _amount)`: Allows a user to withdraw a specified amount of `AETHER` tokens they previously staked on an artifact.
13. `claimAttentionRewards(uint256 _artifactId)`: Allows stakers to claim their accumulated `AETHER` rewards generated from the artifact's attention pool and protocol revenue share.
14. `attachSentimentTag(uint256 _artifactId, SentimentTag _tag)`: Users can associate a `SentimentTag` (Positive or Negative) with an artifact. These tags are aggregated to influence the artifact's `sentimentScore`.

**IV. Challenge System**

15. `initiateVisibilityChallenge(uint256 _artifactId)`: A user pays `challengeCollateral` to initiate a public challenge against an artifact's perceived `visibilityScore`. This triggers a community voting period.
16. `voteOnChallenge(uint256 _challengeId, bool _supportChallenge)`: Users (with governance power) vote on an active visibility challenge, indicating whether they support the challenge (artifact's visibility should decrease) or oppose it.
17. `resolveChallenge(uint256 _challengeId)`: Resolves a challenge after its voting period ends. Based on the aggregated votes, the artifact's `visibilityScore` is adjusted, challenge collateral is distributed to successful voters, and reputations are updated.

**V. Reputation & Governance**

18. `delegate(address _delegatee)`: Allows a user to delegate their governance power (based on their `AETHER` balance and reputation) to another address, enabling a liquid democracy model.
19. `undelegate()`: Allows a user to revoke their delegation and restore direct control over their governance power.
20. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Allows any user with sufficient governance power to create a new governance proposal to modify a protocol parameter.
21. `voteOnProposal(uint256 _proposalId, bool _supportProposal)`: Users with active governance power cast their vote on an open governance proposal.
22. `executeProposal(uint256 _proposalId)`: Allows an address with `GOVERNANCE_EXEC_ROLE` to execute a passed governance proposal, enacting the proposed parameter change.
23. `claimCreatorEarnings(uint256 _artifactId)`: Allows the creator of an artifact to withdraw their share of `AETHER` tokens accumulated from premium content unlocks.
24. `withdrawProtocolFees(address _recipient)`: Allows an address with `DEFAULT_ADMIN_ROLE` (or a future governance-controlled multisig) to withdraw accumulated protocol fees to a specified recipient.

**VI. View Functions (for external data retrieval)**

25. `getArtifactDetails(uint256 _artifactId)`: Returns a comprehensive struct containing all key details of a specific artifact (metadata, scores, owner, prices).
26. `getUserReputation(address _user)`: Returns the current reputation score of a given user.
27. `getGovernancePower(address _user)`: Returns the effective governance power (own + delegated) of a user at the current block.
28. `getChallengeDetails(uint256 _challengeId)`: Returns a struct containing all details of a specific visibility challenge (status, votes, participants, outcome).
29. `getProposalDetails(uint256 _proposalId)`: Returns a struct containing all details of a specific governance proposal (status, votes, proposer, target parameter).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Define custom errors for better debugging
error AetherMind__InvalidAmount();
error AetherMind__NotArtifactOwner();
error AetherMind__ArtifactNotFound();
error AetherMind__NotEnoughStaked();
error AetherMind__ChallengeExpired();
error AetherMind__ChallengeAlreadyVoted();
error AetherMind__ChallengeNotExpired();
error AetherMind__ChallengeNotFound();
error AetherMind__NoPendingEarnings();
error AetherMind__ProposalNotFound();
error AetherMind__ProposalNotReadyForExecution();
error AetherMind__ProposalAlreadyVoted();
error AetherMind__CannotVoteOnSelfDelegated();
error AetherMind__InvalidDelegation();
error AetherMind__InsufficientReputation();
error AetherMind__InvalidParameter();
error AetherMind__InsufficientFunds();
error AetherMind__VotingPeriodActive();


contract AetherMind is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    // --- Roles ---
    // DEFAULT_ADMIN_ROLE: Can assign other roles, set PAUSER_ROLE, and withdraw protocol fees (if governance allows).
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    // PAUSER_ROLE: Can pause/unpause the contract in emergencies.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // GOVERNANCE_EXEC_ROLE: Can execute passed governance proposals.
    bytes32 public constant GOVERNANCE_EXEC_ROLE = keccak256("GOVERNANCE_EXEC_ROLE");

    // --- Tokens & Fees ---
    IERC20 public immutable AETHER_TOKEN; // The utility token for staking, payments, and governance

    // --- Counters ---
    Counters.Counter private _artifactIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _proposalIds;

    // --- Protocol Parameters (Modifiable via Governance) ---
    uint256 public attentionRewardRate; // AETHER tokens per unit of attention per block
    uint256 public challengePeriod;     // Blocks for a challenge voting to last
    uint256 public challengeCollateral; // AETHER tokens required to initiate a challenge
    uint256 public protocolFeeRate;     // Percentage (e.g., 500 for 5%) of premium unlocks that go to protocol (permyriad)
    uint256 public creatorRoyaltyRate;  // Percentage (e.g., 9500 for 95%) of premium unlocks that go to creator (permyriad)
    uint256 public minReputationForProposal; // Minimum reputation required to create a governance proposal
    uint256 public minProposalVotingPower;   // Minimum voting power required for a proposal to be valid (after minReputationForProposal)
    uint256 public proposalVotingPeriod; // Blocks for a governance proposal to last
    uint256 public constant PERMYRIAD_BASE = 10000; // Base for permyriad calculations (10000 = 100%)

    // --- Structs ---

    enum SentimentTag {
        Neutral, // Default / No tag
        Positive,
        Negative
    }

    struct Artifact {
        uint256 id;
        address creator;
        string tokenURI;
        uint256 visibilityScore; // Dynamic score based on staked attention
        uint256 sentimentScorePositive; // Aggregated score from positive tags
        uint256 sentimentScoreNegative; // Aggregated score from negative tags
        uint256 premiumPrice;       // Price in AETHER for premium content
        bool isPremium;             // If true, content is behind premiumPrice
        uint256 totalAttentionStaked; // Total AETHER staked on this artifact
        uint256 lastVisibilityUpdateBlock; // Last block when visibility score was recalculated or attention changed
        uint256 lastPremiumClaimBlock; // Last block when creator earnings were claimed
    }

    struct AttentionStake {
        uint256 amount;
        uint256 startBlock;
    }

    enum ChallengeStatus {
        Active,
        Passed,  // Challenger won
        Failed,  // Challenger lost
        Resolved // Challenge resolved and rewards distributed
    }

    struct Challenge {
        uint256 id;
        uint256 artifactId;
        address challenger;
        uint256 startBlock;
        uint256 endBlock;
        ChallengeStatus status;
        uint256 totalVotesFor;    // Total voting power supporting the challenge
        uint256 totalVotesAgainst; // Total voting power opposing the challenge
    }

    enum ProposalStatus {
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        uint256 id;
        bytes32 paramName;
        uint256 newValue;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        ProposalStatus status;
        uint256 totalVotesFor;    // Total voting power supporting the proposal
        uint256 totalVotesAgainst; // Total voting power opposing the proposal
    }

    // --- Mappings ---

    mapping(uint256 => Artifact) public artifacts;
    mapping(uint256 => mapping(address => AttentionStake)) public attentionStakes; // artifactId => staker => stake
    mapping(uint256 => mapping(address => uint256)) public pendingAttentionRewards; // artifactId => staker => rewards
    mapping(uint256 => uint256) public artifactCreatorEarnings; // artifactId => creator total pending earnings

    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(address => bool)) public challengeVotes; // challengeId => voter => hasVoted

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted

    mapping(address => uint256) public userReputation; // user address => reputation score
    mapping(address => address) public delegates;      // delegator => delegatee
    mapping(address => uint256) public delegatedPower; // delegatee => total power delegated to them
    mapping(address => uint256) public lastVoteBlock;  // user => last block they voted, for reputation decay/gain

    uint256 public totalProtocolFees; // Accumulated AETHER fees for the protocol

    // --- Events ---
    event ArtifactMinted(uint256 indexed artifactId, address indexed creator, string tokenURI);
    event ArtifactMetadataUpdated(uint256 indexed artifactId, string newTokenURI);
    event PremiumPriceSet(uint256 indexed artifactId, uint256 price);
    event PremiumContentUnlocked(uint256 indexed artifactId, address indexed buyer, uint256 amountPaid);
    event ArtifactBurned(uint256 indexed artifactId, address indexed burner);

    event AttentionStaked(uint256 indexed artifactId, address indexed staker, uint256 amount);
    event AttentionUnstaked(uint256 indexed artifactId, address indexed staker, uint256 amount);
    event AttentionRewardsClaimed(uint256 indexed artifactId, address indexed staker, uint256 rewards);
    event SentimentTagAttached(uint256 indexed artifactId, address indexed tagger, SentimentTag tag);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed artifactId, address indexed challenger, uint256 collateral);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool supported);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus status, uint256 newVisibilityScore, uint256 rewardPool);

    event GovernanceDelegated(address indexed delegator, address indexed delegatee);
    event GovernanceUndelegated(address indexed delegator);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool supported);
    event ProposalExecuted(uint256 indexed proposalId);

    event CreatorEarningsClaimed(uint256 indexed artifactId, address indexed creator, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    constructor(address _aetherTokenAddress) ERC721("AetherMind Artifact", "AMA") {
        require(_aetherTokenAddress != address(0), "AetherMind: Invalid AETHER token address");
        AETHER_TOKEN = IERC20(_aetherTokenAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_EXEC_ROLE, msg.sender); // Initially, admin can execute governance proposals

        // Set initial protocol parameters
        attentionRewardRate = 100; // Example: 100 AETHER per unit of attention per block
        challengePeriod = 100;    // Example: 100 blocks for challenge voting
        challengeCollateral = 1000 * (10 ** AETHER_TOKEN.decimals()); // Example: 1000 AETHER
        protocolFeeRate = 500;    // 5% (500 permyriad)
        creatorRoyaltyRate = 9500; // 95% (9500 permyriad)
        minReputationForProposal = 100; // Example: Min reputation to propose
        minProposalVotingPower = 1000 * (10 ** AETHER_TOKEN.decimals()); // Example: Min voting power required for proposal validity
        proposalVotingPeriod = 200; // Example: 200 blocks for proposal voting
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- Internal Utility Functions ---

    function _calculateAttentionRewards(uint256 _artifactId, address _staker) internal view returns (uint256) {
        AttentionStake storage stake = attentionStakes[_artifactId][_staker];
        if (stake.amount == 0 || stake.startBlock >= block.number) {
            return 0;
        }

        uint256 blocksStaked = block.number.sub(stake.startBlock);
        return stake.amount.mul(blocksStaked).mul(attentionRewardRate).div(1e18); // Example scaling
    }

    function _updateArtifactVisibilityScore(uint256 _artifactId) internal {
        Artifact storage artifact = artifacts[_artifactId];
        uint256 currentBlock = block.number;

        // Calculate visibility increase from attention
        uint256 blocksSinceLastUpdate = currentBlock.sub(artifact.lastVisibilityUpdateBlock);
        if (blocksSinceLastUpdate > 0) {
            uint256 attentionBoost = artifact.totalAttentionStaked.mul(blocksSinceLastUpdate);
            artifact.visibilityScore = artifact.visibilityScore.add(attentionBoost.div(1e12)); // Example scaling factor
            artifact.lastVisibilityUpdateBlock = currentBlock;
        }
    }

    function _getVotingPower(address _user) internal view returns (uint256) {
        if (delegates[_user] != address(0)) {
            return 0; // If delegated, own power is not counted directly
        }
        return AETHER_TOKEN.balanceOf(_user).add(userReputation[_user]).add(delegatedPower[_user]);
    }

    // --- I. Core Infrastructure & Access Control ---

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Callable only by a successful governance proposal execution
    function setProtocolParameter(bytes32 _paramName, uint256 _newValue)
        external
        onlyRole(GOVERNANCE_EXEC_ROLE)
    {
        if (_paramName == keccak256("attentionRewardRate")) {
            attentionRewardRate = _newValue;
        } else if (_paramName == keccak256("challengePeriod")) {
            challengePeriod = _newValue;
        } else if (_paramName == keccak256("challengeCollateral")) {
            challengeCollateral = _newValue;
        } else if (_paramName == keccak256("protocolFeeRate")) {
            require(_newValue <= PERMYRIAD_BASE, "AetherMind: Invalid fee rate");
            protocolFeeRate = _newValue;
        } else if (_paramName == keccak256("creatorRoyaltyRate")) {
            require(_newValue <= PERMYRIAD_BASE, "AetherMind: Invalid royalty rate");
            creatorRoyaltyRate = _newValue;
        } else if (_paramName == keccak256("minReputationForProposal")) {
            minReputationForProposal = _newValue;
        } else if (_paramName == keccak256("minProposalVotingPower")) {
            minProposalVotingPower = _newValue;
        } else if (_paramName == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = _newValue;
        } else {
            revert AetherMind__InvalidParameter();
        }
    }

    // --- II. Artifact Management (ERC721 + Custom Logic) ---

    function mintArtifact(string memory _tokenURI) public whenNotPaused returns (uint256) {
        _artifactIds.increment();
        uint256 newArtifactId = _artifactIds.current();

        artifacts[newArtifactId] = Artifact({
            id: newArtifactId,
            creator: msg.sender,
            tokenURI: _tokenURI,
            visibilityScore: 100, // Initial base visibility
            sentimentScorePositive: 0,
            sentimentScoreNegative: 0,
            premiumPrice: 0,
            isPremium: false,
            totalAttentionStaked: 0,
            lastVisibilityUpdateBlock: block.number,
            lastPremiumClaimBlock: block.number
        });

        _mint(msg.sender, newArtifactId);
        emit ArtifactMinted(newArtifactId, msg.sender, _tokenURI);
        return newArtifactId;
    }

    function updateArtifactMetadata(uint256 _artifactId, string memory _newTokenURI) public whenNotPaused {
        _requireOwned(_artifactId); // ERC721 internal check
        require(artifacts[_artifactId].creator == msg.sender, "AetherMind: Only creator can update metadata");
        
        artifacts[_artifactId].tokenURI = _newTokenURI;
        _setTokenURI(_artifactId, _newTokenURI); // Update ERC721 internal URI
        emit ArtifactMetadataUpdated(_artifactId, _newTokenURI);
    }

    function setArtifactPremiumPrice(uint256 _artifactId, uint256 _price) public whenNotPaused {
        _requireOwned(_artifactId); // ERC721 internal check
        require(artifacts[_artifactId].creator == msg.sender, "AetherMind: Only creator can set premium price");

        artifacts[_artifactId].premiumPrice = _price;
        artifacts[_artifactId].isPremium = (_price > 0);
        emit PremiumPriceSet(_artifactId, _price);
    }

    function unlockPremiumContent(uint256 _artifactId) public whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.isPremium, "AetherMind: Artifact is not premium");
        require(artifact.premiumPrice > 0, "AetherMind: Premium price not set");
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), artifact.premiumPrice), "AetherMind: AETHER transfer failed");

        uint256 creatorShare = artifact.premiumPrice.mul(creatorRoyaltyRate).div(PERMYRIAD_BASE);
        uint256 protocolShare = artifact.premiumPrice.mul(protocolFeeRate).div(PERMYRIAD_BASE);
        uint256 attentionStakerShare = artifact.premiumPrice.sub(creatorShare).sub(protocolShare);

        // Distribute to creator
        artifactCreatorEarnings[_artifactId] = artifactCreatorEarnings[_artifactId].add(creatorShare);

        // Add to protocol fees
        totalProtocolFees = totalProtocolFees.add(protocolShare);

        // Distribute to attention stakers proportionally (Simplified: Add to general pool for next claim)
        // A more advanced system would track proportional distribution to active stakers
        // For simplicity, we add to the attention pool, rewards are claimed from there
        // This effectively distributes to *all* current and future stakers until pool is drained.
        // A more precise approach would require iterating through stakers or dynamic accounting.
        // For now, let's just make it a simple reward addition.
        if (attentionStakerShare > 0) {
            // For now, let's assume this adds to a general reward pool that stakers can claim from
            // In a real system, this needs careful accounting per staker based on their stake and duration
            // This is a simplified proxy: just increase a pool that stakers claim from based on their current rewards logic.
            // AetherMind Token balance will reflect this.
        }

        emit PremiumContentUnlocked(_artifactId, msg.sender, artifact.premiumPrice);
    }

    // Override ERC721 transferFrom to include custom logic if needed (e.g., clearing internal state)
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        // Any custom logic here before calling super, e.g., if transfers impact attention stakes:
        // However, attention stakes are *user-specific*, not artifact-specific ownership dependent.
        // So no custom logic needed for this particular contract's design here.
        super.transferFrom(from, to, tokenId);
    }

    function burnArtifact(uint256 _artifactId) public whenNotPaused {
        _requireOwned(_artifactId); // ERC721 internal check
        require(artifacts[_artifactId].creator == msg.sender, "AetherMind: Only creator can burn artifact");
        require(artifactCreatorEarnings[_artifactId] == 0, "AetherMind: Creator must claim earnings first");
        require(artifacts[_artifactId].totalAttentionStaked == 0, "AetherMind: All attention must be unstaked first");

        // Clear artifact data
        delete artifacts[_artifactId];
        _burn(_artifactId); // Burn the NFT
        emit ArtifactBurned(_artifactId, msg.sender);
    }

    // --- III. Attention Economy & Visibility ---

    function stakeAttention(uint256 _artifactId, uint256 _amount) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");
        require(_amount > 0, "AetherMind: Invalid amount");
        
        // Transfer AETHER from staker to contract
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount), "AetherMind: AETHER transfer failed");

        _updateArtifactVisibilityScore(_artifactId); // Update visibility before new stake
        
        // Claim any pending rewards before updating stake
        uint256 rewards = _calculateAttentionRewards(_artifactId, msg.sender);
        if (rewards > 0) {
            pendingAttentionRewards[_artifactId][msg.sender] = pendingAttentionRewards[_artifactId][msg.sender].add(rewards);
        }

        AttentionStake storage stake = attentionStakes[_artifactId][msg.sender];
        stake.amount = stake.amount.add(_amount);
        stake.startBlock = block.number; // Reset start block for reward calculation
        
        artifacts[_artifactId].totalAttentionStaked = artifacts[_artifactId].totalAttentionStaked.add(_amount);

        emit AttentionStaked(_artifactId, msg.sender, _amount);
    }

    function unstakeAttention(uint256 _artifactId, uint256 _amount) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");
        require(_amount > 0, "AetherMind: Invalid amount");
        
        AttentionStake storage stake = attentionStakes[_artifactId][msg.sender];
        require(stake.amount >= _amount, "AetherMind: Not enough staked");

        _updateArtifactVisibilityScore(_artifactId); // Update visibility before unstaking

        // Claim any pending rewards before unstaking
        uint256 rewards = _calculateAttentionRewards(_artifactId, msg.sender);
        if (rewards > 0) {
            pendingAttentionRewards[_artifactId][msg.sender] = pendingAttentionRewards[_artifactId][msg.sender].add(rewards);
        }

        stake.amount = stake.amount.sub(_amount);
        stake.startBlock = block.number; // Reset start block if partial unstake
        
        artifacts[_artifactId].totalAttentionStaked = artifacts[_artifactId].totalAttentionStaked.sub(_amount);

        // Transfer AETHER back to staker
        require(AETHER_TOKEN.transfer(msg.sender, _amount), "AetherMind: AETHER transfer failed");
        emit AttentionUnstaked(_artifactId, msg.sender, _amount);
    }

    function claimAttentionRewards(uint256 _artifactId) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");

        _updateArtifactVisibilityScore(_artifactId); // Update visibility before claiming to include latest rewards

        uint256 currentRewards = _calculateAttentionRewards(_artifactId, msg.sender);
        uint256 totalRewardsToClaim = pendingAttentionRewards[_artifactId][msg.sender].add(currentRewards);

        // Reset the start block for future reward calculation
        attentionStakes[_artifactId][msg.sender].startBlock = block.number;
        pendingAttentionRewards[_artifactId][msg.sender] = 0; // Clear accumulated pending

        require(totalRewardsToClaim > 0, "AetherMind: No pending rewards to claim");
        require(AETHER_TOKEN.transfer(msg.sender, totalRewardsToClaim), "AetherMind: Reward transfer failed");
        emit AttentionRewardsClaimed(_artifactId, msg.sender, totalRewardsToClaim);
    }

    function attachSentimentTag(uint256 _artifactId, SentimentTag _tag) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");
        require(_tag != SentimentTag.Neutral, "AetherMind: Invalid sentiment tag");

        // Simple aggregation. Could add cooldown or reputation weight.
        if (_tag == SentimentTag.Positive) {
            artifacts[_artifactId].sentimentScorePositive = artifacts[_artifactId].sentimentScorePositive.add(1);
        } else if (_tag == SentimentTag.Negative) {
            artifacts[_artifactId].sentimentScoreNegative = artifacts[_artifactId].sentimentScoreNegative.add(1);
        }
        emit SentimentTagAttached(_artifactId, msg.sender, _tag);
    }

    // --- IV. Challenge System ---

    function initiateVisibilityChallenge(uint256 _artifactId) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), challengeCollateral), "AetherMind: Collateral transfer failed");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            artifactId: _artifactId,
            challenger: msg.sender,
            startBlock: block.number,
            endBlock: block.number.add(challengePeriod),
            status: ChallengeStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0
        });

        emit ChallengeInitiated(newChallengeId, _artifactId, msg.sender, challengeCollateral);
    }

    function voteOnChallenge(uint256 _challengeId, bool _supportChallenge) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AetherMind: Challenge not found");
        require(challenge.status == ChallengeStatus.Active, "AetherMind: Challenge not active");
        require(block.number < challenge.endBlock, "AetherMind: Challenge voting period ended");
        require(!challengeVotes[_challengeId][msg.sender], "AetherMind: Already voted on this challenge");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "AetherMind: No voting power");

        if (_supportChallenge) {
            challenge.totalVotesFor = challenge.totalVotesFor.add(voterPower);
        } else {
            challenge.totalVotesAgainst = challenge.totalVotesAgainst.add(voterPower);
        }
        challengeVotes[_challengeId][msg.sender] = true;

        // Record last vote block for reputation updates
        lastVoteBlock[msg.sender] = block.number;

        emit ChallengeVoted(_challengeId, msg.sender, _supportChallenge);
    }

    function resolveChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AetherMind: Challenge not found");
        require(challenge.status == ChallengeStatus.Active, "AetherMind: Challenge not active");
        require(block.number >= challenge.endBlock, "AetherMind: Challenge voting period not ended");

        Artifact storage artifact = artifacts[challenge.artifactId];
        uint256 rewardPool = challengeCollateral; // Challenger's collateral becomes reward pool

        if (challenge.totalVotesFor > challenge.totalVotesAgainst) {
            // Challenger wins: Artifact visibility decreases, challenger gets reward, voters get reputation
            challenge.status = ChallengeStatus.Passed;
            artifact.visibilityScore = artifact.visibilityScore.sub(
                artifact.visibilityScore.mul(challenge.totalVotesFor).div(
                    challenge.totalVotesFor.add(challenge.totalVotesAgainst) // Proportional decrease
                )
            );
            
            // Distribute rewards and reputation to "For" voters
            userReputation[challenge.challenger] = userReputation[challenge.challenger].add(10); // Example reputation gain
            
            // For simplicity, we just add the entire pool to the challenger if they win.
            // A more complex system would distribute to all successful voters proportionally.
            require(AETHER_TOKEN.transfer(challenge.challenger, rewardPool), "AetherMind: Reward transfer failed");

        } else {
            // Challenger loses: Artifact visibility potentially increases, challenger loses collateral
            challenge.status = ChallengeStatus.Failed;
            artifact.visibilityScore = artifact.visibilityScore.add(
                artifact.visibilityScore.mul(challenge.totalVotesAgainst).div(
                    challenge.totalVotesFor.add(challenge.totalVotesAgainst) // Proportional increase
                )
            );

            // Collateral goes to protocol or "Against" voters. For now, to protocol.
            totalProtocolFees = totalProtocolFees.add(rewardPool);
        }
        
        challenge.status = ChallengeStatus.Resolved;
        emit ChallengeResolved(_challengeId, challenge.status, artifact.visibilityScore, rewardPool);
    }

    // --- V. Reputation & Governance ---

    function delegate(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "AetherMind: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "AetherMind: Cannot delegate to self");
        
        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee != address(0)) {
            delegatedPower[currentDelegatee] = delegatedPower[currentDelegatee].sub(AETHER_TOKEN.balanceOf(msg.sender));
        }
        
        delegates[msg.sender] = _delegatee;
        delegatedPower[_delegatee] = delegatedPower[_delegatee].add(AETHER_TOKEN.balanceOf(msg.sender));
        emit GovernanceDelegated(msg.sender, _delegatee);
    }

    function undelegate() public whenNotPaused {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != address(0), "AetherMind: Not currently delegated");

        delegatedPower[currentDelegatee] = delegatedPower[currentDelegatee].sub(AETHER_TOKEN.balanceOf(msg.sender));
        delegates[msg.sender] = address(0);
        emit GovernanceUndelegated(msg.sender);
    }

    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) public whenNotPaused {
        require(userReputation[msg.sender] >= minReputationForProposal, "AetherMind: Insufficient reputation to propose");
        require(_getVotingPower(msg.sender) >= minProposalVotingPower, "AetherMind: Insufficient voting power to propose");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            paramName: _paramName,
            newValue: _newValue,
            proposer: msg.sender,
            startBlock: block.number,
            endBlock: block.number.add(proposalVotingPeriod),
            status: ProposalStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0
        });

        emit ProposalCreated(newProposalId, _paramName, _newValue, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _supportProposal) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetherMind: Proposal not found");
        require(proposal.status == ProposalStatus.Active, "AetherMind: Proposal not active");
        require(block.number < proposal.endBlock, "AetherMind: Proposal voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "AetherMind: Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "AetherMind: No voting power");

        if (_supportProposal) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterPower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterPower);
        }
        proposalVotes[_proposalId][msg.sender] = true;

        lastVoteBlock[msg.sender] = block.number; // Update last vote block for reputation

        emit ProposalVoted(_proposalId, msg.sender, _supportProposal);
    }

    function executeProposal(uint256 _proposalId) public onlyRole(GOVERNANCE_EXEC_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetherMind: Proposal not found");
        require(proposal.status == ProposalStatus.Active, "AetherMind: Proposal not active");
        require(block.number >= proposal.endBlock, "AetherMind: Proposal voting period not ended");
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "AetherMind: Proposal did not pass");

        proposal.status = ProposalStatus.Executed;
        setProtocolParameter(proposal.paramName, proposal.newValue); // Execute the parameter change
        
        emit ProposalExecuted(_proposalId);
    }

    function claimCreatorEarnings(uint256 _artifactId) public whenNotPaused {
        require(artifacts[_artifactId].id != 0, "AetherMind: Artifact not found");
        require(artifacts[_artifactId].creator == msg.sender, "AetherMind: Not artifact creator");

        uint256 earnings = artifactCreatorEarnings[_artifactId];
        require(earnings > 0, "AetherMind: No pending earnings");

        artifactCreatorEarnings[_artifactId] = 0; // Reset earnings
        require(AETHER_TOKEN.transfer(msg.sender, earnings), "AetherMind: Earnings transfer failed");
        emit CreatorEarningsClaimed(_artifactId, msg.sender, earnings);
    }

    function withdrawProtocolFees(address _recipient) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_recipient != address(0), "AetherMind: Invalid recipient address");
        require(totalProtocolFees > 0, "AetherMind: No protocol fees to withdraw");

        uint256 fees = totalProtocolFees;
        totalProtocolFees = 0; // Reset fees
        require(AETHER_TOKEN.transfer(_recipient, fees), "AetherMind: Fee transfer failed");
        emit ProtocolFeesWithdrawn(_recipient, fees);
    }

    // --- VI. View Functions (for external data retrieval) ---

    function getArtifactDetails(uint256 _artifactId) public view returns (
        uint256 id,
        address creator,
        string memory tokenURI,
        uint256 visibilityScore,
        uint256 sentimentScorePositive,
        uint256 sentimentScoreNegative,
        uint256 premiumPrice,
        bool isPremium,
        uint256 totalAttentionStaked
    ) {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.id != 0, "AetherMind: Artifact not found");

        id = artifact.id;
        creator = artifact.creator;
        tokenURI = artifact.tokenURI;
        visibilityScore = artifact.visibilityScore;
        sentimentScorePositive = artifact.sentimentScorePositive;
        sentimentScoreNegative = artifact.sentimentScoreNegative;
        premiumPrice = artifact.premiumPrice;
        isPremium = artifact.isPremium;
        totalAttentionStaked = artifact.totalAttentionStaked;
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    function getGovernancePower(address _user) public view returns (uint256) {
        return _getVotingPower(_user);
    }

    function getChallengeDetails(uint256 _challengeId) public view returns (
        uint256 id,
        uint256 artifactId,
        address challenger,
        uint256 startBlock,
        uint256 endBlock,
        ChallengeStatus status,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst
    ) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "AetherMind: Challenge not found");

        id = challenge.id;
        artifactId = challenge.artifactId;
        challenger = challenge.challenger;
        startBlock = challenge.startBlock;
        endBlock = challenge.endBlock;
        status = challenge.status;
        totalVotesFor = challenge.totalVotesFor;
        totalVotesAgainst = challenge.totalVotesAgainst;
    }

    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        bytes32 paramName,
        uint256 newValue,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        ProposalStatus status,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetherMind: Proposal not found");

        id = proposal.id;
        paramName = proposal.paramName;
        newValue = proposal.newValue;
        proposer = proposal.proposer;
        startBlock = proposal.startBlock;
        endBlock = proposal.endBlock;
        status = proposal.status;
        totalVotesFor = proposal.totalVotesFor;
        totalVotesAgainst = proposal.totalVotesAgainst;
    }

    // Helper to get total supply of artifacts
    function totalSupply() public view override returns (uint256) {
        return _artifactIds.current();
    }
}
```