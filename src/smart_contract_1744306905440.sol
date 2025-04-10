```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (Example Contract - Do not use in production without thorough audit)
 * @dev This contract implements a unique Dynamic NFT concept where NFTs can evolve
 * based on various on-chain and potentially off-chain factors. It includes advanced
 * concepts like dynamic metadata updates, evolution stages, skill trees, breeding,
 * crafting, staking, governance, and more. This is a complex example showcasing
 * a wide range of functionalities.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functionality (ERC721 Base):**
 *   - `constructor()`: Initializes the contract with name and symbol.
 *   - `mint(address _to, string memory _baseURI)`: Mints a new NFT to a recipient with initial metadata base URI.
 *   - `transferFrom(address _from, address _to, uint256 _tokenId)`: Standard ERC721 transfer function.
 *   - `approve(address _approved, uint256 _tokenId)`: Standard ERC721 approval function.
 *   - `getApproved(uint256 _tokenId)`: Standard ERC721 get approved address.
 *   - `setApprovalForAll(address _operator, bool _approved)`: Standard ERC721 set approval for all.
 *   - `isApprovedForAll(address _owner, address _operator)`: Standard ERC721 check approval for all.
 *   - `ownerOf(uint256 _tokenId)`: Standard ERC721 get owner of token.
 *   - `totalSupply()`: Returns the total supply of NFTs.
 *   - `balanceOf(address _owner)`: Returns the balance of NFTs for an owner.
 *   - `tokenURI(uint256 _tokenId)`: Returns the dynamic token URI for an NFT, reflecting its evolution.
 *
 * **2. Dynamic Evolution System:**
 *   - `evolve(uint256 _tokenId)`: Triggers the evolution process for an NFT based on predefined criteria.
 *   - `getEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 *   - `getEvolutionHistory(uint256 _tokenId)`: Returns the evolution history of an NFT.
 *   - `setEvolutionCriteria(uint256 _stage, /* ... evolution criteria params ... */ )`: (Admin) Sets the evolution criteria for a specific stage.
 *   - `getEvolutionCriteria(uint256 _stage)`: Returns the evolution criteria for a stage.
 *
 * **3. Skill Tree System:**
 *   - `allocateSkillPoint(uint256 _tokenId, uint256 _skillId)`: Allocates a skill point to a specific skill for an NFT.
 *   - `getSkillLevel(uint256 _tokenId, uint256 _skillId)`: Returns the level of a specific skill for an NFT.
 *   - `resetSkillTree(uint256 _tokenId)`: Resets the skill tree of an NFT (potentially with a cost).
 *   - `defineSkill(uint256 _skillId, string memory _skillName, string memory _description)`: (Admin) Defines a new skill.
 *   - `getSkillDefinition(uint256 _skillId)`: Returns the definition of a skill.
 *
 * **4. Breeding System:**
 *   - `breedNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Initiates the breeding process between two NFTs (if eligible).
 *   - `claimOffspring(uint256 _breedId)`: Claims the offspring NFT after successful breeding.
 *   - `getBreedingStatus(uint256 _breedId)`: Returns the status of a breeding process.
 *   - `setBreedingRules(/* ... breeding rules params ... */)`: (Admin) Sets the rules and costs for breeding.
 *   - `getBreedingRules()`: Returns the current breeding rules.
 *
 * **5. Crafting System:**
 *   - `craftItem(uint256 _tokenId, uint256 _recipeId)`: Initiates crafting of an item using an NFT and a recipe.
 *   - `claimCraftedItem(uint256 _craftId)`: Claims the crafted item after successful crafting.
 *   - `getCraftingStatus(uint256 _craftId)`: Returns the status of a crafting process.
 *   - `defineRecipe(uint256 _recipeId, /* ... recipe params ... */)`: (Admin) Defines a new crafting recipe.
 *   - `getRecipeDefinition(uint256 _recipeId)`: Returns the definition of a recipe.
 *
 * **6. Staking and Utility:**
 *   - `stakeNFT(uint256 _tokenId)`: Stakes an NFT to earn rewards.
 *   - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT and claims rewards.
 *   - `calculateRewards(uint256 _tokenId)`: Calculates the pending rewards for a staked NFT.
 *   - `setStakingParameters(/* ... staking params ... */)`: (Admin) Sets the parameters for staking and rewards.
 *   - `getStakingParameters()`: Returns the current staking parameters.
 *
 * **7. Governance (Basic Example):**
 *   - `proposeChange(string memory _proposalDescription)`: Allows token holders to propose changes to the contract parameters.
 *   - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on proposals.
 *   - `executeProposal(uint256 _proposalId)`: (Admin/Governance) Executes a passed proposal.
 *   - `getProposalStatus(uint256 _proposalId)`: Returns the status of a governance proposal.
 *
 * **8. Admin and Configuration:**
 *   - `setBaseURI(string memory _baseURI)`: (Admin) Sets the base URI for NFT metadata.
 *   - `withdrawFees()`: (Admin) Allows the contract owner to withdraw accumulated fees.
 *   - `pauseContract()`: (Admin) Pauses certain functionalities of the contract.
 *   - `unpauseContract()`: (Admin) Resumes paused functionalities.
 *   - `setOracleAddress(address _oracleAddress)`: (Admin) Sets the address of an oracle (for future external data integration).
 *
 * **Note:** This is a highly conceptual and complex contract. Real-world implementation would require careful design, security audits, and potentially more sophisticated mechanisms for each system.  Many details (like evolution criteria, breeding rules, crafting recipes, staking parameters, governance logic, oracle integration) are left as placeholders (`/* ... params ... */`) to focus on the overall structure and function count.
 */
contract DynamicNFTEvolution {
    // **** Outline and Function Summary (Copied from above for clarity) ****
    // 1. Core NFT Functionality (ERC721 Base)
    // 2. Dynamic Evolution System
    // 3. Skill Tree System
    // 4. Breeding System
    // 5. Crafting System
    // 6. Staking and Utility
    // 7. Governance (Basic Example)
    // 8. Admin and Configuration


    string public name = "DynamicEvolutionNFT";
    string public symbol = "DENFT";
    string public baseURI;
    address public owner;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _ownerOf;
    // Mapping from owner to number of owned token IDs
    mapping(address => uint256) private _balanceOf;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public totalSupplyCounter;

    // **** 2. Dynamic Evolution System ****
    struct EvolutionData {
        uint8 stage;
        uint256 lastEvolvedTimestamp;
        uint256[] history; // Array to store evolution history (stage numbers)
    }
    mapping(uint256 => EvolutionData) public evolutionData;
    mapping(uint8 => /* ... evolution criteria params ... */ uint256) public evolutionCriteria; // Example: time to evolve per stage

    // **** 3. Skill Tree System ****
    struct SkillTree {
        mapping(uint256 => uint8) skillLevels; // Skill ID to Level
        uint8 availableSkillPoints;
    }
    mapping(uint256 => SkillTree) public skillTrees;
    struct SkillDefinition {
        string name;
        string description;
    }
    mapping(uint256 => SkillDefinition) public skillDefinitions;
    uint256 public nextSkillId = 1;

    // **** 4. Breeding System ****
    struct BreedingProcess {
        uint256 tokenId1;
        uint256 tokenId2;
        address breeder;
        uint256 startTime;
        bool completed;
        uint256 offspringTokenId;
    }
    mapping(uint256 => BreedingProcess) public breedingProcesses; // Breed ID to process
    uint256 public nextBreedId = 1;
    /* ... breeding rules params ... */ uint256 public breedingCost;

    // **** 5. Crafting System ****
    struct CraftingProcess {
        uint256 tokenId;
        uint256 recipeId;
        address crafter;
        uint256 startTime;
        bool completed;
        uint256 craftedItemId; // Example: ID of crafted item (could be another NFT or token)
    }
    mapping(uint256 => CraftingProcess) public craftingProcesses; // Craft ID to process
    uint256 public nextCraftId = 1;
    struct RecipeDefinition {
        /* ... recipe params ... */ string name;
    }
    mapping(uint256 => RecipeDefinition) public recipeDefinitions;
    uint256 public nextRecipeId = 1;

    // **** 6. Staking and Utility ****
    struct StakingData {
        bool isStaked;
        uint256 stakeStartTime;
    }
    mapping(uint256 => StakingData) public stakingData;
    /* ... staking params ... */ uint256 public stakingRewardRate;

    // **** 7. Governance (Basic Example) ****
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        uint256 proposalTimestamp;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    // **** 8. Admin and Configuration ****
    address public oracleAddress;
    bool public paused = false;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event NFTMinted(address indexed _to, uint256 indexed _tokenId);
    event NFTEvolved(uint256 indexed _tokenId, uint8 stage);
    event SkillPointAllocated(uint256 indexed _tokenId, uint256 skillId);
    event BreedingInitiated(uint256 breedId, uint256 tokenId1, uint256 tokenId2, address breeder);
    event OffspringClaimed(uint256 breedId, uint256 offspringTokenId);
    event CraftingInitiated(uint256 craftId, uint256 tokenId, uint256 recipeId, address crafter);
    event ItemCrafted(uint256 craftId, uint256 craftedItemId);
    event NFTStaked(uint256 indexed _tokenId);
    event NFTUnstaked(uint256 indexed _tokenId);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event BaseURISet(string baseURI);
    event OracleAddressSet(address oracleAddress);
    event ContractPaused();
    event ContractUnpaused();


    constructor() {
        owner = msg.sender;
    }

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

    // **** 1. Core NFT Functionality (ERC721 Base) ****

    function mint(address _to, string memory _baseURI) public onlyOwner {
        require(_to != address(0), "Mint to the zero address");
        totalSupplyCounter++;
        uint256 tokenId = totalSupplyCounter;
        _ownerOf[tokenId] = _to;
        _balanceOf[_to]++;
        baseURI = _baseURI; // Set base URI on mint for simplicity, could be managed differently
        evolutionData[tokenId] = EvolutionData({stage: 1, lastEvolvedTimestamp: block.timestamp, history: new uint256[](0)});
        skillTrees[tokenId] = SkillTree({skillLevels: mapping(uint256 => uint8)(), availableSkillPoints: 0}); // Initial skill tree
        emit Transfer(address(0), _to, tokenId);
        emit NFTMinted(_to, tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Transfer caller is not owner nor approved");
        require(_ownerOf[_tokenId] == _from, "Transfer from incorrect owner");
        require(_to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _tokenId);

        _clearApproval(_tokenId);

        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address tokenOwner = ownerOf(_tokenId);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "Approve caller is not owner nor approved for all");

        _tokenApprovals[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddr = _ownerOf[_tokenId];
        require(ownerAddr != address(0), "ERC721: ownerOf query for nonexistent token");
        return ownerAddr;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf[_owner];
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Dynamic URI generation based on evolution stage, skills, etc.
        string memory stageStr = Strings.toString(evolutionData[_tokenId].stage);
        // Example: could include skill levels or other attributes in URI
        return string(abi.encodePacked(baseURI, _tokenId, "/", stageStr, ".json"));
    }


    // **** 2. Dynamic Evolution System ****

    function evolve(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");

        EvolutionData storage data = evolutionData[_tokenId];
        uint8 currentStage = data.stage;
        uint256 timeToEvolve = evolutionCriteria[currentStage]; // Example criteria: time-based

        require(block.timestamp >= data.lastEvolvedTimestamp + timeToEvolve, "Evolution criteria not met yet");
        require(currentStage < 5, "Max evolution stage reached"); // Example: max 5 stages

        data.stage++;
        data.lastEvolvedTimestamp = block.timestamp;
        data.history.push(data.stage); // Record evolution in history
        skillTrees[_tokenId].availableSkillPoints++; // Grant a skill point on evolution

        emit NFTEvolved(_tokenId, data.stage);
    }

    function getEvolutionStage(uint256 _tokenId) public view returns (uint8) {
        require(_exists(_tokenId), "NFT does not exist");
        return evolutionData[_tokenId].stage;
    }

    function getEvolutionHistory(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return evolutionData[_tokenId].history;
    }

    function setEvolutionCriteria(uint8 _stage, uint256 _timeToEvolve) public onlyOwner {
        evolutionCriteria[_stage] = _timeToEvolve; // Example: set time to evolve for a stage
    }

    function getEvolutionCriteria(uint8 _stage) public view returns (uint256) {
        return evolutionCriteria[_stage];
    }


    // **** 3. Skill Tree System ****

    function allocateSkillPoint(uint256 _tokenId, uint256 _skillId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(skillTrees[_tokenId].availableSkillPoints > 0, "No skill points available");
        require(skillDefinitions[_skillId].name.length > 0, "Skill does not exist"); // Check if skill is defined

        skillTrees[_tokenId].skillLevels[_skillId]++;
        skillTrees[_tokenId].availableSkillPoints--;
        emit SkillPointAllocated(_tokenId, _skillId);
    }

    function getSkillLevel(uint256 _tokenId, uint256 _skillId) public view returns (uint8) {
        require(_exists(_tokenId), "NFT does not exist");
        return skillTrees[_tokenId].skillLevels[_skillId];
    }

    function resetSkillTree(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        // Potentially add a cost for resetting skill tree
        delete skillTrees[_tokenId].skillLevels; // Clear skill levels
        skillTrees[_tokenId].availableSkillPoints = 0; // Reset available points (or refund some)
        // You might want to refund some points based on levels reset
    }

    function defineSkill(uint256 _skillId, string memory _skillName, string memory _description) public onlyOwner {
        skillDefinitions[_skillId] = SkillDefinition({name: _skillName, description: _description});
        if (_skillId >= nextSkillId) {
            nextSkillId = _skillId + 1;
        }
    }

    function getSkillDefinition(uint256 _skillId) public view returns (SkillDefinition memory) {
        return skillDefinitions[_skillId];
    }


    // **** 4. Breeding System ****

    function breedNFTs(uint256 _tokenId1, uint256 _tokenId2) public payable whenNotPaused {
        require(_exists(_tokenId1) && _exists(_tokenId2), "One or both NFTs do not exist");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not the owner of both NFTs");
        require(msg.value >= breedingCost, "Insufficient breeding cost");

        uint256 breedId = nextBreedId++;
        breedingProcesses[breedId] = BreedingProcess({
            tokenId1: _tokenId1,
            tokenId2: _tokenId2,
            breeder: msg.sender,
            startTime: block.timestamp,
            completed: false,
            offspringTokenId: 0
        });
        emit BreedingInitiated(breedId, _tokenId1, _tokenId2, msg.sender);
    }

    function claimOffspring(uint256 _breedId) public whenNotPaused {
        require(breedingProcesses[_breedId].breeder == msg.sender, "You are not the breeder");
        require(breedingProcesses[_breedId].completed == false, "Breeding already completed");

        // ... Logic to determine offspring attributes (could be based on parents' attributes, randomness, etc.) ...
        // For simplicity, let's just mint a new NFT as offspring
        totalSupplyCounter++;
        uint256 offspringTokenId = totalSupplyCounter;
        _ownerOf[offspringTokenId] = msg.sender;
        _balanceOf[msg.sender]++;
        evolutionData[offspringTokenId] = EvolutionData({stage: 1, lastEvolvedTimestamp: block.timestamp, history: new uint256[](0)}); // Reset evolution
        skillTrees[offspringTokenId] = SkillTree({skillLevels: mapping(uint256 => uint8)(), availableSkillPoints: 0}); // Reset skills

        breedingProcesses[_breedId].completed = true;
        breedingProcesses[_breedId].offspringTokenId = offspringTokenId;

        emit OffspringClaimed(_breedId, offspringTokenId);
        emit Transfer(address(0), msg.sender, offspringTokenId);
        emit NFTMinted(msg.sender, offspringTokenId);
    }

    function getBreedingStatus(uint256 _breedId) public view returns (BreedingProcess memory) {
        return breedingProcesses[_breedId];
    }

    function setBreedingRules(uint256 _cost) public onlyOwner {
        breedingCost = _cost;
    }

    function getBreedingRules() public view returns (uint256) {
        return breedingCost;
    }


    // **** 5. Crafting System ****

    function craftItem(uint256 _tokenId, uint256 _recipeId) public payable whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(recipeDefinitions[_recipeId].name.length > 0, "Recipe does not exist"); // Check if recipe is defined
        // ... Add checks for required ingredients, etc. based on recipe ...

        uint256 craftId = nextCraftId++;
        craftingProcesses[craftId] = CraftingProcess({
            tokenId: _tokenId,
            recipeId: _recipeId,
            crafter: msg.sender,
            startTime: block.timestamp,
            completed: false,
            craftedItemId: 0 // Placeholder for crafted item ID
        });
        emit CraftingInitiated(craftId, _tokenId, _recipeId, msg.sender);
    }

    function claimCraftedItem(uint256 _craftId) public whenNotPaused {
        require(craftingProcesses[_craftId].crafter == msg.sender, "You are not the crafter");
        require(craftingProcesses[_craftId].completed == false, "Crafting already completed");

        // ... Logic to create the crafted item (could be another NFT, ERC20 token, etc.) ...
        // For simplicity, let's assume it crafts an item with a fixed ID (replace with actual item creation logic)
        uint256 craftedItemId = _craftId + 1000; // Example item ID generation
        craftingProcesses[_craftId].completed = true;
        craftingProcesses[_craftId].craftedItemId = craftedItemId;

        emit ItemCrafted(_craftId, craftedItemId);
        // ... Transfer/mint the crafted item to the crafter ...
    }

    function getCraftingStatus(uint256 _craftId) public view returns (CraftingProcess memory) {
        return craftingProcesses[_craftId];
    }

    function defineRecipe(uint256 _recipeId, string memory _recipeName /* ... recipe params ... */) public onlyOwner {
        recipeDefinitions[_recipeId] = RecipeDefinition({name: _recipeName /* ... recipe params ... */});
        if (_recipeId >= nextRecipeId) {
            nextRecipeId = _recipeId + 1;
        }
    }

    function getRecipeDefinition(uint256 _recipeId) public view returns (RecipeDefinition memory) {
        return recipeDefinitions[_recipeId];
    }


    // **** 6. Staking and Utility ****

    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(!stakingData[_tokenId].isStaked, "NFT is already staked");

        stakingData[_tokenId].isStaked = true;
        stakingData[_tokenId].stakeStartTime = block.timestamp;
        emit NFTStaked(_tokenId);
    }

    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(stakingData[_tokenId].isStaked, "NFT is not staked");

        uint256 rewards = calculateRewards(_tokenId);
        stakingData[_tokenId].isStaked = false;
        stakingData[_tokenId].stakeStartTime = 0;
        // ... Transfer rewards to the owner (assuming rewards are in a token) ...
        // For simplicity, let's just emit an event indicating rewards
        emit NFTUnstaked(_tokenId);
        // ... Transfer `rewards` amount of reward token to msg.sender ...
    }

    function calculateRewards(uint256 _tokenId) public view returns (uint256) {
        if (!stakingData[_tokenId].isStaked) {
            return 0;
        }
        uint256 stakeDuration = block.timestamp - stakingData[_tokenId].stakeStartTime;
        uint256 rewards = (stakeDuration * stakingRewardRate) / 1 days; // Example: rewards per day
        return rewards;
    }

    function setStakingParameters(uint256 _rewardRate) public onlyOwner {
        stakingRewardRate = _rewardRate;
    }

    function getStakingParameters() public view returns (uint256) {
        return stakingRewardRate;
    }


    // **** 7. Governance (Basic Example) ****

    function proposeChange(string memory _proposalDescription) public whenNotPaused {
        require(balanceOf(msg.sender) > 0, "You need to hold at least one NFT to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalTimestamp: block.timestamp
        });
        emit ProposalCreated(proposalId, _proposalDescription, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(balanceOf(msg.sender) > 0, "You need to hold at least one NFT to vote");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        // In a more advanced system, you would track votes per address to prevent double voting

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal not passed");
        // ... Logic to execute the proposal (e.g., change contract parameters) ...
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function getProposalStatus(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // **** 8. Admin and Configuration ****

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function withdrawFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }


    // **** Internal Helper Functions ****

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address ownerAddr = ownerOf(_tokenId);
        return (_spender == ownerAddr || getApproved(_tokenId) == _spender || isApprovedForAll(ownerAddr, _spender));
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {
        // Can add hooks here before transfer, e.g., for game logic or restrictions
    }

    function _clearApproval(uint256 _tokenId) private {
        if (_tokenApprovals[_tokenId] != address(0)) {
            delete _tokenApprovals[_tokenId];
        }
    }
}

// --- Helper library for uint256 to string conversion ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

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