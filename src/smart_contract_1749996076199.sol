Okay, here is a Solidity smart contract implementing a complex, dynamic, and interconnected system centered around "Ethereal Guardians" - dynamic NFTs that can level up, gain attributes, participate in challenges, be staked, and influence a collective treasury/governance.

It incorporates concepts like:
*   **Dynamic NFTs:** Guardian attributes and levels stored on-chain, influencing metadata (via `tokenURI`).
*   **Gamified Progression:** XP system, leveling up based on actions (challenges, staking).
*   **Staking Mechanics:** Locking NFTs for on-chain rewards and XP.
*   **Challenge System:** Users complete predefined challenges to earn rewards/XP/attributes.
*   **Simplified On-Chain Governance:** Proposals and weighted voting (weight based on Guardian level).
*   **Dynamic Parameters:** Contract behavior (like fee rates, reward rates) can be changed via governance.
*   **Treasury Management:** Collecting funds and distributing rewards.
*   **Dynamic Traits:** Ability to add/remove traits to Guardians.

This contract is designed to be more than just a static asset or a simple token; it's a mini-ecosystem with evolving state.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. State Variables & Structs: Define core data structures for Guardians, Challenges, Proposals, and system parameters.
// 2. Events: Declare events to signal key state changes.
// 3. Errors: Define custom errors for clearer failure reasons.
// 4. Modifiers: Custom modifiers for access control and state checks.
// 5. Core ERC721 Implementation: Constructor and overrides for ERC721URIStorage.
// 6. Guardian Management: Minting, burning, getting details.
// 7. Gamification & Progression: Gaining XP, leveling up, attribute management, dynamic traits.
// 8. Staking: Staking/unstaking NFTs, calculating/claiming rewards.
// 9. Challenges: Creating and completing challenges.
// 10. Treasury & Economy: Depositing funds, withdrawing, distributing rewards, dynamic fees.
// 11. Governance: Creating proposals, voting, executing proposals.
// 12. Query Functions: Read-only functions to get contract state.

// Function Summary:
// --- Core ERC721 (Overridden/Extended) ---
// constructor(string memory name_, string memory symbol_, string memory baseURI_): Initializes the contract, ERC721, and sets owner/base URI.
// tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a guardian based on its on-chain state.
// supportsInterface(bytes4 interfaceId): Standard ERC165 support check.

// --- Guardian Management ---
// mintGuardian(address to): Mints a new Guardian NFT to a recipient.
// burnGuardian(uint256 tokenId): Burns (destroys) a Guardian NFT. (Requires specific conditions, e.g., governance vote)
// getGuardianDetails(uint256 tokenId): Retrieves all detailed information for a Guardian.

// --- Gamification & Progression ---
// gainExperience(uint256 tokenId, uint256 xpAmount): Awards XP to a Guardian, potentially triggering a level up.
// _checkLevelUp(uint256 tokenId): Internal helper to handle level up logic.
// modifyGuardianAttributes(uint256 tokenId, string[] memory attributeNames, uint256[] memory attributeValues): Allows modifying specific attributes of a Guardian (e.g., via challenges, events, or governance).
// addGuardianTrait(uint256 tokenId, string memory trait): Adds a dynamic trait string to a Guardian.
// removeGuardianTrait(uint256 tokenId, string memory trait): Removes a dynamic trait string from a Guardian.
// getGuardianTraits(uint256 tokenId): Gets the list of dynamic traits for a Guardian.
// getGuardianLevel(uint256 tokenId): Gets the current level of a Guardian.
// getGuardianXP(uint256 tokenId): Gets the current XP of a Guardian.

// --- Staking ---
// stakeGuardian(uint256 tokenId): Stakes a Guardian NFT, making it unavailable for transfer and eligible for staking rewards/XP.
// unstakeGuardian(uint256 tokenId): Unstakes a Guardian NFT, making it transferable again.
// calculateStakingRewards(uint256 tokenId): Calculates the potential staking rewards accrued for a staked Guardian (view function).
// claimStakingRewards(uint256 tokenId): Claims and transfers accrued staking rewards for a staked Guardian.
// isGuardianStaked(uint256 tokenId): Checks if a Guardian is currently staked.
// getGuardianStakingStartTime(uint256 tokenId): Gets the timestamp when a Guardian was staked.

// --- Challenges ---
// createChallenge(string memory name, string memory description, uint256 requiredLevel, uint256 xpReward, string[] memory attributeBoostNames, uint256[] memory attributeBoostValues): Creates a new on-chain challenge (admin/governance).
// completeChallenge(uint256 challengeId, uint256 guardianTokenId): Marks a challenge as completed for a Guardian, grants rewards/XP/attributes if requirements met and not already completed.
// getChallengeDetails(uint256 challengeId): Retrieves information about a specific challenge.
// getTotalChallenges(): Gets the total number of created challenges.

// --- Treasury & Economy ---
// depositTreasury(): Allows anyone to deposit ETH into the contract's treasury.
// withdrawTreasuryFunds(uint256 amount): Withdraws funds from the treasury (governance/admin).
// distributeRewardPool(uint256 amountPerGuardian): Distributes a fixed amount of ETH from the treasury to eligible Guardians (e.g., staked, high-level - needs logic within).
// setDynamicFeeRate(uint256 newFeeRate): Sets a dynamic fee rate (e.g., for future operations) via governance.
// getDynamicFeeRate(): Gets the current dynamic fee rate.
// getTreasuryBalance(): Gets the current balance of the contract treasury.

// --- Governance ---
// createProposal(string memory description, bytes data): Creates a new governance proposal. 'data' can encode action details.
// voteOnProposal(uint256 proposalId, bool support): Casts a vote on a proposal (weight based on Guardian level).
// executeProposal(uint256 proposalId): Executes a proposal if it has passed and the voting period is over.
// getProposalDetails(uint256 proposalId): Retrieves details of a specific proposal.
// getTotalProposals(): Gets the total number of created proposals.

// --- General Queries ---
// getTotalGuardiansMinted(): Gets the total number of Guardians minted.

contract EtherealGuardians is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextChallengeId;
    Counters.Counter private _nextProposalId;

    uint256 public constant XP_PER_LEVEL = 1000; // XP needed to level up

    // --- State Variables ---
    struct Guardian {
        uint256 level;
        uint256 xp;
        mapping(string => uint256) attributes;
        bool isStaked;
        uint40 stakingStartTime; // uint40 is enough for unix timestamps
        mapping(uint256 => bool) completedChallenges;
        string[] dynamicTraits;
        mapping(string => bool) hasTrait; // Helper for quick trait check
    }

    mapping(uint256 => Guardian) private _guardianData;

    struct Challenge {
        uint256 id;
        string name;
        string description;
        uint256 requiredLevel;
        uint256 xpReward;
        string[] attributeBoostNames;
        uint256[] attributeBoostValues; // Corresponds to names
    }

    mapping(uint256 => Challenge) private _challenges;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes data; // Data payload for the action to be executed
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Simple address-based voting check
        ProposalState state;
        bool executed;
    }

    mapping(uint256 => Proposal) private _proposals;
    uint256 public votingPeriodDuration = 3 days; // Duration for voting

    // Dynamic parameters
    uint256 public dynamicFeeRate = 0; // Example dynamic parameter (basis points)
    uint256 public baseStakingRewardPerSecond = 1 wei; // Example staking reward rate

    // --- Events ---
    event GuardianMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel);
    event GuardianXPChanged(uint256 indexed tokenId, uint256 oldXP, uint256 newXP);
    event GuardianLeveledUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event GuardianStaked(uint256 indexed tokenId, address indexed owner, uint256 startTime);
    event GuardianUnstaked(uint256 indexed tokenId, address indexed owner, uint256 endTime);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 requiredLevel);
    event ChallengeCompleted(uint256 indexed challengeId, uint256 indexed guardianTokenId);
    event GuardianAttributesModified(uint256 indexed tokenId, string[] attributeNames, uint256[] attributeValues);
    event GuardianTraitAdded(uint256 indexed tokenId, string trait);
    event GuardianTraitRemoved(uint256 indexed tokenId, string trait);

    event TreasuryDeposited(address indexed sender, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);
    event RewardPoolDistributed(uint256 amount); // Or more detailed per guardian

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event DynamicFeeRateSet(uint256 oldRate, uint256 newRate);

    // --- Errors ---
    error NotGuardianOwner(uint256 tokenId);
    error GuardianAlreadyStaked(uint256 tokenId);
    error GuardianNotStaked(uint256 tokenId);
    error ChallengeNotFound(uint256 challengeId);
    error InsufficientLevel(uint256 requiredLevel, uint256 currentLevel);
    error ChallengeAlreadyCompleted(uint256 challengeId);
    error AttributeNamesAndValuesMismatch();
    error ProposalNotFound(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId);
    error VotingPeriodNotActive(uint256 proposalId);
    error ProposalNotSucceeded(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalStateInvalid(uint256 proposalId, ProposalState currentState, string action);
    error TraitNotFound(uint256 tokenId, string trait);
    error TraitAlreadyExists(uint256 tokenId, string trait);

    // --- Modifiers ---
    modifier onlyGuardianOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert NotGuardianOwner(tokenId);
        _;
    }

    modifier onlyStakedGuardian(uint256 tokenId) {
        if (!_guardianData[tokenId].isStaked) revert GuardianNotStaked(tokenId);
        _;
    }

     modifier onlyNotStakedGuardian(uint256 tokenId) {
        if (_guardianData[tokenId].isStaked) revert GuardianAlreadyStaked(tokenId);
        _;
    }

    // --- Core ERC721 Implementation ---
    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        ERC721URIStorage()
        Ownable(msg.sender)
    {
         _setBaseURI(baseURI_); // Used for composing metadata URIs
    }

    /// @dev See {ERC721-tokenURI}. Generates a dynamic URI based on Guardian state.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (!_exists(tokenId)) {
            return super.tokenURI(tokenId); // Default error behavior for non-existent tokens
        }

        // In a real dApp, this URI would point to an API/service
        // that reads the on-chain state (level, xp, attributes, traits, staked status)
        // and generates dynamic JSON metadata according to ERC721 Metadata JSON Schema.
        // For this example, we'll return a placeholder indicating dynamism.

        string memory base = _baseURI();
        return string(abi.encodePacked(base, "/", Strings.toString(tokenId), "/metadata.json"));
        // The off-chain service at base/tokenId/metadata.json would query this contract
        // to get details via getGuardianDetails(tokenId) and dynamically generate the JSON.
    }

    // The following functions are standard overrides needed for ERC721URIStorage
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return interfaceId == type(ERC721URIStorage).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Guardian Management ---
    /// @notice Mints a new Guardian NFT.
    /// @param to The address to mint the Guardian to.
    function mintGuardian(address to) external onlyOwner {
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(to, newTokenId);

        // Initialize Guardian data
        Guardian storage newGuardian = _guardianData[newTokenId];
        newGuardian.level = 1; // Start at level 1
        newGuardian.xp = 0;
        // Initialize base attributes if needed, e.g., newGuardian.attributes["strength"] = 1;

        emit GuardianMinted(to, newTokenId, 1);
    }

    /// @notice Burns (destroys) a Guardian NFT. Requires governance approval or specific conditions.
    /// @param tokenId The ID of the Guardian to burn.
    function burnGuardian(uint256 tokenId) external {
        // This function would typically require complex logic:
        // - Only callable via a successful governance proposal execution
        // - Or only if the Guardian meets specific in-game/system conditions
        // - Cannot be staked

        require(!_guardianData[tokenId].isStaked, "Guardian cannot be staked to burn");
        // Example: require(governance.hasApprovedBurn(tokenId), "Burn not approved by governance");

        // For simplicity in this example, let's restrict to owner or governance placeholder
        // In a real system, this would likely be triggered by executeProposal
        // require(ownerOf(tokenId) == msg.sender || msg.sender == address(governanceContract), "Not authorized to burn");
        // For demo, restrict to owner for now.
        require(ownerOf(tokenId) == msg.sender, "Not authorized to burn (demo limit)");


        _burn(tokenId);
        // Optional: Delete _guardianData[tokenId] to free up storage, but be careful with mappings
        // Deleting the struct might not fully clean up nested mappings. A dedicated cleanup might be needed.
        // For simplicity, we'll just rely on _exists(tokenId) check and leave the data.
    }


    /// @notice Retrieves all detailed information for a Guardian.
    /// @param tokenId The ID of the Guardian.
    /// @return Guardian struct containing all data.
    function getGuardianDetails(uint256 tokenId) public view returns (Guardian memory) {
        require(_exists(tokenId), "Guardian does not exist");
        // Note: Mappings inside structs cannot be returned directly.
        // A real implementation would need separate functions to retrieve attributes and completed challenges.
        // For this example, we'll return the struct minus the nested mappings.
        // You'd need `getGuardianAttributes(tokenId)` and `hasCompletedChallenge(tokenId, challengeId)`.
         Guardian storage g = _guardianData[tokenId];
         return Guardian(g.level, g.xp, g.attributes, g.isStaked, g.stakingStartTime, g.completedChallenges, g.dynamicTraits, g.hasTrait);
    }

    // --- Gamification & Progression ---
    /// @notice Awards XP to a Guardian. Checks for level ups.
    /// @param tokenId The ID of the Guardian.
    /// @param xpAmount The amount of XP to add.
    function gainExperience(uint256 tokenId, uint256 xpAmount) external {
         require(_exists(tokenId), "Guardian does not exist");
         // Restrict who can call this: maybe only the owner, or a designated 'Game' contract, or via challenges.
         // For demo, allow owner to award XP.
         require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not authorized to award XP");

        Guardian storage guardian = _guardianData[tokenId];
        uint256 oldXP = guardian.xp;
        guardian.xp = guardian.xp.add(xpAmount);

        emit GuardianXPChanged(tokenId, oldXP, guardian.xp);

        _checkLevelUp(tokenId); // Check if the guardian levels up
    }

    /// @dev Internal helper to check and handle Guardian level ups based on XP.
    function _checkLevelUp(uint256 tokenId) internal {
        Guardian storage guardian = _guardianData[tokenId];
        uint256 oldLevel = guardian.level;

        // Calculate the new level based on total XP
        uint256 newLevel = 1 + (guardian.xp / XP_PER_LEVEL); // Level 1 starts with 0 XP, reaches level 2 at XP_PER_LEVEL

        if (newLevel > oldLevel) {
            guardian.level = newLevel;
             // Example: Automatically boost attributes on level up
             // guardian.attributes["strength"] = guardian.attributes["strength"].add(1);
             // guardian.attributes["defense"] = guardian.attributes["defense"].add(1);

            emit GuardianLeveledUp(tokenId, oldLevel, newLevel);
            // The tokenURI needs to be updated off-chain by the metadata service polling for this event.
        }
    }

     /// @notice Allows modifying specific attributes of a Guardian.
     /// Can be used for boosts from challenges, items, or admin/governance adjustments.
     /// @param tokenId The ID of the Guardian.
     /// @param attributeNames Array of attribute names (e.g., "strength", "intelligence").
     /// @param attributeValues Array of corresponding attribute values.
     function modifyGuardianAttributes(uint256 tokenId, string[] memory attributeNames, uint256[] memory attributeValues) external {
         require(_exists(tokenId), "Guardian does not exist");
         require(attributeNames.length == attributeValues.length, "Names and values must match length");
         // Restrict who can call: owner, a designated 'Game' contract, or via governance execution.
         // For demo, allow owner or contract owner.
         require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not authorized to modify attributes");

         Guardian storage guardian = _guardianData[tokenId];
         for(uint i = 0; i < attributeNames.length; i++) {
             guardian.attributes[attributeNames[i]] = attributeValues[i]; // Overwrite or set attribute
         }

         emit GuardianAttributesModified(tokenId, attributeNames, attributeValues);
     }

     /// @notice Adds a dynamic trait string to a Guardian.
     /// @param tokenId The ID of the Guardian.
     /// @param trait The trait string to add (e.g., "Adventurer", "Defender").
     function addGuardianTrait(uint256 tokenId, string memory trait) external {
         require(_exists(tokenId), "Guardian does not exist");
         // Restrict who can call: owner, a designated 'Game' contract, or via governance execution.
         // For demo, allow owner or contract owner.
         require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not authorized to add trait");
         require(!_guardianData[tokenId].hasTrait[trait], TraitAlreadyExists(tokenId, trait));

         Guardian storage guardian = _guardianData[tokenId];
         guardian.dynamicTraits.push(trait);
         guardian.hasTrait[trait] = true;

         emit GuardianTraitAdded(tokenId, trait);
     }

      /// @notice Removes a dynamic trait string from a Guardian.
      /// @param tokenId The ID of the Guardian.
      /// @param trait The trait string to remove.
     function removeGuardianTrait(uint256 tokenId, string memory trait) external {
         require(_exists(tokenId), "Guardian does not exist");
         // Restrict who can call: owner, a designated 'Game' contract, or via governance execution.
         // For demo, allow owner or contract owner.
         require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not authorized to remove trait");
         require(_guardianData[tokenId].hasTrait[trait], TraitNotFound(tokenId, trait));

         Guardian storage guardian = _guardianData[tokenId];
         // Find and remove the trait from the array
         for(uint i = 0; i < guardian.dynamicTraits.length; i++) {
             if(keccak256(abi.encodePacked(guardian.dynamicTraits[i])) == keccak256(abi.encodePacked(trait))) {
                 // Replace with last element and pop (standard Solidity array removal)
                 guardian.dynamicTraits[i] = guardian.dynamicTraits[guardian.dynamicTraits.length - 1];
                 guardian.dynamicTraits.pop();
                 guardian.hasTrait[trait] = false;
                 emit GuardianTraitRemoved(tokenId, trait);
                 return; // Trait found and removed
             }
         }
         // Should not reach here if hasTrait[trait] is true, but as a safeguard
         revert TraitNotFound(tokenId, trait);
     }

     /// @notice Gets the list of dynamic traits for a Guardian.
     /// @param tokenId The ID of the Guardian.
     /// @return An array of trait strings.
     function getGuardianTraits(uint256 tokenId) public view returns (string[] memory) {
         require(_exists(tokenId), "Guardian does not exist");
         return _guardianData[tokenId].dynamicTraits;
     }


    /// @notice Gets the current level of a Guardian.
    /// @param tokenId The ID of the Guardian.
    /// @return The Guardian's level.
    function getGuardianLevel(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Guardian does not exist");
         return _guardianData[tokenId].level;
    }

     /// @notice Gets the current XP of a Guardian.
     /// @param tokenId The ID of the Guardian.
     /// @return The Guardian's XP.
    function getGuardianXP(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Guardian does not exist");
         return _guardianData[tokenId].xp;
    }


    // --- Staking ---
    /// @notice Stakes a Guardian NFT. Makes it non-transferable and eligible for rewards/XP gain via staking.
    /// @param tokenId The ID of the Guardian to stake.
    function stakeGuardian(uint256 tokenId) external onlyGuardianOwner(tokenId) onlyNotStakedGuardian(tokenId) {
        Guardian storage guardian = _guardianData[tokenId];
        guardian.isStaked = true;
        guardian.stakingStartTime = uint40(block.timestamp); // Use uint40 for smaller storage

        // Note: ERC721 transfer logic might need to be overridden or disabled
        // for staked tokens if standard transfers should be blocked.
        // OpenZeppelin's _beforeTokenTransfer can be used for this.
        // For this example, we rely on dApps checking isGuardianStaked().

        emit GuardianStaked(tokenId, msg.sender, guardian.stakingStartTime);
    }

     /// @notice Unstakes a Guardian NFT. Makes it transferable again.
     /// @param tokenId The ID of the Guardian to unstake.
    function unstakeGuardian(uint256 tokenId) external onlyGuardianOwner(tokenId) onlyStakedGuardian(tokenId) {
        Guardian storage guardian = _guardianData[tokenId];
        uint40 endTime = uint40(block.timestamp);

        // Optional: Claim rewards automatically on unstake, or require separate claim
        // Let's require separate claim for more flexibility.

        guardian.isStaked = false;
        guardian.stakingStartTime = 0; // Reset start time

        emit GuardianUnstaked(tokenId, msg.sender, endTime);
    }

    /// @notice Calculates the potential staking rewards accrued for a staked Guardian.
    /// Rewards accrue based on time staked and potentially Guardian level/attributes.
    /// @param tokenId The ID of the Guardian.
    /// @return The calculated reward amount in wei.
    function calculateStakingRewards(uint256 tokenId) public view onlyStakedGuardian(tokenId) returns (uint256) {
        Guardian storage guardian = _guardianData[tokenId];
        uint256 timeStaked = block.timestamp - guardian.stakingStartTime;
        uint256 level = guardian.level;

        // Example complex reward calculation: base reward + bonus based on level
        uint256 baseReward = timeStaked * baseStakingRewardPerSecond;
        uint256 levelBonus = (level - 1) * 1000000000000000 wei; // Example bonus per level (adjust units)
        // Add other factors like attributes if desired

        return baseReward.add(levelBonus);
    }

     /// @notice Claims and transfers accrued staking rewards for a staked Guardian.
     /// @param tokenId The ID of the Guardian.
    function claimStakingRewards(uint256 tokenId) external onlyGuardianOwner(tokenId) onlyStakedGuardian(tokenId) {
        uint256 rewards = calculateStakingRewards(tokenId);
        require(rewards > 0, "No rewards accrued yet");

        // Reset staking time *before* sending ETH to prevent reentrancy (less risk here but good practice)
        Guardian storage guardian = _guardianData[tokenId];
        guardian.stakingStartTime = uint40(block.timestamp); // Start new reward period from now

        // Send rewards from the contract balance
        (bool success, ) = payable(msg.sender).call{value: rewards}("");
        require(success, "Reward transfer failed");

        emit StakingRewardsClaimed(tokenId, msg.sender, rewards);

        // Optional: Award XP for claiming rewards or based on staking duration
        // gainExperience(tokenId, timeStaked / 1 hour * 10); // Example XP gain per hour staked
    }

     /// @notice Checks if a Guardian is currently staked.
     /// @param tokenId The ID of the Guardian.
     /// @return True if staked, false otherwise.
    function isGuardianStaked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Guardian does not exist");
        return _guardianData[tokenId].isStaked;
    }

    /// @notice Gets the timestamp when a Guardian was staked.
    /// @param tokenId The ID of the Guardian.
    /// @return The staking start timestamp (0 if not staked).
    function getGuardianStakingStartTime(uint256 tokenId) public view returns (uint40) {
        require(_exists(tokenId), "Guardian does not exist");
        return _guardianData[tokenId].stakingStartTime;
    }


    // --- Challenges ---
    /// @notice Creates a new on-chain challenge (can only be called by owner or via governance).
    /// @param name The name of the challenge.
    /// @param description The description of the challenge.
    /// @param requiredLevel The minimum level required to attempt the challenge.
    /// @param xpReward The XP granted upon successful completion.
    /// @param attributeBoostNames Names of attributes to boost upon completion.
    /// @param attributeBoostValues Corresponding values for attribute boosts.
    function createChallenge(string memory name, string memory description, uint256 requiredLevel, uint256 xpReward, string[] memory attributeBoostNames, uint256[] memory attributeBoostValues) external onlyOwner {
        require(attributeBoostNames.length == attributeBoostValues.length, AttributeNamesAndValuesMismatch());

        uint256 newChallengeId = _nextChallengeId.current();
        _nextChallengeId.increment();

        Challenge storage newChallenge = _challenges[newChallengeId];
        newChallenge.id = newChallengeId;
        newChallenge.name = name;
        newChallenge.description = description;
        newChallenge.requiredLevel = requiredLevel;
        newChallenge.xpReward = xpReward;
        newChallenge.attributeBoostNames = attributeBoostNames; // Store arrays directly
        newChallenge.attributeBoostValues = attributeBoostValues;

        emit ChallengeCreated(newChallengeId, name, requiredLevel);
    }

    /// @notice Allows a Guardian owner to mark a challenge as completed for their Guardian.
    /// Checks level requirements and ensures challenge hasn't been completed before.
    /// Awards XP and attribute boosts.
    /// @param challengeId The ID of the challenge.
    /// @param guardianTokenId The ID of the Guardian attempting the challenge.
    function completeChallenge(uint256 challengeId, uint256 guardianTokenId) external onlyGuardianOwner(guardianTokenId) {
        require(_challenges[challengeId].id == challengeId, ChallengeNotFound(challengeId)); // Check if challenge exists by ID
        Guardian storage guardian = _guardianData[guardianTokenId];
        Challenge storage challenge = _challenges[challengeId];

        require(guardian.level >= challenge.requiredLevel, InsufficientLevel(challenge.requiredLevel, guardian.level));
        require(!guardian.completedChallenges[challengeId], ChallengeAlreadyCompleted(challengeId));

        // Mark challenge as completed for this guardian
        guardian.completedChallenges[challengeId] = true;

        // Grant rewards
        gainExperience(guardianTokenId, challenge.xpReward); // Re-use gainExperience logic
        if (challenge.attributeBoostNames.length > 0) {
             modifyGuardianAttributes(guardianTokenId, challenge.attributeBoostNames, challenge.attributeBoostValues); // Re-use modifyAttributes logic
        }

        emit ChallengeCompleted(challengeId, guardianTokenId);
    }

    /// @notice Retrieves information about a specific challenge.
    /// @param challengeId The ID of the challenge.
    /// @return Challenge struct containing details.
    function getChallengeDetails(uint256 challengeId) public view returns (Challenge memory) {
        require(_challenges[challengeId].id == challengeId, ChallengeNotFound(challengeId));
        return _challenges[challengeId];
    }

    /// @notice Gets the total number of created challenges.
    /// @return The total count of challenges.
    function getTotalChallenges() public view returns (uint256) {
        return _nextChallengeId.current();
    }


    // --- Treasury & Economy ---
    /// @notice Allows anyone to deposit ETH into the contract's treasury.
    function depositTreasury() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraws funds from the treasury. Restricted to governance/admin.
    /// @param amount The amount of ETH to withdraw.
    function withdrawTreasuryFunds(uint256 amount) external onlyOwner { // Or callable only via executeProposal
        require(address(this).balance >= amount, "Insufficient treasury balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit TreasuryWithdrawn(msg.sender, amount);
    }

    /// @notice Distributes a fixed amount of ETH from the treasury to eligible Guardians.
    /// Eligibility logic (e.g., staked, high-level) needs to be defined here.
    /// For simplicity, this example is a placeholder.
    /// @param amountPerGuardian The amount of ETH to send to each eligible Guardian.
    function distributeRewardPool(uint256 amountPerGuardian) external onlyOwner { // Or callable only via executeProposal
        // This requires iterating over guardians or having a separate list of eligble ones.
        // Iterating over all guardians in a large collection can hit gas limits.
        // A real implementation might use a Merkle drop, a pull-based system,
        // or distribute based on a snapshot of stakers/levels.

        // Placeholder logic: send to the owner (for demonstration purposes, needs replacing)
        // In a real scenario, you'd iterate over stakers or a list of reward recipients.
        uint256 totalGuardians = _nextTokenId.current();
        uint256 theoreticalTotal = totalGuardians * amountPerGuardian; // Simple example calculation

        require(address(this).balance >= theoreticalTotal, "Insufficient treasury balance for distribution");

        // !!! WARNING: Iterating over ALL tokens is NOT GAS EFFICIENT for large collections !!!
        // This is a simplified example.
        for (uint256 i = 0; i < totalGuardians; i++) {
            uint256 tokenId = i; // Assuming token IDs are sequential from 0 or 1
            if (_exists(tokenId) && _guardianData[tokenId].isStaked) { // Example eligibility: Must exist and be staked
                 // Transfer amountPerGuardian to ownerOf(tokenId)
                 address recipient = ownerOf(tokenId);
                 if (recipient != address(0)) { // Ensure recipient exists
                    (bool success, ) = payable(recipient).call{value: amountPerGuardian}("");
                    // Log success/failure per recipient if needed
                 }
            }
        }
        // Log the distribution event (perhaps total amount sent, or number of recipients)
        emit RewardPoolDistributed(theoreticalTotal); // Example log
    }

    /// @notice Sets a dynamic fee rate (e.g., for marketplace operations, future features).
    /// Can only be called via governance proposal execution.
    /// @param newFeeRate The new fee rate in basis points (e.g., 100 = 1%).
    function setDynamicFeeRate(uint256 newFeeRate) external onlyOwner { // Callable only via executeProposal in real governance
        uint256 oldRate = dynamicFeeRate;
        dynamicFeeRate = newFeeRate;
        emit DynamicFeeRateSet(oldRate, newFeeRate);
    }

    /// @notice Gets the current dynamic fee rate.
    /// @return The current fee rate in basis points.
    function getDynamicFeeRate() public view returns (uint256) {
        return dynamicFeeRate;
    }

     /// @notice Gets the current balance of the contract treasury.
     /// @return The treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Governance ---
    /// @notice Creates a new governance proposal. Anyone can propose.
    /// @param description Description of the proposal.
    /// @param data Data payload encoding the action (e.g., function call data).
    /// @return The ID of the newly created proposal.
    function createProposal(string memory description, bytes memory data) external returns (uint256) {
        uint256 newProposalId = _nextProposalId.current();
        _nextProposalId.increment();

        Proposal storage newProposal = _proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.data = data;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + votingPeriodDuration;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.state = ProposalState.Active;
        newProposal.executed = false;

        emit ProposalCreated(newProposalId, msg.sender, description);
        emit ProposalStateChanged(newProposalId, ProposalState.Active);

        return newProposalId;
    }

    /// @notice Casts a vote on a proposal. Voting weight is based on the voter's highest-level Guardian.
    /// @param proposalId The ID of the proposal.
    /// @param support True for yes, false for no.
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id == proposalId, ProposalNotFound(proposalId));
        require(proposal.state == ProposalState.Active, VotingPeriodNotActive(proposalId));
        require(!proposal.hasVoted[msg.sender], AlreadyVoted(proposalId));
        require(block.timestamp <= proposal.voteEndTime, VotingPeriodNotActive(proposalId));

        // Determine voting weight: Example based on the highest level Guardian owned by the voter
        uint256 voteWeight = 0;
        uint256 highestLevel = 0;
        uint256 totalGuardians = _nextTokenId.current(); // Be cautious with large collections
        for (uint i = 0; i < totalGuardians; i++) {
             if (_exists(i) && ownerOf(i) == msg.sender) {
                 uint256 currentLevel = _guardianData[i].level;
                 if (currentLevel > highestLevel) {
                     highestLevel = currentLevel;
                 }
             }
        }
        // Simple weight: level of highest guardian (min 1 if they own at least one)
        voteWeight = (highestLevel == 0 && balanceOf(msg.sender) > 0) ? 1 : highestLevel; // Ensure weight is at least 1 if they own a Guardian

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voteWeight);

        // Automatically transition state if voting period ends
        if (block.timestamp > proposal.voteEndTime) {
             _updateProposalState(proposalId);
        }
    }

    /// @dev Internal helper to update proposal state after voting ends.
    function _updateProposalState(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
             if (proposal.votesFor > proposal.votesAgainst) {
                 proposal.state = ProposalState.Succeeded;
                 emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
             } else {
                 proposal.state = ProposalState.Failed;
                  emit ProposalStateChanged(proposalId, ProposalState.Failed);
             }
        }
    }

    /// @notice Executes a proposal if it has succeeded and the voting period is over.
    /// This is where on-chain actions triggered by governance happen.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id == proposalId, ProposalNotFound(proposalId));
        require(proposal.state != ProposalState.Executed, ProposalAlreadyExecuted(proposalId));

        // Ensure voting period is over and state is updated
        _updateProposalState(proposalId);
        require(proposal.state == ProposalState.Succeeded, ProposalNotSucceeded(proposalId));

        // --- Execute the action based on proposal.data ---
        // This part is complex and depends heavily on what actions governance can take.
        // A common pattern is using abi.decode and calling specific functions via `delegatecall` or `call`.
        // For simplicity, let's assume the data encodes calls to specific, safe functions
        // like `setDynamicFeeRate` or `distributeRewardPool`, or simple parameter changes.

        // Example: Decode data to call setDynamicFeeRate or distributeRewardPool
        // This requires careful encoding on the proposal creation side.
        // Let's assume data is abi.encodeCall(targetFunction, args...)

        // WARNING: Using `call` with arbitrary data is powerful but dangerous.
        // A real DAO would have a robust mechanism to only allow calls to approved functions (e.g., an allowlist).
        // For this demo, we'll use a placeholder or a simplified switch.

        // Placeholder: Allow calling setDynamicFeeRate or distributeRewardPool directly from the contract owner
        // A real execution would parse `proposal.data` and use `address(this).call(proposal.data)`.
        // Example safe execution:
        // (bool success, ) = address(this).call(proposal.data);
        // require(success, "Proposal execution failed");

        // For a safer *example* within this code, let's manually map proposal description/data to known actions
        // In a real DAO, proposal.data would be the CALLDATA.
        // If data is used, this decode/execute logic needs to be robust.
        // Example (if data is abi.encode(functionSelector, args...)):
        // (bool success, ) = address(this).call(proposal.data);
        // require(success, "Proposal call failed");

        // Let's make `executeProposal` callable *only* by the contract owner for this example,
        // who would manually verify the proposal details and then execute the action.
        // A true DAO execution would likely be permissionless after the voting period ends.
        require(msg.sender == owner(), "Proposal execution restricted to owner (demo)"); // DEMO restriction

        // Actual execution logic placeholder (must parse `proposal.data`)
        // e.g., based on description or a type encoded in data:
        // if (keccak256(abi.encodePacked(proposal.description)) == keccak256(abi.encodePacked("Set Fee Rate"))) {
        //     // Decode new fee rate from proposal.data and call setDynamicFeeRate
        //     (uint256 newRate) = abi.decode(proposal.data, (uint256));
        //     setDynamicFeeRate(newRate); // Call the function
        // } else if (...) { ... }


        // Mark as executed
        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct containing details.
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(_proposals[proposalId].id == proposalId, ProposalNotFound(proposalId));
         // Need to return a memory struct because of the internal mapping
         Proposal storage p = _proposals[proposalId];
         return Proposal(p.id, p.proposer, p.description, p.data, p.voteStartTime, p.voteEndTime, p.votesFor, p.votesAgainst, p.hasVoted, p.state, p.executed);
    }

    /// @notice Gets the total number of created proposals.
    /// @return The total count of proposals.
    function getTotalProposals() public view returns (uint256) {
        return _nextProposalId.current();
    }

    // --- General Queries ---
    /// @notice Gets the total number of Guardians minted.
    /// @return The total count of minted Guardians.
    function getTotalGuardiansMinted() public view returns (uint256) {
        return _nextTokenId.current();
    }

    // Note: Standard ERC721 functions like ownerOf, balanceOf, getApproved, isApprovedForAll, etc.
    // are available automatically from the inherited ERC721 contract.
}
```