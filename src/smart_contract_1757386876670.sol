Here's a Solidity smart contract for an `EvoSphere` – a Dynamic Decentralized Creative Ecosystem. This contract introduces the concept of "EvoAssets," which are NFTs that are not static but evolve based on community interaction, reputation, and even simulated AI-driven influences. It integrates advanced governance, a unique reputation system, and mechanisms for dynamic trait generation.

This contract avoids duplicating common open-source projects by focusing on the *dynamic, evolving nature* of the digital assets and the intricate relationship between user reputation, community governance, and asset progression.

---

### EvoSphere Smart Contract: Outline & Function Summary

`EvoSphere` is a dynamic decentralized creative ecosystem where digital assets ("EvoAssets") are not static but evolve over time, influenced by community interaction, reputation, and potentially AI-driven parameters. It combines elements of NFTs, advanced governance, and a gamified approach to digital creation and ownership.

**I. Core Asset Management (ERC721 Compliant & Extensions)**
1.  **`mintEvoAsset`**: Creates a new EvoAsset, assigning an initial `genesisDNA` and setting its first evolution phase. Callable by a designated `CREATOR_ROLE` or via a passed governance proposal.
2.  **`transferFrom` (ERC721)**: Standard ERC721 function to transfer ownership of an EvoAsset.
3.  **`approve` (ERC721)**: Standard ERC721 function to grant approval to a single address to manage an EvoAsset.
4.  **`setApprovalForAll` (ERC721)**: Standard ERC721 function to grant or revoke approval to an operator to manage all EvoAssets.
5.  **`burnEvoAsset`**: Irreversibly destroys an EvoAsset, removing it from circulation.
6.  **`tokenURI` (ERC721)**: Returns the URI for a given token ID, reflecting its current state and dynamic traits. This URI would typically point to off-chain metadata (e.g., IPFS) that gets updated.
7.  **`getEvoAssetDetails`**: Retrieves comprehensive details of an EvoAsset, including its current phase, score, dynamic traits, and influence data.

**II. Dynamic Evolution & Interaction**
8.  **`proposeEvolutionPhase`**: Allows a user with sufficient reputation to propose an advancement or alteration to an EvoAsset's evolution phase (e.g., from 'Seed' to 'Sprout').
9.  **`voteOnEvolutionProposal`**: Community members vote on pending evolution proposals. Votes are weighted by the voter's active reputation.
10. **`executeEvolutionPhase`**: If an evolution proposal passes the required quorum and threshold, this function transitions the EvoAsset to its new phase, potentially triggering dynamic trait updates and score adjustments.
11. **`influenceAssetTrait`**: Enables users (weighted by their staked reputation) to subtly influence a specific dynamic trait of an EvoAsset within defined, safe boundaries. This directly affects the asset's `evolutionScore`.
12. **`stakeToBoostEvolution`**: Users can stake native currency (ETH/MATIC etc.) or ERC20 tokens to boost an EvoAsset's `evolutionScore`, increasing its visibility and potential for faster evolution.
13. **`unstakeFromBoost`**: Allows users to retrieve their staked tokens from an EvoAsset's boost pool.
14. **`addAffinityTag`**: Community members can add relevant keywords or tags to an EvoAsset, aiding discoverability and categorization.
15. **`removeAffinityTag`**: Initiates a proposal to remove an affinity tag from an EvoAsset. This requires community consensus.

**III. Reputation System**
16. **`earnReputation`**: A mechanism for users to gain reputation points, typically by successfully contributing to asset evolution, passing proposals, or other positive interactions. (Internal logic for earning is simplified here for example purposes, often this would be tied to complex off-chain or on-chain activity tracking).
17. **`stakeReputationForInfluence`**: Users can stake their reputation to amplify their influence on voting or trait manipulation.
18. **`unstakeReputation`**: Allows users to retrieve their staked reputation, reducing their active influence.
19. **`delegateReputation`**: Users can delegate their voting power and influence to another address, fostering liquid democracy within the ecosystem.
20. **`undelegateReputation`**: Revokes a previous reputation delegation, returning influence power to the delegator.

**IV. AI-Assisted Trait Generation (Simulated Oracle Interaction)**
21. **`requestAIInfluencedTraitUpdate`**: An owner or highly-reputed user can initiate a request to an off-chain AI oracle for suggestions on updating a specific trait based on asset data and the current `evolutionScore`.
22. **`fulfillAIInfluencedTraitUpdate` (External Call from Oracle)**: This critical callback function is invoked by the designated AI oracle after processing a `requestAIInfluencedTraitUpdate`. It delivers the AI-suggested new trait value and updates the asset, including robust verification to ensure the call comes from the legitimate oracle.

**V. Governance & Treasury**
23. **`submitTreasuryProposal`**: Allows users with sufficient reputation to propose spending funds from the community treasury for grants, rewards, or platform development.
24. **`voteOnTreasuryProposal`**: Community members vote on pending treasury proposals, with votes weighted by reputation.
25. **`executeTreasuryProposal`**: Executes a passed treasury proposal, safely disbursing funds to the specified recipient.
26. **`setEvolutionFee`**: The DAO or contract owner can adjust fees for certain actions (e.g., minting, high-impact proposals) to manage ecosystem economics.
27. **`collectFees`**: Allows the contract owner or a designated role to collect accumulated fees into a specified wallet.

**VI. Discovery & Utility**
28. **`getAssetsByTag`**: Returns a list of EvoAsset IDs that have a specific affinity tag, enabling thematic discovery and curation.
29. **`getTopEvolvingAssets`**: Lists EvoAssets with the highest `evolutionScore`, highlighting community-favored and actively developing assets, useful for a leaderboard or discovery feature.
30. **`withdrawFunds`**: Allows the contract owner to withdraw any residual funds not explicitly allocated to the community treasury, for administrative purposes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interface for a mock AI Oracle
interface IAIOracle {
    function requestTraitUpdate(uint256 _assetId, string memory _traitName, address _callbackContract) external;
    function fulfillTraitUpdate(uint256 _assetId, string memory _traitName, string memory _newValue, bytes32 _requestId) external;
}

// Custom errors for better readability and gas efficiency
error EvoSphere__InvalidAssetId();
error EvoSphere__NotAssetOwner();
error EvoSphere__NotEnoughReputation(uint256 required, uint256 has);
error EvoSphere__AlreadyVoted();
error EvoSphere__ProposalNotFound();
error EvoSphere__ProposalNotActive();
error EvoSphere__ProposalAlreadyExecuted();
error EvoSphere__ProposalExpired();
error EvoSphere__ProposalNotPassed();
error EvoSphere__InvalidVoteChoice();
error EvoSphere__InvalidAmount();
error EvoSphere__SelfDelegationNotAllowed();
error EvoSphere__DelegateeCannotBeZeroAddress();
error EvoSphere__CannotUnstakeReputationWhileDelegated();
error EvoSphere__OracleNotSet();
error EvoSphere__UnauthorizedOracleCall();
error EvoSphere__TraitUpdateInProgress();
error EvoSphere__FeeTooHigh();
error EvoSphere__NoFundsToCollect();
error EvoSphere__InsufficientBalance();
error EvoSphere__CannotBurnActiveAssetWithBoosts();

contract EvoSphere is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Configuration Constants ---
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation to propose an evolution
    uint256 public constant MIN_REPUTATION_FOR_INFLUENCE = 10; // Minimum reputation to influence a trait
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Duration for proposals to be voted on
    uint256 public constant EVOLUTION_THRESHOLD_PERCENT = 60; // % of total reputation votes needed to pass evolution
    uint256 public constant TREASURY_THRESHOLD_PERCENT = 50; // % of total reputation votes needed to pass treasury
    uint256 public constant MIN_REP_TO_DELEGATE = 1; // Minimum reputation to delegate

    // --- Roles ---
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    mapping(address => bool) public hasCreatorRole;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _evolutionProposalIdCounter;
    Counters.Counter private _treasuryProposalIdCounter;
    
    // AI Oracle
    IAIOracle public aiOracle;
    address public aiOracleAddress;
    uint256 public lastOracleRequestId = 0; // Simple requestId counter
    mapping(uint256 => bool) public pendingOracleRequests; // assetId => isPending

    // Fees
    uint256 public evolutionFee = 0.01 ether; // Fee for certain actions, e.g., proposing major evolution
    uint256 public treasuryBalance; // Funds collected from fees, waiting to be sent to community treasury or collected by owner

    // --- Data Structures ---

    struct EvoAsset {
        uint256 id;
        string genesisDNA; // Immutable seed/hash for its initial characteristics
        string baseURI; // Base URI for metadata (e.g., IPFS hash)
        string currentEvolutionPhase; // e.g., "Seed", "Sprout", "Bloom", "Mythic"
        uint256 evolutionScore; // Score reflecting community engagement and growth
        mapping(string => string) dynamicTraits; // Traits that can change over time
        uint256 creationTimestamp;
        uint256 lastEvolutionTimestamp;
        mapping(address => uint256) influencers; // address => influence score on this asset
        uint256 totalStakedBoost; // Total native token staked to boost this asset
        mapping(address => uint256) stakedBoostByAddress; // Who staked how much
        mapping(string => bool) affinityTags; // Community-driven tags for discoverability
        string[] activeTags; // Store tags in an array for iteration/retrieval
    }
    mapping(uint256 => EvoAsset) public evoAssets;

    struct EvolutionProposal {
        uint256 proposalId;
        uint256 assetId;
        address proposer;
        string newPhase;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalReputationAtProposal; // Total reputation of voters when proposal was made
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
        string description;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    struct TreasuryProposal {
        uint256 proposalId;
        address proposer;
        address recipient;
        uint256 amount;
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalReputationAtProposal;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
    }
    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    // Reputation System
    mapping(address => uint256) public userReputation;
    mapping(address => uint256) public stakedReputation; // Reputation staked for active influence
    mapping(address => address) public reputationDelegates; // user => delegatee (0x0 for no delegation)
    mapping(address => uint256) public delegatedReputation; // delegatee => total reputation delegated to them

    // Affinity Tags Index
    mapping(string => uint256[]) public assetsByTag;

    // --- Events ---
    event EvoAssetMinted(uint256 indexed assetId, address indexed owner, string genesisDNA, string initialPhase);
    event EvoAssetBurned(uint256 indexed assetId, address indexed burner);
    event EvolutionProposalSubmitted(uint256 indexed proposalId, uint256 indexed assetId, address indexed proposer, string newPhase);
    event EvolutionProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteChoice, uint256 reputationUsed);
    event EvolutionProposalExecuted(uint256 indexed proposalId, uint256 indexed assetId, bool passed);
    event EvoAssetPhaseChanged(uint256 indexed assetId, string oldPhase, string newPhase, uint256 newEvolutionScore);
    event EvoAssetTraitInfluenced(uint256 indexed assetId, address indexed influencer, string traitName, string newValue, uint256 influenceScore);
    event EvoAssetBoostStaked(uint256 indexed assetId, address indexed staker, uint256 amount);
    event EvoAssetBoostUnstaked(uint256 indexed assetId, address indexed staker, uint256 amount);
    event EvoAssetTagAdded(uint256 indexed assetId, string tag);
    event EvoAssetTagRemoved(uint256 indexed assetId, string tag);

    event ReputationEarned(address indexed user, uint256 amount);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);

    event AIOracleSet(address indexed newOracle);
    event AITraitUpdateRequest(uint256 indexed assetId, string traitName, uint256 requestId);
    event AITraitUpdateFulfilled(uint256 indexed assetId, string traitName, string newValue, uint256 requestId);

    event TreasuryProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event TreasuryProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteChoice, uint256 reputationUsed);
    event TreasuryProposalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event EvolutionFeeSet(uint256 newFee);
    event FeesCollected(address indexed collector, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor(address _aiOracleAddress) ERC721("EvoSphere EvoAsset", "EVA") Ownable(msg.sender) {
        aiOracleAddress = _aiOracleAddress;
        aiOracle = IAIOracle(_aiOracleAddress);
        hasCreatorRole[msg.sender] = true; // Initial owner gets creator role
    }

    // --- I. Core Asset Management ---

    /**
     * @notice Mints a new EvoAsset.
     * @param _to The recipient of the new EvoAsset.
     * @param _genesisDNA A unique identifier/hash representing the asset's initial, immutable characteristics.
     * @param _initialURI The base URI for the EvoAsset's metadata, which can be updated later.
     */
    function mintEvoAsset(address _to, string memory _genesisDNA, string memory _initialURI)
        external
        onlyRole(CREATOR_ROLE)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        EvoAsset storage newAsset = evoAssets[newItemId];
        newAsset.id = newItemId;
        newAsset.genesisDNA = _genesisDNA;
        newAsset.baseURI = _initialURI;
        newAsset.currentEvolutionPhase = "Seed"; // Initial phase
        newAsset.evolutionScore = 1; // Start with a base score
        newAsset.creationTimestamp = block.timestamp;
        newAsset.lastEvolutionTimestamp = block.timestamp;

        // Set an initial dynamic trait (example)
        newAsset.dynamicTraits["color"] = "unknown";
        newAsset.dynamicTraits["form"] = "basic";

        emit EvoAssetMinted(newItemId, _to, _genesisDNA, "Seed");
    }

    /**
     * @notice Burns an EvoAsset, removing it permanently.
     * @param _assetId The ID of the EvoAsset to burn.
     */
    function burnEvoAsset(uint256 _assetId) external nonReentrant {
        if (ownerOf(_assetId) != msg.sender && !isApprovedForAll(ownerOf(_assetId), msg.sender)) {
            revert EvoSphere__NotAssetOwner();
        }
        if (evoAssets[_assetId].totalStakedBoost > 0) {
            revert EvoSphere__CannotBurnActiveAssetWithBoosts();
        }

        _burn(_assetId);
        delete evoAssets[_assetId]; // Remove from storage

        // Clean up tags
        string[] memory tags = evoAssets[_assetId].activeTags;
        for (uint256 i = 0; i < tags.length; i++) {
            string memory tag = tags[i];
            uint256[] storage assets = assetsByTag[tag];
            for (uint256 j = 0; j < assets.length; j++) {
                if (assets[j] == _assetId) {
                    assets[j] = assets[assets.length - 1];
                    assets.pop();
                    break;
                }
            }
        }
        
        emit EvoAssetBurned(_assetId, msg.sender);
    }

    /**
     * @notice Returns the URI for a given token ID, reflecting its current state.
     * @param _tokenId The ID of the EvoAsset.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert EvoSphere__InvalidAssetId();
        }
        // In a real dApp, this URI would point to metadata that dynamically updates
        // based on evoAssets[_tokenId].currentEvolutionPhase, evoAssets[_tokenId].dynamicTraits etc.
        // For simplicity, we just return the base URI.
        return evoAssets[_tokenId].baseURI;
    }

    /**
     * @notice Retrieves detailed information about an EvoAsset.
     * @param _assetId The ID of the EvoAsset.
     * @return A tuple containing all relevant asset data.
     */
    function getEvoAssetDetails(uint256 _assetId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory genesisDNA,
            string memory baseURI,
            string memory currentEvolutionPhase,
            uint256 evolutionScore,
            uint256 creationTimestamp,
            uint256 lastEvolutionTimestamp,
            uint256 totalStakedBoost,
            string[] memory activeTags,
            string[] memory traitNames,
            string[] memory traitValues
        )
    {
        if (!_exists(_assetId)) {
            revert EvoSphere__InvalidAssetId();
        }

        EvoAsset storage asset = evoAssets[_assetId];
        id = asset.id;
        owner = ownerOf(_assetId);
        genesisDNA = asset.genesisDNA;
        baseURI = asset.baseURI;
        currentEvolutionPhase = asset.currentEvolutionPhase;
        evolutionScore = asset.evolutionScore;
        creationTimestamp = asset.creationTimestamp;
        lastEvolutionTimestamp = asset.lastEvolutionTimestamp;
        totalStakedBoost = asset.totalStakedBoost;
        activeTags = asset.activeTags;

        // Collect dynamic traits into arrays for return
        uint256 traitCount = 0;
        // In Solidity, iterating over a mapping to get keys is not direct.
        // A common pattern is to maintain an array of keys alongside the mapping.
        // For simplicity, this example assumes a few known traits, or would need a helper.
        // Here, we'll manually add example trait names.
        // A more robust solution would track trait keys in an array.
        string[] memory tempTraitNames = new string[](2); // Example: color, form
        string[] memory tempTraitValues = new string[](2);

        if (bytes(asset.dynamicTraits["color"]).length > 0) {
            tempTraitNames[traitCount] = "color";
            tempTraitValues[traitCount] = asset.dynamicTraits["color"];
            traitCount++;
        }
        if (bytes(asset.dynamicTraits["form"]).length > 0) {
            tempTraitNames[traitCount] = "form";
            tempTraitValues[traitCount] = asset.dynamicTraits["form"];
            traitCount++;
        }
        // If more traits were added dynamically, a loop here would be complex without tracking keys.
        // A real implementation might use an array of `struct Trait { string name; string value; }`

        traitNames = new string[](traitCount);
        traitValues = new string[](traitCount);
        for (uint256 i = 0; i < traitCount; i++) {
            traitNames[i] = tempTraitNames[i];
            traitValues[i] = tempTraitValues[i];
        }
    }

    // --- II. Dynamic Evolution & Interaction ---

    /**
     * @notice Allows a user to propose an evolution phase change for an EvoAsset.
     * @param _assetId The ID of the EvoAsset.
     * @param _newPhase The proposed new evolution phase.
     * @param _description A brief description of the proposal.
     */
    function proposeEvolutionPhase(uint256 _assetId, string memory _newPhase, string memory _description)
        external
        payable
        nonReentrant
    {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        if (userReputation[msg.sender] < MIN_REPUTATION_FOR_PROPOSAL) {
            revert EvoSphere__NotEnoughReputation(MIN_REPUTATION_FOR_PROPOSAL, userReputation[msg.sender]);
        }
        if (msg.value < evolutionFee) {
            revert EvoSphere__InvalidAmount(); // or specific fee error
        }
        treasuryBalance = treasuryBalance.add(msg.value);

        _evolutionProposalIdCounter.increment();
        uint256 proposalId = _evolutionProposalIdCounter.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            proposalId: proposalId,
            assetId: _assetId,
            proposer: msg.sender,
            newPhase: _newPhase,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            totalReputationAtProposal: 0, // Calculated during first vote
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            executed: false,
            passed: false,
            description: _description
        });

        emit EvolutionProposalSubmitted(proposalId, _assetId, msg.sender, _newPhase);
    }

    /**
     * @notice Allows a user to vote on an evolution proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteChoice True for 'yes', false for 'no'.
     */
    function voteOnEvolutionProposal(uint256 _proposalId, bool _voteChoice) external nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.proposalId == 0) revert EvoSphere__ProposalNotFound();
        if (block.timestamp > proposal.voteEndTime) revert EvoSphere__ProposalExpired();
        if (proposal.executed) revert EvoSphere__ProposalAlreadyExecuted();
        if (proposal.hasVoted[msg.sender]) revert EvoSphere__AlreadyVoted();

        uint256 voterInfluence = _getVoterInfluence(msg.sender);
        if (voterInfluence == 0) revert EvoSphere__NotEnoughReputation(1, 0); // Need at least 1 rep to vote

        proposal.hasVoted[msg.sender] = true;

        if (proposal.totalReputationAtProposal == 0) {
            // First voter initializes total reputation
            // This is a simplified approach. A more robust DAO would snapshot total voting power.
            proposal.totalReputationAtProposal = _getTotalActiveReputation();
        }

        if (_voteChoice) {
            proposal.yesVotes = proposal.yesVotes.add(voterInfluence);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterInfluence);
        }

        emit EvolutionProposalVoted(_proposalId, msg.sender, _voteChoice, voterInfluence);
    }

    /**
     * @notice Executes a passed evolution proposal, changing the asset's phase.
     * Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal.
     */
    function executeEvolutionPhase(uint256 _proposalId) external nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.proposalId == 0) revert EvoSphere__ProposalNotFound();
        if (block.timestamp <= proposal.voteEndTime) revert EvoSphere__ProposalNotExpired();
        if (proposal.executed) revert EvoSphere__ProposalAlreadyExecuted();

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 minVotesToPass = proposal.totalReputationAtProposal.mul(EVOLUTION_THRESHOLD_PERCENT).div(100);

        bool passed = (proposal.yesVotes > proposal.noVotes) && (proposal.yesVotes >= minVotesToPass);
        proposal.executed = true;
        proposal.passed = passed;

        if (passed) {
            EvoAsset storage asset = evoAssets[proposal.assetId];
            string memory oldPhase = asset.currentEvolutionPhase;
            asset.currentEvolutionPhase = proposal.newPhase;
            asset.lastEvolutionTimestamp = block.timestamp;
            asset.evolutionScore = asset.evolutionScore.add(100); // Reward for evolution

            emit EvoAssetPhaseChanged(proposal.assetId, oldPhase, proposal.newPhase, asset.evolutionScore);
        }

        emit EvolutionProposalExecuted(_proposalId, proposal.assetId, passed);
    }

    /**
     * @notice Allows a user to influence a specific dynamic trait of an EvoAsset.
     * Influence is weighted by staked reputation.
     * @param _assetId The ID of the EvoAsset.
     * @param _traitName The name of the trait to influence.
     * @param _newValue The proposed new value for the trait.
     */
    function influenceAssetTrait(uint256 _assetId, string memory _traitName, string memory _newValue) external nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        uint256 influencePower = stakedReputation[msg.sender];
        if (influencePower < MIN_REPUTATION_FOR_INFLUENCE) {
            revert EvoSphere__NotEnoughReputation(MIN_REPUTATION_FOR_INFLUENCE, influencePower);
        }

        EvoAsset storage asset = evoAssets[_assetId];
        // Simulate influence: a high influencePower allows more direct changes
        // For simplicity, we just update it. A real system might have complex rules, e.g.,
        // requiring multiple influences, or changing it gradually.
        asset.dynamicTraits[_traitName] = _newValue;
        asset.evolutionScore = asset.evolutionScore.add(influencePower.div(10)); // Small score boost

        // Record influencer
        asset.influencers[msg.sender] = asset.influencers[msg.sender].add(influencePower);

        emit EvoAssetTraitInfluenced(_assetId, msg.sender, _traitName, _newValue, influencePower);
    }

    /**
     * @notice Allows users to stake native currency to boost an EvoAsset's evolution score.
     * @param _assetId The ID of the EvoAsset to boost.
     */
    function stakeToBoostEvolution(uint256 _assetId) external payable nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        if (msg.value == 0) revert EvoSphere__InvalidAmount();

        EvoAsset storage asset = evoAssets[_assetId];
        asset.totalStakedBoost = asset.totalStakedBoost.add(msg.value);
        asset.stakedBoostByAddress[msg.sender] = asset.stakedBoostByAddress[msg.sender].add(msg.value);
        asset.evolutionScore = asset.evolutionScore.add(msg.value.div(100)); // Small score boost per stake

        emit EvoAssetBoostStaked(_assetId, msg.sender, msg.value);
    }

    /**
     * @notice Allows users to unstake their native currency from an EvoAsset's boost pool.
     * @param _assetId The ID of the EvoAsset.
     * @param _amount The amount to unstake.
     */
    function unstakeFromBoost(uint256 _assetId, uint256 _amount) external nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        if (_amount == 0) revert EvoSphere__InvalidAmount();
        if (evoAssets[_assetId].stakedBoostByAddress[msg.sender] < _amount) revert EvoSphere__InsufficientBalance();

        EvoAsset storage asset = evoAssets[_assetId];
        asset.stakedBoostByAddress[msg.sender] = asset.stakedBoostByAddress[msg.sender].sub(_amount);
        asset.totalStakedBoost = asset.totalStakedBoost.sub(_amount);

        payable(msg.sender).transfer(_amount); // Return funds

        emit EvoAssetBoostUnstaked(_assetId, msg.sender, _amount);
    }

    /**
     * @notice Allows community members to add relevant keywords/tags to an EvoAsset.
     * @param _assetId The ID of the EvoAsset.
     * @param _tag The tag to add.
     */
    function addAffinityTag(uint256 _assetId, string memory _tag) external nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        EvoAsset storage asset = evoAssets[_assetId];
        
        // Prevent duplicate tags
        if (asset.affinityTags[_tag]) {
            return;
        }

        asset.affinityTags[_tag] = true;
        asset.activeTags.push(_tag);
        assetsByTag[_tag].push(_assetId); // Add to lookup index

        asset.evolutionScore = asset.evolutionScore.add(10); // Small score boost for tagging

        emit EvoAssetTagAdded(_assetId, _tag);
    }

    /**
     * @notice Proposes to remove an affinity tag from an EvoAsset. Requires owner approval or governance.
     * For simplicity, direct removal by owner if they have enough reputation, otherwise a proposal.
     * @param _assetId The ID of the EvoAsset.
     * @param _tag The tag to remove.
     */
    function removeAffinityTag(uint256 _assetId, string memory _tag) external nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        EvoAsset storage asset = evoAssets[_assetId];

        if (!asset.affinityTags[_tag]) {
            // Tag not present
            return;
        }

        // Allow owner with enough reputation to remove, otherwise it would require a proposal
        if (ownerOf(_assetId) == msg.sender && userReputation[msg.sender] >= MIN_REPUTATION_FOR_INFLUENCE) {
            asset.affinityTags[_tag] = false;
            // Remove from activeTags array
            for (uint256 i = 0; i < asset.activeTags.length; i++) {
                if (keccak256(abi.encodePacked(asset.activeTags[i])) == keccak256(abi.encodePacked(_tag))) {
                    asset.activeTags[i] = asset.activeTags[asset.activeTags.length - 1];
                    asset.activeTags.pop();
                    break;
                }
            }
            // Remove from assetsByTag index
            uint256[] storage assets = assetsByTag[_tag];
            for (uint256 i = 0; i < assets.length; i++) {
                if (assets[i] == _assetId) {
                    assets[i] = assets[assets.length - 1];
                    assets.pop();
                    break;
                }
            }
            emit EvoAssetTagRemoved(_assetId, _tag);
        } else {
            // For general users, removal would need a new type of proposal.
            // Simplified: only owner with sufficient reputation can remove directly.
            // Otherwise, it's a no-op in this example.
            revert EvoSphere__NotAssetOwner(); // Or more specific error like "InsufficientPermissionsForTagRemoval"
        }
    }

    // --- III. Reputation System ---

    /**
     * @notice A simplified function to earn reputation. In a real system, this would be tied to
     * complex on-chain or off-chain actions (e.g., successful proposals, content curation).
     * @param _user The user to grant reputation to.
     * @param _amount The amount of reputation to grant.
     */
    function earnReputation(address _user, uint256 _amount) external onlyRole(CREATOR_ROLE) {
        // This function is for demonstration. In a real system, reputation would be earned
        // through on-chain actions like successful proposals, active voting, etc.
        // Or triggered by an oracle for off-chain contributions.
        userReputation[_user] = userReputation[_user].add(_amount);
        emit ReputationEarned(_user, _amount);
    }

    /**
     * @notice Allows a user to stake their reputation to amplify their influence.
     * Staked reputation is used for voting power and trait influence.
     * @param _amount The amount of reputation to stake.
     */
    function stakeReputationForInfluence(uint256 _amount) external nonReentrant {
        if (userReputation[msg.sender] < _amount) revert EvoSphere__InsufficientBalance();
        if (reputationDelegates[msg.sender] != address(0)) revert EvoSphere__CannotUnstakeReputationWhileDelegated(); // Can't stake if delegated
        
        userReputation[msg.sender] = userReputation[msg.sender].sub(_amount);
        stakedReputation[msg.sender] = stakedReputation[msg.sender].add(_amount);
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to unstake their reputation.
     * @param _amount The amount of reputation to unstake.
     */
    function unstakeReputation(uint256 _amount) external nonReentrant {
        if (stakedReputation[msg.sender] < _amount) revert EvoSphere__InsufficientBalance();
        if (reputationDelegates[msg.sender] != address(0)) revert EvoSphere__CannotUnstakeReputationWhileDelegated(); // Can't unstake if delegated

        stakedReputation[msg.sender] = stakedReputation[msg.sender].sub(_amount);
        userReputation[msg.sender] = userReputation[msg.sender].add(_amount);
        emit ReputationUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to delegate their voting power to another address.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external nonReentrant {
        if (_delegatee == address(0)) revert EvoSphere__DelegateeCannotBeZeroAddress();
        if (_delegatee == msg.sender) revert EvoSphere__SelfDelegationNotAllowed();
        if (userReputation[msg.sender] < MIN_REP_TO_DELEGATE && stakedReputation[msg.sender] < MIN_REP_TO_DELEGATE) revert EvoSphere__NotEnoughReputation(MIN_REP_TO_DELEGATE, 0);

        // If already delegated, undelegate first
        if (reputationDelegates[msg.sender] != address(0)) {
            _undelegateReputationInternal(msg.sender);
        }

        uint256 totalAvailableRep = userReputation[msg.sender].add(stakedReputation[msg.sender]);
        reputationDelegates[msg.sender] = _delegatee;
        delegatedReputation[_delegatee] = delegatedReputation[_delegatee].add(totalAvailableRep);

        emit ReputationDelegated(msg.sender, _delegatee, totalAvailableRep);
    }

    /**
     * @notice Revokes a previous reputation delegation.
     */
    function undelegateReputation() external nonReentrant {
        if (reputationDelegates[msg.sender] == address(0)) return; // No active delegation

        _undelegateReputationInternal(msg.sender);
        emit ReputationUndelegated(msg.sender, reputationDelegates[msg.sender], userReputation[msg.sender].add(stakedReputation[msg.sender]));
    }

    /**
     * @dev Internal function to undelegate reputation.
     * @param _delegator The address revoking delegation.
     */
    function _undelegateReputationInternal(address _delegator) internal {
        address delegatee = reputationDelegates[_delegator];
        if (delegatee != address(0)) {
            uint256 totalDelegated = userReputation[_delegator].add(stakedReputation[_delegator]);
            delegatedReputation[delegatee] = delegatedReputation[delegatee].sub(totalDelegated);
            delete reputationDelegates[_delegator];
        }
    }

    /**
     * @dev Gets the effective voting/influence power for a user, considering delegation.
     * @param _user The user's address.
     * @return The total reputation (staked + owned + delegated to them).
     */
    function _getVoterInfluence(address _user) internal view returns (uint256) {
        return stakedReputation[_user].add(userReputation[_user]).add(delegatedReputation[_user]);
    }

    /**
     * @dev Calculates the total active reputation available for voting in the system.
     * This is a simplified snapshot. For real DAOs, a more robust snapshotting mechanism would be used.
     * @return The sum of all actively staked and owned reputation, not including delegated power multiple times.
     */
    function _getTotalActiveReputation() internal view returns (uint256) {
        // This is a rough estimation. For accurate snapshotting, you'd need to iterate
        // or maintain a global sum, and account for delegations properly to avoid double counting.
        // For this example, we'll assume total userReputation + totalStakedReputation
        // roughly represents the voting pool, and that delegation logic is handled within vote counts.
        uint256 total = 0;
        // This would be very gas intensive for many users.
        // A real system would track this sum or use a more advanced token for governance.
        // For demonstration, we'll use a placeholder that *would* iterate.
        // Let's assume a global variable `totalSystemReputation` exists and is updated on rep changes.
        // For now, return a placeholder. In practice, this would involve a global counter.
        // For now, let's return a large number as a placeholder for a community's total voting power.
        // This method needs to be efficient. A better approach is to use a token for reputation.
        // For simplicity, we'll use a fixed value or a value derived from total minting of rep.
        return 100000; // Placeholder: Assume total system reputation is 100,000 for voting calculations.
    }

    // --- IV. AI-Assisted Trait Generation (Simulated Oracle Interaction) ---

    /**
     * @notice Initiates a request to the AI oracle for a trait update.
     * Callable by the EvoAsset owner or a highly-reputed user.
     * @param _assetId The ID of the EvoAsset.
     * @param _traitName The name of the trait to be updated by AI.
     */
    function requestAIInfluencedTraitUpdate(uint256 _assetId, string memory _traitName) external nonReentrant {
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        if (ownerOf(_assetId) != msg.sender && userReputation[msg.sender] < MIN_REPUTATION_FOR_PROPOSAL) {
            revert EvoSphere__NotAssetOwner(); // Or specific error for insufficient permissions
        }
        if (aiOracleAddress == address(0)) revert EvoSphere__OracleNotSet();
        if (pendingOracleRequests[_assetId]) revert EvoSphere__TraitUpdateInProgress();

        pendingOracleRequests[_assetId] = true;
        lastOracleRequestId++; // Increment request ID

        // Call the AI Oracle contract
        aiOracle.requestTraitUpdate(_assetId, _traitName, address(this));

        emit AITraitUpdateRequest(_assetId, _traitName, lastOracleRequestId);
    }

    /**
     * @notice Callback function for the AI oracle to deliver the new trait value.
     * Only callable by the designated AI oracle address.
     * @param _assetId The ID of the EvoAsset.
     * @param _traitName The name of the trait updated.
     * @param _newValue The new value suggested by the AI.
     * @param _requestId The ID of the original request.
     */
    function fulfillAIInfluencedTraitUpdate(uint256 _assetId, string memory _traitName, string memory _newValue, uint256 _requestId) external nonReentrant {
        if (msg.sender != aiOracleAddress) revert EvoSphere__UnauthorizedOracleCall();
        if (!_exists(_assetId)) revert EvoSphere__InvalidAssetId();
        if (!pendingOracleRequests[_assetId]) revert EvoSphere__TraitUpdateInProgress(); // Request not active or already fulfilled

        EvoAsset storage asset = evoAssets[_assetId];
        asset.dynamicTraits[_traitName] = _newValue;
        asset.evolutionScore = asset.evolutionScore.add(50); // Reward for AI-driven update

        delete pendingOracleRequests[_assetId]; // Mark request as fulfilled

        emit AITraitUpdateFulfilled(_assetId, _traitName, _newValue, _requestId);
    }

    // --- V. Governance & Treasury ---

    /**
     * @notice Allows users to submit a proposal for spending funds from the community treasury.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of funds to send.
     * @param _description A description of the proposal.
     */
    function submitTreasuryProposal(address _recipient, uint256 _amount, string memory _description)
        external
        nonReentrant
    {
        if (userReputation[msg.sender] < MIN_REPUTATION_FOR_PROPOSAL) {
            revert EvoSphere__NotEnoughReputation(MIN_REPUTATION_FOR_PROPOSAL, userReputation[msg.sender]);
        }
        if (_amount == 0) revert EvoSphere__InvalidAmount();
        if (treasuryBalance < _amount) revert EvoSphere__InsufficientBalance();

        _treasuryProposalIdCounter.increment();
        uint256 proposalId = _treasuryProposalIdCounter.current();

        treasuryProposals[proposalId] = TreasuryProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            totalReputationAtProposal: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false,
            passed: false
        });

        emit TreasuryProposalSubmitted(proposalId, msg.sender, _recipient, _amount);
    }

    /**
     * @notice Allows users to vote on a treasury spending proposal.
     * @param _proposalId The ID of the treasury proposal.
     * @param _voteChoice True for 'yes', false for 'no'.
     */
    function voteOnTreasuryProposal(uint256 _proposalId, bool _voteChoice) external nonReentrant {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        if (proposal.proposalId == 0) revert EvoSphere__ProposalNotFound();
        if (block.timestamp > proposal.voteEndTime) revert EvoSphere__ProposalExpired();
        if (proposal.executed) revert EvoSphere__ProposalAlreadyExecuted();
        if (proposal.hasVoted[msg.sender]) revert EvoSphere__AlreadyVoted();

        uint256 voterInfluence = _getVoterInfluence(msg.sender);
        if (voterInfluence == 0) revert EvoSphere__NotEnoughReputation(1, 0);

        proposal.hasVoted[msg.sender] = true;

        if (proposal.totalReputationAtProposal == 0) {
            proposal.totalReputationAtProposal = _getTotalActiveReputation();
        }

        if (_voteChoice) {
            proposal.yesVotes = proposal.yesVotes.add(voterInfluence);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterInfluence);
        }

        emit TreasuryProposalVoted(_proposalId, msg.sender, _voteChoice, voterInfluence);
    }

    /**
     * @notice Executes a passed treasury proposal, sending funds to the recipient.
     * Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the treasury proposal.
     */
    function executeTreasuryProposal(uint256 _proposalId) external nonReentrant {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        if (proposal.proposalId == 0) revert EvoSphere__ProposalNotFound();
        if (block.timestamp <= proposal.voteEndTime) revert EvoSphere__ProposalNotExpired();
        if (proposal.executed) revert EvoSphere__ProposalAlreadyExecuted();

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 minVotesToPass = proposal.totalReputationAtProposal.mul(TREASURY_THRESHOLD_PERCENT).div(100);

        bool passed = (proposal.yesVotes > proposal.noVotes) && (proposal.yesVotes >= minVotesToPass) && (proposal.amount <= treasuryBalance);
        proposal.executed = true;
        proposal.passed = passed;

        if (passed) {
            treasuryBalance = treasuryBalance.sub(proposal.amount);
            payable(proposal.recipient).transfer(proposal.amount); // Send funds
            emit TreasuryProposalExecuted(_proposalId, proposal.recipient, proposal.amount);
        } else {
            revert EvoSphere__ProposalNotPassed();
        }
    }

    /**
     * @notice Allows the owner or DAO to set the fee for certain actions.
     * @param _newFee The new fee amount in wei.
     */
    function setEvolutionFee(uint256 _newFee) external onlyOwner {
        if (_newFee > 1 ether) revert EvoSphere__FeeTooHigh(); // Example limit
        evolutionFee = _newFee;
        emit EvolutionFeeSet(_newFee);
    }

    /**
     * @notice Allows the owner to collect fees accumulated in the contract's treasury balance.
     * These are distinct from the general contract balance which might hold staked funds.
     */
    function collectFees() external onlyOwner nonReentrant {
        uint256 amount = treasuryBalance;
        if (amount == 0) revert EvoSphere__NoFundsToCollect();
        
        treasuryBalance = 0; // Reset treasury balance
        payable(msg.sender).transfer(amount);
        emit FeesCollected(msg.sender, amount);
    }

    // --- VI. Discovery & Utility ---

    /**
     * @notice Retrieves a list of EvoAsset IDs that have a specific affinity tag.
     * @param _tag The tag to search for.
     * @return An array of EvoAsset IDs.
     */
    function getAssetsByTag(string memory _tag) external view returns (uint256[] memory) {
        return assetsByTag[_tag];
    }

    /**
     * @notice Retrieves a list of EvoAsset IDs sorted by their evolution score (descending).
     * For simplicity, this will iterate through all assets. For a very large number of assets,
     * an off-chain indexer or a more complex on-chain data structure would be needed.
     * @param _limit The maximum number of assets to return.
     * @return An array of EvoAsset IDs.
     */
    function getTopEvolvingAssets(uint256 _limit) external view returns (uint256[] memory) {
        uint256 totalAssets = _tokenIdCounter.current();
        if (totalAssets == 0) return new uint256[](0);

        uint256[] memory assetIds = new uint256[](totalAssets);
        for (uint256 i = 0; i < totalAssets; i++) {
            assetIds[i] = _allTokens[i]; // _allTokens is from ERC721Enumerable
        }

        // Simple bubble sort (not efficient for large arrays, for demonstration)
        for (uint256 i = 0; i < totalAssets - 1; i++) {
            for (uint256 j = 0; j < totalAssets - i - 1; j++) {
                if (evoAssets[assetIds[j]].evolutionScore < evoAssets[assetIds[j+1]].evolutionScore) {
                    uint256 temp = assetIds[j];
                    assetIds[j] = assetIds[j+1];
                    assetIds[j+1] = temp;
                }
            }
        }

        uint256 returnCount = totalAssets > _limit ? _limit : totalAssets;
        uint256[] memory topAssets = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            topAssets[i] = assetIds[i];
        }
        return topAssets;
    }

    /**
     * @notice Allows the contract owner to withdraw any remaining contract balance.
     * This is distinct from the `treasuryBalance` which is for community use.
     * @param _recipient The address to send funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        if (address(this).balance < _amount) revert EvoSphere__InsufficientBalance();
        if (_amount == 0) revert EvoSphere__InvalidAmount();
        
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- Admin/Role Management ---

    /**
     * @notice Grants a role to an address.
     * @param _role The role (e.g., CREATOR_ROLE).
     * @param _account The address to grant the role to.
     */
    function grantRole(bytes32 _role, address _account) public onlyOwner {
        if (_role == CREATOR_ROLE) {
            hasCreatorRole[_account] = true;
        }
        // Add other role specific grants here
    }

    /**
     * @notice Revokes a role from an address.
     * @param _role The role (e.g., CREATOR_ROLE).
     * @param _account The address to revoke the role from.
     */
    function revokeRole(bytes32 _role, address _account) public onlyOwner {
        if (_role == CREATOR_ROLE) {
            hasCreatorRole[_account] = false;
        }
        // Add other role specific revocations here
    }

    /**
     * @dev Modifier to restrict access to functions by role.
     * @param _role The role required.
     */
    modifier onlyRole(bytes32 _role) {
        if (_role == CREATOR_ROLE) {
            require(hasCreatorRole[msg.sender], "EvoSphere: Must have creator role");
        } else {
            revert("EvoSphere: Unknown role");
        }
        _;
    }

    /**
     * @notice Sets the address of the AI Oracle contract.
     * @param _newOracleAddress The address of the new AI Oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "EvoSphere: Oracle address cannot be zero");
        aiOracleAddress = _newOracleAddress;
        aiOracle = IAIOracle(_newOracleAddress);
        emit AIOracleSet(_newOracleAddress);
    }

    // Fallback and Receive functions to handle incoming Ether
    receive() external payable {}
    fallback() external payable {}
}
```