```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (Example - Replace with your actual name/handle)
 * @dev A smart contract implementing a dynamic NFT system where NFTs evolve based on various on-chain interactions and conditions.
 *      This contract introduces a multi-stage evolution process influenced by user actions, time, and resource management.
 *      It goes beyond simple ERC721 by incorporating dynamic traits, evolution mechanics, staking, and community-driven features.
 *
 * Function Summary:
 *
 * **NFT Core Functions:**
 * 1. mintNFT(address _to, string memory _baseURI) - Mints a new evolving NFT to a specified address.
 * 2. tokenURI(uint256 _tokenId) - Returns the dynamic URI for an NFT, reflecting its current evolution stage and traits.
 * 3. transferNFT(address _to, uint256 _tokenId) - Transfers ownership of an NFT.
 * 4. approveNFT(address _approved, uint256 _tokenId) - Approves an address to operate on a single NFT.
 * 5. setApprovalForAllNFT(address _operator, bool _approved) - Enables or disables approval for an operator to manage all of owner's NFTs.
 * 6. getOwnerOfNFT(uint256 _tokenId) - Returns the owner of a given NFT.
 * 7. getBalanceOfNFT(address _owner) - Returns the number of NFTs owned by an address.
 *
 * **Evolution & Dynamic Traits Functions:**
 * 8. interactWithNFT(uint256 _tokenId, uint8 _interactionType) - Allows users to interact with their NFTs, influencing evolution (e.g., feeding, training).
 * 9. checkEvolution(uint256 _tokenId) - Manually triggers evolution check based on accumulated interaction points and time.
 * 10. getNFTStage(uint256 _tokenId) - Returns the current evolution stage of an NFT.
 * 11. getNFTTraits(uint256 _tokenId) - Returns the current traits of an NFT as a string (can be customized/decoded off-chain).
 * 12. getInteractionPoints(uint256 _tokenId) - Returns the accumulated interaction points for an NFT.
 * 13. getEvolutionTimestamp(uint256 _tokenId) - Returns the timestamp of the last evolution for an NFT.
 * 14. setEvolutionParameters(uint8 _stage, uint256 _interactionThreshold, uint256 _evolutionTimeThreshold) - Admin function to adjust evolution parameters for a specific stage.
 *
 * **Resource Management Functions:**
 * 15. collectResource(uint256 _tokenId) - Allows NFT holders to "collect resources" associated with their NFT (simulating in-game resource generation based on NFT stage).
 * 16. getResourceBalance(uint256 _tokenId) - Returns the resource balance associated with an NFT.
 * 17. useResourceForBoost(uint256 _tokenId) - Allows users to use resources to boost NFT evolution or traits temporarily.
 *
 * **Staking & Community Functions:**
 * 18. stakeNFT(uint256 _tokenId) - Allows users to stake their NFTs to earn rewards or influence community events (placeholder for staking logic).
 * 19. unstakeNFT(uint256 _tokenId) - Allows users to unstake their NFTs.
 * 20. getStakingStatus(uint256 _tokenId) - Returns the staking status of an NFT.
 *
 * **Admin & Utility Functions:**
 * 21. pauseContract() - Pauses the contract, preventing minting and evolution.
 * 22. unpauseContract() - Resumes the contract operations.
 * 23. withdrawFunds() - Allows the contract owner to withdraw accumulated contract balance (if any).
 * 24. supportsInterface(bytes4 interfaceId) - Standard ERC165 interface support.
 */

contract DynamicNFTEvolution {
    // --- State Variables ---

    string public name = "Dynamic Evolving NFTs";
    string public symbol = "DENFT";
    string public baseURI; // Base URI for token metadata

    uint256 public totalSupply;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Ascended }
    struct NFTData {
        EvolutionStage stage;
        string traits; // Dynamic traits, can be updated upon evolution
        uint256 interactionPoints;
        uint256 lastEvolutionTimestamp;
        uint256 resourceBalance;
        bool isStaked;
    }
    mapping(uint256 => NFTData) public nftData;

    // Evolution Parameters per Stage (can be adjusted by admin)
    mapping(EvolutionStage => uint256) public interactionThresholds; // Points needed to evolve
    mapping(EvolutionStage => uint256) public evolutionTimeThresholds; // Time elapsed needed to evolve (in seconds)

    bool public paused;
    address public owner;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTApproved(uint256 tokenId, address approved);
    event ApprovalForAll(address owner, address operator, bool approved);
    event NFT взаимодействовал(uint256 tokenId, uint8 interactionType); // Interaction Event
    event NFTEvolved(uint256 tokenId, EvolutionStage fromStage, EvolutionStage toStage, string newTraits);
    event ResourceCollected(uint256 tokenId, uint256 amount);
    event ResourceUsedForBoost(uint256 tokenId, uint256 amount);
    event NFTStaked(uint256 tokenId);
    event NFTUnstaked(uint256 tokenId);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
    event FundsWithdrawn(address to, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier approvedOrOwner(address _spender, uint256 _tokenId) {
        address owner_ = tokenOwner[_tokenId];
        require(
            _spender == owner_ || tokenApprovals[_tokenId] == _spender || operatorApprovals[owner_][_spender],
            "Not approved for NFT operation"
        );
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseTokenURI) {
        owner = msg.sender;
        baseURI = _baseTokenURI;
        paused = false;

        // Initialize default evolution parameters (Example values, can be adjusted by admin)
        interactionThresholds[EvolutionStage.Egg] = 100;
        evolutionTimeThresholds[EvolutionStage.Egg] = 60 * 60 * 24; // 24 hours
        interactionThresholds[EvolutionStage.Hatchling] = 300;
        evolutionTimeThresholds[EvolutionStage.Hatchling] = 60 * 60 * 48; // 48 hours
        interactionThresholds[EvolutionStage.Juvenile] = 500;
        evolutionTimeThresholds[EvolutionStage.Juvenile] = 60 * 60 * 72; // 72 hours
        interactionThresholds[EvolutionStage.Adult] = 1000; // No further evolution after Adult for this example, but could be expanded
        evolutionTimeThresholds[EvolutionStage.Adult] = type(uint256).max; // No time limit for "Adult" to "Ascended" if we add it later

    }

    // --- NFT Core Functions ---

    /// @notice Mints a new evolving NFT to a specified address.
    /// @param _to The address to receive the NFT.
    /// @param _baseURI Base URI for token metadata
    function mintNFT(address _to, string memory _baseURI) external onlyOwner whenNotPaused {
        uint256 newTokenId = totalSupply++;
        tokenOwner[newTokenId] = _to;
        ownerTokenCount[_to]++;
        nftData[newTokenId] = NFTData({
            stage: EvolutionStage.Egg,
            traits: "Common", // Initial traits
            interactionPoints: 0,
            lastEvolutionTimestamp: block.timestamp,
            resourceBalance: 0,
            isStaked: false
        });
        baseURI = _baseURI; // Update baseURI if needed for each mint (or set once in constructor)

        emit NFTMinted(newTokenId, _to);
    }


    /// @notice Returns the dynamic URI for an NFT, reflecting its current evolution stage and traits.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI string.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        string memory stageName;
        EvolutionStage currentStage = nftData[_tokenId].stage;
        if (currentStage == EvolutionStage.Egg) {
            stageName = "Egg";
        } else if (currentStage == EvolutionStage.Hatchling) {
            stageName = "Hatchling";
        } else if (currentStage == EvolutionStage.Juvenile) {
            stageName = "Juvenile";
        } else if (currentStage == EvolutionStage.Adult) {
            stageName = "Adult";
        } else if (currentStage == EvolutionStage.Ascended) {
            stageName = "Ascended";
        }
        // Example: Construct dynamic URI based on stage and traits. Adapt to your metadata storage.
        return string(abi.encodePacked(baseURI, "/", stageName, "/", nftData[_tokenId].traits, ".json"));
    }

    /// @notice Transfers ownership of an NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused approvedOrOwner(msg.sender, _tokenId) {
        require(_to != address(0), "Transfer to the zero address");
        require(_exists(_tokenId), "Token transfer of nonexistent token");
        address from = tokenOwner[_tokenId];
        _clearApproval(_tokenId);

        ownerTokenCount[from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;

        emit NFTTransferred(_tokenId, from, _to);
    }

    /// @notice Approves an address to operate on a single NFT.
    /// @param _approved The address to be approved.
    /// @param _tokenId The ID of the NFT to be approved for.
    function approveNFT(address _approved, uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit NFTApproved(_tokenId, _approved);
    }

    /// @notice Enables or disables approval for an operator to manage all of owner's NFTs.
    /// @param _operator The address to act as operator.
    /// @param _approved True if the operator is approved, false to revoke approval.
    function setApprovalForAllNFT(address _operator, bool _approved) external whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Returns the owner of a given NFT.
    /// @param _tokenId The ID of the NFT to query.
    /// @return The address of the owner.
    function getOwnerOfNFT(uint256 _tokenId) public view returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @notice Returns the number of NFTs owned by an address.
    /// @param _owner The address to query.
    /// @return The number of NFTs owned by the address.
    function getBalanceOfNFT(address _owner) public view returns (uint256) {
        return ownerTokenCount[_owner];
    }

    // --- Evolution & Dynamic Traits Functions ---

    /// @notice Allows users to interact with their NFTs, influencing evolution.
    /// @param _tokenId The ID of the NFT to interact with.
    /// @param _interactionType Type of interaction (e.g., 1 for feeding, 2 for training, etc.).
    function interactWithNFT(uint256 _tokenId, uint8 _interactionType) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Interact with nonexistent token");

        // Example interaction logic: Increase interaction points based on interaction type
        if (_interactionType == 1) { // Feeding
            nftData[_tokenId].interactionPoints += 20;
        } else if (_interactionType == 2) { // Training
            nftData[_tokenId].interactionPoints += 30;
        } else { // Default interaction
            nftData[_tokenId].interactionPoints += 10;
        }

        emit NFT взаимодействовал(_tokenId, _interactionType);
        _checkAndEvolveNFT(_tokenId); // Automatically check for evolution after interaction
    }

    /// @notice Manually triggers evolution check for an NFT.
    /// @param _tokenId The ID of the NFT to check.
    function checkEvolution(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Evolution check for nonexistent token");
        _checkAndEvolveNFT(_tokenId);
    }

    /// @dev Internal function to check and evolve an NFT if conditions are met.
    /// @param _tokenId The ID of the NFT to check.
    function _checkAndEvolveNFT(uint256 _tokenId) internal {
        EvolutionStage currentStage = nftData[_tokenId].stage;
        EvolutionStage nextStage = currentStage; // Default to no evolution

        if (currentStage == EvolutionStage.Egg) {
            if (nftData[_tokenId].interactionPoints >= interactionThresholds[EvolutionStage.Egg] ||
                block.timestamp >= nftData[_tokenId].lastEvolutionTimestamp + evolutionTimeThresholds[EvolutionStage.Egg]) {
                nextStage = EvolutionStage.Hatchling;
            }
        } else if (currentStage == EvolutionStage.Hatchling) {
            if (nftData[_tokenId].interactionPoints >= interactionThresholds[EvolutionStage.Hatchling] ||
                block.timestamp >= nftData[_tokenId].lastEvolutionTimestamp + evolutionTimeThresholds[EvolutionStage.Hatchling]) {
                nextStage = EvolutionStage.Juvenile;
            }
        } else if (currentStage == EvolutionStage.Juvenile) {
            if (nftData[_tokenId].interactionPoints >= interactionThresholds[EvolutionStage.Juvenile] ||
                block.timestamp >= nftData[_tokenId].lastEvolutionTimestamp + evolutionTimeThresholds[EvolutionStage.Juvenile]) {
                nextStage = EvolutionStage.Adult;
            }
        } else if (currentStage == EvolutionStage.Adult) {
            // Example: Optional evolution to Ascended stage (can be based on more criteria or even community votes)
            // if (someConditionForAscension) { nextStage = EvolutionStage.Ascended; }
            nextStage = EvolutionStage.Adult; // No further evolution in this example after Adult
        }

        if (nextStage != currentStage) {
            _evolveNFT(_tokenId, nextStage);
        }
    }

    /// @dev Internal function to evolve an NFT to a new stage and update traits.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _newStage The new evolution stage.
    function _evolveNFT(uint256 _tokenId, EvolutionStage _newStage) internal {
        EvolutionStage oldStage = nftData[_tokenId].stage;
        nftData[_tokenId].stage = _newStage;
        nftData[_tokenId].lastEvolutionTimestamp = block.timestamp;
        nftData[_tokenId].interactionPoints = 0; // Reset interaction points after evolution

        // Example: Update traits upon evolution (can be more complex, e.g., based on randomness, interaction history, etc.)
        string memory newTraits;
        if (_newStage == EvolutionStage.Hatchling) {
            newTraits = "Agile";
        } else if (_newStage == EvolutionStage.Juvenile) {
            newTraits = "Strong";
        } else if (_newStage == EvolutionStage.Adult) {
            newTraits = "Wise";
        } else if (_newStage == EvolutionStage.Ascended) {
            newTraits = "Divine";
        } else {
            newTraits = nftData[_tokenId].traits; // Keep old traits if no specific traits for this stage
        }
        nftData[_tokenId].traits = newTraits;

        emit NFTEvolved(_tokenId, oldStage, _newStage, newTraits);
    }

    /// @notice Returns the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The evolution stage enum.
    function getNFTStage(uint256 _tokenId) public view returns (EvolutionStage) {
        require(_exists(_tokenId), "Stage query for nonexistent token");
        return nftData[_tokenId].stage;
    }

    /// @notice Returns the current traits of an NFT as a string.
    /// @param _tokenId The ID of the NFT.
    /// @return The trait string.
    function getNFTTraits(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Traits query for nonexistent token");
        return nftData[_tokenId].traits;
    }

    /// @notice Returns the accumulated interaction points for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The interaction points.
    function getInteractionPoints(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Interaction points query for nonexistent token");
        return nftData[_tokenId].interactionPoints;
    }

    /// @notice Returns the timestamp of the last evolution for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The timestamp.
    function getEvolutionTimestamp(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Evolution timestamp query for nonexistent token");
        return nftData[_tokenId].lastEvolutionTimestamp;
    }

    /// @notice Admin function to adjust evolution parameters for a specific stage.
    /// @param _stage The evolution stage to adjust parameters for.
    /// @param _interactionThreshold The new interaction points threshold.
    /// @param _evolutionTimeThreshold The new evolution time threshold (in seconds).
    function setEvolutionParameters(EvolutionStage _stage, uint256 _interactionThreshold, uint256 _evolutionTimeThreshold) external onlyOwner whenNotPaused {
        interactionThresholds[_stage] = _interactionThreshold;
        evolutionTimeThresholds[_stage] = _evolutionTimeThreshold;
    }


    // --- Resource Management Functions ---

    /// @notice Allows NFT holders to "collect resources" associated with their NFT.
    /// @param _tokenId The ID of the NFT.
    function collectResource(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Resource collection for nonexistent token");

        uint256 resourceAmount;
        EvolutionStage currentStage = nftData[_tokenId].stage;

        // Example: Resource generation based on evolution stage
        if (currentStage == EvolutionStage.Egg) {
            resourceAmount = 10;
        } else if (currentStage == EvolutionStage.Hatchling) {
            resourceAmount = 25;
        } else if (currentStage == EvolutionStage.Juvenile) {
            resourceAmount = 50;
        } else if (currentStage == EvolutionStage.Adult) {
            resourceAmount = 100;
        } else if (currentStage == EvolutionStage.Ascended) {
            resourceAmount = 150;
        } else {
            resourceAmount = 0;
        }

        nftData[_tokenId].resourceBalance += resourceAmount;
        emit ResourceCollected(_tokenId, resourceAmount);
    }

    /// @notice Returns the resource balance associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The resource balance.
    function getResourceBalance(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Resource balance query for nonexistent token");
        return nftData[_tokenId].resourceBalance;
    }

    /// @notice Allows users to use resources to boost NFT evolution or traits temporarily.
    /// @param _tokenId The ID of the NFT.
    function useResourceForBoost(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Resource boost for nonexistent token");
        require(nftData[_tokenId].resourceBalance >= 50, "Not enough resources for boost"); // Example cost: 50 resources

        nftData[_tokenId].resourceBalance -= 50; // Deduct resources
        nftData[_tokenId].interactionPoints += 100; // Example boost: Increase interaction points by 100
        emit ResourceUsedForBoost(_tokenId, 50);

        _checkAndEvolveNFT(_tokenId); // Check for evolution after boost
    }


    // --- Staking & Community Functions ---

    /// @notice Allows users to stake their NFTs.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Stake nonexistent token");
        require(!nftData[_tokenId].isStaked, "NFT already staked");

        nftData[_tokenId].isStaked = true;
        emit NFTStaked(_tokenId);
        // Implement staking rewards logic here if needed (e.g., accrue tokens over time)
    }

    /// @notice Allows users to unstake their NFTs.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_exists(_tokenId), "Unstake nonexistent token");
        require(nftData[_tokenId].isStaked, "NFT not staked");

        nftData[_tokenId].isStaked = false;
        emit NFTUnstaked(_tokenId);
        // Implement staking rewards claim logic here if needed
    }

    /// @notice Returns the staking status of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return True if staked, false otherwise.
    function getStakingStatus(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Staking status query for nonexistent token");
        return nftData[_tokenId].isStaked;
    }


    // --- Admin & Utility Functions ---

    /// @notice Pauses the contract, preventing minting and evolution.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes the contract operations.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to withdraw accumulated contract balance.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC165 interface ID for supportsInterface
    }


    // --- Internal Helper Functions ---

    /// @dev Checks if a token ID exists.
    /// @param _tokenId The token ID to check.
    /// @return True if the token exists, false otherwise.
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }

    /// @dev Clears the approval for a token ID.
    /// @param _tokenId The token ID to clear approval for.
    function _clearApproval(uint256 _tokenId) internal {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }
}

// --- Interfaces for ERC721 (for supportsInterface compliance, not strictly necessary for functionality within this contract but good practice) ---
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address approved, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256 tokenId);
}
```