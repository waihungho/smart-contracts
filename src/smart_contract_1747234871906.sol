Okay, here is a Solidity smart contract for a Decentralized Reputation and Skill Verification Network.

This contract aims to create a system where users can attest to each other's skills, where certain attestations can be verified for added weight, and where users can earn non-transferable badges representing verified skills. It also includes a basic governance mechanism for managing skills and badge types, and a simple challenge system for attestations.

It incorporates concepts like:
*   Structured Data (Structs for Users, Skills, Attestations, etc.)
*   Access Control (Owner, Verifiers, Trusted Attesters, Governance)
*   Complex Mappings (Mapping multiple keys, mapping structs)
*   Events for State Changes
*   Timestamps for Validity/Expiry (though not fully implemented for expiry here, the structure allows it)
*   Non-Transferable Tokens/Badges (Simulated via a mapping)
*   On-chain Attestation and Verification Logic
*   Simple On-chain Governance (Proposal, Voting, Execution)
*   Challenge Mechanism

**Outline and Function Summary**

**Contract Name:** `DecentralizedReputationNetwork`

**Core Concepts:**
1.  **User Profiles:** Users can register and update a profile hash (pointing to off-chain metadata).
2.  **Skills:** Defined skills that users can be attested for. Managed via governance.
3.  **Attestations:** One user attests to another user having a specific skill. Attestations have a strength/weight.
4.  **Verifiers:** Designated addresses that can verify specific attestations, increasing their credibility. Managed via governance.
5.  **Trusted Attesters:** Designated addresses (e.g., organizations, DAOs) whose attestations carry more weight initially. Managed via governance.
6.  **Verification Requests:** Users can request verification for received attestations.
7.  **Challenges:** Users can challenge existing attestations.
8.  **Badges:** Non-transferable tokens/status representing verified skills (Soulbound-like). Earned based on verified attestations. Managed via governance.
9.  **Governance:** Simple system for proposals, voting, and executing changes (e.g., adding skills, badge types, managing verifiers/trusted attesters).

**State Variables:**
*   `owner`: The contract owner.
*   `userProfiles`: Mapping from address to `UserProfile`.
*   `skills`: Mapping from skill ID to `Skill`.
*   `skillNameToId`: Mapping from skill name to skill ID for lookup.
*   `attestations`: Mapping from attestation ID to `Attestation`.
*   `attestationCounter`: Counter for unique attestation IDs.
*   `skillCounter`: Counter for unique skill IDs.
*   `badgeTypes`: Mapping from badge ID to `BadgeType`.
*   `badgeTypeCounter`: Counter for unique badge IDs.
*   `userBadges`: Mapping from user address to a mapping of badge ID to boolean (has badge).
*   `verifiers`: Mapping from address to boolean (is verifier).
*   `trustedAttesters`: Mapping from address to boolean (is trusted attester).
*   `attestationVerifications`: Mapping from attestation ID to `Verification`.
*   `challenges`: Mapping from attestation ID to `Challenge`.
*   `governanceProposals`: Mapping from proposal ID to `Proposal`.
*   `proposalCounter`: Counter for unique proposal IDs.
*   `votedProposals`: Mapping from user address to mapping from proposal ID to boolean (has voted).
*   `governanceParams`: Struct holding governance parameters (e.g., voting period, quorum, approval threshold).

**Structs:**
*   `UserProfile`: address, string profileHash, uint[] receivedAttestationIds, uint[] givenAttestationIds.
*   `Skill`: uint id, string name, string description.
*   `Attestation`: uint id, address attester, address attestedUser, uint skillId, uint strength, uint timestamp, bool revoked.
*   `Verification`: address verifier, uint timestamp, bool approved, string reason.
*   `BadgeType`: uint id, string name, string description, uint requiredSkillId, uint requiredVerifiedAttestations.
*   `Challenge`: address challenger, string reason, uint timestamp, bool resolved, bool upheld.
*   `Proposal`: uint id, string description, uint creationTimestamp, uint votingDeadline, ProposalState state, uint yesVotes, uint noVotes, bytes callData, address targetContract.
*   `GovernanceParams`: uint votingPeriodSeconds, uint quorumPercentage, uint approvalPercentage.

**Enums:**
*   `ProposalState`: Pending, Active, Canceled, Defeated, Succeeded, Executed.

**Events:**
*   `ProfileRegistered(address indexed user, string profileHash)`
*   `ProfileUpdated(address indexed user, string profileHash)`
*   `SkillAdded(uint indexed skillId, string name)`
*   `AttestationGiven(uint indexed attestationId, address indexed attester, address indexed attestedUser, uint skillId, uint strength)`
*   `AttestationRevoked(uint indexed attestationId, address indexed revoker)`
*   `VerifierStatusChanged(address indexed verifier, bool isVerifier)`
*   `TrustedAttesterStatusChanged(address indexed attester, bool isTrusted)`
*   `AttestationVerified(uint indexed attestationId, address indexed verifier, bool approved)`
*   `BadgeTypeAdded(uint indexed badgeId, string name)`
*   `BadgeClaimed(uint indexed badgeId, address indexed user)`
*   `ProposalCreated(uint indexed proposalId, address indexed creator, string description)`
*   `Voted(uint indexed proposalId, address indexed voter, bool support)`
*   `ProposalStateChanged(uint indexed proposalId, ProposalState newState)`
*   `AttestationChallenged(uint indexed attestationId, address indexed challenger, string reason)`
*   `ChallengeResolved(uint indexed attestationId, bool upheld)`

**Function Summary (20+ Functions):**

1.  `constructor()`: Initializes contract owner and default governance parameters.
2.  `registerProfile(string _profileHash)`: Creates a user profile.
3.  `updateProfileHash(string _profileHash)`: Updates a user's profile hash.
4.  `addSkill(string _name, string _description)`: Adds a new skill (Owner/Governance).
5.  `attestSkill(address _user, uint _skillId, uint _strength)`: Gives an attestation for a skill to a user.
6.  `revokeAttestationGiven(uint _attestationId)`: Revokes an attestation the sender previously gave.
7.  `applyForVerifier()`: User applies to become a verifier (requires governance approval).
8.  `approveVerifier(address _verifier)`: Grants verifier status (Owner/Governance).
9.  `rejectVerifierApplication(address _verifier)`: Rejects verifier application (Owner/Governance).
10. `removeVerifier(address _verifier)`: Removes verifier status (Owner/Governance).
11. `verifyAttestation(uint _attestationId, bool _approved, string _reason)`: Verifier approves/rejects an attestation verification request.
12. `addTrustedAttester(address _attester)`: Adds a trusted attester (Owner/Governance).
13. `removeTrustedAttester(address _attester)`: Removes a trusted attester (Owner/Governance).
14. `addBadgeType(string _name, string _description, uint _requiredSkillId, uint _requiredVerifiedAttestations)`: Adds a new badge type (Owner/Governance).
15. `updateBadgeRequirements(uint _badgeId, uint _requiredSkillId, uint _requiredVerifiedAttestations)`: Updates badge requirements (Owner/Governance).
16. `canClaimBadge(address _user, uint _badgeId)`: Checks if a user meets the requirements for a badge (View).
17. `claimBadge(uint _badgeId)`: Allows a user to claim a badge if requirements are met.
18. `createProposal(string _description, bytes _callData, address _targetContract)`: Creates a new governance proposal.
19. `vote(uint _proposalId, bool _support)`: Casts a vote on a proposal.
20. `executeProposal(uint _proposalId)`: Executes a successful proposal.
21. `challengeAttestation(uint _attestationId, string _reason)`: Challenges an attestation.
22. `resolveChallenge(uint _attestationId, bool _upheld)`: Resolves a challenge (Verifier/Governance).
23. `setGovernanceParameters(uint _votingPeriodSeconds, uint _quorumPercentage, uint _approvalPercentage)`: Sets governance parameters (Owner/Governance).
24. `getUserProfile(address _user)`: Gets a user's profile (View).
25. `getSkillDetails(uint _skillId)`: Gets skill details (View).
26. `getAttestationDetails(uint _attestationId)`: Gets attestation details (View).
27. `getAttestationVerificationStatus(uint _attestationId)`: Gets verification status (View).
28. `getBadgeDetails(uint _badgeId)`: Gets badge details (View).
29. `hasBadge(address _user, uint _badgeId)`: Checks if user has a badge (View).
30. `isVerifier(address _user)`: Checks if user is a verifier (View).
31. `isTrustedAttester(address _user)`: Checks if user is a trusted attester (View).
32. `getProposalDetails(uint _proposalId)`: Gets proposal details (View).
33. `getTotalAttestationsForSkill(address _user, uint _skillId)`: Counts attestations for a skill (View).
34. `getTotalVerifiedAttestationsForSkill(address _user, uint _skillId)`: Counts *verified* attestations for a skill (View).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedReputationNetwork
 * @dev A smart contract for managing decentralized user reputation and skill verification.
 * Users can attest to each other's skills, verifiers can approve attestations,
 * and users can earn non-transferable badges based on verified skills.
 * Includes a basic governance system for managing skills, badges, verifiers, and trusted attesters.
 */
contract DecentralizedReputationNetwork {

    // --- State Variables ---

    address public owner;

    struct UserProfile {
        address userAddress;
        string profileHash; // IPFS hash or similar for off-chain metadata
        uint[] receivedAttestationIds;
        uint[] givenAttestationIds;
        // Potentially add a reputation score here
    }
    mapping(address => UserProfile) private userProfiles;
    mapping(address => bool) private profileExists; // To check if a profile is registered

    struct Skill {
        uint id;
        string name;
        string description;
        bool active; // Can be deactivated via governance
    }
    mapping(uint => Skill) private skills;
    mapping(string => uint) private skillNameToId;
    uint public skillCounter; // Starts from 1

    struct Attestation {
        uint id;
        address attester;
        address attestedUser;
        uint skillId;
        uint strength; // e.g., 1-5, or a more complex score
        uint timestamp;
        bool revoked; // Attester can revoke their own attestation
    }
    mapping(uint => Attestation) private attestations;
    uint public attestationCounter; // Starts from 1

    struct Verification {
        address verifier; // Address of the verifier
        uint timestamp;
        bool approved; // True if approved, false if rejected
        string reason;
        bool exists; // To check if a verification exists for an attestation
    }
    mapping(uint => Verification) private attestationVerifications; // attestationId => Verification

    struct BadgeType {
        uint id;
        string name;
        string description;
        uint requiredSkillId; // The skill this badge is related to
        uint requiredVerifiedAttestations; // Number of verified attestations for this skill to earn the badge
        bool active; // Can be deactivated via governance
    }
    mapping(uint => BadgeType) private badgeTypes;
    uint public badgeTypeCounter; // Starts from 1

    // Represents non-transferable badges ("Soulbound"). userAddress => badgeId => hasBadge
    mapping(address => mapping(uint => bool)) private userBadges;

    mapping(address => bool) private verifiers; // Addresses eligible to verify attestations
    mapping(address => bool) private trustedAttesters; // Addresses whose attestations get extra weight

    struct Challenge {
        address challenger;
        string reason;
        uint timestamp;
        bool resolved;
        bool upheld; // True if challenger wins (attestation deemed invalid)
        // Could add a stake amount and resolution process (e.g., jury system or verifier decision)
    }
    mapping(uint => Challenge) private challenges; // attestationId => Challenge
    mapping(uint => bool) private hasActiveChallenge; // attestationId => has active challenge

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        uint id;
        string description;
        uint creationTimestamp;
        uint votingDeadline;
        ProposalState state;
        uint yesVotes;
        uint noVotes;
        bytes callData; // The function call to execute if proposal succeeds
        address targetContract; // The contract to call (could be this contract)
        // Could add proposer address, minimum stake to propose, etc.
    }
    mapping(uint => Proposal) private governanceProposals;
    uint public proposalCounter; // Starts from 1
    mapping(address => mapping(uint => bool)) private votedProposals; // userAddress => proposalId => hasVoted

    struct GovernanceParams {
        uint votingPeriodSeconds;
        uint quorumPercentage; // e.g., 4% (400 for 400/10000)
        uint approvalPercentage; // e.g., 50% (5000 for 5000/10000)
        // Add parameters like proposal creation fee, challenge fee, etc.
    }
    GovernanceParams public governanceParams;

    // --- Events ---

    event ProfileRegistered(address indexed user, string profileHash);
    event ProfileUpdated(address indexed user, string profileHash);
    event SkillAdded(uint indexed skillId, string name, string description);
    event SkillDeactivated(uint indexed skillId);
    event AttestationGiven(uint indexed attestationId, address indexed attester, address indexed attestedUser, uint skillId, uint strength, uint timestamp);
    event AttestationRevoked(uint indexed attestationId, address indexed revoker);
    event VerifierStatusChanged(address indexed verifier, bool isVerifier);
    event TrustedAttesterStatusChanged(address indexed attester, bool isTrusted);
    event AttestationVerificationRequested(uint indexed attestationId, address indexed requester); // Not explicitly in functions yet, but good event
    event AttestationVerified(uint indexed attestationId, address indexed verifier, bool approved, string reason);
    event BadgeTypeAdded(uint indexed badgeId, string name, string description);
    event BadgeTypeDeactivated(uint indexed badgeId);
    event BadgeRequirementsUpdated(uint indexed badgeId, uint requiredSkillId, uint requiredVerifiedAttestations);
    event BadgeClaimed(uint indexed badgeId, address indexed user);
    event ProposalCreated(uint indexed proposalId, address indexed creator, string description, uint votingDeadline);
    event Voted(uint indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint indexed proposalId);
    event AttestationChallenged(uint indexed attestationId, address indexed challenger, string reason);
    event ChallengeResolved(uint indexed attestationId, bool upheld);
    event GovernanceParametersUpdated(uint votingPeriodSeconds, uint quorumPercentage, uint approvalPercentage);

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Set default governance parameters
        governanceParams = GovernanceParams({
            votingPeriodSeconds: 7 days, // 7 days voting period
            quorumPercentage: 400,       // 4% quorum (out of 10000)
            approvalPercentage: 5000     // 50% + 1 approval (out of 10000)
        });
    }

    // --- Access Control & Helpers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    // Internal helper function to check if an address is a verifier
    function _isVerifier(address _addr) internal view returns (bool) {
        return verifiers[_addr];
    }

    // Internal helper function to check if an address is a trusted attester
    function _isTrustedAttester(address _addr) internal view returns (bool) {
        return trustedAttesters[_addr];
    }

    // Helper to get total voting supply (simple sum of registered users for now)
    // In a more advanced system, this could be based on reputation score, token holdings, etc.
    function _getTotalVotingSupply() internal view returns (uint) {
        // This is a simplified model. A real system would need a way to track active voters or use a token supply.
        // For this example, let's assume everyone with a profile can vote with 1 weight.
        // A proper implementation might iterate through `userProfiles` or use a separate counter/mapping.
        // Since iterating mappings is bad practice, let's fake it for this example, or require voting tokens.
        // Let's assume voting power is 1 per registered user and we track a count.
         // NOTE: This approach requires tracking registered user count separately, which is omitted for brevity.
         // A realistic DAO would use token balances (ERC20) for voting power.
        return 100; // Placeholder: Assume 100 active potential voters for example calculation
    }

    // --- Core Functionality ---

    /**
     * @dev Registers a user profile.
     * @param _profileHash Hash pointing to off-chain profile data.
     */
    function registerProfile(string memory _profileHash) public {
        require(!profileExists[msg.sender], "Profile already registered");
        userProfiles[msg.sender].userAddress = msg.sender;
        userProfiles[msg.sender].profileHash = _profileHash;
        profileExists[msg.sender] = true;
        emit ProfileRegistered(msg.sender, _profileHash);
    }

    /**
     * @dev Updates a user's profile hash.
     * @param _profileHash New hash pointing to off-chain profile data.
     */
    function updateProfileHash(string memory _profileHash) public {
        require(profileExists[msg.sender], "Profile not registered");
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender, _profileHash);
    }

    /**
     * @dev Adds a new skill type. Requires governance approval (via proposal) or owner if no active governance.
     * @param _name Name of the skill.
     * @param _description Description of the skill.
     */
    function addSkill(string memory _name, string memory _description) public onlyOwner { // Simplified to onlyOwner for example
        require(skillNameToId[_name] == 0, "Skill name already exists"); // Skill IDs start from 1
        skillCounter++;
        skills[skillCounter] = Skill({
            id: skillCounter,
            name: _name,
            description: _description,
            active: true
        });
        skillNameToId[_name] = skillCounter;
        emit SkillAdded(skillCounter, _name, _description);
    }

     /**
     * @dev Deactivates a skill type. Requires governance approval (via proposal) or owner if no active governance.
     * @param _skillId ID of the skill to deactivate.
     */
    function deactivateSkill(uint _skillId) public onlyOwner { // Simplified to onlyOwner for example
        require(skills[_skillId].id != 0, "Skill does not exist");
        require(skills[_skillId].active, "Skill is already inactive");
        skills[_skillId].active = false;
        // Optionally, logic to invalidate or flag attestations for this skill could be added
        emit SkillDeactivated(_skillId);
    }


    /**
     * @dev Gives an attestation for a skill to another user.
     * @param _user The user being attested for.
     * @param _skillId The ID of the skill.
     * @param _strength The strength/weight of the attestation (e.g., 1-5).
     */
    function attestSkill(address _user, uint _skillId, uint _strength) public {
        require(profileExists[msg.sender], "Attester profile not registered");
        require(profileExists[_user], "Attested user profile not registered");
        require(msg.sender != _user, "Cannot attest your own skill");
        require(skills[_skillId].id != 0 && skills[_skillId].active, "Skill does not exist or is inactive");
        require(_strength > 0, "Attestation strength must be greater than 0");

        attestationCounter++;
        attestations[attestationCounter] = Attestation({
            id: attestationCounter,
            attester: msg.sender,
            attestedUser: _user,
            skillId: _skillId,
            strength: _strength,
            timestamp: block.timestamp,
            revoked: false
        });

        userProfiles[_user].receivedAttestationIds.push(attestationCounter);
        userProfiles[msg.sender].givenAttestationIds.push(attestationCounter);

        emit AttestationGiven(attestationCounter, msg.sender, _user, _skillId, _strength, block.timestamp);
    }

     /**
     * @dev Revokes an attestation that the sender previously gave.
     * This only marks it as revoked, keeping the history.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestationGiven(uint _attestationId) public {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation does not exist");
        require(att.attester == msg.sender, "Only the attester can revoke");
        require(!att.revoked, "Attestation already revoked");

        att.revoked = true;
        // Note: Revoking does NOT automatically remove verified status or taken badges.
        // This would require more complex logic or a separate challenge mechanism.
        emit AttestationRevoked(_attestationId, msg.sender);
    }

    // --- Verifier Management ---

    /**
     * @dev User applies to become a verifier. Requires governance approval.
     */
    function applyForVerifier() public {
        require(profileExists[msg.sender], "Profile not registered");
        require(!verifiers[msg.sender], "Already a verifier or application pending (simplified)");
        // In a real system, this would trigger a governance proposal.
        // For this example, we'll just emit an event and assume an off-chain process
        // or a simplified on-chain owner/governance approval flow calls approveVerifier.
        emit VerifierStatusChanged(msg.sender, false); // Indicate application received
    }

    /**
     * @dev Grants verifier status to an address. Called by owner or governance.
     * @param _verifier The address to grant verifier status.
     */
    function approveVerifier(address _verifier) public onlyOwner { // Simplified to onlyOwner
        require(profileExists[_verifier], "Verifier profile not registered");
        require(!verifiers[_verifier], "Address is already a verifier");
        verifiers[_verifier] = true;
        emit VerifierStatusChanged(_verifier, true);
    }

     /**
     * @dev Rejects a verifier application. Called by owner or governance.
     * @param _verifier The address whose application is rejected.
     */
    function rejectVerifierApplication(address _verifier) public onlyOwner { // Simplified to onlyOwner
        // This function might be needed if applyForVerifier triggers a state change/list
        // For this simple example, we just require the address not to be a verifier yet.
        require(!verifiers[_verifier], "Address is already a verifier");
        // Emit event indicating rejection, perhaps with a reason
        // emit VerifierApplicationRejected(_verifier, "Reason..."); // Event not defined, add if needed
    }

    /**
     * @dev Removes verifier status from an address. Called by owner or governance.
     * @param _verifier The address to remove verifier status from.
     */
    function removeVerifier(address _verifier) public onlyOwner { // Simplified to onlyOwner
        require(verifiers[_verifier], "Address is not a verifier");
        verifiers[_verifier] = false;
        emit VerifierStatusChanged(_verifier, false);
    }

    /**
     * @dev Adds an address to the list of trusted attesters. Called by owner or governance.
     * @param _attester The address to add as a trusted attester.
     */
    function addTrustedAttester(address _attester) public onlyOwner { // Simplified to onlyOwner
        require(!trustedAttesters[_attester], "Address is already a trusted attester");
        trustedAttesters[_attester] = true;
        emit TrustedAttesterStatusChanged(_attester, true);
    }

    /**
     * @dev Removes an address from the list of trusted attesters. Called by owner or governance.
     * @param _attester The address to remove from trusted attesters.
     */
    function removeTrustedAttester(address _attester) public onlyOwner { // Simplified to onlyOwner
        require(trustedAttesters[_attester], "Address is not a trusted attester");
        trustedAttesters[_attester] = false;
        emit TrustedAttesterStatusChanged(_attester, false);
    }


    // --- Attestation Verification ---

    /**
     * @dev Verifier approves or rejects the verification of an attestation.
     * @param _attestationId The ID of the attestation to verify.
     * @param _approved True to approve, false to reject.
     * @param _reason Reason for approval or rejection.
     */
    function verifyAttestation(uint _attestationId, bool _approved, string memory _reason) public {
        require(_isVerifier(msg.sender), "Only verifiers can verify attestations");
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation does not exist");
        require(!att.revoked, "Cannot verify a revoked attestation");
        require(!hasActiveChallenge[_attestationId], "Cannot verify attestation with active challenge");
        // Prevent re-verification (or add logic for re-verification if needed)
        require(!attestationVerifications[_attestationId].exists, "Attestation already verified or rejected");

        attestationVerifications[_attestationId] = Verification({
            verifier: msg.sender,
            timestamp: block.timestamp,
            approved: _approved,
            reason: _reason,
            exists: true
        });

        emit AttestationVerified(_attestationId, msg.sender, _approved, _reason);
    }

    // Note: There's no explicit "request" function for verification.
    // Users/DApps would simply call `verifyAttestation` if they are a verifier,
    // or rely on off-chain coordination for verification requests.
    // An event `AttestationVerificationRequested` could be added if a request mechanism is built.


    // --- Badge Management & Claiming ---

    /**
     * @dev Adds a new badge type. Requires governance approval or owner.
     * @param _name Name of the badge.
     * @param _description Description of the badge.
     * @param _requiredSkillId The skill ID associated with this badge.
     * @param _requiredVerifiedAttestations The number of verified attestations needed.
     */
    function addBadgeType(string memory _name, string memory _description, uint _requiredSkillId, uint _requiredVerifiedAttestations) public onlyOwner { // Simplified to onlyOwner
        require(skills[_requiredSkillId].id != 0 && skills[_requiredSkillId].active, "Required skill does not exist or is inactive");
        badgeTypeCounter++;
        badgeTypes[badgeTypeCounter] = BadgeType({
            id: badgeTypeCounter,
            name: _name,
            description: _description,
            requiredSkillId: _requiredSkillId,
            requiredVerifiedAttestations: _requiredVerifiedAttestations,
            active: true
        });
        emit BadgeTypeAdded(badgeTypeCounter, _name, _description);
    }

     /**
     * @dev Deactivates a badge type. Requires governance approval or owner.
     * @param _badgeId ID of the badge to deactivate.
     */
    function deactivateBadgeType(uint _badgeId) public onlyOwner { // Simplified to onlyOwner
        require(badgeTypes[_badgeId].id != 0, "Badge type does not exist");
        require(badgeTypes[_badgeId].active, "Badge type is already inactive");
        badgeTypes[_badgeId].active = false;
        // Optionally, logic regarding existing badges could be added (e.g., they remain held)
        emit BadgeTypeDeactivated(_badgeId);
    }

    /**
     * @dev Updates the requirements for an existing badge type. Requires governance approval or owner.
     * @param _badgeId The ID of the badge type to update.
     * @param _requiredSkillId The new required skill ID.
     * @param _requiredVerifiedAttestations The new required number of verified attestations.
     */
    function updateBadgeRequirements(uint _badgeId, uint _requiredSkillId, uint _requiredVerifiedAttestations) public onlyOwner { // Simplified to onlyOwner
        require(badgeTypes[_badgeId].id != 0 && badgeTypes[_badgeId].active, "Badge type does not exist or is inactive");
        require(skills[_requiredSkillId].id != 0 && skills[_requiredSkillId].active, "New required skill does not exist or is inactive");

        badgeTypes[_badgeId].requiredSkillId = _requiredSkillId;
        badgeTypes[_badgeId].requiredVerifiedAttestations = _requiredVerifiedAttestations;

        emit BadgeRequirementsUpdated(_badgeId, _requiredSkillId, _requiredVerifiedAttestations);
    }

    /**
     * @dev Checks if a user is eligible to claim a specific badge.
     * @param _user The address of the user.
     * @param _badgeId The ID of the badge type.
     * @return bool True if eligible, false otherwise.
     */
    function canClaimBadge(address _user, uint _badgeId) public view returns (bool) {
        BadgeType storage badge = badgeTypes[_badgeId];
        if (badge.id == 0 || !badge.active) {
            return false; // Badge type doesn't exist or is inactive
        }
        if (userBadges[_user][_badgeId]) {
            return false; // User already has the badge
        }
        if (!profileExists[_user]) {
            return false; // User profile not registered
        }

        uint verifiedCount = getTotalVerifiedAttestationsForSkill(_user, badge.requiredSkillId);
        return verifiedCount >= badge.requiredVerifiedAttestations;
    }

    /**
     * @dev Allows a user to claim a badge if they meet the requirements.
     * Badges are non-transferable.
     * @param _badgeId The ID of the badge type to claim.
     */
    function claimBadge(uint _badgeId) public {
        require(canClaimBadge(msg.sender, _badgeId), "Requirements not met or badge already claimed");
        userBadges[msg.sender][_badgeId] = true;
        emit BadgeClaimed(_badgeId, msg.sender);
    }

    /**
     * @dev Checks if a user currently holds a specific badge.
     * @param _user The address of the user.
     * @param _badgeId The ID of the badge type.
     * @return bool True if the user has the badge, false otherwise.
     */
    function hasBadge(address _user, uint _badgeId) public view returns (bool) {
        return userBadges[_user][_badgeId];
    }


    // --- Governance ---

    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _callData The data payload for the function call to execute.
     * @param _targetContract The address of the contract to call.
     */
    function createProposal(string memory _description, bytes memory _callData, address _targetContract) public {
        require(profileExists[msg.sender], "Profile not registered");
        // Could add a stake requirement here
        proposalCounter++;
        governanceProposals[proposalCounter] = Proposal({
            id: proposalCounter,
            description: _description,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + governanceParams.votingPeriodSeconds,
            state: ProposalState.Active,
            yesVotes: 0,
            noVotes: 0,
            callData: _callData,
            targetContract: _targetContract
        });
        emit ProposalCreated(proposalCounter, msg.sender, _description, governanceProposals[proposalCounter].votingDeadline);
    }

    /**
     * @dev Casts a vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'Yes', False for 'No'.
     */
    function vote(uint _proposalId, bool _support) public {
        require(profileExists[msg.sender], "Profile not registered");
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!votedProposals[msg.sender][_proposalId], "Already voted on this proposal");

        votedProposals[msg.sender][_proposalId] = true;

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Checks the state of a proposal based on current time and votes.
     * Automatically updates state to Succeeded or Defeated if voting ended.
     * @param _proposalId The ID of the proposal.
     * @return ProposalState The current state of the proposal.
     */
    function getProposalState(uint _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }

        if (block.timestamp <= proposal.votingDeadline) {
            return ProposalState.Active;
        }

        // Voting period ended, check result
        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        uint totalVotingSupply = _getTotalVotingSupply(); // Use placeholder supply

        // Check quorum
        if (totalVotes * 10000 < totalVotingSupply * governanceParams.quorumPercentage) {
            return ProposalState.Defeated; // Did not meet quorum
        }

        // Check approval percentage
        if (proposal.yesVotes * 10000 > totalVotes * governanceParams.approvalPercentage) {
             // Need more than approvalPercentage
             // Example: 50% approval, 100 votes, 50 yes, 50 no. 5000 > 100*5000 FALSE.
             // Example: 51% approval, 100 votes, 51 yes, 49 no. 5100 > 100*5000 TRUE (if % is 5000)
             // Let's use > for strict majority, or >= for inclusive
             // Using strictly greater for `approvalPercentage`
             return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev Executes a successful proposal. Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint _proposalId) public {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded || getProposalState(_proposalId) == ProposalState.Succeeded, "Proposal is not in Succeeded state");
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        // Update state before executing to prevent re-entrancy (though not likely for external calls)
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute the proposal's action
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        // Optionally emit event with result
        // emit ProposalExecutionResult(_proposalId, success, result); // Event not defined, add if needed
        emit ProposalExecuted(_proposalId);

    }

    /**
     * @dev Sets governance parameters. Requires owner control (initially) or governance proposal.
     * @param _votingPeriodSeconds New voting period in seconds.
     * @param _quorumPercentage New quorum percentage (e.g., 400 for 4%).
     * @param _approvalPercentage New approval percentage (e.g., 5000 for 50%).
     */
    function setGovernanceParameters(uint _votingPeriodSeconds, uint _quorumPercentage, uint _approvalPercentage) public onlyOwner { // Simplified to onlyOwner
        require(_quorumPercentage <= 10000, "Quorum percentage out of 10000");
        require(_approvalPercentage <= 10000, "Approval percentage out of 10000");

        governanceParams.votingPeriodSeconds = _votingPeriodSeconds;
        governanceParams.quorumPercentage = _quorumPercentage;
        governanceParams.approvalPercentage = _approvalPercentage;

        emit GovernanceParametersUpdated(_votingPeriodSeconds, _quorumPercentage, _approvalPercentage);
    }


    // --- Challenge Mechanism (Simplified) ---

    /**
     * @dev Challenges an attestation. Requires a reason.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reason The reason for the challenge.
     */
    function challengeAttestation(uint _attestationId, string memory _reason) public {
        require(profileExists[msg.sender], "Profile not registered");
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "Attestation does not exist");
        require(!att.revoked, "Cannot challenge a revoked attestation");
        require(!hasActiveChallenge[_attestationId], "Attestation already has an active challenge");
        // Could add a stake requirement for challenging
        // Could add a time limit after attestation/verification to challenge

        challenges[_attestationId] = Challenge({
            challenger: msg.sender,
            reason: _reason,
            timestamp: block.timestamp,
            resolved: false,
            uphold: false // Default
        });
        hasActiveChallenge[_attestationId] = true;

        emit AttestationChallenged(_attestationId, msg.sender, _reason);
    }

    /**
     * @dev Resolves a challenge. Can be called by verifiers or via governance.
     * In a real system, this might involve a more complex dispute resolution process.
     * @param _attestationId The ID of the attestation challenge to resolve.
     * @param _upheld True if the challenge is upheld (attestation deemed invalid), false otherwise.
     */
    function resolveChallenge(uint _attestationId, bool _upheld) public {
        // Simplified access control: Only owner or verifier can resolve
        require(msg.sender == owner || _isVerifier(msg.sender), "Only owner or verifier can resolve challenges");

        Challenge storage challenge = challenges[_attestationId];
        require(challenge.challenger != address(0), "No active challenge for this attestation"); // check if challenge exists
        require(!challenge.resolved, "Challenge already resolved");

        challenge.resolved = true;
        challenge.uphold = _upheld;
        hasActiveChallenge[_attestationId] = false; // Mark challenge as inactive

        // If upheld, the attestation's validity is questioned.
        // A simple approach is to mark the *attestation* as challenged/invalidated,
        // potentially removing its contribution to badge requirements.
        // For this example, we just mark the challenge resolution.
        // More complex logic would be needed to handle the effect on the attestation/verification/badges.
        // E.g., if upheld, mark the attestation as 'invalidatedByChallenge'.

        emit ChallengeResolved(_attestationId, _upheld);
    }


    // --- View Functions ---

    /**
     * @dev Gets a user's profile details.
     * @param _user The address of the user.
     * @return UserProfile struct.
     */
    function getUserProfile(address _user) public view returns (UserProfile memory) {
         require(profileExists[_user], "Profile not registered");
         return userProfiles[_user];
    }

    /**
     * @dev Gets details of a specific skill.
     * @param _skillId The ID of the skill.
     * @return Skill struct.
     */
    function getSkillDetails(uint _skillId) public view returns (Skill memory) {
        require(skills[_skillId].id != 0, "Skill does not exist");
        return skills[_skillId];
    }

     /**
     * @dev Gets skill ID by name.
     * @param _name The name of the skill.
     * @return uint Skill ID (0 if not found).
     */
    function getSkillIdByName(string memory _name) public view returns (uint) {
        return skillNameToId[_name];
    }

    /**
     * @dev Gets details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return Attestation struct.
     */
    function getAttestationDetails(uint _attestationId) public view returns (Attestation memory) {
        require(attestations[_attestationId].id != 0, "Attestation does not exist");
        return attestations[_attestationId];
    }

     /**
     * @dev Gets the verification status of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return Verification struct. Returns a struct with exists=false if not verified.
     */
    function getAttestationVerificationStatus(uint _attestationId) public view returns (Verification memory) {
        // No require on attestation existence here, allows checking for non-existent attestations
        return attestationVerifications[_attestationId];
    }

    /**
     * @dev Gets details of a specific badge type.
     * @param _badgeId The ID of the badge type.
     * @return BadgeType struct.
     */
    function getBadgeDetails(uint _badgeId) public view returns (BadgeType memory) {
        require(badgeTypes[_badgeId].id != 0, "Badge type does not exist");
        return badgeTypes[_badgeId];
    }

    /**
     * @dev Checks if an address is currently designated as a verifier.
     * @param _user The address to check.
     * @return bool True if the address is a verifier, false otherwise.
     */
    function isVerifier(address _user) public view returns (bool) {
        return _isVerifier(_user);
    }

    /**
     * @dev Checks if an address is currently designated as a trusted attester.
     * @param _user The address to check.
     * @return bool True if the address is a trusted attester, false otherwise.
     */
     function isTrustedAttester(address _user) public view returns (bool) {
         return _isTrustedAttester(_user);
     }


    /**
     * @dev Gets details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct.
     */
    function getProposalDetails(uint _proposalId) public view returns (Proposal memory) {
        require(governanceProposals[_proposalId].id != 0, "Proposal does not exist");
        // Note: Returns current state, not the *final* state if voting period ended.
        // Use getProposalState to get the calculated final state.
        return governanceProposals[_proposalId];
    }

    /**
     * @dev Gets the current challenge status of an attestation.
     * @param _attestationId The ID of the attestation.
     * @return Challenge struct. Returns a struct with challenger=address(0) if no challenge exists.
     */
    function getChallengeStatus(uint _attestationId) public view returns (Challenge memory) {
        // No require on attestation existence here, allows checking for non-existent attestations
        return challenges[_attestationId];
    }


    /**
     * @dev Counts the total number of valid (non-revoked) attestations for a specific skill received by a user.
     * Includes both verified and unverified attestations.
     * @param _user The user who received the attestations.
     * @param _skillId The skill ID.
     * @return uint The total count of valid attestations.
     */
    function getTotalAttestationsForSkill(address _user, uint _skillId) public view returns (uint) {
        if (!profileExists[_user]) return 0;
        uint count = 0;
        uint[] memory receivedIds = userProfiles[_user].receivedAttestationIds;
        for (uint i = 0; i < receivedIds.length; i++) {
            Attestation storage att = attestations[receivedIds[i]];
            // Ensure attestation exists, is for the correct skill, and is not revoked
            if (att.id != 0 && att.skillId == _skillId && !att.revoked) {
                 // Could add logic to exclude challenged attestations here
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Counts the total number of valid, *verified* attestations for a specific skill received by a user.
     * This is used for badge requirements.
     * @param _user The user who received the attestations.
     * @param _skillId The skill ID.
     * @return uint The total count of valid, verified attestations.
     */
    function getTotalVerifiedAttestationsForSkill(address _user, uint _skillId) public view returns (uint) {
         if (!profileExists[_user]) return 0;
        uint count = 0;
        uint[] memory receivedIds = userProfiles[_user].receivedAttestationIds;
        for (uint i = 0; i < receivedIds.length; i++) {
            uint attestationId = receivedIds[i];
            Attestation storage att = attestations[attestationId];

            // Ensure attestation exists, is for the correct skill, is not revoked, AND is verified and approved
            if (att.id != 0 && att.skillId == _skillId && !att.revoked) {
                Verification memory verification = attestationVerifications[attestationId];
                // Check if verification exists, is approved, and attestation has no active or upheld challenge
                if (verification.exists && verification.approved && !hasActiveChallenge[attestationId]) {
                     // Note: A more robust system might need to check if a challenge was resolved and upheld.
                     // For simplicity, we check if there's NO active challenge currently.
                    Challenge memory challenge = challenges[attestationId];
                    if (!challenge.resolved || !challenge.uphold) { // Only count if no challenge or challenge was not upheld
                        count++;
                    }
                }
            }
        }
        return count;
    }
}
```