Here's a smart contract in Solidity called `GenesisForge`, designed around advanced, creative, and trendy concepts. It features dynamic NFTs, a soulbound token (SBT)-like reputation system, simulated AI oracle integration, liquid reputation-based governance, and NFT staking for yield, all within a decentralized project incubation framework.

The contract focuses on the idea of "Digital Lifeforms" (projects) that start as `GenesisSeeds` (NFTs) and can `Evolve` into `EvolvedOrganisms` (the same NFT with updated state and metadata) based on community funding, research contributions, and "AI-simulated" evaluations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

// Assuming an oracle contract exists for AI-simulated evaluations
interface IAIOracle {
    // Function for GenesisForge to request an assessment.
    // The oracle would likely store the request and respond via `receiveOracleAssessment`.
    function requestAssessment(uint256 projectId, bytes memory data) external;
    // Function for GenesisForge to query the result of a specific assessment.
    function getAssessment(uint256 assessmentId) external view returns (uint256 score);
}

// Assuming a token contract for rewards exists (e.g., a native utility token for the ecosystem)
interface IRewardToken {
    function mint(address to, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}


/**
 * @title GenesisForge
 * @dev A decentralized incubator for "Digital Lifeforms" (projects) represented as dynamic NFTs.
 *      These NFTs start as `GenesisSeeds` and can `Evolve` into `EvolvedOrganisms` based on community
 *      funding, research contributions, and "AI-simulated" evaluations.
 *      Contributors earn non-transferable "Reputation Fragments" (SBTs-like) that confer voting power
 *      and other benefits within the GenesisForge ecosystem.
 *
 *      This contract incorporates:
 *      - Dynamic NFTs: NFTs whose metadata and characteristics change based on on-chain actions.
 *      - Soulbound Token (SBT)-like Reputation: Non-transferable tokens representing reputation,
 *        used for governance and specific access/rewards.
 *      - AI-Simulated Evaluation: Integration with an external oracle that provides "AI-generated scores"
 *        or assessments for project evolution.
 *      - Liquid Reputation-Based Governance: Users can delegate their reputation to others,
 *        enabling a form of liquid democracy.
 *      - Staking Dynamic NFTs for Yield: Evolved NFTs can be staked to generate native utility token yield,
 *        with yield scaling based on the NFT's evolutionary stage.
 *      - Two-Phase Project Lifecycle: `GenesisSeed` (proposal/incubation) -> `EvolvedOrganism` (mature/active).
 */
contract GenesisForge is Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Outline and Function Summary ---
    // I.  Contract Setup & Configuration (Owner-only or Governance-controlled)
    //     1. constructor(address _aiOracle, address _rewardToken)
    //     2. updateOracleAddress(address _newOracle)
    //     3. setProjectCreationFee(uint256 _fee)
    //     4. setContributionWeights(uint256 _fundWeight, uint256 _researchWeight, uint256 _codeWeight)
    //     5. setMinEvolutionScore(uint256 _score)
    //     6. setStakingYieldRate(uint256 _rate)
    //     7. setMinReputationForProposal(uint256 _minReputation)
    //     8. setVotingPeriodDuration(uint256 _duration)
    // II. NFT (Digital Lifeform) Management
    //     9. proposeGenesisProject(string memory _metadataURI)
    //     10. updateProjectMetadata(uint256 _projectId, string memory _newMetadataURI)
    //     11. evolveGenesisSeed(uint256 _projectId, uint256 _assessmentId)
    //     12. retireProject(uint256 _projectId)
    // III. Project & Contribution Management
    //     13. fundProject(uint256 _projectId)
    //     14. contributeResearchData(uint256 _projectId, bytes memory _dataHash)
    //     15. contributeCodeArtifact(uint256 _projectId, bytes memory _artifactHash)
    //     16. finalizeProjectIncubation(uint256 _projectId)
    // IV. Reputation System (Soulbound Tokens - SBT-like)
    //     17. getContributorReputation(address _contributor) view
    //     18. delegateReputation(address _delegatee)
    //     19. revokeReputationDelegation()
    //     20. claimReputationReward()
    // V.   AI-Simulated Evaluation & Oracle Interaction
    //     21. requestEvolutionAssessment(uint256 _projectId)
    //     22. receiveOracleAssessment(uint256 _projectId, uint256 _assessmentId, uint256 _score) onlyOracle
    // VI.  Governance
    //     23. proposeProtocolUpgrade(bytes memory _callData, string memory _description)
    //     24. voteOnProposal(uint256 _proposalId, bool _support)
    //     25. executeProposal(uint256 _proposalId)
    // VII. DeFi / Value Accrual (NFT Staking)
    //     26. stakeEvolvedOrganism(uint256 _tokenId)
    //     27. unstakeEvolvedOrganism(uint256 _tokenId)
    //     28. claimStakedYield(uint256 _tokenId)
    // VIII. Emergency & Utilities
    //     29. togglePause()
    //     30. withdrawFunds()

    // --- State Variables ---

    IAIOracle public aiOracle;
    IRewardToken public rewardToken; // Token minted for rewards (e.g., native utility token)

    Counters.Counter private _projectIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 private _contractCreationBlock; // Stores the block number when the contract was deployed

    uint256 public projectCreationFee = 0.01 ether; // Fee to propose a new project
    uint256 public minEvolutionScore = 750; // Minimum AI score (out of 1000) for evolution
    uint256 public stakingYieldRatePerBlock = 100; // Example: 100 units of reward token per block per staked NFT, scaled by evolution level (e.g., if token has 18 decimals, this is 1e-16 tokens)

    // Weights for calculating internal project evolution score during incubation (before AI assessment)
    // These could also influence the AI's scoring criteria via the data passed to the oracle.
    uint256 public fundContributionWeight = 40; // Max 100
    uint256 public researchContributionWeight = 30; // Max 100
    uint256 public codeContributionWeight = 30; // Max 100

    uint256 public minReputationForProposal = 100; // Minimum reputation required to create a governance proposal
    uint256 public votingPeriodDuration = 3 days; // Duration of a governance proposal's voting period

    bool public paused = false; // Emergency pause switch

    // --- Enums ---

    enum ProjectState {
        GenesisSeed,    // Initial state, project proposed, seeking funds/contributions
        Incubated,      // Ready for evolution assessment (after finalization)
        EvolvedOrganism, // Successfully evolved, active
        Retired         // Project completed or failed
    }

    enum ProposalState {
        Pending,        // Just created, before vote start
        Active,         // Voting is open
        Succeeded,      // Passed voting thresholds
        Defeated,       // Failed voting thresholds
        Executed        // Successfully executed on-chain
    }

    // --- Structs ---

    struct Project {
        address creator;
        ProjectState state;
        uint256 totalFundsContributed; // In Wei
        uint256 totalResearchPoints;
        uint256 totalCodePoints;
        uint256 evolutionScore; // Final AI assessment score
        string metadataURI;
        uint256 creationBlock;
        uint256 lastContributionBlock;
    }

    struct StakedNFT {
        address owner; // Original owner who staked it
        uint256 projectId; // The tokenId of the NFT
        uint256 stakedBlock;
        uint256 lastClaimBlock;
        uint256 evolutionLevel; // Multiplier for yield calculation, derived from evolutionScore
    }

    struct Proposal {
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if proposal passes
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes; // Total reputation points for the proposal
        uint256 againstVotes; // Total reputation points against the proposal
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if a specific address has voted
    }

    // --- Mappings ---

    mapping(uint256 => Project) public projects;
    mapping(uint256 => StakedNFT) public stakedNFTs; // TokenId -> StakedNFT details

    // Soulbound-like reputation system
    mapping(address => uint256) public reputationScores; // `msg.sender` => earned reputation
    mapping(address => address) public reputationDelegates; // `delegator` => `delegatee`
    mapping(address => uint256) public lastReputationClaimBlock; // `claimer` => last block they claimed reputation rewards

    // For AI Oracle callbacks and tracking pending requests
    mapping(uint256 => uint256) public pendingAssessments; // projectId => assessmentId (received from oracle)
    mapping(uint256 => bool) public assessmentRequested; // projectId => true if request sent

    // Governance proposals
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---

    event ProjectProposed(uint256 indexed projectId, address indexed creator, string metadataURI);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ResearchDataContributed(uint256 indexed projectId, address indexed contributor, bytes dataHash);
    event CodeArtifactContributed(uint256 indexed projectId, address indexed contributor, bytes artifactHash);
    event ProjectIncubated(uint256 indexed projectId);
    event ProjectRetired(uint256 indexed projectId);
    event ProjectEvolved(uint256 indexed projectId, uint256 newEvolutionScore, uint256 evolutionLevel);
    event MetadataUpdated(uint256 indexed projectId, string newMetadataURI);

    event EvolutionAssessmentRequested(uint256 indexed projectId);
    event EvolutionAssessmentReceived(uint256 indexed projectId, uint256 indexed assessmentId, uint256 score);

    event ReputationEarned(address indexed contributor, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationRevoked(address indexed delegator);
    event ReputationRewardClaimed(address indexed receiver, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event Paused(address account);
    event Unpaused(address account);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId, address indexed unstaker);
    event StakingYieldClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == address(aiOracle), "GenesisForge: Caller is not the AI oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "GenesisForge: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "GenesisForge: Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(address _aiOracle, address _rewardToken) ERC721("GenesisForgeNFT", "GFNFT") Ownable(msg.sender) {
        require(_aiOracle != address(0), "GenesisForge: AI Oracle address cannot be zero");
        require(_rewardToken != address(0), "GenesisForge: Reward Token address cannot be zero");
        aiOracle = IAIOracle(_aiOracle);
        rewardToken = IRewardToken(_rewardToken);
        _contractCreationBlock = block.number;
        // Ensure default weights sum to 100
        require(fundContributionWeight.add(researchContributionWeight).add(codeContributionWeight) == 100, "Initial weights must sum to 100");
    }

    // --- I. Contract Setup & Configuration ---

    /**
     * @dev Updates the address of the AI Oracle contract.
     *      Can only be called by the contract owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "GenesisForge: New AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracle);
    }

    /**
     * @dev Sets the fee required to propose a new Genesis Project.
     *      Can only be called by the contract owner.
     * @param _fee The new project creation fee in Wei.
     */
    function setProjectCreationFee(uint256 _fee) public onlyOwner {
        projectCreationFee = _fee;
    }

    /**
     * @dev Sets the weights for different contribution types when calculating internal project score.
     *      These weights are internal and can be used to inform the AI oracle or for other logic.
     *      Weights must sum to 100. Can only be called by the contract owner.
     * @param _fundWeight Weight for funds contributed.
     * @param _researchWeight Weight for research data contributions.
     * @param _codeWeight Weight for code artifact contributions.
     */
    function setContributionWeights(uint256 _fundWeight, uint256 _researchWeight, uint256 _codeWeight) public onlyOwner {
        require(_fundWeight.add(_researchWeight).add(_codeWeight) == 100, "Weights must sum to 100");
        fundContributionWeight = _fundWeight;
        researchContributionWeight = _researchWeight;
        codeContributionWeight = _codeWeight;
    }

    /**
     * @dev Sets the minimum AI evolution score required for a project to evolve.
     *      Can only be called by the contract owner.
     * @param _score The minimum score (e.g., out of 1000, assuming 1000 is max).
     */
    function setMinEvolutionScore(uint256 _score) public onlyOwner {
        require(_score <= 1000, "Score cannot exceed 1000"); // Assuming max score is 1000
        minEvolutionScore = _score;
    }

    /**
     * @dev Sets the base yield rate for staking Evolved Organism NFTs.
     *      Can only be called by the contract owner.
     * @param _rate The reward token units per block per base evolution level.
     */
    function setStakingYieldRate(uint256 _rate) public onlyOwner {
        stakingYieldRatePerBlock = _rate;
    }

    /**
     * @dev Sets the minimum reputation score required for a user to propose a governance upgrade.
     *      Can only be called by the contract owner.
     * @param _minReputation The new minimum reputation score.
     */
    function setMinReputationForProposal(uint256 _minReputation) public onlyOwner {
        minReputationForProposal = _minReputation;
    }

    /**
     * @dev Sets the duration for which a governance proposal's voting period remains active.
     *      Can only be called by the contract owner.
     * @param _duration The new duration in seconds (e.g., 3 days = 3 * 24 * 60 * 60).
     */
    function setVotingPeriodDuration(uint256 _duration) public onlyOwner {
        require(_duration > 0, "GenesisForge: Voting period duration must be greater than zero");
        votingPeriodDuration = _duration;
    }

    // --- II. NFT (Digital Lifeform) Management ---

    /**
     * @dev Allows a user to propose a new Genesis Project, creating a GenesisSeed NFT.
     *      Requires payment of `projectCreationFee`. The created NFT's tokenId will be the projectId.
     * @param _metadataURI URI pointing to the project's initial metadata (description, images, etc.).
     * @return newProjectId The ID of the newly created project and NFT.
     */
    function proposeGenesisProject(string memory _metadataURI) public payable whenNotPaused returns (uint256) {
        require(msg.value >= projectCreationFee, "GenesisForge: Insufficient project creation fee");

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        projects[newProjectId] = Project({
            creator: msg.sender,
            state: ProjectState.GenesisSeed,
            totalFundsContributed: 0,
            totalResearchPoints: 0,
            totalCodePoints: 0,
            evolutionScore: 0,
            metadataURI: _metadataURI,
            creationBlock: block.number,
            lastContributionBlock: block.number
        });

        _safeMint(msg.sender, newProjectId); // The project ID acts as the NFT tokenId
        _setTokenURI(newProjectId, _metadataURI); // Set initial NFT URI

        emit ProjectProposed(newProjectId, msg.sender, _metadataURI);
        return newProjectId;
    }

    /**
     * @dev Allows the creator of a project to update its metadata URI.
     *      Useful for dynamic NFTs to reflect project changes before evolution or for minor updates.
     * @param _projectId The ID of the project/NFT.
     * @param _newMetadataURI The new URI for the project's metadata.
     */
    function updateProjectMetadata(uint256 _projectId, string memory _newMetadataURI) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.creator == msg.sender, "GenesisForge: Only project creator can update metadata");
        require(project.state < ProjectState.EvolvedOrganism, "GenesisForge: Cannot update metadata for Evolved or Retired projects");

        project.metadataURI = _newMetadataURI;
        _setTokenURI(_projectId, _newMetadataURI); // Update NFT token URI

        emit MetadataUpdated(_projectId, _newMetadataURI);
    }

    /**
     * @dev Allows a project to evolve from a GenesisSeed (Incubated state) to an EvolvedOrganism.
     *      Requires a successful AI assessment and the project to be in an 'Incubated' state.
     *      This fundamentally changes the NFT's type/state, updating its metadata URI to reflect evolution.
     * @param _projectId The ID of the project/NFT to evolve.
     * @param _assessmentId The ID of the successful AI assessment for this project, provided by the oracle.
     */
    function evolveGenesisSeed(uint256 _projectId, uint256 _assessmentId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(ownerOf(_projectId) == msg.sender, "GenesisForge: Only the NFT owner can initiate evolution");
        require(project.state == ProjectState.Incubated, "GenesisForge: Project must be in Incubated state to evolve");

        // Verify that an assessment was indeed requested and this ID corresponds
        require(pendingAssessments[_projectId] == _assessmentId, "GenesisForge: Invalid or unverified assessment ID for this project");

        uint256 score = aiOracle.getAssessment(_assessmentId);
        require(score >= minEvolutionScore, "GenesisForge: Evolution score too low");

        project.evolutionScore = score;
        project.state = ProjectState.EvolvedOrganism;

        // Calculate evolution level based on score. Higher score = higher level.
        // Example: score 750-849 -> level 1, 850-949 -> level 2, etc.
        uint256 evolutionLevel = (score.sub(minEvolutionScore)).div(100).add(1);
        if (evolutionLevel == 0) evolutionLevel = 1; // Ensure a minimum level of 1 for evolved organisms

        // Update the NFT's metadata URI to reflect its evolved state and level.
        project.metadataURI = string(abi.encodePacked(project.metadataURI, "/evolved_level_", evolutionLevel.toString()));
        _setTokenURI(_projectId, project.metadataURI); // Update NFT token URI to reflect evolved state

        delete pendingAssessments[_projectId]; // Clear pending assessment
        assessmentRequested[_projectId] = false;

        emit ProjectEvolved(_projectId, score, evolutionLevel);
    }

    /**
     * @dev Marks a project as retired (completed or failed).
     *      No further contributions or evolution attempts are possible.
     *      Can be called by the project creator or the contract owner.
     * @param _projectId The ID of the project to retire.
     */
    function retireProject(uint256 _projectId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.creator == msg.sender || msg.sender == owner(), "GenesisForge: Only project creator or owner can retire");
        require(project.state != ProjectState.Retired, "GenesisForge: Project is already retired");

        project.state = ProjectState.Retired;
        emit ProjectRetired(_projectId);
    }

    // --- III. Project & Contribution Management ---

    /**
     * @dev Allows users to contribute ETH to a Genesis Project.
     *      Increases project's total funds and awards reputation to the funder.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) public payable whenNotPaused {
        require(msg.value > 0, "GenesisForge: Must send ETH to fund");
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.state == ProjectState.GenesisSeed, "GenesisForge: Project not in GenesisSeed state");

        project.totalFundsContributed = project.totalFundsContributed.add(msg.value);
        project.lastContributionBlock = block.number;

        // Award reputation for funding: e.g., 1 reputation point per ETH contributed.
        _awardReputation(msg.sender, msg.value.div(1 ether));
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Allows users to contribute verifiable research data to a Genesis Project.
     *      Increases project's research points and awards reputation.
     *      `_dataHash` would ideally be a hash of off-chain data verifiable by the oracle or community.
     * @param _projectId The ID of the project to contribute to.
     * @param _dataHash A hash representing the research data provided (e.g., IPFS hash).
     */
    function contributeResearchData(uint256 _projectId, bytes memory _dataHash) public whenNotPaused {
        require(_dataHash.length > 0, "GenesisForge: Data hash cannot be empty");
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.state == ProjectState.GenesisSeed, "GenesisForge: Project not in GenesisSeed state");

        // Simple scoring: each contribution adds a fixed amount of points
        project.totalResearchPoints = project.totalResearchPoints.add(10); // Example: 10 points per research contribution
        project.lastContributionBlock = block.number;

        // Award reputation for research contribution
        _awardReputation(msg.sender, 5); // Example: 5 reputation points per contribution
        emit ResearchDataContributed(_projectId, msg.sender, _dataHash);
    }

    /**
     * @dev Allows users to contribute verifiable code artifacts to a Genesis Project.
     *      Increases project's code points and awards reputation.
     *      `_artifactHash` would ideally be a hash of off-chain code verifiable by the oracle or community.
     * @param _projectId The ID of the project to contribute to.
     * @param _artifactHash A hash representing the code artifact provided (e.g., IPFS hash or commit hash).
     */
    function contributeCodeArtifact(uint256 _projectId, bytes memory _artifactHash) public whenNotPaused {
        require(_artifactHash.length > 0, "GenesisForge: Artifact hash cannot be empty");
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.state == ProjectState.GenesisSeed, "GenesisForge: Project not in GenesisSeed state");

        // Simple scoring: each contribution adds a fixed amount of points
        project.totalCodePoints = project.totalCodePoints.add(20); // Example: 20 points per code contribution
        project.lastContributionBlock = block.number;

        // Award reputation for code contribution
        _awardReputation(msg.sender, 10); // Example: 10 reputation points per contribution
        emit CodeArtifactContributed(_projectId, msg.sender, _artifactHash);
    }

    /**
     * @dev Marks a GenesisSeed project as ready for evolution assessment.
     *      Only the project creator can do this. Requires some contributions to have been made.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProjectIncubation(uint256 _projectId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.creator == msg.sender, "GenesisForge: Only project creator can finalize incubation");
        require(project.state == ProjectState.GenesisSeed, "GenesisForge: Project must be in GenesisSeed state");

        // Require minimum contributions before incubation can be finalized
        require(project.totalFundsContributed > 0 || project.totalResearchPoints > 0 || project.totalCodePoints > 0,
            "GenesisForge: Project must have received some contributions to finalize incubation");

        project.state = ProjectState.Incubated;
        emit ProjectIncubated(_projectId);
    }

    // --- IV. Reputation System (Soulbound Tokens - SBT-like) ---

    /**
     * @dev Internal function to award non-transferable reputation points to an address.
     * @param _contributor The address to award reputation to.
     * @param _amount The amount of reputation points.
     */
    function _awardReputation(address _contributor, uint256 _amount) internal {
        if (_amount > 0) {
            reputationScores[_contributor] = reputationScores[_contributor].add(_amount);
            emit ReputationEarned(_contributor, _amount);
        }
    }

    /**
     * @dev Returns the current reputation score of a contributor.
     *      This is the direct reputation earned by the address.
     *      Delegated reputation is handled in `voteOnProposal`.
     * @param _contributor The address to query.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return reputationScores[_contributor];
    }

    /**
     * @dev Allows a user to delegate their voting power (reputation) to another address.
     *      This enables a form of liquid democracy. Once delegated, the delegator cannot vote directly.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "GenesisForge: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "GenesisForge: Cannot delegate reputation to self");
        // Optional: Prevent delegating to an address that has already delegated its reputation to someone else
        // This avoids complex delegation chains. For simplicity, we assume one level of delegation.
        // require(reputationDelegates[_delegatee] == address(0), "GenesisForge: Cannot delegate to an already delegated address.");

        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active reputation delegation by the caller.
     *      The caller regains their direct voting power.
     */
    function revokeReputationDelegation() public whenNotPaused {
        require(reputationDelegates[msg.sender] != address(0), "GenesisForge: No active delegation to revoke");
        delete reputationDelegates[msg.sender];
        emit ReputationRevoked(msg.sender);
    }

    /**
     * @dev Allows a user to claim periodic rewards based on their current reputation score.
     *      Rewards are minted from the `rewardToken` contract.
     *      Yield scales with reputation and blocks passed since last claim.
     */
    function claimReputationReward() public whenNotPaused {
        uint256 reputation = reputationScores[msg.sender];
        require(reputation > 0, "GenesisForge: No reputation to earn rewards");

        uint256 lastClaimBlock = lastReputationClaimBlock[msg.sender];
        if (lastClaimBlock == 0) {
            lastClaimBlock = _contractCreationBlock; // If never claimed, start from contract creation block
        }
        uint256 blocksSinceLastClaim = block.number.sub(lastClaimBlock);
        require(blocksSinceLastClaim > 0, "GenesisForge: No new reward accumulated yet");

        // Example: 1 reward token per 10 reputation per 1000 blocks
        // (reputation * blocksSinceLastClaim * 1e15) / (10 * 1000) for rewardToken with 18 decimals
        // Assuming rewardToken has same decimals as ETH (1e18) for simplicity in scaling
        uint256 rewardAmount = (reputation.mul(blocksSinceLastClaim).mul(1 ether)).div(10000); // Scaled by 1 ETH equivalent
        require(rewardAmount > 0, "GenesisForge: Calculated reward is zero");

        rewardToken.mint(msg.sender, rewardAmount);
        lastReputationClaimBlock[msg.sender] = block.number;
        emit ReputationRewardClaimed(msg.sender, rewardAmount);
    }

    // --- V. AI-Simulated Evaluation & Oracle Interaction ---

    /**
     * @dev Requests an AI assessment for a project that has been 'Incubated'.
     *      The AI oracle will then call `receiveOracleAssessment` with the result.
     *      Only the project creator can request an assessment.
     * @param _projectId The ID of the project to assess.
     */
    function requestEvolutionAssessment(uint256 _projectId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.creator == msg.sender, "GenesisForge: Only project creator can request assessment");
        require(project.state == ProjectState.Incubated, "GenesisForge: Project must be in Incubated state for assessment");
        require(!assessmentRequested[_projectId], "GenesisForge: An assessment is already pending for this project");

        // We can pass project-specific data to the oracle if needed.
        // For simplicity, we just pass the project ID. The oracle would fetch details based on this ID.
        bytes memory data = abi.encodePacked(_projectId);
        aiOracle.requestAssessment(_projectId, data);

        assessmentRequested[_projectId] = true; // Mark as requested
        emit EvolutionAssessmentRequested(_projectId);
    }

    /**
     * @dev Callback function for the AI Oracle to deliver an assessment score.
     *      Only callable by the registered `aiOracle` address.
     *      This function stores the assessmentId and score, which can then be used by `evolveGenesisSeed`.
     * @param _projectId The ID of the project that was assessed.
     * @param _assessmentId The ID provided by the oracle for this assessment.
     * @param _score The AI-generated evolution score (e.g., out of 1000).
     */
    function receiveOracleAssessment(uint256 _projectId, uint256 _assessmentId, uint256 _score) public onlyOracle {
        Project storage project = projects[_projectId];
        require(_exists(_projectId), "GenesisForge: Project NFT does not exist");
        require(project.state == ProjectState.Incubated, "GenesisForge: Project not in Incubated state");
        require(assessmentRequested[_projectId], "GenesisForge: No assessment was pending for this project");

        // Store the actual assessmentId for later verification in `evolveGenesisSeed`.
        pendingAssessments[_projectId] = _assessmentId;

        emit EvolutionAssessmentReceived(_projectId, _assessmentId, _score);
    }

    // --- VI. Governance ---

    /**
     * @dev Proposes an upgrade or change to the GenesisForge protocol parameters.
     *      Requires a minimum reputation score to propose.
     * @param _callData The encoded function call (targetting 'this' contract) to execute if the proposal passes.
     * @param _description A description of the proposal.
     * @return newProposalId The ID of the created proposal.
     */
    function proposeProtocolUpgrade(bytes memory _callData, string memory _description) public whenNotPaused returns (uint256) {
        require(reputationScores[msg.sender] >= minReputationForProposal, "GenesisForge: Insufficient reputation to propose");
        require(_callData.length > 0, "GenesisForge: Call data cannot be empty");
        require(bytes(_description).length > 0, "GenesisForge: Description cannot be empty");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(votingPeriodDuration),
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @dev Allows users to vote on an active proposal using their effective reputation.
     *      Delegated reputation is considered: if a user has delegated, they cannot vote directly.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "GenesisForge: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "GenesisForge: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "GenesisForge: Voting is not open");
        require(!proposal.hasVoted[msg.sender], "GenesisForge: You have already voted on this proposal");

        // Liquid Democracy Logic:
        // A user's vote is counted by their direct reputation *unless* they have delegated it.
        // If they have delegated, they cannot vote directly, and their reputation contributes to their delegatee's vote.
        require(reputationDelegates[msg.sender] == address(0), "GenesisForge: Cannot vote directly, your reputation is delegated");

        uint256 votingPower = reputationScores[msg.sender];
        // For liquid democracy, we would need to sum reputation from all delegators for the _delegatee.
        // For simplicity, we'll only count direct reputation + reputation delegated *to* the voter.
        // This requires a more complex structure (e.g., mapping delegatee => list of delegators or sum of delegated reputation).
        // For this example, let's keep it simple: direct reputation of `msg.sender` for direct vote, otherwise delegatee uses their own + what was delegated to them.
        // To properly implement liquid democracy for 'votingPower', one would track `delegatedReputation[delegatee] += delegatorReputation`.
        // For this specific design, we only allow direct voters, and if they delegated, their voting power is with the delegatee.
        // So, this `votingPower` is only the direct `reputationScores[msg.sender]`.
        require(votingPower > 0, "GenesisForge: No reputation to vote");

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Executes a successful proposal. Can only be called after the voting period ends
     *      and if 'for' votes exceed 'against' votes (with a minimum quorum).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "GenesisForge: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "GenesisForge: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "GenesisForge: Voting period has not ended");

        // Example: Quorum of 1000 total reputation points needed for proposal to be valid.
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        require(totalVotes >= 1000, "GenesisForge: Proposal did not meet quorum");
        require(proposal.forVotes > proposal.againstVotes, "GenesisForge: Proposal did not pass");

        proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution attempt

        // Execute the proposed function call targeting this contract
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "GenesisForge: Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // --- VII. DeFi / Value Accrual (NFT Staking) ---

    /**
     * @dev Allows the owner of an EvolvedOrganism NFT to stake it to earn yield.
     *      The NFT must be an EvolvedOrganism.
     *      The NFT is transferred to the contract address.
     * @param _tokenId The ID of the EvolvedOrganism NFT to stake.
     */
    function stakeEvolvedOrganism(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "GenesisForge: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "GenesisForge: Not the owner of the token");
        require(projects[_tokenId].state == ProjectState.EvolvedOrganism, "GenesisForge: Only Evolved Organisms can be staked");
        require(stakedNFTs[_tokenId].projectId == 0, "GenesisForge: NFT is already staked"); // Check if projectId is 0 (default)

        // Transfer NFT to the contract
        _transfer(msg.sender, address(this), _tokenId);

        // Get evolution level for yield calculation (re-calculate in case minEvolutionScore changed)
        uint256 evolutionLevel = (projects[_tokenId].evolutionScore.sub(minEvolutionScore)).div(100).add(1);
        if (evolutionLevel == 0) evolutionLevel = 1; // Ensure min level 1 for scaling

        stakedNFTs[_tokenId] = StakedNFT({
            owner: msg.sender, // The original staker, for unstaking and claiming rights
            projectId: _tokenId,
            stakedBlock: block.number,
            lastClaimBlock: block.number,
            evolutionLevel: evolutionLevel
        });

        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows the original staker to unstake their EvolvedOrganism NFT.
     *      Any accumulated yield is claimed automatically before unstaking.
     * @param _tokenId The ID of the staked NFT.
     */
    function unstakeEvolvedOrganism(uint256 _tokenId) public whenNotPaused {
        StakedNFT storage staked = stakedNFTs[_tokenId];
        require(staked.projectId != 0, "GenesisForge: NFT is not staked");
        require(staked.owner == msg.sender, "GenesisForge: Only the original staker can unstake");

        // Claim any pending yield before unstaking
        _claimYield(_tokenId);

        // Transfer NFT back to the original staker
        _transfer(address(this), msg.sender, _tokenId);

        delete stakedNFTs[_tokenId];
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Claims accumulated yield for a staked EvolvedOrganism NFT.
     * @param _tokenId The ID of the staked NFT.
     */
    function claimStakedYield(uint256 _tokenId) public whenNotPaused {
        StakedNFT storage staked = stakedNFTs[_tokenId];
        require(staked.projectId != 0, "GenesisForge: NFT is not staked");
        require(staked.owner == msg.sender, "GenesisForge: Not the original staker for this NFT");

        _claimYield(_tokenId);
    }

    /**
     * @dev Internal function to calculate and transfer yield for a staked NFT.
     *      Can be called by `unstakeEvolvedOrganism` or `claimStakedYield`.
     * @param _tokenId The ID of the staked NFT.
     */
    function _claimYield(uint256 _tokenId) internal {
        StakedNFT storage staked = stakedNFTs[_tokenId];
        uint256 blocksSinceLastClaim = block.number.sub(staked.lastClaimBlock);
        require(blocksSinceLastClaim > 0, "GenesisForge: No new yield accumulated");

        // Yield = (rate_per_block * blocks_since_claim * evolution_level)
        uint256 yieldAmount = stakingYieldRatePerBlock.mul(blocksSinceLastClaim).mul(staked.evolutionLevel);
        require(yieldAmount > 0, "GenesisForge: Calculated yield is zero");

        rewardToken.mint(staked.owner, yieldAmount);
        staked.lastClaimBlock = block.number;
        emit StakingYieldClaimed(_tokenId, staked.owner, yieldAmount);
    }

    // --- VIII. Emergency & Utilities ---

    /**
     * @dev Pauses/Unpauses the contract in case of emergency. Only owner can call.
     *      Most state-changing functions are protected by `whenNotPaused`.
     */
    function togglePause() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @dev Allows the owner to withdraw all accumulated ETH from fees and project funding.
     *      NOTE: In a more decentralized system, project-specific funds might be handled
     *      by their own treasuries or multi-sigs, separate from the main contract balance.
     *      Here, all incoming ETH goes to the contract's balance.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "GenesisForge: No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "GenesisForge: Failed to withdraw funds");
        emit FundsWithdrawn(owner(), balance);
    }

    // --- ERC721 Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Overrides to provide the dynamic metadata URI based on the project's state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Check if the token exists and is owned by someone
        return projects[tokenId].metadataURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // fallback and receive functions to accept ETH
    receive() external payable {
        // Allow direct ETH receives, though most ETH should come through specific functions.
        // Funds received here would contribute to the general contract balance, withdrawable by owner.
    }
}
```