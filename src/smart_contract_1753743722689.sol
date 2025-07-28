The `AethermindCollective` smart contract provides a decentralized platform for fostering AI innovation, knowledge curation, and model monetization through a unique combination of dynamic NFTs, reputation systems, and adaptive governance. It aims to create a public good for AI models while ensuring contributors are rewarded and the community retains control.

## Outline: AethermindCollective - Decentralized AI Knowledge & Model Collective
================================================================================

This smart contract orchestrates a decentralized autonomous organization (DAO) focused on curating, validating, and monetizing collective AI knowledge and models. It aims to foster a meritocratic AI community by rewarding high-quality contributions and enabling public access to validated AI models.

**Core Components:**
1.  **AETHER Token (ERC20):** The native utility and governance token.
2.  **Knowledge Capsules (Dynamic ERC-721):** Represent AI models, datasets, or knowledge units. Their metadata dynamically updates based on performance validated off-chain.
3.  **Soulbound Knowledge NFTs (SKNs - Non-Transferable ERC-721):** Permanent badges of expertise and achievement, reflecting a user's indelible contributions.
4.  **WisdomScore:** A dynamic, non-transferable reputation score reflecting a user's contribution quality, model performance, and participation within the collective. This score directly influences voting power and reward multipliers.
5.  **Staked Inference Pools:** Users stake AETHER tokens to "sponsor" a Knowledge Capsule's inference requests, earning a share of usage fees. This aligns economic incentives with model utility.
6.  **Adaptive Governance:** The DAO can vote to dynamically adjust its own core protocol parameters (e.g., proposal thresholds, reward multipliers) based on community needs and system performance, enabling self-optimization.
7.  **Off-chain Oracle Integration:** Essential for feeding AI model performance metrics and successful inference execution feedback back onto the blockchain, ensuring data integrity and real-world relevance.
8.  **ZK-Proof Attestation Interface:** A mechanism to submit and verify (conceptually, off-chain) zero-knowledge proofs related to AI model properties (e.g., proving accuracy without revealing training data) or computational integrity.

## Function Summary:
=================

**I. Admin & Protocol Management:**
-   `constructor(address initialOwner, address aetherTokenAddress_)`: Initializes the contract, sets the AETHER token address, and assigns initial ownership.
-   `setProtocolFeeRecipient(address _newRecipient)`: Allows the contract owner (or DAO after transfer) to set the address for receiving protocol fees.
-   `pause()`: Pauses certain contract functionalities in an emergency. Callable by owner/DAO.
-   `unpause()`: Unpauses the contract. Callable by owner/DAO.
-   `withdrawProtocolFees()`: Allows the protocol fee recipient to withdraw accumulated protocol fees.

**II. WisdomScore (Reputation System):**
-   `getWisdomScore(address _user)`: Returns the current WisdomScore of a given user, reflecting their reputation.

**III. Knowledge Capsules (Dynamic AI-NFTs - ERC-721):**
-   `createKnowledgeCapsule(string calldata _modelURI, bytes32 _metadataHash, uint256 _creationStake)`: Mints a new Knowledge Capsule NFT. Requires a staked amount of AETHER, which also boosts the creator's WisdomScore.
-   `updateKnowledgeCapsuleURI(uint256 _capsuleId, string calldata _newURI)`: Allows the capsule owner to update its URI (e.g., after model updates or performance improvements), enabling dynamic NFT characteristics.
-   `submitKnowledgeProof(uint256 _capsuleId, bytes32 _proofHash, string calldata _proofType)`: Provides an interface for submitting a hash of an off-chain ZK-proof (e.g., model accuracy, data privacy). This can trigger internal logic for score updates or capsule status changes after validation.
-   `attestKnowledgePerformance(uint256 _capsuleId, uint256 _performanceScore, bytes32 _oracleSignature)`: A trusted oracle callback function to submit validated performance scores for a Knowledge Capsule, dynamically updating its state and impacting the owner's WisdomScore.
-   `getKnowledgeCapsuleDetails(uint256 _capsuleId)`: Retrieves comprehensive details about a specific Knowledge Capsule.

**IV. Staked Inference Pools & Monetization:**
-   `stakeForInference(uint256 _capsuleId, uint256 _amount)`: Allows users to stake AETHER tokens to a Knowledge Capsule's inference pool, earning a proportional share of future inference fees.
-   `unstakeFromInference(uint256 _capsuleId, uint256 _amount)`: Allows stakers to withdraw their AETHER from an inference pool.
-   `requestInferenceFee(uint256 _capsuleId)`: Returns the calculated AETHER fee required for an inference request for a given capsule.
-   `recordInferenceSuccess(uint256 _capsuleId, address _caller, uint256 _feePaid, bytes32 _oracleSignature)`: Callback for trusted oracles to confirm a successful off-chain inference and the fee paid, distributing fees to stakers and the protocol.
-   `claimStakedInferenceRewards(uint256 _capsuleId)`: Allows stakers to claim their accumulated rewards from a capsule's inference pool.

**V. Governance (Adaptive & Reputation-Weighted):**
-   `submitProposal(string calldata _description, address _target, bytes calldata _callData, uint256 _value, uint256 _minWisdomScore)`: Initiates a new governance proposal. Requires a minimum WisdomScore for the proposer.
-   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on a proposal. Voting power is weighted by AETHER token balance and WisdomScore.
-   `executeProposal(uint256 _proposalId)`: Executes an approved and passed governance proposal.
-   `updateGovernanceParameter(bytes32 _paramName, uint256 _newValue)`: A special function designed to be called by the DAO via an `executeProposal` to dynamically update core protocol parameters.

**VI. Soulbound Knowledge NFTs (SKNs - Non-Transferable ERC-721):**
-   `awardSKN(address _recipient, string calldata _metadataURI)`: Awards a Soulbound Knowledge NFT to a recipient for notable contributions or achievements. Callable only by governance.
-   `getSKNCount(address _owner)`: Returns the number of SKNs held by a specific address.
-   `hasSKN(address _owner, uint256 _sknId)`: Checks if a specific address holds a given SKN.

**VII. Off-chain Integration & Oracles:**
-   `setTrustedOracle(address _oracleAddress, bool _trusted)`: Allows governance to add or remove trusted oracle addresses, controlling who can submit validated off-chain data.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for external contracts (assuming OpenZeppelin for standard ERCs)
// IKcToken interface for Knowledge Capsules, leveraging standard ERC721
interface IKcToken is ERC721 {}

// ISknToken interface for Soulbound Knowledge NFTs, leveraging standard ERC721
// The non-transferability aspect is enforced conceptually by how this contract interacts with it,
// and would ideally be enforced by a custom ERC721 implementation overriding transfer logic.
interface ISknToken is ERC721 {}

contract AethermindCollective is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // AETHER Token (ERC20)
    IERC20 public immutable AETHER_TOKEN;

    // Knowledge Capsules (Dynamic NFTs)
    IKcToken public immutable knowledgeCapsules;
    Counters.Counter private _capsuleIds;

    struct KnowledgeCapsule {
        address owner;
        string modelURI; // IPFS/Arweave URI for model details & dynamic metadata
        bytes32 metadataHash; // Hash of initial metadata to ensure integrity
        uint256 creationTimestamp;
        uint256 lastPerformanceScore; // Dynamic: updated by oracles
        uint256 totalStakedForInference; // Current total AETHER staked in its pool
        uint256 rewardPerShareAccumulated; // Tracks accumulated rewards per unit of stake (scaled by 1e18)
        mapping(address => uint256) stakedAmounts; // Current staked AETHER by address
        mapping(address => uint256) rewardDebt; // (stakedAmount * rewardPerShareAccumulated) / 1e18 for a staker at their last interaction
    }
    mapping(uint256 => KnowledgeCapsule) public s_knowledgeCapsules; // capsuleId => KnowledgeCapsule
    mapping(uint256 => mapping(address => uint256)) public s_claimableRewards; // capsuleId => stakerAddress => claimable_rewards

    // Soulbound Knowledge NFTs (SKNs)
    ISknToken public immutable soulboundKnowledgeNFTs;
    Counters.Counter private _sknIds;

    // WisdomScore (Reputation)
    mapping(address => uint256) public s_wisdomScores; // user => score

    // Governance
    struct Proposal {
        string description;
        address target;
        bytes callData; // Encoded function call data for the target contract
        uint256 value; // ETH value to send with the call (if any)
        uint256 creationTimestamp;
        uint256 endTimestamp;
        uint256 yayVotes; // Weighted votes
        uint256 nayVotes; // Weighted votes
        bool executed;
        bool exists; // To check if proposalId is valid
        uint256 minWisdomScore; // Minimum WisdomScore required for proposal submission
        mapping(address => bool) hasVoted; // User has voted on this proposal
    }
    mapping(uint256 => Proposal) public s_proposals;
    Counters.Counter private _proposalIds;

    // Adaptive Governance Parameters (modifiable by DAO)
    mapping(bytes32 => uint256) public s_governanceParameters; // parameterHash => value

    // Oracles
    mapping(address => bool) public s_trustedOracles;

    // Protocol Fees
    address public s_protocolFeeRecipient;
    uint256 public s_protocolFeeAccumulated;

    // Pausability
    bool public s_paused;

    // --- Events ---
    event ProtocolFeeRecipientSet(address indexed _newRecipient);
    event ProtocolFeesWithdrawn(address indexed _recipient, uint256 _amount);
    event Paused(address indexed _caller);
    event Unpaused(address indexed _caller);

    event WisdomScoreUpdated(address indexed _user, uint256 _newScore);

    event KnowledgeCapsuleCreated(uint256 indexed _capsuleId, address indexed _owner, string _modelURI);
    event KnowledgeCapsuleURIUpdated(uint256 indexed _capsuleId, string _newURI);
    event KnowledgeProofSubmitted(uint256 indexed _capsuleId, bytes32 _proofHash, string _proofType);
    event KnowledgePerformanceAttested(uint256 indexed _capsuleId, uint256 _performanceScore);

    event StakedForInference(uint256 indexed _capsuleId, address indexed _staker, uint256 _amount);
    event UnstakedFromInference(uint256 indexed _capsuleId, address indexed _staker, uint256 _amount);
    event InferenceSuccessRecorded(uint256 indexed _capsuleId, address indexed _caller, uint256 _feePaid);
    event StakedInferenceRewardsClaimed(uint256 indexed _capsuleId, address indexed _staker, uint256 _amount);

    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, string _description);
    event ProposalVoted(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _weight);
    event ProposalExecuted(uint256 indexed _proposalId);
    event GovernanceParameterUpdated(bytes32 _paramName, uint256 _newValue);

    event SKNAwarded(uint256 indexed _sknId, address indexed _recipient, string _metadataURI);

    event TrustedOracleSet(address indexed _oracleAddress, bool _trusted);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!s_paused, "Pausable: paused");
        _;
    }

    modifier onlyTrustedOracle() {
        require(s_trustedOracles[msg.sender], "Oracle: not trusted");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner, address aetherTokenAddress_) Ownable(initialOwner) {
        AETHER_TOKEN = IERC20(aetherTokenAddress_);

        // Deploy Knowledge Capsules and SKN ERC721 contracts directly for this example.
        // In a real scenario, these would be deployed beforehand or as part of a more complex factory/deployment pattern.
        knowledgeCapsules = new ERC721("Knowledge Capsule", "KC");
        soulboundKnowledgeNFTs = new ERC721("Soulbound Knowledge NFT", "SKN");

        s_protocolFeeRecipient = initialOwner; // Initial recipient
        s_paused = false;

        // Initialize governance parameters
        s_governanceParameters["PROPOSAL_DURATION"] = 7 days; // Default 7 days
        s_governanceParameters["MIN_PROPOSAL_WISDOM_SCORE"] = 100; // Default minimum score to propose
        s_governanceParameters["PROTOCOL_INFERENCE_FEE_BPS"] = 1000; // 10% (1000 basis points)
        s_governanceParameters["KC_CREATION_WISDOM_BOOST"] = 50; // WisdomScore boost for creating a KC
        s_governanceParameters["SKN_AWARD_WISDOM_BOOST"] = 200; // WisdomScore boost for receiving an SKN
        s_governanceParameters["PERFORMANCE_WISDOM_BOOST_MULTIPLIER"] = 1; // Multiplier for performance score -> wisdom score
        s_governanceParameters["INFERENCE_BASE_FEE"] = 1e17; // 0.1 AETHER (example)
    }

    // --- Admin & Protocol Management Functions ---

    /**
     * @notice Sets the address for the protocol fee recipient.
     * @param _newRecipient The new address to receive protocol fees.
     * Callable by owner (or DAO after ownership transfer).
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Recipient cannot be zero address");
        s_protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientSet(_newRecipient);
    }

    /**
     * @notice Pauses contract functions in case of emergency.
     * Callable by owner (or DAO after ownership transfer).
     */
    function pause() external onlyOwner {
        require(!s_paused, "Pausable: already paused");
        s_paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses contract functions.
     * Callable by owner (or DAO after ownership transfer).
     */
    function unpause() external onlyOwner {
        require(s_paused, "Pausable: not paused");
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Allows the protocol fee recipient to withdraw accumulated AETHER fees.
     */
    function withdrawProtocolFees() external {
        require(msg.sender == s_protocolFeeRecipient, "Caller is not the fee recipient");
        require(s_protocolFeeAccumulated > 0, "No fees to withdraw");

        uint256 amount = s_protocolFeeAccumulated;
        s_protocolFeeAccumulated = 0;
        AETHER_TOKEN.transfer(s_protocolFeeRecipient, amount);
        emit ProtocolFeesWithdrawn(s_protocolFeeRecipient, amount);
    }

    // --- Internal WisdomScore Management ---

    /**
     * @dev Internal function to update a user's WisdomScore.
     * @param _user The address of the user whose score is being updated.
     * @param _change The amount to change the score by (can be negative).
     */
    function _updateWisdomScore(address _user, int256 _change) internal {
        if (_change > 0) {
            s_wisdomScores[_user] += uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            s_wisdomScores[_user] = s_wisdomScores[_user] > absChange ? s_wisdomScores[_user] - absChange : 0;
        }
        emit WisdomScoreUpdated(_user, s_wisdomScores[_user]);
    }

    /**
     * @dev Internal function to calculate a user's effective voting power.
     * Combines AETHER token wallet balance and WisdomScore.
     * @param _user The address of the user.
     * @return The calculated voting power.
     */
    function _calculateVotingPower(address _user) internal view returns (uint256) {
        // Example: Voting power = (AETHER wallet balance / 1e18) + (WisdomScore / 10)
        // This can be adjusted to include staked amounts or be quadratic.
        return (AETHER_TOKEN.balanceOf(_user) / 1e18) + (s_wisdomScores[_user] / 10);
    }

    // --- WisdomScore (Reputation System) ---

    /**
     * @notice Returns the current WisdomScore of a given user.
     * @param _user The address of the user.
     * @return The WisdomScore of the user.
     */
    function getWisdomScore(address _user) external view returns (uint256) {
        return s_wisdomScores[_user];
    }

    // --- Knowledge Capsules (Dynamic AI-NFTs - ERC-721) ---

    /**
     * @notice Mints a new Knowledge Capsule NFT, representing an AI model or knowledge unit.
     * Requires a stake in AETHER tokens, which also boosts the creator's WisdomScore.
     * @param _modelURI IPFS/Arweave URI pointing to the model's details/metadata. This URI can be updated.
     * @param _metadataHash Hash of the model URI metadata to ensure integrity.
     * @param _creationStake The amount of AETHER tokens to stake for capsule creation.
     */
    function createKnowledgeCapsule(
        string calldata _modelURI,
        bytes32 _metadataHash,
        uint256 _creationStake
    ) external whenNotPaused nonReentrant {
        require(bytes(_modelURI).length > 0, "KC: Model URI cannot be empty");
        require(_creationStake > 0, "KC: Creation stake must be positive");
        AETHER_TOKEN.transferFrom(msg.sender, address(this), _creationStake);

        _capsuleIds.increment();
        uint256 newCapsuleId = _capsuleIds.current();

        s_knowledgeCapsules[newCapsuleId] = KnowledgeCapsule({
            owner: msg.sender,
            modelURI: _modelURI,
            metadataHash: _metadataHash,
            creationTimestamp: block.timestamp,
            lastPerformanceScore: 0,
            totalStakedForInference: _creationStake, // Initial stake
            rewardPerShareAccumulated: 0,
            stakedAmounts: new mapping(address => uint256),
            rewardDebt: new mapping(address => uint256)
        });
        s_knowledgeCapsules[newCapsuleId].stakedAmounts[msg.sender] = _creationStake;
        // The creator's initial stake contributes to their rewardDebt so they don't accrue rewards on their own stake immediately
        s_knowledgeCapsules[newCapsuleId].rewardDebt[msg.sender] = (s_knowledgeCapsules[newCapsuleId].stakedAmounts[msg.sender] * s_knowledgeCapsules[newCapsuleId].rewardPerShareAccumulated) / 1e18;


        knowledgeCapsules.safeMint(msg.sender, newCapsuleId); // Mints the ERC721 NFT
        _updateWisdomScore(msg.sender, int256(s_governanceParameters["KC_CREATION_WISDOM_BOOST"]));

        emit KnowledgeCapsuleCreated(newCapsuleId, msg.sender, _modelURI);
    }

    /**
     * @notice Allows the owner of a Knowledge Capsule to update its metadata URI.
     * This enables dynamic NFT characteristics, reflecting model updates, new versions, or performance improvements.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _newURI The new IPFS/Arweave URI.
     */
    function updateKnowledgeCapsuleURI(
        uint256 _capsuleId,
        string calldata _newURI
    ) external whenNotPaused {
        require(knowledgeCapsules.ownerOf(_capsuleId) == msg.sender, "KC: Not capsule owner");
        require(bytes(_newURI).length > 0, "KC: New URI cannot be empty");

        s_knowledgeCapsules[_capsuleId].modelURI = _newURI;
        // Optionally, update metadataHash if _newURI implies new metadata hash
        emit KnowledgeCapsuleURIUpdated(_capsuleId, _newURI);
    }

    /**
     * @notice Provides an interface for submitting a hash of an off-chain Zero-Knowledge Proof
     * related to a Knowledge Capsule (e.g., proving model accuracy without revealing data,
     * or proving a calculation was performed correctly).
     * The actual ZK-proof verification happens off-chain, and a trusted oracle might attest to its validity.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _proofHash The hash of the ZK-proof.
     * @param _proofType A string describing the type of proof (e.g., "accuracy", "privacy_compliance").
     */
    function submitKnowledgeProof(
        uint256 _capsuleId,
        bytes32 _proofHash,
        string calldata _proofType
    ) external whenNotPaused {
        require(s_knowledgeCapsules[_capsuleId].owner != address(0), "KC: Invalid capsule ID");
        // This function primarily records the submission.
        // Actual impact (e.g., WisdomScore boost, capsule status change) would likely
        // be triggered by a subsequent oracle attestation that validates the proof off-chain.
        emit KnowledgeProofSubmitted(_capsuleId, _proofHash, _proofType);
    }

    /**
     * @notice Callback function for trusted oracles to attest to the performance of a Knowledge Capsule.
     * This dynamically updates the capsule's `lastPerformanceScore` and can impact the owner's WisdomScore.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _performanceScore The validated performance score (e.g., accuracy, efficiency metric).
     * @param _oracleSignature Signature to verify the oracle's authenticity (handled by `onlyTrustedOracle` modifier).
     */
    function attestKnowledgePerformance(
        uint256 _capsuleId,
        uint256 _performanceScore,
        bytes32 _oracleSignature // Placeholder for oracle signature verification (or Chainlink request ID)
    ) external onlyTrustedOracle whenNotPaused {
        // In a real system, _oracleSignature would be verified against the data and oracle's key.
        require(s_knowledgeCapsules[_capsuleId].owner != address(0), "KC: Invalid capsule ID");

        s_knowledgeCapsules[_capsuleId].lastPerformanceScore = _performanceScore;
        // Adjust owner's WisdomScore based on performance
        _updateWisdomScore(
            s_knowledgeCapsules[_capsuleId].owner,
            int256(_performanceScore * s_governanceParameters["PERFORMANCE_WISDOM_BOOST_MULTIPLIER"])
        );
        emit KnowledgePerformanceAttested(_capsuleId, _performanceScore);
    }

    /**
     * @notice Retrieves detailed information about a specific Knowledge Capsule.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @return owner The address of the capsule's owner.
     * @return modelURI The IPFS/Arweave URI of the model.
     * @return metadataHash Hash of the model's metadata.
     * @return creationTimestamp When the capsule was created.
     * @return lastPerformanceScore The latest validated performance score.
     * @return totalStakedForInference Total AETHER currently staked in its pool.
     */
    function getKnowledgeCapsuleDetails(
        uint256 _capsuleId
    )
        external
        view
        returns (
            address owner,
            string memory modelURI,
            bytes32 metadataHash,
            uint256 creationTimestamp,
            uint256 lastPerformanceScore,
            uint256 totalStakedForInference
        )
    {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");

        return (
            kc.owner,
            kc.modelURI,
            kc.metadataHash,
            kc.creationTimestamp,
            kc.lastPerformanceScore,
            kc.totalStakedForInference
        );
    }

    // --- Staked Inference Pools & Monetization ---

    /**
     * @dev Internal helper to update a staker's reward debt and move pending rewards to claimable balance.
     * Called before any change to a user's staked amount or when rewards are distributed.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _staker The address of the staker.
     */
    function _updateRewardDebt(uint256 _capsuleId, address _staker) internal {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        uint256 staked = kc.stakedAmounts[_staker];
        uint256 currentRewardPerShare = kc.rewardPerShareAccumulated;
        uint256 rewardDebt = kc.rewardDebt[_staker];

        // If the user has a stake, calculate their pending rewards based on `rewardPerShareAccumulated` since their last interaction
        if (staked > 0) {
            uint256 pendingRewards = (staked * currentRewardPerShare) / 1e18 - rewardDebt;
            if (pendingRewards > 0) {
                s_claimableRewards[_capsuleId][_staker] += pendingRewards;
            }
        }
        // Update reward debt to current accumulated value
        kc.rewardDebt[_staker] = (staked * currentRewardPerShare) / 1e18;
    }

    /**
     * @notice Allows a user to stake AETHER tokens to a Knowledge Capsule's inference pool.
     * Stakers earn a share of the fees generated from inferences using that capsule.
     * @param _capsuleId The ID of the Knowledge Capsule to stake for.
     * @param _amount The amount of AETHER tokens to stake.
     */
    function stakeForInference(
        uint256 _capsuleId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");
        require(_amount > 0, "Stake: Amount must be positive");

        _updateRewardDebt(_capsuleId, msg.sender); // Calculate pending rewards for previous stake before new stake

        AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount);

        kc.stakedAmounts[msg.sender] += _amount;
        kc.totalStakedForInference += _amount;

        // Update reward debt after new stake to new total
        kc.rewardDebt[msg.sender] = (kc.stakedAmounts[msg.sender] * kc.rewardPerShareAccumulated) / 1e18;

        emit StakedForInference(_capsuleId, msg.sender, _amount);
    }

    /**
     * @notice Allows a staker to unstake AETHER tokens from a Knowledge Capsule's inference pool.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _amount The amount of AETHER tokens to unstake.
     */
    function unstakeFromInference(
        uint256 _capsuleId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");
        require(_amount > 0, "Unstake: Amount must be positive");
        require(kc.stakedAmounts[msg.sender] >= _amount, "Unstake: Insufficient staked amount");

        _updateRewardDebt(_capsuleId, msg.sender); // Calculate pending rewards for previous stake before unstake

        kc.stakedAmounts[msg.sender] -= _amount;
        kc.totalStakedForInference -= _amount;

        // Update reward debt after unstake to new total
        kc.rewardDebt[msg.sender] = (kc.stakedAmounts[msg.sender] * kc.rewardPerShareAccumulated) / 1e18;

        AETHER_TOKEN.transfer(msg.sender, _amount);
        emit UnstakedFromInference(_capsuleId, msg.sender, _amount);
    }

    /**
     * @notice Returns the calculated AETHER fee for an inference request for a given Knowledge Capsule.
     * This fee can be dynamic and set by governance parameters.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @return The required AETHER fee.
     */
    function requestInferenceFee(uint256 _capsuleId) external view returns (uint256) {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");
        return s_governanceParameters["INFERENCE_BASE_FEE"]; // Example: simple base fee
    }

    /**
     * @notice Callback for trusted oracles to confirm a successful off-chain inference execution
     * and the fee paid for it. This function distributes the fee to stakers and the protocol.
     * @param _capsuleId The ID of the Knowledge Capsule.
     * @param _caller The address that requested the inference off-chain.
     * @param _feePaid The actual AETHER fee paid for the inference.
     * @param _oracleSignature Signature to verify the oracle's authenticity.
     */
    function recordInferenceSuccess(
        uint256 _capsuleId,
        address _caller,
        uint256 _feePaid,
        bytes32 _oracleSignature // Placeholder for oracle signature verification (or Chainlink request ID)
    ) external onlyTrustedOracle whenNotPaused nonReentrant {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");
        require(_feePaid > 0, "Inference: Fee paid must be positive");

        // First, update all active stakers' reward debts to capture pending rewards before adding new revenue.
        // This is a simplification; in a real-world system, this is implicitly handled by the rewardPerShare logic,
        // as each staker's debt is updated when they interact.
        // For accurate per-block/per-interaction accrual, `rewardPerShareAccumulated` is updated.
        if (kc.totalStakedForInference > 0) {
            // Update rewardPerShare for all existing stakers by adding new revenue.
            // Scale by 1e18 for precision.
            uint256 revenueForStakers = _feePaid - (_feePaid * s_governanceParameters["PROTOCOL_INFERENCE_FEE_BPS"]) / 10000;
            kc.rewardPerShareAccumulated += (revenueForStakers * 1e18) / kc.totalStakedForInference;
        }

        // Calculate and accumulate protocol fee
        uint256 protocolFee = (_feePaid * s_governanceParameters["PROTOCOL_INFERENCE_FEE_BPS"]) / 10000;
        s_protocolFeeAccumulated += protocolFee;

        emit InferenceSuccessRecorded(_capsuleId, _caller, _feePaid);
    }

    /**
     * @notice Allows stakers to claim their accumulated rewards from a Knowledge Capsule's inference pool.
     * @param _capsuleId The ID of the Knowledge Capsule.
     */
    function claimStakedInferenceRewards(uint256 _capsuleId) external nonReentrant {
        KnowledgeCapsule storage kc = s_knowledgeCapsules[_capsuleId];
        require(kc.owner != address(0), "KC: Invalid capsule ID");

        _updateRewardDebt(_capsuleId, msg.sender); // Accrue any final pending rewards to claimable

        uint256 rewards = s_claimableRewards[_capsuleId][msg.sender];
        require(rewards > 0, "Rewards: No rewards to claim");

        s_claimableRewards[_capsuleId][msg.sender] = 0; // Reset claimable for this user

        AETHER_TOKEN.transfer(msg.sender, rewards);
        emit StakedInferenceRewardsClaimed(_capsuleId, msg.sender, rewards);
    }

    // --- Governance (Adaptive & Reputation-Weighted) ---

    /**
     * @notice Submits a new governance proposal.
     * @param _description A brief description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call data for the target contract.
     * @param _value The ETH value (if any) to send with the call.
     * @param _minWisdomScore The minimum WisdomScore required for this type of proposal to be considered.
     */
    function submitProposal(
        string calldata _description,
        address _target,
        bytes calldata _callData,
        uint256 _value,
        uint256 _minWisdomScore
    ) external whenNotPaused {
        require(bytes(_description).length > 0, "Proposal: Description cannot be empty");
        require(s_wisdomScores[msg.sender] >= _minWisdomScore, "Proposal: Insufficient WisdomScore");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        s_proposals[newProposalId] = Proposal({
            description: _description,
            target: _target,
            callData: _callData,
            value: _value,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp + s_governanceParameters["PROPOSAL_DURATION"],
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            exists: true,
            minWisdomScore: _minWisdomScore,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Allows a user to vote on an active proposal.
     * Voting power is weighted by the user's combined AETHER token wallet balance and WisdomScore.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yay' (support), false for 'nay' (oppose).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = s_proposals[_proposalId];
        require(proposal.exists, "Vote: Invalid proposal ID");
        require(block.timestamp <= proposal.endTimestamp, "Vote: Proposal has ended");
        require(!proposal.executed, "Vote: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Vote: Already voted on this proposal");

        uint256 votingPower = _calculateVotingPower(msg.sender);
        require(votingPower > 0, "Vote: No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yayVotes += votingPower;
        } else {
            proposal.nayVotes += votingPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a proposal if it has passed and the voting period has ended.
     * Anyone can call this function after the voting period has passed and conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = s_proposals[_proposalId];
        require(proposal.exists, "Execute: Invalid proposal ID");
        require(block.timestamp > proposal.endTimestamp, "Execute: Voting period not ended");
        require(!proposal.executed, "Execute: Proposal already executed");
        require(proposal.yayVotes > proposal.nayVotes, "Execute: Proposal not passed");
        // Add a minimum quorum requirement here if needed, e.g., require(proposal.yayVotes + proposal.nayVotes >= MIN_QUORUM, "Execute: Quorum not met");

        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "Execute: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice A special function that allows the DAO to update core governance parameters.
     * This function should only be callable via a successful governance proposal.
     * The `owner` of this contract should eventually be transferred to this contract itself (DAO self-ownership).
     * @param _paramName The name of the parameter to update (e.g., "PROPOSAL_DURATION").
     * @param _newValue The new value for the parameter.
     */
    function updateGovernanceParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        s_governanceParameters[_paramName] = _newValue;
        emit GovernanceParameterUpdated(_paramName, _newValue);
    }

    // --- Soulbound Knowledge NFTs (SKNs - Non-Transferable ERC-721) ---

    /**
     * @notice Awards a Soulbound Knowledge NFT (SKN) to a recipient for notable contributions or achievements.
     * SKNs are non-transferable, signifying personal merit. Callable only by governance (via executeProposal).
     * @param _recipient The address to award the SKN to.
     * @param _metadataURI IPFS/Arweave URI for the SKN's metadata (e.g., achievement details).
     */
    function awardSKN(address _recipient, string calldata _metadataURI) external onlyOwner {
        // This function is callable ONLY by the contract owner.
        // The intention is that the *owner* role will eventually be transferred to the DAO itself
        // (i.e., `transferOwnership(address(this))`).
        // Once owned by the DAO, the `executeProposal` function would call this via `_callData`.
        require(_recipient != address(0), "SKN: Recipient cannot be zero");
        require(bytes(_metadataURI).length > 0, "SKN: Metadata URI cannot be empty");

        _sknIds.increment();
        uint256 newSknId = _sknIds.current();

        soulboundKnowledgeNFTs.safeMint(_recipient, newSknId); // Mints the ERC721 NFT
        // The non-transferability is enforced conceptually or by a custom ERC721 implementation
        // that overrides `_beforeTokenTransfer` to always revert for SKNs.

        _updateWisdomScore(_recipient, int256(s_governanceParameters["SKN_AWARD_WISDOM_BOOST"]));
        emit SKNAwarded(newSknId, _recipient, _metadataURI);
    }

    /**
     * @notice Returns the total number of Soulbound Knowledge NFTs held by a specific address.
     * @param _owner The address to query.
     * @return The count of SKNs held by the owner.
     */
    function getSKNCount(address _owner) external view returns (uint256) {
        return soulboundKnowledgeNFTs.balanceOf(_owner);
    }

    /**
     * @notice Checks if a specific address holds a given Soulbound Knowledge NFT.
     * @param _owner The address to check.
     * @param _sknId The ID of the SKN to check for.
     * @return True if the owner holds the SKN, false otherwise.
     */
    function hasSKN(address _owner, uint256 _sknId) external view returns (bool) {
        return soulboundKnowledgeNFTs.ownerOf(_sknId) == _owner;
    }

    // --- Off-chain Integration & Oracles ---

    /**
     * @notice Sets the trust status of an oracle address.
     * Only trusted oracles can call functions like `attestKnowledgePerformance` and `recordInferenceSuccess`.
     * Callable only by governance (via executeProposal).
     * @param _oracleAddress The address of the oracle.
     * @param _trusted Whether the oracle should be trusted (true) or untrusted (false).
     */
    function setTrustedOracle(address _oracleAddress, bool _trusted) external onlyOwner {
        // Similar to `updateGovernanceParameter` and `awardSKN`, this should only be called by the DAO (owner).
        require(_oracleAddress != address(0), "Oracle: Address cannot be zero");
        s_trustedOracles[_oracleAddress] = _trusted;
        emit TrustedOracleSet(_oracleAddress, _trusted);
    }
}
```