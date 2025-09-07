Here's a smart contract written in Solidity, incorporating advanced, creative, and trendy concepts like AI oracle integration (simulated), a dynamic reputation system with decay, commit-reveal governance, and adaptive protocol parameters. It aims to be distinct from common open-source projects by combining these features into a cohesive, evolving protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable as a placeholder for a more complex DAO governance
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is generally not needed for Solidity 0.8+ but included for illustrative purposes for potential future use or complex calculations.

// Custom errors for better error handling and gas efficiency
error Unauthorized();
error InsufficientFunds();
error InvalidAmount();
error NotYetActive();
error AlreadyActive();
error NotEnoughReputation(address user, uint256 currentReputation, uint256 requiredReputation);
error ProposalNotFound();
error VotingPeriodNotOpen();
error RevealPeriodNotOpen();
error VotingPeriodExpired();
error ProposalNotExecutable();
error DuplicateVote();
error InvalidProposalState();
error InvalidProof(); // For commit-reveal verification
error AlreadyVoted();
error CannotVoteOnOwnProposal();
error InvalidParameterName();
error InvalidURI();
error CannotTransferZERO();

/**
 * @title NexusForgeProtocol
 * @dev An advanced, adaptive, and reputation-driven decentralized protocol for value generation.
 *      It integrates AI oracle sentiment, dynamic fee/reward structures, a decaying reputation system,
 *      and a commit-reveal governance model to create a resilient and community-owned ecosystem.
 *
 * @outline
 * 1. Core Infrastructure & Initialization
 *    - Constructor: Deploys the contract, initializes ERC20 `NEXF` token, sets the initial owner.
 *    - Initialize Protocol: Sets foundational protocol parameters post-deployment and unpauses.
 *    - Ownership/Role Management: Functions to transfer ownership to a DAO or update oracle/keeper roles.
 *
 * 2. Token & Vault Operations
 *    - Stake: Allows users to deposit collateral (ETH) into the vault and receive internal shares. Awards reputation.
 *    - Unstake: Allows users to withdraw their collateral by burning their shares. Penalizes reputation.
 *    - Claim Rewards: Distributes accumulated protocol rewards to stakers based on shares and reputation multipliers.
 *    - Get Current Share Price: Calculates the current value of one vault share.
 *    - Get Vault Balance: Retrieves the total collateral held by the protocol vault.
 *
 * 3. Reputation System
 *    - Earn Reputation: Awards reputation points for positive contributions (e.g., staking, governance participation).
 *    - Lose Reputation: Reduces reputation points for negative actions or inactivity (internal calls).
 *    - Get Reputation Score: Retrieves a user's current reputation points, applying decay for view functions.
 *    - Decay Reputation: Periodically reduces reputation scores for active users to encourage engagement (callable by keeper).
 *    - Get Reputation Multiplier: Returns a reward multiplier based on a user's reputation score.
 *
 * 4. AI Oracle & Adaptive Parameters
 *    - Update AI Sentiment Score: An oracle-callable function to update the global AI-driven market sentiment.
 *    - Get AI Sentiment Score: Retrieves the current AI sentiment score, influencing protocol dynamics.
 *    - Get Dynamic Fee Rate: Calculates transaction fees based on AI sentiment and protocol health.
 *    - Get Dynamic Reward Rate: Determines the reward distribution rate based on AI sentiment and other factors.
 *
 * 5. Governance & DAO (Commit-Reveal Model)
 *    - Get Voting Power: Combines NEXF token balance and reputation for total voting power.
 *    - Propose Parameter Change: Initiates a proposal to modify core protocol parameters.
 *    - Propose Catalyst Grant: Initiates a proposal to fund external projects or internal initiatives.
 *    - Delegate Vote: Allows users to delegate their voting power to another address (liquid democracy).
 *    - Undelegate Vote: Revokes delegated voting power.
 *    - Commit Vote: Allows users to commit a hashed vote (YES/NO/ABSTAIN) for a proposal during the commitment phase.
 *    - Reveal Vote: Allows users to reveal their committed vote during the reveal phase, verifying against the commitment.
 *    - Execute Proposal: Executes the actions defined in a successfully passed governance proposal.
 *    - Get Proposal State: Returns the current lifecycle state of a proposal.
 *
 * 6. Catalyst Grants
 *    - Submit Catalyst Application: Records a URI pointing to an off-chain application for a grant (used by proposeCatalystGrant).
 *    - Fund Catalyst Grant: Transfers approved funds to a grant recipient (triggered by executeProposal).
 *
 * 7. Admin & Emergency (DAO-Controlled)
 *    - Pause Protocol: Halts critical functions in emergencies (DAO-approved).
 *    - Unpause Protocol: Resumes protocol operations (DAO-approved).
 *    - Emergency Withdraw Funds: Allows DAO to withdraw funds in extreme situations (ERC20 or ETH).
 *
 * @function_summary
 * - `constructor(address _initialOwner, string memory _tokenName, string memory _tokenSymbol)`: Deploys the contract, initializes ERC20 `NEXF` token (governance token), sets the initial owner, and mints initial supply to the owner. Starts paused.
 * - `initializeProtocol(uint256 _minStakeAmount, uint256 _initialReputationReward, uint256 _maxReputationScore, uint256 _reputationDecayRateBps, uint256 _minGovernanceReputation, uint256 _proposalThreshold, uint256 _votingPeriodBlocks, uint256 _revealPeriodBlocks)`: Sets foundational protocol parameters post-deployment and unpauses the protocol. Can only be called once by the owner.
 * - `transferOwnershipToDAO(address newOwner)`: Allows the current owner to transfer ownership to a DAO multisig or governance contract.
 * - `setAIOracleAddress(address _newOracleAddress)`: Allows the owner to change the AI Oracle address.
 * - `setKeeperAddress(address _newKeeperAddress)`: Allows the owner to change the Keeper address (for reputation decay).
 * - `stake()`: Users deposit ETH into the vault. They receive internal "shares" and earn an initial reputation reward. Reverts if `msg.value` is less than `minStakeAmount`.
 * - `unstake(uint256 _shares)`: Users withdraw ETH by burning their shares. A portion of their reputation (e.g., 10%) is lost to discourage short-term actions.
 * - `claimRewards()`: Placeholder for claiming accumulated rewards based on user's shares and reputation. In a real system, this would interact with yield-generating strategies.
 * - `getCurrentSharePrice() internal view returns (uint256)`: Calculates the current value of one internal vault share in Wei, considering the total ETH in the vault and total shares.
 * - `getVaultBalance() public view returns (uint256)`: Returns the total ETH held by the protocol vault.
 * - `_earnReputation(address _user, uint256 _amount)`: Internal function to award reputation points to `_user`. Applies decay before adding.
 * - `_loseReputation(address _user, uint256 _amount)`: Internal function to reduce reputation points for `_user`. Applies decay before subtracting.
 * - `getReputationScore(address _user) public view returns (uint256)`: Retrieves an address's reputation score. Automatically applies simulated decay for accurate current score in view functions.
 * - `_applyReputationDecay(address _user) internal`: Helper function to apply the reputation decay logic for a specific user.
 * - `decayReputation()`: Callable by the designated `keeperAddress` to trigger reputation decay, typically used by an off-chain bot for multiple users.
 * - `getReputationMultiplier(address _user) public view returns (uint256)`: Calculates a reward multiplier based on a user's reputation score (e.g., higher reputation means higher rewards).
 * - `updateAI_SentimentScore(int256 _newScore)`: Callable only by `aiOracleAddress` to update the global AI sentiment score (range -100 to 100), which influences dynamic fees and rewards.
 * - `getAI_SentimentScore() public view returns (int256)`: Returns the current AI sentiment score.
 * - `getDynamicFeeRate() public view returns (uint256)`: Calculates the dynamic transaction fee rate (in basis points) based on the current AI sentiment. Positive sentiment may lower fees, negative may increase them.
 * - `getDynamicRewardRate() public view returns (uint256)`: Calculates the dynamic reward distribution rate (in basis points) based on the current AI sentiment. Positive sentiment may increase rewards, negative may decrease them.
 * - `getVotingPower(address _user) public view returns (uint256)`: Returns the total voting power of a user, aggregating their `NEXF` token balance and a weighted portion of their reputation score. Accounts for delegation.
 * - `proposeParameterChange(string memory _description, string memory _paramName, uint256 _newValue)`: Allows users with sufficient `minGovernanceReputation` and `proposalThreshold` to propose changes to specified protocol parameters.
 * - `proposeCatalystGrant(string memory _description, address _recipient, uint256 _amount, string memory _applicationURI)`: Allows eligible users to propose a grant of ETH from the vault to a specific recipient, linking to an off-chain application.
 * - `delegateVote(address _delegatee)`: Allows a user to delegate their voting power to another address, enabling liquid democracy.
 * - `undelegateVote()`: Clears any existing vote delegation for the calling user.
 * - `commitVote(uint256 _proposalId, bytes32 _voteHash)`: During the commit phase, users submit a hash of their vote (support/no-support + nonce). Awards a small reputation for participation.
 * - `revealVote(uint256 _proposalId, bool _support, bytes32 _nonce)`: During the reveal phase, users reveal their actual vote and nonce. The contract verifies this against the previously committed hash and applies the vote.
 * - `_finalizeProposalState(uint256 _proposalId) internal`: Internal helper to transition a proposal's state from ActiveReveal to Succeeded or Defeated based on vote counts and thresholds.
 * - `executeProposal(uint256 _proposalId)`: Executable by `owner` (to be DAO) if a proposal has successfully passed its voting and reveal periods. It applies the parameter change or funds the grant.
 * - `getProposalState(uint256 _proposalId) public view returns (ProposalState)`: Returns the current state of a proposal, dynamically updating based on block number if voting/reveal periods have passed.
 * - `submitCatalystApplication(string memory _applicationURI)`: A general function to record a URI for a catalyst application. The `proposeCatalystGrant` function directly uses the URI.
 * - `_fundCatalystGrant(uint256 _proposalId) internal`: Internal function to transfer ETH for an approved catalyst grant. Called by `executeProposal`.
 * - `pauseProtocol()`: Pauses core functions of the protocol, preventing state-changing operations. Only callable by the `owner`.
 * - `unpauseProtocol()`: Unpauses the protocol, allowing operations to resume. Only callable by the `owner`.
 * - `emergencyWithdrawFunds(address _token, address _recipient, uint256 _amount)`: Allows the `owner` (under DAO control in a real system) to withdraw ETH or any ERC20 token in extreme, paused scenarios.
 * - `receive() external payable`: Allows the contract to receive plain ETH, which contributes to the vault's balance.
 */
contract NexusForgeProtocol is Context, ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables & Constants ---

    // Protocol Parameters (Managed by Governance)
    uint256 public minStakeAmount;             // Minimum ETH amount to stake (in Wei)
    uint256 public initialReputationReward;    // Reputation awarded for initial stake/positive actions
    uint256 public maxReputationScore;         // Cap for a user's reputation score
    uint256 public reputationDecayRateBps;     // Basis points (e.g., 100 = 1%) for reputation decay per decay period
    uint256 public minGovernanceReputation;    // Minimum reputation required to create/vote on proposals
    uint256 public proposalThreshold;          // Minimum NEXF tokens required to create a proposal
    uint256 public votingPeriodBlocks;         // Duration of commit phase in blocks
    uint256 public revealPeriodBlocks;         // Duration of reveal phase in blocks

    // AI Oracle Related
    int256 public aiSentimentScore;    // Global AI sentiment score (-100 to 100, e.g., from a Chainlink AI oracle)
    address public aiOracleAddress;    // Address of the trusted AI oracle that updates `aiSentimentScore`

    // Financials
    uint256 public totalVaultShares;           // Total shares issued for staked ETH
    mapping(address => uint256) public userVaultShares; // User's shares in the vault
    mapping(address => uint256) public userPendingRewards; // Rewards accumulated per user (placeholder for yield)

    // Reputation System
    mapping(address => uint256) public reputationScores;           // Current reputation score of a user
    mapping(address => uint256) public lastReputationUpdateBlock; // Block number of the last reputation update/decay for a user

    // Governance System
    enum ProposalState { Pending, ActiveCommit, ActiveReveal, Succeeded, Defeated, Executed, Canceled }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 creationBlock;
        uint256 votingStartBlock;  // Block when commit phase begins
        uint256 votingEndBlock;    // Block when commit phase ends
        uint256 revealEndBlock;    // Block when reveal phase ends
        ProposalState state;
        uint256 yesVotes;
        uint256 noVotes;
        // uint256 abstainVotes; // For simplicity, we'll exclude abstain for now
        uint256 proposalThresholdAtCreation; // Snapshot of threshold at proposal creation
        address delegatee; // Target address for Catalyst grants
        uint256 amount;    // Amount for Catalyst grants
        string paramName;  // Name of the parameter to change
        uint256 newValue;  // New value for the parameter
        string applicationURI; // URI for off-chain Catalyst grant application details
        bool executed;
        mapping(address => bytes32) commitHashes; // user => keccak256(support, nonce)
        mapping(address => bool) hasRevealed;    // user => whether they have revealed their vote
    }

    uint256 public nextProposalId; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Mapping of proposal ID to Proposal struct
    mapping(uint256 => mapping(address => bool)) public hasCommitted; // proposalId => user => committed?

    // Delegated voting for liquid democracy
    mapping(address => address) public delegates; // user => delegatee (address to whom user delegates voting power)

    // Keeper role for off-chain bots to perform maintenance (e.g., reputation decay)
    address public keeperAddress;

    // --- Events ---
    event ProtocolInitialized(address indexed initializer);
    event Staked(address indexed user, uint256 amount, uint256 shares);
    event Unstaked(address indexed user, uint256 amount, uint256 shares);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationEarned(address indexed user, uint256 amount, uint256 newScore);
    event ReputationLost(address indexed user, uint256 amount, uint256 newScore);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event AISentimentUpdated(int256 oldScore, int256 newScore);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCommitted(uint256 indexed proposalId, address indexed voter, bytes32 voteHash);
    event VoteRevealed(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(string indexed paramName, uint256 oldValue, uint256 newValue);
    event CatalystApplicationSubmitted(uint256 indexed proposalId, address indexed applicant, string applicationURI);
    event CatalystGrantFunded(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event DelegateChanged(address indexed delegator, address indexed oldDelegatee, address indexed newDelegatee);

    // --- Constructor ---
    /**
     * @dev Deploys the contract, initializes the ERC20 NEXF governance token, and sets the initial owner.
     *      The protocol starts in a paused state, awaiting initialization.
     * @param _initialOwner The address that will initially own the contract and receive initial NEXF tokens.
     * @param _tokenName The name of the NEXF token (e.g., "NexusForge Token").
     * @param _tokenSymbol The symbol of the NEXF token (e.g., "NEXF").
     */
    constructor(
        address _initialOwner,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) Ownable(_initialOwner) {
        // Mint initial supply of NEXF to the deployer. In a full DAO, this would be to a treasury.
        _mint(_initialOwner, 100_000_000 * 10**decimals()); // 100 Million NEXF tokens
        aiOracleAddress = _initialOwner; // Set initial oracle to owner, to be changed by DAO later
        keeperAddress = _initialOwner;   // Set initial keeper to owner, to be changed by DAO later
        _pause(); // Start paused, requires initialization to unpause
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        if (_msgSender() != aiOracleAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyKeeper() {
        if (_msgSender() != keeperAddress) {
            revert Unauthorized();
        }
        _;
    }

    // --- 1. Core Infrastructure & Initialization ---

    /**
     * @dev Initializes core protocol parameters. Can only be called once by the owner while paused.
     *      Unpauses the protocol after successful initialization.
     * @param _minStakeAmount Minimum ETH required for staking in Wei.
     * @param _initialReputationReward Reputation points awarded for initial stake.
     * @param _maxReputationScore Maximum reputation points a user can accumulate.
     * @param _reputationDecayRateBps Basis points (e.g., 100 = 1%) for reputation decay per decay period.
     * @param _minGovernanceReputation Minimum reputation required to participate in governance.
     * @param _proposalThreshold Minimum NEXF tokens required to create a proposal.
     * @param _votingPeriodBlocks Number of blocks for the voting (commit) phase.
     * @param _revealPeriodBlocks Number of blocks for the reveal phase.
     */
    function initializeProtocol(
        uint256 _minStakeAmount,
        uint256 _initialReputationReward,
        uint256 _maxReputationScore,
        uint256 _reputationDecayRateBps,
        uint256 _minGovernanceReputation,
        uint256 _proposalThreshold,
        uint256 _votingPeriodBlocks,
        uint256 _revealPeriodBlocks
    ) public onlyOwner {
        if (!paused()) revert AlreadyActive(); // Can only initialize when paused
        if (_minStakeAmount == 0 || _initialReputationReward == 0 || _maxReputationScore == 0 || _votingPeriodBlocks == 0 || _revealPeriodBlocks == 0) {
            revert InvalidAmount();
        }
        
        minStakeAmount = _minStakeAmount;
        initialReputationReward = _initialReputationReward;
        maxReputationScore = _maxReputationScore;
        reputationDecayRateBps = _reputationDecayRateBps;
        minGovernanceReputation = _minGovernanceReputation;
        proposalThreshold = _proposalThreshold;
        votingPeriodBlocks = _votingPeriodBlocks;
        revealPeriodBlocks = _revealPeriodBlocks;

        // Set initial dynamic rates (can be changed by oracle later)
        aiSentimentScore = 50; // Neutral-positive initial sentiment (0 to 100 scale)
        
        _unpause(); // Unpause the protocol after successful initialization
        emit ProtocolInitialized(_msgSender());
    }

    /**
     * @dev Allows the owner to transfer ownership to a DAO multisig or governance contract.
     *      This is a critical step for decentralization.
     * @param newOwner The address of the new owner (e.g., a DAO contract).
     */
    function transferOwnershipToDAO(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     * @dev Allows the current owner to change the AI Oracle address.
     *      In a full DAO, this would be a governance proposal.
     * @param _newOracleAddress The address of the new AI oracle.
     */
    function setAIOracleAddress(address _newOracleAddress) public onlyOwner {
        aiOracleAddress = _newOracleAddress;
    }

    /**
     * @dev Allows the current owner to change the Keeper address.
     *      In a full DAO, this would be a governance proposal.
     * @param _newKeeperAddress The address of the new Keeper.
     */
    function setKeeperAddress(address _newKeeperAddress) public onlyOwner {
        keeperAddress = _newKeeperAddress;
    }


    // --- 2. Token & Vault Operations ---

    /**
     * @dev Allows users to stake ETH into the protocol vault.
     *      They receive internal shares proportional to the ETH deposited, representing their stake.
     *      Awards reputation points for active participation.
     */
    function stake() public payable whenNotPaused {
        if (msg.value < minStakeAmount) {
            revert InvalidAmount();
        }

        uint256 currentShares = totalVaultShares;
        // Exclude current msg.value from balance when calculating share price to avoid re-entry issues
        uint256 currentVaultBalance = address(this).balance.sub(msg.value); 

        uint256 sharesToMint;
        if (currentShares == 0 || currentVaultBalance == 0) {
            // First stake or vault is empty, 1 ETH = 1 share (arbitrary ratio, simplified)
            sharesToMint = msg.value;
        } else {
            // Calculate shares based on current share price
            sharesToMint = msg.value.mul(currentShares).div(currentVaultBalance);
        }
        if (sharesToMint == 0) revert CannotTransferZERO(); // Should not happen with minStakeAmount > 0

        totalVaultShares = totalVaultShares.add(sharesToMint);
        userVaultShares[_msgSender()] = userVaultShares[_msgSender()].add(sharesToMint);
        
        _earnReputation(_msgSender(), initialReputationReward); // Award reputation for staking
        lastReputationUpdateBlock[_msgSender()] = block.number; // Update last activity for decay

        emit Staked(_msgSender(), msg.value, sharesToMint);
    }

    /**
     * @dev Allows users to unstake their ETH by burning shares.
     *      Reduces reputation points as a penalty for early withdrawal or to encourage long-term commitment.
     * @param _shares The amount of shares to burn.
     */
    function unstake(uint256 _shares) public whenNotPaused {
        if (_shares == 0) {
            revert InvalidAmount();
        }
        if (userVaultShares[_msgSender()] < _shares) {
            revert InsufficientFunds(); // User doesn't have enough shares
        }
        if (totalVaultShares == 0) {
            revert InsufficientFunds(); // Vault is empty or no shares were ever issued
        }

        // Calculate ETH to return based on current share price
        uint256 ethToReturn = _shares.mul(address(this).balance).div(totalVaultShares);
        if (ethToReturn == 0) revert CannotTransferZERO();

        userVaultShares[_msgSender()] = userVaultShares[_msgSender()].sub(_shares);
        totalVaultShares = totalVaultShares.sub(_shares);

        // Deduct reputation (e.g., a percentage of current reputation for unstaking)
        uint256 currentReputation = reputationScores[_msgSender()];
        uint256 reputationLossAmount = currentReputation.mul(1000).div(10000); // Lose 10% of reputation
        _loseReputation(_msgSender(), reputationLossAmount);

        (bool sent, ) = _msgSender().call{value: ethToReturn}("");
        if (!sent) {
            // For production, consider re-adding shares/ETH to prevent loss if transfer fails.
            revert InsufficientFunds(); // Failed to send ETH
        }

        emit Unstaked(_msgSender(), ethToReturn, _shares);
    }

    /**
     * @dev Allows users to claim accumulated rewards. Rewards are based on staked shares and reputation multiplier.
     *      This function would need to be integrated with a yield generation strategy (e.g., from external DeFi protocols)
     *      which is beyond the scope of a single contract. Here, it's a placeholder using `userPendingRewards`.
     */
    function claimRewards() public whenNotPaused {
        uint256 rewards = userPendingRewards[_msgSender()];
        if (rewards == 0) {
            revert InvalidAmount(); // No rewards to claim
        }

        userPendingRewards[_msgSender()] = 0; // Reset pending rewards after claiming

        (bool sent, ) = _msgSender().call{value: rewards}("");
        if (!sent) {
            // If sending fails, revert and re-add rewards to pending for safety.
            userPendingRewards[_msgSender()] = rewards;
            revert InsufficientFunds(); // Failed to send ETH
        }

        emit RewardsClaimed(_msgSender(), rewards);
    }

    /**
     * @dev Internal helper function to calculate the current price of one vault share.
     * @return The value of one share in Wei.
     */
    function getCurrentSharePrice() internal view returns (uint256) {
        if (totalVaultShares == 0) {
            return 1 ether; // If no shares, assume 1 share = 1 ETH as base for first staker
        }
        return address(this).balance.div(totalVaultShares);
    }

    /**
     * @dev Returns the total ETH held by the protocol vault.
     * @return The total ETH balance of the contract.
     */
    function getVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- 3. Reputation System ---

    /**
     * @dev Internal function to award reputation points to a user.
     *      Called by other protocol functions for positive contributions (e.g., staking, governance participation).
     * @param _user The address to award reputation to.
     * @param _amount The amount of reputation points to award.
     */
    function _earnReputation(address _user, uint256 _amount) internal {
        _applyReputationDecay(_user); // Apply decay before earning new reputation

        uint256 currentScore = reputationScores[_user];
        uint256 newScore = currentScore.add(_amount);
        reputationScores[_user] = newScore > maxReputationScore ? maxReputationScore : newScore; // Cap reputation
        lastReputationUpdateBlock[_user] = block.number;
        emit ReputationEarned(_user, _amount, reputationScores[_user]);
    }

    /**
     * @dev Internal function to reduce reputation points from a user.
     *      Called for negative actions or specific protocol events (e.g., unstaking).
     * @param _user The address to deduct reputation from.
     * @param _amount The amount of reputation points to deduct.
     */
    function _loseReputation(address _user, uint256 _amount) internal {
        _applyReputationDecay(_user); // Apply decay before losing reputation

        uint256 currentScore = reputationScores[_user];
        uint256 newScore = currentScore.sub(currentScore < _amount ? currentScore : _amount); // Ensure score doesn't go negative
        reputationScores[_user] = newScore;
        lastReputationUpdateBlock[_user] = block.number;
        emit ReputationLost(_user, _amount, reputationScores[_user]);
    }

    /**
     * @dev Returns a user's current reputation score.
     *      Automatically applies a simulated decay before returning the score for accurate view.
     * @param _user The address to query.
     * @return The user's current reputation score after simulated decay.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        uint256 score = reputationScores[_user];
        uint256 lastUpdateBlock = lastReputationUpdateBlock[_user];

        if (lastUpdateBlock > 0 && block.number > lastUpdateBlock && reputationDecayRateBps > 0) {
            uint256 blocksSinceLastUpdate = block.number - lastUpdateBlock;
            // Decay is applied per period. Let's assume 1 decay period = 100 blocks for demonstration.
            // In a real system, this could be time-based or a more complex block-based formula.
            uint256 decayPeriods = blocksSinceLastUpdate.div(100); // Every 100 blocks, 1 decay period passes
            if (decayPeriods > 0) {
                uint256 decayAmount = score.mul(reputationDecayRateBps).div(10000).mul(decayPeriods);
                score = score.sub(decayAmount > score ? score : decayAmount); // Ensure score doesn't go below zero
            }
        }
        return score;
    }

    /**
     * @dev Applies reputation decay for a specific user. Internal helper, also called by `decayReputation`.
     * @param _user The address for whom to apply decay.
     */
    function _applyReputationDecay(address _user) internal {
        uint256 currentScore = reputationScores[_user];
        uint256 lastUpdateBlock = lastReputationUpdateBlock[_user];

        if (lastUpdateBlock > 0 && block.number > lastUpdateBlock && reputationDecayRateBps > 0) {
            uint256 blocksSinceLastUpdate = block.number - lastUpdateBlock;
            uint256 decayPeriods = blocksSinceLastUpdate.div(100); // Assume 100 blocks per decay period
            
            if (decayPeriods > 0) {
                uint256 decayAmount = currentScore.mul(reputationDecayRateBps).div(10000).mul(decayPeriods);
                uint256 newScore = currentScore.sub(decayAmount > currentScore ? currentScore : decayAmount); // Prevent negative score
                reputationScores[_user] = newScore;
                lastReputationUpdateBlock[_user] = block.number;
                emit ReputationDecayed(_user, currentScore, newScore);
            }
        }
    }

    /**
     * @dev Callable by the designated Keeper to periodically apply reputation decay.
     *      This is typically called by an off-chain bot or a scheduled transaction for active users.
     *      For simplicity, this version applies to the caller. A more advanced version would take an array of users.
     */
    function decayReputation() public onlyKeeper {
        _applyReputationDecay(_msgSender());
    }

    /**
     * @dev Calculates a reward multiplier based on a user's reputation score.
     *      Higher reputation grants a higher multiplier, incentivizing good behavior.
     * @param _user The user's address.
     * @return The reward multiplier (e.g., 10000 = 1x, 12000 = 1.2x).
     */
    function getReputationMultiplier(address _user) public view returns (uint256) {
        uint256 score = getReputationScore(_user); // Get decayed score
        // Example: Base multiplier is 1x (10000 basis points). Add 0.1% per 100 reputation points.
        uint256 multiplier = 10000; // Represents 100% or 1x
        if (score > 0) {
            // Adds 10 bps to multiplier for every 100 reputation points (e.g., 100 rep -> 10 bps = 0.1%)
            multiplier = multiplier.add(score.div(100).mul(10)); 
        }
        // Cap the multiplier if a maximum boost is desired
        // return multiplier > MAX_MULTIPLIER ? MAX_MULTIPLIER : multiplier;
        return multiplier;
    }

    // --- 4. AI Oracle & Adaptive Parameters ---

    /**
     * @dev Updates the global AI sentiment score. Only callable by the designated AI Oracle.
     *      This score influences dynamic fees and reward rates.
     * @param _newScore The new AI sentiment score (e.g., -100 for very negative, 100 for very positive).
     */
    function updateAI_SentimentScore(int256 _newScore) public onlyOracle {
        if (_newScore < -100 || _newScore > 100) {
            revert InvalidAmount();
        }
        int256 oldScore = aiSentimentScore;
        aiSentimentScore = _newScore;
        emit AISentimentUpdated(oldScore, _newScore);
    }

    /**
     * @dev Returns the current AI sentiment score.
     * @return The current AI sentiment score.
     */
    function getAI_SentimentScore() public view returns (int256) {
        return aiSentimentScore;
    }

    /**
     * @dev Calculates the dynamic transaction fee rate based on AI sentiment.
     *      Example: Higher sentiment = lower fees, lower sentiment = higher fees.
     * @return The fee rate in basis points (e.g., 100 = 1%).
     */
    function getDynamicFeeRate() public view returns (uint256) {
        uint256 baseFeeBps = 100; // 1% base fee
        int256 sentiment = aiSentimentScore;

        if (sentiment > 0) {
            // Reduce fee by up to 50% for positive sentiment (max -50bps at sentiment 100)
            return baseFeeBps.sub(baseFeeBps.mul(uint256(sentiment)).div(200));
        } else {
            // Increase fee by up to 50% for negative sentiment (max +50bps at sentiment -100)
            return baseFeeBps.add(baseFeeBps.mul(uint256(-sentiment)).div(200));
        }
    }

    /**
     * @dev Calculates the dynamic reward distribution rate based on AI sentiment.
     *      Example: Higher sentiment = higher rewards, lower sentiment = lower rewards.
     * @return The reward rate in basis points.
     */
    function getDynamicRewardRate() public view returns (uint256) {
        uint256 baseRewardBps = 500; // 5% base reward rate
        int256 sentiment = aiSentimentScore;

        if (sentiment > 0) {
            // Increase rewards by up to 50% for positive sentiment (max +250bps at sentiment 100)
            return baseRewardBps.add(baseRewardBps.mul(uint256(sentiment)).div(200));
        } else {
            // Decrease rewards by up to 50% for negative sentiment (max -250bps at sentiment -100)
            return baseRewardBps.sub(baseRewardBps.mul(uint256(-sentiment)).div(200));
        }
    }

    // --- 5. Governance & DAO (Commit-Reveal Model) ---

    /**
     * @dev Returns the voting power of a user, considering their NEXF balance and reputation.
     *      If the user has delegated their vote, the delegatee's power is returned.
     * @param _user The address to query.
     * @return The total voting power (NEXF balance + weighted reputation).
     */
    function getVotingPower(address _user) public view returns (uint256) {
        address trueVoter = delegates[_user] == address(0) ? _user : delegates[_user];
        uint256 nexfBalance = balanceOf(trueVoter);
        uint256 reputation = getReputationScore(trueVoter);
        // Simple aggregation: 1 NEXF token = 1 VP, 100 reputation points = 1 VP (configurable ratio)
        return nexfBalance.add(reputation.div(100));
    }

    /**
     * @dev Allows users to propose a change to a core protocol parameter.
     *      Requires sufficient reputation and NEXF voting power.
     * @param _description A concise description of the proposal.
     * @param _paramName The string name of the parameter to change (e.g., "minStakeAmount").
     * @param _newValue The new value for the parameter.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(
        string memory _description,
        string memory _paramName,
        uint256 _newValue
    ) public whenNotPaused returns (uint256) {
        uint256 proposerReputation = getReputationScore(_msgSender());
        if (proposerReputation < minGovernanceReputation) {
            revert NotEnoughReputation(_msgSender(), proposerReputation, minGovernanceReputation);
        }
        if (getVotingPower(_msgSender()) < proposalThreshold) {
            revert InsufficientFunds(); // Not enough NEXF voting power to propose
        }

        // Validate paramName against a whitelist of mutable parameters
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (!(paramHash == keccak256(abi.encodePacked("minStakeAmount")) ||
              paramHash == keccak256(abi.encodePacked("initialReputationReward")) ||
              paramHash == keccak256(abi.encodePacked("maxReputationScore")) ||
              paramHash == keccak256(abi.encodePacked("reputationDecayRateBps")) ||
              paramHash == keccak256(abi.encodePacked("minGovernanceReputation")) ||
              paramHash == keccak256(abi.encodePacked("proposalThreshold")) ||
              paramHash == keccak256(abi.encodePacked("votingPeriodBlocks")) ||
              paramHash == keccak256(abi.encodePacked("revealPeriodBlocks")))) {
            revert InvalidParameterName();
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: _msgSender(),
            creationBlock: block.number,
            votingStartBlock: block.number.add(1), // Voting starts in the next block
            votingEndBlock: block.number.add(1).add(votingPeriodBlocks),
            revealEndBlock: block.number.add(1).add(votingPeriodBlocks).add(revealPeriodBlocks),
            state: ProposalState.ActiveCommit,
            yesVotes: 0,
            noVotes: 0,
            proposalThresholdAtCreation: proposalThreshold, // Snapshot the threshold
            delegatee: address(0), // Not a grant
            amount: 0, // Not a grant
            paramName: _paramName,
            newValue: _newValue,
            applicationURI: "", // Not a grant
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), _description);
        return proposalId;
    }

    /**
     * @dev Allows users to propose a Catalyst grant for external projects or initiatives.
     *      Requires sufficient reputation and NEXF voting power.
     * @param _description A description of the grant proposal.
     * @param _recipient The address that will receive the grant funds.
     * @param _amount The amount of ETH to grant (in Wei).
     * @param _applicationURI URI (e.g., IPFS hash) pointing to the off-chain application details.
     * @return The ID of the newly created proposal.
     */
    function proposeCatalystGrant(
        string memory _description,
        address _recipient,
        uint256 _amount,
        string memory _applicationURI
    ) public whenNotPaused returns (uint256) {
        uint256 proposerReputation = getReputationScore(_msgSender());
        if (proposerReputation < minGovernanceReputation) {
            revert NotEnoughReputation(_msgSender(), proposerReputation, minGovernanceReputation);
        }
        if (getVotingPower(_msgSender()) < proposalThreshold) {
            revert InsufficientFunds(); // Not enough NEXF voting power
        }
        if (_amount == 0 || _recipient == address(0)) {
            revert InvalidAmount();
        }
        if (bytes(_applicationURI).length == 0) {
            revert InvalidURI();
        }
        if (_amount > address(this).balance) {
            revert InsufficientFunds(); // Cannot propose to grant more than available in the vault
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: _msgSender(),
            creationBlock: block.number,
            votingStartBlock: block.number.add(1),
            votingEndBlock: block.number.add(1).add(votingPeriodBlocks),
            revealEndBlock: block.number.add(1).add(votingPeriodBlocks).add(revealPeriodBlocks),
            state: ProposalState.ActiveCommit,
            yesVotes: 0,
            noVotes: 0,
            proposalThresholdAtCreation: proposalThreshold,
            delegatee: _recipient, // Recipient for the grant
            amount: _amount,
            paramName: "", // Not a parameter change
            newValue: 0, // Not a parameter change
            applicationURI: _applicationURI,
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), _description);
        emit CatalystApplicationSubmitted(proposalId, _msgSender(), _applicationURI);
        return proposalId;
    }
    
    /**
     * @dev Allows a user to delegate their voting power (NEXF balance + reputation) to another address.
     *      This enables "liquid democracy" where experts or trusted community members can vote on behalf of others.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) public {
        address currentDelegate = delegates[_msgSender()];
        if (currentDelegate != _delegatee) {
            delegates[_msgSender()] = _delegatee;
            emit DelegateChanged(_msgSender(), currentDelegate, _delegatee);
        }
    }

    /**
     * @dev Clears any existing vote delegation for the calling user.
     *      Their voting power reverts to being based on their own holdings/reputation.
     */
    function undelegateVote() public {
        address currentDelegate = delegates[_msgSender()];
        if (currentDelegate != address(0)) {
            delete delegates[_msgSender()];
            emit DelegateChanged(_msgSender(), currentDelegate, address(0));
        }
    }

    /**
     * @dev Commits a hashed vote for a proposal during the commitment phase.
     *      Users hash their actual vote (true for YES, false for NO) along with a random nonce off-chain,
     *      and submit only the hash. This prevents front-running and vote buying.
     * @param _proposalId The ID of the proposal.
     * @param _voteHash The `keccak256` hash of `abi.encodePacked(_support, _nonce)`.
     */
    function commitVote(uint256 _proposalId, bytes32 _voteHash) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) { // Check if proposal exists, id 0 is default value
            revert ProposalNotFound();
        }
        if (_msgSender() == proposal.proposer) {
            revert CannotVoteOnOwnProposal(); // Proposer cannot vote on their own proposal
        }
        if (block.number < proposal.votingStartBlock || block.number > proposal.votingEndBlock) {
            revert VotingPeriodNotOpen();
        }
        if (proposal.state != ProposalState.ActiveCommit) {
            revert InvalidProposalState();
        }
        if (hasCommitted[_proposalId][_msgSender()]) {
            revert DuplicateVote(); // User has already committed a vote
        }

        uint256 voterReputation = getReputationScore(_msgSender());
        if (voterReputation < minGovernanceReputation) {
            revert NotEnoughReputation(_msgSender(), voterReputation, minGovernanceReputation);
        }
        if (getVotingPower(_msgSender()) == 0) {
            revert InsufficientFunds(); // Not enough voting power
        }

        proposal.commitHashes[_msgSender()] = _voteHash;
        hasCommitted[_proposalId][_msgSender()] = true;
        _earnReputation(_msgSender(), 10); // Reward a small amount of reputation for governance participation
        emit VoteCommitted(_proposalId, _msgSender(), _voteHash);
    }

    /**
     * @dev Reveals a previously committed vote during the reveal phase.
     *      The user provides their actual vote and nonce, which is checked against the stored hash.
     *      If valid, the vote is counted.
     * @param _proposalId The ID of the proposal.
     * @param _support True for YES vote, false for NO vote.
     * @param _nonce The random nonce string used during the commitment.
     */
    function revealVote(uint256 _proposalId, bool _support, bytes32 _nonce) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) {
            revert ProposalNotFound();
        }
        if (block.number <= proposal.votingEndBlock || block.number > proposal.revealEndBlock) {
            revert RevealPeriodNotOpen();
        }
        if (proposal.state != ProposalState.ActiveCommit && proposal.state != ProposalState.ActiveReveal) {
            revert InvalidProposalState();
        }
        if (!hasCommitted[_proposalId][_msgSender()]) {
            revert InvalidProof(); // No commitment found for this user
        }
        if (proposal.hasRevealed[_msgSender()]) {
            revert AlreadyVoted(); // User has already revealed their vote
        }

        bytes32 expectedHash = keccak256(abi.encodePacked(_support, _nonce));
        if (proposal.commitHashes[_msgSender()] != expectedHash) {
            revert InvalidProof(); // Hash mismatch, invalid proof
        }

        // Apply vote using the user's current voting power
        uint256 votingPower = getVotingPower(_msgSender());
        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }
        
        proposal.hasRevealed[_msgSender()] = true;

        // Transition proposal state if reveal period has started
        if (block.number > proposal.votingEndBlock && block.number <= proposal.revealEndBlock && proposal.state == ProposalState.ActiveCommit) {
            proposal.state = ProposalState.ActiveReveal;
        } else if (block.number > proposal.revealEndBlock) {
             _finalizeProposalState(_proposalId); // Finalize if reveal period is over
        }
        
        emit VoteRevealed(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Internal helper to transition the state of a proposal to Succeeded or Defeated
     *      after the reveal period has concluded.
     * @param _proposalId The ID of the proposal.
     */
    function _finalizeProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number <= proposal.revealEndBlock) {
            revert VotingPeriodNotOpen(); // Still within the reveal period
        }
        // Only finalize if not already in a terminal state
        if (proposal.state == ProposalState.Succeeded || proposal.state == ProposalState.Defeated || proposal.state == ProposalState.Executed || proposal.state == ProposalState.Canceled) {
            return; 
        }

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        if (totalVotes == 0) { // If no one voted at all
            proposal.state = ProposalState.Defeated;
        } else if (proposal.yesVotes > proposal.noVotes && // Simple majority
                   proposal.yesVotes.mul(10000).div(totalVotes) >= 5000) { // Example: >= 50% approval
            // Additional quorum checks could be added here (e.g., totalVotes > minVoteThreshold)
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Defeated;
        }
    }

    /**
     * @dev Executes a successfully passed proposal.
     *      Callable by the `owner` (intended to be a DAO governance module in a live system)
     *      after the reveal period and if the proposal has succeeded.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused { // Owner role simulates DAO executor
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) {
            revert ProposalNotFound();
        }
        if (block.number <= proposal.revealEndBlock) {
            revert VotingPeriodNotOpen(); // Cannot execute before reveal phase ends
        }
        _finalizeProposalState(_proposalId); // Ensure the proposal state is up-to-date

        if (proposal.state != ProposalState.Succeeded) {
            revert ProposalNotExecutable();
        }
        if (proposal.executed) {
            revert AlreadyActive(); // Proposal already executed
        }

        proposal.executed = true; // Mark as executed

        // Execute action based on proposal type
        if (bytes(proposal.paramName).length > 0) { // Parameter change proposal
            bytes32 paramHash = keccak256(abi.encodePacked(proposal.paramName));
            uint256 oldValue; // Placeholder for logging old value

            if (paramHash == keccak256(abi.encodePacked("minStakeAmount"))) {
                oldValue = minStakeAmount;
                minStakeAmount = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("initialReputationReward"))) {
                oldValue = initialReputationReward;
                initialReputationReward = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("maxReputationScore"))) {
                oldValue = maxReputationScore;
                maxReputationScore = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("reputationDecayRateBps"))) {
                oldValue = reputationDecayRateBps;
                reputationDecayRateBps = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("minGovernanceReputation"))) {
                oldValue = minGovernanceReputation;
                minGovernanceReputation = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("proposalThreshold"))) {
                oldValue = proposalThreshold;
                proposalThreshold = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("votingPeriodBlocks"))) {
                oldValue = votingPeriodBlocks;
                votingPeriodBlocks = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("revealPeriodBlocks"))) {
                oldValue = revealPeriodBlocks;
                revealPeriodBlocks = proposal.newValue;
            } else {
                revert InvalidParameterName(); // Should not happen if validation in propose func is correct
            }
            emit ParameterChanged(proposal.paramName, oldValue, proposal.newValue);
        } else if (proposal.amount > 0 && proposal.delegatee != address(0)) { // Catalyst grant proposal
            _fundCatalystGrant(_proposalId);
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Gets the current state of a proposal, dynamically updating it if time periods have passed.
     * @param _proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) {
            revert ProposalNotFound();
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number <= proposal.votingEndBlock) {
            return ProposalState.ActiveCommit;
        } else if (block.number <= proposal.revealEndBlock) {
            return ProposalState.ActiveReveal;
        } else {
            // After reveal period, determine final state based on votes
            uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
            if (totalVotes == 0) {
                return ProposalState.Defeated;
            } else if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes.mul(10000).div(totalVotes) >= 5000) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
    }

    // --- 6. Catalyst Grants ---

    /**
     * @dev This function is primarily for recording the existence of an off-chain application.
     *      Actual funding of a grant happens via `proposeCatalystGrant` and `executeProposal`.
     *      A more robust system might have a separate registry for applications.
     * @param _applicationURI The URI (e.g., IPFS hash) pointing to the detailed off-chain application.
     */
    function submitCatalystApplication(string memory _applicationURI) public whenNotPaused {
        if (bytes(_applicationURI).length == 0) {
            revert InvalidURI();
        }
        // Emitting an event as a record. Note: proposalId 0 indicates it's a general application, not yet linked to a specific proposal.
        emit CatalystApplicationSubmitted(0, _msgSender(), _applicationURI); 
    }

    /**
     * @dev Internal function to transfer funds for an approved catalyst grant.
     *      Only callable by `executeProposal` for a successful grant proposal.
     * @param _proposalId The ID of the approved grant proposal.
     */
    function _fundCatalystGrant(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        // Checks are mostly done in executeProposal, but double-check crucial ones
        if (proposal.state != ProposalState.Succeeded || proposal.executed) {
            revert ProposalNotExecutable();
        }
        if (proposal.amount == 0 || proposal.delegatee == address(0)) {
            revert InvalidProposalState();
        }
        if (address(this).balance < proposal.amount) {
            revert InsufficientFunds(); // Contract does not have enough balance
        }

        (bool sent, ) = proposal.delegatee.call{value: proposal.amount}("");
        if (!sent) {
            revert InsufficientFunds(); // Failed to send ETH
        }

        emit CatalystGrantFunded(_proposalId, proposal.delegatee, proposal.amount);
    }

    // --- 7. Admin & Emergency (DAO-Controlled) ---

    /**
     * @dev Pauses the protocol's core functions, preventing most state-changing operations.
     *      Typically triggered by governance (DAO) or in emergencies.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the protocol, allowing operations to resume.
     *      Typically triggered by governance (DAO).
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows emergency withdrawal of funds (ETH or ERC20 tokens) from the contract.
     *      This is a critical function, ideally controlled by a DAO or multi-sig, and used only when the protocol is paused.
     * @param _token The address of the token to withdraw (0x0 for ETH).
     * @param _recipient The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawFunds(
        address _token,
        address _recipient,
        uint256 _amount
    ) public onlyOwner whenPaused { // Only callable by owner when paused, implies emergency
        if (_recipient == address(0) || _amount == 0) {
            revert InvalidAmount();
        }

        if (_token == address(0)) { // ETH withdrawal
            if (address(this).balance < _amount) {
                revert InsufficientFunds();
            }
            (bool sent, ) = _recipient.call{value: _amount}("");
            if (!sent) {
                revert InsufficientFunds(); // Failed to send ETH
            }
        } else { // ERC20 token withdrawal
            IERC20 token = IERC20(_token);
            if (token.balanceOf(address(this)) < _amount) {
                revert InsufficientFunds();
            }
            bool success = token.transfer(_recipient, _amount);
            if (!success) {
                revert InsufficientFunds(); // Failed to transfer ERC20
            }
        }
    }

    // --- Receive ETH function ---
    /**
     * @dev Fallback function to allow the contract to receive plain ETH.
     *      This ETH will contribute to the general vault balance and can be staked.
     */
    receive() external payable {
        // ETH sent directly to the contract contributes to its balance, which can then be staked or used for grants.
        // No specific event here, as actual staking requires calling the stake() function.
    }
}

// Minimal IERC20 interface for emergencyWithdrawFunds
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```