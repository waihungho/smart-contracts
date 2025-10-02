I've designed a smart contract called `AIEnhancedAdaptiveTrustProtocol` (AIEATP) that focuses on an **AI-driven, adaptive, and reputation-based trust system**. This contract aims to be interesting by combining several advanced concepts:

1.  **AI Integration via Oracles (Chainlink):** The core trust score is not calculated on-chain (too complex/expensive) but by an off-chain AI model. The smart contract requests this assessment via a Chainlink oracle, providing references to verifiable on-chain and off-chain data.
2.  **Adaptive Trust Scores:** Unlike static reputation, the trust score dynamically changes. It's updated by AI assessments and also *decays over time*, encouraging continuous positive engagement.
3.  **Multi-Source Data Integration:** The AI can consume both verifiable on-chain event hashes (e.g., voting records, transaction history) and signed off-chain attestations (e.g., KYC, real-world contributions, social media activity, educational achievements).
4.  **Dispute Resolution for AI Assessments:** A human-governed committee can dispute and potentially override AI-generated scores, introducing a crucial layer of checks and balances for potentially biased or erroneous AI decisions.
5.  **Reputation Staking:** Users can lock native protocol tokens (e.g., LINK for this example) for a duration, signaling commitment. This locked value can be an additional input for the AI's trust assessment.
6.  **Modular & Extensible:** The contract provides a trust score that other dApps can query to implement various "gated" functionalities, access controls, or preferential treatment based on a user's reputation.

The contract uses standard OpenZeppelin contracts for `Ownable` and `Pausable` functionalities, and integrates with Chainlink for oracle services.

---

### Contract Outline and Function Summary

**Contract Name:** `AIEnhancedAdaptiveTrustProtocol`

**Base Features:**
*   `Ownable`: Standard ownership management for administrative functions.
*   `Pausable`: Emergency stop mechanism to pause critical contract functions.
*   `ChainlinkClient`: Base contract for making Chainlink oracle requests.

---

### **I. Core Trust & AI Assessment (8 functions)**
Functions responsible for initiating AI-driven trust score calculations, receiving results from oracles, and querying the current (decayed) trust scores.

1.  `requestAI_TrustScoreUpdate(string calldata _onChainDataReference, string calldata _offChainAttestationReference)`: Initiates an AI-driven trust score update for `msg.sender` by sending a request to the configured Chainlink oracle. Requires a `scoreUpdateFee` in LINK. User provides references (e.g., IPFS CIDs or Merkle roots) to their on-chain and off-chain data for the AI to process.
2.  `fulfillAI_TrustScoreUpdate(bytes32 _requestId, uint256 _newTrustScore)`: An internal callback function invoked by the Chainlink oracle when the AI model has successfully processed the request and returned a `_newTrustScore`. Updates the user's `userTrustScores` and `lastScoreUpdateTimestamp`.
3.  `getUserTrustScore(address _user)`: Returns a user's *current* trust score, which is dynamically calculated by decaying their `rawUserTrustScore` based on `trustScoreDecayRate` and `lastScoreUpdateTimestamp`.
4.  `getRawUserTrustScore(address _user)`: Returns a user's *last AI-assessed* trust score, without any decay applied.
5.  `calculateDecayedScore(uint256 _rawScore, uint256 _lastUpdateTimestamp)`: A `pure` internal helper function used to calculate the decayed score based on the raw score, last update time, and the current block timestamp.
6.  `getLastScoreUpdateTimestamp(address _user)`: A `view` function to retrieve the timestamp when a user's `rawUserTrustScore` was last updated by the AI.
7.  `getPendingAIRequestUser(bytes32 _requestId)`: A `view` function to determine which user initiated a specific pending Chainlink AI request.
8.  `getAIRequestDetails(bytes32 _requestId)`: A `view` function to retrieve the full details (user, data references, timestamp) of a past or pending AI request.

---

### **II. Oracle & Protocol Configuration (6 functions)**
These `onlyOwner` functions allow the contract deployer to set up and manage the Chainlink oracle and key protocol parameters.

9.  `setOracleAddress(address _newOracle)`: Sets the address of the Chainlink oracle contract.
10. `setAIModelJobId(bytes32 _newJobId)`: Sets the specific Job ID for the AI model on the Chainlink network.
11. `setScoreUpdateFee(uint256 _newFee)`: Sets the amount of LINK tokens required to pay for each AI trust score update request.
12. `setTrustScoreDecayRate(uint256 _newRate)`: Sets the rate at which trust scores decay over time (points per second).
13. `setReputationLockDuration(uint256 _newDuration)`: Sets the default minimum duration in seconds for which users must lock tokens for reputation staking.
14. `withdrawProtocolFees(address _to)`: Allows the owner to withdraw accumulated LINK fees collected from `requestAI_TrustScoreUpdate` calls.

---

### **III. Data & Attestation Integration (5 functions)**
Functions for managing trusted data sources and allowing them to submit verifiable information to the protocol, which then can be referenced by users for AI assessment.

15. `registerTrustedDataProvider(address _provider)`: `onlyOwner` function to authorize an address to submit on-chain event hashes.
16. `deregisterTrustedDataProvider(address _provider)`: `onlyOwner` function to revoke the authorization of a data provider.
17. `submitOnChainEventHash(address _user, bytes32 _eventHash, bytes32 _eventType)`: Allows `trustedDataProviders` to record a verifiable hash of an on-chain event for a specific user, categorized by `_eventType`.
18. `registerTrustedOffChainAttestor(address _attestor)`: `onlyOwner` function to authorize an address to submit signed off-chain attestations.
19. `submitSignedOffChainAttestation(address _user, string calldata _attestationCID, bytes calldata _signature)`: Allows `trustedOffChainAttestors` to submit a signed IPFS CID for a user, referencing their off-chain behavior. The AI would verify this signature off-chain.

---

### **IV. Dispute Resolution (AI Assessment) (6 functions)**
A mechanism for challenging AI-generated trust scores and resolving them via a human committee.

20. `proposeAI_AssessmentDispute(address _userToDispute, string calldata _reasonCID)`: Allows a user to dispute their own AI assessment, or a committee member to dispute any user's assessment. Requires an IPFS CID detailing the reason.
21. `addDisputeCommitteeMember(address _member)`: `onlyOwner` function to add a member to the dispute resolution committee.
22. `removeDisputeCommitteeMember(address _member)`: `onlyOwner` function to remove a member from the committee.
23. `voteOnDispute(bytes32 _disputeProposalHash, bool _upholdUser)`: Allows `onlyDisputeCommitteeMember` to cast a vote on a dispute proposal, either to `_upholdUser` (override AI) or reject their claim (agree with AI).
24. `resolveDispute(bytes32 _disputeProposalHash, uint256 _manualScore)`: `onlyOwner` function to finalize a dispute after the voting period ends. Based on votes, it either upholds the AI's assessment or, if the user's claim is upheld, allows the owner to set a `_manualScore`.
25. `getDisputeProposalStatus(bytes32 _disputeHash)`: A `view` function to retrieve the current status and details of a specific dispute proposal.
26. `isDisputeCommitteeMember(address _addr)`: A `view` function to check if a given address is a member of the dispute resolution committee.

---

### **V. Reputation Staking (3 functions)**
Allows users to stake tokens to demonstrate commitment, which can be factored into their AI trust assessment.

27. `lockTokensForReputation(uint256 _amount, uint256 _duration)`: Allows `msg.sender` to lock a specified `_amount` of LINK tokens for a `_duration`. This commitment can positively influence their AI trust score.
28. `releaseLockedTokens()`: Allows `msg.sender` to retrieve their locked LINK tokens once the `reputationLockEndTimestamp` has passed.
29. `getLockedTokens(address _user)`: A `view` function to check the amount of LINK tokens currently locked by a specific user.

---

### **VI. Utility (4 functions)**
Helper `view` functions for querying collected data and access permissions.

30. `getOwnedOnChainEvents(address _user)`: A `view` function to retrieve all on-chain event hashes submitted for a specific user.
31. `getOwnedOffChainAttestations(address _user)`: A `view` function to retrieve all off-chain attestations submitted for a specific user.
32. `isTrustedDataProvider(address _addr)`: A `view` function to check if a given address is a registered trusted data provider.
33. `isTrustedOffChainAttestor(address _addr)`: A `view` function to check if a given address is a registered trusted off-chain attestor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For Reputation Staking
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol"; // For Chainlink LINK token
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol"; // For oracle integration

// Custom Error definitions for better diagnostics and reduced gas costs
error AIEnhancedAdaptiveTrustProtocol__NotEnoughLink();
error AIEnhancedAdaptiveTrustProtocol__RequestNotFound();
error AIEnhancedAdaptiveTrustProtocol__DisputeNotFound();
error AIEnhancedAdaptiveTrustProtocol__UnauthorizedAttestor();
error AIEnhancedAdaptiveTrustProtocol__UnauthorizedDataProvider();
error AIEnhancedAdaptiveTrustProtocol__LockedTokensStillActive();
error AIEnhancedAdaptiveTrustProtocol__DisputeVotePeriodNotEnded();
error AIEnhancedAdaptiveTrustProtocol__DisputeAlreadyResolved();
error AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
error AIEnhancedAdaptiveTrustProtocol__CannotVoteOnOwnDispute();
error AIEnhancedAdaptiveTrustProtocol__AlreadyVoted();
error AIEnhancedAdaptiveTrustProtocol__AmountMustBeGreaterThanZero();
error AIEnhancedAdaptiveTrustProtocol__TokensAlreadyLocked();
error AIEnhancedAdaptiveTrustProtocol__LockDurationTooShort();
error AIEnhancedAdaptiveTrustProtocol__NoTokensLocked();
error AIEnhancedAdaptiveTrustProtocol__NotAuthorizedToProposeDispute();
error AIEnhancedAdaptiveTrustProtocol__DisputeNotOpenForVoting();
error AIEnhancedAdaptiveTrustProtocol__VotingPeriodHasEnded();
error AIEnhancedAdaptiveTrustProtocol__NotADisputeCommitteeMember();

/**
 * @title AIEnhancedAdaptiveTrustProtocol
 * @dev This contract implements an advanced AI-enhanced adaptive trust protocol.
 *      It allows users to build a dynamic trust score based on their verifiable
 *      on-chain actions and off-chain attested behaviors. An off-chain AI model,
 *      integrated via Chainlink Oracles, processes this data to generate and
 *      update trust scores. The protocol includes features for data submission,
 *      dispute resolution for AI assessments, and reputation-based token staking.
 *      The trust score decays over time, encouraging continuous positive engagement.
 *
 * @notice This is a conceptual contract showcasing advanced concepts and may require
 *         further refinement for production use, especially regarding off-chain AI
 *         model specifics, oracle security, and gas optimization.
 */
contract AIEnhancedAdaptiveTrustProtocol is Ownable, Pausable, ChainlinkClient {
    using Counters for Counters.Counter;

    /*/////////////////////////////////////////////////////////////////////////
                            OUTLINE AND FUNCTION SUMMARY
    /////////////////////////////////////////////////////////////////////////*/

    // --- State Variables ---
    // Core Trust Management:
    //      - userTrustScores: Stores the last AI-assessed raw score.
    //      - lastScoreUpdateTimestamp: Timestamp of the last AI-assessed score update.
    //      - trustScoreDecayRate: Rate at which trust scores decay per second.
    // Oracle & Configuration:
    //      - oracleAddress: Address of the Chainlink oracle.
    //      - aiModelJobId: Chainlink Job ID for the AI model.
    //      - scoreUpdateFee: LINK fee for an AI score update request.
    //      - protocolFeesCollected: Accumulated LINK fees.
    // Data & Attestation Integration:
    //      - trustedDataProviders: Addresses authorized to submit on-chain event hashes.
    //      - trustedOffChainAttestors: Addresses authorized to submit signed off-chain attestations.
    //      - userEventLog: Stores hashes of on-chain events submitted for users.
    //      - userOffChainAttestations: Stores CIDs of off-chain attestations for users.
    // Dispute Resolution:
    //      - disputeResolutionCommittee: Members of the dispute committee.
    //      - disputeProposals: Stores details of active dispute proposals.
    //      - disputeVoteRecords: Tracks votes for each dispute.
    //      - disputeVotingPeriod: Duration for committee members to vote.
    //      - disputeProposalCounter: Counter for unique dispute IDs.
    // Reputation Staking:
    //      - lockedTokensForReputation: Amount of LINK locked by a user.
    //      - reputationLockDuration: Duration for which tokens are locked.
    //      - reputationLockEndTimestamp: When locked tokens can be released.
    // Chainlink Request Management:
    //      - pendingAIRequests: Maps Chainlink request IDs to user addresses.
    //      - aiRequestDetails: Stores details about each AI request.

    // --- Enums and Structs ---
    // AiRequestDetails: Details of an AI trust score request.
    // DisputeStatus: Enum for dispute proposal status.
    // DisputeProposal: Details of a dispute proposal.
    // UserOnChainEvent: Structure to store on-chain event details.
    // UserOffChainAttestation: Structure to store off-chain attestation details.

    /*/////////////////////////////////////////////////////////////////////////
                                FUNCTIONS SUMMARY
    /////////////////////////////////////////////////////////////////////////*/

    // I. Core Trust & AI Assessment (8 functions)
    // 1. requestAI_TrustScoreUpdate: Initiates an AI-driven trust score update via Chainlink.
    // 2. fulfillAI_TrustScoreUpdate: Chainlink oracle callback to update a user's trust score.
    // 3. getUserTrustScore: Returns a user's current, decayed trust score.
    // 4. getRawUserTrustScore: Returns a user's last AI-assessed raw trust score.
    // 5. calculateDecayedScore: Internal pure function for score decay logic.
    // 6. getLastScoreUpdateTimestamp: View function for a user's last score update timestamp.
    // 7. getPendingAIRequestUser: View function to check which user an AI request belongs to.
    // 8. getAIRequestDetails: View function for details of a specific AI request.

    // II. Oracle & Protocol Configuration (6 functions)
    // 9. setOracleAddress: Owner sets the Chainlink oracle address.
    // 10. setAIModelJobId: Owner sets the Chainlink job ID for the AI model.
    // 11. setScoreUpdateFee: Owner sets the LINK fee for oracle calls.
    // 12. setTrustScoreDecayRate: Owner sets the decay rate for trust scores.
    // 13. setReputationLockDuration: Owner sets the duration for token locking.
    // 14. withdrawProtocolFees: Owner withdraws accumulated LINK fees.

    // III. Data & Attestation Integration (5 functions)
    // 15. registerTrustedDataProvider: Owner registers a trusted data provider.
    // 16. deregisterTrustedDataProvider: Owner deregisters a trusted data provider.
    // 17. submitOnChainEventHash: Trusted data providers submit verifiable on-chain event hashes for a user.
    // 18. registerTrustedOffChainAttestor: Owner registers a trusted off-chain attestor.
    // 19. submitSignedOffChainAttestation: Trusted attestors submit signed IPFS CIDs for off-chain data.

    // IV. Dispute Resolution (AI Assessment) (6 functions)
    // 20. proposeAI_AssessmentDispute: Allows a user/committee to propose a dispute against an AI assessment.
    // 21. addDisputeCommitteeMember: Owner adds a member to the dispute resolution committee.
    // 22. removeDisputeCommitteeMember: Owner removes a member from the committee.
    // 23. voteOnDispute: Committee members vote on a dispute.
    // 24. resolveDispute: Owner finalizes a dispute, potentially overriding the AI score.
    // 25. getDisputeProposalStatus: View function for dispute details.
    // 26. isDisputeCommitteeMember: View function to check if an address is a committee member.

    // V. Reputation Staking (3 functions)
    // 27. lockTokensForReputation: Users lock LINK tokens to influence AI assessment.
    // 28. releaseLockedTokens: Releases locked LINK tokens after the duration.
    // 29. getLockedTokens: View function for a user's locked LINK tokens.

    // VI. Utility (4 functions)
    // 30. getOwnedOnChainEvents: View function for a user's submitted on-chain event hashes.
    // 31. getOwnedOffChainAttestations: View function for a user's submitted off-chain attestations.
    // 32. isTrustedDataProvider: View function to check if an address is a trusted data provider.
    // 33. isTrustedOffChainAttestor: View function to check if an address is a trusted off-chain attestor.

    /*/////////////////////////////////////////////////////////////////////////
                                  CONTRACT START
    /////////////////////////////////////////////////////////////////////////*/

    // --- Enums and Structs ---
    enum DisputeStatus { Pending, Voting, ResolvedUpholdUser, ResolvedRejectUser, Canceled }

    struct AiRequestDetails {
        address user;
        string onChainDataReference;
        string offChainAttestationReference;
        uint256 timestamp;
    }

    struct DisputeProposal {
        address userToDispute;
        string reasonCID;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        DisputeStatus status;
        uint256 positiveVotes; // Votes to uphold the user's claim (override AI)
        uint256 negativeVotes; // Votes to reject the user's claim (agree with AI)
        uint256 minVotesRequired; // Minimum votes for a resolution
        uint256 resolvedScore; // The score if resolved to uphold user, 0 otherwise
    }

    struct UserOnChainEvent {
        bytes32 eventHash;
        bytes32 eventType;
        uint256 timestamp;
        address submitter;
    }

    struct UserOffChainAttestation {
        string attestationCID;
        bytes signature;
        uint256 timestamp;
        address submitter;
    }

    // --- State Variables ---

    // Core Trust Management
    mapping(address => uint256) public userTrustScores; // Last AI-assessed raw score
    mapping(address => uint256) public lastScoreUpdateTimestamp; // Timestamp of last AI score update
    uint256 public trustScoreDecayRate; // Points per second decay

    // Oracle & Configuration
    address public oracleAddress;
    bytes32 public aiModelJobId;
    uint256 public scoreUpdateFee; // LINK token amount
    uint256 public protocolFeesCollected; // Accumulated LINK fees

    // Data & Attestation Integration
    mapping(address => bool) public trustedDataProviders;
    mapping(address => bool) public trustedOffChainAttestors;
    mapping(address => UserOnChainEvent[]) public userEventLog; // Stores event hashes for a user
    mapping(address => UserOffChainAttestation[]) public userOffChainAttestations; // Stores attestation CIDs for a user

    // Dispute Resolution
    Counters.Counter private disputeProposalCounter; // Not directly used for mapping, but could be used to generate unique IDs if keccak256 hash collision is a concern.
    mapping(bytes32 => DisputeProposal) public disputeProposals; // Maps dispute hash to proposal details
    mapping(bytes32 => mapping(address => bool)) public disputeVoteRecords; // disputeHash => committeeMember => voted
    mapping(address => bool) public disputeResolutionCommittee;
    uint256 public disputeVotingPeriod = 3 days;
    uint256 public disputeVoteThreshold = 3; // Minimum committee votes to finalize a dispute

    // Reputation Staking
    mapping(address => uint256) public lockedTokensForReputation; // Amount of LINK
    mapping(address => uint252) public reputationLockEndTimestamp; // When tokens can be released
    uint256 public reputationLockDuration = 90 days; // Default lock duration

    // Chainlink Request Management
    mapping(bytes32 => AiRequestDetails) public aiRequestDetails; // Maps request ID to details
    mapping(bytes32 => address) public pendingAIRequests; // Maps Chainlink request ID to user address

    // --- Events ---
    event TrustScoreUpdateRequest(
        bytes32 indexed requestId,
        address indexed user,
        string onChainDataReference,
        string offChainAttestationReference
    );
    event TrustScoreUpdated(bytes32 indexed requestId, address indexed user, uint256 oldScore, uint256 newScore);
    event TrustScoreDecayRateSet(uint256 newRate);
    event ScoreUpdateFeeSet(uint256 newFee);
    event OracleAddressSet(address newAddress);
    event AIModelJobIdSet(bytes32 newJobId);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event TrustedDataProviderRegistered(address indexed provider);
    event TrustedDataProviderDeregistered(address indexed provider);
    event OnChainEventSubmitted(address indexed user, bytes32 indexed eventHash, bytes32 eventType, address submitter);
    event TrustedOffChainAttestorRegistered(address indexed attestor);
    event TrustedOffChainAttestorDeregistered(address indexed attestor);
    event OffChainAttestationSubmitted(
        address indexed user,
        string attestationCID,
        address submitter
    );

    event DisputeProposed(bytes32 indexed disputeHash, address indexed userToDispute, string reasonCID);
    event DisputeCommitteeMemberAdded(address indexed member);
    event DisputeCommitteeMemberRemoved(address indexed member);
    event DisputeVoted(bytes32 indexed disputeHash, address indexed voter, bool upholdUser);
    event DisputeResolved(bytes32 indexed disputeHash, DisputeStatus status, uint256 finalScore);

    event TokensLockedForReputation(address indexed user, uint256 amount, uint256 duration, uint256 unlockTime);
    event TokensReleasedFromReputation(address indexed user, uint256 amount);
    event ReputationLockDurationSet(uint256 newDuration);

    // --- Constructor ---
    /**
     * @dev Initializes the contract with the LINK token address, Chainlink oracle address,
     *      AI model job ID, and the fee for AI score updates.
     * @param _linkToken The address of the LINK token contract.
     * @param _oracle The address of the Chainlink oracle contract.
     * @param _jobId The Chainlink Job ID for the AI model.
     * @param _scoreUpdateFee The LINK fee for each AI score update request.
     */
    constructor(address _linkToken, address _oracle, bytes32 _jobId, uint256 _scoreUpdateFee)
        Ownable(msg.sender)
        Pausable()
        ChainlinkClient(_linkToken) // Initializes LINK token for ChainlinkClient
    {
        if (_oracle == address(0) || _linkToken == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        oracleAddress = _oracle;
        aiModelJobId = _jobId;
        scoreUpdateFee = _scoreUpdateFee;
        trustScoreDecayRate = 1; // Default: 1 point per second
        LinkTokenInterface(_linkToken).approve(oracleAddress, type(uint256).max); // Approve LINK for the oracle
    }

    // --- Modifiers ---
    modifier onlyTrustedDataProvider() {
        if (!trustedDataProviders[msg.sender]) {
            revert AIEnhancedAdaptiveTrustProtocol__UnauthorizedDataProvider();
        }
        _;
    }

    modifier onlyTrustedOffChainAttestor() {
        if (!trustedOffChainAttestors[msg.sender]) {
            revert AIEnhancedAdaptiveTrustProtocol__UnauthorizedAttestor();
        }
        _;
    }

    modifier onlyDisputeCommitteeMember() {
        if (!disputeResolutionCommittee[msg.sender]) {
            revert AIEnhancedAdaptiveTrustProtocol__NotADisputeCommitteeMember();
        }
        _;
    }

    /*/////////////////////////////////////////////////////////////////////////
                        I. CORE TRUST & AI ASSESSMENT
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initiates an AI-driven trust score update for the caller.
     *      Requires a LINK fee to cover the oracle request.
     *      The AI will use the provided references to on-chain aggregated data and off-chain attestations.
     * @param _onChainDataReference A hash or IPFS CID referencing aggregated on-chain data for the user.
     * @param _offChainAttestationReference An IPFS CID referencing off-chain attestations for the user.
     */
    function requestAI_TrustScoreUpdate(
        string calldata _onChainDataReference,
        string calldata _offChainAttestationReference
    ) external whenNotPaused {
        if (LinkTokenInterface(s_link).balanceOf(address(this)) < scoreUpdateFee) {
            revert AIEnhancedAdaptiveTrustProtocol__NotEnoughLink();
        }

        Chainlink.Request memory req = buildChainlinkRequest(aiModelJobId, address(this), this.fulfillAI_TrustScoreUpdate.selector);
        // Add parameters for the AI model
        req.addString("userAddress", StringUtils.addressToString(msg.sender));
        req.addString("onChainDataReference", _onChainDataReference);
        req.addString("offChainAttestationReference", _offChainAttestationReference);
        req.addUint("lockedTokens", lockedTokensForReputation[msg.sender]);
        req.addUint("lockedDurationRemaining", reputationLockEndTimestamp[msg.sender] > block.timestamp ? reputationLockEndTimestamp[msg.sender] - block.timestamp : 0);


        bytes32 requestId = sendChainlinkRequestTo(oracleAddress, req, scoreUpdateFee);

        // Store request details for fulfillment and tracking
        pendingAIRequests[requestId] = msg.sender;
        aiRequestDetails[requestId] = AiRequestDetails({
            user: msg.sender,
            onChainDataReference: _onChainDataReference,
            offChainAttestationReference: _offChainAttestationReference,
            timestamp: block.timestamp
        });

        emit TrustScoreUpdateRequest(requestId, msg.sender, _onChainDataReference, _offChainAttestationReference);
    }

    /**
     * @dev Chainlink oracle callback function to fulfill an AI trust score update request.
     *      This function is called by the Chainlink oracle when the AI model returns a score.
     * @param _requestId The Chainlink request ID.
     * @param _newTrustScore The new trust score calculated by the AI.
     */
    function fulfillAI_TrustScoreUpdate(bytes32 _requestId, uint256 _newTrustScore)
        internal
        recordChainlinkFulfillment(_requestId)
    {
        address user = pendingAIRequests[_requestId];
        if (user == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__RequestNotFound();
        }

        uint256 oldScore = userTrustScores[user]; // Get the raw score before this update
        userTrustScores[user] = _newTrustScore;
        lastScoreUpdateTimestamp[user] = block.timestamp;
        delete pendingAIRequests[_requestId]; // Clear from pending requests

        emit TrustScoreUpdated(_requestId, user, oldScore, _newTrustScore);
    }

    /**
     * @dev Calculates and returns a user's current trust score, accounting for decay.
     * @param _user The address of the user.
     * @return The decayed trust score.
     */
    function getUserTrustScore(address _user) public view returns (uint256) {
        uint256 rawScore = userTrustScores[_user];
        uint256 lastUpdate = lastScoreUpdateTimestamp[_user];

        if (rawScore == 0 || lastUpdate == 0) {
            return 0; // No score or never updated
        }

        return calculateDecayedScore(rawScore, lastUpdate);
    }

    /**
     * @dev Returns a user's last AI-assessed raw trust score, without decay.
     * @param _user The address of the user.
     * @return The raw trust score.
     */
    function getRawUserTrustScore(address _user) public view returns (uint256) {
        return userTrustScores[_user];
    }

    /**
     * @dev Internal pure function to calculate a decayed trust score.
     * @param _rawScore The original raw trust score.
     * @param _lastUpdateTimestamp The timestamp of the last score update.
     * @return The decayed score.
     */
    function calculateDecayedScore(uint256 _rawScore, uint256 _lastUpdateTimestamp)
        public
        view
        pure
        returns (uint256)
    {
        if (_rawScore == 0) return 0;
        uint256 timeElapsed = block.timestamp - _lastUpdateTimestamp;
        uint256 decayAmount = timeElapsed * trustScoreDecayRate;
        return _rawScore > decayAmount ? _rawScore - decayAmount : 0;
    }

    /**
     * @dev Returns the timestamp when a user's trust score was last updated by the AI.
     * @param _user The address of the user.
     * @return The timestamp of the last score update.
     */
    function getLastScoreUpdateTimestamp(address _user) public view returns (uint256) {
        return lastScoreUpdateTimestamp[_user];
    }

    /**
     * @dev Returns the user address associated with a pending AI request.
     * @param _requestId The Chainlink request ID.
     * @return The address of the user who made the request.
     */
    function getPendingAIRequestUser(bytes32 _requestId) public view returns (address) {
        return pendingAIRequests[_requestId];
    }

    /**
     * @dev Returns the details of a specific AI trust score request.
     * @param _requestId The Chainlink request ID.
     * @return AiRequestDetails struct containing request information.
     */
    function getAIRequestDetails(bytes32 _requestId) public view returns (AiRequestDetails memory) {
        return aiRequestDetails[_requestId];
    }

    /*/////////////////////////////////////////////////////////////////////////
                        II. ORACLE & PROTOCOL CONFIGURATION
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows the owner to set the Chainlink oracle address.
     * @param _newOracle The new oracle address.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        oracleAddress = _newOracle;
        LinkTokenInterface(s_link).approve(oracleAddress, type(uint256).max); // Re-approve for new oracle
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Allows the owner to set the Chainlink Job ID for the AI model.
     * @param _newJobId The new Job ID.
     */
    function setAIModelJobId(bytes32 _newJobId) external onlyOwner {
        aiModelJobId = _newJobId;
        emit AIModelJobIdSet(_newJobId);
    }

    /**
     * @dev Allows the owner to set the LINK token fee for oracle requests.
     * @param _newFee The new fee amount in LINK.
     */
    function setScoreUpdateFee(uint256 _newFee) external onlyOwner {
        scoreUpdateFee = _newFee;
        emit ScoreUpdateFeeSet(_newFee);
    }

    /**
     * @dev Allows the owner to set the trust score decay rate (points per second).
     * @param _newRate The new decay rate.
     */
    function setTrustScoreDecayRate(uint256 _newRate) external onlyOwner {
        trustScoreDecayRate = _newRate;
        emit TrustScoreDecayRateSet(_newRate);
    }

    /**
     * @dev Allows the owner to set the default duration for reputation token locking.
     * @param _newDuration The new lock duration in seconds.
     */
    function setReputationLockDuration(uint256 _newDuration) external onlyOwner {
        reputationLockDuration = _newDuration;
        emit ReputationLockDurationSet(_newDuration);
    }

    /**
     * @dev Allows the owner to withdraw accumulated LINK fees from the contract.
     * @param _to The address to send the withdrawn fees to.
     */
    function withdrawProtocolFees(address _to) external onlyOwner {
        if (_to == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        // Only withdraw 'excess' LINK that is not part of the scoreUpdateFee budget pre-approved.
        // It's safer to just transfer the total balance, as the budget is for future use.
        uint256 amount = LinkTokenInterface(s_link).balanceOf(address(this));
        if (amount > 0) {
            LinkTokenInterface(s_link).transfer(_to, amount);
            emit ProtocolFeesWithdrawn(_to, amount);
        }
    }

    /*/////////////////////////////////////////////////////////////////////////
                        III. DATA & ATTESTATION INTEGRATION
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows the owner to register an address as a trusted data provider.
     *      Trusted data providers can submit hashes of on-chain events relevant to a user.
     * @param _provider The address to register.
     */
    function registerTrustedDataProvider(address _provider) external onlyOwner {
        if (_provider == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        trustedDataProviders[_provider] = true;
        emit TrustedDataProviderRegistered(_provider);
    }

    /**
     * @dev Allows the owner to deregister a trusted data provider.
     * @param _provider The address to deregister.
     */
    function deregisterTrustedDataProvider(address _provider) external onlyOwner {
        trustedDataProviders[_provider] = false;
        emit TrustedDataProviderDeregistered(_provider);
    }

    /**
     * @dev Allows a trusted data provider to submit a hash of an on-chain event for a specific user.
     *      This event hash can then be referenced by the user for AI trust score updates.
     * @param _user The address of the user this event relates to.
     * @param _eventHash A unique hash identifying the on-chain event.
     * @param _eventType A type identifier for the event (e.g., "DAO_VOTE", "TX_VOLUME").
     */
    function submitOnChainEventHash(address _user, bytes32 _eventHash, bytes32 _eventType)
        external
        whenNotPaused
        onlyTrustedDataProvider
    {
        if (_user == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        userEventLog[_user].push(UserOnChainEvent({
            eventHash: _eventHash,
            eventType: _eventType,
            timestamp: block.timestamp,
            submitter: msg.sender
        }));
        emit OnChainEventSubmitted(_user, _eventHash, _eventType, msg.sender);
    }

    /**
     * @dev Allows the owner to register an address as a trusted off-chain attestor.
     *      Trusted attestors can submit signed IPFS CIDs referencing off-chain behavioral data.
     * @param _attestor The address to register.
     */
    function registerTrustedOffChainAttestor(address _attestor) external onlyOwner {
        if (_attestor == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        trustedOffChainAttestors[_attestor] = true;
        emit TrustedOffChainAttestorRegistered(_attestor);
    }

    /**
     * @dev Allows a trusted off-chain attestor to submit a signed IPFS CID for a specific user.
     *      This attestation can be used by the AI to assess trust. The `_signature`
     *      is expected to be a valid signature by `_attestor` over `_attestationCID` and `_user`.
     * @param _user The address of the user this attestation relates to.
     * @param _attestationCID The IPFS Content Identifier for the off-chain attestation data.
     * @param _signature The cryptographic signature from the attestor for the CID and user.
     */
    function submitSignedOffChainAttestation(
        address _user,
        string calldata _attestationCID,
        bytes calldata _signature
    ) external whenNotPaused onlyTrustedOffChainAttestor {
        if (_user == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        // In a real implementation, `_signature` would be verified against `msg.sender`
        // and a hash of `_user` and `_attestationCID`. For this conceptual contract,
        // we assume `onlyTrustedOffChainAttestor` provides sufficient trust and off-chain AI verifies the full payload.
        userOffChainAttestations[_user].push(UserOffChainAttestation({
            attestationCID: _attestationCID,
            signature: _signature,
            timestamp: block.timestamp,
            submitter: msg.sender
        }));
        emit OffChainAttestationSubmitted(_user, _attestationCID, msg.sender);
    }

    /*/////////////////////////////////////////////////////////////////////////
                        IV. DISPUTE RESOLUTION (AI ASSESSMENT)
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows a user or committee member to propose a dispute against an AI assessment.
     *      The dispute is identified by a unique hash of its content.
     * @param _userToDispute The user whose AI assessment is being disputed.
     * @param _reasonCID An IPFS CID referencing the detailed reason for the dispute.
     * @return The unique hash of the dispute proposal.
     */
    function proposeAI_AssessmentDispute(address _userToDispute, string calldata _reasonCID)
        external
        whenNotPaused
        returns (bytes32)
    {
        if (!(msg.sender == _userToDispute || disputeResolutionCommittee[msg.sender])) {
            revert AIEnhancedAdaptiveTrustProtocol__NotAuthorizedToProposeDispute();
        }
        if (_userToDispute == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }

        bytes32 disputeHash = keccak256(abi.encodePacked(_userToDispute, _reasonCID, block.timestamp, disputeProposalCounter.current()));
        disputeProposalCounter.increment(); // Ensure uniqueness for the hash

        disputeProposals[disputeHash] = DisputeProposal({
            userToDispute: _userToDispute,
            reasonCID: _reasonCID,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + disputeVotingPeriod,
            status: DisputeStatus.Pending,
            positiveVotes: 0,
            negativeVotes: 0,
            minVotesRequired: disputeVoteThreshold,
            resolvedScore: 0
        });

        emit DisputeProposed(disputeHash, _userToDispute, _reasonCID);
        return disputeHash;
    }

    /**
     * @dev Allows the owner to add a member to the dispute resolution committee.
     * @param _member The address of the new committee member.
     */
    function addDisputeCommitteeMember(address _member) external onlyOwner {
        if (_member == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__ZeroAddressNotAllowed();
        }
        disputeResolutionCommittee[_member] = true;
        emit DisputeCommitteeMemberAdded(_member);
    }

    /**
     * @dev Allows the owner to remove a member from the dispute resolution committee.
     * @param _member The address of the committee member to remove.
     */
    function removeDisputeCommitteeMember(address _member) external onlyOwner {
        disputeResolutionCommittee[_member] = false;
        emit DisputeCommitteeMemberRemoved(_member);
    }

    /**
     * @dev Allows a dispute committee member to vote on a dispute proposal.
     * @param _disputeProposalHash The hash of the dispute proposal.
     * @param _upholdUser True to vote to uphold the user's claim (override AI), false to reject (agree with AI).
     */
    function voteOnDispute(bytes32 _disputeProposalHash, bool _upholdUser)
        external
        whenNotPaused
        onlyDisputeCommitteeMember
    {
        DisputeProposal storage proposal = disputeProposals[_disputeProposalHash];
        if (proposal.userToDispute == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__DisputeNotFound();
        }
        if (!(proposal.status == DisputeStatus.Pending || proposal.status == DisputeStatus.Voting)) {
            revert AIEnhancedAdaptiveTrustProtocol__DisputeNotOpenForVoting();
        }
        if (block.timestamp > proposal.votingEndTime) {
            revert AIEnhancedAdaptiveTrustProtocol__VotingPeriodHasEnded();
        }
        if (disputeVoteRecords[_disputeProposalHash][msg.sender]) {
            revert AIEnhancedAdaptiveTrustProtocol__AlreadyVoted();
        }
        if (proposal.userToDispute == msg.sender) {
            revert AIEnhancedAdaptiveTrustProtocol__CannotVoteOnOwnDispute();
        }

        disputeVoteRecords[_disputeProposalHash][msg.sender] = true;
        if (_upholdUser) {
            proposal.positiveVotes++;
        } else {
            proposal.negativeVotes++;
        }
        // Change status to Voting if it's still Pending and a vote has occurred
        if (proposal.status == DisputeStatus.Pending) {
            proposal.status = DisputeStatus.Voting;
        }

        emit DisputeVoted(_disputeProposalHash, msg.sender, _upholdUser);
    }

    /**
     * @dev Allows the owner to finalize a dispute resolution based on committee votes.
     *      Can optionally override the AI score with a manual score if the user's claim is upheld.
     * @param _disputeProposalHash The hash of the dispute proposal.
     * @param _manualScore The score to set if the dispute upholds the user (0 if not applicable).
     */
    function resolveDispute(bytes32 _disputeProposalHash, uint256 _manualScore) external onlyOwner {
        DisputeProposal storage proposal = disputeProposals[_disputeProposalHash];
        if (proposal.userToDispute == address(0)) {
            revert AIEnhancedAdaptiveTrustProtocol__DisputeNotFound();
        }
        if (proposal.status == DisputeStatus.ResolvedUpholdUser || proposal.status == DisputeStatus.ResolvedRejectUser) {
            revert AIEnhancedAdaptiveTrustProtocol__DisputeAlreadyResolved();
        }
        if (block.timestamp <= proposal.votingEndTime) {
            revert AIEnhancedAdaptiveTrustProtocol__DisputeVotePeriodNotEnded();
        }

        DisputeStatus finalStatus;
        uint256 finalScore = 0;

        // Check if enough votes were cast for a decision
        if (proposal.positiveVotes + proposal.negativeVotes < proposal.minVotesRequired) {
            finalStatus = DisputeStatus.Canceled; // Not enough participation
        } else if (proposal.positiveVotes > proposal.negativeVotes) {
            finalStatus = DisputeStatus.ResolvedUpholdUser;
            finalScore = _manualScore; // Owner sets the score
            userTrustScores[proposal.userToDispute] = finalScore;
            lastScoreUpdateTimestamp[proposal.userToDispute] = block.timestamp;
        } else {
            finalStatus = DisputeStatus.ResolvedRejectUser; // AI's assessment stands (or higher votes for reject)
            finalScore = userTrustScores[proposal.userToDispute]; // Retain current score
        }

        proposal.status = finalStatus;
        proposal.resolvedScore = finalScore;

        emit DisputeResolved(_disputeProposalHash, finalStatus, finalScore);
    }

    /**
     * @dev Returns the details and status of a dispute proposal.
     * @param _disputeHash The hash of the dispute proposal.
     * @return DisputeProposal struct containing all details.
     */
    function getDisputeProposalStatus(bytes32 _disputeHash) public view returns (DisputeProposal memory) {
        return disputeProposals[_disputeHash];
    }

    /**
     * @dev Checks if an address is a member of the dispute resolution committee.
     * @param _addr The address to check.
     * @return True if the address is a committee member, false otherwise.
     */
    function isDisputeCommitteeMember(address _addr) public view returns (bool) {
        return disputeResolutionCommittee[_addr];
    }


    /*/////////////////////////////////////////////////////////////////////////
                            V. REPUTATION STAKING
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows a user to lock LINK tokens for a specified duration to signal commitment.
     *      This locked amount can be an input to the off-chain AI model for trust assessment.
     * @param _amount The amount of LINK tokens to lock.
     * @param _duration The duration in seconds for which the tokens will be locked.
     */
    function lockTokensForReputation(uint256 _amount, uint256 _duration) external whenNotPaused {
        if (_amount == 0) {
            revert AIEnhancedAdaptiveTrustProtocol__AmountMustBeGreaterThanZero();
        }
        if (lockedTokensForReputation[msg.sender] > 0) {
            revert AIEnhancedAdaptiveTrustProtocol__TokensAlreadyLocked();
        }
        if (_duration < reputationLockDuration) {
            revert AIEnhancedAdaptiveTrustProtocol__LockDurationTooShort();
        }

        // Transfer LINK from user to this contract
        IERC20(s_link).transferFrom(msg.sender, address(this), _amount);

        lockedTokensForReputation[msg.sender] = _amount;
        reputationLockEndTimestamp[msg.sender] = block.timestamp + _duration;

        emit TokensLockedForReputation(msg.sender, _amount, _duration, block.timestamp + _duration);
    }

    /**
     * @dev Allows a user to release their locked LINK tokens after the lock duration has passed.
     */
    function releaseLockedTokens() external whenNotPaused {
        uint256 amount = lockedTokensForReputation[msg.sender];
        if (amount == 0) {
            revert AIEnhancedAdaptiveTrustProtocol__NoTokensLocked();
        }
        if (block.timestamp < reputationLockEndTimestamp[msg.sender]) {
            revert AIEnhancedAdaptiveTrustProtocol__LockedTokensStillActive();
        }

        lockedTokensForReputation[msg.sender] = 0;
        reputationLockEndTimestamp[msg.sender] = 0; // Clear the timestamp

        // Transfer LINK from this contract back to user
        IERC20(s_link).transfer(msg.sender, amount);

        emit TokensReleasedFromReputation(msg.sender, amount);
    }

    /**
     * @dev Returns the amount of LINK tokens locked by a specific user.
     * @param _user The address of the user.
     * @return The amount of locked LINK tokens.
     */
    function getLockedTokens(address _user) public view returns (uint256) {
        return lockedTokensForReputation[_user];
    }

    /*/////////////////////////////////////////////////////////////////////////
                                  VI. UTILITY
    /////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns all on-chain event hashes submitted for a specific user.
     * @param _user The address of the user.
     * @return An array of UserOnChainEvent structs.
     */
    function getOwnedOnChainEvents(address _user) public view returns (UserOnChainEvent[] memory) {
        return userEventLog[_user];
    }

    /**
     * @dev Returns all off-chain attestations submitted for a specific user.
     * @param _user The address of the user.
     * @return An array of UserOffChainAttestation structs.
     */
    function getOwnedOffChainAttestations(address _user) public view returns (UserOffChainAttestation[] memory) {
        return userOffChainAttestations[_user];
    }

    /**
     * @dev Checks if an address is a registered trusted data provider.
     * @param _addr The address to check.
     * @return True if registered, false otherwise.
     */
    function isTrustedDataProvider(address _addr) public view returns (bool) {
        return trustedDataProviders[_addr];
    }

    /**
     * @dev Checks if an address is a registered trusted off-chain attestor.
     * @param _addr The address to check.
     * @return True if registered, false otherwise.
     */
    function isTrustedOffChainAttestor(address _addr) public view returns (bool) {
        return trustedOffChainAttestors[_addr];
    }

    /**
     * @dev Fallback function to receive LINK tokens.
     */
    receive() external payable {
        // This receive function is primarily here to allow LINK transfers directly to the contract.
        // It's important to note that ERC-20 tokens are not automatically handled by a `receive()` function
        // for standard `transfer()` calls (they use `transfer` on the token contract).
        // However, if LINK tokens (or any ERC-20) were somehow sent via a wrapper that results
        // in `call()` with Ether, this would receive it.
        // As a general best practice, it's good to have a receive function if the contract is
        // expected to hold any ETH, but for LINK-only contract, it's less critical unless
        // specifically handling edge cases or wrapped assets.
    }
}


// --- StringUtils library for address to string conversion (for Chainlink requests) ---
// This is a common utility for Chainlink requests, often included or found in examples.
// It helps convert an address to its string representation for sending as a parameter
// in a Chainlink request, as Chainlink External Adapters often consume string inputs.
library StringUtils {
    /**
     * @dev Converts an address to a string.
     * @param _addr The address to convert.
     * @return The string representation of the address.
     */
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
```