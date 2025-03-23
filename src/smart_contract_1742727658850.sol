```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic NFT system where NFTs can evolve through various on-chain actions and time,
 *      influenced by user interactions, rarity, and potentially external factors (simulated within the contract for demonstration).
 *      It features a complex attribute system, evolution stages, breeding (simplified), staking for evolution boost,
 *      and community governance aspects.
 *
 * **Outline & Function Summary:**
 *
 * **Core NFT Functionality (ERC721Enumerable base):**
 *   1. `mintNFT(address _to, uint256 _rarityLevel)`: Mints a new NFT with a specified rarity level.
 *   2. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given token, dynamically generated based on NFT attributes and stage.
 *   3. `transferNFT(address _from, address _to, uint256 _tokenId)`:  Transfers ownership of an NFT. (Internal use, using safeTransferFrom for external).
 *   4. `getNFTInfo(uint256 _tokenId)`: Retrieves comprehensive information about a specific NFT.
 *   5. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 *   6. `getNFTAttributes(uint256 _tokenId)`: Returns the current attributes of an NFT.
 *   7. `getRarityLevel(uint256 _tokenId)`: Returns the rarity level of an NFT.
 *   8. `getEvolutionTimeLeft(uint256 _tokenId)`: Returns the time remaining until the next evolution stage is reached for an NFT.
 *
 * **Dynamic Evolution & Attributes:**
 *   9. `feedNFT(uint256 _tokenId, uint256 _foodAmount)`: Allows users to "feed" their NFT, potentially boosting attribute growth and evolution speed.
 *  10. `trainNFT(uint256 _tokenId, uint256 _trainingHours)`: Allows users to "train" their NFT, specifically increasing certain attributes based on training type (simulated).
 *  11. `evolveNFT(uint256 _tokenId)`: Manually triggers the evolution check for an NFT, progressing it to the next stage if conditions are met.
 *  12. `_checkAndEvolve(uint256 _tokenId)`: Internal function to automatically check for evolution eligibility based on time and attributes. (Used by feed/train/time-based).
 *  13. `_applyEvolutionChanges(uint256 _tokenId)`: Internal function to apply attribute changes and stage progression during evolution.
 *
 * **Staking & Boosts:**
 *  14. `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFT to earn evolution boost multipliers.
 *  15. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT, removing the evolution boost.
 *  16. `getStakeBoostMultiplier(uint256 _tokenId)`: Returns the current evolution boost multiplier for a staked NFT.
 *
 * **Breeding (Simplified):**
 *  17. `breedNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Allows users to breed two NFTs (simplified - no complex genetics, just based on parent rarities). Mints a new NFT child.
 *  18. `_calculateChildRarity(uint256 _rarity1, uint256 _rarity2)`: Internal function to calculate the rarity of a child NFT based on parent rarities.
 *
 * **Governance & Admin (Owner-Controlled Parameters for Demonstration):**
 *  19. `setEvolutionTimers(uint256[] memory _stageTimers)`: Allows the contract owner to set the time required for each evolution stage.
 *  20. `setBaseAttributeRanges(uint256[4][] memory _attributeRanges)`: Allows the contract owner to set the base attribute ranges for different rarity levels.
 *  21. `setRarityProbabilities(uint256[] memory _rarityProbabilities)`: Allows the contract owner to set the probabilities for each rarity level during minting.
 *  22. `pauseContract()`: Pauses core functionality of the contract (minting, evolve, breed, stake).
 *  23. `unpauseContract()`: Resumes contract functionality after pausing.
 *  24. `withdraw()`: Allows the contract owner to withdraw any accumulated Ether in the contract.
 *
 * **Internal Utilities:**
 *  - `_generateRandomNumber(uint256 _seed)`: Internal function to simulate randomness (for demonstration - in production, use Chainlink VRF or similar).
 *  - `_updateTokenMetadata(uint256 _tokenId)`: Internal function to update the token URI based on current NFT state.
 *
 * **Events:**
 *  - `NFTMinted(uint256 tokenId, address owner, uint256 rarityLevel)`
 *  - `NFTTransferred(uint256 tokenId, address from, address to)`
 *  - `NFTFed(uint256 tokenId, address feeder, uint256 foodAmount)`
 *  - `NFTTrained(uint256 tokenId, address trainer, uint256 trainingHours)`
 *  - `NFTEvolved(uint256 tokenId, uint256 newStage)`
 *  - `NFTStaked(uint256 tokenId, address staker)`
 *  - `NFTUnstaked(uint256 tokenId, address unstaker)`
 *  - `NFTBred(uint256 childTokenId, uint256 parentTokenId1, uint256 parentTokenId2, address breeder)`
 *  - `ContractPaused()`
 *  - `ContractUnpaused()`
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTEvolution is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    enum RarityLevel { Common, Uncommon, Rare, Epic, Legendary }
    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Elder } // Example stages - can be extended

    struct NFTData {
        RarityLevel rarity;
        EvolutionStage stage;
        uint256[] attributes; // Example attributes: [Strength, Agility, Wisdom, Vitality]
        uint256 lastEvolutionTime;
        uint256 lastInteractionTime;
        uint256 feedCount;
        uint256 trainingCount;
        bool isStaked;
    }

    struct EvolutionStageConfig {
        uint256 timerSeconds; // Time required in seconds to evolve to this stage
        uint256[] attributeThresholds; // Minimum attribute values required to evolve to this stage (optional, can be empty)
        uint256[] attributeBoosts;      // Attribute boosts applied upon reaching this stage
    }

    struct RarityConfig {
        RarityLevel level;
        uint256 mintProbabilityPercentage; // Probability of minting this rarity level
        uint256[4] attributeRangeMin;     // Minimum values for attributes at this rarity
        uint256[4] attributeRangeMax;     // Maximum values for attributes at this rarity
    }

    // --- State Variables ---

    mapping(uint256 => NFTData) public nftData;
    mapping(uint256 => EvolutionStageConfig) public evolutionStageConfigs;
    mapping(RarityLevel => RarityConfig) public rarityConfigs;
    mapping(uint256 => uint256) public stakeBoostMultipliers; // TokenId => Multiplier

    uint256[] public rarityProbabilities; // Probabilities for each rarity level (set by owner)
    uint256[] public evolutionTimers;     // Time in seconds for each evolution stage (set by owner)
    string public metadataBaseURI;        // Base URI for token metadata (set by owner)

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner, RarityLevel rarityLevel);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTFed(uint256 tokenId, address feeder, uint256 foodAmount);
    event NFTTrained(uint256 tokenId, address trainer, uint256 trainingHours);
    event NFTEvolved(uint256 tokenId, EvolutionStage newStage);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event NFTBred(uint256 childTokenId, uint256 parentTokenId1, uint256 parentTokenId2, address breeder);
    event ContractPaused();
    event ContractUnpaused();

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, string memory _metadataBaseURI) ERC721(_name, _symbol) {
        metadataBaseURI = _metadataBaseURI;

        // --- Default Configurations (Example - Owner can adjust later) ---
        _setDefaultRarityConfig();
        _setDefaultEvolutionConfig();
    }

    // --- External Functions ---

    /**
     * @dev Mints a new NFT to the specified address with a randomly determined rarity level.
     * @param _to The address to mint the NFT to.
     * @param _rarityLevel The desired rarity level (for testing/controlled minting, otherwise use random rarity selection).
     */
    function mintNFT(address _to, uint256 _rarityLevel) public whenNotPaused {
        require(_rarityLevel < uint256(type(RarityLevel).max) + 1, "Invalid rarity level");
        RarityLevel rarity = RarityLevel(_rarityLevel); // For testing/controlled minting
        //RarityLevel rarity = _selectRandomRarity(); // For random rarity selection based on probabilities

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);

        // Initialize NFT Data
        nftData[tokenId] = NFTData({
            rarity: rarity,
            stage: EvolutionStage.Egg,
            attributes: _generateInitialAttributes(rarity),
            lastEvolutionTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            feedCount: 0,
            trainingCount: 0,
            isStaked: false
        });
        stakeBoostMultipliers[tokenId] = 100; // Default boost multiplier for unstaked NFTs (100% boost)

        _updateTokenMetadata(tokenId); // Generate initial metadata
        emit NFTMinted(tokenId, _to, rarity);
    }

    /**
     * @dev Returns the metadata URI for a given token ID. Dynamically generates metadata based on NFT attributes and stage.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");
        // In a real application, this would likely point to off-chain storage or on-chain metadata generation.
        // For this example, we construct a simple URI.
        return string(abi.encodePacked(metadataBaseURI, "/", Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev Safely transfers an NFT from one address to another.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        safeTransferFrom(_from, _to, _tokenId);
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Retrieves comprehensive information about a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTData struct containing NFT information.
     */
    function getNFTInfo(uint256 _tokenId) public view returns (NFTData memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId];
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The EvolutionStage enum value.
     */
    function getNFTStage(uint256 _tokenId) public view returns (EvolutionStage) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId].stage;
    }

    /**
     * @dev Returns the current attributes of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of uint256 representing the NFT's attributes.
     */
    function getNFTAttributes(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId].attributes;
    }

    /**
     * @dev Returns the rarity level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The RarityLevel enum value.
     */
    function getRarityLevel(uint256 _tokenId) public view returns (RarityLevel) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId].rarity;
    }

    /**
     * @dev Returns the time remaining until the next evolution stage can be reached for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The remaining time in seconds, or 0 if ready to evolve.
     */
    function getEvolutionTimeLeft(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        EvolutionStage currentStage = nftData[_tokenId].stage;
        if (currentStage == EvolutionStage.Elder) return 0; // Max stage reached

        uint256 nextStageTimer = evolutionStageConfigs[uint256(currentStage) + 1].timerSeconds; // Get timer for next stage
        uint256 timeElapsed = block.timestamp - nftData[_tokenId].lastEvolutionTime;
        if (timeElapsed >= nextStageTimer) {
            return 0; // Ready to evolve
        } else {
            return nextStageTimer - timeElapsed; // Time remaining
        }
    }

    /**
     * @dev Allows users to "feed" their NFT, potentially boosting attribute growth and evolution speed.
     * @param _tokenId The ID of the NFT to feed.
     * @param _foodAmount The amount of food given to the NFT.
     */
    function feedNFT(uint256 _tokenId, uint256 _foodAmount) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_foodAmount > 0, "Food amount must be positive");

        nftData[_tokenId].feedCount += _foodAmount;
        nftData[_tokenId].lastInteractionTime = block.timestamp;

        // Example: Small attribute boost upon feeding (can be customized)
        for (uint256 i = 0; i < nftData[_tokenId].attributes.length; i++) {
            nftData[_tokenId].attributes[i] += (_foodAmount / 10); // Example: 10 food units give +1 attribute point
        }

        _checkAndEvolve(_tokenId); // Check for evolution after feeding
        emit NFTFed(_tokenId, _msgSender(), _foodAmount);
    }

    /**
     * @dev Allows users to "train" their NFT, specifically increasing certain attributes.
     * @param _tokenId The ID of the NFT to train.
     * @param _trainingHours The number of hours spent training.
     */
    function trainNFT(uint256 _tokenId, uint256 _trainingHours) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_trainingHours > 0, "Training hours must be positive");

        nftData[_tokenId].trainingCount += _trainingHours;
        nftData[_tokenId].lastInteractionTime = block.timestamp;

        // Example: Training boosts specific attributes (can be customized and made more complex)
        uint256 attributeToBoostIndex = _generateRandomNumber(_tokenId + block.timestamp) % nftData[_tokenId].attributes.length; // Random attribute for simplicity
        nftData[_tokenId].attributes[attributeToBoostIndex] += (_trainingHours * 2); // Example: 1 training hour gives +2 attribute points

        _checkAndEvolve(_tokenId); // Check for evolution after training
        emit NFTTrained(_tokenId, _msgSender(), _trainingHours);
    }

    /**
     * @dev Manually triggers the evolution check for an NFT. Can be called by the owner to initiate evolution if conditions are met.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        _checkAndEvolve(_tokenId);
    }

    /**
     * @dev Allows users to stake their NFT to earn evolution boost multipliers.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(!nftData[_tokenId].isStaked, "NFT is already staked");

        nftData[_tokenId].isStaked = true;
        stakeBoostMultipliers[_tokenId] = 150; // Example: 150% boost when staked
        emit NFTStaked(_tokenId, _msgSender());
    }

    /**
     * @dev Allows users to unstake their NFT, removing the evolution boost.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(nftData[_tokenId].isStaked, "NFT is not staked");

        nftData[_tokenId].isStaked = false;
        stakeBoostMultipliers[_tokenId] = 100; // Revert to default boost
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    /**
     * @dev Returns the current evolution boost multiplier for a staked NFT.
     * @param _tokenId The ID of the NFT.
     * @return The boost multiplier percentage (e.g., 100 for 100%, 150 for 150%).
     */
    function getStakeBoostMultiplier(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        return stakeBoostMultipliers[_tokenId];
    }

    /**
     * @dev Allows users to breed two of their NFTs to create a new child NFT. (Simplified breeding - no complex genetics).
     * @param _tokenId1 The ID of the first parent NFT.
     * @param _tokenId2 The ID of the second parent NFT.
     */
    function breedNFTs(uint256 _tokenId1, uint256 _tokenId2) public whenNotPaused {
        require(_exists(_tokenId1) && _exists(_tokenId2), "One or both parent NFTs do not exist");
        require(ownerOf(_tokenId1) == _msgSender() && ownerOf(_tokenId2) == _msgSender(), "You must own both parent NFTs");
        require(nftData[_tokenId1].stage >= EvolutionStage.Juvenile && nftData[_tokenId2].stage >= EvolutionStage.Juvenile, "Parent NFTs must be at least Juvenile stage to breed");

        RarityLevel childRarity = _calculateChildRarity(nftData[_tokenId1].rarity, nftData[_tokenId2].rarity);

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();
        _mint(_msgSender(), childTokenId);

        // Initialize child NFT data (simplified - inherits some properties from parents, can be more complex)
        nftData[childTokenId] = NFTData({
            rarity: childRarity,
            stage: EvolutionStage.Egg, // Child starts as an egg
            attributes: _generateInitialAttributes(childRarity), // Generate attributes based on child rarity
            lastEvolutionTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            feedCount: 0,
            trainingCount: 0,
            isStaked: false
        });
        stakeBoostMultipliers[childTokenId] = 100; // Default boost

        _updateTokenMetadata(childTokenId);
        emit NFTBred(childTokenId, _tokenId1, _tokenId2, _msgSender());
    }


    // --- Owner-Controlled Functions ---

    /**
     * @dev Sets the time required for each evolution stage.
     * @param _stageTimers An array of time durations (in seconds) for each stage (starting from Hatchling onwards).
     */
    function setEvolutionTimers(uint256[] memory _stageTimers) public onlyOwner {
        require(_stageTimers.length == uint256(type(EvolutionStage).max), "Incorrect number of evolution timers provided");
        for (uint256 i = 1; i <= uint256(type(EvolutionStage).max); i++) { // Start from stage 1 (Hatchling)
            evolutionStageConfigs[i].timerSeconds = _stageTimers[i-1]; // Adjust index for array
        }
        evolutionTimers = _stageTimers; // Store for easy retrieval
    }

    /**
     * @dev Sets the base attribute ranges for each rarity level.
     * @param _attributeRanges A 2D array where each inner array represents [min_attribute1, max_attribute1, min_attribute2, max_attribute2, ...] for each rarity level.
     */
    function setBaseAttributeRanges(uint256[4][] memory _attributeRanges) public onlyOwner {
        require(_attributeRanges.length == uint256(type(RarityLevel).max) + 1, "Incorrect number of attribute ranges provided");
        for (uint256 i = 0; i <= uint256(type(RarityLevel).max); i++) {
            rarityConfigs[RarityLevel(i)].attributeRangeMin = [_attributeRanges[i][0], _attributeRanges[i][1], _attributeRanges[i][2], _attributeRanges[i][3]];
            rarityConfigs[RarityLevel(i)].attributeRangeMax = [_attributeRanges[i][4], _attributeRanges[i][5], _attributeRanges[i][6], _attributeRanges[i][7]];
        }
    }

    /**
     * @dev Sets the probabilities for each rarity level during minting.
     * @param _rarityProbabilities An array of probabilities (percentages) for each rarity level in order (Common, Uncommon, Rare, Epic, Legendary). Sum must be 100.
     */
    function setRarityProbabilities(uint256[] memory _rarityProbabilities) public onlyOwner {
        require(_rarityProbabilities.length == uint256(type(RarityLevel).max) + 1, "Incorrect number of rarity probabilities provided");
        uint256 totalProbability = 0;
        for (uint256 i = 0; i < _rarityProbabilities.length; i++) {
            totalProbability += _rarityProbabilities[i];
            rarityConfigs[RarityLevel(i)].mintProbabilityPercentage = _rarityProbabilities[i];
        }
        require(totalProbability == 100, "Total rarity probabilities must sum to 100");
        rarityProbabilities = _rarityProbabilities; // Store for easy retrieval
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param _metadataBaseURI The new base URI string.
     */
    function setMetadataBaseURI(string memory _metadataBaseURI) public onlyOwner {
        metadataBaseURI = _metadataBaseURI;
    }

    /**
     * @dev Pauses the contract, preventing minting, evolving, breeding, staking, and unstaking.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, resuming normal functionality.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether held in the contract.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Internal Functions ---

    /**
     * @dev Internal function to check if an NFT is eligible for evolution and perform the evolution if so.
     * @param _tokenId The ID of the NFT to check.
     */
    function _checkAndEvolve(uint256 _tokenId) internal {
        EvolutionStage currentStage = nftData[_tokenId].stage;
        if (currentStage == EvolutionStage.Elder) return; // Max stage reached

        EvolutionStage nextStage = EvolutionStage(uint256(currentStage) + 1);
        uint256 nextStageTimer = evolutionStageConfigs[uint256(nextStage)].timerSeconds;
        uint256 timeElapsed = block.timestamp - nftData[_tokenId].lastEvolutionTime;

        if (timeElapsed >= _applyStakeBoost(nextStageTimer, _tokenId)) { // Apply stake boost to evolution timer
            _applyEvolutionChanges(_tokenId, nextStage);
        }
    }

    /**
     * @dev Internal function to apply attribute changes and stage progression during evolution.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _nextStage The next evolution stage to progress to.
     */
    function _applyEvolutionChanges(uint256 _tokenId, EvolutionStage _nextStage) internal {
        nftData[_tokenId].stage = _nextStage;
        nftData[_tokenId].lastEvolutionTime = block.timestamp;

        // Apply attribute boosts from evolution stage config
        uint256[] memory stageBoosts = evolutionStageConfigs[uint256(_nextStage)].attributeBoosts;
        for (uint256 i = 0; i < nftData[_tokenId].attributes.length; i++) {
            nftData[_tokenId].attributes[i] += stageBoosts[i];
        }

        _updateTokenMetadata(_tokenId);
        emit NFTEvolved(_tokenId, _nextStage);
    }

    /**
     * @dev Internal function to select a random rarity level based on defined probabilities.
     * @return The randomly selected RarityLevel.
     */
    function _selectRandomRarity() internal view returns (RarityLevel) {
        uint256 randomNumber = _generateRandomNumber(block.timestamp + block.number) % 100; // Random number 0-99

        uint256 cumulativeProbability = 0;
        for (uint256 i = 0; i <= uint256(type(RarityLevel).max); i++) {
            cumulativeProbability += rarityConfigs[RarityLevel(i)].mintProbabilityPercentage;
            if (randomNumber < cumulativeProbability) {
                return RarityLevel(i);
            }
        }
        return RarityLevel.Common; // Should not reach here in normal cases, but default to Common as fallback
    }

    /**
     * @dev Internal function to generate initial attributes for an NFT based on its rarity level.
     * @param _rarity The rarity level of the NFT.
     * @return An array of uint256 representing the initial attributes.
     */
    function _generateInitialAttributes(RarityLevel _rarity) internal view returns (uint256[] memory) {
        uint256[] memory attributes = new uint256[](4); // 4 attributes as example
        for (uint256 i = 0; i < attributes.length; i++) {
            uint256 minVal = rarityConfigs[_rarity].attributeRangeMin[i];
            uint256 maxVal = rarityConfigs[_rarity].attributeRangeMax[i];
            attributes[i] = minVal + (_generateRandomNumber(block.timestamp + i) % (maxVal - minVal + 1));
        }
        return attributes;
    }

    /**
     * @dev Internal function to calculate the rarity of a child NFT based on the rarity of its parents. (Simplified logic).
     * @param _rarity1 Rarity of parent 1.
     * @param _rarity2 Rarity of parent 2.
     * @return The calculated rarity of the child NFT.
     */
    function _calculateChildRarity(RarityLevel _rarity1, RarityLevel _rarity2) internal view returns (RarityLevel) {
        // Example: Child rarity is the average of parent rarities (can be more complex)
        uint256 parentRaritySum = uint256(_rarity1) + uint256(_rarity2);
        uint256 averageRarity = parentRaritySum / 2;
        if (averageRarity > uint256(type(RarityLevel).max)) {
            averageRarity = uint256(type(RarityLevel).max); // Cap at max rarity
        }
        return RarityLevel(averageRarity);
    }

    /**
     * @dev Internal function to update the token URI based on the current NFT state (stage, attributes, etc.).
     *      This is a placeholder. In a real application, you would likely have a more sophisticated metadata generation system.
     * @param _tokenId The ID of the NFT.
     */
    function _updateTokenMetadata(uint256 _tokenId) internal {
        // In a real application, you would update the token URI (e.g., to IPFS)
        // based on the NFT's current attributes, stage, rarity, etc.
        // This could involve calling an off-chain service or generating metadata on-chain if feasible.
        // For this example, we are just using a simple URI structure based on tokenId which is sufficient for demonstration of dynamic evolution.
        // Example:
        // string memory newMetadataURI = generateMetadataURI(_tokenId); // Hypothetical function
        // _setTokenURI(_tokenId, newMetadataURI); // If ERC721 supports setting URI directly (not standard)
    }

    /**
     * @dev Internal function to generate a pseudo-random number. **Warning: Not secure for production randomness. Use Chainlink VRF or similar for secure randomness on-chain.**
     * @param _seed Seed value for the random number generation.
     * @return A pseudo-random number.
     */
    function _generateRandomNumber(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _seed, msg.sender, block.difficulty)));
    }

    /**
     * @dev Internal function to apply stake boost multiplier to evolution timer.
     * @param _baseTimer Original evolution timer in seconds.
     * @param _tokenId The ID of the NFT.
     * @return Boosted evolution timer in seconds.
     */
    function _applyStakeBoost(uint256 _baseTimer, uint256 _tokenId) internal view returns (uint256) {
        uint256 boostMultiplier = stakeBoostMultipliers[_tokenId];
        return (_baseTimer * 100) / boostMultiplier; // Example: 150% boost means timer becomes (timer * 100) / 150 = timer * (2/3) - faster evolution
    }

    // --- Default Configuration Setup (Called in Constructor) ---

    function _setDefaultRarityConfig() internal {
        rarityProbabilities = [50, 30, 15, 4, 1]; // Example probabilities: Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1%
        uint256[4][] memory defaultAttributeRanges = [
            [10, 20, 10, 20, 10, 20, 10, 20], // Common: [min_str, max_str, min_agi, max_agi, min_wis, max_wis, min_vit, max_vit]
            [20, 35, 20, 35, 20, 35, 20, 35], // Uncommon
            [35, 55, 35, 55, 35, 55, 35, 55], // Rare
            [55, 80, 55, 80, 55, 80, 55, 80], // Epic
            [80, 100, 80, 100, 80, 100, 80, 100] // Legendary
        ];
        setBaseAttributeRanges(defaultAttributeRanges);
        setRarityProbabilities(rarityProbabilities);
    }

    function _setDefaultEvolutionConfig() internal {
        evolutionTimers = [60, 120, 180, 300]; // Example timers in seconds: Hatchling, Juvenile, Adult, Elder (Egg stage has no timer)
        setEvolutionTimers(evolutionTimers);

        evolutionStageConfigs[uint256(EvolutionStage.Hatchling)] = EvolutionStageConfig({
            timerSeconds: evolutionTimers[0],
            attributeThresholds: new uint256[](0), // No attribute thresholds for this stage in this example
            attributeBoosts: [5, 5, 5, 5] // Example: +5 to all attributes upon reaching Hatchling
        });
        evolutionStageConfigs[uint256(EvolutionStage.Juvenile)] = EvolutionStageConfig({
            timerSeconds: evolutionTimers[1],
            attributeThresholds: new uint256[](0),
            attributeBoosts: [10, 10, 10, 10] // Example: +10 to all attributes upon reaching Juvenile
        });
        evolutionStageConfigs[uint256(EvolutionStage.Adult)] = EvolutionStageConfig({
            timerSeconds: evolutionTimers[2],
            attributeThresholds: new uint256[](0),
            attributeBoosts: [15, 15, 15, 15] // Example: +15 to all attributes upon reaching Adult
        });
        evolutionStageConfigs[uint256(EvolutionStage.Elder)] = EvolutionStageConfig({
            timerSeconds: evolutionTimers[3],
            attributeThresholds: new uint256[](0),
            attributeBoosts: [20, 20, 20, 20] // Example: +20 to all attributes upon reaching Elder
        });
    }

    // --- Utility String Conversion (for tokenURI) ---
    // From OpenZeppelin Contracts (Strings.sol) - included here for self-contained contract

    /**
     * @dev Provides a function for converting uint256 to its ASCII string representation.
     * Inspired by OraclizeAPI's implementation as well as stackoverflow answer
     * https://ethereum.stackexchange.com/questions/66488/how-to-convert-uint-to-string-in-solidity
     *
     * @param _uint256 The uint256 number to convert to string
     * @return string representation of the _uint256
     */
    library Strings {
        bytes16 private constant _SYMBOLS = "0123456789abcdef";

        function toString(uint256 _uint256) internal pure returns (string memory) {
            if (_uint256 == 0) {
                return "0";
            }
            uint256 j = _uint256;
            uint256 len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint256 k = len - 1;
            while (_uint256 != 0) {
                bstr[k--] = bytes1(uint8(48 + _uint256 % 10));
                _uint256 /= 10;
            }
            return string(bstr);
        }
    }
}
```

**Explanation of Concepts and Features:**

1.  **Dynamic NFT Evolution:** NFTs are not static images. They evolve through stages (Egg, Hatchling, Juvenile, Adult, Elder) based on time and user interaction.
2.  **Attribute System:** Each NFT has attributes (Strength, Agility, Wisdom, Vitality - example). These attributes can be boosted through feeding and training and are influenced by rarity and evolution.
3.  **Rarity Levels:** NFTs have different rarity levels (Common, Uncommon, Rare, Epic, Legendary) that affect their initial attributes and potentially their evolution paths (although not deeply implemented in this example for simplicity).
4.  **Time-Based Evolution:** NFTs automatically progress to the next evolution stage after a set amount of time has passed since their last evolution.
5.  **User Interaction (Feeding & Training):** Users can interact with their NFTs by feeding and training them. These actions can:
    *   Boost attribute growth.
    *   Potentially speed up the evolution process.
    *   Make the NFT more valuable or desirable.
6.  **Staking for Evolution Boost:** Users can stake their NFTs within the contract. Staked NFTs receive a boost multiplier, making their evolution timers faster. This adds a DeFi element and incentive to hold NFTs.
7.  **Simplified Breeding:** Users can breed two of their NFTs to create a new child NFT. The child's rarity is influenced by the parent's rarities. This introduces a breeding mechanic, although simplified in this example.
8.  **Community Governance (Owner-Controlled Parameters for Demonstration):** While not full DAO governance, the contract owner (initially the deployer) can control key parameters like:
    *   Evolution timers for each stage.
    *   Base attribute ranges for each rarity level.
    *   Probabilities of minting each rarity level.
    *   This allows for dynamic adjustment of the game economy or NFT characteristics.
9.  **Pausable Contract:** An emergency stop mechanism controlled by the owner to pause core functionalities in case of issues or upgrades.
10. **Withdraw Function:** Allows the contract owner to withdraw any Ether accumulated in the contract (e.g., from potential future features like marketplace fees).
11. **Dynamic Metadata (TokenURI):** While the `tokenURI` in this example is simplified, the concept is that it would dynamically change based on the NFT's current state (stage, attributes) to reflect its evolution. In a real application, you'd likely use a more sophisticated off-chain or on-chain metadata generation system.
12. **Randomness (Simulated):** The contract uses `keccak256` and `block.timestamp` for pseudo-randomness for demonstration purposes (rarity selection, attribute generation, training attribute selection). **In a production environment, you MUST use a secure and verifiable randomness source like Chainlink VRF to prevent manipulation.**
13. **Gas Efficiency Considerations:** While functionality is prioritized, the contract is structured with reasonable gas efficiency in mind (using mappings, structs, etc.). Further optimizations could be applied for a production-ready contract.
14. **Events:**  Emits events for all significant actions (minting, transferring, feeding, training, evolving, staking, breeding, pausing, unpausing) for off-chain monitoring and indexing.

**Advanced Concepts Demonstrated:**

*   **Dynamic NFTs:**  NFTs that change over time and based on interactions.
*   **On-Chain Evolution Logic:**  Evolution mechanics are coded directly into the smart contract, making the process decentralized and transparent.
*   **Attribute-Based NFTs:**  NFTs with defined attributes that influence their properties and evolution.
*   **Staking and Boost Mechanics:**  Integrating DeFi concepts into NFTs for utility and engagement.
*   **Simplified Breeding Mechanics:** Introducing a basic breeding system within the NFT contract.
*   **Owner-Controlled Dynamic Parameters:** Allowing for adjustable game/system parameters for adaptability.

**How to Use (Conceptual):**

1.  **Deploy the Contract:** Deploy the `DynamicNFTEvolution` contract to a compatible blockchain (e.g., Ethereum, Polygon, etc.).
2.  **Mint NFTs:** Call the `mintNFT` function (as an admin initially or open to users if designed that way) to create new NFTs. Specify the `rarityLevel` for controlled minting, or modify the function to use `_selectRandomRarity()` for probabilistic minting.
3.  **Interact with NFTs:**
    *   **Feed:** Call `feedNFT(tokenId, foodAmount)` to feed your NFT.
    *   **Train:** Call `trainNFT(tokenId, trainingHours)` to train your NFT.
    *   **Evolve (Manual):** Call `evolveNFT(tokenId)` to manually trigger an evolution check.
    *   **Stake/Unstake:** Call `stakeNFT(tokenId)` and `unstakeNFT(tokenId)` to manage staking.
    *   **Breed:** Call `breedNFTs(tokenId1, tokenId2)` to breed two NFTs you own.
4.  **View NFT Information:** Use functions like `getNFTInfo`, `getNFTStage`, `getNFTAttributes`, `getRarityLevel`, `getEvolutionTimeLeft` to query NFT data.
5.  **Admin Functions (Owner Only):** The contract owner can use functions like `setEvolutionTimers`, `setBaseAttributeRanges`, `setRarityProbabilities`, `pauseContract`, `unpauseContract`, `withdraw` to manage the contract's parameters and state.
6.  **Metadata Handling:** Implement an off-chain service or on-chain mechanism (more complex) to generate dynamic metadata based on the NFT's state. Update the `tokenURI` to point to this dynamic metadata.

**Important Considerations for Production:**

*   **Secure Randomness:** Replace `_generateRandomNumber` with Chainlink VRF or another secure on-chain randomness solution.
*   **Metadata Generation:** Implement a robust and scalable system for dynamic metadata generation (off-chain is usually more practical for complex metadata). Consider IPFS for decentralized storage of metadata assets.
*   **Gas Optimization:** Further optimize the contract for gas efficiency, especially if expecting high transaction volume.
*   **Security Audits:**  Thoroughly audit the contract for security vulnerabilities before deploying to a production environment.
*   **Error Handling and User Experience:**  Improve error messages and consider user experience aspects for interacting with the contract.
*   **Scalability:**  Consider scalability solutions if expecting a large number of NFTs and interactions.
*   **Governance:** For a truly decentralized project, explore more advanced DAO governance mechanisms instead of owner-controlled parameters.

This contract provides a solid foundation for a complex and engaging dynamic NFT system. You can expand upon these features and add more sophisticated mechanics to create a truly unique and innovative NFT experience.