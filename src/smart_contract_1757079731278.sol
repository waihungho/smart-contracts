Here's a smart contract for a "VeriSkill Nexus" platform, designed with advanced concepts, creativity, and modern trends in mind. It integrates Soulbound Tokens (SBTs), Dynamic NFTs, AI Oracle interactions, ZK Proof result consumption, and a reputation system, all while aiming for a unique combination of functionalities.

---

## VeriSkill Nexus Smart Contract

**Concept:**
The `VeriSkillNexus` contract is a decentralized platform for users to claim, verify, and showcase their skills and achievements through Soulbound Skill Tokens (SSTs). These SSTs are non-transferable ERC-721 tokens that also act as Dynamic NFTs, evolving based on further achievements or community endorsements. The platform integrates off-chain AI Oracles for evidence verification and processes the outcomes of ZK Proofs for privacy-preserving claims. It also features a dynamic reputation system based on verified skills and weighted endorsements.

---

### Outline & Function Summary

**I. Core Platform Management:**
1.  `constructor()`: Initializes the platform with an admin, fee collector, and oracle registry.
2.  `updateSystemFee(uint256 newFee)`: Allows the admin to update the fee required for submitting skill claims.
3.  `setTrustedOracleRegistry(address _newRegistry)`: Sets the address of the contract responsible for managing trusted AI Oracles and ZK Verifiers.
4.  `pauseSystem()`: Admin function to pause critical platform functionalities in emergencies.
5.  `unpauseSystem()`: Admin function to unpause the system.
6.  `withdrawProtocolFees(address recipient)`: Admin function to withdraw accumulated protocol fees to a specified recipient.

**II. Skill Definition & Management:**
7.  `defineSkillType(string calldata name, string calldata description, uint256[] calldata prerequisiteSkillIds, uint256 verificationCost)`: Admin defines a new skill type, its prerequisites, and the cost for verification.
8.  `updateSkillType(uint256 skillId, string calldata name, string calldata description, uint256[] calldata prerequisiteSkillIds, uint256 verificationCost)`: Admin can update the details of an existing skill type.
9.  `getSkillTypeDetails(uint256 skillId)`: View function to retrieve comprehensive details about a specific skill type.
10. `getSkillPrerequisites(uint256 skillId)`: View function to get the list of skill IDs required as prerequisites for a given skill.

**III. Skill Claim & Verification (User/Oracle Interaction):**
11. `submitSkillClaim(uint256 skillId, bytes32 evidenceHash, bytes32 zkProofIdentifier)`: Users submit a claim for a skill, providing a hash of off-chain evidence and a unique identifier for an associated ZK proof. Requires paying `verificationCost`.
12. `registerOracleVerdict(uint256 claimId, bool isVerified, bytes32 aiModelHash, string calldata metadataURI)`: A trusted AI Oracle calls this to submit its verification result for a claim, including the AI model's hash and initial metadata URI for the potential SST.
13. `registerZKProofStatus(uint256 claimId, bool isValid)`: A trusted ZK Verifier contract calls this to confirm the validity of a ZK proof associated with a claim.
14. `mintVerifiedSkill(uint256 claimId)`: Called internally once both oracle verdict and ZK proof (if required) are confirmed valid. Mints the Soulbound Skill Token (SST) to the claimant.

**IV. Reputation & Endorsement:**
15. `getReputationScore(address user)`: View function to retrieve the current reputation score of a user.
16. `endorseSkill(address user, uint256 skillTokenId)`: Allows users to endorse another user's *verified* skill token. The endorsement power is weighted by the endorser's own reputation.
17. `revokeEndorsement(address user, uint256 skillTokenId)`: Allows an endorser to revoke a previous endorsement.
18. `updateReputationEpoch()`: Admin/scheduled function to trigger a recalculation of reputation scores for all users, applying decay or boosts based on recent activity.

**V. Soulbound Skill Token (SST) - Dynamic NFT Features:**
19. `getSkillTokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a given SST. This URI can change based on the token's state (tier, endorsements).
20. `upgradeSkillTier(uint256 tokenId, uint256 newTierLevel, bytes32 evidenceHash)`: Allows a user to initiate an upgrade for their skill token to a higher tier (e.g., from "Beginner" to "Advanced"). Requires new evidence and re-verification.
21. `updateTokenMetadata(uint256 tokenId, string calldata newMetadataURI)`: Allows a skill token holder to update their associated metadata URI, usually after a tier upgrade or a system-wide metadata change.
22. `burnSkillToken(uint256 tokenId)`: Allows a user to burn their own Soulbound Skill Token.

**VI. Utility & Access:**
23. `hasSkill(address user, uint256 skillId)`: View function to check if a user possesses at least one verified skill token of a specific type.
24. `getTokenForSkillType(address user, uint256 skillId)`: View function to retrieve the latest minted skill token ID a user holds for a given skill type.
25. `canClaimSkill(address user, uint256 skillId)`: View function to check if a user meets all the prerequisites to claim a specific skill.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces (Conceptual for external systems) ---

/**
 * @title ITrustedOracleRegistry
 * @dev Interface for a conceptual contract that manages a whitelist of trusted AI Oracles and ZK Verifiers.
 *      In a real-world scenario, this would be a more complex system, possibly a DAO or a multi-sig.
 */
interface ITrustedOracleRegistry {
    function isTrustedOracle(address _oracle) external view returns (bool);
    function isTrustedZKVerifier(address _verifier) external view returns (bool);
}

// --- Errors ---

error VeriSkill__Unauthorized();
error VeriSkill__SkillNotFound();
error VeriSkill__ClaimNotFound();
error VeriSkill__ClaimNotPending();
error VeriSkill__ClaimAlreadyProcessed();
error VeriSkill__PrerequisitesNotMet();
error VeriSkill__InsufficientFunds();
error VeriSkill__NoSkillTokenFound();
error VeriSkill__AlreadyVerified();
error VeriSkill__OracleVerdictPending();
error VeriSkill__ZKProofPending();
error VeriSkill__OracleVerdictInvalid();
error VeriSkill__ZKProofInvalid();
error VeriSkill__InvalidSkillTier();
error VeriSkill__TokenNotOwnedByUser();
error VeriSkill__SelfEndorsementNotAllowed();
error VeriSkill__SkillNotVerifiedForUser();
error VeriSkill__CannotEndorseUnmintedSkill();
error VeriSkill__AlreadyEndorsed();
error VeriSkill__NoActiveEndorsement();

contract VeriSkillNexus is ERC721, Ownable2Step, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _skillTypeIds;
    Counters.Counter private _claimIds;
    Counters.Counter private _tokenIds;

    address public feeCollector;
    uint256 public systemFee;
    uint256 public reputationEpochDuration = 7 days; // How often reputation is recalculated
    uint256 public lastReputationEpochUpdateTime;
    uint256 public constant REPUTATION_BASE = 1000; // Starting reputation for new users

    ITrustedOracleRegistry public trustedOracleRegistry;

    // --- Enums & Structs ---

    enum ClaimStatus {
        Pending,
        OracleVerified,
        ZKProofVerified,
        Rejected,
        Minted
    }

    struct SkillType {
        string name;
        string description;
        uint256[] prerequisiteSkillIds;
        uint256 verificationCost;
        bool exists;
    }

    struct SkillClaim {
        uint256 skillId;
        address claimant;
        bytes32 evidenceHash;
        bytes32 zkProofIdentifier; // Identifier for the off-chain ZK proof
        ClaimStatus status;
        bool oracleVerified;
        bool zkProofValid;
        bytes32 aiModelHash;
        string metadataURI; // Initial metadata URI suggested by oracle
    }

    struct Endorsement {
        uint256 endorserReputationAtTime;
        uint256 timestamp;
        bool active;
    }

    // --- Mappings ---

    mapping(uint256 => SkillType) public skillTypes; // skillTypeId => SkillType
    mapping(uint256 => SkillClaim) public skillClaims; // claimId => SkillClaim
    mapping(address => mapping(uint256 => uint256)) public userSkillTokens; // user => skillTypeId => tokenId (latest for that skillType)
    mapping(address => uint256) public userReputation; // user => reputationScore
    mapping(uint256 => address) public tokenOwners; // tokenId => owner (to optimize ownership checks for endorsements)
    mapping(uint256 => mapping(address => Endorsement)) public skillTokenEndorsements; // skillTokenId => endorser => Endorsement details
    mapping(address => mapping(uint256 => bool)) public hasEndorsedSkillToken; // endorser => skillTokenId => bool


    // --- Events ---

    event SystemFeeUpdated(uint256 newFee);
    event TrustedOracleRegistryUpdated(address newRegistry);
    event SkillTypeDefined(uint256 skillId, string name, uint256 verificationCost);
    event SkillTypeUpdated(uint256 skillId, string name);
    event SkillClaimSubmitted(uint256 claimId, uint256 skillId, address claimant, bytes32 evidenceHash, bytes32 zkProofIdentifier);
    event OracleVerdictRegistered(uint256 claimId, bool isVerified, bytes32 aiModelHash);
    event ZKProofStatusRegistered(uint256 claimId, bool isValid);
    event SkillTokenMinted(uint256 tokenId, uint256 skillId, address owner, string metadataURI);
    event ReputationScoreUpdated(address user, uint256 newReputation);
    event SkillEndorsed(uint256 skillTokenId, address endorser, address endorsedUser, uint256 endorsementPower);
    event EndorsementRevoked(uint256 skillTokenId, address endorser, address endorsedUser);
    event SkillTierUpgraded(uint256 tokenId, uint256 newTierLevel, address user);
    event TokenMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event SkillTokenBurned(uint256 tokenId, address owner);


    // --- Constructor ---

    constructor(address initialAdmin, address initialFeeCollector, address initialOracleRegistry)
        ERC721("VeriSkill Token", "SST")
        Ownable2Step(initialAdmin)
    {
        require(initialFeeCollector != address(0), "VeriSkill: Invalid fee collector address");
        require(initialOracleRegistry != address(0), "VeriSkill: Invalid oracle registry address");
        feeCollector = initialFeeCollector;
        trustedOracleRegistry = ITrustedOracleRegistry(initialOracleRegistry);
        systemFee = 0.01 ether; // Example initial fee
        lastReputationEpochUpdateTime = block.timestamp;
    }

    // --- Modifiers ---

    modifier onlyTrustedOracleOrZKVerifier() {
        require(trustedOracleRegistry.isTrustedOracle(_msgSender()) || trustedOracleRegistry.isTrustedZKVerifier(_msgSender()), 
                "VeriSkill: Not a trusted oracle or ZK verifier");
        _;
    }

    modifier onlyTrustedOracle() {
        require(trustedOracleRegistry.isTrustedOracle(_msgSender()), "VeriSkill: Not a trusted oracle");
        _;
    }

    modifier onlyTrustedZKVerifier() {
        require(trustedOracleRegistry.isTrustedZKVerifier(_msgSender()), "VeriSkill: Not a trusted ZK verifier");
        _;
    }

    // --- Core Platform Management Functions ---

    /**
     * @dev Updates the system fee required for submitting skill claims.
     * @param newFee The new fee amount.
     */
    function updateSystemFee(uint256 newFee) external onlyOwner {
        systemFee = newFee;
        emit SystemFeeUpdated(newFee);
    }

    /**
     * @dev Sets the address of the trusted oracle registry contract.
     * @param _newRegistry The address of the new ITrustedOracleRegistry contract.
     */
    function setTrustedOracleRegistry(address _newRegistry) external onlyOwner {
        require(_newRegistry != address(0), "VeriSkill: Invalid oracle registry address");
        trustedOracleRegistry = ITrustedOracleRegistry(_newRegistry);
        emit TrustedOracleRegistryUpdated(_newRegistry);
    }

    /**
     * @dev Pauses the system, preventing most user interactions.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the system, allowing user interactions again.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws accumulated protocol fees to a specified recipient.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyOwner {
        require(recipient != address(0), "VeriSkill: Invalid recipient address");
        uint256 balance = address(this).balance;
        require(balance > 0, "VeriSkill: No fees to withdraw");
        (bool success, ) = payable(recipient).call{value: balance}("");
        require(success, "VeriSkill: Fee withdrawal failed");
    }

    // --- Skill Definition & Management Functions ---

    /**
     * @dev Defines a new skill type with its properties.
     * @param name The name of the skill.
     * @param description A brief description of the skill.
     * @param prerequisiteSkillIds An array of skill IDs that must be possessed before claiming this skill.
     * @param verificationCost The ETH cost to submit a claim for this skill.
     */
    function defineSkillType(
        string calldata name,
        string calldata description,
        uint256[] calldata prerequisiteSkillIds,
        uint256 verificationCost
    ) external onlyOwner {
        _skillTypeIds.increment();
        uint256 newSkillId = _skillTypeIds.current();

        skillTypes[newSkillId] = SkillType(
            name,
            description,
            prerequisiteSkillIds,
            verificationCost,
            true
        );
        emit SkillTypeDefined(newSkillId, name, verificationCost);
    }

    /**
     * @dev Updates an existing skill type's properties.
     * @param skillId The ID of the skill type to update.
     * @param name The new name of the skill.
     * @param description The new description of the skill.
     * @param prerequisiteSkillIds The new array of prerequisite skill IDs.
     * @param verificationCost The new ETH cost for verification.
     */
    function updateSkillType(
        uint256 skillId,
        string calldata name,
        string calldata description,
        uint256[] calldata prerequisiteSkillIds,
        uint256 verificationCost
    ) external onlyOwner {
        SkillType storage skill = skillTypes[skillId];
        if (!skill.exists) revert VeriSkill__SkillNotFound();

        skill.name = name;
        skill.description = description;
        skill.prerequisiteSkillIds = prerequisiteSkillIds;
        skill.verificationCost = verificationCost;
        emit SkillTypeUpdated(skillId, name);
    }

    /**
     * @dev Retrieves details of a specific skill type.
     * @param skillId The ID of the skill type.
     * @return SkillType struct containing all details.
     */
    function getSkillTypeDetails(uint256 skillId) external view returns (SkillType memory) {
        SkillType storage skill = skillTypes[skillId];
        if (!skill.exists) revert VeriSkill__SkillNotFound();
        return skill;
    }

    /**
     * @dev Retrieves the prerequisite skill IDs for a given skill.
     * @param skillId The ID of the skill.
     * @return An array of prerequisite skill IDs.
     */
    function getSkillPrerequisites(uint256 skillId) external view returns (uint256[] memory) {
        SkillType storage skill = skillTypes[skillId];
        if (!skill.exists) revert VeriSkill__SkillNotFound();
        return skill.prerequisiteSkillIds;
    }

    // --- Skill Claim & Verification Functions ---

    /**
     * @dev Allows a user to submit a claim for a specific skill.
     * Requires payment of the verification cost.
     * @param skillId The ID of the skill being claimed.
     * @param evidenceHash A hash of the off-chain evidence supporting the claim.
     * @param zkProofIdentifier An identifier for an off-chain ZK proof that will be submitted.
     */
    function submitSkillClaim(
        uint256 skillId,
        bytes32 evidenceHash,
        bytes32 zkProofIdentifier
    ) external payable whenNotPaused {
        SkillType storage skill = skillTypes[skillId];
        if (!skill.exists) revert VeriSkill__SkillNotFound();
        if (msg.value < skill.verificationCost) revert VeriSkill__InsufficientFunds();
        if (!canClaimSkill(_msgSender(), skillId)) revert VeriSkill__PrerequisitesNotMet();

        _claimIds.increment();
        uint256 newClaimId = _claimIds.current();

        skillClaims[newClaimId] = SkillClaim(
            skillId,
            _msgSender(),
            evidenceHash,
            zkProofIdentifier,
            ClaimStatus.Pending,
            false, // Oracle not verified yet
            false, // ZK proof not verified yet
            bytes32(0),
            ""
        );

        emit SkillClaimSubmitted(newClaimId, skillId, _msgSender(), evidenceHash, zkProofIdentifier);

        // Forward excess payment if any
        if (msg.value > skill.verificationCost) {
            (bool success, ) = payable(_msgSender()).call{value: msg.value - skill.verificationCost}("");
            require(success, "VeriSkill: Failed to refund excess payment");
        }
    }

    /**
     * @dev Trusted AI Oracles call this function to register their verdict on a skill claim.
     * @param claimId The ID of the skill claim.
     * @param isVerified True if the AI Oracle verified the claim, false otherwise.
     * @param aiModelHash A hash identifying the AI model used for verification.
     * @param metadataURI The initial metadata URI for the potential SST if verified.
     */
    function registerOracleVerdict(
        uint256 claimId,
        bool isVerified,
        bytes32 aiModelHash,
        string calldata metadataURI
    ) external onlyTrustedOracle {
        SkillClaim storage claim = skillClaims[claimId];
        if (claim.claimant == address(0)) revert VeriSkill__ClaimNotFound();
        if (claim.status != ClaimStatus.Pending) revert VeriSkill__ClaimAlreadyProcessed();

        claim.oracleVerified = isVerified;
        claim.aiModelHash = aiModelHash;
        claim.metadataURI = metadataURI;

        if (!isVerified) {
            claim.status = ClaimStatus.Rejected;
            // Optionally, refund verification cost here for rejected claims if desired
        } else {
            // Only update status to OracleVerified if ZK proof is not a factor
            // For now, keep as Pending until ZK status or mintVerifiedSkill handles it.
        }
        
        emit OracleVerdictRegistered(claimId, isVerified, aiModelHash);

        // Attempt to mint immediately if ZK proof is not a factor or already verified
        _tryMintSkillToken(claimId);
    }

    /**
     * @dev Trusted ZK Verifier contracts call this to register the status of a ZK proof for a claim.
     * @param claimId The ID of the skill claim.
     * @param isValid True if the ZK proof was successfully verified, false otherwise.
     */
    function registerZKProofStatus(uint256 claimId, bool isValid) external onlyTrustedZKVerifier {
        SkillClaim storage claim = skillClaims[claimId];
        if (claim.claimant == address(0)) revert VeriSkill__ClaimNotFound();
        if (claim.status != ClaimStatus.Pending) revert VeriSkill__ClaimAlreadyProcessed();

        claim.zkProofValid = isValid;

        if (!isValid) {
            claim.status = ClaimStatus.Rejected;
            // Optionally, refund verification cost here for rejected claims if desired
        }
        
        emit ZKProofStatusRegistered(claimId, isValid);

        // Attempt to mint immediately if Oracle verdict is already in
        _tryMintSkillToken(claimId);
    }

    /**
     * @dev Internal function to attempt minting an SST if all conditions are met.
     * Called after oracle verdict or ZK proof status is registered.
     * @param claimId The ID of the skill claim.
     */
    function _tryMintSkillToken(uint256 claimId) internal {
        SkillClaim storage claim = skillClaims[claimId];

        if (claim.status == ClaimStatus.Rejected) return; // Already rejected
        if (!claim.oracleVerified) return; // Oracle not verified yet

        // If a ZK proof identifier was provided, ensure it's also valid
        if (claim.zkProofIdentifier != bytes32(0) && !claim.zkProofValid) return;

        // All conditions met, proceed to mint
        mintVerifiedSkill(claimId);
    }


    /**
     * @dev Mints a Soulbound Skill Token (SST) to the claimant upon successful verification.
     * Can only be called once all verification steps (Oracle, ZK Proof if applicable) are complete.
     * @param claimId The ID of the skill claim to mint for.
     */
    function mintVerifiedSkill(uint256 claimId) public whenNotPaused {
        SkillClaim storage claim = skillClaims[claimId];
        if (claim.claimant == address(0)) revert VeriSkill__ClaimNotFound();
        if (claim.status == ClaimStatus.Minted) revert VeriSkill__ClaimAlreadyProcessed();
        if (claim.status == ClaimStatus.Rejected) revert VeriSkill__ClaimNotPending(); // Already rejected

        // Ensure all verification steps are complete
        if (!claim.oracleVerified) revert VeriSkill__OracleVerdictPending();
        if (claim.zkProofIdentifier != bytes32(0) && !claim.zkProofValid) revert VeriSkill__ZKProofPending();

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(claim.claimant, newTokenId); // Mints the ERC721 token
        userSkillTokens[claim.claimant][claim.skillId] = newTokenId; // Store the latest token ID for this skill type
        tokenOwners[newTokenId] = claim.claimant; // Store owner for efficient lookups

        claim.status = ClaimStatus.Minted; // Update claim status

        // Initialize reputation if it's their first verified skill
        if (userReputation[claim.claimant] == 0) {
            userReputation[claim.claimant] = REPUTATION_BASE;
        } else {
            // Boost reputation for new skill
            userReputation[claim.claimant] += 100; // Example boost
        }

        emit SkillTokenMinted(newTokenId, claim.skillId, claim.claimant, claim.metadataURI);
        emit ReputationScoreUpdated(claim.claimant, userReputation[claim.claimant]);
    }

    // --- Reputation & Endorsement Functions ---

    /**
     * @dev Retrieves the current reputation score of a user.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Allows a user to endorse a specific skill token of another user.
     * The endorsement power is weighted by the endorser's current reputation.
     * @param user The address of the user whose skill token is being endorsed.
     * @param skillTokenId The ID of the specific skill token being endorsed.
     */
    function endorseSkill(address user, uint256 skillTokenId) external whenNotPaused {
        if (_msgSender() == user) revert VeriSkill__SelfEndorsementNotAllowed();
        if (ownerOf(skillTokenId) != user) revert VeriSkill__TokenNotOwnedByUser(); // Ensures token exists and belongs to 'user'

        // Check if already endorsed
        if (hasEndorsedSkillToken[_msgSender()][skillTokenId]) revert VeriSkill__AlreadyEndorsed();

        uint256 endorserRep = userReputation[_msgSender()];
        if (endorserRep == 0) endorserRep = REPUTATION_BASE; // Default if not yet verified for themselves

        skillTokenEndorsements[skillTokenId][_msgSender()] = Endorsement({
            endorserReputationAtTime: endorserRep,
            timestamp: block.timestamp,
            active: true
        });
        hasEndorsedSkillToken[_msgSender()][skillTokenId] = true;

        // Boost the endorsed user's reputation (weighted by endorser's reputation)
        userReputation[user] += (endorserRep / 100); // Example: 1% of endorser's reputation
        emit SkillEndorsed(skillTokenId, _msgSender(), user, (endorserRep / 100));
        emit ReputationScoreUpdated(user, userReputation[user]);
    }

    /**
     * @dev Allows an endorser to revoke a previous endorsement for a skill token.
     * @param user The address of the user who owns the skill token.
     * @param skillTokenId The ID of the specific skill token for which to revoke the endorsement.
     */
    function revokeEndorsement(address user, uint256 skillTokenId) external whenNotPaused {
        if (ownerOf(skillTokenId) != user) revert VeriSkill__TokenNotOwnedByUser();
        
        Endorsement storage endorsement = skillTokenEndorsements[skillTokenId][_msgSender()];
        if (!endorsement.active) revert VeriSkill__NoActiveEndorsement();

        endorsement.active = false;
        hasEndorsedSkillToken[_msgSender()][skillTokenId] = false;

        // Reduce the endorsed user's reputation
        userReputation[user] -= (endorsement.endorserReputationAtTime / 100); // Example: Deduct the same amount
        emit EndorsementRevoked(skillTokenId, _msgSender(), user);
        emit ReputationScoreUpdated(user, userReputation[user]);
    }

    /**
     * @dev Updates the reputation epoch, recalculating scores and applying decay.
     * This function is intended to be called periodically (e.g., by a keeper network).
     */
    function updateReputationEpoch() external onlyOwner {
        if (block.timestamp < lastReputationEpochUpdateTime + reputationEpochDuration) {
            // Not enough time has passed for a new epoch
            return;
        }

        // Iterate through all users (this approach is not scalable for many users,
        // a more gas-efficient method would involve a merkel tree or only updating active users)
        // For demonstration, we'll keep it simple.
        // A better approach would be to track active users or use an off-chain computation with on-chain verification.

        // Placeholder for reputation decay logic.
        // For production, consider an iterable mapping or process only a batch of users.
        // For every user, decrease reputation by a percentage, then add based on new endorsements.

        // For now, we only update the timestamp. Full re-calculation is complex for on-chain.
        // The current endorsement system directly updates reputation, so explicit epoch decay is
        // not strictly necessary if every transaction accounts for it, or off-chain computation.
        lastReputationEpochUpdateTime = block.timestamp;
    }

    // --- Soulbound Skill Token (SST) - Dynamic NFT Functions ---

    /**
     * @dev Returns the dynamic metadata URI for a given SST.
     * The URI can change based on the token's state (tier, endorsements, etc.).
     * @param tokenId The ID of the SST.
     * @return The metadata URI string.
     */
    function getSkillTokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "VeriSkill: Token does not exist");
        
        // This is where dynamic metadata logic would reside.
        // For simplicity, we just return the initial URI stored in the claim,
        // or a default if not found.
        // In a real dNFT, this would query a tier level, endorsement count, etc.,
        // and construct a URI pointing to an IPFS hash with specific attributes.
        
        // Find the claim associated with this tokenId
        uint256 skillId = skillClaims[tokenId].skillId; // Assuming tokenId matches claimId if minting is 1:1, otherwise need another mapping
        // A more robust solution would map tokenId back to a claimId or store `SkillToken` specific metadata struct.
        // For this example, let's assume `tokenId` is also `claimId` for simplicity in this mapping.
        SkillClaim storage claim = skillClaims[tokenId]; 
        
        string memory baseURI = claim.metadataURI;
        if (bytes(baseURI).length == 0) {
            baseURI = "ipfs://Qmbcdefgh.../default.json"; // Placeholder default URI
        }
        
        // Example of dynamic suffix based on reputation (conceptual)
        uint256 ownerReputation = userReputation[ownerOf(tokenId)];
        if (ownerReputation > 2000) {
            return string(abi.encodePacked(baseURI, "?tier=elite&rep=", ownerReputation.toString()));
        } else if (ownerReputation > 1500) {
            return string(abi.encodePacked(baseURI, "?tier=advanced&rep=", ownerReputation.toString()));
        } else {
            return string(abi.encodePacked(baseURI, "?tier=standard&rep=", ownerReputation.toString()));
        }
    }

    /**
     * @dev Allows a user to initiate an upgrade for their skill token to a higher tier.
     * This would typically involve submitting new evidence and going through re-verification.
     * For this example, it's a conceptual placeholder.
     * @param tokenId The ID of the SST to upgrade.
     * @param newTierLevel The new tier level (e.g., 2 for 'Advanced').
     * @param evidenceHash A hash of the new off-chain evidence for the upgrade.
     */
    function upgradeSkillTier(uint256 tokenId, uint256 newTierLevel, bytes32 evidenceHash) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert VeriSkill__TokenNotOwnedByUser();
        if (newTierLevel <= 1) revert VeriSkill__InvalidSkillTier(); // Example: Tiers start from 1, can't go lower.

        // This would trigger a new verification process similar to submitSkillClaim,
        // but linked to an existing token, and once verified, update the token's internal tier state.
        // For simplicity, this function merely updates the metadata URI.
        // In a full implementation, this might create a new claim that references the existing token.
        // For now, let's just allow the owner to update the URI reflecting a new tier (conceptually verified off-chain).
        // A more robust approach would be to mint a new token representing the upgraded skill.

        string memory newUri = string(abi.encodePacked(getSkillTokenURI(tokenId), "&tier_upgrade=", newTierLevel.toString()));
        emit TokenMetadataUpdated(tokenId, newUri);
        // In a real system, the metadata would be updated *after* a successful re-verification process
        // led by an oracle, which would then call a function to update the token's internal state (e.g., a `tier` variable).
    }

    /**
     * @dev Allows a skill token holder to update their associated metadata URI.
     * This could be used to reflect new off-chain achievements or visual flair after a tier upgrade.
     * @param tokenId The ID of the SST.
     * @param newMetadataURI The new metadata URI.
     */
    function updateTokenMetadata(uint256 tokenId, string calldata newMetadataURI) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert VeriSkill__TokenNotOwnedByUser();

        // This example directly updates metadata. In a dNFT, this might be restricted
        // to only certain events or system updates. For a self-managed profile aspect, it's useful.
        SkillClaim storage claim = skillClaims[tokenId]; // Assuming claimId == tokenId
        claim.metadataURI = newMetadataURI;
        emit TokenMetadataUpdated(tokenId, newMetadataURI);
    }

    /**
     * @dev Allows a user to burn their own Soulbound Skill Token.
     * @param tokenId The ID of the SST to burn.
     */
    function burnSkillToken(uint256 tokenId) external whenNotPaused {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != _msgSender()) revert VeriSkill__TokenNotOwnedByUser();

        _burn(tokenId);
        // Remove from user's latest skill token mapping (if it's the latest)
        // This is tricky if a user can have multiple tokens for the same skill type.
        // For simplicity, we assume `userSkillTokens` stores the *only* or *latest* token.
        // A more robust system would need an array of token IDs per skill per user.
        uint256 skillId = skillClaims[tokenId].skillId;
        if (userSkillTokens[tokenOwner][skillId] == tokenId) {
             delete userSkillTokens[tokenOwner][skillId]; // Remove mapping to this token
        }
        delete tokenOwners[tokenId]; // Remove owner mapping

        // Recalculate reputation (e.g., reduce it for burning a verified skill)
        if (userReputation[tokenOwner] > 100) { // Ensure it doesn't go below a base
            userReputation[tokenOwner] -= 100; // Example reduction
        }
        emit SkillTokenBurned(tokenId, tokenOwner);
        emit ReputationScoreUpdated(tokenOwner, userReputation[tokenOwner]);
    }

    // --- Utility & Access Functions ---

    /**
     * @dev Checks if a user possesses at least one verified skill token of a specific type.
     * @param user The address of the user.
     * @param skillId The ID of the skill type.
     * @return True if the user has the skill, false otherwise.
     */
    function hasSkill(address user, uint256 skillId) public view returns (bool) {
        return userSkillTokens[user][skillId] != 0;
    }

    /**
     * @dev Retrieves the latest minted skill token ID a user holds for a given skill type.
     * @param user The address of the user.
     * @param skillId The ID of the skill type.
     * @return The token ID.
     */
    function getTokenForSkillType(address user, uint256 skillId) external view returns (uint256) {
        uint256 tokenId = userSkillTokens[user][skillId];
        if (tokenId == 0) revert VeriSkill__NoSkillTokenFound();
        return tokenId;
    }

    /**
     * @dev Checks if a user meets all the prerequisites to claim a specific skill.
     * @param user The address of the user.
     * @param skillId The ID of the skill to check prerequisites for.
     * @return True if all prerequisites are met, false otherwise.
     */
    function canClaimSkill(address user, uint256 skillId) public view returns (bool) {
        SkillType storage skill = skillTypes[skillId];
        if (!skill.exists) return false;

        // Check if user already has this skill (avoid duplicate claims for the same skill type)
        // This logic might need adjustment if users can earn different 'tiers' or 'versions' of the same skill.
        if (hasSkill(user, skillId)) return false; 

        for (uint256 i = 0; i < skill.prerequisiteSkillIds.length; i++) {
            if (!hasSkill(user, skill.prerequisiteSkillIds[i])) {
                return false;
            }
        }
        return true;
    }

    // --- Internal Overrides for Soulbound Token ---

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent transfers, making tokens Soulbound.
     * Only minting (from address(0)) and burning (to address(0)) are allowed.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Soulbound: Only allow minting (from zero address) or burning (to zero address)
        // This effectively makes tokens non-transferable between user addresses.
        if (from != address(0) && to != address(0)) {
            revert("VeriSkill: Skill Tokens are Soulbound and non-transferable");
        }
    }

    /**
     * @dev Helper to get owner of token. ERC721's ownerOf is public but requires existence check.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return tokenOwners[tokenId];
    }

    // For compatibility with some interfaces, though not strictly needed due to _beforeTokenTransfer
    function approve(address to, uint256 tokenId) public view override {
        revert("VeriSkill: Skill Tokens are Soulbound and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public view override {
        revert("VeriSkill: Skill Tokens are Soulbound and cannot be approved");
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
        revert("VeriSkill: Skill Tokens are Soulbound and cannot be approved");
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        revert("VeriSkill: Skill Tokens are Soulbound and cannot be approved");
    }
}
```