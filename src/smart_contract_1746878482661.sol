Okay, here is a smart contract in Solidity implementing a conceptual "Dynamic Ecosystem DAO" (DEDAO). It combines several advanced and trendy concepts like dynamic parameters, oracle interaction simulation, quadratic staking, unique governance mechanics, and non-transferable "achievement tokens" (SBT-like).

It aims for complexity and creativity by integrating these features into a single system, rather than just implementing standard patterns.

**Disclaimer:** This is a conceptual contract for demonstration. It contains simplified implementations of complex ideas (like randomness, oracle interaction, and governance execution) and does not include production-level error handling, gas optimization, or security audits. Deploying such a complex system requires significant testing and auditing.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CONTRACT OUTLINE: DynamicEcosystemDAO ---
//
// 1.  State Variables & Data Structures: Core parameters, participant data,
//     governance proposals, achievement tracking.
// 2.  Events: Signaling key state changes and actions.
// 3.  Error Handling: Custom errors for clarity.
// 4.  Modifiers: Access control for specific roles (Owner, Oracle, Governor).
// 5.  Constructor: Initializes the contract with owner, oracle, and initial params.
// 6.  Participant Management: Registration and fetching participant data.
// 7.  Staking & Yield: Linear and Quadratic staking mechanisms, yield calculation and claiming.
// 8.  Dynamic State & Oracle: Updating ecosystem health based on oracle input.
// 9.  Fees & Treasury: Dynamic fee calculation, depositing native/token assets, distributing fees, requesting funds.
// 10. Governance: Proposal creation for parameter changes, voting, execution with dynamic quorum based on voting power.
// 11. Achievements (SBT-like): Minting and revoking non-transferable achievements.
// 12. Environmental Events: Simulated random event triggering (requires external randomness like Chainlink VRF in production).
// 13. View Functions: Retrieving various state details.

// --- FUNCTION SUMMARY ---
//
// Participant Management:
// 1.  registerParticipant() external: Registers the caller as a participant.
// 2.  grantReputation(address _participant, uint256 _amount) external onlyGovernor: Grants reputation to a participant.
// 3.  getParticipantData(address _participant) external view returns (ParticipantData memory): Retrieves a participant's detailed data.
// 4.  getParticipantCount() external view returns (uint256): Returns the total number of registered participants.
//
// Staking & Yield:
// 5.  stakeTokens(uint256 _amount) external: Stakes tokens (simulated) linearly, adding to total staked amount.
// 6.  unstakeTokens(uint256 _amount) external: Unstakes linearly staked tokens.
// 7.  initiateQuadraticStake(uint256 _amount) external: Stakes tokens (simulated) quadratically, adding to quadratic power.
// 8.  unstakeQuadratic(uint256 _amount) external: Unstakes quadratically staked tokens.
// 9.  claimYield() external: Claims accumulated yield based on combined staking power, reputation, and health.
// 10. viewCalculatedYield(address _participant) external view returns (uint256): Calculates and returns potential yield for a participant without claiming.
// 11. getTotalStakedAmount() external view returns (uint256): Returns the total amount of linearly staked tokens.
// 12. getTotalQuadraticStakeAmount() external view returns (uint256): Returns the total amount of quadratically staked tokens.
// 13. getTotalQuadraticStakePower() external view returns (uint256): Returns the sum of quadratic power from all participants.
//
// Dynamic State & Oracle:
// 14. updateEcosystemHealth(uint256 _newHealth) external onlyOracle: Updates the core ecosystem health parameter (simulated oracle callback).
// 15. getEcosystemHealth() external view returns (uint256): Returns the current ecosystem health value.
//
// Fees & Treasury:
// 16. calculateDynamicFee(uint256 _amount) external view returns (uint256): Calculates the fee based on the current dynamic rate and ecosystem health.
// 17. depositNativeAssets() external payable: Allows depositing native currency (e.g., Ether) into the contract treasury.
// 18. depositTokenAssets(address _token, uint256 _amount) external: Allows depositing specified ERC20 tokens into the treasury.
// 19. distributeProtocolFees() external: Distributes collected fees to participants (simulated distribution logic).
// 20. requestFundsFromReserve(uint256 _amount, string calldata _reason) external onlyGovernor: Allows governors to request funds from the native asset treasury.
// 21. getReserveBalanceNative() external view returns (uint256): Returns the native asset balance in the treasury.
// 22. getReserveBalanceToken(address _token) external view returns (uint256): Returns the balance of a specific token in the treasury.
//
// Governance:
// 23. proposeParameterChange(string calldata _parameterKey, uint256 _newValue) external onlyRegistered: Creates a proposal to change a system parameter.
// 24. voteOnProposal(uint256 _proposalId, bool _support) external onlyRegistered: Casts a vote on an active proposal.
// 25. executeProposal(uint256 _proposalId) external: Executes an approved proposal.
// 26. getProposalState(uint256 _proposalId) external view returns (ProposalState): Returns the current state of a proposal.
// 27. getCurrentQuorumRequirement() external view returns (uint256): Calculates the current dynamic quorum required for proposals.
//
// Achievements (SBT-like):
// 28. mintAchievementToken(address _participant, uint256 _achievementId) external onlyGovernor: Mints a non-transferable achievement token for a participant.
// 29. revokeAchievement(address _participant, uint256 _achievementId) external onlyGovernor: Revokes an achievement token from a participant.
// 30. getAchievementStatus(address _participant, uint256 _achievementId) external view returns (bool): Checks if a participant holds a specific achievement.
//
// Environmental Events:
// 31. triggerEnvironmentalEvent(uint256 _simulatedRandomness) external onlyOracle: Triggers a simulated environmental event affecting ecosystem health/yield.
// 32. getLastEnvironmentalEventOutcome() external view returns (uint256): Returns the outcome of the last triggered environmental event.

// --- Placeholder for ERC20 interface ---
// (In a real scenario, this would be imported or defined separately)
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract DynamicEcosystemDAO {

    // --- State Variables ---

    address public owner; // Contract owner (can delegate governor role)
    address public oracleAddress; // Address authorized to update ecosystem health/events
    address[] public governors; // Addresses with governor privileges (can be updated via governance)

    // Core dynamic parameters (initially set, changeable via governance)
    uint256 public ecosystemHealth; // Scale: 0 to 10000 (representing 0% to 100%)
    uint256 public baseProtocolFeeRate; // in basis points (e.g., 100 = 1%)
    uint256 public healthInfluenceOnFee; // Multiplier for health impact on fee
    uint256 public governanceVotingPeriod; // in seconds
    uint256 public quorumBasePercentage; // Base quorum % of total voting power (e.g., 500 = 5%)
    uint256 public quorumReputationBonus; // Bonus quorum % per 1000 reputation points

    uint256 public totalStakedAmount; // Total linear staked tokens
    uint256 public totalQuadraticStakeAmount; // Total quadratic staked tokens (raw amount)
    uint256 public totalQuadraticStakePower; // Sum of sqrt(amount) for quadratic stakes

    uint256 public nextParticipantId; // Counter for participant IDs
    uint256 public nextProposalId; // Counter for proposal IDs
    uint256 public lastEnvironmentalEventOutcome; // Stores the outcome of the last triggered event

    // --- Data Structures ---

    struct ParticipantData {
        uint256 id;
        uint256 reputation; // Can be granted, affects yield & quorum influence
        uint256 stakedTokens; // Linear stake
        uint256 quadraticStakedTokens; // Quadratic stake (raw amount)
        mapping(uint256 => bool) achievements; // Achievement ID => Held status (SBT-like)
        uint256 lastYieldClaimTime; // Timestamp of last yield claim
    }

    mapping(address => ParticipantData) public participants;
    mapping(address => bool) public isParticipantRegistered;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        string parameterKey; // Key identifier for the parameter to change
        uint256 newValue; // The proposed new value
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalVotingPower; // Total voting power at proposal creation
        uint256 votesFor; // Voting power supporting the proposal
        uint256 votesAgainst; // Voting power against the proposal
        mapping(address => bool) voted; // Track if an address has voted
        ProposalState state;
        string description; // Added for clarity in proposals
    }

    mapping(uint256 => Proposal) public proposals;

    // Mapping for dynamic parameters (string key to uint256 value pointer)
    // This mapping stores *pointers* to state variables that can be changed by governance
    // Note: This is a simplified approach. A more robust system might use a separate storage contract or upgradeable proxies.
    // We'll simulate changing public state variables directly via string key matching.
    mapping(string => bytes32) public governanceParameterPointers; // Maps parameter key string to memory address/pointer (simplified)

    // --- Events ---

    event ParticipantRegistered(address indexed participant, uint256 participantId);
    event ReputationGranted(address indexed participant, uint256 amount);
    event TokensStaked(address indexed participant, uint256 amount, bool quadratic);
    event TokensUnstaked(address indexed participant, uint256 amount, bool quadratic);
    event YieldClaimed(address indexed participant, uint256 amount);
    event EcosystemHealthUpdated(uint256 newHealth);
    event DynamicFeeCalculated(uint256 amount, uint256 feeRate, uint256 calculatedFee);
    event AssetsDeposited(address indexed depositor, uint256 amount, address indexed token);
    event ProtocolFeesDistributed(uint256 totalAmount);
    event FundsRequestedFromReserve(address indexed governor, uint256 amount, string reason);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string parameterKey, uint256 newValue, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event AchievementMinted(address indexed participant, uint256 achievementId);
    event AchievementRevoked(address indexed participant, uint256 achievementId);
    event EnvironmentalEventTriggered(uint256 indexed outcome);

    // --- Error Handling ---

    error AlreadyRegistered();
    error NotRegistered();
    error InsufficientStake();
    error InvalidProposalState();
    error VotingPeriodEnded();
    error AlreadyVoted();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error QuorumNotMet();
    error TokenTransferFailed();
    error InsufficientReserveFunds();
    error InvalidParameterKey();
    error InvalidAchievementId();


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle");
        _;
    }

    modifier onlyGovernor() {
        bool isGov;
        for (uint i = 0; i < governors.length; i++) {
            if (governors[i] == msg.sender) {
                isGov = true;
                break;
            }
        }
        require(isGov, "Only governor");
        _;
    }

    modifier onlyRegistered() {
        if (!isParticipantRegistered[msg.sender]) revert NotRegistered();
        _;
    }

    // --- Constructor ---

    constructor(address _oracle, uint256 _initialHealth) {
        owner = msg.sender;
        oracleAddress = _oracle;
        ecosystemHealth = _initialHealth; // e.g., 5000 for 50%
        baseProtocolFeeRate = 100; // 1%
        healthInfluenceOnFee = 50; // Fee changes by 0.5% for every 10% health change from 50%
        governanceVotingPeriod = 3 days;
        quorumBasePercentage = 500; // 5% of total voting power
        quorumReputationBonus = 10; // 1% bonus quorum per 1000 reputation

        // Register initial governors (can be changed by governance later)
        governors.push(msg.sender); // Owner is initial governor

        nextParticipantId = 1;
        nextProposalId = 1;

        // Map parameter keys to storage locations (simplified simulation)
        // In a real dynamic parameter system, this would need careful consideration of storage layouts or state variables.
        // For this example, we'll *simulate* changing public state variables based on the string key.
        // This mapping isn't strictly used for storage pointers but for lookup in executeProposal.
        // governanceParameterPointers["baseProtocolFeeRate"] = 0; // Placeholder - actual pointer logic is complex
        // governanceParameterPointers["healthInfluenceOnFee"] = 0;
        // governanceParameterPointers["governanceVotingPeriod"] = 0;
        // governanceParameterPointers["quorumBasePercentage"] = 0;
        // governanceParameterPointers["quorumReputationBonus"] = 0;
        // governanceParameterPointers["oracleAddress"] = 0; // Example: change oracle address
    }

    // --- Participant Management ---

    function registerParticipant() external {
        if (isParticipantRegistered[msg.sender]) revert AlreadyRegistered();
        uint256 pId = nextParticipantId++;
        participants[msg.sender].id = pId;
        isParticipantRegistered[msg.sender] = true;
        emit ParticipantRegistered(msg.sender, pId);
    }

    function grantReputation(address _participant, uint256 _amount) external onlyGovernor {
        if (!isParticipantRegistered[_participant]) revert NotRegistered();
        participants[_participant].reputation += _amount;
        emit ReputationGranted(_participant, _amount);
    }

    function getParticipantData(address _participant) external view onlyRegistered returns (ParticipantData memory) {
         // Need to handle the mapping within the struct not being returned directly.
         // Create a temporary struct without the mapping.
         ParticipantData storage p = participants[_participant];
         return ParticipantData({
             id: p.id,
             reputation: p.reputation,
             stakedTokens: p.stakedTokens,
             quadraticStakedTokens: p.quadraticStakedTokens,
             achievements: p.achievements, // Mapping cannot be returned directly
             lastYieldClaimTime: p.lastYieldClaimTime
         });
         // Note: The 'achievements' mapping inside the returned struct will not be accessible
         // from external calls due to EVM limitations on returning mappings. Use getAchievementStatus instead.
    }

     function getParticipantCount() external view returns (uint256) {
        // This is simplified; actual count requires iterating or tracking separately
        // nextParticipantId - 1 gives the count if IDs start from 1 and are sequential
        return nextParticipantId - 1;
    }


    // --- Staking & Yield ---

    function stakeTokens(uint256 _amount) external onlyRegistered {
        // In a real contract, this would involve ERC20 transferFrom
        // IERC20(ecoTokenAddress).transferFrom(msg.sender, address(this), _amount);
        participants[msg.sender].stakedTokens += _amount;
        totalStakedAmount += _amount;
        emit TokensStaked(msg.sender, _amount, false);
    }

    function unstakeTokens(uint256 _amount) external onlyRegistered {
        if (participants[msg.sender].stakedTokens < _amount) revert InsufficientStake();
        participants[msg.sender].stakedTokens -= _amount;
        totalStakedAmount -= _amount;
        // In a real contract, this would involve ERC20 transfer
        // IERC20(ecoTokenAddress).transfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount, false);
    }

    // Quadratic staking: power grows with sqrt(amount)
    // Simplified: Using integer sqrt approximation or a lookup table would be better for gas/precision.
    // Here, we'll just sum the raw amounts and calculate power when needed.
    function initiateQuadraticStake(uint256 _amount) external onlyRegistered {
        // IERC20(ecoTokenAddress).transferFrom(msg.sender, address(this), _amount);
        participants[msg.sender].quadraticStakedTokens += _amount;
        totalQuadraticStakeAmount += _amount;
        // Recalculate total quadratic power (inefficient for many stakers)
        // A better approach tracks individual power and updates incrementally
        // totalQuadraticStakePower = calculateTotalQuadraticPower(); // Avoid in production
        emit TokensStaked(msg.sender, _amount, true);
    }

    function unstakeQuadratic(uint256 _amount) external onlyRegistered {
         if (participants[msg.sender].quadraticStakedTokens < _amount) revert InsufficientStake();
        participants[msg.sender].quadraticStakedTokens -= _amount;
        totalQuadraticStakeAmount -= _amount;
        // Recalculate total quadratic power (inefficient)
        // totalQuadraticStakePower = calculateTotalQuadraticPower(); // Avoid in production
        // IERC20(ecoTokenAddress).transfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount, true);
    }

    // Internal helper for calculating voting/yield power
    function _getParticipantVotingPower(address _participant) internal view returns (uint256) {
        ParticipantData storage p = participants[_participant];
        // Simple combined power: linear stake + sqrt(quadratic stake) + reputation bonus
        // Using integer sqrt for simplicity; real sqrt requires more complex math
        uint256 quadraticPower = uint256(Math.sqrt(p.quadraticStakedTokens));
        uint256 reputationBonusPower = p.reputation / 100; // 1 unit power per 100 reputation
        return p.stakedTokens + quadraticPower + reputationBonusPower;
    }

    // Calculate approximate integer square root using Newton's method
    library Math {
        function sqrt(uint256 y) internal pure returns (uint256 z) {
            if (y > 3) {
                z = y;
                uint256 x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
            // else z = 0
        }
    }

    // Internal helper to calculate total quadratic power (gas intensive if many participants)
    // For a real contract, this would need a different approach or memoization
    function calculateTotalQuadraticPower() internal view returns (uint256) {
        // This is highly inefficient for a large number of participants.
        // In a real system, track participant IDs or use a different data structure.
        // Or update total power incrementally on stake/unstake (requires tracking individual power).
        uint256 totalPower = 0;
        // This loop is for demonstration ONLY and is not suitable for production
        // with a dynamic/large number of participants.
        // Consider using a separate contract to track staking and total power.
        // As a placeholder, we'll just use totalQuadraticStakeAmount and apply sqrt once.
        // This is NOT accurate quadratic summing, just total raw amount.
        // Accurate total quadratic power requires summing sqrt(individual_amount).
        // Let's sum based on the _getParticipantVotingPower logic instead.
        // This requires iterating participants, which is bad.
        // We will *not* implement a working `calculateTotalQuadraticPower` here
        // as it requires iterating a mapping, which is not possible/scalable in Solidity.
        // The state variable `totalQuadraticStakePower` will need to be updated
        // when individual stakes change, which implies tracking individual power.
        // We will leave totalQuadraticStakePower as a conceptual placeholder for now.
        return 0; // Indicate that this function is not functional due to EVM limitations
    }


    // Yield calculation based on various factors
    function _calculateYield(address _participant) internal view returns (uint256) {
        ParticipantData storage p = participants[_participant];
        uint256 votingPower = _getParticipantVotingPower(_participant);
        uint256 timeSinceLastClaim = block.timestamp - p.lastYieldClaimTime;

        // Simulated yield formula: (votingPower * ecosystemHealth * timeSinceLastClaim) / scale_factor
        // Scale factor to control yield amount and prevent overflow
        uint256 scaleFactor = 1e6; // Adjust as needed

        // Example: 1000 voting power, 5000 health (50%), 1 day (86400s)
        // Yield = (1000 * 5000 * 86400) / 1e6 = 432000 units

        uint256 yieldAmount = (votingPower * ecosystemHealth * timeSinceLastClaim) / scaleFactor;

        // Add bonus based on achievements?
        // if (p.achievements[1]) yieldAmount += yieldAmount / 10; // 10% bonus for achievement 1

        return yieldAmount;
    }

    function claimYield() external onlyRegistered {
        uint256 yieldAmount = _calculateYield(msg.sender);
        if (yieldAmount == 0) return;

        // Reset claim time before transferring to prevent reentrancy issues
        participants[msg.sender].lastYieldClaimTime = block.timestamp;

        // In a real contract, transfer yield tokens (or native currency from treasury)
        // bool success = IERC20(ecoTokenAddress).transfer(msg.sender, yieldAmount);
        // require(success, "Yield transfer failed");

        emit YieldClaimed(msg.sender, yieldAmount);
    }

    function viewCalculatedYield(address _participant) external view returns (uint256) {
         if (!isParticipantRegistered[_participant]) revert NotRegistered();
         return _calculateYield(_participant);
    }


    function getTotalStakedAmount() external view returns (uint256) {
        return totalStakedAmount;
    }

     function getTotalQuadraticStakeAmount() external view returns (uint256) {
        return totalQuadraticStakeAmount;
    }

    function getTotalQuadraticStakePower() external view returns (uint256) {
         // As noted, this is a placeholder. Summing sqrt(individual_stake) requires iterating.
         // This function *should* return the sum of Math.sqrt(participant.quadraticStakedTokens) for all participants.
         // Calculating this on-chain is not scalable.
         // Returning a simple metric for now.
         return uint256(Math.sqrt(totalQuadraticStakeAmount)); // Very rough approximation!
    }


    // --- Dynamic State & Oracle ---

    function updateEcosystemHealth(uint256 _newHealth) external onlyOracle {
        require(_newHealth <= 10000, "Health out of bounds");
        ecosystemHealth = _newHealth;
        emit EcosystemHealthUpdated(ecosystemHealth);
    }

    function getEcosystemHealth() external view returns (uint256) {
        return ecosystemHealth;
    }

    // --- Fees & Treasury ---

    function calculateDynamicFee(uint256 _amount) external view returns (uint256) {
        // Fee rate adjusted based on ecosystem health
        // Example: Fee increases if health is low, decreases if health is high
        // Base fee: baseProtocolFeeRate (e.g., 100 = 1%)
        // Health effect: For every 1% health below 50%, fee increases by healthInfluenceOnFee/100 bps
        //                For every 1% health above 50%, fee decreases by healthInfluenceOnFee/100 bps

        int256 healthDeviationFrom50 = int256(ecosystemHealth) - 5000; // 5000 is 50%
        // Calculate fee adjustment: deviation_percentage * healthInfluenceOnFee
        // deviation_percentage = healthDeviationFrom50 / 100 (since health is 0-10000 scale)
        int256 feeAdjustment = (healthDeviationFrom50 * int256(healthInfluenceOnFee)) / 100; // Adjustment in bps

        // Dynamic fee rate = baseProtocolFeeRate - feeAdjustment
        // Ensure fee rate is non-negative
        int256 currentFeeRate = int256(baseProtocolFeeRate) - feeAdjustment;
        if (currentFeeRate < 0) {
            currentFeeRate = 0;
        }
         if (currentFeeRate > 10000) { // Cap fee rate at 100%
             currentFeeRate = 10000;
         }


        uint256 feeAmount = (_amount * uint256(currentFeeRate)) / 10000; // Divide by 10000 for basis points

        emit DynamicFeeCalculated(_amount, uint256(currentFeeRate), feeAmount);
        return feeAmount;
    }

    // Allows users/protocols to send native assets (like ETH) to the treasury
    receive() external payable {
        emit AssetsDeposited(msg.sender, msg.value, address(0)); // address(0) signifies native asset
    }

     function depositNativeAssets() external payable {
         emit AssetsDeposited(msg.sender, msg.value, address(0)); // address(0) signifies native asset
     }

    // Allows users/protocols to send ERC20 assets to the treasury
    function depositTokenAssets(address _token, uint256 _amount) external {
        // In a real contract, this requires the contract to have been approved
        // to spend the user's tokens *before* calling this function.
        IERC20 token = IERC20(_token);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TokenTransferFailed();
        emit AssetsDeposited(msg.sender, _amount, _token);
    }


    // Placeholder for fee distribution logic - could distribute to stakers, treasury, burn, etc.
    function distributeProtocolFees() external {
        // This function would collect fees held by the contract (requires tracking fee revenue)
        // and distribute them based on protocol logic.
        // For demonstration, we'll just emit an event and assume some logic happens.
        // uint256 totalFeesCollected = ... ; // Need state to track collected fees
        // uint256 amountDistributed = totalFeesCollected; // Distribute all collected fees

        // Example: Transfer a portion to stakers, portion to treasury
        // uint256 stakerShare = amountDistributed / 2;
        // uint256 treasuryShare = amountDistributed - stakerShare;

        // // Distribute stakerShare amongst active stakers (requires iteration - complex)
        // // ...

        // // Keep treasuryShare in the contract

        emit ProtocolFeesDistributed(0); // Emitting 0 for now as actual tracking/distribution is complex
    }

    // Governor-approved withdrawal from the native asset treasury
    function requestFundsFromReserve(uint256 _amount, string calldata _reason) external onlyGovernor {
        if (address(this).balance < _amount) revert InsufficientReserveFunds();
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert InsufficientReserveFunds(); // Or a more specific error like TransferFailed
        emit FundsRequestedFromReserve(msg.sender, _amount, _reason);
    }


     function getReserveBalanceNative() external view returns (uint256) {
         return address(this).balance;
     }

     function getReserveBalanceToken(address _token) external view returns (uint256) {
          return IERC20(_token).balanceOf(address(this));
     }


    // --- Governance ---

    function proposeParameterChange(string calldata _parameterKey, uint256 _newValue) external onlyRegistered {
        uint256 proposalId = nextProposalId++;
        uint256 totalPowerAtCreation = _getParticipantVotingPower(msg.sender); // Or calculate total active power?
        // For simplicity, totalPowerAtCreation uses the proposer's power.
        // A real system would calculate the sum of voting power of *all* active participants
        // at the moment of proposal creation. This is hard without iterating.
        // Let's use total quadratic stake power (as a proxy for active community size).
         totalPowerAtCreation = getTotalQuadraticStakePower(); // Still not perfect, but better proxy

        proposals[proposalId] = Proposal({
            id: proposalId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingPeriod,
            totalVotingPower: totalPowerAtCreation, // Total potential voting power (proxy)
            votesFor: 0,
            votesAgainst: 0,
            voted: abi.Scripted{}, // Initialize mapping
            state: ProposalState.Active,
            description: string(abi.encodePacked("Change ", _parameterKey, " to ", Strings.toString(_newValue))) // Auto-generate description
        });

        emit ProposalCreated(proposalId, msg.sender, _parameterKey, _newValue, proposals[proposalId].description);
    }

     // Helper library for uint to string conversion
     library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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
    }


    function voteOnProposal(uint256 _proposalId, bool _support) external onlyRegistered {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp > proposal.votingEndTime) revert VotingPeriodEnded();
        if (proposal.voted[msg.sender]) revert AlreadyVoted();

        uint256 votingPower = _getParticipantVotingPower(msg.sender);
        require(votingPower > 0, "Participant has no voting power");

        proposal.voted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        // Check if quorum is met implicitly during voting or only on execution?
        // Let's check outcome status based on votes.
        _checkProposalOutcome(proposalId);

        emit Voted(_proposalId, msg.sender, _support, votingPower);
    }

    // Internal function to check proposal outcome after a vote
    function _checkProposalOutcome(uint256 _proposalId) internal {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.state != ProposalState.Active) return;

         // Check if voting period ended
         if (block.timestamp > proposal.votingEndTime) {
             // Check if succeeded: More votesFor than votesAgainst AND Quorum Met
             uint256 requiredQuorum = getCurrentQuorumRequirement(); // Dynamic quorum!
             uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;

             if (proposal.votesFor > proposal.votesAgainst && totalVotesCast >= requiredQuorum) {
                 proposal.state = ProposalState.Succeeded;
                 emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
             } else {
                 proposal.state = ProposalState.Failed;
                 emit ProposalStateChanged(_proposalId, ProposalState.Failed);
             }
         } else {
            // Voting still active, state remains Active
         }
    }


    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state == ProposalState.Active) {
             // Voting period might have just ended, evaluate outcome first
            _checkProposalOutcome(_proposalId);
        }

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotSucceeded();
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();


        // --- Execute the parameter change ---
        // This part simulates updating state variables based on the parameterKey string.
        // This is complex and prone to errors/security risks in a real contract.
        // Using a simple if/else or switch based on string is inefficient.
        // A better approach involves storing parameters in a central mapping or using proxies.
        // For demonstration, we'll use a simple if-else structure.

        bytes memory keyBytes = bytes(proposal.parameterKey);

        if (keccak256(keyBytes) == keccak256("baseProtocolFeeRate")) {
            baseProtocolFeeRate = proposal.newValue;
        } else if (keccak256(keyBytes) == keccak256("healthInfluenceOnFee")) {
            healthInfluenceOnFee = proposal.newValue;
        } else if (keccak256(keyBytes) == keccak256("governanceVotingPeriod")) {
            governanceVotingPeriod = proposal.newValue;
        } else if (keccak256(keyBytes) == keccak256("quorumBasePercentage")) {
             quorumBasePercentage = proposal.newValue;
        } else if (keccak256(keyBytes) == keccak256("quorumReputationBonus")) {
             quorumReputationBonus = proposal.newValue;
        } else if (keccak256(keyBytes) == keccak256("oracleAddress")) {
             // This requires careful type handling (uint256 newValue to address)
             // And potentially access control/multi-sig for critical roles
             // For simplicity, we won't allow changing address parameters this way in this example.
             revert InvalidParameterKey(); // Indicate this key is not directly changeable via uint256 newValue
        }
        // Add more parameters here as needed

        else {
            revert InvalidParameterKey(); // Parameter key not recognized for execution
        }

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
        emit ProposalExecuted(_proposalId, proposal.parameterKey, proposal.newValue);
    }

    // Dynamic Quorum Calculation: Based on a percentage of total potential voting power
    // and potentially influenced by average reputation or other factors.
    function getCurrentQuorumRequirement() public view returns (uint256) {
        // Quorum = (totalQuadraticStakePower * quorumBasePercentage / 10000) + (averageReputation / 1000 * quorumReputationBonus * totalQuadraticStakePower / 10000)
        // Average reputation calculation is hard on-chain. Let's simplify.
        // Quorum = (Total Voting Power Proxy * (quorumBasePercentage + reputationBonusFactor) ) / 10000

        // Proxy for Total Voting Power: Use totalQuadraticStakePower as it represents community "size"
        // A real system would sum _getParticipantVotingPower() for all active participants, which is difficult.
        uint256 totalVotingPowerProxy = getTotalQuadraticStakePower();

        // Reputation bonus factor based on some average reputation metric?
        // Or just a flat bonus? Let's use participant count * average rep as a proxy.
        // uint256 totalReputation = 0; // Requires iterating participants - avoid
        // uint256 participantCount = getParticipantCount();
        // uint256 averageReputation = (participantCount > 0) ? totalReputation / participantCount : 0;
        // uint256 reputationBonusFactor = (averageReputation / 1000) * quorumReputationBonus; // bps bonus per 1000 avg rep

        // Simplified: Just use base quorum percentage
         uint256 requiredQuorum = (totalVotingPowerProxy * quorumBasePercentage) / 10000;

         // Add reputation influence based on total reputation (conceptual, hard to implement efficiently)
         // E.g., Add a small bonus based on *caller's* reputation if calculating for a specific proposal? No, quorum is system-wide.
         // Let's stick to base percentage for now, as adding reputation efficiently is complex.

        return requiredQuorum;
    }


     function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
         if (_proposalId >= nextProposalId || _proposalId == 0) {
             // Invalid proposal ID
             return ProposalState.Pending; // Or a specific error indication
         }
         Proposal storage proposal = proposals[_proposalId];
         // Re-check outcome if voting period ended but state is still active
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingEndTime) {
              uint256 requiredQuorum = getCurrentQuorumRequirement();
              uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
              if (proposal.votesFor > proposal.votesAgainst && totalVotesCast >= requiredQuorum) {
                 return ProposalState.Succeeded;
              } else {
                 return ProposalState.Failed;
              }
         }
         return proposal.state;
     }


    // --- Achievements (SBT-like) ---

    // Achievements are non-transferable tokens/badges recorded directly in participant data mapping.
    // They don't follow ERC721 standard but use the "Soulbound" concept.
    function mintAchievementToken(address _participant, uint256 _achievementId) external onlyGovernor {
        if (!isParticipantRegistered[_participant]) revert NotRegistered();
        if (_achievementId == 0) revert InvalidAchievementId(); // Achievement ID 0 is reserved/invalid
        participants[_participant].achievements[_achievementId] = true;
        emit AchievementMinted(_participant, _achievementId);
    }

    function revokeAchievement(address _participant, uint256 _achievementId) external onlyGovernor {
        if (!isParticipantRegistered[_participant]) revert NotRegistered();
        if (!participants[_participant].achievements[_achievementId]) return; // Nothing to revoke
        participants[_participant].achievements[_achievementId] = false;
        emit AchievementRevoked(_participant, _achievementId);
    }

    function getAchievementStatus(address _participant, uint256 _achievementId) external view returns (bool) {
        if (!isParticipantRegistered[_participant]) return false;
        return participants[_participant].achievements[_achievementId];
    }

    // --- Environmental Events (Simulated Randomness) ---

    // This function simulates the outcome of an environmental event
    // In a real contract, _simulatedRandomness would come from a verifiable random source
    // like Chainlink VRF callback.
    function triggerEnvironmentalEvent(uint256 _simulatedRandomness) external onlyOracle {
        // Use randomness to determine the event outcome (e.g., affects yield multiplier, health)
        // Example: Randomness modulo 100 determines severity/type
        uint256 outcome = _simulatedRandomness % 100;

        lastEnvironmentalEventOutcome = outcome;

        // Example effect: Health slightly fluctuates based on outcome
        if (outcome < 20) { // Bad event
            if (ecosystemHealth > 1000) ecosystemHealth -= 1000;
            else ecosystemHealth = 0;
        } else if (outcome > 80) { // Good event
            if (ecosystemHealth < 9000) ecosystemHealth += 1000;
            else ecosystemHealth = 10000;
        }
        // More complex effects possible based on outcome

        emit EnvironmentalEventTriggered(outcome);
         emit EcosystemHealthUpdated(ecosystemHealth); // Also emit health update if changed
    }

    function getLastEnvironmentalEventOutcome() external view returns (uint256) {
        return lastEnvironmentalEventOutcome;
    }
}
```