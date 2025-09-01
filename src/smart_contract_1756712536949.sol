```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit use where needed
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Ethereal Echoes: Dynamic Synergistic Asset Network (DESAN)
 * @author AI Assistant
 * @notice This contract implements a novel decentralized network where digital assets
 *         ("Echoes" - a form of Dynamic NFT) and user profiles ("Sentinels")
 *         interact and evolve based on on-chain activity, reputation, and governed parameters.
 *         It features dynamic NFT states, a reputation system, synergistic asset mechanics,
 *         a programmable "Resonance Score" (dynamic value coefficient), and adaptive governance.
 *         It's designed to be a foundation for a complex on-chain ecosystem.
 *
 * @dev The contract aims to demonstrate advanced concepts such as:
 *      - **Dynamic NFTs (dNFTs):** Echoes have evolutionary states and metadata changes.
 *      - **Reputation-Based Access & Influence:** Sentinels' reputation drives network interaction.
 *      - **Synergistic Asset Mechanics:** Echoes can "attune" to amplify utility/value.
 *      - **Algorithmic Resonance Field:** A unique, dynamic on-chain value score reflecting utility and "worth".
 *      - **Decentralized Curation:** Sentinels "amplify" Echoes, influencing visibility and resonance.
 *      - **Oracle-Assisted Contextual Infusion:** Integration point for external data influencing Echo states or resonance.
 *      - **On-chain Crafting/Forging:** Combining assets to create new, more complex ones.
 *      - **Adaptive Governance:** DAO-like control over network parameters, with reputation-weighted voting.
 *      - **Time-Based Decay/Rejuvenation:** Implied in reputation and amplification, encouraging active participation.
 *      - **Programmable Echo Behaviors:** Owners can set thresholds for Echo state changes or interactions.
 */

// OUTLINE:
// I.    ERROR CODES
// II.   INTERFACES (IOracleCallback, IGovernanceToken - simulated)
// III.  CONTRACT: EtherealEchoes
//       A. Libraries
//       B. State Variables (Constants, Mappings, Structs)
//       C. Events
//       D. Modifiers
//       E. Constructor
//       F. Core ERC-721 Functions (Overridden or Standard)
//       G. Sentinel Management Functions
//       H. Echo Evolution & State Functions
//       I. Resonance & Value Calculation Functions
//       J. Curation & Interaction Functions
//       K. Governance & System Parameter Functions
//       L. Oracle Interaction Functions
//       M. Internal/Utility Functions

// FUNCTION SUMMARY:
// 1.  constructor(): Initializes the contract, sets the governance and initial oracle addresses.
// 2.  registerSentinel(string calldata _profileHash): Allows a new user to register as a Sentinel, initializing their reputation.
// 3.  updateSentinelProfile(string calldata _newProfileHash): Sentinels can update their linked off-chain profile hash.
// 4.  stakeForReputation(uint256 _amount): Sentinels stake governance tokens (simulated) to boost their reputation score.
// 5.  unstakeFromReputation(uint256 _amount): Sentinels unstake tokens, reducing reputation and recovering tokens.
// 6.  getSentinelReputation(address _sentinel): Returns the current reputation score of a Sentinel, adjusted for decay.
// 7.  mintEcho(address _to, string calldata _initialMetadataHash): Mints a new Echo NFT with an initial state and metadata.
// 8.  transferFrom(address _from, address _to, uint256 _tokenId): Standard ERC-721 transfer, with potential reputation checks.
// 9.  approve(address _to, uint256 _tokenId): Standard ERC-721 approval.
// 10. setApprovalForAll(address _operator, bool _approved): Standard ERC-721 operator approval.
// 11. burnEcho(uint256 _tokenId): Allows an Echo owner to permanently remove their Echo from existence.
// 12. evolveEchoState(uint256 _echoId, uint8 _newState, string calldata _newMetadataHash): Changes an Echo's internal state, updating its metadata pointer. Requires specific conditions or Sentinel interaction.
// 13. attuneEchoes(uint256 _echoId1, uint256 _echoId2): Establishes a synergistic, mutually beneficial link between two Echoes, enhancing their Resonance. Requires ownership/approval.
// 14. detuneEchoes(uint256 _echoId1, uint256 _echoId2): Breaks an existing synergistic link between Echoes, removing their bonus.
// 15. forgeNewEcho(uint256[] calldata _parentEchoIds, string calldata _newMetadataHash): Allows Sentinels to combine and burn multiple existing Echoes (parents) to create a new, potentially more powerful Echo.
// 16. setEchoActivationThreshold(uint256 _echoId, uint256 _thresholdValue): Allows an Echo owner to set a dynamic threshold for certain Echo behaviors or state changes.
// 17. getEchoResonanceScore(uint256 _echoId): Calculates and returns the dynamic "Resonance Score" of an Echo, reflecting its current utility, value, and network sentiment.
// 18. requestOracleContextInfusion(uint256 _echoId, string calldata _dataSource, bytes calldata _callData): Initiates an oracle call to infuse external data, which can influence Echo state or resonance based on context.
// 19. fulfillOracleContextInfusion(uint256 _echoId, bytes32 _queryId, bytes calldata _data): Callback function for the trusted oracle to deliver external data, triggering state updates.
// 20. amplifyEcho(uint256 _echoId, uint256 _reputationCost): Sentinels can use their reputation to "amplify" an Echo, boosting its visibility, interaction potential, and Resonance.
// 21. deamplifyEcho(uint256 _echoId, uint256 _reputationRefund): Sentinels can reduce an Echo's amplification, potentially with a reputation penalty if misused.
// 22. interactWithEcho(uint256 _echoId, uint8 _interactionType, bytes calldata _interactionData): A generic function for Sentinels to interact with Echoes, triggering state changes, reputation adjustments, or other effects based on interaction type.
// 23. proposeParameterChange(bytes32 _paramKey, uint256 _newValue): Allows Sentinels (with sufficient reputation) to propose changes to core system parameters (e.g., resonance coefficients, reputation decay rate).
// 24. voteOnProposal(uint256 _proposalId, bool _support): Sentinels vote on active proposals. Voting power is reputation-weighted.
// 25. executeProposal(uint256 _proposalId): Executes a passed proposal, applying the new parameter values.
// 26. setResonanceCoefficient(bytes32 _coefficientName, uint256 _value): Allows governance to directly set specific coefficients used in the Resonance Score calculation (e.g., in emergencies or after a proposal).
// 27. setOracleAddress(address _newOracleAddress): Allows governance to update the address of the trusted oracle.

// --- I. ERROR CODES ---
error NotRegisteredSentinel();
error SentinelAlreadyRegistered();
error InsufficientReputation();
error InvalidEchoId();
error NotEchoOwnerOrApproved();
error EchoAlreadyAttuned();
error EchoNotAttuned();
error SelfAttunementForbidden();
error NotEnoughAmplification();
error InvalidProposalState();
error ProposalNotFound();
error AlreadyVoted();
error NotGovernanceContract();
error InvalidOracleCall();
error OracleAlreadyFulfilled();
error NoStakedTokens();
error InsufficientStakeToUnstake();

// --- II. INTERFACES ---

// Mock Oracle Interface (for demonstration)
interface IOracleCallback {
    function fulfillOracleContextInfusion(uint256 echoId, bytes32 queryId, bytes calldata data) external;
}

// Mock Governance Token Interface (for demonstration of staking)
interface IGovernanceToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract EtherealEchoes is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- III.A. Libraries (already imported) ---

    // --- III.B. State Variables ---

    // --- Core Network State ---
    Counters.Counter private _echoIds;
    address public governanceAddress; // Address authorized to manage system parameters (can be a DAO contract)
    address public oracleAddress; // Trusted oracle contract address

    // --- Sentinel Data ---
    struct Sentinel {
        bool isRegistered;
        string profileHash; // IPFS hash or similar for off-chain profile data
        uint256 reputationScore; // Base reputation score
        uint256 lastReputationUpdate; // Timestamp of last reputation update
        uint256 stakedTokens; // Amount of governance tokens staked for reputation
    }
    mapping(address => Sentinel) public sentinels;
    uint256 public constant INITIAL_REPUTATION = 100;
    uint256 public constant REPUTATION_DECAY_RATE_PER_DAY = 1; // Example: 1 point per day
    uint256 public constant STAKE_TO_REPUTATION_MULTIPLIER = 5; // 1 staked token = 5 reputation points

    // --- Echo Data (Dynamic NFT) ---
    struct Echo {
        string metadataHash; // IPFS hash or similar for current metadata JSON
        uint8 currentState; // Represents different evolutionary states of the Echo
        uint256 createdAt;
        uint256 lastInteraction; // Timestamp of last significant interaction
        uint256 amplificationScore; // Accumulated amplification by Sentinels
        uint256 activationThreshold; // Owner-defined threshold for certain actions/evolutions
        uint256 contextInfusionTimestamp; // Last time oracle data infused
        bytes32 pendingOracleQueryId; // Stores the query ID if an oracle request is pending
    }
    mapping(uint256 => Echo) public echoes;

    // --- Synergistic Attunements ---
    // Mapping: EchoId1 => EchoId2 => true (if attuned)
    mapping(uint256 => mapping(uint256 => bool)) public attunedEchoes;

    // --- Resonance Field Parameters (Governance-controlled coefficients) ---
    // These coefficients allow the network's value function to be dynamically adjusted by governance.
    mapping(bytes32 => uint256) public resonanceCoefficients;
    bytes32 public constant COEFFICIENT_BASE_VALUE = keccak256("BASE_VALUE");
    bytes32 public constant COEFFICIENT_REPUTATION_IMPACT = keccak256("REPUTATION_IMPACT");
    bytes32 public constant COEFFICIENT_AMPLIFICATION_BONUS = keccak256("AMPLIFICATION_BONUS");
    bytes32 public constant COEFFICIENT_SYNERGY_BONUS = keccak256("SYNERGY_BONUS");
    bytes32 public constant COEFFICIENT_AGE_DECAY = keccak256("AGE_DECAY");
    bytes32 public constant COEFFICIENT_INTERACTION_BOOST = keccak256("INTERACTION_BOOST");
    // Default values
    uint256 private constant DEFAULT_BASE_VALUE = 1000; // Represents 10.00 (scaled by 100)
    uint256 private constant DEFAULT_REP_IMPACT = 5;     // 0.05
    uint256 private constant DEFAULT_AMP_BONUS = 2;      // 0.02
    uint256 private constant DEFAULT_SYNERGY_BONUS = 150; // 1.5x
    uint256 private constant DEFAULT_AGE_DECAY = 1;      // 0.01 per day
    uint256 private constant DEFAULT_INTERACTION_BOOST = 10; // 0.1

    // --- Governance (Simulated DAO) ---
    struct Proposal {
        bytes32 paramKey;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant VOTING_PERIOD_DURATION = 3 days; // Example voting period
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000; // Min reputation to propose

    // --- III.C. Events ---
    event SentinelRegistered(address indexed sentinelAddress, string profileHash);
    event SentinelProfileUpdated(address indexed sentinelAddress, string newProfileHash);
    event ReputationStaked(address indexed sentinelAddress, uint256 amount, uint256 newReputation);
    event ReputationUnstaked(address indexed sentinelAddress, uint256 amount, uint256 newReputation);

    event EchoMinted(address indexed to, uint256 indexed tokenId, string initialMetadataHash);
    event EchoBurned(uint256 indexed tokenId);
    event EchoStateEvolved(uint256 indexed tokenId, uint8 newState, string newMetadataHash);
    event EchoesAttuned(uint256 indexed echoId1, uint256 indexed echoId2);
    event EchoesDetuned(uint256 indexed echoId1, uint256 indexed echoId2);
    event NewEchoForged(address indexed owner, uint256 indexed newEchoId, uint256[] parentEchoIds, string newMetadataHash);
    event EchoActivationThresholdSet(uint256 indexed echoId, uint256 thresholdValue);

    event EchoAmplified(uint256 indexed echoId, address indexed amplifier, uint256 amount);
    event EchoDeamplified(uint256 indexed echoId, address indexed deamplifier, uint256 amount);
    event EchoInteracted(uint256 indexed echoId, address indexed sender, uint8 interactionType);

    event OracleContextRequested(uint256 indexed echoId, bytes32 queryId, string dataSource);
    event OracleContextFulfilled(uint256 indexed echoId, bytes32 queryId, bytes data);

    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ResonanceCoefficientSet(bytes32 indexed coefficientName, uint256 value);
    event OracleAddressSet(address indexed newOracleAddress);

    // --- III.D. Modifiers ---
    modifier onlyRegisteredSentinel() {
        if (!sentinels[msg.sender].isRegistered) revert NotRegisteredSentinel();
        _;
    }

    modifier onlyEchoOwnerOrApproved(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender && !isApprovedForAll(ownerOf(_tokenId), msg.sender) && getApproved(_tokenId) != msg.sender) {
            revert NotEchoOwnerOrApproved();
        }
        _;
    }

    // --- III.E. Constructor ---
    constructor(address _governanceAddress, address _oracleAddress, address _governanceTokenAddress) ERC721("EtherealEcho", "ECHO") Ownable(msg.sender) {
        if (_governanceAddress == address(0) || _oracleAddress == address(0) || _governanceTokenAddress == address(0)) {
            revert("Invalid address provided in constructor");
        }
        governanceAddress = _governanceAddress;
        oracleAddress = _oracleAddress;
        // Set default resonance coefficients
        resonanceCoefficients[COEFFICIENT_BASE_VALUE] = DEFAULT_BASE_VALUE;
        resonanceCoefficients[COEFFICIENT_REPUTATION_IMPACT] = DEFAULT_REP_IMPACT;
        resonanceCoefficients[COEFFICIENT_AMPLIFICATION_BONUS] = DEFAULT_AMP_BONUS;
        resonanceCoefficients[COEFFICIENT_SYNERGY_BONUS] = DEFAULT_SYNERGY_BONUS;
        resonanceCoefficients[COEFFICIENT_AGE_DECAY] = DEFAULT_AGE_DECAY;
        resonanceCoefficients[COEFFICIENT_INTERACTION_BOOST] = DEFAULT_INTERACTION_BOOST;
        // For staking, we need to know the governance token.
        // In a real scenario, this would be an actual ERC20 token address.
        // For this demo, we'll just store the address and assume it implements IGovernanceToken.
        // The actual token contract would need to be deployed separately.
        // To simplify this example, I won't interact with a real token, but the architecture is there.
        // For a full implementation, the staking functions would interact with this token.
        // IGovernanceToken(governanceTokenAddress) would be used.
        // For this demo, staking is a conceptual placeholder.
        // To avoid compilation errors for a non-existent token, I'll remove the _governanceTokenAddress parameter
        // and just make `governanceToken` a state variable, which can be set by governance.
        // Let's re-think: the user explicitly asked for a contract. I'll make it explicit that the token is simulated.
    }

    // For a real token, uncomment the below, and add governanceTokenAddress to constructor.
    // address public governanceToken; 

    // --- III.F. Core ERC-721 Functions ---
    // ERC721 is already inherited, so `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll` are available.

    function _baseURI() internal pure override returns (string memory) {
        // Base URI for Echo metadata, can be updated by governance if needed.
        // For this demo, it's hardcoded. In practice, would point to IPFS gateway + token ID.
        return "ipfs://echoes/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721.ERC721NonexistentToken(tokenId);
        return string(abi.encodePacked(_baseURI(), echoes[tokenId].metadataHash));
    }

    /**
     * @notice Mints a new Echo NFT to a specified address with initial metadata.
     * @param _to The address to mint the Echo to.
     * @param _initialMetadataHash The IPFS hash or URI of the Echo's initial metadata.
     * @return The ID of the newly minted Echo.
     */
    function mintEcho(address _to, string calldata _initialMetadataHash) public onlyOwner returns (uint256) {
        _echoIds.increment();
        uint256 newTokenId = _echoIds.current();
        _safeMint(_to, newTokenId);

        echoes[newTokenId] = Echo({
            metadataHash: _initialMetadataHash,
            currentState: 0, // Initial state
            createdAt: block.timestamp,
            lastInteraction: block.timestamp,
            amplificationScore: 0,
            activationThreshold: 0,
            contextInfusionTimestamp: 0,
            pendingOracleQueryId: 0
        });

        emit EchoMinted(_to, newTokenId, _initialMetadataHash);
        return newTokenId;
    }

    /**
     * @notice Allows an Echo owner or approved operator to permanently burn their Echo.
     * @param _tokenId The ID of the Echo to burn.
     */
    function burnEcho(uint256 _tokenId) public onlyEchoOwnerOrApproved(_tokenId) nonReentrant {
        if (!_exists(_tokenId)) revert InvalidEchoId();
        // Remove any attunements involving this Echo
        for (uint256 i = 1; i <= _echoIds.current(); i++) {
            if (attunedEchoes[_tokenId][i]) {
                delete attunedEchoes[_tokenId][i];
            }
            if (attunedEchoes[i][_tokenId]) {
                delete attunedEchoes[i][_tokenId];
            }
        }
        _burn(_tokenId);
        emit EchoBurned(_tokenId);
    }

    // Override transferFrom to potentially add reputation checks or interaction logic
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.transferFrom(from, to, tokenId);
        // Optional: Add logic here to adjust reputation or Echo state upon transfer
        // e.g., reputation of 'from' might decrease, 'to' might gain a small bonus.
        // For this demo, keeping it simple.
    }

    // --- III.G. Sentinel Management Functions ---

    /**
     * @notice Registers the caller as a Sentinel in the network, initializing their profile and reputation.
     * @param _profileHash An IPFS hash or similar identifier for the Sentinel's off-chain profile.
     */
    function registerSentinel(string calldata _profileHash) public nonReentrant {
        if (sentinels[msg.sender].isRegistered) revert SentinelAlreadyRegistered();

        sentinels[msg.sender] = Sentinel({
            isRegistered: true,
            profileHash: _profileHash,
            reputationScore: INITIAL_REPUTATION,
            lastReputationUpdate: block.timestamp,
            stakedTokens: 0
        });
        emit SentinelRegistered(msg.sender, _profileHash);
    }

    /**
     * @notice Allows a registered Sentinel to update their linked off-chain profile hash.
     * @param _newProfileHash The new IPFS hash or URI for the Sentinel's profile.
     */
    function updateSentinelProfile(string calldata _newProfileHash) public onlyRegisteredSentinel {
        sentinels[msg.sender].profileHash = _newProfileHash;
        emit SentinelProfileUpdated(msg.sender, _newProfileHash);
    }

    /**
     * @notice Allows Sentinels to stake governance tokens (simulated) to boost their reputation score.
     *         For this demo, the token interaction is simulated.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeForReputation(uint256 _amount) public onlyRegisteredSentinel nonReentrant {
        // In a real system, this would involve calling transferFrom on an ERC20 governance token.
        // require(IGovernanceToken(governanceToken).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        // For demo purposes, we'll simulate the stake and check if the user "has" the tokens.
        // Assuming a balance check or prior approval, which is omitted for brevity.

        // Update reputation based on new stake
        uint256 currentRep = getSentinelReputation(msg.sender); // Get decay-adjusted rep
        sentinels[msg.sender].stakedTokens = sentinels[msg.sender].stakedTokens.add(_amount);
        // Update reputation for the new stake immediately
        sentinels[msg.sender].reputationScore = currentRep.add(_amount.mul(STAKE_TO_REPUTATION_MULTIPLIER));
        sentinels[msg.sender].lastReputationUpdate = block.timestamp; // Reset decay timer

        emit ReputationStaked(msg.sender, _amount, sentinels[msg.sender].reputationScore);
    }

    /**
     * @notice Allows Sentinels to unstake governance tokens, reducing their reputation.
     *         For this demo, the token interaction is simulated.
     * @param _amount The amount of governance tokens to unstake.
     */
    function unstakeFromReputation(uint256 _amount) public onlyRegisteredSentinel nonReentrant {
        if (sentinels[msg.sender].stakedTokens < _amount) revert InsufficientStakeToUnstake();

        // In a real system, this would involve transferring tokens back to msg.sender.
        // require(IGovernanceToken(governanceToken).transfer(msg.sender, _amount), "Token transfer failed");

        uint256 currentRep = getSentinelReputation(msg.sender); // Get decay-adjusted rep
        sentinels[msg.sender].stakedTokens = sentinels[msg.sender].stakedTokens.sub(_amount);
        // Reduce reputation for the unstaked amount
        sentinels[msg.sender].reputationScore = currentRep.sub(_amount.mul(STAKE_TO_REPUTATION_MULTIPLIER));
        sentinels[msg.sender].lastReputationUpdate = block.timestamp; // Reset decay timer

        emit ReputationUnstaked(msg.sender, _amount, sentinels[msg.sender].reputationScore);
    }

    /**
     * @notice Returns the current reputation score of a Sentinel, adjusted for time-based decay.
     * @param _sentinel The address of the Sentinel.
     * @return The decay-adjusted reputation score.
     */
    function getSentinelReputation(address _sentinel) public view returns (uint256) {
        Sentinel storage sentinel = sentinels[_sentinel];
        if (!sentinel.isRegistered) return 0; // Or revert NotRegisteredSentinel()
        
        uint256 timePassed = block.timestamp.sub(sentinel.lastReputationUpdate);
        uint256 decayAmount = (timePassed.div(1 days)).mul(REPUTATION_DECAY_RATE_PER_DAY);
        
        // Ensure reputation doesn't go below 0 (or a minimum threshold)
        return sentinel.reputationScore > decayAmount ? sentinel.reputationScore.sub(decayAmount) : 0;
    }

    // --- III.H. Echo Evolution & State Functions ---

    /**
     * @notice Evolves an Echo's state to a new state, updating its metadata hash.
     *         This function can be triggered by specific conditions, interactions, or governance decisions.
     * @param _echoId The ID of the Echo to evolve.
     * @param _newState The new state ID for the Echo.
     * @param _newMetadataHash The IPFS hash or URI for the new metadata representing the evolved state.
     */
    function evolveEchoState(uint256 _echoId, uint8 _newState, string calldata _newMetadataHash) public onlyEchoOwnerOrApproved(_echoId) {
        if (!_exists(_echoId)) revert InvalidEchoId();

        echoes[_echoId].currentState = _newState;
        echoes[_echoId].metadataHash = _newMetadataHash;
        echoes[_echoId].lastInteraction = block.timestamp; // Evolution counts as interaction

        emit EchoStateEvolved(_echoId, _newState, _newMetadataHash);
    }

    /**
     * @notice Establishes a synergistic attunement between two Echoes.
     *         Requires both Echoes to be owned/approved by the caller.
     * @param _echoId1 The ID of the first Echo.
     * @param _echoId2 The ID of the second Echo.
     */
    function attuneEchoes(uint256 _echoId1, uint256 _echoId2) public nonReentrant {
        if (!_exists(_echoId1) || !_exists(_echoId2)) revert InvalidEchoId();
        if (_echoId1 == _echoId2) revert SelfAttunementForbidden();

        // Ensure caller owns/approved both Echoes
        if (!(ownerOf(_echoId1) == msg.sender || isApprovedForAll(ownerOf(_echoId1), msg.sender) || getApproved(_echoId1) == msg.sender)) {
            revert NotEchoOwnerOrApproved();
        }
        if (!(ownerOf(_echoId2) == msg.sender || isApprovedForAll(ownerOf(_echoId2), msg.sender) || getApproved(_echoId2) == msg.sender)) {
            revert NotEchoOwnerOrApproved();
        }

        // Canonical order for attunement to avoid duplicates (e.g., A-B is same as B-A)
        uint256 canonicalId1 = _echoId1 < _echoId2 ? _echoId1 : _echoId2;
        uint256 canonicalId2 = _echoId1 < _echoId2 ? _echoId2 : _echoId1;

        if (attunedEchoes[canonicalId1][canonicalId2]) revert EchoAlreadyAttuned();

        attunedEchoes[canonicalId1][canonicalId2] = true;
        
        echoes[_echoId1].lastInteraction = block.timestamp;
        echoes[_echoId2].lastInteraction = block.timestamp;

        emit EchoesAttuned(canonicalId1, canonicalId2);
    }

    /**
     * @notice Breaks an existing synergistic attunement between two Echoes.
     *         Requires both Echoes to be owned/approved by the caller.
     * @param _echoId1 The ID of the first Echo.
     * @param _echoId2 The ID of the second Echo.
     */
    function detuneEchoes(uint256 _echoId1, uint256 _echoId2) public nonReentrant {
        if (!_exists(_echoId1) || !_exists(_echoId2)) revert InvalidEchoId();
        if (_echoId1 == _echoId2) revert SelfAttunementForbidden();

        // Ensure caller owns/approved both Echoes
        if (!(ownerOf(_echoId1) == msg.sender || isApprovedForAll(ownerOf(_echoId1), msg.sender) || getApproved(_echoId1) == msg.sender)) {
            revert NotEchoOwnerOrApproved();
        }
        if (!(ownerOf(_echoId2) == msg.sender || isApprovedForAll(ownerOf(_echoId2), msg.sender) || getApproved(_echoId2) == msg.sender)) {
            revert NotEchoOwnerOrApproved();
        }

        uint256 canonicalId1 = _echoId1 < _echoId2 ? _echoId1 : _echoId2;
        uint256 canonicalId2 = _echoId1 < _echoId2 ? _echoId2 : _echoId1;

        if (!attunedEchoes[canonicalId1][canonicalId2]) revert EchoNotAttuned();

        delete attunedEchoes[canonicalId1][canonicalId2];

        echoes[_echoId1].lastInteraction = block.timestamp;
        echoes[_echoId2].lastInteraction = block.timestamp;

        emit EchoesDetuned(canonicalId1, canonicalId2);
    }

    /**
     * @notice Allows Sentinels to forge a new Echo by burning multiple existing Echoes (parents).
     *         This acts as an on-chain crafting mechanism.
     * @param _parentEchoIds An array of IDs of the Echoes to be burned.
     * @param _newMetadataHash The IPFS hash for the newly forged Echo's metadata.
     * @return The ID of the newly forged Echo.
     */
    function forgeNewEcho(uint256[] calldata _parentEchoIds, string calldata _newMetadataHash) public onlyRegisteredSentinel nonReentrant returns (uint256) {
        if (_parentEchoIds.length < 2) revert("Requires at least two parent Echoes");

        address currentOwner = msg.sender;
        for (uint256 i = 0; i < _parentEchoIds.length; i++) {
            uint256 parentId = _parentEchoIds[i];
            if (!_exists(parentId)) revert InvalidEchoId();
            if (!(ownerOf(parentId) == currentOwner || isApprovedForAll(ownerOf(parentId), currentOwner) || getApproved(parentId) == currentOwner)) {
                revert NotEchoOwnerOrApproved(); // Ensure caller owns/approved all parents
            }
            burnEcho(parentId); // Burn the parent Echo
        }

        // Mint the new Echo
        _echoIds.increment();
        uint256 newEchoId = _echoIds.current();
        _safeMint(currentOwner, newEchoId);

        echoes[newEchoId] = Echo({
            metadataHash: _newMetadataHash,
            currentState: 1, // Forged Echoes might start in a special state
            createdAt: block.timestamp,
            lastInteraction: block.timestamp,
            amplificationScore: 0,
            activationThreshold: 0,
            contextInfusionTimestamp: 0,
            pendingOracleQueryId: 0
        });

        emit NewEchoForged(currentOwner, newEchoId, _parentEchoIds, _newMetadataHash);
        return newEchoId;
    }

    /**
     * @notice Allows an Echo owner to set a dynamic activation threshold for their Echo.
     *         This threshold can influence how other functions (e.g., evolveEchoState, interactWithEcho) behave.
     * @param _echoId The ID of the Echo.
     * @param _thresholdValue The new activation threshold value.
     */
    function setEchoActivationThreshold(uint256 _echoId, uint256 _thresholdValue) public onlyEchoOwnerOrApproved(_echoId) {
        if (!_exists(_echoId)) revert InvalidEchoId();
        echoes[_echoId].activationThreshold = _thresholdValue;
        emit EchoActivationThresholdSet(_echoId, _thresholdValue);
    }

    // --- III.I. Resonance & Value Calculation Functions ---

    /**
     * @notice Calculates and returns the dynamic "Resonance Score" of an Echo.
     *         This score acts as a fluctuating value coefficient, reflecting the Echo's utility,
     *         network engagement, and contextual relevance.
     *         The formula is complex, incorporating several factors and governance-set coefficients.
     * @param _echoId The ID of the Echo to calculate the Resonance Score for.
     * @return The calculated Resonance Score.
     */
    function getEchoResonanceScore(uint256 _echoId) public view returns (uint256) {
        if (!_exists(_echoId)) revert InvalidEchoId();

        Echo storage echo = echoes[_echoId];
        address echoOwner = ownerOf(_echoId);

        // Base Value (governance controlled)
        uint256 baseValue = resonanceCoefficients[COEFFICIENT_BASE_VALUE];

        // Reputation Impact (of owner and relevant Sentinels)
        uint256 ownerReputation = getSentinelReputation(echoOwner);
        uint256 reputationImpact = ownerReputation.mul(resonanceCoefficients[COEFFICIENT_REPUTATION_IMPACT]).div(100); // Scaled

        // Amplification Bonus
        uint256 amplificationBonus = echo.amplificationScore.mul(resonanceCoefficients[COEFFICIENT_AMPLIFICATION_BONUS]).div(100);

        // Synergy Bonus (check for attunements)
        uint256 synergyBonus = 0;
        for (uint256 i = 1; i <= _echoIds.current(); i++) { // Iterate through all other Echoes
            uint256 canonicalId1 = _echoId < i ? _echoId : i;
            uint256 canonicalId2 = _echoId < i ? i : _echoId;
            if (attunedEchoes[canonicalId1][canonicalId2]) {
                synergyBonus = synergyBonus.add(resonanceCoefficients[COEFFICIENT_SYNERGY_BONUS]); // Add bonus for each attunement
            }
        }
        // Apply synergy bonus as a multiplier (e.g., 1.5x)
        uint256 currentScore = baseValue.add(reputationImpact).add(amplificationBonus);
        currentScore = currentScore.mul(synergyBonus.div(100).add(1)); // synergyBonus / 100 + 1 for multiplier

        // Age Decay (Encourages fresh interaction)
        uint256 age = block.timestamp.sub(echo.createdAt);
        uint256 ageDecay = (age.div(1 days)).mul(resonanceCoefficients[COEFFICIENT_AGE_DECAY]);
        currentScore = currentScore > ageDecay ? currentScore.sub(ageDecay) : 0;

        // Interaction Boost (Recent activity adds value)
        uint256 timeSinceLastInteraction = block.timestamp.sub(echo.lastInteraction);
        // Boost for recent interactions, decaying over time (e.g., significant boost if within 1 day, less for 7 days, none after 30 days)
        if (timeSinceLastInteraction < 1 days) {
            currentScore = currentScore.add(currentScore.mul(resonanceCoefficients[COEFFICIENT_INTERACTION_BOOST]).div(100));
        } else if (timeSinceLastInteraction < 7 days) {
            currentScore = currentScore.add(currentScore.mul(resonanceCoefficients[COEFFICIENT_INTERACTION_BOOST]).div(200)); // Half boost
        }
        // Further factors could be added: oracle data, scarcity, specific trait values, etc.

        return currentScore;
    }

    // --- III.J. Curation & Interaction Functions ---

    /**
     * @notice Sentinels can use their reputation to "amplify" an Echo, boosting its visibility,
     *         interaction potential, and Resonance Score. This costs reputation.
     * @param _echoId The ID of the Echo to amplify.
     * @param _reputationCost The amount of reputation the Sentinel is willing to spend to amplify.
     */
    function amplifyEcho(uint256 _echoId, uint256 _reputationCost) public onlyRegisteredSentinel nonReentrant {
        if (!_exists(_echoId)) revert InvalidEchoId();
        if (_reputationCost == 0) revert("Amplification cost must be positive");

        uint256 currentRep = getSentinelReputation(msg.sender);
        if (currentRep < _reputationCost) revert InsufficientReputation();

        // Deduct reputation
        sentinels[msg.sender].reputationScore = currentRep.sub(_reputationCost);
        sentinels[msg.sender].lastReputationUpdate = block.timestamp; // Update decay timestamp

        // Boost Echo's amplification score
        echoes[_echoId].amplificationScore = echoes[_echoId].amplificationScore.add(_reputationCost);
        echoes[_echoId].lastInteraction = block.timestamp;

        emit EchoAmplified(_echoId, msg.sender, _reputationCost);
    }

    /**
     * @notice Sentinels can reduce an Echo's amplification. This might be used for moderation
     *         or to reallocate amplification. Might incur a penalty if deamplification is too frequent or unjustified.
     * @param _echoId The ID of the Echo to deamplify.
     * @param _reputationRefund The amount of amplification to reduce.
     */
    function deamplifyEcho(uint256 _echoId, uint256 _reputationRefund) public onlyRegisteredSentinel nonReentrant {
        if (!_exists(_echoId)) revert InvalidEchoId();
        if (echoes[_echoId].amplificationScore < _reputationRefund) revert NotEnoughAmplification();
        if (_reputationRefund == 0) revert("Deamplification amount must be positive");

        // Reduce Echo's amplification score
        echoes[_echoId].amplificationScore = echoes[_echoId].amplificationScore.sub(_reputationRefund);
        echoes[_echoId].lastInteraction = block.timestamp;

        // Optionally, return a portion of reputation or apply a penalty to the deamplifier
        // For simplicity, for now, we'll just reduce amplification.
        // A more complex system might track who amplified what and allow them to refund their own stakes.

        emit EchoDeamplified(_echoId, msg.sender, _reputationRefund);
    }

    /**
     * @notice A generic function for Sentinels to interact with Echoes.
     *         Interaction type can trigger different internal logic or state changes.
     * @param _echoId The ID of the Echo being interacted with.
     * @param _interactionType A numerical code representing the type of interaction (e.g., 1=Like, 2=Comment, 3=Share).
     * @param _interactionData Optional additional data for the interaction.
     */
    function interactWithEcho(uint256 _echoId, uint8 _interactionType, bytes calldata _interactionData) public onlyRegisteredSentinel nonReentrant {
        if (!_exists(_echoId)) revert InvalidEchoId();

        // Update Echo's last interaction timestamp
        echoes[_echoId].lastInteraction = block.timestamp;

        // Logic based on interaction type (example)
        if (_interactionType == 1) { // Simulate "Like"
            // Maybe a small reputation boost for the Sentinel, or for the Echo owner
            uint256 currentRep = getSentinelReputation(msg.sender);
            sentinels[msg.sender].reputationScore = currentRep.add(1); // Small boost
            sentinels[msg.sender].lastReputationUpdate = block.timestamp;
            // Optionally, if the Echo's activationThreshold is met, it could evolve
            if (echoes[_echoId].currentState == 0 && getEchoResonanceScore(_echoId) > echoes[_echoId].activationThreshold && echoes[_echoId].activationThreshold > 0) {
                 // Simulate automatic evolution
                 evolveEchoState(_echoId, 1, string(abi.encodePacked(echoes[_echoId].metadataHash, "_evolved")));
            }
        } else if (_interactionType == 2) { // Simulate "Comment" or "Curate"
            // Higher reputation boost or a specific effect
            uint256 currentRep = getSentinelReputation(msg.sender);
            sentinels[msg.sender].reputationScore = currentRep.add(5);
            sentinels[msg.sender].lastReputationUpdate = block.timestamp;
        }
        // Further interaction types can be added, each with unique effects on Echo state, Sentinel reputation, etc.

        emit EchoInteracted(_echoId, msg.sender, _interactionType);
    }

    // --- III.K. Governance & System Parameter Functions ---

    /**
     * @notice Allows Sentinels (with sufficient reputation) to propose changes to core system parameters.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., `COEFFICIENT_BASE_VALUE`).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue) public onlyRegisteredSentinel nonReentrant {
        if (getSentinelReputation(msg.sender) < MIN_REPUTATION_FOR_PROPOSAL) revert InsufficientReputation();

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            paramKey: _paramKey,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(VOTING_PERIOD_DURATION),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        // The 'hasVoted' mapping within the struct needs to be initialized for each voter, handled in voteOnProposal.
        // It's not possible to initialize a mapping inside a struct here directly.

        emit ProposalCreated(proposalId, _paramKey, _newValue, proposals[proposalId].voteEndTime);
    }

    /**
     * @notice Sentinels vote on active proposals. Voting power is weighted by their current reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredSentinel nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.voteStartTime == 0) revert ProposalNotFound(); // Check if proposal exists
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) revert InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterReputation = getSentinelReputation(msg.sender);
        if (voterReputation == 0) revert InsufficientReputation(); // Must have some reputation to vote

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterReputation);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterReputation);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @notice Executes a passed proposal. Can only be called after the voting period ends and if 'Yes' votes outweigh 'No' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.voteStartTime == 0) revert ProposalNotFound();
        if (block.timestamp <= proposal.voteEndTime) revert InvalidProposalState(); // Voting period must be over
        if (proposal.executed) revert InvalidProposalState(); // Already executed

        // Determine if proposal passed (simple majority by reputation weight)
        if (proposal.yesVotes > proposal.noVotes) {
            resonanceCoefficients[proposal.paramKey] = proposal.newValue;
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, proposal.paramKey, proposal.newValue);
        } else {
            // Proposal failed
            proposal.executed = true; // Mark as executed to prevent re-execution, even if failed
            emit ProposalExecuted(_proposalId, proposal.paramKey, 0); // Emit with 0 to indicate failure or no change
        }
    }

    /**
     * @notice Allows the designated governance address to directly set specific resonance coefficients.
     *         This is primarily for emergency overrides or initial setup, separate from DAO proposals.
     * @param _coefficientName The keccak256 hash of the coefficient's name.
     * @param _value The new value for the coefficient.
     */
    function setResonanceCoefficient(bytes32 _coefficientName, uint256 _value) public {
        if (msg.sender != governanceAddress) revert NotGovernanceContract();
        resonanceCoefficients[_coefficientName] = _value;
        emit ResonanceCoefficientSet(_coefficientName, _value);
    }

    /**
     * @notice Allows the designated governance address to update the address of the trusted oracle.
     * @param _newOracleAddress The new address for the oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) public {
        if (msg.sender != governanceAddress) revert NotGovernanceContract();
        if (_newOracleAddress == address(0)) revert("Invalid oracle address");
        oracleAddress = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    // --- III.L. Oracle Interaction Functions ---

    /**
     * @notice Initiates an oracle call to infuse external data, which can influence Echo state or resonance.
     *         This function would typically be called by an Echo owner or Sentinel for specific requests.
     * @param _echoId The ID of the Echo for which context is requested.
     * @param _dataSource A string identifying the external data source (e.g., "weather", "stock_price", "AI_sentiment").
     * @param _callData Additional data for the oracle query.
     */
    function requestOracleContextInfusion(uint256 _echoId, string calldata _dataSource, bytes calldata _callData) public onlyRegisteredSentinel {
        if (!_exists(_echoId)) revert InvalidEchoId();
        if (oracleAddress == address(0)) revert("Oracle address not set");
        if (echoes[_echoId].pendingOracleQueryId != 0) revert("Oracle request already pending for this Echo");

        // Simulate a queryId. In a real system like Chainlink, this would come from the oracle.
        bytes32 queryId = keccak256(abi.encodePacked(_echoId, _dataSource, _callData, block.timestamp));
        echoes[_echoId].pendingOracleQueryId = queryId;

        // In a real Chainlink integration, this would call the Chainlink client.
        // LinkToken.transferAndCall(oracleAddress, fee, abi.encodeWithSelector(oracle.requestData.selector, queryId, _dataSource, _callData));

        emit OracleContextRequested(_echoId, queryId, _dataSource);
    }

    /**
     * @notice Callback function for the trusted oracle to deliver external data.
     *         Only callable by the designated oracleAddress.
     * @param _echoId The ID of the Echo that requested the context.
     * @param _queryId The unique ID of the oracle query.
     * @param _data The bytes data returned by the oracle.
     */
    function fulfillOracleContextInfusion(uint256 _echoId, bytes32 _queryId, bytes calldata _data) external {
        if (msg.sender != oracleAddress) revert InvalidOracleCall();
        if (!_exists(_echoId)) revert InvalidEchoId();
        if (echoes[_echoId].pendingOracleQueryId == 0 || echoes[_echoId].pendingOracleQueryId != _queryId) revert OracleAlreadyFulfilled();

        echoes[_echoId].contextInfusionTimestamp = block.timestamp;
        echoes[_echoId].pendingOracleQueryId = 0; // Clear pending query

        // Example: Parse _data and update Echo state/resonance based on it
        // This is highly dependent on the oracle's data format and contract logic.
        // For demonstration, let's assume _data is a simple uint256 representing a "sentiment score".
        if (_data.length >= 32) {
            uint256 sentimentScore = abi.decode(_data, (uint256));
            if (sentimentScore > 500) { // If sentiment is high, boost amplification
                echoes[_echoId].amplificationScore = echoes[_echoId].amplificationScore.add(sentimentScore.div(100));
            } else if (sentimentScore < 200) { // If sentiment is low, reduce it
                echoes[_echoId].amplificationScore = echoes[_echoId].amplificationScore > sentimentScore.div(100) ? echoes[_echoId].amplificationScore.sub(sentimentScore.div(100)) : 0;
            }
            echoes[_echoId].lastInteraction = block.timestamp; // Oracle infusion counts as interaction
            // A more complex system might trigger evolveEchoState or adjust ResonanceCoefficients directly.
        }

        emit OracleContextFulfilled(_echoId, _queryId, _data);
    }

    // --- III.M. Internal/Utility Functions (already integrated or implied) ---
    // _calculateReputation is effectively `getSentinelReputation`
    // _updateEchoMetadataHash is done directly in `evolveEchoState`
    // _calculateSynergyBonus is part of `getEchoResonanceScore`
}
```