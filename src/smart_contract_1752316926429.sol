Okay, let's design a smart contract that goes beyond standard NFTs or simple DeFi. We'll create a generative, dynamic NFT system focused on "Art Fusion" with built-in governance for evolving traits and a unique "Catalyst" mechanism.

This contract, `CryptoArtFusion`, will allow users to:
1.  Mint initial "Base" art NFTs.
2.  Fuse two existing NFTs (owned by the same user) to create a new, unique "Fusion" NFT.
3.  The Fusion process burns the parent NFTs and requires a special "Catalyst" token (managed internally).
4.  New traits for Fusion NFTs are generated based on the parent traits and some on-chain pseudo-randomness.
5.  Traits can potentially evolve or have dynamic components (represented in the `tokenURI`).
6.  Token holders can propose and vote on adding *new* trait values to the system, influencing future fusion possibilities.
7.  Includes standard ERC721, Enumerable, Metadata, and Royalties.

**Disclaimer:** On-chain randomness using `block.timestamp` and `block.difficulty` is *not* secure and can be manipulated by miners. For production systems, use a verifiable random function (VRF) like Chainlink VRF. Also, complex image generation based *purely* on traits is often done off-chain or through services; this contract focuses on generating *metadata* (traits, lineage, generation) on-chain and providing a URI.

---

**// SPDX-License-Identifier: MIT**
**pragma solidity ^0.8.20;**

**// Outline:**
**// 1. Imports (ERC721, Enumerable, Metadata, Ownable, Pausable, Royalties, Base64)**
**// 2. Errors & Events**
**// 3. Structs & Enums (TokenTraits, Proposal, ProposalState)**
**// 4. State Variables (Counters, Mappings for traits, lineage, generation, trait pools, governance, catalysts, etc.)**
**// 5. Modifiers (onlyOwner, whenNotPaused, whenPaused)**
**// 6. Constructor**
**// 7. ERC721 Overrides (supportsInterface, tokenURI)**
**// 8. Core Art Fusion Logic (mintBaseToken, fuseTokens)**
**// 9. Trait Management (addTraitType, addTraitValue - admin/governance)**
**// 10. Catalyst Management (mintCatalyst - admin, burnCatalyst - internal)**
**// 11. Information & Getter Functions (getTokenTraits, getTokenGeneration, getTokenParents, balanceOfCatalyst, etc.)**
**// 12. Governance Functions (createProposal, voteOnProposal, executeProposal)**
**// 13. Admin & Utility Functions (setBaseMintPrice, withdrawFunds, pause, unpause)**
**// 14. Internal Helper Functions (_generateFusionTraits, _getRandomValue, _toString, etc.)**

**// Function Summary:**
**// - supportsInterface(bytes4 interfaceId): ERC165 standard support check.**
**// - tokenURI(uint256 tokenId): Generates metadata URI for a token based on its on-chain traits, generation, and lineage.**
**// - mintBaseToken(): Allows users to mint initial Base tokens (paid).**
**// - fuseTokens(uint256 parentId1, uint256 parentId2): Fuses two parent tokens into a new Fusion token, burning parents and consuming Catalyst.**
**// - addTraitType(string memory traitType): Admin/Governance adds a new type of trait.**
**// - addTraitValue(string memory traitType, string memory traitValue): Admin/Governance adds a specific value for an existing trait type.**
**// - mintCatalyst(address recipient, uint256 amount): Admin mints Catalyst tokens to a recipient.**
**// - balanceOfCatalyst(address owner): Gets the Catalyst balance of an address.**
**// - getTokenTraits(uint256 tokenId): Returns the traits of a specific token.**
**// - getTokenGeneration(uint256 tokenId): Returns the generation number of a token (0 for Base, 1+ for Fusions).**
**// - getTokenParents(uint256 tokenId): Returns the parent token IDs of a Fusion token.**
**// - createProposal(string memory description, string memory traitType, string memory traitValue): Allows token holders to propose adding a new trait value.**
**// - voteOnProposal(uint256 proposalId, bool support): Allows token holders to vote on a proposal.**
**// - executeProposal(uint256 proposalId): Executes a successful proposal to add a trait value.**
**// - setBaseMintPrice(uint256 price): Admin sets the price for minting Base tokens.**
**// - withdrawFunds(): Admin withdraws collected contract balance.**
**// - pause(): Admin pauses core operations (minting, fusing).**
**// - unpause(): Admin unpauses core operations.**
**// - renounceOwnership(): Renounces ownership (from Ownable).**
**// - transferOwnership(address newOwner): Transfers ownership (from Ownable).**
**// - royaltyInfo(uint256 tokenId, uint256 salePrice): ERC2981 royalty calculation.**
**// - setDefaultRoyalty(address receiver, uint96 feeNumerator): Sets default royalty (from ERC2981).**
**// - _generateFusionTraits(uint256 parentId1, uint256 parentId2, uint256 newGeneration): Internal helper to generate new traits for a fusion token.**
**// - _getRandomValue(uint256 maxValue): Internal helper for pseudo-random number generation (INSECURE for production).**
**// - _burnCatalyst(address owner, uint256 amount): Internal helper to burn Catalyst tokens.**
**// - _mintCatalyst(address recipient, uint256 amount): Internal helper to mint Catalyst tokens.**
**// - _updateTokenTraits(uint256 tokenId, TokenTraits memory newTraits): Internal helper to update/set token traits.**
**// - _recordLineage(uint256 childId, uint256 parentId1, uint256 parentId2): Internal helper to record parent IDs.**
**// - _setGeneration(uint256 tokenId, uint256 generation): Internal helper to set token generation.**
**// - _toString(uint256 value): Internal helper to convert uint256 to string.**

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion

contract CryptoArtFusion is ERC721Enumerable, ERC721URIStorage, ERC721Royalty, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error InvalidTokenId();
    error NotOwnerOfToken(uint256 tokenId);
    error CannotFuseBaseTokens();
    error NotEnoughCatalyst(uint256 required, uint256 has);
    error SelfFusionNotAllowed();
    error InvalidParentsForFusion();
    error FusionLimitReached(uint256 maxGeneration);
    error TraitTypeDoesNotExist(string memory traitType);
    error TraitValueAlreadyExists(string memory traitType, string memory traitValue);
    error ProposalAlreadyExists(uint256 proposalId);
    error ProposalDoesNotExist(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error ProposalNotSucceeded(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId);
    error NotEnoughTokensToVote(uint256 required);
    error ExecutionFailed();
    error NoBalanceToWithdraw();

    // --- Events ---
    event BaseTokenMinted(uint256 indexed tokenId, address indexed owner, uint256 initialGeneration);
    event TokensFused(uint256 indexed parentId1, uint256 indexed parentId2, uint256 indexed newChildId, uint256 newGeneration);
    event CatalystMinted(address indexed recipient, uint256 amount);
    event CatalystBurned(address indexed owner, uint256 amount);
    event TraitsUpdated(uint256 indexed tokenId, string[] traitTypes);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TraitValueAdded(string indexed traitType, string indexed traitValue);
    event BaseMintPriceUpdated(uint256 newPrice);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs & Enums ---
    struct Trait {
        string traitType;
        string value;
    }

    // Traits are stored as a dynamic array of Trait structs
    // Mapping token ID to its array of traits
    mapping(uint256 => Trait[]) private _tokenTraits;

    // Mapping token ID to its generation number (0 for base, 1+ for fusion)
    mapping(uint256 => uint256) private _tokenGeneration;

    // Mapping child token ID to its parent token IDs
    mapping(uint256 => uint256[2]) private _tokenParents;

    // Available traits that can be generated/added
    // traitType => array of possible values
    mapping(string => string[]) private _availableTraits;

    // --- Governance ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        address creator;
        string description;
        string traitType; // Specific to adding trait values
        string traitValue; // Specific to adding trait values
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotes; // Number of token holders who voted
        uint256 supportVotes; // Votes for the proposal
        ProposalState state;
        mapping(address => bool) hasVoted; // To prevent double voting
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingPeriod = 3 days; // Duration for voting
    uint256 public minTokensToVote = 1; // Minimum number of NFTs required to vote
    uint256 public proposalThresholdPercent = 51; // Percentage of support votes needed to pass (out of total votes)

    // --- Catalyst Tokens ---
    mapping(address => uint256) private _catalystBalances;
    uint256 public catalystCostPerFusion = 1; // Amount of Catalyst needed per fusion

    // --- Contract Settings ---
    uint256 public baseMintPrice = 0.05 ether;
    uint256 public maxFusionGeneration = 5; // Maximum generation level for fusion

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address defaultRoyaltyReceiver, uint96 defaultRoyaltyFeeNumerator)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
        ERC721Royalty() // Initialize ERC2981
    {
        _tokenIdCounter.increment(); // Start token IDs from 1
        _proposalIdCounter.increment(); // Start proposal IDs from 1

        // Set initial default royalty
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultRoyaltyFeeNumerator);

        // Add some initial base traits (Admin/Governance can add more later)
        _availableTraits["Background"] = ["Cosmic Void", "Starfield", "Nebula Hue"];
        _availableTraits["Shape"] = ["Orb", "Crystal", "Polygon"];
        _availableTraits["Aura"] = ["None", "Glowing", "Sparkling"];
        _availableTraits["Energy"] = ["Static", "Pulsing", "Swirling"];
    }

    // --- ERC721 Overrides ---

    // Implement ERC165 support for interfaces ERC721, ERC721Enumerable, ERC721Metadata, ERC721Royalty, Ownable, Pausable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty, Ownable, Pausable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Generates the metadata URI for a token
    // Returns a data URI with Base64 encoded JSON
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        // Get token details
        string memory name = string(abi.encodePacked(ERC721.name(), " #", tokenId.toString()));
        uint256 generation = _tokenGeneration[tokenId];
        Trait[] memory traits = _tokenTraits[tokenId];
        uint256[] memory parents = new uint256[](0);
        if (generation > 0) {
            parents = _tokenParents[tokenId];
        }

        string memory description = string(abi.encodePacked(
            "A generative, fuseable art piece. Generation: ", generation.toString()
        ));

        // Build traits JSON array
        string memory traitsJson = "[";
        for (uint i = 0; i < traits.length; i++) {
            traitsJson = string(abi.encodePacked(
                traitsJson,
                '{"trait_type": "', traits[i].traitType, '", "value": "', traits[i].value, '"}'
            ));
            if (i < traits.length - 1) {
                traitsJson = string(abi.encodePacked(traitsJson, ","));
            }
        }
        traitsJson = string(abi.encodePacked(traitsJson, "]"));

        // Build lineage JSON
        string memory parentsJson = "[";
         if (generation > 0) {
             parentsJson = string(abi.encodePacked(
                 parentsJson,
                 parents[0].toString(),
                 ",",
                 parents[1].toString()
             ));
         }
         parentsJson = string(abi.encodePacked(parentsJson, "]"));

        // Example: Deterministic image URL placeholder based on token ID
        // In a real dApp, this URL would point to an API that generates/serves the image
        // based on the token's traits.
        string memory imageUrl = string(abi.encodePacked(
            "ipfs://<PLACEHOLDER_CID>/image/", tokenId.toString(), ".png"
            // Or point to a reveal service: "https://api.cryptoartfusion.xyz/image/" + tokenId.toString()
        ));

        // Construct full metadata JSON
        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', imageUrl, '",',
            '"generation": ', generation.toString(), ',',
            '"parents": ', parentsJson, ',',
            '"attributes": ', traitsJson,
            '}'
        ));

        // Base64 encode and return as data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Core Art Fusion Logic ---

    /**
     * @notice Mints an initial 'Base' token (Generation 0).
     * @dev Assigns random initial traits from the available base pools.
     */
    function mintBaseToken() public payable whenNotPaused returns (uint256) {
        if (msg.value < baseMintPrice) {
            revert("Insufficient payment"); // Use require string for simple errors
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);
        _setGeneration(newTokenId, 0); // Base tokens are Generation 0

        // Assign random initial traits from base pools
        string[] memory traitTypes = new string[](4);
        traitTypes[0] = "Background";
        traitTypes[1] = "Shape";
        traitTypes[2] = "Aura";
        traitTypes[3] = "Energy";

        Trait[] memory initialTraits = new Trait[](traitTypes.length);
        for(uint i = 0; i < traitTypes.length; i++) {
             string memory traitType = traitTypes[i];
             string[] memory values = _availableTraits[traitType];
             if (values.length > 0) {
                uint256 randomIndex = _getRandomValue(values.length); // Use pseudo-randomness
                initialTraits[i] = Trait({traitType: traitType, value: values[randomIndex]});
             } else {
                 // Handle cases where a trait type has no values (shouldn't happen if configured correctly)
                 initialTraits[i] = Trait({traitType: traitType, value: "None"});
             }
        }

        _updateTokenTraits(newTokenId, initialTraits);

        emit BaseTokenMinted(newTokenId, msg.sender, 0);

        return newTokenId;
    }

    /**
     * @notice Fuses two existing tokens owned by the caller to create a new token.
     * @dev Burns the parent tokens, consumes Catalyst, generates new traits, and mints the child token.
     * @param parentId1 The token ID of the first parent.
     * @param parentId2 The token ID of the second parent.
     */
    function fuseTokens(uint256 parentId1, uint256 parentId2) public whenNotPaused returns (uint256) {
        // --- Pre-checks ---
        if (!_exists(parentId1) || !_exists(parentId2)) {
            revert InvalidTokenId();
        }
        if (ownerOf(parentId1) != msg.sender || ownerOf(parentId2) != msg.sender) {
            revert NotOwnerOfToken(ownerOf(parentId1) != msg.sender ? parentId1 : parentId2);
        }
        if (parentId1 == parentId2) {
            revert SelfFusionNotAllowed();
        }
        // Ensure parents are not Base tokens (Generation 0), or define rules for Base fusion if allowed
        // Let's require at least one parent is Generation 1+ for more interesting lineage.
        // Or, simply require *both* parents are Generation 0+ if we want to allow fusing Base tokens.
        // Let's allow fusing any two tokens owned by the caller for simplicity in this example.
        // if (_tokenGeneration[parentId1] == 0 && _tokenGeneration[parentId2] == 0) {
        //     revert CannotFuseBaseTokens(); // Example restriction
        // }

        if (_catalystBalances[msg.sender] < catalystCostPerFusion) {
            revert NotEnoughCatalyst(catalystCostPerFusion, _catalystBalances[msg.sender]);
        }

        // --- Core Fusion Process ---
        uint256 newChildId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        uint256 newGeneration = Math.max(_tokenGeneration[parentId1], _tokenGeneration[parentId2]) + 1;

        if (newGeneration > maxFusionGeneration && maxFusionGeneration > 0) { // maxFusionGeneration == 0 means no limit
             revert FusionLimitReached(maxFusionGeneration);
        }

        // 1. Burn Parents
        _burn(parentId1);
        _burn(parentId2);

        // 2. Consume Catalyst
        _burnCatalyst(msg.sender, catalystCostPerFusion);

        // 3. Generate Child Traits
        Trait[] memory childTraits = _generateFusionTraits(parentId1, parentId2, newGeneration);
        _updateTokenTraits(newChildId, childTraits);

        // 4. Mint Child
        _safeMint(msg.sender, newChildId);
        _setGeneration(newChildId, newGeneration);
        _recordLineage(newChildId, parentId1, parentId2);

        // 5. Emit Event
        emit TokensFused(parentId1, parentId2, newChildId, newGeneration);

        return newChildId;
    }

    // --- Trait Management ---

    /**
     * @notice Admin or governance function to add a new trait type (e.g., "Eyes", "Mouth").
     * @dev Requires owner or successful governance execution.
     * @param traitType The name of the new trait type.
     */
    function addTraitType(string memory traitType) external onlyOwner { // Simplified to onlyOwner for example
        // In a real governance system, this would be called by executeProposal
        require(bytes(traitType).length > 0, "Trait type name cannot be empty");
        // Check if type already exists? Maybe allow adding values to empty types.
        // For now, simple addition.

        // Initialize the array for this type if it doesn't exist
        // This happens automatically when first value is added via addTraitValue or executeProposal

        emit TraitValueAdded(traitType, "TypeAdded"); // Using this event for type addition too, value is placeholder
    }

    /**
     * @notice Admin or governance function to add a new possible value for an existing trait type.
     * @dev Requires owner or successful governance execution.
     * @param traitType The name of the trait type (must exist).
     * @param traitValue The new value to add (e.g., "Blue", "Green").
     */
    function addTraitValue(string memory traitType, string memory traitValue) external onlyOwner { // Simplified to onlyOwner for example
        // In a real governance system, this would be called by executeProposal
        if (_availableTraits[traitType].length == 0 && bytes(traitType).length > 0) {
             // Auto-add trait type if it's the first value being added
             // This is a simpler flow than requiring addTraitType first
        } else if (bytes(traitType).length == 0 || _availableTraits[traitType].length == 0) {
             revert TraitTypeDoesNotExist(traitType);
        }

        for (uint i = 0; i < _availableTraits[traitType].length; i++) {
            if (keccak256(abi.encodePacked(_availableTraits[traitType][i])) == keccak256(abi.encodePacked(traitValue))) {
                revert TraitValueAlreadyExists(traitType, traitValue);
            }
        }

        _availableTraits[traitType].push(traitValue);

        emit TraitValueAdded(traitType, traitValue);
    }

    /**
     * @notice Gets the available trait values for a given trait type.
     * @param traitType The name of the trait type.
     * @return An array of strings representing the available values.
     */
    function getAvailableTraitValues(string memory traitType) public view returns (string[] memory) {
        return _availableTraits[traitType];
    }

    /**
     * @notice Gets all available trait types.
     * @dev Iterating over mapping keys directly is not possible. Need to store types in an array.
     * For simplicity here, we'll return a hardcoded array of the types added in constructor/addTraitType.
     * A production contract would need a state variable `string[] private _traitTypesList;`
     * and update it in addTraitType and executeProposal.
     * Returning a placeholder array based on constructor for demonstration.
     */
    function getAllTraitTypes() public view returns (string[] memory) {
         string[] memory types = new string[](_availableTraits["Background"].length > 0 ? 4 : 0); // Basic check if any types were added
         if (types.length > 0) {
             types[0] = "Background";
             types[1] = "Shape";
             types[2] = "Aura";
             types[3] = "Energy";
             // Need logic here if types were added via governance/addTraitType dynamically
         }
         return types;
    }


    // --- Catalyst Management ---

    /**
     * @notice Admin function to mint Catalyst tokens to a recipient.
     * @dev Used to distribute Catalyst, e.g., for events or initial supply.
     * @param recipient The address to mint tokens to.
     * @param amount The amount of Catalyst to mint.
     */
    function mintCatalyst(address recipient, uint256 amount) public onlyOwner whenNotPaused {
        require(recipient != address(0), "Cannot mint to zero address");
        _mintCatalyst(recipient, amount);
        emit CatalystMinted(recipient, amount);
    }

    /**
     * @notice Gets the Catalyst token balance for an address.
     * @param owner The address to check the balance of.
     * @return The Catalyst balance.
     */
    function balanceOfCatalyst(address owner) public view returns (uint256) {
        return _catalystBalances[owner];
    }

    // --- Information & Getter Functions ---

    /**
     * @notice Gets the array of traits for a specific token.
     * @param tokenId The ID of the token.
     * @return An array of Trait structs.
     */
    function getTokenTraits(uint256 tokenId) public view returns (Trait[] memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // Note: This returns a copy. Modifying the returned array won't change contract state.
        return _tokenTraits[tokenId];
    }

     /**
      * @notice Gets the generation number of a token.
      * @param tokenId The ID of the token.
      * @return The generation number (0 for Base, 1+ for Fusion).
      */
    function getTokenGeneration(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
             revert InvalidTokenId();
        }
        return _tokenGeneration[tokenId];
    }

    /**
     * @notice Gets the parent token IDs of a Fusion token.
     * @param tokenId The ID of the token.
     * @return An array containing the two parent token IDs. Empty array for Base tokens.
     */
    function getTokenParents(uint256 tokenId) public view returns (uint256[2] memory) {
         if (!_exists(tokenId)) {
             revert InvalidTokenId();
        }
        if (_tokenGeneration[tokenId] == 0) {
             // Returning an empty array is tricky for fixed size array in solidity.
             // Let's return [0, 0] for base tokens.
             return [0, 0];
        }
        return _tokenParents[tokenId];
    }

    /**
     * @notice Gets the details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    function getProposal(uint256 proposalId)
         public
         view
         returns (
             uint256 id,
             address creator,
             string memory description,
             string memory traitType,
             string memory traitValue,
             uint256 voteStartTime,
             uint256 voteEndTime,
             uint256 totalVotes,
             uint256 supportVotes,
             ProposalState state
         )
    {
        if (proposalId >= _proposalIdCounter.current() || proposalId == 0) { // proposal IDs start from 1
            revert ProposalDoesNotExist(proposalId);
        }
        Proposal storage p = proposals[proposalId];
         return (
             p.id,
             p.creator,
             p.description,
             p.traitType,
             p.traitValue,
             p.voteStartTime,
             p.voteEndTime,
             p.totalVotes,
             p.supportVotes,
             p.state
         );
    }


    // --- Governance Functions ---

    /**
     * @notice Allows token holders to propose adding a new trait value to an existing type.
     * @dev Requires owning at least `minTokensToVote` NFTs.
     * @param description A description of the proposal.
     * @param traitType The trait type to add a value to (must exist).
     * @param traitValue The new value to propose.
     */
    function createProposal(string memory description, string memory traitType, string memory traitValue) external whenNotPaused returns (uint256) {
         if (balanceOf(msg.sender) < minTokensToVote) {
            revert NotEnoughTokensToVote(minTokensToVote);
         }
        if (bytes(traitType).length == 0 || _availableTraits[traitType].length == 0) {
             revert TraitTypeDoesNotExist(traitType);
        }

        uint256 newProposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        Proposal storage proposal = proposals[newProposalId];
        proposal.id = newProposalId;
        proposal.creator = msg.sender;
        proposal.description = description;
        proposal.traitType = traitType;
        proposal.traitValue = traitValue;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + votingPeriod;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(newProposalId, msg.sender, description);
        return newProposalId;
    }

    /**
     * @notice Allows token holders to vote on an active proposal.
     * @dev Requires owning at least `minTokensToVote` NFTs and not having voted yet. 1 address = 1 vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes' vote, False for 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
         Proposal storage proposal = proposals[proposalId];

        if (proposalId >= _proposalIdCounter.current() || proposalId == 0 || proposal.id == 0) {
            revert ProposalDoesNotExist(proposalId);
        }
        if (proposal.state != ProposalState.Active) {
            revert ProposalNotActive(proposalId);
        }
        if (block.timestamp > proposal.voteEndTime) {
             // Proposal expired, needs to be finalized
             // A separate function could do this, or executeProposal handles it.
             // For simplicity, let's just disallow voting after expiry.
             revert ProposalNotActive(proposalId); // Or a more specific error
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(proposalId);
        }
         if (balanceOf(msg.sender) < minTokensToVote) {
            revert NotEnoughTokensToVote(minTokensToVote);
         }


        proposal.hasVoted[msg.sender] = true;
        proposal.totalVotes++;
        if (support) {
            proposal.supportVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Executes a successful proposal to add a new trait value.
     * @dev Can be called by anyone after the voting period ends if the proposal succeeded.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposalId >= _proposalIdCounter.current() || proposalId == 0 || proposal.id == 0) {
            revert ProposalDoesNotExist(proposalId);
        }
         if (proposal.state != ProposalState.Active) {
            revert ProposalNotActive(proposalId); // Or different error if already Executed/Failed
        }
         if (block.timestamp <= proposal.voteEndTime) {
             revert("Voting period not ended yet"); // Or a state change function
         }

        // Finalize state based on votes
        if (proposal.totalVotes > 0 && (proposal.supportVotes * 100 / proposal.totalVotes) >= proposalThresholdPercent) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }

        if (proposal.state != ProposalState.Succeeded) {
            revert ProposalNotSucceeded(proposalId);
        }

        // Execute the action: Add the trait value
        // Re-check if trait type exists and value doesn't, though voting should ideally prevent this.
        // Adding trait value logic directly here, similar to addTraitValue onlyOwner
         if (bytes(proposal.traitType).length == 0) {
             revert ExecutionFailed(); // Should not happen based on creation checks
         }
        // Check if value already exists (can happen if added via different proposal or admin call simultaneously)
        string[] memory currentValues = _availableTraits[proposal.traitType];
         for (uint i = 0; i < currentValues.length; i++) {
             if (keccak256(abi.encodePacked(currentValues[i])) == keccak256(abi.encodePacked(proposal.traitValue))) {
                 // Value already exists, mark proposal executed but don't add again
                 proposal.state = ProposalState.Executed; // Mark as executed even if trait wasn't added
                 emit ProposalExecuted(proposalId);
                 // Optionally, emit a warning event
                 return; // Exit successfully as the desired state is achieved
             }
         }


        _availableTraits[proposal.traitType].push(proposal.traitValue);

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
        emit TraitValueAdded(proposal.traitType, proposal.traitValue);
    }


    // --- Admin & Utility Functions ---

    /**
     * @notice Admin function to update the price for minting a base token.
     * @param price The new base mint price in wei.
     */
    function setBaseMintPrice(uint256 price) public onlyOwner {
        baseMintPrice = price;
        emit BaseMintPriceUpdated(price);
    }

    /**
     * @notice Admin function to withdraw collected funds from the contract balance.
     * @dev Funds come from base token mints.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoBalanceToWithdraw();
        }
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner(), balance);
    }

    /**
     * @notice Pauses core contract operations (minting, fusing).
     * @dev Inherited from Pausable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses core contract operations.
     * @dev Inherited from Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to generate new traits for a fusion token.
     * @dev This logic defines the generative art rules. Can be complex.
     * @param parentId1 The ID of the first parent.
     * @param parentId2 The ID of the second parent.
     * @param newGeneration The generation number of the child token.
     * @return An array of Trait structs for the new child token.
     */
    function _generateFusionTraits(uint256 parentId1, uint256 parentId2, uint256 newGeneration) internal view returns (Trait[] memory) {
        Trait[] memory traits1 = _tokenTraits[parentId1];
        Trait[] memory traits2 = _tokenTraits[parentId2];

        // Simple Fusion Logic Example:
        // 1. Combine traits from parents.
        // 2. For each trait type, pick one from parents or a new random one from available pool.
        // 3. Maybe add a new trait type or apply generation-specific rules.

        // Get all unique trait types from parents
        mapping(string => bool) internal traitTypesMap;
        string[] memory parentTraitTypes = new string[](traits1.length + traits2.length); // Max possible types

        uint typeCount = 0;
        for(uint i = 0; i < traits1.length; i++) {
            if (!traitTypesMap[traits1[i].traitType]) {
                traitTypesMap[traits1[i].traitType] = true;
                parentTraitTypes[typeCount] = traits1[i].traitType;
                typeCount++;
            }
        }
         for(uint i = 0; i < traits2.length; i++) {
            if (!traitTypesMap[traits2[i].traitType]) {
                traitTypesMap[traits2[i].traitType] = true;
                parentTraitTypes[typeCount] = traits2[i].traitType;
                typeCount++;
            }
        }

        // Determine the number of traits for the child. Could be fixed or dynamic.
        // Let's keep it simple and try to assign a value for each known trait type.
        string[] memory allKnownTraitTypes = getAllTraitTypes(); // Using the simplified getter
        Trait[] memory childTraits = new Trait[](allKnownTraitTypes.length);

        uint traitIndex = 0;
        for(uint i = 0; i < allKnownTraitTypes.length; i++) {
            string memory currentType = allKnownTraitTypes[i];
            string memory selectedValue = "None"; // Default value

            // Find parent values for this type
            string memory parentValue1 = "None";
            string memory parentValue2 = "None";

             for(uint j = 0; j < traits1.length; j++) {
                if (keccak256(abi.encodePacked(traits1[j].traitType)) == keccak256(abi.encodePacked(currentType))) {
                     parentValue1 = traits1[j].value;
                     break;
                }
             }
             for(uint j = 0; j < traits2.length; j++) {
                if (keccak256(abi.encodePacked(traits2[j].traitType)) == keccak256(abi.encodePacked(currentType))) {
                     parentValue2 = traits2[j].value;
                     break;
                }
             }

            string[] memory availableValues = _availableTraits[currentType];
             if (availableValues.length > 0) {
                // Fusion Rule: 50% chance to inherit parent1, 50% chance parent2
                // If parents have different values for the same trait, pick one randomly.
                // If one parent has "None", higher chance to inherit the non-None value.
                // If both have "None", pick randomly from available (or keep "None").
                // If parents have the same value, inherit it.
                // Add a small chance (e.g., 10%) to generate a *new* random value from pool regardless of parents.

                uint256 randChoice = _getRandomValue(100); // 0-99

                if (keccak256(abi.encodePacked(parentValue1)) == keccak256(abi.encodePacked(parentValue2))) {
                    // Parents have the same value or both are "None"
                    if (keccak256(abi.encodePacked(parentValue1)) != keccak256(abi.encodePacked("None")) && randChoice < 90) {
                         selectedValue = parentValue1; // Inherit same value (90% chance)
                    } else {
                         // Either parents were both "None" or random chance for new value
                         uint256 randomIndex = _getRandomValue(availableValues.length);
                         selectedValue = availableValues[randomIndex];
                    }
                } else {
                    // Parents have different values
                     if (keccak256(abi.encodePacked(parentValue1)) == keccak256(abi.encodePacked("None"))) {
                         // Only parent2 has a value (or is "None" while parent1 had a value)
                          if (keccak256(abi.encodePacked(parentValue2)) != keccak256(abi.encodePacked("None")) && randChoice < 80) {
                              selectedValue = parentValue2; // Higher chance to inherit the non-None
                          } else {
                               uint256 randomIndex = _getRandomValue(availableValues.length);
                               selectedValue = availableValues[randomIndex]; // Small chance for completely new
                          }
                     } else if (keccak256(abi.encodePacked(parentValue2)) == keccak256(abi.encodePacked("None"))) {
                         // Only parent1 has a value
                          if (keccak256(abi.encodePacked(parentValue1)) != keccak256(abi.encodePacked("None")) && randChoice < 80) {
                              selectedValue = parentValue1; // Higher chance to inherit the non-None
                          } else {
                               uint256 randomIndex = _getRandomValue(availableValues.length);
                               selectedValue = availableValues[randomIndex]; // Small chance for completely new
                          }
                     } else {
                         // Both parents have non-None, different values
                         if (randChoice < 45) { // 45% chance parent1
                             selectedValue = parentValue1;
                         } else if (randChoice < 90) { // 45% chance parent2
                             selectedValue = parentValue2;
                         } else { // 10% chance for completely new value
                             uint256 randomIndex = _getRandomValue(availableValues.length);
                             selectedValue = availableValues[randomIndex];
                         }
                     }
                }

                 // Optional: Add generation-specific logic (e.g., unlock new traits at higher generations)
                 if (newGeneration >= 3 && keccak256(abi.encodePacked(currentType)) == keccak256(abi.encodePacked("Energy"))) {
                     // Example: High generation adds a chance for a special "Quantum" energy if it exists
                     string[] memory energyValues = _availableTraits["Energy"];
                     for(uint k=0; k<energyValues.length; k++) {
                         if (keccak256(abi.encodePacked(energyValues[k])) == keccak256(abi.encodePacked("Quantum")) && _getRandomValue(100) < 20) {
                             selectedValue = "Quantum"; // 20% chance at gen 3+
                             break;
                         }
                     }
                 }


             }
             // If no available values for this type, selectedValue remains "None" or fallback to a default
             childTraits[traitIndex] = Trait({traitType: currentType, value: selectedValue});
             traitIndex++;

        }

        // Note: This basic logic assumes a fixed set of trait *types* determined by the constructor/governance.
        // More advanced logic could dynamically add *new trait types* based on fusion combinations or generation.

        return childTraits;
    }

    /**
     * @notice Pseudo-random number generation (DO NOT USE FOR SECURITY-CRITICAL APPLICATIONS).
     * @dev Uses block.timestamp and block.difficulty (deprecated in Eth 2.0, use block.basefee instead) or block.number.
     *      This is highly manipulable by miners/validators.
     * @param maxValue The upper bound (exclusive) for the random value (0 to maxValue-1).
     * @return A pseudo-random uint256 value.
     */
     function _getRandomValue(uint256 maxValue) internal view returns (uint256) {
         // Using block.number is slightly better than timestamp but still weak.
         // Real randomness requires Chainlink VRF or similar.
         uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tx.origin, block.difficulty)));
         return randomness % maxValue;
     }


     /**
      * @notice Internal function to burn Catalyst tokens from an address.
      * @param owner The address to burn tokens from.
      * @param amount The amount of Catalyst to burn.
      */
     function _burnCatalyst(address owner, uint256 amount) internal {
        require(_catalystBalances[owner] >= amount, "Insufficient catalyst balance");
        _catalystBalances[owner] -= amount;
        emit CatalystBurned(owner, amount);
     }

     /**
      * @notice Internal function to mint Catalyst tokens to an address.
      * @param recipient The address to mint tokens to.
      * @param amount The amount of Catalyst to mint.
      */
     function _mintCatalyst(address recipient, uint256 amount) internal {
         _catalystBalances[recipient] += amount;
     }


    /**
     * @notice Internal function to set or update the traits of a token.
     * @param tokenId The ID of the token.
     * @param newTraits The array of Trait structs for the token.
     */
    function _updateTokenTraits(uint256 tokenId, Trait[] memory newTraits) internal {
        _tokenTraits[tokenId] = newTraits; // Overwrites existing traits
        // Can add event here if needed, but TraitsUpdated event is emitted elsewhere
    }

    /**
     * @notice Internal function to record the parent token IDs for a child token.
     * @param childId The ID of the child token.
     * @param parentId1 The ID of the first parent.
     * @param parentId2 The ID of the second parent.
     */
    function _recordLineage(uint256 childId, uint256 parentId1, uint256 parentId2) internal {
        // Store in a consistent order (e.g., lowest ID first)
        if (parentId1 < parentId2) {
            _tokenParents[childId] = [parentId1, parentId2];
        } else {
            _tokenParents[childId] = [parentId2, parentId1];
        }
    }

     /**
      * @notice Internal function to set the generation number of a token.
      * @param tokenId The ID of the token.
      * @param generation The generation number.
      */
    function _setGeneration(uint256 tokenId, uint256 generation) internal {
         _tokenGeneration[tokenId] = generation;
    }


    // The following functions are standard ERC721/Enumerable/URIStorage/Royalty overrides
    // They are required by OpenZeppelin but not unique creative functions themselves,
    // though their *implementation* depends on the custom state variables.
    // We've already overridden tokenURI and supportsInterface above.
    // The others (transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, balanceOf, ownerOf, totalSupply, tokenByIndex, tokenOfOwnerByIndex)
    // are handled by inheriting ERC721Enumerable and ERC721URIStorage, which override ERC721 base functions.
    // The _beforeTokenTransfer hook (implicitly used by OZ mint/burn) is where custom logic could go if needed,
    // e.g., checking pausable state before transfer. Pausable already does this.

    // We need to override _burn because ERC721Enumerable requires it if burning is possible.
    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        super._burn(tokenId);
        // Clean up custom data when token is burned
        delete _tokenTraits[tokenId];
        delete _tokenGeneration[tokenId];
        delete _tokenParents[tokenId];
        _deleteTokenURI(tokenId); // Clean up from URIStorage
    }

    // Override _baseURI or set tokenURI directly if not using URIStorage
    // We are using URIStorage but overriding tokenURI to generate data URI, so _baseURI is not used.

    // The ERC721Enumerable requires iterating over token IDs.
    // This is handled by OpenZeppelin's ERC721Enumerable logic.

    // Royalty Info override is part of ERC721Royalty, implemented above.

    // Pausable requires _beforeTokenTransfer override to check paused state.
    // OpenZeppelin's Pausable handles this automatically when inherited *after* ERC721.
    // If it were inherited before, you'd need:
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable, Pausable) {
    //    super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }


}
```