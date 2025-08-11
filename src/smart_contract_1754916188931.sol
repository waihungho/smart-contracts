This Solidity smart contract, `DKIN (Decentralized Knowledge & Innovation Network)`, is designed to be an advanced, creative, and unique platform for crowdsourced knowledge validation, research funding, and reputation building. It combines elements of dynamic NFTs, prediction markets, and sophisticated DAO governance, moving beyond typical DeFi or NFT projects.

---

## Decentralized Knowledge & Innovation Network (DKIN)

**Description:**
A smart contract platform for crowdsourced knowledge validation, research funding, and reputation building through a unique blend of dynamic NFTs, prediction markets, and advanced DAO governance. Users propose "Knowledge Units" (KUs) as NFTs, which are then validated or challenged by the community via token staking. Successful predictions and impactful KUs build on-chain reputation and earn rewards. The network is governed by a reputation-weighted DAO that can fund promising KUs and manage system parameters.

**Core Concepts:**

*   **Dynamic Knowledge Unit NFTs:** ERC721 tokens whose metadata URI can evolve based on validation outcomes, community input, and oracle updates, reflecting the current state and impact of the knowledge.
*   **Prediction Market for Validation:** Users stake tokens to predict the validity, accuracy, or potential impact of Knowledge Units. This creates an economic incentive for honest and informed validation.
*   **Reputation System:** A core on-chain metric for users, directly linked to successful predictions and meaningful contributions. Reputation influences voting power in the DAO and eligibility for certain actions or rewards.
*   **Advanced DAO Governance:** A decentralized autonomous organization where voting power is weighted by a user's reputation score, enabling community-driven decision-making, funding of promising Knowledge Units, and dynamic adjustment of system parameters.
*   **DeSci / Knowledge Management:** Provides a structured framework for proposing, validating, funding, and archiving research, problem statements, solutions, or innovative ideas, promoting a decentralized approach to knowledge creation and curation.

---

### Outline

**I. Core Infrastructure & Setup**
    A. Interfaces & Libraries
    B. State Variables & Constants
    C. Struct Definitions
    D. Events
    E. Constructor

**II. Knowledge Unit (KU) Management (ERC721 Integration)**
    A. ERC721 Overrides & Base URI Management
    B. KU Lifecycle (Proposing, Updating, Archiving)

**III. Validation & Prediction System**
    A. Staking for Validation/Challenge
    B. Finalizing Outcomes & Reward Distribution
    C. Querying Prediction States

**IV. Reputation & Token Management**
    A. General Token Staking/Unstaking
    B. Rewards Withdrawal
    C. Reputation Querying

**V. DAO Governance**
    A. Proposal Creation
    B. Reputation-Weighted Voting
    C. Proposal Execution

**VI. Advanced Features & Configuration**
    A. Knowledge Unit Linking
    B. Oracle Integration for Dynamic Metadata
    C. System Parameter Configuration
    D. Utility & Access Control

---

### Function Summary (27 Functions)

**I. Core Infrastructure Setup:**
1.  `constructor(address _tokenAddress, string memory _baseURI)`: Initializes the contract, sets the ERC20 token for operations (staking, rewards), and establishes the base URI for Knowledge Unit NFTs.
2.  `setBaseURI(string memory _newBaseURI)`: Allows the contract owner to update the default base URI for Knowledge Unit NFTs.

**II. Knowledge Unit (KU) Management (ERC721 for KUs):**
3.  `proposeKnowledgeUnit(string memory _ipfsHash, uint256 _validationDurationDays, uint256 _parentId)`: Mints a new Knowledge Unit NFT, providing its initial content IPFS hash, setting its validation period duration, and optionally linking it to a parent KU.
4.  `updateKnowledgeUnitContent(uint256 _kuId, string memory _newIpfsHash)`: Allows the owner of a KU to update its IPFS content hash, typically before its validation period concludes.
5.  `requestDynamicMetadataUpdate(uint256 _kuId)`: Initiates a public signal or request for the designated oracle to update the dynamic metadata URI for a specific KU.
6.  `updateDynamicMetadataUriByOracle(uint256 _kuId, string memory _newMetadataUri)`: Callable *only* by the trusted oracle to set the dynamic metadata URI for a KU, enabling off-chain data to influence the NFT's representation.
7.  `getKnowledgeUnitDetails(uint256 _kuId)`: Retrieves comprehensive data (status, stakes, timestamps, etc.) for a specific Knowledge Unit.
8.  `getKnowledgeUnitStatus(uint256 _kuId)`: Returns the current lifecycle status (Proposed, Validating, Accepted, Rejected, Archived) of a Knowledge Unit.
9.  `archiveKnowledgeUnit(uint256 _kuId)`: Allows the KU owner or the DAO (via governance) to mark a Knowledge Unit as archived, making it inactive for further validation or funding.

**III. Validation & Prediction System:**
10. `validateKnowledgeUnit(uint256 _kuId, uint256 _amount)`: Allows a user to stake a specified amount of `dkinToken` to express support for (validate) a Knowledge Unit, affecting its aggregated validation stake.
11. `challengeKnowledgeUnit(uint256 _kuId, uint256 _amount)`: Allows a user to stake `dkinToken` to express opposition to (challenge) a Knowledge Unit, contributing to its aggregated challenge stake.
12. `finalizeValidationPeriod(uint256 _kuId)`: Ends the validation period for a KU. It calculates the outcome (Accepted/Rejected) based on total stakes and unique votes, distributes rewards/penalties to participants, updates their reputation scores, and transfers protocol fees.
13. `getUserPredictionForKU(uint256 _kuId, address _user)`: Retrieves whether a specific user has participated in a KU's validation, and if so, their stance (validate/challenge) and staked amount.
14. `getValidationStatusForKU(uint256 _kuId)`: Provides the current aggregate validation and challenge stakes, along with the counts of unique positive and negative validators, for a Knowledge Unit.

**IV. Reputation & Token Management:**
15. `stakeTokens(uint256 _amount)`: Allows users to deposit `dkinToken` into the contract to boost their general staked balance, which can contribute to their perceived influence or future participation eligibility.
16. `unstakeTokens(uint256 _amount)`: Allows users to withdraw tokens from their general staked balance.
17. `withdrawEarnedTokens()`: Enables users to claim and withdraw any `dkinToken` rewards accumulated from successful predictions or direct grants via DAO proposals.
18. `getReputationScore(address _user)`: Returns the current on-chain reputation score for a given user.
19. `getAvailableStake(address _user)`: Returns the amount of tokens a user has in their general (non-KU-specific) staked balance.

**V. DAO Governance:**
20. `createGovernanceProposal(address _target, bytes memory _calldata, string memory _descriptionHash, uint256 _voteDurationDays)`: Allows users with sufficient reputation to propose a governance action, specifying a target contract, the function to call (`calldata`), a detailed description, and the voting duration.
21. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their reputation-weighted vote (for or against) on an active governance proposal.
22. `executeProposal(uint256 _proposalId)`: Triggers the execution of a governance proposal if its voting period has ended, and it has met the defined quorum and majority thresholds.
23. `getProposalDetails(uint256 _proposalId)`: Retrieves comprehensive details about a specific governance proposal, including its status, votes, and execution parameters.
24. `getUserVoteOnProposal(uint256 _proposalId, address _user)`: Checks if a specific user has voted on a particular proposal.

**VI. Advanced Features & Utilities:**
25. `linkKnowledgeUnit(uint256 _childKuId, uint256 _parentKuId)`: Establishes a formal parent-child relationship between two Knowledge Units, representing dependencies or evolutionary steps (e.g., a solution building on a problem).
26. `setOracleAddress(address _newOracleAddress)`: (Owner-only, typically to be controlled by DAO later) Sets the address of the trusted oracle responsible for updating dynamic NFT metadata.
27. `updateSystemParameter(bytes32 _paramKey, uint256 _value)`: Callable *only* by the contract itself (via successful DAO proposal execution) to dynamically adjust core system parameters like minimum stake, reputation factors, or quorum percentages.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Explicit use for clarity, though 0.8+ handles uint overflow by default.

/**
 * @title Decentralized Knowledge & Innovation Network (DKIN)
 * @dev A smart contract platform for crowdsourced knowledge validation, research funding,
 *      and reputation building through a unique blend of dynamic NFTs, prediction markets,
 *      and advanced DAO governance. Users propose "Knowledge Units" (KUs) as NFTs,
 *      which are then validated or challenged by the community via token staking.
 *      Successful predictions and impactful KUs build on-chain reputation and earn rewards.
 *      The network is governed by a reputation-weighted DAO that can fund promising KUs
 *      and manage system parameters.
 *
 * Core Concepts:
 * - Dynamic Knowledge Unit NFTs: ERC721 tokens whose metadata URI can evolve based on validation outcomes and community input.
 * - Prediction Market for Validation: Users stake tokens to predict the validity or impact of KUs.
 * - Reputation System: Linked to successful predictions and contributions, influencing voting power and rewards.
 * - DAO Governance: A decentralized autonomous organization where voting power is weighted by reputation, enabling community-driven decision-making, funding, and parameter adjustments.
 * - DeSci / Knowledge Management: Facilitates structured contribution, validation, and funding of research or innovative ideas.
 */

// --- OUTLINE ---
// I. Interfaces & Libraries
// II. Main Contract (DKIN)
//    A. State Variables & Constants
//    B. Struct Definitions
//    C. Events
//    D. Constructor
//    E. ERC721 Overrides (Knowledge Unit NFT Management)
//    F. Knowledge Unit Lifecycle Management
//       1. Proposing & Initializing KUs
//       2. Updating & Querying KU Metadata
//    G. Validation & Prediction System
//       1. Staking Predictions
//       2. Finalizing Validation Outcomes
//    H. Reputation & Token Management
//       1. General Staking
//       2. Reward Withdrawal
//    I. DAO Governance
//       1. Proposal Creation
//       2. Voting
//       3. Execution
//    J. Advanced Features & Configuration
//       1. Linking KUs
//       2. Oracle Integration (for Dynamic Metadata)
//       3. System Parameter Configuration
//    K. Utility & Read Functions

// --- FUNCTION SUMMARY (27 Functions) ---
// I. Core Infrastructure Setup:
// 1.  constructor(address _tokenAddress, string memory _baseURI) - Initializes the contract, sets the ERC20 token for operations, and base URI for NFTs.
// 2.  setBaseURI(string memory _newBaseURI) - Allows owner to update the base URI for Knowledge Unit NFTs.

// II. Knowledge Unit (KU) Management (ERC721 for KUs):
// 3.  proposeKnowledgeUnit(string memory _ipfsHash, uint256 _validationDurationDays, uint256 _parentId) - Mints a new Knowledge Unit NFT, initiating its validation period.
// 4.  updateKnowledgeUnitContent(uint256 _kuId, string memory _newIpfsHash) - Allows the KU owner to update its IPFS content hash before validation ends.
// 5.  requestDynamicMetadataUpdate(uint256 _kuId) - Initiates a request for the oracle to update the dynamic metadata URI for a KU.
// 6.  updateDynamicMetadataUriByOracle(uint256 _kuId, string memory _newMetadataUri) - Callable by a designated oracle to set the dynamic metadata URI.
// 7.  getKnowledgeUnitDetails(uint256 _kuId) - Retrieves comprehensive details about a specific Knowledge Unit.
// 8.  getKnowledgeUnitStatus(uint256 _kuId) - Returns the current status of a Knowledge Unit.
// 9.  archiveKnowledgeUnit(uint256 _kuId) - Allows the DAO or owner to archive a KU, marking it as inactive.

// III. Validation & Prediction System:
// 10. validateKnowledgeUnit(uint256 _kuId, uint256 _amount) - Stake tokens to support the validity/impact of a KU.
// 11. challengeKnowledgeUnit(uint256 _kuId, uint256 _amount) - Stake tokens to challenge the validity/impact of a KU.
// 12. finalizeValidationPeriod(uint256 _kuId) - Ends the validation period, distributes rewards/penalties, and updates KU status and participant reputations.
// 13. getUserPredictionForKU(uint256 _kuId, address _user) - Retrieves a user's specific prediction details for a KU.
// 14. getValidationStatusForKU(uint256 _kuId) - Provides the current aggregate validation/challenge stakes and counts for a KU.

// IV. Reputation & Token Management:
// 15. stakeTokens(uint256 _amount) - Allows users to stake general tokens to gain voting power and participate.
// 16. unstakeTokens(uint256 _amount) - Allows users to withdraw general staked tokens.
// 17. withdrawEarnedTokens() - Users can withdraw any rewards accumulated from successful predictions or grants.
// 18. getReputationScore(address _user) - Retrieves the reputation score of a given user.
// 19. getAvailableStake(address _user) - Returns the general (non-KU-specific) staked balance of a user.

// V. DAO Governance:
// 20. createGovernanceProposal(address _target, bytes memory _calldata, string memory _descriptionHash, uint256 _voteDurationDays) - Initiates a new governance proposal requiring reputation-weighted votes.
// 21. voteOnProposal(uint256 _proposalId, bool _support) - Allows users to cast their reputation-weighted vote on an active proposal.
// 22. executeProposal(uint256 _proposalId) - Executes a proposal if it has passed its voting period and met the approval threshold.
// 23. getProposalDetails(uint256 _proposalId) - Retrieves comprehensive details about a specific governance proposal.
// 24. getUserVoteOnProposal(uint256 _proposalId, address _user) - Checks if a user has voted on a specific proposal and their vote.

// VI. Advanced Features & Utilities:
// 25. linkKnowledgeUnit(uint256 _childKuId, uint256 _parentKuId) - Establishes a formal parent-child dependency between KUs.
// 26. setOracleAddress(address _newOracleAddress) - Allows the DAO (via governance) or owner to set the address of the trusted oracle for dynamic metadata.
// 27. updateSystemParameter(bytes32 _paramKey, uint256 _value) - Allows DAO to update system-wide parameters (e.g., min stake, reputation gain/loss ratios) via governance.

contract DKIN is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- A. State Variables & Constants ---
    IERC20 public immutable dkinToken; // The ERC20 token used for staking, rewards, and governance
    address public trustedOracle;       // Address authorized to update dynamic metadata

    Counters.Counter private _kuIds;     // Counter for Knowledge Unit IDs
    Counters.Counter private _proposalIds; // Counter for Governance Proposal IDs

    uint256 public minValidationStake;      // Minimum amount required to validate/challenge
    uint256 public minReputationForProposal; // Minimum reputation to create a governance proposal
    uint256 public proposalQuorumPercentage; // Percentage of total votes cast for a proposal to be considered for majority
    uint256 public reputationGainFactor;     // Factor for reputation gain on successful predictions (e.g., 100 = 1x staked amount)
    uint256 public reputationLossFactor;     // Factor for reputation loss on unsuccessful predictions (e.g., 50 = 0.5x staked amount)
    uint256 public protocolFeePercentage;    // Percentage of stake rewards taken as protocol fee (e.g., for treasury)

    // --- B. Struct Definitions ---

    enum KUStatus { Proposed, Validating, Accepted, Rejected, Archived }

    struct KnowledgeUnit {
        uint256 id;
        address owner;
        string ipfsHash; // Hash of the static content (e.g., research paper, problem description)
        string dynamicMetadataUri; // URI pointing to dynamic metadata (e.g., validation status, community comments)
        KUStatus status;
        uint256 creationTimestamp;
        uint224 validationPeriodEnd; // Using uint224 to save gas, as timestamp fits.
        uint256 totalValidationStake;
        uint256 totalChallengeStake;
        uint256 positiveValidationsCount; // Number of unique addresses validating
        uint256 negativeValidationsCount; // Number of unique addresses challenging
        int256 reputationAttributed; // Total reputation added/subtracted based on this KU's outcome
        uint256 parentKuId; // For linking knowledge units (e.g., solution to a problem)
    }

    struct Prediction {
        address predictor;
        uint256 kuId;
        bool isValidation; // true for validate, false for challenge
        uint256 amountStaked;
        uint224 timestamp;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string descriptionHash; // IPFS hash of proposal details
        address targetAddress;   // Address of contract to call
        bytes calldata;          // Calldata for the target contract
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;        // Sum of reputation scores of voters for
        uint256 votesAgainst;    // Sum of reputation scores of voters against
        bool executed;
    }

    // Mappings
    mapping(uint256 => KnowledgeUnit) public knowledgeUnits;
    mapping(uint256 => Prediction[]) public kuIdToPredictions; // All predictions for a given KU
    mapping(address => mapping(uint256 => bool)) public userVotedOnKU; // user => kuId => hasVoted (for unique validation/challenge per KU)

    mapping(address => uint256) public userReputationScore; // User's cumulative reputation
    mapping(address => uint256) public userStakedBalance;   // User's general staked balance (not per KU)
    mapping(address => uint256) public userEarnedRewards;   // User's available rewards to withdraw

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVoters; // proposalId => voterAddress => hasVoted

    // --- C. Events ---
    event KnowledgeUnitProposed(uint256 indexed kuId, address indexed owner, string ipfsHash, uint256 validationPeriodEnd);
    event KnowledgeUnitUpdated(uint256 indexed kuId, address indexed updater, string newIpfsHash);
    event DynamicMetadataRequested(uint256 indexed kuId, address indexed requester);
    event DynamicMetadataUpdated(uint256 indexed kuId, address indexed oracle, string newUri);
    event KnowledgeUnitArchived(uint256 indexed kuId, address indexed archiver);
    event KnowledgeUnitLinked(uint256 indexed childKuId, uint256 indexed parentKuId, address indexed linker);

    event ValidationStaked(uint256 indexed kuId, address indexed predictor, uint256 amount);
    event ChallengeStaked(uint256 indexed kuId, address indexed predictor, uint256 amount);
    event ValidationPeriodFinalized(uint256 indexed kuId, KUStatus finalStatus, uint256 totalValidationStake, uint256 totalChallengeStake);

    event ReputationUpdated(address indexed user, int256 reputationChange, uint256 newReputation);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsWithdrawn(address indexed user, uint256 amount);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionHash, uint256 endTimestamp);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 reputationWeightedVote, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event OracleAddressSet(address indexed newOracleAddress);
    event SystemParameterUpdated(bytes32 indexed paramKey, uint256 value);

    // --- D. Constructor ---
    constructor(address _tokenAddress, string memory _baseURI) ERC721("Knowledge Unit NFT", "KUN") Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        dkinToken = IERC20(_tokenAddress);

        _setBaseURI(_baseURI);

        // Initialize default parameters
        minValidationStake = 100 * (10**18); // Example: 100 tokens (assuming 18 decimals)
        minReputationForProposal = 500;
        proposalQuorumPercentage = 50; // 50% of total votes cast for quorum
        reputationGainFactor = 100;   // 1x (100%) reputation gain of staked amount for every 100 tokens. (e.g. amount * (factor / 100))
        reputationLossFactor = 50;    // 0.5x (50%) reputation loss of staked amount
        protocolFeePercentage = 5;   // 5% fee on prediction market winnings
    }

    // --- E. ERC721 Overrides (Knowledge Unit NFT Management) ---
    function _baseURI() internal view override returns (string memory) {
        return super._baseURI();
    }

    /**
     * @dev 2. Allows owner to update the base URI for Knowledge Unit NFTs.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev Overrides ERC721's tokenURI to support dynamic metadata.
     *      Prioritizes `dynamicMetadataUri` if set, otherwise falls back to static IPFS hash with `_baseURI`.
     * @param tokenId The ID of the Knowledge Unit.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        KnowledgeUnit storage ku = knowledgeUnits[tokenId];
        if (bytes(ku.dynamicMetadataUri).length > 0) {
            return ku.dynamicMetadataUri; // Prioritize dynamic URI if set
        }
        return string(abi.encodePacked(_baseURI(), ku.ipfsHash)); // Fallback to static IPFS hash
    }

    // --- F. Knowledge Unit Lifecycle Management ---

    /**
     * @dev 3. Proposes a new Knowledge Unit (KU) by minting an ERC721 token.
     *        Initiates its validation period.
     * @param _ipfsHash IPFS hash pointing to the KU's static content (e.g., research paper).
     * @param _validationDurationDays Number of days for the initial validation period.
     * @param _parentId Optional parent KU ID, indicating a dependency or derivation. 0 for no parent.
     * @return The ID of the newly created Knowledge Unit.
     */
    function proposeKnowledgeUnit(string memory _ipfsHash, uint256 _validationDurationDays, uint256 _parentId) external returns (uint256) {
        _kuIds.increment();
        uint256 newKuId = _kuIds.current();

        if (_parentId != 0) {
            require(knowledgeUnits[_parentId].id != 0, "Parent KU does not exist");
        }

        _safeMint(msg.sender, newKuId);

        KnowledgeUnit storage newKU = knowledgeUnits[newKuId];
        newKU.id = newKuId;
        newKU.owner = msg.sender;
        newKU.ipfsHash = _ipfsHash;
        newKU.status = KUStatus.Validating;
        newKU.creationTimestamp = block.timestamp;
        newKU.validationPeriodEnd = uint224(block.timestamp + _validationDurationDays.mul(1 days));
        newKU.parentKuId = _parentId;

        emit KnowledgeUnitProposed(newKuId, msg.sender, _ipfsHash, newKU.validationPeriodEnd);
        return newKuId;
    }

    /**
     * @dev 4. Allows the owner of a KU to update its IPFS content hash.
     *        This is typically permitted before the validation period ends.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _newIpfsHash The new IPFS hash.
     */
    function updateKnowledgeUnitContent(uint256 _kuId, string memory _newIpfsHash) external {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.owner == msg.sender, "Only KU owner can update content");
        require(ku.id != 0, "Knowledge Unit does not exist");
        require(ku.status == KUStatus.Proposed || ku.status == KUStatus.Validating, "Cannot update content after validation period");

        ku.ipfsHash = _newIpfsHash;
        emit KnowledgeUnitUpdated(_kuId, msg.sender, _newIpfsHash);
    }

    /**
     * @dev 5. Initiates a request for the oracle to update the dynamic metadata URI for a KU.
     *        This can be called by anyone interested in seeing updated metadata, signalling the oracle.
     * @param _kuId The ID of the Knowledge Unit.
     */
    function requestDynamicMetadataUpdate(uint256 _kuId) external {
        require(knowledgeUnits[_kuId].id != 0, "Knowledge Unit does not exist");
        emit DynamicMetadataRequested(_kuId, msg.sender);
    }

    /**
     * @dev 6. Callable by the designated trusted oracle to set the dynamic metadata URI.
     *        This enables off-chain data aggregation and computation to influence the NFT's evolving representation.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _newMetadataUri The new URI for the dynamic metadata.
     */
    function updateDynamicMetadataUriByOracle(uint256 _kuId, string memory _newMetadataUri) external {
        require(msg.sender == trustedOracle, "Only the trusted oracle can update dynamic metadata");
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");

        ku.dynamicMetadataUri = _newMetadataUri;
        emit DynamicMetadataUpdated(_kuId, msg.sender, _newMetadataUri);
    }

    /**
     * @dev 7. Retrieves comprehensive details about a specific Knowledge Unit.
     * @param _kuId The ID of the Knowledge Unit.
     * @return tuple of KU details.
     */
    function getKnowledgeUnitDetails(uint256 _kuId)
        public view
        returns (
            uint256 id,
            address owner,
            string memory ipfsHash,
            string memory dynamicMetadataUri,
            KUStatus status,
            uint256 creationTimestamp,
            uint256 validationPeriodEnd,
            uint256 totalValidationStake,
            uint256 totalChallengeStake,
            uint256 positiveValidationsCount,
            uint256 negativeValidationsCount,
            int256 reputationAttributed,
            uint256 parentKuId
        )
    {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        return (
            ku.id,
            ku.owner,
            ku.ipfsHash,
            ku.dynamicMetadataUri,
            ku.status,
            ku.creationTimestamp,
            ku.validationPeriodEnd,
            ku.totalValidationStake,
            ku.totalChallengeStake,
            ku.positiveValidationsCount,
            ku.negativeValidationsCount,
            ku.reputationAttributed,
            ku.parentKuId
        );
    }

    /**
     * @dev 8. Returns the current status of a Knowledge Unit.
     * @param _kuId The ID of the Knowledge Unit.
     * @return The KUStatus enum value.
     */
    function getKnowledgeUnitStatus(uint256 _kuId) public view returns (KUStatus) {
        require(knowledgeUnits[_kuId].id != 0, "Knowledge Unit does not exist");
        return knowledgeUnits[_kuId].status;
    }

    /**
     * @dev 9. Allows the DAO (via a successful governance proposal) or the initial owner to archive a Knowledge Unit.
     *        An archived KU cannot be validated further or receive grants.
     * @param _kuId The ID of the Knowledge Unit.
     */
    function archiveKnowledgeUnit(uint256 _kuId) public {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        // DAO's executed proposals will have msg.sender == address(this)
        require(ku.owner == msg.sender || msg.sender == address(this), "Only KU owner or DAO can archive");
        require(ku.status != KUStatus.Archived, "Knowledge Unit already archived");

        ku.status = KUStatus.Archived;
        emit KnowledgeUnitArchived(_kuId, msg.sender);
    }

    // --- G. Validation & Prediction System ---

    /**
     * @dev 10. Stake tokens to support the validity/impact of a Knowledge Unit.
     *        Users can only validate or challenge a specific KU once.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _amount The amount of tokens to stake.
     */
    function validateKnowledgeUnit(uint256 _kuId, uint256 _amount) external {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        require(ku.status == KUStatus.Validating, "KU is not in validation period");
        require(block.timestamp < ku.validationPeriodEnd, "Validation period has ended");
        require(_amount >= minValidationStake, "Stake amount too low");
        require(userVotedOnKU[msg.sender][_kuId] == false, "Already participated in validation/challenge for this KU");

        require(dkinToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        ku.totalValidationStake = ku.totalValidationStake.add(_amount);
        ku.positiveValidationsCount = ku.positiveValidationsCount.add(1);

        kuIdToPredictions[_kuId].push(Prediction({
            predictor: msg.sender,
            kuId: _kuId,
            isValidation: true,
            amountStaked: _amount,
            timestamp: uint224(block.timestamp)
        }));
        userVotedOnKU[msg.sender][_kuId] = true;

        emit ValidationStaked(_kuId, msg.sender, _amount);
    }

    /**
     * @dev 11. Stake tokens to challenge the validity/impact of a Knowledge Unit.
     *        Users can only validate or challenge a specific KU once.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _amount The amount of tokens to stake.
     */
    function challengeKnowledgeUnit(uint256 _kuId, uint256 _amount) external {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        require(ku.status == KUStatus.Validating, "KU is not in validation period");
        require(block.timestamp < ku.validationPeriodEnd, "Validation period has ended");
        require(_amount >= minValidationStake, "Stake amount too low");
        require(userVotedOnKU[msg.sender][_kuId] == false, "Already participated in validation/challenge for this KU");

        require(dkinToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        ku.totalChallengeStake = ku.totalChallengeStake.add(_amount);
        ku.negativeValidationsCount = ku.negativeValidationsCount.add(1);

        kuIdToPredictions[_kuId].push(Prediction({
            predictor: msg.sender,
            kuId: _kuId,
            isValidation: false,
            amountStaked: _amount,
            timestamp: uint224(block.timestamp)
        }));
        userVotedOnKU[msg.sender][_kuId] = true;

        emit ChallengeStaked(_kuId, msg.sender, _amount);
    }

    /**
     * @dev 12. Finalizes the validation period for a KU, distributing rewards/penalties
     *        and updating reputations based on prediction outcomes. Can be called by anyone.
     * @param _kuId The ID of the Knowledge Unit.
     */
    function finalizeValidationPeriod(uint256 _kuId) external {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        require(ku.status == KUStatus.Validating, "KU is not in validation period");
        require(block.timestamp >= ku.validationPeriodEnd, "Validation period not yet ended");

        uint256 validationStake = ku.totalValidationStake;
        uint256 challengeStake = ku.totalChallengeStake;
        KUStatus finalStatus;

        // Determine final status based on total stake, with unique vote count as tie-breaker
        if (validationStake > challengeStake) {
            finalStatus = KUStatus.Accepted;
        } else if (challengeStake > validationStake) {
            finalStatus = KUStatus.Rejected;
        } else { // Tie in stake, use unique vote count
            if (ku.positiveValidationsCount >= ku.negativeValidationsCount) {
                 finalStatus = KUStatus.Accepted;
            } else {
                finalStatus = KUStatus.Rejected;
            }
        }

        int256 totalReputationChange = 0;
        uint256 protocolFeeTotal = 0;

        for (uint i = 0; i < kuIdToPredictions[_kuId].length; i++) {
            Prediction storage p = kuIdToPredictions[_kuId][i];
            uint256 reputationDelta;
            uint256 rewardAmount = 0;

            if ((finalStatus == KUStatus.Accepted && p.isValidation) ||
                (finalStatus == KUStatus.Rejected && !p.isValidation)) {
                // Predictor was correct: earns rewards and reputation
                reputationDelta = p.amountStaked.mul(reputationGainFactor).div(100); // e.g., if factor 100, then 1x amount staked.
                userReputationScore[p.predictor] = userReputationScore[p.predictor].add(reputationDelta);
                totalReputationChange = totalReputationChange.add(int256(reputationDelta));

                uint256 potentialRewardPool;
                uint256 totalWinnerStake;

                if (p.isValidation) { // Validators won, they share the challenger's total stake
                    potentialRewardPool = challengeStake;
                    totalWinnerStake = validationStake;
                } else { // Challengers won, they share the validator's total stake
                    potentialRewardPool = validationStake;
                    totalWinnerStake = challengeStake;
                }

                if (totalWinnerStake > 0) { // Avoid division by zero
                    uint256 individualWinnings = p.amountStaked.mul(potentialRewardPool).div(totalWinnerStake);
                    uint256 protocolFee = individualWinnings.mul(protocolFeePercentage).div(100);
                    rewardAmount = p.amountStaked.add(individualWinnings).sub(protocolFee); // Return stake + winnings - fee
                    protocolFeeTotal = protocolFeeTotal.add(protocolFee);
                } else {
                    rewardAmount = p.amountStaked; // Refund stake if no opposing stake existed
                }

                userEarnedRewards[p.predictor] = userEarnedRewards[p.predictor].add(rewardAmount);

                emit ReputationUpdated(p.predictor, int256(reputationDelta), userReputationScore[p.predictor]);
            } else {
                // Predictor was incorrect: loses reputation, original stake is not refunded (it goes to winners' pool / protocol fee)
                reputationDelta = p.amountStaked.mul(reputationLossFactor).div(100); // e.g., if factor 50, then 0.5x amount staked.
                if (userReputationScore[p.predictor] > reputationDelta) {
                    userReputationScore[p.predictor] = userReputationScore[p.predictor].sub(reputationDelta);
                    totalReputationChange = totalReputationChange.sub(int256(reputationDelta));
                } else {
                    totalReputationChange = totalReputationChange.sub(int256(userReputationScore[p.predictor]));
                    userReputationScore[p.predictor] = 0; // Cap at 0
                }
                emit ReputationUpdated(p.predictor, -int256(reputationDelta), userReputationScore[p.predictor]);
            }
        }

        // Transfer collected protocol fees to the contract owner (acting as treasury)
        if (protocolFeeTotal > 0) {
            require(dkinToken.transfer(owner(), protocolFeeTotal), "Protocol fee transfer failed");
        }

        ku.status = finalStatus;
        ku.reputationAttributed = totalReputationChange;
        emit ValidationPeriodFinalized(_kuId, finalStatus, validationStake, challengeStake);
    }

    /**
     * @dev 13. Retrieves a user's specific prediction details for a KU.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _user The address of the user.
     * @return bool hasPredicted, bool isValidation, uint256 amountStaked
     */
    function getUserPredictionForKU(uint256 _kuId, address _user)
        public view
        returns (bool hasPredicted, bool isValidation, uint256 amountStaked)
    {
        for (uint i = 0; i < kuIdToPredictions[_kuId].length; i++) {
            if (kuIdToPredictions[_kuId][i].predictor == _user) {
                return (true, kuIdToPredictions[_kuId][i].isValidation, kuIdToPredictions[_kuId][i].amountStaked);
            }
        }
        return (false, false, 0);
    }

    /**
     * @dev 14. Provides the current aggregate validation/challenge stakes and counts for a KU.
     * @param _kuId The ID of the Knowledge Unit.
     * @return tuple of counts and stakes.
     */
    function getValidationStatusForKU(uint256 _kuId)
        public view
        returns (uint256 totalValidationStake, uint256 totalChallengeStake, uint256 positiveValidationsCount, uint256 negativeValidationsCount)
    {
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        require(ku.id != 0, "Knowledge Unit does not exist");
        return (ku.totalValidationStake, ku.totalChallengeStake, ku.positiveValidationsCount, ku.negativeValidationsCount);
    }

    // --- H. Reputation & Token Management ---

    /**
     * @dev 15. Allows users to stake general tokens to gain potential voting power and broader participation.
     * @param _amount The amount of tokens to stake.
     */
    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(dkinToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        userStakedBalance[msg.sender] = userStakedBalance[msg.sender].add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev 16. Allows users to withdraw general staked tokens.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) external {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(userStakedBalance[msg.sender] >= _amount, "Insufficient staked balance");
        userStakedBalance[msg.sender] = userStakedBalance[msg.sender].sub(_amount);
        require(dkinToken.transfer(msg.sender, _amount), "Token transfer failed");
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev 17. Allows users to withdraw any accumulated rewards from successful predictions or DAO grants.
     */
    function withdrawEarnedTokens() external {
        uint256 amount = userEarnedRewards[msg.sender];
        require(amount > 0, "No earned rewards to withdraw");
        userEarnedRewards[msg.sender] = 0;
        require(dkinToken.transfer(msg.sender, amount), "Reward transfer failed");
        emit RewardsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev 18. Retrieves the reputation score of a given user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return userReputationScore[_user];
    }

    /**
     * @dev 19. Returns the general (non-KU-specific) staked balance of a user.
     * @param _user The address of the user.
     * @return The general staked amount.
     */
    function getAvailableStake(address _user) public view returns (uint256) {
        return userStakedBalance[_user];
    }

    // --- I. DAO Governance ---

    /**
     * @dev 20. Initiates a new governance proposal. Requires minimum reputation.
     * @param _target The address of the contract the proposal will interact with (can be this contract).
     * @param _calldata The encoded function call (calldata) for the target contract.
     * @param _descriptionHash IPFS hash of a detailed proposal description.
     * @param _voteDurationDays Number of days for the voting period.
     * @return The ID of the newly created proposal.
     */
    function createGovernanceProposal(address _target, bytes memory _calldata, string memory _descriptionHash, uint256 _voteDurationDays)
        external
        returns (uint256)
    {
        require(userReputationScore[msg.sender] >= minReputationForProposal, "Insufficient reputation to create proposal");
        require(_voteDurationDays > 0, "Vote duration must be positive");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        GovernanceProposal storage newProposal = governanceProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.descriptionHash = _descriptionHash;
        newProposal.targetAddress = _target;
        newProposal.calldata = _calldata;
        newProposal.startTimestamp = block.timestamp;
        newProposal.endTimestamp = block.timestamp + _voteDurationDays.mul(1 days);
        newProposal.executed = false;

        emit GovernanceProposalCreated(newProposalId, msg.sender, _descriptionHash, newProposal.endTimestamp);
        return newProposalId;
    }

    /**
     * @dev 21. Allows users to cast their reputation-weighted vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.startTimestamp && block.timestamp < proposal.endTimestamp, "Voting period not active");
        require(!proposal.executed, "Proposal already executed");
        require(!proposalVoters[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterReputation = userReputationScore[msg.sender];
        require(voterReputation > 0, "Voter must have reputation");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        proposalVoters[_proposalId][msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, voterReputation, _support);
    }

    /**
     * @dev 22. Executes a proposal if it has passed its voting period and met the approval threshold.
     *        Anyone can call this to trigger execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.endTimestamp, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotesCast = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotesCast > 0, "No votes cast for this proposal");

        // Quorum: A certain percentage of the *total reputation that voted on this proposal* must vote 'for'.
        // This is a pragmatic approach given the difficulty of tracking total active reputation on-chain cheaply.
        uint256 requiredForVotes = totalVotesCast.mul(proposalQuorumPercentage).div(100);

        require(proposal.votesFor >= requiredForVotes, "Proposal did not meet quorum");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority vote");

        // Execute the proposal's intended action
        (bool success,) = proposal.targetAddress.call(proposal.calldata);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev 23. Retrieves comprehensive details about a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return tuple of proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            address proposer,
            string memory descriptionHash,
            address targetAddress,
            bytes memory calldata,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed
        )
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.descriptionHash,
            proposal.targetAddress,
            proposal.calldata,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /**
     * @dev 24. Checks if a user has voted on a specific proposal and their vote.
     * @param _proposalId The ID of the proposal.
     * @param _user The address of the user.
     * @return True if the user voted, false otherwise.
     */
    function getUserVoteOnProposal(uint256 _proposalId, address _user) public view returns (bool) {
        return proposalVoters[_proposalId][_user];
    }

    // --- J. Advanced Features & Configuration ---

    /**
     * @dev 25. Establishes a formal parent-child dependency between Knowledge Units.
     *        This can be used to represent solutions to problems, follow-up research, etc.
     * @param _childKuId The ID of the child Knowledge Unit.
     * @param _parentKuId The ID of the parent Knowledge Unit.
     */
    function linkKnowledgeUnit(uint256 _childKuId, uint256 _parentKuId) external {
        KnowledgeUnit storage childKu = knowledgeUnits[_childKuId];
        KnowledgeUnit storage parentKu = knowledgeUnits[_parentKuId];

        require(childKu.id != 0 && parentKu.id != 0, "One or both Knowledge Units do not exist");
        require(childKu.owner == msg.sender, "Only owner of child KU can link");
        require(childKu.parentKuId == 0, "Child KU already has a parent");
        require(_childKuId != _parentKuId, "Cannot link KU to itself");

        childKu.parentKuId = _parentKuId;
        emit KnowledgeUnitLinked(_childKuId, _parentKuId, msg.sender);
    }

    /**
     * @dev 26. Sets the address of the trusted oracle for dynamic metadata updates.
     *        This function should ideally be executed via a DAO governance proposal for decentralization
     *        in a production environment, but is `onlyOwner` for initial setup/simplicity here.
     * @param _newOracleAddress The address of the new trusted oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        trustedOracle = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev 27. Allows the DAO to update various system parameters.
     *        This function must be called via a successful governance proposal (msg.sender == address(this)).
     * @param _paramKey A bytes32 identifier for the parameter (e.g., keccak256("minValidationStake")).
     * @param _value The new uint256 value for the parameter.
     */
    function updateSystemParameter(bytes32 _paramKey, uint256 _value) external {
        // This function can ONLY be called by the contract itself, meaning it must be triggered
        // by a successful governance proposal's `executeProposal` call.
        require(msg.sender == address(this), "Function can only be called by the contract itself via governance");

        if (_paramKey == keccak256("minValidationStake")) {
            minValidationStake = _value;
        } else if (_paramKey == keccak256("minReputationForProposal")) {
            minReputationForProposal = _value;
        } else if (_paramKey == keccak256("proposalQuorumPercentage")) {
            require(_value <= 100, "Quorum percentage cannot exceed 100");
            proposalQuorumPercentage = _value;
        } else if (_paramKey == keccak256("reputationGainFactor")) {
            reputationGainFactor = _value;
        } else if (_paramKey == keccak256("reputationLossFactor")) {
            reputationLossFactor = _value;
        } else if (_paramKey == keccak256("protocolFeePercentage")) {
            require(_value <= 100, "Fee percentage cannot exceed 100");
            protocolFeePercentage = _value;
        } else {
            revert("Invalid parameter key");
        }
        emit SystemParameterUpdated(_paramKey, _value);
    }

    // --- K. Utility & Read Functions ---
    // (No additional specific utility functions beyond getters are added, as the main getters are part of the 27 functions)
}
```