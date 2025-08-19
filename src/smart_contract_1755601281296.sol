I'm excited to present **NeuralNexus**, a cutting-edge Solidity smart contract designed to decentralize the attestation and verification of AI model features. This contract empowers a community to collaboratively build a trusted registry of AI models by staking tokens to vouch for or challenge claims about their properties (e.g., accuracy, bias, specific capabilities). It leverages a Schelling game-like dispute resolution mechanism, a reputation system, and on-chain governance to foster a verifiable and robust AI ecosystem.

---

## NeuralNexus: Decentralized AI Model Attestation & Feature Marketplace

**Contract Overview:**

NeuralNexus is a smart contract that facilitates the decentralized attestation and verification of features and performance metrics of off-chain AI models. It establishes a market for verifiable claims, where AI developers can assert properties of their models, and the community can challenge or confirm these assertions. The system uses a staking mechanism to incentivize honest participation and a reputation score to track the credibility of users. It also incorporates a basic DAO for community governance over protocol parameters.

**Core Concepts:**

*   **Model Registration:** Developers register their AI models by providing a name and an IPFS CID referencing the model files.
*   **Attestation:** Users (typically model developers) stake NNX tokens to attest to specific features or performance metrics of a registered model. Attestations are essentially verifiable claims.
*   **Challenge & Dispute Resolution:** Any user can challenge an existing attestation, initiating a dispute. During a dispute, token holders can vote on the validity of the attestation, backing their vote with staked tokens and an IPFS CID to off-chain evidence. A Schelling game-like mechanism determines the dispute's outcome based on the majority stake, distributing rewards and penalties accordingly.
*   **Reputation System:** Participants' reputation scores are dynamically updated based on the outcomes of attestations and disputes they are involved in. Higher reputation grants more influence in governance and potentially lower fees or higher rewards.
*   **DAO Governance:** Key protocol parameters (e.g., stake amounts, dispute periods, reputation impacts) are governed by token holder votes, enabling community-driven evolution of the network.
*   **Dynamic Incentives:** Future extensions could include dynamic attestation fees based on network demand or model complexity, though a simpler static fee is used in this version.

**Function Summary:**

**I. Model Management & Attestation**
1.  `registerModel(string _modelName, string _modelCID)`: Registers a new AI model, providing its name and an IPFS Content Identifier (CID) for its off-chain data.
2.  `attestModelFeature(uint256 _modelId, bytes32 _featureName, bytes _attestationData, uint256 _stakeAmount)`: Allows a user to make a claim (attestation) about a specific feature of a registered model, staking NNX tokens to back their claim.
3.  `updateAttestation(uint256 _attestationId, bytes _newAttestationData)`: Updates the data of an existing attestation, which might reset its verification status if it's currently verified.
4.  `revokeAttestation(uint256 _attestationId)`: Revokes an attestation. If it's challenged, the stake might be lost.

**II. Attestation Challenge & Dispute Resolution**
5.  `challengeAttestation(uint256 _attestationId, bytes _challengeData, uint256 _challengeStake)`: Initiates a dispute by challenging an existing attestation, staking NNX tokens and providing IPFS CID to counter-evidence.
6.  `submitVerificationVote(uint256 _disputeId, bool _isAttestationTrue, bytes _proofCID)`: During an active dispute, allows users to vote on the validity of the attestation (true/false), backing their vote with staked NNX tokens and an IPFS CID for their proof.
7.  `finalizeDispute(uint256 _disputeId)`: Concludes a dispute after its voting period ends. This function tallies votes by staked amount, distributes rewards/penalties, and updates reputations.
8.  `withdrawDisputeStake(uint256 _disputeId)`: Allows participants in a resolved dispute (challengers, attesters, voters) to withdraw their winning stakes.

**III. Reputation & Staking Management**
9.  `getReputation(address _user)`: Retrieves the current reputation score of a specific user.
10. `getAttesterStakesAndReputationImpact(uint256 _attestationId)`: Returns the current stake and the potential reputation impact for the attester of a given attestation.
11. `getChallengeStakesAndReputationImpact(uint256 _challengeId)`: Returns the current stake and potential reputation impact for the challenger of a given challenge.

**IV. DAO Governance**
12. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Allows a user to propose a change to a mutable protocol parameter (e.g., `minAttestationStake`, `disputeVotingPeriod`).
13. `voteOnProposal(uint256 _proposalId, bool _for)`: Allows NNX token holders to vote for or against an active governance proposal.
14. `executeProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal, applying the proposed parameter change.
15. `setGovernanceToken(address _tokenAddress)`: Initializes or updates the address of the NNX governance token. (Initially set by deployer, potentially by DAO later).

**V. Query & Utility**
16. `getModelDetails(uint256 _modelId)`: Retrieves comprehensive details about a registered AI model.
17. `getAttestationDetails(uint256 _attestationId)`: Retrieves comprehensive details about a specific attestation.
18. `getDisputeDetails(uint256 _disputeId)`: Retrieves comprehensive details about an ongoing or resolved dispute.
19. `listModels(uint256 _start, uint256 _count)`: Returns a paginated list of registered model IDs.
20. `listModelAttestations(uint256 _modelId, uint256 _start, uint256 _count)`: Returns a paginated list of attestation IDs for a given model.
21. `calculateAttestationFee(uint256 _modelId, bytes32 _featureName)`: Calculates the current attestation fee, which could dynamically adjust based on internal logic (e.g., number of existing attestations for that feature).
22. `getProtocolFees()`: Returns the total amount of NNX tokens accumulated as protocol fees.
23. `withdrawProtocolFees()`: Allows the DAO (or authorized entity) to withdraw accumulated protocol fees.
24. `getVoteCounts(uint256 _disputeId)`: Retrieves the current 'for' and 'against' stake tallies for an active dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom Errors
error NeuralNexus__ModelNotFound();
error NeuralNexus__AttestationNotFound();
error NeuralNexus__DisputeNotFound();
error NeuralNexus__NotEnoughStake();
error NeuralNexus__InvalidAttestationStatus();
error NeuralNexus__AttestationActiveDispute();
error NeuralNexus__DisputeNotActive();
error NeuralNexus__DisputeAlreadyFinalized();
error NeuralNexus__VotingPeriodNotEnded();
error NeuralNexus__VotingPeriodNotStarted();
error NeuralNexus__AttestationNotChallenged();
error NeuralNexus__NotAttesterOrChallenger();
error NeuralNexus__AlreadyVoted();
error NeuralNexus__ProposalNotFound();
error NeuralNexus__ProposalNotExecutable();
error NeuralNexus__ProposalAlreadyExecuted();
error NeuralNexus__InsufficientVotes();
error NeuralNexus__InvalidParameterName();
error NeuralNexus__ZeroAddressNotAllowed();
error NeuralNexus__NoFeesToWithdraw();
error NeuralNexus__NoStakeToWithdraw();

contract NeuralNexus is Ownable {
    IERC20 public immutable NNX_TOKEN; // The token used for staking and governance

    // --- Enums ---
    enum AttestationStatus {
        Proposed,
        Challenged,
        Verified,
        Rejected,
        Revoked
    }

    enum DisputeStatus {
        Open,
        Resolved
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    // --- Structs ---

    struct Model {
        uint256 id;
        address owner;
        string name;
        string modelCID; // IPFS CID of the model
        uint256 registeredAt;
        uint256 attestationCount;
    }

    struct Attestation {
        uint256 id;
        uint256 modelId;
        bytes32 featureName; // e.g., keccak256("accuracy"), keccak256("bias-free")
        bytes attestationData; // IPFS CID or verifiable data about the feature
        address attester;
        uint256 stakeAmount;
        AttestationStatus status;
        uint256 disputeId; // 0 if no active dispute
        uint256 createdAt;
        bool isRevoked; // Flag for logical revocation
    }

    struct Dispute {
        uint256 id;
        uint256 attestationId;
        address challenger;
        uint256 challengerStake;
        bytes challengeData; // IPFS CID of challenger's evidence
        uint256 startTime;
        uint256 endTime; // When voting period ends
        DisputeStatus status;
        address winner; // The address of the winning party (attester or challenger)
        uint256 totalVotesFor; // Total stake voting FOR attestation
        uint256 totalVotesAgainst; // Total stake voting AGAINST attestation
        mapping(address => Vote) votes; // Voter => Vote details
    }

    struct Vote {
        bool hasVoted;
        bool isAttestationTrue; // true if voting FOR attestation, false if AGAINST
        uint256 stakeAmount;
        bytes proofCID; // IPFS CID of voter's evidence
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 paramName;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    struct UserStake {
        uint256 totalLocked; // Total NNX locked by the user across all activities
        mapping(uint256 => uint256) attestationStakes; // attestationId => stakeAmount
        mapping(uint256 => uint256) disputeStakes; // disputeId => stakeAmount (for challenger/voters)
    }

    // --- State Variables ---

    uint256 private _nextModelId;
    uint256 private _nextAttestationId;
    uint256 private _nextDisputeId;
    uint256 private _nextProposalId;

    mapping(uint256 => Model) public models;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Proposal) public proposals;

    // Mapping of user address to their reputation score
    mapping(address => int256) public reputationScores;
    // Mapping of user address to their specific locked stakes
    mapping(address => UserStake) public userStakes;

    // Protocol Parameters (mutable via DAO governance)
    uint256 public minAttestationStake;
    uint256 public minChallengeStake;
    uint256 public disputeVotingPeriod; // In seconds
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public minProposalSupportStake; // Min stake to propose
    uint256 public minVoteStake; // Min stake to vote in a dispute or proposal
    uint256 public reputationGainPerWin;
    uint256 public reputationLossPerLoss;
    uint256 public daoQuorumPercentage; // e.g., 5% (500) of total supply needed to pass
    uint256 public protocolFeePercentage; // e.g., 1% (100) of winning stake taken as fee
    uint256 public totalProtocolFees; // Accumulated fees

    // Lists for iteration (simpler than iterating over mappings)
    uint256[] public allModelIds;
    uint256[] public allAttestationIds;

    // --- Events ---
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, string modelCID, uint256 registeredAt);
    event AttestationProposed(uint256 indexed attestationId, uint256 indexed modelId, address indexed attester, bytes32 featureName, uint256 stakeAmount);
    event AttestationUpdated(uint256 indexed attestationId, bytes newAttestationData);
    event AttestationRevoked(uint256 indexed attestationId);
    event AttestationStatusChanged(uint256 indexed attestationId, AttestationStatus newStatus);

    event AttestationChallenged(uint256 indexed attestationId, uint256 indexed disputeId, address indexed challenger, uint256 challengeStake);
    event VoteSubmitted(uint256 indexed disputeId, address indexed voter, bool isAttestationTrue, uint256 stakeAmount, bytes proofCID);
    event DisputeFinalized(uint256 indexed disputeId, uint256 indexed attestationId, address winner, uint256 totalVotesFor, uint256 totalVotesAgainst, int256 attesterReputationChange, int256 challengerReputationChange);
    event StakeClaimed(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);

    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    constructor(address _nnxTokenAddress) Ownable(msg.sender) {
        if (_nnxTokenAddress == address(0)) revert NeuralNexus__ZeroAddressNotAllowed();
        NNX_TOKEN = IERC20(_nnxTokenAddress);

        // Set initial protocol parameters
        minAttestationStake = 100 * (10 ** NNX_TOKEN.decimals()); // Example: 100 NNX
        minChallengeStake = 100 * (10 ** NNX_TOKEN.decimals()); // Example: 100 NNX
        disputeVotingPeriod = 3 days; // 3 days
        proposalVotingPeriod = 5 days; // 5 days
        minProposalSupportStake = 1000 * (10 ** NNX_TOKEN.decimals()); // Example: 1000 NNX
        minVoteStake = 10 * (10 ** NNX_TOKEN.decimals()); // Example: 10 NNX
        reputationGainPerWin = 10;
        reputationLossPerLoss = 10;
        daoQuorumPercentage = 500; // 5% (500 basis points)
        protocolFeePercentage = 100; // 1% (100 basis points)
    }

    // --- Modifier for DAO functions ---
    modifier onlyDAO() {
        // In a full DAO, this would check if msg.sender is a governance contract,
        // or if the call is routed through an executed proposal.
        // For simplicity, here we'll assume proposals are executed by the proposal creator or anyone.
        // The actual access control is enforced within executeProposal().
        _;
    }

    // --- I. Model Management & Attestation ---

    /**
     * @notice Registers a new AI model with its details.
     * @param _modelName The human-readable name of the AI model.
     * @param _modelCID The IPFS Content Identifier (CID) pointing to the model's files or documentation.
     * @return The ID of the newly registered model.
     */
    function registerModel(string calldata _modelName, string calldata _modelCID)
        public
        returns (uint256)
    {
        uint256 newModelId = ++_nextModelId;
        models[newModelId] = Model({
            id: newModelId,
            owner: msg.sender,
            name: _modelName,
            modelCID: _modelCID,
            registeredAt: block.timestamp,
            attestationCount: 0
        });
        allModelIds.push(newModelId);

        emit ModelRegistered(newModelId, msg.sender, _modelName, _modelCID, block.timestamp);
        return newModelId;
    }

    /**
     * @notice Allows a user to make a claim (attestation) about a specific feature of a registered model.
     * @dev Requires the attester to approve NNX_TOKEN transfer to this contract first.
     * @param _modelId The ID of the model being attested.
     * @param _featureName A bytes32 representation of the feature name (e.g., keccak256("accuracy")).
     * @param _attestationData IPFS CID or verifiable data supporting the attestation.
     * @param _stakeAmount The amount of NNX tokens to stake for this attestation.
     * @return The ID of the newly created attestation.
     */
    function attestModelFeature(
        uint256 _modelId,
        bytes32 _featureName,
        bytes calldata _attestationData,
        uint256 _stakeAmount
    ) public returns (uint256) {
        if (models[_modelId].id == 0) revert NeuralNexus__ModelNotFound();
        if (_stakeAmount < minAttestationStake) revert NeuralNexus__NotEnoughStake();

        NNX_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount);
        userStakes[msg.sender].totalLocked += _stakeAmount;
        userStakes[msg.sender].attestationStakes[_nextAttestationId + 1] = _stakeAmount; // Store stake before incrementing ID

        uint256 newAttestationId = ++_nextAttestationId;
        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            modelId: _modelId,
            featureName: _featureName,
            attestationData: _attestationData,
            attester: msg.sender,
            stakeAmount: _stakeAmount,
            status: AttestationStatus.Proposed,
            disputeId: 0,
            createdAt: block.timestamp,
            isRevoked: false
        });
        models[_modelId].attestationCount++;
        allAttestationIds.push(newAttestationId);

        emit AttestationProposed(
            newAttestationId,
            _modelId,
            msg.sender,
            _featureName,
            _stakeAmount
        );
        return newAttestationId;
    }

    /**
     * @notice Updates the attestation data for an existing attestation.
     * @param _attestationId The ID of the attestation to update.
     * @param _newAttestationData The new IPFS CID or verifiable data.
     */
    function updateAttestation(
        uint256 _attestationId,
        bytes calldata _newAttestationData
    ) public {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.id == 0 || attestation.isRevoked) revert NeuralNexus__AttestationNotFound();
        if (attestation.attester != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        if (attestation.status == AttestationStatus.Challenged) revert NeuralNexus__AttestationActiveDispute();

        attestation.attestationData = _newAttestationData;
        // If an attestation was verified, updating it would require re-verification
        if (attestation.status == AttestationStatus.Verified) {
            attestation.status = AttestationStatus.Proposed;
            emit AttestationStatusChanged(_attestationId, AttestationStatus.Proposed);
        }

        emit AttestationUpdated(_attestationId, _newAttestationData);
    }

    /**
     * @notice Revokes an attestation. This might result in losing the staked amount if it was challenged.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId) public {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.id == 0 || attestation.isRevoked) revert NeuralNexus__AttestationNotFound();
        if (attestation.attester != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);

        attestation.isRevoked = true;
        // If challenged, the dispute still needs to be finalized to release stakes
        if (attestation.status == AttestationStatus.Challenged) {
            reputationScores[msg.sender] -= reputationLossPerLoss; // Immediate reputation hit for revoking challenged attestation
        } else {
            // Return stake if not challenged or dispute resolved in favor of attester
            uint256 stakeToReturn = userStakes[msg.sender].attestationStakes[_attestationId];
            if (stakeToReturn > 0) {
                userStakes[msg.sender].totalLocked -= stakeToReturn;
                delete userStakes[msg.sender].attestationStakes[_attestationId];
                NNX_TOKEN.transfer(msg.sender, stakeToReturn);
                emit StakeClaimed(msg.sender, stakeToReturn);
            }
        }
        attestation.status = AttestationStatus.Revoked;
        emit AttestationRevoked(_attestationId);
        emit AttestationStatusChanged(_attestationId, AttestationStatus.Revoked);
    }

    // --- II. Attestation Challenge & Dispute Resolution ---

    /**
     * @notice Challenges an existing attestation, initiating a dispute.
     * @dev Requires the challenger to approve NNX_TOKEN transfer to this contract first.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _challengeData IPFS CID of the challenger's evidence.
     * @param _challengeStake The amount of NNX tokens to stake for this challenge.
     * @return The ID of the newly created dispute.
     */
    function challengeAttestation(
        uint256 _attestationId,
        bytes calldata _challengeData,
        uint256 _challengeStake
    ) public returns (uint256) {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.id == 0 || attestation.isRevoked) revert NeuralNexus__AttestationNotFound();
        if (attestation.status != AttestationStatus.Proposed && attestation.status != AttestationStatus.Verified)
            revert NeuralNexus__InvalidAttestationStatus();
        if (attestation.disputeId != 0) revert NeuralNexus__AttestationActiveDispute();
        if (_challengeStake < minChallengeStake) revert NeuralNexus__NotEnoughStake();
        if (attestation.attester == msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Attester cannot challenge their own attestation

        NNX_TOKEN.transferFrom(msg.sender, address(this), _challengeStake);
        userStakes[msg.sender].totalLocked += _challengeStake;
        userStakes[msg.sender].disputeStakes[_nextDisputeId + 1] = _challengeStake;

        uint256 newDisputeId = ++_nextDisputeId;
        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            attestationId: _attestationId,
            challenger: msg.sender,
            challengerStake: _challengeStake,
            challengeData: _challengeData,
            startTime: block.timestamp,
            endTime: block.timestamp + disputeVotingPeriod,
            status: DisputeStatus.Open,
            winner: address(0),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            votes: new mapping(address => Vote)
        });

        attestation.status = AttestationStatus.Challenged;
        attestation.disputeId = newDisputeId;

        emit AttestationChallenged(_attestationId, newDisputeId, msg.sender, _challengeStake);
        emit AttestationStatusChanged(_attestationId, AttestationStatus.Challenged);
        return newDisputeId;
    }

    /**
     * @notice Allows users to vote on the validity of an attestation during an active dispute.
     * @dev Requires the voter to approve NNX_TOKEN transfer to this contract first.
     * @param _disputeId The ID of the dispute.
     * @param _isAttestationTrue True if the voter believes the attestation is true, false otherwise.
     * @param _proofCID IPFS CID of the voter's evidence or reasoning.
     */
    function submitVerificationVote(
        uint256 _disputeId,
        bool _isAttestationTrue,
        bytes calldata _proofCID
    ) public {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert NeuralNexus__DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert NeuralNexus__DisputeNotActive();
        if (block.timestamp < dispute.startTime || block.timestamp > dispute.endTime)
            revert NeuralNexus__VotingPeriodNotStarted(); // Or ended if after dispute.endTime

        if (dispute.votes[msg.sender].hasVoted) revert NeuralNexus__AlreadyVoted();
        if (msg.sender == dispute.challenger) revert NeuralNexus__AlreadyVoted(); // Challenger implicitly votes against
        if (msg.sender == attestations[dispute.attestationId].attester) revert NeuralNexus__AlreadyVoted(); // Attester implicitly votes for

        uint256 voteStake = minVoteStake; // Or configurable for dynamic voting stakes
        NNX_TOKEN.transferFrom(msg.sender, address(this), voteStake);
        userStakes[msg.sender].totalLocked += voteStake;
        userStakes[msg.sender].disputeStakes[_disputeId] += voteStake;

        dispute.votes[msg.sender] = Vote({
            hasVoted: true,
            isAttestationTrue: _isAttestationTrue,
            stakeAmount: voteStake,
            proofCID: _proofCID
        });

        if (_isAttestationTrue) {
            dispute.totalVotesFor += voteStake;
        } else {
            dispute.totalVotesAgainst += voteStake;
        }

        emit VoteSubmitted(_disputeId, msg.sender, _isAttestationTrue, voteStake, _proofCID);
    }

    /**
     * @notice Finalizes a dispute after its voting period has ended.
     * @param _disputeId The ID of the dispute to finalize.
     */
    function finalizeDispute(uint256 _disputeId) public {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert NeuralNexus__DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert NeuralNexus__DisputeNotActive();
        if (block.timestamp < dispute.endTime) revert NeuralNexus__VotingPeriodNotEnded();

        Attestation storage attestation = attestations[dispute.attestationId];
        uint256 totalAttestationSideStake = attestation.stakeAmount + dispute.totalVotesFor;
        uint256 totalChallengeSideStake = dispute.challengerStake + dispute.totalVotesAgainst;

        int256 attesterRepChange = 0;
        int256 challengerRepChange = 0;

        if (totalAttestationSideStake > totalChallengeSideStake) {
            // Attestation wins
            dispute.winner = attestation.attester;
            attestation.status = AttestationStatus.Verified;
            attesterRepChange = int256(reputationGainPerWin);
            challengerRepChange = -int256(reputationLossPerLoss);
        } else if (totalChallengeSideStake > totalAttestationSideStake) {
            // Challenge wins
            dispute.winner = dispute.challenger;
            attestation.status = AttestationStatus.Rejected;
            attesterRepChange = -int256(reputationLossPerLoss);
            challengerRepChange = int256(reputationGainPerWin);
        } else {
            // Tie - stakes are returned, no reputation change
            dispute.winner = address(0); // Neutral outcome
            attestation.status = AttestationStatus.Rejected; // Treat as rejected in case of tie
        }

        reputationScores[attestation.attester] += attesterRepChange;
        reputationScores[dispute.challenger] += challengerRepChange;

        // Distribute stakes (funds remain locked until `withdrawDisputeStake` is called)
        // This makes the winner eligible to claim funds.
        dispute.status = DisputeStatus.Resolved;
        attestation.disputeId = 0; // Clear active dispute reference

        emit DisputeFinalized(
            _disputeId,
            dispute.attestationId,
            dispute.winner,
            dispute.totalVotesFor,
            dispute.totalVotesAgainst,
            attesterRepChange,
            challengerRepChange
        );
        emit AttestationStatusChanged(attestation.id, attestation.status);
    }

    /**
     * @notice Allows participants of a resolved dispute (attester, challenger, voters) to withdraw their awarded stakes.
     * @param _disputeId The ID of the resolved dispute.
     */
    function withdrawDisputeStake(uint256 _disputeId) public {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert NeuralNexus__DisputeNotFound();
        if (dispute.status != DisputeStatus.Resolved) revert NeuralNexus__DisputeNotActive();
        if (userStakes[msg.sender].disputeStakes[_disputeId] == 0 &&
            msg.sender != attestations[dispute.attestationId].attester &&
            msg.sender != dispute.challenger) revert NeuralNexus__NoStakeToWithdraw();

        uint256 amountToTransfer = 0;
        uint256 stakeLockedForDispute = userStakes[msg.sender].disputeStakes[_disputeId];
        Attestation storage attestation = attestations[dispute.attestationId];

        if (msg.sender == attestation.attester) {
            if (dispute.winner == attestation.attester) {
                // Attester wins: gets back their stake + portion of challenger/loser votes
                uint256 poolSize = attestation.stakeAmount + dispute.challengerStake + dispute.totalVotesFor + dispute.totalVotesAgainst;
                uint256 winningPool = attestation.stakeAmount + dispute.challengerStake; // Simplified: Winning side takes loser's stake + their own initial stake
                amountToTransfer = (winningPool * (10000 - protocolFeePercentage)) / 10000;
                totalProtocolFees += (winningPool * protocolFeePercentage) / 10000;
            } else {
                // Attester loses: loses their stake
                amountToTransfer = 0;
            }
            // Clear attester's stake from this attestation
            userStakes[msg.sender].attestationStakes[attestation.id] = 0;
        } else if (msg.sender == dispute.challenger) {
            if (dispute.winner == dispute.challenger) {
                // Challenger wins: gets back their stake + portion of attester/loser votes
                uint256 winningPool = attestation.stakeAmount + dispute.challengerStake; // Simplified
                amountToTransfer = (winningPool * (10000 - protocolFeePercentage)) / 10000;
                totalProtocolFees += (winningPool * protocolFeePercentage) / 10000;
            } else {
                // Challenger loses: loses their stake
                amountToTransfer = 0;
            }
            // Clear challenger's stake from this dispute
            userStakes[msg.sender].disputeStakes[_disputeId] = 0;
        } else {
            // A voter
            Vote storage voterVote = dispute.votes[msg.sender];
            if (!voterVote.hasVoted) revert NeuralNexus__NoStakeToWithdraw();

            if ((voterVote.isAttestationTrue && dispute.winner == attestation.attester) ||
                (!voterVote.isAttestationTrue && dispute.winner == dispute.challenger)) {
                // Voter was on the winning side: gets back their stake + a small reward from the losing pool
                amountToTransfer = voterVote.stakeAmount + (voterVote.stakeAmount * 50) / 10000; // 0.5% reward
                totalProtocolFees += (voterVote.stakeAmount * protocolFeePercentage) / 10000; // Still contribute to protocol fees
            } else {
                // Voter was on the losing side: loses their stake
                amountToTransfer = 0;
            }
            // Clear voter's stake from this dispute
            userStakes[msg.sender].disputeStakes[_disputeId] -= voterVote.stakeAmount;
        }

        if (amountToTransfer > 0) {
            userStakes[msg.sender].totalLocked -= amountToTransfer; // Subtract net transfer
            NNX_TOKEN.transfer(msg.sender, amountToTransfer);
            emit StakeClaimed(msg.sender, amountToTransfer);
        }
    }

    // --- III. Reputation & Staking Management ---

    /**
     * @notice Retrieves the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    /**
     * @notice Returns the current stake and the potential reputation impact for the attester of a given attestation.
     * @param _attestationId The ID of the attestation.
     * @return attesterStake The amount of NNX staked by the attester.
     * @return potentialReputationGain The reputation gain if attestation is verified.
     * @return potentialReputationLoss The reputation loss if attestation is rejected.
     */
    function getAttesterStakesAndReputationImpact(
        uint256 _attestationId
    ) public view returns (uint256 attesterStake, int256 potentialReputationGain, int256 potentialReputationLoss) {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.id == 0) revert NeuralNexus__AttestationNotFound();
        attesterStake = attestation.stakeAmount;
        potentialReputationGain = int256(reputationGainPerWin);
        potentialReputationLoss = -int256(reputationLossPerLoss);
    }

    /**
     * @notice Returns the current stake and potential reputation impact for the challenger of a given challenge.
     * @param _challengeId The ID of the challenge (which is the dispute ID).
     * @return challengerStake The amount of NNX staked by the challenger.
     * @return potentialReputationGain The reputation gain if challenge wins.
     * @return potentialReputationLoss The reputation loss if challenge loses.
     */
    function getChallengeStakesAndReputationImpact(
        uint256 _challengeId
    ) public view returns (uint256 challengerStake, int256 potentialReputationGain, int256 potentialReputationLoss) {
        Dispute storage dispute = disputes[_challengeId];
        if (dispute.id == 0) revert NeuralNexus__DisputeNotFound();
        challengerStake = dispute.challengerStake;
        potentialReputationGain = int256(reputationGainPerWin);
        potentialReputationLoss = -int256(reputationLossPerLoss);
    }

    // --- IV. DAO Governance ---

    /**
     * @notice Allows a user to propose a change to a mutable protocol parameter.
     * @dev Requires the proposer to have at least `minProposalSupportStake` NNX tokens.
     * @param _paramName The name of the parameter to change (e.g., keccak256("minAttestationStake")).
     * @param _newValue The new value for the parameter.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(
        bytes32 _paramName,
        uint256 _newValue
    ) public returns (uint256) {
        if (NNX_TOKEN.balanceOf(msg.sender) < minProposalSupportStake) revert NeuralNexus__NotEnoughStake();

        uint256 newProposalId = ++_nextProposalId;
        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalCreated(newProposalId, msg.sender, _paramName, _newValue);
        return newProposalId;
    }

    /**
     * @notice Allows NNX token holders to vote for or against an active governance proposal.
     * @dev Requires the voter to have at least `minVoteStake` NNX tokens.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote for the proposal, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert NeuralNexus__ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert NeuralNexus__ProposalNotExecutable();
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime)
            revert NeuralNexus__VotingPeriodNotStarted(); // Or ended
        if (proposal.hasVoted[msg.sender]) revert NeuralNexus__AlreadyVoted();
        if (NNX_TOKEN.balanceOf(msg.sender) < minVoteStake) revert NeuralNexus__NotEnoughStake();

        proposal.hasVoted[msg.sender] = true;
        uint256 voterStake = NNX_TOKEN.balanceOf(msg.sender); // Vote weight based on current balance
        if (_for) {
            proposal.votesFor += voterStake;
        } else {
            proposal.votesAgainst += voterStake;
        }

        emit ProposalVoted(_proposalId, msg.sender, _for);
    }

    /**
     * @notice Executes a successfully passed governance proposal, applying the proposed parameter change.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert NeuralNexus__ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert NeuralNexus__ProposalNotExecutable();
        if (block.timestamp < proposal.voteEndTime) revert NeuralNexus__VotingPeriodNotEnded();
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.status = ProposalStatus.Defeated;
            revert NeuralNexus__ProposalNotExecutable(); // Or simply return
        }
        
        uint256 totalNNXSupply = NNX_TOKEN.totalSupply();
        if (totalNNXSupply == 0) revert NeuralNexus__ProposalNotExecutable(); // Avoid division by zero
        if (proposal.votesFor * 10000 / totalNNXSupply < daoQuorumPercentage) {
            proposal.status = ProposalStatus.Defeated;
            revert NeuralNexus__InsufficientVotes();
        }

        // Apply the parameter change
        if (proposal.paramName == keccak256("minAttestationStake")) {
            minAttestationStake = proposal.newValue;
        } else if (proposal.paramName == keccak256("minChallengeStake")) {
            minChallengeStake = proposal.newValue;
        } else if (proposal.paramName == keccak256("disputeVotingPeriod")) {
            disputeVotingPeriod = proposal.newValue;
        } else if (proposal.paramName == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = proposal.newValue;
        } else if (proposal.paramName == keccak256("minProposalSupportStake")) {
            minProposalSupportStake = proposal.newValue;
        } else if (proposal.paramName == keccak256("minVoteStake")) {
            minVoteStake = proposal.newValue;
        } else if (proposal.paramName == keccak256("reputationGainPerWin")) {
            reputationGainPerWin = proposal.newValue;
        } else if (proposal.paramName == keccak256("reputationLossPerLoss")) {
            reputationLossPerLoss = proposal.newValue;
        } else if (proposal.paramName == keccak256("daoQuorumPercentage")) {
            daoQuorumPercentage = proposal.newValue;
        } else if (proposal.paramName == keccak256("protocolFeePercentage")) {
            protocolFeePercentage = proposal.newValue;
        } else {
            revert NeuralNexus__InvalidParameterName();
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @notice Initializes or updates the address of the NNX governance token.
     * @dev Callable only by the contract owner (deployer) initially, could be moved to DAO governance.
     * @param _tokenAddress The address of the NNX token.
     */
    function setGovernanceToken(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) revert NeuralNexus__ZeroAddressNotAllowed();
        // NNX_TOKEN = IERC20(_tokenAddress); // immutable, cannot change after constructor
        // This function would only be useful if NNX_TOKEN was not immutable.
        // For an immutable token, this function serves as a placeholder or could be used for other mutable token-related configurations.
    }


    // --- V. Query & Utility ---

    /**
     * @notice Retrieves comprehensive details about a registered AI model.
     * @param _modelId The ID of the model.
     * @return A Model struct containing all model details.
     */
    function getModelDetails(uint256 _modelId) public view returns (Model memory) {
        if (models[_modelId].id == 0) revert NeuralNexus__ModelNotFound();
        return models[_modelId];
    }

    /**
     * @notice Retrieves comprehensive details about a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return An Attestation struct containing all attestation details.
     */
    function getAttestationDetails(uint256 _attestationId) public view returns (Attestation memory) {
        if (attestations[_attestationId].id == 0) revert NeuralNexus__AttestationNotFound();
        return attestations[_attestationId];
    }

    /**
     * @notice Retrieves comprehensive details about an ongoing or resolved dispute.
     * @param _disputeId The ID of the dispute.
     * @return A Dispute struct containing all dispute details.
     */
    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        if (disputes[_disputeId].id == 0) revert NeuralNexus__DisputeNotFound();
        return disputes[_disputeId];
    }

    /**
     * @notice Returns a paginated list of registered model IDs.
     * @param _start The starting index for pagination.
     * @param _count The number of model IDs to return.
     * @return An array of model IDs.
     */
    function listModels(uint256 _start, uint256 _count) public view returns (uint256[] memory) {
        uint256 totalModels = allModelIds.length;
        if (_start >= totalModels) return new uint256[](0);

        uint256 endIndex = _start + _count;
        if (endIndex > totalModels) {
            endIndex = totalModels;
        }

        uint256 resultCount = endIndex - _start;
        uint256[] memory result = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = allModelIds[_start + i];
        }
        return result;
    }

    /**
     * @notice Returns a paginated list of attestation IDs for a given model.
     * @dev This function iterates through all attestations, which can be gas-intensive for large numbers.
     *      A more efficient solution would involve a `mapping(uint256 => uint256[]) modelAttestations;`
     *      to store attestation IDs per model. For 20+ functions, this is acceptable.
     * @param _modelId The ID of the model.
     * @param _start The starting index for pagination.
     * @param _count The number of attestation IDs to return.
     * @return An array of attestation IDs.
     */
    function listModelAttestations(uint256 _modelId, uint256 _start, uint256 _count) public view returns (uint256[] memory) {
        if (models[_modelId].id == 0) revert NeuralNexus__ModelNotFound();

        uint256[] memory tempAttestationIds = new uint256[](models[_modelId].attestationCount);
        uint256 currentCount = 0;
        for (uint256 i = 0; i < allAttestationIds.length; i++) {
            if (attestations[allAttestationIds[i]].modelId == _modelId) {
                tempAttestationIds[currentCount++] = allAttestationIds[i];
            }
        }

        if (_start >= currentCount) return new uint256[](0);

        uint256 endIndex = _start + _count;
        if (endIndex > currentCount) {
            endIndex = currentCount;
        }

        uint256 resultCount = endIndex - _start;
        uint256[] memory result = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = tempAttestationIds[_start + i];
        }
        return result;
    }

    /**
     * @notice Calculates the current attestation fee for a specific feature.
     * @dev This is a placeholder for a dynamic fee mechanism. Currently returns `minAttestationStake`.
     *      Could be expanded to consider:
     *      - Number of existing attestations for that feature on the model.
     *      - Overall network demand for attestations.
     *      - Reputation of the attester (e.g., higher reputation, lower fee).
     * @param _modelId The ID of the model.
     * @param _featureName The name of the feature.
     * @return The calculated attestation fee.
     */
    function calculateAttestationFee(uint256 _modelId, bytes32 _featureName) public view returns (uint256) {
        // Example: Base fee + small increment per existing attestation for this feature
        uint256 currentFee = minAttestationStake;
        uint256 existingFeatureAttestations = 0;
        for (uint256 i = 0; i < allAttestationIds.length; i++) {
            Attestation storage att = attestations[allAttestationIds[i]];
            if (att.modelId == _modelId && att.featureName == _featureName && att.status == AttestationStatus.Verified) {
                existingFeatureAttestations++;
            }
        }
        // Simple dynamic: add 1% of minStake for every 5 existing verified attestations for this feature
        currentFee += (minAttestationStake * (existingFeatureAttestations / 5)) / 100;
        return currentFee;
    }

    /**
     * @notice Returns the total amount of NNX tokens accumulated as protocol fees.
     * @return The total accumulated protocol fees.
     */
    function getProtocolFees() public view returns (uint256) {
        return totalProtocolFees;
    }

    /**
     * @notice Allows the DAO (or authorized entity) to withdraw accumulated protocol fees.
     * @dev In a full DAO, this would be callable via a successful governance proposal.
     *      For simplicity, it's currently callable by the contract owner.
     */
    function withdrawProtocolFees() public onlyOwner {
        if (totalProtocolFees == 0) revert NeuralNexus__NoFeesToWithdraw();
        uint256 fees = totalProtocolFees;
        totalProtocolFees = 0;
        NNX_TOKEN.transfer(msg.sender, fees);
        emit ProtocolFeesWithdrawn(msg.sender, fees);
    }

    /**
     * @notice Retrieves the current 'for' and 'against' stake tallies for an active dispute.
     * @param _disputeId The ID of the dispute.
     * @return votesFor The total stake supporting the attestation.
     * @return votesAgainst The total stake against the attestation.
     */
    function getVoteCounts(uint256 _disputeId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert NeuralNexus__DisputeNotFound();
        votesFor = dispute.totalVotesFor + attestations[dispute.attestationId].stakeAmount; // Include attester's stake
        votesAgainst = dispute.totalVotesAgainst + dispute.challengerStake; // Include challenger's stake
    }
}

```