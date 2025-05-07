Okay, let's design an interesting, advanced, and creative smart contract that isn't a direct copy of standard open-source templates.

We'll create a **"Decentralized Creative Collective & Reputation Protocol"**.

This contract will combine several concepts:
1.  **Soulbound Tokens (SBTs)** for non-transferable reputation and membership.
2.  **Epochs:** Time periods that gate activities and state changes.
3.  **Curated Proposal System:** Members stake tokens to participate, propose, and curate projects/grants.
4.  **Stake-Weighted Governance:** Voting power based on staked tokens.
5.  **Dynamic SBT Metadata (Conceptual):** Reputation points or achieved traits could influence the SBT's metadata URI (though dynamic metadata often involves off-chain services, we'll structure the contract to *support* storing traits).
6.  **Role-Based Access Control:** For managing epochs and administrative tasks.

**Contract Name:** `CreativeCollectiveProtocol`

**Core Concept:** A community where members earn non-transferable reputation (represented by an SBT) by participating in grant/project proposals, curation, and governance during specific epochs. The collective treasury funds approved proposals.

---

**Outline & Function Summary**

**Contract: `CreativeCollectiveProtocol`**

**Description:** A decentralized protocol for a creative collective. Members stake tokens to join and receive a Soulbound Token (SBT) representing their non-transferable reputation. The protocol operates in epochs, during which members can submit, curate, and vote on proposals for funding or collective decisions. Reputation can be earned through successful participation.

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary libraries (e.g., OpenZeppelin for AccessControl).
2.  **Errors & Events:** Define custom errors and events for transparency.
3.  **Structs & Enums:** Define data structures for Proposals, SBT data, Proposal Status, Vote Options.
4.  **Constants & State Variables:** Define roles, contract addresses (COLLECTIVE_TOKEN), mappings for members, stakes, SBT data, proposals, configuration parameters, epoch counter, treasury balance.
5.  **Access Control:** Define roles using `AccessControl`.
6.  **Constructor:** Initialize roles and set the address of the COLLECTIVE_TOKEN.
7.  **Treasury Management:** Functions to deposit funds and view the treasury balance.
8.  **Membership & SBT:** Functions to join the collective (stake, mint SBT), leave (unstake, burn SBT), claim staked tokens, and view SBT/reputation data.
9.  **Reputation Management:** (Restricted functions) To earn or potentially lose reputation points linked to the SBT.
10. **Epoch Management:** (Restricted functions) To advance epochs and manage epoch-specific state.
11. **Proposal System:** Functions to submit, curate, vote on, execute, and cancel proposals. Functions to view proposal details.
12. **Voting & Delegation:** Functions to delegate and revoke voting power based on stake.
13. **Configuration:** View current protocol parameters. (Updates handled via governance proposals).

**Function Summary:**

1.  `constructor(address _collectiveTokenAddress)`: Initializes the contract, setting the address of the required ERC-20 token and granting initial roles.
2.  `receive() external payable`: Allows receiving native currency (e.g., Ether) into the treasury.
3.  `depositFunds() external payable`: Allows receiving native currency into the treasury with explicit function call (same as receive, but clearer intent).
4.  `getTreasuryBalance() public view returns (uint256)`: Returns the current balance of native currency held by the contract.
5.  `joinCollective() external`: Allows a user to join the collective by staking `minStakeAmount` of the `COLLECTIVE_TOKEN`. Mints a non-transferable Reputation SBT for the user.
6.  `leaveCollective() external`: Allows a member to initiate leaving the collective. Burns their Reputation SBT and starts a cool-down period before staked tokens can be claimed.
7.  `claimStakedTokens() external`: Allows a member who has initiated leaving and completed the cool-down period to claim their staked `COLLECTIVE_TOKEN`.
8.  `getReputationLevel(address member) public view returns (uint256)`: Returns the current reputation points for a given member address.
9.  `getSBTTokenId(address member) public view returns (uint256)`: Returns the SBT token ID associated with a member address. Returns 0 if no SBT exists.
10. `getSBTMetadataURI(address member) public view returns (string memory)`: Returns the (potentially dynamic) metadata URI for a member's SBT, based on their on-chain data (like reputation).
11. `earnReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE)`: Awards reputation points to a member. (Restricted function, ideally called by governance or successful proposal execution).
12. `loseReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE)`: Deducts reputation points from a member. (Restricted function).
13. `startNewEpoch() external onlyRole(EPOCH_MANAGER_ROLE)`: Advances the protocol to the next epoch. Closes voting periods, processes completed proposals, potentially triggers SBT metadata updates. (Restricted function).
14. `getEpochInfo() public view returns (uint256 currentEpoch, uint256 epochStartTime)`: Returns the current epoch number and its start timestamp.
15. `submitProposal(uint256 proposalType, string memory description, address targetAddress, uint256 value, bytes memory callData) external`: Allows a member with sufficient stake to submit a proposal (e.g., grant request, configuration change). Requires staking `proposalStakeAmount`.
16. `curateProposal(uint256 proposalId) external`: Allows members with sufficient reputation/stake to mark a submitted proposal as "curated", making it eligible for voting in the next epoch.
17. `voteOnProposal(uint256 proposalId, uint8 voteOption) external`: Allows members to vote on a curated proposal during the active voting epoch. Vote weight is based on staked `COLLECTIVE_TOKEN` (or delegated stake).
18. `executeProposal(uint256 proposalId) external`: Allows anyone to execute a proposal that has passed its voting period and met the required thresholds (quorum, majority). Handles fund transfers or configuration updates.
19. `cancelProposal(uint256 proposalId) external`: Allows the proposer to cancel their proposal before it enters the voting period.
20. `getCurrentProposals(uint256 statusFilter) public view returns (uint256[] memory)`: Returns a list of proposal IDs filtered by status (Submitted, Curated, Voting, etc.).
21. `getProposalDetails(uint256 proposalId) public view returns (uint256 id, uint256 submitterSbtId, uint256 proposalType, string memory description, address targetAddress, uint256 value, bytes memory callData, uint256 submittedEpoch, uint256 votingEpoch, uint256 endEpoch, uint256 curatedTimestamp, uint256 totalVotesFor, uint256 totalVotesAgainst, uint256 totalVotesAbstain, uint256 stakeRequired, uint256 stakeReturned, uint256 executedTimestamp, uint8 currentStatus)`: Returns detailed information about a specific proposal.
22. `getVoteCount(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes)`: Returns the current vote counts for a proposal during its voting period.
23. `getVoterStake(uint256 proposalId, address voter) public view returns (uint256)`: Returns the amount of stake counted for a specific voter on a specific proposal.
24. `delegateVote(address delegatee) external`: Allows a member to delegate their voting power to another address.
25. `revokeDelegation() external`: Allows a member to revoke their voting delegation.
26. `getConfig() public view returns (uint256 minStakeAmount, uint256 proposalStakeAmount, uint256 curationReputationThreshold, uint256 votingPeriodEpochs, uint256 proposalExecutionGracePeriodEpochs, uint256 leavingCoolDownEpochs, uint256 quorumNumerator, uint256 quorumDenominator)`: Returns the current configuration parameters of the protocol.
27. `hasRole(bytes32 role, address account) public view returns (bool)`: Checks if an account has a specific role (from AccessControl).
28. `grantRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE)`: Grants a role (from AccessControl).
29. `revokeRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE)`: Revokes a role (from AccessControl).
30. `renounceRole(bytes32 role, address account) public virtual`: Renounces a role (from AccessControl).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Just for interface reference, will implement custom logic
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // For metadata URI standard
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
// Contract: CreativeCollectiveProtocol
// Description: A decentralized protocol for a creative collective. Members stake tokens to join and receive a Soulbound Token (SBT) representing their non-transferable reputation. The protocol operates in epochs, during which members can submit, curate, and vote on proposals for funding or collective decisions. Reputation can be earned through successful participation.
//
// Outline:
// 1. Pragma & Imports: Specify Solidity version and import necessary libraries (e.g., OpenZeppelin for AccessControl).
// 2. Errors & Events: Define custom errors and events for transparency.
// 3. Structs & Enums: Define data structures for Proposals, SBT data, Proposal Status, Vote Options.
// 4. Constants & State Variables: Define roles, contract addresses (COLLECTIVE_TOKEN), mappings for members, stakes, SBT data, proposals, configuration parameters, epoch counter, treasury balance.
// 5. Access Control: Define roles using AccessControl.
// 6. Constructor: Initialize roles and set the address of the COLLECTIVE_TOKEN.
// 7. Treasury Management: Functions to deposit funds and view the treasury balance.
// 8. Membership & SBT: Functions to join the collective (stake, mint SBT), leave (unstake, burn SBT), claim staked tokens, and view SBT/reputation data.
// 9. Reputation Management: (Restricted functions) To earn or potentially lose reputation points linked to the SBT.
// 10. Epoch Management: (Restricted functions) To advance epochs and manage epoch-specific state.
// 11. Proposal System: Functions to submit, curate, vote on, execute, and cancel proposals. Functions to view proposal details.
// 12. Voting & Delegation: Functions to delegate and revoke voting power based on stake.
// 13. Configuration: View current protocol parameters. (Updates handled via governance proposals).
//
// Function Summary:
// 1. constructor(address _collectiveTokenAddress): Initializes the contract, setting the address of the required ERC-20 token and granting initial roles.
// 2. receive() external payable: Allows receiving native currency (e.g., Ether) into the treasury.
// 3. depositFunds() external payable: Allows receiving native currency into the treasury with explicit function call (same as receive, but clearer intent).
// 4. getTreasuryBalance() public view returns (uint256): Returns the current balance of native currency held by the contract.
// 5. joinCollective() external: Allows a user to join the collective by staking `minStakeAmount` of the `COLLECTIVE_TOKEN`. Mints a non-transferable Reputation SBT for the user.
// 6. leaveCollective() external: Allows a member to initiate leaving the collective. Burns their Reputation SBT and starts a cool-down period before staked tokens can be claimed.
// 7. claimStakedTokens() external: Allows a member who has initiated leaving and completed the cool-down period to claim their staked `COLLECTIVE_TOKEN`.
// 8. getReputationLevel(address member) public view returns (uint256): Returns the current reputation points for a given member address.
// 9. getSBTTokenId(address member) public view returns (uint256): Returns the SBT token ID associated with a member address. Returns 0 if no SBT exists.
// 10. getSBTMetadataURI(address member) public view returns (string memory): Returns the (potentially dynamic) metadata URI for a member's SBT, based on their on-chain data (like reputation).
// 11. earnReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE): Awards reputation points to a member. (Restricted function, ideally called by governance or successful proposal execution).
// 12. loseReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE): Deducts reputation points from a member. (Restricted function).
// 13. startNewEpoch() external onlyRole(EPOCH_MANAGER_ROLE): Advances the protocol to the next epoch. Closes voting periods, processes completed proposals, potentially triggers SBT metadata updates. (Restricted function).
// 14. getEpochInfo() public view returns (uint256 currentEpoch, uint256 epochStartTime): Returns the current epoch number and its start timestamp.
// 15. submitProposal(uint256 proposalType, string memory description, address targetAddress, uint256 value, bytes memory callData) external: Allows a member with sufficient stake to submit a proposal (e.g., grant request, configuration change). Requires staking `proposalStakeAmount`.
// 16. curateProposal(uint256 proposalId) external: Allows members with sufficient reputation/stake to mark a submitted proposal as "curated", making it eligible for voting in the next epoch.
// 17. voteOnProposal(uint256 proposalId, uint8 voteOption) external: Allows members to vote on a curated proposal during the active voting epoch. Vote weight is based on staked COLLECTIVE_TOKEN (or delegated stake).
// 18. executeProposal(uint256 proposalId) external: Allows anyone to execute a proposal that has passed its voting period and met the required thresholds (quorum, majority). Handles fund transfers or configuration updates.
// 19. cancelProposal(uint256 proposalId) external: Allows the proposer to cancel their proposal before it enters the voting period.
// 20. getCurrentProposals(uint256 statusFilter) public view returns (uint256[] memory): Returns a list of proposal IDs filtered by status (Submitted, Curated, Voting, etc.).
// 21. getProposalDetails(uint256 proposalId) public view returns (uint256 id, uint256 submitterSbtId, uint256 proposalType, string memory description, address targetAddress, uint256 value, bytes memory callData, uint256 submittedEpoch, uint256 votingEpoch, uint256 endEpoch, uint256 curatedTimestamp, uint256 totalVotesFor, uint256 totalVotesAgainst, uint256 totalVotesAbstain, uint256 stakeRequired, uint256 stakeReturned, uint256 executedTimestamp, uint8 currentStatus): Returns detailed information about a specific proposal.
// 22. getVoteCount(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes): Returns the current vote counts for a proposal during its voting period.
// 23. getVoterStake(uint256 proposalId, address voter) public view returns (uint256): Returns the amount of stake counted for a specific voter on a specific proposal.
// 24. delegateVote(address delegatee) external: Allows a member to delegate their voting power to another address.
// 25. revokeDelegation() external: Allows a member to revoke their voting delegation.
// 26. getConfig() public view returns (uint256 minStakeAmount, uint256 proposalStakeAmount, uint256 curationReputationThreshold, uint256 votingPeriodEpochs, uint256 proposalExecutionGracePeriodEpochs, uint256 leavingCoolDownEpochs, uint256 quorumNumerator, uint256 quorumDenominator): Returns the current configuration parameters of the protocol.
// 27. hasRole(bytes32 role, address account) public view returns (bool) (Inherited from AccessControl).
// 28. grantRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) (Inherited from AccessControl).
// 29. revokeRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) (Inherited from AccessControl).
// 30. renounceRole(bytes32 role, address account) public virtual (Inherited from AccessControl).
//
// Note: ERC-721 transfer functions are intentionally omitted or restricted for the SBT to enforce soulbound nature.
// Note: Metadata URI generation for SBTs is complex and usually involves an off-chain service reading on-chain traits. The function here provides the hook.
// Note: This contract assumes a separate ERC-20 token contract is deployed and its address is provided.

contract CreativeCollectiveProtocol is Context, AccessControl {

    using Counters for Counters.Counter;
    Counters.Counter private _sbtTokenIds;
    Counters.Counter private _proposalIds;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant EPOCH_MANAGER_ROLE = keccak256("EPOCH_MANAGER_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    // Add other roles if needed, e.g., CURATOR_ROLE if curation is role-based

    // --- Errors ---
    error NotAMember();
    error AlreadyAMember();
    error StakingRequired(uint256 requiredStake);
    error StakeTransferFailed();
    error InsufficientStake();
    error LeavingCooldownNotFinished(uint256 readyEpoch);
    error NotLeaving();
    error ProposalNotFound();
    error InvalidProposalStatus(uint8 expectedStatus, uint8 currentStatus);
    error AlreadyVoted();
    error VotingNotInProgress();
    error ProposalVotingNotYetStarted();
    error ProposalNotExecutable(uint8 currentStatus);
    error ExecutionFailed();
    error UnauthorizedAction(); // For curation, cancellation etc.
    error DelegationRequired();
    error SelfDelegationForbidden();
    error DelegationAlreadySet();
    error NoDelegationToRevoke();
    error InvalidVoteOption();
    error QuorumNotReached();
    error MajorityNotReached();
    error InsufficientReputationForCuration(uint256 requiredReputation);
    error AddressHasNoSBT();

    // --- Events ---
    event MemberJoined(address indexed member, uint256 sbtTokenId, uint256 stakeAmount);
    event MemberLeaving(address indexed member, uint256 sbtTokenId, uint256 readyToClaimEpoch);
    event StakedTokensClaimed(address indexed member, uint256 amount);
    event ReputationEarned(address indexed member, uint256 sbtTokenId, uint256 points);
    event ReputationLost(address indexed member, uint256 sbtTokenId, uint256 points);
    event EpochStarted(uint256 indexed epoch, uint256 startTime);
    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed submitterSbtId, uint256 proposalType, uint256 submittedEpoch);
    event ProposalCurated(uint256 indexed proposalId, address indexed curator);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteOption, uint256 stakeWeight);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    event DelegationSet(address indexed delegator, address indexed delegatee);
    event DelegationRevoked(address indexed delegator);
    event FundsDeposited(address indexed depositor, uint256 amount);

    // --- Enums ---
    enum ProposalStatus { Submitted, Curated, Voting, EndedSuccessful, EndedFailed, Cancelled, Executed }
    enum VoteOption { Abstain, For, Against } // Corresponds to 0, 1, 2

    // --- Structs ---
    struct SBTData {
        uint256 tokenId;
        uint256 reputationPoints;
        uint256 stakedAmount; // Amount of COLLECTIVE_TOKEN staked by this member
        bool isMember; // Indicates active membership
        uint256 leavingReadyEpoch; // Epoch when staked tokens can be claimed after leaving
        address delegatee; // Address to whom voting power is delegated (self-delegation implies no delegation)
    }

    struct Proposal {
        uint256 id;
        uint256 submitterSbtId; // SBT of the proposer
        uint256 proposalType; // e.g., 0 for Grant, 1 for Config Change, etc.
        string description;
        address targetAddress; // Address to call or send funds to
        uint256 value;       // Amount of native currency to send (for grant proposals)
        bytes callData;      // Call data for targetAddress (for generic execution proposals)

        ProposalStatus currentStatus;

        uint256 submittedEpoch;
        uint256 votingEpoch; // Epoch when voting starts (usually epoch after curation)
        uint256 endEpoch; // Epoch when voting ends

        uint256 curatedTimestamp;
        uint256 executedTimestamp;

        // Voting results
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 totalVotesAbstain;

        // Stake required/returned for proposal submission
        uint256 stakeRequired;
        uint256 stakeReturned;

        mapping(address => bool) hasVoted; // Voter address => has voted on this proposal
        mapping(address => uint256) voteWeight; // Voter address => stake weight used for voting

        // Keep track of voters to calculate quorum
        address[] voters; // Simple array, could be optimized for gas on large scale
    }

    struct ProtocolConfig {
        uint256 minStakeAmount;             // Min COLLECTIVE_TOKEN to stake to become a member
        uint256 proposalStakeAmount;        // COLLECTIVE_TOKEN stake required to submit a proposal
        uint256 curationReputationThreshold; // Min reputation to curate a proposal
        uint256 votingPeriodEpochs;         // Duration of voting period in epochs
        uint256 proposalExecutionGracePeriodEpochs; // Time after voting ends before execution is blocked
        uint256 leavingCoolDownEpochs;      // Epochs to wait after leaving before claiming stake
        uint256 quorumNumerator;            // Quorum = total_staked * numerator / denominator
        uint256 quorumDenominator;
    }

    // --- State Variables ---
    IERC20 public immutable COLLECTIVE_TOKEN;

    mapping(address => SBTData) private _memberSBTs; // Member address => SBT Data
    mapping(uint256 => address) private _sbtOwners; // SBT Token ID => Member address (for lookup)

    mapping(uint256 => Proposal) private _proposals; // Proposal ID => Proposal Data
    mapping(uint256 => uint256[]) private _proposalsByStatus; // Proposal Status => List of Proposal IDs

    ProtocolConfig public config;

    uint256 public currentEpoch = 0;
    uint256 public epochStartTime = block.timestamp; // Timestamp when the current epoch started

    // --- Constructor ---
    constructor(address _collectiveTokenAddress) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EPOCH_MANAGER_ROLE, _msgSender());
        _grantRole(REPUTATION_MANAGER_ROLE, _msgSender());

        COLLECTIVE_TOKEN = IERC20(_collectiveTokenAddress);

        // Set initial configuration (can be changed via governance proposals later)
        config = ProtocolConfig({
            minStakeAmount: 100 ether, // Example: 100 tokens
            proposalStakeAmount: 50 ether, // Example: 50 tokens
            curationReputationThreshold: 100, // Example: 100 reputation points
            votingPeriodEpochs: 3,
            proposalExecutionGracePeriodEpochs: 5,
            leavingCoolDownEpochs: 7,
            quorumNumerator: 4, // 4/10 = 40% quorum
            quorumDenominator: 10
        });

        // Start Epoch 0
        emit EpochStarted(currentEpoch, epochStartTime);
    }

    // --- Treasury Management ---
    receive() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function depositFunds() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Membership & SBT ---

    function joinCollective() external {
        address member = _msgSender();
        if (_memberSBTs[member].isMember) {
            revert AlreadyAMember();
        }

        if (COLLECTIVE_TOKEN.balanceOf(member) < config.minStakeAmount) {
            revert StakingRequired(config.minStakeAmount);
        }

        // Transfer stake to the contract
        bool success = COLLECTIVE_TOKEN.transferFrom(member, address(this), config.minStakeAmount);
        if (!success) {
            revert StakeTransferFailed();
        }

        // Mint SBT (custom logic, not standard ERC721 mint)
        _sbtTokenIds.increment();
        uint256 newTokenId = _sbtTokenIds.current();

        _memberSBTs[member] = SBTData({
            tokenId: newTokenId,
            reputationPoints: 0, // Start with 0 reputation
            stakedAmount: config.minStakeAmount,
            isMember: true,
            leavingReadyEpoch: 0,
            delegatee: member // Self-delegation by default
        });
        _sbtOwners[newTokenId] = member;

        emit MemberJoined(member, newTokenId, config.minStakeAmount);
    }

    function leaveCollective() external {
        address member = _msgSender();
        SBTData storage memberData = _memberSBTs[member];

        if (!memberData.isMember) {
            revert NotAMember();
        }

        // Mark as not a member and set cool-down epoch
        memberData.isMember = false;
        memberData.leavingReadyEpoch = currentEpoch + config.leavingCoolDownEpochs;
        // Note: We don't burn the SBT token ID immediately, just mark it inactive.
        // The SBT data remains linked until the user claims stake (or forever).

        emit MemberLeaving(member, memberData.tokenId, memberData.leavingReadyEpoch);
    }

    function claimStakedTokens() external {
        address member = _msgSender();
        SBTData storage memberData = _memberSBTs[member];

        if (memberData.isMember) {
            revert NotLeaving(); // Can only claim if you initiated leaving
        }
        if (memberData.stakedAmount == 0) {
             revert NotLeaving(); // Or maybe NoStakeToClaim? Let's reuse
        }
        if (currentEpoch < memberData.leavingReadyEpoch) {
            revert LeavingCooldownNotFinished(memberData.leavingReadyEpoch);
        }

        uint256 amountToClaim = memberData.stakedAmount;
        memberData.stakedAmount = 0; // Reset staked amount

        // Transfer staked tokens back
        bool success = COLLECTIVE_TOKEN.transfer(member, amountToClaim);
        if (!success) {
            // This is a critical failure, consider different error handling or pausing
             memberData.stakedAmount = amountToClaim; // Revert state if transfer fails
            revert StakeTransferFailed();
        }

        // Optional: Fully "burn" / unlink SBT here if desired, or keep record for history/stats
        // For now, we keep the SBTData but amount is 0 and isMember is false.

        emit StakedTokensClaimed(member, amountToClaim);
    }

    function getReputationLevel(address member) public view returns (uint256) {
        return _memberSBTs[member].reputationPoints;
    }

    function getSBTTokenId(address member) public view returns (uint256) {
         if (!_memberSBTs[member].isMember && _memberSBTs[member].stakedAmount == 0 && _memberSBTs[member].tokenId == 0) {
             // This address never joined or fully claimed/burned
             return 0;
         }
        return _memberSBTs[member].tokenId;
    }

    // --- SBT Metadata (Conceptual) ---
    // This function hooks into a potential off-chain metadata service.
    // The actual metadata JSON creation happens off-chain based on the returned URI.
    // The URI could encode token ID, current epoch, and reputation level.
    function getSBTMetadataURI(address member) public view returns (string memory) {
         SBTData storage memberData = _memberSBTs[member];
        if (memberData.tokenId == 0) {
            revert AddressHasNoSBT();
        }
        // Example URI structure: `ipfs://<cid>/sbt/<token_id>/<epoch>/<reputation>`
        // An off-chain service listening for events or polling state would resolve this URI.
        string memory baseURI = "ipfs://QmW.../"; // Replace with your base URI
        return string(abi.encodePacked(baseURI, "sbt/", Strings.toString(memberData.tokenId), "/", Strings.toString(currentEpoch), "/", Strings.toString(memberData.reputationPoints)));
    }

    // --- Reputation Management ---

    function earnReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE) {
        SBTData storage memberData = _memberSBTs[member];
        if (memberData.tokenId == 0) {
            revert AddressHasNoSBT();
        }
        memberData.reputationPoints += points;
        emit ReputationEarned(member, memberData.tokenId, points);
    }

    function loseReputation(address member, uint256 points) external onlyRole(REPUTATION_MANAGER_ROLE) {
        SBTData storage memberData = _memberSBTs[member];
         if (memberData.tokenId == 0) {
            revert AddressHasNoSBT();
        }
        memberData.reputationPoints = memberData.reputationPoints > points ? memberData.reputationPoints - points : 0;
        emit ReputationLost(member, memberData.tokenId, points);
    }

    // --- Epoch Management ---
    // This function would typically be called by a trusted bot, multi-sig, or time-based keeper.
    function startNewEpoch() external onlyRole(EPOCH_MANAGER_ROLE) {
        // Process proposals whose voting ended in the *last* epoch
        // (Logic for processing finished epochs would go here - potentially triggering execution checks)

        currentEpoch++;
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpoch, epochStartTime);
    }

     function getEpochInfo() public view returns (uint256 currentEpoch_, uint256 epochStartTime_) {
        return (currentEpoch, epochStartTime);
    }


    // --- Proposal System ---

    function submitProposal(
        uint256 proposalType,
        string memory description,
        address targetAddress,
        uint256 value, // for fund transfers (ETH)
        bytes memory callData // for contract calls
    ) external {
        address submitter = _msgSender();
        SBTData storage submitterData = _memberSBTs[submitter];

        if (!submitterData.isMember) {
            revert NotAMember();
        }
        if (submitterData.stakedAmount < config.proposalStakeAmount) {
            revert InsufficientStake();
        }

        // Transfer proposal stake to the contract
        bool success = COLLECTIVE_TOKEN.transferFrom(submitter, address(this), config.proposalStakeAmount);
        if (!success) {
            revert StakeTransferFailed();
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage newProposal = _proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.submitterSbtId = submitterData.tokenId;
        newProposal.proposalType = proposalType;
        newProposal.description = description;
        newProposal.targetAddress = targetAddress;
        newProposal.value = value;
        newProposal.callData = callData;
        newProposal.currentStatus = ProposalStatus.Submitted;
        newProposal.submittedEpoch = currentEpoch;
        newProposal.stakeRequired = config.proposalStakeAmount;

        _proposalsByStatus[uint8(ProposalStatus.Submitted)].push(newProposalId);

        emit ProposalSubmitted(newProposalId, submitterData.tokenId, proposalType, currentEpoch);
    }

    function curateProposal(uint256 proposalId) external {
        address curator = _msgSender();
         SBTData storage curatorData = _memberSBTs[curator];

        if (!curatorData.isMember) {
            revert NotAMember();
        }
        // Optional: Require reputation for curation
        if (curatorData.reputationPoints < config.curationReputationThreshold) {
             revert InsufficientReputationForCuration(config.curationReputationThreshold);
        }
        // Optional: Require stake for curation
         if (curatorData.stakedAmount < config.minStakeAmount) {
             revert InsufficientStake();
         }


        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.currentStatus != ProposalStatus.Submitted) {
            revert InvalidProposalStatus(uint8(ProposalStatus.Submitted), uint8(proposal.currentStatus));
        }

        // Move to Curated status, set voting epoch for the *next* epoch
        proposal.currentStatus = ProposalStatus.Curated;
        proposal.votingEpoch = currentEpoch + 1;
        proposal.endEpoch = proposal.votingEpoch + config.votingPeriodEpochs;
        proposal.curatedTimestamp = block.timestamp;

        // Remove from Submitted list, add to Curated list (simplified: just update status)
        // In a real contract, managing these lists efficiently is important

        emit ProposalCurated(proposalId, curator);
    }

    function voteOnProposal(uint256 proposalId, uint8 voteOption) external {
        address voter = _msgSender();
        SBTData storage voterData = _memberSBTs[voter];

        if (!voterData.isMember || voterData.stakedAmount == 0) {
            // Only actively staked members can vote
            revert NotAMember();
        }

        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.currentStatus != ProposalStatus.Curated && proposal.currentStatus != ProposalStatus.Voting) {
             revert ProposalVotingNotYetStarted(); // Not yet curated or voting ended
        }

        // Check if voting period is active
        if (currentEpoch < proposal.votingEpoch || currentEpoch >= proposal.endEpoch) {
            revert VotingNotInProgress();
        }

        if (proposal.hasVoted[voter]) {
            revert AlreadyVoted();
        }

        if (voteOption > uint8(VoteOption.Against)) {
            revert InvalidVoteOption();
        }

        // Get effective vote weight (handle delegation)
        address effectiveVoter = voterData.delegatee;
        // If delegatee is self, use own stake. Otherwise, delegatee's stake is irrelevant for *casting* the vote here,
        // but the *weight* applied is the *delegator's* stake.
        // This assumes stake-based voting is tied to the *voter casting* the vote, potentially using delegated power.
        // A more advanced system might track delegated stake separately.
        // Let's assume here the voter casts the vote, and their *own* current stakedAmount is the weight,
        // OR we track stake *at the time of voting epoch start* for snapshot voting.
        // For simplicity, let's use the voter's current stake, but note this can be gamed.
        // A snapshot at the start of the voting epoch would be better.
        // Let's use the voter's CURRENT active stake as weight for simplicity in this example.
        uint256 voteWeight = voterData.stakedAmount;

        if (voteWeight == 0) {
             revert InsufficientStake(); // Should be covered by NotAMember check, but defensive
        }

        proposal.hasVoted[voter] = true;
        proposal.voteWeight[voter] = voteWeight;
        proposal.voters.push(voter); // Add voter to list for quorum calculation

        if (voteOption == uint8(VoteOption.For)) {
            proposal.totalVotesFor += voteWeight;
        } else if (voteOption == uint8(VoteOption.Against)) {
            proposal.totalVotesAgainst += voteWeight;
        } else { // Abstain
            proposal.totalVotesAbstain += voteWeight;
        }

        // If it's the first vote, change status to Voting (optional, could also be done by Epoch Manager)
        if (proposal.currentStatus == ProposalStatus.Curated) {
            proposal.currentStatus = ProposalStatus.Voting;
        }

        emit VoteCast(proposalId, voter, voteOption, voteWeight);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.currentStatus != ProposalStatus.Voting) {
             // Can only execute after voting ends (status check below handles timing)
             revert InvalidProposalStatus(uint8(ProposalStatus.Voting), uint8(proposal.currentStatus));
        }

        // Check if voting period has ended
        if (currentEpoch < proposal.endEpoch) {
            revert ProposalVotingNotYetStarted(); // Voting period not finished
        }

        // Check if execution window is still open (grace period)
        if (currentEpoch >= proposal.endEpoch + config.proposalExecutionGracePeriodEpochs) {
             // This status should ideally be automatically set by the epoch manager
            if (proposal.currentStatus == ProposalStatus.Voting) {
                // Auto-fail if grace period passed before execution attempt
                // (This part is simplified, a real system would need epoch manager to handle this state change)
                 proposal.currentStatus = ProposalStatus.EndedFailed;
                 revert ProposalNotExecutable(uint8(proposal.currentStatus));
            } else {
                 revert ProposalNotExecutable(uint8(proposal.currentStatus));
            }
        }


        // Calculate total vote weight for quorum
        uint256 totalStakedWeight = 0;
        // More accurate quorum calculation needs total *active* stake at the start of the voting epoch.
        // For simplicity here, we'll sum up the weight of all *actual voters* on this proposal.
        // This is a simplified/less secure quorum check. A real DAO needs snapshotting.
        for(uint i = 0; i < proposal.voters.length; i++) {
            totalStakedWeight += proposal.voteWeight[proposal.voters[i]];
        }

        uint256 requiredQuorum = (totalStakedWeight * config.quorumNumerator) / config.quorumDenominator;

        if (proposal.totalVotesFor + proposal.totalVotesAgainst < requiredQuorum) {
            proposal.currentStatus = ProposalStatus.EndedFailed; // Quorum failed
            revert QuorumNotReached();
        }

        if (proposal.totalVotesFor <= proposal.totalVotesAgainst) {
            proposal.currentStatus = ProposalStatus.EndedFailed; // Majority failed
            revert MajorityNotReached();
        }

        // Proposal Passed! Attempt Execution.
        proposal.executedTimestamp = block.timestamp;

        (bool success, ) = proposal.targetAddress.call{value: proposal.value}(proposal.callData);

        if (success) {
            proposal.currentStatus = ProposalStatus.Executed;
             // Return proposer stake on successful execution (or distribute based on vote participation)
             // Simple return to submitter for now
             proposal.stakeReturned = proposal.stakeRequired;
            bool transferStakeSuccess = COLLECTIVE_TOKEN.transfer(
                _sbtOwners[proposal.submitterSbtId], proposal.stakeReturned
            );
            // If stake transfer fails, it's bad but don't revert execution if the main call succeeded
             if (!transferStakeSuccess) {
                 // Log error?
             }
        } else {
            proposal.currentStatus = ProposalStatus.EndedFailed;
            // Optionally penalize proposer or return stake based on outcome
            // For now, stake remains in contract on failure.
            revert ExecutionFailed();
        }

        emit ProposalExecuted(proposalId, _msgSender());
    }

    function cancelProposal(uint256 proposalId) external {
        address canceller = _msgSender();
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        // Only the submitter can cancel
        if (_memberSBTs[canceller].tokenId != proposal.submitterSbtId) {
            revert UnauthorizedAction();
        }

        // Can only cancel before it's curated or starts voting
        if (proposal.currentStatus != ProposalStatus.Submitted) {
            revert InvalidProposalStatus(uint8(ProposalStatus.Submitted), uint8(proposal.currentStatus));
        }

        proposal.currentStatus = ProposalStatus.Cancelled;

        // Return proposer stake
        proposal.stakeReturned = proposal.stakeRequired;
        bool success = COLLECTIVE_TOKEN.transfer(_sbtOwners[proposal.submitterSbtId], proposal.stakeReturned);
         if (!success) {
            // Log error?
         }

        emit ProposalCancelled(proposalId, canceller);
    }

    // --- Proposal Getters ---

    function getCurrentProposals(uint256 statusFilter) public view returns (uint256[] memory) {
        // Note: This is a simplified getter. Storing/filtering lists by status efficiently
        // in Solidity is complex and gas-intensive. A real system might use subgraphs or
        // track IDs in different arrays during state transitions.
        // This implementation iterates through all proposals, which is inefficient for many proposals.

        uint256 totalProposals = _proposalIds.current();
        uint256[] memory filteredProposals = new uint256[](totalProposals);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalProposals; i++) {
            if (_proposals[i].id != 0) { // Check if proposal exists
                if (_proposals[i].currentStatus == ProposalStatus(statusFilter) || statusFilter == 99) { // 99 for all statuses
                    filteredProposals[count] = i;
                    count++;
                }
            }
        }

        // Trim the array
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++){
            result[i] = filteredProposals[i];
        }
        return result;
    }


    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        uint256 submitterSbtId,
        uint256 proposalType,
        string memory description,
        address targetAddress,
        uint256 value,
        bytes memory callData,
        uint256 submittedEpoch,
        uint256 votingEpoch,
        uint256 endEpoch,
        uint256 curatedTimestamp,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst,
        uint256 totalVotesAbstain,
        uint256 stakeRequired,
        uint256 stakeReturned,
        uint256 executedTimestamp,
        uint8 currentStatus
    ) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }

        return (
            proposal.id,
            proposal.submitterSbtId,
            proposal.proposalType,
            proposal.description,
            proposal.targetAddress,
            proposal.value,
            proposal.callData,
            proposal.submittedEpoch,
            proposal.votingEpoch,
            proposal.endEpoch,
            proposal.curatedTimestamp,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.totalVotesAbstain,
            proposal.stakeRequired,
            proposal.stakeReturned,
            proposal.executedTimestamp,
            uint8(proposal.currentStatus)
        );
    }

    function getVoteCount(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
         Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        return (proposal.totalVotesFor, proposal.totalVotesAgainst, proposal.totalVotesAbstain);
    }

     function getVoterStake(uint256 proposalId, address voter) public view returns (uint256) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        // Note: This only returns the stake recorded *when the user voted*
        return proposal.voteWeight[voter];
    }


    // --- Voting & Delegation ---

    function delegateVote(address delegatee) external {
        address delegator = _msgSender();
        SBTData storage delegatorData = _memberSBTs[delegator];

        if (!delegatorData.isMember) {
            revert NotAMember();
        }
        if (delegator == delegatee) {
            revert SelfDelegationForbidden();
        }
        // Check if delegatee is a member? Optional. Can delegate to non-member if they are trusted.
        // Let's allow delegating to any address for flexibility.

        if (delegatorData.delegatee != delegator) {
             revert DelegationAlreadySet();
        }

        delegatorData.delegatee = delegatee;
        emit DelegationSet(delegator, delegatee);
    }

    function revokeDelegation() external {
        address delegator = _msgSender();
        SBTData storage delegatorData = _memberSBTs[delegator];

        if (!delegatorData.isMember) {
            revert NotAMember();
        }
        if (delegatorData.delegatee == delegator) {
            revert NoDelegationToRevoke();
        }

        delegatorData.delegatee = delegator; // Set back to self-delegation
        emit DelegationRevoked(delegator);
    }

    // --- Configuration ---

    function getConfig() public view returns (
        uint256 minStakeAmount,
        uint256 proposalStakeAmount,
        uint256 curationReputationThreshold,
        uint256 votingPeriodEpochs,
        uint256 proposalExecutionGracePeriodEpochs,
        uint256 leavingCoolDownEpochs,
        uint256 quorumNumerator,
        uint256 quorumDenominator
    ) {
        return (
            config.minStakeAmount,
            config.proposalStakeAmount,
            config.curationReputationThreshold,
            config.votingPeriodEpochs,
            config.proposalExecutionGracePeriodEpochs,
            config.leavingCoolDownEpochs,
            config.quorumNumerator,
            config.quorumDenominator
        );
    }

    // Configuration updates would happen via successful governance proposals
    // Example (internal, called by executeProposal):
    // function _updateConfig(uint256 newMinStake, ...) internal { config = newConfig; }

    // --- AccessControl Overrides (standard from OpenZeppelin) ---
    // Needed to make the AccessControl functions visible/usable from outside
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return super.hasRole(role, account);
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
    }

     // --- Custom SBT ERC721-like functions (minimal implementation for Soulbound) ---
     // Does NOT implement full ERC721 standard, specifically transfer functions are missing or restricted.

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _sbtOwners[tokenId];
        if (owner == address(0)) {
             revert AddressHasNoSBT(); // Reusing error for token not found
        }
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        // A member only has one SBT in this design
        return _memberSBTs[owner].tokenId > 0 ? 1 : 0;
    }

    // Omit or restrict transfer functions (transferFrom, safeTransferFrom) to make it soulbound.
    // Function `leaveCollective` acts as the burn mechanism in this context.

     // Standard ERC721Metadata implementation hook (can be extended)
     function name() public pure returns (string memory) {
         return "Creative Collective Reputation SBT";
     }

     function symbol() public pure returns (string memory) {
         return "CC-SBT";
     }

     // tokenURI is handled by getSBTMetadataURI for dynamic data
     // function tokenURI(uint256 tokenId) public view returns (string memory) {} // Can implement this calling getSBTMetadataURI based on token ID -> owner mapping

}
```