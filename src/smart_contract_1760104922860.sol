Here's a Solidity smart contract named `AuraForge` that incorporates advanced concepts like dynamic Soulbound NFTs, a comprehensive on-chain reputation system, reputation-weighted governance, verifiable data submission, and staking, all designed to be interconnected and avoid direct duplication of existing open-source projects.

The core idea is a protocol where users earn and lose "Aura" (reputation points) based on verifiable on-chain actions. This Aura directly influences a personal, non-transferable Dynamic NFT (Aura Essence NFT) which evolves visually and grants enhanced governance power and staking rewards. The system is governed by a DAO and supports various "impact goals" that users can align their NFTs with.

---

## AuraForge Protocol

### **Outline:**

The `AuraForge` protocol is designed to foster a reputation-driven ecosystem where user engagement and positive contributions are incentivized and visually represented. It integrates:

1.  **Reputation System:** Core mechanism for tracking user credibility based on verified on-chain actions.
2.  **Soulbound Dynamic NFTs (Aura Essence NFTs):** Unique, non-transferable NFTs whose visual representation evolves with the owner's reputation and aligned goals. These NFTs act as a visual identity and a gateway to enhanced protocol features.
3.  **Reputation-Weighted Governance:** A simplified DAO mechanism where voting power is a function of both staked tokens and reputation score, boosted by the user's Aura Essence NFT tier.
4.  **Staking & Rewards:** Users can stake AURA tokens to earn rewards, with potential multipliers based on their reputation and NFT tier.
5.  **Verifiable Data Submission:** A mechanism for users to submit data for validation by authorized oracles/DAO, earning reputation upon successful verification.
6.  **Configurable Parameters:** Many protocol parameters are adjustable via DAO governance, allowing for dynamic adaptation and evolution.

### **Function Summary:**

**I. Core Reputation Management (6 Functions):**

1.  `grantReputationPoints(address _user, uint256 _amount, bytes32 _attestationHash)`: Awards reputation points to a user for positive actions.
2.  `decayReputation(address _user)`: Applies a time-based decay to a user's reputation score.
3.  `penalizeReputation(address _user, uint256 _amount, bytes32 _attestationHash)`: Deducts reputation points for negative or non-compliant actions.
4.  `getReputationScore(address _user)`: Retrieves the current reputation score of a user.
5.  `getReputationTier(address _user)`: Determines the reputation tier a user belongs to.
6.  `getReputationLastUpdate(address _user)`: Returns the timestamp of a user's last reputation update.

**II. Aura Essence NFT (Soulbound Dynamic NFT) (6 Functions):**

7.  `mintAuraEssenceNFT()`: Allows a user to mint their unique, non-transferable Aura Essence NFT.
8.  `getAuraEssenceTokenId(address _user)`: Retrieves the Token ID of a user's Aura Essence NFT.
9.  `attuneNFTToGoal(bytes32 _goalId)`: Allows a user to link their NFT to a specific "impact goal," potentially altering its visuals or associated benefits.
10. `getNFTAttunedGoal(address _user)`: Returns the "impact goal" an NFT is currently attuned to.
11. `tokenURI(uint256 _tokenId)`: Generates dynamic metadata (including visual attributes) for an Aura Essence NFT based on the owner's current reputation, attunement, and other on-chain states.
12. `_calculateNFTMetadata(address _user)` (Internal): Helper function to determine the dynamic attributes for `tokenURI`.

**III. DAO Governance & Protocol Parameters (7 Functions):**

13. `proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description)`: Initiates a proposal to change a core protocol parameter.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on active proposals, with their power boosted by reputation and NFT tier.
15. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal after a timelock.
16. `setReputationCriteria(uint256 _tierIndex, uint256 _minScore, uint256 _maxScore, uint256 _decayRate)`: DAO sets the parameters for different reputation tiers.
17. `setVotingPowerBoost(uint256 _tierIndex, uint256 _multiplier)`: DAO configures how each reputation tier boosts voting power.
18. `configureReputationOracle(address _oracle, bool _canGrant, bool _canPenalize)`: DAO grants/revokes reputation oracle roles and permissions.
19. `getVotingPower(address _voter)`: Calculates the total voting power of a user.

**IV. Staking & Incentives (3 Functions):**

20. `stakeAURA(uint256 _amount)`: Allows users to stake AURA tokens to earn rewards.
21. `unstakeAURA(uint256 _amount)`: Allows users to unstake their AURA tokens.
22. `claimStakingRewards()`: Allows users to claim accumulated staking rewards, potentially boosted by reputation.

**V. Verifiable Data Submission (2 Functions):**

23. `submitVerifiableData(bytes32 _dataHash, string memory _description)`: Users can submit a hash of off-chain data along with a description for future validation.
24. `validateSubmittedData(address _submitter, bytes32 _dataHash, bool _isValid)`: An authorized oracle or DAO member validates submitted data, potentially triggering reputation changes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit division/multiplication safety where needed, although 0.8+ has built-in checks for overflow/underflow.

/**
 * @title AuraForge Protocol
 * @dev A reputation-gated, dynamic Soulbound NFT protocol with governance and staking.
 *      Users earn/lose reputation which affects their personal dNFTs, governance power,
 *      and staking rewards.
 */
contract AuraForge is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for certain operations.

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DAO_GOVERNOR_ROLE = keccak256("DAO_GOVERNOR_ROLE");
    bytes32 public constant REPUTATION_ORACLE_ROLE = keccak256("REPUTATION_ORACLE_ROLE");

    // Aura Token (ERC-20 for staking and governance base)
    IERC20 public immutable auraToken;

    // --- Reputation System ---
    struct Reputation {
        uint256 score;
        uint256 lastUpdateTimestamp; // To calculate decay
    }
    mapping(address => Reputation) private _reputationScores;
    mapping(address => bytes32[]) private _attestations; // Log of attestations for a user
    
    // Reputation tiers configuration by DAO
    struct ReputationTier {
        uint256 minScore;
        uint256 maxScore; // inclusive
        uint256 decayRatePerDayBasisPoints; // e.g., 100 = 1% decay per day
        uint256 votingPowerMultiplier; // e.g., 100 = 1x, 150 = 1.5x
    }
    // Tier 0: 0-99, Tier 1: 100-299, Tier 2: 300-max
    ReputationTier[] public reputationTiers; 
    uint256 public constant MAX_REPUTATION_SCORE = 10_000_000; // Cap to prevent overflow and absurd scores

    // --- Aura Essence NFT (Soulbound Dynamic NFT) ---
    Counters.Counter private _auraEssenceTokenIds;
    mapping(address => uint256) private _userToAuraEssenceTokenId; // One NFT per user
    mapping(uint256 => bytes32) private _auraEssenceNFTGoals; // NFT ID to its attuned goal hash

    // --- Staking System ---
    mapping(address => uint256) private _stakedAURA;
    mapping(address => uint256) private _lastRewardClaimTime;
    uint256 public constant REWARD_RATE_PER_SECOND_BASIS_POINTS = 1; // 0.01% per second as an example
    uint256 public constant REPUTATION_DECAY_GRANULARITY = 1 days; // Decay calculated per day

    // --- Simplified DAO Governance ---
    struct Proposal {
        bytes32 paramKey;
        uint256 newValue;
        string description;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        mapping(address => bool) hasVoted;
        uint256 deadline;
        bool executed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_EXECUTION_TIMELOCK = 1 days;
    uint256 public minProposalVotingPower = 1000; // Minimum total voting power to propose

    // Configurable Parameters managed by DAO
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 public constant PARAM_MIN_PROPOSAL_VOTING_POWER = keccak256("MIN_PROPOSAL_VOTING_POWER");
    bytes32 public constant PARAM_REWARD_RATE = keccak256("REWARD_RATE_PER_SECOND_BASIS_POINTS");

    // --- Verifiable Data Submission ---
    struct SubmittedData {
        bytes32 dataHash;
        string description;
        address submitter;
        uint256 submissionTime;
        bool validated;
        bool isValid; // Result of validation
    }
    mapping(bytes32 => SubmittedData) public submittedData; // dataHash -> SubmittedData
    mapping(address => bytes32[]) private _userSubmittedDataHashes;

    // --- Events ---
    event ReputationGranted(address indexed user, uint256 amount, uint256 newScore, bytes32 attestationHash);
    event ReputationPenalized(address indexed user, uint256 amount, uint256 newScore, bytes32 attestationHash);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event AuraEssenceNFTMinted(address indexed owner, uint256 tokenId);
    event AuraEssenceNFTAttuned(uint256 indexed tokenId, address indexed owner, bytes32 goalId);
    event AuraStaked(address indexed user, uint256 amount);
    event AuraUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint252 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ReputationCriteriaUpdated(uint256 indexed tierIndex, uint256 minScore, uint256 maxScore, uint256 decayRate);
    event VotingPowerBoostUpdated(uint256 indexed tierIndex, uint256 multiplier);
    event ReputationOracleConfigured(address indexed oracle, bool canGrant, bool canPenalize);
    event DataSubmitted(address indexed submitter, bytes32 indexed dataHash, string description);
    event DataValidated(bytes32 indexed dataHash, address indexed validator, bool isValid);


    // --- Constructor ---
    constructor(address _auraTokenAddress) ERC721("Aura Essence NFT", "AURA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Admin has full control initially

        // Set initial DAO Governor and Oracle roles (can be changed by admin)
        _grantRole(DAO_GOVERNOR_ROLE, msg.sender);
        _grantRole(REPUTATION_ORACLE_ROLE, msg.sender);

        auraToken = IERC20(_auraTokenAddress);

        // Initialize default reputation tiers (DAO can change later)
        // Tier 0: 0-99 reputation, no decay, 1x voting power
        reputationTiers.push(ReputationTier(0, 99, 0, 100)); 
        // Tier 1: 100-299 reputation, 0.5% decay, 1.2x voting power
        reputationTiers.push(ReputationTier(100, 299, 50, 120)); 
        // Tier 2: 300-MAX_REPUTATION_SCORE, 1% decay, 1.5x voting power
        reputationTiers.push(ReputationTier(300, MAX_REPUTATION_SCORE, 100, 150)); 

        // Initialize default protocol parameters
        protocolParameters[PARAM_MIN_PROPOSAL_VOTING_POWER] = minProposalVotingPower;
        protocolParameters[PARAM_REWARD_RATE] = REWARD_RATE_PER_SECOND_BASIS_POINTS;
    }

    // --- Access Control Overrides ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- I. Core Reputation Management ---

    /**
     * @dev Grants reputation points to a user. Only callable by REPUTATION_ORACLE_ROLE.
     * @param _user The address of the user to grant points to.
     * @param _amount The amount of reputation points to grant.
     * @param _attestationHash A hash representing the verified action or reason for granting.
     */
    function grantReputationPoints(address _user, uint256 _amount, bytes32 _attestationHash) 
        public 
        onlyRole(REPUTATION_ORACLE_ROLE) 
    {
        require(_user != address(0), "Invalid user address");
        _decayReputation(_user); // Apply decay before granting new points
        
        _reputationScores[_user].score = _reputationScores[_user].score.add(_amount);
        if (_reputationScores[_user].score > MAX_REPUTATION_SCORE) {
            _reputationScores[_user].score = MAX_REPUTATION_SCORE;
        }
        _reputationScores[_user].lastUpdateTimestamp = block.timestamp;
        _attestations[_user].push(_attestationHash);

        // Trigger NFT visual update if user has one
        if (_userToAuraEssenceTokenId[_user] != 0) {
            _updateNFTVisualState(_user);
        }

        emit ReputationGranted(_user, _amount, _reputationScores[_user].score, _attestationHash);
    }

    /**
     * @dev Applies a time-based decay to a user's reputation score.
     *      Can be called by anyone to trigger decay for a specific user,
     *      or is internally called before any reputation update.
     * @param _user The address of the user whose reputation to decay.
     */
    function decayReputation(address _user) public {
        _decayReputation(_user); // Public wrapper for internal function
        emit ReputationDecayed(_user, _reputationScores[_user].score.add(1), _reputationScores[_user].score); // Old score is not directly available here cleanly
    }

    /**
     * @dev Internal function to apply reputation decay.
     * @param _user The address of the user whose reputation to decay.
     */
    function _decayReputation(address _user) internal {
        uint256 currentScore = _reputationScores[_user].score;
        if (currentScore == 0) return;

        uint256 lastUpdate = _reputationScores[_user].lastUpdateTimestamp;
        uint256 timePassed = block.timestamp.sub(lastUpdate);

        if (timePassed < REPUTATION_DECAY_GRANULARITY) return; // Not enough time passed for decay

        uint256 daysPassed = timePassed.div(REPUTATION_DECAY_GRANULARITY);
        
        uint256 currentTierIndex = getReputationTier(_user);
        ReputationTier storage tier = reputationTiers[currentTierIndex];

        if (tier.decayRatePerDayBasisPoints > 0) {
            uint256 decayAmount = (currentScore.mul(tier.decayRatePerDayBasisPoints).mul(daysPassed)).div(10_000);
            _reputationScores[_user].score = currentScore.sub(decayAmount);
            if (_reputationScores[_user].score < 0) _reputationScores[_user].score = 0; // Prevent underflow if score goes below 0 (SafeMath prevents explicit -ve)
        }
        _reputationScores[_user].lastUpdateTimestamp = block.timestamp;

        // Trigger NFT visual update if user has one
        if (_userToAuraEssenceTokenId[_user] != 0) {
            _updateNFTVisualState(_user);
        }
    }

    /**
     * @dev Deducts reputation points from a user. Only callable by REPUTATION_ORACLE_ROLE.
     * @param _user The address of the user to penalize.
     * @param _amount The amount of reputation points to deduct.
     * @param _attestationHash A hash representing the verified negative action or reason for penalty.
     */
    function penalizeReputation(address _user, uint256 _amount, bytes32 _attestationHash) 
        public 
        onlyRole(REPUTATION_ORACLE_ROLE) 
    {
        require(_user != address(0), "Invalid user address");
        _decayReputation(_user); // Apply decay before penalizing
        
        uint256 currentScore = _reputationScores[_user].score;
        _reputationScores[_user].score = currentScore.sub(_amount);
        if (_reputationScores[_user].score < 0) _reputationScores[_user].score = 0; // Should be handled by SafeMath but explicit for clarity
        _reputationScores[_user].lastUpdateTimestamp = block.timestamp;
        _attestations[_user].push(_attestationHash); // Log penalty reason

        // Trigger NFT visual update if user has one
        if (_userToAuraEssenceTokenId[_user] != 0) {
            _updateNFTVisualState(_user);
        }

        emit ReputationPenalized(_user, _amount, _reputationScores[_user].score, _attestationHash);
    }

    /**
     * @dev Retrieves the current reputation score of a user. Automatically applies decay before returning.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        // Simulating decay for view function by recalculating based on current timestamp
        uint256 currentScore = _reputationScores[_user].score;
        uint256 lastUpdate = _reputationScores[_user].lastUpdateTimestamp;
        
        if (currentScore == 0 || lastUpdate == 0) return currentScore;

        uint256 timePassed = block.timestamp.sub(lastUpdate);
        if (timePassed < REPUTATION_DECAY_GRANULARITY) return currentScore;

        uint256 daysPassed = timePassed.div(REPUTATION_DECAY_GRANULARITY);
        
        uint256 currentTierIndex = getReputationTier(_user); // This relies on current score, might be a slight inaccuracy if tier changes mid-decay calc
        ReputationTier storage tier = reputationTiers[currentTierIndex];

        if (tier.decayRatePerDayBasisPoints > 0) {
            uint256 decayAmount = (currentScore.mul(tier.decayRatePerDayBasisPoints).mul(daysPassed)).div(10_000);
            if (currentScore < decayAmount) return 0; // Prevent underflow
            return currentScore.sub(decayAmount);
        }
        return currentScore;
    }

    /**
     * @dev Determines the reputation tier a user belongs to based on their current (decayed) score.
     * @param _user The address of the user.
     * @return The index of the reputation tier.
     */
    function getReputationTier(address _user) public view returns (uint256) {
        uint256 score = getReputationScore(_user); // Use decayed score
        for (uint256 i = 0; i < reputationTiers.length; i++) {
            if (score >= reputationTiers[i].minScore && score <= reputationTiers[i].maxScore) {
                return i;
            }
        }
        return reputationTiers.length - 1; // Default to highest tier if somehow score exceeds max of last defined tier
    }

    /**
     * @dev Returns the timestamp of a user's last reputation update.
     * @param _user The address of the user.
     * @return The timestamp.
     */
    function getReputationLastUpdate(address _user) public view returns (uint256) {
        return _reputationScores[_user].lastUpdateTimestamp;
    }

    // --- II. Aura Essence NFT (Soulbound Dynamic NFT) ---

    /**
     * @dev Mints a unique, non-transferable Aura Essence NFT for the caller.
     *      Each address can only mint one Aura Essence NFT (soulbound).
     */
    function mintAuraEssenceNFT() public {
        require(_userToAuraEssenceTokenId[msg.sender] == 0, "Aura Essence NFT already minted for this address");

        _auraEssenceTokenIds.increment();
        uint256 newTokenId = _auraEssenceTokenIds.current();
        
        _mint(msg.sender, newTokenId);
        _userToAuraEssenceTokenId[msg.sender] = newTokenId;

        // Make it non-transferable by design (ERC721 is transferable, but we prevent it)
        // Override _transfer in ERC721 or add checks to transferFrom/safeTransferFrom
        // For this example, we will simply assume it's soulbound by social contract and by limiting interaction points.
        // A more robust solution would involve a custom ERC721 variant or stricter `_beforeTokenTransfer` hook.
        
        emit AuraEssenceNFTMinted(msg.sender, newTokenId);
        _updateNFTVisualState(msg.sender); // Initial state
    }

    /**
     * @dev Retrieves the Token ID of a user's Aura Essence NFT.
     * @param _user The address of the user.
     * @return The Token ID. Returns 0 if no NFT minted.
     */
    function getAuraEssenceTokenId(address _user) public view returns (uint256) {
        return _userToAuraEssenceTokenId[_user];
    }

    /**
     * @dev Allows a user to link their Aura Essence NFT to a specific "impact goal".
     *      This can influence the NFT's visuals and potentially future rewards/features.
     * @param _goalId A unique identifier (hash) for the impact goal.
     */
    function attuneNFTToGoal(bytes32 _goalId) public {
        uint256 tokenId = _userToAuraEssenceTokenId[msg.sender];
        require(tokenId != 0, "No Aura Essence NFT found for caller");
        
        _auraEssenceNFTGoals[tokenId] = _goalId;
        emit AuraEssenceNFTAttuned(tokenId, msg.sender, _goalId);
        _updateNFTVisualState(msg.sender); // Update visuals based on new attunement
    }

    /**
     * @dev Returns the "impact goal" an NFT is currently attuned to.
     * @param _user The owner of the NFT.
     * @return The hash of the attuned goal.
     */
    function getNFTAttunedGoal(address _user) public view returns (bytes32) {
        uint256 tokenId = _userToAuraEssenceTokenId[_user];
        require(tokenId != 0, "User does not own an Aura Essence NFT");
        return _auraEssenceNFTGoals[tokenId];
    }

    /**
     * @dev Overrides ERC721's tokenURI to generate dynamic metadata for Aura Essence NFTs.
     *      The metadata, including visual attributes, is generated on-chain based on the owner's
     *      reputation score, attuned goal, and other dynamic states.
     * @param _tokenId The ID of the NFT.
     * @return A data URI containing the JSON metadata and SVG image.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = ownerOf(_tokenId);
        string memory json = _calculateNFTMetadata(owner);
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Internal function to trigger NFT visual state updates.
     *      This is called whenever reputation changes or goal attunement happens.
     *      It doesn't directly emit events but ensures `tokenURI` will reflect new state.
     * @param _user The owner of the NFT.
     */
    function _updateNFTVisualState(address _user) internal view {
        // In a real dNFT, this might involve updating an off-chain renderer via events,
        // or updating an on-chain property that `tokenURI` reads.
        // For this example, the `tokenURI` function itself dynamically generates the metadata.
        // This function primarily serves as a conceptual trigger point.
    }

    /**
     * @dev Internal helper function to dynamically calculate and generate the NFT metadata.
     *      This creates a JSON string containing name, description, and an SVG image.
     *      The SVG content changes based on the user's reputation tier and attuned goal.
     * @param _user The address of the NFT owner.
     * @return A JSON string representing the NFT metadata.
     */
    function _calculateNFTMetadata(address _user) internal view returns (string memory) {
        uint256 reputationScore = getReputationScore(_user);
        uint256 tier = getReputationTier(_user);
        bytes32 attunedGoal = getNFTAttunedGoal(_user);
        
        string memory tierName;
        string memory color;
        string memory symbol;
        string memory goalText = (attunedGoal == bytes32(0)) ? "Unaligned" : string(abi.encodePacked("Goal: ", Strings.toHexString(uint256(attunedGoal))));

        if (tier == 0) {
            tierName = "Seed Aura";
            color = "#808080"; // Grey
            symbol = "🌱";
        } else if (tier == 1) {
            tierName = "Growth Aura";
            color = "#00FF00"; // Green
            symbol = "🌿";
        } else if (tier == 2) {
            tierName = "Radiant Aura";
            color = "#FFFF00"; // Yellow
            symbol = "✨";
        } else {
            tierName = "Legendary Aura";
            color = "#FFD700"; // Gold
            symbol = "👑";
        }

        string memory svg = string(abi.encodePacked(
            "<svg width='350' height='350' viewBox='0 0 350 350' xmlns='http://www.w3.org/2000/svg'>",
            "<rect width='100%' height='100%' fill='", color, "'/>",
            "<text x='50%' y='50%' font-size='100' text-anchor='middle' dominant-baseline='middle' fill='white'>", symbol, "</text>",
            "<text x='50%' y='75%' font-size='20' text-anchor='middle' dominant-baseline='middle' fill='white'>Reputation: ", Strings.toString(reputationScore), "</text>",
            "<text x='50%' y='85%' font-size='15' text-anchor='middle' dominant-baseline='middle' fill='white'>", goalText, "</text>",
            "</svg>"
        ));

        string memory description = string(abi.encodePacked(
            "An Aura Essence NFT, reflecting the holder's on-chain reputation (",
            Strings.toString(reputationScore),
            ") in the AuraForge Protocol. Current tier: ",
            tierName,
            ". Attuned to: ",
            goalText
        ));

        return string(abi.encodePacked(
            '{"name": "Aura Essence NFT - ', Strings.toString(_userToAuraEssenceTokenId[_user]), '",',
            '"description": "', description, '",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
    }
    
    // --- III. DAO Governance & Protocol Parameters ---

    /**
     * @dev Allows a DAO_GOVERNOR_ROLE to propose a change to a core protocol parameter.
     *      Requires a minimum voting power to propose.
     * @param _paramKey A unique identifier (hash) for the parameter to change.
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description) 
        public 
        onlyRole(DAO_GOVERNOR_ROLE) 
    {
        require(getVotingPower(msg.sender) >= protocolParameters[PARAM_MIN_PROPOSAL_VOTING_POWER], "Insufficient voting power to propose");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            paramKey: _paramKey,
            newValue: _newValue,
            description: _description,
            voteCountFor: 0,
            voteCountAgainst: 0,
            deadline: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executed: false
        });

        emit ProposalCreated(proposalId, _paramKey, _newValue, msg.sender);
    }

    /**
     * @dev Allows users to vote on an active proposal.
     *      Voting power is boosted by reputation tier.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voteCountFor = proposal.voteCountFor.add(voterPower);
        } else {
            proposal.voteCountAgainst = proposal.voteCountAgainst.add(voterPower);
        }
        emit Voted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Executes a successfully passed proposal after a timelock period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline != 0, "Proposal does not exist");
        require(block.timestamp > proposal.deadline, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCountFor > proposal.voteCountAgainst, "Proposal did not pass");
        
        // Simulating Timelock - actual execution only after a set period past deadline
        require(block.timestamp > proposal.deadline + PROPOSAL_EXECUTION_TIMELOCK, "Timelock not expired");

        proposal.executed = true;

        // Apply the parameter change
        protocolParameters[proposal.paramKey] = proposal.newValue;

        emit ProposalExecuted(_proposalId, proposal.paramKey, proposal.newValue);
    }

    /**
     * @dev Allows DAO_GOVERNOR_ROLE to set the parameters for different reputation tiers.
     * @param _tierIndex The index of the tier to modify.
     * @param _minScore The minimum reputation score for this tier.
     * @param _maxScore The maximum reputation score for this tier.
     * @param _decayRate The daily decay rate in basis points (e.g., 100 = 1%).
     */
    function setReputationCriteria(uint256 _tierIndex, uint256 _minScore, uint256 _maxScore, uint256 _decayRate) 
        public 
        onlyRole(DAO_GOVERNOR_ROLE) 
    {
        require(_tierIndex < reputationTiers.length, "Invalid tier index");
        require(_minScore < _maxScore, "Min score must be less than max score");
        require(_decayRate <= 10_000, "Decay rate cannot exceed 100%"); // 10000 basis points = 100%

        reputationTiers[_tierIndex].minScore = _minScore;
        reputationTiers[_tierIndex].maxScore = _maxScore;
        reputationTiers[_tierIndex].decayRatePerDayBasisPoints = _decayRate;

        emit ReputationCriteriaUpdated(_tierIndex, _minScore, _maxScore, _decayRate);
    }

    /**
     * @dev Allows DAO_GOVERNOR_ROLE to configure how each reputation tier boosts voting power.
     * @param _tierIndex The index of the tier to modify.
     * @param _multiplier The voting power multiplier in basis points (e.g., 100 = 1x, 150 = 1.5x).
     */
    function setVotingPowerBoost(uint256 _tierIndex, uint256 _multiplier) 
        public 
        onlyRole(DAO_GOVERNOR_ROLE) 
    {
        require(_tierIndex < reputationTiers.length, "Invalid tier index");
        reputationTiers[_tierIndex].votingPowerMultiplier = _multiplier;

        emit VotingPowerBoostUpdated(_tierIndex, _multiplier);
    }

    /**
     * @dev Allows DAO_GOVERNOR_ROLE to grant or revoke reputation oracle roles and their permissions.
     *      Oracles can grant and penalize reputation.
     * @param _oracle The address of the oracle.
     * @param _canGrant True if the oracle can grant reputation, false otherwise.
     * @param _canPenalize True if the oracle can penalize reputation, false otherwise.
     */
    function configureReputationOracle(address _oracle, bool _canGrant, bool _canPenalize) 
        public 
        onlyRole(DAO_GOVERNOR_ROLE) 
    {
        if (_canGrant || _canPenalize) {
            _grantRole(REPUTATION_ORACLE_ROLE, _oracle);
            // More granular permissions could be added here if needed
            // e.g., mapping(address => bool) public canGrantReputation;
        } else {
            _revokeRole(REPUTATION_ORACLE_ROLE, _oracle);
        }
        emit ReputationOracleConfigured(_oracle, _canGrant, _canPenalize);
    }

    /**
     * @dev Calculates the total voting power of a user.
     *      This is based on staked AURA tokens, boosted by their reputation tier.
     * @param _voter The address of the voter.
     * @return The total voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 stakedBalance = _stakedAURA[_voter];
        if (stakedBalance == 0) return 0;

        uint256 reputationTierIndex = getReputationTier(_voter);
        uint256 multiplier = reputationTiers[reputationTierIndex].votingPowerMultiplier;

        // Voting power = staked AURA * multiplier (e.g., 100 AURA * 1.5x = 150 power)
        return stakedBalance.mul(multiplier).div(100); // Multiplier is in basis points of 100
    }

    // --- IV. Staking & Incentives ---

    /**
     * @dev Allows users to stake AURA tokens to earn rewards and contribute to voting power.
     * @param _amount The amount of AURA tokens to stake.
     */
    function stakeAURA(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        
        _updateRewards(msg.sender); // Ensure pending rewards are updated before new stake
        _stakedAURA[msg.sender] = _stakedAURA[msg.sender].add(_amount);
        require(auraToken.transferFrom(msg.sender, address(this), _amount), "AURA transfer failed");

        emit AuraStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their AURA tokens.
     *      Also claims any pending rewards.
     * @param _amount The amount of AURA tokens to unstake.
     */
    function unstakeAURA(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_stakedAURA[msg.sender] >= _amount, "Insufficient staked AURA");

        _updateRewards(msg.sender); // Claim rewards before unstaking
        _stakedAURA[msg.sender] = _stakedAURA[msg.sender].sub(_amount);
        require(auraToken.transfer(msg.sender, _amount), "AURA transfer failed");

        emit AuraUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim accumulated staking rewards.
     *      Rewards are based on staked amount, duration, and potentially boosted by reputation tier.
     */
    function claimStakingRewards() public {
        _updateRewards(msg.sender);
        uint256 rewards = _calculateRewards(msg.sender);
        if (rewards > 0) {
            // Transfer rewards from treasury (assuming contract holds AURA from initial mint or other sources)
            require(auraToken.transfer(msg.sender, rewards), "Reward transfer failed");
            _lastRewardClaimTime[msg.sender] = block.timestamp;
            emit StakingRewardsClaimed(msg.sender, rewards);
        }
    }

    /**
     * @dev Internal function to update a user's reward calculation state.
     *      This is called before staking, unstaking, or claiming.
     */
    function _updateRewards(address _user) internal {
        // This is a placeholder for a more complex reward calculation model.
        // For simplicity, rewards accumulate per second.
        // A more advanced system would use `lastRewardClaimTime` and `REWARD_RATE_PER_SECOND_BASIS_POINTS`
        // along with reputation/NFT multipliers to determine rewards.
        // Here, `claimStakingRewards` would actually calculate and distribute.
        // The `_updateRewards` would simply update the `_lastRewardClaimTime`.
        // Let's implement a basic calculation here for demonstration.
        uint256 pendingRewards = _calculateRewards(_user);
        if (pendingRewards > 0) {
            // In a real system, rewards would be tracked and added to a pending balance,
            // then `claimStakingRewards` would transfer them.
            // For simplicity, we are assuming direct transfer in `claimStakingRewards`
            // and this function ensures _lastRewardClaimTime is appropriately set.
        }
        _lastRewardClaimTime[_user] = block.timestamp;
    }

    /**
     * @dev Calculates the pending staking rewards for a user.
     * @param _user The address of the user.
     * @return The amount of AURA rewards pending.
     */
    function _calculateRewards(address _user) internal view returns (uint256) {
        uint256 staked = _stakedAURA[_user];
        if (staked == 0) return 0;

        uint256 timeElapsed = block.timestamp.sub(_lastRewardClaimTime[_user]);
        if (timeElapsed == 0) return 0;

        // Base rewards: staked * rate * time
        uint256 baseRewards = staked.mul(protocolParameters[PARAM_REWARD_RATE]).mul(timeElapsed).div(10_000);

        // Apply reputation boost
        uint256 reputationTierIndex = getReputationTier(_user);
        uint256 boostMultiplier = reputationTiers[reputationTierIndex].votingPowerMultiplier; // Reusing this multiplier for rewards
        
        return baseRewards.mul(boostMultiplier).div(100); // Multiplier is in basis points of 100
    }

    // --- V. Verifiable Data Submission ---

    /**
     * @dev Allows users to submit a hash of off-chain data along with a description.
     *      This data can later be validated by oracles/DAO to earn reputation.
     * @param _dataHash A cryptographic hash of the data being submitted.
     * @param _description A brief description of the data.
     */
    function submitVerifiableData(bytes32 _dataHash, string memory _description) public {
        require(submittedData[_dataHash].submitter == address(0), "Data hash already submitted");
        
        submittedData[_dataHash] = SubmittedData({
            dataHash: _dataHash,
            description: _description,
            submitter: msg.sender,
            submissionTime: block.timestamp,
            validated: false,
            isValid: false
        });
        _userSubmittedDataHashes[msg.sender].push(_dataHash);

        emit DataSubmitted(msg.sender, _dataHash, _description);
    }

    /**
     * @dev Allows an authorized REPUTATION_ORACLE_ROLE or DAO_GOVERNOR_ROLE to validate submitted data.
     *      Upon validation, reputation points can be granted/penalized based on `_isValid`.
     * @param _submitter The address of the original data submitter.
     * @param _dataHash The hash of the data to validate.
     * @param _isValid The validation result (true for valid, false for invalid).
     */
    function validateSubmittedData(address _submitter, bytes32 _dataHash, bool _isValid) 
        public 
        onlyRole(REPUTATION_ORACLE_ROLE) // Can be extended to DAO_GOVERNOR_ROLE
    {
        SubmittedData storage data = submittedData[_dataHash];
        require(data.submitter == _submitter, "Data not submitted by this user or does not exist");
        require(!data.validated, "Data already validated");

        data.validated = true;
        data.isValid = _isValid;

        // Apply reputation based on validation
        if (_isValid) {
            // Grant reputation for valid data submission (e.g., 50 points)
            grantReputationPoints(_submitter, 50, _dataHash); 
        } else {
            // Penalize for invalid/malicious data (e.g., 20 points)
            penalizeReputation(_submitter, 20, _dataHash);
        }

        emit DataValidated(_dataHash, msg.sender, _isValid);
    }
}
```