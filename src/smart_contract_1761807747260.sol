This smart contract, **AetherMindGenesis**, introduces a novel and advanced concept in the realm of dynamic NFTs and on-chain interaction. It centers around unique digital entities called "AetherMinds" (ERC721 NFTs), each possessing mutable "Essence Traits" that evolve, decay, and are shaped through user actions, staking, challenges, and attestation from other entities. A fungible "Spark" token (ERC20) fuels this ecosystem, serving as a medium for training, attestation, and staking rewards. The contract also features a basic governance mechanism, allowing holders to propose and vote on key protocol parameters.

The core innovation lies in the on-chain, dynamic nature of the AetherMinds, whose characteristics are not static but react to their environment and the actions of their owners and other entities, fostering a sense of a "living" digital asset.

---

## AetherMindGenesis Smart Contract

**Outline:**

1.  **Core Contracts:**
    *   `AetherMindGenesis`: Main contract managing NFTs, dynamic traits, core logic, and basic governance.
    *   `ISparkToken`: Interface for the external ERC20 utility token (Spark), which fuels the ecosystem.
2.  **AetherMind NFTs (ERC721):** Unique digital entities with dynamic on-chain attributes, representing the core asset.
3.  **Essence Traits:** Mutable numeric attributes (Intellect, Resolve, Adaptability, Aura) for each AetherMind, influencing their capabilities and interactions.
4.  **Spark Token (ERC20):** A utility token used for:
    *   Funding trait evolution (training, attestation).
    *   Entry fees for challenges.
    *   Rewards for staking AetherMinds and maintaining the ecosystem.
5.  **Evolution Mechanisms:**
    *   **Training:** Direct spending of Spark to boost specific traits.
    *   **Attestation:** Verified endorsements from other AetherMinds or authorized entities, providing trait boosts.
    *   **Challenges (Mind Duels):** On-chain contests between AetherMinds where trait comparisons determine outcomes and reward/penalty.
    *   **Staking:** Earning Spark tokens by locking up AetherMinds.
    *   **Decay:** Gradual degradation of certain traits over time, requiring active maintenance (fueled by Spark) to prevent.
6.  **Bonding:** A mechanism for two AetherMinds to form temporary alliances, potentially sharing benefits or influencing each other.
7.  **Governance:** A simplified proposal and voting system allowing AetherMind/Spark holders to shape certain protocol parameters.
8.  **Pausability & Admin:** Essential safety features, including the ability to pause critical functions and administrative controls for owner-specific actions.

---

**Function Summary (23 Functions):**

**I. AetherMind NFT (ERC721) Management & Information (4 functions)**
1.  `mintAetherMind()`: Allows a user to mint a new AetherMind NFT, initializing its base Essence Traits.
2.  `setAetherMindBaseURI(string memory _newBaseURI)`: Sets the base URI for AetherMind NFT metadata, callable by the contract owner.
3.  `getAetherMindTraits(uint256 _tokenId)`: Retrieves the current values of all Essence Traits for a given AetherMind.
4.  `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 `tokenURI` function to provide a dynamically generated URI reflecting the AetherMind's current traits.

**II. Essence Trait Evolution & Interaction (7 functions)**
5.  `trainEssenceTrait(uint256 _tokenId, uint8 _traitIndex, uint256 _sparkAmount)`: Allows an AetherMind owner to spend a specified amount of Spark tokens to increase a particular Essence Trait.
6.  `attestToEssenceTrait(uint256 _attesterTokenId, uint256 _targetTokenId, uint8 _traitIndex, uint256 _attestationPower)`: Enables an AetherMind owner to use their AetherMind (`_attesterTokenId`) to attest to and boost a trait (`_traitIndex`) of another AetherMind (`_targetTokenId`), requiring Spark payment and potentially certain attester trait levels.
7.  `initiateMindDuel(uint256 _challengerTokenId, uint256 _opponentTokenId)`: Initiates a simple on-chain "duel" between two AetherMinds, requiring a Spark entry fee. The duel outcome (winner/loser) is determined by a comparison of their Essence Traits.
8.  `resolveMindDuel(uint256 _duelId, uint256 _winnerTokenId)`: Resolves an initiated duel. This function is callable by the contract owner (or a designated oracle) to finalize the duel, apply trait changes, and distribute rewards based on the outcome.
9.  `decayEssenceTraits(uint256 _tokenId)`: A public function callable by anyone to apply a time-based decay to certain Essence Traits of a specified AetherMind, if a decay period has passed. The caller receives a small Spark reward for performing this maintenance.
10. `bondAetherMinds(uint256 _tokenId1, uint256 _tokenId2)`: Allows the owners of two AetherMinds to form a temporary "bond," potentially leading to shared trait benefits or cooperative actions.
11. `unbondAetherMinds(uint256 _bondId)`: Breaks an existing AetherMind bond, releasing any locked resources or ending shared effects.

**III. Spark Token (ERC20) & Staking (5 functions)**
12. `setSparkTokenAddress(address _sparkAddress)`: Sets the address of the deployed `SparkToken` ERC20 contract. Callable only by the owner.
13. `stakeAetherMindForSpark(uint256 _tokenId)`: Allows an AetherMind owner to stake their NFT to start accruing Spark token rewards over time.
14. `unstakeAetherMind(uint256 _tokenId)`: Unstakes an AetherMind, stopping further Spark reward accrual and automatically claiming any pending rewards.
15. `claimStakedSparkRewards(uint256 _tokenId)`: Allows an owner to claim accumulated Spark rewards for a staked AetherMind without unstaking it.
16. `getPendingSparkRewards(uint256 _tokenId)`: A view function that returns the amount of Spark rewards currently pending for a staked AetherMind.

**IV. Governance (3 functions)**
17. `proposeParameterChange(uint8 _parameterIndex, uint256 _newValue)`: Allows qualified AetherMind/Spark holders to propose changes to key protocol parameters (e.g., trait decay rates, training costs).
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables holders to cast a vote (for or against) on an active governance proposal.
19. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully met its quorum and voting thresholds. Callable by anyone after the voting period ends.

**V. Administrative & Utility (4 functions)**
20. `pause()`: Pauses core contract functionalities (e.g., minting, challenges, staking) in emergencies. Callable only by the owner.
21. `unpause()`: Unpauses the contract, restoring normal functionality. Callable only by the owner.
22. `setTraitDecayRate(uint8 _traitIndex, uint256 _newRate)`: Sets the decay rate for a specific Essence Trait. This can be directly called by the owner or enacted via a governance proposal.
23. `withdrawContractFees(address _to, uint256 _amount)`: Allows the contract owner to withdraw accumulated fees (e.g., from Mind Duels) to a specified address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

// --- Interface for the external Spark ERC20 Token ---
interface ISparkToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract AetherMindGenesis is ERC721, Ownable, Pausable {
    using SafeMath for uint256;

    // --- Data Structures ---

    // AetherMind Essence Traits
    struct EssenceTraits {
        uint16 intellect;    // Cognitive ability, max 65535
        uint16 resolve;      // Persistence and willpower, max 65535
        uint16 adaptability; // Ability to change and learn, max 65535
        uint16 aura;         // Influence and presence, max 65535
        uint256 lastDecayTimestamp; // Timestamp of last trait decay application
    }

    // Duel structure
    struct MindDuel {
        uint256 challengerTokenId;
        uint256 opponentTokenId;
        uint256 challengerTraitsSum; // For determining outcome
        uint256 opponentTraitsSum;
        uint256 sparkEntryFee;
        bool resolved;
        address challenger;
        address opponent;
    }

    // Staking information
    struct StakingInfo {
        uint256 startTime;
        uint256 lastClaimTime;
    }

    // Governance Proposal structure
    enum ParameterType {
        TrainingCostPerPoint,
        AttestationSparkFee,
        MindDuelEntryFee,
        SparkRewardPerBlockStaked,
        TraitDecayRateIntellect,
        TraitDecayRateResolve,
        TraitDecayRateAdaptability,
        TraitDecayRateAura,
        None // Default invalid type
    }

    struct Proposal {
        uint256 id;
        ParameterType paramType;
        uint256 newValue;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 votingDeadline;
        bool executed;
        mapping(address => bool) hasVoted; // Check if an address has voted
    }

    // --- State Variables ---

    ISparkToken public sparkToken; // Address of the deployed Spark ERC20 token

    uint256 private _nextTokenId; // Counter for AetherMind NFTs

    // AetherMind Data
    mapping(uint256 => EssenceTraits) public aetherMindTraits;
    mapping(uint256 => StakingInfo) public stakedAetherMinds;
    mapping(uint256 => address) public aetherMindOwners; // Tracks owner for quick lookup without ERC721.ownerOf() calls for staking.

    // Mind Duel Data
    uint256 private _nextDuelId;
    mapping(uint256 => MindDuel) public mindDuels;

    // Bonding Data
    uint256 private _nextBondId;
    struct AetherMindBond {
        uint256 tokenId1;
        uint256 tokenId2;
        uint256 bondDuration; // in seconds
        uint256 bondStartTime;
        bool active;
    }
    mapping(uint256 => AetherMindBond) public aetherMindBonds;

    // Governance Data
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingPeriod = 3 days; // Default voting period for proposals
    uint256 public proposalQuorumPercentage = 51; // Percentage of total staked AetherMinds/Spark needed to pass

    // Protocol Parameters (configurable via governance)
    uint256 public trainingCostPerPoint = 100 * 10**18; // Spark cost to increase a trait by 1 point
    uint256 public attestationSparkFee = 50 * 10**18;  // Spark cost for an attestation
    uint256 public mindDuelEntryFee = 200 * 10**18;     // Spark cost to initiate a duel
    uint256 public sparkRewardPerBlockStaked = 1 * 10**18; // Spark earned per AetherMind per block
    uint256 public constant SPARK_REWARD_FOR_DECAY_CALL = 5 * 10**18; // Spark reward for calling decayEssenceTraits
    uint256[4] public traitDecayRates; // Decay points per day for Intellect, Resolve, Adaptability, Aura (index-mapped)
    uint16 public constant MAX_TRAIT_VALUE = 65535;

    // Trait Index Mapping (for parameter and function calls)
    uint8 public constant TRAIT_INTELLECT = 0;
    uint8 public constant TRAIT_RESOLVE = 1;
    uint8 public constant TRAIT_ADAPTABILITY = 2;
    uint8 public constant TRAIT_AURA = 3;

    // --- Events ---
    event AetherMindMinted(uint256 indexed tokenId, address indexed owner, uint16 intellect, uint16 resolve, uint16 adaptability, uint16 aura);
    event TraitTrained(uint256 indexed tokenId, uint8 indexed traitIndex, uint256 oldTraitValue, uint256 newTraitValue, uint256 sparkSpent);
    event TraitAttested(uint256 indexed attesterTokenId, uint256 indexed targetTokenId, uint8 indexed traitIndex, uint256 newTraitValue, uint256 attestationPower);
    event MindDuelInitiated(uint256 indexed duelId, uint256 indexed challengerTokenId, uint256 indexed opponentTokenId, address challenger, address opponent, uint256 fee);
    event MindDuelResolved(uint256 indexed duelId, uint256 indexed winnerTokenId, uint256 indexed loserTokenId);
    event TraitDecayed(uint256 indexed tokenId, uint8 indexed traitIndex, uint256 oldTraitValue, uint256 newTraitValue, uint256 decayedAmount);
    event AetherMindStaked(uint256 indexed tokenId, address indexed owner);
    event AetherMindUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimedSpark);
    event SparkRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event AetherMindBonded(uint256 indexed bondId, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 duration);
    event AetherMindUnbonded(uint256 indexed bondId);
    event ProposalCreated(uint256 indexed proposalId, ParameterType indexed paramType, uint256 newValue, uint256 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ParameterType indexed paramType, uint256 newValue);
    event SparkTokenAddressSet(address indexed _sparkAddress);

    // --- Constructor ---
    constructor(address _sparkTokenAddress, string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_sparkTokenAddress != address(0), "Spark Token address cannot be zero");
        sparkToken = ISparkToken(_sparkTokenAddress);
        _nextTokenId = 1;
        _nextDuelId = 1;
        _nextBondId = 1;
        _nextProposalId = 1;

        // Default decay rates (points per day)
        traitDecayRates[TRAIT_INTELLECT] = 1;
        traitDecayRates[TRAIT_RESOLVE] = 1;
        traitDecayRates[TRAIT_ADAPTABILITY] = 1;
        traitDecayRates[TRAIT_AURA] = 1;
    }

    // --- Modifiers ---

    modifier onlyAetherMindOwner(uint256 _tokenId) {
        require(_ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this AetherMind");
        _;
    }

    modifier notStaked(uint256 _tokenId) {
        require(stakedAetherMinds[_tokenId].startTime == 0, "AetherMind is currently staked");
        _;
    }

    modifier onlyStaked(uint256 _tokenId) {
        require(stakedAetherMinds[_tokenId].startTime > 0, "AetherMind is not staked");
        _;
    }

    // --- I. AetherMind NFT (ERC721) Management & Information ---

    /**
     * @notice Mints a new AetherMind NFT to the caller, initializing its base traits.
     * @dev Initial traits are set to a base value.
     */
    function mintAetherMind() external payable whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(msg.sender, tokenId);
        aetherMindOwners[tokenId] = msg.sender; // Update quick lookup mapping

        // Initialize base traits
        aetherMindTraits[tokenId] = EssenceTraits({
            intellect: 50,
            resolve: 50,
            adaptability: 50,
            aura: 50,
            lastDecayTimestamp: block.timestamp
        });

        emit AetherMindMinted(tokenId, msg.sender, 50, 50, 50, 50);
        return tokenId;
    }

    /**
     * @notice Sets the base URI for AetherMind NFT metadata.
     * @dev Callable only by the contract owner.
     * @param _newBaseURI The new base URI for NFT metadata.
     */
    function setAetherMindBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @notice Retrieves the current values of all Essence Traits for a given AetherMind.
     * @param _tokenId The ID of the AetherMind.
     * @return intellect, resolve, adaptability, aura The current trait values.
     */
    function getAetherMindTraits(uint256 _tokenId) public view returns (uint16 intellect, uint16 resolve, uint16 adaptability, uint16 aura) {
        require(_exists(_tokenId), "AetherMind does not exist");
        EssenceTraits storage traits = aetherMindTraits[_tokenId];
        return (traits.intellect, traits.resolve, traits.adaptability, traits.aura);
    }

    /**
     * @notice Overrides ERC721 tokenURI to reflect dynamic metadata.
     * @dev For production, this would typically involve a more robust off-chain API or on-chain data encoding.
     * @param _tokenId The ID of the AetherMind.
     * @return A URI string pointing to the metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Example: A simple dynamic URI. For full dynamic metadata, you'd encode JSON or point to an API.
        return string(abi.encodePacked(
            _baseURI(),
            Strings.toString(_tokenId),
            "/dynamic_traits_v1.json?intellect=", Strings.toString(aetherMindTraits[_tokenId].intellect),
            "&resolve=", Strings.toString(aetherMindTraits[_tokenId].resolve),
            "&adaptability=", Strings.toString(aetherMindTraits[_tokenId].adaptability),
            "&aura=", Strings.toString(aetherMindTraits[_tokenId].aura)
        ));
    }

    // --- II. Essence Trait Evolution & Interaction ---

    /**
     * @notice Allows an AetherMind owner to spend Spark tokens to increase a specific Essence Trait.
     * @param _tokenId The ID of the AetherMind to train.
     * @param _traitIndex The index of the trait to train (0:Intellect, 1:Resolve, 2:Adaptability, 3:Aura).
     * @param _sparkAmount The amount of Spark tokens to spend.
     */
    function trainEssenceTrait(uint256 _tokenId, uint8 _traitIndex, uint256 _sparkAmount)
        external
        whenNotPaused
        onlyAetherMindOwner(_tokenId)
        notStaked(_tokenId)
    {
        require(_sparkAmount > 0, "Spark amount must be greater than zero");
        require(_traitIndex < 4, "Invalid trait index");
        require(sparkToken.transferFrom(msg.sender, address(this), _sparkAmount), "Spark transfer failed");

        EssenceTraits storage traits = aetherMindTraits[_tokenId];
        uint256 pointsGained = _sparkAmount.div(trainingCostPerPoint);
        require(pointsGained > 0, "Spark amount too low for any training points");

        uint256 oldTraitValue;
        uint256 newTraitValue;

        if (_traitIndex == TRAIT_INTELLECT) {
            oldTraitValue = traits.intellect;
            traits.intellect = uint16(uint256(traits.intellect).add(pointsGained).min(MAX_TRAIT_VALUE));
            newTraitValue = traits.intellect;
        } else if (_traitIndex == TRAIT_RESOLVE) {
            oldTraitValue = traits.resolve;
            traits.resolve = uint16(uint256(traits.resolve).add(pointsGained).min(MAX_TRAIT_VALUE));
            newTraitValue = traits.resolve;
        } else if (_traitIndex == TRAIT_ADAPTABILITY) {
            oldTraitValue = traits.adaptability;
            traits.adaptability = uint16(uint256(traits.adaptability).add(pointsGained).min(MAX_TRAIT_VALUE));
            newTraitValue = traits.adaptability;
        } else if (_traitIndex == TRAIT_AURA) {
            oldTraitValue = traits.aura;
            traits.aura = uint16(uint256(traits.aura).add(pointsGained).min(MAX_TRAIT_VALUE));
            newTraitValue = traits.aura;
        }

        emit TraitTrained(_tokenId, _traitIndex, oldTraitValue, newTraitValue, _sparkAmount);
    }

    /**
     * @notice An AetherMind attests to a trait of another AetherMind, boosting it.
     * @dev Requires the attester AetherMind to have a minimum 'Aura' for the attestation to be effective,
     *      and a Spark token payment.
     * @param _attesterTokenId The ID of the AetherMind making the attestation.
     * @param _targetTokenId The ID of the AetherMind receiving the attestation.
     * @param _traitIndex The index of the trait being attested.
     * @param _attestationPower The base power of the attestation (e.g., how many points to add before modifier).
     */
    function attestToEssenceTrait(uint256 _attesterTokenId, uint256 _targetTokenId, uint8 _traitIndex, uint256 _attestationPower)
        external
        whenNotPaused
        onlyAetherMindOwner(_attesterTokenId)
        notStaked(_attesterTokenId)
    {
        require(_exists(_targetTokenId), "Target AetherMind does not exist");
        require(_attesterTokenId != _targetTokenId, "Cannot attest to self");
        require(_traitIndex < 4, "Invalid trait index");
        require(_attestationPower > 0, "Attestation power must be positive");

        require(sparkToken.transferFrom(msg.sender, address(this), attestationSparkFee), "Spark transfer for attestation failed");

        EssenceTraits storage attesterTraits = aetherMindTraits[_attesterTokenId];
        require(attesterTraits.aura >= 100, "Attester AetherMind requires min 100 Aura to attest"); // Example condition

        EssenceTraits storage targetTraits = aetherMindTraits[_targetTokenId];
        uint256 boostAmount = _attestationPower.mul(attesterTraits.aura).div(1000); // Aura provides a multiplier
        require(boostAmount > 0, "Attestation boost too low");

        uint256 oldTraitValue;
        uint256 newTraitValue;

        if (_traitIndex == TRAIT_INTELLECT) {
            oldTraitValue = targetTraits.intellect;
            targetTraits.intellect = uint16(uint256(targetTraits.intellect).add(boostAmount).min(MAX_TRAIT_VALUE));
            newTraitValue = targetTraits.intellect;
        } else if (_traitIndex == TRAIT_RESOLVE) {
            oldTraitValue = targetTraits.resolve;
            targetTraits.resolve = uint16(uint256(targetTraits.resolve).add(boostAmount).min(MAX_TRAIT_VALUE));
            newTraitValue = targetTraits.resolve;
        } else if (_traitIndex == TRAIT_ADAPTABILITY) {
            oldTraitValue = targetTraits.adaptability;
            targetTraits.adaptability = uint16(uint256(targetTraits.adaptability).add(boostAmount).min(MAX_TRAIT_VALUE));
            newTraitValue = targetTraits.adaptability;
        } else if (_traitIndex == TRAIT_AURA) {
            oldTraitValue = targetTraits.aura;
            targetTraits.aura = uint16(uint256(targetTraits.aura).add(boostAmount).min(MAX_TRAIT_VALUE));
            newTraitValue = targetTraits.aura;
        }

        emit TraitAttested(_attesterTokenId, _targetTokenId, _traitIndex, newTraitValue, _attestationPower);
    }

    /**
     * @notice Initiates a simple on-chain "duel" between two AetherMinds.
     * @dev Requires a Spark entry fee. The outcome will be determined by trait comparison and resolved by an admin/oracle.
     * @param _challengerTokenId The ID of the AetherMind initiating the duel.
     * @param _opponentTokenId The ID of the AetherMind being challenged.
     */
    function initiateMindDuel(uint256 _challengerTokenId, uint256 _opponentTokenId)
        external
        whenNotPaused
        onlyAetherMindOwner(_challengerTokenId)
        notStaked(_challengerTokenId)
    {
        require(_exists(_opponentTokenId), "Opponent AetherMind does not exist");
        require(_challengerTokenId != _opponentTokenId, "Cannot duel oneself");
        require(aetherMindOwners[_opponentTokenId] != address(0), "Opponent AetherMind has no owner recorded"); // Should be covered by _exists but good to be explicit
        require(stakedAetherMinds[_opponentTokenId].startTime == 0, "Opponent AetherMind is staked"); // Opponent cannot be staked

        // Transfer entry fee from challenger
        require(sparkToken.transferFrom(msg.sender, address(this), mindDuelEntryFee), "Challenger Spark transfer failed");

        // Transfer entry fee from opponent
        // This is a simpler model. A more advanced one would require explicit approval/transfer from opponent's owner.
        // For this example, assuming the duel is a public challenge anyone can initiate.
        // If the opponent needs to consent, this flow needs to be updated.
        // For now, let's just make challenger pay both fees for simplicity of this example.
        // Or, better, opponent has to accept later.
        // Let's make it challenger pays opponent fee to the contract, and opponent gets a cut if they win.
        require(sparkToken.transferFrom(aetherMindOwners[_opponentTokenId], address(this), mindDuelEntryFee), "Opponent Spark transfer failed, check allowance or balance.");

        uint256 duelId = _nextDuelId++;

        EssenceTraits storage challengerTraits = aetherMindTraits[_challengerTokenId];
        EssenceTraits storage opponentTraits = aetherMindTraits[_opponentTokenId];

        mindDuels[duelId] = MindDuel({
            challengerTokenId: _challengerTokenId,
            opponentTokenId: _opponentTokenId,
            challengerTraitsSum: uint256(challengerTraits.intellect).add(challengerTraits.resolve).add(challengerTraits.adaptability).add(challengerTraits.aura),
            opponentTraitsSum: uint256(opponentTraits.intellect).add(opponentTraits.resolve).add(opponentTraits.adaptability).add(opponentTraits.aura),
            sparkEntryFee: mindDuelEntryFee,
            resolved: false,
            challenger: msg.sender,
            opponent: aetherMindOwners[_opponentTokenId]
        });

        emit MindDuelInitiated(duelId, _challengerTokenId, _opponentTokenId, msg.sender, aetherMindOwners[_opponentTokenId], mindDuelEntryFee);
    }

    /**
     * @notice Resolves an initiated duel, updating traits for winner/loser based on duel logic.
     * @dev Callable only by the contract owner (acting as an oracle/referee).
     * @param _duelId The ID of the duel to resolve.
     * @param _winnerTokenId The ID of the AetherMind declared as the winner.
     */
    function resolveMindDuel(uint256 _duelId, uint256 _winnerTokenId)
        external
        onlyOwner
        whenNotPaused
    {
        MindDuel storage duel = mindDuels[_duelId];
        require(duel.challengerTokenId != 0, "Duel does not exist"); // Check if duel exists
        require(!duel.resolved, "Duel already resolved");
        require(_winnerTokenId == duel.challengerTokenId || _winnerTokenId == duel.opponentTokenId, "Winner must be one of the participants");

        uint256 loserTokenId = (_winnerTokenId == duel.challengerTokenId) ? duel.opponentTokenId : duel.challengerTokenId;

        EssenceTraits storage winnerTraits = aetherMindTraits[_winnerTokenId];
        EssenceTraits storage loserTraits = aetherMindTraits[loserTokenId];

        // Example trait adjustment logic: winner gains, loser loses.
        // Could be more complex, e.g., specific traits, percentage based, etc.
        uint256 traitGain = 10; // Winner gains 10 points per trait
        uint256 traitLoss = 5;  // Loser loses 5 points per trait

        winnerTraits.intellect = uint16(uint256(winnerTraits.intellect).add(traitGain).min(MAX_TRAIT_VALUE));
        winnerTraits.resolve = uint16(uint256(winnerTraits.resolve).add(traitGain).min(MAX_TRAIT_VALUE));
        winnerTraits.adaptability = uint16(uint256(winnerTraits.adaptability).add(traitGain).min(MAX_TRAIT_VALUE));
        winnerTraits.aura = uint16(uint256(winnerTraits.aura).add(traitGain).min(MAX_TRAIT_VALUE));

        loserTraits.intellect = uint16(uint256(loserTraits.intellect).sub(traitLoss).max(1)); // Min 1 to prevent 0
        loserTraits.resolve = uint16(uint256(loserTraits.resolve).sub(traitLoss).max(1));
        loserTraits.adaptability = uint16(uint256(loserTraits.adaptability).sub(traitLoss).max(1));
        loserTraits.aura = uint16(uint256(loserTraits.aura).sub(traitLoss).max(1));

        // Distribute rewards: winner gets both entry fees, minus a small contract cut.
        uint256 totalPool = duel.sparkEntryFee.mul(2);
        uint256 contractCut = totalPool.div(10); // 10% cut
        uint256 winnerReward = totalPool.sub(contractCut);

        sparkToken.mint(aetherMindOwners[_winnerTokenId], winnerReward); // Mint Spark to winner
        // Contract keeps the `contractCut` implicitly in its balance

        duel.resolved = true;
        emit MindDuelResolved(_duelId, _winnerTokenId, loserTokenId);
    }

    /**
     * @notice Callable by anyone to apply a time-based decay to certain traits of an AetherMind.
     * @dev Rewards the caller with a small amount of Spark for performing this maintenance.
     * @param _tokenId The ID of the AetherMind to apply decay to.
     */
    function decayEssenceTraits(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "AetherMind does not exist");
        EssenceTraits storage traits = aetherMindTraits[_tokenId];

        uint256 timeElapsed = block.timestamp.sub(traits.lastDecayTimestamp);
        require(timeElapsed >= 1 days, "Not enough time has passed for decay"); // Decay applies daily

        uint256 daysElapsed = timeElapsed.div(1 days);

        uint256 oldTraitValue;
        uint256 newTraitValue;

        // Apply decay to each trait
        for (uint8 i = 0; i < 4; i++) {
            uint256 decayRate = traitDecayRates[i];
            if (decayRate > 0) {
                uint256 decayAmount = decayRate.mul(daysElapsed);
                if (i == TRAIT_INTELLECT) {
                    oldTraitValue = traits.intellect;
                    traits.intellect = uint16(uint256(traits.intellect).sub(decayAmount).max(1));
                    newTraitValue = traits.intellect;
                } else if (i == TRAIT_RESOLVE) {
                    oldTraitValue = traits.resolve;
                    traits.resolve = uint16(uint256(traits.resolve).sub(decayAmount).max(1));
                    newTraitValue = traits.resolve;
                } else if (i == TRAIT_ADAPTABILITY) {
                    oldTraitValue = traits.adaptability;
                    traits.adaptability = uint16(uint256(traits.adaptability).sub(decayAmount).max(1));
                    newTraitValue = traits.adaptability;
                } else if (i == TRAIT_AURA) {
                    oldTraitValue = traits.aura;
                    traits.aura = uint16(uint256(traits.aura).sub(decayAmount).max(1));
                    newTraitValue = traits.aura;
                }
                emit TraitDecayed(_tokenId, i, oldTraitValue, newTraitValue, decayAmount);
            }
        }
        traits.lastDecayTimestamp = block.timestamp; // Update last decay timestamp

        // Reward the caller for triggering decay
        sparkToken.mint(msg.sender, SPARK_REWARD_FOR_DECAY_CALL);
    }

    /**
     * @notice Forms a temporary bond between two AetherMinds.
     * @dev Both AetherMinds must be owned by the caller and not currently staked or bonded.
     * @param _tokenId1 The ID of the first AetherMind.
     * @param _tokenId2 The ID of the second AetherMind.
     */
    function bondAetherMinds(uint256 _tokenId1, uint256 _tokenId2)
        external
        whenNotPaused
        onlyAetherMindOwner(_tokenId1)
        onlyAetherMindOwner(_tokenId2)
        notStaked(_tokenId1)
        notStaked(_tokenId2)
    {
        require(_tokenId1 != _tokenId2, "Cannot bond an AetherMind to itself");
        require(aetherMindBonds[_findActiveBond(_tokenId1)].tokenId1 == 0, "AetherMind 1 is already in an active bond");
        require(aetherMindBonds[_findActiveBond(_tokenId2)].tokenId1 == 0, "AetherMind 2 is already in an active bond");

        uint256 bondId = _nextBondId++;
        aetherMindBonds[bondId] = AetherMindBond({
            tokenId1: _tokenId1,
            tokenId2: _tokenId2,
            bondDuration: 7 days, // Example: 7 days bond duration
            bondStartTime: block.timestamp,
            active: true
        });

        // Potentially, add some trait boost for bonded AetherMinds, or other effects
        // For example: aetherMindTraits[_tokenId1].aura = aetherMindTraits[_tokenId1].aura.add(10);

        emit AetherMindBonded(bondId, _tokenId1, _tokenId2, 7 days);
    }

    /**
     * @notice Breaks an existing AetherMind bond.
     * @dev Callable by the owner of either AetherMind in the bond.
     * @param _bondId The ID of the bond to break.
     */
    function unbondAetherMinds(uint256 _bondId) external whenNotPaused {
        AetherMindBond storage bond = aetherMindBonds[_bondId];
        require(bond.active, "Bond is not active");
        require(
            _ownerOf(bond.tokenId1) == msg.sender || _ownerOf(bond.tokenId2) == msg.sender,
            "Caller is not an owner of bonded AetherMinds"
        );

        bond.active = false;
        // Revert any temporary trait boosts from bonding if applicable

        emit AetherMindUnbonded(_bondId);
    }

    // Helper to find if an AetherMind is part of an active bond
    function _findActiveBond(uint256 _tokenId) internal view returns (uint256 bondId) {
        for (uint256 i = 1; i < _nextBondId; i++) { // Iterate through existing bonds
            if (aetherMindBonds[i].active && (aetherMindBonds[i].tokenId1 == _tokenId || aetherMindBonds[i].tokenId2 == _tokenId)) {
                return i;
            }
        }
        return 0; // No active bond found
    }

    // --- III. Spark Token (ERC20) & Staking ---

    /**
     * @notice Sets the address of the deployed SparkToken ERC20 contract.
     * @dev This must be called once after deployment to link the contracts.
     * @param _sparkAddress The address of the SparkToken contract.
     */
    function setSparkTokenAddress(address _sparkAddress) public onlyOwner {
        require(_sparkAddress != address(0), "Spark Token address cannot be zero");
        sparkToken = ISparkToken(_sparkAddress);
        emit SparkTokenAddressSet(_sparkAddress);
    }

    /**
     * @notice Stakes an AetherMind to earn Spark tokens over time.
     * @param _tokenId The ID of the AetherMind to stake.
     */
    function stakeAetherMindForSpark(uint256 _tokenId)
        external
        whenNotPaused
        onlyAetherMindOwner(_tokenId)
        notStaked(_tokenId)
    {
        stakedAetherMinds[_tokenId] = StakingInfo({
            startTime: block.timestamp,
            lastClaimTime: block.timestamp
        });
        // We do not transfer the NFT itself, just record its staking status.
        // It's still owned by msg.sender.
        emit AetherMindStaked(_tokenId, msg.sender);
    }

    /**
     * @notice Unstakes an AetherMind, stopping Spark accrual and claiming pending rewards.
     * @param _tokenId The ID of the AetherMind to unstake.
     */
    function unstakeAetherMind(uint256 _tokenId)
        external
        whenNotPaused
        onlyAetherMindOwner(_tokenId)
        onlyStaked(_tokenId)
    {
        uint256 rewards = getPendingSparkRewards(_tokenId);
        delete stakedAetherMinds[_tokenId]; // Remove staking info

        if (rewards > 0) {
            sparkToken.mint(msg.sender, rewards);
        }

        emit AetherMindUnstaked(_tokenId, msg.sender, rewards);
    }

    /**
     * @notice Claims accumulated Spark rewards for a staked AetherMind without unstaking.
     * @param _tokenId The ID of the staked AetherMind.
     */
    function claimStakedSparkRewards(uint256 _tokenId)
        external
        whenNotPaused
        onlyAetherMindOwner(_tokenId)
        onlyStaked(_tokenId)
    {
        uint256 rewards = getPendingSparkRewards(_tokenId);
        require(rewards > 0, "No pending rewards to claim");

        stakedAetherMinds[_tokenId].lastClaimTime = block.timestamp;
        sparkToken.mint(msg.sender, rewards);

        emit SparkRewardsClaimed(_tokenId, msg.sender, rewards);
    }

    /**
     * @notice Returns the amount of Spark rewards pending for a staked AetherMind.
     * @param _tokenId The ID of the staked AetherMind.
     * @return The amount of pending Spark rewards.
     */
    function getPendingSparkRewards(uint256 _tokenId) public view onlyStaked(_tokenId) returns (uint256) {
        StakingInfo storage info = stakedAetherMinds[_tokenId];
        uint256 timeStaked = block.timestamp.sub(info.lastClaimTime);
        return timeStaked.mul(sparkRewardPerBlockStaked).div(1 days / 100); // Assuming average 100 blocks per day for simplification, adjust for real block time.
                                                                           // Realistically, would be `timeStaked / secondsPerBlock * rewardPerBlock`
                                                                           // Simplified to `timeStaked * rewardPerBlock` for demo, consider proper time unit.
                                                                           // Or: `timeStaked.div(1 seconds) * (sparkRewardPerBlockStaked.div(86400))` -> spark per second
    }

    // --- IV. Governance ---

    /**
     * @notice Allows AetherMind/Spark holders to propose changes to protocol parameters.
     * @dev A proposer must hold a minimum amount of Spark or AetherMinds (e.g., 1 AetherMind or 1000 Spark).
     * @param _paramType The type of parameter to change (enum).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(ParameterType _paramType, uint256 _newValue) external whenNotPaused returns (uint256) {
        require(_paramType != ParameterType.None, "Invalid parameter type");
        // Example: Require 1 AetherMind or 1000 Spark to propose
        require(_balanceOf(msg.sender) >= 1 || sparkToken.balanceOf(msg.sender) >= 1000 * 10**18, "Insufficient AetherMinds or Spark to propose");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId].id = proposalId;
        proposals[proposalId].paramType = _paramType;
        proposals[proposalId].newValue = _newValue;
        proposals[proposalId].votingDeadline = block.timestamp.add(proposalVotingPeriod);
        proposals[proposalId].executed = false;

        emit ProposalCreated(proposalId, _paramType, _newValue, proposals[proposalId].votingDeadline);
        return proposalId;
    }

    /**
     * @notice Casts a vote on an active proposal.
     * @dev Voters must hold AetherMinds or Spark. Voting power could scale with holdings.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        // Example voting power: 1 vote per AetherMind owned or 1 vote per 100 Spark.
        uint256 votingPower = _balanceOf(msg.sender).add(sparkToken.balanceOf(msg.sender).div(100 * 10**18));
        require(votingPower > 0, "No voting power");

        if (_support) {
            proposal.voteCountFor = proposal.voteCountFor.add(votingPower);
        } else {
            proposal.voteCountAgainst = proposal.voteCountAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a proposal that has met quorum and passed.
     * @dev Callable by anyone after the voting deadline.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.voteCountFor.add(proposal.voteCountAgainst);
        require(totalVotes > 0, "No votes cast on this proposal");

        // Calculate total possible voting power (e.g., total supply of Spark + total AetherMinds)
        // For simplicity, let's use totalVotes for quorum calc or a fixed min.
        // A more robust DAO would query total circulating Spark/AetherMinds to calculate real quorum.
        // For this example, let's just use minimum votes cast.
        require(proposal.voteCountFor > proposal.voteCountAgainst, "Proposal did not pass");
        require(proposal.voteCountFor.mul(100).div(totalVotes) >= proposalQuorumPercentage, "Proposal did not meet quorum");

        proposal.executed = true;

        if (proposal.paramType == ParameterType.TrainingCostPerPoint) {
            trainingCostPerPoint = proposal.newValue;
        } else if (proposal.paramType == ParameterType.AttestationSparkFee) {
            attestationSparkFee = proposal.newValue;
        } else if (proposal.paramType == ParameterType.MindDuelEntryFee) {
            mindDuelEntryFee = proposal.newValue;
        } else if (proposal.paramType == ParameterType.SparkRewardPerBlockStaked) {
            sparkRewardPerBlockStaked = proposal.newValue;
        } else if (proposal.paramType == ParameterType.TraitDecayRateIntellect) {
            traitDecayRates[TRAIT_INTELLECT] = proposal.newValue;
        } else if (proposal.paramType == ParameterType.TraitDecayRateResolve) {
            traitDecayRates[TRAIT_RESOLVE] = proposal.newValue;
        } else if (proposal.paramType == ParameterType.TraitDecayRateAdaptability) {
            traitDecayRates[TRAIT_ADAPTABILITY] = proposal.newValue;
        } else if (proposal.paramType == ParameterType.TraitDecayRateAura) {
            traitDecayRates[TRAIT_AURA] = proposal.newValue;
        }
        // Add more parameters here if needed

        emit ProposalExecuted(_proposalId, proposal.paramType, proposal.newValue);
    }

    // --- V. Administrative & Utility ---

    /**
     * @notice Pauses core contract functionalities (e.g., minting, challenges).
     * @dev Callable by the contract owner. Inherited from Pausable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Callable by the contract owner. Inherited from Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the decay rate for a specific Essence Trait.
     * @dev Callable directly by the owner or via governance.
     * @param _traitIndex The index of the trait.
     * @param _newRate The new decay rate (points per day).
     */
    function setTraitDecayRate(uint8 _traitIndex, uint256 _newRate) public onlyOwner {
        require(_traitIndex < 4, "Invalid trait index");
        traitDecayRates[_traitIndex] = _newRate;
    }

    /**
     * @notice Allows withdrawal of any collected fees (e.g., challenge entry fees) to a specified address.
     * @dev Callable only by the contract owner.
     * @param _to The address to send the funds to.
     * @param _amount The amount of Spark tokens to withdraw.
     */
    function withdrawContractFees(address _to, uint256 _amount) public onlyOwner {
        require(sparkToken.balanceOf(address(this)) >= _amount, "Insufficient Spark balance in contract");
        sparkToken.transfer(_to, _amount);
    }

    // --- Internal/Utility functions ---

    /**
     * @dev ERC721 hook to update AetherMind owner mapping.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) {
            // Minting: do nothing, owner already set during mintAetherMind
        } else if (to == address(0)) {
            // Burning: remove owner from mapping
            delete aetherMindOwners[tokenId];
        } else {
            // Transfer: update owner mapping
            aetherMindOwners[tokenId] = to;
        }
    }
}
```