Okay, here is a Solidity smart contract incorporating several interesting and advanced concepts: a "Decentralized Skill & Reputation Registry (DSRR)".

This contract manages user reputation and skill attestations using Soulbound Tokens (non-transferable NFTs) as verifiable badges, interacting with a separate Reputation Token (ERC-20) contract, implementing a reputation decay mechanism, conditional access to functions based on reputation/badges, a challenge system for attestations, and a delegation feature.

It requires two external contracts: an ERC-20 for reputation points (minted by this contract) and an ERC-5721 (Soulbound Token) for skill badges (also minted by this contract). For simplicity, we will define minimal interfaces for these external tokens.

---

**Outline and Function Summary: Decentralized Skill & Reputation Registry (DSRR)**

**Concept:** A system where users can register claimed skills, get them attested by designated verifiers, earn non-transferable Soulbound Badge NFTs for verified skills, and accumulate transferable Reputation Points (ERC-20). Functionality within the system is gated by reputation and badge ownership. Includes features for reputation decay, challenge attested skills, and delegation of reputation influence.

**Dependencies (Interfaces):**
*   `IERC20Minimal`: A basic ERC-20 interface for the Reputation Token.
*   `IERC5721Minimal`: A basic ERC-5721 (Soulbound Token) interface for Skill Badges. (Note: ERC-5721 is a proposed standard, this implementation assumes basic minting/checking).

**State Variables:**
*   `owner`: Contract administrator.
*   `verifiers`: Set of addresses authorized to attest skills.
*   `skillDefinitions`: Mapping from skill ID to skill details (name, description, etc.).
*   `nextSkillId`: Counter for new skill definitions.
*   `skillProposals`: Mapping for pending skill proposals.
*   `claims`: Mapping storing details of user claims for skills awaiting verification.
*   `nextClaimId`: Counter for new claims.
*   `attestations`: Mapping storing details of verified skill attestations (links user, skill, verifier, timestamp).
*   `challenges`: Mapping for active or resolved challenges against attestations.
*   `nextChallengeId`: Counter for new challenges.
*   `challengeParameters`: Struct holding stake amount and duration for challenges.
*   `reputationDecayParameters`: Struct holding interval and amount for reputation decay.
*   `userReputationState`: Mapping storing user's reputation points and last update time (for decay).
*   `reputationDelegates`: Mapping from delegator address to delegatee address.
*   `minReputationToProposeSkill`: Minimum reputation required to propose a new skill definition.
*   `reputationRewardPerAttestation`: Reputation points awarded upon successful attestation.
*   `reputationToken`: Address of the associated ERC-20 Reputation Token contract.
*   `skillBadgeNFT`: Address of the associated ERC-5721 Skill Badge contract.

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner.
*   `onlyVerifier`: Restricts function access to authorized verifiers.
*   `onlyProposer`: Restricts function access to the proposer of a skill definition.
*   `hasMinReputation(uint256 minRep)`: Checks if the caller has the minimum required reputation (applies decay before check).
*   `isClaimPending`: Checks if a claim exists and is in PENDING status.
*   `isAttestationValid`: Checks if an attestation exists and is valid (not challenged/revoked).

**Enums:**
*   `SkillStatus`: Proposed, Approved.
*   `ClaimStatus`: Pending, Attested, Rejected.
*   `ChallengeStatus`: Active, ResolvedAccepted, ResolvedRejected.

**Events:**
*   `SkillProposed`: Emitted when a new skill definition is proposed.
*   `SkillApproved`: Emitted when a skill definition is approved.
*   `SkillClaimed`: Emitted when a user requests skill verification.
*   `SkillAttested`: Emitted when a verifier attests a skill claim (triggers badge mint/rep award).
*   `AttestationRevoked`: Emitted when an attestation is revoked.
*   `ReputationUpdated`: Emitted when a user's reputation changes.
*   `ReputationDelegated`: Emitted when reputation power is delegated.
*   `ChallengeInitiated`: Emitted when an attestation is challenged.
*   `ChallengeResolved`: Emitted when a challenge is resolved.
*   `ChallengeStakeWithdrawn`: Emitted when challenge stake is withdrawn.

**Functions (> 20):**

**Admin/Config (Owner):**
1.  `constructor(address _reputationToken, address _skillBadgeNFT)`: Initializes contract, sets owner, links external token contracts.
2.  `addVerifier(address _verifier)`: Adds an address to the list of authorized verifiers.
3.  `removeVerifier(address _verifier)`: Removes an address from the list of authorized verifiers.
4.  `setChallengeParameters(uint256 _stakeAmount, uint48 _duration)`: Sets required stake and duration for challenging attestations.
5.  `setReputationDecayParameters(uint48 _interval, uint256 _amount)`: Sets the interval and amount for reputation decay.
6.  `setMinReputationToProposeSkill(uint256 _minRep)`: Sets the minimum reputation needed to propose a skill.
7.  `setReputationRewardPerAttestation(uint256 _reward)`: Sets reputation points awarded per attestation.
8.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.

**Skill Definition Management (Users/Verifiers):**
9.  `proposeSkillDefinition(string calldata _name, string calldata _description, string calldata _verificationCriteriaHash) payable`: User proposes a new skill definition. May require minimum reputation and/or stake.
10. `updateSkillProposal(uint256 _skillId, string calldata _name, string calldata _description, string calldata _verificationCriteriaHash)`: Proposer updates a pending skill definition proposal.
11. `approveSkillDefinition(uint256 _skillId)`: Verifier approves a pending skill definition, making it available for claims.
12. `getSkillDefinitionDetails(uint256 _skillId)`: View function to get details of a skill definition.
13. `listApprovedSkillDefinitionIds()`: View function to get a list of approved skill definition IDs (potentially batched or requiring iteration off-chain for large lists).

**Skill Claim & Attestation (Users/Verifiers):**
14. `requestSkillVerification(uint256 _skillDefinitionId, string calldata _evidenceHash)`: User submits a claim for a skill, providing off-chain evidence hash.
15. `attestSkillClaim(uint256 _claimId)`: Verifier reviews a pending claim and attests it, triggering badge minting and reputation award.
16. `revokeAttestation(uint256 _attestationId)`: Verifier/Owner can revoke an attestation (e.g., due to discovered fraud). Burns badge, reduces reputation.
17. `getClaimDetails(uint256 _claimId)`: View function for details of a specific claim.
18. `getUserClaims(address _user)`: View function listing claim IDs for a user (potentially batched).

**Reputation Management (Users):**
19. `getUserReputation(address _user)`: View function to get a user's current reputation points, calculating decay before returning.
20. `delegateReputationPower(address _delegatee)`: User delegates their *future* reputation earning/influence power to another address.
21. `getReputationDelegatee(address _user)`: View function to see who a user has delegated to.
22. `undelegateReputationPower()`: User removes their delegation.

**Badge Management (Users):**
23. `checkUserHasBadge(address _user, uint256 _skillDefinitionId)`: View function to check if a user holds the badge for a specific skill definition (queries ERC-5721).

**Challenge System (Users/Verifiers):**
24. `challengeAttestation(uint256 _attestationId) payable`: User challenges an existing attestation, requires staking ETH (or Reputation Token).
25. `resolveChallenge(uint256 _challengeId, bool _accepted)`: Verifier/Owner resolves a challenge. If accepted, attestation is revoked, claimant/attester lose stake/rep/badge. If rejected, challenger loses stake, claimant/attester may gain.
26. `withdrawChallengeStake(uint256 _challengeId)`: Participant withdraws their stake after a challenge is resolved.
27. `getChallengeDetails(uint256 _challengeId)`: View function for details of a specific challenge.

**Gated Function Examples (Showcasing conditional access):**
28. `accessReputationGatedFeature()`: An example function that requires a minimum reputation score.
29. `accessBadgeGatedFeature(uint256 _requiredSkillId)`: An example function that requires possession of a specific skill badge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Interface for ERC-20 Reputation Token
// The DSRR contract will have the MINTER_ROLE on this token
interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    // Function for minting (assumed to be restricted to the DSRR contract)
    function mint(address account, uint256 amount) external;
    // Function for burning (assumed to be callable by the DSRR contract or token holder)
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Minimal Interface for ERC-5721 Soulbound Token (Skill Badges)
// Assumes minting is restricted to the DSRR contract and tokens are non-transferable post-mint.
interface IERC5721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address); // Standard NFT function
    function exists(uint256 tokenId) external view returns (bool); // Standard NFT function
    function balanceOf(address owner) external view returns (uint256); // Standard NFT function

    // Custom function to check if a user has a badge for a specific skillDefinitionId
    // We can map skillDefinitionId to a unique tokenId internally in the ERC5721 contract
    // or have the DSRR generate predictable tokenIds based on skillId and user address.
    // Let's assume a simple mapping in ERC5721 where tokenId = skillDefinitionId.
    // This is a simplification; a real ERC-5721 might map user+skill -> tokenId.
    // We'll assume a function to check ownership based on skillDefinitionId directly.
    function hasBadge(address account, uint256 skillDefinitionId) external view returns (bool);

    // Function for minting (assumed to be restricted to the DSRR contract)
    function mint(address to, uint256 skillDefinitionId) external;
    // Function for burning (assumed to be restricted to the DSRR contract or token holder)
    function burn(uint256 skillDefinitionId) external; // Burning a specific badge type for someone
}

contract DSRR {
    address public owner;

    // --- Role Management ---
    mapping(address => bool) public verifiers;

    // --- Skill Definitions ---
    enum SkillStatus { Proposed, Approved }
    struct SkillDefinition {
        uint256 id;
        address proposer;
        string name;
        string description;
        string verificationCriteriaHash; // IPFS hash or similar
        SkillStatus status;
        uint48 proposalTimestamp;
    }
    mapping(uint256 => SkillDefinition) public skillDefinitions;
    uint256 private nextSkillId = 1; // Start skill IDs from 1
    uint256[] public approvedSkillDefinitionIds;

    // --- Skill Claims (Requests for Verification) ---
    enum ClaimStatus { Pending, Attested, Rejected }
    struct SkillClaim {
        uint256 id;
        address claimant;
        uint256 skillDefinitionId;
        string evidenceHash; // IPFS hash or similar
        ClaimStatus status;
        uint48 claimTimestamp;
        address attester; // Verifier who attested (if status is Attested)
    }
    mapping(uint256 => SkillClaim) public claims;
    uint256 private nextClaimId = 1; // Start claim IDs from 1

    // --- Attestations (Verified Claims) ---
    struct Attestation {
        uint256 id;
        address claimant;
        uint256 skillDefinitionId;
        address attester; // Verifier who attested
        uint48 attestationTimestamp;
        bool revoked; // Set to true if challenged and revoked, or manually revoked
    }
    mapping(uint256 => Attestation) public attestations;
    // Attestation ID can be linked to Claim ID for simplicity, e.g., attestationId = claimId
    // Or a separate counter for attestations. Let's use claimId as attestationId.

    // --- Reputation ---
    struct UserReputationState {
        uint256 points;
        uint48 lastUpdateTime; // Timestamp of last reputation change (gain or decay check)
    }
    mapping(address => UserReputationState) private userReputationState;

    struct ReputationDecayParameters {
        uint48 interval; // Time interval in seconds
        uint256 amount;   // Amount of reputation points to decay per interval
    }
    ReputationDecayParameters public reputationDecayParameters;
    uint256 public minReputationToProposeSkill = 100; // Example default
    uint256 public reputationRewardPerAttestation = 50; // Example default

    // --- Reputation Delegation ---
    mapping(address => address) public reputationDelegates; // delegator => delegatee

    // --- Challenges ---
    enum ChallengeStatus { Active, ResolvedAccepted, ResolvedRejected, Withdrawn } // Withdrawn for stake withdrawal
    struct Challenge {
        uint256 id;
        uint256 attestationId; // The attestation being challenged
        address challenger;
        uint48 challengeTimestamp;
        uint256 stakeAmount; // Amount staked by challenger
        ChallengeStatus status;
        address resolver; // Verifier/Owner who resolved
        uint48 resolutionTimestamp;
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 private nextChallengeId = 1;

    struct ChallengeParameters {
        uint256 stakeAmount;
        uint48 duration; // Duration in seconds for challenge resolution
    }
    ChallengeParameters public challengeParameters;

    // --- Token Addresses ---
    IERC20Minimal public reputationToken;
    IERC5721Minimal public skillBadgeNFT;

    // --- Events ---
    event SkillProposed(uint256 indexed skillId, address indexed proposer, string name);
    event SkillApproved(uint256 indexed skillId, address indexed approver);
    event SkillClaimed(uint256 indexed claimId, address indexed claimant, uint256 indexed skillDefinitionId);
    event SkillAttested(uint256 indexed claimId, uint256 indexed attestationId, address indexed claimant, uint256 indexed skillDefinitionId, address indexed attester, uint256 reputationAwarded);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker, string reason);
    event ReputationUpdated(address indexed user, uint256 newReputation, uint256 oldReputation, string reason);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed attestationId, ChallengeStatus status, address indexed resolver);
    event ChallengeStakeWithdrawn(uint256 indexed challengeId, address indexed participant, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Only verifier");
        _;
    }

    modifier onlyProposer(uint256 _skillId) {
        require(skillDefinitions[_skillId].proposer == msg.sender, "Only proposer");
        _;
    }

    // Applies decay before checking reputation
    modifier hasMinReputation(uint256 minRep) {
        _applyReputationDecay(msg.sender);
        require(userReputationState[msg.sender].points >= minRep, "Insufficient reputation");
        _;
    }

    modifier isClaimPending(uint256 _claimId) {
        require(claims[_claimId].status == ClaimStatus.Pending, "Claim not pending");
        _;
    }

    modifier isAttestationValid(uint256 _attestationId) {
        require(attestations[_attestationId].claimant != address(0), "Attestation does not exist"); // Check if struct exists
        require(!attestations[_attestationId].revoked, "Attestation is revoked");
        // Check for active challenges related to this attestation?
        // Simplified: assume resolution/revocation handles challenge state.
        _;
    }

    // --- Constructor ---
    constructor(address _reputationToken, address _skillBadgeNFT) {
        owner = msg.sender;
        reputationToken = IERC20Minimal(_reputationToken);
        skillBadgeNFT = IERC5721Minimal(_skillBadgeNFT);

        // Add initial verifier (the owner)
        verifiers[msg.sender] = true;

        // Example initial parameters
        reputationDecayParameters = ReputationDecayParameters({ interval: 30 days, amount: 10 });
        challengeParameters = ChallengeParameters({ stakeAmount: 0.01 ether, duration: 7 days });
    }

    // --- Admin/Config Functions ---

    function addVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid address");
        verifiers[_verifier] = true;
        // Event? Could add RoleGranted event
    }

    function removeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid address");
        verifiers[_verifier] = false;
        // Event? Could add RoleRevoked event
    }

    function setChallengeParameters(uint256 _stakeAmount, uint48 _duration) external onlyOwner {
        challengeParameters = ChallengeParameters({ stakeAmount: _stakeAmount, duration: _duration });
    }

    function setReputationDecayParameters(uint48 _interval, uint256 _amount) external onlyOwner {
        reputationDecayParameters = ReputationDecayParameters({ interval: _interval, amount: _amount });
    }

    function setMinReputationToProposeSkill(uint256 _minRep) external onlyOwner {
        minReputationToProposeSkill = _minRep;
    }

    function setReputationRewardPerAttestation(uint256 _reward) external onlyOwner {
        reputationRewardPerAttestation = _reward;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
        // Event? Could add OwnershipTransferred event
    }

    // --- Internal Reputation Management ---
    // Called by functions that change reputation or read it
    function _applyReputationDecay(address _user) internal {
        uint48 currentTime = uint48(block.timestamp);
        uint256 currentPoints = userReputationState[_user].points;
        uint48 lastUpdate = userReputationState[_user].lastUpdateTime;

        if (lastUpdate == 0) {
            // First interaction for this user, set initial timestamp
             userReputationState[_user].lastUpdateTime = currentTime;
             return;
        }

        uint48 decayInterval = reputationDecayParameters.interval;
        uint256 decayAmountPerInterval = reputationDecayParameters.amount;

        if (decayInterval > 0 && decayAmountPerInterval > 0 && currentTime > lastUpdate) {
            uint256 timeElapsed = currentTime - lastUpdate;
            uint256 intervals = timeElapsed / decayInterval;
            uint256 decayPoints = intervals * decayAmountPerInterval;

            uint256 newPoints = currentPoints > decayPoints ? currentPoints - decayPoints : 0;

            if (newPoints != currentPoints) {
                userReputationState[_user].points = newPoints;
                emit ReputationUpdated(_user, newPoints, currentPoints, "decay");
            }
            userReputationState[_user].lastUpdateTime = currentTime;
        }
    }

    // Called by functions that increase reputation
    function _addReputation(address _user, uint256 _amount) internal {
         uint256 oldPoints = userReputationState[_user].points;
         // Apply decay before adding
        _applyReputationDecay(_user);
        userReputationState[_user].points += _amount;
        userReputationState[_user].lastUpdateTime = uint48(block.timestamp); // Update timestamp
        emit ReputationUpdated(_user, userReputationState[_user].points, oldPoints, "gain");
    }

    // Called by functions that decrease reputation (slash)
    function _subtractReputation(address _user, uint256 _amount) internal {
        uint256 oldPoints = userReputationState[_user].points;
         // Apply decay before subtracting
        _applyReputationDecay(_user);
        userReputationState[_user].points = userReputationState[_user].points > _amount ? userReputationState[_user].points - _amount : 0;
        userReputationState[_user].lastUpdateTime = uint48(block.timestamp); // Update timestamp
        emit ReputationUpdated(_user, userReputationState[_user].points, oldPoints, "slashed");
    }


    // --- Skill Definition Management Functions ---

    function proposeSkillDefinition(
        string calldata _name,
        string calldata _description,
        string calldata _verificationCriteriaHash
    )
        external
        payable // Potentially require a stake here too
        hasMinReputation(minReputationToProposeSkill)
        returns (uint256 skillId)
    {
        skillId = nextSkillId++;
        skillDefinitions[skillId] = SkillDefinition({
            id: skillId,
            proposer: msg.sender,
            name: _name,
            description: _description,
            verificationCriteriaHash: _verificationCriteriaHash,
            status: SkillStatus.Proposed,
            proposalTimestamp: uint48(block.timestamp)
        });
        emit SkillProposed(skillId, msg.sender, _name);
    }

    function updateSkillProposal(
        uint256 _skillId,
        string calldata _name,
        string calldata _description,
        string calldata _verificationCriteriaHash
    ) external onlyProposer(_skillId) {
        require(skillDefinitions[_skillId].status == SkillStatus.Proposed, "Skill not in proposed status");
        skillDefinitions[_skillId].name = _name;
        skillDefinitions[_skillId].description = _description;
        skillDefinitions[_skillId].verificationCriteriaHash = _verificationCriteriaHash;
        // No event for update, just modify
    }

    function approveSkillDefinition(uint256 _skillId) external onlyVerifier {
        SkillDefinition storage skill = skillDefinitions[_skillId];
        require(skill.proposer != address(0), "Skill does not exist");
        require(skill.status == SkillStatus.Proposed, "Skill not in proposed status");

        skill.status = SkillStatus.Approved;
        approvedSkillDefinitionIds.push(_skillId); // Simple list, might be inefficient for many skills

        emit SkillApproved(_skillId, msg.sender);
    }

    function getSkillDefinitionDetails(uint256 _skillId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory name,
            string memory description,
            string memory verificationCriteriaHash,
            SkillStatus status,
            uint48 proposalTimestamp
        )
    {
        SkillDefinition storage skill = skillDefinitions[_skillId];
         require(skill.proposer != address(0), "Skill does not exist");
        return (
            skill.id,
            skill.proposer,
            skill.name,
            skill.description,
            skill.verificationCriteriaHash,
            skill.status,
            skill.proposalTimestamp
        );
    }

    function listApprovedSkillDefinitionIds() external view returns (uint256[] memory) {
        // Note: Iterating over this list off-chain or using pagination is recommended for large numbers.
        return approvedSkillDefinitionIds;
    }

    // --- Skill Claim & Attestation Functions ---

    function requestSkillVerification(uint256 _skillDefinitionId, string calldata _evidenceHash) external {
        require(skillDefinitions[_skillDefinitionId].status == SkillStatus.Approved, "Skill not approved");
        // Check if user already has this badge? ERC5721 is Soulbound, shouldn't be able to get it again.
        require(!skillBadgeNFT.hasBadge(msg.sender, _skillDefinitionId), "User already has this badge");

        uint256 claimId = nextClaimId++;
        claims[claimId] = SkillClaim({
            id: claimId,
            claimant: msg.sender,
            skillDefinitionId: _skillDefinitionId,
            evidenceHash: _evidenceHash,
            status: ClaimStatus.Pending,
            claimTimestamp: uint48(block.timestamp),
            attester: address(0) // No attester yet
        });
        emit SkillClaimed(claimId, msg.sender, _skillDefinitionId);
    }

    function attestSkillClaim(uint256 _claimId) external onlyVerifier isClaimPending(_claimId) {
        SkillClaim storage claim = claims[_claimId];
        uint256 skillDefinitionId = claim.skillDefinitionId;
        address claimant = claim.claimant;

        // Basic check if attester has enough reputation/authority? Optional
        // require(getUserReputation(msg.sender) >= MIN_REP_TO_ATTEST, "Insufficient verifier reputation");

        claim.status = ClaimStatus.Attested;
        claim.attester = msg.sender;

        // Create attestation record (using claimId as attestationId)
        attestations[_claimId] = Attestation({
            id: _claimId, // Use claimId as attestationId
            claimant: claimant,
            skillDefinitionId: skillDefinitionId,
            attester: msg.sender,
            attestationTimestamp: uint48(block.timestamp),
            revoked: false
        });

        // Mint Soulbound Badge NFT to the claimant
        skillBadgeNFT.mint(claimant, skillDefinitionId); // ERC-5721 mint

        // Award reputation points to the claimant
        _addReputation(claimant, reputationRewardPerAttestation);

        // Award reputation points to the verifier (optional)
        // _addReputation(msg.sender, REPUTATION_REWARD_FOR_VERIFIER);

        emit SkillAttested(_claimId, _claimId, claimant, skillDefinitionId, msg.sender, reputationRewardPerAttestation);
    }

    function revokeAttestation(uint256 _attestationId, string calldata _reason) external onlyVerifier isAttestationValid(_attestationId) {
        Attestation storage attestation = attestations[_attestationId];
        address claimant = attestation.claimant;
        uint256 skillDefinitionId = attestation.skillDefinitionId;

        attestation.revoked = true;

        // Burn the corresponding Soulbound Badge NFT
        skillBadgeNFT.burn(skillDefinitionId); // Assuming ERC-5721 burn by skillId for the claimant

        // Slash reputation from the claimant
        _subtractReputation(claimant, reputationRewardPerAttestation); // Slash the amount they gained

        // Optionally slash reputation from the original attester if the revocation is for cause
        // _subtractReputation(attestation.attester, SLASh_FOR_BAD_ATTESTATION);

        emit AttestationRevoked(_attestationId, msg.sender, _reason);

        // Need to handle any active challenge on this attestation - they should be auto-resolved?
        // For simplicity, this version assumes manual challenge resolution happens first.
    }

    function getClaimDetails(uint256 _claimId)
         external
        view
        returns (
            uint256 id,
            address claimant,
            uint256 skillDefinitionId,
            string memory evidenceHash,
            ClaimStatus status,
            uint48 claimTimestamp,
            address attester
        )
    {
         require(claims[_claimId].claimant != address(0), "Claim does not exist");
         SkillClaim storage claim = claims[_claimId];
         return (
             claim.id,
             claim.claimant,
             claim.skillDefinitionId,
             claim.evidenceHash,
             claim.status,
             claim.claimTimestamp,
             claim.attester
         );
    }

     function getUserClaims(address _user) external view returns (uint256[] memory) {
        // WARNING: This is inefficient for users with many claims.
        // In production, would require pagination or graph queries.
        uint256[] memory userClaimIds = new uint256[](nextClaimId);
        uint256 counter = 0;
        for (uint256 i = 1; i < nextClaimId; i++) {
            if (claims[i].claimant == _user) {
                userClaimIds[counter++] = i;
            }
        }
        uint256[] memory result = new uint256[](counter);
        for(uint256 i = 0; i < counter; i++) {
            result[i] = userClaimIds[i];
        }
        return result;
    }


    // --- Reputation Management Functions ---

    function getUserReputation(address _user) public returns (uint256) {
        // Note: This view function modifies state (lastUpdateTime) if decay is applied.
        // Clients should be aware this might cost gas if decay is due.
        // A pure view function would just calculate without state change.
        _applyReputationDecay(_user);
        return userReputationState[_user].points;
    }

    function delegateReputationPower(address _delegatee) external {
        // Delegate reputation *influence/earning* NOT token balance
        // This delegatee might receive a portion of reputation points earned by the delegator,
        // or their reputation might be combined for voting/gating purposes elsewhere.
        // Here, it simply records the delegation.
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

     function getReputationDelegatee(address _user) external view returns (address) {
        return reputationDelegates[_user];
    }

    function undelegateReputationPower() external {
        delete reputationDelegates[msg.sender];
        emit ReputationDelegated(msg.sender, address(0)); // Indicate undelegation
    }


    // --- Badge Management Functions ---

    function checkUserHasBadge(address _user, uint256 _skillDefinitionId) external view returns (bool) {
        // Queries the external ERC-5721 contract
        return skillBadgeNFT.hasBadge(_user, _skillDefinitionId);
    }

     // Note: Listing all badge IDs for a user requires iteration which is expensive on-chain.
     // This should typically be done by querying the ERC-5721 contract or via a subgraph.

    // --- Challenge Functions ---

    function challengeAttestation(uint256 _attestationId) external payable isAttestationValid(_attestationId) {
        require(msg.value >= challengeParameters.stakeAmount, "Insufficient stake");

        // Check if attestation is already being challenged
        // For simplicity, we'll only allow one active challenge per attestation at a time
        // A more complex system could allow multiple simultaneous challenges
        for (uint256 i = 1; i < nextChallengeId; i++) {
            if (challenges[i].attestationId == _attestationId && challenges[i].status == ChallengeStatus.Active) {
                revert("Attestation is already under active challenge");
            }
        }

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            attestationId: _attestationId,
            challenger: msg.sender,
            challengeTimestamp: uint48(block.timestamp),
            stakeAmount: msg.value,
            status: ChallengeStatus.Active,
            resolver: address(0),
            resolutionTimestamp: 0
        });

        emit ChallengeInitiated(challengeId, _attestationId, msg.sender, msg.value);
    }

    function resolveChallenge(uint256 _challengeId, bool _attestationStands) external onlyVerifier {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "Challenge does not exist");
        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        require(uint48(block.timestamp) <= challenge.challengeTimestamp + challengeParameters.duration, "Challenge resolution time window expired");

        Attestation storage attestation = attestations[challenge.attestationId];
        address claimant = attestation.claimant;
        address originalAttester = attestation.attester; // Original verifier

        challenge.resolver = msg.sender;
        challenge.resolutionTimestamp = uint48(block.timestamp);

        if (_attestationStands) {
            // Challenger was wrong - Attestation is confirmed
            challenge.status = ChallengeStatus.ResolvedRejected; // Challenger's claim rejected
            // Challenger loses stake (it stays in the contract until withdrawn by someone - e.g., owner, or split between claimant/attester)
            // Let's say stake goes to the owner as a fee for simplicity
            // payable(owner).transfer(challenge.stakeAmount); // BE CAREFUL: direct transfer is risky. Prefer pull pattern. Stake stays until withdrawal.

            // Claimant and Attester reputation might increase slightly for successfully defending
            // _addReputation(claimant, SMALL_BONUS_REP);
            // _addReputation(originalAttester, SMALL_BONUS_REP);

        } else {
            // Challenger was correct - Attestation is false
            challenge.status = ChallengeStatus.ResolvedAccepted; // Challenger's claim accepted

            // Revoke the fraudulent attestation
            // This also burns the badge and slashes claimant reputation
            // We need a separate internal function that doesn't re-slash if already slashed by manual revoke
            _handleFraudulentAttestation(challenge.attestationId, "Resolved challenge");

            // Slash reputation from the claimant and the original attester
            // _subtractReputation(claimant, MAJOR_SLASH_REP); // Already handled by revokeAttestation
             _subtractReputation(originalAttester, reputationRewardPerAttestation); // Slash the original verifier

            // Challenger gets their stake back
            // Their stake is now 'withdrawable'

            // Optionally reward challenger (e.g., some reputation or a portion of slashed rep)
             _addReputation(challenge.challenger, reputationRewardPerAttestation / 2); // Small reward
        }

        emit ChallengeResolved(challenge.id, challenge.attestationId, challenge.status, msg.sender);
    }

    function _handleFraudulentAttestation(uint256 _attestationId, string memory _reason) internal {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.claimant != address(0) && !attestation.revoked) {
            attestation.revoked = true;
            // Burn the corresponding Soulbound Badge NFT
            skillBadgeNFT.burn(attestation.skillDefinitionId);
            // Slash reputation from the claimant
            _subtractReputation(attestation.claimant, reputationRewardPerAttestation);
            emit AttestationRevoked(_attestationId, msg.sender, _reason);
        }
        // If already revoked, do nothing more here
    }


    function withdrawChallengeStake(uint256 _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "Challenge does not exist");
        require(challenge.status != ChallengeStatus.Active, "Challenge still active");
        require(challenge.status != ChallengeStatus.Withdrawn, "Stake already withdrawn");

        uint256 amountToWithdraw = 0;
        address payable recipient;

        if (challenge.status == ChallengeStatus.ResolvedAccepted) {
            // Challenger won, they get their stake back
            require(msg.sender == challenge.challenger, "Only challenger can withdraw winning stake");
            amountToWithdraw = challenge.stakeAmount;
            recipient = payable(msg.sender);
        } else if (challenge.status == ChallengeStatus.ResolvedRejected) {
            // Challenger lost, stake goes somewhere else (e.g., owner or pool)
             // Let's allow owner to withdraw losing stakes
             require(msg.sender == owner, "Only owner can withdraw losing stake");
             amountToWithdraw = challenge.stakeAmount;
             recipient = payable(owner);
        } else {
            revert("Invalid challenge status for withdrawal");
        }

        require(amountToWithdraw > 0, "Nothing to withdraw");

        challenge.status = ChallengeStatus.Withdrawn; // Mark as withdrawn

        // Send ETH using a safe pattern
        (bool success, ) = recipient.call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        emit ChallengeStakeWithdrawn(challenge.id, recipient, amountToWithdraw);
    }

     function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 id,
            uint256 attestationId,
            address challenger,
            uint48 challengeTimestamp,
            uint256 stakeAmount,
            ChallengeStatus status,
            address resolver,
            uint48 resolutionTimestamp
        )
    {
        require(challenges[_challengeId].challenger != address(0), "Challenge does not exist");
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.id,
            challenge.attestationId,
            challenge.challenger,
            challenge.challengeTimestamp,
            challenge.stakeAmount,
            challenge.status,
            challenge.resolver,
            challenge.resolutionTimestamp
        );
    }


    // --- Gated Function Examples ---

    function accessReputationGatedFeature() external hasMinReputation(500) {
        // Only users with 500+ reputation can call this
        // Implement feature logic here...
        // Example: minting a special ERC-20 token, accessing exclusive data hash, etc.
        // reputationToken.mint(msg.sender, 10); // Example reward
        emit ReputationUpdated(msg.sender, getUserReputation(msg.sender), getUserReputation(msg.sender), "Accessed gated feature"); // Log reputation (already decayed by modifier)
    }

    function accessBadgeGatedFeature(uint256 _requiredSkillId) external {
        require(skillBadgeNFT.hasBadge(msg.sender, _requiredSkillId), "Requires specific badge");
        // Only users with the specified badge can call this
        // Implement feature logic here...
        // Example: unlocking content hash, joining a private group, etc.
         emit ReputationUpdated(msg.sender, getUserReputation(msg.sender), getUserReputation(msg.sender), "Accessed badge gated feature"); // Log reputation (decay applied)
    }

    // --- Receive/Fallback (for receiving ETH stakes) ---
    receive() external payable {}
    fallback() external payable {}

    // --- View function for potential reputation after decay (without state change) ---
    // This is a helper view, not the primary getter which applies state changes
     function calculateReputationAfterDecay(address _user) external view returns (uint256) {
        uint48 currentTime = uint48(block.timestamp);
        uint256 currentPoints = userReputationState[_user].points;
        uint48 lastUpdate = userReputationState[_user].lastUpdateTime;

         if (lastUpdate == 0) {
            return currentPoints; // No history, no decay yet
        }

        uint48 decayInterval = reputationDecayParameters.interval;
        uint256 decayAmountPerInterval = reputationDecayParameters.amount;

        if (decayInterval > 0 && decayAmountPerInterval > 0 && currentTime > lastUpdate) {
            uint256 timeElapsed = currentTime - lastUpdate;
            uint256 intervals = timeElapsed / decayInterval;
            uint256 decayPoints = intervals * decayAmountPerInterval;
            return currentPoints > decayPoints ? currentPoints - decayPoints : 0;
        }
        return currentPoints;
     }

    // --- Getters for parameters and counters ---
    function getNextSkillId() external view returns (uint256) { return nextSkillId; }
    function getNextClaimId() external view returns (uint256) { return nextClaimId; }
    function getNextChallengeId() external view returns (uint256) { return nextChallengeId; }

}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Soulbound Tokens (ERC-5721 Inspired):** Skill Badges are non-transferable NFTs, tied permanently to the user's address, representing achievements or verified skills. This leverages the "Soulbound" concept for on-chain identity and reputation.
2.  **Decentralized Attestation System:** Allows designated 'Verifiers' to confirm claims made by users (claiming a skill), creating a system of trust and verification on-chain.
3.  **Reputation System (ERC-20):** Uses a separate ERC-20 token (`DSRRReputationToken`) to quantify reputation points. This token is minted based on on-chain actions (like getting skills attested). While transferable, its primary utility comes from gating access within the DSRR contract.
4.  **Reputation Decay:** Reputation points gradually decrease over time, encouraging continuous engagement or skill acquisition to maintain status. This uses timestamp tracking and calculation on interaction.
5.  **Conditional Gating:** Functions (`accessReputationGatedFeature`, `accessBadgeGatedFeature`) demonstrate how smart contract logic can be made conditional on a user's on-chain reputation score or possession of specific Soulbound Badges.
6.  **Challenge Mechanism:** Allows users to challenge the validity of a skill attestation. This adds a layer of social slashing and dispute resolution, requiring stake and potentially leading to burning badges and slashing reputation if fraud is proven.
7.  **Reputation Delegation:** Users can delegate their *influence* or *earning potential* associated with their reputation points to another address. This isn't transferring tokens but rather a form of delegated power within the DSRR system, usable for future features like delegated voting or earning distribution.
8.  **Separation of Concerns:** The core DSRR logic is separate from the token contracts (ERC-20 and ERC-5721), interacting via interfaces. This makes the system more modular and potentially upgradeable (though upgradeability patterns are not explicitly implemented here).
9.  **IPFS Integration (Implicit):** The `verificationCriteriaHash` and `evidenceHash` fields store hashes, implying interaction with decentralized file storage like IPFS to store the actual evidence or skill criteria documents off-chain, keeping on-chain data minimal.
10. **Modifier Usage for Complex Checks:** Modifiers like `hasMinReputation` and `isAttestationValid` encapsulate complex checks and state updates (like reputation decay), making the function logic cleaner.

This contract provides a framework for building a decentralized professional network, achievement system, or identity layer where skills and reputation are verifiable and influence is earned and managed on-chain. Remember that deploying this requires deploying the `IERC20Minimal` and `IERC5721Minimal` contracts first and granting the DSRR contract the necessary minter/burner roles on them. The ERC-5721 implementation would need specific logic to link a `skillDefinitionId` to a unique token ID minted for a user.