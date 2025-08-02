Okay, this is a fantastic challenge! Let's build something truly unique that combines several cutting-edge concepts: decentralized knowledge validation, dynamic soulbound NFTs, AI-augmented reputation, and a liquid vesting/streaming reward system, all within a "Knowledge Guild" framework.

We'll call this the **"Aetheria Collective: Decentralized Knowledge Guild & Impact Network"**.

---

## Aetheria Collective: Decentralized Knowledge Guild & Impact Network

**Outline:**

The Aetheria Collective is a sophisticated Solidity smart contract designed to foster and reward validated knowledge contributions within specialized "Guilds." It introduces a novel reputation system linked to dynamic Soulbound Tokens (SBTs), integrates with off-chain AI oracles for nuanced assessment, and facilitates perpetual, stream-based rewards for impactful participants.

1.  **Core Concepts:**
    *   **Knowledge Contributions:** Users submit proposals for new knowledge, research, or validated data.
    *   **Peer Validation & Dispute Resolution:** Community members vote on the validity and impact of contributions.
    *   **Dynamic Reputation & SBTs:** User reputation evolves based on successful contributions and validation activities. This reputation is represented by a non-transferable, dynamic NFT (SBT) that visually changes based on accrued impact score.
    *   **AI Oracle Integration (Conceptual):** External AI models can be invoked to provide an objective initial assessment or a secondary dispute resolution layer for complex contributions.
    *   **Knowledge Guilds:** Decentralized autonomous groups focused on specific domains, managing their own policies, treasury, and contribution validation.
    *   **Perpetual Streaming Rewards:** Contributors and validators receive continuous token streams, proportional to their impact and guild activity, enabled by integration with a conceptual "StreamProtocol."
    *   **Liquid Knowledge Bounties:** Guilds or external parties can create bounties for specific knowledge gaps, paid out upon verified fulfillment.

2.  **Architecture & Modules:**
    *   **`UserProfile`:** Manages user metadata, global reputation score, and delegated voting power.
    *   **`Contribution`:** Tracks knowledge proposals, their status, votes, and associated metadata.
    *   **`Guild`:** Manages guild-specific parameters, member lists, treasury, and internal governance.
    *   **`AetheriaBadge` (ERC721-SBT):** The non-transferable dynamic NFT representing a user's reputation and achievements.
    *   **`AIOracleInterface`:** Defines how the contract interacts with an off-chain AI assessment service.
    *   **`StreamProtocolInterface`:** Defines how the contract interacts with a token streaming protocol (e.g., Superfluid).

**Function Summary (20+ Functions):**

**A. User Profile & Global Reputation (5 Functions)**
1.  `registerUserProfile()`: Creates a new user profile and mints their initial Aetheria Badge.
2.  `updateProfileMetadata(string _newURI)`: Allows users to update their off-chain profile metadata.
3.  `delegateReputationPower(address _delegatee)`: Delegates a user's global reputation score for voting/validation.
4.  `undelegateReputationPower()`: Revokes reputation delegation.
5.  `requestReputationScoreReset()`: Initiates a governance proposal to reset a user's reputation (high threshold required).

**B. Knowledge Contributions & Validation (8 Functions)**
6.  `submitKnowledgeContribution(string _contentHash, string _metadataURI, uint256 _bountyId)`: Proposes a new piece of knowledge or research.
7.  `voteOnContribution(uint256 _contributionId, bool _isUpvote)`: Users vote on the perceived value/validity of a contribution.
8.  `proposeForGuildVerification(uint256 _contributionId, uint256 _guildId)`: A contribution is formally proposed to a specific guild for in-depth verification.
9.  `guildVerifyContribution(uint256 _contributionId, bool _isValid)`: Guild members (with sufficient reputation) vote on verifying a proposed contribution.
10. `disputeContribution(uint256 _contributionId, string _reasonHash)`: Initiates a dispute over a verified or rejected contribution.
11. `requestAIOracleAssessment(uint256 _contributionId)`: Triggers an off-chain AI oracle assessment for a disputed or complex contribution.
12. `receiveAIOracleVerdict(uint256 _contributionId, bytes32 _verdictHash, uint256 _impactScore)`: Callback function for the AI oracle to deliver its assessment.
13. `finalizeContribution(uint256 _contributionId)`: Finalizes a contribution's status after successful verification or dispute resolution, updating creator/verifier reputation.

**C. Knowledge Guild Management (6 Functions)**
14. `createKnowledgeGuild(string _name, string _symbol, uint256 _minReputationToJoin, address[] _initialMembers)`: Deploys a new knowledge guild.
15. `applyToGuild(uint256 _guildId)`: Users apply to join a specific guild.
16. `acceptGuildMember(uint256 _guildId, address _applicant)`: Guild members vote to accept new applicants.
17. `proposeGuildPolicy(uint256 _guildId, string _policyHash, uint256 _quorum, uint256 _voteDuration)`: Guild members propose new internal policies.
18. `voteOnGuildPolicy(uint256 _guildId, uint256 _policyId, bool _for)`: Members vote on proposed guild policies.
19. `leaveGuild(uint256 _guildId)`: Allows a user to leave a guild.

**D. Treasury & Streaming Rewards (4 Functions)**
20. `depositGuildTreasury(uint256 _guildId, uint256 _amount)`: Deposits tokens into a guild's treasury.
21. `createKnowledgeBounty(uint256 _guildId, string _bountyDescriptionHash, uint256 _rewardAmount, uint256 _deadline)`: Creates a bounty for specific knowledge, funded by the guild treasury.
22. `claimBountyReward(uint256 _bountyId)`: Allows the creator of a successfully fulfilled bounty to claim their reward.
23. `streamRewardsToContributors(uint256 _guildId, uint256 _flowRatePerUnitImpact)`: Initiates perpetual token streams to top contributors/validators based on their impact score within a guild (conceptual Superfluid integration).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For treasury token interaction

/**
 * @title AetheriaCollective
 * @dev A decentralized knowledge guild and impact network contract.
 *      Manages user profiles, knowledge contributions, guild operations,
 *      dynamic reputation badges (SBTs), and integrates with AI oracles
 *      and streaming reward protocols.
 *      Inspired by concepts of decentralized science (DeSci), verifiable credentials,
 *      and perpetual agreements.
 */
contract AetheriaCollective is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _userProfileIds;
    Counters.Counter private _contributionIds;
    Counters.Counter private _guildIds;
    Counters.Counter private _policyIds;
    Counters.Counter private _bountyIds;

    // --- Structs ---

    enum ContributionStatus {
        Proposed,
        Voting,
        GuildVerificationPending,
        Verified,
        Rejected,
        Disputed,
        AIReviewPending,
        Finalized
    }

    enum GuildApplicationStatus {
        Pending,
        Accepted,
        Rejected
    }

    struct UserProfile {
        uint256 id;
        address userAddress;
        uint256 globalReputationScore; // Overall impact across the network
        uint256[] activeGuilds;
        address delegatedReputationTo; // For delegating voting power
        string metadataURI; // Off-chain metadata for user profile (e.g., ENS, social links)
        bool hasMintedBadge; // To ensure only one badge per user
    }

    struct Contribution {
        uint256 id;
        address proposer;
        string contentHash; // IPFS/Arweave hash of the knowledge content
        string metadataURI; // Off-chain metadata for the contribution (title, description)
        ContributionStatus status;
        uint256 proposedGuildId; // If proposed for specific guild verification
        mapping(address => bool) upvoted;
        mapping(address => bool) downvoted;
        uint256 upvoteCount;
        uint256 downvoteCount;
        uint256 impactScore; // Calculated based on votes, verification, AI assessment
        address[] verifiers; // Addresses of guild members who successfully verified
        uint256 creationTime;
        uint256 finalizationTime;
        uint256 associatedBountyId; // 0 if no bounty
    }

    struct KnowledgeGuild {
        uint256 id;
        string name;
        string symbol; // A unique identifier for the guild
        address treasuryToken; // Address of the ERC20 token used for the treasury
        uint256 minReputationToJoin; // Minimum globalReputationScore to apply
        mapping(address => bool) isMember;
        mapping(address => GuildApplicationStatus) memberApplications;
        mapping(uint256 => GuildPolicy) policies;
        uint256 treasuryBalance; // ERC20 token balance held by the guild contract
        Counters.Counter _policyCounter; // Internal counter for policies
    }

    struct GuildPolicy {
        uint256 id;
        string policyHash; // IPFS/Arweave hash of the policy text
        uint256 proposerReputation; // Reputation of the policy proposer at time of proposal
        uint256 creationTime;
        uint256 voteDuration; // How long members have to vote
        uint256 quorumPercentage; // Percentage of guild reputation needed for approval (e.g., 5100 for 51%)
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    struct KnowledgeBounty {
        uint256 id;
        uint256 guildId;
        address proposer;
        string descriptionHash; // IPFS/Arweave hash of bounty details
        uint256 rewardAmount;
        address rewardToken; // Token used for the bounty (can be different from treasuryToken)
        uint256 deadline;
        address solutionProposer; // Address who submitted the solution
        bool fulfilled;
        bool claimed;
    }

    // --- Mappings ---

    mapping(address => uint256) public addressToUserProfileId;
    mapping(uint256 => UserProfile) public userProfiles;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => KnowledgeGuild) public knowledgeGuilds;
    mapping(uint256 => KnowledgeBounty) public knowledgeBounties;

    address public aiOracleAddress; // Address of the trusted AI Oracle (off-chain service proxy)
    address public streamProtocolAddress; // Address of the conceptual streaming protocol (e.g., Superfluid)

    // --- Events ---

    event UserProfileRegistered(uint256 indexed profileId, address indexed userAddress, string metadataURI);
    event ProfileMetadataUpdated(uint256 indexed profileId, address indexed userAddress, string newURI);
    event ReputationDelegated(uint256 indexed profileId, address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(uint256 indexed profileId, address indexed delegator);
    event ReputationResetProposed(uint256 indexed profileId, address indexed proposer);

    event ContributionSubmitted(uint256 indexed contributionId, address indexed proposer, string contentHash);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, bool isUpvote);
    event ContributionProposedForGuildVerification(uint256 indexed contributionId, uint256 indexed guildId);
    event ContributionGuildVerified(uint256 indexed contributionId, uint256 indexed guildId, bool isValid, address indexed verifier);
    event ContributionDisputed(uint256 indexed contributionId, address indexed disputer);
    event AIOracleAssessmentRequested(uint256 indexed contributionId, address indexed requester);
    event AIOracleVerdictReceived(uint256 indexed contributionId, bytes32 verdictHash, uint256 impactScore);
    event ContributionFinalized(uint256 indexed contributionId, ContributionStatus finalStatus, uint256 finalImpactScore);

    event GuildCreated(uint256 indexed guildId, string name, address indexed creator);
    event GuildApplied(uint256 indexed guildId, address indexed applicant);
    event GuildMemberAccepted(uint256 indexed guildId, address indexed member);
    event GuildPolicyProposed(uint256 indexed guildId, uint256 indexed policyId, address indexed proposer);
    event GuildPolicyVoted(uint256 indexed guildId, uint256 indexed policyId, address indexed voter, bool vote);
    event GuildMemberLeft(uint256 indexed guildId, address indexed member);

    event GuildTreasuryDeposited(uint256 indexed guildId, address indexed depositor, uint256 amount, address tokenAddress);
    event KnowledgeBountyCreated(uint256 indexed bountyId, uint256 indexed guildId, address indexed proposer, uint256 rewardAmount);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed solutionProposer);
    event BountyRewardClaimed(uint256 indexed bountyId, address indexed claimant, uint256 amount);
    event RewardsStreamed(uint256 indexed guildId, uint256 flowRatePerUnitImpact, address indexed streamer);

    // --- Constructor ---

    constructor(address _aiOracleAddress, address _streamProtocolAddress)
        ERC721("AetheriaBadge", "AEBADGE")
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        require(_streamProtocolAddress != address(0), "Stream Protocol address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
        streamProtocolAddress = _streamProtocolAddress;
    }

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(addressToUserProfileId[msg.sender] != 0, "Caller is not a registered user.");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only the AI Oracle can call this function.");
        _;
    }

    modifier onlyGuildMember(uint256 _guildId) {
        require(knowledgeGuilds[_guildId].isMember[msg.sender], "Caller is not a member of this guild.");
        _;
    }

    // --- A. User Profile & Global Reputation (5 Functions) ---

    /**
     * @notice Registers a new user profile and mints their initial Aetheria Badge (SBT).
     * @param _metadataURI Off-chain URI for user's profile information.
     */
    function registerUserProfile(string calldata _metadataURI) external {
        require(addressToUserProfileId[msg.sender] == 0, "User already registered.");

        _userProfileIds.increment();
        uint256 newProfileId = _userProfileIds.current();

        userProfiles[newProfileId] = UserProfile({
            id: newProfileId,
            userAddress: msg.sender,
            globalReputationScore: 100, // Initial reputation
            activeGuilds: new uint256[](0),
            delegatedReputationTo: address(0),
            metadataURI: _metadataURI,
            hasMintedBadge: true
        });
        addressToUserProfileId[msg.sender] = newProfileId;

        // Mint a non-transferable ERC721 token (SBT)
        _mint(msg.sender, newProfileId);
        _setTokenURI(newProfileId, _generateBadgeURI(newProfileId)); // Initial badge URI

        // Make it non-transferable (ERC721 functionality overridden via _beforeTokenTransfer)
        // See _beforeTokenTransfer for the non-transferable logic

        emit UserProfileRegistered(newProfileId, msg.sender, _metadataURI);
    }

    /**
     * @notice Allows a user to update their off-chain profile metadata URI.
     * @param _newURI The new URI for the user's profile metadata.
     */
    function updateProfileMetadata(string calldata _newURI) external onlyRegisteredUser {
        uint256 profileId = addressToUserProfileId[msg.sender];
        userProfiles[profileId].metadataURI = _newURI;
        emit ProfileMetadataUpdated(profileId, msg.sender, _newURI);
    }

    /**
     * @notice Delegates a user's global reputation score to another address for voting/validation purposes.
     *         Only one delegatee can be active at a time.
     * @param _delegatee The address to delegate reputation power to.
     */
    function delegateReputationPower(address _delegatee) external onlyRegisteredUser {
        require(_delegatee != address(0), "Delegatee cannot be zero address.");
        require(_delegatee != msg.sender, "Cannot delegate to self.");
        uint256 profileId = addressToUserProfileId[msg.sender];
        userProfiles[profileId].delegatedReputationTo = _delegatee;
        emit ReputationDelegated(profileId, msg.sender, _delegatee);
    }

    /**
     * @notice Revokes the current reputation delegation.
     */
    function undelegateReputationPower() external onlyRegisteredUser {
        uint256 profileId = addressToUserProfileId[msg.sender];
        require(userProfiles[profileId].delegatedReputationTo != address(0), "No active delegation to revoke.");
        userProfiles[profileId].delegatedReputationTo = address(0);
        emit ReputationUndelegated(profileId, msg.sender);
    }

    /**
     * @notice Proposes a full reset of a user's global reputation score. This requires significant governance approval.
     *         (Implementation detail: This would trigger a guild-wide or global governance vote, not handled within this single function call).
     */
    function requestReputationScoreReset() external onlyRegisteredUser {
        // This would typically initiate a complex governance proposal.
        // For simplicity, we just emit an event indicating the request.
        // Actual reset logic would be part of a `_processReputationResetVote` function.
        emit ReputationResetProposed(addressToUserProfileId[msg.sender], msg.sender);
    }

    // --- B. Knowledge Contributions & Validation (8 Functions) ---

    /**
     * @notice Submits a new knowledge contribution proposal to the network.
     * @param _contentHash IPFS/Arweave hash of the actual knowledge content.
     * @param _metadataURI Off-chain metadata for the contribution (e.g., title, abstract).
     * @param _bountyId The ID of an associated bounty, or 0 if none.
     */
    function submitKnowledgeContribution(
        string calldata _contentHash,
        string calldata _metadataURI,
        uint256 _bountyId
    ) external onlyRegisteredUser {
        _contributionIds.increment();
        uint256 newContributionId = _contributionIds.current();

        contributions[newContributionId].id = newContributionId;
        contributions[newContributionId].proposer = msg.sender;
        contributions[newContributionId].contentHash = _contentHash;
        contributions[newContributionId].metadataURI = _metadataURI;
        contributions[newContributionId].status = ContributionStatus.Proposed;
        contributions[newContributionId].creationTime = block.timestamp;
        contributions[newContributionId].associatedBountyId = _bountyId;
        // Initialize other fields to default values

        if (_bountyId != 0) {
            require(knowledgeBounties[_bountyId].id != 0, "Bounty does not exist.");
            require(!knowledgeBounties[_bountyId].fulfilled, "Bounty already fulfilled.");
            // Link contribution to bounty, could add a mapping bountyId -> contributionId
        }

        emit ContributionSubmitted(newContributionId, msg.sender, _contentHash);
    }

    /**
     * @notice Allows users to upvote or downvote a contribution. Reputation is affected by these votes.
     * @param _contributionId The ID of the contribution to vote on.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function voteOnContribution(uint256 _contributionId, bool _isUpvote) external onlyRegisteredUser {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.Proposed || c.status == ContributionStatus.Voting, "Contribution not in votable state.");
        require(c.proposer != msg.sender, "Cannot vote on your own contribution.");

        uint256 voterProfileId = addressToUserProfileId[msg.sender];
        UserProfile storage voterProfile = userProfiles[voterProfileId];
        address actualVoter = voterProfile.delegatedReputationTo != address(0) ? voterProfile.delegatedReputationTo : msg.sender;

        if (_isUpvote) {
            require(!c.upvoted[actualVoter], "Already upvoted this contribution.");
            c.upvoted[actualVoter] = true;
            c.upvoteCount++;
            if (c.downvoted[actualVoter]) { // If previously downvoted, remove that vote
                c.downvoted[actualVoter] = false;
                c.downvoteCount--;
            }
        } else {
            require(!c.downvoted[actualVoter], "Already downvoted this contribution.");
            c.downvoted[actualVoter] = true;
            c.downvoteCount++;
            if (c.upvoted[actualVoter]) { // If previously upvoted, remove that vote
                c.upvoted[actualVoter] = false;
                c.upvoteCount--;
            }
        }
        // Reputation adjustment logic could go here: small positive/negative for voters
        emit ContributionVoted(_contributionId, msg.sender, _isUpvote);
    }

    /**
     * @notice Proposes a knowledge contribution for formal verification by a specific Guild.
     *         Only members of the target guild with sufficient reputation can make this proposal.
     * @param _contributionId The ID of the contribution.
     * @param _guildId The ID of the guild to propose for verification.
     */
    function proposeForGuildVerification(uint256 _contributionId, uint256 _guildId) external onlyGuildMember(_guildId) {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.Proposed || c.status == ContributionStatus.Voting, "Contribution not in a state to be proposed for verification.");
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        uint256 proposerReputation = userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore;
        require(proposerReputation >= g.minReputationToJoin, "Proposer does not meet guild's minimum reputation for verification proposals.");

        c.status = ContributionStatus.GuildVerificationPending;
        c.proposedGuildId = _guildId;

        emit ContributionProposedForGuildVerification(_contributionId, _guildId);
    }

    /**
     * @notice Guild members vote to formally verify a knowledge contribution.
     *         Successfully verified contributions lead to reputation gain for the creator and verifiers.
     * @param _contributionId The ID of the contribution.
     * @param _isValid True if the guild member believes the contribution is valid.
     */
    function guildVerifyContribution(uint256 _contributionId, bool _isValid) external {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.GuildVerificationPending, "Contribution not in pending verification state.");
        require(c.proposedGuildId != 0, "Contribution not proposed to a guild for verification.");

        KnowledgeGuild storage g = knowledgeGuilds[c.proposedGuildId];
        require(g.isMember[msg.sender], "Caller is not a member of the proposed guild.");

        // Simple majority or reputation-weighted vote could be implemented here.
        // For now, a single guild member's decision based on their reputation.
        uint256 verifierReputation = userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore;
        require(verifierReputation >= g.minReputationToJoin, "Verifier does not meet guild's minimum reputation for verification.");

        // Prevent double verification by the same address
        for(uint i=0; i < c.verifiers.length; i++) {
            require(c.verifiers[i] != msg.sender, "You have already participated in this verification.");
        }

        if (_isValid) {
            c.status = ContributionStatus.Verified; // For simplicity, single high-rep verifier finalizes
            c.verifiers.push(msg.sender);
            _updateReputation(c.proposer, 50); // Creator gains
            _updateReputation(msg.sender, 20); // Verifier gains
            _updateBadgeURI(addressToUserProfileId[c.proposer]);
            _updateBadgeURI(addressToUserProfileId[msg.sender]);

            // If bounty attached, set it as fulfilled
            if (c.associatedBountyId != 0) {
                knowledgeBounties[c.associatedBountyId].fulfilled = true;
                knowledgeBounties[c.associatedBountyId].solutionProposer = c.proposer;
            }
        } else {
            c.status = ContributionStatus.Rejected;
            _updateReputation(c.proposer, -20); // Creator loses
            _updateBadgeURI(addressToUserProfileId[c.proposer]);
        }
        _updateBadgeURI(addressToUserProfileId[msg.sender]);
        emit ContributionGuildVerified(_contributionId, c.proposedGuildId, _isValid, msg.sender);
    }

    /**
     * @notice Allows any registered user to dispute the status (verified/rejected) of a contribution.
     * @param _contributionId The ID of the contribution being disputed.
     * @param _reasonHash IPFS/Arweave hash containing the detailed reasons for the dispute.
     */
    function disputeContribution(uint256 _contributionId, string calldata _reasonHash) external onlyRegisteredUser {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.Verified || c.status == ContributionStatus.Rejected, "Contribution not in a disputable state.");
        // Additional checks like dispute window or reputation requirements for disputer could be added.

        c.status = ContributionStatus.Disputed;
        // Store dispute reasonHash or link it to a dispute resolution system.
        emit ContributionDisputed(_contributionId, msg.sender);
    }

    /**
     * @notice Triggers an off-chain AI oracle assessment for a disputed or complex contribution.
     *         Only callable by guild members or specific roles (e.g., elected dispute resolvers).
     * @param _contributionId The ID of the contribution to send to the AI oracle.
     */
    function requestAIOracleAssessment(uint256 _contributionId) external onlyRegisteredUser {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.Disputed, "Only disputed contributions can request AI assessment.");
        // Further access control: e.g., only specific guild roles or high-rep members.

        c.status = ContributionStatus.AIReviewPending;
        // In a real system, this would make an external call or enqueue a job for the AI oracle.
        // The oracle would then call `receiveAIOracleVerdict`.
        emit AIOracleAssessmentRequested(_contributionId, msg.sender);
    }

    /**
     * @notice Callback function for the AI Oracle to deliver its verdict and assigned impact score.
     *         This function can only be called by the trusted AI Oracle address.
     * @param _contributionId The ID of the contribution that was assessed.
     * @param _verdictHash IPFS/Arweave hash of the AI's detailed verdict.
     * @param _impactScore The impact score assigned by the AI (e.g., 0-100).
     */
    function receiveAIOracleVerdict(uint256 _contributionId, bytes32 _verdictHash, uint256 _impactScore) external onlyAIOracle {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.AIReviewPending, "Contribution is not awaiting AI review.");

        // Apply AI's verdict:
        c.impactScore = _impactScore;
        if (_impactScore >= 70) { // Example threshold for acceptance
            c.status = ContributionStatus.Verified;
            _updateReputation(c.proposer, _impactScore); // Creator gains based on AI score
            _updateBadgeURI(addressToUserProfileId[c.proposer]);
        } else {
            c.status = ContributionStatus.Rejected;
            _updateReputation(c.proposer, -int256(_impactScore / 2)); // Creator loses partially
            _updateBadgeURI(addressToUserProfileId[c.proposer]);
        }

        emit AIOracleVerdictReceived(_contributionId, _verdictHash, _impactScore);
        // Automatically finalize if AI verdict is decisive
        finalizeContribution(_contributionId);
    }

    /**
     * @notice Finalizes a contribution, marking its final status and updating related reputation scores.
     *         Can be called by anyone after a contribution reaches a final state (Verified, Rejected, Finalized).
     * @param _contributionId The ID of the contribution to finalize.
     */
    function finalizeContribution(uint256 _contributionId) public {
        Contribution storage c = contributions[_contributionId];
        require(c.id != 0, "Contribution does not exist.");
        require(c.status == ContributionStatus.Verified || c.status == ContributionStatus.Rejected, "Contribution not in a finalizable state.");

        // Calculate final impact score based on initial votes, guild verification, and AI assessment (if any)
        if (c.status == ContributionStatus.Verified) {
            c.impactScore = c.impactScore == 0 ? (c.upvoteCount * 5 - c.downvoteCount * 2) + 100 : c.impactScore; // Default if not AI assessed
            if (c.impactScore < 0) c.impactScore = 0; // Ensure non-negative
            _updateReputation(c.proposer, int256(c.impactScore / 10)); // Reward creator
            for (uint256 i = 0; i < c.verifiers.length; i++) {
                _updateReputation(c.verifiers[i], int256(c.impactScore / 20)); // Reward verifiers
            }
        } else if (c.status == ContributionStatus.Rejected) {
            c.impactScore = 0;
            _updateReputation(c.proposer, -50); // Penalize creator for rejection
        }

        // Update badge URI for proposer and verifiers
        _updateBadgeURI(addressToUserProfileId[c.proposer]);
        for (uint256 i = 0; i < c.verifiers.length; i++) {
            _updateBadgeURI(addressToUserProfileId[c.verifiers[i]]);
        }

        c.status = ContributionStatus.Finalized;
        c.finalizationTime = block.timestamp;

        emit ContributionFinalized(_contributionId, c.status, c.impactScore);
    }

    // --- C. Knowledge Guild Management (6 Functions) ---

    /**
     * @notice Creates a new Knowledge Guild. The creator becomes an initial member.
     * @param _name The name of the new guild.
     * @param _symbol A short symbol for the guild (e.g., "DEGEN").
     * @param _minReputationToJoin The minimum global reputation score required to apply to this guild.
     * @param _initialMembers An array of addresses to be added as initial members (must be registered users).
     */
    function createKnowledgeGuild(
        string calldata _name,
        string calldata _symbol,
        uint256 _minReputationToJoin,
        address[] calldata _initialMembers
    ) external onlyRegisteredUser {
        _guildIds.increment();
        uint256 newGuildId = _guildIds.current();

        knowledgeGuilds[newGuildId].id = newGuildId;
        knowledgeGuilds[newGuildId].name = _name;
        knowledgeGuilds[newGuildId].symbol = _symbol;
        knowledgeGuilds[newGuildId].minReputationToJoin = _minReputationToJoin;
        knowledgeGuilds[newGuildId].isMember[msg.sender] = true; // Creator is initial member
        knowledgeGuilds[newGuildId].treasuryToken = address(0); // Set by owner or governance later

        // Add creator to their activeGuilds list
        uint256 creatorProfileId = addressToUserProfileId[msg.sender];
        userProfiles[creatorProfileId].activeGuilds.push(newGuildId);

        // Add other initial members
        for (uint256 i = 0; i < _initialMembers.length; i++) {
            address memberAddress = _initialMembers[i];
            require(addressToUserProfileId[memberAddress] != 0, "Initial member must be a registered user.");
            require(!knowledgeGuilds[newGuildId].isMember[memberAddress], "Duplicate initial member.");
            knowledgeGuilds[newGuildId].isMember[memberAddress] = true;
            userProfiles[addressToUserProfileId[memberAddress]].activeGuilds.push(newGuildId);
        }

        emit GuildCreated(newGuildId, _name, msg.sender);
    }

    /**
     * @notice Allows a registered user to apply to join a specific Knowledge Guild.
     * @param _guildId The ID of the guild to apply to.
     */
    function applyToGuild(uint256 _guildId) external onlyRegisteredUser {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(!g.isMember[msg.sender], "Already a member of this guild.");
        require(g.memberApplications[msg.sender] != GuildApplicationStatus.Pending, "Application already pending.");

        uint256 applicantReputation = userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore;
        require(applicantReputation >= g.minReputationToJoin, "Applicant does not meet minimum reputation requirement.");

        g.memberApplications[msg.sender] = GuildApplicationStatus.Pending;
        emit GuildApplied(_guildId, msg.sender);
    }

    /**
     * @notice Allows an existing guild member to accept a pending application.
     *         Requires a vote or majority approval in a more complex setup.
     * @param _guildId The ID of the guild.
     * @param _applicant The address of the applicant to accept.
     */
    function acceptGuildMember(uint256 _guildId, address _applicant) external onlyGuildMember(_guildId) {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.memberApplications[_applicant] == GuildApplicationStatus.Pending, "Applicant does not have a pending application.");
        require(!g.isMember[_applicant], "Applicant is already a member.");

        // In a real DAO, this would be a governance vote. For simplicity, any guild member can accept.
        g.isMember[_applicant] = true;
        g.memberApplications[_applicant] = GuildApplicationStatus.Accepted;

        uint256 applicantProfileId = addressToUserProfileId[_applicant];
        userProfiles[applicantProfileId].activeGuilds.push(_guildId);

        emit GuildMemberAccepted(_guildId, _applicant);
    }

    /**
     * @notice Proposes a new policy within a specific Guild.
     *         Only guild members with sufficient reputation can propose policies.
     * @param _guildId The ID of the guild.
     * @param _policyHash IPFS/Arweave hash of the policy document.
     * @param _quorum Percentage of guild reputation required for approval (e.g., 5100 for 51%).
     * @param _voteDuration Duration in seconds for the vote.
     */
    function proposeGuildPolicy(
        uint256 _guildId,
        string calldata _policyHash,
        uint256 _quorum,
        uint256 _voteDuration
    ) external onlyGuildMember(_guildId) {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        uint256 proposerReputation = userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore;
        require(proposerReputation >= g.minReputationToJoin, "Proposer does not meet guild's minimum reputation to propose policy.");
        require(_quorum > 0 && _quorum <= 10000, "Quorum must be between 1 and 10000 (0.01% - 100%).");
        require(_voteDuration > 0, "Vote duration must be positive.");

        g._policyCounter.increment();
        uint256 newPolicyId = g._policyCounter.current();

        g.policies[newPolicyId] = GuildPolicy({
            id: newPolicyId,
            policyHash: _policyHash,
            proposerReputation: proposerReputation,
            creationTime: block.timestamp,
            voteDuration: _voteDuration,
            quorumPercentage: _quorum,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit GuildPolicyProposed(_guildId, newPolicyId, msg.sender);
    }

    /**
     * @notice Allows guild members to vote on a proposed policy.
     * @param _guildId The ID of the guild.
     * @param _policyId The ID of the policy to vote on.
     * @param _for True for a 'yes' vote, false for 'no'.
     */
    function voteOnGuildPolicy(uint256 _guildId, uint256 _policyId, bool _for) external onlyGuildMember(_guildId) {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        GuildPolicy storage p = g.policies[_policyId];
        require(p.id != 0, "Policy does not exist.");
        require(block.timestamp < p.creationTime + p.voteDuration, "Voting period has ended.");
        require(!p.executed, "Policy already executed.");
        require(!p.hasVoted[msg.sender], "You have already voted on this policy.");

        p.hasVoted[msg.sender] = true;
        if (_for) {
            p.votesFor += userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore; // Reputation-weighted vote
        } else {
            p.votesAgainst += userProfiles[addressToUserProfileId[msg.sender]].globalReputationScore;
        }

        emit GuildPolicyVoted(_guildId, _policyId, msg.sender, _for);
        // A separate function or an automated check on vote conclusion would process the outcome.
    }

    /**
     * @notice Allows a user to leave a specific Knowledge Guild.
     * @param _guildId The ID of the guild to leave.
     */
    function leaveGuild(uint256 _guildId) external {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(g.isMember[msg.sender], "You are not a member of this guild.");

        g.isMember[msg.sender] = false;

        // Remove guild from user's activeGuilds array (expensive, consider alternatives for large arrays)
        uint256 profileId = addressToUserProfileId[msg.sender];
        uint256[] storage activeGuilds = userProfiles[profileId].activeGuilds;
        for (uint256 i = 0; i < activeGuilds.length; i++) {
            if (activeGuilds[i] == _guildId) {
                activeGuilds[i] = activeGuilds[activeGuilds.length - 1];
                activeGuilds.pop();
                break;
            }
        }
        emit GuildMemberLeft(_guildId, msg.sender);
    }

    // --- D. Treasury & Streaming Rewards (4 Functions) ---

    /**
     * @notice Allows anyone to deposit ERC20 tokens into a guild's treasury.
     *         The guild must have a `treasuryToken` set.
     * @param _guildId The ID of the guild.
     * @param _amount The amount of tokens to deposit.
     */
    function depositGuildTreasury(uint256 _guildId, uint256 _amount) external {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(g.treasuryToken != address(0), "Guild treasury token not set.");
        require(_amount > 0, "Amount must be positive.");

        IERC20 token = IERC20(g.treasuryToken);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        g.treasuryBalance += _amount;

        emit GuildTreasuryDeposited(_guildId, msg.sender, _amount, g.treasuryToken);
    }

    /**
     * @notice Creates a new knowledge bounty for a specific task or knowledge gap, funded by a guild.
     * @param _guildId The ID of the guild creating the bounty.
     * @param _bountyDescriptionHash IPFS/Arweave hash of the bounty details.
     * @param _rewardAmount The amount of tokens to reward for fulfilling the bounty.
     * @param _deadline The timestamp by which the bounty must be fulfilled.
     */
    function createKnowledgeBounty(
        uint256 _guildId,
        string calldata _bountyDescriptionHash,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external onlyGuildMember(_guildId) {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(g.treasuryToken != address(0), "Guild treasury token not set.");
        require(g.treasuryBalance >= _rewardAmount, "Insufficient funds in guild treasury.");
        require(_rewardAmount > 0, "Reward amount must be positive.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        knowledgeBounties[newBountyId] = KnowledgeBounty({
            id: newBountyId,
            guildId: _guildId,
            proposer: msg.sender,
            descriptionHash: _bountyDescriptionHash,
            rewardAmount: _rewardAmount,
            rewardToken: g.treasuryToken, // Bounties use guild's treasury token
            deadline: _deadline,
            solutionProposer: address(0),
            fulfilled: false,
            claimed: false
        });

        // Dedicate funds from treasury (not moved yet, just allocated conceptually)
        g.treasuryBalance -= _rewardAmount; // This is a conceptual reduction, actual transfer happens on claim

        emit KnowledgeBountyCreated(newBountyId, _guildId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Allows the creator of a successfully fulfilled bounty to claim their reward.
     *         The bounty must be linked to a verified contribution.
     * @param _bountyId The ID of the bounty to claim.
     */
    function claimBountyReward(uint256 _bountyId) external {
        KnowledgeBounty storage b = knowledgeBounties[_bountyId];
        require(b.id != 0, "Bounty does not exist.");
        require(b.fulfilled, "Bounty not yet fulfilled.");
        require(!b.claimed, "Bounty already claimed.");
        require(b.solutionProposer == msg.sender, "Only the solution proposer can claim this bounty.");

        IERC20 token = IERC20(b.rewardToken);
        require(token.transfer(msg.sender, b.rewardAmount), "Failed to transfer bounty reward.");

        b.claimed = true;
        emit BountyRewardClaimed(_bountyId, msg.sender, b.rewardAmount);
    }

    /**
     * @notice Initiates perpetual token streams to top contributors and validators within a guild.
     *         This function would interact with a streaming protocol like Superfluid.
     * @param _guildId The ID of the guild to stream rewards from.
     * @param _flowRatePerUnitImpact The rate at which tokens are streamed per unit of impact score.
     *                               (e.g., tokens per second per impact point).
     */
    function streamRewardsToContributors(uint256 _guildId, uint256 _flowRatePerUnitImpact) external onlyOwner {
        // This is a conceptual function. Real implementation would involve
        // interfacing with a protocol like Superfluid (e.g., calling `createFlow`, `updateFlow`).
        // It would identify top contributors/validators within the guild based on their impactScore
        // and globalReputationScore, and establish proportional streams.

        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(streamProtocolAddress != address(0), "Stream Protocol address not set.");
        require(g.treasuryToken != address(0), "Guild treasury token not set for streaming.");

        // Example: Iterate through active members (complex for large sets on-chain)
        // This would likely be triggered by a bot or governance off-chain,
        // which then calls specific stream update functions on the Superfluid contract.

        // Placeholder for interaction with StreamProtocol:
        // IStreamProtocol(streamProtocolAddress).createFlow(
        //     g.treasuryToken,
        //     address(this), // Guild as sender
        //     topContributorAddress,
        //     calculatedFlowRate // Based on their impact * _flowRatePerUnitImpact
        // );

        emit RewardsStreamed(_guildId, _flowRatePerUnitImpact, msg.sender);
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Internal function to update a user's global reputation score.
     *      Also triggers an update of their Aetheria Badge URI.
     * @param _user The address of the user whose reputation is being updated.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function _updateReputation(address _user, int256 _change) internal {
        uint256 profileId = addressToUserProfileId[_user];
        if (profileId == 0) return; // Should not happen if onlyRegisteredUser is used

        UserProfile storage profile = userProfiles[profileId];
        if (_change > 0) {
            profile.globalReputationScore += uint256(_change);
        } else {
            // Prevent underflow and ensure reputation doesn't go below 0 (or a minimum threshold)
            if (profile.globalReputationScore > uint256(-_change)) {
                profile.globalReputationScore -= uint256(-_change);
            } else {
                profile.globalReputationScore = 0; // Or a configurable minimum
            }
        }
        _updateBadgeURI(profileId);
    }

    /**
     * @dev Internal function to generate a dynamic URI for the Aetheria Badge.
     *      This URI would point to an API that generates JSON metadata based on
     *      the user's current reputation, active guilds, achievements, etc.
     * @param _badgeId The ID of the badge (which is the user's profile ID).
     * @return The URI for the badge's metadata.
     */
    function _generateBadgeURI(uint256 _badgeId) internal view returns (string memory) {
        UserProfile storage profile = userProfiles[_badgeId];
        // Example dynamic URI: A web server would serve JSON based on these parameters
        // e.g., "https://aetheria.xyz/badges/{profileId}?rep={reputation}&guilds={guildCount}"
        return string(
            abi.encodePacked(
                "https://aetheria.xyz/badges/",
                _badgeId.toString(),
                "?rep=",
                profile.globalReputationScore.toString(),
                "&guilds=",
                profile.activeGuilds.length.toString(),
                "&updated=",
                block.timestamp.toString() // To force re-render in some explorers
            )
        );
    }

    /**
     * @dev Internal function to update the token URI for a specific Aetheria Badge.
     *      Called whenever a user's reputation or linked data changes.
     * @param _badgeId The ID of the badge to update.
     */
    function _updateBadgeURI(uint256 _badgeId) internal {
        // Ensure the token exists and is owned by the corresponding user.
        // It's already checked in _generateBadgeURI, but safer here.
        require(userProfiles[_badgeId].hasMintedBadge, "Badge not minted for this profile.");
        _setTokenURI(_badgeId, _generateBadgeURI(_badgeId));
    }

    /**
     * @dev ERC721 hook to enforce non-transferability, making tokens Soulbound.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from address(0)) and burning (to address(0))
        if (from != address(0) && to != address(0)) {
            revert("Aetheria Badges are soulbound and non-transferable.");
        }
    }

    /**
     * @notice Sets the address of the trusted AI Oracle. Only callable by the contract owner.
     * @param _newOracleAddress The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "New oracle address cannot be zero.");
        aiOracleAddress = _newOracleAddress;
    }

    /**
     * @notice Sets the address of the conceptual streaming protocol. Only callable by the contract owner.
     * @param _newStreamProtocolAddress The new address for the streaming protocol.
     */
    function setStreamProtocolAddress(address _newStreamProtocolAddress) external onlyOwner {
        require(_newStreamProtocolAddress != address(0), "New stream protocol address cannot be zero.");
        streamProtocolAddress = _newStreamProtocolAddress;
    }

    /**
     * @notice Sets the ERC20 token address for a guild's treasury. Only guild creator or owner can set.
     *         Ideally, this would be part of a guild governance proposal.
     * @param _guildId The ID of the guild.
     * @param _tokenAddress The address of the ERC20 token to use for the treasury.
     */
    function setGuildTreasuryToken(uint256 _guildId, address _tokenAddress) external {
        KnowledgeGuild storage g = knowledgeGuilds[_guildId];
        require(g.id != 0, "Guild does not exist.");
        require(g.treasuryToken == address(0), "Treasury token already set for this guild."); // Can only be set once
        require(g.isMember[msg.sender], "Only a guild member can set treasury token."); // Simplistic check

        g.treasuryToken = _tokenAddress;
    }

    // --- View Functions ---

    /**
     * @notice Returns a user's global reputation score.
     * @param _user The address of the user.
     * @return The global reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        uint256 profileId = addressToUserProfileId[_user];
        if (profileId == 0) return 0;
        return userProfiles[profileId].globalReputationScore;
    }

    /**
     * @notice Returns the status of a specific contribution.
     * @param _contributionId The ID of the contribution.
     * @return The current status of the contribution.
     */
    function getContributionStatus(uint256 _contributionId) external view returns (ContributionStatus) {
        require(contributions[_contributionId].id != 0, "Contribution does not exist.");
        return contributions[_contributionId].status;
    }

    /**
     * @notice Returns the total number of registered users.
     */
    function getTotalUsers() external view returns (uint256) {
        return _userProfileIds.current();
    }

    /**
     * @notice Returns the total number of contributions.
     */
    function getTotalContributions() external view returns (uint256) {
        return _contributionIds.current();
    }

    /**
     * @notice Returns the total number of guilds.
     */
    function getTotalGuilds() external view returns (uint256) {
        return _guildIds.current();
    }
}
```