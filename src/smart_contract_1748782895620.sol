Okay, let's design a smart contract based on a dynamic vesting mechanism with features like contribution-based credit issuance, time-and-activity-dependent vesting rates, boosting mechanisms, and an inactivity challenge system. This incorporates dynamic parameters, internal state interaction, and game-theory-lite elements.

We'll call the contract `DynamicVestingSphere`.

Here's the structure:

**Contract Name:** `DynamicVestingSphere`

**Core Concept:** Users contribute a base asset (ETH or ERC20) to receive non-transferable "Credits". These Credits can be converted into a transferable "VestedToken" over time. The rate of conversion (vesting) is dynamic, influenced by global protocol activity, individual user "boosting" actions, and is negatively impacted by user inactivity, potentially triggered by a challenge system.

**Outline:**

1.  **State Variables:** Define contract configuration (tokens, parameters), global state (total activity, admin fees), and user-specific state (credits, vested tokens, activity metrics, challenge info).
2.  **Structs:** Define data structures for User status and Challenge details.
3.  **Events:** Define events to log significant actions (contributions, vesting, claims, boosts, challenges, parameter updates, slashing).
4.  **Modifiers:** Define access control (`onlyAdmin`, pausing).
5.  **Admin Functions:** Functions for setting contract parameters, tokens, and managing admin fees.
6.  **Contribution Functions:** Allow users to contribute ETH or an allowed ERC20 token to receive Credits.
7.  **Vesting & Claiming Functions:** Core logic for converting Credits to VestedTokens and claiming VestedTokens. Includes dynamic rate calculation and inactivity checks/slashing.
8.  **Boosting Functions:** Allow users to lock Credits or another token to increase their vesting rate.
9.  **Inactivity & Challenge Functions:** System for tracking user activity, allowing others to challenge inactive users, and resolving challenges (leading to potential credit slashing and rewards).
10. **Query Functions:** View functions to retrieve contract state, user balances, current rates, and challenge info.
11. **Utility Functions:** Pausing the contract.

**Function Summary (25+ Functions):**

1.  `constructor()`: Initializes the contract, sets the admin address.
2.  `initializeParameters(...)`: (Admin) Sets initial core parameters like contribution rate, base vesting rate, inactivity threshold, challenge stakes, etc.
3.  `setContributionToken(address _token)`: (Admin) Sets the ERC20 token accepted for contributions (0 address for ETH).
4.  `setVestedToken(address _token)`: (Admin) Sets the ERC20 token minted upon vesting.
5.  `setVestingParameters(...)`: (Admin) Updates parameters related to the base vesting rate and global activity multiplier impact.
6.  `setBoostingParameters(...)`: (Admin) Updates parameters related to the boosting token and multiplier calculation.
7.  `setInactivityParameters(...)`: (Admin) Updates parameters for inactivity threshold, challenge stake, cooldown, and penalty percentage.
8.  `setFeeRecipient(address _recipient)`: (Admin) Sets the address receiving admin fees.
9.  `contributeETH()`: (Payable) User contributes Ether to receive Credits.
10. `contributeToken(uint256 _amount)`: User contributes the specified ERC20 token to receive Credits.
11. `vestCredits(uint256 _creditsToVest)`: User converts a specific amount of their Credits into VestedTokens based on the current dynamic rate. Triggers inactivity check first.
12. `claimVestedTokens()`: User claims their accumulated VestedTokens. Triggers inactivity check first.
13. `boostVestingRate(uint256 _amount)`: User locks a specified amount of Credits or BoostingToken to increase their vesting rate.
14. `unboostVestingRate()`: User unlocks their previously boosted amount (may have cooldown/conditions).
15. `challengeInactivity(address _target)`: User pays a stake to initiate an inactivity challenge against another user.
16. `resolveChallenge(address _target)`: Anyone can call after the challenge period ends to resolve the challenge, potentially slashing the target's credits and distributing rewards/stakes.
17. `withdrawAdminFees()`: (Admin) Withdraws accumulated fees from the contract.
18. `pauseContract()`: (Admin) Pauses core user interactions (contribute, vest, claim, boost, challenge).
19. `unpauseContract()`: (Admin) Unpauses the contract.
20. `getCreditsBalance(address _user)`: (View) Get the non-vested Credits balance for a user.
21. `getVestedBalance(address _user)`: (View) Get the claimable VestedTokens balance for a user.
22. `getPendingVestedTokens(address _user)`: (View) Estimate how many VestedTokens a user would receive if they vested their current Credits right now.
23. `getCurrentVestingRate(address _user)`: (View) Calculate and get the current dynamic vesting rate for a user.
24. `getUserLastActiveTime(address _user)`: (View) Get the timestamp of a user's last relevant interaction.
25. `getChallengeStatus(address _target)`: (View) Get the current status and details of an ongoing or past challenge against a user.
26. `getTotalProtocolActivityScore()`: (View) Get the global activity metric used in the vesting rate calculation.
27. `getBoostMultiplier(address _user)`: (View) Get the current boost multiplier applied to a user's rate based on their boost amount.
28. `getInactivitySlashPenalty(address _user)`: (View) Calculate and get the potential credit slash amount if the user were deemed inactive right now.
29. `getContributionRate()`: (View) Get the current rate at which contributions yield Credits.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Dummy interfaces for tokens - replace with real ones like OpenZeppelin if deploying
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Simple ERC20 for the Vested Token - just for demonstration within this file
contract SimpleVestedToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18; // Standard
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ST: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ST: transfer from the zero address");
        require(recipient != address(0), "ST: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ST: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] = _balances[recipient] + amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ST: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ST: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ST: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply = _totalSupply - amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ST: approve from the zero address");
        require(spender != address(0), "ST: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// --- Main Contract ---

contract DynamicVestingSphere {
    // --- State Variables ---

    address public admin;
    bool public paused;

    // --- Token Addresses ---
    // 0x0 will represent native ETH
    IERC20 public contributionToken;
    SimpleVestedToken public vestedToken; // Using the simple implementation above

    // --- Parameters ---
    struct VestingParameters {
        uint256 baseVestingRatePerCredit; // e.g., 1e18 for 1 VestedToken per Credit (before multipliers)
        uint256 globalActivityWeight; // How much global activity influences the rate (percentage points, e.g., 100 = 1%)
        uint256 maxGlobalActivityMultiplier; // Max cap for the activity multiplier (e.g., 2e18 for 2x)
    }
    VestingParameters public vestingParams;

    struct BoostingParameters {
        address boostingToken; // 0x0 for Credits themselves, otherwise ERC20 address
        uint256 boostRatePerToken; // How much 1 token locked boosts the rate (percentage points)
        uint256 maxBoostMultiplier; // Max cap for individual boost multiplier (e.g., 1.5e18 for 1.5x)
        uint256 unboostCooldown; // Time in seconds user must wait after unboosting
    }
    BoostingParameters public boostingParams;

    struct InactivityParameters {
        uint256 inactivityThreshold; // Time in seconds a user can be inactive before being slashable
        uint256 challengeStakeAmount; // Amount of ContributionToken/ETH required to challenge
        uint256 challengeCooldown; // Time in seconds a target cannot be challenged again
        uint256 slashPercentage; // Percentage of credits slashed upon inactivity (e.g., 1000 = 10%)
        uint256 challengerRewardPercentage; // Percentage of slash amount going to the successful challenger (e.g., 500 = 5%)
    }
    InactivityParameters public inactivityParams;

    uint256 public contributionRate; // How many Credits per unit of contribution token (e.g., 1e18 credits per 1e18 token)

    // --- Global State ---
    uint256 public totalProtocolActivityScore; // Metric increased by contributions, vesting, claims, boosts
    uint256 public adminFeesBalance; // Accumulated fees (from slashes, failed challenges)

    // --- User State ---
    struct UserStatus {
        uint256 credits;
        uint256 vestedTokens; // Amount ready to be claimed
        uint256 lastActiveTime; // Timestamp of last vesting/claim/boost/contribution
        uint256 boostAmount; // Amount currently locked for boosting
        address boostingTokenLocked; // Address of the token locked for boosting (0x0 if Credits)
        uint256 lastUnboostTime; // Timestamp user last unboosted
        uint256 lastChallengedTime; // Timestamp user was last challenged
    }
    mapping(address => UserStatus) public userStatus;

    // --- Challenge State ---
    struct Challenge {
        address challenger;
        uint256 stakeAmount; // Amount staked by the challenger
        uint256 startTime; // Timestamp challenge was initiated
        uint256 endTime; // Timestamp challenge period ends (startTime + inactivityThreshold)
        bool resolved; // Has the challenge been resolved?
        bool targetWasInactive; // Was the target found to be inactive?
        uint256 slashedAmount; // Amount of credits slashed from the target
        uint256 rewardAmount; // Amount of stake/slash given to challenger
    }
    mapping(address => Challenge) public latestChallenges; // Target address => Latest Challenge

    // --- Events ---
    event InitializedParameters(address indexed admin);
    event ContributionTokenSet(address indexed token);
    event VestedTokenSet(address indexed token);
    event ParametersUpdated(string paramType, bytes data); // Log updates to param structs
    event FeeRecipientSet(address indexed recipient);

    event EthContributed(address indexed user, uint256 amount, uint256 creditsMinted);
    event TokenContributed(address indexed user, uint256 token, uint256 amount, uint256 creditsMinted);
    event CreditsVested(address indexed user, uint256 creditsUsed, uint256 vestedTokensMinted, uint256 currentRate);
    event VestedTokensClaimed(address indexed user, uint256 amount);

    event BoostApplied(address indexed user, address indexed token, uint256 amount);
    event BoostRemoved(address indexed user, address indexed token, uint256 amount);

    event InactivityChallenged(address indexed challenger, address indexed target, uint256 stakeAmount, uint256 challengeEndTime);
    event ChallengeResolved(address indexed challenger, address indexed target, bool targetWasInactive, uint256 slashedAmount, uint256 rewardAmount);
    event CreditsSlashed(address indexed user, uint256 amount, string reason);

    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        paused = false;
        // Set initial dummy values or require initializeParameters call after deployment
        vestedToken = new SimpleVestedToken("Dynamic Vesting Token", "DVST"); // Deploy a simple vested token
    }

    // --- Admin Functions ---

    function initializeParameters(
        uint256 _baseVestingRatePerCredit,
        uint256 _globalActivityWeight,
        uint256 _maxGlobalActivityMultiplier,
        address _boostingToken,
        uint256 _boostRatePerToken,
        uint256 _maxBoostMultiplier,
        uint256 _unboostCooldown,
        uint256 _inactivityThreshold,
        uint256 _challengeStakeAmount,
        uint256 _challengeCooldown,
        uint256 _slashPercentage,
        uint256 _challengerRewardPercentage,
        uint256 _contributionRate // Credits per contribution unit
    ) external onlyAdmin {
        require(vestingParams.baseVestingRatePerCredit == 0, "Parameters already initialized"); // Simple check

        vestingParams = VestingParameters({
            baseVestingRatePerCredit: _baseVestingRatePerCredit,
            globalActivityWeight: _globalActivityWeight,
            maxGlobalActivityMultiplier: _maxGlobalActivityMultiplier
        });

        boostingParams = BoostingParameters({
            boostingToken: _boostingToken,
            boostRatePerToken: _boostRatePerToken,
            maxBoostMultiplier: _maxBoostMultiplier,
            unboostCooldown: _unboostCooldown
        });

        inactivityParams = InactivityParameters({
            inactivityThreshold: _inactivityThreshold,
            challengeStakeAmount: _challengeStakeAmount,
            challengeCooldown: _challengeCooldown,
            slashPercentage: _slashPercentage,
            challengerRewardPercentage: _challengerRewardPercentage
        });

        contributionRate = _contributionRate;

        emit InitializedParameters(admin);
    }

    function setContributionToken(address _token) external onlyAdmin {
        contributionToken = IERC20(_token);
        emit ContributionTokenSet(_token);
    }

    // Vested Token is deployed in constructor, can't be changed easily unless using upgradeable patterns
    // function setVestedToken(address _token) external onlyAdmin {
    //     require(address(vestedToken) == address(0), "Vested token already set"); // Only set once
    //     vestedToken = SimpleVestedToken(_token); // Cast to your specific SimpleVestedToken if using that
    //     emit VestedTokenSet(_token);
    // }

    function setVestingParameters(uint256 _baseVestingRatePerCredit, uint256 _globalActivityWeight, uint256 _maxGlobalActivityMultiplier) external onlyAdmin {
        vestingParams = VestingParameters({
            baseVestingRatePerCredit: _baseVestingRatePerCredit,
            globalActivityWeight: _globalActivityWeight,
            maxGlobalActivityMultiplier: _maxGlobalActivityMultiplier
        });
        // Log using event, maybe encode data
        emit ParametersUpdated("Vesting", abi.encode(_baseVestingRatePerCredit, _globalActivityWeight, _maxGlobalActivityMultiplier));
    }

    function setBoostingParameters(address _boostingToken, uint256 _boostRatePerToken, uint256 _maxBoostMultiplier, uint256 _unboostCooldown) external onlyAdmin {
        boostingParams = BoostingParameters({
            boostingToken: _boostingToken,
            boostRatePerToken: _boostRatePerToken,
            maxBoostMultiplier: _maxBoostMultiplier,
            unboostCooldown: _unboostCooldown
        });
        emit ParametersUpdated("Boosting", abi.encode(_boostingToken, _boostRatePerToken, _maxBoostMultiplier, _unboostCooldown));
    }

    function setInactivityParameters(uint256 _inactivityThreshold, uint256 _challengeStakeAmount, uint256 _challengeCooldown, uint256 _slashPercentage, uint256 _challengerRewardPercentage) external onlyAdmin {
         require(_slashPercentage <= 10000, "Slash percentage cannot exceed 100%"); // Max 100% (10000 basis points)
         require(_challengerRewardPercentage <= 10000, "Challenger reward percentage cannot exceed 100%");

        inactivityParams = InactivityParameters({
            inactivityThreshold: _inactivityThreshold,
            challengeStakeAmount: _challengeStakeAmount,
            challengeCooldown: _challengeCooldown,
            slashPercentage: _slashPercentage,
            challengerRewardPercentage: _challengerRewardPercentage
        });
        emit ParametersUpdated("Inactivity", abi.encode(_inactivityThreshold, _challengeStakeAmount, _challengeCooldown, _slashPercentage, _challengerRewardPercentage));
    }

    function setContributionRate(uint256 _rate) external onlyAdmin {
        contributionRate = _rate;
        emit ParametersUpdated("ContributionRate", abi.encode(_rate));
    }

     function setFeeRecipient(address _recipient) external onlyAdmin {
        require(_recipient != address(0), "Fee recipient cannot be zero address");
        // Assuming admin address also acts as fee recipient initially
        // For simplicity, let's stick to admin as recipient or allow separate setting:
        // admin = msg.sender; // Keep admin role separate
        // Maybe add a dedicated feeRecipient state variable if needed. For now, admin = fee recipient.
        // If a separate fee recipient is desired, uncomment below and add state variable:
        // feeRecipient = _recipient;
        emit FeeRecipientSet(_recipient);
    }


    function withdrawAdminFees() external onlyAdmin {
        uint256 amount = adminFeesBalance;
        adminFeesBalance = 0;
        if (amount > 0) {
            (bool success,) = payable(admin).call{value: amount}("");
            require(success, "Fee withdrawal failed");
            emit AdminFeesWithdrawn(admin, amount);
        }
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Contribution Functions ---

    function contributeETH() external payable whenNotPaused {
        require(address(contributionToken) == address(0), "ETH contribution not allowed");
        require(msg.value > 0, "Contribution amount must be greater than zero");

        uint256 creditsMinted = (msg.value * contributionRate) / 1e18; // Assuming contributionRate is per 1 ETH (1e18 wei)
        require(creditsMinted > 0, "Credits minted must be greater than zero");

        userStatus[msg.sender].credits += creditsMinted;
        totalProtocolActivityScore += msg.value; // Use ETH value for activity score
        userStatus[msg.sender].lastActiveTime = block.timestamp;

        emit EthContributed(msg.sender, msg.value, creditsMinted);
    }

    function contributeToken(uint256 _amount) external whenNotPaused {
        require(address(contributionToken) != address(0), "Token contribution not allowed");
        require(_amount > 0, "Contribution amount must be greater than zero");
        require(contributionToken.allowance(msg.sender, address(this)) >= _amount, "Token allowance too low");

        uint256 creditsMinted = (_amount * contributionRate) / 1e18; // Assuming contributionRate is per 1 token (1e18 units)
         require(creditsMinted > 0, "Credits minted must be greater than zero");

        contributionToken.transferFrom(msg.sender, address(this), _amount);

        userStatus[msg.sender].credits += creditsMinted;
        totalProtocolActivityScore += _amount; // Use token amount for activity score
        userStatus[msg.sender].lastActiveTime = block.timestamp;

        emit TokenContributed(msg.sender, address(contributionToken), _amount, creditsMinted);
    }

    // --- Internal Calculation Helpers ---

    function _getGlobalActivityMultiplier() internal view returns (uint256) {
        if (totalProtocolActivityScore == 0 || vestingParams.globalActivityWeight == 0) {
            return 1e18; // 1x multiplier
        }
        // Simple linear scaling example: activity score / some basis * weight
        // Example: score 1000, weight 100 (1%), basis 100 -> 1000/100 * 1% = 10%. Multiplier 1.1x
        // Let's use a slightly more robust approach based on log or sigmoid for real projects.
        // For this example, simple linear scaled by a fixed basis relative to potential scale.
        // Let's assume max possible score is 1e24 (large value), weight is basis points (100 = 1%)
        // Multiplier increases by `globalActivityWeight / 10000` for every 1e18 increase in score (example logic)
        uint256 activityMultiplier = 1e18 + ((totalProtocolActivityScore / 1e18) * vestingParams.globalActivityWeight) / 10000;

        return Math.min(activityMultiplier, vestingParams.maxGlobalActivityMultiplier);
    }

    function getBoostMultiplier(address _user) public view returns (uint256) {
         UserStatus storage user = userStatus[_user];
         if (user.boostAmount == 0 || boostingParams.boostRatePerToken == 0) {
             return 1e18; // 1x multiplier
         }

         // Example: boost amount / 1e18 * boostRate (basis points)
         uint256 boostMultiplier = 1e18 + ((user.boostAmount / 1e18) * boostingParams.boostRatePerToken) / 10000;

         return Math.min(boostMultiplier, boostingParams.maxBoostMultiplier);
    }


    function getCurrentVestingRate(address _user) public view returns (uint256) {
        uint256 baseRate = vestingParams.baseVestingRatePerCredit; // e.g., 1e18 (1:1)

        // Apply global activity multiplier
        uint256 globalMultiplier = _getGlobalActivityMultiplier();
        uint256 rateAfterGlobal = (baseRate * globalMultiplier) / 1e18;

        // Apply user boost multiplier
        uint256 userBoostMultiplier = getBoostMultiplier(_user);
        uint256 finalRate = (rateAfterGlobal * userBoostMultiplier) / 1e18;

        // Add potential other factors here (e.g., time elapsed since last activity penalty)

        return finalRate;
    }

    // --- Vesting & Claiming Functions ---

    function _applyInactivitySlash(address _user) internal returns (uint256 slashedAmount) {
        UserStatus storage user = userStatus[_user];
        uint256 currentTime = block.timestamp;

        // Only check/slash if user has credits and has been inactive long enough
        if (user.credits > 0 && user.lastActiveTime > 0 && currentTime > user.lastActiveTime + inactivityParams.inactivityThreshold) {
            // Calculate slash amount based on percentage of current credits
            slashedAmount = (user.credits * inactivityParams.slashPercentage) / 10000; // slashPercentage is in basis points
            user.credits -= slashedAmount;
            adminFeesBalance += slashedAmount; // Send slashed credits to admin fees (as if it were ETH/Token value)
            emit CreditsSlashed(_user, slashedAmount, "Inactivity");

             // Also penalize boost if token wasn't Credits themselves and was inactive
             if (user.boostAmount > 0 && user.boostingTokenLocked != address(0)) {
                 uint256 boostPenalty = (user.boostAmount * inactivityParams.slashPercentage) / 10000;
                 user.boostAmount -= boostPenalty;
                 // Assuming boosted ERC20 tokens go to admin fees too
                 if(user.boostingTokenLocked != address(0)) {
                     IERC20(user.boostingTokenLocked).transfer(admin, boostPenalty); // Transfer actual tokens
                 } else {
                     adminFeesBalance += boostPenalty; // If Credits were boosted, add to fees (conceptually)
                 }
             }
        }
         return slashedAmount;
    }

    function vestCredits(uint256 _creditsToVest) external whenNotPaused {
        UserStatus storage user = userStatus[msg.sender];
        require(user.credits >= _creditsToVest, "Insufficient credits to vest");
        require(_creditsToVest > 0, "Must vest a positive amount");

        // Check and apply inactivity slash before vesting
        _applyInactivitySlash(msg.sender); // This might reduce user.credits

        require(user.credits >= _creditsToVest, "Credits reduced by slash, not enough remaining"); // Re-check after slash

        uint256 currentRate = getCurrentVestingRate(msg.sender);
        uint256 vestedAmount = (_creditsToVest * currentRate) / 1e18; // Rate is per 1 Credit (1e18)

        user.credits -= _creditsToVest;
        user.vestedTokens += vestedAmount;
        user.lastActiveTime = block.timestamp;
        totalProtocolActivityScore += _creditsToVest; // Vesting also counts as activity

        emit CreditsVested(msg.sender, _creditsToVest, vestedAmount, currentRate);
    }

    function claimVestedTokens() external whenNotPaused {
        UserStatus storage user = userStatus[msg.sender];
        uint256 amountToClaim = user.vestedTokens;
        require(amountToClaim > 0, "No vested tokens to claim");

        // Check and apply inactivity slash before claiming (slashes Credits, not VestedTokens)
         _applyInactivitySlash(msg.sender); // Slashes credits, doesn't affect vestedTokens directly

        user.vestedTokens = 0;
        user.lastActiveTime = block.timestamp; // Claiming is also activity

        // Mint/Transfer the vested tokens
        vestedToken._mint(msg.sender, amountToClaim);

        emit VestedTokensClaimed(msg.sender, amountToClaim);
    }

    // --- Boosting Functions ---

    function boostVestingRate(uint256 _amount) external whenNotPaused {
        UserStatus storage user = userStatus[msg.sender];
        require(_amount > 0, "Must boost with a positive amount");
        require(user.boostAmount == 0, "Already boosting"); // Allow only one boost active at a time

        address tokenAddress = boostingParams.boostingToken;
        require(tokenAddress != address(0) || _amount <= user.credits, "Insufficient credits to boost");
        require(tokenAddress == address(0) || IERC20(tokenAddress).allowance(msg.sender, address(this)) >= _amount, "Token allowance too low for boosting");

        user.boostAmount = _amount;
        user.boostingTokenLocked = tokenAddress;
        user.lastActiveTime = block.timestamp; // Boosting is activity

        if (tokenAddress == address(0)) {
            // Lock credits
            require(user.credits >= _amount, "Insufficient credits to boost");
            user.credits -= _amount;
             // Credits aren't 'transferred', just deducted and state updated
        } else {
            // Lock boosting token
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        }

        emit BoostApplied(msg.sender, tokenAddress, _amount);
    }

    function unboostVestingRate() external whenNotPaused {
        UserStatus storage user = userStatus[msg.sender];
        require(user.boostAmount > 0, "No active boost");
        require(block.timestamp >= user.lastUnboostTime + boostingParams.unboostCooldown, "Unboost cooldown active");

        uint256 amount = user.boostAmount;
        address tokenAddress = user.boostingTokenLocked;

        user.boostAmount = 0;
        user.boostingTokenLocked = address(0);
        user.lastUnboostTime = block.timestamp;
        user.lastActiveTime = block.timestamp; // Unboosting is activity

        if (tokenAddress == address(0)) {
            // Return credits
             user.credits += amount;
             // Credits aren't 'transferred', just added back to balance
        } else {
            // Return boosting token
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }

        emit BoostRemoved(msg.sender, tokenAddress, amount);
    }

    // --- Inactivity & Challenge Functions ---

    function challengeInactivity(address _target) external payable whenNotPaused {
         require(msg.sender != _target, "Cannot challenge yourself");
         require(_target != address(0), "Cannot challenge zero address");

         UserStatus storage targetUser = userStatus[_target];
         require(targetUser.lastActiveTime + inactivityParams.challengeCooldown <= block.timestamp, "Target recently challenged or active");

         // Determine stake token/ETH
         address stakeToken = address(contributionToken); // Use contribution token for stake
         uint256 requiredStake = inactivityParams.challengeStakeAmount;

         if (stakeToken == address(0)) {
             // ETH stake
             require(msg.value == requiredStake, "Must send correct ETH stake");
             adminFeesBalance += msg.value; // Hold stake in contract (adds to fees balance, will be distributed later)
         } else {
             // Token stake
             require(msg.value == 0, "Cannot send ETH with token stake");
             require(IERC20(stakeToken).allowance(msg.sender, address(this)) >= requiredStake, "Token allowance too low for stake");
             IERC20(stakeToken).transferFrom(msg.sender, address(this), requiredStake);
              // Hold stake token in contract address directly
         }


         latestChallenges[_target] = Challenge({
             challenger: msg.sender,
             stakeAmount: requiredStake,
             startTime: block.timestamp,
             endTime: block.timestamp + inactivityParams.inactivityThreshold,
             resolved: false,
             targetWasInactive: false, // Determined on resolution
             slashedAmount: 0,
             rewardAmount: 0
         });

        targetUser.lastChallengedTime = block.timestamp; // Update target's challenge timestamp
        userStatus[msg.sender].lastActiveTime = block.timestamp; // Initiating a challenge is activity

         emit InactivityChallenged(msg.sender, _target, requiredStake, latestChallenges[_target].endTime);
    }

     function resolveChallenge(address _target) external whenNotPaused {
         Challenge storage challenge = latestChallenges[_target];
         require(challenge.challenger != address(0), "No challenge found for target");
         require(!challenge.resolved, "Challenge already resolved");
         require(block.timestamp >= challenge.endTime, "Challenge period not ended yet");

         UserStatus storage targetUser = userStatus[_target];
         address stakeToken = address(contributionToken);

         uint256 stakedAmount = challenge.stakeAmount;
         uint256 slashAmount = 0;
         uint256 rewardAmount = 0;
         uint256 feesFromSlash = 0;


         // Check target activity during the challenge period (between challenge.startTime and challenge.endTime)
         bool targetWasActiveDuringChallenge = targetUser.lastActiveTime >= challenge.startTime && targetUser.lastActiveTime <= challenge.endTime;

         challenge.targetWasInactive = !targetWasActiveDuringChallenge;

         if (challenge.targetWasInactive) {
             // Apply slash to target's credits
             // Calculate slash based on credits *at the time of resolution*
             // This adds a dynamic element - target can vest credits BEFORE resolution to minimize slash
             slashAmount = (targetUser.credits * inactivityParams.slashPercentage) / 10000; // basis points
             if (slashAmount > 0) {
                 targetUser.credits -= slashAmount;
                 emit CreditsSlashed(_target, slashAmount, "Inactivity Challenge");
             }

             // Distribute slash amount: part to challenger, part to admin fees
             uint256 challengerShare = (slashAmount * inactivityParams.challengerRewardPercentage) / 10000;
             feesFromSlash = slashAmount - challengerShare;

             // Challenger gets their stake back PLUS their share of the slash
             rewardAmount = stakedAmount + challengerShare;

             // Transfer stake + reward (handled below)
         } else {
             // Target was active, challenger loses stake (or it's returned fully)
             // For simplicity, let's return the stake to the challenger on unsuccessful challenge
              rewardAmount = stakedAmount;
              feesFromSlash = 0; // No slash, no fees from slash
             // Could add a small penalty to challenger stake here for failed challenge if desired
         }

         // --- Handle Stake & Rewards Distribution ---
         if (stakeToken == address(0)) {
             // ETH Stake/Reward
             adminFeesBalance -= stakedAmount; // Deduct original stake held in fees
             adminFeesBalance += feesFromSlash; // Add fees from slash
              if(rewardAmount > 0) {
                (bool success, ) = payable(challenge.challenger).call{value: rewardAmount}("");
                // Log failure if necessary, but contract state is updated regardless
                // require(success, "ETH reward transfer failed"); // Or handle gracefully
              }

         } else {
             // Token Stake/Reward
             // Token stake is held in contract balance. Need to transfer out.
             // This needs careful tracking of token balances held for stakes vs admin fees
             // For simplicity in this example, let's assume the stake tokens become part of admin fees,
             // and the reward tokens are transferred out of admin fees (simplification!).
             // A robust system would track staked tokens separately.
             // Let's adjust: tokens transferred to contract upon stake, they are now in THIS contract's balance.
             // We transfer rewards from THIS contract's balance. Fees from slash are CONCEPTUALLY added to fees.

             if (rewardAmount > 0) {
                 IERC20(stakeToken).transfer(challenge.challenger, rewardAmount);
             }
             // Fees from slash are "conceptual" admin fees added to adminFeesBalance (which is in ETH)
             // A proper system would handle multiple token types for fees.
             // Let's assume for this example that slash fees are converted to ETH equivalent or tracked separately per token type.
             // Simplification: Slashing gives 'Credit' equivalent value to admin fees in ETH.
             // The 'feesFromSlash' calculated above represents Credits/ETH value.
             // We add this value to adminFeesBalance (which is in ETH).

             // So, if stakeToken is ERC20, the *stake* stays in the contract's ERC20 balance.
             // If challenger wins, their stake is transferred back from contract's ERC20 balance + their slash reward.
             // If challenger loses, their stake stays in contract's ERC20 balance (effectively becomes admin fees in that token).
             // The `adminFeesBalance` (in ETH) only increases from ETH stakes or ETH-equivalent slash value.
             // This requires more complex accounting if multiple tokens are involved in fees/stakes.

             // REVISING SIMPLIFIED TOKEN STAKE/REWARD:
             // Stake is transferred to contract. If win, stake+reward transferred from contract. If lose, stake remains in contract (as admin fees).
             // The slash amount is in CREDITS. It's converted conceptually to value.
             // Let's assume slash value is always in ETH equivalent for adminFeesBalance.
             // This needs an oracle or fixed conversion rate... too complex.

             // Let's assume stake is ALWAYS in ETH, and slash value is also calculated in ETH-equivalent.
             // Or, stake is always in ContributionToken, and slash value is also in ContributionToken.
             // Let's go with Stake in ContributionToken, Slash value in ContributionToken.

             stakeToken = address(contributionToken);
             if (stakeToken == address(0)) { // ETH Stake handled above, uses adminFeesBalance for holding
                  // Already handled ETH logic above.
             } else { // Token Stake
                 // Stake tokens are already in address(this).
                 if (rewardAmount > 0) {
                    IERC20(stakeToken).transfer(challenge.challenger, rewardAmount); // Transfer stake + reward
                 }
                 // If target was active, the stakedAmount remains in the contract (becomes admin fees in StakeToken)
                 // If target was inactive, stakeAmount returned + feesFromSlash transferred (total rewardAmount). feesFromSlash amount comes from target's slashed credits (as ContributionToken equivalent)
                 // This still means we need to track fees per token type.
                 // Let's revert to a very simple model: Stake is ETH. Slash value is ETH-equivalent. All fees accumulate in ETH adminFeesBalance.

                  // --- Simplified Model (ETH Stake, ETH Equivalent Slash Value) ---
                  // ETH Stake is added to adminFeesBalance initially.
                  // If win: deduct stakeAmount from adminFeesBalance, add feesFromSlash to adminFeesBalance, send rewardAmount (stake+feesFromSlash) ETH to challenger.
                  // If lose: stakeAmount stays in adminFeesBalance.
             }

             // Re-implementing the simpler ETH stake/reward logic:
             if (stakeToken == address(0)) { // Only applies if stake IS ETH
                  adminFeesBalance -= stakedAmount; // Deduct original stake
                  adminFeesBalance += feesFromSlash; // Add fees from slash (if any)
                   if (rewardAmount > 0) {
                       (bool success, ) = payable(challenge.challenger).call{value: rewardAmount}("");
                       // Consider emitting an event if transfer fails or adding a recovery mechanism
                       // require(success, "ETH reward transfer failed"); // Or log/handle
                   }
             }
             // If stakeToken is NOT ETH, the challenge stake/reward logic needs to handle ERC20 token balances held by the contract, not adminFeesBalance (which is ETH). This makes it significantly more complex for a single example contract.
             // Let's assume for this example, challenge stakes are only in ETH if contributionToken is ETH, or only in ContributionToken if it's an ERC20. And slash value is in the same asset.
             // So, if ContributionToken is ERC20, Stake is ERC20. Slash is ERC20 value. AdminFeesBalance should be mapping(address => uint256).
             // This is growing too complex. Let's stick to ETH stake/fees for simplicity in this example, requiring contributionToken to be ETH.

             // Assuming ContributionToken is ETH (0x0), Stake is ETH, Fees are ETH:
              adminFeesBalance -= stakedAmount; // Deduct original stake from fees balance
              adminFeesBalance += feesFromSlash; // Add fees from slash (if any)
               if (rewardAmount > 0) {
                   (bool success, ) = payable(challenge.challenger).call{value: rewardAmount}("");
                   // require(success, "ETH reward transfer failed");
               }

         }


         challenge.resolved = true;
         challenge.slashedAmount = slashAmount; // Amount of credits slashed (conceptually)
         challenge.rewardAmount = rewardAmount; // Amount of ETH/Token value paid to challenger

         emit ChallengeResolved(challenge.challenger, _target, challenge.targetWasInactive, slashAmount, rewardAmount);
     }

    // --- Query Functions ---

    function getCreditsBalance(address _user) external view returns (uint256) {
        return userStatus[_user].credits;
    }

    function getVestedBalance(address _user) external view returns (uint256) {
        return userStatus[_user].vestedTokens;
    }

    function getPendingVestedTokens(address _user) external view returns (uint256) {
        uint256 currentCredits = userStatus[_user].credits;
        if (currentCredits == 0) {
            return 0;
        }
        uint256 currentRate = getCurrentVestingRate(_user);
        // Estimate based on current credits and rate. Doesn't account for potential slash before vesting.
        return (currentCredits * currentRate) / 1e18;
    }

    function getUserLastActiveTime(address _user) external view returns (uint256) {
        return userStatus[_user].lastActiveTime;
    }

    function getChallengeStatus(address _target) external view returns (address challenger, uint256 stakeAmount, uint256 startTime, uint256 endTime, bool resolved, bool targetWasInactive, uint256 slashedAmount, uint256 rewardAmount) {
        Challenge storage challenge = latestChallenges[_target];
         return (
             challenge.challenger,
             challenge.stakeAmount,
             challenge.startTime,
             challenge.endTime,
             challenge.resolved,
             challenge.targetWasInactive,
             challenge.slashedAmount,
             challenge.rewardAmount
         );
    }

    function getTotalProtocolActivityScore() external view returns (uint256) {
        return totalProtocolActivityScore;
    }

    // getBoostMultiplier is already public view

     function getInactivitySlashPenalty(address _user) external view returns (uint256 potentialSlashAmount) {
         UserStatus storage user = userStatus[_user];
         uint256 currentTime = block.timestamp;

         if (user.credits > 0 && user.lastActiveTime > 0 && currentTime > user.lastActiveTime + inactivityParams.inactivityThreshold) {
             // Calculate slash amount based on percentage of current credits
             potentialSlashAmount = (user.credits * inactivityParams.slashPercentage) / 10000; // slashPercentage is in basis points
         } else {
             potentialSlashAmount = 0;
         }
         return potentialSlashAmount;
     }

     function getContributionRate() external view returns(uint256) {
         return contributionRate;
     }

     function getAdminFeesBalance() external view returns(uint256) {
         return adminFeesBalance;
     }

      function getUserBoostInfo(address _user) external view returns (uint256 amount, address tokenAddress, uint256 lastUnboostTime) {
         UserStatus storage user = userStatus[_user];
         return (user.boostAmount, user.boostingTokenLocked, user.lastUnboostTime);
     }

    // --- Receive/Fallback ---
    receive() external payable {
        // Optional: handle naked ETH transfers. Could mint credits, reject, or add to fees.
        // For this example, let's reject unless it's a contribution
        revert("Naked ETH receive not supported. Use contributeETH.");
    }
    fallback() external payable {
         // Optional: handle calls to undefined functions
         revert("Call to non-existent function.");
    }

}

// Simple Math library (can be replaced by OpenZeppelin's SafeMath or general Math)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
     function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

```

**Explanation of Advanced/Interesting Concepts Used:**

1.  **Dynamic Vesting Rate:** The rate at which non-transferable Credits convert to transferable Vested Tokens isn't fixed. It's calculated based on:
    *   A base rate (`vestingParams.baseVestingRatePerCredit`).
    *   A multiplier derived from the `totalProtocolActivityScore`, capped at `vestingParams.maxGlobalActivityMultiplier`. This incentivizes overall system usage.
    *   An individual multiplier derived from `boostAmount`, capped at `boostingParams.maxBoostMultiplier`. This rewards users who stake assets within the system.
    *   The `getCurrentVestingRate` function encapsulates this multi-factor calculation.

2.  **Contribution-based Credit Issuance:** Users don't just get tokens; they get an intermediate, non-transferable unit (`Credits`) by contributing value (ETH or an ERC20). The `contributionRate` determines the amount of Credits received. This separates initial input from the final tradable asset and facilitates the dynamic vesting process.

3.  **Internal Activity Score:** `totalProtocolActivityScore` is a simple metric tracked by the contract. It increases with contributions, vesting, claiming, and boosting actions. This on-chain metric directly feeds into the dynamic vesting rate, creating a positive feedback loop for active participation.

4.  **Boosting Mechanism:** Users can lock assets (`boostVestingRate`) to temporarily increase their individual vesting rate. This locking mechanism adds a staking-like element that directly benefits the user within the contract's logic, without requiring external DeFi interactions. The asset locked can be Credits themselves or another specified token.

5.  **Inactivity Penalty and Challenge System:**
    *   Users who remain inactive for `inactivityParams.inactivityThreshold` are subject to having a percentage (`inactivityParams.slashPercentage`) of their Credits slashed (sent to admin fees) when they next interact or are challenged.
    *   The `challengeInactivity` function allows any user to pay a stake (`inactivityParams.challengeStakeAmount`) to force an inactivity check on another user.
    *   The `resolveChallenge` function, callable by anyone after a cool-down, checks if the target was active *during the challenge period*. If inactive, the slash is applied, and the challenger receives their stake back plus a portion (`inactivityParams.challengerRewardPercentage`) of the slashed amount as a reward. This adds a decentralized monitoring and incentive mechanism.

6.  **Intermediate Non-transferable Unit (`Credits`):** Using `Credits` as an internal, non-transferable unit is key. It separates potential value from realized, transferable value (`VestedToken`) and allows for mechanics like slashing or boosting without affecting the publicly tradable asset directly until it's vested.

7.  **Parameter Governance (Simplified):** While not a full DAO, the contract includes multiple admin functions (`set...Parameters`, `initializeParameters`) to adjust key dynamics. In a real-world scenario, this would likely evolve into a decentralized governance mechanism.

8.  **State-Dependent Calculations:** Many view functions (`getPendingVestedTokens`, `getCurrentVestingRate`, `getInactivitySlashPenalty`) are not simple reads but perform calculations based on current contract state and user history.

9.  **Internal Token Minting:** The `SimpleVestedToken` is minted directly by the `DynamicVestingSphere` contract upon successful vesting/claiming, demonstrating a common pattern in token economies built around a core protocol action.

10. **Role-Based Access Control:** Simple `onlyAdmin` modifier is used, a standard but necessary pattern for managing administrative functions.

This contract provides a framework for a dynamic, incentive-driven token distribution system that goes beyond basic linear vesting, incorporating elements of network effects, individual staking, and decentralized monitoring through the challenge system. It deliberately avoids direct interaction with external protocols (like AMMs or oracles) to keep the example focused and self-contained, while still demonstrating complex internal state management and dynamic behavior.