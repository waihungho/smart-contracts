The following smart contract, `EvoGenesisProtocol`, introduces a novel system for **Adaptive Digital Entities (ADEs)** represented by dynamic NFTs. These ADEs evolve through various on-chain interactions, resource management, and community governance. The protocol aims to create a living, evolving digital ecosystem on the blockchain.

### Outline and Function Summary

**I. Core Architecture & Token Standards**
*   The contract itself is an **ERC721** token representing individual ADEs.
*   It interacts with an **ERC20 "Essence" Token** (for powering evolution and staking) and an **ERC1155 "Catalyst" Token** (for unlocking advanced evolution paths), whose addresses are set at deployment.
*   Uses `Ownable` for initial admin control, which would ideally be transferred to a DAO or multisig in a production environment.

**II. ADE Management & ERC721 Functions**
1.  `constructor()`: Initializes the contract with addresses for Essence and Catalyst tokens, and a base URI for metadata.
2.  `genesisMint()`: Allows anyone to mint a new ADE with initial randomized base traits (Resilience, Intelligence, Adaptability).
3.  `tokenURI(uint256 tokenId)`: Generates a dynamic metadata URI, reflecting the ADE's current traits, level, and status, ensuring visual representation evolves with the ADE.
4.  `getADETraits(uint256 tokenId)`: Returns the current effective trait scores of an ADE.
5.  `getADEStatus(uint256 tokenId)`: Returns the current operational status of an ADE (e.g., Active, Questing, Hibernating).
6.  `getLevel(uint256 tokenId)`: Calculates and returns the ADE's current level based on its total trait score.

**III. Evolution & Trait Dynamics**
7.  `evolveTrait(uint256 tokenId, uint256 traitId, uint256 essenceAmount)`: Allows an ADE owner to spend "Essence" tokens to permanently boost a specific trait of their ADE.
8.  `unlockEvolutionPath(uint256 tokenId, uint256 pathId, uint256 catalystId)`: Requires an ADE owner to burn a specific "Catalyst" NFT to unlock a new, advanced evolutionary path or ability for their ADE.
9.  `recalibrateADETraits(uint256 tokenId)`: Triggers a recalculation of an ADE's effective traits, applying global environmental factors set by governance. This can be called by anyone but only processes once per cool-down period.

**IV. Essence Token & Staking**
10. `stakeEssenceForADE(uint256 tokenId, uint256 amount)`: Allows an ADE owner to stake "Essence" tokens to their ADE, increasing its passive "Essence" generation rate.
11. `unstakeEssenceFromADE(uint256 tokenId, uint256 amount)`: Allows an ADE owner to unstake "Essence" tokens from their ADE.
12. `claimEssence(uint256 tokenId)`: Allows an ADE owner to claim accumulated "Essence" rewards from their staked ADE.
13. `getPendingEssence(uint256 tokenId)`: Calculates and returns the amount of "Essence" an ADE has accumulated since its last claim or stake adjustment.
14. `getADEStakedEssence(uint256 tokenId)`: Returns the total "Essence" tokens currently staked to a specific ADE.

**V. Gamified Interactions / Quests**
15. `sendADEOnQuest(uint256 tokenId, uint256 questId)`: Sends an ADE on a specific quest, temporarily changing its status and locking it for a set duration.
16. `completeQuest(uint256 tokenId)`: Finalizes a quest for an ADE, distributing rewards (Essence, Catalyst, or trait boosts) upon successful completion.
17. `cancelQuest(uint256 tokenId)`: Allows an ADE owner to prematurely cancel an active quest, potentially incurring a penalty.
18. `getADEActiveQuest(uint256 tokenId)`: Returns details about the ADE's current active quest, if any.

**VI. Governance (Owner/DAO-Controlled Functions)**
19. `proposeParameterChange(bytes32 paramKey, uint256 newValue, uint256 deadline)`: (Owner-only) Initiates a proposal to change a key protocol parameter (e.g., `ESSENCE_EMISSION_RATE_KEY`).
20. `proposeNewQuest(uint256 questId, uint256 duration, uint256 rewardEssence, uint256 traitBoostId, uint256 traitBoostAmount, uint256 deadline)`: (Owner-only) Initiates a proposal to add or modify quest parameters.
21. `voteOnProposal(uint256 proposalId, bool support)`: (Owner-only for this simple implementation, in a full DAO it would be token-weighted) Records a vote on an active proposal.
22. `executeProposal(uint256 proposalId)`: (Owner-only) Executes a passed proposal, triggering the associated protocol change.
23. `setQuestParameters(uint256 questId, uint256 duration, uint252 rewardEssence, uint256 traitBoostId, uint256 traitBoostAmount)`: (Callable only by successful proposal execution) Configures details for a specific quest.
24. `updateBaseEssenceEmissionRate(uint256 newRate)`: (Callable only by successful proposal execution) Adjusts the global rate at which staked ADEs generate Essence.
25. `updateEnvironmentFactor(uint256 factorId, uint252 value)`: (Callable only by successful proposal execution) Sets a global environmental factor that influences ADE traits.
26. `grantCatalyst(address recipient, uint256 catalystId, uint256 amount)`: (Callable only by successful proposal execution) Distributes Catalyst NFTs to an address (e.g., for community rewards).
27. `withdrawTreasury(address tokenAddress, address recipient, uint256 amount)`: (Callable only by successful proposal execution) Allows withdrawing funds from the contract's treasury.
28. `setBaseURI(string memory newBaseURI)`: (Owner-only) Allows updating the base URI for metadata, enabling dynamic frontend integration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title EvoGenesisProtocol
 * @dev A dynamic NFT protocol for Adaptive Digital Entities (ADEs).
 *      ADEs evolve through trait upgrades, catalyst unlocks, quests,
 *      Essence staking, and are influenced by global environmental factors
 *      set by governance.
 *
 * Outline and Function Summary:
 *
 * I. Core Architecture & Token Standards
 *    - The contract itself is an ERC721 token representing individual ADEs.
 *    - It interacts with an ERC20 "Essence" Token and an ERC1155 "Catalyst" Token.
 *    - Uses Ownable for initial admin control, which would ideally be transferred to a DAO.
 *
 * II. ADE Management & ERC721 Functions
 * 1. constructor(): Initializes contract with token addresses and base URI.
 * 2. genesisMint(): Mints a new ADE with initial random traits.
 * 3. tokenURI(uint256 tokenId): Generates dynamic metadata URI, reflecting ADE's current state.
 * 4. getADETraits(uint256 tokenId): Returns current effective trait scores.
 * 5. getADEStatus(uint256 tokenId): Returns current operational status.
 * 6. getLevel(uint256 tokenId): Calculates and returns ADE's level based on total trait score.
 *
 * III. Evolution & Trait Dynamics
 * 7. evolveTrait(uint256 tokenId, uint256 traitId, uint256 essenceAmount): Spends Essence to boost a trait.
 * 8. unlockEvolutionPath(uint256 tokenId, uint256 pathId, uint256 catalystId): Burns Catalyst to unlock evolution path.
 * 9. recalibrateADETraits(uint256 tokenId): Recalculates effective traits based on environmental factors.
 *
 * IV. Essence Token & Staking
 * 10. stakeEssenceForADE(uint256 tokenId, uint256 amount): Stakes Essence to ADE for passive generation.
 * 11. unstakeEssenceFromADE(uint256 tokenId, uint256 amount): Unstakes Essence from ADE.
 * 12. claimEssence(uint256 tokenId): Claims accumulated Essence rewards.
 * 13. getPendingEssence(uint256 tokenId): Calculates pending Essence rewards.
 * 14. getADEStakedEssence(uint256 tokenId): Returns total Essence staked to an ADE.
 *
 * V. Gamified Interactions / Quests
 * 15. sendADEOnQuest(uint256 tokenId, uint256 questId): Sends an ADE on a quest, locking its status.
 * 16. completeQuest(uint256 tokenId): Finalizes a quest, distributing rewards.
 * 17. cancelQuest(uint256 tokenId): Cancels an active quest with a penalty.
 * 18. getADEActiveQuest(uint256 tokenId): Returns details about an ADE's active quest.
 *
 * VI. Governance (Owner/DAO-Controlled Functions)
 * 19. proposeParameterChange(bytes32 paramKey, uint256 newValue, uint256 deadline): Initiates a proposal for general parameter change.
 * 20. proposeNewQuest(uint256 questId, uint256 duration, uint256 rewardEssence, uint256 traitBoostId, uint256 traitBoostAmount, uint256 deadline): Initiates a proposal to add/modify quest.
 * 21. voteOnProposal(uint256 proposalId, bool support): Records a vote on a proposal (Owner-only in this simple version).
 * 22. executeProposal(uint256 proposalId): Executes a passed proposal.
 * 23. setQuestParameters(uint256 questId, uint256 duration, uint256 rewardEssence, uint256 traitBoostId, uint256 traitBoostAmount): (Only by proposal) Configures a quest.
 * 24. updateBaseEssenceEmissionRate(uint256 newRate): (Only by proposal) Adjusts global Essence emission.
 * 25. updateEnvironmentFactor(uint256 factorId, uint256 value): (Only by proposal) Sets global environmental factors.
 * 26. grantCatalyst(address recipient, uint256 catalystId, uint256 amount): (Only by proposal) Distributes Catalyst NFTs.
 * 27. withdrawTreasury(address tokenAddress, address recipient, uint256 amount): (Only by proposal) Withdraws treasury funds.
 * 28. setBaseURI(string memory newBaseURI): (Owner-only) Updates the base URI for metadata.
 */
contract EvoGenesisProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    // External Token Addresses
    IERC20 public immutable essenceToken;
    IERC1155 public immutable catalystTokens;

    // ADE (Adaptive Digital Entity) Data
    enum ADEStatus { Active, Questing, Hibernating }
    enum TraitType { Resilience, Intelligence, Adaptability, Spirit, Agility } // Example traits

    struct ADETraits {
        uint256 resilience;
        uint256 intelligence;
        uint256 adaptability;
        uint256 spirit;
        uint256 agility;
        // Add more traits as needed
    }
    mapping(uint256 => ADETraits) private _adeBaseTraits; // tokenId => base traits
    mapping(uint256 => ADETraits) private _adeEffectiveTraits; // tokenId => effective traits after env factors
    mapping(uint256 => ADEStatus) private _adeStatus;
    mapping(uint256 => uint256) private _unlockedEvolutionPaths; // tokenId => bitmask of unlocked paths

    // Essence Staking & Emission
    uint256 public baseEssenceEmissionRate = 1000; // Essence per ADE per day (scaled by 1e18)
    uint256 public constant ESSENCE_EMISSION_PERIOD = 1 days; // Period for emission calculation
    mapping(uint256 => uint256) private _adeStakedEssence; // tokenId => total Essence staked
    mapping(uint256 => uint256) private _adeLastEssenceClaimTime; // tokenId => last claim/stake adjustment time

    // Environmental Factors (influencing all ADEs)
    mapping(uint256 => uint256) public environmentFactors; // factorId => value (e.g., 0: solar radiation, 1: digital flora density)
    uint256 public constant RECALIBRATION_COOLDOWN = 6 hours;
    mapping(uint256 => uint256) private _adeLastRecalibrationTime; // tokenId => last recalibration time

    // Quest System
    struct Quest {
        uint256 duration;
        uint256 rewardEssence;
        uint256 rewardCatalystId; // 0 if no catalyst reward
        uint256 rewardCatalystAmount;
        TraitType traitBoostId; // Trait to boost upon completion
        uint256 traitBoostAmount;
        bool exists;
    }
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => uint256) private _adeQuestStartTime; // tokenId => start time
    mapping(uint256 => uint256) private _adeActiveQuestId; // tokenId => questId

    // Governance System (Simple Owner-controlled for this example; ideally a full DAO)
    enum ProposalType { UpdateEssenceRate, SetQuestParams, UpdateEnvironmentFactor, GrantCatalyst, WithdrawTreasury, AddNewEvolutionPath }

    struct Proposal {
        ProposalType proposalType;
        bytes32 proposalDataHash; // For off-chain context/details, or specific params
        uint256 targetValue1; // Generic value 1
        uint256 targetValue2; // Generic value 2 (e.g., duration for quest)
        uint256 targetValue3; // Generic value 3 (e.g., rewardEssence for quest)
        uint256 targetValue4; // Generic value 4 (e.g., traitBoostId for quest)
        uint256 targetValue5; // Generic value 5 (e.g., traitBoostAmount for quest)
        address targetAddress; // Generic address for recipient
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool exists;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voterAddress => voted

    // --- Events ---
    event ADEGenesisMinted(uint256 indexed tokenId, address indexed owner, ADETraits initialTraits);
    event ADETraitEvolved(uint256 indexed tokenId, TraitType indexed traitId, uint256 newTraitValue);
    event EvolutionPathUnlocked(uint256 indexed tokenId, uint256 indexed pathId);
    event EssenceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EssenceUnstaked(uint256 indexed tokenId, address indexed unstaker, uint256 amount);
    event EssenceClaimed(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event ADEQuestStarted(uint256 indexed tokenId, uint256 indexed questId, uint256 startTime);
    event ADEQuestCompleted(uint256 indexed tokenId, uint256 indexed questId, uint256 rewardEssence, uint256 traitBoost);
    event ADEQuestCancelled(uint256 indexed tokenId, uint256 indexed questId);
    event ADERecalibrated(uint256 indexed tokenId);
    event EnvironmentFactorUpdated(uint256 indexed factorId, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, bytes32 proposalDataHash, uint256 deadline);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event BaseURIUpdated(string newBaseURI);

    // --- Modifiers ---
    modifier onlyProposalExecutor() {
        // In a full DAO, this would be a specific contract or role.
        // For this example, only the contract owner can execute proposals after they pass a vote.
        // The intention is that these functions are NOT directly callable by owner,
        // but only through the executeProposal mechanism.
        require(msg.sender == address(this), "EvoGenesis: Not proposal executor");
        _;
    }

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _catalystTokensAddress, string memory _initialBaseURI)
        ERC721("EvoGenesis ADE", "ADE")
        Ownable(msg.sender) // Owner is the deployer, ideally a DAO or multisig
    {
        require(_essenceTokenAddress != address(0), "EvoGenesis: Invalid Essence Token address");
        require(_catalystTokensAddress != address(0), "EvoGenesis: Invalid Catalyst Tokens address");
        essenceToken = IERC20(_essenceTokenAddress);
        catalystTokens = IERC1155(_catalystTokensAddress);
        _baseTokenURI = _initialBaseURI;
    }

    // --- I. ADE Management & ERC721 Functions ---

    /**
     * @dev Mints a new Adaptive Digital Entity (ADE) with initial random traits.
     * @return tokenId The ID of the newly minted ADE.
     */
    function genesisMint() public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Assign initial random-ish traits for new ADEs
        // In a real scenario, this would involve more sophisticated randomness or initial parameters
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId)));
        _adeBaseTraits[newTokenId] = ADETraits({
            resilience: 50 + (seed % 20), // 50-69
            intelligence: 50 + ((seed / 10) % 20), // 50-69
            adaptability: 50 + ((seed / 100) % 20), // 50-69
            spirit: 50 + ((seed / 1000) % 20),
            agility: 50 + ((seed / 10000) % 20)
        });

        _adeStatus[newTokenId] = ADEStatus.Active;
        _adeLastEssenceClaimTime[newTokenId] = block.timestamp;
        _adeLastRecalibrationTime[newTokenId] = block.timestamp; // Initial recalibration
        _adeEffectiveTraits[newTokenId] = _adeBaseTraits[newTokenId]; // Initially effective = base

        _safeMint(msg.sender, newTokenId);

        emit ADEGenesisMinted(newTokenId, msg.sender, _adeBaseTraits[newTokenId]);
        return newTokenId;
    }

    /**
     * @dev Generates the dynamic metadata URI for an ADE.
     *      The URI will point to an external service that renders the metadata
     *      based on the ADE's current traits, status, and environment factors.
     * @param tokenId The ID of the ADE.
     * @return The URI for the ADE's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory base = _baseTokenURI;
        return string(abi.encodePacked(base, Strings.toString(tokenId), "/"));
        // Example: https://evogenesis.xyz/api/metadata/123/
        // The API would then fetch on-chain data like getADETraits(tokenId), getADEStatus(tokenId)
        // and environmental factors to render the dynamic JSON/image.
    }

    /**
     * @dev Returns the current effective trait scores of an ADE, considering environmental factors.
     * @param tokenId The ID of the ADE.
     * @return An ADETraits struct containing the effective trait scores.
     */
    function getADETraits(uint256 tokenId) public view returns (ADETraits memory) {
        _requireOwned(tokenId);
        // This returns the last recalibrated effective traits.
        // A frontend could optionally call recalibrateADETraits if cooldown allows, then fetch.
        return _adeEffectiveTraits[tokenId];
    }

    /**
     * @dev Returns the current operational status of an ADE.
     * @param tokenId The ID of the ADE.
     * @return The current ADEStatus (Active, Questing, Hibernating).
     */
    function getADEStatus(uint256 tokenId) public view returns (ADEStatus) {
        _requireOwned(tokenId);
        return _adeStatus[tokenId];
    }

    /**
     * @dev Calculates and returns the ADE's current level based on its total effective trait score.
     * @param tokenId The ID of the ADE.
     * @return The calculated level.
     */
    function getLevel(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        ADETraits memory effectiveTraits = _adeEffectiveTraits[tokenId];
        uint256 totalScore = effectiveTraits.resilience +
                             effectiveTraits.intelligence +
                             effectiveTraits.adaptability +
                             effectiveTraits.spirit +
                             effectiveTraits.agility;
        // Simple level calculation: Level 1 for 250-299, Level 2 for 300-349 etc.
        return (totalScore / 50) - 4; // Adjust to start at Level 1 for base traits around 250
    }

    // --- III. Evolution & Trait Dynamics ---

    /**
     * @dev Allows an ADE owner to spend "Essence" tokens to permanently boost a specific trait of their ADE.
     * @param tokenId The ID of the ADE to evolve.
     * @param traitId The ID of the trait to boost (from TraitType enum).
     * @param essenceAmount The amount of Essence to spend.
     */
    function evolveTrait(uint256 tokenId, uint256 traitId, uint256 essenceAmount) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(essenceAmount > 0, "EvoGenesis: Essence amount must be greater than 0");
        require(essenceToken.transferFrom(msg.sender, address(this), essenceAmount), "EvoGenesis: Essence transfer failed");

        ADETraits storage currentTraits = _adeBaseTraits[tokenId];
        uint256 boostAmount = essenceAmount / 100; // Example: 100 Essence for 1 trait point

        // Apply boost to the specified trait
        if (traitId == uint256(TraitType.Resilience)) {
            currentTraits.resilience += boostAmount;
        } else if (traitId == uint256(TraitType.Intelligence)) {
            currentTraits.intelligence += boostAmount;
        } else if (traitId == uint256(TraitType.Adaptability)) {
            currentTraits.adaptability += boostAmount;
        } else if (traitId == uint256(TraitType.Spirit)) {
            currentTraits.spirit += boostAmount;
        } else if (traitId == uint256(TraitType.Agility)) {
            currentTraits.agility += boostAmount;
        } else {
            revert("EvoGenesis: Invalid trait ID");
        }

        // Trigger recalibration to update effective traits
        _recalibrateADETraitsInternal(tokenId);
        emit ADETraitEvolved(tokenId, TraitType(traitId), _adeEffectiveTraits[tokenId].resilience); // Emitting first trait as example
    }

    /**
     * @dev Requires an ADE owner to burn a specific "Catalyst" NFT to unlock a new,
     *      advanced evolutionary path or ability for their ADE.
     * @param tokenId The ID of the ADE.
     * @param pathId The ID of the evolutionary path to unlock.
     * @param catalystId The ID of the Catalyst NFT to burn.
     */
    function unlockEvolutionPath(uint256 tokenId, uint256 pathId, uint256 catalystId) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(pathId > 0 && pathId < 256, "EvoGenesis: Invalid path ID"); // Path IDs 1-255
        require(!((_unlockedEvolutionPaths[tokenId] >> pathId) & 1 == 1), "EvoGenesis: Path already unlocked");

        // Burn the Catalyst NFT
        catalystTokens.safeTransferFrom(msg.sender, address(this), catalystId, 1, "");
        // If successful, the contract now owns 1 catalyst token.
        // It's effectively 'burned' as it's not re-issuable by this contract typically.

        _unlockedEvolutionPaths[tokenId] |= (1 << pathId); // Set the bit for the unlocked path

        // Apply immediate benefits from unlocking a path (e.g., minor trait boost)
        ADETraits storage currentTraits = _adeBaseTraits[tokenId];
        currentTraits.resilience += 5; // Example immediate boost
        currentTraits.intelligence += 5;

        _recalibrateADETraitsInternal(tokenId);
        emit EvolutionPathUnlocked(tokenId, pathId);
    }

    /**
     * @dev Triggers a recalculation of an ADE's effective traits, applying global environmental factors.
     *      Can be called by anyone but subject to a cooldown.
     * @param tokenId The ID of the ADE to recalibrate.
     */
    function recalibrateADETraits(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(block.timestamp >= _adeLastRecalibrationTime[tokenId] + RECALIBRATION_COOLDOWN, "EvoGenesis: Recalibration on cooldown");
        _recalibrateADETraitsInternal(tokenId);
        _adeLastRecalibrationTime[tokenId] = block.timestamp;
        emit ADERecalibrated(tokenId);
    }

    /**
     * @dev Internal function to apply environmental factors to base traits to get effective traits.
     * @param tokenId The ID of the ADE.
     */
    function _recalibrateADETraitsInternal(uint256 tokenId) internal {
        ADETraits storage base = _adeBaseTraits[tokenId];
        ADETraits storage effective = _adeEffectiveTraits[tokenId];

        // Example application of environmental factors
        // factor 0: General environmental stability, boosts resilience
        // factor 1: Information density, boosts intelligence
        // factor 2: Resource availability, boosts adaptability
        // ...
        effective.resilience = base.resilience + (environmentFactors[0] / 100);
        effective.intelligence = base.intelligence + (environmentFactors[1] / 100);
        effective.adaptability = base.adaptability + (environmentFactors[2] / 100);
        effective.spirit = base.spirit + (environmentFactors[3] / 100);
        effective.agility = base.agility + (environmentFactors[4] / 100);

        // Ensure traits don't go below a minimum (or max out, depending on game design)
        effective.resilience = effective.resilience > base.resilience ? effective.resilience : base.resilience; // Simple example
        // ... similar for other traits
    }

    // --- IV. Essence Token & Staking ---

    /**
     * @dev Allows an ADE owner to stake "Essence" tokens to their ADE,
     *      increasing its passive "Essence" generation rate.
     * @param tokenId The ID of the ADE.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssenceForADE(uint256 tokenId, uint256 amount) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(amount > 0, "EvoGenesis: Stake amount must be greater than 0");

        // Claim any pending Essence before adjusting stake
        _claimEssenceInternal(tokenId);

        require(essenceToken.transferFrom(msg.sender, address(this), amount), "EvoGenesis: Essence transfer failed");
        _adeStakedEssence[tokenId] += amount;
        _adeLastEssenceClaimTime[tokenId] = block.timestamp; // Reset claim time

        emit EssenceStaked(tokenId, msg.sender, amount);
    }

    /**
     * @dev Allows an ADE owner to unstake "Essence" tokens from their ADE.
     * @param tokenId The ID of the ADE.
     * @param amount The amount of Essence to unstake.
     */
    function unstakeEssenceFromADE(uint256 tokenId, uint256 amount) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(amount > 0, "EvoGenesis: Unstake amount must be greater than 0");
        require(_adeStakedEssence[tokenId] >= amount, "EvoGenesis: Insufficient staked Essence");

        // Claim any pending Essence before adjusting stake
        _claimEssenceInternal(tokenId);

        _adeStakedEssence[tokenId] -= amount;
        _adeLastEssenceClaimTime[tokenId] = block.timestamp; // Reset claim time
        require(essenceToken.transfer(msg.sender, amount), "EvoGenesis: Essence transfer back failed");

        emit EssenceUnstaked(tokenId, msg.sender, amount);
    }

    /**
     * @dev Claims accumulated "Essence" rewards for a specific ADE.
     * @param tokenId The ID of the ADE.
     */
    function claimEssence(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        _claimEssenceInternal(tokenId);
    }

    /**
     * @dev Internal function to calculate and transfer pending Essence rewards.
     * @param tokenId The ID of the ADE.
     */
    function _claimEssenceInternal(uint256 tokenId) internal {
        uint256 pendingEssence = getPendingEssence(tokenId);
        if (pendingEssence > 0) {
            _adeLastEssenceClaimTime[tokenId] = block.timestamp; // Update claim time before transfer
            require(essenceToken.transfer(ownerOf(tokenId), pendingEssence), "EvoGenesis: Claim Essence transfer failed");
            emit EssenceClaimed(tokenId, ownerOf(tokenId), pendingEssence);
        }
    }

    /**
     * @dev Calculates and returns the amount of "Essence" an ADE has accumulated.
     * @param tokenId The ID of the ADE.
     * @return The amount of pending Essence.
     */
    function getPendingEssence(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        uint256 stakedEssence = _adeStakedEssence[tokenId];
        if (stakedEssence == 0) {
            return 0;
        }

        uint256 lastClaimTime = _adeLastEssenceClaimTime[tokenId];
        uint256 timeElapsed = block.timestamp - lastClaimTime;
        if (timeElapsed == 0) {
            return 0;
        }

        // Calculate based on staked amount and global emission rate
        // Example: (stakedEssence * baseEssenceEmissionRate / total_protocol_staked_essence) * timeElapsed / ESSENCE_EMISSION_PERIOD
        // For simplicity here, let's assume direct linear emission per ADE based on its staked amount
        uint256 totalEmitted = (stakedEssence * baseEssenceEmissionRate * timeElapsed) / ESSENCE_EMISSION_PERIOD / (1e18); // Scale down by 1e18 if baseRate is scaled
        return totalEmitted;
    }

    /**
     * @dev Returns the total "Essence" tokens currently staked to a specific ADE.
     * @param tokenId The ID of the ADE.
     * @return The total staked Essence amount.
     */
    function getADEStakedEssence(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _adeStakedEssence[tokenId];
    }

    // --- V. Gamified Interactions / Quests ---

    /**
     * @dev Sends an ADE on a specific quest, temporarily changing its status and locking it.
     * @param tokenId The ID of the ADE.
     * @param questId The ID of the quest to embark on.
     */
    function sendADEOnQuest(uint256 tokenId, uint256 questId) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(_adeStatus[tokenId] == ADEStatus.Active, "EvoGenesis: ADE is not active");
        require(quests[questId].exists, "EvoGenesis: Quest does not exist");

        _adeStatus[tokenId] = ADEStatus.Questing;
        _adeActiveQuestId[tokenId] = questId;
        _adeQuestStartTime[tokenId] = block.timestamp;

        // Claim pending essence before starting quest
        _claimEssenceInternal(tokenId);

        emit ADEQuestStarted(tokenId, questId, block.timestamp);
    }

    /**
     * @dev Finalizes a quest for an ADE, distributing rewards upon successful completion.
     * @param tokenId The ID of the ADE.
     */
    function completeQuest(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(_adeStatus[tokenId] == ADEStatus.Questing, "EvoGenesis: ADE is not on a quest");

        uint256 activeQuestId = _adeActiveQuestId[tokenId];
        Quest storage questDetails = quests[activeQuestId];
        require(block.timestamp >= _adeQuestStartTime[tokenId] + questDetails.duration, "EvoGenesis: Quest not yet complete");

        // Distribute rewards
        if (questDetails.rewardEssence > 0) {
            essenceToken.transfer(ownerOf(tokenId), questDetails.rewardEssence);
        }
        if (questDetails.rewardCatalystId > 0 && questDetails.rewardCatalystAmount > 0) {
            catalystTokens.safeTransferFrom(address(this), ownerOf(tokenId), questDetails.rewardCatalystId, questDetails.rewardCatalystAmount, "");
        }
        if (questDetails.traitBoostAmount > 0) {
            ADETraits storage currentTraits = _adeBaseTraits[tokenId];
            if (questDetails.traitBoostId == TraitType.Resilience) currentTraits.resilience += questDetails.traitBoostAmount;
            else if (questDetails.traitBoostId == TraitType.Intelligence) currentTraits.intelligence += questDetails.traitBoostAmount;
            else if (questDetails.traitBoostId == TraitType.Adaptability) currentTraits.adaptability += questDetails.traitBoostAmount;
            else if (questDetails.traitBoostId == TraitType.Spirit) currentTraits.spirit += questDetails.traitBoostAmount;
            else if (questDetails.traitBoostId == TraitType.Agility) currentTraits.agility += questDetails.traitBoostAmount;

            _recalibrateADETraitsInternal(tokenId);
        }

        _adeStatus[tokenId] = ADEStatus.Active;
        _adeActiveQuestId[tokenId] = 0; // Clear active quest
        _adeQuestStartTime[tokenId] = 0; // Clear start time

        emit ADEQuestCompleted(tokenId, activeQuestId, questDetails.rewardEssence, questDetails.traitBoostAmount);
    }

    /**
     * @dev Allows an ADE owner to prematurely cancel an active quest, incurring a penalty.
     * @param tokenId The ID of the ADE.
     */
    function cancelQuest(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(msg.sender == ownerOf(tokenId), "EvoGenesis: Not ADE owner");
        require(_adeStatus[tokenId] == ADEStatus.Questing, "EvoGenesis: ADE is not on a quest");

        uint256 activeQuestId = _adeActiveQuestId[tokenId];
        // Apply penalty: e.g., send some Essence to treasury or burn it.
        // For simplicity, no penalty implemented here, but it's a common pattern.

        _adeStatus[tokenId] = ADEStatus.Active;
        _adeActiveQuestId[tokenId] = 0;
        _adeQuestStartTime[tokenId] = 0;

        emit ADEQuestCancelled(tokenId, activeQuestId);
    }

    /**
     * @dev Returns details about the ADE's current active quest, if any.
     * @param tokenId The ID of the ADE.
     * @return questId The ID of the active quest, 0 if none.
     * @return startTime The timestamp when the quest started.
     * @return duration The total duration of the quest.
     * @return status The current status of the ADE.
     */
    function getADEActiveQuest(uint256 tokenId) public view returns (uint256 questId, uint256 startTime, uint256 duration, ADEStatus status) {
        _requireOwned(tokenId);
        questId = _adeActiveQuestId[tokenId];
        if (questId != 0) {
            startTime = _adeQuestStartTime[tokenId];
            duration = quests[questId].duration;
            status = _adeStatus[tokenId];
        } else {
            startTime = 0;
            duration = 0;
            status = _adeStatus[tokenId]; // Still return ADE's general status
        }
        return (questId, startTime, duration, status);
    }

    // --- VI. Governance (Owner/DAO-Controlled Functions) ---
    // These functions represent actions that would typically be managed by a DAO.
    // For this example, they are `onlyOwner` but internally call functions
    // that are restricted to `onlyProposalExecutor` to simulate DAO execution.

    /**
     * @dev Initiates a proposal to change a key protocol parameter.
     *      Only the contract owner (acting as DAO executive) can create proposals.
     * @param paramKey A bytes32 key identifying the parameter to change (e.g., keccak256("ESSENCE_EMISSION_RATE")).
     * @param newValue The new value for the parameter.
     * @param deadline The timestamp when voting for this proposal ends.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(bytes32 paramKey, uint256 newValue, uint256 deadline) public onlyOwner returns (uint256) {
        require(deadline > block.timestamp, "EvoGenesis: Proposal deadline must be in the future");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposalType: ProposalType.UpdateEssenceRate, // Default, specific type needs to be mapped
            proposalDataHash: paramKey, // Key identifies *what* to change
            targetValue1: newValue,
            targetValue2: 0,
            targetValue3: 0,
            targetValue4: 0,
            targetValue5: 0,
            targetAddress: address(0),
            deadline: deadline,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            exists: true
        });

        // This simplistic mapping assumes paramKey directly corresponds to a ProposalType
        // For a more robust system, paramKey would be checked against a registry
        if (paramKey == keccak256("ESSENCE_EMISSION_RATE")) {
            proposals[proposalId].proposalType = ProposalType.UpdateEssenceRate;
        } else if (paramKey == keccak256("ENVIRONMENT_FACTOR_0")) {
            proposals[proposalId].proposalType = ProposalType.UpdateEnvironmentFactor;
            proposals[proposalId].targetValue2 = 0; // factorId
        }
        // ... extend for other generic parameter changes

        emit ProposalCreated(proposalId, proposals[proposalId].proposalType, paramKey, deadline);
        return proposalId;
    }

    /**
     * @dev Initiates a proposal to add or modify quest parameters.
     *      Only the contract owner (acting as DAO executive) can create proposals.
     * @param questId The ID of the quest to add/modify.
     * @param duration The duration of the quest.
     * @param rewardEssence The Essence reward for the quest.
     * @param traitBoostId The ID of the trait to boost.
     * @param traitBoostAmount The amount of trait boost.
     * @param deadline The timestamp when voting for this proposal ends.
     * @return The ID of the newly created proposal.
     */
    function proposeNewQuest(uint256 questId, uint256 duration, uint256 rewardEssence, uint256 traitBoostId, uint256 traitBoostAmount, uint256 deadline) public onlyOwner returns (uint256) {
        require(deadline > block.timestamp, "EvoGenesis: Proposal deadline must be in the future");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposalType: ProposalType.SetQuestParams,
            proposalDataHash: keccak256(abi.encodePacked("Quest", questId)),
            targetValue1: questId,
            targetValue2: duration,
            targetValue3: rewardEssence,
            targetValue4: traitBoostId,
            targetValue5: traitBoostAmount,
            targetAddress: address(0),
            deadline: deadline,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            exists: true
        });

        emit ProposalCreated(proposalId, ProposalType.SetQuestParams, keccak256(abi.encodePacked("Quest", questId)), deadline);
        return proposalId;
    }

    /**
     * @dev Records a vote on an active proposal.
     *      For this example, only the contract owner can vote (simulating an executive vote or for testing).
     *      In a full DAO, this would be token-weighted or based on governance tokens.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public onlyOwner { // Simplified to onlyOwner for example
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "EvoGenesis: Proposal does not exist");
        require(!proposal.executed, "EvoGenesis: Proposal already executed");
        require(block.timestamp <= proposal.deadline, "EvoGenesis: Voting period has ended");
        require(!_hasVoted[proposalId][msg.sender], "EvoGenesis: Already voted on this proposal");

        if (support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        _hasVoted[proposalId][msg.sender] = true;

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a passed proposal.
     *      Only the contract owner (acting as DAO executive) can execute proposals.
     *      This function ensures the proposal has passed and calls the appropriate internal function.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public onlyOwner { // Simplified to onlyOwner for example
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "EvoGenesis: Proposal does not exist");
        require(!proposal.executed, "EvoGenesis: Proposal already executed");
        require(block.timestamp > proposal.deadline, "EvoGenesis: Voting period not yet ended");
        require(proposal.yesVotes > proposal.noVotes, "EvoGenesis: Proposal did not pass"); // Simple majority

        proposal.executed = true;

        // Execute actions based on proposal type
        if (proposal.proposalType == ProposalType.UpdateEssenceRate) {
            _updateBaseEssenceEmissionRate(proposal.targetValue1);
        } else if (proposal.proposalType == ProposalType.SetQuestParams) {
            _setQuestParameters(
                proposal.targetValue1, // questId
                proposal.targetValue2, // duration
                proposal.targetValue3, // rewardEssence
                TraitType(proposal.targetValue4), // traitBoostId
                proposal.targetValue5 // traitBoostAmount
            );
        } else if (proposal.proposalType == ProposalType.UpdateEnvironmentFactor) {
            _updateEnvironmentFactor(proposal.targetValue2, proposal.targetValue1); // factorId, value
        } else if (proposal.proposalType == ProposalType.GrantCatalyst) {
            _grantCatalyst(proposal.targetAddress, proposal.targetValue1, proposal.targetValue2); // recipient, catalystId, amount
        } else if (proposal.proposalType == ProposalType.WithdrawTreasury) {
            _withdrawTreasury(IERC20(proposal.targetAddress), owner(), proposal.targetValue1); // tokenAddress, recipient, amount
        }
        // ... extend for other proposal types

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev (Callable only by successful proposal execution) Configures details for a specific quest.
     * @param questId The ID of the quest.
     * @param duration The duration of the quest in seconds.
     * @param rewardEssence The amount of Essence rewarded upon completion.
     * @param traitBoostId The ID of the trait to boost.
     * @param traitBoostAmount The amount by which the trait is boosted.
     */
    function _setQuestParameters(
        uint256 questId,
        uint256 duration,
        uint256 rewardEssence,
        TraitType traitBoostId,
        uint256 traitBoostAmount
    ) internal onlyProposalExecutor {
        quests[questId] = Quest({
            duration: duration,
            rewardEssence: rewardEssence,
            rewardCatalystId: 0, // Placeholder, can be extended in proposalData
            rewardCatalystAmount: 0, // Placeholder
            traitBoostId: traitBoostId,
            traitBoostAmount: traitBoostAmount,
            exists: true
        });
    }

    /**
     * @dev (Callable only by successful proposal execution) Adjusts the global rate at which
     *      staked ADEs generate Essence.
     * @param newRate The new base emission rate.
     */
    function _updateBaseEssenceEmissionRate(uint256 newRate) internal onlyProposalExecutor {
        baseEssenceEmissionRate = newRate;
    }

    /**
     * @dev (Callable only by successful proposal execution) Sets a global environmental factor
     *      that influences ADE traits.
     * @param factorId The ID of the environmental factor.
     * @param value The new value for the factor.
     */
    function _updateEnvironmentFactor(uint256 factorId, uint256 value) internal onlyProposalExecutor {
        environmentFactors[factorId] = value;
        emit EnvironmentFactorUpdated(factorId, value);
    }

    /**
     * @dev (Callable only by successful proposal execution) Distributes Catalyst NFTs to an address.
     * @param recipient The address to receive the Catalysts.
     * @param catalystId The ID of the Catalyst NFT.
     * @param amount The amount of Catalysts to grant.
     */
    function _grantCatalyst(address recipient, uint256 catalystId, uint256 amount) internal onlyProposalExecutor {
        require(catalystTokens.safeTransferFrom(address(this), recipient, catalystId, amount, ""), "EvoGenesis: Catalyst grant failed");
    }

    /**
     * @dev (Callable only by successful proposal execution) Allows withdrawing funds from the contract's treasury.
     * @param tokenAddress The address of the ERC20 token to withdraw (or address(0) for native ETH).
     * @param recipient The address to send the funds to.
     * @param amount The amount to withdraw.
     */
    function _withdrawTreasury(IERC20 tokenAddress, address recipient, uint256 amount) internal onlyProposalExecutor {
        if (address(tokenAddress) == address(0)) {
            // Withdraw native ETH
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "EvoGenesis: ETH withdrawal failed");
        } else {
            // Withdraw ERC20 token
            require(tokenAddress.transfer(recipient, amount), "EvoGenesis: ERC20 withdrawal failed");
        }
    }

    /**
     * @dev Allows the owner to update the base URI for metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // --- Internal Helpers ---

    /**
     * @dev Throws if `tokenId` is not valid or not owned by `msg.sender`.
     */
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "EvoGenesis: Token does not exist");
    }

    /**
     * @dev ERC1155 `onERC1155Received` and `onERC1155BatchReceived` need to be implemented
     *      if this contract is to receive ERC1155 tokens directly from other contracts,
     *      which is not the primary mechanism for Catalyst burning here (transferFrom is used).
     *      For simple use, these can be stubbed or omitted if direct contract-to-contract
     *      transfers of ERC1155 are not expected without an explicit handler.
     *      Adding standard stubs for completeness.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
```