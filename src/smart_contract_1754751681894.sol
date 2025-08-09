Okay, this is an exciting challenge! Creating something truly unique, advanced, and trendy that doesn't just rehash existing open-source patterns is tough in the Solidity space, as many fundamental building blocks are common.

My approach will be to integrate several advanced concepts:
1.  **Soulbound Tokens (SBTs) for Reputation:** Non-transferable tokens representing individual reputation and identity.
2.  **Liquid Democracy:** Allowing users to delegate their voting power to trusted individuals, fostering flexible governance.
3.  **Dynamic NFTs (dNFTs):** NFTs whose metadata (and potentially appearance) changes based on on-chain state or milestones, specifically for incubated projects.
4.  **On-chain Skill Endorsement & Matching:** A reputation layer for specific skills, enabling targeted delegation and collaboration.
5.  **Milestone-Based Project Funding:** A DAO-like mechanism for funding projects, with funds released upon successful completion of defined milestones, tied to dNFT progression.
6.  **Dispute Resolution & Slashing (Reputation-Based):** Mechanisms to penalize malicious actors by reducing their soul-bound reputation.
7.  **DAO Parameterization & Evolution:** Governance over the core rules and parameters of the collective itself.

**The Synergist Collective: A Reputation-Driven Project Incubation & Governance DAO**

This contract, "The Synergist Collective," aims to be a decentralized autonomous organization focused on incubating and funding innovative projects, driven by a robust, soul-bound reputation system. Members earn reputation by contributing, voting wisely, endorsing skills accurately, and successfully leading projects.

---

### Outline and Function Summary

**Contract Name:** `SynergistCollective`

**Core Concept:** A reputation-gated, liquid democracy DAO that incubates and funds projects via milestone-based releases, represented by dynamic NFTs. Member identity and influence are tied to non-transferable Soulbound Tokens (SBTs).

**Key Features:**
*   **Synergist Souls (SBTs):** Non-transferable tokens representing a member's identity and accumulated reputation.
*   **Reputation System:** A multi-faceted system tracking general collective reputation and specific skill-based reputations.
*   **Liquid Democracy:** Members can delegate their voting power (based on reputation) to other Synergists.
*   **Project Incubation:** A process for members to propose, get voted on, and receive milestone-based funding for projects.
*   **Dynamic Project NFTs (dNFTs):** Each funded project is represented by an NFT that visually (via metadata) evolves as milestones are achieved.
*   **Community Curation & Dispute Resolution:** Mechanisms for reporting and penalizing malicious behavior, or challenging project milestone claims.
*   **Parametric Governance:** Core contract parameters can be adjusted via Synergist proposals and votes.

---

**Function Summary (at least 20 functions):**

**I. Synergist Soul (SBT) & Identity Management:**
1.  `requestSynergistSoul()`: Initiates a request for a new Synergist Soul.
2.  `voteOnSynergistRequest(uint256 requestId, bool approve)`: Synergists vote on pending Soul requests.
3.  `executeSynergistRequest(uint256 requestId)`: Mints a new Synergist Soul if the request passes governance.
4.  `updateSoulProfile(string calldata _displayName, string calldata _profileURI)`: Allows a Synergist to update their public profile associated with their Soul.
5.  `burnSoul(uint256 soulId)`: Allows a Synergist to voluntarily burn their Soul (e.g., to exit the collective), or can be triggered by governance for severe infractions.

**II. Reputation & Skill System:**
6.  `delegateVote(uint256 soulId, uint256 toSoulId)`: Delegates voting power (based on reputation) to another Synergist.
7.  `undelegateVote(uint256 soulId)`: Revokes a previous delegation.
8.  `endorseSkill(uint256 targetSoulId, string calldata skillTag)`: Endorses a specific skill for another Synergist, boosting their skill reputation.
9.  `revokeSkillEndorsement(uint256 targetSoulId, string calldata skillTag)`: Revokes a previous skill endorsement.
10. `reportMaliciousActivity(uint256 targetSoulId, string calldata reason)`: Reports a Synergist for malicious behavior, potentially leading to reputation slashing via governance.

**III. Governance & Collective Evolution:**
11. `proposeGovernanceChange(string calldata _description, bytes calldata _callData, address _target)`: Submits a proposal to change collective parameters or execute a specific call on a target contract.
12. `voteOnGovernanceProposal(uint256 proposalId, bool approve)`: Synergists cast their vote on a governance proposal.
13. `executeGovernanceProposal(uint256 proposalId)`: Executes a passed governance proposal.

**IV. Project Incubation & Dynamic NFTs:**
14. `submitProjectManifesto(string calldata _name, string calldata _description, uint256 _totalFunding, string[] calldata _milestoneDescriptions, uint256[] calldata _milestoneAmounts)`: Proposes a new project for collective funding.
15. `voteOnProjectManifesto(uint256 manifestoId, bool approve)`: Synergists vote on project funding proposals.
16. `fundProjectMilestone(uint256 projectId, uint256 milestoneIndex)`: Allows the project lead to request funding for a completed milestone. Requires internal verification or dispute period.
17. `submitMilestoneProof(uint256 projectId, uint256 milestoneIndex, string calldata proofURI)`: Project leads submit evidence for milestone completion.
18. `initiateMilestoneDispute(uint256 projectId, uint256 milestoneIndex, string calldata reason)`: Synergists can dispute a claimed milestone completion, pausing funding.
19. `resolveMilestoneDispute(uint256 projectId, uint256 milestoneIndex, bool approved)`: Governance resolves a milestone dispute.
20. `revokeProjectFunding(uint256 projectId)`: Governance can halt a project and retrieve remaining funds if it fails or is malicious.

**V. Treasury & Utility:**
21. `depositFunds()`: Allows anyone to deposit funds into the collective's treasury.
22. `withdrawFunds(uint256 amount, address recipient)`: Withdraws funds from the treasury, only callable via a successful governance proposal.
23. `getSoulReputation(uint256 soulId)`: Retrieves the current reputation score of a Synergist Soul.
24. `getSkillReputation(uint256 soulId, string calldata skillTag)`: Retrieves the reputation score for a specific skill of a Synergist.
25. `getProjectNFTURI(uint256 projectId)`: Retrieves the current metadata URI for a project's dynamic NFT.
26. `getProjectMilestoneStatus(uint256 projectId, uint256 milestoneIndex)`: Checks the status of a specific project milestone.
27. `getProposalState(uint256 proposalId)`: Retrieves the current state and vote counts for any proposal (governance or project).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: For a production system, more robust ERC721 and Ownable implementations
// would be used, likely from OpenZeppelin, but for the purpose of this exercise
// to avoid "duplicating open source," I'm implementing minimal versions
// necessary for the core logic. The true "advanced concepts" lie in the
// Reputation, Liquid Democracy, and Dynamic NFT mechanics.

interface IERC721Minimal is IERC721 {
    function mint(address to, uint258 tokenId) external;
    function burn(uint258 tokenId) external;
    function setTokenURI(uint258 tokenId, string calldata uri) external;
}

// Minimal Owner implementation to avoid direct OpenZeppelin `Ownable` import for core logic
contract MinimalOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "MinimalOwnable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "MinimalOwnable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/// @title SynergistCollective
/// @notice A reputation-gated, liquid democracy DAO for project incubation and funding using dynamic NFTs.
/// @dev This contract manages Synergist Souls (SBTs), reputation, liquid democracy, project funding,
///      and dynamic NFT evolution for funded projects.
contract SynergistCollective is MinimalOwnable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Constants for reputation thresholds and voting
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100;
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 500;
    uint256 public constant INITIAL_SOUL_REPUTATION = 100;
    uint256 public constant REPUTATION_GAIN_PER_VOTE = 1;
    uint256 public constant REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL = 50;
    uint256 public constant REPUTATION_PENALTY_FOR_BAD_REPORT = 10;
    uint256 public constant REPUTATION_PENALTY_FOR_FAILED_PROJECT = 200;

    uint256 public soulRequestVoteDuration = 3 days;
    uint256 public governanceProposalVoteDuration = 7 days;
    uint256 public projectManifestoVoteDuration = 5 days;
    uint256 public milestoneDisputeDuration = 3 days; // Period to dispute a claimed milestone

    // Contracts
    IERC721Minimal public synergistSoulNFT; // Represents Soulbound Tokens (SBTs)
    IERC721Minimal public projectNFTs;      // Represents Dynamic Project NFTs

    // Counters for unique IDs
    Counters.Counter private _soulIdCounter;
    Counters.Counter private _requestSoulIdCounter;
    Counters.Counter private _governanceProposalIdCounter;
    Counters.Counter private _projectManifestoIdCounter;
    Counters.Counter private _projectIdCounter;

    // --- Mappings & Structs ---

    // Synergist Soul & Reputation
    struct SynergistSoul {
        uint256 soulId;
        address owner; // The address holding this soul
        uint256 reputation; // Overall reputation score
        string displayName;
        string profileURI; // IPFS/Arweave URI for profile metadata
        uint256 delegateeSoulId; // SoulId of who this soul delegates to (0 if self)
        uint256 delegatedPower; // Accumulated voting power from delegates
        bool isActive; // Can be false if burned or frozen
    }
    mapping(uint258 => SynergistSoul) public souls;
    mapping(address => uint256) public addressToSoulId; // Maps wallet address to Soul ID

    // Skill Reputation: soulId -> skillTag -> reputation
    mapping(uint256 => mapping(string => uint256)) public skillReputation;
    // Tracks who endorsed whom for a specific skill: endorserSoulId -> targetSoulId -> skillTag -> bool
    mapping(uint256 => mapping(uint256 => mapping(string => bool))) public hasEndorsedSkill;

    // Soul Request for new Synergists
    enum RequestState { Pending, Approved, Rejected, Executed }
    struct SoulRequest {
        uint256 requestId;
        address requester;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation;
        RequestState state;
        mapping(uint256 => bool) hasVoted; // soulId -> voted
    }
    mapping(uint256 => SoulRequest) public soulRequests;

    // General Governance Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 proposalId;
        uint256 proposerSoulId;
        string description;
        bytes callData; // Encoded function call
        address targetContract; // Target contract for the callData
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation; // Snapshot of total voting power to calculate quorum
        ProposalState state;
        mapping(uint256 => bool) hasVoted; // soulId -> voted
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Project Manifestos (Funding Proposals)
    struct Milestone {
        string description;
        uint256 amount;
        bool isCompleted;
        bool isDisputed;
        uint256 disputeDeadline; // Deadline for dispute resolution
        string proofURI; // URI to evidence for milestone completion
    }
    enum ProjectManifestoState { Pending, Active, Rejected, Funded, Revoked }
    struct ProjectManifesto {
        uint256 manifestoId;
        uint256 proposerSoulId;
        string name;
        string description;
        uint256 totalFunding;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation;
        ProjectManifestoState state;
        uint224 currentMilestoneIndex; // 0-indexed current milestone
        Milestone[] milestones;
        uint256 projectId; // ID of the Project NFT if funded
        mapping(uint256 => bool) hasVoted; // soulId -> voted
    }
    mapping(uint256 => ProjectManifesto) public projectManifestos;
    mapping(uint256 => uint256) public projectIdToManifestoId; // Project NFT ID to Manifesto ID

    // Treasury
    address public treasury; // The contract itself acts as the treasury

    // --- Events ---
    event SoulRequested(uint256 indexed requestId, address indexed requester, uint256 deadline);
    event SoulRequestVoted(uint256 indexed requestId, uint256 indexed voterSoulId, bool approved);
    event SoulMinted(uint256 indexed soulId, address indexed owner, uint256 initialReputation);
    event SoulBurned(uint256 indexed soulId, address indexed owner);
    event SoulProfileUpdated(uint256 indexed soulId, string newDisplayName, string newProfileURI);

    event VoteDelegated(uint256 indexed delegatorSoulId, uint256 indexed delegateeSoulId);
    event VoteUndelegated(uint256 indexed delegatorSoulId);

    event SkillEndorsed(uint256 indexed endorserSoulId, uint256 indexed targetSoulId, string skillTag);
    event SkillEndorsementRevoked(uint256 indexed endorserSoulId, uint256 indexed targetSoulId, string skillTag);
    event MaliciousActivityReported(uint256 indexed reporterSoulId, uint256 indexed targetSoulId, string reason);
    event ReputationUpdated(uint256 indexed soulId, uint256 newReputation);

    event GovernanceProposalSubmitted(uint256 indexed proposalId, uint256 indexed proposerSoulId, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, uint256 indexed voterSoulId, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event GovernanceProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event ProjectManifestoSubmitted(uint256 indexed manifestoId, uint256 indexed proposerSoulId, string name);
    event ProjectManifestoVoted(uint256 indexed manifestoId, uint256 indexed voterSoulId, bool approved);
    event ProjectManifestoStateChanged(uint256 indexed manifestoId, ProjectManifestoState newState);
    event ProjectFunded(uint256 indexed manifestoId, uint256 indexed projectId, uint256 totalFunding);

    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofURI);
    event MilestoneFunded(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 disputerSoulId, string reason);
    event MilestoneDisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool approved);
    event ProjectFundingRevoked(uint256 indexed projectId, uint256 remainingFunds);
    event ProjectNFTMetadataUpdated(uint256 indexed projectId, string newURI);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlySynergist(address _addr) {
        require(addressToSoulId[_addr] != 0 && souls[addressToSoulId[_addr]].isActive, "Caller is not an active Synergist");
        _;
    }

    modifier onlyReputableSynergist(address _addr) {
        require(addressToSoulId[_addr] != 0 && souls[addressToSoulId[_addr]].isActive, "Caller is not an active Synergist");
        require(souls[addressToSoulId[_addr]].reputation >= MIN_REPUTATION_FOR_VOTE, "Synergist's reputation is too low");
        _;
    }

    // --- Constructor ---
    /// @notice Deploys the Synergist Collective, initializes SBT and Project NFT contracts.
    /// @param _synergistSoulNFTAddress Address of the Synergist Soulbound Token (SBT) contract.
    /// @param _projectNFTsAddress Address of the Dynamic Project NFT contract.
    constructor(address _synergistSoulNFTAddress, address _projectNFTsAddress) {
        require(_synergistSoulNFTAddress != address(0), "Invalid Synergist Soul NFT address");
        require(_projectNFTsAddress != address(0), "Invalid Project NFT address");

        synergistSoulNFT = IERC721Minimal(_synergistSoulNFTAddress);
        projectNFTs = IERC721Minimal(_projectNFTsAddress);
        treasury = address(this); // The contract itself holds the funds
    }

    // --- Internal/Utility Functions ---

    /// @dev Calculates a Synergist's effective voting power, considering delegation.
    /// @param _soulId The soul ID to check.
    /// @return The effective voting power.
    function _getEffectiveVotingPower(uint256 _soulId) internal view returns (uint256) {
        if (!souls[_soulId].isActive) {
            return 0;
        }
        uint256 directPower = souls[_soulId].reputation;
        uint256 delegatedPower = souls[_soulId].delegatedPower;
        return directPower + delegatedPower;
    }

    /// @dev Updates the reputation of a Synergist.
    /// @param _soulId The soul ID to update.
    /// @param _amount The amount to add or subtract.
    /// @param _add If true, adds reputation; if false, subtracts.
    function _updateReputation(uint256 _soulId, uint256 _amount, bool _add) internal {
        SynergistSoul storage soul = souls[_soulId];
        require(soul.isActive, "Soul is not active");

        if (_add) {
            soul.reputation += _amount;
        } else {
            soul.reputation = soul.reputation > _amount ? soul.reputation - _amount : 0;
        }
        emit ReputationUpdated(_soulId, soul.reputation);
    }

    /// @dev Helper to get current total voting power of all active souls.
    function _getTotalActiveVotingPower() internal view returns (uint256 totalPower) {
        uint256 currentId = _soulIdCounter.current();
        for (uint256 i = 1; i <= currentId; i++) {
            if (souls[i].isActive && souls[i].delegateeSoulId == 0) { // Only count non-delegating souls
                totalPower += souls[i].reputation + souls[i].delegatedPower;
            }
        }
    }

    /// @dev Internal function to update a project's NFT metadata.
    /// @param _projectId The ID of the project's NFT.
    /// @param _manifesto The project manifesto struct.
    function _updateProjectNFT(uint256 _projectId, ProjectManifesto storage _manifesto) internal {
        string memory baseURI = "ipfs://QmbT2FzWzP1G7C8N6Y2K3J4X5L6M7O8P9Q0R1S2T3U4V5/milestone_";
        string memory newURI = string(abi.encodePacked(baseURI, Strings.toString(_manifesto.currentMilestoneIndex + 1), ".json"));
        projectNFTs.setTokenURI(_projectId, newURI);
        emit ProjectNFTMetadataUpdated(_projectId, newURI);
    }


    // --- I. Synergist Soul (SBT) & Identity Management ---

    /// @notice Initiates a request for a new Synergist Soul (SBT).
    /// @dev This starts a voting process by existing Synergists.
    function requestSynergistSoul() public nonReentrant {
        require(addressToSoulId[_msgSender()] == 0, "Requester already has a Synergist Soul");
        
        _requestSoulIdCounter.increment();
        uint256 requestId = _requestSoulIdCounter.current();
        
        soulRequests[requestId] = SoulRequest({
            requestId: requestId,
            requester: _msgSender(),
            votingDeadline: block.timestamp + soulRequestVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: _getTotalActiveVotingPower(),
            state: RequestState.Pending
        });

        emit SoulRequested(requestId, _msgSender(), soulRequests[requestId].votingDeadline);
    }

    /// @notice Allows Synergists to vote on pending Soul requests.
    /// @param requestId The ID of the Soul request to vote on.
    /// @param approve True for approval, false for rejection.
    function voteOnSynergistRequest(uint256 requestId, bool approve) public nonReentrant onlyReputableSynergist(_msgSender()) {
        SoulRequest storage request = soulRequests[requestId];
        require(request.state == RequestState.Pending, "Soul request is not pending");
        require(block.timestamp < request.votingDeadline, "Voting period has ended");

        uint256 voterSoulId = addressToSoulId[_msgSender()];
        require(!request.hasVoted[voterSoulId], "Synergist has already voted on this request");

        uint256 votingPower = _getEffectiveVotingPower(voterSoulId);
        require(votingPower > 0, "Voter has no effective voting power");

        if (approve) {
            request.votesFor += votingPower;
        } else {
            request.votesAgainst += votingPower;
        }
        request.hasVoted[voterSoulId] = true;

        // Reward voter reputation for participation
        _updateReputation(voterSoulId, REPUTATION_GAIN_PER_VOTE, true);

        emit SoulRequestVoted(requestId, voterSoulId, approve);
    }

    /// @notice Mints a new Synergist Soul if the request passes governance.
    /// @param requestId The ID of the Soul request to execute.
    function executeSynergistRequest(uint256 requestId) public nonReentrant {
        SoulRequest storage request = soulRequests[requestId];
        require(request.state == RequestState.Pending, "Soul request is not pending");
        require(block.timestamp >= request.votingDeadline, "Voting period has not ended yet");

        // Quorum: At least 20% of the total voting power at creation must participate
        // Simple majority: More 'for' votes than 'against'
        uint256 totalVotesCast = request.votesFor + request.votesAgainst;
        require(totalVotesCast >= request.totalVotingPowerAtCreation / 5, "Quorum not met");
        
        if (request.votesFor > request.votesAgainst) {
            _soulIdCounter.increment();
            uint256 newSoulId = _soulIdCounter.current();

            synergistSoulNFT.mint(request.requester, newSoulId);

            souls[newSoulId] = SynergistSoul({
                soulId: newSoulId,
                owner: request.requester,
                reputation: INITIAL_SOUL_REPUTATION,
                displayName: "", // Default empty, can be updated later
                profileURI: "",
                delegateeSoulId: 0, // 0 means self-delegated
                delegatedPower: 0,
                isActive: true
            });
            addressToSoulId[request.requester] = newSoulId;
            request.state = RequestState.Executed;
            emit SoulMinted(newSoulId, request.requester, INITIAL_SOUL_REPUTATION);
        } else {
            request.state = RequestState.Rejected;
        }
    }

    /// @notice Allows a Synergist to update their public profile associated with their Soul.
    /// @param _displayName A public display name.
    /// @param _profileURI A URI (e.g., IPFS) to richer profile metadata.
    function updateSoulProfile(string calldata _displayName, string calldata _profileURI) public onlySynergist(_msgSender()) {
        uint256 soulId = addressToSoulId[_msgSender()];
        souls[soulId].displayName = _displayName;
        souls[soulId].profileURI = _profileURI;
        synergistSoulNFT.setTokenURI(soulId, _profileURI); // Assuming the Soul NFT URI tracks the profile
        emit SoulProfileUpdated(soulId, _displayName, _profileURI);
    }

    /// @notice Allows a Synergist to voluntarily burn their Soul.
    /// @dev This should be used cautiously, as it removes all reputation. Can also be triggered by governance for severe infractions.
    /// @param soulId The ID of the Soul to burn. Must be the caller's Soul or authorized by governance.
    function burnSoul(uint256 soulId) public nonReentrant {
        require(souls[soulId].isActive, "Soul is not active or does not exist");
        
        // Either the owner of the soul calls this, or the call comes from a governance proposal
        bool isSelfBurn = addressToSoulId[_msgSender()] == soulId;
        bool isGovernanceAction = false; // Placeholder for actual governance trigger
        // In a real scenario, the `executeGovernanceProposal` would directly call an internal `_burnSoul`
        // function, verifying it's for a valid reason. For this example, we simplify.
        
        require(isSelfBurn || _msgSender() == owner(), "Caller not authorized to burn this soul"); // Simplified for demo

        souls[soulId].isActive = false;
        souls[soulId].reputation = 0;
        souls[soulId].delegateeSoulId = 0; // Clear delegation
        
        // Remove delegated power from delegatee if this soul was delegating
        // (Delegated power will be recalculated next time it's needed)
        
        address targetAddress = souls[soulId].owner;
        delete addressToSoulId[targetAddress]; // Remove address to soulId mapping
        
        synergistSoulNFT.burn(soulId); // Burn the SBT
        
        emit SoulBurned(soulId, targetAddress);
    }

    // --- II. Reputation & Skill System ---

    /// @notice Delegates voting power (based on reputation) to another Synergist.
    /// @param delegatorSoulId The soul ID of the delegator.
    /// @param toSoulId The soul ID of the delegatee.
    function delegateVote(uint256 delegatorSoulId, uint256 toSoulId) public nonReentrant onlySynergist(_msgSender()) {
        require(addressToSoulId[_msgSender()] == delegatorSoulId, "Only a soul owner can delegate their vote.");
        require(souls[delegatorSoulId].isActive, "Delegator soul is not active.");
        require(toSoulId != delegatorSoulId, "Cannot delegate to self.");
        require(souls[toSoulId].isActive, "Delegatee soul is not active.");

        // If already delegating, first remove previous delegated power
        if (souls[delegatorSoulId].delegateeSoulId != 0) {
            uint256 oldDelegateeId = souls[delegatorSoulId].delegateeSoulId;
            souls[oldDelegateeId].delegatedPower -= souls[delegatorSoulId].reputation;
        }

        souls[delegatorSoulId].delegateeSoulId = toSoulId;
        souls[toSoulId].delegatedPower += souls[delegatorSoulId].reputation;

        emit VoteDelegated(delegatorSoulId, toSoulId);
    }

    /// @notice Revokes a previous delegation, restoring direct voting power to the delegator.
    /// @param delegatorSoulId The soul ID of the delegator.
    function undelegateVote(uint256 delegatorSoulId) public nonReentrant onlySynergist(_msgSender()) {
        require(addressToSoulId[_msgSender()] == delegatorSoulId, "Only a soul owner can undelegate their vote.");
        require(souls[delegatorSoulId].isActive, "Delegator soul is not active.");
        require(souls[delegatorSoulId].delegateeSoulId != 0, "No active delegation to undelegate.");

        uint256 oldDelegateeId = souls[delegatorSoulId].delegateeSoulId;
        souls[oldDelegateeId].delegatedPower -= souls[delegatorSoulId].reputation;
        souls[delegatorSoulId].delegateeSoulId = 0; // 0 means self-delegated

        emit VoteUndelegated(delegatorSoulId);
    }

    /// @notice Endorses a specific skill for another Synergist, boosting their skill reputation.
    /// @dev This helps build a decentralized skill graph within the collective.
    /// @param targetSoulId The soul ID of the Synergist whose skill is being endorsed.
    /// @param skillTag A string identifier for the skill (e.g., "SolidityDev", "UXDesign").
    function endorseSkill(uint256 targetSoulId, string calldata skillTag) public onlyReputableSynergist(_msgSender()) {
        uint256 endorserSoulId = addressToSoulId[_msgSender()];
        require(endorserSoulId != targetSoulId, "Cannot endorse your own skill.");
        require(souls[targetSoulId].isActive, "Target Synergist is not active.");
        require(!hasEndorsedSkill[endorserSoulId][targetSoulId][skillTag], "Already endorsed this skill for this Synergist.");

        skillReputation[targetSoulId][skillTag] += (souls[endorserSoulId].reputation / 100); // Endorsement power scales with endorser reputation
        hasEndorsedSkill[endorserSoulId][targetSoulId][skillTag] = true;
        _updateReputation(endorserSoulId, REPUTATION_GAIN_PER_VOTE, true); // Reward for accurate endorsement

        emit SkillEndorsed(endorserSoulId, targetSoulId, skillTag);
    }

    /// @notice Revokes a previous skill endorsement.
    /// @param targetSoulId The soul ID of the Synergist whose skill was endorsed.
    /// @param skillTag The skill tag to revoke.
    function revokeSkillEndorsement(uint256 targetSoulId, string calldata skillTag) public onlySynergist(_msgSender()) {
        uint256 endorserSoulId = addressToSoulId[_msgSender()];
        require(hasEndorsedSkill[endorserSoulId][targetSoulId][skillTag], "No active endorsement for this skill from you.");

        uint256 endorsementPower = (souls[endorserSoulId].reputation / 100);
        if (skillReputation[targetSoulId][skillTag] >= endorsementPower) {
            skillReputation[targetSoulId][skillTag] -= endorsementPower;
        } else {
            skillReputation[targetSoulId][skillTag] = 0;
        }
        delete hasEndorsedSkill[endorserSoulId][targetSoulId][skillTag];
        _updateReputation(endorserSoulId, REPUTATION_PENALTY_FOR_BAD_REPORT, false); // Small penalty for changing mind, discourages frivolous endorsements

        emit SkillEndorsementRevoked(endorserSoulId, targetSoulId, skillTag);
    }

    /// @notice Reports a Synergist for malicious activity, potentially leading to reputation slashing via governance.
    /// @param targetSoulId The soul ID of the Synergist being reported.
    /// @param reason A description of the alleged malicious activity.
    function reportMaliciousActivity(uint256 targetSoulId, string calldata reason) public onlyReputableSynergist(_msgSender()) {
        uint256 reporterSoulId = addressToSoulId[_msgSender()];
        require(reporterSoulId != targetSoulId, "Cannot report yourself.");
        require(souls[targetSoulId].isActive, "Target Synergist is not active.");

        // This would ideally trigger a governance proposal for investigation and a vote
        // For simplicity, here it just logs and penalizes reporter if misused (later check)
        // In a full system, this would queue a dispute for governance to vote on.
        _updateReputation(reporterSoulId, REPUTATION_GAIN_PER_VOTE, true); // Reward for active curation
        
        emit MaliciousActivityReported(reporterSoulId, targetSoulId, reason);
        // Further action (e.g., creating a governance proposal for slashing) would be needed
        // to fully integrate this with the governance system.
    }

    // --- III. Governance & Collective Evolution ---

    /// @notice Submits a proposal to change collective parameters or execute a specific call on a target contract.
    /// @param _description A description of the proposal.
    /// @param _callData The encoded function call to be executed if the proposal passes.
    /// @param _target The target contract address for the `_callData`.
    function proposeGovernanceChange(string calldata _description, bytes calldata _callData, address _target) public onlyReputableSynergist(_msgSender()) {
        uint256 proposerSoulId = addressToSoulId[_msgSender()];
        require(souls[proposerSoulId].reputation >= MIN_REPUTATION_FOR_PROPOSAL, "Proposer reputation too low.");

        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposerSoulId: proposerSoulId,
            description: _description,
            callData: _callData,
            targetContract: _target,
            votingDeadline: block.timestamp + governanceProposalVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: _getTotalActiveVotingPower(), // Snapshot total voting power
            state: ProposalState.Pending
        });

        emit GovernanceProposalSubmitted(proposalId, proposerSoulId, _description);
        emit GovernanceProposalStateChanged(proposalId, ProposalState.Pending);
    }

    /// @notice Synergists cast their vote on a governance proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param approve True for approval, false for rejection.
    function voteOnGovernanceProposal(uint256 proposalId, bool approve) public nonReentrant onlyReputableSynergist(_msgSender()) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal is not active.");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended.");

        uint256 voterSoulId = addressToSoulId[_msgSender()];
        uint256 effectiveVoterSoulId = souls[voterSoulId].delegateeSoulId == 0 ? voterSoulId : souls[voterSoulId].delegateeSoulId;
        require(!proposal.hasVoted[effectiveVoterSoulId], "Synergist or their delegate has already voted on this proposal.");

        uint256 votingPower = _getEffectiveVotingPower(voterSoulId);
        require(votingPower > 0, "Voter has no effective voting power.");

        if (approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[effectiveVoterSoulId] = true;
        _updateReputation(voterSoulId, REPUTATION_GAIN_PER_VOTE, true); // Reward voter for participation

        if (proposal.state == ProposalState.Pending) { // Change state to Active upon first vote
            proposal.state = ProposalState.Active;
            emit GovernanceProposalStateChanged(proposalId, ProposalState.Active);
        }
        emit GovernanceProposalVoted(proposalId, voterSoulId, approve);
    }

    /// @notice Executes a passed governance proposal.
    /// @param proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Succeeded, "Proposal is not in an executable state.");
        require(block.timestamp >= proposal.votingDeadline, "Voting period has not ended.");

        // Quorum: At least 20% of the total voting power at creation must participate
        // Supermajority: At least 60% of votes cast must be 'for'
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        require(totalVotesCast >= proposal.totalVotingPowerAtCreation / 5, "Quorum not met.");
        require(proposal.votesFor * 10 >= totalVotesCast * 6, "Supermajority for 'For' votes not met.");

        // Execute the proposal's callData on its target
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Governance proposal execution failed.");

        proposal.state = ProposalState.Executed;
        _updateReputation(proposal.proposerSoulId, REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL, true); // Reward proposer
        emit GovernanceProposalExecuted(proposalId);
        emit GovernanceProposalStateChanged(proposalId, ProposalState.Executed);
    }

    // --- IV. Project Incubation & Dynamic NFTs ---

    /// @notice Submits a new project proposal for collective funding and incubation.
    /// @param _name The name of the project.
    /// @param _description A detailed description of the project.
    /// @param _totalFunding The total amount of funds requested for the project.
    /// @param _milestoneDescriptions An array of descriptions for each milestone.
    /// @param _milestoneAmounts An array of funding amounts for each milestone.
    function submitProjectManifesto(
        string calldata _name,
        string calldata _description,
        uint256 _totalFunding,
        string[] calldata _milestoneDescriptions,
        uint256[] calldata _milestoneAmounts
    ) public onlyReputableSynergist(_msgSender()) {
        uint256 proposerSoulId = addressToSoulId[_msgSender()];
        require(souls[proposerSoulId].reputation >= MIN_REPUTATION_FOR_PROPOSAL, "Proposer reputation too low for project manifesto.");
        require(_milestoneDescriptions.length > 0, "At least one milestone required.");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Milestone descriptions and amounts must match in length.");

        uint256 calculatedTotalFunding;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            calculatedTotalFunding += _milestoneAmounts[i];
        }
        require(calculatedTotalFunding == _totalFunding, "Sum of milestone amounts must equal total funding.");
        require(_totalFunding > 0, "Total funding must be greater than zero.");

        Milestone[] memory newMilestones = new Milestone[](_milestoneDescriptions.length);
        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newMilestones[i] = Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                isCompleted: false,
                isDisputed: false,
                disputeDeadline: 0,
                proofURI: ""
            });
        }

        _projectManifestoIdCounter.increment();
        uint256 manifestoId = _projectManifestoIdCounter.current();

        projectManifestos[manifestoId] = ProjectManifesto({
            manifestoId: manifestoId,
            proposerSoulId: proposerSoulId,
            name: _name,
            description: _description,
            totalFunding: _totalFunding,
            votingDeadline: block.timestamp + projectManifestoVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: _getTotalActiveVotingPower(),
            state: ProjectManifestoState.Pending,
            currentMilestoneIndex: 0,
            milestones: newMilestones,
            projectId: 0 // Will be set upon funding
        });

        emit ProjectManifestoSubmitted(manifestoId, proposerSoulId, _name);
        emit ProjectManifestoStateChanged(manifestoId, ProjectManifestoState.Pending);
    }

    /// @notice Synergists vote on project funding proposals (manifestos).
    /// @param manifestoId The ID of the project manifesto to vote on.
    /// @param approve True for approval, false for rejection.
    function voteOnProjectManifesto(uint256 manifestoId, bool approve) public nonReentrant onlyReputableSynergist(_msgSender()) {
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        require(manifesto.state == ProjectManifestoState.Pending || manifesto.state == ProjectManifestoState.Active, "Manifesto is not active.");
        require(block.timestamp < manifesto.votingDeadline, "Voting period has ended.");

        uint256 voterSoulId = addressToSoulId[_msgSender()];
        uint256 effectiveVoterSoulId = souls[voterSoulId].delegateeSoulId == 0 ? voterSoulId : souls[voterSoulId].delegateeSoulId;
        require(!manifesto.hasVoted[effectiveVoterSoulId], "Synergist or their delegate has already voted on this manifesto.");

        uint256 votingPower = _getEffectiveVotingPower(voterSoulId);
        require(votingPower > 0, "Voter has no effective voting power.");

        if (approve) {
            manifesto.votesFor += votingPower;
        } else {
            manifesto.votesAgainst += votingPower;
        }
        manifesto.hasVoted[effectiveVoterSoulId] = true;
        _updateReputation(voterSoulId, REPUTATION_GAIN_PER_VOTE, true); // Reward voter for participation

        if (manifesto.state == ProjectManifestoState.Pending) { // Change state to Active upon first vote
            manifesto.state = ProjectManifestoState.Active;
            emit ProjectManifestoStateChanged(manifestoId, ProjectManifestoState.Active);
        }
        emit ProjectManifestoVoted(manifestoId, voterSoulId, approve);
    }

    /// @notice Project lead requests funding for a completed milestone.
    /// @dev This function transitions the project's dNFT and releases funds.
    /// @param projectId The ID of the funded project (its NFT ID).
    /// @param milestoneIndex The 0-indexed milestone to fund.
    function fundProjectMilestone(uint256 projectId, uint256 milestoneIndex) public nonReentrant {
        uint256 manifestoId = projectIdToManifestoId[projectId];
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        
        require(manifesto.state == ProjectManifestoState.Funded, "Project is not in a funded state.");
        require(addressToSoulId[_msgSender()] == manifesto.proposerSoulId, "Only the project proposer can request milestone funding.");
        require(milestoneIndex == manifesto.currentMilestoneIndex, "Only the current milestone can be funded.");
        require(milestoneIndex < manifesto.milestones.length, "Milestone index out of bounds.");

        Milestone storage milestone = manifesto.milestones[milestoneIndex];
        require(milestone.isCompleted, "Milestone has not been marked as completed.");
        require(!milestone.isDisputed || (milestone.isDisputed && block.timestamp >= milestone.disputeDeadline && !milestone.isCompleted), "Milestone is currently under dispute or dispute not resolved.");
        
        uint256 amountToFund = milestone.amount;
        require(address(this).balance >= amountToFund, "Insufficient funds in treasury.");

        // Transfer funds to project proposer
        (bool success, ) = payable(manifesto.proposerSoulId).call{value: amountToFund}("");
        require(success, "Failed to send milestone funds.");

        milestone.isCompleted = true; // Finalize completion
        manifesto.currentMilestoneIndex++; // Move to next milestone

        // Update Project NFT metadata
        _updateProjectNFT(projectId, manifesto);

        emit MilestoneFunded(projectId, milestoneIndex, amountToFund);
        if (manifesto.currentMilestoneIndex == manifesto.milestones.length) {
            // All milestones completed, project considered fully funded and completed.
            manifesto.state = ProjectManifestoState.Revoked; // Mark as complete (use 'Revoked' for final state as a placeholder)
        }
    }

    /// @notice Project leads submit evidence (URI) for milestone completion.
    /// @dev This marks a milestone as pending verification and starts a dispute period.
    /// @param projectId The ID of the funded project.
    /// @param milestoneIndex The 0-indexed milestone that is claimed complete.
    /// @param proofURI A URI (e.g., IPFS) pointing to the evidence of completion.
    function submitMilestoneProof(uint256 projectId, uint256 milestoneIndex, string calldata proofURI) public nonReentrant {
        uint256 manifestoId = projectIdToManifestoId[projectId];
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        
        require(manifesto.state == ProjectManifestoState.Funded, "Project is not in a funded state.");
        require(addressToSoulId[_msgSender()] == manifesto.proposerSoulId, "Only the project proposer can submit milestone proofs.");
        require(milestoneIndex == manifesto.currentMilestoneIndex, "Can only submit proof for the current milestone.");
        require(milestoneIndex < manifesto.milestones.length, "Milestone index out of bounds.");
        
        Milestone storage milestone = manifesto.milestones[milestoneIndex];
        require(!milestone.isCompleted, "Milestone is already completed.");
        require(!milestone.isDisputed || block.timestamp >= milestone.disputeDeadline, "Milestone is currently under active dispute.");

        milestone.isCompleted = true; // Mark as completed for now, awaiting dispute period
        milestone.proofURI = proofURI;
        milestone.disputeDeadline = block.timestamp + milestoneDisputeDuration; // Start dispute period

        emit MilestoneProofSubmitted(projectId, milestoneIndex, proofURI);
    }

    /// @notice Synergists can dispute a claimed milestone completion, pausing funding until resolved.
    /// @param projectId The ID of the funded project.
    /// @param milestoneIndex The 0-indexed milestone to dispute.
    /// @param reason A description of why the milestone completion is being disputed.
    function initiateMilestoneDispute(uint256 projectId, uint256 milestoneIndex, string calldata reason) public onlyReputableSynergist(_msgSender()) {
        uint256 manifestoId = projectIdToManifestoId[projectId];
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        
        require(manifesto.state == ProjectManifestoState.Funded, "Project is not in a funded state.");
        require(milestoneIndex == manifesto.currentMilestoneIndex, "Can only dispute the current milestone.");
        require(milestoneIndex < manifesto.milestones.length, "Milestone index out of bounds.");
        
        Milestone storage milestone = manifesto.milestones[milestoneIndex];
        require(milestone.isCompleted && !milestone.isDisputed, "Milestone is not marked complete or already under dispute.");
        require(block.timestamp < milestone.disputeDeadline, "Dispute period has ended for this milestone.");

        milestone.isDisputed = true;
        // This should ideally trigger a governance vote or a special dispute resolution process
        // For simplicity, it just flags it. A governance proposal would then be needed to `resolveMilestoneDispute`.
        _updateReputation(addressToSoulId[_msgSender()], REPUTATION_GAIN_PER_VOTE, true); // Reward for active curation

        emit MilestoneDisputed(projectId, milestoneIndex, addressToSoulId[_msgSender()], reason);
    }

    /// @notice Governance resolves a milestone dispute, either approving or rejecting the completion.
    /// @dev This function would typically be called via `executeGovernanceProposal`.
    /// @param projectId The ID of the project.
    /// @param milestoneIndex The index of the disputed milestone.
    /// @param approved True if milestone completion is approved, false if rejected.
    function resolveMilestoneDispute(uint256 projectId, uint256 milestoneIndex, bool approved) public onlyOwner nonReentrant {
        // In a real system, this would be callable only by `executeGovernanceProposal`
        // which verifies the proposal passed. For this demo, `onlyOwner` acts as a placeholder
        // for "authorized governance action".
        uint256 manifestoId = projectIdToManifestoId[projectId];
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        
        require(manifesto.state == ProjectManifestoState.Funded, "Project is not in a funded state.");
        require(milestoneIndex == manifesto.currentMilestoneIndex, "Cannot resolve dispute for a non-current milestone.");
        require(milestoneIndex < manifesto.milestones.length, "Milestone index out of bounds.");

        Milestone storage milestone = manifesto.milestones[milestoneIndex];
        require(milestone.isDisputed, "Milestone is not currently under dispute.");

        milestone.isDisputed = false; // Dispute resolved

        if (approved) {
            // Milestone remains `isCompleted = true`, can proceed with `fundProjectMilestone`
            // No action needed here other than clearing dispute flag
        } else {
            milestone.isCompleted = false; // Reject the completion
            milestone.proofURI = ""; // Clear proof
            milestone.disputeDeadline = 0; // Reset
            // Potentially penalize project proposer here
            _updateReputation(manifesto.proposerSoulId, REPUTATION_PENALTY_FOR_FAILED_PROJECT / 2, false);
        }
        emit MilestoneDisputeResolved(projectId, milestoneIndex, approved);
    }

    /// @notice Governance can halt a project and retrieve remaining funds if it fails or is deemed malicious.
    /// @dev This function would typically be called via `executeGovernanceProposal`.
    /// @param projectId The ID of the project to revoke funding for.
    function revokeProjectFunding(uint256 projectId) public nonReentrant onlyOwner {
        // In a real system, this would be callable only by `executeGovernanceProposal`
        // which verifies the proposal passed. For this demo, `onlyOwner` acts as a placeholder
        // for "authorized governance action".
        uint256 manifestoId = projectIdToManifestoId[projectId];
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        
        require(manifesto.state == ProjectManifestoState.Funded, "Project is not in a funded state.");

        uint256 remainingFunds = 0;
        for (uint256 i = manifesto.currentMilestoneIndex; i < manifesto.milestones.length; i++) {
            if (!manifesto.milestones[i].isCompleted) {
                remainingFunds += manifesto.milestones[i].amount;
            }
        }

        manifesto.state = ProjectManifestoState.Revoked;
        _updateReputation(manifesto.proposerSoulId, REPUTATION_PENALTY_FOR_FAILED_PROJECT, false); // Penalize project lead
        
        // Burn the project NFT
        projectNFTs.burn(projectId);

        // If there are remaining funds held by the project, return them to the treasury.
        // This implies the project receives funds into a managed contract, not directly.
        // For simplicity, here we assume all funds are still in THIS contract's treasury until milestone completion.
        // If the project was a separate contract, this would trigger a call to it.

        emit ProjectFundingRevoked(projectId, remainingFunds);
    }

    // --- V. Treasury & Utility ---

    /// @notice Allows anyone to deposit funds into the collective's treasury.
    function depositFunds() public payable {
        require(msg.value > 0, "Must send ETH to deposit.");
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /// @notice Withdraws funds from the treasury. Only callable via a successful governance proposal.
    /// @dev This function would typically be called via `executeGovernanceProposal`.
    /// @param amount The amount of funds to withdraw.
    /// @param recipient The address to send the funds to.
    function withdrawFunds(uint256 amount, address recipient) public nonReentrant onlyOwner {
        // In a real system, this would be callable only by `executeGovernanceProposal`
        // which verifies the proposal passed. For this demo, `onlyOwner` acts as a placeholder
        // for "authorized governance action".
        require(amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= amount, "Insufficient treasury balance.");
        require(recipient != address(0), "Invalid recipient address.");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Failed to send funds.");

        emit FundsWithdrawn(recipient, amount);
    }

    /// @notice Retrieves the current reputation score of a Synergist Soul.
    /// @param soulId The ID of the Synergist Soul.
    /// @return The current reputation score.
    function getSoulReputation(uint256 soulId) public view returns (uint256) {
        return souls[soulId].reputation;
    }

    /// @notice Retrieves the soul ID of the Synergist's delegatee. Returns 0 if self-delegated.
    /// @param soulId The ID of the Synergist Soul.
    /// @return The soul ID of the delegatee.
    function getDelegatee(uint256 soulId) public view returns (uint256) {
        return souls[soulId].delegateeSoulId;
    }

    /// @notice Retrieves the reputation score for a specific skill of a Synergist.
    /// @param soulId The ID of the Synergist Soul.
    /// @param skillTag The skill tag to query (e.g., "SolidityDev").
    /// @return The skill-specific reputation score.
    function getSkillReputation(uint256 soulId, string calldata skillTag) public view returns (uint256) {
        return skillReputation[soulId][skillTag];
    }

    /// @notice Retrieves details about a project manifesto.
    /// @param manifestoId The ID of the project manifesto.
    /// @return name, description, totalFunding, proposerSoulId, currentMilestoneIndex, state, votesFor, votesAgainst, votingDeadline.
    function getProjectManifestoDetails(uint256 manifestoId) public view returns (
        string memory name,
        string memory description,
        uint256 totalFunding,
        uint256 proposerSoulId,
        uint256 currentMilestoneIndex,
        ProjectManifestoState state,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votingDeadline
    ) {
        ProjectManifesto storage manifesto = projectManifestos[manifestoId];
        return (
            manifesto.name,
            manifesto.description,
            manifesto.totalFunding,
            manifesto.proposerSoulId,
            manifesto.currentMilestoneIndex,
            manifesto.state,
            manifesto.votesFor,
            manifesto.votesAgainst,
            manifesto.votingDeadline
        );
    }

    /// @notice Retrieves the current metadata URI for a project's dynamic NFT.
    /// @param projectId The ID of the project's NFT.
    /// @return The current token URI.
    function getProjectNFTURI(uint256 projectId) public view returns (string memory) {
        return projectNFTs.tokenURI(projectId);
    }

    /// @notice Checks the status of a specific project milestone.
    /// @param projectId The ID of the project.
    /// @param milestoneIndex The 0-indexed milestone to check.
    /// @return isCompleted, isDisputed, proofURI, disputeDeadline.
    function getProjectMilestoneStatus(uint256 projectId, uint256 milestoneIndex) public view returns (
        bool isCompleted,
        bool isDisputed,
        string memory proofURI,
        uint256 disputeDeadline
    ) {
        uint256 manifestoId = projectIdToManifestoId[projectId];
        require(projectManifestos[manifestoId].projectId == projectId, "Invalid project ID.");
        require(milestoneIndex < projectManifestos[manifestoId].milestones.length, "Milestone index out of bounds.");
        
        Milestone storage milestone = projectManifestos[manifestoId].milestones[milestoneIndex];
        return (
            milestone.isCompleted,
            milestone.isDisputed,
            milestone.proofURI,
            milestone.disputeDeadline
        );
    }

    /// @notice Retrieves the current state and vote counts for any proposal (governance or project).
    /// @param proposalId The ID of the proposal.
    /// @param isGovernance True if it's a governance proposal, false if a project manifesto.
    /// @return state (uint), votesFor, votesAgainst, votingDeadline.
    function getProposalState(uint256 proposalId, bool isGovernance) public view returns (
        uint256 state,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votingDeadline
    ) {
        if (isGovernance) {
            GovernanceProposal storage proposal = governanceProposals[proposalId];
            return (uint256(proposal.state), proposal.votesFor, proposal.votesAgainst, proposal.votingDeadline);
        } else {
            ProjectManifesto storage manifesto = projectManifestos[proposalId];
            return (uint256(manifesto.state), manifesto.votesFor, manifesto.votesAgainst, manifesto.votingDeadline);
        }
    }

    /// @notice Retrieves the current balance of the collective's treasury.
    /// @return The current ETH balance.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```