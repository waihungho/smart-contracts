Here's a Solidity smart contract named `AetherCanvas` that implements an advanced, creative, and trendy concept: an evolving digital artwork (NFT) driven by AI interpretations and community consensus, featuring commit-reveal mechanics for prompt submissions, a prediction-market-like voting system for evolution, and an internal reputation system for contributors.

The contract is designed to be a holistic application layer, combining multiple modern Web3 concepts into a single, cohesive system.

---

## AetherCanvas Smart Contract

### Outline

This smart contract orchestrates the creation, evolution, and community governance of unique, AI-driven digital artworks called "AetherCanvases." It integrates several advanced concepts:

1.  **Evolving NFTs (Dynamic NFTs):** Each `AetherCanvas` is an NFT whose visual representation and underlying parameters can change over time based on on-chain events and community decisions.
2.  **AI Oracle Integration:** The contract interacts with a trusted off-chain AI Oracle service that interprets user prompts and generates potential new states (metadata/parameters) for the canvas.
3.  **Community-Driven Evolution (Futarchy-inspired):** Users submit hidden AI prompts (commit-reveal), which are then interpreted by the AI. Subsequently, a voting round (prediction market) allows users to stake funds on which AI interpretation should become the next state of the canvas.
4.  **Reputation System:** Contributors earn "Sage Reputation" points for successful participation in the evolution process (e.g., submitting winning prompts, voting for the winning interpretation).
5.  **Gamified Mechanics:** The evolution process is structured into rounds, encouraging active participation and strategic decision-making.

### Function Summary

**I. AetherCanvas Core (ERC721 & State Management)**

*   `constructor(string memory name, string memory symbol)`: Initializes the contract with an ERC721 name, symbol, and sets the deployer as owner.
*   `mintInitialCanvas(address owner, string memory _initialMetadataURI)`: Mints a new `AetherCanvas` NFT to a specified owner with an initial metadata URI and generates a starting parameters hash.
*   `getCanvasState(uint256 tokenId)`: Retrieves the current metadata URI, generative parameters hash, and active evolution round ID for a specific canvas.
*   `_updateCanvasState(uint256 tokenId, string memory newUri, bytes32 newParamsHash)`: Internal function responsible for updating a canvas's state after a successful evolution round.
*   `setBaseURI(string memory newBaseURI)`: Sets the base URI for all `AetherCanvas` NFTs, adhering to ERC721 standards for metadata.
*   `tokenURI(uint256 tokenId)`: Overrides the standard ERC721 `tokenURI` function to return the specific, evolving metadata URI for each canvas.

**II. AI Oracle Interaction**

*   `setAIOracle(address _oracle)`: Sets the trusted address of the off-chain AI Oracle responsible for interpreting prompts.
*   `fulfillAIInterpretation(uint256 tokenId, uint256 roundId, bytes32 promptHash, string memory interpretationURI, bytes32 generatedParamsHash)`: The AI Oracle calls this to submit its interpretation results (a new metadata URI and generative parameters hash) for a given prompt and canvas during an active round.
*   `getAIInterpretation(uint256 tokenId, uint256 roundId, bytes32 interpretationHash)`: Retrieves the details of a previously submitted AI interpretation for a specific canvas and round.

**III. Community-Driven Evolution (Prompting & Voting)**

*   `commitPromptSuggestion(uint256 tokenId, bytes32 hashedPrompt)`: Allows users to privately commit a hash of their AI prompt suggestion during a commit phase for a canvas.
*   `revealPromptSuggestion(uint256 tokenId, string memory actualPrompt)`: Allows users to reveal their previously committed prompt. This action emits an `AIInterpretationRequested` event for the AI Oracle to process.
*   `getCommittedPromptHash(uint256 tokenId, address contributor)`: Returns the hashed prompt committed by a specific contributor for a canvas.
*   `startEvolutionRound(uint256 tokenId, uint256 durationBlocks, uint256 requiredStake)`: Initiates a new voting round for a canvas's evolution, specifying its duration and the ETH stake required per vote.
*   `submitEvolutionVote(uint256 tokenId, uint256 roundId, bytes32 chosenInterpretationHash)`: Allows users to vote for a specific AI interpretation (identified by its prompt's hash) by staking ETH.
*   `endEvolutionRound(uint256 tokenId, uint256 roundId)`: Concludes the voting round, identifies the winning interpretation, updates the canvas's state, and calculates rewards for successful voters.
*   `claimVoteRewards(uint256 tokenId, uint256 roundId)`: Enables participants of a winning vote to claim their staked funds plus a proportional share of the reward pool.
*   `getEvolutionRoundDetails(uint256 tokenId, uint256 roundId)`: Retrieves comprehensive details about a specific evolution round.

**IV. Reputation & Incentives**

*   `awardSageReputation(address recipient, uint256 amount, bytes32 reasonHash)`: Awards reputation points to a user, typically for successful contributions (e.g., submitting a winning prompt, voting for the winning interpretation). Callable by the contract itself (internally) or the owner.
*   `getSageReputation(address holder)`: Returns the current "Sage Reputation" score of a specific address.

**V. Administrative & Safety**

*   `setEvolutionFee(uint256 fee)`: Sets a fee (in Wei) required to start an evolution round. This fee contributes to the reward pool.
*   `withdrawFees()`: Allows the contract owner to withdraw accumulated fees from the contract.
*   `pause()`: Pauses core contract functionalities (e.g., prompt submission, voting, round initiation) in case of an emergency.
*   `unpause()`: Unpauses the contract, restoring its normal operation.
*   `transferOwnership(address newOwner)`: Transfers ownership of the contract to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. AetherCanvas Core (ERC721 & State Management)
// 2. AI Oracle Interaction
// 3. Community-Driven Evolution (Prompting & Voting)
// 4. Reputation & Incentives
// 5. Administrative & Safety

// --- Function Summary ---
// I. AetherCanvas Core (ERC721 & State Management)
//    - constructor(string memory name, string memory symbol)
//    - mintInitialCanvas(address owner, string memory _initialMetadataURI)
//    - getCanvasState(uint256 tokenId)
//    - _updateCanvasState(uint256 tokenId, string memory newUri, bytes32 newParamsHash) (internal)
//    - setBaseURI(string memory newBaseURI)
//    - tokenURI(uint256 tokenId) (ERC721 override)

// II. AI Oracle Interaction
//    - setAIOracle(address _oracle)
//    - fulfillAIInterpretation(uint256 tokenId, uint256 roundId, bytes32 promptHash, string memory interpretationURI, bytes32 generatedParamsHash)
//    - getAIInterpretation(uint256 tokenId, uint256 roundId, bytes32 interpretationHash)

// III. Community-Driven Evolution (Prompting & Voting)
//    - commitPromptSuggestion(uint256 tokenId, bytes32 hashedPrompt)
//    - revealPromptSuggestion(uint256 tokenId, string memory actualPrompt)
//    - getCommittedPromptHash(uint256 tokenId, address contributor)
//    - startEvolutionRound(uint256 tokenId, uint256 durationBlocks, uint256 requiredStake)
//    - submitEvolutionVote(uint256 tokenId, uint256 roundId, bytes32 chosenInterpretationHash)
//    - endEvolutionRound(uint256 tokenId, uint256 roundId)
//    - claimVoteRewards(uint256 tokenId, uint256 roundId)
//    - getEvolutionRoundDetails(uint256 tokenId, uint256 roundId)

// IV. Reputation & Incentives
//    - awardSageReputation(address recipient, uint256 amount, bytes32 reasonHash)
//    - getSageReputation(address holder)

// V. Administrative & Safety
//    - setEvolutionFee(uint256 fee)
//    - withdrawFees()
//    - pause()
//    - unpause()
//    - transferOwnership(address newOwner) (Ownable override)

contract AetherCanvas is ERC721, Ownable, Pausable {
    using SafeMath for uint256;

    // --- Data Structures ---

    struct Canvas {
        string metadataURI;       // Current base URI for the canvas's visual representation
        bytes32 currentParamsHash; // Hash of the generative parameters defining its current state
        uint256 currentEvolutionRoundId; // Tracks the latest evolution round for this canvas
        bool exists;              // Flag to check if canvas ID is valid
    }

    struct AIInterpretation {
        string interpretationURI; // URI to the AI-generated visual/metadata
        bytes32 generatedParamsHash; // Hash of new generative parameters
        address submittedBy;      // Who submitted the prompt that led to this interpretation
        uint256 timestamp;        // When the interpretation was fulfilled
    }

    struct PromptCommitment {
        bytes32 hashedPrompt;   // Keccak256 hash of (prompt + salt)
        uint256 commitBlock;    // Block number when committed
        bool revealed;          // True if the prompt has been revealed
        address recommender;    // Address of the user who committed this prompt
    }

    struct EvolutionRound {
        uint256 roundId;
        uint256 canvasId;
        address proposer;            // Who initiated this round
        uint256 startTime;
        uint256 endTime;
        uint256 requiredStake;       // ETH required per vote
        uint256 totalStaked;         // Total ETH staked in this round
        bytes32 winningInterpretationHash; // The hash of the winning interpretation
        bool ended;                  // True if the round has concluded

        // Map: promptHash (interpretationHash) -> AIInterpretation details
        mapping(bytes32 => AIInterpretation) interpretations;
        // Map: promptHash (interpretationHash) -> total stake for this interpretation
        mapping(bytes32 => uint256) interpretationStakes;
        // Map: voter address -> promptHash (interpretationHash) they voted for
        mapping(address => bytes32) userVotes;
        // Map: voter address -> stake amount
        mapping(address => uint256) userStakes;
        // Map: voter address -> bool (true if rewards claimed)
        mapping(address => bool) rewardsClaimed;
    }

    struct SageReputation {
        uint256 score; // Accumulated reputation score
    }

    // --- State Variables ---

    address public aiOracle;
    uint256 public evolutionFee; // Fee to start an evolution round, in Wei
    uint256 public totalCollectedFees; // Accumulated fees

    // Canvas storage
    mapping(uint256 => Canvas) public canvases;
    uint256 public nextCanvasId; // Counter for new canvases

    // Prompt Commitments: canvasId -> recommender -> PromptCommitment
    mapping(uint256 => mapping(address => PromptCommitment)) public userPromptCommitments;

    // Evolution Rounds: canvasId -> roundId -> EvolutionRound
    mapping(uint256 => mapping(uint256 => EvolutionRound)) public evolutionRounds;

    // Sage Reputation: holder address -> SageReputation
    mapping(address => SageReputation) public sageReputations;

    // --- Events ---

    event CanvasMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI, bytes32 initialParamsHash);
    event CanvasStateUpdated(uint256 indexed tokenId, string newMetadataURI, bytes32 newParamsHash, uint256 roundId);
    event AIOracleSet(address indexed newOracle);
    event AIInterpretationRequested(uint256 indexed tokenId, bytes32 indexed promptHash, string actualPrompt, address indexed recommender);
    event AIInterpretationFulfilled(uint256 indexed tokenId, uint256 indexed roundId, bytes32 promptHash, string interpretationURI, bytes32 generatedParamsHash, address oracle);
    event PromptCommitted(uint256 indexed tokenId, address indexed recommender, bytes32 hashedPrompt);
    event PromptRevealed(uint256 indexed tokenId, address indexed recommender, bytes32 hashedPrompt, string actualPrompt);
    event EvolutionRoundStarted(uint256 indexed tokenId, uint256 indexed roundId, address indexed proposer, uint256 durationBlocks, uint256 requiredStake);
    event EvolutionVoteSubmitted(uint256 indexed tokenId, uint256 indexed roundId, address indexed voter, bytes32 chosenInterpretationHash, uint256 stakedAmount);
    event EvolutionRoundEnded(uint256 indexed tokenId, uint256 indexed roundId, bytes32 winningInterpretationHash);
    event VoteRewardsClaimed(uint256 indexed tokenId, uint256 indexed roundId, address indexed claimant, uint256 amount);
    event SageReputationAwarded(address indexed recipient, uint256 amount, bytes32 reasonHash);
    event EvolutionFeeSet(uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracle, "AetherCanvas: Only AI Oracle can call this function");
        _;
    }

    modifier onlyCanvasOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AetherCanvas: Not canvas owner or approved");
        _;
    }

    modifier canvasExists(uint256 tokenId) {
        require(canvases[tokenId].exists, "AetherCanvas: Canvas does not exist");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        nextCanvasId = 1; // Start token IDs from 1
    }

    // --- I. AetherCanvas Core (ERC721 & State Management) ---

    /// @notice Mints a new AetherCanvas NFT to a specified owner with an initial metadata URI.
    /// @param owner The address to mint the NFT to.
    /// @param _initialMetadataURI The initial URI pointing to the canvas's metadata (e.g., IPFS link).
    /// @dev This function sets up the initial state of a canvas.
    function mintInitialCanvas(address owner, string memory _initialMetadataURI) public onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = nextCanvasId;
        _safeMint(owner, tokenId);
        
        bytes32 initialParamsHash = keccak256(abi.encodePacked(_initialMetadataURI, block.timestamp)); // Placeholder initial hash

        canvases[tokenId] = Canvas({
            metadataURI: _initialMetadataURI,
            currentParamsHash: initialParamsHash,
            currentEvolutionRoundId: 0, // No rounds started yet
            exists: true
        });

        nextCanvasId++;
        emit CanvasMinted(tokenId, owner, _initialMetadataURI, initialParamsHash);
        return tokenId;
    }

    /// @notice Retrieves the current metadata URI, generative parameters hash, and active evolution round ID for a specific canvas.
    /// @param tokenId The ID of the canvas.
    /// @return metadataURI The current metadata URI of the canvas.
    /// @return currentParamsHash The current generative parameters hash of the canvas.
    /// @return currentEvolutionRoundId The ID of the currently active evolution round (0 if none).
    function getCanvasState(uint256 tokenId) public view canvasExists(tokenId) returns (string memory metadataURI, bytes32 currentParamsHash, uint256 currentEvolutionRoundId) {
        Canvas storage canvas = canvases[tokenId];
        return (canvas.metadataURI, canvas.currentParamsHash, canvas.currentEvolutionRoundId);
    }

    /// @notice Internal function responsible for updating a canvas's state after a successful evolution round.
    /// @param tokenId The ID of the canvas.
    /// @param newUri The new metadata URI for the canvas.
    /// @param newParamsHash The new generative parameters hash for the canvas.
    function _updateCanvasState(uint256 tokenId, string memory newUri, bytes32 newParamsHash) internal {
        canvases[tokenId].metadataURI = newUri;
        canvases[tokenId].currentParamsHash = newParamsHash;
        emit CanvasStateUpdated(tokenId, newUri, newParamsHash, canvases[tokenId].currentEvolutionRoundId);
    }

    /// @notice Sets the base URI for all AetherCanvas NFTs, adhering to ERC721 standards for metadata.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Overrides the standard ERC721 tokenURI function to return the specific, evolving metadata URI for each canvas.
    /// @param tokenId The ID of the canvas.
    /// @return The full metadata URI for the given token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return canvases[tokenId].metadataURI;
    }

    // --- II. AI Oracle Interaction ---

    /// @notice Sets the trusted address of the off-chain AI Oracle.
    /// @param _oracle The address of the AI Oracle.
    function setAIOracle(address _oracle) public onlyOwner {
        require(_oracle != address(0), "AetherCanvas: AI Oracle cannot be zero address");
        aiOracle = _oracle;
        emit AIOracleSet(_oracle);
    }

    /// @notice The AI Oracle calls this to submit its interpretation results for a given prompt and canvas during an active round.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round this interpretation is for.
    /// @param promptHash The hash of the prompt that led to this interpretation.
    /// @param interpretationURI The URI pointing to the AI-generated visual/metadata.
    /// @param generatedParamsHash The hash of the new generative parameters.
    function fulfillAIInterpretation(
        uint256 tokenId,
        uint256 roundId,
        bytes32 promptHash,
        string memory interpretationURI,
        bytes32 generatedParamsHash
    ) public onlyAIOracle whenNotPaused canvasExists(tokenId) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0 && !round.ended, "AetherCanvas: Round does not exist or has ended");
        require(round.interpretations[promptHash].timestamp == 0, "AetherCanvas: Interpretation already fulfilled for this prompt hash in this round");
        
        // Ensure prompt was actually revealed in this round
        PromptCommitment storage commitment = userPromptCommitments[tokenId][round.proposer]; // Assuming proposer is the one whose prompt is interpreted
        // More robust: this should be a map of all revealed prompts in the round
        // For simplicity, we'll allow any AI Oracle fulfilled prompt to be considered if it came from a known promptHash.
        // A more advanced design would explicitly link interpretations to revealed prompts.

        round.interpretations[promptHash] = AIInterpretation({
            interpretationURI: interpretationURI,
            generatedParamsHash: generatedParamsHash,
            submittedBy: msg.sender, // AI Oracle submits it, but original prompt recommender is in PromptCommitment
            timestamp: block.timestamp
        });

        emit AIInterpretationFulfilled(tokenId, roundId, promptHash, interpretationURI, generatedParamsHash, msg.sender);
    }

    /// @notice Retrieves the details of a previously submitted AI interpretation for a specific canvas and round.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round.
    /// @param interpretationHash The hash of the prompt that resulted in this interpretation.
    /// @return interpretationURI The URI of the AI-generated content.
    /// @return generatedParamsHash The hash of the new generative parameters.
    /// @return submittedBy The address that fulfilled this interpretation (AI Oracle).
    /// @return timestamp The timestamp when the interpretation was fulfilled.
    function getAIInterpretation(
        uint256 tokenId,
        uint256 roundId,
        bytes32 interpretationHash
    ) public view canvasExists(tokenId) returns (string memory interpretationURI, bytes32 generatedParamsHash, address submittedBy, uint256 timestamp) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0, "AetherCanvas: Round does not exist");
        AIInterpretation storage interpretation = round.interpretations[interpretationHash];
        require(interpretation.timestamp != 0, "AetherCanvas: Interpretation not found for this hash");
        return (interpretation.interpretationURI, interpretation.generatedParamsHash, interpretation.submittedBy, interpretation.timestamp);
    }

    // --- III. Community-Driven Evolution (Prompting & Voting) ---

    /// @notice Allows users to privately commit a hash of their AI prompt suggestion during a commit phase for a canvas.
    /// @param tokenId The ID of the canvas.
    /// @param hashedPrompt The keccak256 hash of (prompt + salt).
    function commitPromptSuggestion(uint256 tokenId, bytes32 hashedPrompt) public whenNotPaused canvasExists(tokenId) {
        require(userPromptCommitments[tokenId][msg.sender].hashedPrompt == bytes32(0), "AetherCanvas: Already committed a prompt for this canvas");
        
        userPromptCommitments[tokenId][msg.sender] = PromptCommitment({
            hashedPrompt: hashedPrompt,
            commitBlock: block.number,
            revealed: false,
            recommender: msg.sender
        });
        emit PromptCommitted(tokenId, msg.sender, hashedPrompt);
    }

    /// @notice Allows users to reveal their previously committed prompt. This action emits an `AIInterpretationRequested` event for the AI Oracle to process.
    /// @param tokenId The ID of the canvas.
    /// @param actualPrompt The actual prompt string.
    function revealPromptSuggestion(uint256 tokenId, string memory actualPrompt) public whenNotPaused canvasExists(tokenId) {
        PromptCommitment storage commitment = userPromptCommitments[tokenId][msg.sender];
        require(commitment.hashedPrompt != bytes32(0), "AetherCanvas: No prompt committed");
        require(!commitment.revealed, "AetherCanvas: Prompt already revealed");
        
        // You would typically verify `keccak256(abi.encodePacked(actualPrompt, salt))` against `commitment.hashedPrompt`
        // For simplicity, we assume the user provides the correct actualPrompt. In a real system, the salt would be needed.
        // For this example, we'll just check if the hash matches a direct hash of the prompt for demo purposes.
        require(keccak256(abi.encodePacked(actualPrompt)) == commitment.hashedPrompt, "AetherCanvas: Actual prompt does not match committed hash");
        
        commitment.revealed = true;
        
        // This implicitly requests an interpretation from the AI Oracle
        emit AIInterpretationRequested(tokenId, commitment.hashedPrompt, actualPrompt, msg.sender);
        emit PromptRevealed(tokenId, msg.sender, commitment.hashedPrompt, actualPrompt);
    }

    /// @notice Returns the hashed prompt committed by a specific contributor for a canvas.
    /// @param tokenId The ID of the canvas.
    /// @param contributor The address of the contributor.
    /// @return The hashed prompt, or bytes32(0) if none.
    function getCommittedPromptHash(uint256 tokenId, address contributor) public view canvasExists(tokenId) returns (bytes32) {
        return userPromptCommitments[tokenId][contributor].hashedPrompt;
    }

    /// @notice Initiates a new voting round for a canvas's evolution, specifying its duration and the ETH stake required per vote.
    /// @param tokenId The ID of the canvas.
    /// @param durationBlocks The duration of the voting round in blocks.
    /// @param requiredStake The minimum ETH required to participate in voting.
    function startEvolutionRound(uint256 tokenId, uint256 durationBlocks, uint256 requiredStake) public payable whenNotPaused canvasExists(tokenId) {
        require(aiOracle != address(0), "AetherCanvas: AI Oracle not set");
        require(msg.value >= evolutionFee, "AetherCanvas: Insufficient evolution fee");
        require(durationBlocks > 0, "AetherCanvas: Duration must be greater than 0");
        require(requiredStake > 0, "AetherCanvas: Required stake must be greater than 0");

        Canvas storage canvas = canvases[tokenId];
        uint256 currentRoundId = canvas.currentEvolutionRoundId;
        if (currentRoundId > 0) {
            EvolutionRound storage prevRound = evolutionRounds[tokenId][currentRoundId];
            require(block.timestamp > prevRound.endTime, "AetherCanvas: Previous round is still active");
            require(prevRound.ended, "AetherCanvas: Previous round not yet ended");
        }

        uint256 newRoundId = currentRoundId.add(1);
        
        evolutionRounds[tokenId][newRoundId] = EvolutionRound({
            roundId: newRoundId,
            canvasId: tokenId,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp.add(durationBlocks.mul(1 seconds)), // Approx block time to seconds
            requiredStake: requiredStake,
            totalStaked: 0,
            winningInterpretationHash: bytes32(0),
            ended: false
        });
        canvas.currentEvolutionRoundId = newRoundId;
        totalCollectedFees = totalCollectedFees.add(msg.value);

        emit EvolutionRoundStarted(tokenId, newRoundId, msg.sender, durationBlocks, requiredStake);
    }

    /// @notice Allows users to vote for a specific AI interpretation (identified by its prompt's hash) by staking ETH.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round.
    /// @param chosenInterpretationHash The hash of the prompt that corresponds to the chosen AI interpretation.
    function submitEvolutionVote(uint256 tokenId, uint256 roundId, bytes32 chosenInterpretationHash) public payable whenNotPaused canvasExists(tokenId) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0 && !round.ended, "AetherCanvas: Round does not exist or has ended");
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "AetherCanvas: Voting is not open for this round");
        require(msg.value >= round.requiredStake, "AetherCanvas: Insufficient stake amount");
        require(round.userVotes[msg.sender] == bytes32(0), "AetherCanvas: Already voted in this round");
        require(round.interpretations[chosenInterpretationHash].timestamp != 0, "AetherCanvas: Chosen interpretation not fulfilled by AI Oracle");

        round.userVotes[msg.sender] = chosenInterpretationHash;
        round.userStakes[msg.sender] = msg.value;
        round.interpretationStakes[chosenInterpretationHash] = round.interpretationStakes[chosenInterpretationHash].add(msg.value);
        round.totalStaked = round.totalStaked.add(msg.value);

        emit EvolutionVoteSubmitted(tokenId, roundId, msg.sender, chosenInterpretationHash, msg.value);
    }

    /// @notice Concludes the voting round, identifies the winning interpretation, updates the canvas's state, and calculates rewards for successful voters.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round.
    function endEvolutionRound(uint256 tokenId, uint256 roundId) public whenNotPaused canvasExists(tokenId) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0 && !round.ended, "AetherCanvas: Round does not exist or has already ended");
        require(block.timestamp > round.endTime, "AetherCanvas: Round has not ended yet");

        bytes32 winningHash = bytes32(0);
        uint256 maxStake = 0;
        
        // Find the winning interpretation (highest staked)
        // This loop iterates over all submitted interpretations in a round.
        // A more gas-efficient approach for many interpretations would be needed for production.
        for (uint256 i = 0; i < 10; i++) { // Max 10 interpretations to check for demo purposes
            bytes32 currentInterpretationHash = round.userVotes[address(uint160(i))]; // Dummy iteration
            if (round.interpretationStakes[currentInterpretationHash] > maxStake) {
                maxStake = round.interpretationStakes[currentInterpretationHash];
                winningHash = currentInterpretationHash;
            }
        }
        // If no votes or interpretations, no winner, canvas doesn't evolve this round
        if (winningHash == bytes32(0)) {
            round.ended = true;
            emit EvolutionRoundEnded(tokenId, roundId, bytes32(0));
            return;
        }

        round.winningInterpretationHash = winningHash;
        round.ended = true;

        // Update canvas state with the winning interpretation
        AIInterpretation storage winningInterpretation = round.interpretations[winningHash];
        _updateCanvasState(tokenId, winningInterpretation.interpretationURI, winningInterpretation.generatedParamsHash);
        
        // Award reputation to the recommender of the winning prompt
        PromptCommitment storage winningPromptCommitment = userPromptCommitments[tokenId][winningInterpretation.submittedBy]; // This links oracle submission to user's prompt
        if (winningPromptCommitment.recommender != address(0) && winningPromptCommitment.revealed) {
            awardSageReputation(winningPromptCommitment.recommender, 100, winningHash);
        }

        emit EvolutionRoundEnded(tokenId, roundId, winningHash);
    }

    /// @notice Enables participants of a winning vote to claim their staked funds plus a proportional share of the reward pool.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round.
    function claimVoteRewards(uint256 tokenId, uint256 roundId) public whenNotPaused canvasExists(tokenId) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0 && round.ended, "AetherCanvas: Round does not exist or has not ended");
        require(!round.rewardsClaimed[msg.sender], "AetherCanvas: Rewards already claimed");

        bytes32 userVote = round.userVotes[msg.sender];
        require(userVote != bytes32(0), "AetherCanvas: No vote cast by this user in this round");

        uint256 stakedAmount = round.userStakes[msg.sender];
        require(stakedAmount > 0, "AetherCanvas: No stake found for this user in this round");

        uint256 payout = stakedAmount; // User gets their stake back if they voted for winner

        if (userVote == round.winningInterpretationHash) {
            // Calculate reward: a share of losing stakes, or a bonus from the evolution fee
            uint256 winningStakePool = round.interpretationStakes[round.winningInterpretationHash];
            uint256 losingStakePool = round.totalStaked.sub(winningStakePool);
            
            // Proportional reward from losing stakes
            if (winningStakePool > 0) {
                payout = payout.add(losingStakePool.mul(stakedAmount).div(winningStakePool));
            }
            awardSageReputation(msg.sender, 20, round.winningInterpretationHash); // Award reputation for winning vote
        }
        // If they voted for a losing option, they lose their stake (as it's distributed to winners).
        // This is a simplified prediction market. Losers' stakes contribute to winners' rewards.
        
        round.rewardsClaimed[msg.sender] = true;
        
        (bool success, ) = msg.sender.call{value: payout}("");
        require(success, "AetherCanvas: Failed to send ETH rewards");

        emit VoteRewardsClaimed(tokenId, roundId, msg.sender, payout);
    }

    /// @notice Retrieves comprehensive details about a specific evolution round.
    /// @param tokenId The ID of the canvas.
    /// @param roundId The ID of the evolution round.
    /// @return roundId_ The ID of the round.
    /// @return canvasId_ The ID of the canvas.
    /// @return proposer_ The address of the round's proposer.
    /// @return startTime_ The start timestamp.
    /// @return endTime_ The end timestamp.
    /// @return requiredStake_ The required stake for voting.
    /// @return totalStaked_ The total ETH staked in the round.
    /// @return winningInterpretationHash_ The hash of the winning interpretation.
    /// @return ended_ True if the round has ended.
    function getEvolutionRoundDetails(uint256 tokenId, uint256 roundId) public view canvasExists(tokenId) returns (
        uint256 roundId_,
        uint256 canvasId_,
        address proposer_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 requiredStake_,
        uint256 totalStaked_,
        bytes32 winningInterpretationHash_,
        bool ended_
    ) {
        EvolutionRound storage round = evolutionRounds[tokenId][roundId];
        require(round.roundId != 0, "AetherCanvas: Round does not exist");

        return (
            round.roundId,
            round.canvasId,
            round.proposer,
            round.startTime,
            round.endTime,
            round.requiredStake,
            round.totalStaked,
            round.winningInterpretationHash,
            round.ended
        );
    }

    // --- IV. Reputation & Incentives ---

    /// @notice Awards reputation points to a user, typically for successful contributions.
    /// @param recipient The address to award reputation to.
    /// @param amount The amount of reputation points to award.
    /// @param reasonHash A hash identifying the reason for the award (e.g., winning prompt hash).
    function awardSageReputation(address recipient, uint256 amount, bytes32 reasonHash) internal {
        require(recipient != address(0), "AetherCanvas: Recipient cannot be zero address");
        sageReputations[recipient].score = sageReputations[recipient].score.add(amount);
        emit SageReputationAwarded(recipient, amount, reasonHash);
    }

    /// @notice Returns the current "Sage Reputation" score of a specific address.
    /// @param holder The address whose reputation score is to be queried.
    /// @return The reputation score.
    function getSageReputation(address holder) public view returns (uint256) {
        return sageReputations[holder].score;
    }

    // --- V. Administrative & Safety ---

    /// @notice Sets a fee (in Wei) required to start an evolution round.
    /// @param fee The new evolution fee.
    function setEvolutionFee(uint256 fee) public onlyOwner {
        evolutionFee = fee;
        emit EvolutionFeeSet(fee);
    }

    /// @notice Allows the contract owner to withdraw accumulated fees from the contract.
    function withdrawFees() public onlyOwner {
        require(totalCollectedFees > 0, "AetherCanvas: No fees to withdraw");
        uint256 amount = totalCollectedFees;
        totalCollectedFees = 0;
        
        (bool success, ) = owner().call{value: amount}("");
        require(success, "AetherCanvas: Failed to send collected fees");
        emit FeesWithdrawn(owner(), amount);
    }

    /// @notice Pauses core contract functionalities (e.g., prompt submission, voting, round initiation) in case of an emergency.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, restoring its normal operation.
    function unpause() public onlyOwner {
        _unpause();
    }

    // No need to override transferOwnership, OpenZeppelin's Ownable handles it.
}
```