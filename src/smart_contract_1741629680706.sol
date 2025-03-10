```solidity
/**
 * @title Dynamic & Interactive NFT Platform with Evolving Traits and Social Interaction
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT platform where NFTs can evolve, interact, and participate in governance.
 *
 * **Outline & Function Summary:**
 *
 * **1. NFT Creation and Management:**
 *    - `createNFT(string memory _baseURI, string memory _initialTrait)`: Allows platform admin to create a new NFT collection with a base URI and initial trait.
 *    - `mintNFT(uint256 _collectionId, address _recipient)`: Mints a new NFT within a specific collection to a recipient.
 *    - `setBaseURI(uint256 _collectionId, string memory _newBaseURI)`: Allows platform admin to update the base URI for a collection.
 *    - `setNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _metadataURI)`: Allows platform admin to set specific metadata URI for an NFT (potentially for special NFTs).
 *    - `transferNFT(uint256 _collectionId, uint256 _tokenId, address _to)`: Allows NFT owner to transfer their NFT.
 *    - `burnNFT(uint256 _collectionId, uint256 _tokenId)`: Allows NFT owner to burn their NFT (permanently remove).
 *
 * **2. Dynamic Trait Evolution:**
 *    - `evolveNFT(uint256 _collectionId, uint256 _tokenId)`: Allows NFT owner to trigger an evolution process for their NFT based on certain conditions (e.g., time, interactions).
 *    - `setEvolutionCriteria(uint256 _collectionId, uint256 _evolutionStage, uint256 _requiredInteractionCount)`: Allows platform admin to set the criteria for NFT evolution stages (e.g., interactions needed).
 *    - `getNFTTraits(uint256 _collectionId, uint256 _tokenId)`: Returns the current traits of an NFT.
 *    - `getEvolutionStage(uint256 _collectionId, uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 *
 * **3. Social Interaction and Reputation:**
 *    - `interactWithNFT(uint256 _collectionId, uint256 _tokenId)`: Allows users to interact with an NFT, increasing its interaction count.
 *    - `getInteractionCount(uint256 _collectionId, uint256 _tokenId)`: Returns the interaction count of an NFT.
 *    - `setInteractionReward(uint256 _collectionId, uint256 _tokenId, uint256 _rewardAmount)`: Allows NFT owners to set a reward for users who interact with their NFT (potentially in platform tokens).
 *    - `claimInteractionReward(uint256 _collectionId, uint256 _tokenId)`: Allows users who interacted with an NFT to claim the interaction reward.
 *
 * **4. Platform Governance (Simplified):**
 *    - `proposeFeature(string memory _featureDescription)`: Allows platform users to propose new features for the platform.
 *    - `voteOnFeature(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on platform feature proposals.
 *    - `getProposalVotes(uint256 _proposalId)`: Returns the current vote count for a proposal.
 *    - `executeProposal(uint256 _proposalId)`: Allows platform admin to execute a successful feature proposal (simplified execution - just marks as executed).
 *
 * **5. Platform Utility and Configuration:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows platform admin to set a platform fee percentage for certain actions (e.g., marketplace in future).
 *    - `withdrawPlatformFees()`: Allows platform admin to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows platform admin to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows platform admin to unpause the contract.
 *    - `setInteractionCost(uint256 _cost)`: Allows platform admin to set a cost (in platform tokens or ETH) for interacting with NFTs.
 *
 * **Advanced Concepts Used:**
 * - **Dynamic NFTs:** NFTs that can evolve and change traits based on on-chain conditions and user interactions.
 * - **Social Interaction Layer:** Integrating social interaction mechanics directly into the NFT contract to enhance engagement.
 * - **Simplified Governance:** Basic on-chain governance for platform feature proposals, leveraging NFT holders for voting.
 * - **Reward System:** Incentivizing user interactions through on-chain rewards.
 *
 * **Important Notes:**
 * - This is a conceptual example and would require further development for production use, including security audits, gas optimization, and more robust governance and evolution logic.
 * - Error handling and access control are implemented for basic security, but more rigorous checks might be needed.
 * - This contract assumes a simplified token system for interaction rewards (you'd need to integrate with an ERC20 token for real rewards).
 */
pragma solidity ^0.8.0;

contract DynamicInteractiveNFTPlatform {
    // --- State Variables ---

    address public platformAdmin;
    uint256 public platformFeePercentage;
    bool public paused;
    uint256 public interactionCost;

    struct NFTCollection {
        string baseURI;
        string initialTrait; // Example: "Common"
        uint256 nextTokenId;
        mapping(uint256 => address) ownerOf;
        mapping(uint256 => string) tokenMetadataURI;
        mapping(uint256 => string[]) nftTraits; // Array of traits for each NFT
        mapping(uint256 => uint256) evolutionStage; // Current evolution stage of NFT
        mapping(uint256 => uint256) interactionCount; // Interaction count for each NFT
        mapping(uint256 => uint256) interactionRewardAmount; // Reward amount for interaction
    }

    mapping(uint256 => NFTCollection) public nftCollections;
    uint256 public nextCollectionId;

    struct EvolutionCriteria {
        uint256 requiredInteractionCount;
        // Could add more criteria like time elapsed, etc. in future
    }
    mapping(uint256 => mapping(uint256 => EvolutionCriteria)) public evolutionCriteria; // collectionId => evolutionStage => Criteria

    struct FeatureProposal {
        string description;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
    }
    mapping(uint256 => FeatureProposal) public featureProposals;
    uint256 public nextProposalId;

    mapping(address => uint256) public platformFeesBalance;

    // --- Events ---
    event NFTCollectionCreated(uint256 collectionId, string baseURI, string initialTrait);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address recipient);
    event NFTBaseURISet(uint256 collectionId, string newBaseURI);
    event NFTMetadataURISet(uint256 collectionId, uint256 tokenId, string metadataURI);
    event NFTTransferred(uint256 collectionId, uint256 tokenId, address from, address to);
    event NFTBurned(uint256 collectionId, uint256 tokenId);
    event NFTEvolved(uint256 collectionId, uint256 tokenId, uint256 newStage);
    event NFTInteraction(uint256 collectionId, uint256 tokenId, address interactor);
    event InteractionRewardSet(uint256 collectionId, uint256 tokenId, uint256 rewardAmount);
    event InteractionRewardClaimed(uint256 collectionId, uint256 tokenId, address claimant, uint256 rewardAmount);
    event FeatureProposed(uint256 proposalId, string description, address proposer);
    event FeatureVoted(uint256 proposalId, address voter, bool vote);
    event FeatureExecuted(uint256 proposalId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();
    event InteractionCostSet(uint256 cost);


    // --- Modifiers ---
    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can call this function.");
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

    modifier nftExists(uint256 _collectionId, uint256 _tokenId) {
        require(nftCollections[_collectionId].ownerOf[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier collectionExists(uint256 _collectionId) {
        require(_collectionId < nextCollectionId, "Collection does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        require(nftCollections[_collectionId].ownerOf[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    // --- Constructor ---
    constructor() {
        platformAdmin = msg.sender;
        platformFeePercentage = 0; // Default platform fee
        paused = false;
        interactionCost = 0; // Default interaction cost is free
    }

    // --- 1. NFT Creation and Management Functions ---

    /**
     * @dev Creates a new NFT collection. Only callable by platform admin.
     * @param _baseURI The base URI for the NFT collection metadata.
     * @param _initialTrait The initial trait assigned to NFTs in this collection.
     */
    function createNFT(string memory _baseURI, string memory _initialTrait) public onlyPlatformAdmin {
        uint256 collectionId = nextCollectionId++;
        nftCollections[collectionId] = NFTCollection({
            baseURI: _baseURI,
            initialTrait: _initialTrait,
            nextTokenId: 1,
            ownerOf: mapping(uint256 => address)(),
            tokenMetadataURI: mapping(uint256 => string)(),
            nftTraits: mapping(uint256 => string[])(),
            evolutionStage: mapping(uint256 => uint256)(),
            interactionCount: mapping(uint256 => uint256)(),
            interactionRewardAmount: mapping(uint256 => uint256)()
        });
        emit NFTCollectionCreated(collectionId, _baseURI, _initialTrait);
    }

    /**
     * @dev Mints a new NFT within a specific collection. Only callable by platform admin.
     * @param _collectionId The ID of the collection to mint into.
     * @param _recipient The address to receive the newly minted NFT.
     */
    function mintNFT(uint256 _collectionId, address _recipient) public onlyPlatformAdmin collectionExists(_collectionId) {
        uint256 tokenId = nftCollections[_collectionId].nextTokenId++;
        nftCollections[_collectionId].ownerOf[tokenId] = _recipient;
        nftCollections[_collectionId].nftTraits[tokenId].push(nftCollections[_collectionId].initialTrait); // Add initial trait
        nftCollections[_collectionId].evolutionStage[tokenId] = 1; // Start at stage 1
        emit NFTMinted(_collectionId, tokenId, _recipient);
    }

    /**
     * @dev Sets the base URI for a specific NFT collection. Only callable by platform admin.
     * @param _collectionId The ID of the collection to update.
     * @param _newBaseURI The new base URI for the collection.
     */
    function setBaseURI(uint256 _collectionId, string memory _newBaseURI) public onlyPlatformAdmin collectionExists(_collectionId) {
        nftCollections[_collectionId].baseURI = _newBaseURI;
        emit NFTBaseURISet(_collectionId, _newBaseURI);
    }

    /**
     * @dev Sets a specific metadata URI for a particular NFT in a collection. Only callable by platform admin.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _metadataURI The custom metadata URI for the NFT.
     */
    function setNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _metadataURI) public onlyPlatformAdmin collectionExists(_collectionId) nftExists(_collectionId, _tokenId) {
        nftCollections[_collectionId].tokenMetadataURI[_tokenId] = _metadataURI;
        emit NFTMetadataURISet(_collectionId, _tokenId, _metadataURI);
    }

    /**
     * @dev Transfers an NFT from the current owner to a new owner.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT to transfer.
     * @param _to The address of the new owner.
     */
    function transferNFT(uint256 _collectionId, uint256 _tokenId, address _to) public collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        require(_to != address(0), "Invalid recipient address.");
        nftCollections[_collectionId].ownerOf[_tokenId] = _to;
        emit NFTTransferred(_collectionId, _tokenId, msg.sender, _to);
    }

    /**
     * @dev Burns (destroys) an NFT. Only callable by the NFT owner.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _collectionId, uint256 _tokenId) public collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        delete nftCollections[_collectionId].ownerOf[_tokenId];
        delete nftCollections[_collectionId].tokenMetadataURI[_tokenId];
        delete nftCollections[_collectionId].nftTraits[_tokenId];
        delete nftCollections[_collectionId].evolutionStage[_tokenId];
        delete nftCollections[_collectionId].interactionCount[_tokenId];
        delete nftCollections[_collectionId].interactionRewardAmount[_tokenId];
        emit NFTBurned(_collectionId, _tokenId);
    }

    // --- 2. Dynamic Trait Evolution Functions ---

    /**
     * @dev Allows NFT owner to trigger evolution of their NFT. Evolution logic is simplified here (based on interaction count).
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _collectionId, uint256 _tokenId) public collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        uint256 currentStage = nftCollections[_collectionId].evolutionStage[_tokenId];
        uint256 nextStage = currentStage + 1;

        EvolutionCriteria storage criteria = evolutionCriteria[_collectionId][nextStage];
        if (criteria.requiredInteractionCount > 0 && nftCollections[_collectionId].interactionCount[_tokenId] >= criteria.requiredInteractionCount) {
            nftCollections[_collectionId].evolutionStage[_tokenId] = nextStage;
            nftCollections[_collectionId].nftTraits[_tokenId].push(string(abi.encodePacked("EvolvedTraitStage", Strings.toString(nextStage)))); // Add a new evolved trait (example)
            emit NFTEvolved(_collectionId, _tokenId, nextStage);
        } else {
            revert("Evolution criteria not met.");
        }
    }

    /**
     * @dev Sets the evolution criteria for a specific evolution stage in a collection. Only callable by platform admin.
     * @param _collectionId The ID of the collection.
     * @param _evolutionStage The evolution stage number.
     * @param _requiredInteractionCount The required interaction count to reach this stage.
     */
    function setEvolutionCriteria(uint256 _collectionId, uint256 _evolutionStage, uint256 _requiredInteractionCount) public onlyPlatformAdmin collectionExists(_collectionId) {
        evolutionCriteria[_collectionId][_evolutionStage] = EvolutionCriteria({
            requiredInteractionCount: _requiredInteractionCount
        });
    }

    /**
     * @dev Gets the current traits of an NFT.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @return An array of strings representing the NFT's traits.
     */
    function getNFTTraits(uint256 _collectionId, uint256 _tokenId) public view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (string[] memory) {
        return nftCollections[_collectionId].nftTraits[_tokenId];
    }

    /**
     * @dev Gets the current evolution stage of an NFT.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage number.
     */
    function getEvolutionStage(uint256 _collectionId, uint256 _tokenId) public view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (uint256) {
        return nftCollections[_collectionId].evolutionStage[_tokenId];
    }


    // --- 3. Social Interaction and Reputation Functions ---

    /**
     * @dev Allows users to interact with an NFT, increasing its interaction count.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT being interacted with.
     */
    function interactWithNFT(uint256 _collectionId, uint256 _tokenId) public payable collectionExists(_collectionId) nftExists(_collectionId, _tokenId) whenNotPaused {
        require(msg.value >= interactionCost, "Insufficient interaction cost paid."); // Require interaction cost (if set)

        nftCollections[_collectionId].interactionCount[_tokenId]++;
        emit NFTInteraction(_collectionId, _tokenId, msg.sender);

        // Transfer platform fee if applicable
        if (platformFeePercentage > 0) {
            uint256 feeAmount = (msg.value * platformFeePercentage) / 100;
            platformFeesBalance[platformAdmin] += feeAmount;
            payable(platformAdmin).transfer(feeAmount); // Immediate transfer of fee. Consider batching in real app for gas optimization
        }
        // Remaining value goes to contract (or could be distributed, etc. in more complex logic)
    }

    /**
     * @dev Gets the interaction count of an NFT.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @return The interaction count of the NFT.
     */
    function getInteractionCount(uint256 _collectionId, uint256 _tokenId) public view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (uint256) {
        return nftCollections[_collectionId].interactionCount[_tokenId];
    }

    /**
     * @dev Allows NFT owner to set a reward for users who interact with their NFT.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @param _rewardAmount The amount of reward for interaction (in platform tokens - simplified here, needs token integration in real app).
     */
    function setInteractionReward(uint256 _collectionId, uint256 _tokenId, uint256 _rewardAmount) public collectionExists(_collectionId) nftExists(_collectionId, _tokenId) onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        nftCollections[_collectionId].interactionRewardAmount[_tokenId] = _rewardAmount;
        emit InteractionRewardSet(_collectionId, _tokenId, _rewardAmount);
    }

    /**
     * @dev Allows users who interacted with an NFT to claim the interaction reward.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     */
    function claimInteractionReward(uint256 _collectionId, uint256 _tokenId) public whenNotPaused {
        // Simplified reward claiming - in real app, track who interacted and if they claimed already
        uint256 rewardAmount = nftCollections[_collectionId].interactionRewardAmount[_tokenId];
        require(rewardAmount > 0, "No reward set for this NFT.");

        // In a real application, you'd transfer platform tokens here instead of ETH
        payable(msg.sender).transfer(rewardAmount); // Simplified ETH transfer for example
        nftCollections[_collectionId].interactionRewardAmount[_tokenId] = 0; // Reset reward after claim (simplified)
        emit InteractionRewardClaimed(_collectionId, _tokenId, msg.sender, rewardAmount);
    }


    // --- 4. Platform Governance (Simplified) Functions ---

    /**
     * @dev Allows platform users to propose new features for the platform.
     * @param _featureDescription Description of the proposed feature.
     */
    function proposeFeature(string memory _featureDescription) public whenNotPaused {
        uint256 proposalId = nextProposalId++;
        featureProposals[proposalId] = FeatureProposal({
            description: _featureDescription,
            upvotes: 0,
            downvotes: 0,
            executed: false
        });
        emit FeatureProposed(proposalId, _featureDescription, msg.sender);
    }

    /**
     * @dev Allows NFT holders to vote on platform feature proposals. Voting power could be based on NFT holdings in real app.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnFeature(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(!featureProposals[_proposalId].executed, "Proposal already executed.");
        // Simplified voting - everyone gets 1 vote, in real app, voting power could be based on NFT holdings
        if (_vote) {
            featureProposals[_proposalId].upvotes++;
        } else {
            featureProposals[_proposalId].downvotes++;
        }
        emit FeatureVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Gets the current vote counts for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Upvote and downvote counts.
     */
    function getProposalVotes(uint256 _proposalId) public view returns (uint256 upvotes, uint256 downvotes) {
        return (featureProposals[_proposalId].upvotes, featureProposals[_proposalId].downvotes);
    }

    /**
     * @dev Allows platform admin to execute a successful feature proposal. Simplified execution - just marks as executed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyPlatformAdmin whenNotPaused {
        require(!featureProposals[_proposalId].executed, "Proposal already executed.");
        // In a real application, execution would involve implementing the proposed feature
        featureProposals[_proposalId].executed = true;
        emit FeatureExecuted(_proposalId);
    }


    // --- 5. Platform Utility and Configuration Functions ---

    /**
     * @dev Sets the platform fee percentage for certain actions (e.g., marketplace in future, interaction fees). Only callable by platform admin.
     * @param _feePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyPlatformAdmin {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Allows platform admin to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyPlatformAdmin {
        uint256 amount = platformFeesBalance[platformAdmin];
        platformFeesBalance[platformAdmin] = 0;
        payable(platformAdmin).transfer(amount);
        emit PlatformFeesWithdrawn(amount, platformAdmin);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing functions from being called. Only callable by platform admin.
     */
    function pauseContract() public onlyPlatformAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, allowing normal operations to resume. Only callable by platform admin.
     */
    function unpauseContract() public onlyPlatformAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Sets the cost for interacting with NFTs. Only callable by platform admin.
     * @param _cost The cost in wei (ETH).
     */
    function setInteractionCost(uint256 _cost) public onlyPlatformAdmin {
        interactionCost = _cost;
        emit InteractionCostSet(_cost);
    }

    // --- Helper Functions (Optional - for front-end or debugging) ---

    /**
     * @dev Gets the base URI for a collection.
     * @param _collectionId The ID of the collection.
     * @return The base URI string.
     */
    function getCollectionBaseURI(uint256 _collectionId) public view collectionExists(_collectionId) returns (string memory) {
        return nftCollections[_collectionId].baseURI;
    }

    /**
     * @dev Gets the owner of an NFT.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOf(uint256 _collectionId, uint256 _tokenId) public view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (address) {
        return nftCollections[_collectionId].ownerOf[_tokenId];
    }

    /**
     * @dev Gets the token URI for an NFT. Combines base URI and token ID.
     * @param _collectionId The ID of the collection.
     * @param _tokenId The ID of the NFT.
     * @return The token URI string.
     */
    function tokenURI(uint256 _collectionId, uint256 _tokenId) public view collectionExists(_collectionId) nftExists(_collectionId, _tokenId) returns (string memory) {
        string memory metadataURI = nftCollections[_collectionId].tokenMetadataURI[_tokenId];
        if (bytes(metadataURI).length > 0) { // If custom metadata URI is set, use it
            return metadataURI;
        } else {
            return string(abi.encodePacked(nftCollections[_collectionId].baseURI, Strings.toString(_tokenId), ".json")); // Default based on base URI and token ID
        }
    }
}

// --- Library for String Conversion (for tokenURI example) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```