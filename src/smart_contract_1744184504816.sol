```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Gamified Staking
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a dynamic NFT marketplace that incorporates AI-generated art,
 *      gamified staking, and advanced marketplace features. This is a conceptual example
 *      demonstrating creative and trendy functionalities and is not intended for production use
 *      without thorough security audits and testing.

 * **Contract Outline & Function Summary:**

 * **State Variables:**
 *   - `owner`: Address of the contract owner.
 *   - `nftName`: Name of the NFT collection.
 *   - `nftSymbol`: Symbol of the NFT collection.
 *   - `baseURI`: Base URI for NFT metadata.
 *   - `totalSupply`: Total number of NFTs minted.
 *   - `nftTraits`: Mapping to store NFT traits (dynamic properties).
 *   - `nftAIArtHashes`: Mapping to store hashes of AI-generated art associated with NFTs.
 *   - `nftStakedUntil`: Mapping to store staking end times for NFTs.
 *   - `stakeRewardRate`: Reward rate for staking (per period).
 *   - `stakePeriod`: Duration of a staking period.
 *   - `marketplaceFee`: Fee for marketplace transactions (percentage).
 *   - `aiArtGenerationCost`: Cost to generate AI art for an NFT.
 *   - `isMarketplaceActive`: Boolean to control marketplace activity.
 *   - `traitEvolutionRules`: Mapping to define rules for NFT trait evolution.
 *   - `gameScores`: Mapping to store game scores for NFTs.
 *   - `minStakeDuration`: Minimum staking duration.
 *   - `maxStakeDuration`: Maximum staking duration.
 *   - `rngContractAddress`: Address of a (hypothetical) RNG contract for trait evolution randomness.
 *   - `allowedAIProviders`: Array of whitelisted AI art providers.
 *   - `traitCategories`: Array of predefined NFT trait categories.

 * **Events:**
 *   - `NFTMinted(uint256 tokenId, address minter)`: Emitted when an NFT is minted.
 *   - `NFTTransferred(uint256 tokenId, address from, address to)`: Emitted when an NFT is transferred.
 *   - `NFTStaked(uint256 tokenId, address staker, uint256 until)`: Emitted when an NFT is staked.
 *   - `NFTUnstaked(uint256 tokenId, address unstaker)`: Emitted when an NFT is unstaked.
 *   - `NFTTraitEvolved(uint256 tokenId, string traitName, string newValue)`: Emitted when an NFT trait evolves.
 *   - `AIArtGenerated(uint256 tokenId, bytes32 artHash, address provider)`: Emitted when AI art is generated for an NFT.
 *   - `NFTListedForSale(uint256 tokenId, address seller, uint256 price)`: Emitted when an NFT is listed for sale.
 *   - `NFTDelistedFromSale(uint256 tokenId, address seller)`: Emitted when an NFT is delisted from sale.
 *   - `NFTBought(uint256 tokenId, address buyer, address seller, uint256 price)`: Emitted when an NFT is bought.
 *   - `MarketplaceFeeUpdated(uint256 newFee)`: Emitted when the marketplace fee is updated.
 *   - `AIArtCostUpdated(uint256 newCost)`: Emitted when the AI art generation cost is updated.
 *   - `StakeRewardRateUpdated(uint256 newRate)`: Emitted when the stake reward rate is updated.
 *   - `TraitEvolutionRuleSet(string traitName, string ruleDescription)`: Emitted when a trait evolution rule is set.
 *   - `GameScoreUpdated(uint256 tokenId, uint256 newScore)`: Emitted when an NFT's game score is updated.
 *   - `AIProviderAdded(address provider)`: Emitted when an AI provider is added to the whitelist.
 *   - `AIProviderRemoved(address provider)`: Emitted when an AI provider is removed from the whitelist.
 *   - `MarketplaceStatusChanged(bool isActive)`: Emitted when the marketplace status is changed (active/inactive).

 * **Modifiers:**
 *   - `onlyOwner()`: Modifier to restrict function access to the contract owner.
 *   - `marketplaceActive()`: Modifier to ensure marketplace functions are only callable when active.

 * **Functions:**
 *   **NFT Core Functions:**
 *     1. `mintNFT(address _to, string memory _initialTrait1, string memory _initialTrait2) payable`: Mints a new NFT with initial traits and triggers AI art generation.
 *     2. `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 *     3. `getNFTTraits(uint256 _tokenId) view returns (string[] memory)`: Retrieves the current traits of an NFT.
 *     4. `getNFTArtHash(uint256 _tokenId) view returns (bytes32)`: Retrieves the AI art hash associated with an NFT.
 *     5. `tokenURI(uint256 _tokenId) view returns (string memory)`: Returns the URI for the NFT metadata.
 *     6. `supportsInterface(bytes4 interfaceId) view returns (bool)`: Supports ERC721 interface.

 *   **Dynamic NFT & Trait Evolution Functions:**
 *     7. `evolveNFTTraits(uint256 _tokenId) payable`: Triggers the evolution of NFT traits based on predefined rules (may involve randomness or external factors).
 *     8. `setTraitEvolutionRule(string memory _traitName, string memory _ruleDescription)`: Sets or updates the evolution rule for a specific trait (admin function).
 *     9. `getTraitEvolutionRule(string memory _traitName) view returns (string memory)`: Retrieves the evolution rule for a specific trait.

 *   **AI Art Generation Functions:**
 *     10. `requestAIArtGeneration(uint256 _tokenId, address _aiProvider) payable`: Allows users to request AI art generation for their NFT from a whitelisted provider.
 *     11. `setAIArtHash(uint256 _tokenId, bytes32 _artHash) onlyOwner`: Allows the owner (or a designated oracle) to set the AI art hash for an NFT.
 *     12. `addAllowedAIProvider(address _provider) onlyOwner`: Adds an AI provider to the whitelist.
 *     13. `removeAllowedAIProvider(address _provider) onlyOwner`: Removes an AI provider from the whitelist.
 *     14. `getAIArtGenerationCost() view returns (uint256)`: Returns the current cost for AI art generation.
 *     15. `setAIArtGenerationCost(uint256 _newCost) onlyOwner`: Sets the cost for AI art generation (admin function).

 *   **Gamified Staking Functions:**
 *     16. `stakeNFT(uint256 _tokenId, uint256 _duration)`: Stakes an NFT for a specified duration to earn rewards or unlock features.
 *     17. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT and claims accumulated rewards.
 *     18. `calculateStakeReward(uint256 _tokenId) view returns (uint256)`: Calculates the staking reward for an NFT.
 *     19. `setStakeRewardRate(uint256 _newRate) onlyOwner`: Sets the staking reward rate (admin function).
 *     20. `getStakeRewardRate() view returns (uint256)`: Returns the current staking reward rate.
 *     21. `setStakePeriod(uint256 _newPeriod) onlyOwner`: Sets the staking period duration (admin function).
 *     22. `getStakePeriod() view returns (uint256)`: Returns the current staking period duration.
 *     23. `setMinStakeDuration(uint256 _minDuration) onlyOwner`: Sets the minimum staking duration.
 *     24. `setMaxStakeDuration(uint256 _maxDuration) onlyOwner`: Sets the maximum staking duration.

 *   **Marketplace Functions:**
 *     25. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *     26. `delistNFTFromSale(uint256 _tokenId)`: Removes an NFT listing from the marketplace.
 *     27. `buyNFT(uint256 _tokenId) payable`: Buys an NFT listed on the marketplace.
 *     28. `setMarketplaceFee(uint256 _newFee) onlyOwner`: Sets the marketplace transaction fee (admin function).
 *     29. `getMarketplaceFee() view returns (uint256)`: Returns the current marketplace transaction fee.
 *     30. `toggleMarketplaceActive() onlyOwner`: Activates or deactivates the marketplace (admin function).
 *     31. `isMarketplaceLive() view returns (bool)`: Checks if the marketplace is currently active.

 *   **Game & Community Functions (Optional - Can be expanded):**
 *     32. `updateGameScore(uint256 _tokenId, uint256 _newScore) onlyOwner`: Updates the game score associated with an NFT (admin/game integration).
 *     33. `getGameScore(uint256 _tokenId) view returns (uint256)`: Retrieves the game score for an NFT.
 *     34. `addTraitCategory(string memory _categoryName) onlyOwner`: Adds a new trait category.
 *     35. `getTraitCategories() view returns (string[] memory)`: Returns a list of all trait categories.

 *   **Admin & Utility Functions:**
 *     36. `setBaseURI(string memory _newBaseURI) onlyOwner`: Sets the base URI for NFT metadata (admin function).
 *     37. `withdrawFunds(address payable _recipient, uint256 _amount) onlyOwner`: Allows the owner to withdraw contract balance.
 *     38. `pauseContract() onlyOwner`: Pauses critical contract functionalities (circuit breaker).
 *     39. `unpauseContract() onlyOwner`: Resumes paused contract functionalities.
 *     40. `isContractPaused() view returns (bool)`: Checks if the contract is currently paused.
 */
contract DynamicNFTMarketplace {
    // State variables
    address public owner;
    string public nftName = "Dynamic AI Art NFT";
    string public nftSymbol = "DAINFT";
    string public baseURI;
    uint256 public totalSupply;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string[]) public nftTraits; // Dynamic traits for NFTs
    mapping(uint256 => bytes32) public nftAIArtHashes; // Hashes of AI generated art
    mapping(uint256 => uint256) public nftStakedUntil; // Staking end time for NFTs
    uint256 public stakeRewardRate = 1; // Reward per staking period
    uint256 public stakePeriod = 7 days; // Default staking period
    uint256 public marketplaceFee = 250; // 2.5% marketplace fee (in basis points, 10000 = 100%)
    uint256 public aiArtGenerationCost = 0.01 ether; // Cost for AI art generation
    bool public isMarketplaceActive = true;
    mapping(string => string) public traitEvolutionRules; // Rules for trait evolution
    mapping(uint256 => uint256) public gameScores; // Game scores associated with NFTs
    uint256 public minStakeDuration = 1 days;
    uint256 public maxStakeDuration = 30 days;
    address public rngContractAddress; // Address of a hypothetical RNG contract (for future randomness)
    address[] public allowedAIProviders;
    string[] public traitCategories;
    bool public paused = false;

    // Marketplace listings (tokenId => price)
    mapping(uint256 => uint256) public nftListings;
    mapping(uint256 => address) public nftSellers;

    // Events
    event NFTMinted(uint256 tokenId, address minter);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTStaked(uint256 tokenId, address staker, uint256 until);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event NFTTraitEvolved(uint256 tokenId, uint256 indexed tokenIdEvent, string traitName, string newValue);
    event AIArtGenerated(uint256 tokenId, bytes32 artHash, address provider);
    event NFTListedForSale(uint256 tokenId, address seller, uint256 price);
    event NFTDelistedFromSale(uint256 tokenId, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event MarketplaceFeeUpdated(uint256 newFee);
    event AIArtCostUpdated(uint256 newCost);
    event StakeRewardRateUpdated(uint256 newRate);
    event TraitEvolutionRuleSet(string traitName, string ruleDescription);
    event GameScoreUpdated(uint256 tokenId, uint256 newScore);
    event AIProviderAdded(address provider);
    event AIProviderRemoved(address provider);
    event MarketplaceStatusChanged(bool isActive);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier marketplaceActive() {
        require(isMarketplaceActive, "Marketplace is not active.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Constructor
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    // --- NFT Core Functions ---
    /// @notice Mints a new NFT with initial traits and triggers AI art generation.
    /// @param _to The address to mint the NFT to.
    /// @param _initialTrait1 The first initial trait of the NFT.
    /// @param _initialTrait2 The second initial trait of the NFT.
    function mintNFT(address _to, string memory _initialTrait1, string memory _initialTrait2) payable whenNotPaused public {
        require(msg.value >= aiArtGenerationCost, "Insufficient funds for AI art generation.");
        uint256 tokenId = ++totalSupply;
        ownerOf[tokenId] = _to;
        balanceOf[_to]++;
        nftTraits[tokenId] = [_initialTrait1, _initialTrait2]; // Set initial traits
        emit NFTMinted(tokenId, _to);
        _requestAIArtGeneration(tokenId); // Internal call to request AI art generation
    }

    /// @notice Transfers an NFT to another address.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) whenNotPaused public {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        address from = msg.sender;
        address to = _to;
        _transfer(from, to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerOf[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @notice Retrieves the current traits of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return string[] An array of strings representing the NFT's traits.
    function getNFTTraits(uint256 _tokenId) view public returns (string[] memory) {
        return nftTraits[_tokenId];
    }

    /// @notice Retrieves the AI art hash associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return bytes32 The bytes32 hash of the AI-generated art.
    function getNFTArtHash(uint256 _tokenId) view public returns (bytes32) {
        return nftAIArtHashes[_tokenId];
    }

    /// @inheritdoc ERC721Metadata
    function tokenURI(uint256 _tokenId) view public returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory base = baseURI;
        // In a real application, this would construct a dynamic URI based on tokenId, traits, art hash, etc.
        return string(abi.encodePacked(base, Strings.toString(_tokenId)));
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return ownerOf[_tokenId] != address(0);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) view virtual public returns (bool) {
        return interfaceId == 0x80ac58cd; // ERC721Metadata
    }

    // --- Dynamic NFT & Trait Evolution Functions ---
    /// @notice Triggers the evolution of NFT traits based on predefined rules.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFTTraits(uint256 _tokenId) payable whenNotPaused public {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        // Example evolution logic - can be made more complex using traitEvolutionRules, RNG, etc.
        string[] memory currentTraits = nftTraits[_tokenId];
        string memory trait1 = currentTraits[0];
        string memory trait2 = currentTraits[1];

        // Simple example: Trait evolution based on current traits (can be replaced with more advanced logic)
        if (keccak256(abi.encodePacked(trait1)) == keccak256(abi.encodePacked("Fire"))) {
            trait1 = "Evolved Fire";
        } else if (keccak256(abi.encodePacked(trait2)) == keccak256(abi.encodePacked("Water"))) {
            trait2 = "Evolved Water";
        }

        nftTraits[_tokenId] = [trait1, trait2];
        emit NFTTraitEvolved(_tokenId, _tokenId, "Trait1", trait1); // Example event for trait evolution
        emit NFTTraitEvolved(_tokenId, _tokenId, "Trait2", trait2);
    }

    /// @notice Sets or updates the evolution rule for a specific trait (admin function).
    /// @param _traitName The name of the trait.
    /// @param _ruleDescription A description of the evolution rule.
    function setTraitEvolutionRule(string memory _traitName, string memory _ruleDescription) onlyOwner public {
        traitEvolutionRules[_traitName] = _ruleDescription;
        emit TraitEvolutionRuleSet(_traitName, _ruleDescription);
    }

    /// @notice Retrieves the evolution rule for a specific trait.
    /// @param _traitName The name of the trait.
    /// @return string The description of the evolution rule.
    function getTraitEvolutionRule(string memory _traitName) view public returns (string memory) {
        return traitEvolutionRules[_traitName];
    }

    // --- AI Art Generation Functions ---
    /// @notice Internal function to request AI art generation (triggered on mint).
    /// @param _tokenId The ID of the NFT for which to request AI art.
    function _requestAIArtGeneration(uint256 _tokenId) internal {
        // In a real application, this would trigger an off-chain process (e.g., using Chainlink Functions, or a custom oracle)
        // to communicate with an AI art generation service.
        // For this example, we'll simulate setting a placeholder hash directly after a delay.
        // In a real scenario, the AI provider would call `setAIArtHash` after generating the art.

        // Simulate AI art generation delay (for demonstration purposes only)
        // In a real implementation, this would be handled off-chain.
        // For simplicity, we will set a dummy hash directly now.

        bytes32 dummyArtHash = keccak256(abi.encodePacked("AI Generated Art for Token ", Strings.toString(_tokenId)));
        setAIArtHash(_tokenId, dummyArtHash); // Directly set the hash for demonstration
        emit AIArtGenerated(_tokenId, dummyArtHash, address(0)); // Provider address would be the AI service address in real use.

        // In a real implementation, you might emit an event to trigger an off-chain AI service, e.g.
        // emit AIArtGenerationRequested(_tokenId, /* parameters for AI service */);
    }


    /// @notice Allows the owner (or a designated oracle) to set the AI art hash for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _artHash The bytes32 hash of the AI-generated art.
    function setAIArtHash(uint256 _tokenId, bytes32 _artHash) onlyOwner public {
        nftAIArtHashes[_tokenId] = _artHash;
        emit AIArtGenerated(_tokenId, _artHash, msg.sender); // Or the actual provider address if it's from an oracle
    }

    /// @notice Adds an AI provider to the whitelist.
    /// @param _provider The address of the AI provider to add.
    function addAllowedAIProvider(address _provider) onlyOwner public {
        allowedAIProviders.push(_provider);
        emit AIProviderAdded(_provider);
    }

    /// @notice Removes an AI provider from the whitelist.
    /// @param _provider The address of the AI provider to remove.
    function removeAllowedAIProvider(address _provider) onlyOwner public {
        for (uint256 i = 0; i < allowedAIProviders.length; i++) {
            if (allowedAIProviders[i] == _provider) {
                delete allowedAIProviders[i];
                // To keep array contiguous, shift elements after deletion (optional, can also just leave a zero address)
                for (uint256 j = i; j < allowedAIProviders.length - 1; j++) {
                    allowedAIProviders[j] = allowedAIProviders[j + 1];
                }
                allowedAIProviders.pop();
                emit AIProviderRemoved(_provider);
                return;
            }
        }
        revert("Provider not found in whitelist.");
    }

    /// @notice Returns the current cost for AI art generation.
    /// @return uint256 The cost in wei.
    function getAIArtGenerationCost() view public returns (uint256) {
        return aiArtGenerationCost;
    }

    /// @notice Sets the cost for AI art generation (admin function).
    /// @param _newCost The new cost in wei.
    function setAIArtGenerationCost(uint256 _newCost) onlyOwner public {
        aiArtGenerationCost = _newCost;
        emit AIArtCostUpdated(_newCost);
    }

    // --- Gamified Staking Functions ---
    /// @notice Stakes an NFT for a specified duration.
    /// @param _tokenId The ID of the NFT to stake.
    /// @param _duration The duration to stake for, in seconds.
    function stakeNFT(uint256 _tokenId, uint256 _duration) whenNotPaused public {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(nftStakedUntil[_tokenId] < block.timestamp, "NFT already staked."); // Prevent re-staking before unstaking
        require(_duration >= minStakeDuration && _duration <= maxStakeDuration, "Invalid stake duration.");

        nftStakedUntil[_tokenId] = block.timestamp + _duration;
        emit NFTStaked(_tokenId, msg.sender, nftStakedUntil[_tokenId]);
    }

    /// @notice Unstakes an NFT and claims accumulated rewards.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) whenNotPaused public {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(nftStakedUntil[_tokenId] > block.timestamp, "NFT is not staked or stake period ended.");

        uint256 reward = calculateStakeReward(_tokenId);
        nftStakedUntil[_tokenId] = 0; // Reset staking status
        payable(msg.sender).transfer(reward); // Transfer reward to staker (example - can be different reward mechanisms)
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Calculates the staking reward for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The calculated reward (in wei, for example).
    function calculateStakeReward(uint256 _tokenId) view public returns (uint256) {
        if (nftStakedUntil[_tokenId] > block.timestamp) {
            uint256 stakedTime = nftStakedUntil[_tokenId] - block.timestamp;
            uint256 periodsStaked = stakedTime / stakePeriod;
            return periodsStaked * stakeRewardRate; // Simple reward calculation
        }
        return 0; // No reward if not staked or stake ended
    }

    /// @notice Sets the staking reward rate (admin function).
    /// @param _newRate The new reward rate per staking period.
    function setStakeRewardRate(uint256 _newRate) onlyOwner public {
        stakeRewardRate = _newRate;
        emit StakeRewardRateUpdated(_newRate);
    }

    /// @notice Returns the current staking reward rate.
    /// @return uint256 The current reward rate.
    function getStakeRewardRate() view public returns (uint256) {
        return stakeRewardRate;
    }

    /// @notice Sets the staking period duration (admin function).
    /// @param _newPeriod The new staking period duration in seconds.
    function setStakePeriod(uint256 _newPeriod) onlyOwner public {
        stakePeriod = _newPeriod;
        emit StakeRewardRateUpdated(_newPeriod); // Reusing event as it's related to staking parameter update
    }

    /// @notice Returns the current staking period duration.
    /// @return uint256 The current staking period duration in seconds.
    function getStakePeriod() view public returns (uint256) {
        return stakePeriod;
    }

    /// @notice Sets the minimum staking duration.
    /// @param _minDuration The minimum duration in seconds.
    function setMinStakeDuration(uint256 _minDuration) onlyOwner public {
        minStakeDuration = _minDuration;
    }

    /// @notice Sets the maximum staking duration.
    /// @param _maxDuration The maximum duration in seconds.
    function setMaxStakeDuration(uint256 _maxDuration) onlyOwner public {
        maxStakeDuration = _maxDuration;
    }


    // --- Marketplace Functions ---
    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listNFTForSale(uint256 _tokenId, uint256 _price) whenNotPaused marketplaceActive public {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(nftListings[_tokenId] == 0, "NFT already listed for sale.");
        require(nftStakedUntil[_tokenId] < block.timestamp, "NFT is staked and cannot be listed."); // Prevent listing staked NFTs

        nftListings[_tokenId] = _price;
        nftSellers[_tokenId] = msg.sender;
        emit NFTListedForSale(_tokenId, msg.sender, _price);
    }

    /// @notice Removes an NFT listing from the marketplace.
    /// @param _tokenId The ID of the NFT to delist.
    function delistNFTFromSale(uint256 _tokenId) whenNotPaused marketplaceActive public {
        require(nftSellers[_tokenId] == msg.sender, "You are not the seller of this NFT listing.");
        require(nftListings[_tokenId] > 0, "NFT is not listed for sale.");

        delete nftListings[_tokenId];
        delete nftSellers[_tokenId];
        emit NFTDelistedFromSale(_tokenId, msg.sender);
    }

    /// @notice Buys an NFT listed on the marketplace.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) payable whenNotPaused marketplaceActive public {
        require(nftListings[_tokenId] > 0, "NFT is not listed for sale.");
        require(msg.value >= nftListings[_tokenId], "Insufficient funds to buy NFT.");

        uint256 price = nftListings[_tokenId];
        address seller = nftSellers[_tokenId];

        delete nftListings[_tokenId];
        delete nftSellers[_tokenId];

        _transfer(seller, msg.sender, _tokenId);

        // Transfer funds to seller with marketplace fee deduction
        uint256 feeAmount = (price * marketplaceFee) / 10000;
        uint256 sellerPayout = price - feeAmount;
        payable(seller).transfer(sellerPayout);
        payable(owner).transfer(feeAmount); // Send fee to contract owner

        emit NFTBought(_tokenId, msg.sender, seller, price);
    }

    /// @notice Sets the marketplace transaction fee (admin function).
    /// @param _newFee The new marketplace fee in basis points (e.g., 250 for 2.5%).
    function setMarketplaceFee(uint256 _newFee) onlyOwner public {
        marketplaceFee = _newFee;
        emit MarketplaceFeeUpdated(_newFee);
    }

    /// @notice Returns the current marketplace transaction fee.
    /// @return uint256 The current marketplace fee in basis points.
    function getMarketplaceFee() view public returns (uint256) {
        return marketplaceFee;
    }

    /// @notice Activates or deactivates the marketplace (admin function).
    function toggleMarketplaceActive() onlyOwner public {
        isMarketplaceActive = !isMarketplaceActive;
        emit MarketplaceStatusChanged(isMarketplaceActive);
    }

    /// @notice Checks if the marketplace is currently active.
    /// @return bool True if the marketplace is active, false otherwise.
    function isMarketplaceLive() view public returns (bool) {
        return isMarketplaceActive;
    }

    // --- Game & Community Functions ---
    /// @notice Updates the game score associated with an NFT (admin/game integration).
    /// @param _tokenId The ID of the NFT.
    /// @param _newScore The new game score.
    function updateGameScore(uint256 _tokenId, uint256 _newScore) onlyOwner public {
        gameScores[_tokenId] = _newScore;
        emit GameScoreUpdated(_tokenId, _newScore);
    }

    /// @notice Retrieves the game score for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The game score.
    function getGameScore(uint256 _tokenId) view public returns (uint256) {
        return gameScores[_tokenId];
    }

    /// @notice Adds a new trait category.
    /// @param _categoryName The name of the trait category.
    function addTraitCategory(string memory _categoryName) onlyOwner public {
        traitCategories.push(_categoryName);
    }

    /// @notice Returns a list of all trait categories.
    /// @return string[] An array of trait category names.
    function getTraitCategories() view public returns (string[] memory) {
        return traitCategories;
    }


    // --- Admin & Utility Functions ---
    /// @notice Sets the base URI for NFT metadata (admin function).
    /// @param _newBaseURI The new base URI.
    function setBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    /// @notice Allows the owner to withdraw contract balance.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount to withdraw in wei.
    function withdrawFunds(address payable _recipient, uint256 _amount) onlyOwner public {
        require(_amount <= address(this).balance, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
    }

    /// @notice Pauses critical contract functionalities (circuit breaker).
    function pauseContract() onlyOwner public {
        paused = true;
    }

    /// @notice Resumes paused contract functionalities.
    function unpauseContract() onlyOwner public {
        paused = false;
    }

    /// @notice Checks if the contract is currently paused.
    function isContractPaused() view public returns (bool) {
        return paused;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```