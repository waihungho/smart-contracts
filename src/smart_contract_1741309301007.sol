```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Evolving Ecosystem NFT Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing Evolving Ecosystem NFTs, where NFTs can dynamically change based on various on-chain and potentially off-chain factors.
 *
 * **Outline:**
 *  - NFT Core Functionality (ERC721 base with extensions)
 *  - Dynamic Evolution System (Stages, Requirements, Triggers)
 *  - Ecosystem Interaction Mechanics (Resource Gathering, Collaborative Evolution)
 *  - Rarity and Attribute System (Evolving Traits, Generation)
 *  - Community Governance (Voting on Evolution Paths, Ecosystem Rules)
 *  - Oracle Integration (Optional - for external data influencing evolution)
 *  - Staking and Utility (NFT Staking for Ecosystem Benefits)
 *  - Marketplace Integration (Basic Listing/Delisting)
 *  - Anti-Tampering and Security Features
 *  - Admin and Governance Controls
 *
 * **Function Summary:**
 *  1. `mintEcosystemNFT(address _to, string memory _baseURI)`: Mints a new Evolving Ecosystem NFT to the specified address with an initial base URI.
 *  2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another, with custom transfer logic.
 *  3. `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT.
 *  4. `setApprovalForAllNFT(address _operator, bool _approved)`: Sets approval for an operator to manage all NFTs for the sender.
 *  5. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of a specific NFT.
 *  6. `checkEvolutionRequirements(uint256 _tokenId)`: Checks if an NFT meets the requirements for evolution to the next stage.
 *  7. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for an NFT if requirements are met, updating its stage and potentially attributes.
 *  8. `interactWithEcosystem(uint256 _tokenId, uint256 _interactionType)`: Allows users to interact with their NFTs within the ecosystem, potentially affecting evolution or attributes based on interaction type.
 *  9. `gatherEcosystemResource(uint256 _tokenId, uint256 _resourceType)`: Simulates gathering resources within the ecosystem using the NFT, potentially required for evolution.
 *  10. `collaborateForEvolution(uint256 _tokenId, uint256 _partnerTokenId)`: Allows two NFT holders to collaborate to trigger or enhance evolution for one or both NFTs.
 *  11. `getNFTRarityScore(uint256 _tokenId)`: Calculates and returns a rarity score for an NFT based on its current attributes and stage.
 *  12. `getNFTAttributes(uint256 _tokenId)`: Returns a struct containing the current attributes of an NFT, which can evolve over time.
 *  13. `proposeEvolutionPath(uint256 _tokenId, uint256 _nextStageDefinition)`: Allows NFT holders to propose new evolution paths or stage definitions (requires governance approval).
 *  14. `voteOnEvolutionPathProposal(uint256 _proposalId, bool _vote)`: Allows community members (potentially NFT holders) to vote on proposed evolution paths.
 *  15. `getStakeNFT(uint256 _tokenId)`: Stakes an NFT to participate in the ecosystem and potentially gain benefits.
 *  16. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT, removing it from ecosystem participation.
 *  17. `claimEcosystemRewards(uint256 _tokenId)`: Allows staked NFT holders to claim rewards accumulated from ecosystem participation.
 *  18. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale within a basic marketplace.
 *  19. `delistNFTForSale(uint256 _tokenId)`: Removes an NFT from the marketplace.
 *  20. `buyNFTFromMarketplace(uint256 _tokenId)`: Allows users to purchase an NFT listed in the marketplace.
 *  21. `pauseContract()`: Pauses core contract functionalities for emergency situations (Admin only).
 *  22. `unpauseContract()`: Resumes contract functionalities after pausing (Admin only).
 *  23. `setEvolutionCriteria(uint256 _stage, /* ... criteria parameters ... */)`: Allows the admin to set or update evolution criteria for different stages. (Admin only)
 *  24. `withdrawContractBalance()`: Allows the admin to withdraw contract balance (e.g., marketplace fees). (Admin only)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EvolvingEcosystemNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---
    struct NFTAttributes {
        uint256 stage;
        uint256 generation;
        uint256 power;
        uint256 agility;
        uint256 wisdom;
        // ... more attributes as needed ...
    }

    struct EvolutionCriteria {
        uint256 requiredStage;
        uint256 requiredResource1;
        uint256 requiredResource2;
        uint256 interactionCount;
        uint256 timeElapsed; // Example: Time-based evolution (consider block.timestamp)
        // ... other criteria ...
    }

    struct SaleListing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct EvolutionProposal {
        uint256 tokenId;
        uint256 nextStageDefinition; // Placeholder for actual stage definition data
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    // --- State Variables ---
    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(uint256 => EvolutionCriteria) public evolutionCriteria;
    mapping(uint256 => SaleListing) public nftMarketplaceListings;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => bool) public isNFTStaked;
    mapping(uint256 => uint256) public nftEcosystemRewards; // Example: Rewards per NFT

    string public baseURI;
    bool public contractPaused;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner);
    event NFTEvolved(uint256 tokenId, uint256 newStage);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTDelistedFromSale(uint256 tokenId, address seller);
    event NFTMarketplacePurchase(uint256 tokenId, address buyer, address seller, uint256 price);
    event EvolutionPathProposed(uint256 proposalId, uint256 tokenId, address proposer);
    event EvolutionPathVoteCast(uint256 proposalId, address voter, bool vote);

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        contractPaused = false;
    }

    // --- External Functions ---

    /**
     * @dev Mints a new Evolving Ecosystem NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURIForToken Optional base URI override for this specific token (consider metadata generation logic).
     */
    function mintEcosystemNFT(address _to, string memory _baseURIForToken) external onlyOwner {
        require(!contractPaused, "Contract is paused");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);

        // Initialize NFT attributes upon minting
        nftAttributes[tokenId] = NFTAttributes({
            stage: 1, // Starting stage
            generation: 1,
            power: 10,
            agility: 10,
            wisdom: 10
            // ... initialize other attributes ...
        });

        // Example Evolution Criteria for Stage 1 to 2 (can be modified/extended)
        evolutionCriteria[tokenId] = EvolutionCriteria({
            requiredStage: 1,
            requiredResource1: 100, // Example resource units
            requiredResource2: 50,
            interactionCount: 5,
            timeElapsed: block.timestamp + 7 days // 7 days from mint
            // ... other initial criteria ...
        });

        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Transfers an NFT from one address to another. Overriding ERC721 _transfer to add custom logic if needed.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approves an address to operate on a single NFT. Overriding ERC721 approve to add custom logic if needed.
     * @param _approved The address being approved.
     * @param _tokenId The ID of the NFT being approved.
     */
    function approveNFT(address _approved, uint256 _tokenId) external payable {
        require(!contractPaused, "Contract is paused");
        address owner = ERC721.ownerOf(_tokenId);
        require(msg.sender == owner || ERC721.getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "Not owner or approved");
        ERC721.approve(_approved, _tokenId);
    }

    /**
     * @dev Sets approval for an operator to manage all NFTs for the sender. Overriding ERC721 setApprovalForAll to add custom logic if needed.
     * @param _operator The address to act as operator.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAllNFT(address _operator, bool _approved) external {
        require(!contractPaused, "Contract is paused");
        ERC721.setApprovalForAll(_operator, _approved);
    }

    /**
     * @dev Returns the current evolution stage of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution stage of the NFT.
     */
    function getNFTStage(uint256 _tokenId) external view returns (uint256) {
        return nftAttributes[_tokenId].stage;
    }

    /**
     * @dev Checks if an NFT meets the requirements for evolution to the next stage.
     * @param _tokenId The ID of the NFT.
     * @return True if the NFT can evolve, false otherwise.
     */
    function checkEvolutionRequirements(uint256 _tokenId) external view returns (bool) {
        require(ERC721.exists(_tokenId), "NFT does not exist");
        EvolutionCriteria memory criteria = evolutionCriteria[_tokenId];
        NFTAttributes memory attributes = nftAttributes[_tokenId];

        // Example criteria check - Expand this logic based on your game/ecosystem rules
        if (attributes.stage < criteria.requiredStage) return false; // Already evolved beyond this criteria
        if (/* check for requiredResource1 >= criteria.requiredResource1 */ false) return false; // Replace with actual resource check
        if (/* check for requiredResource2 >= criteria.requiredResource2 */ false) return false; // Replace with actual resource check
        if (/* check for interactionCount >= criteria.interactionCount */ false) return false; // Replace with actual interaction count check
        if (block.timestamp < criteria.timeElapsed) return false; // Time not elapsed yet

        return true; // All criteria met
    }

    /**
     * @dev Triggers the evolution process for an NFT if requirements are met.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(checkEvolutionRequirements(_tokenId), "Evolution requirements not met");

        NFTAttributes storage attributes = nftAttributes[_tokenId];
        uint256 currentStage = attributes.stage;

        // Example evolution logic - Customize based on your design
        attributes.stage = currentStage + 1; // Increment stage
        attributes.power += 5; // Example attribute increase
        attributes.agility += 3;
        attributes.wisdom += 2;
        attributes.generation += 1; // Example: Generation increases on evolution

        // Update evolution criteria for the next stage (example - can be dynamically set)
        evolutionCriteria[_tokenId] = EvolutionCriteria({
            requiredStage: attributes.stage, // Criteria for next stage now
            requiredResource1: evolutionCriteria[_tokenId].requiredResource1 * 2, // Example: Increase resource requirement
            requiredResource2: evolutionCriteria[_tokenId].requiredResource2 * 2,
            interactionCount: evolutionCriteria[_tokenId].interactionCount + 5,
            timeElapsed: block.timestamp + 14 days // Example: Longer time for next evolution
            // ... adjust criteria for the next stage ...
        });

        emit NFTEvolved(_tokenId, attributes.stage);
    }

    /**
     * @dev Allows users to interact with their NFTs within the ecosystem. Interaction type can affect evolution or attributes.
     * @param _tokenId The ID of the NFT interacting.
     * @param _interactionType Type of interaction (e.g., 1=training, 2=exploration, etc. - define these in your ecosystem).
     */
    function interactWithEcosystem(uint256 _tokenId, uint256 _interactionType) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");

        // Example interaction logic based on _interactionType - Expand this based on your game mechanics
        if (_interactionType == 1) { // Training - Example interaction
            nftAttributes[_tokenId].power += 1; // Increase power slightly
            // ... other training effects ...
        } else if (_interactionType == 2) { // Exploration - Example interaction
            nftAttributes[_tokenId].agility += 1; // Increase agility slightly
            // ... other exploration effects (resource discovery?) ...
        } // ... add more interaction types and effects ...

        // Potentially track interaction count for evolution criteria
        evolutionCriteria[_tokenId].interactionCount++;
    }

    /**
     * @dev Simulates gathering resources within the ecosystem using the NFT. Resources might be required for evolution.
     * @param _tokenId The ID of the NFT gathering resources.
     * @param _resourceType Type of resource being gathered (e.g., 1=wood, 2=stone, etc. - define these).
     */
    function gatherEcosystemResource(uint256 _tokenId, uint256 _resourceType) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(isNFTStaked[_tokenId], "NFT must be staked to gather resources"); // Example: Staking requirement for resource gathering

        // Example resource gathering logic based on _resourceType and NFT attributes
        uint256 resourceAmount = 10; // Base amount
        if (_resourceType == 1) { // Wood gathering
            resourceAmount += nftAttributes[_tokenId].power / 5; // Power influences wood gathering
            // ... specific wood gathering logic ...
        } else if (_resourceType == 2) { // Stone gathering
            resourceAmount += nftAttributes[_tokenId].agility / 5; // Agility influences stone gathering
            // ... specific stone gathering logic ...
        } // ... add more resource types and gathering logic ...

        // **Important:** In a real application, you would likely have a separate resource management system
        // (e.g., another contract or mapping to track user resources). This function would update that resource balance.
        // For simplicity in this example, we are just simulating resource gathering.
        // In a complete system, consider emitting an event with the gathered resource type and amount.

        // Example: (Simulated) -  Pretend we're updating a resource balance somewhere.
        //  userResources[_tokenId][resourceType] += resourceAmount;  // Hypothetical resource tracking

        // For this example, we'll just emit an event to show resource gathering action
        // emit ResourceGathered(_tokenId, _resourceType, resourceAmount); // Define this event if needed.
        // (Not defined in this example to keep it concise, but highly recommended for real implementation)
    }

    /**
     * @dev Allows two NFT holders to collaborate to trigger or enhance evolution for one or both NFTs.
     * @param _tokenId The ID of the initiating NFT.
     * @param _partnerTokenId The ID of the partner NFT.
     */
    function collaborateForEvolution(uint256 _tokenId, uint256 _partnerTokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId) && ERC721.exists(_partnerTokenId), "One or both NFTs do not exist");
        require(ERC721.ownerOf(_partnerTokenId) != address(0), "Partner NFT not owned"); // Basic check, can be more robust

        // Example collaboration logic - Define collaboration benefits and requirements
        NFTAttributes storage attributes1 = nftAttributes[_tokenId];
        NFTAttributes storage attributes2 = nftAttributes[_partnerTokenId];

        if (attributes1.stage == attributes2.stage) {
            // Example: If NFTs are same stage, collaboration might boost evolution chance or give bonus attributes
            if (checkEvolutionRequirements(_tokenId)) {
                // Example: Collaboration might slightly reduce evolution requirements or boost attributes
                evolveNFT(_tokenId); // Evolve the initiating NFT
                nftAttributes[_tokenId].wisdom += 2; // Example bonus wisdom from collaboration
                // ... potentially evolve partner NFT too or give benefits to partner ...
            } else {
                // ... collaboration might still give minor benefits even if not evolving yet ...
            }
        } else {
            // Example: Collaboration between different stages might have different effects
            // ... define logic for different stage collaborations ...
        }

        // ... add more complex collaboration effects and conditions ...
    }

    /**
     * @dev Calculates and returns a rarity score for an NFT based on its current attributes and stage.
     * @param _tokenId The ID of the NFT.
     * @return The rarity score of the NFT.
     */
    function getNFTRarityScore(uint256 _tokenId) external view returns (uint256) {
        require(ERC721.exists(_tokenId), "NFT does not exist");
        NFTAttributes memory attributes = nftAttributes[_tokenId];

        // Example rarity calculation logic - Customize based on your rarity system
        uint256 rarityScore = attributes.stage * 100 + attributes.generation * 50 + attributes.power + attributes.agility + attributes.wisdom;
        // ... add more factors to rarity score calculation (e.g., specific attribute combinations, visual traits if metadata is dynamic) ...

        return rarityScore;
    }

    /**
     * @dev Returns a struct containing the current attributes of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTAttributes struct containing the attributes.
     */
    function getNFTAttributes(uint256 _tokenId) external view returns (NFTAttributes memory) {
        require(ERC721.exists(_tokenId), "NFT does not exist");
        return nftAttributes[_tokenId];
    }

    /**
     * @dev Allows NFT holders to propose new evolution paths or stage definitions (requires governance approval).
     * @param _tokenId The ID of the NFT proposing the path.
     * @param _nextStageDefinition Placeholder for data defining the next evolution stage (struct, bytes, etc. - define structure).
     */
    function proposeEvolutionPath(uint256 _tokenId, uint256 _nextStageDefinition) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        evolutionProposals[proposalId] = EvolutionProposal({
            tokenId: _tokenId,
            nextStageDefinition: _nextStageDefinition, // Store the proposed stage definition (needs further definition)
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });

        emit EvolutionPathProposed(proposalId, _tokenId, msg.sender);
    }

    /**
     * @dev Allows community members (potentially NFT holders) to vote on proposed evolution paths.
     * @param _proposalId The ID of the evolution path proposal.
     * @param _vote True for vote in favor, false for vote against.
     */
    function voteOnEvolutionPathProposal(uint256 _proposalId, bool _vote) external {
        require(!contractPaused, "Contract is paused");
        require(evolutionProposals[_proposalId].isActive, "Proposal is not active");
        // Add logic for who can vote - e.g., NFT holders, DAO token holders, etc.
        // For simplicity, let's assume any address can vote once per proposal in this example.
        // In a real system, track voters per proposal to prevent multiple votes from same address.

        if (_vote) {
            evolutionProposals[_proposalId].votesFor++;
        } else {
            evolutionProposals[_proposalId].votesAgainst++;
        }

        emit EvolutionPathVoteCast(_proposalId, msg.sender, _vote);

        // Example: Check if proposal passed after vote - Define passing criteria (e.g., majority, quorum)
        if (evolutionProposals[_proposalId].votesFor > evolutionProposals[_proposalId].votesAgainst * 2 /* example: 2x more for votes than against */ ) {
            // Proposal passed - Implement logic to apply the new evolution path definition
            // (e.g., update evolutionCriteria, etc. - depends on how _nextStageDefinition is structured)
            evolutionProposals[_proposalId].isActive = false; // Deactivate proposal
            // ... logic to apply the proposed evolution path ...
        } else if (evolutionProposals[_proposalId].votesAgainst > evolutionProposals[_proposalId].votesFor * 2) {
            // Proposal failed
            evolutionProposals[_proposalId].isActive = false; // Deactivate proposal
            // ... optional logic for failed proposal ...
        }
    }

    /**
     * @dev Stakes an NFT to participate in the ecosystem and potentially gain benefits.
     * @param _tokenId The ID of the NFT to stake.
     */
    function getStakeNFT(uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(!isNFTStaked[_tokenId], "NFT already staked");

        isNFTStaked[_tokenId] = true;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT, removing it from ecosystem participation.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(isNFTStaked[_tokenId], "NFT not staked");

        isNFTStaked[_tokenId] = false;
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows staked NFT holders to claim rewards accumulated from ecosystem participation.
     * @param _tokenId The ID of the staked NFT claiming rewards.
     */
    function claimEcosystemRewards(uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(isNFTStaked[_tokenId], "NFT must be staked to claim rewards");
        require(nftEcosystemRewards[_tokenId] > 0, "No rewards to claim"); // Example: Check if rewards are available

        uint256 rewardsAmount = nftEcosystemRewards[_tokenId];
        nftEcosystemRewards[_tokenId] = 0; // Reset claimed rewards

        // **Important:** In a real application, rewards would likely be in tokens (ERC20/etc.).
        // This example assumes ETH for simplicity. Adjust based on your reward token.
        payable(msg.sender).transfer(rewardsAmount); // Transfer rewards to owner
    }

    /**
     * @dev Allows NFT owners to list their NFTs for sale within a basic marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei for the NFT.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(_price > 0, "Price must be greater than zero");
        require(!nftMarketplaceListings[_tokenId].isListed, "NFT already listed");

        nftMarketplaceListings[_tokenId] = SaleListing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });

        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Removes an NFT from the marketplace.
     * @param _tokenId The ID of the NFT to delist.
     */
    function delistNFTForSale(uint256 _tokenId) external {
        require(!contractPaused, "Contract is paused");
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(nftMarketplaceListings[_tokenId].isListed, "NFT not listed");
        require(nftMarketplaceListings[_tokenId].seller == msg.sender, "Only seller can delist");

        nftMarketplaceListings[_tokenId].isListed = false;
        emit NFTDelistedFromSale(_tokenId, msg.sender);
    }

    /**
     * @dev Allows users to purchase an NFT listed in the marketplace.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFTFromMarketplace(uint256 _tokenId) external payable {
        require(!contractPaused, "Contract is paused");
        require(ERC721.exists(_tokenId), "NFT does not exist");
        require(nftMarketplaceListings[_tokenId].isListed, "NFT not listed for sale");
        require(nftMarketplaceListings[_tokenId].seller != msg.sender, "Cannot buy your own NFT");

        SaleListing memory listing = nftMarketplaceListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        nftMarketplaceListings[_tokenId].isListed = false; // Delist after purchase
        _transfer(listing.seller, msg.sender, _tokenId); // Transfer NFT to buyer
        payable(listing.seller).transfer(listing.price); // Transfer funds to seller

        emit NFTMarketplacePurchase(_tokenId, msg.sender, listing.seller, listing.price);

        // Optional: Contract owner can take a fee from marketplace sales
        uint256 feePercentage = 2; // Example: 2% fee
        uint256 contractFee = (listing.price * feePercentage) / 100;
        if (contractFee > 0) {
            payable(owner()).transfer(contractFee);
        }
        // Return remaining ETH to buyer if overpaid
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }


    // --- Admin Functions ---

    /**
     * @dev Pauses core contract functionalities. Only callable by contract owner.
     */
    function pauseContract() external onlyOwner {
        contractPaused = true;
    }

    /**
     * @dev Resumes contract functionalities after pausing. Only callable by contract owner.
     */
    function unpauseContract() external onlyOwner {
        contractPaused = false;
    }

    /**
     * @dev Allows the admin to set or update evolution criteria for different stages.
     * @param _stage The stage to set criteria for.
     * @param _criteria The EvolutionCriteria struct containing the criteria.
     */
    function setEvolutionCriteria(uint256 _stage, EvolutionCriteria memory _criteria) external onlyOwner {
        // **Important**: In a real system, you might want to use a more dynamic way to manage criteria,
        // possibly with separate criteria IDs and more granular control.
        // This example is simplified for demonstration.
        // You would need to define the structure of `EvolutionCriteria` in detail and
        // decide which parameters you want to be configurable.
        // For this example, we'll assume you want to set criteria for a specific stage directly.

        // **Caution**: Be very careful when setting evolution criteria. Ensure they are balanced and well-tested.
        // Consider using a more robust governance mechanism for changing core game logic like evolution criteria in a production environment.

        // Example: Setting criteria for a specific stage
        // (This example assumes `_stage` directly corresponds to the stage number in `EvolutionCriteria.requiredStage`)
        // **This simplistic example might need adjustment based on your exact criteria structure and logic.**

        // Iterate through existing NFTs and update criteria if their current stage is less than or equal to _stage
        for (uint256 tokenId = 1; tokenId <= _tokenIdCounter.current(); tokenId++) {
            if (ERC721.exists(tokenId) && nftAttributes[tokenId].stage <= _stage) {
                evolutionCriteria[tokenId] = _criteria; // Directly overwrite criteria. **Careful with this approach.**
            }
        }
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance.
     * Useful for withdrawing marketplace fees or any accidentally sent ETH to the contract.
     */
    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // --- ERC721 Metadata override (Example - Adapt to your metadata needs) ---
    /**
     * @inheritdoc ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ERC721.exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        // **Dynamic Metadata Generation Example:**
        // You can modify the metadata based on NFT attributes, stage, etc. here.
        // For example, construct a JSON string or a URI to a dynamic metadata server.

        NFTAttributes memory attributes = nftAttributes[tokenId];
        string memory stageStr = Strings.toString(attributes.stage);
        string memory powerStr = Strings.toString(attributes.power);
        string memory agilityStr = Strings.toString(attributes.agility);
        string memory wisdomStr = Strings.toString(attributes.wisdom);

        string memory metadata = string(abi.encodePacked(
            '{ "name": "Evolving NFT #', tokenId.toString(), '",',
            ' "description": "An Evolving Ecosystem NFT, dynamically changing.",',
            ' "image": "ipfs://your_base_ipfs_cid/', tokenId.toString(), '.png",', // Replace with your IPFS CID and image naming
            ' "attributes": [',
            '{ "trait_type": "Stage", "value": "', stageStr, '" },',
            '{ "trait_type": "Power", "value": "', powerStr, '" },',
            '{ "trait_type": "Agility", "value": "', agilityStr, '" },',
            '{ "trait_type": "Wisdom", "value": "', wisdomStr, '" }',
            '] }'
        ));

        string memory jsonURI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
        return jsonURI;
    }

    // --- Internal Helper Functions ---
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || ERC721.getApproved(tokenId) == spender || isApprovedForAll(owner, spender) || owner == address(0)); // Added owner == address(0) to handle cases where token might be burned/removed (if you implement burning).
    }
}

// --- Base64 Encoding Library (For inline metadata - Optional, can use off-chain metadata server instead) ---
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        uint256 encodedLen = 4 * ((data.length + 2) / 3); // Equivalent to ceil(length / 3) * 4
        string memory result = new string(encodedLen);
        assembly {
            let table := add(TABLE, 1)
            let dataPtr := add(data, 32) // data is preceded by length

            mstore(result, encodedLen) // Store length of result string

            let resultPtr := add(result, 32) // result is preceded by length

            for { let i := 0 } lt(i, data.length) { i := add(i, 3) } {
                let byte1 := byte(i, mload(dataPtr))
                let byte2 := byte(add(1, i), mload(dataPtr))
                let byte3 := byte(add(2, i), mload(dataPtr))

                let idx1 := shr(2, byte1)
                let idx2 := shl(4, and(byte1, 0x3))
                idx2 := or(idx2, shr(4, byte2))
                let idx3 := shl(2, and(byte2, 0xf))
                idx3 := or(idx3, shr(6, byte3))
                let idx4 := and(byte3, 0x3f)

                mstore8(resultPtr, mload(add(table, idx1)))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(table, idx2)))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(table, idx3)))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(table, idx4)))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(data.length, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(24, 0x3d3d)) // '=='
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(16, 0x3d)) // '='
            }
        }
        return result;
    }
}
```

**Explanation and Advanced Concepts Used:**

1.  **Evolving Ecosystem NFTs:** The core concept is dynamic NFTs that evolve and change based on interactions within an imagined ecosystem. This goes beyond static NFTs.

2.  **Dynamic Evolution System:**
    *   **Stages and Attributes:** NFTs have stages and attributes (Power, Agility, Wisdom, etc.) that change as they evolve.
    *   **Evolution Criteria:** Evolution is not automatic. It's based on customizable criteria (resources, interactions, time, etc.). This adds a game-like element.
    *   **`evolveNFT()` function:**  This function checks criteria and progresses the NFT to the next stage, updating attributes and potentially resetting/updating evolution criteria for the next stage.

3.  **Ecosystem Interaction Mechanics:**
    *   **`interactWithEcosystem()`:**  A generic function to simulate various interactions within the ecosystem. Different `_interactionType` values can trigger different effects on NFT attributes or evolution progress.
    *   **`gatherEcosystemResource()`:** Simulates resource gathering, which can be a requirement for evolution.  **Important:** In a real application, you'd need a proper resource management system (separate contract/mapping) to track resources. This example is simplified.
    *   **`collaborateForEvolution()`:** Introduces a collaborative aspect. Two NFT holders can interact, potentially boosting evolution chances or providing benefits to each other.

4.  **Rarity and Attribute System:**
    *   **`getNFTRarityScore()`:**  Calculates a rarity score based on attributes and stage. Rarity can be more than just visual; it's tied to the NFT's in-game characteristics.
    *   **`getNFTAttributes()`:** Allows retrieval of the NFT's current attributes.

5.  **Community Governance (Basic Proposal/Voting):**
    *   **`proposeEvolutionPath()`:** NFT holders can propose new evolution paths or stage definitions. This is a very basic form of governance, where users can suggest changes.
    *   **`voteOnEvolutionPathProposal()`:**  A simple voting mechanism for the community to vote on proposed evolution paths. This is a rudimentary DAO-like feature.

6.  **Staking and Utility:**
    *   **`getStakeNFT()` and `unstakeNFT()`:** NFTs can be staked to participate in the ecosystem. Staking is often used for utility and reward distribution.
    *   **`claimEcosystemRewards()`:**  Staked NFTs can earn rewards (in this example, simplified to ETH, but in reality, it would be a token).

7.  **Marketplace Integration (Basic):**
    *   **`listNFTForSale()`, `delistNFTForSale()`, `buyNFTFromMarketplace()`:** Basic marketplace functionality to list, delist, and buy NFTs.  This is a common but essential feature.

8.  **Admin and Security:**
    *   **`pauseContract()` and `unpauseContract()`:** Emergency pause functionality for the contract owner.
    *   **`setEvolutionCriteria()`:** Admin function to adjust evolution rules. **Important**: In a real system, changing core game logic like evolution criteria should ideally be handled by more robust governance.
    *   **`withdrawContractBalance()`:**  Admin can withdraw contract funds (e.g., marketplace fees).
    *   **`Ownable` from OpenZeppelin:**  Used for admin access control.

9.  **Dynamic Metadata (Example in `tokenURI()`):**
    *   The `tokenURI()` function demonstrates how you can generate dynamic metadata based on the NFT's attributes and stage.  It creates inline JSON metadata using Base64 encoding. In a real application, you might use an off-chain metadata server for more complex and visually dynamic NFTs.

10. **Base64 Encoding Library:** Included for inline metadata encoding. You might not need this if you use an off-chain metadata server.

**Important Notes:**

*   **Simplifications:** This contract is a conceptual example. A real-world implementation would require much more detailed logic, error handling, security considerations, and potentially integration with oracles for external data, more robust resource management, and a proper token system for rewards and resources.
*   **Security:**  This is a simplified example and hasn't undergone rigorous security auditing.  In a production environment, thorough security audits are crucial.
*   **Customization:**  You'll need to heavily customize the evolution logic, interaction types, resource gathering, governance mechanisms, and metadata generation to fit your specific game or ecosystem design.
*   **Gas Optimization:**  For a real-world application, gas optimization would be important, especially with complex logic like evolution and interactions.

This example aims to provide a creative starting point and showcases several advanced concepts that can be combined to create interesting and dynamic NFT experiences. Remember to build upon this foundation and tailor it to your specific project requirements.