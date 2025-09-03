Here's a smart contract written in Solidity, focusing on advanced, creative, and trendy concepts within the decentralized science (DeSci) domain, augmented by AI oracle integration and dynamic reputation systems. It aims to be distinct from common open-source implementations by combining these elements into a cohesive protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For Researcher NFTs (dynamic metadata)
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // For Reputation Badges (SBT-like)
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Optional: For advanced data claim verification

// Note on AI Oracle Integration:
// For actual AI oracle integration, you would use Chainlink Automation, Chainlink Functions, or similar
// services. This contract abstracts the oracle interaction to an address and a `submitAIValidationResult`
// function, assuming the off-chain component handles the AI logic and calls back securely.

/**
 * @title DARVProtocol (Decentralized AI-Augmented Research & Validation Protocol)
 * @author YourName (Simulated for this exercise)
 * @notice This contract facilitates a decentralized ecosystem for scientific research,
 *         from proposal and funding to peer review and validation, enhanced by AI oracles.
 *         It incorporates reputation-bound tokens (SBTs) for researchers and validators,
 *         dynamic NFTs for researcher profiles, and a robust system for verifiable data claims.
 *
 * Outline:
 * 1.  **Core Structures & Enums:** Defines the fundamental data types and states for projects, milestones, data claims, and researcher profiles.
 * 2.  **Researcher Management (SBTs & Dynamic NFTs):** Handles researcher registration, profile updates, and reputation tracking. Researcher profiles are represented by non-transferable ERC721 tokens whose metadata URI can be dynamically updated based on achievements. Reputation badges are issued as non-transferable ERC1155 tokens.
 * 3.  **Project Lifecycle:** Manages the entire research project journey from initial proposal, community funding, milestone submission, to final research findings publication.
 * 4.  **Validation & Review:** Implements mechanisms for community validation of milestones and data claims, augmented by AI oracle-driven assessments for objectivity, novelty, or fraud detection. Includes a basic dispute resolution system.
 * 5.  **Reputation & Incentives:** Defines how reputation is earned (or lost) and how participants are rewarded, utilizing non-transferable SBTs for specific achievements and ETH for financial incentives.
 * 6.  **Administrative Functions:** Protocol owner's ability to set global parameters, configure the AI oracle, and manage protocol fees.
 *
 * Function Summary (24 Functions):
 *
 * **Initialization & Settings:**
 * 1.  `constructor()`: Initializes the contract, setting the deployer as the initial owner and configuring base ERC721/ERC1155 settings.
 * 2.  `setProtocolSettings(uint256 _proposalFee, uint256 _validatorStake, uint256 _minFundingDuration, uint256 _milestoneVoteDuration)`: Allows the owner to configure global economic and timing parameters for the protocol.
 * 3.  `setOracleAddress(address _oracle)`: Sets the address of the trusted AI oracle contract that will submit validation results.
 *
 * **Researcher Profiles & Reputation:**
 * 4.  `registerResearcher(string memory _name, string memory _bioURI)`: Creates a unique, non-transferable ERC721 token (Researcher NFT) for a new researcher, linking it to their on-chain profile and off-chain metadata.
 * 5.  `updateResearcherProfile(string memory _newBioURI)`: Allows a registered researcher to update the metadata URI of their Researcher NFT, reflecting changes in their profile or achievements.
 * 6.  `getResearcherProfile(address _researcher)`: Retrieves the basic profile information (NFT ID, name, bio URI, reputation) for a given researcher.
 * 7.  `getResearcherReputation(address _researcher)`: Returns the current reputation score of a researcher, aggregated from their successful activities.
 *
 * **Research Project Management:**
 * 8.  `proposeResearchProject(string memory _title, string memory _descriptionURI, uint256 _budget, uint256[] memory _milestoneAmounts, string[] memory _milestoneDescriptionURIs)`: Submits a new research proposal, including its total budget, and detailed, segmented milestones. Requires a protocol fee.
 * 9.  `fundProject(uint256 _projectId)`: Allows users to contribute ETH towards a specific research project's funding goal.
 * 10. `submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofURI)`: The project's researcher submits verifiable proof for a completed milestone, initiating a community review period.
 * 11. `publishResearchFindings(uint256 _projectId, string memory _findingsURI, bytes32[] memory _dataHashes, string[] memory _dataClaimDescriptions)`: The researcher publishes final research findings, including hashes of underlying data and explicit claims about that data.
 * 12. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details about a specific research project, including its status, funding, and milestones.
 *
 * **Validation & Review:**
 * 13. `voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _approved)`: Community validators stake ETH and cast their vote on whether a submitted milestone proof is satisfactory.
 * 14. `requestAIValidationScore(uint256 _projectId, uint256 _targetId, AITargetType _targetType)`: Initiates a request to the AI oracle for an objective assessment of a project component (e.g., proposal, findings, or a specific claim).
 * 15. `submitAIValidationResult(bytes32 _requestId, int256 _score)`: This function is exclusively called by the trusted AI oracle to deliver the computed score or result for a prior validation request.
 * 16. `attestToDataClaim(uint256 _projectId, uint256 _claimIndex, bool _valid)`: Validators stake ETH and attest to the perceived validity of a specific data claim published as part of the research findings.
 * 17. `initiateDispute(uint256 _projectId, uint256 _milestoneIndex, string memory _reasonURI)`: Allows a validator or researcher to formally challenge the status or validity of a milestone or other project component.
 * 18. `resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _isResearcherFavored, address[] memory _slashedValidators)`: The protocol owner (or a DAO) resolves a dispute, potentially releasing funds, adjusting reputations, and slashing stakes of dishonest validators.
 *
 * **Rewards & Incentives:**
 * 19. `claimResearcherRewards(uint256 _projectId)`: Allows a researcher to claim accumulated ETH from their successfully completed and validated milestones within a project.
 * 20. `claimValidatorRewards()`: Allows validators to claim their refunded stakes from successfully participated votes/attestations, and any earned rewards.
 *
 * **Internal / Utility (called by other functions or specific roles):**
 * 21. `_mintReputationBadge(address _recipient, uint256 _badgeId, uint256 _amount)`: Internal helper function to mint non-transferable ERC1155 reputation badges for various achievements within the protocol.
 * 22. `_updateResearcherNFTMetadata(address _researcher, string memory _newURI)`: Internal helper function to dynamically update the metadata URI of a researcher's ERC721 profile NFT.
 * 23. `getTotalProjectFunds(uint256 _projectId)`: View function to retrieve the current total ETH amount contributed to a specific project.
 * 24. `getProjectStatus(uint256 _projectId)`: View function to get the current status (enum) of a research project.
 * 25. `withdrawProtocolFees()`: Owner function to withdraw accumulated protocol fees.
 */
contract DARVProtocol is Ownable, ERC721("ResearcherProfileNFT", "RPRO"), ERC1155 {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _researcherIdCounter;
    Counters.Counter private _badgeIdCounter; // For unique reputation badges

    address public aiOracleAddress;

    // Protocol settings (set by owner, can be updated)
    uint256 public proposalFee = 0.01 ether; // Fee to propose a project (e.g., 0.01 ETH)
    uint256 public validatorStake = 0.05 ether; // ETH stake required for validators (e.g., 0.05 ETH)
    uint256 public minFundingDuration = 7 days; // Minimum duration for project funding phase in seconds
    uint256 public milestoneVoteDuration = 3 days; // Duration for community voting on milestones in seconds

    uint256 public totalProtocolFeesCollected; // ETH collected from proposal fees and slashed stakes

    // Mappings
    mapping(address => uint256) public researcherToId; // Maps researcher address to their NFT ID
    mapping(uint256 => Researcher) public researchers; // Maps researcher ID to their profile data
    mapping(address => uint256) public researcherReputation; // Tracks researcher reputation score

    mapping(uint256 => Project) public projects; // Maps project ID to project details
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVotedOnMilestone; // projectId -> milestoneIndex -> validator -> voted
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasAttestedToClaim; // projectId -> claimIndex -> validator -> attested

    mapping(address => uint256) public validatorStakes; // Tracks current staked amount by validators
    mapping(address => uint256) public validatorRewards; // Tracks pending rewards for validators (e.g., refunded stake + bonus)

    mapping(bytes32 => AIRequest) public aiRequests; // requestId -> AIRequest details

    // --- Enums ---
    enum ProjectStatus { Proposed, Funding, Active, Completed, Disputed, Cancelled }
    enum MilestoneStatus { Pending, Voting, Completed, Disputed }
    enum AITargetType { Proposal, Findings, MilestoneProof, DataClaim } // What the AI is evaluating

    // --- Structs ---
    struct Researcher {
        uint256 id;
        address wallet;
        string name;
        string bioURI; // URI to IPFS/Arweave for researcher's biography/CV (linked to NFT metadata)
        uint256 reputation; // Accumulated reputation score
    }

    struct Milestone {
        uint256 amount; // ETH amount allocated for this milestone
        string descriptionURI; // URI to IPFS/Arweave for milestone description
        string proofURI; // URI to IPFS/Arweave for proof of completion
        MilestoneStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 validatorStakesCollected; // Total stakes for this milestone
        uint256 voteEndTime; // Timestamp when voting for this milestone ends
    }

    struct DataClaim {
        bytes32 dataHash; // SHA256 hash of the underlying data for integrity
        string description; // Description of the claim about the data
        uint256 attestationsFor;
        uint256 attestationsAgainst;
        bool isValidated; // Final status after community/AI review
    }

    struct Project {
        uint256 id;
        address researcher;
        string title;
        string descriptionURI; // URI to IPFS/Arweave for full project description
        uint256 budget; // Total ETH budget for the project
        uint256 fundedAmount;
        uint256 fundingEndTime; // Timestamp when funding period ends
        ProjectStatus status;
        Milestone[] milestones;
        DataClaim[] dataClaims; // Claims attached to final research findings
        uint256 totalRewardClaimed; // Total ETH claimed by researcher
    }

    struct AIRequest {
        uint256 projectId;
        uint256 targetId; // Milestone index, claim index, or 0 for project/findings
        AITargetType targetType;
        address requester;
        bool fulfilled;
        int256 result; // AI's score or boolean indicator (e.g., -100 to 100, or 0/1)
    }

    // --- Events ---
    event ProtocolSettingsUpdated(uint256 newProposalFee, uint256 newValidatorStake, uint256 newMinFundingDuration, uint256 newMilestoneVoteDuration);
    event OracleAddressUpdated(address indexed newOracleAddress);
    event ResearcherRegistered(address indexed researcher, uint256 researcherId, string name, string bioURI);
    event ResearcherProfileUpdated(address indexed researcher, uint256 researcherId, string newBioURI);
    event ProjectProposed(uint256 indexed projectId, address indexed researcher, string title, uint256 budget, uint256 fundingEndTime);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofURI);
    event MilestoneVoteCasted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed validator, bool approved);
    event MilestoneCompleted(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 fundsReleased);
    event ResearchFindingsPublished(uint256 indexed projectId, string findingsURI);
    event DataClaimAttested(uint256 indexed projectId, uint256 indexed claimIndex, address indexed attester, bool valid);
    event AIValidationRequested(bytes32 indexed requestId, uint256 indexed projectId, AITargetType targetType);
    event AIValidationResultReceived(bytes32 indexed requestId, int256 score);
    event DisputeInitiated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed initiator, string reasonURI);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isResearcherFavored);
    event ResearcherRewardsClaimed(uint256 indexed projectId, address indexed researcher, uint256 amount);
    event ValidatorRewardsClaimed(address indexed validator, uint256 amount);
    event ReputationBadgeMinted(address indexed recipient, uint256 badgeId, uint256 amount);

    // --- Constructor ---
    // ERC1155 constructor requires a URI, setting a placeholder. Specific badge URIs can be managed off-chain.
    constructor() ERC1155("https://darv.protocol/badges/{id}.json") {}

    // --- Modifiers ---
    modifier onlyResearcher(uint256 _projectId) {
        require(msg.sender == projects[_projectId].researcher, "DARV: Not project researcher");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "DARV: Only trusted AI oracle can call");
        _;
    }

    // --- Functions ---

    // 1. Constructor (handled by `Ownable` and initial `ERC1155` setup)

    /**
     * @summary Configures global protocol parameters for fees, stakes, and durations.
     * @param _proposalFee The ETH fee required to propose a new research project.
     * @param _validatorStake The ETH amount validators must stake to participate in voting or attestation.
     * @param _minFundingDuration Minimum duration for a project's funding phase in seconds.
     * @param _milestoneVoteDuration Duration for milestone voting in seconds.
     */
    function setProtocolSettings(
        uint256 _proposalFee,
        uint256 _validatorStake,
        uint256 _minFundingDuration,
        uint256 _milestoneVoteDuration
    ) external onlyOwner {
        require(_proposalFee > 0 && _validatorStake > 0, "DARV: Fees and stakes must be positive");
        require(_minFundingDuration > 0 && _milestoneVoteDuration > 0, "DARV: Durations must be positive");

        proposalFee = _proposalFee;
        validatorStake = _validatorStake;
        minFundingDuration = _minFundingDuration;
        milestoneVoteDuration = _milestoneVoteDuration;

        emit ProtocolSettingsUpdated(_proposalFee, _validatorStake, _minFundingDuration, _milestoneVoteDuration);
    }

    /**
     * @summary Sets the address of the trusted AI oracle contract that can submit validation results.
     * @param _oracle The address of the AI oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "DARV: Oracle address cannot be zero");
        aiOracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    /**
     * @summary Registers a new researcher and mints a non-transferable Researcher Profile NFT (ERC721).
     *          This NFT's metadata URI can be updated dynamically to reflect reputation and achievements.
     * @param _name The public name/alias of the researcher.
     * @param _bioURI The IPFS/Arweave URI for the researcher's detailed biography/CV.
     */
    function registerResearcher(string memory _name, string memory _bioURI) external {
        require(researcherToId[msg.sender] == 0, "DARV: Researcher already registered");
        require(bytes(_name).length > 0, "DARV: Name cannot be empty");
        require(bytes(_bioURI).length > 0, "DARV: Bio URI cannot be empty");

        _researcherIdCounter.increment();
        uint256 newId = _researcherIdCounter.current();

        researcherToId[msg.sender] = newId;
        researchers[newId] = Researcher({
            id: newId,
            wallet: msg.sender,
            name: _name,
            bioURI: _bioURI,
            reputation: 0 // Initial reputation
        });

        // Mint the ERC721 token for the researcher. It's designed to be non-transferable.
        _mint(msg.sender, newId);
        _setTokenURI(newId, _bioURI); // Set initial metadata URI for the dynamic NFT

        emit ResearcherRegistered(msg.sender, newId, _name, _bioURI);
    }

    /**
     * @summary Allows a registered researcher to update the metadata URI of their Researcher Profile NFT.
     *          This function highlights the "dynamic" aspect of the NFT, allowing profiles to evolve.
     * @param _newBioURI The new IPFS/Arweave URI for the updated biography/CV or profile details.
     */
    function updateResearcherProfile(string memory _newBioURI) external {
        uint256 researcherId = researcherToId[msg.sender];
        require(researcherId != 0, "DARV: Caller is not a registered researcher");
        require(bytes(_newBioURI).length > 0, "DARV: New Bio URI cannot be empty");

        researchers[researcherId].bioURI = _newBioURI;
        _setTokenURI(researcherId, _newBioURI); // Update the NFT's metadata URI

        emit ResearcherProfileUpdated(msg.sender, researcherId, _newBioURI);
    }

    /**
     * @summary Retrieves the basic profile information for a given researcher.
     * @param _researcher The address of the researcher.
     * @return id The unique ID of the researcher.
     * @return name The public name of the researcher.
     * @return bioURI The IPFS/Arweave URI of their biography.
     * @return reputation The current reputation score.
     */
    function getResearcherProfile(address _researcher) external view returns (uint256 id, string memory name, string memory bioURI, uint256 reputation) {
        uint256 researcherId = researcherToId[_researcher];
        require(researcherId != 0, "DARV: Researcher not registered");
        Researcher storage r = researchers[researcherId];
        return (r.id, r.name, r.bioURI, r.reputation);
    }

    /**
     * @summary Returns the current reputation score of a researcher.
     * @param _researcher The address of the researcher.
     * @return The current reputation score.
     */
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        uint256 researcherId = researcherToId[_researcher];
        require(researcherId != 0, "DARV: Researcher not registered");
        return researchers[researcherId].reputation;
    }

    /**
     * @summary Submits a new research project proposal. Requires a `proposalFee` payment.
     *          The sum of milestone amounts must equal the total budget.
     * @param _title The title of the research project.
     * @param _descriptionURI The IPFS/Arweave URI for the detailed project description.
     * @param _budget The total ETH budget requested for the project.
     * @param _milestoneAmounts An array of ETH amounts allocated for each milestone.
     * @param _milestoneDescriptionURIs An array of IPFS/Arweave URIs for each milestone's description.
     */
    function proposeResearchProject(
        string memory _title,
        string memory _descriptionURI,
        uint256 _budget,
        uint256[] memory _milestoneAmounts,
        string[] memory _milestoneDescriptionURIs
    ) external payable {
        require(msg.value == proposalFee, "DARV: Incorrect proposal fee");
        require(researcherToId[msg.sender] != 0, "DARV: Only registered researchers can propose");
        require(bytes(_title).length > 0, "DARV: Project title cannot be empty");
        require(bytes(_descriptionURI).length > 0, "DARV: Description URI cannot be empty");
        require(_milestoneAmounts.length == _milestoneDescriptionURIs.length && _milestoneAmounts.length > 0, "DARV: Milestone counts mismatch or no milestones");
        require(_budget > 0, "DARV: Budget must be positive");

        uint256 totalMilestoneAmount;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "DARV: Milestone amount must be positive");
            require(bytes(_milestoneDescriptionURIs[i]).length > 0, "DARV: Milestone description URI cannot be empty");
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _budget, "DARV: Sum of milestone amounts must equal total budget");

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        Milestone[] memory newMilestones = new Milestone[](_milestoneAmounts.length);
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            newMilestones[i] = Milestone({
                amount: _milestoneAmounts[i],
                descriptionURI: _milestoneDescriptionURIs[i],
                proofURI: "",
                status: MilestoneStatus.Pending,
                votesFor: 0,
                votesAgainst: 0,
                validatorStakesCollected: 0,
                voteEndTime: 0
            });
        }

        projects[newProjectId] = Project({
            id: newProjectId,
            researcher: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            budget: _budget,
            fundedAmount: 0,
            fundingEndTime: block.timestamp + minFundingDuration, // Set funding duration
            status: ProjectStatus.Funding,
            milestones: newMilestones,
            dataClaims: new DataClaim[](0), // Initially empty
            totalRewardClaimed: 0
        });

        totalProtocolFeesCollected += proposalFee;
        emit ProjectProposed(newProjectId, msg.sender, _title, _budget, projects[newProjectId].fundingEndTime);
    }

    /**
     * @summary Allows users to contribute ETH to a specific research project's funding goal.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        require(project.status == ProjectStatus.Funding, "DARV: Project not in funding phase");
        require(block.timestamp <= project.fundingEndTime, "DARV: Funding period has ended");
        require(msg.value > 0, "DARV: Funding amount must be positive");

        project.fundedAmount += msg.value;

        if (project.fundedAmount >= project.budget) {
            project.status = ProjectStatus.Active; // Project is fully funded and moves to active
            _mintReputationBadge(msg.sender, 101, 1); // Example: Mint a "Project Funder" badge
        }
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @summary Researcher submits verifiable proof for a completed milestone. This opens a voting period.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-based).
     * @param _proofURI The IPFS/Arweave URI for the proof of completion (e.g., lab notebook, data links).
     */
    function submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofURI)
        external
        onlyResearcher(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DARV: Project not active");
        require(_milestoneIndex < project.milestones.length, "DARV: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Pending, "DARV: Milestone not in pending status");
        require(bytes(_proofURI).length > 0, "DARV: Proof URI cannot be empty");

        milestone.proofURI = _proofURI;
        milestone.status = MilestoneStatus.Voting;
        milestone.voteEndTime = block.timestamp + milestoneVoteDuration;

        emit MilestoneProofSubmitted(_projectId, _milestoneIndex, _proofURI);
    }

    /**
     * @summary Researcher publishes final research findings, including data hashes and descriptive claims.
     *          All milestones must be completed before findings can be published.
     * @param _projectId The ID of the project.
     * @param _findingsURI The IPFS/Arweave URI for the full research findings document (e.g., paper, report).
     * @param _dataHashes An array of SHA256 hashes of the underlying data files (e.g., raw data, processed data).
     * @param _dataClaimDescriptions An array of descriptive claims about each data hash.
     */
    function publishResearchFindings(
        uint256 _projectId,
        string memory _findingsURI,
        bytes32[] memory _dataHashes,
        string[] memory _dataClaimDescriptions
    ) external onlyResearcher(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DARV: Project not active");
        require(bytes(_findingsURI).length > 0, "DARV: Findings URI cannot be empty");
        require(_dataHashes.length == _dataClaimDescriptions.length, "DARV: Data hashes and claims count mismatch");

        // Ensure all milestones are completed before publishing findings
        for (uint256 i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].status == MilestoneStatus.Completed, "DARV: All milestones must be completed first");
        }

        // Add data claims for community/AI validation
        for (uint256 i = 0; i < _dataHashes.length; i++) {
            require(bytes(_dataClaimDescriptions[i]).length > 0, "DARV: Data claim description cannot be empty");
            project.dataClaims.push(DataClaim({
                dataHash: _dataHashes[i],
                description: _dataClaimDescriptions[i],
                attestationsFor: 0,
                attestationsAgainst: 0,
                isValidated: false
            }));
        }

        project.status = ProjectStatus.Completed; // Mark project as completed
        emit ResearchFindingsPublished(_projectId, _findingsURI);
        _mintReputationBadge(msg.sender, 201, 1); // Example: Mint a "Project Completed" badge
        researchers[researcherToId[project.researcher]].reputation += 50; // Boost reputation for completion
        _updateResearcherNFTMetadata(project.researcher, researchers[researcherToId[project.researcher]].bioURI); // Update dynamic NFT
    }

    /**
     * @summary Retrieves comprehensive details about a specific research project.
     * @param _projectId The ID of the project.
     * @return All stored details of the project.
     */
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        require(projects[_projectId].id != 0, "DARV: Project does not exist");
        return projects[_projectId];
    }

    /**
     * @summary Community validators stake ETH and vote on whether a milestone's proof is satisfactory.
     *          Voters must be registered researchers (acting as validators).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _approved True if the validator approves the proof, false otherwise.
     */
    function voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external payable {
        require(msg.value == validatorStake, "DARV: Incorrect validator stake amount");
        require(researcherToId[msg.sender] != 0, "DARV: Caller must be a registered researcher to vote");

        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "DARV: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];

        require(milestone.status == MilestoneStatus.Voting, "DARV: Milestone not in voting phase");
        require(block.timestamp <= milestone.voteEndTime, "DARV: Voting period has ended");
        require(!hasVotedOnMilestone[_projectId][_milestoneIndex][msg.sender], "DARV: Already voted on this milestone");

        if (_approved) {
            milestone.votesFor++;
        } else {
            milestone.votesAgainst++;
        }
        milestone.validatorStakesCollected += validatorStake;
        validatorStakes[msg.sender] += validatorStake; // Track total stake
        hasVotedOnMilestone[_projectId][_milestoneIndex][msg.sender] = true;

        emit MilestoneVoteCasted(_projectId, _milestoneIndex, msg.sender, _approved);

        // Check and finalize milestone if vote duration is over (or specific threshold met)
        _checkMilestoneCompletion(_projectId, _milestoneIndex);
    }

    /**
     * @summary Internal function to check and finalize a milestone's completion status after voting.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function _checkMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) internal {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        // This logic can be more complex (e.g., minimum number of votes, quadratic voting, etc.)
        // For simplicity, finalizes if vote duration is over and in Voting state.
        if (block.timestamp > milestone.voteEndTime && milestone.status == MilestoneStatus.Voting) {
            if (milestone.votesFor > milestone.votesAgainst) {
                milestone.status = MilestoneStatus.Completed;
                researchers[researcherToId[project.researcher]].reputation += 10; // Reward researcher reputation
                _mintReputationBadge(project.researcher, 301, 1); // "Milestone Achiever"
                _updateResearcherNFTMetadata(project.researcher, researchers[researcherToId[project.researcher]].bioURI); // Update dynamic NFT
                emit MilestoneCompleted(_projectId, _milestoneIndex, milestone.amount);
            } else {
                milestone.status = MilestoneStatus.Disputed; // If rejected, it enters a disputed state
                project.status = ProjectStatus.Disputed; // Mark project disputed
                // No reputation penalty yet, moves to dispute resolution.
            }
            // Logic to refund or reward validators is handled in `claimValidatorRewards`.
        }
    }

    /**
     * @summary Sends a request to the configured AI oracle for an objective assessment.
     *          This is a conceptual integration; actual integration would use Chainlink Functions or similar.
     * @param _projectId The ID of the project.
     * @param _targetId The index of the milestone, claim, or 0 for project/findings.
     * @param _targetType The type of entity being validated (Proposal, Findings, MilestoneProof, DataClaim).
     * @return requestId A unique ID for this AI request.
     */
    function requestAIValidationScore(uint256 _projectId, uint256 _targetId, AITargetType _targetType) external {
        require(aiOracleAddress != address(0), "DARV: AI Oracle address not set");
        // Only registered researchers or protocol owner can request AI validation
        require(researcherToId[msg.sender] != 0 || msg.sender == owner(), "DARV: Unauthorized AI request");

        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");

        // Generate a unique request ID (e.g., hash of current state, or Chainlink's requestId)
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _projectId, _targetId, _targetType, block.number));

        aiRequests[requestId] = AIRequest({
            projectId: _projectId,
            targetId: _targetId,
            targetType: _targetType,
            requester: msg.sender,
            fulfilled: false,
            result: 0
        });

        // In a real Chainlink Functions setup, this would trigger an off-chain call:
        // `i_functionsRouter.sendRequest(source, donId, callbackGasLimit, args)`

        emit AIValidationRequested(requestId, _projectId, _targetType);
    }

    /**
     * @summary Called by the AI oracle to deliver the result of a validation request on-chain.
     *          This function should only be callable by the trusted AI oracle address.
     * @param _requestId The unique ID of the AI request.
     * @param _score The integer score or result provided by the AI (e.g., 0 for negative, 1 for positive, or a range).
     */
    function submitAIValidationResult(bytes32 _requestId, int256 _score) external onlyOracle {
        AIRequest storage req = aiRequests[_requestId];
        require(!req.fulfilled, "DARV: AI request already fulfilled");
        require(req.projectId != 0, "DARV: Invalid AI request ID"); // Ensure request exists

        req.fulfilled = true;
        req.result = _score;

        // --- AI Result Processing Logic (conceptual) ---
        // This section would contain more complex logic based on the AI's score and target type.
        // For example:
        Project storage project = projects[req.projectId];
        if (req.targetType == AITargetType.Proposal) {
            // AI could score novelty/feasibility. Negative score might lead to project cancellation.
            if (_score < 0) {
                project.status = ProjectStatus.Cancelled;
                // Potentially refund proposal fee minus a small processing fee.
            }
        } else if (req.targetType == AITargetType.DataClaim) {
            // AI verifies data consistency/fraud. Positive score validates claim.
            if (uint256(req.targetId) < project.dataClaims.length) {
                if (_score > 0) { // Assuming positive score means valid
                    project.dataClaims[req.targetId].isValidated = true;
                    // Boost researcher reputation for AI-validated claims
                    researchers[researcherToId[project.researcher]].reputation += 15;
                    _updateResearcherNFTMetadata(project.researcher, researchers[researcherToId[project.researcher]].bioURI);
                } else {
                    // Claim invalidated, potentially trigger dispute or penalty.
                }
            }
        } else if (req.targetType == AITargetType.MilestoneProof) {
            // AI checks proof validity.
            if (uint256(req.targetId) < project.milestones.length && project.milestones[uint256(req.targetId)].status == MilestoneStatus.Voting) {
                 if (_score > 0) {
                     project.milestones[uint256(req.targetId)].votesFor += 1; // AI counts as a strong "for" vote
                 } else {
                     project.milestones[uint256(req.targetId)].votesAgainst += 1; // AI counts as a strong "against" vote
                 }
                _checkMilestoneCompletion(req.projectId, uint256(req.targetId)); // Re-check completion after AI vote
            }
        }

        emit AIValidationResultReceived(_requestId, _score);
    }

    /**
     * @summary Validators attest to the validity of a specific data claim published by a researcher.
     *          Requires staking `validatorStake`.
     * @param _projectId The ID of the project.
     * @param _claimIndex The index of the data claim (0-based).
     * @param _valid True if the validator believes the claim is valid, false otherwise.
     */
    function attestToDataClaim(uint256 _projectId, uint256 _claimIndex, bool _valid) external payable {
        require(msg.value == validatorStake, "DARV: Incorrect validator stake amount");
        require(researcherToId[msg.sender] != 0, "DARV: Caller must be a registered researcher to attest");

        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        require(_claimIndex < project.dataClaims.length, "DARV: Invalid data claim index");
        DataClaim storage claim = project.dataClaims[_claimIndex];

        require(!hasAttestedToClaim[_projectId][_claimIndex][msg.sender], "DARV: Already attested to this claim");

        if (_valid) {
            claim.attestationsFor++;
        } else {
            claim.attestationsAgainst++;
        }
        validatorStakes[msg.sender] += validatorStake;
        hasAttestedToClaim[_projectId][_claimIndex][msg.sender] = true;

        emit DataClaimAttested(_projectId, _claimIndex, msg.sender, _valid);

        // Logic to finalize claim validation could be added here, e.g., after N attestations or a time period.
        // For simplicity, it just counts attestations; formal validation could trigger `requestAIValidationScore`.
    }

    /**
     * @summary Allows a validator or researcher to initiate a dispute over a milestone (or potentially a general project aspect).
     *          This moves the project into a `Disputed` state awaiting resolution.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being disputed.
     * @param _reasonURI The IPFS/Arweave URI detailing the reason for the dispute.
     */
    function initiateDispute(uint256 _projectId, uint256 _milestoneIndex, string memory _reasonURI) external {
        // Can add a small dispute fee or stake to prevent spam.
        require(researcherToId[msg.sender] != 0 || msg.sender == owner(), "DARV: Only registered researchers/owner can initiate disputes");
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        require(bytes(_reasonURI).length > 0, "DARV: Reason URI cannot be empty");
        require(project.status != ProjectStatus.Disputed, "DARV: Project already in dispute");


        require(_milestoneIndex < project.milestones.length, "DARV: Invalid milestone index for dispute initiation");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status != MilestoneStatus.Disputed, "DARV: Milestone already in dispute");

        milestone.status = MilestoneStatus.Disputed;
        project.status = ProjectStatus.Disputed; // Set project to disputed

        emit DisputeInitiated(_projectId, _milestoneIndex, msg.sender, _reasonURI);
    }

    /**
     * @summary The protocol owner (or a DAO in a more complex setup) resolves a dispute.
     *          This can involve releasing funds, adjusting reputations, and slashing stakes of dishonest validators.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone under dispute.
     * @param _isResearcherFavored True if the dispute is resolved in favor of the researcher, false otherwise.
     * @param _slashedValidators An array of validator addresses whose stakes should be forfeited due to dishonest voting/attestation.
     */
    function resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _isResearcherFavored, address[] memory _slashedValidators) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "DARV: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Disputed, "DARV: Milestone not in dispute");

        if (_isResearcherFavored) {
            milestone.status = MilestoneStatus.Completed;
            researchers[researcherToId[project.researcher]].reputation += 20; // Reward higher for winning dispute
            _updateResearcherNFTMetadata(project.researcher, researchers[researcherToId[project.researcher]].bioURI);
            _mintReputationBadge(project.researcher, 302, 1); // "Dispute Winner" badge
        } else {
            milestone.status = MilestoneStatus.Pending; // Researcher loses, milestone goes back to pending or fails
            // Penalize researcher reputation for failed milestone/dispute loss
            uint256 currentRep = researchers[researcherToId[project.researcher]].reputation;
            researchers[researcherToId[project.researcher]].reputation = currentRep >= 10 ? currentRep - 10 : 0;
            _mintReputationBadge(project.researcher, 401, 1); // "Dispute Loser" badge
        }

        // Handle validator slashing and reputation adjustments
        for (uint256 i = 0; i < _slashedValidators.length; i++) {
            // Stakes for slashed validators are forfeited to protocol fees
            totalProtocolFeesCollected += validatorStakes[_slashedValidators[i]];
            validatorStakes[_slashedValidators[i]] = 0; // Clear their stake (they don't get it back)
            // Penalize validator reputation
            uint256 currentValRep = researcherReputation[_slashedValidators[i]];
            researcherReputation[_slashedValidators[i]] = currentValRep >= 5 ? currentValRep - 5 : 0;
            _mintReputationBadge(_slashedValidators[i], 402, 1); // "Slashed Validator" badge
        }

        // Set project status back to Active if other milestones are pending, or Completed if all done
        bool allMilestonesCompleted = true;
        for(uint256 i=0; i < project.milestones.length; i++) {
            if(project.milestones[i].status != MilestoneStatus.Completed) {
                allMilestonesCompleted = false;
                break;
            }
        }
        project.status = allMilestonesCompleted ? ProjectStatus.Completed : ProjectStatus.Active;

        emit DisputeResolved(_projectId, _milestoneIndex, _isResearcherFavored);
    }

    /**
     * @summary Researcher claims accumulated ETH from successfully completed and validated milestones/projects.
     * @param _projectId The ID of the project.
     */
    function claimResearcherRewards(uint256 _projectId) external onlyResearcher(_projectId) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");

        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status == MilestoneStatus.Completed && project.milestones[i].amount > 0) {
                claimableAmount += project.milestones[i].amount;
                project.milestones[i].amount = 0; // Zero out to prevent re-claiming
            }
        }

        require(claimableAmount > 0, "DARV: No claimable rewards for this project yet");

        project.totalRewardClaimed += claimableAmount;
        payable(msg.sender).transfer(claimableAmount); // Transfer funds

        emit ResearcherRewardsClaimed(_projectId, msg.sender, claimableAmount);
    }

    /**
     * @summary Validators claim their refunded stakes from successfully participated votes/attestations, plus any earned rewards.
     */
    function claimValidatorRewards() external {
        uint256 totalClaimableRewards = validatorRewards[msg.sender];
        uint256 totalRefundableStakes = validatorStakes[msg.sender]; // This represents their net stake to be refunded or lost

        require(totalClaimableRewards + totalRefundableStakes > 0, "DARV: No claimable rewards or stakes for this validator");

        validatorRewards[msg.sender] = 0; // Reset rewards
        validatorStakes[msg.sender] = 0; // Reset stakes (these were refunded or slashed during resolution)

        // For simplicity, a small reward can be paid from protocol fees if system design allows
        // Example: uint256 rewardBonus = totalRefundableStakes / 10;
        // totalProtocolFeesCollected -= rewardBonus; // If paying from fees

        payable(msg.sender).transfer(totalClaimableRewards + totalRefundableStakes);

        // _mintReputationBadge(msg.sender, 501, 1); // Example: "Active Validator" badge
        emit ValidatorRewardsClaimed(msg.sender, totalClaimableRewards + totalRefundableStakes);
    }

    /**
     * @summary Internal function to mint non-transferable reputation badges (ERC1155) for achievements.
     *          These badges are Soulbound Tokens (SBTs) and cannot be transferred.
     * @param _recipient The address to mint the badge to.
     * @param _badgeId The ID of the badge to mint (e.g., 101 for Funder, 201 for Project Completed).
     * @param _amount The number of badges to mint (usually 1 for unique achievements).
     */
    function _mintReputationBadge(address _recipient, uint256 _badgeId, uint256 _amount) internal {
        // Here, you would typically define metadata URI for each badge ID (e.g., via `ERC1155._setURI`)
        // The ERC1155 constructor already sets a base URI.

        _mint(_recipient, _badgeId, _amount, ""); // ERC1155 mint
        // Reputation score can also be updated here based on the badge value
        researchers[researcherToId[_recipient]].reputation += 5; // Small reputation boost for any badge

        emit ReputationBadgeMinted(_recipient, _badgeId, _amount);
    }

    /**
     * @summary Internal function to dynamically update the metadata URI of a researcher's ERC721 profile NFT.
     *          This is called whenever a researcher's reputation or achievements change,
     *          triggering an update to their public on-chain profile.
     * @param _researcher The address of the researcher whose NFT metadata should be updated.
     * @param _newURI The new URI for the researcher's NFT metadata (pointing to a dynamically updated JSON).
     */
    function _updateResearcherNFTMetadata(address _researcher, string memory _newURI) internal {
        uint256 researcherId = researcherToId[_researcher];
        if (researcherId != 0) {
            _setTokenURI(researcherId, _newURI); // Update ERC721 metadata URI
            // The actual metadata JSON file at _newURI would dynamically reflect the researcher's
            // current reputation, badges, active projects, etc., served by an off-chain API.
        }
    }

    /**
     * @summary View function to check the total funds contributed to a project.
     * @param _projectId The ID of the project.
     * @return The total ETH funded for the project.
     */
    function getTotalProjectFunds(uint256 _projectId) external view returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        return project.fundedAmount;
    }

    /**
     * @summary View function to get the current status of a research project.
     * @param _projectId The ID of the project.
     * @return The current status enum of the project.
     */
    function getProjectStatus(uint256 _projectId) external view returns (ProjectStatus) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DARV: Project does not exist");
        return project.status;
    }

    // --- ERC721 Overrides for Non-Transferability (ResearcherProfileNFT) ---
    // These functions make the ResearcherProfileNFTs non-transferable (Soulbound).
    // They prevent transfers after initial minting to the owner.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) { // Allow minting (from zero address)
            revert("DARV: ResearcherProfileNFTs are non-transferable");
        }
    }

    // --- ERC1155 Overrides for Non-Transferability (Reputation Badges) ---
    // These functions make the ERC1155 Reputation Badges non-transferable (Soulbound).
    function _beforeTokenTransfer(address operator, address from, address to, uint224[] memory ids, uint256[] memory amounts, bytes memory data) internal pure override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0) && to != address(0)) { // Allow minting (from zero address)
            revert("DARV: Reputation Badges are non-transferable");
        }
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Can accept direct ETH, but `fundProject` is the preferred method for project funding.
        // This acts as a catch-all for accidental transfers or general protocol donations.
    }

    /**
     * @summary Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner {
        require(totalProtocolFeesCollected > 0, "DARV: No fees to withdraw");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        payable(msg.sender).transfer(amount);
    }
}

```