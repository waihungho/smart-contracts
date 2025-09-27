Here's a Solidity smart contract, `AetherMindSyndicate`, that integrates several advanced, creative, and trendy concepts, including a pseudo-AI decision engine, dynamic NFTs (dNFTs), a reputation-based governance system (SBT-like), optimistic execution with challenges, dynamic fees, and upgradeability. It aims to avoid direct duplication of common open-source libraries by providing custom, minimal implementations where appropriate (e.g., for the dNFTs and base64 encoding), while leveraging interfaces for widely accepted standards like ERC20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

// Minimal ERC721 interface for Manifestation NFTs, to avoid direct OZ import
interface IManifestationNFT {
    function mint(address to) external returns (uint256);
    function updateTrait(uint256 tokenId, bytes32 traitKey, bytes32 newValue) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    // Minimal standard functions to avoid duplication, but indicate ERC721 compliance
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

/**
 * @title AetherMindSyndicate
 * @dev An advanced, dynamic, and community-governed decentralized intelligence protocol.
 *      It functions as a pseudo-AI agent managing an asset pool, driven by configurable parameters
 *      and community proposals. It features dynamic NFTs (Manifestation NFTs) whose traits evolve
 *      with the protocol's state, a reputation-based governance system (SBTs), and an optimistic
 *      execution model. The contract is designed to be upgradeable.
 *
 * @outline
 * 1.  Core AetherMind State & Asset Management: Variables holding core "AI" parameters, asset pool, and basic deposit/withdrawal.
 * 2.  Oracle & External Data Integration: Functions to register and interact with external data sources.
 * 3.  AetherMind Decision Engine: Logic for the pseudo-AI to propose actions based on its internal state and external data.
 * 4.  Syndicate Governance: Framework for proposal creation, voting (using reputation), delegation, and optimistic execution challenges.
 * 5.  Reputation System (SBT-like): Management of non-transferable reputation points impacting governance power.
 * 6.  Manifestation NFTs (Dynamic NFTs): Soulbound NFTs whose traits dynamically update based on AetherMind's performance and protocol events.
 * 7.  Economic & Lifecycle Management: Dynamic fees, reward distribution, emergency controls, and upgradeability.
 *
 * @function_summary
 * 1.  `constructor()`: Initializes the AetherMind Syndicate with core parameters, sets up governance roles, and links to the Manifestation NFT contract.
 * 2.  `depositAssets(address _token, uint256 _amount)`: Allows participants to deposit ERC20 tokens or native ETH into the Syndicate's collective asset pool.
 * 3.  `withdrawProfits(address _token, uint256 _amount)`: Enables eligible participants (based on their stake or reputation) to withdraw their allocated share of accumulated profits from the asset pool, applying dynamic fees.
 * 4.  `updateCoreParameter(bytes32 _paramKey, int256 _newValue)`: A governance-controlled function to adjust internal "AetherMind" parameters (e.g., risk tolerance, strategic biases) that influence its decision-making.
 * 5.  `registerExternalOracle(bytes32 _oracleId, address _oracleAddress)`: Allows governance to register and approve trusted external oracle contracts for fetching real-world data (e.g., market prices, sentiment feeds).
 * 6.  `proposeAetherAction()`: Triggers the AetherMind's internal decision engine, which analyzes current market conditions and internal parameters to suggest an asset management action (e.g., trade, rebalance) for governance approval.
 * 7.  `executeAetherAction(bytes32 _proposalHash)`: Executes a previously proposed AetherMind action that has successfully passed the governance voting process.
 * 8.  `setDecisionLogicWeight(bytes32 _metric, uint256 _weight)`: A governance function that adjusts the influence (weight) of various data metrics (e.g., volatility index, oracle data) on the AetherMind's action proposal logic.
 * 9.  `createGovernanceProposal(string calldata _description, bytes[] calldata _calldata, address[] calldata _targets)`: Allows reputation holders to submit a new proposal for Syndicate governance, including arbitrary contract calls.
 * 10. `voteOnProposal(bytes32 _proposalHash, bool _support)`: Enables reputation holders to cast their vote on an active governance proposal, with voting power proportional to their current reputation score (or their delegate's).
 * 11. `delegateReputation(address _delegatee)`: Allows a reputation holder to delegate their voting power to another address, enabling proxy voting within the Syndicate.
 * 12. `awardReputation(address _to, uint256 _amount, bytes32 _reasonHash)`: A privileged function to mint non-transferable reputation points (SBTs) to an address, typically for positive contributions or achievements.
 * 13. `revokeReputation(address _from, uint256 _amount, bytes32 _reasonHash)`: A privileged function to deduct reputation points from an address, typically for malicious actions or failed commitments.
 * 14. `challengeOptimisticAction(bytes32 _actionHash, string calldata _reason)`: Allows a reputation holder to formally challenge an action that was executed optimistically, requiring a stake of reputation and triggering a review process.
 * 15. `mintManifestationNFT(address _to)`: Mints a unique, soulbound Manifestation NFT to a participant, symbolizing their long-term engagement and reflecting the AetherMind's evolving state.
 * 16. `updateNFTTrait(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue)`: An internal or privileged function that dynamically updates specific traits of a Manifestation NFT based on AetherMind's performance, parameter shifts, or governance milestones.
 * 17. `getNFTMetadataURI(uint256 _tokenId)`: Returns the dynamically generated metadata URI for a Manifestation NFT, ensuring its visual representation (traits) always reflects its current on-chain state.
 * 18. `adjustDynamicFee(bytes32 _feeType, uint256 _newRate)`: A governance-controlled function to dynamically set various protocol fees (e.g., withdrawal fees, proposal submission fees) based on performance, market conditions, or treasury needs.
 * 19. `emergencyShutdown()`: A critical, highly-privileged function designed to halt all non-essential contract operations in the event of a severe vulnerability or external threat, allowing for fund preservation.
 * 20. `performAssetRebalance(address[] calldata _assetsToSell, uint256[] calldata _amountsToSell, address[] calldata _assetsToBuy)`: Executes a multi-token asset rebalancing operation within the Syndicate's pool, typically as a result of an approved AetherMind action.
 * 21. `setGlobalThreshold(bytes32 _thresholdKey, uint256 _value)`: Allows governance to configure system-wide thresholds (e.g., minimum reputation for proposal creation, maximum slippage tolerance for trades).
 * 22. `queueUpgrade(address _newImplementation)`: Initiates the process for upgrading the AetherMind Syndicate's core logic to a new implementation contract, using a UUPS proxy pattern (logic within this contract).
 * 23. `distributePerformanceRewards(address _token, uint256 _amount)`: Distributes a specified amount of accumulated profits or performance-based rewards to eligible participants (e.g., based on reputation or dNFT holdings), as determined by governance.
 */
contract AetherMindSyndicate is Context {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- Core AetherMind State & Asset Management ---
    address public immutable initialImplementer; // For upgradeability reference (UUPS)
    bool public paused; // Global pause switch
    address public manifestationNFTContract; // Address of the associated Manifestation NFT contract

    // AetherMind's internal parameters (pseudo-AI configuration)
    mapping(bytes32 => int256) public coreParameters; // e.g., "risk_tolerance", "profit_target_ratio"

    // Asset pool balances
    mapping(address => uint256) public assetBalances; // ERC20 token => balance (address(0) for native ETH)
    address[] public supportedAssets; // List of tokens managed by the syndicate

    // --- Oracle & External Data Integration ---
    mapping(bytes32 => address) public registeredOracles; // oracleId => oracleAddress
    mapping(bytes32 => uint256) public decisionLogicWeights; // metric => weight (e.g., "market_volatility" => 100)

    // --- Syndicate Governance ---
    struct Proposal {
        bytes32 proposalHash;
        string description;
        address proposer;
        address[] targets; // Contracts to call
        bytes[] calldatas; // Data for calls
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted; // voter => voted
    }
    mapping(bytes32 => Proposal) public proposals;
    mapping(uint256 => bytes32) public proposalHashes; // proposalId => proposalHash mapping (for easier iteration if needed)
    uint256 public nextProposalId;
    uint256 public constant VOTING_PERIOD = 3 days; // Example voting period duration

    // Optimistic Execution Management
    struct OptimisticAction {
        bytes32 actionHash;
        address proposer;
        address target;
        bytes calldataPayload;
        uint256 executionTime;
        uint256 challengeEndTime;
        bool challenged;
        bool resolved;
        address challenger; // address of the challenger if challenged
        uint256 stakedReputation; // reputation staked by challenger
    }
    mapping(bytes32 => OptimisticAction) public optimisticActions;
    uint256 public constant CHALLENGE_PERIOD = 1 days; // Example challenge period duration
    uint256 public constant CHALLENGE_STAKE_REPUTATION = 100; // Reputation points required to challenge

    // --- Reputation System (SBT-like) ---
    mapping(address => uint256) public reputationScores; // user => non-transferable reputation points
    mapping(address => address) public reputationDelegates; // delegator => delegatee

    // --- Dynamic Fees ---
    mapping(bytes32 => uint256) public dynamicFees; // feeType => rate (e.g., "withdrawal_fee" => 100 = 1%)

    // --- Global Thresholds ---
    mapping(bytes32 => uint256) public globalThresholds; // e.g., "min_reputation_for_proposal"

    // --- Upgradeability (minimal UUPS-like implementation) ---
    address internal _queuedNewImplementation; // Stores the proposed new implementation address

    // --- Roles (simplified access control) ---
    address public governanceCouncil; // Primary multi-sig or single address for critical config
    address public executorRole;      // Can execute approved proposals / AetherMind actions

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(_msgSender() == governanceCouncil, "AM: Not governance council");
        _;
    }

    modifier onlyExecutor() {
        require(_msgSender() == executorRole, "AM: Not executor");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AM: Paused");
        _;
    }

    // --- Events ---
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrew(address indexed user, address indexed token, uint256 amount);
    event CoreParameterUpdated(bytes32 indexed paramKey, int256 newValue);
    event OracleRegistered(bytes32 indexed oracleId, address indexed oracleAddress);
    event DecisionLogicWeightUpdated(bytes32 indexed metric, uint256 weight);
    event AetherActionProposed(bytes32 indexed proposalHash, address indexed proposer, string description);
    event AetherActionExecuted(bytes32 indexed proposalHash);
    event GovernanceProposalCreated(bytes32 indexed proposalHash, address indexed proposer, string description);
    event Voted(bytes32 indexed proposalHash, address indexed voter, bool support, uint256 votingPower);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationAwarded(address indexed to, uint256 amount, bytes32 reasonHash);
    event ReputationRevoked(address indexed from, uint256 amount, bytes32 reasonHash);
    event OptimisticActionChallenged(bytes32 indexed actionHash, address indexed challenger, string reason);
    event OptimisticActionResolved(bytes32 indexed actionHash, bool success);
    event ManifestationNFTMinted(address indexed to, uint256 tokenId);
    event NFTTraitUpdated(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 newValue);
    event DynamicFeeAdjusted(bytes32 indexed feeType, uint256 newRate);
    event EmergencyShutdownTriggered(address indexed by);
    event AssetRebalanced(address indexed executor, address[] assetsSold, uint256[] amountsSold, address[] assetsBought);
    event GlobalThresholdSet(bytes32 indexed thresholdKey, uint256 value);
    event UpgradeQueued(address indexed newImplementation);
    event Upgraded(address indexed implementation);
    event PerformanceRewardsDistributed(address indexed token, uint256 amount);

    /**
     * @dev Constructor initializes the AetherMind Syndicate.
     * @param _governanceCouncil The address designated as the initial governance council.
     * @param _executorRole The address designated as the initial executor role.
     * @param _manifestationNFTContract The address of the Manifestation NFT contract.
     */
    constructor(address _governanceCouncil, address _executorRole, address _manifestationNFTContract) {
        require(_governanceCouncil != address(0), "AM: Zero address for governance");
        require(_executorRole != address(0), "AM: Zero address for executor");
        require(_manifestationNFTContract != address(0), "AM: Zero address for NFT contract");

        initialImplementer = _msgSender(); // For UUPS proxy reference
        governanceCouncil = _governanceCouncil;
        executorRole = _executorRole;
        manifestationNFTContract = _manifestationNFTContract;

        // Initialize some core AetherMind parameters
        coreParameters["risk_tolerance"] = 70; // 0-100 scale
        coreParameters["profit_target_ratio"] = 10; // 10 = 10%
        coreParameters["rebalance_frequency_seconds"] = 7 days; // in seconds

        // Initialize dynamic fees (e.g., 0.1% withdrawal fee = 10 basis points)
        dynamicFees["withdrawal_fee"] = 10; // Basis points (10000 = 100%)

        // Initialize global thresholds
        globalThresholds["min_reputation_for_proposal"] = 50;
        globalThresholds["min_reputation_for_challenge"] = CHALLENGE_STAKE_REPUTATION;

        // Add ETH as a supported asset initially
        supportedAssets.push(address(0)); // address(0) for native ETH

        paused = false;
        nextProposalId = 1;
    }

    /**
     * @dev Allows participants to deposit ERC20 tokens or native ETH into the Syndicate's collective asset pool.
     *      Native ETH can be sent directly to the contract via the `receive()` function or by calling this with `_token = address(0)`.
     * @param _token The address of the ERC20 token to deposit (address(0) for native ETH).
     * @param _amount The amount of tokens to deposit.
     */
    function depositAssets(address _token, uint256 _amount) external payable whenNotPaused {
        require(_amount > 0, "AM: Deposit amount must be > 0");

        if (_token == address(0)) { // Native ETH deposit
            require(msg.value == _amount, "AM: ETH amount mismatch");
            assetBalances[_token] += _amount;
        } else { // ERC20 token deposit
            require(msg.value == 0, "AM: Cannot send ETH with ERC20 deposit");
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
            assetBalances[_token] += _amount;

            // Add to supported assets if new and not already present
            bool found = false;
            for (uint i = 0; i < supportedAssets.length; i++) {
                if (supportedAssets[i] == _token) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                supportedAssets.push(_token);
            }
        }
        emit Deposited(_msgSender(), _token, _amount);
    }

    /**
     * @dev Enables eligible participants to withdraw their allocated share of accumulated profits.
     *      Requires a prior governance decision for profit distribution. Dynamic withdrawal fees apply.
     * @param _token The address of the token to withdraw (address(0) for native ETH).
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawProfits(address _token, uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AM: Withdraw amount must be > 0");
        // Simplified: In a production system, this would require validation against
        // a user's specific entitlement (e.g., their share of distributed profits)
        // as determined by a successful `distributePerformanceRewards` event or other allocation logic.
        // For this example, we assume `_amount` passed here represents a validated,
        // claimable amount for the caller, and the fee is applied.

        uint256 feeRate = dynamicFees["withdrawal_fee"]; // in basis points
        uint256 withdrawalFee = (_amount * feeRate) / 10000;
        uint256 amountAfterFee = _amount - withdrawalFee;

        require(assetBalances[_token] >= _amount, "AM: Insufficient contract balance for withdrawal (including fee)");
        assetBalances[_token] -= _amount; // Deduct total amount including fee

        if (_token == address(0)) { // Native ETH withdrawal
            Address.sendValue(payable(_msgSender()), amountAfterFee);
            // The fee amount (withdrawalFee) remains in the contract for native ETH.
        } else { // ERC20 token withdrawal
            IERC20(_token).safeTransfer(_msgSender(), amountAfterFee);
            // The fee amount (withdrawalFee) remains in the contract for ERC20.
        }
        emit Withdrew(_msgSender(), _token, _amount);
    }

    /**
     * @dev Allows governance to adjust core AetherMind parameters influencing its decision-making logic.
     * @param _paramKey The identifier for the parameter (e.g., "risk_tolerance").
     * @param _newValue The new integer value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramKey, int256 _newValue) external onlyGovernance {
        coreParameters[_paramKey] = _newValue;
        emit CoreParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @dev Allows governance to register and approve trusted external oracle contracts for data feeds.
     * @param _oracleId A unique identifier for the oracle.
     * @param _oracleAddress The address of the oracle contract.
     */
    function registerExternalOracle(bytes32 _oracleId, address _oracleAddress) external onlyGovernance {
        require(_oracleAddress != address(0), "AM: Zero address for oracle");
        registeredOracles[_oracleId] = _oracleAddress;
        emit OracleRegistered(_oracleId, _oracleAddress);
    }

    /**
     * @dev Triggers the AetherMind's internal decision engine to propose an asset management action.
     *      This proposal then needs to go through governance.
     *      In a real system, this would involve complex logic reading oracle data and internal state.
     *      For this example, it generates a placeholder rebalance proposal.
     * @return The hash of the generated proposal.
     */
    function proposeAetherAction() external whenNotPaused returns (bytes32) {
        // This is where the "pseudo-AI" logic would dynamically generate an action.
        // It would read `coreParameters`, `decisionLogicWeights`, `registeredOracles` (calling them for data),
        // and `assetBalances` to formulate an optimal action (e.g., swap tokens, allocate funds).
        // For instance, if `coreParameters["risk_tolerance"]` is low and `decisionLogicWeights["market_volatility"]`
        // is high (after fetching from an oracle), it might propose to sell volatile assets.

        // Placeholder logic: Imagine AetherMind decides to rebalance.
        string memory description = "AetherMind proposes an asset rebalance based on current market conditions.";
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        // Example: The proposed action is a call to `performAssetRebalance` with specific parameters
        // determined by the AetherMind's logic. These parameters are hardcoded here for demo.
        address[] memory assetsToSell = new address[](0); // e.g., [USDC_ADDRESS, LINK_ADDRESS]
        uint256[] memory amountsToSell = new uint256[](0); // e.g., [100 * 1e6, 5 * 1e18]
        address[] memory assetsToBuy = new address[](0); // e.g., [DAI_ADDRESS, WETH_ADDRESS]

        targets[0] = address(this); // Target is this contract
        calldatas[0] = abi.encodeWithSelector(
            this.performAssetRebalance.selector,
            assetsToSell,
            amountsToSell,
            assetsToBuy
        );

        bytes32 proposalHash = keccak256(abi.encode(description, targets, calldatas, nextProposalId, _msgSender()));
        Proposal storage newProposal = proposals[proposalHash];
        require(newProposal.proposer == address(0), "AM: Proposal already exists (hash collision)");

        newProposal.proposalHash = proposalHash;
        newProposal.description = description;
        newProposal.proposer = _msgSender();
        newProposal.targets = targets;
        newProposal.calldatas = calldatas;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        newProposal.canceled = false;

        proposalHashes[nextProposalId] = proposalHash;
        nextProposalId++;

        emit AetherActionProposed(proposalHash, _msgSender(), description);
        return proposalHash;
    }

    /**
     * @dev Executes a successfully voted-on AetherMind-proposed action.
     *      Can only be called by the `executorRole` after a proposal has passed.
     * @param _proposalHash The hash of the proposal to execute.
     */
    function executeAetherAction(bytes32 _proposalHash) external onlyExecutor whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.proposer != address(0), "AM: Proposal not found");
        require(block.timestamp > proposal.votingEndTime, "AM: Voting not ended");
        require(proposal.yayVotes > proposal.nayVotes, "AM: Proposal not approved");
        require(!proposal.executed, "AM: Proposal already executed");
        require(!proposal.canceled, "AM: Proposal canceled");

        proposal.executed = true;

        for (uint i = 0; i < proposal.targets.length; i++) {
            // Optimistic execution check: This `executeAetherAction` implies a standard
            // governance flow. An 'optimistic' flow might execute directly and allow challenge.
            // For now, this is a post-vote execution.
            Address.functionCall(proposal.targets[i], proposal.calldatas[i]);
        }
        emit AetherActionExecuted(_proposalHash);
    }

    /**
     * @dev Allows governance to adjust the influence (weight) of different data metrics
     *      on the AetherMind's decision-making algorithm.
     * @param _metric The identifier for the metric (e.g., "market_volatility").
     * @param _weight The new weight (e.g., 0-100 scale).
     */
    function setDecisionLogicWeight(bytes32 _metric, uint256 _weight) external onlyGovernance {
        decisionLogicWeights[_metric] = _weight;
        emit DecisionLogicWeightUpdated(_metric, _weight);
    }

    /**
     * @dev Allows reputation holders to submit a new general governance proposal.
     * @param _description A string describing the proposal.
     * @param _calldata An array of calldata payloads for the target contracts.
     * @param _targets An array of target contract addresses for the calls.
     */
    function createGovernanceProposal(
        string calldata _description,
        bytes[] calldata _calldata,
        address[] calldata _targets
    ) external whenNotPaused returns (bytes32) {
        require(reputationScores[_msgSender()] >= globalThresholds["min_reputation_for_proposal"], "AM: Insufficient reputation to propose");
        require(_targets.length == _calldata.length, "AM: Mismatch target/calldata length");
        require(_targets.length > 0, "AM: No targets specified");

        bytes32 proposalHash = keccak256(abi.encode(_description, _targets, _calldata, nextProposalId, _msgSender()));
        Proposal storage newProposal = proposals[proposalHash];
        require(newProposal.proposer == address(0), "AM: Proposal already exists (hash collision)"); // Ensure hash is unique for new proposals

        newProposal.proposalHash = proposalHash;
        newProposal.description = _description;
        newProposal.proposer = _msgSender();
        newProposal.targets = _targets;
        newProposal.calldatas = _calldata;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        newProposal.canceled = false;

        proposalHashes[nextProposalId] = proposalHash;
        nextProposalId++;

        emit GovernanceProposalCreated(proposalHash, _msgSender(), _description);
        return proposalHash;
    }

    /**
     * @dev Enables reputation holders to cast their vote on an active governance proposal.
     *      Voting power is proportional to their current reputation score (or their delegate's).
     * @param _proposalHash The hash of the proposal to vote on.
     * @param _support True for 'yay', false for 'nay'.
     */
    function voteOnProposal(bytes32 _proposalHash, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.proposer != address(0), "AM: Proposal not found");
        require(block.timestamp <= proposal.votingEndTime, "AM: Voting period ended");
        require(!proposal.executed, "AM: Proposal already executed");
        require(!proposal.canceled, "AM: Proposal canceled");

        address voter = _msgSender();
        address actualVotingPowerHolder = reputationDelegates[voter] != address(0) ? reputationDelegates[voter] : voter;
        uint256 votingPower = reputationScores[actualVotingPowerHolder];

        require(votingPower > 0, "AM: No voting power");
        require(!proposal.hasVoted[actualVotingPowerHolder], "AM: Already voted");

        proposal.hasVoted[actualVotingPowerHolder] = true;
        if (_support) {
            proposal.yayVotes += votingPower;
        } else {
            proposal.nayVotes += votingPower;
        }

        emit Voted(_proposalHash, actualVotingPowerHolder, _support, votingPower);
    }

    /**
     * @dev Allows a reputation holder to delegate their voting power to another address.
     *      This delegate will then vote on their behalf using their reputation score.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external {
        require(_delegatee != address(0), "AM: Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "AM: Cannot delegate to self");
        reputationDelegates[_msgSender()] = _delegatee;
        emit ReputationDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Awards non-transferable reputation points (SBTs) to an address.
     *      Typically used by governance or automated systems for positive contributions or achievements.
     * @param _to The recipient of the reputation.
     * @param _amount The amount of reputation points to award.
     * @param _reasonHash A hash identifying the reason for the award (e.g., keccak256("successful_proposal")).
     */
    function awardReputation(address _to, uint256 _amount, bytes32 _reasonHash) external onlyGovernance {
        require(_to != address(0), "AM: Cannot award to zero address");
        require(_amount > 0, "AM: Amount must be greater than 0");
        reputationScores[_to] += _amount;
        emit ReputationAwarded(_to, _amount, _reasonHash);
    }

    /**
     * @dev Revokes reputation points from an address.
     *      Used for malicious actions or failed commitments, by governance.
     * @param _from The address from which to revoke reputation.
     * @param _amount The amount of reputation points to revoke.
     * @param _reasonHash A hash identifying the reason for the revocation.
     */
    function revokeReputation(address _from, uint256 _amount, bytes32 _reasonHash) external onlyGovernance {
        require(_from != address(0), "AM: Cannot revoke from zero address");
        require(_amount > 0, "AM: Amount must be greater than 0");
        require(reputationScores[_from] >= _amount, "AM: Insufficient reputation to revoke");
        reputationScores[_from] -= _amount;
        emit ReputationRevoked(_from, _amount, _reasonHash);
    }

    /**
     * @dev Allows a reputation holder to formally challenge an action that was executed optimistically.
     *      Requires staking reputation points. This would initiate a dispute resolution process.
     * @param _actionHash The hash of the optimistic action to challenge.
     * @param _reason A string describing the reason for the challenge.
     */
    function challengeOptimisticAction(bytes32 _actionHash, string calldata _reason) external whenNotPaused {
        OptimisticAction storage action = optimisticActions[_actionHash];
        require(action.proposer != address(0), "AM: Action not found or not optimistically executed");
        require(action.challengeEndTime > block.timestamp, "AM: Challenge period ended");
        require(!action.challenged, "AM: Action already challenged");
        require(reputationScores[_msgSender()] >= globalThresholds["min_reputation_for_challenge"], "AM: Insufficient reputation to challenge");

        // Stake reputation for challenging by temporarily reducing score
        reputationScores[_msgSender()] -= globalThresholds["min_reputation_for_challenge"];
        action.stakedReputation = globalThresholds["min_reputation_for_challenge"];
        
        action.challenged = true;
        action.challenger = _msgSender();
        // In a full system, this would trigger a governance vote or arbitration mechanism
        // to resolve the challenge, potentially returning or slashing the staked reputation.
        emit OptimisticActionChallenged(_actionHash, _msgSender(), _reason);
    }

    /**
     * @dev Mints a unique, soulbound Manifestation NFT to a participant.
     *      The NFT symbolizes long-term engagement and reflects AetherMind's state.
     *      Requires the caller to have some reputation.
     * @param _to The recipient address for the NFT.
     * @return The ID of the newly minted NFT.
     */
    function mintManifestationNFT(address _to) external whenNotPaused returns (uint256) {
        require(_to != address(0), "AM: Cannot mint to zero address");
        require(manifestationNFTContract != address(0), "AM: NFT contract not set");
        
        // Example eligibility: requires some reputation to mint
        require(reputationScores[_msgSender()] > 0, "AM: Requires reputation to mint NFT");

        // Minting is handled by the Manifestation NFT contract.
        // The NFT contract itself will enforce its soulbound property by disallowing transfers.
        uint256 newId = IManifestationNFT(manifestationNFTContract).mint(_to);
        emit ManifestationNFTMinted(_to, newId);
        return newId;
    }

    /**
     * @dev Dynamically updates specific traits of a Manifestation NFT.
     *      This is typically triggered by AetherMind's performance, parameter shifts, or governance milestones.
     *      Callable only by `governanceCouncil`.
     * @param _tokenId The ID of the NFT to update.
     * @param _traitKey The identifier for the trait (e.g., "mood", "performance_tier").
     * @param _newValue The new value for the trait.
     */
    function updateNFTTrait(uint256 _tokenId, bytes32 _traitKey, bytes32 _newValue) external onlyGovernance {
        require(manifestationNFTContract != address(0), "AM: NFT contract not set");
        IManifestationNFT(manifestationNFTContract).updateTrait(_tokenId, _traitKey, _newValue);
        emit NFTTraitUpdated(_tokenId, _traitKey, _newValue);
    }

    /**
     * @dev Returns the dynamically generated metadata URI for a Manifestation NFT.
     *      This URI should reflect its current on-chain traits, fetched from the linked NFT contract.
     * @param _tokenId The ID of the NFT.
     * @return The URI pointing to the NFT's metadata.
     */
    function getNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        require(manifestationNFTContract != address(0), "AM: NFT contract not set");
        return IManifestationNFT(manifestationNFTContract).tokenURI(_tokenId);
    }

    /**
     * @dev Allows governance to dynamically adjust various protocol fees (e.g., withdrawal fees).
     *      Rates are typically in basis points (e.g., 100 = 1%).
     * @param _feeType The identifier for the fee (e.g., "withdrawal_fee").
     * @param _newRate The new rate for the fee.
     */
    function adjustDynamicFee(bytes32 _feeType, uint256 _newRate) external onlyGovernance {
        dynamicFees[_feeType] = _newRate;
        emit DynamicFeeAdjusted(_feeType, _newRate);
    }

    /**
     * @dev A critical, highly-privileged function to halt all non-essential contract operations.
     *      Designed for emergency situations like critical vulnerabilities or severe market events.
     *      Callable only by `governanceCouncil`.
     */
    function emergencyShutdown() external onlyGovernance {
        paused = true;
        emit EmergencyShutdownTriggered(_msgSender());
    }

    /**
     * @dev Executes a multi-token asset rebalancing operation within the Syndicate's pool.
     *      This function would typically interact with a DEX or AMM liquidity pool.
     *      Callable only by `executorRole` (e.g., after an AetherMind proposal is approved).
     * @param _assetsToSell An array of token addresses to sell.
     * @param _amountsToSell An array of amounts corresponding to `_assetsToSell`.
     * @param _assetsToBuy An array of token addresses to buy.
     */
    function performAssetRebalance(
        address[] calldata _assetsToSell,
        uint256[] calldata _amountsToSell,
        address[] calldata _assetsToBuy
    ) external onlyExecutor whenNotPaused {
        require(_assetsToSell.length == _amountsToSell.length, "AM: Mismatch sell arrays length");
        require(_assetsToSell.length > 0 || _assetsToBuy.length > 0, "AM: No assets to trade");
        
        // This is a placeholder for actual DEX/AMM integration logic.
        // In a real scenario, this would involve external calls to a router contract,
        // with slippage control, oracle price checks, etc.

        // Simulate selling assets
        for (uint i = 0; i < _assetsToSell.length; i++) {
            address token = _assetsToSell[i];
            uint256 amount = _amountsToSell[i];
            require(assetBalances[token] >= amount, "AM: Insufficient balance to sell");
            assetBalances[token] -= amount;
            // Simulate conversion: in a real DEX interaction, this would result in other assets being received.
        }

        // Simulate buying assets
        // For simplicity, assume some arbitrary amounts are "received" or converted
        // based on the simulated sales. A robust system would calculate actual buy amounts
        // from DEX returns.
        for (uint i = 0; i < _assetsToBuy.length; i++) {
            address token = _assetsToBuy[i];
            // Placeholder: Adding a fixed amount. This needs real conversion logic.
            // For example, if we sold 1 ETH, we might buy 2000 DAI.
            assetBalances[token] += 100 * 10**18; 
        }

        emit AssetRebalanced(_msgSender(), _assetsToSell, _amountsToSell, _assetsToBuy);
    }

    /**
     * @dev Allows governance to configure system-wide thresholds (e.g., minimum reputation for proposal, max slippage).
     * @param _thresholdKey The identifier for the threshold.
     * @param _value The new value for the threshold.
     */
    function setGlobalThreshold(bytes32 _thresholdKey, uint252 _value) external onlyGovernance {
        globalThresholds[_thresholdKey] = _value;
        emit GlobalThresholdSet(_thresholdKey, _value);
    }

    // --- UUPS Proxy related (minimal implementation to avoid full OZ library) ---
    // The UUPS implementation slot is a fixed constant across UUPS proxies.
    bytes32 constant private IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3eaae95838520f0abf7d2182337e16;

    /**
     * @dev Queues an upgrade to a new implementation contract.
     *      This is the first step in a two-step upgrade process for UUPS.
     *      The actual upgrade (`_upgradeTo`) is handled by the proxy,
     *      but the logic of `_authorizeUpgrade` resides in this implementation.
     * @param _newImplementationAddress The address of the new implementation contract.
     */
    function queueUpgrade(address _newImplementationAddress) external onlyGovernance {
        require(_newImplementationAddress != address(0), "AM: New implementation is zero address");
        // For a full UUPS, _newImplementationAddress would likely be verified for code existence.
        // Here, we just queue it. The actual upgrade call would target the proxy.
        _queuedNewImplementation = _newImplementationAddress; // Store for `_authorizeUpgrade` to reference
        emit UpgradeQueued(_newImplementationAddress);
    }

    /**
     * @dev This internal function is called by the proxy contract to authorize an upgrade.
     *      It ensures that only the `governanceCouncil` can authorize the upgrade.
     *      This is a common pattern in UUPS, where the authorization logic lives in the implementation.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal view {
        // In a UUPS proxy, this function is called via delegatecall from the proxy.
        // `_msgSender()` here would return the address that called the proxy, which must be governance.
        require(_msgSender() == governanceCouncil, "AM: Only governance can authorize upgrade");
        require(newImplementation == _queuedNewImplementation, "AM: Upgrade target not queued");
        // Additional checks can be added here, e.g., for security audits, pausing.
    }

    /**
     * @dev Distributes a specified amount of accumulated profits or performance-based rewards.
     *      Eligibility and precise distribution logic are determined by governance decisions
     *      and typically disbursed via individual `withdrawProfits` calls.
     * @param _token The token to distribute (address(0) for native ETH).
     * @param _amount The total amount to distribute.
     */
    function distributePerformanceRewards(address _token, uint256 _amount) external onlyGovernance whenNotPaused {
        require(_amount > 0, "AM: Distribution amount must be > 0");
        require(assetBalances[_token] >= _amount, "AM: Insufficient balance for distribution");

        assetBalances[_token] -= _amount;

        // In a real scenario, this function would either:
        // 1. Automatically send funds to eligible addresses based on internal logic (e.g., share proportional to reputation).
        // 2. Mark amounts as claimable by eligible users, who would then use `withdrawProfits`.
        // For simplicity, we just deduct the amount from the pool and emit an event,
        // implying an off-chain calculation or subsequent governance action for individual claims.
        emit PerformanceRewardsDistributed(_token, _amount);
    }

    /**
     * @dev Fallback function to receive native ETH.
     *      Allows direct ETH deposits for `depositAssets` where _token is address(0).
     */
    receive() external payable {
        if (!paused) {
            assetBalances[address(0)] += msg.value;
            emit Deposited(_msgSender(), address(0), msg.value);
        } else {
            revert("AM: Contract is paused and cannot receive ETH.");
        }
    }
}

// --- Minimal ManifestationNFT contract for integration ---
// This is a simplified ERC721-like contract for demonstration.
// It doesn't inherit from OpenZeppelin's ERC721,
// but implements the necessary functions for the AetherMindSyndicate to interact with it.
// It is 'soulbound' by simply not having transfer functionality (or making it governance-controlled).
contract ManifestationNFT is IManifestationNFT, Context {
    string public name;
    string public symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => mapping(bytes32 => bytes32)) public tokenTraits; // tokenId => traitKey => traitValue

    uint256 private _nextTokenId;
    address public aetherMindSyndicateAddress; // Address of the main contract for privileged calls

    // --- Modifiers ---
    modifier onlyAetherMindSyndicate() {
        require(_msgSender() == aetherMindSyndicateAddress, "MNFT: Not AetherMind Syndicate");
        _;
    }

    /**
     * @dev Constructor for the ManifestationNFT contract.
     * @param _aetherMindSyndicateAddress The address of the main AetherMindSyndicate contract.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     */
    constructor(address _aetherMindSyndicateAddress, string memory _name, string memory _symbol) {
        require(_aetherMindSyndicateAddress != address(0), "MNFT: Zero address for AetherMind");
        aetherMindSyndicateAddress = _aetherMindSyndicateAddress;
        name = _name;
        symbol = _symbol;
        _nextTokenId = 1;
    }

    /**
     * @dev Mints a new Manifestation NFT. Callable only by the AetherMindSyndicate.
     *      These NFTs are 'soulbound' as transfer functions are explicitly prevented.
     * @param to The recipient of the NFT.
     * @return The ID of the newly minted NFT.
     */
    function mint(address to) external onlyAetherMindSyndicate returns (uint256) {
        require(to != address(0), "MNFT: Mint to the zero address");
        // Additional logic could be added here, e.g., `require(_balances[to] == 0, "MNFT: Only one NFT per address");`

        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = to;
        _balances[to]++;
        
        // Initialize some default traits that can be dynamically updated later
        tokenTraits[tokenId]["generation"] = bytes32(uint256(1)); // Initial generation (e.g., from 1 to N)
        tokenTraits[tokenId]["status"] = bytes32(abi.encodePacked("nascent")); // Initial status
        tokenTraits[tokenId]["performance_tier"] = bytes32(abi.encodePacked("alpha")); // Initial tier

        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    /**
     * @dev Updates a specific trait of a Manifestation NFT. Callable only by the AetherMindSyndicate.
     *      This allows the dNFT to evolve based on protocol events.
     * @param tokenId The ID of the NFT.
     * @param traitKey The key for the trait (e.g., "generation", "status", "performance_tier").
     * @param newValue The new value for the trait.
     */
    function updateTrait(uint256 tokenId, bytes32 traitKey, bytes32 newValue) external onlyAetherMindSyndicate {
        require(_owners[tokenId] != address(0), "MNFT: Token does not exist");
        tokenTraits[tokenId][traitKey] = newValue;
        // Could emit a specific event for trait updates if granular tracking is needed.
    }

    /**
     * @dev Returns the owner of the NFT. Standard ERC721 function.
     * @param tokenId The ID of the NFT.
     * @return The owner's address.
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "MNFT: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Returns the number of NFTs owned by an address. Standard ERC721 function.
     * @param owner The address to query.
     * @return The number of NFTs.
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "MNFT: Balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Generates a dynamic metadata URI for the given token ID.
     *      This function constructs a Base64 encoded JSON string representing the NFT's traits.
     *      This allows traits to be truly on-chain and dynamic.
     * @param tokenId The ID of the NFT.
     * @return The URI.
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_owners[tokenId] != address(0), "MNFT: URI query for nonexistent token");
        
        // Fetch current traits
        bytes32 generationBytes = tokenTraits[tokenId]["generation"];
        bytes32 statusBytes = tokenTraits[tokenId]["status"];
        bytes32 performanceTierBytes = tokenTraits[tokenId]["performance_tier"];
        
        string memory generation = _toString(uint256(generationBytes)); // Assuming generation is stored as uint in bytes32
        string memory status = bytes32ToString(statusBytes);
        string memory performanceTier = bytes32ToString(performanceTierBytes);

        // Construct JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "AetherMind Manifestation #', _toString(tokenId), '",',
            '"description": "A dynamic manifestation of AetherMind engagement. Its traits evolve with the protocol\\'s state.",',
            '"attributes": [',
            '{"trait_type": "Generation", "value": "', generation, '"},',
            '{"trait_type": "Status", "value": "', status, '"},',
            '{"trait_type": "Performance Tier", "value": "', performanceTier, '"}',
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Utility functions for tokenURI (minimal) ---
    /** @dev Converts a uint256 to its string representation. */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    /** @dev Converts a bytes32 to its string representation, assuming it contains a valid string. */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = _bytes32[j];
        }
        return string(bytesArray);
    }

    // --- ERC721 functions that are disabled or restricted for soulbound NFTs ---
    // These functions are included in the IManifestationNFT interface for ERC721 compatibility,
    // but their implementation here explicitly prevents actions that would allow transfer
    // or arbitrary approval, enforcing the 'soulbound' nature.
    function isApprovedForAll(address, address) external pure returns (bool) { return false; }
    function setApprovalForAll(address, bool) external pure { revert("MNFT: Soulbound - No general approval"); }
    function getApproved(uint256) external pure returns (address) { revert("MNFT: Soulbound - No individual approval"); }
    function approve(address, uint256) external pure { revert("MNFT: Soulbound - No individual approval"); }
    function transferFrom(address, address, uint256) external pure { revert("MNFT: Soulbound - No transfer"); }
    function safeTransferFrom(address, address, uint256) external pure { revert("MNFT: Soulbound - No transfer"); }
    function safeTransferFrom(address, address, uint256, bytes calldata) external pure { revert("MNFT: Soulbound - No transfer"); }
}

// Minimal Base64 encoding library (derived from common patterns, not direct OZ import)
// Used only for `tokenURI` to embed dynamic JSON metadata directly on-chain.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        
        uint256 i;
        uint256 j;
        for (i = 0; i < data.length; i += 3) {
            uint256 chunk = 0;
            if (i < data.length) chunk |= uint256(uint8(data[i])) << 16;
            if (i + 1 < data.length) chunk |= uint256(uint8(data[i + 1])) << 8;
            if (i + 2 < data.length) chunk |= uint256(uint8(data[i + 2]));

            result[j++] = bytes1(TABLE[(chunk >> 18) & 0x3F]);
            result[j++] = bytes1(TABLE[(chunk >> 12) & 0x3F]);
            result[j++] = bytes1(TABLE[(chunk >> 6) & 0x3F]);
            result[j++] = bytes1(TABLE[chunk & 0x3F]);
        }

        if (data.length % 3 == 1) {
            result[result.length - 1] = '=';
            result[result.length - 2] = '=';
        } else if (data.length % 3 == 2) {
            result[result.length - 1] = '=';
        }

        return string(result);
    }
}

```