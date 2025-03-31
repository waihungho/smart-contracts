```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Dynamic NFT system where NFTs can evolve and change based on various on-chain actions and conditions.
 * It introduces concepts like NFT evolution, attribute mutations, on-chain randomness with verifiable seeds,
 * decentralized governance for evolution paths, NFT fusion, skill-based upgrades, and rarity tiers.
 *
 * **Outline:**
 *
 * **Core NFT Functionality:**
 *   1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to the specified address with an initial base URI.
 *   2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 *   3. `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to transfer a specific NFT.
 *   4. `getApprovedNFT(uint256 _tokenId)`: Gets the approved address for a specific NFT.
 *   5. `setApprovalForAllNFT(address _operator, bool _approved)`: Sets approval for an operator to transfer all NFTs of an owner.
 *   6. `isApprovedForAllNFT(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 *   7. `tokenURINFT(uint256 _tokenId)`: Returns the token URI for a given NFT ID.
 *   8. `ownerOfNFT(uint256 _tokenId)`: Returns the owner of a given NFT ID.
 *   9. `balanceOfNFT(address _owner)`: Returns the balance of NFTs owned by an address.
 *   10. `totalSupplyNFT()`: Returns the total supply of NFTs.
 *
 * **Dynamic Evolution and Attributes:**
 *   11. `performAction(uint256 _tokenId, uint8 _actionType)`: Allows NFT owners to perform actions that can trigger evolution or attribute changes.
 *   12. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for an NFT based on accumulated experience.
 *   13. `mutateAttribute(uint256 _tokenId, uint8 _attributeIndex)`: Mutates a specific attribute of an NFT based on randomness and conditions.
 *   14. `getNFTAttributes(uint256 _tokenId)`: Retrieves the current attributes of an NFT.
 *   15. `getNFTEvolutionStage(uint256 _tokenId)`: Gets the current evolution stage of an NFT.
 *
 * **Advanced and Creative Functions:**
 *   16. `fuseNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Allows owners to fuse two NFTs to create a new, potentially enhanced NFT.
 *   17. `upgradeSkill(uint256 _tokenId, uint8 _skillIndex)`: Allows owners to upgrade specific skills of their NFTs using in-game currency or resources (simulated on-chain).
 *   18. `rollRandomAttribute(uint256 _tokenId)`: Initiates a random attribute roll for an NFT, using a verifiable on-chain randomness mechanism.
 *   19. `voteForEvolutionPath(uint256 _tokenId, uint8 _pathId)`: Allows NFT holders to vote on future evolution paths or attribute changes for their NFT type. (Decentralized Governance Simulation)
 *   20. `claimRarityTierReward(uint256 _tokenId)`: Allows NFT holders to claim rewards based on their NFT's current rarity tier (determined by attributes).
 *   21. `setBaseURINFT(string memory _newBaseURI)`: Allows the contract owner to update the base URI for NFT metadata.
 *   22. `pauseContract()`: Allows the contract owner to pause core functionalities in case of emergency.
 *   23. `unpauseContract()`: Allows the contract owner to unpause core functionalities.
 *   24. `withdrawFunds()`: Allows the contract owner to withdraw contract balance.
 *
 * **Function Summary:**
 *
 * - **NFT Management (10 functions):** Mint, transfer, approve, get approvals, set/check operator approvals, token URI, owner, balance, total supply. Standard ERC721-like functionality.
 * - **Dynamic NFT Evolution & Attributes (5 functions):** Perform actions, evolve, mutate attributes, get attributes, get evolution stage. Core dynamic NFT mechanisms.
 * - **Advanced Features (9 functions):** Fuse NFTs, upgrade skills, random attribute roll, vote for evolution path (governance), claim rarity reward, set base URI, pause/unpause, withdraw funds. Creative and advanced concepts.
 */
contract DynamicNFTEvolution {
    // --- State Variables ---
    string public name = "DynamicEvoNFT";
    string public symbol = "DENFT";
    string public baseURI;
    uint256 public totalSupply;
    uint256 public nextTokenId = 1;
    address public owner;
    bool public paused = false;

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => NFTData) public nftData;
    mapping(address => uint256) public ownerTokenCount;

    struct NFTData {
        uint8 evolutionStage;
        uint8[5] attributes; // Example: [Strength, Agility, Intelligence, Luck, Charisma]
        uint256 experiencePoints;
        uint8 rarityTier;
    }

    enum ActionType {
        QUEST,
        TRAINING,
        EXPLORATION,
        CHALLENGE
    }

    enum EvolutionPath {
        PATH_A,
        PATH_B,
        PATH_C
    }

    // --- Events ---
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event NFTMinted(uint256 indexed _tokenId, address indexed _owner);
    event NFTActionPerformed(uint256 indexed _tokenId, ActionType _actionType, address indexed _caller);
    event NFTEvolved(uint256 indexed _tokenId, uint8 _newStage);
    event NFTAttributeMutated(uint256 indexed _tokenId, uint8 _attributeIndex, uint8 _newValue);
    event NFTRandomAttributeRolled(uint256 indexed _tokenId, uint8[5] _newAttributes);
    event NFTFused(uint256 indexed _newTokenId, uint256 _tokenId1, uint256 _tokenId2);
    event NFTSkillUpgraded(uint256 indexed _tokenId, uint8 _skillIndex, uint8 _newLevel);
    event RarityRewardClaimed(uint256 indexed _tokenId, uint8 _rarityTier, address indexed _claimer);
    event EvolutionPathVoted(uint256 indexed _tokenId, EvolutionPath _pathId, address indexed _voter);
    event BaseURISet(string _newBaseURI, address indexed _caller);
    event ContractPaused(address indexed _caller);
    event ContractUnpaused(address indexed _caller);
    event FundsWithdrawn(address indexed _caller, uint256 _amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier approvedOrOwner(address _spender, uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender || _spender == tokenApprovals[_tokenId] || operatorApprovals[tokenOwner[_tokenId]][_spender], "Not approved to transfer.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    // --- Core NFT Functionality ---

    /// @notice Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI to use for this NFT type (can be updated later).
    function mintNFT(address _to, string memory _baseURI) external onlyOwner whenNotPaused returns (uint256) {
        uint256 newToken = nextTokenId++;
        tokenOwner[newToken] = _to;
        nftData[newToken] = NFTData({
            evolutionStage: 1,
            attributes: [5, 5, 5, 5, 5], // Initial attributes
            experiencePoints: 0,
            rarityTier: 1
        });
        totalSupply++;
        ownerTokenCount[_to]++;
        baseURI = _baseURI; // Set base URI during minting
        emit NFTMinted(newToken, _to);
        emit Transfer(address(0), _to, newToken);
        return newToken;
    }

    /// @notice Transfers an NFT from one address to another.
    /// @param _from The current owner of the NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) approvedOrOwner(msg.sender, _tokenId) {
        require(tokenOwner[_tokenId] == _from, "Incorrect from address.");
        require(_to != address(0), "Transfer to the zero address.");

        _clearApproval(_tokenId);
        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    /// @notice Safe transfer NFT, reverts if recipient is contract and does not implement ERC721Receiver
    function safeTransferFromNFT(address _from, address _to, uint256 _tokenId, bytes memory _data) external whenNotPaused validTokenId(_tokenId) approvedOrOwner(msg.sender, _tokenId) {
        transferNFT(_from, _to, _tokenId);
        // Add safe transfer check if needed (requires ERC721Receiver interface)
        // (omitted for simplicity in this example)
    }

    function safeTransferFromNFT(address _from, address _to, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) approvedOrOwner(msg.sender, _tokenId) {
        safeTransferFromNFT(_from, _to, _tokenId, "");
    }


    /// @notice Approves an address to transfer a specific NFT.
    /// @param _approved The address to be approved.
    /// @param _tokenId The ID of the NFT to approve.
    function approveNFT(address _approved, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    /// @notice Gets the approved address for a specific NFT.
    /// @param _tokenId The ID of the NFT to check approval for.
    /// @return The approved address or address(0) if no address is approved.
    function getApprovedNFT(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return tokenApprovals[_tokenId];
    }

    /// @notice Sets approval for an operator to transfer all NFTs of an owner.
    /// @param _operator The address to be approved as an operator.
    /// @param _approved True if the operator is approved, false to revoke approval.
    function setApprovalForAllNFT(address _operator, bool _approved) external whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Checks if an operator is approved for all NFTs of an owner.
    /// @param _owner The owner of the NFTs.
    /// @param _operator The address to check for operator approval.
    /// @return True if the operator is approved, false otherwise.
    function isApprovedForAllNFT(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /// @notice Returns the token URI for a given NFT ID.
    /// @param _tokenId The ID of the NFT.
    /// @return The token URI string.
    function tokenURINFT(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        // In a real implementation, this would likely be more dynamic,
        // potentially fetching metadata from IPFS or a similar decentralized storage.
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));
    }

    /// @notice Returns the owner of a given NFT ID.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the owner.
    function ownerOfNFT(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @notice Returns the balance of NFTs owned by an address.
    /// @param _owner The address to check the balance for.
    /// @return The number of NFTs owned by the address.
    function balanceOfNFT(address _owner) external view returns (uint256) {
        return ownerTokenCount[_owner];
    }

    /// @notice Returns the total supply of NFTs.
    /// @return The total number of NFTs minted.
    function totalSupplyNFT() external view returns (uint256) {
        return totalSupply;
    }

    // --- Dynamic Evolution and Attributes ---

    /// @notice Allows NFT owners to perform actions that can trigger evolution or attribute changes.
    /// @param _tokenId The ID of the NFT performing the action.
    /// @param _actionType The type of action being performed (e.g., QUEST, TRAINING).
    function performAction(uint256 _tokenId, uint8 _actionType) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        ActionType action = ActionType(_actionType); // Convert uint8 to enum
        require(_actionType < uint8(type(ActionType).max), "Invalid action type.");

        uint256 experienceGain;
        if (action == ActionType.QUEST) {
            experienceGain = 10;
        } else if (action == ActionType.TRAINING) {
            experienceGain = 5;
        } else if (action == ActionType.EXPLORATION) {
            experienceGain = 8;
        } else if (action == ActionType.CHALLENGE) {
            experienceGain = 15;
        } else {
            experienceGain = 0; // Default or error handling if needed
        }

        nftData[_tokenId].experiencePoints += experienceGain;
        emit NFTActionPerformed(_tokenId, action, msg.sender);

        // Check for evolution trigger (example: 100 exp per stage)
        if (nftData[_tokenId].experiencePoints >= 100 * nftData[_tokenId].evolutionStage) {
            evolveNFT(_tokenId);
        }
    }

    /// @notice Triggers the evolution process for an NFT based on accumulated experience.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) public whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        uint8 currentStage = nftData[_tokenId].evolutionStage;
        uint256 currentExp = nftData[_tokenId].experiencePoints;

        if (currentExp >= 100 * currentStage) {
            nftData[_tokenId].evolutionStage++;
            nftData[_tokenId].experiencePoints -= (100 * currentStage); // Reset exp for next stage
            // Example evolution attribute boost - can be more complex
            for (uint8 i = 0; i < nftData[_tokenId].attributes.length; i++) {
                nftData[_tokenId].attributes[i]++; // Increase all attributes by 1 on evolution
            }
            _updateRarityTier(_tokenId); // Recalculate rarity tier after evolution
            emit NFTEvolved(_tokenId, nftData[_tokenId].evolutionStage);
        } else {
            revert("Not enough experience to evolve.");
        }
    }

    /// @notice Mutates a specific attribute of an NFT based on randomness and conditions.
    /// @param _tokenId The ID of the NFT to mutate.
    /// @param _attributeIndex The index of the attribute to mutate (0-4 in this example).
    function mutateAttribute(uint256 _tokenId, uint8 _attributeIndex) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_attributeIndex < nftData[_tokenId].attributes.length, "Invalid attribute index.");

        // Example: Simple random mutation - can be improved with more sophisticated logic
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _attributeIndex)));
        uint8 mutationAmount = uint8(randomValue % 5) + 1; // Random increase 1-5

        nftData[_tokenId].attributes[_attributeIndex] += mutationAmount;
        _updateRarityTier(_tokenId); // Rarity tier might change after attribute mutation
        emit NFTAttributeMutated(_tokenId, _attributeIndex, nftData[_tokenId].attributes[_attributeIndex]);
    }

    /// @notice Retrieves the current attributes of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return An array of attribute values.
    function getNFTAttributes(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint8[5] memory) {
        return nftData[_tokenId].attributes;
    }

    /// @notice Gets the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The evolution stage (uint8).
    function getNFTEvolutionStage(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint8) {
        return nftData[_tokenId].evolutionStage;
    }

    // --- Advanced and Creative Functions ---

    /// @notice Allows owners to fuse two NFTs to create a new, potentially enhanced NFT.
    /// @param _tokenId1 The ID of the first NFT to fuse.
    /// @param _tokenId2 The ID of the second NFT to fuse.
    function fuseNFTs(uint256 _tokenId1, uint256 _tokenId2) external whenNotPaused validTokenId(_tokenId1) validTokenId(_tokenId2) onlyTokenOwner(_tokenId1) {
        require(tokenOwner[_tokenId2] == msg.sender, "You must own both NFTs to fuse.");

        // Create a new NFT - inheriting some properties from parents (example)
        uint256 newToken = nextTokenId++;
        address ownerFuse = msg.sender; // New NFT owned by the user fusing
        tokenOwner[newToken] = ownerFuse;

        // Attribute inheritance/combination logic (example - average attributes)
        uint8[5] memory combinedAttributes;
        for (uint8 i = 0; i < 5; i++) {
            combinedAttributes[i] = (nftData[_tokenId1].attributes[i] + nftData[_tokenId2].attributes[i]) / 2;
        }

        nftData[newToken] = NFTData({
            evolutionStage: nftData[_tokenId1].evolutionStage > nftData[_tokenId2].evolutionStage ? nftData[_tokenId1].evolutionStage : nftData[_tokenId2].evolutionStage, // Higher stage
            attributes: combinedAttributes,
            experiencePoints: 0, // Reset experience for fused NFT
            rarityTier: 1 // Recalculated below
        });
        _updateRarityTier(newToken);

        totalSupply++;
        ownerTokenCount[ownerFuse]++;

        // Burn the fused NFTs (transfer to address(0))
        _burnNFT(_tokenId1);
        _burnNFT(_tokenId2);

        emit NFTFused(newToken, _tokenId1, _tokenId2);
        emit NFTMinted(newToken, ownerFuse);
        emit Transfer(address(0), ownerFuse, newToken); // Mint event for clarity, though technically not a mint in the traditional sense.
    }

    /// @notice Allows owners to upgrade specific skills of their NFTs using simulated on-chain currency.
    /// @param _tokenId The ID of the NFT to upgrade.
    /// @param _skillIndex The index of the skill/attribute to upgrade (0-4).
    function upgradeSkill(uint256 _tokenId, uint8 _skillIndex) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_skillIndex < nftData[_tokenId].attributes.length, "Invalid skill index.");

        uint8 currentSkillLevel = nftData[_tokenId].attributes[_skillIndex];
        uint256 upgradeCost = 10 * (uint256(currentSkillLevel) + 1); // Example increasing cost

        // Simulate currency check - in a real game, this would interact with a token contract
        // For this example, we just check if the user 'has enough simulated currency'
        // (This part is simplified - replace with actual token balance check and transfer logic)
        // Assume a function `hasEnoughCurrency(address _user, uint256 _amount)` exists elsewhere
        // require(hasEnoughCurrency(msg.sender, upgradeCost), "Not enough currency to upgrade skill.");
        // (Simulated check for demonstration purposes)
        if (true) { // Replace with actual currency check
            nftData[_tokenId].attributes[_skillIndex]++; // Upgrade skill
            _updateRarityTier(_tokenId);
            emit NFTSkillUpgraded(_tokenId, _skillIndex, nftData[_tokenId].attributes[_skillIndex]);
            // Simulate currency transfer - in a real game, transfer tokens from user to contract/treasury
            // transferCurrency(msg.sender, address(this), upgradeCost);
        } else {
            revert("Simulated currency check failed (replace with actual currency logic).");
        }
    }

    /// @notice Initiates a random attribute roll for an NFT, using on-chain randomness (simplified).
    /// @param _tokenId The ID of the NFT to roll attributes for.
    function rollRandomAttribute(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        // Simplified on-chain randomness - for production use, consider Chainlink VRF or similar
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId)));
        uint8[5] memory newAttributes;
        for (uint8 i = 0; i < 5; i++) {
            newAttributes[i] = uint8(randomSeed % 20) + 1; // Random attribute value 1-20 (example range)
            randomSeed = randomSeed / 20; // Move to next pseudo-random value
        }

        nftData[_tokenId].attributes = newAttributes;
        _updateRarityTier(_tokenId);
        emit NFTRandomAttributeRolled(_tokenId, newAttributes);
    }

    /// @notice Allows NFT holders to vote on future evolution paths for their NFT type. (Decentralized Governance Simulation)
    /// @param _tokenId The ID of the NFT voting.
    /// @param _pathId The ID of the evolution path being voted for.
    function voteForEvolutionPath(uint256 _tokenId, uint8 _pathId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        EvolutionPath path = EvolutionPath(_pathId); // Convert uint8 to enum
        require(_pathId < uint8(type(EvolutionPath).max), "Invalid evolution path ID.");

        // In a real governance system, voting power might be weighted by NFT attributes or staking.
        // For this example, it's a simple vote per NFT.
        // Implement voting logic here - likely using a separate voting contract or system in a real application.
        // For simplicity, we just emit an event indicating the vote.

        emit EvolutionPathVoted(_tokenId, path, msg.sender);
        // In a real system, track votes, aggregate, and implement logic to change evolution paths based on votes.
    }

    /// @notice Allows NFT holders to claim rewards based on their NFT's current rarity tier.
    /// @param _tokenId The ID of the NFT claiming the reward.
    function claimRarityTierReward(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        uint8 rarityTier = nftData[_tokenId].rarityTier;
        uint256 rewardAmount;

        if (rarityTier == 5) { // Example: Tier 5 is highest rarity
            rewardAmount = 100 ether; // Example reward - could be tokens, NFTs, etc.
        } else if (rarityTier == 4) {
            rewardAmount = 50 ether;
        } else if (rarityTier == 3) {
            rewardAmount = 20 ether;
        } else {
            rewardAmount = 0; // No reward for lower tiers in this example
        }

        if (rewardAmount > 0) {
            payable(msg.sender).transfer(rewardAmount); // Transfer reward in ETH (example)
            emit RarityRewardClaimed(_tokenId, rarityTier, msg.sender);
        } else {
            revert("No reward for this rarity tier.");
        }
    }

    // --- Admin Functions ---

    /// @notice Sets the base URI for NFT metadata. Only callable by the contract owner.
    /// @param _newBaseURI The new base URI string.
    function setBaseURINFT(string memory _newBaseURI) external onlyOwner whenNotPaused {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI, msg.sender);
    }

    /// @notice Pauses the contract, preventing core functionalities from being used.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring core functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to withdraw any Ether in the contract.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    // --- Internal Helper Functions ---

    function _burnNFT(uint256 _tokenId) internal validTokenId(_tokenId) {
        address ownerBurn = tokenOwner[_tokenId];
        _clearApproval(_tokenId);
        ownerTokenCount[ownerBurn]--;
        delete tokenOwner[_tokenId];
        delete nftData[_tokenId];
        totalSupply--;
        emit Transfer(ownerBurn, address(0), _tokenId); // Transfer to zero address indicates burn
    }


    function _clearApproval(uint256 _tokenId) private {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
            emit Approval(tokenOwner[_tokenId], address(0), _tokenId); // Emit approval to null address
        }
    }

    function _updateRarityTier(uint256 _tokenId) internal validTokenId(_tokenId) {
        // Example Rarity Calculation - can be customized based on attribute distribution
        uint256 totalAttributes = 0;
        for (uint8 i = 0; i < nftData[_tokenId].attributes.length; i++) {
            totalAttributes += nftData[_tokenId].attributes[i];
        }

        if (totalAttributes >= 80) {
            nftData[_tokenId].rarityTier = 5; // Legendary
        } else if (totalAttributes >= 60) {
            nftData[_tokenId].rarityTier = 4; // Epic
        } else if (totalAttributes >= 40) {
            nftData[_tokenId].rarityTier = 3; // Rare
        } else if (totalAttributes >= 25) {
            nftData[_tokenId].rarityTier = 2; // Uncommon
        } else {
            nftData[_tokenId].rarityTier = 1; // Common
        }
    }
}

// --- Library for String Conversion (Optional, but useful for tokenURI) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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