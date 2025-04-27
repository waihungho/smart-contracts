Okay, here is a smart contract in Solidity incorporating advanced, creative, and trendy concepts like dynamic fees based on user activity/reputation ("Flow Score"), a unique "Entanglement" fee adjustment based on transaction partners, a staking mechanism with time-weighted rewards, and a simple on-chain governance module to manage key parameters.

It uses OpenZeppelin libraries for foundational standards (ERC20, AccessControl, Pausable) but builds entirely custom logic on top, ensuring it's not a direct copy of existing popular token contracts.

**Contract Name:** `QuantumFlowToken`

**Concepts Integrated:**
1.  **ERC-20 Base:** Standard token functionality.
2.  **Dynamic Fees:** Transfer fees vary based on parameters.
3.  **Flow Score (Reputation):** An on-chain score tracking user activity/participation.
4.  **Entanglement Fee Logic:** Fee discount based on the *average* Flow Score of sender and receiver.
5.  **Staking:** Users can stake tokens to earn rewards.
6.  **Time-Weighted Staking Rewards:** Rewards accrue based on stake duration and amount.
7.  **Fee Distribution:** Transfer fees are split between burning, a treasury, and potentially funding rewards (indirectly via governance).
8.  **On-Chain Governance:** Holders (with sufficient Flow Score) can propose and vote on parameter changes.
9.  **Access Control:** Role-based permissions for administrative actions.
10. **Pausable:** Ability to pause transfers in emergencies.
11. **Bulk Transfers:** Utility function for sending tokens to multiple recipients.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title QuantumFlowToken
/// @dev An advanced ERC-20 token with dynamic fees, user reputation, staking, and on-chain governance.
/// @author YourName or Pseudonym

/*
 Outline & Function Summary

 1. Core Token & Base Functionality
    - Based on ERC-20, AccessControl, Pausable.
    - Overrides _transfer for custom fee logic and flow score updates.
    - Basic token info (name, symbol, supply).

 2. Role Management (Inherited from AccessControl)
    - DEFAULT_ADMIN_ROLE: Can grant/revoke other roles.
    - PAUSER_ROLE: Can pause/unpause the contract.
    - GOVERNANCE_ROLE: Can set key token parameters and withdraw from treasury.

 3. Dynamic Fee System
    - transferFeePercentage: Base percentage applied to transfers.
    - burnFeePercentage: Percentage of the fee that is burned.
    - treasuryFeePercentage: Percentage of the fee sent to the treasury.
    - minFlowScoreForFeeDiscount: Minimum combined average score for a fee discount.
    - entanglementFactorWeight: Influences how much the average flow score affects the fee discount.
    - Fee is calculated in _transfer and split.

 4. Flow Score (User Reputation/Activity)
    - userFlowScore: Mapping tracking a score for each address.
    - lastActivityTime: Tracks last significant activity time.
    - Score updates dynamically on transfers (sender & receiver).
    - Score influences fee discount via entanglement logic.

 5. Staking Mechanism
    - Allows users to stake QFT tokens.
    - Staked balances track user stakes.
    - Rewards accrue based on staked amount and time.
    - Reward rate can be adjusted via governance or administrative action (e.g., funded by treasury).

 6. Treasury
    - treasuryAddress: Address receiving the treasury portion of transfer fees.
    - treasuryBalance: Tracks tokens held in the treasury.
    - Funds can be withdrawn by GOVERNANCE_ROLE.

 7. On-Chain Governance
    - Allows GOVERNANCE_ROLE or potentially users (if implemented) to propose changes to parameters.
    - proposalCounter: Counter for unique proposal IDs.
    - proposals: Mapping storing proposal details (parameter, value, state).
    - votes: Mapping tracking user votes on proposals.
    - Governance parameters (min score/balance to vote, quorum, majority) are configurable.

 8. Events
    - Log significant actions: Transfers (with fees), Fee/Parameter updates, Score updates, Staking actions, Treasury withdrawals, Governance actions.

 9. State Variables
    - Mappings for balances, allowances, scores, stakes, votes, etc.
    - Variables for fee percentages, governance parameters, staking state.

 10. Functions (20+ Unique/Overridden Beyond Basic ERC20)

    *   **Core Overrides & Base:**
        - `constructor()`: Initializes token, roles, initial parameters.
        - `_transfer()` (internal, override): Implements core transfer logic including fees, score updates, and pausable check.
        - `pause()` (external): Pauses transfers (PAUSER_ROLE).
        - `unpause()` (external): Unpauses transfers (PAUSER_ROLE).
        - `burn()` (public): Burns tokens from caller (override).
        - `burnFrom()` (public): Burns tokens from account (override).

    *   **Dynamic Fee & Parameter Management (GOVERNANCE_ROLE):**
        - `setTransferFeePercentage(uint256 percentage)`: Sets the base transfer fee.
        - `setBurnFeePercentage(uint256 percentage)`: Sets the percentage of fee burned.
        - `setTreasuryFeePercentage(uint256 percentage)`: Sets the percentage of fee sent to treasury.
        - `setEntanglementFactorWeight(uint256 weight)`: Sets the weight for fee discount calculation.
        - `setMinFlowScoreForFeeDiscount(uint256 score)`: Sets min score for discount eligibility.
        - `getEffectiveTransferFee(address sender, address recipient, uint256 amount)` (public view): Calculates effective fee for a transfer.
        - `_calculateEffectiveFeePercentage(address sender, address recipient)` (internal view): Calculates fee % after score discount.

    *   **Flow Score & Reputation:**
        - `getFlowScore(address user)` (public view): Gets a user's current Flow Score.
        - `_updateFlowScore(address user, uint256 scoreChange)` (internal): Updates user's score.
        - `_applyFlowScoreUpdate(address sender, address recipient, uint256 amount)` (internal): Logic to update scores based on transfer.
        - `getUserLastActivityTime(address user)` (public view): Gets last activity timestamp.

    *   **Staking:**
        - `stake(uint256 amount)` (public nonReentrant): Stakes tokens for the caller.
        - `withdrawStake(uint256 amount)` (public nonReentrant): Withdraws staked tokens.
        - `claimRewards()` (public nonReentrant): Claims accumulated staking rewards.
        - `calculateRewards(address user)` (public view): Calculates pending rewards for a user.
        - `getUserStake(address user)` (public view): Gets user's staked balance.
        - `getTotalStakedSupply()` (public view): Gets total staked tokens.
        - `getRewardRate()` (public view): Gets the current reward rate per second per staked token.
        - `setRewardRate(uint256 rate)` (external GOVERNANCE_ROLE): Sets the staking reward rate.
        - `_updateReward(address account)` (internal): Updates reward state before staking/claiming/checking.
        - `_earned(address account)` (internal view): Calculates earned rewards since last update.

    *   **Treasury:**
        - `getTreasuryAddress()` (public view): Gets the treasury address.
        - `getTreasuryBalance()` (public view): Gets treasury balance.
        - `withdrawTreasuryFunds(address recipient, uint256 amount)` (external GOVERNANCE_ROLE): Transfers funds from treasury.
        - `setTreasuryAddress(address newAddress)` (external GOVERNANCE_ROLE): Sets the treasury address.

    *   **Governance:**
        - `proposeParameterChange(string memory paramName, uint256 newValue, uint256 duration)` (public): Creates a proposal (requires min score/balance?). Let's make it GOVERNANCE_ROLE for simplicity in this example, or add proposal criteria later.
        - `voteOnProposal(uint256 proposalId, bool support)` (public): Casts a vote on a proposal (requires min score/balance).
        - `executeProposal(uint256 proposalId)` (public): Executes a successful proposal.
        - `getProposalDetails(uint256 proposalId)` (public view): Gets details of a proposal.
        - `getVoteStatus(uint256 proposalId, address user)` (public view): Gets user's vote status.
        - `setVoteParameters(uint256 minScore, uint256 minTokens, uint256 quorumBP, uint256 majorityBP)` (external GOVERNANCE_ROLE): Sets governance voting thresholds.

    *   **Utilities:**
        - `bulkTransfer(address[] memory recipients, uint256[] memory amounts)` (public): Transfers tokens to multiple addresses.
        - `getBurnedSupply()` (public view): Gets total tokens burned.
        - `getTotalCirculatingSupply()` (public view): Gets total supply minus treasury/burned? No, standard `totalSupply` is sufficient. Let's remove this for simplicity or define it as `totalSupply() - treasuryBalance()`. Let's keep `getBurnedSupply`.

*/


contract QuantumFlowToken is ERC20, AccessControl, Pausable, ReentrancyGuard {

    // --- Roles ---
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // --- Dynamic Fee Parameters (Stored as basis points, 10000 = 100%) ---
    uint256 public transferFeePercentage = 100; // 1%
    uint256 public burnFeePercentage = 5000; // 50% of the fee
    uint256 public treasuryFeePercentage = 5000; // 50% of the fee
    uint256 public minFlowScoreForFeeDiscount = 100; // Minimum *average* score for sender/recipient
    uint256 public entanglementFactorWeight = 1; // Weight for score discount calculation (higher = more impact)

    // --- Flow Score System ---
    mapping(address => uint256) private userFlowScore;
    mapping(address => uint48) private lastActivityTime; // Use uint48 for timestamp efficiency

    // --- Staking System ---
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;
    uint256 public totalStakedSupply;
    uint256 public rewardRate = 0; // Tokens per second per staked token (can be adjusted by governance)
    uint256 private rewardPerTokenStored;
    uint48 private lastUpdateTime; // Use uint48 for timestamp efficiency

    // --- Treasury ---
    address public treasuryAddress;
    uint256 public treasuryBalance; // Tracks QFT held by the contract as treasury

    // --- Governance ---
    uint256 public proposalCounter;
    struct GovernanceProposal {
        string paramName;
        uint256 newValue;
        uint48 endTime; // Use uint48 for timestamp efficiency
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool exists; // To check if proposalId is valid
    }
    mapping(uint256 => GovernanceProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted; // proposalId => voter => voted

    // Governance Parameters
    uint256 public minVoteScore = 50; // Minimum flow score to vote
    uint256 public minVoteTokenBalance = 100 ether; // Minimum token balance to vote
    uint256 public voteQuorumBP = 4000; // 40% of *staked* supply needed for quorum (basis points)
    uint256 public voteMajorityBP = 5000; // 50% + 1 of participating votes needed for majority (basis points)


    // --- Burn Tracking ---
    uint256 private totalBurned;

    // --- Events ---
    event FeeParametersUpdated(uint256 indexed transferFee, uint256 indexed burnFee, uint256 indexed treasuryFee);
    event EntanglementParametersUpdated(uint256 indexed minScoreForDiscount, uint256 indexed factorWeight);
    event FlowScoreUpdated(address indexed user, uint256 newScore);
    event Staked(address indexed user, uint256 amount);
    event WithdrawnStake(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 indexed newRate);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event TreasuryAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ProposalCreated(uint256 indexed proposalId, string paramName, uint256 newValue, uint48 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event GovernanceParametersUpdated(uint256 indexed minScore, uint256 indexed minTokens, uint256 indexed quorum, uint256 indexed majority);
    event BulkTransfer(address indexed sender, address[] recipients, uint256 totalAmount);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address initialTreasuryAddress
    )
        ERC20(name, symbol)
        Pausable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender()); // Admin initially gets Pauser role
        _grantRole(GOVERNANCE_ROLE, _msgSender()); // Admin initially gets Governance role

        _mint(_msgSender(), initialSupply);
        treasuryAddress = initialTreasuryAddress;
        proposalCounter = 0;

        // Initial flow score for the deployer/initial minter
        userFlowScore[_msgSender()] = 10; // Start with a base score
        lastActivityTime[_msgSender()] = uint48(block.timestamp);
    }

    // --- Core Overrides ---

    /// @dev Override _update to apply custom transfer logic (fees, flow score).
    /// This function is called internally by transfer and transferFrom.
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // Calculate fee
        uint256 feeAmount = 0;
        if (transferFeePercentage > 0) {
             uint256 effectiveFeePercentage = _calculateEffectiveFeePercentage(from, to);
             // Use standard percentage calculation; potential for dust remaining below 1 / 10000
             feeAmount = (amount * effectiveFeePercentage) / 10000;
        }

        uint256 amountAfterFee = amount - feeAmount;

        // Update Staking rewards before balance change
        _updateReward(from);
        _updateReward(to);

        // Execute the actual token transfer of the amount *after* fee
        super._transfer(from, to, amountAfterFee);

        // Handle Fee Distribution
        if (feeAmount > 0) {
            uint256 burnAmount = (feeAmount * burnFeePercentage) / 10000;
            uint256 treasuryAmount = feeAmount - burnAmount; // Remaining goes to treasury

            if (burnAmount > 0) {
                // Burn the burn portion
                super._transfer(from, address(0), burnAmount); // Transfer to zero address for burning
                 unchecked {
                    totalBurned += burnAmount;
                }
            }

            if (treasuryAmount > 0) {
                 // Transfer the treasury portion to the treasury address
                 // Note: This increases the *contract's* internal balance for treasury management
                super._transfer(from, address(this), treasuryAmount); // Transfer to self to manage treasury balance
                unchecked {
                    treasuryBalance += treasuryAmount;
                }
            }

            emit Transfer(from, address(0), burnAmount); // Emit transfer event for burn
             if (treasuryAddress != address(0)) {
                emit Transfer(from, address(this), treasuryAmount); // Emit transfer event for treasury
             }
        }

        // Update Flow Score
        _applyFlowScoreUpdate(from, to, amountAfterFee);
    }

    /// @dev Internal function to calculate the effective fee percentage after considering flow score discount.
    /// Fee discount is applied if the *average* flow score of sender and receiver is above minFlowScoreForFeeDiscount.
    /// The discount amount is influenced by the entanglementFactorWeight.
    /// Returns fee in basis points (e.g., 100 for 1%).
    function _calculateEffectiveFeePercentage(address sender, address recipient) internal view returns (uint256) {
        uint256 baseFee = transferFeePercentage;
        if (baseFee == 0) {
            return 0;
        }

        uint256 senderScore = userFlowScore[sender];
        uint256 recipientScore = userFlowScore[recipient];

        // Calculate average score, handle potential division by zero if both scores are zero (though scores start at 0)
        uint256 averageScore = (senderScore + recipientScore);
        if (sender != address(0) && recipient != address(0)) {
             averageScore = averageScore / 2;
        } else if (sender == address(0)) { // Minting
             averageScore = recipientScore;
        } else if (recipient == address(0)) { // Burning
             averageScore = senderScore;
        }


        if (averageScore >= minFlowScoreForFeeDiscount && entanglementFactorWeight > 0) {
            // Calculate potential discount based on how much the average score exceeds the minimum
            // Discount increases with score and entanglement weight
            uint256 scoreExcess = averageScore - minFlowScoreForFeeDiscount;
            // Simple discount calculation: discount = (scoreExcess * entanglementWeight) / some_scaling_factor
            // Scaling factor prevents discount from exceeding the base fee too easily.
            // Let's use a dynamic scaling factor based on the score itself for diminishing returns on score
            // Max possible score impact: Let's assume max score for discount calculation is 10000 (arbitrary cap)
            uint256 effectiveScoreForDiscount = Math.min(scoreExcess, 10000); // Cap the score component for discount calculation
            uint256 potentialDiscountBP = (effectiveScoreForDiscount * entanglementFactorWeight);
             // Apply a division to scale the potential discount
             // A higher divisor means less discount per score point
            uint256 discountBP = potentialDiscountBP / 50; // Example scaling: 50

            // Ensure discount doesn't exceed the base fee percentage
            if (discountBP > baseFee) {
                discountBP = baseFee;
            }
            return baseFee - discountBP;
        } else {
            return baseFee;
        }
    }

    /// @dev Override burn to include pausable check and burn tracking.
    function burn(uint256 amount) public virtual override whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /// @dev Override burnFrom to include pausable check and burn tracking.
    function burnFrom(address account, uint256 amount) public virtual override whenNotPaused {
        _burn(account, amount);
    }

     /// @dev Override _burn to track total burned amount.
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        unchecked {
             totalBurned += amount;
        }
    }

    // --- Dynamic Fee & Parameter Management (GOVERNANCE_ROLE) ---

    /// @dev Sets the base transfer fee percentage in basis points (10000 = 100%).
    /// @param percentage New transfer fee percentage.
    function setTransferFeePercentage(uint256 percentage) external onlyRole(GOVERNANCE_ROLE) {
        require(percentage <= 10000, "Fee percentage cannot exceed 100%");
        require(percentage >= burnFeePercentage + treasuryFeePercentage, "Transfer fee must cover burn and treasury fees");
        transferFeePercentage = percentage;
        emit FeeParametersUpdated(transferFeePercentage, burnFeePercentage, treasuryFeePercentage);
    }

    /// @dev Sets the percentage of the transfer fee that is burned (basis points).
    /// @param percentage New burn fee percentage.
    function setBurnFeePercentage(uint256 percentage) external onlyRole(GOVERNANCE_ROLE) {
        require(percentage <= 10000, "Burn percentage cannot exceed 100%");
        require(percentage + treasuryFeePercentage <= transferFeePercentage, "Burn + Treasury must not exceed Transfer fee");
        burnFeePercentage = percentage;
        emit FeeParametersUpdated(transferFeePercentage, burnFeePercentage, treasuryFeePercentage);
    }

    /// @dev Sets the percentage of the transfer fee that goes to the treasury (basis points).
    /// @param percentage New treasury fee percentage.
    function setTreasuryFeePercentage(uint256 percentage) external onlyRole(GOVERNANCE_ROLE) {
        require(percentage <= 10000, "Treasury percentage cannot exceed 100%");
         require(burnFeePercentage + percentage <= transferFeePercentage, "Burn + Treasury must not exceed Transfer fee");
        treasuryFeePercentage = percentage;
        emit FeeParametersUpdated(transferFeePercentage, burnFeePercentage, treasuryFeePercentage);
    }

    /// @dev Sets the minimum average flow score required for a fee discount (raw score value).
    /// @param score New minimum flow score threshold.
    function setMinFlowScoreForFeeDiscount(uint256 score) external onlyRole(GOVERNANCE_ROLE) {
        minFlowScoreForFeeDiscount = score;
        emit EntanglementParametersUpdated(minFlowScoreForFeeDiscount, entanglementFactorWeight);
    }

     /// @dev Sets the weight applied to the flow score difference when calculating the fee discount.
     /// Higher weight means a greater discount for users with high scores.
     /// @param weight New entanglement factor weight.
    function setEntanglementFactorWeight(uint256 weight) external onlyRole(GOVERNANCE_ROLE) {
        entanglementFactorWeight = weight;
        emit EntanglementParametersUpdated(minFlowScoreForFeeDiscount, entanglementFactorWeight);
    }

    /// @dev Calculates the effective fee amount for a potential transfer considering flow score.
    /// @param sender The sender's address.
    /// @param recipient The recipient's address.
    /// @param amount The amount to be transferred.
    /// @return The calculated fee amount.
    function getEffectiveTransferFee(address sender, address recipient, uint256 amount) public view returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 effectiveFeePercentage = _calculateEffectiveFeePercentage(sender, recipient);
        return (amount * effectiveFeePercentage) / 10000;
    }

    // --- Flow Score & Reputation ---

    /// @dev Gets the current Flow Score for a user.
    /// @param user The address to query.
    /// @return The user's Flow Score.
    function getFlowScore(address user) public view returns (uint256) {
        return userFlowScore[user];
    }

    /// @dev Internal function to update a user's flow score.
    /// Score is based on activity. A simple model: score increases slightly on any transfer activity (send/receive).
    /// A more complex model could weigh by amount, frequency, or partners' scores (entanglement).
    /// This simple implementation just increments slightly per activity and adds a small bonus for value.
    /// @param sender The sender in the transfer.
    /// @param recipient The recipient in the transfer.
    /// @param amount The amount transferred (after fee).
    function _applyFlowScoreUpdate(address sender, address recipient, uint256 amount) internal {
        uint256 scoreIncrease = 1; // Base score increase for any activity

        // Add a bonus based on amount transferred (scaled down significantly)
        // Avoid large amounts causing massive score jumps
        uint256 amountBonus = amount / (10**decimals() * 10); // Example: 1 QFT adds 0.1 bonus points

        if (sender != address(0)) { // Not minting
             // Slightly decrease sender score (cost of doing business?) or just add activity points
             // Let's add activity points to sender, reflecting engagement
             userFlowScore[sender] = userFlowScore[sender] + scoreIncrease + (amountBonus / 2); // Smaller bonus for sender
             lastActivityTime[sender] = uint48(block.timestamp);
             emit FlowScoreUpdated(sender, userFlowScore[sender]);
        }

        if (recipient != address(0)) { // Not burning
            // Increase recipient score more significantly, rewarding receiving
            userFlowScore[recipient] = userFlowScore[recipient] + scoreIncrease + amountBonus; // Larger bonus for receiver
            lastActivityTime[recipient] = uint48(block.timestamp);
            emit FlowScoreUpdated(recipient, userFlowScore[recipient]);
        }
        // Note: This is a very basic score model. Advanced models could include decay, staking bonuses, governance participation, etc.
    }

     /// @dev Gets the last activity timestamp for a user.
     /// Useful for potential future features like activity-based score decay or rewards.
     /// @param user The address to query.
     /// @return The timestamp of the user's last recorded activity.
    function getUserLastActivityTime(address user) public view returns (uint48) {
        return lastActivityTime[user];
    }


    // --- Staking System ---

    /// @dev Helper to update reward state before any staking action.
    /// @param account The account to update rewards for.
    function _updateReward(address account) internal {
        uint256 currentTimestamp = block.timestamp;
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateTime = uint48(currentTimestamp);

        if (account != address(0)) {
            rewards[account] = _earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    /// @dev Calculates the reward per token (staked) based on rate and time.
    /// @return The accumulated reward per token.
    function _rewardPerToken() internal view returns (uint256) {
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        // Ensure rewardRate * timeElapsed does not overflow
        // Using basic multiplication here. For very high rates or long times, consider SafeMath or a different time unit.
        uint256 rewardPerTokenThisPeriod = (rewardRate * timeElapsed * (10**18)) / totalStakedSupply; // Scale by 10^18 for precision
        return rewardPerTokenStored + rewardPerTokenThisPeriod;
    }

    /// @dev Calculates the earned rewards for a user since their last update.
    /// @param account The account to check.
    /// @return The earned rewards for the account.
    function _earned(address account) internal view returns (uint256) {
        uint256 currentUserRewardPerToken = _rewardPerToken();
        uint256 userStake = stakedBalances[account];
        uint256 userPaid = userRewardPerTokenPaid[account];

        // Calculate pending rewards: (userStake * (currentUserRewardPerToken - userPaid)) / 10^18
        uint256 earnedAmount = (userStake * (currentUserRewardPerToken - userPaid)) / (10**18);
        return rewards[account] + earnedAmount;
    }


    /// @dev Allows a user to stake QuantumFlow Tokens.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");

        _updateReward(_msgSender());
        stakedBalances[_msgSender()] += amount;
        totalStakedSupply += amount;

        _transfer(_msgSender(), address(this), amount); // Transfer tokens to the contract

        emit Staked(_msgSender(), amount);
    }

    /// @dev Allows a user to withdraw staked QuantumFlow Tokens.
    /// @param amount The amount of tokens to withdraw.
    function withdrawStake(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalances[_msgSender()] >= amount, "Insufficient staked balance");

        _updateReward(_msgSender());
        stakedBalances[_msgSender()] -= amount;
        totalStakedSupply -= amount;

        _transfer(address(this), _msgSender(), amount); // Transfer tokens back from the contract

        emit WithdrawnStake(_msgSender(), amount);
    }

    /// @dev Allows a user to claim accumulated staking rewards.
    function claimRewards() public nonReentrant {
        _updateReward(_msgSender());
        uint256 rewardAmount = rewards[_msgSender()];
        require(rewardAmount > 0, "No rewards to claim");

        rewards[_msgSender()] = 0; // Reset rewards before transfer

        // Mint or transfer rewards? Let's assume rewards are minted (inflationary) or transferred from treasury.
        // For simplicity, let's mint. This requires MINTER_ROLE. If we don't want inflationary,
        // rewards would need to be funded by the treasury and transferred out.
        // Let's make it transferable from treasury/governance funds.
        // This requires the contract to hold reward tokens.
        // Let's make this function transfer from THIS contract's balance (funded by treasury or minting by admin).
        // This means the contract needs to hold `rewardAmount` tokens.
         require(balanceOf(address(this)) >= rewardAmount, "Insufficient contract balance for rewards. Needs funding.");

        _transfer(address(this), _msgSender(), rewardAmount); // Transfer rewards from contract balance

        emit RewardsClaimed(_msgSender(), rewardAmount);
    }

     /// @dev Sets the staking reward rate per second per token.
     /// This function would typically be called by governance or an admin role after funding the contract.
     /// @param rate New reward rate (tokens per second per token).
     function setRewardRate(uint256 rate) external onlyRole(GOVERNANCE_ROLE) {
        // Before changing rate, update all rewards based on old rate
        // This is computationally expensive for many users. A better model might update rewards lazily on interaction.
        // Let's update for a specific user (the caller) before updating the global rate state.
        // The _updateReward(address(0)) call in _rewardPerToken handles updating the global rewardPerTokenStored state.
        _updateReward(_msgSender()); // Update caller's rewards state based on old rate and elapsed time

        rewardRate = rate;
        lastUpdateTime = uint48(block.timestamp);
        rewardPerTokenStored = _rewardPerToken(); // Update stored reward per token *after* changing rate

        emit RewardRateUpdated(rate);
    }


    /// @dev Calculates pending staking rewards for a user without claiming.
    /// @param user The address to check.
    /// @return The amount of pending rewards.
    function calculateRewards(address user) public view returns (uint256) {
        return _earned(user);
    }

    /// @dev Gets the staked balance for a user.
    /// @param user The address to check.
    /// @return The staked balance.
    function getUserStake(address user) public view returns (uint256) {
        return stakedBalances[user];
    }

    /// @dev Gets the total amount of tokens currently staked in the contract.
    /// @return Total staked supply.
    function getTotalStakedSupply() public view returns (uint256) {
        return totalStakedSupply;
    }

    /// @dev Gets the current staking reward rate.
    /// @return Current reward rate (tokens per second per staked token).
    function getRewardRate() public view returns (uint256) {
        return rewardRate;
    }


    // --- Treasury ---

    /// @dev Gets the address designated as the treasury.
    /// @return The treasury address.
    function getTreasuryAddress() public view returns (address) {
        return treasuryAddress;
    }

     /// @dev Gets the current balance of tokens held by the contract as treasury funds.
     /// @return The treasury balance.
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    /// @dev Allows the GOVERNANCE_ROLE to withdraw funds from the contract's treasury balance.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount to withdraw.
    function withdrawTreasuryFunds(address recipient, uint256 amount) external onlyRole(GOVERNANCE_ROLE) {
        require(recipient != address(0), "Cannot send to zero address");
        require(treasuryBalance >= amount, "Insufficient treasury balance");
        require(balanceOf(address(this)) >= amount, "Insufficient contract token balance"); // Ensure contract holds the tokens

        // Transfer from this contract's balance to the recipient
        super._transfer(address(this), recipient, amount); // Use super to avoid triggering fees on withdrawal

        unchecked {
             treasuryBalance -= amount;
        }

        emit TreasuryWithdrawal(recipient, amount);
    }

     /// @dev Allows the GOVERNANCE_ROLE to set a new treasury address.
     /// This doesn't move existing funds, only designates the target for future fees.
     /// @param newAddress The new address for the treasury.
    function setTreasuryAddress(address newAddress) external onlyRole(GOVERNANCE_ROLE) {
        require(newAddress != address(0), "New treasury address cannot be zero address");
        address oldAddress = treasuryAddress;
        treasuryAddress = newAddress;
        emit TreasuryAddressUpdated(oldAddress, newAddress);
    }


    // --- Governance ---

    /// @dev Allows creation of a proposal to change a contract parameter.
    /// Only GOVERNANCE_ROLE can create proposals in this basic example.
    /// In a real system, this might require token holding or flow score.
    /// @param paramName The name of the parameter to change (e.g., "transferFeePercentage").
    /// @param newValue The new value for the parameter.
    /// @param duration The duration of the voting period in seconds.
    function proposeParameterChange(string memory paramName, uint256 newValue, uint256 duration) external onlyRole(GOVERNANCE_ROLE) {
        require(duration > 0, "Voting duration must be positive");
        proposalCounter++;
        uint256 proposalId = proposalCounter;

        proposals[proposalId] = GovernanceProposal({
            paramName: paramName,
            newValue: newValue,
            endTime: uint48(block.timestamp + duration),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            exists: true
        });

        emit ProposalCreated(proposalId, paramName, newValue, uint48(block.timestamp + duration));
    }

    /// @dev Allows a user to vote on an active proposal.
    /// Requires minimum flow score and token balance.
    /// @param proposalId The ID of the proposal.
    /// @param support True for 'yes', False for 'no'.
    function voteOnProposal(uint256 proposalId, bool support) external {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!hasVoted[proposalId][_msgSender()], "Already voted on this proposal");
        require(userFlowScore[_msgSender()] >= minVoteScore, "Insufficient Flow Score to vote");
        require(balanceOf(_msgSender()) >= minVoteTokenBalance, "Insufficient token balance to vote");

        hasVoted[proposalId][_msgSender()] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, _msgSender(), support);
    }

    /// @dev Allows anyone to execute a proposal after the voting period ends if it passed.
    /// Checks quorum and majority against the *total staked supply* for quorum.
    /// Majority is based on *participating votes* (votesFor + votesAgainst).
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast"); // No point executing if nobody voted

        // Check Quorum: total votes must be at least a percentage of total staked supply
        // Use SafeMath for quorum calculation to avoid overflow if supply is huge (though basis points scale helps)
        // Let's use standard multiplication/division for simplicity assuming reasonable values
        uint256 requiredQuorumVotes = (totalStakedSupply * voteQuorumBP) / 10000;
        require(totalVotes >= requiredQuorumVotes, "Quorum not met");

        // Check Majority: votesFor must be > 50% of total participating votes
        // Using basis points: votesFor must be > (totalVotes * majorityBP) / 10000
        require(proposal.votesFor > (totalVotes * voteMajorityBP) / 10000, "Majority not met");


        // Proposal passes, execute the parameter change
        proposal.executed = true;
        bool success = false;

        // Note: Using a simple string matching here is not ideal for production as it's error-prone.
        // A better approach would be a struct with enum for param type and value or a proposal handler contract.
        // For this example, we use strings.
        if (keccak256(bytes(proposal.paramName)) == keccak256("transferFeePercentage")) {
             setTransferFeePercentage(proposal.newValue); // Call the setter function
             success = true;
        } else if (keccak256(bytes(proposal.paramName)) == keccak256("burnFeePercentage")) {
             setBurnFeePercentage(proposal.newValue);
             success = true;
        } else if (keccak256(bytes(proposal.paramName)) == keccak256("treasuryFeePercentage")) {
             setTreasuryFeePercentage(proposal.newValue);
             success = true;
        } else if (keccak256(bytes(proposal.paramName)) == keccak256("minFlowScoreForFeeDiscount")) {
             setMinFlowScoreForFeeDiscount(proposal.newValue);
             success = true;
        } else if (keccak256(bytes(proposal.paramName)) == keccak256("entanglementFactorWeight")) {
             setEntanglementFactorWeight(proposal.newValue);
             success = true;
        } else if (keccak256(bytes(proposal.paramName)) == keccak256("rewardRate")) {
             setRewardRate(proposal.newValue);
             success = true;
        }
         // Add more parameter checks here as needed...

        emit ProposalExecuted(proposalId, success);
        // Revert if execution failed for a valid parameter name? Or just emit success=false?
        // Let's just emit success=false and leave the state unchanged if the paramName didn't match or setter failed internally.
    }

    /// @dev Gets the details of a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The proposal struct details.
    function getProposalDetails(uint256 proposalId) public view returns (GovernanceProposal memory) {
        return proposals[proposalId];
    }

    /// @dev Checks if a user has voted on a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @param user The address to check.
    /// @return True if the user has voted, false otherwise.
    function getVoteStatus(uint256 proposalId, address user) public view returns (bool) {
        return hasVoted[proposalId][user];
    }

     /// @dev Allows the GOVERNANCE_ROLE to update parameters controlling voting eligibility and thresholds.
     /// @param minScore Minimum flow score to vote.
     /// @param minTokens Minimum token balance to vote.
     /// @param quorumBP Quorum percentage (basis points).
     /// @param majorityBP Majority percentage (basis points).
    function setVoteParameters(uint256 minScore, uint256 minTokens, uint256 quorumBP, uint256 majorityBP) external onlyRole(GOVERNANCE_ROLE) {
        require(quorumBP <= 10000, "Quorum cannot exceed 100%");
        require(majorityBP <= 10000, "Majority cannot exceed 100%");
        minVoteScore = minScore;
        minVoteTokenBalance = minTokens;
        voteQuorumBP = quorumBP;
        voteMajorityBP = majorityBP;
        emit GovernanceParametersUpdated(minVoteScore, minVoteTokenBalance, voteQuorumBP, voteMajorityBP);
    }


    // --- Utilities ---

    /// @dev Allows sending tokens to multiple recipients in a single transaction.
    /// Applies fees and updates flow scores for each transfer.
    /// @param recipients Array of recipient addresses.
    /// @param amounts Array of amounts corresponding to recipients.
    function bulkTransfer(address[] memory recipients, uint256[] memory amounts) public whenNotPaused {
        require(recipients.length == amounts.length, "Recipients and amounts array length mismatch");
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(balanceOf(_msgSender()) >= totalAmount, "Insufficient balance for bulk transfer");

        for (uint i = 0; i < recipients.length; i++) {
            // _transfer handles fees, pausable, and flow score updates for each recipient
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }

        emit BulkTransfer(_msgSender(), recipients, totalAmount);
    }

     /// @dev Gets the total amount of tokens that have been burned.
     /// @return The total burned supply.
    function getBurnedSupply() public view returns (uint256) {
        return totalBurned;
    }

    // The following functions are inherited from ERC20, AccessControl, Pausable and provide standard functionality:
    // name(), symbol(), decimals(), totalSupply(), balanceOf(account), transfer(recipient, amount), allowance(owner, spender), approve(spender, amount), transferFrom(sender, recipient, amount)
    // hasRole(role, account), getRoleAdmin(role), grantRole(role, account), revokeRole(role, account), renounceRole(role, account)
    // paused()

}

// Simple Math library if needed for older Solidity or complex ops, not strictly necessary in 0.8+ for basic uint ops
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
     function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```