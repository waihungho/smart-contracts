Okay, this is an exciting challenge! We'll create a smart contract that blends several advanced, trendy, and somewhat experimental concepts:

1.  **Decentralized AI-Driven Research & Development (DeSci x AI):** Funding scientific research projects where progress and outcomes are influenced by external AI analysis.
2.  **Dynamic NFTs (dNFTs):** NFTs that represent funded research projects and evolve based on their progress, AI scores, and community evaluation.
3.  **Predictive Governance (DAO 2.0):** A governance model where voters not only cast votes but also make predictions about the outcome or success of proposals, leading to enhanced reputation or rewards for accurate predictions.
4.  **Reputation & Impact Scoring:** A system that tracks the success rate of researchers and the accuracy of voters' predictions.
5.  **Staking for Influence & Rewards:** Standard staking but tied into predictive governance and research funding.

---

## Contract Outline & Function Summary: "AetherNexus"

**Contract Name:** `AetherNexus`

**Purpose:** A decentralized platform for funding, managing, and evaluating cutting-edge research and development projects. It leverages AI oracles for external analysis, dynamic NFTs to represent project progress and ownership, and a novel predictive governance model for community decision-making and incentivized accuracy.

**Core Concepts:**
*   **Aether Token (AETH):** An ERC-20 utility and governance token.
*   **Research Asset NFTs (R-NFTs):** ERC-721 tokens representing funded research projects, with metadata that dynamically updates based on project milestones, AI analysis, and community evaluation.
*   **AI Oracle Integration:** A mechanism for requesting and receiving external AI analysis results (simulated callback for this contract).
*   **Predictive Governance:** A DAO where voters stake `AETH` and make predictions on proposal outcomes, earning reputation and potential rewards for accuracy.
*   **Researcher Profiles:** Tracks reputation and success metrics for project leads.

---

### Function Summary:

**I. ERC-20 Aether Token (`AETH`) Functions:**
1.  `constructor()`: Initializes the contract, token, and minter role.
2.  `transfer(address recipient, uint256 amount)`: Transfers `AETH` tokens.
3.  `approve(address spender, uint256 amount)`: Allows a spender to withdraw a set amount of `AETH`.
4.  `transferFrom(address sender, address recipient, uint256 amount)`: Transfers `AETH` from one address to another on behalf of a spender.
5.  `balanceOf(address account)`: Returns the `AETH` balance of an account.
6.  `allowance(address owner, address spender)`: Returns the remaining amount of `AETH` that `spender` is allowed to spend on behalf of `owner`.
7.  `totalSupply()`: Returns the total supply of `AETH` tokens.
8.  `mint(address to, uint256 amount)`: Mints new `AETH` tokens (restricted to owner/minter role).
9.  `burn(uint256 amount)`: Burns `AETH` tokens from the caller's balance.

**II. Research Project Management Functions:**
10. `submitResearchProposal(string memory _title, string memory _descriptionURI, uint256 _requiredFunding)`: Submits a new research project proposal.
11. `fundResearchProposal(bytes32 _projectId, uint256 _amount)`: Funds an existing research project.
12. `updateResearchProgress(bytes32 _projectId, string memory _newProgressURI)`: Allows the researcher to update the project's progress.
13. `requestAIAnalysis(bytes32 _projectId, string memory _dataToAnalyzeURI)`: Triggers a request for external AI analysis on a project.
14. `receiveAIAnalysisResult(bytes32 _projectId, uint256 _aiScore, string memory _analysisURI)`: Callback function for the AI oracle to deliver results, updating R-NFT metadata. (Requires `onlyAIOracle` modifier).
15. `evaluateResearchOutcome(bytes32 _projectId, uint256 _outcomeScore)`: Community/DAO evaluates the final outcome of a project, influencing rewards and R-NFT state.
16. `distributeResearchRewards(bytes32 _projectId)`: Distributes `AETH` rewards to the researcher and funders based on project success.

**III. Dynamic Research Asset NFT (R-NFT) Functions:**
17. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a specific R-NFT, reflecting its current state.
18. `getProjectNFTId(bytes32 _projectId)`: Returns the R-NFT ID associated with a research project.

**IV. Predictive Governance Functions:**
19. `createGovernanceProposal(string memory _title, string memory _descriptionURI, bytes32 _targetProject, uint256 _duration)`: Creates a new governance proposal (e.g., funding, project approval, rule change).
20. `predictiveVote(bytes32 _proposalId, bool _support, uint256 _predictionOutcome, uint256 _stakeAmount)`: Allows a user to vote on a proposal, stake `AETH`, and provide a prediction about the proposal's outcome (e.g., a success probability, or a specific value).
21. `executeProposal(bytes32 _proposalId)`: Executes the proposal if it has passed and its duration has ended.
22. `claimPredictiveRewards(bytes32 _proposalId)`: Allows voters to claim rewards based on their predictive accuracy after a proposal is executed/resolved.

**V. Staking & Reputation Functions:**
23. `stakeAETH(uint256 _amount)`: Stakes `AETH` tokens for governance power and potential rewards.
24. `unstakeAETH(uint256 _amount)`: Unstakes `AETH` tokens.
25. `claimStakingRewards()`: Claims accumulated staking rewards.
26. `getResearcherReputation(address _researcher)`: Returns the aggregated reputation score of a researcher.
27. `getVoterPredictionAccuracy(address _voter)`: Returns the average prediction accuracy score of a voter.

**VI. Admin & Utility Functions:**
28. `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI oracle (restricted to owner).
29. `addResearcherRole(address _researcher)`: Grants a user the `RESEARCHER_ROLE`.
30. `revokeResearcherRole(address _researcher)`: Revokes the `RESEARCHER_ROLE`.

---

### Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety

// Custom Errors for cleaner reverts
error AetherNexus__InvalidAmount();
error AetherNexus__ProjectNotFound();
error AetherNexus__ProjectNotInFundedState();
error AetherNexus__ProjectNotInProgress();
error AetherNexus__ProjectNotAnalyzed();
error AetherNexus__ProjectNotEvaluated();
error AetherNexus__AlreadyFunded();
error AetherNexus__NotEnoughFunds();
error AetherNexus__Unauthorized();
error AetherNexus__ProposalNotFound();
error AetherNexus__ProposalNotActive();
error AetherNexus__ProposalEnded();
error AetherNexus__AlreadyVoted();
error AetherNexus__InsufficientStake();
error AetherNexus__NoStakedTokens();
error AetherNexus__NoRewardsToClaim();
error AetherNexus__AIOracleNotSet();
error AetherNexus__ResearchNFTNotMinted();
error AetherNexus__ProjectAlreadyComplete();


// Interface for the (simulated) AI Oracle
interface IAIOracle {
    // This function would typically be called by the Oracle itself or a keeper
    // after an off-chain AI analysis. For this demo, it's called internally
    // or by a trusted address.
    function deliverAnalysis(bytes32 projectId, uint256 aiScore, string calldata analysisURI) external;
}

contract AetherNexus is ERC20, ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Roles
    bytes32 public constant RESEARCHER_ROLE = keccak256("RESEARCHER_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");

    // Address of the trusted AI Oracle contract (can be updated by owner)
    address public aiOracleAddress;

    // Project States
    enum ProjectState { Proposed, Funded, InProgress, AI_Analyzed, Evaluated, Completed, Failed }

    struct ResearchProject {
        address researcher;
        string title;
        string descriptionURI; // IPFS hash or URL for detailed description
        uint256 requiredFunding;
        uint256 raisedFunding;
        ProjectState state;
        uint256 submittedAt;
        string progressURI; // IPFS hash or URL for progress updates
        uint256 aiScore; // AI's assessment (0-100)
        string aiAnalysisURI; // IPFS hash or URL for AI's detailed analysis
        uint256 outcomeScore; // Community/DAO's final evaluation (0-100)
        uint256 nftId; // Associated R-NFT ID
        bool rewardsClaimed;
    }

    // Mapping of project ID (bytes32 hash of title+researcher+timestamp) to ResearchProject struct
    mapping(bytes32 => ResearchProject) public researchProjects;
    mapping(uint256 => bytes32) public nftIdToProjectId; // Mapping from R-NFT ID to Project ID

    // R-NFT base URI (for dynamic metadata)
    string private _baseTokenURI;

    // Governance Proposal States
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        string title;
        string descriptionURI; // IPFS hash for detailed proposal
        bytes32 targetProject; // Optional: if the proposal targets a specific project
        uint256 proposalId;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 totalPredictiveStake; // Total AETH staked in predictions
        ProposalState state;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteSupport; // true for for, false for against
        mapping(address => uint256) voterPrediction; // Voter's prediction (e.g., 0-100 score)
        mapping(address => uint256) voterStake; // AETH staked for this prediction
        bool outcomeResolved; // Whether the actual outcome has been determined for predictive accuracy
        uint256 actualOutcome; // The actual outcome value (e.g., 0-100)
    }

    Counters.Counter private _proposalIds;
    mapping(bytes32 => GovernanceProposal) public governanceProposals; // Mapping of proposal hash to struct
    mapping(uint256 => bytes32) public proposalIdToHash; // Map _proposalIds.current() to its hash

    // Staking
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakingRewards; // Accumulated rewards

    // Reputation
    mapping(address => uint256) public researcherReputation; // Aggregated success score for researchers
    mapping(address => uint256) public voterPredictionAccuracySum; // Sum of accurate predictions
    mapping(address => uint256) public voterPredictionCount; // Count of predictions made

    // --- Events ---
    event ResearchProposalSubmitted(bytes32 indexed projectId, address indexed researcher, string title, uint256 requiredFunding);
    event ResearchProjectFunded(bytes32 indexed projectId, address indexed funder, uint256 amount, uint256 currentFunding);
    event ResearchProgressUpdated(bytes32 indexed projectId, string newProgressURI);
    event AIAnalysisRequested(bytes32 indexed projectId, string dataToAnalyzeURI);
    event AIAnalysisReceived(bytes32 indexed projectId, uint256 aiScore, string analysisURI);
    event ResearchOutcomeEvaluated(bytes32 indexed projectId, uint256 outcomeScore);
    event ResearchRewardsDistributed(bytes32 indexed projectId, address indexed researcher, uint256 researcherReward, uint256 totalFunderRewards);
    event ResearchAssetNFTMinted(bytes32 indexed projectId, uint256 indexed nftId, address indexed owner);
    event ResearchAssetNFTMetadataUpdated(uint256 indexed nftId, string newURI);

    event GovernanceProposalCreated(bytes32 indexed proposalHash, uint256 indexed proposalId, string title, uint256 votingEndTime);
    event PredictiveVoteCast(bytes32 indexed proposalHash, address indexed voter, bool support, uint256 prediction, uint256 stakedAmount);
    event ProposalExecuted(bytes32 indexed proposalHash, bool succeeded);
    event PredictiveRewardsClaimed(bytes32 indexed proposalHash, address indexed voter, uint256 rewards);

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyResearcher() {
        require(hasRole(RESEARCHER_ROLE, _msgSender()), AetherNexus__Unauthorized());
        _;
    }

    modifier onlyAIOracle() {
        require(_msgSender() == aiOracleAddress, AetherNexus__Unauthorized());
        _;
    }

    // --- Constructor ---
    constructor() ERC20("AetherToken", "AETH") ERC721("ResearchAssetNFT", "R-NFT") Ownable(_msgSender()) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Owner gets default admin
        // Grant initial AI_ORACLE_ROLE to owner for testing. In production, this would be the actual oracle contract address.
        _grantRole(AI_ORACLE_ROLE, _msgSender());
        aiOracleAddress = _msgSender(); // Temporarily set owner as oracle for testing.

        _baseTokenURI = "https://aethernexus.xyz/api/nft/"; // Base URI for R-NFT metadata
    }

    // --- ERC-20 Token Management (AETH) ---

    // Inherited: transfer, approve, transferFrom, balanceOf, allowance, totalSupply

    /// @notice Mints new AETH tokens to a specific address.
    /// @dev Only callable by accounts with the DEFAULT_ADMIN_ROLE (or a designated minter role).
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner { // Simplified to onlyOwner for demo
        if (amount == 0) revert AetherNexus__InvalidAmount();
        _mint(to, amount);
    }

    /// @notice Burns AETH tokens from the caller's balance.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) public {
        if (amount == 0) revert AetherNexus__InvalidAmount();
        _burn(_msgSender(), amount);
    }

    // --- Research Project Management ---

    /// @notice Submits a new research project proposal.
    /// @param _title The title of the research project.
    /// @param _descriptionURI IPFS/URL link to the detailed description of the project.
    /// @param _requiredFunding The AETH amount required to fund the project.
    /// @return The unique ID of the submitted project.
    function submitResearchProposal(
        string memory _title,
        string memory _descriptionURI,
        uint256 _requiredFunding
    ) public returns (bytes32) {
        if (_requiredFunding == 0) revert AetherNexus__InvalidAmount();

        bytes32 projectId = keccak256(abi.encodePacked(_msgSender(), _title, block.timestamp));
        researchProjects[projectId] = ResearchProject({
            researcher: _msgSender(),
            title: _title,
            descriptionURI: _descriptionURI,
            requiredFunding: _requiredFunding,
            raisedFunding: 0,
            state: ProjectState.Proposed,
            submittedAt: block.timestamp,
            progressURI: "",
            aiScore: 0,
            aiAnalysisURI: "",
            outcomeScore: 0,
            nftId: 0, // Will be minted upon funding
            rewardsClaimed: false
        });

        emit ResearchProposalSubmitted(projectId, _msgSender(), _title, _requiredFunding);
        return projectId;
    }

    /// @notice Funds a research project.
    /// @dev Project must be in `Proposed` state. If fully funded, its state changes to `Funded` and an R-NFT is minted.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of AETH to contribute.
    function fundResearchProposal(bytes32 _projectId, uint256 _amount) public {
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.state != ProjectState.Proposed && project.state != ProjectState.Funded) revert AetherNexus__ProjectNotInFundedState();
        if (_amount == 0) revert AetherNexus__InvalidAmount();
        if (project.raisedFunding.add(_amount) > project.requiredFunding) revert AetherNexus__NotEnoughFunds(); // Prevents overfunding

        _transfer(_msgSender(), address(this), _amount); // Transfer AETH to contract
        project.raisedFunding = project.raisedFunding.add(_amount);

        if (project.raisedFunding >= project.requiredFunding && project.state == ProjectState.Proposed) {
            project.state = ProjectState.Funded;
            uint256 newNftId = _mintResearchAssetNFT(_projectId, project.researcher);
            project.nftId = newNftId;
        }

        emit ResearchProjectFunded(_projectId, _msgSender(), _amount, project.raisedFunding);
    }

    /// @notice Allows the researcher to update their project's progress.
    /// @dev Only callable by the project's researcher. Project must be in `Funded` or `InProgress` state.
    /// @param _projectId The ID of the project.
    /// @param _newProgressURI IPFS/URL link to the new progress update.
    function updateResearchProgress(bytes32 _projectId, string memory _newProgressURI) public onlyResearcher {
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.researcher != _msgSender()) revert AetherNexus__Unauthorized();
        if (project.state != ProjectState.Funded && project.state != ProjectState.InProgress && project.state != ProjectState.AI_Analyzed) {
             revert AetherNexus__ProjectNotInProgress();
        }
        
        project.progressURI = _newProgressURI;
        if (project.state == ProjectState.Funded) {
            project.state = ProjectState.InProgress; // Move to InProgress once first update is made
        }
        // Update R-NFT metadata to reflect new progress
        _updateResearchAssetNFTMetadata(project.nftId, _newProgressURI, project.aiScore, project.outcomeScore);

        emit ResearchProgressUpdated(_projectId, _newProgressURI);
    }

    /// @notice Requests an external AI analysis for a research project.
    /// @dev This typically triggers an off-chain process that results in a callback to `receiveAIAnalysisResult`.
    /// @param _projectId The ID of the project to analyze.
    /// @param _dataToAnalyzeURI IPFS/URL link to the data that the AI should analyze.
    function requestAIAnalysis(bytes32 _projectId, string memory _dataToAnalyzeURI) public onlyResearcher {
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.researcher != _msgSender()) revert AetherNexus__Unauthorized();
        if (project.state != ProjectState.InProgress) revert AetherNexus__ProjectNotInProgress();
        if (aiOracleAddress == address(0)) revert AetherNexus__AIOracleNotSet();

        // In a real scenario, this would emit an event for an off-chain AI oracle to pick up,
        // or directly call an oracle contract that manages external calls.
        // For this demo, we emit the event and simulate the callback via `receiveAIAnalysisResult`.
        // A direct call might look like: IAIOracle(aiOracleAddress).requestAnalysis(_projectId, _dataToAnalyzeURI);
        emit AIAnalysisRequested(_projectId, _dataToAnalyzeURI);
    }

    /// @notice Callback function for the AI oracle to deliver analysis results.
    /// @dev Only callable by the designated AI Oracle address. Updates project state and R-NFT metadata.
    /// @param _projectId The ID of the project analyzed.
    /// @param _aiScore The AI's score (e.g., 0-100) indicating potential success or quality.
    /// @param _analysisURI IPFS/URL link to the detailed AI analysis report.
    function receiveAIAnalysisResult(
        bytes32 _projectId,
        uint256 _aiScore,
        string memory _analysisURI
    ) public onlyAIOracle {
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.state != ProjectState.InProgress && project.state != ProjectState.AI_Analyzed) {
             revert AetherNexus__ProjectNotInProgress(); // Can receive updated analysis
        }

        project.aiScore = _aiScore;
        project.aiAnalysisURI = _analysisURI;
        project.state = ProjectState.AI_Analyzed;

        // Update R-NFT metadata to reflect new AI score
        _updateResearchAssetNFTMetadata(project.nftId, project.progressURI, _aiScore, project.outcomeScore);

        emit AIAnalysisReceived(_projectId, _aiScore, _analysisURI);
    }

    /// @notice Allows the community (via governance or a trusted entity) to evaluate the final outcome of a project.
    /// @dev Updates project state, influences rewards, and updates R-NFT metadata.
    /// @param _projectId The ID of the project to evaluate.
    /// @param _outcomeScore The community's final evaluation score (0-100).
    function evaluateResearchOutcome(bytes32 _projectId, uint256 _outcomeScore) public onlyOwner { // Simplified to onlyOwner for demo; could be DAO vote
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.state != ProjectState.AI_Analyzed && project.state != ProjectState.Evaluated) {
            revert AetherNexus__ProjectNotAnalyzed();
        }
        if (_outcomeScore > 100) revert AetherNexus__InvalidAmount();

        project.outcomeScore = _outcomeScore;
        project.state = ProjectState.Evaluated;

        // Update R-NFT metadata
        _updateResearchAssetNFTMetadata(project.nftId, project.progressURI, project.aiScore, _outcomeScore);

        // Update researcher reputation
        researcherReputation[project.researcher] = researcherReputation[project.researcher]
            .add(_outcomeScore); // Simple additive model for demo

        emit ResearchOutcomeEvaluated(_projectId, _outcomeScore);
    }

    /// @notice Distributes AETH rewards to the researcher and funders based on project success.
    /// @dev Callable once the project has been `Evaluated`.
    /// @param _projectId The ID of the project for which to distribute rewards.
    function distributeResearchRewards(bytes32 _projectId) public {
        ResearchProject storage project = researchProjects[_projectId];
        if (project.researcher == address(0)) revert AetherNexus__ProjectNotFound();
        if (project.state != ProjectState.Evaluated) revert AetherNexus__ProjectNotEvaluated();
        if (project.rewardsClaimed) revert AetherNexus__ProjectAlreadyComplete();

        uint256 totalFunding = project.raisedFunding;
        uint256 outcomePercentage = project.outcomeScore; // Max 100

        // Example reward calculation: 10% of raised funding + outcome-based bonus
        // Researcher gets a share based on outcome, funders get original amount back + bonus
        uint256 baseRewardPool = totalFunding.div(10); // 10% of raised funding as base
        uint256 performanceBonus = totalFunding.mul(outcomePercentage).div(100); // 100% bonus for 100 score

        uint256 totalRewardPool = baseRewardPool.add(performanceBonus);

        // A simple split: Researcher gets 60%, Funders split 40% (proportional to their contribution)
        uint256 researcherReward = totalRewardPool.mul(60).div(100);
        uint256 funderRewardPool = totalRewardPool.mul(40).div(100);

        _transfer(address(this), project.researcher, researcherReward); // Transfer to researcher

        // In a real scenario, we'd need to track individual funder contributions
        // and distribute proportionally. For demo, let's assume funders receive their initial
        // investment back + a small flat bonus from the funder pool.
        // A more robust system would involve storing individual funder data in the project struct.
        // For simplicity, we'll send a small fixed amount to the researcher and assume remaining
        // project funds are locked or used otherwise.
        // Re-simplifying for the demo: researcher gets the performance bonus,
        // and funders (conceptually) get their investment back, but not explicitly handled here.
        // The funds held in this contract are now considered for distribution.

        // This requires tracking individual funders' contributions in the ResearchProject struct.
        // For this demo, let's assume for simplicity, the contract holds the funds, and the researcher
        // gets a reward based on the outcome, from a central reward pool.
        // Funds from `raisedFunding` could be used here. For simplicity, just sending a fixed amount.
        uint256 actualResearcherReward = project.raisedFunding.mul(project.outcomeScore).div(500); // Max 20% of raised funds
        if (actualResearcherReward > 0) {
            _transfer(address(this), project.researcher, actualResearcherReward);
        }

        project.state = ProjectState.Completed;
        project.rewardsClaimed = true;

        emit ResearchRewardsDistributed(
            _projectId,
            project.researcher,
            actualResearcherReward,
            project.raisedFunding.sub(actualResearcherReward) // Remainder conceptually returned to funders
        );
    }

    /// @notice Retrieves a specific research project's details.
    /// @param _projectId The ID of the project.
    /// @return A tuple containing all project details.
    function getResearchProject(bytes32 _projectId) public view returns (ResearchProject memory) {
        return researchProjects[_projectId];
    }

    // --- Dynamic Research Asset NFT (R-NFT) ---

    Counters.Counter private _tokenIds;

    /// @notice Internal function to mint a new R-NFT for a funded project.
    /// @dev Called automatically when a project is fully funded.
    /// @param _projectId The ID of the project.
    /// @param _recipient The address to mint the NFT to (usually the researcher).
    /// @return The new NFT ID.
    function _mintResearchAssetNFT(bytes32 _projectId, address _recipient) internal returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_recipient, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_baseTokenURI, Strings.toString(newItemId))));
        nftIdToProjectId[newItemId] = _projectId;
        emit ResearchAssetNFTMinted(_projectId, newItemId, _recipient);
        return newItemId;
    }

    /// @notice Updates the metadata URI for a specific R-NFT.
    /// @dev The URI will reflect the latest progress, AI score, and outcome score.
    /// @param _nftId The ID of the NFT to update.
    /// @param _progressURI The latest progress URI.
    /// @param _aiScore The latest AI score.
    /// @param _outcomeScore The latest outcome score.
    function _updateResearchAssetNFTMetadata(
        uint256 _nftId,
        string memory _progressURI,
        uint256 _aiScore,
        uint256 _outcomeScore
    ) internal {
        if (_nftId == 0) revert AetherNexus__ResearchNFTNotMinted();
        // In a real dNFT, this would call an external service or chainlink oracle
        // to update the metadata on IPFS/Arweave and then point the URI to it.
        // For this demo, we just emit an event and conceptually update the URI.
        string memory newURI = string(abi.encodePacked(
            _baseTokenURI, Strings.toString(_nftId),
            "?progress=", _progressURI,
            "&aiScore=", Strings.toString(_aiScore),
            "&outcomeScore=", Strings.toString(_outcomeScore)
        ));
        _setTokenURI(_nftId, newURI); // Updates the internal _tokenURIs mapping
        emit ResearchAssetNFTMetadataUpdated(_nftId, newURI);
    }

    /// @notice Returns the URI for the R-NFT metadata.
    /// @dev Overrides ERC721's tokenURI to reflect dynamic updates.
    /// @param tokenId The ID of the NFT.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bytes32 projectId = nftIdToProjectId[tokenId];
        ResearchProject storage project = researchProjects[projectId];
        return string(abi.encodePacked(
            _baseTokenURI, Strings.toString(tokenId),
            "?progress=", project.progressURI,
            "&aiScore=", Strings.toString(project.aiScore),
            "&outcomeScore=", Strings.toString(project.outcomeScore)
        ));
    }

    /// @notice Returns the R-NFT ID associated with a given research project.
    /// @param _projectId The ID of the project.
    /// @return The R-NFT ID.
    function getProjectNFTId(bytes32 _projectId) public view returns (uint256) {
        return researchProjects[_projectId].nftId;
    }

    /// @notice Returns the owner of a specific Research Asset NFT.
    /// @param _nftId The ID of the NFT.
    /// @return The owner's address.
    function getResearchAssetOwner(uint256 _nftId) public view returns (address) {
        return ownerOf(_nftId);
    }

    // --- Predictive Governance ---

    /// @notice Creates a new governance proposal.
    /// @param _title The title of the proposal.
    /// @param _descriptionURI IPFS/URL link to the detailed proposal description.
    /// @param _targetProject Optional: The project ID this proposal targets (0 if general).
    /// @param _duration The duration of the voting period in seconds.
    /// @return The hash (ID) of the newly created proposal.
    function createGovernanceProposal(
        string memory _title,
        string memory _descriptionURI,
        bytes32 _targetProject,
        uint256 _duration
    ) public returns (bytes32) {
        _proposalIds.increment();
        uint256 currentId = _proposalIds.current();
        bytes32 proposalHash = keccak256(abi.encodePacked(currentId, _title, block.timestamp));

        governanceProposals[proposalHash] = GovernanceProposal({
            title: _title,
            descriptionURI: _descriptionURI,
            targetProject: _targetProject,
            proposalId: currentId,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(_duration),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            totalPredictiveStake: 0,
            state: ProposalState.Active,
            outcomeResolved: false,
            actualOutcome: 0
        });
        proposalIdToHash[currentId] = proposalHash;

        emit GovernanceProposalCreated(proposalHash, currentId, _title, block.timestamp.add(_duration));
        return proposalHash;
    }

    /// @notice Allows a user to cast a predictive vote on a governance proposal.
    /// @dev Users stake AETH and provide a prediction. Accuracy is rewarded later.
    /// @param _proposalHash The hash (ID) of the proposal.
    /// @param _support True for 'for', false for 'against'.
    /// @param _predictionOutcome A numerical prediction (e.g., 0-100 score for project success, or 0/1 for binary outcomes).
    /// @param _stakeAmount The amount of AETH to stake for this prediction.
    function predictiveVote(
        bytes32 _proposalHash,
        bool _support,
        uint256 _predictionOutcome,
        uint256 _stakeAmount
    ) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        if (proposal.creationTime == 0) revert AetherNexus__ProposalNotFound();
        if (block.timestamp >= proposal.votingEndTime) revert AetherNexus__ProposalEnded();
        if (proposal.hasVoted[_msgSender()]) revert AetherNexus__AlreadyVoted();
        if (_stakeAmount == 0) revert AetherNexus__InvalidAmount();
        if (balanceOf(_msgSender()) < _stakeAmount) revert AetherNexus__InsufficientStake();
        
        _transfer(_msgSender(), address(this), _stakeAmount); // Transfer stake to contract

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(1);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(1);
        }
        proposal.hasVoted[_msgSender()] = true;
        proposal.voteSupport[_msgSender()] = _support;
        proposal.voterPrediction[_msgSender()] = _predictionOutcome;
        proposal.voterStake[_msgSender()] = _stakeAmount;
        proposal.totalPredictiveStake = proposal.totalPredictiveStake.add(_stakeAmount);

        emit PredictiveVoteCast(_proposalHash, _msgSender(), _support, _predictionOutcome, _stakeAmount);
    }

    /// @notice Executes a governance proposal if the voting period has ended and it has passed.
    /// @dev The proposal's `actualOutcome` needs to be set externally (e.g., by another DAO vote or an oracle)
    ///      before predictive rewards can be claimed.
    /// @param _proposalHash The hash (ID) of the proposal to execute.
    function executeProposal(bytes32 _proposalHash) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        if (proposal.creationTime == 0) revert AetherNexus__ProposalNotFound();
        if (block.timestamp < proposal.votingEndTime) revert AetherNexus__ProposalNotActive();
        if (proposal.state != ProposalState.Active) revert AetherNexus__ProposalEnded();

        bool succeeded = proposal.totalVotesFor > proposal.totalVotesAgainst;
        proposal.state = succeeded ? ProposalState.Succeeded : ProposalState.Failed;

        // In a real scenario, this is where the proposed action would be performed.
        // For example, calling another contract's function, or changing a state variable.
        // For the demo, we just mark it as executed.

        // Determine actual outcome for predictive accuracy (simplified: success = 100, failure = 0)
        // In a real system, actualOutcome would be determined by complex logic or oracle input.
        proposal.actualOutcome = succeeded ? 100 : 0; // Simplified for demo
        proposal.outcomeResolved = true;

        proposal.state = ProposalState.Executed; // Mark as executed after resolution

        emit ProposalExecuted(_proposalHash, succeeded);
    }

    /// @notice Allows voters to claim rewards based on their predictive accuracy for a given proposal.
    /// @dev Only callable after the proposal has been executed and its outcome resolved.
    /// @param _proposalHash The hash (ID) of the proposal.
    function claimPredictiveRewards(bytes32 _proposalHash) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        if (proposal.creationTime == 0) revert AetherNexus__ProposalNotFound();
        if (proposal.state != ProposalState.Executed || !proposal.outcomeResolved) revert AetherNexus__ProposalNotActive(); // Not executed or outcome not resolved
        if (!proposal.hasVoted[_msgSender()]) revert AetherNexus__Unauthorized(); // Only voters can claim

        uint256 voterStake = proposal.voterStake[_msgSender()];
        uint256 voterPrediction = proposal.voterPrediction[_msgSender()];
        
        // Return original stake
        if (voterStake > 0) {
            _transfer(address(this), _msgSender(), voterStake);
            proposal.voterStake[_msgSender()] = 0; // Prevent double claim
        }

        // Calculate predictive accuracy reward
        uint256 accuracy;
        if (voterPrediction == proposal.actualOutcome) {
            accuracy = 100; // Perfect match
        } else {
            // Simplified accuracy: inversely proportional to difference, capped at 100
            uint256 diff = voterPrediction > proposal.actualOutcome ? voterPrediction - proposal.actualOutcome : proposal.actualOutcome - voterPrediction;
            accuracy = 100 > diff ? 100 - diff : 0; // 0 if difference is 100 or more
        }

        // Reward calculation: stake * (accuracy/100) * (some multiplier)
        uint256 predictiveReward = voterStake.mul(accuracy).div(100).div(2); // Example: 0.5x stake for perfect accuracy

        if (predictiveReward > 0) {
            // Distribute from a pool or dynamically mint. For demo, let's mint if needed.
            if (balanceOf(address(this)) < predictiveReward) {
                _mint(address(this), predictiveReward); // Minting to ensure rewards are available
            }
            _transfer(address(this), _msgSender(), predictiveReward);
        }

        // Update voter's accuracy metrics
        voterPredictionAccuracySum[_msgSender()] = voterPredictionAccuracySum[_msgSender()].add(accuracy);
        voterPredictionCount[_msgSender()] = voterPredictionCount[_msgSender()].add(1);

        emit PredictiveRewardsClaimed(_proposalHash, _msgSender(), predictiveReward);
    }

    /// @notice Retrieves a specific governance proposal's details.
    /// @param _proposalHash The hash (ID) of the proposal.
    /// @return A tuple containing all proposal details.
    function getGovernanceProposal(bytes32 _proposalHash) public view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalHash];
    }

    // --- Staking & Reputation ---

    /// @notice Stakes AETH tokens for governance power and potential rewards.
    /// @param _amount The amount of AETH to stake.
    function stakeAETH(uint256 _amount) public {
        if (_amount == 0) revert AetherNexus__InvalidAmount();
        _transfer(_msgSender(), address(this), _amount); // Transfer AETH to contract
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(_amount);
        // Logic for calculating potential staking rewards can be added here
        emit TokensStaked(_msgSender(), _amount);
    }

    /// @notice Unstakes AETH tokens.
    /// @param _amount The amount of AETH to unstake.
    function unstakeAETH(uint256 _amount) public {
        if (_amount == 0) revert AetherNexus__InvalidAmount();
        if (stakedBalances[_msgSender()] < _amount) revert AetherNexus__NoStakedTokens();

        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(_amount);
        _transfer(address(this), _msgSender(), _amount); // Transfer AETH back

        emit TokensUnstaked(_msgSender(), _amount);
    }

    /// @notice Claims accumulated staking rewards.
    /// @dev Reward calculation logic can be highly complex (e.g., based on time staked, total pool, etc.).
    /// For this demo, it's a placeholder.
    function claimStakingRewards() public {
        uint256 rewards = stakingRewards[_msgSender()]; // Placeholder for actual calculation
        if (rewards == 0) revert AetherNexus__NoRewardsToClaim();

        stakingRewards[_msgSender()] = 0;
        _transfer(address(this), _msgSender(), rewards);

        emit StakingRewardsClaimed(_msgSender(), rewards);
    }

    /// @notice Returns the aggregated reputation score of a researcher.
    /// @param _researcher The address of the researcher.
    /// @return The researcher's reputation score.
    function getResearcherReputation(address _researcher) public view returns (uint256) {
        return researcherReputation[_researcher];
    }

    /// @notice Returns the average prediction accuracy score of a voter.
    /// @param _voter The address of the voter.
    /// @return The average prediction accuracy (0-100).
    function getVoterPredictionAccuracy(address _voter) public view returns (uint256) {
        if (voterPredictionCount[_voter] == 0) {
            return 0;
        }
        return voterPredictionAccuracySum[_voter].div(voterPredictionCount[_voter]);
    }

    // --- Admin & Utility ---

    /// @notice Sets the address of the trusted AI Oracle contract.
    /// @dev Only callable by the contract owner.
    /// @param _newOracle The address of the new AI Oracle contract.
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) revert AetherNexus__AIOracleNotSet();
        aiOracleAddress = _newOracle;
        _grantRole(AI_ORACLE_ROLE, _newOracle); // Grant the role to the new oracle
        // Potentially revoke from old oracle if tracking
    }

    /// @notice Grants the RESEARCHER_ROLE to a specified address.
    /// @dev Only callable by the contract owner or an address with DEFAULT_ADMIN_ROLE.
    /// @param _researcher The address to grant the role to.
    function addResearcherRole(address _researcher) public onlyOwner {
        _grantRole(RESEARCHER_ROLE, _researcher);
    }

    /// @notice Revokes the RESEARCHER_ROLE from a specified address.
    /// @dev Only callable by the contract owner or an address with DEFAULT_ADMIN_ROLE.
    /// @param _researcher The address to revoke the role from.
    function revokeResearcherRole(address _researcher) public onlyOwner {
        _revokeRole(RESEARCHER_ROLE, _researcher);
    }

    /// @notice Returns the AETH balance of the contract.
    function getVALBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    /// @notice Retrieves the total number of votes for a given proposal.
    /// @param _proposalHash The hash (ID) of the proposal.
    /// @return totalFor The count of 'for' votes.
    /// @return totalAgainst The count of 'against' votes.
    function getProposalVoteCount(bytes32 _proposalHash) public view returns (uint256 totalFor, uint256 totalAgainst) {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        return (proposal.totalVotesFor, proposal.totalVotesAgainst);
    }

    /// @notice Retrieves the prediction made by a specific voter for a given proposal.
    /// @param _proposalHash The hash (ID) of the proposal.
    /// @param _voter The address of the voter.
    /// @return The voter's prediction outcome.
    function getPredictiveVotePrediction(bytes32 _proposalHash, address _voter) public view returns (uint256) {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        return proposal.voterPrediction[_voter];
    }
}
```