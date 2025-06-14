Okay, here is a Solidity smart contract featuring a concept I'll call "VoyagerBadge". It's a dynamic NFT (ERC-721) that represents a user's on-chain journey and reputation within this system, earning points ("Chronos") and leveling up based on interactions. It includes elements of gamification, data association, and a simplified voting mechanism tied to the Badge's progression.

This design aims to be creative by combining dynamic NFT metadata (driven by on-chain actions), a simple point/leveling system, simulated staking rewards based on holding/interacting, associating external data (like an IPFS hash for a profile), and a basic voting system weighted by the NFT's level. It avoids duplicating a single, standard open-source contract like a basic ERC20, ERC721, or a standard staking/voting contract by weaving these mechanics into a single, stateful NFT system.

---

**Contract: VoyagerBadge**

**Outline:**

1.  **Contract Information:** SPDX License, Pragma, Imports.
2.  **Interfaces:** (If necessary, though for this design, standard ERC721 is enough).
3.  **Libraries:** OpenZeppelin (ERC721, Ownable, Pausable, Counters).
4.  **State Variables:**
    *   Counters for token IDs and proposals.
    *   Mappings for Chronos points, levels, staking status, staked claim history, associated data hashes.
    *   Parameters for Chronos earning rates (achievements, staking).
    *   Level thresholds (Chronos required for each level).
    *   Governance proposal struct and mapping.
    *   Voting history mapping.
    *   Base URI for metadata.
5.  **Events:** For key actions (Mint, Burn, ChronosEarned, LevelUp, DataAssociated, ProposalCreated, Voted, ProposalExecuted).
6.  **Modifiers:** Custom modifiers for access control beyond Ownable (e.g., `onlyBadgeOwner`, `whenBadgeStaked`).
7.  **Constructor:** Initializes owner, base URI, and initial parameters.
8.  **Core ERC-721 Functions:** (`tokenURI` - customized to reflect dynamic state).
9.  **Admin Functions:** (`setBaseURI`, `pause`, `unpause`, `updateAchievementChronosValue`, `updateStakingChronosPerDay`, `updateLevelThresholds`, `withdrawETH`).
10. **Badge Management Functions:** (`mintBadge`, `burnBadge`).
11. **Chronos & Level Functions:** (`getChronosBalance`, `getVoyagerLevel`, `getLevelThreshold`, `_calculateVoyagerLevel` - internal helper).
12. **Progression Functions:** (`registerAchievement`, `burnChronosForBoost`).
13. **Staking/Holding Reward Functions:** (`stakeBadgeForChronos`, `unstakeBadge`, `claimStakedChronos`, `_calculatePendingStakingReward` - internal helper, `isBadgeStaked`, `getBadgeStakedStartTime`).
14. **Data Association Functions:** (`associateDataHash`, `getDataHash`).
15. **Governance Functions:** (`createProposal`, `voteOnProposal`, `executeProposal`, `getProposalState`, `getProposal`, `getVoteCount`).

**Function Summary:**

1.  `constructor(string memory baseURI_)`: Initializes the contract, setting the deployer as owner and establishing the base URI for NFT metadata. Sets initial Chronos earning rates and level thresholds.
2.  `setBaseURI(string memory baseURI_)`: Owner-only function to update the base URI for token metadata.
3.  `pause()`: Owner-only function to pause state-changing operations.
4.  `unpause()`: Owner-only function to unpause the contract.
5.  `updateAchievementChronosValue(uint256 newValue)`: Owner-only function to set the Chronos points awarded for registering an achievement.
6.  `updateStakingChronosPerDay(uint256 newValue)`: Owner-only function to set the Chronos points earned per staked day.
7.  `updateLevelThresholds(uint256[] memory newThresholds)`: Owner-only function to update the Chronos thresholds required for each level.
8.  `withdrawETH()`: Owner-only function to withdraw any Ether accidentally sent to the contract.
9.  `mintBadge()`: Allows any user to mint a new Voyager Badge NFT for themselves. Sets initial Chronos and level (level 0).
10. `burnBadge(uint256 tokenId)`: Allows the owner of a Badge to burn it, removing it from existence along with associated Chronos and data.
11. `getChronosBalance(uint256 tokenId)`: Returns the current Chronos balance for a specific Badge.
12. `getVoyagerLevel(uint256 tokenId)`: Returns the current level of a specific Badge based on its Chronos balance and the defined thresholds.
13. `getLevelThreshold(uint8 level)`: Returns the Chronos required to reach a specific level.
14. `registerAchievement(uint256 tokenId)`: Allows the owner of a Badge to register an achievement, awarding Chronos points and potentially increasing the Badge's level. Requires the Badge to be owned by the caller and not staked.
15. `burnChronosForBoost(uint256 tokenId, uint256 amount)`: Allows the owner of a Badge to burn a specified amount of Chronos points. This is a placeholder for future mechanics where burning Chronos grants a temporary boost or effect.
16. `stakeBadgeForChronos(uint256 tokenId)`: Allows the owner of a Badge to stake it, starting a timer for earning staking rewards (Chronos). Requires the Badge to be owned by the caller and not already staked.
17. `unstakeBadge(uint256 tokenId)`: Allows the owner of a staked Badge to unstake it. Calculates and adds accrued staking rewards to the Chronos balance, updates the staking state. Requires the Badge to be owned by the caller and to be staked.
18. `claimStakedChronos(uint256 tokenId)`: (Alternative to unstake for claiming without unstaking, or integrated into unstake) - *Decision:* Integrate into `unstakeBadge` and add a separate view function `getPendingStakingReward`. So, need functions:
    *   `isBadgeStaked(uint256 tokenId)`: Checks if a badge is currently staked.
    *   `getBadgeStakedStartTime(uint256 tokenId)`: Returns the timestamp when a badge was staked.
    *   `getPendingStakingReward(uint256 tokenId)`: Calculates and returns the Chronos reward accrued since staking began (or last claim/unstake) without modifying state.
19. `associateDataHash(uint256 tokenId, bytes32 dataHash)`: Allows the owner of a Badge to associate an external data hash (like an IPFS hash for profile data or achievements) with the Badge.
20. `getDataHash(uint256 tokenId)`: Returns the associated data hash for a specific Badge.
21. `createProposal(string memory description, uint8 proposalType, uint256 targetValue)`: Allows any Badge holder to create a governance proposal to change a contract parameter (e.g., earning rates). Requires minimum level? (Let's add a min level requirement).
22. `voteOnProposal(uint256 proposalId, bool support)`: Allows a Badge holder to vote on an active proposal. Voting weight is determined by the Badge's current level. Each unique Badge can vote once per proposal.
23. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal that has ended and met the voting requirements (e.g., majority vote). Applies the proposed change to the contract state.
24. `getProposalState(uint256 proposalId)`: Returns the current state of a governance proposal (Pending, Active, Succeeded, Defeated, Executed).
25. `getProposal(uint256 proposalId)`: Returns details about a specific proposal.
26. `getVoteCount(uint256 proposalId)`: Returns the current yay and nay vote counts for a proposal.
27. `tokenURI(uint256 tokenId)`: Overrides the ERC721 function to return a URI based on the token ID and the contract's `baseTokenURI`. The off-chain metadata server should use this ID to fetch dynamic data (Chronos, Level, Data Hash) via view functions and construct the final metadata JSON.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Contract: VoyagerBadge ---
// Outline:
// 1. Contract Information: SPDX License, Pragma, Imports.
// 2. Libraries: OpenZeppelin (ERC721, Ownable, Pausable, Counters).
// 3. State Variables: Counters, Mappings (Chronos, levels, staking, data, governance), Parameters, Level Thresholds.
// 4. Events: State changes and key actions.
// 5. Modifiers: Custom access control.
// 6. Constructor: Initialization.
// 7. Core ERC-721 Functions: tokenURI override.
// 8. Admin Functions: Configuration and maintenance.
// 9. Badge Management Functions: Minting and burning.
// 10. Chronos & Level Functions: Getters and internal calculation.
// 11. Progression Functions: Earning and spending Chronos.
// 12. Staking/Holding Reward Functions: Mechanics for earning Chronos over time.
// 13. Data Association Functions: Linking external data.
// 14. Governance Functions: Basic on-chain voting weighted by Badge level.

// Function Summary:
// 1. constructor(string memory baseURI_): Deploys and initializes contract parameters.
// 2. setBaseURI(string memory baseURI_): Admin sets the base URI for NFT metadata.
// 3. pause(): Admin pauses contract state-changing functions.
// 4. unpause(): Admin unpauses the contract.
// 5. updateAchievementChronosValue(uint256 newValue): Admin sets Chronos awarded for achievements.
// 6. updateStakingChronosPerDay(uint256 newValue): Admin sets Chronos awarded per day staked.
// 7. updateLevelThresholds(uint256[] memory newThresholds): Admin sets Chronos required for each level.
// 8. withdrawETH(): Admin withdraws accidentally sent ETH.
// 9. mintBadge(): Mints a new Badge NFT for the caller.
// 10. burnBadge(uint256 tokenId): Allows Badge owner to burn their Badge.
// 11. getChronosBalance(uint256 tokenId): Gets Chronos balance for a Badge.
// 12. getVoyagerLevel(uint256 tokenId): Gets the level of a Badge.
// 13. getLevelThreshold(uint8 level): Gets Chronos needed for a specific level.
// 14. registerAchievement(uint256 tokenId): Awards Chronos for an achievement.
// 15. burnChronosForBoost(uint256 tokenId, uint256 amount): Placeholder to burn Chronos.
// 16. stakeBadgeForChronos(uint256 tokenId): Stakes a Badge to earn Chronos over time.
// 17. unstakeBadge(uint256 tokenId): Unstakes a Badge and claims earned Chronos.
// 18. isBadgeStaked(uint256 tokenId): Checks if a Badge is staked.
// 19. getBadgeStakedStartTime(uint256 tokenId): Gets staking start time.
// 20. getPendingStakingReward(uint256 tokenId): Calculates Chronos earned from staking since last claim/start.
// 21. associateDataHash(uint256 tokenId, bytes32 dataHash): Links external data hash to a Badge.
// 22. getDataHash(uint256 tokenId): Gets the linked data hash.
// 23. createProposal(string memory description, uint8 proposalType, uint256 targetValue): Creates a governance proposal.
// 24. voteOnProposal(uint256 proposalId, bool support): Votes on a proposal using Badge level weight.
// 25. executeProposal(uint256 proposalId): Executes a passed proposal.
// 26. getProposalState(uint256 proposalId): Gets the state of a proposal.
// 27. getProposal(uint256 proposalId): Gets details of a proposal.
// 28. getVoteCount(uint256 proposalId): Gets vote counts for a proposal.

contract VoyagerBadge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextProposalId;

    // Badge State
    mapping(uint256 => uint256) private _chronosPoints; // token ID => Chronos points
    mapping(uint256 => uint8) private _voyagerLevel; // token ID => Level (derived from Chronos)
    mapping(uint256 => uint48) private _badgeStakingStartTime; // token ID => Timestamp when staked (0 if not staked)
    mapping(uint256 => uint256) private _claimedStakingChronos; // token ID => Total Chronos claimed from staking
    mapping(uint256 => bytes32) private _dataHashes; // token ID => Associated data hash (e.g., IPFS)

    // Parameters
    uint256 public chronosPerAchievement = 50;
    uint256 public chronosPerStakedDay = 10; // Chronos points per 24 hours staked
    uint256[] public levelThresholds; // Chronos required for each level (index 0 is level 1 threshold, etc.)
    uint8 public constant MAX_LEVEL = 20; // Cap the level

    // Governance
    struct Proposal {
        address creator;
        string description;
        uint8 proposalType; // e.g., 0: UpdateChronosPerAchievement, 1: UpdateStakingRate
        uint256 targetValue; // New value for the parameter
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yayVotes; // Weighted votes
        uint256 nayVotes; // Weighted votes
        bool executed;
        mapping(address => bool) hasVoted; // address => has voted on this proposal
    }

    mapping(uint256 => Proposal) public proposals; // proposal ID => Proposal data
    uint256 public votingPeriodDuration = 3 days; // Duration proposals are open for voting
    uint8 public constant MIN_LEVEL_TO_CREATE_PROPOSAL = 2; // Minimum level to create a proposal
    uint256 public constant PROPOSAL_PASS_THRESHOLD_BPS = 5000; // 50% (in basis points) of total possible voting power

    // Metadata
    string private _baseTokenURI;

    // --- Events ---

    event BadgeMinted(address indexed owner, uint256 indexed tokenId);
    event BadgeBurned(uint256 indexed tokenId);
    event ChronosEarned(uint256 indexed tokenId, uint256 amount, string method);
    event ChronosBurned(uint256 indexed tokenId, uint256 amount, string method);
    event LevelUp(uint256 indexed tokenId, uint8 newLevel);
    event DataHashAssociated(uint256 indexed tokenId, bytes32 dataHash);
    event BadgeStaked(uint256 indexed tokenId, uint48 timestamp);
    event BadgeUnstaked(uint256 indexed tokenId, uint256 claimedChronos);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, uint8 proposalType, uint256 targetValue, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Modifiers ---

    modifier onlyBadgeOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not badge owner or approved");
        _;
    }

    modifier whenBadgeStaked(uint256 tokenId) {
        require(_badgeStakingStartTime[tokenId] > 0, "Badge is not staked");
        _;
    }

    modifier whenBadgeNotStaked(uint256 tokenId) {
        require(_badgeStakingStartTime[tokenId] == 0, "Badge is already staked");
        _;
    }

    modifier onlyProposalCreator(uint256 proposalId) {
        require(proposals[proposalId].creator == msg.sender, "Not proposal creator");
        _;
    }

    // --- Constructor ---

    constructor(string memory baseURI_) ERC721("VoyagerBadge", "VGB") Ownable(msg.sender) Pausable(false) {
        _baseTokenURI = baseURI_;
        // Set initial level thresholds (example: level 1 requires 100, level 2 requires 300, level 3 requires 600...)
        levelThresholds = [100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500, 6600, 7800, 9100, 10500, 12000, 13600, 15300, 17100, 19000, 21000]; // 20 thresholds for levels 1-20
        require(levelThresholds.length == MAX_LEVEL, "Incorrect number of level thresholds");
    }

    // --- Core ERC-721 Functions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Standard ERC721 check

        // The metadata json should be hosted off-chain.
        // This function returns the base URI + token ID.
        // The off-chain server can then call view functions like
        // getChronosBalance, getVoyagerLevel, getDataHash
        // to construct the dynamic metadata.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // --- Admin Functions ---

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateAchievementChronosValue(uint256 newValue) public onlyOwner whenNotPaused {
        chronosPerAchievement = newValue;
    }

    function updateStakingChronosPerDay(uint256 newValue) public onlyOwner whenNotPaused {
        chronosPerStakedDay = newValue;
    }

    function updateLevelThresholds(uint256[] memory newThresholds) public onlyOwner whenNotPaused {
        require(newThresholds.length == MAX_LEVEL, "Incorrect number of level thresholds");
        levelThresholds = newThresholds;
    }

    // Allow owner to withdraw ETH sent by mistake
    function withdrawETH() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Badge Management Functions ---

    function mintBadge() public whenNotPaused returns (uint256) {
        uint256 newItemId = _nextTokenId.current();
        _nextTokenId.increment();

        _mint(msg.sender, newItemId);
        _chronosPoints[newItemId] = 0;
        _voyagerLevel[newItemId] = 0; // Start at level 0
        _badgeStakingStartTime[newItemId] = 0; // Not staked initially
        _claimedStakingChronos[newItemId] = 0; // No claimed staking rewards yet

        emit BadgeMinted(msg.sender, newItemId);
        return newItemId;
    }

    function burnBadge(uint256 tokenId) public whenNotPaused onlyBadgeOwner(tokenId) {
        // Ensure any pending staking rewards are claimed before burning
        if (_badgeStakingStartTime[tokenId] > 0) {
            unstakeBadge(tokenId); // This will claim rewards and reset staking state
        }

        _burn(tokenId);

        // Clean up associated data
        delete _chronosPoints[tokenId];
        delete _voyagerLevel[tokenId];
        delete _badgeStakingStartTime[tokenId];
        delete _claimedStakingChronos[tokenId];
        delete _dataHashes[tokenId];

        emit BadgeBurned(tokenId);
    }

    // --- Chronos & Level Functions ---

    function getChronosBalance(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _chronosPoints[tokenId];
    }

    function getVoyagerLevel(uint256 tokenId) public view returns (uint8) {
         _requireOwned(tokenId);
         return _voyagerLevel[tokenId]; // Stored level is easier to access
    }

    // Internal helper to calculate level from Chronos
    function _calculateVoyagerLevel(uint256 chronos) internal view returns (uint8) {
        for (uint8 i = 0; i < levelThresholds.length; i++) {
            if (chronos < levelThresholds[i]) {
                return i; // Level i requires less than threshold[i] Chronos
            }
        }
        return MAX_LEVEL; // Achieved maximum level
    }

    function getLevelThreshold(uint8 level) public view returns (uint256) {
        require(level > 0 && level <= MAX_LEVEL, "Invalid level");
        return levelThresholds[level - 1];
    }

    // --- Progression Functions ---

    function registerAchievement(uint256 tokenId) public whenNotPaused onlyBadgeOwner(tokenId) whenBadgeNotStaked(tokenId) {
        require(chronosPerAchievement > 0, "Achievement points not set");

        uint256 currentChronos = _chronosPoints[tokenId];
        uint8 currentLevel = _voyagerLevel[tokenId];
        uint256 newChronos = currentChronos.add(chronosPerAchievement);
        uint8 newLevel = _calculateVoyagerLevel(newChronos);

        _chronosPoints[tokenId] = newChronos;
        emit ChronosEarned(tokenId, chronosPerAchievement, "Achievement");

        if (newLevel > currentLevel) {
            _voyagerLevel[tokenId] = newLevel;
            emit LevelUp(tokenId, newLevel);
        }
    }

    function burnChronosForBoost(uint256 tokenId, uint256 amount) public whenNotPaused onlyBadgeOwner(tokenId) {
        require(_chronosPoints[tokenId] >= amount, "Insufficient Chronos");
        require(amount > 0, "Cannot burn 0 Chronos");

        _chronosPoints[tokenId] = _chronosPoints[tokenId].sub(amount);
        // Placeholder for applying a 'boost' effect off-chain or updating state
        // e.g., mapping(uint256 => uint48) public boostExpirationTime;
        // boostExpirationTime[tokenId] = uint48(block.timestamp + 1 days);

        emit ChronosBurned(tokenId, amount, "Boost");
    }

    // --- Staking/Holding Reward Functions ---

    function stakeBadgeForChronos(uint256 tokenId) public whenNotPaused onlyBadgeOwner(tokenId) whenBadgeNotStaked(tokenId) {
        require(chronosPerStakedDay > 0, "Staking rewards not enabled");
        _badgeStakingStartTime[tokenId] = uint48(block.timestamp);
        emit BadgeStaked(tokenId, uint48(block.timestamp));
    }

    function unstakeBadge(uint256 tokenId) public whenNotPaused onlyBadgeOwner(tokenId) whenBadgeStaked(tokenId) {
        uint256 pendingReward = _calculatePendingStakingReward(tokenId);
        _chronosPoints[tokenId] = _chronosPoints[tokenId].add(pendingReward);
        _claimedStakingChronos[tokenId] = _claimedStakingChronos[tokenId].add(pendingReward);

        // Reset staking state
        _badgeStakingStartTime[tokenId] = 0;

        // Update level if needed
        uint8 currentLevel = _voyagerLevel[tokenId];
        uint8 newLevel = _calculateVoyagerLevel(_chronosPoints[tokenId]);
        if (newLevel > currentLevel) {
             _voyagerLevel[tokenId] = newLevel;
             emit LevelUp(tokenId, newLevel);
        }

        emit ChronosEarned(tokenId, pendingReward, "Staking");
        emit BadgeUnstaked(tokenId, pendingReward);
    }

     function isBadgeStaked(uint256 tokenId) public view returns (bool) {
        _requireOwned(tokenId);
        return _badgeStakingStartTime[tokenId] > 0;
    }

    function getBadgeStakedStartTime(uint256 tokenId) public view returns (uint48) {
        _requireOwned(tokenId);
        return _badgeStakingStartTime[tokenId];
    }

    function getPendingStakingReward(uint256 tokenId) public view whenBadgeStaked(tokenId) returns (uint256) {
         // Calculate time elapsed since last claim/stake
        uint256 elapsedSeconds = block.timestamp - _badgeStakingStartTime[tokenId];
        // Calculate reward based on full days elapsed
        uint256 elapsedDays = elapsedSeconds / (1 days);
        // Total possible reward based on time staked
        uint256 totalPossibleReward = elapsedDays.mul(chronosPerStakedDay);

        // Note: This simple model awards based on *days*. Rewards for partial days are not accrued until a full day passes.
        // More complex models would track fractions or use per-second rates.

        return totalPossibleReward;
    }


    // --- Data Association Functions ---

    function associateDataHash(uint256 tokenId, bytes32 dataHash) public whenNotPaused onlyBadgeOwner(tokenId) {
        _dataHashes[tokenId] = dataHash;
        emit DataHashAssociated(tokenId, dataHash);
    }

    function getDataHash(uint256 tokenId) public view returns (bytes32) {
        _requireOwned(tokenId);
        return _dataHashes[tokenId];
    }

    // --- Governance Functions ---

    // Enum to represent proposal types (expand as needed)
    enum ProposalType { UpdateChronosPerAchievement, UpdateStakingRate }

    // Enum to represent proposal states
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    function createProposal(
        string memory description,
        uint8 proposalType,
        uint256 targetValue
    ) public whenNotPaused {
        uint256 creatorBadgeId = 0; // Need to find the caller's badge
         uint256 supply = totalSupply();
        bool found = false;
        for (uint256 i = 0; i < supply; i++) {
            uint256 currentTokenId = _nextTokenId.current().sub(supply).add(i); // Simple way to iterate minted tokens
             if (_exists(currentTokenId) && ownerOf(currentTokenId) == msg.sender) {
                 creatorBadgeId = currentTokenId;
                 found = true;
                 break;
             }
        }
        require(found, "Caller must own a Badge to create a proposal");
        require(_voyagerLevel[creatorBadgeId] >= MIN_LEVEL_TO_CREATE_PROPOSAL, "Insufficient level to create proposal");

        uint256 proposalId = _nextProposalId.current();
        _nextProposalId.increment();

        proposals[proposalId] = Proposal({
            creator: msg.sender,
            description: description,
            proposalType: proposalType,
            targetValue: targetValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            // hasVoted mapping is inside the struct
        });

        emit ProposalCreated(proposalId, msg.sender, proposalType, targetValue, proposals[proposalId].voteEndTime);
    }

    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "Voting is not active");

        uint256 voterBadgeId = 0; // Need to find the caller's badge
        uint256 supply = totalSupply();
        bool found = false;
         for (uint256 i = 0; i < supply; i++) {
             uint256 currentTokenId = _nextTokenId.current().sub(supply).add(i); // Simple way to iterate minted tokens
              if (_exists(currentTokenId) && ownerOf(currentTokenId) == msg.sender) {
                  voterBadgeId = currentTokenId;
                  found = true;
                  break;
              }
         }
        require(found, "Caller must own a Badge to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal"); // Check if this address has voted

        // Voting weight is the Badge's level + 1 (so level 0 has 1 weight, level 1 has 2 weight, etc.)
        // This encourages leveling up for more influence.
        uint256 voteWeight = uint256(_voyagerLevel[voterBadgeId]) + 1;
        require(voteWeight > 0, "Invalid vote weight"); // Should always be true if badge exists

        if (support) {
            proposal.yayVotes = proposal.yayVotes.add(voteWeight);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(voteWeight);
        }

        proposal.hasVoted[msg.sender] = true; // Record that this address has voted

        emit Voted(proposalId, msg.sender, support, voteWeight);
    }

    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yayVotes.add(proposal.nayVotes);

        bool passed = false;
        if (totalVotes > 0) {
             // Example simple pass condition: > 50% yay votes of *participating* votes
             // For a more robust system, consider quorum (min total votes needed)
             // and potentially weighted total supply or staked vote power for thresholds.
             // This example uses 50% of *participating* votes for simplicity.
            passed = proposal.yayVotes.mul(10000) / totalVotes > PROPOSAL_PASS_THRESHOLD_BPS;

            // Alternative more robust check (requires tracking total voting power available or staked)
            // uint256 totalVotingPower = _calculateTotalVotingPower(); // Needs helper function to sum (level + 1) for all existing/staked badges
            // if (totalVotingPower > 0) {
            //     // Check quorum (e.g., 10% participation)
            //     bool meetsQuorum = totalVotes.mul(10000) / totalVotingPower >= QUORUM_THRESHOLD_BPS;
            //     // Check threshold against total voting power (e.g., needs > 25% of *total* power)
            //     bool meetsThreshold = proposal.yayVotes.mul(10000) / totalVotingPower > PROPOSAL_PASS_THRESHOLD_BPS;
            //     passed = meetsQuorum && meetsThreshold;
            // }
        }


        proposal.executed = true;

        if (passed) {
            // Apply the proposed change based on proposalType
            if (proposal.proposalType == uint8(ProposalType.UpdateChronosPerAchievement)) {
                chronosPerAchievement = proposal.targetValue;
            } else if (proposal.proposalType == uint8(ProposalType.UpdateStakingRate)) {
                chronosPerStakedDay = proposal.targetValue;
            }
            // Add more proposal types and logic here
        }

        emit ProposalExecuted(proposalId, passed);
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creator == address(0)) {
            return ProposalState.Pending; // Represents non-existent
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp < proposal.voteStartTime) {
            return ProposalState.Pending; // Created but voting hasn't started
        } else if (block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime) {
            return ProposalState.Active;
        } else {
             // Voting ended, not yet executed
             uint256 totalVotes = proposal.yayVotes.add(proposal.nayVotes);
             if (totalVotes > 0 && proposal.yayVotes.mul(10000) / totalVotes > PROPOSAL_PASS_THRESHOLD_BPS) {
                  // (Using same simple pass condition as execute)
                  return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
        }
    }

    function getProposal(uint256 proposalId) public view returns (
        address creator,
        string memory description,
        uint8 proposalType,
        uint256 targetValue,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 yayVotes,
        uint256 nayVotes,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");

        return (
            proposal.creator,
            proposal.description,
            proposal.proposalType,
            proposal.targetValue,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.yayVotes,
            proposal.nayVotes,
            proposal.executed
        );
    }

    function getVoteCount(uint256 proposalId) public view returns (uint256 yay, uint256 nay) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        return (proposal.yayVotes, proposal.nayVotes);
    }


    // --- Override required ERC721Enumerable function (if using ERC721Enumerable) ---
    // This simple token iteration is okay for small numbers of tokens,
    // but for a large supply, a better approach might be needed (e.g., tracking token IDs in an array).
    // ERC721 does not strictly require this, but if using extensions like Enumerable, it would.
    // For simplicity, this contract doesn't use Enumerable, so this is not needed.
    // Kept for reference:
    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add logic here if transfers should affect state (e.g., unstake on transfer)
        if (_badgeStakingStartTime[tokenId] > 0) {
             // Unstake before transfer. Need to call internal helper logic or require unstaking first.
             // Calling unstakeBadge(tokenId) directly from here might be complex due to msg.sender checks.
             // A safer approach is to require unstaking before transfer.
             require(_badgeStakingStartTime[tokenId] == 0, "Cannot transfer staked badge. Unstake first.");
        }
    }
    */

    // Helper function to require token ownership/approval within other functions
     function _requireOwned(uint256 tokenId) internal view {
         require(_exists(tokenId), "ERC721: invalid token ID");
         // This doesn't check ownership, only existence. Use ownerOf(tokenId) == msg.sender or onlyBadgeOwner
         // Let's rely on the `onlyBadgeOwner` modifier where needed, or ownerOf checks.
         // For simple getters, existence check is enough.
     }

     // To implement the governance proposal execution more safely for different types,
     // you might use an array of bytes for parameters or more complex structs.
     // The current uint256 targetValue is sufficient for simple parameter updates.
}
```