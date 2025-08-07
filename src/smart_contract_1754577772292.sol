Here's a Solidity smart contract named "Synthetica Agora" which embodies several advanced and creative concepts: a dynamic micro-economy, adaptive parameter adjustment, intrinsic value for digital assets, and a nuanced on-chain reputation system.

---

## Synthetica Agora: A Decentralized Adaptive Micro-Economy for Curated Digital Assets & Knowledge Exchange

This contract introduces a novel ecosystem where digital assets (Synthetica Artifacts) and knowledge fragments possess a dynamic "Intrinsic Value" (IV) or "Wisdom Weight" (WW) derived from community curation, endorsement, and dispute resolution, rather than speculative market forces alone. The protocol's economic parameters (fees, rewards, thresholds) adapt over time based on on-chain activity and "system vitality." Users build an on-chain "Wisdom Weight" reputation score, which influences their impact and rewards.

### Key Concepts:

*   **Synthetica Artifacts (SA):** ERC721 NFTs whose value is influenced by community "curation" (staking ETH/tokens). Their "Intrinsic Value" is a calculated score reflecting curated value, utility, and time.
*   **Knowledge Fragments (KF):** Tokenized verifiable insights, data, or research snippets. They gain "Wisdom Weight" from community "endorsement" (staking ETH/tokens) and are subject to a unique dispute resolution mechanism.
*   **Intrinsic Value (IV):** A calculated, non-monetary score for Synthetica Artifacts, dynamically influenced by curator stakes, initial perceived value, and time decay.
*   **Wisdom Weight (WW):** A user-centric, non-transferable (soul-bound-like) reputation score. It increases with successful curation, endorsement, and correct dispute resolution, and decreases with adverse actions. It grants influence and reward potential.
*   **Dynamic Adjustment:** Core economic parameters (e.g., fees, reward multipliers, dispute stakes) are not fixed but adapt based on the overall health and activity of the Agora (e.g., total fees collected, number of disputes, content volume). This mimics a rudimentary "AI-like" adaptive behavior directly on-chain.

---

### Function Summary:

**I. Core Infrastructure & Protocol Control**

1.  **`constructor()`**: Initializes the contract, sets initial adaptive parameters, and deploys the internal ERC721 token for Synthetica Artifacts.
2.  **`updateAgoraParameters(AgoraParameters _newParams)`**: Allows the owner (or future DAO) to adjust core economic and behavioral parameters of the Agora.
3.  **`pauseAgora()`**: Pauses most state-changing operations in case of emergency.
4.  **`unpauseAgora()`**: Unpauses the contract.
5.  **`withdrawProtocolFees()`**: Allows the owner to withdraw accumulated protocol fees.

**II. Synthetica Artifacts (ERC721-Based Digital Assets) Management**

6.  **`mintArtifact(address _to, string calldata _tokenURI, uint256 _initialValue)`**: Mints a new Synthetica Artifact. The `_initialValue` contributes to its starting Intrinsic Value.
7.  **`burnArtifact(uint256 _artifactId)`**: Allows the artifact owner to burn their artifact, provided there are no active curator stakes.
8.  **`transferArtifact(address _from, address _to, uint256 _artifactId)`**: Standard ERC721 transfer function (inherited).
9.  **`curateArtifact(uint256 _artifactId, uint256 _amount)`**: Users stake `_amount` of ETH/tokens to "curate" an artifact, increasing its Intrinsic Value. Also increases the curator's Wisdom Weight.
10. **`reclaimCuratorStake(uint256 _artifactId)`**: Allows a curator to reclaim their staked tokens after a cooldown period, with a minor Wisdom Weight reduction.
11. **`getArtifactIntrinsicValue(uint256 _artifactId)`**: Calculates the current Intrinsic Value of an artifact based on curation stake, base value, and time decay.
12. **`getArtifactDetails(uint256 _artifactId)`**: Retrieves comprehensive details about a Synthetica Artifact.
13. **`getArtifactCuratorStake(uint256 _artifactId, address _curator)`**: Gets the staked amount by a specific curator on an artifact.

**III. Knowledge Fragments & Semantic Curation**

14. **`submitKnowledgeFragment(string calldata _uri, string calldata _title, string[] calldata _topics)`**: Submits a new knowledge fragment (e.g., IPFS hash of a research paper, data insight). Grants a small Wisdom Weight bonus to the submitter.
15. **`endorseKnowledgeFragment(uint256 _fragmentId, uint256 _amount)`**: Users stake tokens to "endorse" a knowledge fragment, contributing to its Wisdom Weight and increasing their own.
16. **`disputeKnowledgeFragment(uint256 _fragmentId, uint256 _amount)`**: Initiates a dispute against a knowledge fragment, requiring a significant stake to challenge its validity.
17. **`resolveDispute(uint256 _fragmentId, bool _isResolvedValid)`**: Owner/Governance resolves a dispute, impacting the fragment's Wisdom Weight and the Wisdom Weights of the disputer/submitter.
18. **`getKnowledgeFragmentWisdomWeight(uint256 _fragmentId)`**: Calculates the current Wisdom Weight of a knowledge fragment based on endorsements and dispute status.
19. **`getKnowledgeFragmentDetails(uint256 _fragmentId)`**: Retrieves detailed information about a Knowledge Fragment.
20. **`getFragmentEndorserStake(uint256 _fragmentId, address _endorser)`**: Gets the staked amount by a specific endorser on a fragment.

**IV. Adaptive Reward & Reputation System ("Wisdom Weight" - WW)**

21. **`updateUserWisdomWeight(address _user, int256 _delta)`**: Internal function to adjust a user's Wisdom Weight based on their actions.
22. **`claimCuratorRewards()`**: Allows users to claim a portion of the protocol's reward pool, proportional to their Wisdom Weight and successful participation.
23. **`getWisdomWeight(address _user)`**: Retrieves a user's current Wisdom Weight.

**V. Dynamic Protocol Adjustment**

24. **`triggerDynamicAdjustment()`**: A permissioned function (ideally called periodically by a DAO or a keeper bot) that recalculates and adjusts core protocol parameters based on aggregated on-chain metrics (e.g., total fees, reward pool balance, dispute volume).
25. **`getDynamicParameters()`**: Retrieves the current dynamically adjusted parameters.

**VI. Utility & Accounting**

26. **`getTotalProtocolFees()`**: Returns the total accumulated fees collected by the protocol.
27. **`getNextArtifactId()`**: Returns the ID that will be assigned to the next minted artifact.
28. **`getNextKnowledgeFragmentId()`**: Returns the ID that will be assigned to the next submitted knowledge fragment.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
//
// Synthetica Agora: A Decentralized Adaptive Micro-Economy for Curated Digital Assets & Knowledge Exchange.
// This contract introduces a novel ecosystem where digital assets (Synthetica Artifacts) and knowledge fragments
// possess a dynamic "Intrinsic Value" (IV) or "Wisdom Weight" (WW) derived from community curation,
// endorsement, and dispute resolution, rather than speculative market forces alone. The protocol's economic
// parameters (fees, rewards, thresholds) adapt over time based on on-chain activity and "system vitality."
// Users build an on-chain "Wisdom Weight" reputation score, which influences their impact and rewards.
//
// Key Concepts:
// - Synthetica Artifacts (SA): ERC721 NFTs whose value is influenced by community "curation" (staking).
// - Knowledge Fragments (KF): Tokenized verifiable insights/data, gaining "Wisdom Weight" from "endorsement" (staking).
// - Intrinsic Value (IV): A calculated score for SAs, reflecting their curated value and utility.
// - Wisdom Weight (WW): A user-centric reputation score, enhancing their influence and reward potential.
// - Dynamic Adjustment: Core economic parameters adapt based on network activity and health metrics.
//
// I. Core Infrastructure & Protocol Control
// 1.  constructor(): Initializes the contract, sets initial parameters, and deploys internal ERC721.
// 2.  updateAgoraParameters(uint256 _newBaseCurationFee, ...): Allows the owner (or governance) to adjust core economic parameters.
// 3.  pauseAgora(): Pauses the contract for emergencies, preventing most state-changing operations.
// 4.  unpauseAgora(): Unpauses the contract, re-enabling operations.
// 5.  withdrawProtocolFees(): Allows the owner to withdraw accumulated protocol fees.
//
// II. Synthetica Artifacts (ERC721-Based Digital Assets) Management
// 6.  mintArtifact(address _to, string calldata _tokenURI, uint256 _initialValue): Mints a new Synthetica Artifact.
// 7.  burnArtifact(uint256 _artifactId): Allows the artifact owner to burn their artifact under specific conditions.
// 8.  transferArtifact(address _from, address _to, uint256 _artifactId): Standard ERC721 transfer function (inherited).
// 9.  curateArtifact(uint256 _artifactId, uint256 _amount): Users stake tokens to "curate" an artifact, increasing its IV.
// 10. reclaimCuratorStake(uint256 _artifactId): Allows a curator to reclaim their staked tokens after a cooldown period.
// 11. getArtifactIntrinsicValue(uint256 _artifactId): Calculates the current Intrinsic Value of an artifact.
// 12. getArtifactDetails(uint256 _artifactId): Retrieves detailed information about an artifact.
// 13. getArtifactCuratorStake(uint256 _artifactId, address _curator): Gets the stake amount for a specific curator on an artifact.
//
// III. Knowledge Fragments & Semantic Curation
// 14. submitKnowledgeFragment(string calldata _uri, string calldata _title, string[] calldata _topics): Submits a new knowledge fragment.
// 15. endorseKnowledgeFragment(uint256 _fragmentId, uint256 _amount): Users stake tokens to "endorse" a knowledge fragment, increasing its Wisdom Weight.
// 16. disputeKnowledgeFragment(uint256 _fragmentId, uint256 _amount): Initiates a dispute against a knowledge fragment, requiring a higher stake.
// 17. resolveDispute(uint256 _fragmentId, bool _isResolvedValid): Owner/governance resolves a dispute, impacting fragment WW and user WWs.
// 18. getKnowledgeFragmentWisdomWeight(uint256 _fragmentId): Calculates the current Wisdom Weight of a knowledge fragment.
// 19. getKnowledgeFragmentDetails(uint256 _fragmentId): Retrieves detailed information about a knowledge fragment.
// 20. getFragmentEndorserStake(uint256 _fragmentId, address _endorser): Gets the stake for a specific endorser on a fragment.
//
// IV. Adaptive Reward & Reputation System ("Wisdom Weight" - WW)
// 21. updateUserWisdomWeight(address _user, int256 _delta): Internal function to adjust a user's Wisdom Weight.
// 22. claimCuratorRewards(): Allows users to claim rewards based on their successful curation/endorsement activities and WW.
// 23. getWisdomWeight(address _user): Retrieves a user's current Wisdom Weight.
//
// V. Dynamic Protocol Adjustment
// 24. triggerDynamicAdjustment(): A permissioned function to recalculate global economic parameters based on network activity.
// 25. getDynamicParameters(): Retrieves the current dynamically adjusted parameters.
//
// VI. Utility & Accounting
// 26. getTotalProtocolFees(): Returns the total accumulated protocol fees.
// 27. getNextArtifactId(): Returns the next available artifact ID.
// 28. getNextKnowledgeFragmentId(): Returns the next available knowledge fragment ID.

// --- Smart Contract Implementation ---

contract SyntheticaAgora is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Global counters for unique IDs
    Counters.Counter private _artifactIds;
    Counters.Counter private _knowledgeFragmentIds;

    // Protocol state
    bool public paused;

    // Structs for Digital Assets (Synthetica Artifacts)
    struct SyntheticaArtifact {
        uint256 id;
        address owner;
        string uri; // IPFS hash or metadata URI
        uint256 creationTime;
        uint256 baseIntrinsicValue; // Initial IV set by minter
        uint256 totalCuratorStake;
        mapping(address => uint256) curatorStakes; // Curator => Stake Amount
        mapping(address => uint256) curatorStakeTimes; // Curator => Timestamp of last stake update
    }

    mapping(uint256 => SyntheticaArtifact) public syntheticaArtifacts;
    mapping(uint256 => bool) public artifactExists; // Check if an artifact exists

    // Structs for Knowledge Fragments
    struct KnowledgeFragment {
        uint256 id;
        address submitter;
        string uri; // IPFS hash of content/data
        string title; // Short title for indexing
        string[] topics; // Keywords/topics for categorization
        uint256 submissionTime;
        uint256 totalEndorsementStake;
        mapping(address => uint256) endorserStakes; // Endorser => Stake Amount
        mapping(address => uint256) endorserStakeTimes; // Endorser => Timestamp of last stake update
        bool inDispute;
        uint256 disputeStake;
        address disputer;
    }

    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    mapping(uint256 => bool) public knowledgeFragmentExists;

    // User Wisdom Weight (Reputation Score)
    mapping(address => int256) public userWisdomWeight; // Can be negative for bad actors

    // Protocol Parameters (Initial & Dynamically Adjusted)
    struct AgoraParameters {
        uint256 baseCurationFee; // Fee for curating artifacts
        uint256 baseEndorsementFee; // Fee for endorsing knowledge fragments
        uint256 baseMintingFee; // Fee to mint a new artifact
        uint256 baseKnowledgeSubmissionFee; // Fee to submit a knowledge fragment
        uint256 minCuratorStake; // Minimum stake required to curate an artifact
        uint256 minEndorserStake; // Minimum stake required to endorse a fragment
        uint256 minDisputeStake; // Minimum stake to dispute a fragment
        uint256 curatorCooldownPeriod; // Time before curator can reclaim stake
        uint256 intrinsicValueMultiplier; // Multiplier for staked value in IV calculation
        uint256 wisdomWeightMultiplier; // Multiplier for staked value in WW calculation
        uint256 disputeResolutionBonus; // WW points
        uint256 disputeResolutionPenalty; // WW points
        uint256 timeDecayFactor; // Points per day, for IV/WW
        uint256 rewardPoolAllocationRate; // Percentage of fees allocated to reward pool (e.g., 1000 = 10%)
    }
    AgoraParameters public agoraParameters;
    uint256 public totalProtocolFees;
    uint256 public rewardPoolBalance;

    // Events
    event AgoraPaused(address indexed by);
    event AgoraUnpaused(address indexed by);
    event AgoraParametersUpdated(AgoraParameters newParams);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, string uri, uint256 initialValue);
    event ArtifactBurned(uint256 indexed artifactId, address indexed by);
    event ArtifactCurated(uint256 indexed artifactId, address indexed curator, uint256 amount, uint256 newTotalStake);
    event CuratorStakeReclaimed(uint256 indexed artifactId, address indexed curator, uint256 amount);

    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, address indexed submitter, string uri, string title, string[] topics);
    event KnowledgeFragmentEndorsed(uint256 indexed fragmentId, address indexed endorser, uint256 amount, uint256 newTotalStake);
    event KnowledgeFragmentDisputed(uint256 indexed fragmentId, address indexed disputer, uint256 amount);
    event KnowledgeDisputeResolved(uint256 indexed fragmentId, bool isValid, address indexed resolver);

    event UserWisdomWeightUpdated(address indexed user, int256 oldWeight, int256 newWeight);
    event CuratorRewardsClaimed(address indexed user, uint256 amount);
    event DynamicAdjustmentTriggered(uint256 timestamp);

    // --- Constructor ---

    constructor()
        ERC721("SyntheticaAgoraArtifact", "SAA") // Artifacts are ERC721
        Ownable(msg.sender) // Owner for initial control, can be migrated to DAO
    {
        paused = false;
        // Set initial parameters - these would ideally be set by a DAO or governance after deployment
        agoraParameters = AgoraParameters({
            baseCurationFee: 0.01 ether, // Example: 0.01 ETH
            baseEndorsementFee: 0.005 ether,
            baseMintingFee: 0.02 ether,
            baseKnowledgeSubmissionFee: 0.01 ether,
            minCuratorStake: 0.1 ether,
            minEndorserStake: 0.05 ether,
            minDisputeStake: 0.5 ether, // Higher stake for disputes
            curatorCooldownPeriod: 7 days,
            intrinsicValueMultiplier: 100, // For IV calculation: stake * multiplier (e.g., 1 ETH stake adds 100 IV points)
            wisdomWeightMultiplier: 10,    // For WW calculation: stake * multiplier (e.g., 1 ETH stake adds 10 WW points)
            disputeResolutionBonus: 50,    // WW points bonus for correct dispute resolution
            disputeResolutionPenalty: 100, // WW points penalty for incorrect dispute/submission
            timeDecayFactor: 1, // Points per day (e.g., IV/WW reduces by 1 point per day)
            rewardPoolAllocationRate: 1000 // 10% (1000/10000) of fees go to reward pool
        });
    }

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Agora: Paused");
        _;
    }

    modifier onlyValidArtifact(uint256 _artifactId) {
        require(artifactExists[_artifactId], "Artifact: Does not exist");
        _;
    }

    modifier onlyValidKnowledgeFragment(uint256 _fragmentId) {
        require(knowledgeFragmentExists[_fragmentId], "Fragment: Does not exist");
        _;
    }

    // --- I. Core Infrastructure & Protocol Control ---

    /// @notice Allows the owner to update core protocol parameters.
    /// @param _newParams A struct containing all new parameter values.
    function updateAgoraParameters(AgoraParameters memory _newParams) public onlyOwner {
        agoraParameters = _newParams;
        emit AgoraParametersUpdated(_newParams);
    }

    /// @notice Pauses the contract in emergencies. Only owner can call.
    function pauseAgora() public onlyOwner {
        paused = true;
        emit AgoraPaused(msg.sender);
    }

    /// @notice Unpauses the contract. Only owner can call.
    function unpauseAgora() public onlyOwner {
        paused = false;
        emit AgoraUnpaused(msg.sender);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() public onlyOwner {
        require(totalProtocolFees > 0, "No fees to withdraw");
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        payable(owner()).transfer(amount);
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    // --- II. Synthetica Artifacts (ERC721-Based Digital Assets) Management ---

    /// @notice Mints a new Synthetica Artifact (NFT).
    /// @param _to The address to mint the artifact to.
    /// @param _tokenURI The URI pointing to the artifact's metadata (e.g., IPFS hash).
    /// @param _initialValue An initial intrinsic value suggested by the minter (can be 0).
    function mintArtifact(address _to, string calldata _tokenURI, uint256 _initialValue)
        public payable whenNotPaused returns (uint256)
    {
        require(msg.value >= agoraParameters.baseMintingFee, "Minting: Insufficient fee");
        totalProtocolFees = totalProtocolFees.add(agoraParameters.baseMintingFee);
        rewardPoolBalance = rewardPoolBalance.add(agoraParameters.baseMintingFee.mul(agoraParameters.rewardPoolAllocationRate).div(10000));

        uint256 newItemId = _artifactIds.current();
        _artifactIds.increment();

        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        syntheticaArtifacts[newItemId] = SyntheticaArtifact({
            id: newItemId,
            owner: _to,
            uri: _tokenURI,
            creationTime: block.timestamp,
            baseIntrinsicValue: _initialValue,
            totalCuratorStake: 0
        });
        artifactExists[newItemId] = true;

        // Refund any excess ETH sent
        if (msg.value > agoraParameters.baseMintingFee) {
            payable(msg.sender).transfer(msg.value.sub(agoraParameters.baseMintingFee));
        }

        emit ArtifactMinted(newItemId, _to, _tokenURI, _initialValue);
        return newItemId;
    }

    /// @notice Allows the artifact owner to burn their artifact.
    /// @param _artifactId The ID of the artifact to burn.
    function burnArtifact(uint256 _artifactId) public onlyValidArtifact(_artifactId) {
        require(syntheticaArtifacts[_artifactId].owner == msg.sender, "Artifact: Not owner");
        require(syntheticaArtifacts[_artifactId].totalCuratorStake == 0, "Artifact: Cannot burn with active stakes");

        _burn(_artifactId);
        delete syntheticaArtifacts[_artifactId];
        artifactExists[_artifactId] = false;

        emit ArtifactBurned(_artifactId, msg.sender);
    }

    /// @notice Curate an artifact by staking tokens, increasing its Intrinsic Value.
    /// @param _artifactId The ID of the artifact to curate.
    /// @param _amount The amount of tokens to stake for curation.
    function curateArtifact(uint256 _artifactId, uint256 _amount)
        public payable whenNotPaused onlyValidArtifact(_artifactId)
    {
        require(_amount >= agoraParameters.minCuratorStake, "Curation: Stake too low");
        require(msg.value >= agoraParameters.baseCurationFee.add(_amount), "Curation: Insufficient funds (stake + fee)");

        totalProtocolFees = totalProtocolFees.add(agoraParameters.baseCurationFee);
        rewardPoolBalance = rewardPoolBalance.add(agoraParameters.baseCurationFee.mul(agoraParameters.rewardPoolAllocationRate).div(10000));

        SyntheticaArtifact storage artifact = syntheticaArtifacts[_artifactId];
        artifact.totalCuratorStake = artifact.totalCuratorStake.add(_amount);
        artifact.curatorStakes[msg.sender] = artifact.curatorStakes[msg.sender].add(_amount);
        artifact.curatorStakeTimes[msg.sender] = block.timestamp;

        // Refund any excess ETH sent
        if (msg.value > _amount.add(agoraParameters.baseCurationFee)) {
            payable(msg.sender).transfer(msg.value.sub(_amount).sub(agoraParameters.baseCurationFee));
        }

        // Update user's Wisdom Weight based on stake
        // Div by 1 ether to normalize amount, then multiply by WW multiplier
        updateUserWisdomWeight(msg.sender, int256(_amount.div(1 ether).mul(agoraParameters.wisdomWeightMultiplier))); 

        emit ArtifactCurated(_artifactId, msg.sender, _amount, artifact.totalCuratorStake);
    }

    /// @notice Allows a curator to reclaim their staked tokens after a cooldown period.
    /// @param _artifactId The ID of the artifact.
    function reclaimCuratorStake(uint256 _artifactId) public whenNotPaused onlyValidArtifact(_artifactId) {
        SyntheticaArtifact storage artifact = syntheticaArtifacts[_artifactId];
        uint256 stake = artifact.curatorStakes[msg.sender];
        require(stake > 0, "Curation: No stake to reclaim");
        require(block.timestamp >= artifact.curatorStakeTimes[msg.sender].add(agoraParameters.curatorCooldownPeriod),
                "Curation: Cooldown period not over");

        artifact.totalCuratorStake = artifact.totalCuratorStake.sub(stake);
        artifact.curatorStakes[msg.sender] = 0;
        delete artifact.curatorStakeTimes[msg.sender]; // Clear timestamp

        payable(msg.sender).transfer(stake); // Return the staked tokens

        // Reduce user's Wisdom Weight proportional to reclaimed stake (e.g., half the original WW gain)
        updateUserWisdomWeight(msg.sender, -int256(stake.div(1 ether).mul(agoraParameters.wisdomWeightMultiplier).div(2)));

        emit CuratorStakeReclaimed(_artifactId, msg.sender, stake);
    }

    /// @notice Calculates the current Intrinsic Value of an artifact.
    /// @param _artifactId The ID of the artifact.
    /// @return The calculated Intrinsic Value.
    function getArtifactIntrinsicValue(uint256 _artifactId) public view onlyValidArtifact(_artifactId) returns (uint256) {
        SyntheticaArtifact storage artifact = syntheticaArtifacts[_artifactId];
        uint256 timeElapsed = block.timestamp.sub(artifact.creationTime);
        uint256 timeDecay = timeElapsed.div(1 days).mul(agoraParameters.timeDecayFactor); // Decay per day

        // IV = Base Value + (Total Staked * Multiplier) - (Time Elapsed * Decay Factor)
        uint256 iv = artifact.baseIntrinsicValue.add(artifact.totalCuratorStake.mul(agoraParameters.intrinsicValueMultiplier));

        if (iv > timeDecay) {
            iv = iv.sub(timeDecay);
        } else {
            iv = 0; // IV cannot go below zero
        }
        return iv;
    }

    /// @notice Retrieves detailed information about a Synthetica Artifact.
    /// @param _artifactId The ID of the artifact.
    function getArtifactDetails(uint256 _artifactId)
        public view onlyValidArtifact(_artifactId)
        returns (uint256 id, address owner, string memory uri, uint256 creationTime, uint256 baseIntrinsicValue, uint256 totalCuratorStake, uint256 currentIntrinsicValue)
    {
        SyntheticaArtifact storage artifact = syntheticaArtifacts[_artifactId];
        return (
            artifact.id,
            artifact.owner,
            artifact.uri,
            artifact.creationTime,
            artifact.baseIntrinsicValue,
            artifact.totalCuratorStake,
            getArtifactIntrinsicValue(_artifactId)
        );
    }

    /// @notice Gets the amount of tokens a specific curator has staked on an artifact.
    /// @param _artifactId The ID of the artifact.
    /// @param _curator The address of the curator.
    /// @return The staked amount.
    function getArtifactCuratorStake(uint256 _artifactId, address _curator) public view onlyValidArtifact(_artifactId) returns (uint256) {
        return syntheticaArtifacts[_artifactId].curatorStakes[_curator];
    }

    // --- III. Knowledge Fragments & Semantic Curation ---

    /// @notice Submits a new knowledge fragment.
    /// @param _uri The URI (e.g., IPFS hash) to the fragment's content.
    /// @param _title A short, descriptive title for the fragment.
    /// @param _topics An array of keywords or topics for categorization.
    function submitKnowledgeFragment(string calldata _uri, string calldata _title, string[] calldata _topics)
        public payable whenNotPaused returns (uint256)
    {
        require(msg.value >= agoraParameters.baseKnowledgeSubmissionFee, "Submission: Insufficient fee");
        totalProtocolFees = totalProtocolFees.add(agoraParameters.baseKnowledgeSubmissionFee);
        rewardPoolBalance = rewardPoolBalance.add(agoraParameters.baseKnowledgeSubmissionFee.mul(agoraParameters.rewardPoolAllocationRate).div(10000));

        uint256 newFragmentId = _knowledgeFragmentIds.current();
        _knowledgeFragmentIds.increment();

        knowledgeFragments[newFragmentId] = KnowledgeFragment({
            id: newFragmentId,
            submitter: msg.sender,
            uri: _uri,
            title: _title,
            topics: _topics,
            submissionTime: block.timestamp,
            totalEndorsementStake: 0,
            inDispute: false,
            disputeStake: 0,
            disputer: address(0)
        });
        knowledgeFragmentExists[newFragmentId] = true;

        // Refund any excess ETH sent
        if (msg.value > agoraParameters.baseKnowledgeSubmissionFee) {
            payable(msg.sender).transfer(msg.value.sub(agoraParameters.baseKnowledgeSubmissionFee));
        }

        updateUserWisdomWeight(msg.sender, int256(10)); // Small WW bonus for submission

        emit KnowledgeFragmentSubmitted(newFragmentId, msg.sender, _uri, _title, _topics);
        return newFragmentId;
    }

    /// @notice Endorses a knowledge fragment by staking tokens, increasing its Wisdom Weight.
    /// @param _fragmentId The ID of the knowledge fragment.
    /// @param _amount The amount of tokens to stake for endorsement.
    function endorseKnowledgeFragment(uint256 _fragmentId, uint256 _amount)
        public payable whenNotPaused onlyValidKnowledgeFragment(_fragmentId)
    {
        require(_amount >= agoraParameters.minEndorserStake, "Endorsement: Stake too low");
        require(msg.value >= agoraParameters.baseEndorsementFee.add(_amount), "Endorsement: Insufficient funds (stake + fee)");
        require(!knowledgeFragments[_fragmentId].inDispute, "Endorsement: Fragment is currently under dispute.");

        totalProtocolFees = totalProtocolFees.add(agoraParameters.baseEndorsementFee);
        rewardPoolBalance = rewardPoolBalance.add(agoraParameters.baseEndorsementFee.mul(agoraParameters.rewardPoolAllocationRate).div(10000));

        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        fragment.totalEndorsementStake = fragment.totalEndorsementStake.add(_amount);
        fragment.endorserStakes[msg.sender] = fragment.endorserStakes[msg.sender].add(_amount);
        fragment.endorserStakeTimes[msg.sender] = block.timestamp;

        // Refund any excess ETH sent
        if (msg.value > _amount.add(agoraParameters.baseEndorsementFee)) {
            payable(msg.sender).transfer(msg.value.sub(_amount).sub(agoraParameters.baseEndorsementFee));
        }

        // Update user's Wisdom Weight
        updateUserWisdomWeight(msg.sender, int256(_amount.div(1 ether).mul(agoraParameters.wisdomWeightMultiplier)));

        emit KnowledgeFragmentEndorsed(_fragmentId, msg.sender, _amount, fragment.totalEndorsementStake);
    }

    /// @notice Initiates a dispute against a knowledge fragment.
    /// @param _fragmentId The ID of the knowledge fragment to dispute.
    /// @param _amount The amount of tokens to stake for the dispute.
    function disputeKnowledgeFragment(uint256 _fragmentId, uint256 _amount)
        public payable whenNotPaused onlyValidKnowledgeFragment(_fragmentId)
    {
        require(_amount >= agoraParameters.minDisputeStake, "Dispute: Stake too low");
        require(msg.value >= _amount, "Dispute: Insufficient stake sent");
        require(!knowledgeFragments[_fragmentId].inDispute, "Dispute: Fragment already under dispute");
        require(knowledgeFragments[_fragmentId].submitter != msg.sender, "Dispute: Cannot dispute your own fragment");

        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        fragment.inDispute = true;
        fragment.disputeStake = _amount;
        fragment.disputer = msg.sender;

        // Any excess ETH sent for stake is refunded.
        if (msg.value > _amount) {
            payable(msg.sender).transfer(msg.value.sub(_amount));
        }

        emit KnowledgeFragmentDisputed(_fragmentId, msg.sender, _amount);
    }

    /// @notice Owner/Governance resolves a dispute for a knowledge fragment.
    /// @param _fragmentId The ID of the fragment.
    /// @param _isResolvedValid True if the fragment is deemed valid, false if invalid.
    function resolveDispute(uint256 _fragmentId, bool _isResolvedValid)
        public onlyOwner whenNotPaused onlyValidKnowledgeFragment(_fragmentId)
    {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.inDispute, "Dispute: Fragment not under dispute");

        address disputer = fragment.disputer;
        uint256 disputeStake = fragment.disputeStake;

        // Reset dispute status
        fragment.inDispute = false;
        fragment.disputeStake = 0;
        fragment.disputer = address(0);

        if (_isResolvedValid) {
            // Fragment is valid: Disputer loses stake, it's added to protocol fees.
            // Disputer gets a WW penalty.
            totalProtocolFees = totalProtocolFees.add(disputeStake);
            rewardPoolBalance = rewardPoolBalance.add(disputeStake.mul(agoraParameters.rewardPoolAllocationRate).div(10000));
            updateUserWisdomWeight(disputer, -int256(agoraParameters.disputeResolutionPenalty));
        } else {
            // Fragment is invalid: Disputer wins, gets stake back + bonus.
            // Disputer gets a WW bonus. Submitter gets a WW penalty.
            payable(disputer).transfer(disputeStake.add(disputeStake.div(10))); // Return stake + 10% bonus
            updateUserWisdomWeight(disputer, int256(agoraParameters.disputeResolutionBonus));
            updateUserWisdomWeight(fragment.submitter, -int256(agoraParameters.disputeResolutionPenalty));
            // In a more complex system, endorsers might face penalties or forced stake reclamation here.
            // For simplicity, their WW is indirectly affected by the fragment's lower WW.
        }

        emit KnowledgeDisputeResolved(_fragmentId, _isResolvedValid, msg.sender);
    }

    /// @notice Calculates the current Wisdom Weight of a knowledge fragment.
    /// @param _fragmentId The ID of the knowledge fragment.
    /// @return The calculated Wisdom Weight.
    function getKnowledgeFragmentWisdomWeight(uint256 _fragmentId) public view onlyValidKnowledgeFragment(_fragmentId) returns (uint256) {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        uint256 timeElapsed = block.timestamp.sub(fragment.submissionTime);
        uint256 timeDecay = timeElapsed.div(1 days).mul(agoraParameters.timeDecayFactor);

        // WW = Total Endorsed Stake * Multiplier - (Time Elapsed * Decay Factor)
        uint256 ww = fragment.totalEndorsementStake.mul(agoraParameters.wisdomWeightMultiplier);

        if (ww > timeDecay) {
            ww = ww.sub(timeDecay);
        } else {
            ww = 0; // WW cannot go below zero
        }

        // If in dispute, reduce effective WW
        if (fragment.inDispute) {
            ww = ww.div(2); // Halve WW during dispute to signal uncertainty
        }
        return ww;
    }

    /// @notice Retrieves detailed information about a Knowledge Fragment.
    /// @param _fragmentId The ID of the knowledge fragment.
    function getKnowledgeFragmentDetails(uint256 _fragmentId)
        public view onlyValidKnowledgeFragment(_fragmentId)
        returns (uint256 id, address submitter, string memory uri, string memory title, string[] memory topics, uint256 submissionTime, uint256 totalEndorsementStake, bool inDispute, uint256 currentWisdomWeight)
    {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        return (
            fragment.id,
            fragment.submitter,
            fragment.uri,
            fragment.title,
            fragment.topics,
            fragment.submissionTime,
            fragment.totalEndorsementStake,
            fragment.inDispute,
            getKnowledgeFragmentWisdomWeight(_fragmentId)
        );
    }

    /// @notice Gets the amount of tokens a specific endorser has staked on a knowledge fragment.
    /// @param _fragmentId The ID of the fragment.
    /// @param _endorser The address of the endorser.
    /// @return The staked amount.
    function getFragmentEndorserStake(uint256 _fragmentId, address _endorser) public view onlyValidKnowledgeFragment(_fragmentId) returns (uint256) {
        return knowledgeFragments[_fragmentId].endorserStakes[_endorser];
    }

    // --- IV. Adaptive Reward & Reputation System ("Wisdom Weight" - WW) ---

    /// @notice Internal function to adjust a user's Wisdom Weight.
    /// @param _user The address of the user.
    /// @param _delta The amount to add or subtract from their WW.
    function updateUserWisdomWeight(address _user, int256 _delta) internal {
        int256 oldWeight = userWisdomWeight[_user];
        userWisdomWeight[_user] = userWisdomWeight[_user].add(_delta);
        emit UserWisdomWeightUpdated(_user, oldWeight, userWisdomWeight[_user]);
    }

    /// @notice Allows users to claim rewards based on their Wisdom Weight and successful curation/endorsement activities.
    /// A simplified distribution model for demonstration.
    function claimCuratorRewards() public whenNotPaused {
        require(userWisdomWeight[msg.sender] > 0, "Rewards: Insufficient Wisdom Weight or not eligible");
        require(rewardPoolBalance > 0, "Rewards: Pool is empty");

        // Simplified proportional reward: (user's WW / some total WW scale) * portion of pool.
        // In a real system, `totalActiveWisdomWeight` would be tracked, and rewards would
        // be allocated based on the success and duration of specific contributions.
        // For this example, let's use a fixed denominator for scaling to avoid complex sum of all WWs.
        uint256 claimableAmount = rewardPoolBalance.mul(uint256(userWisdomWeight[msg.sender])).div(1_000_000_000); // Scale down by a large fixed factor

        require(claimableAmount > 0, "Rewards: No claimable amount");
        require(rewardPoolBalance >= claimableAmount, "Rewards: Not enough in pool");

        rewardPoolBalance = rewardPoolBalance.sub(claimableAmount);
        payable(msg.sender).transfer(claimableAmount);

        // Reduce WW after claiming to simulate "consuming" influence/rewards
        updateUserWisdomWeight(msg.sender, -int256(claimableAmount.div(1 ether).div(10))); // Small WW reduction per ETH claimed

        emit CuratorRewardsClaimed(msg.sender, claimableAmount);
    }

    /// @notice Retrieves a user's current Wisdom Weight.
    /// @param _user The address of the user.
    /// @return The current Wisdom Weight.
    function getWisdomWeight(address _user) public view returns (int256) {
        return userWisdomWeight[_user];
    }

    // --- V. Dynamic Protocol Adjustment ---

    /// @notice Triggers a recalculation of global economic parameters based on network activity.
    ///         This function should ideally be called periodically by a trusted oracle,
    ///         a time-locked function, or a DAO proposal.
    function triggerDynamicAdjustment() public onlyOwner whenNotPaused {
        // This is where the "adaptive" logic resides.
        // The adjustments here are simplified examples.
        // A real system would gather more metrics (e.g., number of active curators, total IV of artifacts,
        // average dispute resolution time, growth rate of knowledge fragments) and use more sophisticated
        // algorithms (but still deterministic and on-chain) to adjust parameters.

        // Example 1: If protocol fees are high, reduce minting/submission fees to encourage more activity.
        if (totalProtocolFees > 10 ether) {
            agoraParameters.baseMintingFee = agoraParameters.baseMintingFee.div(2).max(1 wei); // Don't go to zero
            agoraParameters.baseKnowledgeSubmissionFee = agoraParameters.baseKnowledgeSubmissionFee.div(2).max(1 wei);
        }
        // Example 2: If the reward pool is low, increase the allocation rate from fees to replenish it.
        if (rewardPoolBalance < 1 ether && totalProtocolFees > 0) {
            agoraParameters.rewardPoolAllocationRate = agoraParameters.rewardPoolAllocationRate.add(100); // Increase by 1%
        }
        // Example 3: If too many disputes are pending (requires tracking `numPendingDisputes`), increase dispute stake.
        // (Not implemented for brevity, but shows the type of metric)
        // if (numPendingDisputes > threshold) { agoraParameters.minDisputeStake = agoraParameters.minDisputeStake.mul(2); }

        // Ensure parameters stay within reasonable bounds (e.g., percentage doesn't exceed 100%)
        agoraParameters.rewardPoolAllocationRate = agoraParameters.rewardPoolAllocationRate.min(10000); // Max 100%

        emit DynamicAdjustmentTriggered(block.timestamp);
        emit AgoraParametersUpdated(agoraParameters); // Emit updated parameters for transparency
    }

    /// @notice Retrieves the current dynamically adjusted parameters.
    function getDynamicParameters() public view returns (AgoraParameters memory) {
        return agoraParameters;
    }

    // --- VI. Utility & Accounting ---

    /// @notice Returns the total accumulated protocol fees.
    function getTotalProtocolFees() public view returns (uint256) {
        return totalProtocolFees;
    }

    /// @notice Returns the next available artifact ID.
    function getNextArtifactId() public view returns (uint256) {
        return _artifactIds.current();
    }

    /// @notice Returns the next available knowledge fragment ID.
    function getNextKnowledgeFragmentId() public view returns (uint256) {
        return _knowledgeFragmentIds.current();
    }

    // Override the `supportsInterface` function required by ERC165 and ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Fallback function to accept ETH (e.g., for fees if not explicitly handled)
    receive() external payable {
        // This makes the contract able to receive ETH directly.
        // All fee and stake payments are explicitly handled in functions,
        // so this is mostly for unexpected transfers or future additions.
    }
}
```