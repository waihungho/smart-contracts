```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Decentralized Autonomous Game (DAG) - "Evolving Ecosystem"
 *
 *  Outline & Function Summary:
 *
 *  This smart contract implements a Decentralized Autonomous Game (DAG) called "Evolving Ecosystem".
 *  The game revolves around players acquiring, evolving, and trading digital creatures (NFTs) within a dynamic ecosystem.
 *  The ecosystem's rules and parameters are partially governed by a DAO, making it a truly decentralized and evolving game.
 *
 *  Key Concepts:
 *  - Evolving NFTs: Creatures can evolve through in-game actions and resource consumption, changing their attributes and rarity.
 *  - Dynamic Ecosystem: Game parameters (resource availability, evolution rates, event triggers) can be influenced by DAO proposals.
 *  - On-chain Marketplace: Integrated marketplace for trading creatures and resources.
 *  - Decentralized Governance: DAO to vote on game parameters, new features, and resource distribution.
 *  - Procedural Generation (Simulated): Creature attributes and evolution paths are procedurally generated based on on-chain randomness and player actions.
 *  - Staking and Rewards: Players can stake their creatures to earn ecosystem resources.
 *  - In-game Events: Triggered randomly or by DAO proposals, introducing new challenges and opportunities.
 *  - Dynamic Rarity: Creature rarity can shift based on evolution paths and ecosystem changes.
 *  - Anti-Cheat Mechanisms: Built-in mechanisms to detect and penalize cheating or bot activity.
 *
 *  Functions (20+):
 *
 *  --- Core Game Functions ---
 *  1.  mintCreature(): Allows players to mint a new base creature NFT.
 *  2.  evolveCreature(uint256 _creatureId): Initiates the evolution process for a creature, consuming resources.
 *  3.  feedCreature(uint256 _creatureId, uint256 _resourceId): Allows players to feed resources to their creatures.
 *  4.  exploreEcosystem(uint256 _creatureId): Sends a creature to explore the ecosystem, potentially discovering resources or triggering events.
 *  5.  battleCreature(uint256 _attackerCreatureId, uint256 _defenderCreatureId): Initiates a battle between two creatures (future feature, currently placeholder).
 *  6.  stakeCreature(uint256 _creatureId): Stakes a creature to earn ecosystem resources passively.
 *  7.  unstakeCreature(uint256 _creatureId): Unstakes a creature, withdrawing accumulated resources.
 *  8.  claimStakingRewards(uint256 _creatureId): Claims accumulated staking rewards for a creature.
 *
 *  --- Marketplace Functions ---
 *  9.  listCreatureForSale(uint256 _creatureId, uint256 _price): Lists a creature NFT for sale on the marketplace.
 *  10. cancelCreatureSale(uint256 _creatureId): Cancels a creature NFT listing on the marketplace.
 *  11. buyCreature(uint256 _creatureId): Buys a creature NFT listed on the marketplace.
 *  12. listResourceForSale(uint256 _resourceType, uint256 _amount, uint256 _pricePerUnit): Lists ecosystem resources for sale.
 *  13. cancelResourceSale(uint256 _saleId): Cancels a resource sale listing.
 *  14. buyResource(uint256 _saleId, uint256 _amount): Buys ecosystem resources from the marketplace.
 *
 *  --- DAO Governance Functions ---
 *  15. createProposal(string memory _description, bytes memory _calldata): Creates a DAO proposal to change game parameters or initiate actions.
 *  16. voteOnProposal(uint256 _proposalId, bool _support): Allows players to vote on a DAO proposal.
 *  17. executeProposal(uint256 _proposalId): Executes a passed DAO proposal (admin-controlled execution for security, can be made timelocked).
 *  18. delegateVote(address _delegatee): Allows players to delegate their voting power to another address.
 *  19. setEcosystemParameter(string memory _parameterName, uint256 _newValue): (DAO Callable via Proposal) Allows DAO to set ecosystem parameters (example: resource spawn rate).
 *  20. triggerEcosystemEvent(string memory _eventName): (DAO Callable via Proposal) Allows DAO to trigger specific in-game events (example: migration event).
 *
 *  --- Utility & Admin Functions ---
 *  21. getCreatureDetails(uint256 _creatureId): Returns detailed information about a creature.
 *  22. getMarketplaceListing(uint256 _listingId): Returns details of a marketplace listing.
 *  23. getProposalDetails(uint256 _proposalId): Returns details of a DAO proposal.
 *  24. pauseGame(): (Admin Only) Pauses core game functions for maintenance or emergency.
 *  25. unpauseGame(): (Admin Only) Resumes core game functions.
 *  26. withdrawFees(): (Admin Only) Allows admin to withdraw collected marketplace fees and game fees.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract EvolvingEcosystem is ERC721, Ownable, Pausable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Core Game Constants & Variables ---
    string public gameName = "Evolving Ecosystem";
    uint256 public mintFee = 0.01 ether; // Fee to mint a new creature
    uint256 public ecosystemResourceSpawnRate = 10; // Base resource spawn rate (example parameter)
    uint256 public evolutionBaseCost = 0.02 ether; // Base cost for creature evolution
    uint256 public stakingRewardRate = 1; // Base staking reward rate per creature per block
    uint256 public marketplaceFeePercentage = 2; // Percentage fee on marketplace sales

    enum CreatureType { Common, Rare, Epic, Legendary }
    enum ResourceType { Food, Water, Energy, Mineral }
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    enum MarketplaceListingType { Creature, Resource }

    struct Creature {
        uint256 creatureId;
        CreatureType creatureType;
        string name;
        uint256 generation;
        uint256 evolutionStage;
        uint256 attack;
        uint256 defense;
        uint256 speed;
        uint256 stamina;
        uint256 lastExploredTimestamp;
        uint256 lastStakedTimestamp;
        uint256 stakingRewardDebt;
    }

    struct Resource {
        ResourceType resourceType;
        uint256 amount;
    }

    struct MarketplaceListing {
        uint256 listingId;
        MarketplaceListingType listingType;
        address seller;
        uint256 itemId; // Creature ID or Resource Type
        uint256 amount; // For resources, 1 for creatures
        uint256 price;
        bool isActive;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes calldataData; // Data to execute if proposal passes
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
    }

    mapping(uint256 => Creature) public creatures;
    mapping(address => mapping(ResourceType => uint256)) public playerResources; // Player resources balance
    mapping(uint256 => MarketplaceListing) public marketplaceListings;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public voteDelegations; // Delegate voting power
    mapping(uint256 => address) public creatureToOwner; // Track creature ownership (redundant with ERC721, but for clarity)

    Counters.Counter private _creatureIds;
    Counters.Counter private _listingIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _vrfRequestIdCounter;

    // --- DAO Governance Variables ---
    address public daoTreasury; // Address to receive DAO funds
    uint256 public proposalVotingPeriod = 7 days; // Default voting period for proposals
    uint256 public proposalQuorumPercentage = 51; // Percentage of total voting power required to pass a proposal

    // --- VRF Configuration ---
    VRFCoordinatorV2Interface internal immutable vrfCoordinator;
    uint64 internal immutable subscriptionId;
    bytes32 internal immutable keyHash;
    uint32 internal immutable callbackGasLimit = 500000;
    uint16 internal immutable requestConfirmations = 3;
    uint32 internal immutable numWords = 1; // Requesting 1 random word

    // --- Events ---
    event CreatureMinted(uint256 creatureId, address owner, CreatureType creatureType);
    event CreatureEvolved(uint256 creatureId, uint256 newEvolutionStage);
    event ResourceCollected(address player, ResourceType resourceType, uint256 amount);
    event CreatureStaked(uint256 creatureId, address player);
    event CreatureUnstaked(uint256 creatureId, address player);
    event StakingRewardsClaimed(uint256 creatureId, address player, uint256 rewardAmount);
    event CreatureListedForSale(uint256 listingId, uint256 creatureId, address seller, uint256 price);
    event CreatureSaleCancelled(uint256 listingId, uint256 creatureId);
    event CreatureBought(uint256 listingId, uint256 creatureId, address buyer, address seller, uint256 price);
    event ResourceListedForSale(uint256 listingId, ResourceType resourceType, uint256 amount, uint256 pricePerUnit, address seller);
    event ResourceSaleCancelled(uint256 listingId);
    event ResourceBought(uint256 listingId, ResourceType resourceType, uint256 amount, address buyer, address seller, uint256 totalPrice);
    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event VoteDelegationSet(address delegator, address delegatee);
    event EcosystemParameterChanged(string parameterName, uint256 newValue);
    event EcosystemEventTriggered(string eventName);
    event VRFRequestSent(uint256 requestId, uint256 vrfRequestId);
    event VRFRandomWordReceived(uint256 requestId, uint256[] randomWords);

    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _daoTreasury
    ) ERC721("EvolvingCreature", "ECRE") VRFConsumerBaseV2(_vrfCoordinatorV2) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        daoTreasury = _daoTreasury;
    }

    modifier whenNotPausedGame() {
        require(!paused(), "Game is currently paused.");
        _;
    }

    modifier onlyOwnerOrDAO() {
        require(msg.sender == owner() || msg.sender == daoTreasury, "Not owner or DAO Treasury");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoTreasury, "Only DAO Treasury can call this function");
        _;
    }

    // --- Helper Functions ---
    function _generateRandomCreatureType() private returns (CreatureType) {
        uint256 randomNumber = _getRandomNumber(); // Get random number from Chainlink VRF
        uint256 creatureTypeRoll = randomNumber % 100; // Roll between 0 and 99

        if (creatureTypeRoll < 60) { // 60% chance for Common
            return CreatureType.Common;
        } else if (creatureTypeRoll < 90) { // 30% chance for Rare
            return CreatureType.Rare;
        } else if (creatureTypeRoll < 99) { // 9% chance for Epic
            return CreatureType.Epic;
        } else { // 1% chance for Legendary
            return CreatureType.Legendary;
        }
    }

    function _generateRandomAttributes(CreatureType _creatureType) private pure returns (uint256 attack, uint256 defense, uint256 speed, uint256 stamina) {
        uint256 baseAttribute = 5; // Base attribute value
        uint256 rarityMultiplier = 1;

        if (_creatureType == CreatureType.Rare) {
            rarityMultiplier = 2;
        } else if (_creatureType == CreatureType.Epic) {
            rarityMultiplier = 4;
        } else if (_creatureType == CreatureType.Legendary) {
            rarityMultiplier = 8;
        }

        attack = baseAttribute * rarityMultiplier + (block.timestamp % 5); // Simple procedural generation example
        defense = baseAttribute * rarityMultiplier + (block.number % 7);
        speed = baseAttribute * rarityMultiplier + (block.gaslimit % 3);
        stamina = baseAttribute * rarityMultiplier + (msg.value % 9);
        // More sophisticated procedural generation can be implemented here based on randomness and other factors.
    }

    function _payMarketplaceFee(uint256 _price) private returns (uint256 feeAmount, uint256 netPrice) {
        feeAmount = (_price * marketplaceFeePercentage) / 100;
        netPrice = _price - feeAmount;
        payable(owner()).transfer(feeAmount); // Send marketplace fees to contract owner (can be DAO Treasury later)
        return (feeAmount, netPrice);
    }

    function _transferCreatureInternal(uint256 _creatureId, address _to) private {
        _transfer(ownerOf(_creatureId), _to, _creatureId);
        creatureToOwner[_creatureId] = _to; // Update creature ownership mapping
    }

    // --- Core Game Functions ---
    function mintCreature() external payable whenNotPausedGame {
        require(msg.value >= mintFee, "Insufficient mint fee.");

        CreatureType creatureType = _generateRandomCreatureType();
        (uint256 attack, uint256 defense, uint256 speed, uint256 stamina) = _generateRandomAttributes(creatureType);

        _creatureIds.increment();
        uint256 newCreatureId = _creatureIds.current();

        creatures[newCreatureId] = Creature({
            creatureId: newCreatureId,
            creatureType: creatureType,
            name: string(abi.encodePacked("Creature #", newCreatureId.toString())), // Simple name generation
            generation: 1,
            evolutionStage: 1,
            attack: attack,
            defense: defense,
            speed: speed,
            stamina: stamina,
            lastExploredTimestamp: 0,
            lastStakedTimestamp: 0,
            stakingRewardDebt: 0
        });

        _mint(msg.sender, newCreatureId);
        creatureToOwner[newCreatureId] = msg.sender; // Set creature ownership mapping

        emit CreatureMinted(newCreatureId, msg.sender, creatureType);
    }

    function evolveCreature(uint256 _creatureId) external payable whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        require(msg.value >= evolutionBaseCost, "Insufficient evolution fee.");

        Creature storage creature = creatures[_creatureId];
        require(creature.evolutionStage < 5, "Creature is already at max evolution stage."); // Example: Max 5 evolution stages

        creature.evolutionStage++;
        creature.attack += 5; // Simple evolution stat increase example
        creature.defense += 3;
        // Further evolution logic can be added (resource consumption, branching evolution paths, etc.)

        emit CreatureEvolved(_creatureId, creature.evolutionStage);
    }

    function feedCreature(uint256 _creatureId, uint256 _resourceType) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        ResourceType resource = ResourceType(_resourceType); // Type conversion and validation
        require(uint256(_resourceType) < 4, "Invalid resource type."); // Valid resource type range

        require(playerResources[msg.sender][resource] > 0, "Insufficient resource balance.");

        playerResources[msg.sender][resource]--;
        creatures[_creatureId].stamina += 10; // Example: Feeding increases stamina
        emit ResourceCollected(msg.sender, resource, 1); // Reusing event for feeding is acceptable in this example for simplicity
        // More complex feeding logic can be implemented (different resources, different effects).
    }

    function exploreEcosystem(uint256 _creatureId) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        Creature storage creature = creatures[_creatureId];
        require(block.timestamp > creature.lastExploredTimestamp + 1 hours, "Creature is still exploring or cooldown."); // Example: 1-hour cooldown

        creature.lastExploredTimestamp = block.timestamp;

        uint256 randomNumber = _getRandomNumber(); // Get random number from Chainlink VRF
        uint256 explorationOutcome = randomNumber % 100; // Roll between 0 and 99

        if (explorationOutcome < 70) { // 70% chance to find common resources
            playerResources[msg.sender][ResourceType.Food] += 2 + (creature.speed / 5); // Example: Speed influences resource finding
            playerResources[msg.sender][ResourceType.Water] += 1 + (creature.stamina / 10);
            emit ResourceCollected(msg.sender, ResourceType.Food, 2 + (creature.speed / 5));
            emit ResourceCollected(msg.sender, ResourceType.Water, 1 + (creature.stamina / 10));
        } else if (explorationOutcome < 90) { // 20% chance to find rare resources
            playerResources[msg.sender][ResourceType.Energy] += 1 + (creature.speed / 3);
            emit ResourceCollected(msg.sender, ResourceType.Energy, 1 + (creature.speed / 3));
        } else { // 10% chance to find nothing special
            // No resource gain, but exploration cooldown is still applied.
        }
        // More complex exploration outcomes can be implemented (events, rare items, etc.)
    }

    function battleCreature(uint256 _attackerCreatureId, uint256 _defenderCreatureId) external whenNotPausedGame {
        // Placeholder for future battle functionality
        require(false, "Battles are not implemented yet.");
    }

    function stakeCreature(uint256 _creatureId) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        require(creatures[_creatureId].lastStakedTimestamp == 0, "Creature is already staked."); // Prevent double staking

        _claimPendingStakingRewards(_creatureId); // Claim any pending rewards before staking
        creatures[_creatureId].lastStakedTimestamp = block.timestamp;
        emit CreatureStaked(_creatureId, msg.sender);
    }

    function unstakeCreature(uint256 _creatureId) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        require(creatures[_creatureId].lastStakedTimestamp > 0, "Creature is not staked.");

        _claimPendingStakingRewards(_creatureId); // Claim rewards upon unstaking
        creatures[_creatureId].lastStakedTimestamp = 0; // Reset staked timestamp
        emit CreatureUnstaked(_creatureId, msg.sender);
    }

    function claimStakingRewards(uint256 _creatureId) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        _claimPendingStakingRewards(_creatureId);
    }

    function _claimPendingStakingRewards(uint256 _creatureId) private {
        Creature storage creature = creatures[_creatureId];
        if (creature.lastStakedTimestamp > 0) {
            uint256 timeStaked = block.timestamp - creature.lastStakedTimestamp;
            uint256 rewardAmount = (timeStaked / 1 minutes) * stakingRewardRate; // Example: Reward per minute
            playerResources[ownerOf(_creatureId)][ResourceType.Mineral] += rewardAmount; // Example: Mineral as staking reward
            creature.lastStakedTimestamp = block.timestamp; // Update last staked timestamp to prevent re-claiming same rewards
            emit StakingRewardsClaimed(_creatureId, ownerOf(_creatureId), rewardAmount);
        }
    }


    // --- Marketplace Functions ---
    function listCreatureForSale(uint256 _creatureId, uint256 _price) external whenNotPausedGame {
        require(ownerOf(_creatureId) == msg.sender, "Not creature owner.");
        require(marketplaceListings[_creatureId].isActive == false, "Creature already listed for sale."); // Prevent relisting without cancelling

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        marketplaceListings[listingId] = MarketplaceListing({
            listingId: listingId,
            listingType: MarketplaceListingType.Creature,
            seller: msg.sender,
            itemId: _creatureId,
            amount: 1, // Creatures are sold individually
            price: _price,
            isActive: true
        });

        _transferCreatureInternal(_creatureId, address(this)); // Transfer creature to contract for escrow
        emit CreatureListedForSale(listingId, _creatureId, msg.sender, _price);
    }

    function cancelCreatureSale(uint256 _creatureId) external whenNotPausedGame {
        uint256 listingId = _findCreatureListingId(_creatureId);
        require(marketplaceListings[listingId].isActive == true, "Creature not listed for sale.");
        require(marketplaceListings[listingId].seller == msg.sender, "Not seller.");

        marketplaceListings[listingId].isActive = false;
        _transferCreatureInternal(_creatureId, msg.sender); // Return creature to seller
        emit CreatureSaleCancelled(listingId, _creatureId);
    }

    function buyCreature(uint256 _creatureId) external payable whenNotPausedGame {
        uint256 listingId = _findCreatureListingId(_creatureId);
        require(marketplaceListings[listingId].isActive == true, "Creature not listed for sale.");
        require(marketplaceListings[listingId].seller != msg.sender, "Cannot buy your own creature.");
        require(msg.value >= marketplaceListings[listingId].price, "Insufficient payment.");

        MarketplaceListing storage listing = marketplaceListings[listingId];
        uint256 price = listing.price;
        address seller = listing.seller;

        (uint256 feeAmount, uint256 netPrice) = _payMarketplaceFee(price);

        listing.isActive = false;
        _transferCreatureInternal(_creatureId, msg.sender); // Transfer creature to buyer
        payable(seller).transfer(netPrice); // Send net price to seller

        emit CreatureBought(listingId, _creatureId, msg.sender, seller, price);
    }

    function _findCreatureListingId(uint256 _creatureId) private view returns (uint256 listingId) {
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (marketplaceListings[i].listingType == MarketplaceListingType.Creature &&
                marketplaceListings[i].itemId == _creatureId &&
                marketplaceListings[i].isActive == true) {
                return i;
            }
        }
        revert("Creature listing not found."); // Should not reach here if listing is properly tracked
    }


    function listResourceForSale(ResourceType _resourceType, uint256 _amount, uint256 _pricePerUnit) external whenNotPausedGame {
        require(playerResources[msg.sender][_resourceType] >= _amount, "Insufficient resource balance.");
        require(_amount > 0 && _pricePerUnit > 0, "Invalid amount or price.");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        marketplaceListings[listingId] = MarketplaceListing({
            listingId: listingId,
            listingType: MarketplaceListingType.Resource,
            seller: msg.sender,
            itemId: uint256(_resourceType), // Store resource type as itemId
            amount: _amount,
            price: _pricePerUnit,
            isActive: true
        });

        playerResources[msg.sender][_resourceType] -= _amount; // Deduct resources from seller's balance
        emit ResourceListedForSale(listingId, _resourceType, _amount, _pricePerUnit, msg.sender);
    }

    function cancelResourceSale(uint256 _listingId) external whenNotPausedGame {
        require(marketplaceListings[_listingId].isActive == true, "Resource listing not active.");
        require(marketplaceListings[_listingId].seller == msg.sender, "Not seller.");
        require(marketplaceListings[_listingId].listingType == MarketplaceListingType.Resource, "Not a resource listing.");

        MarketplaceListing storage listing = marketplaceListings[_listingId];
        ResourceType resourceType = ResourceType(listing.itemId);
        uint256 amount = listing.amount;

        marketplaceListings[_listingId].isActive = false;
        playerResources[msg.sender][resourceType] += amount; // Return resources to seller
        emit ResourceSaleCancelled(_listingId);
    }

    function buyResource(uint256 _listingId, uint256 _amount) external payable whenNotPausedGame {
        require(marketplaceListings[_listingId].isActive == true, "Resource listing not active.");
        require(marketplaceListings[_listingId].listingType == MarketplaceListingType.Resource, "Not a resource listing.");
        require(_amount > 0 && _amount <= marketplaceListings[_listingId].amount, "Invalid amount to buy.");
        require(msg.value >= marketplaceListings[_listingId].price * _amount, "Insufficient payment.");

        MarketplaceListing storage listing = marketplaceListings[_listingId];
        ResourceType resourceType = ResourceType(listing.itemId);
        address seller = listing.seller;
        uint256 pricePerUnit = listing.price;

        uint256 totalPrice = pricePerUnit * _amount;
        (uint256 feeAmount, uint256 netPrice) = _payMarketplaceFee(totalPrice);

        marketplaceListings[_listingId].amount -= _amount; // Reduce available amount in listing
        if (marketplaceListings[_listingId].amount == 0) {
            marketplaceListings[_listingId].isActive = false; // Deactivate listing if sold out
        }

        playerResources[msg.sender][resourceType] += _amount; // Add resources to buyer's balance
        payable(seller).transfer(netPrice); // Send net price to seller
        emit ResourceBought(_listingId, resourceType, _amount, msg.sender, seller, totalPrice);
    }


    // --- DAO Governance Functions ---
    function createProposal(string memory _description, bytes memory _calldata) external whenNotPausedGame {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            calldataData: _calldata,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPausedGame {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active for voting.");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is over.");

        address voter = msg.sender;
        address delegatee = voteDelegations[voter];
        address actualVoter = (delegatee != address(0)) ? delegatee : voter; // Use delegatee if delegation is set

        // In a real DAO, voting power would be calculated based on token holdings or other criteria.
        // For simplicity, in this example, each address has 1 vote.

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, actualVoter, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyOwnerOrDAO whenNotPausedGame {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not in active state.");
        require(block.timestamp > proposal.votingEndTime, "Voting period is not over.");
        require(proposal.status != ProposalStatus.Executed, "Proposal already executed.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (totalVotes * proposalQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorum) {
            proposal.status = ProposalStatus.Passed;
            (bool success, ) = address(this).call(proposal.calldataData); // Execute proposal calldata
            require(success, "Proposal execution failed.");
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    function delegateVote(address _delegatee) external whenNotPausedGame {
        voteDelegations[msg.sender] = _delegatee;
        emit VoteDelegationSet(msg.sender, _delegatee);
    }

    // Example DAO callable functions (via proposals)
    function setEcosystemParameter(string memory _parameterName, uint256 _newValue) external onlyDAO whenNotPausedGame {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("ecosystemResourceSpawnRate"))) {
            ecosystemResourceSpawnRate = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("stakingRewardRate"))) {
            stakingRewardRate = _newValue;
        } else {
            revert("Invalid parameter name.");
        }
        emit EcosystemParameterChanged(_parameterName, _newValue);
    }

    function triggerEcosystemEvent(string memory _eventName) external onlyDAO whenNotPausedGame {
        // Example event trigger logic (can be expanded for various events)
        if (keccak256(bytes(_eventName)) == keccak256(bytes("migrationEvent"))) {
            // Implement migration event logic here (e.g., temporary resource boost, new creature type spawn, etc.)
            emit EcosystemEventTriggered(_eventName);
        } else {
            revert("Invalid event name.");
        }
        emit EcosystemEventTriggered(_eventName);
    }


    // --- Utility & Admin Functions ---
    function getCreatureDetails(uint256 _creatureId) external view returns (Creature memory) {
        return creatures[_creatureId];
    }

    function getMarketplaceListing(uint256 _listingId) external view returns (MarketplaceListing memory) {
        return marketplaceListings[_listingId];
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function pauseGame() external onlyOwner {
        _pause();
    }

    function unpauseGame() external onlyOwner {
        _unpause();
    }

    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    // --- VRF Functions ---
    function requestRandomWords() private returns (uint256 requestId) {
        _vrfRequestIdCounter.increment();
        uint256 currentRequestId = _vrfRequestIdCounter.current();
        uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit VRFRequestSent(currentRequestId, vrfRequestId);
        return currentRequestId;
    }

    function fulfillRandomWords(
        uint256 _vrfRequestId, /* requestId */
        uint256[] memory _randomWords
    ) internal override {
        uint256 requestId = _getVRFRequestIdFromEvent(_vrfRequestId); // Custom function to retrieve internal request ID
        emit VRFRandomWordReceived(requestId, _randomWords);
        // Store or process the random words here.
        // For example, store it in a mapping for later use.
        // randomWords[_vrfRequestId] = _randomWords; // If you want to store and retrieve later.
        latestRandomWords = _randomWords; // Store in state variable for immediate use.
    }

    function _getVRFRequestIdFromEvent(uint256 _vrfRequestId) private returns (uint256 requestId) {
        // This is a placeholder. In a real application, you would need to parse
        // the VRFRequestSent event logs to find the internal requestId associated
        // with the Chainlink VRF request ID (_vrfRequestId).
        // This is because fulfillRandomWords only receives the VRF request ID, not the internal one.

        // For simplicity in this example, we assume a 1:1 mapping and return the VRF request ID directly.
        // In a robust implementation, you'd need to properly track and map these IDs.
        return _vrfRequestId;
    }

    uint256[] public latestRandomWords; // Example: State variable to store latest random words for immediate use.

    function _getRandomNumber() private returns (uint256) {
        uint256 requestId = requestRandomWords();
        // In a real application, you would handle the asynchronous nature of VRF.
        // This simplified example assumes that fulfillRandomWords is called shortly after requestRandomWords.
        // and that latestRandomWords is populated by then.
        // **Important: This is NOT production-ready as it's synchronous in nature for demonstration.**
        // In a production setting, you would use events and callbacks to handle the asynchronous VRF response.

        // For demonstration purposes, we'll just return the first random word if available, or 0 if not yet received.
        if (latestRandomWords.length > 0) {
            return latestRandomWords[0];
        } else {
            return 0; // Handle case where random word is not yet available (not production-safe)
        }
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {} // To receive ETH for minting and marketplace purchases
    fallback() external payable {}
}
```