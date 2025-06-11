Okay, here is a Solidity smart contract called `QuantumFundManager`. This contract introduces concepts like probabilistic yield boosts (simulating 'quantum fluctuations' on market outcomes), dynamic strategy parameters influenced by governance voting, time-based epochs, and a yield-share mechanism for accurate accounting.

It's *not* a direct copy of standard open-source contracts like ERC20 or basic staking pools, though it uses common patterns like Ownable and Pausable. The combination of probabilistic yield, dynamic parameters via on-chain voting, and epoch-based distribution in a single fund management context provides a unique blend.

**Disclaimer:** The "Quantum Fluctuation" randomness here is simulated using simple methods (`block.timestamp`, `block.difficulty`). **This is NOT suitable for production environments where secure, unpredictable randomness is required.** For production, you would need a service like Chainlink VRF. This contract is for educational and conceptual demonstration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- QuantumFundManager Contract Outline ---
// 1. State Variables: Define contract's persistent data (owner, token, pools, parameters, epochs, governance).
// 2. Events: Define events emitted for transparency and off-chain tracking.
// 3. Modifiers: Define custom modifiers (e.g., for specific roles).
// 4. Constructor: Initialize contract state.
// 5. Pausability: Implement pause/unpause functionality.
// 6. Fund Management & Staking:
//    - Core deposit, withdrawal, staking functions.
//    - Yield calculation and distribution logic (epoch-based, yield-share).
//    - Probabilistic "Quantum Fluctuation" yield boost mechanism.
//    - Early withdrawal penalties.
// 7. Epoch Advancement: Function to manually trigger epoch transition and yield distribution.
// 8. Parameter Management: Functions for owner/manager to set core parameters.
// 9. Governance-Lite:
//    - Proposal creation for parameter changes.
//    - Voting on proposals.
//    - Execution of successful proposals.
// 10. Utility & View Functions: Functions to query contract state (user info, pool info, proposal state).
// 11. Emergency Functions: Owner functions for crisis scenarios (e.g., stuck tokens).
// 12. Internal Helpers: Private functions for complex logic (yield calculation, fluctuation).

// --- QuantumFundManager Function Summary ---
// 1. constructor(IERC20 _quantumToken, uint256 _epochDuration, uint256 _baseYieldRatePerEpoch, uint256 _fluctuationMagnitude, uint256 _fluctuationProbability, uint256 _performanceFeeRate, uint256 _withdrawalFeeRate, uint256 _minStakeAmount): Initializes contract with token and parameters.
// 2. pause(): Owner function to pause contract operations.
// 3. unpause(): Owner function to unpause contract operations.
// 4. updateFundManager(address _newManager): Owner function to set or change the fund manager address.
// 5. stake(uint256 _amount): Allows a user to stake tokens into the fund.
// 6. unstake(uint256 _amount): Allows a user to request unstaking (initiates potential cooldown/lock). Note: actual withdrawal is separate.
// 7. claimYield(): Allows a user to claim their accrued yield.
// 8. withdrawPrincipal(): Allows a user to withdraw their principal after lock/cooldown period.
// 9. withdrawPrincipalEarly(): Allows a user to withdraw principal before the lock period ends, incurring a fee.
// 10. advanceEpoch(): Fund manager or permitted address triggers the end of an epoch, yield calculation, fluctuation, and distribution.
// 11. setBaseYieldRate(uint256 _rate): Manager sets the base yield rate per epoch.
// 12. setFluctuationParameters(uint256 _magnitude, uint256 _probability): Manager sets quantum fluctuation parameters.
// 13. setPerformanceFeeRate(uint256 _rate): Manager sets the performance fee rate on yield.
// 14. setWithdrawalFeeRate(uint256 _rate): Manager sets the early withdrawal fee rate on principal.
// 15. setEpochDuration(uint256 _duration): Manager sets the duration of an epoch.
// 16. setMinStakeAmount(uint256 _amount): Manager sets the minimum stake amount required.
// 17. proposeParameterChange(string memory _paramName, uint256 _newValue): Allows authorized users to propose a change to a configurable parameter.
// 18. voteOnProposal(uint256 _proposalId, bool _support): Allows stakers to vote on an active proposal.
// 19. executeProposal(uint256 _proposalId): Executes a proposal if the voting period is over and it passed the threshold.
// 20. getProposalState(uint256 _proposalId): View function to check the current state of a proposal.
// 21. delegateVote(address _delegatee): Allows a staker to delegate their voting power.
// 22. emergencyWithdrawStuckTokens(address _tokenAddress): Owner can withdraw tokens accidentally sent to the contract (excluding the fund token).
// 23. getUserStake(address _user): View user's current staked amount.
// 24. getPendingYield(address _user): View user's pending yield amount.
// 25. getTotalStaked(): View total amount staked in the fund.
// 26. getCurrentEpochInfo(): View current epoch number and start time.
// 27. getEpochYieldAmount(uint256 _epoch): View the total yield calculated for a specific past epoch.
// 28. getParameter(string memory _paramName): View the current value of a configurable parameter.
// 29. isPremiumStaker(address _user): View if a user qualifies as a premium staker (e.g., based on stake amount, simplified).
// 30. getUserLockUntilEpoch(address _user): View the epoch until which a user's principal is locked without early withdrawal fee.

contract QuantumFundManager is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable quantumToken;
    address public fundManager;

    // Staking and Yield
    mapping(address => uint256) public userStakes;
    uint256 public totalStaked;

    // Yield Share Mechanism: tracks yield per unit of stake over time
    uint256 public totalYieldShares; // Total accumulated yield per unit of stake (scaled)
    mapping(address => uint256) public userLastYieldShares; // Last yield share value seen by user

    // Epochs
    uint256 public currentEpoch;
    uint256 public epochDuration;
    uint256 public lastEpochStartTime;
    mapping(uint256 => uint256) public epochYieldAmounts; // Total yield calculated for each epoch

    // Parameters (can be changed via governance)
    uint256 public baseYieldRatePerEpoch; // Yield percentage per epoch (e.g., 100 = 1%)
    uint256 public fluctuationMagnitude; // Max percentage boost/reduction from fluctuation (e.g., 500 = 5%)
    uint256 public fluctuationProbability; // Probability of fluctuation (e.g., 3000 = 30%) - scaled to 10000

    uint256 public performanceFeeRate; // Fee on earned yield (e.g., 1000 = 10%)
    uint256 public withdrawalFeeRate; // Fee on early principal withdrawal (e.g., 500 = 5%)
    uint256 public minStakeAmount; // Minimum required stake amount

    // Withdrawal Lock
    mapping(address => uint256) public userLockUntilEpoch; // Epoch until which principal is locked

    // Governance-Lite
    struct Proposal {
        string paramName;
        uint256 newValue;
        uint256 startTime;
        uint256 votingPeriod; // Duration of voting
        uint256 supportVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) voted; // Keep track of who voted
    }

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalThreshold; // Minimum support votes needed to pass
    uint256 public proposalVotingPeriod; // Default voting period

    mapping(address => address) public voteDelegates; // User => delegatee address

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newStake);
    event Unstaked(address indexed user, uint256 amount, uint256 newStake); // unstake request
    event PrincipalWithdrawn(address indexed user, uint256 amount);
    event PrincipalWithdrawnEarly(address indexed user, uint256 amount, uint256 feePaid);
    event YieldClaimed(address indexed user, uint256 amount);
    event EpochAdvanced(uint256 indexed epoch, uint256 yieldGenerated, int256 fluctuationApplied);
    event ParameterChanged(string paramName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event FundManagerUpdated(address indexed oldManager, address indexed newManager);
    event EmergencyTokensWithdrawn(address indexed tokenAddress, uint256 amount);

    // --- Modifiers ---

    modifier onlyFundManagerOrOwner() {
        require(msg.sender == owner() || msg.sender == fundManager, "Not owner or fund manager");
        _;
    }

    // --- Constructor ---

    constructor(
        IERC20 _quantumToken,
        uint256 _epochDuration,
        uint256 _baseYieldRatePerEpoch,
        uint256 _fluctuationMagnitude,
        uint256 _fluctuationProbability,
        uint256 _performanceFeeRate,
        uint256 _withdrawalFeeRate,
        uint256 _minStakeAmount,
        uint256 _proposalThreshold,
        uint256 _proposalVotingPeriod
    ) Ownable(msg.sender) Pausable(false) {
        require(address(_quantumToken) != address(0), "Invalid token address");
        require(_epochDuration > 0, "Epoch duration must be > 0");
        require(_baseYieldRatePerEpoch <= 10000, "Base yield rate invalid"); // Max 100%
        require(_fluctuationMagnitude <= 10000, "Fluctuation magnitude invalid"); // Max 100%
        require(_fluctuationProbability <= 10000, "Fluctuation probability invalid"); // Max 100%
        require(_performanceFeeRate <= 10000, "Performance fee rate invalid"); // Max 100%
        require(_withdrawalFeeRate <= 10000, "Withdrawal fee rate invalid"); // Max 100%
        require(_proposalThreshold > 0, "Proposal threshold must be > 0");
        require(_proposalVotingPeriod > 0, "Proposal voting period must be > 0");

        quantumToken = _quantumToken;
        fundManager = msg.sender; // Initially owner is fund manager

        epochDuration = _epochDuration;
        lastEpochStartTime = block.timestamp;
        currentEpoch = 1;

        baseYieldRatePerEpoch = _baseYieldRatePerEpoch;
        fluctuationMagnitude = _fluctuationMagnitude;
        fluctuationProbability = _fluctuationProbability;
        performanceFeeRate = _performanceFeeRate;
        withdrawalFeeRate = _withdrawalFeeRate;
        minStakeAmount = _minStakeAmount;

        proposalThreshold = _proposalThreshold;
        proposalVotingPeriod = _proposalVotingPeriod;
    }

    // --- Pausability ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Fund Management & Staking ---

    function updateFundManager(address _newManager) public onlyOwner {
        require(_newManager != address(0), "Invalid address");
        emit FundManagerUpdated(fundManager, _newManager);
        fundManager = _newManager;
    }

    function stake(uint256 _amount) public payable whenNotPaused nonReentrant {
        require(_amount >= minStakeAmount, "Stake amount too low");
        require(quantumToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Update yield share tracking before staking new amount
        _updateUserYieldShares(msg.sender);

        userStakes[msg.sender] = userStakes[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);

        // Set or extend lock period (example: lock for 3 epochs from current)
        userLockUntilEpoch[msg.sender] = currentEpoch + 3;

        emit Staked(msg.sender, _amount, userStakes[msg.sender]);
    }

    function unstake(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        require(userStakes[msg.sender] >= _amount, "Insufficient stake");

        // Claim any pending yield first
        claimYield();

        // Reduce stake immediately
        userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        // Note: Actual withdrawal happens via withdrawPrincipal functions

        emit Unstaked(msg.sender, _amount, userStakes[msg.sender]);
    }

    function claimYield() public whenNotPaused nonReentrant {
        uint256 pendingYield = getPendingYield(msg.sender);

        if (pendingYield > 0) {
            // Update yield share tracking and calculate earned amount
            _updateUserYieldShares(msg.sender);

            // Apply performance fee
            uint256 fee = pendingYield.mul(performanceFeeRate).div(10000);
            uint256 yieldToTransfer = pendingYield.sub(fee);

            require(quantumToken.transfer(msg.sender, yieldToTransfer), "Yield transfer failed");

            // Note: Fee could be transferred to owner/manager or burned,
            // currently it just reduces the amount transferred to user.
            // You might want to add a separate fee pool.

            emit YieldClaimed(msg.sender, yieldToTransfer);
        }
    }

    function withdrawPrincipal() public whenNotPaused nonReentrant {
        require(userStakes[msg.sender] > 0, "No principal to withdraw");
        require(currentEpoch >= userLockUntilEpoch[msg.sender], "Principal is still locked");

        uint256 amount = userStakes[msg.sender];

        // Claim any pending yield first
        claimYield();

        // Reset stake and update total
        userStakes[msg.sender] = 0;
        totalStaked = totalStaked.sub(amount); // SafeMath already checked in unstake logic if used first, but good practice

        require(quantumToken.transfer(msg.sender, amount), "Principal transfer failed");

        emit PrincipalWithdrawn(msg.sender, amount);
    }

    function withdrawPrincipalEarly() public whenNotPaused nonReentrant {
         require(userStakes[msg.sender] > 0, "No principal to withdraw");
         require(currentEpoch < userLockUntilEpoch[msg.sender], "Principal is not locked (use withdrawPrincipal)");

         uint256 amount = userStakes[msg.sender];
         uint256 fee = amount.mul(withdrawalFeeRate).div(10000);
         uint256 amountToTransfer = amount.sub(fee);

         // Claim any pending yield first
         claimYield();

         // Reset stake and update total
         userStakes[msg.sender] = 0;
         totalStaked = totalStaked.sub(amount);

         require(quantumToken.transfer(msg.sender, amountToTransfer), "Early principal transfer failed");

         // Note: Fee could be transferred to owner/manager or burned
         // currently it just reduces the amount transferred to user.

         emit PrincipalWithdrawnEarly(msg.sender, amountToTransfer, fee);
    }

    // --- Epoch Advancement & Yield Calculation ---

    function advanceEpoch() public onlyFundManagerOrOwner whenNotPaused nonReentrant {
        require(block.timestamp >= lastEpochStartTime + epochDuration, "Epoch duration not passed yet");
        require(totalStaked > 0, "Cannot advance epoch with no total staked");

        // Calculate yield for the epoch
        uint256 baseYield = totalStaked.mul(baseYieldRatePerEpoch).div(10000);
        int256 fluctuation = _applyQuantumFluctuation(baseYield);
        uint256 actualEpochYield = baseYield.add(fluctuation); // Handle potential negative fluctuation if needed, or clamp at 0

        if (actualEpochYield > 0) {
             // Distribute yield shares
             uint256 yieldSharesToAdd = actualEpochYield.mul(1e18).div(totalStaked); // Scale yield shares
             totalYieldShares = totalYieldShares.add(yieldSharesToAdd);
        }

        // Store yield for historical lookup
        epochYieldAmounts[currentEpoch] = actualEpochYield;

        lastEpochStartTime = block.timestamp;
        currentEpoch = currentEpoch.add(1);

        emit EpochAdvanced(currentEpoch - 1, actualEpochYield, fluctuation);
    }

    // Internal helper to update a user's yield shares
    function _updateUserYieldShares(address _user) internal {
        if (userStakes[_user] > 0) {
            uint256 accrued = (totalYieldShares.sub(userLastYieldShares[_user])).mul(userStakes[_user]).div(1e18);
            // Note: accrued yield is implicit in the difference between current and last yield shares.
            // We just need to update the user's last share point.
            userLastYieldShares[_user] = totalYieldShares;
        } else {
             // If user has no stake, just update their last share point to current
             userLastYieldShares[_user] = totalYieldShares;
        }
    }

    // Internal helper to apply quantum fluctuation (simulated)
    // Returns the amount of yield increase/decrease
    function _applyQuantumFluctuation(uint256 _baseYield) internal view returns (int256) {
        // Simple simulated randomness. NOT secure for production.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, totalStaked, msg.sender))) % 10000;

        if (randomness < fluctuationProbability) {
            // Fluctuation occurs
            uint256 fluctuationAmount = _baseYield.mul(fluctuationMagnitude).div(10000);

            // Another simple random element to make it positive or negative (50/50 chance)
            uint256 signRandomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.gaslimit, msg.sender))) % 2;

            if (signRandomness == 0) {
                 // Negative fluctuation (yield reduction)
                 return - int256(fluctuationAmount);
            } else {
                 // Positive fluctuation (yield boost)
                 return int256(fluctuationAmount);
            }
        }
        return 0; // No fluctuation
    }

    // --- Parameter Management (Manager Setters) ---

    function setBaseYieldRate(uint256 _rate) public onlyFundManagerOrOwner {
        require(_rate <= 10000, "Rate invalid");
        baseYieldRatePerEpoch = _rate;
        emit ParameterChanged("baseYieldRatePerEpoch", _rate);
    }

    function setFluctuationParameters(uint256 _magnitude, uint256 _probability) public onlyFundManagerOrOwner {
        require(_magnitude <= 10000, "Magnitude invalid");
        require(_probability <= 10000, "Probability invalid");
        fluctuationMagnitude = _magnitude;
        fluctuationProbability = _probability;
        emit ParameterChanged("fluctuationMagnitude", _magnitude);
        emit ParameterChanged("fluctuationProbability", _probability);
    }

    function setPerformanceFeeRate(uint256 _rate) public onlyFundManagerOrOwner {
         require(_rate <= 10000, "Rate invalid");
         performanceFeeRate = _rate;
         emit ParameterChanged("performanceFeeRate", _rate);
    }

    function setWithdrawalFeeRate(uint256 _rate) public onlyFundManagerOrOwner {
         require(_rate <= 10000, "Rate invalid");
         withdrawalFeeRate = _rate;
         emit ParameterChanged("withdrawalFeeRate", _rate);
    }

    function setEpochDuration(uint256 _duration) public onlyFundManagerOrOwner {
         require(_duration > 0, "Duration must be > 0");
         epochDuration = _duration;
         emit ParameterChanged("epochDuration", _duration);
    }

    function setMinStakeAmount(uint256 _amount) public onlyFundManagerOrOwner {
         minStakeAmount = _amount;
         emit ParameterChanged("minStakeAmount", _amount);
    }

    // --- Governance-Lite ---

    function proposeParameterChange(string memory _paramName, uint256 _newValue) public whenNotPaused {
        // Basic check: Only allow proposal for known parameters
        bytes32 paramHash = keccak256(bytes(_paramName));
        bool isValidParam = false;
        if (paramHash == keccak256("baseYieldRatePerEpoch") ||
            paramHash == keccak256("fluctuationMagnitude") ||
            paramHash == keccak256("fluctuationProbability") ||
            paramHash == keccak256("performanceFeeRate") ||
            paramHash == keccak256("withdrawalFeeRate") ||
            paramHash == keccak256("epochDuration") ||
            paramHash == keccak256("minStakeAmount")) {
                isValidParam = true;
        }
        require(isValidParam, "Invalid parameter name for proposal");

        proposalCounter = proposalCounter.add(1);
        uint256 proposalId = proposalCounter;

        proposals[proposalId] = Proposal({
            paramName: _paramName,
            newValue: _newValue,
            startTime: block.timestamp,
            votingPeriod: proposalVotingPeriod,
            supportVotes: 0,
            againstVotes: 0,
            executed: false,
            voted: new mapping(address => bool) // Initialize the nested mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _paramName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(bytes(proposal.paramName).length > 0, "Proposal does not exist"); // Check if proposal exists
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp < proposal.startTime + proposal.votingPeriod, "Voting period has ended");

        // Determine actual voter (self or delegatee)
        address voter = voteDelegates[msg.sender] == address(0) ? msg.sender : voteDelegates[msg.sender];

        require(!proposal.voted[voter], "Already voted on this proposal");
        // Require voter has *some* stake at time of voting (could make more complex: snapshot stake at proposal start)
        require(userStakes[voter] > 0, "Must have stake to vote");

        if (_support) {
            proposal.supportVotes = proposal.supportVotes.add(userStakes[voter]); // Vote weight based on stake
        } else {
            proposal.againstVotes = proposal.againstVotes.add(userStakes[voter]); // Vote weight based on stake
        }
        proposal.voted[voter] = true;

        emit Voted(_proposalId, voter, _support);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(bytes(proposal.paramName).length > 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.startTime + proposal.votingPeriod, "Voting period not ended");

        bool passed = proposal.supportVotes >= proposalThreshold && proposal.supportVotes > proposal.againstVotes;

        if (passed) {
            // Execute the parameter change based on paramName
            bytes32 paramHash = keccak256(bytes(proposal.paramName));
            uint256 newValue = proposal.newValue;

            if (paramHash == keccak256("baseYieldRatePerEpoch")) {
                require(newValue <= 10000, "Invalid new rate");
                baseYieldRatePerEpoch = newValue;
            } else if (paramHash == keccak256("fluctuationMagnitude")) {
                 require(newValue <= 10000, "Invalid new magnitude");
                 fluctuationMagnitude = newValue;
            } else if (paramHash == keccak256("fluctuationProbability")) {
                 require(newValue <= 10000, "Invalid new probability");
                 fluctuationProbability = newValue;
            } else if (paramHash == keccak256("performanceFeeRate")) {
                 require(newValue <= 10000, "Invalid new rate");
                 performanceFeeRate = newValue;
            } else if (paramHash == keccak256("withdrawalFeeRate")) {
                 require(newValue <= 10000, "Invalid new rate");
                 withdrawalFeeRate = newValue;
            } else if (paramHash == keccak256("epochDuration")) {
                 require(newValue > 0, "Invalid new duration");
                 epochDuration = newValue;
            } else if (paramHash == keccak256("minStakeAmount")) {
                 minStakeAmount = newValue;
            } else {
                 // Should not happen if proposeParameterChange validates names
                 revert("Unknown parameter");
            }

            emit ParameterChanged(proposal.paramName, newValue);
        }

        proposal.executed = true; // Mark as executed regardless of pass/fail
        emit ProposalExecuted(_proposalId, passed);
    }

    // Proposal State: 0: Pending, 1: Active, 2: Defeated, 3: Succeeded, 4: Executed
    function getProposalState(uint256 _proposalId) public view returns (uint8) {
        Proposal storage proposal = proposals[_proposalId];
         if (bytes(proposal.paramName).length == 0) return 0; // Not found/Pending

        if (proposal.executed) return 4;

        if (block.timestamp < proposal.startTime + proposal.votingPeriod) return 1; // Active

        // Voting period ended
        if (proposal.supportVotes >= proposalThreshold && proposal.supportVotes > proposal.againstVotes) return 3; // Succeeded
        return 2; // Defeated
    }

    function delegateVote(address _delegatee) public {
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        voteDelegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    // --- Utility & View Functions ---

    function getPendingYield(address _user) public view returns (uint256) {
        if (userStakes[_user] == 0) {
            return 0;
        }
        // Calculate yield based on the difference between current total shares and user's last recorded shares
        uint256 accumulatedShares = totalYieldShares.sub(userLastYieldShares[_user]);
        return accumulatedShares.mul(userStakes[_user]).div(1e18); // Scale back down
    }

    function getUserStake(address _user) public view returns (uint256) {
        return userStakes[_user];
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function getCurrentEpochInfo() public view returns (uint256 epoch, uint256 startTime, uint256 duration, uint256 nextEpochStart) {
        return (currentEpoch, lastEpochStartTime, epochDuration, lastEpochStartTime + epochDuration);
    }

    function getEpochYieldAmount(uint256 _epoch) public view returns (uint256) {
        return epochYieldAmounts[_epoch];
    }

    function getParameter(string memory _paramName) public view returns (uint256) {
         bytes32 paramHash = keccak256(bytes(_paramName));
         if (paramHash == keccak256("baseYieldRatePerEpoch")) return baseYieldRatePerEpoch;
         if (paramHash == keccak256("fluctuationMagnitude")) return fluctuationMagnitude;
         if (paramHash == keccak256("fluctuationProbability")) return fluctuationProbability;
         if (paramHash == keccak256("performanceFeeRate")) return performanceFeeRate;
         if (paramHash == keccak256("withdrawalFeeRate")) return withdrawalFeeRate;
         if (paramHash == keccak256("epochDuration")) return epochDuration;
         if (paramHash == keccak256("minStakeAmount")) return minStakeAmount;
         revert("Unknown parameter");
    }

    function isPremiumStaker(address _user) public view returns (bool) {
        // Example: Premium if stake is > 10x min stake
        return userStakes[_user] >= minStakeAmount.mul(10);
    }

     function getUserLockUntilEpoch(address _user) public view returns (uint256) {
        return userLockUntilEpoch[_user];
    }


    // --- Emergency Functions ---

    function emergencyWithdrawStuckTokens(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(quantumToken), "Cannot withdraw the main fund token this way");
        IERC20 stuckToken = IERC20(_tokenAddress);
        uint256 balance = stuckToken.balanceOf(address(this));
        require(balance > 0, "No stuck tokens of this type");
        require(stuckToken.transfer(owner(), balance), "Emergency token transfer failed");
        emit EmergencyTokensWithdrawn(_tokenAddress, balance);
    }

    // Fallback/Receive to prevent accidental ether sends (unless payable is needed elsewhere)
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
         revert("Invalid function call");
    }
}
```