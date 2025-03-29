```solidity
/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT system where NFTs can evolve through various on-chain actions and conditions.
 *      This contract introduces several advanced concepts like dynamic metadata, on-chain evolution logic, resource management,
 *      staking for evolution, skill-based evolution, and community-driven evolution.
 *      It aims to be creative and trendy by incorporating elements of gamification and user interaction to drive NFT evolution.
 *
 * **Outline:**
 * 1. **Core NFT Functionality:** Minting, Burning, Transferring NFTs (ERC721 base).
 * 2. **Dynamic Metadata:**  NFT metadata changes based on evolution stage and attributes.
 * 3. **Evolution System:**
 *    - Stages of Evolution (Enum).
 *    - Evolution Requirements (Resources, Time, Skills, Community Votes).
 *    - Evolution Logic (Deterministic and Random elements).
 * 4. **Resource Management:** Internal token system to fuel evolution.
 * 5. **Staking for Evolution:** Stake NFTs to earn resources and unlock evolution paths.
 * 6. **Skill-Based Evolution:**  Achieve on-chain "skills" to enable certain evolutions.
 * 7. **Community-Driven Evolution:** Voting mechanism for specific evolution paths.
 * 8. **Attribute System:** NFTs have attributes that influence evolution and rarity.
 * 9. **Rarity System:** Dynamically calculated rarity based on attributes and evolution stage.
 * 10. **Marketplace Integration (Placeholder):** Basic functions for listing/delisting NFTs (not a full marketplace).
 * 11. **Admin Functions:**  Contract management and parameter setting.
 * 12. **Event Emission:** Comprehensive event logging for all key actions.
 * 13. **Pausing Mechanism:** Emergency pause function for security.
 * 14. **Withdrawal Mechanism:** Admin controlled withdrawal of contract balance.
 * 15. **Royalty System (Basic):** Simple royalty on secondary sales.
 * 16. **Batch Minting:** Mint multiple NFTs at once.
 * 17. **Attribute Randomization Seed:**  Controllable randomness for attribute generation.
 * 18. **Token Gating for Evolution:**  Hold a specific token to unlock certain evolutions.
 * 19. **NFT Merging (Experimental):** Combine two NFTs to create a new evolved NFT.
 * 20. **External Oracle Integration (Placeholder):**  Example of how external data could influence evolution (not fully implemented).
 *
 * **Function Summary:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to the specified address with initial metadata.
 * 2. `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT.
 * 3. `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 * 4. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 5. `getBaseURI()`: Returns the base URI for NFT metadata.
 * 6. `setBaseURI(string memory _newBaseURI)`: Admin function to set the base URI for NFT metadata.
 * 7. `evolveNFT(uint256 _tokenId, EvolutionPath _path)`: Initiates the evolution process for an NFT based on the chosen path.
 * 8. `checkEvolutionRequirements(uint256 _tokenId, EvolutionPath _path)`: Checks if an NFT meets the requirements for a specific evolution path.
 * 9. `getResourceBalance(address _owner)`: Returns the resource balance of an address.
 * 10. `mintResources(address _to, uint256 _amount)`: Admin function to mint resources to an address.
 * 11. `stakeNFT(uint256 _tokenId)`: Stakes an NFT to earn resources and potentially unlock evolution paths.
 * 12. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT.
 * 13. `claimStakingRewards(uint256 _tokenId)`: Claims accumulated staking rewards for an NFT.
 * 14. `setSkillLevel(address _owner, SkillType _skill, uint256 _level)`:  Allows setting skill levels for an address (could be earned through on-chain actions - placeholder).
 * 15. `getSkillLevel(address _owner, SkillType _skill)`: Returns the skill level of an address.
 * 16. `startCommunityVote(uint256 _tokenId, EvolutionPath _path)`: Starts a community vote for a specific evolution path for an NFT.
 * 17. `voteForEvolutionPath(uint256 _voteId, EvolutionPath _path)`: Allows users to vote on a community evolution path.
 * 18. `finalizeCommunityVote(uint256 _voteId)`: Finalizes a community vote and applies the winning evolution path (if successful).
 * 19. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in a basic internal marketplace.
 * 20. `delistNFTFromSale(uint256 _tokenId)`: Delists an NFT from sale.
 * 21. `buyNFT(uint256 _tokenId)`: Allows buying a listed NFT.
 * 22. `pauseContract()`: Pauses the contract functionality (admin function).
 * 23. `unpauseContract()`: Unpauses the contract functionality (admin function).
 * 24. `withdrawContractBalance(address _to, uint256 _amount)`: Admin function to withdraw contract balance.
 * 25. `setRoyaltyPercentage(uint256 _percentage)`: Admin function to set the royalty percentage.
 * 26. `getRoyaltyPercentage()`: Returns the current royalty percentage.
 * 27. `batchMintNFTs(address _to, uint256 _count, string memory _baseURI)`: Mints multiple NFTs in a batch.
 * 28. `setRandomSeed(uint256 _seed)`: Admin function to set the seed for attribute randomization.
 * 29. `mergeNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Merges two NFTs into a new evolved NFT (experimental).
 * 30. `setTokenGate(address _tokenAddress, EvolutionPath _path)`: Admin function to set a token gate for an evolution path.
 * 31. `getTokenGate(EvolutionPath _path)`: Returns the token gate address for an evolution path.
 * 32. `setOracleAddress(address _oracleAddress)`: Admin function to set the address of an external oracle (placeholder).
 * 33. `requestExternalDataForEvolution(uint256 _tokenId, EvolutionPath _path)`: Function to request data from an external oracle to influence evolution (placeholder).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTEvolution is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    string private _baseURI;

    // --- Enums and Structs ---
    enum EvolutionStage {
        STAGE_INITIAL,
        STAGE_ONE,
        STAGE_TWO,
        STAGE_THREE,
        STAGE_FINAL // Example stages - can be expanded
    }

    enum EvolutionPath {
        PATH_A,
        PATH_B,
        PATH_C // Example paths - can be expanded
    }

    enum SkillType {
        COMBAT,
        MAGIC,
        CRAFTING,
        TRADING // Example skills - can be expanded
    }

    struct NFTAttributes {
        uint8 strength;
        uint8 agility;
        uint8 intelligence;
        uint8 luck;
        // ... more attributes can be added
    }

    struct SaleListing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct CommunityVote {
        EvolutionPath path;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) voters;
        uint256 votesForPath;
        bool isActive;
        bool isFinalized;
    }

    // --- State Variables ---
    mapping(uint256 => EvolutionStage) public nftStage;
    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(address => uint256) public resourceBalance; // Internal resource system
    mapping(uint256 => uint256) public nftStakingStartTime;
    mapping(uint256 => SaleListing) public nftListings;
    mapping(uint256 => CommunityVote) public activeCommunityVotes;
    Counters.Counter private _voteIdCounter;
    mapping(address => mapping(SkillType => uint256)) public skillLevels;
    mapping(EvolutionPath => address) public tokenGates; // Token gating for evolution paths
    address public oracleAddress; // Placeholder for external oracle
    uint256 public royaltyPercentage = 5; // Default royalty percentage
    uint256 public randomSeed; // Seed for attribute randomization

    uint256 public resourceMintAmountPerBlock = 10; // Example resource mint rate
    uint256 public stakingRewardPerBlock = 1; // Example staking reward rate

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTBurned(uint256 tokenId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTEvolved(uint256 tokenId, EvolutionStage previousStage, EvolutionStage newStage, EvolutionPath path);
    event ResourceMinted(address to, uint256 amount);
    event ResourceSpent(address from, uint256 amount, string reason);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event StakingRewardsClaimed(uint256 tokenId, address owner, uint256 rewardAmount);
    event SkillLevelSet(address owner, SkillType skill, uint256 level);
    event CommunityVoteStarted(uint256 voteId, uint256 tokenId, EvolutionPath path);
    event VoteCast(uint256 voteId, address voter, EvolutionPath path);
    event CommunityVoteFinalized(uint256 voteId, EvolutionPath winningPath, bool success);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTDelistedFromSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ContractBalanceWithdrawn(address to, uint256 amount, address admin);
    event RoyaltyPercentageSet(uint256 percentage, address admin);
    event RandomSeedSet(uint256 seed, address admin);
    event NFTMerged(uint256 newNFTTokenId, uint256 tokenId1, uint256 tokenId2);
    event TokenGateSet(EvolutionPath path, address tokenAddress, address admin);
    event OracleAddressSet(address oracleAddress, address admin);
    event ExternalDataRequested(uint256 tokenId, EvolutionPath path, address oracleAddress);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner or approved");
        _;
    }

    modifier onlyListedNFT(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier onlySeller(uint256 _tokenId) {
        require(nftListings[_tokenId].seller == _msgSender(), "Not the seller of the NFT");
        _;
    }

    modifier validEvolutionPath(EvolutionPath _path) {
        require(_path >= EvolutionPath.PATH_A && _path <= EvolutionPath.PATH_C, "Invalid evolution path"); // Adjust range as needed
        _;
    }

    modifier validVoteId(uint256 _voteId) {
        require(activeCommunityVotes[_voteId].isActive, "Invalid or inactive vote ID");
        _;
    }


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        _baseURI = _uri;
        randomSeed = block.timestamp; // Initialize random seed with block timestamp
    }

    // --- Core NFT Functions ---
    function mintNFT(address _to, string memory _tokenURI) public onlyOwner whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI, _tokenURI))); // Combine base URI and token URI
        nftStage[tokenId] = EvolutionStage.STAGE_INITIAL;
        _generateInitialAttributes(tokenId);
        emit NFTMinted(tokenId, _to);
    }

    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
    }

    function transferNFT(address _to, uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        safeTransferFrom(_msgSender(), _to, _tokenId);
        emit NFTTransferred(_tokenId, _msgSender(), _to);
    }

    function getNFTStage(uint256 _tokenId) public view returns (EvolutionStage) {
        return nftStage[_tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner whenNotPaused {
        _baseURI = _newBaseURI;
    }

    // --- Evolution System ---
    function evolveNFT(uint256 _tokenId, EvolutionPath _path) public onlyNFTOwner(_tokenId) whenNotPaused validEvolutionPath(_path) {
        require(checkEvolutionRequirements(_tokenId, _path), "Evolution requirements not met");

        EvolutionStage currentStage = nftStage[_tokenId];
        EvolutionStage nextStage;

        // Example evolution logic - can be customized based on _path and currentStage
        if (currentStage == EvolutionStage.STAGE_INITIAL) {
            if (_path == EvolutionPath.PATH_A) {
                nextStage = EvolutionStage.STAGE_ONE;
                _applyPathAEvolution(_tokenId); // Apply path-specific attribute changes
            } else if (_path == EvolutionPath.PATH_B) {
                nextStage = EvolutionStage.STAGE_ONE;
                _applyPathBEvolution(_tokenId);
            } else {
                nextStage = EvolutionStage.STAGE_ONE;
                _applyPathCEvolution(_tokenId);
            }
        } else if (currentStage == EvolutionStage.STAGE_ONE) {
            if (_path == EvolutionPath.PATH_A) {
                nextStage = EvolutionStage.STAGE_TWO;
                _applyPathAEvolution(_tokenId);
            } else if (_path == EvolutionPath.PATH_B) {
                nextStage = EvolutionStage.STAGE_TWO;
                _applyPathBEvolution(_tokenId);
            } else {
                nextStage = EvolutionStage.STAGE_TWO;
                _applyPathCEvolution(_tokenId);
            }
        } else if (currentStage == EvolutionStage.STAGE_TWO) {
            if (_path == EvolutionPath.PATH_A) {
                nextStage = EvolutionStage.STAGE_THREE;
                _applyPathAEvolution(_tokenId);
            } else if (_path == EvolutionPath.PATH_B) {
                nextStage = EvolutionStage.STAGE_THREE;
                _applyPathBEvolution(_tokenId);
            } else {
                nextStage = EvolutionStage.STAGE_THREE;
                _applyPathCEvolution(_tokenId);
            }
        } else if (currentStage == EvolutionStage.STAGE_THREE) {
            nextStage = EvolutionStage.STAGE_FINAL; // Final stage example
            _applyPathAEvolution(_tokenId); // Example final stage evolution
        } else {
            revert("NFT is already at maximum evolution stage");
        }

        nftStage[_tokenId] = nextStage;
        _updateTokenMetadata(_tokenId); // Update token metadata to reflect evolution
        emit NFTEvolved(_tokenId, currentStage, nextStage, _path);
    }

    function checkEvolutionRequirements(uint256 _tokenId, EvolutionPath _path) public view returns (bool) {
        // Example requirements - customize based on paths and game logic
        if (_path == EvolutionPath.PATH_A) {
            return resourceBalance[_msgSender()] >= 100; // Require 100 resources for Path A
        } else if (_path == EvolutionPath.PATH_B) {
            return skillLevels[_msgSender()][SkillType.CRAFTING] >= 5; // Require level 5 crafting skill for Path B
        } else if (_path == EvolutionPath.PATH_C) {
            return getStakingDuration(_tokenId) >= 7 days; // Require staking for 7 days for Path C
        }
        return false; // Default to false if path is not recognized
    }

    // --- Resource Management ---
    function getResourceBalance(address _owner) public view returns (uint256) {
        return resourceBalance[_owner];
    }

    function mintResources(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        resourceBalance[_to] = resourceBalance[_to].add(_amount);
        emit ResourceMinted(_to, _amount);
    }

    function _spendResources(address _from, uint256 _amount, string memory _reason) internal {
        require(resourceBalance[_from] >= _amount, "Insufficient resources");
        resourceBalance[_from] = resourceBalance[_from].sub(_amount);
        emit ResourceSpent(_from, _amount, _reason);
    }

    function _generateResources() internal {
        resourceBalance[address(this)] = resourceBalance[address(this)].add(resourceMintAmountPerBlock);
    }

    function setResourceMintAmountPerBlock(uint256 _amount) public onlyOwner {
        resourceMintAmountPerBlock = _amount;
    }

    // --- Staking for Evolution ---
    function stakeNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(nftStakingStartTime[_tokenId] == 0, "NFT is already staked"); // Prevent double staking
        nftStakingStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, _msgSender());
    }

    function unstakeNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(nftStakingStartTime[_tokenId] != 0, "NFT is not staked");
        uint256 reward = calculateStakingReward(_tokenId);
        resourceBalance[_msgSender()] = resourceBalance[_msgSender()].add(reward);
        nftStakingStartTime[_tokenId] = 0; // Reset staking time
        emit NFTUnstaked(_tokenId, _msgSender());
        emit StakingRewardsClaimed(_tokenId, _msgSender(), reward);
    }

    function claimStakingRewards(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(nftStakingStartTime[_tokenId] != 0, "NFT is not staked");
        uint256 reward = calculateStakingReward(_tokenId);
        resourceBalance[_msgSender()] = resourceBalance[_msgSender()].add(reward);
        nftStakingStartTime[_tokenId] = block.timestamp; // Keep staking and update start time
        emit StakingRewardsClaimed(_tokenId, _msgSender(), reward);
    }

    function calculateStakingReward(uint256 _tokenId) public view returns (uint256) {
        if (nftStakingStartTime[_tokenId] == 0) return 0;
        uint256 duration = block.timestamp.sub(nftStakingStartTime[_tokenId]);
        return duration.div(1 days).mul(stakingRewardPerBlock); // Example: 1 reward per day staked
    }

    function getStakingDuration(uint256 _tokenId) public view returns (uint256) {
        if (nftStakingStartTime[_tokenId] == 0) return 0;
        return block.timestamp.sub(nftStakingStartTime[_tokenId]);
    }

    function setStakingRewardPerBlock(uint256 _amount) public onlyOwner {
        stakingRewardPerBlock = _amount;
    }


    // --- Skill-Based Evolution (Placeholder - needs more detailed skill acquisition logic) ---
    function setSkillLevel(address _owner, SkillType _skill, uint256 _level) public onlyOwner { // Example - Admin sets skills
        skillLevels[_owner][_skill] = _level;
        emit SkillLevelSet(_owner, _skill, _level);
    }

    function getSkillLevel(address _owner, SkillType _skill) public view returns (uint256) {
        return skillLevels[_owner][_skill];
    }

    // --- Community-Driven Evolution ---
    function startCommunityVote(uint256 _tokenId, EvolutionPath _path) public onlyNFTOwner(_tokenId) whenNotPaused validEvolutionPath(_path) {
        _voteIdCounter.increment();
        uint256 voteId = _voteIdCounter.current();
        require(!activeCommunityVotes[voteId].isActive, "Vote already active for this ID");

        activeCommunityVotes[voteId] = CommunityVote({
            path: _path,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days, // Example: 3-day voting period
            votesForPath: 0,
            isActive: true,
            isFinalized: false
        });

        emit CommunityVoteStarted(voteId, _tokenId, _path);
    }

    function voteForEvolutionPath(uint256 _voteId, EvolutionPath _path) public whenNotPaused validVoteId(_voteId) validEvolutionPath(_path) {
        require(!activeCommunityVotes[_voteId].voters[_msgSender()], "Already voted");
        require(block.timestamp < activeCommunityVotes[_voteId].endTime, "Voting period ended");
        require(_path == activeCommunityVotes[_voteId].path, "Invalid path for this vote"); // Only vote for the path associated with the vote

        activeCommunityVotes[_voteId].voters[_msgSender()] = true;
        activeCommunityVotes[_voteId].votesForPath++;
        emit VoteCast(_voteId, _msgSender(), _path);
    }

    function finalizeCommunityVote(uint256 _voteId) public whenNotPaused validVoteId(_voteId) {
        require(block.timestamp >= activeCommunityVotes[_voteId].endTime, "Voting period not ended yet");
        require(!activeCommunityVotes[_voteId].isFinalized, "Vote already finalized");

        activeCommunityVotes[_voteId].isActive = false;
        activeCommunityVotes[_voteId].isFinalized = true;

        EvolutionPath winningPath = activeCommunityVotes[_voteId].path; // Assume the proposed path wins if vote is active (can be more complex)
        bool success = activeCommunityVotes[_voteId].votesForPath > 0; // Example: Vote succeeds if at least one vote is cast

        if (success) {
            // Find an NFT associated with this vote (need to link vote to NFT - can be done by storing tokenId in CommunityVote struct if needed)
            // For now, assume the vote is general and doesn't apply to a specific NFT directly in this simplified example.
            // In a real implementation, you'd likely link a vote to an NFT and then evolve that NFT based on the vote result.
            // evolveNFT(tokenIdLinkedToVote, winningPath); // Example - need to implement linking
            emit CommunityVoteFinalized(_voteId, winningPath, true);
        } else {
            emit CommunityVoteFinalized(_voteId, winningPath, false); // Vote failed, no evolution
        }
    }


    // --- Attribute System and Randomization ---
    function _generateInitialAttributes(uint256 _tokenId) internal {
        // Example: Simple attribute randomization - can be made more complex
        uint256 rand = _generateRandomNumber();
        nftAttributes[_tokenId] = NFTAttributes({
            strength: uint8(rand % 100),
            agility: uint8((rand / 100) % 100),
            intelligence: uint8((rand / 10000) % 100),
            luck: uint8((rand / 1000000) % 100)
        });
    }

    function _applyPathAEvolution(uint256 _tokenId) internal {
        nftAttributes[_tokenId].strength += 10; // Example: Path A increases strength
        nftAttributes[_tokenId].agility += 5;
    }

    function _applyPathBEvolution(uint256 _tokenId) internal {
        nftAttributes[_tokenId].agility += 15; // Example: Path B increases agility more
        nftAttributes[_tokenId].intelligence += 5;
    }

    function _applyPathCEvolution(uint256 _tokenId) internal {
        nftAttributes[_tokenId].intelligence += 15; // Example: Path C increases intelligence more
        nftAttributes[_tokenId].strength += 5;
    }


    function _updateTokenMetadata(uint256 _tokenId) internal {
        // Example: Update token URI based on stage and attributes
        string memory stageStr;
        if (nftStage[_tokenId] == EvolutionStage.STAGE_INITIAL) stageStr = "Initial";
        else if (nftStage[_tokenId] == EvolutionStage.STAGE_ONE) stageStr = "StageOne";
        else if (nftStage[_tokenId] == EvolutionStage.STAGE_TWO) stageStr = "StageTwo";
        else if (nftStage[_tokenId] == EvolutionStage.STAGE_THREE) stageStr = "StageThree";
        else stageStr = "FinalStage";

        string memory newURI = string(abi.encodePacked(
            "metadata/", stageStr, "_", uint2str(nftAttributes[_tokenId].strength), "_",
            uint2str(nftAttributes[_tokenId].agility), "_", uint2str(nftAttributes[_tokenId].intelligence), "_",
            uint2str(nftAttributes[_tokenId].luck), ".json" // Example metadata filename structure
        ));
        _setTokenURI(_tokenId, string(abi.encodePacked(_baseURI, newURI)));
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 lsb = uint8(48 + (_i % 10));
            bstr[k] = bytes1(lsb);
            _i /= 10;
        }
        return string(bstr);
    }

    function _generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, _tokenIdCounter.current(), _msgSender(), randomSeed)));
    }

    function setRandomSeed(uint256 _seed) public onlyOwner {
        randomSeed = _seed;
        emit RandomSeedSet(_seed, _msgSender());
    }


    // --- Rarity System (Basic - could be expanded) ---
    function calculateRarityScore(uint256 _tokenId) public view returns (uint256) {
        NFTAttributes memory attrs = nftAttributes[_tokenId];
        uint256 rarityScore = uint256(attrs.strength) + uint256(attrs.agility) + uint256(attrs.intelligence) + uint256(attrs.luck);
        // Can add more complex rarity logic based on attribute combinations, stage, etc.
        return rarityScore;
    }

    // --- Marketplace Integration (Basic - not a full marketplace) ---
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        nftListings[_tokenId] = SaleListing({
            price: _price,
            seller: _msgSender(),
            isListed: true
        });
        _approve(address(this), _tokenId); // Approve contract to transfer NFT on sale
        emit NFTListedForSale(_tokenId, _price, _msgSender());
    }

    function delistNFTFromSale(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused onlyListedNFT(_tokenId) onlySeller(_tokenId) {
        nftListings[_tokenId].isListed = false;
        _approve(address(0), _tokenId); // Remove approval
        emit NFTDelistedFromSale(_tokenId, nftListings[_tokenId].price, _msgSender());
    }

    function buyNFT(uint256 _tokenId) public payable whenNotPaused onlyListedNFT(_tokenId) {
        SaleListing storage listing = nftListings[_tokenId];
        require(_msgSender() != listing.seller, "Seller cannot buy their own NFT");
        require(msg.value >= listing.price, "Insufficient funds sent");

        nftListings[_tokenId].isListed = false; // Delist after purchase
        _approve(address(0), _tokenId); // Remove approval

        uint256 royaltyAmount = listing.price.mul(royaltyPercentage).div(100); // Calculate royalty
        uint256 sellerProceeds = listing.price.sub(royaltyAmount);

        // Transfer funds
        payable(listing.seller).transfer(sellerProceeds);
        payable(owner()).transfer(royaltyAmount); // Send royalty to contract owner (can be changed)

        safeTransferFrom(listing.seller, _msgSender(), _tokenId);
        emit NFTBought(_tokenId, listing.price, _msgSender(), listing.seller);
    }

    // --- Admin Functions ---
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }

    function withdrawContractBalance(address _to, uint256 _amount) public onlyOwner {
        payable(_to).transfer(_amount);
        emit ContractBalanceWithdrawn(_to, _amount, _msgSender());
    }

    function setRoyaltyPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_percentage, _msgSender());
    }

    function getRoyaltyPercentage() public view returns (uint256) {
        return royaltyPercentage;
    }

    function batchMintNFTs(address _to, uint256 _count, string memory _baseURI) public onlyOwner whenNotPaused {
        for (uint256 i = 0; i < _count; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(_to, tokenId);
            _setTokenURI(tokenId, string(abi.encodePacked(_baseURI, string(uint2str(tokenId)), ".json"))); // Example sequential URI
            nftStage[tokenId] = EvolutionStage.STAGE_INITIAL;
            _generateInitialAttributes(tokenId);
            emit NFTMinted(tokenId, _to);
        }
    }

    // --- NFT Merging (Experimental) ---
    function mergeNFTs(uint256 _tokenId1, uint256 _tokenId2) public onlyNFTOwner(_tokenId1) onlyNFTOwner(_tokenId2) whenNotPaused {
        require(_tokenId1 != _tokenId2, "Cannot merge the same NFT with itself");
        require(ownerOf(_tokenId1) == ownerOf(_tokenId2), "NFTs must be owned by the same address");

        // Example merging logic - can be customized based on game design
        _tokenIdCounter.increment();
        uint256 newNFTTokenId = _tokenIdCounter.current();
        _safeMint(ownerOf(_tokenId1), newNFTTokenId);
        _setTokenURI(newNFTTokenId, string(abi.encodePacked(_baseURI, "merged_nft_", string(uint2str(newNFTTokenId)), ".json"))); // Example URI
        nftStage[newNFTTokenId] = EvolutionStage.STAGE_ONE; // New NFT starts at stage 1 (example)
        _generateMergedAttributes(newNFTTokenId, _tokenId1, _tokenId2); // Combine attributes

        burnNFT(_tokenId1);
        burnNFT(_tokenId2);

        emit NFTMerged(newNFTTokenId, _tokenId1, _tokenId2);
    }

    function _generateMergedAttributes(uint256 _newTokenId, uint256 _tokenId1, uint256 _tokenId2) internal {
        // Example: Average attributes of merged NFTs - can be more complex
        NFTAttributes memory attrs1 = nftAttributes[_tokenId1];
        NFTAttributes memory attrs2 = nftAttributes[_tokenId2];

        nftAttributes[_newTokenId] = NFTAttributes({
            strength: uint8((uint256(attrs1.strength) + uint256(attrs2.strength)) / 2),
            agility: uint8((uint256(attrs1.agility) + uint256(attrs2.agility)) / 2),
            intelligence: uint8((uint256(attrs1.intelligence) + uint256(attrs2.intelligence)) / 2),
            luck: uint8((uint256(attrs1.luck) + uint256(attrs2.luck)) / 2)
        });
    }

    // --- Token Gating for Evolution ---
    function setTokenGate(address _tokenAddress, EvolutionPath _path) public onlyOwner validEvolutionPath(_path) {
        tokenGates[_path] = _tokenAddress;
        emit TokenGateSet(_path, _tokenAddress, _msgSender());
    }

    function getTokenGate(EvolutionPath _path) public view validEvolutionPath(_path) returns (address) {
        return tokenGates[_path];
    }

    function _checkTokenGate(address _owner, EvolutionPath _path) internal view returns (bool) {
        address gateToken = tokenGates[_path];
        if (gateToken == address(0)) return true; // No token gate set, allow evolution
        IERC20 token = IERC20(gateToken);
        return token.balanceOf(_owner) > 0; // Require at least 1 token for gating
    }

    // --- External Oracle Integration (Placeholder - needs actual oracle implementation) ---
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress, _msgSender());
    }

    function requestExternalDataForEvolution(uint256 _tokenId, EvolutionPath _path) public onlyNFTOwner(_tokenId) whenNotPaused validEvolutionPath(_path) {
        require(oracleAddress != address(0), "Oracle address not set");
        // In a real implementation, you would interact with the oracle contract here.
        // This is a placeholder - actual oracle integration requires more complex logic.
        // Example: Call oracle function to get data, and then in a callback function,
        // process the data and potentially trigger evolution based on oracle response.

        // For this example, we just emit an event indicating a request was made.
        emit ExternalDataRequested(_tokenId, _path, oracleAddress);

        // Placeholder logic - for a real oracle, you'd need a callback function to process the data.
        // _processOracleDataAndEvolve(_tokenId, _path, oracleData); // Example callback function
    }

    // --- Internal function to process oracle data (Placeholder - needs actual oracle response handling) ---
    // function _processOracleDataAndEvolve(uint256 _tokenId, EvolutionPath _path, bytes memory _oracleData) internal {
    //     // Example: Decode oracle data (assuming it's encoded in some format)
    //     uint256 externalValue = abi.decode(_oracleData, (uint256));

    //     if (externalValue > 50) { // Example condition based on oracle data
    //         evolveNFT(_tokenId, _path); // Evolve if oracle data meets condition
    //     } else {
    //         // Handle case where oracle data does not meet evolution condition
    //         // Maybe emit an event or revert transaction depending on desired behavior.
    //     }
    // }

    // --- Blockly tick to generate resources periodically ---
    function tick() public {
        _generateResources();
    }
}
```