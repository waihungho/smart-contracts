This smart contract, named `AetherialSkillNet`, is designed as a decentralized, AI-augmented reputation and skill validation network. It introduces "Skill Orbs" as Soulbound Tokens (SBTs) to represent validated skills, dynamic skill levels, an attestation system for validators, and integrates Chainlink Functions for AI-powered pre-scoring of applications. The goal is to provide a novel, verifiable, and decentralized way to attest to professional skills and build a Web3-native reputation.

---

## Contract: `AetherialSkillNet`

### Outline:

1.  **Preamble & Imports:** License, Solidity version, OpenZeppelin (ERC721, Ownable), Chainlink Client.
2.  **Enums:** Define states for applications, orbs, and skill categories.
3.  **Structs:**
    *   `SkillOrb`: Details for each unique skill (SBT).
    *   `SkillApplication`: Records for user applications to acquire a skill orb.
    *   `SkillCategory`: Defines types of skills available on the network.
    *   `Validator`: Information about network validators.
4.  **State Variables:**
    *   Counters for unique IDs.
    *   Mappings to store `SkillOrb`s, `SkillApplication`s, `SkillCategory`s, and `Validator`s.
    *   Mapping for a simple on-chain reputation system.
    *   Chainlink specific variables for AI integration.
    *   DAO/Governance related addresses and parameters.
5.  **Events:** Crucial for off-chain monitoring and UI updates.
6.  **Modifiers:** Access control for different roles (owner, validator, skill category manager).
7.  **Constructor:** Initializes the ERC721 contract and Chainlink client.
8.  **SBT (Skill Orb) Management Functions:**
    *   User-facing functions for applying, submitting evidence, revoking, and burning Skill Orbs.
    *   Internal ERC721 override to enforce non-transferability.
9.  **Validator & Attestation System Functions:**
    *   Functions for users to become/deregister as validators, stake, and participate in the attestation process.
    *   Mechanisms for challenging and resolving disputed attestations.
    *   Reward distribution for validators.
10. **AI Oracle Integration (Chainlink Functions) Functions:**
    *   Requesting an off-chain AI service to pre-score skill applications.
    *   Callback function to receive and process AI results.
    *   Admin functions to configure Chainlink parameters.
11. **Skill Category & DAO Governance (Lite) Functions:**
    *   Functions for decentralized management of skill categories, including proposals, voting, and finalization.
    *   Parameter adjustments for skill categories.
    *   Management of `SkillCategoryManager` roles.
12. **View Functions:** Comprehensive read-only functions to query the state of orbs, applications, validators, skill categories, and reputation scores.

---

### Function Summary:

#### **SBT (Skill Orb) Management Functions:**

1.  `mintSkillOrbApplication(string memory _skillCategoryName, string memory _evidenceURI)`:
    *   Allows a user to apply for a new Skill Orb (SBT) of a specific category, providing initial evidence.
    *   Status: `PendingEvidence`.
2.  `submitAttestationEvidence(uint256 _applicationId, string memory _evidenceURI)`:
    *   Permits an applicant to update or add further evidence to their pending skill application.
    *   Status: `PendingValidation`.
3.  `revokeSkillOrbApplication(uint256 _applicationId)`:
    *   Enables an applicant to cancel their own pending skill orb application.
    *   Status: `Revoked`.
4.  `burnSkillOrb(uint256 _tokenId)`:
    *   Allows the owner of a Skill Orb (SBT) to permanently destroy it, removing it from their record.
    *   (Internal override for `_beforeTokenTransfer` enforces non-transferability).

#### **Validator & Attestation System Functions:**

5.  `registerValidator(uint256 _stakeAmount)`:
    *   Allows any user to register as a validator by staking a minimum amount of ETH/tokens.
    *   Requires `_minValidatorStake`.
6.  `deregisterValidator()`:
    *   Allows an active validator to unstake their funds and cease being a validator after a cooldown period.
7.  `attestSkillApplication(uint256 _applicationId, bool _approved)`:
    *   Allows a registered validator to review and approve or reject a pending skill application.
    *   If approved, increments `validatedByCount` and potentially mints the Skill Orb.
    *   Rewards validators for successful attestations.
8.  `challengeAttestation(uint256 _applicationId, address _validatorAddress)`:
    *   Enables another validator or a `SkillCategoryManager` to challenge a specific attestation made by a validator on an application, usually due to suspected malicious intent or error.
9.  `resolveChallenge(uint256 _applicationId, address _validatorAddress, bool _challengeApproved)`:
    *   Allows a `SkillCategoryManager` (or DAO consensus) to resolve a challenge, potentially penalizing the challenged validator or restoring their reputation.
10. `distributeAttestationRewards()`:
    *   (Conceptual/Placeholder) A function to distribute reputation points or tokens to validators for successfully attested applications.
11. `updateValidatorStake(uint256 _newStakeAmount)`:
    *   Allows an active validator to increase or decrease their staked amount.

#### **AI Oracle Integration (Chainlink Functions) Functions:**

12. `requestAIPrescore(uint256 _applicationId)`:
    *   Initiates an off-chain request (via Chainlink Functions) for an AI to pre-score or analyze the evidence of a skill application.
    *   Costs an `aiRequestFee`.
13. `fulfillAIPrescore(bytes32 _requestId, uint256 _preScore)`:
    *   Callback function invoked by the Chainlink oracle once the AI's pre-scoring result is available.
    *   Updates the `aiPreScore` for the relevant application.
14. `setChainlinkOracle(address _oracle, bytes32 _jobId)`:
    *   (Owner Only) Sets the Chainlink oracle address and job ID for AI requests.
15. `setAIFee(uint256 _fee)`:
    *   (Owner Only) Sets the fee required to request an AI pre-score.

#### **Skill Category & DAO Governance (Lite) Functions:**

16. `proposeSkillCategory(string memory _name, uint256 _minAttestationsRequired)`:
    *   Allows a `SkillCategoryManager` to propose a new skill category, setting the minimum attestations required for a Skill Orb to be minted for it.
    *   Status: `Proposed`.
17. `voteOnSkillCategoryProposal(uint256 _proposalId, bool _approve)`:
    *   (Conceptual) Allows participants (e.g., validators or other designated roles) to vote on proposed skill categories.
18. `finalizeSkillCategoryProposal(uint256 _proposalId)`:
    *   Allows a `SkillCategoryManager` to finalize a proposed skill category if it has met the voting requirements, making it active.
    *   Status: `Active`.
19. `updateSkillCategoryParameters(uint256 _categoryId, uint256 _newMinAttestationsRequired)`:
    *   Allows `SkillCategoryManagers` to adjust parameters of an existing skill category, such as the minimum attestations required.
20. `addSkillCategoryManager(address _manager)`:
    *   (Owner Only) Grants the `SkillCategoryManager` role to an address.
21. `removeSkillCategoryManager(address _manager)`:
    *   (Owner Only) Revokes the `SkillCategoryManager` role from an address.
22. `setMinimumValidationStake(uint256 _amount)`:
    *   (Owner/DAO) Sets the minimum ETH/token stake required to become a validator.

#### **View Functions:**

23. `getSkillOrbDetails(uint256 _tokenId)`:
    *   Returns all details for a specific Skill Orb by its ID.
24. `getUserSkillOrbs(address _user)`:
    *   Returns an array of Skill Orb IDs owned by a specific user.
25. `getSkillApplicationStatus(uint256 _applicationId)`:
    *   Retrieves the current status and details of a skill application.
26. `getValidatorStatus(address _validator)`:
    *   Returns the active status, stake, and reputation of a validator.
27. `getSkillCategoryDetails(uint256 _categoryId)`:
    *   Provides details about a specific skill category, including its name and attestation requirements.
28. `getUserReputation(address _user)`:
    *   Returns the accumulated reputation score for a general user (not necessarily a validator).
29. `getValidatorReputation(address _validator)`:
    *   Returns the reputation score specifically for a validator.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/CCIPReceiver.sol"; // Using CCIPReceiver for Chainlink Functions, which is part of CCIP
import "@chainlink/contracts/src/v0.8/functions/v1/FunctionsClient.sol"; // For Chainlink Functions specific client

/**
 * @title AetherialSkillNet
 * @dev A decentralized, AI-augmented reputation and skill validation network.
 *      It leverages Soulbound Tokens (SBTs) for skill representation,
 *      a validator attestation system, and Chainlink Functions for AI-powered pre-scoring.
 *
 * Outline:
 * 1. Preamble & Imports
 * 2. Enums: ApplicationStatus, OrbStatus, SkillCategoryStatus
 * 3. Structs: SkillOrb, SkillApplication, SkillCategory, Validator
 * 4. State Variables: Counters, Mappings, Chainlink specific, DAO parameters
 * 5. Events: For all major actions
 * 6. Modifiers: onlyOwner, onlyValidator, onlySkillCategoryManager
 * 7. Constructor: Initializes ERC721 and Chainlink client
 * 8. SBT (Skill Orb) Management Functions: mint, submit evidence, revoke, burn, non-transferability override
 * 9. Validator & Attestation System Functions: register, deregister, attest, challenge, resolve challenge, rewards, update stake
 * 10. AI Oracle Integration (Chainlink Functions) Functions: request pre-score, fulfill pre-score, set Chainlink config
 * 11. Skill Category & DAO Governance (Lite) Functions: propose, vote, finalize, update params, manage managers, set min stake
 * 12. View Functions: Get details for orbs, applications, validators, categories, reputation.
 */
contract AetherialSkillNet is ERC721, Ownable, FunctionsClient {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum ApplicationStatus { PendingEvidence, PendingValidation, Approved, Rejected, Revoked, Challenged }
    enum OrbStatus { Active, Burned }
    enum SkillCategoryStatus { Proposed, Active, Inactive }

    // --- Structs ---

    /**
     * @dev Represents a Soulbound Token (SBT) for a validated skill. Non-transferable.
     *      Can have dynamic levels based on further attestations or achievements.
     * @param tokenId Unique identifier for the Skill Orb.
     * @param owner Address that possesses this Skill Orb.
     * @param skillCategoryId ID of the skill category this orb belongs to.
     * @param level The current level of proficiency for this skill (dynamic).
     * @param status Current status of the orb (e.g., Active, Burned).
     * @param metadataURI IPFS/URL to the metadata (e.g., image, detailed description).
     */
    struct SkillOrb {
        uint256 tokenId;
        address owner;
        uint256 skillCategoryId;
        uint256 level; // Dynamic: can increase with further attestations or achievements
        OrbStatus status;
        string metadataURI;
    }

    /**
     * @dev Represents a user's application to acquire a Skill Orb.
     * @param applicant Address submitting the application.
     * @param skillCategoryId ID of the skill category being applied for.
     * @param evidenceURI IPFS/URL to the evidence supporting the skill claim.
     * @param status Current status of the application.
     * @param validatedByCount Number of validators who have approved this application.
     * @param aiPreScore Pre-score given by AI (0-100), -1 if not requested/available.
     * @param attestingValidators Map of validator address to their attestation status (true for approved, false for rejected).
     */
    struct SkillApplication {
        address applicant;
        uint256 skillCategoryId;
        string evidenceURI;
        ApplicationStatus status;
        uint256 validatedByCount;
        int256 aiPreScore; // -1 if not requested/available, 0-100 otherwise
        mapping(address => bool) attestingValidators; // True if validator approved
    }

    /**
     * @dev Defines a type of skill available on the network (e.g., "Solidity Expert").
     * @param name Name of the skill category.
     * @param minAttestationsRequired Minimum number of validator attestations needed to mint a Skill Orb for this category.
     * @param currentStatus Current status of the skill category (e.g., Proposed, Active).
     * @param proposalVotes Count of votes for a proposed skill category.
     */
    struct SkillCategory {
        string name;
        uint256 minAttestationsRequired;
        SkillCategoryStatus currentStatus;
        uint256 proposalVotes; // For governance proposals
    }

    /**
     * @dev Represents a validator in the network.
     * @param isActive True if the validator is currently active.
     * @param stake Amount of ETH/tokens staked by the validator.
     * @param reputationScore Score reflecting the validator's accuracy and trustworthiness.
     */
    struct Validator {
        bool isActive;
        uint256 stake;
        uint256 reputationScore;
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _applicationIdCounter;
    Counters.Counter private _skillCategoryIdCounter;

    // Mappings for core data structures
    mapping(uint256 => SkillOrb) public idToSkillOrb;
    mapping(address => uint256[]) public userSkillOrbs; // Store token IDs for quick lookup
    mapping(uint256 => SkillApplication) public idToSkillApplication;
    mapping(address => uint256[]) public userSkillApplications; // Store application IDs for quick lookup
    mapping(uint256 => SkillCategory) public idToSkillCategory;
    mapping(string => uint256) public skillCategoryNameToId; // For easy lookup by name
    mapping(address => Validator) public validators;

    // General user reputation (separate from validator reputation)
    mapping(address => uint256) public userReputation;

    // Chainlink Functions specific variables
    bytes32 public s_functionsJobId;
    uint256 public s_aiRequestFee; // LINK tokens or native token depending on config

    // Governance/DAO variables
    uint256 public minValidatorStake = 1 ether; // Minimum stake to become a validator
    mapping(address => bool) public skillCategoryManagers; // Addresses authorized to manage skill categories

    // --- Events ---
    event SkillOrbApplicationCreated(uint256 indexed applicationId, address indexed applicant, uint256 indexed skillCategoryId);
    event SkillOrbMinted(uint256 indexed tokenId, address indexed owner, uint256 indexed skillCategoryId);
    event SkillOrbBurned(uint256 indexed tokenId, address indexed owner);
    event SkillApplicationStatusChanged(uint256 indexed applicationId, ApplicationStatus newStatus, string reason);
    event ValidatorRegistered(address indexed validator, uint256 stake);
    event ValidatorDeregistered(address indexed validator);
    event SkillAttested(uint256 indexed applicationId, address indexed validator, bool approved);
    event AttestationChallenged(uint256 indexed applicationId, address indexed challengedValidator, address indexed challenger);
    event ChallengeResolved(uint256 indexed applicationId, address indexed challengedValidator, bool challengeApproved);
    event AIPrescoreRequested(uint256 indexed applicationId, bytes32 indexed requestId);
    event AIPrescoreFulfilled(uint256 indexed applicationId, int256 preScore);
    event SkillCategoryProposed(uint256 indexed categoryId, string name, uint256 minAttestationsRequired);
    event SkillCategoryFinalized(uint256 indexed categoryId, string name);
    event SkillCategoryParamsUpdated(uint256 indexed categoryId, uint256 newMinAttestations);
    event SkillLevelIncremented(uint256 indexed tokenId, uint256 newLevel);

    // --- Modifiers ---
    modifier onlyValidator() {
        require(validators[msg.sender].isActive, "Caller is not an active validator");
        _;
    }

    modifier onlySkillCategoryManager() {
        require(skillCategoryManagers[msg.sender] || owner() == msg.sender, "Caller is not a skill category manager");
        _;
    }

    // --- Constructor ---
    constructor(
        address _router, // Chainlink Functions Router address
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) FunctionsClient(_router) {
        // Initial setup for the owner as a skill category manager
        skillCategoryManagers[msg.sender] = true;
    }

    // --- Core SBT (Skill Orb) Management Functions ---

    /**
     * @dev Allows a user to apply for a new Skill Orb.
     * @param _skillCategoryName The name of the skill category (e.g., "Solidity Expert").
     * @param _evidenceURI IPFS/URL to supporting evidence (e.g., project portfolio, resume).
     */
    function mintSkillOrbApplication(string memory _skillCategoryName, string memory _evidenceURI) public {
        uint256 categoryId = skillCategoryNameToId[_skillCategoryName];
        require(categoryId != 0, "Skill category does not exist");
        require(idToSkillCategory[categoryId].currentStatus == SkillCategoryStatus.Active, "Skill category not active");
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        _applicationIdCounter.increment();
        uint256 newApplicationId = _applicationIdCounter.current();

        idToSkillApplication[newApplicationId] = SkillApplication({
            applicant: msg.sender,
            skillCategoryId: categoryId,
            evidenceURI: _evidenceURI,
            status: ApplicationStatus.PendingValidation, // Direct to validation, skip pending evidence for simplicity
            validatedByCount: 0,
            aiPreScore: -1 // Default to -1 indicating no AI pre-score yet
        });
        userSkillApplications[msg.sender].push(newApplicationId);

        emit SkillOrbApplicationCreated(newApplicationId, msg.sender, categoryId);
        emit SkillApplicationStatusChanged(newApplicationId, ApplicationStatus.PendingValidation, "Initial application submitted");
    }

    /**
     * @dev Allows an applicant to update or add further evidence to their pending skill application.
     * @param _applicationId The ID of the application to update.
     * @param _newEvidenceURI New IPFS/URL to updated evidence.
     */
    function submitAttestationEvidence(uint256 _applicationId, string memory _newEvidenceURI) public {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.applicant == msg.sender, "Not your application");
        require(
            app.status == ApplicationStatus.PendingValidation || app.status == ApplicationStatus.Challenged,
            "Application not in a modifiable state"
        );
        require(bytes(_newEvidenceURI).length > 0, "New evidence URI cannot be empty");

        app.evidenceURI = _newEvidenceURI;
        // Optionally reset AI pre-score or require new validation if evidence changes significantly
        app.aiPreScore = -1; // Reset AI score as evidence changed

        emit SkillApplicationStatusChanged(_applicationId, app.status, "Evidence updated");
    }

    /**
     * @dev Allows an applicant to cancel their own pending skill orb application.
     * @param _applicationId The ID of the application to revoke.
     */
    function revokeSkillOrbApplication(uint256 _applicationId) public {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.applicant == msg.sender, "Not your application");
        require(
            app.status != ApplicationStatus.Approved && app.status != ApplicationStatus.Rejected && app.status != ApplicationStatus.Revoked,
            "Application already finalized or revoked"
        );

        app.status = ApplicationStatus.Revoked;
        emit SkillApplicationStatusChanged(_applicationId, ApplicationStatus.Revoked, "Application revoked by applicant");
    }

    /**
     * @dev Allows the owner of a Skill Orb to permanently burn it (destroy the SBT).
     * @param _tokenId The ID of the Skill Orb to burn.
     */
    function burnSkillOrb(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not authorized to burn this token");

        SkillOrb storage orb = idToSkillOrb[_tokenId];
        require(orb.status == OrbStatus.Active, "Skill Orb is not active");

        // ERC721 internal burn
        _burn(_tokenId);
        orb.status = OrbStatus.Burned;
        orb.owner = address(0); // Clear owner to indicate burned

        // Remove from userSkillOrbs array (less efficient, but acceptable for reads)
        uint256[] storage orbs = userSkillOrbs[msg.sender];
        for (uint256 i = 0; i < orbs.length; i++) {
            if (orbs[i] == _tokenId) {
                orbs[i] = orbs[orbs.length - 1]; // Replace with last element
                orbs.pop(); // Remove last element
                break;
            }
        }

        emit SkillOrbBurned(_tokenId, msg.sender);
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to enforce Soulbound (non-transferable) nature.
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address(0)) and burning (to address(0))
        if (from != address(0) && to != address(0)) {
            revert("Skill Orbs are soulbound and cannot be transferred.");
        }
    }

    // --- Validator & Attestation System Functions ---

    /**
     * @dev Allows any user to register as a validator by staking a minimum amount.
     * @param _stakeAmount The amount of ETH/tokens to stake.
     */
    function registerValidator(uint256 _stakeAmount) public payable {
        require(!validators[msg.sender].isActive, "Already an active validator");
        require(msg.value >= minValidatorStake, "Insufficient stake amount");
        require(_stakeAmount == msg.value, "Stake amount must match sent value");

        validators[msg.sender] = Validator({
            isActive: true,
            stake: _stakeAmount,
            reputationScore: 0 // Initial reputation
        });

        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /**
     * @dev Allows an active validator to unstake their funds and cease being a validator.
     *      A cooldown period or challenge window could be added here for production.
     */
    function deregisterValidator() public onlyValidator {
        address validatorAddress = msg.sender;
        Validator storage val = validators[validatorAddress];

        val.isActive = false;
        // In a real system, there would be a cooldown/withdrawal period
        // transfer funds back (val.stake)
        (bool success,) = payable(validatorAddress).call{value: val.stake}("");
        require(success, "Failed to send stake back");
        val.stake = 0;

        emit ValidatorDeregistered(validatorAddress);
    }

    /**
     * @dev Allows a registered validator to review and approve or reject a pending skill application.
     * @param _applicationId The ID of the application to attest.
     * @param _approved True to approve, false to reject.
     */
    function attestSkillApplication(uint256 _applicationId, bool _approved) public onlyValidator {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.status == ApplicationStatus.PendingValidation, "Application not in pending validation state");
        require(!app.attestingValidators[msg.sender], "Validator already attested this application");

        app.attestingValidators[msg.sender] = true; // Mark validator's decision

        if (_approved) {
            app.validatedByCount++;
            validators[msg.sender].reputationScore += 1; // Reward for positive attestation (simple)
        } else {
            // Penalize for negative attestation if it goes against consensus later, or just record
            // For now, no direct penalty for rejection, just no reward.
        }

        SkillCategory storage category = idToSkillCategory[app.skillCategoryId];

        // If enough positive attestations, mint the Skill Orb
        if (app.validatedByCount >= category.minAttestationsRequired) {
            app.status = ApplicationStatus.Approved;
            _mintSkillOrb(app.applicant, app.skillCategoryId, app.evidenceURI);
            emit SkillApplicationStatusChanged(_applicationId, ApplicationStatus.Approved, "Enough attestations received");
        } else {
            emit SkillAttested(_applicationId, msg.sender, _approved);
        }
    }

    /**
     * @dev Internal function to mint a new Skill Orb (SBT).
     */
    function _mintSkillOrb(address _to, uint256 _skillCategoryId, string memory _metadataURI) internal {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // ERC721 internal safeMint
        _safeMint(_to, newTokenId);

        idToSkillOrb[newTokenId] = SkillOrb({
            tokenId: newTokenId,
            owner: _to,
            skillCategoryId: _skillCategoryId,
            level: 1, // Start at level 1
            status: OrbStatus.Active,
            metadataURI: _metadataURI
        });
        userSkillOrbs[_to].push(newTokenId);

        emit SkillOrbMinted(newTokenId, _to, _skillCategoryId);
    }

    /**
     * @dev Allows another validator or a skill category manager to challenge a specific attestation
     *      made by a validator on an application.
     * @param _applicationId The ID of the application.
     * @param _validatorAddress The address of the validator whose attestation is being challenged.
     */
    function challengeAttestation(uint256 _applicationId, address _validatorAddress) public {
        // Can be called by any validator or a skill category manager
        require(validators[msg.sender].isActive || skillCategoryManagers[msg.sender], "Not authorized to challenge");

        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.status == ApplicationStatus.Approved || app.status == ApplicationStatus.Rejected, "Application not in final state");
        require(app.attestingValidators[_validatorAddress], "Validator did not attest this application");

        // A more robust system would involve a stake for the challenge, and a formal dispute resolution period.
        // For simplicity, we just mark it as challenged.
        app.status = ApplicationStatus.Challenged;
        // Optionally penalize challenger if challenge is frivolous.
        emit AttestationChallenged(_applicationId, _validatorAddress, msg.sender);
        emit SkillApplicationStatusChanged(_applicationId, ApplicationStatus.Challenged, "Attestation challenged");
    }

    /**
     * @dev Allows a SkillCategoryManager (or DAO consensus) to resolve a challenge.
     * @param _applicationId The ID of the application under challenge.
     * @param _challengedValidator The validator whose attestation was challenged.
     * @param _challengeApproved True if the challenge is upheld (meaning the challenged validator was wrong).
     */
    function resolveChallenge(uint256 _applicationId, address _challengedValidator, bool _challengeApproved) public onlySkillCategoryManager {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.status == ApplicationStatus.Challenged, "Application not currently challenged");
        require(app.attestingValidators[_challengedValidator], "Challenged address did not attest this application");

        Validator storage val = validators[_challengedValidator];

        if (_challengeApproved) {
            // If challenge is approved, the challenged validator was wrong. Penalize.
            require(val.reputationScore > 0, "Validator reputation already at zero.");
            val.reputationScore -= 1; // Simple reputation reduction
            // In a real system, might slash a portion of their stake.
        } else {
            // If challenge is rejected, the challenged validator was correct, and challenger might be penalized.
            // For simplicity, no penalty to challenger here, but reputation of challenged validator might increase.
            val.reputationScore += 1; // Reward for falsely challenged
        }

        // Revert to previous status or new status based on resolution
        // This is simplified. In complex systems, the original decision might be reverted.
        app.status = ApplicationStatus.PendingValidation; // Or back to Approved/Rejected as before challenge
        emit ChallengeResolved(_applicationId, _challengedValidator, _challengeApproved);
        emit SkillApplicationStatusChanged(_applicationId, app.status, "Challenge resolved");
    }

    /**
     * @dev (Conceptual) A function to distribute reputation points or tokens to validators.
     *      This would likely be called by a DAO or an automated bot periodically.
     */
    function distributeAttestationRewards() public {
        // This function would iterate through recent approved applications
        // and award reputation/tokens based on a complex formula.
        // For this example, reputation is updated directly in attestSkillApplication.
    }

    /**
     * @dev Allows an active validator to increase or decrease their staked amount.
     *      Decreasing stake might have a cooldown.
     * @param _newStakeAmount The new desired stake amount.
     */
    function updateValidatorStake(uint256 _newStakeAmount) public payable onlyValidator {
        Validator storage val = validators[msg.sender];
        require(_newStakeAmount >= minValidatorStake, "New stake below minimum");

        if (_newStakeAmount > val.stake) {
            // Increase stake
            require(msg.value == (_newStakeAmount - val.stake), "Amount sent does not match stake increase");
            val.stake = _newStakeAmount;
        } else if (_newStakeAmount < val.stake) {
            // Decrease stake - release funds. Could implement a cooldown.
            uint256 amountToReturn = val.stake - _newStakeAmount;
            val.stake = _newStakeAmount;
            (bool success,) = payable(msg.sender).call{value: amountToReturn}("");
            require(success, "Failed to return excess stake");
        } else {
            require(msg.value == 0, "No stake change, no ETH expected");
        }
        emit ValidatorRegistered(msg.sender, val.stake); // Re-emit for stake update
    }

    // --- AI Oracle Integration (Chainlink Functions) Functions ---

    /**
     * @dev Requests an off-chain AI service to pre-score or analyze the evidence of a skill application.
     *      Requires a fee in LINK tokens (or native token if configured in Chainlink Functions).
     * @param _applicationId The ID of the application to pre-score.
     */
    function requestAIPrescore(uint256 _applicationId) public payable {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        require(app.applicant == msg.sender, "Not your application");
        require(app.status == ApplicationStatus.PendingValidation, "Application not in pending state");
        require(app.aiPreScore == -1, "AI pre-score already requested or fulfilled");
        require(msg.value >= s_aiRequestFee, "Insufficient fee for AI request"); // Using native token for simplicity, adjust for LINK

        // Build Chainlink Functions request
        string[] memory args = new string[](2);
        args[0] = app.evidenceURI; // Pass evidence URI to the AI script
        args[1] = app.skillCategoryId.toString(); // Pass skill category for context

        bytes32 requestId = _sendRequest(s_functionsJobId, "", args, s_aiRequestFee, gasLimit); // gasLimit needs to be defined
        emit AIPrescoreRequested(_applicationId, requestId);
    }

    // Default gas limit for Chainlink Functions requests (adjust as needed)
    uint64 public gasLimit = 300000;

    /**
     * @dev Callback function invoked by the Chainlink oracle once the AI's pre-scoring result is available.
     * @param _requestId The ID of the Chainlink request.
     * @param _response The raw response from the oracle (expected to be the AI pre-score as a string).
     * @param _err The error message if the request failed.
     */
    function fulfillAIPrescore(bytes32 _requestId, bytes memory _response, bytes memory _err) internal override {
        // Link _requestId to actual applicationId (requires mapping requestId to applicationId)
        // For simplicity, let's assume `_requestId` is directly tied to an application ID or find it.
        // A more robust system would map `requestId` to `applicationId` to handle async callbacks.
        // As a placeholder, let's just find the application by iterating (not efficient for production):
        // (In a real scenario, map requestId -> applicationId when sending the request)
        uint256 applicationId = 0;
        bool found = false;
        for (uint256 i = 1; i <= _applicationIdCounter.current(); i++) { // Iterate all applications, find which one had this request
             if (idToSkillApplication[i].status == ApplicationStatus.PendingValidation && idToSkillApplication[i].aiPreScore == -1) {
                // This is a very weak link. A proper system needs a requestId -> applicationId map.
                // For a concept demo, we'll assign it to the next un-prescored pending validation.
                // This is a major simplification.
                applicationId = i;
                found = true;
                break;
            }
        }
        if (!found) {
            // Handle case where application not found or already processed.
            // Log an error or revert, depending on desired behavior.
            return;
        }

        if (_err.length > 0) {
            // Handle Chainlink Functions execution errors
            emit AIPrescoreFulfilled(applicationId, -1); // Indicate error with -1
            emit SkillApplicationStatusChanged(applicationId, idToSkillApplication[applicationId].status, string(abi.encodePacked("AI prescore failed: ", _err)));
            return;
        }

        int256 preScore = 0;
        try {
            preScore = int256(abi.decode(_response, (uint256))); // Decode response as uint256 for score 0-100
        } catch {
            // Handle decoding errors (e.g., AI returned non-numeric result)
            emit AIPrescoreFulfilled(applicationId, -1);
            emit SkillApplicationStatusChanged(applicationId, idToSkillApplication[applicationId].status, "AI prescore decoding error");
            return;
        }

        SkillApplication storage app = idToSkillApplication[applicationId];
        app.aiPreScore = preScore; // Store the AI pre-score

        emit AIPrescoreFulfilled(applicationId, preScore);
        emit SkillApplicationStatusChanged(applicationId, app.status, "AI prescore received");
    }

    /**
     * @dev (Owner Only) Sets the Chainlink Functions Router address and job ID.
     * @param _jobId The job ID of the Chainlink Functions consumer.
     */
    function setChainlinkOracle(bytes32 _jobId) public onlyOwner {
        s_functionsJobId = _jobId;
    }

    /**
     * @dev (Owner Only) Sets the fee required to request an AI pre-score.
     * @param _fee The fee amount (in LINK or native token depending on Chainlink config).
     */
    function setAIFee(uint256 _fee) public onlyOwner {
        s_aiRequestFee = _fee;
    }

    // --- Skill Category & DAO Governance (Lite) Functions ---

    /**
     * @dev Allows a SkillCategoryManager to propose a new skill category.
     *      The proposal then needs to be voted on/finalized.
     * @param _name The name of the new skill category (e.g., "Web3 Developer").
     * @param _minAttestationsRequired Minimum validator attestations needed for this skill.
     */
    function proposeSkillCategory(string memory _name, uint256 _minAttestationsRequired) public onlySkillCategoryManager {
        require(skillCategoryNameToId[_name] == 0, "Skill category name already exists");
        require(bytes(_name).length > 0, "Skill category name cannot be empty");
        require(_minAttestationsRequired > 0, "Min attestations must be greater than 0");

        _skillCategoryIdCounter.increment();
        uint256 newCategoryId = _skillCategoryIdCounter.current();

        idToSkillCategory[newCategoryId] = SkillCategory({
            name: _name,
            minAttestationsRequired: _minAttestationsRequired,
            currentStatus: SkillCategoryStatus.Proposed,
            proposalVotes: 0 // Initialize votes
        });
        skillCategoryNameToId[_name] = newCategoryId;

        emit SkillCategoryProposed(newCategoryId, _name, _minAttestationsRequired);
    }

    /**
     * @dev (Conceptual) Allows participants to vote on proposed skill categories.
     *      In a real DAO, this would involve token-weighted voting.
     * @param _proposalId The ID of the skill category proposal.
     * @param _approve True to approve the proposal, false to reject.
     */
    function voteOnSkillCategoryProposal(uint256 _proposalId, bool _approve) public {
        SkillCategory storage category = idToSkillCategory[_proposalId];
        require(category.currentStatus == SkillCategoryStatus.Proposed, "Category not in proposed state");

        // Simple vote count for demonstration. In reality, consider voter weight (e.g., based on stake or reputation).
        if (_approve) {
            category.proposalVotes++;
        } else {
            // Can decrement votes or just register rejection.
        }
        // Emit a Vote event (omitted for brevity)
    }

    /**
     * @dev Allows a SkillCategoryManager to finalize a proposed skill category if it meets criteria.
     * @param _proposalId The ID of the skill category proposal to finalize.
     */
    function finalizeSkillCategoryProposal(uint256 _proposalId) public onlySkillCategoryManager {
        SkillCategory storage category = idToSkillCategory[_proposalId];
        require(category.currentStatus == SkillCategoryStatus.Proposed, "Category not in proposed state");
        // Example: require a certain number of votes to pass
        require(category.proposalVotes >= 3, "Not enough votes to finalize proposal (example: 3)");

        category.currentStatus = SkillCategoryStatus.Active;
        emit SkillCategoryFinalized(_proposalId, category.name);
    }

    /**
     * @dev Allows SkillCategoryManagers to adjust parameters of an existing skill category.
     * @param _categoryId The ID of the skill category to update.
     * @param _newMinAttestationsRequired The new minimum attestations required.
     */
    function updateSkillCategoryParameters(uint256 _categoryId, uint256 _newMinAttestationsRequired) public onlySkillCategoryManager {
        SkillCategory storage category = idToSkillCategory[_categoryId];
        require(category.currentStatus == SkillCategoryStatus.Active, "Skill category not active");
        require(_newMinAttestationsRequired > 0, "Min attestations must be greater than 0");

        category.minAttestationsRequired = _newMinAttestationsRequired;
        emit SkillCategoryParamsUpdated(_categoryId, _newMinAttestationsRequired);
    }

    /**
     * @dev (Owner Only) Grants the `SkillCategoryManager` role to an address.
     * @param _manager The address to grant the role.
     */
    function addSkillCategoryManager(address _manager) public onlyOwner {
        skillCategoryManagers[_manager] = true;
    }

    /**
     * @dev (Owner Only) Revokes the `SkillCategoryManager` role from an address.
     * @param _manager The address to revoke the role from.
     */
    function removeSkillCategoryManager(address _manager) public onlyOwner {
        require(msg.sender != _manager, "Cannot revoke own manager role"); // Prevent accidental lockout
        skillCategoryManagers[_manager] = false;
    }

    /**
     * @dev (Owner/DAO) Sets the minimum ETH/token stake required to become a validator.
     * @param _amount The new minimum stake amount.
     */
    function setMinimumValidationStake(uint256 _amount) public onlyOwner { // Could be DAO-governed
        require(_amount > 0, "Minimum stake must be greater than zero");
        minValidatorStake = _amount;
    }

    // --- Dynamic Orb Functions (Internal/Triggered) ---

    /**
     * @dev Increments the level of a Skill Orb.
     *      Could be called internally based on further attestations,
     *      or by an oracle verifying external achievements.
     * @param _tokenId The ID of the Skill Orb to level up.
     */
    function incrementSkillLevel(uint256 _tokenId) public {
        SkillOrb storage orb = idToSkillOrb[_tokenId];
        require(orb.owner == msg.sender || skillCategoryManagers[msg.sender] || owner() == msg.sender, "Not authorized to level up this orb");
        require(orb.status == OrbStatus.Active, "Skill Orb is not active");

        orb.level++;
        emit SkillLevelIncremented(_tokenId, orb.level);
        // This could trigger an update to the metadataURI off-chain to reflect new level.
    }

    // --- View Functions ---

    /**
     * @dev Returns all details for a specific Skill Orb by its ID.
     * @param _tokenId The ID of the Skill Orb.
     * @return SkillOrb struct values.
     */
    function getSkillOrbDetails(uint256 _tokenId) public view returns (uint256, address, uint256, uint256, OrbStatus, string memory) {
        SkillOrb storage orb = idToSkillOrb[_tokenId];
        return (orb.tokenId, orb.owner, orb.skillCategoryId, orb.level, orb.status, orb.metadataURI);
    }

    /**
     * @dev Returns an array of Skill Orb IDs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of uint256 representing Skill Orb IDs.
     */
    function getUserSkillOrbs(address _user) public view returns (uint256[] memory) {
        return userSkillOrbs[_user];
    }

    /**
     * @dev Retrieves the current status and details of a skill application.
     * @param _applicationId The ID of the application.
     * @return SkillApplication struct values.
     */
    function getSkillApplicationStatus(uint256 _applicationId)
        public
        view
        returns (address, uint256, string memory, ApplicationStatus, uint256, int256)
    {
        SkillApplication storage app = idToSkillApplication[_applicationId];
        return (app.applicant, app.skillCategoryId, app.evidenceURI, app.status, app.validatedByCount, app.aiPreScore);
    }

    /**
     * @dev Returns the active status, stake, and reputation of a validator.
     * @param _validator The address of the validator.
     * @return isActive, stake, reputationScore.
     */
    function getValidatorStatus(address _validator) public view returns (bool, uint256, uint256) {
        Validator storage val = validators[_validator];
        return (val.isActive, val.stake, val.reputationScore);
    }

    /**
     * @dev Provides details about a specific skill category.
     * @param _categoryId The ID of the skill category.
     * @return name, minAttestationsRequired, currentStatus, proposalVotes.
     */
    function getSkillCategoryDetails(uint256 _categoryId) public view returns (string memory, uint256, SkillCategoryStatus, uint256) {
        SkillCategory storage category = idToSkillCategory[_categoryId];
        return (category.name, category.minAttestationsRequired, category.currentStatus, category.proposalVotes);
    }

    /**
     * @dev Returns the accumulated reputation score for a general user.
     *      This is a basic placeholder; a real reputation system might be more complex.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user]; // This would be updated via successful skill orb mints, challenges, etc.
    }

    /**
     * @dev Returns the reputation score specifically for a validator.
     * @param _validator The address of the validator.
     * @return The validator's reputation score.
     */
    function getValidatorReputation(address _validator) public view returns (uint256) {
        return validators[_validator].reputationScore;
    }
}
```