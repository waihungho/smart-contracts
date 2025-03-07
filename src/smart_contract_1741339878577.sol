```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Investment Fund (DAIF) - Advanced Smart Contract
 * @author Bard (Example - Not for Production)
 *
 * @dev This contract implements a Decentralized Autonomous Investment Fund (DAIF) with advanced features.
 * It allows users to deposit ETH, participate in investment strategy proposals, vote on strategies,
 * and receive proportional shares of profits or losses based on the fund's performance.
 *
 * **Outline and Function Summary:**
 *
 * **Core Investment Functions:**
 *   1. `depositETH()`: Allows users to deposit ETH into the fund.
 *   2. `withdrawETH(uint256 _amount)`: Allows users to withdraw ETH from their balance in the fund.
 *   3. `getInvestorBalance(address _investor)`: Returns the ETH balance of a specific investor.
 *   4. `getTotalFundBalance()`: Returns the total ETH balance held by the fund.
 *
 * **Fund Management & Strategy Functions:**
 *   5. `proposeInvestmentStrategy(string memory _strategyName, string memory _strategyDescription, address _targetContract, bytes memory _strategyData)`: Allows fund managers to propose a new investment strategy.
 *   6. `voteOnStrategy(uint256 _strategyId, bool _vote)`: Allows investors to vote on pending investment strategies.
 *   7. `executeStrategy(uint256 _strategyId)`: Allows fund managers to execute an approved investment strategy (simulated here, requires external execution in real-world).
 *   8. `getStrategyDetails(uint256 _strategyId)`: Returns details of a specific investment strategy.
 *   9. `getStrategyStatus(uint256 _strategyId)`: Returns the current status of an investment strategy (Pending, Approved, Rejected, Executed).
 *   10. `listPendingStrategies()`: Returns a list of IDs of currently pending investment strategies.
 *   11. `listApprovedStrategies()`: Returns a list of IDs of approved investment strategies.
 *   12. `listRejectedStrategies()`: Returns a list of IDs of rejected investment strategies.
 *   13. `listExecutedStrategies()`: Returns a list of IDs of executed investment strategies.
 *   14. `cancelStrategyProposal(uint256 _strategyId)`: Allows the proposer to cancel a strategy proposal before voting ends.
 *
 * **Governance & Roles Functions:**
 *   15. `addFundManager(address _manager)`: Allows the contract owner to add a new fund manager.
 *   16. `removeFundManager(address _manager)`: Allows the contract owner to remove a fund manager.
 *   17. `isFundManager(address _account)`: Checks if an address is a registered fund manager.
 *   18. `setVotingDuration(uint256 _durationInBlocks)`: Allows the contract owner to set the voting duration for strategy proposals.
 *   19. `getVotingDuration()`: Returns the current voting duration for strategy proposals.
 *
 * **Advanced & Utility Functions:**
 *   20. `emergencyWithdrawal(address _recipient)`: Allows the contract owner to withdraw all funds to a specified address in case of an emergency. (Use with extreme caution).
 *   21. `pauseContract()`: Allows the contract owner to pause the contract, preventing deposits, withdrawals, and strategy proposals.
 *   22. `unpauseContract()`: Allows the contract owner to unpause the contract.
 *   23. `isContractPaused()`: Returns the current pause status of the contract.
 *   24. `calculateInvestorShare(address _investor)`: Calculates the current proportional share of an investor based on total fund value (Illustrative - more complex calculations needed in real-world).
 */

contract DecentralizedAutonomousInvestmentFund {

    // --- State Variables ---

    address public owner;
    mapping(address => uint256) public investorBalances; // Investor address => ETH balance
    uint256 public totalFundBalance;
    uint256 public votingDurationInBlocks = 100; // Default voting duration in blocks

    mapping(address => bool) public isManager;
    address[] public fundManagers;

    uint256 public strategyCounter;
    struct InvestmentStrategy {
        string name;
        string description;
        address proposer;
        address targetContract;
        bytes strategyData;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        StrategyStatus status;
    }
    mapping(uint256 => InvestmentStrategy) public strategies;
    enum StrategyStatus { Pending, Approved, Rejected, Executed, Cancelled }

    bool public paused;

    // --- Events ---

    event Deposit(address indexed investor, uint256 amount);
    event Withdrawal(address indexed investor, uint256 amount);
    event StrategyProposed(uint256 strategyId, string strategyName, address proposer);
    event StrategyVoted(uint256 strategyId, address investor, bool vote);
    event StrategyExecuted(uint256 strategyId);
    event StrategyCancelled(uint256 strategyId);
    event FundManagerAdded(address manager);
    event FundManagerRemoved(address manager);
    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyFundManagers() {
        require(isManager[msg.sender], "Only fund managers can call this function.");
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

    modifier validStrategyId(uint256 _strategyId) {
        require(_strategyId > 0 && _strategyId <= strategyCounter, "Invalid strategy ID.");
        _;
    }

    modifier strategyInStatus(uint256 _strategyId, StrategyStatus _status) {
        require(strategies[_strategyId].status == _status, "Strategy is not in the required status.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        isManager[owner] = true; // Owner is initially a fund manager
        fundManagers.push(owner);
        paused = false;
        strategyCounter = 0;
    }

    // --- Core Investment Functions ---

    /// @notice Allows users to deposit ETH into the fund.
    function depositETH() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        investorBalances[msg.sender] += msg.value;
        totalFundBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows users to withdraw ETH from their balance in the fund.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(investorBalances[msg.sender] >= _amount, "Insufficient balance.");
        payable(msg.sender).transfer(_amount);
        investorBalances[msg.sender] -= _amount;
        totalFundBalance -= _amount;
        emit Withdrawal(msg.sender, _amount);
    }

    /// @notice Returns the ETH balance of a specific investor.
    /// @param _investor The address of the investor.
    /// @return The ETH balance of the investor.
    function getInvestorBalance(address _investor) external view returns (uint256) {
        return investorBalances[_investor];
    }

    /// @notice Returns the total ETH balance held by the fund.
    /// @return The total ETH balance of the fund.
    function getTotalFundBalance() external view returns (uint256) {
        return totalFundBalance;
    }

    // --- Fund Management & Strategy Functions ---

    /// @notice Allows fund managers to propose a new investment strategy.
    /// @param _strategyName A descriptive name for the strategy.
    /// @param _strategyDescription A detailed description of the strategy.
    /// @param _targetContract The address of the contract to interact with for the strategy.
    /// @param _strategyData Encoded data to be passed to the target contract function.
    function proposeInvestmentStrategy(
        string memory _strategyName,
        string memory _strategyDescription,
        address _targetContract,
        bytes memory _strategyData
    ) external onlyFundManagers whenNotPaused {
        strategyCounter++;
        strategies[strategyCounter] = InvestmentStrategy({
            name: _strategyName,
            description: _strategyDescription,
            proposer: msg.sender,
            targetContract: _targetContract,
            strategyData: _strategyData,
            startTime: block.number,
            endTime: block.number + votingDurationInBlocks,
            yesVotes: 0,
            noVotes: 0,
            status: StrategyStatus.Pending
        });
        emit StrategyProposed(strategyCounter, _strategyName, msg.sender);
    }

    /// @notice Allows investors to vote on pending investment strategies.
    /// @param _strategyId The ID of the strategy to vote on.
    /// @param _vote True for Yes, False for No.
    function voteOnStrategy(uint256 _strategyId, bool _vote) external whenNotPaused validStrategyId(_strategyId) strategyInStatus(_strategyId, StrategyStatus.Pending) {
        require(block.number <= strategies[_strategyId].endTime, "Voting period has ended.");
        require(investorBalances[msg.sender] > 0, "Only investors can vote."); // Optional: Require investors to have a balance to vote

        // Simple vote counting - In a real DAO, consider weighted voting based on investment amount
        if (_vote) {
            strategies[_strategyId].yesVotes++;
        } else {
            strategies[_strategyId].noVotes++;
        }
        emit StrategyVoted(_strategyId, msg.sender, _vote);

        // Automatically update strategy status if voting period ends
        if (block.number > strategies[_strategyId].endTime) {
            _finalizeStrategy(_strategyId);
        }
    }

    /// @dev Internal function to finalize a strategy after the voting period.
    function _finalizeStrategy(uint256 _strategyId) internal validStrategyId(_strategyId) strategyInStatus(_strategyId, StrategyStatus.Pending) {
        if (strategies[_strategyId].yesVotes > strategies[_strategyId].noVotes) {
            strategies[_strategyId].status = StrategyStatus.Approved;
        } else {
            strategies[_strategyId].status = StrategyStatus.Rejected;
        }
    }

    /// @notice Allows fund managers to execute an approved investment strategy.
    /// @dev In a real-world scenario, this function would interact with external contracts or protocols.
    /// @param _strategyId The ID of the strategy to execute.
    function executeStrategy(uint256 _strategyId) external onlyFundManagers whenNotPaused validStrategyId(_strategyId) strategyInStatus(_strategyId, StrategyStatus.Approved) {
        strategies[_strategyId].status = StrategyStatus.Executed;
        // In a real implementation:
        // 1. Call the target contract and function using strategies[_strategyId].targetContract and strategies[_strategyId].strategyData
        // 2. Handle potential errors and revert scenarios
        // 3. Update fund balance and investor balances based on strategy outcome (This is complex and requires external data/oracles in real-world)

        // Placeholder for strategy execution logic - For demonstration purposes, we just mark it as executed.
        emit StrategyExecuted(_strategyId);
    }


    /// @notice Returns details of a specific investment strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return Strategy details (name, description, proposer, targetContract, status, votes, etc.).
    function getStrategyDetails(uint256 _strategyId) external view validStrategyId(_strategyId) returns (InvestmentStrategy memory) {
        return strategies[_strategyId];
    }

    /// @notice Returns the current status of an investment strategy.
    /// @param _strategyId The ID of the strategy.
    /// @return The status of the strategy (Pending, Approved, Rejected, Executed).
    function getStrategyStatus(uint256 _strategyId) external view validStrategyId(_strategyId) returns (StrategyStatus) {
        return strategies[_strategyId].status;
    }

    /// @notice Returns a list of IDs of currently pending investment strategies.
    /// @return An array of strategy IDs.
    function listPendingStrategies() external view returns (uint256[] memory) {
        uint256[] memory pendingStrategyIds = new uint256[](strategyCounter); // Max size, might be less in reality
        uint256 count = 0;
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Pending) {
                pendingStrategyIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(pendingStrategyIds, count) // Update array length
        }
        return pendingStrategyIds;
    }

    /// @notice Returns a list of IDs of approved investment strategies.
    /// @return An array of strategy IDs.
    function listApprovedStrategies() external view returns (uint256[] memory) {
        uint256[] memory approvedStrategyIds = new uint256[](strategyCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Approved) {
                approvedStrategyIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(approvedStrategyIds, count)
        }
        return approvedStrategyIds;
    }

    /// @notice Returns a list of IDs of rejected investment strategies.
    /// @return An array of strategy IDs.
    function listRejectedStrategies() external view returns (uint256[] memory) {
        uint256[] memory rejectedStrategyIds = new uint256[](strategyCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Rejected) {
                rejectedStrategyIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(rejectedStrategyIds, count)
        }
        return rejectedStrategyIds;
    }

    /// @notice Returns a list of IDs of executed investment strategies.
    /// @return An array of strategy IDs.
    function listExecutedStrategies() external view returns (uint256[] memory) {
        uint256[] memory executedStrategyIds = new uint256[](strategyCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Executed) {
                executedStrategyIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(executedStrategyIds, count)
        }
        return executedStrategyIds;
    }

    /// @notice Allows the proposer to cancel a strategy proposal before voting ends.
    /// @param _strategyId The ID of the strategy to cancel.
    function cancelStrategyProposal(uint256 _strategyId) external validStrategyId(_strategyId) strategyInStatus(_strategyId, StrategyStatus.Pending) {
        require(strategies[_strategyId].proposer == msg.sender, "Only strategy proposer can cancel.");
        require(block.number <= strategies[_strategyId].endTime, "Voting period has ended, cannot cancel now.");
        strategies[_strategyId].status = StrategyStatus.Cancelled;
        emit StrategyCancelled(_strategyId);
    }


    // --- Governance & Roles Functions ---

    /// @notice Allows the contract owner to add a new fund manager.
    /// @param _manager The address of the new fund manager.
    function addFundManager(address _manager) external onlyOwner {
        require(!isManager[_manager], "Address is already a fund manager.");
        isManager[_manager] = true;
        fundManagers.push(_manager);
        emit FundManagerAdded(_manager);
    }

    /// @notice Allows the contract owner to remove a fund manager.
    /// @param _manager The address of the fund manager to remove.
    function removeFundManager(address _manager) external onlyOwner {
        require(isManager[_manager], "Address is not a fund manager.");
        require(_manager != owner, "Cannot remove the contract owner as a manager."); // Prevent removing owner
        isManager[_manager] = false;

        // Remove from fundManagers array (optional - depends on how you use the array)
        for (uint256 i = 0; i < fundManagers.length; i++) {
            if (fundManagers[i] == _manager) {
                fundManagers[i] = fundManagers[fundManagers.length - 1];
                fundManagers.pop();
                break;
            }
        }
        emit FundManagerRemoved(_manager);
    }

    /// @notice Checks if an address is a registered fund manager.
    /// @param _account The address to check.
    /// @return True if the address is a fund manager, false otherwise.
    function isFundManager(address _account) external view returns (bool) {
        return isManager[_account];
    }

    /// @notice Allows the contract owner to set the voting duration for strategy proposals.
    /// @param _durationInBlocks The voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        require(_durationInBlocks > 0, "Voting duration must be greater than zero.");
        votingDurationInBlocks = _durationInBlocks;
    }

    /// @notice Returns the current voting duration for strategy proposals.
    /// @return The voting duration in blocks.
    function getVotingDuration() external view returns (uint256) {
        return votingDurationInBlocks;
    }

    // --- Advanced & Utility Functions ---

    /// @notice Allows the contract owner to withdraw all funds to a specified address in case of an emergency.
    /// @dev Use with extreme caution as this bypasses normal withdrawal mechanisms.
    /// @param _recipient The address to receive the funds.
    function emergencyWithdrawal(address payable _recipient) external onlyOwner {
        uint256 amount = totalFundBalance;
        require(amount > 0, "No funds to withdraw.");
        _recipient.transfer(amount);
        totalFundBalance = 0;
        // Reset investor balances - optional, depends on emergency scenario handling
        for (uint256 i = 0; i < fundManagers.length; i++) { // Iterate through managers as a proxy for investors for simplicity in example
            investorBalances[fundManagers[i]] = 0;
        }
        emit EmergencyWithdrawal(_recipient, amount);
    }

    /// @notice Allows the contract owner to pause the contract, preventing deposits, withdrawals, and strategy proposals.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows the contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Returns the current pause status of the contract.
    /// @return True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Calculates the current proportional share of an investor based on total fund value.
    /// @dev **Illustrative and Simplified:** In a real-world fund, share calculation would be much more complex,
    ///      accounting for strategy performance, fees, time-weighted contributions, etc. This is a basic example.
    /// @param _investor The address of the investor.
    /// @return The proportional share of the investor (in hypothetical units, not actual ETH).
    function calculateInvestorShare(address _investor) external view returns (uint256) {
        if (totalFundBalance == 0) {
            return 0; // Avoid division by zero
        }
        return (investorBalances[_investor] * 10000) / totalFundBalance; // Example: Share as parts per 10000
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Decentralized Autonomous Investment Fund (DAIF):**  The core concept itself is trendy and addresses the growing interest in decentralized finance (DeFi) and decentralized autonomous organizations (DAOs).  It aims to create a fund managed by code and community rather than traditional centralized institutions.

2.  **Investment Strategy Proposals & Voting:**  This incorporates DAO-like governance into the investment process. Fund managers propose strategies, and investors (the community) vote on whether to approve them. This is a core element of decentralization and community-driven decision-making.

3.  **Simulated Strategy Execution:**  While this example doesn't integrate with real DeFi protocols (which would be very complex for a single contract example), it lays the groundwork for how strategies could be defined and executed within a smart contract context.  The `executeStrategy` function is a placeholder for more sophisticated logic that would interact with external contracts and potentially oracles to manage investments.

4.  **Strategy Lifecycle Management:** The contract tracks the status of strategies (Pending, Approved, Rejected, Executed, Cancelled), providing a clear workflow for investment proposals.

5.  **Fund Manager Roles:**  The concept of fund managers with specific privileges (proposing strategies, executing strategies) adds a layer of delegated management within the decentralized framework.

6.  **Voting Duration & Governance Parameters:**  The voting duration is configurable, demonstrating a basic governance parameter that can be adjusted by the contract owner (potentially by a DAO governance mechanism in a more advanced version).

7.  **Emergency Withdrawal & Pausing:**  These are safety mechanisms often seen in smart contracts, acknowledging the need for owner intervention in exceptional circumstances, even in a decentralized system.  Pausing provides a circuit breaker in case of vulnerabilities or unforeseen issues.

8.  **Investor Share Calculation (Illustrative):** The `calculateInvestorShare` function hints at the concept of tracking investor contributions and distributing profits/losses proportionally.  While simplified in this example, it points towards the complex accounting and distribution mechanisms needed in a real DAIF.

**Key Improvements and Considerations for a Real-World Implementation:**

*   **Real Strategy Execution:**  The `executeStrategy` function is a placeholder. A real DAIF would need to integrate with DeFi protocols (e.g., DEXs, lending platforms, yield farms) to execute investment strategies. This would involve:
    *   **Oracle Integration:** To get real-time price data and market information.
    *   **DeFi Protocol Interactions:**  Using interfaces to interact with external smart contracts.
    *   **Risk Management:**  Implementing safeguards to manage risks associated with DeFi protocols.
*   **Advanced Governance:**  For a true DAO, governance should be more decentralized. Consider:
    *   **Token-based Governance:**  Issuing a governance token to investors for voting power.
    *   **Delegated Voting:** Allowing token holders to delegate their voting power.
    *   **On-chain Governance Proposals:**  Making governance changes through proposals and voting.
*   **Performance Tracking & Reporting:**  A real DAIF needs robust mechanisms to track fund performance, calculate Net Asset Value (NAV), and provide transparent reporting to investors.
*   **Security Audits:**  Smart contracts managing funds require rigorous security audits to prevent vulnerabilities and exploits.
*   **Gas Optimization:**  Real-world contracts need to be optimized for gas efficiency to minimize transaction costs.
*   **Fee Structure:** Implement a fee structure (e.g., management fees, performance fees) to incentivize fund managers and sustain the DAIF.
*   **Legal and Regulatory Compliance:**  DAIFs operating with real funds would need to consider legal and regulatory compliance in their jurisdictions.

This smart contract provides a conceptual framework for a Decentralized Autonomous Investment Fund. Building a production-ready DAIF would require significant further development, security considerations, and integration with the wider DeFi ecosystem.