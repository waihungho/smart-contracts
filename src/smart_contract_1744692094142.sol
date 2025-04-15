```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (Example - Conceptual Smart Contract)
 * @dev A smart contract implementing a dynamic NFT collection where NFTs can evolve, interact, and have unique on-chain properties.
 *
 * Function Outline & Summary:
 *
 * 1.  `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to a specified address with an initial base URI.
 * 2.  `evolveNFT(uint256 _tokenId)`: Triggers NFT evolution based on time and other on-chain conditions.
 * 3.  `checkEvolutionEligibility(uint256 _tokenId)`: Internal function to determine if an NFT is eligible for evolution.
 * 4.  `getNFTStage(uint256 _tokenId)`: Retrieves the current evolution stage of an NFT.
 * 5.  `getNFTLevel(uint256 _tokenId)`: Retrieves the current level of an NFT.
 * 6.  `trainNFT(uint256 _tokenId)`: Allows NFT owners to "train" their NFTs, increasing their level.
 * 7.  `battleNFT(uint256 _tokenId1, uint256 _tokenId2)`: Simulates a battle between two NFTs, affecting their stats or properties.
 * 8.  `stakeNFT(uint256 _tokenId)`: Allows NFT owners to stake their NFTs for potential rewards or benefits.
 * 9.  `unstakeNFT(uint256 _tokenId)`: Allows NFT owners to unstake their NFTs.
 * 10. `calculateStakingReward(uint256 _tokenId)`: Calculates the potential staking reward for an NFT.
 * 11. `claimStakingReward(uint256 _tokenId)`: Allows NFT owners to claim their staking rewards.
 * 12. `setBaseURI(string memory _newBaseURI)`: Allows the contract owner to set a new base URI for metadata.
 * 13. `tokenURI(uint256 _tokenId)`: Overrides the standard tokenURI to dynamically generate metadata based on NFT properties.
 * 14. `pauseContract()`: Allows the contract owner to pause core functionalities.
 * 15. `unpauseContract()`: Allows the contract owner to unpause core functionalities.
 * 16. `withdrawFunds()`: Allows the contract owner to withdraw contract balance.
 * 17. `setEvolutionStageData(uint8 _stage, string memory _stageName, uint256 _evolutionTime)`: Allows the owner to configure evolution stage parameters.
 * 18. `getEvolutionStageData(uint8 _stage)`: Retrieves data for a specific evolution stage.
 * 19. `setTrainingCost(uint256 _cost)`: Allows the owner to set the cost for training NFTs.
 * 20. `getTrainingCost()`: Retrieves the current training cost.
 * 21. `setBattleReward(uint256 _reward)`: Allows the owner to set the reward for winning a battle.
 * 22. `getBattleReward()`: Retrieves the current battle reward.
 * 23. `setStakingRewardRate(uint256 _rate)`: Allows the owner to set the staking reward rate.
 * 24. `getStakingRewardRate()`: Retrieves the current staking reward rate.
 */

contract DynamicNFTEvolution is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI;

    // NFT Stage Enum
    enum NFTStage {
        Egg,
        Hatchling,
        Juvenile,
        Adult,
        Elder
    }

    // Struct to define evolution stages
    struct EvolutionStage {
        string stageName;
        uint256 evolutionTime; // Time in seconds after minting to evolve to this stage
        // Add more stage-specific attributes here if needed (e.g., image URI parts, stat boosts)
    }

    mapping(uint256 => NFTStage) public nftStage;
    mapping(uint256 => uint256) public nftLevel;
    mapping(uint256 => uint256) public lastEvolutionTime;
    mapping(uint256 => uint256) public stakingStartTime;
    mapping(uint256 => bool) public isStaked;

    EvolutionStage[] public evolutionStages;
    uint256 public trainingCost = 0.01 ether; // Example training cost
    uint256 public battleReward = 0.05 ether;   // Example battle reward
    uint256 public stakingRewardRate = 10;       // Example reward rate (per day per NFT, adjust as needed)

    event NFTMinted(uint256 tokenId, address to);
    event NFTEvolved(uint256 tokenId, NFTStage newStage);
    event NFTTrained(uint256 tokenId, uint256 newLevel);
    event NFTBattled(uint256 tokenId1, uint256 tokenId2, uint256 winnerTokenId, uint256 loserTokenId);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event StakingRewardClaimed(uint256 tokenId, address owner, uint256 reward);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        _setupInitialEvolutionStages();
    }

    // --- Initial Setup ---

    function _setupInitialEvolutionStages() private {
        evolutionStages.push(EvolutionStage({stageName: "Egg", evolutionTime: 0})); // Stage 0: Egg (initial)
        evolutionStages.push(EvolutionStage({stageName: "Hatchling", evolutionTime: 86400})); // Stage 1: Hatchling (1 day)
        evolutionStages.push(EvolutionStage({stageName: "Juvenile", evolutionTime: 259200})); // Stage 2: Juvenile (3 days)
        evolutionStages.push(EvolutionStage({stageName: "Adult", evolutionTime: 604800}));    // Stage 3: Adult (7 days)
        evolutionStages.push(EvolutionStage({stageName: "Elder", evolutionTime: 1209600}));   // Stage 4: Elder (14 days)
    }

    // --- Core NFT Functions ---

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to receive the NFT.
     * @param _baseURI The base URI for the NFT metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(_to, tokenId);
        nftStage[tokenId] = NFTStage.Egg; // Initial stage
        nftLevel[tokenId] = 1;         // Initial level
        lastEvolutionTime[tokenId] = block.timestamp;
        baseURI = _baseURI; // Set base URI for this minting session - could be improved for dynamic URI management
        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Triggers the evolution of an NFT if it meets the criteria.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT");

        NFTStage currentStage = nftStage[_tokenId];
        require(currentStage != NFTStage.Elder, "NFT is already at the final stage");

        if (checkEvolutionEligibility(_tokenId)) {
            NFTStage nextStage = NFTStage(uint8(currentStage) + 1); // Move to the next stage
            nftStage[_tokenId] = nextStage;
            lastEvolutionTime[_tokenId] = block.timestamp; // Update evolution time
            emit NFTEvolved(_tokenId, nextStage);
        } else {
            revert("NFT is not yet eligible to evolve.");
        }
    }

    /**
     * @dev Internal function to check if an NFT is eligible for evolution based on time.
     * @param _tokenId The ID of the NFT to check.
     * @return bool True if eligible for evolution, false otherwise.
     */
    function checkEvolutionEligibility(uint256 _tokenId) internal view returns (bool) {
        NFTStage currentStage = nftStage[_tokenId];
        uint256 currentStageIndex = uint256(currentStage);

        if (currentStageIndex < evolutionStages.length - 1) { // Check if there is a next stage
            uint256 nextStageEvolutionTime = evolutionStages[currentStageIndex + 1].evolutionTime;
            return (block.timestamp >= lastEvolutionTime[_tokenId] + nextStageEvolutionTime);
        }
        return false; // Already at the last stage or no next stage defined
    }

    /**
     * @dev Gets the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTStage The current evolution stage.
     */
    function getNFTStage(uint256 _tokenId) public view returns (NFTStage) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftStage[_tokenId];
    }

    /**
     * @dev Gets the current level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return uint256 The current level.
     */
    function getNFTLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftLevel[_tokenId];
    }

    /**
     * @dev Allows NFT owners to train their NFTs, increasing their level.
     * @param _tokenId The ID of the NFT to train.
     */
    function trainNFT(uint256 _tokenId) public payable whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT");
        require(msg.value >= trainingCost, "Insufficient training cost paid.");

        nftLevel[_tokenId]++; // Increase level
        payable(owner()).transfer(msg.value); // Send training cost to contract owner
        emit NFTTrained(_tokenId, nftLevel[_tokenId]);
    }

    /**
     * @dev Simulates a battle between two NFTs.
     * @param _tokenId1 The ID of the first NFT.
     * @param _tokenId2 The ID of the second NFT.
     */
    function battleNFT(uint256 _tokenId1, uint256 _tokenId2) public payable whenNotPaused nonReentrant {
        require(_exists(_tokenId1) && _exists(_tokenId2), "One or both NFTs do not exist");
        require(msg.sender == ownerOf(_tokenId1) || msg.sender == ownerOf(_tokenId2), "You are not the owner of either NFT");
        require(ownerOf(_tokenId1) != ownerOf(_tokenId2), "Cannot battle your own NFTs");
        require(msg.value >= battleReward, "Insufficient battle reward paid.");

        // Simple battle logic based on level (can be made more complex)
        uint256 level1 = nftLevel[_tokenId1];
        uint256 level2 = nftLevel[_tokenId2];

        uint256 winnerTokenId;
        uint256 loserTokenId;

        if (level1 > level2) {
            winnerTokenId = _tokenId1;
            loserTokenId = _tokenId2;
            nftLevel[_tokenId1]++; // Winner gains level
        } else if (level2 > level1) {
            winnerTokenId = _tokenId2;
            loserTokenId = _tokenId1;
            nftLevel[_tokenId2]++; // Winner gains level
        } else {
            // Tie - For simplicity, tokenId1 wins in a tie
            winnerTokenId = _tokenId1;
            loserTokenId = _tokenId2;
            nftLevel[_tokenId1]++; // Winner in tie gains level
        }
        payable(owner()).transfer(msg.value); // Send battle reward to contract owner

        emit NFTBattled(_tokenId1, _tokenId2, winnerTokenId, loserTokenId);
    }

    /**
     * @dev Allows NFT owners to stake their NFTs.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT");
        require(!isStaked[_tokenId], "NFT is already staked");

        isStaked[_tokenId] = true;
        stakingStartTime[_tokenId] = block.timestamp;
        _transfer(msg.sender, address(this), _tokenId); // Transfer NFT to contract for staking
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows NFT owners to unstake their NFTs.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(isStaked[_tokenId], "NFT is not staked");
        require(msg.sender == getApproved(_tokenId) || msg.sender == ownerOf(_tokenId), "Not approved or owner"); // Allow approved address to unstake

        isStaked[_tokenId] = false;
        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to owner
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Calculates the staking reward for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return uint256 The calculated staking reward.
     */
    function calculateStakingReward(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        require(isStaked[_tokenId], "NFT is not staked");

        uint256 timeStaked = block.timestamp - stakingStartTime[_tokenId];
        uint256 reward = (timeStaked * stakingRewardRate) / 86400; // Example: reward per day
        return reward;
    }

    /**
     * @dev Allows NFT owners to claim their staking rewards.
     * @param _tokenId The ID of the NFT.
     */
    function claimStakingReward(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(isStaked[_tokenId], "NFT is not staked");
        require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT");

        uint256 reward = calculateStakingReward(_tokenId);
        require(reward > 0, "No staking reward to claim");

        stakingStartTime[_tokenId] = block.timestamp; // Reset staking start time after claiming (or adjust logic)
        payable(msg.sender).transfer(reward); // Transfer reward to owner
        emit StakingRewardClaimed(_tokenId, msg.sender, reward);
    }


    // --- Metadata Functions ---

    /**
     * @dev Sets the base URI for token metadata. Only owner can call.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner whenNotPaused {
        baseURI = _newBaseURI;
    }

    /**
     * @inheritdoc ERC721Enumerable
     * @dev Overrides tokenURI to dynamically generate metadata based on NFT properties.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory stageName = evolutionStages[uint256(nftStage[_tokenId])].stageName;
        uint256 level = nftLevel[_tokenId];

        // Construct dynamic JSON metadata (example - customize as needed)
        string memory metadata = string(abi.encodePacked(
            '{"name": "', name(), ' #', Strings.toString(_tokenId), '",',
            '"description": "A Dynamic NFT evolving through stages. Current Stage: ', stageName, ', Level: ', Strings.toString(level), '",',
            '"image": "', baseURI, Strings.toString(_tokenId), '.png",', // Example image URI
            '"attributes": [',
                '{"trait_type": "Stage", "value": "', stageName, '"},',
                '{"trait_type": "Level", "value": ', Strings.toString(level), '}',
            ']',
            '}'
        ));

        string memory jsonBase64 = vm.base64(bytes(metadata));
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }


    // --- Admin Functions ---

    /**
     * @dev Pauses the contract, preventing core functionalities. Only owner can call.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, restoring core functionalities. Only owner can call.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance.
     */
    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Sets the data for a specific evolution stage. Only owner can call.
     * @param _stage The stage index (0, 1, 2, ...).
     * @param _stageName The name of the stage.
     * @param _evolutionTime The time in seconds to evolve to this stage from the previous one.
     */
    function setEvolutionStageData(uint8 _stage, string memory _stageName, uint256 _evolutionTime) public onlyOwner {
        require(_stage < evolutionStages.length, "Invalid stage index");
        evolutionStages[_stage] = EvolutionStage({stageName: _stageName, evolutionTime: _evolutionTime});
    }

    /**
     * @dev Retrieves data for a specific evolution stage.
     * @param _stage The stage index.
     * @return EvolutionStage The data for the specified stage.
     */
    function getEvolutionStageData(uint8 _stage) public view onlyOwner returns (EvolutionStage memory) {
        require(_stage < evolutionStages.length, "Invalid stage index");
        return evolutionStages[_stage];
    }

    /**
     * @dev Sets the cost for training NFTs. Only owner can call.
     * @param _cost The new training cost in wei.
     */
    function setTrainingCost(uint256 _cost) public onlyOwner {
        trainingCost = _cost;
    }

    /**
     * @dev Retrieves the current training cost.
     * @return uint256 The current training cost in wei.
     */
    function getTrainingCost() public view returns (uint256) {
        return trainingCost;
    }

    /**
     * @dev Sets the reward for winning a battle. Only owner can call.
     * @param _reward The new battle reward in wei.
     */
    function setBattleReward(uint256 _reward) public onlyOwner {
        battleReward = _reward;
    }

    /**
     * @dev Retrieves the current battle reward.
     * @return uint256 The current battle reward in wei.
     */
    function getBattleReward() public view returns (uint256) {
        return battleReward;
    }

    /**
     * @dev Sets the staking reward rate. Only owner can call.
     * @param _rate The new staking reward rate (adjust units as needed).
     */
    function setStakingRewardRate(uint256 _rate) public onlyOwner {
        stakingRewardRate = _rate;
    }

    /**
     * @dev Retrieves the current staking reward rate.
     * @return uint256 The current staking reward rate.
     */
    function getStakingRewardRate() public view returns (uint256) {
        return stakingRewardRate;
    }

    // --- Overrides for Pausable ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // --- Support Interfaces ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```