Here's a smart contract in Solidity called `NeuralNexus`, designed to be an interesting, advanced-concept, creative, and trendy platform. It simulates a decentralized "AI" or "cognitive network" where NFTs (Neural Units) evolve, a utility token ($COG) drives participation, and a reputation system ($INF) influences dynamic parameters and governance.

**Outline:**

**I. Contract Overview:**
*   A decentralized "AI simulation" platform.
*   Manages core tokens ($COG, $INF) and evolving NFTs (Neural Units).
*   Features dynamic adaptation of system parameters via governance and automated cycles.
*   Includes a treasury for funding research and network improvements.

**II. Core Tokens and NFTs:**
*   **A. Cognition Token ($COG):** An ERC-20 like utility and governance token used for staking, rewards, and proposing.
*   **B. Neural Unit (NNU):** An ERC-721 like Dynamic NFT representing computational nodes. Its "synaptic weights" (attributes) evolve based on training.
*   **C. Influence Points ($INF):** An internal, non-transferable ERC-20 like token representing reputation and voting power within the system.

**III. Core Mechanics:**
*   **A. Inference/Training Module:** Users stake $COG to participate in training Neural Units by submitting "data observations".
*   **B. Neural Unit Evolution:** Neural Unit attributes ("synaptic weights") dynamically evolve based on the impact and quality of submitted training data.
*   **C. Adaptive Engine & Governance:** Key system parameters (e.g., reward rates, evolution factors) are not fixed but can dynamically adjust based on DAO proposals and simulated "automated adaptation cycles" (akin to on-chain feedback loops).
*   **D. Treasury Management:** A community-governed treasury that can allocate funds for "research grants" or network improvements.

**IV. Access Control & Emergency Features:**
*   Pausable functionality for emergency situations.
*   Owner-controlled emergency withdrawals.

**Function Summary (Total: 40 Functions):**

---

**A. Core Infrastructure (Access Control, Pausability, Emergency):**
1.  `constructor()`: Initializes the contract, sets up owner, and mints initial $COG tokens.
2.  `pauseContract()`: Pauses contract functionality in emergencies (Owner only).
3.  `unpauseContract()`: Unpauses contract functionality (Owner only).
4.  `emergencyWithdrawERC20(IERC20 _token, address _to, uint256 _amount)`: Allows owner to withdraw specified ERC20 tokens in emergencies.
5.  `emergencyWithdrawETH(address _to, uint256 _amount)`: Allows owner to withdraw ETH in emergencies.

**B. Cognition Token ($COG) Management (ERC-20 functions are internal/simplified):**
6.  `mintCognitionTokens(address _to, uint256 _amount)`: Mints new $COG tokens (e.g., for initial supply or governed emission).
7.  `transferCognitionTokens(address _recipient, uint256 _amount)`: Transfers $COG tokens.
8.  `approveCognitionTokens(address _spender, uint256 _amount)`: Approves spending of $COG tokens.
9.  `allowanceCognitionTokens(address _owner, address _spender)`: Checks allowance of $COG tokens.
10. `burnCognitionTokens(uint256 _amount)`: Burns $COG tokens from sender's balance.
11. `balanceOfCog(address _account)`: Returns $COG balance of an address.
12. `getTotalSupplyCog()`: Returns total supply of $COG.

**C. Neural Unit (NNU) Management (ERC-721 functions are internal/simplified):**
13. `mintNeuralUnit(address _to)`: Mints a new Neural Unit NFT to an address.
14. `getNeuralUnitSynapticWeights(uint256 _tokenId)`: Returns the current synaptic weights (attributes) of a Neural Unit.
15. `evolveNeuralUnitWeights(uint256 _tokenId, uint256 _dataImpact, uint256 _qualityScore)`: Core function to update a Neural Unit's weights based on training data impact and quality.
16. `transferNeuralUnit(address _from, address _to, uint256 _tokenId)`: Transfers a Neural Unit NFT.
17. `getNeuralUnitOwner(uint256 _tokenId)`: Returns the owner of a Neural Unit NFT.
18. `getTotalSupplyNnu()`: Returns total supply of NNUs.
19. `tokenURI(uint256 _tokenId)`: Returns the URI for a given NNU token ID (conceptual for future metadata).
20. `setBaseURI(string memory baseURI_)`: Sets the base URI for all Neural Unit NFTs (Owner only).

**D. Inference/Training Module:**
21. `stakeCognitionForTraining(uint256 _amount)`: Allows users to stake $COG tokens to participate in training.
22. `unstakeCognitionFromTraining(uint256 _amount)`: Allows users to unstake $COG tokens.
23. `submitTrainingDataBatch(uint256 _neuralUnitId, uint256 _dataHash, uint256 _processingPowerContribution, uint256 _dataQualityScore)`: Users submit data batches, initiating Neural Unit evolution and potentially earning rewards.
24. `claimTrainingRewards()`: Allows users to claim accumulated $COG and $INF rewards from training and staking.
25. `getPendingTrainingRewards(address _user)`: Returns pending $COG and $INF rewards for a user.
26. `getStakedCogBalance(address _user)`: Returns the amount of $COG staked by a user.
27. `getNeuralUnitTrainingHistory(uint256 _neuralUnitId)`: Retrieves a simplified history of training events for a Neural Unit.

**E. Influence Points ($INF) & Reputation (Internal ERC-20 like):**
28. `getInfluencePoints(address _user)`: Returns the $INF balance of a user.
29. `delegateInfluence(address _delegatee)`: Allows users to delegate their $INF-based influence to another address (e.g., for governance).
30. `burnInfluenceForAdaptiveBoost(uint256 _amount, uint256 _parameterIndex, int256 _boostValue)`: Allows users to burn $INF to conceptually propose or accelerate a specific adaptive parameter change.

**F. Adaptive Engine & Governance:**
31. `proposeAdaptiveParameterChange(string memory _description, uint256 _parameterIndex, int256 _newValue, uint256 _voteThreshold, uint256 _duration)`: Users can propose changes to system's adaptive parameters.
32. `voteOnAdaptiveParameterChange(uint256 _proposalId, bool _support)`: Users vote on active proposals.
33. `executeAdaptiveParameterChange(uint256 _proposalId)`: Executes an approved adaptive parameter change.
34. `getCurrentAdaptiveParameters()`: Returns the current values of all adaptive parameters.
35. `triggerAutomatedAdaptationCycle()`: Callable by a trusted oracle/keeper, auto-adjusts parameters based on network activity and health metrics (Owner for simplicity, could be decentralized).

**G. Treasury Management & Research Funding:**
36. `depositTreasuryFunds()`: Allows anyone to deposit ETH into the treasury (via payable fallback or explicit call).
37. `proposeTreasuryAllocation(string memory _description, address _recipient, uint256 _amount, uint256 _voteThreshold, uint256 _duration)`: Proposes allocation of treasury funds for research or network improvements.
38. `voteOnTreasuryAllocation(uint256 _proposalId, bool _support)`: Votes on treasury allocation proposals.
39. `executeTreasuryAllocation(uint256 _proposalId)`: Executes an approved treasury allocation.
40. `getTreasuryBalance()`: Returns the current ETH balance of the treasury.
41. `getProposalState(uint256 _proposalId)`: Returns the current state of a governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For emergencyWithdraw, not direct inheritance
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For conceptual NFT, not direct inheritance
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safe math, though 0.8+ has default checks
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

// Outline:
// I.  Contract Overview
// II. Core Tokens and NFTs
//     A. Cognition Token ($COG) - ERC-20 Utility/Governance Token
//     B. Neural Unit (NNU) - ERC-721 Dynamic NFT representing computational nodes
//     C. Influence Points ($INF) - Reputation/Voting Power Token (Internal, Non-transferable ERC-20 simulation)
// III. Core Mechanics
//     A. Inference/Training Module: Users stake $COG to train Neural Units by submitting "data observations".
//     B. Neural Unit Evolution: Neural Unit attributes (synaptic weights) evolve based on training success.
//     C. Adaptive Engine & Governance: System parameters dynamically adjust based on network activity or DAO proposals.
//     D. Treasury Management: Funds allocated for "research" and network improvements via DAO.
// IV. Access Control & Emergency Features
//
// Function Summary:
// --- Core Infrastructure (Access Control, Pausability, Emergency) ---
// 1.  constructor(): Initializes the contract, sets up owner, mints initial COG tokens.
// 2.  pauseContract(): Pauses contract functionality in emergencies (Owner only).
// 3.  unpauseContract(): Unpauses contract functionality (Owner only).
// 4.  emergencyWithdrawERC20(IERC20 _token, address _to, uint256 _amount): Allows owner to withdraw specified ERC20 tokens in emergencies.
// 5.  emergencyWithdrawETH(address _to, uint256 _amount): Allows owner to withdraw ETH in emergencies.
//
// --- Cognition Token ($COG) Management (ERC-20 functions are internal/simplified) ---
// 6.  mintCognitionTokens(address _to, uint256 _amount): Mints new $COG tokens (e.g., for initial supply or governed emission).
// 7.  transferCognitionTokens(address _recipient, uint256 _amount): Transfers $COG tokens.
// 8.  approveCognitionTokens(address _spender, uint256 _amount): Approves spending of $COG tokens.
// 9.  allowanceCognitionTokens(address _owner, address _spender): Checks allowance of $COG tokens.
// 10. burnCognitionTokens(uint256 _amount): Burns $COG tokens from sender's balance.
// 11. balanceOfCog(address _account): Returns $COG balance of an address.
// 12. getTotalSupplyCog(): Returns total supply of $COG.
//
// --- Neural Unit (NNU) Management (ERC-721 functions are internal/simplified) ---
// 13. mintNeuralUnit(address _to): Mints a new Neural Unit NFT to an address.
// 14. getNeuralUnitSynapticWeights(uint256 _tokenId): Returns the current synaptic weights (attributes) of a Neural Unit.
// 15. evolveNeuralUnitWeights(uint256 _tokenId, uint256 _dataImpact, uint256 _qualityScore): Core function to update a Neural Unit's weights based on training data impact and quality.
// 16. transferNeuralUnit(address _from, address _to, uint256 _tokenId): Transfers a Neural Unit NFT.
// 17. getNeuralUnitOwner(uint256 _tokenId): Returns the owner of a Neural Unit NFT.
// 18. getTotalSupplyNnu(): Returns total supply of NNUs.
// 19. tokenURI(uint256 _tokenId): Returns the URI for a given NNU token ID. (Conceptual for future metadata)
// 20. setBaseURI(string memory baseURI_): Sets the base URI for all Neural Unit NFTs.
//
// --- Inference/Training Module ---
// 21. stakeCognitionForTraining(uint256 _amount): Allows users to stake $COG tokens to participate in training.
// 22. unstakeCognitionFromTraining(uint256 _amount): Allows users to unstake $COG tokens.
// 23. submitTrainingDataBatch(uint256 _neuralUnitId, uint256 _dataHash, uint256 _processingPowerContribution, uint256 _dataQualityScore): Users submit data batches, initiating Neural Unit evolution and potentially earning rewards.
// 24. claimTrainingRewards(): Allows users to claim accumulated $COG and $INF rewards from training.
// 25. getPendingTrainingRewards(address _user): Returns pending $COG and $INF rewards for a user.
// 26. getStakedCogBalance(address _user): Returns the amount of $COG staked by a user.
// 27. getNeuralUnitTrainingHistory(uint256 _neuralUnitId): Retrieves a simplified history of training events for a Neural Unit.
//
// --- Influence Points ($INF) & Reputation (Internal ERC-20 like) ---
// 28. getInfluencePoints(address _user): Returns the $INF balance of a user.
// 29. delegateInfluence(address _delegatee): Allows users to delegate their $INF-based influence to another address (e.g., for governance).
// 30. burnInfluenceForAdaptiveBoost(uint256 _amount, uint256 _parameterIndex, int256 _boostValue): Allows users to burn $INF to propose or accelerate a specific adaptive parameter change.
//
// --- Adaptive Engine & Governance ---
// 31. proposeAdaptiveParameterChange(string memory _description, uint256 _parameterIndex, int256 _newValue, uint256 _voteThreshold, uint256 _duration): Users can propose changes to system's adaptive parameters.
// 32. voteOnAdaptiveParameterChange(uint256 _proposalId, bool _support): Users vote on active proposals.
// 33. executeAdaptiveParameterChange(uint256 _proposalId): Executes an approved adaptive parameter change.
// 34. getCurrentAdaptiveParameters(): Returns the current values of all adaptive parameters.
// 35. triggerAutomatedAdaptationCycle(): Callable by a trusted oracle/keeper, auto-adjusts parameters based on network activity and health metrics.
//
// --- Treasury Management & Research Funding ---
// 36. depositTreasuryFunds(): Allows anyone to deposit ETH into the treasury.
// 37. proposeTreasuryAllocation(string memory _description, address _recipient, uint256 _amount, uint256 _voteThreshold, uint256 _duration): Proposes allocation of treasury funds for research or network improvements.
// 38. voteOnTreasuryAllocation(uint256 _proposalId, bool _support): Votes on treasury allocation proposals.
// 39. executeTreasuryAllocation(uint256 _proposalId): Executes an approved treasury allocation.
// 40. getTreasuryBalance(): Returns the current ETH balance of the treasury.
// 41. getProposalState(uint256 _proposalId): Returns the current state of a governance proposal.


contract NeuralNexus is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for clarity, despite 0.8+ built-in checks

    // --- Events ---
    event CognitionTokensMinted(address indexed to, uint256 amount);
    event CognitionTokensBurned(address indexed from, uint256 amount);
    event NeuralUnitMinted(address indexed owner, uint256 indexed tokenId);
    event NeuralUnitEvolved(uint256 indexed tokenId, uint256 dataImpact, uint256 qualityScore, uint256[] newWeights);
    event CognitionStaked(address indexed user, uint256 amount);
    event CognitionUnstaked(address indexed user, uint256 amount);
    event TrainingDataSubmitted(address indexed submitter, uint256 indexed neuralUnitId, uint256 dataHash, uint256 qualityScore);
    event TrainingRewardsClaimed(address indexed user, uint256 cogAmount, uint256 infAmount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event InfluenceBurnedForBoost(address indexed burner, uint256 amount, uint256 parameterIndex, int256 boostValue);
    event ParameterChangeProposed(uint256 indexed proposalId, string description, uint256 parameterIndex, int256 newValue, uint256 voteThreshold, uint256 duration);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ParameterChangeExecuted(uint256 indexed proposalId, uint256 parameterIndex, int256 newValue);
    event AutomatedAdaptationTriggered(uint256 timestamp);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryAllocationProposed(uint256 indexed proposalId, string description, address recipient, uint256 amount, uint256 voteThreshold, uint256 duration);
    event TreasuryAllocationExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    // --- I. Contract Overview ---
    // Represents an innovative decentralized "AI simulation" platform.
    // Manages core tokens ($COG, $INF) and evolving NFTs (Neural Units).
    // Features dynamic adaptation of system parameters via governance and automated cycles.

    // --- II. Core Tokens and NFTs ---

    // A. Cognition Token ($COG) - ERC-20 Utility/Governance Token (Simplified implementation)
    string public constant COG_NAME = "Cognition Token";
    string public constant COG_SYMBOL = "COG";
    uint8 public constant COG_DECIMALS = 18;
    mapping(address => uint256) private _cogBalances;
    mapping(address => mapping(address => uint256)) private _cogAllowances;
    uint256 private _cogTotalSupply;

    // B. Neural Unit (NNU) - ERC-721 Dynamic NFT (Simplified implementation)
    string public constant NNU_NAME = "Neural Unit";
    string public constant NNU_SYMBOL = "NNU";
    Counters.Counter private _neuralUnitTokenIds;
    mapping(uint256 => address) private _neuralUnitOwners;
    mapping(address => uint256) private _neuralUnitBalanceOf;
    mapping(uint256 => address) private _neuralUnitApproved; // For simplified NFT transfer/evolution approval
    // Synaptic weights for each Neural Unit (simulated attributes, 3 values for simplicity)
    mapping(uint256 => uint256[3]) public neuralUnitSynapticWeights; // [weight1, weight2, weight3]
    // A simple record of last training for reward calculation and history
    mapping(uint256 => uint256) public neuralUnitLastTrainingTime;
    string private _baseTokenURI; // Base URI for NFT metadata

    // C. Influence Points ($INF) - Reputation/Voting Power (Internal, Non-transferable ERC-20 simulation)
    mapping(address => uint256) private _influenceBalances;
    mapping(address => address) private _influenceDelegates; // delegator => delegatee

    // --- III. Core Mechanics ---

    // A. Inference/Training Module
    mapping(address => uint256) public stakedCogBalances;
    mapping(address => uint256) public pendingCogRewards;
    mapping(address => uint256) public pendingInfRewards;
    mapping(address => uint256) public lastRewardClaimTime; // For staking reward calculation

    // B. Neural Unit Evolution (parameters for evolution logic)
    uint256 public constant MIN_DATA_QUALITY = 100; // Minimum quality score for effective training
    uint256 public constant MAX_SYNAPTIC_WEIGHT = 10000; // Max value for any synaptic weight
    uint256 public constant MIN_SYNAPTIC_WEIGHT = 0;   // Min value for any synaptic weight

    // C. Adaptive Engine & Governance
    // Parameter indexes for the adaptive engine
    uint256 public constant PARAM_TRAINING_REWARD_RATE_COG = 0; // COG rewards per unit of quality score
    uint256 public constant PARAM_TRAINING_REWARD_RATE_INF = 1; // INF rewards per unit of quality score
    uint256 public constant PARAM_STAKING_APR_COG = 2;          // Simulated APR for staked COG (in basis points)
    uint256 public constant PARAM_NEURAL_EVOLUTION_FACTOR = 3;  // Multiplier for synaptic weight changes (in basis points)
    uint256 public constant PARAM_MIN_PROPOSAL_COG_STAKE = 4;   // Minimum COG required to create a proposal
    uint256 public constant PARAM_DEFAULT_VOTE_THRESHOLD_BP = 5; // Default BPS (basis points) threshold for proposals (e.g. 5000 for 50%)
    uint256 public constant PARAM_COUNT = 6; // Total number of adaptive parameters

    // Current adaptive parameters (stored as int256 to allow for conceptual negative changes)
    mapping(uint256 => int256) public adaptiveParameters;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 id;
        string description;
        uint256 parameterIndex; // For parameter changes, type(uint256).max for treasury
        int256 newValue;        // For parameter changes, 0 for treasury
        address recipient;       // For treasury proposals
        uint256 amount;          // For treasury proposals
        uint256 voteThreshold;   // BPS of total voting power required to pass
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this specific proposal
        ProposalState state;
        bool isTreasuryProposal;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => GovernanceProposal) public proposals;

    // D. Treasury Management
    // Treasury funds are held in this contract's ETH balance directly.

    // --- Configuration Constants ---
    uint256 public constant INITIAL_COG_SUPPLY = 100_000_000 * (10 ** COG_DECIMALS); // 100M COG
    uint256 public constant SECONDS_IN_YEAR = 31536000; // Roughly 365.25 days

    constructor() Ownable(msg.sender) Pausable() {
        // Initialize COG token
        _cogTotalSupply = INITIAL_COG_SUPPLY;
        _cogBalances[msg.sender] = INITIAL_COG_SUPPLY;
        emit CognitionTokensMinted(msg.sender, INITIAL_COG_SUPPLY);

        // Initialize adaptive parameters
        adaptiveParameters[PARAM_TRAINING_REWARD_RATE_COG] = 10;    // 10 units COG per quality point
        adaptiveParameters[PARAM_TRAINING_REWARD_RATE_INF] = 1;     // 1 unit INF per quality point
        adaptiveParameters[PARAM_STAKING_APR_COG] = 500;            // 5% APR (500 basis points)
        adaptiveParameters[PARAM_NEURAL_EVOLUTION_FACTOR] = 100;    // 100 = 1x (100 basis points)
        adaptiveParameters[PARAM_MIN_PROPOSAL_COG_STAKE] = 1000 * (10 ** COG_DECIMALS); // 1000 COG required for proposals
        adaptiveParameters[PARAM_DEFAULT_VOTE_THRESHOLD_BP] = 5000; // 50% for default proposals

        // Set initial base URI for NFTs
        setBaseURI("https://neuralnexus.io/nnu/metadata/");
    }

    // --- Core Infrastructure (Access Control, Pausability, Emergency) ---

    /// @notice Pauses contract functionality. Callable by owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract functionality. Callable by owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows owner to withdraw specified ERC20 tokens in emergencies.
    /// @param _token The address of the ERC20 token to withdraw.
    /// @param _to The recipient address.
    /// @param _amount The amount of tokens to withdraw.
    function emergencyWithdrawERC20(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "NN: Amount must be greater than 0");
        require(_token.transfer(_to, _amount), "NN: ERC20 transfer failed");
    }

    /// @notice Allows owner to withdraw ETH in emergencies.
    /// @param _to The recipient address.
    /// @param _amount The amount of ETH to withdraw.
    function emergencyWithdrawETH(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "NN: Amount must be greater than 0");
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success, "NN: ETH transfer failed");
    }

    // --- Cognition Token ($COG) Management (ERC-20 functions are internal/simplified) ---

    /// @notice Mints new $COG tokens to a specified address. Governed function, only callable by owner or via proposal.
    /// @param _to The recipient address.
    /// @param _amount The amount of $COG to mint.
    function mintCognitionTokens(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_to != address(0), "NN: Mint to the zero address");
        _cogTotalSupply = _cogTotalSupply.add(_amount);
        _cogBalances[_to] = _cogBalances[_to].add(_amount);
        emit CognitionTokensMinted(_to, _amount);
    }

    /// @notice Transfers $COG tokens from the sender to a recipient.
    /// @param _recipient The address to receive tokens.
    /// @param _amount The amount of $COG to transfer.
    function transferCognitionTokens(address _recipient, uint256 _amount) public whenNotPaused returns (bool) {
        require(_recipient != address(0), "NN: Transfer to the zero address");
        require(_cogBalances[msg.sender] >= _amount, "NN: Insufficient COG balance");

        _cogBalances[msg.sender] = _cogBalances[msg.sender].sub(_amount);
        _cogBalances[_recipient] = _cogBalances[_recipient].add(_amount);
        // In a full ERC20, an event `Transfer(msg.sender, _recipient, _amount)` would be emitted here.
        return true;
    }

    /// @notice Approves a spender to spend $COG tokens on behalf of the sender.
    /// @param _spender The address authorized to spend.
    /// @param _amount The maximum amount of $COG that can be spent.
    function approveCognitionTokens(address _spender, uint256 _amount) public whenNotPaused returns (bool) {
        _cogAllowances[msg.sender][_spender] = _amount;
        // In a full ERC20, an event `Approval(msg.sender, _spender, _amount)` would be emitted here.
        return true;
    }

    /// @notice Returns the amount of $COG that an owner allowed to a spender.
    /// @param _owner The address of the owner.
    /// @param _spender The address of the spender.
    /// @return The allowance amount.
    function allowanceCognitionTokens(address _owner, address _spender) public view returns (uint256) {
        return _cogAllowances[_owner][_spender];
    }

    /// @notice Burns $COG tokens from the sender's balance.
    /// @param _amount The amount of $COG to burn.
    function burnCognitionTokens(uint256 _amount) public whenNotPaused {
        require(_cogBalances[msg.sender] >= _amount, "NN: Burn amount exceeds balance");
        _cogBalances[msg.sender] = _cogBalances[msg.sender].sub(_amount);
        _cogTotalSupply = _cogTotalSupply.sub(_amount);
        emit CognitionTokensBurned(msg.sender, _amount);
    }

    /// @notice Returns the $COG balance of an address.
    /// @param _account The address to query.
    /// @return The balance.
    function balanceOfCog(address _account) public view returns (uint256) {
        return _cogBalances[_account];
    }

    /// @notice Returns the total supply of $COG tokens.
    /// @return The total supply.
    function getTotalSupplyCog() public view returns (uint256) {
        return _cogTotalSupply;
    }

    // --- Neural Unit (NNU) Management (ERC-721 functions are internal/simplified) ---

    /// @notice Mints a new Neural Unit NFT to a specified address.
    /// @param _to The recipient address.
    /// @return The ID of the newly minted Neural Unit.
    function mintNeuralUnit(address _to) public whenNotPaused returns (uint256) {
        _neuralUnitTokenIds.increment();
        uint256 newId = _neuralUnitTokenIds.current();
        _neuralUnitOwners[newId] = _to;
        _neuralUnitBalanceOf[_to] = _neuralUnitBalanceOf[_to].add(1);

        // Initialize synaptic weights (e.g., to neutral/base values)
        neuralUnitSynapticWeights[newId][0] = 5000;
        neuralUnitSynapticWeights[newId][1] = 5000;
        neuralUnitSynapticWeights[newId][2] = 5000;
        neuralUnitLastTrainingTime[newId] = block.timestamp; // Set initial last training time

        emit NeuralUnitMinted(_to, newId);
        return newId;
    }

    /// @notice Returns the current synaptic weights (attributes) of a Neural Unit.
    /// @param _tokenId The ID of the Neural Unit.
    /// @return An array of the three synaptic weights.
    function getNeuralUnitSynapticWeights(uint256 _tokenId) public view returns (uint256[3] memory) {
        require(_neuralUnitOwners[_tokenId] != address(0), "NN: Neural Unit does not exist");
        return neuralUnitSynapticWeights[_tokenId];
    }

    /// @notice Core function to update a Neural Unit's weights based on training data impact and quality.
    /// This simulates the "learning" process. Only the owner or an approved address can evolve.
    /// @param _tokenId The ID of the Neural Unit to evolve.
    /// @param _dataImpact A value representing the magnitude of data impact (e.g., from 0-10000).
    /// @param _qualityScore The quality of the submitted data (e.g., from 0-10000).
    function evolveNeuralUnitWeights(uint256 _tokenId, uint256 _dataImpact, uint256 _qualityScore) public whenNotPaused {
        require(_neuralUnitOwners[_tokenId] == msg.sender || _neuralUnitApproved[_tokenId] == msg.sender, "NN: Not owner or approved for Neural Unit");
        require(_neuralUnitOwners[_tokenId] != address(0), "NN: Neural Unit does not exist");
        require(_qualityScore >= MIN_DATA_QUALITY, "NN: Data quality too low for effective evolution");
        
        int256 evolutionFactor = adaptiveParameters[PARAM_NEURAL_EVOLUTION_FACTOR]; // e.g., 100 = 1x (100 basis points)
        
        uint256 oldWeight0 = neuralUnitSynapticWeights[_tokenId][0];
        uint256 oldWeight1 = neuralUnitSynapticWeights[_tokenId][1];
        uint252 oldWeight2 = neuralUnitSynapticWeights[_tokenId][2]; // No need for temporary variable for `oldWeight2`
        
        // Simulate evolution: weights adjust based on data impact and quality
        // The `evolutionFactor` is applied as a multiplier. Divided by 100 for basis points (100 = 1x).
        int256 change0 = int256(_dataImpact).mul(evolutionFactor).div(10000); // Scale by 10000 to normalize _dataImpact
        int256 change1 = int256(_qualityScore).mul(evolutionFactor).div(10000);

        neuralUnitSynapticWeights[_tokenId][0] = uint256(Math.max(int256(MIN_SYNAPTIC_WEIGHT), Math.min(int256(MAX_SYNAPTIC_WEIGHT), int256(oldWeight0) + change0)));
        neuralUnitSynapticWeights[_tokenId][1] = uint256(Math.max(int256(MIN_SYNAPTIC_WEIGHT), Math.min(int256(MAX_SYNAPTIC_WEIGHT), int256(oldWeight1) + change1)));
        // Weight 2 is a composite, e.g., slightly influenced by the average change, ensuring it stays within bounds.
        neuralUnitSynapticWeights[_tokenId][2] = uint256(Math.max(int256(MIN_SYNAPTIC_WEIGHT), Math.min(int256(MAX_SYNAPTIC_WEIGHT), int256(oldWeight2) + (change0 + change1) / 20)));

        neuralUnitLastTrainingTime[_tokenId] = block.timestamp;
        
        emit NeuralUnitEvolved(_tokenId, _dataImpact, _qualityScore, neuralUnitSynapticWeights[_tokenId]);
    }

    /// @notice Transfers a Neural Unit NFT. (Simplified ERC-721 transferFrom)
    /// @param _from The current owner of the NFT.
    /// @param _to The recipient of the NFT.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNeuralUnit(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_neuralUnitOwners[_tokenId] == _from, "NN: Caller is not owner of token");
        require(_from == msg.sender || _neuralUnitApproved[_tokenId] == msg.sender, "NN: Not authorized to transfer");
        require(_to != address(0), "NN: Transfer to the zero address");

        _neuralUnitBalanceOf[_from] = _neuralUnitBalanceOf[_from].sub(1);
        _neuralUnitOwners[_tokenId] = _to;
        _neuralUnitBalanceOf[_to] = _neuralUnitBalanceOf[_to].add(1);
        _neuralUnitApproved[_tokenId] = address(0); // Clear approval after transfer
        // In a full ERC721, a `Transfer(from, to, tokenId)` event would be emitted.
    }
    
    /// @notice Returns the owner of a Neural Unit NFT.
    /// @param _tokenId The ID of the Neural Unit.
    /// @return The owner's address.
    function getNeuralUnitOwner(uint256 _tokenId) public view returns (address) {
        require(_neuralUnitOwners[_tokenId] != address(0), "NN: Neural Unit does not exist");
        return _neuralUnitOwners[_tokenId];
    }

    /// @notice Returns the total supply of Neural Units.
    /// @return The total supply.
    function getTotalSupplyNnu() public view returns (uint256) {
        return _neuralUnitTokenIds.current();
    }

    /// @notice Returns the URI for a given NNU token ID. (Conceptual for future metadata)
    /// @param _tokenId The ID of the Neural Unit.
    /// @return The URI string.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_neuralUnitOwners[_tokenId] != address(0), "NNU: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /// @notice Sets the base URI for all Neural Unit NFTs.
    /// @dev This function would typically be callable by governance or owner to update metadata.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    // --- Inference/Training Module ---

    /// @notice Allows users to stake $COG tokens to participate in training.
    /// @param _amount The amount of $COG to stake.
    function stakeCognitionForTraining(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "NN: Stake amount must be greater than 0");
        require(_cogBalances[msg.sender] >= _amount, "NN: Insufficient COG balance for staking");

        // Before staking, ensure any pending staking rewards are accounted for up to this point
        _calculateStakingRewards(msg.sender);

        _cogBalances[msg.sender] = _cogBalances[msg.sender].sub(_amount);
        stakedCogBalances[msg.sender] = stakedCogBalances[msg.sender].add(_amount);
        lastRewardClaimTime[msg.sender] = block.timestamp; // Reset timer for new stake calculation
        
        emit CognitionStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake $COG tokens.
    /// @param _amount The amount of $COG to unstake.
    function unstakeCognitionFromTraining(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "NN: Unstake amount must be greater than 0");
        require(stakedCogBalances[msg.sender] >= _amount, "NN: Insufficient staked COG balance");

        // Distribute any pending rewards before unstaking
        _distributeTrainingRewards(msg.sender);

        stakedCogBalances[msg.sender] = stakedCogBalances[msg.sender].sub(_amount);
        _cogBalances[msg.sender] = _cogBalances[msg.sender].add(_amount);
        lastRewardClaimTime[msg.sender] = block.timestamp; // Reset timer even after unstake for consistency
        
        emit CognitionUnstaked(msg.sender, _amount);
    }

    /// @notice Users submit data batches, initiating Neural Unit evolution and potentially earning rewards.
    /// Requires staked COG. The `_dataHash` and `_processingPowerContribution` are conceptual.
    /// @param _neuralUnitId The ID of the Neural Unit targeted for training.
    /// @param _dataHash A hash representing the unique data batch (conceptual, not verified on-chain).
    /// @param _processingPowerContribution Simulated contribution (conceptual).
    /// @param _dataQualityScore The quality of the submitted data (influences rewards and evolution).
    function submitTrainingDataBatch(
        uint256 _neuralUnitId,
        uint256 _dataHash, // Unique identifier for the data batch (e.g., IPFS CID hash)
        uint256 _processingPowerContribution, // Conceptual "compute" contributed
        uint256 _dataQualityScore // Quality score provided by the data provider (would be verified by oracle in real system)
    ) public whenNotPaused {
        require(stakedCogBalances[msg.sender] > 0, "NN: Must have staked COG to submit training data");
        require(_neuralUnitOwners[_neuralUnitId] != address(0), "NN: Neural Unit does not exist");
        require(_dataQualityScore >= MIN_DATA_QUALITY, "NN: Data quality too low");

        // Distribute any pending staking rewards up to this point
        _calculateStakingRewards(msg.sender);

        // Automatically evolve the Neural Unit based on the data
        evolveNeuralUnitWeights(_neuralUnitId, _processingPowerContribution, _dataQualityScore);

        // Calculate rewards based on quality and current adaptive parameters
        // Example: reward is (quality * rate) / 100 for basis points, or simply (quality * rate)
        uint256 cogReward = _dataQualityScore.mul(uint256(adaptiveParameters[PARAM_TRAINING_REWARD_RATE_COG]));
        uint256 infReward = _dataQualityScore.mul(uint256(adaptiveParameters[PARAM_TRAINING_REWARD_RATE_INF]));

        pendingCogRewards[msg.sender] = pendingCogRewards[msg.sender].add(cogReward);
        pendingInfRewards[msg.sender] = pendingInfRewards[msg.sender].add(infReward);

        emit TrainingDataSubmitted(msg.sender, _neuralUnitId, _dataHash, _dataQualityScore);
    }

    /// @notice Calculates and adds staking rewards to pending rewards based on staked amount and time.
    /// @param _user The address for whom to calculate rewards.
    function _calculateStakingRewards(address _user) internal {
        uint256 stakedAmount = stakedCogBalances[_user];
        if (stakedAmount == 0) return;

        uint256 timeElapsed = block.timestamp.sub(lastRewardClaimTime[_user]);
        if (timeElapsed == 0) return;

        // Rewards based on (staked amount * APR * time_elapsed) / SECONDS_IN_YEAR
        uint256 apr = uint256(adaptiveParameters[PARAM_STAKING_APR_COG]); // in basis points, e.g., 500 for 5%
        // Rewards = stakedAmount * APR_BP / 10000 * timeElapsed / SECONDS_IN_YEAR
        uint256 rewards = stakedAmount.mul(apr).mul(timeElapsed).div(10000).div(SECONDS_IN_YEAR);

        pendingCogRewards[_user] = pendingCogRewards[_user].add(rewards);
        lastRewardClaimTime[_user] = block.timestamp;
    }

    /// @notice Internal function to distribute pending training and staking rewards.
    /// @param _user The user to distribute rewards to.
    function _distributeTrainingRewards(address _user) internal {
        _calculateStakingRewards(_user); // First calculate staking rewards up to current block.

        uint256 cogToClaim = pendingCogRewards[_user];
        uint256 infToClaim = pendingInfRewards[_user];

        if (cogToClaim > 0) {
            _cogTotalSupply = _cogTotalSupply.add(cogToClaim); // Mint rewards (increases total supply)
            _cogBalances[_user] = _cogBalances[_user].add(cogToClaim);
            pendingCogRewards[_user] = 0;
        }
        if (infToClaim > 0) {
            _influenceBalances[_user] = _influenceBalances[_user].add(infToClaim); // INF is only minted, not burned from supply
            pendingInfRewards[_user] = 0;
        }
        if (cogToClaim > 0 || infToClaim > 0) {
            emit TrainingRewardsClaimed(_user, cogToClaim, infToClaim);
        }
    }

    /// @notice Allows users to claim accumulated $COG and $INF rewards from training and staking.
    function claimTrainingRewards() public whenNotPaused {
        _distributeTrainingRewards(msg.sender);
    }

    /// @notice Returns pending $COG and $INF rewards for a user.
    /// @param _user The user's address.
    /// @return cogPending The amount of pending $COG.
    /// @return infPending The amount of pending $INF.
    function getPendingTrainingRewards(address _user) public view returns (uint256 cogPending, uint256 infPending) {
        // Simulate rewards calculation without modifying state for view function
        uint256 currentCogPending = pendingCogRewards[_user];
        uint256 currentInfPending = pendingInfRewards[_user];

        uint256 stakedAmount = stakedCogBalances[_user];
        if (stakedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(lastRewardClaimTime[_user]);
            if (timeElapsed > 0) {
                uint256 apr = uint256(adaptiveParameters[PARAM_STAKING_APR_COG]);
                uint256 rewards = stakedAmount.mul(apr).mul(timeElapsed).div(10000).div(SECONDS_IN_YEAR);
                currentCogPending = currentCogPending.add(rewards);
            }
        }
        return (currentCogPending, currentInfPending);
    }

    /// @notice Returns the amount of $COG staked by a user.
    /// @param _user The user's address.
    /// @return The staked amount.
    function getStakedCogBalance(address _user) public view returns (uint256) {
        return stakedCogBalances[_user];
    }

    /// @notice Retrieves a simplified history of training events for a Neural Unit.
    /// @dev In a real scenario, this would involve more complex event indexing or on-chain data structures.
    /// For this example, it just returns the last training timestamp.
    /// @param _neuralUnitId The ID of the Neural Unit.
    /// @return The timestamp of the last training event.
    function getNeuralUnitTrainingHistory(uint256 _neuralUnitId) public view returns (uint256 lastTrainingTime) {
        require(_neuralUnitOwners[_neuralUnitId] != address(0), "NN: Neural Unit does not exist");
        return neuralUnitLastTrainingTime[_neuralUnitId];
    }


    // --- Influence Points ($INF) & Reputation (Internal ERC-20 like) ---

    /// @notice Returns the $INF balance of a user.
    /// @param _user The user's address.
    /// @return The $INF balance.
    function getInfluencePoints(address _user) public view returns (uint256) {
        return _influenceBalances[_user];
    }

    /// @notice Allows users to delegate their $INF-based influence to another address (e.g., for governance).
    /// @param _delegatee The address to delegate influence to.
    function delegateInfluence(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "NN: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "NN: Cannot delegate to self");
        _influenceDelegates[msg.sender] = _delegatee;
        emit InfluenceDelegated(msg.sender, _delegatee, _influenceBalances[msg.sender]); // Emits current influence for context
    }

    /// @notice Allows users to burn $INF to propose or accelerate a specific adaptive parameter change.
    /// This is a unique mechanic where burning reputation can influence system dynamics.
    /// @dev This function currently only logs the action. In a more complex system,
    /// it could affect a proposal's voting weight, or directly bias the `triggerAutomatedAdaptationCycle`.
    /// @param _amount The amount of $INF to burn.
    /// @param _parameterIndex The index of the adaptive parameter to conceptually boost.
    /// @param _boostValue The conceptual value to add/subtract to the parameter's next automated adaptation cycle or proposal vote weight.
    function burnInfluenceForAdaptiveBoost(uint256 _amount, uint256 _parameterIndex, int256 _boostValue) public whenNotPaused {
        require(_influenceBalances[msg.sender] >= _amount, "NN: Insufficient INF balance to burn");
        require(_parameterIndex < PARAM_COUNT, "NN: Invalid parameter index");

        _influenceBalances[msg.sender] = _influenceBalances[msg.sender].sub(_amount);
        
        emit InfluenceBurnedForBoost(msg.sender, _amount, _parameterIndex, _boostValue);
    }

    // --- Adaptive Engine & Governance ---

    /// @notice Users can propose changes to system's adaptive parameters.
    /// Requires a minimum COG stake defined by `PARAM_MIN_PROPOSAL_COG_STAKE`.
    /// @param _description A description of the proposal.
    /// @param _parameterIndex The index of the adaptive parameter to change.
    /// @param _newValue The proposed new value for the parameter.
    /// @param _voteThreshold The percentage (in basis points, e.g., 5000 for 50%) of total voting power required to pass.
    /// @param _duration The duration of the voting period in seconds.
    /// @return The ID of the created proposal.
    function proposeAdaptiveParameterChange(
        string memory _description,
        uint256 _parameterIndex,
        int256 _newValue,
        uint256 _voteThreshold,
        uint256 _duration
    ) public whenNotPaused returns (uint256) {
        require(stakedCogBalances[msg.sender] >= uint256(adaptiveParameters[PARAM_MIN_PROPOSAL_COG_STAKE]), "NN: Insufficient staked COG to propose");
        require(_parameterIndex < PARAM_COUNT, "NN: Invalid parameter index for proposal");
        require(_duration > 0, "NN: Proposal duration must be positive");
        require(_voteThreshold > 0 && _voteThreshold <= 10000, "NN: Vote threshold must be between 1 and 10000 BP");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            description: _description,
            parameterIndex: _parameterIndex,
            newValue: _newValue,
            recipient: address(0), // Not applicable for parameter change
            amount: 0,             // Not applicable for parameter change
            voteThreshold: _voteThreshold,
            startTime: block.timestamp,
            endTime: block.timestamp.add(_duration),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            isTreasuryProposal: false
        });

        emit ParameterChangeProposed(proposalId, _description, _parameterIndex, _newValue, _voteThreshold, _duration);
        return proposalId;
    }

    /// @notice Users vote on active governance proposals.
    /// Voting power is based on $INF balance (delegated or direct).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnAdaptiveParameterChange(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NN: Proposal does not exist"); // Check if proposal initialized
        require(proposal.state == ProposalState.Active, "NN: Proposal is not active");
        require(block.timestamp <= proposal.endTime, "NN: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "NN: Already voted on this proposal");
        require(!proposal.isTreasuryProposal, "NN: Use voteOnTreasuryAllocation for treasury proposals");

        address voterInfluenceSource = _influenceDelegates[msg.sender] != address(0) ? _influenceDelegates[msg.sender] : msg.sender;
        uint256 voteWeight = _influenceBalances[voterInfluenceSource];
        require(voteWeight > 0, "NN: No influence points to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @notice Executes an approved adaptive parameter change proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeAdaptiveParameterChange(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NN: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "NN: Proposal is not active");
        require(block.timestamp > proposal.endTime, "NN: Voting period has not ended");
        require(!proposal.isTreasuryProposal, "NN: Use executeTreasuryAllocation for treasury proposals");

        // The denominator for quorum calculation is typically total circulating governance tokens or total staked tokens.
        // For simplicity, `_cogTotalSupply` is used as a proxy for total potential voting power.
        // In a real DAO, this would be a snapshot of actual voting power.
        uint256 totalPotentialVotingPower = _cogTotalSupply;
        uint256 requiredVotes = totalPotentialVotingPower.mul(proposal.voteThreshold).div(10000);

        if (proposal.votesFor >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            adaptiveParameters[proposal.parameterIndex] = proposal.newValue;
            emit ParameterChangeExecuted(proposal.id, proposal.parameterIndex, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /// @notice Returns the current values of all adaptive parameters.
    /// @return An array containing the current values of the parameters.
    function getCurrentAdaptiveParameters() public view returns (int256[PARAM_COUNT] memory) {
        int256[PARAM_COUNT] memory currentParams;
        for (uint256 i = 0; i < PARAM_COUNT; i++) {
            currentParams[i] = adaptiveParameters[i];
        }
        return currentParams;
    }

    /// @notice Callable by a trusted oracle/keeper, auto-adjusts parameters based on network activity and health metrics.
    /// @dev This simulates an on-chain "AI" that adjusts system parameters. The logic here is simplified.
    /// @dev For simplicity, only `owner` can call, but in production, it would be a decentralized keeper network or a more complex governance mechanism.
    function triggerAutomatedAdaptationCycle() public onlyOwner whenNotPaused {
        // This function would ideally analyze on-chain metrics (e.g., number of active stakers,
        // average daily training submissions, NFT evolution rates).
        // For demonstration, let's use current `_cogTotalSupply` as a simple proxy for network activity/health.
        uint256 networkActivityScore = _cogTotalSupply; // Simplified proxy

        int256 currentStakingApr = adaptiveParameters[PARAM_STAKING_APR_COG];
        int256 currentInfRewardRate = adaptiveParameters[PARAM_TRAINING_REWARD_RATE_INF];
        int256 currentEvolutionFactor = adaptiveParameters[PARAM_NEURAL_EVOLUTION_FACTOR];

        // Example adaptation rules:
        // If network activity (proxy by total supply) is low, slightly increase staking APR to incentivize.
        if (networkActivityScore < (INITIAL_COG_SUPPLY / 2)) {
            adaptiveParameters[PARAM_STAKING_APR_COG] = currentStakingApr.add(50); // Increase APR by 0.5% (50 BP)
        } else if (networkActivityScore > INITIAL_COG_SUPPLY * 2) {
            // If too much supply/activity, might decrease APR to manage inflation
            adaptiveParameters[PARAM_STAKING_APR_COG] = currentStakingApr.sub(20); // Decrease APR by 0.2% (20 BP)
        }
        // Ensure APR stays within sensible bounds (e.g., 1% to 100%)
        adaptiveParameters[PARAM_STAKING_APR_COG] = Math.max(100, Math.min(10000, adaptiveParameters[PARAM_STAKING_APR_COG]));

        // Further adaptive logic could be added based on other metrics (e.g., if NFT evolution is too slow, increase evolution factor).
        
        emit AutomatedAdaptationTriggered(block.timestamp);
    }

    // --- Treasury Management & Research Funding ---

    /// @notice Allows anyone to deposit ETH into the treasury.
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows anyone to deposit ETH into the treasury via explicit function call.
    function depositTreasuryFunds() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Proposes allocation of treasury funds for research or network improvements.
    /// Requires a minimum COG stake defined by `PARAM_MIN_PROPOSAL_COG_STAKE`.
    /// @param _description A description of the treasury allocation proposal.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of ETH to allocate.
    /// @param _voteThreshold The percentage (in basis points) of total voting power required to pass.
    /// @param _duration The duration of the voting period in seconds.
    /// @return The ID of the created proposal.
    function proposeTreasuryAllocation(
        string memory _description,
        address _recipient,
        uint256 _amount,
        uint256 _voteThreshold,
        uint256 _duration
    ) public whenNotPaused returns (uint256) {
        require(stakedCogBalances[msg.sender] >= uint256(adaptiveParameters[PARAM_MIN_PROPOSAL_COG_STAKE]), "NN: Insufficient staked COG to propose");
        require(_recipient != address(0), "NN: Recipient cannot be zero address");
        require(_amount > 0, "NN: Allocation amount must be positive");
        require(_duration > 0, "NN: Proposal duration must be positive");
        require(_voteThreshold > 0 && _voteThreshold <= 10000, "NN: Vote threshold must be between 1 and 10000 BP");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            description: _description,
            parameterIndex: type(uint256).max, // Sentinel value for non-parameter proposal
            newValue: 0,                   // Not applicable for treasury proposal
            recipient: _recipient,
            amount: _amount,
            voteThreshold: _voteThreshold,
            startTime: block.timestamp,
            endTime: block.timestamp.add(_duration),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            isTreasuryProposal: true
        });

        emit TreasuryAllocationProposed(proposalId, _description, _recipient, _amount, _voteThreshold, _duration);
        return proposalId;
    }

    /// @notice Votes on treasury allocation proposals.
    /// Uses the same voting logic as parameter changes (based on $INF balance).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnTreasuryAllocation(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NN: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "NN: Proposal is not active");
        require(block.timestamp <= proposal.endTime, "NN: Voting period has ended");
        require(proposal.isTreasuryProposal, "NN: Use voteOnAdaptiveParameterChange for parameter proposals");
        require(!proposal.hasVoted[msg.sender], "NN: Already voted on this proposal");

        address voterInfluenceSource = _influenceDelegates[msg.sender] != address(0) ? _influenceDelegates[msg.sender] : msg.sender;
        uint256 voteWeight = _influenceBalances[voterInfluenceSource];
        require(voteWeight > 0, "NN: No influence points to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @notice Executes an approved treasury allocation proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeTreasuryAllocation(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "NN: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "NN: Proposal is not active");
        require(block.timestamp > proposal.endTime, "NN: Voting period has not ended");
        require(proposal.isTreas TreasuryProposal, "NN: Use executeAdaptiveParameterChange for parameter proposals");
        require(address(this).balance >= proposal.amount, "NN: Insufficient treasury balance");

        // Similar quorum logic as parameter changes. Using COG total supply as a proxy for total voting power.
        uint256 totalPotentialVotingPower = _cogTotalSupply;
        uint256 requiredVotes = totalPotentialVotingPower.mul(proposal.voteThreshold).div(10000);

        if (proposal.votesFor >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            (bool success,) = payable(proposal.recipient).call{value: proposal.amount}("");
            require(success, "NN: ETH transfer failed for treasury allocation");
            emit TreasuryAllocationExecuted(proposal.id, proposal.recipient, proposal.amount);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /// @notice Returns the current ETH balance of the treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the current state of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The state enum value.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "NN: Proposal does not exist");
        GovernanceProposal storage proposal = proposals[_proposalId];
        
        // If the proposal is active and its voting period has ended,
        // re-evaluate its state for a real-time view.
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.endTime) {
            uint256 totalPotentialVotingPower = _cogTotalSupply; // Proxy for total
            uint256 requiredVotes = totalPotentialVotingPower.mul(proposal.voteThreshold).div(10000);

            if (proposal.votesFor >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }
}

// Simple Math library for min/max on uint256 and int256
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}

```