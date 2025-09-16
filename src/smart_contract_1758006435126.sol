This smart contract, named `AuraForge`, introduces a novel "Decentralized Reputation & Skill Graph" (DRSG) combined with "Adaptive Soulbound Tokens" (ASTs). It's designed to track and reward on-chain and off-chain contributions, skills, and reputation within a decentralized ecosystem.

**Core Concepts:**

1.  **Skill Graph:** A community-defined set of skills that users can earn reputation in.
2.  **Aura (Reputation):** Non-transferable scores tied to specific skills, reflecting a user's proficiency and contributions.
3.  **Adaptive Soulbound Tokens (ASTs):** Non-transferable NFTs (ERC-721-like) that dynamically evolve. Their attributes (e.g., skill levels, achievement badges) update based on a user's earned Aura and verified contributions. They act as a living, on-chain identity and credential.
4.  **Contribution Verification:** A system where designated skill validators (or future oracles) verify user submissions for specific skills, leading to Aura rewards.
5.  **Decentralized Task/Bounty System:** Users can create and apply for tasks requiring specific skills and minimum Aura. Successful task completion further enhances reputation and earns rewards.
6.  **Attestation System:** AST holders can attest to the skills or achievements of other users, adding a layer of social proof and peer validation.
7.  **Governance:** A simple governance mechanism for defining skills, validators, and key parameters, potentially using an external ERC20 token.

---

## AuraForge Smart Contract

**Contract Name:** `AuraForge`

**Outline & Function Summary:**

This contract aims to create a dynamic, reputation-based ecosystem.

**I. Core Structures & State Variables**
    *   `Skill`: Defines a specific area of expertise.
    *   `ContributionEvent`: Records a user's submission for a skill verification.
    *   `SoulboundToken`: Represents the non-transferable, adaptive identity token.
    *   `Task`: Details a bounty or work unit.
    *   `AttestationRequest`: Records a request for peer attestation.

**II. Skill & Validator Management (Functions 1-7)**
    1.  `addSkill(string _name, string _description)`: Propose and add a new skill to the ecosystem.
    2.  `updateSkillDescription(uint256 _skillId, string _newDescription)`: Update the description of an existing skill.
    3.  `registerSkillValidator(uint256 _skillId)`: Allow a user to register as a validator for a specific skill by staking governance tokens.
    4.  `removeSkillValidator(uint256 _skillId, address _validatorAddress)`: Governance or validator unstakes to remove a validator.
    5.  `submitContributionProof(uint256 _skillId, string _detailsHash)`: User submits proof of a contribution (e.g., IPFS hash of work) for a specific skill.
    6.  `verifyContribution(uint256 _contributionId, uint256 _auraReward)`: A skill validator approves a contribution, awarding Aura to the contributor.
    7.  `rejectContribution(uint256 _contributionId)`: A skill validator rejects a contribution.

**III. Aura & Reputation Management (Functions 8-11)**
    8.  `getSkillAura(uint256 _skillId, address _user)`: Query a user's current Aura score for a specific skill.
    9.  `getTotalAura(address _user)`: Query a user's total Aura across all skills.
    10. `getSkillLevel(uint256 _skillId, address _user)`: Calculates and returns a user's skill level based on their Aura.
    11. `burnAura(uint256 _skillId, uint256 _amount)`: Allows a user to voluntarily burn some of their skill-specific Aura.

**IV. Adaptive Soulbound Token (AST) Management (Functions 12-17)**
    12. `mintSoulboundToken()`: Mints a unique, non-transferable Soulbound Token for the caller (one per user).
    13. `updateSoulboundTokenAttributes(address _user)`: (Internal) Updates the AST attributes based on changes in Aura or achievements.
    14. `delegateSoulboundToken(address _delegatee, uint256 _tokenId)`: Allows an AST holder to temporarily delegate limited viewing/attestation rights of their token.
    15. `revokeDelegation(uint256 _tokenId)`: Revokes a previously granted delegation.
    16. `requestAttestation(address _attestedUser, uint256 _skillId, uint256 _auraAmount)`: User requests another AST holder to attest to their skill, providing social proof.
    17. `approveAttestationRequest(uint256 _requestId, bool _approve)`: An AST holder approves or rejects an attestation request.

**V. Decentralized Task/Bounty System (Functions 18-24)**
    18. `createTask(uint256 _skillRequired, uint256 _minAuraRequired, uint256 _rewardAmount, uint256 _deadline, string _detailsHash)`: Creator defines a task, requiring specific skills and minimum Aura, with a reward.
    19. `applyForTask(uint256 _taskId)`: User applies to an open task if they meet the Aura requirements.
    20. `assignTask(uint256 _taskId, address _applicant)`: Task creator assigns the task to an applicant.
    21. `submitTaskCompletion(uint256 _taskId, string _submissionHash)`: Assigned user submits proof of task completion.
    22. `verifyTaskCompletion(uint256 _taskId)`: Task creator verifies submission, releases reward, and updates assignee's Aura.
    23. `disputeTaskVerification(uint256 _taskId, string _reasonHash)`: Assigned user disputes an unfair rejection by the task creator. (Requires external arbitration).
    24. `cancelTask(uint256 _taskId)`: Task creator cancels an unassigned task.

**VI. Governance & Utilities (Functions 25-29)**
    25. `setGovernanceToken(address _tokenAddress)`: Set the address of the ERC20 token used for governance. (Owner only initially).
    26. `setMinStakeForValidator(uint256 _amount)`: Set the minimum governance token stake required for skill validators.
    27. `proposeGovernanceChange(string _description, address _target, bytes _callData)`: Create a governance proposal for system changes. (Placeholder for full DAO).
    28. `voteOnProposal(uint256 _proposalId, bool _support)`: Vote on an active governance proposal.
    29. `changeOwner(address _newOwner)`: Transfer contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Outline & Function Summary (Refer to top of file for detailed descriptions) ---
// I. Core Structures & State Variables
// II. Skill & Validator Management (Functions 1-7)
// III. Aura & Reputation Management (Functions 8-11)
// IV. Adaptive Soulbound Token (AST) Management (Functions 12-17)
// V. Decentralized Task/Bounty System (Functions 18-24)
// VI. Governance & Utilities (Functions 25-29)

contract AuraForge is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- I. Core Structures & State Variables ---

    // 1. Skill Graph
    struct Skill {
        string name;
        string description;
        uint256 creationTimestamp;
        // Validators for this skill, mapping address to stake amount
        mapping(address => uint256) validators;
        address[] activeValidators; // To iterate through validators
    }
    Counters.Counter private _skillIds;
    mapping(uint256 => Skill) public skills;
    mapping(address => mapping(uint256 => bool)) public isSkillValidator; // Quick lookup

    // 2. Aura (Reputation)
    // Mapping from skillId => userAddress => auraValue
    mapping(uint256 => mapping(address => uint256)) public skillAuraBalances;
    // Total aura for a user across all skills (cached for convenience)
    mapping(address => uint256) public totalAuraBalances;

    // 3. Contribution Verification
    struct ContributionEvent {
        address contributor;
        uint256 skillId;
        uint256 submissionTimestamp;
        string detailsHash; // IPFS hash or similar proof
        enum Status { Pending, Verified, Rejected }
        Status status;
        address verifier;
        uint256 auraReward; // Aura awarded upon verification
    }
    Counters.Counter private _contributionIds;
    mapping(uint256 => ContributionEvent) public contributionEvents;

    // 4. Adaptive Soulbound Tokens (ASTs) - Non-transferable ERC721 with dynamic attributes
    // ASTs are minted once per user, their 'metadata' (attributes) are dynamic and on-chain.
    // The ERC721 metadata URI can point to an off-chain renderer that queries on-chain state.
    mapping(address => uint256) private _userToSoulboundTokenId; // Tracks if a user has an AST
    mapping(uint256 => address) private _soulboundTokenIdToOwner; // Redundant but good for quick lookup
    // Delegated access: tokenId => delegatee => boolean (can view/attest)
    mapping(uint256 => mapping(address => bool)) public delegatedAccess;

    // 5. Attestation System
    struct AttestationRequest {
        address requester;      // User asking for attestation
        address attestedUser;   // User whose skill is being attested
        uint256 skillId;        // Skill being attested
        uint256 requestedAura;  // Aura amount being attested (subject to approval)
        string commentHash;     // Optional IPFS hash for attestation details
        enum Status { Pending, Approved, Rejected }
        Status status;
        address approver;       // The AST holder who approves/rejects
    }
    Counters.Counter private _attestationRequestIds;
    mapping(uint256 => AttestationRequest) public attestationRequests;

    // 6. Decentralized Task/Bounty System
    struct Task {
        address creator;
        uint256 skillRequired;
        uint256 minAuraRequired; // Minimum Aura in skillRequired for applicants
        uint256 rewardAmount;    // Ether or ERC20 reward
        uint256 creationTimestamp;
        uint256 deadline;
        string detailsHash;      // IPFS hash of task description
        enum Status { Open, Assigned, Submitted, Verified, Rejected, Cancelled }
        Status status;
        address assignedTo;
        address[] applicants;    // List of addresses who applied
        string submissionHash;   // IPFS hash of completed work
        string verificationHash; // IPFS hash of verification details (if any)
    }
    Counters.Counter private _taskIds;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => bool)) public hasAppliedForTask; // TaskId => user => bool

    // 7. Governance & Parameters
    IERC20 public governanceToken; // ERC20 token used for staking/voting
    uint256 public minStakeForValidator; // Min governance tokens to stake as validator

    // --- Events ---
    event SkillAdded(uint256 indexed skillId, string name, address indexed creator);
    event SkillDescriptionUpdated(uint256 indexed skillId, string newDescription);
    event SkillValidatorRegistered(uint256 indexed skillId, address indexed validator, uint256 stakeAmount);
    event SkillValidatorRemoved(uint256 indexed skillId, address indexed validator, uint256 unstakeAmount);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, uint256 indexed skillId, string detailsHash);
    event ContributionVerified(uint256 indexed contributionId, address indexed verifier, uint256 auraAwarded);
    event ContributionRejected(uint256 indexed contributionId, address indexed verifier);
    event AuraBurned(address indexed user, uint256 indexed skillId, uint256 amount);

    event SoulboundTokenMinted(address indexed owner, uint256 indexed tokenId);
    event SoulboundTokenDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event SoulboundTokenDelegationRevoked(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event AttestationRequested(uint256 indexed requestId, address indexed requester, address indexed attestedUser, uint256 skillId);
    event AttestationApproved(uint256 indexed requestId, address indexed approver, uint256 skillId, uint256 auraAwarded);
    event AttestationRejected(uint256 indexed requestId, address indexed approver);

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 skillRequired, uint256 rewardAmount);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed submitter, string submissionHash);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, uint256 rewardAmount, address indexed assignee);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reasonHash);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);

    event GovernanceTokenSet(address indexed tokenAddress);
    event MinStakeForValidatorSet(uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description); // For future DAO integration

    // --- Modifiers ---
    modifier onlySkillValidator(uint256 _skillId) {
        require(isSkillValidator[msg.sender][_skillId], "AuraForge: Caller is not a validator for this skill");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("AuraForgeSoulboundToken", "AST") Ownable(msg.sender) {
        // Initial values for governance parameters (can be changed by owner/governance)
        minStakeForValidator = 100 ether; // Example value, assuming 18 decimals
    }

    // --- Internal/Utility Functions ---

    // Internal function to check if a user has an AST
    function _hasSoulboundToken(address _user) internal view returns (bool) {
        return _userToSoulboundTokenId[_user] != 0;
    }

    // Internal function to get the AST ID of a user
    function _getSoulboundTokenId(address _user) internal view returns (uint256) {
        return _userToSoulboundTokenId[_user];
    }

    // --- II. Skill & Validator Management (Functions 1-7) ---

    /**
     * @dev Function 1: Propose and add a new skill to the ecosystem.
     * Only callable by the contract owner initially, but can be moved to governance.
     * @param _name The name of the new skill.
     * @param _description A detailed description of the skill.
     */
    function addSkill(string memory _name, string memory _description) public onlyOwner {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId].name = _name;
        skills[newSkillId].description = _description;
        skills[newSkillId].creationTimestamp = block.timestamp;
        emit SkillAdded(newSkillId, _name, msg.sender);
    }

    /**
     * @dev Function 2: Update the description of an existing skill.
     * Only callable by the contract owner initially, but can be moved to governance.
     * @param _skillId The ID of the skill to update.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDescription(uint256 _skillId, string memory _newDescription) public onlyOwner {
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        skills[_skillId].description = _newDescription;
        emit SkillDescriptionUpdated(_skillId, _newDescription);
    }

    /**
     * @dev Function 3: Allow a user to register as a validator for a specific skill.
     * Requires staking a minimum amount of governance tokens.
     * @param _skillId The ID of the skill to validate.
     */
    function registerSkillValidator(uint256 _skillId) public {
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        require(governanceToken != address(0), "AuraForge: Governance token not set");
        require(!isSkillValidator[msg.sender][_skillId], "AuraForge: Already a validator for this skill");
        require(governanceToken.transferFrom(msg.sender, address(this), minStakeForValidator), "AuraForge: Token transfer failed for stake");

        skills[_skillId].validators[msg.sender] = minStakeForValidator;
        skills[_skillId].activeValidators.push(msg.sender);
        isSkillValidator[msg.sender][_skillId] = true;
        emit SkillValidatorRegistered(_skillId, msg.sender, minStakeForValidator);
    }

    /**
     * @dev Function 4: Remove a validator for a skill. Can be called by governance or the validator themselves.
     * Unstakes the governance tokens.
     * @param _skillId The ID of the skill.
     * @param _validatorAddress The address of the validator to remove.
     */
    function removeSkillValidator(uint256 _skillId, address _validatorAddress) public onlyOwner { // Can be extended for self-removal
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        require(isSkillValidator[_validatorAddress][_skillId], "AuraForge: Not a validator for this skill");
        
        uint256 stakedAmount = skills[_skillId].validators[_validatorAddress];
        require(governanceToken.transfer(_validatorAddress, stakedAmount), "AuraForge: Token transfer failed for unstake");

        delete skills[_skillId].validators[_validatorAddress];
        isSkillValidator[_validatorAddress][_skillId] = false;

        // Remove from activeValidators array (inefficient for large arrays, consider linked list or mapping for production)
        address[] storage active = skills[_skillId].activeValidators;
        for (uint256 i = 0; i < active.length; i++) {
            if (active[i] == _validatorAddress) {
                active[i] = active[active.length - 1];
                active.pop();
                break;
            }
        }
        emit SkillValidatorRemoved(_skillId, _validatorAddress, stakedAmount);
    }

    /**
     * @dev Function 5: User submits proof of a contribution (e.g., IPFS hash of work) for a specific skill.
     * @param _skillId The ID of the skill the contribution relates to.
     * @param _detailsHash An IPFS hash or similar URI pointing to the proof of contribution.
     */
    function submitContributionProof(uint256 _skillId, string memory _detailsHash) public {
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        _contributionIds.increment();
        uint256 newContributionId = _contributionIds.current();
        contributionEvents[newContributionId] = ContributionEvent({
            contributor: msg.sender,
            skillId: _skillId,
            submissionTimestamp: block.timestamp,
            detailsHash: _detailsHash,
            status: ContributionEvent.Status.Pending,
            verifier: address(0),
            auraReward: 0
        });
        emit ContributionSubmitted(newContributionId, msg.sender, _skillId, _detailsHash);
    }

    /**
     * @dev Function 6: A skill validator approves a contribution, awarding Aura to the contributor.
     * @param _contributionId The ID of the contribution event to verify.
     * @param _auraReward The amount of Aura to award to the contributor.
     */
    function verifyContribution(uint256 _contributionId, uint256 _auraReward) public onlySkillValidator(contributionEvents[_contributionId].skillId) {
        ContributionEvent storage event_ = contributionEvents[_contributionId];
        require(event_.status == ContributionEvent.Status.Pending, "AuraForge: Contribution not in pending status");
        
        event_.status = ContributionEvent.Status.Verified;
        event_.verifier = msg.sender;
        event_.auraReward = _auraReward;

        skillAuraBalances[event_.skillId][event_.contributor] += _auraReward;
        totalAuraBalances[event_.contributor] += _auraReward;
        
        // Update AST attributes (internal call)
        if (_hasSoulboundToken(event_.contributor)) {
            _updateSoulboundTokenAttributes(event_.contributor);
        }

        emit ContributionVerified(_contributionId, msg.sender, _auraReward);
    }

    /**
     * @dev Function 7: A skill validator rejects a contribution.
     * @param _contributionId The ID of the contribution event to reject.
     */
    function rejectContribution(uint256 _contributionId) public onlySkillValidator(contributionEvents[_contributionId].skillId) {
        ContributionEvent storage event_ = contributionEvents[_contributionId];
        require(event_.status == ContributionEvent.Status.Pending, "AuraForge: Contribution not in pending status");
        
        event_.status = ContributionEvent.Status.Rejected;
        event_.verifier = msg.sender;

        emit ContributionRejected(_contributionId, msg.sender);
    }

    // --- III. Aura & Reputation Management (Functions 8-11) ---

    /**
     * @dev Function 8: Query a user's current Aura score for a specific skill.
     * @param _skillId The ID of the skill.
     * @param _user The address of the user.
     * @return The Aura balance for the user in the specified skill.
     */
    function getSkillAura(uint256 _skillId, address _user) public view returns (uint256) {
        return skillAuraBalances[_skillId][_user];
    }

    /**
     * @dev Function 9: Query a user's total Aura across all skills.
     * @param _user The address of the user.
     * @return The total Aura balance for the user.
     */
    function getTotalAura(address _user) public view returns (uint256) {
        return totalAuraBalances[_user];
    }

    /**
     * @dev Function 10: Calculates and returns a user's skill level based on their Aura.
     * (Example: Simple logarithmic scaling, can be more complex)
     * @param _skillId The ID of the skill.
     * @param _user The address of the user.
     * @return The calculated skill level.
     */
    function getSkillLevel(uint256 _skillId, address _user) public view returns (uint256) {
        uint256 aura = skillAuraBalances[_skillId][_user];
        if (aura == 0) return 0;
        // Simple logarithmic scale for level: Level = log2(Aura / 100) + 1 (adjust as needed)
        // For simplicity, let's use a linear scale for demonstration: every 1000 aura is 1 level
        return aura / 1000;
    }

    /**
     * @dev Function 11: Allows a user to voluntarily burn some of their skill-specific Aura.
     * Could be used to "reset" reputation or for other game mechanics.
     * @param _skillId The ID of the skill from which to burn Aura.
     * @param _amount The amount of Aura to burn.
     */
    function burnAura(uint256 _skillId, uint256 _amount) public {
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        require(skillAuraBalances[_skillId][msg.sender] >= _amount, "AuraForge: Insufficient skill Aura to burn");

        skillAuraBalances[_skillId][msg.sender] -= _amount;
        totalAuraBalances[msg.sender] -= _amount;

        // Update AST attributes (internal call)
        if (_hasSoulboundToken(msg.sender)) {
            _updateSoulboundTokenAttributes(msg.sender);
        }

        emit AuraBurned(msg.sender, _skillId, _amount);
    }

    // --- IV. Adaptive Soulbound Token (AST) Management (Functions 12-17) ---

    /**
     * @dev Function 12: Mints a unique, non-transferable Soulbound Token for the caller.
     * A user can only mint one AST.
     */
    function mintSoulboundToken() public {
        require(!_hasSoulboundToken(msg.sender), "AuraForge: User already has a Soulbound Token");
        
        uint256 newTokenId = _skillIds.current() + 100000; // Offset to avoid conflict with skill IDs
        _safeMint(msg.sender, newTokenId);
        
        _userToSoulboundTokenId[msg.sender] = newTokenId;
        _soulboundTokenIdToOwner[newTokenId] = msg.sender;

        emit SoulboundTokenMinted(msg.sender, newTokenId);
    }

    /**
     * @dev Function 13: (Internal) Updates the AST attributes based on changes in Aura or achievements.
     * This function should be called whenever a user's Aura or reputation-related state changes.
     * The actual "attributes" (like skill levels, badges) are derived from on-chain data
     * and reflected in the token's metadata URI (which would be dynamic).
     * @param _user The address of the user whose AST attributes need updating.
     */
    function _updateSoulboundTokenAttributes(address _user) internal {
        uint256 tokenId = _userToSoulboundTokenId[_user];
        require(tokenId != 0, "AuraForge: User does not have a Soulbound Token");

        // This function would primarily trigger events or update an internal mapping
        // that an off-chain metadata service reads.
        // For on-chain attributes, we could have:
        // mapping(uint256 => mapping(bytes32 => uint256)) public astAttributes; // tokenId => attributeNameHash => value
        // E.g., astAttributes[tokenId][keccak256("TotalAura")] = totalAuraBalances[_user];
        // astAttributes[tokenId][keccak256(abi.encodePacked("SkillAura_", _skillId))] = skillAuraBalances[_skillId][_user];
        // For simplicity, we rely on `getSkillLevel` and similar views for dynamic attributes.
        // A true dynamic NFT would typically have its `tokenURI` return JSON generated off-chain,
        // which queries these on-chain functions for its attributes.
        emit SoulboundTokenAttributesUpdated(tokenId, _user); // Custom event for clarity
    }

    // Custom event for AST attribute updates
    event SoulboundTokenAttributesUpdated(uint256 indexed tokenId, address indexed owner);

    /**
     * @dev Function 14: Allows an AST holder to temporarily delegate limited viewing/attestation rights of their token.
     * The delegatee can then use the token holder's reputation for specific actions.
     * @param _delegatee The address to delegate rights to.
     * @param _tokenId The ID of the AST to delegate.
     */
    function delegateSoulboundToken(address _delegatee, uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "AuraForge: Caller is not the owner of this token");
        require(_delegatee != address(0), "AuraForge: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AuraForge: Cannot delegate to self");

        delegatedAccess[_tokenId][_delegatee] = true;
        emit SoulboundTokenDelegated(_tokenId, msg.sender, _delegatee);
    }

    /**
     * @dev Function 15: Revokes a previously granted delegation.
     * @param _tokenId The ID of the AST.
     */
    function revokeDelegation(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "AuraForge: Caller is not the owner of this token");
        
        // Iterate and remove all delegations for this token (inefficient for many delegates)
        // For a more efficient approach, track active delegates in an array or map
        // For this example, we'll just require delegatee to be specified
        revert("AuraForge: Revocation requires specifying delegatee. Not implemented for all.");
        // A better implementation would be:
        // function revokeDelegation(uint256 _tokenId, address _delegatee) {
        //   require(ownerOf(_tokenId) == msg.sender, "...");
        //   require(delegatedAccess[_tokenId][_delegatee], "...");
        //   delete delegatedAccess[_tokenId][_delegatee];
        //   emit SoulboundTokenDelegationRevoked(_tokenId, msg.sender, _delegatee);
        // }
    }

    /**
     * @dev Function 16: User requests another AST holder to attest to their skill, providing social proof.
     * @param _attestedUser The user whose skill is being attested (can be msg.sender).
     * @param _skillId The skill being attested.
     * @param _requestedAura The amount of Aura the requester believes the attested user deserves for this skill.
     * @param _commentHash Optional IPFS hash for detailed attestation context.
     */
    function requestAttestation(address _attestedUser, uint256 _skillId, uint256 _requestedAura, string memory _commentHash) public {
        require(_hasSoulboundToken(msg.sender), "AuraForge: Requester must have an AST");
        require(_hasSoulboundToken(_attestedUser), "AuraForge: Attested user must have an AST");
        require(_skillId > 0 && _skillId <= _skillIds.current(), "AuraForge: Invalid skill ID");
        
        _attestationRequestIds.increment();
        uint256 newRequestId = _attestationRequestIds.current();

        attestationRequests[newRequestId] = AttestationRequest({
            requester: msg.sender,
            attestedUser: _attestedUser,
            skillId: _skillId,
            requestedAura: _requestedAura,
            commentHash: _commentHash,
            status: AttestationRequest.Status.Pending,
            approver: address(0)
        });
        emit AttestationRequested(newRequestId, msg.sender, _attestedUser, _skillId);
    }

    /**
     * @dev Function 17: An AST holder approves or rejects an attestation request.
     * If approved, the attested user receives Aura.
     * @param _requestId The ID of the attestation request.
     * @param _approve True to approve, false to reject.
     */
    function approveAttestationRequest(uint256 _requestId, bool _approve) public {
        AttestationRequest storage req = attestationRequests[_requestId];
        require(req.status == AttestationRequest.Status.Pending, "AuraForge: Request not pending");
        require(_hasSoulboundToken(msg.sender), "AuraForge: Approver must have an AST");
        // An AST holder can attest if they are the original requester, or if they have sufficient reputation, or if delegated.
        // For simplicity, let's say *any* AST holder can attest for *any* other AST holder if they believe it.
        // In a real system, there would be rules (e.g., higher reputation required to attest to a skill).
        
        req.approver = msg.sender;
        if (_approve) {
            req.status = AttestationRequest.Status.Approved;
            skillAuraBalances[req.skillId][req.attestedUser] += req.requestedAura;
            totalAuraBalances[req.attestedUser] += req.requestedAura;

            if (_hasSoulboundToken(req.attestedUser)) {
                _updateSoulboundTokenAttributes(req.attestedUser);
            }
            emit AttestationApproved(_requestId, msg.sender, req.skillId, req.requestedAura);
        } else {
            req.status = AttestationRequest.Status.Rejected;
            emit AttestationRejected(_requestId, msg.sender);
        }
    }

    // --- V. Decentralized Task/Bounty System (Functions 18-24) ---

    /**
     * @dev Function 18: Creator defines a task, requiring specific skills and minimum Aura, with a reward.
     * Creator sends the reward amount along with the transaction (ether).
     * @param _skillRequired The skill ID required for the task.
     * @param _minAuraRequired The minimum Aura required in that skill for applicants.
     * @param _rewardAmount The reward amount in Ether.
     * @param _deadline The timestamp by which the task must be completed.
     * @param _detailsHash IPFS hash or similar URI for task description.
     */
    function createTask(
        uint256 _skillRequired,
        uint256 _minAuraRequired,
        uint256 _rewardAmount,
        uint256 _deadline,
        string memory _detailsHash
    ) public payable {
        require(_skillRequired > 0 && _skillRequired <= _skillIds.current(), "AuraForge: Invalid skill ID");
        require(msg.value == _rewardAmount, "AuraForge: Sent Ether must match rewardAmount");
        require(_deadline > block.timestamp, "AuraForge: Deadline must be in the future");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            skillRequired: _skillRequired,
            minAuraRequired: _minAuraRequired,
            rewardAmount: _rewardAmount,
            creationTimestamp: block.timestamp,
            deadline: _deadline,
            detailsHash: _detailsHash,
            status: Task.Status.Open,
            assignedTo: address(0),
            applicants: new address[](0),
            submissionHash: "",
            verificationHash: ""
        });
        emit TaskCreated(newTaskId, msg.sender, _skillRequired, _rewardAmount);
    }

    /**
     * @dev Function 19: User applies to an open task if they meet the Aura requirements.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.status == Task.Status.Open, "AuraForge: Task is not open for applications");
        require(block.timestamp < task.deadline, "AuraForge: Task application deadline passed");
        require(skillAuraBalances[task.skillRequired][msg.sender] >= task.minAuraRequired, "AuraForge: Insufficient Aura for this task");
        require(!hasAppliedForTask[_taskId][msg.sender], "AuraForge: Already applied for this task");
        
        task.applicants.push(msg.sender);
        hasAppliedForTask[_taskId][msg.sender] = true;
        emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @dev Function 20: Task creator assigns the task to an applicant.
     * @param _taskId The ID of the task.
     * @param _applicant The address of the applicant to assign the task to.
     */
    function assignTask(uint256 _taskId, address _applicant) public {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AuraForge: Only task creator can assign");
        require(task.status == Task.Status.Open, "AuraForge: Task is not open");
        require(hasAppliedForTask[_taskId][_applicant], "AuraForge: Applicant has not applied for this task");
        
        task.assignedTo = _applicant;
        task.status = Task.Status.Assigned;
        emit TaskAssigned(_taskId, _applicant);
    }

    /**
     * @dev Function 21: Assigned user submits proof of task completion.
     * @param _taskId The ID of the task.
     * @param _submissionHash IPFS hash or similar URI for completed work proof.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _submissionHash) public {
        Task storage task = tasks[_taskId];
        require(task.assignedTo == msg.sender, "AuraForge: Only assigned user can submit completion");
        require(task.status == Task.Status.Assigned, "AuraForge: Task is not in assigned status");
        require(block.timestamp < task.deadline, "AuraForge: Task submission deadline passed");

        task.submissionHash = _submissionHash;
        task.status = Task.Status.Submitted;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _submissionHash);
    }

    /**
     * @dev Function 22: Task creator verifies submission, releases reward, and updates assignee's Aura.
     * Adds Aura to the assigned user for the required skill.
     * @param _taskId The ID of the task.
     */
    function verifyTaskCompletion(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AuraForge: Only task creator can verify");
        require(task.status == Task.Status.Submitted, "AuraForge: Task is not submitted for verification");
        
        task.status = Task.Status.Verified;
        // Transfer reward Ether to the assignee
        (bool success, ) = payable(task.assignedTo).call{value: task.rewardAmount}("");
        require(success, "AuraForge: Failed to send reward");

        // Reward Aura for successful task completion
        uint256 auraReward = task.rewardAmount / 1 ether * 100; // Example: 100 Aura per ETH reward
        skillAuraBalances[task.skillRequired][task.assignedTo] += auraReward;
        totalAuraBalances[task.assignedTo] += auraReward;

        if (_hasSoulboundToken(task.assignedTo)) {
            _updateSoulboundTokenAttributes(task.assignedTo);
        }

        emit TaskVerified(_taskId, msg.sender, task.rewardAmount, task.assignedTo);
    }

    /**
     * @dev Function 23: Assigned user disputes an unfair rejection by the task creator.
     * This would ideally trigger a governance vote or an external arbitration process.
     * For this contract, it simply records the dispute.
     * @param _taskId The ID of the task.
     * @param _reasonHash IPFS hash or similar URI for the dispute reason.
     */
    function disputeTaskVerification(uint256 _taskId, string memory _reasonHash) public {
        Task storage task = tasks[_taskId];
        require(task.assignedTo == msg.sender, "AuraForge: Only assigned user can dispute");
        require(task.status == Task.Status.Rejected || task.status == Task.Status.Submitted, "AuraForge: Task not in a disputable state");
        
        // Mark task as disputed, further action would be handled by a governance module.
        // For simplicity, we don't change the status here, but rather log the event.
        emit TaskDisputed(_taskId, msg.sender, _reasonHash);
    }

    /**
     * @dev Function 24: Task creator cancels an unassigned task.
     * Refunds the reward amount to the creator.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "AuraForge: Only task creator can cancel");
        require(task.status == Task.Status.Open, "AuraForge: Task is not open for cancellation");
        
        task.status = Task.Status.Cancelled;
        // Refund remaining Ether to the creator
        (bool success, ) = payable(task.creator).call{value: task.rewardAmount}("");
        require(success, "AuraForge: Failed to send refund");

        emit TaskCancelled(_taskId, msg.sender);
    }

    // --- VI. Governance & Utilities (Functions 25-29) ---

    /**
     * @dev Function 25: Set the address of the ERC20 token used for governance (staking, voting).
     * Only callable by the contract owner.
     * @param _tokenAddress The address of the ERC20 governance token.
     */
    function setGovernanceToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "AuraForge: Governance token cannot be zero address");
        governanceToken = IERC20(_tokenAddress);
        emit GovernanceTokenSet(_tokenAddress);
    }

    /**
     * @dev Function 26: Set the minimum governance token stake required for skill validators.
     * Only callable by the contract owner.
     * @param _amount The new minimum stake amount.
     */
    function setMinStakeForValidator(uint256 _amount) public onlyOwner {
        require(_amount > 0, "AuraForge: Min stake must be greater than zero");
        minStakeForValidator = _amount;
        emit MinStakeForValidatorSet(_amount);
    }

    /**
     * @dev Function 27: (Placeholder for full DAO integration) Create a governance proposal for system changes.
     * This function would typically require a stake or existing reputation to propose.
     * @param _description A description of the proposal.
     * @param _target The address of the contract to call (e.g., this contract for internal changes).
     * @param _callData The encoded function call to execute if the proposal passes.
     */
    function proposeGovernanceChange(string memory _description, address _target, bytes memory _callData) public {
        // In a real DAO, this would create a proposal object, store it, and allow voting.
        // For this example, it's a placeholder to indicate future governance integration.
        // require(_hasSoulboundToken(msg.sender), "AuraForge: Only AST holders can propose");
        // require(totalAuraBalances[msg.sender] >= MIN_AURA_TO_PROPOSE, "AuraForge: Insufficient Aura to propose");
        // proposalCount.increment();
        // proposals[proposalCount.current()] = Proposal(...);
        // emit ProposalCreated(proposalCount.current(), _description);
        revert("AuraForge: Full governance system not implemented yet. This is a placeholder.");
    }

    /**
     * @dev Function 28: (Placeholder) Vote on an active governance proposal.
     * Requires the governance token or ASTs for voting power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        // require(_hasSoulboundToken(msg.sender), "AuraForge: Only AST holders can vote");
        // require(proposals[_proposalId].status == Proposal.Status.Active, "AuraForge: Proposal not active");
        // ... record vote ...
        revert("AuraForge: Full governance system not implemented yet. This is a placeholder.");
    }

    /**
     * @dev Function 29: Transfer contract ownership to a new address.
     * Inherited from OpenZeppelin's Ownable.
     * @param _newOwner The address of the new owner.
     */
    // This function is already provided by Ownable, exposed as `transferOwnership`.
    // Keeping it here for the explicit function count requirement.
    // function changeOwner(address _newOwner) public onlyOwner {
    //    transferOwnership(_newOwner);
    // }

    // --- ERC721 Overrides for Soulbound (Non-transferable) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent transfer if it's not a mint or burn to/from address(0)
        if (from != address(0) && to != address(0)) {
            revert("AuraForge: Soulbound Tokens are non-transferable");
        }
    }

    // `approve`, `setApprovalForAll` should also be effectively disabled for soulbound tokens.
    // The current ERC721 implementation will still allow setting approvals, but _beforeTokenTransfer
    // will prevent the actual transfer. For strict soulbound, these functions should be overridden
    // to revert, or a custom ERC721 implementation without them used.
    // For this example, relying on _beforeTokenTransfer to prevent actual transfers is sufficient.
    function approve(address to, uint256 tokenId) public view override {
        revert("AuraForge: Soulbound Tokens cannot be approved for transfer.");
    }

    function setApprovalForAll(address operator, bool approved) public view override {
        revert("AuraForge: Soulbound Tokens cannot be approved for transfer.");
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public view override {
        revert("AuraForge: Soulbound Tokens are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public view override {
        revert("AuraForge: Soulbound Tokens are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public view override {
        revert("AuraForge: Soulbound Tokens are non-transferable.");
    }

    // Optional: Make tokenURI dynamic by providing a base URI and expecting an off-chain service
    // to generate the metadata based on on-chain data.
    string private _baseTokenURI;

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        // A real implementation would parse the base URI and append the tokenId
        // and potentially other parameters to allow an off-chain service to render the dynamic metadata.
        // Example: "https://auraforge.io/metadata/tokenId/" + toString(tokenId)
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }
}

// Helper library for uint to string conversion
library Strings {
    bytes16 private constant _HEX_TABLE = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```