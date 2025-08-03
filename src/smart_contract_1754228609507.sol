Here's a Solidity smart contract for a "Decentralized Autonomous Collective for AI Model Training & Ownership," named `AetherBrainCollective`. This contract aims to showcase interesting, advanced, creative, and trendy functions by integrating concepts like decentralized AI development, NFT-based model ownership, staking, a simplified dispute resolution system, and basic on-chain governance.

**Key Advanced Concepts & Creativity:**

1.  **AI Model as NFT (`AetherModelNFT`):** Instead of just data, trained AI models themselves are represented as unique, transferable NFTs, establishing provable ownership in a decentralized manner.
2.  **Decentralized Training Workflow:** A structured on-chain workflow for proposing training tasks, compute providers accepting them, submitting off-chain proofs (hashes/references), and validation by an oracle.
3.  **Staking for Participation & Trust:** Participants (proposers, compute providers) stake tokens as collateral, which can be slashed for misbehavior or returned/rewarded for successful contributions. This aligns incentives.
4.  **On-chain Reference to Off-chain Proofs:** Acknowledges the reality of AI training being off-chain, using hashes/URIs as on-chain attestations (e.g., for ZKP references or model integrity hashes).
5.  **Simplified Dispute Resolution:** A mechanism for anyone with sufficient stake to challenge a training or validation result, forcing an arbitration process (simplified to `onlyOwner` for this example, but extensible to DAO vote).
6.  **Dynamic Fee/Reward Curve (Conceptual):** The `setDynamicFeeCurveParameters` function introduces the idea of dynamically adjusting protocol economics based on configurable on-chain parameters, rather than fixed values.
7.  **Lightweight On-chain Governance:** A basic proposal and voting system allowing staked token holders to influence core contract parameters and future upgrades.
8.  **"Non-Duplication" Aspect:** While individual components (ERC20, ERC721, DAO) are common, their unique combination and specific application to the *lifecycle of AI model training and ownership* (from task proposal to NFT minting to dispute resolution) aim to differentiate this from generic open-source projects. The flow and specialized roles are designed to be novel.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in NFT

// --- Outline for AetherBrainCollective Smart Contract ---

// 1. Introduction
//    - Purpose: A decentralized platform for collaborative AI model training, validation, and ownership.
//    - Vision: To foster an open-source, community-driven ecosystem for AI development, where contributions are rewarded and AI models become provably owned digital assets.

// 2. Core Concepts
//    - AetherToken (ERC20): The native utility token used for staking, rewards, and governance.
//    - AetherModelNFT (ERC721): Non-fungible tokens representing unique, validated AI models. Owners have rights to the model.
//    - Datasets: Off-chain data referenced and registered on-chain for training.
//    - Training Tasks: Proposals for AI model training, requiring compute and data contributions.
//    - Compute Providers: Individuals or entities offering computational resources.
//    - Validators/Oracles: Entities responsible for verifying the quality and integrity of trained models.
//    - Staking: Participants stake AetherTokens as collateral or to gain voting power.
//    - Rewards: AetherTokens distributed for successful contributions (proposing, compute, validation).
//    - Dispute Resolution: Mechanisms for challenging and resolving issues in training or validation.

// 3. Contract Structure & Interfaces
//    - `AetherBrainCollective`: The main contract orchestrating tasks, staking, rewards, and NFT minting.
//    - Interfaces for ERC20 (AetherToken) and ERC721 (AetherModelNFT).
//    - Utilizes OpenZeppelin for secure standard patterns (Ownable, Pausable, ReentrancyGuard).

// --- Function Summary ---

// I. Core Administration & Configuration (Owner/DAO Controlled)
//    - `constructor()`: Initializes the contract with initial configurations (owner, admin, fees).
//    - `setAetherToken(address _tokenAddress)`: Sets the address of the AetherToken ERC20 contract.
//    - `setAetherModelNFT(address _nftAddress)`: Sets the address of the AetherModelNFT ERC721 contract and attempts to grant it minting rights.
//    - `setProtocolFeeRecipient(address _recipient)`: Defines the address to receive collected protocol fees.
//    - `setValidationOracleAddress(address _oracleAddress)`: Designates the address of the trusted validation oracle.
//    - `pauseContract()`: Emergency function to pause core operations.
//    - `unpauseContract()`: Resumes operations after pausing.
//    - `withdrawProtocolFees()`: Allows the fee recipient to withdraw accumulated fees.

// II. Dataset & AI Model Lifecycle (On-chain Representation)
//    - `registerDataset(string calldata _metadataURI, bytes32 _dataHash)`: Registers metadata for an off-chain dataset, assigning a unique ID.
//    - `_mintAIModelNFT(address _to, uint256 _modelNFTId, string calldata _tokenURI)`: Internal function; mints a new AetherModelNFT upon successful model validation.
//    - `updateAIModelMetadataURI(uint256 _modelNFTId, string calldata _newUri)`: Allows AetherModelNFT owners to update their model's off-chain metadata URI.
//    - `getAIModelDetails(uint256 _modelNFTId)`: Retrieves on-chain details of a specific AetherModelNFT.
//    - `getDatasetDetails(uint256 _datasetId)`: Retrieves registered details of a dataset by its ID.

// III. Training Task Management & Execution
//    - `proposeTrainingTask(string calldata _modelType, uint256[] calldata _inputDatasetIds, uint256 _rewardAmount, uint256 _proposerStake)`: Initiates a new AI training task, defining requirements and staking rewards.
//    - `acceptTrainingTask(uint256 _taskId, uint256 _computeStake)`: A compute provider commits to a task by staking collateral.
//    - `submitTrainingProof(uint256 _taskId, string calldata _trainingProofHash)`: Compute provider submits proof of off-chain training completion, awaiting validation.

// IV. Validation & Dispute Resolution
//    - `submitValidationResult(uint256 _taskId, bool _success, string calldata _modelNFTUri, uint256 _modelNFTId)`: The validation oracle submits the verdict (success/failure) for a training task.
//    - `challengeTrainingResult(uint256 _taskId)`: Allows staked participants to dispute a training proof or validation result.
//    - `resolveDispute(uint256 _taskId, bool _proposerWins)`: An authorized entity resolves disputes, reallocating stakes and outcomes.

// V. Staking & Rewards
//    - `stakeForContribution(uint256 _amount)`: Users stake AetherToken to participate as a contributor or gain voting power.
//    - `unstakeContribution(uint256 _amount)`: Allows withdrawal of staked tokens after cool-down or task completion.
//    - `claimTaskRewards(uint256 _taskId)`: Allows participants to claim AetherToken rewards and AIModelNFTs for completed tasks.

// VI. Advanced & Governance Concepts (Simplified DAO)
//    - `setDynamicFeeCurveParameters(uint256 _paramA, uint256 _paramB, uint256 _paramC)`: Configures parameters for a dynamic fee/reward calculation curve.
//    - `proposeProtocolUpgrade(ProposalType _pType, bytes calldata _data, string calldata _description)`: Proposes a significant protocol change (e.g., contract upgrade, parameter adjustment).
//    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows staked users to vote on active proposals.
//    - `executeProposal(uint256 _proposalId)`: Executes a passed and timelocked (conceptual) upgrade proposal.

// --- Helper Contracts (for demonstration purposes) ---

// IAetherModelNFT.sol (Interface for AetherModelNFT)
interface IAetherModelNFT is IERC721 {
    function mint(address to, uint256 tokenId, string calldata uri) external;
    function setMinter(address minter) external;
    function updateTokenURI(uint256 tokenId, string calldata _newUri) external;
}

// IAetherToken.sol (Interface for AetherToken)
interface IAetherToken is IERC20 {
    // IERC20 already defines the necessary functions (transfer, transferFrom, approve, allowance, balanceOf, totalSupply).
    // No additional functions needed for this example.
}

// AetherToken.sol (A simple ERC20 implementation for demonstration)
contract AetherToken is Ownable, IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(uint256 initialSupply) Ownable(msg.sender) {
        name = "Aether Token";
        symbol = "AETHER";
        decimals = 18; // Standard for many ERC20 tokens
        totalSupply_ = initialSupply * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            balances[sender] -= amount;
            balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice A simple faucet function to distribute tokens for testing.
    /// @param amount The amount of tokens to mint and send to the caller.
    function faucet(uint256 amount) public {
        require(amount > 0, "Faucet: amount must be > 0");
        totalSupply_ += amount; // This is a simple mint for demonstration.
        balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}

// AetherModelNFT.sol (A simple ERC721 implementation with a minter role)
contract AetherModelNFT is Ownable, IERC721 {
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    address private _minter; // The designated address allowed to mint new tokens

    constructor() Ownable(msg.sender) {
        _name = "Aether AI Model NFT";
        _symbol = "AEMN";
        _minter = msg.sender; // Initial minter is deployer, can be changed by owner.
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Sets the address of the designated minter. Only callable by the contract owner.
    /// @param minterAddress The address to be set as the new minter.
    function setMinter(address minterAddress) public onlyOwner {
        require(minterAddress != address(0), "AEMN: Zero address for minter");
        _minter = minterAddress;
        emit MinterSet(minterAddress);
    }

    event MinterSet(address newMinter);

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /// @notice Allows the owner of a token (or an approved address) to update its metadata URI.
    /// @param tokenId The ID of the token to update.
    /// @param _newUri The new URI pointing to the token's metadata.
    function updateTokenURI(uint256 tokenId, string calldata _newUri) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AEMN: Not owner nor approved to update URI");
        _tokenURIs[tokenId] = _newUri;
        emit URI(tokenURI(tokenId), tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Using ownerOf for proper checks
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // Using ownerOf for proper checks
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approvals for the transferred token

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // Using ownerOf for proper checks
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId); // Using ownerOf for proper checks
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (empty reason)");
                }
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        } else {
            return true;
        }
    }

    /// @notice Mints a new AetherModelNFT. Only callable by the designated minter address.
    /// @param to The address to receive the new NFT.
    /// @param tokenId The unique ID for the new token.
    /// @param uri The metadata URI for the token.
    function mint(address to, uint256 tokenId, string calldata uri) external {
        require(msg.sender == _minter, "AEMN: Only designated minter can mint");
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
        emit URI(uri, tokenId);
    }
}

// Main Contract
contract AetherBrainCollective is Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- State Variables ---

    IAetherToken public aetherToken;
    IAetherModelNFT public aetherModelNFT;
    address public protocolFeeRecipient;
    address public validationOracleAddress;

    // Fee parameters for dynamic fee curve: f(x) = a*x^2 + b*x + c
    // Stored as scaled integers to avoid floats. (e.g., 1e18 for 1.0)
    // For simplicity in _calculateProtocolFee, we'll use dynamicFeeParamB as a basis point percentage.
    uint256 public dynamicFeeParamA; // Coefficient for x^2
    uint256 public dynamicFeeParamB; // Coefficient for x (used as basis point percentage for fee)
    uint256 public dynamicFeeParamC; // Constant term
    uint256 public constant SCALE_FACTOR = 1e18; // For fixed-point arithmetic if full quadratic used.

    uint256 public totalProtocolFeesCollected;

    // Datasets
    struct Dataset {
        uint256 id;
        string metadataURI; // IPFS hash or similar for dataset description
        bytes32 dataHash;   // Cryptographic hash of the dataset
        address owner;      // The address that registered the dataset
        uint64 registeredAt;
    }
    mapping(uint256 => Dataset) public datasets;
    uint256 public nextDatasetId;

    // Training Tasks
    enum TaskStatus {
        Proposed,
        Accepted,
        ProofSubmitted,
        AwaitingValidation,
        ValidatedSuccess,
        ValidatedFailure,
        Disputed,
        Completed,
        Cancelled // Not implemented, but good to have.
    }

    struct TrainingTask {
        uint256 taskId;
        string modelType;           // e.g., "ImageClassification", "NLP", "ReinforcementLearning"
        uint256[] inputDatasetIds;  // IDs of datasets used for training
        address proposer;           // Address that proposed the task
        address computeProvider;    // Address that accepted the task
        uint256 proposerStake;      // Stake from proposer
        uint256 computeStake;       // Stake from compute provider
        uint256 rewardAmount;       // Total AetherToken rewards for this task (before distribution to other parties)
        uint256 protocolFee;        // Fees collected for the protocol from this task
        uint256 modelNFTId;         // Token ID of the minted AI model NFT if successful
        string trainingProofHash;   // Hash/reference to off-chain training proof (e.g., ZKP hash, model hash)
        TaskStatus status;
        uint64 proposedAt;
        uint64 acceptedAt;
        uint64 proofSubmittedAt;
        uint64 validatedAt;
        uint64 completedAt;
        address currentDisputer;    // Who initiated the current dispute (if any)
    }
    mapping(uint256 => TrainingTask) public trainingTasks;
    uint256 public nextTaskId;

    // Staking Pool
    mapping(address => uint256) public stakedContributions; // For general staking pool participants (for voting, challenging)
    mapping(address => uint64) public lastUnstakeRequestTime; // For cool-down period (not fully implemented in this example)

    // Governance Proposals
    enum ProposalType {
        SetAetherToken,
        SetAetherModelNFT,
        SetProtocolFeeRecipient,
        SetValidationOracle,
        SetDynamicFeeCurveParameters,
        CustomUpgrade // Placeholder for more complex upgrade patterns (e.g., UUPS proxy)
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType pType;
        bytes data; // Encoded call data for execution, or parameters for specific types
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;       // Total stake weight of 'for' votes
        uint256 votesAgainst;   // Total stake weight of 'against' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public minStakeForProposal; // Minimum AETHER stake required to create a proposal
    uint256 public votingPeriodBlocks; // Duration of voting in blocks

    // --- Events ---
    event AetherTokenSet(address indexed _tokenAddress);
    event AetherModelNFTSet(address indexed _nftAddress);
    event ProtocolFeeRecipientSet(address indexed _recipient);
    event ValidationOracleSet(address indexed _oracle);
    event DatasetRegistered(uint256 indexed _datasetId, address indexed _owner, string _metadataURI);
    event TrainingTaskProposed(uint256 indexed _taskId, address indexed _proposer, string _modelType, uint256 _rewardAmount);
    event TrainingTaskAccepted(uint256 indexed _taskId, address indexed _computeProvider);
    event TrainingProofSubmitted(uint256 indexed _taskId, string _proofHash);
    event ValidationResultSubmitted(uint256 indexed _taskId, bool _success, address indexed _oracle);
    event ModelNFTMinted(uint256 indexed _taskId, uint256 indexed _modelNFTId, address indexed _owner, string _tokenURI);
    event TaskRewardsClaimed(uint256 indexed _taskId, address indexed _claimer, uint256 _amount);
    event TaskStatusUpdated(uint256 indexed _taskId, TaskStatus _oldStatus, TaskStatus _newStatus);
    event DisputeChallenged(uint256 indexed _taskId, address indexed _challenger);
    event DisputeResolved(uint256 indexed _taskId, address indexed _resolver, bool _proposerWins); // true = proposer wins, false = challenger/compute wins
    event ContributionStaked(address indexed _contributor, uint256 _amount);
    event ContributionUnstaked(address indexed _contributor, uint256 _amount);
    event DynamicFeeCurveParametersSet(uint256 _paramA, uint256 _paramB, uint256 _paramC);
    event ProtocolImprovementProposed(uint256 indexed _proposalId, ProposalType _type, address indexed _proposer, string _description);
    event ProposalVoted(uint252 indexed _proposalId, address indexed _voter, bool _support, uint256 _voteWeight);
    event ProposalExecuted(uint256 indexed _proposalId);

    // --- Modifiers ---
    modifier onlyValidationOracle() {
        require(msg.sender == validationOracleAddress, "ABC: Only the validation oracle can call this function");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the AetherBrainCollective contract.
    /// @param _aetherTokenAddress The address of the AetherToken ERC20 contract.
    /// @param _aetherModelNFTAddress The address of the AetherModelNFT ERC721 contract.
    /// @param _protocolFeeRecipient The address designated to receive protocol fees.
    /// @param _validationOracleAddress The address of the trusted validation oracle.
    constructor(
        address _aetherTokenAddress,
        address _aetherModelNFTAddress,
        address _protocolFeeRecipient,
        address _validationOracleAddress
    ) Ownable(msg.sender) {
        require(_aetherTokenAddress != address(0), "ABC: AetherToken address cannot be zero");
        require(_aetherModelNFTAddress != address(0), "ABC: AetherModelNFT address cannot be zero");
        require(_protocolFeeRecipient != address(0), "ABC: Fee recipient address cannot be zero");
        require(_validationOracleAddress != address(0), "ABC: Validation oracle address cannot be zero");

        aetherToken = IAetherToken(_aetherTokenAddress);
        aetherModelNFT = IAetherModelNFT(_aetherModelNFTAddress);
        protocolFeeRecipient = _protocolFeeRecipient;
        validationOracleAddress = _validationOracleAddress;

        // Attempt to set this contract as the minter on the AetherModelNFT contract.
        // This assumes the deployer of AetherBrainCollective is also the owner/deployer of AetherModelNFT,
        // or has the authority to grant this contract minting rights.
        try aetherModelNFT.setMinter(address(this)) {
            // Minter set successfully. No specific action needed.
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("ABC: Failed to set AetherBrainCollective as NFT minter: ", reason)));
        } catch {
            revert("ABC: Failed to set AetherBrainCollective as NFT minter (unknown error)");
        }

        // Initialize dynamic fee curve parameters.
        // For _calculateProtocolFee, `dynamicFeeParamB` is interpreted as basis points.
        // So, 1000 = 10% (1000/10000).
        dynamicFeeParamA = 0; // No quadratic component initially for fees
        dynamicFeeParamB = 1000; // Example: 10% fee (1000 basis points)
        dynamicFeeParamC = 0; // No constant offset

        // Initial governance parameters
        minStakeForProposal = 1000 * (10 ** 18); // Example: 1000 AETHER tokens (assuming 18 decimals)
        votingPeriodBlocks = 7200; // Example: ~1 day at 12s/block
    }

    // --- I. Core Administration & Configuration ---

    /// @notice Sets the address of the AetherToken ERC20 contract. Only callable by the owner.
    /// @param _tokenAddress The new address for the AetherToken contract.
    function setAetherToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "ABC: Token address cannot be zero");
        aetherToken = IAetherToken(_tokenAddress);
        emit AetherTokenSet(_tokenAddress);
    }

    /// @notice Sets the address of the AetherModelNFT ERC721 contract and grants it minting rights.
    ///         Requires `_nftAddress` to have a `setMinter` function callable by this contract's owner.
    /// @param _nftAddress The new address for the AetherModelNFT contract.
    function setAetherModelNFT(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0), "ABC: NFT address cannot be zero");
        aetherModelNFT = IAetherModelNFT(_nftAddress);
        // Attempt to set this contract as the minter on the new NFT contract
        try aetherModelNFT.setMinter(address(this)) {
            // Minter set successfully.
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("ABC: Failed to set AetherBrainCollective as new NFT minter: ", reason)));
        } catch {
            revert("ABC: Failed to set AetherBrainCollective as new NFT minter (unknown error)");
        }
        emit AetherModelNFTSet(_nftAddress);
    }

    /// @notice Sets the address that receives protocol fees. Only callable by the owner.
    /// @param _recipient The new address for the protocol fee recipient.
    function setProtocolFeeRecipient(address _recipient) public onlyOwner {
        require(_recipient != address(0), "ABC: Recipient address cannot be zero");
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientSet(_recipient);
    }

    /// @notice Sets the address of the trusted validation oracle. Only callable by the owner.
    /// @param _oracleAddress The new address for the validation oracle.
    function setValidationOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ABC: Oracle address cannot be zero");
        validationOracleAddress = _oracleAddress;
        emit ValidationOracleSet(_oracleAddress);
    }

    /// @notice Pauses the contract's core operations. Only callable by the owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract's core operations. Only callable by the owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the designated protocol fee recipient to withdraw accumulated fees.
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "ABC: Only fee recipient can withdraw");
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "ABC: No fees to withdraw");
        totalProtocolFeesCollected = 0; // Reset before transfer to prevent re-entrancy issues (even with nonReentrant)
        aetherToken.transfer(protocolFeeRecipient, amount);
    }

    // --- II. Dataset & AI Model Lifecycle (On-chain Representation) ---

    /// @notice Registers metadata for an off-chain dataset.
    ///         The dataset itself remains off-chain, but its existence and integrity are recorded.
    /// @param _metadataURI A URI pointing to the dataset's description/metadata (e.g., IPFS hash).
    /// @param _dataHash A cryptographic hash (e.g., SHA256) of the dataset content, for integrity verification.
    /// @return The unique ID assigned to the registered dataset.
    function registerDataset(string calldata _metadataURI, bytes32 _dataHash) external whenNotPaused returns (uint256) {
        uint256 currentId = nextDatasetId++;
        datasets[currentId] = Dataset({
            id: currentId,
            metadataURI: _metadataURI,
            dataHash: _dataHash,
            owner: msg.sender,
            registeredAt: uint64(block.timestamp)
        });
        emit DatasetRegistered(currentId, msg.sender, _metadataURI);
        return currentId;
    }

    /// @notice Internal function to mint a new AetherModelNFT.
    ///         Only callable by this contract, typically after a successful training and validation.
    /// @param _to The address to receive the NFT.
    /// @param _modelNFTId The desired token ID for the new NFT.
    /// @param _tokenURI The URI pointing to the model's metadata (e.g., IPFS hash for model weights, description).
    function _mintAIModelNFT(address _to, uint256 _modelNFTId, string calldata _tokenURI) internal {
        aetherModelNFT.mint(_to, _modelNFTId, _tokenURI);
    }

    /// @notice Allows the owner of an AetherModelNFT to update its metadata URI.
    ///         This enables updating off-chain links (e.g., if model weights are moved).
    /// @param _modelNFTId The ID of the AetherModelNFT.
    /// @param _newUri The new URI for the model's metadata.
    function updateAIModelMetadataURI(uint256 _modelNFTId, string calldata _newUri) external whenNotPaused {
        require(aetherModelNFT.ownerOf(_modelNFTId) == msg.sender, "ABC: Not the owner of this NFT");
        aetherModelNFT.updateTokenURI(_modelNFTId, _newUri);
    }

    /// @notice Retrieves on-chain details for a specific AI model NFT.
    ///         This links the NFT back to its training task and associated metadata.
    /// @param _modelNFTId The ID of the AetherModelNFT.
    /// @return modelType, inputDatasetIds, trainingProofHash, owner, status, rewardAmount, proposer, computeProvider
    function getAIModelDetails(uint256 _modelNFTId)
        public view
        returns (string memory modelType, uint256[] memory inputDatasetIds, string memory trainingProofHash, address owner, TaskStatus status, uint256 rewardAmount, address proposer, address computeProvider)
    {
        // Iterate through tasks to find the one that minted this NFT. Not efficient for many tasks.
        // A direct mapping `modelNFTId => taskId` could be added for better performance if needed.
        for (uint256 i = 0; i < nextTaskId; i++) {
            if (trainingTasks[i].modelNFTId == _modelNFTId) {
                TrainingTask storage task = trainingTasks[i];
                return (task.modelType, task.inputDatasetIds, task.trainingProofHash, aetherModelNFT.ownerOf(_modelNFTId), task.status, task.rewardAmount, task.proposer, task.computeProvider);
            }
        }
        revert("ABC: Model NFT details not found or not associated with a task.");
    }

    /// @notice Retrieves registered details of a dataset by its ID.
    /// @param _datasetId The ID of the dataset.
    /// @return metadataURI, dataHash, owner, registeredAt
    function getDatasetDetails(uint256 _datasetId)
        public view
        returns (string memory metadataURI, bytes32 dataHash, address owner, uint64 registeredAt)
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.id == _datasetId, "ABC: Dataset not found"); // Ensure it's a valid, existing ID
        return (dataset.metadataURI, dataset.dataHash, dataset.owner, dataset.registeredAt);
    }

    // --- III. Training Task Management & Execution ---

    /// @notice Proposes a new AI training task, defining requirements and staking rewards.
    ///         The proposer stakes tokens as collateral for the task's validity.
    /// @param _modelType Type of AI model to be trained (e.g., "ImageClassification", "NLP").
    /// @param _inputDatasetIds Array of registered dataset IDs to be used for training.
    /// @param _rewardAmount Total AetherToken reward for successful completion (to be distributed).
    /// @param _proposerStake Amount of AetherToken staked by the proposer.
    function proposeTrainingTask(
        string calldata _modelType,
        uint256[] calldata _inputDatasetIds,
        uint256 _rewardAmount,
        uint256 _proposerStake
    ) external whenNotPaused nonReentrant {
        require(_inputDatasetIds.length > 0, "ABC: Must specify at least one dataset");
        require(_rewardAmount > 0, "ABC: Reward amount must be greater than zero");
        require(_proposerStake > 0, "ABC: Proposer must stake tokens");
        require(aetherToken.transferFrom(msg.sender, address(this), _proposerStake), "ABC: Proposer token transfer failed");

        // Validate that all specified datasets are registered.
        for (uint256 i = 0; i < _inputDatasetIds.length; i++) {
            require(datasets[_inputDatasetIds[i]].id == _inputDatasetIds[i], "ABC: One or more datasets not found");
        }

        uint256 currentId = nextTaskId++;
        uint256 fee = _calculateProtocolFee(_rewardAmount); // Calculate fee based on reward amount
        totalProtocolFeesCollected += fee;

        trainingTasks[currentId] = TrainingTask({
            taskId: currentId,
            modelType: _modelType,
            inputDatasetIds: _inputDatasetIds,
            proposer: msg.sender,
            computeProvider: address(0), // No compute provider yet
            proposerStake: _proposerStake,
            computeStake: 0,
            rewardAmount: _rewardAmount,
            protocolFee: fee,
            modelNFTId: 0, // Will be assigned upon successful validation
            trainingProofHash: "",
            status: TaskStatus.Proposed,
            proposedAt: uint64(block.timestamp),
            acceptedAt: 0,
            proofSubmittedAt: 0,
            validatedAt: 0,
            completedAt: 0,
            currentDisputer: address(0)
        });

        emit TrainingTaskProposed(currentId, msg.sender, _modelType, _rewardAmount);
    }

    /// @notice A compute provider accepts a proposed training task by staking collateral.
    ///         This commits them to performing the training work.
    /// @param _taskId The ID of the training task to accept.
    /// @param _computeStake The amount of AetherToken staked by the compute provider as collateral.
    function acceptTrainingTask(uint256 _taskId, uint256 _computeStake) external whenNotPaused nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TaskStatus.Proposed, "ABC: Task is not in Proposed status");
        require(msg.sender != task.proposer, "ABC: Proposer cannot be compute provider for their own task");
        require(_computeStake > 0, "ABC: Compute provider must stake tokens");
        require(aetherToken.transferFrom(msg.sender, address(this), _computeStake), "ABC: Compute provider token transfer failed");

        task.computeProvider = msg.sender;
        task.computeStake = _computeStake;
        task.status = TaskStatus.Accepted;
        task.acceptedAt = uint64(block.timestamp);

        emit TrainingTaskAccepted(_taskId, msg.sender);
        emit TaskStatusUpdated(_taskId, TaskStatus.Proposed, TaskStatus.Accepted);
    }

    /// @notice The compute provider submits a cryptographic proof (e.g., hash of results, ZKP reference)
    ///         of off-chain training completion. This transitions the task to "awaiting validation".
    /// @param _taskId The ID of the training task.
    /// @param _trainingProofHash The hash or reference to the off-chain proof artifact.
    function submitTrainingProof(uint256 _taskId, string calldata _trainingProofHash) external whenNotPaused {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TaskStatus.Accepted, "ABC: Task is not in Accepted status");
        require(msg.sender == task.computeProvider, "ABC: Only the assigned compute provider can submit proof");
        require(bytes(_trainingProofHash).length > 0, "ABC: Training proof hash cannot be empty");

        task.trainingProofHash = _trainingProofHash;
        task.status = TaskStatus.ProofSubmitted;
        task.proofSubmittedAt = uint64(block.timestamp);

        emit TrainingProofSubmitted(_taskId, _trainingProofHash);
        emit TaskStatusUpdated(_taskId, TaskStatus.Accepted, TaskStatus.ProofSubmitted);
    }

    // --- IV. Validation & Dispute Resolution ---

    /// @notice The designated validation oracle submits the verdict (success/failure) for a training task.
    ///         Triggers reward distribution or slashing based on the outcome.
    /// @param _taskId The ID of the training task.
    /// @param _success True if the validation was successful, false otherwise.
    /// @param _modelNFTUri The URI for the new AI model NFT, if validation is successful.
    /// @param _modelNFTId The token ID for the new AI model NFT, if validation is successful. Must be unique.
    function submitValidationResult(uint256 _taskId, bool _success, string calldata _modelNFTUri, uint256 _modelNFTId)
        external
        onlyValidationOracle
        whenNotPaused
        nonReentrant
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted || task.status == TaskStatus.Disputed, "ABC: Task not in ProofSubmitted or Disputed status");
        require(task.computeProvider != address(0), "ABC: Task has no compute provider"); // Should always be set for these statuses

        task.validatedAt = uint64(block.timestamp);

        if (_success) {
            require(bytes(_modelNFTUri).length > 0, "ABC: Model NFT URI must be provided for successful validation");
            require(_modelNFTId > 0, "ABC: Model NFT ID must be provided and unique for successful validation");
            require(aetherModelNFT.ownerOf(_modelNFTId) == address(0), "ABC: Model NFT ID already exists"); // Check for uniqueness

            task.status = TaskStatus.ValidatedSuccess;
            task.modelNFTId = _modelNFTId;
            // The proposer receives the minted NFT, as they initiated the task to get a model.
            _mintAIModelNFT(task.proposer, _modelNFTId, _modelNFTUri);
            emit ModelNFTMinted(_taskId, _modelNFTId, task.proposer, _modelNFTUri);

            // Reward distribution logic: Simplified example shares
            uint256 rewardPool = task.rewardAmount; // Total allocated for rewards by proposer
            uint256 computeReward = (rewardPool * 40) / 100; // Example: 40% for compute provider
            uint256 oracleReward = (rewardPool * 10) / 100;  // Example: 10% for validation oracle
            uint256 proposerShare = rewardPool - computeReward - oracleReward; // Remaining for proposer (claimed via claimTaskRewards)

            // Return stakes and distribute rewards
            aetherToken.transfer(task.computeProvider, task.computeStake + computeReward); // Return compute stake + reward
            aetherToken.transfer(validationOracleAddress, oracleReward); // Oracle reward
            // Proposer's stake is retained within the contract to fund their share and is returned when they claim rewards.
            task.rewardAmount = proposerShare; // Update task's rewardAmount to represent only proposer's remaining claimable reward

            emit TaskStatusUpdated(_taskId, task.status == TaskStatus.Disputed ? TaskStatus.Disputed : TaskStatus.ProofSubmitted, TaskStatus.ValidatedSuccess);
            emit ValidationResultSubmitted(_taskId, true, msg.sender);

        } else { // Validation failed
            task.status = TaskStatus.ValidatedFailure;

            // Slashing: Penalize compute provider for failed training, and proposer for a bad task (if applicable).
            uint256 penaltyToCompute = (task.computeStake * 50) / 100; // 50% of compute stake slashed
            uint256 penaltyToProposer = (task.proposerStake * 10) / 100; // 10% of proposer stake slashed

            // Return remaining stakes to participants
            aetherToken.transfer(task.computeProvider, task.computeStake - penaltyToCompute);
            aetherToken.transfer(task.proposer, task.proposerStake - penaltyToProposer);

            // Slashed amounts go to the protocol's fee treasury.
            totalProtocolFeesCollected += penaltyToCompute + penaltyToProposer;
            task.rewardAmount = 0; // No rewards to claim

            emit TaskStatusUpdated(_taskId, task.status == TaskStatus.Disputed ? TaskStatus.Disputed : TaskStatus.ProofSubmitted, TaskStatus.ValidatedFailure);
            emit ValidationResultSubmitted(_taskId, false, msg.sender);
        }
        task.completedAt = uint64(block.timestamp); // Task is now resolved
    }

    /// @notice Allows any staked participant to challenge a training proof or validation result.
    ///         Requires a minimum stake (`minStakeForProposal`) to initiate a dispute, which acts as collateral.
    /// @param _taskId The ID of the training task to challenge.
    function challengeTrainingResult(uint256 _taskId) external whenNotPaused nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(
            task.status == TaskStatus.ProofSubmitted ||
            task.status == TaskStatus.ValidatedSuccess ||
            task.status == TaskStatus.ValidatedFailure,
            "ABC: Task not in a valid state to be challenged"
        );
        require(stakedContributions[msg.sender] >= minStakeForProposal, "ABC: Insufficient stake to challenge"); // Re-use minStakeForProposal for challenger's stake

        require(task.currentDisputer == address(0), "ABC: Task is already under active dispute"); // Prevent multiple simultaneous challenges

        // Take the dispute stake from challenger as collateral.
        uint256 disputeStakeAmount = minStakeForProposal;
        require(aetherToken.transferFrom(msg.sender, address(this), disputeStakeAmount), "ABC: Challenger token transfer failed");

        task.currentDisputer = msg.sender;
        task.status = TaskStatus.Disputed; // Set task status to Disputed

        emit DisputeChallenged(_taskId, msg.sender);
        emit TaskStatusUpdated(_taskId, task.status, TaskStatus.Disputed);
    }

    /// @notice An authorized entity (e.g., DAO vote, multi-sig, or specific arbiter) resolves a dispute.
    ///         Redistributes staked funds based on the dispute outcome.
    ///         For this example, only the contract owner can resolve disputes.
    /// @param _taskId The ID of the task under dispute.
    /// @param _proposerWins True if the proposer/original result is upheld; false if the challenger wins.
    function resolveDispute(uint256 _taskId, bool _proposerWins) external onlyOwner whenNotPaused nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TaskStatus.Disputed, "ABC: Task is not in Disputed status");
        require(task.currentDisputer != address(0), "ABC: No active dispute on this task");

        address challenger = task.currentDisputer;
        uint256 disputeStake = minStakeForProposal; // The amount of stake taken from the challenger

        if (_proposerWins) {
            // Proposer/original result is upheld. Challenger loses their stake.
            totalProtocolFeesCollected += disputeStake; // Slashed amount goes to protocol treasury.
            // Revert task status to its previous validated state if it was validated.
            if (task.validatedAt > 0) {
                 task.status = task.modelNFTId > 0 ? TaskStatus.ValidatedSuccess : TaskStatus.ValidatedFailure;
            } else { // If dispute happened after proof submission but before validation
                 task.status = TaskStatus.ProofSubmitted;
            }

        } else {
            // Challenger wins. Challenger gets their stake back.
            aetherToken.transfer(challenger, disputeStake);
            // If challenger wins, the original validation is deemed incorrect.
            // The task status reverts to `ProofSubmitted` to allow re-validation.
            task.status = TaskStatus.ProofSubmitted;
            // Additional slashing for original oracle/compute could be implemented here for a more robust system.
        }

        task.currentDisputer = address(0); // Clear the current disputer
        emit DisputeResolved(_taskId, msg.sender, _proposerWins);
        emit TaskStatusUpdated(_taskId, TaskStatus.Disputed, task.status);
    }

    // --- V. Staking & Rewards ---

    /// @notice Allows users to stake AetherToken to participate as a general contributor or gain voting power.
    /// @param _amount The amount of AetherToken to stake.
    function stakeForContribution(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "ABC: Amount to stake must be greater than zero");
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "ABC: Staking token transfer failed");
        stakedContributions[msg.sender] += _amount;
        emit ContributionStaked(msg.sender, _amount);
    }

    /// @notice Allows users to withdraw their staked tokens.
    ///         A real system might implement a cool-down period or task-specific locking.
    /// @param _amount The amount of AetherToken to unstake.
    function unstakeContribution(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "ABC: Amount to unstake must be greater than zero");
        require(stakedContributions[msg.sender] >= _amount, "ABC: Insufficient staked balance");

        // Simple unstaking. For production, consider checking if funds are locked in active tasks/disputes.
        // E.g., `require(lastUnstakeRequestTime[msg.sender] + UNSTAKE_COOL_DOWN_PERIOD < block.timestamp, "ABC: Unstake cooldown active");`

        stakedContributions[msg.sender] -= _amount;
        aetherToken.transfer(msg.sender, _amount);
        emit ContributionUnstaked(msg.sender, _amount);
    }

    /// @notice Allows participants to claim AetherToken rewards for completed tasks.
    ///         The proposer claims their share of the reward pool.
    /// @param _taskId The ID of the completed task.
    function claimTaskRewards(uint256 _taskId) external nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TaskStatus.ValidatedSuccess, "ABC: Task not successfully validated");
        require(task.proposer == msg.sender, "ABC: Only the proposer can claim the remaining rewards");
        require(task.rewardAmount > 0, "ABC: No rewards to claim or already claimed"); // task.rewardAmount holds the proposer's share after distribution

        uint256 rewardsToClaim = task.rewardAmount;
        task.rewardAmount = 0; // Set to zero to prevent re-claiming

        aetherToken.transfer(msg.sender, rewardsToClaim);
        emit TaskRewardsClaimed(_taskId, msg.sender, rewardsToClaim);

        // The AI Model NFT is minted to the proposer directly in `submitValidationResult`, so no transfer here.
    }

    // --- VI. Advanced & Governance Concepts ---

    /// @notice Configures parameters for a dynamic fee/reward calculation curve.
    ///         The curve is intended to be a quadratic equation: `fee = (A * value^2 + B * value + C)`.
    ///         For simplicity in `_calculateProtocolFee`, `dynamicFeeParamB` is used as a basis point percentage.
    /// @param _paramA Coefficient for x^2, typically scaled.
    /// @param _paramB Coefficient for x, intended here as basis points (e.g., 100 for 1%).
    /// @param _paramC Constant term.
    function setDynamicFeeCurveParameters(uint256 _paramA, uint256 _paramB, uint256 _paramC) public onlyOwner {
        dynamicFeeParamA = _paramA;
        dynamicFeeParamB = _paramB;
        dynamicFeeParamC = _paramC;
        emit DynamicFeeCurveParametersSet(_paramA, _paramB, _paramC);
    }

    /// @dev Internal helper function to calculate protocol fees based on a simplified dynamic curve.
    ///      Currently, it uses `dynamicFeeParamB` as a percentage in basis points.
    ///      Example: if `_value` is 1000 and `dynamicFeeParamB` is 100 (1%), fee is 10.
    /// @param _value The base value for fee calculation (e.g., the reward amount).
    /// @return The calculated protocol fee.
    function _calculateProtocolFee(uint256 _value) internal view returns (uint256) {
        // Simplified: using dynamicFeeParamB as basis points percentage (e.g., 1000 for 10%)
        // A more complex quadratic calculation could be:
        // uint256 aTerm = (dynamicFeeParamA * _value) / SCALE_FACTOR;
        // aTerm = (aTerm * _value) / SCALE_FACTOR;
        // uint256 bTerm = (dynamicFeeParamB * _value) / SCALE_FACTOR;
        // uint256 cTerm = dynamicFeeParamC;
        // return (aTerm + bTerm + cTerm) / SOME_NORMALIZATION_FACTOR;

        // Current simplified implementation:
        return (_value * dynamicFeeParamB) / 10000; // paramB is in basis points
    }

    /// @notice Proposes a significant protocol change (e.g., contract upgrade, parameter adjustment).
    ///         Requires a minimum stake (`minStakeForProposal`) from the proposer.
    /// @param _pType The type of proposal (e.g., SetValidationOracle, CustomUpgrade).
    /// @param _data Encoded call data for execution, or parameters for specific types.
    /// @param _description A human-readable description of the proposal.
    function proposeProtocolUpgrade(
        ProposalType _pType,
        bytes calldata _data,
        string calldata _description
    ) external whenNotPaused nonReentrant {
        require(stakedContributions[msg.sender] >= minStakeForProposal, "ABC: Insufficient stake to propose");

        uint256 currentId = nextProposalId++;
        proposals[currentId] = Proposal({
            proposalId: currentId,
            pType: _pType,
            data: _data,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            // hasVoted mapping is initialized with default values for new keys
            executed: false
        });

        emit ProtocolImprovementProposed(currentId, _pType, msg.sender, _description);
    }

    /// @notice Allows staked users to vote on active proposals.
    ///         Vote weight is proportional to the user's staked `AetherToken` balance.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' the proposal, False for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "ABC: Proposal not found");
        require(block.number >= proposal.startBlock && block.number < proposal.endBlock, "ABC: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "ABC: Already voted on this proposal");
        uint256 voteWeight = stakedContributions[msg.sender];
        require(voteWeight > 0, "ABC: Must have staked tokens to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @notice Executes a passed and time-locked (conceptually) upgrade proposal.
    ///         Requires the voting period to be over and the proposal to have passed by simple majority.
    ///         Note: A real DAO would typically involve a timelock contract for security.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "ABC: Proposal not found");
        require(block.number >= proposal.endBlock, "ABC: Voting period not ended");
        require(!proposal.executed, "ABC: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "ABC: Proposal did not pass");

        proposal.executed = true; // Mark as executed to prevent re-execution

        // Execute the proposed change based on its type
        if (proposal.pType == ProposalType.SetAetherToken) {
            address newTokenAddress = abi.decode(proposal.data, (address));
            setAetherToken(newTokenAddress); // Calls the owner-only function
        } else if (proposal.pType == ProposalType.SetAetherModelNFT) {
            address newNFTAddress = abi.decode(proposal.data, (address));
            setAetherModelNFT(newNFTAddress); // Calls the owner-only function
        } else if (proposal.pType == ProposalType.SetProtocolFeeRecipient) {
            address newRecipient = abi.decode(proposal.data, (address));
            setProtocolFeeRecipient(newRecipient); // Calls the owner-only function
        } else if (proposal.pType == ProposalType.SetValidationOracle) {
            address newOracle = abi.decode(proposal.data, (address));
            setValidationOracleAddress(newOracle); // Calls the owner-only function
        } else if (proposal.pType == ProposalType.SetDynamicFeeCurveParameters) {
            (uint256 a, uint256 b, uint256 c) = abi.decode(proposal.data, (uint256, uint256, uint256));
            setDynamicFeeCurveParameters(a, b, c); // Calls the owner-only function
        } else if (proposal.pType == ProposalType.CustomUpgrade) {
            // For true contract upgrades (e.g., changing the logic of the entire contract),
            // this would typically involve a proxy pattern (like UUPS).
            // This example doesn't implement the proxy part, so this type is a placeholder.
            // In a UUPS system, `proposal.data` would contain the address of the new logic contract.
            // The `upgradeTo()` function of the proxy would be called here.
            revert("ABC: CustomUpgrade requires a proxy contract implementation not provided in this example.");
        } else {
            revert("ABC: Unknown proposal type");
        }

        emit ProposalExecuted(_proposalId);
    }
}
```