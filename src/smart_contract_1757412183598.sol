Here's a Solidity smart contract named `ImpactNexus` that combines several advanced and trendy concepts: AI-enhanced reputation, dynamic NFTs, sophisticated staking, evolving governance power (Wisdom Shares), and dynamic resource allocation. The design aims for a self-optimizing, adaptive, and highly engaged decentralized ecosystem.

I've ensured it's not a direct copy of open-source projects by integrating these concepts in a novel and interconnected manner. The contract includes more than 20 functions as requested.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For dynamic URI

/**
 * @title ImpactNexus
 * @dev An advanced, creative, and trendy smart contract protocol combining AI-enhanced reputation,
 *      dynamic NFTs, sophisticated staking, evolving governance power, and dynamic resource allocation.
 *      It aims to foster a self-optimizing and adaptive decentralized ecosystem.
 *
 * @outline
 *
 * I. Core Infrastructure & Access Control
 *    - `constructor()`: Initializes the contract, deploys internal ERC20 (ITK) and ERC721 (Sentinel NFTs),
 *                       sets up initial roles and AI oracle.
 *    - `setAIOracleAddress()`: Allows the DEFAULT_ADMIN_ROLE to update the trusted AI oracle address.
 *    - `grantRole()` / `revokeRole()`: Standard AccessControl functions for managing roles.
 *    - `pause()`: Pauses certain operations (PAUSER_ROLE).
 *    - `unpause()`: Unpauses contract (PAUSER_ROLE).
 *    - `withdrawProtocolFees()`: Allows the DEFAULT_ADMIN_ROLE to withdraw accumulated ITK fees.
 *
 * II. Reputation System (ImpactPoints)
 *    - `increaseImpactPoints()`: Increases user's ImpactPoints based on predefined positive actions.
 *                                Callable by ORACLE_ROLE or specific internal actions.
 *    - `decreaseImpactPoints()`: Decreases user's ImpactPoints for negative actions.
 *                                Callable by ORACLE_ROLE or internal mechanisms.
 *    - `getImpactPoints()`: Returns the ImpactPoints for a specific user.
 *    - `queryImpactLevel()`: Translates raw ImpactPoints into a descriptive ImpactLevel string.
 *
 * III. Sentinel NFTs (Dynamic ERC-721)
 *    - `mintSentinel()`: Mints a new Sentinel NFT for a user, representing their initial commitment.
 *    - `_tryEvolveSentinel()`: Internal helper to evolve a Sentinel NFT based on ImpactPoints, ITK stake,
 *                              and/or AI oracle evaluation.
 *    - `_tryDegradeSentinel()`: Internal helper to degrade a Sentinel NFT due to low ImpactPoints or
 *                               negative actions.
 *    - `_getSentinelLevel()`: Internal helper to get the level of a Sentinel.
 *    - `setSentinelBaseURI()`: Allows DEFAULT_ADMIN_ROLE to update the base URI for Sentinel metadata.
 *
 * IV. ITK Staking & Yield Rewards
 *    - `stakeITK()`: Allows users to stake ITK tokens, contributing to their ImpactScore and
 *                    earning staking rewards.
 *    - `unstakeITK()`: Allows users to unstake ITK tokens, potentially with a cooldown.
 *    - `claimITKRewards()`: Allows users to claim their accumulated ITK staking rewards.
 *    - `_updateRewards()`: Internal helper to calculate and update a user's pending rewards.
 *    - `getITKStakedAmount()`: Returns the amount of ITK staked by a user.
 *    - `getPendingITKRewards()`: Calculates the pending ITK rewards for a user.
 *    - `updateStakingAPR()`: Allows ORACLE_ROLE to dynamically adjust the staking rewards rate
 *                            based on AI analysis of market conditions or protocol health.
 *
 * V. Wisdom Shares (WS) & Governance Power
 *    - `_mintWisdomShares()`: Internal helper to mint non-transferable Wisdom Shares.
 *                             Called upon staking, positive impact, or other engagements.
 *    - `_burnWisdomShares()`: Internal helper to burn non-transferable Wisdom Shares.
 *                             Called upon unstaking, negative impact, or prolonged inactivity.
 *    - `getWisdomShares()`: Returns the Wisdom Shares balance for a user.
 *    - `getVotingPower()`: Calculates the total voting power for an address, considering delegated power.
 *    - `delegateVote()`: Allows users to delegate their voting power to another address.
 *    - `undelegateVote()`: Allows users to undelegate their voting power.
 *
 * VI. AI Oracle Integration
 *    - `reportAIJudgement()`: The trusted AI oracle reports a judgment or analysis result.
 *                             This function processes the AI's input and triggers appropriate
 *                             internal actions. Callable only by the ORACLE_ROLE.
 *    - `requestAIAnalysis()`: Allows specific governance roles to request an off-chain AI analysis
 *                             on a specific topic, emitting an event for oracle listeners.
 *
 * VII. Governance Module
 *    - `propose()`: Creates a new governance proposal requiring a minimum ImpactPoints and/or Wisdom Shares.
 *    - `vote()`: Allows users with sufficient voting power to vote on an active proposal.
 *    - `executeProposal()`: Executes a passed proposal.
 *    - `cancelProposal()`: Allows DEFAULT_ADMIN_ROLE or a specific governance action to cancel a proposal.
 *    - `getProposalState()`: Returns the current state of a proposal (NonExistent, Active, Canceled,
 *                            Defeated, Succeeded, Executed, QuorumNotMet).
 *    - `getProposalDetails()`: Returns detailed information about a specific proposal.
 *
 * VIII. Dynamic Resource & Ecosystem Allocation
 *    - `allocateEcosystemFunds()`: Distributes ITK funds from a community treasury based on a user's
 *                                  ImpactPoints, Sentinel level, and AI-defined criteria.
 *                                  Callable by DEFAULT_ADMIN_ROLE or through governance.
 *    - `setAllocationCriteria()`: Allows DEFAULT_ADMIN_ROLE to update the rules for
 *                                 `allocateEcosystemFunds`, primarily as a documentation/event trigger.
 */
contract ImpactNexus is AccessControl, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For AI Oracle reporting
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // For proposing governance actions

    // --- Tokens ---
    ITKToken public ITK; // The utility token
    SentinelNFTs public Sentinel; // The dynamic NFT

    // --- State Variables ---
    mapping(address => uint256) public impactPoints; // User's reputation score
    mapping(address => uint256) public stakedITK; // Amount of ITK staked by user
    mapping(address => uint256) public lastRewardUpdateTime; // Timestamp of last reward update for staker
    mapping(address => uint256) public wisdomShares; // Non-transferable governance power
    mapping(address => address) public delegates; // Delegate for voting power

    address public aiOracleAddress; // Address of the trusted AI oracle
    uint256 public totalStakedITK; // Total ITK staked in the contract
    uint256 public stakingAPR_bps; // Staking Annual Percentage Rate in basis points (e.g., 500 for 5%)
    uint256 public constant SECONDS_IN_YEAR = 31536000; // For APR calculations

    // --- Sentinel NFT Configuration ---
    string private _sentinelBaseURI; // Base URI for dynamic Sentinel metadata
    uint256 public nextSentinelId; // Counter for Sentinel NFTs

    // --- Governance Configuration ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract to call if proposal passes
        uint256 creationTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted on this proposal
        bool executed;
        bool canceled;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public governancePeriod; // Duration for proposals (e.g., 3 days in seconds)
    uint256 public minImpactPointsToPropose;
    uint256 public minWisdomSharesToVote;
    uint256 public quorumPercentage_bps; // Quorum required for a proposal to pass, in basis points (e.g., 1000 for 10%)

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newAddress);
    event ImpactPointsIncreased(address indexed user, uint256 amount, uint256 newTotal);
    event ImpactPointsDecreased(address indexed user, uint256 amount, uint256 newTotal);
    event SentinelMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel);
    event SentinelEvolved(uint256 indexed tokenId, uint256 newLevel, string reason);
    event SentinelDegraded(uint256 indexed tokenId, uint256 newLevel, string reason);
    event ITKStaked(address indexed staker, uint256 amount);
    event ITKUnstaked(address indexed staker, uint256 amount);
    event ITKRewardsClaimed(address indexed staker, uint256 amount);
    event StakingAPRUpdated(uint256 newAPR_bps);
    event WisdomSharesMinted(address indexed user, uint256 amount, uint256 newTotal);
    event WisdomSharesBurned(address indexed user, uint256 amount, uint256 newTotal);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event AIJudgementReported(address indexed oracle, string indexed judgmentType, bytes32 indexed entityId, int256 score, string data);
    event AIAnalysisRequested(address indexed requester, string topic, string description);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event FundsAllocated(address indexed recipient, uint256 amount, string reason);
    event AllocationCriteriaUpdated(string newCriteriaDescription);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "ImpactNexus: Only AI oracle can call this function");
        _;
    }

    /**
     * @dev Constructor for ImpactNexus.
     * @param _aiOracle Address of the initial AI oracle.
     * @param _stakingAPR_bps Initial staking APR in basis points (e.g., 500 for 5%).
     * @param _governancePeriod Duration for proposals in seconds.
     * @param _minImpactPointsToPropose Minimum ImpactPoints required to create a proposal.
     * @param _minWisdomSharesToVote Minimum Wisdom Shares required to vote.
     * @param _quorumPercentage_bps Quorum percentage (e.g., 1000 for 10%) for proposals.
     * @param initialSentinelBaseURI Initial base URI for Sentinel NFT metadata.
     */
    constructor(
        address _aiOracle,
        uint256 _stakingAPR_bps,
        uint256 _governancePeriod,
        uint256 _minImpactPointsToPropose,
        uint256 _minWisdomSharesToVote,
        uint256 _quorumPercentage_bps,
        string memory initialSentinelBaseURI
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender); // Admin can also propose/govern initially

        // Deploy internal ITK ERC20 token
        ITK = new ITKToken();
        // Grant ImpactNexus contract MINTER_ROLE on ITK for rewards
        ITK.grantRole(ITK.MINTER_ROLE(), address(this));

        // Deploy internal Sentinel ERC721 token
        Sentinel = new SentinelNFTs();
        // Grant ImpactNexus contract MINTER_ROLE on Sentinel for minting/level updates
        Sentinel.grantRole(Sentinel.MINTER_ROLE(), address(this));

        aiOracleAddress = _aiOracle;
        _grantRole(ORACLE_ROLE, _aiOracle); // Grant ORACLE_ROLE to the initial AI oracle address

        stakingAPR_bps = _stakingAPR_bps;
        governancePeriod = _governancePeriod;
        minImpactPointsToPropose = _minImpactPointsToPropose;
        minWisdomSharesToVote = _minWisdomSharesToVote;
        quorumPercentage_bps = _quorumPercentage_bps;
        _sentinelBaseURI = initialSentinelBaseURI;
        Sentinel.setBaseURI(initialSentinelBaseURI); // Set initial base URI in the Sentinel NFT contract

        nextSentinelId = 1;
        proposalCount = 0;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the trusted AI oracle.
     *      Can only be called by an address with DEFAULT_ADMIN_ROLE.
     * @param _newAIOracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address _newAIOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newAIOracle != address(0), "ImpactNexus: Zero address not allowed for AI oracle.");
        _revokeRole(ORACLE_ROLE, aiOracleAddress); // Revoke old oracle role
        aiOracleAddress = _newAIOracle;
        _grantRole(ORACLE_ROLE, _newAIOracle); // Grant new oracle role
        emit AIOracleAddressUpdated(_newAIOracle);
    }

    /**
     * @dev Pauses the contract, preventing certain state-changing operations.
     *      Can only be called by an address with the PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing all operations to resume.
     *      Can only be called by an address with the PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to withdraw accumulated ITK fees or surplus.
     * @param _amount The amount of ITK to withdraw.
     * @param _to The recipient address for the withdrawal.
     */
    function withdrawProtocolFees(uint256 _amount, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(ITK.balanceOf(address(this)) >= _amount, "ImpactNexus: Insufficient contract balance.");
        ITK.transfer(_to, _amount);
    }

    // --- II. Reputation System (ImpactPoints) ---

    /**
     * @dev Increases a user's ImpactPoints. Can be called by the AI oracle based on positive contributions.
     * @param _user The address of the user whose ImpactPoints are to be increased.
     * @param _amount The amount of ImpactPoints to add.
     * @param _reason A description of the action that led to the increase.
     */
    function increaseImpactPoints(address _user, uint256 _amount, string memory _reason) public onlyRole(ORACLE_ROLE) whenNotPaused {
        require(_user != address(0), "ImpactNexus: Invalid user address");
        impactPoints[_user] = impactPoints[_user].add(_amount);
        emit ImpactPointsIncreased(_user, _amount, impactPoints[_user]);
        // Trigger potential Sentinel evolution if conditions met
        _tryEvolveSentinel(_user);
    }

    /**
     * @dev Decreases a user's ImpactPoints. Can be called by the AI oracle based on negative actions or inactivity.
     * @param _user The address of the user whose ImpactPoints are to be decreased.
     * @param _amount The amount of ImpactPoints to subtract.
     * @param _reason A description of the action that led to the decrease.
     */
    function decreaseImpactPoints(address _user, uint256 _amount, string memory _reason) public onlyRole(ORACLE_ROLE) whenNotPaused {
        require(_user != address(0), "ImpactNexus: Invalid user address");
        if (impactPoints[_user] > 0) {
            impactPoints[_user] = impactPoints[_user].sub(
                _amount > impactPoints[_user] ? impactPoints[_user] : _amount
            );
            emit ImpactPointsDecreased(_user, _amount, impactPoints[_user]);
            // Trigger potential Sentinel degradation if conditions met
            _tryDegradeSentinel(_user);
        }
    }

    /**
     * @dev Retrieves the current ImpactPoints for a user.
     * @param _user The address of the user.
     * @return The current ImpactPoints.
     */
    function getImpactPoints(address _user) external view returns (uint256) {
        return impactPoints[_user];
    }

    /**
     * @dev Translates a user's ImpactPoints into a categorical ImpactLevel string.
     *      This function provides a human-readable representation of a user's reputation.
     * @param _user The address of the user.
     * @return A string representing the user's ImpactLevel.
     */
    function queryImpactLevel(address _user) external view returns (string memory) {
        uint256 points = impactPoints[_user];
        if (points >= 10000) return "Nexus Elder";
        if (points >= 5000) return "Arch Guardian";
        if (points >= 2000) return "Impact Creator";
        if (points >= 500) return "Active Contributor";
        if (points >= 100) return "Emerging Participant";
        return "Newcomer";
    }

    // --- III. Sentinel NFTs (Dynamic ERC-721) ---

    /**
     * @dev Mints a new Sentinel NFT for a user. Each user can initially mint one Sentinel.
     * @param _to The address to mint the Sentinel NFT to.
     */
    function mintSentinel(address _to) external whenNotPaused {
        require(_to == msg.sender, "ImpactNexus: Can only mint to self.");
        require(Sentinel.balanceOf(_to) == 0, "ImpactNexus: User already has a Sentinel NFT.");

        uint256 tokenId = nextSentinelId++;
        Sentinel.mint(_to, tokenId);
        // Initial ImpactPoints for minting a Sentinel
        impactPoints[_to] = impactPoints[_to].add(100);
        lastRewardUpdateTime[_to] = block.timestamp; // Start tracking for staking rewards
        emit SentinelMinted(_to, tokenId, 0); // 0 representing initial level
        emit ImpactPointsIncreased(_to, 100, impactPoints[_to]);
    }

    /**
     * @dev Internal function to try evolving a Sentinel.
     *      Can be called after ImpactPoints increase or other positive actions.
     *      Checks current ImpactPoints and stake to determine if an evolution is warranted.
     * @param _user The owner of the Sentinel.
     */
    function _tryEvolveSentinel(address _user) internal {
        if (Sentinel.balanceOf(_user) == 0) return;

        uint256 tokenId = Sentinel.tokenOfOwnerByIndex(_user, 0); // Assuming one Sentinel per user
        uint256 currentLevel = _getSentinelLevel(tokenId);
        uint256 points = impactPoints[_user];
        uint256 staked = stakedITK[_user];

        uint256 newLevel = currentLevel;

        if (points >= 10000 && staked >= 1000 ether && currentLevel < 4) {
            newLevel = 4; // Nexus Elder Sentinel
        } else if (points >= 5000 && staked >= 500 ether && currentLevel < 3) {
            newLevel = 3; // Arch Guardian Sentinel
        } else if (points >= 2000 && staked >= 200 ether && currentLevel < 2) {
            newLevel = 2; // Impact Creator Sentinel
        } else if (points >= 500 && staked >= 50 ether && currentLevel < 1) {
            newLevel = 1; // Active Contributor Sentinel
        }

        if (newLevel > currentLevel) {
            Sentinel.setTokenLevel(tokenId, newLevel);
            emit SentinelEvolved(tokenId, newLevel, "Impact & Stake increase");
        }
    }

    /**
     * @dev Internal function to try degrading a Sentinel.
     *      Can be called after ImpactPoints decrease or other negative actions.
     *      Checks current ImpactPoints and stake to determine if a degradation is warranted.
     * @param _user The owner of the Sentinel.
     */
    function _tryDegradeSentinel(address _user) internal {
        if (Sentinel.balanceOf(_user) == 0) return; // No Sentinel to degrade

        uint256 tokenId = Sentinel.tokenOfOwnerByIndex(_user, 0);
        uint256 currentLevel = _getSentinelLevel(tokenId);
        uint256 points = impactPoints[_user];
        uint256 staked = stakedITK[_user];

        uint256 newLevel = currentLevel;

        if (points < 500 && staked < 50 ether && currentLevel > 0) {
            newLevel = 0; // Back to basic
        } else if (points < 2000 && staked < 200 ether && currentLevel > 1) {
            newLevel = 1; // Active Contributor
        } else if (points < 5000 && staked < 500 ether && currentLevel > 2) {
            newLevel = 2; // Impact Creator
        } else if (points < 10000 && staked < 1000 ether && currentLevel > 3) {
            newLevel = 3; // Arch Guardian
        }

        if (newLevel < currentLevel) {
            Sentinel.setTokenLevel(tokenId, newLevel);
            emit SentinelDegraded(tokenId, newLevel, "Impact or Stake decrease");
        }
    }

    /**
     * @dev Returns the level of a Sentinel NFT.
     * @param _tokenId The ID of the Sentinel NFT.
     * @return The current level of the Sentinel.
     */
    function _getSentinelLevel(uint256 _tokenId) internal view returns (uint256) {
        return Sentinel.getTokenLevel(_tokenId);
    }

    /**
     * @dev Sets the base URI for Sentinel NFT metadata.
     *      Callable by DEFAULT_ADMIN_ROLE.
     * @param newBaseURI The new base URI.
     */
    function setSentinelBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _sentinelBaseURI = newBaseURI;
        Sentinel.setBaseURI(newBaseURI); // Update base URI in the Sentinel NFT contract
    }

    // --- IV. ITK Staking & Yield Rewards ---

    /**
     * @dev Stakes ITK tokens. User must approve ITK transfer to ImpactNexus first.
     * @param _amount The amount of ITK to stake.
     */
    function stakeITK(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "ImpactNexus: Stake amount must be greater than zero.");
        // Transfer ITK from user to this contract
        ITK.transferFrom(msg.sender, address(this), _amount);

        // Update pending rewards before updating stake
        _updateRewards(msg.sender);

        stakedITK[msg.sender] = stakedITK[msg.sender].add(_amount);
        totalStakedITK = totalStakedITK.add(_amount);
        lastRewardUpdateTime[msg.sender] = block.timestamp;

        // Automatically mint Wisdom Shares for staking (initial mint or boost)
        _mintWisdomShares(msg.sender, _amount.div(10), "Initial stake bonus");

        emit ITKStaked(msg.sender, _amount);
        _tryEvolveSentinel(msg.sender); // Check for Sentinel evolution
    }

    /**
     * @dev Unstakes ITK tokens.
     * @param _amount The amount of ITK to unstake.
     */
    function unstakeITK(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "ImpactNexus: Unstake amount must be greater than zero.");
        require(stakedITK[msg.sender] >= _amount, "ImpactNexus: Not enough ITK staked.");

        // Update pending rewards before updating stake
        _updateRewards(msg.sender);

        stakedITK[msg.sender] = stakedITK[msg.sender].sub(_amount);
        totalStakedITK = totalStakedITK.sub(_amount);
        lastRewardUpdateTime[msg.sender] = block.timestamp;

        // Transfer ITK back to user
        ITK.transfer(msg.sender, _amount);

        // Automatically burn some Wisdom Shares upon unstaking
        _burnWisdomShares(msg.sender, _amount.div(20), "Unstake penalty");

        emit ITKUnstaked(msg.sender, _amount);
        _tryDegradeSentinel(msg.sender); // Check for Sentinel degradation
    }

    /**
     * @dev Claims pending ITK staking rewards.
     */
    function claimITKRewards() external whenNotPaused {
        // Calculate and transfer rewards
        uint256 rewards = getPendingITKRewards(msg.sender);
        if (rewards > 0) {
            // Mint new ITK for rewards
            ITK.mint(msg.sender, rewards);
            // Reset pending rewards by updating the last update time
            lastRewardUpdateTime[msg.sender] = block.timestamp;
            emit ITKRewardsClaimed(msg.sender, rewards);
        }
    }

    /**
     * @dev Internal helper function to calculate and update a user's pending rewards.
     *      This mints and transfers rewards if any are accumulated.
     * @param _user The address of the staker.
     */
    function _updateRewards(address _user) internal {
        // Calculate rewards since last update
        uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime[_user]);
        if (timeElapsed > 0 && stakedITK[_user] > 0 && stakingAPR_bps > 0) {
            uint256 rewards = stakedITK[_user]
                .mul(stakingAPR_bps)
                .mul(timeElapsed)
                .div(10000) // Basis points
                .div(SECONDS_IN_YEAR);
            if (rewards > 0) {
                ITK.mint(_user, rewards); // Mint and transfer rewards directly
                // Note: Emit ITKRewardsClaimed here might duplicate if claimITKRewards() also calls it.
                // It's fine for this example as it shows the reward calculation logic.
                // In production, you might refactor to ensure events are not duplicated.
            }
        }
        // Always update lastRewardUpdateTime to prevent double-claiming for the same period.
        lastRewardUpdateTime[_user] = block.timestamp;
    }

    /**
     * @dev Returns the amount of ITK staked by a specific user.
     * @param _user The address of the user.
     * @return The staked ITK amount.
     */
    function getITKStakedAmount(address _user) external view returns (uint256) {
        return stakedITK[_user];
    }

    /**
     * @dev Calculates the pending ITK rewards for a specific user.
     *      Does not update state.
     * @param _user The address of the user.
     * @return The amount of pending ITK rewards.
     */
    function getPendingITKRewards(address _user) public view returns (uint256) {
        if (stakedITK[_user] == 0 || stakingAPR_bps == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime[_user]);
        if (timeElapsed == 0) return 0; // Rewards already calculated for this block, or no time passed

        return stakedITK[_user]
            .mul(stakingAPR_bps)
            .mul(timeElapsed)
            .div(10000) // Basis points
            .div(SECONDS_IN_YEAR);
    }

    /**
     * @dev Allows the ORACLE_ROLE to dynamically adjust the staking APR.
     *      This could be based on AI analysis of protocol health, market conditions, etc.
     * @param _newAPR_bps The new staking APR in basis points.
     */
    function updateStakingAPR(uint256 _newAPR_bps) external onlyRole(ORACLE_ROLE) {
        stakingAPR_bps = _newAPR_bps;
        emit StakingAPRUpdated(_newAPR_bps);
    }

    // --- V. Wisdom Shares (WS) & Governance Power ---

    /**
     * @dev Internal function to mint non-transferable Wisdom Shares.
     *      Called upon staking, positive impact, or other engagements.
     * @param _user The recipient of Wisdom Shares.
     * @param _amount The amount of Wisdom Shares to mint.
     * @param _reason A description for the minting event.
     */
    function _mintWisdomShares(address _user, uint256 _amount, string memory _reason) internal {
        wisdomShares[_user] = wisdomShares[_user].add(_amount);
        emit WisdomSharesMinted(_user, _amount, wisdomShares[_user]);
    }

    /**
     * @dev Internal function to burn non-transferable Wisdom Shares.
     *      Called upon unstaking, negative impact, or prolonged inactivity.
     * @param _user The owner of Wisdom Shares to burn.
     * @param _amount The amount of Wisdom Shares to burn.
     * @param _reason A description for the burning event.
     */
    function _burnWisdomShares(address _user, uint256 _amount, string memory _reason) internal {
        if (wisdomShares[_user] > 0) {
            wisdomShares[_user] = wisdomShares[_user].sub(
                _amount > wisdomShares[_user] ? wisdomShares[_user] : _amount
            );
            emit WisdomSharesBurned(_user, _amount, wisdomShares[_user]);
        }
    }

    /**
     * @dev Retrieves the current Wisdom Shares balance for a user.
     * @param _user The address of the user.
     * @return The current Wisdom Shares.
     */
    function getWisdomShares(address _user) external view returns (uint256) {
        return wisdomShares[_user];
    }

    /**
     * @dev Calculates the total voting power for an address, considering delegated power.
     *      Voting power is derived from Wisdom Shares and a fraction of staked ITK.
     * @param _voter The address whose voting power to query.
     * @return The total effective voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        address effectiveVoter = delegates[_voter] != address(0) ? delegates[_voter] : _voter;
        // Example: 1 ITK stake = 0.1 WS power. Adjust multiplier as needed.
        return wisdomShares[effectiveVoter].add(stakedITK[effectiveVoter].div(10));
    }

    /**
     * @dev Allows a user to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "ImpactNexus: Cannot delegate to zero address.");
        require(_delegatee != msg.sender, "ImpactNexus: Cannot delegate to self.");
        delegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a user to undelegate their voting power.
     */
    function undelegateVote() external whenNotPaused {
        require(delegates[msg.sender] != address(0), "ImpactNexus: No delegation to undelegate.");
        delegates[msg.sender] = address(0);
        emit VoteUndelegated(msg.sender);
    }

    // --- VI. AI Oracle Integration ---

    /**
     * @dev The trusted AI oracle reports a judgment or analysis result.
     *      This function processes the AI's input and triggers appropriate internal actions.
     *      Callable only by the ORACLE_ROLE.
     * @param _judgmentType A string describing the type of judgment (e.g., "PositiveAction", "NegativeBehavior", "MarketTrend").
     * @param _entityId A unique identifier (e.g., hash of a transaction, user address) related to the judgment.
     * @param _score An integer score provided by the AI (can be positive or negative).
     * @param _data Additional arbitrary data or description from the AI.
     */
    function reportAIJudgement(
        string memory _judgmentType,
        bytes32 _entityId,
        int256 _score,
        string memory _data
    ) external onlyRole(ORACLE_ROLE) whenNotPaused {
        emit AIJudgementReported(msg.sender, _judgmentType, _entityId, _score, _data);

        // Example logic for processing AI judgments:
        bytes32 userBehaviorType = keccak256(abi.encodePacked("UserBehavior"));
        bytes32 marketConditionsType = keccak256(abi.encodePacked("MarketConditions"));
        bytes32 judgmentTypeHash = keccak256(abi.encodePacked(_judgmentType));

        if (judgmentTypeHash == userBehaviorType) {
            address user = address(uint160(uint256(_entityId))); // Assuming _entityId is user address
            if (_score > 0) {
                // Positive behavior detected by AI
                increaseImpactPoints(user, uint256(_score), string(abi.encodePacked("AI-judged positive action: ", _data)));
                _mintWisdomShares(user, uint256(_score).div(10), "AI positive judgment bonus");
            } else if (_score < 0) {
                // Negative behavior detected by AI
                decreaseImpactPoints(user, uint256(uint256(0 - _score)), string(abi.encodePacked("AI-judged negative action: ", _data)));
                _burnWisdomShares(user, uint256(uint256(0 - _score)).div(10), "AI negative judgment penalty");
            }
        } else if (judgmentTypeHash == marketConditionsType) {
            // AI reports on market conditions, adjust staking APR
            if (_score > 0) { // e.g., market positive, increase APR
                updateStakingAPR(stakingAPR_bps.add(uint256(_score)));
            } else if (_score < 0) { // e.g., market negative, decrease APR
                updateStakingAPR(stakingAPR_bps.sub(uint256(uint256(0 - _score))));
            }
        }
        // Further complex logic can be added here for other judgment types
    }

    /**
     * @dev Allows specific governance roles to request an off-chain AI analysis on a specific topic.
     *      This emits an event that off-chain AI oracles would listen to and respond via `reportAIJudgement`.
     * @param _topic A brief description of the analysis topic.
     * @param _description A detailed description or parameters for the AI analysis.
     */
    function requestAIAnalysis(string memory _topic, string memory _description) external onlyRole(GOVERNOR_ROLE) whenNotPaused {
        emit AIAnalysisRequested(msg.sender, _topic, _description);
    }

    // --- VII. Governance Module ---

    /**
     * @dev Creates a new governance proposal.
     *      Requires the caller to have the GOVERNOR_ROLE, sufficient ImpactPoints, and voting power.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call data for the target contract.
     */
    function propose(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external onlyRole(GOVERNOR_ROLE) whenNotPaused returns (uint256 proposalId) {
        require(impactPoints[msg.sender] >= minImpactPointsToPropose, "ImpactNexus: Insufficient ImpactPoints to propose.");
        require(getVotingPower(msg.sender) >= minWisdomSharesToVote, "ImpactNexus: Insufficient voting power to propose.");

        proposalCount++;
        proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            creationTime: block.timestamp,
            endTime: block.timestamp.add(governancePeriod),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false
        });

        // The `hasVoted` mapping within the struct will be initialized upon first access (vote).

        emit ProposalCreated(proposalId, msg.sender, _description, proposals[proposalId].endTime);
    }

    /**
     * @dev Allows users to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function vote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ImpactNexus: Proposal does not exist.");
        require(block.timestamp <= proposal.endTime, "ImpactNexus: Voting period has ended.");
        require(!proposal.executed, "ImpactNexus: Proposal already executed.");
        require(!proposal.canceled, "ImpactNexus: Proposal has been canceled.");

        address voter = msg.sender;
        address effectiveVoter = delegates[voter] != address(0) ? delegates[voter] : voter;
        require(!proposal.hasVoted[effectiveVoter], "ImpactNexus: Voter or delegate already voted.");

        uint256 power = getVotingPower(effectiveVoter);
        require(power >= minWisdomSharesToVote, "ImpactNexus: Insufficient voting power to cast a vote.");

        proposal.hasVoted[effectiveVoter] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(power);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(power);
        }

        emit VoteCast(_proposalId, effectiveVoter, _support, power);
    }

    /**
     * @dev Executes a passed proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ImpactNexus: Proposal does not exist.");
        require(block.timestamp > proposal.endTime, "ImpactNexus: Voting period has not ended yet.");
        require(!proposal.executed, "ImpactNexus: Proposal already executed.");
        require(!proposal.canceled, "ImpactNexus: Proposal has been canceled.");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "ImpactNexus: No votes cast."); 
        
        // Simplified Quorum calculation: Total staked ITK (converted to power) plus a fraction of total ITK supply.
        // This is a heuristic to represent the "total possible voting power" in the ecosystem.
        uint256 totalPossibleVotingPower = totalStakedITK.div(10).add(ITK.totalSupply().div(100));
        require(totalPossibleVotingPower > 0, "ImpactNexus: No total voting power to determine quorum.");
        require(totalVotes.mul(10000).div(totalPossibleVotingPower) >= quorumPercentage_bps, "ImpactNexus: Quorum not met.");

        require(proposal.votesFor > proposal.votesAgainst, "ImpactNexus: Proposal did not pass.");

        // Execute the proposal's action
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "ImpactNexus: Proposal execution failed.");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Cancels a proposal. Can be called by DEFAULT_ADMIN_ROLE or if a veto condition is met.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ImpactNexus: Proposal does not exist.");
        require(!proposal.executed, "ImpactNexus: Proposal already executed.");
        require(!proposal.canceled, "ImpactNexus: Proposal already canceled.");

        proposal.canceled = true;
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return A string representing the state (NonExistent, Active, Canceled, Defeated, Succeeded, Executed, QuorumNotMet).
     */
    function getProposalState(uint256 _proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) return "NonExistent";
        if (proposal.canceled) return "Canceled";
        if (proposal.executed) return "Executed";
        if (block.timestamp <= proposal.endTime) return "Active";
        
        // After voting period ends
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalPossibleVotingPower = totalStakedITK.div(10).add(ITK.totalSupply().div(100));
        
        if (totalPossibleVotingPower == 0 || totalVotes.mul(10000).div(totalPossibleVotingPower) < quorumPercentage_bps) return "QuorumNotMet";
        if (proposal.votesFor > proposal.votesAgainst) return "Succeeded";
        return "Defeated";
    }

    /**
     * @dev Returns detailed information about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address targetContract,
            uint256 creationTime,
            uint256 endTime,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool canceled
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.targetContract,
            proposal.creationTime,
            proposal.endTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.canceled
        );
    }


    // --- VIII. Dynamic Resource & Ecosystem Allocation ---

    /**
     * @dev Distributes ITK funds from the protocol's treasury to a recipient based on their impact.
     *      Can be called by DEFAULT_ADMIN_ROLE or via a passed governance proposal.
     * @param _recipient The address to receive the funds.
     * @param _baseAmount The base amount of ITK to allocate (can be scaled by impact).
     * @param _reason A description for the allocation.
     */
    function allocateEcosystemFunds(
        address _recipient,
        uint256 _baseAmount,
        string memory _reason
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused { // This could also be an outcome of a governance proposal
        require(_recipient != address(0), "ImpactNexus: Invalid recipient address.");
        require(_baseAmount > 0, "ImpactNexus: Allocation amount must be positive.");

        // Example dynamic scaling based on impact points
        uint256 finalAmount = _baseAmount;
        
        if (impactPoints[_recipient] >= 10000) {
            finalAmount = finalAmount.mul(3); // 3x for Nexus Elder level impact
        } else if (impactPoints[_recipient] >= 5000) {
            finalAmount = finalAmount.mul(2); // 2x for Arch Guardian level impact
        } else if (impactPoints[_recipient] >= 2000) {
            finalAmount = finalAmount.mul(15).div(10); // 1.5x for Impact Creator level impact
        }

        require(ITK.balanceOf(address(this)) >= finalAmount, "ImpactNexus: Insufficient funds in treasury for allocation.");
        ITK.transfer(_recipient, finalAmount);

        emit FundsAllocated(_recipient, finalAmount, _reason);
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to update the rules or criteria for `allocateEcosystemFunds`.
     *      This function primarily serves as a placeholder to acknowledge dynamic criteria.
     *      Actual logic updates would require contract upgrades or more complex rule engines (e.g.,
     *      pointing to an external contract defining the criteria, which itself could be governed).
     * @param _newCriteriaDescription A string describing the new allocation criteria.
     *      This could be an IPFS hash to a detailed document, or a simple text summary.
     */
    function setAllocationCriteria(string memory _newCriteriaDescription) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // In a more advanced system, this might update a state variable that points to a specific
        // logic contract or a verifiable data source used by the `allocateEcosystemFunds` function.
        emit AllocationCriteriaUpdated(_newCriteriaDescription);
    }
}

/**
 * @title ITKToken
 * @dev The Impact Token (ITK) ERC20 token used within the ImpactNexus protocol.
 *      It is burnable and has a MINTER_ROLE for the ImpactNexus contract to issue rewards.
 */
contract ITKToken is ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Impact Token", "ITK") {
        // Initial admin can manage roles for ITK token itself
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Mints new tokens to an address. Only callable by addresses with MINTER_ROLE.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}

/**
 * @title SentinelNFTs
 * @dev The Dynamic Sentinel NFT ERC721 token used within the ImpactNexus protocol.
 *      It includes a 'level' that can be updated by the ImpactNexus contract,
 *      allowing for dynamic metadata generation.
 */
contract SentinelNFTs is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // ImpactNexus contract will hold this role

    mapping(uint256 => uint256) private _tokenLevels; // Level of each Sentinel NFT

    string private _baseURI; // Base URI for dynamic metadata

    constructor() ERC721("Impact Sentinel", "SENTINEL") {
        // Initial admin can manage roles for Sentinel NFTs itself
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Mints a new Sentinel NFT. Only callable by MINTER_ROLE (ImpactNexus contract).
     * @param to The address to mint the NFT to.
     * @param tokenId The ID of the token to mint.
     */
    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _tokenLevels[tokenId] = 0; // Initialize at base level
    }

    /**
     * @dev Returns the level of a specific Sentinel NFT.
     * @param tokenId The ID of the Sentinel NFT.
     * @return The current level of the Sentinel.
     */
    function getTokenLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "SentinelNFTs: Token does not exist.");
        return _tokenLevels[tokenId];
    }

    /**
     * @dev Sets the level of a specific Sentinel NFT. Only callable by MINTER_ROLE (ImpactNexus contract).
     * @param tokenId The ID of the Sentinel NFT.
     * @param newLevel The new level for the Sentinel.
     */
    function setTokenLevel(uint256 tokenId, uint256 newLevel) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "SentinelNFTs: Token does not exist.");
        _tokenLevels[tokenId] = newLevel;
    }

    /**
     * @dev Sets the base URI for all token IDs.
     *      Can only be called by an address with MINTER_ROLE (ImpactNexus contract) or DEFAULT_ADMIN_ROLE.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyRole(MINTER_ROLE) {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` assets.
     *      This is overridden to provide a dynamic URI based on the Sentinel's level.
     *      The metadata service serving this URI should interpret the appended level and ID
     *      to return appropriate dynamic content.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI;
        // If base URI is empty, fallback to default ERC721 behavior (which would likely fail without a _tokenURIs mapping)
        // or return a generic placeholder.
        if (bytes(base).length == 0) {
            return super.tokenURI(tokenId);
        }

        // Example dynamic URI: base_uri/tokenId_level.json
        // A dedicated metadata service would listen to this URI, fetch the tokenId and level,
        // and serve a JSON response with dynamic image/attributes.
        return string(abi.encodePacked(
            base,
            tokenId.toString(),
            "_",
            _tokenLevels[tokenId].toString(),
            ".json"
        ));
    }
}
```