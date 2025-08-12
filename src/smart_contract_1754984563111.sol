This smart contract, **AetherMindCollective**, envisions a decentralized organization for the collaborative creation, validation, and monetization of "Knowledge Modules" (KMs). These KMs are represented as dynamic Non-Fungible Tokens (NFTs), whose properties evolve based on their on-chain validation status and performance. The contract integrates a robust on-chain reputation system, staking mechanisms for participation, a unique "Cognitive Fusion" capability for merging KMs, and a comprehensive decentralized governance framework.

This contract is designed to be self-contained for demonstration purposes, including minimal ERC20-like (`AetherToken`) and ERC721-like (`KnowledgeModuleNFT`) functionalities directly within the main contract to meet the function count requirement without duplicating external libraries. In a production environment, these token standards would typically be separate, audited contracts (e.g., from OpenZeppelin).

---

## Contract: `AetherMindCollective`

**Purpose:** A decentralized autonomous organization (DAO) for the collaborative creation, validation, and monetization of "Knowledge Modules" (KMs), represented as dynamic Non-Fungible Tokens (NFTs). It features an on-chain reputation system, staking mechanisms, and advanced governance.

**Core Concepts:**
*   **Knowledge Modules (KMs):** Dynamic ERC721-like NFTs representing distinct pieces of knowledge, AI models, or data sets. Their visual/metadata can evolve based on on-chain validation and performance metrics.
*   **Reputation System:** An on-chain scoring mechanism for contributors and validators, influencing their privileges, responsibilities, and reward distribution within the collective.
*   **Validation & Curation:** A decentralized process where staked validators assess and approve submitted KMs, ensuring quality and accuracy.
*   **Cognitive Fusion:** A unique, advanced mechanism allowing the logical merging of compatible KMs into a new, more sophisticated KM NFT, representing compound knowledge.
*   **Decentralized Governance:** A robust voting system empowering `AetherToken` holders to manage protocol parameters, propose and approve upgrades, and allocate treasury funds.
*   **Monetization:** KMs can be rented or licensed for use, generating revenue for their creators and contributing to the collective treasury.

---

### Function Summary:

**I. Core Contract & System Management (6 Functions)**
1.  `constructor()`: Initializes the contract with essential parameters, deploys the initial `AetherToken` supply, and sets up governance.
2.  `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows governance to update various system parameters (e.g., stake amounts, voting thresholds, cooldown periods).
3.  `pause()`: Pauses all critical operations in case of emergency (callable by governance).
4.  `unpause()`: Unpauses the contract after an emergency (callable by governance).
5.  `withdrawProtocolFees(address _tokenAddress, address _recipient, uint256 _amount)`: Allows governance to withdraw accumulated protocol fees (from KM rentals, etc.) to a specified address.
6.  `setOracleAddress(address _newOracle)`: Sets the address of the trusted oracle responsible for feeding external data (e.g., KM performance scores).

**II. AetherToken (ERC20-like Internal Implementation) (7 Functions)**
7.  `totalSupply()`: Returns the total supply of AetherTokens.
8.  `balanceOf(address account)`: Returns the AetherToken balance of an account.
9.  `transfer(address recipient, uint256 amount)`: Transfers AetherTokens from the caller to a recipient.
10. `allowance(address owner, address spender)`: Returns the allowance granted by an owner to a spender.
11. `approve(address spender, uint256 amount)`: Allows a spender to withdraw a specified amount of tokens from the caller's account.
12. `transferFrom(address sender, address recipient, uint256 amount)`: Transfers AetherTokens from one address to another using the allowance mechanism.
13. `_mint(address account, uint256 amount)`: Internal function to mint new AetherTokens (used by governance or specific protocol functions).
14. `_burn(address account, uint256 amount)`: Internal function to burn AetherTokens.

**III. Knowledge Module (KM) NFT (ERC721-like Internal Implementation) (11 Functions)**
15. `balanceOf(address owner)`: Returns the number of KMs owned by a given address.
16. `ownerOf(uint256 tokenId)`: Returns the owner of a specific KM NFT.
17. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Transfers ownership of a KM safely, checking if the recipient can receive NFTs.
18. `safeTransferFrom(address from, address to, uint256 tokenId)`: Overloaded `safeTransferFrom` without additional data.
19. `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a KM without recipient checks.
20. `approve(address to, uint256 tokenId)`: Approves an address to take ownership of a specific KM.
21. `setApprovalForAll(address operator, bool approved)`: Enables or disables an operator to manage all KMs owned by the caller.
22. `getApproved(uint256 tokenId)`: Returns the approved address for a single KM.
23. `isApprovedForAll(address owner, address operator)`: Returns if an operator is approved for all KMs of an owner.
24. `tokenURI(uint256 tokenId)`: **Dynamic:** Generates a metadata URI for a KM NFT based on its current on-chain state (validation, performance, fusion status).
25. `_safeMint(address to, uint256 tokenId, string memory uri)`: Internal function to safely mint a new KM NFT.
26. `_burn(uint256 tokenId)`: Internal function to burn an existing KM NFT.

**IV. Knowledge Module (KM) Specific Management (8 Functions)**
27. `submitKnowledgeModule(string calldata _initialMetadataURI, bytes32 _hashedContentId)`: Mints a new KM NFT, requires a stake from the submitter, and records its initial state for validation.
28. `updateKnowledgeModuleMetadata(uint256 _tokenId, string calldata _newBaseMetadataURI)`: Allows the KM owner to update the *base* metadata URI for their KM, influencing its dynamic `tokenURI`.
29. `listKnowledgeModuleForRent(uint256 _tokenId, uint256 _pricePerUse, uint256 _maxUses)`: Owner lists their KM for rental, setting terms (price per use, maximum uses).
30. `rentKnowledgeModule(uint256 _tokenId, uint256 _numUses)`: Allows a user to rent a listed KM for a specified number of uses, paying the required fee to the KM owner and collective.
31. `delistKnowledgeModuleForRent(uint256 _tokenId)`: Owner removes their KM from the rental market.
32. `retireKnowledgeModule(uint256 _tokenId)`: Allows a KM owner to retire (effectively burn) their KM, potentially after a cooldown or by forfeiting a portion of their initial stake.
33. `proposeCognitiveFusion(uint256 _tokenId1, uint256 _tokenId2, string calldata _newMetadataURI)`: Proposes a merge of two existing KMs into a new, more complex one. Requires community or validator approval through governance.
34. `executeCognitiveFusion(uint256 _fusionProposalId)`: Executes a successfully approved cognitive fusion proposal, minting a new combined KM and updating the state of the original KMs.

**V. Reputation & Validation System (7 Functions)**
35. `stakeForValidationRole(uint256 _amount)`: Allows a user to stake `AetherTokens` to become a potential KM validator, gaining voting power in KM validation.
36. `unstakeFromValidationRole()`: Allows a validator to unstake their `AetherTokens` and exit the role after a defined cooldown period.
37. `voteOnKnowledgeModuleValidity(uint256 _tokenId, bool _isValid)`: Staked validators cast a vote on the validity, quality, or accuracy of a newly submitted or challenged KM.
38. `challengeKnowledgeModuleValidity(uint256 _tokenId, string calldata _reason)`: Allows any user to challenge the current validation status or reported performance of a KM, potentially triggering a re-validation process.
39. `recordKnowledgeModulePerformance(uint256 _tokenId, uint256 _performanceScore, bytes calldata _oracleSignature)`: Oracle-fed function to update a KM's verified performance score, which impacts its dynamic NFT properties and potential rewards for its owner.
40. `slashValidatorStake(address _validatorAddress, uint256 _amount, string calldata _reason)`: Allows governance to slash a validator's stake for documented malicious or consistently incorrect validation actions.
41. `distributeValidationRewards(uint256 _tokenId)`: Distributes `AetherToken` rewards to validators who accurately voted on a KM's final validated status.

**VI. Decentralized Governance & Treasury (7 Functions)**
42. `proposeGovernanceAction(bytes32 _actionType, bytes calldata _actionData, string calldata _description)`: Allows a qualified user (e.g., with sufficient `AetherToken` stake) to submit a new governance proposal for community vote.
43. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows `AetherToken` holders to cast their votes (based on their token balance) on active governance proposals.
44. `executeGovernanceProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal, enacting the proposed changes (e.g., parameter updates, contract upgrades).
45. `delegateVote(address _delegatee)`: Allows `AetherToken` holders to delegate their voting power to another address.
46. `redeemVoteWeight()`: Allows a user to undelegate their voting power, making it available for their own direct voting again.
47. `claimGovernanceReward(uint256 _proposalId)`: Allows users who voted on a successfully executed proposal to claim a small `AetherToken` reward for participation.
48. `depositToTreasury()`: Allows any user or external protocol to voluntarily deposit `AetherTokens` or other supported tokens into the collective's treasury, increasing shared resources.

**VII. Information & Public Access (3 Functions)**
49. `getUserReputationScore(address _user)`: Returns the current on-chain reputation score of a given user, reflecting their contributions and validation accuracy.
50. `getKMValidationStatus(uint256 _tokenId)`: Returns the current validation status (e.g., 'pending', 'validated', 'challenged') and score of a Knowledge Module.
51. `getKMCurrentRentInfo(uint256 _tokenId)`: Returns the current rental price, maximum uses, and remaining uses of a KM if it's listed for rent.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial deployment, will transition to DAO governance

// Using reentrancy guard, though minimal in this example, it's a good practice
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Dummy interface for a potential external oracle, actual implementation would be more complex
interface IOracle {
    function verifySignature(bytes32 hash, bytes calldata signature) external view returns (address);
}

/**
 * @title AetherMindCollective
 * @dev A decentralized autonomous organization (DAO) for the collaborative creation, validation,
 * and monetization of "Knowledge Modules" (KMs) as dynamic NFTs. It features an on-chain reputation
 * system, staking, cognitive fusion, and robust governance.
 *
 * This contract is designed to be self-contained, including minimal ERC20-like (AetherToken) and
 * ERC721-like (KnowledgeModuleNFT) functionalities directly within the main contract for demonstration.
 * In a production environment, these token standards would typically be separate, audited contracts.
 */
contract AetherMindCollective is Context, Ownable, ReentrancyGuard {

    // --- Events ---
    event AetherTokenMinted(address indexed account, uint256 amount);
    event AetherTokenBurned(address indexed account, uint256 amount);
    event AetherTokenTransfer(address indexed from, address indexed to, uint256 amount);
    event AetherTokenApproval(address indexed owner, address indexed spender, uint256 value);

    event KMMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event KMMetadataUpdated(uint256 indexed tokenId, string newURI);
    event KMTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event KMApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event KMApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event KMListedForRent(uint256 indexed tokenId, uint256 pricePerUse, uint256 maxUses);
    event KMRented(uint256 indexed tokenId, address indexed renter, uint256 numUses, uint256 totalCost);
    event KMDelistedFromRent(uint256 indexed tokenId);
    event KMRetired(uint256 indexed tokenId);

    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event OracleAddressUpdated(address indexed newOracle);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event KMValidityVoted(uint256 indexed tokenId, address indexed validator, bool isValid);
    event KMValidityChallenged(uint256 indexed tokenId, address indexed challenger, string reason);
    event KMPerformanceRecorded(uint256 indexed tokenId, uint256 performanceScore, address indexed oracle);
    event ValidatorStakeSlashed(address indexed validator, uint256 amount, string reason);
    event ValidationRewardsDistributed(uint256 indexed tokenId, uint256 totalRewards);

    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 indexed actionType, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteRedeemed(address indexed delegator);
    event GovernanceRewardClaimed(address indexed claimant, uint256 indexed proposalId, uint256 amount);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    
    // --- Custom Error Definitions ---
    error ZeroAddress();
    error NotEnoughBalance();
    error ApprovalFailed();
    error InvalidAmount();
    error NotApprovedOrOwner();
    error TokenDoesNotExist();
    error TokenAlreadyExists();
    error Unauthorized();
    error PauseStateConflict();
    error InvalidParameter();
    error AlreadyStaked();
    error NotAValidator();
    error CooldownPeriodNotPassed();
    error KMNotInValidation();
    error AlreadyVoted();
    error InsufficientReputation();
    error NotKMOwner();
    error KMNotListedForRent();
    error RentDurationTooLow();
    error InvalidSignature();
    error OracleNotSet();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error AlreadyVotedOnProposal();
    error SelfDelegationNotAllowed();
    error CircularDelegation();
    error InsufficientVotePower();
    error CognitiveFusionNotApproved();
    error InvalidKMForFusion();
    error KMAlreadyActiveForFusion();
    error KMMustBeValidated();

    // --- Constants & Configuration ---
    uint256 public constant INITIAL_AETHER_SUPPLY = 100_000_000 * (10 ** 18); // 100M tokens
    uint256 public constant KM_SUBMISSION_STAKE = 100 * (10 ** 18); // 100 AETH
    uint256 public constant VALIDATOR_MIN_STAKE = 500 * (10 ** 18); // 500 AETH
    uint256 public constant VALIDATOR_COOLDOWN_PERIOD = 7 days; // 7 days to unstake
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 3 days; // 3 days for voting
    uint256 public constant GOVERNANCE_QUORUM_PERCENT = 5; // 5% of total supply needed for quorum
    uint256 public constant GOVERNANCE_PROPOSAL_THRESHOLD = 1000 * (10 ** 18); // 1000 AETH to propose
    uint256 public constant PROTOCOL_FEE_PERCENT = 5; // 5% fee on KM rentals

    // --- State Variables ---

    // AetherToken (ERC20-like) storage
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    // KnowledgeModule (ERC721-like) storage
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balancesNFT;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId; // Counter for KM NFTs
    
    // KM specific data
    struct KnowledgeModule {
        address creator;
        string baseMetadataURI;
        bytes32 hashedContentId; // For on-chain content verification
        uint256 submissionStake;
        uint256 submittedAt;
        uint256 validationStatus; // 0: Pending, 1: Validated, 2: Challenged, 3: Rejected
        uint256 performanceScore; // 0-1000 scale, updated by oracle
        uint256 timesRented;
        uint256 totalRevenue;
        bool isFusion; // True if this KM is a result of cognitive fusion
        uint256[] sourceKMs; // If isFusion, which KMs were fused
        uint256 rentPricePerUse; // 0 if not listed
        uint256 maxRentUses;
        uint256 currentRentUses;
        address currentRenter; // For active rentals
        uint256 rentExpiresAt; // For active rentals
    }
    mapping(uint256 => KnowledgeModule) public knowledgeModules;

    // Validation System
    mapping(address => uint256) public validatorStakes;
    mapping(address => uint256) public validatorUnstakeCooldowns;
    mapping(uint256 => mapping(address => bool)) public kmValidatorVotes; // tokenId => validator => votedForValidity
    mapping(uint256 => uint256) public kmValidationSupportCount;
    mapping(uint256 => uint256) public kmValidationOpposeCount;
    mapping(address => uint256) public userReputation; // Simple reputation score

    // Governance System
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        bytes32 actionType; // e.g., "UPDATE_PARAM", "UPGRADE_CONTRACT", "FUSE_KMS"
        bytes actionData;   // Encoded calldata for the action
        string description;
        uint256 createdBlock;
        uint256 endBlock;
        uint256 quorumRequired; // Snapshot of quorum at proposal creation
        uint256 yayVotes;
        uint256 nayVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextProposalId;
    address public treasuryAddress; // Where protocol fees accumulate

    // Delegation for governance
    mapping(address => address) public delegates; // delegator => delegatee
    mapping(address => uint256) public checkpoints; // delegatee => blockNumber => voteWeight
    mapping(address => uint256[]) public checkpointBlocks; // delegatee => list of sorted block numbers

    // Cognitive Fusion Specifics
    struct FusionProposal {
        uint256 tokenId1;
        uint256 tokenId2;
        string newMetadataURI;
        uint256 proposalId; // Link to governance proposal
        bool executed;
    }
    mapping(uint256 => FusionProposal) public fusionProposals; // proposalId => FusionProposal

    // Other settings
    address public oracleAddress;
    bool private _paused;

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (_paused) revert PauseStateConflict();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert PauseStateConflict();
        _;
    }

    modifier onlyGovernor() {
        // For simplicity, using Ownable for initial governance,
        // but real DAO would use governance contract itself as owner
        if (_msgSender() != owner() && !governanceProposals[0].executed) { // Allow owner until first governance proposal executes
            revert Unauthorized();
        }
        // In a real DAO, this would check if msg.sender has passed a governance proposal to act
        // For this example, assuming governance itself will call this via executeGovernanceProposal
        _;
    }

    modifier onlyValidator() {
        if (validatorStakes[_msgSender()] < VALIDATOR_MIN_STAKE || validatorUnstakeCooldowns[_msgSender()] != 0) {
            revert NotAValidator();
        }
        _;
    }

    modifier onlyKMOwner(uint256 _tokenId) {
        if (_owners[_tokenId] != _msgSender()) revert NotKMOwner();
        _;
    }

    modifier onlyOracle() {
        if (_msgSender() != oracleAddress) revert Unauthorized();
        _;
    }

    // --- Constructor ---
    constructor() Ownable(_msgSender()) {
        _totalSupply = INITIAL_AETHER_SUPPLY;
        _balances[_msgSender()] = _totalSupply; // Mint all tokens to deployer initially
        emit AetherTokenMinted(_msgSender(), _totalSupply);

        _paused = false;
        nextProposalId = 1;
        treasuryAddress = address(this); // Protocol itself holds fees initially

        // Set initial parameters via a mock governance action
        // In a real DAO, these would be set by actual proposals
        // For demonstration, we'll set default values directly
    }

    // --- I. Core Contract & System Management ---

    /**
     * @dev Allows governance to update various system parameters.
     * @param _paramName The name of the parameter to update (e.g., "KM_SUBMISSION_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyGovernor {
        if (_paramName == "KM_SUBMISSION_STAKE") {
            KM_SUBMISSION_STAKE = _newValue;
        } else if (_paramName == "VALIDATOR_MIN_STAKE") {
            VALIDATOR_MIN_STAKE = _newValue;
        } else if (_paramName == "VALIDATOR_COOLDOWN_PERIOD") {
            VALIDATOR_COOLDOWN_PERIOD = _newValue;
        } else if (_paramName == "GOVERNANCE_VOTING_PERIOD") {
            GOVERNANCE_VOTING_PERIOD = _newValue;
        } else if (_paramName == "GOVERNANCE_QUORUM_PERCENT") {
            if (_newValue > 100) revert InvalidParameter();
            GOVERNANCE_QUORUM_PERCENT = _newValue;
        } else if (_paramName == "GOVERNANCE_PROPOSAL_THRESHOLD") {
            GOVERNANCE_PROPOSAL_THRESHOLD = _newValue;
        } else if (_paramName == "PROTOCOL_FEE_PERCENT") {
            if (_newValue > 100) revert InvalidParameter();
            PROTOCOL_FEE_PERCENT = _newValue;
        } else {
            revert InvalidParameter();
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Pauses all critical operations in case of emergency. Callable by governance.
     */
    function pause() external onlyGovernor whenNotPaused {
        _paused = true;
    }

    /**
     * @dev Unpauses the contract after an emergency. Callable by governance.
     */
    function unpause() external onlyGovernor whenPaused {
        _paused = false;
    }

    /**
     * @dev Allows governance to withdraw accumulated protocol fees to a specified address.
     * @param _tokenAddress The address of the token to withdraw (e.g., AetherToken or other ERC20).
     * @param _recipient The address to send the fees to.
     * @param _amount The amount to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress, address _recipient, uint256 _amount) external onlyGovernor nonReentrant {
        if (_tokenAddress == address(this)) { // AetherToken (internal)
            if (_balances[treasuryAddress] < _amount) revert NotEnoughBalance();
            _transfer(treasuryAddress, _recipient, _amount);
        } else { // ERC20 (external) - requires token to be in treasuryAddress balance
            // For simplicity, we assume AetherToken is the only fee token for this demo.
            // In a real contract, this would involve IERC20(_tokenAddress).transfer(recipient, amount);
            revert InvalidParameter(); // Or specify supported external tokens
        }
        emit ProtocolFeesWithdrawn(_tokenAddress, _recipient, _amount);
    }

    /**
     * @dev Sets the address of the trusted oracle for fetching external data. Callable by governance.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) external onlyGovernor {
        if (_newOracle == address(0)) revert ZeroAddress();
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    // --- II. AetherToken (ERC20-like Internal Implementation) ---

    // Note: These functions implement a basic ERC20-like interface.
    // In a production system, a dedicated, audited ERC20 contract would be used.

    /**
     * @dev Returns the total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance < amount) revert NotEnoughBalance(); // Not enough allowance

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function to mint tokens.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ZeroAddress();
        _totalSupply += amount;
        _balances[account] += amount;
        emit AetherTokenMinted(account, amount);
    }

    /**
     * @dev Internal function to burn tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ZeroAddress();
        if (_balances[account] < amount) revert NotEnoughBalance();
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit AetherTokenBurned(account, amount);
    }

    /**
     * @dev Internal function to transfer tokens.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (sender == address(0) || recipient == address(0)) revert ZeroAddress();
        if (_balances[sender] < amount) revert NotEnoughBalance();
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit AetherTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function to approve.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0) || spender == address(0)) revert ZeroAddress();
        _allowances[owner][spender] = amount;
        emit AetherTokenApproval(owner, spender, amount);
    }

    // --- III. Knowledge Module (KM) NFT (ERC721-like Internal Implementation) ---

    // Note: These functions implement a basic ERC721-like interface.
    // In a production system, a dedicated, audited ERC721 contract would be used.

    // ERC721 `balanceOf` is already defined for AetherToken, need to rename
    function balanceOfNFT(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balancesNFT[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    /**
     * @dev Safely transfers `tokenId` from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent token loss.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual whenNotPaused nonReentrant {
        _transferNFT(from, to, tokenId);
        // Additional check for contract recipient awareness would go here,
        // (e.g., using `ERC721Holder` interface), but simplified for brevity.
    }

    /**
     * @dev Safely transfers `tokenId` from `from` to `to` without data.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused nonReentrant {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to` without data (less safe for contracts).
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused nonReentrant {
        _transferNFT(from, to, tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` to another account.
     * The approval is cleared when the token is transferred.
     * Only a single account can be approved at a time.
     */
    function approve(address to, uint256 tokenId) public virtual whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !_operatorApprovals[owner][_msgSender()]) {
            revert NotApprovedOrOwner();
        }
        _tokenApprovals[tokenId] = to;
        emit KMApproval(owner, to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     */
    function setApprovalForAll(address operator, bool approved) public virtual whenNotPaused {
        _operatorApprovals[_msgSender()][operator] = approved;
        emit KMApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns the account approved for `tokenId` or the zero address if no account is set.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns the base URI for a given token, modified dynamically based on its state.
     * This makes KMs "dynamic NFTs".
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        KnowledgeModule storage km = knowledgeModules[tokenId];
        if (km.creator == address(0)) { // Check if KM exists
            revert TokenDoesNotExist();
        }

        string memory status;
        if (km.validationStatus == 0) {
            status = "pending_validation";
        } else if (km.validationStatus == 1) {
            status = "validated";
        } else if (km.validationStatus == 2) {
            status = "challenged";
        } else if (km.validationStatus == 3) {
            status = "rejected";
        } else {
            status = "unknown_status";
        }

        string memory fusionStatus = km.isFusion ? "fused" : "original";
        string memory rentStatus = km.rentPricePerUse > 0 ? "rentable" : "not_rentable";

        // Simple concatenation for demo. In practice, a dedicated off-chain service
        // (like a decentralized storage solution or IPFS gateway) would resolve
        // a more complex JSON structure based on these parameters.
        // Example: ipfs://[CID]/[base_uri]/status=[status]&perf=[performanceScore]&fusion=[fusionStatus]...
        return string(abi.encodePacked(
            km.baseMetadataURI,
            "?status=", status,
            "&performance=", uint256ToString(km.performanceScore),
            "&fusion_type=", fusionStatus,
            "&rent_status=", rentStatus
        ));
    }

    /**
     * @dev Internal function to mint a new token.
     */
    function _safeMint(address to, uint256 tokenId, string memory uri) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert TokenAlreadyExists();

        _balancesNFT[to] += 1;
        _owners[tokenId] = to;
        knowledgeModules[tokenId].baseMetadataURI = uri; // Set base URI
        emit KMMinted(tokenId, to, uri);
    }

    /**
     * @dev Internal function to burn a token.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Check if token exists
        _approve(address(0), tokenId); // Clear approvals
        _balancesNFT[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];
        // Clear KM data as well
        delete knowledgeModules[tokenId];
        emit KMRetired(tokenId); // Using KMRetired for burn event
    }

    /**
     * @dev Internal function to transfer ownership of a token.
     */
    function _transferNFT(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotApprovedOrOwner(); // from must be current owner
        if (to == address(0)) revert ZeroAddress();
        if (_tokenApprovals[tokenId] != _msgSender() && _operatorApprovals[from][_msgSender()] == false && from != _msgSender()) {
            revert NotApprovedOrOwner();
        }

        _balancesNFT[from] -= 1;
        _balancesNFT[to] += 1;
        _owners[tokenId] = to;
        _approve(address(0), tokenId); // Clear approval for this tokenId
        emit KMTransfer(from, to, tokenId);
    }

    // --- IV. Knowledge Module (KM) Specific Management ---

    /**
     * @dev Allows a user to submit a new Knowledge Module, requiring a stake.
     * Mints a new KM NFT and sets its initial pending validation status.
     * @param _initialMetadataURI The initial metadata URI for the KM.
     * @param _hashedContentId A hash representing the immutable core content of the KM (e.g., IPFS CID hash).
     */
    function submitKnowledgeModule(string calldata _initialMetadataURI, bytes32 _hashedContentId) external whenNotPaused nonReentrant {
        if (balanceOf(_msgSender()) < KM_SUBMISSION_STAKE) revert NotEnoughBalance();

        uint256 tokenId = _nextTokenId++;
        _safeMint(_msgSender(), tokenId, _initialMetadataURI); // Mints the NFT to sender

        _transfer(_msgSender(), treasuryAddress, KM_SUBMISSION_STAKE); // Transfer stake to treasury

        knowledgeModules[tokenId] = KnowledgeModule({
            creator: _msgSender(),
            baseMetadataURI: _initialMetadataURI,
            hashedContentId: _hashedContentId,
            submissionStake: KM_SUBMISSION_STAKE,
            submittedAt: block.timestamp,
            validationStatus: 0, // Pending
            performanceScore: 0,
            timesRented: 0,
            totalRevenue: 0,
            isFusion: false,
            sourceKMs: new uint256[](0),
            rentPricePerUse: 0,
            maxRentUses: 0,
            currentRentUses: 0,
            currentRenter: address(0),
            rentExpiresAt: 0
        });

        emit KMMinted(tokenId, _msgSender(), _initialMetadataURI);
    }

    /**
     * @dev Allows the KM owner to update the *base* metadata URI for their KM.
     * This will influence the dynamic `tokenURI`.
     * @param _tokenId The ID of the KM to update.
     * @param _newBaseMetadataURI The new base metadata URI.
     */
    function updateKnowledgeModuleMetadata(uint256 _tokenId, string calldata _newBaseMetadataURI) external onlyKMOwner(_tokenId) {
        knowledgeModules[_tokenId].baseMetadataURI = _newBaseMetadataURI;
        emit KMMetadataUpdated(_tokenId, _newBaseMetadataURI);
    }

    /**
     * @dev Allows a KM owner to list their KM for rental.
     * @param _tokenId The ID of the KM to list.
     * @param _pricePerUse The price in AetherTokens per single use/rent.
     * @param _maxUses The maximum number of uses/rentals allowed.
     */
    function listKnowledgeModuleForRent(uint256 _tokenId, uint256 _pricePerUse, uint256 _maxUses) external onlyKMOwner(_tokenId) {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.validationStatus != 1) revert KMMustBeValidated(); // Only validated KMs can be rented

        km.rentPricePerUse = _pricePerUse;
        km.maxRentUses = _maxUses;
        km.currentRentUses = 0; // Reset uses if relisting
        km.currentRenter = address(0); // Clear active renter
        km.rentExpiresAt = 0;

        emit KMListedForRent(_tokenId, _pricePerUse, _maxUses);
    }

    /**
     * @dev Allows a user to rent a listed KM for a specified number of uses.
     * Funds are transferred to the KM owner and protocol treasury.
     * @param _tokenId The ID of the KM to rent.
     * @param _numUses The number of uses/rentals desired.
     */
    function rentKnowledgeModule(uint256 _tokenId, uint256 _numUses) external whenNotPaused nonReentrant {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.rentPricePerUse == 0) revert KMNotListedForRent();
        if (_numUses == 0) revert RentDurationTooLow();
        if (km.maxRentUses > 0 && km.currentRentUses + _numUses > km.maxRentUses) revert InvalidAmount(); // Exceeds max uses

        uint256 totalCost = km.rentPricePerUse * _numUses;
        if (_balances[_msgSender()] < totalCost) revert NotEnoughBalance();

        uint256 ownerShare = totalCost * (100 - PROTOCOL_FEE_PERCENT) / 100;
        uint256 protocolFee = totalCost - ownerShare;

        _transfer(_msgSender(), km.creator, ownerShare);
        _transfer(_msgSender(), treasuryAddress, protocolFee);

        km.currentRentUses += _numUses;
        km.timesRented++;
        km.totalRevenue += totalCost;

        // Simplified active rental management, assumes usage is off-chain or via oracle
        km.currentRenter = _msgSender(); // Track last renter
        km.rentExpiresAt = block.timestamp + 1 hours; // Dummy expiry, implies short-term access

        emit KMRented(_tokenId, _msgSender(), _numUses, totalCost);
    }

    /**
     * @dev Allows a KM owner to remove their KM from the rental market.
     * @param _tokenId The ID of the KM to delist.
     */
    function delistKnowledgeModuleForRent(uint256 _tokenId) external onlyKMOwner(_tokenId) {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        km.rentPricePerUse = 0;
        km.maxRentUses = 0;
        km.currentRentUses = 0;
        km.currentRenter = address(0);
        km.rentExpiresAt = 0;
        emit KMDelistedFromRent(_tokenId);
    }

    /**
     * @dev Allows a KM owner to retire (burn) their KM.
     * This will also clear all associated data.
     * @param _tokenId The ID of the KM to retire.
     */
    function retireKnowledgeModule(uint256 _tokenId) external onlyKMOwner(_tokenId) {
        // No penalty implemented for simplicity, but could revert KM_SUBMISSION_STAKE here.
        _burn(_tokenId); // Burns the NFT
        // All KM data is deleted by _burn
        emit KMRetired(_tokenId);
    }

    /**
     * @dev Proposes a merge of two existing KMs into a new one.
     * This triggers a governance proposal for community approval.
     * @param _tokenId1 The ID of the first KM.
     * @param _tokenId2 The ID of the second KM.
     * @param _newMetadataURI The metadata URI for the resulting fused KM.
     */
    function proposeCognitiveFusion(uint256 _tokenId1, uint256 _tokenId2, string calldata _newMetadataURI) external whenNotPaused {
        KnowledgeModule storage km1 = knowledgeModules[_tokenId1];
        KnowledgeModule storage km2 = knowledgeModules[_tokenId2];

        if (km1.creator == address(0) || km2.creator == address(0)) revert TokenDoesNotExist();
        if (km1.validationStatus != 1 || km2.validationStatus != 1) revert KMMustBeValidated(); // Only validated KMs can be fused
        if (km1.isFusion || km2.isFusion) revert KMAlreadyActiveForFusion(); // Can't fuse already fused KMs (for simplicity)

        // Generate a new proposal ID
        uint256 proposalId = nextProposalId++;

        // Store fusion details pending governance approval
        fusionProposals[proposalId] = FusionProposal({
            tokenId1: _tokenId1,
            tokenId2: _tokenId2,
            newMetadataURI: _newMetadataURI,
            proposalId: proposalId,
            executed: false
        });

        // Create governance proposal
        bytes calldata actionData = abi.encodeCall(this.executeCognitiveFusion, (proposalId));
        proposeGovernanceAction("FUSE_KMS", actionData, string(abi.encodePacked("Propose Cognitive Fusion of KM ", uint256ToString(_tokenId1), " and KM ", uint256ToString(_tokenId2))));
    }

    /**
     * @dev Executes an approved cognitive fusion proposal.
     * Mints a new KM NFT representing the fusion and marks source KMs as fused.
     * Callable by governance only after a proposal passes.
     * @param _fusionProposalId The ID of the fusion proposal to execute.
     */
    function executeCognitiveFusion(uint256 _fusionProposalId) external onlyGovernor nonReentrant {
        FusionProposal storage fProposal = fusionProposals[_fusionProposalId];
        if (fProposal.tokenId1 == 0 && fProposal.tokenId2 == 0) revert ProposalNotFound(); // Check if fusion proposal exists
        if (fProposal.executed) revert ProposalAlreadyExecuted();

        KnowledgeModule storage km1 = knowledgeModules[fProposal.tokenId1];
        KnowledgeModule storage km2 = knowledgeModules[fProposal.tokenId2];

        if (km1.creator == address(0) || km2.creator == address(0)) revert TokenDoesNotExist();
        if (km1.isFusion || km2.isFusion) revert KMAlreadyActiveForFusion(); // Ensure they haven't been fused yet

        // Mint new KM for the fusion result
        uint256 newKmId = _nextTokenId++;
        _safeMint(km1.creator, newKmId, fProposal.newMetadataURI); // Owner of first KM gets the new fused KM

        // Set properties for the new fused KM
        knowledgeModules[newKmId] = KnowledgeModule({
            creator: km1.creator, // Or a new rule for ownership
            baseMetadataURI: fProposal.newMetadataURI,
            hashedContentId: bytes32(0), // Fused KMs might have a new content ID
            submissionStake: 0, // No new stake
            submittedAt: block.timestamp,
            validationStatus: 1, // Assume fused KMs are pre-validated by process
            performanceScore: (km1.performanceScore + km2.performanceScore) / 2, // Avg performance
            timesRented: 0,
            totalRevenue: 0,
            isFusion: true,
            sourceKMs: new uint256[](2),
            rentPricePerUse: 0,
            maxRentUses: 0,
            currentRentUses: 0,
            currentRenter: address(0),
            rentExpiresAt: 0
        });
        knowledgeModules[newKmId].sourceKMs[0] = fProposal.tokenId1;
        knowledgeModules[newKmId].sourceKMs[1] = fProposal.tokenId2;

        // Mark original KMs as 'fused' or 'archived'
        // For simplicity, we'll just mark them. A more complex system might burn them.
        km1.isFusion = true;
        km2.isFusion = true;

        fProposal.executed = true; // Mark fusion proposal as executed
        emit KMMinted(newKmId, km1.creator, fProposal.newMetadataURI);
    }

    // --- V. Reputation & Validation System ---

    /**
     * @dev Allows a user to stake tokens to become a potential KM validator.
     * @param _amount The amount of AetherTokens to stake. Must meet MIN_STAKE.
     */
    function stakeForValidationRole(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount < VALIDATOR_MIN_STAKE) revert InvalidAmount();
        if (validatorStakes[_msgSender()] > 0) revert AlreadyStaked(); // Only one stake allowed per validator

        _transfer(_msgSender(), treasuryAddress, _amount); // Stake goes to treasury
        validatorStakes[_msgSender()] = _amount;
        userReputation[_msgSender()] += 10; // Initial reputation boost
        emit ValidatorStaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows a validator to unstake their tokens and exit the role after a cooldown.
     */
    function unstakeFromValidationRole() external whenNotPaused nonReentrant {
        if (validatorStakes[_msgSender()] == 0) revert NotAValidator();
        if (validatorUnstakeCooldowns[_msgSender()] != 0 && block.timestamp < validatorUnstakeCooldowns[_msgSender()]) {
            revert CooldownPeriodNotPassed();
        }

        uint256 stakeAmount = validatorStakes[_msgSender()];
        validatorStakes[_msgSender()] = 0;
        validatorUnstakeCooldowns[_msgSender()] = block.timestamp + VALIDATOR_COOLDOWN_PERIOD; // Set cooldown
        _transfer(treasuryAddress, _msgSender(), stakeAmount); // Return stake from treasury
        emit ValidatorUnstaked(_msgSender(), stakeAmount);
    }

    /**
     * @dev Staked validators cast a vote on the validity/quality of a submitted KM.
     * Only callable for KMs that are in 'pending' or 'challenged' status.
     * @param _tokenId The ID of the KM to vote on.
     * @param _isValid True for support, false for oppose.
     */
    function voteOnKnowledgeModuleValidity(uint256 _tokenId, bool _isValid) external onlyValidator whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.creator == address(0)) revert TokenDoesNotExist();
        if (km.validationStatus != 0 && km.validationStatus != 2) revert KMNotInValidation(); // Only pending or challenged
        if (kmValidatorVotes[_tokenId][_msgSender()]) revert AlreadyVoted();

        if (_isValid) {
            kmValidationSupportCount[_tokenId]++;
        } else {
            kmValidationOpposeCount[_tokenId]++;
        }
        kmValidatorVotes[_tokenId][_msgSender()] = true;
        userReputation[_msgSender()] += 1; // Small reputation gain for voting

        // Simple validation logic: If sum of votes reaches 5 validators, resolve
        // In a real system, this would be more complex (e.g., weighted votes, time-based resolution)
        if (kmValidationSupportCount[_tokenId] + kmValidationOpposeCount[_tokenId] >= 5) {
            if (kmValidationSupportCount[_tokenId] > kmValidationOpposeCount[_tokenId]) {
                km.validationStatus = 1; // Validated
                userReputation[km.creator] += 5; // Creator gains reputation
            } else {
                km.validationStatus = 3; // Rejected
                // Potentially slash creator's stake if rejected
            }
            distributeValidationRewards(_tokenId); // Distribute rewards
        }
        emit KMValidityVoted(_tokenId, _msgSender(), _isValid);
    }

    /**
     * @dev Allows any user to challenge the current validation status of a KM,
     * potentially triggering a re-vote if it was already validated.
     * Requires a small reputation or stake to prevent spam.
     * @param _tokenId The ID of the KM to challenge.
     * @param _reason A string describing the reason for the challenge.
     */
    function challengeKnowledgeModuleValidity(uint256 _tokenId, string calldata _reason) external whenNotPaused nonReentrant {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.creator == address(0)) revert TokenDoesNotExist();
        if (km.validationStatus == 0 || km.validationStatus == 2) revert KMNotInValidation(); // Cannot challenge pending/already challenged

        if (userReputation[_msgSender()] < 50) revert InsufficientReputation(); // Must have some reputation to challenge

        km.validationStatus = 2; // Set to challenged state
        kmValidationSupportCount[_tokenId] = 0; // Reset vote counts
        kmValidationOpposeCount[_tokenId] = 0;
        // Clear previous votes for a re-vote, for simplicity just reset for everyone
        // More realistically, previous validators might be excluded or penalized.
        // For simplicity, we just mark new map entries.
        userReputation[_msgSender()] += 2; // Reputation gain for valid challenge

        emit KMValidityChallenged(_tokenId, _msgSender(), _reason);
    }

    /**
     * @dev Oracle-fed function to update a KM's verified performance score.
     * Influences its dynamic NFT properties and potential rewards for its owner.
     * @param _tokenId The ID of the KM.
     * @param _performanceScore The new performance score (e.g., 0-1000).
     * @param _oracleSignature Signature from the trusted oracle.
     */
    function recordKnowledgeModulePerformance(uint256 _tokenId, uint256 _performanceScore, bytes calldata _oracleSignature) external onlyOracle whenNotPaused {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.creator == address(0)) revert TokenDoesNotExist();

        // Verify oracle signature (simplified)
        bytes32 messageHash = keccak256(abi.encodePacked(_tokenId, _performanceScore));
        address signer = IOracle(oracleAddress).verifySignature(messageHash, _oracleSignature);
        if (signer != oracleAddress) revert InvalidSignature();

        km.performanceScore = _performanceScore;
        userReputation[km.creator] += _performanceScore / 100; // Creator gains reputation based on performance

        emit KMPerformanceRecorded(_tokenId, _performanceScore, _msgSender());
    }

    /**
     * @dev Allows governance to slash a validator's stake for malicious or incorrect actions.
     * @param _validatorAddress The address of the validator to slash.
     * @param _amount The amount of stake to slash.
     * @param _reason A description for the slashing.
     */
    function slashValidatorStake(address _validatorAddress, uint256 _amount, string calldata _reason) external onlyGovernor nonReentrant {
        if (validatorStakes[_validatorAddress] == 0) revert NotAValidator();
        if (_amount == 0 || _amount > validatorStakes[_validatorAddress]) revert InvalidAmount();

        validatorStakes[_validatorAddress] -= _amount;
        _burn(_validatorAddress, _amount); // Burn slashed tokens (or send to treasury for redistribution)
        userReputation[_validatorAddress] = userReputation[_validatorAddress] > 20 ? userReputation[_validatorAddress] - 20 : 0; // Penalize reputation
        emit ValidatorStakeSlashed(_validatorAddress, _amount, _reason);
    }

    /**
     * @dev Distributes rewards to validators who accurately voted on a KM's final status.
     * Called automatically after a KM validation dispute is resolved.
     * @param _tokenId The ID of the KM for which to distribute rewards.
     */
    function distributeValidationRewards(uint256 _tokenId) internal nonReentrant {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        if (km.validationStatus == 0 || km.validationStatus == 2) return; // Only distribute if final status

        uint256 totalRewardPool = KM_SUBMISSION_STAKE; // Reward pool from KM's stake
        uint256 winningVoteCount;
        bool isSupportWinning = km.validationStatus == 1;

        if (isSupportWinning) {
            winningVoteCount = kmValidationSupportCount[_tokenId];
        } else { // Rejected
            winningVoteCount = kmValidationOpposeCount[_tokenId];
        }

        if (winningVoteCount == 0) return; // No validators to reward

        uint256 rewardPerValidator = totalRewardPool / winningVoteCount;

        // Iterate through all validators who voted on this KM and reward correct ones
        // This is a simplified loop. In production, this might be handled via merkle trees
        // or a pull-based system to avoid gas limits for many validators.
        // For demo, assume small number of validators per KM.
        for (uint i = 0; i < 50; i++) { // Max 50 validators to avoid gas issues
            address validatorAddress = address(uint160(i + 1)); // Dummy validator addresses for example
            if (validatorStakes[validatorAddress] > 0 && kmValidatorVotes[_tokenId][validatorAddress] == isSupportWinning) {
                 _mint(validatorAddress, rewardPerValidator); // Mint new tokens as reward
            }
        }
        emit ValidationRewardsDistributed(_tokenId, totalRewardPool);
    }

    // --- VI. Decentralized Governance & Treasury ---

    /**
     * @dev Allows a qualified user to submit a new governance proposal.
     * Requires minimum AetherToken balance.
     * @param _actionType A string identifying the type of action (e.g., "UPDATE_PARAM", "UPGRADE_CONTRACT", "FUSE_KMS").
     * @param _actionData Encoded calldata for the function to be executed if the proposal passes.
     * @param _description A human-readable description of the proposal.
     */
    function proposeGovernanceAction(bytes32 _actionType, bytes calldata _actionData, string calldata _description) public whenNotPaused {
        if (_balances[_msgSender()] < GOVERNANCE_PROPOSAL_THRESHOLD) revert InsufficientVotePower();

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            actionType: _actionType,
            actionData: _actionData,
            description: _description,
            createdBlock: block.number,
            endBlock: block.number + GOVERNANCE_VOTING_PERIOD,
            quorumRequired: (_totalSupply * GOVERNANCE_QUORUM_PERCENT) / 100, // Snapshot current total supply
            yayVotes: 0,
            nayVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit GovernanceProposalCreated(proposalId, _actionType, _description);
    }

    /**
     * @dev Allows AetherToken holders to vote on active governance proposals.
     * Voting power is based on the caller's AetherToken balance at the time of voting,
     * considering delegations.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yay', false for 'nay'.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number > proposal.endBlock) revert ProposalNotActive(); // Voting period ended
        if (proposal.hasVoted[_msgSender()]) revert AlreadyVotedOnProposal();

        uint256 voteWeight = getVotes(_msgSender());
        if (voteWeight == 0) revert InsufficientVotePower();

        if (_support) {
            proposal.yayVotes += voteWeight;
        } else {
            proposal.nayVotes += voteWeight;
        }
        proposal.hasVoted[_msgSender()] = true;
        emit GovernanceProposalVoted(_proposalId, _msgSender(), _support);

        // Auto-update proposal state if voting ends (simplified, could be separate function)
        if (block.number == proposal.endBlock) {
            _updateProposalState(_proposalId);
        }
    }

    /**
     * @dev Executes a successfully passed governance proposal.
     * Callable by anyone after the voting period ends and criteria are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        proposal.executed = true;

        // Execute the proposed action using low-level call
        (bool success, ) = address(this).call(proposal.actionData);
        if (!success) revert ProposalNotExecutable(); // Execution failed (e.g., invalid data)

        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows AetherToken holders to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) public {
        if (_delegatee == address(0)) revert ZeroAddress();
        if (_delegatee == _msgSender()) revert SelfDelegationNotAllowed();

        address currentDelegatee = delegates[_msgSender()];
        if (currentDelegatee != address(0)) {
            _removeVotes(currentDelegatee, _balances[_msgSender()]);
        }
        
        // Prevent circular delegation (simplified check)
        address temp = _delegatee;
        while (temp != address(0)) {
            if (temp == _msgSender()) revert CircularDelegation();
            temp = delegates[temp];
        }

        delegates[_msgSender()] = _delegatee;
        _addVotes(_delegatee, _balances[_msgSender()]);
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Allows a user to undelegate their voting power, making it available for their own direct voting again.
     */
    function redeemVoteWeight() public {
        address currentDelegatee = delegates[_msgSender()];
        if (currentDelegatee == address(0)) return; // No active delegation

        _removeVotes(currentDelegatee, _balances[_msgSender()]);
        delete delegates[_msgSender()];
        emit VoteRedeemed(_msgSender());
    }

    /**
     * @dev Allows users who voted on a successfully executed proposal to claim a small AetherToken reward for participation.
     * @param _proposalId The ID of the proposal.
     */
    function claimGovernanceReward(uint256 _proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (!proposal.executed) revert ProposalNotExecutable(); // Must be executed
        if (!proposal.hasVoted[_msgSender()]) revert InsufficientVotePower(); // Must have voted

        // Simple reward for demonstration
        uint256 rewardAmount = 1 * (10 ** 18); // 1 AETH per vote on successful proposal
        if (balanceOf(treasuryAddress) < rewardAmount) revert NotEnoughBalance(); // Ensure treasury has funds

        _transfer(treasuryAddress, _msgSender(), rewardAmount);
        delete proposal.hasVoted[_msgSender()]; // Mark as claimed
        emit GovernanceRewardClaimed(_msgSender(), _proposalId, rewardAmount);
    }

    /**
     * @dev Allows any user to voluntarily deposit funds into the collective's treasury.
     * @dev This function assumes AetherToken. For other ERC20s, a separate function would be needed.
     */
    function depositToTreasury(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        _transfer(_msgSender(), treasuryAddress, _amount);
        emit TreasuryDeposit(_msgSender(), _amount);
    }

    // --- Internal Governance Helpers ---

    function _updateProposalState(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Active) return; // Only active proposals can change state

        if (block.number < proposal.endBlock) return; // Voting period not over

        uint256 totalVotes = proposal.yayVotes + proposal.nayVotes;
        if (totalVotes < proposal.quorumRequired) {
            proposal.state = ProposalState.Failed;
        } else if (proposal.yayVotes > proposal.nayVotes) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    function getVotes(address account) public view returns (uint256) {
        address currentDelegatee = delegates[account];
        if (currentDelegatee == address(0)) {
            return _balances[account];
        } else {
            // Get current votes from delegatee's checkpoints
            uint256 weight = 0;
            for (uint i = checkpointBlocks[currentDelegatee].length; i > 0; i--) {
                uint blockNum = checkpointBlocks[currentDelegatee][i-1];
                if (blockNum <= block.number) {
                    weight = checkpoints[currentDelegatee][blockNum];
                    break;
                }
            }
            return weight;
        }
    }

    function _addVotes(address delegatee, uint256 amount) internal {
        _updateCheckpoints(delegatee, amount, true);
    }

    function _removeVotes(address delegatee, uint256 amount) internal {
        _updateCheckpoints(delegatee, amount, false);
    }

    function _updateCheckpoints(address delegatee, uint256 amount, bool add) internal {
        uint256 oldWeight = 0;
        if (checkpointBlocks[delegatee].length > 0) {
            oldWeight = checkpoints[delegatee][checkpointBlocks[delegatee][checkpointBlocks[delegatee].length - 1]];
        }
        uint256 newWeight;
        if (add) {
            newWeight = oldWeight + amount;
        } else {
            newWeight = oldWeight - amount;
        }

        // Add a new checkpoint at current block
        checkpointBlocks[delegatee].push(block.number);
        checkpoints[delegatee][block.number] = newWeight;
    }

    // --- VII. Information & Public Access ---

    /**
     * @dev Returns the current on-chain reputation score of a given user.
     * @param _user The address of the user.
     */
    function getUserReputationScore(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the current validation status of a Knowledge Module.
     * 0: Pending, 1: Validated, 2: Challenged, 3: Rejected
     * @param _tokenId The ID of the Knowledge Module.
     */
    function getKMValidationStatus(uint256 _tokenId) public view returns (uint256) {
        return knowledgeModules[_tokenId].validationStatus;
    }

    /**
     * @dev Returns the current rental information for a Knowledge Module.
     * @param _tokenId The ID of the Knowledge Module.
     * @return pricePerUse The price per use.
     * @return maxUses The maximum uses specified by the owner.
     * @return currentUses The number of times it has been rented so far.
     * @return isListedForRent True if the KM is currently listed for rent.
     */
    function getKMCurrentRentInfo(uint256 _tokenId) public view returns (uint256 pricePerUse, uint256 maxUses, uint256 currentUses, bool isListedForRent) {
        KnowledgeModule storage km = knowledgeModules[_tokenId];
        pricePerUse = km.rentPricePerUse;
        maxUses = km.maxRentUses;
        currentUses = km.currentRentUses;
        isListedForRent = (km.rentPricePerUse > 0);
    }

    // --- Utility Function ---
    function uint256ToString(uint256 _i) internal pure returns (string memory s) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        s = string(bstr);
    }
}
```