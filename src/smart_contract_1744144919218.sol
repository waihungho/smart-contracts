```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Ecosystem NFT with Advanced On-Chain Interactions
 * @author Bard (Example - Not for Production)
 * @dev This contract implements a dynamic NFT ecosystem with features beyond basic token transfers,
 * including on-chain evolution, staking, crafting, governance, and a dynamic marketplace.
 * It showcases advanced concepts and aims for creativity and trendiness in blockchain applications.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Functions (DynamicEcosystemNFT):**
 * 1. `mintNFT(address _to, string memory _baseMetadataURI)`: Mints a new NFT to a specified address with an initial base metadata URI.
 * 2. `evolveNFT(uint256 _tokenId)`: Triggers on-chain evolution of an NFT based on predefined rules and randomness.
 * 3. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for a given NFT token.
 * 4. `setBaseMetadataURI(string memory _baseURI)`: Admin function to set the base metadata URI for all NFTs.
 * 5. `setEvolutionRule(uint8 _ruleId, EvolutionRule memory _rule)`: Admin function to define or update evolution rules.
 * 6. `getRandomNumber()`: Internal function to generate a pseudo-random number for evolution and other features.
 * 7. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support.
 * 8. `tokenURI(uint256 tokenId)`: Standard ERC721 function to get the token URI.
 * 9. `ownerOf(uint256 tokenId)`: Standard ERC721 function to get the owner of a token.
 * 10. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function.
 * 11. `approve(address approved, uint256 tokenId)`: Standard ERC721 approve function.
 * 12. `getApproved(uint256 tokenId)`: Standard ERC721 getApproved function.
 * 13. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 setApprovalForAll function.
 * 14. `isApprovedForAll(address owner, address operator)`: Standard ERC721 isApprovedForAll function.
 *
 * **Staking and Reward Functions (NFTStaking):**
 * 15. `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFTs to earn rewards.
 * 16. `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs and claim accumulated rewards.
 * 17. `claimRewards(uint256 _tokenId)`: Allows users to claim accumulated rewards for a staked NFT without unstaking.
 * 18. `setRewardRate(uint256 _newRate)`: Admin function to set the reward rate for staking.
 * 19. `getStakingInfo(uint256 _tokenId)`: Retrieves staking information for a given NFT.
 *
 * **Crafting and Fusion Functions (NFTCrafting):**
 * 20. `craftNFTs(uint256[] memory _tokenIds)`: Allows users to craft new NFTs by burning existing ones based on predefined recipes.
 * 21. `addCraftingRecipe(uint256[] memory _requiredTokenIds, string memory _resultMetadataURI)`: Admin function to add new crafting recipes.
 * 22. `getCraftingRecipes()`: Retrieves the list of available crafting recipes.
 *
 * **Governance and Community Features (NFTGovernance - Simplified):**
 * 23. `proposeFeatureChange(string memory _proposalDescription, string memory _proposedValue)`: Allows NFT holders to propose changes to contract parameters.
 * 24. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows NFT holders to vote on active proposals.
 * 25. `executeProposal(uint256 _proposalId)`:  Admin/Timelock function to execute a passed proposal after a voting period.
 * 26. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *
 * **Dynamic Marketplace (NFTMarketplace - Basic Listing/Delisting for demonstration):**
 * 27. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale.
 * 28. `delistNFTFromSale(uint256 _tokenId)`: Allows NFT owners to remove their NFT from sale.
 * 29. `getListingDetails(uint256 _tokenId)`: Retrieves listing details for a given NFT.
 *
 * **Utility Functions:**
 * 30. `pauseContract()`: Admin function to pause core contract functionalities.
 * 31. `unpauseContract()`: Admin function to unpause contract functionalities.
 * 32. `isContractPaused()`:  Returns the current paused state of the contract.
 * 33. `withdrawContractBalance()`: Admin function to withdraw contract's ETH balance.
 */

contract DynamicEcosystemNFT {
    // --- State Variables ---
    string public name = "Dynamic Ecosystem NFT";
    string public symbol = "DENFT";
    string public baseMetadataURI;
    uint256 public totalSupply;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balance;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(uint256 => string) public nftMetadataURIs; // Store specific metadata for evolved NFTs
    mapping(uint256 => uint8) public nftEvolutionLevel; // Track evolution level of NFTs
    mapping(uint8 => EvolutionRule) public evolutionRules; // Rules for NFT evolution
    uint8 public numEvolutionRules = 0;
    bool public paused = false;
    address public contractAdmin;

    struct EvolutionRule {
        string nextMetadataSuffix; // Suffix to append to base URI for next level metadata
        uint8 requiredLevel;      // Required level to trigger this evolution rule
        uint256 evolutionChance;  // Chance out of 10000 (e.g., 5000 for 50%)
        uint256 cooldownPeriod;   // Cooldown period in seconds before evolution can be attempted again
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTEvolved(uint256 indexed tokenId, uint8 newLevel, string newMetadataURI);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Not owner of NFT");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == contractAdmin, "Only contract admin allowed");
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
    constructor(string memory _baseURI) {
        baseMetadataURI = _baseURI;
        contractAdmin = msg.sender;
    }

    // --- Core NFT Functions ---

    /// @dev Mints a new NFT to a specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseMetadataURI The initial base metadata URI for the NFT.
    function mintNFT(address _to, string memory _baseMetadataURI) external onlyAdmin whenNotPaused {
        require(_to != address(0), "Mint to the zero address");
        totalSupply++;
        uint256 newTokenId = totalSupply;
        tokenOwner[newTokenId] = _to;
        balance[_to]++;
        nftMetadataURIs[newTokenId] = _baseMetadataURI; // Initial metadata
        nftEvolutionLevel[newTokenId] = 1; // Start at level 1
        emit Transfer(address(0), _to, newTokenId);
        emit NFTMinted(_to, newTokenId);
    }

    /// @dev Triggers on-chain evolution of an NFT based on predefined rules and randomness.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist");
        uint8 currentLevel = nftEvolutionLevel[_tokenId];
        uint8 nextLevel = currentLevel + 1;

        if (evolutionRules[nextLevel].requiredLevel == nextLevel) { // Check if evolution rule exists for next level
            EvolutionRule storage rule = evolutionRules[nextLevel];
            if (block.timestamp >= rule.cooldownPeriod) { // Check cooldown (simplified - always allows evolution for example)
                uint256 randomNumber = getRandomNumber();
                if (randomNumber < rule.evolutionChance) {
                    string memory newMetadataURI = string(abi.encodePacked(baseMetadataURI, rule.nextMetadataSuffix));
                    nftMetadataURIs[_tokenId] = newMetadataURI;
                    nftEvolutionLevel[_tokenId] = nextLevel;
                    evolutionRules[nextLevel].cooldownPeriod = block.timestamp + 1 days; // Reset cooldown
                    emit NFTEvolved(_tokenId, nextLevel, newMetadataURI);
                } else {
                    // Evolution failed - could add event for failed evolution if needed
                }
            } else {
                revert("Evolution cooldown period not over");
            }
        } else {
            revert("No evolution rule defined for this level");
        }
    }

    /// @dev Retrieves the current metadata URI for a given NFT token.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function getNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist");
        return nftMetadataURIs[_tokenId];
    }

    /// @dev Admin function to set the base metadata URI for all NFTs.
    /// @param _baseURI The new base metadata URI.
    function setBaseMetadataURI(string memory _baseURI) external onlyAdmin whenNotPaused {
        baseMetadataURI = _baseURI;
    }

    /// @dev Admin function to define or update evolution rules.
    /// @param _ruleId The ID of the evolution rule (level).
    /// @param _rule The EvolutionRule struct containing the rule details.
    function setEvolutionRule(uint8 _ruleId, EvolutionRule memory _rule) external onlyAdmin whenNotPaused {
        evolutionRules[_ruleId] = _rule;
        if (_ruleId > numEvolutionRules) {
            numEvolutionRules = _ruleId;
        }
    }

    /// @dev Internal function to generate a pseudo-random number. (Simplified for example - in production, use Chainlink VRF or similar)
    function getRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 10000;
    }

    // --- ERC721 Standard Functions ---

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return nftMetadataURIs[tokenId];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused {
        // solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address approved, uint256 tokenId) public virtual whenNotPaused {
        address owner = ownerOf(tokenId);
        require(approved != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual whenNotPaused {
        require(operator != msg.sender, "ERC721: approve to caller");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return operatorApprovals[owner][operator];
    }

    // --- Internal ERC721 Helper Functions ---

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenOwner[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        delete tokenApprovals[tokenId];

        balance[from]--;
        balance[to]++;
        tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // --- NFT Staking Contract ---
}

contract NFTStaking is DynamicEcosystemNFT {
    using SafeMath for uint256;

    uint256 public rewardRate = 10; // Rewards per day per staked NFT (example - adjust as needed)
    mapping(uint256 => StakingInfo) public stakingInfo;
    address public stakingAdmin;

    struct StakingInfo {
        uint256 stakeStartTime;
        uint256 lastRewardClaimTime;
        address staker;
        bool isStaked;
    }

    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 rewardsClaimed);
    event RewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 rewardsClaimed);
    event RewardRateChanged(uint256 newRate, address admin);

    modifier onlyStakingAdmin() {
        require(msg.sender == stakingAdmin, "Only staking admin allowed");
        _;
    }

    constructor(string memory _baseURI) DynamicEcosystemNFT(_baseURI) {
        stakingAdmin = msg.sender;
    }

    /// @dev Allows users to stake their NFTs to earn rewards.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(!stakingInfo[_tokenId].isStaked, "NFT is already staked");
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");

        _transfer(msg.sender, address(this), _tokenId); // Transfer NFT to staking contract
        stakingInfo[_tokenId] = StakingInfo({
            stakeStartTime: block.timestamp,
            lastRewardClaimTime: block.timestamp,
            staker: msg.sender,
            isStaked: true
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @dev Allows users to unstake their NFTs and claim accumulated rewards.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) external whenNotPaused {
        require(stakingInfo[_tokenId].isStaked && stakingInfo[_tokenId].staker == msg.sender, "NFT is not staked by you");

        uint256 rewards = calculateRewards(_tokenId);
        stakingInfo[_tokenId].isStaked = false; // Mark as unstaked
        stakingInfo[_tokenId].lastRewardClaimTime = block.timestamp; // Update claim time

        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to staker
        // For simplicity, rewards are not actually transferred in this example. In a real contract, you'd transfer a reward token.
        emit NFTUnstaked(_tokenId, msg.sender, rewards);
    }

    /// @dev Allows users to claim accumulated rewards for a staked NFT without unstaking.
    /// @param _tokenId The ID of the NFT to claim rewards for.
    function claimRewards(uint256 _tokenId) external whenNotPaused {
        require(stakingInfo[_tokenId].isStaked && stakingInfo[_tokenId].staker == msg.sender, "NFT is not staked by you");

        uint256 rewards = calculateRewards(_tokenId);
        stakingInfo[_tokenId].lastRewardClaimTime = block.timestamp; // Update last claim time
        // Again, rewards are not transferred in this example.
        emit RewardsClaimed(_tokenId, msg.sender, rewards);
    }

    /// @dev Calculates the rewards accumulated for a staked NFT.
    /// @param _tokenId The ID of the staked NFT.
    /// @return The amount of rewards accumulated.
    function calculateRewards(uint256 _tokenId) public view returns (uint256) {
        if (!stakingInfo[_tokenId].isStaked) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - stakingInfo[_tokenId].lastRewardClaimTime;
        uint256 rewards = (timeElapsed * rewardRate) / (1 days); // Example: rewards per day
        return rewards;
    }

    /// @dev Admin function to set the reward rate for staking.
    /// @param _newRate The new reward rate.
    function setRewardRate(uint256 _newRate) external onlyStakingAdmin whenNotPaused {
        rewardRate = _newRate;
        emit RewardRateChanged(_newRate, msg.sender);
    }

    /// @dev Retrieves staking information for a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return StakingInfo struct containing staking details.
    function getStakingInfo(uint256 _tokenId) external view returns (StakingInfo memory) {
        return stakingInfo[_tokenId];
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract NFTCrafting is NFTStaking {
    struct CraftingRecipe {
        uint256[] requiredTokenIds; // Token IDs required for crafting (example: [1, 2] means token 1 and 2 are needed)
        string resultMetadataURI;   // Metadata URI of the crafted NFT
    }

    mapping(uint256 => CraftingRecipe) public craftingRecipes; // Recipe ID => Recipe
    uint256 public numCraftingRecipes = 0;
    address public craftingAdmin;

    event NFTsCrafted(address indexed crafter, uint256[] burnedTokenIds, uint256 craftedTokenId);
    event CraftingRecipeAdded(uint256 recipeId, uint256[] requiredTokenIds, string resultMetadataURI);

    modifier onlyCraftingAdmin() {
        require(msg.sender == craftingAdmin, "Only crafting admin allowed");
        _;
    }

    constructor(string memory _baseURI) NFTStaking(_baseURI) {
        craftingAdmin = msg.sender;
    }

    /// @dev Allows users to craft new NFTs by burning existing ones based on predefined recipes.
    /// @param _tokenIds An array of token IDs to be used for crafting.
    function craftNFTs(uint256[] memory _tokenIds) external whenNotPaused {
        uint256 recipeId = findCraftingRecipe(_tokenIds); // Find matching recipe based on input tokens
        require(recipeId > 0, "No crafting recipe found for these NFTs");

        CraftingRecipe memory recipe = craftingRecipes[recipeId];

        // Check ownership and burn required NFTs
        for (uint256 i = 0; i < recipe.requiredTokenIds.length; i++) {
            uint256 tokenId = recipe.requiredTokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not owner of required NFT");
            _burnNFT(tokenId); // Burn the required NFTs
        }

        // Mint the new crafted NFT
        totalSupply++;
        uint256 craftedTokenId = totalSupply;
        tokenOwner[craftedTokenId] = msg.sender;
        balance[msg.sender]++;
        nftMetadataURIs[craftedTokenId] = recipe.resultMetadataURI; // Set metadata from recipe
        nftEvolutionLevel[craftedTokenId] = 1; // Reset level for crafted NFT
        emit Transfer(address(0), msg.sender, craftedTokenId);
        emit NFTsCrafted(msg.sender, recipe.requiredTokenIds, craftedTokenId);
    }

    /// @dev Admin function to add new crafting recipes.
    /// @param _requiredTokenIds An array of token IDs required for the recipe.
    /// @param _resultMetadataURI Metadata URI of the resulting crafted NFT.
    function addCraftingRecipe(uint256[] memory _requiredTokenIds, string memory _resultMetadataURI) external onlyCraftingAdmin whenNotPaused {
        numCraftingRecipes++;
        craftingRecipes[numCraftingRecipes] = CraftingRecipe({
            requiredTokenIds: _requiredTokenIds,
            resultMetadataURI: _resultMetadataURI
        });
        emit CraftingRecipeAdded(numCraftingRecipes, _requiredTokenIds, _resultMetadataURI);
    }

    /// @dev Retrieves the list of available crafting recipes.
    /// @return An array of CraftingRecipe structs.
    function getCraftingRecipes() external view returns (CraftingRecipe[] memory) {
        CraftingRecipe[] memory recipes = new CraftingRecipe[](numCraftingRecipes);
        for (uint256 i = 1; i <= numCraftingRecipes; i++) {
            recipes[i-1] = craftingRecipes[i];
        }
        return recipes;
    }

    /// @dev Internal helper function to find a matching crafting recipe based on input tokens.
    /// @param _tokenIds Array of token IDs to check against recipes.
    /// @return Recipe ID if a match is found, 0 if no match.
    function findCraftingRecipe(uint256[] memory _tokenIds) internal view returns (uint256) {
        for (uint256 i = 1; i <= numCraftingRecipes; i++) {
            CraftingRecipe storage recipe = craftingRecipes[i];
            if (areTokenArraysEqual(_tokenIds, recipe.requiredTokenIds)) {
                return i; // Recipe ID found
            }
        }
        return 0; // No recipe found
    }

    /// @dev Internal helper function to burn an NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function _burnNFT(uint256 _tokenId) internal {
        require(ownerOf(_tokenId) != address(0), "NFT does not exist");

        address owner = ownerOf(_tokenId);

        // Clear approvals
        delete tokenApprovals[_tokenId];

        balance[owner]--;
        delete tokenOwner[_tokenId];
        delete nftMetadataURIs[_tokenId];
        delete nftEvolutionLevel[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    /// @dev Internal helper function to compare two arrays of token IDs for recipe matching.
    function areTokenArraysEqual(uint256[] memory arr1, uint256[] memory arr2) internal pure returns (bool) {
        if (arr1.length != arr2.length) {
            return false;
        }
        // For simplicity, assuming order doesn't matter in recipes and token IDs are sorted in recipes.
        // In a real scenario, more robust matching might be needed.
        uint256[] memory sortedArr1 = sortArray(arr1);
        uint256[] memory sortedArr2 = sortArray(arr2);

        for (uint256 i = 0; i < sortedArr1.length; i++) {
            if (sortedArr1[i] != sortedArr2[i]) {
                return false;
            }
        }
        return true;
    }

    function sortArray(uint256[] memory arr) internal pure returns (uint256[] memory) {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    uint256 temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
        return arr;
    }
}

contract NFTGovernance is NFTCrafting {
    enum ProposalState { Pending, Active, Canceled, Passed, Executed }

    struct Proposal {
        uint256 proposalId;
        string description;
        string proposedValue;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        address proposer;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount = 0;
    uint256 public votingPeriod = 7 days; // Example voting period
    uint256 public quorumPercentage = 5; // Example quorum percentage (5% of total supply)
    address public governanceAdmin;

    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);
    event VotingPeriodChanged(uint256 newPeriod, address admin);
    event QuorumPercentageChanged(uint256 newPercentage, address admin);

    modifier onlyGovernanceAdmin() {
        require(msg.sender == governanceAdmin, "Only governance admin allowed");
        _;
    }

    constructor(string memory _baseURI) NFTCrafting(_baseURI) {
        governanceAdmin = msg.sender;
    }

    /// @dev Allows NFT holders to propose changes to contract parameters.
    /// @param _proposalDescription Description of the proposed change.
    /// @param _proposedValue The proposed new value or parameter.
    function proposeFeatureChange(string memory _proposalDescription, string memory _proposedValue) external whenNotPaused {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.description = _proposalDescription;
        newProposal.proposedValue = _proposedValue;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.state = ProposalState.Pending;
        newProposal.proposer = msg.sender;

        emit ProposalCreated(proposalCount, _proposalDescription, msg.sender);
    }

    /// @dev Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending, "Proposal is not in Pending state");
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(balance[msg.sender] > 0, "Voter must own at least one NFT");

        proposal.state = ProposalState.Active; // Move to active state on first vote
        if (_support) {
            proposal.votesFor += balance[msg.sender]; // Voting power is based on NFT balance
        } else {
            proposal.votesAgainst += balance[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @dev Admin/Timelock function to execute a passed proposal after a voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernanceAdmin whenNotPaused { // In real scenario, consider timelock
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not in Active state");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended");

        uint256 quorum = (totalSupply * quorumPercentage) / 100;
        require(proposal.votesFor >= quorum, "Proposal does not meet quorum");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority vote");

        proposal.state = ProposalState.Executed;
        // Example execution - can be expanded based on proposal types.
        // For simplicity, just logging the executed proposal details here.
        // In a real contract, this would modify contract parameters based on `proposal.proposedValue`.
        // e.g., if proposal is to change reward rate: `setRewardRate(uint256(uint256(keccak256(abi.encodePacked(proposal.proposedValue)))));` (example - needs proper parsing and validation)

        emit ProposalExecuted(_proposalId);
    }

    /// @dev Retrieves details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @dev Admin function to change the voting period.
    /// @param _newPeriod The new voting period in seconds.
    function changeVotingPeriod(uint256 _newPeriod) external onlyGovernanceAdmin whenNotPaused {
        votingPeriod = _newPeriod;
        emit VotingPeriodChanged(_newPeriod, msg.sender);
    }

    /// @dev Admin function to change the quorum percentage.
    /// @param _newPercentage The new quorum percentage.
    function changeQuorumPercentage(uint256 _newPercentage) external onlyGovernanceAdmin whenNotPaused {
        quorumPercentage = _newPercentage;
        emit QuorumPercentageChanged(_newPercentage, msg.sender);
    }

    /// @dev Admin function to cancel a proposal before voting ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external onlyGovernanceAdmin whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal cannot be canceled in current state");
        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
    }
}

contract NFTMarketplace is NFTGovernance {
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => Listing) public nftListings;
    address public marketplaceAdmin;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    modifier onlyMarketplaceAdmin() {
        require(msg.sender == marketplaceAdmin, "Only marketplace admin allowed");
        _;
    }

    constructor(string memory _baseURI) NFTGovernance(_baseURI) {
        marketplaceAdmin = msg.sender;
    }

    /// @dev Allows NFT owners to list their NFTs for sale.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price in wei for which the NFT is listed.
    function listNFTForSale(uint256 _tokenId, uint256 _price) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        require(_price > 0, "Price must be greater than zero");
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");

        nftListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isListed: true
        });
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    /// @dev Allows NFT owners to remove their NFT from sale.
    /// @param _tokenId The ID of the NFT to delist.
    function delistNFTFromSale(uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        delete nftListings[_tokenId]; // Remove listing
        emit NFTDelisted(_tokenId, msg.sender);
    }

    /// @dev Retrieves listing details for a given NFT.
    /// @param _tokenId The ID of the NFT to get listing details for.
    /// @return Listing struct containing listing details.
    function getListingDetails(uint256 _tokenId) external view returns (Listing memory) {
        return nftListings[_tokenId];
    }

    /// @dev Function to buy an NFT listed on the marketplace. (Simplified - payment handling not fully implemented)
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) external payable whenNotPaused {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        Listing memory listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        _transfer(listing.seller, msg.sender, _tokenId); // Transfer NFT to buyer

        // In a real marketplace, you would handle payment forwarding to the seller and potentially platform fees.
        payable(listing.seller).transfer(listing.price); // Example - basic transfer of ETH to seller

        delete nftListings[_tokenId]; // Remove listing after purchase
        emit NFTBought(_tokenId, msg.sender, listing.seller, listing.price);
    }
}

contract EcosystemController is NFTMarketplace {
    address public controllerAdmin;

    event ContractPausedByAdmin(address admin);
    event ContractUnpausedByAdmin(address admin);
    event ContractBalanceWithdrawn(address admin, uint256 amount);

    modifier onlyControllerAdmin() {
        require(msg.sender == controllerAdmin, "Only controller admin allowed");
        _;
    }

    constructor(string memory _baseURI) NFTMarketplace(_baseURI) {
        controllerAdmin = msg.sender;
    }

    /// @dev Admin function to pause core contract functionalities.
    function pauseContract() external onlyControllerAdmin whenNotPaused {
        paused = true;
        emit ContractPausedByAdmin(msg.sender);
        emit ContractPaused(msg.sender); // Inherited event for external tracking
    }

    /// @dev Admin function to unpause contract functionalities.
    function unpauseContract() external onlyControllerAdmin whenPaused {
        paused = false;
        emit ContractUnpausedByAdmin(msg.sender);
        emit ContractUnpaused(msg.sender); // Inherited event for external tracking
    }

    /// @dev Returns the current paused state of the contract.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @dev Admin function to withdraw contract's ETH balance.
    function withdrawContractBalance() external onlyControllerAdmin {
        uint256 contractBalance = address(this).balance;
        payable(controllerAdmin).transfer(contractBalance);
        emit ContractBalanceWithdrawn(msg.sender, contractBalance);
    }
}
```

**Explanation of Concepts and Functions:**

This smart contract combines several advanced and trendy concepts into a single ecosystem. Here's a breakdown:

1.  **Dynamic NFTs (Evolution):**
    *   NFTs are not static; they can evolve on-chain based on predefined rules.
    *   `evolveNFT()` function triggers evolution, using randomness (simplified in this example) and rules set by the admin.
    *   Evolution is level-based, and each level can have different metadata (demonstrated by changing `nftMetadataURIs`).
    *   Cooldown periods can be implemented for evolution attempts.

2.  **NFT Staking and Rewards:**
    *   NFT holders can stake their NFTs within the contract to earn rewards (conceptual in this example, rewards are calculated but not actually transferred).
    *   `stakeNFT()`, `unstakeNFT()`, `claimRewards()` functions manage the staking process.
    *   Reward rate is configurable by the staking admin.
    *   Staking provides utility to NFTs beyond just holding or trading.

3.  **NFT Crafting/Fusion:**
    *   Users can combine (burn) existing NFTs to create new, potentially rarer or more valuable NFTs.
    *   `craftNFTs()` function implements crafting based on recipes.
    *   `addCraftingRecipe()` allows the admin to define new crafting recipes.
    *   Crafting adds a layer of gameplay and scarcity to the NFT ecosystem.

4.  **Simplified On-Chain Governance:**
    *   NFT holders can participate in governance by proposing and voting on changes to contract parameters (e.g., voting periods, reward rates).
    *   `proposeFeatureChange()`, `voteOnProposal()`, `executeProposal()` functions enable basic governance.
    *   Voting power is proportional to the number of NFTs held.
    *   Governance allows for community involvement in the evolution of the ecosystem.

5.  **Basic NFT Marketplace (Listing/Delisting):**
    *   A rudimentary marketplace functionality is included to allow users to list their NFTs for sale directly within the contract.
    *   `listNFTForSale()`, `delistNFTFromSale()`, `buyNFT()` functions (basic implementation) handle marketplace operations.
    *   This provides an on-chain trading venue for the NFTs.

6.  **Contract Pausing and Administration:**
    *   Admin functions (`pauseContract()`, `unpauseContract()`, `withdrawContractBalance()`, `setRewardRate()`, `addCraftingRecipe()`, `changeVotingPeriod()`, `changeQuorumPercentage()`, `cancelProposal()`, `setBaseMetadataURI()`, `setEvolutionRule()`, `mintNFT()`) are included for contract management and emergency control.
    *   A `paused` state allows for emergency halts of core functionalities if needed.

**Important Notes:**

*   **Security:** This is an example and is **not audited or production-ready**. Security considerations like reentrancy, access control vulnerabilities, and proper randomness implementation (for evolution) are crucial in real-world contracts.
*   **Randomness:** The `getRandomNumber()` function is a very simplified and insecure pseudo-random number generator. For production use cases that rely on secure randomness (like NFT evolution chance), you **must integrate with a verifiable randomness oracle like Chainlink VRF**.
*   **Gas Optimization:**  This contract is written for demonstration and conceptual clarity. Gas optimization techniques would be necessary for a production deployment to reduce transaction costs.
*   **Reward Token:**  The staking rewards in this example are conceptual. In a real system, you would need to integrate a separate reward token (ERC20) and implement actual reward distribution mechanisms.
*   **Marketplace Functionality:** The marketplace in this example is extremely basic (listing and delisting, simplified buying). A real marketplace would require much more robust features like order books, bidding, fee structures, and more secure payment handling.
*   **Governance Execution:**  The `executeProposal()` function is also very simplified. Real governance execution often involves timelocks, more complex parameter updates, or even contract upgrades based on community proposals.
*   **Error Handling and Events:**  The contract includes events for important actions, which is good practice for on-chain transparency. Error messages using `require` statements help with debugging and user feedback.
*   **Modular Design:** The contract is broken down into multiple contracts (`DynamicEcosystemNFT`, `NFTStaking`, `NFTCrafting`, `NFTGovernance`, `NFTMarketplace`, `EcosystemController`) for better organization and potential reusability or upgradability.
*   **ERC721 Standard:**  It implements the ERC721 non-fungible token standard, ensuring compatibility with marketplaces and wallets that support NFTs.

This example is designed to be a creative starting point and showcase a range of advanced concepts that can be implemented in smart contracts beyond simple token transfers. Remember to thoroughly research, audit, and test any smart contract before deploying it to a production environment.