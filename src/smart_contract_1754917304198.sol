The `AetherWeaver` contract is a sophisticated Solidity smart contract designed to manage a universe of dynamically evolving digital assets, known as "Aether Shards" (ERC721 NFTs). It incorporates advanced concepts like AI oracle integration for dynamic narrative generation, a user reputation system (Weaver XP), gamified evolution mechanics, and simplified decentralized governance.

The core idea is that Aether Shards are not static NFTs. Their traits and "lore" (backstory/description) can evolve based on owner interactions (nurturing, merging), a pseudo-random on-chain generative engine, and insights fed by a trusted AI oracle. The global "mood" of the Aether Weaver universe can also be influenced by the oracle, affecting shard evolution paths.

### Outline:

**I. Core Infrastructure & Access Control**
   - Essential functions for contract setup, ownership management, pausing in emergencies, and fund withdrawal.

**II. Aether Shard (ERC721) Management**
   - Functions governing the entire lifecycle of Aether Shards, from minting and nurturing to complex evolution and merging mechanics. It also includes a unique "redeem" function.

**III. Oracle & AI Integration**
   - Dedicated interfaces for a trusted AI oracle to interact with the contract, enabling AI-generated lore updates for shards and influencing the contract's global narrative state based on external data.

**IV. Weaver XP (Reputation System)**
   - Functions for users to earn, track, claim, and delegate "Weaver XP," serving as an on-chain reputation metric that grants voting power and influences shard interactions.

**V. Governance (Simplified DAO)**
   - A module allowing the community, empowered by their Weaver XP, to propose, vote on, and execute significant changes to the contract's parameters or narrative direction.

### Function Summary:

1.  **`constructor(address _initialOracleAddress)`**: Initializes the contract, setting the owner and the initial trusted AI oracle address.
2.  **`setOracleAddress(address _newOracleAddress)`**: Allows the contract owner to update the trusted AI oracle address.
3.  **`pauseContract()`**: An emergency function callable by the owner to pause all sensitive operations, preventing further state changes.
4.  **`unpauseContract()`**: Callable by the owner to unpause the contract and resume normal operations.
5.  **`withdrawFunds()`**: Allows the contract owner to withdraw any accumulated ETH fees from contract interactions (e.g., nurture costs).
6.  **`mintInitialShard(address _to, string calldata _initialTraitDNA)`**: Mints a brand new Aether Shard to a specified address with an initial set of descriptive traits, marking the beginning of its journey.
7.  **`getShardDetails(uint256 _shardId)`**: A public view function to retrieve the current state, evolution stage, traits, and lore information of any given Aether Shard.
8.  **`nurtureShard(uint256 _shardId)`**: Allows an Aether Shard owner to "nurture" their shard by sending a small amount of Ether, increasing its `nurtureCount` and potential for evolution.
9.  **`evolveShard(uint256 _shardId)`**: Triggers the evolution process for a shard. Its success and the resulting new traits/stage are influenced by its `nurtureCount`, the owner's `WeaverXP`, and the contract's `currentGlobalMood`.
10. **`mergeShards(uint256 _shardId1, uint256 _shardId2)`**: Enables the combination of two Aether Shards. One shard is typically sacrificed, while the primary shard potentially gains new traits or advances, with the outcome dynamically influenced by the shards' properties and a pseudo-random seed.
11. **`requestLoreUpdate(uint256 _shardId)`**: Allows a shard owner to request the AI oracle to generate updated narrative lore for their shard, reflecting its current evolution and traits. Requires a small fee.
12. **`updateShardLore(uint256 _shardId, string calldata _newLoreHash, string calldata _newDescription)`**: A function callable *only by the trusted oracle* to commit AI-generated lore details (IPFS hash and a short description) to a specific shard.
13. **`classifyEventData(string calldata _eventContext, uint256 _classificationId)`**: A function callable *only by the trusted oracle* to inject external event classifications or sentiment, which directly influences the `currentGlobalMood` of the Aether Weaver universe, impacting shard evolution and other dynamics.
14. **`getWeaverXP(address _user)`**: A public view function to query the total Weaver XP (claimed + unclaimed) balance for any given user address.
15. **`claimWeaverXP()`**: Allows users to claim their accumulated `unclaimedWeaverXP` earned from interactions like minting, nurturing, or evolving shards, moving it to their `weaverXP` balance.
16. **`delegateWeaverXP(address _delegatee)`**: Enables a user to delegate their `WeaverXP` voting power to another address for governance proposals, without transferring the underlying XP.
17. **`proposeNarrativeShift(string calldata _description, bytes calldata _callData)`**: Allows users with a sufficient amount of `WeaverXP` to create a new governance proposal, specifying a description and the encoded function call to be executed if the proposal passes.
18. **`voteOnProposal(uint256 _proposalId, bool _vote)`**: Allows users (or their designated delegates) to cast a 'yes' or 'no' vote on an active proposal, with their `WeaverXP` acting as their voting power.
19. **`executeProposal(uint256 _proposalId)`**: Triggers the execution of a governance proposal that has successfully passed its voting period, met the quorum, and received more 'yes' votes than 'no' votes.
20. **`redeemShardForResources(uint256 _shardId)`**: Allows a shard owner to "redeem" or "disenchant" a shard, burning it in exchange for a dynamic amount of Ether. The redemption reward is influenced by the shard's evolution stage and, potentially, its traits.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Core Infrastructure & Access Control
//    - Owner-controlled functions for contract management (pause, unpause, withdraw, set oracle).
// II. Aether Shard (ERC721) Management
//    - Functions related to the lifecycle and interaction with Aether Shards (dynamic NFTs).
//    - Includes minting, nurturing, evolving, merging, and strategic redemption.
// III. Oracle & AI Integration
//    - Dedicated functions for a trusted AI oracle to feed data and insights into the contract, influencing shard lore and global narrative.
// IV. Weaver XP (Reputation System)
//    - Functions for users to earn, view, and potentially delegate their Weaver XP, which signifies their engagement and influence.
// V. Governance (Simplified DAO)
//    - Functions for community members to propose, vote on, and execute significant narrative shifts or parameter changes.

// Function Summary:
// 1. constructor(): Initializes the contract, setting the owner and base parameters.
// 2. setOracleAddress(address _newOracleAddress): Allows the owner to update the trusted AI oracle address.
// 3. pauseContract(): Owner function to pause all sensitive operations in an emergency.
// 4. unpauseContract(): Owner function to unpause the contract.
// 5. withdrawFunds(): Allows the owner to withdraw accumulated fees from contract interactions.
// 6. mintInitialShard(address _to, string calldata _initialTraitDNA): Mints a new Aether Shard to an address with an initial set of traits.
// 7. getShardDetails(uint256 _shardId): Public view function to retrieve the current state and details of a specific Aether Shard.
// 8. nurtureShard(uint256 _shardId): Allows a shard owner to "nurture" their shard, investing resources (ether) to boost its evolution potential.
// 9. evolveShard(uint256 _shardId): Triggers the evolution process for a shard, potentially advancing its stage and altering traits based on nurture, XP, and global mood.
// 10. mergeShards(uint256 _shardId1, uint256 _shardId2): Allows two shards to be combined, potentially destroying one and transforming the other based on complex rules and AI influence.
// 11. requestLoreUpdate(uint256 _shardId): User requests the oracle to generate updated narrative lore for their shard, reflecting its current state and evolution.
// 12. updateShardLore(uint256 _shardId, string calldata _newLoreHash, string calldata _newDescription): Oracle-only function to commit AI-generated lore details to a shard.
// 13. classifyEventData(string calldata _eventContext, uint256 _classificationId): Oracle-only function to inject external event classification/sentiment, influencing the global narrative mood.
// 14. getWeaverXP(address _user): Public view function to retrieve the Weaver XP balance for a given user.
// 15. claimWeaverXP(): Allows users to claim accumulated Weaver XP based on their interactions and contributions.
// 16. delegateWeaverXP(address _delegatee): Allows a user to delegate their voting power (XP) to another address for governance purposes.
// 17. proposeNarrativeShift(string calldata _description, bytes calldata _callData): Allows users with sufficient XP to propose a governance action to change contract parameters or global narrative.
// 18. voteOnProposal(uint256 _proposalId, bool _vote): Allows users (or their delegates) to cast votes on active proposals using their XP as voting power.
// 19. executeProposal(uint256 _proposalId): Triggers the execution of a passed and finalized governance proposal.
// 20. redeemShardForResources(uint256 _shardId): Allows a shard owner to "redeem" or "disenchant" a shard, burning it in exchange for a dynamic amount of resources (e.g., Ether), influenced by its evolution stage and traits.

contract AetherWeaver is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- Events ---
    event ShardMinted(uint256 indexed shardId, address indexed owner, string initialTraitDNA);
    event ShardNurtured(uint256 indexed shardId, address indexed nurturer, uint256 amountNurtured);
    event ShardEvolved(uint256 indexed shardId, uint256 newEvolutionStage, string newTraitDNA);
    event ShardMerged(uint256 indexed primaryShardId, uint256 indexed sacrificedShardId, string newTraitDNA);
    event ShardLoreUpdated(uint256 indexed shardId, string newLoreHash, string newDescription);
    event GlobalMoodUpdated(uint256 indexed classificationId, GlobalNarrativeMood newMood);
    event WeaverXPClaimed(address indexed user, uint256 amount);
    event WeaverXPDelegated(address indexed delegator, address indexed delegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event ShardRedeemed(uint256 indexed shardId, address indexed redeemer, uint256 redeemedAmount);

    // --- Enums & Structs ---
    enum GlobalNarrativeMood { NEUTRAL, OPTIMISTIC, PESSIMISTIC, CHAOTIC }

    struct ShardDetails {
        uint256 evolutionStage;       // Current stage of evolution (e.g., 0=egg, 1=larva, 2=juvenile, 3=mature)
        string traitDNA;              // A string representation of the shard's current traits (e.g., "body:crystalline,eyes:fiery")
        string currentLoreHash;       // IPFS CID or similar hash pointing to detailed AI-generated lore
        string currentLoreDescription; // Short, on-chain summary of the lore
        uint256 nurtureCount;         // How many times this shard has been nurtured
        uint256 lastNurtureTime;      // Timestamp of the last nurture
        uint256 mintedTime;           // Timestamp of minting
    }

    struct Proposal {
        string description;
        bytes callData;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---
    uint256 public nextShardId;
    mapping(uint256 => ShardDetails) public shardDetails;
    address public oracleAddress;
    GlobalNarrativeMood public currentGlobalMood;

    // Weaver XP & Delegation
    mapping(address => uint256) public weaverXP; // Raw XP earned (claimed XP, used for voting)
    mapping(address => uint256) public unclaimedWeaverXP; // XP waiting to be claimed
    mapping(address => address) public xpDelegates; // Delegatee for voting power

    // Governance
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Example voting period
    uint256 public constant MIN_XP_FOR_PROPOSAL = 1000; // Minimum XP to create a proposal
    
    // Total XP in circulation (a simplified metric for quorum calculation for this example)
    // In a real DAO, this would be dynamically calculated from all claimed XP or a governance token's total supply.
    uint256 public totalWeaverXPSupply; 
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 10; // 10% of total XP needed for quorum

    // Fees & Costs
    uint252 public constant NURTURE_COST = 0.01 ether; // Cost to nurture a shard
    uint252 public constant LORE_UPDATE_REQUEST_COST = 0.05 ether; // Cost for a user to request lore update

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracleAddress) ERC721("Aether Shard", "AESHD") Ownable(msg.sender) {
        require(_initialOracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _initialOracleAddress;
        currentGlobalMood = GlobalNarrativeMood.NEUTRAL;
        nextShardId = 1; // Start Shard IDs from 1
        nextProposalId = 1;
        totalWeaverXPSupply = 0; // Initialize total XP
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Allows the owner to set or update the trusted AI oracle address.
    /// @param _newOracleAddress The new address of the AI oracle.
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    /// @notice Allows the owner to pause critical contract functions in an emergency.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract, resuming operations.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated ETH fees from the contract.
    function withdrawFunds() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Withdrawal failed");
    }

    // --- II. Aether Shard (ERC721) Management ---

    /// @notice Mints a new Aether Shard to a specified address.
    /// @param _to The address to mint the shard to.
    /// @param _initialTraitDNA The initial string representation of the shard's traits.
    /// @return The ID of the newly minted shard.
    function mintInitialShard(address _to, string calldata _initialTraitDNA) external whenNotPaused returns (uint256) {
        require(_to != address(0), "Mint to the zero address");
        uint256 shardId = nextShardId;
        
        _safeMint(_to, shardId);

        shardDetails[shardId] = ShardDetails({
            evolutionStage: 0, // Initial stage
            traitDNA: _initialTraitDNA,
            currentLoreHash: "", // To be set by oracle
            currentLoreDescription: "A nascent shard, awaiting its destiny.",
            nurtureCount: 0,
            lastNurtureTime: block.timestamp,
            mintedTime: block.timestamp
        });

        nextShardId++;
        _addWeaverXP(msg.sender, 50); // Reward minter with XP
        emit ShardMinted(shardId, _to, _initialTraitDNA);
        return shardId;
    }

    /// @notice Public view function to retrieve the details of a specific Aether Shard.
    /// @param _shardId The ID of the shard.
    /// @return A tuple containing all shard details.
    function getShardDetails(uint256 _shardId) external view returns (ShardDetails memory) {
        _checkShardExists(_shardId);
        return shardDetails[_shardId];
    }

    /// @notice Allows a shard owner to "nurture" their shard, investing ETH to boost its evolution potential.
    /// Nurturing increases its nurtureCount, which is a factor in evolution.
    /// @param _shardId The ID of the shard to nurture.
    function nurtureShard(uint256 _shardId) external payable whenNotPaused {
        _checkShardOwnership(_shardId, msg.sender);
        require(msg.value >= NURTURE_COST, "Insufficient ETH for nurturing");

        // Simple cooldown to prevent spamming nurture
        require(block.timestamp >= shardDetails[_shardId].lastNurtureTime + 1 hours, "Shard is on nurture cooldown (1 hour)");

        shardDetails[_shardId].nurtureCount++;
        shardDetails[_shardId].lastNurtureTime = block.timestamp;

        _addWeaverXP(msg.sender, 10); // Reward with XP for nurturing
        emit ShardNurtured(_shardId, msg.sender, msg.value);
    }

    /// @notice Triggers the evolution process for a shard.
    /// Evolution is influenced by nurture count, owner's XP, and the global narrative mood.
    /// @param _shardId The ID of the shard to evolve.
    function evolveShard(uint256 _shardId) external whenNotPaused {
        _checkShardOwnership(_shardId, msg.sender);
        ShardDetails storage shard = shardDetails[_shardId];

        // Basic evolution conditions (can be more complex)
        require(shard.nurtureCount >= 5, "Shard requires at least 5 nurtures to attempt evolution");
        require(weaverXP[msg.sender] >= 100, "Owner requires at least 100 XP to facilitate evolution");
        
        // Pseudo-randomness influenced by block data and global mood
        // block.prevrandao replaced block.difficulty in Ethereum after The Merge
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _shardId, shard.nurtureCount, currentGlobalMood)));
        
        uint256 newStage = shard.evolutionStage;
        string memory newTraitDNA = shard.traitDNA;

        bool evolved = false;
        // Example evolution logic based on current stage and pseudo-randomness
        if (newStage == 0 && (randSeed % 100) < 60) { // 60% chance to evolve from stage 0
            newStage = 1;
            newTraitDNA = _deriveNewTraits(shard.traitDNA, newStage, randSeed);
            _addWeaverXP(msg.sender, 20);
            evolved = true;
        } else if (newStage == 1 && (randSeed % 100) < 40) { // 40% chance from stage 1
            newStage = 2;
            newTraitDNA = _deriveNewTraits(shard.traitDNA, newStage, randSeed);
            _addWeaverXP(msg.sender, 30);
            evolved = true;
        } else if (newStage == 2 && (randSeed % 100) < 20) { // 20% chance from stage 2
            newStage = 3;
            newTraitDNA = _deriveNewTraits(shard.traitDNA, newStage, randSeed);
            _addWeaverXP(msg.sender, 50);
            evolved = true;
        }

        require(evolved, "Shard did not evolve this time. Try nurturing more or waiting for a different global mood.");

        shard.evolutionStage = newStage;
        shard.traitDNA = newTraitDNA;
        shard.nurtureCount = 0; // Reset nurture count after successful evolution
        shard.lastNurtureTime = block.timestamp; // Reset cooldown

        emit ShardEvolved(_shardId, newStage, newTraitDNA);
    }

    /// @notice Allows two shards to be combined (merged), consuming one and transforming the other.
    /// The outcome is influenced by the shards' traits, evolution stages, and global mood.
    /// @param _shardId1 The ID of the primary shard (will be kept/transformed).
    /// @param _shardId2 The ID of the sacrificed shard (will be burned).
    function mergeShards(uint256 _shardId1, uint256 _shardId2) external whenNotPaused {
        _checkShardOwnership(_shardId1, msg.sender);
        _checkShardOwnership(_shardId2, msg.sender);
        require(_shardId1 != _shardId2, "Cannot merge a shard with itself");

        ShardDetails storage shard1 = shardDetails[_shardId1];
        ShardDetails storage shard2 = shardDetails[_shardId2];

        // Determine outcome based on internal logic and pseudo-randomness
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _shardId1, _shardId2, shard1.evolutionStage, shard2.evolutionStage, currentGlobalMood)));
        
        string memory newTraitDNA = _determineMergedTraits(shard1.traitDNA, shard2.traitDNA, randSeed);
        uint256 newStage = shard1.evolutionStage; 

        // Example merge success/failure probability
        if ((randSeed % 100) < 70) { // 70% chance of successful merge
            if (shard2.evolutionStage > shard1.evolutionStage && shard1.evolutionStage < 3) {
                 // If sacrificed shard is higher stage, potentially boost primary shard's stage
                newStage = shard1.evolutionStage + 1;
            }
            shard1.traitDNA = newTraitDNA;
            shard1.evolutionStage = newStage;
            _burn(_shardId2); // Burn the sacrificed shard
            _addWeaverXP(msg.sender, 40); // Reward for successful merge
            emit ShardMerged(_shardId1, _shardId2, newTraitDNA);
        } else {
            // Merge failed: Shard2 is still burned, but Shard1 gets negative effect or no change.
            _burn(_shardId2);
            _addWeaverXP(msg.sender, 5); // Small consolation XP for attempt
            // In a real scenario, you might add a "scar" trait or decrease nurtureCount on shard1 for failure
            emit ShardMerged(_shardId1, _shardId2, "Merge failed: Sacrificed shard lost, primary unchanged."); 
        }
    }

    /// @notice Allows a user to request the AI oracle to generate updated narrative lore for their shard.
    /// This is an on-chain request that triggers an off-chain AI process.
    /// @param _shardId The ID of the shard for which to request lore.
    function requestLoreUpdate(uint256 _shardId) external payable whenNotPaused {
        _checkShardOwnership(_shardId, msg.sender);
        require(msg.value >= LORE_UPDATE_REQUEST_COST, "Insufficient ETH for lore update request");

        // Emit an event that the oracle can listen to, containing shard details for AI context
        // The oracle would then call updateShardLore with the AI-generated data.
        emit ShardLoreUpdated(_shardId, "REQUESTED", "Lore update requested by owner. Awaiting oracle response.");
    }

    // --- III. Oracle & AI Integration ---

    /// @notice Callable only by the trusted oracle. Updates a shard's narrative lore and description.
    /// @param _shardId The ID of the shard to update.
    /// @param _newLoreHash The IPFS CID or hash pointing to the full new lore.
    /// @param _newDescription A short, on-chain summary of the new lore.
    function updateShardLore(uint256 _shardId, string calldata _newLoreHash, string calldata _newDescription) external onlyOracle {
        _checkShardExists(_shardId);
        shardDetails[_shardId].currentLoreHash = _newLoreHash;
        shardDetails[_shardId].currentLoreDescription = _newDescription;
        emit ShardLoreUpdated(_shardId, _newLoreHash, _newDescription);
    }

    /// @notice Callable only by the trusted oracle. Injects external event classification/sentiment,
    /// which influences the global narrative mood of the Aether Weaver universe.
    /// @param _eventContext A description or identifier of the external event. (Not stored, for oracle context only)
    /// @param _classificationId A numerical ID representing the classification (e.g., 0=Neutral, 1=Optimistic).
    function classifyEventData(string calldata _eventContext, uint256 _classificationId) external onlyOracle {
        require(_classificationId < uint256(type(GlobalNarrativeMood).max), "Invalid classification ID");
        currentGlobalMood = GlobalNarrativeMood(_classificationId);
        emit GlobalMoodUpdated(_classificationId, currentGlobalMood);
    }

    // --- IV. Weaver XP (Reputation System) ---

    /// @notice Public view function to retrieve the Weaver XP balance for a given user.
    /// @param _user The address of the user.
    /// @return The total Weaver XP for the user (claimed + unclaimed).
    function getWeaverXP(address _user) external view returns (uint256) {
        return weaverXP[_user] + unclaimedWeaverXP[_user];
    }

    /// @notice Allows users to claim accumulated Weaver XP based on their interactions.
    function claimWeaverXP() external {
        uint256 amount = unclaimedWeaverXP[msg.sender];
        require(amount > 0, "No unclaimed XP to claim");
        unclaimedWeaverXP[msg.sender] = 0;
        weaverXP[msg.sender] += amount;
        totalWeaverXPSupply += amount; // Update total supply when XP is claimed
        emit WeaverXPClaimed(msg.sender, amount);
    }

    /// @notice Allows a user to delegate their voting power (XP) to another address.
    /// Delegation is only for governance voting.
    /// @param _delegatee The address to delegate XP to.
    function delegateWeaverXP(address _delegatee) external {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        xpDelegates[msg.sender] = _delegatee;
        emit WeaverXPDelegated(msg.sender, _delegatee);
    }

    // --- V. Governance (Simplified DAO) ---

    /// @notice Allows users with sufficient XP to propose a governance action.
    /// @param _description A description of the proposal.
    /// @param _callData The encoded function call (target address, function selector, arguments) to execute if the proposal passes.
    ///                  Example: `abi.encodeWithSelector(ERC721.approve.selector, _spender, _tokenId)`
    function proposeNarrativeShift(string calldata _description, bytes calldata _callData) external whenNotPaused {
        require(weaverXP[msg.sender] >= MIN_XP_FOR_PROPOSAL, "Not enough XP to propose");
        uint256 proposalId = nextProposalId;
        
        proposals[proposalId] = Proposal({
            description: _description,
            callData: _callData,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });
        nextProposalId++;
        
        // Mark hasVoted for the proposer to prevent them voting twice on their own proposal
        proposals[proposalId].hasVoted[msg.sender] = true; 
        
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows users (or their delegates) to cast votes on active proposals.
    /// Voting power is based on the delegator's XP at the time of voting.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");

        address voterAddress = msg.sender;
        // If the sender has delegated their XP, use the delegatee's address for tracking purposes.
        // The XP used for voting will be that of the original delegator.
        if (xpDelegates[msg.sender] != address(0)) {
            voterAddress = xpDelegates[msg.sender]; 
        }

        require(!proposal.hasVoted[voterAddress], "Already voted on this proposal");
        uint256 votingPower = weaverXP[voterAddress]; // Use actual XP balance of the voter or delegate
        require(votingPower > 0, "No XP to vote with");

        proposal.hasVoted[voterAddress] = true;

        if (_vote) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        emit VoteCast(_proposalId, voterAddress, _vote);
    }

    /// @notice Triggers the execution of a passed and finalized governance proposal.
    /// Requires the voting period to be over and the proposal to have met quorum and passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        // Quorum check: total votes must meet a percentage of the total known XP supply.
        // This is a simplified quorum. A truly decentralized quorum would sum up all XP holders' balances.
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 requiredQuorum = (totalWeaverXPSupply * PROPOSAL_QUORUM_PERCENT) / 100;
        
        require(totalVotes >= requiredQuorum, "Quorum not met");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass (more 'No' votes or tied)");

        proposal.passed = true;
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "Proposal execution failed");
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows a shard owner to "redeem" or "disenchant" a shard, burning it
    /// in exchange for a dynamic amount of Ether, influenced by its evolution stage and traits.
    /// @param _shardId The ID of the shard to redeem.
    function redeemShardForResources(uint256 _shardId) external whenNotPaused {
        _checkShardOwnership(_shardId, msg.sender);
        ShardDetails storage shard = shardDetails[_shardId];

        uint256 rewardAmount = 0;
        // Base reward + bonus for evolution stage
        rewardAmount += 0.005 ether; // Base redemption value
        if (shard.evolutionStage == 1) rewardAmount += 0.005 ether;
        if (shard.evolutionStage == 2) rewardAmount += 0.01 ether;
        if (shard.evolutionStage == 3) rewardAmount += 0.02 ether;

        // Ensure there are enough funds in the contract to cover the redemption
        require(address(this).balance >= rewardAmount, "Not enough funds in contract for redemption");

        _burn(_shardId); // ERC721 burn
        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "Failed to send redemption reward");

        _addWeaverXP(msg.sender, 15); // Reward for strategic shard management
        emit ShardRedeemed(_shardId, msg.sender, rewardAmount);
    }


    // --- Internal/Private Helper Functions ---

    /// @dev Internal function to add XP to a user's unclaimed balance.
    /// @param _user The address to add XP to.
    /// @param _amount The amount of XP to add.
    function _addWeaverXP(address _user, uint256 _amount) internal {
        unclaimedWeaverXP[_user] += _amount;
        // totalWeaverXPSupply is only incremented when XP is claimed,
        // to simplify quorum calculation based on "active" XP.
    }

    /// @dev Internal helper to check if a shard exists.
    function _checkShardExists(uint256 _shardId) internal view {
        require(_exists(_shardId), "Shard does not exist");
    }

    /// @dev Internal helper to check if msg.sender owns the shard.
    function _checkShardOwnership(uint256 _shardId, address _owner) internal view {
        require(ownerOf(_shardId) == _owner, "Not the shard owner");
    }

    /// @dev Internal logic to derive new traits based on evolution stage and randomness.
    /// This is a simplified placeholder; actual trait generation would be more complex
    /// and likely involve parsing or more structured data.
    /// @param _currentDNA The current trait string of the shard.
    /// @param _newStage The new evolution stage.
    /// @param _seed A random seed for trait variation.
    /// @return A new trait string.
    function _deriveNewTraits(string memory _currentDNA, uint256 _newStage, uint256 _seed) internal pure returns (string memory) {
        if (_newStage == 1) return string(abi.encodePacked(_currentDNA, ",stage1_trait-", (_seed % 100).toString()));
        if (_newStage == 2) return string(abi.encodePacked(_currentDNA, ",stage2_trait-", (_seed % 100).toString()));
        if (_newStage == 3) return string(abi.encodePacked(_currentDNA, ",stage3_trait-", (_seed % 100).toString()));
        return _currentDNA;
    }

    /// @dev Internal logic to determine merged traits. Placeholder for complex trait blending.
    /// Actual logic would likely involve more sophisticated string parsing or structured trait IDs.
    /// @param _dna1 The trait string of the primary shard.
    /// @param _dna2 The trait string of the sacrificed shard.
    /// @param _seed A random seed for merge outcome variation.
    /// @return A new trait string representing the merged outcome.
    function _determineMergedTraits(string memory _dna1, string memory _dna2, uint256 _seed) internal pure returns (string memory) {
        // Simple concatenation for example. Real logic would parse, combine, and mutate.
        string memory combined = string(abi.encodePacked(_dna1, ";", _dna2));
        if (_seed % 2 == 0) {
            return string(abi.encodePacked(combined, ":fused_effect:positive"));
        } else {
            return string(abi.encodePacked(combined, ":fused_effect:neutral"));
        }
    }
}
```