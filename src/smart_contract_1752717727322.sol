Here's a Solidity smart contract named `MetamorphRealm`, designed to be an advanced, creative, and trendy decentralized application. It features dynamic NFTs ("Living Assets"), an internal ERC-20 token for ecosystem interactions ("Realm Essence"), a reputation system, oracle integration for external data, and on-chain governance for protocol parameters and even individual asset trait upgrades.

It intentionally avoids direct duplication of major open-source projects by combining and extending existing concepts with unique mechanics, such as:
*   Living Assets that dynamically evolve based on time, owner reputation, *and* external oracle data.
*   An internal token (`RealmEssence`) that acts as "fuel" for NFT evolution and is earned via staking or purchased.
*   A reputation system directly influencing asset evolution.
*   The ability to "merge" two NFTs into a new one.
*   Community governance over specific *individual* NFT trait upgrades, not just general protocol parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For int256 math, uint256 operations benefit from 0.8+ default checks

/*
    MetamorphRealm: A Decentralized Autonomous Protocol for Adaptive On-Chain Ecosystems

    Outline:
    I. Core Concepts:
        1.  Living Assets (LAs): Dynamic NFTs with evolving traits based on time, external events, user interaction, and owner reputation.
        2.  Realm Essence (RE): An internal ERC-20 token, vital for LA evolution, sustainment, and reputation building.
        3.  Reputation System: On-chain score reflecting user reliability, participation, and contribution to the ecosystem.
        4.  Oracle Integration: Enables LAs to react to real-world data or complex off-chain computations.
        5.  Community Governance: Allows collective decision-making for protocol parameters and asset-specific trait upgrades.

    II. Function Summary (at least 20 functions required):

    A. Living Asset (LA) Management (ERC-721 based) - 10 Functions:
    1.  mintLivingAsset(): Mints a new Living Asset (LA), assigning initial dynamic traits.
    2.  evolveLivingAsset(uint256 tokenId): Triggers the evolution of an LA, consuming Realm Essence (RE) and leveraging owner's reputation and external data.
    3.  decayLivingAsset(uint256 tokenId): Initiates decay for an LA if it's not adequately maintained (e.g., insufficient RE or neglect).
    4.  mergeLivingAssets(uint256 tokenId1, uint256 tokenId2): Allows merging two LAs to create a new, potentially more powerful or uniquely-traited LA, consuming RE.
    5.  extractEssenceFromAsset(uint256 tokenId): Burns an LA to recover a portion of its embedded Realm Essence (RE), based on its current state and rarity.
    6.  getCurrentAssetTraits(uint256 tokenId): Retrieves the current dynamic traits and state of a specified Living Asset.
    7.  freezeAssetEvolution(uint256 tokenId): Temporarily halts the evolution and decay process for an LA, requiring an RE cost.
    8.  unfreezeAssetEvolution(uint256 tokenId): Resumes evolution and decay for a previously frozen LA.
    9.  proposeAssetTraitUpgrade(uint256 tokenId, uint256 traitId, uint256 targetValue): Allows an LA owner to propose a specific, targeted upgrade to one of their asset's traits, subject to community vote.
    10. voteOnTraitUpgrade(bytes32 proposalHash, bool support): Enables community members to vote on proposed individual asset trait upgrades.

    B. Realm Essence (RE) Management (ERC-20 based) - 5 Functions:
    11. depositForEssence(): Allows users to deposit ETH/WETH to acquire Realm Essence (RE) tokens.
    12. withdrawEssence(uint256 amount): Enables users to burn Realm Essence (RE) tokens and withdraw proportional ETH/WETH.
    13. stakeEssence(uint256 amount): Users can stake RE tokens to earn rewards and boost their reputation score.
    14. unstakeEssence(uint256 amount): Allows users to unstake their RE tokens.
    15. distributeEssenceRewards(): Callable by a privileged role (or scheduled), distributes accumulated RE rewards to stakers.

    C. Reputation System - 2 External Functions:
    16. getUserReputation(address userAddress): Retrieves the current reputation score for a specific user.
    17. boostUserReputation(address toAddress, uint256 amount): Allows a user to temporarily boost another user's reputation score (a direct transfer of points).
    (Note: `updateUserReputation` is an internal helper function).

    D. Oracle & External Data Integration - 2 Functions:
    18. updateExternalFactor(uint256 factorId, uint256 value): Callable by a designated oracle, updates specific external data points that influence LA evolution.
    19. setOracleAddress(address newOracleAddress): Sets or updates the trusted address for the external data oracle.

    E. Governance & Protocol Parameters - 5 Functions:
    20. proposeParameterChange(bytes32 paramName, uint256 newValue): Initiates a proposal to change core protocol parameters (e.g., evolution costs, decay rates).
    21. voteOnParameterChange(bytes32 proposalHash, bool support): Enables community members to vote on active protocol parameter change proposals.
    22. setEvolutionInterval(uint256 interval): Sets the minimum time interval required between successive evolutions of an LA.
    23. configureTraitDefinition(uint256 traitId, string memory name, uint256 min, uint256 max, uint256 evolutionCostPerUnit, uint256 decayRatePerUnit): Defines or updates the properties of a specific trait, including its range and RE cost for evolution/decay.
    24. claimProtocolFees(): Allows the protocol's treasury or designated governance address to claim collected fees.
*/

// --- RealmEssence Token Contract ---
// This ERC20 token acts as the primary medium of exchange and fuel within the MetamorphRealm ecosystem.
// For this example, MetamorphRealm contract will be assumed to be the owner of this token for minting/burning capabilities.
contract RealmEssence is ERC20, Ownable {
    using SafeMath for uint256; // Using SafeMath for consistency, though 0.8+ provides default checks for uint256.

    constructor() ERC20("Realm Essence", "RE") Ownable(msg.sender) {}

    /// @notice Allows the owner (expected to be MetamorphRealm contract) to mint new RE tokens.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Allows the owner (expected to be MetamorphRealm contract) to burn RE tokens from an address.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

// --- MetamorphRealm Core Contract ---
contract MetamorphRealm is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeMath for int256; // Essential for handling reputation, which can be negative

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // NFT Token ID counter
    RealmEssence public immutable RE_TOKEN; // Realm Essence token contract

    address public oracleAddress; // Address of the trusted oracle for external data

    mapping(address => int256) public userReputations; // Mapping for user reputations (can be negative)
    mapping(uint256 => uint256) public externalFactors; // factorId => value (e.g., weather, market index)

    // Living Asset structure (dynamic NFT)
    struct LivingAsset {
        uint256 birthTime; // Timestamp of minting
        uint256 lastEvolutionTime; // Timestamp of last evolution or decay check
        uint256 vitality; // A "health" or "energy" score (0-MAX_VITALITY), impacts decay/evolution
        mapping(uint256 => uint256) traits; // traitId => traitValue
        bool isFrozen; // If true, asset doesn't evolve/decay
    }
    mapping(uint256 => LivingAsset) public livingAssets;

    // Trait Definitions
    struct TraitDefinition {
        string name;
        uint256 min;
        uint256 max;
        uint256 evolutionCostPerUnit; // RE cost to increase trait value by 1 unit
        uint256 decayRatePerUnit; // Vitality loss per unit if not maintained (e.g., per BASE_EVOLUTION_INTERVAL)
    }
    mapping(uint256 => TraitDefinition) public traitDefinitions; // traitId => TraitDefinition
    uint256 public nextTraitId = 1; // Counter for new trait IDs

    // Governance Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        bytes32 proposalHash; // Unique hash of the proposal data for integrity checks
        address proposer;
        uint256 voteThreshold; // Minimum total reputation required to pass
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        ProposalState state;
        // Data for specific proposal types:
        uint256 targetTokenId; // For asset trait upgrade proposals (0 if protocol parameter change)
        uint256 targetTraitId; // For asset trait upgrade proposals
        uint256 targetTraitValue; // For asset trait upgrade proposals
        bytes32 paramName; // For protocol parameter change proposals (bytes32(0) if asset trait upgrade)
        uint256 newParamValue; // For protocol parameter change proposals
    }
    mapping(bytes32 => GovernanceProposal) public governanceProposals;
    mapping(bytes32 => mapping(address => bool)) public hasVoted; // proposalHash => voterAddress => voted

    // Protocol Parameters (configurable via governance)
    uint256 public constant MIN_REPUTATION = 0; // Minimum allowed reputation score
    uint256 public constant INITIAL_REPUTATION = 100; // Initial reputation for new users
    uint256 public constant MIN_ESSENCE_DEPOSIT = 0.01 ether; // Min ETH to deposit for RE
    uint256 public constant ESSENCE_RATE = 1000; // 1 ETH = 1000 RE
    uint256 public constant BASE_MINT_COST_RE = 1000; // Base RE cost to mint an LA
    uint256 public BASE_EVOLUTION_INTERVAL = 1 days; // Min time between evolutions (configurable)
    uint256 public constant BASE_VITALITY_DECAY_RATE = 1; // Base vitality decay per BASE_EVOLUTION_INTERVAL if no activity
    uint256 public constant FREEZE_COST_RE = 500; // RE cost to freeze an asset
    uint256 public constant MERGE_COST_RE = 2000; // RE cost to merge assets
    uint256 public constant MIN_VITALITY_FOR_EVOLUTION = 20; // Min vitality for an asset to evolve
    uint256 public constant VITALITY_PER_RE_MAINTENANCE = 1; // Vitality recovered per RE spent on maintenance
    uint256 public constant MAX_VITALITY = 100; // Max vitality score
    uint256 public constant BASE_RE_REWARD_PER_STAKE_DAY = 10; // RE rewards for staking per unit of RE per day
    uint256 public constant STAKE_REPUTATION_BOOST_PER_DAY = 1; // Reputation boost per staked RE per day
    uint256 public constant STAKE_DURATION_FOR_REWARD = 7 days; // Min duration for stake rewards
    uint256 public MIN_REPUTATION_FOR_PROPOSAL = 500; // Min reputation to create a proposal (configurable)
    uint256 public constant VOTING_PERIOD = 3 days; // Duration for voting on proposals
    uint256 public constant MIN_VITALITY_FOR_MERGE = 50; // Min vitality for merging assets
    uint256 public constant ESSENCE_WITHDRAW_FEE_BPS = 50; // 0.5% withdrawal fee (in Basis Points)

    // Staking variables
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }
    mapping(address => Stake) public stakedEssence;

    // --- Events ---
    event LivingAssetMinted(uint256 indexed tokenId, address indexed owner, uint256 birthTime);
    event LivingAssetEvolved(uint256 indexed tokenId, address indexed owner, uint256 newVitality, uint256[] traitIds, uint256[] newTraitValues);
    event LivingAssetDecayed(uint256 indexed tokenId, address indexed owner, uint256 currentVitality);
    event LivingAssetMerged(uint256 indexed newTokenId, address indexed owner, uint256 indexed mergedTokenId1, uint256 indexed mergedTokenId2);
    event EssenceExtracted(uint256 indexed tokenId, address indexed owner, uint256 extractedAmount);
    event LivingAssetFrozen(uint256 indexed tokenId, address indexed owner);
    event LivingAssetUnfrozen(uint256 indexed tokenId, address indexed owner);

    event RealmEssenceDeposited(address indexed user, uint256 ethAmount, uint256 reAmount);
    event RealmEssenceWithdrawn(address indexed user, uint256 reAmount, uint256 ethAmount);
    event RealmEssenceStaked(address indexed user, uint256 amount);
    event RealmEssenceUnstaked(address indexed user, uint256 amount);
    event EssenceRewardsDistributed(address indexed recipient, uint256 amount);

    event UserReputationUpdated(address indexed user, int256 newReputation);
    event ReputationBoosted(address indexed booster, address indexed recipient, uint256 amount);

    event ExternalFactorUpdated(uint256 indexed factorId, uint256 newValue);
    event OracleAddressSet(address indexed newOracleAddress);

    event ProposalCreated(bytes32 indexed proposalHash, address indexed proposer, uint256 deadline, ProposalState state);
    event ProposalVoted(bytes32 indexed proposalHash, address indexed voter, bool support);
    event ProposalStateChanged(bytes32 indexed proposalHash, ProposalState newState);
    event ParameterChanged(bytes32 indexed paramName, uint256 newValue);
    event TraitDefinitionConfigured(uint256 indexed traitId, string name, uint256 min, uint256 max, uint256 evolutionCostPerUnit, uint256 decayRatePerUnit);
    event ProtocolFeesClaimed(address indexed recipient, uint256 ethAmount, uint256 reAmount);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "MetamorphRealm: Not the oracle");
        _;
    }

    modifier onlyAssetOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "MetamorphRealm: Not asset owner or approved");
        _;
    }

    // --- Constructor ---
    /// @notice Constructs the MetamorphRealm contract.
    /// @param _reTokenAddress The address of the deployed RealmEssence ERC20 token.
    constructor(address _reTokenAddress) ERC721("MetamorphRealm Living Asset", "MRLA") Ownable(msg.sender) {
        RE_TOKEN = RealmEssence(_reTokenAddress);
        oracleAddress = msg.sender; // Initial oracle is deployer, can be changed by owner.

        // Configure some initial traits for Living Assets (examples)
        // Trait IDs start from 1
        _configureTrait(1, "Resilience", 1, 100, 10, 1); // Cost 10 RE/unit to evolve, decays 1 vitality/unit if neglected
        _configureTrait(2, "Adaptability", 1, 100, 15, 2);
        _configureTrait(3, "Luminosity", 1, 100, 8, 0); // No decay for this trait
    }

    // --- Internal Helpers ---

    /// @dev Internal helper to define or update trait properties.
    function _configureTrait(uint256 traitId, string memory name, uint256 min, uint256 max, uint256 evolutionCostPerUnit, uint256 decayRatePerUnit) internal {
        traitDefinitions[traitId] = TraitDefinition(name, min, max, evolutionCostPerUnit, decayRatePerUnit);
        if (traitId >= nextTraitId) { // Auto-increment nextTraitId if a new highest ID is configured
            nextTraitId = traitId.add(1);
        }
        emit TraitDefinitionConfigured(traitId, name, min, max, evolutionCostPerUnit, decayRatePerUnit);
    }

    /// @dev Internal helper to update a user's reputation score.
    function _updateUserReputation(address userAddress, int256 change) internal {
        int256 newRep = userReputations[userAddress].add(change);
        if (newRep < 0) { // Reputation cannot go below 0
            userReputations[userAddress] = 0;
        } else {
            userReputations[userAddress] = newRep;
        }
        emit UserReputationUpdated(userAddress, userReputations[userAddress]);
    }

    /// @dev Internal helper to update an asset's vitality score, clamping within 0 and MAX_VITALITY.
    function _updateAssetVitality(uint256 tokenId, int256 change) internal {
        LivingAsset storage asset = livingAssets[tokenId];
        int256 newVitality = int256(asset.vitality).add(change);
        if (newVitality < 0) {
            asset.vitality = 0;
        } else if (newVitality > int256(MAX_VITALITY)) {
            asset.vitality = MAX_VITALITY;
        } else {
            asset.vitality = uint256(newVitality);
        }
    }

    /// @dev Internal helper to check if an address is the owner or approved for an NFT.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) == spender || getApproved(tokenId) == spender || isApprovedForAll(_ownerOf(tokenId), spender);
    }

    // --- A. Living Asset (LA) Management ---

    /// @notice Mints a new Living Asset (LA), assigning initial dynamic traits.
    /// @dev Costs BASE_MINT_COST_RE in Realm Essence. Initial vitality is MAX_VITALITY.
    /// @return tokenId The ID of the newly minted Living Asset.
    function mintLivingAsset() public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        require(RE_TOKEN.transferFrom(msg.sender, address(this), BASE_MINT_COST_RE), "MetamorphRealm: RE transfer failed for mint");

        LivingAsset storage newAsset = livingAssets[tokenId];
        newAsset.birthTime = block.timestamp;
        newAsset.lastEvolutionTime = block.timestamp;
        newAsset.vitality = MAX_VITALITY;
        newAsset.isFrozen = false;

        // Initialize traits based on definitions (e.g., to min value)
        for (uint256 i = 1; i < nextTraitId; i++) { // Iterate through all defined traits
            if (traitDefinitions[i].max > 0) { // Ensure trait is properly defined
                newAsset.traits[i] = traitDefinitions[i].min;
            }
        }

        _safeMint(msg.sender, tokenId);
        _updateUserReputation(msg.sender, 50); // Small reputation boost for minting
        emit LivingAssetMinted(tokenId, msg.sender, newAsset.birthTime);
        return tokenId;
    }

    /// @notice Triggers the evolution of an LA, consuming Realm Essence (RE) and leveraging owner's reputation and external data.
    /// @dev An asset can only evolve if enough time has passed, it has sufficient vitality, and RE is paid.
    /// @param tokenId The ID of the Living Asset to evolve.
    function evolveLivingAsset(uint256 tokenId) public onlyAssetOwner(tokenId) {
        LivingAsset storage asset = livingAssets[tokenId];
        require(!asset.isFrozen, "MetamorphRealm: Asset is frozen");
        require(asset.vitality >= MIN_VITALITY_FOR_EVOLUTION, "MetamorphRealm: Asset vitality too low to evolve");
        require(block.timestamp >= asset.lastEvolutionTime.add(BASE_EVOLUTION_INTERVAL), "MetamorphRealm: Not enough time has passed since last evolution");

        address owner = _ownerOf(tokenId);
        uint256 ownerReputation = uint256(userReputations[owner]);

        uint256 totalRECost = 0;
        uint256[] memory evolvedTraitIdsTemp = new uint256[](nextTraitId); // Max possible size
        uint256[] memory evolvedTraitValuesTemp = new uint256[](nextTraitId);
        uint256 currentEvolvedCount = 0;

        for (uint256 i = 1; i < nextTraitId; i++) {
            TraitDefinition storage td = traitDefinitions[i];
            if (td.max > 0) { // Ensure trait is defined
                uint256 currentTraitValue = asset.traits[i];
                if (currentTraitValue < td.max) {
                    // Evolution logic: influenced by vitality, owner reputation, and external factors.
                    uint256 potentialIncrease = 1; // Base increase
                    potentialIncrease = potentialIncrease.add(ownerReputation.div(100)); // Reputation boost
                    potentialIncrease = potentialIncrease.add(externalFactors[i].div(10)); // External factor influence (e.g., trait 1 influenced by external factor 1)

                    uint256 actualIncrease = td.max.sub(currentTraitValue) < potentialIncrease ? td.max.sub(currentTraitValue) : potentialIncrease;
                    if (actualIncrease > 0) {
                        uint256 cost = actualIncrease.mul(td.evolutionCostPerUnit);
                        totalRECost = totalRECost.add(cost);
                        asset.traits[i] = asset.traits[i].add(actualIncrease);
                        evolvedTraitIdsTemp[currentEvolvedCount] = i;
                        evolvedTraitValuesTemp[currentEvolvedCount] = asset.traits[i];
                        currentEvolvedCount++;
                    }
                }
            }
        }

        require(totalRECost > 0, "MetamorphRealm: No traits to evolve or already maxed out.");
        require(RE_TOKEN.transferFrom(owner, address(this), totalRECost), "MetamorphRealm: RE transfer failed for evolution");

        _updateAssetVitality(tokenId, - (int256(totalRECost) / int256(VITALITY_PER_RE_MAINTENANCE))); // Small vitality cost
        asset.lastEvolutionTime = block.timestamp;
        _updateUserReputation(owner, 20); // Small reputation boost for evolving

        // Copy evolved traits to fixed-size arrays for event
        uint256[] memory finalEvolvedTraitIds = new uint256[](currentEvolvedCount);
        uint256[] memory finalEvolvedTraitValues = new uint256[](currentEvolvedCount);
        for(uint256 k=0; k<currentEvolvedCount; k++){
            finalEvolvedTraitIds[k] = evolvedTraitIdsTemp[k];
            finalEvolvedTraitValues[k] = evolvedTraitValuesTemp[k];
        }

        emit LivingAssetEvolved(tokenId, owner, asset.vitality, finalEvolvedTraitIds, finalEvolvedTraitValues);
    }

    /// @notice Initiates decay for an LA if it's not adequately maintained.
    /// @dev Applies decay based on time since last activity and trait-specific decay rates.
    /// @param tokenId The ID of the Living Asset to decay.
    function decayLivingAsset(uint256 tokenId) public onlyAssetOwner(tokenId) {
        LivingAsset storage asset = livingAssets[tokenId];
        require(!asset.isFrozen, "MetamorphRealm: Asset is frozen, cannot decay");
        
        uint256 timeSinceLastActivity = block.timestamp.sub(asset.lastEvolutionTime);
        if (timeSinceLastActivity < BASE_EVOLUTION_INTERVAL) return; // Not enough time for decay to apply

        uint256 intervalsPassed = timeSinceLastActivity.div(BASE_EVOLUTION_INTERVAL);
        uint256 totalVitalityLoss = intervalsPassed.mul(BASE_VITALITY_DECAY_RATE);

        for (uint256 i = 1; i < nextTraitId; i++) {
            TraitDefinition storage td = traitDefinitions[i];
            if (td.max > 0 && td.decayRatePerUnit > 0) { // Ensure trait is defined and has decay
                totalVitalityLoss = totalVitalityLoss.add(asset.traits[i].mul(td.decayRatePerUnit));
            }
        }
        
        _updateAssetVitality(tokenId, - (int256(totalVitalityLoss)));
        asset.lastEvolutionTime = block.timestamp; // Update last activity time after decay check

        emit LivingAssetDecayed(tokenId, _ownerOf(tokenId), asset.vitality);
    }

    /// @notice Allows merging two LAs to create a new, potentially more powerful or uniquely-traited LA.
    /// @dev Burns the two source assets and mints a new one. Traits are combined/averaged. Costs RE.
    /// @param tokenId1 The ID of the first Living Asset.
    /// @param tokenId2 The ID of the second Living Asset.
    function mergeLivingAssets(uint256 tokenId1, uint256 tokenId2) public {
        address owner = msg.sender;
        require(_isApprovedOrOwner(owner, tokenId1), "MetamorphRealm: Not owner or approved for first asset");
        require(_isApprovedOrOwner(owner, tokenId2), "MetamorphRealm: Not owner or approved for second asset");
        require(tokenId1 != tokenId2, "MetamorphRealm: Cannot merge asset with itself");

        LivingAsset storage asset1 = livingAssets[tokenId1];
        LivingAsset storage asset2 = livingAssets[tokenId2];

        require(asset1.vitality >= MIN_VITALITY_FOR_MERGE, "MetamorphRealm: First asset vitality too low for merge");
        require(asset2.vitality >= MIN_VITALITY_FOR_MERGE, "MetamorphRealm: Second asset vitality too low for merge");

        require(RE_TOKEN.transferFrom(owner, address(this), MERGE_COST_RE), "MetamorphRealm: RE transfer failed for merge");

        // Mint new token
        uint256 newId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        LivingAsset storage newAsset = livingAssets[newId];
        newAsset.birthTime = block.timestamp;
        newAsset.lastEvolutionTime = block.timestamp;
        newAsset.vitality = asset1.vitality.add(asset2.vitality).div(2); // Average vitality

        // Combine traits: Example strategy is averaging traits, ensuring bounds
        for (uint256 i = 1; i < nextTraitId; i++) {
            newAsset.traits[i] = asset1.traits[i].add(asset2.traits[i]).div(2);
            // Ensure traits stay within bounds
            if (newAsset.traits[i] > traitDefinitions[i].max) newAsset.traits[i] = traitDefinitions[i].max;
            if (newAsset.traits[i] < traitDefinitions[i].min) newAsset.traits[i] = traitDefinitions[i].min;
        }

        // Burn original assets
        _burn(tokenId1);
        _burn(tokenId2);

        _safeMint(owner, newId);
        _updateUserReputation(owner, 100); // Significant reputation boost for merging
        emit LivingAssetMerged(newId, owner, tokenId1, tokenId2);
    }

    /// @notice Burns an LA to recover a portion of its embedded Realm Essence (RE).
    /// @dev The amount recovered depends on the asset's current vitality and trait values.
    /// @param tokenId The ID of the Living Asset to extract essence from.
    function extractEssenceFromAsset(uint256 tokenId) public onlyAssetOwner(tokenId) {
        address owner = msg.sender;
        LivingAsset storage asset = livingAssets[tokenId];

        // Calculate recovery amount: Base + (vitality / MAX_VITALITY) * BASE_MINT_COST_RE * 0.5 (example)
        // Plus bonus based on trait values
        uint256 recoveredAmount = BASE_MINT_COST_RE.mul(asset.vitality).div(MAX_VITALITY).div(2); // 50% of initial cost based on vitality
        for (uint256 i = 1; i < nextTraitId; i++) {
            if (traitDefinitions[i].max > 0) {
                recoveredAmount = recoveredAmount.add(asset.traits[i].mul(traitDefinitions[i].evolutionCostPerUnit).div(4)); // 25% of invested evolution cost
            }
        }

        _burn(tokenId);
        require(RE_TOKEN.mint(owner, recoveredAmount), "MetamorphRealm: RE mint failed for extraction");
        _updateUserReputation(owner, -50); // Small reputation penalty for extraction
        emit EssenceExtracted(tokenId, owner, recoveredAmount);
    }

    /// @notice Retrieves the current dynamic traits and state of a specified Living Asset.
    /// @param tokenId The ID of the Living Asset.
    /// @return vitality The current vitality of the asset.
    /// @return isFrozen Whether the asset is currently frozen.
    /// @return traitIds An array of trait IDs.
    /// @return traitValues An array of corresponding trait values.
    function getCurrentAssetTraits(uint256 tokenId) public view returns (uint256 vitality, bool isFrozen, uint256[] memory traitIds, uint256[] memory traitValues) {
        LivingAsset storage asset = livingAssets[tokenId];
        vitality = asset.vitality;
        isFrozen = asset.isFrozen;

        uint256 definedTraitCount = nextTraitId.sub(1);
        traitIds = new uint256[](definedTraitCount);
        traitValues = new uint256[](definedTraitCount);

        for (uint256 i = 1; i <= definedTraitCount; i++) {
            traitIds[i-1] = i;
            traitValues[i-1] = asset.traits[i];
        }
    }

    /// @notice Temporarily halts the evolution and decay process for an LA.
    /// @dev Costs FREEZE_COST_RE.
    /// @param tokenId The ID of the Living Asset to freeze.
    function freezeAssetEvolution(uint256 tokenId) public onlyAssetOwner(tokenId) {
        LivingAsset storage asset = livingAssets[tokenId];
        require(!asset.isFrozen, "MetamorphRealm: Asset is already frozen");
        require(RE_TOKEN.transferFrom(msg.sender, address(this), FREEZE_COST_RE), "MetamorphRealm: RE transfer failed for freezing");
        asset.isFrozen = true;
        _updateUserReputation(msg.sender, 10); // Small reputation boost for maintaining asset
        emit LivingAssetFrozen(tokenId, msg.sender);
    }

    /// @notice Resumes evolution and decay for a previously frozen LA.
    /// @param tokenId The ID of the Living Asset to unfreeze.
    function unfreezeAssetEvolution(uint256 tokenId) public onlyAssetOwner(tokenId) {
        LivingAsset storage asset = livingAssets[tokenId];
        require(asset.isFrozen, "MetamorphRealm: Asset is not frozen");
        asset.isFrozen = false;
        asset.lastEvolutionTime = block.timestamp; // Reset timer upon unfreeze
        emit LivingAssetUnfrozen(tokenId, msg.sender);
    }

    /// @notice Allows an LA owner to propose a specific, targeted upgrade to one of their asset's traits, subject to community vote.
    /// @dev This allows for fine-grained, governance-backed evolution beyond natural processes.
    /// @param tokenId The ID of the Living Asset.
    /// @param traitId The ID of the trait to upgrade.
    /// @param targetValue The desired new value for the trait.
    function proposeAssetTraitUpgrade(uint256 tokenId, uint256 traitId, uint256 targetValue) public onlyAssetOwner(tokenId) {
        require(userReputations[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL, "MetamorphRealm: Not enough reputation to propose");
        require(traitDefinitions[traitId].max > 0, "MetamorphRealm: Trait not defined");
        require(targetValue > livingAssets[tokenId].traits[traitId], "MetamorphRealm: Target value must be higher than current trait value");
        require(targetValue <= traitDefinitions[traitId].max, "MetamorphRealm: Target value exceeds trait max");

        bytes memory proposalData = abi.encode(tokenId, traitId, targetValue); // Used for unique hash and integrity
        bytes32 proposalHash = keccak256(proposalData);

        require(governanceProposals[proposalHash].state == ProposalState.Pending, "MetamorphRealm: Proposal already exists or is active");

        governanceProposals[proposalHash] = GovernanceProposal({
            proposalHash: proposalHash,
            proposer: msg.sender,
            voteThreshold: MIN_REPUTATION_FOR_PROPOSAL.div(2), // Lower threshold for individual asset changes
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp.add(VOTING_PERIOD),
            state: ProposalState.Active,
            targetTokenId: tokenId,
            targetTraitId: traitId,
            targetTraitValue: targetValue,
            paramName: bytes32(0), // Not a param change
            newParamValue: 0 // Not a param change
        });
        emit ProposalCreated(proposalHash, msg.sender, governanceProposals[proposalHash].deadline, ProposalState.Active);
    }

    /// @notice Enables community members to vote on proposed individual asset trait upgrades.
    /// @param proposalHash The hash of the proposal.
    /// @param support True for 'for' (yes), false for 'against' (no).
    function voteOnTraitUpgrade(bytes32 proposalHash, bool support) public {
        GovernanceProposal storage proposal = governanceProposals[proposalHash];
        require(proposal.state == ProposalState.Active, "MetamorphRealm: Proposal not active");
        require(proposal.targetTokenId != 0, "MetamorphRealm: This is not a trait upgrade proposal"); // Ensure it's a trait upgrade
        require(block.timestamp <= proposal.deadline, "MetamorphRealm: Voting period ended");
        require(userReputations[msg.sender] > MIN_REPUTATION, "MetamorphRealm: Voter has no reputation");
        require(!hasVoted[proposalHash][msg.sender], "MetamorphRealm: Already voted on this proposal");

        uint256 voterReputation = uint256(userReputations[msg.sender]);

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        hasVoted[proposalHash][msg.sender] = true;
        emit ProposalVoted(proposalHash, msg.sender, support);

        _checkProposalState(proposalHash); // Check if voting period is over or sufficient votes achieved to change state
    }

    /// @dev Internal function to update proposal state and potentially execute if conditions are met.
    function _checkProposalState(bytes32 proposalHash) internal {
        GovernanceProposal storage proposal = governanceProposals[proposalHash];
        if (proposal.state != ProposalState.Active) return; // Only check active proposals

        if (block.timestamp > proposal.deadline) {
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposal.voteThreshold) {
                proposal.state = ProposalState.Succeeded;
                emit ProposalStateChanged(proposalHash, ProposalState.Succeeded);
                _executeProposal(proposalHash); // Attempt to execute if succeeded
            } else {
                proposal.state = ProposalState.Failed;
                emit ProposalStateChanged(proposalHash, ProposalState.Failed);
            }
        }
    }

    /// @dev Executes a successful proposal. Callable only internally after a proposal succeeds.
    function _executeProposal(bytes32 proposalHash) internal {
        GovernanceProposal storage proposal = governanceProposals[proposalHash];
        require(proposal.state == ProposalState.Succeeded, "MetamorphRealm: Proposal not in succeeded state");

        if (proposal.targetTokenId != 0) { // If it's an asset trait upgrade
            LivingAsset storage asset = livingAssets[proposal.targetTokenId];
            asset.traits[proposal.targetTraitId] = proposal.targetTraitValue;
            proposal.state = ProposalState.Executed;
            emit LivingAssetEvolved(proposal.targetTokenId, ownerOf(proposal.targetTokenId), asset.vitality, new uint256[](1), new uint256[](1)); // Simplified event, trait change is direct
            emit ProposalStateChanged(proposalHash, ProposalState.Executed);
        } else if (proposal.paramName != bytes32(0)) { // If it's a protocol parameter change
            // This is a simplified dispatcher for known parameters. In a real system,
            // this would involve a more generic function call mechanism (e.g., via a proxy).
            if (proposal.paramName == "BASE_EVOLUTION_INTERVAL") {
                BASE_EVOLUTION_INTERVAL = proposal.newParamValue;
            } else if (proposal.paramName == "MIN_REPUTATION_FOR_PROPOSAL") {
                MIN_REPUTATION_FOR_PROPOSAL = proposal.newParamValue;
            } else {
                // If the parameter name is not recognized for direct update
                proposal.state = ProposalState.Failed;
                emit ProposalStateChanged(proposalHash, ProposalState.Failed);
                return;
            }
            proposal.state = ProposalState.Executed;
            emit ParameterChanged(proposal.paramName, proposal.newParamValue);
            emit ProposalStateChanged(proposalHash, ProposalState.Executed);
        } else {
            proposal.state = ProposalState.Failed; // Should not happen if proposal data is consistent
            emit ProposalStateChanged(proposalHash, ProposalState.Failed);
        }
    }


    // --- B. Realm Essence (RE) Management ---

    /// @notice Allows users to deposit ETH/WETH to acquire Realm Essence (RE) tokens.
    /// @dev Exchange rate is ESSENCE_RATE (e.g., 1 ETH = 1000 RE). Requires a minimum deposit.
    function depositForEssence() public payable {
        require(msg.value >= MIN_ESSENCE_DEPOSIT, "MetamorphRealm: Minimum deposit not met");
        uint256 reAmount = msg.value.mul(ESSENCE_RATE);
        require(RE_TOKEN.mint(msg.sender, reAmount), "MetamorphRealm: RE minting failed");
        _updateUserReputation(msg.sender, 10); // Small reputation boost for contributing liquidity
        emit RealmEssenceDeposited(msg.sender, msg.value, reAmount);
    }

    /// @notice Enables users to burn Realm Essence (RE) tokens and withdraw proportional ETH/WETH.
    /// @dev A small fee (ESSENCE_WITHDRAW_FEE_BPS) is taken, which goes to the protocol treasury.
    /// @param amount The amount of RE to burn.
    function withdrawEssence(uint256 amount) public {
        require(RE_TOKEN.balanceOf(msg.sender) >= amount, "MetamorphRealm: Insufficient RE balance");
        uint256 ethAmount = amount.div(ESSENCE_RATE);
        uint256 fee = ethAmount.mul(ESSENCE_WITHDRAW_FEE_BPS).div(10000); // 10000 for basis points (1%)
        uint256 actualEthAmount = ethAmount.sub(fee);

        require(RE_TOKEN.burn(msg.sender, amount), "MetamorphRealm: RE burning failed");
        payable(msg.sender).transfer(actualEthAmount);
        // Fees remain in this contract's ETH balance and can be claimed by owner/governance

        _updateUserReputation(msg.sender, -5); // Small reputation penalty for withdrawing
        emit RealmEssenceWithdrawn(msg.sender, amount, actualEthAmount);
    }

    /// @notice Users can stake RE tokens to earn rewards and boost their reputation score.
    /// @param amount The amount of RE to stake.
    function stakeEssence(uint256 amount) public {
        require(amount > 0, "MetamorphRealm: Stake amount must be greater than zero");
        require(RE_TOKEN.transferFrom(msg.sender, address(this), amount), "MetamorphRealm: RE transfer failed for staking");

        if (stakedEssence[msg.sender].amount > 0) {
            // Process any existing rewards/reputation from previous stake before adding new stake
            distributeEssenceRewards();
        }

        stakedEssence[msg.sender].amount = stakedEssence[msg.sender].amount.add(amount);
        stakedEssence[msg.sender].startTime = block.timestamp; // Reset start time for new total stake

        _updateUserReputation(msg.sender, 50); // Initial reputation boost for staking
        emit RealmEssenceStaked(msg.sender, amount);
    }

    /// @notice Allows users to unstake their RE tokens.
    /// @param amount The amount of RE to unstake.
    function unstakeEssence(uint256 amount) public {
        require(stakedEssence[msg.sender].amount >= amount, "MetamorphRealm: Insufficient staked RE");

        // Distribute rewards before unstaking
        distributeEssenceRewards();

        stakedEssence[msg.sender].amount = stakedEssence[msg.sender].amount.sub(amount);
        require(RE_TOKEN.transfer(msg.sender, amount), "MetamorphRealm: RE transfer failed for unstaking");
        
        if (stakedEssence[msg.sender].amount == 0) {
            stakedEssence[msg.sender].startTime = 0; // Reset if fully unstaked
        } else {
            stakedEssence[msg.sender].startTime = block.timestamp; // Update start time for remaining stake
        }

        _updateUserReputation(msg.sender, -20); // Small reputation penalty for unstaking
        emit RealmEssenceUnstaked(msg.sender, amount);
    }

    /// @notice Distributes accumulated RE rewards to stakers. Callable by any staker or owner to trigger.
    /// @dev Calculates rewards based on staked amount and duration. The contract must be capable of minting RE.
    function distributeEssenceRewards() public {
        Stake storage userStake = stakedEssence[msg.sender];
        if (userStake.amount == 0 || userStake.startTime == 0) return;

        uint256 eligibleDuration = block.timestamp.sub(userStake.startTime);
        if (eligibleDuration < STAKE_DURATION_FOR_REWARD) return; // Wait until eligible duration passes

        uint256 daysStaked = eligibleDuration.div(1 days);
        if (daysStaked == 0) return; // Ensure at least one full day has passed for rewards

        uint256 rewards = userStake.amount.mul(BASE_RE_REWARD_PER_STAKE_DAY).mul(daysStaked);
        
        require(RE_TOKEN.mint(msg.sender, rewards), "MetamorphRealm: Failed to mint RE rewards");

        _updateUserReputation(msg.sender, int256(userStake.amount.mul(STAKE_REPUTATION_BOOST_PER_DAY).mul(daysStaked)));

        userStake.startTime = block.timestamp; // Reset start time for future calculations
        emit EssenceRewardsDistributed(msg.sender, rewards);
    }

    // --- C. Reputation System ---

    /// @notice Retrieves the current reputation score for a specific user.
    /// @param userAddress The address of the user.
    /// @return The current reputation score.
    function getUserReputation(address userAddress) public view returns (int256) {
        return userReputations[userAddress];
    }

    /// @notice Allows a user to temporarily boost another user's reputation score.
    /// @dev This is a direct transfer of reputation points.
    /// @param toAddress The address to boost.
    /// @param amount The amount of reputation to transfer.
    function boostUserReputation(address toAddress, uint256 amount) public {
        require(userReputations[msg.sender] >= int256(amount), "MetamorphRealm: Insufficient reputation to boost another user");
        require(amount > 0, "MetamorphRealm: Boost amount must be positive");
        require(msg.sender != toAddress, "MetamorphRealm: Cannot boost your own reputation directly via this function");
        
        _updateUserReputation(msg.sender, - int256(amount)); // Deduct from sender
        _updateUserReputation(toAddress, int256(amount));   // Add to recipient
        
        emit ReputationBoosted(msg.sender, toAddress, amount);
    }

    // --- D. Oracle & External Data Integration ---

    /// @notice Callable by a designated oracle, updates specific external data points that influence LA evolution.
    /// @param factorId An identifier for the external factor (e.g., 1 for "global energy", 2 for "market volatility").
    /// @param value The new value for the external factor.
    function updateExternalFactor(uint256 factorId, uint256 value) public onlyOracle {
        externalFactors[factorId] = value;
        emit ExternalFactorUpdated(factorId, value);
    }

    /// @notice Sets or updates the trusted address for the external data oracle.
    /// @dev Only the contract owner can call this.
    /// @param newOracleAddress The address of the new oracle.
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        require(newOracleAddress != address(0), "MetamorphRealm: Oracle address cannot be zero");
        oracleAddress = newOracleAddress;
        emit OracleAddressSet(newOracleAddress);
    }

    // --- E. Governance & Protocol Parameters ---

    /// @notice Initiates a proposal to change core protocol parameters.
    /// @dev Requires a minimum reputation.
    /// @param paramName A string identifier for the parameter (e.g., "BASE_EVOLUTION_INTERVAL").
    /// @param newValue The proposed new value for the parameter.
    function proposeParameterChange(bytes32 paramName, uint256 newValue) public {
        require(userReputations[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL, "MetamorphRealm: Not enough reputation to propose");
        require(paramName != bytes32(0), "MetamorphRealm: Parameter name cannot be empty");

        bytes memory proposalData = abi.encode(paramName, newValue);
        bytes32 proposalHash = keccak256(proposalData);

        require(governanceProposals[proposalHash].state == ProposalState.Pending, "MetamorphRealm: Proposal already exists or is active");

        governanceProposals[proposalHash] = GovernanceProposal({
            proposalHash: proposalHash,
            proposer: msg.sender,
            voteThreshold: MIN_REPUTATION_FOR_PROPOSAL.mul(2), // Higher threshold for protocol changes
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp.add(VOTING_PERIOD),
            state: ProposalState.Active,
            targetTokenId: 0, // Not an asset trait upgrade
            targetTraitId: 0,
            targetTraitValue: 0,
            paramName: paramName,
            newParamValue: newValue
        });
        emit ProposalCreated(proposalHash, msg.sender, governanceProposals[proposalHash].deadline, ProposalState.Active);
    }

    /// @notice Enables community members to vote on active protocol parameter change proposals.
    /// @param proposalHash The hash of the proposal.
    /// @param support True for 'for', false for 'against'.
    function voteOnParameterChange(bytes32 proposalHash, bool support) public {
        GovernanceProposal storage proposal = governanceProposals[proposalHash];
        require(proposal.state == ProposalState.Active, "MetamorphRealm: Proposal not active");
        require(proposal.targetTokenId == 0 && proposal.paramName != bytes32(0), "MetamorphRealm: Not a parameter change proposal"); // Ensure it's a param change proposal
        require(block.timestamp <= proposal.deadline, "MetamorphRealm: Voting period ended");
        require(userReputations[msg.sender] > MIN_REPUTATION, "MetamorphRealm: Voter has no reputation");
        require(!hasVoted[proposalHash][msg.sender], "MetamorphRealm: Already voted on this proposal");

        uint256 voterReputation = uint256(userReputations[msg.sender]);

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        hasVoted[proposalHash][msg.sender] = true;
        emit ProposalVoted(proposalHash, msg.sender, support);

        _checkProposalState(proposalHash); // Check if voting period is over or sufficient votes achieved
    }

    /// @notice Sets the minimum time interval required between successive evolutions of an LA.
    /// @dev Can only be called by the contract owner or via governance.
    /// @param interval The new interval in seconds.
    function setEvolutionInterval(uint256 interval) public onlyOwner {
        require(interval > 0, "MetamorphRealm: Interval must be positive");
        BASE_EVOLUTION_INTERVAL = interval;
        emit ParameterChanged("BASE_EVOLUTION_INTERVAL", interval);
    }

    /// @notice Defines or updates the properties of a specific trait, including its range and RE cost for evolution/decay.
    /// @dev Can only be called by the contract owner or via governance.
    /// @param traitId The ID of the trait. If 0, a new ID is assigned.
    /// @param name The name of the trait.
    /// @param min The minimum value for the trait.
    /// @param max The maximum value for the trait.
    /// @param evolutionCostPerUnit The RE cost to increase trait value by 1 unit.
    /// @param decayRatePerUnit The vitality loss per unit if not maintained.
    function configureTraitDefinition(uint256 traitId, string memory name, uint256 min, uint256 max, uint256 evolutionCostPerUnit, uint256 decayRatePerUnit) public onlyOwner {
        uint256 actualTraitId = traitId;
        if (actualTraitId == 0) {
            actualTraitId = nextTraitId;
        } else {
            // If updating an existing trait, ensure it exists
            require(traitDefinitions[actualTraitId].max > 0 || actualTraitId < nextTraitId, "MetamorphRealm: Trait ID does not exist for update");
        }
        _configureTrait(actualTraitId, name, min, max, evolutionCostPerUnit, decayRatePerUnit);
    }

    /// @notice Allows the protocol's treasury or designated governance address to claim collected fees.
    /// @dev Fees include ETH from withdrawal fees and RE from asset minting/merging.
    function claimProtocolFees() public onlyOwner {
        uint256 balanceETH = address(this).balance;
        uint256 balanceRE = RE_TOKEN.balanceOf(address(this));

        if (balanceETH > 0) {
            payable(owner()).transfer(balanceETH);
        }
        if (balanceRE > 0) {
            require(RE_TOKEN.transfer(owner(), balanceRE), "MetamorphRealm: RE fee transfer failed");
        }
        // Emit a combined event
        if (balanceETH > 0 || balanceRE > 0) {
            emit ProtocolFeesClaimed(owner(), balanceETH, balanceRE);
        }
    }
}
```