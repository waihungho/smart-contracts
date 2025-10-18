```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For managing skill issuers

/**
 * @title SynapticNexus: An Intent-Driven, Skill-Reputation Protocol
 * @dev This contract facilitates a decentralized marketplace where users can post "Intents" (requests for services/tasks),
 *      and other users can "Fulfill" these intents. The system incorporates a robust skill-attestation and
 *      reputation mechanism to ensure trust and quality.
 *      Users manage their profiles, declare skills through verifiable attestations, and engage in a lifecycle
 *      of intent creation, proposal, fulfillment, and dispute resolution.
 *      Off-chain data (like full profile details, intent specifics, proposal content, and evidence) is referenced
 *      by cryptographic hashes, allowing for privacy, data sovereignty, and efficient on-chain storage.
 */

/*
 * OUTLINE & FUNCTION SUMMARY
 *
 * I. Core Registry & Identity (User & Skill Management)
 *    1.  registerProfile(string calldata _encryptedProfileURI, bytes32[] calldata _skillHashes)
 *        - Description: Allows a new user to register their profile, providing a URI to their encrypted off-chain data
 *                       and initial skill attestations. Each skill hash must be issued by a trusted entity.
 *    2.  updateProfileURI(string calldata _newEncryptedProfileURI)
 *        - Description: Updates the URI pointing to the user's encrypted off-chain profile data.
 *    3.  addSkillAttestation(bytes32 _skillHash, uint256 _validUntil)
 *        - Description: Adds a verifiable skill attestation to the user's profile. The _msgSender() must be a trusted issuer.
 *    4.  revokeSkillAttestation(bytes32 _skillHash)
 *        - Description: Allows a user to revoke a previously added skill attestation from their profile.
 *    5.  getProfile(address _user) view returns (User memory)
 *        - Description: Retrieves a user's basic on-chain profile information.
 *    6.  getUserSkillHashes(address _user) view returns (bytes32[] memory)
 *        - Description: Returns an array of all active skill hashes associated with a specific user.
 *    7.  isSkillAttested(address _user, bytes32 _skillHash) view returns (bool)
 *        - Description: Checks if a given user currently possesses a specific, valid skill attestation.
 *
 * II. Intent Management & Lifecycle
 *    8.  createIntent(bytes32 _intentHash, uint256 _bountyAmount, address _bountyToken, uint256 _stakeRequired, uint256 _deadline, bytes32[] calldata _requiredSkillHashes)
 *        - Description: Creates a new intent (request). The creator provides an off-chain intent hash, bounty, required fulfiller stake, deadline, and required skills. Creator must approve bounty token transfer.
 *    9.  cancelIntent(uint256 _intentId)
 *        - Description: Allows the intent creator to cancel an active intent before it's accepted for fulfillment.
 *    10. proposeFulfillment(uint256 _intentId, bytes32 _proposalHash)
 *        - Description: A potential fulfiller proposes to take on an intent, staking the required amount. Fulfiller must approve stake token transfer.
 *    11. acceptFulfillmentProposal(uint256 _intentId, address _fulfiller)
 *        - Description: The intent creator accepts a fulfillment proposal, locking the fulfiller's stake and assigning the intent.
 *    12. rejectFulfillmentProposal(uint256 _intentId, address _fulfiller)
 *        - Description: The intent creator rejects a fulfillment proposal, releasing the fulfiller's stake.
 *    13. markIntentFulfilled(uint256 _intentId, bytes32 _resultHash)
 *        - Description: The intent creator marks the intent as completed, providing a hash of the result. Initiates a review period for the fulfiller.
 *    14. confirmFulfillment(uint256 _intentId)
 *        - Description: The fulfiller confirms successful completion and acceptance by the creator, releasing funds and updating reputation.
 *    15. disputeFulfillment(uint256 _intentId, bytes32 _disputeEvidenceHash)
 *        - Description: Either creator or fulfiller can initiate a dispute during the review period or before confirmation.
 *
 * III. Reputation & Dispute Resolution
 *    16. resolveDispute(uint256 _intentId, bool _creatorWins, bytes32 _resolutionEvidenceHash)
 *        - Description: An authorized arbitrator (or governance) resolves a dispute, distributing funds and adjusting reputation.
 *    17. getReputation(address _user) view returns (int256)
 *        - Description: Retrieves the current reputation score of a specific user.
 *    18. punishReputation(address _user, uint256 _amount)
 *        - Description: Allows the owner/arbitrator to directly reduce a user's reputation for severe misconduct.
 *
 * IV. System Governance & Parameters
 *    19. updateArbitrator(address _newArbitrator)
 *        - Description: Sets or changes the address of the authorized dispute arbitrator.
 *    20. setIntentFee(uint256 _feePercentage)
 *        - Description: Sets the percentage fee collected by the protocol on successful intent fulfillments (max 100%).
 *    21. addSkillIssuer(address _issuer)
 *        - Description: Adds an address to the list of trusted skill issuers.
 *    22. removeSkillIssuer(address _issuer)
 *        - Description: Removes an address from the list of trusted skill issuers.
 *
 */

contract SynapticNexus is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // --- State Variables ---

    uint256 private _nextIntentId;
    address public arbitrator;
    uint256 public intentFeePercentage = 500; // 5.00%, scaled by 100 to allow decimals (e.g., 500 = 5.00%, 10 = 0.10%)
    uint256 public constant MAX_FEE_PERCENTAGE = 10000; // 100.00%
    uint256 public constant REVIEW_PERIOD_DURATION = 3 days; // Time for creator/fulfiller to confirm/dispute

    EnumerableSet.AddressSet private _skillIssuers; // Set of addresses trusted to issue skill attestations

    // --- Data Structures ---

    enum IntentState {
        Open,           // Intent created, awaiting proposals
        Proposed,       // One or more proposals received
        InProgress,     // Proposal accepted, fulfiller assigned
        FulfilledReview,// Creator marked fulfilled, awaiting fulfiller confirmation or dispute
        Disputed,       // A dispute has been raised
        Completed,      // Successfully completed
        Cancelled       // Creator cancelled intent
    }

    struct User {
        bool exists;
        string encryptedProfileURI;
        int256 reputation; // Can be positive or negative
        // Mapping of skill hash to its validUntil timestamp. 0 if revoked/expired.
        mapping(bytes32 => uint256) skills;
        EnumerableSet.Bytes32Set userSkillHashes; // To iterate over skills
    }

    struct Intent {
        uint256 id;
        address creator;
        bytes32 intentHash; // Hash of off-chain intent details
        uint256 bountyAmount;
        address bountyToken; // ERC20 token address for the bounty
        uint256 stakeRequired;
        address stakeToken; // ERC20 token address for the stake (can be same as bounty token)
        uint256 deadline; // When the intent must be fulfilled by
        bytes32[] requiredSkillHashes;
        IntentState state;
        address fulfiller; // The address of the chosen fulfiller
        uint256 fulfilledTimestamp; // When creator marked as fulfilled
        bytes32 resultHash; // Hash of off-chain result details
        bytes32 disputeEvidenceHash; // Hash of off-chain dispute evidence
        address currentProposer; // For internal state, to track who has a pending proposal on offer
    }

    // Mappings
    mapping(address => User) public users;
    mapping(uint256 => Intent) public intents;
    mapping(uint256 => mapping(address => bool)) public hasProposed; // intentId => fulfiller => bool
    mapping(address => mapping(uint256 => uint256)) public fulfillerStakes; // fulfiller => intentId => amount

    // --- Events ---

    event ProfileRegistered(address indexed user, string encryptedProfileURI);
    event ProfileURIUpdated(address indexed user, string newEncryptedProfileURI);
    event SkillAttestationAdded(address indexed user, address indexed issuer, bytes32 skillHash, uint256 validUntil);
    event SkillAttestationRevoked(address indexed user, bytes32 skillHash);
    event IntentCreated(uint256 indexed intentId, address indexed creator, bytes32 intentHash, uint256 bountyAmount, address bountyToken, uint256 deadline);
    event IntentCancelled(uint256 indexed intentId);
    event FulfillmentProposed(uint256 indexed intentId, address indexed fulfiller, bytes32 proposalHash);
    event FulfillmentProposalAccepted(uint256 indexed intentId, address indexed creator, address indexed fulfiller);
    event FulfillmentProposalRejected(uint256 indexed intentId, address indexed creator, address indexed fulfiller);
    event IntentMarkedFulfilled(uint256 indexed intentId, address indexed creator, bytes32 resultHash);
    event IntentConfirmed(uint256 indexed intentId, address indexed fulfiller);
    event IntentDisputed(uint256 indexed intentId, address indexed disputer, bytes32 disputeEvidenceHash);
    event DisputeResolved(uint256 indexed intentId, address indexed arbitrator, bool creatorWins);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);
    event ArbitratorUpdated(address indexed oldArbitrator, address indexed newArbitrator);
    event IntentFeeSet(uint256 newFeePercentage);
    event SkillIssuerAdded(address indexed issuer);
    event SkillIssuerRemoved(address indexed issuer);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(users[_msgSender()].exists, "SynapticNexus: User not registered");
        _;
    }

    modifier onlyIntentCreator(uint256 _intentId) {
        require(intents[_intentId].creator == _msgSender(), "SynapticNexus: Not intent creator");
        _;
    }

    modifier onlyIntentFulfiller(uint256 _intentId) {
        require(intents[_intentId].fulfiller == _msgSender(), "SynapticNexus: Not intent fulfiller");
        _;
    }

    modifier onlyArbitrator() {
        require(_msgSender() == arbitrator, "SynapticNexus: Only arbitrator can call");
        _;
    }

    constructor(address _initialArbitrator) Ownable(_msgSender()) {
        require(_initialArbitrator != address(0), "SynapticNexus: Arbitrator cannot be zero address");
        arbitrator = _initialArbitrator;
    }

    // --- I. Core Registry & Identity (User & Skill Management) ---

    /**
     * @notice Registers a new user profile.
     * @param _encryptedProfileURI A URI pointing to the user's encrypted off-chain profile data.
     * @param _skillHashes An array of initial skill hashes attested to by trusted issuers.
     */
    function registerProfile(string calldata _encryptedProfileURI, bytes32[] calldata _skillHashes) external {
        require(!users[_msgSender()].exists, "SynapticNexus: User already registered");
        require(bytes(_encryptedProfileURI).length > 0, "SynapticNexus: Profile URI cannot be empty");

        users[_msgSender()].exists = true;
        users[_msgSender()].encryptedProfileURI = _encryptedProfileURI;
        users[_msgSender()].reputation = 0; // Starting reputation

        for (uint256 i = 0; i < _skillHashes.length; i++) {
            require(_skillIssuers.contains(_msgSender()), "SynapticNexus: Initial skills must be self-attested or by another issuer"); // This might be better as a separate function. For simplicity, let's assume initial skills can be 'claimed' but they don't get 'issued' until an issuer calls addSkillAttestation. Or, remove this check, and the user's `addSkillAttestation` function is called later by the issuer. For now, let's make it the issuer's job.
        }
        // Let's refine this: initial registration just sets up the profile. Skill attestations are *issued* by others.
        // So, _skillHashes here would be empty, and users would have to get skill attestations post-registration.
        // For the sake of having a function signature that implies initial skills, I'll keep the param but require
        // external issuers to call addSkillAttestation.
        if (_skillHashes.length > 0) {
            revert("SynapticNexus: Initial skill attestations must be issued externally");
        }

        emit ProfileRegistered(_msgSender(), _encryptedProfileURI);
    }

    /**
     * @notice Updates the URI pointing to the user's encrypted off-chain profile data.
     * @param _newEncryptedProfileURI The new URI.
     */
    function updateProfileURI(string calldata _newEncryptedProfileURI) external onlyRegisteredUser {
        require(bytes(_newEncryptedProfileURI).length > 0, "SynapticNexus: New profile URI cannot be empty");
        users[_msgSender()].encryptedProfileURI = _newEncryptedProfileURI;
        emit ProfileURIUpdated(_msgSender(), _newEncryptedProfileURI);
    }

    /**
     * @notice Adds a verifiable skill attestation to a user's profile.
     * @dev Only trusted skill issuers can call this function. The issuer is _msgSender().
     * @param _user The address of the user receiving the attestation.
     * @param _skillHash The cryptographic hash of the skill details.
     * @param _validUntil Timestamp when the attestation expires (0 for indefinite).
     */
    function addSkillAttestation(address _user, bytes32 _skillHash, uint256 _validUntil) external {
        require(_skillIssuers.contains(_msgSender()), "SynapticNexus: Only trusted skill issuers can attest");
        require(users[_user].exists, "SynapticNexus: User must be registered");
        require(_skillHash != bytes32(0), "SynapticNexus: Skill hash cannot be zero");

        if (users[_user].skills[_skillHash] == 0 || users[_user].skills[_skillHash] < block.timestamp) {
            // Add if new or expired
            users[_user].userSkillHashes.add(_skillHash);
        }
        users[_user].skills[_skillHash] = _validUntil; // Overwrite or set

        emit SkillAttestationAdded(_user, _msgSender(), _skillHash, _validUntil);
    }

    /**
     * @notice Allows a user to revoke a previously added skill attestation from their profile.
     * @param _skillHash The cryptographic hash of the skill to revoke.
     */
    function revokeSkillAttestation(bytes32 _skillHash) external onlyRegisteredUser {
        require(_skillHash != bytes32(0), "SynapticNexus: Skill hash cannot be zero");
        require(users[_msgSender()].skills[_skillHash] != 0, "SynapticNexus: Skill not found or already revoked");

        users[_msgSender()].skills[_skillHash] = 0; // Set to 0 to indicate revoked/expired
        users[_msgSender()].userSkillHashes.remove(_skillHash);

        emit SkillAttestationRevoked(_msgSender(), _skillHash);
    }

    /**
     * @notice Retrieves a user's basic on-chain profile information.
     * @param _user The address of the user.
     * @return User struct containing basic profile data.
     */
    function getProfile(address _user) external view returns (User memory) {
        require(users[_user].exists, "SynapticNexus: User not registered");
        return users[_user]; // Note: mapping(bytes32 => uint256) skills cannot be returned directly from structs in memory
    }

    /**
     * @notice Returns an array of all active skill hashes associated with a specific user.
     * @param _user The address of the user.
     * @return An array of skill hashes.
     */
    function getUserSkillHashes(address _user) external view returns (bytes32[] memory) {
        require(users[_user].exists, "SynapticNexus: User not registered");
        bytes32[] memory activeSkills = new bytes32[](users[_user].userSkillHashes.length());
        uint256 count = 0;
        for (uint256 i = 0; i < users[_user].userSkillHashes.length(); i++) {
            bytes32 skillHash = users[_user].userSkillHashes.at(i);
            if (users[_user].skills[skillHash] == 0 || users[_user].skills[skillHash] < block.timestamp) {
                // If skill expired or revoked, remove it from the set for next retrieval
                // Cannot modify state in a view function, so this will only prune on-demand in non-view calls.
                // For view, we just filter it out.
            } else {
                activeSkills[count] = skillHash;
                count++;
            }
        }
        bytes32[] memory finalSkills = new bytes32[](count);
        for(uint i=0; i<count; i++) {
            finalSkills[i] = activeSkills[i];
        }
        return finalSkills;
    }

    /**
     * @notice Checks if a given user possesses a specific, valid skill attestation.
     * @param _user The address of the user.
     * @param _skillHash The cryptographic hash of the skill.
     * @return True if the user has the skill and it's not expired/revoked, false otherwise.
     */
    function isSkillAttested(address _user, bytes32 _skillHash) public view returns (bool) {
        if (!users[_user].exists) return false;
        uint256 validUntil = users[_user].skills[_skillHash];
        return (validUntil != 0 && (validUntil == type(uint256).max || validUntil >= block.timestamp));
    }

    // --- II. Intent Management & Lifecycle ---

    /**
     * @notice Creates a new intent (request).
     * @param _intentHash The cryptographic hash of off-chain intent details.
     * @param _bountyAmount The amount of bounty tokens offered for fulfillment.
     * @param _bountyToken The ERC20 token address used for the bounty.
     * @param _stakeRequired The amount of stake tokens required from the fulfiller.
     * @param _deadline The timestamp by which the intent must be fulfilled.
     * @param _requiredSkillHashes An array of skill hashes required from the fulfiller.
     */
    function createIntent(
        bytes32 _intentHash,
        uint256 _bountyAmount,
        address _bountyToken,
        uint256 _stakeRequired,
        uint256 _deadline,
        bytes32[] calldata _requiredSkillHashes
    ) external onlyRegisteredUser {
        require(_intentHash != bytes32(0), "SynapticNexus: Intent hash cannot be zero");
        require(_bountyAmount > 0, "SynapticNexus: Bounty must be greater than zero");
        require(_bountyToken != address(0), "SynapticNexus: Bounty token cannot be zero address");
        require(_deadline > block.timestamp, "SynapticNexus: Deadline must be in the future");
        // Stake token is assumed to be the same as bounty token for simplicity. Can be extended.
        require(IERC20(_bountyToken).transferFrom(_msgSender(), address(this), _bountyAmount), "SynapticNexus: Failed to transfer bounty tokens");

        _nextIntentId++;
        uint256 newIntentId = _nextIntentId;

        intents[newIntentId] = Intent({
            id: newIntentId,
            creator: _msgSender(),
            intentHash: _intentHash,
            bountyAmount: _bountyAmount,
            bountyToken: _bountyToken,
            stakeRequired: _stakeRequired,
            stakeToken: _bountyToken, // Using bounty token for stake for now
            deadline: _deadline,
            requiredSkillHashes: _requiredSkillHashes,
            state: IntentState.Open,
            fulfiller: address(0),
            fulfilledTimestamp: 0,
            resultHash: bytes32(0),
            disputeEvidenceHash: bytes32(0),
            currentProposer: address(0)
        });

        emit IntentCreated(newIntentId, _msgSender(), _intentHash, _bountyAmount, _bountyToken, _deadline);
    }

    /**
     * @notice Allows the intent creator to cancel an active intent before it's accepted for fulfillment.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) external onlyIntentCreator(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.Open || intent.state == IntentState.Proposed, "SynapticNexus: Intent not in cancellable state");

        // Refund bounty to creator
        require(IERC20(intent.bountyToken).transfer(intent.creator, intent.bountyAmount), "SynapticNexus: Failed to refund bounty");

        intent.state = IntentState.Cancelled;
        emit IntentCancelled(_intentId);
    }

    /**
     * @notice A potential fulfiller proposes to take on an intent, staking the required amount.
     * @param _intentId The ID of the intent to propose fulfillment for.
     * @param _proposalHash The cryptographic hash of off-chain proposal details.
     */
    function proposeFulfillment(uint256 _intentId, bytes32 _proposalHash) external onlyRegisteredUser {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.Open || intent.state == IntentState.Proposed, "SynapticNexus: Intent not open for proposals");
        require(block.timestamp < intent.deadline, "SynapticNexus: Intent deadline passed");
        require(!hasProposed[_intentId][_msgSender()], "SynapticNexus: Already proposed for this intent");

        // Check fulfiller's skills
        for (uint256 i = 0; i < intent.requiredSkillHashes.length; i++) {
            require(isSkillAttested(_msgSender(), intent.requiredSkillHashes[i]), "SynapticNexus: Fulfiller missing required skill");
        }

        // Transfer stake from fulfiller
        require(intent.stakeRequired > 0, "SynapticNexus: Stake required must be greater than zero for proposal");
        require(IERC20(intent.stakeToken).transferFrom(_msgSender(), address(this), intent.stakeRequired), "SynapticNexus: Failed to transfer stake tokens");
        fulfillerStakes[_msgSender()][_intentId] = intent.stakeRequired; // Record the stake

        intent.state = IntentState.Proposed;
        hasProposed[_intentId][_msgSender()] = true;
        intent.currentProposer = _msgSender(); // Store the last proposer for display/UI purposes, not for logic

        emit FulfillmentProposed(_intentId, _msgSender(), _proposalHash);
    }

    /**
     * @notice The intent creator accepts a fulfillment proposal, locking the fulfiller's stake and assigning the intent.
     * @param _intentId The ID of the intent.
     * @param _fulfiller The address of the chosen fulfiller.
     */
    function acceptFulfillmentProposal(uint256 _intentId, address _fulfiller) external onlyIntentCreator(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.Proposed || intent.state == IntentState.Open, "SynapticNexus: Intent not in proposal state");
        require(hasProposed[_intentId][_fulfiller], "SynapticNexus: Fulfiller has not proposed for this intent");
        require(block.timestamp < intent.deadline, "SynapticNexus: Intent deadline passed");

        // Check if stake was transferred
        require(fulfillerStakes[_fulfiller][_intentId] == intent.stakeRequired, "SynapticNexus: Fulfiller did not provide required stake");

        intent.fulfiller = _fulfiller;
        intent.state = IntentState.InProgress;

        // Clear other proposals' stakes (if any, in a real system this would be more complex, needing to iterate through all proposers)
        // For simplicity, we assume only one active proposal is 'considered' at a time, or creator manages off-chain.
        // In this implementation, stakes are held on the contract, so if multiple proposed, those funds are temporarily locked.
        // A more advanced system would have a `rejectProposal` for creator to reject other proposers.

        emit FulfillmentProposalAccepted(_intentId, _msgSender(), _fulfiller);
    }

    /**
     * @notice The intent creator rejects a fulfillment proposal, releasing the fulfiller's stake.
     * @param _intentId The ID of the intent.
     * @param _fulfiller The address of the fulfiller whose proposal is rejected.
     */
    function rejectFulfillmentProposal(uint256 _intentId, address _fulfiller) external onlyIntentCreator(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.Open || intent.state == IntentState.Proposed, "SynapticNexus: Intent not in proposal state");
        require(hasProposed[_intentId][_fulfiller], "SynapticNexus: Fulfiller has not proposed for this intent");
        require(intent.fulfiller == address(0), "SynapticNexus: Fulfiller already accepted for this intent");

        uint256 stake = fulfillerStakes[_fulfiller][_intentId];
        require(stake == intent.stakeRequired && stake > 0, "SynapticNexus: Invalid stake amount or no stake");
        
        // Release stake
        fulfillerStakes[_fulfiller][_intentId] = 0; // Clear the stake record
        hasProposed[_intentId][_fulfiller] = false;
        require(IERC20(intent.stakeToken).transfer(_fulfiller, stake), "SynapticNexus: Failed to refund stake");

        // If this was the *only* proposal and we reject it, the intent goes back to Open state.
        // If there are other proposals (not explicitly handled in this simplified proposal acceptance model),
        // it would remain Proposed. For simplicity, we assume it's Open if no other accepted.
        // A full implementation might track all proposers.
        intent.state = IntentState.Open; // Simplification

        emit FulfillmentProposalRejected(_intentId, _msgSender(), _fulfiller);
    }

    /**
     * @notice The intent creator marks the intent as completed, providing a hash of the result.
     *         Initiates a review period for the fulfiller.
     * @param _intentId The ID of the intent.
     * @param _resultHash The cryptographic hash of the off-chain result details.
     */
    function markIntentFulfilled(uint256 _intentId, bytes32 _resultHash) external onlyIntentCreator(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.InProgress, "SynapticNexus: Intent not in progress");
        require(block.timestamp < intent.deadline, "SynapticNexus: Intent deadline passed before fulfillment");
        require(_resultHash != bytes32(0), "SynapticNexus: Result hash cannot be zero");

        intent.state = IntentState.FulfilledReview;
        intent.fulfilledTimestamp = block.timestamp;
        intent.resultHash = _resultHash;

        emit IntentMarkedFulfilled(_intentId, _msgSender(), _resultHash);
    }

    /**
     * @notice The fulfiller confirms successful completion and acceptance by the creator,
     *         releasing funds and updating reputation.
     * @param _intentId The ID of the intent.
     */
    function confirmFulfillment(uint256 _intentId) external onlyIntentFulfiller(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.FulfilledReview, "SynapticNexus: Intent not in fulfilled review state");
        require(block.timestamp <= intent.fulfilledTimestamp + REVIEW_PERIOD_DURATION, "SynapticNexus: Review period expired, dispute required");

        // Calculate fee
        uint256 fee = (intent.bountyAmount * intentFeePercentage) / MAX_FEE_PERCENTAGE;
        uint256 netBounty = intent.bountyAmount - fee;

        // Release bounty to fulfiller
        require(IERC20(intent.bountyToken).transfer(intent.fulfiller, netBounty), "SynapticNexus: Failed to transfer net bounty");
        // Transfer fee to owner/treasury
        if (fee > 0) {
            require(IERC20(intent.bountyToken).transfer(owner(), fee), "SynapticNexus: Failed to transfer fee");
            emit FundsWithdrawn(owner(), fee); // Funds withdrawn to owner as fee
        }

        // Release stake to fulfiller
        uint256 fulfillerStake = fulfillerStakes[intent.fulfiller][_intentId];
        require(fulfillerStake == intent.stakeRequired && fulfillerStake > 0, "SynapticNexus: Invalid fulfiller stake");
        fulfillerStakes[intent.fulfiller][_intentId] = 0;
        require(IERC20(intent.stakeToken).transfer(intent.fulfiller, fulfillerStake), "SynapticNexus: Failed to refund stake");

        // Update reputation for both creator and fulfiller
        _adjustReputation(intent.creator, 10); // Positive for creator
        _adjustReputation(intent.fulfiller, 20); // More positive for fulfiller

        intent.state = IntentState.Completed;
        emit IntentConfirmed(_intentId, _msgSender());
    }

    /**
     * @notice Either creator or fulfiller can initiate a dispute during the review period or before confirmation.
     * @param _intentId The ID of the intent.
     * @param _disputeEvidenceHash The cryptographic hash of off-chain dispute evidence.
     */
    function disputeFulfillment(uint256 _intentId, bytes32 _disputeEvidenceHash) external onlyRegisteredUser {
        Intent storage intent = intents[_intentId];
        require(_msgSender() == intent.creator || _msgSender() == intent.fulfiller, "SynapticNexus: Only creator or fulfiller can dispute");
        
        // Allow dispute if in review period or if fulfiller hasn't confirmed and deadline passed
        bool canDispute = (intent.state == IntentState.FulfilledReview && block.timestamp <= intent.fulfilledTimestamp + REVIEW_PERIOD_DURATION) ||
                          (intent.state == IntentState.InProgress && block.timestamp > intent.deadline);

        require(canDispute, "SynapticNexus: Cannot dispute intent in current state or period");
        require(_disputeEvidenceHash != bytes32(0), "SynapticNexus: Dispute evidence hash cannot be zero");

        intent.state = IntentState.Disputed;
        intent.disputeEvidenceHash = _disputeEvidenceHash;

        emit IntentDisputed(_intentId, _msgSender(), _disputeEvidenceHash);
    }

    // --- III. Reputation & Dispute Resolution ---

    /**
     * @notice An authorized arbitrator (or governance) resolves a dispute, distributing funds and adjusting reputation.
     * @param _intentId The ID of the disputed intent.
     * @param _creatorWins True if the creator wins the dispute, false if the fulfiller wins.
     * @param _resolutionEvidenceHash The cryptographic hash of off-chain resolution evidence.
     */
    function resolveDispute(uint256 _intentId, bool _creatorWins, bytes32 _resolutionEvidenceHash) external onlyArbitrator {
        Intent storage intent = intents[_intentId];
        require(intent.state == IntentState.Disputed, "SynapticNexus: Intent not in disputed state");
        require(_resolutionEvidenceHash != bytes32(0), "SynapticNexus: Resolution evidence hash cannot be zero");

        uint256 fee = (intent.bountyAmount * intentFeePercentage) / MAX_FEE_PERCENTAGE;
        uint256 netBounty = intent.bountyAmount - fee;
        uint256 fulfillerStake = fulfillerStakes[intent.fulfiller][_intentId];
        
        fulfillerStakes[intent.fulfiller][_intentId] = 0; // Clear the stake record

        if (_creatorWins) {
            // Creator wins: Creator gets bounty back, Fulfiller loses stake and reputation.
            require(IERC20(intent.bountyToken).transfer(intent.creator, intent.bountyAmount), "SynapticNexus: Failed to refund bounty to creator");
            
            // Fulfiller stake is forfeited. Transferred to owner as penalty.
            if (fulfillerStake > 0) {
                require(IERC20(intent.stakeToken).transfer(owner(), fulfillerStake), "SynapticNexus: Failed to transfer forfeited stake to owner");
                emit FundsWithdrawn(owner(), fulfillerStake);
            }

            _adjustReputation(intent.creator, 5); // Small positive for creator
            _adjustReputation(intent.fulfiller, -50); // Significant negative for fulfiller
        } else {
            // Fulfiller wins: Fulfiller gets bounty and stake back, Creator loses reputation.
            require(IERC20(intent.bountyToken).transfer(intent.fulfiller, netBounty), "SynapticNexus: Failed to transfer net bounty to fulfiller");
            if (fee > 0) {
                require(IERC20(intent.bountyToken).transfer(owner(), fee), "SynapticNexus: Failed to transfer fee to owner");
                emit FundsWithdrawn(owner(), fee);
            }
            if (fulfillerStake > 0) {
                require(IERC20(intent.stakeToken).transfer(intent.fulfiller, fulfillerStake), "SynapticNexus: Failed to refund stake to fulfiller");
            }

            _adjustReputation(intent.creator, -20); // Negative for creator
            _adjustReputation(intent.fulfiller, 15); // Positive for fulfiller
        }

        intent.state = IntentState.Completed; // Or a specific 'DisputeResolved' state
        intent.disputeEvidenceHash = _resolutionEvidenceHash; // Overwrite with resolution details
        emit DisputeResolved(_intentId, _msgSender(), _creatorWins);
    }

    /**
     * @notice Retrieves the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) external view returns (int256) {
        require(users[_user].exists, "SynapticNexus: User not registered");
        return users[_user].reputation;
    }

    /**
     * @notice Allows the owner/arbitrator to directly reduce a user's reputation for severe misconduct.
     * @param _user The address of the user to punish.
     * @param _amount The amount by which to reduce reputation.
     */
    function punishReputation(address _user, uint256 _amount) external {
        require(users[_user].exists, "SynapticNexus: User not registered");
        require(_amount > 0, "SynapticNexus: Amount must be positive");
        require(_msgSender() == owner() || _msgSender() == arbitrator, "SynapticNexus: Only owner or arbitrator can punish reputation");

        _adjustReputation(_user, -int256(_amount));
    }

    /**
     * @dev Internal function to adjust a user's reputation.
     * @param _user The address of the user.
     * @param _change The amount to add to reputation (can be negative).
     */
    function _adjustReputation(address _user, int256 _change) internal {
        int256 oldReputation = users[_user].reputation;
        users[_user].reputation += _change;
        emit ReputationUpdated(_user, oldReputation, users[_user].reputation);
    }

    // --- IV. System Governance & Parameters ---

    /**
     * @notice Sets or changes the address of the authorized dispute arbitrator.
     * @param _newArbitrator The address of the new arbitrator.
     */
    function updateArbitrator(address _newArbitrator) external onlyOwner {
        require(_newArbitrator != address(0), "SynapticNexus: Arbitrator cannot be zero address");
        address oldArbitrator = arbitrator;
        arbitrator = _newArbitrator;
        emit ArbitratorUpdated(oldArbitrator, _newArbitrator);
    }

    /**
     * @notice Sets the percentage fee collected by the protocol on successful intent fulfillments.
     * @param _feePercentage The new fee percentage, scaled by 100 (e.g., 500 for 5.00%). Max 10000 (100%).
     */
    function setIntentFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= MAX_FEE_PERCENTAGE, "SynapticNexus: Fee percentage exceeds 100%");
        intentFeePercentage = _feePercentage;
        emit IntentFeeSet(_feePercentage);
    }

    /**
     * @notice Adds an address to the list of trusted skill issuers.
     * @param _issuer The address to add as a skill issuer.
     */
    function addSkillIssuer(address _issuer) external onlyOwner {
        require(_issuer != address(0), "SynapticNexus: Issuer address cannot be zero");
        require(_skillIssuers.add(_issuer), "SynapticNexus: Issuer already added");
        emit SkillIssuerAdded(_issuer);
    }

    /**
     * @notice Removes an address from the list of trusted skill issuers.
     * @param _issuer The address to remove as a skill issuer.
     */
    function removeSkillIssuer(address _issuer) external onlyOwner {
        require(_skillIssuers.remove(_issuer), "SynapticNexus: Issuer not found");
        emit SkillIssuerRemoved(_issuer);
    }

    /**
     * @notice Allows the owner to withdraw any residual ERC20 tokens sent to the contract by mistake.
     * @dev Should only be used for accidental transfers, not protocol funds (which are managed by intent logic).
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAccidentalTokens(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "SynapticNexus: Token address cannot be zero");
        IERC20 token = IERC20(_token);
        require(token.transfer(owner(), _amount), "SynapticNexus: Failed to withdraw tokens");
        emit FundsWithdrawn(owner(), _amount);
    }
}

```