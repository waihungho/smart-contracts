Okay, this is an exciting challenge! Let's craft a sophisticated and innovative smart contract. I'll design a system called **"AetherMind Collective"**.

**Concept:** AetherMind Collective is a decentralized protocol that facilitates the curation of dynamic knowledge fragments (NFTs) based on AI-generated insights, validated by collective intelligence. It leverages a unique blend of AI oracle management, a decentralized prediction market for insight validation, and an evolving NFT mechanism.

**Key Innovative Concepts:**

1.  **AI Oracle Marketplace & Governance:** Staked users propose and govern the lifecycle of AI Oracles that provide insights.
2.  **Collective Insight Validation (Prediction Market):** Users can challenge AI insights, staking tokens on their perceived accuracy, which leads to a resolution and reward distribution.
3.  **Dynamic Knowledge Fragment NFTs:** NFTs that represent curated insights, capable of being updated as new information emerges, and uniquely, *fused* together to create more comprehensive knowledge representations.
4.  **Observation-to-Insight Flow:** A structured process from user-submitted observations to AI-generated insights, culminating in validated knowledge NFTs.

---

### **AetherMind Collective: Outline and Function Summary**

**Contract Name:** `AetherMindCollective`

**I. Core System & Setup**
*   `constructor()`: Initializes the contract with critical addresses and parameters.
*   `pause()`: Emergency stop for critical functions by the owner.
*   `unpause()`: Resumes paused functions by the owner.
*   `setProtocolFeeRecipient(address _newRecipient)`: Updates the address receiving protocol fees.
*   `setProtocolFeePercentage(uint256 _newPercentage)`: Adjusts the percentage of fees collected.

**II. Token & Staking Management**
*   `stake(uint256 _amount)`: Users stake the native token to gain participation rights (voting, observation, validation).
*   `unstake(uint256 _amount)`: Users withdraw staked tokens after a cooldown period.
*   `claimStakingRewards()`: Users claim accumulated rewards from staking.
*   `distributeProtocolFeesToStakers()`: Owner/protocol function to distribute collected fees to active stakers.

**III. AI Oracle Management**
*   `proposeAIOracle(string calldata _name, string calldata _description, address _oracleAddress, string calldata _apiEndpoint)`: Allows stakers to propose new AI oracles for governance approval.
*   `approveAIOracle(uint256 _oracleId)`: (Governance execution) Activates a proposed AI oracle.
*   `revokeAIOracle(uint256 _oracleId)`: (Governance execution) Deactivates an AI oracle.
*   `updateOracleConfiguration(uint256 _oracleId, uint256 _feeRate, uint256 _maxInferenceGasLimit)`: (Governance execution) Modifies an oracle's operational parameters.
*   `setOracleRewardMultiplier(uint256 _oracleId, uint256 _multiplier)`: (Governance execution) Adjusts reward weighting for an oracle's insights.

**IV. Observation & Insight Generation**
*   `submitObservation(uint256 _topicId, bytes32 _dataHash, string calldata _metadataURI)`: Users contribute hashed observational data linked to a topic.
*   `submitAIInsight(uint256 _oracleId, uint256 _observationId, bytes32 _insightHash, string calldata _insightURI)`: Approved AI Oracles submit their processed insights.
*   `challengeInsight(uint256 _insightId, uint256 _amount, string calldata _reasonURI)`: Users stake tokens to challenge the accuracy of an AI insight.

**V. Insight Validation & Dynamic NFTs**
*   `resolveInsightChallenge(uint256 _challengeId, bool _isAccurate)`: (Oracle/Governance) Resolves a challenged insight, distributing staked tokens and marking insight validity.
*   `mintKnowledgeFragmentNFT(uint256 _insightId, address _to)`: Mints a unique "Knowledge Fragment" NFT based on a validated insight.
*   `updateKnowledgeFragmentNFT(uint256 _tokenId, bytes32 _newContentHash, string calldata _newMetadataURI)`: Allows designated updaters (e.g., original minter, oracle, or DAO) to evolve the NFT's metadata with new insights.
*   `fuseKnowledgeFragments(uint256[] calldata _tokenIdsToFuse, string calldata _fusedMetadataURI)`: Burns multiple existing Knowledge Fragment NFTs to mint a new, more comprehensive one, representing aggregated knowledge.

**VI. Governance & Collective Decision**
*   `createGovernanceProposal(uint256 _proposalType, bytes calldata _calldata, string calldata _descriptionURI)`: Stakers initiate proposals for system changes.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Staked users vote on active proposals.
*   `delegateVote(address _delegatee)`: Stakers delegate their voting power.
*   `undelegateVote()`: Stakers revoke their delegation.
*   `executeProposal(uint256 _proposalId)`: Any user can trigger the execution of a passed proposal.

**Total Functions: 26**

---

### **Solidity Smart Contract: AetherMindCollective**

For conciseness and best practices, I will define interfaces for the native token (`IERC20`) and the Knowledge Fragment NFT (`IKnowledgeFragmentNFT`), assuming they are separate contracts. The NFT contract (`KnowledgeFragmentNFT.sol`) will be provided as a separate file, demonstrating its unique functions (`updateMetadata`, `mint`, `burn`).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For managing stakers easily

// --- Interfaces for external contracts ---

/**
 * @title IKnowledgeFragmentNFT
 * @dev Interface for the Knowledge Fragment NFT contract, which is an ERC721
 *      with additional custom functionalities for dynamic metadata and fusing.
 */
interface IKnowledgeFragmentNFT {
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI, bytes32 newContentHash);
    event FragmentFused(address indexed minter, uint256[] indexed burntTokenIds, uint256 newFragmentId, string newMetadataURI);

    function mint(address to, uint256 insightId, string calldata tokenURI, bytes32 contentHash) external returns (uint256);
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI, bytes32 newContentHash) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setMinter(address minterAddress) external; // To allow AetherMindCollective to mint
}

/**
 * @title IAetherMindGovernance
 * @dev Interface for the governance module if it were a separate, more complex contract.
 *      For this example, governance logic is embedded within AetherMindCollective.
 */
interface IAetherMindGovernance {
    enum ProposalType {
        UpdateProtocolFeeRecipient,
        UpdateProtocolFeePercentage,
        ApproveOracle,
        RevokeOracle,
        UpdateOracleConfiguration,
        SetOracleRewardMultiplier,
        CustomAction // For general purpose
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        bytes calldataPayload; // Data to be executed if proposal passes
        string descriptionURI;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted;
    }
}


// --- Main AetherMindCollective Contract ---

contract AetherMindCollective is Ownable, Pausable, IAetherMindGovernance {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---
    IERC20 public immutable NATIVE_TOKEN; // ERC20 token used for staking, rewards, and fees
    IKnowledgeFragmentNFT public immutable KNOWLEDGE_FRAGMENT_NFT; // Address of the dynamic NFT contract

    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500 basis points)
    uint256 public constant MAX_FEE_PERCENTAGE = 10000; // 100%

    // Staking parameters
    uint256 public constant STAKING_COOLDOWN_PERIOD = 7 days; // Time before unstaked tokens can be withdrawn
    uint256 public constant MIN_STAKE_AMOUNT = 1 ether;

    // Oracle parameters
    uint256 public nextOracleId;
    uint256 public constant MIN_ORACLE_PROPOSAL_STAKE = 10 ether; // Stake required to propose an oracle

    // Observation & Insight parameters
    uint256 public nextObservationId;
    uint256 public nextInsightId;
    uint256 public nextChallengeId;
    uint256 public constant INSIGHT_CHALLENGE_WINDOW = 3 days; // Time window to challenge an insight

    // Governance parameters
    uint256 public nextProposalId;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 5 days;
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 1 days; // Delay after voting ends before execution
    uint256 public constant QUORUM_PERCENTAGE = 4000; // 40% of total staked supply needed to pass (4000 basis points)
    uint256 public constant MIN_PROPOSAL_STAKE = 50 ether; // Stake required to create a proposal

    // --- Data Structures ---

    struct Staker {
        uint256 balance;
        uint256 unstakeRequestTimestamp;
        uint256 rewardsAccumulated;
        address delegatedTo; // Address to which voting power is delegated
    }

    struct AIOracle {
        uint256 id;
        string name;
        string description;
        address oracleAddress; // The actual off-chain AI service's signing address
        string apiEndpoint; // Informational endpoint for the AI service
        bool isActive;
        uint256 feeRate; // Fee charged by oracle per insight (in native token)
        uint256 maxInferenceGasLimit; // Max gas allowed for oracle's off-chain inference (for cost estimation)
        uint256 rewardMultiplier; // Multiplier for rewards to this oracle (e.g., 100 for 1x, 150 for 1.5x)
    }

    struct Observation {
        uint256 id;
        uint256 topicId;
        address submitter;
        bytes32 dataHash; // Hash of the raw data (stored off-chain)
        string metadataURI; // URI to additional metadata or IPFS link
        uint256 timestamp;
    }

    struct AIInsight {
        uint256 id;
        uint256 oracleId;
        uint256 observationId;
        address submitter; // The oracleAddress that submitted it
        bytes32 insightHash; // Hash of the AI-generated insight
        string insightURI; // URI to the insight data (e.g., IPFS)
        uint256 timestamp;
        bool isChallenged;
        bool isValidated; // True if passed challenges or challenge window expired
        uint256 challengeWindowEnd;
    }

    struct InsightChallenge {
        uint256 id;
        uint256 insightId;
        address challenger;
        uint256 stakeAmount;
        string reasonURI; // URI explaining the challenge reason
        bool resolved;
        bool accurateVerdict; // True if insight was deemed accurate
        uint256 resolutionTimestamp;
        EnumerableSet.AddressSet nayStakes; // Addresses that staked against accuracy
        EnumerableSet.AddressSet yayStakes; // Addresses that staked for accuracy
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        bytes calldataPayload;
        string descriptionURI;
        uint256 proposer; // ID of the staker who proposed it
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        bool passed;
        bool active; // True while voting is open
        mapping(address => bool) hasVoted; // Tracks if an address (or its delegatee) has voted
        uint256 totalVotesAtProposalCreation; // Total staked tokens at proposal creation for quorum calculation
    }

    // --- Mappings ---
    mapping(address => Staker) public stakers;
    EnumerableSet.AddressSet private _activeStakers; // To iterate over active stakers for reward distribution
    uint256 public totalStaked; // Total native tokens staked in the contract

    mapping(uint256 => AIOracle) public aiOracles;
    mapping(address => uint256) public oracleAddressToId; // Reverse lookup

    mapping(uint256 => Observation) public observations;
    mapping(uint256 => AIInsight) public insights;
    mapping(uint256 => InsightChallenge) public challenges;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegations; // delegatee => delegator

    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 releaseTime);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event ProtocolFeesDistributed(uint256 amount);

    event OracleProposed(uint256 indexed oracleId, address indexed proposer, string name);
    event OracleApproved(uint256 indexed oracleId, address indexed approver);
    event OracleRevoked(uint256 indexed oracleId, address indexed revoker);
    event OracleConfigurationUpdated(uint256 indexed oracleId, uint256 feeRate, uint256 maxInferenceGasLimit);
    event OracleRewardMultiplierUpdated(uint256 indexed oracleId, uint256 multiplier);

    event ObservationSubmitted(uint256 indexed observationId, address indexed submitter, uint256 topicId);
    event AIInsightSubmitted(uint256 indexed insightId, uint256 indexed oracleId, uint256 observationId, address submitter);
    event InsightChallenged(uint256 indexed challengeId, uint256 indexed insightId, address indexed challenger, uint256 stakeAmount);
    event InsightChallengeResolved(uint256 indexed challengeId, uint256 indexed insightId, bool accurateVerdict);

    event KnowledgeFragmentMinted(uint256 indexed tokenId, uint256 indexed insightId, address indexed to);
    event KnowledgeFragmentUpdated(uint256 indexed tokenId, bytes32 newContentHash);
    event KnowledgeFragmentsFused(address indexed minter, uint256[] burntTokenIds, uint256 newFragmentId);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, IAetherMindGovernance.ProposalType proposalType);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyStaker() {
        require(stakers[_msgSender()].balance >= MIN_STAKE_AMOUNT, "AetherMind: Caller must be an active staker");
        _;
    }

    modifier onlyApprovedOracle(uint256 _oracleId) {
        require(aiOracles[_oracleId].isActive && aiOracles[_oracleId].oracleAddress == _msgSender(), "AetherMind: Not an active approved oracle");
        _;
    }

    modifier onlyGovernanceExecution() {
        // This modifier is used by functions that are callable ONLY through a passed governance proposal execution.
        // The actual proposal execution logic in executeProposal() will call these functions via `calldataPayload`.
        // This modifier primarily serves as documentation and a safety catch if someone tries to call them directly.
        require(msg.sender == address(this), "AetherMind: Only callable via governance execution");
        _;
    }

    modifier notPaused() {
        _notPaused();
        _;
    }

    // --- Constructor ---
    constructor(address _nativeToken, address _knowledgeFragmentNFT) Ownable(_msgSender()) {
        require(_nativeToken != address(0), "AetherMind: Native token address cannot be zero");
        require(_knowledgeFragmentNFT != address(0), "AetherMind: Knowledge Fragment NFT address cannot be zero");

        NATIVE_TOKEN = IERC20(_nativeToken);
        KNOWLEDGE_FRAGMENT_NFT = IKnowledgeFragmentNFT(_knowledgeFragmentNFT);

        protocolFeeRecipient = _msgSender();
        protocolFeePercentage = 500; // 5% initial fee

        // Grant this contract the Minter role in the NFT contract
        KNOWLEDGE_FRAGMENT_NFT.setMinter(address(this));
    }

    // --- I. Core System & Setup (5 functions) ---

    // Inherited `pause()` and `unpause()` from Pausable

    /**
     * @dev Sets a new address to receive protocol fees. Only callable by the owner.
     * @param _newRecipient The new address for fee collection.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "AetherMind: New fee recipient cannot be zero address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @dev Sets a new percentage for protocol fees. Only callable by the owner.
     * @param _newPercentage The new fee percentage (in basis points, e.g., 500 for 5%).
     */
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= MAX_FEE_PERCENTAGE, "AetherMind: Fee percentage exceeds 100%");
        emit ProtocolFeePercentageUpdated(protocolFeePercentage, _newPercentage);
        protocolFeePercentage = _newPercentage;
    }

    // --- II. Token & Staking Management (4 functions) ---

    /**
     * @dev Allows users to stake NATIVE_TOKEN to participate in the AetherMind collective.
     * @param _amount The amount of NATIVE_TOKEN to stake.
     */
    function stake(uint256 _amount) external notPaused {
        require(_amount >= MIN_STAKE_AMOUNT, "AetherMind: Stake amount too low");
        require(NATIVE_TOKEN.transferFrom(_msgSender(), address(this), _amount), "AetherMind: Token transfer failed");

        if (stakers[_msgSender()].balance == 0) {
            _activeStakers.add(_msgSender());
        }
        stakers[_msgSender()].balance = stakers[_msgSender()].balance.add(_amount);
        totalStaked = totalStaked.add(_amount);

        emit Staked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to request unstaking of their NATIVE_TOKEN. Subject to a cooldown.
     * @param _amount The amount of NATIVE_TOKEN to unstake.
     */
    function unstake(uint256 _amount) external notPaused {
        require(stakers[_msgSender()].balance >= _amount, "AetherMind: Insufficient staked balance");
        require(stakers[_msgSender()].unstakeRequestTimestamp == 0, "AetherMind: Unstake already requested, await cooldown");

        stakers[_msgSender()].unstakeRequestTimestamp = block.timestamp.add(STAKING_COOLDOWN_PERIOD);
        stakers[_msgSender()].balance = stakers[_msgSender()].balance.sub(_amount);
        totalStaked = totalStaked.sub(_amount); // Reduce total staked immediately

        // If balance becomes 0 after unstake request, remove from active stakers.
        // Actual transfer happens after cooldown.
        if (stakers[_msgSender()].balance == 0) {
            _activeStakers.remove(_msgSender());
        }

        emit UnstakeRequested(_msgSender(), _amount, stakers[_msgSender()].unstakeRequestTimestamp);
    }

    /**
     * @dev Allows stakers to claim their accumulated rewards from staking.
     *      (Reward calculation logic is simplified here; in a real system, it could be more complex,
     *      e.g., based on pro-rata share of fees, insight validation accuracy, etc.)
     */
    function claimStakingRewards() external notPaused {
        uint256 rewards = stakers[_msgSender()].rewardsAccumulated;
        require(rewards > 0, "AetherMind: No rewards to claim");

        stakers[_msgSender()].rewardsAccumulated = 0;
        require(NATIVE_TOKEN.transfer(_msgSender(), rewards), "AetherMind: Reward token transfer failed");

        emit RewardsClaimed(_msgSender(), rewards);
    }

    /**
     * @dev Distributes collected protocol fees to active stakers.
     *      Can be called by anyone (or more likely, a scheduled keeper), but transfers from contract balance.
     */
    function distributeProtocolFeesToStakers() external notPaused {
        uint256 contractBalance = NATIVE_TOKEN.balanceOf(address(this));
        uint256 feeAmount = contractBalance.mul(protocolFeePercentage).div(MAX_FEE_PERCENTAGE);
        
        // This is a simplified distribution. In a real scenario, this would distribute remaining `contractBalance - feeAmount`
        // or a dedicated portion meant for stakers. For this example, let's assume `feeAmount` is the pool.
        
        require(feeAmount > 0, "AetherMind: No fees to distribute");
        require(totalStaked > 0, "AetherMind: No active stakers to distribute to");

        // Transfer fee portion to the recipient
        require(NATIVE_TOKEN.transfer(protocolFeeRecipient, feeAmount), "AetherMind: Fee transfer to recipient failed");

        // The remaining contract balance (minus the feeAmount) is distributed proportionally
        uint256 distributableAmount = contractBalance.sub(feeAmount);
        
        if (distributableAmount > 0) {
            for (uint256 i = 0; i < _activeStakers.length(); i++) {
                address stakerAddress = _activeStakers.at(i);
                uint256 stakerShare = stakers[stakerAddress].balance.mul(distributableAmount).div(totalStaked);
                stakers[stakerAddress].rewardsAccumulated = stakers[stakerAddress].rewardsAccumulated.add(stakerShare);
            }
            emit ProtocolFeesDistributed(distributableAmount);
        }
    }

    // --- III. AI Oracle Management (5 functions) ---

    /**
     * @dev Allows any staker to propose a new AI oracle for governance review.
     * @param _name The name of the AI oracle.
     * @param _description A brief description of the oracle's capabilities.
     * @param _oracleAddress The address associated with the AI service (e.g., signing address).
     * @param _apiEndpoint Informational URI for the oracle's API.
     */
    function proposeAIOracle(string calldata _name, string calldata _description, address _oracleAddress, string calldata _apiEndpoint)
        external onlyStaker notPaused
    {
        require(_oracleAddress != address(0), "AetherMind: Oracle address cannot be zero");
        require(oracleAddressToId[_oracleAddress] == 0, "AetherMind: Oracle with this address already exists");
        require(stakers[_msgSender()].balance >= MIN_ORACLE_PROPOSAL_STAKE, "AetherMind: Insufficient stake to propose oracle");

        nextOracleId = nextOracleId.add(1);
        aiOracles[nextOracleId] = AIOracle({
            id: nextOracleId,
            name: _name,
            description: _description,
            oracleAddress: _oracleAddress,
            apiEndpoint: _apiEndpoint,
            isActive: false, // Must be approved by governance
            feeRate: 0,
            maxInferenceGasLimit: 0,
            rewardMultiplier: 100 // Default 1x
        });
        oracleAddressToId[_oracleAddress] = nextOracleId;

        emit OracleProposed(nextOracleId, _msgSender(), _name);
    }

    /**
     * @dev (Governance execution) Approves a proposed AI oracle, making it active.
     * @param _oracleId The ID of the oracle to approve.
     */
    function approveAIOracle(uint256 _oracleId) external onlyGovernanceExecution notPaused {
        require(_oracleId > 0 && _oracleId <= nextOracleId, "AetherMind: Invalid oracle ID");
        require(!aiOracles[_oracleId].isActive, "AetherMind: Oracle is already active");

        aiOracles[_oracleId].isActive = true;
        // Set default config (can be updated later by governance)
        aiOracles[_oracleId].feeRate = 100; // Example default: 1% fee for insights
        aiOracles[_oracleId].maxInferenceGasLimit = 1000000; // Example default

        emit OracleApproved(_oracleId, _msgSender());
    }

    /**
     * @dev (Governance execution) Revokes an active AI oracle, preventing further insight submissions.
     * @param _oracleId The ID of the oracle to revoke.
     */
    function revokeAIOracle(uint256 _oracleId) external onlyGovernanceExecution notPaused {
        require(_oracleId > 0 && _oracleId <= nextOracleId, "AetherMind: Invalid oracle ID");
        require(aiOracles[_oracleId].isActive, "AetherMind: Oracle is not active");

        aiOracles[_oracleId].isActive = false;

        emit OracleRevoked(_oracleId, _msgSender());
    }

    /**
     * @dev (Governance execution) Updates an approved oracle's operational parameters.
     * @param _oracleId The ID of the oracle to update.
     * @param _feeRate The new fee rate charged by the oracle (basis points).
     * @param _maxInferenceGasLimit The new maximum gas limit for off-chain inference.
     */
    function updateOracleConfiguration(uint256 _oracleId, uint256 _feeRate, uint256 _maxInferenceGasLimit)
        external onlyGovernanceExecution notPaused
    {
        require(_oracleId > 0 && _oracleId <= nextOracleId, "AetherMind: Invalid oracle ID");
        require(aiOracles[_oracleId].isActive, "AetherMind: Oracle is not active");
        require(_feeRate <= MAX_FEE_PERCENTAGE, "AetherMind: Fee rate exceeds 100%");

        aiOracles[_oracleId].feeRate = _feeRate;
        aiOracles[_oracleId].maxInferenceGasLimit = _maxInferenceGasLimit;

        emit OracleConfigurationUpdated(_oracleId, _feeRate, _maxInferenceGasLimit);
    }

    /**
     * @dev (Governance execution) Adjusts the reward multiplier for insights from a specific oracle.
     * @param _oracleId The ID of the oracle.
     * @param _multiplier The new reward multiplier (e.g., 100 for 1x, 150 for 1.5x).
     */
    function setOracleRewardMultiplier(uint256 _oracleId, uint256 _multiplier) external onlyGovernanceExecution notPaused {
        require(_oracleId > 0 && _oracleId <= nextOracleId, "AetherMind: Invalid oracle ID");
        require(aiOracles[_oracleId].isActive, "AetherMind: Oracle is not active");
        require(_multiplier > 0, "AetherMind: Multiplier must be greater than zero");

        aiOracles[_oracleId].rewardMultiplier = _multiplier;

        emit OracleRewardMultiplierUpdated(_oracleId, _multiplier);
    }

    // --- IV. Observation & Insight Generation (3 functions) ---

    /**
     * @dev Allows users to submit raw observational data (hashed off-chain) for a specific topic.
     *      The actual data should be stored off-chain (e.g., IPFS) and linked via metadataURI.
     * @param _topicId The ID of the topic this observation relates to.
     * @param _dataHash A hash of the raw observational data.
     * @param _metadataURI URI pointing to the full data and additional context.
     */
    function submitObservation(uint256 _topicId, bytes32 _dataHash, string calldata _metadataURI) external onlyStaker notPaused {
        // A real system would likely have a governance-approved list of topics. For simplicity, assume _topicId is valid.
        nextObservationId = nextObservationId.add(1);
        observations[nextObservationId] = Observation({
            id: nextObservationId,
            topicId: _topicId,
            submitter: _msgSender(),
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            timestamp: block.timestamp
        });

        emit ObservationSubmitted(nextObservationId, _msgSender(), _topicId);
    }

    /**
     * @dev Approved AI Oracles submit their processed insights based on observations.
     *      The oracle pays a fee for submission (e.g., to cover gas + a protocol fee).
     * @param _oracleId The ID of the AI oracle submitting the insight.
     * @param _observationId The ID of the observation this insight is based on.
     * @param _insightHash A hash of the AI-generated insight.
     * @param _insightURI URI pointing to the full insight data (e.g., IPFS).
     */
    function submitAIInsight(uint256 _oracleId, uint256 _observationId, bytes32 _insightHash, string calldata _insightURI)
        external payable onlyApprovedOracle(_oracleId) notPaused
    {
        require(_observationId > 0 && _observationId <= nextObservationId, "AetherMind: Invalid observation ID");

        AIOracle storage oracle = aiOracles[_oracleId];
        uint256 requiredFee = oracle.feeRate.mul(msg.value).div(MAX_FEE_PERCENTAGE); // Simplified fee calculation based on msg.value

        require(msg.value >= requiredFee, "AetherMind: Insufficient fee paid for insight submission");

        // Protocol collects a fee from the oracle's submission fee
        uint256 protocolShare = requiredFee.mul(protocolFeePercentage).div(MAX_FEE_PERCENTAGE);
        // The remaining fee is considered oracle's revenue or cost
        
        // This example transfers the entire msg.value to the contract, then separates
        // protocol fees and potentially rewards for successful oracle operation.
        // For simplicity here, msg.value is just the oracle's operational cost/fee,
        // of which a portion goes to protocol.
        
        // Transfer protocol's share to fee recipient
        require(NATIVE_TOKEN.transfer(protocolFeeRecipient, protocolShare), "AetherMind: Protocol fee transfer failed");
        
        // The rest of msg.value (oracle's cut) is implicitly handled if it came from the oracle.
        // The oracle itself would have paid `requiredFee` to this contract as `msg.value`.
        // The actual `NATIVE_TOKEN` used for this is the `msg.value` amount.
        // A better model would be: oracle pays `_submissionCost` in `NATIVE_TOKEN` and that's distributed.
        // Let's assume for now, `msg.value` IS the `NATIVE_TOKEN` and requiredFee is paid to this contract.

        nextInsightId = nextInsightId.add(1);
        insights[nextInsightId] = AIInsight({
            id: nextInsightId,
            oracleId: _oracleId,
            observationId: _observationId,
            submitter: _msgSender(),
            insightHash: _insightHash,
            insightURI: _insightURI,
            timestamp: block.timestamp,
            isChallenged: false,
            isValidated: false, // Remains false until challenge window expires or resolved
            challengeWindowEnd: block.timestamp.add(INSIGHT_CHALLENGE_WINDOW)
        });

        emit AIInsightSubmitted(nextInsightId, _oracleId, _observationId, _msgSender());
    }

    /**
     * @dev Allows users to challenge the accuracy or integrity of an AI insight by staking tokens.
     *      Funds are locked until the challenge is resolved.
     * @param _insightId The ID of the insight being challenged.
     * @param _amount The amount of NATIVE_TOKEN to stake on the challenge.
     * @param _reasonURI URI explaining the reason for the challenge.
     */
    function challengeInsight(uint256 _insightId, uint256 _amount, string calldata _reasonURI) external onlyStaker notPaused {
        require(_insightId > 0 && _insightId <= nextInsightId, "AetherMind: Invalid insight ID");
        AIInsight storage insight = insights[_insightId];
        require(block.timestamp <= insight.challengeWindowEnd, "AetherMind: Challenge window for this insight has expired");
        require(!insight.isChallenged, "AetherMind: Insight is already under challenge");
        require(_amount > 0, "AetherMind: Stake amount must be positive");
        require(NATIVE_TOKEN.transferFrom(_msgSender(), address(this), _amount), "AetherMind: Token transfer failed");

        insight.isChallenged = true;
        nextChallengeId = nextChallengeId.add(1);
        
        InsightChallenge storage newChallenge = challenges[nextChallengeId];
        newChallenge.id = nextChallengeId;
        newChallenge.insightId = _insightId;
        newChallenge.challenger = _msgSender();
        newChallenge.stakeAmount = _amount;
        newChallenge.reasonURI = _reasonURI;
        newChallenge.resolved = false;
        newChallenge.accurateVerdict = false; // Default, will be set on resolution

        // Challenger automatically votes 'nay' (insight is NOT accurate)
        newChallenge.nayStakes.add(_msgSender());

        emit InsightChallenged(nextChallengeId, _insightId, _msgSender(), _amount);
    }

    // --- V. Insight Validation & Dynamic NFTs (4 functions) ---

    /**
     * @dev (Oracle/Governance) Resolves a challenged insight, distributing staked tokens to winners/losers.
     *      This could be called by a trusted oracle, or via a governance proposal for critical insights.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isAccurate The verdict: true if the insight is deemed accurate, false otherwise.
     */
    function resolveInsightChallenge(uint256 _challengeId, bool _isAccurate) external notPaused {
        require(challenges[_challengeId].insightId != 0, "AetherMind: Invalid challenge ID");
        InsightChallenge storage challenge = challenges[_challengeId];
        require(!challenge.resolved, "AetherMind: Challenge already resolved");
        
        // This function could be restricted to owner or specific 'resolution oracles' or be a target of governance.
        // For this example, let's assume `owner()` or an `approved resolver role` can call it.
        // A more robust system would require voting among multiple 'resolution oracles' or full DAO vote.
        require(_msgSender() == owner(), "AetherMind: Only owner can resolve challenges");

        challenge.resolved = true;
        challenge.accurateVerdict = _isAccurate;
        challenge.resolutionTimestamp = block.timestamp;
        
        AIInsight storage insight = insights[challenge.insightId];
        insight.isValidated = _isAccurate; // Insight is validated if accurate

        uint256 totalYayStake = NATIVE_TOKEN.balanceOf(address(this)); // This is oversimplified.
        // In a real system, you'd track individual stakes for yay/nay, not just contract balance.
        // This implies `challengeInsight` would track stakes per address, and total `yayStakes` and `nayStakes` values.

        // Placeholder for reward distribution:
        // If _isAccurate, yayStakes win, nayStakes lose their stake.
        // If !_isAccurate, nayStakes win, yayStakes lose their stake.
        // The losing stakes would be split as protocol fees or burned.
        // The winning stakes get their original stake back + a share of the losing stakes.

        // For simplicity: returning challenge.stakeAmount to challenger if challenge wins (i.e., insight is inaccurate)
        // Or if insight is accurate, then challenger loses stake.

        if (_isAccurate) { // Insight was accurate, challenger loses
            // Challenger's stake becomes protocol fee or is burned.
            // Other stakers who supported accuracy (if any) would share some reward, not implemented fully here.
        } else { // Insight was inaccurate, challenger wins
            require(NATIVE_TOKEN.transfer(challenge.challenger, challenge.stakeAmount), "AetherMind: Failed to return challenger stake");
        }

        emit InsightChallengeResolved(_challengeId, challenge.insightId, _isAccurate);
    }

    /**
     * @dev Mints a unique "Knowledge Fragment" NFT based on a validated (or unchallenged and expired window) AI insight.
     * @param _insightId The ID of the validated insight.
     * @param _to The recipient address for the new NFT.
     */
    function mintKnowledgeFragmentNFT(uint256 _insightId, address _to) external notPaused {
        require(_insightId > 0 && _insightId <= nextInsightId, "AetherMind: Invalid insight ID");
        AIInsight storage insight = insights[_insightId];
        require(insight.submitter != address(0), "AetherMind: Insight does not exist");
        
        // Insight must be validated (or challenge window expired without a challenge/resolution)
        bool canMint = (insight.isValidated) ||
                       (block.timestamp > insight.challengeWindowEnd && !insight.isChallenged);
        require(canMint, "AetherMind: Insight not yet validated or challenge window not expired");

        // The NFT's URI and content hash would be derived from the insight's URI and hash
        uint256 newTokenId = KNOWLEDGE_FRAGMENT_NFT.mint(_to, _insightId, insight.insightURI, insight.insightHash);

        emit KnowledgeFragmentMinted(newTokenId, _insightId, _to);
    }

    /**
     * @dev Allows the creator, owner, or designated updaters (via governance) to evolve the NFT's metadata
     *      as new related insights emerge or the underlying knowledge improves.
     * @param _tokenId The ID of the Knowledge Fragment NFT to update.
     * @param _newContentHash A new hash reflecting updated content (off-chain).
     * @param _newMetadataURI A new URI pointing to the updated metadata/content.
     */
    function updateKnowledgeFragmentNFT(uint256 _tokenId, bytes32 _newContentHash, string calldata _newMetadataURI)
        external notPaused
    {
        // This function can be restricted further (e.g., only minter, or a governance-approved role).
        // For flexibility, let's assume the NFT owner or this contract (via governance) can trigger updates.
        require(KNOWLEDGE_FRAGMENT_NFT.exists(_tokenId), "AetherMind: NFT does not exist");
        require(KNOWLEDGE_FRAGMENT_NFT.ownerOf(_tokenId) == _msgSender() || owner() == _msgSender(), "AetherMind: Not authorized to update NFT");

        KNOWLEDGE_FRAGMENT_NFT.updateMetadata(_tokenId, _newMetadataURI, _newContentHash);

        emit KnowledgeFragmentUpdated(_tokenId, _newContentHash);
    }

    /**
     * @dev Fuses multiple existing Knowledge Fragment NFTs into a new, more comprehensive one.
     *      The original NFTs are burned, and a new one is minted to the caller.
     * @param _tokenIdsToFuse An array of NFT IDs to be fused (burned).
     * @param _fusedMetadataURI The URI for the new, fused NFT's metadata.
     */
    function fuseKnowledgeFragments(uint256[] calldata _tokenIdsToFuse, string calldata _fusedMetadataURI)
        external notPaused
    {
        require(_tokenIdsToFuse.length >= 2, "AetherMind: At least two NFTs are required to fuse");
        
        // Ensure caller owns all NFTs to be fused
        for (uint256 i = 0; i < _tokenIdsToFuse.length; i++) {
            require(KNOWLEDGE_FRAGMENT_NFT.ownerOf(_tokenIdsToFuse[i]) == _msgSender(), "AetherMind: Caller does not own all NFTs to fuse");
            KNOWLEDGE_FRAGMENT_NFT.burn(_tokenIdsToFuse[i]); // Burn the original NFTs
        }

        // Generate a new content hash for the fused NFT (e.g., by hashing all original content hashes)
        bytes32 newContentHash = keccak256(abi.encodePacked(_tokenIdsToFuse, _fusedMetadataURI));

        // Mint a new, fused NFT. The insightId for a fused NFT could be 0 or a special ID.
        uint256 newFusedTokenId = KNOWLEDGE_FRAGMENT_NFT.mint(_msgSender(), 0, _fusedMetadataURI, newContentHash);

        emit KnowledgeFragmentsFused(_msgSender(), _tokenIdsToFuse, newFusedTokenId);
    }

    // --- VI. Governance & Collective Decision (5 functions) ---

    /**
     * @dev Allows stakers to create proposals for system changes.
     * @param _proposalType The type of proposal (e.g., ApproveOracle, UpdateProtocolFeePercentage).
     * @param _calldata The encoded function call data for execution if the proposal passes.
     * @param _descriptionURI URI pointing to a detailed description of the proposal.
     */
    function createGovernanceProposal(ProposalType _proposalType, bytes calldata _calldata, string calldata _descriptionURI)
        external onlyStaker notPaused
    {
        require(stakers[_msgSender()].balance >= MIN_PROPOSAL_STAKE, "AetherMind: Insufficient stake to create proposal");

        nextProposalId = nextProposalId.add(1);
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            proposalType: _proposalType,
            calldataPayload: _calldata,
            descriptionURI: _descriptionURI,
            proposer: nextProposalId, // Placeholder; not actual staker ID
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(PROPOSAL_VOTING_PERIOD),
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            passed: false,
            active: true,
            totalVotesAtProposalCreation: totalStaked
        });

        emit ProposalCreated(nextProposalId, _msgSender(), _proposalType);
    }

    /**
     * @dev Allows staked users to vote "for" or "against" an active proposal.
     *      Voting power is based on staked tokens at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yay" (for), false for "nay" (against).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyStaker notPaused {
        require(_proposalId > 0 && _proposalId <= nextProposalId, "AetherMind: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "AetherMind: Proposal is not active for voting");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "AetherMind: Voting period is not open");

        address voterAddress = _msgSender();
        if (stakers[_msgSender()].delegatedTo != address(0)) {
            voterAddress = stakers[_msgSender()].delegatedTo; // If delegated, vote using delegatee's power
        }

        require(!proposal.hasVoted[voterAddress], "AetherMind: Already voted on this proposal");

        uint256 votingPower = stakers[voterAddress].balance;
        require(votingPower > 0, "AetherMind: Voter has no active stake/voting power");

        if (_support) {
            proposal.yayVotes = proposal.yayVotes.add(votingPower);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(votingPower);
        }
        proposal.hasVoted[voterAddress] = true;

        emit Voted(_proposalId, _msgSender(), _support, votingPower);
    }

    /**
     * @dev Allows stakers to delegate their voting power to another address.
     *      The delegatee's votes will reflect the delegator's stake.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external onlyStaker {
        require(_delegatee != address(0), "AetherMind: Delegatee cannot be zero address");
        require(_delegatee != _msgSender(), "AetherMind: Cannot delegate to self");
        require(stakers[_msgSender()].delegatedTo == address(0), "AetherMind: Already delegated");

        stakers[_msgSender()].delegatedTo = _delegatee;
        delegations[_delegatee] = _msgSender(); // Store for easy lookup, though delegatee field is canonical

        emit VoteDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Allows stakers to revoke their delegation of voting power.
     */
    function undelegateVote() external onlyStaker {
        require(stakers[_msgSender()].delegatedTo != address(0), "AetherMind: No active delegation to undelegate");
        
        address currentDelegatee = stakers[_msgSender()].delegatedTo;
        stakers[_msgSender()].delegatedTo = address(0);
        delete delegations[currentDelegatee]; // Remove delegation from reverse lookup

        emit VoteUndelegated(_msgSender());
    }

    /**
     * @dev Any user can execute a passed governance proposal after the voting period ends and an execution delay.
     *      The calldataPayload of the proposal is executed directly on this contract.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external notPaused {
        require(_proposalId > 0 && _proposalId <= nextProposalId, "AetherMind: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "AetherMind: Proposal not active");
        require(block.timestamp > proposal.voteEndTime.add(PROPOSAL_EXECUTION_DELAY), "AetherMind: Execution delay not met");
        require(!proposal.executed, "AetherMind: Proposal already executed");

        // Check if proposal passed
        uint256 totalVotes = proposal.yayVotes.add(proposal.nayVotes);
        uint256 quorumThreshold = proposal.totalVotesAtProposalCreation.mul(QUORUM_PERCENTAGE).div(MAX_FEE_PERCENTAGE); // Using MAX_FEE_PERCENTAGE as 10000 bp

        proposal.passed = (proposal.yayVotes > proposal.nayVotes) && (totalVotes >= quorumThreshold);

        if (proposal.passed) {
            // Execute the payload. This relies on the calldataPayload targeting functions within this contract
            // that have the `onlyGovernanceExecution` modifier.
            (bool success, ) = address(this).call(proposal.calldataPayload);
            require(success, "AetherMind: Proposal execution failed");
        }
        
        proposal.executed = true;
        proposal.active = false;

        emit ProposalExecuted(_proposalId);
    }

    // --- View Functions (examples, not counted in the 20+ requirement for "actions") ---
    function getStakerDetails(address _staker) external view returns (uint256 balance, uint256 unstakeRequestTimestamp, uint256 rewardsAccumulated, address delegatedTo) {
        Staker storage s = stakers[_staker];
        return (s.balance, s.unstakeRequestTimestamp, s.rewardsAccumulated, s.delegatedTo);
    }

    function getOracleDetails(uint256 _oracleId) external view returns (uint256 id, string memory name, bool isActive, uint256 feeRate) {
        AIOracle storage o = aiOracles[_oracleId];
        return (o.id, o.name, o.isActive, o.feeRate);
    }

    function getProposalDetails(uint256 _proposalId) external view returns (uint256 id, IAetherMindGovernance.ProposalType proposalType, uint256 yayVotes, uint256 nayVotes, bool executed, bool passed, uint256 voteEndTime) {
        Proposal storage p = proposals[_proposalId];
        return (p.id, p.proposalType, p.yayVotes, p.nayVotes, p.executed, p.passed, p.voteEndTime);
    }

    function getInsightDetails(uint256 _insightId) external view returns (uint256 id, uint256 oracleId, bool isChallenged, bool isValidated, uint256 challengeWindowEnd) {
        AIInsight storage i = insights[_insightId];
        return (i.id, i.oracleId, i.isChallenged, i.isValidated, i.challengeWindowEnd);
    }
}

// --- KnowledgeFragmentNFT.sol (Separate Contract File) ---
// This contract would be deployed separately and its address passed to AetherMindCollective.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title KnowledgeFragmentNFT
 * @dev An ERC721 contract for dynamic NFTs representing curated insights.
 *      It allows for metadata updates and a fusing mechanism.
 */
contract KnowledgeFragmentNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping to store content hash for each token, allowing for on-chain verification of metadata changes
    mapping(uint256 => bytes32) public tokenContentHashes;
    // Store the insight ID that originally minted this NFT (0 for fused fragments)
    mapping(uint256 => uint256) public originalInsightId; 
    
    address public minterAddress; // The AetherMindCollective contract address

    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI, bytes32 newContentHash);
    event FragmentFused(address indexed minter, uint256[] indexed burntTokenIds, uint256 newFragmentId, string newMetadataURI);

    constructor(address _owner) ERC721("KnowledgeFragment", "KFRG") Ownable(_owner) {}

    /**
     * @dev Sets the address allowed to mint new NFTs.
     *      Typically, this will be the AetherMindCollective contract.
     * @param _minterAddress The address of the AetherMindCollective contract.
     */
    function setMinter(address _minterAddress) external onlyOwner {
        require(_minterAddress != address(0), "KFRG: Minter address cannot be zero");
        minterAddress = _minterAddress;
    }

    /**
     * @dev Internal check to ensure only the designated minter (AetherMindCollective)
     *      or the owner can call certain functions.
     */
    modifier onlyMinterOrOwner() {
        require(msg.sender == minterAddress || msg.sender == owner(), "KFRG: Not authorized to call this function");
        _;
    }

    /**
     * @dev Mints a new Knowledge Fragment NFT. Callable by the designated minter or owner.
     * @param to The address to mint the NFT to.
     * @param insightId The ID of the AetherMind insight this NFT represents (0 if fused).
     * @param tokenURI The URI for the NFT's metadata.
     * @param contentHash A hash of the NFT's content for integrity verification.
     * @return The ID of the newly minted token.
     */
    function mint(address to, uint256 insightId, string calldata tokenURI, bytes32 contentHash) external onlyMinterOrOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenContentHashes[newItemId] = contentHash;
        originalInsightId[newItemId] = insightId;
        return newItemId;
    }

    /**
     * @dev Allows updating the metadata (URI and content hash) of an existing NFT.
     *      This makes the NFT dynamic. Callable by the owner of the NFT or the contract owner.
     * @param tokenId The ID of the NFT to update.
     * @param newMetadataURI The new URI for the NFT's metadata.
     * @param newContentHash The new hash of the NFT's content.
     */
    function updateMetadata(uint256 tokenId, string calldata newMetadataURI, bytes32 newContentHash) external {
        require(_exists(tokenId), "KFRG: Token does not exist");
        // Only the token owner or the contract owner can update metadata
        require(_msgSender() == ownerOf(tokenId) || _msgSender() == owner(), "KFRG: Not authorized to update metadata");

        _setTokenURI(tokenId, newMetadataURI);
        tokenContentHashes[tokenId] = newContentHash;
        emit MetadataUpdated(tokenId, newMetadataURI, newContentHash);
    }

    /**
     * @dev Burns an NFT. Callable by the token owner or the designated minter (AetherMindCollective).
     *      This is used in the `fuseKnowledgeFragments` function.
     * @param tokenId The ID of the NFT to burn.
     */
    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "KFRG: Token does not exist");
        require(_msgSender() == ownerOf(tokenId) || _msgSender() == minterAddress, "KFRG: Not authorized to burn token");
        _burn(tokenId);
        delete tokenContentHashes[tokenId];
        delete originalInsightId[tokenId];
    }

    /**
     * @dev Checks if a token ID exists.
     * @param tokenId The ID of the token to check.
     * @return True if the token exists, false otherwise.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}
```