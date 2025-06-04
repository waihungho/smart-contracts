Okay, here is a Solidity smart contract implementing a concept I'll call the "QuantumTrustNexus". It's designed as a decentralized platform for staking on the future outcome of verifiable claims, integrating a reputation system, a managed oracle network for resolution, and dynamic parameters based on system performance.

It combines elements of prediction markets, reputation systems, and dynamic governance, aiming for a creative and less common combination than standard DeFi or NFT contracts. It utilizes OpenZeppelin contracts for secure access control and pausing.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Although NTX is internal, good practice to reference

/**
 * @title QuantumTrustNexus Contract
 * @dev A decentralized platform for staking on future verifiable claims.
 *      Features include claim proposal, staking on outcomes, oracle-based resolution,
 *      a reputation system for participants based on prediction accuracy, dynamic
 *      protocol parameters, and an integrated staking token (NTX).
 *
 * OUTLINE:
 * 1. Imports and Contract Definition
 * 2. Access Control Roles Definition
 * 3. Errors
 * 4. Events
 * 5. State Variables
 *    - Core platform state (claim counter, mappings for claims, user stakes, etc.)
 *    - Oracle management state
 *    - Reputation system state
 *    - Dynamic parameter state
 *    - NTX Token state (internal balances)
 * 6. Struct Definitions (Claim, OracleSubmission, UserStake, UserReputation)
 * 7. Constructor (Initialize roles)
 * 8. Role Management Functions (Inherited from AccessControl, plus custom setters)
 * 9. Pause/Unpause Functions (Inherited from Pausable)
 * 10. NTX Token Functions (Internal logic for balance management)
 * 11. Claim Management Functions (Proposing, Staking, Unstaking)
 * 12. Oracle Management Functions (Registering, Setting fees)
 * 13. Resolution Functions (Submitting oracle data, Triggering resolution, Calculating payouts)
 * 14. Reputation System Functions (Updating, Querying, Ranking)
 * 15. Dynamic Parameter Functions (Admin setters for base parameters, Public getters for calculated current values)
 * 16. Withdrawal Functions (Stakes, Oracle Fees)
 * 17. Admin/Protocol Settings Functions
 * 18. View/Query Functions
 *
 * FUNCTION SUMMARY:
 *
 * Access Control & Pausing:
 * - constructor(): Initializes admin role.
 * - pause(): Pauses contract functionality (Admin).
 * - unpause(): Unpauses contract functionality (Admin).
 * - grantRole(): Grants a role (Admin).
 * - revokeRole(): Revokes a role (Admin).
 * - renounceRole(): Renounces own role.
 * - hasRole(): Checks if address has a role.
 * - getRoleAdmin(): Gets the admin role for a given role.
 * - setOracleAdminRole(): Sets the address for the ORACLE_ADMIN role (Admin).
 *
 * NTX Token (Internal):
 * - _mintNTX(): Internal minting function (Admin controlled).
 * - _burnNTX(): Internal burning function (User controlled for fees/exit).
 * - _transferNTX(): Internal transfer function.
 * - balanceOfNTX(address user): Get user's NTX balance.
 * - totalSupplyNTX(): Get total NTX supply.
 *
 * Claim Management:
 * - proposeClaim(string calldata description, uint256 resolutionTime, string calldata oracleIdentifier): Propose a new claim (Any user).
 * - stakeForClaim(uint256 claimId, uint8 outcome, uint256 amount): Stake NTX on a claim outcome (Any user).
 * - unstakeFromClaim(uint256 claimId): Unstake NTX from an unresolved claim (Any user - subject to policy).
 * - getClaimDetails(uint256 claimId): Get details of a claim.
 * - getUserStakeOnClaim(uint256 claimId, address user): Get a user's stake details for a claim.
 * - listActiveClaims(): Get list of claim IDs not yet resolved.
 * - listResolvedClaims(): Get list of claim IDs that are resolved.
 *
 * Oracle Management:
 * - registerOracle(address oracleAddress, string calldata identifier): Register an oracle (Oracle Admin).
 * - unregisterOracle(address oracleAddress): Unregister an oracle (Oracle Admin).
 * - setOracleFee(address oracleAddress, uint256 fee): Set fee for an oracle (Oracle Admin).
 * - getOracleStatus(address oracleAddress): Get status and identifier of an oracle.
 * - getRegisteredOracles(): Get list of registered oracle addresses.
 *
 * Resolution:
 * - submitOracleResolution(uint256 claimId, uint8 outcome, string calldata oracleProof): Submit resolution data for a claim (Oracle).
 * - resolveClaim(uint256 claimId): Trigger resolution and payout for a claim (Oracle Admin or incentivized trigger).
 * - getClaimResolutionDetails(uint256 claimId): Get submitted oracle resolutions for a claim.
 *
 * Reputation System:
 * - updateReputation(address user): Trigger reputation calculation for a user.
 * - getUserReputation(address user): Get a user's reputation score.
 * - getTopPredictors(uint256 count): Get a list of users with highest reputation (Simplified).
 *
 * Dynamic Parameters:
 * - updateStakingFeeParameters(uint256 baseFeePermil, uint256 accuracyImpactPermil): Admin sets parameters for dynamic staking fee calculation.
 * - updateResolutionThresholdParameters(uint256 minOracles, uint256 consensusPermil): Admin sets parameters for dynamic resolution threshold calculation.
 * - updateReputationMultiplierParameters(uint256 correctStakeWeight, uint256 incorrectStakeWeight): Admin sets parameters for reputation calculation.
 * - getCurrentStakingFee(): Get the current calculated staking fee (Public View).
 * - getCurrentResolutionThreshold(): Get the current required oracle consensus threshold (Public View).
 * - getCurrentReputationMultiplier(): Get the current multiplier used in reputation calculation (Public View).
 *
 * Withdrawals:
 * - withdrawResolvedStakes(uint256 claimId): Withdraw winning stakes after claim resolution (Any user).
 * - withdrawOracleFees(): Withdraw accumulated fees (Oracle).
 *
 * Admin/Protocol Settings:
 * - setMinStakeAmount(uint256 amount): Set minimum required stake amount (Admin).
 * - setOracleRegistrationFee(uint256 fee): Set fee to register an oracle (Admin).
 *
 * Utility/View:
 * - getClaimOutcome(uint256 claimId): Get the final outcome of a resolved claim.
 * - getClaimStakeSummary(uint256 claimId): Get total staked amounts per outcome for a claim.
 */
contract QuantumTrustNexus is AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- 2. Access Control Roles Definition ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    // DEFAULT_ADMIN_ROLE is inherited from AccessControl

    // --- 3. Errors ---
    error ClaimNotFound(uint256 claimId);
    error ClaimNotResolvable(uint256 claimId, string reason);
    error ClaimAlreadyResolved(uint256 claimId);
    error InvalidOutcome(uint8 outcome);
    error InsufficientStakeAmount(uint256 required, uint256 provided);
    error StakeAlreadyExists(uint256 claimId, address user);
    error StakeDoesNotExist(uint256 claimId, address user);
    error UnstakeNotAllowedYet(uint256 resolutionTime);
    error ResolutionTimePassed(uint256 resolutionTime);
    error OracleNotRegistered(address oracle);
    error OracleAlreadyRegistered(address oracle);
    error InvalidOracleProof(); // Generic for now, implementation would vary
    error NotEnoughOracleSubmissions(uint256 required, uint256 provided);
    error OracleConsensusNotReached();
    error UserHasNoWithdrawableFunds();
    error OracleHasNoFeesToWithdraw();
    error ResolutionPending(uint256 claimId);
    error ClaimNotInResolutionWindow(uint256 claimId);


    // --- 4. Events ---
    event ClaimProposed(uint256 indexed claimId, address indexed proposer, string description, uint256 resolutionTime, string oracleIdentifier);
    event StakeAdded(uint256 indexed claimId, address indexed staker, uint8 outcome, uint256 amount);
    event StakeRemoved(uint256 indexed claimId, address indexed staker, uint256 amount);
    event OracleRegistered(address indexed oracleAddress, string identifier);
    event OracleUnregistered(address indexed oracleAddress);
    event OracleFeeSet(address indexed oracleAddress, uint256 fee);
    event OracleResolutionSubmitted(uint256 indexed claimId, address indexed oracleAddress, uint8 outcome, string oracleProof);
    event ClaimResolved(uint256 indexed claimId, uint8 finalOutcome, uint256 resolutionTimestamp);
    event StakeWithdrawn(uint256 indexed claimId, address indexed user, uint256 amount);
    event OracleFeesWithdrawn(address indexed oracleAddress, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event DynamicParametersUpdated(string paramName, uint256 value1, uint256 value2); // Generic event


    // --- 5. State Variables ---
    Counters.Counter private _claimIds;

    // --- 6. Struct Definitions ---

    struct Claim {
        uint256 id;
        address proposer;
        string description;
        uint256 proposalTimestamp;
        uint256 resolutionTime; // Timestamp when the claim should be resolved
        string oracleIdentifier; // Identifier for the type of oracle data needed
        bool resolved;
        uint8 finalOutcome; // 0: Unresolved, 1: True, 2: False, 3: Invalid/Cancelled (example outcomes)
        uint256 resolutionTimestamp; // Actual timestamp of resolution
        uint256 totalStaked; // Total NTX staked on this claim across all outcomes
        mapping(uint8 => uint256) totalStakedByOutcome; // Total NTX staked per outcome
        mapping(address => UserStake) stakes; // User's stake details on this claim
        mapping(address => OracleSubmission) oracleSubmissions; // Submitted resolutions by oracles
        address[] stakers; // List of unique addresses that staked on this claim (gas consideration for large lists)
        address[] submittingOracles; // List of oracles who submitted resolutions (gas consideration)
    }

    struct UserStake {
        uint256 amount;
        uint8 outcome;
        bool withdrawn;
        bool exists; // To check if mapping entry is a real stake
    }

    struct OracleSubmission {
        uint8 outcome;
        string proof; // Proof data submitted by the oracle
        uint256 timestamp;
        bool exists; // To check if mapping entry is a real submission
    }

    struct UserReputation {
        uint256 totalCorrectStakeValue;
        uint256 totalIncorrectStakeValue;
        // Calculated reputation score derived from the above
    }

    struct Oracle {
        string identifier;
        uint256 fee; // Fee in NTX per successful resolution submission
        bool registered;
    }

    // Core platform state
    mapping(uint256 => Claim) public claims;
    uint256[] public activeClaimIds; // List of claims not yet resolved
    uint256[] public resolvedClaimIds; // List of claims that are resolved

    // Oracle management state
    mapping(address => Oracle) public registeredOracles;
    address[] public registeredOracleAddresses; // List of registered oracle addresses
    mapping(address => uint256) public oracleFeeBalances; // NTX owed to oracles

    // Reputation system state
    mapping(address => UserReputation) public userReputationData;
    // A simplified approach for top predictors - maybe store manually or calculate off-chain
    address[] public topPredictors; // Example: Store top N manually or via a helper contract/process

    // Dynamic parameter state (Admin sets base parameters, getters calculate current value)
    uint256 private _minStakeAmount = 1000; // Example: 10 NTX (assuming 18 decimals)
    uint256 private _oracleRegistrationFee = 5000; // Example: 50 NTX

    // Dynamic staking fee parameters (e.g., base permil, impact of system accuracy)
    uint256 private _baseStakingFeePermil = 5; // 0.5% base fee on total staked on a claim
    uint256 private _accuracyImpactPermil = 10; // How much overall system accuracy affects the fee multiplier

    // Dynamic resolution threshold parameters (e.g., min number of oracles, required consensus percentage)
    uint256 private _minRequiredOracles = 3;
    uint256 private _requiredConsensusPermil = 700; // 70% consensus needed

    // Dynamic reputation parameters (weights for correct/incorrect stakes)
    uint256 private _correctStakeWeight = 2;
    uint256 private _incorrectStakeWeight = 3; // Incorrect predictions might penalize more

    // NTX Token state (internal management)
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public constant NTX_NAME = "Nexus Trust Xelph";
    string public constant NTX_SYMBOL = "NTX";
    uint8 public constant NTX_DECIMALS = 18;


    // --- 7. Constructor ---
    constructor() Pausable(false) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Grant admin role to deployer
    }

    // --- 8. Role Management Functions ---
    // Inherited from AccessControl: grantRole, revokeRole, renounceRole, hasRole, getRoleAdmin

    /// @dev Sets the address holding the ORACLE_ADMIN_ROLE.
    /// @param oracleAdminAddress The address to grant the ORACLE_ADMIN_ROLE.
    function setOracleAdminRole(address oracleAdminAddress) external onlyRole(ADMIN_ROLE) {
        _grantRole(ORACLE_ADMIN_ROLE, oracleAdminAddress);
    }

    /// @dev Grants the ORACLE_ROLE to an address. Can only be called by ORACLE_ADMIN_ROLE.
    /// @param oracleAddress The address to grant the ORACLE_ROLE.
    function grantOracleRole(address oracleAddress) external onlyRole(ORACLE_ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, oracleAddress);
    }

    /// @dev Revokes the ORACLE_ROLE from an address. Can only be called by ORACLE_ADMIN_ROLE.
    /// @param oracleAddress The address to revoke the ORACLE_ROLE from.
    function revokeOracleRole(address oracleAddress) external onlyRole(ORACLE_ADMIN_ROLE) {
        _revokeRole(ORACLE_ROLE, oracleAddress);
    }


    // --- 9. Pause/Unpause Functions ---
    // Inherited from Pausable: pause, unpause

    // --- 10. NTX Token Functions (Internal Logic) ---
    // These are not standard ERC20 functions, they are internal management functions

    /// @dev Mints NTX tokens and assigns them to an account. Only callable by ADMIN_ROLE.
    /// @param to The address to mint tokens for.
    /// @param amount The amount of tokens to mint.
    function _mintNTX(address to, uint256 amount) internal onlyRole(ADMIN_ROLE) whenNotPaused {
        require(to != address(0), "Mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        // Could emit a custom Mint event if needed
    }

     /// @dev Burns NTX tokens from an account. User burns their own tokens.
    /// @param amount The amount of tokens to burn.
    function burnNTX(uint256 amount) external whenNotPaused {
        _burnNTX(msg.sender, amount);
        // Could emit a custom Burn event if needed
    }

    /// @dev Internal burning function.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function _burnNTX(address from, uint256 amount) internal {
        require(from != address(0), "Burn from the zero address");
        require(_balances[from] >= amount, "Insufficient balance for burn");
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }

    /// @dev Internal function to transfer NTX tokens. Used within staking/withdrawal logic.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    function _transferNTX(address from, address to, uint256 amount) internal {
         require(from != address(0), "Transfer from the zero address");
         require(to != address(0), "Transfer to the zero address");
         require(_balances[from] >= amount, "Insufficient balance for transfer");

         _balances[from] = _balances[from].sub(amount);
         _balances[to] = _balances[to].add(amount);
         // Could emit a custom Transfer event if needed
    }

    /// @dev Returns the balance of NTX for a specific user.
    /// @param user The address to query balance for.
    /// @return The user's balance.
    function balanceOfNTX(address user) public view returns (uint256) {
        return _balances[user];
    }

    /// @dev Returns the total supply of NTX tokens.
    /// @return The total supply.
    function totalSupplyNTX() public view returns (uint256) {
        return _totalSupply;
    }

    // --- 11. Claim Management Functions ---

    /// @dev Proposes a new verifiable claim.
    /// @param description A detailed description of the claim and expected outcomes.
    /// @param resolutionTime The timestamp by which the claim should be resolvable.
    /// @param oracleIdentifier An identifier specifying the type of oracle data needed for resolution.
    /// @return The ID of the newly created claim.
    function proposeClaim(string calldata description, uint256 resolutionTime, string calldata oracleIdentifier)
        external
        whenNotPaused
        returns (uint256)
    {
        require(resolutionTime > block.timestamp, "Resolution time must be in the future");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(oracleIdentifier).length > 0, "Oracle identifier cannot be empty");

        _claimIds.increment();
        uint256 newClaimId = _claimIds.current();

        Claim storage newClaim = claims[newClaimId];
        newClaim.id = newClaimId;
        newClaim.proposer = msg.sender;
        newClaim.description = description;
        newClaim.proposalTimestamp = block.timestamp;
        newClaim.resolutionTime = resolutionTime;
        newClaim.oracleIdentifier = oracleIdentifier;
        newClaim.resolved = false;
        newClaim.finalOutcome = 0; // 0 indicates unresolved

        activeClaimIds.push(newClaimId);

        emit ClaimProposed(newClaimId, msg.sender, description, resolutionTime, oracleIdentifier);
        return newClaimId;
    }

    /// @dev Stakes NTX tokens on a specific outcome of a claim.
    /// @param claimId The ID of the claim to stake on.
    /// @param outcome The chosen outcome (e.g., 1 for True, 2 for False).
    /// @param amount The amount of NTX to stake.
    function stakeForClaim(uint256 claimId, uint8 outcome, uint256 amount)
        external
        whenNotPaused
    {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId); // Check if claim exists
        if (claim.resolved) revert ClaimAlreadyResolved(claimId);
        if (block.timestamp >= claim.resolutionTime) revert ResolutionTimePassed(claim.resolutionTime);
        if (outcome == 0 || outcome > 2) revert InvalidOutcome(outcome); // Assuming 1/2 are valid outcomes
        if (amount < _minStakeAmount) revert InsufficientStakeAmount(_minStakeAmount, amount);

        // Check if user already staked on this claim - simplified to allow only one stake per user per claim
        if (claim.stakes[msg.sender].exists) revert StakeAlreadyExists(claimId, msg.sender);

        _transferNTX(msg.sender, address(this), amount); // Transfer NTX to the contract

        UserStake storage userStake = claim.stakes[msg.sender];
        userStake.amount = amount;
        userStake.outcome = outcome;
        userStake.withdrawn = false;
        userStake.exists = true;

        claim.totalStaked = claim.totalStaked.add(amount);
        claim.totalStakedByOutcome[outcome] = claim.totalStakedByOutcome[outcome].add(amount);
        claim.stakers.push(msg.sender); // Add user to the list of stakers

        emit StakeAdded(claimId, msg.sender, outcome, amount);
    }

    /// @dev Allows a user to unstake their NTX from an unresolved claim before resolutionTime.
    ///      Note: This is a simplified example. Real systems might have lock-in periods.
    /// @param claimId The ID of the claim to unstake from.
    function unstakeFromClaim(uint256 claimId)
        external
        whenNotPaused
    {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId);
        if (claim.resolved) revert ClaimAlreadyResolved(claimId);
        if (block.timestamp >= claim.resolutionTime) revert UnstakeNotAllowedYet(claim.resolutionTime);

        UserStake storage userStake = claim.stakes[msg.sender];
        if (!userStake.exists) revert StakeDoesNotExist(claimId, msg.sender);

        uint256 amount = userStake.amount;
        uint8 outcome = userStake.outcome;

        // Transfer NTX back to the user
        _transferNTX(address(this), msg.sender, amount);

        // Update claim state
        claim.totalStaked = claim.totalStaked.sub(amount);
        claim.totalStakedByOutcome[outcome] = claim.totalStakedByOutcome[outcome].sub(amount);

        // Mark stake as removed (cannot simply delete from mapping without breaking iteration potentially)
        delete claim.stakes[msg.sender]; // Safely delete struct from mapping

        // Remove user from stakers list (inefficient for large lists, potential gas issue)
        // A more efficient method would use a mapping to index or not store stakers list on-chain
        for (uint i = 0; i < claim.stakers.length; i++) {
            if (claim.stakers[i] == msg.sender) {
                claim.stakers[i] = claim.stakers[claim.stakers.length - 1];
                claim.stakers.pop();
                break;
            }
        }

        emit StakeRemoved(claimId, msg.sender, amount);
    }


    // --- 12. Oracle Management Functions ---

    /// @dev Registers an address as an oracle. Requires ORACLE_ADMIN_ROLE.
    ///      Requires payment of an oracle registration fee in NTX.
    /// @param oracleAddress The address to register as an oracle.
    /// @param identifier A string identifying the oracle's type or service.
    function registerOracle(address oracleAddress, string calldata identifier)
        external
        onlyRole(ORACLE_ADMIN_ROLE)
        whenNotPaused
    {
        if (registeredOracles[oracleAddress].registered) revert OracleAlreadyRegistered(oracleAddress);
        require(bytes(identifier).length > 0, "Identifier cannot be empty");
        require(balanceOfNTX(msg.sender) >= _oracleRegistrationFee, "Insufficient NTX for registration fee");

        _burnNTX(msg.sender, _oracleRegistrationFee); // Burn registration fee

        registeredOracles[oracleAddress] = Oracle({
            identifier: identifier,
            fee: 0, // Fee set separately
            registered: true
        });
        registeredOracleAddresses.push(oracleAddress);
        _grantRole(ORACLE_ROLE, oracleAddress); // Automatically grant ORACLE_ROLE

        emit OracleRegistered(oracleAddress, identifier);
    }

     /// @dev Unregisters an oracle. Requires ORACLE_ADMIN_ROLE.
     /// @param oracleAddress The address to unregister.
    function unregisterOracle(address oracleAddress)
        external
        onlyRole(ORACLE_ADMIN_ROLE)
        whenNotPaused
    {
        if (!registeredOracles[oracleAddress].registered) revert OracleNotRegistered(oracleAddress);

        // Revoke the oracle role
        _revokeRole(ORACLE_ROLE, oracleAddress);

        // Mark as unregistered (don't delete to preserve history if needed, or handle carefully)
        registeredOracles[oracleAddress].registered = false;
        // Remove from list (inefficient)
        for (uint i = 0; i < registeredOracleAddresses.length; i++) {
             if (registeredOracleAddresses[i] == oracleAddress) {
                 registeredOracleAddresses[i] = registeredOracleAddresses[registeredOracleAddresses.length - 1];
                 registeredOracleAddresses.pop();
                 break;
             }
        }

        // Note: Any pending oracle fees would remain in oracleFeeBalances[oracleAddress] until withdrawn.
        emit OracleUnregistered(oracleAddress);
    }

     /// @dev Sets the fee for a registered oracle. Requires ORACLE_ADMIN_ROLE.
     /// @param oracleAddress The oracle address.
     /// @param fee The fee amount in NTX per successful resolution contribution.
    function setOracleFee(address oracleAddress, uint256 fee)
        external
        onlyRole(ORACLE_ADMIN_ROLE)
        whenNotPaused
    {
        if (!registeredOracles[oracleAddress].registered) revert OracleNotRegistered(oracleAddress);
        registeredOracles[oracleAddress].fee = fee;
        emit OracleFeeSet(oracleAddress, fee);
    }

    /// @dev Gets the registration status and identifier of an oracle.
    /// @param oracleAddress The oracle address.
    /// @return identifier The oracle's identifier string.
    /// @return registered True if the oracle is currently registered.
    function getOracleStatus(address oracleAddress)
        public
        view
        returns (string memory identifier, bool registered)
    {
        Oracle storage oracle = registeredOracles[oracleAddress];
        return (oracle.identifier, oracle.registered);
    }

    /// @dev Returns the list of currently registered oracle addresses.
    ///      Note: This can be expensive if the list is very long.
    /// @return An array of registered oracle addresses.
    function getRegisteredOracles() public view returns (address[] memory) {
        return registeredOracleAddresses;
    }


    // --- 13. Resolution Functions ---

    /// @dev Allows a registered oracle to submit their resolution for a claim.
    ///      Can only be called within a specific time window after resolutionTime.
    /// @param claimId The ID of the claim to resolve.
    /// @param outcome The oracle's determined outcome (1, 2, or potentially 3 for invalid).
    /// @param oracleProof An optional string providing proof or reference for the resolution.
    function submitOracleResolution(uint256 claimId, uint8 outcome, string calldata oracleProof)
        external
        onlyRole(ORACLE_ROLE)
        whenNotPaused
    {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId);
        if (claim.resolved) revert ClaimAlreadyResolved(claimId);
        if (outcome == 0 || outcome > 3) revert InvalidOutcome(outcome); // Allow 3 for Invalid/Cancelled

        // Resolution window: Start after resolutionTime, End example: resolutionTime + 1 day (adjust as needed)
        uint256 resolutionWindowEnd = claim.resolutionTime + 1 days; // Example window
        if (block.timestamp < claim.resolutionTime || block.timestamp > resolutionWindowEnd) {
             revert ClaimNotInResolutionWindow(claimId);
        }

        // Check if oracle is registered and active
        if (!registeredOracles[msg.sender].registered) revert OracleNotRegistered(msg.sender);

        // Check if this oracle has already submitted for this claim
        if (claim.oracleSubmissions[msg.sender].exists) {
            // Could allow updating submission before resolution window ends, but for simplicity, disallow.
            revert("Oracle already submitted for this claim");
        }

        claim.oracleSubmissions[msg.sender] = OracleSubmission({
            outcome: outcome,
            proof: oracleProof,
            timestamp: block.timestamp,
            exists: true
        });
        claim.submittingOracles.push(msg.sender); // Add oracle to the list for this claim

        emit OracleResolutionSubmitted(claimId, msg.sender, outcome, oracleProof);
    }


    /// @dev Triggers the resolution process for a claim based on submitted oracle data.
    ///      Can be called by anyone after the resolution window begins. Incentivized trigger.
    /// @param claimId The ID of the claim to resolve.
    function resolveClaim(uint256 claimId)
        external
        whenNotPaused
    {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId);
        if (claim.resolved) revert ClaimAlreadyResolved(claimId);

        // Resolution window: Check if it's after resolutionTime
         if (block.timestamp < claim.resolutionTime) {
             revert ResolutionPending(claimId); // Not time to resolve yet
         }
         // Also check if still within a reasonable window to trigger resolution?
         // Optional: add an end time like in submitOracleResolution if resolutions must be triggered within a window.

        // Count oracle submissions and check for consensus
        mapping(uint8 => uint256) memory outcomeCounts;
        uint256 validSubmissionCount = 0;
        uint8 consensusOutcome = 0;
        uint256 maxCount = 0;

        // Only count submissions from registered oracles and within the resolution window
        uint256 resolutionWindowEnd = claim.resolutionTime + 1 days; // Match window from submitOracleResolution

        for (uint i = 0; i < claim.submittingOracles.length; i++) {
            address oracleAddress = claim.submittingOracles[i];
            OracleSubmission storage submission = claim.oracleSubmissions[oracleAddress];

            if (submission.exists && registeredOracles[oracleAddress].registered && submission.timestamp >= claim.resolutionTime && submission.timestamp <= resolutionWindowEnd) {
                 outcomeCounts[submission.outcome]++;
                 validSubmissionCount++;

                 if (outcomeCounts[submission.outcome] > maxCount) {
                     maxCount = outcomeCounts[submission.outcome];
                     consensusOutcome = submission.outcome;
                 } else if (outcomeCounts[submission.outcome] == maxCount) {
                     // Handle ties - maybe mark as invalid or require admin intervention
                     // For simplicity, let's say ties result in no consensus / invalid outcome
                     consensusOutcome = 3; // Indicate a tie or no clear majority
                 }
            }
        }

        uint256 requiredOracles = getCurrentResolutionThreshold(); // Get dynamic threshold
        if (validSubmissionCount < requiredOracles) revert NotEnoughOracleSubmissions(requiredOracles, validSubmissionCount);

        uint256 consensusPercentage = validSubmissionCount > 0 ? (maxCount.mul(1000)).div(validSubmissionCount) : 0;

        if (consensusPercentage < _requiredConsensusPermil) {
            // No strong enough consensus - might mark as invalid or require admin review
            consensusOutcome = 3; // Example: Mark as Invalid/Cancelled if consensus % is too low
        }

        if (consensusOutcome == 0) {
             revert OracleConsensusNotReached(); // Should not happen if validSubmissionCount > 0 and no ties/low consensus
        }

        // Set final outcome and mark as resolved
        claim.finalOutcome = consensusOutcome;
        claim.resolved = true;
        claim.resolutionTimestamp = block.timestamp;

        // Move claim from active to resolved list (inefficient for large lists)
        for (uint i = 0; i < activeClaimIds.length; i++) {
             if (activeClaimIds[i] == claimId) {
                 activeClaimIds[i] = activeClaimIds[activeClaimIds.length - 1];
                 activeClaimIds.pop();
                 break;
             }
        }
        resolvedClaimIds.push(claimId);

        // Calculate and distribute rewards/penalties and update reputation
        _distributeStakesAndFees(claimId, consensusOutcome);

        emit ClaimResolved(claimId, consensusOutcome, block.timestamp);
    }

    /// @dev Internal function to handle stake distribution and oracle fees after resolution.
    /// @param claimId The ID of the resolved claim.
    /// @param finalOutcome The determined final outcome.
    function _distributeStakesAndFees(uint256 claimId, uint8 finalOutcome) internal {
        Claim storage claim = claims[claimId];
        uint256 winningStakeTotal = claim.totalStakedByOutcome[finalOutcome];
        uint256 totalStakedOnClaim = claim.totalStaked;
        uint256 stakingFee = totalStakedOnClaim.mul(getCurrentStakingFee()).div(1000); // Fee is in permil

        uint256 totalToDistributeToWinners = totalStakedOnClaim.sub(stakingFee);

        // Distribute winning pool proportionally to winning stakers
        if (winningStakeTotal > 0 && finalOutcome != 0 && finalOutcome != 3) { // If there are winners and outcome is valid
            for (uint i = 0; i < claim.stakers.length; i++) {
                address stakerAddress = claim.stakers[i];
                UserStake storage userStake = claim.stakes[stakerAddress];

                if (userStake.exists && userStake.outcome == finalOutcome) {
                    // Calculate proportional share of the winning pool
                    uint256 payout = userStake.amount.mul(totalToDistributeToWinners).div(winningStakeTotal);
                    // Add payout to user's internal balance. User must withdraw later.
                    _balances[stakerAddress] = _balances[stakerAddress].add(payout);
                    // Note: We don't set userStake.withdrawn = true here. That happens when they call withdrawResolvedStakes.

                    // Update reputation data - Correct prediction
                    userReputationData[stakerAddress].totalCorrectStakeValue =
                        userReputationData[stakerAddress].totalCorrectStakeValue.add(userStake.amount);

                    // Trigger reputation update (can be done lazily or eagerly)
                     updateReputation(stakerAddress); // Eager update example
                } else if (userStake.exists) {
                     // Update reputation data - Incorrect prediction
                    userReputationData[stakerAddress].totalIncorrectStakeValue =
                        userReputationData[stakerAddress].totalIncorrectStakeValue.add(userStake.amount);

                    // Trigger reputation update
                     updateReputation(stakerAddress); // Eager update example
                }
            }
        } else {
             // If finalOutcome is 3 (Invalid/Cancelled) or no winning stakes:
             // Return all staked funds back to users (minus fee or potentially no fee?)
             // Let's return the funds, possibly minus a smaller fee or no fee.
             // Simplified: Return all non-fee funds. Fee might be distributed differently or burned.
            uint256 fundsToReturn = totalStakedOnClaim; // Or totalStakedOnClaim.sub(stakingFee) if fee applies even to invalid
             for (uint i = 0; i < claim.stakers.length; i++) {
                address stakerAddress = claim.stakers[i];
                UserStake storage userStake = claim.stakes[stakerAddress];
                 if (userStake.exists) {
                      // For invalid claims, return the user's original stake amount
                     _balances[stakerAddress] = _balances[stakerAddress].add(userStake.amount);
                     // No reputation update for invalid claims (or adjust logic)
                 }
             }
            // Decide what happens to the stakingFee if claim is invalid. Burn? Send to admin?
            // Example: Burn the fee
            // _burnNTX(address(this), stakingFee); // Requires contract to have balance
        }

        // Pay oracle fees for successful submissions on this claim
        for (uint i = 0; i < claim.submittingOracles.length; i++) {
            address oracleAddress = claim.submittingOracles[i];
            OracleSubmission storage submission = claim.oracleSubmissions[oracleAddress];

            // Check if oracle submission matched the final outcome and was within the window
             uint256 resolutionWindowEnd = claim.resolutionTime + 1 days;
            if (submission.exists && submission.outcome == finalOutcome && submission.timestamp >= claim.resolutionTime && submission.timestamp <= resolutionWindowEnd) {
                uint256 oracleFee = registeredOracles[oracleAddress].fee;
                if (oracleFee > 0) {
                    oracleFeeBalances[oracleAddress] = oracleFeeBalances[oracleAddress].add(oracleFee);
                    // Oracle must withdraw fees later via withdrawOracleFees
                }
            }
        }

         // Any remaining NTX in the claim (e.g., from fee if not burned) stays in the contract
         // or could be sent to a treasury/burned. Simplified: stays in contract for now.
    }

     /// @dev Gets the list of submitted oracle resolutions for a claim.
     /// @param claimId The ID of the claim.
     /// @return An array of tuples containing oracle address, outcome, and timestamp.
    function getClaimResolutionDetails(uint256 claimId)
        public
        view
        returns (tuple(address oracle, uint8 outcome, uint256 timestamp)[] memory)
    {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId);

        tuple(address oracle, uint8 outcome, uint256 timestamp)[] memory details =
            new tuple(address oracle, uint8 outcome, uint256 timestamp)[claim.submittingOracles.length];

        uint256 count = 0;
        uint256 resolutionWindowEnd = claim.resolutionTime + 1 days;

        for(uint i = 0; i < claim.submittingOracles.length; i++) {
            address oracleAddress = claim.submittingOracles[i];
            OracleSubmission storage submission = claim.oracleSubmissions[oracleAddress];
             // Only include valid, registered submissions within the window
            if (submission.exists && registeredOracles[oracleAddress].registered && submission.timestamp >= claim.resolutionTime && submission.timestamp <= resolutionWindowEnd) {
                 details[count] = tuple(oracleAddress, submission.outcome, submission.timestamp);
                 count++;
             }
        }

        // Resize array if some submissions were filtered out (e.g., from unregistered oracles)
        if (count < details.length) {
            tuple(address oracle, uint8 outcome, uint256 timestamp)[] memory filteredDetails =
                new tuple(address oracle, uint8 outcome, uint256 timestamp)[count];
            for(uint i = 0; i < count; i++) {
                filteredDetails[i] = details[i];
            }
            return filteredDetails;
        }

        return details;
    }


    // --- 14. Reputation System Functions ---

    /// @dev Triggers an update of the user's reputation score based on their prediction history.
    ///      Can be called by the user themselves or via an automated process.
    ///      Note: This is a simplified calculation. A real system might iterate history.
    ///      Here, we assume userReputationData is updated during claim resolution.
    /// @param user The address of the user to update.
    function updateReputation(address user) public whenNotPaused {
         // Recalculate score based on current totalCorrectStakeValue and totalIncorrectStakeValue
         // This could be more complex, e.g., decay over time, factor in number of claims, etc.
         uint256 currentReputationScore = _calculateReputationScore(userReputationData[user]);
         // We don't store the calculated score explicitly in UserReputation struct in this example,
         // but calculate it dynamically. However, an event is useful.
         emit ReputationUpdated(user, currentReputationScore);
    }

    /// @dev Internal pure function to calculate a reputation score from raw data.
    /// @param data The UserReputation struct for the user.
    /// @return The calculated reputation score.
    function _calculateReputationScore(UserReputation storage data) internal view returns (uint256) {
        uint256 correct = data.totalCorrectStakeValue;
        uint256 incorrect = data.totalIncorrectStakeValue;
        uint256 total = correct.add(incorrect);

        if (total == 0) {
            return 0; // No prediction history
        }

        // Example formula: (CorrectStake * correctWeight - IncorrectStake * incorrectWeight) / (TotalStake) * some_multiplier
        // Ensure no underflow if incorrect > correct
        int256 weightedCorrect = correct.mul(_correctStakeWeight).toInt256();
        int256 weightedIncorrect = incorrect.mul(_incorrectWeight).toInt256();

        int256 rawScore = weightedCorrect.sub(weightedIncorrect);

        // Normalize and scale. Simple scaling: shift by a base, handle negative scores.
        // Let's ensure score is non-negative for simplicity here.
        // If rawScore is negative, clamp to 0 or use a different base.
        int256 scaledScore = rawScore.div(int256(total)); // Integer division

        // Adjust for the multiplier - simple multiplication
        // Example: scale from -N to +N range, then shift to 0 to MaxRange
        // Let's use a base multiplier to avoid small integer results.
        // Example: Max possible stake value per claim * weight. Let's assume stakes are capped or use total system value.
        // A fixed multiplier works better for score range.
        uint256 reputationMultiplier = getCurrentReputationMultiplier(); // Get dynamic multiplier

        // Simple positive score example: correct / total * multiplier
        uint256 positiveScore = correct.mul(10000).div(total); // Scale to 0-10000
        uint256 finalScore = positiveScore.mul(reputationMultiplier).div(100); // Apply multiplier, scale back

        // A score could also be negative to represent consistently wrong predictions.
        // If using `rawScore`, need to handle negative scores and scale appropriately.
        // For this example, let's simplify and use a ratio approach that stays positive but reflects accuracy.
        // Score = correct / (correct + incorrect) * BaseScoreRange
        uint256 scoreOutOfBase = correct.mul(10000).div(total); // Scale to 0-10000
        uint256 finalScorePositive = scoreOutOfBase.mul(reputationMultiplier).div(100); // Apply multiplier, scale back

        return finalScorePositive; // Example: 0-10000 range initially scaled by multiplier/100
    }


    /// @dev Gets the current calculated reputation score for a user.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) public view returns (uint256) {
         return _calculateReputationScore(userReputationData[user]);
    }

    /// @dev Gets a list of addresses with the highest reputation scores.
    ///      Note: This function is highly inefficient for large numbers of users.
    ///      In a real application, this would likely be done off-chain or with a dedicated
    ///      on-chain data structure optimized for ranking (e.g., a sorted list updated incrementally).
    ///      This is a simplified placeholder. It just returns a static placeholder array.
    /// @param count The number of top predictors to return.
    /// @return An array of addresses.
    function getTopPredictors(uint256 count) public view returns (address[] memory) {
        // This implementation is a placeholder due to gas costs of sorting/iterating all users.
        // A practical solution requires off-chain processing or a more advanced on-chain pattern.
        count = count; // Silence compiler warning
        return new address[](0); // Return empty array as placeholder
        // A real implementation would need to iterate over all users, calculate reputation, and sort.
        // Consider keeping a smaller, manually updated list or integrating with a layer 2 solution.
    }


    // --- 15. Dynamic Parameter Functions ---

    /// @dev Sets parameters used to calculate the current staking fee. Requires ADMIN_ROLE.
    ///      The current fee is calculated based on these parameters and potentially system state.
    /// @param baseFeePermil The base fee rate in permil (parts per 1000).
    /// @param accuracyImpactPermil How much overall system accuracy impacts the fee multiplier (e.g., higher accuracy lowers fee).
    function updateStakingFeeParameters(uint256 baseFeePermil, uint256 accuracyImpactPermil)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _baseStakingFeePermil = baseFeePermil;
        _accuracyImpactPermil = accuracyImpactPermil;
        emit DynamicParametersUpdated("StakingFee", baseFeePermil, accuracyImpactPermil);
    }

    /// @dev Sets parameters used to calculate the minimum number of oracles and consensus percentage required for resolution. Requires ADMIN_ROLE.
    /// @param minOracles The minimum number of distinct oracle submissions required.
    /// @param consensusPermil The percentage (in permil) of submitted oracles that must agree.
    function updateResolutionThresholdParameters(uint256 minOracles, uint256 consensusPermil)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        require(consensusPermil <= 1000, "Consensus permil cannot exceed 1000 (100%)");
        _minRequiredOracles = minOracles;
        _requiredConsensusPermil = consensusPermil;
        emit DynamicParametersUpdated("ResolutionThreshold", minOracles, consensusPermil);
    }

    /// @dev Sets parameters used in reputation score calculation weights. Requires ADMIN_ROLE.
    /// @param correctStakeWeight The weight for correct predictions.
    /// @param incorrectStakeWeight The weight for incorrect predictions.
    function updateReputationMultiplierParameters(uint256 correctStakeWeight, uint256 incorrectStakeWeight)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _correctStakeWeight = correctStakeWeight;
        _incorrectStakeWeight = incorrectStakeWeight;
        emit DynamicParametersUpdated("ReputationWeights", correctStakeWeight, incorrectStakeWeight);
    }

    /// @dev Calculates the current staking fee rate in permil (parts per 1000).
    ///      This value is dynamic based on admin parameters and could also factor in
    ///      system-wide metrics (e.g., average prediction accuracy, total volume - though calculating these on-chain is complex).
    ///      Simplified: Currently just returns the base fee adjusted slightly based on a fictional system metric.
    /// @return The current staking fee rate in permil.
    function getCurrentStakingFee() public view returns (uint256) {
         // Example dynamic calculation: Base fee + penalty based on low *system-wide* accuracy (placeholder)
         // In a real system, `_getSystemAccuracy()` would be a complex function or rely on aggregated data.
         // For now, it's just _baseStakingFeePermil. Add complexity here later if needed.
         // uint256 systemAccuracy = _getSystemAccuracy(); // (e.g., 0-10000 scale)
         // uint256 accuracyPenalty = (10000 - systemAccuracy).mul(_accuracyImpactPermil).div(10000); // Max penalty when accuracy is 0
         // return _baseStakingFeePermil.add(accuracyPenalty);
         return _baseStakingFeePermil; // Simplified for example
    }

    /// @dev Calculates the current required number of unique oracle submissions for resolution.
    /// @return The minimum required number of unique oracle submissions.
    function getCurrentResolutionThreshold() public view returns (uint256) {
        // Could become dynamic based on value staked on claim, number of registered oracles, etc.
        // Simplified: Returns the base minimum required oracles.
        return _minRequiredOracles;
    }

     /// @dev Calculates the current multiplier used in the reputation score calculation.
     /// @return The multiplier value.
    function getCurrentReputationMultiplier() public view returns (uint256) {
         // Could be dynamic based on total protocol activity, time elapsed, etc.
         // Simplified: Returns a fixed base multiplier. Let's use 100 as a base for scaling.
         return 100; // Example: A base to scale the calculated score (0-100 range -> 0-10000 using 100x)
    }


    // --- 16. Withdrawal Functions ---

    /// @dev Allows a user to withdraw their winning stake amount after a claim is resolved.
    ///      Funds are moved from the contract's internal balance back to the user's internal balance.
    /// @param claimId The ID of the resolved claim.
    function withdrawResolvedStakes(uint256 claimId) external whenNotPaused {
        Claim storage claim = claims[claimId];
        if (claim.id == 0) revert ClaimNotFound(claimId);
        if (!claim.resolved) revert ResolutionPending(claimId);

        UserStake storage userStake = claim.stakes[msg.sender];
        if (!userStake.exists) revert StakeDoesNotExist(claimId, msg.sender);
        if (userStake.withdrawn) revert("Stake already withdrawn");

        // Check if the user's staked outcome was the winning outcome or if claim was invalid/cancelled
        bool userWon = (claim.finalOutcome != 0 && claim.finalOutcome == userStake.outcome);
        bool claimInvalid = (claim.finalOutcome == 3);

        uint256 amountToWithdraw = 0;

        if (userWon) {
            // Recalculate payout amount based on final pool and user's share
            uint256 winningStakeTotal = claim.totalStakedByOutcome[claim.finalOutcome];
             uint256 totalStakedOnClaim = claim.totalStaked;
             uint256 stakingFee = totalStakedOnClaim.mul(getCurrentStakingFee()).div(1000);
             uint256 totalToDistributeToWinners = totalStakedOnClaim.sub(stakingFee);

            if (winningStakeTotal > 0) { // Should be > 0 if there are winners
                 amountToWithdraw = userStake.amount.mul(totalToDistributeToWinners).div(winningStakeTotal);
            } else {
                 // This case should not happen if userWon is true and finalOutcome is valid.
                 // If it somehow does, return their original stake? Let's revert for safety.
                 revert("Error calculating payout");
            }
        } else if (claimInvalid) {
             // Return original stake amount if the claim was invalid/cancelled
            amountToWithdraw = userStake.amount;
        } else {
             // User lost - amountToWithdraw is 0. But we still mark as withdrawn to prevent future attempts.
            amountToWithdraw = 0; // User loses stake
             // The user's stake amount remains in the contract, becoming part of the fee pool / burnt value
             // or potentially distributed to oracle/treasury depending on the fee model.
        }

         userStake.withdrawn = true; // Mark as withdrawn regardless of payout amount

        if (amountToWithdraw > 0) {
             // Transfer the calculated amount from contract balance to user's internal balance
            _transferNTX(address(this), msg.sender, amountToWithdraw);
        }

        emit StakeWithdrawn(claimId, msg.sender, amountToWithdraw);
    }

    /// @dev Allows a registered oracle to withdraw their accumulated fees.
    function withdrawOracleFees() external whenNotPaused {
         if (!registeredOracles[msg.sender].registered) revert OracleNotRegistered(msg.sender);

        uint256 amount = oracleFeeBalances[msg.sender];
        if (amount == 0) revert OracleHasNoFeesToWithdraw();

        oracleFeeBalances[msg.sender] = 0; // Reset balance before transferring

        _transferNTX(address(this), msg.sender, amount);

        emit OracleFeesWithdrawn(msg.sender, amount);
    }


    // --- 17. Admin/Protocol Settings Functions ---

    /// @dev Sets the minimum amount of NTX required to stake on a claim. Requires ADMIN_ROLE.
    /// @param amount The new minimum stake amount.
    function setMinStakeAmount(uint256 amount) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _minStakeAmount = amount;
    }

    /// @dev Sets the fee required to register as an oracle. Requires ADMIN_ROLE.
    /// @param fee The new registration fee amount in NTX.
    function setOracleRegistrationFee(uint256 fee) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _oracleRegistrationFee = fee;
    }


    // --- 18. View/Query Functions ---

    /// @dev Gets the final outcome of a resolved claim.
    /// @param claimId The ID of the claim.
    /// @return The final outcome (0: Unresolved, 1: True, 2: False, 3: Invalid/Cancelled).
    function getClaimOutcome(uint256 claimId) public view returns (uint8) {
        Claim storage claim = claims[claimId];
         if (claim.id == 0) revert ClaimNotFound(claimId);
        return claim.finalOutcome;
    }

    /// @dev Gets the total staked amounts per outcome for a claim.
    /// @param claimId The ID of the claim.
    /// @return An array containing total staked for outcome 1, 2, etc.
    function getClaimStakeSummary(uint256 claimId) public view returns (uint256[] memory) {
        Claim storage claim = claims[claimId];
         if (claim.id == 0) revert ClaimNotFound(claimId);
        // Assuming outcomes 1 and 2 are the main ones, and possibly 3 for invalid stakes if allowed.
        // This needs to match the outcomes logic used in stakeForClaim and resolveClaim.
        // Let's return an array where index 0 is for outcome 1, index 1 for outcome 2 etc.
        // The mapping totalStakedByOutcome uses outcome uint8 as key directly.
        uint8 maxOutcome = 3; // Assuming outcomes 1, 2, 3 possible
        uint256[] memory summary = new uint256[](maxOutcome);
        for(uint8 i = 1; i <= maxOutcome; i++) {
            summary[i-1] = claim.totalStakedByOutcome[i];
        }
        return summary;
    }

    /// @dev Gets the details of a claim.
    /// @param claimId The ID of the claim.
    /// @return A tuple containing claim details.
    function getClaimDetails(uint256 claimId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 proposalTimestamp,
            uint256 resolutionTime,
            string memory oracleIdentifier,
            bool resolved,
            uint8 finalOutcome,
            uint256 resolutionTimestamp,
            uint256 totalStaked
        )
    {
        Claim storage claim = claims[claimId];
         if (claim.id == 0) revert ClaimNotFound(claimId);

        return (
            claim.id,
            claim.proposer,
            claim.description,
            claim.proposalTimestamp,
            claim.resolutionTime,
            claim.oracleIdentifier,
            claim.resolved,
            claim.finalOutcome,
            claim.resolutionTimestamp,
            claim.totalStaked
        );
    }

     /// @dev Gets the stake details for a specific user on a claim.
     /// @param claimId The ID of the claim.
     /// @param user The address of the user.
     /// @return amount The amount staked.
     /// @return outcome The staked outcome.
     /// @return withdrawn Whether the stake has been withdrawn.
     /// @return exists Whether a stake exists for this user on this claim.
    function getUserStakeOnClaim(uint256 claimId, address user)
        public
        view
        returns (uint256 amount, uint8 outcome, bool withdrawn, bool exists)
    {
        Claim storage claim = claims[claimId];
         if (claim.id == 0) revert ClaimNotFound(claimId);
        UserStake storage userStake = claim.stakes[user];
        return (userStake.amount, userStake.outcome, userStake.withdrawn, userStake.exists);
    }


     /// @dev Returns the list of IDs for claims that are not yet resolved.
     ///      Note: This can be expensive for very large lists.
     /// @return An array of claim IDs.
    function listActiveClaims() public view returns (uint256[] memory) {
        return activeClaimIds;
    }

     /// @dev Returns the list of IDs for claims that have been resolved.
     ///      Note: This can be expensive for very large lists.
     /// @return An array of claim IDs.
    function listResolvedClaims() public view returns (uint256[] memory) {
        return resolvedClaimIds;
    }

     /// @dev Returns the token name.
    function name() public pure returns (string memory) {
        return NTX_NAME;
    }

    /// @dev Returns the token symbol.
    function symbol() public pure returns (string memory) {
        return NTX_SYMBOL;
    }

    /// @dev Returns the number of decimals the token uses.
    function decimals() public pure returns (uint8) {
        return NTX_DECIMALS;
    }

    // Example function for initial NTX distribution (Admin only)
    /// @dev Mints initial NTX supply for a user. Callable only by ADMIN_ROLE.
    ///      Used for initial token distribution.
    /// @param to The address to mint tokens for.
    /// @param amount The amount of tokens to mint.
    function initialMint(address to, uint256 amount) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _mintNTX(to, amount);
    }
}
```