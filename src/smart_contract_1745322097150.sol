```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Evolving Ecosystem NFT Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract showcasing advanced concepts like dynamic NFTs, on-chain governance,
 *      resource management, and interactive ecosystem participation.
 *
 * **Outline:**
 *  - Dynamic NFT Evolution: NFTs that can evolve and change based on on-chain actions and resources.
 *  - Resource Management: System for managing on-chain resources that NFTs can utilize.
 *  - On-Chain Governance: Basic governance mechanism for community-driven ecosystem changes.
 *  - Interactive Ecosystem: Functions allowing users to interact with the ecosystem and their NFTs.
 *  - Advanced Access Control: Role-based access control for different functionalities.
 *  - Unique Randomness Implementation: Controlled randomness for certain features.
 *  - Data Storage Optimization: Efficient data storage for NFT attributes and ecosystem state.
 *
 * **Function Summary:**
 *  1. `mintEcosystemNFT()`: Mints a new Ecosystem NFT to a user with initial attributes.
 *  2. `transferNFT()`: Transfers an Ecosystem NFT to another address.
 *  3. `getNFTMetadata()`: Retrieves metadata of a specific NFT, including dynamic attributes.
 *  4. `nftLevelUp()`: Allows NFT owners to level up their NFTs using resources.
 *  5. `stakeNFT()`: Allows NFT owners to stake their NFTs to earn ecosystem resources.
 *  6. `unstakeNFT()`: Allows NFT owners to unstake their NFTs and claim earned resources.
 *  7. `claimResources()`: Allows NFT owners to claim accumulated resources for their NFTs.
 *  8. `getResourceBalance()`: Retrieves the resource balance of a specific NFT.
 *  9. `depositResources()`: Allows users to deposit resources into the ecosystem pool.
 * 10. `withdrawResources()`: (Admin only) Allows admin to withdraw resources from the ecosystem pool.
 * 11. `setResourceRewardRate()`: (Admin only) Sets the resource reward rate for NFT staking.
 * 12. `getEcosystemParameter()`: Retrieves a specific ecosystem parameter (e.g., reward rate).
 * 13. `proposeParameterChange()`: Allows users to propose changes to ecosystem parameters.
 * 14. `voteOnParameterChange()`: Allows users to vote on proposed parameter changes.
 * 15. `executeParameterChange()`: (Admin only) Executes a parameter change if it passes governance.
 * 16. `getRandomNumber()`: Generates a pseudo-random number within a specified range.
 * 17. `attributeEnhancement()`: Allows NFT owners to enhance specific NFT attributes using resources.
 * 18. `setNFTAttribute()`: (Admin only) Allows admin to directly set specific attributes of an NFT.
 * 19. `initializeEcosystem()`: (Admin only) Initializes the ecosystem with initial parameters.
 * 20. `pauseContract()`: (Admin only) Pauses certain functionalities of the contract for maintenance.
 * 21. `unpauseContract()`: (Admin only) Resumes paused functionalities of the contract.
 * 22. `getTotalNFTsMinted()`: Returns the total number of NFTs minted in the ecosystem.
 * 23. `getNFTLevel()`: Returns the current level of a specific NFT.
 */

contract EvolvingEcosystemNFT {
    // --- State Variables ---

    string public name = "Evolving Ecosystem NFT";
    string public symbol = "EENFT";

    address public admin; // Admin address with privileged functions
    bool public paused = false; // Paused state for emergency maintenance

    uint256 public nextNFTId = 1; // Counter for NFT IDs
    mapping(uint256 => address) public nftOwner; // NFT ID to owner address
    mapping(address => uint256[]) public ownerNFTs; // Owner address to list of NFT IDs
    mapping(uint256 => NFTMetadata) public nftMetadata; // NFT ID to metadata struct
    mapping(uint256 => uint256) public nftLevel; // NFT ID to level
    mapping(uint256 => uint256) public nftResourceBalance; // NFT ID to resource balance

    uint256 public ecosystemResourcePool; // Pool of resources in the ecosystem
    uint256 public resourceRewardRate = 10; // Base reward rate per block for staking (example)

    mapping(uint256 => ParameterProposal) public parameterProposals; // Proposal ID to proposal details
    uint256 public nextProposalId = 1; // Counter for proposal IDs
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID to voter to voted status

    struct NFTMetadata {
        uint256 generation;
        string baseType;
        uint256 level;
        uint256 power;
        uint256 agility;
        // ... more dynamic attributes can be added here ...
    }

    struct ParameterProposal {
        string description;
        string parameterName;
        uint256 proposedValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalEndTime;
    }

    // --- Events ---

    event NFTMinted(address indexed owner, uint256 nftId);
    event NFTTransferred(uint256 indexed nftId, address indexed from, address indexed to);
    event NFTLeveledUp(uint256 indexed nftId, uint256 newLevel);
    event NFTStaked(uint256 indexed nftId, address indexed owner);
    event NFTUnstaked(uint256 indexed nftId, address indexed owner);
    event ResourcesClaimed(uint256 indexed nftId, uint256 amount);
    event ResourcesDeposited(address indexed depositor, uint256 amount);
    event ResourcesWithdrawn(address indexed admin, uint256 amount);
    event RewardRateSet(uint256 newRate);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 proposedValue, string description);
    event ParameterVoteCast(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AttributeEnhanced(uint256 indexed nftId, string attribute, uint256 newValue);
    event NFTAttributeSet(uint256 indexed nftId, string attribute, uint256 newValue);

    // --- Modifiers ---

    modifier onlyOwnerOf(uint256 _nftId) {
        require(nftOwner[_nftId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
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

    modifier validNFT(uint256 _nftId) {
        require(nftOwner[_nftId] != address(0), "Invalid NFT ID");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(parameterProposals[_proposalId].proposalEndTime > block.timestamp, "Proposal expired");
        require(!parameterProposals[_proposalId].executed, "Proposal already executed");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        initializeEcosystem(); // Initialize ecosystem parameters on deployment
    }

    // --- Admin Functions ---

    /// @dev Initializes the ecosystem with default parameters (can be customized later).
    function initializeEcosystem() public onlyAdmin {
        resourceRewardRate = 10; // Set initial reward rate
        emit RewardRateSet(resourceRewardRate);
        // ... initialize other ecosystem parameters if needed ...
    }

    /// @dev Allows admin to withdraw resources from the ecosystem pool.
    /// @param _amount The amount of resources to withdraw.
    function withdrawResources(uint256 _amount) public onlyAdmin {
        require(ecosystemResourcePool >= _amount, "Insufficient ecosystem resources");
        payable(admin).transfer(_amount); // Assuming resources are ETH for simplicity, can be adapted for tokens
        ecosystemResourcePool -= _amount;
        emit ResourcesWithdrawn(admin, _amount);
    }

    /// @dev Sets the resource reward rate for NFT staking.
    /// @param _newRate The new resource reward rate per block.
    function setResourceRewardRate(uint256 _newRate) public onlyAdmin {
        resourceRewardRate = _newRate;
        emit RewardRateSet(_newRate);
    }

    /// @dev Allows admin to directly set specific attributes of an NFT (for debugging or special events).
    /// @param _nftId The ID of the NFT.
    /// @param _attribute The name of the attribute to set (string for flexibility).
    /// @param _value The new value of the attribute.
    function setNFTAttribute(uint256 _nftId, string memory _attribute, uint256 _value) public onlyAdmin validNFT(_nftId) {
        if (keccak256(bytes(_attribute)) == keccak256(bytes("level"))) {
            nftLevel[_nftId] = _value;
        } else if (keccak256(bytes(_attribute)) == keccak256(bytes("power"))) {
            nftMetadata[_nftId].power = _value;
        } else if (keccak256(bytes(_attribute)) == keccak256(bytes("agility"))) {
            nftMetadata[_nftId].agility = _value;
        }
        // ... add more attribute handling as needed ...
        emit NFTAttributeSet(_nftId, _attribute, _value);
    }

    /// @dev Pauses certain functionalities of the contract for maintenance.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @dev Resumes paused functionalities of the contract.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @dev Executes a parameter change if it passes governance.
    /// @param _proposalId The ID of the proposal to execute.
    function executeParameterChange(uint256 _proposalId) public onlyAdmin validProposal(_proposalId) {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed");
        require(!proposal.executed, "Proposal already executed");

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("resourceRewardRate"))) {
            resourceRewardRate = proposal.proposedValue;
            emit RewardRateSet(resourceRewardRate);
        }
        // ... Add more parameter handling based on proposal.parameterName ...

        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.proposedValue);
    }


    // --- NFT Core Functions ---

    /// @dev Mints a new Ecosystem NFT to a user with initial attributes.
    /// @param _to The address to mint the NFT to.
    /// @param _baseType The base type of the NFT (e.g., "Fire", "Water").
    function mintEcosystemNFT(address _to, string memory _baseType) public whenNotPaused {
        uint256 newNftId = nextNFTId++;
        nftOwner[newNftId] = _to;
        ownerNFTs[_to].push(newNftId);

        // Initialize NFT metadata with dynamic attributes based on baseType (example)
        NFTMetadata memory newMetadata;
        newMetadata.generation = 1;
        newMetadata.baseType = _baseType;
        newMetadata.level = 1;
        newMetadata.power = getRandomNumber(10, 20); // Example: Random power between 10 and 20
        newMetadata.agility = getRandomNumber(5, 15); // Example: Random agility between 5 and 15
        nftMetadata[newNftId] = newMetadata;
        nftLevel[newNftId] = 1; // Initialize level to 1

        emit NFTMinted(_to, newNftId);
    }

    /// @dev Transfers an Ecosystem NFT to another address.
    /// @param _to The address to transfer the NFT to.
    /// @param _nftId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _nftId) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        address from = nftOwner[_nftId];
        nftOwner[_nftId] = _to;

        // Update ownerNFTs mapping (remove from sender, add to receiver - basic implementation)
        uint256[] storage senderNFTList = ownerNFTs[from];
        for (uint256 i = 0; i < senderNFTList.length; i++) {
            if (senderNFTList[i] == _nftId) {
                senderNFTList[i] = senderNFTList[senderNFTList.length - 1];
                senderNFTList.pop();
                break;
            }
        }
        ownerNFTs[_to].push(_nftId);

        emit NFTTransferred(_nftId, from, _to);
    }

    /// @dev Retrieves metadata of a specific NFT, including dynamic attributes.
    /// @param _nftId The ID of the NFT.
    /// @return NFTMetadata struct containing NFT metadata.
    function getNFTMetadata(uint256 _nftId) public view validNFT(_nftId) returns (NFTMetadata memory) {
        return nftMetadata[_nftId];
    }

    /// @dev Returns the owner of a specific NFT.
    /// @param _nftId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _nftId) public view validNFT(_nftId) returns (address) {
        return nftOwner[_nftId];
    }

    /// @dev Returns the total number of NFTs minted in the ecosystem.
    function getTotalNFTsMinted() public view returns (uint256) {
        return nextNFTId - 1;
    }

    /// @dev Returns the current level of a specific NFT.
    /// @param _nftId The ID of the NFT.
    /// @return The level of the NFT.
    function getNFTLevel(uint256 _nftId) public view validNFT(_nftId) returns (uint256) {
        return nftLevel[_nftId];
    }

    // --- NFT Evolution and Resource Functions ---

    /// @dev Allows NFT owners to level up their NFTs using resources.
    /// @param _nftId The ID of the NFT to level up.
    function nftLevelUp(uint256 _nftId) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        uint256 currentLevel = nftLevel[_nftId];
        uint256 levelUpCost = getLevelUpCost(currentLevel); // Calculate level up cost based on current level

        require(nftResourceBalance[_nftId] >= levelUpCost, "Insufficient resources to level up");

        nftResourceBalance[_nftId] -= levelUpCost;
        nftLevel[_nftId]++;
        nftMetadata[_nftId].level = nftLevel[_nftId]; // Update level in metadata too (for consistency)
        nftMetadata[_nftId].power += getRandomNumber(3, 7); // Example: Increase power on level up
        nftMetadata[_nftId].agility += getRandomNumber(1, 4); // Example: Increase agility on level up

        emit NFTLeveledUp(_nftId, nftLevel[_nftId]);
    }

    /// @dev Calculates the cost to level up an NFT based on its current level (example logic).
    /// @param _currentLevel The current level of the NFT.
    /// @return The resource cost to level up.
    function getLevelUpCost(uint256 _currentLevel) public pure returns (uint256) {
        return (_currentLevel * 100) + 50; // Example: Increasing cost per level
    }

    /// @dev Allows NFT owners to stake their NFTs to earn ecosystem resources.
    /// @param _nftId The ID of the NFT to stake.
    function stakeNFT(uint256 _nftId) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        // Basic staking implementation - can be expanded with staking duration, etc.
        // For now, just mark NFT as staked (could use a mapping for staking status if needed for more complex logic)
        emit NFTStaked(_nftId, msg.sender);
    }

    /// @dev Allows NFT owners to unstake their NFTs and claim earned resources.
    /// @param _nftId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _nftId) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        claimResources(_nftId); // Automatically claim resources upon unstaking (can be separate if needed)
        emit NFTUnstaked(_nftId, msg.sender);
    }

    /// @dev Allows NFT owners to claim accumulated resources for their NFTs.
    /// @param _nftId The ID of the NFT to claim resources for.
    function claimResources(uint256 _nftId) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        uint256 rewards = calculateRewards(_nftId);
        if (rewards > 0) {
            nftResourceBalance[_nftId] += rewards;
            ecosystemResourcePool -= rewards; // Deduct resources from the ecosystem pool
            emit ResourcesClaimed(_nftId, rewards);
        }
    }

    /// @dev Calculates the resources earned by an NFT since the last claim (example logic).
    /// @param _nftId The ID of the NFT.
    /// @return The amount of resources earned.
    function calculateRewards(uint256 _nftId) public view validNFT(_nftId) returns (uint256) {
        // Example reward calculation based on NFT level and reward rate
        uint256 reward = nftLevel[_nftId] * resourceRewardRate;
        return reward; // In a real system, track last claim time and calculate based on time elapsed.
    }

    /// @dev Retrieves the resource balance of a specific NFT.
    /// @param _nftId The ID of the NFT.
    /// @return The resource balance of the NFT.
    function getResourceBalance(uint256 _nftId) public view validNFT(_nftId) returns (uint256) {
        return nftResourceBalance[_nftId];
    }

    /// @dev Allows users to deposit resources into the ecosystem pool.
    function depositResources() public payable whenNotPaused {
        // For simplicity, resources are ETH in this example. Can be adapted to ERC20 tokens.
        ecosystemResourcePool += msg.value;
        emit ResourcesDeposited(msg.sender, msg.value);
    }

    // --- Governance Functions ---

    /// @dev Retrieves a specific ecosystem parameter.
    /// @param _parameterName The name of the parameter to retrieve (string for flexibility).
    /// @return The value of the parameter.
    function getEcosystemParameter(string memory _parameterName) public view returns (uint256) {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("resourceRewardRate"))) {
            return resourceRewardRate;
        }
        // ... Add more parameter handling as needed ...
        revert("Parameter not found");
    }

    /// @dev Allows users to propose changes to ecosystem parameters.
    /// @param _parameterName The name of the parameter to change.
    /// @param _proposedValue The proposed new value for the parameter.
    /// @param _description A description of the proposed change.
    function proposeParameterChange(string memory _parameterName, uint256 _proposedValue, string memory _description) public whenNotPaused {
        require(bytes(_parameterName).length > 0 && bytes(_description).length > 0, "Parameter name and description required");

        uint256 proposalId = nextProposalId++;
        parameterProposals[proposalId] = ParameterProposal({
            description: _description,
            parameterName: _parameterName,
            proposedValue: _proposedValue,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalEndTime: block.timestamp + 7 days // Example: 7 days voting period
        });

        emit ParameterProposalCreated(proposalId, _parameterName, _proposedValue, _description);
    }

    /// @dev Allows users to vote on proposed parameter changes.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for 'for', false for 'against'.
    function voteOnParameterChange(uint256 _proposalId, bool _vote) public whenNotPaused validProposal(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposalVotes[_proposalId][msg.sender] = true;
        emit ParameterVoteCast(_proposalId, msg.sender, _vote);
    }


    // --- Utility Functions ---

    /// @dev Generates a pseudo-random number within a specified range (inclusive).
    /// @param _min Minimum value (inclusive).
    /// @param _max Maximum value (inclusive).
    /// @return A pseudo-random number between _min and _max.
    function getRandomNumber(uint256 _min, uint256 _max) internal view returns (uint256) {
        uint256 range = _max - _min + 1;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % range;
        return randomNumber + _min;
    }

    /// @dev Allows NFT owners to enhance specific NFT attributes using resources.
    /// @param _nftId The ID of the NFT to enhance.
    /// @param _attribute The attribute to enhance (e.g., "power", "agility").
    function attributeEnhancement(uint256 _nftId, string memory _attribute) public whenNotPaused onlyOwnerOf(_nftId) validNFT(_nftId) {
        uint256 enhancementCost = getEnhancementCost(_nftId, _attribute); // Calculate cost based on attribute and NFT level

        require(nftResourceBalance[_nftId] >= enhancementCost, "Insufficient resources for enhancement");
        nftResourceBalance[_nftId] -= enhancementCost;

        if (keccak256(bytes(_attribute)) == keccak256(bytes("power"))) {
            nftMetadata[_nftId].power += getRandomNumber(2, 5); // Example: Increase power by 2-5
            emit AttributeEnhanced(_nftId, "power", nftMetadata[_nftId].power);
        } else if (keccak256(bytes(_attribute)) == keccak256(bytes("agility"))) {
            nftMetadata[_nftId].agility += getRandomNumber(1, 3); // Example: Increase agility by 1-3
            emit AttributeEnhanced(_nftId, "agility", nftMetadata[_nftId].agility);
        } else {
            revert("Invalid attribute for enhancement");
        }
    }

    /// @dev Calculates the cost to enhance a specific NFT attribute (example logic).
    /// @param _nftId The ID of the NFT.
    /// @param _attribute The attribute being enhanced.
    /// @return The resource cost for enhancement.
    function getEnhancementCost(uint256 _nftId, string memory _attribute) public view returns (uint256) {
        uint256 baseCost = 50; // Base cost for enhancement
        uint256 levelMultiplier = nftLevel[_nftId] / 5 + 1; // Increase cost every 5 levels
        return baseCost * levelMultiplier; // Example: Cost increases with level
    }


    // --- Fallback and Receive (Optional) ---

    receive() external payable {} // Allow contract to receive ETH

    fallback() external {} // Fallback function
}
```