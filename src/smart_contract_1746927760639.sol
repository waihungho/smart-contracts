Okay, here is a Solidity smart contract incorporating several advanced, creative, and interconnected concepts for an NFT project, aiming for uniqueness and interactivity beyond typical static NFTs. It focuses on an "evolutionary" theme triggered by staking and includes fusion mechanics and dynamic properties.

It is built using OpenZeppelin contracts for robustness (ERC721, Enumerable, URIStorage, Ownable) but introduces custom logic for the core mechanics (evolution, staking, fusion, traits). The complexity lies in the interaction of these mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Included for completeness, though less critical in 0.8+
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For potential future contract interactions

/*
Outline:

1.  Purpose: Create a dynamic NFT that evolves through staking, can be fused, has genetic and acquired traits, and features a lifecycle including a soulbound stage.
2.  Core Concepts:
    *   Evolution Stages: NFTs progress through defined stages (Egg -> Hatchling -> Juvenile -> Adult -> Elder -> Ancestral).
    *   Staking for Evolution: Owners must stake their NFT for a minimum duration (in blocks) to enable evolution.
    *   Dynamic Traits: Traits change upon evolution based on genetics (initial genes), time staked, and a form of on-chain entropy (simulation provided, true randomness needs Chainlink VRF or similar).
    *   Genetic Imprinting: Initial properties (genes) are determined at minting and influence potential evolution paths and traits.
    *   Fusion (Breeding/Sacrifice): Two NFTs can be burned to create a new Egg, inheriting traits/genes from parents.
    *   Soulbound Stage: The final stage (Ancestral) makes the NFT non-transferable.
    *   Treasury/Protocol Sink: Optional ETH fees for actions can be collected.
    *   Simulations: View functions to predict potential outcomes of evolution based on current state.
3.  Inheritance: ERC721, ERC721Enumerable, ERC721URIStorage, Ownable.
4.  State Variables: NFT data struct, evolution durations mapping, base URI, treasury address, token counter.
5.  Events: Signify key lifecycle and state changes (Mint, Stake, Evolve, Fuse, Trait Mutate, Owner actions).
6.  Key Functions: (See summary below) Minting, Staking/Evolution claim, Fusion, Getters for all data points, Owner-only configuration/withdrawal, Utility/Simulation functions.
7.  Advanced Concepts Highlights: Dynamic state based on on-chain action (staking duration), on-chain derived randomness affecting traits (though simplified), burning mechanism for new minting (fusion), soulbound status, view functions for state projection (simulation).
8.  Security Considerations: Reliance on block data for entropy is susceptible to miner manipulation; for production-grade randomness affecting high-value traits/genes, Chainlink VRF or similar is recommended. Ensure robust off-chain metadata API handles dynamic tokenURI data.
*/

/*
Function Summary:

Core ERC721/Enumerable/URIStorage (Overridden where necessary):
- constructor(string name, string symbol, address treasuryAddr): Initializes contract, sets name, symbol, owner, treasury, and default evolution durations.
- tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a token.
- supportsInterface(bytes4 interfaceId): Standard EIP-165 interface check.
- transferFrom(address from, address to, uint256 tokenId): Overridden to prevent transfer of staked or soulbound tokens.
- safeTransferFrom(address from, address to, uint256 tokenId): Overridden to prevent transfer of staked or soulbound tokens.
- safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Overridden to prevent transfer of staked or soulbound tokens.

Custom Mechanics:
- mint(): Mints a new NFT (Egg stage) to the caller. Genes are derived from caller/block data. (Public, payable optional for cost)
- stakeForEvolution(uint256 tokenId, uint64 durationBlocks): Locks an NFT for a minimum duration to enable evolution. Requires ownership and meeting minimum stage duration. (Public)
- claimEvolution(uint256 tokenId): Triggers evolution if staked duration is met and caller is owner/staker. Calculates next stage and new traits, unstakes the NFT. (Public)
- unstakeEarly(uint256 tokenId): Allows owner/staker to cancel a stake early (no evolution occurs). (Public)
- fuseNFTs(uint256 parent1TokenId, uint256 parent2TokenId): Burns two parent NFTs (owned by caller) and mints a new Egg NFT with genes derived from parents. (Public, payable optional for cost)

Getters (View Functions):
- getNftData(uint256 tokenId): Returns the full NFTData struct for a token.
- getStage(uint256 tokenId): Returns the current Stage enum.
- getGenes(uint256 tokenId): Returns the immutable genes value.
- getTraits(uint256 tokenId): Returns the dynamic traits value.
- isStaked(uint256 tokenId): Checks if a token is currently staked.
- isSoulbound(uint256 tokenId): Checks if a token is soulbound (Ancestral stage).
- getEvolveReadyBlock(uint256 tokenId): Gets the block number when staking ends.
- getStakeOwner(uint256 tokenId): Gets the address that initiated the current stake.
- getEvolutionDuration(Stage stage): Gets the required staking duration for a specific stage evolution.
- isEvolutionReady(uint256 tokenId): Convenience check if a token is staked and its stake period is over.
- getBirthBlock(uint256 tokenId): Gets the block number when the NFT was minted.
- getLastActionBlock(uint256 tokenId): Gets the block number of the last stake start or evolution claim.
- getStageAsUint(uint256 tokenId): Gets the Stage as a uint8.
- getMinStakeDurationForEvolution(uint256 tokenId): Gets the minimum stake duration required for the *current* stage's evolution.
- exists(uint256 tokenId): Checks if a token ID exists.
- getTreasuryAddress(): Gets the configured treasury address.
- getStakeInitiator(uint256 tokenId): Gets the address that called stakeForEvolution.

Simulations (View Functions):
- simulateNextTraits(uint256 tokenId): Estimates potential traits after evolution based on current state and minimum stake duration (or current stake progress if active). Uses deterministic simulation entropy.
- simulateNextStage(uint256 tokenId): Predicts the next stage if the minimum staking duration for the *current* stage is met.

Owner-Only Functions:
- setBaseURI(string baseURI): Sets the base URI for token metadata.
- setEvolutionDuration(Stage stage, uint64 durationBlocks): Configures minimum stake duration for a stage's evolution.
- withdrawTreasury(): Transfers collected ETH to the treasury address.
- burnToken(uint256 tokenId): Allows owner to permanently burn a token (cannot be staked).
- setTreasuryAddress(address newTreasuryAddr): Updates the treasury address.

Utility:
- getCurrentBlock(): Returns the current block number (useful for frontend checks against evolveReadyBlock).

Total Public/External Functions: 30+ (Includes ERC721/Enumerable overrides, custom methods, getters, simulations, owner functions, utility).
*/

contract EvolutionaryNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---
    enum Stage { Egg, Hatchling, Juvenile, Adult, Elder, Ancestral }

    struct NFTData {
        Stage stage;
        uint256 genes;          // Immutable fixed properties, set at mint
        uint256 traits;         // Mutable dynamic properties, change on evolution/actions
        uint64 lastActionBlock; // Block number of the last significant action (stake start or evolution claim)
        uint64 evolveReadyBlock; // Block number when staking period ends
        address stakeOwner;      // Address that initiated the current stake
        bool isStaked;
        bool isSoulbound;       // True when the NFT reaches the Ancestral stage
        uint64 birthBlock;      // Block number when the NFT was minted
    }

    mapping(uint256 => NFTData) private _nftData;
    mapping(Stage => uint64) public evolutionDurationBlocks; // Minimum blocks required to stake for each stage evolution

    string private _baseTokenURI;
    address private _treasuryAddress;

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 genes, uint64 birthBlock);
    event NFTStaked(uint256 indexed tokenId, address indexed owner, uint64 stakeDurationBlocks, uint64 evolveReadyBlock);
    event NFTEvolved(uint256 indexed tokenId, Stage fromStage, Stage toStage, uint256 newTraits, uint64 evolveBlock);
    event NFTFused(uint256 indexed newTokenId, uint256 indexed parent1TokenId, uint256 indexed parent2TokenId, uint256 newGenes);
    event TraitsMutated(uint256 indexed tokenId, uint256 oldTraits, uint256 newTraits);
    event EvolutionDurationSet(Stage indexed stage, uint64 durationBlocks);
    event BaseTokenURISet(string baseTokenURI);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, bool early);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address treasuryAddr)
        ERC721(name, symbol)
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        require(treasuryAddr != address(0), "Treasury address cannot be zero");
        _treasuryAddress = treasuryAddr;

        // Set some default minimum evolution durations in blocks.
        // These can be updated later by the owner.
        // Example durations (adjust for desired pacing):
        evolutionDurationBlocks[Stage.Egg] = 20;      // Relatively fast to hatch
        evolutionDurationBlocks[Stage.Hatchling] = 50;
        evolutionDurationBlocks[Stage.Juvenile] = 100;
        evolutionDurationBlocks[Stage.Adult] = 200;
        evolutionDurationBlocks[Stage.Elder] = 500;
        // Ancestral cannot evolve further, duration is irrelevant
    }

    // --- ERC721 Overrides ---

    // The base URI should point to an API that serves dynamic JSON metadata
    // based on the token ID by reading the contract's state.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             // Fallback or custom logic if base URI isn't set
             // Maybe return a default error URI or an on-chain generated basic one
             return super.tokenURI(tokenId); // Default ERC721URIStorage behavior (empty string if not set)
        }
        // Assume base URI ends with '/', like 'https://api.yoursite.com/metadata/'
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // Internal helper for OpenZeppelin's URI storage
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return _baseTokenURI;
    }

    // ERC165 support (includes ERC721, ERC721Enumerable)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Override transfer functions to prevent transfer when staked or soulbound
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _beforeTokenTransfer(from, to, tokenId); // Hook for OZ pre-transfer checks (e.g., approval)
        require(!_nftData[tokenId].isStaked, "NFT is staked and cannot be transferred");
        require(!_nftData[tokenId].isSoulbound, "NFT is soulbound and cannot be transferred");
         // Additional check: the `from` address must be the current owner for standard transfer
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
         _beforeTokenTransfer(from, to, tokenId);
         require(!_nftData[tokenId].isStaked, "NFT is staked and cannot be transferred");
         require(!_nftData[tokenId].isSoulbound, "NFT is soulbound and cannot be transferred");
         // Additional check: the `from` address must be the current owner
         require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
         _safeTransfer(from, to, tokenId, "");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
         _beforeTokenTransfer(from, to, tokenId);
         require(!_nftData[tokenId].isStaked, "NFT is staked and cannot be transferred");
         require(!_nftData[tokenId].isSoulbound, "NFT is soulbound and cannot be transferred");
          // Additional check: the `from` address must be the current owner
         require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
         _safeTransfer(from, to, tokenId, data);
    }

    // --- Internal Helper Functions ---

    // Mints a new NFT with initial state
    function _mintNFT(address to, uint256 initialGenes) internal returns (uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, newTokenId); // Mints the token and assigns ownership

        _nftData[newTokenId] = NFTData({
            stage: Stage.Egg,
            genes: initialGenes,
            traits: 0, // Initial traits can be zero or derived from genes
            lastActionBlock: uint64(block.number),
            evolveReadyBlock: 0, // Not staked initially
            stakeOwner: address(0),
            isStaked: false,
            isSoulbound: false,
            birthBlock: uint64(block.number)
        });

        // Set initial token URI if needed, or rely on the dynamic tokenURI function
        // _setTokenURI(newTokenId, initialURI); // If using static URIs initially

        emit NFTMinted(newTokenId, to, initialGenes, uint64(block.number));
        return newTokenId;
    }

    // Logic to calculate new traits upon evolution or action
    // This is where complex 'game logic' can reside.
     function _calculateNewTraits(
         uint256 currentTraits,
         uint256 genes,
         uint64 timeStakedBlocks,
         uint256 entropy // Source of variability
     ) internal pure returns (uint256)
     {
         // --- Advanced Trait Calculation Logic Placeholder ---
         // This is a simplified example. In a real application, this function
         // could encode complex interactions between genes, environmental factors
         // (timeStakedBlocks acts as one), and randomness.
         // Example: Bitwise operations, scaling factors based on genes,
         // probability-based trait additions/mutations using entropy.

         uint256 newTraits = currentTraits;

         // Example Logic: Increase traits based on time staked and genes, with potential mutation
         uint256 timeFactor = timeStakedBlocks / 10; // Scale down blocks for trait points
         uint256 geneInfluence = (genes % 256); // Use lower byte of genes
         uint256 traitIncrease = (timeFactor * geneInfluence) / 100; // Simplified growth calculation

         newTraits += traitIncrease;

         // Introduce a chance for a significant "mutation" using entropy
         // Using (entropy % 1000) < 10 gives roughly 1% chance of mutation per evolution attempt
         if ((entropy % 1000) < 10) {
             // Apply a random boost or change based on entropy
             uint256 mutationBoost = (entropy % 500) + 100; // Add 100-600 points
             newTraits += mutationBoost;
         }

         // Apply a ceiling to prevent trait overflow or excessively high values
         uint256 maxTraits = type(uint32).max; // Use uint32 max for example (approx 4 billion)
         if (newTraits > maxTraits) {
             newTraits = maxTraits;
         }

         // Consider adding checks or logic to prevent specific undesirable trait combinations
         // or ensure trait diversity based on genes.

         return newTraits;
     }

     // Logic to determine the next evolution stage
     function _determineNextStage(Stage currentStage, uint64 timeStakedBlocks) internal view returns (Stage) {
         // --- Advanced Stage Determination Logic Placeholder ---
         // This could depend on minimum time staked *plus* meeting certain trait thresholds,
         // specific gene requirements, or even external oracle data.

         uint64 requiredBlocks = evolutionDurationBlocks[currentStage];

         // Simple logic: Stage progresses only if minimum time is met for the current stage
         if (timeStakedBlocks >= requiredBlocks) {
             if (currentStage == Stage.Egg) return Stage.Hatchling;
             if (currentStage == Stage.Hatchling) return Stage.Juvenile;
             if (currentStage == Stage.Juvenile) return Stage.Adult;
             if (currentStage == Stage.Adult) return Stage.Elder;
             if (currentStage == Stage.Elder) return Stage.Ancestral;
         }

         // Otherwise, stay in the current stage
         return currentStage;
     }

     // Handles the fusion of two NFTs into a new one
     function _handleFusion(uint256 parent1TokenId, uint256 parent2TokenId) internal returns (uint256) {
         NFTData storage data1 = _nftData[parent1TokenId];
         NFTData storage data2 = _nftData[parent2TokenId];

         // --- Advanced Gene Mixing Logic Placeholder ---
         // Combine genes and potentially traits from parents to determine the new NFT's genes.
         // This can involve averaging, bitwise operations, dominant/recessive gene simulation,
         // or introducing variation.

         // Example: Simple XOR of genes, mixed with block data for variation
         uint256 newGenes = (data1.genes ^ data2.genes) ^ uint256(keccak256(abi.encodePacked(block.hash(block.number - 1), parent1TokenId, parent2TokenId)));

         // Optional: Incorporate parent traits into the new genes
         // newGenes = newGenes ^ data1.traits ^ data2.traits;

         // Ensure new genes are within a valid format if encoding is used
         // newGenes = newGenes % type(uint256).max; // Example limiting

         // Burn the parent tokens
         _burn(parent1TokenId);
         delete _nftData[parent1TokenId]; // Clear data mapping for burned token
         emit NFTBurned(parent1TokenId, msg.sender);

         _burn(parent2TokenId);
         delete _nftData[parent2TokenId]; // Clear data mapping for burned token
         emit NFTBurned(parent2TokenId, msg.sender);

         // Mint the new Egg NFT
         uint256 newTokenId = _mintNFT(msg.sender, newGenes);

         emit NFTFused(newTokenId, parent1TokenId, parent2TokenId, newGenes);

         return newTokenId;
     }

     // Helper to generate entropy for traits calculation.
     // NOTE: Block hash/timestamp/etc. can be influenced by miners. For production,
     // consider using Chainlink VRF or similar for unbiasable randomness.
     function _getEntropy() internal view returns (uint256) {
         // Use a mix of block and transaction data for an on-chain entropy source
         return uint256(keccak256(abi.encodePacked(
             block.timestamp,
             block.number,
             tx.gasprice,
             tx.origin, // Using tx.origin is generally discouraged for authorization, but acceptable for entropy
             block.difficulty // `prevrandao` after The Merge
         )));
     }

     // Internal helper to unstake an NFT
     function _unstakeNFT(uint256 tokenId, bool early) internal {
         NFTData storage data = _nftData[tokenId];
         require(data.isStaked, "Token not staked"); // Should not happen if called correctly

         address staker = data.stakeOwner;
         data.isStaked = false;
         data.stakeOwner = address(0); // Clear stake owner
         data.evolveReadyBlock = 0; // Reset ready block

         emit NFTUnstaked(tokenId, staker, early);
     }


    // --- Public / External Functions ---

    // 1. Mint a new NFT (starts as Egg)
    function mint() public payable returns (uint256) {
        // Add minting price check if payable is used, send to treasury or burn
        // require(msg.value >= mintPrice, "Insufficient ETH");
        // if (msg.value > 0) {
        //    (bool success,) = payable(_treasuryAddress).call{value: msg.value}("");
        //    require(success, "ETH transfer failed");
        // }

        // Generate initial genes based on caller, token ID, and block data
        uint256 initialGenes = uint256(keccak256(abi.encodePacked(msg.sender, _tokenIdCounter.current(), block.timestamp, block.number, _getEntropy())));

        // Add supply limit check if desired
        // require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");

        return _mintNFT(msg.sender, initialGenes);
    }

    // 2. Get all data for a specific NFT
    function getNftData(uint256 tokenId) public view returns (NFTData memory) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId];
    }

    // 3. Stake an NFT to enable its evolution
    function stakeForEvolution(uint256 tokenId, uint64 durationBlocks) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner"); // Only owner can stake
        require(!_nftData[tokenId].isStaked, "NFT is already staked"); // Cannot restake if already staked
        require(_nftData[tokenId].stage != Stage.Ancestral, "Ancestral stage cannot evolve further"); // Cannot stake Ancestral

        Stage currentStage = _nftData[tokenId].stage;
        uint64 minDuration = evolutionDurationBlocks[currentStage];
        require(durationBlocks >= minDuration, "Stake duration is less than the minimum required for this stage");

        NFTData storage data = _nftData[tokenId];
        data.isStaked = true;
        data.stakeOwner = msg.sender;
        data.lastActionBlock = uint64(block.number); // Record stake start block
        data.evolveReadyBlock = uint64(block.number + durationBlocks);

        emit NFTStaked(tokenId, msg.sender, durationBlocks, data.evolveReadyBlock);
    }

    // 4. Claim evolution after staking period is complete
    function claimEvolution(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner"); // Only owner can claim
        require(_nftData[tokenId].isStaked, "NFT is not staked"); // Must be staked
        require(msg.sender == _nftData[tokenId].stakeOwner, "Only the original staker (who is still owner) can claim"); // Staker must still be the owner
        require(block.number >= _nftData[tokenId].evolveReadyBlock, "Stake period is not over yet"); // Staking period must be finished
        require(_nftData[tokenId].stage != Stage.Ancestral, "Ancestral stage cannot evolve further"); // Cannot evolve Ancestral

        NFTData storage data = _nftData[tokenId];
        Stage currentStage = data.stage;
        uint64 timeStakedBlocks = data.evolveReadyBlock - data.lastActionBlock; // Actual duration staked

        Stage nextStage = _determineNextStage(currentStage, timeStakedBlocks);

        // Only evolve if the stage actually changes
        if (nextStage == currentStage) {
            // If stage doesn't change, it means the minimum duration for *this* stage wasn't met
            // (e.g., if stakeForEvolution allowed staking for less than minimum for a later stage,
            // or if duration was just above current min but below next min).
            // In our _determineNextStage, it only progresses if min is met, so this case
            // would only happen if duration was exactly currentStage min blocks or if already max stage.
            // Given the require in stakeForEvolution, this branch primarily serves the Ancestral check above.
            // Unstake anyway.
            _unstakeNFT(tokenId, false); // Not an "early" unstake in the sense of failure
            // Could emit a specific event like EvolutionAttemptedButNoProgress
            return; // No evolution happened
        }

        uint256 oldTraits = data.traits;
        data.stage = nextStage;
        // Calculate new traits based on genes, time staked, and entropy
        data.traits = _calculateNewTraits(oldTraits, data.genes, timeStakedBlocks, _getEntropy());
        data.lastActionBlock = uint64(block.number); // Update last action block to claim time
        _unstakeNFT(tokenId, false); // Unstake after successful evolution

        emit NFTEvolved(tokenId, currentStage, nextStage, data.traits, uint64(block.number));
        if (data.traits != oldTraits) {
             emit TraitsMutated(tokenId, oldTraits, data.traits);
        }

        // Make Ancestral soulbound
        if (nextStage == Stage.Ancestral) {
            data.isSoulbound = true;
        }
    }

    // 5. Allows the owner/staker to unstake before the evolution period ends
    function unstakeEarly(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        require(_nftData[tokenId].isStaked, "NFT is not staked");
        require(msg.sender == _nftData[tokenId].stakeOwner, "Only the original staker (who is still owner) can unstake");
        require(block.number < _nftData[tokenId].evolveReadyBlock, "Stake period is already over, use claimEvolution instead"); // Must be before the ready block

        // Optional: Add penalty logic here (e.g., reduce traits, require ETH payment)

        _unstakeNFT(tokenId, true); // Unstake early flag true
    }

    // 6. Fuse two NFTs to create a new one
    function fuseNFTs(uint256 parent1TokenId, uint256 parent2TokenId) public payable returns (uint256) {
         require(_exists(parent1TokenId), "Parent 1 does not exist");
         require(_exists(parent2TokenId), "Parent 2 does not exist");
         require(parent1TokenId != parent2TokenId, "Cannot fuse an NFT with itself");
         require(ownerOf(parent1TokenId) == msg.sender, "Caller is not the owner of parent 1");
         require(ownerOf(parent2TokenId) == msg.sender, "Caller is not the owner of parent 2");

         // Optional: Add stage requirements for fusion (e.g., must be Juvenile or older)
         // require(_nftData[parent1TokenId].stage >= Stage.Juvenile, "Parent 1 is too young to fuse");
         // require(_nftData[parent2TokenId].stage >= Stage.Juvenile, "Parent 2 is too young to fuse");

         // Ensure parents are not staked
         require(!_nftData[parent1TokenId].isStaked, "Parent 1 is staked");
         require(!_nftData[parent2TokenId].isStaked, "Parent 2 is staked");

         // Optional: Add fusion cost and send to treasury or burn
         // require(msg.value >= fusionCost, "Insufficient ETH for fusion");
         // if (msg.value > 0) {
         //    (bool success,) = payable(_treasuryAddress).call{value: msg.value}("");
         //    require(success, "ETH transfer failed");
         // }

         return _handleFusion(parent1TokenId, parent2TokenId);
    }

    // 7. Get the current evolution stage of an NFT
    function getStage(uint256 tokenId) public view returns (Stage) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId].stage;
    }

    // 8. Get the immutable genes of an NFT
    function getGenes(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId].genes;
    }

    // 9. Get the dynamic traits of an NFT
    function getTraits(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId].traits;
    }

    // 10. Check if an NFT is currently staked
    function isStaked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId].isStaked;
    }

     // 11. Check if an NFT is soulbound (non-transferable)
    function isSoulbound(uint255 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _nftData[tokenId].isSoulbound;
    }

    // 12. Get the block number when a staked NFT's evolution staking period ends
    function getEvolveReadyBlock(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "Token does not exist");
         return _nftData[tokenId].evolveReadyBlock;
    }

     // 13. Get the address that initiated the current stake for an NFT
    function getStakeOwner(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "Token does not exist");
         return _nftData[tokenId].stakeOwner; // This is the address recorded *at the time of staking*
    }

    // 14. Owner-only: Set the base URI for token metadata.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURISet(baseURI);
    }

    // 15. Owner-only: Set the minimum required staking duration for a specific evolution stage.
    function setEvolutionDuration(Stage stage, uint64 durationBlocks) public onlyOwner {
         require(stage != Stage.Ancestral, "Cannot set evolution duration for Ancestral stage");
         evolutionDurationBlocks[stage] = durationBlocks;
         emit EvolutionDurationSet(stage, durationBlocks);
    }

    // 16. Owner-only: Withdraw collected ETH from the contract balance to the treasury address.
    function withdrawTreasury() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Treasury balance is zero");
        (bool success, ) = payable(_treasuryAddress).call{value: balance}("");
        require(success, "ETH withdrawal failed");
        emit TreasuryWithdrawal(_treasuryAddress, balance);
    }

    // 17. Get the configured treasury address.
    function getTreasuryAddress() public view returns (address) {
        return _treasuryAddress;
    }

     // 18. Get the minimum staking duration required for a specific stage to potentially evolve.
    function getEvolutionDuration(Stage stage) public view returns (uint64) {
         require(stage != Stage.Ancestral, "Ancestral stage has no evolution duration");
         return evolutionDurationBlocks[stage];
    }

    // 19. Check if an NFT is currently staked and the staking period has ended (ready to claim).
    function isEvolutionReady(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        NFTData memory data = _nftData[tokenId];
        return data.isStaked && block.number >= data.evolveReadyBlock && data.stage != Stage.Ancestral;
    }

    // 20. Get the block number when the NFT was minted.
    function getBirthBlock(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "Token does not exist");
         return _nftData[tokenId].birthBlock;
    }

    // 21. Get the block number of the last stake start or evolution claim action.
    function getLastActionBlock(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "Token does not exist");
         return _nftData[tokenId].lastActionBlock;
    }

    // 22. Simulate potential traits after evolution.
    // This function estimates the new traits using the current state and simulation entropy.
    // Note: Actual traits on claim might differ slightly due to real block entropy.
     function simulateNextTraits(uint256 tokenId) public view returns (uint256 potentialTraits) {
         require(_exists(tokenId), "Token does not exist");
         NFTData memory data = _nftData[tokenId];
         require(data.stage != Stage.Ancestral, "Ancestral stage has no further trait evolution");

         uint64 simulatedTimeStaked = 0;
         if (data.isStaked) {
              // If staked, simulate based on time from stake start to current block
              simulatedTimeStaked = uint64(block.number) - data.lastActionBlock;
              // If stake period is over, use the full staked duration
              if (block.number >= data.evolveReadyBlock) {
                  simulatedTimeStaked = data.evolveReadyBlock - data.lastActionBlock;
              }
         } else {
             // If not staked, simulate based on the minimum required duration for the current stage
             simulatedTimeStaked = evolutionDurationBlocks[data.stage];
         }

         // Use a deterministic hash based on current view state for simulation entropy
         // This entropy source is different from the one used in _getEntropy (which includes tx-specific data)
         // to make the simulation function purely `view` and deterministic for the current block state.
         uint256 simulationEntropy = uint256(keccak256(abi.encodePacked(
             data.traits,
             data.genes,
             simulatedTimeStaked,
             block.number, // Include current block for simulation context
             address(this) // Include contract address for uniqueness
         )));

         return _calculateNewTraits(data.traits, data.genes, simulatedTimeStaked, simulationEntropy);
     }

     // 23. Simulate the potential next stage if the minimum staking duration for the current stage is met.
     // Note: This only considers the minimum duration requirement, not potential trait thresholds if _determineNextStage logic were more complex.
     function simulateNextStage(uint256 tokenId) public view returns (Stage potentialNextStage) {
          require(_exists(tokenId), "Token does not exist");
          NFTData memory data = _nftData[tokenId];
          if (data.stage == Stage.Ancestral) return Stage.Ancestral; // Cannot evolve from Ancestral
          uint64 minDuration = evolutionDurationBlocks[data.stage];
          return _determineNextStage(data.stage, minDuration); // Simulate meeting the minimum time
     }

     // 24. Owner-only: Burn a token permanently.
     // Useful for cleanup or specific game/protocol mechanics.
     function burnToken(uint256 tokenId) public onlyOwner {
         require(_exists(tokenId), "Token does not exist");
         require(!_nftData[tokenId].isStaked, "Cannot burn a staked token");
         // Can burn soulbound tokens if needed by owner
         address owner = ownerOf(tokenId); // Get owner before burning
         _burn(tokenId);
         delete _nftData[tokenId]; // Clear data mapping
         emit NFTBurned(tokenId, owner);
     }

     // 25. Get the current block number. Useful for frontend to compare against evolveReadyBlock.
     function getCurrentBlock() public view returns (uint64) {
         return uint64(block.number);
     }

     // 26. Get the Stage as a uint8 (useful for systems/interfaces that don't handle Solidity enums directly).
     function getStageAsUint(uint256 tokenId) public view returns (uint8) {
          require(_exists(tokenId), "Token does not exist");
          return uint8(_nftData[tokenId].stage);
     }

     // 27. Get the minimum staking duration required for the *current* stage of an NFT to potentially evolve.
     function getMinStakeDurationForEvolution(uint256 tokenId) public view returns (uint64) {
          require(_exists(tokenId), "Token does not exist");
          Stage currentStage = _nftData[tokenId].stage;
          if (currentStage == Stage.Ancestral) return 0; // Ancestral cannot evolve
          return evolutionDurationBlocks[currentStage];
     }

     // 28. Public wrapper for OpenZeppelin's _exists check.
     function exists(uint256 tokenId) public view returns (bool) {
         return _exists(tokenId);
     }

     // 29. Owner-only: Update the address designated to receive treasury withdrawals.
     function setTreasuryAddress(address newTreasuryAddr) public onlyOwner {
         require(newTreasuryAddr != address(0), "Treasury address cannot be zero");
         _treasuryAddress = newTreasuryAddr;
     }

     // 30. Get the address that initially called `stakeForEvolution` for the current stake.
     // This might be different from the current owner if the NFT was transferred while unstaked,
     // but `claimEvolution` and `unstakeEarly` require the staker to still be the owner.
     function getStakeInitiator(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "Token does not exist");
         return _nftData[tokenId].stakeOwner;
     }

    // Fallback function to receive ETH for potential minting/fusion fees
    receive() external payable {
        // Optional: Add logic to handle unexpected ETH transfers, like logging or reverting
    }

    // Fallback function for non-payable calls to contract without matching function
    fallback() external {
        revert("Function not found or not allowed");
    }
}
```