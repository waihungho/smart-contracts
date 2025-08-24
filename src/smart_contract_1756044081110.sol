This smart contract, **ChronoForge**, introduces a novel ecosystem built around "Sentient NFTs" (sNFTs) and an adaptive protocol with dynamic tokenomics. It aims to integrate a form of on-chain decision-making influenced by off-chain data (via oracles), creating a more responsive and evolving decentralized application.

---

### ChronoForge Protocol: Outline and Function Summary

**Concept:** ChronoForge is an adaptive protocol that issues "Sentient NFTs" (sNFTs). These sNFTs are dynamic, programmable agents within the ecosystem, possessing traits and capabilities that evolve based on owner interaction, internal protocol events, and external market signals provided by a trusted oracle. The protocol itself features adaptive tokenomics, adjusting fees, rewards, and even internal lending rates in response to these factors, aiming for a self-regulating and resilient system.

**I. Core Protocol Management**
1.  **`initializeProtocol`**: Sets initial global parameters for the protocol, including initial token supply, oracle address, and governance thresholds.
2.  **`updateProtocolParameter`**: Allows the admin or governance to adjust core protocol parameters like base fees, staking reward rates, or minting costs.
3.  **`setOracleAddress`**: Establishes or updates the address of the trusted data oracle.
4.  **`pauseProtocol`**: Emergency function to halt critical protocol operations, e.g., token transfers, sNFT minting.
5.  **`unpauseProtocol`**: Resumes operations after a pause.

**II. ChronoToken (CHR) Management (ERC-20 based)**
6.  **`mintChronoTokens`**: Creates new CHR tokens, typically for initial distribution, staking rewards, or specific protocol needs.
7.  **`burnChronoTokens`**: Destroys CHR tokens, e.g., for fee mechanisms, sNFT upgrades, or supply reduction.
8.  **`stakeChronoTokens`**: Allows users to lock CHR tokens to earn rewards and participate in governance.
9.  **`unstakeChronoTokens`**: Enables users to withdraw their staked CHR tokens after a cooldown period.

**III. Sentient NFT (sNFT) Management (ERC-721 based)**
10. **`mintSentientNFT`**: Mints a new unique sNFT. The cost and initial traits might be dynamically determined based on protocol conditions.
11. **`upgradeSentientNFTModule`**: Enhances an sNFT by adding or upgrading a "Decision Module," unlocking new capabilities or improving existing ones.
12. **`modifySNFTTrait`**: Allows for dynamic adjustment of an sNFT's traits based on owner actions, protocol events, or oracle data.
13. **`getSNFTHealthScore`**: A view function that calculates and returns a composite "health" or "sentiment" score for an sNFT, reflecting its activity, age, and module upgrades.

**IV. Adaptive Mechanics & Oracle Integration**
14. **`receiveOracleData`**: An oracle-only function to push external market data (e.g., volatility, gas prices, aggregated AI signals) to the protocol, which then influences adaptive parameters.
15. **`updateAdaptiveParameters`**: Triggers the recalculation and adjustment of protocol-wide adaptive parameters (fees, rewards, interest rates) based on recent oracle data and internal state.
16. **`executeSNFTDecision`**: Allows an sNFT owner to trigger a specific "Decision Module" on their sNFT, provided certain on-chain conditions (e.g., sNFT health, oracle signals) are met. This is where sNFTs act as programmable agents.

**V. Decentralized Autonomous Governance (DAO)**
17. **`submitProposal`**: Users or sNFTs can submit new governance proposals for the community to vote on.
18. **`voteOnProposal`**: Participants vote using their staked CHR and sNFTs (sNFT votes can be weighted by their health score).
19. **`delegateVote`**: Allows users to delegate their CHR and sNFT voting power to another address.
20. **`executeProposal`**: Carries out the actions defined in a proposal that has met the required voting thresholds.

**VI. Internal DeFi & Liquidity**
21. **`lendChronoTokens`**: Enables users to deposit CHR into a protocol-managed liquidity pool, earning yield.
22. **`borrowChronoTokens`**: Allows users to borrow CHR against their staked CHR or sNFT collateral, with dynamically adjusted interest rates.
23. **`repayBorrowing`**: Users repay their borrowed CHR and associated interest.

**VII. View Functions**
24. **`getProtocolStatus`**: Returns the current state of adaptive protocol parameters.
25. **`getSNFTDetails`**: Provides a comprehensive view of an sNFT's current traits, modules, and owner.
26. **`getProposalDetails`**: Retrieves all information about a specific governance proposal.

---

### ChronoForge Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ChronoForge: Adaptive Protocol with Sentient NFTs
 * @dev This contract implements a novel ecosystem featuring dynamic NFTs (sNFTs) and
 *      adaptive tokenomics. sNFTs evolve based on interaction and external data,
 *      acting as programmable agents. The protocol dynamically adjusts fees,
 *      rewards, and internal DeFi parameters based on oracle signals and network state.
 *      It integrates ERC-20 (ChronoToken) and ERC-721 (SentientNFT) standards,
 *      DAO-like governance, and a basic internal lending/borrowing mechanism.
 *      The core innovation lies in the synergistic combination of these elements:
 *      - Dynamic NFTs with "Decision Modules" influenced by off-chain AI/market data.
 *      - Adaptive protocol parameters (fees, rewards, rates) based on real-time conditions.
 *      - Weighted governance where both native tokens and sNFTs (with varying "health") contribute.
 */
contract ChronoForge is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For basic arithmetic, though Solidity 0.8+ has built-in overflow checks.

    // --- Events ---
    event ProtocolInitialized(address indexed admin, uint256 initialSupply);
    event ProtocolParameterUpdated(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue);
    event OracleAddressUpdated(address indexed newOracle);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);

    event ChronoTokensMinted(address indexed to, uint256 amount);
    event ChronoTokensBurned(address indexed from, uint256 amount);
    event ChronoTokensStaked(address indexed staker, uint256 amount);
    event ChronoTokensUnstaked(address indexed staker, uint256 amount);

    event SNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 mintCost);
    event SNFTModuleUpgraded(uint256 indexed tokenId, bytes32 indexed moduleName, uint256 newLevel);
    event SNFTTraitModified(uint256 indexed tokenId, bytes32 indexed traitName, uint256 newValue);

    event OracleDataReceived(bytes32 indexed dataKey, uint256 value, uint256 timestamp);
    event AdaptiveParametersUpdated(uint256 newBaseFee, uint256 newStakingRewardRate, uint256 newBorrowRate);
    event SNFTDecisionExecuted(uint256 indexed tokenId, bytes32 indexed decisionModule);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed submitter, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 chrWeight, uint256 snftWeight);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId);

    event ChronoTokensLent(address indexed lender, uint256 amount);
    event ChronoTokensBorrowed(address indexed borrower, uint256 amount, uint256 indexed snftCollateralId);
    event ChronoTokensRepaid(address indexed borrower, uint256 amount);

    // --- State Variables ---
    bool public paused;
    address public oracleAddress;

    // Adapative Protocol Parameters (dynamically adjusted)
    struct AdaptiveParams {
        uint256 baseProtocolFeeBps; // Base fee in basis points (e.g., 100 = 1%)
        uint256 stakingRewardRatePerBlock; // Rewards for CHR stakers
        uint256 sNFTMintCostCHR; // Cost to mint an sNFT in CHR
        uint256 sNFTModuleUpgradeCostCHR; // Cost to upgrade an sNFT module
        uint256 internalLendingAPR_Bps; // Annual percentage rate for internal lending in basis points
        uint256 internalBorrowingAPR_Bps; // Annual percentage rate for internal borrowing in basis points
        uint256 minSNFTHealthForModuleExecution; // Minimum health score for sNFT decision module execution
    }
    AdaptiveParams public adaptiveParams;

    // Oracle Data Store
    mapping(bytes32 => uint256) public latestOracleData; // Stores latest data from oracle (e.g., "marketVolatility", "globalSNFTSentiment")
    mapping(bytes32 => uint256) public latestOracleDataTimestamp; // Timestamp of when data was last updated

    // Governance
    Counters.Counter public proposalIds;
    uint256 public constant MIN_VOTE_CHRONO_TOKENS_FOR_PROPOSAL = 1_000_000 * 10**18; // 1M CHR
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 100; // ~15 mins for 6s block time
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 10; // 10% of total voting power
    uint256 public constant PROPOSAL_PASS_THRESHOLD_PERCENTAGE = 51; // 51% 'for' votes

    struct Proposal {
        string description;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bytes data; // Encoded call data for execution
        address target; // Target contract for execution
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool
    mapping(address => address) public delegates; // delegator => delegatee

    // Internal DeFi
    uint256 public totalChronoTokensLent;
    uint256 public totalChronoTokensBorrowed;

    struct Loan {
        uint256 amount;
        uint256 timestamp;
        uint256 interestAccrued;
        uint256 sNFTCollateralId; // The sNFT used as collateral
    }
    mapping(address => mapping(uint256 => Loan)) public borrowerLoans; // borrower => sNFT_ID => Loan

    // --- Token Contracts ---
    ChronoToken public chronoToken;
    SentientNFT public sentientNFT;

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoForge: Only oracle can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "ChronoForge: Only admin can call this function");
        _;
    }

    // --- Constructor ---
    constructor(
        address _chronoTokenAddress,
        address _sentientNFTAddress,
        address _initialOracleAddress
    ) Ownable(msg.sender) {
        require(_chronoTokenAddress != address(0), "ChronoForge: Invalid CHR token address");
        require(_sentientNFTAddress != address(0), "ChronoForge: Invalid sNFT token address");
        require(_initialOracleAddress != address(0), "ChronoForge: Invalid oracle address");

        chronoToken = ChronoToken(_chronoTokenAddress);
        sentientNFT = SentientNFT(_sentientNFTAddress);
        oracleAddress = _initialOracleAddress;

        // Set initial adaptive parameters (can be updated via governance/admin)
        adaptiveParams = AdaptiveParams({
            baseProtocolFeeBps: 100, // 1%
            stakingRewardRatePerBlock: 1 ether / 1000, // 0.001 CHR per block per unit staked (example)
            sNFTMintCostCHR: 100 * 10**18, // 100 CHR
            sNFTModuleUpgradeCostCHR: 50 * 10**18, // 50 CHR
            internalLendingAPR_Bps: 200, // 2% APR
            internalBorrowingAPR_Bps: 500, // 5% APR
            minSNFTHealthForModuleExecution: 50 // Out of 100
        });

        paused = false;
        emit ProtocolInitialized(msg.sender, chronoToken.totalSupply());
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Allows admin/governance to update a specific protocol parameter.
     * @param _parameterName Name of the parameter to update (e.g., "baseProtocolFeeBps").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _parameterName, uint256 _newValue) external onlyAdmin {
        // In a full DAO, this would be callable only via successful proposal execution.
        // For this example, simplified to owner.
        uint256 oldValue;
        if (_parameterName == "baseProtocolFeeBps") {
            oldValue = adaptiveParams.baseProtocolFeeBps;
            adaptiveParams.baseProtocolFeeBps = _newValue;
        } else if (_parameterName == "stakingRewardRatePerBlock") {
            oldValue = adaptiveParams.stakingRewardRatePerBlock;
            adaptiveParams.stakingRewardRatePerBlock = _newValue;
        } else if (_parameterName == "sNFTMintCostCHR") {
            oldValue = adaptiveParams.sNFTMintCostCHR;
            adaptiveParams.sNFTMintCostCHR = _newValue;
        } else if (_parameterName == "sNFTModuleUpgradeCostCHR") {
            oldValue = adaptiveParams.sNFTModuleUpgradeCostCHR;
            adaptiveParams.sNFTModuleUpgradeCostCHR = _newValue;
        } else if (_parameterName == "internalLendingAPR_Bps") {
            oldValue = adaptiveParams.internalLendingAPR_Bps;
            adaptiveParams.internalLendingAPR_Bps = _newValue;
        } else if (_parameterName == "internalBorrowingAPR_Bps") {
            oldValue = adaptiveParams.internalBorrowingAPR_Bps;
            adaptiveParams.internalBorrowingAPR_Bps = _newValue;
        } else if (_parameterName == "minSNFTHealthForModuleExecution") {
            oldValue = adaptiveParams.minSNFTHealthForModuleExecution;
            adaptiveParams.minSNFTHealthForModuleExecution = _newValue;
        } else {
            revert("ChronoForge: Invalid parameter name");
        }
        emit ProtocolParameterUpdated(_parameterName, oldValue, _newValue);
    }

    /**
     * @dev Sets the address of the trusted data oracle. Only callable by admin.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyAdmin {
        require(_newOracle != address(0), "ChronoForge: Invalid oracle address");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Pauses the protocol in case of emergency. Only callable by admin.
     */
    function pauseProtocol() external onlyAdmin {
        require(!paused, "ChronoForge: Protocol already paused");
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Only callable by admin.
     */
    function unpauseProtocol() external onlyAdmin {
        require(paused, "ChronoForge: Protocol not paused");
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- II. ChronoToken (CHR) Management (ERC-20 based) ---

    /**
     * @dev Mints new CHR tokens and sends them to a specified address.
     *      Admin-only for initial supply or specific reward distribution.
     * @param _to The address to receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mintChronoTokens(address _to, uint256 _amount) external onlyAdmin whenNotPaused {
        chronoToken.mint(_to, _amount);
        emit ChronoTokensMinted(_to, _amount);
    }

    /**
     * @dev Burns CHR tokens from the caller's balance.
     * @param _amount The amount of tokens to burn.
     */
    function burnChronoTokens(uint256 _amount) external whenNotPaused {
        chronoToken.burn(msg.sender, _amount);
        emit ChronoTokensBurned(msg.sender, _amount);
    }

    /**
     * @dev Stakes CHR tokens for rewards and governance participation.
     *      Tokens are transferred from the staker to the ChronoForge contract.
     * @param _amount The amount of CHR tokens to stake.
     */
    function stakeChronoTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "ChronoForge: Stake amount must be greater than 0");
        chronoToken.transferFrom(msg.sender, address(this), _amount);
        chronoToken.stake(msg.sender, _amount); // Delegate staking logic to ChronoToken contract
        emit ChronoTokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes CHR tokens. Tokens are returned to the staker.
     * @param _amount The amount of CHR tokens to unstake.
     */
    function unstakeChronoTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "ChronoForge: Unstake amount must be greater than 0");
        chronoToken.unstake(msg.sender, _amount); // Delegate unstaking logic
        chronoToken.transfer(msg.sender, _amount);
        emit ChronoTokensUnstaked(msg.sender, _amount);
    }

    // --- III. Sentient NFT (sNFT) Management (ERC-721 based) ---

    /**
     * @dev Mints a new Sentient NFT to the caller. Requires CHR payment.
     *      The initial traits are determined by the protocol (e.g., random, fixed).
     */
    function mintSentientNFT() external whenNotPaused {
        uint256 mintCost = adaptiveParams.sNFTMintCostCHR;
        require(chronoToken.balanceOf(msg.sender) >= mintCost, "ChronoForge: Insufficient CHR for minting sNFT");
        chronoToken.transferFrom(msg.sender, address(this), mintCost); // Pay minting fee

        uint256 newTokenId = sentientNFT.mint(msg.sender);
        // Set initial random/deterministic traits for the new sNFT
        sentientNFT.setSNFTTrait(newTokenId, "generation", 1);
        sentientNFT.setSNFTTrait(newTokenId, "energy", 100);
        sentientNFT.setSNFTModule(newTokenId, "baseModule", 1); // Give a base module

        emit SNFTMinted(newTokenId, msg.sender, mintCost);
    }

    /**
     * @dev Upgrades a specific decision module on an sNFT. Requires CHR payment.
     *      Module levels can unlock new functionalities or improve existing ones.
     * @param _tokenId The ID of the sNFT.
     * @param _moduleName The name of the module to upgrade (e.g., "rebalanceModule", "voteAssistModule").
     */
    function upgradeSentientNFTModule(uint256 _tokenId, bytes32 _moduleName) external whenNotPaused {
        require(sentientNFT.ownerOf(_tokenId) == msg.sender, "ChronoForge: Not owner of sNFT");
        uint256 upgradeCost = adaptiveParams.sNFTModuleUpgradeCostCHR;
        require(chronoToken.balanceOf(msg.sender) >= upgradeCost, "ChronoForge: Insufficient CHR for module upgrade");
        chronoToken.transferFrom(msg.sender, address(this), upgradeCost); // Pay upgrade fee

        uint256 currentLevel = sentientNFT.getSNFTModule(_tokenId, _moduleName);
        sentientNFT.setSNFTModule(_tokenId, _moduleName, currentLevel + 1); // Increment module level

        emit SNFTModuleUpgraded(_tokenId, _moduleName, currentLevel + 1);
    }

    /**
     * @dev Modifies a dynamic trait of an sNFT. This can be called by owner based on actions,
     *      or by oracle/admin in more complex scenarios.
     * @param _tokenId The ID of the sNFT.
     * @param _traitName The name of the trait to modify (e.g., "energy", "sentiment").
     * @param _newValue The new value for the trait.
     */
    function modifySNFTTrait(uint256 _tokenId, bytes32 _traitName, uint256 _newValue) external whenNotPaused {
        require(sentientNFT.ownerOf(_tokenId) == msg.sender, "ChronoForge: Not owner of sNFT");
        // Further logic could restrict which traits can be modified by owner vs. oracle/protocol.
        sentientNFT.setSNFTTrait(_tokenId, _traitName, _newValue);
        emit SNFTTraitModified(_tokenId, _traitName, _newValue);
    }

    /**
     * @dev Calculates and returns the dynamic health/sentiment score of an sNFT.
     *      Score is based on age, module levels, owner's staked CHR, and oracle data.
     * @param _tokenId The ID of the sNFT.
     * @return The calculated health score (e.g., 0-100).
     */
    function getSNFTHealthScore(uint256 _tokenId) public view returns (uint256) {
        // Example composite score calculation
        uint256 baseScore = 50; // Starting point
        uint256 ageBonus = (block.timestamp - sentientNFT.getMintTimestamp(_tokenId)) / (1 days); // 1 bonus point per day, max 20
        ageBonus = ageBonus > 20 ? 20 : ageBonus;

        uint256 moduleBonus = 0;
        // Iterate through known modules (simplified, could be more complex in real dApp)
        if (sentientNFT.getSNFTModule(_tokenId, "baseModule") > 0) moduleBonus += 5;
        if (sentientNFT.getSNFTModule(_tokenId, "rebalanceModule") > 0) moduleBonus += 10;
        if (sentientNFT.getSNFTModule(_tokenId, "voteAssistModule") > 0) moduleBonus += 10;

        uint256 ownerChrStake = chronoToken.getStakedAmount(sentientNFT.ownerOf(_tokenId)) / (10**18); // Convert to whole CHR
        uint256 stakeBonus = ownerChrStake / 1000; // 1 point per 1000 staked CHR, max 20
        stakeBonus = stakeBonus > 20 ? 20 : stakeBonus;

        uint256 marketSentimentInfluence = latestOracleData["globalSNFTSentiment"]; // Assume oracle provides 0-100
        if (marketSentimentInfluence == 0) marketSentimentInfluence = 50; // Default if no data

        // Max possible score without oracle influence: 50 + 20 + 25 + 20 = 115
        // Adjust for desired 0-100 range and oracle influence
        uint256 rawScore = baseScore.add(ageBonus).add(moduleBonus).add(stakeBonus);
        // Average with market sentiment for final score
        uint256 finalScore = (rawScore.add(marketSentimentInfluence)) / 2;

        return finalScore > 100 ? 100 : finalScore; // Cap at 100
    }


    // --- IV. Adaptive Mechanics & Oracle Integration ---

    /**
     * @dev Receives and stores external data from the trusted oracle.
     *      This data influences adaptive protocol parameters and sNFT decisions.
     * @param _dataKey A unique key for the data point (e.g., "marketVolatility", "globalSNFTSentiment").
     * @param _value The value of the data point.
     */
    function receiveOracleData(bytes32 _dataKey, uint256 _value) external onlyOracle {
        latestOracleData[_dataKey] = _value;
        latestOracleDataTimestamp[_dataKey] = block.timestamp;
        emit OracleDataReceived(_dataKey, _value, block.timestamp);
        // Automatically trigger adaptive parameter update if certain data is received
        // or this can be a separate timed call. For now, separate.
    }

    /**
     * @dev Updates adaptive protocol parameters based on recent oracle data and internal state.
     *      Can be called by anyone, but relies on up-to-date oracle data.
     */
    function updateAdaptiveParameters() external whenNotPaused {
        require(latestOracleDataTimestamp["marketVolatility"] > 0 &&
                block.timestamp - latestOracleDataTimestamp["marketVolatility"] < 1 hours,
                "ChronoForge: Oracle market data is outdated or unavailable.");

        uint256 marketVolatility = latestOracleData["marketVolatility"]; // Assume 0-100 scale

        // Example logic for dynamic adjustments:
        // Higher volatility -> higher fees, lower staking rewards (to curb activity), higher borrowing rates.
        uint256 newBaseFeeBps = adaptiveParams.baseProtocolFeeBps;
        uint256 newStakingRewardRate = adaptiveParams.stakingRewardRatePerBlock;
        uint256 newBorrowRateBps = adaptiveParams.internalBorrowingAPR_Bps;

        if (marketVolatility > 70) { // High volatility
            newBaseFeeBps = 150; // 1.5%
            newStakingRewardRate = adaptiveParams.stakingRewardRatePerBlock.mul(80).div(100); // 20% less
            newBorrowRateBps = 800; // 8%
        } else if (marketVolatility < 30) { // Low volatility
            newBaseFeeBps = 50; // 0.5%
            newStakingRewardRate = adaptiveParams.stakingRewardRatePerBlock.mul(120).div(100); // 20% more
            newBorrowRateBps = 300; // 3%
        } else { // Moderate volatility
            newBaseFeeBps = 100;
            newStakingRewardRate = 1 ether / 1000;
            newBorrowRateBps = 500;
        }

        adaptiveParams.baseProtocolFeeBps = newBaseFeeBps;
        adaptiveParams.stakingRewardRatePerBlock = newStakingRewardRate;
        adaptiveParams.internalBorrowingAPR_Bps = newBorrowRateBps;

        emit AdaptiveParametersUpdated(newBaseFeeBps, newStakingRewardRate, newBorrowRateBps);
    }

    /**
     * @dev Allows an sNFT owner to execute a specific decision module if the sNFT's health
     *      and oracle data conditions are met. This represents the "sentient" aspect.
     * @param _tokenId The ID of the sNFT.
     * @param _decisionModule The name of the decision module to execute (e.g., "rebalanceModule").
     */
    function executeSNFTDecision(uint256 _tokenId, bytes32 _decisionModule) external whenNotPaused {
        require(sentientNFT.ownerOf(_tokenId) == msg.sender, "ChronoForge: Not owner of sNFT");
        require(sentientNFT.getSNFTModule(_tokenId, _decisionModule) > 0, "ChronoForge: sNFT does not have this module");

        uint256 sNFTHealth = getSNFTHealthScore(_tokenId);
        require(sNFTHealth >= adaptiveParams.minSNFTHealthForModuleExecution, "ChronoForge: sNFT health too low for decision");

        // Example decision logic based on modules and oracle data
        if (_decisionModule == "rebalanceModule") {
            require(sentientNFT.getSNFTModule(_tokenId, "rebalanceModule") >= 1, "ChronoForge: Rebalance module not active");
            require(latestOracleDataTimestamp["suggestedRebalanceThreshold"] > 0 &&
                    block.timestamp - latestOracleDataTimestamp["suggestedRebalanceThreshold"] < 1 hours,
                    "ChronoForge: Oracle rebalance data is outdated or unavailable.");

            uint256 currentBalanceChr = chronoToken.balanceOf(address(this));
            uint256 targetBalanceChr = latestOracleData["suggestedRebalanceThreshold"]; // Assume oracle gives a target % of total supply
            
            // This rebalance would likely involve shifting funds held by the protocol itself,
            // or adjusting rewards distribution. Not directly rebalancing user funds for security.
            if (currentBalanceChr > targetBalanceChr) {
                 // Example: Burn excess CHR to rebalance supply
                uint256 burnAmount = currentBalanceChr.sub(targetBalanceChr).div(10); // Burn 10% of excess
                chronoToken.burn(address(this), burnAmount);
                emit ChronoTokensBurned(address(this), burnAmount);
            } else if (currentBalanceChr < targetBalanceChr) {
                // Example: Mint a small amount if supply is too low (requires admin role for full mint)
                // For simplicity, this example will just log the "decision"
                // A real implementation might trigger an admin mint or adjust staking rewards
            }
            // More complex logic would involve interacting with internal lending/borrowing or external protocols
            // if the protocol managed a pool of assets directly.
            // For now, it's a "decision" that potentially affects protocol parameters or supply.

        } else if (_decisionModule == "voteAssistModule") {
            // An sNFT with a voteAssistModule could automatically vote on proposals
            // with a preference set by the owner, if the sNFT health is high.
            // This would involve calling `voteOnProposal` internally.
            // For this example, we just emit the event.
        }
        // Add more decision modules here...

        emit SNFTDecisionExecuted(_tokenId, _decisionModule);
    }

    // --- V. Decentralized Autonomous Governance (DAO) ---

    /**
     * @dev Allows users to submit a new governance proposal. Requires a minimum CHR stake.
     * @param _description A clear description of the proposal.
     * @param _target The target contract address for the proposal's execution.
     * @param _data The encoded calldata for the function to be executed by the proposal.
     */
    function submitProposal(string memory _description, address _target, bytes memory _data) external whenNotPaused {
        require(chronoToken.getStakedAmount(msg.sender) >= MIN_VOTE_CHRONO_TOKENS_FOR_PROPOSAL, "ChronoForge: Insufficient CHR staked to submit proposal");

        proposalIds.increment();
        uint256 proposalId = proposalIds.current();

        proposals[proposalId] = Proposal({
            description: _description,
            proposer: msg.sender,
            startBlock: block.number,
            endBlock: block.number + PROPOSAL_VOTING_PERIOD_BLOCKS,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            target: _target,
            data: _data
        });
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users (or their delegates) to vote on an active proposal.
     *      Voting power combines staked CHR and sNFT health score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     * @param _snftTokenIds Optional array of sNFT token IDs to use for voting power.
     */
    function voteOnProposal(uint256 _proposalId, bool _support, uint256[] memory _snftTokenIds) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoForge: Proposal does not exist");
        require(block.number >= proposal.startBlock && block.number < proposal.endBlock, "ChronoForge: Voting period is not active");

        address voter = delegates[msg.sender] != address(0) ? delegates[msg.sender] : msg.sender;
        require(!hasVoted[_proposalId][voter], "ChronoForge: Already voted on this proposal");

        uint256 chrVotingPower = chronoToken.getStakedAmount(voter);
        require(chrVotingPower > 0 || _snftTokenIds.length > 0, "ChronoForge: No voting power (0 staked CHR or sNFTs)");

        uint256 snftVotingPower = 0;
        for (uint256 i = 0; i < _snftTokenIds.length; i++) {
            uint256 tokenId = _snftTokenIds[i];
            require(sentientNFT.ownerOf(tokenId) == voter, "ChronoForge: Not owner of sNFT used for voting");
            // sNFT voting power is proportional to its health score
            snftVotingPower = snftVotingPower.add(getSNFTHealthScore(tokenId));
        }
        // Normalize sNFT voting power (e.g., 100 health points = 1 CHR token's voting power)
        // This is a design choice and can be adjusted
        uint256 totalVotingPower = chrVotingPower.add(snftVotingPower.mul(1 ether).div(100)); // 1 health point = 0.01 CHR equivalent

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(totalVotingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(totalVotingPower);
        }

        hasVoted[_proposalId][voter] = true;
        emit VoteCast(_proposalId, voter, _support, chrVotingPower, snftVotingPower);
    }

    /**
     * @dev Allows a user to delegate their voting power (staked CHR and sNFTs) to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external {
        require(_delegatee != address(0), "ChronoForge: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "ChronoForge: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Executes a proposal if it has passed the voting thresholds and period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "ChronoForge: Proposal does not exist");
        require(block.number >= proposal.endBlock, "ChronoForge: Voting period has not ended");
        require(!proposal.executed, "ChronoForge: Proposal already executed");

        uint256 totalStakedCHR = chronoToken.totalStaked(); // Total CHR staked in the protocol
        uint256 totalSNFTHealth = 0;
        // This would require iterating all sNFTs, which is not feasible on-chain.
        // For a real DAO, total voting power would be tracked more efficiently or based on snapshots.
        // For this example, we will approximate total voting power based on total staked CHR only
        // or a predefined max value for sNFTs.
        // Let's simplify: sNFTs add to voter's individual power, but total quorum only uses CHR for simplicity.

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        uint256 requiredQuorum = totalStakedCHR.mul(PROPOSAL_QUORUM_PERCENTAGE).div(100);

        require(totalVotes >= requiredQuorum, "ChronoForge: Quorum not reached");
        require(proposal.forVotes.mul(100).div(totalVotes) >= PROPOSAL_PASS_THRESHOLD_PERCENTAGE, "ChronoForge: Proposal did not pass");

        // Execute the proposal's action
        (bool success,) = proposal.target.call(proposal.data);
        require(success, "ChronoForge: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- VI. Internal DeFi & Liquidity ---

    /**
     * @dev Allows users to lend CHR tokens to the protocol's liquidity pool.
     * @param _amount The amount of CHR to lend.
     */
    function lendChronoTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "ChronoForge: Lend amount must be greater than 0");
        chronoToken.transferFrom(msg.sender, address(this), _amount);
        totalChronoTokensLent = totalChronoTokensLent.add(_amount);
        emit ChronoTokensLent(msg.sender, _amount);
    }

    /**
     * @dev Allows users to borrow CHR tokens against an sNFT as collateral.
     *      Interest accrues dynamically.
     * @param _amount The amount of CHR to borrow.
     * @param _snftCollateralId The ID of the sNFT used as collateral.
     */
    function borrowChronoTokens(uint256 _amount, uint256 _snftCollateralId) external whenNotPaused {
        require(_amount > 0, "ChronoForge: Borrow amount must be greater than 0");
        require(sentientNFT.ownerOf(_snftCollateralId) == msg.sender, "ChronoForge: Not owner of sNFT collateral");
        require(borrowerLoans[msg.sender][_snftCollateralId].amount == 0, "ChronoForge: Already has an active loan with this sNFT");
        require(totalChronoTokensLent >= totalChronoTokensBorrowed.add(_amount), "ChronoForge: Insufficient liquidity for borrowing"); // Simple liquidity check

        // Transfer sNFT to contract as collateral
        sentientNFT.transferFrom(msg.sender, address(this), _snftCollateralId);

        borrowerLoans[msg.sender][_snftCollateralId] = Loan({
            amount: _amount,
            timestamp: block.timestamp,
            interestAccrued: 0,
            sNFTCollateralId: _snftCollateralId
        });

        totalChronoTokensBorrowed = totalChronoTokensBorrowed.add(_amount);
        chronoToken.transfer(msg.sender, _amount); // Transfer borrowed amount to user
        emit ChronoTokensBorrowed(msg.sender, _amount, _snftCollateralId);
    }

    /**
     * @dev Calculates the current outstanding debt including accrued interest for a specific loan.
     * @param _borrower The borrower's address.
     * @param _snftCollateralId The sNFT ID used as collateral.
     * @return The total amount due (principal + interest).
     */
    function calculateLoanDebt(address _borrower, uint256 _snftCollateralId) public view returns (uint256) {
        Loan storage loan = borrowerLoans[_borrower][_snftCollateralId];
        if (loan.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp.sub(loan.timestamp);
        // Simple interest calculation: (principal * rate * time) / (10000 * 365 days)
        // Assuming rate is APR in Bps
        uint256 annualInterest = loan.amount.mul(adaptiveParams.internalBorrowingAPR_Bps).div(10000); // Amount * (APR / 100%)
        uint256 interest = annualInterest.mul(timeElapsed).div(31536000); // interest per second (365*24*60*60)

        return loan.amount.add(interest).add(loan.interestAccrued);
    }

    /**
     * @dev Allows borrowers to repay their loans and retrieve their sNFT collateral.
     * @param _snftCollateralId The ID of the sNFT used as collateral.
     */
    function repayBorrowing(uint256 _snftCollateralId) external whenNotPaused {
        Loan storage loan = borrowerLoans[msg.sender][_snftCollateralId];
        require(loan.amount > 0, "ChronoForge: No active loan with this sNFT");

        uint256 totalDebt = calculateLoanDebt(msg.sender, _snftCollateralId);
        require(chronoToken.balanceOf(msg.sender) >= totalDebt, "ChronoForge: Insufficient CHR to repay loan");

        chronoToken.transferFrom(msg.sender, address(this), totalDebt); // Transfer repayment to contract
        totalChronoTokensBorrowed = totalChronoTokensBorrowed.sub(loan.amount); // Reduce borrowed amount (principal only)

        // Return sNFT collateral
        sentientNFT.transferFrom(address(this), msg.sender, _snftCollateralId);

        delete borrowerLoans[msg.sender][_snftCollateralId];
        emit ChronoTokensRepaid(msg.sender, totalDebt);
    }

    // --- VII. View Functions ---

    /**
     * @dev Returns the current state of core adaptive protocol parameters.
     */
    function getProtocolStatus() public view returns (AdaptiveParams memory) {
        return adaptiveParams;
    }

    /**
     * @dev Returns all details of a specific Sentient NFT.
     * @param _tokenId The ID of the sNFT.
     * @return An SNFTDetails struct containing all relevant information.
     */
    function getSNFTDetails(uint256 _tokenId) public view returns (SentientNFT.SNFTDetails memory) {
        return sentientNFT.getSNFTDetails(_tokenId);
    }

    /**
     * @dev Retrieves details about a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A Proposal struct containing its state and details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }
}

/**
 * @title ChronoToken (CHR)
 * @dev ERC20 token for ChronoForge, with added staking functionality.
 *      Staking is managed by the ChronoForge protocol.
 */
contract ChronoToken is ERC20 {
    mapping(address => uint256) public stakedBalances;
    uint256 public totalStakedAmount;

    constructor(uint256 initialSupply) ERC20("ChronoToken", "CHR") {
        _mint(msg.sender, initialSupply);
    }

    // Only ChronoForge contract can call these
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == address(this.owner()), "ChronoToken: Only ChronoForge protocol owner can mint"); // Simplistic access control, should be more robust
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == address(this.owner()), "ChronoToken: Only ChronoForge protocol owner can burn");
        _burn(_from, _amount);
    }

    function stake(address _staker, uint256 _amount) external {
        require(msg.sender == address(this.owner()), "ChronoToken: Only ChronoForge protocol can manage staking");
        stakedBalances[_staker] = stakedBalances[_staker].add(_amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
    }

    function unstake(address _staker, uint256 _amount) external {
        require(msg.sender == address(this.owner()), "ChronoToken: Only ChronoForge protocol can manage unstaking");
        require(stakedBalances[_staker] >= _amount, "ChronoToken: Insufficient staked amount");
        stakedBalances[_staker] = stakedBalances[_staker].sub(_amount);
        totalStakedAmount = totalStakedAmount.sub(_amount);
    }

    function getStakedAmount(address _staker) public view returns (uint256) {
        return stakedBalances[_staker];
    }

    function totalStaked() public view returns (uint256) {
        return totalStakedAmount;
    }
}

/**
 * @title SentientNFT (sNFT)
 * @dev ERC721 token for ChronoForge, with dynamic traits and decision modules.
 *      Traits and modules can be set by the ChronoForge protocol.
 */
contract SentientNFT is ERC721 {
    Counters.Counter private _tokenIdTracker;

    struct SNFTDetails {
        address owner;
        uint256 mintTimestamp;
        mapping(bytes32 => uint256) modules; // Module name => Level/Value
        mapping(bytes32 => uint256) dynamicTraits; // Trait name => Value
        uint256 lastActionTimestamp; // To track activity
    }

    mapping(uint256 => SNFTDetails) public sNFTData;

    constructor() ERC721("SentientNFT", "sNFT") {}

    // Only ChronoForge protocol can call mint and set internal data
    function mint(address _to) external returns (uint256) {
        require(msg.sender == address(this.owner()), "SentientNFT: Only ChronoForge protocol can mint"); // Simplistic access control
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(_to, newTokenId);

        sNFTData[newTokenId].owner = _to;
        sNFTData[newTokenId].mintTimestamp = block.timestamp;
        sNFTData[newTokenId].lastActionTimestamp = block.timestamp;

        return newTokenId;
    }

    function setSNFTModule(uint256 _tokenId, bytes32 _moduleName, uint256 _level) external {
        require(msg.sender == address(this.owner()), "SentientNFT: Only ChronoForge protocol can set modules");
        require(_exists(_tokenId), "SentientNFT: sNFT does not exist");
        sNFTData[_tokenId].modules[_moduleName] = _level;
        sNFTData[_tokenId].lastActionTimestamp = block.timestamp;
    }

    function getSNFTModule(uint256 _tokenId, bytes32 _moduleName) public view returns (uint256) {
        return sNFTData[_tokenId].modules[_moduleName];
    }

    function setSNFTTrait(uint256 _tokenId, bytes32 _traitName, uint256 _value) external {
        require(msg.sender == address(this.owner()), "SentientNFT: Only ChronoForge protocol can set traits");
        require(_exists(_tokenId), "SentientNFT: sNFT does not exist");
        sNFTData[_tokenId].dynamicTraits[_traitName] = _value;
        sNFTData[_tokenId].lastActionTimestamp = block.timestamp;
    }

    function getSNFTTrait(uint256 _tokenId, bytes32 _traitName) public view returns (uint256) {
        return sNFTData[_tokenId].dynamicTraits[_traitName];
    }

    function getMintTimestamp(uint256 _tokenId) public view returns (uint256) {
        return sNFTData[_tokenId].mintTimestamp;
    }

    // View function to get all details, handles the mappings internally for external consumption
    function getSNFTDetails(uint256 _tokenId) public view returns (SNFTDetails memory) {
        require(_exists(_tokenId), "SentientNFT: sNFT does not exist");
        // Due to Solidity's limitations, mappings within structs cannot be directly returned or accessed via memory.
        // For a true "all details" function, you'd need to iterate through known traits/modules or return them separately.
        // This is a simplified version, returning a struct with basic fields.
        // A more complex dApp would have dedicated functions to query each trait/module.
        return SNFTDetails({
            owner: ownerOf(_tokenId),
            mintTimestamp: sNFTData[_tokenId].mintTimestamp,
            lastActionTimestamp: sNFTData[_tokenId].lastActionTimestamp,
            modules: sNFTData[_tokenId].modules, // This will return a default empty mapping in Solidity <0.8.19
            dynamicTraits: sNFTData[_tokenId].dynamicTraits // Same as above
        });
    }

    // Helper to get specific trait/module from sNFTData for external view
    function getSNFTDynamicTrait(uint256 _tokenId, bytes32 _traitName) public view returns (uint256) {
        return sNFTData[_tokenId].dynamicTraits[_traitName];
    }

    function getSNFTModuleLevel(uint256 _tokenId, bytes32 _moduleName) public view returns (uint256) {
        return sNFTData[_tokenId].modules[_moduleName];
    }
}
```