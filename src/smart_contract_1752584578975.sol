Here's a Solidity smart contract for a decentralized AI model refinement and generative art platform, named `SynthMindForge`. It aims to be unique by combining elements of AI-model curation (via oracles and community attestation), a dynamic NFT system that evolves, staking/slashing mechanisms, and a reputation system, without directly duplicating existing open-source projects.

This contract assumes the existence of two other deployed contracts:
1.  **SYMF (Synthetic Mind Forge Token)**: An ERC20 token used for staking, fees, and rewards.
2.  **SYNTH (Synthetic AI Output NFT)**: An ERC721 token representing the AI-generated art/models, which has a `mint(address to, uint256 tokenId)` function accessible by the `SynthMindForge` contract (e.g., via a Minter role).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Define custom errors for gas efficiency and clarity
error InvalidState(string message);
error Unauthorized(string message);
error InsufficientFunds(string message);
error InvalidAmount(string message);
error RecipeNotFound(uint256 recipeId);
error AttestationNotFound(uint256 attestationId);
error RefinerNotStaked();
error NotRefinementPhase();
error RefinementActive();
error RefinementCompleted();
error DuplicateAttestation();
error DisputeActive();
error DisputeResolved();
error NotSynthOwner();
error NotMintableState();

// Minimalistic interface for ERC721 with a `mint` function (assuming custom implementation)
interface IERC721Mintable is IERC721 {
    function mint(address to, uint256 tokenId) external;
}


/**
 * @title SynthMindForge
 * @dev A decentralized platform for AI model refinement, generative art creation,
 *      and dynamic NFT minting.
 *      Sculptors propose AI model "recipes". Refiners stake tokens to attest
 *      to the quality and potential of these recipes. Upon successful refinement,
 *      an AI oracle submits the generated output hash, leading to the minting
 *      of a dynamic "Synth" NFT. The platform incorporates a reputation system,
 *      staking, slashing, and a dispute mechanism.
 *
 * Outline:
 * 1.  State Variables & Enums
 * 2.  Events
 * 3.  Constructor & Initialization
 * 4.  Platform Management (Owner/Admin Functions)
 * 5.  Sculptor Functions (Recipe Proposal & Management)
 * 6.  Refiner Functions (Staking, Attestation, Dispute)
 * 7.  AI Oracle / Output Submission Functions
 * 8.  Synth (Dynamic NFT) Management
 * 9.  Reputation System (Internal & View)
 * 10. Helper Functions (Internal)
 *
 * Function Summary:
 *
 * **I. Platform Management (Owner/Admin Functions)**
 * - `constructor(address _symfTokenAddress, address _synthTokenAddress)`: Initializes the contract by setting the addresses of the SYMF ERC20 and SYNTH ERC721 tokens. The deployer becomes the initial owner and AI oracle.
 * - `setSYMFTokenAddress(IERC20 _symfToken)`: Allows the owner to update the address of the SYMF ERC20 token.
 * - `setSYNTHTokenAddress(IERC721Mintable _synthToken)`: Allows the owner to update the address of the SYNTH ERC721 token.
 * - `setMinimumRefinerStake(uint256 _amount)`: Sets the minimum amount of SYMF tokens a user must stake to become an active refiner.
 * - `setRefinementPhaseDuration(uint256 _duration)`: Sets the time duration (in seconds) for which a recipe remains open for refiner attestations.
 * - `setProtocolFeeRate(uint16 _rate)`: Sets the percentage of collected stakes that goes to the protocol treasury, expressed in basis points (e.g., 500 for 5%).
 * - `setAIOracleAddress(address _oracleAddress)`: Designates an address that is authorized to submit AI-generated output hashes, acting as a trusted AI oracle.
 * - `withdrawProtocolFees()`: Enables the contract owner to withdraw accumulated protocol fees (in SYMF tokens) to the owner's address.
 * - `pause()`: Activates the contract's pause mechanism, preventing most state-changing operations during emergencies. Only callable by the owner.
 * - `unpause()`: Deactivates the contract's pause mechanism, resuming normal operations. Only callable by the owner.
 *
 * **II. Sculptor Functions (Recipe Proposal & Management)**
 * - `proposeAIRecipe(AIRecipeParams memory _params, uint256 _sculptorStake)`: Allows a sculptor to propose a new AI model "recipe" by providing its parameters and staking a defined amount of SYMF tokens. The recipe enters a `Proposed` state.
 * - `updateAIRecipeParams(uint256 _recipeId, AIRecipeParams memory _newParams)`: Permits the sculptor to modify the parameters of their recipe, but only if it's still in the `Proposed` status.
 * - `finalizeRecipeProposal(uint256 _recipeId)`: Moves a recipe from the `Proposed` state to `RefinementPhase`, opening it up for refiner attestations and starting the refinement timer. Only callable by the sculptor.
 * - `claimSculptorRewards(uint256 _recipeId)`: Allows a sculptor to claim their initial stake back plus a bonus if their recipe was successfully refined and a Synth NFT was minted.
 * - `withdrawFailedRecipeStake(uint256 _recipeId)`: Enables a sculptor to reclaim their initial stake if their recipe failed to meet the refinement criteria within the set duration.
 *
 * **III. Refiner Functions (Staking, Attestation, Dispute)**
 * - `stakeAsRefiner(uint256 _amount)`: Allows any user to stake SYMF tokens, contributing to their total staked balance required to act as a refiner.
 * - `attestRecipeQuality(uint256 _recipeId, uint8 _qualityScore, uint256 _attestationStake)`: Allows a staked refiner to provide a quality score (1-100) for a recipe currently in `RefinementPhase`, backing their assessment with an additional stake. Prevents duplicate attestations per refiner per recipe.
 * - `challengeAttestation(uint256 _attestationId, uint256 _challengeStake)`: Enables a refiner to challenge a specific attestation made by another refiner, initiating a dispute. The challenger must stake an amount.
 * - `resolveAttestationDispute(uint256 _attestationId, bool _challengerWins)`: (Admin/Owner function) Resolves an active dispute, determining if the challenger's claim was valid. Stakes are distributed or slashed based on the outcome, affecting refuter reputations.
 * - `claimRefinerRewards()`: Allows a refiner to claim accumulated bonus rewards, which are a separate payout from the return of their original stakes (handled during recipe conclusion).
 * - `unstakeAsRefiner(uint256 _amount)`: Allows a refiner to withdraw a specified amount of SYMF tokens from their general staked pool in the contract.
 *
 * **IV. AI Oracle / Output Submission Functions**
 * - `submitAIOutputHash(uint256 _recipeId, bytes32 _outputHash, string calldata _outputURI)`: Callable only by the designated `AI_ORACLE_ADDRESS`, this function submits the verifiable hash and URI of the AI's generated output for a recipe that has successfully completed its refinement phase. This triggers the minting of a SYNTH NFT and the distribution of rewards/slashing.
 *
 * **V. Synth (Dynamic NFT) Management**
 * - `evolveSynth(uint256 _synthTokenId, bytes32 _newPropertiesHash, string calldata _newURI)`: Allows the current owner of a SYNTH NFT to update its `propertiesHash` and `currentURI`, signifying an "evolution" of the NFT's state or appearance. Increments the `evolutionStage`.
 * - `getSynthProperties(uint256 _synthTokenId)`: A view function to retrieve the current properties hash, URI, and evolution stage of a given SYNTH NFT.
 *
 * **VI. Reputation System (Internal & View)**
 * - `getSculptorScore(address _sculptor)`: Returns the current reputation score of a specified sculptor.
 * - `getRefinerScore(address _refiner)`: Returns the current reputation score of a specified refiner.
 * - `getRefinerStakedAmount(address _refiner)`: Returns the total amount of SYMF tokens currently staked by a refiner.
 * - `getRecipeDetails(uint256 _recipeId)`: A view function that returns all stored details for a specific AI recipe, including its status, parameters, and associated stakes.
 * - `getAttestationDetails(uint256 _attestationId)`: A view function that returns all stored details for a specific attestation, including the refiner, quality score, and dispute status.
 *
 * **VII. Helper Functions (Internal)**
 * - `_mintSynth(uint256 _recipeId, address _sculptor, bytes32 _outputHash, string memory _outputURI)`: An internal function responsible for minting a new SYNTH NFT to the sculptor's address upon successful recipe refinement.
 * - `_distributeRewardsAndSlashing(uint256 _recipeId)`: An internal function that processes all attestations for a successfully refined recipe, returning stakes to valid refiners, awarding bonuses, and slashing stakes from refiners who made poor or successfully challenged attestations.
 * - `_updateReputation(address _participant, bool _isSuccess, bool _isSculptor)`: An internal utility function used to adjust the reputation scores of sculptors or refiners based on the success or failure of their actions within the protocol.
 */
contract SynthMindForge is Ownable, Pausable, ReentrancyGuard {
    // I. State Variables & Enums

    IERC20 public SYMF_TOKEN; // Synthetic Mind Forge ERC20 Utility Token
    IERC721Mintable public SYNTH_TOKEN; // Synthetic AI-Generated Output ERC721 NFT

    uint256 public nextRecipeId;
    uint256 public nextAttestationId;
    uint256 public nextSynthTokenId;

    // Configuration parameters
    uint256 public minimumRefinerStake; // Minimum SYMF a refiner must stake to participate
    uint256 public refinementPhaseDuration; // Duration for the refinement phase in seconds
    uint16 public protocolFeeRate; // Fee percentage (e.g., 500 for 5%)

    uint256 public totalProtocolFeesCollected;

    // Enums for clarity and state management
    enum RecipeStatus {
        Proposed, // Sculptor proposed, parameters can be updated
        RefinementPhase, // Open for refiner attestations
        RefinementCompletedSuccess, // Successfully refined, waiting for AI output
        RefinementCompletedFailed, // Failed to meet refinement criteria
        SynthMinted // Synth NFT has been minted
    }

    enum DisputeStatus {
        None,
        Active,
        Resolved
    }

    // Structs for data organization
    struct AIRecipeParams {
        string modelType; // e.g., "Generative", "Classification"
        bytes dataHash; // Hash of off-chain input data/parameters, e.g., IPFS hash
        string aestheticTags; // e.g., "abstract", "photorealistic"
        uint256 complexityScore; // 1-100, impacts gas/compute expectation off-chain
        string outputFormat; // e.g., "image", "text", "audio"
    }

    struct Recipe {
        uint256 id;
        address sculptor;
        AIRecipeParams params;
        RecipeStatus status;
        uint256 creationTime;
        uint256 refinementPhaseStartTime;
        uint256 sculptorStake;
        uint256 totalAttestationStake; // Sum of all stakes on this recipe
        uint256 successfulAttestationCount; // Count of attestations above a threshold (e.g., avg > 70)
        uint256 totalQualityScoreSum; // Sum of all quality scores
        address synthOwner; // Owner of the minted Synth (initially sculptor)
        bytes32 finalOutputHash; // Hash of the final AI generated output
        string finalOutputURI; // URI for the final AI generated output
        uint256 synthTokenId; // ID of the minted SYNTH NFT
        bool rewardsClaimed; // True if sculptor has claimed rewards/stake
        uint256[] attestationIds; // List of all attestation IDs for this recipe
    }

    struct Attestation {
        uint256 id;
        uint256 recipeId;
        address refiner;
        uint8 qualityScore; // 1-100
        uint256 attestationStake;
        uint256 attestationTime;
        bool isDisputed;
        DisputeStatus disputeStatus;
        address challenger;
        uint256 challengeStake;
        bool challengerWins; // Outcome of the dispute
        bool rewardsClaimed; // True if refiner stake/bonus has been processed for this attestation
    }

    struct Synth {
        uint256 id;
        uint256 recipeId;
        bytes32 propertiesHash; // Hash representing the current state/properties of the Synth
        string currentURI; // URI to metadata/visuals of the current state
        uint8 evolutionStage; // How many times it has evolved
    }

    // Mappings for data retrieval
    mapping(uint256 => Recipe) public recipes;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => Synth) public synths;

    // Refiner specific data
    mapping(address => uint256) public refinerStakes; // Total SYMF staked by a refiner
    mapping(address => uint256) public refinerReputation; // Reputation score for refiners
    mapping(address => uint256) public sculptorReputation; // Reputation score for sculptors
    mapping(address => mapping(uint256 => bool)) public hasAttested; // To prevent duplicate attestations per refiner per recipe
    mapping(address => uint256) public refinerBonusRewards; // Pending bonus rewards for refiners

    // Define roles/access control beyond Ownable if needed
    address public AI_ORACLE_ADDRESS; // Address authorized to submit AI output hashes

    // II. Events

    event SYMFTokenAddressSet(address indexed _symfToken);
    event SYNTHTokenAddressSet(address indexed _synthToken);
    event MinimumRefinerStakeSet(uint256 _amount);
    event RefinementPhaseDurationSet(uint256 _duration);
    event ProtocolFeeRateSet(uint16 _rate);
    event AIOracleAddressSet(address indexed _oracleAddress);
    event ProtocolFeesWithdrawn(address indexed _to, uint256 _amount);

    event AIRecipeProposed(uint256 indexed _recipeId, address indexed _sculptor, uint256 _sculptorStake, AIRecipeParams _params);
    event AIRecipeParamsUpdated(uint256 indexed _recipeId, AIRecipeParams _newParams);
    event AIRecipeFinalized(uint256 indexed _recipeId, uint256 _refinementPhaseStartTime);
    event SculptorRewardsClaimed(uint256 indexed _recipeId, address indexed _sculptor, uint256 _amount);
    event FailedRecipeStakeWithdrawn(uint256 indexed _recipeId, address indexed _sculptor, uint256 _amount);

    event RefinerStaked(address indexed _refiner, uint256 _amount, uint256 _totalStake);
    event RefinerAttested(uint256 indexed _attestationId, uint256 indexed _recipeId, address indexed _refiner, uint8 _qualityScore, uint256 _attestationStake);
    event AttestationDisputeChallenged(uint256 indexed _attestationId, address indexed _challenger, uint256 _challengeStake);
    event AttestationDisputeResolved(uint256 indexed _attestationId, bool _challengerWins);
    event RefinerBonusRewardsClaimed(address indexed _refiner, uint256 _totalAmount);
    event RefinerUnstaked(address indexed _refiner, uint256 _amount, uint256 _totalStake);

    event AIOutputSubmitted(uint256 indexed _recipeId, bytes32 _outputHash, string _outputURI);
    event SynthMinted(uint256 indexed _synthTokenId, uint256 indexed _recipeId, address indexed _owner);
    event SynthEvolved(uint256 indexed _synthTokenId, uint8 _newEvolutionStage, bytes32 _newPropertiesHash, string _newURI);

    // III. Constructor & Initialization

    constructor(address _symfTokenAddress, address _synthTokenAddress) Ownable(msg.sender) {
        if (_symfTokenAddress == address(0) || _synthTokenAddress == address(0)) {
            revert InvalidAmount("Token addresses cannot be zero");
        }
        SYMF_TOKEN = IERC20(_symfTokenAddress);
        SYNTH_TOKEN = IERC721Mintable(_synthTokenAddress);

        nextRecipeId = 1;
        nextAttestationId = 1;
        nextSynthTokenId = 1;

        minimumRefinerStake = 100 * 10**18; // Default: 100 SYMF, assuming 18 decimals
        refinementPhaseDuration = 7 days; // Default: 7 days
        protocolFeeRate = 500; // Default: 5% (500 basis points)
        AI_ORACLE_ADDRESS = msg.sender; // Owner is default AI oracle, can be changed.

        emit SYMFTokenAddressSet(_symfTokenAddress);
        emit SYNTHTokenAddressSet(_synthTokenAddress);
        emit MinimumRefinerStakeSet(minimumRefinerStake);
        emit RefinementPhaseDurationSet(refinementPhaseDuration);
        emit ProtocolFeeRateSet(protocolFeeRate);
        emit AIOracleAddressSet(AI_ORACLE_ADDRESS);
    }

    // IV. Platform Management (Owner/Admin Functions)

    /**
     * @dev Sets the address of the SYMF ERC20 token.
     * @param _symfToken The address of the SYMF token contract.
     */
    function setSYMFTokenAddress(IERC20 _symfToken) external onlyOwner {
        if (address(_symfToken) == address(0)) revert InvalidAmount("Token address cannot be zero");
        SYMF_TOKEN = _symfToken;
        emit SYMFTokenAddressSet(address(_symfToken));
    }

    /**
     * @dev Sets the address of the SYNTH ERC721 token.
     * @param _synthToken The address of the SYNTH token contract.
     */
    function setSYNTHTokenAddress(IERC721Mintable _synthToken) external onlyOwner {
        if (address(_synthToken) == address(0)) revert InvalidAmount("Token address cannot be zero");
        SYNTH_TOKEN = _synthToken;
        emit SYNTHTokenAddressSet(address(_synthToken));
    }

    /**
     * @dev Sets the minimum stake required for a refiner.
     * @param _amount The new minimum stake amount in SYMF.
     */
    function setMinimumRefinerStake(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert InvalidAmount("Minimum refiner stake cannot be zero");
        minimumRefinerStake = _amount;
        emit MinimumRefinerStakeSet(_amount);
    }

    /**
     * @dev Sets the duration for the refinement phase in seconds.
     * @param _duration The new duration in seconds.
     */
    function setRefinementPhaseDuration(uint256 _duration) external onlyOwner {
        if (_duration == 0) revert InvalidAmount("Refinement phase duration cannot be zero");
        refinementPhaseDuration = _duration;
        emit RefinementPhaseDurationSet(_duration);
    }

    /**
     * @dev Sets the protocol fee percentage.
     * @param _rate The fee rate in basis points (e.g., 500 for 5%). Max 10,000 (100%).
     */
    function setProtocolFeeRate(uint16 _rate) external onlyOwner {
        if (_rate > 10000) revert InvalidAmount("Fee rate cannot exceed 100%");
        protocolFeeRate = _rate;
        emit ProtocolFeeRateSet(_rate);
    }

    /**
     * @dev Allows the owner to set the address of the authorized AI oracle.
     * @param _oracleAddress The address of the AI oracle.
     */
    function setAIOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) revert InvalidAmount("Oracle address cannot be zero");
        AI_ORACLE_ADDRESS = _oracleAddress;
        emit AIOracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Allows the owner to withdraw collected protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        if (totalProtocolFeesCollected == 0) revert InsufficientFunds("No fees to withdraw");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        SYMF_TOKEN.transfer(owner(), amount);
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // V. Sculptor Functions (Recipe Proposal & Management)

    /**
     * @dev Allows a sculptor to propose a new AI model recipe, locking a stake.
     * The stake is used as a commitment and for dispute resolution.
     * @param _params The structured parameters for the AI recipe.
     * @param _sculptorStake The amount of SYMF tokens the sculptor stakes.
     */
    function proposeAIRecipe(AIRecipeParams memory _params, uint256 _sculptorStake) external whenNotPaused nonReentrant {
        if (_sculptorStake == 0) revert InvalidAmount("Sculptor stake cannot be zero");
        SYMF_TOKEN.transferFrom(msg.sender, address(this), _sculptorStake);

        uint256 currentRecipeId = nextRecipeId++;
        recipes[currentRecipeId] = Recipe({
            id: currentRecipeId,
            sculptor: msg.sender,
            params: _params,
            status: RecipeStatus.Proposed,
            creationTime: block.timestamp,
            refinementPhaseStartTime: 0,
            sculptorStake: _sculptorStake,
            totalAttestationStake: 0,
            successfulAttestationCount: 0,
            totalQualityScoreSum: 0,
            synthOwner: address(0), // Set later upon minting
            finalOutputHash: bytes32(0),
            finalOutputURI: "",
            synthTokenId: 0,
            rewardsClaimed: false,
            attestationIds: new uint256[](0) // Initialize empty array
        });

        emit AIRecipeProposed(currentRecipeId, msg.sender, _sculptorStake, _params);
    }

    /**
     * @dev Allows a sculptor to update a recipe's parameters before it enters refinement.
     * @param _recipeId The ID of the recipe to update.
     * @param _newParams The new structured parameters for the AI recipe.
     */
    function updateAIRecipeParams(uint256 _recipeId, AIRecipeParams memory _newParams) external whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.sculptor != msg.sender) revert Unauthorized("Only the sculptor can update params");
        if (recipe.status != RecipeStatus.Proposed) revert InvalidState("Recipe must be in Proposed status to update params");

        recipe.params = _newParams;
        emit AIRecipeParamsUpdated(_recipeId, _newParams);
    }

    /**
     * @dev Moves a proposed recipe into the refinement phase, starting the timer.
     * This signals that the recipe is ready for refiner attestations.
     * @param _recipeId The ID of the recipe to finalize.
     */
    function finalizeRecipeProposal(uint256 _recipeId) external whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.sculptor != msg.sender) revert Unauthorized("Only the sculptor can finalize proposal");
        if (recipe.status != RecipeStatus.Proposed) revert InvalidState("Recipe must be in Proposed status");

        recipe.status = RecipeStatus.RefinementPhase;
        recipe.refinementPhaseStartTime = block.timestamp;
        emit AIRecipeFinalized(_recipeId, block.timestamp);
    }

    /**
     * @dev Allows a sculptor to claim rewards for a successfully refined and minted Synth.
     * Rewards are distributed after the Synth is minted.
     * @param _recipeId The ID of the recipe for which to claim rewards.
     */
    function claimSculptorRewards(uint256 _recipeId) external nonReentrant {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.sculptor != msg.sender) revert Unauthorized("Only the sculptor can claim rewards");
        if (recipe.status != RecipeStatus.SynthMinted) revert InvalidState("Synth not yet minted or recipe not successful");
        if (recipe.rewardsClaimed) revert InvalidState("Rewards already claimed");

        // Sculptor gets their initial stake back + a small bonus
        uint256 rewardAmount = recipe.sculptorStake;
        uint256 bonus = (recipe.totalAttestationStake * 10) / 1000; // 1% of total attestation stake
        rewardAmount += bonus;

        recipe.rewardsClaimed = true;
        SYMF_TOKEN.transfer(msg.sender, rewardAmount);
        emit SculptorRewardsClaimed(_recipeId, msg.sender, rewardAmount);

        _updateReputation(msg.sender, true, true);
    }

    /**
     * @dev Allows a sculptor to withdraw their stake if a recipe fails to be refined.
     * A recipe fails if it doesn't meet the refinement criteria within the phase duration.
     * @param _recipeId The ID of the recipe.
     */
    function withdrawFailedRecipeStake(uint256 _recipeId) external nonReentrant {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.sculptor != msg.sender) revert Unauthorized("Only the sculptor can withdraw stake");
        if (recipe.status == RecipeStatus.Proposed) revert InvalidState("Recipe still in Proposed status. Finalize or wait.");
        if (recipe.status == RecipeStatus.SynthMinted) revert InvalidState("Recipe was successful and minted Synth.");
        if (recipe.status == RecipeStatus.RefinementPhase && block.timestamp < recipe.refinementPhaseStartTime + refinementPhaseDuration) {
            revert NotRefinementPhase("Refinement phase still active.");
        }
        if (recipe.rewardsClaimed) revert InvalidState("Stake already withdrawn or claimed as reward.");

        if (recipe.status != RecipeStatus.RefinementCompletedFailed) {
            recipe.status = RecipeStatus.RefinementCompletedFailed;
        }

        uint256 stakeAmount = recipe.sculptorStake;
        recipe.sculptorStake = 0; // Clear stake after withdrawal
        recipe.rewardsClaimed = true; // Mark as processed

        SYMF_TOKEN.transfer(msg.sender, stakeAmount);
        emit FailedRecipeStakeWithdrawn(_recipeId, msg.sender, stakeAmount);

        _updateReputation(msg.sender, false, true);
    }

    // VI. Refiner Functions (Staking, Attestation, Dispute)

    /**
     * @dev Allows a user to stake SYMF tokens to become a refiner.
     * The staked amount is added to their total refiner stake.
     * @param _amount The amount of SYMF tokens to stake.
     */
    function stakeAsRefiner(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount("Stake amount cannot be zero");
        // Ensure total stake meets minimum. If not, require to top up to minimum.
        if (refinerStakes[msg.sender] < minimumRefinerStake && refinerStakes[msg.sender] + _amount < minimumRefinerStake) {
            revert InsufficientFunds("Total stake must meet minimum requirement");
        }

        SYMF_TOKEN.transferFrom(msg.sender, address(this), _amount);
        refinerStakes[msg.sender] += _amount;
        emit RefinerStaked(msg.sender, _amount, refinerStakes[msg.sender]);
    }

    /**
     * @dev Refiners attest to a recipe's quality, staking a portion of their SYMF.
     * This increases the recipe's total attestation stake and contributes to its quality score.
     * @param _recipeId The ID of the recipe to attest.
     * @param _qualityScore The quality score (1-100) given by the refiner.
     * @param _attestationStake The amount of SYMF tokens staked for this attestation.
     */
    function attestRecipeQuality(uint256 _recipeId, uint8 _qualityScore, uint256 _attestationStake) external whenNotPaused nonReentrant {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.status != RecipeStatus.RefinementPhase) revert NotRefinementPhase("Recipe not in refinement phase");
        if (block.timestamp >= recipe.refinementPhaseStartTime + refinementPhaseDuration) revert RefinementCompleted("Refinement phase has ended");
        if (refinerStakes[msg.sender] < minimumRefinerStake) revert RefinerNotStaked();
        if (_qualityScore == 0 || _qualityScore > 100) revert InvalidAmount("Quality score must be between 1 and 100");
        if (_attestationStake == 0) revert InvalidAmount("Attestation stake cannot be zero");
        if (refinerStakes[msg.sender] < _attestationStake) revert InsufficientFunds("Not enough staked SYMF for attestation");
        if (hasAttested[msg.sender][_recipeId]) revert DuplicateAttestation();

        refinerStakes[msg.sender] -= _attestationStake; // Deduct from refiner's available stake (still in contract)
        recipe.totalAttestationStake += _attestationStake;
        recipe.totalQualityScoreSum += _qualityScore;
        // Increment successfulAttestationCount if _qualityScore meets a simple threshold for initial tally.
        // The final determination of success is in `submitAIOutputHash`.
        if (_qualityScore > 50) { // A lenient threshold just to count participants for a recipe success tally
            recipe.successfulAttestationCount++;
        }

        uint256 currentAttestationId = nextAttestationId++;
        attestations[currentAttestationId] = Attestation({
            id: currentAttestationId,
            recipeId: _recipeId,
            refiner: msg.sender,
            qualityScore: _qualityScore,
            attestationStake: _attestationStake,
            attestationTime: block.timestamp,
            isDisputed: false,
            disputeStatus: DisputeStatus.None,
            challenger: address(0),
            challengeStake: 0,
            challengerWins: false,
            rewardsClaimed: false
        });
        hasAttested[msg.sender][_recipeId] = true;
        recipe.attestationIds.push(currentAttestationId); // Store attestation ID for easier iteration

        emit RefinerAttested(currentAttestationId, _recipeId, msg.sender, _qualityScore, _attestationStake);
    }

    /**
     * @dev Allows a refiner to challenge another refiner's attestation, initiating a dispute.
     * Requires the challenger to stake an amount.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _challengeStake The amount of SYMF tokens to stake for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, uint256 _challengeStake) external whenNotPaused nonReentrant {
        Attestation storage att = attestations[_attestationId];
        if (att.id == 0) revert AttestationNotFound(_attestationId);
        if (att.refiner == msg.sender) revert InvalidState("Cannot challenge your own attestation");
        if (att.isDisputed) revert DisputeActive("Attestation already under dispute");
        if (refinerStakes[msg.sender] < minimumRefinerStake) revert RefinerNotStaked();
        if (refinerStakes[msg.sender] < _challengeStake) revert InsufficientFunds("Not enough staked SYMF for challenge");
        if (_challengeStake == 0) revert InvalidAmount("Challenge stake cannot be zero");

        // Ensure the recipe for this attestation is still in a state where disputes are relevant
        Recipe storage recipe = recipes[att.recipeId];
        if (recipe.status != RecipeStatus.RefinementPhase && recipe.status != RecipeStatus.RefinementCompletedSuccess) {
            revert InvalidState("Recipe is not in a disputable phase");
        }

        SYMF_TOKEN.transferFrom(msg.sender, address(this), _challengeStake); // Transfer stake to contract
        refinerStakes[msg.sender] -= _challengeStake; // Deduct from refiner's available stake (still in contract)

        att.isDisputed = true;
        att.disputeStatus = DisputeStatus.Active;
        att.challenger = msg.sender;
        att.challengeStake = _challengeStake;

        emit AttestationDisputeChallenged(_attestationId, msg.sender, _challengeStake);
    }

    /**
     * @dev Owner/DAO resolves an attestation dispute, distributing stakes accordingly.
     * This function should ideally be called by a DAO or a trusted oracle after off-chain arbitration.
     * @param _attestationId The ID of the attestation dispute to resolve.
     * @param _challengerWins True if the challenger's claim is valid, false otherwise.
     */
    function resolveAttestationDispute(uint256 _attestationId, bool _challengerWins) external onlyOwner nonReentrant {
        Attestation storage att = attestations[_attestationId];
        if (att.id == 0) revert AttestationNotFound(_attestationId);
        if (att.disputeStatus != DisputeStatus.Active) revert DisputeResolved("Dispute not active or already resolved");

        att.disputeStatus = DisputeStatus.Resolved;
        att.challengerWins = _challengerWins;

        if (_challengerWins) {
            // Challenger wins: Original attester is penalized, challenger is rewarded
            // Attester's stake is slashed. Challenger gets their stake back + bonus from attester's slashed stake.
            uint256 attesterSlashedAmount = att.attestationStake;
            totalProtocolFeesCollected += attesterSlashedAmount; // Protocol takes attester's stake

            refinerStakes[att.challenger] += att.challengeStake; // Challenger gets their stake back
            refinerBonusRewards[att.challenger] += (attesterSlashedAmount * 50) / 100; // 50% of attester's slashed stake goes to challenger
            _updateReputation(att.refiner, false, false); // Attester loses reputation
            _updateReputation(att.challenger, true, false); // Challenger gains reputation
        } else {
            // Challenger loses: Challenger's stake is penalized, original attester's stake is returned.
            uint256 challengerSlashedAmount = att.challengeStake;
            totalProtocolFeesCollected += challengerSlashedAmount; // Protocol takes challenger's stake

            refinerStakes[att.refiner] += att.attestationStake; // Attester gets their stake back
            refinerBonusRewards[att.refiner] += (challengerSlashedAmount * 50) / 100; // 50% of challenger's slashed stake goes to attester
            _updateReputation(att.refiner, true, false); // Attester gains reputation
            _updateReputation(att.challenger, false, false); // Challenger loses reputation
        }
        att.rewardsClaimed = true; // Mark the attestation as processed
        emit AttestationDisputeResolved(_attestationId, _challengerWins);
    }

    /**
     * @dev Allows a refiner to claim accumulated bonus rewards from successful attestations.
     * These are separate from the return of their original staked amount, which is handled
     * when the recipe is concluded.
     */
    function claimRefinerRewards() external nonReentrant {
        uint256 bonusAmount = refinerBonusRewards[msg.sender];
        if (bonusAmount == 0) revert InvalidState("No bonus rewards to claim");
        refinerBonusRewards[msg.sender] = 0; // Reset
        SYMF_TOKEN.transfer(msg.sender, bonusAmount);
        emit RefinerBonusRewardsClaimed(msg.sender, bonusAmount);
    }

    /**
     * @dev Allows a refiner to unstake SYMF tokens from their general stake pool.
     * Does not affect specific attestation stakes unless they have been processed.
     * @param _amount The amount of SYMF to unstake.
     */
    function unstakeAsRefiner(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount("Unstake amount cannot be zero");
        if (refinerStakes[msg.sender] < _amount) revert InsufficientFunds("Not enough staked SYMF to unstake");

        // In a real system, a cooldown period might be implemented here to prevent rapid unstaking.
        // For simplicity, it's instant here.

        refinerStakes[msg.sender] -= _amount;
        SYMF_TOKEN.transfer(msg.sender, _amount);
        emit RefinerUnstaked(msg.sender, _amount, refinerStakes[msg.sender]);
    }

    // VII. AI Oracle / Output Submission Functions

    /**
     * @dev Authorized AI oracle submits the final AI-generated output hash and URI for a successfully refined recipe.
     * This function can only be called if the recipe has successfully passed the refinement phase.
     * Triggers Synth NFT minting and rewards distribution.
     * @param _recipeId The ID of the recipe.
     * @param _outputHash The SHA-256 hash of the final AI-generated output data.
     * @param _outputURI The URI pointing to the actual output data or its metadata.
     */
    function submitAIOutputHash(uint256 _recipeId, bytes32 _outputHash, string calldata _outputURI) external whenNotPaused {
        if (msg.sender != AI_ORACLE_ADDRESS) revert Unauthorized("Only authorized AI oracle can submit output hash");

        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        if (recipe.status != RecipeStatus.RefinementPhase) revert InvalidState("Recipe not in refinement phase");
        if (block.timestamp < recipe.refinementPhaseStartTime + refinementPhaseDuration) revert RefinementActive("Refinement phase not yet ended");

        // Define success criteria (example values)
        uint256 minAttestationsRequired = 3; // At least 3 refiners needed
        uint256 minAverageQualityScore = 70; // Average score must be at least 70

        // Check if the recipe meets the minimum requirements based on collected attestations
        if (recipe.successfulAttestationCount < minAttestationsRequired ||
            (recipe.successfulAttestationCount > 0 && recipe.totalQualityScoreSum / recipe.successfulAttestationCount < minAverageQualityScore)) {
            recipe.status = RecipeStatus.RefinementCompletedFailed;
            // Sculptor can call `withdrawFailedRecipeStake` to get stake back
            revert InvalidState("Recipe failed to meet refinement criteria.");
        }

        recipe.finalOutputHash = _outputHash;
        recipe.finalOutputURI = _outputURI;
        recipe.status = RecipeStatus.RefinementCompletedSuccess;

        emit AIOutputSubmitted(_recipeId, _outputHash, _outputURI);

        _mintSynth(_recipeId, recipe.sculptor, _outputHash, _outputURI);
        _distributeRewardsAndSlashing(_recipeId);
    }

    // VIII. Synth (Dynamic NFT) Management

    /**
     * @dev Internal function to mint a new SYNTH NFT.
     * Called automatically after successful AI output submission.
     * @param _recipeId The ID of the recipe that led to this Synth.
     * @param _sculptor The address of the sculptor who proposed the recipe.
     * @param _outputHash The initial properties hash for the Synth.
     * @param _outputURI The initial URI for the Synth's metadata/visuals.
     */
    function _mintSynth(uint256 _recipeId, address _sculptor, bytes32 _outputHash, string memory _outputURI) internal {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.status != RecipeStatus.RefinementCompletedSuccess) revert NotMintableState("Recipe not in successful state for minting");
        if (recipe.synthTokenId != 0) revert InvalidState("Synth already minted for this recipe");

        uint256 currentSynthTokenId = nextSynthTokenId++;
        recipe.synthTokenId = currentSynthTokenId;
        recipe.synthOwner = _sculptor;
        recipe.status = RecipeStatus.SynthMinted;

        synths[currentSynthTokenId] = Synth({
            id: currentSynthTokenId,
            recipeId: _recipeId,
            propertiesHash: _outputHash,
            currentURI: _outputURI,
            evolutionStage: 0
        });

        // The SYNTH_TOKEN contract must have a mint function that this contract is authorized to call.
        // This typically means SynthMindForge's address is set as a Minter role in the SYNTH ERC721 contract.
        SYNTH_TOKEN.mint(_sculptor, currentSynthTokenId);
        emit SynthMinted(currentSynthTokenId, _recipeId, _sculptor);
    }

    /**
     * @dev Allows the owner of a Synth to trigger its evolution, updating its properties and URI.
     * This could involve paying a fee or interacting with another AI service off-chain.
     * @param _synthTokenId The ID of the SYNTH NFT to evolve.
     * @param _newPropertiesHash The new hash representing the evolved properties.
     * @param _newURI The new URI for the evolved Synth's metadata/visuals.
     */
    function evolveSynth(uint256 _synthTokenId, bytes32 _newPropertiesHash, string calldata _newURI) external whenNotPaused {
        Synth storage synth = synths[_synthTokenId];
        if (synth.id == 0) revert InvalidState("Synth not found");
        // Ensure msg.sender is the current owner of the SYNTH NFT
        if (SYNTH_TOKEN.ownerOf(_synthTokenId) != msg.sender) revert NotSynthOwner("Only Synth owner can evolve");

        // Optional: require payment in SYMF for evolution, collected as protocol fees
        // uint256 evolutionFee = 10 * 10**18; // Example fee (10 SYMF)
        // SYMF_TOKEN.transferFrom(msg.sender, address(this), evolutionFee);
        // totalProtocolFeesCollected += evolutionFee;

        synth.propertiesHash = _newPropertiesHash;
        synth.currentURI = _newURI;
        synth.evolutionStage++;

        emit SynthEvolved(_synthTokenId, synth.evolutionStage, _newPropertiesHash, _newURI);
    }

    /**
     * @dev Returns the current properties hash and URI of a Synth.
     * @param _synthTokenId The ID of the SYNTH NFT.
     * @return _propertiesHash The current properties hash.
     * @return _currentURI The current URI.
     * @return _evolutionStage The current evolution stage.
     */
    function getSynthProperties(uint256 _synthTokenId) external view returns (bytes32 _propertiesHash, string memory _currentURI, uint8 _evolutionStage) {
        Synth storage synth = synths[_synthTokenId];
        if (synth.id == 0) revert InvalidState("Synth not found");
        return (synth.propertiesHash, synth.currentURI, synth.evolutionStage);
    }

    // IX. Reputation System (Internal & View)

    /**
     * @dev Internal function to update reputation scores.
     * @param _participant The address of the participant (sculptor or refiner).
     * @param _isSuccess True if the action was successful, false otherwise.
     * @param _isSculptor True if the participant is a sculptor, false if a refiner.
     */
    function _updateReputation(address _participant, bool _isSuccess, bool _isSculptor) internal {
        if (_isSculptor) {
            if (_isSuccess) {
                sculptorReputation[_participant] += 10; // Gain 10 points for success
            } else {
                sculptorReputation[_participant] = sculptorReputation[_participant] >= 5 ? sculptorReputation[_participant] - 5 : 0; // Lose 5 points
            }
        } else { // Refiner
            if (_isSuccess) {
                refinerReputation[_participant] += 5; // Gain 5 points for success
            } else {
                refinerReputation[_participant] = refinerReputation[_participant] >= 2 ? refinerReputation[_participant] - 2 : 0; // Lose 2 points
            }
        }
    }

    /**
     * @dev Returns the current reputation score of a sculptor.
     * @param _sculptor The address of the sculptor.
     * @return The sculptor's reputation score.
     */
    function getSculptorScore(address _sculptor) external view returns (uint256) {
        return sculptorReputation[_sculptor];
    }

    /**
     * @dev Returns the current reputation score of a refiner.
     * @param _refiner The address of the refiner.
     * @return The refiner's reputation score.
     */
    function getRefinerScore(address _refiner) external view returns (uint256) {
        return refinerReputation[_refiner];
    }

    /**
     * @dev Returns the total SYMF staked by a refiner.
     * @param _refiner The address of the refiner.
     * @return The total staked amount.
     */
    function getRefinerStakedAmount(address _refiner) external view returns (uint256) {
        return refinerStakes[_refiner];
    }

    /**
     * @dev Returns the details of a specific recipe.
     * @param _recipeId The ID of the recipe.
     * @return A tuple containing all recipe details.
     */
    function getRecipeDetails(uint256 _recipeId)
        external
        view
        returns (
            uint256 id,
            address sculptor,
            AIRecipeParams memory params,
            RecipeStatus status,
            uint256 creationTime,
            uint256 refinementPhaseStartTime,
            uint256 sculptorStake,
            uint256 totalAttestationStake,
            uint256 successfulAttestationCount,
            uint256 totalQualityScoreSum,
            address synthOwner,
            bytes32 finalOutputHash,
            string memory finalOutputURI,
            uint256 synthTokenId,
            bool rewardsClaimed,
            uint256[] memory attestationIds
        )
    {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeNotFound(_recipeId);
        return (
            recipe.id,
            recipe.sculptor,
            recipe.params,
            recipe.status,
            recipe.creationTime,
            recipe.refinementPhaseStartTime,
            recipe.sculptorStake,
            recipe.totalAttestationStake,
            recipe.successfulAttestationCount,
            recipe.totalQualityScoreSum,
            recipe.synthOwner,
            recipe.finalOutputHash,
            recipe.finalOutputURI,
            recipe.synthTokenId,
            recipe.rewardsClaimed,
            recipe.attestationIds
        );
    }

    /**
     * @dev Returns the details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return A tuple containing all attestation details.
     */
    function getAttestationDetails(uint256 _attestationId)
        external
        view
        returns (
            uint256 id,
            uint256 recipeId,
            address refiner,
            uint8 qualityScore,
            uint256 attestationStake,
            uint256 attestationTime,
            bool isDisputed,
            DisputeStatus disputeStatus,
            address challenger,
            uint256 challengeStake,
            bool challengerWins,
            bool rewardsClaimed
        )
    {
        Attestation storage att = attestations[_attestationId];
        if (att.id == 0) revert AttestationNotFound(_attestationId);
        return (
            att.id,
            att.recipeId,
            att.refiner,
            att.qualityScore,
            att.attestationStake,
            att.attestationTime,
            att.isDisputed,
            att.disputeStatus,
            att.challenger,
            att.challengeStake,
            att.challengerWins,
            att.rewardsClaimed
        );
    }

    // X. Helper Functions (Internal)

    /**
     * @dev Internal function to distribute rewards and handle slashing after recipe refinement.
     * This function iterates through all attestations made for a given recipe
     * and adjusts refiner stakes and bonus rewards based on the outcome.
     * @param _recipeId The ID of the recipe that has completed refinement.
     */
    function _distributeRewardsAndSlashing(uint256 _recipeId) internal {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.status != RecipeStatus.SynthMinted) revert InvalidState("Recipe not in SynthMinted status for reward distribution");

        // Define a threshold for a "successful" individual attestation within a successful recipe
        uint256 minSuccessQualityScore = 70;

        for (uint256 i = 0; i < recipe.attestationIds.length; i++) {
            uint256 attId = recipe.attestationIds[i];
            Attestation storage att = attestations[attId];

            // Skip if attestation is invalid (e.g., deleted), or already processed
            if (att.refiner == address(0) || att.rewardsClaimed) continue;

            // Determine if the attestation was valid (not successfully disputed)
            bool attestationValid = (!att.isDisputed || (att.disputeStatus == DisputeStatus.Resolved && !att.challengerWins));

            if (attestationValid && att.qualityScore >= minSuccessQualityScore) {
                // Refiner made a good attestation and it was not successfully challenged
                refinerStakes[att.refiner] += att.attestationStake; // Return original staked amount
                refinerBonusRewards[att.refiner] += (att.attestationStake * 5) / 1000; // Small 0.5% bonus from stake (example)
                _updateReputation(att.refiner, true, false); // Increase refiner's reputation
            } else {
                // Refiner made a poor attestation (below consensus) or was successfully challenged
                uint256 slashedAmount = (att.attestationStake * 20) / 100; // Example: 20% of stake is slashed
                totalProtocolFeesCollected += slashedAmount; // Slashed amount goes to protocol treasury
                refinerStakes[att.refiner] += (att.attestationStake - slashedAmount); // Return remaining stake
                _updateReputation(att.refiner, false, false); // Decrease refiner's reputation
            }
            att.rewardsClaimed = true; // Mark attestation as processed
        }
    }
}
```