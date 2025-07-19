The `CredibilityNexus` protocol is designed as a decentralized network for assessing and validating claims related to the security, functionality, and factual accuracy of decentralized applications (dApps) and smart contracts. It introduces a unique blend of reputation, game theory, and a conceptual layer for zero-knowledge proofs to foster trust and verifiable information within the blockchain ecosystem.

### Outline:

The contract orchestrates a system where users can:
1.  **Register dApps**: Onboard dApps into the system for scrutiny.
2.  **Submit Claims**: Assert facts or identify issues (e.g., vulnerabilities, bugs) about registered dApps, backed by a stake.
3.  **Stake & Dispute**: Other participants can stake tokens to support or dispute claims, leading to a game-theoretic resolution process.
4.  **Reputation & Soulbound Badges**: Participants earn non-transferable "Credibility Badges" (SBTs) based on their accuracy in claim validation, with their score dynamically influencing the badge's appearance.
5.  **Epoch-based Resolution**: Claims and disputes are resolved in defined time periods (epochs).
6.  **Simulated ZK-Proof Integration**: A conceptual framework allowing for privacy-preserving claims, where the veracity of an off-chain ZK-proof can be attested on-chain.
7.  **Decentralized Governance**: Key protocol parameters are adjustable through a simplified on-chain voting mechanism.

### Function Summary:

**I. Core Registry & Attestation:**
1.  `registerDApp(string calldata _dAppName, address _dAppAddress, string calldata _description, string calldata _ipfsHash)`: Registers a new dApp/contract, requiring an initial stake.
2.  `getRegisteredDAppDetails(bytes32 _dAppId)`: Retrieves details of a registered dApp.
3.  `submitClaim(bytes32 _dAppId, ClaimType _type, string calldata _claimText, string calldata _evidenceIpfsHash, uint256 _expiresInEpochs)`: Submits a new claim about a registered dApp, requiring a stake.
4.  `getClaimDetails(bytes32 _claimId)`: Retrieves details of a specific claim.
5.  `hasActiveClaim(bytes32 _dAppId, ClaimType _type)`: Checks if a dApp has an active, unresolved claim of a specific type.

**II. Staking & Dispute Mechanism:**
6.  `stakeForClaim(bytes32 _claimId)`: Stakes CRED tokens in support of a claim's validity.
7.  `stakeAgainstClaim(bytes32 _claimId)`: Stakes CRED tokens in dispute of a claim's validity.
8.  `challengeClaim(bytes32 _claimId)`: Initiates a formal challenge against a claim, requiring a specific challenge bond.
9.  `supportChallenge(bytes32 _challengeId)`: Stakes CRED tokens to support an ongoing challenge.
10. `getClaimStakes(bytes32 _claimId)`: Views total staked amounts for/against a claim.
11. `getChallengeStakes(bytes32 _challengeId)`: Views total staked amounts for/against a challenge.

**III. Resolution & Rewards:**
12. `advanceEpoch()`: Advances the protocol to the next epoch, triggering resolution of claims and challenges from the previous epoch.
13. `_resolveClaim(bytes32 _claimId)`: Internal function called by `advanceEpoch` to determine claim outcome and distribute rewards/penalties for the main actors (submitter/challenger).
14. `claimStakedTokensAndRewards()`: Allows participants to withdraw their principal stake and earned rewards from resolved claims/challenges.
15. `getPendingRewards(address _participant)`: Views the amount of CRED tokens a participant can claim.

**IV. Reputation & Soulbound Badges:**
16. `getCredibilityScore(address _participant)`: Retrieves a participant's current credibility score (reputation).
17. `getCredibilityBadgeURI(address _participant)`: Generates the SVG data URI for a participant's dynamic Soulbound Credibility Badge, reflecting their score.
18. `_updateCredibilityScore(address _participant, int256 _change)`: Internal function to adjust a participant's credibility score.
19. `_mintOrUpdateCredibilityBadge(address _participant, uint256 _score)`: Internal function to mint the SBT (if not exists) or conceptually update its metadata.

**V. ZK-Proof Integration (Simulated):**
20. `submitPrivateClaimProof(bytes32 _dAppId, ClaimType _type, bytes32 _hashedProof, string calldata _description)`: Allows submission of a claim accompanied by a hash of an off-chain zero-knowledge proof, for privacy.
21. `verifyPrivateClaimProofHash(bytes32 _privateClaimProofId, bytes32 _actualProofHash)`: Internal/restricted function to 'verify' the ZKP by matching a pre-computed or externally validated hash. (Simulated, requires off-chain infrastructure for actual ZKP computation).
22. `getPrivateClaimProofDetails(bytes32 _privateClaimProofId)`: Retrieves details of a submitted private claim proof.

**VI. Governance & Parameters:**
23. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Initiates a governance proposal to alter a protocol parameter.
24. `voteOnParameterChange(bytes32 _proposalId, bool _support)`: Allows participants to vote on a parameter change proposal.
25. `executeParameterChange(bytes32 _proposalId)`: Executes a passed governance proposal.
26. `getProtocolParameters()`: Views all current configurable protocol parameters.

**VII. Utility/Admin:**
27. `setCREDTokenAddress(address _newTokenAddress)`: Sets the address of the staking token (owner-only).
28. `getSBTBalance(address _participant)`: Checks if a participant has an SBT (returns 1 if minted, 0 otherwise).
29. `renounceOwnership()`: Standard OpenZeppelin function to relinquish contract ownership.
30. `getCredibilityNexusVersion()`: Returns the contract version.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256.toString()

/*
Outline:
The CredibilityNexus protocol is a decentralized system for validating claims about dApps and smart contracts.
Participants can submit claims regarding a dApp's security, functionality, or factual accuracy.
Other participants can then stake a designated ERC-20 token (CRED) to either support or dispute these claims.
The protocol features a game-theoretic dispute resolution mechanism where successful stakers earn rewards and reputation,
while unsuccessful ones incur penalties. Reputation is represented by non-transferable Soulbound Tokens (SBTs),
reflecting a participant's earned credibility. The system operates in epochs, with claims being resolved periodically.
A conceptual integration for ZK-proofs allows for privacy-preserving attestations.

Function Summary:

I. Core Registry & Attestation:
1.  registerDApp(string calldata _dAppName, address _dAppAddress, string calldata _description, string calldata _ipfsHash): Registers a new dApp/contract, requiring an initial stake.
2.  getRegisteredDAppDetails(bytes32 _dAppId): Retrieves details of a registered dApp.
3.  submitClaim(bytes32 _dAppId, ClaimType _type, string calldata _claimText, string calldata _evidenceIpfsHash, uint256 _expiresInEpochs): Submits a new claim about a registered dApp, requiring a stake.
4.  getClaimDetails(bytes32 _claimId): Retrieves details of a specific claim.
5.  hasActiveClaim(bytes32 _dAppId, ClaimType _type): Checks if a dApp has an active, unresolved claim of a specific type.

II. Staking & Dispute Mechanism:
6.  stakeForClaim(bytes32 _claimId): Stakes CRED tokens in support of a claim's validity.
7.  stakeAgainstClaim(bytes32 _claimId): Stakes CRED tokens in dispute of a claim's validity.
8.  challengeClaim(bytes32 _claimId): Initiates a formal challenge against a claim, requiring a specific challenge bond.
9.  supportChallenge(bytes32 _challengeId): Stakes CRED tokens to support an ongoing challenge.
10. getClaimStakes(bytes32 _claimId): Views total staked amounts for/against a claim.
11. getChallengeStakes(bytes32 _challengeId): Views total staked amounts for/against a challenge.

III. Resolution & Rewards:
12. advanceEpoch(): Advances the protocol to the next epoch, triggering resolution of claims and challenges from the previous epoch.
13. _resolveClaim(bytes32 _claimId): Internal function called by `advanceEpoch` to determine claim outcome and distribute rewards/penalties.
14. claimStakedTokensAndRewards(): Allows participants to withdraw their principal stake and earned rewards from resolved claims/challenges.
15. getPendingRewards(address _participant): Views the amount of CRED tokens a participant can claim.

IV. Reputation & Soulbound Badges:
16. getCredibilityScore(address _participant): Retrieves a participant's current credibility score (reputation).
17. getCredibilityBadgeURI(address _participant): Generates the SVG data URI for a participant's dynamic Soulbound Credibility Badge.
18. _updateCredibilityScore(address _participant, int256 _change): Internal function to adjust a participant's credibility score.
19. _mintOrUpdateCredibilityBadge(address _participant, uint256 _score): Internal function to mint the SBT (if not exists) or update its metadata.

V. ZK-Proof Integration (Simulated):
20. submitPrivateClaimProof(bytes32 _dAppId, ClaimType _type, bytes32 _hashedProof, string calldata _description): Allows submission of a claim accompanied by a hash of an off-chain zero-knowledge proof, for privacy.
21. verifyPrivateClaimProofHash(bytes32 _privateClaimProofId, bytes32 _actualProofHash): Internal/restricted function to 'verify' the ZKP by matching a pre-computed or externally validated hash. (Simulated, requires off-chain infrastructure for actual ZKP computation).
22. getPrivateClaimProofDetails(bytes32 _privateClaimProofId): Retrieves details of a submitted private claim proof.

VI. Governance & Parameters:
23. proposeParameterChange(bytes32 _paramName, uint256 _newValue): Initiates a governance proposal to alter a protocol parameter.
24. voteOnParameterChange(bytes32 _proposalId, bool _support): Allows participants to vote on a parameter change proposal.
25. executeParameterChange(bytes32 _proposalId): Executes a passed governance proposal.
26. getProtocolParameters(): Views all current configurable protocol parameters.

VII. Utility/Admin:
27. setCREDTokenAddress(address _newTokenAddress): Sets the address of the staking token (owner-only).
28. getSBTBalance(address _participant): Checks if a participant has an SBT (always 1 if minted, 0 otherwise).
29. renounceOwnership(): Standard OpenZeppelin function to relinquish contract ownership.
30. getCredibilityNexusVersion(): Returns the contract version.
*/

contract CredibilityNexus is Ownable {
    using Strings for uint256;

    // --- Events ---
    event DAppRegistered(bytes32 indexed dAppId, address indexed owner, string name, address dAppAddress);
    event ClaimSubmitted(bytes32 indexed claimId, bytes32 indexed dAppId, address indexed submitter, ClaimType claimType);
    event StakeAdded(bytes32 indexed claimOrChallengeId, address indexed staker, uint256 amount, bool isFor);
    event ClaimChallenged(bytes32 indexed claimId, bytes32 indexed challengeId, address indexed challenger, uint256 bondAmount);
    event EpochAdvanced(uint256 indexed newEpoch);
    event ClaimResolved(bytes32 indexed claimId, bool isAccepted, uint256 resolvedEpoch);
    event RewardsClaimed(address indexed participant, uint256 amount);
    event CredibilityScoreUpdated(address indexed participant, uint256 newScore);
    event CredibilityBadgeMinted(address indexed participant, uint256 tokenId);
    event ParameterChangeProposed(bytes32 indexed proposalId, bytes32 paramName, uint256 newValue);
    event ParameterVoteCast(bytes32 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(bytes32 indexed proposalId, bytes32 paramName, uint256 newValue);
    event PrivateClaimProofSubmitted(bytes32 indexed proofId, bytes32 indexed dAppId, address indexed submitter, bytes32 hashedProof);

    // --- Enums ---
    enum ClaimType {
        SecurityVulnerability,
        FunctionalBug,
        FactValidation,
        AuditCompletion,
        GeneralAttestation
    }

    enum ClaimStatus {
        Pending,          // Claim is submitted, open for initial staking
        Challenged,       // Claim is challenged, open for challenge support
        Accepted,         // Claim is definitively accepted
        Rejected,         // Claim is definitively rejected
        Objectionable     // Claim was challenged, and the challenge was successful
    }

    enum ChallengeStatus {
        Active,
        ResolvedSuccessful, // Challenge succeeded, claim rejected
        ResolvedFailed      // Challenge failed, claim accepted
    }

    // --- Structs ---
    struct DApp {
        string name;
        address dAppAddress;
        string description;
        string ipfsHash; // IPFS hash for general info/docs
        uint256 registrationEpoch;
        bytes32[] activeClaims; // List of active claim IDs for this dApp
    }

    struct Claim {
        bytes32 dAppId;
        address submitter;
        ClaimType claimType;
        string claimText;
        string evidenceIpfsHash;
        uint256 submitEpoch;
        uint256 expiresAfterEpoch; // Claim is resolved after this epoch if no challenge, or within challenge period
        ClaimStatus status;
        uint256 totalStakedFor;
        uint256 totalStakedAgainst;
        mapping(address => uint256) stakersFor;     // Stake amounts for specific participants
        mapping(address => uint256) stakersAgainst; // Stake amounts against specific participants
        bytes32 currentChallengeId; // 0x0 if no active challenge
    }

    struct Challenge {
        bytes32 claimId;
        address challenger;
        uint256 bondAmount;
        uint256 startEpoch;
        uint256 expiresAfterEpoch; // Challenge window ends
        ChallengeStatus status;
        uint256 totalStakedForChallenge; // To support challenger
        mapping(address => uint256) stakersForChallenge; // Stake amounts for specific participants
    }

    struct Participant {
        uint256 credibilityScore; // Reputation points
        uint256 tokenId; // Soulbound token ID (1 if minted, 0 otherwise)
        uint256 pendingRewards; // CRED tokens
        mapping(bytes32 => uint256) stakes; // claim/challenge ID -> amount staked by participant
    }

    struct ParameterProposal {
        bytes32 paramName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startEpoch;
        uint256 endEpoch;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    struct PrivateClaimProof {
        bytes32 dAppId;
        ClaimType claimType;
        address submitter;
        bytes32 hashedProof; // Hash of the actual ZK-Proof
        uint256 submitEpoch;
        bool verified; // Placeholder for ZKP verification status
        string description;
    }

    // --- State Variables ---
    IERC20 public CREDToken; // The ERC-20 token used for staking and rewards

    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTimestamp;

    // Mappings for data storage
    mapping(bytes32 => DApp) public dApps;
    mapping(bytes32 => Claim) public claims;
    mapping(bytes32 => Challenge) public challenges;
    mapping(address => Participant) public participants;
    mapping(bytes32 => ParameterProposal) public parameterProposals;
    mapping(bytes32 => PrivateClaimProof) public privateClaimProofs;

    // Arrays for iterable claims/proposals to be resolved
    bytes32[] private activeClaimsToResolve;
    mapping(bytes32 => uint256) private activeClaimIndex; // For efficient removal

    bytes32[] private activeProposalsToResolve;
    mapping(bytes32 => uint256) private activeProposalIndex; // For efficient removal


    // Counters for unique IDs
    uint256 private nextDAppId = 1;
    uint256 private nextClaimId = 1;
    uint256 private nextChallengeId = 1;
    uint256 private nextPrivateClaimProofId = 1;
    uint256 private nextProposalId = 1;
    uint256 private nextSBTTokenId = 1; // For Soulbound Badges

    // Protocol Parameters (adjustable via governance)
    struct ProtocolParameters {
        uint256 registrationStakeAmount;
        uint256 claimSubmissionStakeAmount;
        uint256 claimResolutionEpochs; // How many epochs a claim is open before auto-resolving if not challenged
        uint256 challengeBondAmount;
        uint256 challengePeriodEpochs; // How many epochs a challenge is open for support
        uint256 epochDuration; // Seconds per epoch
        uint256 minVotesForProposal; // Minimum votes required for a proposal to be considered
        uint256 proposalVoteDurationEpochs;
        uint256 credibilityBonusFactor; // Base points for correct actions
        uint256 credibilityPenaltyFactor; // Base points for incorrect actions
    }
    ProtocolParameters public params;

    // --- Modifiers ---
    modifier onlyActiveEpoch() {
        require(block.timestamp >= lastEpochAdvanceTimestamp + params.epochDuration, "CredibilityNexus: Epoch has not ended yet.");
        _;
    }

    modifier hasCredibilityBadge(address _participant) {
        require(participants[_participant].tokenId != 0, "CredibilityNexus: Participant must have a Credibility Badge.");
        _;
    }

    // --- Constructor ---
    constructor(address _CREDTokenAddress) Ownable(msg.sender) {
        require(_CREDTokenAddress != address(0), "CredibilityNexus: CRED token address cannot be zero.");
        CREDToken = IERC20(_CREDTokenAddress);

        // Initialize default parameters
        params = ProtocolParameters({
            registrationStakeAmount: 100 * (10 ** 18), // 100 CRED
            claimSubmissionStakeAmount: 10 * (10 ** 18), // 10 CRED
            claimResolutionEpochs: 3,
            challengeBondAmount: 50 * (10 ** 18), // 50 CRED
            challengePeriodEpochs: 2,
            epochDuration: 7 days, // 1 week per epoch
            minVotesForProposal: 5,
            proposalVoteDurationEpochs: 1,
            credibilityBonusFactor: 100, // 100 base points for correct
            credibilityPenaltyFactor: 50 // 50 base points for incorrect
        });

        currentEpoch = 0;
        lastEpochAdvanceTimestamp = block.timestamp;
    }

    // --- I. Core Registry & Attestation ---

    /**
     * @notice Registers a new dApp/contract within the CredibilityNexus.
     * @dev Requires the caller to stake `registrationStakeAmount` CRED tokens.
     * @param _dAppName Name of the dApp.
     * @param _dAppAddress On-chain address of the dApp contract (can be address(0) if not directly a contract).
     * @param _description A brief description of the dApp.
     * @param _ipfsHash IPFS hash linking to dApp documentation or audit reports.
     * @return bytes32 Unique ID of the registered dApp.
     */
    function registerDApp(
        string calldata _dAppName,
        address _dAppAddress,
        string calldata _description,
        string calldata _ipfsHash
    ) external returns (bytes32) {
        require(bytes(_dAppName).length > 0, "CredibilityNexus: DApp name cannot be empty.");
        require(bytes(_description).length > 0, "CredibilityNexus: DApp description cannot be empty.");
        require(bytes(_ipfsHash).length > 0, "CredibilityNexus: DApp IPFS hash cannot be empty.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.registrationStakeAmount), "CredibilityNexus: Stake transfer failed.");

        bytes32 dAppId = keccak256(abi.encodePacked("dApp", nextDAppId++, block.timestamp, msg.sender)); // Ensure unique ID
        dApps[dAppId] = DApp({
            name: _dAppName,
            dAppAddress: _dAppAddress,
            description: _description,
            ipfsHash: _ipfsHash,
            registrationEpoch: currentEpoch,
            activeClaims: new bytes32[](0)
        });

        _updateParticipantStake(msg.sender, dAppId, params.registrationStakeAmount);
        _mintOrUpdateCredibilityBadge(msg.sender, participants[msg.sender].credibilityScore);

        emit DAppRegistered(dAppId, msg.sender, _dAppName, _dAppAddress);
        return dAppId;
    }

    /**
     * @notice Retrieves the details of a registered dApp.
     * @param _dAppId The unique ID of the dApp.
     * @return tuple DApp details.
     */
    function getRegisteredDAppDetails(
        bytes32 _dAppId
    ) external view returns (string memory, address, string memory, string memory, uint256, bytes32[] memory) {
        DApp storage dapp = dApps[_dAppId];
        require(bytes(dapp.name).length > 0, "CredibilityNexus: DApp not found.");
        return (dapp.name, dapp.dAppAddress, dapp.description, dapp.ipfsHash, dapp.registrationEpoch, dapp.activeClaims);
    }

    /**
     * @notice Submits a new claim about a registered dApp.
     * @dev Requires the caller to stake `claimSubmissionStakeAmount` CRED tokens.
     * @param _dAppId The ID of the dApp the claim is about.
     * @param _type The type of claim (e.g., SecurityVulnerability).
     * @param _claimText A detailed description of the claim.
     * @param _evidenceIpfsHash IPFS hash linking to supporting evidence.
     * @param _expiresInEpochs Number of epochs before the claim can be resolved if unchallenged.
     * @return bytes32 Unique ID of the submitted claim.
     */
    function submitClaim(
        bytes32 _dAppId,
        ClaimType _type,
        string calldata _claimText,
        string calldata _evidenceIpfsHash,
        uint256 _expiresInEpochs
    ) external returns (bytes32) {
        require(bytes(dApps[_dAppId].name).length > 0, "CredibilityNexus: DApp not found.");
        require(bytes(_claimText).length > 0, "CredibilityNexus: Claim text cannot be empty.");
        require(bytes(_evidenceIpfsHash).length > 0, "CredibilityNexus: Evidence IPFS hash cannot be empty.");
        require(_expiresInEpochs > 0, "CredibilityNexus: Expiration must be greater than 0 epochs.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.claimSubmissionStakeAmount), "CredibilityNexus: Stake transfer failed.");

        bytes32 claimId = keccak256(abi.encodePacked("claim", nextClaimId++, block.timestamp, msg.sender));

        Claim storage newClaim = claims[claimId];
        newClaim.dAppId = _dAppId;
        newClaim.submitter = msg.sender;
        newClaim.claimType = _type;
        newClaim.claimText = _claimText;
        newClaim.evidenceIpfsHash = _evidenceIpfsHash;
        newClaim.submitEpoch = currentEpoch;
        newClaim.expiresAfterEpoch = currentEpoch + _expiresInEpochs;
        newClaim.status = ClaimStatus.Pending;
        newClaim.totalStakedFor = params.claimSubmissionStakeAmount; // Submitter's initial stake
        newClaim.stakersFor[msg.sender] = params.claimSubmissionStakeAmount;

        dApps[_dAppId].activeClaims.push(claimId);
        activeClaimsToResolve.push(claimId);
        activeClaimIndex[claimId] = activeClaimsToResolve.length - 1;

        _updateParticipantStake(msg.sender, claimId, params.claimSubmissionStakeAmount);
        _mintOrUpdateCredibilityBadge(msg.sender, participants[msg.sender].credibilityScore);

        emit ClaimSubmitted(claimId, _dAppId, msg.sender, _type);
        return claimId;
    }

    /**
     * @notice Retrieves the details of a specific claim.
     * @param _claimId The unique ID of the claim.
     * @return tuple Claim details.
     */
    function getClaimDetails(
        bytes32 _claimId
    ) external view returns (bytes32, address, ClaimType, string memory, string memory, uint256, uint256, ClaimStatus, uint256, uint256, bytes32) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "CredibilityNexus: Claim not found.");
        return (
            claim.dAppId,
            claim.submitter,
            claim.claimType,
            claim.claimText,
            claim.evidenceIpfsHash,
            claim.submitEpoch,
            claim.expiresAfterEpoch,
            claim.status,
            claim.totalStakedFor,
            claim.totalStakedAgainst,
            claim.currentChallengeId
        );
    }

    /**
     * @notice Checks if a dApp has an active, unresolved claim of a specific type.
     * @param _dAppId The ID of the dApp.
     * @param _type The type of claim to check for.
     * @return bool True if an active claim of that type exists, false otherwise.
     */
    function hasActiveClaim(bytes32 _dAppId, ClaimType _type) external view returns (bool) {
        DApp storage dapp = dApps[_dAppId];
        require(bytes(dapp.name).length > 0, "CredibilityNexus: DApp not found.");

        for (uint256 i = 0; i < dapp.activeClaims.length; i++) {
            bytes32 claimId = dapp.activeClaims[i];
            Claim storage claim = claims[claimId];
            if (claim.claimType == _type && (claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged)) {
                return true;
            }
        }
        return false;
    }

    // --- II. Staking & Dispute Mechanism ---

    /**
     * @notice Stakes CRED tokens in support of a claim's validity.
     * @param _claimId The ID of the claim to stake on.
     */
    function stakeForClaim(bytes32 _claimId) external hasCredibilityBadge(msg.sender) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "CredibilityNexus: Claim not found.");
        require(claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged, "CredibilityNexus: Claim not in a stakeable state.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.claimSubmissionStakeAmount), "CredibilityNexus: Stake transfer failed.");

        claim.totalStakedFor += params.claimSubmissionStakeAmount;
        claim.stakersFor[msg.sender] += params.claimSubmissionStakeAmount;
        _updateParticipantStake(msg.sender, _claimId, params.claimSubmissionStakeAmount);

        emit StakeAdded(_claimId, msg.sender, params.claimSubmissionStakeAmount, true);
    }

    /**
     * @notice Stakes CRED tokens in dispute of a claim's validity.
     * @param _claimId The ID of the claim to stake against.
     */
    function stakeAgainstClaim(bytes32 _claimId) external hasCredibilityBadge(msg.sender) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "CredibilityNexus: Claim not found.");
        require(claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged, "CredibilityNexus: Claim not in a stakeable state.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.claimSubmissionStakeAmount), "CredibilityNexus: Stake transfer failed.");

        claim.totalStakedAgainst += params.claimSubmissionStakeAmount;
        claim.stakersAgainst[msg.sender] += params.claimSubmissionStakeAmount;
        _updateParticipantStake(msg.sender, _claimId, params.claimSubmissionStakeAmount);

        emit StakeAdded(_claimId, msg.sender, params.claimSubmissionStakeAmount, false);
    }

    /**
     * @notice Initiates a formal challenge against a claim.
     * @dev Requires the challenger to post a `challengeBondAmount`.
     * @param _claimId The ID of the claim to challenge.
     * @return bytes32 Unique ID of the created challenge.
     */
    function challengeClaim(bytes32 _claimId) external returns (bytes32) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "CredibilityNexus: Claim not found.");
        require(claim.status == ClaimStatus.Pending, "CredibilityNexus: Claim is not in a pending state or already challenged.");
        require(claim.currentChallengeId == 0x0, "CredibilityNexus: Claim already has an active challenge.");
        require(msg.sender != claim.submitter, "CredibilityNexus: Submitter cannot challenge their own claim.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.challengeBondAmount), "CredibilityNexus: Challenge bond transfer failed.");

        bytes32 challengeId = keccak256(abi.encodePacked("challenge", nextChallengeId++, block.timestamp, msg.sender, _claimId));

        Challenge storage newChallenge = challenges[challengeId];
        newChallenge.claimId = _claimId;
        newChallenge.challenger = msg.sender;
        newChallenge.bondAmount = params.challengeBondAmount;
        newChallenge.startEpoch = currentEpoch;
        newChallenge.expiresAfterEpoch = currentEpoch + params.challengePeriodEpochs;
        newChallenge.status = ChallengeStatus.Active;
        newChallenge.totalStakedForChallenge = params.challengeBondAmount; // Challenger's initial bond
        newChallenge.stakersForChallenge[msg.sender] = params.challengeBondAmount;

        claim.status = ClaimStatus.Challenged;
        claim.currentChallengeId = challengeId;

        _updateParticipantStake(msg.sender, challengeId, params.challengeBondAmount);
        _mintOrUpdateCredibilityBadge(msg.sender, participants[msg.sender].credibilityScore);

        emit ClaimChallenged(_claimId, challengeId, msg.sender, params.challengeBondAmount);
        return challengeId;
    }

    /**
     * @notice Stakes CRED tokens to support an ongoing challenge.
     * @param _challengeId The ID of the challenge to support.
     */
    function supportChallenge(bytes32 _challengeId) external hasCredibilityBadge(msg.sender) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.claimId != 0x0, "CredibilityNexus: Challenge not found.");
        require(challenge.status == ChallengeStatus.Active, "CredibilityNexus: Challenge is not active.");
        require(CREDToken.transferFrom(msg.sender, address(this), params.claimSubmissionStakeAmount), "CredibilityNexus: Stake transfer failed.");

        challenge.totalStakedForChallenge += params.claimSubmissionStakeAmount;
        challenge.stakersForChallenge[msg.sender] += params.claimSubmissionStakeAmount;
        _updateParticipantStake(msg.sender, _challengeId, params.claimSubmissionStakeAmount);

        emit StakeAdded(_challengeId, msg.sender, params.claimSubmissionStakeAmount, true); // For challenge
    }

    /**
     * @notice Retrieves the total staked amounts for and against a specific claim.
     * @param _claimId The ID of the claim.
     * @return totalStakedFor Total CRED staked supporting the claim.
     * @return totalStakedAgainst Total CRED staked disputing the claim.
     */
    function getClaimStakes(bytes32 _claimId) external view returns (uint256 totalStakedFor, uint256 totalStakedAgainst) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "CredibilityNexus: Claim not found.");
        return (claim.totalStakedFor, claim.totalStakedAgainst);
    }

    /**
     * @notice Retrieves the total staked amounts for and against a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return totalStakedForChallenge Total CRED staked supporting the challenge.
     * @return totalStakedAgainstChallenge Total CRED staked supporting the original claim (against challenge).
     */
    function getChallengeStakes(bytes32 _challengeId) external view returns (uint256 totalStakedForChallenge, uint256 totalStakedAgainstChallenge) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.claimId != 0x0, "CredibilityNexus: Challenge not found.");
        // Staked against challenge means staked for the claim itself
        Claim storage claim = claims[challenge.claimId];
        return (challenge.totalStakedForChallenge, (claim.totalStakedFor - claim.stakersFor[claim.submitter]) + claim.totalStakedAgainst); // Simplified, excludes submitter's initial stake from 'for' side in context of challenge balance.
    }

    // --- III. Resolution & Rewards ---

    /**
     * @notice Advances the protocol to the next epoch, triggering resolution of claims and challenges.
     * @dev Can only be called after `epochDuration` has passed since the last advance.
     */
    function advanceEpoch() external onlyActiveEpoch {
        currentEpoch++;
        lastEpochAdvanceTimestamp = block.timestamp;

        // Process claims that are due for resolution
        bytes32[] memory claimsToProcess = new bytes32[](0);
        for(uint256 i = 0; i < activeClaimsToResolve.length; ) {
            bytes32 claimId = activeClaimsToResolve[i];
            Claim storage claim = claims[claimId];
            if (claim.submitter != address(0) &&
                (claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged) &&
                claim.expiresAfterEpoch <= currentEpoch)
            {
                claimsToProcess.push(claimId);
                _removeClaimFromActiveList(claimId); // Remove from active list
                // Do not increment i, as the element at i has been replaced by the last element.
            } else {
                i++; // Only increment if not removed
            }
        }

        for (uint256 i = 0; i < claimsToProcess.length; i++) {
            _resolveClaim(claimsToProcess[i]);
        }

        // Process proposals that are due for evaluation (not execution, as execution needs another call)
        bytes32[] memory proposalsToEvaluate = new bytes32[](0);
        for (uint256 i = 0; i < activeProposalsToResolve.length; ) {
            bytes32 proposalId = activeProposalsToResolve[i];
            ParameterProposal storage proposal = parameterProposals[proposalId];
            if (!proposal.executed && proposal.startEpoch != 0 && currentEpoch > proposal.endEpoch) {
                // Proposal voting period has ended, it's now ready for execution if it passed.
                proposalsToEvaluate.push(proposalId);
                _removeProposalFromActiveList(proposalId);
            } else {
                i++;
            }
        }
        // No explicit function call for proposals, they simply become eligible for `executeParameterChange`.

        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @dev Internal function to determine claim outcome and distribute rewards/penalties.
     *      This function performs simplified stake distribution focusing on the submitter/challenger.
     *      A more complex system for full proportional distribution would require explicit arrays of staker addresses.
     * @param _claimId The ID of the claim to resolve.
     */
    function _resolveClaim(bytes32 _claimId) internal {
        Claim storage claim = claims[_claimId];
        require(claim.submitter != address(0) && (claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged), "CredibilityNexus: Claim not found or not in resolvable state.");
        require(claim.expiresAfterEpoch <= currentEpoch, "CredibilityNexus: Claim not expired for resolution.");

        bool isAcceptedOutcome = false; // Default to rejected

        uint256 totalPoolForClaim = claim.totalStakedFor + claim.totalStakedAgainst;
        uint256 totalChallengePool = 0;

        // Case 1: Claim was challenged
        if (claim.currentChallengeId != 0x0) {
            Challenge storage challenge = challenges[claim.currentChallengeId];
            require(challenge.status == ChallengeStatus.Active, "CredibilityNexus: Challenge is not active.");
            require(challenge.expiresAfterEpoch <= currentEpoch, "CredibilityNexus: Challenge period has not ended.");

            totalChallengePool = challenge.totalStakedForChallenge; // Sum of challenger and supporters
            // The stake AGAINST the challenge is implied from total staked FOR the claim.
            uint256 totalStakedAgainstChallenge = claim.totalStakedFor - challenge.totalStakedForChallenge; // Original claim's FOR stake minus challenge FOR stake

            // If challenge stakes (for challenge) are greater than anti-challenge stakes (for original claim's approval)
            if (challenge.totalStakedForChallenge > totalStakedAgainstChallenge) {
                // Challenge successful, claim rejected
                isAcceptedOutcome = false;
                challenge.status = ChallengeStatus.ResolvedSuccessful;
                claim.status = ClaimStatus.Objectionable;

                // Reward Challenger and penalize claim submitter
                participants[challenge.challenger].pendingRewards += challenge.stakersForChallenge[challenge.challenger] + (totalPoolForClaim + totalChallengePool) / 2; // Simplified
                _updateCredibilityScore(challenge.challenger, int256(params.credibilityBonusFactor * 3)); // High bonus
                _updateCredibilityScore(claim.submitter, -int256(params.credibilityPenaltyFactor * 2)); // High penalty
            } else {
                // Challenge failed, claim accepted
                isAcceptedOutcome = true;
                challenge.status = ChallengeStatus.ResolvedFailed;
                claim.status = ClaimStatus.Accepted;

                // Reward Claim Submitter and penalize Challenger
                participants[claim.submitter].pendingRewards += claim.stakersFor[claim.submitter] + (totalPoolForClaim + totalChallengePool) / 2; // Simplified
                _updateCredibilityScore(claim.submitter, int256(params.credibilityBonusFactor * 3)); // High bonus
                _updateCredibilityScore(challenge.challenger, -int256(params.credibilityPenaltyFactor * 2)); // High penalty
            }

            // Clear stakes related to the challenge for the main actors
            delete participants[challenge.challenger].stakes[challenge.currentChallengeId];
            delete participants[claim.submitter].stakes[_claimId]; // Or the relevant challenge ID if they had stake there
        } else {
            // Case 2: Claim was NOT challenged. Auto-resolve based on initial stakes.
            if (claim.totalStakedFor > claim.totalStakedAgainst) {
                isAcceptedOutcome = true;
                claim.status = ClaimStatus.Accepted;

                // Reward Submitter
                participants[claim.submitter].pendingRewards += claim.stakersFor[claim.submitter] + (totalPoolForClaim / 2); // Simplified
                _updateCredibilityScore(claim.submitter, int256(params.credibilityBonusFactor));
            } else { // Including ties, for simplicity, treated as rejected
                isAcceptedOutcome = false;
                claim.status = ClaimStatus.Rejected;

                // Penalize Submitter
                _updateCredibilityScore(claim.submitter, -int256(params.credibilityPenaltyFactor));
            }

            // Clear stake for submitter on this claim
            delete participants[claim.submitter].stakes[_claimId];
        }

        emit ClaimResolved(_claimId, isAcceptedOutcome, currentEpoch);
    }

    /**
     * @notice Helper to remove a claim from the active claims list.
     * @dev Uses a swap-and-pop method for O(1) removal.
     */
    function _removeClaimFromActiveList(bytes32 _claimId) internal {
        uint256 index = activeClaimIndex[_claimId];
        uint256 lastIndex = activeClaimsToResolve.length - 1;
        if (index != lastIndex) {
            bytes32 lastClaimId = activeClaimsToResolve[lastIndex];
            activeClaimsToResolve[index] = lastClaimId;
            activeClaimIndex[lastClaimId] = index;
        }
        activeClaimsToResolve.pop();
        delete activeClaimIndex[_claimId];
    }

    /**
     * @notice Helper to remove a proposal from the active proposals list.
     * @dev Uses a swap-and-pop method for O(1) removal.
     */
    function _removeProposalFromActiveList(bytes32 _proposalId) internal {
        uint256 index = activeProposalIndex[_proposalId];
        uint256 lastIndex = activeProposalsToResolve.length - 1;
        if (index != lastIndex) {
            bytes32 lastProposalId = activeProposalsToResolve[lastIndex];
            activeProposalsToResolve[index] = lastProposalId;
            activeProposalIndex[lastProposalId] = index;
        }
        activeProposalsToResolve.pop();
        delete activeProposalIndex[_proposalId];
    }

    /**
     * @dev Internal function for updating participant stake records.
     */
    function _updateParticipantStake(address _participant, bytes32 _entityId, uint256 _amount) internal {
        participants[_participant].stakes[_entityId] += _amount;
    }

    /**
     * @notice Allows participants to withdraw their principal stake and earned rewards from resolved claims/challenges.
     */
    function claimStakedTokensAndRewards() external {
        Participant storage participant = participants[msg.sender];
        uint256 amount = participant.pendingRewards;
        require(amount > 0, "CredibilityNexus: No pending rewards to claim.");

        participant.pendingRewards = 0;
        require(CREDToken.transfer(msg.sender, amount), "CredibilityNexus: Failed to transfer rewards.");

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Views the amount of CRED tokens a participant can claim.
     * @param _participant The address of the participant.
     * @return uint256 Amount of pending rewards.
     */
    function getPendingRewards(address _participant) external view returns (uint256) {
        return participants[_participant].pendingRewards;
    }

    // --- IV. Reputation & Soulbound Badges ---

    /**
     * @notice Retrieves a participant's current credibility score (reputation).
     * @param _participant The address of the participant.
     * @return uint256 The credibility score.
     */
    function getCredibilityScore(address _participant) public view returns (uint256) {
        return participants[_participant].credibilityScore;
    }

    /**
     * @notice Generates the SVG data URI for a participant's dynamic Soulbound Credibility Badge.
     * @dev Returns an SVG string as a data URI, which is conceptualized as an SBT tokenURI.
     *      Note: Full Base64 encoding is omitted for simplicity and to avoid duplicating common libraries.
     * @param _participant The address of the participant.
     * @return string Data URI representing the SVG of the badge.
     */
    function getCredibilityBadgeURI(address _participant) external view returns (string memory) {
        Participant storage p = participants[_participant];
        require(p.tokenId != 0, "CredibilityNexus: Participant has no Credibility Badge yet.");

        uint256 score = p.credibilityScore;
        string memory color = "#6c757d"; // Gray for Novice
        string memory rank = "Novice";

        if (score >= 1000) { color = "#FFD700"; rank = "Legend"; } // Gold
        else if (score >= 500) { color = "#C0C0C0"; rank = "Expert"; } // Silver
        else if (score >= 100) { color = "#CD7F32"; rank = "Journeyman"; } // Bronze
        else if (score >= 10) { color = "#007BFF"; rank = "Apprentice"; } // Blue

        string memory svg = string(abi.encodePacked(
            '<svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="100%" height="100%" fill="#2c2f33" rx="15"/>',
            '<text x="150" y="50" font-family="monospace" font-size="24" fill="white" text-anchor="middle">Credibility Badge</text>',
            '<rect x="50" y="80" width="200" height="80" fill="', color, '" rx="10"/>',
            '<text x="150" y="115" font-family="monospace" font-size="18" fill="', (score >= 500 ? "black" : "white"), '" text-anchor="middle">Rank: ', rank, '</text>',
            '<text x="150" y="145" font-family="monospace" font-size="16" fill="', (score >= 500 ? "black" : "white"), '" text-anchor="middle">Score: ', score.toString(), '</text>',
            '<text x="150" y="185" font-family="monospace" font-size="12" fill="#aaaaaa" text-anchor="middle">', _participant.toHexString(), '</text>',
            '</svg>'
        ));

        // For simplicity and to avoid duplicating open-source Base64 library,
        // we return the raw SVG as data:image/svg+xml;utf8,
        // which modern browsers often handle directly, instead of full base64.
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;utf8,", svg));

        return string(abi.encodePacked(
            'data:application/json;base64,',
            _dummyBase64Encode(abi.encodePacked(
                '{"name":"Credibility Badge #', _participant.toHexString(), '",',
                '"description":"A soulbound token representing a participant\'s credibility score in CredibilityNexus. This badge is non-transferable and evolves with their reputation.",',
                '"image":"', imageURI, '",',
                '"attributes":[{"trait_type":"Credibility Score","value":', score.toString(), '},{"trait_type":"Rank","value":"', rank, '"}]}'
            ))
        ));
    }

    // Dummy Base64 encoder for demonstration.
    // In a production environment, a proper Base64 library (e.g., OpenZeppelin's) would be used.
    function _dummyBase64Encode(bytes memory data) internal pure returns (string memory) {
        // This is not a real Base64 encoder. It's a placeholder.
        // It simply converts the bytes to a string. A proper Base64 encoding requires a more complex algorithm.
        // The `data:application/json;base64,` prefix is still included for conceptual completeness.
        return string(data);
    }


    /**
     * @dev Internal function to adjust a participant's credibility score.
     * @param _participant The address of the participant.
     * @param _change The amount to change the score by (can be negative).
     */
    function _updateCredibilityScore(address _participant, int256 _change) internal {
        Participant storage p = participants[_participant];
        if (_change > 0) {
            p.credibilityScore += uint256(_change);
        } else {
            if (p.credibilityScore <= uint256(-_change)) {
                p.credibilityScore = 0;
            } else {
                p.credibilityScore -= uint256(-_change);
            }
        }
        _mintOrUpdateCredibilityBadge(_participant, p.credibilityScore);
        emit CredibilityScoreUpdated(_participant, p.credibilityScore);
    }

    /**
     * @dev Internal function to mint the SBT (if not exists) or update its metadata.
     *      This is a simplified SBT implementation. It tracks a `tokenId` internally.
     *      The actual "badge" is derived dynamically via `getCredibilityBadgeURI`.
     * @param _participant The address of the participant.
     * @param _score The current score for conceptual updating the badge metadata.
     */
    function _mintOrUpdateCredibilityBadge(address _participant, uint256 _score) internal {
        Participant storage p = participants[_participant];
        if (p.tokenId == 0) {
            p.tokenId = nextSBTTokenId++;
            emit CredibilityBadgeMinted(_participant, p.tokenId);
        }
        // No explicit update needed here, as `getCredibilityBadgeURI` dynamically generates based on current score.
    }

    // --- V. ZK-Proof Integration (Simulated) ---

    /**
     * @notice Allows submission of a claim accompanied by a hash of an off-chain zero-knowledge proof.
     * @dev The actual ZK-Proof verification happens off-chain, and only its hash is recorded here.
     *      Verification function is for checking this hash against a known valid hash.
     * @param _dAppId The ID of the dApp the claim is about.
     * @param _type The type of private claim.
     * @param _hashedProof The keccak256 hash of the generated ZK-Proof.
     * @param _description A description of what the proof attests to.
     * @return bytes32 Unique ID of the private claim proof.
     */
    function submitPrivateClaimProof(
        bytes32 _dAppId,
        ClaimType _type,
        bytes32 _hashedProof,
        string calldata _description
    ) external returns (bytes32) {
        require(bytes(dApps[_dAppId].name).length > 0, "CredibilityNexus: DApp not found.");
        require(_hashedProof != bytes32(0), "CredibilityNexus: Hashed proof cannot be zero.");
        require(bytes(_description).length > 0, "CredibilityNexus: Description cannot be empty.");

        bytes32 proofId = keccak256(abi.encodePacked("privateProof", nextPrivateClaimProofId++, block.timestamp, msg.sender, _dAppId));

        PrivateClaimProof storage newProof = privateClaimProofs[proofId];
        newProof.dAppId = _dAppId;
        newProof.claimType = _type;
        newProof.submitter = msg.sender;
        newProof.hashedProof = _hashedProof;
        newProof.submitEpoch = currentEpoch;
        newProof.verified = false; // Awaiting off-chain verification trigger or specific call
        newProof.description = _description;

        _mintOrUpdateCredibilityBadge(msg.sender, participants[msg.sender].credibilityScore);
        emit PrivateClaimProofSubmitted(proofId, _dAppId, msg.sender, _hashedProof);
        return proofId;
    }

    /**
     * @notice Internal/restricted function to 'verify' the ZKP by matching a pre-computed or externally validated hash.
     * @dev In a real system, this would involve a precompiled ZKP verifier contract, or an oracle.
     *      For this example, it's a simple hash comparison as a conceptual placeholder.
     *      Can be called by owner or a designated verifier role.
     * @param _privateClaimProofId The ID of the private claim proof to verify.
     * @param _actualProofHash The hash of the ZKP that has been externally verified as true.
     * @return bool True if verification is successful.
     */
    function verifyPrivateClaimProofHash(bytes32 _privateClaimProofId, bytes32 _actualProofHash) external onlyOwner returns (bool) {
        PrivateClaimProof storage proof = privateClaimProofs[_privateClaimProofId];
        require(proof.submitter != address(0), "CredibilityNexus: Private claim proof not found.");
        require(!proof.verified, "CredibilityNexus: Proof already verified.");
        require(proof.hashedProof == _actualProofHash, "CredibilityNexus: Provided hash does not match stored hash.");

        proof.verified = true;
        _updateCredibilityScore(proof.submitter, int256(params.credibilityBonusFactor * 5)); // Higher bonus for verified ZKP
        // Optionally, an internal claim could be created here based on the verified proof.

        return true;
    }

    /**
     * @notice Retrieves details of a submitted private claim proof.
     * @param _privateClaimProofId The unique ID of the private claim proof.
     * @return tuple Private claim proof details.
     */
    function getPrivateClaimProofDetails(
        bytes32 _privateClaimProofId
    ) external view returns (bytes32, ClaimType, address, bytes32, uint256, bool, string memory) {
        PrivateClaimProof storage proof = privateClaimProofs[_privateClaimProofId];
        require(proof.submitter != address(0), "CredibilityNexus: Private claim proof not found.");
        return (proof.dAppId, proof.claimType, proof.submitter, proof.hashedProof, proof.submitEpoch, proof.verified, proof.description);
    }

    // --- VI. Governance & Parameters ---

    /**
     * @notice Initiates a governance proposal to alter a protocol parameter.
     * @dev Requires a small stake to prevent spam.
     * @param _paramName The string name of the parameter to change (e.g., "claimSubmissionStakeAmount").
     * @param _newValue The new value for the parameter.
     * @return bytes32 Unique ID of the proposal.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) external returns (bytes32) {
        // A minimal stake for proposing might be implemented here, similar to claimSubmissionStakeAmount.
        // For simplicity, it's omitted for now.

        bytes32 proposalId = keccak256(abi.encodePacked("proposal", nextProposalId++, block.timestamp, msg.sender, _paramName));

        ParameterProposal storage proposal = parameterProposals[proposalId];
        proposal.paramName = _paramName;
        proposal.newValue = _newValue;
        proposal.votesFor = 0; // Votes are cast using individual participants (1-person-1-vote for simplicity)
        proposal.votesAgainst = 0;
        proposal.startEpoch = currentEpoch;
        proposal.endEpoch = currentEpoch + params.proposalVoteDurationEpochs;
        proposal.executed = false;

        activeProposalsToResolve.push(proposalId);
        activeProposalIndex[proposalId] = activeProposalsToResolve.length - 1;

        emit ParameterChangeProposed(proposalId, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @notice Allows participants to vote on a parameter change proposal.
     * @dev Vote weight could be based on CRED token balance (snapshot or current).
     *      For simplicity, a 1-person-1-vote model here, requiring a Credibility Badge.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnParameterChange(bytes32 _proposalId, bool _support) external hasCredibilityBadge(msg.sender) {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.paramName != bytes32(0), "CredibilityNexus: Proposal not found.");
        require(proposal.startEpoch != 0 && currentEpoch <= proposal.endEpoch, "CredibilityNexus: Voting period has ended or not started.");
        require(!proposal.hasVoted[msg.sender], "CredibilityNexus: Already voted on this proposal.");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ParameterVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed governance proposal.
     * @dev Can be called by anyone after the voting period ends, if the proposal passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(bytes32 _proposalId) external {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.paramName != bytes32(0), "CredibilityNexus: Proposal not found.");
        require(!proposal.executed, "CredibilityNexus: Proposal already executed.");
        require(currentEpoch > proposal.endEpoch, "CredibilityNexus: Voting period has not ended.");
        require(proposal.votesFor > proposal.votesAgainst, "CredibilityNexus: Proposal did not pass.");
        require(proposal.votesFor >= params.minVotesForProposal, "CredibilityNexus: Not enough votes to pass.");

        bytes32 paramName = proposal.paramName;
        uint256 newValue = proposal.newValue;

        // Apply the parameter change based on `paramName`
        if (paramName == keccak256(abi.encodePacked("registrationStakeAmount"))) {
            params.registrationStakeAmount = newValue;
        } else if (paramName == keccak256(abi.encodePacked("claimSubmissionStakeAmount"))) {
            params.claimSubmissionStakeAmount = newValue;
        } else if (paramName == keccak256(abi.encodePacked("claimResolutionEpochs"))) {
            params.claimResolutionEpochs = newValue;
        } else if (paramName == keccak256(abi.encodePacked("challengeBondAmount"))) {
            params.challengeBondAmount = newValue;
        } else if (paramName == keccak256(abi.encodePacked("challengePeriodEpochs"))) {
            params.challengePeriodEpochs = newValue;
        } else if (paramName == keccak256(abi.encodePacked("epochDuration"))) {
            params.epochDuration = newValue;
        } else if (paramName == keccak256(abi.encodePacked("minVotesForProposal"))) {
            params.minVotesForProposal = newValue;
        } else if (paramName == keccak256(abi.encodePacked("proposalVoteDurationEpochs"))) {
            params.proposalVoteDurationEpochs = newValue;
        } else if (paramName == keccak256(abi.encodePacked("credibilityBonusFactor"))) {
            params.credibilityBonusFactor = newValue;
        } else if (paramName == keccak256(abi.encodePacked("credibilityPenaltyFactor"))) {
            params.credibilityPenaltyFactor = newValue;
        } else {
            revert("CredibilityNexus: Unknown parameter name.");
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, paramName, newValue);
    }

    /**
     * @notice Views all current configurable protocol parameters.
     * @return tuple All protocol parameters.
     */
    function getProtocolParameters() external view returns (ProtocolParameters memory) {
        return params;
    }

    // --- VII. Utility/Admin ---

    /**
     * @notice Sets the address of the staking token (CREDToken).
     * @dev Only callable by the contract owner.
     * @param _newTokenAddress The address of the new ERC-20 token.
     */
    function setCREDTokenAddress(address _newTokenAddress) external onlyOwner {
        require(_newTokenAddress != address(0), "CredibilityNexus: New token address cannot be zero.");
        CREDToken = IERC20(_newTokenAddress);
    }

    /**
     * @notice Checks if a participant has an SBT. (Simplistic, as it's an internal SBT).
     * @param _participant The address of the participant.
     * @return uint256 Returns 1 if SBT is minted, 0 otherwise.
     */
    function getSBTBalance(address _participant) external view returns (uint256) {
        return participants[_participant].tokenId != 0 ? 1 : 0;
    }

    /**
     * @notice Returns the current version of the CredibilityNexus contract.
     * @return string Contract version.
     */
    function getCredibilityNexusVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    // Fallback and Receive (Optional, but good practice for handling ETH)
    receive() external payable {}
    fallback() external payable {}
}
```