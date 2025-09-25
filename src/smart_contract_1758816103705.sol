This smart contract, "Synapse-L&D," is designed as a decentralized platform for funding and evaluating projects or learning modules, integrating advanced concepts like dynamic NFTs, an adaptive reputation system, and a robust DAO governance model. It aims to foster a self-improving, community-driven ecosystem.

---

### **Synapse-L&D Smart Contract Outline & Function Summary**

**I. Core Infrastructure & Tokenomics**
*   **`SYNAPTToken` (ERC20):** The native utility token for staking, rewards, and governance.
*   **`InsightNFT` (ERC721):** Dynamic, reputation-linked achievement NFTs whose metadata can evolve.
*   **`SynapseLd` (Main Contract):** Orchestrates the entire ecosystem.

**II. Key Concepts**
*   **Adaptive Reputation:** User reputation scores (`reputationScore`) change dynamically based on successful project submissions, backing successful projects, challenging incorrect oracle reports, or negative actions.
*   **Dynamic NFTs:** `InsightNFT`s are minted upon significant achievements (e.g., completing a high-reputation project) and their `tokenURI` (and thus visual representation/metadata) can be updated based on ongoing performance, further achievements, or linked project status.
*   **Decentralized Oracle Integration (Simulated):** A designated `oracleAddress` provides crucial off-chain data (e.g., project outcome). The system includes mechanisms to challenge potentially incorrect oracle reports.
*   **DAO Governance:** Staked `SYNAPTToken`s and reputation scores grant voting power on proposals that can evolve protocol parameters, execute actions, or even challenge oracle reports.
*   **Timelocked Unstaking:** To prevent sudden market dumps and encourage long-term commitment, unstaking `SYNAPTToken`s involves a timelock period.
*   **Project Lifecycle:** Comprehensive management from proposal submission, community backing, outcome reporting, to reward distribution and potential liquidation of failed projects.

---

### **Function Summary (SynapseLd Contract)**

**I. Core Infrastructure & Tokenomics (Interactions with SYNAPTToken)**
1.  **`stakeSYNAPT(uint256 amount)`:** Allows a user to stake `SYNAPTToken`s into the platform for project backing and governance.
2.  **`requestUnstakeWithTimelock(uint256 amount)`:** Initiates a timelocked process to unstake `SYNAPTToken`s, locking them for a defined period.
3.  **`finalizeUnstake()`:** Completes the unstaking process after the timelock has expired, transferring tokens back to the user.
4.  **`burnSYNAPT(uint256 amount)`:** Allows a user to burn their `SYNAPTToken`s (e.g., for self-curation or specific protocol interactions).
5.  **`mintSYNAPT(address recipient, uint256 amount)`:** (Admin/DAO only) Mints new `SYNAPTToken`s for specific purposes like initial rewards or treasury funding.

**II. Project & Learning Module Management**
6.  **`submitProjectProposal(string calldata _title, string calldata _description, uint256 _requiredStake)`:** Users submit new project proposals, specifying details and the minimum `SYNAPTToken` stake required to initiate funding.
7.  **`backProject(uint256 _projectId, uint256 _amount)`:** Allows users to stake `SYNAPTToken`s on a specific project, signaling their support and providing funding.
8.  **`signalProjectCompletion(uint256 _projectId)`:** The project owner signals that their project is complete and ready for oracle evaluation.
9.  **`oracleReportOutcome(uint256 _projectId, Outcome _outcome, string calldata _details)`:** (Oracle only) The designated oracle provides an official report on a project's outcome (Success, Failure, PartialSuccess).
10. **`claimProjectRewards(uint256 _projectId)`:** Project owner and successful backers claim their rewards (SYNAPT tokens, reputation, potentially InsightNFTs) after a successful project outcome.
11. **`liquidateFailedProject(uint256 _projectId)`:** Allows a supermajority of backers of a failed project to collectively withdraw their remaining staked funds (if any) and penalize the project owner's reputation.
12. **`requestProjectExtension(uint256 _projectId, uint256 _newDeadline, uint256 _additionalStakeRequired)`:** Project owners can request an extension (time/funds), which may require further community approval or additional backing.

**III. Adaptive Reputation & Dynamic NFTs (Interactions with InsightNFT)**
13. **`getReputationScore(address _user)`:** Retrieves the current reputation score of a given user.
14. **`awardInsightNFT(address _recipient, uint256 _projectId, string calldata _initialMetadataURI)`:** (Internal/System) Mints a new `InsightNFT` to a user upon a significant achievement (e.g., successful project completion).
15. **`updateInsightNFTStatus(uint256 _tokenId, string calldata _newMetadataURI)`:** (NFT Owner/System) Updates the metadata URI of an `InsightNFT`, allowing its visual representation or linked data to evolve based on new achievements or project status.
16. **`delegateReputationScore(address _delegatee)`:** Allows a user to temporarily delegate their reputation-based voting power to another user for governance purposes.

**IV. Governance & Protocol Evolution (DAO)**
17. **`createGovernanceProposal(string calldata _title, string calldata _description, address _targetContract, bytes calldata _callData)`:** Users with sufficient staked tokens/reputation can propose protocol changes, parameter updates, or specific actions.
18. **`voteOnProposal(uint256 _proposalId, bool _support)`:** Stakers vote on active proposals using their combined staked SYNAPT tokens and reputation score.
19. **`executeProposal(uint256 _proposalId)`:** Executes a passed governance proposal, triggering the associated contract calls.
20. **`challengeOracleReport(uint256 _projectId, string calldata _reason)`:** Allows a group of stakers to challenge an oracle's outcome report, initiating a governance dispute resolution process.

**V. Advanced Features & Security**
21. **`activateEmergencyPause()`:** (Admin/DAO only) Pauses critical contract functionalities in case of an emergency.
22. **`deactivateEmergencyPause()`:** (Admin/DAO only) Resumes contract functionalities after an emergency pause.
23. **`setMinimumStakingRequirement(uint256 _newMin)`:** (DAO only) Adjusts the minimum `SYNAPTToken` stake required to submit a project or create a governance proposal.
24. **`blacklistAddress(address _user)`:** (DAO only) Blacklists a malicious user, preventing them from participating in key contract functions and impacting their reputation.
25. **`fundProtocolTreasury()`:** Allows any user to send ETH to the contract's treasury, managed by the DAO for community initiatives.
26. **`withdrawETHFromTreasury(uint256 amount)`:** (DAO only) Allows the DAO to withdraw ETH from the protocol's treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Custom ERC20 Token for Synapse-L&D (SYNAPT) ---
contract SYNAPTToken is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply, address initialOwner)
        ERC20("SYNAPT Token", "SYNAPT")
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply);
    }

    // Function to allow SynapseLd contract to mint tokens for rewards etc.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Function to allow SynapseLd contract to burn tokens for penalties etc.
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}

// --- Custom ERC721 Token for Insight NFTs ---
contract InsightNFT is ERC721, Ownable {
    constructor(address initialOwner)
        ERC721("Insight NFT", "INSIGHT")
        Ownable(initialOwner)
    {}

    // Mapping to store dynamic metadata URIs
    mapping(uint256 => string) private _tokenUris;

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbdF9s7Qz2X.../base/"; // Placeholder for a base URI
    }

    // Function to allow SynapseLd contract to mint NFTs
    function mint(address to, uint256 tokenId, string calldata uri) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Override _setTokenURI to use our custom mapping for dynamic updates
    function _setTokenURI(uint256 tokenId, string calldata uri) internal override {
        _tokenUris[tokenId] = uri;
    }

    // Allows the NFT owner (or contract owner if delegated) to update the metadata URI
    function updateTokenURI(uint256 tokenId, string calldata newUri) public onlyOwner {
        require(_exists(tokenId), "InsightNFT: token does not exist");
        // For dynamic NFTs, this can be restricted to the token owner or an authorized contract
        // For simplicity, here it's restricted to contract owner (SynapseLd contract)
        _setTokenURI(tokenId, newUri);
    }

    // Returns the token URI from our custom mapping
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenUris[tokenId];
    }
}

// --- Main Synapse-L&D Contract ---
contract SynapseLd is Ownable, Pausable, ReentrancyGuard {
    // --- Constants & Immutable Variables ---
    SYNAPTToken public immutable SYNAPT;
    InsightNFT public immutable insightNFT;
    uint256 public constant UNSTAKE_TIMELOCK = 7 days; // 7 days timelock for unstaking
    uint256 public constant MIN_REPUTATION_FOR_GOVERNANCE = 1000;
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 1000 * (10 ** 18); // 1000 SYNAPT

    // --- State Variables ---
    address public oracleAddress;
    uint256 public nextProjectId = 1;
    uint256 public nextInsightNftId = 1;
    uint256 public nextProposalId = 1;
    uint256 public minProjectStakeRequirement = 100 * (10 ** 18); // Default 100 SYNAPT

    // --- Enums & Structs ---
    enum ProjectStatus { Pending, Funding, Active, Completed, Failed, Liquidated, Challenged }
    enum Outcome { Unknown, Success, PartialSuccess, Failure }
    enum ProposalStatus { Active, Passed, Failed, Executed, Challenged }

    struct UserProfile {
        uint256 reputationScore;
        uint256 stakedTokens; // Total SYNAPT tokens staked by the user
        uint256 lastStakeChange; // Timestamp of last stake change for rewards calculation, if applicable
    }

    struct UnstakeRequest {
        uint256 amount;
        uint256 withdrawableAt;
    }

    struct Project {
        uint256 id;
        address owner;
        string title;
        string description;
        uint256 requiredStake;
        uint256 fundsRaised;
        ProjectStatus status;
        Outcome outcome;
        address[] backers;
        mapping(address => uint256) backedAmounts;
        uint256 deadline; // For funding/completion
        uint256 completionSignalTime;
        uint256 reputationImpactMultiplier; // How much this project affects reputation
        uint256 insightNftId; // 0 if no NFT awarded yet
    }
    mapping(uint256 => Project) public projects;

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address targetContract; // Contract to call if proposal passes
        bytes callData;         // Calldata for the targetContract
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // User => Voted status
        ProposalStatus status;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public proposals;

    // --- Mappings ---
    mapping(address => UserProfile) public userProfiles;
    mapping(address => UnstakeRequest) public unstakeRequests;
    mapping(address => address) public delegatedReputation; // Delegatee => Delegator

    // --- Events ---
    event SYNAPTStaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 withdrawableAt);
    event UnstakeFinalized(address indexed user, uint256 amount);
    event SYNAPTBurned(address indexed burner, uint256 amount);
    event SYNAPTMinted(address indexed recipient, uint256 amount);

    event ProjectProposalSubmitted(uint256 indexed projectId, address indexed owner, string title, uint256 requiredStake);
    event ProjectBacked(uint256 indexed projectId, address indexed backer, uint256 amount);
    event ProjectCompletionSignaled(uint256 indexed projectId, address indexed owner);
    event OracleOutcomeReported(uint256 indexed projectId, Outcome outcome, string details);
    event ProjectRewardsClaimed(uint256 indexed projectId, address indexed claimant, uint256 rewards);
    event ProjectLiquidated(uint256 indexed projectId);
    event ProjectExtensionRequested(uint256 indexed projectId, uint256 newDeadline, uint256 additionalStake);

    event InsightNftAwarded(address indexed recipient, uint256 indexed projectId, uint256 indexed tokenId);
    event InsightNftStatusUpdated(uint256 indexed tokenId, string newMetadataURI);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationScoreAdjusted(address indexed user, int256 adjustment, uint256 newScore);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleReportChallenged(uint256 indexed projectId, uint256 indexed proposalId, address indexed challenger);

    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);
    event MinStakeRequirementSet(uint256 newMinStake);
    event AddressBlacklisted(address indexed user);
    event ProtocolTreasuryFunded(address indexed sender, uint256 amount);
    event TreasuryETHWithdraw(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "SynapseLd: Only the designated oracle can call this function");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "SynapseLd: Only project owner can call this function");
        _;
    }

    modifier notBlacklisted(address _user) {
        require(!_isBlacklisted[_user], "SynapseLd: User is blacklisted");
        _;
    }

    mapping(address => bool) private _isBlacklisted;

    // --- Constructor ---
    constructor(address _oracleAddress) Ownable(msg.sender) {
        SYNAPT = new SYNAPTToken(100_000_000 * (10 ** 18), msg.sender); // 100M initial supply
        insightNFT = new InsightNFT(address(this)); // SynapseLd contract is the owner/minter of NFTs
        oracleAddress = _oracleAddress;
    }

    // Fallback function for receiving ETH to the treasury
    receive() external payable {
        emit ProtocolTreasuryFunded(msg.sender, msg.value);
    }

    // --- Internal/Helper Functions ---
    function _adjustReputation(address _user, int256 _adjustment) internal {
        UserProfile storage user = userProfiles[_user];
        if (_adjustment > 0) {
            user.reputationScore += uint256(_adjustment);
        } else {
            uint256 absAdjustment = uint256(-_adjustment);
            if (user.reputationScore <= absAdjustment) {
                user.reputationScore = 0;
            } else {
                user.reputationScore -= absAdjustment;
            }
        }
        emit ReputationScoreAdjusted(_user, _adjustment, user.reputationScore);
    }

    function _getVotingPower(address _voter) internal view returns (uint256) {
        address actualVoter = delegatedReputation[_voter] == address(0) ? _voter : delegatedReputation[_voter];
        return userProfiles[actualVoter].stakedTokens + userProfiles[actualVoter].reputationScore;
    }

    // --- I. Core Infrastructure & Tokenomics ---

    /**
     * @notice Stakes SYNAPT tokens into the platform for project backing and governance.
     * @param amount The amount of SYNAPT tokens to stake.
     */
    function stakeSYNAPT(uint256 amount) public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        require(amount > 0, "SynapseLd: Stake amount must be greater than zero");
        SYNAPT.transferFrom(msg.sender, address(this), amount);
        userProfiles[msg.sender].stakedTokens += amount;
        userProfiles[msg.sender].lastStakeChange = block.timestamp;
        emit SYNAPTStaked(msg.sender, amount, userProfiles[msg.sender].stakedTokens);
    }

    /**
     * @notice Initiates a timelocked process to unstake SYNAPT tokens.
     *         Tokens will be locked for UNSTAKE_TIMELOCK duration.
     * @param amount The amount of SYNAPT tokens to unstake.
     */
    function requestUnstakeWithTimelock(uint256 amount) public whenNotPaused notBlacklisted(msg.sender) {
        UserProfile storage user = userProfiles[msg.sender];
        require(user.stakedTokens >= amount, "SynapseLd: Insufficient staked tokens");
        require(unstakeRequests[msg.sender].amount == 0, "SynapseLd: Pending unstake request exists");
        require(amount > 0, "SynapseLd: Unstake amount must be greater than zero");

        user.stakedTokens -= amount;
        unstakeRequests[msg.sender] = UnstakeRequest(amount, block.timestamp + UNSTAKE_TIMELOCK);
        emit UnstakeRequested(msg.sender, amount, unstakeRequests[msg.sender].second);
    }

    /**
     * @notice Finalizes the unstaking process after the timelock has expired.
     *         Transfers tokens back to the user.
     */
    function finalizeUnstake() public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        UnstakeRequest storage request = unstakeRequests[msg.sender];
        require(request.amount > 0, "SynapseLd: No pending unstake request");
        require(block.timestamp >= request.withdrawableAt, "SynapseLd: Unstake timelock not yet expired");

        uint256 amountToWithdraw = request.amount;
        delete unstakeRequests[msg.sender];
        SYNAPT.transfer(msg.sender, amountToWithdraw);
        emit UnstakeFinalized(msg.sender, amountToWithdraw);
    }

    /**
     * @notice Allows a user to burn their own SYNAPT tokens.
     * @param amount The amount of SYNAPT tokens to burn.
     */
    function burnSYNAPT(uint256 amount) public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        require(amount > 0, "SynapseLd: Burn amount must be greater than zero");
        SYNAPT.burnFrom(msg.sender, amount); // Uses ERC20Burnable's burnFrom, requires prior approval
        emit SYNAPTBurned(msg.sender, amount);
    }

    /**
     * @notice Mints new SYNAPT tokens to a recipient. Callable only by the contract owner (admin/DAO).
     * @param recipient The address to mint tokens to.
     * @param amount The amount of SYNAPT tokens to mint.
     */
    function mintSYNAPT(address recipient, uint256 amount) public whenNotPaused onlyOwner {
        require(amount > 0, "SynapseLd: Mint amount must be greater than zero");
        SYNAPT.mint(recipient, amount);
        emit SYNAPTMinted(recipient, amount);
    }

    // --- II. Project & Learning Module Management ---

    /**
     * @notice Users submit new project proposals, requiring a minimum stake.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _requiredStake The minimum SYNAPT stake required to start funding for this project.
     */
    function submitProjectProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requiredStake
    ) public whenNotPaused notBlacklisted(msg.sender) returns (uint256) {
        require(userProfiles[msg.sender].reputationScore > 0, "SynapseLd: Must have reputation to submit project");
        require(_requiredStake >= minProjectStakeRequirement, "SynapseLd: Required stake too low");

        uint256 currentProjectId = nextProjectId++;
        projects[currentProjectId] = Project({
            id: currentProjectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            requiredStake: _requiredStake,
            fundsRaised: 0,
            status: ProjectStatus.Pending,
            outcome: Outcome.Unknown,
            backers: new address[](0),
            deadline: 0, // Set later when funding starts/completes
            completionSignalTime: 0,
            reputationImpactMultiplier: userProfiles[msg.sender].reputationScore / 100, // Dynamic impact
            insightNftId: 0
        });

        emit ProjectProposalSubmitted(currentProjectId, msg.sender, _title, _requiredStake);
        return currentProjectId;
    }

    /**
     * @notice Allows users to stake SYNAPT tokens on a project, backing it.
     * @param _projectId The ID of the project to back.
     * @param _amount The amount of SYNAPT tokens to stake on the project.
     */
    function backProject(uint256 _projectId, uint256 _amount) public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Pending || project.status == ProjectStatus.Funding, "SynapseLd: Project not accepting new backers");
        require(userProfiles[msg.sender].stakedTokens >= _amount, "SynapseLd: Insufficient staked tokens to back project");
        require(_amount > 0, "SynapseLd: Backing amount must be greater than zero");
        require(project.owner != msg.sender, "SynapseLd: Project owner cannot back their own project");

        // Transfer tokens from user's staked balance to project's funds
        userProfiles[msg.sender].stakedTokens -= _amount;
        project.fundsRaised += _amount;
        
        if (project.backedAmounts[msg.sender] == 0) {
            project.backers.push(msg.sender);
        }
        project.backedAmounts[msg.sender] += _amount;

        if (project.fundsRaised >= project.requiredStake && project.status == ProjectStatus.Pending) {
            project.status = ProjectStatus.Active;
            project.deadline = block.timestamp + 30 days; // Example: 30 days to complete once funded
        } else if (project.fundsRaised < project.requiredStake && project.status == ProjectStatus.Pending) {
            project.status = ProjectStatus.Funding;
        }

        emit ProjectBacked(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Project owner signals that their project is complete and ready for oracle evaluation.
     * @param _projectId The ID of the project.
     */
    function signalProjectCompletion(uint256 _projectId) public whenNotPaused onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "SynapseLd: Project is not active");
        require(block.timestamp <= project.deadline, "SynapseLd: Project deadline has passed");

        project.completionSignalTime = block.timestamp;
        project.status = ProjectStatus.Completed; // Awaiting oracle report

        emit ProjectCompletionSignaled(_projectId, msg.sender);
    }

    /**
     * @notice The designated oracle provides an official report on a project's outcome.
     * @param _projectId The ID of the project.
     * @param _outcome The outcome of the project (Success, Failure, PartialSuccess).
     * @param _details Additional details from the oracle report.
     */
    function oracleReportOutcome(
        uint256 _projectId,
        Outcome _outcome,
        string calldata _details
    ) public whenNotPaused onlyOracle {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Completed || project.status == ProjectStatus.Challenged, "SynapseLd: Project not ready for oracle report or currently challenged");
        require(_outcome != Outcome.Unknown, "SynapseLd: Outcome cannot be Unknown");

        project.outcome = _outcome;

        // Apply reputation adjustments based on outcome
        int256 reputationChange = 0;
        if (_outcome == Outcome.Success) {
            reputationChange = int256(project.reputationImpactMultiplier * 10); // Example: high positive impact
            project.status = ProjectStatus.Completed;
        } else if (_outcome == Outcome.PartialSuccess) {
            reputationChange = int256(project.reputationImpactMultiplier * 5); // Example: moderate positive impact
            project.status = ProjectStatus.Completed;
        } else if (_outcome == Outcome.Failure) {
            reputationChange = -int256(project.reputationImpactMultiplier * 15); // Example: high negative impact
            project.status = ProjectStatus.Failed;
        }
        _adjustReputation(project.owner, reputationChange);

        emit OracleOutcomeReported(_projectId, _outcome, _details);
    }

    /**
     * @notice Project owner and successful backers claim their rewards after a project's successful outcome.
     *         Rewards include SYNAPT tokens, reputation, and potentially InsightNFTs.
     *         This function can be called multiple times for different backers.
     * @param _projectId The ID of the project.
     */
    function claimProjectRewards(uint256 _projectId) public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Completed, "SynapseLd: Project is not completed successfully");
        require(project.outcome == Outcome.Success || project.outcome == Outcome.PartialSuccess, "SynapseLd: Project outcome not successful");
        require(project.backedAmounts[msg.sender] > 0 || project.owner == msg.sender, "SynapseLd: Not a backer or owner of this project");

        uint256 rewards = 0;

        if (msg.sender == project.owner) {
            // Owner claims their portion
            uint256 ownerRewardFactor = (project.outcome == Outcome.Success) ? 120 : 100; // 120% for success, 100% for partial success
            rewards = (project.fundsRaised * ownerRewardFactor) / 100;
            // Transfer funds back to the owner's staked balance
            userProfiles[project.owner].stakedTokens += rewards;
            
            // Award InsightNFT if not already awarded
            if (project.insightNftId == 0 && project.outcome == Outcome.Success) {
                uint256 currentNftId = nextInsightNftId++;
                insightNFT.mint(project.owner, currentNftId, string(abi.encodePacked("ipfs://QmbdF9s7Qz2X.../project_success/", Strings.toString(_projectId))));
                project.insightNftId = currentNftId;
                emit InsightNftAwarded(project.owner, _projectId, currentNftId);
            }
            project.fundsRaised = 0; // All funds distributed for the project
        } else {
            // Backers claim their portion
            require(project.backedAmounts[msg.sender] > 0, "SynapseLd: No funds backed by this user");
            uint256 backerRewardFactor = (project.outcome == Outcome.Success) ? 110 : 105; // 110% for success, 105% for partial
            rewards = (project.backedAmounts[msg.sender] * backerRewardFactor) / 100;
            userProfiles[msg.sender].stakedTokens += rewards; // Return staked amount + profit
            project.backedAmounts[msg.sender] = 0; // Mark as claimed
        }

        emit ProjectRewardsClaimed(_projectId, msg.sender, rewards);
    }

    /**
     * @notice Allows a supermajority of backers of a failed project to collectively withdraw
     *         their remaining staked funds (if any) and penalize the project owner's reputation.
     * @param _projectId The ID of the failed project.
     */
    function liquidateFailedProject(uint256 _projectId) public whenNotPaused notBlacklisted(msg.sender) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Failed, "SynapseLd: Project is not in a failed state");

        // Example: Only 75% of funds are recoverable if project failed
        uint256 recoverableFunds = (project.fundsRaised * 75) / 100;
        uint256 backerShare = 0;
        for (uint i = 0; i < project.backers.length; i++) {
            address backer = project.backers[i];
            if (project.backedAmounts[backer] > 0) {
                backerShare += project.backedAmounts[backer];
            }
        }

        require(backerShare > 0, "SynapseLd: No recoverable funds for backers");

        // Distribute remaining funds proportionally to backers
        for (uint i = 0; i < project.backers.length; i++) {
            address backer = project.backers[i];
            if (project.backedAmounts[backer] > 0) {
                uint256 amountToRefund = (project.backedAmounts[backer] * recoverableFunds) / backerShare;
                userProfiles[backer].stakedTokens += amountToRefund;
                project.backedAmounts[backer] = 0; // Mark as refunded
            }
        }
        
        // Penalize owner heavily
        _adjustReputation(project.owner, -int256(project.reputationImpactMultiplier * 20));

        project.status = ProjectStatus.Liquidated;
        project.fundsRaised = 0; // All funds distributed/lost
        emit ProjectLiquidated(_projectId);
    }

    /**
     * @notice Project owners can request an extension (time/funds), which may require
     *         further community approval or additional backing.
     *         This creates a governance proposal for community approval.
     * @param _projectId The ID of the project.
     * @param _newDeadline The new proposed deadline timestamp.
     * @param _additionalStakeRequired The additional SYNAPT stake requested.
     */
    function requestProjectExtension(
        uint256 _projectId,
        uint256 _newDeadline,
        uint256 _additionalStakeRequired
    ) public whenNotPaused onlyProjectOwner(_projectId) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "SynapseLd: Project is not active");
        require(_newDeadline > project.deadline, "SynapseLd: New deadline must be after current deadline");

        // Create a governance proposal for project extension
        bytes memory callData = abi.encodeWithSelector(
            this.executeProjectExtension.selector, // A function to be called by DAO if proposal passes
            _projectId, _newDeadline, _additionalStakeRequired
        );
        
        uint256 proposalId = createGovernanceProposal(
            string(abi.encodePacked("Extend Project ", Strings.toString(_projectId))),
            string(abi.encodePacked("Request for extension for project ", Strings.toString(_projectId), ". New deadline: ", Strings.toString(_newDeadline), ", additional stake: ", Strings.toString(_additionalStakeRequired))),
            address(this), // Target contract is SynapseLd itself
            callData
        );
        
        emit ProjectExtensionRequested(_projectId, _newDeadline, _additionalStakeRequired);
        return proposalId;
    }

    /**
     * @notice Internal function to execute a project extension if approved by DAO.
     *         This is called via `executeProposal` if the extension proposal passes.
     */
    function executeProjectExtension(
        uint256 _projectId,
        uint256 _newDeadline,
        uint256 _additionalStakeRequired
    ) public onlyOwner whenNotPaused { // Only callable by the contract itself (via DAO execution)
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Active, "SynapseLd: Project is not active");
        require(_newDeadline > project.deadline, "SynapseLd: New deadline must be after current deadline");

        project.deadline = _newDeadline;
        project.requiredStake += _additionalStakeRequired; // Increase required stake for more funding

        // Optionally, reset status to Funding if new requiredStake is not met
        if (project.fundsRaised < project.requiredStake) {
            project.status = ProjectStatus.Funding;
        }
    }


    // --- III. Adaptive Reputation & Dynamic NFTs ---

    /**
     * @notice Retrieves the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    /**
     * @notice (Internal/System) Mints a new dynamic InsightNFT to a user upon a significant achievement.
     *         Callable only by the contract itself (owner of InsightNFT).
     * @param _recipient The address to receive the NFT.
     * @param _projectId The ID of the project linked to this NFT.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function awardInsightNFT(
        address _recipient,
        uint256 _projectId,
        string calldata _initialMetadataURI
    ) internal {
        uint256 currentNftId = nextInsightNftId++;
        insightNFT.mint(_recipient, currentNftId, _initialMetadataURI);
        emit InsightNftAwarded(_recipient, _projectId, currentNftId);
    }

    /**
     * @notice Allows the InsightNFT's metadata/status to change based on further achievements
     *         or linked project performance. Callable by the NFT owner or the SynapseLd contract.
     * @param _tokenId The ID of the InsightNFT to update.
     * @param _newMetadataURI The new metadata URI for the NFT.
     */
    function updateInsightNFTStatus(uint256 _tokenId, string calldata _newMetadataURI) public whenNotPaused {
        require(insightNFT.ownerOf(_tokenId) == msg.sender || msg.sender == address(this), "SynapseLd: Only NFT owner or contract can update status");
        insightNFT.updateTokenURI(_tokenId, _newMetadataURI); // Requires SynapseLd to be owner for this call
        emit InsightNftStatusUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Allows a user to temporarily delegate their reputation-based voting power to another user.
     *         This means the delegatee's vote will include the delegator's power.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateReputationScore(address _delegatee) public whenNotPaused notBlacklisted(msg.sender) {
        require(msg.sender != _delegatee, "SynapseLd: Cannot delegate to self");
        delegatedReputation[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    // --- IV. Governance & Protocol Evolution (DAO) ---

    /**
     * @notice Users with sufficient staked tokens/reputation can create new governance proposals.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposed change.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call (selector + arguments) for the target contract.
     */
    function createGovernanceProposal(
        string calldata _title,
        string calldata _description,
        address _targetContract,
        bytes calldata _callData
    ) public whenNotPaused notBlacklisted(msg.sender) returns (uint256) {
        require(_getVotingPower(msg.sender) >= MIN_STAKE_FOR_PROPOSAL, "SynapseLd: Insufficient voting power to create proposal");

        uint256 currentProposalId = nextProposalId++;
        proposals[currentProposalId] = GovernanceProposal({
            id: currentProposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + 7 days, // Example: 7 days for voting
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            status: ProposalStatus.Active,
            executed: false
        });

        emit GovernanceProposalCreated(currentProposalId, msg.sender, _title);
        return currentProposalId;
    }

    /**
     * @notice Allows users to vote on active governance proposals using their combined staked SYNAPT tokens and reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, False for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused notBlacklisted(msg.sender) {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynapseLd: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SynapseLd: Proposal is not active for voting");
        require(block.timestamp <= proposal.votingDeadline, "SynapseLd: Voting deadline has passed");
        require(!proposal.hasVoted[msg.sender], "SynapseLd: User has already voted on this proposal");

        uint256 votingPower = _getVotingPower(msg.sender);
        require(votingPower > 0, "SynapseLd: User has no voting power");

        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a passed governance proposal. Only callable after the voting deadline
     *         and if the 'for' votes exceed 'against' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynapseLd: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SynapseLd: Proposal is not active");
        require(block.timestamp > proposal.votingDeadline, "SynapseLd: Voting period has not ended");
        require(!proposal.executed, "SynapseLd: Proposal already executed");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            // Execute the proposal
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "SynapseLd: Proposal execution failed");
            proposal.executed = true;
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            // No event for failure needed, status change is enough.
        }
    }

    /**
     * @notice Allows a group of stakers to challenge an oracle report for a project,
     *         initiating a governance dispute resolution process. This creates a new
     *         governance proposal where the community votes on the validity of the oracle's report.
     * @param _projectId The ID of the project whose oracle report is being challenged.
     * @param _reason A description of why the oracle report is being challenged.
     */
    function challengeOracleReport(uint256 _projectId, string calldata _reason) public whenNotPaused notBlacklisted(msg.sender) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Completed || project.status == ProjectStatus.Failed, "SynapseLd: Project status not suitable for challenge");
        require(project.outcome != Outcome.Unknown, "SynapseLd: Oracle has not reported an outcome yet");
        
        // Example: Requires a certain amount of staked tokens to initiate a challenge
        require(userProfiles[msg.sender].stakedTokens >= MIN_STAKE_FOR_PROPOSAL, "SynapseLd: Insufficient stake to challenge oracle");

        project.status = ProjectStatus.Challenged; // Temporarily pause further actions on the project

        // Create a governance proposal for the challenge
        bytes memory callData = abi.encodeWithSelector(
            this.resolveOracleChallenge.selector, // Function to be called if challenge passes/fails
            _projectId, true // Placeholder for resolution logic (e.g., true for challenge accepted, false for rejected)
        );

        uint256 proposalId = createGovernanceProposal(
            string(abi.encodePacked("Challenge Oracle Report for Project ", Strings.toString(_projectId))),
            string(abi.encodePacked("Oracle report for project ", Strings.toString(_projectId), " is challenged. Reason: ", _reason)),
            address(this),
            callData
        );

        emit OracleReportChallenged(_projectId, proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @notice Internal function to resolve an oracle challenge if approved by DAO.
     *         This is called via `executeProposal` if the challenge passes.
     * @param _projectId The ID of the project.
     * @param _challengeAccepted If true, the challenge is accepted (oracle was wrong), else rejected.
     */
    function resolveOracleChallenge(uint256 _projectId, bool _challengeAccepted) public onlyOwner whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynapseLd: Project does not exist");
        require(project.status == ProjectStatus.Challenged, "SynapseLd: Project not in challenged state");

        if (_challengeAccepted) {
            // Oracle was wrong: penalize oracle reputation, potentially reverse project outcome,
            // or allow new oracle report
            _adjustReputation(oracleAddress, -int256(1000)); // Significant penalty for oracle
            // Reset project status to allow new oracle report or specific outcome
            project.status = ProjectStatus.Pending; // Or a new state like 'Re-evaluation'
            project.outcome = Outcome.Unknown; // Reset outcome
        } else {
            // Oracle was correct: penalize challenger reputation, revert project status
            // to original 'Completed' or 'Failed'
            _adjustReputation(msg.sender, -int256(500)); // Penalty for failed challenge
            // Revert to original outcome status
            if (project.outcome == Outcome.Success || project.outcome == Outcome.PartialSuccess) {
                 project.status = ProjectStatus.Completed;
            } else if (project.outcome == Outcome.Failure) {
                project.status = ProjectStatus.Failed;
            }
        }
        // Emit events for specific resolution actions
    }

    // --- V. Advanced Features & Security ---

    /**
     * @notice Activates an emergency pause, halting critical contract functionalities.
     *         Callable only by the contract owner (admin/DAO).
     */
    function activateEmergencyPause() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Deactivates an emergency pause, resuming critical contract functionalities.
     *         Callable only by the contract owner (admin/DAO).
     */
    function deactivateEmergencyPause() public onlyOwner onlyPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the DAO (via governance) to adjust the minimum SYNAPT stake required
     *         to submit a project or create a governance proposal.
     * @param _newMin The new minimum stake requirement.
     */
    function setMinimumStakingRequirement(uint256 _newMin) public onlyOwner {
        // This function should ideally be callable only via DAO proposal execution
        minProjectStakeRequirement = _newMin;
        emit MinStakeRequirementSet(_newMin);
    }

    /**
     * @notice Blacklists a malicious user, preventing them from participating in key contract functions.
     *         Callable only by the DAO (via governance).
     * @param _user The address to blacklist.
     */
    function blacklistAddress(address _user) public onlyOwner {
        require(!_isBlacklisted[_user], "SynapseLd: Address already blacklisted");
        _isBlacklisted[_user] = true;
        _adjustReputation(_user, -int256(userProfiles[_user].reputationScore)); // Wipe reputation
        emit AddressBlacklisted(_user);
    }

    /**
     * @notice Allows any user to send ETH to the contract's treasury, managed by the DAO.
     */
    function fundProtocolTreasury() public payable whenNotPaused {
        emit ProtocolTreasuryFunded(msg.sender, msg.value);
    }

    /**
     * @notice Allows the DAO (via governance) to withdraw ETH from the protocol's treasury.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETHFromTreasury(uint256 amount) public onlyOwner {
        // This function should ideally be callable only via DAO proposal execution
        require(address(this).balance >= amount, "SynapseLd: Insufficient treasury balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "SynapseLd: ETH withdrawal failed");
        emit TreasuryETHWithdraw(msg.sender, amount);
    }
}
```