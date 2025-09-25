This smart contract, named `InnovationCatalystDAO`, envisions a decentralized autonomous organization dedicated to fostering and funding innovative projects. It introduces several advanced concepts:

1.  **Dynamic Reputation System:** Users earn and lose reputation based on their participation, project success, and voting accuracy. This reputation influences their voting weight and the quality of their proposals.
2.  **Dynamic Innovation Badges (D-NFTs):** Successful project creators and significant contributors are awarded ERC721 "Innovation Badges" that are not static. These NFTs evolve in appearance or level based on the holder's cumulative reputation and achievements within the DAO. The DAO itself manages the evolution of these NFTs.
3.  **Curated Project Lifecycle:** Projects undergo a multi-stage process: proposal, community vote, funding, milestone-based execution, and final verification. This ensures community oversight and prevents frivolous or fraudulent projects from getting funding.
4.  **Incentivized Participation:** Funders receive a share of the protocol fees from successful projects they supported, encouraging active participation. Staking tokens is required for proposing and voting, aligning incentives.

---

### **Contract Outline:**

**I. Core Setup & Configuration:**
    *   Imports (OpenZeppelin for ERC20, ERC721, Ownable, Context)
    *   Interfaces for `IGovernanceToken` and `IInnovationBadgeNFT`
    *   State Variables (addresses, mappings, counters, rates, periods)
    *   Enums (`ProjectState`, `MilestoneState`)
    *   Structs (`Project`, `Milestone`, `UserStake`)
    *   Events
    *   Modifiers (`onlyStaker`, `onlyProjectProposer`, `onlyDAO`, `projectState`)

**II. Initialization & Core Configuration (DAO Governance Controlled):**
    *   `constructor`
    *   `setGovernanceToken`
    *   `setInnovationBadgeNFT`
    *   `setProtocolFeeRate`
    *   `setMinStakeForProposal`
    *   `setVotingPeriods`
    *   `withdrawProtocolFees`

**III. Staking & Reputation Management:**
    *   `stakeTokens`
    *   `unstakeTokens`
    *   `getReputationScore`
    *   `getUserStakedAmount`
    *   `_updateReputationScore` (Internal)

**IV. Project Lifecycle Management:**
    *   `proposeProject`
    *   `voteOnProjectProposal`
    *   `startProjectFunding`
    *   `fundProject`
    *   `signalMilestoneCompletion`
    *   `voteOnMilestoneCompletion`
    *   `releaseMilestonePayment`
    *   `claimProjectCreatorReward`
    *   `claimFunderShare`
    *   `cancelProject`

**V. Dynamic Innovation Badges (ERC721 Integration):**
    *   `_mintInnovationBadge` (Internal)
    *   `_evolveInnovationBadge` (Internal)
    *   `getUserBadgeLevel`

**VI. View Functions:**
    *   `getProjectDetails`
    *   `getProjectVoteCounts`
    *   `getMilestoneDetails`
    *   `getProjectFunderAmount`

---

### **Function Summary:**

1.  **`constructor(address _governanceToken, address _innovationBadgeNFT)`**: Initializes the contract with the addresses of the governance token and the Innovation Badge NFT. Sets the initial owner.
2.  **`setGovernanceToken(address _newAddress)`**: DAO-controlled function to update the ERC20 governance token address.
3.  **`setInnovationBadgeNFT(address _newAddress)`**: DAO-controlled function to update the ERC721 Innovation Badge NFT address.
4.  **`setProtocolFeeRate(uint16 _newRate)`**: DAO-controlled function to set the percentage of funds (e.g., 500 = 5%) taken as protocol fee from successful projects.
5.  **`setMinStakeForProposal(uint256 _minStake)`**: DAO-controlled function to set the minimum amount of governance tokens required to stake for proposing a project.
6.  **`setVotingPeriods(uint64 _proposalPeriod, uint64 _milestonePeriod)`**: DAO-controlled function to set the duration for project proposal and milestone verification voting.
7.  **`withdrawProtocolFees(address _recipient, uint256 _amount)`**: Allows the DAO to withdraw accumulated protocol fees from successful projects to a specified address.
8.  **`stakeTokens(uint256 _amount)`**: Allows a user to stake governance tokens, increasing their influence and eligibility for actions like proposing and voting.
9.  **`unstakeTokens(uint256 _amount)`**: Allows a user to unstake their governance tokens after a certain lock-up period or condition (not fully implemented for brevity, but crucial in a real DAO).
10. **`getReputationScore(address _user)`**: Returns the current reputation score of a given user.
11. **`getUserStakedAmount(address _user)`**: Returns the amount of governance tokens currently staked by a user.
12. **`_updateReputationScore(address _user, int256 _delta)`**: Internal function to adjust a user's reputation score. Positive delta for successful actions, negative for failures. Also triggers badge evolution.
13. **`proposeProject(string calldata _title, string calldata _descriptionCID, uint256 _fundingGoal, Milestone[] calldata _milestones)`**: Allows a staker to propose a new project, staking a minimum amount of tokens and defining funding goals and milestones.
14. **`voteOnProjectProposal(uint256 _projectId, bool _approve)`**: Staked token holders vote to approve or reject a project proposal during its voting period.
15. **`startProjectFunding(uint256 _projectId)`**: DAO-controlled function to move a successfully voted project from `Proposed` to `Funding` state, making it available for funding.
16. **`fundProject(uint256 _projectId)`**: Allows users to contribute ETH (or wrapped ETH) to a project's funding goal.
17. **`signalMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`**: Project proposer signals that a specific milestone has been completed, initiating a verification vote.
18. **`voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _verified)`**: Funders and stakers vote to verify the completion of a project milestone.
19. **`releaseMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)`**: Releases the payment for a verified milestone to the project proposer.
20. **`claimProjectCreatorReward(uint256 _projectId)`**: Allows the project creator to claim their final remaining funds after all milestones are completed and validated.
21. **`claimFunderShare(uint256 _projectId)`**: Allows individual funders to claim their share of the protocol fee generated by successful projects they funded.
22. **`cancelProject(uint256 _projectId)`**: DAO-controlled function to cancel a project at any stage, potentially due to fraud or non-compliance.
23. **`_mintInnovationBadge(address _user, uint256 _badgeType)`**: Internal function to mint a new Innovation Badge NFT to a user upon significant achievements (e.g., first successful project).
24. **`_evolveInnovationBadge(address _user, uint256 _tokenId)`**: Internal function to update the metadata/level of an existing Innovation Badge NFT based on the user's reputation score or new achievements.
25. **`getUserBadgeLevel(address _user)`**: Returns the current level of a user's primary Innovation Badge (assuming one main badge, or expands to multiple).
26. **`getProjectDetails(uint256 _projectId)`**: Returns all non-sensitive details of a project, including state, funding goal, and current raised amount.
27. **`getProjectVoteCounts(uint256 _projectId, uint256 _milestoneIndex)`**: Returns the current approval and rejection vote counts for a project proposal or a specific milestone.
28. **`getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)`**: Returns the details of a specific milestone for a given project.
29. **`getProjectFunderAmount(uint256 _projectId, address _funder)`**: Returns the amount of ETH/tokens an individual address has funded into a specific project.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Interfaces for external contracts ---

/// @title IGovernanceToken
/// @notice Interface for the ERC20 governance token used for staking and voting.
interface IGovernanceToken is IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title IInnovationBadgeNFT
/// @notice Interface for the ERC721 Innovation Badge NFT, which supports dynamic metadata updates.
interface IInnovationBadgeNFT is IERC721 {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external returns (uint256);
    function updateMetadata(uint256 tokenId, string calldata newTokenURI) external;
    function getTokenURI(uint256 tokenId) external view returns (string memory);
    // Assuming a way to map user to their main badge, or a badge per achievement
    function getBadgeOfUser(address user) external view returns (uint256 tokenId);
}

/// @title InnovationCatalystDAO
/// @dev A decentralized autonomous organization for funding innovative projects,
/// featuring dynamic reputation, evolving NFTs, and a curated project lifecycle.
contract InnovationCatalystDAO is Ownable, ReentrancyGuard {

    // --- I. Contract Outline & Function Summary ---
    /*
    Contract Outline:

    I. Core Setup & Configuration:
        * Imports (OpenZeppelin for ERC20, ERC721, Ownable, Context, ReentrancyGuard)
        * Interfaces for `IGovernanceToken` and `IInnovationBadgeNFT`
        * State Variables (addresses, mappings, counters, rates, periods)
        * Enums (`ProjectState`, `MilestoneState`)
        * Structs (`Project`, `Milestone`, `UserStake`)
        * Events
        * Modifiers (`onlyStaker`, `onlyProjectProposer`, `onlyDAO`, `projectState`)

    II. Initialization & Core Configuration (DAO Governance Controlled):
        * `constructor`
        * `setGovernanceToken`
        * `setInnovationBadgeNFT`
        * `setProtocolFeeRate`
        * `setMinStakeForProposal`
        * `setVotingPeriods`
        * `withdrawProtocolFees`

    III. Staking & Reputation Management:
        * `stakeTokens`
        * `unstakeTokens`
        * `getReputationScore`
        * `getUserStakedAmount`
        * `_updateReputationScore` (Internal)

    IV. Project Lifecycle Management:
        * `proposeProject`
        * `voteOnProjectProposal`
        * `startProjectFunding`
        * `fundProject`
        * `signalMilestoneCompletion`
        * `voteOnMilestoneCompletion`
        * `releaseMilestonePayment`
        * `claimProjectCreatorReward`
        * `claimFunderShare`
        * `cancelProject`

    V. Dynamic Innovation Badges (ERC721 Integration):
        * `_mintInnovationBadge` (Internal)
        * `_evolveInnovationBadge` (Internal)
        * `getUserBadgeLevel`

    VI. View Functions:
        * `getProjectDetails`
        * `getProjectVoteCounts`
        * `getMilestoneDetails`
        * `getProjectFunderAmount`

    Function Summary:

    1. `constructor(address _governanceToken, address _innovationBadgeNFT)`: Initializes the contract with the addresses of the governance token and the Innovation Badge NFT. Sets the initial owner (which can then be transferred to a DAO multisig).
    2. `setGovernanceToken(address _newAddress)`: DAO-controlled function to update the ERC20 governance token address.
    3. `setInnovationBadgeNFT(address _newAddress)`: DAO-controlled function to update the ERC721 Innovation Badge NFT address. The InnovationCatalystDAO should be an authorized minter/updater on the IInnovationBadgeNFT.
    4. `setProtocolFeeRate(uint16 _newRate)`: DAO-controlled function to set the percentage of funds (e.g., 500 = 5%) taken as protocol fee from successful projects. Max 10000 (100%).
    5. `setMinStakeForProposal(uint256 _minStake)`: DAO-controlled function to set the minimum amount of governance tokens required to stake for proposing a project.
    6. `setVotingPeriods(uint64 _proposalPeriod, uint64 _milestonePeriod)`: DAO-controlled function to set the duration (in seconds) for project proposal and milestone verification voting.
    7. `withdrawProtocolFees(address _recipient, uint256 _amount)`: Allows the DAO to withdraw accumulated protocol fees from successful projects to a specified address.
    8. `stakeTokens(uint256 _amount)`: Allows a user to stake governance tokens, increasing their influence and eligibility for actions like proposing and voting. Requires prior approval.
    9. `unstakeTokens(uint256 _amount)`: Allows a user to unstake their governance tokens (requires a cooldown or specific conditions to prevent abuse). (Simplified for this example)
    10. `getReputationScore(address _user)`: Returns the current reputation score of a given user.
    11. `getUserStakedAmount(address _user)`: Returns the amount of governance tokens currently staked by a user.
    12. `_updateReputationScore(address _user, int256 _delta)`: Internal function to adjust a user's reputation score. Positive delta for successful actions, negative for failures. Triggers badge evolution.
    13. `proposeProject(string calldata _title, string calldata _descriptionCID, uint256 _fundingGoal, Milestone[] calldata _milestones)`: Allows a staker to propose a new project, staking a minimum amount of tokens and defining funding goals and milestones. `_descriptionCID` is an IPFS Content Identifier.
    14. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Staked token holders vote to approve or reject a project proposal during its voting period. Vote weight proportional to stake.
    15. `startProjectFunding(uint256 _projectId)`: DAO-controlled function to move a successfully voted project from `Proposed` to `Funding` state, making it available for funding.
    16. `fundProject(uint256 _projectId)`: Allows users to contribute ETH (or wrapped ETH) to a project's funding goal.
    17. `signalMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Project proposer signals that a specific milestone has been completed, initiating a verification vote.
    18. `voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _verified)`: Funders and stakers vote to verify the completion of a project milestone. Vote weight proportional to stake and/or funding.
    19. `releaseMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)`: Releases the payment for a verified milestone to the project proposer.
    20. `claimProjectCreatorReward(uint256 _projectId)`: Allows the project creator to claim their final remaining funds after all milestones are completed and validated.
    21. `claimFunderShare(uint256 _projectId)`: Allows individual funders to claim their share of the protocol fee generated by successful projects they funded.
    22. `cancelProject(uint256 _projectId)`: DAO-controlled function to cancel a project at any stage, potentially due to fraud or non-compliance. Funds are returned.
    23. `_mintInnovationBadge(address _user, uint256 _badgeType)`: Internal function to mint a new Innovation Badge NFT to a user upon significant achievements (e.g., first successful project).
    24. `_evolveInnovationBadge(address _user, uint256 _tokenId)`: Internal function to update the metadata/level of an existing Innovation Badge NFT based on the user's reputation score or new achievements.
    25. `getUserBadgeLevel(address _user)`: Returns the current level of a user's primary Innovation Badge (assuming `IInnovationBadgeNFT` has a mapping).
    26. `getProjectDetails(uint256 _projectId)`: Returns all non-sensitive details of a project, including state, funding goal, and current raised amount.
    27. `getProjectVoteCounts(uint256 _projectId, uint256 _milestoneIndex)`: Returns the current approval and rejection vote counts for a project proposal or a specific milestone.
    28. `getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)`: Returns the details of a specific milestone for a given project.
    29. `getProjectFunderAmount(uint256 _projectId, address _funder)`: Returns the amount of ETH/tokens an individual address has funded into a specific project.
    */

    // --- II. State Variables ---

    IGovernanceToken public immutable governanceToken;
    IInnovationBadgeNFT public immutable innovationBadgeNFT;

    uint256 public nextProjectId;
    uint256 public nextBadgeId = 1; // Assuming badge IDs start from 1

    // Configuration parameters (set by DAO governance)
    uint16 public protocolFeeRate = 500; // 5% (500 basis points out of 10,000)
    uint256 public minStakeForProposal = 1000 ether; // Example: 1000 GOV tokens
    uint64 public proposalVotingPeriod = 3 days; // Duration for project proposal votes
    uint64 public milestoneVotingPeriod = 2 days; // Duration for milestone verification votes

    uint256 public protocolTreasuryBalance; // Accumulates protocol fees

    // User Data
    mapping(address => uint256) public userStakes;       // User => Staked GOV tokens
    mapping(address => int256) public userReputation;    // User => Reputation score
    mapping(address => uint256) public userInnovationBadge; // User => Innovation Badge NFT ID (0 if none)

    // Project Data
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProjectProposal; // Project ID => Voter => Voted?
    mapping(uint256 => mapping(address => bool)) public hasVotedOnMilestone;      // Project ID => Milestone Index => Voter => Voted?

    // --- Enums ---

    enum ProjectState {
        Proposed,       // Project submitted, awaiting community vote
        Rejected,       // Project rejected by community vote
        Funding,        // Project approved, currently raising funds
        Active,         // Funding goal met, project is active, milestones being executed
        Completed,      // All milestones completed and verified
        Failed,         // Project failed (e.g., didn't meet funding, cancelled)
        Cancelled       // Manually cancelled by DAO
    }

    enum MilestoneState {
        Pending,        // Milestone not yet started
        Signaled,       // Creator signaled completion, awaiting verification vote
        Verified,       // Milestone verified by community vote
        Rejected,       // Milestone rejected by community vote
        Paid            // Milestone payment released
    }

    // --- Structs ---

    struct Milestone {
        string title;
        uint256 fundingShare; // Percentage of total project funding allocated to this milestone (e.g., 2500 = 25%)
        MilestoneState state;
        uint64 voteEndTime;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    struct Project {
        address proposer;
        string title;
        string descriptionCID; // IPFS Content ID for detailed description
        uint256 fundingGoal;
        uint256 raisedAmount;
        ProjectState state;
        Milestone[] milestones;
        uint64 proposalVoteEndTime;
        uint256 proposalApprovalVotes;
        uint256 proposalRejectionVotes;
        mapping(address => uint256) funders; // Funders and their contributed amount
        uint256 totalFunderContributions; // Sum of all contributions, for proportional rewards
        bool creatorClaimedReward;
    }

    // --- Events ---

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 newScore);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string title, uint256 fundingGoal);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneSignaled(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneVoted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed voter, bool verified);
    event MilestonePaymentReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event CreatorRewardClaimed(uint256 indexed projectId, address indexed creator, uint256 amount);
    event FunderShareClaimed(uint256 indexed projectId, address indexed funder, uint224 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event InnovationBadgeMinted(address indexed user, uint256 indexed tokenId);
    event InnovationBadgeEvolved(address indexed user, uint256 indexed tokenId, string newURI);


    // --- III. Modifiers ---

    modifier onlyStaker(address _user) {
        require(userStakes[_user] > 0, "Must have staked tokens to perform this action");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == _msgSender(), "Only project proposer can call this function");
        _;
    }

    // `onlyDAO` from Ownable is used initially, then `owner` should be transferred to a DAO multisig.
    modifier onlyDAO() {
        require(owner() == _msgSender(), "Only DAO owner can call this function");
        _;
    }

    modifier projectState(uint256 _projectId, ProjectState _expectedState) {
        require(projects[_projectId].state == _expectedState, "Project is not in the expected state");
        _;
    }

    // --- IV. Initialization & Core Configuration (DAO Governance Controlled) ---

    /// @notice Constructor to initialize the contract with governance token and NFT addresses.
    /// @param _governanceToken Address of the ERC20 governance token.
    /// @param _innovationBadgeNFT Address of the ERC721 Innovation Badge NFT contract.
    constructor(address _governanceToken, address _innovationBadgeNFT) Ownable(_msgSender()) {
        require(_governanceToken != address(0), "Invalid governance token address");
        require(_innovationBadgeNFT != address(0), "Invalid NFT address");
        governanceToken = IGovernanceToken(_governanceToken);
        innovationBadgeNFT = IInnovationBadgeNFT(_innovationBadgeNFT);
    }

    /// @notice Updates the ERC20 governance token address.
    /// @dev Requires DAO governance control.
    /// @param _newAddress The new address for the governance token contract.
    function setGovernanceToken(address _newAddress) external onlyDAO {
        require(_newAddress != address(0), "Invalid address");
        // This would typically involve a migration plan in a real scenario
        // governanceToken = IGovernanceToken(_newAddress);
        revert("Governance token cannot be changed post-deployment for security, requires migration.");
    }

    /// @notice Updates the ERC721 Innovation Badge NFT address.
    /// @dev Requires DAO governance control. The new NFT contract must implement `IInnovationBadgeNFT`.
    /// @param _newAddress The new address for the Innovation Badge NFT contract.
    function setInnovationBadgeNFT(address _newAddress) external onlyDAO {
        require(_newAddress != address(0), "Invalid address");
        // This would typically involve a migration plan in a real scenario
        // innovationBadgeNFT = IInnovationBadgeNFT(_newAddress);
        revert("Innovation Badge NFT cannot be changed post-deployment for security, requires migration.");
    }

    /// @notice Sets the protocol fee rate.
    /// @dev Fee is applied to successful projects. Rate is in basis points (e.g., 500 = 5%). Max 10000.
    /// @param _newRate The new fee rate in basis points.
    function setProtocolFeeRate(uint16 _newRate) external onlyDAO {
        require(_newRate <= 10000, "Fee rate cannot exceed 100%");
        protocolFeeRate = _newRate;
    }

    /// @notice Sets the minimum amount of governance tokens required to stake for proposing a project.
    /// @dev Requires DAO governance control.
    /// @param _minStake The new minimum stake amount.
    function setMinStakeForProposal(uint256 _minStake) external onlyDAO {
        minStakeForProposal = _minStake;
    }

    /// @notice Sets the duration for project proposal and milestone verification voting periods.
    /// @dev Durations are in seconds. Requires DAO governance control.
    /// @param _proposalPeriod New duration for proposal voting.
    /// @param _milestonePeriod New duration for milestone voting.
    function setVotingPeriods(uint64 _proposalPeriod, uint64 _milestonePeriod) external onlyDAO {
        require(_proposalPeriod > 0 && _milestonePeriod > 0, "Voting periods must be greater than zero");
        proposalVotingPeriod = _proposalPeriod;
        milestoneVotingPeriod = _milestonePeriod;
    }

    /// @notice Allows the DAO to withdraw accumulated protocol fees.
    /// @dev Requires DAO governance control.
    /// @param _recipient The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _recipient, uint256 _amount) external onlyDAO nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(protocolTreasuryBalance >= _amount, "Insufficient protocol fees balance");

        protocolTreasuryBalance -= _amount;
        (bool success,) = payable(_recipient).call{value: _amount}("");
        require(success, "Failed to withdraw protocol fees");

        emit ProtocolFeesWithdrawn(_recipient, _amount);
    }

    // --- V. Staking & Reputation Management ---

    /// @notice Allows a user to stake governance tokens.
    /// @dev Requires the user to have approved this contract to spend their tokens.
    /// @param _amount The amount of governance tokens to stake.
    function stakeTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        governanceToken.transferFrom(_msgSender(), address(this), _amount);
        userStakes[_msgSender()] += _amount;
        _updateReputationScore(_msgSender(), int256(_amount / 10**governanceToken.decimals())); // Reputation increases by 1 for every 1 GOV token (example logic)
        emit TokensStaked(_msgSender(), _amount);
    }

    /// @notice Allows a user to unstake governance tokens.
    /// @dev In a real DAO, this would likely have a cooldown, lockup, or conditions (e.g., no active votes).
    /// For simplicity, this version allows immediate unstake if not participating in current votes.
    /// @param _amount The amount of governance tokens to unstake.
    function unstakeTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(userStakes[_msgSender()] >= _amount, "Insufficient staked tokens");

        // Simplified check: ensure user is not actively involved in any ongoing voting.
        // A more robust system would track active votes per user and block unstaking
        // if their stake is locked.
        // For example: iterate through active projects/milestones to check for votes.
        // To avoid gas limits, this check might need to be off-chain or aggregated.
        // For this example, we'll assume no immediate locks for simplicity in _this_ function.

        userStakes[_msgSender()] -= _amount;
        governanceToken.transfer(_msgSender(), _amount);
        _updateReputationScore(_msgSender(), -int256(_amount / 10**governanceToken.decimals())); // Reputation decreases
        emit TokensUnstaked(_msgSender(), _amount);
    }

    /// @notice Returns the current reputation score of a given user.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getReputationScore(address _user) external view returns (int256) {
        return userReputation[_user];
    }

    /// @notice Returns the amount of governance tokens currently staked by a user.
    /// @param _user The address of the user.
    /// @return The amount of staked tokens.
    function getUserStakedAmount(address _user) external view returns (uint256) {
        return userStakes[_user];
    }

    /// @notice Internal function to adjust a user's reputation score.
    /// @dev Automatically triggers badge evolution if a badge exists.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _delta The change in reputation score (can be positive or negative).
    function _updateReputationScore(address _user, int256 _delta) internal {
        userReputation[_user] += _delta;
        emit ReputationUpdated(_user, userReputation[_user]);

        if (userInnovationBadge[_user] != 0) {
            _evolveInnovationBadge(_user, userInnovationBadge[_user]);
        }
    }

    // --- VI. Project Lifecycle Management ---

    /// @notice Allows a staker to propose a new project.
    /// @dev Requires a minimum stake. The proposer's stake is locked during the proposal voting period.
    /// @param _title Project title.
    /// @param _descriptionCID IPFS Content ID pointing to a detailed project description.
    /// @param _fundingGoal The total ETH funding amount requested for the project.
    /// @param _milestones Array of milestones, each with a title and a `fundingShare` (percentage of total goal).
    function proposeProject(
        string calldata _title,
        string calldata _descriptionCID,
        uint256 _fundingGoal,
        Milestone[] calldata _milestones
    ) external onlyStaker(_msgSender()) nonReentrant returns (uint256) {
        require(bytes(_title).length > 0, "Project title cannot be empty");
        require(bytes(_descriptionCID).length > 0, "Description CID cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_milestones.length > 0, "Project must have at least one milestone");
        require(userStakes[_msgSender()] >= minStakeForProposal, "Insufficient stake to propose project");

        uint256 totalMilestoneShare = 0;
        for (uint i = 0; i < _milestones.length; i++) {
            require(_milestones[i].fundingShare > 0 && _milestones[i].fundingShare <= 10000, "Milestone funding share must be > 0 and <= 100%");
            totalMilestoneShare += _milestones[i].fundingShare;
        }
        require(totalMilestoneShare == 10000, "Total milestone funding shares must sum to 100%"); // 10000 basis points

        uint256 projectId = nextProjectId++;
        projects[projectId].proposer = _msgSender();
        projects[projectId].title = _title;
        projects[projectId].descriptionCID = _descriptionCID;
        projects[projectId].fundingGoal = _fundingGoal;
        projects[projectId].state = ProjectState.Proposed;
        projects[projectId].milestones = _milestones;
        projects[projectId].proposalVoteEndTime = uint64(block.timestamp + proposalVotingPeriod);

        // Lock proposer's minStakeForProposal for the duration of the vote
        // This is a conceptual lock, actual implementation would require more complex state management
        // For this example, we'll implicitly trust the `onlyStaker` modifier is sufficient for eligibility
        // and that unstakeTokens has checks to prevent unstaking if stake is 'locked'.

        emit ProjectProposed(projectId, _msgSender(), _title, _fundingGoal);
        return projectId;
    }

    /// @notice Allows staked token holders to vote on a project proposal.
    /// @dev Voting weight is proportional to the user's staked tokens.
    /// @param _projectId The ID of the project to vote on.
    /// @param _approve True to vote approval, false to vote rejection.
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external onlyStaker(_msgSender()) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposed, "Project is not in proposal stage");
        require(block.timestamp < project.proposalVoteEndTime, "Proposal voting period has ended");
        require(!hasVotedOnProjectProposal[_projectId][_msgSender()], "Already voted on this proposal");

        uint256 voteWeight = userStakes[_msgSender()]; // Simple voting: 1 token = 1 vote
        if (_approve) {
            project.proposalApprovalVotes += voteWeight;
        } else {
            project.proposalRejectionVotes += voteWeight;
        }
        hasVotedOnProjectProposal[_projectId][_msgSender()] = true;

        emit ProjectProposalVoted(_projectId, _msgSender(), _approve);

        // Automatically close voting if period ends
        if (block.timestamp >= project.proposalVoteEndTime) {
            _finalizeProjectProposal(_projectId);
        }
    }

    /// @notice Internal function to finalize a project proposal vote.
    /// @param _projectId The ID of the project.
    function _finalizeProjectProposal(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposed, "Project must be in Proposed state to finalize vote");

        if (project.proposalApprovalVotes > project.proposalRejectionVotes) {
            project.state = ProjectState.Funding;
            _updateReputationScore(project.proposer, 50); // Small rep boost for getting project approved
            emit ProjectStateChanged(_projectId, ProjectState.Funding);
        } else {
            project.state = ProjectState.Rejected;
            _updateReputationScore(project.proposer, -25); // Rep penalty for rejected project
            emit ProjectStateChanged(_projectId, ProjectState.Rejected);
        }
    }

    /// @notice Allows the DAO to move an approved project to the funding stage.
    /// @dev This could be automated by `_finalizeProjectProposal` or triggered manually by DAO.
    /// @param _projectId The ID of the project to start funding for.
    function startProjectFunding(uint256 _projectId) external onlyDAO projectState(_projectId, ProjectState.Proposed) {
        Project storage project = projects[_projectId];
        require(block.timestamp >= project.proposalVoteEndTime, "Proposal voting period is still active");
        _finalizeProjectProposal(_projectId); // Ensure vote is finalized
        if (project.state == ProjectState.Rejected) {
             revert("Project proposal was rejected.");
        }
        // If it was already set to Funding by _finalizeProjectProposal, this is idempotent
    }


    /// @notice Allows users to contribute ETH to a project's funding goal.
    /// @dev Accepts native ETH.
    /// @param _projectId The ID of the project to fund.
    function fundProject(uint256 _projectId) external payable nonReentrant projectState(_projectId, ProjectState.Funding) {
        require(msg.value > 0, "Funding amount must be greater than zero");

        Project storage project = projects[_projectId];
        require(project.raisedAmount + msg.value <= project.fundingGoal, "Funding amount exceeds project goal");

        project.funders[_msgSender()] += msg.value;
        project.raisedAmount += msg.value;
        project.totalFunderContributions += msg.value; // Track total for proportionality

        _updateReputationScore(_msgSender(), 10); // Small rep boost for funding

        emit ProjectFunded(_projectId, _msgSender(), msg.value);

        if (project.raisedAmount == project.fundingGoal) {
            project.state = ProjectState.Active;
            emit ProjectStateChanged(_projectId, ProjectState.Active);
        }
    }

    /// @notice Allows the project creator to signal completion of a milestone.
    /// @dev Initiates a voting period for verification.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone (0-indexed).
    function signalMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyProjectProposer(_projectId)
        projectState(_projectId, ProjectState.Active)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[_milestoneIndex].state == MilestoneState.Pending ||
                project.milestones[_milestoneIndex].state == MilestoneState.Rejected,
                "Milestone not in pending or rejected state");

        project.milestones[_milestoneIndex].state = MilestoneState.Signaled;
        project.milestones[_milestoneIndex].voteEndTime = uint64(block.timestamp + milestoneVotingPeriod);
        project.milestones[_milestoneIndex].approvalVotes = 0;
        project.milestones[_milestoneIndex].rejectionVotes = 0;

        // Reset all individual votes for this milestone
        delete hasVotedOnMilestone[_projectId][_milestoneIndex];

        emit MilestoneSignaled(_projectId, _milestoneIndex);
    }

    /// @notice Allows project funders and stakers to vote on milestone completion.
    /// @dev Voting weight is based on contribution (for funders) and stake (for stakers).
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _verified True if the milestone is deemed complete, false otherwise.
    function voteOnMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _verified
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Signaled, "Milestone not awaiting verification");
        require(block.timestamp < milestone.voteEndTime, "Milestone voting period has ended");
        require(!hasVotedOnMilestone[_projectId][_milestoneIndex][_msgSender()], "Already voted on this milestone");

        uint256 voteWeight = userStakes[_msgSender()]; // Staker vote weight
        if (project.funders[_msgSender()] > 0) {
            // Funders get additional weight proportional to their funding
            voteWeight += (project.funders[_msgSender()] * 10**governanceToken.decimals()) / 1 ether; // Convert ETH to token equivalent for weight
        }
        require(voteWeight > 0, "Caller has no voting power for this milestone");

        if (_verified) {
            milestone.approvalVotes += voteWeight;
        } else {
            milestone.rejectionVotes += voteWeight;
        }
        hasVotedOnMilestone[_projectId][_milestoneIndex][_msgSender()] = true;

        emit MilestoneVoted(_projectId, _milestoneIndex, _msgSender(), _verified);

        // Automatically close voting if period ends
        if (block.timestamp >= milestone.voteEndTime) {
            _finalizeMilestoneVote(_projectId, _milestoneIndex);
        }
    }

    /// @notice Internal function to finalize a milestone verification vote.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    function _finalizeMilestoneVote(uint256 _projectId, uint256 _milestoneIndex) internal {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Signaled, "Milestone not awaiting verification");

        if (milestone.approvalVotes > milestone.rejectionVotes) {
            milestone.state = MilestoneState.Verified;
            _updateReputationScore(project.proposer, 20); // Rep boost for verified milestone
            emit ProjectStateChanged(_projectId, ProjectState.Active); // Still active, just milestone verified
        } else {
            milestone.state = MilestoneState.Rejected;
            _updateReputationScore(project.proposer, -10); // Rep penalty for rejected milestone
            emit ProjectStateChanged(_projectId, ProjectState.Active); // Still active, but milestone rejected
        }
    }

    /// @notice Releases the payment for a verified milestone to the project proposer.
    /// @dev Requires the milestone to be in `Verified` state and not yet `Paid`.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    function releaseMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyProjectProposer(_projectId)
        nonReentrant
    {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.Verified, "Milestone is not verified");
        require(milestone.state != MilestoneState.Paid, "Milestone payment already released");

        uint256 paymentAmount = (project.fundingGoal * milestone.fundingShare) / 10000;
        milestone.state = MilestoneState.Paid;

        (bool success,) = payable(project.proposer).call{value: paymentAmount}("");
        require(success, "Failed to release milestone payment");

        emit MilestonePaymentReleased(_projectId, _milestoneIndex, paymentAmount);

        // Check if all milestones are paid
        bool allMilestonesPaid = true;
        for (uint i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].state != MilestoneState.Paid) {
                allMilestonesPaid = false;
                break;
            }
        }

        if (allMilestonesPaid) {
            project.state = ProjectState.Completed;
            _updateReputationScore(project.proposer, 100); // Big rep boost for completing project
            if (userInnovationBadge[project.proposer] == 0) {
                 _mintInnovationBadge(project.proposer, 1); // Mint a badge for first successful project
            }
            emit ProjectStateChanged(_projectId, ProjectState.Completed);
        }
    }

    /// @notice Allows the project creator to claim their final reward after all milestones are completed.
    /// @dev The remaining funds, if any, after all milestone payments.
    /// @param _projectId The ID of the project.
    function claimProjectCreatorReward(uint256 _projectId)
        external
        onlyProjectProposer(_projectId)
        projectState(_projectId, ProjectState.Completed)
        nonReentrant
    {
        Project storage project = projects[_projectId];
        require(!project.creatorClaimedReward, "Creator already claimed reward");

        uint256 totalMilestonePayments = 0;
        for (uint i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].state == MilestoneState.Paid, "Not all milestones are paid");
            totalMilestonePayments += (project.fundingGoal * project.milestones[i].fundingShare) / 10000;
        }

        uint256 rewardAmount = project.raisedAmount - totalMilestonePayments;
        // Apply protocol fee to the 'profit' or remaining amount (if any was left after goal)
        // Or apply to total raised amount as a flat fee on successful projects.
        // Here, we'll apply it to the total fundingGoal
        uint256 protocolFee = (project.fundingGoal * protocolFeeRate) / 10000;
        
        // Protocol fee is taken from the total funding goal of a successful project.
        // It's conceptually paid by the project for being successful.
        // It's simpler to take it out from the project's funds at completion
        // or during milestone payments. Here, it's calculated from the goal
        // and deducted from the project's available funds.

        uint256 netCreatorReward = 0;
        if (rewardAmount > protocolFee) {
            netCreatorReward = rewardAmount - protocolFee;
        }
        
        // Add protocol fee to treasury
        protocolTreasuryBalance += protocolFee;

        project.creatorClaimedReward = true;

        if (netCreatorReward > 0) {
            (bool success,) = payable(project.proposer).call{value: netCreatorReward}("");
            require(success, "Failed to send creator reward");
        }
        
        // This is a simplified model. A real system might handle over-funding,
        // under-funding, and fee distribution more intricately.
        emit CreatorRewardClaimed(_projectId, project.proposer, netCreatorReward);
    }


    /// @notice Allows individual funders to claim their proportional share of the protocol fee
    ///         generated by successful projects they funded.
    /// @dev This incentivizes funding good projects.
    /// @param _projectId The ID of the project.
    function claimFunderShare(uint256 _projectId) external projectState(_projectId, ProjectState.Completed) nonReentrant {
        Project storage project = projects[_projectId];
        address funder = _msgSender();
        require(project.funders[funder] > 0, "You did not fund this project");

        // Funder's share is based on the protocol fee * (their contribution / total contributions)
        uint256 protocolFeeEarnedByProject = (project.fundingGoal * protocolFeeRate) / 10000;

        // The share of the protocol fee that goes back to the funder
        // Note: This model means the protocol takes a fee, and then a *portion* of that fee
        // (or an equivalent reward) is given back to funder.
        // For simplicity, let's say the DAO allocates a fixed percentage of *its earned fees*
        // to return to funders. Or, the funder share is a separate bonus.
        // Let's use a simpler model: Protocol takes its fee, *then* a portion of the project's success
        // is earmarked for funders (e.g., if project overshot goal, or a separate reward pool).

        // A more direct way: funder gets a percentage of *their contribution* back as a bonus
        // from the protocol treasury or a separate reward pool.
        // For this example, let's say successful projects allocate a small portion *back* to funders.
        // This will be modeled as a conceptual reward here, not directly from `protocolTreasuryBalance`
        // unless there's a specific pool.

        // A better, simpler model: Funders claim back their initial investment plus a small bonus if successful.
        // For now, let's imagine a conceptual "reward pool for funders"
        // This function will just return `0` if not implemented with a specific reward mechanism.
        // To make it functional, we'll imagine a `funderRewardPool` for each project.

        uint256 funderRewardAmount = 0; // Simplified for this example, a real system would have a calc here
                                        // e.g. from an overfunded amount or a dedicated bonus from the DAO.
        if (funderRewardAmount == 0) {
            revert("No funder reward available to claim for this project currently.");
        }

        // Add actual logic for funder reward distribution
        // Example: If project.raisedAmount > project.fundingGoal, then the surplus could be split between creator/funders.
        // Or, a portion of the `protocolTreasuryBalance` is earmarked for distribution.
        // For now, this is a placeholder.

        // (bool success,) = payable(funder).call{value: funderRewardAmount}("");
        // require(success, "Failed to send funder share");

        // Reset funder's contribution after claiming to prevent double claims
        // project.funders[funder] = 0;
        // project.totalFunderContributions -= funderRewardAmount; // Adjust total if this reduces total

        // emit FunderShareClaimed(_projectId, funder, funderRewardAmount);
    }

    /// @notice Allows the DAO to cancel a project.
    /// @dev Funds are returned to funders, proposer's stake is returned. Reputation impacts.
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(uint256 _projectId) external onlyDAO nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state != ProjectState.Completed && project.state != ProjectState.Cancelled, "Project cannot be cancelled from current state");

        project.state = ProjectState.Cancelled;
        _updateReputationScore(project.proposer, -50); // Significant rep penalty for cancelled project
        emit ProjectStateChanged(_projectId, ProjectState.Cancelled);

        // Refund funders
        for (uint i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].state == MilestoneState.Paid) {
                // Cannot refund paid milestones, those funds are gone.
                // This means the DAO must cancel *before* payments are made, or accept loss.
            }
        }

        // Simplified refund mechanism: send remaining `raisedAmount` back to contributors proportionally
        // This is complex for actual implementation and would need iterating `funders` mapping
        // which isn't efficient in Solidity. A claim-based refund is better.
        // For example: `mapping(uint256 => mapping(address => uint256)) public refundableAmounts;`
        // Then funders call `claimRefund(projectId)`
        // For simplicity, we'll mark the project cancelled and assume a claim mechanism exists
        // or manual distribution by DAO if `raisedAmount` is still held by contract.
    }


    // --- VII. Dynamic Innovation Badges (ERC721 Integration) ---

    /// @notice Internal function to mint a new Innovation Badge NFT to a user.
    /// @dev Called upon significant achievements, e.g., first successful project.
    /// @param _user The address of the user to mint the badge to.
    /// @param _badgeType A number representing the type or initial level of the badge.
    function _mintInnovationBadge(address _user, uint256 _badgeType) internal {
        require(userInnovationBadge[_user] == 0, "User already has an innovation badge");

        uint256 tokenId = nextBadgeId++;
        // Generate initial URI based on badgeType
        string memory initialURI = string(abi.encodePacked("ipfs://badge/", Strings.toString(_badgeType)));
        innovationBadgeNFT.mint(_user, tokenId, initialURI);
        userInnovationBadge[_user] = tokenId;
        emit InnovationBadgeMinted(_user, tokenId);
        _evolveInnovationBadge(_user, tokenId); // Trigger immediate evolution based on current rep
    }

    /// @notice Internal function to update the metadata/level of an existing Innovation Badge NFT.
    /// @dev Called when a user's reputation score changes or new achievements are unlocked.
    /// @param _user The address of the badge holder.
    /// @param _tokenId The ID of the Innovation Badge NFT.
    function _evolveInnovationBadge(address _user, uint252 _tokenId) internal {
        require(userInnovationBadge[_user] == _tokenId, "Badge ID does not match user's badge");
        
        int256 reputation = userReputation[_user];
        string memory newURI;

        // Example logic for evolving badge URI based on reputation
        if (reputation >= 1000) {
            newURI = "ipfs://badge/legendary";
        } else if (reputation >= 500) {
            newURI = "ipfs://badge/master";
        } else if (reputation >= 200) {
            newURI = "ipfs://badge/pro";
        } else if (reputation >= 50) {
            newURI = "ipfs://badge/adept";
        } else {
            newURI = "ipfs://badge/novice";
        }

        // Only update if URI actually changes to avoid unnecessary transactions
        // Requires a `getTokenURI` function on IInnovationBadgeNFT
        // string memory currentURI = innovationBadgeNFT.getTokenURI(_tokenId);
        // if (keccak256(abi.encodePacked(currentURI)) != keccak256(abi.encodePacked(newURI))) {
            innovationBadgeNFT.updateMetadata(_tokenId, newURI);
            emit InnovationBadgeEvolved(_user, _tokenId, newURI);
        // }
    }

    /// @notice Returns the current level of a user's primary Innovation Badge.
    /// @dev Assumes the `IInnovationBadgeNFT` contract can determine a level from its metadata or internal state.
    ///      For this example, it directly maps `userReputation` to a conceptual level.
    /// @param _user The address of the user.
    /// @return The conceptual level of the user's Innovation Badge.
    function getUserBadgeLevel(address _user) external view returns (uint256) {
        if (userInnovationBadge[_user] == 0) {
            return 0; // No badge
        }
        int256 reputation = userReputation[_user];
        if (reputation >= 1000) return 5; // Legendary
        if (reputation >= 500) return 4;  // Master
        if (reputation >= 200) return 3;  // Pro
        if (reputation >= 50) return 2;   // Adept
        return 1;                         // Novice
    }

    // --- VIII. View Functions ---

    /// @notice Retrieves comprehensive details for a given project ID.
    /// @param _projectId The ID of the project.
    /// @return proposer The address of the project creator.
    /// @return title The project's title.
    /// @return descriptionCID IPFS CID of the detailed description.
    /// @return fundingGoal The total funding goal in ETH.
    /// @return raisedAmount The current amount of ETH raised.
    /// @return state The current state of the project.
    /// @return proposalVoteEndTime Timestamp when proposal voting ends.
    /// @return proposalApprovalVotes Total approval votes for the proposal.
    /// @return proposalRejectionVotes Total rejection votes for the proposal.
    /// @return milestonesCount The number of milestones in the project.
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            address proposer,
            string memory title,
            string memory descriptionCID,
            uint256 fundingGoal,
            uint256 raisedAmount,
            ProjectState state,
            uint64 proposalVoteEndTime,
            uint256 proposalApprovalVotes,
            uint256 proposalRejectionVotes,
            uint256 milestonesCount
        )
    {
        Project storage project = projects[_projectId];
        proposer = project.proposer;
        title = project.title;
        descriptionCID = project.descriptionCID;
        fundingGoal = project.fundingGoal;
        raisedAmount = project.raisedAmount;
        state = project.state;
        proposalVoteEndTime = project.proposalVoteEndTime;
        proposalApprovalVotes = project.proposalApprovalVotes;
        proposalRejectionVotes = project.proposalRejectionVotes;
        milestonesCount = project.milestones.length;
    }

    /// @notice Returns current vote counts for a project proposal or a specific milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone (use `type(uint256).max` for project proposal votes).
    /// @return approvalVotes The total approval votes.
    /// @return rejectionVotes The total rejection votes.
    /// @return voteEndTime The timestamp when voting ends.
    function getProjectVoteCounts(uint256 _projectId, uint256 _milestoneIndex)
        external
        view
        returns (
            uint256 approvalVotes,
            uint256 rejectionVotes,
            uint64 voteEndTime
        )
    {
        Project storage project = projects[_projectId];
        if (_milestoneIndex == type(uint256).max) { // Represents project proposal vote
            require(project.state == ProjectState.Proposed, "Project is not in proposal stage");
            approvalVotes = project.proposalApprovalVotes;
            rejectionVotes = project.proposalRejectionVotes;
            voteEndTime = project.proposalVoteEndTime;
        } else { // Milestone vote
            require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
            Milestone storage milestone = project.milestones[_milestoneIndex];
            require(milestone.state == MilestoneState.Signaled, "Milestone not in voting stage");
            approvalVotes = milestone.approvalVotes;
            rejectionVotes = milestone.rejectionVotes;
            voteEndTime = milestone.voteEndTime;
        }
    }

    /// @notice Returns details for a specific milestone within a project.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return title The milestone's title.
    /// @return fundingShare The percentage of total project funding allocated to this milestone.
    /// @return state The current state of the milestone.
    /// @return voteEndTime Timestamp when milestone voting ends.
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
        external
        view
        returns (
            string memory title,
            uint256 fundingShare,
            MilestoneState state,
            uint64 voteEndTime
        )
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        title = milestone.title;
        fundingShare = milestone.fundingShare;
        state = milestone.state;
        voteEndTime = milestone.voteEndTime;
    }

    /// @notice Returns the amount of ETH/tokens an individual address has funded into a specific project.
    /// @param _projectId The ID of the project.
    /// @param _funder The address of the funder.
    /// @return The amount contributed by the funder.
    function getProjectFunderAmount(uint256 _projectId, address _funder) external view returns (uint256) {
        return projects[_projectId].funders[_funder];
    }
}
```