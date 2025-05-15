Okay, here is a Solidity smart contract concept called `QuantumTreasury`. It's designed as a sophisticated treasury management system incorporating elements of multi-asset handling, governance, strategy execution, flash loans, and a unique "quantum-inspired" probabilistic strategy selection mechanism using Chainlink VRF (simulating non-deterministic choice among approved strategies).

This contract aims to be advanced and creative by:
1.  Handling multiple ERC20 assets.
2.  Implementing a governance proposal and voting system.
3.  Allowing different investment/yield strategies managed on-chain (represented by target protocols/addresses).
4.  Using Chainlink VRF to probabilistically select one strategy to fund among multiple *approved* proposals that meet a threshold (the "quantum" non-deterministic choice).
5.  Supporting UUPS proxy pattern for upgradeability.
6.  Including a flash loan mechanism on the treasury's available assets.
7.  Integrating a basic performance tracking concept (though actual performance calculation is complex and often requires off-chain data/oracles).

It avoids duplicating standard ERC20/ERC721/governance token contracts themselves, focusing on the *management* layer with novel features.

---

**Outline and Function Summary**

**Contract:** `QuantumTreasury`

**Base Contracts:** `Ownable`, `ReentrancyGuard`, `ERC1967Upgrade`, `VRFConsumerBaseV2` (Chainlink)

**Concept:** A multi-asset treasury governed by token holders, capable of executing whitelisted investment strategies. Features include asset whitelisting, deposits/withdrawals, strategy proposals/voting/execution, a VRF-based probabilistic strategy selection mechanism, flash loans, and upgradeability.

**State Variables:**
*   `_owner`: Initial owner (can be transferred or renounced).
*   `_governanceToken`: ERC20 token used for voting power.
*   `whitelistedAssets`: Set of approved token addresses.
*   `strategyCounter`: Monotonically increasing ID for strategies.
*   `proposalCounter`: Monotonically increasing ID for proposals.
*   `proposals`: Mapping from proposal ID to `StrategyProposal` struct.
*   `strategies`: Mapping from strategy ID to `ActiveStrategy` struct.
*   `strategyAllocations`: Mapping from strategy ID to mapping from token address to allocated amount.
*   `proposalVotes`: Mapping from proposal ID to mapping from voter address to vote (bool: true for yay, false for nay).
*   `s_vrfCoordinator`: Address of the VRF Coordinator.
*   `s_keyHash`: Key hash used for VRF requests.
*   `s_subscriptionId`: Subscription ID for VRF.
*   `s_requestId`: Current VRF request ID.
*   `s_requestConfig`: Mapping from VRF request ID to the list of approved proposal IDs being considered for selection.

**Structs:**
*   `StrategyDetails`: Details of a proposed strategy (asset, amount, target, type, etc.).
*   `StrategyProposal`: Contains `StrategyDetails`, status, vote counts, expiry, etc.
*   `ActiveStrategy`: Contains `StrategyDetails` of an active strategy, execution time, performance data, etc.

**Events:**
*   `Initialized(uint8 version)`
*   `AssetWhitelisted(address indexed token)`
*   `AssetRemovedFromWhitelist(address indexed token)`
*   `FundsDeposited(address indexed token, address indexed depositor, uint256 amount)`
*   `FundsWithdrawn(address indexed token, address indexed recipient, uint256 amount)`
*   `StrategyProposed(uint256 indexed proposalId, address indexed proposer, StrategyDetails details)`
*   `StrategyVoted(uint256 indexed proposalId, address indexed voter, bool vote)`
*   `StrategyApproved(uint256 indexed proposalId)`
*   `VRFRequestedForSelection(uint256 indexed requestId, uint256[] approvedProposals)`
*   `StrategySelectedAndExecuting(uint256 indexed strategyId, uint256 indexed proposalId)`
*   `StrategyAllocationUpdated(uint256 indexed strategyId, address indexed token, uint256 newAmount)`
*   `StrategyLiquidated(uint256 indexed strategyId, address indexed liquidator)`
*   `PerformanceReported(uint256 indexed strategyId, int256 performance)`
*   `FlashLoan(address indexed receiver, address indexed token, uint256 amount)`
*   `GovernanceTokenSet(address indexed oldToken, address indexed newToken)`

**Modifiers:**
*   `onlyWhitelistedAsset(address tokenAddress)`
*   `onlyGovernance()` (Placeholder - requires actual governance logic based on token holdings/delegation)
*   `whenNotPaused` (Inherited from ReentrancyGuard, also serves as a basic pause functionality if needed)

**Functions (>= 20):**

1.  `initialize(address initialOwner, address govToken, address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId)`: Initializes the contract (UUPS pattern), sets owner, governance token, and VRF parameters.
2.  `whitelistAsset(address tokenAddress)`: Adds an ERC20 token to the list of approved assets for the treasury. (`onlyOwner`/`onlyGovernance`)
3.  `removeAssetFromWhitelist(address tokenAddress)`: Removes an ERC20 token from the whitelist. (`onlyOwner`/`onlyGovernance`)
4.  `isAssetWhitelisted(address tokenAddress)`: Checks if a token is currently whitelisted.
5.  `deposit(address tokenAddress, uint256 amount)`: Allows users to deposit whitelisted tokens into the treasury.
6.  `withdraw(address tokenAddress, uint256 amount, address recipient)`: Allows governance to withdraw whitelisted tokens from the available balance. (`onlyGovernance`)
7.  `getTotalAssetBalance(address tokenAddress)`: Returns the total balance of a token held by the treasury (available + allocated in strategies).
8.  `getAvailableAssetBalance(address tokenAddress)`: Returns the balance of a token not currently allocated to any strategy.
9.  `proposeStrategy(StrategyDetails memory details)`: Allows users (potentially requiring min gov token holdings) to propose a new investment strategy. Requires the proposed asset to be whitelisted. (`onlyGovernance` or weighted access)
10. `voteOnStrategy(uint256 proposalId, bool vote)`: Allows governance token holders to vote on a strategy proposal. (`onlyGovernance`)
11. `executeApprovedStrategiesVRF()`: Triggered by governance/time after voting period. Gathers approved proposals and requests random words from Chainlink VRF to select *one* among them probabilistically. (`onlyGovernance`)
12. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback function. Uses the random word to select one approved strategy from the list associated with the `requestId` and allocates funds to it. (`onlyVRFCoordinator`)
13. `updateStrategyAllocation(uint256 strategyId, address tokenAddress, uint256 newAmount)`: Allows governance to change the amount of a specific token allocated to an *active* strategy. Requires available balance or moving from another strategy (more complex). Simple version: increase allocation from available. (`onlyGovernance`)
14. `liquidateStrategy(uint256 strategyId)`: Initiates the process to exit a strategy, returning funds from the strategy's target protocol back to the treasury's available balance. (`onlyGovernance`)
15. `getStrategyDetails(uint256 strategyId)`: Retrieves the details of an active strategy.
16. `getProposalDetails(uint256 proposalId)`: Retrieves the details and current vote counts for a strategy proposal.
17. `reportStrategyPerformance(uint256 strategyId, int256 performanceChangeBps)`: Placeholder for receiving performance data (e.g., from an oracle or manual governance report). `performanceChangeBps` is change in basis points. (`onlyGovernance`)
18. `setGovernanceToken(address newGovToken)`: Allows governance to change the designated governance token. (`onlyOwner`/`onlyGovernance`)
19. `flashLoan(address receiver, address token, uint256 amount, bytes calldata data)`: Executes a flash loan of the specified token amount from the treasury's *available* balance. Requires the receiver contract to repay the amount + fee immediately.
20. `sweepTokens(address tokenAddress, address recipient)`: Emergency function to sweep *non-whitelisted* tokens accidentally sent to the contract. Use with extreme caution. (`onlyOwner`)
21. `getVersion()`: Returns the current version of the contract implementation (for UUPS).
22. `upgradeTo(address newImplementation)`: Upgrades the proxy to a new implementation contract. (`onlyOwner`)
23. `upgradeToAndCall(address newImplementation, bytes calldata data)`: Upgrades the proxy and calls a function on the new implementation (e.g., for data migration). (`onlyOwner`)
24. `withdrawLink(uint256 amount, address recipient)`: Allows withdrawing LINK token balance, necessary for paying VRF fees. (`onlyOwner`/`onlyGovernance`)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title QuantumTreasury
 * @dev A multi-asset treasury contract with governance, strategy execution,
 * UUPS upgradeability, Flash Loans, and a VRF-based probabilistic strategy selection.
 * The "Quantum" aspect refers to the non-deterministic selection among approved strategies
 * simulating a probabilistic choice using Chainlink VRF.
 */
contract QuantumTreasury is Initializable, UUPSUpgradeable, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    // Initialized via UUPS initialize function
    address private _governanceToken; // ERC20 token address used for voting power

    // Asset Management
    mapping(address => bool) private whitelistedAssets;
    address[] private whitelistedAssetList; // To easily iterate or check total count

    // Strategy Management
    uint256 private strategyCounter; // Unique ID for active strategies
    uint256 private proposalCounter; // Unique ID for strategy proposals

    enum ProposalStatus { Pending, Approved, Rejected, Executing, Completed }
    enum StrategyStatus { Active, Liquidating, Liquidated }
    enum StrategyType { Staking, Lending, YieldFarming, SwapBased, ProtocolSpecific } // Examples

    struct StrategyDetails {
        address asset;           // The asset to allocate
        uint256 amount;          // The amount of the asset to allocate
        address targetProtocol;  // The contract/protocol address for the strategy
        StrategyType strategyType; // Type of strategy
        string name;             // Name of the strategy
        bytes executionData;     // ABI encoded data for the call to targetProtocol
    }

    struct StrategyProposal {
        uint256 id;
        address proposer;
        StrategyDetails details;
        uint256 submissionTime;
        uint256 votingPeriodEnd; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        bool executed; // Whether this proposal led to an active strategy
        uint256 enactedStrategyId; // The ID of the strategy if executed
    }

    struct ActiveStrategy {
        uint256 id;
        uint256 proposalId; // The proposal this strategy originated from
        StrategyDetails details; // Details copied from the proposal
        uint256 executionTime;
        StrategyStatus status;
        int256 cumulativePerformanceBps; // Cumulative performance in basis points relative to initial allocation
    }

    mapping(uint256 => StrategyProposal) public proposals;
    mapping(uint256 => ActiveStrategy) public strategies;
    // Tracks allocation per strategy per token. strategyAllocations[strategyId][tokenAddress] => amount
    mapping(uint256 => mapping(address => uint256)) private strategyAllocations;

    // Governance Voting
    mapping(uint256 => mapping(address => bool)) private proposalVotes; // proposalId => voterAddress => hasVoted
    // Note: Actual vote weight based on _governanceToken balance/delegation would be implemented in getVotes()

    // Chainlink VRF for probabilistic strategy selection
    VRFCoordinatorV2Interface public s_vrfCoordinator;
    bytes32 public s_keyHash;
    uint64 public s_subscriptionId;

    // Map requestId to the list of approved proposal IDs being considered
    mapping(uint256 => uint256[]) private s_requestConfig;
    // Map requestId to the number of words requested (should be 1 for single selection)
    mapping(uint256 => uint16) private s_requestsNumWords;
    // Map requestId to the sender (for context if needed, though not strictly required here)
    mapping(uint256 => address) private s_requestSender;

    // --- Events ---

    event Initialized(uint8 version);
    event AssetWhitelisted(address indexed token);
    event AssetRemovedFromWhitelist(address indexed token);
    event FundsDeposited(address indexed token, address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event StrategyProposed(uint256 indexed proposalId, address indexed proposer, StrategyDetails details);
    event StrategyVoted(uint256 indexed proposalId, address indexed voter, bool vote); // true = For, false = Against
    event StrategyApproved(uint256 indexed proposalId); // Proposal reached approval threshold
    event VRFRequestedForSelection(uint256 indexed requestId, uint256[] approvedProposals);
    event StrategySelectedAndExecuting(uint256 indexed strategyId, uint256 indexed proposalId, address indexed asset, uint256 amount, address targetProtocol);
    event StrategyAllocationUpdated(uint256 indexed strategyId, address indexed token, uint256 newAmount);
    event StrategyLiquidated(uint256 indexed strategyId, address indexed liquidator);
    event PerformanceReported(uint256 indexed strategyId, int256 performance); // Performance change in BPS
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount);
    event GovernanceTokenSet(address indexed oldToken, address indexed newToken);
    event LinkWithdrawn(uint256 amount, address indexed recipient);

    // --- Modifiers ---

    modifier onlyWhitelistedAsset(address tokenAddress) {
        require(whitelistedAssets[tokenAddress], "QuantumTreasury: Asset not whitelisted");
        _;
    }

    // Placeholder for actual governance check based on voting power
    // In a full implementation, this would check sender's voting power against a threshold
    modifier onlyGovernance() {
        // Replace this with real governance logic checking _governanceToken balance/delegation
        // For simplicity in this example, we'll allow the owner or specific addresses,
        // or just make itWithOwner temporarily for demonstration.
        // In a production system, this MUST involve the governance token.
        // For this example, let's assume only owner can trigger governance actions.
        // This should be replaced with actual governance multisig/DAO logic.
        require(msg.sender == owner(), "QuantumTreasury: Caller is not governance");
        _;
    }

    // --- Initializer (UUPS) ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() VRFConsumerBaseV2(0) {} // Dummy constructor for upgradeability base

    /**
     * @dev Initializes the QuantumTreasury contract.
     * @param initialOwner The address that will initially own the contract (can be DAO/multisig).
     * @param govToken The address of the ERC20 governance token.
     * @param vrfCoordinator The address of the Chainlink VRF Coordinator.
     * @param keyHash The key hash for VRF requests.
     * @param subscriptionId The subscription ID for the VRF service.
     */
    function initialize(
        address initialOwner,
        address govToken,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(govToken != address(0), "QuantumTreasury: Zero address gov token");
        require(vrfCoordinator != address(0), "QuantumTreasury: Zero address VRF coordinator");
        require(keyHash != bytes32(0), "QuantumTreasury: Zero key hash");
        // subscriptionId can be 0 initially if not set up, but should be set before using VRF

        _governanceToken = govToken;
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;

        strategyCounter = 0;
        proposalCounter = 0;

        emit Initialized(1); // Version 1
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- Asset Management ---

    /**
     * @dev Whitelists an ERC20 token address. Only whitelisted tokens can be deposited or used in strategies.
     * @param tokenAddress The address of the ERC20 token.
     */
    function whitelistAsset(address tokenAddress) external onlyGovernance {
        require(tokenAddress != address(0), "QuantumTreasury: Zero address asset");
        require(!whitelistedAssets[tokenAddress], "QuantumTreasury: Asset already whitelisted");
        whitelistedAssets[tokenAddress] = true;
        whitelistedAssetList.push(tokenAddress);
        emit AssetWhitelisted(tokenAddress);
    }

    /**
     * @dev Removes an ERC20 token address from the whitelist.
     * Cannot remove assets that are currently allocated in active strategies.
     * @param tokenAddress The address of the ERC20 token.
     */
    function removeAssetFromWhitelist(address tokenAddress) external onlyGovernance {
        require(whitelistedAssets[tokenAddress], "QuantumTreasury: Asset not whitelisted");

        // Check if asset is allocated in any active strategy
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Active && strategyAllocations[i][tokenAddress] > 0) {
                revert("QuantumTreasury: Asset allocated in active strategy");
            }
        }

        whitelistedAssets[tokenAddress] = false;
        // Remove from list (simple swap and pop, order doesn't matter)
        uint256 index = type(uint256).max;
        for(uint256 i = 0; i < whitelistedAssetList.length; i++) {
            if(whitelistedAssetList[i] == tokenAddress) {
                index = i;
                break;
            }
        }
        if (index != type(uint256).max) {
             if (index != whitelistedAssetList.length - 1) {
                whitelistedAssetList[index] = whitelistedAssetList[whitelistedAssetList.length - 1];
            }
            whitelistedAssetList.pop();
        }

        emit AssetRemovedFromWhitelist(tokenAddress);
    }

    /**
     * @dev Checks if a token is currently whitelisted.
     * @param tokenAddress The address of the ERC20 token.
     * @return bool True if whitelisted, false otherwise.
     */
    function isAssetWhitelisted(address tokenAddress) external view returns (bool) {
        return whitelistedAssets[tokenAddress];
    }

    /**
     * @dev Deposits whitelisted tokens into the treasury.
     * Requires the user to have pre-approved the token transfer.
     * @param tokenAddress The address of the whitelisted ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address tokenAddress, uint256 amount) external nonReentrant onlyWhitelistedAsset(tokenAddress) {
        require(amount > 0, "QuantumTreasury: Deposit amount must be greater than zero");
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        emit FundsDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Allows governance to withdraw available whitelisted tokens from the treasury.
     * Does not withdraw funds allocated in active strategies.
     * @param tokenAddress The address of the whitelisted ERC20 token.
     * @param amount The amount of tokens to withdraw.
     * @param recipient The address to send the tokens to.
     */
    function withdraw(address tokenAddress, uint256 amount, address recipient) external onlyGovernance nonReentrant onlyWhitelistedAsset(tokenAddress) {
        require(amount > 0, "QuantumTreasury: Withdraw amount must be greater than zero");
        require(recipient != address(0), "QuantumTreasury: Zero address recipient");
        uint256 availableBalance = getAvailableAssetBalance(tokenAddress);
        require(availableBalance >= amount, "QuantumTreasury: Insufficient available balance");

        IERC20(tokenAddress).safeTransfer(recipient, amount);
        emit FundsWithdrawn(tokenAddress, recipient, amount);
    }

    /**
     * @dev Gets the total balance of a token held by the treasury, including allocated funds.
     * @param tokenAddress The address of the ERC20 token.
     * @return uint256 The total balance.
     */
    function getTotalAssetBalance(address tokenAddress) public view onlyWhitelistedAsset(tokenAddress) returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Gets the available balance of a token (total balance minus allocated funds).
     * @param tokenAddress The address of the ERC20 token.
     * @return uint256 The available balance.
     */
    function getAvailableAssetBalance(address tokenAddress) public view onlyWhitelistedAsset(tokenAddress) returns (uint256) {
        uint256 totalAllocated = 0;
        for (uint256 i = 1; i <= strategyCounter; i++) {
            if (strategies[i].status == StrategyStatus.Active) {
                 totalAllocated += strategyAllocations[i][tokenAddress];
            }
        }
        uint256 totalBalance = getTotalAssetBalance(tokenAddress);
        // Should never underflow if logic is correct, but safety check
        return totalBalance >= totalAllocated ? totalBalance - totalAllocated : 0;
    }

     /**
     * @dev Returns the list of all whitelisted asset addresses.
     * @return address[] Array of whitelisted token addresses.
     */
    function getWhitelistedAssets() external view returns (address[] memory) {
        return whitelistedAssetList;
    }


    // --- Strategy Management & Governance ---

    /**
     * @dev Allows a user (with sufficient governance power) to propose a new investment strategy.
     * Requires the asset to be whitelisted. Sets a voting period.
     * @param details The StrategyDetails struct containing proposal specifics.
     */
    function proposeStrategy(StrategyDetails memory details) external onlyGovernance {
        require(details.asset != address(0), "QuantumTreasury: Proposal asset zero address");
        require(details.amount > 0, "QuantumTreasury: Proposal amount zero");
        require(details.targetProtocol != address(0), "QuantumTreasury: Proposal target zero address");
        require(whitelistedAssets[details.asset], "QuantumTreasury: Proposal asset not whitelisted");
        // Add more validation on details.executionData if format is standardized

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        // Define voting period duration (e.g., 3 days)
        uint256 votingDuration = 3 days; // Example duration

        proposals[proposalId] = StrategyProposal({
            id: proposalId,
            proposer: msg.sender,
            details: details,
            submissionTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            executed: false,
            enactedStrategyId: 0
        });

        emit StrategyProposed(proposalId, msg.sender, details);
    }

    /**
     * @dev Allows governance token holders to vote on a strategy proposal.
     * Requires voting to be open and the voter to have sufficient voting power.
     * @param proposalId The ID of the proposal to vote on.
     * @param vote True for 'For', False for 'Against'.
     */
    function voteOnStrategy(uint256 proposalId, bool vote) external nonReentrant onlyGovernance {
        StrategyProposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "QuantumTreasury: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "QuantumTreasury: Voting not open for this proposal");
        require(block.timestamp <= proposal.votingPeriodEnd, "QuantumTreasury: Voting period has ended");
        require(!proposalVotes[proposalId][msg.sender], "QuantumTreasury: Already voted on this proposal");

        // In a real system, get vote weight based on governance token balance/delegation
        uint256 voteWeight = getVotes(msg.sender); // Placeholder: Implement getVotes()
        require(voteWeight > 0, "QuantumTreasury: Caller has no voting power");

        proposalVotes[proposalId][msg.sender] = true;

        if (vote) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        emit StrategyVoted(proposalId, msg.sender, vote);
    }

    /**
     * @dev Placeholder function to get a user's voting power.
     * In a real implementation, this would read balance/delegation from _governanceToken.
     * @param account The address to get votes for.
     * @return uint256 The voting power of the account.
     */
    function getVotes(address account) public view returns (uint256) {
        // This is a placeholder.
        // A real implementation would likely use ERC20Votes or read historical balances.
        // Example using ERC20Votes: return IERC20Votes(_governanceToken).getVotes(account);
        // For this example, let's just return 1 for the owner, 0 otherwise.
        if (account == owner()) return 1; // Simple example for owner to trigger actions
        return 0; // Default 0 for others
    }

    /**
     * @dev Triggered after voting period ends. Identifies approved proposals
     * that meet a threshold and requests VRF random words to select one probabilistically.
     * Only one VRF request can be pending at a time per type (strategy selection).
     */
    function executeApprovedStrategiesVRF() external onlyGovernance nonReentrant {
        uint256[] memory approvedProposalIds = new uint256[](0);
        uint256 quorumThreshold = 5; // Example: Minimum total votes needed
        uint256 approvalThresholdBps = 6000; // Example: 60% 'For' votes needed (in BPS)

        for (uint256 i = 1; i <= proposalCounter; i++) {
            StrategyProposal storage proposal = proposals[i];
            // Check if voting period ended and proposal is still Pending
            if (proposal.status == ProposalStatus.Pending && block.timestamp > proposal.votingPeriodEnd) {
                uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

                if (totalVotes >= quorumThreshold) {
                    // Check approval percentage
                    if (proposal.votesFor * 10000 / totalVotes >= approvalThresholdBps) {
                         // Meets quorum and approval threshold -> Approved
                         proposal.status = ProposalStatus.Approved;
                         approvedProposalIds.push(proposal.id);
                         emit StrategyApproved(proposal.id);
                    } else {
                         // Meets quorum but fails approval -> Rejected
                         proposal.status = ProposalStatus.Rejected;
                    }
                } else {
                    // Fails quorum -> Rejected
                    proposal.status = ProposalStatus.Rejected;
                }
            }
        }

        require(approvedProposalIds.length > 0, "QuantumTreasury: No proposals approved meeting thresholds");
        // Ensure no VRF request is currently pending for strategy selection
        require(s_requestId == 0, "QuantumTreasury: VRF request already pending"); // Simple check

        // Request a single random word to select from the approved list
        uint32 numWords = 1;
        uint32 callbackGasLimit = 300000; // Set appropriate gas limit for fulfillRandomWords

        s_requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations, // Inherited from VRFConsumerBaseV2
            callbackGasLimit,
            numWords
        );

        s_requestConfig[s_requestId] = approvedProposalIds;
        s_requestsNumWords[s_requestId] = numWords;
        s_requestSender[s_requestId] = msg.sender; // Store sender context if needed

        emit VRFRequestedForSelection(s_requestId, approvedProposalIds);
    }

    /**
     * @dev Chainlink VRF callback function. Receives random words and selects/executes one strategy.
     * This function is called by the VRF Coordinator.
     * @param requestId The ID of the VRF request.
     * @param randomWords Array of random words (we expect one).
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(s_requestsNumWords[requestId] == 1, "QuantumTreasury: Unexpected number of random words"); // Ensure it's our request type
        require(s_requestConfig[requestId].length > 0, "QuantumTreasury: No approved proposals found for requestId"); // Ensure config exists

        uint256[] memory approvedProposals = s_requestConfig[requestId];
        uint256 randomIndex = randomWords[0] % approvedProposals.length;
        uint256 selectedProposalId = approvedProposals[randomIndex];

        StrategyProposal storage selectedProposal = proposals[selectedProposalId];
        // Double check status, though fulfill should only run once per request
        require(selectedProposal.status == ProposalStatus.Approved, "QuantumTreasury: Selected proposal not in Approved state");

        // --- Execute the selected strategy ---
        strategyCounter++;
        uint256 newStrategyId = strategyCounter;
        StrategyDetails memory details = selectedProposal.details;

        // Check available balance BEFORE attempting allocation/transfer
        uint256 availableBalance = getAvailableAssetBalance(details.asset);
        require(availableBalance >= details.amount, "QuantumTreasury: Insufficient available balance for selected strategy");

        strategies[newStrategyId] = ActiveStrategy({
            id: newStrategyId,
            proposalId: selectedProposalId,
            details: details,
            executionTime: block.timestamp,
            status: StrategyStatus.Active,
            cumulativePerformanceBps: 0 // Starts at 0
        });

        // Record the allocation
        strategyAllocations[newStrategyId][details.asset] = details.amount;

        // Mark the proposal as executed
        selectedProposal.status = ProposalStatus.Executing; // Temporary status during execution
        selectedProposal.executed = true;
        selectedProposal.enactedStrategyId = newStrategyId;

        // Transfer funds to the target protocol and execute the strategy logic
        // Use low-level call to interact with arbitrary protocols
        IERC20(details.asset).safeTransfer(details.targetProtocol, details.amount);

        // Execute the specific strategy action on the target protocol if executionData is provided
        // This assumes the targetProtocol is a smart contract and expects details.executionData
        if (details.executionData.length > 0) {
             (bool success, bytes memory returndata) = details.targetProtocol.call(details.executionData);
             // Decide if a failed execution should revert the whole transaction or just log
             // For a treasury, reverting might be safer to prevent locking funds.
             require(success, string(abi.encodePacked("QuantumTreasury: Strategy execution failed: ", returndata)));
        }

        // Mark as Active after successful execution
        strategies[newStrategyId].status = StrategyStatus.Active;
        selectedProposal.status = ProposalStatus.Completed; // Proposal completed after strategy is active

        emit StrategySelectedAndExecuting(newStrategyId, selectedProposalId, details.asset, details.amount, details.targetProtocol);

        // Cleanup VRF request state
        delete s_requestConfig[requestId];
        delete s_requestsNumWords[requestId];
        delete s_requestSender[requestId];
        s_requestId = 0; // Reset requestId to indicate no pending request
    }


    /**
     * @dev Allows governance to change the allocated amount for an active strategy.
     * Can increase allocation from available balance. Decreasing frees up balance.
     * @param strategyId The ID of the active strategy.
     * @param tokenAddress The token address within the strategy allocation.
     * @param newAmount The new total amount to allocate to this strategy for this token.
     */
    function updateStrategyAllocation(uint256 strategyId, address tokenAddress, uint256 newAmount) external onlyGovernance nonReentrant onlyWhitelistedAsset(tokenAddress) {
        ActiveStrategy storage strategy = strategies[strategyId];
        require(strategy.id != 0 && strategy.status == StrategyStatus.Active, "QuantumTreasury: Strategy not active");

        uint256 currentAmount = strategyAllocations[strategyId][tokenAddress];

        if (newAmount > currentAmount) {
            uint256 increaseAmount = newAmount - currentAmount;
            uint256 availableBalance = getAvailableAssetBalance(tokenAddress); // Gets available balance considering *all* strategies
            require(availableBalance >= increaseAmount, "QuantumTreasury: Insufficient available balance to increase allocation");

            // Logic to send the `increaseAmount` to the targetProtocol and potentially execute data
            // This is complex as it depends on the specific strategy protocol interface.
            // For this example, we only update the internal allocation record.
            // A real system needs to interact with targetProtocol to deploy/stake the additional funds.
            // IERC20(tokenAddress).safeTransfer(strategy.details.targetProtocol, increaseAmount);
            // Maybe call strategy.details.targetProtocol with specific data...
            // require(strategy.details.targetProtocol.call(abi.encode(...)), "Failed to deploy additional funds");

        } else if (newAmount < currentAmount) {
             uint256 decreaseAmount = currentAmount - newAmount;
             // Logic to retrieve `decreaseAmount` from the targetProtocol.
             // This is also complex and depends on the specific strategy protocol interface.
             // For this example, we only update the internal allocation record.
             // A real system needs to interact with targetProtocol to unstake/redeem funds.
             // require(strategy.details.targetProtocol.call(abi.encode(...)), "Failed to retrieve funds");
             // IERC20(tokenAddress).safeTransferFrom(strategy.details.targetProtocol, address(this), decreaseAmount); // Might need allowance
        }

        strategyAllocations[strategyId][tokenAddress] = newAmount;

        emit StrategyAllocationUpdated(strategyId, tokenAddress, newAmount);
    }


    /**
     * @dev Initiates the process to liquidate (exit) an active strategy.
     * Funds should be returned from the target protocol to the treasury.
     * Actual retrieval logic depends on the target protocol and is not fully implemented here.
     * @param strategyId The ID of the strategy to liquidate.
     */
    function liquidateStrategy(uint256 strategyId) external onlyGovernance nonReentrant {
        ActiveStrategy storage strategy = strategies[strategyId];
        require(strategy.id != 0 && strategy.status == StrategyStatus.Active, "QuantumTreasury: Strategy not active");

        strategy.status = StrategyStatus.Liquidating; // Mark as liquidating

        // --- Interaction with Target Protocol (Placeholder) ---
        // This is the most complex part, depending on the specific strategy protocol.
        // It would involve calling a 'redeem', 'unstake', or similar function on `strategy.details.targetProtocol`.
        // You might need stored information about the 'position' within the protocol,
        // which would need to be saved during strategy execution.
        // Example:
        // (bool success, bytes memory returndata) = strategy.details.targetProtocol.call(abi.encodeCall(ITargetProtocol.redeem, (strategy.positionId)));
        // require(success, string(abi.encodePacked("QuantumTreasury: Liquidation call failed: ", returndata)));
        // The tokens would then be transferred *back* to this contract's address by the target protocol.

        // For this example, we will just assume the funds are returned immediately after this call.
        // In reality, this might be a multi-step process or require waiting.
        // Need to verify that the allocated tokens + yield (if any) have been returned.

        // Mark as Liquidated after assumed return (in reality, would verify balance increase)
        strategy.status = StrategyStatus.Liquidated;
        // Note: We don't zero out strategyAllocations here immediately, as the balance check
        // and getAvailableAssetBalance() logic rely on it being non-zero until funds are retrieved.
        // A more robust system would track return process.

        emit StrategyLiquidated(strategyId, msg.sender);
    }

    /**
     * @dev Allows governance to report performance change for an active strategy.
     * This is a simplified model; real performance tracking is complex.
     * @param strategyId The ID of the active strategy.
     * @param performanceChangeBps The change in performance in basis points (e.g., 100 for +1%, -50 for -0.5%).
     */
    function reportStrategyPerformance(uint256 strategyId, int256 performanceChangeBps) external onlyGovernance {
        ActiveStrategy storage strategy = strategies[strategyId];
        require(strategy.id != 0 && strategy.status == StrategyStatus.Active, "QuantumTreasury: Strategy not active");

        // Update cumulative performance
        strategy.cumulativePerformanceBps += performanceChangeBps;

        emit PerformanceReported(strategyId, performanceChangeBps);
    }

    /**
     * @dev Gets the details of an active strategy.
     * @param strategyId The ID of the strategy.
     * @return ActiveStrategy struct.
     */
    function getStrategyDetails(uint256 strategyId) public view returns (ActiveStrategy memory) {
        require(strategies[strategyId].id != 0, "QuantumTreasury: Strategy does not exist");
        return strategies[strategyId];
    }

     /**
     * @dev Gets the allocated amount for a specific token within an active strategy.
     * @param strategyId The ID of the strategy.
     * @param tokenAddress The address of the token.
     * @return uint256 The allocated amount.
     */
    function getStrategyAllocatedAmount(uint256 strategyId, address tokenAddress) public view returns (uint256) {
        require(strategies[strategyId].id != 0, "QuantumTreasury: Strategy does not exist");
        return strategyAllocations[strategyId][tokenAddress];
    }

    /**
     * @dev Gets the details of a strategy proposal.
     * @param proposalId The ID of the proposal.
     * @return StrategyProposal struct.
     */
    function getProposalDetails(uint256 proposalId) public view returns (StrategyProposal memory) {
         require(proposals[proposalId].id != 0, "QuantumTreasury: Proposal does not exist");
         return proposals[proposalId];
    }

    /**
     * @dev Sets the governance token address. Can only be called once initially,
     * or subsequent changes require existing governance approval.
     * @param newGovToken The address of the new ERC20 governance token.
     */
    function setGovernanceToken(address newGovToken) external onlyGovernance {
        require(newGovToken != address(0), "QuantumTreasury: Zero address gov token");
        address oldToken = _governanceToken;
        _governanceToken = newGovToken;
        emit GovernanceTokenSet(oldToken, newGovToken);
    }

    /**
     * @dev Returns the address of the current governance token.
     * @return address The governance token address.
     */
    function getGovernanceToken() external view returns (address) {
        return _governanceToken;
    }


    // --- Advanced / Utility ---

    /**
     * @dev Allows a flash loan of an available asset from the treasury.
     * The `receiver` contract must implement `IERC3156FlashLoanRecipient`.
     * @param receiver The address of the contract receiving the loan.
     * @param token The address of the token being loaned.
     * @param amount The amount of the token being loaned.
     * @param data Optional data to pass to the receiver's callback.
     */
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant onlyWhitelistedAsset(token) {
        require(amount > 0, "QuantumTreasury: Flash loan amount must be greater than zero");
        uint256 availableBalance = getAvailableAssetBalance(token);
        require(availableBalance >= amount, "QuantumTreasury: Insufficient available balance for flash loan");

        // Calculate flash loan fee (e.g., 0.09%, 9 basis points)
        uint256 fee = (amount * 9) / 10000; // 0.09% fee
        uint256 amountPlusFee = amount + fee;

        // Transfer loan amount to receiver
        IERC20(token).safeTransfer(receiver, amount);

        // Call receiver's onFlashLoan function
        IERC3156FlashLoanRecipient recipientContract = IERC3156FlashLoanRecipient(receiver);
        require(
            recipientContract.onFlashLoan(msg.sender, token, amount, fee, data) ==
            IERC3156FlashLoanRecipient.onFlashLoan.selector,
            "QuantumTreasury: Flash loan callback failed"
        );

        // Verify full repayment + fee
        require(
            IERC20(token).balanceOf(address(this)) >= availableBalance + fee, // Check if balance increased by at least the fee (original amount returned + fee)
            "QuantumTreasury: Flash loan repayment failed"
        );

        // Note: This assumes the fee stays in the treasury. You might want to handle fees differently.

        emit FlashLoan(receiver, token, amount);
    }

    /**
     * @dev Emergency function to sweep non-whitelisted tokens accidentally sent to the contract.
     * Use with extreme caution. Only callable by the owner.
     * @param tokenAddress The address of the token to sweep.
     * @param recipient The address to send the tokens to.
     */
    function sweepTokens(address tokenAddress, address recipient) external onlyOwner {
        require(tokenAddress != address(0), "QuantumTreasury: Cannot sweep zero address");
        require(recipient != address(0), "QuantumTreasury: Zero address recipient");
        // Prevent sweeping whitelisted assets via this function
        require(!whitelistedAssets[tokenAddress], "QuantumTreasury: Cannot sweep whitelisted assets via this function");
        // Prevent sweeping ETH (if contract holds ETH, though this is ERC20 focused)
        // require(tokenAddress != address(0) || tokenAddress != 0xEeeeeEeeeEeSpeakForTheDeadEeEeEeEe); // WETH or native check

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(recipient, balance);
        }
        // No specific event defined for this, could add one if needed.
    }

    /**
     * @dev Allows governance to withdraw LINK tokens from the contract, which are needed to pay VRF fees.
     * @param amount The amount of LINK to withdraw.
     * @param recipient The address to send the LINK to.
     */
    function withdrawLink(uint256 amount, address recipient) external onlyGovernance {
        require(amount > 0, "QuantumTreasury: Withdraw amount must be greater than zero");
        require(recipient != address(0), "QuantumTreasury: Zero address recipient");
        // Assumes LINK token address is known or passed in initialize
        // For Chainlink VRF v2, LINK token is a constant on each chain.
        // Eg: Polygon Mainnet LINK is 0xb0897686c5450723a5f34223e37eeac99ac9f66b
        // You should import/define the correct LINK address for your target chain.
        address linkTokenAddress = 0xb0897686c5450723a5f34223e37eeac99ac9f66b; // Example: Polygon Mainnet LINK
        IERC20(linkTokenAddress).safeTransfer(recipient, amount);
        emit LinkWithdrawn(amount, recipient);
    }


    // --- Getters for VRF state ---
    function getRequestId() external view returns (uint256) {
        return s_requestId;
    }
    function getRequestConfig(uint256 requestId) external view returns (uint256[] memory) {
        return s_requestConfig[requestId];
    }

    // --- UUPS Upgradeability ---
    // Inherited getVersion, upgradeTo, upgradeToAndCall

}


// Interface for Flash Loan Receiver (IERC3156 standard)
// Simplified for this example, can use full standard from OpenZeppelin if available
interface IERC3156FlashLoanRecipient {
    /**
     * @dev Callback function that is called when a flash loan is executed.
     * The borrower returns the funds and fee here.
     * @param initiator The address that initiated the flash loan.
     * @param token The address of the token that was loaned.
     * @param amount The amount of the token that was loaned.
     * @param fee The fee for the flash loan.
     * @param data Optional data passed by the initiator.
     * @return bytes4 The selector of the function (i.e., `bytes4(keccak256("onFlashLoan(address,address,uint256,uint256,bytes)"))`).
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes4);
}
```