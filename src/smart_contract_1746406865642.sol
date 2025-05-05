Okay, let's design a concept for a decentralized, community-driven generative storytelling engine. It's a bit abstract for a smart contract to *generate* the story itself, but it can manage the *process* of collaborative creation, validation, and ownership of the narrative segments.

**Concept: Decentralized Autonomous Story Engine (DASE)**

The DASE smart contract facilitates the collaborative creation of a story. Users propose "chapters" (represented by an IPFS hash pointing to the content). The community votes on proposed chapters using a native token. The winning chapter is added to the official story sequence. Contributors and voters are rewarded. The story evolves autonomously based on community consensus via token-weighted voting and timed periods.

This concept is creative (storytelling), advanced (combines staking, voting, dynamic state), and leverages trendy ideas (decentralization, community governance, IPFS for content linking). It's not a standard ERC-20, ERC-721, or simple DAO template.

---

**Outline and Function Summary:**

**Outline:**

1.  **State Management:** Defines the current phase of the story cycle (Proposing, Voting, Idle).
2.  **Core Data Structures:** Stores approved chapters (IPFS hashes), current proposals, and user interactions (stakes, votes).
3.  **Token Interaction:** Uses an external ERC-20 token for staking, voting, and rewards.
4.  **Lifecycle Management:** Functions to transition between states (start/end proposing, start/end voting).
5.  **Proposal Mechanism:** Users submit chapter proposals with a stake.
6.  **Voting Mechanism:** Users vote on proposals using tokens.
7.  **Finalization:** Process voting results, select winner, add chapter, distribute rewards/stakes.
8.  **User Interactions:** Functions for claiming rewards and stakes, querying state.
9.  **Configuration:** Owner/Governance functions to set parameters.
10. **View Functions:** To query the state of the contract and story.

**Function Summary:**

1.  `constructor(address _storyTokenAddress, uint256 _initialProposalDuration, uint256 _initialVotingDuration, uint256 _minimumStakeAmount)`: Initializes the contract with required parameters and the associated ERC-20 story token.
2.  `setProposalPeriodDuration(uint256 _duration)`: Sets the duration for the proposal submission period (owner/governance only).
3.  `setVotingPeriodDuration(uint256 _duration)`: Sets the duration for the voting period (owner/governance only).
4.  `setMinimumStake(uint256 _amount)`: Sets the minimum token stake required to submit a proposal (owner/governance only).
5.  `setWinningRewardPercentage(uint256 _percentage)`: Sets the percentage of the total stake pool awarded to the winning proposer (owner/governance only).
6.  `startProposalPeriod()`: Transitions the state from Idle to Proposing, starts the timer. Can only be called when Idle.
7.  `submitChapterProposal(string memory _ipfsHash)`: Allows users to submit an IPFS hash representing a chapter during the Proposing period, requires minimum token stake via `transferFrom`.
8.  `endProposalPeriod()`: Transitions state from Proposing to Voting, compiles proposals for voting, starts voting timer. Callable after proposal period duration ends.
9.  `startVotingPeriod()`: (Internal) Called by `endProposalPeriod` to set the voting start time and state.
10. `voteForProposal(uint256 _proposalId, uint256 _amount)`: Allows users to vote on a specific proposal during the Voting period, requires token spend via `transferFrom`. Vote weight is proportional to amount spent.
11. `endVotingPeriod()`: Transitions state from Voting to Processing, initiates the finalization process. Callable after voting period duration ends.
12. `finalizeVotingPeriod()`: (Internal/Public triggered) Called by `endVotingPeriod`. Calculates winner, adds winning chapter, distributes rewards and stakes, clears proposals, transitions to Idle. This is the core logic function.
13. `claimStakedTokens(uint256 _proposalId)`: Allows proposers of *non-winning* proposals to claim back their original stake after the voting period is finalized.
14. `claimReward()`: Allows the proposer of the *winning* chapter to claim their stake back plus the calculated reward after finalization.
15. `getChapterCount()`: View function returning the total number of approved chapters in the story.
16. `getChapterHash(uint256 _chapterIndex)`: View function returning the IPFS hash for a specific chapter index.
17. `getProposalDetails(uint256 _proposalId)`: View function returning details about a specific proposal (author, hash, stake, current votes).
18. `getAllCurrentProposalIds()`: View function returning an array of IDs for proposals currently active in the voting round.
19. `getCurrentState()`: View function returning the current state of the contract (Idle, Proposing, Voting, Processing).
20. `getPeriodTimestamps()`: View function returning the start and end timestamps for the current or last active period.
21. `getUserVoteWeight(address _user)`: View function showing the total voting weight a user contributed in the current/last voting round.
22. `getMinimumStake()`: View function returning the current minimum stake requirement for proposals.
23. `getWinningRewardPercentage()`: View function returning the configured reward percentage for the winning proposer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for config, could be replaced with DAO

/**
 * @title DecentralizedAutonomousStoryEngine
 * @dev A smart contract for collaborative story creation managed by token staking and voting.
 * Users propose chapter segments (IPFS hashes), stake tokens, and vote on proposals.
 * The winning proposal is added to the official story sequence, and participants are rewarded.
 */
contract DecentralizedAutonomousStoryEngine is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Outline ---
    // 1. State Management
    // 2. Core Data Structures
    // 3. Token Interaction
    // 4. Lifecycle Management
    // 5. Proposal Mechanism
    // 6. Voting Mechanism
    // 7. Finalization
    // 8. User Interactions
    // 9. Configuration
    // 10. View Functions

    // --- State Management ---
    enum State {
        Idle,        // Ready to start a new cycle
        Proposing,   // Accepting new chapter proposals
        Voting,      // Accepting votes on submitted proposals
        Processing   // Finalizing results, distributing rewards (brief internal state)
    }

    State public currentState;

    uint256 public proposalPeriodStartTime;
    uint256 public proposalPeriodEndTime;
    uint256 public votingPeriodStartTime;
    uint256 public votingPeriodEndTime;

    uint256 public proposalPeriodDuration; // in seconds
    uint256 public votingPeriodDuration;   // in seconds

    // --- Core Data Structures ---
    struct Proposal {
        uint256 id;
        address author;
        string ipfsHash; // IPFS hash pointing to the chapter content
        uint256 stake; // Tokens staked by the author
        uint256 totalVotes; // Total token votes received
        bool finalized; // Flag to indicate if this proposal has been processed
        // Maybe add a mapping for individual voter stakes/votes if needed later
        mapping(address => uint256) votesByAddress; // Track votes per address for this proposal
    }

    Proposal[] public proposals; // Array to store current proposals
    uint256 private nextProposalId = 1;

    string[] public chapters; // Array storing IPFS hashes of approved chapters

    // --- Token Interaction ---
    IERC20 public immutable storyToken; // The ERC-20 token used for staking and voting

    uint256 public minimumStakeAmount; // Minimum tokens required to submit a proposal

    // Reward mechanism:
    // - Winning proposer gets their stake back + a percentage of the total stake pool
    // - Losing proposers can claim their stake back
    uint256 public winningRewardPercentage = 50; // Percentage of total stake pool (0-100)

    // --- User Interactions & Data ---
    // Need to track rewards claimable by users
    mapping(address => uint256) public unclaimedRewards; // Rewards for winning proposers

    // Need to track stakes claimable by users (for losing proposals)
    mapping(uint256 => mapping(address => uint256)) private unclaimedStakes; // proposalId => author => stake

    // --- Events ---
    event StateChanged(State newState);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed author, string ipfsHash, uint256 stake);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 voteAmount);
    event VotingPeriodFinalized(uint256 indexed winningProposalId, string winningIpfsHash, uint256 totalVotesCast);
    event ChapterAdded(uint256 indexed chapterIndex, string ipfsHash);
    event StakeClaimed(uint256 indexed proposalId, address indexed author, uint256 amount);
    event RewardClaimed(address indexed winner, uint256 amount);
    event ConfigUpdated(string paramName, uint256 newValue);

    // --- Modifiers ---
    modifier onlyState(State _state) {
        require(currentState == _state, "DASE: Invalid state");
        _;
    }

    modifier onlyProposingPeriod() {
        require(currentState == State.Proposing, "DASE: Not in proposing period");
        require(block.timestamp >= proposalPeriodStartTime && block.timestamp <= proposalPeriodEndTime, "DASE: Proposing period not active");
        _;
    }

    modifier onlyVotingPeriod() {
        require(currentState == State.Voting, "DASE: Not in voting period");
        require(block.timestamp >= votingPeriodStartTime && block.timestamp <= votingPeriodEndTime, "DASE: Voting period not active");
        _;
    }

    modifier afterPeriodEnd(uint256 _endTime) {
        require(block.timestamp > _endTime, "DASE: Period not ended yet");
        _;
    }

    // --- Functions ---

    /**
     * @dev Constructor to initialize the contract.
     * @param _storyTokenAddress Address of the ERC20 token used for staking and voting.
     * @param _initialProposalDuration Initial duration for the proposal period in seconds.
     * @param _initialVotingDuration Initial duration for the voting period in seconds.
     * @param _minimumStakeAmount Initial minimum token stake for proposals.
     */
    constructor(
        address _storyTokenAddress,
        uint256 _initialProposalDuration,
        uint256 _initialVotingDuration,
        uint256 _minimumStakeAmount
    ) Ownable(msg.sender) {
        storyToken = IERC20(_storyTokenAddress);
        proposalPeriodDuration = _initialProposalDuration;
        votingPeriodDuration = _initialVotingDuration;
        minimumStakeAmount = _minimumStakeAmount;
        currentState = State.Idle;
    }

    // 9. Configuration
    /**
     * @dev Sets the duration for the proposal submission period. Callable by owner.
     * @param _duration The new duration in seconds.
     */
    function setProposalPeriodDuration(uint256 _duration) external onlyOwner {
        proposalPeriodDuration = _duration;
        emit ConfigUpdated("proposalPeriodDuration", _duration);
    }

    /**
     * @dev Sets the duration for the voting period. Callable by owner.
     * @param _duration The new duration in seconds.
     */
    function setVotingPeriodDuration(uint256 _duration) external onlyOwner {
        votingPeriodDuration = _duration;
        emit ConfigUpdated("votingPeriodDuration", _duration);
    }

    /**
     * @dev Sets the minimum token stake required to submit a proposal. Callable by owner.
     * @param _amount The new minimum stake amount.
     */
    function setMinimumStake(uint256 _amount) external onlyOwner {
        minimumStakeAmount = _amount;
        emit ConfigUpdated("minimumStakeAmount", _amount);
    }

    /**
     * @dev Sets the percentage of the total stake pool awarded to the winning proposer. Callable by owner.
     * @param _percentage The new percentage (0-100).
     */
    function setWinningRewardPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "DASE: Percentage cannot exceed 100");
        winningRewardPercentage = _percentage;
        emit ConfigUpdated("winningRewardPercentage", _percentage);
    }

    // 4. Lifecycle Management
    /**
     * @dev Starts the proposal submission period. Can only be called when in Idle state.
     */
    function startProposalPeriod() external onlyState(State.Idle) nonReentrant {
        // Clear previous round's proposals and data
        delete proposals; // Resets the dynamic array
        nextProposalId = 1; // Reset proposal ID counter

        currentState = State.Proposing;
        proposalPeriodStartTime = block.timestamp;
        proposalPeriodEndTime = block.timestamp + proposalPeriodDuration;
        emit StateChanged(currentState);
    }

    // 5. Proposal Mechanism
    /**
     * @dev Allows a user to submit a chapter proposal. Requires minimum stake.
     * @param _ipfsHash IPFS hash pointing to the chapter content.
     */
    function submitChapterProposal(string memory _ipfsHash) external payable onlyProposingPeriod nonReentrant {
        require(bytes(_ipfsHash).length > 0, "DASE: IPFS hash cannot be empty");
        require(storyToken.balanceOf(msg.sender) >= minimumStakeAmount, "DASE: Insufficient token balance for stake");
        // require(storyToken.allowance(msg.sender, address(this)) >= minimumStakeAmount, "DASE: Approve tokens for staking"); // This check is typically done off-chain before calling

        // Transfer stake from user
        storyToken.safeTransferFrom(msg.sender, address(this), minimumStakeAmount);

        proposals.push(Proposal({
            id: nextProposalId,
            author: msg.sender,
            ipfsHash: _ipfsHash,
            stake: minimumStakeAmount,
            totalVotes: 0,
            finalized: false // Not yet finalized
        }));

        emit ProposalSubmitted(nextProposalId, msg.sender, _ipfsHash, minimumStakeAmount);
        nextProposalId++;
    }

    /**
     * @dev Ends the proposal period and transitions to the voting period.
     * Can only be called when in Proposing state and the duration has passed.
     */
    function endProposalPeriod() external onlyState(State.Proposing) afterPeriodEnd(proposalPeriodEndTime) nonReentrant {
         // Optionally add a minimum number of proposals check here

        currentState = State.Voting;
        votingPeriodStartTime = block.timestamp;
        votingPeriodEndTime = block.timestamp + votingPeriodDuration;
        emit StateChanged(currentState);
    }

    // 6. Voting Mechanism
    /**
     * @dev Allows a user to vote for a specific proposal. Vote weight is token amount.
     * Requires tokens to be transferred from the voter.
     * @param _proposalId The ID of the proposal to vote for.
     * @param _amount The amount of tokens to use for voting.
     */
    function voteForProposal(uint256 _proposalId, uint256 _amount) external payable onlyVotingPeriod nonReentrant {
        require(_amount > 0, "DASE: Vote amount must be greater than zero");
        require(_proposalId > 0 && _proposalId < nextProposalId, "DASE: Invalid proposal ID");

        // Find the proposal by ID (need to iterate as proposals is an array)
        uint256 proposalIndex = type(uint256).max;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _proposalId) {
                proposalIndex = i;
                break;
            }
        }
        require(proposalIndex != type(uint256).max, "DASE: Proposal not found in current round");
        require(!proposals[proposalIndex].finalized, "DASE: Cannot vote on a finalized proposal"); // Should not happen in Voting state, but safety check

        require(storyToken.balanceOf(msg.sender) >= _amount, "DASE: Insufficient token balance for vote");
        // require(storyToken.allowance(msg.sender, address(this)) >= _amount, "DASE: Approve tokens for voting"); // Again, off-chain check is standard

        // Transfer tokens from user as votes
        storyToken.safeTransferFrom(msg.sender, address(this), _amount);

        proposals[proposalIndex].totalVotes += _amount;
        proposals[proposalIndex].votesByAddress[msg.sender] += _amount; // Track user's total vote weight in this round

        emit VoteCast(_proposalId, msg.sender, _amount);
    }

    /**
     * @dev Ends the voting period and triggers finalization.
     * Can only be called when in Voting state and the duration has passed.
     */
    function endVotingPeriod() external onlyState(State.Voting) afterPeriodEnd(votingPeriodEndTime) nonReentrant {
        currentState = State.Processing; // Enter processing state temporarily
        emit StateChanged(currentState);
        finalizeVotingPeriod(); // Immediately trigger finalization
    }

    // 7. Finalization
    /**
     * @dev Finalizes the voting period, determines the winning proposal,
     * adds the chapter, and distributes stakes/rewards.
     * Called internally by `endVotingPeriod`.
     */
    function finalizeVotingPeriod() internal nonReentrant {
        require(currentState == State.Processing, "DASE: Not in processing state");

        uint256 winningProposalId = 0;
        string memory winningIpfsHash = "";
        uint256 maxVotes = 0;
        uint256 winningProposalIndex = type(uint256).max;
        uint256 totalStakePool = 0; // Sum of all stakes

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].totalVotes > maxVotes) {
                maxVotes = proposals[i].totalVotes;
                winningProposalId = proposals[i].id;
                winningIpfsHash = proposals[i].ipfsHash;
                winningProposalIndex = i;
            }
            // Sum up all stakes for the reward calculation
            totalStakePool += proposals[i].stake;

            // Mark proposal as finalized to prevent further interaction
            proposals[i].finalized = true;
        }

        // Handle case with no proposals or no votes
        if (winningProposalId == 0 || maxVotes == 0) {
             // Return all stakes if no winner or no votes
            for (uint i = 0; i < proposals.length; i++) {
                 if(proposals[i].stake > 0) {
                     unclaimedStakes[proposals[i].id][proposals[i].author] = proposals[i].stake;
                 }
            }
            // No chapter added, transition back to Idle
            currentState = State.Idle;
            emit VotingPeriodFinalized(0, "", 0);
            emit StateChanged(currentState);
            return;
        }

        // Add winning chapter to the story
        chapters.push(winningIpfsHash);
        emit ChapterAdded(chapters.length - 1, winningIpfsHash);

        emit VotingPeriodFinalized(winningProposalId, winningIpfsHash, maxVotes);

        // Distribute rewards and return stakes
        uint256 rewardAmount = (totalStakePool * winningRewardPercentage) / 100;
        uint256 remainingStakePool = totalStakePool - rewardAmount; // This pool goes back to losing proposers

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == winningProposalId) {
                // Winner claims stake + reward
                unclaimedRewards[proposals[i].author] += proposals[i].stake + rewardAmount;
            } else {
                // Losers claim their stake back
                if(proposals[i].stake > 0) {
                    unclaimedStakes[proposals[i].id][proposals[i].author] = proposals[i].stake;
                }
            }
             // Votes (tokens spent on voting) are burned or sent to a treasury/DAO?
             // Let's assume votes are spent (burned) for simplicity in this version.
             // A more advanced version could send vote tokens to a treasury or liquidity pool.
             // The tokens spent for voting are implicitly "burned" from the perspective
             // of the contract's balance if they aren't explicitly sent elsewhere.
             // In SafeERC20 they are transferred to 'this', so they stay here unless moved.
             // For this version, they remain in the contract. A future version could manage them.
        }

        // Transition to Idle state, ready for the next round
        currentState = State.Idle;
        emit StateChanged(currentState);

        // Note: proposals array is not cleared here, but flagged finalized.
        // It is cleared at the start of the *next* proposing period.
    }

    // 8. User Interactions
    /**
     * @dev Allows a user to claim their stake back if their proposal did not win.
     * @param _proposalId The ID of the proposal the user authored.
     */
    function claimStakedTokens(uint256 _proposalId) external nonReentrant {
        require(_proposalId > 0 && _proposalId < nextProposalId, "DASE: Invalid proposal ID");

        // Find the proposal to verify sender is the author
        uint256 proposalIndex = type(uint256).max;
         for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _proposalId) {
                proposalIndex = i;
                break;
            }
        }
        require(proposalIndex != type(uint256).max, "DASE: Proposal not found");
        require(proposals[proposalIndex].author == msg.sender, "DASE: Not the author of this proposal");
        require(proposals[proposalIndex].finalized, "DASE: Proposal not yet finalized"); // Only claim after finalization
        // Ensure it wasn't the winning proposal
        require(chapters.length == 0 || !bytes(chapters[chapters.length-1]).equals(bytes(proposals[proposalIndex].ipfsHash)), "DASE: This was the winning proposal, claim reward instead");


        uint256 amount = unclaimedStakes[_proposalId][msg.sender];
        require(amount > 0, "DASE: No unclaimed stake for this proposal");

        unclaimedStakes[_proposalId][msg.sender] = 0; // Reset claimable amount

        storyToken.safeTransfer(msg.sender, amount);
        emit StakeClaimed(_proposalId, msg.sender, amount);
    }

    /**
     * @dev Allows the author of the winning proposal to claim their stake plus reward.
     */
    function claimReward() external nonReentrant {
        uint256 amount = unclaimedRewards[msg.sender];
        require(amount > 0, "DASE: No unclaimed rewards");

        unclaimedRewards[msg.sender] = 0; // Reset claimable amount

        storyToken.safeTransfer(msg.sender, amount);
        emit RewardClaimed(msg.sender, amount);
    }


    // 10. View Functions
    /**
     * @dev Returns the total number of approved chapters in the story.
     */
    function getChapterCount() external view returns (uint256) {
        return chapters.length;
    }

    /**
     * @dev Returns the IPFS hash for a specific chapter index.
     * @param _chapterIndex The index of the chapter (0-based).
     */
    function getChapterHash(uint256 _chapterIndex) external view returns (string memory) {
        require(_chapterIndex < chapters.length, "DASE: Invalid chapter index");
        return chapters[_chapterIndex];
    }

    /**
     * @dev Returns details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (uint256 id, address author, string memory ipfsHash, uint256 stake, uint256 totalVotes, bool finalized) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "DASE: Invalid proposal ID");

        // Find the proposal - inefficient for many proposals, but simple for demo
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _proposalId) {
                return (proposals[i].id, proposals[i].author, proposals[i].ipfsHash, proposals[i].stake, proposals[i].totalVotes, proposals[i].finalized);
            }
        }
        revert("DASE: Proposal not found"); // Should not be reachable if ID check passes, but safety
    }

     /**
      * @dev Returns details for a proposal given its index in the *current* proposals array.
      * Note: This index is temporary and only valid during Proposing/Voting states before clearing.
      * @param _index The index in the current `proposals` array.
      */
    function getProposalDetailsByIndex(uint256 _index) external view returns (uint256 id, address author, string memory ipfsHash, uint256 stake, uint256 totalVotes, bool finalized) {
        require(_index < proposals.length, "DASE: Invalid proposal index");
        return (proposals[_index].id, proposals[_index].author, proposals[_index].ipfsHash, proposals[_index].stake, proposals[_index].totalVotes, proposals[_index].finalized);
    }

    /**
     * @dev Returns an array of IDs for proposals currently active in the voting round.
     * Note: This list is only relevant during Voting state. After finalization, the array is cleared for the next round.
     * To see details after finalization, use `getProposalDetails` with the ID.
     */
    function getAllCurrentProposalIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](proposals.length);
        for (uint i = 0; i < proposals.length; i++) {
            ids[i] = proposals[i].id;
        }
        return ids;
    }

    /**
     * @dev Returns the current state of the contract.
     */
    function getCurrentState() external view returns (State) {
        return currentState;
    }

    /**
     * @dev Returns the start and end timestamps for the current or last active period.
     * Useful for UIs to show remaining time.
     */
    function getPeriodTimestamps() external view returns (uint256 propStartTime, uint256 propEndTime, uint256 voteStartTime, uint256 voteEndTime) {
        return (proposalPeriodStartTime, proposalPeriodEndTime, votingPeriodStartTime, votingPeriodEndTime);
    }

     /**
      * @dev Returns the total vote weight contributed by a user in the current/last voting round.
      * Requires iterating through proposals, potentially inefficient.
      * A dedicated mapping `userTotalVotesInRound[address]` could be added for efficiency.
      * This version iterates for simplicity.
      * @param _user The address of the user.
      */
     function getUserVoteWeight(address _user) external view returns (uint256) {
        uint256 totalWeight = 0;
         for (uint i = 0; i < proposals.length; i++) {
            // Check votesByAddress for this user across all proposals in the array
             totalWeight += proposals[i].votesByAddress[_user];
         }
         return totalWeight;
     }

     /**
      * @dev Returns the minimum stake amount required for proposal submission.
      */
     function getMinimumStake() external view returns (uint256) {
         return minimumStakeAmount;
     }

     /**
      * @dev Returns the configured winning reward percentage.
      */
     function getWinningRewardPercentage() external view returns (uint256) {
         return winningRewardPercentage;
     }

    /**
     * @dev Returns the unclaimed stake amount for a specific proposal and author.
     * @param _proposalId The ID of the proposal.
     * @param _author The address of the proposal author.
     */
    function getUnclaimedStake(uint256 _proposalId, address _author) external view returns (uint256) {
        return unclaimedStakes[_proposalId][_author];
    }

    /**
     * @dev Returns the total unclaimed rewards for a specific address (winning proposer rewards).
     * @param _user The address to check.
     */
    function getUnclaimedRewards(address _user) external view returns (uint256) {
        return unclaimedRewards[_user];
    }
}
```

**Explanation of Key Concepts and Advanced Aspects:**

1.  **Dynamic State Machine:** The `State` enum and corresponding transitions (`startProposalPeriod`, `endProposalPeriod`, `endVotingPeriod`, `finalizeVotingPeriod`) create a clear, time-based lifecycle for each story chapter's creation. This is more structured than a simple multi-sig or basic voting.
2.  **Token-Weighted Staking & Voting:**
    *   **Staking:** Users *must* stake a minimum amount of the `storyToken` to propose. This adds a cost to proposing, mitigating spam and giving value to the proposals.
    *   **Voting:** Voting power is directly proportional to the amount of `storyToken` a user is willing to spend (transfer) for a specific proposal. This makes the token the primary governance mechanism.
3.  **Incentivized Contribution:**
    *   The winning proposer gets their stake returned PLUS a percentage of the *total stake pool* from *all* proposals in that round. This heavily incentivizes proposing quality content that wins votes.
    *   Losing proposers get their stake returned.
    *   Voters' tokens are spent. A more advanced version could distribute a fraction of these to winning voters or a community treasury, but burning or retaining in the contract is simpler.
4.  **IPFS for Content:** The contract doesn't store the potentially large chapter text. It stores immutable IPFS hashes. This is standard practice for linking on-chain contracts to off-chain data like images (NFTs) or, in this case, narrative content, keeping gas costs down.
5.  **Autonomous Progression:** Once periods end, specific functions (`endProposalPeriod`, `endVotingPeriod`) need to be called (either by anyone or a trusted oracle/bot) to push the state forward. The `finalizeVotingPeriod` logic runs automatically upon `endVotingPeriod`, performing the core consensus mechanism and state update autonomously based on the recorded votes.
6.  **Modular Design:** Uses OpenZeppelin contracts (`IERC20`, `SafeERC20`, `ReentrancyGuard`, `Ownable`) for standard patterns and safety. `Ownable` is used for configuration, but this could easily be replaced by a more decentralized DAO governance mechanism in a production version.
7.  **Non-Duplicate Nature:** While it uses standard components (ERC20, IPFS linking), the *application* to a collaborative, evolving story managed by staking and timed voting periods is a creative use case not commonly found in generic open-source contract templates like standard DAOs or NFT factories. The combination of proposal staking, vote spending, and reward distribution based on winning a narrative consensus round is unique.

This contract provides a framework for a community to collectively write a story, with economic incentives and token governance driving the narrative's evolution.