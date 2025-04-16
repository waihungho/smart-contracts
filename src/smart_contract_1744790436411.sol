```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Metaverse Interaction Contract
 * @author Bard (Example - Replace with your name)
 * @dev A smart contract demonstrating advanced concepts like dynamic NFTs, metaverse interactions,
 *      governance, staking with evolving rewards, and a unique on-chain reputation system.
 *
 * Function Summary:
 * -----------------
 * **Core NFT Functions:**
 * 1. mintNFT(address _to, uint256 _initialTier, string memory _baseURI) - Mints a new Dynamic NFT with initial tier and base URI.
 * 2. transferNFT(address _to, uint256 _tokenId) - Transfers an NFT to another address.
 * 3. burnNFT(uint256 _tokenId) - Burns (destroys) an NFT.
 * 4. getTokenURI(uint256 _tokenId) - Returns the URI for a given NFT token ID (dynamic based on tier/stage).
 * 5. supportsInterface(bytes4 interfaceId) -  ERC165 interface support.
 *
 * **Dynamic NFT Evolution & Tier System:**
 * 6. triggerEvolution(uint256 _tokenId) - Triggers an evolution check for an NFT based on on-chain activity/conditions.
 * 7. getNFTTier(uint256 _tokenId) - Returns the current tier of an NFT.
 * 8. getEvolutionStage(uint256 _tokenId) - Returns the current evolution stage within a tier for an NFT.
 * 9. setEvolutionParameters(uint256 _tier, uint256 _stageThreshold, uint256 _rewardMultiplier) - Governance function to set evolution parameters.
 * 10. getEvolutionParameters(uint256 _tier) - Returns evolution parameters for a given tier.
 *
 * **Metaverse Interaction & Reputation System:**
 * 11. recordMetaverseAction(uint256 _tokenId, string memory _actionType) - Records a metaverse action associated with an NFT, influencing reputation and evolution.
 * 12. getNFTReputation(uint256 _tokenId) - Returns the reputation score of an NFT (dynamically calculated).
 * 13. setReputationWeight(string memory _actionType, uint256 _weight) - Governance function to set reputation weight for metaverse actions.
 * 14. getReputationWeight(string memory _actionType) - Returns the reputation weight for a given metaverse action type.
 *
 * **Staking & Evolving Rewards:**
 * 15. stakeNFT(uint256 _tokenId) - Stakes an NFT to earn evolving rewards based on tier and reputation.
 * 16. unstakeNFT(uint256 _tokenId) - Unstakes an NFT and claims accumulated rewards.
 * 17. getStakingReward(uint256 _tokenId) - Calculates and returns the current staking reward for an NFT.
 * 18. setStakingRewardParameters(uint256 _baseRewardRate, uint256 _tierMultiplier) - Governance function to set staking reward parameters.
 * 19. getStakingRewardParameters() - Returns current staking reward parameters.
 *
 * **Governance & Utility Functions:**
 * 20. pauseContract() - Pauses core contract functions (governance only).
 * 21. unpauseContract() - Unpauses contract functions (governance only).
 * 22. setGovernanceAddress(address _governanceAddress) - Sets the governance contract address.
 * 23. getGovernanceAddress() - Returns the current governance contract address.
 * 24. withdrawContractBalance(address _to) - Allows governance to withdraw contract balance (ETH or tokens).
 * 25. setRoyaltyInfo(address _recipient, uint256 _feeNumerator) - Sets royalty information for secondary sales.
 * 26. getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) - Returns royalty information for a token and sale price (ERC2981).
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract DynamicNFTMetaverseContract is Ownable, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    string public name = "Dynamic Metaverse NFT";
    string public symbol = "DYNM";
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public nftTier; // Tier of the NFT
    mapping(uint256 => uint256) public evolutionStage; // Evolution stage within the tier
    mapping(uint256 => uint256) public nftReputation; // Reputation score of the NFT
    mapping(uint256 => uint256) public lastEvolutionTimestamp; // Timestamp of last evolution trigger
    mapping(uint256 => uint256) public lastMetaverseActionTimestamp; // Timestamp of last metaverse action

    // Evolution Parameters per Tier (Tier => (Stage Threshold, Reward Multiplier))
    mapping(uint256 => EvolutionParameters) public evolutionParams;
    struct EvolutionParameters {
        uint256 stageThreshold; // Reputation needed to reach next stage
        uint256 rewardMultiplier; // Reward multiplier for staking in this tier
    }

    // Metaverse Action Reputation Weights (Action Type => Reputation Weight)
    mapping(string => uint256) public reputationWeights;

    // Staking Parameters
    uint256 public baseStakingRewardRate = 100; // Base reward per time unit (e.g., per day)
    uint256 public stakingTierMultiplier = 10; // Multiplier based on NFT tier
    mapping(uint256 => uint256) public nftStakeStartTime; // Timestamp when NFT was staked
    mapping(uint256 => uint256) public nftStakedBalance; // Accumulate staking reward balance
    mapping(uint256 => bool) public isNFTStaked; // Track if NFT is staked

    // Royalty Information (ERC2981)
    address private _royaltyRecipient;
    uint256 private _royaltyFeeNumerator;

    // Governance Address - Allows for delegated governance actions
    address public governanceAddress;

    // Contract Paused State
    bool public paused;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to, uint256 initialTier);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event NFTEvolutionTriggered(uint256 tokenId, uint256 previousTier, uint256 newTier, uint256 previousStage, uint256 newStage);
    event MetaverseActionRecorded(uint256 tokenId, string actionType, uint256 reputationChange);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner, uint256 rewardClaimed);
    event StakingRewardParametersUpdated(uint256 baseRewardRate, uint256 tierMultiplier);
    event EvolutionParametersUpdated(uint256 tier, uint256 stageThreshold, uint256 rewardMultiplier);
    event ReputationWeightUpdated(string actionType, uint256 weight);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
    event GovernanceAddressUpdated(address newGovernanceAddress, address oldGovernanceAddress);
    event RoyaltyInfoUpdated(address recipient, uint256 feeNumerator);
    event ContractBalanceWithdrawn(address to, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance contract allowed");
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovernanceAddress, address _initialRoyaltyRecipient, uint256 _initialRoyaltyFeeNumerator) payable {
        _royaltyRecipient = _initialRoyaltyRecipient;
        _royaltyFeeNumerator = _initialRoyaltyFeeNumerator;
        governanceAddress = _initialGovernanceAddress;
        // Initialize default evolution parameters for Tier 1
        evolutionParams[1] = EvolutionParameters({stageThreshold: 100, rewardMultiplier: 1});
        // Initialize default reputation weights for some actions
        reputationWeights["quest_completed"] = 50;
        reputationWeights["social_event_attend"] = 20;
        reputationWeights["resource_gathered"] = 10;
    }

    // --- Core NFT Functions ---
    function mintNFT(address _to, uint256 _initialTier, string memory _baseURI) external onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        tokenOwner[newTokenId] = _to;
        _tokenURIs[newTokenId] = _baseURI; // Base URI, can be dynamically updated
        nftTier[newTokenId] = _initialTier;
        evolutionStage[newTokenId] = 1; // Start at stage 1 within the tier
        nftReputation[newTokenId] = 0;
        lastEvolutionTimestamp[newTokenId] = block.timestamp;
        lastMetaverseActionTimestamp[newTokenId] = block.timestamp;

        emit NFTMinted(newTokenId, _to, _initialTier);
    }

    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_to != address(0), "Transfer to the zero address");

        address from = msg.sender;
        tokenOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, from, _to);
    }

    function burnNFT(uint256 _tokenId) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender || msg.sender == owner(), "Not NFT owner or admin");

        address ownerAddress = tokenOwner[_tokenId];
        delete tokenOwner[_tokenId];
        delete _tokenURIs[_tokenId];
        delete nftTier[_tokenId];
        delete evolutionStage[_tokenId];
        delete nftReputation[_tokenId];
        delete lastEvolutionTimestamp[_tokenId];
        delete lastMetaverseActionTimestamp[_tokenId];
        delete nftStakeStartTime[_tokenId];
        delete nftStakedBalance[_tokenId];
        delete isNFTStaked[_tokenId];

        emit NFTBurned(_tokenId);
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        // Dynamic URI generation based on tier and stage (example - can be more complex)
        return string(abi.encodePacked(_tokenURIs[_tokenId], "/", nftTier[_tokenId].toString(), "/", evolutionStage[_tokenId].toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Dynamic NFT Evolution & Tier System ---
    function triggerEvolution(uint256 _tokenId) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_exists(_tokenId), "Token does not exist");

        uint256 currentTier = nftTier[_tokenId];
        uint256 currentStage = evolutionStage[_tokenId];
        uint256 currentReputation = nftReputation[_tokenId];
        EvolutionParameters memory currentTierParams = evolutionParams[currentTier];

        if (currentTierParams.stageThreshold > 0 && currentReputation >= currentTierParams.stageThreshold) {
            uint256 previousTier = currentTier;
            uint256 previousStage = currentStage;
            nftTier[_tokenId]++; // Evolve to next tier
            evolutionStage[_tokenId] = 1; // Reset stage to 1 in new tier
            lastEvolutionTimestamp[_tokenId] = block.timestamp;
            emit NFTEvolutionTriggered(_tokenId, previousTier, nftTier[_tokenId], previousStage, evolutionStage[_tokenId]);
        } else {
            // Can add logic for stage progression within a tier based on time or other factors if needed
            // For simplicity, evolution is currently just tier-based
        }
    }

    function getNFTTier(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return nftTier[_tokenId];
    }

    function getEvolutionStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return evolutionStage[_tokenId];
    }

    function setEvolutionParameters(uint256 _tier, uint256 _stageThreshold, uint256 _rewardMultiplier) external onlyGovernance whenNotPaused {
        evolutionParams[_tier] = EvolutionParameters({stageThreshold: _stageThreshold, rewardMultiplier: _rewardMultiplier});
        emit EvolutionParametersUpdated(_tier, _stageThreshold, _rewardMultiplier);
    }

    function getEvolutionParameters(uint256 _tier) public view returns (EvolutionParameters memory) {
        return evolutionParams[_tier];
    }

    // --- Metaverse Interaction & Reputation System ---
    function recordMetaverseAction(uint256 _tokenId, string memory _actionType) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_exists(_tokenId), "Token does not exist");
        require(reputationWeights[_actionType] > 0, "Invalid action type");

        uint256 reputationChange = reputationWeights[_actionType];
        nftReputation[_tokenId] += reputationChange;
        lastMetaverseActionTimestamp[_tokenId] = block.timestamp;

        emit MetaverseActionRecorded(_tokenId, _actionType, reputationChange);
    }

    function getNFTReputation(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return nftReputation[_tokenId];
    }

    function setReputationWeight(string memory _actionType, uint256 _weight) external onlyGovernance whenNotPaused {
        reputationWeights[_actionType] = _weight;
        emit ReputationWeightUpdated(_actionType, _weight);
    }

    function getReputationWeight(string memory _actionType) public view returns (uint256) {
        return reputationWeights[_actionType];
    }

    // --- Staking & Evolving Rewards ---
    function stakeNFT(uint256 _tokenId) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_exists(_tokenId), "Token does not exist");
        require(!isNFTStaked[_tokenId], "NFT already staked");

        isNFTStaked[_tokenId] = true;
        nftStakeStartTime[_tokenId] = block.timestamp;
        nftStakedBalance[_tokenId] = 0; // Reset balance on stake
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) external whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "Not NFT owner");
        require(_exists(_tokenId), "Token does not exist");
        require(isNFTStaked[_tokenId], "NFT not staked");

        uint256 reward = getStakingReward(_tokenId);
        isNFTStaked[_tokenId] = false;
        nftStakeStartTime[_tokenId] = 0;
        nftStakedBalance[_tokenId] = 0; // Reset balance after unstake (rewards claimed)

        // Transfer reward to user (example - using contract balance, could be external token)
        payable(msg.sender).transfer(reward); // Simple ETH transfer as example

        emit NFTUnstaked(_tokenId, msg.sender, reward);
    }

    function getStakingReward(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        if (!isNFTStaked[_tokenId]) {
            return 0; // No reward if not staked
        }

        uint256 timeStaked = block.timestamp - nftStakeStartTime[_tokenId];
        uint256 tierMultiplier = evolutionParams[nftTier[_tokenId]].rewardMultiplier;
        uint256 rewardRate = baseStakingRewardRate * tierMultiplier;
        uint256 reward = (rewardRate * timeStaked) / 1 days; // Example reward rate per day

        return reward;
    }

    function setStakingRewardParameters(uint256 _baseRewardRate, uint256 _tierMultiplier) external onlyGovernance whenNotPaused {
        baseStakingRewardRate = _baseRewardRate;
        stakingTierMultiplier = _tierMultiplier;
        emit StakingRewardParametersUpdated(_baseRewardRate, _tierMultiplier);
    }

    function getStakingRewardParameters() public view returns (uint256 baseRewardRate, uint256 tierMultiplier) {
        return (baseStakingRewardRate, stakingTierMultiplier);
    }

    // --- Governance & Utility Functions ---
    function pauseContract() external onlyGovernance whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyGovernance whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setGovernanceAddress(address _governanceAddress) external onlyGovernance whenNotPaused {
        address oldGovernanceAddress = governanceAddress;
        governanceAddress = _governanceAddress;
        emit GovernanceAddressUpdated(_governanceAddress, oldGovernanceAddress);
    }

    function getGovernanceAddress() public view returns (address) {
        return governanceAddress;
    }

    function withdrawContractBalance(address _to) external onlyGovernance whenNotPaused {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
        emit ContractBalanceWithdrawn(_to, balance);
    }

    // --- ERC2981 Royalty Functions ---
    function setRoyaltyInfo(address _recipient, uint256 _feeNumerator) external onlyOwner whenNotPaused {
        require(_feeNumerator <= 10000, "Royalty fee too high (max 100%)"); // Max 100% royalty
        _royaltyRecipient = _recipient;
        _royaltyFeeNumerator = _feeNumerator;
        emit RoyaltyInfoUpdated(_recipient, _feeNumerator);
    }

    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_royaltyRecipient, (_salePrice * _royaltyFeeNumerator) / 10000); // Royalty calculation
    }

    // --- Internal Helper Functions ---
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }

    // --- ERC721 Metadata (Basic Implementation) ---
    function name() public view virtual override returns (string memory) {
        return name;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol;
    }
}

// --- ERC721 Enumerable (Basic Implementation - Consider OpenZeppelin library for production) ---
// For demonstration purposes, not fully implemented for brevity.
// You would typically import and inherit from OpenZeppelin's ERC721Enumerable for full functionality.
abstract contract ERC721Enumerable is IERC721Enumerable {
    function totalSupply() public view virtual override returns (uint256) {
        // In a real implementation, you would track total supply
        return 0; // Placeholder
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        // In a real implementation, you would track tokens per owner and index
        revert("Not implemented"); // Placeholder
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        // In a real implementation, you would track all tokens and index
        revert("Not implemented"); // Placeholder
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256 tokenId);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address approved, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external payable;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```