```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ____ _                 _                       ______                 __
/ ___| |__   ___  _ __ | |_ ___  _ __ ___     / ____/___  ____ ______/ /_
| |   | '_ \ / _ \| '_ \| __/ _ \| '__/ __|   / /   / __ \/ __ `/ ___/ __ \
| |___| | | | (_) | | | | || (_) | |  \__ \  / /___/ /_/ / /_/ (__  ) / / /
 \____|_| |_|\___/|_| |_|\__\___/|_|  |___/  \____/\____/\__,_/____/_/ /_/

*/

/**
 * @title ChronoForge Protocol - Decentralized Innovation Epochs
 * @dev This contract orchestrates a decentralized research and development ecosystem.
 *      It enables the creation of innovation "Epochs," where innovators propose projects,
 *      receive milestone-based funding, and manage intellectual property (IP) through
 *      Dynamic Innovation NFTs (dINFTs). The protocol incorporates a reputation system,
 *      decentralized governance for funding decisions, and a dispute resolution mechanism.
 *      It aims to be unique by combining dynamic NFTs, simulated ZK-proof validation flows,
 *      on-chain IP management, and a multi-stakeholder governance model for R&D.
 *
 * @notice Placeholder for off-chain proofs/data: Throughout the contract, `_hash` or `_proofHash`
 *         parameters are used. In a real-world scenario, these would typically refer to
 *         IPFS/Arweave content hashes, verifiable computation proofs (e.g., ZK-SNARKs),
 *         or external oracle data, which would be validated off-chain or by a trusted oracle
 *         network before being recorded on-chain. This contract focuses on the on-chain logic.
 */

// --- Outline ---
// I. State Variables & Constants
// II. Struct Definitions
// III. Events
// IV. Modifiers (Access Control)
// V. Core Epoch Management Functions (6 functions)
// VI. Dynamic Innovation NFT (dINFT) & Project Lifecycle Functions (8 functions)
// VII. Reputation & Governance Functions (4 functions)
// VIII. Dispute Resolution & Treasury Functions (4 functions)

// --- Function Summary (22 Functions) ---

// I. Constructor
// 1.  constructor(): Initializes the contract with the deployer as admin and sets initial roles.

// II. Core Epoch Management Functions
// 2.  createEpoch(uint256 _duration, string memory _goalHash, uint256 _minFunding, uint256 _maxFunding):
//     Initiates a new research epoch with defined parameters.
// 3.  submitInnovationProposal(uint256 _epochId, string memory _title, string memory _descriptionHash, uint256 _requestedGrant, uint256[] memory _milestonePercentages):
//     Allows an Innovator to submit a project proposal for a specific epoch.
// 4.  fundEpoch(uint256 _epochId):
//     Enables Patrons to contribute ETH to a specific epoch's funding pool.
// 5.  voteOnProposal(uint256 _proposalId, bool _approve):
//     Patrons cast votes on pending innovation proposals.
// 6.  finalizeEpochProposals(uint256 _epochId):
//     Admin/DAO finalizes the winning proposals for an epoch based on votes and funding.
// 7.  transitionEpochPhase(uint256 _epochId):
//     Advances the phase of an epoch (e.g., from Funding to Active, Active to Concluded).

// III. Dynamic Innovation NFT (dINFT) & Project Lifecycle Functions
// 8.  mintDINFTForProposal(uint256 _proposalId):
//     (Internal/Admin) Mints a Dynamic Innovation NFT for a successfully funded proposal.
// 9.  submitMilestoneProof(uint256 _dINFTId, uint256 _milestoneIndex, string memory _proofHash):
//     Innovator submits proof of completion for a specific milestone.
// 10. requestMilestoneValidation(uint256 _dINFTId, uint256 _milestoneIndex):
//     Innovator requests a validator to review their submitted milestone proof.
// 11. validateMilestoneProof(uint256 _dINFTId, uint256 _milestoneIndex, bool _isValid, string memory _validatorRemarksHash):
//     Designated Validator reviews and approves/rejects a milestone proof.
// 12. claimMilestoneGrant(uint256 _dINFTId, uint256 _milestoneIndex):
//     Innovator claims the grant portion for a successfully validated milestone.
// 13. updateDINFTMetadata(uint256 _dINFTId):
//     (Internal) Updates the on-chain metadata (e.g., URI) of a dINFT based on milestone progress.
// 14. transferDINFTPartialOwnership(uint256 _dINFTId, address _recipient, uint256 _percentage):
//     Allows a dINFT owner to transfer a percentage of their future royalty/ownership share.
// 15. registerIPRoyaltySplit(uint256 _dINFTId, address _payee, uint256 _percentage):
//     Establishes an on-chain royalty split for potential commercialization of the dINFT's IP.

// IV. Reputation & Governance Functions
// 16. getInnovatorReputation(address _innovator):
//     Retrieves the current reputation score of an innovator.
// 17. getValidatorReputation(address _validator):
//     Retrieves the current reputation score of a validator.
// 18. delegateVotingPower(address _delegatee):
//     Allows a Patron to delegate their voting power to another address.
// 19. submitGovernanceProposal(string memory _proposalHash):
//     Allows a privileged role (e.g., high-reputation patron/innovator) to submit a protocol-level governance proposal.

// V. Dispute Resolution & Treasury Functions
// 20. initiateDisputeOnMilestone(uint256 _dINFTId, uint256 _milestoneIndex, string memory _reasonHash):
//     Initiates a formal dispute regarding a milestone validation or non-validation.
// 21. resolveDispute(uint256 _disputeId, bool _favorInnovator, string memory _resolutionHash):
//     Arbitrators resolve an open dispute, affecting milestone status and reputations.
// 22. collectRoyaltiesForDINFT(uint256 _dINFTId):
//     Allows registered IP payees to collect accumulated royalties for a dINFT.
// 23. withdrawTreasuryFunds(address _recipient, uint256 _amount):
//     Allows the Admin (or DAO via governance) to withdraw funds from the main protocol treasury.


contract ChronoForgeProtocol {

    // --- I. State Variables & Constants ---

    address public admin; // Protocol administrator
    uint256 public nextEpochId;
    uint256 public nextProposalId;
    uint256 public nextDINFTId;
    uint256 public nextDisputeId;

    // Reputation thresholds for special privileges (e.g., governance proposals)
    uint256 public constant MIN_GOV_PROPOSAL_REPUTATION = 1000; // Example value

    // Enum for Epoch phases
    enum EpochPhase { Creation, Funding, Active, Concluded }

    // Enum for Proposal status
    enum ProposalStatus { Pending, Approved, Rejected, Funded }

    // Enum for Milestone status
    enum MilestoneStatus { Pending, Submitted, Validated, Rejected, Disputed }

    // --- II. Struct Definitions ---

    struct Epoch {
        uint256 id;
        uint256 duration; // in seconds
        string goalHash; // Hash of the epoch's overall goal/manifesto
        uint256 minFunding; // Minimum funding required to activate epoch
        uint256 maxFunding; // Maximum funding cap for the epoch
        uint256 currentFunding; // Current accumulated funding
        EpochPhase phase;
        uint256 startTime;
        uint256 endTime;
        uint256[] proposalIds; // List of proposals submitted for this epoch
        mapping(address => uint256) patronVotes; // Voting power for patrons
        mapping(uint258 => uint256) proposalFundingAmount; // Amount awarded to each proposal
    }

    struct InnovationProposal {
        uint256 id;
        uint256 epochId;
        address innovator;
        string title;
        string descriptionHash; // Hash of proposal details (e.g., IPFS CID)
        uint256 requestedGrant; // Total grant requested in wei
        uint256 currentVotesFor;
        uint256 currentVotesAgainst;
        ProposalStatus status;
        uint256 dINFTId; // 0 if no dINFT minted yet
        uint256[] milestonePercentages; // Percentages of total grant for each milestone
    }

    struct Milestone {
        uint256 index;
        uint256 percentage; // % of total grant
        MilestoneStatus status;
        string proofHash; // Hash of the submitted proof
        address validator; // Address of the validator who approved/rejected
        string validatorRemarksHash; // Hash of validator's remarks
        uint256 grantAmount; // Actual wei amount for this milestone
    }

    struct DINFTData {
        uint256 id;
        uint256 proposalId;
        address innovator;
        string uri; // Base URI for the dINFT metadata, evolving dynamically
        uint256 currentMilestone; // Index of the next milestone to be worked on
        uint256 completedMilestones;
        Milestone[] milestones;
        mapping(address => uint256) royaltySplits; // Address => percentage of royalties (basis points)
        uint256 accumulatedRoyalties; // Total royalties collected, ready for distribution
    }

    struct Reputation {
        uint256 innovatorScore;
        uint256 validatorScore;
    }

    struct Dispute {
        uint256 id;
        uint256 dINFTId;
        uint256 milestoneIndex;
        address initiator;
        string reasonHash; // Hash of the dispute reason
        bool resolved;
        bool favorInnovator; // True if dispute resolved in favor of innovator
        string resolutionHash; // Hash of the arbitrator's resolution
        address arbitrator;
    }

    // Mappings for main data structures
    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => InnovationProposal) public proposals;
    mapping(uint256 => DINFTData) public dINFTs;
    mapping(address => Reputation) public reputationScores;
    mapping(uint256 => Dispute) public disputes;

    // Addresses for various roles (simple access control)
    address public arbiterCouncilAddress; // Centralized for example, could be a multi-sig or DAO
    mapping(address => bool) public isValidator; // Whitelist of addresses allowed to validate

    // --- III. Events ---

    event EpochCreated(uint256 indexed epochId, address indexed creator, uint256 duration, uint256 minFunding, uint256 maxFunding);
    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed epochId, address indexed innovator, uint256 requestedGrant);
    event EpochFunded(uint256 indexed epochId, address indexed funder, uint255 amount, uint256 totalFunding);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event EpochProposalsFinalized(uint256 indexed epochId, uint256[] fundedProposalIds);
    event EpochPhaseTransitioned(uint256 indexed epochId, EpochPhase newPhase);

    event DINFTMinted(uint256 indexed dINFTId, uint256 indexed proposalId, address indexed innovator, string uri);
    event MilestoneProofSubmitted(uint256 indexed dINFTId, uint256 indexed milestoneIndex, string proofHash);
    event MilestoneValidationRequested(uint256 indexed dINFTId, uint256 indexed milestoneIndex, address indexed innovator);
    event MilestoneValidated(uint256 indexed dINFTId, uint256 indexed milestoneIndex, bool isValid, address indexed validator);
    event MilestoneGrantClaimed(uint256 indexed dINFTId, uint256 indexed milestoneIndex, address indexed innovator, uint256 amount);
    event DINFTMetadataUpdated(uint256 indexed dINFTId, string newURI);
    event DINFTPartialOwnershipTransferred(uint256 indexed dINFTId, address indexed from, address indexed to, uint256 percentage);
    event IPRoyaltySplitRegistered(uint256 indexed dINFTId, address indexed payee, uint256 percentage);
    event RoyaltiesCollected(uint256 indexed dINFTId, address indexed collector, uint256 amount);

    event ReputationUpdated(address indexed user, uint256 innovatorScore, uint256 validatorScore);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event GovernanceProposalSubmitted(uint256 proposalId, string proposalHash, address indexed proposer);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed dINFTId, uint256 indexed milestoneIndex, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, bool favorInnovator, address indexed arbitrator);

    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- IV. Modifiers (Access Control) ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "ChronoForge: Only admin can call this function.");
        _;
    }

    modifier onlyInnovator(uint256 _dINFTId) {
        require(dINFTs[_dINFTId].innovator == msg.sender, "ChronoForge: Only the dINFT innovator can call this function.");
        _;
    }

    modifier onlyValidatorAllowed() {
        require(isValidator[msg.sender], "ChronoForge: Only designated validators can call this function.");
        _;
    }

    modifier onlyArbiterCouncil() {
        require(msg.sender == arbiterCouncilAddress, "ChronoForge: Only the arbiter council can call this function.");
        _;
    }

    // Role management functions (can be expanded into a proper RBAC system)
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "ChronoForge: New admin cannot be zero address.");
        admin = _newAdmin;
    }

    function setArbiterCouncilAddress(address _newArbiterCouncil) public onlyAdmin {
        require(_newArbiterCouncil != address(0), "ChronoForge: New arbiter council cannot be zero address.");
        arbiterCouncilAddress = _newArbiterCouncil;
    }

    function addValidator(address _validator) public onlyAdmin {
        require(_validator != address(0), "ChronoForge: Validator address cannot be zero.");
        isValidator[_validator] = true;
    }

    function removeValidator(address _validator) public onlyAdmin {
        isValidator[_validator] = false;
    }

    // --- I. Constructor ---
    constructor() {
        admin = msg.sender;
        arbiterCouncilAddress = msg.sender; // Set deployer as initial arbiter council
        nextEpochId = 1;
        nextProposalId = 1;
        nextDINFTId = 1;
        nextDisputeId = 1;
    }

    // --- V. Core Epoch Management Functions ---

    /**
     * @dev Creates a new research epoch. Only callable by admin.
     * @param _duration Duration of the epoch in seconds.
     * @param _goalHash IPFS/Arweave hash of the epoch's goal document.
     * @param _minFunding Minimum ETH required to activate this epoch.
     * @param _maxFunding Maximum ETH this epoch can accept.
     */
    function createEpoch(uint256 _duration, string memory _goalHash, uint256 _minFunding, uint256 _maxFunding)
        public
        onlyAdmin
    {
        require(_duration > 0, "ChronoForge: Epoch duration must be positive.");
        require(_minFunding > 0, "ChronoForge: Minimum funding must be positive.");
        require(_maxFunding >= _minFunding, "ChronoForge: Max funding must be >= min funding.");

        epochs[nextEpochId] = Epoch({
            id: nextEpochId,
            duration: _duration,
            goalHash: _goalHash,
            minFunding: _minFunding,
            maxFunding: _maxFunding,
            currentFunding: 0,
            phase: EpochPhase.Creation, // Starts in Creation phase
            startTime: 0, // Set when transitioning to Active
            endTime: 0,   // Set when transitioning to Active
            proposalIds: new uint256[](0)
        });

        emit EpochCreated(nextEpochId, msg.sender, _duration, _minFunding, _maxFunding);
        nextEpochId++;
    }

    /**
     * @dev Allows an innovator to submit a detailed research proposal for an epoch.
     * @param _epochId The ID of the epoch to submit to.
     * @param _title Title of the proposal.
     * @param _descriptionHash IPFS/Arweave hash of the detailed proposal document.
     * @param _requestedGrant Total ETH grant requested for the project.
     * @param _milestonePercentages Array of percentages (out of 10000 for basis points) for each milestone.
     */
    function submitInnovationProposal(uint256 _epochId, string memory _title, string memory _descriptionHash, uint256 _requestedGrant, uint256[] memory _milestonePercentages)
        public
    {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.id != 0, "ChronoForge: Epoch does not exist.");
        require(epoch.phase == EpochPhase.Creation || epoch.phase == EpochPhase.Funding, "ChronoForge: Proposals can only be submitted during Creation or Funding phase.");
        require(_requestedGrant > 0, "ChronoForge: Requested grant must be positive.");
        require(_milestonePercentages.length > 0, "ChronoForge: Must define at least one milestone.");

        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _milestonePercentages.length; i++) {
            totalPercentage += _milestonePercentages[i];
        }
        require(totalPercentage == 10000, "ChronoForge: Milestone percentages must sum to 100%. (10000 basis points)");

        Milestone[] memory newMilestones = new Milestone[](_milestonePercentages.length);
        for (uint256 i = 0; i < _milestonePercentages.length; i++) {
            newMilestones[i] = Milestone({
                index: i,
                percentage: _milestonePercentages[i],
                status: MilestoneStatus.Pending,
                proofHash: "",
                validator: address(0),
                validatorRemarksHash: "",
                grantAmount: (_requestedGrant * _milestonePercentages[i]) / 10000
            });
        }

        proposals[nextProposalId] = InnovationProposal({
            id: nextProposalId,
            epochId: _epochId,
            innovator: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            requestedGrant: _requestedGrant,
            currentVotesFor: 0,
            currentVotesAgainst: 0,
            status: ProposalStatus.Pending,
            dINFTId: 0 // Will be set upon funding
        });

        epoch.proposalIds.push(nextProposalId);

        emit ProposalSubmitted(nextProposalId, _epochId, msg.sender, _requestedGrant);
        nextProposalId++;
    }

    /**
     * @dev Allows patrons to contribute ETH to an epoch's funding pool.
     * @param _epochId The ID of the epoch to fund.
     */
    function fundEpoch(uint256 _epochId) public payable {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.id != 0, "ChronoForge: Epoch does not exist.");
        require(epoch.phase == EpochPhase.Funding || epoch.phase == EpochPhase.Creation, "ChronoForge: Epoch is not in funding phase.");
        require(msg.value > 0, "ChronoForge: Must send positive ETH.");
        require(epoch.currentFunding + msg.value <= epoch.maxFunding, "ChronoForge: Funding exceeds epoch maximum.");

        if (epoch.phase == EpochPhase.Creation) {
            epoch.phase = EpochPhase.Funding; // Automatically transitions to funding when first funded
            emit EpochPhaseTransitioned(_epochId, EpochPhase.Funding);
        }

        epoch.currentFunding += msg.value;
        // This simple voting mechanism implies 1 ETH = 1 vote. Can be extended to an ERC20 voting token.
        epoch.patronVotes[msg.sender] += msg.value;

        emit EpochFunded(_epochId, msg.sender, msg.value, epoch.currentFunding);
    }

    /**
     * @dev Allows a patron to vote on a specific innovation proposal.
     *      Voting power is determined by the amount funded in the epoch.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public {
        InnovationProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChronoForge: Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "ChronoForge: Proposal is not in pending status.");

        Epoch storage epoch = epochs[proposal.epochId];
        require(epoch.id != 0, "ChronoForge: Epoch does not exist for this proposal.");
        require(epoch.phase == EpochPhase.Funding, "ChronoForge: Voting is only allowed during the funding phase.");

        uint256 votingPower = epoch.patronVotes[msg.sender];
        require(votingPower > 0, "ChronoForge: You must fund the epoch to vote.");

        // Simple voting: each address can vote once per proposal.
        // For more advanced voting, track votes per address for each proposal.
        // For now, let's assume votes are cumulative by fund amount.
        // To prevent double voting on same proposal, store (address, proposalId) in a mapping.
        // Example simple "already voted" check (can be expanded):
        // require(epoch.hasVoted[msg.sender][_proposalId] == false, "ChronoForge: Already voted on this proposal.");
        // epoch.hasVoted[msg.sender][_proposalId] = true;

        if (_approve) {
            proposal.currentVotesFor += votingPower;
        } else {
            proposal.currentVotesAgainst += votingPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin or a DAO function to finalize which proposals get funded for an epoch.
     *      This function distributes the available funds to approved proposals.
     * @param _epochId The ID of the epoch to finalize.
     */
    function finalizeEpochProposals(uint256 _epochId) public onlyAdmin { // Can be changed to DAO governance later
        Epoch storage epoch = epochs[_epochId];
        require(epoch.id != 0, "ChronoForge: Epoch does not exist.");
        require(epoch.phase == EpochPhase.Funding, "ChronoForge: Epoch is not in funding phase.");
        require(epoch.currentFunding >= epoch.minFunding, "ChronoForge: Epoch not sufficiently funded.");

        uint256 totalFundedAmount = 0;
        uint256[] memory fundedProposalIds = new uint256[](0);

        // Sort proposals by votes (descending) - complex on-chain. For simplicity, iterate and fund top voted.
        // Or, define a threshold: (votesFor / totalVotes) > 0.51
        // For demonstration, let's fund proposals that have more 'for' votes than 'against' votes,
        // up to the epoch's current funding limit.
        for (uint256 i = 0; i < epoch.proposalIds.length; i++) {
            uint256 proposalId = epoch.proposalIds[i];
            InnovationProposal storage proposal = proposals[proposalId];

            if (proposal.status == ProposalStatus.Pending && proposal.currentVotesFor > proposal.currentVotesAgainst) {
                if (totalFundedAmount + proposal.requestedGrant <= epoch.currentFunding) {
                    proposal.status = ProposalStatus.Approved;
                    totalFundedAmount += proposal.requestedGrant;
                    fundedProposalIds = _addToArray(fundedProposalIds, proposalId);
                    // Mint dINFT immediately upon approval
                    _mintDINFTForProposal(proposalId);
                } else {
                    proposal.status = ProposalStatus.Rejected; // Not enough funds, or over budget.
                }
            } else if (proposal.status == ProposalStatus.Pending) {
                proposal.status = ProposalStatus.Rejected; // Did not pass vote
            }
        }

        // Store how much each proposal received.
        // This could be made more sophisticated, e.g., prorated funding if total requested exceeds total available.
        // For now, it's either fully funded or not.
        for(uint256 i = 0; i < fundedProposalIds.length; i++) {
            proposals[fundedProposalIds[i]].status = ProposalStatus.Funded;
            epoch.proposalFundingAmount[fundedProposalIds[i]] = proposals[fundedProposalIds[i]].requestedGrant;
        }

        epoch.phase = EpochPhase.Active;
        epoch.startTime = block.timestamp;
        epoch.endTime = block.timestamp + epoch.duration; // Epoch becomes active for its duration

        emit EpochProposalsFinalized(_epochId, fundedProposalIds);
        emit EpochPhaseTransitioned(_epochId, EpochPhase.Active);
    }

    /**
     * @dev Allows the admin to manually transition an epoch's phase.
     *      This can be used for force-starting/concluding if conditions are met or in emergencies.
     * @param _epochId The ID of the epoch to transition.
     */
    function transitionEpochPhase(uint256 _epochId) public onlyAdmin {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.id != 0, "ChronoForge: Epoch does not exist.");

        if (epoch.phase == EpochPhase.Creation && epoch.currentFunding > 0) {
            epoch.phase = EpochPhase.Funding;
        } else if (epoch.phase == EpochPhase.Funding && epoch.currentFunding >= epoch.minFunding && block.timestamp >= epoch.startTime + epoch.duration) {
            // If funding period is over and min funding met, it should have been finalized already.
            // This case handles explicit transition if `finalizeEpochProposals` wasn't called.
            // A more robust system would automate the finalize call or have a governance proposal.
            // For now, this assumes admin explicitly calls finalize, then transitions.
            revert("ChronoForge: Epoch funding phase requires finalization before transition.");
        } else if (epoch.phase == EpochPhase.Active && block.timestamp >= epoch.endTime) {
            epoch.phase = EpochPhase.Concluded;
        } else {
            revert("ChronoForge: Cannot transition epoch phase.");
        }
        emit EpochPhaseTransitioned(_epochId, epoch.phase);
    }

    // --- VI. Dynamic Innovation NFT (dINFT) & Project Lifecycle Functions ---

    /**
     * @dev Internal function to mint a dINFT for a successfully funded proposal.
     *      This effectively represents the project's on-chain presence and IP.
     * @param _proposalId The ID of the funded proposal.
     */
    function _mintDINFTForProposal(uint256 _proposalId) internal {
        InnovationProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Funded, "ChronoForge: Proposal not approved or funded.");
        require(proposal.dINFTId == 0, "ChronoForge: dINFT already minted for this proposal.");

        // Initialize milestones for the dINFT based on proposal
        Milestone[] memory dINFTMilestones = new Milestone[](proposal.milestonePercentages.length);
        for (uint256 i = 0; i < proposal.milestonePercentages.length; i++) {
            dINFTMilestones[i] = Milestone({
                index: i,
                percentage: proposal.milestonePercentages[i],
                status: MilestoneStatus.Pending,
                proofHash: "",
                validator: address(0),
                validatorRemarksHash: "",
                grantAmount: (proposal.requestedGrant * proposal.milestonePercentages[i]) / 10000 // Calculate actual grant per milestone
            });
        }

        dINFTs[nextDINFTId] = DINFTData({
            id: nextDINFTId,
            proposalId: _proposalId,
            innovator: proposal.innovator,
            uri: string(abi.encodePacked("ipfs://initial-dinft-metadata/", Strings.toString(nextDINFTId))), // Base URI (can be updated)
            currentMilestone: 0, // Starts at milestone 0
            completedMilestones: 0,
            milestones: dINFTMilestones,
            accumulatedRoyalties: 0
        });

        // Link dINFT to proposal
        proposal.dINFTId = nextDINFTId;

        // Distribute initial grant for the first milestone if available and needed.
        // Or wait for innovator to submit proof for first milestone.
        // Let's assume initial grant is claimed upon first milestone completion.

        emit DINFTMinted(nextDINFTId, _proposalId, proposal.innovator, dINFTs[nextDINFTId].uri);
        nextDINFTId++;
    }

    /**
     * @dev Allows the innovator to submit a proof (e.g., hash of results, link to demo) for a milestone.
     *      This does not automatically validate the milestone.
     * @param _dINFTId The ID of the dINFT (project).
     * @param _milestoneIndex The index of the milestone being completed.
     * @param _proofHash IPFS/Arweave hash of the milestone's proof.
     */
    function submitMilestoneProof(uint256 _dINFTId, uint256 _milestoneIndex, string memory _proofHash)
        public
        onlyInnovator(_dINFTId)
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(_milestoneIndex < dinft.milestones.length, "ChronoForge: Invalid milestone index.");
        require(dinft.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "ChronoForge: Milestone not in Pending status.");
        require(_milestoneIndex == dinft.currentMilestone, "ChronoForge: Milestones must be submitted sequentially.");

        dinft.milestones[_milestoneIndex].proofHash = _proofHash;
        dinft.milestones[_milestoneIndex].status = MilestoneStatus.Submitted;

        emit MilestoneProofSubmitted(_dINFTId, _milestoneIndex, _proofHash);
    }

    /**
     * @dev Innovator requests validation for a previously submitted milestone proof.
     *      This could trigger an off-chain notification to validators.
     * @param _dINFTId The ID of the dINFT.
     * @param _milestoneIndex The index of the milestone to validate.
     */
    function requestMilestoneValidation(uint256 _dINFTId, uint256 _milestoneIndex)
        public
        onlyInnovator(_dINFTId)
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(_milestoneIndex < dinft.milestones.length, "ChronoForge: Invalid milestone index.");
        require(dinft.milestones[_milestoneIndex].status == MilestoneStatus.Submitted, "ChronoForge: Milestone proof not submitted or already validated.");

        // In a real system, this would trigger an off-chain validator pool to pick up the task.
        // For simplicity, it just changes state.
        emit MilestoneValidationRequested(_dINFTId, _milestoneIndex, msg.sender);
    }

    /**
     * @dev Allows a designated validator to review and approve/reject a milestone proof.
     *      Affects innovator and validator reputation.
     * @param _dINFTId The ID of the dINFT.
     * @param _milestoneIndex The index of the milestone being validated.
     * @param _isValid True if the proof is valid, false otherwise.
     * @param _validatorRemarksHash Hash of validator's detailed remarks (e.g., IPFS CID).
     */
    function validateMilestoneProof(uint256 _dINFTId, uint256 _milestoneIndex, bool _isValid, string memory _validatorRemarksHash)
        public
        onlyValidatorAllowed
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(_milestoneIndex < dinft.milestones.length, "ChronoForge: Invalid milestone index.");
        require(dinft.milestones[_milestoneIndex].status == MilestoneStatus.Submitted, "ChronoForge: Milestone not in Submitted status.");
        require(dinft.milestones[_milestoneIndex].validator == address(0), "ChronoForge: Milestone already validated.");

        dinft.milestones[_milestoneIndex].validator = msg.sender;
        dinft.milestones[_milestoneIndex].validatorRemarksHash = _validatorRemarksHash;

        if (_isValid) {
            dinft.milestones[_milestoneIndex].status = MilestoneStatus.Validated;
            _updateReputation(msg.sender, 50, "Validator", "Milestone validated successfully."); // Positive validator reputation
            _updateReputation(dinft.innovator, 100, "Innovator", "Milestone validated successfully."); // Positive innovator reputation
        } else {
            dinft.milestones[_milestoneIndex].status = MilestoneStatus.Rejected;
            _updateReputation(msg.sender, 10, "Validator", "Milestone rejected."); // Minor positive for rejection (preventing bad work)
            _updateReputation(dinft.innovator, -50, "Innovator", "Milestone rejected."); // Negative innovator reputation
        }

        emit MilestoneValidated(_dINFTId, _milestoneIndex, _isValid, msg.sender);
        _updateDINFTMetadata(_dINFTId); // Update dINFT metadata based on new status
    }

    /**
     * @dev Allows the innovator to claim the grant for a successfully validated milestone.
     * @param _dINFTId The ID of the dINFT.
     * @param _milestoneIndex The index of the milestone to claim grant for.
     */
    function claimMilestoneGrant(uint256 _dINFTId, uint256 _milestoneIndex)
        public
        onlyInnovator(_dINFTId)
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(_milestoneIndex < dinft.milestones.length, "ChronoForge: Invalid milestone index.");
        require(dinft.milestones[_milestoneIndex].status == MilestoneStatus.Validated, "ChronoForge: Milestone not validated.");
        require(_milestoneIndex == dinft.completedMilestones, "ChronoForge: Milestones must be claimed sequentially."); // Ensure sequential claim

        InnovationProposal storage proposal = proposals[dinft.proposalId];
        Epoch storage epoch = epochs[proposal.epochId];
        require(epoch.proposalFundingAmount[proposal.id] > 0, "ChronoForge: Proposal not funded or grant already withdrawn.");

        uint256 grantAmount = dinft.milestones[_milestoneIndex].grantAmount;
        require(grantAmount > 0, "ChronoForge: Milestone grant amount is zero.");
        require(epoch.currentFunding >= grantAmount, "ChronoForge: Insufficient funds in epoch treasury.");

        // Transfer funds from epoch treasury to innovator
        epoch.currentFunding -= grantAmount;
        (bool success, ) = dinft.innovator.call{value: grantAmount}("");
        require(success, "ChronoForge: Failed to transfer grant.");

        dinft.completedMilestones++;
        if (dinft.completedMilestones < dinft.milestones.length) {
            dinft.currentMilestone = dinft.completedMilestones; // Advance to next milestone
        } else {
            // All milestones completed.
            // Potentially reward innovator further, mark project as finished.
        }

        emit MilestoneGrantClaimed(_dINFTId, _milestoneIndex, dinft.innovator, grantAmount);
        _updateDINFTMetadata(_dINFTId); // Update dINFT metadata
    }

    /**
     * @dev Internal function to update the dINFT's URI based on its progress.
     *      This simulates the "dynamic" aspect of the NFT.
     * @param _dINFTId The ID of the dINFT.
     */
    function _updateDINFTMetadata(uint256 _dINFTId) internal {
        DINFTData storage dinft = dINFTs[_dINFTId];
        uint256 progress = (dinft.completedMilestones * 100) / dinft.milestones.length;
        string memory newURI = string(abi.encodePacked(
            "ipfs://dinft-metadata/",
            Strings.toString(_dINFTId),
            "/progress_",
            Strings.toString(progress)
        ));
        dinft.uri = newURI;
        emit DINFTMetadataUpdated(_dINFTId, newURI);
    }

    /**
     * @dev Allows a dINFT owner to transfer a percentage of their future royalty/ownership share.
     *      This is for the innovator to share their IP rights or future earnings.
     * @param _dINFTId The ID of the dINFT.
     * @param _recipient The address to transfer the share to.
     * @param _percentage The percentage (in basis points, 10000 = 100%) to transfer.
     */
    function transferDINFTPartialOwnership(uint256 _dINFTId, address _recipient, uint256 _percentage)
        public
        onlyInnovator(_dINFTId)
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(_recipient != address(0), "ChronoForge: Recipient cannot be zero address.");
        require(_percentage > 0 && _percentage <= 10000, "ChronoForge: Percentage must be between 1 and 10000.");

        // For simplicity, this directly updates the royalty split.
        // A more complex system would manage a separate "ownership" token or share registry.
        // For now, it simply re-allocates the `dinft.innovator`'s share.
        // This function would typically reduce the `innovator`'s share and add to `_recipient`.
        // To implement this properly, the `royaltySplits` mapping would need to be initialized with the innovator's 100% first.
        
        // Example: if innovator previously had 100%
        // uint256 currentInnovatorShare = dinft.royaltySplits[dinft.innovator]; // Assuming it's set up
        // require(currentInnovatorShare >= _percentage, "ChronoForge: Innovator does not own that much share.");
        // dinft.royaltySplits[dinft.innovator] -= _percentage;
        dinft.royaltySplits[_recipient] += _percentage; // This just adds, assuming the primary innovator manages this.
        // More robust: use a separate ERC-1155 or a custom token for fractional ownership.

        emit DINFTPartialOwnershipTransferred(_dINFTId, msg.sender, _recipient, _percentage);
    }

    /**
     * @dev Establishes an on-chain royalty split for potential commercialization of the dINFT's IP.
     *      Allows the dINFT owner to register payees for future revenues.
     * @param _dINFTId The ID of the dINFT.
     * @param _payee The address to receive a share of royalties.
     * @param _percentage The percentage (in basis points) of royalties this payee should receive.
     */
    function registerIPRoyaltySplit(uint256 _dINFTId, address _payee, uint256 _percentage)
        public
        onlyInnovator(_dINFTId)
    {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(_payee != address(0), "ChronoForge: Payee cannot be zero address.");
        require(_percentage > 0 && _percentage <= 10000, "ChronoForge: Percentage must be between 1 and 10000.");

        uint256 currentTotalPercentage = 0;
        // This loop would require iterating over all entries, which is bad for gas if many payees.
        // Better: enforce max number of payees, or use a separate "RoyaltySplitter" contract.
        // For simple demo: just set. Max 100% total must be enforced off-chain or by governance.
        // A real system would use a Merkle tree or a payout system like ERC-2981 royalties.
        
        dinft.royaltySplits[_payee] = _percentage; // Overwrites existing, or sets new.

        emit IPRoyaltySplitRegistered(_dINFTId, _payee, _percentage);
    }

    // --- VII. Reputation & Governance Functions ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address whose reputation is being updated.
     * @param _scoreChange The amount to change the score by (positive for gain, negative for loss).
     * @param _role "Innovator" or "Validator" to specify which score to update.
     * @param _reasonHash Hash of the reason for the reputation change.
     */
    function _updateReputation(address _user, int256 _scoreChange, string memory _role, string memory _reasonHash) internal {
        Reputation storage userRep = reputationScores[_user];

        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Innovator"))) {
            if (_scoreChange > 0) userRep.innovatorScore += uint256(_scoreChange);
            else if (userRep.innovatorScore >= uint256(-_scoreChange)) userRep.innovatorScore -= uint256(-_scoreChange);
            else userRep.innovatorScore = 0;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Validator"))) {
            if (_scoreChange > 0) userRep.validatorScore += uint256(_scoreChange);
            else if (userRep.validatorScore >= uint256(-_scoreChange)) userRep.validatorScore -= uint256(-_scoreChange);
            else userRep.validatorScore = 0;
        }

        emit ReputationUpdated(_user, userRep.innovatorScore, userRep.validatorScore);
        _reasonHash; // Suppress unused parameter warning, would be used in a log/off-chain db
    }

    /**
     * @dev Retrieves the current reputation score of an innovator.
     * @param _innovator The address of the innovator.
     * @return The innovator's reputation score.
     */
    function getInnovatorReputation(address _innovator) public view returns (uint256) {
        return reputationScores[_innovator].innovatorScore;
    }

    /**
     * @dev Retrieves the current reputation score of a validator.
     * @param _validator The address of the validator.
     * @return The validator's reputation score.
     */
    function getValidatorReputation(address _validator) public view returns (uint256) {
        return reputationScores[_validator].validatorScore;
    }

    /**
     * @dev Allows a Patron to delegate their voting power to another address.
     *      Voting power is linked to funded amounts in epochs.
     *      Note: This is a placeholder. A full delegation system requires tracking who delegated to whom for each epoch.
     *      For simplicity, it's a global delegation for future epoch funding, or would rely on an external voting contract.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public {
        // In a real system, `epoch.patronVotes[msg.sender]` would be redirected to `_delegatee`.
        // This typically involves an ERC-20 token with a `delegate` function.
        // For this contract, it's a symbolic function.
        // If funds are deposited, they are owned by `msg.sender`, but the voting power (based on funds)
        // is now linked to `_delegatee` for new epoch participations.
        // This would require a mapping: `address => address` for `delegations`.
        // E.g., `mapping(address => address) public votingDelegations;`
        // `votingDelegations[msg.sender] = _delegatee;`
        // Then in `voteOnProposal`, use `votingDelegations[msg.sender]` to get actual voter.

        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a privileged role (e.g., high-reputation patron/innovator)
     *      to submit a protocol-level governance proposal.
     * @param _proposalHash IPFS/Arweave hash of the governance proposal document.
     */
    function submitGovernanceProposal(string memory _proposalHash) public {
        // Example: require a minimum reputation score to submit governance proposals.
        require(reputationScores[msg.sender].innovatorScore >= MIN_GOV_PROPOSAL_REPUTATION ||
                reputationScores[msg.sender].validatorScore >= MIN_GOV_PROPOSAL_REPUTATION,
                "ChronoForge: Insufficient reputation to submit governance proposal.");

        // In a real system, this would trigger an ERC-20 based governance process (e.g., Snapshot, Compound Governor)
        // For now, it's a symbolic function.
        emit GovernanceProposalSubmitted(nextProposalId, _proposalHash, msg.sender);
        // A simple on-chain proposal ID might be needed here, or it defers to an off-chain system.
    }

    // --- VIII. Dispute Resolution & Treasury Functions ---

    /**
     * @dev Initiates a formal dispute regarding a milestone's validation status.
     *      Can be called by innovator (if milestone rejected) or validator (if proof fraudulent).
     * @param _dINFTId The ID of the dINFT.
     * @param _milestoneIndex The index of the milestone under dispute.
     * @param _reasonHash IPFS/Arweave hash detailing the reason for the dispute.
     */
    function initiateDisputeOnMilestone(uint256 _dINFTId, uint256 _milestoneIndex, string memory _reasonHash) public {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(_milestoneIndex < dinft.milestones.length, "ChronoForge: Invalid milestone index.");

        MilestoneStatus status = dinft.milestones[_milestoneIndex].status;
        require(status == MilestoneStatus.Validated || status == MilestoneStatus.Rejected, "ChronoForge: Milestone not in a disputable state.");
        require(msg.sender == dinft.innovator || isValidator[msg.sender], "ChronoForge: Only innovator or validator can initiate dispute.");

        // Prevent duplicate disputes for the same milestone
        for (uint256 i = 1; i < nextDisputeId; i++) {
            if (disputes[i].dINFTId == _dINFTId && disputes[i].milestoneIndex == _milestoneIndex && !disputes[i].resolved) {
                revert("ChronoForge: Dispute already active for this milestone.");
            }
        }

        disputes[nextDisputeId] = Dispute({
            id: nextDisputeId,
            dINFTId: _dINFTId,
            milestoneIndex: _milestoneIndex,
            initiator: msg.sender,
            reasonHash: _reasonHash,
            resolved: false,
            favorInnovator: false, // Default
            resolutionHash: "",
            arbitrator: address(0)
        });

        // Mark milestone as disputed
        dinft.milestones[_milestoneIndex].status = MilestoneStatus.Disputed;

        emit DisputeInitiated(nextDisputeId, _dINFTId, _milestoneIndex, msg.sender);
        nextDisputeId++;
    }

    /**
     * @dev Allows the designated arbiter council to resolve an open dispute.
     *      Affects innovator and validator reputations based on resolution.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _favorInnovator True if the resolution favors the innovator, false otherwise.
     * @param _resolutionHash IPFS/Arweave hash detailing the arbiter's decision.
     */
    function resolveDispute(uint256 _disputeId, bool _favorInnovator, string memory _resolutionHash)
        public
        onlyArbiterCouncil
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "ChronoForge: Dispute does not exist.");
        require(!dispute.resolved, "ChronoForge: Dispute already resolved.");

        DINFTData storage dinft = dINFTs[dispute.dINFTId];
        Milestone storage milestone = dinft.milestones[dispute.milestoneIndex];

        dispute.resolved = true;
        dispute.favorInnovator = _favorInnovator;
        dispute.resolutionHash = _resolutionHash;
        dispute.arbitrator = msg.sender;

        if (_favorInnovator) {
            // Revert milestone to submitted state if it was rejected, or keep validated if it was disputed
            milestone.status = MilestoneStatus.Submitted; // Allows re-validation
            _updateReputation(dinft.innovator, 20, "Innovator", "Dispute resolved in favor of innovator.");
            // Potentially penalize the validator who initially rejected it, or reward if it was a false dispute.
        } else {
            // Milestone remains Rejected or stays Validated if dispute was unfounded
            if (milestone.status == MilestoneStatus.Disputed) { // If it was already validated, dispute was rejected.
                milestone.status = MilestoneStatus.Rejected; // Set to rejected if innovator dispute failed.
            }
            _updateReputation(dinft.innovator, -20, "Innovator", "Dispute resolved against innovator.");
        }

        emit DisputeResolved(_disputeId, _favorInnovator, msg.sender);
    }

    /**
     * @dev Allows registered IP payees to collect accumulated royalties for a dINFT.
     *      Royalties would be external funds sent to this contract, then distributed.
     * @param _dINFTId The ID of the dINFT.
     */
    function collectRoyaltiesForDINFT(uint256 _dINFTId) public {
        DINFTData storage dinft = dINFTs[_dINFTId];
        require(dinft.id != 0, "ChronoForge: dINFT does not exist.");
        require(dinft.accumulatedRoyalties > 0, "ChronoForge: No accumulated royalties for this dINFT.");

        uint256 totalCollected = dinft.accumulatedRoyalties;
        dinft.accumulatedRoyalties = 0; // Reset accumulated royalties

        // Distribute based on royaltySplits.
        // This iteration over a mapping is gas-inefficient if many payees.
        // A better approach would be pull-based (each payee calls to claim their share) or fixed number of payees.
        // For demonstration, iterate over known payees.
        // This assumes `royaltySplits` is an iterable list or small fixed set.
        // Better: have a `claimMyRoyalties(dINFTId)` function.
        
        // This requires an iteration through all keys in `royaltySplits`, which is not directly supported by Solidity mappings.
        // For a practical implementation, `royaltySplits` would need to be accompanied by a dynamic array of payees,
        // or a pull-based system where each payee queries their balance and claims.
        // Here, it will be a symbolic function.
        // Example: Imagine an external `receiveRoyaltyPayment(dINFTId, amount)` function exists.
        // `dINFTs[_dINFTId].accumulatedRoyalties += amount_from_external_source;`

        // Simulate distribution for simplicity:
        // Assume all royalty splits for this dINFT are already tracked.
        // This function would normally calculate the caller's share and send it.
        uint256 callerShare = dinft.royaltySplits[msg.sender];
        require(callerShare > 0, "ChronoForge: You are not a registered payee for this dINFT.");

        uint256 amountToClaim = (totalCollected * callerShare) / 10000; // Calculate caller's share
        require(amountToClaim > 0, "ChronoForge: No royalties to claim for your share.");

        // This assumes the `totalCollected` is held by the contract.
        // In reality, this contract would just be the logic, and a separate treasury holds funds.
        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        require(success, "ChronoForge: Failed to transfer royalties.");

        emit RoyaltiesCollected(_dINFTId, msg.sender, amountToClaim);
    }

    /**
     * @dev Allows the Admin (or DAO via governance) to withdraw funds from the main protocol treasury.
     *      Funds could be for operational costs, liquidity, or specific distributions approved by governance.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyAdmin { // Could be replaced by a DAO voting mechanism
        require(_recipient != address(0), "ChronoForge: Recipient cannot be zero address.");
        require(_amount > 0, "ChronoForge: Amount must be positive.");
        require(address(this).balance >= _amount, "ChronoForge: Insufficient contract balance.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ChronoForge: Failed to withdraw from treasury.");

        emit TreasuryWithdrawn(_recipient, _amount);
    }

    // --- Internal Utility Functions ---

    /**
     * @dev Simple helper to add an element to a dynamic array.
     */
    function _addToArray(uint256[] memory _array, uint256 _element) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _element;
        return newArray;
    }
}

// Minimal String conversion utility (inspired by OpenZeppelin's Strings.sol)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint8(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```