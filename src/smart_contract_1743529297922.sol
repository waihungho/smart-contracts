```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution Game Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT evolution game with decentralized governance and advanced features.
 *
 * **Outline and Function Summary:**
 *
 * **Contract Overview:**
 * This contract manages a game where users can own and evolve dynamic NFTs representing creatures.
 * NFTs can be staked to earn resources, traded in a marketplace, and their evolution is governed by community proposals.
 * The contract incorporates randomness for evolution outcomes and decentralized governance for parameter adjustments.
 *
 * **Core Features:**
 * 1. **Dynamic NFT Evolution:** NFTs can evolve through stages, changing their metadata and properties.
 * 2. **Resource Staking & Generation:** NFTs can be staked to earn in-game resources.
 * 3. **Decentralized Governance (DAO-lite):** Community voting on game parameters and evolution rules.
 * 4. **Marketplace:** Trading NFTs and resources within the contract.
 * 5. **Randomness Integration:** Utilizing a pseudo-random function for unpredictable evolution outcomes.
 * 6. **Dynamic Metadata Updates:** NFT metadata updates on-chain to reflect evolution and changes.
 * 7. **Emergency Pause Mechanism:** Contract owner can pause critical functions in case of emergencies.
 * 8. **Token Gating for Advanced Features:**  Future potential to introduce a governance token for exclusive access.
 *
 * **Function List (20+):**
 *
 * **NFT Management (7 functions):**
 * 1. `mintCreature(string memory _name, string memory _metadataURI)`: Mints a new creature NFT to the caller.
 * 2. `transferCreature(address _to, uint256 _tokenId)`: Transfers ownership of a creature NFT. (Standard ERC721)
 * 3. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on a single creature NFT. (Standard ERC721)
 * 4. `getApproved(uint256 _tokenId)`: Gets the approved address for a creature NFT. (Standard ERC721)
 * 5. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for an operator to manage all of caller's creature NFTs. (Standard ERC721)
 * 6. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved to manage all creature NFTs of an owner. (Standard ERC721)
 * 7. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a creature NFT, dynamically updated based on evolution stage.
 *
 * **Evolution & Staking (6 functions):**
 * 8. `evolveCreature(uint256 _tokenId)`: Attempts to evolve a creature NFT to the next stage, consuming resources.
 * 9. `stakeCreature(uint256 _tokenId)`: Stakes a creature NFT to start generating resources.
 * 10. `unstakeCreature(uint256 _tokenId)`: Unstakes a creature NFT and claims accumulated resources.
 * 11. `claimResources(uint256 _tokenId)`: Claims accumulated resources for a staked creature without unstaking.
 * 12. `getResourceBalance(uint256 _tokenId)`: Gets the current resource balance for a staked creature.
 * 13. `getEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of a creature NFT.
 *
 * **Marketplace (4 functions):**
 * 14. `listCreatureForSale(uint256 _tokenId, uint256 _price)`: Lists a creature NFT for sale in the marketplace.
 * 15. `buyCreature(uint256 _listingId)`: Buys a creature NFT from the marketplace listing.
 * 16. `cancelCreatureListing(uint256 _listingId)`: Cancels a creature NFT listing in the marketplace.
 * 17. `withdrawMarketplaceFunds()`: Allows the contract owner to withdraw marketplace fees (if any implemented).
 *
 * **Governance & Administration (6 functions):**
 * 18. `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Allows users to propose changes to game parameters through governance.
 * 19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on a governance proposal.
 * 20. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (owner-controlled execution for simplicity in this example).
 * 21. `setParameter(string memory _parameterName, uint256 _newValue)`:  (Admin function) Directly sets a game parameter (for initial setup or emergency overrides).
 * 22. `pauseContract()`: (Admin function) Pauses critical contract functions.
 * 23. `unpauseContract()`: (Admin function) Resumes paused contract functions.
 */

contract DynamicNFTEvolutionGame {
    // --- State Variables ---

    // ERC721 Metadata
    string public name = "Dynamic Creature";
    string public symbol = "DCR";
    string public baseURI; // Base URI for token metadata, can be set by admin

    // NFT Ownership and Balances (using standard ERC721)
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public nextTokenId = 1; // Starting token ID

    // Creature Data
    struct Creature {
        string name;
        uint8 evolutionStage;
        uint256 lastResourceClaimTime;
    }
    mapping(uint256 => Creature) public creatures;

    // Evolution Parameters
    uint256 public evolutionCost = 100; // Resource cost to evolve
    uint8 public maxEvolutionStage = 3;
    mapping(uint8 => string) public evolutionStageMetadataSuffixes; // Suffixes to append to baseURI for each stage

    // Resource Generation
    uint256 public resourceGenerationRate = 1; // Resources generated per hour per staked creature
    mapping(uint256 => uint256) public stakedCreatureIds; // Token IDs of staked creatures
    mapping(uint256 => uint256) public stakedTime; // Timestamp when creature was staked

    // Marketplace
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public creatureListings; // listingId => Listing
    uint256 public nextListingId = 1;

    // Governance Proposals
    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalEndTime;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256 public governanceVoteDuration = 7 days; // Proposal voting duration
    uint256 public governanceThreshold = 50; // Percentage of votes required to pass (50%)

    // Game Parameters (Governance-controlled)
    mapping(string => uint256) public gameParameters;

    // Admin and Pausing
    address public owner;
    bool public paused;

    // --- Events ---
    event CreatureMinted(uint256 tokenId, address owner, string creatureName);
    event CreatureEvolved(uint256 tokenId, uint8 newStage);
    event CreatureStaked(uint256 tokenId);
    event CreatureUnstaked(uint256 tokenId, uint256 resourcesClaimed);
    event CreatureListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event CreatureBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event CreatureListingCancelled(uint256 listingId);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

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

    modifier creatureExists(uint256 _tokenId) {
        require(ownerOf[_tokenId] != address(0), "Creature does not exist.");
        _;
    }

    modifier onlyCreatureOwner(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this creature.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(creatureListings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier listingOwner(uint256 _listingId) {
        require(creatureListings[_listingId].seller == msg.sender, "You are not the seller of this listing.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].proposalEndTime && !proposals[_proposalId].executed, "Proposal is not active or already executed.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
        paused = false;

        // Initialize default evolution stage metadata suffixes
        evolutionStageMetadataSuffixes[0] = "_stage0";
        evolutionStageMetadataSuffixes[1] = "_stage1";
        evolutionStageMetadataSuffixes[2] = "_stage2";
        evolutionStageMetadataSuffixes[3] = "_stage3";

        // Initialize default game parameters
        gameParameters["initialResourceAmount"] = 50; // Example parameter
        gameParameters["marketplaceFeePercentage"] = 2; // Example parameter (2%)
    }

    // --- ERC721 Core Functions ---
    function mintCreature(string memory _name, string memory _metadataURI) public whenNotPaused {
        uint256 tokenId = nextTokenId++;
        ownerOf[tokenId] = msg.sender;
        balanceOf[msg.sender]++;
        creatures[tokenId] = Creature({
            name: _name,
            evolutionStage: 0,
            lastResourceClaimTime: block.timestamp
        });
        emit CreatureMinted(tokenId, msg.sender, _name);
    }

    function transferCreature(address _to, uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        _transfer(_tokenId, _to);
    }

    function approve(address _approved, uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        _approve(_approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view creatureExists(_tokenId) returns (address) {
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function tokenURI(uint256 _tokenId) public view creatureExists(_tokenId) returns (string memory) {
        string memory stageSuffix = evolutionStageMetadataSuffixes[creatures[_tokenId].evolutionStage];
        return string(abi.encodePacked(baseURI, _toString(_tokenId), stageSuffix, ".json")); // Example URI construction
    }

    // --- Evolution & Staking Functions ---
    function evolveCreature(uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        require(creatures[_tokenId].evolutionStage < maxEvolutionStage, "Creature is already at max evolution stage.");

        uint256 currentResources = getResourceBalance(_tokenId);
        require(currentResources >= evolutionCost, "Not enough resources to evolve.");

        // Deduct evolution cost (example - in a real game, resources would be tracked separately)
        creatures[_tokenId].lastResourceClaimTime = block.timestamp; // Reset claim time after evolution cost is "spent"

        // Simulate evolution outcome with randomness (basic example)
        uint256 randomNumber = _generateRandomNumber(_tokenId);
        if (randomNumber % 2 == 0) { // 50% chance of successful evolution (example)
            creatures[_tokenId].evolutionStage++;
            emit CreatureEvolved(_tokenId, creatures[_tokenId].evolutionStage);
        } else {
            // Evolution failed (can add failure logic, like resource loss, or nothing happens)
            // For now, just emit an event or log if needed.
        }
    }

    function stakeCreature(uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        require(stakedCreatureIds[_tokenId] == 0, "Creature is already staked.");
        stakedCreatureIds[_tokenId] = _tokenId;
        stakedTime[_tokenId] = block.timestamp;
        emit CreatureStaked(_tokenId);
    }

    function unstakeCreature(uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        require(stakedCreatureIds[_tokenId] == _tokenId, "Creature is not staked.");
        uint256 resources = claimResources(_tokenId); // Automatically claim resources on unstake
        delete stakedCreatureIds[_tokenId];
        delete stakedTime[_tokenId];
        emit CreatureUnstaked(_tokenId, resources);
    }

    function claimResources(uint256 _tokenId) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        require(stakedCreatureIds[_tokenId] == _tokenId, "Creature is not staked.");
        uint256 timeElapsed = block.timestamp - stakedTime[_tokenId];
        uint256 resourcesEarned = (timeElapsed * resourceGenerationRate) / 3600; // Resources per hour
        creatures[_tokenId].lastResourceClaimTime = block.timestamp; // Update last claim time
        emit CreatureUnstaked(_tokenId, resourcesEarned); // Reusing unstaked event for simplicity, consider a separate 'ResourcesClaimed' event
        return resourcesEarned; // Return claimed resources (in a real game, resources would be managed separately)
    }

    function getResourceBalance(uint256 _tokenId) public view creatureExists(_tokenId) onlyCreatureOwner(_tokenId) returns (uint256) {
        if (stakedCreatureIds[_tokenId] != _tokenId) {
            return 0; // Not staked, no resources
        }
        uint256 timeElapsed = block.timestamp - stakedTime[_tokenId];
        uint256 resourcesEarned = (timeElapsed * resourceGenerationRate) / 3600; // Resources per hour
        return resourcesEarned;
    }

    function getEvolutionStage(uint256 _tokenId) public view creatureExists(_tokenId) returns (uint8) {
        return creatures[_tokenId].evolutionStage;
    }

    // --- Marketplace Functions ---
    function listCreatureForSale(uint256 _tokenId, uint256 _price) public whenNotPaused creatureExists(_tokenId) onlyCreatureOwner(_tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this creature.");
        require(creatureListings[nextListingId].tokenId == 0, "Listing ID collision, try again."); // Basic collision check
        creatureListings[nextListingId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        _approve(address(this), _tokenId); // Approve contract to transfer NFT on sale
        emit CreatureListed(nextListingId, _tokenId, msg.sender, _price);
        nextListingId++;
    }

    function buyCreature(uint256 _listingId) public payable whenNotPaused validListing(_listingId) {
        Listing storage listing = creatureListings[_listingId];
        require(listing.seller != msg.sender, "Cannot buy your own listing.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        // Transfer NFT
        _transferFrom(listing.seller, msg.sender, listing.tokenId);

        // Transfer funds to seller (and handle marketplace fees if implemented)
        payable(listing.seller).transfer(listing.price); // Simple transfer - consider secure transfer patterns in production

        // Deactivate listing
        listing.isActive = false;
        emit CreatureBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelCreatureListing(uint256 _listingId) public whenNotPaused validListing(_listingId) listingOwner(_listingId) {
        creatureListings[_listingId].isActive = false;
        _approve(address(0), creatureListings[_listingId].tokenId); // Remove contract approval
        emit CreatureListingCancelled(_listingId);
    }

    function withdrawMarketplaceFunds() public onlyOwner {
        // In a more complex marketplace with fees, this function would withdraw accumulated fees.
        // For this example, it's a placeholder, as we don't have fees implemented.
        // Implement fee logic and withdrawal here if needed in a real application.
    }

    // --- Governance Functions ---
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public whenNotPaused {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        proposals[nextProposalId] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndTime: block.timestamp + governanceVoteDuration,
            executed: false
        });
        emit ParameterProposalCreated(nextProposalId, _parameterName, _newValue);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        // In a more advanced DAO, voting power would be based on token holdings or staking.
        // For this simple example, each address gets one vote per proposal.
        // To prevent double voting, you would need to track who has voted (mapping(proposalId => mapping(voterAddress => bool)) voted).
        // This simplified version allows voting for demonstration.

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].proposalEndTime, "Proposal voting is still active.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 percentageFor = (proposals[_proposalId].votesFor * 100) / totalVotes; // Basic percentage calculation

        if (percentageFor >= governanceThreshold) {
            setParameter(proposals[_proposalId].parameterName, proposals[_proposalId].newValue);
            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed - can add failure logic or emit an event if needed.
        }
    }

    // --- Admin Functions ---
    function setParameter(string memory _parameterName, uint256 _newValue) public onlyOwner {
        gameParameters[_parameterName] = _newValue;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setGovernanceThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold <= 100, "Governance threshold must be a percentage (<= 100).");
        governanceThreshold = _newThreshold;
    }

    // --- Internal Helper Functions ---
    function _transfer(uint256 _tokenId, address _to) internal {
        address from = ownerOf[_tokenId];
        require(from != address(0), "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, _to, _tokenId);

        _approve(address(0), _tokenId); // Clear approvals

        balanceOf[from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;

        emit Transfer(from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_tokenId, _to);
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf[_tokenId], _approved, _tokenId);
    }

    function _setApprovalForAll(address _owner, address _operator, bool _approved) internal {
        require(_owner != _operator, "ERC721: approve to caller");
        _operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        require(ownerOf[_tokenId] != address(0), "ERC721: nonexistent token");
        address ownerToken = ownerOf[_tokenId];
        return (_spender == ownerToken || getApproved(_tokenId) == _spender || isApprovedForAll(ownerToken, _spender));
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {
        // Can be used for hooks before token transfer if needed in future extensions
    }

    function _generateRandomNumber(uint256 _seed) private view returns (uint256) {
        // Simple pseudo-random number generation (NOT SECURE for critical randomness)
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, block.difficulty)));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // From OpenZeppelin Strings library (modified for inline)
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

    // --- ERC721 Interface Support (optional, but good practice) ---
    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }

    interface IERC721 is IERC165 {
        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

        function balanceOf(address owner) external view returns (uint256 balance);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
        function transferFrom(address from, address to, uint256 tokenId) external payable;
        function approve(address approved, uint256 tokenId) external payable;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function setApprovalForAll(address operator, bool approved) external payable;
        function isApprovedForAll(address owner, address operator) external view returns (bool);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // --- Fallback and Receive (optional) ---
    receive() external payable {} // To allow receiving ETH for marketplace purchases
    fallback() external {}
}
```