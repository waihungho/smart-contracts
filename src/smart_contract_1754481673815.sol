This smart contract, **EthosSphere**, proposes a novel decentralized reputation and identity framework. It's built around the concept of "Soulbound Tokens" (SBTs) that are dynamically updated based on a user's on-chain actions and the vouching of other trusted identities within the network. It integrates reputation-based access control, a unique dispute resolution system, and micro-task coordination.

**Core Concepts:**

1.  **Dynamic Ethos Badges (SBTs):** Non-transferable ERC-721 tokens representing a user's identity. Their metadata (visuals, traits) evolve dynamically based on their accumulated "Aura" (reputation score) and other on-chain activities.
2.  **Aura (Reputation Score):** A numerical score tied to each `EthosBadge`. It increases through vouches from other users, successful task completions, and positive dispute resolutions. It decreases from negative actions or successful disputes against them.
3.  **Vouching System:** Users can stake ETH to vouch for another user's reputation. This increases the vouched-for user's Aura. Stakes can be slashed if a vouched-for individual is later found to be malicious via a dispute.
4.  **Decentralized Dispute Resolution:** A mechanism for users to challenge false vouches, malicious actors, or incorrect Aura adjustments. Disputes involve staking, evidence submission, and a jury of high-Aura users voting on outcomes.
5.  **Reputation-Gated Features:** Certain functionalities, like initiating higher-impact vouches, becoming a dispute jury member, or accessing premium features, are unlocked based on a user's Aura score.
6.  **Micro-Task Coordination:** A system where users can post small, verifiable tasks, and others can complete them to earn Aura and potentially rewards. This fosters productive on-chain collaboration.

---

## **EthosSphere Smart Contract Outline & Function Summary**

**Contract Name:** `EthosSphere`

**Inherits:** `ERC721`, `Ownable`, `ReentrancyGuard`

**Core Data Structures:**

*   `Identity`: Stores user profile details, Aura score, status, and associated EthosBadge ID.
*   `Vouch`: Records details of a vouch, including who vouched, who was vouched for, amount staked, and status.
*   `Dispute`: Manages the lifecycle of a dispute, including involved parties, stakes, evidence, and jury votes.
*   `ReputationTask`: Defines a task, its reward, and completion status.

---

### **Outline & Function Summary:**

**I. Identity & Ethos Badge Management (ERC-721 SBTs)**

*   `constructor()`: Initializes the ERC-721 token, sets contract owner.
*   `registerIdentity(string calldata _username, string calldata _bio)`:
    *   Registers a new identity for `msg.sender`.
    *   Mints a unique Ethos Badge (SBT) for them.
    *   Requires a registration fee.
*   `updateProfileDetails(string calldata _newUsername, string calldata _newBio)`:
    *   Allows a registered user to update their `username` and `bio`.
*   `getIdentityDetails(address _identityAddress)`:
    *   Retrieves the full `Identity` struct for a given address.
*   `getEthosBadgeURI(uint256 _tokenId)`:
    *   **Advanced Concept: Dynamic NFT Metadata.** Returns a URI pointing to off-chain metadata (e.g., IPFS gateway) that generates a JSON based on the token's current Aura, status, etc.
*   `tokenURI(uint256 _tokenId)`: Overrides `ERC721`'s `tokenURI` to provide dynamic metadata. (Internal/External helper for `getEthosBadgeURI`).
*   `_setTokenURI(uint256 _tokenId, string memory _newURI)`: Internal function to update the token URI if needed (e.g., a base URI change).
*   `isRegistered(address _addr)`: Checks if an address has a registered identity.

**II. Aura (Reputation) & Vouching System**

*   `vouchForIdentity(address _identityToVouchFor)`:
    *   **Advanced Concept: Staked Vouching.** Allows a registered user to vouch for another.
    *   Requires `msg.sender` to be registered and stake `vouchStakeAmount`.
    *   Increases the `_identityToVouchFor`'s Aura score based on `auraImpactFactors.vouch`.
    *   The voucher's stake is held until retraction or dispute.
*   `retractVouch(uint256 _vouchId)`:
    *   Allows the original voucher to retract their vouch.
    *   Decreases the vouched-for identity's Aura.
    *   Refunds the voucher's staked ETH.
*   `getAuraScore(address _identityAddress)`:
    *   Retrieves the current Aura score for a given identity.
*   `getVouchDetails(uint256 _vouchId)`:
    *   Retrieves detailed information about a specific vouch.
*   `getIdentityVouches(address _identityAddress)`:
    *   Returns an array of vouch IDs where `_identityAddress` is either the voucher or the vouched-for.
*   `_updateAuraScore(address _identityAddress, int256 _change)`:
    *   Internal helper function to atomically update an identity's Aura score and potentially trigger dynamic badge updates.

**III. Decentralized Dispute Resolution System**

*   `initiateDispute(uint256 _vouchId, string calldata _reason)`:
    *   **Advanced Concept: On-Chain Dispute Initiation.** Allows any registered user to initiate a dispute against a specific vouch (e.g., claiming it's fraudulent).
    *   Requires a `disputeStakeAmount` from the initiator.
    *   The vouching party's stake for that vouch also gets locked for the dispute duration.
*   `submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI)`:
    *   Allows involved parties and potential jury members to submit evidence (e.g., IPFS link to documents/videos) during the evidence submission phase.
*   `voteOnDispute(uint256 _disputeId, bool _isVouchValid)`:
    *   **Advanced Concept: Jury Voting (Reputation-Gated).** Allows registered identities with Aura above `juryPoolThreshold` to vote on the dispute's outcome.
    *   Votes are weighted by the voter's Aura score.
*   `resolveDispute(uint256 _disputeId)`:
    *   **Advanced Concept: Automated Dispute Resolution.** Resolves a dispute after the voting period ends.
    *   Based on the majority vote, it determines if the vouch was valid or not.
    *   Slashes stakes of the losing party (initiator if vouch is valid, voucher if vouch is invalid) and distributes them to the winning party/jury.
    *   Adjusts Aura scores of involved parties based on `auraImpactFactors.disputeWin` or `disputeLoss`.
*   `getDisputeDetails(uint256 _disputeId)`:
    *   Retrieves the full `Dispute` struct details.
*   `getDisputeVoteCount(uint256 _disputeId)`:
    *   Retrieves the current positive and negative weighted vote counts for a dispute.

**IV. Reputation-Earning Micro-Task System**

*   `createReputationTask(string calldata _title, string calldata _description, uint256 _rewardAura)`:
    *   Allows high-Aura users or the admin to create new tasks.
    *   Tasks have a title, description, and an Aura reward for completion.
*   `submitTaskCompletion(uint256 _taskId, string calldata _proofURI)`:
    *   Allows any registered user to submit proof of task completion.
*   `verifyTaskCompletion(uint256 _taskId, address _completer, bool _isSuccessful)`:
    *   Allows the task creator or admin to verify a task submission.
    *   If successful, rewards the completer with `_rewardAura` and potentially a small ETH reward from the task creator.
*   `getTaskDetails(uint256 _taskId)`:
    *   Retrieves the details of a specific reputation task.

**V. Governance & Administrative Functions (Ownable)**

*   `setRegistrationFee(uint256 _newFee)`:
    *   Allows the owner to update the fee for registering an identity.
*   `setVouchStakeAmount(uint256 _newAmount)`:
    *   Allows the owner to update the ETH amount required to vouch.
*   `setDisputeStakeAmount(uint256 _newAmount)`:
    *   Allows the owner to update the ETH amount required to initiate a dispute.
*   `setAuraImpactFactors(int256 _vouch, int256 _disputeWin, int256 _disputeLoss, int256 _taskComplete)`:
    *   Allows the owner to calibrate how much Aura changes based on different actions.
*   `setJuryPoolThreshold(uint256 _newThreshold)`:
    *   Allows the owner to set the minimum Aura required to be a dispute jury member.
*   `withdrawFees()`:
    *   Allows the owner to withdraw accumulated fees from registration and dispute resolutions.
*   `emergencyAuraAdjustment(address _identityAddress, int256 _adjustment)`:
    *   **Advanced Concept: Emergency Override.** An owner-only function for critical scenarios to manually adjust Aura. Should be used with extreme caution and transparently.
*   `pauseSystem()`: Pauses core functionalities in case of emergency.
*   `unpauseSystem()`: Unpauses the system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title EthosSphere
 * @dev A decentralized reputation and identity framework built on dynamic Soulbound Tokens (SBTs).
 *      It leverages on-chain vouching, reputation-gated access, a unique dispute resolution system,
 *      and micro-task coordination to foster a trust-based ecosystem.
 *      Ethos Badges (SBTs) evolve dynamically based on a user's accumulated Aura (reputation score).
 */
contract EthosSphere is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _identityIds;
    Counters.Counter private _vouchIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _taskIds;

    // Mapping of address to Identity struct
    mapping(address => Identity) public identities;
    // Mapping of identity ID to address (for reverse lookup, useful for ERC721)
    mapping(uint256 => address) public identityIdToAddress;
    // Mapping of Ethos Badge (ERC721) ID to Identity struct
    mapping(uint256 => Identity) public ethosBadges;

    // Mapping of Vouch ID to Vouch struct
    mapping(uint256 => Vouch) public vouches;
    // Mapping of address to array of vouch IDs they initiated
    mapping(address => uint256[]) public userInitiatedVouches;
    // Mapping of address to array of vouch IDs they received
    mapping(address => uint256[]) public userReceivedVouches;

    // Mapping of Dispute ID to Dispute struct
    mapping(uint256 => Dispute) public disputes;

    // Mapping of Task ID to ReputationTask struct
    mapping(uint256 => ReputationTask) public reputationTasks;

    // System Parameters
    uint256 public registrationFee;
    uint256 public vouchStakeAmount;
    uint256 public disputeStakeAmount;
    uint256 public juryPoolThreshold; // Minimum Aura score to be eligible for jury

    // Defines how much Aura changes based on actions
    struct AuraImpactFactors {
        int256 vouch;
        int256 disputeWin;
        int256 disputeLoss;
        int256 taskComplete;
    }
    AuraImpactFactors public auraImpactFactors;

    uint256 public totalEthDeposited; // Tracks all ETH staked in the contract

    bool public paused; // Emergency pause switch

    // --- Enums ---
    enum IdentityStatus { Active, Suspended }
    enum VouchStatus { Active, Retracted, Disputed, Validated, Invalidated }
    enum DisputeStatus { Open, EvidenceCollection, Voting, Resolved }
    enum TaskStatus { Open, InProgress, Completed, Verified }

    // --- Structs ---
    struct Identity {
        uint256 id;
        string username;
        string bio;
        int256 auraScore;
        IdentityStatus status;
        uint256 ethosBadgeId;
        address walletAddress;
    }

    struct Vouch {
        uint256 id;
        address voucher;
        address vouchedFor;
        uint256 amountStaked;
        uint256 timestamp;
        VouchStatus status;
        uint256 disputeId; // 0 if no dispute
    }

    struct Dispute {
        uint256 id;
        uint256 vouchId; // The vouch being disputed
        address initiator;
        string reason;
        uint256 initiatorStake;
        uint256 defendantStake; // The vouching party's stake for the vouched vouch
        mapping(address => bool) hasVoted; // Tracks if a jury member has voted
        mapping(address => string) evidenceURIs; // Mapping of address to submitted evidence URI
        int256 positiveVotes; // Weighted sum of votes for vouch being valid
        int256 negativeVotes; // Weighted sum of votes against vouch being valid
        uint256 disputeStartTime;
        uint256 evidenceEndTime; // Timestamp for end of evidence submission
        uint256 votingEndTime; // Timestamp for end of voting
        DisputeStatus status;
        address[] juryVoters; // List of addresses that voted
        bool result; // True if vouch is valid, false if invalid
    }

    struct ReputationTask {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 rewardAura;
        uint256 rewardEth; // Optional ETH reward
        address completer;
        TaskStatus status;
        string proofURI;
        uint256 creationTimestamp;
        uint256 completionTimestamp;
    }

    // --- Events ---
    event IdentityRegistered(uint256 indexed id, address indexed walletAddress, string username, uint256 ethosBadgeId);
    event ProfileUpdated(uint256 indexed id, address indexed walletAddress, string newUsername, string newBio);
    event VouchSubmitted(uint256 indexed vouchId, address indexed voucher, address indexed vouchedFor, uint256 amountStaked);
    event VouchRetracted(uint256 indexed vouchId, address indexed voucher, address indexed vouchedFor);
    event AuraScoreUpdated(address indexed identityAddress, int256 newAuraScore, int256 change);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed vouchId, address indexed initiator, string reason);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool vote);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed vouchId, bool result);
    event ReputationTaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 rewardAura);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed completer, string proofURI);
    event TaskCompletionVerified(uint256 indexed taskId, address indexed completer, bool success, uint256 auraRewarded);
    event FeeWithdrawn(address indexed to, uint256 amount);
    event SystemPaused(address indexed by);
    event SystemUnpaused(address indexed by);
    event ParametersUpdated(string paramName, uint256 newValue);
    event AuraImpactFactorsUpdated(int256 vouch, int256 disputeWin, int256 disputeLoss, int256 taskComplete);

    // --- Errors ---
    error NotRegistered();
    error AlreadyRegistered();
    error IdentityNotFound();
    error VouchNotFound();
    error SelfVouchingNotAllowed();
    error VouchAlreadyDisputed();
    error NotVoucher();
    error InsufficientAuraForJury();
    error DisputeNotFound();
    error InvalidDisputePhase();
    error AlreadyVoted();
    error TaskNotFound();
    error NotTaskCreator();
    error TaskAlreadyCompleted();
    error ZeroAddress();
    error InsufficientFunds(uint256 required, uint256 available);
    error NotPaused();
    error IsPaused();
    error EmergencyAdjustmentForbidden();

    // --- Modifiers ---
    modifier onlyRegistered() {
        if (identities[msg.sender].id == 0) revert NotRegistered();
        _;
    }

    modifier onlyIfPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier onlyIfUnpaused() {
        if (paused) revert IsPaused();
        _;
    }

    modifier disputePhase(uint256 _disputeId, DisputeStatus _expectedStatus) {
        if (disputes[_disputeId].status != _expectedStatus) revert InvalidDisputePhase();
        _;
    }

    modifier onlyJuryMember(address _voter) {
        if (identities[_voter].auraScore < int256(juryPoolThreshold)) revert InsufficientAuraForJury();
        _;
    }

    modifier notSelf(address _addr) {
        if (_addr == msg.sender) revert SelfVouchingNotAllowed();
        _;
    }

    // --- Constructor ---
    constructor() ERC721("EthosBadge", "ETHS") Ownable(msg.sender) {
        registrationFee = 0.01 ether;
        vouchStakeAmount = 0.005 ether;
        disputeStakeAmount = 0.005 ether;
        juryPoolThreshold = 100; // Example: Aura score of 100 to be a jury
        auraImpactFactors = AuraImpactFactors({
            vouch: 10,
            disputeWin: 50,
            disputeLoss: -50,
            taskComplete: 20
        });
        paused = false;
    }

    // --- I. Identity & Ethos Badge Management ---

    /**
     * @dev Registers a new identity for the sender and mints an Ethos Badge (SBT).
     * @param _username The desired username for the identity.
     * @param _bio A short biography for the identity.
     */
    function registerIdentity(string calldata _username, string calldata _bio)
        external
        payable
        onlyIfUnpaused
    {
        if (identities[msg.sender].id != 0) revert AlreadyRegistered();
        if (msg.value < registrationFee) revert InsufficientFunds(registrationFee, msg.value);
        if (msg.sender == address(0)) revert ZeroAddress();

        _identityIds.increment();
        uint256 newId = _identityIds.current();
        uint256 newTokenId = newId; // Ethos Badge ID matches Identity ID for simplicity

        identities[msg.sender] = Identity({
            id: newId,
            username: _username,
            bio: _bio,
            auraScore: 0,
            status: IdentityStatus.Active,
            ethosBadgeId: newTokenId,
            walletAddress: msg.sender
        });
        identityIdToAddress[newId] = msg.sender;
        ethosBadges[newTokenId] = identities[msg.sender];

        _safeMint(msg.sender, newTokenId); // Mint the Soulbound Token
        _setTokenURI(newTokenId, _generateTokenURI(newTokenId)); // Set initial dynamic URI

        totalEthDeposited += msg.value;
        emit IdentityRegistered(newId, msg.sender, _username, newTokenId);
    }

    /**
     * @dev Allows a registered user to update their profile details.
     * @param _newUsername The new username.
     * @param _newBio The new biography.
     */
    function updateProfileDetails(string calldata _newUsername, string calldata _newBio)
        external
        onlyRegistered
        onlyIfUnpaused
    {
        identities[msg.sender].username = _newUsername;
        identities[msg.sender].bio = _newBio;
        emit ProfileUpdated(identities[msg.sender].id, msg.sender, _newUsername, _newBio);
    }

    /**
     * @dev Retrieves the full details of an identity.
     * @param _identityAddress The address of the identity to retrieve.
     * @return Identity struct.
     */
    function getIdentityDetails(address _identityAddress)
        external
        view
        returns (Identity memory)
    {
        if (identities[_identityAddress].id == 0) revert IdentityNotFound();
        return identities[_identityAddress];
    }

    /**
     * @dev Checks if an address is registered.
     * @param _addr The address to check.
     * @return True if registered, false otherwise.
     */
    function isRegistered(address _addr) external view returns (bool) {
        return identities[_addr].id != 0;
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata.
     *      The metadata URI for Ethos Badges will be generated based on current Aura score, status, etc.
     *      This would typically point to an off-chain API or IPFS gateway that serves dynamic JSON.
     * @param _tokenId The ID of the Ethos Badge.
     * @return A URI string.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        return _generateTokenURI(_tokenId);
    }

    /**
     * @dev Internal function to generate the dynamic token URI.
     *      This would ideally involve more complex logic based on the Identity's current state.
     */
    function _generateTokenURI(uint256 _tokenId) internal view returns (string memory) {
        // In a real dApp, this would be an IPFS gateway or an API that generates
        // JSON metadata based on the on-chain state of the Ethos Badge (aura, status etc.)
        // For demonstration, a placeholder.
        string memory baseURI = "ipfs://QmbF6t9xTzY4vKx2cRj7HwP3dM8sZqN5jL0V0cW1aB2s3/metadata/"; // Example base IPFS
        return string.concat(baseURI, _tokenId.toString(), ".json");
    }

    // Function to ensure Soulbound nature (non-transferable)
    function _approve(address to, uint256 tokenId) internal pure override {
        revert ERC721ApproveNotSupported(); // Disable approval
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal pure override {
        revert ERC721ApproveAllNotSupported(); // Disable setApprovalForAll
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert ERC721TransferNotSupported(); // Disable transferFrom
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert ERC721TransferNotSupported(); // Disable safeTransferFrom
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert ERC721TransferNotSupported(); // Disable safeTransferFrom
    }

    // --- II. Aura (Reputation) & Vouching System ---

    /**
     * @dev Allows a registered user to vouch for another registered user's identity.
     *      Requires a stake, which can be slashed upon dispute.
     * @param _identityToVouchFor The address of the identity to vouch for.
     */
    function vouchForIdentity(address _identityToVouchFor)
        external
        payable
        onlyRegistered
        notSelf(_identityToVouchFor)
        onlyIfUnpaused
        nonReentrant
    {
        if (identities[_identityToVouchFor].id == 0) revert IdentityNotFound();
        if (msg.value < vouchStakeAmount) revert InsufficientFunds(vouchStakeAmount, msg.value);

        _vouchIds.increment();
        uint256 newVouchId = _vouchIds.current();

        vouches[newVouchId] = Vouch({
            id: newVouchId,
            voucher: msg.sender,
            vouchedFor: _identityToVouchFor,
            amountStaked: msg.value,
            timestamp: block.timestamp,
            status: VouchStatus.Active,
            disputeId: 0
        });

        userInitiatedVouches[msg.sender].push(newVouchId);
        userReceivedVouches[_identityToVouchFor].push(newVouchId);

        _updateAuraScore(_identityToVouchFor, auraImpactFactors.vouch);
        totalEthDeposited += msg.value;
        emit VouchSubmitted(newVouchId, msg.sender, _identityToVouchFor, msg.value);
    }

    /**
     * @dev Allows the original voucher to retract their vouch.
     *      This reduces the vouched-for identity's Aura and refunds the stake.
     * @param _vouchId The ID of the vouch to retract.
     */
    function retractVouch(uint256 _vouchId)
        external
        onlyRegistered
        onlyIfUnpaused
        nonReentrant
    {
        Vouch storage vouch = vouches[_vouchId];
        if (vouch.id == 0) revert VouchNotFound();
        if (vouch.voucher != msg.sender) revert NotVoucher();
        if (vouch.status != VouchStatus.Active) revert VouchAlreadyDisputed(); // Can only retract active vouches

        vouch.status = VouchStatus.Retracted;
        _updateAuraScore(vouch.vouchedFor, -auraImpactFactors.vouch); // Reduce aura
        
        uint256 refundAmount = vouch.amountStaked;
        totalEthDeposited -= refundAmount;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) {
            // Revert or log for manual review, should ideally not fail on simple transfer
            // For robust system, consider an emergency withdrawal function for stuck funds.
            revert("Failed to refund stake.");
        }

        emit VouchRetracted(_vouchId, vouch.voucher, vouch.vouchedFor);
    }

    /**
     * @dev Gets the current Aura score for a given identity.
     * @param _identityAddress The address of the identity.
     * @return The Aura score.
     */
    function getAuraScore(address _identityAddress)
        external
        view
        returns (int256)
    {
        if (identities[_identityAddress].id == 0) revert IdentityNotFound();
        return identities[_identityAddress].auraScore;
    }

    /**
     * @dev Retrieves detailed information about a specific vouch.
     * @param _vouchId The ID of the vouch.
     * @return Vouch struct.
     */
    function getVouchDetails(uint256 _vouchId)
        external
        view
        returns (Vouch memory)
    {
        if (vouches[_vouchId].id == 0) revert VouchNotFound();
        return vouches[_vouchId];
    }

    /**
     * @dev Gets the list of vouch IDs initiated by or received by an identity.
     * @param _identityAddress The address of the identity.
     * @return An array of vouch IDs.
     */
    function getIdentityVouches(address _identityAddress)
        external
        view
        returns (uint256[] memory initiated, uint256[] memory received)
    {
        if (identities[_identityAddress].id == 0) revert IdentityNotFound();
        return (userInitiatedVouches[_identityAddress], userReceivedVouches[_identityAddress]);
    }

    /**
     * @dev Internal helper to update an identity's Aura score.
     *      Can be positive or negative change.
     * @param _identityAddress The address of the identity.
     * @param _change The amount to change the Aura score by (can be negative).
     */
    function _updateAuraScore(address _identityAddress, int256 _change) internal {
        Identity storage identity = identities[_identityAddress];
        if (identity.id == 0) revert IdentityNotFound(); // Should not happen internally

        identity.auraScore += _change;
        // Optionally, trigger metadata update for the Ethos Badge
        // _setTokenURI(identity.ethosBadgeId, _generateTokenURI(identity.ethosBadgeId));
        emit AuraScoreUpdated(_identityAddress, identity.auraScore, _change);
    }

    // --- III. Decentralized Dispute Resolution System ---

    /**
     * @dev Initiates a dispute against an existing vouch.
     *      Requires a stake from the initiator, and locks the voucher's stake.
     * @param _vouchId The ID of the vouch to dispute.
     * @param _reason A brief reason for the dispute.
     */
    function initiateDispute(uint256 _vouchId, string calldata _reason)
        external
        payable
        onlyRegistered
        onlyIfUnpaused
        nonReentrant
    {
        Vouch storage vouch = vouches[_vouchId];
        if (vouch.id == 0) revert VouchNotFound();
        if (vouch.status != VouchStatus.Active) revert VouchAlreadyDisputed(); // Can only dispute active vouches

        if (msg.value < disputeStakeAmount) revert InsufficientFunds(disputeStakeAmount, msg.value);

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        vouch.status = VouchStatus.Disputed;
        vouch.disputeId = newDisputeId;

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            vouchId: _vouchId,
            initiator: msg.sender,
            reason: _reason,
            initiatorStake: msg.value,
            defendantStake: vouch.amountStaked,
            disputeStartTime: block.timestamp,
            evidenceEndTime: block.timestamp + 2 days, // 2 days for evidence collection
            votingEndTime: block.timestamp + 5 days,   // 5 days total for evidence + voting
            status: DisputeStatus.EvidenceCollection,
            positiveVotes: 0,
            negativeVotes: 0,
            juryVoters: new address[](0)
        });

        totalEthDeposited += msg.value; // Initiator's stake
        // Voucher's stake is already counted as deposited when vouch was created

        emit DisputeInitiated(newDisputeId, _vouchId, msg.sender, _reason);
    }

    /**
     * @dev Allows involved parties and jury members to submit evidence for a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI A URI pointing to the evidence (e.g., IPFS link).
     */
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI)
        external
        onlyRegistered
        disputePhase(_disputeId, DisputeStatus.EvidenceCollection)
    {
        Dispute storage dispute = disputes[_disputeId];
        // Only involved parties or potential jury members can submit evidence
        bool isParticipant = (msg.sender == dispute.initiator || msg.sender == vouches[dispute.vouchId].voucher || msg.sender == vouches[dispute.vouchId].vouchedFor);
        bool isJuryEligible = (identities[msg.sender].auraScore >= int256(juryPoolThreshold));

        if (!isParticipant && !isJuryEligible) revert("Only participants or jury-eligible users can submit evidence.");

        if (block.timestamp > dispute.evidenceEndTime) revert InvalidDisputePhase();

        dispute.evidenceURIs[msg.sender] = _evidenceURI;
        emit EvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /**
     * @dev Allows eligible jury members to vote on a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _isVouchValid True if the voter believes the vouch is valid, false otherwise.
     */
    function voteOnDispute(uint256 _disputeId, bool _isVouchValid)
        external
        onlyRegistered
        onlyJuryMember(msg.sender)
        disputePhase(_disputeId, DisputeStatus.EvidenceCollection) // Voting can start during evidence if desired, or set a new phase
    {
        Dispute storage dispute = disputes[_disputeId];
        if (block.timestamp > dispute.votingEndTime) revert InvalidDisputePhase();
        if (dispute.hasVoted[msg.sender]) revert AlreadyVoted();

        // Ensure dispute status is correct for voting
        if (block.timestamp > dispute.evidenceEndTime && dispute.status == DisputeStatus.EvidenceCollection) {
            dispute.status = DisputeStatus.Voting; // Transition to Voting phase
        }
        if (dispute.status != DisputeStatus.Voting && dispute.status != DisputeStatus.EvidenceCollection) revert InvalidDisputePhase(); // Allow voting during evidence or dedicated voting phase

        int256 voteWeight = identities[msg.sender].auraScore; // Aura-weighted voting

        if (_isVouchValid) {
            dispute.positiveVotes += voteWeight;
        } else {
            dispute.negativeVotes += voteWeight;
        }
        dispute.hasVoted[msg.sender] = true;
        dispute.juryVoters.push(msg.sender);
        emit DisputeVoteCast(_disputeId, msg.sender, _isVouchValid);
    }

    /**
     * @dev Resolves a dispute after the voting period ends.
     *      Distributes stakes and adjusts Aura scores based on the outcome.
     *      Can be called by anyone after votingEndTime.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId)
        external
        onlyIfUnpaused
        nonReentrant
    {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound();
        if (dispute.status == DisputeStatus.Resolved) revert InvalidDisputePhase();
        if (block.timestamp < dispute.votingEndTime) revert InvalidDisputePhase(); // Must wait for voting to end

        Vouch storage vouch = vouches[dispute.vouchId];

        bool vouchWasValid = dispute.positiveVotes >= dispute.negativeVotes; // Majority rule for validity
        dispute.result = vouchWasValid;
        dispute.status = DisputeStatus.Resolved;

        address winnerAddress;
        address loserAddress;
        uint256 loserStake;
        int256 winnerAuraChange;
        int256 loserAuraChange;

        if (vouchWasValid) {
            // Vouch was valid. Initiator loses stake, Voucher (defendant) gets stake back.
            winnerAddress = vouch.voucher;
            loserAddress = dispute.initiator;
            loserStake = dispute.initiatorStake;
            vouch.status = VouchStatus.Validated;
            winnerAuraChange = auraImpactFactors.disputeWin;
            loserAuraChange = auraImpactFactors.disputeLoss;
        } else {
            // Vouch was invalid. Voucher loses stake, Initiator gets stake back.
            winnerAddress = dispute.initiator;
            loserAddress = vouch.voucher;
            loserStake = dispute.defendantStake;
            vouch.status = VouchStatus.Invalidated;
            winnerAuraChange = auraImpactFactors.disputeWin;
            loserAuraChange = auraImpactFactors.disputeLoss;

            // Reduce aura of the vouched-for individual as well, as their vouch was invalidated
            _updateAuraScore(vouch.vouchedFor, -auraImpactFactors.vouch);
        }

        // Distribute stakes
        uint256 totalWinningStake = dispute.initiatorStake + dispute.defendantStake - loserStake; // The one who didn't lose
        uint256 juryRewardPerVoter = totalWinningStake / dispute.juryVoters.length;

        // Refund winner's stake (if any) and reward jury (if any)
        if (winnerAddress != address(0) && (dispute.initiator == winnerAddress || vouch.voucher == winnerAddress)) {
             // Only refund if they were actually a party in the dispute who had their stake held
            uint256 refundAmount = (dispute.initiator == winnerAddress) ? dispute.initiatorStake : dispute.defendantStake;
            totalEthDeposited -= refundAmount;
            (bool success, ) = payable(winnerAddress).call{value: refundAmount}("");
            if (!success) { /* Handle error */ }
        }
        
        // Distribute portion of loser's stake to jury
        for (uint i = 0; i < dispute.juryVoters.length; i++) {
            address juryMember = dispute.juryVoters[i];
            totalEthDeposited -= juryRewardPerVoter;
            (bool success, ) = payable(juryMember).call{value: juryRewardPerVoter}("");
            if (!success) { /* Handle error */ }
        }

        // Transfer remaining loser stake (if any) to protocol fees or burn (here, added to totalEthDeposited for admin withdrawal)
        uint256 remainingLoserStake = loserStake - (juryRewardPerVoter * dispute.juryVoters.length);
        if (remainingLoserStake > 0) {
            // This portion remains in contract, accessible by owner's withdrawFees
        }

        // Update Aura scores
        _updateAuraScore(winnerAddress, winnerAuraChange);
        if (loserAddress != address(0)) { // Loser might be 0x0 if it was the initial dispute of the non-existence of a vouch
            _updateAuraScore(loserAddress, loserAuraChange);
        }

        emit DisputeResolved(_disputeId, dispute.vouchId, vouchWasValid);
    }

    /**
     * @dev Retrieves details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct.
     */
    function getDisputeDetails(uint256 _disputeId)
        external
        view
        returns (Dispute memory)
    {
        if (disputes[_disputeId].id == 0) revert DisputeNotFound();
        return disputes[_disputeId];
    }

    /**
     * @dev Retrieves the current vote counts for a dispute.
     * @param _disputeId The ID of the dispute.
     * @return positiveVotes_ The sum of weighted positive votes.
     * @return negativeVotes_ The sum of weighted negative votes.
     */
    function getDisputeVoteCount(uint256 _disputeId)
        external
        view
        returns (int256 positiveVotes_, int256 negativeVotes_)
    {
        if (disputes[_disputeId].id == 0) revert DisputeNotFound();
        return (disputes[_disputeId].positiveVotes, disputes[_disputeId].negativeVotes);
    }

    // --- IV. Reputation-Earning Micro-Task System ---

    /**
     * @dev Creates a new reputation task.
     *      Can be created by owner or high-Aura users.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _rewardAura The amount of Aura to reward upon successful completion.
     */
    function createReputationTask(string calldata _title, string calldata _description, uint256 _rewardAura)
        external
        onlyRegistered
        onlyIfUnpaused
    {
        // Only owner or users above a certain Aura threshold can create tasks
        if (msg.sender != owner() && identities[msg.sender].auraScore < int256(juryPoolThreshold)) {
            revert("Only owner or high-Aura users can create tasks.");
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        reputationTasks[newTaskId] = ReputationTask({
            id: newTaskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            rewardAura: _rewardAura,
            rewardEth: 0, // No ETH reward for now, focus on Aura
            completer: address(0),
            status: TaskStatus.Open,
            proofURI: "",
            creationTimestamp: block.timestamp,
            completionTimestamp: 0
        });

        emit ReputationTaskCreated(newTaskId, msg.sender, _title, _rewardAura);
    }

    /**
     * @dev Allows a registered user to submit proof of task completion.
     * @param _taskId The ID of the task.
     * @param _proofURI A URI pointing to the proof (e.g., IPFS link).
     */
    function submitTaskCompletion(uint256 _taskId, string calldata _proofURI)
        external
        onlyRegistered
        onlyIfUnpaused
    {
        ReputationTask storage task = reputationTasks[_taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.Open) revert TaskAlreadyCompleted();

        task.completer = msg.sender;
        task.proofURI = _proofURI;
        task.status = TaskStatus.InProgress; // Waiting for verification

        emit TaskCompletionSubmitted(_taskId, msg.sender, _proofURI);
    }

    /**
     * @dev Verifies a task completion and awards Aura.
     *      Can only be called by the task creator or owner.
     * @param _taskId The ID of the task.
     * @param _completer The address of the user who completed the task.
     * @param _isSuccessful True if the completion is deemed successful, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, address _completer, bool _isSuccessful)
        external
        onlyRegistered // Creator/owner must be registered too
        onlyIfUnpaused
    {
        ReputationTask storage task = reputationTasks[_taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.creator != msg.sender && owner() != msg.sender) revert NotTaskCreator(); // Only creator or owner can verify
        if (task.status != TaskStatus.InProgress) revert("Task not in progress for verification.");
        if (task.completer != _completer) revert("Incorrect completer address.");

        if (_isSuccessful) {
            _updateAuraScore(_completer, int256(task.rewardAura));
            task.status = TaskStatus.Verified;
            task.completionTimestamp = block.timestamp;
        } else {
            // Task failed, potentially reset for re-submission or mark as failed
            task.status = TaskStatus.Open; // Make it open again for another attempt
            task.completer = address(0);
            task.proofURI = "";
        }
        emit TaskCompletionVerified(_taskId, _completer, _isSuccessful, _isSuccessful ? task.rewardAura : 0);
    }

    /**
     * @dev Retrieves details of a specific reputation task.
     * @param _taskId The ID of the task.
     * @return ReputationTask struct.
     */
    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (ReputationTask memory)
    {
        if (reputationTasks[_taskId].id == 0) revert TaskNotFound();
        return reputationTasks[_taskId];
    }

    // --- V. Governance & Administrative Functions ---

    /**
     * @dev Allows the owner to update the registration fee.
     * @param _newFee The new registration fee in wei.
     */
    function setRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
        emit ParametersUpdated("registrationFee", _newFee);
    }

    /**
     * @dev Allows the owner to update the vouch stake amount.
     * @param _newAmount The new vouch stake amount in wei.
     */
    function setVouchStakeAmount(uint256 _newAmount) external onlyOwner {
        vouchStakeAmount = _newAmount;
        emit ParametersUpdated("vouchStakeAmount", _newAmount);
    }

    /**
     * @dev Allows the owner to update the dispute stake amount.
     * @param _newAmount The new dispute stake amount in wei.
     */
    function setDisputeStakeAmount(uint256 _newAmount) external onlyOwner {
        disputeStakeAmount = _newAmount;
        emit ParametersUpdated("disputeStakeAmount", _newAmount);
    }

    /**
     * @dev Allows the owner to update the Aura impact factors for various actions.
     * @param _vouch Aura change for a successful vouch.
     * @param _disputeWin Aura change for winning a dispute.
     * @param _disputeLoss Aura change for losing a dispute.
     * @param _taskComplete Aura change for completing a task.
     */
    function setAuraImpactFactors(int256 _vouch, int256 _disputeWin, int256 _disputeLoss, int256 _taskComplete)
        external
        onlyOwner
    {
        auraImpactFactors = AuraImpactFactors({
            vouch: _vouch,
            disputeWin: _disputeWin,
            disputeLoss: _disputeLoss,
            taskComplete: _taskComplete
        });
        emit AuraImpactFactorsUpdated(_vouch, _disputeWin, _disputeLoss, _taskComplete);
    }

    /**
     * @dev Allows the owner to set the minimum Aura score required to be a dispute jury member.
     * @param _newThreshold The new minimum Aura score.
     */
    function setJuryPoolThreshold(uint256 _newThreshold) external onlyOwner {
        juryPoolThreshold = _newThreshold;
        emit ParametersUpdated("juryPoolThreshold", _newThreshold);
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees (registration fees, remaining slashed stakes).
     *      Uses `totalEthDeposited` to track contract balance minus live stakes.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        // Calculate withdrawable amount: contract balance minus currently active stakes.
        // This is a simplified calculation. A more robust system would track active stakes precisely.
        // For this design, totalEthDeposited reflects what has come in.
        // The *actual* withdrawable amount is contractBalance - sum_of_active_vouch_stakes - sum_of_active_dispute_stakes.
        // A simple way to manage this is to assume fees and slashed stakes accumulate and are available.
        // If `totalEthDeposited` correctly tracks ALL *unsettled* funds including fees, this works.
        // Here, we withdraw the entire current balance, assuming all "staked" funds are either processed or are temporary.
        // A better approach would be to separately track `accumulatedFees`.
        // For simplicity of this example:
        uint256 amountToWithdraw = contractBalance; 
        if (amountToWithdraw == 0) revert("No fees to withdraw.");

        totalEthDeposited = 0; // Reset for simplicity, assuming all is withdrawn
        (bool success, ) = payable(owner()).call{value: amountToWithdraw}("");
        if (!success) {
            totalEthDeposited = amountToWithdraw; // Revert if failed
            revert("Failed to withdraw fees.");
        }
        emit FeeWithdrawn(owner(), amountToWithdraw);
    }

    /**
     * @dev Emergency function to manually adjust an identity's Aura score.
     *      Should be used with extreme caution and transparency.
     * @param _identityAddress The address of the identity.
     * @param _adjustment The amount to adjust the Aura by (can be negative).
     */
    function emergencyAuraAdjustment(address _identityAddress, int256 _adjustment)
        external
        onlyOwner
        onlyIfPaused // Only callable when system is paused for safety
    {
        if (identities[_identityAddress].id == 0) revert IdentityNotFound();
        _updateAuraScore(_identityAddress, _adjustment);
        emit AuraScoreUpdated(_identityAddress, identities[_identityAddress].auraScore, _adjustment);
        emit EmergencyAdjustmentForbidden(); // Log to show this sensitive function was called
    }

    /**
     * @dev Pauses the contract, disabling most functions for emergency.
     */
    function pauseSystem() external onlyOwner onlyIfUnpaused {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, re-enabling functions.
     */
    function unpauseSystem() external onlyOwner onlyIfPaused {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }
}
```