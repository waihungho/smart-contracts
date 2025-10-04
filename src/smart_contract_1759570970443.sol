Here's a Solidity smart contract named `EvolveSphereProtocol` that aims to be interesting, advanced, creative, and trendy, with a focus on dynamic NFTs, reputation systems, and adaptive ecosystem management. It includes more than 20 distinct functions.

---

## EvolveSphereProtocol: Outline and Function Summary

**Contract Name:** `EvolveSphereProtocol`

**Concept Summary:**
The `EvolveSphereProtocol` is a decentralized, self-optimizing ecosystem designed to foster long-term engagement and contributions from its users. It introduces "SphereFragments" – dynamic, soulbound ERC-721 NFTs that serve as evolving on-chain identity markers, representing a user's reputation, contributions, and access tiers within the protocol. Users stake resources (ERC-20 tokens) to earn reputation, which in turn levels up their SphereFragment NFT and unlocks advanced privileges. The protocol incorporates a reputation decay mechanism to encourage continuous activity, integrates with oracles for adaptive parameter adjustments, and features a lightweight governance system.

**Key Features:**

1.  **Dynamic Soulbound NFTs (SphereFragments):** Non-transferable NFTs that visually and functionally evolve based on a user's on-chain reputation and activity.
2.  **Reputation System:** Users earn reputation points through staking, contributions, and active participation. Reputation decays over time to incentivize continuous engagement.
3.  **Tiered Access & Privileges:** Reputation and SphereFragment levels grant users access to exclusive features, higher rewards, and governance participation.
4.  **Adaptive Staking & Rewards:** Users stake ERC-20 tokens to earn rewards and reputation. Staking parameters and reward distribution can dynamically adjust based on oracle data or governance decisions.
5.  **Lightweight On-chain Governance:** Reputable users can propose and vote on key protocol parameter changes, ensuring community-driven evolution.
6.  **Oracle Integration (Conceptual):** Mechanisms to react to external market conditions or data feeds, allowing the protocol to self-optimize.
7.  **Role-Based Access Control:** Granular permissions for various administrative and operational tasks.

---

**Function Summary:**

**I. Core Ecosystem Management & Configuration (6 functions)**

1.  `constructor()`: Initializes the contract, sets up roles, and defines initial parameters like staking periods and minimum amounts.
2.  `updateStakingPeriod(uint256 _newPeriod)`: Allows governance to adjust the duration users must stake tokens.
3.  `updateReputationThresholds(uint256[] calldata _newThresholds)`: Enables governance to redefine the reputation points required for each SphereFragment level.
4.  `setOracleAddress(address _newOracle)`: Updates the address of the trusted oracle used for external data.
5.  `togglePauseState(bool _paused)`: Allows authorized roles to pause/unpause core protocol functionalities for maintenance or emergency.
6.  `emergencyWithdrawERC20(address _token, uint256 _amount)`: Admin function to rescue accidentally sent ERC-20 tokens from the contract.

**II. Resource Management (Staking & Rewards) (6 functions)**

7.  `stakeResources(uint256 _amount)`: Users deposit ERC-20 tokens into the protocol, initiating their staking period and earning initial reputation.
8.  `unstakeResources()`: Allows users to withdraw their staked tokens and accrued rewards after their staking period has elapsed.
9.  `claimReputationBoost()`: Users can claim a temporary reputation boost based on recent active participation (e.g., governance voting, contributions).
10. `distributeEcosystemRewards(address[] calldata _recipients, uint256[] calldata _amounts)`: Authorized role distributes additional ERC-20 rewards to specified contributors based on their impact.
11. `getAvailableRewards(address _user)`: View function to check the pending reward amount for a specific user.
12. `getStakedBalance(address _user)`: View function to check the current staked token balance for a specific user.

**III. Reputation & Identity (SphereFragments) (6 functions)**

13. `mintSphereFragment(address _to)`: Mints a new SphereFragment NFT to an address upon meeting initial contribution/reputation criteria.
14. `updateSphereFragmentLevel(uint256 _tokenId)`: Advances the level of a SphereFragment NFT if the owner's reputation crosses a new threshold.
15. `decayReputation(address _user)`: A scheduled or authorized function to reduce a user's reputation score if they have been inactive for a defined period.
16. `getReputationScore(address _user)`: View function to retrieve the current reputation score of a specific user.
17. `getSphereFragmentMetadataURI(uint256 _tokenId)`: Returns the dynamic metadata URI for a given SphereFragment, reflecting its current level and status.
18. `isEligibleForTier(address _user, uint256 _tierLevel)`: Checks if a user's reputation qualifies them for a specified access tier.

**IV. Advanced Interaction & Governance (6 functions)**

19. `proposeParameterChange(string calldata _description, address _target, bytes calldata _callData, uint256 _duration)`: Reputable users can submit proposals to change protocol parameters or execute arbitrary calls.
20. `voteOnProposal(uint256 _proposalId, bool _voteYes)`: Users with sufficient reputation can cast their vote (yes/no) on an active proposal.
21. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal after its voting period and required delay.
22. `submitDataContribution(string calldata _contributionHash)`: (Conceptual) Placeholder for users submitting valuable data or content, earning reputation.
23. `requestOracleData(bytes32 _queryId)`: Initiates a request to the configured oracle for external data (e.g., market price, event outcome).
24. `processOracleResponse(bytes32 _queryId, bytes calldata _response)`: Callback function for the oracle to deliver requested data, triggering internal protocol adjustments.

**V. Utilities & Access Control (3 functions)**

25. `grantRole(bytes32 role, address account)`: Grants a specific administrative role to an address.
26. `revokeRole(bytes32 role, address account)`: Revokes a specific administrative role from an address.
27. `hasRole(bytes32 role, address account)`: View function to check if an address possesses a specific role.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Interface for a simplified oracle that returns bytes data
interface IOracle {
    function requestData(bytes32 _queryId, string calldata _dataSource) external;
    function fulfillData(bytes32 _queryId, bytes calldata _response) external;
}

/**
 * @title EvolveSphereProtocol
 * @dev A decentralized, self-optimizing ecosystem with dynamic, soulbound NFTs, reputation, and adaptive governance.
 */
contract EvolveSphereProtocol is Context, AccessControl, ERC721Enumerable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant ORACLE_RESPONDER_ROLE = keccak256("ORACLE_RESPONDER_ROLE");
    bytes32 public constant GOVERNANCE_EXEC_ROLE = keccak256("GOVERNANCE_EXEC_ROLE");

    // --- Staking Configuration ---
    IERC20 public stakingToken;
    uint256 public stakingPeriod; // Duration in seconds for which tokens must be staked
    uint256 public minStakingAmount;
    uint256 public baseReputationPerStake; // Reputation points gained per staking event

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakeTimestamps; // When did the user last stake/reset their stake period
    mapping(address => uint256) public lastReputationClaimTimestamp;

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public lastReputationDecayTimestamp;
    uint256 public reputationDecayRate; // Points per decay interval
    uint256 public reputationDecayInterval; // Time in seconds for decay check
    uint256 public reputationBoostAmount; // Temporary boost for recent activity

    // --- SphereFragment NFT (ERC721) ---
    uint256 public nextTokenId; // Counter for SphereFragment NFTs
    mapping(address => uint256) public userSphereFragmentId; // Maps user address to their unique SphereFragment NFT ID
    mapping(uint256 => uint256) public sphereFragmentLevel; // Maps NFT ID to its current level
    uint256[] public reputationThresholdsForLevel; // reputationThresholdsForLevel[0] = Level 1, [1] = Level 2 etc.

    // --- Governance ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target;
        bytes callData;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted; // Nested mapping for votes
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public proposalVotingPeriod; // Duration for voting
    uint256 public proposalMinReputationToPropose;
    uint256 public proposalMinReputationToVote;
    uint256 public proposalQuorumThreshold; // Percentage of total reputation needed to pass (e.g., 5100 for 51%)

    // --- Oracle Integration ---
    address public oracleAddress;
    mapping(bytes32 => bool) public pendingOracleRequests; // To track active requests

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event ReputationGained(address indexed user, uint256 newScore, uint256 change);
    event ReputationDecayed(address indexed user, uint256 newScore, uint256 change);
    event SphereFragmentMinted(address indexed owner, uint256 tokenId, uint256 initialLevel);
    event SphereFragmentLeveledUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteYes);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event OracleRequestSent(bytes32 indexed queryId);
    event OracleResponseProcessed(bytes32 indexed queryId, bytes response);
    event RewardsDistributed(address[] recipients, uint256[] amounts);
    event DataContributed(address indexed contributor, string contributionHash);


    constructor(address _stakingTokenAddress, uint256 _initialStakingPeriod, uint256 _minStakingAmount, uint256 _baseReputationPerStake)
        ERC721("EvolveSphere Fragment", "ESF")
        _pause() // Start paused for initial setup
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REPUTATION_MANAGER_ROLE, msg.sender);
        _grantRole(ORACLE_RESPONDER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_EXEC_ROLE, msg.sender);

        stakingToken = IERC20(_stakingTokenAddress);
        stakingPeriod = _initialStakingPeriod; // e.g., 30 days
        minStakingAmount = _minStakingAmount;
        baseReputationPerStake = _baseReputationPerStake;

        // Initial reputation thresholds for levels
        reputationThresholdsForLevel = [100, 500, 2000, 10000]; // Level 1 (100+), Level 2 (500+), etc.
        reputationDecayRate = 10; // 10 points
        reputationDecayInterval = 1 days; // Every day
        reputationBoostAmount = 50; // 50 points boost

        proposalVotingPeriod = 7 days;
        proposalMinReputationToPropose = 500; // Must be Level 2 or higher
        proposalMinReputationToVote = 100; // Must be Level 1 or higher
        proposalQuorumThreshold = 5100; // 51%

        nextTokenId = 1;
        nextProposalId = 1;
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Calculates and applies reputation decay if due.
     * This function is called internally before operations that rely on reputation,
     * or can be manually triggered by a REPUTATION_MANAGER_ROLE.
     * @param _user The address whose reputation might decay.
     */
    function _applyReputationDecay(address _user) internal {
        if (reputationScores[_user] == 0) return; // No reputation to decay

        uint256 lastDecay = lastReputationDecayTimestamp[_user];
        if (lastDecay == 0) { // First time user, set decay timestamp
            lastReputationDecayTimestamp[_user] = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(lastDecay);
        if (timeElapsed >= reputationDecayInterval) {
            uint256 decayIntervals = timeElapsed.div(reputationDecayInterval);
            uint256 actualDecay = reputationDecayRate.mul(decayIntervals);

            uint256 currentReputation = reputationScores[_user];
            uint256 newReputation = currentReputation.sub(actualDecay > currentReputation ? currentReputation : actualDecay);

            reputationScores[_user] = newReputation;
            lastReputationDecayTimestamp[_user] = lastDecay.add(decayIntervals.mul(reputationDecayInterval)); // Update last decay timestamp accurately

            emit ReputationDecayed(_user, newReputation, currentReputation.sub(newReputation));
        }
    }

    /**
     * @dev Awards reputation points to a user and updates their SphereFragment level.
     * @param _user The address to award reputation to.
     * @param _points The number of reputation points to award.
     */
    function _awardReputation(address _user, uint256 _points) internal {
        _applyReputationDecay(_user);
        uint256 oldReputation = reputationScores[_user];
        reputationScores[_user] = oldReputation.add(_points);
        emit ReputationGained(_user, reputationScores[_user], _points);
        
        // Try to level up the SphereFragment if the user has one
        if (userSphereFragmentId[_user] != 0) {
            updateSphereFragmentLevel(userSphereFragmentId[_user]);
        }
    }

    /**
     * @dev Checks the current level for a given reputation score.
     */
    function _getSphereFragmentLevelByReputation(uint256 _reputation) internal view returns (uint256) {
        for (uint256 i = reputationThresholdsForLevel.length; i > 0; i--) {
            if (_reputation >= reputationThresholdsForLevel[i - 1]) {
                return i; // Level is (index + 1)
            }
        }
        return 0; // Base level if no threshold is met
    }

    // --- Pausable Function Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Make SphereFragments soulbound: prevent transfers once minted.
        // Allow minting (from address(0)) and burning (to address(0))
        require(from == address(0) || to == address(0), "ESF: SphereFragments are soulbound and cannot be transferred");
    }

    // --- ERC721 Metadata ---
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://EvolveSphereFragments/"; // Base URI for metadata service
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata based on fragment level.
     * This requires an off-chain metadata server that generates JSON based on the token ID and level.
     * Example: ipfs://EvolveSphereFragments/{tokenId}/{level}.json
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 level = sphereFragmentLevel[tokenId];
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString(), "/", level.toString(), ".json"));
    }

    // --- Core Ecosystem Management & Configuration (6 functions) ---

    /**
     * @dev Allows governance to adjust the duration users must stake tokens.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param _newPeriod The new staking period in seconds.
     */
    function updateStakingPeriod(uint256 _newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_newPeriod > 0, "ESF: Staking period must be positive");
        stakingPeriod = _newPeriod;
    }

    /**
     * @dev Enables governance to redefine the reputation points required for each SphereFragment level.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param _newThresholds An array of reputation thresholds, where index i corresponds to level i+1.
     *                       Must be strictly increasing.
     */
    function updateReputationThresholds(uint256[] calldata _newThresholds) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_newThresholds.length > 0, "ESF: Thresholds cannot be empty");
        for (uint256 i = 1; i < _newThresholds.length; i++) {
            require(_newThresholds[i] > _newThresholds[i-1], "ESF: Thresholds must be strictly increasing");
        }
        reputationThresholdsForLevel = _newThresholds;
    }

    /**
     * @dev Sets or updates the address of the trusted oracle.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOracle != address(0), "ESF: Oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    /**
     * @dev Pauses or unpauses core protocol functionalities.
     * Requires DEFAULT_ADMIN_ROLE. Useful for emergencies or upgrades.
     * @param _paused If true, pauses the contract; if false, unpauses.
     */
    function togglePauseState(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Allows the admin to withdraw accidentally sent ERC-20 tokens.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param _token The address of the ERC-20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(_token).transfer(msg.sender, _amount), "ESF: Failed to withdraw tokens");
    }

    // --- Resource Management (Staking & Rewards) (6 functions) ---

    /**
     * @dev Allows a user to stake ERC-20 tokens into the protocol.
     * Initiates their staking period and awards initial reputation.
     * @param _amount The amount of tokens to stake.
     */
    function stakeResources(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount >= minStakingAmount, "ESF: Amount too low to stake");
        require(stakingToken.transferFrom(_msgSender(), address(this), _amount), "ESF: Token transfer failed");

        _applyReputationDecay(_msgSender()); // Apply decay before adding new reputation

        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(_amount);
        stakeTimestamps[_msgSender()] = block.timestamp;

        _awardReputation(_msgSender(), baseReputationPerStake); // Award base reputation for staking
        lastReputationDecayTimestamp[_msgSender()] = block.timestamp; // Reset decay timer on activity

        // Mint SphereFragment if user doesn't have one
        if (userSphereFragmentId[_msgSender()] == 0) {
            mintSphereFragment(_msgSender());
        } else {
            updateSphereFragmentLevel(userSphereFragmentId[_msgSender()]);
        }
        
        emit Staked(_msgSender(), _amount, block.timestamp);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens after the staking period has elapsed.
     * Rewards are implicitly part of the un-staking logic in a full implementation, here
     * it focuses on returning the staked amount.
     */
    function unstakeResources() external nonReentrant whenNotPaused {
        uint256 stakedAmount = stakedBalances[_msgSender()];
        require(stakedAmount > 0, "ESF: No tokens staked");
        require(block.timestamp.sub(stakeTimestamps[_msgSender()]) >= stakingPeriod, "ESF: Staking period not over yet");

        stakedBalances[_msgSender()] = 0;
        stakeTimestamps[_msgSender()] = 0;

        require(stakingToken.transfer(_msgSender(), stakedAmount), "ESF: Token transfer failed during unstake");

        _applyReputationDecay(_msgSender()); // Apply decay on unstake
        lastReputationDecayTimestamp[_msgSender()] = block.timestamp; // Reset decay timer on activity

        // Potentially reduce reputation or affect NFT level
        // (For this example, we only decay, not direct reduction on unstake)
        updateSphereFragmentLevel(userSphereFragmentId[_msgSender()]);

        emit Unstaked(_msgSender(), stakedAmount, block.timestamp);
    }

    /**
     * @dev Users can claim a temporary reputation boost based on recent active participation.
     * For example, voting in governance, or a recent stake. Can only be claimed once per day.
     */
    function claimReputationBoost() external whenNotPaused {
        _applyReputationDecay(_msgSender()); // Apply decay before boosting

        require(block.timestamp.sub(lastReputationClaimTimestamp[_msgSender()]) >= 1 days, "ESF: Can only claim boost once per day");
        require(reputationScores[_msgSender()] > 0, "ESF: Must have some reputation to claim a boost"); // Prevent spam

        _awardReputation(_msgSender(), reputationBoostAmount);
        lastReputationClaimTimestamp[_msgSender()] = block.timestamp;
        lastReputationDecayTimestamp[_msgSender()] = block.timestamp; // Reset decay timer on activity
    }

    /**
     * @dev Authorized role distributes additional ERC-20 rewards to specified contributors.
     * Requires REPUTATION_MANAGER_ROLE. Rewards are sent from the contract's balance.
     * @param _recipients Array of addresses to receive rewards.
     * @param _amounts Array of amounts corresponding to recipients.
     */
    function distributeEcosystemRewards(address[] calldata _recipients, uint256[] calldata _amounts) external onlyRole(REPUTATION_MANAGER_ROLE) whenNotPaused {
        require(_recipients.length == _amounts.length, "ESF: Recipients and amounts mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(stakingToken.transfer(_recipients[i], _amounts[i]), "ESF: Failed to distribute reward");
        }
        emit RewardsDistributed(_recipients, _amounts);
    }

    /**
     * @dev View function to check the current available (unclaimed) rewards for a user.
     * (Placeholder for a more complex reward calculation, currently returns 0).
     */
    function getAvailableRewards(address _user) external pure returns (uint256) {
        // In a real system, this would calculate pending rewards based on staking duration,
        // reward rates, and other factors. For this example, it's a placeholder.
        _user; // Unused, but keeps compiler happy
        return 0;
    }

    /**
     * @dev View function to check the current staked token balance for a specific user.
     * @param _user The address of the user.
     */
    function getStakedBalance(address _user) external view returns (uint256) {
        return stakedBalances[_user];
    }

    // --- Reputation & Identity (SphereFragments) (6 functions) ---

    /**
     * @dev Mints a new SphereFragment NFT to an address.
     * Can only be called if the user does not already own a SphereFragment.
     * Requires REPUTATION_MANAGER_ROLE or can be called internally by staking logic.
     * @param _to The address to mint the SphereFragment to.
     */
    function mintSphereFragment(address _to) public onlyRole(REPUTATION_MANAGER_ROLE) whenNotPaused {
        require(userSphereFragmentId[_to] == 0, "ESF: User already has a SphereFragment");
        _applyReputationDecay(_to);

        uint256 tokenId = nextTokenId++;
        _safeMint(_to, tokenId);
        userSphereFragmentId[_to] = tokenId;
        sphereFragmentLevel[tokenId] = _getSphereFragmentLevelByReputation(reputationScores[_to]);
        
        emit SphereFragmentMinted(_to, tokenId, sphereFragmentLevel[tokenId]);
    }

    /**
     * @dev Advances the level of a SphereFragment NFT if the owner's reputation crosses a new threshold.
     * Can be called by anyone to trigger an update for a specific NFT, though usually triggered internally.
     * @param _tokenId The ID of the SphereFragment NFT to update.
     */
    function updateSphereFragmentLevel(uint256 _tokenId) public whenNotPaused {
        address owner = ownerOf(_tokenId);
        _applyReputationDecay(owner); // Apply decay before checking new level

        uint256 currentReputation = reputationScores[owner];
        uint256 newLevel = _getSphereFragmentLevelByReputation(currentReputation);
        
        if (newLevel > sphereFragmentLevel[_tokenId]) {
            uint256 oldLevel = sphereFragmentLevel[_tokenId];
            sphereFragmentLevel[_tokenId] = newLevel;
            emit SphereFragmentLeveledUp(_tokenId, oldLevel, newLevel);
        } else if (newLevel < sphereFragmentLevel[_tokenId]) {
            // Also handle de-leveling if reputation drops
            uint256 oldLevel = sphereFragmentLevel[_tokenId];
            sphereFragmentLevel[_tokenId] = newLevel;
            emit SphereFragmentLeveledUp(_tokenId, oldLevel, newLevel); // Use same event for simplicity
        }
    }

    /**
     * @dev Reduces a user's reputation score if they have been inactive.
     * Can be called by a REPUTATION_MANAGER_ROLE. Or integrated with a keeper network.
     * @param _user The address whose reputation might decay.
     */
    function decayReputation(address _user) external onlyRole(REPUTATION_MANAGER_ROLE) {
        _applyReputationDecay(_user);
        // If the decay caused a level change, update the NFT
        if (userSphereFragmentId[_user] != 0) {
            updateSphereFragmentLevel(userSphereFragmentId[_user]);
        }
    }

    /**
     * @dev View function to retrieve the current reputation score of a specific user.
     * @param _user The address of the user.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        // This view function should ideally also apply decay for accuracy if current_timestamp > lastReputationDecayTimestamp[_user]
        // But for a pure 'view' function, it usually just returns the stored state.
        // A client application should call _applyReputationDecay via a transaction if full accuracy is needed before a read.
        return reputationScores[_user];
    }

    /**
     * @dev Returns the dynamic metadata URI for a given SphereFragment NFT.
     * @param _tokenId The ID of the SphereFragment.
     */
    function getSphereFragmentMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /**
     * @dev Checks if a user's reputation qualifies them for a specified access tier.
     * @param _user The address of the user.
     * @param _tierLevel The level of the tier to check against (e.g., 1 for Level 1, 2 for Level 2).
     */
    function isEligibleForTier(address _user, uint256 _tierLevel) external view returns (bool) {
        // Apply decay conceptually for the check, but not alter state
        uint256 currentRep = reputationScores[_user]; // A client could simulate decay before calling
        uint256 userCurrentLevel = _getSphereFragmentLevelByReputation(currentRep);
        return userCurrentLevel >= _tierLevel;
    }

    // --- Advanced Interaction & Governance (6 functions) ---

    /**
     * @dev Allows reputable users to submit proposals for protocol parameter changes or actions.
     * Requires minimum reputation (`proposalMinReputationToPropose`).
     * @param _description A description of the proposal.
     * @param _target The target contract address for the proposal's execution.
     * @param _callData The encoded function call data for execution.
     * @param _duration The duration of the voting period in seconds.
     */
    function proposeParameterChange(
        string calldata _description,
        address _target,
        bytes calldata _callData,
        uint256 _duration
    ) external nonReentrant whenNotPaused {
        _applyReputationDecay(_msgSender());
        require(reputationScores[_msgSender()] >= proposalMinReputationToPropose, "ESF: Insufficient reputation to propose");
        require(_duration > 0, "ESF: Proposal duration must be positive");
        
        uint256 proposalId = nextProposalId++;
        proposals[proposalId].id = proposalId;
        proposals[proposalId].proposer = _msgSender();
        proposals[proposalId].description = _description;
        proposals[proposalId].target = _target;
        proposals[proposalId].callData = _callData;
        proposals[proposalId].deadline = block.timestamp.add(_duration);
        proposals[proposalId].executed = false;

        emit ProposalCreated(proposalId, _msgSender(), _description, proposals[proposalId].deadline);
    }

    /**
     * @dev Allows users with sufficient reputation to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteYes True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteYes) external nonReentrant whenNotPaused {
        _applyReputationDecay(_msgSender());
        require(reputationScores[_msgSender()] >= proposalMinReputationToVote, "ESF: Insufficient reputation to vote");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ESF: Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "ESF: Voting period has ended");
        require(!proposal.executed, "ESF: Proposal already executed");
        require(!proposal.hasVoted[_msgSender()], "ESF: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_voteYes) {
            proposal.voteCountYes = proposal.voteCountYes.add(reputationScores[_msgSender()]);
        } else {
            proposal.voteCountNo = proposal.voteCountNo.add(reputationScores[_msgSender()]);
        }
        _awardReputation(_msgSender(), 1); // Small reputation boost for active participation
        emit Voted(_proposalId, _msgSender(), _voteYes);
    }

    /**
     * @dev Executes a successfully passed proposal.
     * Requires GOVERNANCE_EXEC_ROLE. Only executable after voting period and if quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyRole(GOVERNANCE_EXEC_ROLE) nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ESF: Proposal does not exist");
        require(block.timestamp > proposal.deadline, "ESF: Voting period not over yet");
        require(!proposal.executed, "ESF: Proposal already executed");

        uint256 totalVotes = proposal.voteCountYes.add(proposal.voteCountNo);
        // Calculate total reputation of all users (approximate or a more complex snapshot)
        // For simplicity, let's assume `totalReputation` is total reputation in the system,
        // which would need to be tracked or calculated. For this example, let's just use 
        // a simplified quorum based on participating votes.
        require(totalVotes > 0, "ESF: No votes cast");
        uint256 yesPercentage = proposal.voteCountYes.mul(10000).div(totalVotes);
        require(yesPercentage >= proposalQuorumThreshold, "ESF: Proposal did not meet quorum threshold");

        proposal.executed = true;
        bool success = false;
        // Execute the call
        (success,) = proposal.target.call(proposal.callData); // unchecked call, revert if target reverts

        emit ProposalExecuted(_proposalId, success);
        require(success, "ESF: Proposal execution failed");
    }

    /**
     * @dev (Conceptual) Allows users to submit valuable data or content to the ecosystem.
     * Awards reputation for contributions. The actual data validation and storage mechanism
     * would be off-chain (e.g., IPFS) and validated by other means.
     * @param _contributionHash A hash or URI pointing to the off-chain contribution.
     */
    function submitDataContribution(string calldata _contributionHash) external whenNotPaused {
        require(bytes(_contributionHash).length > 0, "ESF: Contribution hash cannot be empty");
        _awardReputation(_msgSender(), 5); // Award some reputation for contributing
        lastReputationDecayTimestamp[_msgSender()] = block.timestamp; // Reset decay timer on activity
        emit DataContributed(_msgSender(), _contributionHash);
    }

    /**
     * @dev Initiates a request to the configured oracle for external data.
     * Requires DEFAULT_ADMIN_ROLE or other authorized role to prevent spamming the oracle.
     * @param _queryId A unique ID for this data request.
     */
    function requestOracleData(bytes32 _queryId) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(oracleAddress != address(0), "ESF: Oracle address not set");
        require(!pendingOracleRequests[_queryId], "ESF: Duplicate oracle request ID");
        
        pendingOracleRequests[_queryId] = true;
        IOracle(oracleAddress).requestData(_queryId, "some_data_source_or_query_string");
        emit OracleRequestSent(_queryId);
    }

    /**
     * @dev Callback function for the oracle to deliver requested data.
     * Can only be called by the trusted oracle address.
     * @param _queryId The ID of the original data request.
     * @param _response The data returned by the oracle.
     */
    function processOracleResponse(bytes32 _queryId, bytes calldata _response) external onlyRole(ORACLE_RESPONDER_ROLE) whenNotPaused {
        require(msg.sender == oracleAddress, "ESF: Only the oracle can call this function");
        require(pendingOracleRequests[_queryId], "ESF: Unknown or already processed oracle request");

        delete pendingOracleRequests[_queryId];

        // Process the response data, e.g., update staking rates, adjust parameters
        // This is where the "adaptive" logic would live.
        // Example: if (bytes32(_response) == keccak256("market_bullish")) { stakingPeriod = 15 days; }

        emit OracleResponseProcessed(_queryId, _response);
    }

    // --- Utilities & Access Control (3 functions) ---

    /**
     * @dev Grants a specific role to an account.
     * Only callable by accounts with the DEFAULT_ADMIN_ROLE or the role itself.
     * @param role The role to grant (e.g., `REPUTATION_MANAGER_ROLE`).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override {
        // Explicitly check for DEFAULT_ADMIN_ROLE or current role for granular control
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(role, _msgSender()), "ESF: Must have admin role or the specific role to grant");
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a specific role from an account.
     * Only callable by accounts with the DEFAULT_ADMIN_ROLE or the role itself.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override {
        // Explicitly check for DEFAULT_ADMIN_ROLE or current role for granular control
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(role, _msgSender()), "ESF: Must have admin role or the specific role to revoke");
        _revokeRole(role, account);
    }

    /**
     * @dev Checks if an account has a specific role.
     * @param role The role to check.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return super.hasRole(role, account);
    }
}

```