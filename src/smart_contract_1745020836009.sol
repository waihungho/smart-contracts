```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Decentralized Dynamic NFT Evolution & Utility Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT collection with evolving properties,
 *      advanced utility features, and decentralized governance elements.
 *
 * **Outline & Function Summary:**
 *
 * **Contract Overview:**
 * This contract creates a collection of Dynamic NFTs (DNFTs) that can evolve over time and based on user interactions.
 * It incorporates features like:
 *   - Layered Evolution: NFTs progress through multiple evolution stages, changing properties and appearance.
 *   - Utility Staking: Users can stake DNFTs to earn rewards or gain access to platform features.
 *   - On-Chain Randomness & Events: Random events can influence NFT evolution and rarity.
 *   - Decentralized Governance (Simple): Token holders can vote on certain contract parameters.
 *   - Dynamic Metadata: NFT metadata (URI) updates to reflect evolution and attributes.
 *   - Merkle Whitelist:  Allows for whitelisting users for minting or special features.
 *   - On-Chain Marketplace Integration (Placeholder): Hooks for future marketplace integration.
 *   - Community Treasury: Collects fees for platform development and community initiatives.
 *   - Upgradeable Logic (Placeholder - for future extensibility, not implemented in detail here).
 *
 * **Functions (20+):**
 *
 * **Core NFT Functions (ERC721 Base):**
 * 1. `mint(address _to)`: Mints a new base-level DNFT to the specified address. (Admin/Whitelist restricted)
 * 2. `tokenURI(uint256 tokenId)`: Returns the dynamic URI for the given tokenId, reflecting its current state.
 * 3. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function.
 * 4. `approve(address approved, uint256 tokenId)`: Standard ERC721 approve function.
 * 5. `getApproved(uint256 tokenId)`: Standard ERC721 getApproved function.
 * 6. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 setApprovalForAll function.
 * 7. `isApprovedForAll(address owner, address operator)`: Standard ERC721 isApprovedForAll function.
 * 8. `ownerOf(uint256 tokenId)`: Standard ERC721 ownerOf function.
 * 9. `balanceOf(address owner)`: Standard ERC721 balanceOf function.
 * 10. `totalSupply()`: Standard ERC721 totalSupply function.
 *
 * **Evolution & Attribute Functions:**
 * 11. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for a given DNFT if conditions are met.
 * 12. `getEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of a DNFT.
 * 13. `getNFTAttributes(uint256 _tokenId)`: Returns a struct containing the attributes of a DNFT based on its stage and randomness.
 * 14. `setEvolutionParameters(uint8 _stages, uint256 _baseEvolutionTime)`: Admin function to set global evolution parameters.
 *
 * **Utility & Staking Functions:**
 * 15. `stakeNFT(uint256 _tokenId)`: Allows users to stake their DNFT to earn platform utility tokens.
 * 16. `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their DNFT and claim earned utility tokens.
 * 17. `claimUtilityTokens(uint256 _tokenId)`: Allows users to manually claim accumulated utility tokens from staked NFTs.
 * 18. `getUtilityTokenBalance(address _owner)`:  Returns the utility token balance of an address (placeholder - utility token logic not fully implemented here).
 * 19. `setUtilityTokenRewardRate(uint256 _rate)`: Admin function to set the staking reward rate.
 *
 * **Governance & Community Functions:**
 * 20. `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Allows token holders to propose changes to contract parameters.
 * 21. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on active proposals.
 * 22. `executeProposal(uint256 _proposalId)`: Executes a successful proposal (based on voting threshold). (Admin/Governance controlled)
 * 23. `setGovernanceThreshold(uint256 _threshold)`: Admin function to set the voting threshold for proposals.
 *
 * **Admin & Utility Functions:**
 * 24. `setBaseURI(string memory _baseURI)`: Admin function to set the base URI for NFT metadata.
 * 25. `pauseContract()`: Admin function to pause core functionalities of the contract.
 * 26. `unpauseContract()`: Admin function to unpause the contract.
 * 27. `withdrawCommunityTreasury()`: Admin function to withdraw funds from the community treasury.
 * 28. `setMerkleRoot(bytes32 _merkleRoot)`: Admin function to set the Merkle root for whitelisting.
 * 29. `isWhitelisted(address _account, bytes32[] calldata _merkleProof)`: Checks if an address is whitelisted using Merkle proof.
 * 30. `getRandomNumber()`: Internal function to generate a pseudo-random number (for demonstration, consider Chainlink VRF in production).
 */
contract DynamicNFTCollection is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string private _baseURI;

    // --- Evolution Parameters ---
    uint8 public numEvolutionStages = 3; // Number of evolution stages (e.g., Stage 1, Stage 2, Stage 3)
    uint256 public baseEvolutionTime = 7 days; // Base time for each evolution stage

    // --- NFT State ---
    mapping(uint256 => uint8) public evolutionStage; // tokenId => evolution stage (starts at 1)
    mapping(uint256 => uint256) public lastEvolutionTime; // tokenId => last evolution timestamp
    mapping(uint256 => uint256) public nftRandomSeed; // tokenId => random seed generated at mint

    // --- Utility Staking ---
    mapping(uint256 => bool) public isStaked; // tokenId => is staked
    mapping(uint256 => uint256) public stakeStartTime; // tokenId => stake start timestamp
    uint256 public utilityTokenRewardRate = 1; // Utility tokens per day per staked NFT (placeholder)

    // --- Governance ---
    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public governanceThreshold = 50; // Percentage of votes needed to pass a proposal
    uint256 public proposalDuration = 7 days; // Duration for voting on proposals
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // --- Community Treasury ---
    address payable public communityTreasury;

    // --- Pausable Contract ---
    bool public paused = false;

    // --- Merkle Whitelist ---
    bytes32 public merkleRoot;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTEvolved(uint256 tokenId, uint8 newStage);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event UtilityTokensClaimed(uint256 tokenId, address owner, uint256 amount);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyWhitelisted(bytes32[] calldata _merkleProof) {
        require(isWhitelisted(msg.sender, _merkleProof), "Not whitelisted");
        _;
    }

    modifier onlyGovernance() {
        // Simple governance - for demonstration. In real-world, use more robust governance mechanisms.
        require(balanceOf(msg.sender) > 0, "Not enough tokens to govern"); // Example: Must hold at least 1 NFT to govern
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _uri, address payable _treasury) ERC721(_name, _symbol) {
        _baseURI = _uri;
        communityTreasury = _treasury;
    }

    // --- Core NFT Functions ---

    function mint(address _to, bytes32[] calldata _merkleProof) external onlyOwner onlyWhitelisted(_merkleProof) whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        evolutionStage[tokenId] = 1; // Start at stage 1
        lastEvolutionTime[tokenId] = block.timestamp;
        nftRandomSeed[tokenId] = getRandomNumber(); // Generate random seed at mint
        emit NFTMinted(tokenId, _to);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");
        string memory stageStr = Strings.toString(evolutionStage[tokenId]);
        string memory attributesStr = _getAttributeString(tokenId); // Get dynamic attributes string
        return string(abi.encodePacked(_baseURI, "/", stageStr, "/", tokenId.toString(), attributesStr, ".json")); // Example URI structure
    }

    function _getAttributeString(uint256 _tokenId) private view returns (string memory) {
        // This is a placeholder - in real-world, generate dynamic attributes based on stage, randomness, etc.
        // For now, just returning a simple identifier based on stage.
        uint8 stage = evolutionStage[_tokenId];
        return string(abi.encodePacked("_stage", Strings.toString(stage)));
    }

    // --- Evolution & Attribute Functions ---

    function evolveNFT(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(evolutionStage[_tokenId] < numEvolutionStages, "NFT is already at max stage");

        uint256 timeElapsed = block.timestamp - lastEvolutionTime[_tokenId];
        require(timeElapsed >= baseEvolutionTime, "Evolution time not reached yet");

        evolutionStage[_tokenId]++;
        lastEvolutionTime[_tokenId] = block.timestamp;
        nftRandomSeed[_tokenId] = getRandomNumber(); // Re-roll random seed upon evolution (optional)

        emit NFTEvolved(_tokenId, evolutionStage[_tokenId]);
    }

    function getEvolutionStage(uint256 _tokenId) external view returns (uint8) {
        require(_exists(_tokenId), "Token does not exist");
        return evolutionStage[_tokenId];
    }

    struct NFTAttributes {
        uint8 stage;
        uint256 seed;
        // Add more attributes based on your NFT design (e.g., rarity, power, speed)
    }

    function getNFTAttributes(uint256 _tokenId) external view returns (NFTAttributes memory) {
        require(_exists(_tokenId), "Token does not exist");
        return NFTAttributes({
            stage: evolutionStage[_tokenId],
            seed: nftRandomSeed[_tokenId]
            // Populate other attributes based on stage and seed here in real implementation
        });
    }

    function setEvolutionParameters(uint8 _stages, uint256 _baseEvolutionTime) external onlyOwner {
        numEvolutionStages = _stages;
        baseEvolutionTime = _baseEvolutionTime;
    }


    // --- Utility & Staking Functions ---

    function stakeNFT(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(!isStaked[_tokenId], "NFT is already staked");

        isStaked[_tokenId] = true;
        stakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(isStaked[_tokenId], "NFT is not staked");

        claimUtilityTokens(_tokenId); // Automatically claim tokens before unstaking
        isStaked[_tokenId] = false;
        delete stakeStartTime[_tokenId]; // Clean up stake start time
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    function claimUtilityTokens(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        require(isStaked[_tokenId], "NFT is not staked");

        uint256 timeStaked = block.timestamp - stakeStartTime[_tokenId];
        uint256 tokensEarned = (timeStaked / 1 days) * utilityTokenRewardRate; // Placeholder reward calculation

        // In a real implementation, you would mint/transfer a separate utility token here.
        // For this example, we'll just emit an event and assume a separate token contract exists.
        emit UtilityTokensClaimed(_tokenId, msg.sender, tokensEarned);
        // Consider updating user's utility token balance in a real scenario.
    }

    // Placeholder - In a real implementation, you would manage a separate utility token contract.
    function getUtilityTokenBalance(address _owner) external pure returns (uint256) {
        // Placeholder - Return 0 for now. In real-world, fetch from utility token contract.
        return 0;
    }

    function setUtilityTokenRewardRate(uint256 _rate) external onlyOwner {
        utilityTokenRewardRate = _rate;
    }


    // --- Governance & Community Functions ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyGovernance whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyGovernance whenNotPaused {
        require(proposals[_proposalId].endTime > block.timestamp, "Proposal voting period ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        hasVoted[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(proposals[_proposalId].endTime <= block.timestamp, "Proposal voting period not ended yet");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 percentageFor = (proposals[_proposalId].votesFor * 100) / totalVotes; // Calculate percentage

        if (percentageFor >= governanceThreshold) {
            string memory parameterName = proposals[_proposalId].parameterName;
            uint256 newValue = proposals[_proposalId].newValue;

            // Example parameter changes - extend this based on your contract parameters
            if (keccak256(bytes(parameterName)) == keccak256(bytes("baseEvolutionTime"))) {
                baseEvolutionTime = newValue;
            } else if (keccak256(bytes(parameterName)) == keccak256(bytes("utilityTokenRewardRate"))) {
                utilityTokenRewardRate = newValue;
            } else if (keccak256(bytes(parameterName)) == keccak256(bytes("governanceThreshold"))) {
                governanceThreshold = newValue;
            } else {
                revert("Invalid parameter to change"); // Or handle unknown parameters gracefully
            }

            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal failed to reach governance threshold");
        }
    }

    function setGovernanceThreshold(uint256 _threshold) external onlyOwner {
        governanceThreshold = _threshold;
    }

    // --- Admin & Utility Functions ---

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI = _newBaseURI;
    }

    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawCommunityTreasury() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(communityTreasury).transfer(balance);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function isWhitelisted(address _account, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }


    // --- Randomness (Simplified - Use VRF in Production) ---
    function getRandomNumber() private view returns (uint256) {
        // Simple pseudo-random number using block hash and timestamp for demonstration.
        // **WARNING:** This is NOT secure for high-stakes applications. Use Chainlink VRF or similar in production.
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenIdCounter.current())));
    }

    // --- Override _beforeTokenTransfer to add custom logic if needed ---
    // override _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Add custom logic before token transfer (e.g., reset staking on transfer)
    // }

    // --- Placeholder for Marketplace Integration Hooks ---
    // function onSaleListed(uint256 _tokenId, uint256 _price, address _marketplace) external whenNotPaused {
    //     require(_exists(_tokenId), "Token does not exist");
    //     // Logic to react to NFT being listed on a marketplace (e.g., update metadata, trigger events)
    // }
    // function onSaleSuccessful(uint256 _tokenId, uint256 _price, address _buyer, address _marketplace) external whenNotPaused {
    //     require(_exists(_tokenId), "Token does not exist");
    //     // Logic to react to NFT sale (e.g., update ownership, trigger events)
    // }

    // --- Placeholder for Upgradeability (using Proxy pattern) ---
    // For real upgradeability, implement a proxy pattern (e.g., using OpenZeppelin Upgrades Plugins).
    // This contract is not designed for direct upgradeability in this example.
}
```