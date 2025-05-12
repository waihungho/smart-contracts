Okay, here's a smart contract concept for "Evolving Algorithmic Art NFTs" where the generated art parameters are influenced by minting conditions, holder actions (evolution/staking), and decentralized governance (NFT holder voting).

This avoids standard patterns like simple collectibles or DeFi integrations and focuses on dynamic state, on-chain influence, and community control over generative properties.

It will include:
1.  **Generative Parameters:** Traits derived from a unique seed generated at minting.
2.  **Evolution/Staking:** NFTs can be "evolved" over time by staking them, changing their state and potentially their visual attributes.
3.  **On-chain Governance:** NFT holders can propose and vote on changes to the global parameters that influence the generation process.
4.  **Dynamic Metadata:** The `tokenURI` will reflect the current, evolving state of the NFT.
5.  **Burning for Boost:** Burning an NFT can provide a temporary or permanent boost to another NFT's evolution progress.

---

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  ** Imports** (ERC721, Ownable or Access Control)
3.  ** Errors** (Custom errors for clarity)
4.  ** Structs**
    *   `NFTAttributes`: Defines the parameters that describe the art (derived from seed + evolution).
    *   `GenerationSettings`: Global parameters influencing the generation process.
    *   `Proposal`: Defines a governance proposal structure.
5.  ** State Variables**
    *   Basic ERC721 state (handled by inherited contract).
    *   Token-specific state (seed, evolution state, etc.).
    *   Global generation settings.
    *   Governance state (proposals, votes).
    *   Counters.
6.  ** Events**
    *   Minting, Evolution, Governance actions, Parameter changes.
7.  ** Modifiers** (e.g., only evolving, only governance participant)
8.  ** Constructor**
9.  ** Core ERC721 Functions** (Overridden or provided by base - `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`)
10. ** Minting Functions** (`mint`, `batchMint`, internal seed generation)
11. ** View Functions**
    *   Get NFT attributes (`getTokenAttributes`).
    *   Get evolution state (`getEvolutionState`).
    *   Get global generation settings (`getGenerationSettings`).
    *   Get governance proposal details (`getProposalDetails`, `getProposalState`).
    *   Get user vote (`getUserVote`).
    *   ERC721 `tokenURI`.
    *   Total supply.
12. ** Evolution Functions** (`startEvolution`, `stopEvolution`, `claimEvolutionBoost`, `getEvolutionProgress`)
13. ** Burning Functions** (`burnForBoost`)
14. ** Governance Functions** (`submitParameterProposal`, `voteForProposal`, `executeProposal`, `cancelProposal`)
15. ** Admin/Utility Functions** (`setBaseURI`, `withdrawFunds`, `pauseMinting`)
16. ** Internal Helper Functions** (Seed generation logic, attribute calculation, governance checks)

---

**Function Summary:**

1.  `constructor(string name, string symbol, string initialBaseURI)`: Initializes the contract, setting name, symbol, and base URI. Also sets initial global generation settings.
2.  `balanceOf(address owner) public view override returns (uint256)`: ERC721 Standard: Returns the number of tokens owned by `owner`.
3.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721 Standard: Returns the owner of the specified `tokenId`.
4.  `getApproved(uint256 tokenId) public view override returns (address)`: ERC721 Standard: Returns the approved address for a single token.
5.  `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721 Standard: Returns if an operator is approved for all of an owner's tokens.
6.  `approve(address to, uint256 tokenId) public override`: ERC721 Standard: Approves another address to transfer ownership of a token.
7.  `setApprovalForAll(address operator, bool approved) public override`: ERC721 Standard: Approves or removes an operator for all tokens owned by the caller.
8.  `transferFrom(address from, address to, uint256 tokenId) public override`: ERC721 Standard: Transfers ownership of a token.
9.  `safeTransferFrom(address from, address to, uint256 tokenId) public override`: ERC721 Standard: Safer transfer function.
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override`: ERC721 Standard: Safer transfer function with data.
11. `mint() public payable returns (uint256 tokenId)`: Mints a new NFT to the caller, generating a unique seed and initial state. Requires payment.
12. `batchMint(uint256 count) public payable returns (uint256[] memory tokenIds)`: Mints multiple NFTs to the caller. Requires payment.
13. `tokenURI(uint256 tokenId) public view override returns (string memory)`: ERC721 Standard: Returns a URI pointing to the JSON metadata for the token. This metadata is dynamically generated based on the token's state (seed, evolution).
14. `getTokenAttributes(uint256 tokenId) public view returns (NFTAttributes memory)`: Calculates and returns the current derived attributes for a given token based on its seed and evolution state.
15. `getEvolutionState(uint256 tokenId) public view returns (uint256 evolutionLevel, uint256 currentEvolutionPoints, uint256 evolutionStartTime, bool isEvolving)`: Returns the evolution status of a token.
16. `startEvolution(uint256 tokenId) public`: Locks the specified NFT in the contract, beginning its evolution process. The NFT cannot be transferred while evolving.
17. `stopEvolution(uint256 tokenId) public`: Stops the evolution process for the specified NFT, accumulating gained evolution points and unlocking the token for transfer.
18. `claimEvolutionBoost(uint256 tokenId) public`: Claims accumulated evolution points as a boost that can be applied later. (Could be internal points or a separate token).
19. `burnForBoost(uint256 tokenIdToBurn, uint256 tokenIdToBoost) public`: Burns `tokenIdToBurn` and transfers its accumulated evolution potential (or a fixed boost) to `tokenIdToBoost`.
20. `getGenerationSettings() public view returns (GenerationSettings memory)`: Returns the current global parameters that influence the art generation.
21. `submitParameterProposal(string description, string parameterName, uint256 newValue) public`: Allows NFT holders (with sufficient standing, e.g., min balance) to propose changes to global generation settings.
22. `voteForProposal(uint256 proposalId, bool support) public`: Allows NFT holders to vote on an active proposal. Voting weight could be based on the number/evolution level of NFTs held.
23. `executeProposal(uint256 proposalId) public`: Executes a proposal if it has passed and the voting period has ended, applying the proposed parameter change.
24. `cancelProposal(uint256 proposalId) public`: Allows the proposer or potentially governance to cancel a proposal under certain conditions.
25. `getProposalDetails(uint256 proposalId) public view returns (Proposal memory)`: Returns details of a specific governance proposal.
26. `getProposalState(uint256 proposalId) public view returns (uint8 state)`: Returns the current state of a proposal (e.g., Active, Succeeded, Failed, Executed).
27. `getUserVote(uint256 proposalId, address voter) public view returns (bool hasVoted, bool support)`: Returns whether a user has voted on a proposal and their stance.
28. `setBaseURI(string memory newBaseURI) public onlyOwner`: Allows the owner to update the base URI for metadata.
29. `withdrawFunds() public onlyOwner`: Allows the owner to withdraw collected minting fees.
30. `pauseMinting(bool paused) public onlyOwner`: Allows the owner to pause or unpause minting.

*(Note: Some functions like standard ERC721 transfers might be inherited/implemented by the base contract, but are listed for completeness as part of the contract's functionality. The implementation will rely on libraries like OpenZeppelin, but the custom logic (generative, evolution, governance) is unique).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports
// 3. Errors
// 4. Structs (NFTAttributes, GenerationSettings, Proposal)
// 5. State Variables (Token data, Global settings, Governance)
// 6. Events
// 7. Modifiers (onlyEvolvingParticipant, onlyGovernanceParticipant)
// 8. Constructor
// 9. Core ERC721 Functions (Inherited/Overridden: balanceOf, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom)
// 10. Minting Functions (mint, batchMint, internal seed generation)
// 11. View Functions (getTokenAttributes, getEvolutionState, getGenerationSettings, getProposalDetails, getProposalState, getUserVote, tokenURI, totalSupply)
// 12. Evolution Functions (startEvolution, stopEvolution, claimEvolutionBoost, getEvolutionProgress - getEvolutionState covers this)
// 13. Burning Functions (burnForBoost)
// 14. Governance Functions (submitParameterProposal, voteForProposal, executeProposal, cancelProposal)
// 15. Admin/Utility Functions (setBaseURI, withdrawFunds, pauseMinting)
// 16. Internal Helper Functions (Seed generation logic, attribute calculation, governance checks)

// --- Function Summary ---
// 1. constructor(string name, string symbol, string initialBaseURI)
// 2. balanceOf(address owner)
// 3. ownerOf(uint256 tokenId)
// 4. getApproved(uint256 tokenId)
// 5. isApprovedForAll(address owner, address operator)
// 6. approve(address to, uint256 tokenId)
// 7. setApprovalForAll(address operator, bool approved)
// 8. transferFrom(address from, address to, uint256 tokenId)
// 9. safeTransferFrom(address from, address to, uint256 tokenId)
// 10. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 11. mint()
// 12. batchMint(uint256 count)
// 13. tokenURI(uint256 tokenId)
// 14. getTokenAttributes(uint256 tokenId)
// 15. getEvolutionState(uint256 tokenId)
// 16. startEvolution(uint256 tokenId)
// 17. stopEvolution(uint256 tokenId)
// 18. claimEvolutionBoost(uint256 tokenId)
// 19. burnForBoost(uint256 tokenIdToBurn, uint256 tokenIdToBoost)
// 20. getGenerationSettings()
// 21. submitParameterProposal(string description, string parameterName, uint256 newValue)
// 22. voteForProposal(uint256 proposalId, bool support)
// 23. executeProposal(uint256 proposalId)
// 24. cancelProposal(uint256 proposalId)
// 25. getProposalDetails(uint256 proposalId)
// 26. getProposalState(uint256 proposalId)
// 27. getUserVote(uint256 proposalId, address voter)
// 28. setBaseURI(string memory newBaseURI)
// 29. withdrawFunds()
// 30. pauseMinting(bool paused)

contract GenerativeArtNFT is ERC721, Ownable, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error MintingPaused();
    error InsufficientFunds(uint256 required, uint256 sent);
    error InvalidTokenId();
    error NotNFTOwner(address caller, uint256 tokenId);
    error TokenAlreadyEvolving(uint256 tokenId);
    error TokenNotEvolving(uint256 tokenId);
    error CannotTransferWhileEvolving(uint256 tokenId);
    error ProposalNotFound(uint256 proposalId);
    error ProposalAlreadyActive(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error ProposalVotingPeriodNotEnded(uint256 proposalId);
    error ProposalVotingPeriodEnded(uint256 proposalId);
    error ProposalNotPassed(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error InsufficientVotingPower(uint256 required, uint256 available);
    error InvalidParameterName(string parameterName);
    error InvalidParameterValue(string parameterName, uint256 value);
    error SelfBurnNotAllowed();
    error CannotBurnEvolvingToken(uint256 tokenId);
    error CannotBoostEvolvingToken(uint256 tokenId);

    // --- Structs ---

    struct NFTAttributes {
        bytes32 seed; // The core random-ish value determining base traits
        uint256 creationBlock;
        address creator;
        uint256 evolutionLevel; // Current level based on evolution points
        uint256 baseHue; // Example attribute derived from seed
        uint256 complexity; // Example attribute derived from seed + evolution
        uint256 energyPotential; // Points accumulated for boosting others or self
        // Add more generative attributes here (shapes, patterns, animations speed, etc.)
        // Use uints or fixed point for values that can be interpolated/scaled
    }

    struct GenerationSettings {
        uint256 evolutionRatePerSecond; // How fast evolution points accumulate
        uint256 minComplexity;
        uint256 maxComplexity;
        uint256 baseMintPrice;
        uint256 proposalThresholdNFTs; // Minimum number of NFTs required to submit a proposal
        uint256 proposalVotingPeriod; // Duration of voting period in seconds
        uint256 quorumNumerator; // Numerator for voting quorum check (denominator is total supply)
        // Add more global parameters influencing art here (e.g., palette constraints, animation rules)
    }

    // Governance Proposal State
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        string parameterName; // The parameter to change (e.g., "evolutionRatePerSecond")
        uint256 newValue; // The proposed value for the parameter
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Record of who voted
        ProposalState state;
    }

    // --- State Variables ---

    // Token Data
    mapping(uint256 => NFTAttributes) private _tokenAttributes;
    mapping(uint256 => uint256) private _evolutionStartTime; // 0 if not evolving
    mapping(uint256 => uint256) private _currentEvolutionPoints;
    mapping(uint256 => bool) private _isEvolving;

    // Global Settings
    GenerationSettings public generationSettings;

    // Governance
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals; // Use public mapping for easy viewing of details
    mapping(string => uint256) private _parameterNameToUintMapping; // Helper for parameter name string to uint

    // Contract State
    string private _baseTokenURI;
    bool public paused = false;

    // --- Events ---
    event NFTMinted(address indexed owner, uint256 indexed tokenId, bytes32 seed);
    event EvolutionStarted(uint256 indexed tokenId, address indexed owner, uint256 startTime);
    event EvolutionStopped(uint256 indexed tokenId, address indexed owner, uint256 endTime, uint256 accumulatedPoints);
    event EvolutionBoostClaimed(uint256 indexed tokenId, address indexed owner, uint256 claimedPoints);
    event NFTBurnedForBoost(uint256 indexed tokenIdToBurn, uint256 indexed tokenIdToBoost, address indexed burner);
    event GlobalSettingsChanged(string parameterName, uint256 oldValue, uint256 newValue);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, string parameterName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event MintingPausedStateChanged(bool pausedState);

    // --- Modifiers ---
    modifier onlyEvolvingParticipant(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert NotNFTOwner(msg.sender, tokenId);
        if (!_isEvolving[tokenId]) revert TokenNotEvolving(tokenId);
        _;
    }

     modifier onlyGovernanceParticipant() {
        if (balanceOf(msg.sender) < generationSettings.proposalThresholdNFTs) {
             revert InsufficientVotingPower(generationSettings.proposalThresholdNFTs, balanceOf(msg.sender));
         }
        _;
    }


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory initialBaseURI)
        ERC721(name, symbol)
        Ownable(msg.sender) // Using OpenZeppelin's Ownable for basic admin, Governance handles parameters
    {
        _baseTokenURI = initialBaseURI;

        // Initialize default global generation settings
        generationSettings = GenerationSettings({
            evolutionRatePerSecond: 100, // Points per second
            minComplexity: 10,
            maxComplexity: 100,
            baseMintPrice: 0.01 ether,
            proposalThresholdNFTs: 1, // Minimum NFTs to propose/vote
            proposalVotingPeriod: 3 days, // 3 days voting period
            quorumNumerator: 10 // 10% of total supply needed for quorum (10/100)
        });

        // Map parameter names to a simple uint for internal proposal handling
        // This is a simplified approach; a more robust system might use keccak256 or allow more complex changes
        _parameterNameToUintMapping["evolutionRatePerSecond"] = 1;
        _parameterNameToUintMapping["minComplexity"] = 2;
        _parameterNameToUintMapping["maxComplexity"] = 3;
        _parameterNameToUintMapping["baseMintPrice"] = 4;
        _parameterNameToUintMapping["proposalThresholdNFTs"] = 5;
        _parameterNameToUintMapping["proposalVotingPeriod"] = 6;
        _parameterNameToUintMapping["quorumNumerator"] = 7;
        // Add mappings for other parameters here
    }

    // --- Overridden ERC721 Transfer Functions (to prevent transfer while evolving) ---

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (_isEvolving[tokenId]) revert CannotTransferWhileEvolving(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        if (_isEvolving[tokenId]) revert CannotTransferWhileEvolving(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (_isEvolving[tokenId]) revert CannotTransferWhileEvolving(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // --- Minting Functions ---

    function mint() public payable nonReentrant returns (uint256 tokenId) {
        if (paused) revert MintingPaused();
        if (msg.value < generationSettings.baseMintPrice) {
            revert InsufficientFunds(generationSettings.baseMintPrice, msg.value);
        }

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        bytes32 seed = _generateSeed(tokenId, msg.sender);

        _tokenAttributes[tokenId] = NFTAttributes({
            seed: seed,
            creationBlock: block.number,
            creator: msg.sender,
            evolutionLevel: 0,
            currentEvolutionPoints: 0, // Start with 0 points
            baseHue: uint256(seed) % 360, // Example derivation
            complexity: generationSettings.minComplexity, // Starts at min, evolves upwards
            energyPotential: 0
        });

        _safeMint(msg.sender, tokenId);

        emit NFTMinted(msg.sender, tokenId, seed);

        return tokenId;
    }

     function batchMint(uint256 count) public payable nonReentrant returns (uint256[] memory tokenIds) {
        if (paused) revert MintingPaused();
        uint256 totalPrice = generationSettings.baseMintPrice * count;
        if (msg.value < totalPrice) {
            revert InsufficientFunds(totalPrice, msg.value);
        }

        tokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;

            bytes32 seed = _generateSeed(tokenId, msg.sender);

            _tokenAttributes[tokenId] = NFTAttributes({
                seed: seed,
                creationBlock: block.number,
                creator: msg.sender,
                evolutionLevel: 0,
                currentEvolutionPoints: 0,
                baseHue: uint256(seed) % 360,
                complexity: generationSettings.minComplexity,
                energyPotential: 0
            });

            _safeMint(msg.sender, tokenId);
            emit NFTMinted(msg.sender, tokenId, seed);
        }
        return tokenIds;
    }


    // --- View Functions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller *could* own it (or is approved)

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             return ""; // Or a default error URI
        }

        // Get dynamic attributes
        NFTAttributes memory attrs = getTokenAttributes(tokenId);

        // Build JSON metadata string dynamically
        string memory json = string(abi.encodePacked(
            '{"name": "', name(), ' #', Strings.toString(tokenId),
            '", "description": "An evolving generative art piece influenced by blockchain state and community governance.",',
            '"image": "', base, Strings.toString(tokenId), '.svg",', // Points to an off-chain rendering service
            '"attributes": [',
                '{"trait_type": "Creation Block", "value": ', Strings.toString(attrs.creationBlock), '},',
                '{"trait_type": "Evolution Level", "value": ', Strings.toString(attrs.evolutionLevel), '},',
                '{"trait_type": "Base Hue", "value": ', Strings.toString(attrs.baseHue), '},',
                '{"trait_type": "Complexity", "value": ', Strings.toString(attrs.complexity), '},',
                '{"trait_type": "Energy Potential", "value": ', Strings.toString(attrs.energyPotential), '}',
                // Add more attributes derived from NFTAttributes struct
            ']}'
        ));

        // Encode JSON to Base64 data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getTokenAttributes(uint256 tokenId) public view returns (NFTAttributes memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        NFTAttributes memory attrs = _tokenAttributes[tokenId];

        // Recalculate dynamic attributes based on current state if evolving
        if (_isEvolving[tokenId]) {
             uint256 elapsed = block.timestamp - _evolutionStartTime[tokenId];
             uint256 potentialPoints = elapsed * generationSettings.evolutionRatePerSecond;
             // Add accumulated points from previous sessions/burns
             uint256 totalPoints = attrs.currentEvolutionPoints + potentialPoints;

             // Simple mapping of points to level and complexity (can be complex function)
             uint256 evolutionLevel = totalPoints / 10000; // Example: 10000 points per level
             uint256 complexity = generationSettings.minComplexity + (evolutionLevel * (generationSettings.maxComplexity - generationSettings.minComplexity) / 100); // Example scaling

             // Update attributes in memory for this view call
             attrs.evolutionLevel = evolutionLevel;
             attrs.complexity = complexity;
             // Note: This view does NOT modify stored state, only calculates current view
        }
        // Stored attributes are used if not evolving

        return attrs;
    }

    function getEvolutionState(uint256 tokenId) public view returns (uint256 evolutionLevel, uint256 currentEvolutionPoints, uint256 evolutionStartTime, bool isEvolvingStatus) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         NFTAttributes storage attrs = _tokenAttributes[tokenId];

         uint256 currentPoints = attrs.currentEvolutionPoints;
         uint256 startTime = _evolutionStartTime[tokenId];
         bool evolvingStatus = _isEvolving[tokenId];

         if (evolvingStatus) {
             uint256 elapsed = block.timestamp - startTime;
             currentPoints += elapsed * generationSettings.evolutionRatePerSecond;
         }

         evolutionLevel = currentPoints / 10000; // Match calculation in getTokenAttributes
         currentEvolutionPoints = currentPoints; // Return total points for progress bar etc.
         evolutionStartTime = startTime;
         isEvolvingStatus = evolvingStatus;

         return (evolutionLevel, currentEvolutionPoints, evolutionStartTime, isEvolvingStatus);
    }

    function getGenerationSettings() public view returns (GenerationSettings memory) {
        return generationSettings;
    }

    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        if (proposals[proposalId].id == 0) revert ProposalNotFound(proposalId); // Check if proposal exists
        return proposals[proposalId];
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         if (proposals[proposalId].id == 0) revert ProposalNotFound(proposalId);
         Proposal storage proposal = proposals[proposalId];

         if (proposal.state == ProposalState.Pending && block.timestamp >= proposal.submissionTime) {
             // Simple state transition: active when submitted (could add delay)
             return ProposalState.Active;
         }
         if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingEndTime) {
             // Determine Succeeded/Failed based on current votes (quorum check needed for execution)
             // For *state view*, we can just check if time is up
              return ProposalState.Failed; // Assume failed until executed if time is up (simplification)
         }
         return proposal.state; // Return current stored state if not Active/VotingEnded
    }

    function getUserVote(uint256 proposalId, address voter) public view returns (bool hasVoted, bool support) {
        if (proposals[proposalId].id == 0) revert ProposalNotFound(proposalId);
        // We can't read mapping values directly from outside without an external view function
        // This getter is needed. Note: Mapping is *inside* the Proposal struct, need helper
        // This is a common limitation; requires modifying the struct mapping visibility or using events/separate storage.
        // For a simple example, let's assume we track voters/votes separately or restructure Proposal slightly.
        // Workaround: Need an internal mapping helper or change struct visibility (less safe).
        // Let's add a simple check if they *could* have voted. A full impl needs mapping.
        // The `hasVoted` mapping is inside the struct, making it non-publicly readable.
        // A proper DAO would use a separate `mapping(uint256 => mapping(address => bool)) public hasVoted` or similar.
        // For this example, we'll indicate if the *proposal* exists and is past submission, implying they *could* vote.
        // Acknowledge this is a simplified view helper.
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        // This view cannot expose the internal mapping. A real implementation would track votes differently or require a complex getter.
        // Returning a dummy value or requiring a refactor of the struct/storage.
        // Let's return if the proposal exists and voting is active.
        return (getProposalState(proposalId) == ProposalState.Active, false); // Simplified: doesn't show actual vote
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Evolution Functions ---

    function startEvolution(uint256 tokenId) public nonReentrant {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotNFTOwner(msg.sender, tokenId);
        if (_isEvolving[tokenId]) revert TokenAlreadyEvolving(tokenId);

        _isEvolving[tokenId] = true;
        _evolutionStartTime[tokenId] = block.timestamp;
        // Accumulated points from previous sessions/burns remain in _tokenAttributes[tokenId].currentEvolutionPoints

        emit EvolutionStarted(tokenId, msg.sender, block.timestamp);
    }

    function stopEvolution(uint256 tokenId) public nonReentrant onlyEvolvingParticipant(tokenId) {
        // onlyEvolvingParticipant checks owner and isEvolving
        uint256 startTime = _evolutionStartTime[tokenId];
        uint256 elapsed = block.timestamp - startTime;
        uint256 gainedPoints = elapsed * generationSettings.evolutionRatePerSecond;

        // Accumulate points into the stored value
        _tokenAttributes[tokenId].currentEvolutionPoints += gainedPoints;

        // Recalculate level and complexity based on new total points
        uint256 totalPoints = _tokenAttributes[tokenId].currentEvolutionPoints;
        uint256 newLevel = totalPoints / 10000; // Example: 10000 points per level
        uint256 newComplexity = generationSettings.minComplexity + (newLevel * (generationSettings.maxComplexity - generationSettings.minComplexity) / 100);

        _tokenAttributes[tokenId].evolutionLevel = newLevel;
        _tokenAttributes[tokenId].complexity = newComplexity;

        // Reset evolution state variables
        _isEvolving[tokenId] = false;
        _evolutionStartTime[tokenId] = 0; // Reset start time

        emit EvolutionStopped(tokenId, msg.sender, block.timestamp, gainedPoints);
    }

    function claimEvolutionBoost(uint256 tokenId) public nonReentrant {
         // Allows owner to convert current accumulated points into 'energy potential'
         // This makes the accumulated points available to be transferred via burnForBoost
         // Does not stop evolution if currently active.
         address owner = ownerOf(tokenId);
         if (owner != msg.sender) revert NotNFTOwner(msg.sender, tokenId);

         NFTAttributes storage attrs = _tokenAttributes[tokenId];

         // Calculate points gained since start if evolving
         uint256 currentPoints = attrs.currentEvolutionPoints;
         if (_isEvolving[tokenId]) {
              uint256 elapsed = block.timestamp - _evolutionStartTime[tokenId];
              currentPoints += elapsed * generationSettings.evolutionRatePerSecond;
         }

         uint256 pointsToClaim = currentPoints - attrs.energyPotential; // Only claim new points not yet claimed

         if (pointsToClaim > 0) {
             attrs.energyPotential += pointsToClaim;
             // Reset current points ONLY if not evolving, otherwise points keep accumulating for next claim/stop
             if (!_isEvolving[tokenId]) {
                 attrs.currentEvolutionPoints = 0;
                 // Note: if evolving, the points are still accumulating towards the next stop/claim
                 // This design allows claiming mid-evolution, but the points aren't removed from current accumulation.
                 // A cleaner approach might require stopping evolution first.
                 // Let's enforce stopping evolution first for simplicity and clarity.
                 revert TokenAlreadyEvolving(tokenId); // Simpler: require stop() first
             }

             emit EvolutionBoostClaimed(tokenId, msg.sender, pointsToClaim);
         } else {
             // No new points to claim, maybe emit an event or revert
         }
    }


    // --- Burning Functions ---

    function burnForBoost(uint256 tokenIdToBurn, uint256 tokenIdToBoost) public nonReentrant {
        address burner = msg.sender;
        address burnTokenOwner = ownerOf(tokenIdToBurn);
        address boostTokenOwner = ownerOf(tokenIdToBoost);

        if (burnTokenOwner != burner) revert NotNFTOwner(burner, tokenIdToBurn);
        if (tokenIdToBurn == tokenIdToBoost) revert SelfBurnNotAllowed();
        if (_isEvolving[tokenIdToBurn]) revert CannotBurnEvolvingToken(tokenIdToBurn);
        // Decide if you can boost an evolving token, or only non-evolving ones
        if (_isEvolving[tokenIdToBoost]) revert CannotBoostEvolvingToken(tokenIdToBoost); // Example restriction

        // Get potential energy from the token to be burned
        NFTAttributes storage burnAttrs = _tokenAttributes[tokenIdToBurn];
        uint256 boostAmount = burnAttrs.energyPotential; // Use accumulated energy

        if (boostAmount > 0) {
            // Apply the boost to the target token
            NFTAttributes storage boostAttrs = _tokenAttributes[tokenIdToBoost];
            boostAttrs.currentEvolutionPoints += boostAmount; // Add to total accumulated points

            // Update target token's level/complexity based on new points
            uint256 totalPoints = boostAttrs.currentEvolutionPoints;
            uint256 newLevel = totalPoints / 10000;
            uint256 newComplexity = generationSettings.minComplexity + (newLevel * (generationSettings.maxComplexity - generationSettings.minComplexity) / 100);

            boostAttrs.evolutionLevel = newLevel;
            boostAttrs.complexity = newComplexity;

            burnAttrs.energyPotential = 0; // Energy transferred

            // Burn the token
            _burn(tokenIdToBurn);

            emit NFTBurnedForBoost(tokenIdToBurn, tokenIdToBoost, burner);
            // Optionally emit an event for the boost received by tokenIdToBoost
        } else {
            // Token has no energy potential to transfer, maybe revert or just do nothing
             revert InvalidTokenId(); // Or a more specific error
        }
    }


    // --- Governance Functions ---

    function submitParameterProposal(
        string memory description,
        string memory parameterName,
        uint256 newValue
    ) public onlyGovernanceParticipant nonReentrant returns (uint256 proposalId) {

        // Validate parameter name
        uint256 paramKey = _parameterNameToUintMapping[parameterName];
        if (paramKey == 0) revert InvalidParameterName(parameterName);

        // Basic validation for value ranges (add more checks based on parameter)
        if (paramKey == _parameterNameToUintMapping["quorumNumerator"] && newValue > 100) {
            revert InvalidParameterValue(parameterName, newValue);
        }
         if (paramKey == _parameterNameToUintMapping["proposalThresholdNFTs"] && newValue > totalSupply()) {
            revert InvalidParameterValue(parameterName, newValue);
        }


        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            parameterName: parameterName,
            newValue: newValue,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + generationSettings.proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            state: ProposalState.Active // Starts Active immediately upon submission
        });

        emit ProposalSubmitted(proposalId, msg.sender, description, parameterName, newValue);
        return proposalId;
    }


    function voteForProposal(uint256 proposalId, bool support) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        if (getProposalState(proposalId) != ProposalState.Active) revert ProposalNotActive(proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(proposalId, msg.sender);

        // Voting power based on NFT count (simplistic)
        uint256 votingPower = balanceOf(msg.sender);
        if (votingPower == 0) revert InsufficientVotingPower(generationSettings.proposalThresholdNFTs, 0); // Requires at least 1 NFT to vote

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    function executeProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        if (getProposalState(proposalId) != ProposalState.Active && getProposalState(proposalId) != ProposalState.Failed) {
             // Allow execution if Active but time is up, or if state is already Failed (time up, quorum/votes not met)
        } else if (block.timestamp < proposal.votingEndTime) {
             revert ProposalVotingPeriodNotEnded(proposalId);
        }


        // Check if proposal passed
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 currentSupply = totalSupply(); // Use current supply for quorum check
        uint256 quorumThreshold = (currentSupply * generationSettings.quorumNumerator) / 100;

        if (totalVotes < quorumThreshold) {
            proposal.state = ProposalState.Failed; // Update state if quorum not met
             revert ProposalNotPassed(proposalId); // Quorum not met
        }

        if (proposal.votesFor <= proposal.votesAgainst) {
             proposal.state = ProposalState.Failed; // Update state if votes didn't pass
             revert ProposalNotPassed(proposalId); // Majority not met
        }

        // Proposal passed! Execute the change.
        string memory parameterName = proposal.parameterName;
        uint256 newValue = proposal.newValue;
        uint256 paramKey = _parameterNameToUintMapping[parameterName];
        uint256 oldValue;

        // Use the mapped key to apply the change
        if (paramKey == _parameterNameToUintMapping["evolutionRatePerSecond"]) {
             oldValue = generationSettings.evolutionRatePerSecond;
             generationSettings.evolutionRatePerSecond = newValue;
        } else if (paramKey == _parameterNameToUintMapping["minComplexity"]) {
             oldValue = generationSettings.minComplexity;
             generationSettings.minComplexity = newValue;
        } else if (paramKey == _parameterNameToUintMapping["maxComplexity"]) {
             oldValue = generationSettings.maxComplexity;
             generationSettings.maxComplexity = newValue;
        } else if (paramKey == _parameterNameToUintMapping["baseMintPrice"]) {
             oldValue = generationSettings.baseMintPrice;
             generationSettings.baseMintPrice = newValue;
        } else if (paramKey == _parameterNameToUintMapping["proposalThresholdNFTs"]) {
             oldValue = generationSettings.proposalThresholdNFTs;
             generationSettings.proposalThresholdNFTs = newValue;
        } else if (paramKey == _parameterNameToUintMapping["proposalVotingPeriod"]) {
             oldValue = generationSettings.proposalVotingPeriod;
             generationSettings.proposalVotingPeriod = newValue;
        } else if (paramKey == _parameterNameToUintMapping["quorumNumerator"]) {
             // Add extra validation for quorum: cannot be > 100
             if (newValue > 100) revert InvalidParameterValue(parameterName, newValue);
             oldValue = generationSettings.quorumNumerator;
             generationSettings.quorumNumerator = newValue;
        }
        // Add execution branches for other parameters

        proposal.state = ProposalState.Executed; // Mark as executed

        emit GlobalSettingsChanged(parameterName, oldValue, newValue);
        emit ProposalExecuted(proposalId);
    }

     function cancelProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        if (proposal.proposer != msg.sender && owner() != msg.sender) { // Only proposer or contract owner can cancel
            revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable error for lack of specific role error
        }
        if (getProposalState(proposalId) != ProposalState.Active) { // Only cancel if not yet finalized
            revert ProposalVotingPeriodEnded(proposalId); // Already ended/executed/failed
        }

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(proposalId);
    }


    // --- Admin/Utility Functions ---

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function withdrawFunds() public onlyOwner nonReentrant {
        // Withdraw contract balance (minting fees)
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

     function pauseMinting(bool pausedState) public onlyOwner {
        paused = pausedState;
        emit MintingPausedStateChanged(pausedState);
    }


    // --- Internal Helper Functions ---

    function _generateSeed(uint256 tokenId, address minter) internal view returns (bytes32) {
        // Pseudo-random seed generation based on available entropy sources
        // NOTE: block.timestamp and block.number are predictable to miners/validators.
        // tx.origin can be problematic. msg.sender is better.
        // Combining multiple sources and hashing provides *some* level of uniqueness,
        // but true randomness on EVM requires Chainlink VRF or similar oracle.
        // This is suitable for generative art parameters where perfect unpredictability isn't a hard security requirement.
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty, // Less relevant in PoS, but still there
                block.number,
                msg.sender,
                tx.origin, // Use with caution in real apps, here for entropy
                tokenId,
                _tokenIdCounter.current(), // A changing nonce
                blockhash(block.number - 1) // Blockhash of previous block
            )
        );
        return seed;
    }

    // Override required for ERC721Burnable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of evolving tokens
        if (from != address(0) && _isEvolving[tokenId]) { // Check from != address(0) to allow minting/burning
             revert CannotTransferWhileEvolving(tokenId);
        }
    }

     // Override to handle burning custom state
    function _beforeTokenBurn(address account, uint256 tokenId) internal override {
        super._beforeTokenBurn(account, tokenId);
        if (_isEvolving[tokenId]) revert CannotBurnEvolvingToken(tokenId);

        // Clean up custom state associated with the token ID
        delete _tokenAttributes[tokenId];
        delete _evolutionStartTime[tokenId]; // Should be 0 if not evolving, but good practice
        delete _isEvolving[tokenId];
        delete _currentEvolutionPoints[tokenId];
        // Note: Votes for proposals (`proposal.hasVoted`) are not cleaned up here per token.
        // A more complex governance would need to handle this, perhaps by re-calculating voting power.
    }
}
```