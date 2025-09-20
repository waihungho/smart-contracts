This smart contract, **AuraEngine**, is designed as a decentralized protocol for community-driven investment strategy formulation and execution, coupled with a dynamic, reputation-based influence system represented by "Aura." Participants propose and vote on investment strategies, and their success or failure directly impacts their Aura score. Aura dynamically determines a participant's influence, reward share, and is reflected in upgradable, dynamic NFTs. The protocol integrates with trusted oracles for market data and strategy outcome validation, and includes a challenge mechanism for dispute resolution.

---

## AuraEngine: Decentralized Dynamic Strategy & Reputation Protocol

### **Outline:**

1.  **State Variables & Core Data Structures:**
    *   Owner, Pauser, Oracle, NFT Contract addresses.
    *   `Participant` struct (address, registration time, active status, etc.).
    *   `Strategy` struct (ID, proposer, description, status, target asset, risk profile, funding, votes, outcome, etc.).
    *   Mappings for participants, strategies, Aura balances, votes.
    *   Protocol parameters (min stakes, voting periods, Aura decay rates).
    *   Internal treasury for strategy execution.
2.  **Access Control & Modifiers:**
    *   `onlyOwner`, `onlyPauser`, `onlyOracle`, `onlyRegistered`.
    *   `whenNotPaused`, `whenPaused`.
3.  **Core Protocol Management:**
    *   Initialization, pausing, parameter updates, setting external contract addresses.
4.  **Participant Management:**
    *   Registration, deregistration, profile updates.
5.  **Aura (Reputation) System:**
    *   Earning, burning, decay, delegation of Aura.
    *   Calculating participant tiers based on Aura.
6.  **Investment Strategy Lifecycle:**
    *   Proposal, staking, voting, execution (by keeper), outcome settlement, challenge mechanism.
    *   Funding strategies from a collective pool.
7.  **Dynamic NFT Integration:**
    *   Interacting with an external `AuraTierNFT` contract to mint, update, or burn NFTs based on a participant's Aura tier.
8.  **Oracle Integration:**
    *   Receiving and processing external data for strategy outcomes.
9.  **Treasury & Rewards:**
    *   Depositing funds for strategy execution.
    *   Distributing profits/losses and protocol rewards.

### **Function Summary (27 Functions):**

**A. Protocol & Access Control (5 functions):**
1.  `initialize()`: Initializes the contract with an owner and pauser.
2.  `updateProtocolParameter()`: Allows owner to adjust protocol-wide settings (e.g., voting duration, min stakes).
3.  `setTrustedOracle()`: Sets the address of the trusted oracle contract.
4.  `setAuraTierNFTContract()`: Sets the address of the dynamic Aura Tier NFT contract.
5.  `pauseProtocol()`: Pauses core functionality in emergencies.
6.  `unpauseProtocol()`: Unpauses the protocol.

**B. Participant Management (3 functions):**
7.  `registerParticipant()`: Allows a user to join the protocol by staking a minimum amount and agreeing to terms.
8.  `deregisterParticipant()`: Allows a participant to leave, reclaiming their stake (after fulfilling obligations).
9.  `updateParticipantProfileHash()`: Allows participants to update a hash representing their off-chain profile/description.

**C. Aura (Reputation) System (5 functions):**
10. `getAuraBalance()`: Returns the current Aura balance of an address (public view).
11. `delegateAura()`: Allows a participant to delegate their Aura to another address for voting power.
12. `reclaimDelegatedAura()`: Allows a participant to reclaim their previously delegated Aura.
13. `checkAuraTier()`: Returns the current Aura tier of a participant based on their balance.
14. `updateAuraDecayRate()`: (Owner) Sets the rate at which Aura naturally decays over time for participants.

**D. Investment Strategy Lifecycle (9 functions):**
15. `proposeInvestmentStrategy()`: A registered participant proposes a new strategy, staking a deposit.
16. `depositForStrategyProposal()`: Allows the proposer to deposit the required collateral for a strategy proposal.
17. `voteOnStrategy()`: Registered participants vote on proposed strategies, weighted by their Aura.
18. `executeApprovedStrategy()`: (External Keeper) Triggers the execution of an approved, funded strategy.
19. `settleStrategyOutcome()`: (Trusted Oracle) Submits the final outcome (profit/loss) for an executed strategy, updating participant Aura and distributing funds.
20. `challengeStrategyOutcome()`: Allows a participant to challenge an oracle-submitted outcome, requiring a bond.
21. `withdrawProposalDeposit()`: Allows a proposer to withdraw their initial deposit if the strategy is approved, failed to get funded, or challenged.
22. `emergencyHaltStrategy()`: (Owner/Pauser) Immediately halts an ongoing strategy in critical situations.
23. `cancelStrategyProposal()`: Allows a proposer to cancel their strategy if it hasn't reached quorum or funding.

**E. Treasury & Rewards (3 functions):**
24. `depositFundsForExecution()`: Participants deposit funds into a collective pool to be used for approved strategies.
25. `withdrawStrategyProfit()`: Allows participants to withdraw their share of profits from a successful strategy.
26. `claimProtocolRewards()`: Allows participants to claim general protocol rewards for active participation (e.g., voting, successful proposals).

**F. Oracle Interaction (1 function):**
27. `submitOracleData()`: (Trusted Oracle) Submits specific data (e.g., market price at strategy close, event outcome) for settling strategies.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Custom Errors ---
error AuraEngine__NotRegistered();
error AuraEngine__AlreadyRegistered();
error AuraEngine__ZeroAddress();
error AuraEngine__InvalidParameter();
error AuraEngine__NotEnoughStake();
error AuraEngine__StrategyNotFound();
error AuraEngine__StrategyNotProposable();
error AuraEngine__StrategyNotVoteable();
error AuraEngine__StrategyNotExecutable();
error AuraEngine__StrategyNotSettleable();
error AuraEngine__StrategyAlreadyVoted();
error AuraEngine__StrategyAlreadyFunded();
error AuraEngine__StrategyNotFunded();
error AuraEngine__StrategyExpired();
error AuraEngine__InsufficientAura();
error AuraEngine__SelfDelegationNotAllowed();
error AuraEngine__InvalidDelegationTarget();
error AuraEngine__NoActiveDelegation();
error AuraEngine__UnauthorizedOracle();
error AuraEngine__UnauthorizedNFTContract();
error AuraEngine__ProposalDepositNotClaimable();
error AuraEngine__InsufficientFunds();
error AuraEngine__NoProfitsToWithdraw();
error AuraEngine__NoRewardsToClaim();
error AuraEngine__ChallengeAlreadyInitiated();
error AuraEngine__ChallengePeriodExpired();

// --- Interfaces ---

// Interface for a dynamic Aura Tier NFT contract
interface IAuraTierNFT {
    function mintTierNFT(address to, uint256 tier) external;
    function updateTierNFTMetadata(address holder, uint256 newTier) external;
    function burnTierNFT(address holder) external;
    function getTier(address holder) external view returns (uint256);
}

// Interface for a trusted Oracle
interface ITrustedOracle {
    function getOracleData(bytes32 dataKey) external view returns (uint256 value, uint256 timestamp);
}

contract AuraEngine is Ownable, Pausable, ReentrancyGuard {

    // --- Enums & Structs ---

    enum StrategyStatus {
        Proposed,         // Awaiting proposal deposit
        Voting,           // Open for votes
        Approved,         // Approved by community, awaiting funding
        Funded,           // Funded, awaiting execution (by keeper)
        Executing,        // Currently active / being managed off-chain
        Settled,          // Outcome determined, funds distributed
        Challenged,       // Outcome challenged, awaiting re-evaluation
        Rejected,         // Not approved by votes or failed to fund
        Halted,           // Emergency halt
        Cancelled         // Proposer cancelled before quorum/funding
    }

    enum StrategyOutcome {
        Pending,
        Success,
        Failure,
        Neutral
    }

    struct Participant {
        bool isRegistered;
        uint256 registrationTime;
        bytes32 profileHash;      // IPFS hash or similar for off-chain profile data
        uint256 initialStake;     // Stake required to register
        address delegatedTo;      // Address to which Aura is delegated
        address delegatedFrom;    // Address from which Aura is received
        uint256 lastAuraUpdate;   // Timestamp of last Aura calculation/decay
    }

    struct Strategy {
        uint256 strategyId;
        address proposer;
        string descriptionURI;    // IPFS hash for detailed strategy description
        StrategyStatus status;
        uint256 proposalDeposit;
        uint256 minRequiredAura;  // Min Aura to propose
        uint256 fundingTarget;    // Amount of funds required for execution
        uint256 currentFunding;   // Current amount funded for this strategy
        uint256 startVoteTime;
        uint256 endVoteTime;
        uint256 executionStartTime; // When the strategy officially started executing
        uint256 executionDuration;  // Expected duration in seconds
        uint256 forVotes;         // Total Aura for "for" votes
        uint256 againstVotes;     // Total Aura for "against" votes
        StrategyOutcome outcome;  // Final outcome (Success/Failure)
        int256 profitLossPercentage; // % profit or loss (e.g., 1000 for 10%, -500 for -5%)
        address[] funders;        // Addresses that contributed funds
        uint256[] funderAmounts;  // Amounts contributed by each funder
        uint256 challengerDeposit; // Deposit for challenging outcome
        address challenger;       // Address that challenged the outcome
        uint256 challengeExpiration; // Timestamp when challenge period expires
    }

    // --- State Variables ---

    address public pauser; // Can pause/unpause the protocol
    address public trustedOracle; // Address of the oracle contract
    address public auraTierNFTContract; // Address of the dynamic NFT contract

    IERC20 public acceptedToken; // The ERC20 token used for stakes, funding, and rewards

    uint256 public nextStrategyId;

    // Protocol parameters (adjustable by owner)
    uint256 public minRegistrationStake;
    uint256 public minProposalDeposit;
    uint256 public votingPeriodDuration; // seconds
    uint256 public fundingPeriodDuration; // seconds
    uint256 public challengePeriodDuration; // seconds after settlement
    uint256 public minVoteQuorumAura; // Minimum total Aura for a vote to be valid
    uint256 public minVoteMajorityPercentage; // e.g., 51% (represented as 5100 for 51.00%)
    uint256 public baseAuraMintOnSuccess; // Base Aura amount minted for successful strategy
    uint256 public auraDecayRatePerSecond; // How much Aura decays per second (e.g., 1 Aura per 86400 seconds)
    uint256[] public auraTierThresholds; // e.g., [0, 100, 500, 2000] for tiers 0, 1, 2, 3
    uint256 public protocolRewardPercentage; // % of profits taken by protocol (e.g., 500 for 5%)
    uint256 public challengeBondPercentage; // % of strategy funding needed to challenge (e.g., 1000 for 10%)

    // Mappings
    mapping(address => Participant) public participants;
    mapping(address => uint256) public auraBalances; // User's actual Aura balance
    mapping(uint256 => Strategy) public strategies;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // participant => strategyId => voted
    mapping(address => uint256) public participantRewards; // Rewards accumulated for participation

    // --- Events ---
    event Initialized(address indexed owner, address indexed pauser);
    event ProtocolParameterUpdated(string indexed paramName, uint256 newValue);
    event TrustedOracleSet(address indexed newOracle);
    event AuraTierNFTContractSet(address indexed newContract);

    event ParticipantRegistered(address indexed participant, uint256 stake);
    event ParticipantDeregistered(address indexed participant);
    event ParticipantProfileUpdated(address indexed participant, bytes32 newHash);

    event AuraMinted(address indexed participant, uint256 amount, string reason);
    event AuraBurned(address indexed participant, uint256 amount, string reason);
    event AuraDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event AuraReclaimed(address indexed delegator, address indexed delegatee, uint256 amount);
    event AuraTierChanged(address indexed participant, uint256 oldTier, uint256 newTier);

    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, string descriptionURI, uint256 deposit);
    event StrategyProposalDepositMade(uint256 indexed strategyId, address indexed proposer, uint256 amount);
    event StrategyVoted(uint256 indexed strategyId, address indexed voter, bool support, uint256 auraWeight);
    event StrategyStatusChanged(uint256 indexed strategyId, StrategyStatus newStatus);
    event StrategyApproved(uint256 indexed strategyId);
    event StrategyRejected(uint256 indexed strategyId);
    event StrategyFunded(uint256 indexed strategyId, address indexed funder, uint256 amount);
    event StrategyExecuted(uint256 indexed strategyId);
    event StrategySettled(uint256 indexed strategyId, StrategyOutcome outcome, int256 profitLossPercentage, uint256 protocolFee);
    event StrategyOutcomeChallenged(uint256 indexed strategyId, address indexed challenger, uint256 bond);
    event StrategyHalted(uint256 indexed strategyId);
    event StrategyCancelled(uint256 indexed strategyId);

    event FundsDepositedForExecution(address indexed sender, uint256 amount);
    event ProfitsWithdrawn(address indexed participant, uint256 strategyId, uint256 amount);
    event ProtocolRewardsClaimed(address indexed participant, uint256 amount);
    event ProposalDepositWithdrawn(address indexed proposer, uint252 strategyId, uint256 amount);

    // --- Constructor & Initializer ---
    // Using an initializer pattern for potential upgradeability (e.g., UUPS proxy)
    // For a simple contract, a constructor would suffice.
    constructor() {
        // pauser is set to msg.sender as a default here. Can be updated.
        // acceptedToken needs to be set after deployment as well.
    }

    function initialize(address initialOwner, address _pauser, address _acceptedToken, uint256 _minRegistrationStake) public initializer {
        _transferOwnership(initialOwner);
        pauser = _pauser;
        acceptedToken = IERC20(_acceptedToken);

        minRegistrationStake = _minRegistrationStake;
        minProposalDeposit = 1 ether; // Example value
        votingPeriodDuration = 3 days;
        fundingPeriodDuration = 7 days;
        challengePeriodDuration = 2 days;
        minVoteQuorumAura = 1000 ether; // Example value, needs to be scaled by Aura unit
        minVoteMajorityPercentage = 5100; // 51%
        baseAuraMintOnSuccess = 50 ether;
        auraDecayRatePerSecond = 100; // 1 Aura per 100 seconds (example, adjust significantly)
        auraTierThresholds = [0, 100 ether, 500 ether, 2000 ether]; // Tier 0, 1, 2, 3 thresholds
        protocolRewardPercentage = 500; // 5%
        challengeBondPercentage = 1000; // 10%

        nextStrategyId = 1;
        emit Initialized(initialOwner, _pauser);
    }

    modifier onlyPauser() {
        if (msg.sender != pauser) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != trustedOracle) revert AuraEngine__UnauthorizedOracle();
        _;
    }

    modifier onlyRegistered() {
        if (!participants[msg.sender].isRegistered) revert AuraEngine__NotRegistered();
        _;
    }

    // --- Internal Aura Management (decay, mint, burn) ---

    // Calculates current Aura after decay
    function _calculateCurrentAura(address participantAddr) internal view returns (uint256) {
        Participant storage p = participants[participantAddr];
        if (!p.isRegistered || auraBalances[participantAddr] == 0 || p.lastAuraUpdate == 0) {
            return auraBalances[participantAddr];
        }

        uint256 timeElapsed = block.timestamp - p.lastAuraUpdate;
        uint256 decayAmount = timeElapsed * auraDecayRatePerSecond;

        if (decayAmount >= auraBalances[participantAddr]) {
            return 0;
        } else {
            return auraBalances[participantAddr] - decayAmount;
        }
    }

    // Applies decay and updates lastAuraUpdate timestamp
    function _updateAuraWithDecay(address participantAddr) internal returns (uint256) {
        uint256 currentAura = _calculateCurrentAura(participantAddr);
        uint256 oldAura = auraBalances[participantAddr];
        auraBalances[participantAddr] = currentAura;
        participants[participantAddr].lastAuraUpdate = block.timestamp;

        if (currentAura != oldAura) {
            _checkAndUpdateAuraNFT(participantAddr, oldAura, currentAura);
        }
        return currentAura;
    }

    function _mintAura(address participantAddr, uint256 amount, string memory reason) internal {
        _updateAuraWithDecay(participantAddr); // Apply decay before minting
        uint256 oldAura = auraBalances[participantAddr];
        auraBalances[participantAddr] += amount;
        emit AuraMinted(participantAddr, amount, reason);
        _checkAndUpdateAuraNFT(participantAddr, oldAura, auraBalances[participantAddr]);
    }

    function _burnAura(address participantAddr, uint256 amount, string memory reason) internal {
        _updateAuraWithDecay(participantAddr); // Apply decay before burning
        uint256 oldAura = auraBalances[participantAddr];
        if (auraBalances[participantAddr] < amount) {
            auraBalances[participantAddr] = 0;
        } else {
            auraBalances[participantAddr] -= amount;
        }
        emit AuraBurned(participantAddr, amount, reason);
        _checkAndUpdateAuraNFT(participantAddr, oldAura, auraBalances[participantAddr]);
    }

    // --- NFT Management Internal ---

    function _getAuraTier(uint256 auraAmount) internal view returns (uint256) {
        for (uint256 i = auraTierThresholds.length - 1; i >= 0; i--) {
            if (auraAmount >= auraTierThresholds[i]) {
                return i;
            }
        }
        return 0; // Should not be reached if 0 is in thresholds
    }

    function _checkAndUpdateAuraNFT(address participantAddr, uint256 oldAura, uint256 newAura) internal {
        if (address(auraTierNFTContract) == address(0)) return; // No NFT contract set

        uint256 oldTier = _getAuraTier(oldAura);
        uint256 newTier = _getAuraTier(newAura);

        if (oldTier == newTier) return;

        emit AuraTierChanged(participantAddr, oldTier, newTier);

        if (oldTier == 0 && newTier > 0) { // First time minting a tier NFT
            IAuraTierNFT(auraTierNFTContract).mintTierNFT(participantAddr, newTier);
        } else if (newTier == 0) { // Aura dropped below all tiers, burn NFT
            IAuraTierNFT(auraTierNFTContract).burnTierNFT(participantAddr);
        } else { // Tier change (upgrade/downgrade)
            IAuraTierNFT(auraTierNFTContract).updateTierNFTMetadata(participantAddr, newTier);
        }
    }


    // --- A. Protocol & Access Control Functions ---

    // Initializer, to be called once after deployment (e.g., for UUPS proxy)
    function initializer(address initialOwner, address _pauser, address _acceptedToken, uint256 _minRegistrationStake) public virtual {
        // The Ownable's constructor sets msg.sender as owner. This pattern is for UUPS proxy contracts.
        // For a non-proxy, `constructor(address _acceptedToken, ...)` would call `Ownable(_initialOwner)`
        // and then set other initial values.
        if (initialized) revert InvalidInitialization(); // Prevent re-initialization
        _setOwner(initialOwner);
        pauser = _pauser;
        acceptedToken = IERC20(_acceptedToken);

        minRegistrationStake = _minRegistrationStake;
        minProposalDeposit = 1 ether; // Example value
        votingPeriodDuration = 3 days;
        fundingPeriodDuration = 7 days;
        challengePeriodDuration = 2 days;
        minVoteQuorumAura = 1000 ether; // Example value, needs to be scaled by Aura unit
        minVoteMajorityPercentage = 5100; // 51%
        baseAuraMintOnSuccess = 50 ether;
        auraDecayRatePerSecond = 100; // 1 Aura per 100 seconds (example, adjust significantly)
        auraTierThresholds = [0, 100 ether, 500 ether, 2000 ether]; // Tier 0, 1, 2, 3 thresholds
        protocolRewardPercentage = 500; // 5%
        challengeBondPercentage = 1000; // 10%

        nextStrategyId = 1;
        initialized = true;
        emit Initialized(initialOwner, _pauser);
    }

    bool private initialized; // Internal flag for initializer

    function updateProtocolParameter(string calldata paramName, uint256 newValue) external onlyOwner {
        if (bytes(paramName).length == 0) revert AuraEngine__InvalidParameter();
        
        if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minRegistrationStake"))) {
            minRegistrationStake = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minProposalDeposit"))) {
            minProposalDeposit = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("votingPeriodDuration"))) {
            votingPeriodDuration = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("fundingPeriodDuration"))) {
            fundingPeriodDuration = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("challengePeriodDuration"))) {
            challengePeriodDuration = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minVoteQuorumAura"))) {
            minVoteQuorumAura = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minVoteMajorityPercentage"))) {
            if (newValue > 10000) revert AuraEngine__InvalidParameter(); // Max 100%
            minVoteMajorityPercentage = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("baseAuraMintOnSuccess"))) {
            baseAuraMintOnSuccess = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("auraDecayRatePerSecond"))) {
            auraDecayRatePerSecond = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("protocolRewardPercentage"))) {
            if (newValue > 10000) revert AuraEngine__InvalidParameter();
            protocolRewardPercentage = newValue;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("challengeBondPercentage"))) {
            if (newValue > 10000) revert AuraEngine__InvalidParameter();
            challengeBondPercentage = newValue;
        } else {
            revert AuraEngine__InvalidParameter();
        }
        emit ProtocolParameterUpdated(paramName, newValue);
    }

    function setTrustedOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert AuraEngine__ZeroAddress();
        trustedOracle = _oracle;
        emit TrustedOracleSet(_oracle);
    }

    function setAuraTierNFTContract(address _nftContract) external onlyOwner {
        if (_nftContract == address(0)) revert AuraEngine__ZeroAddress();
        auraTierNFTContract = _nftContract;
        emit AuraTierNFTContractSet(_nftContract);
    }

    function pauseProtocol() external onlyPauser whenNotPaused {
        _pause();
    }

    function unpauseProtocol() external onlyPauser whenPaused {
        _unpause();
    }

    // --- B. Participant Management Functions ---

    function registerParticipant(bytes32 _profileHash) external payable whenNotPaused {
        if (participants[msg.sender].isRegistered) revert AuraEngine__AlreadyRegistered();
        if (msg.value < minRegistrationStake) revert AuraEngine__NotEnoughStake();

        participants[msg.sender] = Participant({
            isRegistered: true,
            registrationTime: block.timestamp,
            profileHash: _profileHash,
            initialStake: msg.value,
            delegatedTo: address(0),
            delegatedFrom: address(0),
            lastAuraUpdate: block.timestamp
        });
        // Initial Aura could be minted here or set to 0 and earned later
        // For now, start at 0 and earn via participation
        emit ParticipantRegistered(msg.sender, msg.value);
    }

    function deregisterParticipant() external onlyRegistered whenNotPaused {
        // Ensure participant has no pending strategies, delegations, or funds
        // This is a simplified version; real-world needs more checks
        require(auraBalances[msg.sender] == 0, "AuraEngine: Cannot deregister with active Aura.");
        require(participants[msg.sender].delegatedTo == address(0), "AuraEngine: Cannot deregister while delegating Aura.");
        require(participants[msg.sender].delegatedFrom == address(0), "AuraEngine: Cannot deregister while receiving Aura delegation.");
        // Check for active strategies where msg.sender is proposer or funder

        uint256 stake = participants[msg.sender].initialStake;
        delete participants[msg.sender];
        
        (bool success,) = payable(msg.sender).call{value: stake}("");
        if (!success) revert AuraEngine__InsufficientFunds(); // Or more specific error

        emit ParticipantDeregistered(msg.sender);
    }

    function updateParticipantProfileHash(bytes32 _newHash) external onlyRegistered whenNotPaused {
        participants[msg.sender].profileHash = _newHash;
        emit ParticipantProfileUpdated(msg.sender, _newHash);
    }

    // --- C. Aura (Reputation) System Functions ---

    function getAuraBalance(address participantAddr) public view returns (uint256) {
        return _calculateCurrentAura(participantAddr);
    }

    function delegateAura(address _delegatee) external onlyRegistered whenNotPaused {
        if (_delegatee == address(0)) revert AuraEngine__ZeroAddress();
        if (_delegatee == msg.sender) revert AuraEngine__SelfDelegationNotAllowed();
        if (!participants[_delegatee].isRegistered) revert AuraEngine__InvalidDelegationTarget();

        _updateAuraWithDecay(msg.sender); // Ensure delegator's Aura is current
        uint256 delegatorAura = auraBalances[msg.sender];
        if (delegatorAura == 0) revert AuraEngine__InsufficientAura();

        // Clear previous delegation if any
        if (participants[msg.sender].delegatedTo != address(0)) {
            address oldDelegatee = participants[msg.sender].delegatedTo;
            participants[oldDelegatee].delegatedFrom = address(0); // Clear delegation from old delegatee
            // In a more complex system, you might need to manage nested delegations carefully
            // For simplicity, direct delegation only.
        }

        participants[msg.sender].delegatedTo = _delegatee;
        participants[_delegatee].delegatedFrom = msg.sender; // Mark delegatee as receiving delegation

        emit AuraDelegated(msg.sender, _delegatee, delegatorAura);
    }

    function reclaimDelegatedAura() external onlyRegistered whenNotPaused {
        address oldDelegatee = participants[msg.sender].delegatedTo;
        if (oldDelegatee == address(0)) revert AuraEngine__NoActiveDelegation();

        participants[msg.sender].delegatedTo = address(0);
        participants[oldDelegatee].delegatedFrom = address(0); // Clear delegation from old delegatee

        _updateAuraWithDecay(msg.sender); // Update Aura after reclamation to be safe
        emit AuraReclaimed(msg.sender, oldDelegatee, auraBalances[msg.sender]);
    }

    function checkAuraTier(address participantAddr) public view returns (uint256) {
        uint256 currentAura = getAuraBalance(participantAddr);
        return _getAuraTier(currentAura);
    }

    function updateAuraDecayRate(uint256 _newRate) external onlyOwner {
        auraDecayRatePerSecond = _newRate;
        emit ProtocolParameterUpdated("auraDecayRatePerSecond", _newRate);
    }

    // --- D. Investment Strategy Lifecycle Functions ---

    function proposeInvestmentStrategy(
        string calldata _descriptionURI,
        uint256 _minRequiredAura,
        uint256 _fundingTarget,
        uint256 _executionDuration
    ) external onlyRegistered whenNotPaused nonReentrant returns (uint256) {
        if (_fundingTarget == 0 || _executionDuration == 0) revert AuraEngine__InvalidParameter();
        if (minRequiredAura > _updateAuraWithDecay(msg.sender)) revert AuraEngine__InsufficientAura();

        uint256 strategyId = nextStrategyId++;
        strategies[strategyId] = Strategy({
            strategyId: strategyId,
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            status: StrategyStatus.Proposed,
            proposalDeposit: 0, // Will be set in depositForStrategyProposal
            minRequiredAura: _minRequiredAura,
            fundingTarget: _fundingTarget,
            currentFunding: 0,
            startVoteTime: 0,
            endVoteTime: 0,
            executionStartTime: 0,
            executionDuration: _executionDuration,
            forVotes: 0,
            againstVotes: 0,
            outcome: StrategyOutcome.Pending,
            profitLossPercentage: 0,
            funders: new address[](0),
            funderAmounts: new uint256[](0),
            challengerDeposit: 0,
            challenger: address(0),
            challengeExpiration: 0
        });

        emit StrategyProposed(strategyId, msg.sender, _descriptionURI, minProposalDeposit); // Min deposit is stated
        return strategyId;
    }

    function depositForStrategyProposal(uint256 _strategyId) external payable onlyRegistered whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer != msg.sender) revert AuraEngine__StrategyNotFound();
        if (strategy.status != StrategyStatus.Proposed) revert AuraEngine__StrategyNotProposable();
        if (msg.value < minProposalDeposit) revert AuraEngine__NotEnoughStake();

        strategy.proposalDeposit = msg.value;
        strategy.status = StrategyStatus.Voting;
        strategy.startVoteTime = block.timestamp;
        strategy.endVoteTime = block.timestamp + votingPeriodDuration;

        emit StrategyProposalDepositMade(_strategyId, msg.sender, msg.value);
        emit StrategyStatusChanged(_strategyId, StrategyStatus.Voting);
    }

    function voteOnStrategy(uint256 _strategyId, bool _support) external onlyRegistered whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status != StrategyStatus.Voting) revert AuraEngine__StrategyNotVoteable();
        if (block.timestamp > strategy.endVoteTime) revert AuraEngine__StrategyExpired();
        if (hasVoted[msg.sender][_strategyId]) revert AuraEngine__StrategyAlreadyVoted();

        _updateAuraWithDecay(msg.sender); // Ensure voter's Aura is current
        uint256 voterAura = auraBalances[msg.sender];
        if (participants[msg.sender].delegatedTo != address(0)) {
            // If msg.sender delegated their Aura, their own Aura here is 0 for voting purposes
            // We should use the Aura of the delegatee or prevent voting if delegated.
            // For simplicity, let's say if you delegated, you can't vote yourself directly.
            revert AuraEngine__NoActiveDelegation(); // You can't vote directly if you delegated your Aura
        }
        
        // Check if current participant receives delegation
        if (participants[msg.sender].delegatedFrom != address(0)) {
            // This participant receives Aura delegation, their vote carries their own Aura + delegated Aura
            // A more complex system would need to track exact delegated amounts per address.
            // For simplicity, we'll assume `auraBalances[msg.sender]` reflects all effective Aura.
            // (This simplifies Aura tracking, but means delegation isn't truly 'transferring' balance.)
            // Alternative: A separate mapping for effective voting power.
        }

        if (voterAura == 0) revert AuraEngine__InsufficientAura();

        hasVoted[msg.sender][_strategyId] = true;
        if (_support) {
            strategy.forVotes += voterAura;
        } else {
            strategy.againstVotes += voterAura;
        }
        _mintAura(msg.sender, 1 ether, "Vote Participation"); // Small reward for voting
        emit StrategyVoted(_strategyId, msg.sender, _support, voterAura);
    }

    function executeApprovedStrategy(uint256 _strategyId) external whenNotPaused nonReentrant {
        // This function would typically be called by a decentralized keeper network
        // or a trusted bot once a strategy is approved and funded.
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status == StrategyStatus.Voting && block.timestamp > strategy.endVoteTime) {
            _evaluateVotingOutcome(_strategyId);
        }

        if (strategy.status != StrategyStatus.Funded) revert AuraEngine__StrategyNotExecutable();
        if (strategy.currentFunding < strategy.fundingTarget) revert AuraEngine__StrategyNotFunded();

        // Transfer funds for strategy execution to an external investment module or designated address
        // This is a placeholder for actual investment logic, likely off-chain or via another contract.
        // For simplicity, we assume funds are 'locked' here and released later.
        
        strategy.status = StrategyStatus.Executing;
        strategy.executionStartTime = block.timestamp;
        emit StrategyExecuted(_strategyId);
        emit StrategyStatusChanged(_strategyId, StrategyStatus.Executing);
    }

    function _evaluateVotingOutcome(uint256 _strategyId) internal {
        Strategy storage strategy = strategies[_strategyId];
        uint256 totalVotes = strategy.forVotes + strategy.againstVotes;

        if (totalVotes < minVoteQuorumAura) {
            strategy.status = StrategyStatus.Rejected;
            // Return proposal deposit
            (bool success,) = payable(strategy.proposer).call{value: strategy.proposalDeposit}("");
            if (!success) emit AuraEngine__InsufficientFunds(); // Log error, don't revert
            emit StrategyRejected(_strategyId);
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Rejected);
            return;
        }

        uint256 forPercentage = (strategy.forVotes * 10000) / totalVotes; // Scaled by 10000 for 100%

        if (forPercentage >= minVoteMajorityPercentage) {
            strategy.status = StrategyStatus.Approved;
            emit StrategyApproved(_strategyId);
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Approved);
        } else {
            strategy.status = StrategyStatus.Rejected;
            // Return proposal deposit
            (bool success,) = payable(strategy.proposer).call{value: strategy.proposalDeposit}("");
            if (!success) emit AuraEngine__InsufficientFunds(); // Log error
            emit StrategyRejected(_strategyId);
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Rejected);
        }
    }

    function settleStrategyOutcome(
        uint256 _strategyId,
        int256 _profitLossPercentage // e.g., 1000 for 10% profit, -500 for 5% loss
    ) external onlyOracle whenNotPaused nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status != StrategyStatus.Executing) revert AuraEngine__StrategyNotSettleable();
        // Additional check: Ensure oracle data pertains to the correct strategy execution context
        // e.g., by comparing `strategy.executionStartTime` with oracle data timestamp if available

        strategy.profitLossPercentage = _profitLossPercentage;
        
        uint256 initialInvestment = strategy.currentFunding;
        uint256 finalValue;
        if (_profitLossPercentage >= 0) {
            finalValue = (initialInvestment * (10000 + uint256(_profitLossPercentage))) / 10000;
            strategy.outcome = StrategyOutcome.Success;
        } else {
            finalValue = (initialInvestment * (10000 - uint256(uint256(-_profitLossPercentage)))) / 10000;
            strategy.outcome = StrategyOutcome.Failure;
        }

        uint256 totalProfit = 0;
        if (finalValue > initialInvestment) {
            totalProfit = finalValue - initialInvestment;
        }
        
        uint256 protocolFee = (totalProfit * protocolRewardPercentage) / 10000;
        uint256 distributableAmount = finalValue - protocolFee;

        // Distribute funds to funders
        for (uint256 i = 0; i < strategy.funders.length; i++) {
            address funder = strategy.funders[i];
            uint256 amountFunded = strategy.funderAmounts[i];
            uint256 share = (amountFunded * distributableAmount) / initialInvestment; // Proportional distribution

            // Update participantRewards (or directly transfer if no vesting/claim system)
            participantRewards[funder] += share;
        }

        // Update proposer Aura based on success/failure
        if (strategy.outcome == StrategyOutcome.Success) {
            _mintAura(strategy.proposer, baseAuraMintOnSuccess + (totalProfit / 1 ether), "Successful Strategy Proposer");
        } else if (strategy.outcome == StrategyOutcome.Failure) {
            _burnAura(strategy.proposer, baseAuraMintOnSuccess / 2, "Failed Strategy Proposer"); // Burn less than mint
        }

        // Return proposal deposit if not challenged
        (bool success,) = payable(strategy.proposer).call{value: strategy.proposalDeposit}("");
        if (!success) emit AuraEngine__InsufficientFunds(); // Log, don't revert

        strategy.status = StrategyStatus.Settled;
        strategy.challengeExpiration = block.timestamp + challengePeriodDuration;

        emit StrategySettled(_strategyId, strategy.outcome, _profitLossPercentage, protocolFee);
        emit StrategyStatusChanged(_strategyId, StrategyStatus.Settled);
    }

    function challengeStrategyOutcome(uint256 _strategyId) external payable onlyRegistered whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status != StrategyStatus.Settled) revert AuraEngine__StrategyNotSettleable();
        if (block.timestamp > strategy.challengeExpiration) revert AuraEngine__ChallengePeriodExpired();
        if (strategy.challenger != address(0)) revert AuraEngine__ChallengeAlreadyInitiated();

        uint256 requiredBond = (strategy.fundingTarget * challengeBondPercentage) / 10000;
        if (msg.value < requiredBond) revert AuraEngine__NotEnoughStake();

        strategy.challenger = msg.sender;
        strategy.challengerDeposit = msg.value;
        strategy.status = StrategyStatus.Challenged;

        // More complex logic needed here: e.g., a dispute resolution module,
        // community re-vote on outcome, or another oracle's decision.
        // For simplicity, this is a flag and a bond.
        
        _burnAura(msg.sender, baseAuraMintOnSuccess / 4, "Challenged Strategy Outcome"); // Small Aura cost to challenge

        emit StrategyOutcomeChallenged(_strategyId, msg.sender, msg.value);
        emit StrategyStatusChanged(_strategyId, StrategyStatus.Challenged);
    }

    function withdrawProposalDeposit(uint252 _strategyId) external onlyRegistered nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer != msg.sender) revert AuraEngine__StrategyNotFound();

        // Can withdraw if:
        // 1. Status is Approved (deposit returned by settleStrategyOutcome, but might fail)
        // 2. Status is Rejected (deposit returned during evaluation, but might fail)
        // 3. Status is Cancelled
        // 4. Status is Halted
        // 5. It hasn't received funds and is past funding period (implicitly handled by evaluateVotingOutcome).
        
        bool canWithdraw = false;
        if (strategy.status == StrategyStatus.Rejected || strategy.status == StrategyStatus.Cancelled || strategy.status == StrategyStatus.Halted) {
            canWithdraw = true;
        } else if (strategy.status == StrategyStatus.Approved && strategy.currentFunding == 0 && block.timestamp > strategy.endVoteTime + fundingPeriodDuration) {
            // If approved but never funded and funding period passed
            canWithdraw = true;
            strategy.status = StrategyStatus.Rejected; // Mark as rejected due to lack of funding
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Rejected);
        }

        if (!canWithdraw || strategy.proposalDeposit == 0) revert AuraEngine__ProposalDepositNotClaimable();

        uint256 deposit = strategy.proposalDeposit;
        strategy.proposalDeposit = 0; // Prevent double withdrawal

        (bool success,) = payable(msg.sender).call{value: deposit}("");
        if (!success) revert AuraEngine__InsufficientFunds(); // Revert if transfer fails
        emit ProposalDepositWithdrawn(msg.sender, _strategyId, deposit);
    }

    function emergencyHaltStrategy(uint256 _strategyId) external onlyPauser {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status == StrategyStatus.Executing || strategy.status == StrategyStatus.Funded) {
            strategy.status = StrategyStatus.Halted;
            // Additional logic: try to recover funds, close positions, etc. (implementation specific)
            // For now, it just changes status.
            emit StrategyHalted(_strategyId);
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Halted);
        } else {
            revert AuraEngine__StrategyNotExecutable(); // Can only halt active strategies
        }
    }

    function cancelStrategyProposal(uint256 _strategyId) external onlyRegistered {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.proposer != msg.sender) revert AuraEngine__StrategyNotFound();
        if (strategy.status != StrategyStatus.Proposed && strategy.status != StrategyStatus.Voting) {
            revert AuraEngine__StrategyNotProposable(); // Can only cancel if not approved/funded/executing
        }
        if (strategy.status == StrategyStatus.Voting && block.timestamp < strategy.endVoteTime) {
            // Cannot cancel if voting is active unless special conditions.
            // For simplicity, allow if before funding is complete.
        }

        // If a deposit was made, it can be reclaimed
        if (strategy.proposalDeposit > 0) {
            uint256 deposit = strategy.proposalDeposit;
            strategy.proposalDeposit = 0;
            (bool success,) = payable(msg.sender).call{value: deposit}("");
            if (!success) emit AuraEngine__InsufficientFunds(); // Log error, don't revert
        }
        
        strategy.status = StrategyStatus.Cancelled;
        emit StrategyCancelled(_strategyId);
        emit StrategyStatusChanged(_strategyId, StrategyStatus.Cancelled);
    }

    // --- E. Treasury & Rewards Functions ---

    function depositFundsForExecution(uint256 _strategyId, uint256 _amount) external onlyRegistered whenNotPaused nonReentrant {
        if (_amount == 0) revert AuraEngine__InvalidParameter();
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status != StrategyStatus.Approved) revert AuraEngine__StrategyNotFunded();
        if (block.timestamp > strategy.endVoteTime + fundingPeriodDuration) {
            // Funding period expired, mark strategy as rejected
            strategy.status = StrategyStatus.Rejected;
            emit StrategyStatusChanged(_strategyId, StrategyStatus.Rejected);
            revert AuraEngine__StrategyExpired();
        }

        if (acceptedToken.transferFrom(msg.sender, address(this), _amount)) {
            strategy.currentFunding += _amount;
            strategy.funders.push(msg.sender);
            strategy.funderAmounts.push(_amount);
            
            if (strategy.currentFunding >= strategy.fundingTarget) {
                strategy.status = StrategyStatus.Funded;
                emit StrategyStatusChanged(_strategyId, StrategyStatus.Funded);
            }
            emit FundsDepositedForExecution(msg.sender, _amount);
        } else {
            revert AuraEngine__InsufficientFunds();
        }
    }

    function withdrawStrategyProfit(uint256 _strategyId) external onlyRegistered nonReentrant {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.status != StrategyStatus.Settled) revert AuraEngine__StrategyNotSettleable();
        // Additional checks: ensure challenger bond is settled if challenged, etc.

        uint256 share = 0;
        for (uint256 i = 0; i < strategy.funders.length; i++) {
            if (strategy.funders[i] == msg.sender) {
                // Simplified: this assumes profit is already calculated and stored in participantRewards.
                // A more robust system would recalculate share based on final value of strategy.
                share = participantRewards[msg.sender]; 
                participantRewards[msg.sender] = 0; // Clear pending rewards
                break;
            }
        }

        if (share == 0) revert AuraEngine__NoProfitsToWithdraw();

        if (!acceptedToken.transfer(msg.sender, share)) {
            revert AuraEngine__InsufficientFunds(); // Should not happen if logic is correct
        }
        emit ProfitsWithdrawn(msg.sender, _strategyId, share);
    }

    function claimProtocolRewards() external onlyRegistered nonReentrant {
        uint256 rewards = participantRewards[msg.sender];
        if (rewards == 0) revert AuraEngine__NoRewardsToClaim();

        participantRewards[msg.sender] = 0; // Clear rewards

        if (!acceptedToken.transfer(msg.sender, rewards)) {
            revert AuraEngine__InsufficientFunds(); // Transfer failure
        }
        emit ProtocolRewardsClaimed(msg.sender, rewards);
    }

    // --- F. Oracle Interaction Functions ---

    // This function is for a trusted oracle to submit data, for example,
    // market prices at a specific time, or the outcome of an external event
    // that impacts a strategy. This would be called directly by the oracle.
    function submitOracleData(bytes32 _dataKey, uint256 _value) external onlyOracle whenNotPaused {
        // This is a generic oracle data submission.
        // For actual strategy settlement, `settleStrategyOutcome` is used,
        // which would internally use or verify this data or request specific data.
        // Example: If a strategy is "buy ETH if price < X, sell if price > Y",
        // the oracle could submit `_dataKey = keccak256("ETH_PRICE")`, `_value = currentPrice`.
        // The contract would then process this based on active strategies.
        // For simplicity, we assume `settleStrategyOutcome` directly receives the final outcome from oracle.
        // A more advanced system would have mapping for active data requests and their fulfillment.
        emit TrustedOracleSet(trustedOracle); // Re-emit to show activity, or a dedicated event
    }

    // --- View Functions (Getters) ---
    function getStrategyDetails(uint256 _strategyId) external view returns (Strategy memory) {
        return strategies[_strategyId];
    }

    function getParticipantDetails(address _participantAddr) external view returns (Participant memory) {
        return participants[_participantAddr];
    }
}
```