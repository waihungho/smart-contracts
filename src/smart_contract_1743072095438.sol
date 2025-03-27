```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Investment Fund (DAIF) - Advanced Smart Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a Decentralized Autonomous Investment Fund (DAIF)
 * with advanced features for community-driven investment strategies and fund management.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Functionality:**
 *    - `deposit(uint256 _amount)`: Allows investors to deposit ETH into the fund and receive fund shares.
 *    - `withdraw(uint256 _shares)`: Allows investors to withdraw ETH from the fund by burning their shares.
 *    - `redeemShares(uint256 _shares)`:  Similar to withdraw, but allows withdrawal of specific tokens held by the fund (if implemented). (Placeholder for advanced asset management)
 *    - `getFundValue()`: Returns the current total value of the fund in ETH (and potentially other assets).
 *    - `getTotalShares()`: Returns the total number of shares currently in circulation.
 *    - `getInvestorShareValue(address _investor)`: Returns the value of a specific investor's shares in ETH.
 *
 * **2. Investment Strategy Proposals & Voting (DAO-like Governance):**
 *    - `proposeInvestmentStrategy(string memory _strategyName, string memory _strategyDescription, address _targetAsset, uint256 _allocationPercentage)`: Allows fund managers to propose new investment strategies.
 *    - `voteOnStrategy(uint256 _strategyId, bool _vote)`: Investors can vote to approve or reject proposed investment strategies based on their shares.
 *    - `executeStrategy(uint256 _strategyId)`:  Fund managers can execute approved strategies (in a simplified simulation - in real-world, this would be more complex integration with DeFi protocols).
 *    - `getStrategyDetails(uint256 _strategyId)`: Returns details of a specific investment strategy.
 *    - `getActiveStrategies()`: Returns a list of currently active investment strategy IDs.
 *    - `getPastStrategies()`: Returns a list of past investment strategy IDs (approved and rejected).
 *
 * **3. Fund Management & Governance:**
 *    - `setGovernanceParameter(string memory _parameterName, uint256 _newValue)`: Allows governance to set key parameters like voting thresholds, fees, etc.
 *    - `appointFundManager(address _newManager)`: Allows governance to appoint new fund managers.
 *    - `revokeFundManager(address _manager)`: Allows governance to revoke fund manager status.
 *    - `pauseContract()`: Allows governance to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows governance to unpause the contract.
 *    - `emergencyWithdrawal(address _recipient, uint256 _amount)`:  Allows governance to withdraw funds to a designated address in emergency situations (e.g., exploit).
 *
 * **4. Advanced Features & Data Retrieval:**
 *    - `getContractBalance()`: Returns the current ETH balance of the contract.
 *    - `getVersion()`: Returns the contract version for easy identification and upgrades tracking.
 *    - `distributeRewards(uint256 _rewardAmount)`: (Placeholder) Function to distribute rewards to share holders (e.g., from staking or yield farming - advanced DeFi integration).
 *    - `getPortfolioHoldings()`: (Placeholder) Function to simulate and return a simplified representation of the fund's portfolio holdings (for visualization purposes - advanced asset tracking).
 *
 * **Note:** This contract is a simplified example and would require significant expansion and security audits for real-world deployment, especially for handling actual investments and integrations with external protocols.  Features marked "(Placeholder)" indicate areas for further development and advanced concepts.
 */
contract DecentralizedAutonomousInvestmentFund {
    string public contractName = "Decentralized Autonomous Investment Fund";
    string public version = "1.0.0";

    // State Variables
    mapping(address => uint256) public investorShares; // Investor address => shares held
    uint256 public totalShares = 0;
    uint256 public ethBalance = 0; // Track ETH balance explicitly (could also use address(this).balance)

    address public governanceAddress; // Address authorized for governance functions
    address[] public fundManagers; // List of addresses authorized as fund managers
    uint256 public strategyProposalThreshold = 5; // Percentage of shares needed to propose a strategy (e.g., 5%)
    uint256 public strategyApprovalThreshold = 50; // Percentage of shares needed to approve a strategy (e.g., 50%)
    bool public paused = false;

    struct InvestmentStrategy {
        uint256 id;
        string name;
        string description;
        address targetAsset; // Placeholder for target asset (e.g., token address, could be more complex)
        uint256 allocationPercentage; // Percentage of fund to allocate (e.g., 20%)
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
        bool isApproved;
        uint256 proposalTimestamp;
    }
    InvestmentStrategy[] public investmentStrategies;
    uint256 public nextStrategyId = 1;
    mapping(uint256 => mapping(address => bool)) public strategyVotes; // strategyId => investorAddress => hasVoted

    event Deposit(address investor, uint256 amount, uint256 sharesIssued);
    event Withdrawal(address investor, uint256 sharesBurned, uint256 amountWithdrawn);
    event StrategyProposed(uint256 strategyId, string strategyName, address proposer);
    event StrategyVoted(uint256 strategyId, address voter, bool vote);
    event StrategyExecuted(uint256 strategyId);
    event GovernanceParameterSet(string parameterName, uint256 newValue);
    event FundManagerAppointed(address newManager, address appointedBy);
    event FundManagerRevoked(address revokedManager, address revokedBy);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);
    event EmergencyWithdrawal(address recipient, uint256 amount, address withdrawnBy);
    event RewardsDistributed(uint256 rewardAmount, uint256 totalShares);

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function");
        _;
    }

    modifier onlyFundManager() {
        bool isManager = false;
        for (uint256 i = 0; i < fundManagers.length; i++) {
            if (fundManagers[i] == msg.sender) {
                isManager = true;
                break;
            }
        }
        require(isManager, "Only fund managers can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier strategyNotActive(uint256 _strategyId) {
        require(!investmentStrategies[_strategyId].isActive, "Strategy is already active");
        _;
    }

    // Constructor
    constructor() {
        governanceAddress = msg.sender; // Initial governance address is the contract deployer
        fundManagers.push(msg.sender); // Deployer is also the initial fund manager
    }

    // -------------------- 1. Core Functionality --------------------

    /// @notice Allows investors to deposit ETH into the fund and receive fund shares.
    /// @param _amount The amount of ETH to deposit.
    function deposit(uint256 _amount) external payable whenNotPaused {
        require(msg.value == _amount, "ETH value sent is not equal to deposit amount");
        require(_amount > 0, "Deposit amount must be greater than zero");

        uint256 sharesToIssue;
        if (totalShares == 0) {
            sharesToIssue = _amount; // Initial deposit: 1 ETH = 1 Share (for simplicity)
        } else {
            sharesToIssue = (_amount * totalShares) / ethBalance; // Calculate shares based on current fund value
        }

        investorShares[msg.sender] += sharesToIssue;
        totalShares += sharesToIssue;
        ethBalance += _amount;

        emit Deposit(msg.sender, _amount, sharesToIssue);
    }

    /// @notice Allows investors to withdraw ETH from the fund by burning their shares.
    /// @param _shares The number of shares to withdraw.
    function withdraw(uint256 _shares) external whenNotPaused {
        require(_shares > 0, "Withdrawal shares must be greater than zero");
        require(investorShares[msg.sender] >= _shares, "Insufficient shares to withdraw");

        uint256 ethToWithdraw = (_shares * ethBalance) / totalShares;
        require(ethBalance >= ethToWithdraw, "Insufficient fund balance for withdrawal");

        investorShares[msg.sender] -= _shares;
        totalShares -= _shares;
        ethBalance -= ethToWithdraw;

        payable(msg.sender).transfer(ethToWithdraw);

        emit Withdrawal(msg.sender, _shares, ethToWithdraw);
    }

    /// @notice Placeholder for advanced asset management - redeem shares for specific tokens held by the fund.
    /// @param _shares The number of shares to redeem.
    function redeemShares(uint256 _shares) external whenNotPaused {
        // In a more advanced version, this would allow redemption for specific tokens
        // currently held by the fund, based on portfolio allocation and share value.
        // This is a placeholder for future expansion.
        require(_shares > 0, "Redeem shares must be greater than zero");
        require(investorShares[msg.sender] >= _shares, "Insufficient shares to redeem");

        // For now, as a simplified example, it just behaves like a regular ETH withdrawal.
        withdraw(_shares);
    }

    /// @notice Returns the current total value of the fund in ETH.
    /// @return The total fund value in ETH.
    function getFundValue() public view returns (uint256) {
        return ethBalance; // In a real scenario, this would also include the value of other assets held.
    }

    /// @notice Returns the total number of shares currently in circulation.
    /// @return The total number of shares.
    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }

    /// @notice Returns the value of a specific investor's shares in ETH.
    /// @param _investor The address of the investor.
    /// @return The value of the investor's shares in ETH.
    function getInvestorShareValue(address _investor) public view returns (uint256) {
        if (totalShares == 0) return 0; // Avoid division by zero if no shares exist
        return (investorShares[_investor] * ethBalance) / totalShares;
    }

    // -------------------- 2. Investment Strategy Proposals & Voting --------------------

    /// @notice Allows fund managers to propose new investment strategies.
    /// @param _strategyName A descriptive name for the strategy.
    /// @param _strategyDescription A detailed description of the strategy.
    /// @param _targetAsset The address of the target asset for investment (placeholder, could be more complex).
    /// @param _allocationPercentage The percentage of the fund to allocate to this strategy.
    function proposeInvestmentStrategy(
        string memory _strategyName,
        string memory _strategyDescription,
        address _targetAsset,
        uint256 _allocationPercentage
    ) external onlyFundManager whenNotPaused {
        require(bytes(_strategyName).length > 0 && bytes(_strategyDescription).length > 0, "Strategy name and description cannot be empty");
        require(_allocationPercentage > 0 && _allocationPercentage <= 100, "Allocation percentage must be between 1 and 100");
        require(address(_targetAsset) != address(0), "Target asset address cannot be zero address");

        require((investorShares[msg.sender] * 100) / totalShares >= strategyProposalThreshold, "Proposer does not meet share threshold to propose strategy");


        investmentStrategies.push(InvestmentStrategy({
            id: nextStrategyId,
            name: _strategyName,
            description: _strategyDescription,
            targetAsset: _targetAsset,
            allocationPercentage: _allocationPercentage,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            isActive: false,
            isExecuted: false,
            isApproved: false,
            proposalTimestamp: block.timestamp
        }));
        emit StrategyProposed(nextStrategyId, _strategyName, msg.sender);
        nextStrategyId++;
    }

    /// @notice Investors can vote to approve or reject proposed investment strategies based on their shares.
    /// @param _strategyId The ID of the strategy to vote on.
    /// @param _vote True for approve, false for reject.
    function voteOnStrategy(uint256 _strategyId, bool _vote) external whenNotPaused {
        require(_strategyId > 0 && _strategyId < nextStrategyId, "Invalid strategy ID");
        require(!strategyVotes[_strategyId][msg.sender], "Investor has already voted on this strategy");
        require(!investmentStrategies[_strategyId].isActive, "Cannot vote on an active strategy");

        strategyVotes[_strategyId][msg.sender] = true;

        if (_vote) {
            investmentStrategies[_strategyId].votesFor += investorShares[msg.sender];
        } else {
            investmentStrategies[_strategyId].votesAgainst += investorShares[msg.sender];
        }

        uint256 totalVotesFor = investmentStrategies[_strategyId].votesFor;
        uint256 totalVotesAgainst = investmentStrategies[_strategyId].votesAgainst;

        if ((totalVotesFor * 100) / totalShares >= strategyApprovalThreshold) {
            investmentStrategies[_strategyId].isApproved = true;
        }

        emit StrategyVoted(_strategyId, msg.sender, _vote);
    }

    /// @notice Fund managers can execute approved strategies (simplified simulation).
    /// @param _strategyId The ID of the strategy to execute.
    function executeStrategy(uint256 _strategyId) external onlyFundManager whenNotPaused strategyNotActive(_strategyId) {
        require(_strategyId > 0 && _strategyId < nextStrategyId, "Invalid strategy ID");
        require(investmentStrategies[_strategyId].isApproved, "Strategy is not approved by governance");
        require(!investmentStrategies[_strategyId].isExecuted, "Strategy is already executed");

        investmentStrategies[_strategyId].isActive = true;
        investmentStrategies[_strategyId].isExecuted = true; // Mark as executed for this example.

        // In a real-world scenario, this function would:
        // 1. Interact with DeFi protocols or exchanges to execute the investment strategy.
        // 2. Transfer funds from the contract to the target asset (or protocol).
        // 3. Track the investment performance.
        // For this example, we'll just simulate it by marking it as active and executed.

        emit StrategyExecuted(_strategyId);
    }

    /// @notice Returns details of a specific investment strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return InvestmentStrategy struct containing strategy details.
    function getStrategyDetails(uint256 _strategyId) public view returns (InvestmentStrategy memory) {
        require(_strategyId > 0 && _strategyId < nextStrategyId, "Invalid strategy ID");
        return investmentStrategies[_strategyId];
    }

    /// @notice Returns a list of currently active investment strategy IDs.
    /// @return Array of active strategy IDs.
    function getActiveStrategies() public view returns (uint256[] memory) {
        uint256[] memory activeStrategyIds = new uint256[](investmentStrategies.length);
        uint256 count = 0;
        for (uint256 i = 0; i < investmentStrategies.length; i++) {
            if (investmentStrategies[i].isActive) {
                activeStrategyIds[count] = investmentStrategies[i].id;
                count++;
            }
        }
        // Resize the array to remove unused elements
        uint256[] memory trimmedActiveStrategyIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedActiveStrategyIds[i] = activeStrategyIds[i];
        }
        return trimmedActiveStrategyIds;
    }

    /// @notice Returns a list of past investment strategy IDs (approved and rejected).
    /// @return Array of past strategy IDs.
    function getPastStrategies() public view returns (uint256[] memory) {
        uint256[] memory pastStrategyIds = new uint256[](investmentStrategies.length);
        uint256 count = 0;
        for (uint256 i = 0; i < investmentStrategies.length; i++) {
            if (!investmentStrategies[i].isActive) {
                pastStrategyIds[count] = investmentStrategies[i].id;
                count++;
            }
        }
        // Resize the array to remove unused elements
        uint256[] memory trimmedPastStrategyIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedPastStrategyIds[i] = pastStrategyIds[i];
        }
        return trimmedPastStrategyIds;
    }

    // -------------------- 3. Fund Management & Governance --------------------

    /// @notice Allows governance to set key parameters like voting thresholds, fees, etc.
    /// @param _parameterName The name of the parameter to set (string identifier).
    /// @param _newValue The new value for the parameter.
    function setGovernanceParameter(string memory _parameterName, uint256 _newValue) external onlyGovernance whenNotPaused {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("strategyProposalThreshold"))) {
            strategyProposalThreshold = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("strategyApprovalThreshold"))) {
            strategyApprovalThreshold = _newValue;
        } else {
            revert("Invalid governance parameter name");
        }
        emit GovernanceParameterSet(_parameterName, _newValue);
    }

    /// @notice Allows governance to appoint new fund managers.
    /// @param _newManager The address of the new fund manager to appoint.
    function appointFundManager(address _newManager) external onlyGovernance whenNotPaused {
        require(_newManager != address(0), "New manager address cannot be zero address");
        // Check if already a manager (optional, depending on desired behavior)
        bool alreadyManager = false;
        for (uint256 i = 0; i < fundManagers.length; i++) {
            if (fundManagers[i] == _newManager) {
                alreadyManager = true;
                break;
            }
        }
        require(!alreadyManager, "Address is already a fund manager");

        fundManagers.push(_newManager);
        emit FundManagerAppointed(_newManager, msg.sender);
    }

    /// @notice Allows governance to revoke fund manager status.
    /// @param _manager The address of the fund manager to revoke.
    function revokeFundManager(address _manager) external onlyGovernance whenNotPaused {
        require(_manager != governanceAddress, "Cannot revoke governance address as fund manager"); // Prevent revoking governance itself
        for (uint256 i = 0; i < fundManagers.length; i++) {
            if (fundManagers[i] == _manager) {
                // Remove the manager from the array (more gas efficient to swap with last and pop)
                fundManagers[i] = fundManagers[fundManagers.length - 1];
                fundManagers.pop();
                emit FundManagerRevoked(_manager, msg.sender);
                return;
            }
        }
        revert("Address is not a fund manager");
    }

    /// @notice Allows governance to pause the contract in case of emergency.
    function pauseContract() external onlyGovernance {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows governance to unpause the contract.
    function unpauseContract() external onlyGovernance {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows governance to withdraw funds to a designated address in emergency situations.
    /// @param _recipient The address to receive the emergency withdrawn funds.
    /// @param _amount The amount of ETH to withdraw in emergency.
    function emergencyWithdrawal(address _recipient, uint256 _amount) external onlyGovernance whenNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero address");
        require(ethBalance >= _amount, "Insufficient contract balance for emergency withdrawal");

        ethBalance -= _amount;
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount, msg.sender);
    }

    // -------------------- 4. Advanced Features & Data Retrieval --------------------

    /// @notice Returns the current ETH balance of the contract.
    /// @return The contract's ETH balance.
    function getContractBalance() public view returns (uint256) {
        return ethBalance; // Or address(this).balance; using ethBalance for consistency in this example
    }

    /// @notice Returns the contract version for easy identification and upgrades tracking.
    /// @return The contract version string.
    function getVersion() public view returns (string memory) {
        return version;
    }

    /// @notice Placeholder function to distribute rewards to share holders (e.g., from staking or yield farming).
    /// @param _rewardAmount The amount of reward to distribute (in ETH or tokens - needs expansion).
    function distributeRewards(uint256 _rewardAmount) external onlyGovernance whenNotPaused {
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(ethBalance >= _rewardAmount, "Insufficient contract balance for reward distribution");

        ethBalance -= _rewardAmount;
        uint256 rewardPerShare = _rewardAmount / totalShares; // Simple uniform distribution for example

        for (uint256 i = 0; i < investmentStrategies.length; i++) { // Very inefficient - iterate investors in real-world
            address investorAddress = investmentStrategies[i].proposer; // Example - distribute to proposers for now (replace with actual investor loop)
            if (investorShares[investorAddress] > 0) {
                uint256 investorReward = investorShares[investorAddress] * rewardPerShare;
                payable(investorAddress).transfer(investorReward); // Gas intensive for large number of investors
            }
        }

        emit RewardsDistributed(_rewardAmount, totalShares);
    }

    /// @notice Placeholder function to simulate and return a simplified representation of the fund's portfolio holdings.
    /// @return A string representing the portfolio (in a real scenario, this would be more structured data).
    function getPortfolioHoldings() public view returns (string memory) {
        // In a real advanced scenario, this would:
        // 1. Track the actual assets held by the contract (ETH, tokens, etc.).
        // 2. Fetch real-time price data from oracles for each asset.
        // 3. Calculate the value of each holding and the total portfolio value.
        // 4. Return a structured data format (e.g., array of structs) representing holdings.

        // For this simplified example, just return a placeholder string.
        return "Simulated Portfolio Holdings: [ETH: " + uint2str(ethBalance) + ", ... (Advanced Asset Tracking Placeholder)]";
    }

    // --- Utility Function (for string conversion in getPortfolioHoldings - avoid external libs for simplicity) ---
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
```