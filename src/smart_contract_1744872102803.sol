```solidity
/**
 * @title Decentralized Dynamic NFT with On-Chain Interactions & Reputation System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a unique Decentralized Dynamic NFT (dNFT) system.
 *      This dNFT evolves based on on-chain interactions and accumulates a reputation score.
 *      It features advanced concepts like dynamic metadata updates, on-chain actions influencing NFT traits,
 *      a reputation system influencing NFT utility, and decentralized governance for NFT evolution.
 *
 * **Outline & Function Summary:**
 *
 * **Core dNFT Functions:**
 * 1. `mintNFT(string _baseURI)`: Mints a new dNFT with an initial base URI.
 * 2. `tokenURI(uint256 _tokenId)`: Returns the dynamic URI for a given dNFT, reflecting its current state.
 * 3. `getNFTTraits(uint256 _tokenId)`: Returns the current traits of a dNFT, influencing its metadata.
 * 4. `interactWithNFT(uint256 _tokenId, uint8 _interactionType)`: Allows users to interact with a dNFT, triggering trait evolution and reputation changes.
 * 5. `evolveNFT(uint256 _tokenId)`: (Internal/Admin) Manually triggers the evolution logic for a dNFT.
 * 6. `setBaseMetadata(uint256 _tokenId, string _newBaseMetadata)`: (Admin) Sets a new base metadata URI for a specific dNFT.
 * 7. `setGlobalBaseURI(string _newGlobalBaseURI)`: (Admin) Sets a new global base URI prefix for all dNFTs.
 * 8. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of a dNFT. (Standard ERC721)
 * 9. `burnNFT(uint256 _tokenId)`: Burns (destroys) a dNFT.
 *
 * **Reputation System Functions:**
 * 10. `getReputation(uint256 _tokenId)`: Retrieves the reputation score of a dNFT.
 * 11. `increaseReputation(uint256 _tokenId, uint256 _amount)`: (Internal) Increases a dNFT's reputation.
 * 12. `decreaseReputation(uint256 _tokenId, uint256 _amount)`: (Internal) Decreases a dNFT's reputation.
 * 13. `applyReputationBonus(uint256 _tokenId)`: (Admin/Governance) Applies a reputation bonus to a dNFT based on community votes/actions.
 *
 * **Utility & Feature Functions:**
 * 14. `enableFeatureForReputation(uint256 _featureId, uint256 _minReputation)`: (Admin/Governance) Enables a specific feature for dNFTs with a minimum reputation.
 * 15. `isFeatureEnabled(uint256 _tokenId, uint256 _featureId)`: Checks if a specific feature is enabled for a dNFT based on its reputation.
 * 16. `registerInteractionType(string _interactionName, uint8 _interactionId)`: (Admin) Registers a new interaction type with a unique ID.
 * 17. `getInteractionName(uint8 _interactionId)`: Retrieves the name of an interaction type.
 * 18. `setTraitEvolutionRule(uint8 _interactionType, uint8 _traitId, int8 _evolutionValue)`: (Admin) Defines rules for how interactions affect NFT traits.
 * 19. `getTraitEvolutionRule(uint8 _interactionType, uint8 _traitId)`: Retrieves the evolution rule for a specific interaction and trait.
 * 20. `pauseContract()`: (Admin) Pauses core contract functionalities.
 * 21. `unpauseContract()`: (Admin) Resumes contract functionalities.
 * 22. `setGovernanceContract(address _governanceContract)`: (Admin) Sets the address of the governance contract (for future decentralized control).
 * 23. `getGovernanceContract()`: (Admin) Retrieves the address of the governance contract.
 * 24. `withdrawFees()`: (Admin) Allows admin to withdraw accumulated contract fees (if any, for future features).

 * **Events:**
 * - `NFTMinted(uint256 tokenId, address owner)`: Emitted when a new dNFT is minted.
 * - `NFTInteracted(uint256 tokenId, address interactor, uint8 interactionType)`: Emitted when a user interacts with a dNFT.
 * - `NFTEvolved(uint256 tokenId, uint256 newTraits)`: Emitted when a dNFT evolves.
 * - `ReputationChanged(uint256 tokenId, uint256 newReputation)`: Emitted when a dNFT's reputation changes.
 * - `FeatureEnabledByReputation(uint256 featureId, uint256 minReputation)`: Emitted when a feature is enabled for a reputation level.
 * - `BaseMetadataUpdated(uint256 tokenId, string newBaseMetadata)`: Emitted when a dNFT's base metadata is updated.
 * - `GlobalBaseURIUpdated(string newGlobalBaseURI)`: Emitted when the global base URI is updated.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public globalBaseURI;
    mapping(uint256 => string) private _baseMetadataURIs;
    mapping(uint256 => uint256) private _nftTraits; // Represent traits as a uint256 bitmask or struct for more complex traits
    mapping(uint256 => uint256) private _nftReputation;
    mapping(uint8 => string) private _interactionTypes;
    mapping(uint8 => mapping(uint8 => int8)) private _traitEvolutionRules; // interactionType => traitId => evolutionValue
    mapping(uint256 => uint256) private _featureMinReputation; // featureId => minReputation
    mapping(uint256 => address) private _tokenApprovals; // ERC721 approvals (redundant with OpenZeppelin ERC721, but for clarity if we extend)
    address public governanceContract;
    bool public paused;


    // Define trait IDs for easier management (Example - can be expanded)
    uint8 public constant TRAIT_TYPE = 0; // Example: Type of NFT (Warrior, Mage, etc.)
    uint8 public constant TRAIT_POWER = 1; // Example: Power level
    uint8 public constant TRAIT_AGILITY = 2; // Example: Agility level
    uint8 public constant TRAIT_LUCK = 3;  // Example: Luck factor

    // Define interaction type IDs (Example - can be expanded)
    uint8 public constant INTERACTION_QUEST_COMPLETED = 1;
    uint8 public constant INTERACTION_PVP_WIN = 2;
    uint8 public constant INTERACTION_SOCIAL_ENGAGEMENT = 3;
    uint8 public constant INTERACTION_NEGATIVE_ACTION = 4; // Example: Penalties


    // Define Feature IDs (Example - can be expanded)
    uint256 public constant FEATURE_EXCLUSIVE_ACCESS = 1;
    uint256 public constant FEATURE_REWARDS_BOOST = 2;
    uint256 public constant FEATURE_CUSTOMIZATION_OPTIONS = 3;


    event NFTMinted(uint256 tokenId, address owner);
    event NFTInteracted(uint256 tokenId, address interactor, uint8 interactionType);
    event NFTEvolved(uint256 tokenId, uint256 newTraits);
    event ReputationChanged(uint256 tokenId, uint256 newReputation);
    event FeatureEnabledByReputation(uint256 featureId, uint256 minReputation);
    event BaseMetadataUpdated(uint256 tokenId, string newBaseMetadata);
    event GlobalBaseURIUpdated(string newGlobalBaseURI);

    constructor(string memory _name, string memory _symbol, string memory _globalBaseURI) ERC721(_name, _symbol) {
        globalBaseURI = _globalBaseURI;
        _interactionTypes[INTERACTION_QUEST_COMPLETED] = "Quest Completed";
        _interactionTypes[INTERACTION_PVP_WIN] = "PvP Win";
        _interactionTypes[INTERACTION_SOCIAL_ENGAGEMENT] = "Social Engagement";
        _interactionTypes[INTERACTION_NEGATIVE_ACTION] = "Negative Action";

        // Example trait evolution rules:
        _setTraitEvolutionRule(INTERACTION_QUEST_COMPLETED, TRAIT_POWER, 1); // Quest completion increases power
        _setTraitEvolutionRule(INTERACTION_PVP_WIN, TRAIT_AGILITY, 2);      // PvP win increases agility
        _setTraitEvolutionRule(INTERACTION_SOCIAL_ENGAGEMENT, TRAIT_LUCK, 1);   // Social engagement increases luck
        _setTraitEvolutionRule(INTERACTION_NEGATIVE_ACTION, TRAIT_POWER, -1);   // Negative action decreases power
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "Only governance contract can call this function");
        _;
    }

    /**
     * @dev Mints a new dNFT.
     * @param _baseURI Base URI for the NFT's metadata.
     */
    function mintNFT(string memory _baseURI) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _baseMetadataURIs[tokenId] = _baseURI;
        _nftTraits[tokenId] = _getDefaultTraits(); // Initialize with default traits
        _nftReputation[tokenId] = 0; // Initial reputation is 0
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @dev Returns the dynamic URI for a given dNFT, reflecting its current state.
     * @param _tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        string memory baseURI = _baseMetadataURIs[_tokenId];
        if (bytes(baseURI).length == 0) {
            baseURI = globalBaseURI;
        }
        // Dynamically generate URI based on traits, reputation, etc.
        // For simplicity, we can append tokenId and current traits to the base URI.
        string memory traitsString = _uint256ToString(_nftTraits[_tokenId]); // Convert traits to string for URI
        return string(abi.encodePacked(baseURI, "/", _uint2str(_tokenId), "?traits=", traitsString, "&rep=", _uint2str(_nftReputation[_tokenId])));
    }

    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function _uint256ToString(uint256 _i) internal pure returns (string memory) {
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
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }


    /**
     * @dev Returns the current traits of a dNFT.
     * @param _tokenId The ID of the NFT.
     * @return The traits as a uint256 (or struct if traits are complex).
     */
    function getNFTTraits(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        return _nftTraits[_tokenId];
    }

    /**
     * @dev Allows users to interact with a dNFT, triggering trait evolution and reputation changes.
     * @param _tokenId The ID of the NFT being interacted with.
     * @param _interactionType The type of interaction (e.g., Quest Completed, PvP Win).
     */
    function interactWithNFT(uint256 _tokenId, uint8 _interactionType) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(_interactionTypes[_interactionType].length > 0, "Invalid interaction type");

        // Apply trait evolution based on interaction type
        _evolveTraits(_tokenId, _interactionType);

        // Update reputation based on interaction type (can be more complex logic)
        if (_interactionType == INTERACTION_QUEST_COMPLETED || _interactionType == INTERACTION_PVP_WIN || _interactionType == INTERACTION_SOCIAL_ENGAGEMENT) {
            increaseReputation(_tokenId, 1); // Example: positive interactions increase reputation
        } else if (_interactionType == INTERACTION_NEGATIVE_ACTION) {
            decreaseReputation(_tokenId, 1); // Example: negative interactions decrease reputation
        }

        emit NFTInteracted(_tokenId, msg.sender, _interactionType);
        evolveNFT(_tokenId); // Trigger NFT evolution after interaction (can be automatic or delayed)
    }

    /**
     * @dev (Internal) Evolves the NFT based on some logic (e.g., time-based, interaction count, etc.).
     *      Currently a placeholder for more complex evolution logic.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) internal whenNotPaused {
        // Example: Simple time-based evolution (can be replaced with more complex logic)
        // if (block.timestamp % 1 days == 0) { // Evolve every day (example)
        //     _nftTraits[_tokenId] = _nftTraits[_tokenId] + 1; // Simple trait increase
        //     emit NFTEvolved(_tokenId, _nftTraits[_tokenId]);
        // }
        // For now, evolution is primarily driven by interactions in interactWithNFT
         emit NFTEvolved(_tokenId, _nftTraits[_tokenId]); // Emit event even if no change
    }

    /**
     * @dev (Admin) Sets a new base metadata URI for a specific dNFT.
     * @param _tokenId The ID of the NFT.
     * @param _newBaseMetadata The new base metadata URI.
     */
    function setBaseMetadata(uint256 _tokenId, string memory _newBaseMetadata) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        _baseMetadataURIs[_tokenId] = _newBaseMetadata;
        emit BaseMetadataUpdated(_tokenId, _newBaseMetadata);
    }

    /**
     * @dev (Admin) Sets a new global base URI prefix for all dNFTs (used if individual base URI is not set).
     * @param _newGlobalBaseURI The new global base URI.
     */
    function setGlobalBaseURI(string memory _newGlobalBaseURI) public onlyOwner whenNotPaused {
        globalBaseURI = _newGlobalBaseURI;
        emit GlobalBaseURIUpdated(_newGlobalBaseURI);
    }

    // Standard ERC721 transfer function (using OpenZeppelin implementation)
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        transferFrom(msg.sender, _to, _tokenId);
    }

    // Standard ERC721 burn function
    function burnNFT(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _burn(_tokenId);
    }

    /**
     * @dev Retrieves the reputation score of a dNFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score.
     */
    function getReputation(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        return _nftReputation[_tokenId];
    }

    /**
     * @dev (Internal) Increases a dNFT's reputation.
     * @param _tokenId The ID of the NFT.
     * @param _amount The amount to increase reputation by.
     */
    function increaseReputation(uint256 _tokenId, uint256 _amount) internal {
        _nftReputation[_tokenId] = _nftReputation[_tokenId] + _amount;
        emit ReputationChanged(_tokenId, _nftReputation[_tokenId]);
    }

    /**
     * @dev (Internal) Decreases a dNFT's reputation.
     * @param _tokenId The ID of the NFT.
     * @param _amount The amount to decrease reputation by.
     */
    function decreaseReputation(uint256 _tokenId, uint256 _amount) internal {
        // Prevent reputation from going below 0
        _nftReputation[_tokenId] = _nftReputation[_tokenId] > _amount ? _nftReputation[_tokenId] - _amount : 0;
        emit ReputationChanged(_tokenId, _nftReputation[_tokenId]);
    }

    /**
     * @dev (Admin/Governance) Applies a reputation bonus to a dNFT.
     *      This could be triggered by community votes or other governance actions.
     * @param _tokenId The ID of the NFT.
     */
    function applyReputationBonus(uint256 _tokenId) public onlyOwner whenNotPaused { // Consider making this governance controlled
        require(_exists(_tokenId), "NFT does not exist");
        increaseReputation(_tokenId, 10); // Example bonus amount
    }

    /**
     * @dev (Admin/Governance) Enables a specific feature for dNFTs with a minimum reputation.
     * @param _featureId The ID of the feature to enable.
     * @param _minReputation The minimum reputation required to access the feature.
     */
    function enableFeatureForReputation(uint256 _featureId, uint256 _minReputation) public onlyOwner whenNotPaused { // Consider making this governance controlled
        _featureMinReputation[_featureId] = _minReputation;
        emit FeatureEnabledByReputation(_featureId, _minReputation);
    }

    /**
     * @dev Checks if a specific feature is enabled for a dNFT based on its reputation.
     * @param _tokenId The ID of the NFT.
     * @param _featureId The ID of the feature to check.
     * @return True if the feature is enabled, false otherwise.
     */
    function isFeatureEnabled(uint256 _tokenId, uint256 _featureId) public view returns (bool) {
        require(_exists(_tokenId), "NFT does not exist");
        return _nftReputation[_tokenId] >= _featureMinReputation[_featureId];
    }

    /**
     * @dev (Admin) Registers a new interaction type with a unique ID.
     * @param _interactionName The name of the interaction type.
     * @param _interactionId The unique ID for the interaction type.
     */
    function registerInteractionType(string memory _interactionName, uint8 _interactionId) public onlyOwner whenNotPaused {
        require(_interactionTypes[_interactionId].length == 0, "Interaction ID already exists");
        _interactionTypes[_interactionId] = _interactionName;
    }

    /**
     * @dev Retrieves the name of an interaction type.
     * @param _interactionId The ID of the interaction type.
     * @return The name of the interaction type.
     */
    function getInteractionName(uint8 _interactionId) public view returns (string memory) {
        return _interactionTypes[_interactionId];
    }

    /**
     * @dev (Admin) Sets rules for how interactions affect NFT traits.
     * @param _interactionType The type of interaction.
     * @param _traitId The ID of the trait to be affected.
     * @param _evolutionValue The value by which the trait should evolve (positive or negative).
     */
    function setTraitEvolutionRule(uint8 _interactionType, uint8 _traitId, int8 _evolutionValue) public onlyOwner whenNotPaused {
        _setTraitEvolutionRule(_interactionType, _traitId, _evolutionValue);
    }

    function _setTraitEvolutionRule(uint8 _interactionType, uint8 _traitId, int8 _evolutionValue) private {
        _traitEvolutionRules[_interactionType][_traitId] = _evolutionValue;
    }

    /**
     * @dev Retrieves the evolution rule for a specific interaction and trait.
     * @param _interactionType The type of interaction.
     * @param _traitId The ID of the trait.
     * @return The evolution value.
     */
    function getTraitEvolutionRule(uint8 _interactionType, uint8 _traitId) public view returns (int8) {
        return _traitEvolutionRules[_interactionType][_traitId];
    }

    /**
     * @dev (Admin) Pauses core contract functionalities.
     */
    function pauseContract() public onlyOwner {
        paused = true;
        _pause();
    }

    /**
     * @dev (Admin) Resumes contract functionalities.
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        _unpause();
    }

    /**
     * @dev (Admin) Sets the address of the governance contract.
     * @param _governanceContract The address of the governance contract.
     */
    function setGovernanceContract(address _governanceContract) public onlyOwner {
        governanceContract = _governanceContract;
    }

    /**
     * @dev (Admin) Retrieves the address of the governance contract.
     * @return The address of the governance contract.
     */
    function getGovernanceContract() public view returns (address) {
        return governanceContract;
    }

    /**
     * @dev (Admin) Allows admin to withdraw accumulated contract fees (placeholder for future fee mechanisms).
     */
    function withdrawFees() public onlyOwner {
        // Placeholder for future fee withdrawal mechanism
        // For example, if some functions charge a fee, the contract could accumulate ETH/tokens
        // and this function allows the owner to withdraw them.
        // For now, it's empty as there are no fee mechanisms implemented.
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to evolve NFT traits based on interaction type.
     * @param _tokenId The ID of the NFT.
     * @param _interactionType The type of interaction.
     */
    function _evolveTraits(uint256 _tokenId, uint8 _interactionType) internal {
        uint256 currentTraits = _nftTraits[_tokenId];
        uint256 newTraits = currentTraits;

        // Example: Evolve based on predefined rules
        for (uint8 traitId = 0; traitId < 4; traitId++) { // Iterate through example traits (0-3)
            int8 evolutionValue = _traitEvolutionRules[_interactionType][traitId];
            if (evolutionValue != 0) {
                // Example: Simple trait modification (can be more sophisticated based on trait type)
                if (traitId == TRAIT_POWER) {
                    newTraits = _adjustTrait(newTraits, TRAIT_POWER, evolutionValue);
                } else if (traitId == TRAIT_AGILITY) {
                    newTraits = _adjustTrait(newTraits, TRAIT_AGILITY, evolutionValue);
                } else if (traitId == TRAIT_LUCK) {
                    newTraits = _adjustTrait(newTraits, TRAIT_LUCK, evolutionValue);
                } else if (traitId == TRAIT_TYPE) {
                    // Example: Trait type could evolve under specific conditions (more complex logic)
                    // For simplicity, we're not evolving type in this example.
                }
            }
        }

        _nftTraits[_tokenId] = newTraits; // Update traits
        emit NFTEvolved(_tokenId, newTraits);
    }

    /**
     * @dev Internal function to adjust a specific trait in the traits bitmask.
     *      This is a simplified example. For complex traits, consider using structs instead of bitmasks.
     * @param _currentTraits The current traits bitmask.
     * @param _traitId The ID of the trait to adjust.
     * @param _adjustment The value to adjust the trait by.
     * @return The updated traits bitmask.
     */
    function _adjustTrait(uint256 _currentTraits, uint8 _traitId, int8 _adjustment) internal pure returns (uint256) {
        // Example: Simple increment/decrement of a trait value within a uint256
        // This assumes traits are represented in a simple way within the uint256.
        // For a real-world scenario, you might use structs to represent traits more robustly.
        uint256 mask = 255 << (_traitId * 8); // Example: 8 bits per trait (adjust as needed)
        uint256 currentValue = (_currentTraits & mask) >> (_traitId * 8);
        int256 newValue = int256(currentValue) + _adjustment;

        // Clamp trait value to a reasonable range (0-255 in this example)
        if (newValue < 0) newValue = 0;
        if (newValue > 255) newValue = 255;

        uint256 clearedTraits = _currentTraits & ~mask; // Clear existing trait bits
        uint256 newTraitBits = uint256(uint8(newValue)) << (_traitId * 8); // Shift new value into position
        return clearedTraits | newTraitBits; // Combine cleared traits with new trait value
    }


    /**
     * @dev Internal function to get default traits when minting a new NFT.
     * @return Default traits as a uint256 (or struct).
     */
    function _getDefaultTraits() internal pure returns (uint256) {
        // Example: Set default traits for new NFTs (can be customized)
        uint256 defaultTraits = 0;
        // Initialize TRAIT_TYPE, TRAIT_POWER, TRAIT_AGILITY, TRAIT_LUCK to default values (e.g., all 0)
        return defaultTraits;
    }

    // --- ERC721 Overrides (for clarity and potential extensions) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic before token transfer if needed (e.g., trait resets on transfer?)
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        // Add any custom logic after token transfer if needed
    }

    function approve(address spender, uint256 tokenId) public override whenNotPaused {
        address owner = ERC721.ownerOf(tokenId);
        require(spender != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
        delete _tokenApprovals[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        delete _tokenApprovals[tokenId];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}
```