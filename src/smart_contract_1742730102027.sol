```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Gemini
 * @dev A smart contract implementing a dynamic and evolving NFT system with advanced features.
 *
 * Function Summary:
 *
 * **NFT Management & Minting:**
 * 1. mintNFT(address _to, string memory _baseURI): Mints a new NFT to the specified address.
 * 2. batchMintNFT(address _to, uint256 _count, string memory _baseURI): Mints multiple NFTs at once to the specified address.
 * 3. setBaseURI(string memory _newBaseURI): Sets the base URI for NFT metadata (admin only).
 * 4. tokenURI(uint256 _tokenId): Returns the URI for a specific NFT token.
 * 5. burnNFT(uint256 _tokenId): Burns (destroys) an NFT (owner or approved operator only).
 * 6. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer function, extended with custom logic.
 *
 * **Dynamic Evolution & Attributes:**
 * 7. triggerEvolution(uint256 _tokenId): Initiates the evolution process for an NFT, based on time and randomness.
 * 8. getNFTStage(uint256 _tokenId): Returns the current evolution stage of an NFT.
 * 9. getNFTAttributes(uint256 _tokenId): Returns a struct containing dynamic attributes of an NFT.
 * 10. setEvolutionTime(uint256 _newTime): Sets the time required for evolution (admin only).
 * 11. setAttributeWeight(string memory _attributeName, uint256 _weight): Sets the weight for attribute generation during evolution (admin only).
 *
 * **Staking & Utility:**
 * 12. stakeNFT(uint256 _tokenId): Allows users to stake their NFTs for utility benefits.
 * 13. unstakeNFT(uint256 _tokenId): Allows users to unstake their NFTs.
 * 14. getStakingStatus(uint256 _tokenId): Returns the staking status of an NFT.
 * 15. setStakingRewardRate(uint256 _newRate): Sets the reward rate for staking (admin only). (Placeholder, actual reward system needs further definition)
 *
 * **Governance & Community Features:**
 * 16. proposeCommunityEvent(string memory _eventName, uint256 _startTime, uint256 _endTime, string memory _details): Allows NFT holders to propose community events.
 * 17. voteOnEventProposal(uint256 _proposalId, bool _vote): Allows NFT holders to vote on event proposals.
 * 18. getEventProposalDetails(uint256 _proposalId): Returns details of a community event proposal.
 *
 * **Advanced & Unique Features:**
 * 19. whitelistMint(address _to, bytes32[] memory _merkleProof, string memory _baseURI): Mints NFT to whitelisted address using Merkle Proof.
 * 20. createAirdropCampaign(address[] memory _recipients, string memory _baseURI): Creates and executes an NFT airdrop campaign to a list of addresses (admin only).
 * 21. setApprovedOperator(address _operator, bool _approved): Allows setting an approved operator for NFT management beyond standard approvals (admin only).
 * 22. isApprovedOperator(address _operator, uint256 _tokenId): Checks if an address is an approved operator for a specific NFT.
 *
 * **Events:**
 * - NFTMinted(uint256 tokenId, address to)
 * - NFTBurned(uint256 tokenId, address owner)
 * - NFTEvolved(uint256 tokenId, uint256 newStage)
 * - NFTStaked(uint256 tokenId, address owner)
 * - NFTUnstaked(uint256 tokenId, address owner)
 * - CommunityEventProposed(uint256 proposalId, string eventName, address proposer)
 * - CommunityEventVoteCast(uint256 proposalId, address voter, bool vote)
 * - ApprovedOperatorSet(address operator, bool approved)
 */
contract DynamicNFTEvolution is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;
    string private _baseTokenURI;

    // Evolution Parameters
    uint256 public evolutionTime = 7 days; // Time required for evolution
    uint256 public lastEvolutionTimestamp;
    uint256 public currentStage = 1;

    // NFT Stages (Example, can be expanded)
    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Evolved }
    mapping(uint256 => EvolutionStage) public nftStage;

    // Dynamic NFT Attributes
    struct NFTAttributes {
        uint256 level;
        uint256 power;
        uint256 agility;
        uint256 intelligence;
        uint256 stageMultiplier; // Multiplier based on evolution stage
        uint256 rarityScore; // Score based on attribute values
    }
    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(string => uint256) public attributeWeights; // Weights for attribute generation

    // Staking
    mapping(uint256 => bool) public isNFTStaked;
    uint256 public stakingRewardRate = 1; // Placeholder reward rate (per block or time unit) - needs more complex implementation

    // Community Event Proposals
    struct EventProposal {
        string eventName;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        string details;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
    }
    mapping(uint256 => EventProposal) public eventProposals;
    Counters.Counter private _proposalIds;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => voted

    // Whitelist Minting
    bytes32 public merkleRoot;

    // Approved Operators - for extended management
    mapping(address => mapping(uint256 => bool)) public approvedOperators; // operator => tokenId => isApproved

    // Chainlink VRF Configuration
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    LinkTokenInterface private immutable linkToken;
    bytes32 private immutable vrfKeyHash;
    uint64 private immutable subscriptionId;
    uint32 private immutable requestConfirmations = 3;
    uint32 private immutable numWords = 1;
    uint256 public vrfFee = 0.1 * 10**18; // 0.1 LINK fee for VRF request

    // Events
    event NFTMinted(uint256 tokenId, address to);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTEvolved(uint256 tokenId, uint256 newStage);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event CommunityEventProposed(uint256 proposalId, string eventName, address proposer);
    event CommunityEventVoteCast(uint256 proposalId, address voter, bool vote);
    event ApprovedOperatorSet(address operator, bool approved);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _vrfCoordinatorV2,
        address _linkToken,
        bytes32 _vrfKeyHash,
        uint64 _subscriptionId
    ) ERC721(_name, _symbol) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        _baseTokenURI = _baseURI;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        linkToken = LinkTokenInterface(_linkToken);
        vrfKeyHash = _vrfKeyHash;
        subscriptionId = _subscriptionId;

        // Initialize attribute weights (example)
        attributeWeights["level"] = 20;
        attributeWeights["power"] = 30;
        attributeWeights["agility"] = 25;
        attributeWeights["intelligence"] = 25;
    }

    /**
     * @dev Override _beforeTokenTransfer to implement custom logic during token transfers.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add custom logic here before every token transfer if needed, e.g., check for staking status, etc.
        if (isNFTStaked[tokenId]) {
            require(to == address(this) || to == from, "Cannot transfer staked NFT to a new owner directly. Unstake first.");
            // Allow transfer back to owner or to the contract itself (for internal operations, if needed)
        }
    }

    /**
     * @dev Override _burn to implement custom logic when burning tokens.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        address owner = ownerOf(tokenId);
        super._burn(tokenId);
        delete nftStage[tokenId];
        delete nftAttributes[tokenId];
        delete isNFTStaked[tokenId];
        delete approvedOperators[msg.sender][tokenId];
        emit NFTBurned(tokenId, owner);
    }

    /**
     * @dev Sets the base URI for all token metadata. Only owner can call.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId The token ID.
     * @return The URI string for the token.
     */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
    }

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI Base URI for the NFT metadata.
     * @return The ID of the newly minted NFT.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_baseURI, newItemId.toString(), ".json")));

        // Initialize NFT stage and attributes
        nftStage[newItemId] = EvolutionStage.Egg;
        nftAttributes[newItemId] = _generateInitialAttributes();

        emit NFTMinted(newItemId, _to);
        return newItemId;
    }

    /**
     * @dev Batch mints multiple NFTs to the specified address.
     * @param _to The address to mint NFTs to.
     * @param _count The number of NFTs to mint.
     * @param _baseURI Base URI for the NFTs metadata.
     */
    function batchMintNFT(address _to, uint256 _count, string memory _baseURI) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            mintNFT(_to, _baseURI); // Reusing mintNFT for simplicity, can optimize for gas if needed
        }
    }

    /**
     * @dev Burns (destroys) an NFT. Only the owner or an approved operator can burn.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId) || isApprovedOperator(_msgSender(), _tokenId), "Burner is not owner or approved operator");
        _burn(_tokenId);
    }

    /**
     * @dev Initiate the evolution process for an NFT. Requires time elapsed and requests randomness from Chainlink VRF.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function triggerEvolution(uint256 _tokenId) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        require(nftStage[_tokenId] != EvolutionStage.Evolved, "NFT is already fully evolved");
        require(block.timestamp >= lastEvolutionTimestamp + evolutionTime, "Evolution cooldown not reached");

        lastEvolutionTimestamp = block.timestamp; // Update global evolution timestamp

        // Request randomness from Chainlink VRF to determine evolution outcome
        uint256 requestId = requestRandomWords();
        s_requestIdToTokenId[requestId] = _tokenId; // Store token ID associated with request
    }

    mapping(uint256 => uint256) private s_requestIdToTokenId;

    /**
     * @dev Callback function from Chainlink VRF with random words.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords Array of random words (only one word expected in this contract).
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 tokenId = s_requestIdToTokenId[_requestId];
        require(_exists(tokenId), "Token ID not found for VRF request");

        _evolveNFT(tokenId, _randomWords[0]);
        delete s_requestIdToTokenId[_requestId]; // Clean up mapping
    }

    /**
     * @dev Internal function to handle the actual NFT evolution logic.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _randomWord Random number from Chainlink VRF.
     */
    function _evolveNFT(uint256 _tokenId, uint256 _randomWord) internal {
        EvolutionStage currentStageEnum = nftStage[_tokenId];
        EvolutionStage nextStageEnum;
        uint256 newStageNumber = uint256(currentStageEnum) + 1; // Increment stage number

        if (newStageNumber > uint256(EvolutionStage.Evolved)) {
            nextStageEnum = EvolutionStage.Evolved; // Cap at Evolved stage
        } else {
            nextStageEnum = EvolutionStage(newStageNumber);
        }

        nftStage[_tokenId] = nextStageEnum;
        nftAttributes[_tokenId] = _generateEvolvedAttributes(nftAttributes[_tokenId], nextStageEnum, _randomWord); // Update attributes based on new stage

        emit NFTEvolved(_tokenId, newStageNumber);
    }


    /**
     * @dev Sets the time duration required between evolutions. Only owner can call.
     * @param _newTime The new evolution time in seconds.
     */
    function setEvolutionTime(uint256 _newTime) public onlyOwner {
        evolutionTime = _newTime;
    }

    /**
     * @dev Sets the weight for a specific attribute used in attribute generation. Only owner can call.
     * @param _attributeName The name of the attribute (e.g., "power", "agility").
     * @param _weight The new weight for the attribute.
     */
    function setAttributeWeight(string memory _attributeName, uint256 _weight) public onlyOwner {
        attributeWeights[_attributeName] = _weight;
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution stage enum.
     */
    function getNFTStage(uint256 _tokenId) public view returns (EvolutionStage) {
        return nftStage[_tokenId];
    }

    /**
     * @dev Returns the dynamic attributes of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTAttributes struct containing the attributes.
     */
    function getNFTAttributes(uint256 _tokenId) public view returns (NFTAttributes memory) {
        return nftAttributes[_tokenId];
    }

    /**
     * @dev Generates initial attributes for a newly minted NFT. (Example logic)
     * @return NFTAttributes struct with initial attributes.
     */
    function _generateInitialAttributes() internal view returns (NFTAttributes memory) {
        return NFTAttributes({
            level: 1,
            power: 10,
            agility: 10,
            intelligence: 10,
            stageMultiplier: 100,
            rarityScore: 30 // Base score
        });
    }

    /**
     * @dev Generates evolved attributes based on the current attributes, next stage, and randomness. (Example logic)
     * @param _currentAttributes Current attributes of the NFT.
     * @param _nextStage The next evolution stage.
     * @param _randomWord Random number from VRF.
     * @return NFTAttributes struct with evolved attributes.
     */
    function _generateEvolvedAttributes(NFTAttributes memory _currentAttributes, EvolutionStage _nextStage, uint256 _randomWord) internal view returns (NFTAttributes memory) {
        uint256 stageMultiplierIncrease = 25; // Percentage increase per stage

        NFTAttributes memory evolvedAttributes = _currentAttributes;
        evolvedAttributes.level += 1;
        evolvedAttributes.stageMultiplier = _currentAttributes.stageMultiplier + (_currentAttributes.stageMultiplier * stageMultiplierIncrease / 100); // Increase stage multiplier

        // Apply randomness to attribute growth (example - can be more sophisticated)
        uint256 randomnessFactor = _randomWord % 100; // 0-99 range for randomness

        evolvedAttributes.power += (attributeWeights["power"] * randomnessFactor / 100);
        evolvedAttributes.agility += (attributeWeights["agility"] * randomnessFactor / 100);
        evolvedAttributes.intelligence += (attributeWeights["intelligence"] * randomnessFactor / 100);

        // Recalculate rarity score (example - can be based on a more complex formula)
        evolvedAttributes.rarityScore = evolvedAttributes.power + evolvedAttributes.agility + evolvedAttributes.intelligence + evolvedAttributes.level * 5;

        return evolvedAttributes;
    }


    /**
     * @dev Allows users to stake their NFTs.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        require(!isNFTStaked[_tokenId], "NFT is already staked");

        isNFTStaked[_tokenId] = true;
        // Transfer NFT to contract (optional, depending on staking mechanism)
        // safeTransferFrom(_msgSender(), address(this), _tokenId);

        emit NFTStaked(_tokenId, _msgSender());
    }

    /**
     * @dev Allows users to unstake their NFTs.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        require(isNFTStaked[_tokenId], "NFT is not staked");

        isNFTStaked[_tokenId] = false;
        // Transfer NFT back to owner (if transferred to contract during staking)
        // safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit NFTUnstaked(_tokenId, _msgSender());
    }

    /**
     * @dev Returns the staking status of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function getStakingStatus(uint256 _tokenId) public view returns (bool) {
        return isNFTStaked[_tokenId];
    }

    /**
     * @dev Sets the staking reward rate. Only owner can call.
     * @param _newRate The new staking reward rate. (Placeholder - needs actual reward mechanism)
     */
    function setStakingRewardRate(uint256 _newRate) public onlyOwner {
        stakingRewardRate = _newRate;
    }

    /**
     * @dev Allows NFT holders to propose a community event.
     * @param _eventName Name of the event.
     * @param _startTime Unix timestamp for event start time.
     * @param _endTime Unix timestamp for event end time.
     * @param _details Details of the event.
     */
    function proposeCommunityEvent(string memory _eventName, uint256 _startTime, uint256 _endTime, string memory _details) public {
        require(_exists(tokenOfOwnerByIndex(_msgSender(), 0)), "Must own at least one NFT to propose an event"); // Simple check - owner of at least one NFT
        require(_startTime < _endTime, "Start time must be before end time");
        require(_endTime > block.timestamp, "End time must be in the future");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        eventProposals[proposalId] = EventProposal({
            eventName: _eventName,
            proposer: _msgSender(),
            startTime: _startTime,
            endTime: _endTime,
            details: _details,
            yesVotes: 0,
            noVotes: 0,
            isActive: true
        });

        emit CommunityEventProposed(proposalId, _eventName, _msgSender());
    }

    /**
     * @dev Allows NFT holders to vote on an event proposal.
     * @param _proposalId The ID of the event proposal.
     * @param _vote True for yes, false for no.
     */
    function voteOnEventProposal(uint256 _proposalId, bool _vote) public {
        require(_exists(tokenOfOwnerByIndex(_msgSender(), 0)), "Must own at least one NFT to vote"); // Simple check - owner of at least one NFT
        require(eventProposals[_proposalId].isActive, "Proposal is not active");
        require(!hasVotedOnProposal[_proposalId][_msgSender()], "Already voted on this proposal");

        hasVotedOnProposal[_proposalId][_msgSender()] = true;
        if (_vote) {
            eventProposals[_proposalId].yesVotes++;
        } else {
            eventProposals[_proposalId].noVotes++;
        }

        emit CommunityEventVoteCast(_proposalId, _msgSender(), _vote);
        // Implement logic to process proposal outcomes based on votes (e.g., after a certain time or vote count)
    }

    /**
     * @dev Returns details of a community event proposal.
     * @param _proposalId The ID of the proposal.
     * @return EventProposal struct containing proposal details.
     */
    function getEventProposalDetails(uint256 _proposalId) public view returns (EventProposal memory) {
        return eventProposals[_proposalId];
    }

    /**
     * @dev Mints an NFT to a whitelisted address using a Merkle Proof.
     * @param _to The address to mint the NFT to.
     * @param _merkleProof Merkle proof for whitelist inclusion.
     * @param _baseURI Base URI for the NFT metadata.
     */
    function whitelistMint(address _to, bytes32[] memory _merkleProof, string memory _baseURI) public {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");
        require(_to == _msgSender(), "Recipient address must match sender"); // Optional - enforce msg.sender == _to

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_baseURI, newItemId.toString(), ".json")));

        nftStage[newItemId] = EvolutionStage.Egg; // Initialize stage and attributes for whitelisted mints too
        nftAttributes[newItemId] = _generateInitialAttributes();

        emit NFTMinted(newItemId, _to);
    }

    /**
     * @dev Sets the Merkle root for whitelist minting. Only owner can call.
     * @param _newMerkleRoot The new Merkle root.
     */
    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @dev Creates and executes an NFT airdrop campaign to a list of addresses. Only owner can call.
     * @param _recipients Array of recipient addresses.
     * @param _baseURI Base URI for the airdropped NFTs metadata.
     */
    function createAirdropCampaign(address[] memory _recipients, string memory _baseURI) public onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            mintNFT(_recipients[i], _baseURI); // Reuse mintNFT for airdrop, optimize for gas if needed for large airdrops
        }
    }

    /**
     * @dev Sets an approved operator for an NFT. Allows operators to manage NFTs on behalf of owners (beyond standard approvals). Only owner can call.
     * @param _operator The address of the operator to approve or disapprove.
     * @param _approved True to approve, false to disapprove.
     */
    function setApprovedOperator(address _operator, bool _approved) public onlyOwner {
        approvedOperators[_operator][_tokenIds.current()] = _approved; // Approves for all future NFTs minted after this call - consider tokenId input if needed for specific NFT approval
        emit ApprovedOperatorSet(_operator, _approved);
    }

    /**
     * @dev Checks if an address is an approved operator for a specific NFT.
     * @param _operator The address to check.
     * @param _tokenId The ID of the NFT.
     * @return True if approved operator, false otherwise.
     */
    function isApprovedOperator(address _operator, uint256 _tokenId) public view returns (bool) {
        return approvedOperators[_operator][_tokenId];
    }

    /**
     * @dev Safe transfer function, overridden for potential custom logic.
     * @param from address The address which you are transferring from.
     * @param to address The address which you are transferring to.
     * @param tokenId uint256 The token ID to be transferred.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        super.safeTransferFrom(from, to, tokenId);
        // Add any custom logic after safe transfer if needed.
    }


    // -------------------- Chainlink VRF Functions --------------------

    /**
     * @dev Requests randomness from Chainlink VRF.
     */
    function requestRandomWords() internal returns (uint256 requestId) {
        // Check LINK balance
        require(linkToken.balanceOf(address(this)) >= vrfFee, "Not enough LINK - fill contract with LINK");

        // Send the VRF request
        requestId = vrfCoordinator.requestRandomWords(
            vrfKeyHash,
            subscriptionId,
            requestConfirmations,
            numWords
        );
        return requestId;
    }

    /**
     * @dev Gets the VRF fee for a request.
     */
    function getVrfFee() public view returns (uint256) {
        return vrfFee;
    }

    /**
     * @dev Sets the VRF fee for requests. Only owner can call.
     */
    function setVrfFee(uint256 _newFee) public onlyOwner {
        vrfFee = _newFee;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```