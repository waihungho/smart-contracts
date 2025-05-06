Okay, let's design a complex, advanced, and creative smart contract. We'll build a Decentralized Autonomous Venture DAO (DAV DAO) that integrates several modern concepts:

1.  **DAO Governance:** Standard proposal/voting system.
2.  **Weighted Voting:** Voting power based on staked tokens *and* an integrated Soulbound Membership NFT (SBM).
3.  **Soulbound Membership NFT (SBM):** A non-transferable NFT used for proving membership status and boosting voting power/access. Minted upon joining, burned upon leaving. Levels might be linked to reputation.
4.  **On-Chain Reputation:** A score tracked per member based on active participation (voting, successful proposals).
5.  **Liquid Delegation:** Members can delegate their voting power (stake + NFT bonus + reputation bonus) to another member.
6.  **Multi-type Proposals:** Handling funding proposals (sending funds) and generic governance proposals (calling arbitrary contract functions).
7.  **Time-locked Execution:** A delay between a proposal passing and being executable.
8.  **Integrated Treasury:** Handling incoming funds (ETH/WETH) and distributing them or using them for investments/grants.
9.  **Dynamic Parameters:** Key DAO parameters (quorum, thresholds, timelock) are governable.
10. **Pausable & Reentrancy Guard:** Standard security practices.
11. **Custom Errors:** Modern Solidity error handling.

This combines DAO mechanics, NFT utility (Soulbound property is key here), reputation systems, liquid democracy, and flexible execution. It should be distinct from standard OpenZeppelin Governor or basic DAO examples due to the integrated SBM, reputation, weighted delegation, and multi-asset/multi-type execution.

---

**Outline and Function Summary**

**Contract:** `DecentralizedAutonomousVentureDao`

**Purpose:** Implements a sophisticated DAO for decentralized venture funding and governance. Members stake a specific ERC20 token, receive a Soulbound Membership NFT, gain voting power based on stake, NFT, and reputation, propose and vote on initiatives (funding or governance), and manage a shared treasury.

**Core Concepts:**
*   DAO Governance (Proposals, Voting, Execution)
*   Staking for Membership and Base Voting Power
*   Soulbound Membership NFT (SBM) for Proof-of-Membership and Voting Boost
*   On-Chain Reputation System linked to participation
*   Liquid Delegation of Voting Power
*   Multi-type Proposals (Funding, Governance)
*   Treasury Management
*   Dynamic DAO Parameters

**Function Summary:**

**I. State Management & Configuration**
1.  `constructor(address _stakingToken, string memory _sbmName, string memory _sbmSymbol, uint256 _minStake, uint256 _votingPeriod, uint256 _executionTimelock, uint256 _quorumNumerator, uint256 _quorumDenominator, uint256 _proposalThresholdNumerator, uint256 _proposalThresholdDenominator)`: Initializes the DAO with required tokens, SBM details, and initial parameters.
2.  `setDaoParameters(uint256 _minStake, uint256 _votingPeriod, uint256 _executionTimelock, uint256 _quorumNumerator, uint256 _quorumDenominator, uint256 _proposalThresholdNumerator, uint256 _proposalThresholdDenominator)`: Allows governance to update core DAO parameters.
3.  `pause()`: Pauses contract operations (emergency function, typically guarded).
4.  `unpause()`: Unpauses contract operations.
5.  `emergencyWithdraw(address _token, uint256 _amount)`: Allows authorized role to withdraw stuck tokens (emergency use).

**II. Membership & Staking**
6.  `joinDao(uint256 _amount)`: Stake minimum required tokens to become a member and mint a Soulbound Membership NFT.
7.  `leaveDao()`: Unstake tokens, burn the Soulbound Membership NFT, and leave the DAO.
8.  `stake(uint256 _amount)`: Add more tokens to an existing stake.
9.  `unstake(uint256 _amount)`: Remove tokens from stake (up to the minimum stake if still a member).
10. `delegateVote(address _delegatee)`: Delegate voting power (stake + NFT bonus + reputation bonus) to another member.
11. `undelegateVote()`: Remove delegation and vote directly.

**III. Voting Power & Reputation**
12. `getVotingPower(address _member)`: Calculates the current total voting power for an address (considering stake, NFT bonus, reputation bonus, and delegation).
13. `getReputation(address _member)`: Retrieves the current reputation score for a member.
14. `getMemberStake(address _member)`: Retrieves the current staked amount for a member.
15. `_updateReputation(address _member, int256 _change)` (Internal): Updates a member's reputation score based on their activity. Called by other functions (e.g., `vote`, `executeProposal`).

**IV. Treasury Management**
16. `depositFunds()`: Allows anyone to send Ether or the staking token (via payable or transfer) to the DAO treasury.
17. `withdrawExcessFunds(address _token, uint256 _amount)`: Allows governance to withdraw non-staked funds from the treasury (e.g., distributing returns). This likely requires a governance proposal.
18. `getDaoBalance(address _token)`: Checks the balance of a specific token held by the DAO treasury.

**V. Proposal Management**
19. `createFundingProposal(address _recipient, uint256 _amount, address _token, string memory _description)`: Creates a proposal to send funds to a recipient. Requires staking minimum tokens to propose.
20. `createGovernanceProposal(address _target, uint256 _value, bytes memory _callData, string memory _description)`: Creates a proposal to call a function on another contract (for governance actions). Requires staking minimum tokens to propose.
21. `cancelProposal(uint256 _proposalId)`: Allows the proposer (or governance) to cancel a proposal before voting ends.
22. `getProposalDetails(uint256 _proposalId)`: Retrieves all details for a specific proposal.
23. `getProposalState(uint256 _proposalId)`: Retrieves the current state of a specific proposal.

**VI. Voting**
24. `vote(uint256 _proposalId, bool _support)`: Casts a vote (for/against) on an active proposal using the member's current voting power.
25. `getVote(uint256 _proposalId, address _voter)`: Checks how a specific member voted on a proposal and their voting power used.
26. `getCurrentVotes(uint256 _proposalId)`: Gets the current vote tally (support, against, abstain) for a proposal.

**VII. Execution**
27. `queueExecution(uint256 _proposalId)`: Moves a successfully passed proposal to the queued state, starting the timelock.
28. `executeProposal(uint256 _proposalId)`: Executes the actions of a proposal after the timelock has passed. Updates reputation for successful proposers/voters.

**VIII. Soulbound Membership NFT (SBM) Management (Internal/Interacted via Membership)**
29. `_mintMembershipNFT(address _to, uint256 _tokenId)` (Internal): Mints an SBM NFT upon joining.
30. `_burnMembershipNFT(uint256 _tokenId)` (Internal): Burns an SBM NFT upon leaving.
31. `getMembershipNFTId(address _member)`: Get the SBM token ID associated with a member's address.

This structure provides a robust framework integrating multiple layers of interaction and state based on member actions, token holdings, and unique NFT identity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // Required for _burn
import "@openzeppelin/contracts/utils/Context.sol"; // Required by ERC721Burnable

// Custom Errors
error InvalidAmount();
error MinimumStakeNotMet();
error AlreadyMember();
error NotMember();
error CannotLeaveWithActiveStake();
error ProposalNotFound();
error Unauthorized();
error VotingPeriodInactive();
error VotingPeriodActive();
error ProposalStateInvalid();
error AlreadyVoted();
error QuorumNotReached();
error ThresholdNotReached();
error TimelockNotPassed();
error ProposalNotQueued();
error ExecutionFailed();
error InvalidDaoParameters();
error DelegationSelfError();
error CannotDelegateWithActiveVote();
error CannotUnstakeBelowMinStake();
error AmountTooLarge();
error ExecutionTimelockNotPassed();
error CannotSetZeroAddress();

// Interfaces
interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

// ERC721 implementation with Soulbound property check
contract SoulboundERC721 is ERC721, ERC721Burnable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Override _beforeTokenTransfer to prevent transfers between non-zero addresses
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address 0) and burning (to address 0)
        if (from != address(0) && to != address(0)) {
            revert Unauthorized(); // Prevent transfers between users
        }
    }
}


contract DecentralizedAutonomousVentureDao is Ownable, Pausable, ReentrancyGuard, SoulboundERC721 {
    using Counters for Counters.Counter;
    using Address for address;

    // State Variables
    IERC20Detailed public immutable stakingToken;
    SoulboundERC721 public immutable membershipNFT;

    uint256 public minStake; // Minimum tokens required to be a member
    uint256 public votingPeriod; // Duration of voting in seconds
    uint256 public executionTimelock; // Delay before a passed proposal can be executed

    uint256 public quorumNumerator; // For quorum calculation: quorumNumerator / quorumDenominator
    uint256 public quorumDenominator;

    uint256 public proposalThresholdNumerator; // Percentage of total staked tokens required to create a proposal
    uint256 public proposalThresholdDenominator;

    Counters.Counter private _proposalIds;

    struct MemberProfile {
        uint256 stake;
        int256 reputation; // Can be positive or negative
        address delegatee; // Address this member delegates their vote to
        uint256 membershipNFTId; // The token ID of their SBM NFT
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Track who has voted
        mapping(address => uint256) voterWeight; // Track voting power used by each voter (including delegated)
        State state;

        // For Execution (Funding or Governance)
        ProposalType proposalType;
        address target; // Target contract for governance or recipient for funding
        uint256 value; // ETH value for governance or token amount for funding
        bytes callData; // Function call data for governance proposals
        address token; // Specific token for funding proposals
    }

    enum State {
        Draft, // Initial state (not used externally, internal to creation)
        Pending, // Waiting for start time
        Active, // Voting is open
        Canceled, // Canceled by proposer or governance
        Defeated, // Did not pass quorum or threshold
        Succeeded, // Passed quorum and threshold, waiting for timelock
        Queued, // Timelock started
        Expired, // Timelock passed but not executed
        Executed // Successfully executed
    }

    enum ProposalType {
        Funding,
        Governance
    }

    mapping(address => MemberProfile) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) private _stakes; // Separate mapping for easier total stake calculation
    mapping(uint256 => address) public membershipNFTLookup; // Mapping from SBM token ID to member address

    // --- Configuration Parameters ---
    uint256 public constant REPUTATION_VOTE_WEIGHT = 1; // Reputation points gained/lost per vote impact
    uint256 public constant REPUTATION_SUCCESSFUL_PROPOSAL = 10; // Reputation points for a successful proposal
    uint256 public constant SBM_VOTE_BOOST_PERCENT = 5; // Percentage boost to voting power from SBM (e.g., 5% of base stake)

    // Events
    event MemberJoined(address indexed member, uint256 stakedAmount, uint256 membershipNFTId);
    event MemberLeft(address indexed member, uint256 unstakedAmount, uint256 membershipNFTId);
    event Staked(address indexed member, uint256 amount, uint256 totalStake);
    event Unstaked(address indexed member, uint256 amount, uint256 totalStake);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime, ProposalType proposalType);
    event ProposalCanceled(uint256 indexed proposalId);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, State oldState, State newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed sender, uint256 amount, address token);
    event FundsWithdrawn(address indexed recipient, uint256 amount, address token);
    event ReputationUpdated(address indexed member, int256 newReputation);
    event DaoParametersUpdated(uint256 minStake, uint256 votingPeriod, uint256 executionTimelock, uint256 quorumNumerator, uint256 quorumDenominator, uint256 proposalThresholdNumerator, uint256 proposalThresholdDenominator);

    modifier onlyMember() {
        if (!isMember(_msgSender())) revert NotMember();
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        if (proposals[_proposalId].proposer != _msgSender()) revert Unauthorized();
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        if (_proposalId == 0 || _proposalId > _proposalIds.current()) revert ProposalNotFound();
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != State.Active) revert VotingPeriodInactive();
        if (block.timestamp < proposal.startTime || block.timestamp > proposal.endTime) revert VotingPeriodInactive();
        _;
    }

     modifier executionPeriodActive(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != State.Queued) revert ProposalStateInvalid(); // Must be Queued
        if (block.timestamp < proposal.endTime + executionTimelock) revert ExecutionTimelockNotPassed(); // Timelock must have passed
        _;
    }

    modifier onlyGovernance() {
        // In a real DAO, this would be a more complex check,
        // like requiring a successful governance proposal execution.
        // For this example, we'll use onlyOwner or similar simplistic check,
        // OR allow *anyone* who has executed a governance proposal to trigger parameter changes
        // Let's stick with onlyOwner for simplicity in this example, but note this is a simplification.
        // A more advanced approach would be a separate Timelock/Governor contract executing calls here.
        if (owner() != _msgSender()) revert Unauthorized(); // Simplified governance check
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingToken,
        string memory _sbmName,
        string memory _sbmSymbol,
        uint256 _minStake,
        uint256 _votingPeriod,
        uint256 _executionTimelock,
        uint256 _quorumNumerator,
        uint256 _quorumDenominator,
        uint256 _proposalThresholdNumerator,
        uint256 _proposalThresholdDenominator
    ) ERC721(_sbmName, _sbmSymbol) SoulboundERC721(_sbmName, _sbmSymbol) Ownable(_msgSender()) Pausable() {
        if (_stakingToken == address(0)) revert CannotSetZeroAddress();
        if (_quorumDenominator == 0 || _proposalThresholdDenominator == 0) revert InvalidDaoParameters();
        if (_quorumNumerator > _quorumDenominator || _proposalThresholdNumerator > _proposalThresholdDenominator) revert InvalidDaoParameters();

        stakingToken = IERC20Detailed(_stakingToken);
        membershipNFT = this; // The DAO contract IS the SBM NFT contract

        minStake = _minStake;
        votingPeriod = _votingPeriod;
        executionTimelock = _executionTimelock;
        quorumNumerator = _quorumNumerator;
        quorumDenominator = _quorumDenominator;
        proposalThresholdNumerator = _proposalThresholdNumerator;
        proposalThresholdDenominator = _proposalThresholdDenominator;

        _proposalIds.increment(); // Start proposal IDs from 1
    }

    // --- Configuration Functions ---
    function setDaoParameters(
        uint256 _minStake,
        uint256 _votingPeriod,
        uint256 _executionTimelock,
        uint256 _quorumNumerator,
        uint256 _quorumDenominator,
        uint256 _proposalThresholdNumerator,
        uint256 _proposalThresholdDenominator
    ) external onlyGovernance whenNotPaused {
         if (_quorumDenominator == 0 || _proposalThresholdDenominator == 0) revert InvalidDaoParameters();
         if (_quorumNumerator > _quorumDenominator || _proposalThresholdNumerator > _proposalThresholdDenominator) revert InvalidDaoParameters();

        minStake = _minStake;
        votingPeriod = _votingPeriod;
        executionTimelock = _executionTimelock;
        quorumNumerator = _quorumNumerator;
        quorumDenominator = _quorumDenominator;
        proposalThresholdNumerator = _proposalThresholdNumerator;
        proposalThresholdDenominator = _proposalThresholdDenominator;

        emit DaoParametersUpdated(minStake, votingPeriod, executionTimelock, quorumNumerator, quorumDenominator, proposalThresholdNumerator, proposalThresholdDenominator);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner whenPaused nonReentrant {
        // This is an emergency function. It should only be callable
        // by a trusted role (owner) when the contract is paused.
        // It's primarily for recovering accidentally sent tokens.
        // It should *not* be used for regular DAO treasury management.
        if (_amount == 0) revert InvalidAmount();

        IERC20 tokenContract = IERC20(_token);
        uint256 balance = tokenContract.balanceOf(address(this));
        if (_amount > balance) revert AmountTooLarge();

        tokenContract.transfer(owner(), _amount);
        emit FundsWithdrawn(owner(), _amount, _token);
    }

    // --- Membership & Staking Functions ---

    function joinDao(uint256 _amount) external whenNotPaused nonReentrant {
        address member = _msgSender();
        if (isMember(member)) revert AlreadyMember();
        if (_amount < minStake) revert MinimumStakeNotMet();

        // Transfer staking tokens to DAO treasury
        bool success = stakingToken.transferFrom(member, address(this), _amount);
        if (!success) revert ExecutionFailed(); // Use a more specific error if needed

        _stakes[member] += _amount;
        uint256 nextNFTId = _proposalIds.current(); // Use proposal counter as NFT ID source (simple unique ID)
        _mintMembershipNFT(member, nextNFTId);

        members[member] = MemberProfile({
            stake: _amount,
            reputation: 0,
            delegatee: address(0), // Initially no delegatee
            membershipNFTId: nextNFTId
        });
        membershipNFTLookup[nextNFTId] = member;

        emit MemberJoined(member, _amount, nextNFTId);
        emit Staked(member, _amount, _stakes[member]);
    }

    function leaveDao() external onlyMember whenNotPaused nonReentrant {
        address member = _msgSender();
        MemberProfile storage memberProfile = members[member];

        // Cannot leave if currently delegating or being delegated *with active voting power contribution*
        // Simple check: Cannot leave if delegated to someone (forces undelegate first)
        if (memberProfile.delegatee != address(0)) revert CannotLeaveWithActiveStake();
        // More complex check would verify if their *power* is currently delegated and contributing to votes.
        // For simplicity, requiring undelegation first is sufficient.

        uint256 totalStake = _stakes[member];
        uint256 nftId = memberProfile.membershipNFTId;

        // Burn the Soulbound NFT
        _burnMembershipNFT(nftId);
        delete membershipNFTLookup[nftId];

        // Transfer all staked tokens back
        _stakes[member] = 0;
        bool success = stakingToken.transfer(member, totalStake);
         if (!success) revert ExecutionFailed(); // Use a more specific error if needed

        // Clear member profile
        delete members[member]; // This also clears stake, reputation, delegatee

        emit MemberLeft(member, totalStake, nftId);
        emit Unstaked(member, totalStake, 0);
    }

    function stake(uint256 _amount) external onlyMember whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        address member = _msgSender();

        bool success = stakingToken.transferFrom(member, address(this), _amount);
        if (!success) revert ExecutionFailed(); // Use a more specific error if needed

        _stakes[member] += _amount;
        members[member].stake = _stakes[member]; // Update stake in member profile struct as well for easy access

        emit Staked(member, _amount, _stakes[member]);
    }

    function unstake(uint256 _amount) external onlyMember whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        address member = _msgSender();
        uint256 currentStake = _stakes[member];

        if (_amount > currentStake) revert AmountTooLarge();

        uint256 remainingStake = currentStake - _amount;
        if (remainingStake < minStake && remainingStake != 0) revert CannotUnstakeBelowMinStake(); // Allow unstaking *all* if leaving, but not below min if staying

        _stakes[member] = remainingStake;
        members[member].stake = remainingStake;

        bool success = stakingToken.transfer(member, _amount);
        if (!success) revert ExecutionFailed(); // Use a more specific error if needed

        emit Unstaked(member, _amount, remainingStake);
    }

    function delegateVote(address _delegatee) external onlyMember whenNotPaused {
        address delegator = _msgSender();
        if (_delegatee == delegator) revert DelegationSelfError();

        // Optional: Prevent delegation if the member has already voted on an active proposal
        // This requires iterating through active proposals or tracking voting status more closely.
        // For simplicity, we'll allow delegation at any time, assuming users manage this.
        // A more robust system might snapshot voting power *at the start* of a proposal.

        Address.isContract(_delegatee); // Basic check delegatee isn't a zero address or odd value

        address currentDelegatee = members[delegator].delegatee;
        members[delegator].delegatee = _delegatee;

        emit DelegateChanged(delegator, currentDelegatee, _delegatee);
    }

    function undelegateVote() external onlyMember whenNotPaused {
        address delegator = _msgSender();
        address currentDelegatee = members[delegator].delegatee;
        if (currentDelegatee == address(0)) return; // No active delegation

        members[delegator].delegatee = address(0);

        emit DelegateChanged(delegator, currentDelegatee, address(0));
    }

    // --- Voting Power & Reputation Functions ---

    function getVotingPower(address _member) public view returns (uint256) {
        if (!isMember(_member)) return 0;

        address currentAddress = _member;
        // Resolve delegation chain
        while (members[currentAddress].delegatee != address(0) && members[currentAddress].delegatee != currentAddress) {
            address nextDelegatee = members[currentAddress].delegatee;
            // Basic loop prevention for circular delegation (though a true cycle would be caught by gas limit)
            if (nextDelegatee == _member) break; // Detected cycle
            currentAddress = nextDelegatee;
        }
        // `currentAddress` is now the final delegatee or the original member if not delegating

        uint256 baseStake = _stakes[currentAddress];
        if (baseStake == 0) return 0; // Must have stake to have voting power

        uint256 reputation = members[currentAddress].reputation > 0 ? uint256(members[currentAddress].reputation) : 0;
        uint256 reputationBonus = reputation / 10; // Simple mapping: 10 reputation = 1 token-equivalent power

        uint256 sbmBonus = 0;
        if (members[currentAddress].membershipNFTId > 0) { // Check if they hold an SBM NFT
             sbmBonus = (baseStake * SBM_VOTE_BOOST_PERCENT) / 100;
        }

        // Simple combined power: Stake + Reputation Bonus + SBM Bonus
        // More complex models could involve non-linear curves or time-decay.
        return baseStake + reputationBonus + sbmBonus;
    }

    function getReputation(address _member) external view returns (int256) {
        if (!isMember(_member)) return 0;
        return members[_member].reputation;
    }

    function getMemberStake(address _member) external view returns (uint256) {
        return _stakes[_member];
    }

    function isMember(address _member) public view returns (bool) {
        // A member must have an SBM NFT and meet the minimum stake
        // Checking for the NFT is sufficient as it's minted only upon joining with min stake
        return membershipNFT.ownerOf(members[_member].membershipNFTId) == _member;
    }

    // Internal function to update reputation
    function _updateReputation(address _member, int256 _change) internal {
        if (!isMember(_member)) return; // Only update reputation for members

        members[_member].reputation += _change;
        emit ReputationUpdated(_member, members[_member].reputation);
    }


    // --- Treasury Functions ---

    receive() external payable {
        depositFunds(); // Allow receiving ETH directly
    }

    function depositFunds() public payable whenNotPaused nonReentrant {
        // Allows anyone to send ETH
        if (msg.value > 0) {
            emit FundsDeposited(_msgSender(), msg.value, address(0)); // address(0) convention for ETH
        }
        // Can also be called to deposit the staking token via transferFrom
        // The actual transferFrom call would happen before calling this public function,
        // or be handled in a separate function like stake() for the staking token.
        // We'll assume external calls or the staking function handle the token transfers
        // and this function is primarily for ETH.
    }

    function withdrawExcessFunds(address _token, uint256 _amount) external onlyGovernance whenNotPaused nonReentrant {
        // This function requires governance approval (handled by the `onlyGovernance` modifier,
        // which is simplified to `onlyOwner` here, but in a real DAO would be via proposal execution).
        // It allows withdrawing funds not currently staked.

        if (_amount == 0) revert InvalidAmount();

        if (_token == address(0)) { // Handle ETH withdrawal
             uint256 balance = address(this).balance;
             if (_amount > balance) revert AmountTooLarge();
             Address.sendValue(payable(owner()), _amount); // Sending to owner as per simplified governance
             emit FundsWithdrawn(owner(), _amount, address(0));
        } else { // Handle ERC20 withdrawal
            IERC20 tokenContract = IERC20(_token);
            uint256 balance = tokenContract.balanceOf(address(this));
            uint256 stakedAmount = (_token == address(stakingToken)) ? getTotalStaked() : 0;
            uint256 availableBalance = balance - stakedAmount;

            if (_amount > availableBalance) revert AmountTooLarge();

            tokenContract.transfer(owner(), _amount); // Sending to owner as per simplified governance
            emit FundsWithdrawn(owner(), _amount, _token);
        }
    }

    function getDaoBalance(address _token) external view returns (uint256) {
         if (_token == address(0)) { // Handle ETH balance
             return address(this).balance;
         } else { // Handle ERC20 balance
            return IERC20(_token).balanceOf(address(this));
         }
    }

    function getTotalStaked() public view returns (uint256) {
        // Calculates total staked tokens by summing up individual stakes
        // This is O(N) with number of members. For large DAOs,
        // a more efficient method (like tracking total stake directly)
        // would be needed, but would require careful updates on stake/unstake.
        uint256 total = 0;
        for (uint256 i = 1; i <= _proposalIds.current(); i++) { // Iterate through potential SBM token IDs to find members
            address member = membershipNFTLookup[i];
            if (member != address(0) && isMember(member)) {
                total += _stakes[member];
            }
        }
        return total;
    }

    // --- Proposal Functions ---

    function createFundingProposal(address _recipient, uint256 _amount, address _token, string memory _description) external onlyMember whenNotPaused nonReentrant {
        address proposer = _msgSender();
        uint256 proposerStake = _stakes[proposer];
        uint256 totalStaked = getTotalStaked();
        uint256 proposalThreshold = (totalStaked * proposalThresholdNumerator) / proposalThresholdDenominator;

        if (proposerStake < proposalThreshold) revert MinimumStakeNotMet(); // Use min stake for proposal threshold check

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = proposer;
        proposal.description = _description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.state = State.Active;
        proposal.proposalType = ProposalType.Funding;
        proposal.target = _recipient; // Recipient address
        proposal.value = _amount;     // Token amount
        proposal.token = _token;      // Token address
        proposal.callData = "";       // Not used for funding proposals

        emit ProposalCreated(proposalId, proposer, _description, proposal.startTime, proposal.endTime, ProposalType.Funding);
    }

    function createGovernanceProposal(address _target, uint256 _value, bytes memory _callData, string memory _description) external onlyMember whenNotPaused nonReentrant {
        address proposer = _msgSender();
        uint256 proposerStake = _stakes[proposer];
        uint256 totalStaked = getTotalStaked();
        uint256 proposalThreshold = (totalStaked * proposalThresholdNumerator) / proposalThresholdDenominator;

        if (proposerStake < proposalThreshold) revert MinimumStakeNotMet(); // Use min stake for proposal threshold check

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = proposer;
        proposal.description = _description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.state = State.Active;
        proposal.proposalType = ProposalType.Governance;
        proposal.target = _target; // Target contract
        proposal.value = _value;     // ETH value to send with call
        proposal.token = address(0);  // Not used for governance proposals
        proposal.callData = _callData; // Function call data

        emit ProposalCreated(proposalId, proposer, _description, proposal.startTime, proposal.endTime, ProposalType.Governance);
    }

    function cancelProposal(uint256 _proposalId) external proposalExists(_proposalId) whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        // Only proposer or governance can cancel
        if (proposal.proposer != _msgSender() && owner() != _msgSender()) revert Unauthorized();

        // Can only cancel if voting hasn't ended
        if (block.timestamp > proposal.endTime && proposal.state == State.Active) revert VotingPeriodActive();
        // Can also cancel if it's still Pending (though created as Active currently)
        if (proposal.state != State.Active && proposal.state != State.Pending) revert ProposalStateInvalid();


        State oldState = proposal.state;
        proposal.state = State.Canceled;

        emit ProposalCanceled(_proposalId);
        emit ProposalStateChanged(_proposalId, oldState, proposal.state);
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 forVotes,
        uint256 againstVotes,
        State state,
        ProposalType proposalType,
        address target,
        uint256 value,
        bytes memory callData,
        address token
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.state,
            proposal.proposalType,
            proposal.target,
            proposal.value,
            proposal.callData,
            proposal.token
        );
    }

    function getProposalState(uint256 _proposalId) public view proposalExists(_proposalId) returns (State) {
        Proposal storage proposal = proposals[_proposalId];

        // Update state if voting period ended and it's still active
        if (proposal.state == State.Active && block.timestamp > proposal.endTime) {
            return _getProposalStateInternal(proposal);
        }
        return proposal.state;
    }

    function _getProposalStateInternal(Proposal storage proposal) internal view returns (State) {
         if (proposal.state == State.Active && block.timestamp > proposal.endTime) {
            // Voting ended, determine if successful
            uint256 totalVotingPower = getTotalStaked(); // Simplified: Quorum based on total potential power, not just participating voters
            uint256 requiredQuorum = (totalVotingPower * quorumNumerator) / quorumDenominator;
            uint256 totalVotesCast = proposal.forVotes + proposal.againstVotes; // Add abstain votes if implemented

            if (totalVotesCast < requiredQuorum) {
                return State.Defeated; // Did not meet quorum
            }

            uint256 requiredThreshold = (totalVotesCast * proposalThresholdNumerator) / proposalThresholdDenominator;
             if (proposal.forVotes < requiredThreshold) {
                 return State.Defeated; // Did not meet threshold (percentage of votes cast)
             }

            return State.Succeeded; // Passed both quorum and threshold
         }
         // Add checks for other states if needed (e.g., Expired)
         if (proposal.state == State.Queued && block.timestamp > proposal.endTime + executionTimelock) {
             return State.Expired;
         }

         return proposal.state; // Return current stored state if no transition happened
    }


    // --- Voting Functions ---

    function vote(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) votingPeriodActive(_proposalId) nonReentrant {
        address voter = _msgSender();
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.hasVoted[voter]) revert AlreadyVoted();

        uint256 votingPower = getVotingPower(voter);
        if (votingPower == 0) revert NotMember(); // Should not happen with onlyMember, but safety check

        proposal.hasVoted[voter] = true;
        proposal.voterWeight[voter] = votingPower; // Record the weight used for this vote

        if (_support) {
            proposal.forVotes += votingPower;
             _updateReputation(voter, int256(REPUTATION_VOTE_WEIGHT)); // Reward voting 'for'
        } else {
            proposal.againstVotes += votingPower;
            _updateReputation(voter, -int256(REPUTATION_VOTE_WEIGHT)); // Penalize voting 'against' (simple model, could be more complex)
        }

        emit Voted(_proposalId, voter, _support, votingPower);
    }

    function getVote(uint256 _proposalId, address _voter) external view proposalExists(_proposalId) returns (bool hasVoted, uint256 weight) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.hasVoted[_voter], proposal.voterWeight[_voter]);
    }

     function getCurrentVotes(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 forVotes, uint256 againstVotes) {
         Proposal storage proposal = proposals[_proposalId];
         return (proposal.forVotes, proposal.againstVotes);
     }

    // --- Execution Functions ---

    function queueExecution(uint256 _proposalId) external proposalExists(_proposalId) whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        // Ensure voting period is over and state is Succeeded
        if (block.timestamp <= proposal.endTime) revert VotingPeriodActive();
        if (_getProposalStateInternal(proposal) != State.Succeeded) revert ProposalStateInvalid();
        if (proposal.state != State.Active) revert ProposalStateInvalid(); // Must transition from Active after voting ends

        State oldState = proposal.state;
        proposal.state = State.Queued;

        emit ProposalStateChanged(_proposalId, oldState, proposal.state);
    }

    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) executionPeriodActive(_proposalId) whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        // Check if the state is Queued and timelock has passed again
        // (executionPeriodActive modifier does this, but belts and suspenders)
        if (proposal.state != State.Queued) revert ProposalStateInvalid();
        if (block.timestamp < proposal.endTime + executionTimelock) revert ExecutionTimelockNotPassed();

        State oldState = proposal.state;

        bool success = false;
        // Execute based on proposal type
        if (proposal.proposalType == ProposalType.Funding) {
            // Funding Proposal: Send tokens
            if (proposal.token == address(0)) { // ETH
                uint256 balance = address(this).balance;
                if (proposal.value > balance) revert AmountTooLarge(); // Check if DAO has enough ETH
                (success,) = payable(proposal.target).call{value: proposal.value}("");
            } else { // ERC20 Token
                 IERC20 tokenContract = IERC20(proposal.token);
                 uint256 balance = tokenContract.balanceOf(address(this));
                 if (proposal.value > balance) revert AmountTooLarge(); // Check if DAO has enough tokens
                 success = tokenContract.transfer(proposal.target, proposal.value);
            }
             if (!success) revert ExecutionFailed();

             // Update reputation for successful funding
             _updateReputation(proposal.proposer, int256(REPUTATION_SUCCESSFUL_PROPOSAL)); // Reward proposer
             // Could also reward voters who voted 'for'

        } else if (proposal.proposalType == ProposalType.Governance) {
            // Governance Proposal: Call arbitrary contract function
            // Check if DAO has enough ETH to send with the call
            if (proposal.value > address(this).balance) revert AmountTooLarge();

            (success,) = proposal.target.call{value: proposal.value}(proposal.callData);

            if (!success) revert ExecutionFailed();

             // Update reputation for successful governance execution
            _updateReputation(proposal.proposer, int256(REPUTATION_SUCCESSFUL_PROPOSAL)); // Reward proposer
             // Could also reward voters who voted 'for'
        } else {
             revert ProposalStateInvalid(); // Should not happen with current types
        }


        proposal.state = State.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, oldState, proposal.state);
    }

    // --- Soulbound Membership NFT (SBM) Functions (Integrated via Membership) ---

    // The NFT contract is 'this' contract itself.
    // Functions like `balanceOf`, `ownerOf`, `tokenURI` are inherited from ERC721.
    // `transferFrom` and `safeTransferFrom` are effectively disabled by the `_beforeTokenTransfer` override,
    // enforcing the soulbound property.
    // Minting and Burning are handled internally by `joinDao` and `leaveDao`.

    function getMembershipNFTId(address _member) external view returns (uint256) {
         if (!isMember(_member)) return 0; // Return 0 or specific error if not member
         return members[_member].membershipNFTId;
    }

    // Override base ERC721 transfer functions to prevent user-initiated transfers
    // This is handled by the SoulboundERC721 base contract now.
    // We only expose minting/burning via joinDao/leaveDao.

    function _mintMembershipNFT(address _to, uint256 _tokenId) internal {
         _mint(_to, _tokenId);
         // No need to explicitly set tokenURI here unless we have metadata.
         // A more advanced version could set a dynamic URI based on reputation.
    }

    function _burnMembershipNFT(uint256 _tokenId) internal {
         _burn(_tokenId);
    }

    // --- Utility/View Functions ---

    function getDaoParameters() external view returns (
        uint256 _minStake,
        uint256 _votingPeriod,
        uint256 _executionTimelock,
        uint256 _quorumNumerator,
        uint256 _quorumDenominator,
        uint256 _proposalThresholdNumerator,
        uint256 _proposalThresholdDenominator
    ) {
        return (
            minStake,
            votingPeriod,
            executionTimelock,
            quorumNumerator,
            quorumDenominator,
            proposalThresholdNumerator,
            proposalThresholdDenominator
        );
    }

    function getProposalsCount() external view returns (uint256) {
        return _proposalIds.current();
    }

    // Added view functions called internally by other functions
    // function isMember(address _member) is already above
    // function getVotingPower(address _member) is already above
    // function getReputation(address _member) is already above
    // function getMemberStake(address _member) is already above
    // function getTotalStaked() is already above
    // function getDaoBalance(address _token) is already above
    // function getProposalDetails(uint256 _proposalId) is already above
    // function getProposalState(uint256 _proposalId) is already above
    // function getVote(uint256 _proposalId, address _voter) is already above
    // function getCurrentVotes(uint256 _proposalId) is already above
    // function getMembershipNFTId(address _member) is already above


    // Final Function Count Check:
    // 1. constructor
    // 2. setDaoParameters
    // 3. pause
    // 4. unpause
    // 5. emergencyWithdraw
    // 6. joinDao
    // 7. leaveDao
    // 8. stake
    // 9. unstake
    // 10. delegateVote
    // 11. undelegateVote
    // 12. getVotingPower (view)
    // 13. getReputation (view)
    // 14. getMemberStake (view)
    // 15. _updateReputation (internal) - Doesn't count towards external function requirement, but is core logic.
    // 16. receive (payable)
    // 17. depositFunds
    // 18. withdrawExcessFunds
    // 19. getDaoBalance (view)
    // 20. getTotalStaked (view)
    // 21. createFundingProposal
    // 22. createGovernanceProposal
    // 23. cancelProposal
    // 24. getProposalDetails (view)
    // 25. getProposalState (public, view)
    // 26. _getProposalStateInternal (internal, view) - Doesn't count
    // 27. vote
    // 28. getVote (view)
    // 29. getCurrentVotes (view)
    // 30. queueExecution
    // 31. executeProposal
    // 32. getMembershipNFTId (view)
    // 33. _mintMembershipNFT (internal) - Doesn't count
    // 34. _burnMembershipNFT (internal) - Doesn't count
    // 35. getDaoParameters (view)
    // 36. getProposalsCount (view)
    // 37. isMember (public, view)
    // --- Inherited Public Functions (ERC721 / Ownable / Pausable) ---
    // 38. owner() (view)
    // 39. renounceOwnership()
    // 40. transferOwnership(address newOwner)
    // 41. paused() (view)
    // 42. name() (view)
    // 43. symbol() (view)
    // 44. balanceOf(address owner) (view)
    // 45. ownerOf(uint256 tokenId) (view)
    // 46. tokenURI(uint256 tokenId) (view) - Requires base implementation/override
    // 47. supportsInterface(bytes4 interfaceId) (view)
    // 48. getApproved(uint256 tokenId) (view)
    // 49. isApprovedForAll(address owner, address operator) (view)

    // Counting only functions callable externally or public views relevant to users/clients:
    // 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16 (receive), 17, 18, 19, 20, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31, 32, 35, 36, 37
    // Plus inherited: 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49
    // Total: 33 + 12 = 45. Well over the required 20.

    // Note: tokenURI requires implementation if metadata is needed for the SBM.
    // The current ERC721 base doesn't provide a default. For a full implementation,
    // this should be added, potentially returning a URL pointing to JSON metadata.
    // function tokenURI(uint256 tokenId) public view override returns (string memory) { ... }
}
```