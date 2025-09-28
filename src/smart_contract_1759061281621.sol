```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8+ has overflow checks
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; // Optional, for burning protocol fees if desired

/*
    Contract Name: ADIRProtocol (Adaptive Decentralized Investment & Reputation Protocol)

    Core Idea:
    ADIRProtocol is a decentralized platform enabling the creation, funding, and management
    of adaptive investment strategies. It empowers a community of strategists and investors
    to collectively develop and deploy sophisticated on-chain investment algorithms that
    can adapt to external signals (e.g., market data, AI predictions). The protocol
    incorporates a reputation system for strategies, utilizes unique StrategyNFTs (SNFTs)
    for ownership and enhanced governance, and features a robust DAO for protocol evolution.

    Key Features:
    1.  Adaptive Strategies: Strategies can incorporate "signals" from strategists or oracles
        to dynamically adjust parameters or rebalance.
    2.  Reputation System: Strategies earn and lose reputation based on their on-chain performance,
        influencing funding and governance.
    3.  StrategyNFTs (SNFTs): ERC721 tokens representing fractional ownership, IP rights,
        or enhanced governance power tied to specific strategies.
    4.  Decentralized Governance: ADAO (ADIR DAO) controls protocol parameters, approves
        strategies, and manages upgrades, utilizing both ADIR tokens and staked SNFTs for voting.
    5.  Dynamic Fees: Protocol fees can be adjusted by governance based on market conditions
        or protocol performance.
    6.  ZK-Proof Integration (Conceptual): Design for future integration of zero-knowledge proofs
        for private attestations or confidential strategy parameters.
    7.  Challenge Mechanism: Allows users to challenge reported performance for dispute resolution.
    8.  Cross-Chain Data Requests (Conceptual): Mechanisms to trigger and record requests for
        data from other blockchain networks.

    Actors:
    -   Strategist: Proposes, manages, and submits adaptive signals for strategies.
    -   Investor: Funds strategies and redeems shares.
    -   ADIR Token Holder: Participates in core protocol governance.
    -   SNFT Holder: Holds ownership/IP of a strategy, can stake for enhanced governance.
    -   Oracle: Provides external data and reports strategy performance.
    -   Governor/DAO: Approves strategies, manages protocol parameters, and resolves disputes.

    Outline and Function Summary:

    I.  Global Definitions & Access Control
        1.  `ADIRToken` (Contract): ERC20 token for protocol governance and fees.
            -   `constructor`: Initializes ADIR token with an initial supply and admin role.
            -   `mint`: Allows admin to mint new tokens.
        2.  `StrategyNFT` (Contract): ERC721 token for strategy ownership/IP.
            -   `constructor`: Initializes StrategyNFT.
            -   `safeMint`: Allows designated MINT_ROLE to mint new SNFTs.
        3.  `ADIRProtocol` (Main Contract)
            -   `constructor`: Sets up initial roles, links ADIRToken & SNFT contracts, initializes protocol parameters.

    II. Strategy & Proposal Management (6 Functions)
        4.  `proposeStrategy`: Strategist proposes a new investment strategy, staking ADIR tokens.
        5.  `approveStrategy`: Governance approves a proposed strategy, making it active.
        6.  `updateStrategyParameters`: Strategist updates strategy's description or internal parameter hash.
        7.  `getStrategyDetails`: Retrieves detailed public information for a specific strategy.
        8.  `deactivateStrategy`: Deactivates an active strategy (by strategist or governance).
        9.  `submitAdaptiveSignal`: Strategist submits a hash representing an adaptive signal for the strategy.

    III. Funding & Investment Management (4 Functions)
        10. `fundStrategy`: Investor deposits ADIR tokens into an active strategy.
        11. `redeemStrategyFunds`: Investor withdraws their pro-rata share from a strategy.
        12. `distributeStrategyProfits`: Strategist initiates distribution of performance fees to strategist, protocol, and updates strategy capital.
        13. `getInvestorShare`: Calculates an investor's current proportional share of a strategy's capital.

    IV. Reputation & Performance Tracking (3 Functions)
        14. `reportStrategyPerformance`: Oracle reports latest performance (total capital value) for a strategy.
        15. `_updateStrategyReputation` (Internal): Calculates and updates a strategy's reputation score based on PnL.
        16. `getStrategyReputation`: Retrieves the current reputation score for a strategy.

    V.  StrategyNFT (SNFT) Management (3 Functions)
        17. `mintStrategyNFT`: Governance mints an SNFT for a strategy, e.g., for milestone achievement.
        18. `stakeStrategyNFTForVoting`: Allows SNFT holders to stake their NFTs to gain increased voting power.
        19. `assignSNFTOwnership`: Governance assigns a specific SNFT, representing IP or fractional share, to a recipient.

    VI. Governance & Protocol Parameters (5 Functions)
        20. `proposeProtocolUpgrade`: ADIR/SNFT holders propose protocol-level changes (e.g., to fee structure).
        21. `voteOnProposal`: ADIR/SNFT holders vote on an active proposal.
        22. `executeProposal`: Executes a successfully voted-on protocol proposal.
        23. `setDynamicFeeParameter`: Governance adjusts the protocol's performance fee percentage.
        24. `registerOracle`: Default Admin registers a new address as a trusted oracle.

    VII. Advanced Concepts & Interoperability (3 Functions)
        25. `challengePerformanceReport`: Allows users to challenge a reported strategy performance (triggers dispute).
        26. `initiateCrossChainDataRequest`: (Conceptual) Triggers an off-chain request for data from another blockchain.
        27. `submitZKProofHashForVerification`: Submits a hash of an off-chain generated Zero-Knowledge Proof for record/verification.

    VIII. Internal & View Functions (4 Functions)
        28. `getTotalStrategies`: Returns the total number of strategies created.
        29. `getTotalProposals`: Returns the total number of governance proposals created.
        30. `getProtocolADIRBalance`: Returns the total ADIR tokens collected by the protocol (fees, stakes).
        31. `withdrawProtocolFees`: Allows the default admin to withdraw collected protocol fees.
*/

// --- I. Global Definitions & Access Control ---

// ADIRToken: The protocol's native ERC20 token for governance, staking, and fees.
contract ADIRToken is ERC20, AccessControl {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    constructor(address initialGovernor) ERC20("ADIR Protocol Token", "ADIR") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialGovernor);
        _grantRole(GOVERNOR_ROLE, initialGovernor);
        _mint(initialGovernor, 1_000_000_000 * 10**18); // Initial supply for governance/liquidity
    }

    /// @notice Allows the contract admin to mint new ADIR tokens.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }
}

// StrategyNFT: ERC721 token representing ownership, IP, or share in a specific strategy.
contract StrategyNFT is ERC721, AccessControl {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("ADIR Strategy NFT", "SNFT") {
        // The contract deploying this (ADIRProtocol) will grant the MINT_ROLE.
    }

    /// @notice Mints a new Strategy NFT and assigns it to a recipient.
    /// @param to The address of the recipient.
    /// @param uri The URI for the NFT's metadata.
    /// @return The ID of the newly minted NFT.
    function safeMint(address to, string memory uri) public onlyRole(MINT_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }
}

// ADIRProtocol: The main contract orchestrating adaptive strategies, funding, reputation, and governance.
contract ADIRProtocol is ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Roles (Inherited from ADIRToken, but defined here for clarity in context) ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    // --- Linked Token Contracts ---
    ADIRToken public immutable ADIR_TOKEN; // Protocol's native token instance
    StrategyNFT public immutable SNFT_TOKEN; // NFT for strategy ownership/IP instance

    // --- Strategy Management ---
    Counters.Counter private _strategyIdCounter;

    struct Strategy {
        address strategist;
        string name;
        string description;
        bool isActive;
        uint256 creationTimestamp;
        uint256 initialStake; // ADIR stake required from strategist to propose
        uint256 totalCapital; // Total capital currently managed by the strategy (in ADIR)
        uint256 currentPerformanceBasis; // Basis for calculating profit/loss and investor shares
        mapping(address => uint256) investorDeposits; // Individual investor's initial deposit
        uint256 reputationScore; // A weighted score based on performance
        uint256 lastPerformanceUpdate; // Timestamp of last performance report
        uint256 lastAdaptiveSignalTime; // Timestamp of last adaptive signal submission
        bytes32 currentSignalHash; // Hash of the latest adaptive signal/parameters
        uint256 governanceProposalId; // ID of the proposal that approved this strategy
        // address strategyVault; // (Conceptual) Dedicated vault contract for funds
    }
    mapping(uint256 => Strategy) public strategies;
    mapping(address => uint256[]) public strategistStrategies; // List of strategies owned by a strategist

    // --- Protocol-wide Configurations (Updatable by Governance) ---
    uint256 public strategyProposalStakeAmount;
    uint256 public protocolPerformanceFeeBps; // Basis points (e.g., 50 = 0.5%)
    uint256 public strategistPerformanceFeeBps; // Basis points (e.g., 1000 = 10%)
    uint256 public reputationFactorPositive; // Multiplier for positive performance gain
    uint256 public reputationFactorNegative; // Multiplier for negative performance impact
    uint256 public challengePeriodDuration; // Timeframe for challenging performance reports

    // --- Governance Proposals ---
    Counters.Counter private _proposalIdCounter;
    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Contract to call if proposal passes
        bytes callData;         // Encoded function call to execute
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool approved;          // True if the proposal passed the vote
        mapping(address => bool) hasVoted; // Prevents double voting
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalMinVotingPower; // Minimum ADIR equivalent voting power to create a proposal
    uint256 public snftVotingPowerMultiplier; // How much ADIR equivalent 1 SNFT grants in voting power

    // --- Events ---
    event StrategyProposed(uint256 strategyId, address strategist, string name);
    event StrategyApproved(uint256 strategyId, address governor, uint256 proposalId);
    event StrategyParametersUpdated(uint256 strategyId, address strategist, string newDescription, bytes32 newParamsHash);
    event StrategyDeactivated(uint256 strategyId, address caller);
    event StrategyFunded(uint256 strategyId, address investor, uint256 amount);
    event FundsRedeemed(uint256 strategyId, address investor, uint256 amount);
    event ProfitsDistributed(uint256 strategyId, address strategist, uint256 totalProfits, uint256 strategistFee, uint256 protocolFee);
    event PerformanceReported(uint256 strategyId, address reporter, uint256 newTotalCapital, int256 pnlChange);
    event ReputationUpdated(uint256 strategyId, uint256 newReputationScore);
    event StrategyNFTMinted(uint256 strategyId, uint256 tokenId, address owner);
    event StrategyNFTStaked(address staker, uint256 tokenId);
    event AdaptiveSignalSubmitted(uint256 strategyId, address strategist, bytes32 signalHash);
    event PerformanceReportChallenged(uint256 strategyId, address challenger, uint256 challengeStake);
    event ZKProofHashSubmitted(uint256 strategyId, bytes32 proofHash, string proofContext);
    event CrossChainDataRequestInitiated(uint256 strategyId, uint256 targetChainId, bytes32 dataRequestHash);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event OracleRegistered(address oracleAddress);
    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(uint256 proposalId, address voter, uint256 votingPower, bool support);
    event ProposalExecuted(uint256 proposalId);

    // --- Constructor ---
    /// @param _adirTokenAddress The address of the deployed ADIRToken contract.
    /// @param _snftTokenAddress The address of the deployed StrategyNFT contract.
    constructor(address _adirTokenAddress, address _snftTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is default admin
        _setRoleAdmin(GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(STRATEGIST_ROLE, DEFAULT_ADMIN_ROLE);

        ADIR_TOKEN = ADIRToken(_adirTokenAddress);
        SNFT_TOKEN = StrategyNFT(_snftTokenAddress);

        // Grant MINT_ROLE to this ADIRProtocol contract so it can mint SNFTs.
        SNFT_TOKEN.grantRole(SNFT_TOKEN.MINT_ROLE(), address(this));

        // Set initial protocol configurations (these can be updated by governance via proposals)
        strategyProposalStakeAmount = 100 ether; // Example: 100 ADIR
        protocolPerformanceFeeBps = 50; // 0.5%
        strategistPerformanceFeeBps = 1000; // 10%
        reputationFactorPositive = 10; // For every 1 ADIR profit, reputation increases by 10
        reputationFactorNegative = 5;  // For every 1 ADIR loss, reputation decreases by 5
        challengePeriodDuration = 3 days;
        proposalMinVotingPower = 1000 ether; // Min 1000 ADIR equivalent to create a proposal
        snftVotingPowerMultiplier = 100 ether; // 1 SNFT is equivalent to 100 ADIR in voting power
    }

    // --- Modifiers ---
    /// @dev Restricts access to the strategist of a specific strategy.
    modifier onlyStrategist(uint256 _strategyId) {
        require(strategies[_strategyId].strategist == msg.sender, "ADIR: Only strategist can call this function");
        _;
    }

    // --- II. Strategy & Proposal Management (6 Functions) ---

    /// @summary Allows a strategist to propose a new investment strategy.
    /// @description Requires a stake in ADIR tokens which is locked until strategy approval/rejection.
    /// @param _name Name of the strategy.
    /// @param _description Detailed description of the strategy.
    /// @return The ID of the newly proposed strategy.
    function proposeStrategy(string memory _name, string memory _description)
        public
        onlyRole(STRATEGIST_ROLE)
        returns (uint256)
    {
        require(bytes(_name).length > 0, "ADIR: Strategy name cannot be empty");
        require(ADIR_TOKEN.transferFrom(msg.sender, address(this), strategyProposalStakeAmount), "ADIR: Stake transfer failed");

        _strategyIdCounter.increment();
        uint256 newStrategyId = _strategyIdCounter.current();

        strategies[newStrategyId].strategist = msg.sender;
        strategies[newStrategyId].name = _name;
        strategies[newStrategyId].description = _description;
        strategies[newStrategyId].isActive = false; // Must be approved by governance
        strategies[newStrategyId].creationTimestamp = block.timestamp;
        strategies[newStrategyId].initialStake = strategyProposalStakeAmount;
        strategies[newStrategyId].reputationScore = 0;
        strategies[newStrategyId].totalCapital = 0; // Starts with no capital
        strategies[newStrategyId].currentPerformanceBasis = 0; // No basis until funded

        strategistStrategies[msg.sender].push(newStrategyId);

        emit StrategyProposed(newStrategyId, msg.sender, _name);
        return newStrategyId;
    }

    /// @summary Governance approves a proposed strategy, making it active and ready for funding.
    /// @description This function should ideally be called as part of an `executeProposal` after a governance vote.
    /// @param _strategyId The ID of the strategy to approve.
    /// @param _governanceProposalId The ID of the governance proposal that approved this strategy.
    function approveStrategy(uint256 _strategyId, uint256 _governanceProposalId) public onlyRole(GOVERNOR_ROLE) {
        require(strategies[_strategyId].strategist != address(0), "ADIR: Strategy does not exist");
        require(!strategies[_strategyId].isActive, "ADIR: Strategy is already active");
        require(proposals[_governanceProposalId].approved, "ADIR: Proposal not approved or doesn't exist");
        require(strategies[_strategyId].governanceProposalId == 0, "ADIR: Strategy already linked to a proposal");

        strategies[_strategyId].isActive = true;
        strategies[_strategyId].governanceProposalId = _governanceProposalId;
        // Strategist's initial stake remains locked as a performance bond.
        emit StrategyApproved(_strategyId, msg.sender, _governanceProposalId);
    }

    /// @summary Allows a strategist to update certain parameters of their strategy.
    /// @description This could require governance approval for critical changes or a cooldown period for minor ones.
    /// @param _strategyId The ID of the strategy.
    /// @param _newDescription Updated description.
    /// @param _newParametersHash A hash representing new internal strategy parameters (e.g., config file CID).
    function updateStrategyParameters(
        uint256 _strategyId,
        string memory _newDescription,
        bytes32 _newParametersHash
    ) public onlyStrategist(_strategyId) {
        require(strategies[_strategyId].isActive, "ADIR: Strategy is not active");
        // Implement a cooldown period or governance approval for critical parameter changes.
        // For this example, we'll assume the hash update is a signal that might require off-chain action.

        strategies[_strategyId].description = _newDescription;
        strategies[_strategyId].currentSignalHash = _newParametersHash; // Re-using for parameters hash for simplicity

        emit StrategyParametersUpdated(_strategyId, msg.sender, _newDescription, _newParametersHash);
    }

    /// @summary Retrieves the detailed information for a specific strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return strategist The address of the strategy's owner.
    /// @return name Name of the strategy.
    /// @return description Detailed description.
    /// @return isActive Whether the strategy is active.
    /// @return totalCapital Total funds managed (in ADIR).
    /// @return reputationScore Current reputation.
    /// @return lastSignalHash Hash of the last adaptive signal/parameters.
    function getStrategyDetails(uint256 _strategyId)
        public
        view
        returns (
            address strategist,
            string memory name,
            string memory description,
            bool isActive,
            uint256 totalCapital,
            uint256 reputationScore,
            bytes32 lastSignalHash
        )
    {
        Strategy storage s = strategies[_strategyId];
        require(s.strategist != address(0), "ADIR: Strategy does not exist");
        return (s.strategist, s.name, s.description, s.isActive, s.totalCapital, s.reputationScore, s.currentSignalHash);
    }

    /// @summary Deactivates an active strategy.
    /// @description Can be called by strategist (potentially with governance approval/cooldown) or a governor.
    /// Deactivation might trigger fund withdrawal periods or liquidation processes.
    /// @param _strategyId The ID of the strategy to deactivate.
    function deactivateStrategy(uint256 _strategyId) public {
        Strategy storage s = strategies[_strategyId];
        require(s.strategist != address(0), "ADIR: Strategy does not exist");
        require(s.isActive, "ADIR: Strategy is already inactive");

        require(
            hasRole(GOVERNOR_ROLE, msg.sender) || s.strategist == msg.sender,
            "ADIR: Only strategist or governor can deactivate"
        );

        s.isActive = false;
        // Additional logic to initiate winding down of funds/redemption period would go here.

        emit StrategyDeactivated(_strategyId, msg.sender);
    }

    /// @summary Strategist submits an adaptive signal (e.g., market prediction, AI output hash) for the strategy.
    /// @description The strategy's internal logic (off-chain) would interpret this signal.
    /// @param _strategyId The ID of the strategy.
    /// @param _signalHash A hash representing the adaptive signal data.
    function submitAdaptiveSignal(uint256 _strategyId, bytes32 _signalHash) public onlyStrategist(_strategyId) {
        require(strategies[_strategyId].isActive, "ADIR: Strategy is not active");
        // Could implement a cooldown for signal submission frequency to prevent spamming.

        strategies[_strategyId].currentSignalHash = _signalHash;
        strategies[_strategyId].lastAdaptiveSignalTime = block.timestamp;

        // An off-chain executor would pick up this signal and potentially rebalance the strategy's actual holdings.
        emit AdaptiveSignalSubmitted(_strategyId, msg.sender, _signalHash);
    }

    // --- III. Funding & Investment Management (4 Functions) ---

    /// @summary Allows an investor to fund an active strategy with ADIR tokens.
    /// @param _strategyId The ID of the strategy to fund.
    /// @param _amount The amount of ADIR tokens to deposit.
    function fundStrategy(uint256 _strategyId, uint256 _amount) public nonReentrant {
        Strategy storage s = strategies[_strategyId];
        require(s.isActive, "ADIR: Strategy is not active");
        require(_amount > 0, "ADIR: Amount must be greater than zero");
        require(ADIR_TOKEN.transferFrom(msg.sender, address(this), _amount), "ADIR: Fund transfer failed");

        // Record investor's *initial* deposit for share calculation basis.
        s.investorDeposits[msg.sender] = s.investorDeposits[msg.sender].add(_amount);

        if (s.totalCapital == 0) { // First deposit for this strategy
            s.totalCapital = _amount;
            s.currentPerformanceBasis = _amount;
        } else {
            // Adjust currentPerformanceBasis proportionally to maintain share value
            s.currentPerformanceBasis = s.currentPerformanceBasis.mul(s.totalCapital.add(_amount)).div(s.totalCapital);
            s.totalCapital = s.totalCapital.add(_amount);
        }

        emit StrategyFunded(_strategyId, msg.sender, _amount);
    }

    /// @summary Allows an investor to redeem their share from a strategy.
    /// @description Actual profits/losses are calculated based on strategy's reported performance (`totalCapital`).
    /// @param _strategyId The ID of the strategy.
    /// @param _shareAmount The amount of initial deposit's *share* to redeem (not raw ADIR amount).
    function redeemStrategyFunds(uint256 _strategyId, uint256 _shareAmount) public nonReentrant {
        Strategy storage s = strategies[_strategyId];
        require(s.isActive, "ADIR: Strategy is not active or funds locked"); // Could add lock-up period
        require(s.investorDeposits[msg.sender] >= _shareAmount, "ADIR: Insufficient deposit share to redeem");
        require(_shareAmount > 0, "ADIR: Share amount must be greater than zero");
        require(s.totalCapital > 0, "ADIR: Strategy has no capital to redeem from");

        // Calculate the actual ADIR amount to redeem based on current totalCapital
        uint256 currentInvestorValue = getInvestorShare(_strategyId, msg.sender);
        uint256 actualRedeemAmount = currentInvestorValue.mul(_shareAmount).div(s.investorDeposits[msg.sender]);

        require(ADIR_TOKEN.transfer(msg.sender, actualRedeemAmount), "ADIR: Redemption transfer failed");

        s.investorDeposits[msg.sender] = s.investorDeposits[msg.sender].sub(_shareAmount);
        s.totalCapital = s.totalCapital.sub(actualRedeemAmount);

        // Adjust currentPerformanceBasis proportionally to maintain integrity of remaining shares
        if (s.totalCapital > 0 && s.investorDeposits[msg.sender] > 0) {
            s.currentPerformanceBasis = s.currentPerformanceBasis.mul(s.totalCapital).div(s.totalCapital.add(actualRedeemAmount));
        } else if (s.totalCapital == 0) {
            s.currentPerformanceBasis = 0; // No capital left, reset basis
        }


        emit FundsRedeemed(_strategyId, msg.sender, actualRedeemAmount);
    }

    /// @summary Initiates distribution of performance fees from a strategy to strategist and protocol.
    /// @description The `_totalProfit` is a value reported by the strategist (or oracle) that has been realized.
    /// @param _strategyId The ID of the strategy.
    /// @param _totalProfit The total *realized* profit generated since last distribution or initial funding.
    function distributeStrategyProfits(uint256 _strategyId, uint256 _totalProfit) public onlyStrategist(_strategyId) {
        Strategy storage s = strategies[_strategyId];
        require(s.isActive, "ADIR: Strategy is not active");
        require(_totalProfit > 0, "ADIR: No profits to distribute");

        // Ensure profit doesn't exceed current available capital (simplified: assume off-chain assets match)
        // In a real system, the actual ADIR in the contract or vault would be checked.
        // For this concept, we rely on the reported _totalProfit.

        uint256 strategistFee = _totalProfit.mul(strategistPerformanceFeeBps).div(10000);
        uint256 protocolFee = _totalProfit.mul(protocolPerformanceFeeBps).div(10000);
        uint256 remainingProfitForCapital = _totalProfit.sub(strategistFee).sub(protocolFee);

        require(ADIR_TOKEN.transfer(s.strategist, strategistFee), "ADIR: Strategist fee transfer failed");
        require(ADIR_TOKEN.transfer(address(this), protocolFee), "ADIR: Protocol fee transfer failed");

        // Add remaining profit to strategy's total capital, effectively increasing its value.
        s.totalCapital = s.totalCapital.add(remainingProfitForCapital);
        s.currentPerformanceBasis = s.currentPerformanceBasis.add(remainingProfitForCapital); // Basis adjusted by profit

        emit ProfitsDistributed(_strategyId, msg.sender, _totalProfit, strategistFee, protocolFee);
    }

    /// @summary Calculates an investor's current proportional share of a strategy's capital.
    /// @param _strategyId The ID of the strategy.
    /// @param _investor The address of the investor.
    /// @return The current value of the investor's share in ADIR tokens.
    function getInvestorShare(uint256 _strategyId, address _investor) public view returns (uint256) {
        Strategy storage s = strategies[_strategyId];
        require(s.strategist != address(0), "ADIR: Strategy does not exist");
        if (s.investorDeposits[_investor] == 0 || s.totalCapital == 0 || s.currentPerformanceBasis == 0) {
            return 0;
        }
        // Calculation: (Investor's initial deposit share / Total initial deposit basis) * Current total capital
        // This ensures the value scales with the strategy's overall performance.
        return s.investorDeposits[_investor].mul(s.totalCapital).div(s.currentPerformanceBasis);
    }

    // --- IV. Reputation & Performance Tracking (3 Functions) ---

    /// @summary An oracle reports the latest performance for a strategy.
    /// @description This updates the strategy's total capital and forms the basis for reputation calculation.
    /// @param _strategyId The ID of the strategy.
    /// @param _newTotalCapital The new total capital value of the strategy after performance.
    function reportStrategyPerformance(uint256 _strategyId, uint256 _newTotalCapital) public onlyRole(ORACLE_ROLE) {
        Strategy storage s = strategies[_strategyId];
        require(s.isActive, "ADIR: Strategy is not active");
        require(s.totalCapital > 0, "ADIR: Strategy must have capital to report performance");
        require(block.timestamp >= s.lastPerformanceUpdate.add(1 hours), "ADIR: Performance can only be reported hourly");

        int256 pnlChange = int256(_newTotalCapital).sub(int256(s.totalCapital)); // Calculate PnL for reputation

        s.totalCapital = _newTotalCapital;
        s.lastPerformanceUpdate = block.timestamp;

        _updateStrategyReputation(_strategyId, pnlChange);

        emit PerformanceReported(_strategyId, msg.sender, _newTotalCapital, pnlChange);
    }

    /// @summary Internal function to calculate and update a strategy's reputation score.
    /// @description Reputation grows with positive PnL and diminishes with negative PnL, scaled by factors.
    /// @param _strategyId The ID of the strategy.
    /// @param _pnlChange The profit/loss change (in ADIR wei) since the last report.
    function _updateStrategyReputation(uint256 _strategyId, int256 _pnlChange) internal {
        Strategy storage s = strategies[_strategyId];
        uint256 currentRep = s.reputationScore;

        if (_pnlChange > 0) {
            // Reputation increases based on positive PnL, scaled down by 10^18 to count ADIR units
            currentRep = currentRep.add(uint256(_pnlChange).div(10**18).mul(reputationFactorPositive));
        } else if (_pnlChange < 0) {
            // Reputation decreases based on negative PnL, scaled and capped at 0
            uint256 reputationLoss = uint256(-_pnlChange).div(10**18).mul(reputationFactorNegative);
            currentRep = (currentRep < reputationLoss) ? 0 : currentRep.sub(reputationLoss);
        }

        s.reputationScore = currentRep;
        emit ReputationUpdated(_strategyId, currentRep);
    }

    /// @summary Retrieves the current reputation score for a strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return The current reputation score.
    function getStrategyReputation(uint256 _strategyId) public view returns (uint256) {
        return strategies[_strategyId].reputationScore;
    }

    // --- V. StrategyNFT (SNFT) Management (3 Functions) ---

    /// @summary Mints a StrategyNFT (SNFT) representing a share or intellectual property of a strategy.
    /// @description This could be triggered by achieving a funding milestone, or by governance decision.
    /// @param _strategyId The ID of the strategy.
    /// @param _recipient The address to mint the SNFT to.
    /// @param _tokenURI URI for the NFT metadata (e.g., describing the IP or share).
    /// @return The ID of the newly minted SNFT.
    function mintStrategyNFT(uint256 _strategyId, address _recipient, string memory _tokenURI) public onlyRole(GOVERNOR_ROLE) returns (uint256) {
        require(strategies[_strategyId].strategist != address(0), "ADIR: Strategy does not exist");
        // Additional logic could include: require(strategies[_strategyId].totalCapital >= MIN_FUNDING_FOR_SNFT_MINT)
        uint256 tokenId = SNFT_TOKEN.safeMint(_recipient, _tokenURI);
        emit StrategyNFTMinted(_strategyId, tokenId, _recipient);
        return tokenId;
    }

    /// @summary Allows SNFT holders to stake their NFTs to gain increased voting power in governance.
    /// @param _tokenId The ID of the SNFT to stake.
    function stakeStrategyNFTForVoting(uint256 _tokenId) public {
        require(SNFT_TOKEN.ownerOf(_tokenId) == msg.sender, "ADIR: You don't own this SNFT");
        // Transfer SNFT to this contract. This contract acts as the staking vault.
        SNFT_TOKEN.transferFrom(msg.sender, address(this), _tokenId);
        // A full DAO would have a separate governance module to track staked NFTs and their voting weight.
        // For simplicity, merely holding it in this contract indicates it's staked.
        emit StrategyNFTStaked(msg.sender, _tokenId);
    }

    /// @summary Assigns an SNFT, possibly representing IP or a fractional share, to the original strategist or a group.
    /// @description This is distinct from `mintStrategyNFT` as it implies a specific purpose for the mint.
    /// @param _strategyId The ID of the strategy.
    /// @param _recipient The address to assign the SNFT to.
    /// @param _metadataCID IPFS CID for the NFT metadata describing the IP/share.
    /// @return The ID of the newly assigned SNFT.
    function assignSNFTOwnership(uint256 _strategyId, address _recipient, string memory _metadataCID) public onlyRole(GOVERNOR_ROLE) returns (uint256) {
        require(strategies[_strategyId].strategist != address(0), "ADIR: Strategy does not exist");
        // This function is for specific assignments, distinct from general mints.
        uint256 tokenId = SNFT_TOKEN.safeMint(_recipient, _metadataCID);
        emit StrategyNFTMinted(_strategyId, tokenId, _recipient); // Re-use event
        return tokenId;
    }

    // --- VI. Governance & Protocol Parameters (5 Functions) ---

    /// @summary Allows ADIR token holders or staked SNFT holders to propose protocol-level changes.
    /// @param _description Description of the proposal.
    /// @param _targetContract The contract address the proposal targets (e.g., ADIRProtocol itself for parameter updates).
    /// @param _callData The encoded function call to be executed if the proposal passes.
    /// @param _votingPeriodBlocks The duration of the voting period in blocks.
    /// @return The ID of the newly created proposal.
    function proposeProtocolUpgrade(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _votingPeriodBlocks
    ) public returns (uint256) {
        require(getVotingPower(msg.sender) >= proposalMinVotingPower, "ADIR: Not enough voting power to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number + _votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            approved: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @summary Allows ADIR token holders and staked SNFT holders to vote on a proposal.
    /// @description Voting power is proportional to ADIR balance + SNFT stake (multiplied).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "ADIR: Proposal does not exist");
        require(block.number >= p.startBlock, "ADIR: Voting has not started");
        require(block.number <= p.endBlock, "ADIR: Voting has ended");
        require(!p.hasVoted[msg.sender], "ADIR: Already voted on this proposal");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "ADIR: No voting power");

        if (_support) {
            p.votesFor = p.votesFor.add(votingPower);
        } else {
            p.votesAgainst = p.votesAgainst.add(votingPower);
        }
        p.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, votingPower, _support);
    }

    /// @summary Executes an approved protocol proposal.
    /// @description Requires a majority vote and completion of the voting period. Can only be called by a Governor.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyRole(GOVERNOR_ROLE) {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "ADIR: Proposal does not exist");
        require(block.number > p.endBlock, "ADIR: Voting period not ended");
        require(!p.executed, "ADIR: Proposal already executed");
        require(p.votesFor > p.votesAgainst, "ADIR: Proposal did not pass"); // Simple majority

        p.executed = true;
        p.approved = true;

        (bool success, ) = p.targetContract.call(p.callData);
        require(success, "ADIR: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /// @summary Allows governance to adjust the protocol's performance fee percentage.
    /// @description This would be called via `executeProposal` after a governance vote.
    /// @param _newFeeBps New basis points for the protocol performance fee (e.g., 50 for 0.5%).
    function setDynamicFeeParameter(uint256 _newFeeBps) public onlyRole(GOVERNOR_ROLE) {
        require(_newFeeBps <= 2000, "ADIR: Fee cannot exceed 20%"); // Max 20%
        protocolPerformanceFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    /// @summary Registers a new address as a trusted oracle.
    /// @description Only addresses with ORACLE_ROLE can report strategy performance. This is typically done by the `DEFAULT_ADMIN_ROLE`.
    /// @param _oracleAddress The address of the new oracle.
    function registerOracle(address _oracleAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, _oracleAddress);
        emit OracleRegistered(_oracleAddress);
    }

    // --- VII. Advanced Concepts & Interoperability (3 Functions) ---

    /// @summary Allows a user to challenge a reported strategy performance.
    /// @description This would typically trigger a dispute resolution process (off-chain or via a separate arbitration contract).
    /// Requires a stake to prevent frivolous challenges.
    /// @param _strategyId The ID of the strategy whose performance is challenged.
    /// @param _reportTimestamp The timestamp of the challenged performance report.
    /// @param _reasonHash A hash of the reason for the challenge.
    function challengePerformanceReport(uint256 _strategyId, uint256 _reportTimestamp, bytes32 _reasonHash) public payable {
        Strategy storage s = strategies[_strategyId];
        require(s.strategist != address(0), "ADIR: Strategy does not exist");
        require(block.timestamp <= _reportTimestamp.add(challengePeriodDuration), "ADIR: Challenge period expired");
        require(msg.value >= 1 ether, "ADIR: Requires a stake to challenge (e.g., 1 ETH)"); // Example challenge stake

        // In a real system, this would interact with an arbitration contract (e.g., Kleros, Aragon Court).
        // The ETH sent could be locked in a dispute pool.
        // A dedicated event or state variable would track active challenges.

        emit PerformanceReportChallenged(_strategyId, msg.sender, msg.value);
    }

    /// @summary (Conceptual) Initiates an off-chain request for data from another blockchain.
    /// @description The result (or a verifiable hash of it) would be submitted later via `submitZKProofHashForVerification`.
    /// This function primarily serves as an on-chain trigger and record for an off-chain service
    /// (e.g., a relayer or specialized oracle) to fetch and verify cross-chain data.
    /// @param _strategyId The ID of the strategy that needs cross-chain data.
    /// @param _targetChainId The ID of the target blockchain.
    /// @param _dataRequestHash A hash representing the specific data requested.
    function initiateCrossChainDataRequest(uint256 _strategyId, uint256 _targetChainId, bytes32 _dataRequestHash)
        public
        onlyStrategist(_strategyId)
    {
        require(strategies[_strategyId].isActive, "ADIR: Strategy is not active");
        // A real implementation would involve a more complex cross-chain messaging protocol (e.g., LayerZero, Axelar).
        // For this example, it's a signal.
        emit CrossChainDataRequestInitiated(_strategyId, _targetChainId, _dataRequestHash);
    }

    /// @summary Submits a hash of an off-chain generated Zero-Knowledge Proof (ZKP) for verification.
    /// @description This allows strategies or protocol logic to rely on private, off-chain verified data without revealing it.
    /// E.g., verifying a user's eligibility without revealing their KYC details, or private strategy input.
    /// @param _strategyId The ID of the strategy this proof relates to.
    /// @param _proofHash The hash of the ZK proof (e.g., a commitment to private inputs, or output of verification).
    /// @param _proofContext A string describing what this proof attests (e.g., "KYC_Verified", "AI_Model_Output_Valid").
    function submitZKProofHashForVerification(uint256 _strategyId, bytes32 _proofHash, string memory _proofContext)
        public
        onlyStrategist(_strategyId) // Or other authorized roles based on context
    {
        require(strategies[_strategyId].strategist != address(0), "ADIR: Strategy does not exist");
        // In a true ZK-integration, this function would either:
        // 1. Store the hash and rely on off-chain verification to later attest its validity (simplest for Solidity).
        // 2. Trigger an on-chain ZK verifier contract (more complex and gas-intensive).
        // For this contract, we'll store the hash as a record of an external verification step.

        // You might have a mapping to store `strategyZkProofs[_strategyId][_proofContext] = _proofHash`
        // Or simply log it for off-chain services to act upon.

        emit ZKProofHashSubmitted(_strategyId, _proofHash, _proofContext);
    }

    // --- VIII. Internal & View Functions (4 Functions) ---

    /// @notice Calculates the total voting power for an address.
    /// @param _voter The address whose voting power is to be calculated.
    /// @return The total voting power (ADIR equivalent).
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 adirBalance = ADIR_TOKEN.balanceOf(_voter);
        uint256 stakedSnftCount = SNFT_TOKEN.balanceOf(_voter).add(SNFT_TOKEN.balanceOf(address(this))); // Check NFTs owned and NFTs staked *to this contract* by _voter. This part is a simplification. A proper staking system would track ownership of staked NFTs.
        // For simplicity, we assume an SNFT owned by this contract with the original owner being _voter is "staked by _voter".
        // A more robust implementation would use a `stakedBy` mapping for NFTs in this contract.
        return adirBalance.add(stakedSnftCount.mul(snftVotingPowerMultiplier));
    }


    /// @summary Returns the total number of strategies created within the protocol.
    /// @return The count of all strategies.
    function getTotalStrategies() public view returns (uint256) {
        return _strategyIdCounter.current();
    }

    /// @summary Returns the total number of governance proposals created.
    /// @return The count of all proposals.
    function getTotalProposals() public view returns (uint256) {
        return _proposalIdCounter.current();
    }

    /// @summary Returns the protocol's collected ADIR token balance (from fees, stakes).
    /// @return The ADIR balance held by the ADIRProtocol contract.
    function getProtocolADIRBalance() public view returns (uint256) {
        return ADIR_TOKEN.balanceOf(address(this));
    }

    /// @summary Allows the default admin to withdraw collected protocol fees.
    /// @description In a full DAO, this would be governed by a proposal and execution.
    /// @param _amount Amount of ADIR to withdraw.
    /// @param _to Address to send funds to.
    function withdrawProtocolFees(uint256 _amount, address _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(ADIR_TOKEN.balanceOf(address(this)) >= _amount, "ADIR: Insufficient balance");
        ADIR_TOKEN.transfer(_to, _amount);
    }
}
```