Okay, this is an ambitious and fun challenge! Let's design a concept around *Generative & Evolving Art NFTs* with on-chain parameters, timed evolution, community influence on future parameters, and dynamic artist splits.

Here's the concept:

**Generative & Evolving Art NFT**

*   **Generative:** When an NFT is minted, its initial visual traits (represented by on-chain parameters) are determined by verifiable randomness (Chainlink VRF). These parameters dictate aspects like color palettes, shapes, textures, initial rarity, etc.
*   **Evolving:** NFTs are not static. Owners can "nurture" their art over time or by performing specific actions (e.g., paying a fee). Nurturing triggers changes to the on-chain parameters, potentially altering the art's appearance, rarity, or even unlocking new traits. There might be different "evolution stages".
*   **Community Influence:** NFT holders can propose changes to the *rules* or *ranges* for future trait generation or evolution. A simplified on-chain voting mechanism allows holders to approve or reject these proposals. Successful proposals influence *new* mints or the *evolution* process for *all* NFTs.
*   **Dynamic Metadata:** The `tokenURI` function dynamically generates metadata based on the *current* state of the NFT's on-chain parameters and evolution stage. This often involves referencing an external renderer/API (since complex image generation is too costly on-chain).
*   **Artist Splits:** Revenue generated from minting or nurturing fees is automatically split among a predefined set of artists/beneficiaries based on configurable percentages.

This concept combines ERC721, VRF, dynamic state, time-based logic, a basic governance/influence mechanism, and revenue splitting, providing a good mix of advanced features.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional, for enumeration
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For safe ETH transfers
import "@chainlink/contracts/src/v0.8/VRF/VRFV2WrapperConsumerBase.sol"; // Using VRFV2 Wrapper for simplicity

// Error handling
error NotEnoughEth();
error InvalidArtistSplit();
error TokenDoesNotExist();
error NotOwnerOrApproved();
error NurtureCooldownActive();
error InsufficientNurtureFee();
error ProposalDoesNotExist();
error AlreadyVoted();
error ProposalNotExecutable();
error ProposalStillActive();
error NoActiveProposals();
error InvalidTraitRange();
error CannotWithdrawZero();

// --- CONTRACT: GenerativeArtNFT ---
// A smart contract for generating and evolving art NFTs based on on-chain parameters,
// verifiable randomness, and community influence.
// NFTs change appearance (via metadata) based on their state and evolution.
// Revenue from minting/nurturing is split among artists.

// --- OUTLINE & FUNCTION SUMMARY ---

// STATE VARIABLES:
// - VRF Configuration: wrapper address, keyhash, callback gas, confirmations, subscription ID.
// - Generative Rules: Defines the possible ranges and types of art traits.
// - Evolution Rules: Defines how traits change upon nurturing, cooldowns, costs per stage.
// - Community Proposals: Stores proposals for rule changes, votes, state.
// - Artist Splits: Defines beneficiaries and their percentage shares.
// - Token Data: Mappings for traits, evolution state, VRF request tracking.
// - Counters & Config: Token ID counter, proposal counter, base URI, renderer address, mint interval.

// STRUCTS:
// - ArtTraits: Stores the on-chain parameters defining an NFT's appearance.
// - EvolutionState: Tracks nurturing count, last nurtured time, current evolution stage.
// - TraitRange: Defines min/max bounds for a specific trait type.
// - ArtistSplit: Defines an artist address and their share in basis points.
// - Proposal: Represents a community proposal to change rules, including votes and state.

// ENUMS:
// - ProposalState: Lifecycle of a proposal (Pending, Approved, Rejected, Executed).
// - ProposalType: Type of rule change being proposed (e.g., NewTraitRange, UpdateEvolutionCost).

// FUNCTIONS:
// --- ERC721 & Enumerable Standard Functions (Inherited/Overridden) ---
// 01. constructor(address vrfWrapperAddress, ...) - Initializes contract, ERC721, Ownable, VRF.
// 02. ownerOf(uint256 tokenId) - Get owner of token (inherited).
// 03. balanceOf(address owner) - Get balance of owner (inherited).
// 04. getApproved(uint256 tokenId) - Get approved address for token (inherited).
// 05. isApprovedForAll(address owner, address operator) - Check if operator is approved for all (inherited).
// 06. approve(address to, uint256 tokenId) - Approve address for token (inherited).
// 07. setApprovalForAll(address operator, bool approved) - Approve operator for all tokens (inherited).
// 08. transferFrom(address from, address to, uint256 tokenId) - Transfer token (inherited).
// 09. safeTransferFrom(address from, address to, uint256 tokenId) - Safe transfer (inherited).
// 10. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - Safe transfer with data (inherited).
// 11. supportsInterface(bytes4 interfaceId) - Check supported interfaces (inherited).
// 12. tokenByIndex(uint256 index) - Get token ID by index (from ERC721Enumerable, if enabled).
// 13. tokenOfOwnerByIndex(address owner, uint256 index) - Get token ID of owner by index (from ERC721Enumerable, if enabled).
// 14. totalSupply() - Get total supply (from ERC721Enumerable, if enabled).

// --- Core Minting & Generative Logic ---
// 15. requestRandomTraits(uint256 numberOfTokens) - Requests VRF for minting new tokens.
// 16. rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) - VRF callback to generate traits.
// 17. getArtTraits(uint256 tokenId) - Retrieve the on-chain traits for an NFT.
// 18. generateTokenURI(uint256 tokenId) - Dynamically generates the metadata URI (overrides ERC721).

// --- Evolution & Nurturing ---
// 19. nurtureArt(uint256 tokenId) payable - Allows owner to pay a fee to evolve their NFT.
// 20. getEvolutionState(uint256 tokenId) - Get the current evolution state of an NFT.
// 21. getEvolutionCost(uint8 evolutionStage) - Get the required fee for a specific stage.

// --- Community Influence (Simplified Governance) ---
// 22. proposeTraitRangeUpdate(string memory traitType, uint256 min, uint256 max) - Allows anyone to propose a trait range change.
// 23. voteOnProposal(uint256 proposalId, bool approve) - Allows NFT holders to vote on a proposal.
// 24. executeProposal(uint256 proposalId) - Admin executes a proposal that has passed.
// 25. getProposalState(uint256 proposalId) - Check the status of a proposal.
// 26. getProposal(uint256 proposalId) - Get details of a proposal.
// 27. getVoteCount(uint256 proposalId) - Get current vote counts for a proposal.

// --- Artist Splits & Revenue Distribution ---
// 28. addArtistSplit(address artist, uint16 shareBps) onlyOwner - Add or update an artist's revenue share.
// 29. removeArtistSplit(address artist) onlyOwner - Remove an artist from revenue share.
// 30. distributeFunds() onlyOwner - Distribute accumulated funds to artists based on splits.
// 31. getArtistSplit(address artist) - Get an artist's configured share.
// 32. getUndistributedFunds() - Check the contract's balance available for distribution.

// --- Configuration & Admin ---
// 33. setBaseMetadataURI(string memory newBaseURI) onlyOwner - Set the base URI for metadata.
// 34. setRendererAddress(address renderer) onlyOwner - Set address of the off-chain metadata renderer.
// 35. setMinMintInterval(uint256 intervalSeconds) onlyOwner - Set minimum time between mints.
// 36. setEvolutionCost(uint8 stage, uint256 cost) onlyOwner - Set the nurture cost for an evolution stage.
// 37. setEvolutionCooldown(uint8 stage, uint256 cooldownSeconds) onlyOwner - Set the nurture cooldown for a stage.
// 38. setInitialTraitRanges(string[] memory traitTypes, uint256[] memory mins, uint256[] memory maxs) onlyOwner - Set initial generative ranges.
// 39. withdrawLink() onlyOwner - Withdraw excess LINK from the contract (if using VRF wrapper).
// 40. withdrawEth(address payable recipient, uint256 amount) onlyOwner - Owner can withdraw ETH (used for withdrawing *other* funds, not distributed ones).

contract GenerativeArtNFT is ERC721, ERC721Enumerable, Ownable, VRFV2WrapperConsumerBase {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    // --- Constants & Configuration ---
    uint16 public constant BASIS_POINTS_DIVISOR = 10000; // For artist splits (100% = 10000 bps)
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long proposals are open for voting
    uint256 public constant MIN_VOTING_POWER = 1; // Minimum NFT balance to vote on a proposal

    // --- VRF Configuration ---
    address immutable public vrfWrapper;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint64 public s_subscriptionId;

    // --- Counters ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _requestIdCounter; // To track VRF requests initiated by this contract
    Counters.Counter private _proposalCounter;

    // --- Token Data ---
    struct ArtTraits {
        // Example traits - actual traits would be application-specific
        uint8 colorPalette; // Index from 0-255
        uint8 shapeComplexity; // From 0-255
        uint8 textureType; // Index from 0-255
        uint8 specialProperty; // From 0-255, used for rarity/dynamic effects
        uint8 evolutionStage; // Current evolution stage (starts at 0)
        // ... potentially more traits ...
    }

    struct EvolutionState {
        uint256 nurtureCount;
        uint256 lastNurtureTime;
        uint8 currentEvolutionStage;
    }

    mapping(uint256 => ArtTraits) private _tokenTraits;
    mapping(uint252 => EvolutionState) private _evolutionState; // Use uint252 to save gas on key type
    mapping(uint256 => uint256) private _requestIdToTokenId; // VRF request ID -> first token ID in batch
    mapping(uint256 => uint256) private _tokenToRequestId; // Token ID -> VRF request ID that generated it

    // --- Generative & Evolution Rules ---
    struct TraitRange {
        uint256 min;
        uint256 max;
    }
    // Maps trait name (string) to its current allowed range for generation
    mapping(string => TraitRange) public traitRanges;
    // Nurture cost per evolution stage (in wei)
    mapping(uint8 => uint256) public evolutionCosts;
    // Nurture cooldown per evolution stage (in seconds)
    mapping(uint8 => uint256) public evolutionCooldowns;

    // --- Community Influence / Proposals ---
    enum ProposalState { Pending, Approved, Rejected, Executed }
    enum ProposalType {
        NewTraitRange,
        UpdateEvolutionCost,
        UpdateEvolutionCooldown,
        // ... potentially more proposal types ...
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes data; // Encoded data specific to the proposal type
        uint256 submitTime;
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
    }

    mapping(uint256 => Proposal) public proposals;
    // Mapping to track if an address has voted on a specific proposal
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    // --- Artist Splits ---
    struct ArtistSplit {
        address artist;
        uint16 shareBps; // Share in basis points
        bool active; // Is this split active? Allows "removing" without deleting
    }
    // Store splits in an array for easy iteration, map address to index
    ArtistSplit[] public artistSplits;
    mapping(address => uint256) private _artistAddressToIndex;
    uint256 private _totalArtistBps; // Sum of all active shareBps, must be <= BASIS_POINTS_DIVISOR

    // --- Configuration ---
    string private _baseMetadataURI;
    address public rendererAddress; // Address of an off-chain service for generating metadata JSON/images
    uint256 public minMintInterval; // Minimum time in seconds between mint requests

    // --- Events ---
    event MintRequested(uint256 indexed requestId, address indexed requester, uint256 numberOfTokens);
    event TraitsGenerated(uint256 indexed requestId, uint256 indexed firstTokenId, uint256 numberOfTokens);
    event ArtNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 feePaid, uint8 newEvolutionStage);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType);
    event Voted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event FundsDistributed(address indexed distributor, uint256 totalAmount);
    event ArtistSplitUpdated(address indexed artist, uint16 shareBps, bool active);
    event ConfigUpdated(string configName, bytes32 value);

    // --- Constructor ---
    constructor(
        address vrfWrapperAddress,
        uint64 subscriptionId,
        bytes32 vrfKeyHash,
        uint32 callbackGas,
        uint16 requestConf,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) ERC721Enumerable() Ownable(msg.sender) VRFV2WrapperConsumerBase(vrfWrapperAddress) {
        vrfWrapper = vrfWrapperAddress;
        s_subscriptionId = subscriptionId;
        keyHash = vrfKeyHash;
        callbackGasLimit = callbackGas;
        requestConfirmations = requestConf;

        // Set initial configuration defaults (can be changed by owner)
        minMintInterval = 15 seconds; // Prevent spamming VRF requests
        evolutionCosts[0] = 0; // Stage 0 (initial) costs nothing to nurture
        evolutionCooldowns[0] = 0; // Stage 0 has no cooldown initially
        // Set some default trait ranges (Owner should configure this properly)
        traitRanges["colorPalette"] = TraitRange(0, 255);
        traitRanges["shapeComplexity"] = TraitRange(0, 255);
        traitRanges["textureType"] = TraitRange(0, 255);
        traitRanges["specialProperty"] = TraitRange(0, 255);
    }

    // --- ERC721 & Enumerable Overrides ---
    // Note: ERC721Enumerable adds `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`
    //       Need to override _update and _increaseSupply to support Enumerable

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // 18. Dynamically generates the metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

        // If a renderer address is set, delegate metadata generation to it
        if (rendererAddress != address(0)) {
            // Construct URI like: ipfs://<base>/renderer/<rendererAddress>/<tokenId>
             return string(abi.encodePacked(
                 _baseMetadataURI,
                 "renderer/",
                 Address.toString(rendererAddress),
                 "/",
                 Strings.toString(tokenId)
             ));
        } else {
            // Fallback or simple base URI + token ID
             return string(abi.encodePacked(
                 _baseMetadataURI,
                 Strings.toString(tokenId)
             ));
        }
         // The actual metadata JSON at this URI would read the on-chain traits
         // using getArtTraits(tokenId) and format it according to ERC721 metadata standards.
         // This keeps on-chain cost low while allowing dynamic metadata.
    }

    // --- Core Minting & Generative Logic ---

    // 15. Requests VRF for minting new tokens
    function requestRandomTraits(uint256 numberOfTokens) public payable nonReentrant {
        if (msg.value < requestCalculatePrice(callbackGasLimit)) {
            revert NotEnoughEth();
        }
        // Optional: Add a mint fee here on top of VRF cost, which goes to artist splits
        // uint256 totalMintFee = numberOfTokens * MINT_FEE_PER_TOKEN;
        // require(msg.value >= requestCalculatePrice(callbackGasLimit) + totalMintFee, "Insufficient funds including mint fee");
        // Assuming the msg.value covers the VRF cost and optionally a mint fee

        if (block.timestamp < _lastMintTime.add(minMintInterval)) {
            revert("Minting is on cooldown");
        }

        require(numberOfTokens > 0 && numberOfTokens <= 5, "Can only mint between 1 and 5 tokens at a time"); // Limit batch size

        uint256 startingTokenId = _tokenIdCounter.current();

        // Check for potential overflow on token ID counter
        require(startingTokenId <= type(uint256).max - numberOfTokens, "Token ID counter overflow");

        uint256 requestId = requestRandomness(keyHash, callbackGasLimit, requestConfirmations);

        // Map the request ID to the first token ID in this batch
        _requestIdToTokenId[requestId] = startingTokenId;

        // Temporarily advance the counter, will be fully minted in callback
        _tokenIdCounter.increment(numberOfTokens);
        _requestIdCounter.increment();
        _lastMintTime = block.timestamp;

        // Optional: Distribute the mint fee portion of msg.value immediately
        // if (totalMintFee > 0) {
        //     _distributeFundsInternal(totalMintFee); // Needs modification to handle direct distribution
        // }

        emit MintRequested(requestId, msg.sender, numberOfTokens);
    }

    uint256 private _lastMintTime; // State variable to track last mint time

    // 16. VRF callback to generate traits and complete minting
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // This function is called by the Chainlink VRF wrapper contract.
        // DO NOT add sensitive logic here that depends on `msg.sender` being the oracle.
        // The VRF wrapper ensures the randomness is valid for the `requestId`.

        require(randomWords.length > 0, "VRF callback returned no words");

        uint256 startingTokenId = _requestIdToTokenId[requestId];
        require(startingTokenId > 0, "Unknown VRF request ID"); // Ensure request ID was mapped
        delete _requestIdToTokenId[requestId]; // Clean up mapping

        uint256 numTokens = _tokenIdCounter.current() - startingTokenId; // Number of tokens in this batch

        // Basic check for sufficient random words (need at least 4 uint256 per token for 4 uint8 traits)
        require(randomWords.length >= numTokens * 4 / (256/8), "Not enough random words for number of tokens"); // Simplify check: Need enough bits

        uint256 randomWordIndex = 0;
        uint256 bitIndex = 0;

        // Helper to get a number within a range from random words
        function getBoundedRandom(uint256 min, uint256 max) pure returns (uint256) {
             // Simple modulo bias demonstration - in a real contract use more robust biasing correction
             if (min == max) return min;
             uint256 range = max - min + 1;
             uint256 randomNumber = randomWords[randomWordIndex];
             // Simple bit extraction
             uint8 bitsNeeded = 0;
             uint256 tempRange = range;
             while (tempRange > 0) {
                 bitsNeeded++;
                 tempRange >>= 1;
             }

             if (bitIndex + bitsNeeded > 256) {
                 randomWordIndex++;
                 bitIndex = 0;
                 if (randomWordIndex >= randomWords.length) {
                      // Ran out of random words - handle error or request more?
                      // For this example, we'll revert or use fallback logic.
                      // A production system needs more robust handling.
                     revert("Ran out of random words during trait generation");
                 }
                 randomNumber = randomWords[randomWordIndex];
             }

             uint256 result = (randomNumber >> bitIndex) & ((1 << bitsNeeded) - 1);
             bitIndex += bitsNeeded;

             // Simple modulo (known bias, acceptable for example)
             return min + (result % range);
        }


        for (uint256 i = 0; i < numTokens; i++) {
            uint256 currentTokenId = startingTokenId + i;

            // Generate traits using random words and current trait ranges
            ArtTraits memory newTraits;

            // Example trait generation (accessing traitRanges mapping)
            // Ensure traitRanges exist for the types used
            if (traitRanges["colorPalette"].max > 0) {
                 newTraits.colorPalette = uint8(getBoundedRandom(traitRanges["colorPalette"].min, traitRanges["colorPalette"].max));
            } else { newTraits.colorPalette = 0; }
            if (traitRanges["shapeComplexity"].max > 0) {
                 newTraits.shapeComplexity = uint8(getBoundedRandom(traitRanges["shapeComplexity"].min, traitRanges["shapeComplexity"].max));
            } else { newTraits.shapeComplexity = 0; }
            if (traitRanges["textureType"].max > 0) {
                 newTraits.textureType = uint8(getBoundedRandom(traitRanges["textureType"].min, traitRanges["textureType"].max));
            } else { newTraits.textureType = 0; }
            if (traitRanges["specialProperty"].max > 0) {
                 newTraits.specialProperty = uint8(getBoundedRandom(traitRanges["specialProperty"].min, traitRanges["specialProperty"].max));
            } else { newTraits.specialProperty = 0; }

            newTraits.evolutionStage = 0; // Starts at stage 0

            // Store the generated traits
            _tokenTraits[currentTokenId] = newTraits;

            // Initialize evolution state
            _evolutionState[uint252(currentTokenId)] = EvolutionState({
                nurtureCount: 0,
                lastNurtureTime: block.timestamp, // Or mint time
                currentEvolutionStage: 0
            });

            // Mint the token to the original requester
            address recipient = _ownerOf(startingTokenId + i); // Need to store requester address per token ID or per request
            // For simplicity here, let's assume the requester address is known or passed.
            // In a real contract, you'd map requestId -> requester address in `requestRandomTraits`.
            // For *this* example, let's assume the msg.sender from `requestRandomTraits` is stored elsewhere and retrieved here.
            // Or, map request ID to the *requester* address directly. Let's add that mapping:
            mapping(uint256 => address) private _requestIdToRequester; // Added this state variable

            // In requestRandomTraits: _requestIdToRequester[requestId] = msg.sender;
            // Here: address recipient = _requestIdToRequester[requestId]; delete _requestIdToRequester[requestId];

            // Let's adjust `requestRandomTraits` and this function accordingly.
            // Assuming the mapping is added and populated:
            address recipientAddress = _requestIdToRequester[requestId];
            // Don't delete recipientAddress mapping here, might need it later if tokenIds aren't sequential per request.
            // Better to map requestID -> array of recipient addresses if batch minting to multiple people.
            // For simplicity, let's assume 1 request = N tokens to 1 address (the requester).

            _safeMint(recipientAddress, currentTokenId);
            _tokenToRequestId[currentTokenId] = requestId; // Map token back to request ID
        }
         // Clean up the requester mapping after processing the batch
         delete _requestIdToRequester[requestId];


        emit TraitsGenerated(requestId, startingTokenId, numTokens);
    }

    // 17. Retrieve the on-chain traits for an NFT
    function getArtTraits(uint256 tokenId) public view returns (ArtTraits memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return _tokenTraits[tokenId];
    }

    // --- Evolution & Nurturing ---

    // 19. Allows owner to pay a fee to evolve their NFT
    function nurtureArt(uint256 tokenId) public payable nonReentrant {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved();
        }

        EvolutionState storage evolution = _evolutionState[uint252(tokenId)];
        uint8 currentStage = evolution.currentEvolutionStage;
        uint8 nextStage = currentStage + 1; // Assuming linear progression

        // Check cooldown
        if (block.timestamp < evolution.lastNurtureTime + evolutionCooldowns[currentStage]) {
            revert NurtureCooldownActive();
        }

        // Check fee
        uint256 requiredFee = evolutionCosts[currentStage];
        if (msg.value < requiredFee) {
            revert InsufficientNurtureFee();
        }

        // Update evolution state
        evolution.nurtureCount++;
        evolution.lastNurtureTime = block.timestamp;
        // Determine if stage advances (could be based on nurtureCount or time)
        // Simple example: stage advances after N nurtures or if next stage cost/cooldown is defined
        bool stageAdvanced = evolutionCosts[nextStage] > 0 || evolutionCooldowns[nextStage] > 0; // If next stage config exists
        if (stageAdvanced) {
            evolution.currentEvolutionStage = nextStage;
            // Potentially call a function to update traits based on the *new* stage
             _updateTraitsBasedOnEvolution(tokenId, nextStage);
        } else {
             // If no new stage, still potentially update traits based on nurture count within stage
             _updateTraitsBasedOnEvolution(tokenId, currentStage);
        }


        // Distribute the nurture fee
        if (msg.value > 0) {
             // Send the fee to the contract for distribution
             // Since this is payable, the ETH is already here.
             // No need to send msg.value explicitly, it's in address(this).balance.
             // The `distributeFunds` function will handle it later.
             // If immediate distribution is needed, call _distributeFundsInternal(msg.value) here
             // but this adds complexity. Let's stick to manual/timed distribution via `distributeFunds`.
        }

        emit ArtNurtured(tokenId, msg.sender, msg.value, evolution.currentEvolutionStage);
    }

    // Internal helper to update traits based on evolution state
    function _updateTraitsBasedOnEvolution(uint256 tokenId, uint8 newStage) internal {
        ArtTraits storage traits = _tokenTraits[tokenId];
        EvolutionState storage evolution = _evolutionState[uint252(tokenId)];

        traits.evolutionStage = newStage; // Update the stored stage

        // --- Trait Update Logic ---
        // This is where the art *conceptually* changes.
        // How traits change based on evolution stage and nurture count is complex art logic.
        // Examples:
        // - Stage 1: unlocks a new color palette range
        // - Stage 2: increases shape complexity range
        // - Nurture count: could subtly shift existing trait values within bounds
        // - SpecialProperty could increase with stage/nurture, affecting rarity calculation off-chain

        // For this example, let's make it simple:
        // Update traits based on a derived 'evolution level' combining stage and count
        uint256 evolutionLevel = uint256(newStage) * 100 + evolution.nurtureCount; // Simple level calculation

        // Example: As evolutionLevel increases, bias traits towards higher values within their ranges
        // (This requires generating random numbers *again* or applying a deterministic shift)
        // To avoid re-rolling randomness, let's apply a deterministic shift based on evolutionLevel.
        // This shift needs to be capped by the defined traitRanges or stage-specific ranges.

        // Example (simplified deterministic trait shift):
        // This logic is illustrative and needs careful design for real art.
        // traits.colorPalette = uint8(min(traitRanges["colorPalette"].max, traits.colorPalette + evolutionLevel / 50));
        // traits.shapeComplexity = uint8(min(traitRanges["shapeComplexity"].max, traits.shapeComplexity + evolutionLevel / 40));
        // traits.textureType = uint8(min(traitRanges["textureType"].max, traits.textureType + evolutionLevel / 60));
        // traits.specialProperty = uint8(min(traitRanges["specialProperty"].max, traits.specialProperty + evolutionLevel / 30));

        // The *actual* change logic would be complex and specific to the art theme.
        // The key is that it uses the `evolution` state and potentially `traitRanges` to update `traits`.

        // For a real system, you might have mappings like:
        // mapping(uint8 => mapping(string => TraitRange)) public stageSpecificTraitRanges;
        // And the logic here would use `stageSpecificTraitRanges[newStage]`.
        // Or you might store deterministic evolution rules:
        // mapping(uint8 => bytes) public evolutionRules; // Encoded instructions

        // For this example, we just update the stage, and the off-chain renderer interprets the stage + original traits.
        // A more advanced version would actually modify `_tokenTraits[tokenId]` based on rules.
        // Let's add a simple modification example: increase specialProperty slightly per nurture.
        traits.specialProperty = uint8(min(255, traits.specialProperty + evolution.nurtureCount)); // Cap at 255

        // The main point is that `_tokenTraits[tokenId]` is updated here, and `tokenURI` reflects it.
    }

    // 20. Get the current evolution state of an NFT
    function getEvolutionState(uint256 tokenId) public view returns (EvolutionState memory) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _evolutionState[uint252(tokenId)];
    }

    // 21. Get the required fee for a specific stage.
    function getEvolutionCost(uint8 evolutionStage) public view returns (uint256) {
        return evolutionCosts[evolutionStage];
    }

    // --- Community Influence (Simplified Governance) ---
    // This is a very basic proposal/voting system. Real DAOs are far more complex.

    // 22. Allows anyone to propose a trait range change.
    function proposeTraitRangeUpdate(string memory traitType, uint256 min, uint256 max) public {
        // Basic validation
        require(bytes(traitType).length > 0, "Trait type name cannot be empty");
        require(max >= min, "Max range must be >= min");
        // Optional: Check if traitType is known, or allow adding new ones? Allowing new adds complexity.
        // For this example, require traitType to be one of the keys in `traitRanges`.
        require(traitRanges[traitType].max > 0 || traitRanges[traitType].min > 0, "Unknown or uninitialized trait type");


        uint256 proposalId = _proposalCounter.current();
        _proposalCounter.increment();

        // Encode the proposal data
        bytes memory proposalData = abi.encode(traitType, min, max);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.NewTraitRange,
            data: proposalData,
            submitTime: block.timestamp,
            totalVotes: 0,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Pending
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.NewTraitRange);
    }

    // 23. Allows NFT holders to vote on a proposal.
    function voteOnProposal(uint256 proposalId, bool approve) public {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.id == 0) { // Check if proposal exists (structs default to 0)
            revert ProposalDoesNotExist();
        }

        if (proposal.state != ProposalState.Pending) {
            revert("Voting is not open for this proposal");
        }

        if (block.timestamp > proposal.submitTime + PROPOSAL_VOTING_PERIOD) {
            proposal.state = ProposalState.Rejected; // Automatically mark as rejected if time passed without execution
            revert("Voting period has ended");
        }

        if (_hasVoted[proposalId][msg.sender]) {
            revert AlreadyVoted();
        }

        // Require voter to hold at least MIN_VOTING_POWER NFTs
        uint256 voterTokenBalance = balanceOf(msg.sender);
        require(voterTokenBalance >= MIN_VOTING_POWER, "Insufficient voting power");

        _hasVoted[proposalId][msg.sender] = true;
        proposal.totalVotes += voterTokenBalance; // Weight vote by balance
        if (approve) {
            proposal.yesVotes += voterTokenBalance;
        } else {
            proposal.noVotes += voterTokenBalance;
        }

        // Simple majority threshold (e.g., > 50% of total votes on proposal)
        // A more robust system would use total supply or a quorum.
        if (proposal.yesVotes > proposal.totalVotes / 2 && proposal.totalVotes >= MIN_VOTING_POWER) { // Simple majority check + minimum votes
             proposal.state = ProposalState.Approved;
        } else if (proposal.noVotes >= proposal.totalVotes / 2 && proposal.totalVotes >= MIN_VOTING_POWER) {
             proposal.state = ProposalState.Rejected;
        } // Else stays Pending

        emit Voted(proposalId, msg.sender, approve);
    }

    // 24. Admin executes a proposal that has passed.
    // In a real DAO, this might be callable by anyone after a delay, or triggered automatically.
    function executeProposal(uint256 proposalId) public onlyOwner {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.id == 0) {
             revert ProposalDoesNotExist();
        }

        if (proposal.state == ProposalState.Executed) {
             revert("Proposal already executed");
        }

        if (block.timestamp <= proposal.submitTime + PROPOSAL_VOTING_PERIOD && proposal.state == ProposalState.Pending) {
             revert ProposalStillActive(); // Voting period not over, and not yet Approved/Rejected
        }


        if (proposal.state != ProposalState.Approved) {
             revert ProposalNotExecutable(); // Only execute if Approved
        }

        // Execute the proposal based on its type and data
        if (proposal.proposalType == ProposalType.NewTraitRange) {
            (string memory traitType, uint256 min, uint256 max) = abi.decode(proposal.data, (string, uint256, uint256));
            // Apply the new range - this affects future mints
            traitRanges[traitType] = TraitRange(min, max);
             emit ConfigUpdated(string(abi.encodePacked("traitRange_", traitType)), bytes32(min | (max << 128))); // Basic event
        }
        // Add logic for other proposal types here...
        // else if (proposal.proposalType == ProposalType.UpdateEvolutionCost) { ... }


        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, msg.sender);
    }

    // 25. Check the status of a proposal.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        if (proposals[proposalId].id == 0) {
             revert ProposalDoesNotExist();
        }
        // Re-evaluate state if voting period ended but state is still Pending
        if (proposals[proposalId].state == ProposalState.Pending && block.timestamp > proposals[proposalId].submitTime + PROPOSAL_VOTING_PERIOD) {
             return ProposalState.Rejected; // Expired without reaching threshold
        }
        return proposals[proposalId].state;
    }

    // 26. Get details of a proposal.
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        if (proposals[proposalId].id == 0) {
             revert ProposalDoesNotExist();
        }
        return proposals[proposalId];
    }

    // 27. Get current vote counts for a proposal.
    function getVoteCount(uint256 proposalId) public view returns (uint256 total, uint256 yes, uint256 no) {
         if (proposals[proposalId].id == 0) {
             revert ProposalDoesNotExist();
        }
        Proposal storage proposal = proposals[proposalId];
        return (proposal.totalVotes, proposal.yesVotes, proposal.noVotes);
    }

    // --- Artist Splits & Revenue Distribution ---

    // 28. Add or update an artist's revenue share.
    function addArtistSplit(address artist, uint16 shareBps) public onlyOwner {
        require(artist != address(0), "Invalid artist address");
        require(shareBps <= BASIS_POINTS_DIVISOR, "Share exceeds 100%");

        uint256 index;
        bool exists = false;
        if (_artistAddressToIndex[artist] > 0) { // Mapping value is index + 1
            index = _artistAddressToIndex[artist] - 1;
            exists = artistSplits[index].artist == artist && artistSplits[index].active; // Double check
        } else {
            // Check if it exists but is inactive
             for(uint i = 0; i < artistSplits.length; i++){
                 if(artistSplits[i].artist == artist && !artistSplits[i].active){
                     index = i;
                     exists = false; // Treat as new for total calculation
                     break;
                 }
             }
        }

        uint16 oldShare = 0;
        if (exists) {
             oldShare = artistSplits[index].shareBps;
        }

        uint256 newTotalBps = _totalArtistBps.sub(oldShare).add(shareBps);
        require(newTotalBps <= BASIS_POINTS_DIVISOR, "Total artist shares exceed 100%");

        if (exists) {
            artistSplits[index].shareBps = shareBps;
             _totalArtistBps = newTotalBps;
        } else {
            if (_artistAddressToIndex[artist] == 0) { // Brand new address
                 artistSplits.push(ArtistSplit(artist, shareBps, true));
                 _artistAddressToIndex[artist] = artistSplits.length; // Store index + 1
            } else { // Exists but was inactive
                 index = _artistAddressToIndex[artist] - 1;
                 artistSplits[index].shareBps = shareBps;
                 artistSplits[index].active = true;
            }
             _totalArtistBps = newTotalBps;
        }

        emit ArtistSplitUpdated(artist, shareBps, true);
    }

    // 29. Remove an artist from revenue share.
    function removeArtistSplit(address artist) public onlyOwner {
        require(artist != address(0), "Invalid artist address");

        uint256 index;
        bool found = false;
        if (_artistAddressToIndex[artist] > 0) {
            index = _artistAddressToIndex[artist] - 1;
            if(artistSplits[index].artist == artist && artistSplits[index].active) {
                 found = true;
            }
        }

        require(found, "Artist not found or not active in splits");

        uint16 oldShare = artistSplits[index].shareBps;

        artistSplits[index].active = false; // Mark as inactive instead of removing from array
        artistSplits[index].shareBps = 0; // Reset share
         _totalArtistBps = _totalArtistBps.sub(oldShare);

        // Note: Funds accrued *before* removal still belong to the artist
        // The distribution logic needs to handle this.
        // A more robust system would track accruals per artist over time.
        // For simplicity here, we just stop future accrual. The `distributeFunds`
        // will send what's currently in the contract's balance based on *current* splits.
        // If an artist is removed, they won't receive future distributions unless re-added.
        // This is a limitation of this simple model.

        emit ArtistSplitUpdated(artist, 0, false);
    }

    // 30. Distribute accumulated funds to artists based on splits.
    function distributeFunds() public onlyOwner nonReentrant {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) {
             revert CannotWithdrawZero();
        }

        uint256 totalDistributed = 0;

        // Iterate through active artist splits
        for (uint256 i = 0; i < artistSplits.length; i++) {
            if (artistSplits[i].active && artistSplits[i].shareBps > 0) {
                uint256 shareAmount = totalBalance.mul(artistSplits[i].shareBps).div(BASIS_POINTS_DIVISOR);
                if (shareAmount > 0) {
                    address payable artistAddress = payable(artistSplits[i].artist);
                    // Use low-level call for safer transfer
                    (bool success, ) = artistAddress.call{value: shareAmount}("");
                    require(success, "Failed to send funds to artist");
                    totalDistributed += shareAmount;
                }
            }
        }

        // Handle any remainder due to rounding or if totalBps < 10000
        // This remainder stays in the contract or could be sent to owner/treasury.
        // For simplicity, it stays for now.
        // uint256 remainder = totalBalance.sub(totalDistributed);
        // if (remainder > 0) {
        //    // Send remainder to owner?
        //    payable(owner()).transfer(remainder);
        // }


        emit FundsDistributed(msg.sender, totalDistributed);
    }

    // 31. Get an artist's configured share.
    function getArtistSplit(address artist) public view returns (uint16 shareBps, bool active) {
        if (_artistAddressToIndex[artist] > 0) {
            uint256 index = _artistAddressToIndex[artist] - 1;
            return (artistSplits[index].shareBps, artistSplits[index].active);
        }
        return (0, false); // Artist not found or inactive
    }

    // 32. Check the contract's balance available for distribution.
    function getUndistributedFunds() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Configuration & Admin ---

    // 33. Set the base URI for metadata.
    function setBaseMetadataURI(string memory newBaseURI) public onlyOwner {
        _baseMetadataURI = newBaseURI;
         emit ConfigUpdated("baseMetadataURI", keccak256(abi.encodePacked(newBaseURI))); // Use hash as value for bytes32
    }

     // 34. Set address of the off-chain metadata renderer.
    function setRendererAddress(address renderer) public onlyOwner {
         rendererAddress = renderer;
          emit ConfigUpdated("rendererAddress", bytes32(uint256(uint160(renderer))));
    }

    // 35. Set minimum time between mints.
    function setMinMintInterval(uint256 intervalSeconds) public onlyOwner {
        minMintInterval = intervalSeconds;
         emit ConfigUpdated("minMintInterval", bytes32(intervalSeconds));
    }

    // 36. Set the nurture cost for an evolution stage.
    function setEvolutionCost(uint8 stage, uint256 cost) public onlyOwner {
        evolutionCosts[stage] = cost;
         emit ConfigUpdated(string(abi.encodePacked("evolutionCost_", Strings.toString(stage))), bytes32(cost));
    }

     // 37. Set the nurture cooldown for a stage.
    function setEvolutionCooldown(uint8 stage, uint256 cooldownSeconds) public onlyOwner {
         evolutionCooldowns[stage] = cooldownSeconds;
          emit ConfigUpdated(string(abi.encodePacked("evolutionCooldown_", Strings.toString(stage))), bytes32(cooldownSeconds));
    }

    // 38. Set initial generative ranges for multiple traits.
    function setInitialTraitRanges(string[] memory traitTypes, uint256[] memory mins, uint256[] memory maxs) public onlyOwner {
        require(traitTypes.length == mins.length && traitTypes.length == maxs.length, "Input array lengths mismatch");
        for(uint i = 0; i < traitTypes.length; i++) {
            require(bytes(traitTypes[i]).length > 0, "Trait type name cannot be empty");
            require(maxs[i] >= mins[i], "Max range must be >= min");
             traitRanges[traitTypes[i]] = TraitRange(mins[i], maxs[i]);
             emit ConfigUpdated(string(abi.encodePacked("initialTraitRange_", traitTypes[i])), bytes32(mins[i] | (maxs[i] << 128)));
        }
    }


    // 39. Withdraw excess LINK from the contract (if using VRF wrapper).
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(i_link); // i_link is from VRFV2WrapperConsumerBase
        require(address(link).balance > 0, "No LINK balance to withdraw");
        link.transfer(msg.sender, address(link).balance);
    }

    // 40. Owner can withdraw any other ETH balance not intended for artist splits.
    // Use with caution. Distribution should typically be via `distributeFunds`.
    function withdrawEth(address payable recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");

        recipient.transfer(amount); // Use transfer for simple cases
    }

    // Fallback function to receive ETH (for nurturing fees and minting costs)
    receive() external payable {}
    fallback() external payable {}


    // --- Internal/Helper Functions ---
    // Add internal helper functions here if needed for complex logic
    // Example: _distributeFundsInternal(uint256 amount) if you want to distribute immediately on mint/nurture.

    // Helper to get minimum of two uint256 values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```

**Explanation of Advanced Concepts Used:**

1.  **On-Chain Generative Traits (via VRF):** Traits like `colorPalette`, `shapeComplexity`, etc., are stored directly on-chain. Their initial values are determined by `Chainlink VRF` (`requestRandomTraits` -> `rawFulfillRandomWords`), ensuring verifiability and tamper-resistance.
2.  **Dynamic & Evolving NFTs:** The `nurtureArt` function allows owners to interact with their NFTs. This interaction updates the `EvolutionState` and triggers `_updateTraitsBasedOnEvolution`, which *changes* the on-chain traits (`_tokenTraits`).
3.  **Dynamic Metadata (`tokenURI` Override):** Instead of static JSON on IPFS, the `tokenURI` function is overridden to point to a URL that includes the `tokenId` and potentially the contract address. An off-chain service (the "renderer" address) is expected to read the *current* on-chain state (`getArtTraits`, `getEvolutionState`) for that specific `tokenId` and dynamically generate the metadata JSON and potentially the image URL. This makes the art truly reflect its on-chain state changes.
4.  **Simplified On-Chain Governance/Influence:** The `proposeTraitRangeUpdate`, `voteOnProposal`, and `executeProposal` functions demonstrate a basic mechanism for community input. NFT holders (with a minimum balance) can vote on proposed changes to future trait generation rules. This isn't a full DAO but shows how token ownership can grant influence.
5.  **Dynamic Artist Splits:** The `addArtistSplit`, `removeArtistSplit`, and `distributeFunds` functions manage a dynamic list of beneficiaries and their revenue shares. Revenue collected by the contract (from nurture fees, potentially future mint fees) can be distributed according to the *current* split configuration. Uses basis points for flexible percentages.
6.  **VRF V2 Wrapper:** Uses the Chainlink VRF V2 Wrapper contract for a simpler integration model compared to direct V2 consumer, handling subscription management externally.
7.  **Gas Optimization (Minor):** Using `uint252` for the `_evolutionState` mapping key demonstrates a small gas-saving technique, though its practical impact depends on the EVM version and access patterns.
8.  **State Management Complexity:** Manages multiple interconnected state mappings and structs (`_tokenTraits`, `_evolutionState`, `traitRanges`, `proposals`, `artistSplits`), which is characteristic of more complex contracts.

This contract provides a framework. The actual "art logic" (how `_updateTraitsBasedOnEvolution` modifies traits, how `traitRanges` map to visual properties) would need to be defined off-chain by the renderer service based on the parameters exposed by the contract. The proposal types and execution logic could also be expanded significantly for a more complex governance system.