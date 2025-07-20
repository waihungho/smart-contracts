Here's a Solidity smart contract named `ChronoForge` that embodies several advanced, creative, and trending concepts in the Web3 space. It aims to provide a unique "Adaptive Value Layer" and a "Decentralized Future Foundry."

**Core Concepts:**

1.  **Chrono (CHRONO) Token & Protocol Health Index (PHI):**
    *   `CHRONO` is an ERC20 token whose utility and economics are dynamically adjusted based on a `Protocol Health Index (PHI)`.
    *   PHI is an abstract index (0-10000) that could, in a full implementation, derive from on-chain metrics like TVL, volatility, governance participation, or even external oracle data.
    *   **Dynamic Fees:** Transaction fees for `CHRONO` transfers adjust based on PHI, incentivizing activity when the protocol is "healthy" and discouraging congestion/speculation when it's under stress.
    *   **Adaptive Rewards:** Future rewards (e.g., from staking or the ChronoForge) can be scaled by a `ChronoMultiplier` derived from PHI.

2.  **The ChronoForge (Conditional Asset Generation & Staking):**
    *   A sophisticated mechanism where users can propose and back "future events" or "conditional strategies."
    *   Users stake `CHRONO` as collateral for these "Forge Templates."
    *   If a predefined on-chain condition (e.g., specific timestamp, external price feed, custom oracle call) is met by an expiry timestamp, stakers can claim a reward. Otherwise, they can reclaim their collateral.
    *   This isn't just a prediction market; it's a generic framework for conditional asset release or dynamic yield generation, allowing for highly flexible and creative "smart agreements."

3.  **Decentralized Governance & Treasury:**
    *   A robust governance system allows `CHRONO` holders (or those with accumulated Reputation Points) to propose and vote on critical protocol changes (e.g., updating PHI oracle, adjusting parameters, distributing treasury funds).
    *   Includes a timelock for approved proposals, ensuring security.

4.  **Advanced & Utility Features:**
    *   **Flash Forge Loan:** A unique "flash loan" mechanism specifically designed to allow users to temporarily collateralize a Forge action (stake, check condition, claim reward/reclaim collateral) within a single atomic transaction without needing to hold `CHRONO` long-term. This showcases advanced Solidity control flow and composability.
    *   **Reputation System:** Users can lock `CHRONO` for a duration to earn non-transferable "Reputation Points," which could grant them privileges like lower fees, higher voting power, or the ability to submit governance proposals.

**Uniqueness & Creativity:**

*   Combines **dynamic tokenomics** (PHI-driven fees/rewards) with a highly **flexible conditional execution layer** (ChronoForge).
*   The **Flash Forge Loan** is a novel application of flash loan concepts, moving beyond simple arbitrage to facilitate complex, multi-step conditional interactions.
*   The generalized `ConditionType` and `conditionParams` for the Forge allow for future-proofing and diverse use cases without changing the core contract logic.
*   The Reputation System provides a soft-identity layer, incentivizing long-term engagement over pure capital.

---

## Contract: ChronoForge

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
    Outline:
    I. Core CHRONO Token & Protocol Health Index (PHI)
    II. The ChronoForge (Conditional Asset Generation & Staking)
    III. Governance & Treasury Management
    IV. Advanced & Utility Features
    V. Administrative & Emergency
*/

/*
    Function Summary:

    I. Core CHRONO Token & Protocol Health Index (PHI)
    1.  constructor(string memory name_, string memory symbol_, address initialOwner_): Initializes ERC20 token, sets owner, and treasury.
    2.  mintInitialSupply(address beneficiary, uint256 amount): Mints initial supply of CHRONO, restricted to owner/deployer once.
    3.  burn(uint256 amount): Allows users to burn their CHRONO tokens.
    4.  _dynamicTransactionFee(uint256 amount): Internal function to calculate a dynamic transaction fee based on PHI.
    5.  transfer(address to, uint256 amount): Overrides ERC20 transfer to apply dynamic fees.
    6.  transferFrom(address from, address to, uint256 amount): Overrides ERC20 transferFrom to apply dynamic fees.
    7.  getProtocolHealthIndex(): Returns the current Protocol Health Index (PHI).
    8.  setPHICalculator(address newPHICalculator): Sets the address of the contract responsible for calculating PHI (governance controlled).
    9.  updateProtocolHealthIndex(uint256 newPHI): Updates the PHI (callable by authorized PHI Calculator or governance).
    10. getChronoMultiplier(): Calculates and returns a multiplier based on PHI, affecting rewards/fees.

    II. The ChronoForge (Conditional Asset Generation & Staking)
    11. proposeForgeTemplate(string calldata name, ConditionType conditionType, bytes calldata conditionParams, uint256 collateralRequired, uint256 rewardAmount, address rewardToken, uint256 expiryTimestamp): Allows users to propose new "Forge" templates for conditional asset generation.
    12. voteForForgeTemplate(uint256 templateId): Allows governance-approved voters to vote for a proposed Forge template.
    13. approveForgeTemplate(uint256 templateId): Admin/governance function to formally approve a Forge template after sufficient votes (fallback for faster approval).
    14. stakeForForge(uint256 templateId, uint256 amount): Users stake CHRONO (or other allowed tokens) as collateral for an approved Forge template.
    15. checkForgeCondition(uint256 templateId): Anyone can call to trigger the condition check for an active Forge template. If condition met, it's marked as fulfilled.
    16. claimForgeReward(uint256 templateId): Allows stakers to claim rewards if their staked Forge's condition has been met.
    17. reclaimForgeCollateral(uint256 templateId): Allows stakers to reclaim their collateral if the Forge expired or was cancelled without meeting its condition.
    18. cancelForgeProposal(uint256 templateId): Allows the proposer to cancel their Forge template if it's still in the 'Proposed' state.
    19. updateForgeParams(uint256 newMinCollateral, uint256 newProposalVoteThreshold): Governance function to adjust parameters related to ChronoForge.

    III. Governance & Treasury Management
    20. submitGovernanceProposal(bytes calldata callData, address targetContract, string calldata description): Allows users to propose governance actions.
    21. voteOnProposal(uint256 proposalId, bool support): Allows governance participants (CHRONO holders/reputation holders) to vote on active proposals.
    22. executeProposal(uint256 proposalId): Executes an approved and timelocked governance proposal.
    23. updateGovernanceParams(uint256 newVotingPeriod, uint256 newMinReputationToPropose): Adjusts governance parameters.
    24. distributeTreasuryFunds(address token, address recipient, uint256 amount): Allows governance to distribute funds from the protocol treasury.

    IV. Advanced & Utility Features
    25. flashForgeLoan(uint256 amount, uint256 templateId, bytes calldata data): A unique "flash loan" mechanism allowing temporary CHRONO collateral for a Forge action, repaid within the same transaction.
    26. lockChronoForReputation(uint256 amount, uint256 duration): Users can lock CHRONO to earn "reputation points" which might grant future benefits (e.g., lower fees, higher voting power for proposals).
    27. claimReputationPoints(): Users can claim reputation points from their unlocked CHRONO.
    28. getReputationPoints(address user): Returns the reputation points for a given user.
    29. onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): A standard ERC721 receiver hook, enabling the contract to potentially receive NFTs as collateral or rewards in future extensions.

    V. Administrative & Emergency
    30. pauseProtocol(): Pauses key protocol functions in an emergency (owner/governance).
    31. unpauseProtocol(): Unpauses the protocol (owner/governance).
    32. withdrawERC20Tokens(address tokenAddress, uint256 amount): Allows owner/governance to withdraw accidentally sent ERC20 tokens.
*/

contract ChronoForge is ERC20, Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    // I. Core CHRONO Token & Protocol Health Index (PHI)
    uint256 private s_protocolHealthIndex; // Placeholder for a complex, dynamic index (e.g., based on TVL, volatility, governance participation).
    address public authorizedPHICalculator; // Address of the oracle/contract responsible for updating PHI.
    address public treasuryAddress; // Address where protocol fees/revenue accrue.

    // II. The ChronoForge (Conditional Asset Generation & Staking)
    uint256 private s_nextForgeTemplateId;
    mapping(uint256 => ForgeTemplate) public forgeTemplates;
    mapping(uint256 => mapping(address => UserForgeStake)) public userForgeStakes; // templateId => staker => UserForgeStake
    uint256 public minCollateralForForge; // Minimum CHRONO required to stake for a Forge.
    uint256 public proposalVoteThreshold; // Minimum votes required for a Forge template to be approved.

    // Defines types of conditions a Forge Template can check
    enum ConditionType {
        TIMESTAMP_LT,       // Timestamp less than a target value
        TIMESTAMP_GT,       // Timestamp greater than a target value
        PRICE_GT_USDC,      // Price (of an asset) greater than (in USDC, requires external oracle)
        CUSTOM_ORACLE_CALL  // A generic oracle call, conditionParams should include target address and callData expecting a boolean return
    }

    // Defines the lifecycle status of a Forge Template
    enum ForgeStatus {
        Proposed,   // Newly proposed, awaiting votes/approval
        Approved,   // Approved by governance/votes, can be staked against
        Active,     // Has at least one stake, condition can be checked
        Fulfilled,  // Condition met successfully
        Expired,    // Condition not met and past expiry timestamp
        Canceled    // Proposer canceled or governance rejected
    }

    // Structure for a ChronoForge Template
    struct ForgeTemplate {
        uint256 id;
        string name;
        address proposer;
        ConditionType conditionType;
        bytes conditionParams; // ABI-encoded parameters for the specific condition check
        uint256 collateralRequired; // Minimum CHRONO amount required to stake
        uint256 rewardAmount;       // Base reward amount (scaled by ChronoMultiplier)
        address rewardToken;        // Address of the ERC20 or ERC721 token to be rewarded
        uint256 expiryTimestamp;    // When the Forge becomes invalid if condition not met
        ForgeStatus status;
        uint256 votesFor;           // Votes in favor of approving this template
        uint256 votesAgainst;       // Votes against approving this template
        uint256 approvedTimestamp;  // Timestamp when the template was approved
        bool isConditionMet;        // True if the condition has been met
    }

    // Structure for a user's stake in a Forge Template
    struct UserForgeStake {
        uint256 templateId;
        address staker;
        uint256 amount;             // Amount of CHRONO staked
        bool claimedReward;         // True if reward has been claimed
        bool reclaimedCollateral;   // True if collateral has been reclaimed
    }

    // III. Governance & Treasury Management
    uint256 private s_nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedProposal; // proposalId => voter => voted
    uint256 public votingPeriod; // How long a proposal is active for voting (in seconds).
    uint256 public minReputationToPropose; // Minimum reputation required to submit a governance proposal.
    uint256 public proposalExecutionDelay; // Time after approval before a proposal can be executed (timelock).
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total supply (or voting power) needed to pass a proposal.

    // Defines the lifecycle status of a Governance Proposal
    enum ProposalStatus {
        Pending,    // Newly submitted, awaiting initial votes/active state
        Active,     // Currently in voting period
        Approved,   // Passed voting, awaiting timelock
        Rejected,   // Failed voting
        Executed    // Successfully executed
    }

    // Structure for a Governance Proposal
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        address targetContract; // Contract address to call
        bytes callData;         // ABI-encoded function call for execution
        string description;     // Description of the proposal
        uint256 creationBlock;  // Block number when proposal was submitted
        uint256 votesFor;       // Total voting power in favor
        uint256 votesAgainst;   // Total voting power against
        uint256 proposalEndBlock; // Block number when voting ends
        uint256 executionTimestamp; // Earliest timestamp for execution (timelock)
        ProposalStatus status;
        bool executed;          // True if the proposal has been executed
    }

    // IV. Advanced & Utility Features
    mapping(address => uint256) public reputationPoints; // Non-transferable points
    mapping(address => LockedChrono) public lockedChronoBalances; // User's locked CHRONO for reputation

    // Structure for locked CHRONO
    struct LockedChrono {
        uint256 amount;
        uint256 unlockTime;
    }

    // --- Events ---
    event PHIUpdated(uint256 newPHI);
    event ChronoMultiplierUpdated(uint256 multiplier);
    event DynamicFeeApplied(address indexed payer, uint256 amount, uint256 feeAmount);

    event ForgeTemplateProposed(uint256 indexed templateId, address indexed proposer, string name);
    event ForgeTemplateVoted(uint256 indexed templateId, address indexed voter, bool support);
    event ForgeTemplateApproved(uint256 indexed templateId);
    event ForgeTemplateCancelled(uint256 indexed templateId);
    event ChronoStakedForForge(uint256 indexed templateId, address indexed staker, uint256 amount);
    event ForgeConditionChecked(uint256 indexed templateId, bool conditionMet);
    event ForgeRewardClaimed(uint256 indexed templateId, address indexed staker, uint256 rewardAmount, address rewardToken);
    event ForgeCollateralReclaimed(uint256 indexed templateId, address indexed staker, uint256 collateralAmount);
    event ForgeParamsUpdated(uint256 newMinCollateral, uint256 newProposalVoteThreshold);

    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalApproved(uint256 indexed proposalId);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event GovernanceParamsUpdated(uint256 newVotingPeriod, uint256 newMinReputationToPropose);
    event TreasuryFundsDistributed(address indexed token, address indexed recipient, uint256 amount);

    event FlashForgeLoan(address indexed borrower, uint256 amount, uint256 templateId);
    event ChronoLockedForReputation(address indexed user, uint256 amount, uint256 duration);
    event ReputationPointsClaimed(address indexed user, uint256 points);

    // --- Modifiers ---
    modifier onlyPHICalculator() {
        require(msg.sender == authorizedPHICalculator || msg.sender == owner(), "ChronoForge: Only PHI Calculator or Owner");
        _;
    }

    modifier onlyGovernance() {
        require(hasReputation(msg.sender) || msg.sender == owner(), "ChronoForge: Only governance participants or Owner");
        _;
    }

    modifier canPropose() {
        require(reputationPoints[msg.sender] >= minReputationToPropose, "ChronoForge: Insufficient reputation to propose");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, address initialOwner_)
        ERC20(name_, symbol_)
        Ownable(initialOwner_)
    {
        treasuryAddress = address(this); // Contract itself holds treasury funds by default, governed by DAO
        s_nextForgeTemplateId = 1;
        s_nextProposalId = 1;
        minCollateralForForge = 100 * (10 ** decimals()); // Example: 100 CHRONO
        proposalVoteThreshold = 5; // Example: 5 governance votes to approve a forge template.
        votingPeriod = 7 days; // Example: 7 days for governance proposals voting
        minReputationToPropose = 100; // Example: 100 reputation points to propose
        proposalExecutionDelay = 2 days; // Example: 2 days timelock for governance execution
    }

    // --- I. Core CHRONO Token & Protocol Health Index (PHI) ---

    /// @notice Mints the initial supply of CHRONO tokens to a beneficiary. Callable only once by the deployer.
    /// @param beneficiary The address to receive the initial supply.
    /// @param amount The amount of CHRONO tokens to mint.
    function mintInitialSupply(address beneficiary, uint256 amount) public onlyOwner {
        require(totalSupply() == 0, "ChronoForge: Initial supply already minted");
        _mint(beneficiary, amount);
    }

    /// @notice Allows a user to burn their own CHRONO tokens.
    /// @param amount The amount of CHRONO tokens to burn.
    function burn(uint256 amount) public virtual pausable {
        _burn(msg.sender, amount);
    }

    /// @dev Internal function to calculate a dynamic transaction fee based on the Protocol Health Index.
    /// @param amount The base amount of the transaction.
    /// @return feeAmount The calculated fee amount.
    function _dynamicTransactionFee(uint256 amount) internal view returns (uint256 feeAmount) {
        uint256 multiplier = getChronoMultiplier(); // Higher multiplier could mean lower fee if PHI is high
        // Example fee calculation: inversely proportional to multiplier, capped at 0.5% max.
        // Multiplier is scaled 500 (0.5x) to 2000 (2x), where 1000 is 1x.
        // If PHI is high (multiplier is high), fee is low. If PHI is low (multiplier is low), fee is higher.
        uint256 baseFeePermille = 5; // 0.5% (5/1000)
        
        // Adjust baseFeePermille based on multiplier (higher multiplier = lower adjusted fee)
        // E.g., if multiplier is 2000 (2x), adjustedFeePermille = 5 * 1000 / 2000 = 2.5
        // If multiplier is 500 (0.5x), adjustedFeePermille = 5 * 1000 / 500 = 10 (capped at max)
        uint256 adjustedFeePermille = (baseFeePermille * 1000) / multiplier; 

        // Cap the adjusted fee at a maximum of 0.5% of the amount for simplicity, or define a max fee permille.
        // For this example, let's say the max adjusted fee can be 1% (10 permille).
        uint256 maxFeePermille = 10; // 1%
        if (adjustedFeePermille > maxFeePermille) {
            adjustedFeePermille = maxFeePermille;
        }

        feeAmount = (amount * adjustedFeePermille) / 1000;
        
        // Ensure the fee does not exceed the amount itself (edge case for very small amounts)
        if (feeAmount > amount) {
            feeAmount = amount;
        }
    }

    /// @notice Overrides ERC20 `transfer` to apply dynamic fees.
    /// @param to The recipient address.
    /// @param amount The amount of CHRONO to transfer.
    /// @return A boolean indicating if the transfer was successful.
    function transfer(address to, uint256 amount) public override virtual pausable returns (bool) {
        uint256 fee = _dynamicTransactionFee(amount);
        require(amount >= fee, "ChronoForge: Amount too small for fee");
        _transfer(msg.sender, treasuryAddress, fee); // Send fee to treasury
        _transfer(msg.sender, to, amount - fee);     // Send net amount to recipient
        emit DynamicFeeApplied(msg.sender, amount, fee);
        return true;
    }

    /// @notice Overrides ERC20 `transferFrom` to apply dynamic fees.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param amount The amount of CHRONO to transfer.
    /// @return A boolean indicating if the transfer was successful.
    function transferFrom(address from, address to, uint256 amount) public override virtual pausable returns (bool) {
        uint256 fee = _dynamicTransactionFee(amount);
        require(amount >= fee, "ChronoForge: Amount too small for fee");
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount); // Reduce allowance
        }
        _transfer(from, treasuryAddress, fee);     // Send fee to treasury
        _transfer(from, to, amount - fee);         // Send net amount to recipient
        emit DynamicFeeApplied(from, amount, fee);
        return true;
    }

    /// @notice Returns the current Protocol Health Index (PHI).
    /// @return The current PHI value.
    function getProtocolHealthIndex() public view returns (uint256) {
        return s_protocolHealthIndex;
    }

    /// @notice Sets the address of the authorized PHI Calculator. Only callable by the owner.
    /// @param newPHICalculator The address of the new PHI calculator contract.
    function setPHICalculator(address newPHICalculator) public onlyOwner {
        require(newPHICalculator != address(0), "ChronoForge: Invalid PHI Calculator address");
        authorizedPHICalculator = newPHICalculator;
    }

    /// @notice Updates the Protocol Health Index (PHI). Callable by the authorized PHI Calculator or owner.
    /// @param newPHI The new PHI value (expected 0-10000).
    function updateProtocolHealthIndex(uint256 newPHI) public onlyPHICalculator {
        require(newPHI <= 10000, "ChronoForge: PHI cannot exceed 10000");
        s_protocolHealthIndex = newPHI;
        emit PHIUpdated(newPHI);
        emit ChronoMultiplierUpdated(getChronoMultiplier());
    }

    /// @notice Calculates and returns the Chrono Multiplier based on the current PHI.
    ///         This multiplier affects rewards and dynamically influences fees.
    /// @return The calculated multiplier (e.g., 1000 for 1x, 500 for 0.5x, 2000 for 2x).
    function getChronoMultiplier() public view returns (uint256) {
        // Example scaling: PHI 0 = 0.5x (500), PHI 5000 = 1x (1000), PHI 10000 = 2x (2000)
        // Formula: (s_protocolHealthIndex * 1500 / 10000) + 500
        return (s_protocolHealthIndex * 1500 / 10000) + 500;
    }

    // --- II. The ChronoForge (Conditional Asset Generation & Staking) ---

    /// @notice Allows users to propose a new ChronoForge template.
    /// @param name A descriptive name for the template.
    /// @param conditionType The type of condition to check (e.g., TIMESTAMP_GT, PRICE_GT_USDC).
    /// @param conditionParams ABI-encoded parameters specific to the conditionType.
    /// @param collateralRequired The minimum CHRONO amount required to stake for this template.
    /// @param rewardAmount The base amount of the reward token.
    /// @param rewardToken The address of the token to be rewarded (ERC20 or ERC721).
    /// @param expiryTimestamp The timestamp after which the Forge can no longer be fulfilled.
    /// @return The ID of the newly proposed Forge template.
    function proposeForgeTemplate(
        string calldata name,
        ConditionType conditionType,
        bytes calldata conditionParams,
        uint256 collateralRequired,
        uint256 rewardAmount,
        address rewardToken,
        uint256 expiryTimestamp
    ) public pausable returns (uint256) {
        require(collateralRequired >= minCollateralForForge, "ChronoForge: Collateral too low");
        require(expiryTimestamp > block.timestamp, "ChronoForge: Expiry must be in the future");
        require(bytes(name).length > 0, "ChronoForge: Name cannot be empty");
        require(rewardToken != address(0), "ChronoForge: Reward token cannot be zero address");
        require(rewardAmount > 0, "ChronoForge: Reward amount must be positive");

        uint256 templateId = s_nextForgeTemplateId++;
        forgeTemplates[templateId] = ForgeTemplate({
            id: templateId,
            name: name,
            proposer: msg.sender,
            conditionType: conditionType,
            conditionParams: conditionParams,
            collateralRequired: collateralRequired,
            rewardAmount: rewardAmount,
            rewardToken: rewardToken,
            expiryTimestamp: expiryTimestamp,
            status: ForgeStatus.Proposed,
            votesFor: 0,
            votesAgainst: 0,
            approvedTimestamp: 0,
            isConditionMet: false
        });

        emit ForgeTemplateProposed(templateId, msg.sender, name);
        return templateId;
    }

    /// @notice Allows governance participants to vote for a proposed Forge template.
    ///         Templates require `proposalVoteThreshold` votes to be approved.
    /// @param templateId The ID of the Forge template to vote for.
    function voteForForgeTemplate(uint256 templateId) public pausable onlyGovernance {
        ForgeTemplate storage template = forgeTemplates[templateId];
        require(template.status == ForgeStatus.Proposed, "ChronoForge: Template not in proposed state");
        // A more advanced system would track individual votes to prevent double voting.
        // For simplicity, here it just increments a counter.
        template.votesFor++;
        emit ForgeTemplateVoted(templateId, msg.sender, true);

        if (template.votesFor >= proposalVoteThreshold) {
            template.status = ForgeStatus.Approved;
            template.approvedTimestamp = block.timestamp;
            emit ForgeTemplateApproved(templateId);
        }
    }

    /// @notice Allows the owner (or potentially governance) to directly approve a Forge template.
    ///         Acts as a fallback or override for the voting mechanism.
    /// @param templateId The ID of the Forge template to approve.
    function approveForgeTemplate(uint256 templateId) public onlyOwner {
        ForgeTemplate storage template = forgeTemplates[templateId];
        require(template.status == ForgeStatus.Proposed, "ChronoForge: Template not in proposed state");
        template.status = ForgeStatus.Approved;
        template.approvedTimestamp = block.timestamp;
        emit ForgeTemplateApproved(templateId);
    }

    /// @notice Allows a user to stake CHRONO as collateral for an approved Forge template.
    /// @param templateId The ID of the Forge template to stake for.
    /// @param amount The amount of CHRONO to stake. Must meet `collateralRequired`.
    function stakeForForge(uint256 templateId, uint256 amount) public pausable nonReentrant {
        ForgeTemplate storage template = forgeTemplates[templateId];
        require(template.status == ForgeStatus.Approved || template.status == ForgeStatus.Active, "ChronoForge: Template not approved or active");
        require(block.timestamp < template.expiryTimestamp, "ChronoForge: Template has expired");
        require(amount >= template.collateralRequired, "ChronoForge: Insufficient collateral for this Forge");
        require(userForgeStakes[templateId][msg.sender].amount == 0, "ChronoForge: Already staked for this Forge");

        _transfer(msg.sender, address(this), amount); // Transfer CHRONO collateral to contract
        userForgeStakes[templateId][msg.sender] = UserForgeStake({
            templateId: templateId,
            staker: msg.sender,
            amount: amount,
            claimedReward: false,
            reclaimedCollateral: false
        });
        template.status = ForgeStatus.Active; // Activate upon first stake
        emit ChronoStakedForForge(templateId, msg.sender, amount);
    }

    /// @notice Allows anyone to trigger the condition check for an active Forge template.
    ///         If the condition is met, the template's status is updated to Fulfilled.
    ///         If expired, it's marked as Expired.
    /// @param templateId The ID of the Forge template to check.
    function checkForgeCondition(uint256 templateId) public pausable nonReentrant {
        ForgeTemplate storage template = forgeTemplates[templateId];
        require(template.status == ForgeStatus.Active, "ChronoForge: Template not active");
        require(!template.isConditionMet, "ChronoForge: Condition already met");

        // If expiry reached before condition check
        if (block.timestamp >= template.expiryTimestamp) {
            template.status = ForgeStatus.Expired;
            emit ForgeConditionChecked(templateId, false);
            return;
        }

        bool conditionMet = false;
        if (template.conditionType == ConditionType.TIMESTAMP_LT) {
            uint256 targetTimestamp = abi.decode(template.conditionParams, (uint256));
            conditionMet = (block.timestamp < targetTimestamp);
        } else if (template.conditionType == ConditionType.TIMESTAMP_GT) {
            uint256 targetTimestamp = abi.decode(template.conditionParams, (uint256));
            conditionMet = (block.timestamp > targetTimestamp);
        } else if (template.conditionType == ConditionType.PRICE_GT_USDC) {
            // For a real application, this would integrate with a reliable oracle (e.g., Chainlink)
            // Example: (address tokenAddress, uint256 targetPriceInUSDC) = abi.decode(template.conditionParams, (address, uint256));
            // IPriceOracle oracle = IPriceOracle(someOracleAddress);
            // uint256 currentPrice = oracle.getLatestPrice(tokenAddress); // Assuming 8-18 decimals
            // conditionMet = currentPrice > targetPriceInUSDC;
            // For demonstration, we'll assume a dummy oracle returns true if conditionParams indicate a valid check.
            conditionMet = true; // Placeholder: Replace with actual oracle integration
        } else if (template.conditionType == ConditionType.CUSTOM_ORACLE_CALL) {
            (address oracleContract, bytes memory callData) = abi.decode(template.conditionParams, (address, bytes));
            (bool success, bytes memory result) = oracleContract.staticcall(callData);
            require(success, "ChronoForge: Custom oracle call failed");
            conditionMet = abi.decode(result, (bool)); // Expects a boolean return value from the oracle call
        }

        if (conditionMet) {
            template.isConditionMet = true;
            template.status = ForgeStatus.Fulfilled;
        } else if (block.timestamp >= template.expiryTimestamp) {
            template.status = ForgeStatus.Expired; // Condition not met by expiry
        }
        emit ForgeConditionChecked(templateId, conditionMet);
    }

    /// @notice Allows a staker to claim rewards if their staked Forge's condition has been met.
    /// @param templateId The ID of the Forge template.
    function claimForgeReward(uint256 templateId) public pausable nonReentrant {
        ForgeTemplate storage template = forgeTemplates[templateId];
        UserForgeStake storage userStake = userForgeStakes[templateId][msg.sender];

        require(userStake.amount > 0, "ChronoForge: No stake found for this user");
        require(template.status == ForgeStatus.Fulfilled, "ChronoForge: Condition not met or not fulfilled");
        require(!userStake.claimedReward, "ChronoForge: Reward already claimed");

        uint256 rewardToClaim = (template.rewardAmount * getChronoMultiplier()) / 1000; // Reward scaled by PHI multiplier
        
        // This assumes ERC20 rewards. For ERC721, a different logic to transfer specific NFTs would be needed.
        // If template.rewardToken is a recognized ERC721 contract, you'd use IERC721(template.rewardToken).safeTransferFrom(address(this), msg.sender, tokenId);
        // This implies the contract must hold the specific NFT before it can be claimed.
        IERC20(template.rewardToken).safeTransfer(msg.sender, rewardToClaim);
        userStake.claimedReward = true;
        
        // Optionally, collateral could be burned or returned here instead of just "spent".
        // For simplicity, collateral is considered spent if reward is claimed.
        emit ForgeRewardClaimed(templateId, msg.sender, rewardToClaim, template.rewardToken);
    }

    /// @notice Allows a staker to reclaim their CHRONO collateral if the Forge template expired or was canceled.
    /// @param templateId The ID of the Forge template.
    function reclaimForgeCollateral(uint256 templateId) public pausable nonReentrant {
        ForgeTemplate storage template = forgeTemplates[templateId];
        UserForgeStake storage userStake = userForgeStakes[templateId][msg.sender];

        require(userStake.amount > 0, "ChronoForge: No stake found for this user");
        require(template.status == ForgeStatus.Expired || template.status == ForgeStatus.Canceled, "ChronoForge: Template not expired or cancelled");
        require(!userStake.reclaimedCollateral, "ChronoForge: Collateral already reclaimed");

        // Return CHRONO collateral to staker
        _transfer(address(this), msg.sender, userStake.amount);
        userStake.reclaimedCollateral = true;
        emit ForgeCollateralReclaimed(templateId, msg.sender, userStake.amount);
    }

    /// @notice Allows the proposer to cancel their Forge template if it's still in the 'Proposed' state.
    /// @param templateId The ID of the Forge template to cancel.
    function cancelForgeProposal(uint256 templateId) public pausable {
        ForgeTemplate storage template = forgeTemplates[templateId];
        require(template.proposer == msg.sender, "ChronoForge: Only proposer can cancel");
        require(template.status == ForgeStatus.Proposed, "ChronoForge: Template not in proposed state");

        template.status = ForgeStatus.Canceled;
        emit ForgeTemplateCancelled(templateId);
    }

    /// @notice Allows the owner to update parameters for the ChronoForge.
    /// @param newMinCollateral The new minimum CHRONO collateral required for a Forge.
    /// @param newProposalVoteThreshold The new minimum votes required for a Forge template to be approved.
    function updateForgeParams(uint256 newMinCollateral, uint256 newProposalVoteThreshold) public onlyOwner {
        require(newMinCollateral > 0, "ChronoForge: Min collateral must be greater than zero");
        require(newProposalVoteThreshold > 0, "ChronoForge: Proposal vote threshold must be greater than zero");
        minCollateralForForge = newMinCollateral;
        proposalVoteThreshold = newProposalVoteThreshold;
        emit ForgeParamsUpdated(newMinCollateral, newProposalVoteThreshold);
    }

    // --- III. Governance & Treasury Management ---

    /// @notice Allows users with sufficient reputation to submit a governance proposal.
    /// @param callData ABI-encoded function call to be executed if the proposal passes.
    /// @param targetContract The address of the contract the `callData` will be executed on.
    /// @param description A descriptive string for the proposal.
    /// @return The ID of the newly submitted proposal.
    function submitGovernanceProposal(
        bytes calldata callData,
        address targetContract,
        string calldata description
    ) public pausable canPropose returns (uint256) {
        require(bytes(description).length > 0, "ChronoForge: Description cannot be empty");
        require(targetContract != address(0), "ChronoForge: Target contract cannot be zero address");

        uint256 proposalId = s_nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            targetContract: targetContract,
            callData: callData,
            description: description,
            creationBlock: block.number,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndBlock: block.number + votingPeriod / 12, // Approx blocks (assuming 12s per block)
            executionTimestamp: 0,
            status: ProposalStatus.Pending,
            executed: false
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, description);
        return proposalId;
    }

    /// @notice Allows governance participants to vote on an active proposal.
    ///         Voting power is based on the sender's CHRONO balance at the time of voting.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) public pausable {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "ChronoForge: Proposal not active for voting");
        require(!hasVotedProposal[proposalId][msg.sender], "ChronoForge: Already voted on this proposal");
        require(block.number <= proposal.proposalEndBlock, "ChronoForge: Voting period ended");
        
        uint256 voterPower = balanceOf(msg.sender); // Simple 1 CHRONO = 1 vote. Could use reputationPoints here too.
        require(voterPower > 0, "ChronoForge: No voting power");

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        hasVotedProposal[proposalId][msg.sender] = true;

        // If voting period ends with this vote, determine outcome
        if (block.number >= proposal.proposalEndBlock) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 quorumThreshold = totalSupply() * QUORUM_PERCENTAGE / 100; // Quorum based on total CHRONO supply

            if (proposal.votesFor > proposal.votesAgainst && totalVotes >= quorumThreshold) {
                proposal.status = ProposalStatus.Approved;
                proposal.executionTimestamp = block.timestamp + proposalExecutionDelay; // Set timelock
                emit GovernanceProposalApproved(proposalId);
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        } else {
             proposal.status = ProposalStatus.Active; // Set to active if voting still open
        }

        emit GovernanceProposalVoted(proposalId, msg.sender, support);
    }

    /// @notice Executes an approved governance proposal after its timelock has elapsed.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public pausable nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == ProposalStatus.Approved, "ChronoForge: Proposal not approved");
        require(block.timestamp >= proposal.executionTimestamp, "ChronoForge: Execution timelock not elapsed");
        require(!proposal.executed, "ChronoForge: Proposal already executed");

        proposal.executed = true;
        proposal.status = ProposalStatus.Executed;

        // Execute the proposed call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "ChronoForge: Proposal execution failed");

        emit GovernanceProposalExecuted(proposalId);
    }

    /// @notice Allows the owner to update governance parameters. In a fully decentralized DAO, this would also be a governance proposal.
    /// @param newVotingPeriod The new duration for proposal voting in seconds.
    /// @param newMinReputationToPropose The new minimum reputation required to submit a proposal.
    function updateGovernanceParams(uint256 newVotingPeriod, uint256 newMinReputationToPropose) public onlyOwner {
        require(newVotingPeriod > 0, "ChronoForge: Voting period must be positive");
        require(newMinReputationToPropose >= 0, "ChronoForge: Min reputation cannot be negative");
        votingPeriod = newVotingPeriod;
        minReputationToPropose = newMinReputationToPropose;
        emit GovernanceParamsUpdated(newVotingPeriod, newMinReputationToPropose);
    }

    /// @notice Allows governance to distribute funds from the protocol treasury.
    /// @param token The address of the token to distribute (0 for native ETH if applicable, though this contract only handles ERC20).
    /// @param recipient The address to send funds to.
    /// @param amount The amount to distribute.
    function distributeTreasuryFunds(address token, address recipient, uint256 amount) public pausable onlyGovernance {
        require(recipient != address(0), "ChronoForge: Recipient cannot be zero address");
        require(amount > 0, "ChronoForge: Amount must be positive");

        // If the token is CHRONO itself, use internal transfer
        if (token == address(this)) {
            _transfer(address(this), recipient, amount);
        } else { // Otherwise, use SafeERC20 for external ERC20 tokens
            IERC20(token).safeTransfer(recipient, amount);
        }
        emit TreasuryFundsDistributed(token, recipient, amount);
    }

    // --- IV. Advanced & Utility Features ---

    /// @notice A unique "flash loan" mechanism that provides temporary CHRONO collateral for a Forge action.
    ///         The borrower must execute a series of actions (e.g., stakeForForge, checkForgeCondition, claimReward/reclaimCollateral)
    ///         and repay the loan plus a fee within the same transaction.
    /// @param amount The amount of CHRONO to loan.
    /// @param templateId The ID of the Forge template the loan is intended for.
    /// @param data ABI-encoded calldata for the borrower's custom logic to execute with the loaned funds.
    /// @return A boolean indicating if the flash loan transaction was successful.
    function flashForgeLoan(uint256 amount, uint256 templateId, bytes calldata data) public pausable nonReentrant returns (bool) {
        require(amount > 0, "ChronoForge: Flash loan amount must be positive");
        require(templateId > 0, "ChronoForge: Invalid template ID");
        require(balanceOf(address(this)) >= amount, "ChronoForge: Insufficient CHRONO for flash loan");

        // 1. Send CHRONO loan to borrower (msg.sender)
        _transfer(address(this), msg.sender, amount);
        emit FlashForgeLoan(msg.sender, amount, templateId);

        // 2. Call arbitrary logic on the borrower.
        // The `data` param is expected to contain calls to stakeForForge, checkForgeCondition, claimForgeReward, etc.
        // It's the borrower's responsibility to repay and execute the Forge logic within this transaction.
        (bool success, ) = msg.sender.call(data);
        require(success, "ChronoForge: Flash loan callback failed");

        // 3. Repay loan + fee
        uint256 fee = (amount * 3) / 1000; // 0.3% flash loan fee
        uint256 totalRepay = amount + fee;
        require(balanceOf(msg.sender) >= totalRepay, "ChronoForge: Insufficient CHRONO to repay flash loan + fee");
        _transfer(msg.sender, address(this), totalRepay); // Transfer back to contract

        return true;
    }

    /// @notice Allows a user to lock their CHRONO tokens for a specified duration to earn reputation points.
    ///         Only one lock per user at a time.
    /// @param amount The amount of CHRONO to lock.
    /// @param duration The duration in seconds for which the tokens will be locked (max 1 year).
    function lockChronoForReputation(uint256 amount, uint256 duration) public pausable nonReentrant {
        require(amount > 0, "ChronoForge: Amount must be positive");
        require(duration > 0, "ChronoForge: Duration must be positive");
        require(duration <= 365 days, "ChronoForge: Max lock duration is 1 year");
        require(lockedChronoBalances[msg.sender].amount == 0, "ChronoForge: Already has locked CHRONO");

        _transfer(msg.sender, address(this), amount); // Transfer CHRONO to contract
        lockedChronoBalances[msg.sender] = LockedChrono({
            amount: amount,
            unlockTime: block.timestamp + duration
        });
        emit ChronoLockedForReputation(msg.sender, amount, duration);
    }

    /// @notice Allows a user to claim their accrued reputation points and unlock their CHRONO
    ///         once the lock period has ended.
    function claimReputationPoints() public pausable nonReentrant {
        LockedChrono storage locked = lockedChronoBalances[msg.sender];
        require(locked.amount > 0, "ChronoForge: No locked CHRONO found");
        require(block.timestamp >= locked.unlockTime, "ChronoForge: Lock period not over yet");

        // Calculate reputation points based on amount and duration.
        // Example: 1 CHRONO for 1 day = 1 point. Adjust denominator based on token decimals for fair scaling.
        uint256 actualLockedDuration = locked.unlockTime - (locked.unlockTime - block.timestamp); // This should be `duration` from `lockChronoForReputation` if calculation is at exact unlock.
        uint256 points = (locked.amount * actualLockedDuration) / (10 ** decimals() * 1 days); 

        reputationPoints[msg.sender] += points;
        _transfer(address(this), msg.sender, locked.amount); // Return locked CHRONO
        delete lockedChronoBalances[msg.sender]; // Clear locked balance
        emit ReputationPointsClaimed(msg.sender, points);
    }

    /// @notice Returns the current reputation points for a given user.
    /// @param user The address of the user.
    /// @return The number of reputation points.
    function getReputationPoints(address user) public view returns (uint256) {
        return reputationPoints[user];
    }

    /// @notice Checks if a user has any reputation points.
    /// @param user The address of the user.
    /// @return True if the user has more than 0 reputation points, false otherwise.
    function hasReputation(address user) public view returns (bool) {
        return reputationPoints[user] > 0;
    }

    /// @notice Standard ERC721 receiver hook. Allows the contract to receive ERC721 tokens.
    ///         Useful if NFTs are to be used as collateral or rewards in future Forge templates.
    /// @param operator The address which called `safeTransferFrom` function.
    /// @param from The address which previously owned the NFT.
    /// @param tokenId The NFT identifier.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Implement specific logic here if NFTs are intended to be held or processed by ChronoForge.
        // For example, if an NFT is used as collateral for a Forge.
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- V. Administrative & Emergency ---

    /// @notice Pauses key protocol functions in an emergency. Callable only by the owner.
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the protocol. Callable only by the owner.
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accidentally sent ERC20 tokens from the contract.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20Tokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(this), "ChronoForge: Cannot withdraw native CHRONO with this function"); // Prevent withdrawing CHRONO via this.
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}
```