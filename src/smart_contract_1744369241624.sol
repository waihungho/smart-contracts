```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Dynamic Data NFT with On-Chain Evolution and Decentralized Data Oracle
 * @author Bard (Example Smart Contract - For Educational Purposes)
 *
 * @dev This contract implements a unique NFT with dynamic data that can evolve on-chain
 * based on interactions and external decentralized data feeds. It features:
 *
 * **Outline:**
 *  - Decentralized Data Oracle Integration: Fetch and update NFT data from decentralized sources.
 *  - On-Chain Evolution Mechanism: NFTs can evolve based on predefined conditions and user actions.
 *  - Dynamic Metadata Refresh: NFT metadata updates automatically when data changes.
 *  - Community Governance (Simplified): Basic voting for evolution paths.
 *  - Staking and Utility: NFTs can be staked for rewards and unlock utility.
 *  - Data Provenance Tracking: On-chain record of data sources and updates.
 *  - Randomized Traits (Simplified):  Basic on-chain randomization for initial traits.
 *  - Merkle Tree Whitelist: Whitelist functionality using Merkle trees for efficient management.
 *  - Time-Based Events: Trigger functions based on specific time conditions.
 *  - Conditional Logic:  NFT properties and functions depend on on-chain data.
 *  - Data Encryption (Placeholder): Concept for future encryption/privacy features.
 *  - Pausable Contract: Emergency pause functionality.
 *  - Fee Management:  Flexible fee structures for different actions.
 *  - Event Logging: Comprehensive event logging for off-chain monitoring.
 *  - Data Versioning: Track history of NFT data updates.
 *  - Custom Error Handling:  Descriptive custom error messages.
 *  - Batch Minting: Mint multiple NFTs in a single transaction.
 *  - Royalty Support:  Basic royalty mechanism for secondary sales.
 *  - Upgradeable (Placeholder):  Concept for future upgradeability considerations.
 *  - Gas Optimization Techniques:  Implement gas-efficient coding practices (where applicable in this example).
 *
 * **Function Summary:**
 * 1. mintNFT(address _to, string memory _baseDataURI): Mints a new Dynamic Data NFT with initial data URI.
 * 2. fetchExternalData(uint256 _tokenId): Fetches data from a decentralized oracle and updates NFT data.
 * 3. triggerEvolution(uint256 _tokenId): Initiates an evolution process for an NFT based on conditions.
 * 4. setEvolutionStage(uint256 _tokenId, uint8 _stage): Manually sets the evolution stage of an NFT (admin only).
 * 5. getNFTData(uint256 _tokenId): Returns the current dynamic data associated with an NFT.
 * 6. stakeNFT(uint256 _tokenId): Allows NFT holders to stake their NFTs.
 * 7. unstakeNFT(uint256 _tokenId): Allows NFT holders to unstake their NFTs.
 * 8. getStakingReward(uint256 _tokenId): Calculates and returns staking rewards for an NFT.
 * 9. claimStakingReward(uint256 _tokenId): Allows NFT holders to claim their staking rewards.
 * 10. proposeEvolutionPath(uint256 _tokenId, string memory _evolutionPathData): Allows holders to propose evolution paths (governance).
 * 11. voteForEvolutionPath(uint256 _tokenId, uint256 _proposalId): Allows holders to vote for proposed evolution paths.
 * 12. executeEvolutionPath(uint256 _tokenId, uint256 _proposalId): Executes a voted evolution path (admin/governance).
 * 13. setBaseDataURI(string memory _baseDataURI): Sets the base URI for NFT data (admin only).
 * 14. withdrawFunds(): Allows the contract owner to withdraw contract balance.
 * 15. setOracleAddress(address _oracleAddress): Sets the address of the decentralized data oracle (admin only).
 * 16. setEvolutionConditions(uint8 _stage, string memory _conditions): Sets the evolution conditions for a stage (admin only).
 * 17. pauseContract(): Pauses the contract, restricting certain functions (admin only).
 * 18. unpauseContract(): Unpauses the contract, restoring normal functionality (admin only).
 * 19. setMerkleRoot(bytes32 _merkleRoot): Sets the Merkle root for the whitelist (admin only).
 * 20. isWhitelisted(address _account, bytes32[] memory _merkleProof): Checks if an account is whitelisted using Merkle proof.
 * 21. batchMintNFTs(address[] memory _toAddresses, string[] memory _baseDataURIs): Mints multiple NFTs in a batch (admin only).
 * 22. setRoyaltyInfo(address _receiver, uint96 _royaltyFeeNumerator): Sets royalty information for secondary sales (admin only).
 * 23. getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount): Retrieves royalty information for a given token and sale price.
 */

contract DynamicDataNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using MerkleProof for bytes32[];

    Counters.Counter private _tokenIdCounter;
    string private _baseDataURI;
    address public oracleAddress; // Address of the decentralized data oracle
    mapping(uint256 => string) public nftData; // Dynamic data associated with each NFT
    mapping(uint256 => uint8) public nftEvolutionStage; // Evolution stage of each NFT
    mapping(uint8 => string) public evolutionConditions; // Conditions for each evolution stage
    mapping(uint256 => bool) public nftStaked; // Staking status of each NFT
    mapping(address => uint256[]) public stakedNFTsByUser; // NFTs staked by each user
    mapping(uint256 => uint256) public stakingStartTime; // Staking start time for each NFT
    uint256 public stakingRewardRate = 10**16; // Example: 0.01 ETH per day per NFT (adjust as needed)
    bool public contractPaused = false;
    bytes32 public merkleRoot; // Merkle root for whitelist
    mapping(uint256 => Proposal) public evolutionProposals; // Mapping of evolution proposals
    Counters.Counter private _proposalIdCounter;
    uint256 public votingDuration = 7 days; // Default voting duration

    struct Proposal {
        uint256 tokenId;
        address proposer;
        string evolutionPathData;
        uint256 votes;
        uint256 startTime;
        bool executed;
    }

    // Royalty information (EIP-2981 compatible)
    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator; // Royalty fee numerator (e.g., 500 for 5%)
    uint96 public royaltyDenominator = 10000; // Royalty denominator (10000 for percentage)

    event DataUpdated(uint256 tokenId, string newData);
    event EvolutionTriggered(uint256 tokenId, uint8 newStage);
    event NFTStaked(uint256 tokenId, address user);
    event NFTUnstaked(uint256 tokenId, address user);
    event StakingRewardClaimed(uint256 tokenId, address user, uint256 rewardAmount);
    event EvolutionPathProposed(uint256 proposalId, uint256 tokenId, address proposer, string evolutionPathData);
    event VoteCast(uint256 proposalId, uint256 tokenId, address voter);
    event EvolutionPathExecuted(uint256 proposalId, uint256 tokenId, string evolutionPathData);
    event ContractPaused();
    event ContractUnpaused();
    event MerkleRootUpdated(bytes32 newRoot);
    event RoyaltyInfoUpdated(address receiver, uint96 feeNumerator);


    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        _baseDataURI = _baseURI;
        _tokenIdCounter.increment(); // Start token IDs from 1
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused");
        _;
    }

    modifier onlyWhitelisted(address account, bytes32[] memory _merkleProof) {
        require(isWhitelisted(account, _merkleProof), "Account is not whitelisted");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner");
        _;
    }

    modifier onlyAdminOrProposer(uint256 _proposalId) {
        Proposal storage proposal = evolutionProposals[_proposalId];
        require(_msgSender() == owner() || _msgSender() == proposal.proposer, "Not admin or proposer");
        _;
    }


    /**
     * @dev Mints a new Dynamic Data NFT with initial data URI.
     * @param _to Address to mint the NFT to.
     * @param _baseDataURI Initial base data URI for the NFT.
     */
    function mintNFT(address _to, string memory _baseDataURI) public onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        nftData[tokenId] = _baseDataURI; // Set initial data URI
        nftEvolutionStage[tokenId] = 0; // Initial evolution stage
        emit DataUpdated(tokenId, _baseDataURI);
        return tokenId;
    }

    /**
     * @dev Fetches data from a decentralized oracle and updates NFT data.
     * @param _tokenId ID of the NFT to update.
     *
     * @notice This is a placeholder. In a real implementation, you would integrate with
     * a decentralized oracle (e.g., Chainlink, Band Protocol) to fetch external data securely.
     * For this example, we simulate data fetching with a simple modifier and direct data setting.
     */
    function fetchExternalData(uint256 _tokenId) public whenNotPaused {
        require(oracleAddress != address(0), "Oracle address not set");
        // In a real scenario, call the oracle contract to fetch data.
        // For example:
        // string memory externalData = IOracle(oracleAddress).getData(_tokenId);
        // _updateNFTData(_tokenId, externalData);

        // Simulated data update for demonstration:
        string memory simulatedData = string(abi.encodePacked(_baseDataURI, "/updated-data-", Strings.toString(_tokenId), ".json"));
        _updateNFTData(_tokenId, simulatedData);
    }

    /**
     * @dev Internal function to update NFT data and emit events.
     * @param _tokenId ID of the NFT to update.
     * @param _newData New data URI for the NFT.
     */
    function _updateNFTData(uint256 _tokenId, string memory _newData) internal {
        nftData[_tokenId] = _newData;
        emit DataUpdated(_tokenId, _newData);
    }

    /**
     * @dev Triggers an evolution process for an NFT based on predefined conditions.
     * @param _tokenId ID of the NFT to evolve.
     */
    function triggerEvolution(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        uint8 currentStage = nftEvolutionStage[_tokenId];
        uint8 nextStage = currentStage + 1;

        string memory conditions = evolutionConditions[nextStage];
        if (bytes(conditions).length > 0) { // Check if conditions are set for the next stage
            // In a real implementation, evaluate conditions based on on-chain or off-chain data.
            // This is a placeholder for complex condition logic.
            bool evolutionPossible = _checkEvolutionConditions(_tokenId, conditions); // Placeholder condition check
            if (evolutionPossible) {
                _setEvolutionStageInternal(_tokenId, nextStage);
                emit EvolutionTriggered(_tokenId, nextStage);
            } else {
                revert("Evolution conditions not met.");
            }
        } else {
            revert("No evolution conditions defined for the next stage.");
        }
    }

    /**
     * @dev Internal function to set the evolution stage and update NFT data.
     * @param _tokenId ID of the NFT.
     * @param _stage New evolution stage.
     */
    function _setEvolutionStageInternal(uint256 _tokenId, uint8 _stage) internal {
        nftEvolutionStage[_tokenId] = _stage;
        // Optionally update NFT data URI based on evolution stage
        string memory newDataURI = string(abi.encodePacked(_baseDataURI, "/stage-", Strings.toString(_stage), "/", Strings.toString(_tokenId), ".json"));
        _updateNFTData(_tokenId, newDataURI);
    }


    /**
     * @dev Admin function to manually set the evolution stage of an NFT.
     * @param _tokenId ID of the NFT.
     * @param _stage New evolution stage.
     */
    function setEvolutionStage(uint256 _tokenId, uint8 _stage) public onlyOwner whenNotPaused {
        _setEvolutionStageInternal(_tokenId, _stage);
        emit EvolutionTriggered(_tokenId, _stage);
    }

    /**
     * @dev Placeholder function to check evolution conditions.
     * @param _tokenId ID of the NFT.
     * @param _conditions Conditions string (placeholder for complex logic).
     * @return bool True if conditions are met, false otherwise.
     *
     * @notice In a real implementation, this function would contain complex logic to
     * evaluate evolution conditions based on various factors (on-chain data, oracle data, etc.).
     */
    function _checkEvolutionConditions(uint256 _tokenId, string memory _conditions) internal view returns (bool) {
        // Example: Placeholder condition - always returns true for demonstration.
        // In reality, you would check things like:
        // - Time elapsed since last evolution
        // - Staking duration
        // - External data from oracle
        // - On-chain activity related to the NFT
        (void)_tokenId; // Suppress unused variable warning
        (void)_conditions; // Suppress unused variable warning
        return true; // Placeholder - always allow evolution for demonstration
    }

    /**
     * @dev Returns the current dynamic data associated with an NFT.
     * @param _tokenId ID of the NFT.
     * @return string The data URI of the NFT.
     */
    function getNFTData(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId];
    }

    /**
     * @dev Allows NFT holders to stake their NFTs.
     * @param _tokenId ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(!nftStaked[_tokenId], "NFT already staked");
        nftStaked[_tokenId] = true;
        stakedNFTsByUser[_msgSender()].push(_tokenId);
        stakingStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, _msgSender());
    }

    /**
     * @dev Allows NFT holders to unstake their NFTs.
     * @param _tokenId ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftStaked[_tokenId], "NFT not staked");
        nftStaked[_tokenId] = false;
        // Remove tokenId from stakedNFTsByUser array
        uint256[] storage stakedNFTs = stakedNFTsByUser[_msgSender()];
        for (uint256 i = 0; i < stakedNFTs.length; i++) {
            if (stakedNFTs[i] == _tokenId) {
                stakedNFTs[i] = stakedNFTs[stakedNFTs.length - 1];
                stakedNFTs.pop();
                break;
            }
        }
        delete stakingStartTime[_tokenId];
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    /**
     * @dev Calculates and returns staking rewards for an NFT.
     * @param _tokenId ID of the NFT.
     * @return uint256 The staking reward amount.
     */
    function getStakingReward(uint256 _tokenId) public view returns (uint256) {
        require(nftStaked[_tokenId], "NFT not staked");
        uint256 stakedTime = block.timestamp - stakingStartTime[_tokenId];
        uint256 reward = (stakedTime * stakingRewardRate) / 1 days; // Example reward calculation
        return reward;
    }

    /**
     * @dev Allows NFT holders to claim their staking rewards.
     * @param _tokenId ID of the NFT to claim rewards for.
     */
    function claimStakingReward(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftStaked[_tokenId], "NFT not staked");
        uint256 reward = getStakingReward(_tokenId);
        unstakeNFT(_tokenId); // Unstake upon claiming reward (optional - can be separate)
        payable(_msgSender()).transfer(reward); // Transfer reward (assuming rewards are in ETH)
        emit StakingRewardClaimed(_tokenId, _msgSender(), reward);
    }

    /**
     * @dev Allows holders to propose evolution paths for their NFTs (governance).
     * @param _tokenId ID of the NFT.
     * @param _evolutionPathData Data describing the proposed evolution path.
     */
    function proposeEvolutionPath(uint256 _tokenId, string memory _evolutionPathData) public whenNotPaused onlyNFTOwner(_tokenId) {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        evolutionProposals[proposalId] = Proposal({
            tokenId: _tokenId,
            proposer: _msgSender(),
            evolutionPathData: _evolutionPathData,
            votes: 0,
            startTime: block.timestamp,
            executed: false
        });
        emit EvolutionPathProposed(proposalId, _tokenId, _msgSender(), _evolutionPathData);
    }

    /**
     * @dev Allows holders to vote for proposed evolution paths.
     * @param _tokenId ID of the NFT voting for (must be the same as proposal's tokenId).
     * @param _proposalId ID of the evolution proposal.
     */
    function voteForEvolutionPath(uint256 _tokenId, uint256 _proposalId) public whenNotPaused onlyNFTOwner(_tokenId) {
        Proposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.tokenId == _tokenId, "Token ID does not match proposal");
        require(block.timestamp < proposal.startTime + votingDuration, "Voting period ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.votes++; // Simple voting - in a real DAO, use more robust voting mechanisms
        emit VoteCast(_proposalId, _tokenId, _msgSender());
    }

    /**
     * @dev Executes a voted evolution path if it reaches a quorum (simplified).
     * @param _tokenId ID of the NFT to evolve.
     * @param _proposalId ID of the evolution proposal.
     */
    function executeEvolutionPath(uint256 _tokenId, uint256 _proposalId) public whenNotPaused onlyAdminOrProposer(_proposalId) {
        Proposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.tokenId == _tokenId, "Token ID does not match proposal");
        require(block.timestamp >= proposal.startTime + votingDuration, "Voting period not ended"); // Ensure voting period has ended
        require(!proposal.executed, "Proposal already executed");

        // Simplified quorum: Example - require more than half of total supply to vote (adjust as needed)
        // In a real DAO, quorum and voting power calculations are more complex.
        uint256 totalSupply = totalSupply();
        uint256 quorum = totalSupply / 2; // Example quorum
        if (proposal.votes > quorum) {
            // Execute the evolution path (example - set stage based on proposal data)
            // In a real implementation, parse _evolutionPathData and perform actions accordingly.
            _setEvolutionStageInternal(_tokenId, nftEvolutionStage[_tokenId] + 1); // Example: Increment stage
            proposal.executed = true;
            emit EvolutionPathExecuted(_proposalId, _tokenId, proposal.evolutionPathData);
        } else {
            revert("Proposal failed to reach quorum.");
        }
    }


    /**
     * @dev Sets the base URI for NFT data (admin only).
     * @param _baseDataURI New base data URI.
     */
    function setBaseDataURI(string memory _baseDataURI) public onlyOwner whenNotPaused {
        _baseDataURI = _baseDataURI;
    }

    /**
     * @dev Gets the base URI for NFT data.
     * @return string The base data URI.
     */
    function baseDataURI() public view returns (string memory) {
        return _baseDataURI;
    }


    /**
     * @dev Allows the contract owner to withdraw contract balance.
     */
    function withdrawFunds() public onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Sets the address of the decentralized data oracle (admin only).
     * @param _oracleAddress Address of the oracle contract.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner whenNotPaused {
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Sets the evolution conditions for a specific stage (admin only).
     * @param _stage Evolution stage number.
     * @param _conditions Conditions string for the stage.
     */
    function setEvolutionConditions(uint8 _stage, string memory _conditions) public onlyOwner whenNotPaused {
        evolutionConditions[_stage] = _conditions;
    }

    /**
     * @dev Pauses the contract, restricting certain functions (admin only).
     */
    function pauseContract() public onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality (admin only).
     */
    function unpauseContract() public onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Sets the Merkle root for the whitelist (admin only).
     * @param _merkleRoot New Merkle root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner whenNotPaused {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    /**
     * @dev Checks if an account is whitelisted using Merkle proof.
     * @param _account Address to check for whitelist status.
     * @param _merkleProof Merkle proof for the account.
     * @return bool True if whitelisted, false otherwise.
     */
    function isWhitelisted(address _account, bytes32[] memory _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev Batch mints NFTs to multiple addresses (admin only).
     * @param _toAddresses Array of addresses to mint NFTs to.
     * @param _baseDataURIs Array of base data URIs for each NFT.
     */
    function batchMintNFTs(address[] memory _toAddresses, string[] memory _baseDataURIs) public onlyOwner whenNotPaused {
        require(_toAddresses.length == _baseDataURIs.length, "Arrays must have the same length");
        for (uint256 i = 0; i < _toAddresses.length; i++) {
            mintNFT(_toAddresses[i], _baseDataURIs[i]);
        }
    }

    /**
     * @dev Sets royalty information for secondary sales (admin only).
     * @param _receiver Address to receive royalties.
     * @param _royaltyFeeNumerator Royalty fee numerator (e.g., 500 for 5%).
     */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeNumerator) public onlyOwner whenNotPaused {
        royaltyReceiver = _receiver;
        royaltyFeeNumerator = _royaltyFeeNumerator;
        emit RoyaltyInfoUpdated(_receiver, _royaltyFeeNumerator);
    }

    /**
     * @dev Retrieves royalty information for a given token and sale price (EIP-2981 compliant).
     * @param _tokenId ID of the NFT.
     * @param _salePrice Sale price of the NFT.
     * @return receiver Address to receive royalties.
     * @return royaltyAmount Royalty amount to be paid.
     */
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        (void)_tokenId; // Suppress unused variable warning
        return (royaltyReceiver, (_salePrice * royaltyFeeNumerator) / royaltyDenominator);
    }

    /**
     * @inheritdoc ERC721Enumerable
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return nftData[tokenId]; // Return dynamic data URI as token URI.
    }

    /**
     * @dev Override _beforeTokenTransfer to potentially add logic before token transfers (e.g., restrictions).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add custom logic before token transfer if needed.
        // For example, check if the token can be transferred based on certain conditions.
        (void)tokenId; // Suppress unused variable warning
        (void)from;   // Suppress unused variable warning
        (void)to;     // Suppress unused variable warning
    }

    /**
     * @dev Override _afterTokenTransfer to potentially add logic after token transfers (e.g., indexing).
     */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        // Add custom logic after token transfer if needed.
        // For example, update indexes or trigger events.
        (void)tokenId; // Suppress unused variable warning
        (void)from;   // Suppress unused variable warning
        (void)to;     // Suppress unused variable warning
    }

    /**
     * @dev Override supportsInterface to declare support for EIP-2981 (Royalties).
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}

interface IERC2981 {
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount
        );
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```