Here is a Solidity smart contract named `DAFAN_ForesightNetwork` that incorporates advanced concepts like AI oracle integration, ZK-proof verification (via an external contract), a dynamic soulbound reputation system, and a decentralized autonomous organization (DAO) for action protocols based on collective foresight. This design aims to be creative and avoid direct duplication of existing large open-source projects by combining these elements into a unique system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
// SafeMath is not explicitly needed for Solidity 0.8.0+ as arithmetic operations revert on overflow/underflow by default.

// --- INTERFACES ---

/**
 * @dev Interface for a minimal ERC721 Soulbound Token (SBT).
 *      This interface defines the essential functions for a non-transferable token.
 */
interface IForesightSBT {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getTokenId(address owner) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external; // Required for ERC721 compliance, but will revert
    function safeTransferFrom(address from, address to, uint256 tokenId) external; // Required for ERC721 compliance, but will revert
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external; // Required for ERC721 compliance, but will revert
    function approve(address to, uint256 tokenId) external; // Required for ERC721 compliance, but will revert
    function setApprovalForAll(address operator, bool approved) external; // Required for ERC721 compliance, but will revert
    function getApproved(uint256 tokenId) external view returns (address operator); // Required for ERC721 compliance, but will return zero address
    function isApprovedForAll(address owner, address operator) external view returns (bool); // Required for ERC721 compliance, but will return false
}

/**
 * @dev Interface for an external ZK Proof Verifier contract.
 *      This contract will call an instance of this interface to verify zero-knowledge proofs.
 *      The actual implementation of the ZK Verifier is external to DAFAN.
 */
interface IZKVerifier {
    function verifyProof(bytes calldata _proof, bytes calldata _publicInputs) external view returns (bool);
}

/**
 * @dev Interface for an AI Oracle, modeled after request/fulfill patterns (e.g., Chainlink).
 *      Allows the contract to request AI-driven resolutions for foresight intents.
 */
interface IAIOracle {
    /**
     * @notice Requests an AI resolution for a given foresight intent.
     * @param _callbackAddress The address of the contract to call back (usually DAFAN).
     * @param _callbackFunction The function selector for the callback (e.g., `this.receiveOracleResolution.selector`).
     * @param _intentId The ID of the foresight intent to resolve.
     * @param _description A description for the AI to process (e.g., the intent's description).
     * @return requestId A unique identifier for the oracle request.
     */
    function requestAIResolution(
        address _callbackAddress,
        bytes4 _callbackFunction,
        uint256 _intentId,
        string calldata _description
    ) external returns (bytes32 requestId);
}

// IERC20 from OpenZeppelin is already imported.

/**
 * @title DAFAN_ForesightNetwork (Decentralized Autonomous Foresight & Action Network)
 * @author [Your Name/Alias]
 * @notice DAFAN is a decentralized protocol designed to harness collective intelligence for foresight and facilitate adaptive action.
 *         Users propose and stake on future events (Foresight Intents). Accurate predictions earn reputation and rewards,
 *         while inaccurate ones lead to stake loss and reputation reduction. The system integrates AI oracles for
 *         objective resolution and ZK-proofs for privacy-preserving predictions. A Soulbound Token (SBT) represents
 *         a user's foresight reputation, which in turn influences their ability to propose and vote on "Action Protocols"
 *         – tasks or initiatives funded by the DAO, aimed at addressing foreseen needs or opportunities.
 *
 * @dev This contract relies on external ERC20, SBT, ZK Verifier, and AI Oracle contracts.
 *      The ZK Verifier and AI Oracle functionalities are represented by interfaces and external calls.
 *      The SBT implementation is a minimal ERC721 designed to be non-transferable (see `ForesightSBT` contract below).
 */
contract DAFAN_ForesightNetwork is Ownable, Pausable {

    // --- State Variables ---

    IERC20 public immutable stakingToken;
    IForesightSBT public foresightSBT;
    IZKVerifier public zkVerifier;
    IAIOracle public aiOracle;

    uint256 public nextIntentId;
    uint256 public nextActionProtocolId;
    uint256 public minReputationForSBT = 1000; // Reputation threshold to mint an SBT
    uint256 public sbtBurnThreshold = 500; // Reputation threshold below which an SBT is burned
    uint256 public minStakeAmount = 1 ether; // Minimum stake for a foresight intent
    uint256 public minReputationForProposingAction = 5000; // Min reputation to propose Action Protocol
    uint256 public minReputationForVoting = 1000; // Min reputation to vote on Action Protocol
    uint256 public predictionGracePeriod = 1 days; // Time (in seconds) that must pass before a prediction epoch can be set

    // Mapping of user address to their foresight reputation score
    mapping(address => int256) public foresightReputation;
    // Mapping of AI Oracle request ID to the intent ID it's resolving
    mapping(bytes32 => uint256) public oracleRequestToIntent;

    // --- Structs ---

    enum IntentStatus {
        Open,                 // Actively accepting stakes
        PendingOracleResolution, // Awaiting AI oracle's response
        ResolvedCorrect,      // Prediction was accurate
        ResolvedIncorrect,    // Prediction was inaccurate
        Cancelled             // Intent was cancelled
    }

    struct ForesightIntent {
        address proposer;
        string description;
        uint256 predictionEpoch; // Target timestamp when the prediction can be resolved
        bytes32 predictionHash;   // keccak256(abi.encode(secret, outcome)) for private, or outcome for public
        uint256 totalStake;       // Total tokens staked on this intent
        bool isPrivate;           // If true, requires ZK proof for submission and subsequent reveal
        bytes32 revealedOutcome;  // Only for private predictions, set after revealPrivatePrediction
        mapping(address => uint256) stakers; // User's stake amount
        IntentStatus status;
        address[] currentStakers; // To iterate over stakers for reward distribution/reputation update
        bytes32 oracleRequestId;  // Link to oracle request if applicable
    }
    mapping(uint256 => ForesightIntent) public foresightIntents;

    enum ActionProtocolStatus {
        Proposed,  // Protocol has been proposed
        Voting,    // Actively accepting votes
        Approved,  // Approved by vote, ready for execution
        Rejected,  // Rejected by vote
        Executed,  // An executor has claimed the task and is working on it
        Completed, // Executor has submitted proof and received reward
        Cancelled  // Protocol was cancelled
    }

    struct ActionProtocol {
        address proposer;
        string description;
        uint256 reputationThreshold; // Min reputation required for execution
        uint256 rewardAmount;
        uint256 deadline;            // Voting/execution deadline
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a user has voted
        ActionProtocolStatus status;
        address executor;            // Address of the user who executes it
        bytes proofData;             // Proof of completion submitted by executor
    }
    mapping(uint256 => ActionProtocol) public actionProtocols;

    // --- Events ---

    event ForesightIntentProposed(
        uint256 indexed intentId,
        address indexed proposer,
        string description,
        uint256 predictionEpoch,
        uint256 stakeAmount,
        bool isPrivate
    );
    event StakeAddedToIntent(uint256 indexed intentId, address indexed staker, uint256 amount);
    event PrivatePredictionRevealed(uint256 indexed intentId, address indexed proposer, bytes32 revealedOutcome);
    event OracleResolutionRequested(uint256 indexed intentId, bytes32 indexed oracleRequestId);
    event ForesightIntentResolved(
        uint256 indexed intentId,
        bytes32 actualOutcomeHash,
        IntentStatus status,
        uint256 remainingStakeInPool // Total stake in the pool after resolution (0 if incorrect, original if correct)
    );
    event ForesightRewardsClaimed(uint256 indexed intentId, address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);
    event SBTIssued(address indexed user, uint256 tokenId);
    event SBTBurned(address indexed user, uint256 tokenId);
    event ActionProtocolProposed(
        uint256 indexed protocolId,
        address indexed proposer,
        string description,
        uint256 rewardAmount,
        uint256 deadline
    );
    event ActionProtocolVoted(
        uint256 indexed protocolId,
        address indexed voter,
        bool support,
        uint256 votesFor,
        uint256 votesAgainst
    );
    event ActionProtocolStatusUpdated(uint256 indexed protocolId, ActionProtocolStatus newStatus);
    event ActionProtocolExecuted(uint256 indexed protocolId, address indexed executor);
    event ActionProofSubmitted(uint256 indexed protocolId, address indexed executor);
    event ActionRewardClaimed(uint256 indexed protocolId, address indexed executor, uint256 rewardAmount);

    // --- Modifiers ---

    modifier onlyReputable(uint256 _minReputation) {
        require(foresightReputation[msg.sender] >= int256(_minReputation), "DAFAN: Not enough reputation");
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the DAFAN contract.
     * @param _stakingTokenAddress The address of the ERC20 token used for staking and rewards.
     * @param _foresightSBTAddress The address of the ForesightSBT (Soulbound Token) contract.
     * @param _zkVerifierAddress The address of the external ZK Proof Verifier contract.
     * @param _aiOracleAddress The address of the AI Oracle contract.
     */
    constructor(
        address _stakingTokenAddress,
        address _foresightSBTAddress,
        address _zkVerifierAddress,
        address _aiOracleAddress
    ) Ownable(msg.sender) Pausable() {
        require(_stakingTokenAddress != address(0), "DAFAN: Staking token address cannot be zero");
        require(_foresightSBTAddress != address(0), "DAFAN: SBT address cannot be zero");
        require(_zkVerifierAddress != address(0), "DAFAN: ZK Verifier address cannot be zero");
        require(_aiOracleAddress != address(0), "DAFAN: AI Oracle address cannot be zero");

        stakingToken = IERC20(_stakingTokenAddress);
        foresightSBT = IForesightSBT(_foresightSBTAddress);
        zkVerifier = IZKVerifier(_zkVerifierAddress);
        aiOracle = IAIOracle(_aiOracleAddress);
    }

    // --- I. Core Setup & Administration ---

    /**
     * @notice Admin function to set or update the address of the ZK proof verifier contract.
     * @param _verifier The new address for the ZK verifier contract.
     */
    function setZKVerifierAddress(address _verifier) external onlyOwner {
        require(_verifier != address(0), "DAFAN: ZK Verifier address cannot be zero");
        zkVerifier = IZKVerifier(_verifier);
    }

    /**
     * @notice Admin function to set or update the address of the AI oracle interface.
     * @param _oracle The new address for the AI oracle contract.
     */
    function setAIOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "DAFAN: AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_oracle);
    }

    /**
     * @notice Admin function to pause contract operations in emergencies.
     * @dev Uses OpenZeppelin's Pausable functionality.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Admin function to unpause contract operations.
     * @dev Uses OpenZeppelin's Pausable functionality.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Admin/DAO function to withdraw surplus tokens from the contract.
     * @dev This function allows the owner (or eventually a DAO vote) to retrieve tokens
     *      that might accumulate in the contract (e.g., from lost stakes).
     * @param _token The address of the token to withdraw.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawDAOProceeds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner { // In a full DAO, this would be behind a governance vote.
        require(_to != address(0), "DAFAN: Target address cannot be zero");
        IERC20(_token).transfer(_to, _amount);
    }

    // --- II. Foresight Intent Management ---

    /**
     * @notice Propose a new foresight intent, staking tokens on its outcome.
     * @dev The prediction can be public (direct outcome hash) or private (commitment hash + ZK proof).
     *      For private predictions, the actual outcome is revealed later.
     *      The ZK proof, if provided, must verify the proposer's commitment without revealing the outcome immediately.
     * @param _description A clear description of the foresight event.
     * @param _predictionEpoch The target timestamp when the prediction can be resolved.
     * @param _predictionHash The keccak256 hash of the predicted outcome (or commitment for private).
     * @param _stakeAmount The amount of staking tokens to commit.
     * @param _isPrivate If true, the prediction is private and requires a ZK proof.
     * @param _privateProof ZK proof bytes, required if `_isPrivate` is true. Proves knowledge of the commitment.
     */
    function proposeForesightIntent(
        string calldata _description,
        uint256 _predictionEpoch,
        bytes32 _predictionHash,
        uint256 _stakeAmount,
        bool _isPrivate,
        bytes calldata _privateProof
    ) external whenNotPaused {
        require(_stakeAmount >= minStakeAmount, "DAFAN: Stake amount too low");
        require(_predictionEpoch > block.timestamp + predictionGracePeriod, "DAFAN: Prediction epoch too soon");

        if (_isPrivate) {
            require(_privateProof.length > 0, "DAFAN: ZK proof required for private intent");
            // Public inputs for ZK proof would typically include the predictionHash and potentially the proposer's address
            require(zkVerifier.verifyProof(_privateProof, abi.encodePacked(_predictionHash, msg.sender)), "DAFAN: Invalid ZK proof for private intent");
        }

        require(stakingToken.transferFrom(msg.sender, address(this), _stakeAmount), "DAFAN: Token transfer failed");

        uint256 intentId = nextIntentId++;
        ForesightIntent storage newIntent = foresightIntents[intentId];
        newIntent.proposer = msg.sender;
        newIntent.description = _description;
        newIntent.predictionEpoch = _predictionEpoch;
        newIntent.predictionHash = _predictionHash;
        newIntent.totalStake = _stakeAmount;
        newIntent.isPrivate = _isPrivate;
        newIntent.stakers[msg.sender] = _stakeAmount;
        newIntent.currentStakers.push(msg.sender);
        newIntent.status = IntentStatus.Open;

        emit ForesightIntentProposed(intentId, msg.sender, _description, _predictionEpoch, _stakeAmount, _isPrivate);
    }

    /**
     * @notice For private predictions, the proposer reveals the secret and actual predicted outcome.
     * @dev This must be called after the prediction epoch has passed but before `resolveForesightIntent`
     *      is called, to enable verification against the original commitment.
     * @param _intentId The ID of the private foresight intent.
     * @param _secret A unique secret used in the original commitment hash (e.g., a random salt).
     * @param _actualPredictedOutcome The actual outcome that was committed to.
     */
    function revealPrivatePrediction(
        uint256 _intentId,
        bytes32 _secret,
        bytes32 _actualPredictedOutcome
    ) external whenNotPaused {
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.proposer == msg.sender, "DAFAN: Only proposer can reveal private prediction");
        require(intent.isPrivate, "DAFAN: Not a private prediction");
        require(intent.status == IntentStatus.Open || intent.status == IntentStatus.PendingOracleResolution, "DAFAN: Intent is not open for reveal");
        require(intent.revealedOutcome == bytes32(0), "DAFAN: Prediction already revealed");
        require(block.timestamp >= intent.predictionEpoch, "DAFAN: Prediction epoch not reached yet");

        // Verify that the revealed secret and outcome match the original commitment hash
        require(keccak256(abi.encode(_secret, _actualPredictedOutcome)) == intent.predictionHash, "DAFAN: Revealed outcome does not match commitment");

        intent.revealedOutcome = _actualPredictedOutcome;
        emit PrivatePredictionRevealed(_intentId, msg.sender, _actualPredictedOutcome);
    }

    /**
     * @notice Add more stake to an existing foresight intent.
     * @param _intentId The ID of the foresight intent to stake on.
     * @param _amount The amount of tokens to stake.
     */
    function stakeOnExistingIntent(uint256 _intentId, uint256 _amount) external whenNotPaused {
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.status == IntentStatus.Open, "DAFAN: Intent not open for staking");
        require(_amount > 0, "DAFAN: Stake amount must be greater than zero");
        require(block.timestamp < intent.predictionEpoch, "DAFAN: Cannot stake on expired intent");

        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "DAFAN: Token transfer failed");

        if (intent.stakers[msg.sender] == 0) {
            intent.currentStakers.push(msg.sender);
        }
        intent.stakers[msg.sender] += _amount;
        intent.totalStake += _amount;

        emit StakeAddedToIntent(_intentId, msg.sender, _amount);
    }

    /**
     * @notice Submits a request to the AI Oracle to resolve a foresight intent.
     * @dev Only callable if the intent is open and its prediction epoch has passed.
     *      Requires the AI Oracle to be set.
     * @param _intentId The ID of the foresight intent to resolve.
     * @param _oracleCallbackAddress The address of the contract to call back (usually this contract).
     * @param _oracleCallbackFunction The function selector for the callback (e.g., `this.receiveOracleResolution.selector`).
     */
    function submitOracleResolutionRequest(
        uint256 _intentId,
        address _oracleCallbackAddress,
        bytes4 _oracleCallbackFunction
    ) external whenNotPaused {
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.status == IntentStatus.Open, "DAFAN: Intent not open for oracle request");
        require(block.timestamp >= intent.predictionEpoch, "DAFAN: Prediction epoch not reached");
        require(address(aiOracle) != address(0), "DAFAN: AI Oracle not set");
        require(intent.oracleRequestId == bytes32(0), "DAFAN: Oracle request already pending or completed");

        intent.status = IntentStatus.PendingOracleResolution;
        bytes32 requestId = aiOracle.requestAIResolution(
            _oracleCallbackAddress,
            _oracleCallbackFunction,
            _intentId,
            intent.description
        );
        intent.oracleRequestId = requestId;
        oracleRequestToIntent[requestId] = _intentId;

        emit OracleResolutionRequested(_intentId, requestId);
    }

    /**
     * @notice Callback function from the AI Oracle to deliver resolution for a foresight intent.
     * @dev This function should only be callable by the designated AI Oracle contract.
     * @param _oracleRequestId The ID of the oracle request.
     * @param _resolvedOutcomeHash The keccak256 hash of the outcome as determined by the AI Oracle.
     */
    function receiveOracleResolution(
        bytes32 _oracleRequestId,
        bytes32 _resolvedOutcomeHash
    ) external whenNotPaused {
        require(msg.sender == address(aiOracle), "DAFAN: Only AI Oracle can call this function");
        uint256 intentId = oracleRequestToIntent[_oracleRequestId];
        ForesightIntent storage intent = foresightIntents[intentId];

        require(intent.status == IntentStatus.PendingOracleResolution, "DAFAN: Intent not awaiting oracle resolution");
        require(intent.oracleRequestId == _oracleRequestId, "DAFAN: Oracle request ID mismatch");

        // Now proceed to resolve the intent based on the oracle's input
        _resolveForesightIntent(intentId, _resolvedOutcomeHash);

        delete oracleRequestToIntent[_oracleRequestId]; // Clean up mapping
    }

    /**
     * @notice Manually resolve a foresight intent if its outcome is clear or decided by DAO.
     * @dev Only callable by owner (or via DAO vote if implemented). For private predictions,
     *      the `revealPrivatePrediction` must have been called first.
     * @param _intentId The ID of the foresight intent to resolve.
     * @param _actualOutcomeHash The keccak256 hash of the actual outcome.
     */
    function resolveForesightIntent(
        uint256 _intentId,
        bytes32 _actualOutcomeHash
    ) external onlyOwner whenNotPaused { // In a full DAO, this would be behind a governance vote.
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.status == IntentStatus.Open, "DAFAN: Intent not open for manual resolution");
        require(block.timestamp >= intent.predictionEpoch, "DAFAN: Prediction epoch not reached");
        require(intent.oracleRequestId == bytes32(0), "DAFAN: Intent awaiting oracle resolution, use receiveOracleResolution");

        _resolveForesightIntent(_intentId, _actualOutcomeHash);
    }

    /**
     * @dev Internal function to handle the core logic of resolving a foresight intent.
     *      Updates reputations and adjusts funds based on prediction accuracy.
     * @param _intentId The ID of the foresight intent.
     * @param _actualOutcomeHash The keccak256 hash of the actual outcome.
     */
    function _resolveForesightIntent(uint256 _intentId, bytes32 _actualOutcomeHash) internal {
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.status != IntentStatus.ResolvedCorrect && intent.status != IntentStatus.ResolvedIncorrect && intent.status != IntentStatus.Cancelled, "DAFAN: Intent already resolved or cancelled");

        bytes32 comparablePredictionHash = intent.predictionHash;
        if (intent.isPrivate) {
            require(intent.revealedOutcome != bytes32(0), "DAFAN: Private prediction not revealed yet");
            comparablePredictionHash = intent.revealedOutcome; // Compare with the revealed outcome for private predictions
        }

        bool isCorrectOutcome = (comparablePredictionHash == _actualOutcomeHash);
        intent.status = isCorrectOutcome ? IntentStatus.ResolvedCorrect : IntentStatus.ResolvedIncorrect;

        uint256 finalRemainingStake = 0; // The total stake left in the pool for correct stakers to claim

        if (isCorrectOutcome) {
            for (uint256 i = 0; i < intent.currentStakers.length; i++) {
                address staker = intent.currentStakers[i];
                uint256 stakeAmount = intent.stakers[staker];
                _updateForesightReputation(staker, int256(stakeAmount / 100)); // Example: +1 reputation for every 100 tokens staked
                // `intent.stakers[staker]` still holds their stake, which they can claim later.
            }
            finalRemainingStake = intent.totalStake;
        } else { // Prediction was incorrect
            // All staked tokens are implicitly "lost" to the protocol/DAO treasury.
            // Individual stakes are marked as 0 so they cannot be claimed.
            for (uint256 i = 0; i < intent.currentStakers.length; i++) {
                address staker = intent.currentStakers[i];
                uint256 stakeAmount = intent.stakers[staker];
                _updateForesightReputation(staker, -int256(stakeAmount / 50)); // Example: -1 reputation for every 50 tokens lost
                intent.stakers[staker] = 0; // Staked tokens are forfeited.
            }
            intent.totalStake = 0; // All stake is now considered 'lost' to the protocol/DAO.
            finalRemainingStake = 0;
        }

        emit ForesightIntentResolved(_intentId, _actualOutcomeHash, intent.status, finalRemainingStake);
    }

    /**
     * @notice Allows a user to claim their rewards from a correctly resolved foresight intent.
     * @param _intentId The ID of the foresight intent.
     */
    function claimForesightRewards(uint256 _intentId) external whenNotPaused {
        ForesightIntent storage intent = foresightIntents[_intentId];
        require(intent.status == IntentStatus.ResolvedCorrect, "DAFAN: Intent not resolved correctly");

        uint256 rewardAmount = intent.stakers[msg.sender];
        require(rewardAmount > 0, "DAFAN: No rewards to claim or already claimed");

        intent.stakers[msg.sender] = 0; // Clear claimed amount
        require(stakingToken.transfer(msg.sender, rewardAmount), "DAFAN: Reward transfer failed");

        emit ForesightRewardsClaimed(_intentId, msg.sender, rewardAmount);
    }

    // --- III. Reputation & Soulbound Token (SBT) Management ---

    /**
     * @notice Retrieves a user's current foresight reputation score.
     * @param _user The address of the user.
     * @return The integer reputation score.
     */
    function getForesightReputation(address _user) external view returns (int256) {
        return foresightReputation[_user];
    }

    /**
     * @dev Internal function to update a user's foresight reputation score.
     *      Checks for SBT issuance/burning thresholds.
     * @param _user The address of the user whose reputation is being updated.
     * @param _change The amount to change the reputation by (can be positive or negative).
     */
    function _updateForesightReputation(address _user, int256 _change) internal {
        int256 currentRep = foresightReputation[_user];
        int256 newRep = currentRep + _change;
        if (newRep < 0) newRep = 0; // Reputation cannot go below zero.

        foresightReputation[_user] = newRep;
        emit ReputationUpdated(_user, currentRep, newRep);

        // Check SBT thresholds
        // Only mint if they don't have one AND crossed the threshold
        if (currentRep < int256(minReputationForSBT) && newRep >= int256(minReputationForSBT)) {
            if (foresightSBT.balanceOf(_user) == 0) {
                foresightSBT.mint(_user, uint256(uint160(_user))); // Use address as token ID for simplicity
                emit SBTIssued(_user, uint256(uint160(_user)));
            }
        }
        // Only burn if they have one AND fell below the threshold
        else if (currentRep >= int256(sbtBurnThreshold) && newRep < int256(sbtBurnThreshold)) {
            if (foresightSBT.balanceOf(_user) > 0) {
                foresightSBT.burn(foresightSBT.getTokenId(_user));
                emit SBTBurned(_user, foresightSBT.getTokenId(_user));
            }
        }
    }

    /**
     * @notice Mints a non-transferable SBT for a user if they meet the minimum reputation threshold.
     * @dev Callable by anyone, but will only succeed if the user meets criteria.
     * @param _user The address of the user to issue the SBT to.
     */
    function issueForesightSBT(address _user) external whenNotPaused {
        require(foresightReputation[_user] >= int256(minReputationForSBT), "DAFAN: User does not meet reputation threshold");
        require(foresightSBT.balanceOf(_user) == 0, "DAFAN: User already has an SBT");

        foresightSBT.mint(_user, uint256(uint160(_user))); // Using address as token ID
        emit SBTIssued(_user, uint256(uint160(_user)));
    }

    /**
     * @notice Burns a user's SBT if their reputation drops below the burn threshold.
     * @dev Can be called by the user themselves or by the owner/DAO.
     * @param _user The address of the user whose SBT should be burned.
     */
    function burnForesightSBT(address _user) external whenNotPaused {
        require(foresightSBT.balanceOf(_user) > 0, "DAFAN: User does not have an SBT");
        require(foresightReputation[_user] < int256(sbtBurnThreshold), "DAFAN: User's reputation is above burn threshold");

        foresightSBT.burn(foresightSBT.getTokenId(_user));
        emit SBTBurned(_user, foresightSBT.getTokenId(_user));
    }

    // --- IV. Action Protocol Management (DAO-like) ---

    /**
     * @notice Proposes a new Action Protocol (task/initiative) for the DAO.
     * @dev Requires the proposer to have a minimum reputation score.
     * @param _description A detailed description of the action protocol.
     * @param _reputationThreshold The minimum reputation required for a user to execute this protocol.
     * @param _rewardAmount The reward for successfully completing this protocol.
     * @param _deadline The timestamp when voting/execution should end.
     */
    function proposeActionProtocol(
        string calldata _description,
        uint256 _reputationThreshold,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external onlyReputable(minReputationForProposingAction) whenNotPaused {
        require(_rewardAmount > 0, "DAFAN: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "DAFAN: Deadline must be in the future");
        require(stakingToken.balanceOf(address(this)) >= _rewardAmount, "DAFAN: Not enough tokens in contract for reward");

        uint256 protocolId = nextActionProtocolId++;
        ActionProtocol storage newProtocol = actionProtocols[protocolId];
        newProtocol.proposer = msg.sender;
        newProtocol.description = _description;
        newProtocol.reputationThreshold = _reputationThreshold;
        newProtocol.rewardAmount = _rewardAmount;
        newProtocol.deadline = _deadline;
        newProtocol.status = ActionProtocolStatus.Voting;

        emit ActionProtocolProposed(protocolId, msg.sender, _description, _rewardAmount, _deadline);
    }

    /**
     * @notice Allows users to vote on a proposed Action Protocol.
     * @dev Reputation-weighted voting could be implemented here (e.g., vote weight = reputation / X).
     *      For simplicity, it's currently 1 vote per reputable user.
     *      Automatically updates protocol status if deadline reached during a vote.
     * @param _protocolId The ID of the action protocol to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnActionProtocol(uint256 _protocolId, bool _support) external onlyReputable(minReputationForVoting) whenNotPaused {
        ActionProtocol storage protocol = actionProtocols[_protocolId];
        require(protocol.status == ActionProtocolStatus.Voting, "DAFAN: Action Protocol not in voting phase");
        require(block.timestamp <= protocol.deadline, "DAFAN: Voting period has ended");
        require(!protocol.hasVoted[msg.sender], "DAFAN: Already voted on this protocol");

        protocol.hasVoted[msg.sender] = true;
        if (_support) {
            protocol.totalVotesFor++;
        } else {
            protocol.totalVotesAgainst++;
        }

        emit ActionProtocolVoted(_protocolId, msg.sender, _support, protocol.totalVotesFor, protocol.totalVotesAgainst);

        // If deadline is met (or passed with this vote), transition status
        if (block.timestamp >= protocol.deadline) {
            if (protocol.totalVotesFor > protocol.totalVotesAgainst) {
                protocol.status = ActionProtocolStatus.Approved;
            } else {
                protocol.status = ActionProtocolStatus.Rejected;
            }
            emit ActionProtocolStatusUpdated(_protocolId, protocol.status);
        }
    }

    /**
     * @notice Allows a user with sufficient reputation to execute an approved Action Protocol.
     * @dev This function signifies claiming responsibility for the task. Actual completion and reward
     *      claim will happen in `submitActionProofAndClaim` and `verifyActionProofAndReward`.
     * @param _protocolId The ID of the action protocol to execute.
     */
    function executeActionProtocol(uint256 _protocolId) external whenNotPaused {
        ActionProtocol storage protocol = actionProtocols[_protocolId];
        require(protocol.status == ActionProtocolStatus.Approved, "DAFAN: Action Protocol not approved");
        require(protocol.executor == address(0), "DAFAN: Action Protocol already assigned an executor");
        require(foresightReputation[msg.sender] >= int256(protocol.reputationThreshold), "DAFAN: Not enough reputation to execute this protocol");
        require(block.timestamp <= protocol.deadline, "DAFAN: Execution deadline has passed");

        protocol.executor = msg.sender;
        protocol.status = ActionProtocolStatus.Executed; // Status moves to Executed, awaiting proof
        emit ActionProtocolExecuted(_protocolId, msg.sender);
        emit ActionProtocolStatusUpdated(_protocolId, protocol.status);
    }

    /**
     * @notice Allows the assigned executor to submit proof of completion for an Action Protocol.
     * @dev The `_proofData` can be a hash of off-chain work, a link, or a ZK proof of computation.
     * @param _protocolId The ID of the action protocol.
     * @param _proofData Arbitrary bytes data representing proof of completion.
     */
    function submitActionProofAndClaim(uint256 _protocolId, bytes calldata _proofData) external whenNotPaused {
        ActionProtocol storage protocol = actionProtocols[_protocolId];
        require(protocol.status == ActionProtocolStatus.Executed, "DAFAN: Action Protocol not in execution phase");
        require(protocol.executor == msg.sender, "DAFAN: Only the assigned executor can submit proof");
        require(_proofData.length > 0, "DAFAN: Proof data cannot be empty");

        protocol.proofData = _proofData;
        emit ActionProofSubmitted(_protocolId, msg.sender);
    }

    /**
     * @notice Admin/DAO function to verify the submitted proof and release the reward for an Action Protocol.
     * @dev This requires manual review of `_proofData` or integration with a decentralized verification system.
     *      Updates the executor's reputation upon successful verification.
     * @param _protocolId The ID of the action protocol.
     * @param _executor The address of the executor who submitted the proof.
     */
    function verifyActionProofAndReward(uint256 _protocolId, address _executor) external onlyOwner whenNotPaused { // In a full DAO, this would be behind a governance vote.
        ActionProtocol storage protocol = actionProtocols[_protocolId];
        require(protocol.status == ActionProtocolStatus.Executed, "DAFAN: Action Protocol not in execution phase");
        require(protocol.executor == _executor, "DAFAN: Executor mismatch");
        require(protocol.proofData.length > 0, "DAFAN: No proof submitted yet");

        // Here, external verification logic for `_proofData` would be integrated.
        // For this contract, we assume `owner` makes the decision after reviewing `_proofData`.

        require(stakingToken.transfer(_executor, protocol.rewardAmount), "DAFAN: Reward transfer failed");

        protocol.status = ActionProtocolStatus.Completed;
        emit ActionProtocolRewardClaimed(_protocolId, _executor, protocol.rewardAmount);
        emit ActionProtocolStatusUpdated(_protocolId, protocol.status);

        _updateForesightReputation(_executor, int256(protocol.rewardAmount / 50)); // Example: Reputation boost for completing task
    }

    // --- V. ZK Proof Verification (External Stub) ---

    /**
     * @notice Placeholder for calling an external ZK Verifier contract.
     * @dev This function merely forwards the call to the configured `zkVerifier` address.
     *      The actual verification logic resides in the `IZKVerifier` contract.
     *      It is exposed externally for direct calls if needed, but primarily used internally.
     * @param _proof The raw ZK proof bytes.
     * @param _publicInputs The public inputs for the ZK proof.
     * @return True if the proof is valid, false otherwise.
     */
    function verifyZKProof(bytes calldata _proof, bytes calldata _publicInputs) external view returns (bool) {
        return zkVerifier.verifyProof(_proof, _publicInputs);
    }
}


/**
 * @title ForesightSBT
 * @notice A simplified, non-transferable ERC721-like contract for Soulbound Tokens.
 * @dev This implementation focuses on the core "soulbound" aspect (non-transferability)
 *      and minimal ERC721 compatibility for DAFAN's reputation system.
 *      It does not include full ERC721Enumerable or ERC721Metadata for brevity.
 */
contract ForesightSBT is IForesightSBT, Ownable {
    mapping(uint256 => address) private _owners;       // Token ID to owner address
    mapping(address => uint256) private _balances;     // Owner address to number of tokens (max 1 for SBT)
    mapping(address => uint256) private _userTokenId;  // Maps user address to their single SBT tokenId

    // ERC721 Standard Events (simplified for non-transferability)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    constructor() Ownable(msg.sender) {}

    /**
     * @notice Mints a new SBT for an address. Callable only by the contract owner (DAFAN).
     * @param to The address to mint the SBT to.
     * @param tokenId The ID of the token to mint.
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        require(to != address(0), "ForesightSBT: mint to the zero address");
        require(_owners[tokenId] == address(0), "ForesightSBT: token already minted");
        require(_userTokenId[to] == 0, "ForesightSBT: user already has an SBT");

        _owners[tokenId] = to;
        _balances[to]++;
        _userTokenId[to] = tokenId;
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Burns an existing SBT. Callable only by the contract owner (DAFAN).
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) external onlyOwner {
        address owner = _owners[tokenId];
        require(owner != address(0), "ForesightSBT: token does not exist");

        _balances[owner]--;
        delete _owners[tokenId];
        delete _userTokenId[owner];
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @notice Returns the number of tokens owned by `owner`. For this SBT, it's 0 or 1.
     * @param owner The address to query the balance of.
     * @return The number of tokens owned by `owner`.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @notice Returns the owner of the `tokenId` token.
     * @param tokenId The ID of the token to query the owner of.
     * @return The owner of the token.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ForesightSBT: owner query for nonexistent token");
        return _owners[tokenId];
    }

    /**
     * @notice Returns the tokenId owned by `owner`. Assumes a maximum of 1 SBT per user.
     * @param owner The address to query the token ID of.
     * @return The token ID owned by `owner`. Returns 0 if no SBT is held.
     */
    function getTokenId(address owner) public view override returns (uint256) {
        return _userTokenId[owner];
    }

    // --- Non-transferable ERC721 overrides ---
    // These functions are implemented to revert, enforcing the soulbound nature.

    function transferFrom(address, address, uint256) public pure override {
        revert("ForesightSBT: Tokens are soulbound and non-transferable");
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert("ForesightSBT: Tokens are soulbound and non-transferable");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
        revert("ForesightSBT: Tokens are soulbound and non-transferable");
    }

    function approve(address, uint256) public pure override {
        revert("ForesightSBT: Tokens are soulbound and non-transferable");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("ForesightSBT: Tokens are soulbound and non-transferable");
    }

    function getApproved(uint256) public pure override returns (address) {
        // As tokens are non-transferable, approval mechanism is irrelevant.
        return address(0);
    }

    function isApprovedForAll(address, address) public pure override returns (bool) {
        // As tokens are non-transferable, approval mechanism is irrelevant.
        return false;
    }
}
```