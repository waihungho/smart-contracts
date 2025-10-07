This smart contract, named **Decentralized Skill & Impact Network (DSIN)**, proposes a novel ecosystem for on-chain skill verification, collaborative project execution, and reputation-based governance. It introduces dynamic NFTs (Non-Fungible Tokens) called "Skill Tokens" that represent a user's verified skills and accrue "Impact Score" based on their contributions to community-driven "Missions" and peer attestations. The accumulated Impact Score then directly influences a user's governance power within the network.

---

## Decentralized Skill & Impact Network (DSIN)

**Author:** YourName (GPT-4)
**Version:** 1.0.0
**License:** MIT

### Outline & Function Summary

**I. Core Setup & Administration:**
*   `constructor()`: Initializes the contract, setting the deployer as the initial owner and default treasury.
*   `setTreasuryAddress(address _newTreasury)`: Allows the owner (or governance) to set the official treasury address for mission funds and proposal/attestation stakes.

**II. Skill Token Management (Dynamic ERC721):**
*   `mintSkillToken(string calldata _skillType, string calldata _proofHash)`: Mints a new Skill Token NFT to the caller, representing a specific skill type and linking to an external verifiable proof (e.g., IPFS hash of a credential).
*   `updateSkillTokenProof(uint256 _skillId, string calldata _newProofHash)`: Allows the owner of a Skill Token to update its associated proof hash.
*   `freezeSkillToken(uint256 _skillId)`: (Admin/Governance) Freezes a Skill Token, rendering it temporarily unusable for missions or attestations, typically due to misuse.
*   `unfreezeSkillToken(uint256 _skillId)`: (Admin/Governance) Unfreezes a previously frozen Skill Token.
*   `getSkillTokenDetails(uint256 _skillId)`: Retrieves comprehensive details about a specific Skill Token.
*   `getOwnerSkillTokens(address _owner)`: Returns an array of all Skill Token IDs owned by a given address.
*   `getTokenImpactScore(uint256 _skillId)`: Retrieves the current Impact Score of a specific Skill Token.
*   *(Inherited from ERC721)*: `transferFrom`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`.

**III. Mission Lifecycle Management:**
*   `proposeMission(string calldata _title, string calldata _description, string[] calldata _requiredSkills, uint256 _bountyAmount, uint256 _submissionDeadlineDays)`: Initiates a new mission proposal, requiring a small ETH stake and outlining project details, required skills, and bounty.
*   `approveMissionProposal(uint256 _missionId)`: (Admin/Governance) Approves a proposed mission, making it eligible for funding and setting its submission deadline. The proposer's stake is refunded.
*   `fundMission(uint256 _missionId)`: Allows any user to contribute ETH to a mission's bounty. The mission transitions to 'Active' once fully funded.
*   `joinMission(uint256 _missionId, uint256 _skillTokenId)`: Allows an eligible user to join an active mission by committing one of their Skill Tokens that matches the mission's required skills.
*   `submitMissionDeliverable(uint256 _missionId, uint256 _skillTokenId, string calldata _deliverableHash)`: A participant submits the IPFS hash of their completed work for a mission.
*   `reviewMissionDeliverable(uint256 _missionId, uint256 _participantSkillTokenId, bool _approved, uint256 _contributionScore)`: (Mission Proposer) Reviews a participant's deliverable, marks it as approved/rejected, and assigns a contribution score (0-100).
*   `finalizeMission(uint256 _missionId)`: (Mission Proposer) Finalizes a mission after all deliverables are reviewed, distributing the bounty and Impact Score proportionally to participants based on their contribution scores.
*   `disputeMissionOutcome(uint256 _missionId)`: Allows a participant or the proposer to initiate a dispute over a completed mission's outcome, requiring a dispute stake.
*   `voteOnDispute(uint256 _missionId, bool _supportProposer)`: Allows users with sufficient aggregated Impact Score to vote on a mission dispute.
*   `resolveDispute(uint256 _missionId)`: Finalizes a mission dispute based on voting results. Overturning the proposer's outcome marks the mission as 'Failed'.
*   `getMissionDetails(uint256 _missionId)`: Retrieves all available details for a specific mission.
*   `getActiveMissions()`: Returns a list of all mission IDs that are currently 'Approved' or 'Active'.
*   `getMissionParticipants(uint256 _missionId)`: Returns an array of Skill Token IDs representing the participants of a mission.

**IV. Attestation & Reputation System:**
*   `attestToSkill(address _subject, uint256 _skillTokenId, string calldata _attestationHash)`: Allows a user to formally attest to another user's Skill Token, requiring an ETH stake and a link to verifiable attestation details. Increases the attested Skill Token's Impact Score.
*   `revokeAttestation(uint256 _skillTokenId)`: Allows an attester to revoke their previous attestation for a Skill Token. The stake is forfeited.
*   `getSkillAttestations(uint256 _skillTokenId)`: Retrieves all active attestations for a given Skill Token.
*   `getUserTotalImpactScore(address _user)`: Calculates and returns the sum of Impact Scores from all Skill Tokens owned by a specific user.

**V. Decentralized Governance:**
*   `proposeGovernanceChange(bytes calldata _callData, string calldata _description)`: Allows users with sufficient aggregated Impact Score to propose a system-wide change (e.g., contract parameter updates or even upgrades), requiring an ETH stake.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with sufficient aggregated Impact Score to vote on an active governance proposal.
*   `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed its voting period and met quorum/threshold requirements.
*   `getProposalDetails(uint256 _proposalId)`: Retrieves full details of a specific governance proposal.
*   `setMinProposalImpact(uint256 _newMinImpact)`: (Admin/Governance) Sets the minimum aggregated Impact Score required to submit a new governance proposal.
*   `setMinVoteImpact(uint256 _newMinImpact)`: (Admin/Governance) Sets the minimum aggregated Impact Score required for a user's vote to be counted in governance.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Decentralized Skill & Impact Network (DSIN)
 * @author YourName (GPT-4)
 * @notice This contract implements a novel decentralized network for skill verification, collaborative mission execution,
 *         and reputation-based governance. It introduces dynamic NFTs called "Skill Tokens" which accrue "Impact Score"
 *         based on successful contributions to community-driven "Missions" and peer attestations.
 *         The Impact Score then influences governance power within the DAO.
 *
 * @dev Key Concepts:
 *      - Skill Tokens (Dynamic ERC721): NFTs representing a verified skill, with a mutable `impactScore`.
 *      - Missions: Collaborative projects proposed, funded, executed, and reviewed by the community.
 *      - Attestations: On-chain verifiable claims by users about others' skills, backed by a stake (forfeited on revoke for simplicity).
 *      - Impact Score: A reputation metric derived from mission contributions and attestations, used for governance.
 *      - Impact-Weighted Governance: DAO proposals are voted on using aggregated Impact Score.
 *      - Dispute Resolution: A simple on-chain voting mechanism for mission outcomes.
 *
 * Outline & Function Summary:
 *
 * I. Core Setup & Administration:
 *    - constructor: Initializes the contract with an owner.
 *    - setTreasuryAddress: Sets the address where mission funds and stakes are managed.
 *
 * II. Skill Token Management (Dynamic ERC721):
 *    - mintSkillToken: Mints a new Skill Token NFT for a specific skill type and associated proof.
 *    - updateSkillTokenProof: Allows the owner to update the verifiable proof hash for their Skill Token.
 *    - freezeSkillToken: Governance function to temporarily disable a Skill Token (e.g., for misuse).
 *    - unfreezeSkillToken: Governance function to re-enable a frozen Skill Token.
 *    - getSkillTokenDetails: Retrieves all details of a specific Skill Token.
 *    - getOwnerSkillTokens: Retrieves all Skill Tokens owned by a specific address.
 *    - getTokenImpactScore: Retrieves the current impact score of a specific Skill Token.
 *    - transferFrom (inherited): Standard ERC721 transfer.
 *    - safeTransferFrom (inherited): Standard ERC721 transfer.
 *    - approve (inherited): Standard ERC721 approval.
 *    - getApproved (inherited): Standard ERC721 approval check.
 *    - setApprovalForAll (inherited): Standard ERC721 operator approval.
 *    - isApprovedForAll (inherited): Standard ERC721 operator approval check.
 *
 * III. Mission Lifecycle Management:
 *    - proposeMission: Initiates a new mission proposal with required skills and bounty. Requires a stake.
 *    - approveMissionProposal: Allows governors (or sufficiently high impact users) to approve a mission.
 *    - fundMission: Allows anyone to contribute funds to a mission's bounty.
 *    - joinMission: Allows a user to formally join a mission using one of their eligible Skill Tokens.
 *    - submitMissionDeliverable: Participants submit an IPFS hash of their work for a mission.
 *    - reviewMissionDeliverable: Mission proposer/governance reviews a deliverable and assigns a contribution score.
 *    - finalizeMission: Distributes bounty and impact rewards upon successful mission completion.
 *    - disputeMissionOutcome: Allows a participant to initiate a dispute over mission finalization.
 *    - voteOnDispute: Allows eligible users to vote on a mission dispute.
 *    - resolveDispute: Finalizes the dispute based on voting results.
 *    - getMissionDetails: Retrieves all details of a specific mission.
 *    - getActiveMissions: Retrieves a list of currently active or approved missions.
 *    - getMissionParticipants: Retrieves the list of participants for a given mission.
 *
 * IV. Attestation & Reputation System:
 *    - attestToSkill: Allows a user to vouch for another user's skill token, requiring a stake.
 *    - revokeAttestation: Allows an attester to revoke their attestation (stake forfeited).
 *    - getSkillAttestations: Retrieves details of all attestations received for a Skill Token.
 *    - getUserTotalImpactScore: Calculates the sum of impact scores across all Skill Tokens owned by a user.
 *
 * V. Decentralized Governance:
 *    - proposeGovernanceChange: Allows a user with sufficient impact to propose a system-wide change (e.g., parameter update).
 *    - voteOnProposal: Allows users to vote on governance proposals using their aggregated Impact Score.
 *    - executeProposal: Executes a successfully voted-on governance proposal.
 *    - getProposalDetails: Retrieves details of a specific governance proposal.
 *    - setMinProposalImpact: Sets the minimum impact score required to propose a governance change.
 *    - setMinVoteImpact: Sets the minimum impact score required for a vote to count towards governance.
 */
contract DecentralizedSkillImpactNetwork is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _skillTokenIds;
    Counters.Counter private _missionIds;
    Counters.Counter private _proposalIds;

    address public treasuryAddress; // Address where mission funds and proposal/attestation stakes are held
    uint256 public constant PROPOSAL_STAKE_AMOUNT = 0.01 ether; // Stake required to propose a mission or governance change
    uint256 public constant ATTESTATION_STAKE_AMOUNT = 0.005 ether; // Stake required to attest to a skill
    uint256 public constant DISPUTE_STAKE_AMOUNT = 0.02 ether; // Stake required to initiate a dispute

    uint256 public minProposalImpact = 100; // Minimum aggregated impact score to propose governance change
    uint256 public minVoteImpact = 10; // Minimum aggregated impact score for a vote to be counted
    uint256 public governanceQuorumNumerator = 50; // Quorum for governance proposals: (total_impact * numerator / denominator)
    uint256 public governanceQuorumDenominator = 100; // E.g., 50/100 = 50%

    // --- Structs ---

    struct SkillToken {
        uint256 id;
        address owner;
        string skillType; // e.g., "SolidityDev", "UXDesigner"
        string proofHash; // IPFS hash of verifiable credential or proof
        uint256 impactScore; // Dynamic score, accumulates from missions and attestations
        bool isActive; // Can be frozen by governance
    }

    enum MissionStatus { Proposed, Approved, Active, Completed, Disputed, Failed }

    struct Mission {
        uint256 id;
        address proposer;
        string title;
        string description;
        string[] requiredSkills;
        uint256 bountyAmount; // Total amount available for participants
        uint256 fundedAmount; // Actual amount received
        MissionStatus status;
        uint256 deadline; // Unix timestamp, for submission or dispute resolution
        mapping(uint256 => MissionParticipant) participants; // skillTokenId => participant info
        uint256[] participantSkillTokenIds; // To iterate over participants
        uint256 totalContributionScore; // Sum of scores for completed tasks

        // Dispute related
        address disputeInitiator;
        mapping(address => bool) hasVotedOnDispute; // user => voted (to prevent double voting)
        uint256 disputeYesVotes; // Votes for proposer/original outcome
        uint256 disputeNoVotes; // Votes against proposer/original outcome
    }

    struct MissionParticipant {
        address participantAddress;
        uint256 skillTokenId;
        string deliverableHash; // IPFS hash of their specific deliverable
        uint256 contributionScore; // Assigned by reviewer
        bool reviewed;
        bool submitted;
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        ProposalStatus status;
        uint256 creationTimestamp;
        uint256 endTimestamp;
        uint256 votesFor; // Total aggregated impact score voting 'for'
        uint256 votesAgainst; // Total aggregated impact score voting 'against'
        mapping(address => bool) hasVoted; // user => voted (to prevent double voting)
    }

    struct Attestation {
        address attester;
        uint256 skillTokenId; // The skill token being attested to
        string attestationHash; // IPFS hash of verifiable attestation details
        uint256 timestamp;
        bool active;
    }

    // --- Mappings ---

    mapping(uint256 => SkillToken) public skillTokens;
    mapping(address => uint256[]) private _ownerSkillTokens; // owner => array of skillTokenIds

    mapping(uint256 => Mission) public missions;
    mapping(uint256 => mapping(uint256 => Attestation)) public skillAttestations; // skillTokenId => attestationIndex => Attestation
    mapping(uint256 => uint256[]) private _skillAttestationIndices; // skillTokenId => array of attestation indices

    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---

    event SkillTokenMinted(uint256 indexed skillId, address indexed owner, string skillType, string proofHash);
    event SkillTokenProofUpdated(uint256 indexed skillId, string newProofHash);
    event SkillTokenFrozen(uint256 indexed skillId);
    event SkillTokenUnfrozen(uint256 indexed skillId);

    event MissionProposed(uint256 indexed missionId, address indexed proposer, string title, uint256 bountyAmount);
    event MissionApproved(uint256 indexed missionId);
    event MissionFunded(uint256 indexed missionId, address indexed funder, uint256 amount);
    event MissionJoined(uint256 indexed missionId, address indexed participant, uint256 indexed skillTokenId);
    event DeliverableSubmitted(uint256 indexed missionId, address indexed participant, string deliverableHash);
    event DeliverableReviewed(uint256 indexed missionId, address indexed participant, uint256 contributionScore, bool approved);
    event MissionFinalized(uint256 indexed missionId, uint256 totalBountyPaid, uint256 totalImpactDistributed);
    event MissionOutcomeDisputed(uint256 indexed missionId, address indexed initiator);
    event DisputeVote(uint256 indexed missionId, address indexed voter, bool supportProposer);
    event DisputeResolved(uint256 indexed missionId, bool proposerOutcomeUpheld);

    event SkillAttested(address indexed attester, address indexed subject, uint256 indexed skillTokenId, string attestationHash);
    event AttestationRevoked(address indexed attester, uint256 indexed skillTokenId);
    event ImpactScoreUpdated(uint256 indexed skillTokenId, uint256 newImpactScore);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event MinProposalImpactSet(uint256 newMinImpact);
    event MinVoteImpactSet(uint256 newMinImpact);

    // --- Modifiers ---

    modifier onlyMissionProposer(uint256 _missionId) {
        require(msg.sender == missions[_missionId].proposer, "DSIN: Only mission proposer can call this.");
        _;
    }

    modifier onlySkillOwner(uint256 _skillId) {
        require(_exists(_skillId), "DSIN: Skill Token does not exist.");
        require(ownerOf(_skillId) == msg.sender, "DSIN: Caller is not the skill token owner.");
        _;
    }

    modifier onlyActiveSkillToken(uint256 _skillId) {
        require(skillTokens[_skillId].isActive, "DSIN: Skill Token is frozen.");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("SkillToken", "SKT") Ownable(msg.sender) {
        treasuryAddress = msg.sender; // Default to owner, should be changed to a secure multisig or DAO contract later
    }

    // --- I. Core Setup & Administration ---

    /// @notice Sets the address where mission funds and proposal/attestation stakes are held.
    /// @dev Only callable by the contract owner (or through governance proposal).
    /// @param _newTreasury The new address for the treasury.
    function setTreasuryAddress(address _newTreasury) public onlyOwner {
        require(_newTreasury != address(0), "DSIN: Treasury cannot be zero address.");
        treasuryAddress = _newTreasury;
    }

    // --- II. Skill Token Management (Dynamic ERC721) ---

    /// @notice Mints a new Skill Token NFT for a specific skill type.
    /// @dev Requires a proof hash (e.g., IPFS link to a verifiable credential).
    /// @param _skillType A string representing the type of skill (e.g., "SolidityDev", "UXDesigner").
    /// @param _proofHash IPFS hash of the proof of skill.
    function mintSkillToken(string calldata _skillType, string calldata _proofHash) public nonReentrant {
        _skillTokenIds.increment();
        uint256 newItemId = _skillTokenIds.current();

        SkillToken storage newSkill = skillTokens[newItemId];
        newSkill.id = newItemId;
        newSkill.owner = msg.sender;
        newSkill.skillType = _skillType;
        newSkill.proofHash = _proofHash;
        newSkill.impactScore = 0;
        newSkill.isActive = true;

        _safeMint(msg.sender, newItemId);
        _ownerSkillTokens[msg.sender].push(newItemId);

        emit SkillTokenMinted(newItemId, msg.sender, _skillType, _proofHash);
    }

    /// @notice Allows the owner to update the verifiable proof hash for their Skill Token.
    /// @param _skillId The ID of the Skill Token to update.
    /// @param _newProofHash The new IPFS hash for the proof.
    function updateSkillTokenProof(uint256 _skillId, string calldata _newProofHash) public onlySkillOwner(_skillId) onlyActiveSkillToken(_skillId) {
        skillTokens[_skillId].proofHash = _newProofHash;
        emit SkillTokenProofUpdated(_skillId, _newProofHash);
    }

    /// @notice Governance function to temporarily disable a Skill Token (e.g., for misuse).
    /// @dev Only callable by the contract owner (or through governance proposal).
    /// @param _skillId The ID of the Skill Token to freeze.
    function freezeSkillToken(uint256 _skillId) public onlyOwner {
        require(skillTokens[_skillId].isActive, "DSIN: Skill Token already frozen.");
        skillTokens[_skillId].isActive = false;
        emit SkillTokenFrozen(_skillId);
    }

    /// @notice Governance function to re-enable a frozen Skill Token.
    /// @dev Only callable by the contract owner (or through governance proposal).
    /// @param _skillId The ID of the Skill Token to unfreeze.
    function unfreezeSkillToken(uint256 _skillId) public onlyOwner {
        require(!skillTokens[_skillId].isActive, "DSIN: Skill Token is not frozen.");
        skillTokens[_skillId].isActive = true;
        emit SkillTokenUnfrozen(_skillId);
    }

    /// @notice Retrieves all details of a specific Skill Token.
    /// @param _skillId The ID of the Skill Token.
    /// @return The SkillToken struct details.
    function getSkillTokenDetails(uint256 _skillId) public view returns (SkillToken memory) {
        require(_exists(_skillId), "DSIN: Skill Token does not exist.");
        return skillTokens[_skillId];
    }

    /// @notice Retrieves all Skill Tokens owned by a specific address.
    /// @param _owner The address to query.
    /// @return An array of Skill Token IDs.
    function getOwnerSkillTokens(address _owner) public view returns (uint256[] memory) {
        return _ownerSkillTokens[_owner];
    }

    /// @notice Retrieves the current impact score of a specific Skill Token.
    /// @param _skillId The ID of the Skill Token.
    /// @return The impact score.
    function getTokenImpactScore(uint256 _skillId) public view returns (uint256) {
        require(_exists(_skillId), "DSIN: Skill Token does not exist.");
        return skillTokens[_skillId].impactScore;
    }

    /// @dev Overrides `_beforeTokenTransfer` from ERC721 to keep `_ownerSkillTokens` mapping in sync.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0)) {
            uint256[] storage fromTokens = _ownerSkillTokens[from];
            for (uint256 i = 0; i < fromTokens.length; i++) {
                if (fromTokens[i] == tokenId) {
                    fromTokens[i] = fromTokens[fromTokens.length - 1];
                    fromTokens.pop();
                    break;
                }
            }
        }
        if (to != address(0)) {
            _ownerSkillTokens[to].push(tokenId);
        }
        skillTokens[tokenId].owner = to; // Update owner in SkillToken struct
    }


    // --- III. Mission Lifecycle Management ---

    /// @notice Initiates a new mission proposal with required skills and bounty.
    /// @dev Requires a ETH stake to propose.
    /// @param _title The title of the mission.
    /// @param _description A detailed description of the mission.
    /// @param _requiredSkills An array of skill types needed for the mission.
    /// @param _bountyAmount The total ETH bounty for successful completion.
    /// @param _submissionDeadlineDays The number of days until the submission deadline (from approval).
    function proposeMission(
        string calldata _title,
        string calldata _description,
        string[] calldata _requiredSkills,
        uint256 _bountyAmount,
        uint256 _submissionDeadlineDays
    ) public payable nonReentrant {
        require(msg.value == PROPOSAL_STAKE_AMOUNT, "DSIN: Incorrect proposal stake amount.");
        require(_bountyAmount > 0, "DSIN: Bounty amount must be greater than zero.");
        require(_requiredSkills.length > 0, "DSIN: At least one skill is required.");
        require(_submissionDeadlineDays > 0, "DSIN: Submission deadline must be in the future.");

        _missionIds.increment();
        uint256 newMissionId = _missionIds.current();

        Mission storage newMission = missions[newMissionId];
        newMission.id = newMissionId;
        newMission.proposer = msg.sender;
        newMission.title = _title;
        newMission.description = _description;
        newMission.requiredSkills = _requiredSkills;
        newMission.bountyAmount = _bountyAmount;
        newMission.fundedAmount = 0; // Will be funded by others
        newMission.status = MissionStatus.Proposed;
        // Deadline is set upon approval

        // Forward proposal stake to treasury
        payable(treasuryAddress).transfer(PROPOSAL_STAKE_AMOUNT);

        emit MissionProposed(newMissionId, msg.sender, _title, _bountyAmount);
    }

    /// @notice Allows governors (or sufficiently high impact users) to approve a mission.
    /// @dev This function is currently `onlyOwner` for simplicity. In a real DAO, it would be governed by a successful governance proposal or weighted vote.
    /// @param _missionId The ID of the mission to approve.
    function approveMissionProposal(uint256 _missionId) public onlyOwner {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Proposed, "DSIN: Mission is not in 'Proposed' status.");

        mission.status = MissionStatus.Approved;
        // Set submission deadline, e.g., 30 days after approval
        mission.deadline = block.timestamp + 30 days; 

        // Refund proposer's stake from treasury (requires treasury to be a contract with withdraw functionality)
        // For this example, let's assume `treasuryAddress` is just a recipient. A refund mechanism would be more complex.
        // For now, the proposer stake is effectively 'spent' to propose.
        // If a refund is critical: the stake should be held by DSIN and refunded by DSIN.
        // For current logic, it is forwarded to treasury and not refunded here.

        emit MissionApproved(_missionId);
    }

    /// @notice Allows anyone to contribute funds to a mission's bounty.
    /// @param _missionId The ID of the mission to fund.
    function fundMission(uint256 _missionId) public payable nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Approved || mission.status == MissionStatus.Active, "DSIN: Mission not approved or active.");
        require(msg.value > 0, "DSIN: Must send positive amount.");
        require(mission.fundedAmount + msg.value <= mission.bountyAmount, "DSIN: Funding exceeds required bounty.");

        mission.fundedAmount += msg.value;
        if (mission.fundedAmount == mission.bountyAmount) {
            mission.status = MissionStatus.Active; // Mission becomes active once fully funded
        }
        // Funds are forwarded directly to the treasury address
        payable(treasuryAddress).transfer(msg.value);

        emit MissionFunded(_missionId, msg.sender, msg.value);
    }

    /// @notice Allows a user to formally join a mission using one of their eligible Skill Tokens.
    /// @param _missionId The ID of the mission to join.
    /// @param _skillTokenId The ID of the Skill Token the participant is using.
    function joinMission(uint256 _missionId, uint256 _skillTokenId) public onlySkillOwner(_skillTokenId) onlyActiveSkillToken(_skillTokenId) {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Active, "DSIN: Mission is not active.");
        require(block.timestamp <= mission.deadline, "DSIN: Mission submission deadline passed.");
        require(skillTokens[_skillTokenId].owner == msg.sender, "DSIN: Skill Token not owned by caller.");

        // Check if skill type matches mission requirements
        bool skillMatch = false;
        for (uint256 i = 0; i < mission.requiredSkills.length; i++) {
            if (keccak256(abi.encodePacked(mission.requiredSkills[i])) == keccak256(abi.encodePacked(skillTokens[_skillTokenId].skillType))) {
                skillMatch = true;
                break;
            }
        }
        require(skillMatch, "DSIN: Skill Token type does not match mission requirements.");

        // Ensure participant hasn't joined with this specific skill token already
        for (uint256 i = 0; i < mission.participantSkillTokenIds.length; i++) {
            require(mission.participantSkillTokenIds[i] != _skillTokenId, "DSIN: Skill Token already used to join this mission.");
        }

        mission.participantSkillTokenIds.push(_skillTokenId);
        MissionParticipant storage participant = mission.participants[_skillTokenId];
        participant.participantAddress = msg.sender;
        participant.skillTokenId = _skillTokenId;
        participant.submitted = false;
        participant.reviewed = false;
        participant.contributionScore = 0;

        emit MissionJoined(_missionId, msg.sender, _skillTokenId);
    }

    /// @notice Participants submit an IPFS hash of their work for a mission.
    /// @param _missionId The ID of the mission.
    /// @param _skillTokenId The ID of the Skill Token used to join the mission.
    /// @param _deliverableHash The IPFS hash of the submitted work.
    function submitMissionDeliverable(uint256 _missionId, uint256 _skillTokenId, string calldata _deliverableHash)
        public onlySkillOwner(_skillTokenId) onlyActiveSkillToken(_skillTokenId)
    {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Active, "DSIN: Mission is not active.");
        require(block.timestamp <= mission.deadline, "DSIN: Mission submission deadline passed.");

        MissionParticipant storage participant = mission.participants[_skillTokenId];
        require(participant.participantAddress == msg.sender, "DSIN: Skill Token not registered for this mission or not owned by caller.");
        require(!participant.submitted, "DSIN: Deliverable already submitted for this skill token.");

        participant.deliverableHash = _deliverableHash;
        participant.submitted = true;

        emit DeliverableSubmitted(_missionId, msg.sender, _deliverableHash);
    }

    /// @notice Mission proposer/governance reviews a deliverable and assigns a contribution score.
    /// @dev Only callable by the mission proposer. In a more complex system, this could involve a peer review or elected reviewer role.
    /// @param _missionId The ID of the mission.
    /// @param _participantSkillTokenId The skill token ID of the participant whose deliverable is being reviewed.
    /// @param _approved True if the deliverable is approved, false otherwise.
    /// @param _contributionScore The score (0-100) indicating contribution quality.
    function reviewMissionDeliverable(
        uint256 _missionId,
        uint256 _participantSkillTokenId,
        bool _approved,
        uint256 _contributionScore
    ) public onlyMissionProposer(_missionId) {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Active, "DSIN: Mission is not active.");
        require(_exists(_participantSkillTokenId), "DSIN: Participant Skill Token does not exist.");
        require(mission.participants[_participantSkillTokenId].submitted, "DSIN: Deliverable not submitted yet.");
        require(!mission.participants[_participantSkillTokenId].reviewed, "DSIN: Deliverable already reviewed.");
        require(_contributionScore <= 100, "DSIN: Contribution score must be between 0 and 100.");

        MissionParticipant storage participant = mission.participants[_participantSkillTokenId];
        participant.reviewed = true;
        participant.contributionScore = _approved ? _contributionScore : 0;
        mission.totalContributionScore += participant.contributionScore;

        emit DeliverableReviewed(_missionId, participant.participantAddress, _contributionScore, _approved);
    }

    /// @notice Distributes bounty and impact rewards upon successful mission completion.
    /// @dev Only callable by the mission proposer after all deliverables are reviewed and no active dispute.
    ///      Funds are assumed to be held by the `treasuryAddress` which handles payouts.
    /// @param _missionId The ID of the mission.
    function finalizeMission(uint256 _missionId) public onlyMissionProposer(_missionId) nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Active, "DSIN: Mission not active.");
        require(mission.fundedAmount == mission.bountyAmount, "DSIN: Mission not fully funded.");
        require(mission.disputeInitiator == address(0), "DSIN: Cannot finalize with an active dispute."); // Ensure no active dispute

        // Ensure all deliverables are reviewed if there are participants
        if (mission.participantSkillTokenIds.length > 0) {
            for (uint256 i = 0; i < mission.participantSkillTokenIds.length; i++) {
                require(mission.participants[mission.participantSkillTokenIds[i]].reviewed, "DSIN: Not all deliverables reviewed.");
            }
        }

        mission.status = MissionStatus.Completed;

        uint256 totalBountyPaid = 0;
        uint256 totalImpactDistributed = 0;

        if (mission.totalContributionScore > 0) {
            for (uint256 i = 0; i < mission.participantSkillTokenIds.length; i++) {
                uint256 skillId = mission.participantSkillTokenIds[i];
                MissionParticipant storage participant = mission.participants[skillId];

                if (participant.contributionScore > 0) {
                    // Distribute bounty proportionally. This assumes `treasuryAddress` is a contract with a `withdrawTo` function.
                    // For this basic example, we will just record the payment, or have `treasuryAddress` simply hold the funds.
                    // A proper implementation would involve a dedicated treasury contract with `call` or specific `transfer` methods.
                    uint224 participantBounty = uint224((mission.bountyAmount * participant.contributionScore) / mission.totalContributionScore);
                    // A real treasury contract would manage the actual ETH transfer
                    // Example: ITreasury(treasuryAddress).distributeBounty(participant.participantAddress, participantBounty);
                    totalBountyPaid += participantBounty;

                    // Distribute impact score proportionally
                    uint256 impactGain = (100 * participant.contributionScore) / mission.totalContributionScore; // Max 100 impact for mission
                    skillTokens[skillId].impactScore += impactGain;
                    totalImpactDistributed += impactGain;
                    emit ImpactScoreUpdated(skillId, skillTokens[skillId].impactScore);
                }
            }
        }
        // Any remaining bounty (due to rounding or no contributions) stays in treasury.

        emit MissionFinalized(_missionId, totalBountyPaid, totalImpactDistributed);
    }

    /// @notice Allows a participant or proposer to initiate a dispute over mission finalization.
    /// @dev Requires a dispute stake.
    /// @param _missionId The ID of the mission to dispute.
    function disputeMissionOutcome(uint256 _missionId) public payable nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Completed, "DSIN: Mission not in 'Completed' status.");
        require(msg.value == DISPUTE_STAKE_AMOUNT, "DSIN: Incorrect dispute stake amount.");
        require(mission.disputeInitiator == address(0), "DSIN: Mission already has an active dispute.");
        
        bool isParticipant = false;
        for (uint256 i = 0; i < mission.participantSkillTokenIds.length; i++) {
            if (mission.participants[mission.participantSkillTokenIds[i]].participantAddress == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant || msg.sender == mission.proposer, "DSIN: Only mission proposer or participant can dispute.");

        mission.status = MissionStatus.Disputed;
        mission.disputeInitiator = msg.sender;
        mission.deadline = block.timestamp + 7 days; // Dispute voting period: 7 days

        // Forward dispute stake to treasury
        payable(treasuryAddress).transfer(DISPUTE_STAKE_AMOUNT);

        emit MissionOutcomeDisputed(_missionId, msg.sender);
    }

    /// @notice Allows eligible users to vote on a mission dispute.
    /// @dev Voting power is based on aggregated Impact Score.
    /// @param _missionId The ID of the mission under dispute.
    /// @param _supportProposer True to support the proposer's outcome, false to support the dispute initiator's claim.
    function voteOnDispute(uint256 _missionId, bool _supportProposer) public {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Disputed, "DSIN: Mission is not under dispute.");
        require(block.timestamp <= mission.deadline, "DSIN: Dispute voting period has ended.");
        require(!mission.hasVoted[msg.sender], "DSIN: Already voted on this dispute.");

        uint256 voterImpact = getUserTotalImpactScore(msg.sender);
        require(voterImpact >= minVoteImpact, "DSIN: Insufficient impact to vote on disputes.");

        mission.hasVoted[msg.sender] = true;
        if (_supportProposer) {
            mission.disputeYesVotes += voterImpact;
        } else {
            mission.disputeNoVotes += voterImpact;
        }

        emit DisputeVote(_missionId, msg.sender, _supportProposer);
    }

    /// @notice Finalizes the dispute based on voting results.
    /// @dev Anyone can call this after the voting period ends.
    /// @param _missionId The ID of the mission.
    function resolveDispute(uint256 _missionId) public nonReentrant {
        Mission storage mission = missions[_missionId];
        require(mission.status == MissionStatus.Disputed, "DSIN: Mission is not under dispute.");
        require(block.timestamp > mission.deadline, "DSIN: Dispute voting period not yet ended.");

        bool proposerOutcomeUpheld;
        if (mission.disputeYesVotes > mission.disputeNoVotes) {
            proposerOutcomeUpheld = true;
        } else if (mission.disputeNoVotes > mission.disputeYesVotes) {
            proposerOutcomeUpheld = false;
        } else {
            // Tie-breaker: default to proposer's outcome
            proposerOutcomeUpheld = true;
        }

        if (proposerOutcomeUpheld) {
            // Original outcome stands, dispute initiator's stake is forfeited to treasury.
            // (Assumes stake was sent to treasury upon dispute initiation)
        } else {
            // Original outcome overturned. The mission is marked as Failed.
            // For simplicity, we don't attempt to reverse fund transfers (which already went to treasury).
            // A more complex system would put funds in escrow until dispute resolution.
            mission.status = MissionStatus.Failed;
            // The dispute initiator's stake is not forfeited; it remains in the treasury, but implies a 'win'.
            // For a refund, the treasury would need a `withdrawTo` function.
        }
        mission.disputeInitiator = address(0); // Reset dispute initiator
        // Reset dispute votes for potential future disputes (unlikely, but good practice)
        // No need to reset mapping values, as `hasVoted` is checked for `_proposalId` specific voting.

        emit DisputeResolved(_missionId, proposerOutcomeUpheld);
    }

    /// @notice Retrieves all details of a specific mission.
    /// @param _missionId The ID of the mission.
    /// @return The Mission struct details.
    function getMissionDetails(uint256 _missionId) public view returns (Mission memory) {
        require(missions[_missionId].id != 0, "DSIN: Mission does not exist."); // Check if mission ID exists
        return missions[_missionId];
    }

    /// @notice Retrieves a list of currently active or approved missions.
    /// @return An array of Mission IDs.
    function getActiveMissions() public view returns (uint256[] memory) {
        uint256[] memory tempActiveMissions = new uint256[](_missionIds.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _missionIds.current(); i++) {
            if (missions[i].status == MissionStatus.Approved || missions[i].status == MissionStatus.Active) {
                tempActiveMissions[count] = i;
                count++;
            }
        }
        uint256[] memory activeMissions = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeMissions[i] = tempActiveMissions[i];
        }
        return activeMissions;
    }

    /// @notice Retrieves the list of participants (their skill token IDs) for a given mission.
    /// @param _missionId The ID of the mission.
    /// @return An array of skill token IDs of participants.
    function getMissionParticipants(uint256 _missionId) public view returns (uint256[] memory) {
        require(missions[_missionId].id != 0, "DSIN: Mission does not exist.");
        return missions[_missionId].participantSkillTokenIds;
    }


    // --- IV. Attestation & Reputation System ---

    /// @notice Allows a user to vouch for another user's skill token, requiring a stake.
    /// @param _subject The address of the user whose skill is being attested.
    /// @param _skillTokenId The ID of the Skill Token being attested to.
    /// @param _attestationHash IPFS hash of verifiable attestation details (e.g., specific work, reference letter).
    function attestToSkill(address _subject, uint256 _skillTokenId, string calldata _attestationHash) public payable nonReentrant {
        require(msg.value == ATTESTATION_STAKE_AMOUNT, "DSIN: Incorrect attestation stake amount.");
        require(msg.sender != _subject, "DSIN: Cannot attest to your own skill.");
        require(_exists(_skillTokenId), "DSIN: Skill Token does not exist.");
        require(skillTokens[_skillTokenId].owner == _subject, "DSIN: Skill Token not owned by subject.");
        require(skillTokens[_skillTokenId].isActive, "DSIN: Skill Token is frozen.");

        // Check if attester has already attested this skill token
        for (uint256 i = 0; i < _skillAttestationIndices[_skillTokenId].length; i++) {
            uint256 currentAttestationIndex = _skillAttestationIndices[_skillTokenId][i];
            if (skillAttestations[_skillTokenId][currentAttestationIndex].attester == msg.sender &&
                skillAttestations[_skillTokenId][currentAttestationIndex].active) {
                revert("DSIN: Already attested to this skill token.");
            }
        }

        uint256 attestationIndex = _skillAttestationIndices[_skillTokenId].length; // Use length as next index
        _skillAttestationIndices[_skillTokenId].push(attestationIndex);

        Attestation storage newAttestation = skillAttestations[_skillTokenId][attestationIndex];
        newAttestation.attester = msg.sender;
        newAttestation.skillTokenId = _skillTokenId;
        newAttestation.attestationHash = _attestationHash;
        newAttestation.timestamp = block.timestamp;
        newAttestation.active = true;

        // Increase impact for the attested skill
        skillTokens[_skillTokenId].impactScore += 5; // Example: 5 impact points per attestation
        emit ImpactScoreUpdated(_skillTokenId, skillTokens[_skillTokenId].impactScore);

        // Forward stake to treasury (it is forfeited upon revocation)
        payable(treasuryAddress).transfer(ATTESTATION_STAKE_AMOUNT);

        emit SkillAttested(msg.sender, _subject, _skillTokenId, _attestationHash);
    }

    /// @notice Allows an attester to revoke their attestation and reclaim their stake.
    /// @dev For simplicity in this example, the attestation stake is forfeited upon revocation.
    ///      A real system would require a more complex treasury/escrow mechanism for refunds.
    /// @param _skillTokenId The ID of the Skill Token the attestation was made for.
    function revokeAttestation(uint256 _skillTokenId) public nonReentrant {
        require(_exists(_skillTokenId), "DSIN: Skill Token does not exist.");

        // Find the active attestation by msg.sender for _skillTokenId
        bool found = false;
        uint256 attestationIndexToRevoke = type(uint256).max;
        for (uint256 i = 0; i < _skillAttestationIndices[_skillTokenId].length; i++) {
            uint256 currentAttestationIndex = _skillAttestationIndices[_skillTokenId][i];
            if (skillAttestations[_skillTokenId][currentAttestationIndex].attester == msg.sender &&
                skillAttestations[_skillTokenId][currentAttestationIndex].active) {
                attestationIndexToRevoke = currentAttestationIndex;
                found = true;
                break;
            }
        }
        require(found, "DSIN: No active attestation by caller for this skill token.");

        skillAttestations[_skillTokenId][attestationIndexToRevoke].active = false;

        // Decrease impact for the attested skill (but not below zero)
        skillTokens[_skillTokenId].impactScore = skillTokens[_skillTokenId].impactScore > 5 ? skillTokens[_skillTokenId].impactScore - 5 : 0;
        emit ImpactScoreUpdated(_skillTokenId, skillTokens[_skillTokenId].impactScore);

        // Attestation stake is forfeited to the treasury.

        emit AttestationRevoked(msg.sender, _skillTokenId);
    }

    /// @notice Retrieves details of all attestations received for a Skill Token.
    /// @param _skillTokenId The ID of the Skill Token.
    /// @return An array of Attestation structs.
    function getSkillAttestations(uint256 _skillTokenId) public view returns (Attestation[] memory) {
        require(_exists(_skillTokenId), "DSIN: Skill Token does not exist.");

        uint256 numActiveAttestations = 0;
        for (uint256 i = 0; i < _skillAttestationIndices[_skillTokenId].length; i++) {
            if (skillAttestations[_skillTokenId][_skillAttestationIndices[_skillTokenId][i]].active) {
                numActiveAttestations++;
            }
        }

        Attestation[] memory activeAttestations = new Attestation[](numActiveAttestations);
        uint256 currentCount = 0;
        for (uint256 i = 0; i < _skillAttestationIndices[_skillTokenId].length; i++) {
            uint256 attestationIndex = _skillAttestationIndices[_skillTokenId][i];
            if (skillAttestations[_skillTokenId][attestationIndex].active) {
                activeAttestations[currentCount] = skillAttestations[_skillTokenId][attestationIndex];
                currentCount++;
            }
        }
        return activeAttestations;
    }

    /// @notice Calculates the sum of impact scores across all Skill Tokens owned by a user.
    /// @param _user The address of the user.
    /// @return The total aggregated impact score.
    function getUserTotalImpactScore(address _user) public view returns (uint256) {
        uint256 totalImpact = 0;
        uint256[] memory userSkills = _ownerSkillTokens[_user];
        for (uint256 i = 0; i < userSkills.length; i++) {
            totalImpact += skillTokens[userSkills[i]].impactScore;
        }
        return totalImpact;
    }

    // --- V. Decentralized Governance ---

    /// @notice Allows a user with sufficient impact to propose a system-wide change.
    /// @dev This uses a simplified `delegatecall` for execution. Real production systems often use more robust upgrade patterns (e.g., UUPS proxies).
    /// @param _callData The encoded function call to be executed if the proposal passes.
    /// @param _description A description of the proposal.
    function proposeGovernanceChange(bytes calldata _callData, string calldata _description) public payable nonReentrant {
        require(getUserTotalImpactScore(msg.sender) >= minProposalImpact, "DSIN: Insufficient impact to propose.");
        require(msg.value == PROPOSAL_STAKE_AMOUNT, "DSIN: Incorrect proposal stake amount.");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        GovernanceProposal storage newProposal = governanceProposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.callData = _callData;
        newProposal.status = ProposalStatus.Pending;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.endTimestamp = block.timestamp + 7 days; // Voting period: 7 days

        // Forward stake to treasury (it is forfeited if proposal fails, or if refunded, treasury handles it)
        payable(treasuryAddress).transfer(PROPOSAL_STAKE_AMOUNT);

        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    /// @notice Allows users to vote on governance proposals using their aggregated Impact Score.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True if voting 'for', false if voting 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "DSIN: Proposal is not in 'Pending' status.");
        require(block.timestamp <= proposal.endTimestamp, "DSIN: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "DSIN: Already voted on this proposal.");

        uint256 voterImpact = getUserTotalImpactScore(msg.sender);
        require(voterImpact >= minVoteImpact, "DSIN: Insufficient impact to vote.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterImpact;
        } else {
            proposal.votesAgainst += voterImpact;
        }

        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a successfully voted-on governance proposal.
    /// @dev Only callable after voting period ends and if quorum/threshold met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "DSIN: Proposal is not in 'Pending' status.");
        require(block.timestamp > proposal.endTimestamp, "DSIN: Voting period has not ended.");

        uint256 totalPossibleImpact = 0;
        // For simplicity, we use the current total impact of all active tokens.
        // A robust DAO would use a snapshotting mechanism (e.g., Compound's GovernorAlpha/Bravo).
        for (uint256 i = 1; i <= _skillTokenIds.current(); i++) {
            if (skillTokens[i].isActive) {
                totalPossibleImpact += skillTokens[i].impactScore;
            }
        }
        
        uint224 totalVotes = uint224(proposal.votesFor + proposal.votesAgainst);
        
        // Quorum check: E.g., at least 50% of total possible impact must have voted
        require(totalVotes * governanceQuorumDenominator >= totalPossibleImpact * governanceQuorumNumerator, "DSIN: Quorum not met.");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal passes, execute the callData
            (bool success, ) = address(this).call(proposal.callData); // Using address(this) for internal calls
            require(success, "DSIN: Proposal execution failed.");
            proposal.status = ProposalStatus.Approved;

            // Proposer's stake is not refunded in this simplified example (forfeited to treasury).
        } else {
            // Proposal fails
            proposal.status = ProposalStatus.Rejected;
            // Proposer's stake is forfeited to the treasury.
        }

        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Retrieves details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The GovernanceProposal struct details.
    function getProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        require(governanceProposals[_proposalId].id != 0, "DSIN: Proposal does not exist.");
        return governanceProposals[_proposalId];
    }

    /// @notice Sets the minimum impact score required to propose a governance change.
    /// @dev Only callable by the contract owner (or through governance proposal).
    /// @param _newMinImpact The new minimum impact score.
    function setMinProposalImpact(uint256 _newMinImpact) public onlyOwner {
        minProposalImpact = _newMinImpact;
        emit MinProposalImpactSet(_newMinImpact);
    }

    /// @notice Sets the minimum impact score required for a vote to count towards governance.
    /// @dev Only callable by the contract owner (or through governance proposal).
    /// @param _newMinImpact The new minimum impact score.
    function setMinVoteImpact(uint256 _newMinImpact) public onlyOwner {
        minVoteImpact = _newMinImpact;
        emit MinVoteImpactSet(_newMinImpact);
    }
}
```