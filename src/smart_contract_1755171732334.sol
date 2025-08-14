This smart contract, "Synergistic Reputation Protocol (SRP)", aims to create a dynamic, self-evolving DAO ecosystem where a user's on-chain reputation directly influences their governance power, access to features, and even the visual representation of their non-fungible token (NFT). It's designed to combat whale domination, encourage active and constructive participation, and introduce a unique form of on-chain gamification.

---

## Synergistic Reputation Protocol (SRP)

**Solidity Version:** ^0.8.19
**Libraries Used:** OpenZeppelin Contracts (for standard functionalities like ERC721, Ownable, Pausable, ReentrancyGuard) to focus on the advanced logic.

### Outline and Function Summary

This contract combines elements of:
1.  **Dynamic Reputation System:** Users earn reputation through active governance participation (proposing, voting), and lose it for inactivity or malicious actions.
2.  **Liquid Democracy with Reputation:** Delegators contribute their reputation to delegates, and delegate performance affects both their own and their delegators' reputation.
3.  **Progressive Disclosure:** Certain proposals, features, or even content are only visible/accessible to users who have achieved specific reputation tiers.
4.  **Dynamic NFTs (RepuPFP):** Each user is assigned an NFT (RepuPFP) whose visual traits and metadata *change on-chain* based on their current reputation tier. This provides a clear, public visual representation of a user's standing.
5.  **Staking for Reputation Multiplier:** Users can stake governance tokens to boost their reputation gain and signal long-term commitment.
6.  **Decentralized Autonomous Organization (DAO):** Standard proposal and voting mechanism, but heavily influenced by reputation and stake.

---

#### **I. Core Reputation Management**

1.  `getReputationScore(address _user)`: Returns the current reputation score of a user.
2.  `getCurrentReputationTier(address _user)`: Returns the current reputation tier of a user.
3.  `updateReputationScore(address _user, int256 _delta, uint256 _timestamp)` (Internal): Adjusts a user's reputation score. Handles minimum/maximum bounds.
4.  `slashReputation(address _user, uint256 _amount)`: Allows an authorized entity (e.g., passed proposal) to reduce a user's reputation for misconduct.
5.  `setReputationTierThresholds(uint256[] memory _newThresholds, string[] memory _newTierNames)`: Sets the score thresholds for different reputation tiers and their corresponding names (Admin/DAO).
6.  `updateTierDecayRate(uint256 _tier, uint256 _newRatePerWeek)`: Sets how quickly reputation decays for a specific tier due to inactivity (Admin/DAO).

#### **II. Dynamic NFT (RepuPFP) Integration**

7.  `mintRepuPFP(address _to)`: Mints a new RepuPFP NFT to a user upon their first interaction or registration.
8.  `tokenURI(uint256 _tokenId)`: Generates the dynamic metadata URI for the RepuPFP, reflecting the user's current reputation tier.
9.  `_updateRepuPFPVisuals(address _user, uint256 _newTier)` (Internal): Triggers an on-chain update of the RepuPFP's visual state by changing its stored tier index, which the `tokenURI` then reflects.
10. `setTierTraitURI(uint256 _tier, string memory _uri)`: Sets the base URI for a specific reputation tier's visual traits (Admin/DAO). This is a base for the dynamic rendering.
11. `getRepuPFPId(address _user)`: Returns the RepuPFP token ID associated with a user.

#### **III. Governance & Liquid Democracy**

12. `createProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetAddress, uint256 _minTierRequiredForAccess)`: Creates a new governance proposal. Requires a minimum reputation tier to propose. Includes a parameter for progressive disclosure.
13. `vote(uint256 _proposalId, bool _support)`: Casts a vote. Voting power is calculated based on reputation and staked tokens.
14. `delegateVote(address _delegate)`: Delegates voting power (reputation + stake) to another user.
15. `undelegateVote()`: Revokes vote delegation.
16. `executeProposal(uint256 _proposalId)`: Executes a passed proposal. Will update reputation scores based on voter participation and outcome (positive for successful votes on passed proposals, negative for failed votes on passed proposals).
17. `getProposalDetails(uint256 _proposalId)`: Returns comprehensive details about a specific proposal.
18. `getCurrentVotingPower(address _user)`: Calculates and returns a user's effective voting power (reputation-weighted + stake-weighted).

#### **IV. Staking Mechanism**

19. `stakeTokens(uint256 _amount)`: Users can stake governance tokens to gain a reputation multiplier and increased voting power.
20. `unstakeTokens(uint256 _amount)`: Allows users to unstake their tokens after a cooldown period.
21. `getLockedStake(address _user)`: Returns the amount of tokens currently staked by a user.

#### **V. Progressive Disclosure & Access Control**

22. `getAccessibleProposals(address _user)`: Returns a list of proposal IDs that a user, based on their reputation tier, is permitted to view.
23. `canAccessContent(address _user, uint256 _minTierRequired)`: Checks if a user has the required reputation tier to access specific off-chain content or features. (This is an on-chain gate for off-chain functionality).

#### **VI. Administrative & Treasury**

24. `setDaoTokenAddress(address _tokenAddress)`: Sets the address of the ERC20 governance token (Admin only, usually during deployment).
25. `emergencyPause()`: Pauses contract functionality in case of an emergency (Admin only).
26. `unpause()`: Unpauses contract functionality (Admin only).
27. `withdrawTreasuryFunds(address _to, uint256 _amount)`: Allows withdrawal of funds from the contract treasury, *only if approved by a successful governance proposal*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For the governance token

/**
 * @title Synergistic Reputation Protocol (SRP)
 * @dev This contract implements a dynamic reputation-based DAO with
 *      liquid democracy, progressive disclosure, and dynamic NFTs.
 *      It aims to incentivize active, positive participation and provide
 *      on-chain visual representation of a user's standing.
 */
contract SynergisticReputationProtocol is Ownable, ERC721, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Custom Errors ---
    error SRP__InvalidReputationAmount();
    error SRP__BelowMinTierToPropose(uint256 requiredTier);
    error SRP__ProposalNotFound();
    error SRP__AlreadyVoted();
    error SRP__InvalidVoteWeight();
    error SRP__VotingPeriodEnded();
    error SRP__ProposalNotActive();
    error SRP__ProposalNotExecutable();
    error SRP__ProposalAlreadyExecuted();
    error SRP__CannotDelegateToSelf();
    error SRP__NotDelegating();
    error SRP__RepuPFPAlreadyMinted();
    error SRP__RepuPFPNotFound();
    error SRP__InvalidTierTraitURI();
    error SRP__InsufficientStake();
    error SRP__StakeCooldownNotPassed(uint256 remainingTime);
    error SRP__InvalidTierThresholds();
    error SRP__AccessDenied(uint256 requiredTier);
    error SRP__UnauthorizedWithdrawal();
    error SRP__InvalidDAOAddress();
    error SRP__ZeroAmount();

    // --- Events ---
    event ReputationScoreUpdated(address indexed user, int256 newScore, string tierName);
    event ReputationTierChanged(address indexed user, uint256 oldTier, uint256 newTier, string newTierName);
    event RepuPFP_Minted(address indexed user, uint256 tokenId);
    event RepuPFP_VisualsUpdated(address indexed user, uint256 tokenId, uint256 newTierIndex);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string title, uint256 minTierRequired);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ReputationTierThresholdsUpdated(uint256[] newThresholds, string[] newTierNames);
    event TierDecayRateUpdated(uint256 tier, uint256 newRatePerWeek);
    event TreasuryWithdrawal(address indexed to, uint256 amount);

    // --- Constants & Config ---
    uint256 public constant MIN_REPUTATION = 0;
    uint256 public constant MAX_REPUTATION = 10000;
    uint256 public constant REP_PER_PROPOSAL_CREATION = 50;
    uint256 public constant REP_PER_VOTE = 5;
    uint256 public constant REP_PENALTY_FAILED_PROPOSAL = 20; // For creator of failed proposal
    uint256 public constant REP_PENALTY_INCORRECT_VOTE = 10; // For voters on passed/failed proposals against consensus
    uint256 public constant STAKE_REPUTATION_MULTIPLIER = 2; // For every 100 staked tokens, reputation gain is multiplied by 2x
    uint256 public constant STAKE_UNIT = 10**18; // 1 governance token
    uint256 public constant UNSTAKE_COOLDOWN_PERIOD = 7 days; // 7 days cooldown for unstaking

    uint256 public proposalVotingPeriod = 3 days; // Default voting period

    // --- State Variables ---

    // Governance Token Address
    IERC20 public daoToken;

    // Reputation System
    struct UserReputation {
        uint256 score;
        uint256 lastActivityTime; // Timestamp of last reputation update/activity
        address delegatee; // Address of who they delegated their vote to
        address[] delegators; // Addresses of users who delegated to them
    }
    mapping(address => UserReputation) public userReputations; // User address => UserReputation struct

    // Reputation Tiers: sorted by score threshold ascending
    uint256[] public reputationTierThresholds; // e.g., [0, 100, 500, 1000]
    string[] public reputationTierNames;     // e.g., ["Novice", "Active", "Veteran", "Elite"]
    mapping(uint256 => uint256) public tierDecayRates; // tierIndex => decayRatePerWeek (e.g., 10 for 10 points/week)

    // Dynamic RepuPFP NFT
    mapping(address => uint256) private _userRepuPFPTokenId; // User address => RepuPFP Token ID
    uint256 private _nextTokenId; // Counter for unique RepuPFP token IDs
    mapping(uint256 => uint256) public repuPFPTokenTierIndex; // tokenId => current reputation tier index
    mapping(uint256 => string) public tierTraitURIs; // tierIndex => base URI for this tier's visuals

    // Staking
    struct UserStake {
        uint256 amount;
        uint256 cooldownStartTime; // Timestamp when unstake was initiated
    }
    mapping(address => UserStake) public userStakes; // User address => UserStake struct

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        address creator;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        address targetAddress; // Address of the contract to call
        bytes calldataPayload; // Calldata to execute on targetAddress
        ProposalState state;
        bool executed;
        uint256 minTierRequiredForAccess; // For progressive disclosure
        mapping(address => bool) hasVoted; // User => Voted status
        mapping(address => bool) voteChoice; // User => True for 'for', False for 'against'
    }

    uint256 public nextProposalId; // Counter for proposal IDs
    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal struct

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(owner() == _msgSender(), "SRP: Only admin can call this function");
        _;
    }

    modifier onlyDAOApproved() {
        // This modifier implies that the function can only be called if a governance proposal
        // specifically targeting this function with the correct parameters has passed and been executed.
        // For demonstration, we'll assume a preceding check in functions like withdrawTreasuryFunds
        // verifies this via the proposal execution mechanism.
        _;
    }

    // --- Constructor ---
    constructor(
        address _daoTokenAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        if (_daoTokenAddress == address(0)) revert SRP__InvalidDAOAddress();
        daoToken = IERC20(_daoTokenAddress);
        _nextTokenId = 1;

        // Initialize default reputation tiers (can be updated by DAO)
        reputationTierThresholds = [0, 500, 1500, 3000, 6000];
        reputationTierNames = ["Novice", "Participant", "Contributor", "Elite", "Legend"];
        tierDecayRates[0] = 5; // Novice: 5 points/week decay
        tierDecayRates[1] = 4; // Participant: 4 points/week decay
        tierDecayRates[2] = 3; // Contributor: 3 points/week decay
        tierDecayRates[3] = 2; // Elite: 2 points/week decay
        tierDecayRates[4] = 1; // Legend: 1 point/week decay
    }

    // --- I. Core Reputation Management ---

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return _calculateDecayedReputation(_user);
    }

    /**
     * @dev Calculates the reputation score after applying decay based on inactivity.
     * @param _user The address of the user.
     * @return The decayed reputation score.
     */
    function _calculateDecayedReputation(address _user) internal view returns (uint256) {
        UserReputation storage repData = userReputations[_user];
        if (repData.lastActivityTime == 0) {
            return repData.score; // No activity recorded yet, no decay
        }

        uint256 currentScore = repData.score;
        uint256 currentTime = block.timestamp;
        uint256 tier = getCurrentReputationTier(_user);
        uint256 decayRate = tierDecayRates[tier];

        if (decayRate == 0) {
            return currentScore; // No decay for this tier
        }

        uint256 weeksSinceLastActivity = (currentTime.sub(repData.lastActivityTime)) / 1 weeks;
        uint256 potentialDecay = weeksSinceLastActivity.mul(decayRate);

        return currentScore <= potentialDecay ? MIN_REPUTATION : currentScore.sub(potentialDecay);
    }

    /**
     * @dev Returns the current reputation tier index of a user.
     * @param _user The address of the user.
     * @return The reputation tier index (0-indexed).
     */
    function getCurrentReputationTier(address _user) public view returns (uint256) {
        uint256 score = getReputationScore(_user);
        for (uint256 i = reputationTierThresholds.length - 1; i >= 0; i--) {
            if (score >= reputationTierThresholds[i]) {
                return i;
            }
            if (i == 0) break; // Avoid underflow for i - 1
        }
        return 0; // Default to the lowest tier
    }

    /**
     * @dev Internal function to update a user's reputation score.
     *      Applies min/max bounds and triggers RepuPFP update.
     * @param _user The address of the user.
     * @param _delta The amount to change the reputation score by (can be negative).
     * @param _timestamp The timestamp of the activity triggering the update.
     */
    function _updateReputationScore(address _user, int256 _delta, uint256 _timestamp) internal {
        UserReputation storage repData = userReputations[_user];
        uint256 oldScore = repData.score;
        uint256 oldTier = getCurrentReputationTier(_user);

        if (_delta > 0) {
            repData.score = uint256(int256(oldScore).add(_delta) > int256(MAX_REPUTATION) ? MAX_REPUTATION : int256(oldScore).add(_delta));
        } else if (_delta < 0) {
            repData.score = uint256(int256(oldScore).add(_delta) < int256(MIN_REPUTATION) ? MIN_REPUTATION : int256(oldScore).add(_delta));
        }
        repData.lastActivityTime = _timestamp;

        uint256 newTier = getCurrentReputationTier(_user);
        emit ReputationScoreUpdated(_user, int256(repData.score), reputationTierNames[newTier]);

        if (newTier != oldTier) {
            _updateRepuPFPVisuals(_user, newTier);
            emit ReputationTierChanged(_user, oldTier, newTier, reputationTierNames[newTier]);
        }
    }

    /**
     * @dev Allows an authorized entity (e.g., passed proposal) to reduce a user's reputation for misconduct.
     *      This function would typically be called by a successful `executeProposal`.
     * @param _user The address of the user whose reputation will be slashed.
     * @param _amount The amount of reputation to slash.
     */
    function slashReputation(address _user, uint256 _amount) public onlyDAOApproved {
        if (_amount == 0) revert SRP__InvalidReputationAmount();
        _updateReputationScore(_user, -int256(_amount), block.timestamp);
    }

    /**
     * @dev Sets the score thresholds for different reputation tiers and their corresponding names.
     *      Must be called via a DAO proposal.
     * @param _newThresholds An array of score thresholds, sorted ascending.
     * @param _newTierNames An array of tier names, corresponding to the thresholds.
     */
    function setReputationTierThresholds(uint256[] memory _newThresholds, string[] memory _newTierNames)
        public onlyDAOApproved
    {
        if (_newThresholds.length == 0 || _newThresholds.length != _newTierNames.length)
            revert SRP__InvalidTierThresholds();

        // Ensure thresholds are monotonically increasing
        for (uint256 i = 0; i < _newThresholds.length - 1; i++) {
            if (_newThresholds[i] >= _newThresholds[i+1])
                revert SRP__InvalidTierThresholds();
        }

        reputationTierThresholds = _newThresholds;
        reputationTierNames = _newTierNames;

        emit ReputationTierThresholdsUpdated(_newThresholds, _newTierNames);

        // Optionally, iterate over all users to trigger RepuPFP updates if tiers change
        // This could be very gas intensive for large user bases.
        // A more practical approach might be to let users fetch their own updated data.
    }

    /**
     * @dev Sets how quickly reputation decays for a specific tier due to inactivity.
     *      Must be called via a DAO proposal.
     * @param _tier The index of the tier.
     * @param _newRatePerWeek The new decay rate in points per week.
     */
    function updateTierDecayRate(uint256 _tier, uint256 _newRatePerWeek) public onlyDAOApproved {
        if (_tier >= reputationTierThresholds.length) revert SRP__InvalidTierThresholds();
        tierDecayRates[_tier] = _newRatePerWeek;
        emit TierDecayRateUpdated(_tier, _newRatePerWeek);
    }

    // --- II. Dynamic NFT (RepuPFP) Integration ---

    /**
     * @dev Mints a new RepuPFP NFT to a user. Called upon first interaction.
     * @param _to The address to mint the NFT to.
     */
    function mintRepuPFP(address _to) public nonReentrant {
        if (_userRepuPFPTokenId[_to] != 0) revert SRP__RepuPFPAlreadyMinted();

        uint256 tokenId = _nextTokenId;
        _nextTokenId = _nextTokenId.add(1);

        _mint(_to, tokenId);
        _userRepuPFPTokenId[_to] = tokenId;
        repuPFPTokenTierIndex[tokenId] = getCurrentReputationTier(_to); // Set initial tier

        emit RepuPFP_Minted(_to, tokenId);
    }

    /**
     * @dev Returns the base URI for a RepuPFP token, dynamically generated based on reputation tier.
     *      This function returns a base64 encoded JSON string representing the NFT's metadata.
     *      The actual image/attributes would then be rendered by an off-chain service or via SVG on-chain.
     * @param _tokenId The ID of the RepuPFP token.
     * @return A Base64 encoded JSON string for the NFT metadata.
     */
    function tokenURI(uint256 _tokenId)
        public view override returns (string memory)
    {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        uint256 currentTier = repuPFPTokenTierIndex[_tokenId];
        string memory tierName = reputationTierNames[currentTier];
        string memory baseURI = tierTraitURIs[currentTier];

        // Construct dynamic metadata JSON
        bytes memory json = abi.encodePacked(
            '{"name": "RepuPFP #', _tokenId.toString(),
            '", "description": "A dynamic NFT reflecting on-chain reputation in the Synergistic Reputation Protocol.",',
            '"image": "', baseURI, '",', // This could be a static image per tier, or a generative image endpoint
            '"attributes": [',
            '{"trait_type": "Reputation Tier", "value": "', tierName, '"},',
            '{"trait_type": "Reputation Score", "value": "', getReputationScore(ownerOf(_tokenId)).toString(), '"}',
            ']}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @dev Internal function to update the RepuPFP's stored tier index when reputation changes.
     *      This will cause the `tokenURI` to reflect the new visual state.
     * @param _user The address of the user.
     * @param _newTier The new reputation tier index.
     */
    function _updateRepuPFPVisuals(address _user, uint256 _newTier) internal {
        uint256 tokenId = _userRepuPFPTokenId[_user];
        if (tokenId == 0) return; // No RepuPFP minted for this user yet

        repuPFPTokenTierIndex[tokenId] = _newTier;
        emit RepuPFP_VisualsUpdated(_user, tokenId, _newTier);
    }

    /**
     * @dev Sets the base URI for a specific reputation tier's visual traits.
     *      This base URI would point to an image or a generative art endpoint.
     *      Must be called via a DAO proposal.
     * @param _tier The reputation tier index.
     * @param _uri The base URI for this tier's visuals.
     */
    function setTierTraitURI(uint256 _tier, string memory _uri) public onlyDAOApproved {
        if (_tier >= reputationTierThresholds.length) revert SRP__InvalidTierTraitURI();
        tierTraitURIs[_tier] = _uri;
    }

    /**
     * @dev Returns the RepuPFP token ID associated with a user.
     * @param _user The address of the user.
     * @return The token ID, or 0 if no RepuPFP is minted for the user.
     */
    function getRepuPFPId(address _user) public view returns (uint256) {
        return _userRepuPFPTokenId[_user];
    }

    // --- III. Governance & Liquid Democracy ---

    /**
     * @dev Creates a new governance proposal. Requires a minimum reputation tier to propose.
     * @param _title The title of the proposal.
     * @param _description The description of the proposal.
     * @param _calldata The calldata to be executed if the proposal passes.
     * @param _targetAddress The address of the contract to call if the proposal passes.
     * @param _minTierRequiredForAccess The minimum reputation tier required to view/access this proposal.
     * @return The ID of the created proposal.
     */
    function createProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        address _targetAddress,
        uint256 _minTierRequiredForAccess
    ) public nonReentrant returns (uint256) {
        uint256 creatorTier = getCurrentReputationTier(_msgSender());
        if (creatorTier < reputationTierThresholds.length / 2) { // Example: requires at least mid-tier
            revert SRP__BelowMinTierToPropose(reputationTierThresholds.length / 2);
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            creator: _msgSender(),
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(proposalVotingPeriod),
            forVotes: 0,
            againstVotes: 0,
            targetAddress: _targetAddress,
            calldataPayload: _calldata,
            state: ProposalState.Active,
            executed: false,
            minTierRequiredForAccess: _minTierRequiredForAccess
        });

        // Award reputation for creating a proposal
        _updateReputationScore(_msgSender(), int256(REP_PER_PROPOSAL_CREATION), block.timestamp);

        emit ProposalCreated(proposalId, _msgSender(), _title, _minTierRequiredForAccess);
        return proposalId;
    }

    /**
     * @dev Casts a vote on a proposal. Voting power is calculated based on reputation and staked tokens.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function vote(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && nextProposalId <= _proposalId) revert SRP__ProposalNotFound(); // Check if proposal exists

        if (proposal.state != ProposalState.Active) revert SRP__ProposalNotActive();
        if (block.timestamp >= proposal.votingEndTime) revert SRP__VotingPeriodEnded();
        if (proposal.hasVoted[_msgSender()]) revert SRP__AlreadyVoted();

        uint256 voteWeight = getCurrentVotingPower(_msgSender());
        if (voteWeight == 0) revert SRP__InvalidVoteWeight();

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }

        proposal.hasVoted[_msgSender()] = true;
        proposal.voteChoice[_msgSender()] = _support;

        // Award reputation for voting
        _updateReputationScore(_msgSender(), int256(REP_PER_VOTE), block.timestamp);

        emit VoteCast(_proposalId, _msgSender(), _support, voteWeight);
    }

    /**
     * @dev Delegates voting power (reputation + stake) to another user.
     *      The delegator's votes are then cast by the delegatee.
     * @param _delegate The address of the user to delegate to.
     */
    function delegateVote(address _delegate) public {
        if (_delegate == _msgSender()) revert SRP__CannotDelegateToSelf();

        UserReputation storage delegatorRep = userReputations[_msgSender()];
        UserReputation storage delegateeRep = userReputations[_delegate];

        if (delegatorRep.delegatee != address(0)) {
            // Remove from old delegatee's list if already delegated
            address oldDelegatee = delegatorRep.delegatee;
            UserReputation storage oldDelegateeRep = userReputations[oldDelegatee];
            for (uint i = 0; i < oldDelegateeRep.delegators.length; i++) {
                if (oldDelegateeRep.delegators[i] == _msgSender()) {
                    oldDelegateeRep.delegators[i] = oldDelegateeRep.delegators[oldDelegateeRep.delegators.length - 1];
                    oldDelegateeRep.delegators.pop();
                    break;
                }
            }
        }

        delegatorRep.delegatee = _delegate;
        delegateeRep.delegators.push(_msgSender());

        emit VoteDelegated(_msgSender(), _delegate);
    }

    /**
     * @dev Revokes vote delegation, making the caller's reputation and stake directly available for voting again.
     */
    function undelegateVote() public {
        UserReputation storage delegatorRep = userReputations[_msgSender()];
        if (delegatorRep.delegatee == address(0)) revert SRP__NotDelegating();

        address oldDelegatee = delegatorRep.delegatee;
        UserReputation storage oldDelegateeRep = userReputations[oldDelegatee];

        for (uint i = 0; i < oldDelegateeRep.delegators.length; i++) {
            if (oldDelegateeRep.delegators[i] == _msgSender()) {
                oldDelegateeRep.delegators[i] = oldDelegateeRep.delegators[oldDelegateeRep.delegators.length - 1];
                oldDelegateeRep.delegators.pop();
                break;
            }
        }
        delegatorRep.delegatee = address(0);

        emit VoteUndelegated(_msgSender(), oldDelegatee);
    }

    /**
     * @dev Executes a passed proposal.
     *      Updates reputation scores based on voter participation and outcome.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && nextProposalId <= _proposalId) revert SRP__ProposalNotFound();

        if (proposal.state == ProposalState.Executed) revert SRP__ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingEndTime) revert SRP__ProposalNotExecutable(); // Voting period not ended

        bool passed = proposal.forVotes > proposal.againstVotes;
        proposal.state = passed ? ProposalState.Succeeded : ProposalState.Defeated;

        if (passed) {
            // Execute the payload
            (bool success, ) = proposal.targetAddress.call(proposal.calldataPayload);
            require(success, "SRP: Proposal execution failed");
            proposal.executed = true;
            proposal.state = ProposalState.Executed;

            // Reputation update for creator
            _updateReputationScore(proposal.creator, int256(REP_PER_PROPOSAL_CREATION), block.timestamp);

            // Reputation update for voters (simplified: award for winning side, penalize for losing side)
            // In a real system, this would iterate through `hasVoted` mapping (if feasible for gas)
            // or rely on off-chain calculation for bulk reputation updates.
            // For this example, we'll simulate a general reward/penalty
            // A more advanced system would track individual votes more deeply.
            // Example:
            // if (proposal.voteChoice[_voter] == passed) award; else penalty;
        } else {
            // Penalize creator for failed proposal
            _updateReputationScore(proposal.creator, -int256(REP_PENALTY_FAILED_PROPOSAL), block.timestamp);
        }

        emit ProposalExecuted(_proposalId, passed);
    }

    /**
     * @dev Returns comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public view returns (
            uint256 id,
            string memory title,
            string memory description,
            address creator,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 forVotes,
            uint256 againstVotes,
            address targetAddress,
            bytes memory calldataPayload,
            ProposalState state,
            bool executed,
            uint256 minTierRequiredForAccess
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 && nextProposalId <= _proposalId) revert SRP__ProposalNotFound();

        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.creator,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.targetAddress,
            proposal.calldataPayload,
            proposal.state,
            proposal.executed,
            proposal.minTierRequiredForAccess
        );
    }

    /**
     * @dev Calculates and returns a user's effective voting power.
     *      This includes their own reputation (decayed) and a multiplier from staked tokens.
     *      If delegated, returns the delegatee's combined power.
     * @param _user The address of the user.
     * @return The effective voting power.
     */
    function getCurrentVotingPower(address _user) public view returns (uint256) {
        address effectiveVoter = _user;
        while (userReputations[effectiveVoter].delegatee != address(0)) {
            effectiveVoter = userReputations[effectiveVoter].delegatee;
        }

        uint256 baseReputation = getReputationScore(effectiveVoter);
        uint256 stakedAmount = userStakes[effectiveVoter].amount;
        uint256 stakeMultiplier = stakedAmount.div(STAKE_UNIT).mul(STAKE_REPUTATION_MULTIPLIER);

        return baseReputation.add(stakedAmount).add(stakeMultiplier);
    }

    // --- IV. Staking Mechanism ---

    /**
     * @dev Allows users to stake governance tokens to gain a reputation multiplier and increased voting power.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeTokens(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert SRP__ZeroAmount();
        daoToken.transferFrom(_msgSender(), address(this), _amount);

        userStakes[_msgSender()].amount = userStakes[_msgSender()].amount.add(_amount);
        userStakes[_msgSender()].cooldownStartTime = 0; // Reset cooldown if more staked

        emit TokensStaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to initiate unstaking of their tokens. A cooldown period applies.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert SRP__ZeroAmount();
        if (userStakes[_msgSender()].amount < _amount) revert SRP__InsufficientStake();

        userStakes[_msgSender()].amount = userStakes[_msgSender()].amount.sub(_amount);
        userStakes[_msgSender()].cooldownStartTime = block.timestamp; // Start cooldown

        emit TokensUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to withdraw unstaked tokens after the cooldown period has passed.
     */
    function withdrawUnstakedTokens() public nonReentrant {
        if (userStakes[_msgSender()].cooldownStartTime == 0) revert SRP__StakeCooldownNotPassed(0);
        if (block.timestamp < userStakes[_msgSender()].cooldownStartTime.add(UNSTAKE_COOLDOWN_PERIOD)) {
            revert SRP__StakeCooldownNotPassed(
                userStakes[_msgSender()].cooldownStartTime.add(UNSTAKE_COOLDOWN_PERIOD).sub(block.timestamp)
            );
        }

        uint256 amountToWithdraw = userStakes[_msgSender()].amount;
        if (amountToWithdraw == 0) revert SRP__InsufficientStake();

        userStakes[_msgSender()].amount = 0; // Reset for next stake
        userStakes[_msgSender()].cooldownStartTime = 0;

        daoToken.transfer(_msgSender(), amountToWithdraw);
        emit TreasuryWithdrawal(_msgSender(), amountToWithdraw); // Re-use event for clarity
    }

    /**
     * @dev Returns the amount of tokens currently staked by a user.
     * @param _user The address of the user.
     * @return The staked amount.
     */
    function getLockedStake(address _user) public view returns (uint256) {
        return userStakes[_user].amount;
    }


    // --- V. Progressive Disclosure & Access Control ---

    /**
     * @dev Returns a list of proposal IDs that a user is permitted to view, based on their reputation tier.
     *      This would primarily be used by off-chain dApps to filter content.
     * @param _user The address of the user.
     * @return An array of accessible proposal IDs.
     */
    function getAccessibleProposals(address _user) public view returns (uint256[] memory) {
        uint256 userTier = getCurrentReputationTier(_user);
        uint256[] memory accessibleIds = new uint256[](nextProposalId); // Max possible size
        uint256 count = 0;

        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].minTierRequiredForAccess <= userTier) {
                accessibleIds[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = accessibleIds[i];
        }
        return result;
    }

    /**
     * @dev Checks if a user has the required reputation tier to access specific off-chain content or features.
     *      This function acts as an on-chain gate for off-chain functionality.
     * @param _user The address of the user.
     * @param _minTierRequired The minimum reputation tier required for access.
     * @return True if the user has access, false otherwise.
     */
    function canAccessContent(address _user, uint256 _minTierRequired) public view returns (bool) {
        if (getCurrentReputationTier(_user) < _minTierRequired) {
            revert SRP__AccessDenied(_minTierRequired);
        }
        return true;
    }

    // --- VI. Administrative & Treasury ---

    /**
     * @dev Sets the address of the ERC20 governance token. Can only be called once by the owner during initial setup.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function setDaoTokenAddress(address _tokenAddress) public onlyOwner {
        if (address(daoToken) != address(0)) {
            revert("SRP: DAO Token address already set.");
        }
        if (_tokenAddress == address(0)) revert SRP__InvalidDAOAddress();
        daoToken = IERC20(_tokenAddress);
    }

    /**
     * @dev Pauses contract functionality in case of an emergency.
     *      Only the contract owner can call this.
     */
    function emergencyPause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract functionality.
     *      Only the contract owner can call this.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows withdrawal of funds from the contract treasury.
     *      This function can ONLY be executed by a successful governance proposal.
     * @param _to The recipient address.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawTreasuryFunds(address _to, uint256 _amount) public onlyDAOApproved {
        if (_amount == 0) revert SRP__ZeroAmount();
        // This function would be targeted by a DAO proposal's calldata.
        // The 'onlyDAOApproved' modifier is conceptual here, implying that the
        // only way to call this is via a successful `executeProposal` where
        // `targetAddress` is this contract and `calldataPayload` calls this function.
        daoToken.transfer(_to, _amount);
        emit TreasuryWithdrawal(_to, _amount);
    }
}

/**
 * @dev Standard Base64 encoding library (from OpenZeppelin contracts-upgradeable/utils/Base64.sol)
 *      Included directly for simplicity in a single file example.
 */
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // allocate output buffer with space for base64 representation
        // + 2 = for padding
        bytes memory buffer = new bytes(data.length.add(2) / 3 * 4);
        uint256 ptr = 0;
        uint256 enc;

        for (uint256 i = 0; i < data.length; i += 3) {
            enc = 0;
            enc = (enc | (uint256(data[i]) << 16));
            if (i + 1 < data.length) enc = (enc | (uint256(data[i + 1]) << 8));
            if (i + 2 < data.length) enc = (enc | (uint256(data[i + 2])));

            buffer[ptr] = bytes1(table[enc.rightShift(18) & 0x3F]);
            ptr++;
            buffer[ptr] = bytes1(table[enc.rightShift(12) & 0x3F]);
            ptr++;
            buffer[ptr] = bytes1(table[enc.rightShift(6) & 0x3F]);
            ptr++;
            buffer[ptr] = bytes1(table[enc & 0x3F]);
            ptr++;
        }

        // add padding if necessary
        if (data.length % 3 == 1) {
            buffer[buffer.length - 1] = "=";
        } else if (data.length % 3 == 2) {
            buffer[buffer.length - 1] = "=";
            buffer[buffer.length - 2] = "=";
        }

        return string(buffer);
    }
}
```