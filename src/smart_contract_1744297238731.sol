```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Investment Fund (DAIF)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Investment Fund (DAIF) with advanced features.
 * This contract allows users to deposit funds, participate in governance, and benefit from diverse investment strategies
 * managed autonomously through community voting and potentially algorithmic approaches.
 *
 * **Outline:**
 *
 * 1. **Core Functionality:**
 *    - Deposit and Withdrawal of Funds
 *    - Fund Value Tracking and Reporting
 *    - Fee Management (Performance Fees, Management Fees)
 *
 * 2. **Governance and Strategy Management:**
 *    - Strategy Proposal and Voting Mechanism
 *    - Dynamic Strategy Allocation based on Governance
 *    - Risk Parameter Setting and Management via Governance
 *    - Emergency Shutdown Mechanism (Governance-Triggered)
 *
 * 3. **Advanced Investment Strategies (Conceptual - Can be extended):**
 *    - Algorithmic Strategy Integration (Placeholder for future implementation)
 *    - Diversification across different asset types (Tokens, NFTs, etc.)
 *    - Yield Farming and Staking Strategy Integration
 *    - Rebalancing Strategies based on market conditions
 *
 * 4. **User Features and Incentives:**
 *    - Referral Program for attracting new investors
 *    - Staking Mechanism for Governance Tokens (Incentivizing Participation)
 *    - Performance-Based Rewards for Active Governance Participants
 *    - Risk Assessment for Users to understand fund risk profile
 *
 * 5. **Security and Control Features:**
 *    - Pausable Functionality for Emergency Situations
 *    - Upgradable Contract Architecture (Proxy Pattern - Conceptual)
 *    - Oracle Integration for Price Feeds (Placeholder)
 *    - Role-Based Access Control (Owner, Strategist, Governance Council - Conceptual)
 *
 * **Function Summary:**
 *
 * 1. `deposit(uint256 _amount)`: Allows users to deposit funds into the DAIF.
 * 2. `withdraw(uint256 _amount)`: Allows users to withdraw their funds from the DAIF.
 * 3. `getFundValue()`: Returns the current total value of the DAIF.
 * 4. `getUserBalance(address _user)`: Returns the balance of a specific user in the DAIF.
 * 5. `proposeStrategy(string memory _strategyName, address _strategyContract, bytes memory _strategyData)`: Allows governance token holders to propose a new investment strategy.
 * 6. `voteOnStrategy(uint256 _proposalId, bool _vote)`: Allows governance token holders to vote on a strategy proposal.
 * 7. `executeStrategy(uint256 _strategyId)`: Executes a strategy that has been approved by governance.
 * 8. `setRiskThreshold(uint256 _newThreshold)`: Allows governance to set a risk threshold for the fund.
 * 9. `getRiskScore()`: Returns the current risk score of the DAIF based on implemented strategies.
 * 10. `emergencyShutdown()`: Allows governance to trigger an emergency shutdown of the DAIF in critical situations.
 * 11. `setPerformanceFeeRate(uint256 _newRate)`: Allows the owner to set the performance fee rate.
 * 12. `setManagementFeeRate(uint256 _newRate)`: Allows the owner to set the management fee rate.
 * 13. `distributeFees()`: Distributes collected fees to the owner/designated address.
 * 14. `addStrategy(string memory _strategyName, address _strategyContract)`: Allows the owner to add a pre-approved strategy to the available strategies.
 * 15. `removeStrategy(uint256 _strategyId)`: Allows the owner to remove a strategy from the available strategies.
 * 16. `activateStrategy(uint256 _strategyId)`: Allows the owner to activate a pre-approved strategy for investment.
 * 17. `deactivateStrategy(uint256 _strategyId)`: Allows the owner to deactivate a currently active strategy.
 * 18. `setReferralBonus(uint256 _bonusPercentage)`: Allows the owner to set the referral bonus percentage.
 * 19. `referInvestor(address _referredInvestor)`: Allows users to refer new investors and earn a bonus.
 * 20. `pauseContract()`: Allows the owner to pause the contract in case of emergencies.
 * 21. `unpauseContract()`: Allows the owner to unpause the contract.
 * 22. `setOracleAddress(address _oracleAddress)`: Allows the owner to set the address of the price oracle.
 * 23. `getStrategyPerformance(uint256 _strategyId)`: Returns the performance metrics of a specific strategy.
 * 24. `stakeGovernanceTokens(uint256 _amount)`: Allows users to stake governance tokens to participate in voting (Conceptual).
 * 25. `unstakeGovernanceTokens(uint256 _amount)`: Allows users to unstake governance tokens (Conceptual).
 * 26. `rewardGovernanceParticipants()`: Distributes rewards to active governance participants based on their voting activity (Conceptual).
 */

contract DecentralizedAutonomousInvestmentFund {
    // State Variables

    address public owner;
    string public contractName = "Decentralized Autonomous Investment Fund";

    mapping(address => uint256) public userBalances;
    uint256 public totalFundValue;

    uint256 public performanceFeeRate = 5; // 5% performance fee (example)
    uint256 public managementFeeRate = 1;   // 1% management fee per year (example - simplified)
    uint256 public lastFeeCollectionTimestamp;

    struct StrategyProposal {
        string strategyName;
        address strategyContract;
        bytes strategyData;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }
    mapping(uint256 => StrategyProposal) public strategyProposals;
    uint256 public proposalCount;

    struct InvestmentStrategy {
        string strategyName;
        address strategyContract;
        bool isActive;
        uint256 allocationPercentage; // Percentage of fund allocated to this strategy
        // Add more strategy-specific parameters if needed
    }
    mapping(uint256 => InvestmentStrategy) public investmentStrategies;
    uint256 public strategyCount;

    uint256 public riskThreshold = 70; // Example risk threshold (0-100)
    // Function to calculate risk score would be implemented based on strategies and market conditions
    // For simplicity, riskScore is just a placeholder here
    uint256 public riskScore = 50;

    bool public paused = false;
    address public oracleAddress; // Address of price oracle contract (for future integration)

    uint256 public referralBonusPercentage = 2; // Example referral bonus percentage

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event StrategyProposed(uint256 proposalId, string strategyName, address strategyContract, address proposer, uint256 timestamp);
    event StrategyVoted(uint256 proposalId, address voter, bool vote, uint256 timestamp);
    event StrategyExecuted(uint256 strategyId, string strategyName, address strategyContract, uint256 timestamp);
    event RiskThresholdSet(uint256 newThreshold, address setter, uint256 timestamp);
    event EmergencyShutdownTriggered(address trigger, uint256 timestamp);
    event PerformanceFeeRateSet(uint256 newRate, address setter, uint256 timestamp);
    event ManagementFeeRateSet(uint256 newRate, address setter, uint256 timestamp);
    event FeesDistributed(uint256 amount, address distributor, uint256 timestamp);
    event StrategyAdded(uint256 strategyId, string strategyName, address strategyContract, address adder, uint256 timestamp);
    event StrategyRemoved(uint256 strategyId, address remover, uint256 timestamp);
    event StrategyActivated(uint256 strategyId, address activator, uint256 timestamp);
    event StrategyDeactivated(uint256 strategyId, address deactivator, uint256 timestamp);
    event ReferralBonusSet(uint256 bonusPercentage, address setter, uint256 timestamp);
    event InvestorReferred(address referrer, address referredInvestor, uint256 bonusPercentage, uint256 timestamp);
    event ContractPaused(address pauser, uint256 timestamp);
    event ContractUnpaused(address unpauser, uint256 timestamp);
    event OracleAddressSet(address newOracleAddress, address setter, uint256 timestamp);
    event StrategyPerformanceReport(uint256 strategyId, string strategyName, uint256 performanceValue, uint256 timestamp); // Example Performance Event

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        lastFeeCollectionTimestamp = block.timestamp;
    }

    // 1. Core Functionality

    /// @notice Allows users to deposit funds into the DAIF.
    /// @param _amount The amount of funds to deposit.
    function deposit(uint256 _amount) external payable whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than zero.");
        userBalances[msg.sender] += _amount;
        totalFundValue += _amount;
        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    /// @notice Allows users to withdraw their funds from the DAIF.
    /// @param _amount The amount of funds to withdraw.
    function withdraw(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance.");
        userBalances[msg.sender] -= _amount;
        totalFundValue -= _amount;
        payable(msg.sender).transfer(_amount); // Sending Ether directly
        emit Withdrawal(msg.sender, _amount, block.timestamp);
    }

    /// @notice Returns the current total value of the DAIF.
    /// @return The total fund value.
    function getFundValue() external view returns (uint256) {
        return totalFundValue;
    }

    /// @notice Returns the balance of a specific user in the DAIF.
    /// @param _user The address of the user.
    /// @return The user's balance.
    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

    // 2. Governance and Strategy Management

    /// @notice Allows governance token holders to propose a new investment strategy.
    /// @param _strategyName The name of the proposed strategy.
    /// @param _strategyContract The address of the strategy contract.
    /// @param _strategyData Additional data required for strategy execution.
    function proposeStrategy(string memory _strategyName, address _strategyContract, bytes memory _strategyData) external whenNotPaused {
        // In a real DAO, this would be restricted to governance token holders
        proposalCount++;
        strategyProposals[proposalCount] = StrategyProposal({
            strategyName: _strategyName,
            strategyContract: _strategyContract,
            strategyData: _strategyData,
            votesFor: 0,
            votesAgainst: 0,
            isActive: false
        });
        emit StrategyProposed(proposalCount, _strategyName, _strategyContract, msg.sender, block.timestamp);
    }

    /// @notice Allows governance token holders to vote on a strategy proposal.
    /// @param _proposalId The ID of the strategy proposal.
    /// @param _vote True for 'for', false for 'against'.
    function voteOnStrategy(uint256 _proposalId, bool _vote) external whenNotPaused {
        // In a real DAO, voting power would be based on governance token holdings
        require(strategyProposals[_proposalId].strategyName.length > 0, "Invalid proposal ID.");
        require(!strategyProposals[_proposalId].isActive, "Proposal already decided.");

        if (_vote) {
            strategyProposals[_proposalId].votesFor++;
        } else {
            strategyProposals[_proposalId].votesAgainst++;
        }
        emit StrategyVoted(_proposalId, msg.sender, _vote, block.timestamp);

        // Example: Simple majority to activate strategy (can be changed to quorum, etc.)
        if (strategyProposals[_proposalId].votesFor > strategyProposals[_proposalId].votesAgainst * 2) { // Example: For votes twice of against votes
            strategyProposals[_proposalId].isActive = true;
            emit StrategyExecuted(_proposalId, strategyProposals[_proposalId].strategyName, strategyProposals[_proposalId].strategyContract, block.timestamp);
        }
    }

    /// @notice Executes a strategy that has been approved by governance. (Owner can trigger after voting - more secure approach)
    /// @param _strategyId The ID of the strategy to execute.
    function executeStrategy(uint256 _strategyId) external onlyOwner whenNotPaused {
        require(strategyProposals[_strategyId].strategyName.length > 0, "Invalid strategy ID.");
        require(strategyProposals[_strategyId].isActive, "Strategy proposal not approved yet.");

        // In a real implementation, this would call the strategy contract and execute the strategy
        // Example:
        // (bool success, bytes memory returnData) = strategyProposals[_strategyId].strategyContract.call(strategyProposals[_strategyId].strategyData);
        // require(success, "Strategy execution failed.");

        // For this example, we just log the execution
        emit StrategyExecuted(_strategyId, strategyProposals[_strategyId].strategyName, strategyProposals[_strategyId].strategyContract, block.timestamp);
    }

    /// @notice Allows governance to set a risk threshold for the fund.
    /// @param _newThreshold The new risk threshold (0-100).
    function setRiskThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused { // Governance controlled in real DAO
        require(_newThreshold <= 100, "Risk threshold must be between 0 and 100.");
        riskThreshold = _newThreshold;
        emit RiskThresholdSet(_newThreshold, msg.sender, block.timestamp);
    }

    /// @notice Returns the current risk score of the DAIF based on implemented strategies. (Placeholder - Needs actual risk calculation logic)
    /// @return The current risk score.
    function getRiskScore() external view returns (uint256) {
        // In a real implementation, this would calculate the risk score based on
        // the currently active strategies and market conditions.
        // This is a placeholder for a more complex risk assessment mechanism.
        return riskScore;
    }

    /// @notice Allows governance to trigger an emergency shutdown of the DAIF in critical situations.
    function emergencyShutdown() external onlyOwner whenNotPaused { // Governance controlled in real DAO
        paused = true;
        emit EmergencyShutdownTriggered(msg.sender, block.timestamp);
    }

    // 3. Advanced Investment Strategies (Conceptual - Can be extended)
    // ... (Strategy contracts and integration logic would be implemented separately) ...
    // ... (Functions to manage strategy allocation, rebalancing, etc. would be added here) ...


    // 4. User Features and Incentives

    /// @notice Allows the owner to set the performance fee rate.
    /// @param _newRate The new performance fee rate (in percentage, e.g., 5 for 5%).
    function setPerformanceFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 100, "Performance fee rate must be between 0 and 100.");
        performanceFeeRate = _newRate;
        emit PerformanceFeeRateSet(_newRate, msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to set the management fee rate.
    /// @param _newRate The new management fee rate (in percentage, e.g., 1 for 1%).
    function setManagementFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 100, "Management fee rate must be between 0 and 100.");
        managementFeeRate = _newRate;
        emit ManagementFeeRateSet(_newRate, msg.sender, block.timestamp);
    }

    /// @notice Distributes collected fees to the owner/designated address. (Simplified example)
    function distributeFees() external onlyOwner whenNotPaused {
        uint256 timeElapsed = block.timestamp - lastFeeCollectionTimestamp;
        uint256 managementFees = (totalFundValue * managementFeeRate * timeElapsed) / (100 * 365 days); // Simplified annual management fee
        // Performance fees would be calculated based on strategy performance and realized gains

        uint256 totalFees = managementFees; // + performanceFees; // Add performance fees calculation logic here
        require(totalFees <= address(this).balance, "Insufficient contract balance to distribute fees.");

        payable(owner).transfer(totalFees); // Owner receives fees in this simplified example
        lastFeeCollectionTimestamp = block.timestamp;
        emit FeesDistributed(totalFees, msg.sender, block.timestamp);
    }


    /// @notice Allows the owner to add a pre-approved strategy to the available strategies.
    /// @param _strategyName The name of the strategy.
    /// @param _strategyContract The address of the strategy contract.
    function addStrategy(string memory _strategyName, address _strategyContract) external onlyOwner {
        strategyCount++;
        investmentStrategies[strategyCount] = InvestmentStrategy({
            strategyName: _strategyName,
            strategyContract: _strategyContract,
            isActive: false,
            allocationPercentage: 0
        });
        emit StrategyAdded(strategyCount, _strategyName, _strategyContract, msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to remove a strategy from the available strategies.
    /// @param _strategyId The ID of the strategy to remove.
    function removeStrategy(uint256 _strategyId) external onlyOwner {
        require(investmentStrategies[_strategyId].strategyName.length > 0, "Invalid strategy ID.");
        delete investmentStrategies[_strategyId];
        emit StrategyRemoved(_strategyId, msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to activate a pre-approved strategy for investment.
    /// @param _strategyId The ID of the strategy to activate.
    function activateStrategy(uint256 _strategyId) external onlyOwner {
        require(investmentStrategies[_strategyId].strategyName.length > 0, "Invalid strategy ID.");
        investmentStrategies[_strategyId].isActive = true;
        emit StrategyActivated(_strategyId, msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to deactivate a currently active strategy.
    /// @param _strategyId The ID of the strategy to deactivate.
    function deactivateStrategy(uint256 _strategyId) external onlyOwner {
        require(investmentStrategies[_strategyId].strategyName.length > 0, "Invalid strategy ID.");
        investmentStrategies[_strategyId].isActive = false;
        emit StrategyDeactivated(_strategyId, msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to set the referral bonus percentage.
    /// @param _bonusPercentage The referral bonus percentage.
    function setReferralBonus(uint256 _bonusPercentage) external onlyOwner {
        require(_bonusPercentage <= 100, "Referral bonus percentage must be between 0 and 100.");
        referralBonusPercentage = _bonusPercentage;
        emit ReferralBonusSet(_bonusPercentage, msg.sender, block.timestamp);
    }

    /// @notice Allows users to refer new investors and earn a bonus.
    /// @param _referredInvestor The address of the investor being referred.
    function referInvestor(address _referredInvestor) external whenNotPaused {
        // In a real implementation, referral bonuses would be calculated and distributed upon the referred investor's deposit.
        // This is a simplified example logging the referral.
        emit InvestorReferred(msg.sender, _referredInvestor, referralBonusPercentage, block.timestamp);
    }

    // 5. Security and Control Features

    /// @notice Allows the owner to pause the contract in case of emergencies.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender, block.timestamp);
    }

    /// @notice Allows the owner to set the address of the price oracle.
    /// @param _oracleAddress The address of the price oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress, msg.sender, block.timestamp);
    }

    /// @notice Returns the performance metrics of a specific strategy. (Placeholder - Needs actual strategy performance tracking)
    /// @param _strategyId The ID of the strategy.
    /// @return The performance value (example - can be ROI, APY, etc.).
    function getStrategyPerformance(uint256 _strategyId) external view returns (uint256) {
        // In a real implementation, this function would query the strategy contract
        // or track performance metrics internally based on strategy execution.
        // This is a placeholder returning a dummy value.
        uint256 performanceValue = 5; // Example performance value (e.g., 5% ROI)
        emit StrategyPerformanceReport(_strategyId, investmentStrategies[_strategyId].strategyName, performanceValue, block.timestamp);
        return performanceValue;
    }

    // 6. Governance Token Staking and Rewards (Conceptual)

    // ... (Functions for governance token staking, unstaking, and reward distribution would be implemented here) ...
    // ... (These functions would interact with a separate governance token contract - not included in this example for simplicity) ...

    // Example placeholders:
    function stakeGovernanceTokens(uint256 _amount) external view returns (uint256){
        return _amount; // Placeholder
    }
    function unstakeGovernanceTokens(uint256 _amount) external view returns (uint256){
        return _amount; // Placeholder
    }
    function rewardGovernanceParticipants() external view returns (uint256){
        return 1; // Placeholder
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```