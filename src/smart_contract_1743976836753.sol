```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating Dynamic NFTs that can evolve based on various on-chain and off-chain conditions.
 *
 * Function Outline:
 *
 * **Core NFT Functions:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to a specified address.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * 3. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for a given NFT.
 * 4. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 * 5. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 * 6. `approve(address _approved, uint256 _tokenId)`: Approves an address to spend a specific NFT.
 * 7. `getApproved(uint256 _tokenId)`: Gets the approved address for a specific NFT.
 * 8. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for all NFTs for an operator.
 * 9. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 * 10. `totalSupply()`: Returns the total number of NFTs minted.
 *
 * **Dynamic Evolution Functions:**
 * 11. `checkEvolutionConditions(uint256 _tokenId)`: Checks if an NFT meets the conditions for evolution.
 * 12. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for an NFT (if conditions are met).
 * 13. `setEvolutionConditions(uint256 _tokenId, EvolutionCondition[] memory _conditions)`: Allows the owner to set custom evolution conditions for an NFT.
 * 14. `getEvolutionConditions(uint256 _tokenId)`: Retrieves the currently set evolution conditions for an NFT.
 * 15. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 16. `getEvolutionHistory(uint256 _tokenId)`: Retrieves the history of evolution stages for an NFT.
 * 17. `setBaseMetadataURI(uint256 _stage, string memory _baseURI)`: Sets the base metadata URI for a specific evolution stage.
 * 18. `getExternalConditionData(uint256 _tokenId, uint256 _conditionIndex)`: Allows an NFT owner to manually input external condition data (for specific condition types).
 *
 * **Utility & Configuration Functions:**
 * 19. `pauseContract()`: Pauses the contract functionalities (except for viewing functions).
 * 20. `unpauseContract()`: Resumes the contract functionalities.
 * 21. `setContractURI(string memory _contractURI)`: Sets the contract-level metadata URI.
 * 22. `getContractURI()`: Retrieves the contract-level metadata URI.
 * 23. `withdraw()`: Allows the contract owner to withdraw any accumulated Ether.
 * 24. `supportsInterface(bytes4 interfaceId)`:  (Standard ERC721 interface support check)
 *
 * Function Summary:
 * This smart contract implements a dynamic NFT system where NFTs can evolve through different stages based on customizable on-chain and potentially off-chain conditions.
 * It provides standard ERC721 NFT functionalities along with advanced features for defining evolution conditions, managing evolution stages, and dynamically updating NFT metadata based on these evolutions.
 * The contract allows for manual input of external condition data, providing flexibility for integrating with off-chain events or oracles (though oracle integration itself is not directly implemented in this basic version).
 * It includes utility functions for contract management like pausing, setting contract metadata, and owner withdrawal.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTEvolution is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    enum ConditionType {
        TIME_ELAPSED,
        TOKEN_BALANCE,
        CONTRACT_INTERACTION,
        EXTERNAL_DATA // For conditions that require external data (e.g., oracle)
    }

    struct EvolutionCondition {
        ConditionType conditionType;
        uint256 thresholdValue; // For numerical conditions (time, balance, etc.)
        uint256 timestamp;      // For TIME_ELAPSED conditions, track start time
        bytes32 externalDataHash; // Placeholder for external data hash (or other relevant data)
        bool conditionMet;      // Flag to indicate if the condition is met
    }

    struct NFTData {
        uint256 currentStage;
        EvolutionCondition[][] evolutionConditions; // Array of evolution stages, each stage has an array of conditions
        string[] evolutionHistory; // Store base URIs for each stage
        string baseURI; // Initial base URI
    }

    mapping(uint256 => NFTData) private _nftData;
    mapping(uint256 => string) private _baseMetadataURIs; // Stage -> Base URI
    string public contractURI;
    bool public paused;

    // --- Events ---
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTEvolved(uint256 indexed tokenId, uint256 newStage, string newMetadataURI);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event EvolutionConditionsSet(uint256 indexed tokenId);
    event ExternalConditionDataInput(uint256 indexed tokenId, uint256 conditionIndex);
    event BaseMetadataURISet(uint256 stage, string baseURI);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("DynamicEvolutionNFT", "DENFT") {
        // Initialize contract, if needed
        paused = false;
    }

    // --- Core NFT Functions ---

    /**
     * @dev Mints a new Dynamic NFT to a specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The initial base metadata URI for the NFT.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);

        _nftData[tokenId] = NFTData({
            currentStage: 1,
            evolutionConditions: new EvolutionCondition[][](0), // Initially no evolution stages defined
            evolutionHistory: new string[](1),
            baseURI: _baseURI
        });
        _nftData[tokenId].evolutionHistory[0] = _baseURI; // Store initial base URI as first stage

        emit NFTMinted(_to, tokenId);
        return tokenId;
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev @inheritdoc ERC721
     * @param tokenId The token ID for which to retrieve the URI.
     * @return The metadata URI for the given token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory currentBaseURI = _nftData[tokenId].evolutionHistory[_nftData[tokenId].currentStage - 1];
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")); // Example: baseURI/tokenId.json
    }


    /**
     * @dev Retrieves the current metadata URI for a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /**
     * @dev Returns the owner of a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return super.ownerOf(_tokenId);
    }

    /**
     * @dev Returns the number of NFTs owned by an address.
     * @param _owner The address to check the balance of.
     * @return The number of NFTs owned by the address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return super.balanceOf(_owner);
    }

    /**
     * @dev Approves an address to spend a specific NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT to approve spending for.
     */
    function approve(address _approved, uint256 _tokenId) public whenNotPaused override {
        super.approve(_approved, _tokenId);
    }

    /**
     * @dev Gets the approved address for a specific NFT.
     * @param _tokenId The ID of the NFT to get the approved address for.
     * @return The approved address.
     */
    function getApproved(uint256 _tokenId) public view override returns (address) {
        return super.getApproved(_tokenId);
    }

    /**
     * @dev Enables or disables approval for all NFTs for an operator.
     * @param _operator The address to set as an operator.
     * @param _approved True if the operator is approved, false otherwise.
     */
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused override {
        super.setApprovalForAll(_operator, _approved);
    }

    /**
     * @dev Checks if an operator is approved for all NFTs of an owner.
     * @param _owner The owner of the NFTs.
     * @param _operator The operator to check for approval.
     * @return True if the operator is approved for all NFTs of the owner, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns the total number of NFTs minted.
     * @return The total supply of NFTs.
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Dynamic Evolution Functions ---

    /**
     * @dev Checks if an NFT meets the conditions for evolution to the next stage.
     * @param _tokenId The ID of the NFT to check evolution conditions for.
     * @return True if conditions are met, false otherwise.
     */
    function checkEvolutionConditions(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist");
        NFTData storage nft = _nftData[_tokenId];
        uint256 nextStage = nft.currentStage + 1;

        if (nextStage > nft.evolutionConditions.length) {
            return false; // No more evolution stages defined
        }

        EvolutionCondition[] storage conditions = nft.evolutionConditions[nextStage - 1]; // Access conditions for the *next* stage

        if (conditions.length == 0) {
            return false; // No conditions set for this stage, cannot evolve
        }

        for (uint256 i = 0; i < conditions.length; i++) {
            if (!conditions[i].conditionMet) { // If any condition is not met, evolution is blocked
                return false;
            }
        }

        return true; // All conditions for the next stage are met
    }


    /**
     * @dev Triggers the evolution process for an NFT, advancing it to the next stage if conditions are met.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        NFTData storage nft = _nftData[_tokenId];

        require(checkEvolutionConditions(_tokenId), "Evolution conditions not met");

        uint256 nextStage = nft.currentStage + 1;
        require(nextStage <= nft.evolutionConditions.length, "No further evolution stages defined"); // Ensure stage exists

        nft.currentStage = nextStage;
        string memory newBaseURI = _baseMetadataURIs[nextStage];
        require(bytes(newBaseURI).length > 0, "Base URI for next stage not set");

        nft.evolutionHistory.push(newBaseURI); // Add new base URI to history

        emit NFTEvolved(_tokenId, nextStage, tokenURI(_tokenId));
    }


    /**
     * @dev Allows the owner to set custom evolution conditions for an NFT.
     * Can only set conditions for stages that are defined (stage number must be within defined stage range).
     * @param _tokenId The ID of the NFT to set evolution conditions for.
     * @param _conditions An array of EvolutionCondition structs defining the conditions for the next evolution stage.
     *                   Conditions are ANDed together - all must be met for evolution.
     *
     * Example of setting conditions for Stage 2:
     * `setEvolutionConditions(tokenId, [
     *    EvolutionCondition(ConditionType.TIME_ELAPSED, 86400, block.timestamp, bytes32(0), false), // 1 day elapsed
     *    EvolutionCondition(ConditionType.TOKEN_BALANCE, 10, 0, bytes32(0), false) // Owner has 10 tokens of some other token (not implemented here)
     * ]);`
     */
    function setEvolutionConditions(uint256 _tokenId, EvolutionCondition[] memory _conditions) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "Not token owner");

        NFTData storage nft = _nftData[_tokenId];
        uint256 nextStage = nft.currentStage + 1; // Set conditions for the *next* stage

        // Ensure we are setting conditions for a valid stage (within the defined evolution path)
        if (nft.evolutionConditions.length < nextStage) {
            nft.evolutionConditions.push(_conditions); // Add new stage's conditions
        } else {
            nft.evolutionConditions[nextStage - 1] = _conditions; // Overwrite conditions for existing stage (if needed, for flexibility)
        }

        // Initialize timestamps for TIME_ELAPSED conditions if present
        for (uint256 i = 0; i < _conditions.length; i++) {
            if (_conditions[i].conditionType == ConditionType.TIME_ELAPSED) {
                nft.evolutionConditions[nextStage - 1][i].timestamp = block.timestamp; // Set current timestamp as start time
            }
        }

        emit EvolutionConditionsSet(_tokenId);
    }


    /**
     * @dev Retrieves the currently set evolution conditions for a specific NFT and stage.
     * @param _tokenId The ID of the NFT.
     * @return An array of EvolutionCondition structs for the current evolution stage.
     */
    function getEvolutionConditions(uint256 _tokenId) public view returns (EvolutionCondition[] memory) {
        require(_exists(_tokenId), "Token does not exist");
        NFTData storage nft = _nftData[_tokenId];
        uint256 nextStage = nft.currentStage + 1; // Get conditions for the *next* stage

        if (nextStage > nft.evolutionConditions.length || nft.evolutionConditions.length == 0 ) {
             return new EvolutionCondition[](0); // Return empty array if no conditions defined for next stage or no stages at all
        }
        return nft.evolutionConditions[nextStage - 1];
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage (starting from 1).
     */
    function getNFTStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return _nftData[_tokenId].currentStage;
    }

    /**
     * @dev Retrieves the history of evolution stages for an NFT (as base metadata URIs).
     * @param _tokenId The ID of the NFT.
     * @return An array of base metadata URI strings representing the evolution history.
     */
    function getEvolutionHistory(uint256 _tokenId) public view returns (string[] memory) {
        require(_exists(_tokenId), "Token does not exist");
        return _nftData[_tokenId].evolutionHistory;
    }

    /**
     * @dev Sets the base metadata URI for a specific evolution stage.
     * @param _stage The evolution stage number (starting from 1).
     * @param _baseURI The base metadata URI for this stage.
     */
    function setBaseMetadataURI(uint256 _stage, string memory _baseURI) public onlyOwner whenNotPaused {
        require(_stage > 0, "Stage must be greater than 0");
        _baseMetadataURIs[_stage] = _baseURI;
        emit BaseMetadataURISet(_stage, _baseURI);
    }

    /**
     * @dev Allows an NFT owner to manually input external condition data for a specific condition.
     * This is a simplified way to handle external data for demo purposes. In a real-world scenario,
     * an oracle would be used to automatically update this data based on external events.
     *
     * @param _tokenId The ID of the NFT.
     * @param _conditionIndex The index of the condition within the current stage's conditions array.
     * @param _dataHash The external data hash or relevant data to fulfill the condition.
     */
    function getExternalConditionData(uint256 _tokenId, uint256 _conditionIndex) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "Not token owner");

        NFTData storage nft = _nftData[_tokenId];
        uint256 nextStage = nft.currentStage + 1;

        require(nextStage <= nft.evolutionConditions.length, "No evolution conditions defined for next stage");
        require(_conditionIndex < nft.evolutionConditions[nextStage - 1].length, "Invalid condition index");

        EvolutionCondition storage condition = nft.evolutionConditions[nextStage - 1][_conditionIndex];

        require(condition.conditionType == ConditionType.EXTERNAL_DATA, "Condition is not of type EXTERNAL_DATA");

        // In a real application, you would verify the external data using an oracle or some other mechanism.
        // For this example, we simply mark the condition as met.
        condition.conditionMet = true;
        emit ExternalConditionDataInput(_tokenId, _conditionIndex);

        // After setting external data, re-evaluate evolution conditions automatically
        if (checkEvolutionConditions(_tokenId)) {
            // Optionally, auto-evolve if all conditions are now met immediately after external data input
            // evolveNFT(_tokenId); // Uncomment to enable auto-evolution on external data input
        }
    }


    // --- Utility & Configuration Functions ---

    /**
     * @dev Pauses the contract, preventing most functions from being executed.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing functions to be executed again.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Sets the contract-level metadata URI.
     * @param _contractURI The URI for the contract metadata.
     */
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    /**
     * @dev Retrieves the contract-level metadata URI.
     * @return The contract metadata URI string.
     */
    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether in the contract.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Functions (if any needed, for example, for more complex condition checks) ---
    // For more complex condition checks, you might create internal functions here,
    // especially if they need to access private state variables or perform more intricate logic.
    // Example:
    // function _checkTokenBalanceCondition(uint256 _tokenId, EvolutionCondition memory _condition) internal view returns (bool) { ... }
}
```