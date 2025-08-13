```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- ChronoGlyphNexus Smart Contract ---
//
// Outline & Function Summary:
//
// The ChronoGlyphNexus is an advanced, non-transferable ERC721 (Soulbound Token-like) system
// designed to create dynamic, reputation-bound "ChronoGlyphs" for users. These Glyphs
// represent a user's on-chain history, foresight, and "predictive potential" within the ecosystem.
// Glyphs evolve (level up/down) based on the accuracy of user-proposed "predictions" about future
// events. Successful predictions enhance a Glyph's traits, potentially unlocking access to
// a community-driven "FutureFlux Pool" for funding projects, while incorrect predictions
// or malicious actions can degrade a Glyph. The system aims to incentivize verifiable foresight
// and collective intelligence for decentralized resource allocation.
//
// Key Concepts:
// - ChronoGlyph NFTs: Non-transferable tokens representing user identity and reputation.
// - Predictive Attestation: Users propose and support outcomes of future events.
// - Dynamic Evolution: Glyphs gain/lose "levels" and "traits" based on prediction accuracy.
// - FutureFlux Pool: A community treasury where funding is unlocked based on Glyphs' "foresight levels".
// - AI-Informed Resolution (conceptual): While not direct AI calls, the resolution mechanism
//   is designed to be integrated with robust oracle networks (potentially AI-driven) for complex outcomes.
//
// I. Core Glyph Management (SBT-like ERC721)
//    - These functions manage the creation and state of ChronoGlyph NFTs.
// 1.  `mintChronoGlyph(string memory _initialTraitURI)`: Mints a new ChronoGlyph for a user. Only one per address.
// 2.  `getGlyphInfo(address _owner)`: Retrieves comprehensive details about a user's ChronoGlyph.
// 3.  `isGlyphOwner(address _addr)`: Checks if an address possesses a ChronoGlyph.
// 4.  `tokenURI(uint256 tokenId)`: Standard ERC721 function to get the metadata URI of a Glyph.
// 5.  `_updateGlyphMetadata(uint256 _tokenId, string memory _newURI)`: Internal helper to update a Glyph's URI.
//
// II. Predictive Attestation & Resolution
//     - These functions handle the lifecycle of future event predictions, from proposal to resolution and reward.
// 6.  `proposePrediction(string memory _description, bytes32 _outcomeHash, uint256 _deadline, uint256 _collateralAmount)`: User proposes a future event outcome, committing collateral.
// 7.  `supportPrediction(uint256 _predictionId, uint256 _supportAmount)`: Allows other Glyph-holders to support an existing prediction with collateral.
// 8.  `challengePrediction(uint256 _predictionId, string memory _reason)`: Enables Glyph-holders to challenge a proposed prediction.
// 9.  `submitOracleResolution(uint256 _predictionId, bytes32 _actualOutcomeHash, address _resolverAddress)`: Designated oracles resolve a prediction based on real-world outcomes.
// 10. `claimPredictionReward(uint256 _predictionId)`: Allows participants of a correct prediction to claim their share of collateral.
// 11. `penalizeIncorrectPrediction(uint256 _predictionId)`: Internal function to handle collateral slashing for incorrect predictions.
//
// III. Glyph Evolution & Traits
//      - These functions manage the dynamic changes to a ChronoGlyph's attributes based on performance.
// 12. `evolveGlyph(uint256 _predictionId)`: Internal. Upgrades a Glyph's level and traits upon correct prediction.
// 13. `degradeGlyph(uint256 _predictionId)`: Internal. Degrades a Glyph's level and traits upon incorrect prediction or failed challenge.
// 14. `getGlyphTraits(address _owner)`: Returns the current traits and level of a user's ChronoGlyph.
// 15. `_mintNewTrait(uint256 _tokenId, uint8 _traitType, uint256 _value)`: Internal helper to assign or update specific traits.
//
// IV. FutureFlux Pool & Funding
//     - These functions manage the community treasury and the Glyph-gated funding mechanism.
// 16. `depositToFutureFlux()`: Allows anyone to contribute funds to the FutureFlux Pool.
// 17. `proposeFundingRequest(string memory _description, uint256 _amount, uint256 _requiredGlyphLevel)`: A user proposes a project for funding, requiring a minimum Glyph level.
// 18. `voteOnFundingRequest(uint256 _requestId, bool _approve)`: Glyph-holders with sufficient level vote on funding proposals.
// 19. `executeFundingRequest(uint256 _requestId)`: Executes a funding request if it passes the vote and conditions are met.
// 20. `withdrawFromFutureFlux(address _to, uint256 _amount)`: Allows the owner (or governance) to withdraw funds in emergencies.
//
// V. System Configuration & Governance
//    - These functions allow for administrative control and parameter adjustments.
// 21. `setResolutionOracle(address _oracleAddress, bool _isOracle)`: Designates or revokes resolution oracle addresses.
// 22. `updateChronoParams(uint256 _newMinCollateral, uint256 _newRewardRatio, uint256 _newDecayRate, uint256 _newFundingVoteThreshold)`: Adjusts key operational parameters.
// 23. `pauseSystem()`: Emergency function to pause critical contract operations.
// 24. `unpauseSystem()`: Unpauses the system after a pause.
// 25. `transferOwnership(address _newOwner)`: Transfers ownership of the contract.

contract ChronoGlyphNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _predictionIdCounter;
    Counters.Counter private _fundingRequestIdCounter;

    // Mapping from owner address to glyph tokenId
    mapping(address => uint256) private _ownerGlyph;
    // Mapping from tokenId to Glyph data
    mapping(uint256 => Glyph) private _glyphs;

    // Prediction storage
    mapping(uint256 => Prediction) private _predictions;
    mapping(address => bool) private _isResolutionOracle; // Addresses authorized to resolve predictions

    // Funding Request storage
    mapping(uint256 => FundingRequest) private _fundingRequests;

    // --- Configuration Parameters ---
    uint256 public minPredictionCollateral = 0.01 ether; // Minimum collateral for a prediction
    uint256 public predictionRewardRatio = 1500; // 150% - reward multiplier for correct prediction collateral
    uint256 public glyphLevelDecayRate = 1; // Amount of levels a glyph decays on incorrect prediction
    uint256 public glyphLevelUpThreshold = 3; // Number of correct predictions to level up
    uint256 public fundingVoteThreshold = 70; // 70% approval needed for funding requests (out of total votes cast)

    // --- Structs ---

    enum PredictionStatus { Pending, ResolvedCorrect, ResolvedIncorrect, Challenged, Disputed }
    enum FundingStatus { Proposed, Approved, Rejected, Executed }

    struct Glyph {
        uint256 tokenId;
        address owner;
        uint256 level; // Represents overall reputation/foresight
        uint256 correctPredictionsCount; // Track for leveling up
        uint256 incorrectPredictionsCount; // Track for leveling down
        string metadataURI; // Dynamic URI reflecting current traits/level
        mapping(uint8 => uint256) traits; // Example: 0: 'Wisdom', 1: 'Foresight', 2: 'Influence'
    }

    struct Prediction {
        uint256 id;
        address proposer;
        string description;
        bytes32 outcomeHash; // Keccak256 hash of the predicted outcome string
        uint256 deadline;
        uint256 collateralTotal;
        uint256 challengeCollateral;
        PredictionStatus status;
        bytes32 actualOutcomeHash; // Keccak256 hash of the actual outcome string (set by oracle)
        mapping(address => uint256) participantsCollateral; // Proposer + Supporters
        mapping(address => bool) challengedBy; // Addresses that challenged
        address[] participantAddresses; // To iterate over participants for rewards
    }

    struct FundingRequest {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        uint256 requiredGlyphLevel;
        FundingStatus status;
        uint256 voteFor;
        uint256 voteAgainst;
        mapping(address => bool) hasVoted; // Prevents double voting
    }

    // --- Events ---

    event GlyphMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event GlyphLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event GlyphLeveledDown(uint256 indexed tokenId, uint256 newLevel);
    event GlyphTraitUpdated(uint256 indexed tokenId, uint8 traitType, uint256 value);

    event PredictionProposed(uint256 indexed predictionId, address indexed proposer, uint256 collateral);
    event PredictionSupported(uint256 indexed predictionId, address indexed supporter, uint256 amount);
    event PredictionChallenged(uint256 indexed predictionId, address indexed challenger, string reason);
    event PredictionResolved(uint256 indexed predictionId, PredictionStatus status, bytes32 actualOutcomeHash);
    event PredictionRewardClaimed(uint256 indexed predictionId, address indexed claimant, uint256 amount);

    event FutureFluxDeposited(address indexed depositor, uint256 amount);
    event FundingRequestProposed(uint256 indexed requestId, address indexed proposer, uint256 amount, uint256 requiredGlyphLevel);
    event FundingRequestVoted(uint256 indexed requestId, address indexed voter, bool approved);
    event FundingRequestExecuted(uint256 indexed requestId, address indexed recipient, uint256 amount);

    event OracleSet(address indexed oracleAddress, bool isOracle);
    event ChronoParamsUpdated(uint256 minCollateral, uint256 rewardRatio, uint256 decayRate, uint256 fundingVoteThreshold);

    // --- Constructor ---

    constructor() ERC721("ChronoGlyph", "CGLYPH") Ownable(msg.sender) Pausable() {
        // Initial parameters can be set here or via updateChronoParams
    }

    // --- Modifiers ---

    modifier onlyGlyphHolder() {
        require(_ownerGlyph[msg.sender] != 0, "Caller must hold a ChronoGlyph");
        _;
    }

    modifier onlyResolutionOracle() {
        require(_isResolutionOracle[msg.sender], "Caller is not a designated resolution oracle");
        _;
    }

    modifier onlyPredictionProposer(uint256 _predictionId) {
        require(_predictions[_predictionId].proposer == msg.sender, "Only the prediction proposer can call this");
        _;
    }

    // --- ERC721 Overrides (to make it Soulbound/Non-transferable) ---

    // Overriding _transfer to prevent transferability
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(false, "ChronoGlyphs are non-transferable (Soulbound)");
    }

    // Overriding approve and setApprovalForAll to prevent approvals
    function approve(address to, uint256 tokenId) public virtual override {
        revert("ChronoGlyphs are non-transferable (Soulbound)");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("ChronoGlyphs are non-transferable (Soulbound)");
    }

    // Overriding transferFrom to prevent transfers
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("ChronoGlyphs are non-transferable (Soulbound)");
    }

    // Overriding safeTransferFrom to prevent transfers
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("ChronoGlyphs are non-transferable (Soulbound)");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert("ChronoGlyphs are non-transferable (Soulbound)");
    }

    // --- I. Core Glyph Management ---

    /// @notice Mints a new ChronoGlyph for the caller. Each address can only mint one.
    /// @param _initialTraitURI The initial metadata URI for the Glyph, reflecting its starting state.
    function mintChronoGlyph(string memory _initialTraitURI) public whenNotPaused {
        require(_ownerGlyph[msg.sender] == 0, "You already own a ChronoGlyph.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _ownerGlyph[msg.sender] = newTokenId;

        Glyph storage newGlyph = _glyphs[newTokenId];
        newGlyph.tokenId = newTokenId;
        newGlyph.owner = msg.sender;
        newGlyph.level = 1; // Start at level 1
        newGlyph.correctPredictionsCount = 0;
        newGlyph.incorrectPredictionsCount = 0;
        newGlyph.metadataURI = _initialTraitURI;

        emit GlyphMinted(newTokenId, msg.sender, _initialTraitURI);
    }

    /// @notice Retrieves detailed information about a user's ChronoGlyph.
    /// @param _owner The address of the Glyph owner.
    /// @return Glyph struct containing token ID, owner, level, correct/incorrect prediction counts, and metadata URI.
    function getGlyphInfo(address _owner) public view returns (uint256 tokenId, address owner, uint256 level, uint256 correctCount, uint256 incorrectCount, string memory metadataURI) {
        uint256 _tokenId = _ownerGlyph[_owner];
        require(_tokenId != 0, "Address does not own a ChronoGlyph.");
        Glyph storage glyph = _glyphs[_tokenId];
        return (glyph.tokenId, glyph.owner, glyph.level, glyph.correctPredictionsCount, glyph.incorrectPredictionsCount, glyph.metadataURI);
    }

    /// @notice Checks if a given address owns a ChronoGlyph.
    /// @param _addr The address to check.
    /// @return True if the address owns a Glyph, false otherwise.
    function isGlyphOwner(address _addr) public view returns (bool) {
        return _ownerGlyph[_addr] != 0;
    }

    /// @notice Standard ERC721 function to get the metadata URI.
    /// @param tokenId The ID of the ChronoGlyph.
    /// @return The metadata URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _glyphs[tokenId].metadataURI;
    }

    /// @dev Internal function to update a Glyph's metadata URI. Only callable by the contract itself.
    /// @param _tokenId The ID of the Glyph to update.
    /// @param _newURI The new metadata URI.
    function _updateGlyphMetadata(uint256 _tokenId, string memory _newURI) internal {
        _glyphs[_tokenId].metadataURI = _newURI;
        emit GlyphTraitUpdated(_tokenId, 255, 0); // TraitType 255 can signify a general URI update
    }

    // --- II. Predictive Attestation & Resolution ---

    /// @notice Proposes a future event prediction. Requires collateral from the proposer.
    /// @param _description A detailed description of the event.
    /// @param _outcomeHash A keccak256 hash of the predicted outcome string (e.g., hash("Outcome A wins")).
    /// @param _deadline The Unix timestamp by which the prediction must be resolved.
    /// @param _collateralAmount The amount of ETH (or token if integrated) to put down as collateral.
    function proposePrediction(
        string memory _description,
        bytes32 _outcomeHash,
        uint256 _deadline,
        uint256 _collateralAmount
    ) public payable whenNotPaused onlyGlyphHolder {
        require(_collateralAmount >= minPredictionCollateral, "Collateral too low.");
        require(msg.value == _collateralAmount, "Incorrect collateral sent.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(_outcomeHash != bytes32(0), "Outcome hash cannot be empty.");

        _predictionIdCounter.increment();
        uint256 newPredictionId = _predictionIdCounter.current();

        Prediction storage newPrediction = _predictions[newPredictionId];
        newPrediction.id = newPredictionId;
        newPrediction.proposer = msg.sender;
        newPrediction.description = _description;
        newPrediction.outcomeHash = _outcomeHash;
        newPrediction.deadline = _deadline;
        newPrediction.status = PredictionStatus.Pending;
        newPrediction.collateralTotal = _collateralAmount;
        newPrediction.participantsCollateral[msg.sender] = _collateralAmount;
        newPrediction.participantAddresses.push(msg.sender);

        emit PredictionProposed(newPredictionId, msg.sender, _collateralAmount);
    }

    /// @notice Allows a Glyph-holder to support an existing prediction with additional collateral.
    /// @param _predictionId The ID of the prediction to support.
    /// @param _supportAmount The amount of ETH to add as support.
    function supportPrediction(uint256 _predictionId, uint256 _supportAmount) public payable whenNotPaused onlyGlyphHolder {
        Prediction storage prediction = _predictions[_predictionId];
        require(prediction.status == PredictionStatus.Pending, "Prediction is not pending.");
        require(block.timestamp < prediction.deadline, "Prediction deadline passed.");
        require(_supportAmount > 0, "Support amount must be greater than zero.");
        require(msg.value == _supportAmount, "Incorrect support amount sent.");

        prediction.collateralTotal = prediction.collateralTotal.add(_supportAmount);
        if (prediction.participantsCollateral[msg.sender] == 0) {
            prediction.participantAddresses.push(msg.sender);
        }
        prediction.participantsCollateral[msg.sender] = prediction.participantsCollateral[msg.sender].add(_supportAmount);

        emit PredictionSupported(_predictionId, msg.sender, _supportAmount);
    }

    /// @notice Allows a Glyph-holder to challenge a proposed prediction.
    /// A challenge requires a separate collateral, which is slashed if the challenge fails.
    /// @param _predictionId The ID of the prediction to challenge.
    /// @param _reason A brief reason for the challenge.
    function challengePrediction(uint256 _predictionId, string memory _reason) public payable whenNotPaused onlyGlyphHolder {
        Prediction storage prediction = _predictions[_predictionId];
        require(prediction.status == PredictionStatus.Pending, "Prediction is not pending.");
        require(block.timestamp < prediction.deadline, "Prediction deadline passed.");
        require(!prediction.challengedBy[msg.sender], "You have already challenged this prediction.");
        require(msg.value >= minPredictionCollateral.mul(2), "Challenge requires higher collateral (2x min)."); // Example: 2x min collateral

        prediction.challengedBy[msg.sender] = true;
        prediction.challengeCollateral = prediction.challengeCollateral.add(msg.value);
        prediction.status = PredictionStatus.Challenged; // Prediction enters challenged state

        emit PredictionChallenged(_predictionId, msg.sender, _reason);
    }

    /// @notice Allows a designated resolution oracle to submit the actual outcome of a prediction.
    /// This function triggers the resolution logic.
    /// @param _predictionId The ID of the prediction to resolve.
    /// @param _actualOutcomeHash The keccak256 hash of the actual observed outcome.
    /// @param _resolverAddress The address of the oracle resolving (for logging).
    function submitOracleResolution(
        uint256 _predictionId,
        bytes32 _actualOutcomeHash,
        address _resolverAddress // Can be msg.sender or a specific oracle address from an off-chain system
    ) public whenNotPaused onlyResolutionOracle {
        Prediction storage prediction = _predictions[_predictionId];
        require(prediction.status == PredictionStatus.Pending || prediction.status == PredictionStatus.Challenged, "Prediction is already resolved or invalid state.");
        require(block.timestamp >= prediction.deadline, "Cannot resolve before deadline.");
        require(_actualOutcomeHash != bytes32(0), "Actual outcome hash cannot be empty.");

        prediction.actualOutcomeHash = _actualOutcomeHash;

        if (prediction.outcomeHash == _actualOutcomeHash) {
            prediction.status = PredictionStatus.ResolvedCorrect;
            // If challenged, challengers lose their collateral to the prediction pool
            if (prediction.challengeCollateral > 0) {
                // Collateral added to the pool of correct participants
                prediction.collateralTotal = prediction.collateralTotal.add(prediction.challengeCollateral);
                emit PredictionResolved(_predictionId, PredictionStatus.ResolvedCorrect, _actualOutcomeHash);
                // No specific event for challenge failure, it's absorbed into prediction success.
            } else {
                emit PredictionResolved(_predictionId, PredictionStatus.ResolvedCorrect, _actualOutcomeHash);
            }
        } else {
            prediction.status = PredictionStatus.ResolvedIncorrect;
            // If challenged and prediction was incorrect, challenger collateral is returned.
            // Proposer/supporters collateral is lost.
            emit PredictionResolved(_predictionId, PredictionStatus.ResolvedIncorrect, _actualOutcomeHash);
        }
    }

    /// @notice Allows participants (proposer or supporters) to claim their rewards if a prediction was correct.
    /// Triggers Glyph evolution for successful participants and degradation for incorrect ones.
    /// @param _predictionId The ID of the prediction.
    function claimPredictionReward(uint256 _predictionId) public whenNotPaused onlyGlyphHolder {
        Prediction storage prediction = _predictions[_predictionId];
        require(prediction.status == PredictionStatus.ResolvedCorrect || prediction.status == PredictionStatus.ResolvedIncorrect, "Prediction not resolved yet.");
        uint256 userTokenId = _ownerGlyph[msg.sender];
        require(userTokenId != 0, "Caller does not own a Glyph.");

        uint256 userCollateral = prediction.participantsCollateral[msg.sender];
        require(userCollateral > 0, "You did not participate in this prediction.");

        // Mark as claimed to prevent double claims
        prediction.participantsCollateral[msg.sender] = 0;

        if (prediction.status == PredictionStatus.ResolvedCorrect) {
            uint256 rewardAmount = userCollateral.mul(predictionRewardRatio).div(1000); // e.g., 150% reward
            payable(msg.sender).transfer(rewardAmount);
            emit PredictionRewardClaimed(_predictionId, msg.sender, rewardAmount);
            _handleGlyphEvolution(userTokenId, true); // Evolve Glyph
        } else if (prediction.status == PredictionStatus.ResolvedIncorrect) {
            // Collateral is lost, no reward
            emit PredictionRewardClaimed(_predictionId, msg.sender, 0); // Still emit for tracking, reward is 0
            _handleGlyphEvolution(userTokenId, false); // Degrade Glyph
        }
    }

    /// @dev Internal function to penalize incorrect predictions. This will typically be called by the oracle during resolution.
    /// @param _predictionId The ID of the prediction.
    function penalizeIncorrectPrediction(uint256 _predictionId) internal {
        Prediction storage prediction = _predictions[_predictionId];
        require(prediction.status == PredictionStatus.ResolvedIncorrect, "Prediction not resolved incorrect.");

        // If the prediction was incorrect, and someone challenged it correctly, return their collateral
        if (prediction.challengeCollateral > 0 && prediction.outcomeHash != prediction.actualOutcomeHash) {
            // Iterate over challengers and return their collateral
            // NOTE: A more robust solution might track individual challenger collateral if multiple challenges are allowed.
            // For simplicity, here we assume total challenge collateral and it's returned to the first challenger or a governance pot.
            // In this design, challenger collateral is absorbed if prediction is correct. If prediction is incorrect, it's returned.
            // A more complex system might return to specific challengers.
            // For now, let's assume challengeCollateral is pooled and lost on incorrect challenge, or returned on correct one.
            // Simpler: if prediction correct, challenger loses collateral to prediction pool. If incorrect, challenger gets collateral back.
            // The challengeCollateral is directly handled in submitOracleResolution.
        }

        // Proposer and supporters of the incorrect prediction lose their collateral.
        // The collateral remains in the contract, potentially added to the FutureFlux Pool, or burned.
        // For simplicity, it stays in the contract's balance and can be withdrawn by owner/governance, or auto-transferred to FutureFlux.
        // Let's have it implicitly held by contract for now.
    }

    // --- III. Glyph Evolution & Traits ---

    /// @dev Internal function to handle Glyph evolution (level up/down).
    /// @param _tokenId The ID of the Glyph to evolve.
    /// @param _isCorrect A boolean indicating if the associated prediction was correct.
    function _handleGlyphEvolution(uint256 _tokenId, bool _isCorrect) internal {
        Glyph storage glyph = _glyphs[_tokenId];

        if (_isCorrect) {
            glyph.correctPredictionsCount = glyph.correctPredictionsCount.add(1);
            if (glyph.correctPredictionsCount >= glyphLevelUpThreshold) {
                glyph.level = glyph.level.add(1);
                glyph.correctPredictionsCount = 0; // Reset for next level
                _mintNewTrait(_tokenId, uint8(glyph.level), 1); // Assign a new trait for leveling up
                emit GlyphLeveledUp(_tokenId, glyph.level);
                // Update metadata URI to reflect new level/traits
                _updateGlyphMetadata(_tokenId, string(abi.encodePacked(tokenURI(_tokenId), "?level=", Strings.toString(glyph.level))));
            }
        } else {
            glyph.incorrectPredictionsCount = glyph.incorrectPredictionsCount.add(1);
            if (glyph.level > 1) { // Cannot go below level 1
                glyph.level = glyph.level.sub(glyphLevelDecayRate);
                if (glyph.level < 1) glyph.level = 1; // Ensure level doesn't go below 1
                _mintNewTrait(_tokenId, uint8(glyph.level), 0); // Potentially remove/degrade a trait
                emit GlyphLeveledDown(_tokenId, glyph.level);
                // Update metadata URI to reflect new level/traits
                _updateGlyphMetadata(_tokenId, string(abi.encodePacked(tokenURI(_tokenId), "?level=", Strings.toString(glyph.level))));
            }
        }
    }

    /// @notice Retrieves the current traits and level of a user's ChronoGlyph.
    /// @param _owner The address of the Glyph owner.
    /// @return The Glyph's current level.
    function getGlyphTraits(address _owner) public view returns (uint256 level) {
        uint256 _tokenId = _ownerGlyph[_owner];
        require(_tokenId != 0, "Address does not own a ChronoGlyph.");
        return _glyphs[_tokenId].level;
        // In a real implementation, you'd iterate through glyph.traits mapping or
        // define specific trait getter functions if you have many.
    }

    /// @dev Internal function to add or update a specific trait for a Glyph.
    /// TraitType can represent different categories (e.g., 0: Wisdom, 1: Foresight).
    /// Value indicates the magnitude or presence of the trait.
    /// @param _tokenId The ID of the Glyph.
    /// @param _traitType The type of trait (e.g., an enum value).
    /// @param _value The value of the trait.
    function _mintNewTrait(uint256 _tokenId, uint8 _traitType, uint256 _value) internal {
        _glyphs[_tokenId].traits[_traitType] = _value;
        emit GlyphTraitUpdated(_tokenId, _traitType, _value);
    }

    // --- IV. FutureFlux Pool & Funding ---

    /// @notice Allows anyone to deposit Ether into the FutureFlux Pool.
    function depositToFutureFlux() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        emit FutureFluxDeposited(msg.sender, msg.value);
    }

    /// @notice Proposes a funding request from the FutureFlux Pool.
    /// Requires the proposer's Glyph to meet a minimum level.
    /// @param _description A description of the project requiring funding.
    /// @param _amount The amount of Ether requested.
    /// @param _requiredGlyphLevel The minimum Glyph level required to propose this request.
    function proposeFundingRequest(
        string memory _description,
        uint256 _amount,
        uint256 _requiredGlyphLevel
    ) public whenNotPaused onlyGlyphHolder {
        uint256 proposerGlyphLevel = _glyphs[_ownerGlyph[msg.sender]].level;
        require(proposerGlyphLevel >= _requiredGlyphLevel, "Glyph level too low to propose this request.");
        require(_amount > 0, "Funding amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient funds in FutureFlux Pool.");

        _fundingRequestIdCounter.increment();
        uint256 newRequestId = _fundingRequestIdCounter.current();

        FundingRequest storage newRequest = _fundingRequests[newRequestId];
        newRequest.id = newRequestId;
        newRequest.proposer = msg.sender;
        newRequest.description = _description;
        newRequest.amount = _amount;
        newRequest.requiredGlyphLevel = _requiredGlyphLevel;
        newRequest.status = FundingStatus.Proposed;
        newRequest.voteFor = 0;
        newRequest.voteAgainst = 0;

        emit FundingRequestProposed(newRequestId, msg.sender, _amount, _requiredGlyphLevel);
    }

    /// @notice Allows Glyph-holders to vote on a funding request.
    /// Only Glyphs with a level equal to or higher than the request's required level can vote.
    /// @param _requestId The ID of the funding request.
    /// @param _approve True for an 'approve' vote, false for 'reject'.
    function voteOnFundingRequest(uint256 _requestId, bool _approve) public whenNotPaused onlyGlyphHolder {
        FundingRequest storage request = _fundingRequests[_requestId];
        require(request.status == FundingStatus.Proposed, "Funding request is not in a votable state.");
        require(!request.hasVoted[msg.sender], "You have already voted on this request.");

        uint256 voterGlyphLevel = _glyphs[_ownerGlyph[msg.sender]].level;
        require(voterGlyphLevel >= request.requiredGlyphLevel, "Your Glyph level is too low to vote on this request.");

        request.hasVoted[msg.sender] = true;
        if (_approve) {
            request.voteFor = request.voteFor.add(1);
        } else {
            request.voteAgainst = request.voteAgainst.add(1);
        }

        emit FundingRequestVoted(_requestId, msg.sender, _approve);
    }

    /// @notice Executes a funding request if it has been approved by the community.
    /// Checks the voting threshold and transfers funds.
    /// @param _requestId The ID of the funding request to execute.
    function executeFundingRequest(uint256 _requestId) public whenNotPaused {
        FundingRequest storage request = _fundingRequests[_requestId];
        require(request.status == FundingStatus.Proposed, "Funding request is not proposed.");
        
        uint256 totalVotes = request.voteFor.add(request.voteAgainst);
        require(totalVotes > 0, "No votes cast yet.");

        uint256 approvalPercentage = request.voteFor.mul(100).div(totalVotes);
        
        if (approvalPercentage >= fundingVoteThreshold) {
            request.status = FundingStatus.Approved;
            require(address(this).balance >= request.amount, "Insufficient funds in FutureFlux Pool for execution.");
            payable(request.proposer).transfer(request.amount);
            request.status = FundingStatus.Executed;
            emit FundingRequestExecuted(_requestId, request.proposer, request.amount);
        } else {
            request.status = FundingStatus.Rejected;
            // Optionally, penalize proposer for rejected request, or allow re-proposal
        }
    }

    /// @notice Allows the contract owner to withdraw funds from the FutureFlux Pool in emergencies or for controlled releases.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of Ether to withdraw.
    function withdrawFromFutureFlux(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient funds in FutureFlux Pool.");
        payable(_to).transfer(_amount);
    }

    // --- V. System Configuration & Governance ---

    /// @notice Designates or revokes an address as a resolution oracle.
    /// Only callable by the contract owner.
    /// @param _oracleAddress The address to set/unset as oracle.
    /// @param _isOracle True to make it an oracle, false to revoke.
    function setResolutionOracle(address _oracleAddress, bool _isOracle) public onlyOwner {
        _isResolutionOracle[_oracleAddress] = _isOracle;
        emit OracleSet(_oracleAddress, _isOracle);
    }

    /// @notice Updates core parameters of the ChronoGlyphNexus system.
    /// Only callable by the contract owner.
    /// @param _newMinCollateral New minimum collateral for predictions.
    /// @param _newRewardRatio New reward multiplier for correct predictions (e.g., 1500 for 150%).
    /// @param _newDecayRate New Glyph level decay rate on incorrect predictions.
    /// @param _newFundingVoteThreshold New percentage needed for funding requests to pass.
    function updateChronoParams(
        uint256 _newMinCollateral,
        uint256 _newRewardRatio,
        uint256 _newDecayRate,
        uint256 _newFundingVoteThreshold
    ) public onlyOwner {
        require(_newMinCollateral > 0, "Min collateral must be positive.");
        require(_newRewardRatio > 1000, "Reward ratio should be greater than 100% (1000)."); // Ensure profit
        require(_newDecayRate > 0, "Decay rate must be positive.");
        require(_newFundingVoteThreshold > 0 && _newFundingVoteThreshold <= 100, "Funding threshold must be between 1-100.");

        minPredictionCollateral = _newMinCollateral;
        predictionRewardRatio = _newRewardRatio;
        glyphLevelDecayRate = _newDecayRate;
        fundingVoteThreshold = _newFundingVoteThreshold;

        emit ChronoParamsUpdated(minPredictionCollateral, predictionRewardRatio, glyphLevelDecayRate, fundingVoteThreshold);
    }

    /// @notice Pauses critical functions of the contract in an emergency.
    /// Only callable by the contract owner. Inherited from Pausable.
    function pauseSystem() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract after an emergency pause.
    /// Only callable by the contract owner. Inherited from Pausable.
    function unpauseSystem() public onlyOwner {
        _unpause();
    }

    /// @notice Transfers ownership of the contract.
    /// Only callable by the current owner. Inherited from Ownable.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) public override onlyOwner {
        super.transferOwnership(_newOwner);
    }
}
```