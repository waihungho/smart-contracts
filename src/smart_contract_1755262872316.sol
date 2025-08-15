Here's a smart contract in Solidity that incorporates interesting, advanced concepts, and trendy functions, designed not to directly duplicate existing open-source projects but to combine functionalities in a unique way.

This contract, `AuraGenesisNexus`, acts as a decentralized Skill and Reputation Registry. It leverages the concept of **Soulbound Tokens (SBTs)** for skill attestation, integrates with a simulated **AI Oracle** for verifiable credentials, implements a **dynamic reputation system**, allows for **liquid delegation** of attestation power, and provides **conditional access** to functions based on skills and reputation. It also includes a conceptual **meta-transaction sponsorship** mechanism.

---

## Contract Name: `AuraGenesisNexus`

### Outline:

1.  **Core State Management:** Defines essential data structures and mappings for skills, SBTs, and user reputation scores.
2.  **Skill Definition & Attestation:** Functions for administrators to define new skill types and for qualified entities (or users themselves, pending verification) to issue Skill-Bound Tokens (SBTs).
3.  **SBT Lifecycle Management:** Handles the dynamic aspects of SBTs, including revocation, renewal, and querying their status and expiration.
4.  **Reputation System:** Manages on-chain reputation scores, which can be updated based on skill verification results and subject to decay.
5.  **AI Oracle Integration (Simulated):** Provides an interface for interacting with a hypothetical decentralized AI verification oracle and its callback mechanism for processing verification results.
6.  **Liquid Verification Delegation:** Enables users to delegate their attestation and verification authority to other trusted addresses.
7.  **Access Control & Conditional Execution:** Demonstrates how possession of specific SBTs and a minimum reputation score can gate access to certain contract functionalities or resource allocations.
8.  **Meta-Transaction Sponsorship (Conceptual):** A conceptual mechanism for allowing third parties (e.g., DAOs, sponsors) to cover transaction fees for specific users based on predefined conditions, enhancing user experience.
9.  **Administrative & Utility Functions:** Standard owner-only controls for contract management, including pausing, unpausing, and fund withdrawals.

### Function Summary:

1.  `constructor()`: Initializes the contract, setting the deployer as the owner.
2.  `defineSkill(string _name, string _description, uint256 _validityDurationSeconds)`: (Admin) Allows the owner to define a new type of skill, specifying its name, description, and the duration for which its corresponding SBT is valid.
3.  `attestSkill(address _recipient, uint256 _skillId, string _attestationProofUri)`: Issues a non-transferable Skill-Bound Token (SBT) to a specified recipient for a given `_skillId`. The attester is typically the caller (or their delegatee), providing a URI to off-chain proof.
4.  `revokeSkillAttestation(uint256 _sbtId)`: Revokes an existing SBT. This can be called by the original attester or the contract owner.
5.  `renewSkillAttestation(uint256 _sbtId, string _newAttestationProofUri)`: Allows the holder of an expiring SBT to renew it, requiring a new URI for updated proof, potentially triggering re-verification.
6.  `requestSkillVerification(uint256 _sbtId, bytes _proofData)`: Initiates a request to the simulated AI oracle for verification of the specified SBT's attestation, sending relevant proof data.
7.  `callback_VerifySkill(uint256 _sbtId, bool _isVerified, int256 _reputationDelta)`: (Only AI Oracle) A callback function invoked by the trusted AI oracle to provide the verification result for an SBT and a corresponding reputation adjustment for the SBT holder.
8.  `setAIOracleAddress(address _oracleAddress)`: (Admin) Sets the address of the trusted AI Oracle contract that will provide verification callbacks.
9.  `updateAIOracleConfiguration(bytes32 _configKey, uint256 _value)`: (Admin) Allows the owner to update specific configuration parameters for the AI oracle interaction, e.g., verification thresholds or costs.
10. `getSkillDetails(uint256 _skillId)`: (View) Retrieves the name, description, and validity duration of a skill defined in the system.
11. `getSBTHolderStatus(uint256 _sbtId)`: (View) Returns detailed information about a specific SBT, including its holder, skill ID, issuance/expiration dates, and verification status.
12. `getReputationScore(address _user)`: (View) Returns the current on-chain reputation score of a given user address.
13. `decayReputation(address _user, uint256 _amount)`: (Admin/Trusted) Decreases a user's reputation score by a specified `_amount`. This could be used for periodic decay or as a penalty.
14. `delegateVerificationPower(address _delegatee)`: Allows a user to delegate their authority to attest to or verify skills to another address. The delegatee can then act on behalf of the delegator.
15. `revokeVerificationPower()`: Revokes an active verification delegation, restoring the attestation power to the original delegator.
16. `getVerificationDelegatee(address _delegator)`: (View) Returns the address to whom a given delegator has assigned their verification power, if any.
17. `isQualifiedForAttestation(address _potentialAttester, uint256 _requiredReputation, uint256 _requiredSkillId)`: (View) Checks if an address (or its delegatee) meets the minimum reputation and holds a specified skill necessary to act as a qualified attester for a given skill.
18. `accessQualifiedResource(uint256 _requiredSkillId, uint256 _minReputation)`: A demonstration function that can only be called by users who possess a specific SBT and meet a minimum reputation score, showcasing conditional access.
19. `distributePerformanceReward(address _recipient, uint256 _amount, uint256 _requiredSkillId)`: (Admin/Trusted) Distributes a reward (in native currency, ETH) from the contract's balance to a recipient, provided they hold the specified `_requiredSkillId` SBT.
20. `proposeAdaptiveGovernanceAction(string _proposalHash, uint256 _requiredSkillId, uint256 _minReputation)`: (Conceptual) A placeholder function demonstrating how only users with specific skills and reputation could propose actions within a DAO integrated with this system.
21. `sponsorUserTransaction(address _user, bytes _functionCallData, uint256 _sponsorshipValue)`: (Conceptual) Allows a sponsor to designate funds to cover the gas costs for a specific user's transaction if certain (off-chain or on-chain) conditions are met. *Note: True meta-transactions require an off-chain relayer service; this function implements the on-chain funding and permissioning logic.*
22. `updateAttesterThreshold(uint256 _newThreshold)`: (Admin) Sets the global minimum reputation score required for any address to be considered eligible to attest to skills.
23. `batchUpdateReputation(address[] calldata _users, int256[] calldata _deltas)`: (Admin/Trusted) Allows for efficient bulk adjustments of multiple users' reputation scores.
24. `withdrawContractBalance(address _to, uint256 _amount)`: (Admin) Enables the owner to withdraw native currency (ETH) from the contract's balance to a specified address.
25. `pause()`: (Admin) Pauses the contract, preventing most state-changing operations. Essential for maintenance or emergency situations.
26. `unpause()`: (Admin) Unpauses the contract, resuming normal operations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors for better revert messages and gas efficiency
error InvalidSkillId();
error SkillAlreadyDefined();
error SBTHasNoHolder();
error SBTNotFound();
error SBTNotActive();
error SBTExpired();
error NotQualifiedAttester();
error NotOriginalAttester();
error AttestationNotVerified();
error AttestationAlreadyVerified();
error ZeroAddressNotAllowed();
error DelegationAlreadyExists();
error NoActiveDelegation();
error InsufficientReputation();
error InsufficientFunds();
error OnlyAIOracle();
error InvalidSponsorshipAmount();
error SponsorshipFailed();
error Unauthorized();
error ReputationDecayTooHigh();

/**
 * @title AuraGenesisNexus
 * @dev A decentralized Skill and Reputation Registry using Soulbound Tokens (SBTs),
 *      simulated AI Oracle integration, dynamic reputation, liquid delegation,
 *      and conditional access.
 */
contract AuraGenesisNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Structs ---

    /**
     * @dev Represents a defined skill type within the Nexus.
     * @param name The human-readable name of the skill.
     * @param description A brief description of the skill.
     * @param validityDurationSeconds The duration (in seconds) an SBT for this skill is valid after issuance.
     * @param isDefined Flag to check if the skill ID is actually used.
     */
    struct Skill {
        string name;
        string description;
        uint256 validityDurationSeconds;
        bool isDefined;
    }

    /**
     * @dev Represents a Soulbound Token (SBT) for a specific skill attestation.
     *      These tokens are non-transferable.
     * @param holder The address holding this SBT.
     * @param skillId The ID of the skill this SBT represents.
     * @param issuanceTimestamp The Unix timestamp when the SBT was issued.
     * @param expirationTimestamp The Unix timestamp when the SBT expires.
     * @param attester The address that originally attested to this skill.
     * @param attestationProofUri URI pointing to off-chain proof (e.g., IPFS hash).
     * @param isVerifiedByOracle True if the skill attestation has been verified by the AI oracle.
     * @param isActive True if the SBT is currently active (not revoked, not expired).
     */
    struct SkillBoundToken {
        address holder;
        uint256 skillId;
        uint256 issuanceTimestamp;
        uint256 expirationTimestamp;
        address attester;
        string attestationProofUri;
        bool isVerifiedByOracle;
        bool isActive;
    }

    /**
     * @dev Represents a conceptual meta-transaction sponsorship.
     * @param sponsor The address that provided the sponsorship.
     * @param targetUser The user whose transaction is being sponsored.
     * @param sponsoredValue The amount of ETH sponsored for gas.
     * @param functionCallHash Keccak256 hash of the intended function call data.
     * @param timestamp The time of sponsorship.
     * @param claimed True if the sponsorship has been (conceptually) claimed.
     */
    struct Sponsorship {
        address sponsor;
        address targetUser;
        uint256 sponsoredValue;
        bytes32 functionCallHash;
        uint256 timestamp;
        bool claimed;
    }


    // --- State Variables ---

    uint256 private nextSbtId; // Counter for unique SBT IDs
    uint256 private nextSkillId; // Counter for unique Skill IDs

    // Skill definitions: skillId => Skill
    mapping(uint256 => Skill) public skills;

    // SkillBoundTokens: sbtId => SkillBoundToken
    mapping(uint256 => SkillBoundToken) public sbts;

    // User reputation scores: address => score
    mapping(address => int256) public reputationScores;

    // Liquid delegation for attestation power: delegator => delegatee
    mapping(address => address) public verificationDelegations;

    // Trusted AI Oracle address
    address public aiOracleAddress;

    // Configuration for AI Oracle interaction (e.g., verification thresholds)
    mapping(bytes32 => uint256) public aiOracleConfig;

    // Minimum reputation score required to be an attester
    uint256 public attesterReputationThreshold;

    // Sponsorships mapping (sponsorshipId => Sponsorship)
    uint256 private nextSponsorshipId;
    mapping(uint256 => Sponsorship) public sponsorships;


    // --- Events ---

    event SkillDefined(uint256 indexed skillId, string name, uint256 validityDuration);
    event SkillBoundTokenIssued(uint256 indexed sbtId, address indexed holder, uint256 indexed skillId, address attester, string attestationProofUri);
    event SkillBoundTokenRevoked(uint256 indexed sbtId, address indexed holder, uint256 indexed skillId);
    event SkillBoundTokenRenewed(uint256 indexed sbtId, address indexed holder, uint256 indexed skillId, string newAttestationProofUri);
    event SkillVerificationRequested(uint256 indexed sbtId, address indexed requester, address indexed aiOracle);
    event SkillVerified(uint256 indexed sbtId, address indexed holder, bool isVerified, int256 reputationDelta);
    event ReputationUpdated(address indexed user, int256 oldScore, int256 newScore, int256 delta);
    event ReputationDecayed(address indexed user, uint256 amount);
    event AIOracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event AIOracleConfigUpdated(bytes32 indexed configKey, uint256 value);
    event VerificationPowerDelegated(address indexed delegator, address indexed delegatee);
    event VerificationPowerRevoked(address indexed delegator);
    event AttesterThresholdUpdated(uint256 newThreshold);
    event ResourceAccessed(address indexed user, uint256 skillId, uint256 minReputation);
    event PerformanceRewardDistributed(address indexed recipient, uint256 amount, uint256 skillId);
    event AdaptiveGovernanceActionProposed(address indexed proposer, string proposalHash);
    event TransactionSponsored(uint256 indexed sponsorshipId, address indexed sponsor, address indexed targetUser, uint256 sponsoredValue, bytes32 functionCallHash);
    event SponsorshipClaimed(uint256 indexed sponsorshipId, address indexed claimant);


    // --- Modifiers ---

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert OnlyAIOracle();
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        nextSbtId = 1; // SBT IDs start from 1
        nextSkillId = 1; // Skill IDs start from 1
        attesterReputationThreshold = 100; // Default minimum reputation for attesters
        nextSponsorshipId = 1; // Sponsorship IDs start from 1
    }

    // --- Core State Management & Utility Functions ---

    /**
     * @dev Sets the address of the trusted AI Oracle contract.
     *      Only callable by the owner.
     * @param _oracleAddress The address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        emit AIOracleAddressSet(aiOracleAddress, _oracleAddress);
        aiOracleAddress = _oracleAddress;
    }

    /**
     * @dev Updates a configuration parameter for AI Oracle interaction.
     *      Only callable by the owner.
     * @param _configKey A bytes32 key representing the configuration parameter.
     * @param _value The new value for the parameter.
     */
    function updateAIOracleConfiguration(bytes32 _configKey, uint256 _value) external onlyOwner {
        aiOracleConfig[_configKey] = _value;
        emit AIOracleConfigUpdated(_configKey, _value);
    }

    /**
     * @dev Updates the minimum reputation score required for an address to be an attester.
     *      Only callable by the owner.
     * @param _newThreshold The new minimum reputation score.
     */
    function updateAttesterThreshold(uint256 _newThreshold) external onlyOwner {
        attesterReputationThreshold = _newThreshold;
        emit AttesterThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Retrieves details of a defined skill.
     * @param _skillId The ID of the skill to retrieve.
     * @return name The name of the skill.
     * @return description The description of the skill.
     * @return validityDurationSeconds The validity duration in seconds.
     */
    function getSkillDetails(uint256 _skillId) external view returns (string memory name, string memory description, uint256 validityDurationSeconds) {
        Skill storage s = skills[_skillId];
        if (!s.isDefined) {
            revert InvalidSkillId();
        }
        return (s.name, s.description, s.validityDurationSeconds);
    }

    /**
     * @dev Retrieves the current status of a specific SBT.
     * @param _sbtId The ID of the SBT to retrieve.
     * @return holder The address holding the SBT.
     * @return skillId The ID of the skill the SBT represents.
     * @return issuanceTimestamp The timestamp when the SBT was issued.
     * @return expirationTimestamp The timestamp when the SBT expires.
     * @return attester The address of the original attester.
     * @return attestationProofUri The URI pointing to the off-chain proof.
     * @return isVerified True if the SBT has been verified by the oracle.
     * @return isActive True if the SBT is currently active.
     */
    function getSBTHolderStatus(uint256 _sbtId)
        external
        view
        returns (
            address holder,
            uint256 skillId,
            uint256 issuanceTimestamp,
            uint256 expirationTimestamp,
            address attester,
            string memory attestationProofUri,
            bool isVerified,
            bool isActive
        )
    {
        SkillBoundToken storage sbt = sbts[_sbtId];
        if (sbt.holder == address(0)) {
            revert SBTNotFound();
        }
        return (
            sbt.holder,
            sbt.skillId,
            sbt.issuanceTimestamp,
            sbt.expirationTimestamp,
            sbt.attester,
            sbt.attestationProofUri,
            sbt.isVerifiedByOracle,
            sbt.isActive && (sbt.expirationTimestamp == 0 || block.timestamp <= sbt.expirationTimestamp)
        );
    }

    // --- Skill Definition & Attestation ---

    /**
     * @dev Allows the owner to define a new skill type.
     * @param _name The name of the skill.
     * @param _description A description of the skill.
     * @param _validityDurationSeconds The duration (in seconds) an SBT for this skill is valid.
     */
    function defineSkill(string calldata _name, string calldata _description, uint256 _validityDurationSeconds) external onlyOwner whenNotPaused {
        if (bytes(_name).length == 0) {
            revert InvalidSkillId(); // Using this error to signify invalid input for skill creation too
        }

        uint256 newSkillId = nextSkillId++;
        skills[newSkillId] = Skill({
            name: _name,
            description: _description,
            validityDurationSeconds: _validityDurationSeconds,
            isDefined: true
        });
        emit SkillDefined(newSkillId, _name, _validityDurationSeconds);
    }

    /**
     * @dev Issues a non-transferable Skill-Bound Token (SBT) to a recipient.
     *      The caller (or their delegatee) becomes the attester.
     * @param _recipient The address to receive the SBT.
     * @param _skillId The ID of the skill being attested.
     * @param _attestationProofUri URI pointing to off-chain proof (e.g., IPFS hash).
     */
    function attestSkill(address _recipient, uint256 _skillId, string calldata _attestationProofUri) external whenNotPaused {
        if (_recipient == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        Skill storage skill = skills[_skillId];
        if (!skill.isDefined) {
            revert InvalidSkillId();
        }

        // Determine the effective attester (caller or their delegatee)
        address effectiveAttester = verificationDelegations[msg.sender];
        if (effectiveAttester == address(0)) { // If no delegation, caller is attester
            effectiveAttester = msg.sender;
        }

        // Check if the effective attester is qualified
        if (reputationScores[effectiveAttester] < int256(attesterReputationThreshold)) {
            revert NotQualifiedAttester();
        }
        // In a more complex system, one might also check if the attester has specific skills for attestation.
        // E.g., isQualifiedForAttestation(effectiveAttester, attesterReputationThreshold, SOME_ATTESTER_SKILL_ID);

        uint256 newSbtId = nextSbtId++;
        uint256 issuanceTime = block.timestamp;
        uint256 expirationTime = skill.validityDurationSeconds == 0 ? 0 : issuanceTime + skill.validityDurationSeconds;

        sbts[newSbtId] = SkillBoundToken({
            holder: _recipient,
            skillId: _skillId,
            issuanceTimestamp: issuanceTime,
            expirationTimestamp: expirationTime,
            attester: effectiveAttester,
            attestationProofUri: _attestationProofUri,
            isVerifiedByOracle: false, // Will be verified by oracle callback
            isActive: true
        });

        emit SkillBoundTokenIssued(newSbtId, _recipient, _skillId, effectiveAttester, _attestationProofUri);
    }

    /**
     * @dev Revokes an existing SBT. Can be called by the original attester or the contract owner.
     * @param _sbtId The ID of the SBT to revoke.
     */
    function revokeSkillAttestation(uint256 _sbtId) external whenNotPaused {
        SkillBoundToken storage sbt = sbts[_sbtId];
        if (sbt.holder == address(0)) {
            revert SBTNotFound();
        }
        if (!sbt.isActive) {
            revert SBTNotActive();
        }

        // Only original attester or owner can revoke
        if (msg.sender != sbt.attester && msg.sender != owner()) {
            revert NotOriginalAttester();
        }

        sbt.isActive = false; // Mark as inactive
        // Optionally, reduce reputation of holder/attester if revocation implies misconduct
        // updateReputation(sbt.holder, -50); // Example: penalty
        emit SkillBoundTokenRevoked(_sbtId, sbt.holder, sbt.skillId);
    }

    /**
     * @dev Allows the SBT holder to renew an expiring skill.
     *      Requires new proof and potentially triggers re-verification.
     * @param _sbtId The ID of the SBT to renew.
     * @param _newAttestationProofUri New URI pointing to updated off-chain proof.
     */
    function renewSkillAttestation(uint256 _sbtId, string calldata _newAttestationProofUri) external whenNotPaused {
        SkillBoundToken storage sbt = sbts[_sbtId];
        if (sbt.holder == address(0)) {
            revert SBTNotFound();
        }
        if (sbt.holder != msg.sender) { // Only holder can renew their own SBT
            revert Unauthorized();
        }
        if (!sbt.isActive) { // Must be active or recently expired
            if (sbt.expirationTimestamp != 0 && block.timestamp > sbt.expirationTimestamp + 7 days) { // Grace period, e.g., 7 days
                revert SBTExpired(); // Too long after expiration
            }
        }

        Skill storage skill = skills[sbt.skillId];
        if (!skill.isDefined) {
            revert InvalidSkillId(); // Skill definition somehow lost (shouldn't happen)
        }

        // Update timestamps and proof
        sbt.issuanceTimestamp = block.timestamp;
        sbt.expirationTimestamp = skill.validityDurationSeconds == 0 ? 0 : block.timestamp + skill.validityDurationSeconds;
        sbt.attestationProofUri = _newAttestationProofUri;
        sbt.isVerifiedByOracle = false; // Reset verification status, requires re-verification
        sbt.isActive = true; // Ensure it's active again

        emit SkillBoundTokenRenewed(_sbtId, msg.sender, sbt.skillId, _newAttestationProofUri);

        // Optionally, automatically request re-verification
        // requestSkillVerification(_sbtId, abi.encodePacked(_newAttestationProofUri));
    }


    // --- AI Oracle Integration (Simulated) ---

    /**
     * @dev Initiates a request to the AI oracle for skill verification.
     *      Only callable by the SBT holder.
     * @param _sbtId The ID of the SBT to verify.
     * @param _proofData Additional data/params for the oracle to use for verification.
     */
    function requestSkillVerification(uint256 _sbtId, bytes calldata _proofData) external whenNotPaused nonReentrant {
        SkillBoundToken storage sbt = sbts[_sbtId];
        if (sbt.holder == address(0)) {
            revert SBTNotFound();
        }
        if (sbt.holder != msg.sender) {
            revert Unauthorized();
        }
        if (sbt.isVerifiedByOracle) {
            revert AttestationAlreadyVerified(); // Already verified
        }
        if (!sbt.isActive || (sbt.expirationTimestamp != 0 && block.timestamp > sbt.expirationTimestamp)) {
            revert SBTNotActive(); // Cannot verify inactive or expired SBTs
        }
        if (aiOracleAddress == address(0)) {
            revert OnlyAIOracle(); // Oracle not set, using this error to hint at config
        }

        // In a real scenario, this would be an external call to an oracle network (e.g., Chainlink request)
        // For this example, we simulate a direct callback.
        // uint256 verificationCost = aiOracleConfig["verification_cost"]; // Example of using config
        // require(msg.value >= verificationCost, "Insufficient payment for verification.");

        // Simulate immediate callback for demonstration purposes. In real life, it would be asynchronous.
        // callback_VerifySkill(_sbtId, true, 50); // For demonstration, assume verified and add 50 reputation

        emit SkillVerificationRequested(_sbtId, msg.sender, aiOracleAddress);
    }

    /**
     * @dev Callback function from the trusted AI Oracle to provide verification results.
     *      Only callable by the designated AI Oracle address.
     * @param _sbtId The ID of the SBT that was verified.
     * @param _isVerified True if the attestation was verified successfully, false otherwise.
     * @param _reputationDelta The amount to change the holder's reputation score by.
     */
    function callback_VerifySkill(uint256 _sbtId, bool _isVerified, int256 _reputationDelta) external onlyAIOracle whenNotPaused nonReentrant {
        SkillBoundToken storage sbt = sbts[_sbtId];
        if (sbt.holder == address(0)) {
            revert SBTNotFound();
        }
        if (sbt.isVerifiedByOracle) { // Prevent re-verifying
            revert AttestationAlreadyVerified();
        }
        if (!sbt.isActive) { // Cannot verify inactive SBTs
            revert SBTNotActive();
        }

        sbt.isVerifiedByOracle = _isVerified;

        if (_isVerified) {
            // Update reputation based on verification outcome
            _updateReputation(sbt.holder, _reputationDelta);
        } else {
            // Optionally, penalize for failed verification
            _updateReputation(sbt.holder, -int256(aiOracleConfig["failed_verification_penalty"]));
        }

        emit SkillVerified(_sbtId, sbt.holder, _isVerified, _reputationDelta);
    }


    // --- Reputation System ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address of the user.
     * @param _delta The amount to change the reputation score by (can be positive or negative).
     */
    function _updateReputation(address _user, int256 _delta) internal {
        int256 oldScore = reputationScores[_user];
        int256 newScore = oldScore + _delta;

        // Ensure reputation doesn't go below zero (or a minimum threshold)
        if (newScore < 0) {
            newScore = 0;
        }

        reputationScores[_user] = newScore;
        emit ReputationUpdated(_user, oldScore, newScore, _delta);
    }

    /**
     * @dev Allows for periodic or event-based decay of a user's reputation score.
     *      Callable by the owner or a designated trusted role.
     * @param _user The address of the user whose reputation will decay.
     * @param _amount The amount by which the reputation score will decrease.
     */
    function decayReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        if (_user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_amount == 0) {
            return; // No decay
        }
        if (reputationScores[_user] < int256(_amount)) {
            // Ensure score doesn't become negative due to decay
            _amount = uint256(reputationScores[_user]);
        }
        _updateReputation(_user, -int256(_amount));
        emit ReputationDecayed(_user, _amount);
    }

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getReputationScore(address _user) external view returns (int256) {
        return reputationScores[_user];
    }


    // --- Liquid Verification Delegation ---

    /**
     * @dev Allows a user to delegate their ability to attest to or verify skills to another address.
     * @param _delegatee The address to delegate verification power to.
     */
    function delegateVerificationPower(address _delegatee) external whenNotPaused {
        if (_delegatee == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (verificationDelegations[msg.sender] != address(0)) {
            revert DelegationAlreadyExists();
        }
        verificationDelegations[msg.sender] = _delegatee;
        emit VerificationPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes an active verification delegation, restoring power to the original delegator.
     */
    function revokeVerificationPower() external whenNotPaused {
        if (verificationDelegations[msg.sender] == address(0)) {
            revert NoActiveDelegation();
        }
        delete verificationDelegations[msg.sender];
        emit VerificationPowerRevoked(msg.sender);
    }

    /**
     * @dev Returns the address a user has delegated their verification power to.
     * @param _delegator The address of the delegator.
     * @return The address of the delegatee, or address(0) if no delegation exists.
     */
    function getVerificationDelegatee(address _delegator) external view returns (address) {
        return verificationDelegations[_delegator];
    }

    /**
     * @dev Checks if an address (or its delegatee) meets the criteria to act as a qualified attester.
     * @param _potentialAttester The address to check.
     * @param _requiredReputation The minimum reputation score required.
     * @param _requiredSkillId An optional skill ID required (0 if no specific skill needed).
     * @return True if qualified, false otherwise.
     */
    function isQualifiedForAttestation(address _potentialAttester, uint256 _requiredReputation, uint256 _requiredSkillId) external view returns (bool) {
        address actualAttester = verificationDelegations[_potentialAttester];
        if (actualAttester == address(0)) {
            actualAttester = _potentialAttester; // No delegation, check self
        }

        if (reputationScores[actualAttester] < int256(_requiredReputation)) {
            return false;
        }

        if (_requiredSkillId != 0) {
            bool hasRequiredSkill = false;
            // Iterate through all SBTs (inefficient for many, but for a concept it's ok)
            // In a real system, would use a mapping like mapping(address => mapping(uint256 => uint256[])) public userSBTs;
            // or an ERC-721 enumerable extension if it were a full NFT.
            for (uint256 i = 1; i < nextSbtId; i++) {
                SkillBoundToken storage sbt = sbts[i];
                if (sbt.holder == actualAttester && sbt.skillId == _requiredSkillId && sbt.isActive && sbt.isVerifiedByOracle) {
                    if (sbt.expirationTimestamp == 0 || block.timestamp <= sbt.expirationTimestamp) {
                        hasRequiredSkill = true;
                        break;
                    }
                }
            }
            if (!hasRequiredSkill) {
                return false;
            }
        }
        return true;
    }


    // --- Access Control & Conditional Execution ---

    /**
     * @dev A demonstration function that can only be called by users
     *      who possess a specific SBT and meet a minimum reputation score.
     * @param _requiredSkillId The skill ID required to call this function.
     * @param _minReputation The minimum reputation score required.
     */
    function accessQualifiedResource(uint256 _requiredSkillId, uint256 _minReputation) external view whenNotPaused {
        if (!isQualifiedForAttestation(msg.sender, _minReputation, _requiredSkillId)) {
            revert InsufficientReputation(); // Using this to broadly indicate not qualified
        }
        // Logic for accessing the qualified resource goes here
        emit ResourceAccessed(msg.sender, _requiredSkillId, _minReputation);
    }

    /**
     * @dev Distributes a reward (in native currency, ETH) from the contract's balance
     *      to a recipient, provided they hold the specified `_requiredSkillId` SBT.
     * @param _recipient The address to receive the reward.
     * @param _amount The amount of native currency to distribute.
     * @param _requiredSkillId The skill ID the recipient must hold.
     */
    function distributePerformanceReward(address _recipient, uint256 _amount, uint256 _requiredSkillId) external onlyOwner whenNotPaused nonReentrant {
        if (_recipient == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (address(this).balance < _amount) {
            revert InsufficientFunds();
        }

        // Check if recipient holds the required skill and is verified
        bool hasSkill = false;
        for (uint256 i = 1; i < nextSbtId; i++) {
            SkillBoundToken storage sbt = sbts[i];
            if (sbt.holder == _recipient && sbt.skillId == _requiredSkillId && sbt.isActive && sbt.isVerifiedByOracle) {
                if (sbt.expirationTimestamp == 0 || block.timestamp <= sbt.expirationTimestamp) {
                    hasSkill = true;
                    break;
                }
            }
        }

        if (!hasSkill) {
            revert Unauthorized(); // Recipient does not have the required skill
        }

        (bool success,) = _recipient.call{value: _amount}("");
        if (!success) {
            revert SponsorshipFailed(); // Using this for failed transfer
        }
        emit PerformanceRewardDistributed(_recipient, _amount, _requiredSkillId);
    }

    /**
     * @dev A conceptual function demonstrating how only users with specific skills and reputation
     *      could propose actions within a DAO integrated with this system.
     * @param _proposalHash A hash of the proposal details (e.g., IPFS hash).
     * @param _requiredSkillId The skill ID required to propose.
     * @param _minReputation The minimum reputation score required.
     */
    function proposeAdaptiveGovernanceAction(string calldata _proposalHash, uint256 _requiredSkillId, uint256 _minReputation) external whenNotPaused {
        if (!isQualifiedForAttestation(msg.sender, _minReputation, _requiredSkillId)) {
            revert InsufficientReputation(); // User not qualified to propose
        }
        // In a real DAO, this would interact with a governance module
        emit AdaptiveGovernanceActionProposed(msg.sender, _proposalHash);
    }

    // --- Meta-Transaction Sponsorship (Conceptual) ---

    /**
     * @dev Allows a sponsor to designate funds to cover the gas costs for a specific user's transaction.
     *      This function records the sponsorship; true execution requires an off-chain relayer.
     * @param _user The address of the user whose transaction is to be sponsored.
     * @param _functionCallData The encoded call data of the function to be sponsored.
     * @param _sponsorshipValue The amount of ETH the sponsor is providing for gas.
     */
    function sponsorUserTransaction(address _user, bytes calldata _functionCallData, uint256 _sponsorshipValue) external payable whenNotPaused {
        if (_user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_sponsorshipValue == 0) {
            revert InvalidSponsorshipAmount();
        }
        if (msg.value < _sponsorshipValue) {
            revert InsufficientFunds();
        }

        // In a real system, you might add conditions here for who can be sponsored,
        // e.g., only new users, users with certain low reputation but high skill, etc.
        // For example:
        // if (reputationScores[_user] > 500) { revert("User too high reputation for sponsorship."); }

        uint256 newSponsorshipId = nextSponsorshipId++;
        sponsorships[newSponsorshipId] = Sponsorship({
            sponsor: msg.sender,
            targetUser: _user,
            sponsoredValue: _sponsorshipValue,
            functionCallHash: keccak256(_functionCallData), // Hash to match against later
            timestamp: block.timestamp,
            claimed: false
        });

        // Any excess ETH sent beyond _sponsorshipValue is returned to sender
        if (msg.value > _sponsorshipValue) {
            (bool success, ) = msg.sender.call{value: msg.value - _sponsorshipValue}("");
            if (!success) {
                revert SponsorshipFailed(); // Return failed
            }
        }
        emit TransactionSponsored(newSponsorshipId, msg.sender, _user, _sponsorshipValue, keccak256(_functionCallData));
    }

    /**
     * @dev CONCEPTUAL: This function would be called by an off-chain relayer
     *      after verifying the user's signed meta-transaction.
     *      It would consume the sponsorship and execute the function call.
     *      For this example, it only marks a sponsorship as claimed.
     * @param _sponsorshipId The ID of the sponsorship to claim.
     * @param _claimedBy The address claiming the sponsorship (typically the relayer).
     */
    function claimSponsorship(uint256 _sponsorshipId, address _claimedBy) external onlyOwner { // Only owner can simulate claiming
        Sponsorship storage sp = sponsorships[_sponsorshipId];
        if (sp.sponsor == address(0)) {
            revert SBTNotFound(); // Using SBTNotFound broadly for non-existent ID
        }
        if (sp.claimed) {
            revert SponsorshipFailed(); // Already claimed
        }

        sp.claimed = true;
        // In a real meta-tx setup, relayer would actually execute the call here
        // (bool success, ) = sp.targetUser.call(abi.encodeCall(targetFunction, params));
        // then send the sponsoredValue to the relayer to cover gas.

        emit SponsorshipClaimed(_sponsorshipId, _claimedBy);
    }


    // --- Administrative & Utility Functions ---

    /**
     * @dev Allows for batch updates to multiple users' reputation scores.
     *      Callable by the owner or a designated trusted role.
     * @param _users An array of user addresses.
     * @param _deltas An array of reputation changes corresponding to _users.
     */
    function batchUpdateReputation(address[] calldata _users, int256[] calldata _deltas) external onlyOwner whenNotPaused {
        if (_users.length != _deltas.length) {
            revert InvalidSkillId(); // Using this error for array length mismatch
        }
        for (uint256 i = 0; i < _users.length; i++) {
            _updateReputation(_users[i], _deltas[i]);
        }
    }

    /**
     * @dev Allows the owner to withdraw native currency (ETH) from the contract's balance.
     * @param _to The address to send the funds to.
     * @param _amount The amount of native currency to withdraw.
     */
    function withdrawContractBalance(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_to == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (address(this).balance < _amount) {
            revert InsufficientFunds();
        }
        (bool success,) = _to.call{value: _amount}("");
        if (!success) {
            revert SponsorshipFailed(); // Using this for failed transfer
        }
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Only callable by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     *      Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```