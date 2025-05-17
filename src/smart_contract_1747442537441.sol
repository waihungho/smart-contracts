Okay, let's design a smart contract called `MetaMorph` that manages dynamic, evolving NFTs (ERC721) powered by a custom fungible token (ERC20) representing "Evolutionary Energy". The NFTs can be staked to earn energy, fused together, or evolved using energy, and the system includes a basic governance mechanism for rule changes.

This contract combines elements of NFTs, ERC20 utility tokens, staking, resource management, dynamic state changes, and on-chain governance, aiming for an advanced and creative blend beyond standard implementations.

**Disclaimer:** This is a complex example for educational purposes. Deploying such a contract requires extensive auditing, gas optimization, and careful consideration of economic model design. On-chain randomness and true external data influence (oracles) are simplified or simulated here.

---

**Outline & Function Summary**

**Contract:** `MetaMorph`

**Core Concept:** A system managing dynamic NFTs (`MetaMorphs`) that possess evolving traits and stages. Interaction with MetaMorphs (staking, fusion, evolution) requires and produces a fungible token (`Evolutionary Energy`). The system parameters can be influenced by a simple on-chain governance mechanism.

**Inherited Standards:**
*   ERC721 / ERC721Metadata: For the MetaMorph NFTs.
*   ERC20: For the Evolutionary Energy token.
*   Ownable: Basic contract ownership.

**State Variables:**
*   NFT state (owner, approvals, balance, etc.)
*   MetaMorph specific data (structs for traits, stages, staking info)
*   ERC20 state (balances, allowances, total supply)
*   System parameters (fusion cost, evolution cost, energy per block, trait modifiers)
*   Governance data (proposals, vote counts, voter status)
*   Counters (total NFTs minted, proposal IDs)

**Structs:**
*   `Trait`: Defines a specific characteristic of a MetaMorph.
*   `MetaMorphData`: Stores dynamic data for each NFT (traits, stage, energy earned, stake status).
*   `Proposal`: Represents a governance proposal.

**Enums:**
*   `TraitType`: Defines categories of traits (e.g., FIRE, WATER, AIR).
*   `ProposalState`: Defines the status of a proposal.

**Events:**
*   Standard ERC721/ERC20 events.
*   `MetaMorphMinted`: When a new MetaMorph is created.
*   `MetaMorphStaked`: When an NFT is staked.
*   `MetaMorphUnstaked`: When an NFT is unstaked.
*   `EnergyClaimed`: When staked energy is claimed.
*   `MetaMorphFused`: When MetaMorphs are fused.
*   `MetaMorphEvolved`: When a MetaMorph evolves.
*   `EnvironmentalEffectApplied`: When the simulation modifies parameters.
*   `ProposalCreated`: When a governance proposal is made.
*   `Voted`: When a user casts a vote.
*   `ProposalExecuted`: When a proposal's action is performed.

**Function Summary (Approx. 40 functions including standard ERC721/ERC20):**

**ERC721 Standard Functions (9):**
1.  `balanceOf(address owner)`: Get number of NFTs owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get owner of a specific NFT.
3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer NFT ownership.
4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
5.  `transferFrom(address from, address to, uint256 tokenId)`: Unsafe transfer NFT ownership.
6.  `approve(address to, uint256 tokenId)`: Approve address to manage an NFT.
7.  `setApprovalForAll(address operator, bool approved)`: Set operator approval for all NFTs.
8.  `getApproved(uint256 tokenId)`: Get the approved address for an NFT.
9.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved.

**ERC721Metadata Standard Functions (2):**
10. `name()`: Get NFT collection name.
11. `symbol()`: Get NFT collection symbol.

**ERC165 Standard Function (1):**
12. `supportsInterface(bytes4 interfaceId)`: Check interface support.

**ERC20 Standard Functions (6):**
13. `totalSupply()`: Get total supply of ENERGY tokens.
14. `balanceOf(address account)`: Get ENERGY balance of an account.
15. `transfer(address to, uint256 amount)`: Transfer ENERGY tokens.
16. `transferFrom(address from, address to, uint256 amount)`: Transfer ENERGY using allowance.
17. `approve(address spender, uint256 amount)`: Approve spender for ENERGY transfer.
18. `allowance(address owner, address spender)`: Get allowance granted.

**MetaMorph Core Functions (Dynamic State, Staking, Fusion, Evolution):**
19. `mintMetaMorph(address recipient)`: Owner mints a new MetaMorph with initial traits.
20. `getMetaMorphData(uint256 tokenId)`: Get all dynamic data for a MetaMorph (view).
21. `getMetaMorphTraits(uint256 tokenId)`: Get traits of a MetaMorph (view).
22. `getMetaMorphStage(uint256 tokenId)`: Get evolution stage (view).
23. `stakeMetaMorph(uint256 tokenId)`: Stake a MetaMorph to earn ENERGY.
24. `unstakeMetaMorph(uint256 tokenId)`: Unstake a MetaMorph.
25. `claimStakedEnergy(uint256 tokenId)`: Claim earned ENERGY for a staked/unstaked NFT.
26. `calculatePendingEnergy(uint256 tokenId)`: Calculate ENERGY earned but not claimed (view).
27. `fuseMetaMorphs(uint256 tokenId1, uint256 tokenId2)`: Fuse two MetaMorphs into a new one (burns originals, consumes ENERGY).
28. `evolveMetaMorph(uint256 tokenId)`: Evolve a MetaMorph to the next stage (consumes ENERGY).
29. `burnMetaMorph(uint256 tokenId)`: Owner of NFT can burn it (optional).
30. `setEvolutionCost(uint256 stage, uint256 cost)`: Owner sets ENERGY cost for evolving to a stage.
31. `setFusionCost(uint256 cost)`: Owner sets base ENERGY cost for fusion.
32. `setEnergyPerBlock(uint256 amount)`: Owner sets base ENERGY earned per block staked.

**MetaMorph Environmental Simulation (Owner-controlled for simplicity):**
33. `simulateEnvironmentalEffect(TraitType _type, int256 _modifier)`: Owner applies a global modifier affecting traits or energy gain of a specific type.

**Governance Functions:**
34. `proposeRuleChange(string description, bytes callData)`: Propose a change (encoded function call). Requires minimum ENERGY balance.
35. `voteOnProposal(uint256 proposalId, bool support)`: Vote for or against a proposal. Voting power based on ENERGY balance.
36. `executeProposal(uint256 proposalId)`: Execute a passed proposal after the voting period ends.
37. `getProposalDetails(uint256 proposalId)`: View details of a proposal.
38. `getVoteCount(uint256 proposalId)`: View vote counts for a proposal.
39. `getVoterStatus(uint256 proposalId, address voter)`: Check if an address has voted on a proposal.

**Additional Utility Functions:**
40. `getMetaMorphCount()`: Get total number of MetaMorphs minted (view).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline & Function Summary
//
// Contract: MetaMorph
// Core Concept: A system managing dynamic NFTs (MetaMorphs) that possess evolving traits and stages.
// Interaction with MetaMorphs (staking, fusion, evolution) requires and produces a
// fungible token (Evolutionary Energy). The system parameters can be influenced by
// a simple on-chain governance mechanism.
//
// Inherited Standards:
// - ERC721 / ERC721Enumerable: For the MetaMorph NFTs.
// - ERC20: For the Evolutionary Energy token.
// - Ownable: Basic contract ownership.
//
// State Variables:
// - NFT state (owner, approvals, balance, etc. - handled by inherited ERC721)
// - MetaMorph specific data (structs for traits, stages, staking info)
// - ERC20 state (balances, allowances, total supply - handled by inherited ERC20)
// - System parameters (fusion cost, evolution cost, energy per block, trait modifiers)
// - Governance data (proposals, vote counts, voter status)
// - Counters (total NFTs minted, proposal IDs)
//
// Structs:
// - Trait: Defines a specific characteristic of a MetaMorph.
// - MetaMorphData: Stores dynamic data for each NFT.
// - Proposal: Represents a governance proposal.
//
// Enums:
// - TraitType: Defines categories of traits.
// - ProposalState: Defines the status of a proposal.
//
// Events:
// - Standard ERC721/ERC20 events.
// - MetaMorphMinted: When a new MetaMorph is created.
// - MetaMorphStaked: When an NFT is staked.
// - MetaMorphUnstaked: When an NFT is unstaked.
// - EnergyClaimed: When staked energy is claimed.
// - MetaMorphFused: When MetaMorphs are fused.
// - MetaMorphEvolved: When a MetaMorph evolves.
// - EnvironmentalEffectApplied: When the simulation modifies parameters.
// - ProposalCreated: When a governance proposal is made.
// - Voted: When a user casts a vote.
// - ProposalExecuted: When a proposal's action is performed.
//
// Function Summary (Approx. 40 functions including standard ERC721/ERC20):
// ERC721 Standard Functions (9): balanceOf, ownerOf, safeTransferFrom(2), transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll
// ERC721Metadata Standard Functions (2): name, symbol
// ERC165 Standard Function (1): supportsInterface
// ERC20 Standard Functions (6): totalSupply, balanceOf, transfer, transferFrom, approve, allowance
// MetaMorph Core Functions (Dynamic State, Staking, Fusion, Evolution):
// 19. mintMetaMorph(address recipient)
// 20. getMetaMorphData(uint256 tokenId)
// 21. getMetaMorphTraits(uint256 tokenId)
// 22. getMetaMorphStage(uint256 tokenId)
// 23. stakeMetaMorph(uint256 tokenId)
// 24. unstakeMetaMorph(uint256 tokenId)
// 25. claimStakedEnergy(uint256 tokenId)
// 26. calculatePendingEnergy(uint256 tokenId)
// 27. fuseMetaMorphs(uint256 tokenId1, uint256 tokenId2)
// 28. evolveMetaMorph(uint256 tokenId)
// 29. burnMetaMorph(uint256 tokenId)
// 30. setEvolutionCost(uint256 stage, uint256 cost)
// 31. setFusionCost(uint256 cost)
// 32. setEnergyPerBlock(uint256 amount)
// MetaMorph Environmental Simulation (Owner-controlled for simplicity):
// 33. simulateEnvironmentalEffect(TraitType _type, int256 _modifier)
// Governance Functions:
// 34. proposeRuleChange(string description, bytes callData)
// 35. voteOnProposal(uint256 proposalId, bool support)
// 36. executeProposal(uint256 proposalId)
// 37. getProposalDetails(uint256 proposalId)
// 38. getVoteCount(uint256 proposalId)
// 39. getVoterStatus(uint256 proposalId, address voter)
// Additional Utility Functions:
// 40. getMetaMorphCount()


contract MetaMorph is ERC721Enumerable, ERC20, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    // --- ERC721 & ERC20 Standard Implementations ---
    // Inherited from OpenZeppelin

    // --- Custom Structs, Enums, and State ---

    enum TraitType { NONE, FIRE, WATER, EARTH, AIR, MYSTIC }
    uint256 public constant MAX_TRAIT_VALUE = 100;
    uint256 public constant MAX_STAGE = 5;

    struct Trait {
        TraitType traitType;
        int256 value; // Can be positive or negative, influenced by environment
        uint40 lastChangedTime; // Timestamp of last change
    }

    struct MetaMorphData {
        uint8 stage; // Evolution stage, starts at 1
        mapping(TraitType => Trait) traits; // Dynamic traits
        uint256 creationTime;
        // Staking data
        bool isStaked;
        uint40 lastStakedActionTime; // Timestamp of last stake/unstake/claim
        uint256 energyEarnedWhileStaked; // Cumulative energy earned from staking this NFT
    }

    mapping(uint256 => MetaMorphData) private _metaMorphData;
    Counters.Counter private _tokenIdCounter;

    // System Parameters
    uint256 public fusionEnergyCost = 500; // Base ENERGY cost to fuse
    mapping(uint8 => uint256) public evolutionEnergyCost; // ENERGY cost per stage
    uint256 public energyPerBlockStaked = 1; // Base ENERGY earned per staked MetaMorph per block

    mapping(TraitType => int256) public environmentalTraitModifiers; // Global modifiers from simulation

    // Governance
    struct Proposal {
        uint256 id;
        string description;
        address payable target; // Contract to call (usually self)
        bytes callData;       // Encoded function call
        uint256 creationTime;
        uint256 endTime;
        uint256 voteThreshold; // Minimum votes needed based on ENERGY supply
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Prevent double voting
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public minEnergyToPropose = 1000; // Minimum ENERGY to create a proposal
    uint256 public proposalVotingPeriod = 3 days; // Duration of voting

    // --- Events ---
    event MetaMorphMinted(uint256 tokenId, address indexed recipient);
    event MetaMorphStaked(uint256 tokenId, address indexed owner);
    event MetaMorphUnstaked(uint256 tokenId, address indexed owner, uint256 energyEarned);
    event EnergyClaimed(uint256 tokenId, address indexed owner, uint256 amount);
    event MetaMorphFused(uint256 tokenId1, uint256 tokenId2, uint256 newTokenId, address indexed owner);
    event MetaMorphEvolved(uint256 tokenId, uint8 newStage, uint256 energySpent);
    event EnvironmentalEffectApplied(TraitType indexed traitType, int256 modifierValue);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Constructor ---
    constructor() ERC721("MetaMorph", "MORPH") ERC20("Evolutionary Energy", "ENERGY") Ownable(msg.sender) {
        // Initial evolution costs
        evolutionEnergyCost[1] = 100;
        evolutionEnergyCost[2] = 300;
        evolutionEnergyCost[3] = 800;
        evolutionEnergyCost[4] = 2000;
        evolutionEnergyCost[5] = type(uint256).max; // Cannot evolve past max stage

        // Mint initial ENERGY supply (e.g., to owner for distribution/testing)
        _mint(msg.sender, 1000000 * (10 ** 18)); // 1 Million ENERGY tokens
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId) ||
               interfaceId == type(IERC20).interfaceId; // Also indicate ERC20 support
    }

    // --- MetaMorph Core Logic ---

    /// @notice Owner mints a new MetaMorph token.
    /// @param recipient The address to receive the new token.
    function mintMetaMorph(address recipient) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(recipient, newItemId);

        // Initialize MetaMorph data
        MetaMorphData storage data = _metaMorphData[newItemId];
        data.stage = 1;
        data.creationTime = uint40(block.timestamp);
        data.lastStakedActionTime = uint40(block.timestamp); // Initialize for staking calculations

        // Assign initial random-ish traits (simplified randomness)
        bytes32 entropy = keccak256(abi.encodePacked(newItemId, block.timestamp, block.difficulty, msg.sender));
        TraitType[] memory traitTypes = new TraitType[](5); // Use all 5 types
        traitTypes[0] = TraitType.FIRE;
        traitTypes[1] = TraitType.WATER;
        traitTypes[2] = TraitType.EARTH;
        traitTypes[3] = TraitType.AIR;
        traitTypes[4] = TraitType.MYSTIC;

        for(uint i = 0; i < traitTypes.length; i++) {
             // Deterministic value based on entropy and index
            int256 initialValue = int256(uint256(keccak256(abi.encodePacked(entropy, i))) % (MAX_TRAIT_VALUE + 1));
            data.traits[traitTypes[i]] = Trait({
                traitType: traitTypes[i],
                value: initialValue,
                lastChangedTime: uint40(block.timestamp)
            });
        }

        emit MetaMorphMinted(newItemId, recipient);
    }

    /// @notice Get all dynamic data for a specific MetaMorph token.
    /// @param tokenId The ID of the MetaMorph token.
    /// @return The MetaMorphData struct.
    function getMetaMorphData(uint256 tokenId) public view returns (MetaMorphData memory) {
        require(_exists(tokenId), "MetaMorph: token does not exist");
         // Must manually copy fields from storage mapping to memory for return
        MetaMorphData storage data = _metaMorphData[tokenId];
        MetaMorphData memory memoryData;
        memoryData.stage = data.stage;
        memoryData.creationTime = data.creationTime;
        memoryData.isStaked = data.isStaked;
        memoryData.lastStakedActionTime = data.lastStakedActionTime;
        memoryData.energyEarnedWhileStaked = data.energyEarnedWhileStaked;

        // Copy traits (requires explicit iteration)
        TraitType[] memory allTraitTypes = new TraitType[](5); // Assume 5 trait types
        allTraitTypes[0] = TraitType.FIRE;
        allTraitTypes[1] = TraitType.WATER;
        allTraitTypes[2] = TraitType.EARTH;
        allTraitTypes[3] = TraitType.AIR;
        allTraitTypes[4] = TraitType.MYSTIC;

        for(uint i = 0; i < allTraitTypes.length; i++) {
            memoryData.traits[allTraitTypes[i]] = data.traits[allTraitTypes[i]];
        }

        return memoryData;
    }

    /// @notice Get the traits of a specific MetaMorph token.
    /// @param tokenId The ID of the MetaMorph token.
    /// @return An array of Trait structs.
    function getMetaMorphTraits(uint256 tokenId) public view returns (Trait[] memory) {
         require(_exists(tokenId), "MetaMorph: token does not exist");
        MetaMorphData storage data = _metaMorphData[tokenId];
        TraitType[] memory allTraitTypes = new TraitType[](5); // Assume 5 trait types
        allTraitTypes[0] = TraitType.FIRE;
        allTraitTypes[1] = TraitType.WATER;
        allTraitTypes[2] = TraitType.EARTH;
        allTraitTypes[3] = TraitType.AIR;
        allTraitTypes[4] = TraitType.MYSTIC;

        Trait[] memory currentTraits = new Trait[](allTraitTypes.length);
         for(uint i = 0; i < allTraitTypes.length; i++) {
            currentTraits[i] = data.traits[allTraitTypes[i]];
        }
        return currentTraits;
    }

     /// @notice Get the evolution stage of a specific MetaMorph token.
    /// @param tokenId The ID of the MetaMorph token.
    /// @return The current stage (uint8).
    function getMetaMorphStage(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "MetaMorph: token does not exist");
         return _metaMorphData[tokenId].stage;
    }


    /// @notice Stake a MetaMorph token to earn ENERGY.
    /// @param tokenId The ID of the MetaMorph token to stake.
    function stakeMetaMorph(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "MetaMorph: caller is not owner or approved");
        MetaMorphData storage data = _metaMorphData[tokenId];
        require(!data.isStaked, "MetaMorph: token already staked");

        // Calculate and add any pending energy from previous staking periods
        uint256 pending = calculatePendingEnergy(tokenId);
        data.energyEarnedWhileStaked = data.energyEarnedWhileStaked.add(pending);

        data.isStaked = true;
        data.lastStakedActionTime = uint40(block.timestamp);

        // Transfer the NFT to the contract address to secure it while staked
        // This also prevents transfer/fusion/evolution while staked
        _transfer(_msgSender(), address(this), tokenId);

        emit MetaMorphStaked(tokenId, _msgSender());
    }

    /// @notice Unstake a MetaMorph token. Claims pending energy automatically.
    /// @param tokenId The ID of the MetaMorph token to unstake.
    function unstakeMetaMorph(uint256 tokenId) public {
        require(ownerOf(tokenId) == address(this), "MetaMorph: token not staked or not owned by contract");
        MetaMorphData storage data = _metaMorphData[tokenId];
        require(data.isStaked, "MetaMorph: token not currently staked");

        address originalOwner = address(bytes20(uint160(_tokenData[tokenId].owner))); // Nasty way to get owner from ERC721Enumerable internal data

        // Calculate and add pending energy
        uint256 pending = calculatePendingEnergy(tokenId);
        data.energyEarnedWhileStaked = data.energyEarnedWhileStaked.add(pending);

        data.isStaked = false;
        data.lastStakedActionTime = uint40(block.timestamp);

        // Transfer the NFT back to the original owner
        _transfer(address(this), originalOwner, tokenId);

        // Mint the earned energy to the owner
        _mint(originalOwner, data.energyEarnedWhileStaked);
        emit EnergyClaimed(tokenId, originalOwner, data.energyEarnedWhileStaked);

        data.energyEarnedWhileStaked = 0; // Reset cumulative earned energy

        emit MetaMorphUnstaked(tokenId, originalOwner, pending); // Emit pending for clarity
    }

     /// @notice Claim energy earned while staking a MetaMorph without unstaking.
    /// @param tokenId The ID of the MetaMorph token.
    function claimStakedEnergy(uint256 tokenId) public {
        require(ownerOf(tokenId) == address(this), "MetaMorph: token not staked or not owned by contract");
        MetaMorphData storage data = _metaMorphData[tokenId];
        require(data.isStaked, "MetaMorph: token not currently staked");

        address originalOwner = address(bytes20(uint160(_tokenData[tokenId].owner))); // Get owner

        uint256 pending = calculatePendingEnergy(tokenId);
        data.energyEarnedWhileStaked = data.energyEarnedWhileStaked.add(pending);
        data.lastStakedActionTime = uint40(block.timestamp); // Reset timer

        _mint(originalOwner, data.energyEarnedWhileStaked);
        emit EnergyClaimed(tokenId, originalOwner, data.energyEarnedWhileStaked);

        data.energyEarnedWhileStaked = 0; // Reset cumulative earned energy
    }

    /// @notice Calculate ENERGY earned by a staked MetaMorph since the last action.
    /// @param tokenId The ID of the MetaMorph token.
    /// @return The amount of pending ENERGY.
    function calculatePendingEnergy(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "MetaMorph: token does not exist");
        MetaMorphData storage data = _metaMorphData[tokenId];

        if (!data.isStaked) {
            return 0; // Only staked NFTs earn energy
        }

        uint256 blocksStaked = block.timestamp.sub(data.lastStakedActionTime);
        uint256 baseEnergy = blocksStaked.mul(energyPerBlockStaked);

        // Trait modifiers could influence energy gain (simplified: sum of trait values)
        int256 traitInfluence = 0;
         TraitType[] memory allTraitTypes = new TraitType[](5); // Assume 5 trait types
        allTraitTypes[0] = TraitType.FIRE;
        allTraitTypes[1] = TraitType.WATER;
        allTraitTypes[2] = TraitType.EARTH;
        allTraitTypes[3] = TraitType.AIR;
        allTraitTypes[4] = TraitType.MYSTIC;

         for(uint i = 0; i < allTraitTypes.length; i++) {
            traitInfluence += data.traits[allTraitTypes[i]].value;
        }

        // Apply trait influence (simplified: percentage modifier based on sum)
        // Example: trait sum of 100 = +10% energy, -50 = -5% energy. Needs careful balancing.
        // Avoid negative energy gain; cap at 0.
        int256 modifiedEnergy = int256(baseEnergy);
        modifiedEnergy = modifiedEnergy + (modifiedEnergy * traitInfluence / 1000); // Scale influence (e.g. sum 100 gives 10%)
        if (modifiedEnergy < 0) modifiedEnergy = 0;

        return uint256(modifiedEnergy);
    }


    /// @notice Fuse two MetaMorph tokens into a new, potentially higher-stage one.
    /// Burns the two input tokens. Requires ENERGY.
    /// @param tokenId1 The ID of the first MetaMorph token.
    /// @param tokenId2 The ID of the second MetaMorph token.
    function fuseMetaMorphs(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "MetaMorph: cannot fuse a token with itself");
        require(_isApprovedOrOwner(_msgSender(), tokenId1), "MetaMorph: caller is not owner or approved for token1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "MetaMorph: caller is not owner or approved for token2");

        MetaMorphData storage data1 = _metaMorphData[tokenId1];
        MetaMorphData storage data2 = _metaMorphData[tokenId2];
        require(!data1.isStaked && !data2.isStaked, "MetaMorph: cannot fuse staked tokens");

        uint256 requiredEnergy = fusionEnergyCost; // Could add complexity based on traits/stages

        // Require and burn ENERGY from the caller
        require(balanceOf(_msgSender()) >= requiredEnergy, "MetaMorph: Insufficient ENERGY balance");
        _burn(_msgSender(), requiredEnergy);

        // Burn the two input tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new token
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newTokenId);

        // Initialize new MetaMorph data (Simplified fusion logic)
        MetaMorphData storage newData = _metaMorphData[newTokenId];
        newData.creationTime = uint40(block.timestamp);
        newData.lastStakedActionTime = uint40(block.timestamp);

        // Determine new stage (e.g., average + potential stage up)
        uint8 avgStage = uint8((data1.stage + data2.stage) / 2);
        uint8 newStage = avgStage;
        bytes32 entropy = keccak256(abi.encodePacked(tokenId1, tokenId2, block.timestamp, block.difficulty));
        if (uint256(entropy) % 10 < (data1.stage + data2.stage)) { // Simplified chance based on stage
             if (newStage < MAX_STAGE) newStage++;
        }
        newData.stage = newStage;

        // Combine/randomize traits (Simplified: average traits with some random variation)
        TraitType[] memory allTraitTypes = new TraitType[](5);
        allTraitTypes[0] = TraitType.FIRE; allTraitTypes[1] = TraitType.WATER; allTraitTypes[2] = TraitType.EARTH; allTraitTypes[3] = TraitType.AIR; allTraitTypes[4] = TraitType.MYSTIC;

        for(uint i = 0; i < allTraitTypes.length; i++) {
            int256 avgValue = (data1.traits[allTraitTypes[i]].value + data2.traits[allTraitTypes[i]].value) / 2;
            int256 variation = int256(uint256(keccak256(abi.encodePacked(entropy, i, "fusion"))) % 21) - 10; // +/- 10 variation
            int256 finalValue = avgValue + variation;

            // Apply environmental modifier
            finalValue += environmentalTraitModifiers[allTraitTypes[i]];

            // Cap trait values
            if (finalValue > int256(MAX_TRAIT_VALUE)) finalValue = int256(MAX_TRAIT_VALUE);
            if (finalValue < -int256(MAX_TRAIT_VALUE)) finalValue = -int256(MAX_TRAIT_VALUE); // Allow negative traits

            newData.traits[allTraitTypes[i]] = Trait({
                traitType: allTraitTypes[i],
                value: finalValue,
                lastChangedTime: uint40(block.timestamp)
            });
        }

        emit MetaMorphFused(tokenId1, tokenId2, newTokenId, _msgSender());
    }

    /// @notice Evolve a MetaMorph to the next stage. Requires ENERGY.
    /// @param tokenId The ID of the MetaMorph token to evolve.
    function evolveMetaMorph(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "MetaMorph: caller is not owner or approved");
        MetaMorphData storage data = _metaMorphData[tokenId];
        require(!data.isStaked, "MetaMorph: cannot evolve staked tokens");
        require(data.stage < MAX_STAGE, "MetaMorph: already at max stage");

        uint8 nextStage = data.stage + 1;
        uint256 requiredEnergy = evolutionEnergyCost[nextStage];
        require(requiredEnergy > 0, "MetaMorph: Evolution cost not set for next stage");

        // Require and burn ENERGY from the caller
        require(balanceOf(_msgSender()) >= requiredEnergy, "MetaMorph: Insufficient ENERGY balance");
        _burn(_msgSender(), requiredEnergy);

        data.stage = nextStage;

        // Optional: Reroll/boost traits upon evolution
        bytes32 entropy = keccak256(abi.encodePacked(tokenId, block.timestamp, "evolve"));
        TraitType[] memory allTraitTypes = new TraitType[](5);
        allTraitTypes[0] = TraitType.FIRE; allTraitTypes[1] = TraitType.WATER; allTraitTypes[2] TraitType.EARTH; allTraitTypes[3] = TraitType.AIR; allTraitTypes[4] = TraitType.MYSTIC;

        for(uint i = 0; i < allTraitTypes.length; i++) {
            Trait storage trait = data.traits[allTraitTypes[i]];
            // Simplified: Boost traits slightly + add some randomness
            int256 boost = int256(data.stage * 2); // Higher stages boost more
            int256 randomness = int256(uint256(keccak256(abi.encodePacked(entropy, i, "traitboost"))) % 11) - 5; // +/- 5
            trait.value = trait.value + boost + randomness;

             // Apply environmental modifier
            trait.value += environmentalTraitModifiers[allTraitTypes[i]];

            // Cap trait values
            if (trait.value > int256(MAX_TRAIT_VALUE)) trait.value = int256(MAX_TRAIT_VALUE);
            if (trait.value < -int256(MAX_TRAIT_VALUE)) trait.value = -int256(MAX_TRAIT_VALUE);

            trait.lastChangedTime = uint40(block.timestamp);
        }


        emit MetaMorphEvolved(tokenId, nextStage, requiredEnergy);
    }

    /// @notice Allow owner of an NFT to burn it.
    /// @param tokenId The ID of the MetaMorph token to burn.
    function burnMetaMorph(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "MetaMorph: caller is not owner or approved");
        MetaMorphData storage data = _metaMorphData[tokenId];
        require(!data.isStaked, "MetaMorph: cannot burn staked tokens");

        _burn(tokenId);
        // Note: MetaMorphData remains in storage mapping, but the NFT ownership is gone.
        // Could potentially implement a mechanism to clear this data, but mapping deletion is gas-intensive.
    }

    /// @notice Owner sets the ENERGY cost for evolving to a specific stage.
    /// @param stage The target stage (must be > 1 and <= MAX_STAGE).
    /// @param cost The ENERGY cost.
    function setEvolutionCost(uint8 stage, uint256 cost) public onlyOwner {
        require(stage > 1 && stage <= MAX_STAGE, "MetaMorph: Invalid stage");
        evolutionEnergyCost[stage] = cost;
    }

    /// @notice Owner sets the base ENERGY cost for fusion.
    /// @param cost The base ENERGY cost.
    function setFusionCost(uint256 cost) public onlyOwner {
        fusionEnergyCost = cost;
    }

    /// @notice Owner sets the base ENERGY earned per block staked.
    /// @param amount The amount of ENERGY per block.
    function setEnergyPerBlock(uint256 amount) public onlyOwner {
        energyPerBlockStaked = amount;
    }

    // --- Environmental Simulation (Simplified) ---

    /// @notice Owner applies a global modifier that can affect specific trait types.
    /// This simulates external conditions influencing MetaMorph attributes.
    /// @param _type The TraitType affected.
    /// @param _modifier The value added/subtracted to traits of this type.
    function simulateEnvironmentalEffect(TraitType _type, int256 _modifier) public onlyOwner {
        require(_type != TraitType.NONE, "MetaMorph: Cannot modify NONE trait type");
        environmentalTraitModifiers[_type] = _modifier;
        // In a real system, this would ideally trigger trait re-calculation or influence
        // future calculations for all NFTs or a subset. This simplified version
        // just sets a global variable that fusion/evolution/energy calc can use.
        emit EnvironmentalEffectApplied(_type, _modifier);
    }

    // --- Governance Functions ---

    /// @notice Create a new governance proposal.
    /// Requires minimum ENERGY balance.
    /// @param description A brief description of the proposal.
    /// @param callData The ABI-encoded call data for the function to execute if the proposal passes.
    function proposeRuleChange(string memory description, bytes memory callData) public {
        require(balanceOf(_msgSender()) >= minEnergyToPropose, "Governance: Insufficient ENERGY to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        uint256 currentEnergySupply = totalSupply();
        // Simplified threshold: 5% of total supply must vote 'for' to pass
        uint256 requiredVotes = currentEnergySupply.mul(5).div(100);
        if (requiredVotes == 0 && currentEnergySupply > 0) requiredVotes = 1; // Minimum 1 vote if supply > 0


        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = description;
        proposal.target = payable(address(this)); // Proposals target this contract
        proposal.callData = callData;
        proposal.creationTime = block.timestamp;
        proposal.endTime = block.timestamp.add(proposalVotingPeriod);
        proposal.voteThreshold = requiredVotes; // Simplified threshold logic
        proposal.executed = false;
        // No initial votes, must call voteOnProposal separately

        emit ProposalCreated(proposalId, _msgSender(), description);
    }

    /// @notice Vote on an active governance proposal.
    /// Voting power is based on the voter's current ENERGY balance.
    /// @param proposalId The ID of the proposal.
    /// @param support True for 'for', False for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Governance: Invalid proposal ID");
        require(block.timestamp < proposal.endTime, "Governance: Voting period has ended");
        require(!proposal.executed, "Governance: Proposal already executed");
        require(!proposal.hasVoted[_msgSender()], "Governance: Already voted on this proposal");

        uint256 votingPower = balanceOf(_msgSender());
        require(votingPower > 0, "Governance: Must hold ENERGY to vote");

        proposal.hasVoted[_msgSender()] = true;

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        emit Voted(proposalId, _msgSender(), support, votingPower);
    }

    /// @notice Execute a governance proposal if it has passed and the voting period is over.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Governance: Invalid proposal ID");
        require(block.timestamp >= proposal.endTime, "Governance: Voting period is not over");
        require(!proposal.executed, "Governance: Proposal already executed");

        // Check if the proposal passed (more 'for' votes than 'against', and meets threshold)
        require(proposal.forVotes > proposal.againstVotes, "Governance: Proposal did not pass");
        require(proposal.forVotes >= proposal.voteThreshold, "Governance: Proposal did not meet vote threshold");

        proposal.executed = true;

        // Execute the proposed action
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Governance: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /// @notice Get details for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return id, description, target, creationTime, endTime, voteThreshold, forVotes, againstVotes, executed
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        string memory description,
        address target,
        uint256 creationTime,
        uint256 endTime,
        uint256 voteThreshold,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Governance: Invalid proposal ID"); // Check if proposal exists

        return (
            proposal.id,
            proposal.description,
            proposal.target,
            proposal.creationTime,
            proposal.endTime,
            proposal.voteThreshold,
            proposal.executed
        );
    }

     /// @notice Get vote counts for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return forVotes, againstVotes
    function getVoteCount(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
         Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Governance: Invalid proposal ID"); // Check if proposal exists
        return (proposal.forVotes, proposal.againstVotes);
    }

    /// @notice Check if a specific address has voted on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voter The address to check.
    /// @return True if the address has voted, False otherwise.
    function getVoterStatus(uint256 proposalId, address voter) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Governance: Invalid proposal ID"); // Check if proposal exists
        return proposal.hasVoted[voter];
    }


    // --- Additional Utility ---

    /// @notice Get the total number of MetaMorph tokens minted.
    /// @return The total count.
    function getMetaMorphCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Internal Helper Functions (Inherited) ---
    // _mint, _safeMint, _burn, _transfer, _exists are provided by OpenZeppelin


    // --- Overrides and Internal Logic for ERC721Enumerable ---
    // Need to override _beforeTokenTransfer to handle staking correctly
    // and potentially other custom logic.

    // Override to prevent transfers while staked or during operations like fusion/evolution
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the transfer is *not* initiated by the contract itself (e.g., for staking/unstaking/fusion)
        if (msg.sender != address(this)) {
            // Prevent transfer if staked
            if (_metaMorphData[tokenId].isStaked) {
                 // Allow transfer *from* the contract *to* the original owner during unstaking
                 require(!(from == address(this) && to != address(0)), "MetaMorph: Token is staked and cannot be transferred externally");
            }
             // Prevent transfers if involved in active fusion/evolution (this requires more complex state tracking)
             // For simplicity here, we rely on the fact that staked tokens are owned by the contract,
             // and fusion/evolution logic handles burning/transferring internally before allowing user control again.
        } else {
             // If transfer is by the contract itself (staking/unstaking/fusion), allow it.
             // Ensure token data exists if transferring *from* the contract (e.g. unstaking)
             if (from == address(this)) {
                  require(_exists(tokenId), "MetaMorph: Staked token does not exist (internal error)");
             }
        }

        // When transferring *to* the contract (for staking), mark as staked (handled in stakeMetaMorph)
        // When transferring *from* the contract (unstaking/fusion), mark as unstaked (handled in unstakeMetaMorph/fuseMetaMorphs)
    }

    // Override to ensure MetaMorphData is handled if tokens are manually burned (e.g., via operator)
    function _burn(uint256 tokenId) internal override(ERC721Enumerable, ERC721) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         MetaMorphData storage data = _metaMorphData[tokenId];
         require(!data.isStaked, "MetaMorph: Cannot burn staked token"); // Should be checked by external burnMetaMorph

        super._burn(tokenId);
        // Note: Trait data remains in storage but is inaccessible via public functions requiring _exists() or ownerOf().
        // Explicit deletion of mapping contents (`delete _metaMorphData[tokenId];`) is possible but expensive.
    }

    // --- Receive/Fallback ---
    // Add fallback function to receive ether, although not explicitly used by the contract logic
    // This is good practice unless you specifically want to reject ether.
    receive() external payable {}
    fallback() external payable {}


}
```