The `NeuralNexusProtocol` is a sophisticated Solidity smart contract designed to manage a decentralized ecosystem of dynamic, AI-enhanced NFTs called "Cognitive Shards." Each shard represents a unit of digital consciousness and possesses evolving traits and neural potential. The protocol introduces an ERC20 fungible token, "Essence" ($ESSENCE), which acts as a computational resource required for various operations such as evolving shards, merging entities, and activating dormant units.

Beyond individual shard management, the protocol enables the formation of "Neural Networks" – dynamic collectives of shards that can collaborate on "Neural Inference" queries, simulating a form of collective intelligence. The entire ecosystem is governed by a Decentralized Autonomous Organization (DAO), allowing Essence token holders and staked shard owners to propose and vote on crucial protocol parameters, ensuring community-driven evolution and adaptation.

**Concept:** The NeuralNexus Protocol seeks to explore the intersection of dynamic NFTs, resource economies, and decentralized governance to create a living, evolving digital organism on the blockchain, influenced by on-chain actions and simulated external data.

---

## NeuralNexusProtocol Smart Contract

**Outline:**

1.  **State Variables & Constants:** Global configurations, counters for Shards, Networks, Proposals, and Inference Queries. Mappings for entity data.
2.  **Structs:** `Shard`, `NeuralNetwork`, `Proposal`, `NeuralInferenceQuery`.
3.  **Events:** Comprehensive logging for all key actions and state changes within the protocol.
4.  **Modifiers:** Access control (`onlyOwner`, `onlyShardOwner`), state checks (`whenNotDormant`, `onlyUnstakedShard`, `onlyActiveProposal`, etc.).
5.  **Libraries:** `SafeMath` (from OpenZeppelin) for secure arithmetic operations and `Counters` for ID generation.
6.  **ERC721 & ERC20 Core Implementations:** Inherits `ERC721Enumerable` for NFT functionality and deploys a custom `EssenceToken` (ERC20).
7.  **Constructor:** Initializes the protocol, sets initial parameters, and deploys the `EssenceToken`.
8.  **Core Cognitive Shard Management:** Functions governing the lifecycle of individual Cognitive Shards, including minting, evolving traits, increasing potential, and merging.
9.  **Neural Network Management:** Functions for creating, adding/removing members, and updating the purpose of Neural Networks.
10. **Essence Token & Staking:** Functions for interacting with the $ESSENCE token, including staking shards to earn yield.
11. **Evolution & Oracle Simulation:** Mechanisms for epoch-based shard evolution and simulating external data influence on the ecosystem.
12. **Decentralized Autonomous Organization (DAO) Governance:** Functions for proposing, voting on, and executing protocol-wide parameter changes and specific shard mutations.
13. **Neural Inference System:** Functions for initiating queries to Neural Networks for collective intelligence, and resolving these queries.
14. **Utility & View Functions:** Public functions to query the current state of Shards, Networks, Proposals, and other protocol parameters.

---

**Function Summary:**

1.  `constructor(address _owner, string memory _essenceName, string memory _essenceSymbol)`: Initializes the contract with an owner, sets initial epoch parameters, and deploys the associated Essence ERC20 token.
2.  `mintCognitiveShard(address _recipient, uint256 _initialPotential, uint256 _initialTraitBitmask, string memory _tokenURI)`: Mints a new Cognitive Shard NFT to `_recipient` with a given initial neural potential, trait bitmask, and metadata URI. Callable only by the contract owner.
3.  `evolveShardTraits(uint256 _shardId, uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove, uint256 _essenceCost)`: Allows a shard owner to evolve their shard's traits by adding specified traits (via bitmask OR) and/or removing others (via bitmask AND-NOT), consuming a specific `_essenceCost`.
4.  `increaseShardPotential(uint256 _shardId, uint256 _amount, uint256 _essenceCost)`: Enables a shard owner to boost their shard's `neuralPotential` by a specified `_amount`, consuming `_essenceCost`.
5.  `mergeCognitiveShards(uint256[] memory _shardIdsToMerge, string memory _newTokenURI, uint256 _essenceCost)`: Merges multiple existing Cognitive Shards into a single new, more powerful shard. The original shards are burned, their potentials are summed, and traits are combined. Requires `_essenceCost`.
6.  `proposeTraitMutation(uint256 _shardId, uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove, string memory _rationaleURI)`: Initiates a DAO proposal for a specific trait mutation on an owned shard. This proposal must be voted on by the community.
7.  `createNeuralNetwork(string memory _purposeURI)`: Allows any user to create a new Neural Network, defining its purpose with a URI.
8.  `addShardToNetwork(uint256 _networkId, uint256 _shardId)`: Adds an owned, non-staked Cognitive Shard to a specified Neural Network, contributing its potential to the collective.
9.  `removeShardFromNetwork(uint256 _networkId, uint256 _shardId)`: Removes an owned Cognitive Shard from a Neural Network, decreasing the network's collective potential.
10. `proposeNetworkPurposeUpdate(uint256 _networkId, string memory _newPurposeURI)`: Allows the creator of a Neural Network (or designated members in a more complex system) to propose updating its descriptive URI.
11. `triggerEpochEvolution()`: Callable by anyone, this function advances the global evolution epoch if the `epochDuration` has passed. It simulates time-based processes like potential decay/growth (though actual per-shard logic is abstracted for gas efficiency).
12. `submitExternalDataInfluence(bytes32 _dataHash, uint256 _influenceMagnitude)`: Simulates an oracle feed, allowing the owner to submit external data (represented by a hash and influence magnitude) that could affect future epoch evolution parameters.
13. `proposeGlobalEvolutionParameter(bytes32 _paramKey, uint256 _newValue, string memory _descriptionURI)`: Initiates a DAO proposal to change a core protocol parameter (e.g., yield rates, voting periods) identified by `_paramKey` to `_newValue`.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible participants (currently, Essence token holders) to cast their vote (yes/no) on an active DAO proposal.
15. `executeProposal(uint256 _proposalId)`: Executes a DAO proposal that has reached its voting end epoch and satisfied the quorum and majority vote requirements.
16. `stakeShardForEssence(uint256 _shardId)`: Allows a Cognitive Shard owner to stake their shard, making it eligible to earn passive Essence token rewards each epoch.
17. `claimStakedEssence(uint256 _shardId)`: Allows a staked shard owner to claim their accumulated Essence rewards based on the number of epochs their shard has been staked.
18. `activateDormantShard(uint256 _shardId, uint256 _essenceCost)`: Re-activates a dormant Cognitive Shard (e.g., one with zero potential) by consuming `_essenceCost`, restoring it to a minimal active state.
19. `initiateNeuralInference(uint256 _networkId, bytes32 _queryHash, uint256 _essenceStake)`: Allows a user to submit a query (identified by `_queryHash`) to a specific Neural Network, staking `_essenceStake` as a reward for resolution.
20. `resolveNeuralInference(uint256 _queryId, bytes32 _resultHash)`: Enables a member of the target Neural Network to submit a resolution (`_resultHash`) for an active inference query, distributing the staked Essence.
21. `withdrawInferenceStake(uint256 _queryId)`: Allows the initiator of an inference query to withdraw their staked Essence. (Note: In this implementation, stake is distributed on resolution, so this function is mainly for handling un-resolved/expired queries if such logic were added).
22. `updateTraitDescription(uint256 _traitBit, string memory _newDescriptionURI)`: Allows the contract owner (or via a DAO proposal) to update the metadata URI associated with a specific trait bit, providing human-readable descriptions for evolving traits.
23. `configureEssenceYieldRate(uint256 _newRate)`: Allows the contract owner (or via a DAO proposal) to adjust the rate at which staked shards earn Essence per epoch.

---
**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for safety, though 0.8.x mostly handles overflow/underflow

/**
 * @title NeuralNexusProtocol
 * @dev Manages dynamic, AI-enhanced NFTs (Cognitive Shards), Neural Networks,
 *      an Essence token economy, and DAO governance.
 */
contract NeuralNexusProtocol is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables & Constants ---
    Counters.Counter private _shardIdCounter;
    Counters.Counter private _networkIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _inferenceQueryIdCounter;

    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds for each epoch
    uint256 public lastEpochTimestamp;
    uint256 public essenceYieldRatePerEpoch; // Rate of Essence rewarded per epoch for staked shards (scaled by Essence token decimals)

    // Reference to the Essence ERC20 token
    EssenceToken public essenceToken;

    // Data about Cognitive Shards
    struct Shard {
        uint256 neuralPotential; // Represents intelligence/strength
        uint256 genesisTimestamp;
        uint256 lastEvolutionEpoch;
        uint256 traits; // Bitmask of traits
        uint256 networkId; // 0 if not part of any network
        bool isStaked;
        uint256 stakedEpochs; // Total epochs shard has been staked
        uint256 lastStakedEpochClaimed; // Last epoch for which Essence was claimed
    }
    mapping(uint256 => Shard) public cognitiveShards;
    mapping(address => uint256[]) public ownerStakedShards; // To keep track of staked shards by owner

    // Data about Neural Networks
    struct NeuralNetwork {
        string purposeURI; // URI to describe the network's purpose (e.g., IPFS CID)
        uint256[] shardMembers; // Array of shard IDs that are members
        uint256 collectivePotential; // Sum of member potentials
        address creator;
        uint256 lastPurposeUpdateEpoch;
    }
    mapping(uint256 => NeuralNetwork) public neuralNetworks;
    mapping(uint256 => bool) public networkExists; // Helper to check if network ID is valid

    // DAO Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        address proposer;
        string descriptionURI;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 yesVotes;
        uint256 noVotes;
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract to call
        ProposalState state;
        mapping(address => bool) hasVoted; // Check if an address has voted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public minEssenceToPropose; // Minimum Essence required to submit a proposal
    uint256 public votingPeriodEpochs; // Number of epochs a proposal is active for voting
    uint256 public proposalQuorumPercentage; // e.g., 50 for 50% of total voting power needed for quorum

    // External Data Influence (Simulated Oracle)
    mapping(uint256 => bytes32) public epochExternalDataHash; // Data hash for current epoch (e.g., IPFS CID)
    mapping(uint256 => uint256) public epochExternalDataInfluence; // Influence magnitude for current epoch

    // Neural Inference System
    enum InferenceState { Active, Resolved, Withdrawn }
    struct NeuralInferenceQuery {
        uint256 networkId;
        address initiator;
        bytes32 queryHash; // Hash of the query data (e.g., IPFS CID)
        bytes32 resultHash; // Hash of the result data
        uint256 essenceStake;
        InferenceState state;
        uint256 submissionEpoch;
        uint256 resolutionEpoch;
    }
    mapping(uint256 => NeuralInferenceQuery) public inferenceQueries;

    // Trait Definitions and Descriptions
    // For simplicity, traits are just bits. `traitDescriptionURIs` maps trait bit (e.g., 1, 2, 4, 8) to its URI.
    mapping(uint256 => string) public traitDescriptionURIs;

    // --- Events ---
    event ShardMinted(uint256 indexed shardId, address indexed owner, uint256 initialPotential, uint256 initialTraits);
    event ShardEvolved(uint256 indexed shardId, uint256 oldTraits, uint256 newTraits);
    event ShardPotentialIncreased(uint256 indexed shardId, uint256 oldPotential, uint256 newPotential);
    event ShardsMerged(uint256[] indexed mergedShardIds, uint256 indexed newShardId);
    event TraitMutationProposed(uint256 indexed shardId, uint256 proposalId, string rationaleURI);
    event NeuralNetworkCreated(uint256 indexed networkId, address indexed creator, string purposeURI);
    event ShardAddedToNetwork(uint256 indexed networkId, uint256 indexed shardId);
    event ShardRemovedFromNetwork(uint256 indexed networkId, uint256 indexed shardId);
    event NetworkPurposeUpdated(uint256 indexed networkId, string newPurposeURI);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 lastTimestamp);
    event ExternalDataSubmitted(bytes32 indexed dataHash, uint256 influenceMagnitude, uint256 epoch);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionURI);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState newState);
    event ShardStaked(uint256 indexed shardId, address indexed owner);
    event EssenceClaimed(uint256 indexed shardId, address indexed owner, uint256 amount);
    event ShardActivated(uint256 indexed shardId, uint256 essenceCost);
    event NeuralInferenceInitiated(uint256 indexed queryId, uint256 indexed networkId, address indexed initiator, bytes32 queryHash, uint256 essenceStake);
    event NeuralInferenceResolved(uint256 indexed queryId, bytes32 resultHash);
    event InferenceStakeWithdrawn(uint256 indexed queryId, address indexed initiator, uint256 amount);
    event TraitDescriptionUpdated(uint256 indexed traitBit, string newDescriptionURI);
    event EssenceYieldRateConfigured(uint256 newRate);


    // --- Modifiers ---
    modifier onlyShardOwner(uint256 _shardId) {
        require(_exists(_shardId), "NeuralNexus: Shard does not exist");
        require(ERC721.ownerOf(_shardId) == msg.sender, "NeuralNexus: Not shard owner");
        _;
    }

    modifier onlyNetworkMember(uint256 _networkId, uint256 _shardId) {
        require(networkExists[_networkId], "NeuralNexus: Network does not exist");
        require(cognitiveShards[_shardId].networkId == _networkId, "NeuralNexus: Shard not a member of this network");
        require(ERC721.ownerOf(_shardId) == msg.sender, "NeuralNexus: Shard must be owned by caller");
        _;
    }

    modifier onlyNetworkCreator(uint256 _networkId) {
        require(networkExists[_networkId], "NeuralNexus: Network does not exist");
        require(neuralNetworks[_networkId].creator == msg.sender, "NeuralNexus: Not network creator");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "NeuralNexus: Proposal not active");
        _;
    }

    modifier onlyUnstakedShard(uint256 _shardId) {
        require(!cognitiveShards[_shardId].isStaked, "NeuralNexus: Shard is currently staked");
        _;
    }

    modifier onlyStakedShard(uint256 _shardId) {
        require(cognitiveShards[_shardId].isStaked, "NeuralNexus: Shard is not staked");
        _;
    }

    modifier whenNotDormant(uint256 _shardId) {
        // Simple dormancy check: potential must be > 0. More complex logic could be used.
        require(cognitiveShards[_shardId].neuralPotential > 0, "NeuralNexus: Shard is dormant");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the NeuralNexus Protocol contract.
    /// @param _owner The initial owner of the protocol (can be a multisig/DAO later).
    /// @param _essenceName The name for the Essence ERC20 token.
    /// @param _essenceSymbol The symbol for the Essence ERC20 token.
    constructor(address _owner, string memory _essenceName, string memory _essenceSymbol)
        ERC721("CognitiveShard", "CSHRD")
        Ownable(_owner)
    {
        // Deploy Essence Token, setting this contract as its initial owner
        essenceToken = new EssenceToken(_essenceName, _essenceSymbol, address(this));

        // Initial protocol parameters
        currentEpoch = 1;
        epochDuration = 1 days; // 1 day per epoch for example
        lastEpochTimestamp = block.timestamp;
        essenceYieldRatePerEpoch = 100 * (10 ** essenceToken.decimals()); // 100 Essence per epoch for a staked shard

        minEssenceToPropose = 1000 * (10 ** essenceToken.decimals()); // 1000 Essence to propose
        votingPeriodEpochs = 7; // 7 epochs for voting
        proposalQuorumPercentage = 50; // 50% quorum
    }

    // --- Core Cognitive Shard Management ---

    /// @notice Mints a new Cognitive Shard NFT. Only callable by the owner (protocol admin/DAO).
    /// @param _recipient The address to mint the shard to.
    /// @param _initialPotential The initial neural potential of the shard.
    /// @param _initialTraitBitmask A bitmask representing the initial traits of the shard.
    /// @param _tokenURI The URI pointing to the metadata of the new shard.
    function mintCognitiveShard(address _recipient, uint256 _initialPotential, uint256 _initialTraitBitmask, string memory _tokenURI) public onlyOwner {
        require(_initialPotential > 0, "NeuralNexus: Initial potential must be greater than 0");
        _shardIdCounter.increment();
        uint256 newShardId = _shardIdCounter.current();

        Shard storage newShard = cognitiveShards[newShardId];
        newShard.neuralPotential = _initialPotential;
        newShard.genesisTimestamp = block.timestamp;
        newShard.lastEvolutionEpoch = currentEpoch;
        newShard.traits = _initialTraitBitmask;
        newShard.networkId = 0; // Not part of any network initially
        newShard.isStaked = false;
        newShard.stakedEpochs = 0;
        newShard.lastStakedEpochClaimed = currentEpoch; // Set to current epoch to avoid immediate claim on mint

        _mint(_recipient, newShardId);
        _setTokenURI(newShardId, _tokenURI); // Set base URI or specific URI

        emit ShardMinted(newShardId, _recipient, _initialPotential, _initialTraitBitmask);
    }

    /// @notice Allows a shard owner to evolve their shard's traits by consuming Essence.
    /// @dev Traits are represented by a bitmask. Adding a trait sets its bit, removing unsets it.
    /// @param _shardId The ID of the shard to evolve.
    /// @param _traitBitmaskToAdd Bits to be OR-ed with current traits.
    /// @param _traitBitmaskToRemove Bits to be AND-NOT-ed with current traits.
    /// @param _essenceCost The amount of Essence tokens required for this evolution.
    function evolveShardTraits(uint256 _shardId, uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove, uint256 _essenceCost)
        public
        onlyShardOwner(_shardId)
        whenNotDormant(_shardId)
    {
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceCost), "NeuralNexus: Essence transfer failed for evolution");

        Shard storage shard = cognitiveShards[_shardId];
        uint256 oldTraits = shard.traits;
        
        // Apply additions and removals using bitwise operations
        uint256 newTraits = (oldTraits | _traitBitmaskToAdd) & (~_traitBitmaskToRemove);

        require(newTraits != oldTraits, "NeuralNexus: No actual trait change requested");

        shard.traits = newTraits;
        shard.lastEvolutionEpoch = currentEpoch;

        // In a real dApp, tokenURI would typically resolve to a dynamic API endpoint reflecting these changes.
        // _setTokenURI(_shardId, "new-uri-based-on-traits-logic");

        emit ShardEvolved(_shardId, oldTraits, newTraits);
    }

    /// @notice Allows a shard owner to increase their shard's neural potential by consuming Essence.
    /// @param _shardId The ID of the shard.
    /// @param _amount The amount to increase neural potential by.
    /// @param _essenceCost The amount of Essence tokens required.
    function increaseShardPotential(uint256 _shardId, uint256 _amount, uint256 _essenceCost)
        public
        onlyShardOwner(_shardId)
        whenNotDormant(_shardId)
    {
        require(_amount > 0, "NeuralNexus: Amount must be greater than 0");
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceCost), "NeuralNexus: Essence transfer failed for potential increase");

        Shard storage shard = cognitiveShards[_shardId];
        uint256 oldPotential = shard.neuralPotential;
        shard.neuralPotential = shard.neuralPotential.add(_amount);

        emit ShardPotentialIncreased(_shardId, oldPotential, shard.neuralPotential);
    }

    /// @notice Merges multiple Cognitive Shards into a single new, more powerful shard.
    /// The original shards are burned. The new shard's potential is the sum of merged shards,
    /// and its traits are a combination.
    /// @param _shardIdsToMerge An array of shard IDs to merge.
    /// @param _newTokenURI The URI for the metadata of the newly merged shard.
    /// @param _essenceCost The Essence cost for the merge operation.
    function mergeCognitiveShards(uint256[] memory _shardIdsToMerge, string memory _newTokenURI, uint256 _essenceCost) public {
        require(_shardIdsToMerge.length >= 2, "NeuralNexus: At least two shards are required for merging");
        
        uint256 combinedPotential = 0;
        uint256 combinedTraits = 0;
        
        // Ensure all shards are owned by msg.sender and sum their properties
        for (uint256 i = 0; i < _shardIdsToMerge.length; i++) {
            uint256 currentShardId = _shardIdsToMerge[i];
            require(_exists(currentShardId), "NeuralNexus: Shard does not exist");
            require(ERC721.ownerOf(currentShardId) == msg.sender, "NeuralNexus: Not the owner of shard to be merged");
            require(!cognitiveShards[currentShardId].isStaked, "NeuralNexus: Cannot merge staked shards");
            require(cognitiveShards[currentShardId].networkId == 0, "NeuralNexus: Cannot merge shards that are part of a network");
            
            combinedPotential = combinedPotential.add(cognitiveShards[currentShardId].neuralPotential);
            combinedTraits = combinedTraits | cognitiveShards[currentShardId].traits; // OR all traits
        }
        
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceCost), "NeuralNexus: Essence transfer failed for merge");

        // Mint new merged shard
        _shardIdCounter.increment();
        uint256 newShardId = _shardIdCounter.current();

        Shard storage newShard = cognitiveShards[newShardId];
        newShard.neuralPotential = combinedPotential;
        newShard.genesisTimestamp = block.timestamp;
        newShard.lastEvolutionEpoch = currentEpoch;
        newShard.traits = combinedTraits;
        newShard.networkId = 0;
        newShard.isStaked = false;
        newShard.stakedEpochs = 0;
        newShard.lastStakedEpochClaimed = currentEpoch;

        _mint(msg.sender, newShardId);
        _setTokenURI(newShardId, _newTokenURI);

        // Burn original shards
        for (uint256 i = 0; i < _shardIdsToMerge.length; i++) {
            _burn(_shardIdsToMerge[i]);
            delete cognitiveShards[_shardIdsToMerge[i]]; // Clean up storage
        }

        emit ShardsMerged(_shardIdsToMerge, newShardId);
    }

    /// @notice Allows a shard owner to propose a specific trait mutation for their shard.
    /// This is a governance proposal, requiring voting.
    /// @param _shardId The ID of the shard.
    /// @param _traitBitmaskToAdd The traits to propose adding (bitmask).
    /// @param _traitBitmaskToRemove The traits to propose removing (bitmask).
    /// @param _rationaleURI URI to description of the rationale for the mutation.
    function proposeTraitMutation(uint256 _shardId, uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove, string memory _rationaleURI)
        public
        onlyShardOwner(_shardId)
    {
        require(essenceToken.balanceOf(msg.sender) >= minEssenceToPropose, "NeuralNexus: Not enough Essence to propose");
        
        // Build callData for `_executeTraitMutationProposal` which will be called by `executeProposal`
        bytes memory callData = abi.encodeWithSelector(
            this.executeTraitMutationProposal.selector,
            _shardId,
            _traitBitmaskToAdd,
            _traitBitmaskToRemove
        );

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposer = msg.sender;
        newProposal.descriptionURI = _rationaleURI;
        newProposal.startEpoch = currentEpoch;
        newProposal.endEpoch = currentEpoch.add(votingPeriodEpochs);
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;
        newProposal.callData = callData;
        newProposal.targetContract = address(this);
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, _rationaleURI);
    }

    /// @notice Internal function to execute a trait mutation proposal. Callable only by executeProposal.
    function executeTraitMutationProposal(uint256 _shardId, uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove) internal {
        // This function should only be callable by `executeProposal`, which means `msg.sender` will be this contract itself.
        require(msg.sender == address(this), "NeuralNexus: Function can only be called internally via a successful proposal");
        
        Shard storage shard = cognitiveShards[_shardId];
        uint256 oldTraits = shard.traits;
        uint256 newTraits = (oldTraits | _traitBitmaskToAdd) & (~_traitBitmaskToRemove);

        shard.traits = newTraits;
        shard.lastEvolutionEpoch = currentEpoch;

        emit ShardEvolved(_shardId, oldTraits, newTraits);
    }


    // --- Neural Network Management ---

    /// @notice Creates a new Neural Network entity.
    /// @param _purposeURI URI describing the network's purpose (e.g., IPFS CID).
    function createNeuralNetwork(string memory _purposeURI) public {
        _networkIdCounter.increment();
        uint256 newNetworkId = _networkIdCounter.current();

        NeuralNetwork storage newNetwork = neuralNetworks[newNetworkId];
        newNetwork.purposeURI = _purposeURI;
        newNetwork.creator = msg.sender;
        newNetwork.lastPurposeUpdateEpoch = currentEpoch;
        newNetwork.collectivePotential = 0; // Will be updated when shards are added

        networkExists[newNetworkId] = true;

        emit NeuralNetworkCreated(newNetworkId, msg.sender, _purposeURI);
    }

    /// @notice Adds an owned Cognitive Shard to an existing Neural Network.
    /// @param _networkId The ID of the network.
    /// @param _shardId The ID of the shard to add.
    function addShardToNetwork(uint256 _networkId, uint256 _shardId)
        public
        onlyShardOwner(_shardId)
        whenNotDormant(_shardId)
    {
        require(networkExists[_networkId], "NeuralNexus: Network does not exist");
        require(cognitiveShards[_shardId].networkId == 0, "NeuralNexus: Shard is already part of a network");
        require(!cognitiveShards[_shardId].isStaked, "NeuralNexus: Cannot add staked shard to network");

        cognitiveShards[_shardId].networkId = _networkId;
        neuralNetworks[_networkId].shardMembers.push(_shardId);
        neuralNetworks[_networkId].collectivePotential = neuralNetworks[_networkId].collectivePotential.add(cognitiveShards[_shardId].neuralPotential);

        emit ShardAddedToNetwork(_networkId, _shardId);
    }

    /// @notice Removes an owned Cognitive Shard from a Neural Network.
    /// @param _networkId The ID of the network.
    /// @param _shardId The ID of the shard to remove.
    function removeShardFromNetwork(uint256 _networkId, uint256 _shardId)
        public
        onlyNetworkMember(_networkId, _shardId)
    {
        Shard storage shard = cognitiveShards[_shardId];
        NeuralNetwork storage network = neuralNetworks[_networkId];

        require(network.shardMembers.length > 0, "NeuralNexus: Network has no members"); // Sanity check

        bool found = false;
        for (uint256 i = 0; i < network.shardMembers.length; i++) {
            if (network.shardMembers[i] == _shardId) {
                // Remove shard from array by swapping with last element and popping
                network.shardMembers[i] = network.shardMembers[network.shardMembers.length - 1];
                network.shardMembers.pop();
                found = true;
                break;
            }
        }
        require(found, "NeuralNexus: Shard not found in network members list");

        network.collectivePotential = network.collectivePotential.sub(shard.neuralPotential);
        shard.networkId = 0; // Detach shard from network

        emit ShardRemovedFromNetwork(_networkId, _shardId);
    }

    /// @notice Allows members of a Neural Network to propose an update to its defined purpose.
    /// @dev For simplicity, currently this can only be called by the network creator.
    ///      In a more complex system, this would trigger an internal network-specific vote.
    /// @param _networkId The ID of the network.
    /// @param _newPurposeURI The new URI describing the network's purpose.
    function proposeNetworkPurposeUpdate(string memory _newPurposeURI, uint256 _networkId)
        public // Make public to allow testing, but typically should be more restricted.
        onlyNetworkCreator(_networkId) // Restricted to network creator for simplicity
    {
        require(bytes(_newPurposeURI).length > 0, "NeuralNexus: Purpose URI cannot be empty");
        neuralNetworks[_networkId].purposeURI = _newPurposeURI;
        neuralNetworks[_networkId].lastPurposeUpdateEpoch = currentEpoch;
        emit NetworkPurposeUpdated(_networkId, _newPurposeURI);
    }


    // --- Essence Token & Staking ---

    /// @notice Allows a Cognitive Shard owner to stake their shard to passively earn Essence tokens over time.
    /// @param _shardId The ID of the shard to stake.
    function stakeShardForEssence(uint256 _shardId)
        public
        onlyShardOwner(_shardId)
        onlyUnstakedShard(_shardId)
        whenNotDormant(_shardId)
    {
        require(cognitiveShards[_shardId].networkId == 0, "NeuralNexus: Cannot stake a shard that is part of a network");
        
        Shard storage shard = cognitiveShards[_shardId];
        shard.isStaked = true;
        shard.lastStakedEpochClaimed = currentEpoch; // Reset for new staking period
        
        ownerStakedShards[msg.sender].push(_shardId);

        emit ShardStaked(_shardId, msg.sender);
    }

    /// @notice Allows a staked shard owner to claim their accumulated Essence rewards.
    /// Rewards are calculated based on epochs passed since last claim.
    /// @param _shardId The ID of the staked shard.
    function claimStakedEssence(uint256 _shardId)
        public
        onlyShardOwner(_shardId)
        onlyStakedShard(_shardId)
    {
        Shard storage shard = cognitiveShards[_shardId];
        uint256 epochsPassed = currentEpoch.sub(shard.lastStakedEpochClaimed);
        
        require(epochsPassed > 0, "NeuralNexus: No new epochs passed since last claim");

        uint256 rewards = epochsPassed.mul(essenceYieldRatePerEpoch);
        require(rewards > 0, "NeuralNexus: No rewards to claim");

        essenceToken.mint(msg.sender, rewards);
        shard.lastStakedEpochClaimed = currentEpoch;
        shard.stakedEpochs = shard.stakedEpochs.add(epochsPassed); // Keep track of total staked epochs

        emit EssenceClaimed(_shardId, msg.sender, rewards);
    }

    /// @notice Re-activates a Cognitive Shard that has become dormant.
    /// This costs Essence and might restore some potential.
    /// @param _shardId The ID of the dormant shard.
    /// @param _essenceCost The cost to activate the shard.
    function activateDormantShard(uint256 _shardId, uint256 _essenceCost)
        public
        onlyShardOwner(_shardId)
    {
        require(cognitiveShards[_shardId].neuralPotential == 0, "NeuralNexus: Shard is not dormant (potential > 0)");
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceCost), "NeuralNexus: Essence transfer failed for activation");

        Shard storage shard = cognitiveShards[_shardId];
        // Restore a base potential or a percentage of max potential
        shard.neuralPotential = 100; // Example base restoration value
        shard.lastEvolutionEpoch = currentEpoch; // Reset evolution clock

        emit ShardActivated(_shardId, _essenceCost);
    }

    // --- Evolution & Oracle Simulation ---

    /// @notice Advances the global evolution epoch. Can be called by anyone,
    /// but only if enough time has passed. Triggers automated processes.
    /// @dev In a full implementation, this might trigger a batch process or enable
    ///      individual shard owners to call an update function.
    function triggerEpochEvolution() public {
        require(block.timestamp >= lastEpochTimestamp.add(epochDuration), "NeuralNexus: Epoch duration not yet passed");
        
        currentEpoch = currentEpoch.add(1);
        lastEpochTimestamp = block.timestamp;

        // Placeholder for epoch-based shard decay/growth.
        // In a production system, iterating all shards here would be gas-prohibitive.
        // This would typically involve a pull model or a keeper network.

        emit EpochAdvanced(currentEpoch, lastEpochTimestamp);
    }

    /// @notice Simulates an oracle submitting external data that can influence evolution parameters or shard traits.
    /// This data is then available for the current epoch.
    /// @dev In a real scenario, this would be restricted to a trusted oracle address(es).
    /// @param _dataHash Hash of the external data (e.g., IPFS CID for a dataset).
    /// @param _influenceMagnitude A value indicating the strength/type of influence.
    function submitExternalDataInfluence(bytes32 _dataHash, uint256 _influenceMagnitude) public onlyOwner {
        epochExternalDataHash[currentEpoch] = _dataHash;
        epochExternalDataInfluence[currentEpoch] = _influenceMagnitude;

        emit ExternalDataSubmitted(_dataHash, _influenceMagnitude, currentEpoch);
    }

    // --- Decentralized Autonomous Organization (DAO) Governance ---

    /// @notice Initiates a DAO proposal to change a global evolution parameter or other protocol settings.
    /// @param _paramKey A unique key identifying the parameter (e.g., keccak256("essenceYieldRate")).
    /// @param _newValue The new value for the parameter.
    /// @param _descriptionURI URI to a detailed description of the proposal.
    function proposeGlobalEvolutionParameter(bytes32 _paramKey, uint256 _newValue, string memory _descriptionURI) public {
        require(essenceToken.balanceOf(msg.sender) >= minEssenceToPropose, "NeuralNexus: Not enough Essence to propose");
        
        // Encode the function call for `_setGlobalParameter`
        bytes memory callData = abi.encodeWithSelector(
            this._setGlobalParameter.selector,
            _paramKey,
            _newValue
        );

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposer = msg.sender;
        newProposal.descriptionURI = _descriptionURI;
        newProposal.startEpoch = currentEpoch;
        newProposal.endEpoch = currentEpoch.add(votingPeriodEpochs);
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;
        newProposal.callData = callData;
        newProposal.targetContract = address(this); // Target is this contract itself
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, _descriptionURI);
    }

    /// @notice Allows eligible participants to cast votes on active DAO proposals.
    /// @dev Voting power is based on Essence token balance (simplified).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyActiveProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "NeuralNexus: Already voted on this proposal");
        require(currentEpoch <= proposal.endEpoch, "NeuralNexus: Voting period has ended");

        uint256 votingPower = essenceToken.balanceOf(msg.sender); // Simple voting power
        require(votingPower > 0, "NeuralNexus: No voting power");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a DAO proposal that has met the voting threshold and quorum requirements.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "NeuralNexus: Proposal already executed");
        require(currentEpoch > proposal.endEpoch, "NeuralNexus: Voting period not ended yet");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 totalEssenceSupply = essenceToken.totalSupply(); // Using total supply as max voting power

        // Check for quorum: total votes must meet a percentage of total possible voting power
        require(totalVotes.mul(100) >= totalEssenceSupply.mul(proposalQuorumPercentage).div(100), "NeuralNexus: Quorum not met");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Succeeded;
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "NeuralNexus: Proposal execution failed");
        } else {
            proposal.state = ProposalState.Failed;
        }
        
        emit ProposalExecuted(_proposalId, proposal.state);
    }

    /// @notice Internal function to set global parameters, only callable by `executeProposal`.
    /// @dev This function uses `bytes32` for `_paramKey` to allow setting various parameters dynamically.
    function _setGlobalParameter(bytes32 _paramKey, uint256 _newValue) internal {
        require(msg.sender == address(this), "NeuralNexus: Function can only be called internally via a successful proposal");

        if (_paramKey == keccak256("essenceYieldRate")) {
            essenceYieldRatePerEpoch = _newValue;
            emit EssenceYieldRateConfigured(_newValue);
        } else if (_paramKey == keccak256("minEssenceToPropose")) {
            minEssenceToPropose = _newValue;
        } else if (_paramKey == keccak256("votingPeriodEpochs")) {
            votingPeriodEpochs = _newValue;
        } else if (_paramKey == keccak256("proposalQuorumPercentage")) {
            require(_newValue <= 100, "NeuralNexus: Quorum percentage cannot exceed 100");
            proposalQuorumPercentage = _newValue;
        }
        // Extend with more configurable parameters as needed
    }
    
    /// @notice A governance function to update the URI pointing to human-readable descriptions for specific shard traits.
    /// @dev This function can be called by the owner directly or via a DAO proposal.
    /// @param _traitBit The specific trait bit (e.g., 1 for trait A, 2 for trait B, 4 for trait C etc.)
    /// @param _newDescriptionURI The new URI for the trait's description.
    function updateTraitDescription(uint256 _traitBit, string memory _newDescriptionURI) public onlyOwner {
        require(_traitBit > 0, "NeuralNexus: Trait bit must be positive");
        traitDescriptionURIs[_traitBit] = _newDescriptionURI;
        emit TraitDescriptionUpdated(_traitBit, _newDescriptionURI);
    }

    /// @notice A governance function to adjust the rate at which staked shards earn Essence.
    /// @dev This function can be called by the owner directly or via a DAO proposal.
    /// @param _newRate The new Essence yield rate per epoch per staked shard.
    function configureEssenceYieldRate(uint256 _newRate) public onlyOwner {
        essenceYieldRatePerEpoch = _newRate;
        emit EssenceYieldRateConfigured(_newRate);
    }


    // --- Neural Inference System ---

    /// @notice Allows a user to submit a "query" to a Neural Network, staking Essence for its collective intelligence/prediction.
    /// @param _networkId The ID of the Neural Network to query.
    /// @param _queryHash Hash of the query data (e.g., IPFS CID pointing to the actual question/data).
    /// @param _essenceStake The amount of Essence staked by the initiator as a reward/fee.
    function initiateNeuralInference(uint256 _networkId, bytes32 _queryHash, uint256 _essenceStake) public {
        require(networkExists[_networkId], "NeuralNexus: Network does not exist");
        require(neuralNetworks[_networkId].shardMembers.length > 0, "NeuralNexus: Network has no active members to infer");
        require(_essenceStake > 0, "NeuralNexus: Must stake some Essence for inference");
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceStake), "NeuralNexus: Essence transfer failed for inference stake");

        _inferenceQueryIdCounter.increment();
        uint256 queryId = _inferenceQueryIdCounter.current();

        NeuralInferenceQuery storage newQuery = inferenceQueries[queryId];
        newQuery.networkId = _networkId;
        newQuery.initiator = msg.sender;
        newQuery.queryHash = _queryHash;
        newQuery.essenceStake = _essenceStake;
        newQuery.state = InferenceState.Active;
        newQuery.submissionEpoch = currentEpoch;

        emit NeuralInferenceInitiated(queryId, _networkId, msg.sender, _queryHash, _essenceStake);
    }

    /// @notice Allows the designated leader or members of a Neural Network to submit a resolution for an active neural inference query.
    /// @dev For simplicity, any owner of a shard within the target network can resolve. A more complex system might require consensus.
    /// @param _queryId The ID of the inference query.
    /// @param _resultHash Hash of the result data (e.g., IPFS CID pointing to the answer/prediction).
    function resolveNeuralInference(uint256 _queryId, bytes32 _resultHash) public {
        NeuralInferenceQuery storage query = inferenceQueries[_queryId];
        require(query.state == InferenceState.Active, "NeuralNexus: Inference query is not active");
        require(query.networkId > 0, "NeuralNexus: Invalid query ID"); // Ensure query exists

        // Verify that msg.sender is an owner of a shard within the target network
        bool isNetworkMemberOwner = false;
        for (uint256 i = 0; i < neuralNetworks[query.networkId].shardMembers.length; i++) {
            if (ERC721.ownerOf(neuralNetworks[query.networkId].shardMembers[i]) == msg.sender) {
                isNetworkMemberOwner = true;
                break;
            }
        }
        require(isNetworkMemberOwner, "NeuralNexus: Only an owner of a shard in the target network can resolve");

        query.resultHash = _resultHash;
        query.state = InferenceState.Resolved;
        query.resolutionEpoch = currentEpoch;

        // Distribute essence stake to network creator as a reward for resolution
        essenceToken.transfer(neuralNetworks[query.networkId].creator, query.essenceStake);

        emit NeuralInferenceResolved(_queryId, _resultHash);
    }

    /// @notice Allows the initiator of a neural inference query to withdraw their staked Essence once the query is resolved.
    /// @dev In this specific implementation, all stake is distributed to the network creator upon `resolveNeuralInference`.
    ///      This function is included primarily for cases where stake might be refunded (e.g., query failure, expiration),
    ///      which would require additional logic in `resolveNeuralInference` to not distribute all stake immediately.
    /// @param _queryId The ID of the inference query.
    function withdrawInferenceStake(uint256 _queryId) public {
        NeuralInferenceQuery storage query = inferenceQueries[_queryId];
        require(query.initiator == msg.sender, "NeuralNexus: Only the initiator can withdraw stake");
        require(query.state == InferenceState.Resolved, "NeuralNexus: Inference query is not resolved");
        
        // As per current implementation, stake is transferred on resolve. So, this will typically revert.
        revert("NeuralNexus: Stake already distributed upon resolution. No stake to withdraw.");
    }

    // --- Utility & View Functions ---

    /// @notice Gets detailed information about a Cognitive Shard.
    /// @param _shardId The ID of the shard.
    /// @return potential, genesisTime, lastEpoch, traits, networkId, isStaked, stakedEpochs, lastStakedClaimEpoch, ownerAddress, tokenUri
    function getShardDetails(uint256 _shardId)
        public
        view
        returns (
            uint256 potential,
            uint256 genesisTime,
            uint256 lastEvolutionEpoch,
            uint256 traits,
            uint256 networkId,
            bool isStaked,
            uint256 stakedEpochs,
            uint256 lastStakedClaimEpoch,
            address ownerAddress,
            string memory tokenUri
        )
    {
        require(_exists(_shardId), "NeuralNexus: Shard does not exist");
        Shard storage shard = cognitiveShards[_shardId];
        return (
            shard.neuralPotential,
            shard.genesisTimestamp,
            shard.lastEvolutionEpoch,
            shard.traits,
            shard.networkId,
            shard.isStaked,
            shard.stakedEpochs,
            shard.lastStakedEpochClaimed,
            ERC721.ownerOf(_shardId),
            tokenURI(_shardId) // Calls ERC721's tokenURI
        );
    }

    /// @notice Gets detailed information about a Neural Network.
    /// @param _networkId The ID of the network.
    /// @return purposeUri, shardMembers, collectivePotential, creator, lastPurposeUpdateEpoch
    function getNetworkDetails(uint256 _networkId)
        public
        view
        returns (
            string memory purposeUri,
            uint256[] memory shardMembers,
            uint256 collectivePotential,
            address creator,
            uint256 lastPurposeUpdateEpoch
        )
    {
        require(networkExists[_networkId], "NeuralNexus: Network does not exist");
        NeuralNetwork storage network = neuralNetworks[_networkId];
        return (
            network.purposeURI,
            network.shardMembers,
            network.collectivePotential,
            network.creator,
            network.lastPurposeUpdateEpoch
        );
    }

    /// @notice Gets the current status of an epoch.
    /// @return currentEpochId, epochDurationInSeconds, lastEpochTimestampUTC
    function getEpochStatus() public view returns (uint256 currentEpochId, uint256 epochDurationInSeconds, uint256 lastEpochTimestampUTC) {
        return (currentEpoch, epochDuration, lastEpochTimestamp);
    }

    /// @notice Calculates the Essence cost for evolving a shard based on the number of bits changed.
    /// @dev This is a simplified calculation. Real contracts might use complex formulae.
    /// @param _traitBitmaskToAdd Traits being added (positive bits).
    /// @param _traitBitmaskToRemove Traits being removed (positive bits).
    /// @return cost The calculated Essence cost.
    function calculateShardEvolutionCost(uint256 _traitBitmaskToAdd, uint256 _traitBitmaskToRemove) public pure returns (uint256 cost) {
        uint256 baseCost = 50 * (10 ** 18); // Example base cost: 50 Essence
        uint256 bitsChanged = 0;
        // Count set bits in combined mask of additions and removals
        uint256 combinedChangeMask = _traitBitmaskToAdd | _traitBitmaskToRemove;
        for (uint256 i = 0; i < 256; i++) { 
            if ((combinedChangeMask >> i) & 1 == 1) {
                bitsChanged = bitsChanged.add(1);
            }
        }
        return baseCost.add(bitsChanged.mul(10 * (10 ** 18))); // Example: 10 Essence per bit changed
    }

    /// @notice Gets the description URI for a specific trait bit.
    /// @param _traitBit The trait bit (e.g., 1, 2, 4, 8 for distinct traits).
    /// @return descriptionUri The URI pointing to the trait's description.
    function getTraitDescription(uint256 _traitBit) public view returns (string memory descriptionUri) {
        return traitDescriptionURIs[_traitBit];
    }

    /// @notice Gets the status of a specific DAO proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return state The current state of the proposal.
    /// @return yesVotes, noVotes, totalVotes The vote counts.
    /// @return proposer The address of the proposer.
    /// @return descriptionURI The URI of the proposal's description.
    function getProposalStatus(uint256 _proposalId)
        public
        view
        returns (ProposalState state, uint256 yesVotes, uint256 noVotes, uint256 totalVotes, address proposer, string memory descriptionURI)
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.state,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.yesVotes.add(proposal.noVotes),
            proposal.proposer,
            proposal.descriptionURI
        );
    }

    /// @notice Gets details about a Neural Inference Query.
    /// @param _queryId The ID of the query.
    /// @return networkId, initiator, queryHash, resultHash, essenceStake, state, submissionEpoch, resolutionEpoch
    function getInferenceQueryDetails(uint256 _queryId)
        public
        view
        returns (uint256 networkId, address initiator, bytes32 queryHash, bytes32 resultHash, uint256 essenceStake, InferenceState state, uint256 submissionEpoch, uint256 resolutionEpoch)
    {
        NeuralInferenceQuery storage query = inferenceQueries[_queryId];
        return (
            query.networkId,
            query.initiator,
            query.queryHash,
            query.resultHash,
            query.essenceStake,
            query.state,
            query.submissionEpoch,
            query.resolutionEpoch
        );
    }
}

// Minimal ERC20 implementation for the Essence Token, owned by the NeuralNexusProtocol contract
contract EssenceToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address _owner) ERC20(name, symbol) Ownable(_owner) {}

    /// @notice Mints new Essence tokens. Only callable by the owner (NeuralNexusProtocol contract).
    /// @param to The recipient of the tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```