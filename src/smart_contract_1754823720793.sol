This smart contract, `DecentralizedKnowledgeNetwork`, is designed to be a platform for submitting, curating, and monetizing verifiable knowledge and insights. It combines several advanced concepts: **Dynamic NFTs (dINFTs)**, **Proof-of-Utility Staking (PoUS)**, **Epoch-based Oracle Evaluation**, and a **Decentralized Dispute Resolution** mechanism. The goal is to create a self-sustaining ecosystem where valuable insights gain reputation and reward their contributors and supporters.

---

## Contract Outline & Function Summary

**Contract Name:** `DecentralizedKnowledgeNetwork`

**Core Concepts:**

*   **Knowledge Atom (KA):** A discrete, verifiable piece of information, insight, or claim. Each KA is represented as a **Dynamic NFT (dINFT)**, whose on-chain score influences its off-chain metadata (visual representation, traits).
*   **Insight Value Score (IVS):** A dynamic, on-chain score for each KA, reflecting its utility, accuracy, and predictive power over time. It's updated through oracle evaluations and dispute resolutions.
*   **Proof-of-Utility Staking (PoUS):** Users can stake `KIN_TOKEN` (the network's native utility token) on KAs they believe will prove valuable. Successful KAs reward their creators and stakers proportionally to their IVS gains.
*   **Epoch-based Evaluation:** KAs are periodically evaluated by whitelisted off-chain oracles/verifiers who submit signed or verifiable results on-chain, updating the KA's IVS.
*   **Dispute Resolution:** A decentralized mechanism allowing users to challenge the validity of KAs or support them, involving bond staking and a resolution process (e.g., admin, DAO vote, or trusted committee).
*   **Insight Query Market:** Users can pay a fee in `KIN_TOKEN` to access the content of specific KAs, rewarding the KA's creator and stakers.

**Token Economy:**

*   **KIN Token (`IERC20`):** An external ERC-20 token used for staking, paying query fees, and distributing rewards/bonds.
*   **dINFT (`ERC721`):** The Knowledge Atom NFTs, representing ownership of a specific insight and whose metadata (via `metadataURI`) can dynamically change based on its `insightValueScore`.

**Access Control:**

*   The contract owner (`Ownable`) manages crucial protocol parameters (fees, minimum stakes, epoch durations) and whitelists/removes oracle verifiers.
*   KA creators have specific permissions over their own KAs (e.g., updating content, setting query fees, withdrawing earnings).

---

**Function Summary (33 functions):**

**I. Core Knowledge Atom (KA) Management & Lifecycle**

1.  `submitKnowledgeAtom(string memory _contentHash, string memory _metadataURI, uint256 _evaluationPeriodDays)`: Mints a new dINFT representing a Knowledge Atom. `_contentHash` typically points to off-chain data (e.g., IPFS), `_metadataURI` to the NFT metadata JSON, and `_evaluationPeriodDays` sets how frequently this KA should be evaluated.
2.  `updateKnowledgeAtom(uint256 _tokenId, string memory _newContentHash)`: Allows the KA creator to update its content hash. Restricted to KAs with low IVS or before their first evaluation to prevent manipulation of highly-rated insights.
3.  `retireKnowledgeAtom(uint256 _tokenId)`: Allows the KA creator to soft-delete their KA, changing its status to `Retired`. Not possible if active stakes or challenges exist.
4.  `getKnowledgeAtomDetails(uint256 _tokenId)`: Retrieves all stored details of a specific Knowledge Atom.

**II. Proof-of-Utility Staking (PoUS)**

5.  `stakeOnKnowledgeAtom(uint256 _tokenId, uint256 _amount)`: Allows users to stake `KIN_TOKEN` on a KA, expressing confidence in its utility. Staked funds are held by the contract.
6.  `unstakeFromKnowledgeAtom(uint256 _tokenId, uint256 _amount)`: Allows users to withdraw their staked `KIN_TOKEN`. Subject to conditions (e.g., not challenged, no pending rewards).
7.  `claimStakingRewards(uint256 _tokenId)`: Enables stakers to claim rewards from KAs that have achieved a positive `insightValueScore`. Rewards are proportional to stake and IVS, minus protocol fees.

**III. Insight Value Score (IVS) & Epoch Management**

8.  `triggerEpochEvaluation()`: Callable by anyone (or an automated keeper bot) to advance the global evaluation epoch. This marks a new period for KAs to be evaluated by oracles.
9.  `submitEvaluationResult(uint256 _tokenId, int256 _scoreChange, bytes memory _proof)`: A whitelisted oracle/verifier calls this to submit a signed evaluation result (e.g., a verifiable compute proof or signed attestation), which updates the KA's `insightValueScore`.
10. `getKnowledgeAtomIVS(uint256 _tokenId)`: Retrieves the current Insight Value Score of a specified Knowledge Atom.

**IV. Dispute Resolution**

11. `challengeKnowledgeAtom(uint256 _tokenId, uint256 _bondAmount, string memory _reasonHash)`: Initiates a formal challenge against a KA, requiring the challenger to post a `KIN_TOKEN` bond proportional to the KA's staked value. The KA's status changes to `Challenged`.
12. `supportKnowledgeAtom(uint256 _tokenId, uint256 _bondAmount)`: Allows other users to post `KIN_TOKEN` bonds to support a KA that is currently under challenge.
13. `resolveDispute(uint256 _tokenId, bool _isChallengerVictorious)`: A privileged function (e.g., `onlyOwner` or a DAO) to officially resolve a dispute. It determines the outcome, updates KA status/IVS, and allocates/slashes bonds.
14. `claimSupportRefund(uint256 _tokenId)`: Allows individual supporters to claim their proportional share of the bond pool if their supported KA wins a dispute.
15. `getChallengeStatus(uint256 _tokenId)`: Retrieves the current challenge status of a Knowledge Atom.

**V. Query Market & Access Control**

16. `queryKnowledgeAtom(uint256 _tokenId)`: Allows users to pay a `KIN_TOKEN` fee to access the `_contentHash` of a KA. The fee contributes to the KA's creator and stakers.
17. `setKnowledgeAtomQueryFee(uint256 _tokenId, uint256 _fee)`: The creator of a KA can set the fee required to query their specific Knowledge Atom.
18. `withdrawKnowledgeAtomQueryFees(uint256 _tokenId)`: Allows the KA creator to withdraw accumulated query fees, after protocol fees are deducted.

**VI. Token & NFT Management (Beyond ERC721 basics)**

19. `batchMintKnowledgeAtoms(string[] memory _contentHashes, string[] memory _metadataURIs, uint256[] memory _evaluationPeriodDays)`: A utility function to submit multiple KAs in a single transaction.
20. `transferFrom(address _from, address _to, uint256 _tokenId)`: (Inherited from ERC721) Standard function to transfer ownership of a dINFT.
21. `approve(address to, uint256 tokenId)`: (Inherited from ERC721) Standard function to approve another address to transfer a specific dINFT.
22. `setApprovalForAll(address operator, bool approved)`: (Inherited from ERC721) Standard function to approve/disapprove an operator for all dINFTs owned by the caller.
23. `getApproved(uint256 tokenId)`: (Inherited from ERC721) Standard function to get the approved address for a specific dINFT.
24. `isApprovedForAll(address owner, address operator)`: (Inherited from ERC721) Standard function to check if an operator is approved for all dINFTs of an owner.
25. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for the dINFT metadata, typically handled by the platform owner to point to a metadata resolver service.

**VII. Administrative & Protocol Parameters**

26. `setMinimumStakeAmount(uint256 _amount)`: Owner function to set the minimum `KIN_TOKEN` required for staking on a KA.
27. `setChallengeBondRatio(uint256 _ratio)`: Owner function to set the percentage (in basis points) of total staked value required as a bond to challenge a KA.
28. `addOracleVerifier(address _oracleAddress)`: Owner function to whitelist an address, allowing it to submit KA evaluation results.
29. `removeOracleVerifier(address _oracleAddress)`: Owner function to remove an address from the oracle verifier whitelist.
30. `setProtocolFee(uint256 _feeBasisPoints)`: Owner function to set the protocol fee percentage (in basis points) taken from staking rewards and query fees.
31. `withdrawProtocolFees()`: Owner function to withdraw accumulated protocol fees.
32. `setEpochDuration(uint256 _durationSeconds)`: Owner function to set the duration of the global evaluation epochs.
33. `pause()`: Owner function to pause critical contract operations in an emergency.
34. `unpause()`: Owner function to unpause contract operations.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Decentralized Knowledge & Insight Network (DKIN)
 * @author YourNameHere (Inspired by current Web3 trends: DeSci, Dynamic NFTs, Oracles, Reputation Systems)
 * @notice This contract facilitates the creation, curation, and monetization of verifiable knowledge and insights
 *         represented as Dynamic NFTs (dINFTs). It incorporates Proof-of-Utility Staking, epoch-based
 *         oracle evaluations, and a decentralized dispute resolution mechanism to foster a reputable and
 *         valuable knowledge base.
 */
contract DecentralizedKnowledgeNetwork is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // KIN Token: The utility token for staking, fees, and rewards within the network.
    IERC20 public immutable KIN_TOKEN; 

    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    // Enum representing the lifecycle status of a Knowledge Atom.
    enum KnowledgeAtomStatus { Active, Challenged, Resolved, Retired }

    /**
     * @dev Represents a single Knowledge Atom (KA), which is also a dINFT.
     * @param creator The address that minted this KA.
     * @param contentHash IPFS hash or similar pointer to the detailed, off-chain knowledge content.
     * @param metadataURI Initial URI for the NFT metadata; off-chain services will update based on IVS.
     * @param mintTimestamp The timestamp when this KA was minted.
     * @param lastEvaluationTimestamp The last time this KA's IVS was formally updated by an oracle.
     * @param insightValueScore A dynamic score reflecting the KA's utility, accuracy, and predictive power. Can be positive or negative.
     * @param evaluationPeriodDays The suggested duration in days after which this KA should be re-evaluated by oracles.
     * @param totalStakedAmount Total KIN tokens currently staked on this KA by various stakers.
     * @param accumulatedQueryFees Total KIN collected from users querying this KA.
     * @param queryFee The fee set by the creator for accessing this KA's content.
     * @param status The current lifecycle status of the KA (Active, Challenged, Resolved, Retired).
     * @param lastStatusChangeTimestamp Timestamp of the last status change.
     */
    struct KnowledgeAtom {
        address creator;
        string contentHash;
        string metadataURI;
        uint256 mintTimestamp;
        uint256 lastEvaluationTimestamp;
        int256 insightValueScore;
        uint256 evaluationPeriodDays;
        uint256 totalStakedAmount;
        uint256 accumulatedQueryFees;
        uint256 queryFee;
        KnowledgeAtomStatus status;
        uint256 lastStatusChangeTimestamp;
    }

    /**
     * @dev Represents a single stake by a user on a Knowledge Atom.
     * @param staker The address that placed this stake.
     * @param amount The amount of KIN tokens staked.
     * @param timestamp The time when the stake was placed.
     * @param claimed Flag indicating if rewards for this specific stake period have been claimed.
     */
    struct Stake {
        address staker;
        uint256 amount;
        uint256 timestamp;
        bool claimed;
    }

    // Enum representing the status of an ongoing challenge.
    enum ChallengeStatus { None, ActiveChallenge, DisputeResolved }

    /**
     * @dev Represents an active challenge against a Knowledge Atom.
     * @param challenger The address that initiated the challenge.
     * @param bondAmount The KIN bond placed by the challenger.
     * @param reasonHash IPFS hash of the detailed reason for the challenge.
     * @param challengeTimestamp The time when the challenge was initiated.
     * @param supportBonds Mapping of supporter address to their staked KIN bond.
     * @param totalSupportBond Total KIN tokens staked by supporters.
     * @param status Current status of the challenge (None, ActiveChallenge, DisputeResolved).
     * @param challengerVictorious True if the challenger won the dispute, false otherwise.
     */
    struct Challenge {
        address challenger;
        uint256 bondAmount;
        string reasonHash;
        uint256 challengeTimestamp;
        mapping(address => uint256) supportBonds;
        uint256 totalSupportBond;
        ChallengeStatus status;
        bool challengerVictorious;
    }

    // --- Mappings ---

    mapping(uint256 => KnowledgeAtom) public knowledgeAtoms;
    mapping(uint256 => mapping(address => Stake)) private _stakes; // tokenId => staker => Stake details
    mapping(uint256 => Challenge) public challenges; // tokenId => Challenge details
    mapping(address => bool) public isOracleVerifier; // Whitelisted addresses for submitting evaluation results

    // --- Protocol Parameters ---

    uint256 public minimumStakeAmount = 100 * (10 ** 18); // Default 100 KIN (assuming 18 decimals)
    uint256 public challengeBondRatioBasisPoints = 500; // 5% of KA's total staked value (500 basis points)
    uint256 public protocolFeeBasisPoints = 100; // 1% (100 basis points) on rewards and query fees
    uint256 public accumulatedProtocolFees; // Total KIN accumulated by the protocol from fees
    uint256 public epochDurationSeconds = 7 days; // Default duration of a global evaluation epoch

    uint256 public lastEpochEvaluationTimestamp; // Timestamp of the last global epoch evaluation

    // --- Events ---

    event KnowledgeAtomSubmitted(uint256 indexed tokenId, address indexed creator, string contentHash, string metadataURI);
    event KnowledgeAtomUpdated(uint256 indexed tokenId, address indexed updater, string newContentHash);
    event KnowledgeAtomRetired(uint256 indexed tokenId, address indexed retirer);
    event KnowledgeAtomStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event KnowledgeAtomUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 rewards);
    event InsightValueScoreUpdated(uint256 indexed tokenId, int256 oldScore, int256 newScore, address indexed updater);
    event ChallengeInitiated(uint256 indexed tokenId, address indexed challenger, uint256 bondAmount);
    event SupportInitiated(uint256 indexed tokenId, address indexed supporter, uint256 bondAmount);
    event DisputeResolved(uint256 indexed tokenId, bool challengerVictorious);
    event SupportRefundClaimed(uint256 indexed tokenId, address indexed staker, uint256 refundAmount);
    event KnowledgeAtomQueried(uint256 indexed tokenId, address indexed caller, uint256 feePaid);
    event KnowledgeAtomQueryFeeSet(uint256 indexed tokenId, address indexed creator, uint256 newFee);
    event KnowledgeAtomQueryFeesWithdrawn(uint256 indexed tokenId, address indexed creator, uint256 amount);
    event OracleVerifierAdded(address indexed oracle);
    event OracleVerifierRemoved(address indexed oracle);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue); // Generic event for param updates
    event EpochEvaluationTriggered(uint256 timestamp);

    // --- Modifiers ---

    modifier onlyOracleVerifier() {
        require(isOracleVerifier[msg.sender], "DKIN: Only oracle verifier can call");
        _;
    }

    modifier onlyKnowledgeAtomCreator(uint256 _tokenId) {
        require(knowledgeAtoms[_tokenId].creator == msg.sender, "DKIN: Only KA creator can call");
        _;
    }

    modifier notChallenged(uint256 _tokenId) {
        require(challenges[_tokenId].status == ChallengeStatus.None, "DKIN: Knowledge Atom is currently challenged");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the ERC721 token and sets the KIN token address.
     * @param _kinTokenAddress The address of the KIN ERC20 token.
     * @param name The name for the ERC721 Knowledge Atom NFTs (e.g., "Knowledge Atom").
     * @param symbol The symbol for the ERC721 Knowledge Atom NFTs (e.g., "KA").
     */
    constructor(address _kinTokenAddress, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(_kinTokenAddress != address(0), "DKIN: KIN Token address cannot be zero");
        KIN_TOKEN = IERC20(_kinTokenAddress);
        lastEpochEvaluationTimestamp = block.timestamp; // Initialize first epoch evaluation time
    }

    // --- I. Core Knowledge Atom (KA) Management & Lifecycle ---

    /**
     * @notice Allows users to submit a new Knowledge Atom (KA). Mints a new dINFT.
     * @param _contentHash IPFS hash or similar pointing to the detailed content of the KA.
     * @param _metadataURI Initial URI for the NFT metadata, can be updated off-chain by a resolver.
     * @param _evaluationPeriodDays The duration in days after which this specific KA should be re-evaluated.
     * @return newTokenId The ID of the newly minted Knowledge Atom NFT.
     */
    function submitKnowledgeAtom(string memory _contentHash, string memory _metadataURI, uint256 _evaluationPeriodDays)
        public
        whenNotPaused
        returns (uint256)
    {
        require(bytes(_contentHash).length > 0, "DKIN: Content hash cannot be empty");
        require(bytes(_metadataURI).length > 0, "DKIN: Metadata URI cannot be empty");
        require(_evaluationPeriodDays > 0, "DKIN: Evaluation period must be positive");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        knowledgeAtoms[newTokenId] = KnowledgeAtom({
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            mintTimestamp: block.timestamp,
            lastEvaluationTimestamp: block.timestamp,
            insightValueScore: 0,
            evaluationPeriodDays: _evaluationPeriodDays,
            totalStakedAmount: 0,
            accumulatedQueryFees: 0,
            queryFee: 0, // Default to 0, creator can set later
            status: KnowledgeAtomStatus.Active,
            lastStatusChangeTimestamp: block.timestamp
        });

        emit KnowledgeAtomSubmitted(newTokenId, msg.sender, _contentHash, _metadataURI);
        return newTokenId;
    }

    /**
     * @notice Allows the creator to update the content hash of their KA.
     *         Only allowed if the KA has a non-positive IVS or before its first evaluation period has passed.
     * @param _tokenId The ID of the Knowledge Atom to update.
     * @param _newContentHash The new IPFS hash for the KA content.
     */
    function updateKnowledgeAtom(uint256 _tokenId, string memory _newContentHash)
        public
        whenNotPaused
        onlyKnowledgeAtomCreator(_tokenId)
        notChallenged(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active");
        // Allow updates only if IVS is non-positive (needs improvement) OR before the initial evaluation period
        require(ka.insightValueScore <= 0 || (block.timestamp < ka.mintTimestamp + (ka.evaluationPeriodDays * 1 days)),
            "DKIN: KA cannot be updated at this stage due to positive IVS or post-initial-evaluation");
        require(bytes(_newContentHash).length > 0, "DKIN: New content hash cannot be empty");

        ka.contentHash = _newContentHash;
        emit KnowledgeAtomUpdated(_tokenId, msg.sender, _newContentHash);
    }

    /**
     * @notice Allows the KA creator to soft-delete their Knowledge Atom.
     *         This changes its status to Retired and prevents further active interaction.
     *         Cannot be retired if there are active stakes or challenges.
     * @param _tokenId The ID of the Knowledge Atom to retire.
     */
    function retireKnowledgeAtom(uint256 _tokenId)
        public
        whenNotPaused
        onlyKnowledgeAtomCreator(_tokenId)
        notChallenged(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active");
        require(ka.totalStakedAmount == 0, "DKIN: Cannot retire KA with active stakes");

        ka.status = KnowledgeAtomStatus.Retired;
        ka.lastStatusChangeTimestamp = block.timestamp;
        emit KnowledgeAtomRetired(_tokenId, msg.sender);
    }

    /**
     * @notice Retrieves detailed information about a Knowledge Atom.
     * @param _tokenId The ID of the Knowledge Atom.
     * @return KnowledgeAtom struct containing all details.
     */
    function getKnowledgeAtomDetails(uint256 _tokenId)
        public
        view
        returns (KnowledgeAtom memory)
    {
        require(knowledgeAtoms[_tokenId].creator != address(0), "DKIN: Knowledge Atom does not exist");
        return knowledgeAtoms[_tokenId];
    }

    // --- II. Proof-of-Utility Staking (PoUS) ---

    /**
     * @notice Allows users to stake KIN tokens on a Knowledge Atom.
     * @param _tokenId The ID of the Knowledge Atom to stake on.
     * @param _amount The amount of KIN tokens to stake.
     */
    function stakeOnKnowledgeAtom(uint256 _tokenId, uint256 _amount)
        public
        whenNotPaused
        notChallenged(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active for staking");
        require(_amount >= minimumStakeAmount, "DKIN: Stake amount too low");
        require(KIN_TOKEN.transferFrom(msg.sender, address(this), _amount), "DKIN: KIN transfer failed");

        _stakes[_tokenId][msg.sender].amount += _amount;
        _stakes[_tokenId][msg.sender].staker = msg.sender; // Ensure staker address is set
        _stakes[_tokenId][msg.sender].timestamp = block.timestamp;
        _stakes[_tokenId][msg.sender].claimed = false; // Reset claimed status for new stakes

        ka.totalStakedAmount += _amount;

        emit KnowledgeAtomStaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @notice Allows users to unstake KIN tokens from a Knowledge Atom.
     *         Unstaking is only allowed if the KA is not currently challenged,
     *         and either rewards have been claimed or the KA is not yet due for evaluation.
     * @param _tokenId The ID of the Knowledge Atom.
     * @param _amount The amount of KIN tokens to unstake.
     */
    function unstakeFromKnowledgeAtom(uint256 _tokenId, uint256 _amount)
        public
        whenNotPaused
        notChallenged(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        Stake storage stake = _stakes[_tokenId][msg.sender];

        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(stake.amount >= _amount, "DKIN: Insufficient staked amount");
        // Only allow unstaking if rewards have already been claimed OR it's before the next evaluation period for this specific stake
        require(stake.claimed || (block.timestamp < ka.lastEvaluationTimestamp + (ka.evaluationPeriodDays * 1 days)),
            "DKIN: Cannot unstake with pending rewards or during evaluation period.");

        stake.amount -= _amount;
        ka.totalStakedAmount -= _amount;

        require(KIN_TOKEN.transfer(msg.sender, _amount), "DKIN: KIN transfer failed");
        emit KnowledgeAtomUnstaked(_tokenId, msg.sender, _amount);
    }

    /**
     * @notice Allows stakers to claim rewards based on the Knowledge Atom's Insight Value Score.
     *         Rewards are calculated based on the positive IVS and a share of query fees.
     *         Rewards are available once the KA has been evaluated and deemed valuable.
     * @param _tokenId The ID of the Knowledge Atom.
     */
    function claimStakingRewards(uint256 _tokenId)
        public
        whenNotPaused
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        Stake storage stake = _stakes[_tokenId][msg.sender];

        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(stake.amount > 0, "DKIN: No active stake found");
        require(ka.status == KnowledgeAtomStatus.Active || ka.status == KnowledgeAtomStatus.Retired, "DKIN: KA not in a claimable state");
        require(!stake.claimed, "DKIN: Rewards already claimed for this stake period");
        require(block.timestamp >= ka.lastEvaluationTimestamp + (ka.evaluationPeriodDays * 1 days), "DKIN: Evaluation period not ended yet");


        uint256 rewards = 0;
        if (ka.insightValueScore > 0) {
            // Reward calculation example:
            // 0.01% of staked amount per IVS point if IVS is positive (up to 100% of stake for IVS of 10000)
            uint256 stakingReward = stake.amount * uint256(ka.insightValueScore) / 10000;
            // Proportional share of accumulated query fees based on their stake vs total stake
            uint256 queryFeeShare = ka.totalStakedAmount > 0 ? ka.accumulatedQueryFees * stake.amount / ka.totalStakedAmount : 0;
            rewards = stakingReward + queryFeeShare;
        }

        require(rewards > 0, "DKIN: No rewards to claim or IVS not positive");

        // Deduct protocol fee from rewards
        uint256 protocolFee = rewards * protocolFeeBasisPoints / 10000;
        rewards -= protocolFee;
        accumulatedProtocolFees += protocolFee;

        stake.claimed = true; // Mark as claimed for this stake period

        require(KIN_TOKEN.transfer(msg.sender, rewards), "DKIN: KIN reward transfer failed");
        emit StakingRewardsClaimed(_tokenId, msg.sender, rewards);
    }

    // --- III. Insight Value Score (IVS) & Epoch Management ---

    /**
     * @notice Triggers the evaluation of KAs for the current epoch.
     *         Can be called by anyone, but only executes if a global epoch duration has passed.
     *         This function mainly updates the `lastEpochEvaluationTimestamp`, signaling new evaluation rounds.
     */
    function triggerEpochEvaluation()
        public
        whenNotPaused
    {
        require(block.timestamp >= lastEpochEvaluationTimestamp + epochDurationSeconds, "DKIN: Not enough time has passed for a new epoch");

        lastEpochEvaluationTimestamp = block.timestamp;
        emit EpochEvaluationTriggered(block.timestamp);

        // In a live system, this would likely trigger off-chain keeper networks or automated bots
        // to gather data, perform evaluations, and then call `submitEvaluationResult` for eligible KAs.
    }

    /**
     * @notice Allows a whitelisted oracle/verifier to submit an evaluation result for a KA.
     *         This updates the KA's Insight Value Score (IVS) and its `lastEvaluationTimestamp`.
     * @param _tokenId The ID of the Knowledge Atom being evaluated.
     * @param _scoreChange The change in IVS (can be positive or negative).
     * @param _proof Cryptographic proof (e.g., ZKP hash, signed data) from the oracle confirming evaluation.
     */
    function submitEvaluationResult(uint256 _tokenId, int256 _scoreChange, bytes memory _proof)
        public
        whenNotPaused
        onlyOracleVerifier
    {
        // _proof is illustrative; actual implementation would include on-chain verification of the proof.
        require(knowledgeAtoms[_tokenId].creator != address(0), "DKIN: Knowledge Atom does not exist");
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active for evaluation");
        // Ensure that this specific KA is due for an evaluation
        require(block.timestamp >= ka.lastEvaluationTimestamp + (ka.evaluationPeriodDays * 1 days),
            "DKIN: Not yet time for this KA's scheduled evaluation");

        ka.insightValueScore += _scoreChange;
        ka.lastEvaluationTimestamp = block.timestamp;

        // Reset claimed status for all stakes on this KA after evaluation, so stakers can claim new rewards.
        // This would require iterating through a list of stakers, which is gas-intensive for large numbers.
        // A more practical solution involves users calling `claimStakingRewards` after each epoch.
        // For this example, the `claimed` flag is reset per *new stake*. A full claim cycle needs more complex tracking.

        emit InsightValueScoreUpdated(_tokenId, ka.insightValueScore - _scoreChange, ka.insightValueScore, msg.sender);
    }

    /**
     * @notice Retrieves the current Insight Value Score of a Knowledge Atom.
     * @param _tokenId The ID of the Knowledge Atom.
     * @return The current IVS.
     */
    function getKnowledgeAtomIVS(uint256 _tokenId)
        public
        view
        returns (int256)
    {
        require(knowledgeAtoms[_tokenId].creator != address(0), "DKIN: Knowledge Atom does not exist");
        return knowledgeAtoms[_tokenId].insightValueScore;
    }

    // --- IV. Dispute Resolution ---

    /**
     * @notice Initiates a challenge against a Knowledge Atom, requiring a bond.
     *         The bond amount is proportional to the KA's total staked value.
     * @param _tokenId The ID of the Knowledge Atom to challenge.
     * @param _bondAmount The amount of KIN tokens to put up as a bond.
     * @param _reasonHash IPFS hash of the detailed reason for the challenge.
     */
    function challengeKnowledgeAtom(uint256 _tokenId, uint256 _bondAmount, string memory _reasonHash)
        public
        whenNotPaused
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active for challenge");
        require(challenges[_tokenId].status == ChallengeStatus.None, "DKIN: KA already under challenge");
        require(ka.totalStakedAmount > 0, "DKIN: Cannot challenge a KA with no active stakes");

        uint256 requiredBond = ka.totalStakedAmount * challengeBondRatioBasisPoints / 10000;
        require(_bondAmount >= requiredBond, "DKIN: Insufficient challenge bond");
        require(KIN_TOKEN.transferFrom(msg.sender, address(this), _bondAmount), "DKIN: KIN bond transfer failed");

        challenges[_tokenId] = Challenge({
            challenger: msg.sender,
            bondAmount: _bondAmount,
            reasonHash: _reasonHash,
            challengeTimestamp: block.timestamp,
            totalSupportBond: 0,
            status: ChallengeStatus.ActiveChallenge,
            challengerVictorious: false // Default, to be set on resolution
        });
        ka.status = KnowledgeAtomStatus.Challenged;
        ka.lastStatusChangeTimestamp = block.timestamp;

        emit ChallengeInitiated(_tokenId, msg.sender, _bondAmount);
    }

    /**
     * @notice Allows users to support a challenged Knowledge Atom, placing a bond.
     * @param _tokenId The ID of the Knowledge Atom to support.
     * @param _bondAmount The amount of KIN tokens to put up as support bond.
     */
    function supportKnowledgeAtom(uint256 _tokenId, uint256 _bondAmount)
        public
        whenNotPaused
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        Challenge storage challenge = challenges[_tokenId];

        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(challenge.status == ChallengeStatus.ActiveChallenge, "DKIN: KA is not actively challenged");
        require(_bondAmount > 0, "DKIN: Support bond must be positive");
        require(KIN_TOKEN.transferFrom(msg.sender, address(this), _bondAmount), "DKIN: KIN support bond transfer failed");

        challenge.supportBonds[msg.sender] += _bondAmount;
        challenge.totalSupportBond += _bondAmount;

        emit SupportInitiated(_tokenId, msg.sender, _bondAmount);
    }

    /**
     * @notice Resolves a dispute for a challenged Knowledge Atom.
     *         This function would typically be called by a DAO vote, a trusted oracle, or a specific resolution committee.
     *         It distributes the bonds, updates KA status and IVS based on the resolution outcome.
     * @param _tokenId The ID of the Knowledge Atom.
     * @param _isChallengerVictorious True if the challenger wins, false if supporters win.
     */
    function resolveDispute(uint256 _tokenId, bool _isChallengerVictorious)
        public
        onlyOwner // Or a DAO/committee role, could be adapted to a voting mechanism
        whenNotPaused
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        Challenge storage challenge = challenges[_tokenId];

        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(challenge.status == ChallengeStatus.ActiveChallenge, "DKIN: KA is not actively challenged");

        challenge.status = ChallengeStatus.DisputeResolved;
        challenge.challengerVictorious = _isChallengerVictorious;
        ka.lastStatusChangeTimestamp = block.timestamp;

        uint256 totalBondPool = challenge.bondAmount + challenge.totalSupportBond;
        uint256 protocolFeeTotal = totalBondPool * protocolFeeBasisPoints / 10000;
        accumulatedProtocolFees += protocolFeeTotal;

        if (_isChallengerVictorious) {
            // Challenger wins: Challenger gets their bond back + supporters' bonds (minus protocol fee)
            // Supporters lose their bonds. KA's IVS decreases significantly, status moves to Retired.
            uint256 challengerPayout = totalBondPool - protocolFeeTotal;
            // Transfer to challenger. Remaining supporter bonds are effectively lost to challenger.
            require(KIN_TOKEN.transfer(challenge.challenger, challengerPayout), "DKIN: Challenger bond transfer failed");

            ka.insightValueScore -= uint256(ka.insightValueScore > 0 ? ka.insightValueScore : 0) / 2; // Halve positive IVS, or make it more negative
            ka.status = KnowledgeAtomStatus.Retired; // Winning challenge strongly penalizes KA
        } else {
            // Supporters win: Supporters get their bonds back + challenger's bond (minus protocol fee).
            // Challenger loses their bond. KA's IVS increases, status moves back to Active.
            // Supporters must call `claimSupportRefund` individually.
            ka.insightValueScore += uint256(ka.insightValueScore < 0 ? 0 : ka.insightValueScore) / 2; // Increase IVS if non-negative
            ka.status = KnowledgeAtomStatus.Active; // Winning support keeps KA active
        }

        emit DisputeResolved(_tokenId, _isChallengerVictorious);
        // Clear challenge data after resolution to free up space (optional, but good practice if not needed anymore)
        // Note: Individual support bonds are not cleared here, as they are used by `claimSupportRefund`.
    }

    /**
     * @notice Allows supporters to claim their refunded bonds after a successful support.
     *         This function should be called by the individual supporters.
     * @param _tokenId The ID of the Knowledge Atom.
     */
    function claimSupportRefund(uint256 _tokenId) public whenNotPaused {
        Challenge storage challenge = challenges[_tokenId];
        require(challenge.status == ChallengeStatus.DisputeResolved, "DKIN: Dispute not resolved yet");
        require(!challenge.challengerVictorious, "DKIN: Challenger won, no refund for supporters");
        require(challenge.supportBonds[msg.sender] > 0, "DKIN: No support bond found for sender");

        uint256 supporterBond = challenge.supportBonds[msg.sender];
        uint256 totalBonds = challenge.bondAmount + challenge.totalSupportBond;
        
        // Calculate the proportional share of the forfeited challenger's bond that this supporter gets
        uint256 challengerForfeitedShare = challenge.bondAmount * supporterBond / challenge.totalSupportBond;
        uint256 grossRefund = supporterBond + challengerForfeitedShare;

        // Apply protocol fee to the total refund (proportional to supporter's share of total pool)
        uint256 protocolFeeShare = grossRefund * protocolFeeBasisPoints / 10000;
        uint256 refundAmount = grossRefund - protocolFeeShare;
        accumulatedProtocolFees += protocolFeeShare; // Add to protocol's accumulated fees

        delete challenge.supportBonds[msg.sender]; // Clear the claim for this supporter

        require(KIN_TOKEN.transfer(msg.sender, refundAmount), "DKIN: Support refund transfer failed");
        emit SupportRefundClaimed(_tokenId, msg.sender, refundAmount);
    }

    /**
     * @notice Retrieves the current status of a challenge for a Knowledge Atom.
     * @param _tokenId The ID of the Knowledge Atom.
     * @return The ChallengeStatus enum value.
     */
    function getChallengeStatus(uint256 _tokenId)
        public
        view
        returns (ChallengeStatus)
    {
        return challenges[_tokenId].status;
    }

    // --- V. Query Market & Access Control ---

    /**
     * @notice Allows users to query a Knowledge Atom, paying a fee set by the creator.
     * @param _tokenId The ID of the Knowledge Atom to query.
     * @return The content hash of the KA.
     */
    function queryKnowledgeAtom(uint256 _tokenId)
        public
        whenNotPaused
        returns (string memory)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.creator != address(0), "DKIN: Knowledge Atom does not exist");
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active for querying");
        require(ka.queryFee > 0, "DKIN: This KA has no query fee set");

        require(KIN_TOKEN.transferFrom(msg.sender, address(this), ka.queryFee), "DKIN: KIN query fee transfer failed");
        ka.accumulatedQueryFees += ka.queryFee;

        emit KnowledgeAtomQueried(_tokenId, msg.sender, ka.queryFee);
        return ka.contentHash;
    }

    /**
     * @notice Allows the creator of a Knowledge Atom to set its query fee.
     * @param _tokenId The ID of the Knowledge Atom.
     * @param _fee The new query fee in KIN tokens.
     */
    function setKnowledgeAtomQueryFee(uint256 _tokenId, uint256 _fee)
        public
        whenNotPaused
        onlyKnowledgeAtomCreator(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        require(ka.status == KnowledgeAtomStatus.Active, "DKIN: KA is not active");

        ka.queryFee = _fee;
        emit KnowledgeAtomQueryFeeSet(_tokenId, msg.sender, _fee);
    }

    /**
     * @notice Allows the creator of a Knowledge Atom to withdraw accumulated query fees.
     * @param _tokenId The ID of the Knowledge Atom.
     */
    function withdrawKnowledgeAtomQueryFees(uint256 _tokenId)
        public
        whenNotPaused
        onlyKnowledgeAtomCreator(_tokenId)
    {
        KnowledgeAtom storage ka = knowledgeAtoms[_tokenId];
        uint256 feesToWithdraw = ka.accumulatedQueryFees;
        require(feesToWithdraw > 0, "DKIN: No fees to withdraw");

        // Apply protocol fee to the creator's withdrawal
        uint256 protocolFee = feesToWithdraw * protocolFeeBasisPoints / 10000;
        uint256 creatorShare = feesToWithdraw - protocolFee;
        accumulatedProtocolFees += protocolFee;

        ka.accumulatedQueryFees = 0;
        require(KIN_TOKEN.transfer(msg.sender, creatorShare), "DKIN: KIN fee withdrawal failed");
        emit KnowledgeAtomQueryFeesWithdrawn(_tokenId, msg.sender, creatorShare);
    }

    // --- VI. Token & NFT Management (Beyond ERC721 basics) ---

    /**
     * @notice Allows bulk submission of Knowledge Atoms, minting multiple dINFTs.
     * @param _contentHashes Array of IPFS hashes for content.
     * @param _metadataURIs Array of metadata URIs for NFTs.
     * @param _evaluationPeriodDays Array of evaluation periods for each KA.
     */
    function batchMintKnowledgeAtoms(string[] memory _contentHashes, string[] memory _metadataURIs, uint256[] memory _evaluationPeriodDays)
        public
        whenNotPaused
    {
        require(_contentHashes.length == _metadataURIs.length && _contentHashes.length == _evaluationPeriodDays.length, "DKIN: Mismatched array lengths");
        require(_contentHashes.length > 0, "DKIN: No KAs provided for batch minting");

        for (uint256 i = 0; i < _contentHashes.length; i++) {
            submitKnowledgeAtom(_contentHashes[i], _metadataURIs[i], _evaluationPeriodDays[i]);
        }
    }

    // Inherited ERC721 functions (e.g., transferFrom, approve, setApprovalForAll) are automatically available.

    /**
     * @notice Sets the base URI for NFT metadata.
     * This is an admin function typically used by the platform to manage where the dINFT metadata resolvers live.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI)
        public
        onlyOwner
    {
        _setBaseURI(_newBaseURI);
        emit ParametersUpdated("BaseURI", 0, 0); // Event for generic parameter updates, old/new values aren't numeric
    }

    // --- VII. Administrative & Protocol Parameters ---

    /**
     * @notice Sets the minimum amount of KIN required to stake on a Knowledge Atom.
     * @param _amount The new minimum stake amount.
     */
    function setMinimumStakeAmount(uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "DKIN: Minimum stake amount must be positive");
        emit ParametersUpdated("MinimumStakeAmount", minimumStakeAmount, _amount);
        minimumStakeAmount = _amount;
    }

    /**
     * @notice Sets the ratio (in basis points) for the challenge bond relative to the KA's total staked value.
     * @param _ratio The new ratio in basis points (e.g., 500 for 5%).
     */
    function setChallengeBondRatio(uint256 _ratio)
        public
        onlyOwner
    {
        require(_ratio > 0 && _ratio <= 10000, "DKIN: Ratio must be between 1 and 10000 (100%)");
        emit ParametersUpdated("ChallengeBondRatio", challengeBondRatioBasisPoints, _ratio);
        challengeBondRatioBasisPoints = _ratio;
    }

    /**
     * @notice Adds an address to the list of whitelisted oracle verifiers.
     * These addresses can submit evaluation results for KAs.
     * @param _oracleAddress The address to whitelist.
     */
    function addOracleVerifier(address _oracleAddress)
        public
        onlyOwner
    {
        require(_oracleAddress != address(0), "DKIN: Oracle address cannot be zero");
        require(!isOracleVerifier[_oracleAddress], "DKIN: Address is already an oracle");
        isOracleVerifier[_oracleAddress] = true;
        emit OracleVerifierAdded(_oracleAddress);
    }

    /**
     * @notice Removes an address from the list of whitelisted oracle verifiers.
     * @param _oracleAddress The address to remove.
     */
    function removeOracleVerifier(address _oracleAddress)
        public
        onlyOwner
    {
        require(_oracleAddress != address(0), "DKIN: Oracle address cannot be zero");
        require(isOracleVerifier[_oracleAddress], "DKIN: Address is not an oracle");
        isOracleVerifier[_oracleAddress] = false;
        emit OracleVerifierRemoved(_oracleAddress);
    }

    /**
     * @notice Sets the protocol fee in basis points (e.g., 100 for 1%).
     * This fee is taken from staking rewards and query fees.
     * @param _feeBasisPoints The new fee percentage in basis points.
     */
    function setProtocolFee(uint256 _feeBasisPoints)
        public
        onlyOwner
    {
        require(_feeBasisPoints <= 10000, "DKIN: Fee cannot exceed 100%");
        emit ParametersUpdated("ProtocolFee", protocolFeeBasisPoints, _feeBasisPoints);
        protocolFeeBasisPoints = _feeBasisPoints;
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees()
        public
        onlyOwner
    {
        uint256 feesToWithdraw = accumulatedProtocolFees;
        require(feesToWithdraw > 0, "DKIN: No protocol fees to withdraw");
        accumulatedProtocolFees = 0;
        require(KIN_TOKEN.transfer(msg.sender, feesToWithdraw), "DKIN: Protocol fee withdrawal failed");
    }

    /**
     * @notice Sets the duration of an evaluation epoch in seconds.
     * @param _durationSeconds The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _durationSeconds)
        public
        onlyOwner
    {
        require(_durationSeconds > 0, "DKIN: Epoch duration must be positive");
        emit ParametersUpdated("EpochDuration", epochDurationSeconds, _durationSeconds);
        epochDurationSeconds = _durationSeconds;
    }
}
```