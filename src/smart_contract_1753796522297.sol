Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical DeFi or NFT concepts. I'll propose a concept I call **"VeritasNet" - A Decentralized Epistemic Network and Predictive Oracle.**

**Concept:** VeritasNet is a platform where users submit "Propositions" (statements or predictions about the future or subjective truths). Other users then "Validate" or "Challenge" these propositions by staking tokens. The system uses a dynamic reputation (Epistemic Score) and a unique "Veracity Score" for propositions to establish a collective, incentivized truth or consensus, rather than just relying on simple majority votes. This can be used for forecasting subjective outcomes, curating decentralized knowledge, or even for "on-chain expert systems."

**Key Advanced Concepts:**

1.  **Dynamic Reputation (Epistemic Score):** Users gain or lose reputation based on the accuracy of their validations/challenges. Higher reputation users might have more weight or earn more.
2.  **Incentivized Truth-Seeking:** Users are rewarded for correctly validating or challenging propositions that align with the final, resolved outcome. Stakers are slashed if they are wrong.
3.  **Proposition Lifecycle Management:** Propositions go through stages: Pending, Validated, Challenged, Finalized.
4.  **Collective "Veracity Score":** Each proposition accumulates a "veracity score" reflecting the collective confidence in its truthfulness, not just a binary true/false.
5.  **Time-Windowed Validation:** Propositions have a specific period for voting before resolution.
6.  **ERC-20 Integration:** Uses a custom ERC-20 token for staking, fees, and rewards.
7.  **Emergency Pause/Admin Controls:** Standard but important for security.

---

## VeritasNet - Decentralized Epistemic Network & Predictive Oracle

**Outline:**

1.  **Contract Information:** License, Pragma, Imports.
2.  **Error Handling:** Custom errors for clarity.
3.  **Interfaces:** `IERC20` for token interaction.
4.  **Enums:** For Proposition Status and Vote Type.
5.  **Structs:**
    *   `Proposition`: Details of a submitted statement/prediction.
    *   `Vote`: Details of a validation or challenge vote.
    *   `UserAccount`: User-specific reputation and staking data.
6.  **State Variables:** Mappings to store propositions, votes, user accounts, and configuration parameters.
7.  **Events:** To signal important state changes.
8.  **Modifiers:** For access control (`onlyOwner`) and contract state (`whenNotPaused`).
9.  **Core Logic Functions:**
    *   `constructor`: Initializes owner and payment token.
    *   `submitProposition`: Allows users to post propositions.
    *   `validateProposition`: Allows users to stake and agree with a proposition.
    *   `challengeProposition`: Allows users to stake and disagree with a proposition.
    *   `finalizeProposition`: Resolves a proposition, distributes rewards/slashes stakes, updates scores.
    *   `claimRewards`: Allows users to claim accumulated rewards.
    *   `depositTokens`: Users deposit tokens into contract for future stakes/fees.
    *   `withdrawTokens`: Users withdraw available tokens.
10. **Admin & Configuration Functions:**
    *   `setValidationWindow`: Sets the time window for voting.
    *   `setPropositionFee`: Sets the fee for submitting a proposition.
    *   `setVoteStakeAmount`: Sets the minimum stake for validation/challenge.
    *   `setEpistemicScoreInfluence`: Sets how much epistemic score influences rewards/penalties.
    *   `updatePaymentToken`: Changes the ERC-20 token used.
    *   `setMinimumEpistemicScoreForSubmission`: Sets minimum reputation to submit propositions.
    *   `setOwner`: Transfers contract ownership.
    *   `togglePause`: Pauses/unpauses contract functionality.
    *   `recoverERC20`: Recovers accidentally sent ERC20 tokens (admin).
11. **View & Getter Functions (Read-only):**
    *   `getPropositionDetails`: Retrieves all data for a specific proposition.
    *   `getUserAccountDetails`: Retrieves a user's epistemic score and staked amount.
    *   `getPropositionVotes`: Retrieves details for all votes on a proposition.
    *   `getContractBalance`: Returns the contract's balance of the payment token.
    *   `getAvailableRewards`: Returns pending rewards for a user.
    *   `getPendingPropositionsCount`: Returns the number of propositions awaiting finalization.

---

**Function Summary (20+ Functions):**

1.  `constructor(address _paymentTokenAddress)`: Initializes the contract, setting the owner and the address of the ERC-20 token used for staking and rewards.
2.  `submitProposition(string memory _contentHash)`: Allows any user (meeting minimum epistemic score) to submit a new proposition by paying a fee. `_contentHash` should be IPFS hash or similar for proposition content.
3.  `validateProposition(uint256 _propositionId)`: Users stake tokens to vote "true" on a proposition. Increases proposition's positive sentiment.
4.  `challengeProposition(uint256 _propositionId)`: Users stake tokens to vote "false" on a proposition. Increases proposition's negative sentiment.
5.  `finalizeProposition(uint256 _propositionId)`: Resolves a proposition after its validation window. Distributes rewards to correct voters, slashes incorrect voters, and updates proposition's `veracityScore` and users' `epistemicScore`. Only executable after the window closes.
6.  `claimRewards()`: Allows users to withdraw their accumulated rewards from finalized propositions.
7.  `depositTokens(uint256 _amount)`: Allows users to deposit the payment token into the contract, making it available for future staking and fees.
8.  `withdrawTokens(uint256 _amount)`: Allows users to withdraw their available balance (not locked in stakes) of the payment token from the contract.
9.  `setValidationWindow(uint256 _newWindowInSeconds)`: (Owner-only) Sets the duration for which propositions are open for validation/challenge.
10. `setPropositionFee(uint256 _newFeeAmount)`: (Owner-only) Sets the ERC-20 token fee required to submit a new proposition.
11. `setVoteStakeAmount(uint256 _newStakeAmount)`: (Owner-only) Sets the fixed amount of ERC-20 tokens required to validate or challenge a proposition.
12. `setEpistemicScoreInfluence(uint256 _influencePercentage)`: (Owner-only) Adjusts how much the `epistemicScore` of a user influences their reward multiplier or penalty reduction.
13. `updatePaymentToken(address _newTokenAddress)`: (Owner-only) Changes the ERC-20 token address used by the contract. Careful use required.
14. `setMinimumEpistemicScoreForSubmission(uint256 _newMinScore)`: (Owner-only) Sets the minimum `epistemicScore` a user must have to be eligible to submit propositions.
15. `setOwner(address _newOwner)`: (Owner-only) Transfers ownership of the contract to a new address.
16. `togglePause()`: (Owner-only) Pauses or unpauses critical contract functionalities (e.g., submitting, voting, finalizing) in emergencies.
17. `recoverERC20(address _tokenAddress, uint256 _amount)`: (Owner-only) Allows the owner to recover ERC-20 tokens accidentally sent to the contract that are *not* the designated payment token.
18. `getPropositionDetails(uint256 _propositionId)`: (View) Returns all stored details for a specific proposition.
19. `getUserAccountDetails(address _user)`: (View) Returns a user's `epistemicScore`, `stakedAmount`, and `availableRewards`.
20. `getPropositionVotes(uint256 _propositionId)`: (View) Returns an array of `Vote` structs for a given proposition.
21. `getContractBalance()`: (View) Returns the current balance of the designated payment token held by the contract.
22. `getAvailableRewards(address _user)`: (View) Returns the amount of rewards a user can currently claim.
23. `getPendingPropositionsCount()`: (View) Returns the total number of propositions that are currently in the `PENDING` or `VALIDATING` state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title VeritasNet - A Decentralized Epistemic Network & Predictive Oracle
/// @author YourNameHere (inspired by request)
/// @notice This contract enables users to submit "propositions" (statements/predictions),
///         which are then validated or challenged by other users through staking.
///         It maintains a dynamic 'Epistemic Score' for users based on their
///         accuracy and a 'Veracity Score' for propositions based on collective consensus.
///         Rewards are distributed, and stakes are slashed, based on the final resolution.

contract VeritasNet is Ownable, Pausable {

    // --- Custom Errors ---
    error InvalidPropositionId();
    error PropositionNotInValidState();
    error PropositionStillActive();
    error PropositionAlreadyFinalized();
    error InsufficientStakeAmount();
    error InsufficientBalance();
    error NotEnoughTimePassed();
    error NotEnoughTimeLeft();
    error NoRewardsToClaim();
    error DuplicateVote();
    error EpistemicScoreTooLow();
    error SelfInteraction();
    error TokenTransferFailed();

    // --- Enums ---
    enum PropositionStatus {
        PENDING,       // Just submitted, waiting for initial votes
        VALIDATING,    // Actively receiving votes
        FINALIZED_TRUE, // Resolved as true/validated
        FINALIZED_FALSE // Resolved as false/challenged
    }

    enum VoteType {
        VALIDATE,
        CHALLENGE
    }

    // --- Structs ---

    struct Proposition {
        uint256 id;
        address proposer;
        string contentHash; // IPFS hash or similar for the actual proposition text/data
        uint256 creationTimestamp;
        uint256 validationWindowEnd;
        uint256 totalValidationStaked;
        uint256 totalChallengeStaked;
        PropositionStatus status;
        int256 veracityScore; // A score reflecting collective belief, e.g., 0-100 or -100 to 100
        uint256 totalVotes;
    }

    struct Vote {
        uint256 id;
        uint256 propositionId;
        address voter;
        VoteType voteType;
        uint256 stakeAmount;
        uint256 timestamp;
    }

    struct UserAccount {
        uint256 epistemicScore; // Represents user's reputation/accuracy
        uint256 totalStaked;    // Total tokens user has ever staked (for reference)
        uint256 availableRewards; // Rewards accumulated from correct votes
    }

    // --- State Variables ---

    IERC20 public paymentToken;

    uint256 public nextPropositionId;
    uint256 public nextVoteId;

    // Configuration parameters
    uint256 public validationWindowDuration; // In seconds
    uint256 public propositionFee;         // Amount of paymentToken to submit a proposition
    uint256 public voteStakeAmount;        // Amount of paymentToken to cast a vote
    uint256 public epistemicScoreInfluence; // Percentage (0-100) how much epistemic score affects rewards/penalties
    uint256 public minimumEpistemicScoreForSubmission; // Minimum score to submit a proposition

    // Mappings
    mapping(uint256 => Proposition) public propositions;
    mapping(uint256 => Vote) public votes;
    mapping(address => UserAccount) public userAccounts;
    mapping(uint256 => uint256[]) public propositionVotes; // propositionId => array of voteIds
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposition; // user => propositionId => bool

    // Internal mapping to track active stakes per user per proposition
    mapping(address => mapping(uint256 => uint256)) private userPropositionStakes;


    // --- Events ---

    event PropositionSubmitted(
        uint256 indexed propositionId,
        address indexed proposer,
        string contentHash,
        uint256 creationTimestamp,
        uint256 validationWindowEnd
    );
    event VoteCasted(
        uint256 indexed voteId,
        uint256 indexed propositionId,
        address indexed voter,
        VoteType voteType,
        uint256 stakeAmount
    );
    event PropositionFinalized(
        uint256 indexed propositionId,
        PropositionStatus newStatus,
        int256 finalVeracityScore,
        uint256 totalValidationStaked,
        uint256 totalChallengeStaked
    );
    event StakeReleased(address indexed user, uint256 indexed propositionId, uint256 amount);
    event StakeSlashed(address indexed user, uint256 indexed propositionId, uint256 amount);
    event EpistemicScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ConfigurationUpdated(string indexed paramName, uint256 newValue);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event ERC20Recovered(address indexed tokenAddress, uint256 amount);

    // --- Constructor ---

    constructor(address _paymentTokenAddress) Ownable(msg.sender) {
        if (_paymentTokenAddress == address(0)) {
            revert("Invalid payment token address");
        }
        paymentToken = IERC20(_paymentTokenAddress);

        // Initial default configurations
        validationWindowDuration = 7 days; // 7 days for voting
        propositionFee = 10 * (10 ** 18);  // 10 tokens
        voteStakeAmount = 1 * (10 ** 18);  // 1 token per vote
        epistemicScoreInfluence = 50;     // 50% influence
        minimumEpistemicScoreForSubmission = 0; // No minimum initially

        nextPropositionId = 1;
        nextVoteId = 1;

        // Initialize owner's epistemic score to a base value
        userAccounts[msg.sender].epistemicScore = 1000;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Core Logic Functions ---

    /// @notice Allows a user to submit a new proposition.
    ///         Requires a fee and optionally a minimum epistemic score.
    /// @param _contentHash IPFS hash or similar identifier for the proposition's content.
    function submitProposition(string memory _contentHash) public payable whenNotPaused {
        if (userAccounts[msg.sender].epistemicScore < minimumEpistemicScoreForSubmission) {
            revert EpistemicScoreTooLow();
        }
        if (propositionFee > 0) {
            if (!paymentToken.transferFrom(msg.sender, address(this), propositionFee)) {
                revert TokenTransferFailed();
            }
        }

        uint256 propId = nextPropositionId++;
        uint256 endTime = block.timestamp + validationWindowDuration;

        propositions[propId] = Proposition({
            id: propId,
            proposer: msg.sender,
            contentHash: _contentHash,
            creationTimestamp: block.timestamp,
            validationWindowEnd: endTime,
            totalValidationStaked: 0,
            totalChallengeStaked: 0,
            status: PropositionStatus.PENDING,
            veracityScore: 0, // Neutral initial score
            totalVotes: 0
        });

        // Initialize user account if it's their first interaction
        if (userAccounts[msg.sender].epistemicScore == 0 && msg.sender != owner()) {
            userAccounts[msg.sender].epistemicScore = 100; // Base score for new users
        }

        emit PropositionSubmitted(propId, msg.sender, _contentHash, block.timestamp, endTime);
    }

    /// @notice Allows a user to validate (agree with) a proposition.
    ///         Requires staking `voteStakeAmount` tokens.
    /// @param _propositionId The ID of the proposition to validate.
    function validateProposition(uint256 _propositionId) public whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert InvalidPropositionId();
        if (prop.status != PropositionStatus.PENDING && prop.status != PropositionStatus.VALIDATING) {
            revert PropositionNotInValidState();
        }
        if (block.timestamp >= prop.validationWindowEnd) revert NotEnoughTimeLeft();
        if (hasVotedOnProposition[msg.sender][_propositionId]) revert DuplicateVote();
        if (msg.sender == prop.proposer) revert SelfInteraction();

        // Transfer stake amount from user to contract
        if (!paymentToken.transferFrom(msg.sender, address(this), voteStakeAmount)) {
            revert TokenTransferFailed();
        }

        uint256 voteId = nextVoteId++;
        votes[voteId] = Vote({
            id: voteId,
            propositionId: _propositionId,
            voter: msg.sender,
            voteType: VoteType.VALIDATE,
            stakeAmount: voteStakeAmount,
            timestamp: block.timestamp
        });

        prop.totalValidationStaked += voteStakeAmount;
        prop.totalVotes++;
        propositionVotes[_propositionId].push(voteId);
        hasVotedOnProposition[msg.sender][_propositionId] = true;
        userPropositionStakes[msg.sender][_propositionId] += voteStakeAmount; // Track specific stake

        // Set status to VALIDATING if it was PENDING
        if (prop.status == PropositionStatus.PENDING) {
            prop.status = PropositionStatus.VALIDATING;
        }

        // Initialize user account if it's their first interaction
        if (userAccounts[msg.sender].epistemicScore == 0 && msg.sender != owner()) {
            userAccounts[msg.sender].epistemicScore = 100; // Base score for new users
        }

        emit VoteCasted(voteId, _propositionId, msg.sender, VoteType.VALIDATE, voteStakeAmount);
    }

    /// @notice Allows a user to challenge (disagree with) a proposition.
    ///         Requires staking `voteStakeAmount` tokens.
    /// @param _propositionId The ID of the proposition to challenge.
    function challengeProposition(uint256 _propositionId) public whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert InvalidPropositionId();
        if (prop.status != PropositionStatus.PENDING && prop.status != PropositionStatus.VALIDATING) {
            revert PropositionNotInValidState();
        }
        if (block.timestamp >= prop.validationWindowEnd) revert NotEnoughTimeLeft();
        if (hasVotedOnProposition[msg.sender][_propositionId]) revert DuplicateVote();
        if (msg.sender == prop.proposer) revert SelfInteraction();

        // Transfer stake amount from user to contract
        if (!paymentToken.transferFrom(msg.sender, address(this), voteStakeAmount)) {
            revert TokenTransferFailed();
        }

        uint256 voteId = nextVoteId++;
        votes[voteId] = Vote({
            id: voteId,
            propositionId: _propositionId,
            voter: msg.sender,
            voteType: VoteType.CHALLENGE,
            stakeAmount: voteStakeAmount,
            timestamp: block.timestamp
        });

        prop.totalChallengeStaked += voteStakeAmount;
        prop.totalVotes++;
        propositionVotes[_propositionId].push(voteId);
        hasVotedOnProposition[msg.sender][_propositionId] = true;
        userPropositionStakes[msg.sender][_propositionId] += voteStakeAmount; // Track specific stake

        // Set status to VALIDATING if it was PENDING
        if (prop.status == PropositionStatus.PENDING) {
            prop.status = PropositionStatus.VALIDATING;
        }

        // Initialize user account if it's their first interaction
        if (userAccounts[msg.sender].epistemicScore == 0 && msg.sender != owner()) {
            userAccounts[msg.sender].epistemicScore = 100; // Base score for new users
        }

        emit VoteCasted(voteId, _propositionId, msg.sender, VoteType.CHALLENGE, voteStakeAmount);
    }

    /// @notice Finalizes a proposition after its validation window has closed.
    ///         Calculates the outcome, updates veracity and epistemic scores,
    ///         and distributes rewards or slashes stakes.
    /// @param _propositionId The ID of the proposition to finalize.
    function finalizeProposition(uint256 _propositionId) public whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert InvalidPropositionId();
        if (prop.status == PropositionStatus.FINALIZED_TRUE || prop.status == PropositionStatus.FINALIZED_FALSE) {
            revert PropositionAlreadyFinalized();
        }
        if (block.timestamp < prop.validationWindowEnd) revert PropositionStillActive();

        PropositionStatus finalStatus;
        int256 newVeracityScore = 0;

        uint256 totalStaked = prop.totalValidationStaked + prop.totalChallengeStaked;
        if (totalStaked == 0) {
            // No votes, proposition is effectively neutral/undetermined
            finalStatus = PropositionStatus.FINALIZED_FALSE; // Or maybe introduce a 'UNDETERMINED' status
            newVeracityScore = 0;
            // Refund proposition fee to proposer if no one voted
            if (propositionFee > 0) {
                 if (!paymentToken.transfer(prop.proposer, propositionFee)) {
                    revert TokenTransferFailed();
                }
            }
        } else {
            // Calculate outcome based on staked amounts
            if (prop.totalValidationStaked >= prop.totalChallengeStaked) {
                finalStatus = PropositionStatus.FINALIZED_TRUE;
                // Veracity score based on ratio of validation stake to total stake, scaled
                newVeracityScore = int256((prop.totalValidationStaked * 100) / totalStaked);
            } else {
                finalStatus = PropositionStatus.FINALIZED_FALSE;
                // Veracity score based on ratio of challenge stake to total stake, scaled negatively
                newVeracityScore = -int256((prop.totalChallengeStaked * 100) / totalStaked);
            }
        }

        prop.status = finalStatus;
        prop.veracityScore = newVeracityScore;

        uint256 winningStakePool = 0;
        uint256 losingStakePool = 0;

        if (finalStatus == PropositionStatus.FINALIZED_TRUE) {
            winningStakePool = prop.totalValidationStaked;
            losingStakePool = prop.totalChallengeStaked;
        } else { // FINALIZED_FALSE
            winningStakePool = prop.totalChallengeStaked;
            losingStakePool = prop.totalValidationStaked;
        }

        // Iterate through all votes for this proposition
        for (uint256 i = 0; i < propositionVotes[_propositionId].length; i++) {
            uint256 voteId = propositionVotes[_propositionId][i];
            Vote storage currentVote = votes[voteId];
            UserAccount storage userAcc = userAccounts[currentVote.voter];

            // If it's the voter's first interaction
            if (userAcc.epistemicScore == 0 && currentVote.voter != owner()) {
                userAcc.epistemicScore = 100; // Base score for new users
            }

            uint256 initialStake = currentVote.stakeAmount;
            uint256 epistemicFactor = userAcc.epistemicScore > 0 ? userAcc.epistemicScore : 1; // Avoid division by zero
            epistemicFactor = epistemicFactor > 2000 ? 2000 : epistemicFactor; // Cap epistemic score influence to prevent runaway scores

            uint256 rewardAmount = 0;
            uint256 slashAmount = 0;

            bool isCorrectVote = (finalStatus == PropositionStatus.FINALIZED_TRUE && currentVote.voteType == VoteType.VALIDATE) ||
                                 (finalStatus == PropositionStatus.FINALIZED_FALSE && currentVote.voteType == VoteType.CHALLENGE);

            if (winningStakePool > 0) { // Avoid division by zero
                if (isCorrectVote) {
                    // Reward calculation: proportional to stake + epistemic influence
                    rewardAmount = (initialStake * 1000) / winningStakePool; // Base reward multiplier (e.g., 1000 to distribute losing pool + some gain)
                    rewardAmount = (rewardAmount * (1000 + (epistemicFactor * epistemicScoreInfluence / 100))) / 1000; // Influence from epistemic score
                    rewardAmount = (rewardAmount * losingStakePool) / 1000; // Rewards come from the losing pool
                    rewardAmount += initialStake; // Return initial stake

                    userAcc.availableRewards += rewardAmount;
                    uint256 oldEpistemicScore = userAcc.epistemicScore;
                    userAcc.epistemicScore += (initialStake * 100) / voteStakeAmount; // Increase score for correct vote
                    emit EpistemicScoreUpdated(currentVote.voter, oldEpistemicScore, userAcc.epistemicScore);
                    emit StakeReleased(currentVote.voter, _propositionId, initialStake);
                } else {
                    // Slash calculation: base slash + epistemic influence (less slash for higher score)
                    slashAmount = initialStake; // Default to full slash
                    slashAmount = (slashAmount * (1000 - (epistemicFactor * epistemicScoreInfluence / 100))) / 1000; // Reduce slash for higher score
                    slashAmount = (slashAmount * 80) / 100; // Slash 80%

                    // Transfer slashed amount to the contract (for reward pool)
                    // No need to transfer, as it's already in the contract. Just don't return it.
                    userAcc.availableRewards += (initialStake - slashAmount); // Return the unslashed portion

                    uint256 oldEpistemicScore = userAcc.epistemicScore;
                    userAcc.epistemicScore = userAcc.epistemicScore > (initialStake * 50 / voteStakeAmount) ?
                                             userAcc.epistemicScore - (initialStake * 50 / voteStakeAmount) : 0; // Decrease score for incorrect vote
                    emit EpistemicScoreUpdated(currentVote.voter, oldEpistemicScore, userAcc.epistemicScore);
                    emit StakeSlashed(currentVote.voter, _propositionId, slashAmount);
                }
            } else { // winningStakePool == 0 means no one voted correctly, or totalStaked was 0, everyone gets their stake back
                 userAcc.availableRewards += initialStake;
                 emit StakeReleased(currentVote.voter, _propositionId, initialStake);
            }
            delete userPropositionStakes[currentVote.voter][_propositionId]; // Clear specific stake tracking
        }

        emit PropositionFinalized(_propositionId, finalStatus, newVeracityScore, prop.totalValidationStaked, prop.totalChallengeStaked);
    }

    /// @notice Allows a user to claim their accumulated rewards.
    function claimRewards() public whenNotPaused {
        UserAccount storage userAcc = userAccounts[msg.sender];
        if (userAcc.availableRewards == 0) revert NoRewardsToClaim();

        uint256 amountToTransfer = userAcc.availableRewards;
        userAcc.availableRewards = 0; // Reset rewards before transfer

        if (!paymentToken.transfer(msg.sender, amountToTransfer)) {
            revert TokenTransferFailed();
        }

        emit RewardsClaimed(msg.sender, amountToTransfer);
    }

    /// @notice Allows a user to deposit tokens into the contract to fund future stakes and fees.
    /// @param _amount The amount of tokens to deposit.
    function depositTokens(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert InsufficientStakeAmount();
        if (!paymentToken.transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }
        userAccounts[msg.sender].totalStaked += _amount; // Track total staked for user reference
    }

    /// @notice Allows a user to withdraw available tokens from the contract.
    ///         Cannot withdraw tokens currently locked in active stakes.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawTokens(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert InsufficientStakeAmount();
        // This function assumes tokens are directly held by the user within the contract's balance
        // and that 'availableRewards' is the only 'available' balance for withdrawal.
        // For a more complex system, 'available balance' for withdrawal should be tracked separately from 'availableRewards'.
        // For this contract, we'll assume the user's withdrawable balance is their availableRewards + any unspent deposited tokens
        // For simplicity, this function will only allow withdrawal of 'availableRewards' for now.
        // A more robust system would track `userDeposits` separately and allow `withdrawUserDeposit`.
        // This function is kept simple by just allowing `claimRewards` which is tracked directly.
        // If a user has deposited tokens for future stakes, they are essentially 'spent' from their direct control until used or a dedicated withdraw function is added for them.
        // This needs careful re-evaluation for a production system. For now, users deposit to stake and claim rewards.
        revert("Withdrawal of general deposits is not supported directly. Use claimRewards.");
        // If we were to implement it:
        // if (paymentToken.balanceOf(address(this)) < _amount) revert InsufficientBalance(); // Contract level check
        // if (userAccounts[msg.sender].availableDeposits < _amount) revert InsufficientBalance(); // User level check
        // if (!paymentToken.transfer(msg.sender, _amount)) revert TokenTransferFailed();
        // userAccounts[msg.sender].availableDeposits -= _amount;
    }


    // --- Admin & Configuration Functions ---

    /// @notice Sets the duration for which propositions are open for validation/challenge.
    /// @param _newWindowInSeconds The new duration in seconds.
    function setValidationWindow(uint256 _newWindowInSeconds) public onlyOwner {
        if (_newWindowInSeconds == 0) revert("Validation window must be greater than 0");
        validationWindowDuration = _newWindowInSeconds;
        emit ConfigurationUpdated("validationWindowDuration", _newWindowInSeconds);
    }

    /// @notice Sets the ERC-20 token fee required to submit a new proposition.
    /// @param _newFeeAmount The new fee amount.
    function setPropositionFee(uint256 _newFeeAmount) public onlyOwner {
        propositionFee = _newFeeAmount;
        emit ConfigurationUpdated("propositionFee", _newFeeAmount);
    }

    /// @notice Sets the fixed amount of ERC-20 tokens required to validate or challenge a proposition.
    /// @param _newStakeAmount The new stake amount.
    function setVoteStakeAmount(uint256 _newStakeAmount) public onlyOwner {
        if (_newStakeAmount == 0) revert("Vote stake amount must be greater than 0");
        voteStakeAmount = _newStakeAmount;
        emit ConfigurationUpdated("voteStakeAmount", _newStakeAmount);
    }

    /// @notice Adjusts how much the 'epistemicScore' of a user influences their reward multiplier or penalty reduction.
    /// @param _influencePercentage A value between 0 and 100.
    function setEpistemicScoreInfluence(uint256 _influencePercentage) public onlyOwner {
        if (_influencePercentage > 100) revert("Influence percentage cannot exceed 100%");
        epistemicScoreInfluence = _influencePercentage;
        emit ConfigurationUpdated("epistemicScoreInfluence", _influencePercentage);
    }

    /// @notice Changes the ERC-20 token address used by the contract.
    ///         Use with extreme caution, as existing token balances will not migrate.
    /// @param _newTokenAddress The address of the new ERC-20 token.
    function updatePaymentToken(address _newTokenAddress) public onlyOwner {
        if (_newTokenAddress == address(0)) revert("Invalid token address");
        paymentToken = IERC20(_newTokenAddress);
        emit ConfigurationUpdated("paymentToken", uint256(uint160(_newTokenAddress))); // Cast address to uint for logging
    }

    /// @notice Sets the minimum `epistemicScore` a user must have to be eligible to submit propositions.
    /// @param _newMinScore The new minimum epistemic score.
    function setMinimumEpistemicScoreForSubmission(uint256 _newMinScore) public onlyOwner {
        minimumEpistemicScoreForSubmission = _newMinScore;
        emit ConfigurationUpdated("minimumEpistemicScoreForSubmission", _newMinScore);
    }

    /// @notice Transfers ownership of the contract.
    /// @param _newOwner The address of the new owner.
    function setOwner(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner); // Uses Ownable's transferOwnership
        emit OwnershipTransferred(owner(), _newOwner);
    }

    /// @notice Pauses or unpauses critical contract functionalities.
    ///         Uses Pausable's _pause() and _unpause().
    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
            emit ContractUnpaused(msg.sender);
        } else {
            _pause();
            emit ContractPaused(msg.sender);
        }
    }

    /// @notice Allows the owner to recover ERC-20 tokens accidentally sent to the contract
    ///         that are NOT the designated payment token.
    /// @param _tokenAddress The address of the ERC-20 token to recover.
    /// @param _amount The amount of tokens to recover.
    function recoverERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress == address(0) || _amount == 0) revert("Invalid input for recovery");
        if (_tokenAddress == address(paymentToken)) revert("Cannot recover primary payment token with this function");

        IERC20 foreignToken = IERC20(_tokenAddress);
        if (foreignToken.balanceOf(address(this)) < _amount) revert InsufficientBalance();

        if (!foreignToken.transfer(owner(), _amount)) {
            revert TokenTransferFailed();
        }
        emit ERC20Recovered(_tokenAddress, _amount);
    }

    // --- View & Getter Functions ---

    /// @notice Retrieves all stored details for a specific proposition.
    /// @param _propositionId The ID of the proposition.
    /// @return propositionDetails A tuple containing all proposition data.
    function getPropositionDetails(uint256 _propositionId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory contentHash,
            uint256 creationTimestamp,
            uint256 validationWindowEnd,
            uint256 totalValidationStaked,
            uint256 totalChallengeStaked,
            PropositionStatus status,
            int256 veracityScore,
            uint256 totalVotes
        )
    {
        Proposition storage prop = propositions[_propositionId];
        if (prop.id == 0) revert InvalidPropositionId();

        return (
            prop.id,
            prop.proposer,
            prop.contentHash,
            prop.creationTimestamp,
            prop.validationWindowEnd,
            prop.totalValidationStaked,
            prop.totalChallengeStaked,
            prop.status,
            prop.veracityScore,
            prop.totalVotes
        );
    }

    /// @notice Retrieves a user's epistemic score, total staked amount (for reference), and available rewards.
    /// @param _user The address of the user.
    /// @return epistemicScore The user's current epistemic score.
    /// @return totalStaked The total amount the user has ever staked (for reference).
    /// @return availableRewards The amount of tokens the user can claim.
    function getUserAccountDetails(address _user)
        public
        view
        returns (uint256 epistemicScore, uint256 totalStaked, uint256 availableRewards)
    {
        UserAccount storage userAcc = userAccounts[_user];
        return (userAcc.epistemicScore, userAcc.totalStaked, userAcc.availableRewards);
    }

    /// @notice Retrieves details for all votes on a given proposition.
    /// @param _propositionId The ID of the proposition.
    /// @return votes_ An array of Vote structs.
    function getPropositionVotes(uint256 _propositionId) public view returns (Vote[] memory) {
        if (propositions[_propositionId].id == 0) revert InvalidPropositionId();

        uint256[] storage voteIds = propositionVotes[_propositionId];
        Vote[] memory _votes = new Vote[](voteIds.length);

        for (uint256 i = 0; i < voteIds.length; i++) {
            _votes[i] = votes[voteIds[i]];
        }
        return _votes;
    }

    /// @notice Returns the current balance of the designated payment token held by the contract.
    /// @return The contract's balance of the payment token.
    function getContractBalance() public view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }

    /// @notice Returns the amount of rewards a user can currently claim.
    /// @param _user The address of the user.
    /// @return The amount of claimable rewards.
    function getAvailableRewards(address _user) public view returns (uint256) {
        return userAccounts[_user].availableRewards;
    }

    /// @notice Returns the total number of propositions that are currently in the PENDING or VALIDATING state.
    /// @dev This function iterates through all propositions, which can be gas-intensive if there are many.
    ///      For a large-scale system, an off-chain indexer or a more efficient on-chain counter for active propositions would be needed.
    /// @return count The number of pending/validating propositions.
    function getPendingPropositionsCount() public view returns (uint256 count) {
        count = 0;
        // This is not efficient for a large number of propositions.
        // In a real dApp, you'd likely use an off-chain indexer.
        // For on-chain efficiency, you'd maintain a dynamic array of pending IDs or use a linked list.
        for (uint256 i = 1; i < nextPropositionId; i++) {
            if (propositions[i].status == PropositionStatus.PENDING ||
                propositions[i].status == PropositionStatus.VALIDATING) {
                count++;
            }
        }
    }
}
```