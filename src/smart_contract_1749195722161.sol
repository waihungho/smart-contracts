Okay, let's create a smart contract that explores decentralized intellectual property licensing, community curation, and governance – combining aspects of creative economies, social tokens (simulated), and DAOs in a novel way.

We will build a contract called `DecentralizedCreativeCommons` where creators can register their works (linking to off-chain content like IPFS), define licensing terms, users can acquire licenses, and a staked community can curate works and govern the platform parameters.

---

**Contract Outline & Function Summary**

**Contract Name:** `DecentralizedCreativeCommons`

**Purpose:** A decentralized platform for creators to register creative works, define and issue on-chain licenses for their use, and allow a community (staked with a simulated CURATE token) to curate works, handle disputes, and govern protocol parameters. It moves beyond simple NFT ownership to focus on the *licensing* of underlying creative assets.

**Key Concepts:**
*   **Work Registration:** Creators link to their creative work (via a content hash, e.g., IPFS) and define licensing terms.
*   **On-Chain Licensing:** Users acquire non-transferable (in this version) licenses with specific, verifiable terms.
*   **Community Curation:** Staked users can upvote or downvote works, influencing their visibility or reputation.
*   **Dispute Resolution:** A mechanism (simplified) for users to dispute license usage, potentially involving community review.
*   **Governance:** Staked users can propose and vote on changes to platform parameters (fees, staking requirements, etc.).
*   **Creator Earnings:** Creators earn fees when licenses based on their terms are acquired.
*   **Simulated Token:** Uses an internal balance for a simulated staking/governance token (`CURATE`) to avoid external dependencies for this example.

**Data Structures:**
*   `Work`: Details about a registered creative work (creator, metadata, licensing terms, status, curation score).
*   `LicensingTerms`: Defines allowed/disallowed uses for a work (commercial, modification, attribution, etc.).
*   `License`: Represents a specific grant of rights to a user for a particular work under certain terms.
*   `Proposal`: Details for governance proposals (target function, parameters, voting data).

**Function Summary:**

**1. Core Work Management (7 Functions):**
*   `registerWork`: Register a new creative work with initial terms.
*   `updateWorkMetadata`: Creator updates external metadata link/hash.
*   `updateWorkLicensingParams`: Creator updates default licensing terms for *future* licenses of their work.
*   `deactivateWork`: Creator temporarily deactivates a work (prevents new licenses).
*   `reactivateWork`: Creator reactivates a deactivated work.
*   `getWorkDetails`: Retrieve details of a specific work.
*   `getWorksByCreator`: List all works registered by a creator.

**2. Licensing & Usage (7 Functions):**
*   `acquireLicense`: User acquires a license for a work by paying the required fee.
*   `revokeLicense`: Creator revokes a specific license (if contract terms allow, e.g., breach).
*   `disputeLicenseUse`: User or creator initiates a dispute about license usage.
*   `getLicenseDetails`: Retrieve details of a specific license.
*   `getLicensesForWork`: List all active licenses issued for a specific work.
*   `getLicensesByUser`: List all active licenses held by a specific user.
*   `isLicenseValid`: Check if a specific license ID is currently valid and active.

**3. Community Curation (5 Functions):**
*   `stakeCURATE`: Stake simulated CURATE tokens to gain curation and governance power.
*   `unstakeCURATE`: Unstake CURATE tokens.
*   `curateWork`: Cast a curation vote (upvote/downvote) for a work.
*   `getWorkCurationScore`: Get the current community curation score for a work.
*   `getCuratorStake`: Get the staked amount for a specific curator.

**4. Dispute Resolution (Simplified) (3 Functions):**
*   `submitDisputeVote`: Staked curator votes on a pending license usage dispute.
*   `resolveDispute`: Admin/governance executes the outcome of a dispute vote.
*   `getActiveDisputes`: List works/licenses currently under dispute.

**5. Governance (6 Functions):**
*   `submitProposal`: Submit a new governance proposal (e.g., change fees, min stake).
*   `voteOnProposal`: Cast a vote on an active governance proposal.
*   `endProposalVoting`: Anyone can trigger the end of the voting period.
*   `executeProposal`: Execute a successful governance proposal.
*   `getProposalDetails`: Retrieve details of a specific proposal.
*   `getProposals`: List all proposals.

**6. Financial & Fees (2 Functions):**
*   `withdrawCreatorEarnings`: Creator withdraws accumulated earnings from license fees.
*   `withdrawPlatformFees`: Admin withdraws platform fees.

**7. Getters & Helpers (Additional Functions - bringing total over 20):**
*   `getTotalWorks`: Get the total number of registered works.
*   `getTotalLicenses`: Get the total number of issued licenses.
*   `getPlatformFeePercentage`: Get the current platform fee percentage.
*   `getMinCurationStake`: Get the minimum stake required to curate.
*   `getMinStakeForProposal`: Get the minimum stake required to submit a proposal.
*   `getVotingPeriod`: Get the duration of voting periods (for proposals/disputes).
*   `getRequiredVotesForProposal`: Get the percentage of staked votes required for a proposal to pass.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedCreativeCommons
 * @dev A smart contract platform for decentralized creative work licensing,
 *      community curation, dispute resolution, and governance.
 *      Creators register works and define licensing terms. Users acquire
 *      licenses. A staked community curates works and governs parameters.
 */
contract DecentralizedCreativeCommons {

    // --- Contract State ---

    address public immutable owner; // Platform admin
    uint256 private workCounter;
    uint256 private licenseCounter;
    uint256 private proposalCounter;
    uint256 private disputeCounter; // Tracks unique dispute IDs

    // Configuration parameters (governable)
    uint8 public platformFeePercentage = 5; // 5%
    uint256 public minCurationStake = 1 ether; // Minimum CURATE to curate
    uint256 public minStakeForProposal = 10 ether; // Minimum CURATE to submit proposal
    uint256 public votingPeriod = 7 days; // Duration for proposal/dispute voting
    uint256 public requiredVotesForProposal = 60; // Percentage (e.g., 60%) of staked tokens needed to pass

    // Simulated CURATE token balances (simplified internal accounting)
    mapping(address => uint256) private _curateBalances;
    mapping(address => uint256) private _stakedCURATE;
    uint256 private totalStakedCURATE;

    // Financials
    mapping(address => uint256) private creatorEarnings;
    uint256 private platformFees;

    // --- Data Structures ---

    struct LicensingTerms {
        bool commercialUseAllowed;
        bool modificationAllowed;
        bool attributionRequired;
        bool sublicensingAllowed;
        uint8 royaltyPercentageOnAcquisition; // Percentage of license fee for creator
        // Add more granular terms as needed
    }

    struct Work {
        address creator;
        string metadataHash; // e.g., IPFS hash linking to title, description, link to content
        LicensingTerms defaultLicensingTerms;
        bool isActive; // Creator can deactivate work
        uint256 creationTimestamp;
        int256 curationScore; // Community upvotes/downvotes
    }

    struct License {
        uint256 workId;
        address licensee;
        LicensingTerms grantedTerms; // Actual terms granted (can differ from default)
        uint256 acquisitionTimestamp;
        uint256 expirationTimestamp; // 0 for perpetual, otherwise timestamp
        bool isActive; // Can be revoked or expire
    }

    struct Dispute {
        uint256 disputeId;
        uint256 licenseId; // License being disputed
        address initiatedBy;
        uint256 initiationTimestamp;
        string detailsHash; // IPFS hash for dispute details/evidence
        mapping(address => bool) hasVoted; // Voter address => true
        int256 voteTally; // Weighted by stake
        bool resolved;
        bool outcomeForLicensee; // True if licensee wins dispute, false if challenger wins
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description; // IPFS hash for proposal details
        uint256 submissionTimestamp;
        uint256 votingEndTimestamp;
        bytes callData; // The data to call on this contract (or another) if proposal passes
        address target; // Address of the contract to call
        uint256 value; // ETH value to send with the call
        mapping(address => bool) hasVoted; // Voter address => true
        uint256 yesVotes; // Weighted by stake
        uint256 noVotes; // Weighted by stake
        ProposalState state;
    }

    // --- Storage Mappings ---

    mapping(uint256 => Work) public works;
    mapping(address => uint256[]) public worksByCreator; // Creator address => array of workIds

    mapping(uint256 => License) public licenses;
    mapping(uint256 => uint256[]) public licensesForWork; // WorkId => array of licenseIds
    mapping(address => uint256[]) public licensesByUser; // User address => array of licenseIds

    mapping(uint256 => mapping(address => int256)) private workCurationVotes; // workId => voterAddress => vote (+1 or -1)

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => uint256[]) public activeDisputes; // Simple list of active dispute IDs

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => uint256[]) public activeProposals; // Simple list of active proposal IDs

    // --- Events ---

    event WorkRegistered(uint256 workId, address creator, string metadataHash);
    event WorkMetadataUpdated(uint256 workId, string newMetadataHash);
    event WorkLicensingParamsUpdated(uint256 workId, LicensingTerms newTerms);
    event WorkDeactivated(uint256 workId);
    event WorkReactivated(uint256 workId);

    event LicenseAcquired(uint256 licenseId, uint256 workId, address licensee, LicensingTerms grantedTerms, uint256 acquisitionCost);
    event LicenseRevoked(uint256 licenseId, address revokedBy);
    event LicenseDisputeInitiated(uint256 disputeId, uint256 licenseId, address initiatedBy);
    event LicenseDisputeResolved(uint256 disputeId, bool outcomeForLicensee);

    event CURATEStaked(address user, uint256 amount, uint256 newTotalStake);
    event CURATEUnstaked(address user, uint256 amount, uint256 newTotalStake);
    event WorkCurated(uint256 workId, address curator, int8 vote, int256 newScore);

    event ProposalSubmitted(uint256 proposalId, address proposer, string description);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 weightedVotes);
    event ProposalStateChanged(uint256 proposalId, ProposalState newState);
    event ProposalExecuted(uint256 proposalId);

    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyCreator(uint256 _workId) {
        require(works[_workId].creator == msg.sender, "Not creator");
        _;
    }

    modifier onlyLicensee(uint256 _licenseId) {
        require(licenses[_licenseId].licensee == msg.sender, "Not licensee");
        _;
    }

    modifier onlyActiveWork(uint256 _workId) {
        require(works[_workId].isActive, "Work is not active");
        _;
    }

    modifier onlyActiveLicense(uint256 _licenseId) {
        require(licenses[_licenseId].isActive, "License is not active");
        require(licenses[_licenseId].expirationTimestamp == 0 || licenses[_licenseId].expirationTimestamp > block.timestamp, "License expired");
        _;
    }

    modifier onlyCuratorStakeholder() {
        require(_stakedCURATE[msg.sender] >= minCurationStake, "Requires minimum curation stake");
        _;
    }

    modifier onlyGovernorStakeholder(uint256 _requiredStake) {
         require(_stakedCURATE[msg.sender] >= _requiredStake, "Requires minimum governance stake");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        workCounter = 0;
        licenseCounter = 0;
        proposalCounter = 0;
        disputeCounter = 0;
        totalStakedCURATE = 0;
        // NOTE: In a real scenario, CURATE tokens would need to be distributed/minted
        // For this simulation, we'll assume users somehow acquire internal balances
        // A simple way to simulate this for testing:
        // _curateBalances[msg.sender] = 1000 ether; // Give deployer initial simulated balance
    }

    // --- Simulated CURATE Token Functions (Internal) ---
    // These simulate ERC20 behavior necessary for staking without a real token contract dependency.

    function mintSimulatedCURATE(address user, uint256 amount) external onlyOwner {
        // Allows the owner to simulate minting tokens for testing
        _curateBalances[user] += amount;
    }

    function balanceSimulatedCURATE(address user) external view returns (uint256) {
        // Check user's liquid CURATE balance
        return _curateBalances[user];
    }

    // --- Core Work Management (7) ---

    /**
     * @dev Registers a new creative work.
     * @param _metadataHash IPFS hash or link to external metadata.
     * @param _terms Initial default licensing terms for this work.
     */
    function registerWork(string memory _metadataHash, LicensingTerms memory _terms) external {
        workCounter++;
        uint256 workId = workCounter;
        works[workId] = Work(
            msg.sender,
            _metadataHash,
            _terms,
            true,
            block.timestamp,
            0 // Initial curation score
        );
        worksByCreator[msg.sender].push(workId);
        emit WorkRegistered(workId, msg.sender, _metadataHash);
    }

    /**
     * @dev Allows the creator to update the metadata hash for their work.
     * @param _workId The ID of the work to update.
     * @param _newMetadataHash The new IPFS hash or link.
     */
    function updateWorkMetadata(uint256 _workId, string memory _newMetadataHash) external onlyCreator(_workId) {
        works[_workId].metadataHash = _newMetadataHash;
        emit WorkMetadataUpdated(_workId, _newMetadataHash);
    }

    /**
     * @dev Allows the creator to update the default licensing terms for FUTURE licenses.
     *      Existing licenses are NOT affected.
     * @param _workId The ID of the work.
     * @param _newTerms The new default licensing terms.
     */
    function updateWorkLicensingParams(uint256 _workId, LicensingTerms memory _newTerms) external onlyCreator(_workId) {
        works[_workId].defaultLicensingTerms = _newTerms;
        emit WorkLicensingParamsUpdated(_workId, _newTerms);
    }

    /**
     * @dev Allows the creator to deactivate their work. Prevents new licenses from being acquired.
     * @param _workId The ID of the work to deactivate.
     */
    function deactivateWork(uint255 _workId) external onlyCreator(_workId) {
        require(works[_workId].isActive, "Work already inactive");
        works[_workId].isActive = false;
        emit WorkDeactivated(_workId);
    }

     /**
     * @dev Allows the creator to reactivate their work. Allows new licenses to be acquired.
     * @param _workId The ID of the work to reactivate.
     */
    function reactivateWork(uint255 _workId) external onlyCreator(_workId) {
        require(!works[_workId].isActive, "Work already active");
        works[_workId].isActive = true;
        emit WorkReactivated(_workId);
    }


    /**
     * @dev Gets the details of a specific work.
     * @param _workId The ID of the work.
     * @return Work struct details.
     */
    function getWorkDetails(uint256 _workId) external view returns (Work memory) {
        return works[_workId];
    }

     /**
     * @dev Lists all work IDs registered by a specific creator.
     * @param _creator The creator's address.
     * @return An array of work IDs.
     */
    function getWorksByCreator(address _creator) external view returns (uint256[] memory) {
        return worksByCreator[_creator];
    }


    // --- Licensing & Usage (7) ---

    /**
     * @dev Allows a user to acquire a license for a work based on the current default terms.
     *      Calculates and distributes fees.
     * @param _workId The ID of the work to license.
     */
    function acquireLicense(uint256 _workId) external payable onlyActiveWork(_workId) {
        Work storage work = works[_workId];
        LicensingTerms storage terms = work.defaultLicensingTerms;

        // Calculate fees
        uint256 totalFee = msg.value;
        uint256 creatorShare = (totalFee * terms.royaltyPercentageOnAcquisition) / 100;
        uint256 platformShare = (totalFee * platformFeePercentage) / 100;

        // Ensure enough fee is paid
        require(totalFee >= creatorShare + platformShare, "Insufficient license fee sent");

        // Distribute fees (accrue internally)
        creatorEarnings[work.creator] += creatorShare;
        platformFees += platformShare;
        // Any remaining amount is returned or considered part of the fee.
        // For simplicity, we assume exactly the right amount is sent or excess is kept as fee.
        // A more robust version might calculate the required fee first.

        licenseCounter++;
        uint256 licenseId = licenseCounter;

        // Grant the license
        licenses[licenseId] = License(
            _workId,
            msg.sender,
            terms, // Grant terms based on default at time of acquisition
            block.timestamp,
            0, // Perpetual license
            true
        );

        licensesForWork[_workId].push(licenseId);
        licensesByUser[msg.sender].push(licenseId);

        emit LicenseAcquired(licenseId, _workId, msg.sender, terms, totalFee);
    }

    /**
     * @dev Allows the creator (or potentially governance/dispute resolution) to revoke a license.
     *      This might happen due to terms violation (checked off-chain or via dispute).
     * @param _licenseId The ID of the license to revoke.
     */
    function revokeLicense(uint256 _licenseId) external {
        License storage license = licenses[_licenseId];
        require(license.isActive, "License already inactive");

        // Only creator of the work can initiate revocation directly
        // Or add checks for governance/dispute resolution process
        require(works[license.workId].creator == msg.sender || msg.sender == owner, "Not authorized to revoke"); // Added owner as potential revoker for admin control

        license.isActive = false;
        license.expirationTimestamp = block.timestamp; // Mark as expired now
        emit LicenseRevoked(_licenseId, msg.sender);
    }

    /**
     * @dev Allows a user (creator, licensee, or other) to initiate a dispute about license usage.
     *      Requires staking to prevent spam.
     * @param _licenseId The ID of the license in dispute.
     * @param _detailsHash IPFS hash for dispute details and evidence.
     */
    function disputeLicenseUse(uint256 _licenseId, string memory _detailsHash) external onlyCuratorStakeholder {
        // Basic check if license exists and is active
        require(licenses[_licenseId].isActive, "License must be active to dispute");

        // TODO: Add stake locking mechanism for initiator

        disputeCounter++;
        uint256 disputeId = disputeCounter;

        disputes[disputeId] = Dispute(
            disputeId,
            _licenseId,
            msg.sender,
            block.timestamp,
            _detailsHash,
            // hasVoted map is initialized empty
            0, // voteTally
            false, // resolved
            false // outcomeForLicensee - default assumes challenger wins until proven otherwise
        );

        activeDisputes[0].push(disputeId); // Store in a simple array for active disputes

        emit LicenseDisputeInitiated(disputeId, _licenseId, msg.sender);
    }

    /**
     * @dev Gets the details of a specific license.
     * @param _licenseId The ID of the license.
     * @return License struct details.
     */
    function getLicenseDetails(uint256 _licenseId) external view returns (License memory) {
        return licenses[_licenseId];
    }

    /**
     * @dev Lists all active license IDs for a specific work.
     * @param _workId The ID of the work.
     * @return An array of license IDs.
     */
    function getLicensesForWork(uint256 _workId) external view returns (uint256[] memory) {
        // Filter out inactive/expired licenses if needed, or return all associated IDs
        // Returning all associated IDs currently:
        return licensesForWork[_workId];
    }

    /**
     * @dev Lists all active license IDs held by a specific user.
     * @param _user The user's address.
     * @return An array of license IDs.
     */
    function getLicensesByUser(address _user) external view returns (uint256[] memory) {
        // Filter out inactive/expired licenses if needed, or return all associated IDs
        // Returning all associated IDs currently:
        return licensesByUser[_user];
    }

    /**
     * @dev Checks if a specific license ID is currently valid (active and not expired).
     * @param _licenseId The ID of the license.
     * @return True if valid, false otherwise.
     */
    function isLicenseValid(uint256 _licenseId) external view returns (bool) {
        License storage license = licenses[_licenseId];
        if (!license.isActive) return false;
        if (license.expirationTimestamp != 0 && license.expirationTimestamp <= block.timestamp) return false;
        // Add checks related to work status? (e.g., is the work still active?)
        // require(works[license.workId].isActive, "Work for license is inactive"); // Maybe add this check
        return true;
    }


    // --- Community Curation (5) ---

    /**
     * @dev Stakes simulated CURATE tokens to participate in curation and governance.
     * @param _amount The amount of CURATE to stake.
     */
    function stakeCURATE(uint256 _amount) external {
        require(_curateBalances[msg.sender] >= _amount, "Insufficient CURATE balance");
        _curateBalances[msg.sender] -= _amount;
        _stakedCURATE[msg.sender] += _amount;
        totalStakedCURATE += _amount;
        emit CURATEStaked(msg.sender, _amount, _stakedCURATE[msg.sender]);
    }

    /**
     * @dev Unstakes simulated CURATE tokens.
     *      TODO: Add potential cooldown/lockup period.
     * @param _amount The amount of CURATE to unstake.
     */
    function unstakeCURATE(uint256 _amount) external {
        require(_stakedCURATE[msg.sender] >= _amount, "Insufficient staked CURATE");
        // TODO: Implement cooldown/lockup period before tokens are available
        _stakedCURATE[msg.sender] -= _amount;
        totalStakedCURATE -= _amount;
        _curateBalances[msg.sender] += _amount; // Return to liquid balance after cooldown
        emit CURATEUnstaked(msg.sender, _amount, _stakedCURATE[msg.sender]);
    }

    /**
     * @dev Casts a curation vote for a work. Requires minimum stake.
     *      Vote is +1 for upvote, -1 for downvote. Cannot vote twice.
     * @param _workId The ID of the work to curate.
     * @param _vote Must be 1 (upvote) or -1 (downvote).
     */
    function curateWork(uint256 _workId, int8 _vote) external onlyCuratorStakeholder {
        require(_vote == 1 || _vote == -1, "Invalid vote value (must be 1 or -1)");
        require(workCurationVotes[_workId][msg.sender] == 0, "Already voted on this work");

        workCurationVotes[_workId][msg.sender] = _vote;
        works[_workId].curationScore += (_vote * int256(_stakedCURATE[msg.sender])); // Weight vote by stake

        emit WorkCurated(_workId, msg.sender, _vote, works[_workId].curationScore);
    }

     /**
     * @dev Gets the current community curation score for a work.
     * @param _workId The ID of the work.
     * @return The weighted curation score.
     */
    function getWorkCurationScore(uint256 _workId) external view returns (int256) {
        return works[_workId].curationScore;
    }

     /**
     * @dev Gets the staked amount for a specific curator.
     * @param _curator The address of the curator.
     * @return The amount of CURATE staked.
     */
    function getCuratorStake(address _curator) external view returns (uint256) {
        return _stakedCURATE[_curator];
    }


    // --- Dispute Resolution (Simplified) (3) ---

    /**
     * @dev Allows staked curators to vote on an active license dispute.
     * @param _disputeId The ID of the dispute.
     * @param _support True to support the licensee, false to support the challenger.
     */
    function submitDisputeVote(uint256 _disputeId, bool _support) external onlyCuratorStakeholder {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "Dispute already resolved");
        // TODO: Check if voting period is still active

        require(!dispute.hasVoted[msg.sender], "Already voted in this dispute");
        dispute.hasVoted[msg.sender] = true;

        uint256 weightedVote = _stakedCURATE[msg.sender];
        if (_support) {
            dispute.voteTally += int256(weightedVote);
        } else {
            dispute.voteTally -= int256(weightedVote);
        }

        // TODO: Add event for dispute vote cast
    }

    /**
     * @dev Admin or Governance can trigger the resolution of a dispute after voting ends.
     *      In a real system, this would be part of the governance execution.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external onlyOwner { // Simplified to onlyOwner for example
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.resolved, "Dispute already resolved");
        // TODO: Check if voting period has ended and quorum/threshold met

        dispute.resolved = true;

        // Determine outcome based on vote tally
        if (dispute.voteTally >= 0) { // Positive or zero tally favors licensee
            dispute.outcomeForLicensee = true;
            // No action needed on the license if licensee wins
        } else { // Negative tally favors challenger (revocation)
            dispute.outcomeForLicensee = false;
            // Revoke the license if challenger wins
            licenses[dispute.licenseId].isActive = false;
            licenses[dispute.licenseId].expirationTimestamp = block.timestamp;
            emit LicenseRevoked(dispute.licenseId, address(this)); // Revoked by contract
        }

        // Remove from active disputes list (simplified: clear the list)
        // In a real system, you'd remove the specific ID
        delete activeDisputes[0];

        emit LicenseDisputeResolved(_disputeId, dispute.outcomeForLicensee);
    }

     /**
     * @dev Gets the list of active dispute IDs.
     * @return An array of active dispute IDs.
     */
    function getActiveDisputes() external view returns (uint256[] memory) {
        // NOTE: This uses a simplified array (activeDisputes[0]).
        // A better approach for production is a linked list or iterating through all disputes.
        return activeDisputes[0];
    }


    // --- Governance (6) ---

    /**
     * @dev Allows staked users to submit governance proposals.
     * @param _description IPFS hash for proposal details.
     * @param _target Contract address the proposal will call.
     * @param _value ETH value to send with the call.
     * @param _callData Encoded function call data for the proposal.
     */
    function submitProposal(string memory _description, address _target, uint256 _value, bytes memory _callData)
        external onlyGovernorStakeholder(minStakeForProposal)
    {
        proposalCounter++;
        uint256 proposalId = proposalCounter;

        proposals[proposalId] = Proposal(
            proposalId,
            msg.sender,
            _description,
            block.timestamp,
            block.timestamp + votingPeriod,
            _callData,
            _target,
            _value,
            // hasVoted map is initialized empty
            0, // yesVotes
            0, // noVotes
            ProposalState.Active
        );

        activeProposals[0].push(proposalId); // Add to active list (simplified)

        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows staked users to vote on an active governance proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernorStakeholder(0) { // Min stake is checked on submit
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingEndTimestamp, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        uint256 weightedVote = _stakedCURATE[msg.sender];

        if (_support) {
            proposal.yesVotes += weightedVote;
        } else {
            proposal.noVotes += weightedVote;
        }

        emit VoteCast(_proposalId, msg.sender, _support, weightedVote);
    }

    /**
     * @dev Ends the voting period for a proposal and updates its state.
     *      Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal.
     */
    function endProposalVoting(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.votingEndTimestamp, "Voting period is still active");

        // Calculate total votes cast by active stakers at the time of voting end (simplified)
        // A more robust system would snapshot stake at proposal start.
        uint256 totalActiveStake = totalStakedCURATE; // Using current total staked for simplicity

        if (totalActiveStake > 0 && (proposal.yesVotes * 100) / totalActiveStake >= requiredVotesForProposal) {
            // Check if YES votes meet threshold based on total *active* stake
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }

         // Remove from active proposals list (simplified)
        delete activeProposals[0]; // Clears the array

        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    /**
     * @dev Executes a successfully passed governance proposal.
     *      Anyone can call this if the proposal state is Succeeded.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal has not succeeded");

        // Execute the proposal call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, proposal.state);
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Gets the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Gets the list of all proposal IDs.
     * @return An array of proposal IDs.
     */
    function getProposals() external view returns (uint256[] memory) {
        // Returns all proposal IDs created
        uint256[] memory allProposals = new uint256[](proposalCounter);
        for (uint256 i = 1; i <= proposalCounter; i++) {
            allProposals[i-1] = i;
        }
        return allProposals;
    }


    // --- Financial & Fees (2) ---

    /**
     * @dev Allows a creator to withdraw their accumulated earnings from license fees.
     */
    function withdrawCreatorEarnings() external {
        uint256 amount = creatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        creatorEarnings[msg.sender] = 0; // Set balance to zero before sending
        // Use call to prevent re-entrancy issues
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit CreatorEarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = platformFees;
        require(amount > 0, "No platform fees to withdraw");

        platformFees = 0; // Set balance to zero before sending
         // Use call to prevent re-entrancy issues
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Platform fee withdrawal failed");

        emit PlatformFeesWithdrawn(owner, amount);
    }

    // --- Getters & Helpers (Additional functions) ---

    /**
     * @dev Gets the total number of registered works.
     * @return Total work count.
     */
    function getTotalWorks() external view returns (uint256) {
        return workCounter;
    }

    /**
     * @dev Gets the total number of issued licenses.
     * @return Total license count.
     */
    function getTotalLicenses() external view returns (uint256) {
        return licenseCounter;
    }

    /**
     * @dev Gets the current platform fee percentage on license acquisitions.
     * @return Percentage (0-100).
     */
    function getPlatformFeePercentage() external view returns (uint8) {
        return platformFeePercentage;
    }

    /**
     * @dev Gets the minimum CURATE stake required to participate in curation voting.
     * @return Minimum stake amount.
     */
    function getMinCurationStake() external view returns (uint256) {
        return minCurationStake;
    }

    /**
     * @dev Gets the minimum CURATE stake required to submit a governance proposal.
     * @return Minimum stake amount.
     */
    function getMinStakeForProposal() external view returns (uint256) {
        return minStakeForProposal;
    }

    /**
     * @dev Gets the duration of voting periods for proposals and disputes.
     * @return Voting period in seconds.
     */
    function getVotingPeriod() external view returns (uint256) {
        return votingPeriod;
    }

     /**
     * @dev Gets the required percentage of total staked votes for a proposal to pass.
     * @return Percentage (0-100).
     */
    function getRequiredVotesForProposal() external view returns (uint256) {
        return requiredVotesForProposal;
    }

    /**
     * @dev Gets the total amount of CURATE tokens currently staked in the protocol.
     * @return Total staked amount.
     */
    function getTotalStakedCURATE() external view returns (uint256) {
        return totalStakedCURATE;
    }


    // --- Fallback and Receive ---

    receive() external payable {
        // Handle incoming Ether if necessary (e.g., for license acquisition)
        // The acquireLicense function handles value directly, so this might not be strictly needed,
        // but good practice if other functions might receive Ether.
    }

    fallback() external payable {
        // Fallback function
    }
}
```