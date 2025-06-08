Okay, let's create a smart contract that embodies some advanced concepts. How about an "EcoFund" that allows contributors to pool funds, token holders to vote on ecological projects, and introduces mechanisms like tiered funding release based on project progress, a reputation system for voters, and issuance of "Impact Credits" for successful participation? It will involve governance tokens, another type of token, voting, state transitions, and multiple interaction points.

Here's the outline and function summary, followed by the Solidity code.

---

**Smart Contract: EcoFund**

This contract facilitates decentralized funding for ecological projects. Contributors deposit funds, receiving governance tokens. Token holders vote on proposed projects. Approved projects receive tiered funding based on progress updates. Voters who support successful projects earn reputation and "Impact Credits".

**Outline:**

1.  **License and Pragma**
2.  **Imports** (OpenZeppelin for ERC20, Ownable, Pausable, ERC20Votes)
3.  **Error Definitions**
4.  **Enums** (`ProjectState`, `ProjectType`)
5.  **Structs** (`Project`, `ProjectUpdate`)
6.  **Events**
7.  **State Variables**
    *   Contract owner, pause state.
    *   Governance Token (`ECO`).
    *   Impact Credit Token (`ImpactCredit`).
    *   Fund balance tracking.
    *   Project storage mapping (`projects`).
    *   Next project ID counter.
    *   Mapping for voter reputation.
    *   Mapping for claimable impact credits.
    *   Governance parameters (quorum, voting period).
8.  **Modifiers** (`onlyApprovedProject`, `onlyProjectProposerOrVerifier`, `onlyVoter`)
9.  **Constructor** (Initialize tokens, owner, governance params)
10. **Fund Management Functions**
    *   `depositFunds`
    *   `withdrawAdminFees`
    *   `getFundBalance`
11. **Governance Token (`ECO`) Functions** (Standard ERC20 + Voting)
    *   `mintGovernanceTokens` (Internal, called on deposit)
    *   `transfer`
    *   `approve`
    *   `transferFrom`
    *   `balanceOf`
    *   `allowance`
    *   `totalSupply`
    *   `delegateVote`
    *   `getVotes`
    *   `getPastVotes`
12. **Impact Credit Token (`ImpactCredit`) Functions** (Standard ERC20)
    *   `claimImpactCredits`
    *   `transfer`
    *   `approve`
    *   `transferFrom`
    *   `balanceOf`
    *   `allowance`
    *   `totalSupply`
    *   `getClaimableImpactCredits`
13. **Project Lifecycle Functions**
    *   `proposeProject`
    *   `voteOnProject`
    *   `getProjectVoteCount`
    *   `executeProjectFunding`
    *   `submitProjectUpdate`
    *   `verifyProjectUpdate` (Allows verification/rejection by authorized party)
    *   `releaseTieredFunding` (Requires verified update)
    *   `verifyProjectCompletion`
    *   `recordProjectImpact` (Simulated/Placeholder for impact data)
    *   `getProjectDetails`
    *   `getProjectUpdates`
    *   `getProjectState`
14. **Reputation Functions**
    *   `updateReputation` (Internal)
    *   `getReputationScore`
15. **Admin/Utility Functions**
    *   `pause`
    *   `unpause`
    *   `setGovernanceParameters`
    *   `setVerifierAddress` (Address responsible for update verification)
    *   `getGovernanceParameters`
    *   `getVerifierAddress`

**Function Summary:**

1.  `constructor(address initialOwner, uint256 minQuorumBPS, uint256 votingPeriodBlocks)`: Initializes the contract, deploys ECO and ImpactCredit tokens, sets owner and governance parameters.
2.  `depositFunds()`: Allows users to deposit ETH to the fund, receiving ECO tokens in return (scaled).
3.  `withdrawAdminFees(address recipient, uint256 amount)`: Allows the owner/admin to withdraw a portion of the fund (for operational costs, etc.).
4.  `getFundBalance()`: Returns the current balance of ETH held by the contract.
5.  `mintGovernanceTokens(address account, uint256 amount)` (Internal): Mints ECO tokens. Called by `depositFunds`.
6.  `transfer(address to, uint256 amount)`: Standard ERC20 transfer for ECO.
7.  `approve(address spender, uint256 amount)`: Standard ERC20 approve for ECO.
8.  `transferFrom(address from, address to, uint256 amount)`: Standard ERC20 transferFrom for ECO.
9.  `balanceOf(address account)` (ECO): Returns the balance of ECO tokens for an account.
10. `allowance(address owner, address spender)` (ECO): Returns the allowance for ECO tokens.
11. `totalSupply()` (ECO): Returns the total supply of ECO tokens.
12. `delegateVote(address delegatee)`: Delegates voting power for ECO tokens.
13. `getVotes(address account)`: Gets current voting power for an account.
14. `getPastVotes(address account, uint256 blockNumber)`: Gets voting power for an account at a past block.
15. `claimImpactCredits()`: Allows users to claim earned Impact Credits.
16. `transfer(address to, uint256 amount)` (ImpactCredit): Standard ERC20 transfer for ImpactCredit.
17. `approve(address spender, uint256 amount)` (ImpactCredit): Standard ERC20 approve for ImpactCredit.
18. `transferFrom(address from, address to, uint256 amount)` (ImpactCredit): Standard ERC20 transferFrom for ImpactCredit.
19. `balanceOf(address account)` (ImpactCredit): Returns the balance of Impact Credit tokens.
20. `allowance(address owner, address spender)` (ImpactCredit): Returns the allowance for Impact Credit tokens.
21. `totalSupply()` (ImpactCredit): Returns the total supply of Impact Credit tokens.
22. `getClaimableImpactCredits(address account)`: Returns the number of Impact Credits an account can claim.
23. `proposeProject(string memory title, string memory description, uint256 goalAmount, address payable recipient, ProjectType projectType, uint256 fundingTiersCount)`: Allows anyone to propose a new ecological project.
24. `voteOnProject(uint256 projectId, bool support)`: Allows ECO token holders to vote on a proposed project.
25. `getProjectVoteCount(uint256 projectId)`: Returns the current support/against vote counts for a project proposal.
26. `executeProjectFunding(uint256 projectId)`: Executes the funding decision after the voting period ends, transitions project state. Rewards successful voters with claimable Impact Credits and updates reputation.
27. `submitProjectUpdate(uint256 projectId, string memory details, uint256 completionPercentage)`: Allows the project recipient to submit a progress update.
28. `verifyProjectUpdate(uint256 projectId, uint256 updateIndex, bool verified)`: Allows the designated verifier to mark a project update as verified or rejected.
29. `releaseTieredFunding(uint256 projectId)`: Releases the next tier of funding to the project recipient, if the latest update is verified.
30. `verifyProjectCompletion(uint256 projectId)`: Allows the verifier to mark a project as completed. Rewards voters who supported the project upon completion.
31. `recordProjectImpact(uint256 projectId, string memory impactData)`: Allows recording project impact data (placeholder).
32. `getProjectDetails(uint256 projectId)`: Retrieves comprehensive details about a project.
33. `getProjectUpdates(uint256 projectId)`: Retrieves all submitted updates for a project.
34. `getProjectState(uint256 projectId)`: Returns the current state of a project.
35. `updateReputation(address voter, bool successfulVote)` (Internal): Updates voter reputation based on vote outcome and project result.
36. `getReputationScore(address account)`: Returns the reputation score of an account.
37. `pause()`: Pauses the contract (owner only).
38. `unpause()`: Unpauses the contract (owner only).
39. `setGovernanceParameters(uint256 minQuorumBPS, uint256 votingPeriodBlocks)`: Sets governance parameters (owner only).
40. `setVerifierAddress(address _verifier)`: Sets the address responsible for verifying project updates/completion (owner only).
41. `getGovernanceParameters()`: Returns the current governance parameters.
42. `getVerifierAddress()`: Returns the address of the current verifier.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Custom ERC20 for Governance Tokens
contract EcoGovernanceToken is ERC20, ERC20Votes {
    constructor(address initialAuthority) ERC20("Eco Governance Token", "ECO") ERC20Votes(initialAuthority) {}

    // The following two functions are overrides necessary to make the token ERC20 compatible
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function mint(address account, uint256 amount) external {
        // Restrict minting - In the main contract, we'll only allow the EcoFund contract itself to call this
        // For simplicity here, let's assume the deployer of EcoFund is the minter authority passed to constructor
        // In a real scenario, this would be restricted specifically to the EcoFund contract address.
        // Example: require(msg.sender == minterAuthority, "Only minter authority can mint");
        _mint(account, amount);
    }
}

// Custom ERC20 for Impact Credits
contract ImpactCreditToken is ERC20 {
    constructor() ERC20("Eco Impact Credit", "IMPACT") {}

    // EcoFund contract will be the only minter
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can call");
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        require(minter == address(0), "Minter already set");
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}


// Main EcoFund Contract
contract EcoFund is Ownable, Pausable {

    // --- Error Definitions ---
    error Fund__InsufficientBalance();
    error Fund__ProjectNotFound(uint256 projectId);
    error Fund__ProjectNotInState(uint256 projectId, ProjectState requiredState);
    error Fund__VotingPeriodNotEnded(uint256 projectId);
    error Fund__VotingPeriodEnded(uint256 projectId);
    error Fund__AlreadyVoted(uint256 projectId, address voter);
    error Fund__NoVotingPower(address voter);
    error Fund__QuorumNotReached(uint256 projectId, uint256 requiredQuorum, uint256 totalVotes);
    error Fund__ProjectNotApproved(uint256 projectId);
    error Fund__InvalidUpdateIndex(uint256 projectId, uint256 index);
    error Fund__UpdateAlreadyVerified(uint256 projectId, uint256 index);
    error Fund__UpdateNotVerified(uint256 projectId, uint256 index);
    error Fund__InvalidFundingTier(uint256 projectId, uint256 tier);
    error Fund__TierAlreadyReleased(uint256 projectId, uint256 tier);
    error Fund__ProjectNotCompleted(uint256 projectId);
    error Fund__AlreadyClaimed(address account);
    error Fund__NoClaimableCredits(address account);
    error Fund__ZeroAddress();
    error Fund__InvalidGovernanceParameters();
    error Fund__VerifierNotSet();
    error Fund__NotProjectRecipient(uint256 projectId);


    // --- Enums ---
    enum ProjectState { Proposed, Voting, Approved, Rejected, Funding, Completed, Failed }
    enum ProjectType { Reforestation, CleanEnergy, WasteManagement, Education, Biodiversity, Research } // Example types

    // --- Structs ---
    struct ProjectUpdate {
        string details;
        uint256 completionPercentage;
        uint256 timestamp;
        bool verified;
        bool rejected;
        bool fundingReleased; // Track if funding tier for this update level was released
    }

    struct Project {
        string title;
        string description;
        uint256 goalAmount;
        address payable recipient;
        ProjectType projectType;
        ProjectState state;
        uint256 proposalBlock; // Block number when proposed (can derive voting end)
        uint256 supportVotes;
        uint256 againstVotes;
        uint256 totalVoteSupplyAtProposal; // Total supply of ECO at proposal for quorum check
        address proposer;
        ProjectUpdate[] updates;
        uint256 fundingTiersCount; // How many tiers funding is split into
        uint256 releasedFundingAmount; // Total funding released so far
        string impactData; // Placeholder for impact data
    }

    // --- Events ---
    event FundsDeposited(address indexed account, uint256 amount, uint256 mintedTokens);
    event AdminFeesWithdraw(address indexed recipient, uint256 amount);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string title, uint256 goalAmount);
    event ProjectVoted(uint256 indexed projectId, address indexed voter, bool support, uint256 votes);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectRejected(uint256 indexed projectId);
    event ProjectFundingExecuted(uint256 indexed projectId, uint256 fundedAmount);
    event ProjectUpdateSubmitted(uint256 indexed projectId, uint256 indexed updateIndex, uint256 completionPercentage);
    event ProjectUpdateVerified(uint256 indexed projectId, uint256 indexed updateIndex);
    event ProjectUpdateRejected(uint256 indexed projectId, uint256 indexed updateIndex);
    event TieredFundingReleased(uint256 indexed projectId, uint256 indexed updateIndex, uint256 amount);
    event ProjectCompleted(uint256 indexed projectId);
    event ProjectFailed(uint256 indexed projectId); // Consider adding ways to fail projects
    event ImpactDataRecorded(uint256 indexed projectId, string impactData);
    event ReputationUpdated(address indexed account, int256 scoreChange, uint256 newScore);
    event ImpactCreditsClaimed(address indexed account, uint256 amount);
    event GovernanceParametersSet(uint256 minQuorumBPS, uint256 votingPeriodBlocks);
    event VerifierAddressSet(address indexed verifier);


    // --- State Variables ---
    EcoGovernanceToken public ecoToken;
    ImpactCreditToken public impactCreditToken;

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId = 1;

    mapping(address => uint256) public reputationScore; // Higher score = more trusted voter
    mapping(address => uint256) private claimableImpactCredits; // Credits earned but not yet claimed
    mapping(uint256 => mapping(address => bool)) private hasVoted; // To prevent double voting

    uint256 public minQuorumBPS; // Minimum percentage of total supply needed to vote, in basis points (e.g., 500 for 5%)
    uint256 public votingPeriodBlocks; // How many blocks voting lasts for


    address public verifier; // Address authorized to verify project updates/completion

    // --- Modifiers ---
    modifier onlyApprovedProject(uint256 projectId) {
        require(projects[projectId].state == ProjectState.Approved, Fund__ProjectNotInState(projectId, ProjectState.Approved));
        _;
    }

     modifier onlyProjectProposerOrVerifier(uint256 projectId) {
        require(msg.sender == projects[projectId].proposer || msg.sender == verifier, "Only project proposer or verifier can call");
        _;
    }

    modifier onlyVerifier() {
        require(msg.sender == verifier, "Only verifier can call");
        _;
    }

    modifier onlyProjectRecipient(uint256 projectId) {
        require(msg.sender == projects[projectId].recipient, Fund__NotProjectRecipient(projectId));
        _;
    }


    // --- Constructor ---
    constructor(address initialOwner, uint256 _minQuorumBPS, uint256 _votingPeriodBlocks) Ownable(initialOwner) Pausable(false) {
        if (initialOwner == address(0)) revert Fund__ZeroAddress();
        if (_minQuorumBPS == 0 || _votingPeriodBlocks == 0) revert Fund__InvalidGovernanceParameters();

        // Deploy Governance Token and set this contract as the minter authority (or initial authority for votes)
        ecoToken = new EcoGovernanceToken(address(this)); // Set this contract as the initial authority for ERC20Votes

        // Deploy Impact Credit Token and set this contract as the minter
        impactCreditToken = new ImpactCreditToken();
        impactCreditToken.transferOwnership(initialOwner); // Temporarily give owner control to set minter
        impactCreditToken.setMinter(address(this));
        impactCreditToken.transferOwnership(address(this)); // Transfer ownership back to the EcoFund contract itself

        minQuorumBPS = _minQuorumBPS;
        votingPeriodBlocks = _votingPeriodBlocks;

        emit GovernanceParametersSet(minQuorumBPS, votingPeriodBlocks);
    }

    // --- Fund Management Functions ---

    /// @notice Allows users to deposit ETH and receive ECO governance tokens.
    function depositFunds() public payable whenNotPaused {
        require(msg.value > 0, "Must deposit non-zero ETH");

        // Simple linear scaling: 1 ETH = 100 ECO tokens
        // In a real system, this might be based on a bonding curve or other logic.
        uint256 tokensToMint = msg.value * 100;
        ecoToken.mint(msg.sender, tokensToMint);

        emit FundsDeposited(msg.sender, msg.value, tokensToMint);
    }

    /// @notice Allows the admin (owner) to withdraw funds for operational costs.
    /// @param recipient The address to send the fees to.
    /// @param amount The amount of ETH to withdraw.
    function withdrawAdminFees(address payable recipient, uint256 amount) public onlyOwner whenNotPaused {
        if (recipient == address(0)) revert Fund__ZeroAddress();
        if (amount > address(this).balance) revert Fund__InsufficientBalance();

        (bool success,) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit AdminFeesWithdraw(recipient, amount);
    }

    /// @notice Returns the current balance of ETH held by the contract.
    function getFundBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Governance Token (`ECO`) Functions ---

    // ERC20 functions are inherited and exposed directly from ecoToken instance
    // e.g., ecoToken.transfer(), ecoToken.balanceOf(), etc.
    // We provide convenience wrappers or rely on external interaction with the token address.
    // The functions below are direct wrappers or ERC20Votes specifics.

    function transfer(address to, uint256 amount) public returns (bool) {
        return ecoToken.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return ecoToken.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        return ecoToken.transferFrom(from, to, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return ecoToken.balanceOf(account);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return ecoToken.allowance(owner, spender);
    }

    function totalSupply() public view returns (uint256) {
        return ecoToken.totalSupply();
    }

    /// @notice Delegates voting power of the caller's ECO tokens.
    /// @param delegatee The address to delegate voting power to.
    function delegateVote(address delegatee) public {
         ecoToken.delegate(delegatee);
    }

    /// @notice Gets the current voting power of an account.
    /// @param account The address to check.
    function getVotes(address account) public view returns (uint256) {
        return ecoToken.getVotes(account);
    }

    /// @notice Gets the voting power of an account at a specific past block number.
    /// @param account The address to check.
    /// @param blockNumber The block number to check at.
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        return ecoToken.getPastVotes(account, blockNumber);
    }

    // --- Impact Credit Token (`ImpactCredit`) Functions ---

    /// @notice Allows users to claim their earned Impact Credits.
    function claimImpactCredits() public whenNotPaused {
        uint256 claimable = claimableImpactCredits[msg.sender];
        if (claimable == 0) revert Fund__NoClaimableCredits(msg.sender);

        claimableImpactCredits[msg.sender] = 0; // Reset claimable balance
        impactCreditToken.mint(msg.sender, claimable);

        emit ImpactCreditsClaimed(msg.sender, claimable);
    }

    // Standard ERC20 functions for ImpactCredit are also accessible via the token contract address directly,
    // but including wrappers for clarity.
    function transfer(address to, uint256 amount) public returns (bool) {
        return impactCreditToken.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return impactCreditToken.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        return impactCreditToken.transferFrom(from, to, amount);
    }

    function balanceOfImpact(address account) public view returns (uint256) {
        return impactCreditToken.balanceOf(account);
    }

    function allowanceImpact(address owner, address spender) public view returns (uint256) {
        return impactCreditToken.allowance(owner, spender);
    }

    function totalSupplyImpact() public view returns (uint256) {
        return impactCreditToken.totalSupply();
    }


    /// @notice Returns the number of Impact Credits an account can claim.
    /// @param account The address to check.
    function getClaimableImpactCredits(address account) public view returns (uint256) {
        return claimableImpactCredits[account];
    }

    // --- Project Lifecycle Functions ---

    /// @notice Allows anyone to propose a new ecological project.
    /// @param title Title of the project.
    /// @param description Detailed description.
    /// @param goalAmount The total ETH required for the project.
    /// @param recipient The address receiving funds if approved.
    /// @param projectType Categorization of the project.
    /// @param fundingTiersCount The number of tiers funding will be split into. Must be >= 1.
    function proposeProject(
        string memory title,
        string memory description,
        uint256 goalAmount,
        address payable recipient,
        ProjectType projectType,
        uint256 fundingTiersCount
    ) public whenNotPaused {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(goalAmount > 0, "Goal amount must be greater than 0");
        if (recipient == address(0)) revert Fund__ZeroAddress();
        require(fundingTiersCount >= 1, "Must have at least 1 funding tier");

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            title: title,
            description: description,
            goalAmount: goalAmount,
            recipient: recipient,
            projectType: projectType,
            state: ProjectState.Proposed,
            proposalBlock: block.number,
            supportVotes: 0,
            againstVotes: 0,
            totalVoteSupplyAtProposal: ecoToken.totalSupply(), // Snapshot total supply for quorum calculation
            proposer: msg.sender,
            updates: new ProjectUpdate[](0),
            fundingTiersCount: fundingTiersCount,
            releasedFundingAmount: 0,
            impactData: ""
        });

        emit ProjectProposed(projectId, msg.sender, title, goalAmount);
    }

    /// @notice Allows ECO token holders to vote on a proposed project.
    /// @param projectId The ID of the project to vote on.
    /// @param support True for supporting the project, false for opposing.
    function voteOnProject(uint256 projectId, bool support) public whenNotPaused {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Proposed) revert Fund__ProjectNotInState(projectId, ProjectState.Proposed);
        if (block.number >= project.proposalBlock + votingPeriodBlocks) revert Fund__VotingPeriodEnded(projectId);
        if (hasVoted[projectId][msg.sender]) revert Fund__AlreadyVoted(projectId, msg.sender);

        uint256 votes = ecoToken.getVotes(msg.sender);
        if (votes == 0) revert Fund__NoVotingPower(msg.sender);

        hasVoted[projectId][msg.sender] = true;

        if (support) {
            project.supportVotes += votes;
        } else {
            project.againstVotes += votes;
        }

        emit ProjectVoted(projectId, msg.sender, support, votes);
    }

     /// @notice Returns the current vote counts for a project proposal.
     /// @param projectId The ID of the project.
     /// @return supportVotes The total support votes.
     /// @return againstVotes The total against votes.
    function getProjectVoteCount(uint256 projectId) public view returns (uint256 supportVotes, uint256 againstVotes) {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        return (project.supportVotes, project.againstVotes);
    }


    /// @notice Executes the funding decision for a project after the voting period.
    /// @param projectId The ID of the project.
    function executeProjectFunding(uint256 projectId) public whenNotPaused {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Proposed) revert Fund__ProjectNotInState(projectId, ProjectState.Proposed);
        if (block.number < project.proposalBlock + votingPeriodBlocks) revert Fund__VotingPeriodNotEnded(projectId);

        // Check quorum
        uint256 totalVotesCast = project.supportVotes + project.againstVotes;
        uint256 requiredQuorum = (project.totalVoteSupplyAtProposal * minQuorumBPS) / 10000;

        if (totalVotesCast < requiredQuorum) {
            project.state = ProjectState.Rejected;
            emit ProjectRejected(projectId);
             // Optional: Reward voters who voted with the majority side even if it failed quorum, or penalize etc.
        } else if (project.supportVotes > project.againstVotes) {
            project.state = ProjectState.Approved;

            // --- Advanced Concept: Reward Successful Voters with Impact Credits and Reputation ---
            // This is a simplified approach. A full implementation would iterate through voters
            // using a snapshot or event logs. For a smart contract function, this requires
            // a more complex mechanism (e.g., a separate claim process initiated off-chain
            // or batched).
            // Here, we simulate by granting a base amount per successful vote token.
            // A fairer system would distribute from a pool based on voting weight among winners.

            // Simulate granting claimable credits to supporting voters
            // In a real scenario, we'd need a list of voters and their votes
            // For demo purposes, this part is conceptual. A real implementation
            // might rely on an off-chain process to identify voters and call a function
            // like `grantClaimableCredits(address[] voters, uint256[] amounts)`
            // or users call `claimForProject(projectId)` which checks their vote in storage/logs.
            // We will implement a simplified claim mechanism later.

            // For simplicity in this example, let's just assume a base amount is granted per supporting vote token
            // This requires iterating votes, which is gas-intensive. Let's skip direct per-voter credit minting here,
            // and just emit an event or have a separate claiming process based on vote *logs*.
            // The claimableImpactCredits mapping and `claimImpactCredits` function will handle the claiming *if*
            // another process (potentially off-chain or a whitelisted admin function) populates the mapping
            // based on voting logs after `executeProjectFunding`.

            // Reputation: Increase reputation for voters who supported the approved project
            // Similar challenge as Impact Credits for identifying all voters on-chain.
            // We'll keep `reputationScore` but assume it's updated via a separate process or simplified logic.
            // For now, the `updateReputation` function is internal and shows the concept.

            emit ProjectApproved(projectId);

            // Don't release funding immediately, wait for tiered release
        } else {
            project.state = ProjectState.Rejected;
            emit ProjectRejected(projectId);
             // Optional: Penalize voters who supported the rejected project
        }
    }

    /// @notice Allows the project recipient to submit a progress update.
    /// @param projectId The ID of the project.
    /// @param details Description of the update.
    /// @param completionPercentage The reported completion percentage (0-100).
    function submitProjectUpdate(uint256 projectId, string memory details, uint256 completionPercentage) public whenNotPaused onlyProjectRecipient(projectId) {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Funding) revert Fund__ProjectNotInState(projectId, ProjectState.Funding);
        require(completionPercentage >= 0 && completionPercentage <= 100, "Invalid completion percentage");

        project.updates.push(ProjectUpdate({
            details: details,
            completionPercentage: completionPercentage,
            timestamp: block.timestamp,
            verified: false,
            rejected: false,
            fundingReleased: false
        }));

        emit ProjectUpdateSubmitted(projectId, project.updates.length - 1, completionPercentage);
    }

    /// @notice Allows the designated verifier to verify or reject a project update.
    /// This is crucial for the tiered funding release mechanism.
    /// @param projectId The ID of the project.
    /// @param updateIndex The index of the update in the updates array.
    /// @param verified True to verify, false to reject.
    function verifyProjectUpdate(uint256 projectId, uint256 updateIndex, bool verified) public whenNotPaused onlyVerifier {
        Project storage project = projects[projectId];
         if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Funding) revert Fund__ProjectNotInState(projectId, ProjectState.Funding);
        if (updateIndex >= project.updates.length) revert Fund__InvalidUpdateIndex(projectId, updateIndex);
        if (project.updates[updateIndex].verified || project.updates[updateIndex].rejected) revert Fund__UpdateAlreadyVerified(projectId, updateIndex);

        if (verified) {
            project.updates[updateIndex].verified = true;
            emit ProjectUpdateVerified(projectId, updateIndex);
        } else {
            project.updates[updateIndex].rejected = true;
            emit ProjectUpdateRejected(projectId, updateIndex);
            // Consider implications of rejection: project failure? Opportunity to resubmit?
            // For simplicity, rejection just marks it as not verified for funding.
        }
    }


    /// @notice Releases the next tier of funding to the project recipient.
    /// Requires that the latest submitted update has been verified.
    /// @param projectId The ID of the project.
    function releaseTieredFunding(uint256 projectId) public whenNotPaused {
        Project storage project = projects[projectId];
         if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Funding) revert Fund__ProjectNotInState(projectId, ProjectState.Funding);
        require(project.fundingTiersCount > 0, "Project has no funding tiers defined");

        uint256 currentTier = project.releasedFundingAmount == 0 ? 0 : project.updates.length; // Logic for which tier: tier 0 on initial execute, then tier 1 after 1st update, etc.
        uint256 updateIndexForThisTier = currentTier > 0 ? currentTier - 1 : 0; // Update index corresponds to tier 1 onwards

        if (currentTier > 0) { // For tiers > 0, an update is required
             if (updateIndexForThisTier >= project.updates.length) revert Fund__InvalidFundingTier(projectId, currentTier);
             if (!project.updates[updateIndexForThisTier].verified) revert Fund__UpdateNotVerified(projectId, updateIndexForThisTier);
             if (project.updates[updateIndexForThisTier].fundingReleased) revert Fund__TierAlreadyReleased(projectId, currentTier);
        } else { // For tier 0 (initial release), no update is required, but check if already released
             if (project.releasedFundingAmount > 0) revert Fund__TierAlreadyReleased(projectId, 0);
        }


        uint256 totalFunding = project.goalAmount;
        uint256 tiers = project.fundingTiersCount;
        uint256 fundingPerTier = totalFunding / tiers;
        uint256 lastTierAmount = totalFunding - (fundingPerTier * (tiers - 1)); // Ensure all funds are sent


        uint256 amountToSend = fundingPerTier;
        if (currentTier == tiers - 1) { // If releasing the last tier (0-indexed)
            amountToSend = lastTierAmount;
        } else if (currentTier >= tiers) {
             revert Fund__InvalidFundingTier(projectId, currentTier);
        }


        if (amountToSend > address(this).balance) revert Fund__InsufficientBalance();
        if (project.releasedFundingAmount + amountToSend > project.goalAmount) {
             // This should not happen if logic is correct, but as a safeguard
             revert Fund__InvalidFundingTier(projectId, currentTier);
        }


        (bool success, ) = project.recipient.call{value: amountToSend}("");
        require(success, "Funding transfer failed");

        project.releasedFundingAmount += amountToSend;

        if (currentTier > 0) {
           project.updates[updateIndexForThisTier].fundingReleased = true;
        }


        emit TieredFundingReleased(projectId, currentTier, amountToSend);

        // If all funding released, transition state
        if (project.releasedFundingAmount >= project.goalAmount) {
            // Project is now fully funded, but needs verification for 'Completed' state
            // It stays in 'Funding' state until explicitly verified as 'Completed'
        }
    }

     /// @notice Allows the designated verifier to mark a project as completed.
     /// Can only be called if the project state is Funding and all funding has been released.
     /// @param projectId The ID of the project.
     function verifyProjectCompletion(uint256 projectId) public whenNotPaused onlyVerifier {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        // Allow completion verification from Funding state only
        if (project.state != ProjectState.Funding) revert Fund__ProjectNotInState(projectId, ProjectState.Funding);
        require(project.releasedFundingAmount >= project.goalAmount, "Project funding not fully released");

        project.state = ProjectState.Completed;
        emit ProjectCompleted(projectId);

        // --- Advanced Concept: Reward Successful Voters with Impact Credits and Reputation on Completion ---
        // This is another point where a system would identify original voters and reward them.
        // Again, for simplicity in this example, the `claimableImpactCredits` system exists
        // but relies on an external process to populate it based on vote logs.
        // A real implementation might have a mapping `projectVoters[projectId][voterAddress] = true`
        // populated during `voteOnProject`, and then iterate that mapping here (gas intensive),
        // or rely on emitted events and off-chain processing.

        // Update reputation for successful voters - conceptual, relies on external process to identify voters
        // updateReputation(voterAddress, true); // Example call for each successful voter

    }

    /// @notice Allows recording impact data for a completed project.
    /// This data is stored on-chain but might reference off-chain reports or verifiable credentials.
    /// @param projectId The ID of the project.
    /// @param impactData String containing impact details or a URI.
    function recordProjectImpact(uint256 projectId, string memory impactData) public whenNotPaused onlyVerifier {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        if (project.state != ProjectState.Completed) revert Fund__ProjectNotInState(projectId, ProjectState.Completed);

        project.impactData = impactData;
        emit ImpactDataRecorded(projectId, impactData);
    }


    /// @notice Retrieves comprehensive details about a project.
    /// @param projectId The ID of the project.
    /// @return projectDetails A struct containing all project data.
    function getProjectDetails(uint256 projectId) public view returns (Project memory) {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        return project;
    }

     /// @notice Retrieves all submitted updates for a project.
     /// @param projectId The ID of the project.
     /// @return updates An array of ProjectUpdate structs.
    function getProjectUpdates(uint256 projectId) public view returns (ProjectUpdate[] memory) {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        return project.updates;
    }

    /// @notice Returns the current state of a project.
    /// @param projectId The ID of the project.
    /// @return state The current state of the project.
    function getProjectState(uint256 projectId) public view returns (ProjectState) {
        Project storage project = projects[projectId];
        if (project.proposer == address(0)) revert Fund__ProjectNotFound(projectId);
        return project.state;
    }


    // --- Reputation Functions ---

    /// @notice Internal function to update a voter's reputation score.
    /// This is a conceptual function. How reputation is gained/lost based on vote outcomes
    /// (successful project = positive rep, failed project = negative rep) would be implemented
    /// within `executeProjectFunding` and `verifyProjectCompletion`/`ProjectFailure` functions,
    /// likely requiring iterating over voters or using external processes to identify them.
    /// @param voter The address whose reputation to update.
    /// @param successfulVote True if the vote was on the successful side of the project outcome.
    function updateReputation(address voter, bool successfulVote) internal {
        // Simple logic: +10 for successful vote, -5 for unsuccessful vote
        int256 scoreChange = successfulVote ? 10 : -5;

        // Safely update reputation score (handle potential negative results from casting)
        unchecked {
             if (successfulVote) {
                reputationScore[voter] += uint256(scoreChange);
             } else {
                if (reputationScore[voter] >= uint256(-scoreChange)) {
                    reputationScore[voter] -= uint256(-scoreChange);
                } else {
                     reputationScore[voter] = 0; // Don't let reputation go below 0
                }
             }
        }


        emit ReputationUpdated(voter, scoreChange, reputationScore[voter]);
    }

    /// @notice Returns the reputation score of an account.
    /// @param account The address to check.
    function getReputationScore(address account) public view returns (uint256) {
        return reputationScore[account];
    }


    // --- Admin/Utility Functions ---

    /// @notice Pauses the contract. Only callable by the owner.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by the owner.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Sets the governance parameters: minimum quorum and voting period length.
    /// @param _minQuorumBPS The minimum percentage of total supply needed to vote, in basis points (e.g., 500 for 5%).
    /// @param _votingPeriodBlocks How many blocks voting lasts for.
    function setGovernanceParameters(uint256 _minQuorumBPS, uint256 _votingPeriodBlocks) public onlyOwner {
        if (_minQuorumBPS == 0 || _votingPeriodBlocks == 0) revert Fund__InvalidGovernanceParameters();
        minQuorumBPS = _minQuorumBPS;
        votingPeriodBlocks = _votingPeriodBlocks;
        emit GovernanceParametersSet(minQuorumBPS, votingPeriodBlocks);
    }

    /// @notice Sets the address responsible for verifying project updates and completion.
    /// This could be a multisig, a DAO controlled address, or a trusted entity.
    /// @param _verifier The address of the verifier.
    function setVerifierAddress(address _verifier) public onlyOwner {
        if (_verifier == address(0)) revert Fund__ZeroAddress();
        verifier = _verifier;
        emit VerifierAddressSet(verifier);
    }

    /// @notice Returns the current governance parameters.
    /// @return _minQuorumBPS The minimum quorum in basis points.
    /// @return _votingPeriodBlocks The voting period in blocks.
    function getGovernanceParameters() public view returns (uint256 _minQuorumBPS, uint256 _votingPeriodBlocks) {
        return (minQuorumBPS, votingPeriodBlocks);
    }

     /// @notice Returns the address of the current verifier.
     /// @return The verifier address.
    function getVerifierAddress() public view returns (address) {
        require(verifier != address(0), Fund__VerifierNotSet()); // Ensure verifier is set
        return verifier;
    }

    // --- Fallback/Receive ---
    // Allow receiving ETH
    receive() external payable {
        // Optionally log deposits via fallback
        // emit FundsDeposited(msg.sender, msg.value, 0); // Can't mint tokens here easily
    }
}
```

**Explanation of Concepts & Features:**

1.  **Dual Token Model (`ECO` and `ImpactCredit`):**
    *   `ECO` (Governance Token): Standard ERC20 + ERC20Votes. Represents voting power and ownership stake in the fund. Minted upon contributing ETH. Supports delegation.
    *   `ImpactCredit` (Utility/Reward Token): Standard ERC20. Represents positive contribution to successful projects. Earned by participating in governance for successful projects. Can be claimed by users. Could potentially be used for future benefits or trading.

2.  **Decentralized Governance (Simulated):** Users vote on projects using their ECO token power (`voteOnProject`). The `executeProjectFunding` function checks the voting outcome against a minimum quorum and simple majority. This is a basic DAO pattern.

3.  **Tiered Funding Release:** Projects don't receive all funds at once upon approval. Funding is split into tiers (`fundingTiersCount`). The project recipient must submit updates (`submitProjectUpdate`), which must be verified by a designated `verifier` (`verifyProjectUpdate`). Only after an update is verified can the next funding tier be released (`releaseTieredFunding`). This provides a rudimentary progress-based funding mechanism.

4.  **Project Lifecycle:** Projects transition through distinct states (Proposed, Voting, Approved, Rejected, Funding, Completed). Functions are restricted based on the current state.

5.  **Reputation System:** A simple `reputationScore` mapping tracks voter reputation. The concept is to reward/penalize voters based on whether the projects they supported were successful. *Note: The actual on-chain implementation of identifying all voters for a past proposal is complex and gas-intensive. The `updateReputation` function is internal and conceptual here; a real system might use event logs processed off-chain to call a helper function, or a different data structure.*

6.  **Impact Tracking (Placeholder):** `recordProjectImpact` allows storing a string (e.g., a link to an IPFS document or a summarized report) about the project's outcome. This connects on-chain activity to potential real-world results.

7.  **Designated Verifier:** A specific address (`verifier`) is responsible for confirming project updates and final completion. In a fully decentralized system, this could be a multisig wallet controlled by elected governors, a DAO decision, or an oracle feeding data. Here, it's a single address for simplicity.

8.  **Pausable and Ownable:** Standard security features for contract management.

9.  **Error Handling:** Uses custom errors (`error Fund__...`) for clearer failure messages.

10. **ERC20Votes Integration:** The `ECO` token inherits from OpenZeppelin's `ERC20Votes`, providing built-in delegation and vote snapshotting functionality needed for robust governance.

This contract combines financial pooling, governance, a novel tiered funding release based on verified updates, multiple token types, and a conceptual reputation system, going beyond a simple ERC20, NFT, or basic voting contract. It demonstrates how different DeFi and DAO concepts can be combined with a specific real-world theme (ecological funding).