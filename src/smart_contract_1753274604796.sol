Here's a Solidity smart contract named "CogniDAO" that embodies advanced, creative, and trendy concepts related to decentralized AI and data. It focuses on verifiable AI model performance, dynamic reward distribution, and the tokenization of AI models and datasets as NFTs.

**Disclaimer:** This contract is designed to showcase advanced concepts and should be considered a conceptual blueprint. Real-world deployment would require extensive audits, more sophisticated economic models, robust oracle integration (e.g., Chainlink functions for off-chain computation/ZK-proof verification), and a more mature DAO governance implementation (e.g., OpenZeppelin Governor contracts). The ZK-proof verification is abstracted via an interface to an assumed external `IZKVerifier` contract, as complex ZK computations are typically not performed directly within a Solidity contract due to gas costs.

---

# CogniDAO: Decentralized Autonomous Research & Development Fund for AI & Data

**Author:** CogniCraft Devs
**License:** MIT

## Outline of Contract Structure:

1.  **Introduction:**
    *   **Concept:** CogniDAO is a pioneering decentralized platform for the funding, verification, and deployment of AI models and curated datasets. It leverages blockchain technology to create a transparent, incentivized ecosystem where AI researchers, data providers, and users can collaborate.
    *   **Core Innovation:** The core innovation lies in the use of verifiable computation (ZK-proofs) for model performance, dynamic reward distribution based on ongoing utility, and NFTs representing deployable AI Agents and licensed Data Assets. This aims to foster a public good for AI, ensure trust, and distribute value fairly.
    *   **Dependencies:** Relies on an external ERC20 token for its native currency (CGN) and an external (or mocked) `IZKVerifier` contract for actual ZK-proof verification.

2.  **Core State Definitions:**
    *   `IERC20 cogniToken`: The native ERC20 token (CGN) for governance, staking, and rewards.
    *   `IZKVerifier zkVerifier`: Interface to an external contract for verifying ZK-proofs of AI model computations.
    *   `AIAgentNFT aiAgentNFT`: ERC721 contract for unique AI Agent NFTs, representing deployed and verifiable AI models.
    *   `DataAssetNFT dataAssetNFT`: ERC721 contract for unique Data Asset NFTs, representing curated and licensable datasets.
    *   **DAO Governance Parameters:** `votingPeriod`, `minStakeForProposal`, `quorumPercentage`, `minStakedForVoting`.
    *   **Staking Data:** `totalStakedCGN` (per user), `stakingRewardsAccrued`, `totalStakedSupply`.
    *   **Proposals:** `Proposal` struct and `proposals` mapping for DAO proposals (General Governance, AI Model Approval, Data Set Approval, Parameter Updates).
    *   **AI Models:** `AIModel` struct and `aiModels` mapping to track lifecycle, staking, rewards, and performance metrics for proposed and deployed AI models. `aiAgentIdToModelId` maps NFT token IDs to internal model IDs.
    *   **Data Sets:** `DataSet` struct and `dataSets` mapping to track lifecycle, quality staking, and licensing revenue for proposed and approved datasets. `dataAssetIdToDataSetId` maps NFT token IDs to internal dataset IDs.
    *   **Oracle Management:** `trustedOracleAddress` for receiving external data feeds.

3.  **Events:** Comprehensive events for traceability and off-chain monitoring of all significant actions.

4.  **Modifiers:** `onlyStaker` (for minimum CGN stake) and `onlyTrustedOracle` (for authorized oracle calls).

5.  **ERC721 Extensions:** Dedicated `AIAgentNFT` and `DataAssetNFT` contracts, owned by the main `CogniDAO` contract, allowing it to mint and manage these specialized NFTs.

6.  **Main CogniDAO Contract Functions (27 functions):**

## Function Summary:

1.  **`constructor(address _cogniTokenAddress, address _zkVerifierAddress, string memory _aiAgentName, string memory _aiAgentSymbol, string memory _dataAssetName, string memory _dataAssetSymbol)`**
    *   Initializes the CogniDAO contract, setting the CGN token address, ZK-verifier address, and ERC721 details for AI Agents and Data Assets. Transfers NFT contract ownership to itself.

2.  **`updateCogniTokenAddress(address _newCogniTokenAddress)`**
    *   **(Admin)** Allows the contract owner to update the address of the CGN ERC20 token.

3.  **`updateZKVerifierAddress(address _newZKVerifierAddress)`**
    *   **(Admin)** Allows the contract owner to update the address of the external ZK-proof verifier contract.

4.  **`updateGovernanceParameters(uint256 _newVotingPeriod, uint256 _newMinStakeForProposal, uint256 _newQuorumPercentage, uint256 _newMinStakedForVoting)`**
    *   **(Admin)** Allows the contract owner to adjust DAO governance parameters like voting period, minimum stake for proposal/voting, and quorum.

5.  **`setTrustedOracleAddress(address _newOracleAddress)`**
    *   **(Admin)** Sets the address of the trusted oracle that can push external data feeds.

6.  **`submitProposal(bytes32 _proposalHash, string calldata _descriptionURI, ProposalType _proposalType)`**
    *   Allows any user with sufficient CGN stake to submit a new governance proposal (e.g., for new AI models, datasets, or parameter changes).

7.  **`voteOnProposal(uint256 _proposalId, bool _support)`**
    *   Allows CGN stakers to cast their vote (for or against) on an active proposal. Voting power is proportional to staked CGN.

8.  **`executeProposal(uint256 _proposalId)`**
    *   Allows anyone to trigger the execution of a proposal that has passed its voting period and met the quorum.

9.  **`proposeAIModel(string calldata _modelURI, string calldata _description, address _ownerAddress)`**
    *   Initiates the process of registering a new AI model with the DAO. Creates a proposal for DAO review.

10. **`submitZKProofForModelEvaluation(uint256 _modelId, bytes calldata _proofData, bytes32 _publicInputsHash)`**
    *   Allows a proposed AI model owner to submit a ZK-proof demonstrating their model's performance. The proof is then verified by the external `IZKVerifier` contract.

11. **`_verifyAndApproveModel(uint256 _modelId)`**
    *   **(Internal / DAO-triggered)** Called internally by `executeProposal` upon a successful `AIModelApproval` vote. Marks an AI model as verified and approved, then mints an AI Agent NFT to the specified owner.

12. **`stakeForModelReliability(uint256 _aiAgentId, uint256 _amount)`**
    *   Allows the AI Agent NFT owner or other stakeholders to stake CGN, committing to the model's ongoing reliability and integrity. Required for the model to be 'Deployed' and earn rewards.

13. **`slashModelStake(uint256 _aiAgentId, uint256 _amount, bytes calldata _reason)`**
    *   **(DAO-triggered)** Allows the DAO (via proposal execution) to slash staked CGN from an AI Agent if it is proven malicious, faulty, or consistently underperforms.

14. **`claimModelRewards(uint256 _aiAgentId)`**
    *   Allows the owner of an approved AI Agent NFT to claim their accumulated CGN rewards based on model usage and verified performance metrics received via oracle.

15. **`updateAIAgentMetadata(uint256 _aiAgentId, string calldata _newMetadataURI)`**
    *   Allows the owner of an AI Agent NFT to update its metadata URI (e.g., for new versions, documentation updates).

16. **`emergencyPauseAIModel(uint256 _aiAgentId)`**
    *   **(DAO-triggered)** Allows the DAO (via proposal execution) to unilaterally pause a deployed AI Agent if it poses a significant threat or malfunction.

17. **`proposeDataSet(string calldata _dataURI, string calldata _description, address _ownerAddress)`**
    *   Initiates the process of registering a new dataset with the DAO. Creates a proposal for DAO review.

18. **`_verifyAndApproveDataSet(uint256 _dataSetId)`**
    *   **(Internal / DAO-triggered)** Called internally by `executeProposal` upon a successful `DataSetApproval` vote. Marks a dataset as verified and approved, then mints a Data Asset NFT to the specified owner.

19. **`stakeForDataSetQuality(uint256 _dataSetId, uint256 _amount)`**
    *   Allows the Data Asset NFT owner or other curators to stake CGN, committing to the data's quality and accuracy. Required for the dataset to be 'Curated' and available for licensing.

20. **`licenseDataSetAccess(uint256 _dataSetId, uint256 _licensingFee)`**
    *   Allows users to pay a specified CGN licensing fee to gain access or usage rights to an approved Data Asset. The fee is transferred to the DAO.

21. **`stakeCGNForVotingRights(uint256 _amount)`**
    *   Allows users to stake CGN tokens in the contract to gain voting power in DAO proposals and potentially earn staking rewards.

22. **`unstakeCGN(uint256 _amount)`**
    *   Allows users to unstake their CGN tokens. (Note: A cool-down period could be implemented).

23. **`claimStakingRewards()`**
    *   Allows users to claim accumulated staking rewards for their participation in DAO governance.

24. **`receiveOracleDataFeed(uint256 _aiAgentId, uint256 _performanceScore, uint256 _usageCount)`**
    *   **(Trusted Oracle Only)** Callback function for an authorized oracle to push external performance metrics and usage counts for deployed AI Agents, directly influencing model rewards.

25. **`getProposalDetails(uint256 _proposalId) view`**
    *   Returns comprehensive details about a specific proposal.

26. **`getAIAgentDetails(uint256 _aiAgentId) view`**
    *   Returns comprehensive details about a specific deployed AI Agent NFT's underlying model.

27. **`getDataSetDetails(uint256 _dataSetId) view`**
    *   Returns comprehensive details about a specific approved Data Asset NFT's underlying dataset.

28. **`getUserStake(address _user) view`**
    *   Returns the total CGN tokens staked by a specific user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit SafeMath, though Solidity 0.8+ handles overflow

/**
 * @title CogniDAO: Decentralized Autonomous Research & Development Fund for AI & Data
 * @author CogniCraft Devs
 * @notice CogniDAO is a pioneering decentralized platform for the funding, verification, and deployment
 *         of AI models and curated datasets. It leverages blockchain technology to create a transparent,
 *         incentivized ecosystem where AI researchers, data providers, and users can collaborate.
 *         The core innovation lies in the use of verifiable computation (ZK-proofs) for model performance,
 *         dynamic reward distribution based on ongoing utility, and NFTs representing deployable AI Agents
 *         and licensed Data Assets. This aims to foster a public good for AI, ensure trust, and
 *         distribute value fairly.
 *
 * @dev This contract relies on an external ERC20 token for its native currency (CGN)
 *      and an external (or mocked) ZK-Verifier contract for actual ZK-proof verification.
 *      The ZK-proof verification is abstracted for simplicity in this Solidity contract,
 *      assuming a pre-existing or future method for on-chain proof validation (e.g., via precompiles,
 *      rollup verifiers, or specialized layer-2 solutions).
 *      A more robust DAO would use OpenZeppelin's Governor contracts for complex proposal execution.
 */

// --- Function Summary ---
//
// 1.  constructor(address _cogniTokenAddress, address _zkVerifierAddress, string memory _aiAgentName, string memory _aiAgentSymbol, string memory _dataAssetName, string memory _dataAssetSymbol)
//     - Initializes the CogniDAO contract, setting the CGN token address, ZK-verifier address, and ERC721 details for AI Agents and Data Assets.
// 2.  updateCogniTokenAddress(address _newCogniTokenAddress)
//     - (Admin) Allows the contract owner to update the address of the CGN ERC20 token.
// 3.  updateZKVerifierAddress(address _newZKVerifierAddress)
//     - (Admin) Allows the contract owner to update the address of the external ZK-proof verifier contract.
// 4.  updateGovernanceParameters(uint256 _newVotingPeriod, uint256 _newMinStakeForProposal, uint256 _newQuorumPercentage, uint256 _newMinStakedForVoting)
//     - (Admin) Allows the contract owner to adjust DAO governance parameters like voting period, minimum stake for proposal/voting, and quorum.
// 5.  setTrustedOracleAddress(address _newOracleAddress)
//     - (Admin) Sets the address of the trusted oracle that can push external data feeds.
// 6.  submitProposal(bytes32 _proposalHash, string calldata _descriptionURI, ProposalType _proposalType)
//     - Allows any user with sufficient CGN stake to submit a new governance proposal (e.g., new AI model, dataset, parameter change).
// 7.  voteOnProposal(uint256 _proposalId, bool _support)
//     - Allows CGN stakers to cast their vote (for or against) on an active proposal. Voting power is proportional to staked CGN.
// 8.  executeProposal(uint256 _proposalId)
//     - Allows anyone to trigger the execution of a proposal that has passed its voting period and met the quorum.
// 9.  proposeAIModel(string calldata _modelURI, string calldata _description, address _ownerAddress)
//     - Initiates the process of registering a new AI model with the DAO. Creates a proposal for review.
// 10. submitZKProofForModelEvaluation(uint256 _modelId, bytes calldata _proofData, bytes32 _publicInputsHash)
//     - Allows a proposed AI model owner to submit a ZK-proof demonstrating their model's performance. The proof is then verified by the external ZK-Verifier.
// 11. _verifyAndApproveModel(uint256 _modelId)
//     - (Internal / DAO Approved) Marks an AI model as verified and approved after a successful ZK-proof validation and DAO vote. Mints an AI Agent NFT.
// 12. stakeForModelReliability(uint256 _aiAgentId, uint256 _amount)
//     - Allows the AI Agent owner or other stakeholders to stake CGN, committing to the model's ongoing reliability and integrity. Required for rewards.
// 13. slashModelStake(uint256 _aiAgentId, uint256 _amount, bytes calldata _reason)
//     - (DAO Approved) Allows the DAO to slash staked CGN from an AI Agent if it is proven malicious, faulty, or consistently underperforms.
// 14. claimModelRewards(uint256 _aiAgentId)
//     - Allows the owner of an approved AI Agent NFT to claim their accumulated CGN rewards based on model usage and verified performance.
// 15. updateAIAgentMetadata(uint256 _aiAgentId, string calldata _newMetadataURI)
//     - Allows the owner of an AI Agent NFT to update its metadata URI (e.g., for new versions, documentation updates).
// 16. emergencyPauseAIModel(uint256 _aiAgentId)
//     - (DAO Approved) Allows the DAO to unilaterally pause a deployed AI Agent if it poses a significant threat or malfunction.
// 17. proposeDataSet(string calldata _dataURI, string calldata _description, address _ownerAddress)
//     - Initiates the process of registering a new dataset with the DAO. Creates a proposal for review.
// 18. _verifyAndApproveDataSet(uint256 _dataSetId)
//     - (Internal / DAO Approved) Marks a dataset as verified and approved after DAO vote. Mints a Data Asset NFT.
// 19. stakeForDataSetQuality(uint256 _dataSetId, uint256 _amount)
//     - Allows the Data Asset owner or other curators to stake CGN, committing to the data's quality and accuracy. Required for licensing.
// 20. licenseDataSetAccess(uint256 _dataSetId, uint256 _licensingFee)
//     - Allows users to pay a specified CGN licensing fee to gain access or usage rights to an approved Data Asset.
// 21. stakeCGNForVotingRights(uint256 _amount)
//     - Allows users to stake CGN tokens in the contract to gain voting power in DAO proposals and earn staking rewards.
// 22. unstakeCGN(uint256 _amount)
//     - Allows users to unstake their CGN tokens after a cool-down period, revoking their voting power for the unstaked amount.
// 23. claimStakingRewards()
//     - Allows users to claim accumulated staking rewards for their participation in DAO governance.
// 24. receiveOracleDataFeed(uint256 _aiAgentId, uint256 _performanceScore, uint256 _usageCount)
//     - (Authorized Oracle) Allows an authorized oracle to push external performance metrics and usage counts for deployed AI Agents, influencing rewards.
// 25. getProposalDetails(uint256 _proposalId) view
//     - Returns comprehensive details about a specific proposal.
// 26. getAIAgentDetails(uint256 _aiAgentId) view
//     - Returns comprehensive details about a specific deployed AI Agent NFT.
// 27. getDataSetDetails(uint256 _dataSetId) view
//     - Returns comprehensive details about a specific Data Asset NFT.
// 28. getUserStake(address _user) view
//     - Returns the total CGN tokens staked by a specific user.

// --- External Contracts ---
// Assumed ZK-Verifier Interface (simplified for demonstration)
interface IZKVerifier {
    function verifyProof(bytes calldata _proof, bytes32 _publicInputsHash) external view returns (bool);
}

// --- ERC721 for AI Agents ---
contract AIAgentNFT is ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function updateURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        require(_exists(tokenId), "AIAgentNFT: token does not exist");
        _setTokenURI(tokenId, newTokenURI);
    }
}

// --- ERC721 for Data Assets ---
contract DataAssetNFT is ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function updateURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        require(_exists(tokenId), "DataAssetNFT: token does not exist");
        _setTokenURI(tokenId, newTokenURI);
    }
}

contract CogniDAO is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public cogniToken; // The native ERC20 token for governance and rewards (CGN)
    IZKVerifier public zkVerifier; // External contract for ZK-proof verification

    AIAgentNFT public aiAgentNFT; // ERC721 contract for AI Agent NFTs
    DataAssetNFT public dataAssetNFT; // ERC721 contract for Data Asset NFTs

    // DAO Governance Parameters
    uint256 public votingPeriod; // Duration of voting in seconds
    uint256 public minStakeForProposal; // Minimum CGN stake required to submit a proposal (in wei)
    uint256 public quorumPercentage; // Percentage of total staked votes required for a proposal to pass (e.g., 51 for 51%)
    uint256 public minStakedForVoting; // Minimum CGN stake required to vote (in wei)

    // Staking related
    mapping(address => uint256) public totalStakedCGN; // User's total staked CGN
    mapping(address => uint256) public stakingRewardsAccrued; // Accrued rewards for stakers (Simplified: Not actively accruing in this contract)
    uint256 public totalStakedSupply; // Total CGN staked in the contract

    // Proposal Management
    Counters.Counter private _proposalIds;
    enum ProposalType {
        GeneralGovernance, // General DAO proposals (e.g., treasury allocation, new features)
        AIModelApproval,   // Proposal to approve a new AI model for deployment
        DataSetApproval,   // Proposal to approve a new dataset for curation
        UpdateParameter    // Proposal to update a contract parameter via governance (requires off-chain signature or proxy)
    }

    struct Proposal {
        uint256 id;
        bytes32 proposalHash; // Unique identifier for the proposal content (e.g., hash of IPFS URI or call data)
        string descriptionURI; // URI to proposal details (e.g., IPFS)
        address proposer;
        ProposalType proposalType;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        // Specific fields for AI/DataSet related proposals
        uint256 targetEntityId; // AI Model ID or Data Set ID if type is AIModelApproval/DataSetApproval
        address targetEntityOwner; // Proposed owner for AI Model or Data Set NFT
    }
    mapping(uint256 => Proposal) public proposals;

    // AI Model Management
    Counters.Counter private _aiModelIds;
    enum ModelStatus {
        Proposed,      // Submitted, awaiting DAO review
        AwaitingProof, // Awaiting ZK-proof submission for verification
        ProofSubmitted,// ZK-proof submitted, awaiting verification/DAO decision (ProofVerified means ZK-Verifier returned true)
        Approved,      // Approved by DAO, NFT can be minted
        Deployed,      // Deployed and active (after owner stakes reliability)
        Paused,        // Temporarily paused by DAO due to issues
        Slashed        // Slashed due to malfunction/malice, stake removed
    }

    struct AIModel {
        uint256 id;
        string modelURI; // URI to model details (e.g., IPFS link to model weights, docs, API endpoint)
        address owner; // Address of the AI Agent NFT owner
        ModelStatus status;
        uint256 stakedReliability; // CGN staked by model owner for reliability
        uint256 totalRewardsEarned; // Accumulated rewards for this model
        uint256 lastClaimTime; // Timestamp of last reward claim
        // ZK-Proof related
        bytes32 currentZKProofHash; // Hash of the public inputs used in the latest proof
        bool zkProofVerified; // Flag for external ZK verifier result on currentZKProofHash
        uint256 performanceScore; // Aggregated score from oracles/verified proofs (e.g., 0-100)
        uint256 usageCount; // Number of times model was used, from oracle
    }
    mapping(uint256 => AIModel) public aiModels; // AIModel ID to its struct
    mapping(uint256 => uint256) public aiAgentIdToModelId; // AI Agent NFT TokenID to AIModel ID

    // Data Set Management
    Counters.Counter private _dataSetIds;
    enum DataSetStatus {
        Proposed, // Submitted, awaiting DAO review
        Approved, // Approved by DAO, NFT minted
        Curated   // Actively curated and available for licensing (after owner stakes quality)
    }

    struct DataSet {
        uint256 id;
        string dataURI; // URI to dataset details (e.g., IPFS link to dataset, schema, docs, access methods)
        address owner; // Address of the Data Asset NFT owner
        DataSetStatus status;
        uint256 stakedQuality; // CGN staked by data owner/curator for quality
        uint256 totalLicensedRevenue; // Accumulated revenue from licensing this dataset
    }
    mapping(uint256 => DataSet) public dataSets; // DataSet ID to its struct
    mapping(uint256 => uint256) public dataAssetIdToDataSetId; // Data Asset NFT TokenID to DataSet ID

    // Oracle Management
    address public trustedOracleAddress; // Address of the trusted oracle for data feeds

    // --- Events ---
    event CogniTokenAddressUpdated(address indexed newAddress);
    event ZKVerifierAddressUpdated(address indexed newAddress);
    event GovernanceParametersUpdated(uint256 newVotingPeriod, uint256 newMinStakeForProposal, uint256 newQuorumPercentage, uint256 newMinStakedForVoting);
    event TrustedOracleAddressUpdated(address indexed newAddress);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string descriptionURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    event AIModelProposed(uint256 indexed modelId, address indexed owner, string modelURI);
    event ZKProofSubmitted(uint256 indexed modelId, bytes32 indexed proofHash, address indexed submitter, bool verifiedByZKVerifier);
    event AIModelVerifiedAndApproved(uint256 indexed modelId, uint256 indexed aiAgentTokenId, address indexed owner);
    event AIAgentMetadataUpdated(uint256 indexed aiAgentTokenId, string newURI);
    event ModelReliabilityStaked(uint256 indexed aiAgentId, address indexed staker, uint256 amount);
    event ModelStakeSlashed(uint256 indexed aiAgentId, uint256 amount, string reason);
    event ModelRewardsClaimed(uint256 indexed aiAgentId, address indexed owner, uint256 amount);
    event AIModelPaused(uint256 indexed aiAgentId);

    event DataSetProposed(uint256 indexed dataSetId, address indexed owner, string dataURI);
    event DataSetVerifiedAndApproved(uint256 indexed dataSetId, uint256 indexed dataAssetTokenId, address indexed owner);
    event DataSetQualityStaked(uint256 indexed dataSetId, address indexed staker, uint256 amount);
    event DataSetAccessed(uint256 indexed dataSetId, address indexed accessor, uint256 fee);

    event CGNStakedForVoting(address indexed user, uint256 amount);
    event CGNUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    event OracleDataReceived(uint256 indexed aiAgentId, uint256 performanceScore, uint256 usageCount);

    // --- Modifiers ---
    modifier onlyStaker() {
        require(totalStakedCGN[msg.sender] >= minStakedForVoting, "CogniDAO: Insufficient stake to perform action");
        _;
    }

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracleAddress, "CogniDAO: Not authorized oracle");
        _;
    }

    // --- Constructor ---
    constructor(
        address _cogniTokenAddress,
        address _zkVerifierAddress,
        string memory _aiAgentName,
        string memory _aiAgentSymbol,
        string memory _dataAssetName,
        string memory _dataAssetSymbol
    )
        Ownable(msg.sender)
    {
        require(_cogniTokenAddress != address(0), "CogniDAO: CGN Token address cannot be zero");
        require(_zkVerifierAddress != address(0), "CogniDAO: ZK Verifier address cannot be zero");

        cogniToken = IERC20(_cogniTokenAddress);
        zkVerifier = IZKVerifier(_zkVerifierAddress);

        // Deploy child NFT contracts and transfer their ownership to this DAO contract
        aiAgentNFT = new AIAgentNFT(_aiAgentName, _aiAgentSymbol);
        dataAssetNFT = new DataAssetNFT(_dataAssetName, _dataAssetSymbol);

        aiAgentNFT.transferOwnership(address(this));
        dataAssetNFT.transferOwnership(address(this));

        // Default governance parameters (can be updated via owner or DAO later)
        votingPeriod = 7 days; // 7 days in seconds
        minStakeForProposal = 1000 * 10**18; // 1000 CGN (assuming 18 decimals)
        quorumPercentage = 51; // 51% of total staked supply
        minStakedForVoting = 100 * 10**18; // 100 CGN

        // Set initial trusted oracle (for demonstration, owner is initial oracle, should be a dedicated oracle service in production)
        trustedOracleAddress = msg.sender;
    }

    // --- Admin Functions ---

    /**
     * @dev Updates the address of the main CGN ERC20 token. Callable by the contract owner.
     * @param _newCogniTokenAddress The new address of the CGN token contract.
     */
    function updateCogniTokenAddress(address _newCogniTokenAddress) public onlyOwner {
        require(_newCogniTokenAddress != address(0), "CogniDAO: New CGN Token address cannot be zero");
        cogniToken = IERC20(_newCogniTokenAddress);
        emit CogniTokenAddressUpdated(_newCogniTokenAddress);
    }

    /**
     * @dev Updates the address of the external ZK-proof verifier contract. Callable by the contract owner.
     * @param _newZKVerifierAddress The new address of the ZKVerifier contract.
     */
    function updateZKVerifierAddress(address _newZKVerifierAddress) public onlyOwner {
        require(_newZKVerifierAddress != address(0), "CogniDAO: New ZK Verifier address cannot be zero");
        zkVerifier = IZKVerifier(_newZKVerifierAddress);
        emit ZKVerifierAddressUpdated(_newZKVerifierAddress);
    }

    /**
     * @dev Updates DAO governance parameters. Callable by the contract owner.
     *      In a full DAO implementation, these would be updated via a successful governance proposal.
     * @param _newVotingPeriod New duration for voting periods in seconds.
     * @param _newMinStakeForProposal New minimum CGN stake required to submit a proposal.
     * @param _newQuorumPercentage New percentage of total staked votes required for a proposal to pass.
     * @param _newMinStakedForVoting New minimum CGN stake required to vote.
     */
    function updateGovernanceParameters(
        uint256 _newVotingPeriod,
        uint256 _newMinStakeForProposal,
        uint256 _newQuorumPercentage,
        uint256 _newMinStakedForVoting
    ) public onlyOwner {
        require(_newVotingPeriod > 0, "CogniDAO: Voting period must be greater than zero");
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "CogniDAO: Quorum percentage must be between 1 and 100");
        votingPeriod = _newVotingPeriod;
        minStakeForProposal = _newMinStakeForProposal;
        quorumPercentage = _newQuorumPercentage;
        minStakedForVoting = _newMinStakedForVoting;
        emit GovernanceParametersUpdated(votingPeriod, minStakeForProposal, quorumPercentage, minStakedForVoting);
    }

    /**
     * @dev Sets the address of the trusted oracle that can push external data feeds. Callable by the contract owner.
     *      This address should ideally be a decentralized oracle network's smart contract.
     * @param _newOracleAddress The address of the new trusted oracle.
     */
    function setTrustedOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "CogniDAO: Oracle address cannot be zero");
        trustedOracleAddress = _newOracleAddress;
        emit TrustedOracleAddressUpdated(_newOracleAddress);
    }

    // --- DAO Governance Functions ---

    /**
     * @dev Allows users with sufficient CGN stake to submit a new proposal to the DAO.
     * @param _proposalHash A unique hash identifying the proposal content (e.g., keccak256 hash of IPFS content).
     * @param _descriptionURI URI to detailed proposal description (e.g., IPFS link to markdown, PDF).
     * @param _proposalType The type of proposal (GeneralGovernance, AIModelApproval, DataSetApproval, UpdateParameter).
     */
    function submitProposal(
        bytes32 _proposalHash,
        string calldata _descriptionURI,
        ProposalType _proposalType
    ) public onlyStaker nonReentrant {
        require(totalStakedCGN[msg.sender] >= minStakeForProposal, "CogniDAO: Insufficient stake to submit proposal");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage p = proposals[newProposalId];
        p.id = newProposalId;
        p.proposalHash = _proposalHash;
        p.descriptionURI = _descriptionURI;
        p.proposer = msg.sender;
        p.proposalType = _proposalType;
        p.voteStartTime = block.timestamp;
        p.voteEndTime = block.timestamp.add(votingPeriod);
        p.executed = false;
        p.passed = false;
        // targetEntityId and targetEntityOwner will be set if proposalType is AIModelApproval or DataSetApproval later in proposeAIModel/proposeDataSet

        emit ProposalSubmitted(newProposalId, msg.sender, _proposalType, _descriptionURI);
    }

    /**
     * @dev Allows CGN stakers to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyStaker {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "CogniDAO: Proposal does not exist");
        require(block.timestamp >= p.voteStartTime, "CogniDAO: Voting has not started");
        require(block.timestamp <= p.voteEndTime, "CogniDAO: Voting has ended");
        require(!p.executed, "CogniDAO: Proposal already executed");
        require(!p.hasVoted[msg.sender], "CogniDAO: Already voted on this proposal");

        uint256 voterStake = totalStakedCGN[msg.sender];
        require(voterStake >= minStakedForVoting, "CogniDAO: Insufficient stake to vote");

        if (_support) {
            p.votesFor = p.votesFor.add(voterStake);
        } else {
            p.votesAgainst = p.votesAgainst.add(voterStake);
        }
        p.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterStake);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and met quorum requirements.
     *      Anyone can call this function to trigger execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "CogniDAO: Proposal does not exist");
        require(block.timestamp > p.voteEndTime, "CogniDAO: Voting period not ended");
        require(!p.executed, "CogniDAO: Proposal already executed");

        uint256 totalVotes = p.votesFor.add(p.votesAgainst);
        require(totalVotes > 0, "CogniDAO: No votes cast");

        // Quorum check: A significant portion of total staked supply must have voted.
        // This prevents proposals from passing with very few votes if totalStakedSupply is high.
        uint256 requiredQuorumVotes = totalStakedSupply.mul(quorumPercentage).div(100);
        require(totalVotes >= requiredQuorumVotes, "CogniDAO: Quorum not met");

        p.passed = p.votesFor > p.votesAgainst;
        p.executed = true;

        if (p.passed) {
            if (p.proposalType == ProposalType.AIModelApproval) {
                // Directly call the internal function to mint AI Agent NFT
                _verifyAndApproveModel(p.targetEntityId);
            } else if (p.proposalType == ProposalType.DataSetApproval) {
                // Directly call the internal function to mint Data Asset NFT
                _verifyAndApproveDataSet(p.targetEntityId);
            } else if (p.proposalType == ProposalType.UpdateParameter) {
                // In a production DAO, this would involve a complex call to
                // another contract (e.g., via a proxy) or more specific parameter update logic.
                // For this example, it signifies a successful vote on a parameter change that
                // would be manually applied by the owner or a separate upgrade mechanism.
                // This contract's `updateGovernanceParameters` is onlyOwner, so a real DAO
                // would have a mechanism to trigger it or similar functions via a proposal.
            } else if (p.proposalType == ProposalType.GeneralGovernance) {
                // Logic for general governance proposals (e.g., funding grants,
                // other arbitrary actions) would go here. Could involve direct ETH/token transfers
                // or calls to other contracts.
            }
        }
        emit ProposalExecuted(_proposalId, p.passed);
    }

    // --- AI Model Management (ERC721 AI Agents) ---

    /**
     * @dev Proposes a new AI model for review and potential deployment by the DAO.
     *      This creates a 'AIModelApproval' proposal.
     * @param _modelURI URI to the AI model's details (e.g., IPFS link to model architecture, weights, documentation, inference API).
     * @param _description A brief description of the model for the proposal.
     * @param _ownerAddress The address proposed to be the owner of the AI Agent NFT upon approval.
     */
    function proposeAIModel(string calldata _modelURI, string calldata _description, address _ownerAddress) public onlyStaker nonReentrant {
        require(bytes(_modelURI).length > 0, "CogniDAO: Model URI cannot be empty");
        require(_ownerAddress != address(0), "CogniDAO: Model owner address cannot be zero");

        _aiModelIds.increment();
        uint256 newModelId = _aiModelIds.current();

        AIModel storage model = aiModels[newModelId];
        model.id = newModelId;
        model.modelURI = _modelURI;
        model.owner = _ownerAddress; // Proposed owner, confirmed upon DAO approval
        model.status = ModelStatus.Proposed;

        // Create a DAO proposal for this model's approval
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage p = proposals[newProposalId];
        p.id = newProposalId;
        // Hash unique data to prevent proposal duplication for the same model
        p.proposalHash = keccak256(abi.encodePacked("AIModelApproval", newModelId, _modelURI, _ownerAddress, block.timestamp));
        p.descriptionURI = _description;
        p.proposer = msg.sender;
        p.proposalType = ProposalType.AIModelApproval;
        p.voteStartTime = block.timestamp;
        p.voteEndTime = block.timestamp.add(votingPeriod);
        p.executed = false;
        p.passed = false;
        p.targetEntityId = newModelId;
        p.targetEntityOwner = _ownerAddress;

        emit AIModelProposed(newModelId, _ownerAddress, _modelURI);
        emit ProposalSubmitted(newProposalId, msg.sender, ProposalType.AIModelApproval, _description);
    }

    /**
     * @dev Allows a proposed AI model owner to submit a ZK-proof of their model's performance on a specific dataset.
     *      This function interacts with the external ZK-Verifier contract.
     * @param _modelId The ID of the AI model.
     * @param _proofData The raw ZK-proof data generated off-chain.
     * @param _publicInputsHash The hash of the public inputs used in the ZK-proof (e.g., commitments to dataset hash, model ID, performance metric).
     */
    function submitZKProofForModelEvaluation(uint256 _modelId, bytes calldata _proofData, bytes32 _publicInputsHash) public nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "CogniDAO: Model does not exist");
        require(model.owner == msg.sender, "CogniDAO: Only model owner can submit proof");
        require(model.status == ModelStatus.Proposed || model.status == ModelStatus.AwaitingProof, "CogniDAO: Model not in valid state for proof submission");

        // Call the external ZK-Verifier contract to verify the proof
        bool verified = zkVerifier.verifyProof(_proofData, _publicInputsHash);

        model.currentZKProofHash = _publicInputsHash;
        model.zkProofVerified = verified;

        if (verified) {
             model.status = ModelStatus.AwaitingProof; // Change to AwaitingProof (indicating proof submitted and valid)
        } else {
            // Proof failed, status remains Proposed or AwaitingProof, allowing re-submission
        }

        emit ZKProofSubmitted(_modelId, _publicInputsHash, msg.sender, verified);
    }

    /**
     * @dev Internal function called by `executeProposal` when an AIModelApproval proposal passes.
     *      Mints an AI Agent NFT to the model owner and sets the model's status to Approved.
     * @param _modelId The ID of the AI model to approve.
     */
    function _verifyAndApproveModel(uint256 _modelId) internal {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "CogniDAO: Model does not exist");
        // Ensure that a ZK proof was submitted and verified, if required for final approval.
        // The DAO would vote on the proof's validity based on its verification outcome.
        require(model.zkProofVerified, "CogniDAO: ZK proof not verified for approval");
        require(model.status == ModelStatus.AwaitingProof, "CogniDAO: Model not in awaiting proof status for approval.");

        model.status = ModelStatus.Approved;
        uint256 newTokenId = _aiModelIds.current(); // Using current counter for NFT token ID for simplicity

        aiAgentNFT.mint(model.owner, newTokenId, model.modelURI); // Mint the AI Agent NFT
        aiAgentIdToModelId[newTokenId] = _modelId; // Map the new NFT TokenID to the internal AIModel ID

        emit AIModelVerifiedAndApproved(_modelId, newTokenId, model.owner);
    }

    /**
     * @dev Allows an AI Agent owner or authorized party to stake CGN for the model's ongoing reliability.
     *      This stake is required for the model to enter 'Deployed' status and become eligible for rewards.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     * @param _amount The amount of CGN to stake.
     */
    function stakeForModelReliability(uint256 _aiAgentId, uint256 _amount) public nonReentrant {
        require(_amount > 0, "CogniDAO: Amount must be greater than zero");
        address modelOwner = aiAgentNFT.ownerOf(_aiAgentId);
        require(modelOwner == msg.sender, "CogniDAO: Only AI Agent owner can stake for reliability");

        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: Model does not exist for this AI Agent NFT");
        require(model.status == ModelStatus.Approved || model.status == ModelStatus.Deployed, "CogniDAO: Model not in approved or deployed state");

        cogniToken.transferFrom(msg.sender, address(this), _amount); // Transfer CGN to contract
        model.stakedReliability = model.stakedReliability.add(_amount);
        model.status = ModelStatus.Deployed; // Model becomes deployed once reliability is staked

        emit ModelReliabilityStaked(_aiAgentId, msg.sender, _amount);
    }

    /**
     * @dev Allows the DAO (via proposal execution) to slash staked CGN from an AI Agent.
     *      Used if a model is proven malicious, faulty, or consistently underperforms.
     *      The slashed funds could be burned, sent to a treasury, or redistributed. For simplicity,
     *      they are removed from the model's stake and remain in the contract for DAO discretion.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     * @param _amount The amount of CGN to slash.
     * @param _reason A reason or reference (e.g., IPFS link to an investigation report) for slashing.
     */
    function slashModelStake(uint256 _aiAgentId, uint256 _amount, string calldata _reason) public nonReentrant {
        // This function should ONLY be callable via a passed DAO proposal execution.
        // A more robust DAO implementation (e.g., OpenZeppelin Governor) would ensure this.
        require(msg.sender == address(this), "CogniDAO: Only executable by DAO proposal");

        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: Model does not exist for this AI Agent NFT");
        require(model.stakedReliability >= _amount, "CogniDAO: Insufficient staked reliability to slash");
        require(model.status == ModelStatus.Deployed || model.status == ModelStatus.Paused, "CogniDAO: Model not in deployable or paused state for slashing");

        model.stakedReliability = model.stakedReliability.sub(_amount);
        model.status = ModelStatus.Slashed; // Mark as slashed
        emit ModelStakeSlashed(_aiAgentId, _amount, _reason);
    }

    /**
     * @dev Allows the owner of an approved AI Agent NFT to claim their accumulated CGN rewards.
     *      Rewards are based on verified usage and performance metrics received via oracle.
     *      Reward calculation formula is simplified for this example; a real system would use
     *      a more sophisticated, potentially time-weighted, accrual mechanism.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     */
    function claimModelRewards(uint256 _aiAgentId) public nonReentrant {
        address modelOwner = aiAgentNFT.ownerOf(_aiAgentId);
        require(modelOwner == msg.sender, "CogniDAO: Only AI Agent owner can claim rewards");

        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: Model does not exist for this AI Agent NFT");
        require(model.status == ModelStatus.Deployed, "CogniDAO: Model not in deployed status to earn rewards");
        require(model.stakedReliability > 0, "CogniDAO: Model must have reliability staked to earn rewards");

        // Simplified reward calculation: based on performance score and usage count (e.g., per 100 units)
        // This needs a much more complex, economically sound model in production.
        uint256 rewardsAvailable = (model.performanceScore.mul(model.usageCount)).div(100);

        require(rewardsAvailable > 0, "CogniDAO: No rewards available to claim");
        require(cogniToken.balanceOf(address(this)) >= rewardsAvailable, "CogniDAO: Insufficient contract balance for rewards");

        model.totalRewardsEarned = model.totalRewardsEarned.add(rewardsAvailable);
        // Reset metrics for the next reward cycle
        model.performanceScore = 0;
        model.usageCount = 0;
        model.lastClaimTime = block.timestamp;

        cogniToken.transfer(msg.sender, rewardsAvailable);
        emit ModelRewardsClaimed(_aiAgentId, msg.sender, rewardsAvailable);
    }

    /**
     * @dev Allows the owner of an AI Agent NFT to update its metadata URI. This can reflect new model versions,
     *      updated documentation, or changes in API endpoints.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     * @param _newMetadataURI The new URI for the NFT metadata (e.g., IPFS link).
     */
    function updateAIAgentMetadata(uint256 _aiAgentId, string calldata _newMetadataURI) public {
        address modelOwner = aiAgentNFT.ownerOf(_aiAgentId);
        require(modelOwner == msg.sender, "CogniDAO: Only AI Agent owner can update metadata");
        require(bytes(_newMetadataURI).length > 0, "CogniDAO: New metadata URI cannot be empty");

        aiAgentNFT.updateURI(_aiAgentId, _newMetadataURI);
        emit AIAgentMetadataUpdated(_aiAgentId, _newMetadataURI);
    }

    /**
     * @dev Allows the DAO (via proposal execution) to pause a deployed AI Agent.
     *      A paused model would not be eligible for rewards or new oracle data.
     * @param _aiAgentId The Token ID of the AI Agent NFT to pause.
     */
    function emergencyPauseAIModel(uint256 _aiAgentId) public {
        // This function should ONLY be callable via a passed DAO proposal execution.
        require(msg.sender == address(this), "CogniDAO: Only executable by DAO proposal");

        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: Model does not exist for this AI Agent NFT");
        require(model.status == ModelStatus.Deployed, "CogniDAO: Model not in deployed status to pause");

        model.status = ModelStatus.Paused;
        emit AIModelPaused(_aiAgentId);
    }

    // --- Data Set Management (ERC721 Data Assets) ---

    /**
     * @dev Proposes a new dataset for review and potential licensing by the DAO.
     *      This creates a 'DataSetApproval' proposal.
     * @param _dataURI URI to the dataset's details (e.g., IPFS link to dataset, schema, documentation).
     * @param _description A brief description of the dataset for the proposal.
     * @param _ownerAddress The address proposed to be the owner of the Data Asset NFT upon approval.
     */
    function proposeDataSet(string calldata _dataURI, string calldata _description, address _ownerAddress) public onlyStaker nonReentrant {
        require(bytes(_dataURI).length > 0, "CogniDAO: Data URI cannot be empty");
        require(_ownerAddress != address(0), "CogniDAO: Data owner address cannot be zero");

        _dataSetIds.increment();
        uint256 newDataSetId = _dataSetIds.current();

        DataSet storage dataSet = dataSets[newDataSetId];
        dataSet.id = newDataSetId;
        dataSet.dataURI = _dataURI;
        dataSet.owner = _ownerAddress; // Proposed owner, confirmed upon DAO approval
        dataSet.status = DataSetStatus.Proposed;

        // Create a DAO proposal for this dataset's approval
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage p = proposals[newProposalId];
        p.id = newProposalId;
        // Hash unique data to prevent proposal duplication for the same dataset
        p.proposalHash = keccak256(abi.encodePacked("DataSetApproval", newDataSetId, _dataURI, _ownerAddress, block.timestamp));
        p.descriptionURI = _description;
        p.proposer = msg.sender;
        p.proposalType = ProposalType.DataSetApproval;
        p.voteStartTime = block.timestamp;
        p.voteEndTime = block.timestamp.add(votingPeriod);
        p.executed = false;
        p.passed = false;
        p.targetEntityId = newDataSetId;
        p.targetEntityOwner = _ownerAddress;

        emit DataSetProposed(newDataSetId, _ownerAddress, _dataURI);
        emit ProposalSubmitted(newProposalId, msg.sender, ProposalType.DataSetApproval, _description);
    }

    /**
     * @dev Internal function called by `executeProposal` when a DataSetApproval proposal passes.
     *      Mints a Data Asset NFT to the dataset owner and sets the dataset's status to Approved.
     * @param _dataSetId The ID of the dataset to approve.
     */
    function _verifyAndApproveDataSet(uint256 _dataSetId) internal {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.id != 0, "CogniDAO: Dataset does not exist");
        require(dataSet.status == DataSetStatus.Proposed, "CogniDAO: Dataset not in proposed status for approval.");

        dataSet.status = DataSetStatus.Approved;
        uint256 newTokenId = _dataSetIds.current(); // Using current counter for NFT token ID for simplicity

        dataAssetNFT.mint(dataSet.owner, newTokenId, dataSet.dataURI); // Mint the Data Asset NFT
        dataAssetIdToDataSetId[newTokenId] = _dataSetId; // Map the new NFT TokenID to the internal DataSet ID

        emit DataSetVerifiedAndApproved(_dataSetId, newTokenId, dataSet.owner);
    }

    /**
     * @dev Allows a Data Asset owner or other curators to stake CGN for the data's quality and accuracy.
     *      This stake is required for the dataset to enter 'Curated' status and be available for licensing.
     * @param _dataSetId The Token ID of the Data Asset NFT.
     * @param _amount The amount of CGN to stake.
     */
    function stakeForDataSetQuality(uint256 _dataSetId, uint256 _amount) public nonReentrant {
        require(_amount > 0, "CogniDAO: Amount must be greater than zero");
        address dataOwner = dataAssetNFT.ownerOf(_dataSetId);
        require(dataOwner == msg.sender, "CogniDAO: Only Data Asset owner can stake for quality");

        uint256 internalDataSetId = dataAssetIdToDataSetId[_dataSetId];
        DataSet storage dataSet = dataSets[internalDataSetId];
        require(dataSet.id != 0, "CogniDAO: Dataset does not exist for this Data Asset NFT");
        require(dataSet.status == DataSetStatus.Approved || dataSet.status == DataSetStatus.Curated, "CogniDAO: Dataset not in approved or curated state");

        cogniToken.transferFrom(msg.sender, address(this), _amount); // Transfer CGN to contract
        dataSet.stakedQuality = dataSet.stakedQuality.add(_amount);
        dataSet.status = DataSetStatus.Curated; // Dataset becomes curated once quality is staked

        emit DataSetQualityStaked(_dataSetId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to pay a specified CGN licensing fee to gain access or usage rights to an approved Data Asset.
     *      The fee is transferred to the DAO's contract balance.
     *      In a more complex system, a portion could be distributed directly to the data owner.
     * @param _dataSetId The Token ID of the Data Asset NFT.
     * @param _licensingFee The amount of CGN tokens to pay for the license.
     */
    function licenseDataSetAccess(uint256 _dataSetId, uint256 _licensingFee) public nonReentrant {
        require(_licensingFee > 0, "CogniDAO: Licensing fee must be greater than zero");

        uint256 internalDataSetId = dataAssetIdToDataSetId[_dataSetId];
        DataSet storage dataSet = dataSets[internalDataSetId];
        require(dataSet.id != 0, "CogniDAO: Dataset does not exist for this Data Asset NFT");
        require(dataSet.status == DataSetStatus.Curated, "CogniDAO: Dataset not available for licensing (not curated)");
        require(dataSet.stakedQuality > 0, "CogniDAO: Dataset must have staked quality to be licensed");

        cogniToken.transferFrom(msg.sender, address(this), _licensingFee);
        dataSet.totalLicensedRevenue = dataSet.totalLicensedRevenue.add(_licensingFee);

        emit DataSetAccessed(_dataSetId, msg.sender, _licensingFee);
    }

    // --- Staking & Rewards ---

    /**
     * @dev Allows users to stake CGN tokens in the contract to gain voting power in DAO proposals and potentially earn staking rewards.
     * @param _amount The amount of CGN tokens to stake.
     */
    function stakeCGNForVotingRights(uint256 _amount) public nonReentrant {
        require(_amount > 0, "CogniDAO: Amount to stake must be greater than zero");
        cogniToken.transferFrom(msg.sender, address(this), _amount); // Transfer CGN from user to contract
        totalStakedCGN[msg.sender] = totalStakedCGN[msg.sender].add(_amount);
        totalStakedSupply = totalStakedSupply.add(_amount);
        emit CGNStakedForVoting(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their CGN tokens.
     *      Note: A cool-down period or governance vote might be added in a more complex system for security.
     * @param _amount The amount of CGN tokens to unstake.
     */
    function unstakeCGN(uint256 _amount) public nonReentrant {
        require(_amount > 0, "CogniDAO: Amount to unstake must be greater than zero");
        require(totalStakedCGN[msg.sender] >= _amount, "CogniDAO: Insufficient staked amount");
        require(cogniToken.balanceOf(address(this)) >= _amount, "CogniDAO: Insufficient contract balance to unstake");

        totalStakedCGN[msg.sender] = totalStakedCGN[msg.sender].sub(_amount);
        totalStakedSupply = totalStakedSupply.sub(_amount);
        cogniToken.transfer(msg.sender, _amount); // Transfer CGN from contract back to user
        emit CGNUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim accumulated staking rewards.
     *      Reward calculation logic for stakers would be more complex (e.g., based on time staked,
     *      protocol revenue share, inflation schedule). Here, `stakingRewardsAccrued` is a placeholder
     *      that would be updated by internal reward distribution mechanisms.
     */
    function claimStakingRewards() public nonReentrant {
        uint256 rewards = stakingRewardsAccrued[msg.sender];
        require(rewards > 0, "CogniDAO: No rewards available");
        require(cogniToken.balanceOf(address(this)) >= rewards, "CogniDAO: Insufficient contract balance for rewards");

        stakingRewardsAccrued[msg.sender] = 0; // Reset claimed rewards
        cogniToken.transfer(msg.sender, rewards);
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    // --- Oracle Integration ---

    /**
     * @dev Callback function for a trusted oracle to push external performance metrics and usage counts
     *      for deployed AI Agents. This data directly influences model rewards calculations.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     * @param _performanceScore The performance score (e.g., accuracy, utility metric) typically from 0-100.
     * @param _usageCount The number of times the model was observed to be used or triggered.
     */
    function receiveOracleDataFeed(uint256 _aiAgentId, uint256 _performanceScore, uint256 _usageCount) public onlyTrustedOracle {
        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: Model does not exist for this AI Agent NFT");
        require(model.status == ModelStatus.Deployed, "CogniDAO: Model not in deployed status to receive oracle data");
        require(_performanceScore <= 100, "CogniDAO: Performance score must be 0-100");

        // Simple aggregation for performance score (e.g., a running average) and direct sum for usage.
        // In a real system, this would require careful consideration of data freshness, weighting, etc.
        if (model.usageCount > 0) { // If there was prior usage, average it.
            model.performanceScore = (model.performanceScore.add(_performanceScore)).div(2);
        } else { // First data point
            model.performanceScore = _performanceScore;
        }
        model.usageCount = model.usageCount.add(_usageCount);

        emit OracleDataReceived(_aiAgentId, _performanceScore, _usageCount);
    }

    // --- View Functions ---

    /**
     * @dev Returns comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        bytes32 proposalHash,
        string memory descriptionURI,
        address proposer,
        ProposalType proposalType,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool passed,
        uint256 targetEntityId,
        address targetEntityOwner
    ) {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "CogniDAO: Proposal does not exist");
        return (
            p.id,
            p.proposalHash,
            p.descriptionURI,
            p.proposer,
            p.proposalType,
            p.voteStartTime,
            p.voteEndTime,
            p.votesFor,
            p.votesAgainst,
            p.executed,
            p.passed,
            p.targetEntityId,
            p.targetEntityOwner
        );
    }

    /**
     * @dev Returns comprehensive details about a specific deployed AI Agent NFT's underlying model.
     * @param _aiAgentId The Token ID of the AI Agent NFT.
     * @return AIModel details struct.
     */
    function getAIAgentDetails(uint256 _aiAgentId) public view returns (
        uint256 id,
        string memory modelURI,
        address owner,
        ModelStatus status,
        uint256 stakedReliability,
        uint256 totalRewardsEarned,
        uint256 lastClaimTime,
        bytes32 currentZKProofHash,
        bool zkProofVerified,
        uint256 performanceScore,
        uint256 usageCount
    ) {
        uint256 modelId = aiAgentIdToModelId[_aiAgentId];
        require(modelId != 0, "CogniDAO: AI Agent NFT not linked to a model");
        AIModel storage model = aiModels[modelId];
        require(model.id != 0, "CogniDAO: AI Agent not found or not mapped");

        return (
            model.id,
            model.modelURI,
            model.owner,
            model.status,
            model.stakedReliability,
            model.totalRewardsEarned,
            model.lastClaimTime,
            model.currentZKProofHash,
            model.zkProofVerified,
            model.performanceScore,
            model.usageCount
        );
    }

    /**
     * @dev Returns comprehensive details about a specific approved Data Asset NFT's underlying dataset.
     * @param _dataSetId The Token ID of the Data Asset NFT.
     * @return DataSet details struct.
     */
    function getDataSetDetails(uint256 _dataSetId) public view returns (
        uint256 id,
        string memory dataURI,
        address owner,
        DataSetStatus status,
        uint256 stakedQuality,
        uint256 totalLicensedRevenue
    ) {
        uint256 internalDataSetId = dataAssetIdToDataSetId[_dataSetId];
        require(internalDataSetId != 0, "CogniDAO: Data Asset NFT not linked to a dataset");
        DataSet storage dataSet = dataSets[internalDataSetId];
        require(dataSet.id != 0, "CogniDAO: Data Asset not found or not mapped");

        return (
            dataSet.id,
            dataSet.dataURI,
            dataSet.owner,
            dataSet.status,
            dataSet.stakedQuality,
            dataSet.totalLicensedRevenue
        );
    }

    /**
     * @dev Returns the total CGN tokens staked by a specific user for voting rights.
     * @param _user The address of the user.
     * @return The amount of CGN tokens staked by the user.
     */
    function getUserStake(address _user) public view returns (uint256) {
        return totalStakedCGN[_user];
    }
}
```