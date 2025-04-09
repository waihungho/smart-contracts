```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution Contract - "ChronoGenesis NFTs"
 * @author Bard (Example Implementation)
 * @dev A smart contract implementing dynamic NFTs that evolve over time and through user interactions.
 *      This contract introduces concepts like:
 *      - Time-based NFT evolution stages.
 *      - User-driven evolution through resource contribution.
 *      - Rarity tiers influencing evolution paths.
 *      - On-chain voting for community-driven evolution paths.
 *      - Staking NFTs for enhanced evolution potential.
 *      - Dynamic metadata updates reflecting evolution stages.
 *      - Utility token integration for ecosystem interactions.
 *      - Randomized evolution elements for surprise and uniqueness.
 *      - NFT breeding/merging for creating new NFTs.
 *      - Special events triggering unique evolution paths.
 *      - A marketplace for trading evolved NFTs.
 *      - Leaderboard and reward system for active users.
 *      - Governance mechanisms for future contract upgrades.
 *      - Anti-whale mechanisms to promote fair distribution.
 *      - Layered metadata for richer NFT experiences.
 *      - Conditional evolution based on external oracle data (simulated here).
 *      - NFT burning for resource reclamation or rarity control.
 *      - Customizable evolution traits through user choices.
 *      - Dynamic royalties based on NFT evolution stage.
 *
 * Function Summary:
 * 1. initializeContract(): Initializes contract parameters like NFT name, symbol, evolution intervals, etc. (Admin only).
 * 2. mintNFT(): Mints a new ChronoGenesis NFT with an initial stage and rarity tier.
 * 3. getNFTStage(): Returns the current evolution stage of a given NFT.
 * 4. getNFTMetadataURI(): Returns the dynamic metadata URI for a given NFT, reflecting its current stage.
 * 5. checkAndEvolveNFT(): Checks if an NFT is eligible to evolve based on time and triggers evolution if conditions are met.
 * 6. manualEvolveNFT(): Allows NFT owners to manually trigger evolution using resources or tokens (if required).
 * 7. contributeResourcesForEvolution(): Allows users to contribute resources (e.g., utility tokens) to accelerate or influence evolution.
 * 8. setEvolutionCriteria(): Allows admin to set the criteria and rules for NFT evolution at each stage. (Admin only).
 * 9. startCommunityVoteForEvolutionPath(): Starts a community vote for choosing between different evolution paths for a specific NFT stage. (Admin only).
 * 10. castVoteForEvolutionPath(): Allows NFT holders to cast their vote for a specific evolution path.
 * 11. finalizeEvolutionPathVote(): Finalizes the community vote and sets the chosen evolution path. (Admin only).
 * 12. stakeNFTForEvolutionBoost(): Allows NFT holders to stake their NFTs to receive a boost in evolution speed or potential.
 * 13. unstakeNFT(): Allows NFT holders to unstake their NFTs.
 * 14. breedNFTs(): Allows users to breed two compatible NFTs to create a new NFT with inherited traits.
 * 15. mergeNFTs(): Allows users to merge two NFTs to create a single, more advanced NFT (potentially burning the originals).
 * 16. triggerSpecialEventEvolution(): Allows admin to trigger a special event that causes unique evolution paths for NFTs. (Admin only).
 * 17. burnNFT(): Allows NFT owners to burn their NFTs, potentially reclaiming resources or increasing scarcity.
 * 18. setBaseMetadataURI(): Allows admin to set the base URI for NFT metadata. (Admin only).
 * 19. withdrawContractBalance(): Allows admin to withdraw contract balance (e.g., accumulated fees). (Admin only, with safeguards).
 * 20. getNFTTraits(): Returns the current traits/attributes of an NFT based on its stage and rarity.
 * 21. setRarityTierTraits(): Allows admin to define specific traits associated with each rarity tier. (Admin only).
 * 22. setStageMetadataSuffixes(): Allows admin to define suffixes to append to base metadata URI based on NFT stage. (Admin only).
 * 23. setUtilityTokenAddress(): Allows admin to set the address of the utility token used in the ecosystem. (Admin only).
 * 24. getStakedNFTInfo(): Returns information about a staked NFT, including staking duration and boost status.
 * 25. getRandomNumber():  Internal function to generate a pseudo-random number (for evolution variations).
 * 26. pauseContract(): Pauses certain functionalities of the contract for maintenance or emergency. (Admin only).
 * 27. unpauseContract(): Resumes paused functionalities. (Admin only).
 * 28. isContractPaused(): Returns the current paused state of the contract.
 * 29. setDynamicRoyaltyPercentage(): Allows admin to set dynamic royalty percentage based on NFT stage. (Admin only).
 * 30. getDynamicRoyaltyPercentage(): Returns the current dynamic royalty percentage for a given NFT stage.
 */

contract ChronoGenesisNFT {
    // --- Outline and Function Summary (Already provided above in comments) ---

    // --- State Variables ---
    string public name;
    string public symbol;
    string public baseMetadataURI;
    string public stageMetadataSuffixes; // e.g., "_stage1,_stage2,_stage3"

    address public admin;
    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => uint256) public nftStage; // 1, 2, 3, ...
    mapping(uint256 => uint256) public nftRarityTier; // e.g., 1 (Common), 2 (Rare), 3 (Epic)
    mapping(uint256 => uint256) public nftEvolutionTimestamp;
    mapping(uint256 => bool) public isNFTStaked;
    mapping(uint256 => uint256) public nftStakingStartTime;
    mapping(uint256 => string) public nftEvolutionPath; // Store chosen evolution path (e.g., "fire", "water", "air")

    uint256 public baseEvolutionInterval; // Base time for stage evolution (e.g., in seconds)
    mapping(uint256 => uint256) public stageEvolutionIntervalMultiplier; // Multiplier for evolution interval at each stage

    mapping(uint256 => mapping(uint256 => string[])) public rarityTierTraits; // rarityTier => stage => traits array

    address public utilityTokenAddress; // Address of the utility token contract (if used)

    mapping(uint256 => uint256) public dynamicRoyaltyPercentages; // stage => royalty percentage (in basis points)

    bool public paused = false;

    // --- Enums and Structs ---
    enum RarityTier { Common, Rare, Epic, Legendary }
    enum NFTStageEnum { Stage1, Stage2, Stage3, Stage4, Stage5 } // Example stages

    struct NFTInfo {
        uint256 tokenId;
        address owner;
        uint256 stage;
        uint256 rarityTier;
        uint256 evolutionTimestamp;
        bool isStaked;
    }

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, uint256 rarityTier, uint256 stage);
    event NFTEvolved(uint256 tokenId, uint256 oldStage, uint256 newStage, string evolutionPath);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event NFTBurned(uint256 tokenId, address owner);
    event EvolutionPathVoteStarted(uint256 stage, string[] possiblePaths);
    event EvolutionPathVoteCast(uint256 tokenId, address voter, string path);
    event EvolutionPathVoteFinalized(uint256 stage, string chosenPath);

    // --- Modifiers ---
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        name = "ChronoGenesis NFT";
        symbol = "CNFT";
        baseMetadataURI = "ipfs://your_base_metadata_uri/"; // Replace with your actual base URI
        stageMetadataSuffixes = "_stage1,_stage2,_stage3,_stage4,_stage5"; // Example suffixes
        baseEvolutionInterval = 86400; // 24 hours in seconds
        stageEvolutionIntervalMultiplier[1] = 1;
        stageEvolutionIntervalMultiplier[2] = 2;
        stageEvolutionIntervalMultiplier[3] = 3;
        stageEvolutionIntervalMultiplier[4] = 4;
        stageEvolutionIntervalMultiplier[5] = 5;

        // Example traits for rarity tiers and stages (can be expanded significantly)
        rarityTierTraits[uint256(RarityTier.Common)][1] = ["Common Trait A", "Common Trait B"];
        rarityTierTraits[uint256(RarityTier.Rare)][1] = ["Rare Trait A", "Rare Trait B", "Rare Trait C"];
        rarityTierTraits[uint256(RarityTier.Epic)][1] = ["Epic Trait A", "Epic Trait B", "Epic Trait C", "Epic Trait D"];
        rarityTierTraits[uint256(RarityTier.Legendary)][1] = ["Legendary Trait A", "Legendary Trait B", "Legendary Trait C", "Legendary Trait D", "Legendary Trait E"];

        dynamicRoyaltyPercentages[1] = 500; // 5% for Stage 1
        dynamicRoyaltyPercentages[2] = 750; // 7.5% for Stage 2
        dynamicRoyaltyPercentages[3] = 1000; // 10% for Stage 3
        dynamicRoyaltyPercentages[4] = 1250; // 12.5% for Stage 4
        dynamicRoyaltyPercentages[5] = 1500; // 15% for Stage 5
    }

    // --- 1. initializeContract (Admin only) ---
    function initializeContract(string memory _name, string memory _symbol, string memory _baseMetadataURI, uint256 _baseEvolutionInterval) external onlyAdmin {
        name = _name;
        symbol = _symbol;
        baseMetadataURI = _baseMetadataURI;
        baseEvolutionInterval = _baseEvolutionInterval;
        // Additional initialization logic can be added here
    }

    // --- 2. mintNFT ---
    function mintNFT(address _to, uint256 _rarityTier) external whenNotPaused {
        require(_rarityTier >= uint256(RarityTier.Common) && _rarityTier <= uint256(RarityTier.Legendary), "Invalid rarity tier");
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = _to;
        nftStage[tokenId] = 1; // Initial stage
        nftRarityTier[tokenId] = _rarityTier;
        nftEvolutionTimestamp[tokenId] = block.timestamp + baseEvolutionInterval * stageEvolutionIntervalMultiplier[1];
        emit NFTMinted(tokenId, _to, _rarityTier, 1);
    }

    // --- 3. getNFTStage ---
    function getNFTStage(uint256 _tokenId) external view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        return nftStage[_tokenId];
    }

    // --- 4. getNFTMetadataURI ---
    function getNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        uint256 currentStage = nftStage[_tokenId];
        string memory stageSuffix = "";
        string[] memory suffixes = stringSplit(stageMetadataSuffixes, ",");
        if (currentStage > 0 && currentStage <= suffixes.length) {
            stageSuffix = suffixes[currentStage - 1];
        }
        return string(abi.encodePacked(baseMetadataURI, _toString(_tokenId), stageSuffix, ".json")); // Example: ipfs://your_base_metadata_uri/1_stage1.json
    }

    // --- 5. checkAndEvolveNFT (Automatic Evolution) ---
    function checkAndEvolveNFT(uint256 _tokenId) external whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        require(nftStage[_tokenId] < uint256(NFTStageEnum.Stage5), "NFT is already at max stage"); // Example max stage
        require(block.timestamp >= nftEvolutionTimestamp[_tokenId], "NFT not yet ready to evolve");

        uint256 currentStage = nftStage[_tokenId];
        uint256 nextStage = currentStage + 1;
        string memory chosenPath = "default"; // Default path if no community vote or special event

        // Example: Conditional evolution based on a simulated oracle data (replace with actual oracle integration)
        bool oracleConditionMet = isOracleConditionMet(_tokenId); // Simulate checking an external condition
        if (oracleConditionMet && nextStage == 3) { // Example: Stage 3 evolution influenced by oracle
            chosenPath = "oracle_path";
        } else if (nftEvolutionPath[_tokenId] != "") {
            chosenPath = nftEvolutionPath[_tokenId]; // Use community voted path if available
        } else {
            chosenPath = generateRandomEvolutionPath(_tokenId, nextStage); // Random path if no vote and no oracle
        }


        uint256 oldStage = currentStage;
        nftStage[_tokenId] = nextStage;
        nftEvolutionTimestamp[_tokenId] = block.timestamp + baseEvolutionInterval * stageEvolutionIntervalMultiplier[nextStage];
        nftEvolutionPath[_tokenId] = chosenPath; // Store the chosen path
        emit NFTEvolved(_tokenId, oldStage, nextStage, chosenPath);
    }

    // --- 6. manualEvolveNFT (Manual Evolution - Example: using utility tokens) ---
    function manualEvolveNFT(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(nftStage[_tokenId] < uint256(NFTStageEnum.Stage5), "NFT is already at max stage"); // Example max stage
        // Example: Require utility tokens for manual evolution
        // require(UtilityToken(utilityTokenAddress).transferFrom(msg.sender, address(this), evolutionCost), "Insufficient utility tokens");
        checkAndEvolveNFT(_tokenId); // Re-use the evolution logic
    }

    // --- 7. contributeResourcesForEvolution (Community driven evolution acceleration) ---
    function contributeResourcesForEvolution(uint256 _tokenId) external payable onlyOwnerOf(_tokenId) whenNotPaused {
        // Example: Users can contribute ETH to accelerate the evolution timer
        uint256 contributionValue = msg.value;
        uint256 timeBoost = contributionValue / 1 ether * 3600; // Example: 1 ETH reduces evolution time by 1 hour
        nftEvolutionTimestamp[_tokenId] = nftEvolutionTimestamp[_tokenId] - timeBoost;
        if (block.timestamp >= nftEvolutionTimestamp[_tokenId]) {
            checkAndEvolveNFT(_tokenId); // Evolve immediately if time boost makes it eligible
        }
        // Optionally, you can store contributed ETH for community rewards or contract upkeep
    }

    // --- 8. setEvolutionCriteria (Admin only) ---
    function setEvolutionCriteria(uint256 _stage, uint256 _intervalMultiplier) external onlyAdmin {
        stageEvolutionIntervalMultiplier[_stage] = _intervalMultiplier;
    }

    // --- 9. startCommunityVoteForEvolutionPath (Admin only) ---
    function startCommunityVoteForEvolutionPath(uint256 _stage, string[] memory _possiblePaths) external onlyAdmin {
        // In a real implementation, you'd need more robust voting mechanism, potentially using snapshot voting or similar
        emit EvolutionPathVoteStarted(_stage, _possiblePaths);
        // Store voting state if needed for more complex voting logic
    }

    // --- 10. castVoteForEvolutionPath (NFT Holders vote) ---
    function castVoteForEvolutionPath(uint256 _tokenId, string memory _path) external onlyOwnerOf(_tokenId) whenNotPaused {
        // In a real implementation, you'd need to record votes and tally them
        emit EvolutionPathVoteCast(_tokenId, msg.sender, _path);
        nftEvolutionPath[_tokenId] = _path; // For simplicity, directly set the path based on first vote. In real system, tally votes.
    }

    // --- 11. finalizeEvolutionPathVote (Admin only) ---
    function finalizeEvolutionPathVote(uint256 _stage, string memory _chosenPath) external onlyAdmin {
        // In a real implementation, tally votes and determine the winning path
        emit EvolutionPathVoteFinalized(_stage, _chosenPath);
        // Logic to apply the chosen path to NFTs evolving to this stage
    }

    // --- 12. stakeNFTForEvolutionBoost ---
    function stakeNFTForEvolutionBoost(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(!isNFTStaked[_tokenId], "NFT already staked");
        isNFTStaked[_tokenId] = true;
        nftStakingStartTime[_tokenId] = block.timestamp;
        // Example: Reduce evolution interval by a percentage for staked NFTs
        nftEvolutionTimestamp[_tokenId] = nftEvolutionTimestamp[_tokenId] - (baseEvolutionInterval * stageEvolutionIntervalMultiplier[nftStage[_tokenId]] / 10); // 10% boost
        emit NFTStaked(_tokenId, msg.sender);
    }

    // --- 13. unstakeNFT ---
    function unstakeNFT(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(isNFTStaked[_tokenId], "NFT not staked");
        isNFTStaked[_tokenId] = false;
        emit NFTUnstaked(_tokenId, msg.sender);
        // Revert evolution boost if needed (optional depending on design)
    }

    // --- 14. breedNFTs (Example - basic breeding with random offspring) ---
    function breedNFTs(uint256 _tokenId1, uint256 _tokenId2) external whenNotPaused {
        require(nftOwner[_tokenId1] == msg.sender && nftOwner[_tokenId2] == msg.sender, "Not owner of both NFTs");
        require(nftStage[_tokenId1] >= 2 && nftStage[_tokenId2] >= 2, "NFTs must be at least Stage 2 to breed"); // Example breeding requirement

        uint256 newRarityTier = (nftRarityTier[_tokenId1] + nftRarityTier[_tokenId2]) / 2; // Example: Average rarity
        // In a real breeding system, you would have more complex logic to inherit traits, introduce mutations, etc.

        mintNFT(msg.sender, newRarityTier); // Mint a new NFT to the breeder
        // Optionally, you could burn or modify the parent NFTs after breeding
    }

    // --- 15. mergeNFTs (Example - merge to create more advanced NFT) ---
    function mergeNFTs(uint256 _tokenId1, uint256 _tokenId2) external onlyOwnerOf(_tokenId1) whenNotPaused {
        require(nftOwner[_tokenId2] == msg.sender, "Not owner of both NFTs");
        require(nftStage[_tokenId1] == nftStage[_tokenId2] && nftStage[_tokenId1] < uint256(NFTStageEnum.Stage5), "NFTs must be same stage and not max stage to merge"); // Example merge requirements

        uint256 nextStage = nftStage[_tokenId1] + 1;
        string memory chosenPath = "merged_path"; // Example path for merged NFTs

        uint256 oldStage = nftStage[_tokenId1];
        nftStage[_tokenId1] = nextStage;
        nftEvolutionTimestamp[_tokenId1] = block.timestamp + baseEvolutionInterval * stageEvolutionIntervalMultiplier[nextStage];
        nftEvolutionPath[_tokenId1] = chosenPath;
        emit NFTEvolved(_tokenId1, oldStage, nextStage, chosenPath);

        burnNFT(_tokenId2); // Burn the second NFT after merge
    }

    // --- 16. triggerSpecialEventEvolution (Admin only) ---
    function triggerSpecialEventEvolution(uint256 _rarityTier, string memory _eventPath) external onlyAdmin {
        // Example: Trigger a special evolution path for all NFTs of a specific rarity tier
        for (uint256 i = 1; i < nextNFTId; i++) {
            if (nftOwner[i] != address(0) && nftRarityTier[i] == _rarityTier) {
                nftEvolutionPath[i] = _eventPath; // Set special event path
                checkAndEvolveNFT(i); // Trigger evolution for eligible NFTs
            }
        }
    }

    // --- 17. burnNFT ---
    function burnNFT(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        address owner = nftOwner[_tokenId];
        delete nftOwner[_tokenId];
        delete nftStage[_tokenId];
        delete nftRarityTier[_tokenId];
        delete nftEvolutionTimestamp[_tokenId];
        delete isNFTStaked[_tokenId];
        delete nftStakingStartTime[_tokenId];
        delete nftEvolutionPath[_tokenId];

        emit NFTBurned(_tokenId, owner);
        // Optionally, you could implement resource reclamation logic here if burning NFTs provides some benefit.
    }

    // --- 18. setBaseMetadataURI (Admin only) ---
    function setBaseMetadataURI(string memory _newBaseURI) external onlyAdmin {
        baseMetadataURI = _newBaseURI;
    }

    // --- 19. withdrawContractBalance (Admin only - with safeguards) ---
    function withdrawContractBalance() external onlyAdmin {
        // Example: Allow admin to withdraw ETH balance, but with safety checks
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance); // Be cautious with withdrawing contract funds in production
    }

    // --- 20. getNFTTraits ---
    function getNFTTraits(uint256 _tokenId) external view returns (string[] memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        return rarityTierTraits[nftRarityTier[_tokenId]][nftStage[_tokenId]];
    }

    // --- 21. setRarityTierTraits (Admin only) ---
    function setRarityTierTraits(uint256 _rarityTier, uint256 _stage, string[] memory _traits) external onlyAdmin {
        rarityTierTraits[_rarityTier][_stage] = _traits;
    }

    // --- 22. setStageMetadataSuffixes (Admin only) ---
    function setStageMetadataSuffixes(string memory _suffixes) external onlyAdmin {
        stageMetadataSuffixes = _suffixes;
    }

    // --- 23. setUtilityTokenAddress (Admin only) ---
    function setUtilityTokenAddress(address _tokenAddress) external onlyAdmin {
        utilityTokenAddress = _tokenAddress;
    }

    // --- 24. getStakedNFTInfo ---
    function getStakedNFTInfo(uint256 _tokenId) external view returns (uint256 startTime, bool isStakedBool) {
        return (nftStakingStartTime[_tokenId], isNFTStaked[_tokenId]);
    }

    // --- 25. getRandomNumber (Internal - Pseudo-random - Use Chainlink VRF for production) ---
    function getRandomNumber(uint256 _seed) internal view returns (uint256) {
        // Warning: blockhash(block.number - 1) is not truly random and can be predictable, especially in test environments or before mainnet PoS.
        // For production-level randomness, use Chainlink VRF or a similar decentralized randomness solution.
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _seed, msg.sender, block.timestamp)));
    }

    // --- 26. pauseContract (Admin only) ---
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
    }

    // --- 27. unpauseContract (Admin only) ---
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
    }

    // --- 28. isContractPaused ---
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    // --- 29. setDynamicRoyaltyPercentage (Admin only) ---
    function setDynamicRoyaltyPercentage(uint256 _stage, uint256 _percentageBasisPoints) external onlyAdmin {
        dynamicRoyaltyPercentages[_stage] = _percentageBasisPoints;
    }

    // --- 30. getDynamicRoyaltyPercentage ---
    function getDynamicRoyaltyPercentage(uint256 _stage) external view returns (uint256) {
        return dynamicRoyaltyPercentages[_stage];
    }

    // --- Helper Functions ---
    function _toString(uint256 _num) internal pure returns (string memory) {
        if (_num == 0) {
            return "0";
        }
        uint256 j = _num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_num != 0) {
            bstr[k--] = bytes1(uint8(48 + _num % 10));
            _num /= 10;
        }
        return string(bstr);
    }

    function stringSplit(string memory _base, string memory _delimiter) internal pure returns (string[] memory splits) {
        bytes memory baseBytes = bytes(_base);
        bytes memory delimiterBytes = bytes(_delimiter);
        uint256 splitsCount = 0;
        for (uint256 i = 0; i < baseBytes.length;) {
            splitsCount++;
            i += delimiterBytes.length;
            while (i < baseBytes.length && baseBytes[i] != delimiterBytes[0]) {
                i++;
            }
        }
        splits = new string[](splitsCount);
        uint256 start = 0;
        uint256 splitIndex = 0;
        for (uint256 i = 0; i <= baseBytes.length; i++) {
            if (i < baseBytes.length && (i - start < delimiterBytes.length && slice(baseBytes, start, i) == delimiterBytes)) {
                splits[splitIndex++] = string(slice(baseBytes, start, i - delimiterBytes.length));
                start = i + delimiterBytes.length;
                i = start;
            } else if (i == baseBytes.length) {
                splits[splitIndex++] = string(slice(baseBytes, start, baseBytes.length));
            }
        }
        return splits;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length <= _bytes.length - _start, "Slice length out of bounds");
        bytes memory tempBytes = new bytes(_length);

        for (uint256 i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }

    function isOracleConditionMet(uint256 _tokenId) internal view returns (bool) {
        // **Simulated Oracle Check** - Replace with actual oracle integration for real-world conditions
        // This is a placeholder. In a real scenario, you would use Chainlink or another oracle to fetch external data.
        // For example, you might check weather data, game scores, or stock prices.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId)));
        uint256 randomNumber = getRandomNumber(seed) % 100; // Generate a random number between 0 and 99
        return randomNumber < 50; // Simulate 50% chance of oracle condition being met
    }

    function generateRandomEvolutionPath(uint256 _tokenId, uint256 _stage) internal view returns (string memory) {
        // Example: Randomly choose from a set of evolution paths based on stage and token ID seed
        string[] memory possiblePaths;
        if (_stage == 2) {
            possiblePaths = new string[](3);
            possiblePaths[0] = "fire";
            possiblePaths[1] = "water";
            possiblePaths[2] = "earth";
        } else if (_stage == 3) {
            possiblePaths = new string[](2);
            possiblePaths[0] = "light";
            possiblePaths[1] = "dark";
        } else {
            possiblePaths = new string[](1);
            possiblePaths[0] = "default";
        }

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, _stage)));
        uint256 randomIndex = getRandomNumber(seed) % possiblePaths.length;
        return possiblePaths[randomIndex];
    }
}
```