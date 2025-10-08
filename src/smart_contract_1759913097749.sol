```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Interfaces for external contracts (SynapticToken and AttestationNFT) ---
interface ISynapticToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IAttestationNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title SynapticNexus
 * @author YourName (GPT-4)
 * @notice A decentralized, adaptive intelligence network for collective knowledge, predictive forecasting, and reputation-driven governance.
 *
 * @dev This contract implements a novel system where participants contribute information (attestations) and make predictions,
 * earning reputation based on accuracy and community consensus. This reputation fuels dynamic governance for resource
 * allocation and network parameter adjustments. It also allows for the tokenization of verified knowledge into NFTs.
 *
 * Outline and Function Summary:
 *
 * Purpose: The Synaptic Nexus is a decentralized, adaptive intelligence network designed to foster collective knowledge accumulation,
 * predictive foresight, and reputation-driven adaptive governance. It empowers participants to contribute verified information,
 * predict future events, and collaboratively steer the network's evolution and resource allocation based on their earned trust and accuracy.
 *
 * Core Mechanics:
 * 1. Attestation & Verification: Users submit claims (attestations) about information, backed by a stake. Other users can challenge or verify these.
 *    Accuracy (as determined by community consensus or external resolution) impacts reputation.
 * 2. Predictive Forecasting Markets: Participants can create and participate in prediction markets on various topics, staking tokens on specific outcomes.
 *    Accurate predictions yield rewards and boost reputation.
 * 3. Dynamic Reputation System: A participant's reputation is dynamically calculated based on the accuracy of their attestations and predictions,
 *    their active participation, and a time-based decay factor. Higher reputation grants more influence in governance.
 * 4. Adaptive Governance & Treasury: The network's treasury is managed through reputation-weighted proposals and voting. Governance parameters
 *    (e.g., stake requirements, quorum) can also be adaptively adjusted by high-reputation participants.
 * 5. Knowledge-Bound NFTs (Attestation NFTs): Once an attestation is confirmed as highly reliable, it can be minted as a unique ERC721 NFT,
 *    symbolizing verifiable knowledge or contribution.
 *
 *
 * Function Summary:
 *
 * I. Core Infrastructure & Protocol Management
 * 1. constructor(address _synapticTokenAddress, address _attestationNFTAddress): Initializes the contract with the Synaptic Token (for staking) and Attestation NFT contract addresses, and sets the initial owner.
 * 2. setProtocolParameters(uint256 _minAttestationStake, uint256 _challengeStakeRatio, uint256 _attestationChallengePeriod, uint256 _minForecastStake, uint256 _forecastResolutionPeriod, uint256 _reputationDecayRate, uint256 _minReputationToPropose, uint256 _quorumPercentage): Allows governance to adjust fundamental network parameters, influencing economic incentives and governance thresholds.
 *
 * II. Participant Management & Identity
 * 3. registerParticipant(string calldata _metadataURI): Registers a new address as a network participant, associating a URI for their public profile or identity metadata.
 * 4. updateParticipantMetadata(string calldata _newMetadataURI): Allows a registered participant to update their associated profile metadata URI.
 * 5. togglePrivacySetting(uint256 _settingIndex, bool _value): Enables participants to manage specific privacy preferences related to their contributions or profile visibility.
 *
 * III. Attestation & Verification System
 * 6. submitAttestation(bytes32 _subjectHash, string calldata _attestationURI, uint256 _stakeAmount): Participants submit an attestation (a claim about a `_subjectHash`) along with its details URI, backing it with a token stake.
 * 7. challengeAttestation(bytes32 _attestationId, string calldata _reasonURI, uint256 _challengeStake): Allows any participant to formally challenge an existing attestation, providing a reason and staking tokens.
 * 8. verifyAttestation(bytes32 _attestationId): Community members can endorse an attestation, contributing to its "truth score." The weight of their endorsement is based on their reputation.
 * 9. resolveAttestationChallenge(bytes32 _attestationId, bool _challengerWins): Owner/Governance resolves a challenged attestation. If challenger wins, original attester is penalized; otherwise, challenger is penalized. Stakes are distributed.
 * 10. revokeOwnAttestation(bytes32 _attestationId): Allows an attester to revoke their own attestation if it's not currently under challenge.
 *
 * IV. Predictive Forecasting Markets
 * 11. createForecastMarket(bytes32 _marketHash, string calldata _questionURI, uint256 _resolutionTimestamp, uint256 _entryStake): Initiates a new prediction market, defining its question, resolution time, and minimum stake.
 * 12. participateInForecast(bytes32 _marketId, bool _predictionOutcome, uint256 _stakeAmount): Participants stake tokens on their predicted outcome (true/false) for a specified market.
 * 13. submitForecastOutcome(bytes32 _marketId, bool _actualOutcome): An authorized entity (e.g., oracle, governance) submits the definitive outcome for a resolved prediction market.
 * 14. claimForecastRewards(bytes32 _marketId): Allows participants with correct predictions to claim their share of the prize pool and earn reputation.
 *
 * V. Dynamic Reputation Management
 * 15. getReputationScore(address _participant): Computes and returns a participant's current dynamic reputation score, based on their track record, activity, and decay. This is the participant's personal, non-delegated, decayed reputation.
 * 16. delegateReputation(address _delegatee, uint256 _amount): Allows a participant to delegate a portion of their *reputation points* to another. This affects their effective voting power.
 * 17. undelegateReputation(address _delegatee, uint256 _amount): Allows a participant to revoke a previous reputation delegation.
 * 18. slashReputation(address _participant, uint256 _amount, string calldata _reasonURI): A governance-controlled function to penalize participants by reducing their reputation for proven malicious activities.
 *
 * VI. Adaptive Governance & Treasury
 * 19. proposeInitiative(string calldata _proposalURI, uint256 _fundingAmount, address _recipient): Participants meeting a minimum reputation threshold can propose initiatives requiring funding from the network's treasury.
 * 20. voteOnProposal(bytes32 _proposalId, bool _support): Registered participants cast votes on proposals, with their voting power weighted by their effective reputation (personal + delegated in - delegated out).
 * 21. executeProposal(bytes32 _proposalId): Executes a proposal that has successfully passed the voting phase and quorum requirements, transferring the specified funds.
 * 22. updateGovernanceParameters(uint256 _minReputationToPropose, uint256 _quorumPercentage): Allows governance to dynamically adjust parameters specific to the governance process itself, such as minimum reputation for proposing or the required voting quorum. (This function is callable via `executeProposal` after a successful governance vote).
 *
 * VII. Knowledge-Bound NFTs (AttestationNFTs)
 * 23. mintAttestationNFT(bytes32 _attestationId, address _to): Mints a unique ERC721 NFT for a *verified and highly reputable* attestation, transferring ownership to `_to`.
 * 24. transferAttestationNFT(address _from, address _to, uint256 _tokenId): Standard ERC721 function to transfer ownership of an Attestation NFT. (Interacts with `_attestationNFTContract`).
 * 25. burnAttestationNFT(uint256 _tokenId): Standard ERC721 function to burn an Attestation NFT. (Interacts with `_attestationNFTContract`).
 */
contract SynapticNexus {
    address public owner;
    ISynapticToken public immutable synapticToken;
    IAttestationNFT public immutable attestationNFT;

    // --- Events ---
    event ParticipantRegistered(address indexed participant, string metadataURI);
    event ParticipantMetadataUpdated(address indexed participant, string newMetadataURI);
    event PrivacySettingToggled(address indexed participant, uint256 settingIndex, bool value);

    event AttestationSubmitted(bytes32 indexed attestationId, address indexed attester, bytes32 subjectHash, string attestationURI, uint256 stakeAmount);
    event AttestationChallenged(bytes32 indexed attestationId, address indexed challenger, string reasonURI, uint256 challengeStake);
    event AttestationVerified(bytes32 indexed attestationId, address indexed verifier, uint256 reputationWeight);
    event AttestationResolved(bytes32 indexed attestationId, bool challengerWins, uint256 attesterStakeDistributed, uint256 challengerStakeDistributed);
    event AttestationRevoked(bytes32 indexed attestationId, address indexed attester);
    event AttestationNFTMinted(bytes32 indexed attestationId, uint256 indexed tokenId, address indexed to);

    event ForecastMarketCreated(bytes32 indexed marketId, address indexed creator, string questionURI, uint256 resolutionTimestamp, uint256 entryStake);
    event ForecastParticipated(bytes32 indexed marketId, address indexed participant, bool predictionOutcome, uint256 stakeAmount);
    event ForecastOutcomeSubmitted(bytes32 indexed marketId, bool actualOutcome);
    event ForecastRewardsClaimed(bytes32 indexed marketId, address indexed participant, uint256 rewardAmount, uint256 reputationEarned);

    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationSlashed(address indexed participant, uint256 amount, string reasonURI);

    event ProposalSubmitted(bytes32 indexed proposalId, address indexed proposer, string proposalURI, uint256 fundingAmount, address recipient);
    event VotedOnProposal(bytes32 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(bytes32 indexed proposalId);
    event ProtocolParametersUpdated(uint256 minAttestationStake, uint256 challengeStakeRatio, uint256 attestationChallengePeriod, uint256 minForecastStake, uint256 forecastResolutionPeriod, uint256 reputationDecayRate, uint256 minReputationToPropose, uint256 quorumPercentage);
    event GovernanceParametersUpdated(uint256 minReputationToPropose, uint256 quorumPercentage);

    // --- Errors ---
    error NotRegisteredParticipant();
    error AlreadyRegisteredParticipant();
    error InvalidStakeAmount();
    error AttestationNotFound();
    error AttestationNotInChallenge();
    error AttestationChallengeActive();
    error AttestationChallengeNotEnded();
    error AttestationChallengeAlreadyResolved();
    error AttestationNotBySender();
    error ForecastMarketNotFound();
    error ForecastMarketNotOpen();
    error ForecastMarketAlreadyResolved();
    error ForecastMarketNotResolved();
    error PredictionAlreadyMade();
    error NoRewardsToClaim();
    error InsufficientReputation();
    error ProposalNotFound();
    error ProposalNotOpen();
    error ProposalAlreadyVoted();
    error ProposalNotPassed();
    error ProposalAlreadyExecuted();
    error InsufficientFunds();
    error DelegationFailed();
    error NoDelegationFound();
    error AttestationNotVerifiedEnough();
    error AttestationNFTAlreadyMinted();
    error InsufficientReputationToPropose();
    error OnlyOwner();

    // --- Enums ---
    enum AttestationStatus { Pending, Challenged, ResolvedValid, ResolvedInvalid, Revoked }
    enum ForecastStatus { Open, Resolved }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // --- Structs ---
    struct Participant {
        string metadataURI;
        uint256 accurateContributions; // Sum of points for accurate actions
        uint256 totalContributions;   // Sum of points for all actions (accurate/inaccurate)
        uint256 lastActiveTimestamp;
        bool isRegistered;
        mapping(uint256 => bool) privacySettings; // 0: metadata, 1: attestations, 2: forecasts
    }

    struct Attestation {
        bytes32 subjectHash;
        string attestationURI;
        address attester;
        uint256 stakeAmount;
        AttestationStatus status;
        uint256 challengePeriodEnd;
        uint256 verificationCount; // Sum of effective reputation scores of verifiers
        address challenger; // address of the active challenger, address(0) if none
        uint256 challengeStake; // stake of the active challenger
        string challengeReasonURI; // reason for the active challenge
        uint256 resolutionTimestamp;
        uint256 attestationIdCounter; // For NFT tokenId generation
        bool nftMinted;
    }

    struct ForecastMarket {
        string questionURI;
        address creator;
        uint256 resolutionTimestamp;
        uint256 entryStake;
        ForecastStatus status;
        bool resolvedOutcome; // true or false
        uint256 totalStakedForTrue;
        uint256 totalStakedForFalse;
        mapping(address => Prediction) predictions; // Participant address => Prediction
    }

    struct Prediction {
        bool outcome;
        uint256 stake;
        bool claimed;
    }

    struct Proposal {
        string proposalURI;
        address proposer;
        uint256 fundingAmount;
        address recipient;
        ProposalStatus status;
        uint256 votesFor; // Number of unique addresses
        uint256 votesAgainst; // Number of unique addresses
        uint256 totalReputationFor; // Sum of effective reputation scores of 'for' voters
        uint256 totalReputationAgainst; // Sum of effective reputation scores of 'against' voters
        uint256 creationTimestamp;
        uint256 proposalPeriodEnd;
        bool executed;
        mapping(address => bool) hasVoted; // Participant address => Voted (true/false)
    }

    // --- State Variables ---
    mapping(address => Participant) public participants;
    mapping(bytes32 => Attestation) public attestations;
    uint256 private _attestationIdCounter; // To generate unique NFT tokenIds
    mapping(bytes32 => bytes32) public attestationSubjectToId; // Map subject hash to attestation ID for easier lookup (if only one active attestation per subject)
    
    mapping(bytes32 => ForecastMarket) public forecastMarkets;
    mapping(bytes32 => Proposal) public proposals;

    // Reputation related:
    mapping(address => uint256) public totalDelegatedReputationIn; // How much reputation *this address* has received
    mapping(address => uint256) public totalDelegatedReputationOut; // How much reputation *this address* has delegated out

    // Protocol Parameters (adjustable via governance)
    uint256 public minAttestationStake; // Min tokens required to submit an attestation
    uint256 public challengeStakeRatio; // % of attestation stake required to challenge (e.g., 5000 for 50%)
    uint256 public attestationChallengePeriod; // Duration in seconds for an attestation to be challenged
    uint256 public minForecastStake; // Min tokens required to participate in a forecast
    uint256 public forecastResolutionPeriod; // How long after resolutionTimestamp a forecast can be resolved.
    uint256 public reputationDecayRate; // Annual decay rate for reputation (e.g., 100 for 1%)
    uint256 public minReputationToPropose; // Min reputation required to submit a governance proposal
    uint256 public quorumPercentage; // Percentage of total network reputation needed for a proposal to pass (e.g., 3000 for 30%)
    uint256 public constant REPUTATION_MULTIPLIER = 1e4; // For precision in reputation calculations (e.g., 10000 for 1 unit)

    // A mock for total network reputation. In a real system, this would be dynamically calculated (e.g., from a reputation token snapshot).
    uint256 public constant MOCK_TOTAL_NETWORK_REPUTATION = 1_000_000 * REPUTATION_MULTIPLIER;


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyRegisteredParticipant() {
        if (!participants[msg.sender].isRegistered) revert NotRegisteredParticipant();
        _;
    }

    // --- Constructor ---
    constructor(address _synapticTokenAddress, address _attestationNFTAddress) {
        owner = msg.sender;
        synapticToken = ISynapticToken(_synapticTokenAddress);
        attestationNFT = IAttestationNFT(_attestationNFTAddress);

        // Set initial protocol parameters (can be updated via governance later)
        minAttestationStake = 100 ether; // Example: 100 tokens
        challengeStakeRatio = 5000; // Example: 50%
        attestationChallengePeriod = 3 days;
        minForecastStake = 10 ether; // Example: 10 tokens
        forecastResolutionPeriod = 7 days;
        reputationDecayRate = 100; // Example: 1% annual decay (scaled by REPUTATION_MULTIPLIER implicitly)
        minReputationToPropose = 10000; // Example: 10,000 reputation points
        quorumPercentage = 3000; // Example: 30%

        // Approve this contract to mint NFTs on behalf of AttestationNFT (if it's an admin-minting NFT contract)
        // If AttestationNFT has a public mint function, this might not be needed.
        // Assuming the `mint` function in IAttestationNFT is intended to be called by this contract.
        // This is a common pattern for contracts managing related NFTs.
        attestationNFT.setApprovalForAll(address(this), true);
    }

    // I. Core Infrastructure & Protocol Management
    /**
     * @notice Allows governance to adjust fundamental network parameters.
     * @dev This function is typically called as a result of a successful governance proposal.
     * @param _minAttestationStake Minimum tokens required to submit an attestation.
     * @param _challengeStakeRatio Percentage (e.g., 5000 for 50%) of attestation stake required to challenge.
     * @param _attestationChallengePeriod Duration in seconds for an attestation to be challenged.
     * @param _minForecastStake Minimum tokens required to participate in a forecast.
     * @param _forecastResolutionPeriod How long after resolutionTimestamp a forecast can be resolved.
     * @param _reputationDecayRate Annual decay rate for reputation (e.g., 100 for 1%).
     * @param _minReputationToPropose Minimum reputation required to submit a governance proposal.
     * @param _quorumPercentage Percentage of total reputation needed for a proposal to pass (e.g., 3000 for 30%).
     */
    function setProtocolParameters(
        uint256 _minAttestationStake,
        uint256 _challengeStakeRatio,
        uint256 _attestationChallengePeriod,
        uint256 _minForecastStake,
        uint256 _forecastResolutionPeriod,
        uint256 _reputationDecayRate,
        uint256 _minReputationToPropose,
        uint256 _quorumPercentage
    ) external onlyOwner { // In a full DAO, this would be callable only by a successful governance vote
        minAttestationStake = _minAttestationStake;
        challengeStakeRatio = _challengeStakeRatio;
        attestationChallengePeriod = _attestationChallengePeriod;
        minForecastStake = _minForecastStake;
        forecastResolutionPeriod = _forecastResolutionPeriod;
        reputationDecayRate = _reputationDecayRate;
        minReputationToPropose = _minReputationToPropose;
        quorumPercentage = _quorumPercentage;
        emit ProtocolParametersUpdated(
            _minAttestationStake,
            _challengeStakeRatio,
            _attestationChallengePeriod,
            _minForecastStake,
            _forecastResolutionPeriod,
            _reputationDecayRate,
            _minReputationToPropose,
            _quorumPercentage
        );
    }

    // II. Participant Management & Identity
    /**
     * @notice Registers a new address as a network participant, associating a URI for their public profile or identity metadata.
     * @param _metadataURI URI pointing to the participant's off-chain profile metadata.
     */
    function registerParticipant(string calldata _metadataURI) external {
        if (participants[msg.sender].isRegistered) revert AlreadyRegisteredParticipant();
        participants[msg.sender].isRegistered = true;
        participants[msg.sender].metadataURI = _metadataURI;
        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        // Initial reputation for new participants could be 0 or a small default.
        // For this demo, reputation starts at 0 and builds up.
        emit ParticipantRegistered(msg.sender, _metadataURI);
    }

    /**
     * @notice Allows a registered participant to update their associated profile metadata URI.
     * @param _newMetadataURI New URI pointing to the participant's updated off-chain profile metadata.
     */
    function updateParticipantMetadata(string calldata _newMetadataURI) external onlyRegisteredParticipant {
        participants[msg.sender].metadataURI = _newMetadataURI;
        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit ParticipantMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @notice Enables participants to manage specific privacy preferences related to their contributions or profile visibility.
     * @dev Example indices: 0 for metadata visibility, 1 for attestation history, 2 for forecast history.
     * @param _settingIndex The index of the privacy setting to toggle.
     * @param _value The new boolean value for the setting (true for public, false for private).
     */
    function togglePrivacySetting(uint256 _settingIndex, bool _value) external onlyRegisteredParticipant {
        participants[msg.sender].privacySettings[_settingIndex] = _value;
        emit PrivacySettingToggled(msg.sender, _settingIndex, _value);
    }

    // III. Attestation & Verification System
    /**
     * @notice Participants submit an attestation (a claim about a `_subjectHash`) along with its details URI, backing it with a token stake.
     * @param _subjectHash A hash uniquely identifying the subject of the attestation (e.g., IPFS CID of the claim).
     * @param _attestationURI URI pointing to the detailed content of the attestation.
     * @param _stakeAmount The amount of Synaptic Tokens staked to back this attestation.
     */
    function submitAttestation(bytes32 _subjectHash, string calldata _attestationURI, uint256 _stakeAmount) external onlyRegisteredParticipant {
        if (_stakeAmount < minAttestationStake) revert InvalidStakeAmount();
        if (!synapticToken.transferFrom(msg.sender, address(this), _stakeAmount)) revert InvalidStakeAmount();

        _attestationIdCounter++;
        bytes32 attestationId = keccak256(abi.encodePacked(_subjectHash, msg.sender, block.timestamp, _attestationIdCounter));
        
        attestations[attestationId] = Attestation({
            subjectHash: _subjectHash,
            attestationURI: _attestationURI,
            attester: msg.sender,
            stakeAmount: _stakeAmount,
            status: AttestationStatus.Pending,
            challengePeriodEnd: block.timestamp + attestationChallengePeriod,
            verificationCount: 0,
            challenger: address(0),
            challengeStake: 0,
            challengeReasonURI: "",
            resolutionTimestamp: 0,
            attestationIdCounter: _attestationIdCounter,
            nftMinted: false
        });
        attestationSubjectToId[_subjectHash] = attestationId; // Store for quick lookup (assuming single active attestation per subject)

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit AttestationSubmitted(attestationId, msg.sender, _subjectHash, _attestationURI, _stakeAmount);
    }

    /**
     * @notice Allows any participant to formally challenge an existing attestation, providing a reason and staking tokens.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonURI URI pointing to the detailed reason for the challenge.
     * @param _challengeStake The amount of Synaptic Tokens staked to back this challenge.
     */
    function challengeAttestation(bytes32 _attestationId, string calldata _reasonURI, uint256 _challengeStake) external onlyRegisteredParticipant {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attester == address(0)) revert AttestationNotFound();
        if (attestation.status != AttestationStatus.Pending) revert AttestationChallengeActive(); // Can only challenge Pending
        if (block.timestamp > attestation.challengePeriodEnd) revert AttestationChallengeNotEnded();
        if (attestation.challenger != address(0)) revert AttestationChallengeActive(); // Already under challenge

        uint256 requiredChallengeStake = (attestation.stakeAmount * challengeStakeRatio) / 10000;
        if (_challengeStake < requiredChallengeStake) revert InvalidStakeAmount();
        if (!synapticToken.transferFrom(msg.sender, address(this), _challengeStake)) revert InvalidStakeAmount();

        attestation.challenger = msg.sender;
        attestation.challengeStake = _challengeStake;
        attestation.challengeReasonURI = _reasonURI;
        attestation.status = AttestationStatus.Challenged;

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit AttestationChallenged(_attestationId, msg.sender, _reasonURI, _challengeStake);
    }

    /**
     * @notice Community members can endorse an attestation, contributing to its "truth score."
     * The weight of their endorsement is based on their effective reputation.
     * @param _attestationId The ID of the attestation to verify.
     */
    function verifyAttestation(bytes32 _attestationId) external onlyRegisteredParticipant {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attester == address(0)) revert AttestationNotFound();
        if (attestation.status != AttestationStatus.Pending) revert AttestationChallengeActive(); // Can only verify Pending
        if (block.timestamp > attestation.challengePeriodEnd) revert AttestationChallengeNotEnded(); // Can't verify after challenge period ends
        if (attestation.attester == msg.sender) revert AttestationNotBySender(); // Attester can't verify their own

        uint256 verifierReputation = _getEffectiveVotingPower(msg.sender);
        if (verifierReputation == 0) revert InsufficientReputation(); // Must have some reputation to verify

        attestation.verificationCount += verifierReputation;
        
        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit AttestationVerified(_attestationId, msg.sender, verifierReputation);
    }


    /**
     * @notice Owner/Governance resolves a challenged attestation. If challenger wins, original attester is penalized; otherwise, challenger is penalized. Stakes are distributed.
     * @dev In a full DAO, this would be subject to a governance vote for final resolution.
     * @param _attestationId The ID of the challenged attestation.
     * @param _challengerWins True if the challenger's claim is valid, false otherwise.
     */
    function resolveAttestationChallenge(bytes32 _attestationId, bool _challengerWins) external onlyOwner {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attester == address(0)) revert AttestationNotFound();
        if (attestation.status != AttestationStatus.Challenged) revert AttestationNotInChallenge();
        if (block.timestamp < attestation.challengePeriodEnd) revert AttestationChallengeNotEnded(); // Ensure challenge period has passed.

        attestation.resolutionTimestamp = block.timestamp;
        uint256 attesterShare = 0;
        uint256 challengerShare = 0;

        if (_challengerWins) {
            attestation.status = AttestationStatus.ResolvedInvalid;
            // Challenger wins: Attester loses stake, challenger gets a portion of it.
            if (attestation.stakeAmount > 0) {
                // Return half to challenger, burn half (or add to treasury)
                challengerShare = attestation.stakeAmount / 2;
                synapticToken.transfer(attestation.challenger, challengerShare);
            }
            if (attestation.challengeStake > 0) { // Return challenger's original stake
                synapticToken.transfer(attestation.challenger, attestation.challengeStake);
            }
            _adjustParticipantReputation(attestation.attester, false, attestation.stakeAmount / 10 ether); // Example reputation impact
            _adjustParticipantReputation(attestation.challenger, true, attestation.challengeStake / 10 ether);
        } else {
            attestation.status = AttestationStatus.ResolvedValid;
            // Attester wins: Attester gets their stake back + a portion of challenger's stake.
            if (attestation.stakeAmount > 0) { // Return attester's stake
                synapticToken.transfer(attestation.attester, attestation.stakeAmount);
            }
            if (attestation.challengeStake > 0) {
                // Return half to attester, burn half (or add to treasury)
                attesterShare = attestation.challengeStake / 2;
                synapticToken.transfer(attestation.attester, attesterShare);
            }
            _adjustParticipantReputation(attestation.attester, true, attestation.stakeAmount / 10 ether);
            _adjustParticipantReputation(attestation.challenger, false, attestation.challengeStake / 10 ether);
        }

        emit AttestationResolved(_attestationId, _challengerWins, attesterShare, challengerShare);
    }

    /**
     * @notice Allows an attester to revoke their own attestation if it's not currently under challenge and challenge period has not passed.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeOwnAttestation(bytes32 _attestationId) external onlyRegisteredParticipant {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attester == address(0)) revert AttestationNotFound();
        if (attestation.attester != msg.sender) revert AttestationNotBySender();
        if (attestation.status != AttestationStatus.Pending) revert AttestationChallengeActive(); // Cannot revoke if challenged or resolved.
        if (block.timestamp > attestation.challengePeriodEnd) revert AttestationChallengeNotEnded(); // Cannot revoke after challenge period ends.

        attestation.status = AttestationStatus.Revoked;
        // Return attester's stake
        synapticToken.transfer(msg.sender, attestation.stakeAmount);
        attestation.stakeAmount = 0; // Clear stake
        
        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit AttestationRevoked(_attestationId, msg.sender);
    }

    // IV. Predictive Forecasting Markets
    /**
     * @notice Initiates a new prediction market, defining its question, resolution time, and minimum stake.
     * @param _marketHash A hash uniquely identifying the market (e.g., IPFS CID of the question details).
     * @param _questionURI URI pointing to the detailed question and terms of the forecast.
     * @param _resolutionTimestamp The timestamp at which the forecast should be resolved.
     * @param _entryStake Minimum tokens required to participate in this market.
     */
    function createForecastMarket(bytes32 _marketHash, string calldata _questionURI, uint256 _resolutionTimestamp, uint256 _entryStake) external onlyRegisteredParticipant {
        if (_resolutionTimestamp <= block.timestamp) revert ForecastMarketNotOpen();
        if (_entryStake < minForecastStake) revert InvalidStakeAmount();
        
        forecastMarkets[_marketHash] = ForecastMarket({
            questionURI: _questionURI,
            creator: msg.sender,
            resolutionTimestamp: _resolutionTimestamp,
            entryStake: _entryStake,
            status: ForecastStatus.Open,
            resolvedOutcome: false, // Default
            totalStakedForTrue: 0,
            totalStakedForFalse: 0
        });

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit ForecastMarketCreated(_marketHash, msg.sender, _questionURI, _resolutionTimestamp, _entryStake);
    }

    /**
     * @notice Participants stake tokens on their predicted outcome (true/false) for a specified market.
     * @param _marketId The ID of the forecast market.
     * @param _predictionOutcome The participant's predicted outcome (true for 'yes', false for 'no').
     * @param _stakeAmount The amount of Synaptic Tokens staked on this prediction.
     */
    function participateInForecast(bytes32 _marketId, bool _predictionOutcome, uint256 _stakeAmount) external onlyRegisteredParticipant {
        ForecastMarket storage market = forecastMarkets[_marketId];
        if (market.creator == address(0)) revert ForecastMarketNotFound();
        if (market.status != ForecastStatus.Open || block.timestamp >= market.resolutionTimestamp) revert ForecastMarketNotOpen();
        if (_stakeAmount < market.entryStake) revert InvalidStakeAmount();
        if (market.predictions[msg.sender].stake > 0) revert PredictionAlreadyMade(); // Only one prediction per market

        if (!synapticToken.transferFrom(msg.sender, address(this), _stakeAmount)) revert InvalidStakeAmount();

        market.predictions[msg.sender] = Prediction({
            outcome: _predictionOutcome,
            stake: _stakeAmount,
            claimed: false
        });

        if (_predictionOutcome) {
            market.totalStakedForTrue += _stakeAmount;
        } else {
            market.totalStakedForFalse += _stakeAmount;
        }

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit ForecastParticipated(_marketId, msg.sender, _predictionOutcome, _stakeAmount);
    }

    /**
     * @notice An authorized entity (e.g., oracle, governance) submits the definitive outcome for a resolved prediction market.
     * @dev This function is `onlyOwner` for simplicity, but in a production system, it would integrate with a decentralized oracle network.
     * @param _marketId The ID of the forecast market to resolve.
     * @param _actualOutcome The definitive outcome of the market (true or false).
     */
    function submitForecastOutcome(bytes32 _marketId, bool _actualOutcome) external onlyOwner {
        ForecastMarket storage market = forecastMarkets[_marketId];
        if (market.creator == address(0)) revert ForecastMarketNotFound();
        if (market.status != ForecastStatus.Open) revert ForecastMarketAlreadyResolved();
        if (block.timestamp < market.resolutionTimestamp) revert ForecastMarketNotOpen(); // Cannot resolve before resolution time.
        if (block.timestamp > market.resolutionTimestamp + forecastResolutionPeriod) revert ForecastMarketNotOpen(); // Cannot resolve after resolution period

        market.resolvedOutcome = _actualOutcome;
        market.status = ForecastStatus.Resolved;

        emit ForecastOutcomeSubmitted(_marketId, _actualOutcome);
    }

    /**
     * @notice Allows participants with correct predictions to claim their share of the prize pool and earn reputation.
     * @param _marketId The ID of the forecast market.
     */
    function claimForecastRewards(bytes32 _marketId) external onlyRegisteredParticipant {
        ForecastMarket storage market = forecastMarkets[_marketId];
        if (market.creator == address(0)) revert ForecastMarketNotFound();
        if (market.status != ForecastStatus.Resolved) revert ForecastMarketNotResolved();

        Prediction storage prediction = market.predictions[msg.sender];
        if (prediction.stake == 0 || prediction.claimed) revert NoRewardsToClaim();

        uint256 totalPool = market.totalStakedForTrue + market.totalStakedForFalse;
        uint256 rewardAmount = 0;
        uint256 reputationEarned = 0;

        if (prediction.outcome == market.resolvedOutcome) {
            // Correct prediction
            uint256 winningPool = (market.resolvedOutcome) ? market.totalStakedForTrue : market.totalStakedForFalse;
            if (winningPool == 0) revert NoRewardsToClaim(); // Should not happen if there are participants
            rewardAmount = (prediction.stake * totalPool) / winningPool; // Proportional share of the total pool
            
            synapticToken.transfer(msg.sender, rewardAmount);
            reputationEarned = prediction.stake / (1 ether); // Example: reputation proportional to stake
            _adjustParticipantReputation(msg.sender, true, reputationEarned);
        } else {
            // Incorrect prediction: stake is lost (remains in contract treasury)
            _adjustParticipantReputation(msg.sender, false, prediction.stake / (2 ether)); // Minor reputation loss
        }
        
        prediction.claimed = true;
        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit ForecastRewardsClaimed(_marketId, msg.sender, rewardAmount, reputationEarned);
    }

    // V. Dynamic Reputation Management
    /**
     * @notice Computes and returns a participant's current dynamic reputation score, based on their track record, activity, and decay.
     *         This is the participant's personal, non-delegated, decayed reputation.
     * @param _participant The address of the participant.
     * @return The calculated personal reputation score.
     */
    function getReputationScore(address _participant) public view returns (uint256) {
        Participant storage p = participants[_participant];
        if (!p.isRegistered) return 0;

        uint256 baseReputation = 0;
        if (p.totalContributions > 0) {
            baseReputation = (p.accurateContributions * REPUTATION_MULTIPLIER) / p.totalContributions;
        }

        // Apply decay based on inactivity
        uint256 timeSinceLastActive = block.timestamp - p.lastActiveTimestamp;
        uint256 decayPeriods = timeSinceLastActive / 31536000; // Roughly 1 year in seconds
        
        uint256 currentReputation = baseReputation;
        for (uint256 i = 0; i < decayPeriods; i++) {
            currentReputation = (currentReputation * (REPUTATION_MULTIPLIER - reputationDecayRate)) / REPUTATION_MULTIPLIER;
            if (currentReputation == 0 && baseReputation > 0) break; // Avoid unnecessary calculations if reputation hits zero
        }

        return currentReputation;
    }

    /**
     * @dev Internal function to adjust a participant's accurate/total contribution counts for reputation.
     * This is a simplified model. A robust system would track different types of contributions and their weights.
     * @param _participant The address of the participant.
     * @param _isAccurate True if the contribution was accurate/positive, false otherwise.
     * @param _points The 'point' value of this contribution for reputation calculation.
     */
    function _adjustParticipantReputation(address _participant, bool _isAccurate, uint256 _points) internal {
        Participant storage p = participants[_participant];
        if (!p.isRegistered) return; // Cannot adjust reputation for unregistered users

        p.totalContributions += _points;
        if (_isAccurate) {
            p.accurateContributions += _points;
        }
        p.lastActiveTimestamp = block.timestamp;
    }

    /**
     * @notice Allows a participant to delegate a portion of their *reputation points* to another.
     *         This affects their effective voting power.
     * @param _delegatee The address of the participant to delegate reputation to.
     * @param _amount The amount of reputation points to delegate.
     */
    function delegateReputation(address _delegatee, uint256 _amount) external onlyRegisteredParticipant {
        if (!participants[_delegatee].isRegistered) revert NotRegisteredParticipant();
        if (_amount == 0) revert DelegationFailed();
        if (_delegatee == msg.sender) revert DelegationFailed(); // Cannot delegate to self

        // We check against the participant's current accurateContributions as the pool of delegatable raw points
        // to avoid issues with dynamic decay in getReputationScore.
        // This means reputation is conceptual points, not tokens.
        if (participants[msg.sender].accurateContributions < _amount + totalDelegatedReputationOut[msg.sender]) revert InsufficientReputation();

        totalDelegatedReputationOut[msg.sender] += _amount;
        totalDelegatedReputationIn[_delegatee] += _amount;

        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @notice Allows a participant to revoke a previous reputation delegation.
     * @param _delegatee The address of the participant from whom to revoke delegation.
     * @param _amount The amount of reputation points to undelegate.
     */
    function undelegateReputation(address _delegatee, uint256 _amount) external onlyRegisteredParticipant {
        if (totalDelegatedReputationOut[msg.sender] < _amount) revert NoDelegationFound();
        if (_amount == 0) revert DelegationFailed();
        
        totalDelegatedReputationOut[msg.sender] -= _amount;
        // Ensure that totalDelegatedReputationIn[_delegatee] doesn't underflow, assuming _delegatee has enough.
        // In a complex system, this might need more robust checks or a queue system.
        totalDelegatedReputationIn[_delegatee] = totalDelegatedReputationIn[_delegatee] > _amount ? totalDelegatedReputationIn[_delegatee] - _amount : 0;

        emit ReputationUndelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @notice A governance-controlled function to penalize participants by reducing their reputation for proven malicious activities.
     * @dev This function is `onlyOwner` for simplicity. In a production DAO, this would be triggered by a specific governance vote.
     * @param _participant The address of the participant whose reputation is to be slashed.
     * @param _amount The amount of reputation points to slash.
     * @param _reasonURI URI explaining the reason for the slashing.
     */
    function slashReputation(address _participant, uint256 _amount, string calldata _reasonURI) external onlyOwner {
        if (!participants[_participant].isRegistered) revert NotRegisteredParticipant();
        
        // This simplifies slashing by directly decreasing accurateContributions and increasing totalContributions
        // to worsen the reputation ratio.
        if (participants[_participant].accurateContributions < _amount) {
             participants[_participant].accurateContributions = 0;
        } else {
             participants[_participant].accurateContributions -= _amount;
        }
        participants[_participant].totalContributions += _amount; // Adding to total without accurate decreases the ratio

        participants[_participant].lastActiveTimestamp = block.timestamp; // Mark activity
        emit ReputationSlashed(_participant, _amount, _reasonURI);
    }

    /**
     * @dev Internal function to calculate a participant's effective voting power, including delegated reputation.
     * @param _participant The address of the participant.
     * @return The total effective reputation score for voting.
     */
    function _getEffectiveVotingPower(address _participant) internal view returns (uint256) {
        uint256 personalReputation = getReputationScore(_participant);
        return personalReputation + totalDelegatedReputationIn[_participant] - totalDelegatedReputationOut[_participant];
    }

    // VI. Adaptive Governance & Treasury
    /**
     * @notice Participants meeting a minimum reputation threshold can propose initiatives requiring funding from the network's treasury.
     * @param _proposalURI URI pointing to the detailed content of the proposal.
     * @param _fundingAmount The amount of tokens requested from the treasury.
     * @param _recipient The address to receive the funds if the proposal passes.
     */
    function proposeInitiative(string calldata _proposalURI, uint256 _fundingAmount, address _recipient) external onlyRegisteredParticipant {
        if (_getEffectiveVotingPower(msg.sender) < minReputationToPropose) revert InsufficientReputationToPropose();
        
        bytes32 proposalId = keccak256(abi.encodePacked(_proposalURI, msg.sender, block.timestamp, _fundingAmount));

        proposals[proposalId] = Proposal({
            proposalURI: _proposalURI,
            proposer: msg.sender,
            fundingAmount: _fundingAmount,
            recipient: _recipient,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            creationTimestamp: block.timestamp,
            proposalPeriodEnd: block.timestamp + 7 days, // Example: 7 days voting period
            executed: false
        });

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit ProposalSubmitted(proposalId, msg.sender, _proposalURI, _fundingAmount, _recipient);
    }

    /**
     * @notice Registered participants cast votes on proposals, with their voting power weighted by their effective reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote 'for', false to vote 'against'.
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external onlyRegisteredParticipant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert ProposalNotOpen();
        if (block.timestamp > proposal.proposalPeriodEnd) revert ProposalNotOpen();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 votingPower = _getEffectiveVotingPower(msg.sender);
        if (votingPower == 0) revert InsufficientReputation();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
            proposal.totalReputationFor += votingPower;
        } else {
            proposal.votesAgainst++;
            proposal.totalReputationAgainst += votingPower;
        }

        participants[msg.sender].lastActiveTimestamp = block.timestamp;
        emit VotedOnProposal(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a proposal that has successfully passed the voting phase and quorum requirements, transferring the specified funds.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) external onlyRegisteredParticipant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert ProposalAlreadyExecuted(); // Can only execute pending
        if (block.timestamp <= proposal.proposalPeriodEnd) revert ProposalNotOpen(); // Voting period must have ended
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Use mock total network reputation for quorum check. In production, this would be a snapshot.
        uint256 currentTotalNetworkReputation = MOCK_TOTAL_NETWORK_REPUTATION; 
        
        uint256 totalReputationCast = proposal.totalReputationFor + proposal.totalReputationAgainst;
        if (totalReputationCast == 0) { // No votes cast, reject by default
            proposal.status = ProposalStatus.Rejected;
            return;
        }

        // Check quorum: Total reputation cast must be at least quorumPercentage of total network reputation
        if ((totalReputationCast * 10000) / currentTotalNetworkReputation < quorumPercentage) {
            proposal.status = ProposalStatus.Rejected;
            return;
        }

        // Check approval: Votes For must be > Votes Against (or a specific threshold)
        if (proposal.totalReputationFor > proposal.totalReputationAgainst) {
            proposal.status = ProposalStatus.Approved;
            if (proposal.fundingAmount > 0) {
                if (synapticToken.balanceOf(address(this)) < proposal.fundingAmount) revert InsufficientFunds();
                synapticToken.transfer(proposal.recipient, proposal.fundingAmount);
            }
            proposal.executed = true;
            proposal.executionTimestamp = block.timestamp;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    /**
     * @notice Allows governance to dynamically adjust parameters specific to the governance process itself, such as minimum reputation for proposing or the required voting quorum.
     * @dev This function is typically called as a result of a successful governance proposal.
     * @param _minReputationToPropose New minimum reputation required to submit a governance proposal.
     * @param _quorumPercentage New percentage of total reputation needed for a proposal to pass (e.g., 3000 for 30%).
     */
    function updateGovernanceParameters(uint256 _minReputationToPropose, uint256 _quorumPercentage) external onlyOwner { // Similar to setProtocolParameters, callable by successful governance vote
        minReputationToPropose = _minReputationToPropose;
        quorumPercentage = _quorumPercentage;
        emit GovernanceParametersUpdated(_minReputationToPropose, _quorumPercentage);
    }

    // VII. Knowledge-Bound NFTs (AttestationNFTs)
    /**
     * @notice Mints a unique ERC721 NFT for a *verified and highly reputable* attestation, transferring ownership to `_to`.
     * @dev Requires the attestation to be `ResolvedValid` and to have a high enough `verificationCount`
     *      relative to the attester's own reputation score, ensuring community endorsement.
     * @param _attestationId The ID of the attestation for which to mint an NFT.
     * @param _to The address to which the Attestation NFT will be minted.
     */
    function mintAttestationNFT(bytes32 _attestationId, address _to) external onlyRegisteredParticipant {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attester == address(0)) revert AttestationNotFound();
        if (attestation.status != AttestationStatus.ResolvedValid) revert AttestationNotVerifiedEnough();
        
        // Example criterion for "highly reputable": verificationCount must be at least 2x attester's personal reputation.
        // This incentivizes highly reputable attestations and strong community backing.
        if (attestation.verificationCount < (getReputationScore(attestation.attester) * 2)) revert AttestationNotVerifiedEnough();
        if (attestation.nftMinted) revert AttestationNFTAlreadyMinted();

        attestationNFT.mint(_to, attestation.attestationIdCounter, attestation.attestationURI);
        attestation.nftMinted = true;
        emit AttestationNFTMinted(_attestationId, attestation.attestationIdCounter, _to);
    }

    /**
     * @notice Standard ERC721 function to transfer ownership of an Attestation NFT.
     * @dev This delegates the call to the actual AttestationNFT contract. The `msg.sender` must be the owner of the NFT or approved.
     * @param _from The current owner of the NFT.
     * @param _to The recipient of the NFT.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferAttestationNFT(address _from, address _to, uint252 _tokenId) external onlyRegisteredParticipant {
        // The ERC721 standard functions (transferFrom, safeTransferFrom) typically include ownership and approval checks.
        // By calling `attestationNFT.transferFrom`, we rely on the ERC721 contract's implementation of these checks.
        // `msg.sender` must be `_from` or approved to transfer for `attestationNFT` contract.
        attestationNFT.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @notice Standard ERC721 function to burn an Attestation NFT.
     * @dev This delegates the call to the actual AttestationNFT contract. The `msg.sender` must be the owner of the NFT or approved.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnAttestationNFT(uint252 _tokenId) external onlyRegisteredParticipant {
        // Similar to transfer, assuming the NFT contract handles ownership checks.
        // The caller (msg.sender) must be the owner of the NFT or approved.
        attestationNFT.burn(_tokenId);
    }
}
```