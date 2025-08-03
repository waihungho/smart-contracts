Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical DeFi or NFT patterns, focusing on dynamic systems, collective intelligence, and a touch of the futuristic.

I present **QuantumLeap: The Collective Foresight Protocol**.

**Concept:**
QuantumLeap is a decentralized platform where users collaboratively curate knowledge and predict future outcomes. It combines elements of prediction markets, dynamic NFTs, a reputation system, and a simulated "Oracle AI" to foster collective intelligence. Users stake tokens on "Temporal Streams" (topics/events) and "Propositions" (statements about the future or verifiable facts). Their "Nexus NFT" evolves based on their accuracy, contributions, and earned "Synaptic Links" (reputation).

---

## QuantumLeap: The Collective Foresight Protocol

### Outline:

1.  **Introduction & Core Concept:** Decentralized collective intelligence platform for knowledge curation and future prediction.
2.  **Tokenomics:**
    *   **QLP (Quantum Leap Points - ERC-20):** Utility token for staking, rewards, and participation.
    *   **Nexus NFT (ERC-721):** Dynamic NFT representing a user's commitment, reputation, and foresight within the protocol. Its visual "level" evolves.
3.  **Key Modules:**
    *   **Temporal Streams:** Categorized topics or events where predictions/facts are submitted.
    *   **Propositions:** Verifiable statements about a Temporal Stream. Users stake QLP on their belief in a proposition's truth.
    *   **Curation & Consensus:** Users "curate" propositions by staking QLP, signaling their agreement or disagreement.
    *   **Oracle AI (Simulated):** A mechanism (initially admin-driven, later potentially DAO-governed or Chainlink-integrated for real external data) that provides "guidance" or resolves ambiguous propositions.
    *   **Synaptic Links (Reputation):** Non-transferable points earned for accurate predictions, successful curation, and overall contribution. Powers NFT evolution.
    *   **Dynamic Nexus NFTs:** NFTs that visually upgrade/evolve based on a user's Synaptic Links.
    *   **Dispute Resolution:** Mechanism to challenge proposition resolutions.
    *   **Epoch Management:** Time-based system for progressing the protocol state, resolving propositions, and distributing rewards.

---

### Function Summary (20+ Functions):

1.  `constructor()`: Initializes the contract, deploys ERC-20 and ERC-721, sets up admin.
2.  `createTemporalStream(string calldata _name, string calldata _description, uint256 _resolutionEpochDelta)`: Initiates a new topic/event stream for propositions. Requires a small QLP stake.
3.  `submitProposition(uint256 _streamId, string calldata _statement, uint256 _stakeAmount)`: Users submit a verifiable statement to a stream, staking QLP.
4.  `curateProposition(uint256 _propositionId, bool _support, uint256 _stakeAmount)`: Users stake QLP to either `_support` or `_dispute` a proposition.
5.  `resolveProposition(uint256 _propositionId, PropositionStatus _finalStatus)`: Admin/Oracle AI marks a proposition as true, false, or disputed. Triggers reward/penalty calculations.
6.  `initiateDispute(uint256 _propositionId)`: Allows users to challenge the `resolveProposition` outcome, requiring a larger QLP stake.
7.  `voteOnDispute(uint256 _disputeId, bool _voteForOriginalResolution)`: Community votes on a dispute, determining the final status.
8.  `claimRewards(uint256[] calldata _propositionIds)`: Allows users to claim QLP rewards and Synaptic Links from successfully resolved propositions and curation.
9.  `mintNexusNFT()`: Mints a unique Nexus NFT for a new participant. Only one per address.
10. `upgradeNexusNFT(uint256 _tokenId)`: Triggers the internal logic to potentially upgrade the visual level of a Nexus NFT based on Synaptic Links.
11. `getNexusNFTLevel(uint256 _tokenId) public view returns (uint8)`: Returns the current visual level of a Nexus NFT.
12. `getSynapticLinks(address _user) public view returns (uint256)`: Returns the total Synaptic Links for a user.
13. `setOracleAIGuidance(uint256 _propositionId, bool _guidanceValue)`: Admin/DAO sets the "guidance" for a proposition, simulating Oracle AI input. This can influence resolution.
14. `requestOracleAIGuidance(uint256 _propositionId)`: (Simulated) User can request "AI guidance" on a proposition, potentially consuming QLP.
15. `advanceEpoch()`: Admin/Time-based function to move to the next epoch, triggering resolution of eligible propositions and dispute periods.
16. `getStreamDetails(uint256 _streamId) public view returns (Stream memory)`: Retrieves details about a specific Temporal Stream.
17. `getPropositionDetails(uint256 _propositionId) public view returns (Proposition memory)`: Retrieves details about a specific proposition.
18. `getUserPropositionStake(address _user, uint256 _propositionId) public view returns (uint256 supported, uint256 disputed)`: Returns user's staked QLP for a proposition (supported/disputed).
19. `getTopCurators(uint256 _limit) public view returns (address[] memory, uint256[] memory)`: Returns a list of addresses and their Synaptic Links, ordered by reputation.
20. `getTotalStakedQLP() public view returns (uint256)`: Returns the total amount of QLP currently staked across all propositions and streams.
21. `withdrawContractFunds(address _tokenAddress, uint256 _amount)`: Admin function to withdraw accidental token transfers or protocol fees.
22. `pauseProtocol()`: Admin function to pause all core interactions in case of emergency.
23. `unpauseProtocol()`: Admin function to unpause the protocol.
24. `setMinimumStake(uint256 _newStake)`: Admin function to adjust minimum QLP required for actions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Errors for better debugging ---
error QuantumLeap__InvalidStreamId();
error QuantumLeap__InvalidPropositionId();
error QuantumLeap__AlreadyHasNexusNFT();
error QuantumLeap__NoNexusNFT();
error QuantumLeap__InsufficientStake();
error QuantumLeap__PropositionNotResolvableYet();
error QuantumLeap__PropositionAlreadyResolved();
error QuantumLeap__PropositionAlreadyDisputed();
error QuantumLeap__NotADisputeParticipant();
error QuantumLeap__DisputeAlreadyVoted();
error QuantumLeap__DisputeVotingPeriodEnded();
error QuantumLeap__DisputeNotInitiated();
error QuantumLeap__UnauthorizedResolution();
error QuantumLeap__NoRewardsToClaim();
error QuantumLeap__InvalidStatus();
error QuantumLeap__StreamAlreadyActive();
error QuantumLeap__StreamAlreadyInactive();
error QuantumLeap__MinimumStakeNotMet();
error QuantumLeap__InvalidEpochTransition();

contract QuantumLeap is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---
    ERC20 public immutable qlpToken;
    NexusNFT public immutable nexusNFT;

    Counters.Counter private _streamIds;
    Counters.Counter private _propositionIds;
    Counters.Counter private _disputeIds;

    // --- Configuration Constants (can be made configurable by admin/DAO) ---
    uint256 public MIN_STREAM_STAKE = 100 * (10 ** 18); // Example: 100 QLP
    uint256 public MIN_PROPOSITION_STAKE = 10 * (10 ** 18); // Example: 10 QLP
    uint256 public MIN_CURATION_STAKE = 5 * (10 ** 18); // Example: 5 QLP
    uint256 public DISPUTE_INITIATION_STAKE_MULTIPLIER = 5; // Dispute stake is 5x MIN_PROPOSITION_STAKE
    uint256 public DISPUTE_VOTING_PERIOD_EPOCHS = 3; // How many epochs a dispute vote lasts
    uint256 public ORACLE_AI_INFLUENCE_FACTOR = 1000; // Multiplier for Oracle AI guidance (e.g., 1000 = 100% influence)
    uint256 public SYNAPTIC_LINKS_PER_QLP_REWARDED = 1; // 1 Synaptic Link per QLP reward
    uint256 public BASE_NFT_UPGRADE_THRESHOLD = 1000; // Initial Synaptic Links needed for NFT Level 2
    uint256 public NFT_UPGRADE_SCALING_FACTOR = 2; // Each subsequent level needs 2x previous threshold

    uint256 public currentEpoch;
    uint256 public epochDuration = 1 days; // Example: Each epoch is 1 day

    // --- Enums ---
    enum PropositionStatus {
        Pending,
        True,
        False,
        Disputed,
        ResolvedTrue, // After dispute
        ResolvedFalse // After dispute
    }

    // --- Structs ---
    struct Stream {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256 creationEpoch;
        uint256 resolutionEpochDelta; // Epochs from creation until propositions can be resolved
        bool isActive;
        mapping(uint256 => bool) propositions; // Tracks propositions belonging to this stream
        uint256 propositionCount;
    }

    struct Proposition {
        uint256 id;
        uint256 streamId;
        address creator;
        string statement;
        uint256 creationEpoch;
        uint256 resolutionEpoch; // Expected epoch when it can be resolved
        PropositionStatus status;
        uint256 stakedForSupport;
        uint256 stakedForDispute;
        mapping(address => uint256) userSupportStakes; // User's stake for support
        mapping(address => uint256) userDisputeStakes; // User's stake for dispute
        bool oracleAIGuidance; // Simulated AI guidance: true = 'Yes', false = 'No'
        bool oracleAIGuidanceSet; // Has AI guidance been set for this prop?
        uint256 rewardPool; // QLP accumulated for this proposition's rewards
        uint256 totalPayouts; // Track total QLP paid out to avoid over-payouts
        uint256 disputeId; // 0 if no active dispute
    }

    struct Dispute {
        uint256 id;
        uint256 propositionId;
        address initiator;
        uint256 initiationEpoch;
        uint256 votingEndEpoch;
        uint256 stake; // QLP staked by initiator
        uint256 votesForOriginalResolution;
        uint256 votesAgainstOriginalResolution;
        mapping(address => bool) hasVoted; // True if address has voted in this dispute
        bool resolved;
    }

    // --- Mappings ---
    mapping(uint256 => Stream) public streams;
    mapping(uint256 => Proposition) public propositions;
    mapping(uint256 => Dispute) public disputes;

    mapping(address => uint256) public userSynapticLinks; // User's reputation points
    mapping(address => uint256) public userNexusNFTTokenId; // Stores tokenId of user's Nexus NFT (0 if none)

    // --- Events ---
    event TemporalStreamCreated(uint256 indexed streamId, string name, address indexed creator, uint256 creationEpoch);
    event PropositionSubmitted(uint256 indexed propositionId, uint256 indexed streamId, address indexed creator, string statement, uint256 stakeAmount);
    event PropositionCurated(uint256 indexed propositionId, address indexed curator, bool support, uint256 stakeAmount);
    event PropositionResolved(uint256 indexed propositionId, PropositionStatus newStatus, uint256 resolutionEpoch);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed propositionId, address indexed initiator, uint256 stake);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool voteForOriginalResolution);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed propositionId, PropositionStatus finalStatus);
    event RewardsClaimed(address indexed user, uint256 QLPRewarded, uint256 synapticLinksEarned);
    event NexusNFTMinted(uint256 indexed tokenId, address indexed owner);
    event NexusNFTUpgraded(uint256 indexed tokenId, uint8 newLevel, uint256 synapticLinksRequired);
    event OracleAIGuidanceSet(uint256 indexed propositionId, bool guidanceValue);
    event EpochAdvanced(uint256 newEpoch);
    event MinimumStakeUpdated(uint256 newMinimumStake);

    // --- Constructor ---
    constructor(address _qlpTokenAddress, address _nexusNFTAddress) Ownable(msg.sender) {
        qlpToken = ERC20(_qlpTokenAddress);
        nexusNFT = NexusNFT(_nexusNFTAddress);
        currentEpoch = 1; // Start from Epoch 1
    }

    // --- Modifiers ---
    modifier onlyNexusNFTHolder(address _user) {
        if (userNexusNFTTokenId[_user] == 0) revert QuantumLeap__NoNexusNFT();
        _;
    }

    // --- 1. createTemporalStream ---
    function createTemporalStream(
        string calldata _name,
        string calldata _description,
        uint256 _resolutionEpochDelta // How many epochs from creation until propositions in this stream can be resolved
    ) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        if (qlpToken.balanceOf(msg.sender) < MIN_STREAM_STAKE) revert QuantumLeap__InsufficientStake();
        qlpToken.transferFrom(msg.sender, address(this), MIN_STREAM_STAKE);

        uint256 newStreamId = _streamIds.current();
        _streamIds.increment();

        Stream storage newStream = streams[newStreamId];
        newStream.id = newStreamId;
        newStream.name = _name;
        newStream.description = _description;
        newStream.creator = msg.sender;
        newStream.creationEpoch = currentEpoch;
        newStream.resolutionEpochDelta = _resolutionEpochDelta;
        newStream.isActive = true; // Stream is active upon creation
        newStream.propositionCount = 0;

        emit TemporalStreamCreated(newStreamId, _name, msg.sender, currentEpoch);
    }

    // --- 2. submitProposition ---
    function submitProposition(
        uint256 _streamId,
        string calldata _statement,
        uint256 _stakeAmount
    ) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        if (_stakeAmount < MIN_PROPOSITION_STAKE) revert QuantumLeap__MinimumStakeNotMet();
        if (streams[_streamId].id == 0) revert QuantumLeap__InvalidStreamId();
        if (!streams[_streamId].isActive) revert QuantumLeap__StreamAlreadyInactive();

        qlpToken.transferFrom(msg.sender, address(this), _stakeAmount);

        uint256 newPropositionId = _propositionIds.current();
        _propositionIds.increment();

        Proposition storage newProposition = propositions[newPropositionId];
        newProposition.id = newPropositionId;
        newProposition.streamId = _streamId;
        newProposition.creator = msg.sender;
        newProposition.statement = _statement;
        newProposition.creationEpoch = currentEpoch;
        // Proposition can be resolved after stream's delta + a buffer (e.g., 1 epoch)
        newProposition.resolutionEpoch = currentEpoch.add(streams[_streamId].resolutionEpochDelta).add(1);
        newProposition.status = PropositionStatus.Pending;
        newProposition.stakedForSupport = _stakeAmount;
        newProposition.userSupportStakes[msg.sender] = _stakeAmount;
        newProposition.rewardPool = _stakeAmount; // Creator's stake goes into the reward pool
        newProposition.oracleAIGuidanceSet = false; // No guidance yet

        streams[_streamId].propositions[newPropositionId] = true;
        streams[_streamId].propositionCount = streams[_streamId].propositionCount.add(1);

        emit PropositionSubmitted(newPropositionId, _streamId, msg.sender, _statement, _stakeAmount);
    }

    // --- 3. curateProposition ---
    function curateProposition(
        uint256 _propositionId,
        bool _support, // true to support, false to dispute
        uint256 _stakeAmount
    ) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        if (_stakeAmount < MIN_CURATION_STAKE) revert QuantumLeap__MinimumStakeNotMet();
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        if (prop.status != PropositionStatus.Pending) revert QuantumLeap__PropositionAlreadyResolved();
        if (currentEpoch >= prop.resolutionEpoch) revert QuantumLeap__PropositionNotResolvableYet(); // Cannot curate once past resolution epoch

        qlpToken.transferFrom(msg.sender, address(this), _stakeAmount);

        if (_support) {
            prop.userSupportStakes[msg.sender] = prop.userSupportStakes[msg.sender].add(_stakeAmount);
            prop.stakedForSupport = prop.stakedForSupport.add(_stakeAmount);
        } else {
            prop.userDisputeStakes[msg.sender] = prop.userDisputeStakes[msg.sender].add(_stakeAmount);
            prop.stakedForDispute = prop.stakedForDispute.add(_stakeAmount);
        }
        prop.rewardPool = prop.rewardPool.add(_stakeAmount); // All stakes add to the reward pool

        emit PropositionCurated(_propositionId, msg.sender, _support, _stakeAmount);
    }

    // --- 4. resolveProposition (Admin/Oracle Role) ---
    // In a fully decentralized system, this would be a DAO vote or a Chainlink oracle
    // For this contract, it simulates the "final decision" by a privileged entity.
    function resolveProposition(
        uint256 _propositionId,
        PropositionStatus _finalStatus // Must be True or False
    ) external onlyOwner whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        if (prop.status != PropositionStatus.Pending) revert QuantumLeap__PropositionAlreadyResolved();
        if (currentEpoch < prop.resolutionEpoch) revert QuantumLeap__PropositionNotResolvableYet();
        if (_finalStatus != PropositionStatus.True && _finalStatus != PropositionStatus.False) revert QuantumLeap__InvalidStatus();

        prop.status = _finalStatus;
        _distributePropositionRewards(_propositionId);

        emit PropositionResolved(_propositionId, _finalStatus, currentEpoch);
    }

    // --- 5. initiateDispute ---
    function initiateDispute(uint256 _propositionId) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        if (prop.status != PropositionStatus.True && prop.status != PropositionStatus.False) revert QuantumLeleap__PropositionNotResolvableYet(); // Can only dispute if already resolved
        if (prop.disputeId != 0) revert QuantumLeap__PropositionAlreadyDisputed(); // Already under dispute

        uint256 disputeStake = MIN_PROPOSITION_STAKE.mul(DISPUTE_INITIATION_STAKE_MULTIPLIER);
        if (qlpToken.balanceOf(msg.sender) < disputeStake) revert QuantumLeap__InsufficientStake();
        qlpToken.transferFrom(msg.sender, address(this), disputeStake);

        uint256 newDisputeId = _disputeIds.current();
        _disputeIds.increment();

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.id = newDisputeId;
        newDispute.propositionId = _propositionId;
        newDispute.initiator = msg.sender;
        newDispute.initiationEpoch = currentEpoch;
        newDispute.votingEndEpoch = currentEpoch.add(DISPUTE_VOTING_PERIOD_EPOCHS);
        newDispute.stake = disputeStake;
        newDispute.resolved = false;

        prop.status = PropositionStatus.Disputed; // Change proposition status to Disputed
        prop.disputeId = newDisputeId;

        emit DisputeInitiated(newDisputeId, _propositionId, msg.sender, disputeStake);
    }

    // --- 6. voteOnDispute ---
    function voteOnDispute(uint256 _disputeId, bool _voteForOriginalResolution) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert QuantumLeap__DisputeNotInitiated();
        if (dispute.resolved) revert QuantumLeap__DisputeAlreadyVoted();
        if (dispute.hasVoted[msg.sender]) revert QuantumLeap__DisputeAlreadyVoted();
        if (currentEpoch > dispute.votingEndEpoch) revert QuantumLeap__DisputeVotingPeriodEnded();

        dispute.hasVoted[msg.sender] = true;
        if (_voteForOriginalResolution) {
            dispute.votesForOriginalResolution = dispute.votesForOriginalResolution.add(1);
        } else {
            dispute.votesAgainstOriginalResolution = dispute.votesAgainstOriginalResolution.add(1);
        }

        emit DisputeVoted(_disputeId, msg.sender, _voteForOriginalResolution);
    }

    // Internal function to resolve a dispute after its voting period ends
    function _resolveDispute(uint256 _disputeId) internal {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.resolved) return; // Already resolved
        if (currentEpoch <= dispute.votingEndEpoch) return; // Voting period not over

        Proposition storage prop = propositions[dispute.propositionId];

        PropositionStatus finalStatus;
        if (dispute.votesForOriginalResolution > dispute.votesAgainstOriginalResolution) {
            finalStatus = (prop.status == PropositionStatus.Disputed && prop.stakedForSupport > prop.stakedForDispute) ? PropositionStatus.ResolvedTrue : PropositionStatus.ResolvedFalse; // Assume original was majority
            qlpToken.transfer(dispute.initiator, dispute.stake.div(2)); // Initiator loses half stake if they lose
        } else if (dispute.votesAgainstOriginalResolution > dispute.votesForOriginalResolution) {
            finalStatus = (prop.status == PropositionStatus.Disputed && prop.stakedForSupport <= prop.stakedForDispute) ? PropositionStatus.ResolvedTrue : PropositionStatus.ResolvedFalse; // Assume original was minority
            qlpToken.transfer(dispute.initiator, dispute.stake.mul(2)); // Initiator gets 2x stake back if they win (from protocol funds)
        } else { // Tie
            finalStatus = prop.status; // Revert to original status
            qlpToken.transfer(dispute.initiator, dispute.stake); // Initiator gets stake back on tie
        }

        prop.status = finalStatus;
        dispute.resolved = true;
        prop.disputeId = 0; // Clear dispute ID

        _distributePropositionRewards(dispute.propositionId); // Re-distribute rewards based on final status

        emit DisputeResolved(_disputeId, dispute.propositionId, finalStatus);
    }

    // --- 7. claimRewards ---
    function claimRewards(uint256[] calldata _propositionIds) external whenNotPaused onlyNexusNFTHolder(msg.sender) {
        uint256 totalQLPRewarded = 0;
        uint256 totalSynapticLinks = 0;

        for (uint256 i = 0; i < _propositionIds.length; i++) {
            uint256 propositionId = _propositionIds[i];
            Proposition storage prop = propositions[propositionId];

            if (prop.id == 0 || (prop.status != PropositionStatus.True && prop.status != PropositionStatus.False &&
                                 prop.status != PropositionStatus.ResolvedTrue && prop.status != PropositionStatus.ResolvedFalse) ||
                                 prop.totalPayouts == prop.rewardPool) {
                continue; // Skip invalid or unresolved/already paid out propositions
            }

            uint256 userReward = 0;
            if (prop.status == PropositionStatus.True || prop.status == PropositionStatus.ResolvedTrue) {
                // Rewarding for correct support
                uint256 userSupportStake = prop.userSupportStakes[msg.sender];
                if (userSupportStake > 0 && prop.stakedForSupport > 0) {
                    userReward = prop.rewardPool.mul(userSupportStake).div(prop.stakedForSupport);
                    prop.userSupportStakes[msg.sender] = 0; // Mark as claimed
                }
            } else if (prop.status == PropositionStatus.False || prop.status == PropositionStatus.ResolvedFalse) {
                // Rewarding for correct dispute
                uint256 userDisputeStake = prop.userDisputeStakes[msg.sender];
                if (userDisputeStake > 0 && prop.stakedForDispute > 0) {
                    userReward = prop.rewardPool.mul(userDisputeStake).div(prop.stakedForDispute);
                    prop.userDisputeStakes[msg.sender] = 0; // Mark as claimed
                }
            }
            
            if (userReward > 0) {
                prop.totalPayouts = prop.totalPayouts.add(userReward);
                totalQLPRewarded = totalQLPRewarded.add(userReward);
                totalSynapticLinks = totalSynapticLinks.add(userReward.mul(SYNAPTIC_LINKS_PER_QLP_REWARDED));
            }
        }

        if (totalQLPRewarded == 0) revert QuantumLeap__NoRewardsToClaim();

        qlpToken.transfer(msg.sender, totalQLPRewarded);
        userSynapticLinks[msg.sender] = userSynapticLinks[msg.sender].add(totalSynapticLinks);

        emit RewardsClaimed(msg.sender, totalQLPRewarded, totalSynapticLinks);
    }

    // Internal function to distribute rewards for a single proposition
    function _distributePropositionRewards(uint256 _propositionId) internal {
        Proposition storage prop = propositions[_propositionId];
        if (prop.totalPayouts > 0) return; // Rewards already processed for this proposition

        if (prop.status == PropositionStatus.True || prop.status == PropositionStatus.ResolvedTrue) {
            // Rewards go to those who supported
            // No direct transfer here, just update total payouts. Users call claimRewards.
            prop.totalPayouts = prop.rewardPool; // Mark all as available for correct supporters
        } else if (prop.status == PropositionStatus.False || prop.status == PropositionStatus.ResolvedFalse) {
            // Rewards go to those who disputed
            // No direct transfer here, just update total payouts. Users call claimRewards.
            prop.totalPayouts = prop.rewardPool; // Mark all as available for correct disputers
        } else {
            // If it's a tie or otherwise unresolved, return stakes to everyone
            prop.totalPayouts = prop.rewardPool; // Mark all as available for anyone who staked
        }
    }

    // --- 8. mintNexusNFT ---
    function mintNexusNFT() external whenNotPaused {
        if (userNexusNFTTokenId[msg.sender] != 0) revert QuantumLeap__AlreadyHasNexusNFT();

        uint256 newTokenId = nexusNFT.mint(msg.sender);
        userNexusNFTTokenId[msg.sender] = newTokenId;

        emit NexusNFTMinted(newTokenId, msg.sender);
    }

    // --- 9. upgradeNexusNFT ---
    function upgradeNexusNFT(uint256 _tokenId) external whenNotPaused {
        if (nexusNFT.ownerOf(_tokenId) != msg.sender) revert QuantumLeap__NoNexusNFT(); // Ensure caller owns the NFT

        uint8 currentLevel = nexusNFT.getNFTLevel(_tokenId);
        uint256 requiredSynapticLinks = _calculateRequiredSynapticLinks(currentLevel.add(1));

        if (userSynapticLinks[msg.sender] < requiredSynapticLinks) revert QuantumLeap__NoRewardsToClaim(); // Not enough Synaptic Links

        // Burn the old NFT and mint a new one with the updated level data
        nexusNFT.burn(_tokenId);
        uint256 newLevel = currentLevel.add(1);
        uint256 newNFTId = nexusNFT.mintWithLevel(msg.sender, newLevel);
        userNexusNFTTokenId[msg.sender] = newNFTId; // Update stored token ID

        emit NexusNFTUpgraded(newNFTId, uint8(newLevel), requiredSynapticLinks);
    }

    // Internal helper to calculate required Synaptic Links for next NFT level
    function _calculateRequiredSynapticLinks(uint8 _level) internal view returns (uint256) {
        if (_level <= 1) return 0; // Level 1 is initial
        uint256 required = BASE_NFT_UPGRADE_THRESHOLD;
        for (uint8 i = 2; i < _level; i++) {
            required = required.mul(NFT_UPGRADE_SCALING_FACTOR);
        }
        return required;
    }

    // --- 10. getNexusNFTLevel ---
    function getNexusNFTLevel(uint256 _tokenId) public view returns (uint8) {
        return nexusNFT.getNFTLevel(_tokenId);
    }

    // --- 11. getSynapticLinks ---
    function getSynapticLinks(address _user) public view returns (uint256) {
        return userSynapticLinks[_user];
    }

    // --- 12. setOracleAIGuidance (Admin/Oracle Role) ---
    // Simulates an AI oracle providing input on a proposition
    function setOracleAIGuidance(uint256 _propositionId, bool _guidanceValue) external onlyOwner {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        if (prop.status != PropositionStatus.Pending) revert QuantumLeap__PropositionAlreadyResolved(); // Only set guidance for pending props
        if (currentEpoch >= prop.resolutionEpoch) revert QuantumLeap__PropositionNotResolvableYet(); // No guidance once past resolution

        prop.oracleAIGuidance = _guidanceValue;
        prop.oracleAIGuidanceSet = true;

        emit OracleAIGuidanceSet(_propositionId, _guidanceValue);
    }

    // --- 13. requestOracleAIGuidance (Simulated) ---
    // User can "request" AI guidance for a proposition (e.g., this could consume QLP or require a minimum reputation)
    // For now, it's just a placeholder and doesn't do anything complex.
    function requestOracleAIGuidance(uint256 _propositionId) external view {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        // Here you might add a QLP cost or reputation check
        // Return prop.oracleAIGuidance if already set, or default/error if not.
        // For simplicity, just return whether it's been set.
        if (!prop.oracleAIGuidanceSet) {
             // Revert or return a default "no guidance yet" value
            revert("No AI guidance set for this proposition yet.");
        }
        // In a real system, you'd integrate with Chainlink for AI results or a decentralized oracle network.
        // This function just confirms that guidance *could* be requested.
    }


    // --- 14. advanceEpoch ---
    // This function must be called periodically (e.g., by a keeper network or admin)
    // to advance the protocol's time and trigger resolutions.
    function advanceEpoch() external onlyOwner {
        uint256 nextEpoch = currentEpoch.add(1);
        // Ensure that at least `epochDuration` has passed since last advance (optional, for real time)
        // if (block.timestamp < currentEpoch * epochDuration + epochDuration) revert QuantumLeap__InvalidEpochTransition();

        currentEpoch = nextEpoch;
        
        // Check for propositions ready for resolution
        // This loop can be costly for many propositions; in production, use a queue or external keeper.
        for (uint256 i = 1; i < _propositionIds.current(); i++) {
            Proposition storage prop = propositions[i];
            if (prop.id != 0 && prop.status == PropositionStatus.Pending && currentEpoch >= prop.resolutionEpoch) {
                // Apply simulated AI guidance here if set, otherwise default to majority stake.
                PropositionStatus finalStatus;
                if (prop.oracleAIGuidanceSet) {
                    finalStatus = prop.oracleAIGuidance ? PropositionStatus.True : PropositionStatus.False;
                } else {
                    finalStatus = (prop.stakedForSupport >= prop.stakedForDispute) ? PropositionStatus.True : PropositionStatus.False;
                }
                prop.status = finalStatus;
                _distributePropositionRewards(i);
                emit PropositionResolved(i, finalStatus, currentEpoch);
            } else if (prop.id != 0 && prop.status == PropositionStatus.Disputed && prop.disputeId != 0) {
                 // Check if dispute voting period has ended
                Dispute storage dispute = disputes[prop.disputeId];
                if (!dispute.resolved && currentEpoch > dispute.votingEndEpoch) {
                    _resolveDispute(prop.disputeId);
                }
            }
        }
        emit EpochAdvanced(currentEpoch);
    }

    // --- View Functions ---

    // --- 15. getStreamDetails ---
    function getStreamDetails(uint256 _streamId) public view returns (Stream memory) {
        if (streams[_streamId].id == 0) revert QuantumLeap__InvalidStreamId();
        return streams[_streamId];
    }

    // --- 16. getPropositionDetails ---
    function getPropositionDetails(uint256 _propositionId) public view returns (Proposition memory) {
        if (propositions[_propositionId].id == 0) revert QuantumLeap__InvalidPropositionId();
        return propositions[_propositionId];
    }

    // --- 17. getUserPropositionStake ---
    function getUserPropositionStake(address _user, uint256 _propositionId)
        public
        view
        returns (uint256 supported, uint256 disputed)
    {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert QuantumLeap__InvalidPropositionId();
        return (prop.userSupportStakes[_user], prop.userDisputeStakes[_user]);
    }

    // --- 18. getTopCurators (Simplified) ---
    // A real leaderboard would require a dedicated off-chain indexing solution or a more complex on-chain array.
    // This is a placeholder for demonstration purposes.
    function getTopCurators(uint256 _limit) public view returns (address[] memory, uint256[] memory) {
        // In a real scenario, this would iterate over all users or a pre-sorted list.
        // For a demonstration, it's just a conceptual function.
        // Consider a limited loop or requiring an external indexer.
        // Example: Only returns owner's and a dummy's links for demo.
        address[] memory users = new address[](2);
        uint256[] memory links = new uint256[](2);

        users[0] = owner();
        links[0] = userSynapticLinks[owner()];

        users[1] = address(0x1234); // A dummy address for demonstration
        links[1] = userSynapticLinks[address(0x1234)];

        return (users, links);
    }

    // --- 19. getTotalStakedQLP ---
    function getTotalStakedQLP() public view returns (uint256) {
        return qlpToken.balanceOf(address(this));
    }

    // --- 20. getCurrentEpoch ---
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    // --- Admin & Utility Functions ---

    // --- 21. withdrawContractFunds ---
    function withdrawContractFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(qlpToken)) {
            qlpToken.transfer(msg.sender, _amount);
        } else {
            // For other ERC-20 tokens accidentally sent
            IERC20(_tokenAddress).transfer(msg.sender, _amount);
        }
    }

    // --- 22. pauseProtocol ---
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    // --- 23. unpauseProtocol ---
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    // --- 24. setMinimumStake ---
    function setMinimumStake(uint256 _newMinStreamStake, uint256 _newMinPropStake, uint256 _newMinCurateStake) external onlyOwner {
        MIN_STREAM_STAKE = _newMinStreamStake;
        MIN_PROPOSITION_STAKE = _newMinPropStake;
        MIN_CURATION_STAKE = _newMinCurateStake;
        emit MinimumStakeUpdated(_newMinPropStake); // Emit one for simplicity, could be multiple
    }

    // --- NexusNFT (ERC721) for Dynamic NFTs ---
    // This would be a separate contract, but included here for completeness of the concept
    // In a real deployment, you'd deploy this separately and pass its address to QuantumLeap constructor.
    // For this example, it's nested for easier compilation.
    contract NexusNFT is ERC721 {
        using Counters for Counters.Counter;
        Counters.Counter private _tokenIdCounter;

        // Mapping from tokenId to its current visual level
        mapping(uint256 => uint8) private _nftLevels;

        // Base URI for metadata (e.g., pointing to an IPFS gateway for dynamic JSON)
        string public baseURI;

        constructor() ERC721("Nexus NFT", "NXUS") {
            baseURI = "ipfs://QmbB123abc/metadata/"; // Example base URI (replace with real one)
        }

        // Mint function called by QuantumLeap
        function mint(address _to) external returns (uint256) {
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();
            _safeMint(_to, newItemId);
            _nftLevels[newItemId] = 1; // Start at Level 1
            return newItemId;
        }

        // Mint function for upgraded NFTs (called by QuantumLeap)
        function mintWithLevel(address _to, uint8 _level) external returns (uint256) {
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();
            _safeMint(_to, newItemId);
            _nftLevels[newItemId] = _level;
            return newItemId;
        }

        // Burn function (called by QuantumLeap during upgrade)
        function burn(uint256 _tokenId) external {
            require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not owner nor approved");
            _burn(_tokenId);
            delete _nftLevels[_tokenId];
        }

        // Get the current level of an NFT
        function getNFTLevel(uint256 _tokenId) public view returns (uint8) {
            return _nftLevels[_tokenId];
        }

        // Override tokenURI to provide dynamic metadata based on level
        function tokenURI(uint256 _tokenId) public view override returns (string memory) {
            _requireOwned(_tokenId);
            uint8 level = _nftLevels[_tokenId];
            // In a real scenario, this would return a URL like:
            // "ipfs://.../metadata/level_<level>.json" or
            // "https://api.yourdomain.com/nexusnft/<tokenId>"
            // that dynamically serves JSON based on the level.
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), "_level_", Strings.toString(level), ".json"));
        }

        // Set the base URI (can be updated for metadata changes)
        function setBaseURI(string memory _newBaseURI) external onlyOwner {
            baseURI = _newBaseURI;
        }
    }
}
```