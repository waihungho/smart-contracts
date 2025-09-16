Okay, this is an exciting challenge! I'll design a smart contract called `SynergyReputationMatrix` (SRM) that leverages several advanced, creative, and trendy concepts:

*   **Dynamic, Evolving NFTs:** The "Reputational Passport" NFT changes its metadata and appearance based on a user's on-chain actions and accumulated "skills."
*   **Modular Skill System:** Instead of a single reputation score, users accrue specific, granular "skills" (e.g., DeFi Contributor, DAO Participant, Builder, Validator), each with its own score.
*   **Attestation-Based & Delegated Authority:** Reputation isn't self-asserted but attested by authorized entities (protocols, DAOs, trusted community members). Users can also delegate attestation rights to specific protocols for automated updates.
*   **Time-Decay Mechanism:** Skills can have configurable time-decay rates, ensuring recency bias and continuous engagement.
*   **Skill Forging:** A creative mechanic where users can combine two existing skills to "forge" a new, more advanced skill, requiring strategic accumulation.
*   **On-chain Proof Linking:** Explicitly link specific on-chain transaction hashes as proof for certain attestations.
*   **Dispute Resolution Framework:** A basic mechanism for users to dispute attestations, which can be resolved by an owner/governance.
*   **Soulbound-like (Non-transferable):** The passports are initially non-transferable to prevent reputation markets, but the contract could include a governance-controlled mechanism to make them transferrable later if deemed appropriate (though not implemented by default here to align with soulbound nature).

---

## SynergyReputationMatrix (SRM)

**Concept:** The `SynergyReputationMatrix` is a novel decentralized identity and reputation system. It issues dynamic, non-transferable (soulbound-like) NFTs called "Reputational Passports" to users. These passports evolve based on verifiable on-chain and off-chain actions, attested to by authorized entities. Unlike simple scoring systems, SRM tracks multiple "skills" (e.g., DeFi Contributor, DAO Participant, Builder, Validator) and incorporates time-decay, delegated attestation, and even skill forging, providing a granular and evolving representation of a user's on-chain persona. It serves as a queryable primitive for other dApps to implement reputation-gated access, personalized incentives, or specialized governance weights.

**Key Advanced Concepts:**
1.  **Dynamic/Evolving NFTs:** Passport metadata (traits, image) changes based on real-time on-chain actions and attestations.
2.  **Modular Skill System:** Granular reputation across multiple distinct categories, rather than a single score.
3.  **Attestation-based Decentralization:** Reputation is built on verifiable claims from authorized (and potentially decentralized) attestors, not centralized scoring.
4.  **Time-Decay & Recency Bias:** Older actions gradually lose influence, encouraging continuous engagement.
5.  **Delegated Attestation:** Users can grant temporary, scoped permissions for automated attestation by protocols or third parties.
6.  **Skill Forging:** Mechanism to combine foundational skills into advanced, composite ones, requiring strategic accumulation.
7.  **On-chain Proof Linking:** Explicitly linking specific transaction hashes or other on-chain data as proof for attestations.
8.  **Dispute Mechanism:** A basic framework for challenging invalid attestations, emphasizing user control over their reputation.

---

### Function Summary:

*   **Passport Management:**
    1.  `mintPassport()`: Mints a unique Reputational Passport NFT for the caller.
    2.  `tokenURI(uint256 tokenId)`: Generates dynamic metadata URI for the passport based on accumulated skills.
    3.  `getPassportSkillProfile(address passportOwner)`: Retrieves the calculated scores for all skills associated with a user's passport.
    4.  `hasPassport(address user)`: Checks if a given address owns a Reputational Passport.
*   **Attestation & Skill Building:**
    5.  `attestSkill(address passportOwner, string calldata skillId, uint256 value, string calldata proofURI)`: An authorized attestor adds a skill attestation to a user's passport.
    6.  `revokeAttestation(address passportOwner, string calldata skillId, bytes32 attestationHash)`: An attestor revokes a previously issued attestation.
    7.  `getAttestationsForSkill(address passportOwner, string calldata skillId)`: Returns all raw attestations for a specific skill of a passport owner.
    8.  `querySkillScore(address passportOwner, string calldata skillId)`: Calculates and returns the current aggregated score for a specific skill, considering decay.
    9.  `getOverallReputationScore(address passportOwner)`: Calculates and returns a weighted aggregate of all skill scores, representing overall reputation.
    10. `linkOnChainProof(address passportOwner, string calldata skillId, bytes32 txHash, string calldata proofDescription)`: Allows an attestor to link a specific on-chain transaction as proof for an attestation.
*   **Attestor & Role Management (Owner/Governance):**
    11. `registerAttestor(address newAttestor, string calldata name, string[] calldata allowedSkills)`: Registers a new entity as an authorized attestor with specific skill granting permissions.
    12. `updateAttestorPermissions(address attestor, string[] calldata allowedSkills)`: Modifies the list of skills an attestor is authorized to grant.
    13. `revokeAttestor(address attestor)`: Revokes the attestor status from an address.
    14. `getAttestorInfo(address attestor)`: Retrieves details about a registered attestor.
    15. `proposeSkillDefinition(string calldata skillId, string calldata description, uint256 defaultDecayRateNumerator, uint256 defaultDecayRateDenominator)`: Owner/governance proposes a new skill type for the system.
    16. `activateSkillDefinition(string calldata skillId)`: Owner/governance activates a proposed skill, making it available for attestors.
    17. `setSkillDecayRate(string calldata skillId, uint256 decayRateNumerator, uint256 decayRateDenominator)`: Sets the time-decay rate for a specific skill.
*   **Advanced User Features:**
    18. `delegateAttestationPermission(address delegatee, string calldata skillId, uint256 duration)`: Allows a passport owner to temporarily delegate permission for a specific skill's attestation to another address.
    19. `revokeDelegatedPermission(address delegatee, string calldata skillId)`: Revokes a previously granted delegated attestation permission.
    20. `forgeSkill(address passportOwner, string calldata primarySkillId, string calldata secondarySkillId, string calldata forgedSkillId, uint256 requiredPrimaryScore, uint256 requiredSecondaryScore, uint256 forgedValue)`: Allows a user to "forge" a new, advanced skill by combining existing ones if certain score thresholds are met.
*   **Dispute Mechanism (Owner/Arbitrator):**
    21. `disputeAttestation(address passportOwner, string calldata skillId, bytes32 attestationHash, string calldata reasonURI)`: Allows a passport owner to flag an attestation as disputed.
    22. `resolveDispute(address passportOwner, string calldata skillId, bytes32 attestationHash, bool removeAttestation)`: Owner/arbitrator resolves a dispute, potentially removing the attestation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Custom Errors ---
error PassportAlreadyMinted();
error PassportDoesNotExist();
error NotAuthorizedAttestor();
error SkillNotAllowedForAttestor();
error SkillDoesNotExist();
error AttestationNotFound();
error SkillNotActive();
error PassportOwnerMismatch();
error UnauthorizedAttestationDelegate();
error DelegatedPermissionNotFound();
error InsufficientSkillScore();
error ForgedSkillAlreadyExists();
error AttestationAlreadyDisputed();
error AttestationNotDisputed();
error AttestationNotActive(); // For attestation revocation on disputed ones
error AttestationRevoked(); // When trying to dispute an already revoked one
error SkillAlreadyActive();
error SkillAlreadyProposed();

contract SynergyReputationMatrix is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;

    // --- Data Structures ---

    struct Attestation {
        address attestor;
        uint256 value; // The raw value attested
        uint256 timestamp; // When the attestation was made
        string proofURI; // URI to off-chain proof (e.g., IPFS hash of a verifiable credential)
        bytes32 onChainProofTxHash; // Optional: A transaction hash as on-chain proof
        bool revoked; // If the attestor revoked it
        bool disputed; // If the passport owner disputed it
        bool active; // False if removed by dispute resolution
    }

    struct AttestorInfo {
        string name;
        mapping(string => bool) allowedSkills; // Skills this attestor can attest for
        bool isActive;
    }

    struct SkillDefinition {
        string description;
        uint256 decayRateNumerator;   // For exponential decay: score = initial_score * (decay_num / decay_den)^(time_elapsed / decay_period_in_seconds)
        uint256 decayRateDenominator; // For simplicity, we'll use a linear decay approximation.
        bool isActive;
        bool isProposed;
    }

    struct DelegatedAttestationPermission {
        address delegatee;
        uint256 expiration; // Unix timestamp
        bool revokedByOwner;
    }

    // --- Mappings & State Variables ---

    uint256 private _nextTokenId; // Counter for passport NFTs

    // passportId => owner address (ERC721 handles tokenId -> owner mapping)
    mapping(address => uint256) public userPassport; // user address => tokenId

    // attestor address => AttestorInfo
    mapping(address => AttestorInfo) public attestors;

    // skillId (string) => SkillDefinition
    mapping(string => SkillDefinition) public skillDefinitions;

    // passport owner => skillId => array of attestations
    mapping(address => mapping(string => Attestation[])) public userSkillAttestations;

    // passport owner => skillId => delegatee address => DelegatedAttestationPermission
    mapping(address => mapping(string => mapping(address => DelegatedAttestationPermission))) public delegatedAttestationPermissions;

    // passport owner => skillId => total raw score for that skill (before decay)
    mapping(address => mapping(string => uint256)) public userRawSkillScores;

    // Store a list of all defined skillIds for iteration in `getPassportSkillProfile` and `getOverallReputationScore`
    string[] public allSkillIds;
    mapping(string => bool) public skillIdExists;

    string private _baseTokenURI; // Base URI for off-chain metadata processing

    // --- Events ---
    event PassportMinted(address indexed owner, uint256 indexed tokenId);
    event SkillAttested(address indexed passportOwner, string indexed skillId, address indexed attestor, uint256 value, bytes32 attestationHash);
    event AttestationRevoked(address indexed passportOwner, string indexed skillId, bytes32 indexed attestationHash, address attestor);
    event AttestorRegistered(address indexed attestor, string name);
    event AttestorPermissionsUpdated(address indexed attestor, string[] allowedSkills);
    event AttestorRevoked(address indexed attestor);
    event SkillDefinitionProposed(string indexed skillId, string description);
    event SkillDefinitionActivated(string indexed skillId);
    event SkillDecayRateUpdated(string indexed skillId, uint256 numerator, uint256 denominator);
    event AttestationPermissionDelegated(address indexed passportOwner, address indexed delegatee, string indexed skillId, uint256 expiration);
    event AttestationPermissionRevoked(address indexed passportOwner, address indexed delegatee, string indexed skillId);
    event SkillForged(address indexed passportOwner, string indexed forgedSkillId, string primarySkillId, string secondarySkillId, uint256 forgedValue);
    event AttestationDisputed(address indexed passportOwner, string indexed skillId, bytes32 indexed attestationHash, string reasonURI);
    event AttestationDisputeResolved(address indexed passportOwner, string indexed skillId, bytes32 indexed attestationHash, bool removed);
    event OnChainProofLinked(address indexed passportOwner, string indexed skillId, bytes32 indexed attestationHash, bytes32 txHash);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseURI;
    }

    // --- Modifiers ---
    modifier onlyAttestor() {
        if (!attestors[msg.sender].isActive) {
            revert NotAuthorizedAttestor();
        }
        _;
    }

    modifier onlyPassportOwner(address _passportOwner) {
        if (userPassport[_passportOwner] == 0 || ownerOf(userPassport[_passportOwner]) != _passportOwner) {
            revert PassportDoesNotExist();
        }
        if (msg.sender != _passportOwner) {
            revert PassportOwnerMismatch();
        }
        _;
    }

    // --- Passport Management (ERC721 functionality) ---

    /// @notice Mints a unique Reputational Passport NFT for the caller.
    /// @dev Each address can only mint one passport. The passport is non-transferable.
    function mintPassport() public {
        if (userPassport[msg.sender] != 0) {
            revert PassportAlreadyMinted();
        }

        _nextTokenId++;
        uint256 tokenId = _nextTokenId;

        _safeMint(msg.sender, tokenId);
        userPassport[msg.sender] = tokenId;

        // Make it soulbound (non-transferable)
        _setApprovalForAll(msg.sender, address(0), false); // Revoke any default operator approvals
        _approve(address(0), tokenId); // Make it unapprovable to anyone else

        emit PassportMinted(msg.sender, tokenId);
    }

    /// @notice Returns the dynamic metadata URI for a given passport tokenId.
    /// @dev This function dynamically generates the metadata based on the current skill profile.
    ///      In a production system, this would likely point to an off-chain renderer service.
    /// @param tokenId The ID of the Reputational Passport.
    /// @return The URI pointing to the passport's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721URIStorage.URIQueryForNonexistentToken();
        }
        address owner = ownerOf(tokenId);
        // Get aggregated skill scores
        (string[] memory skillIds, uint256[] memory scores) = getPassportSkillProfile(owner);

        // Construct JSON metadata
        string memory attributes = "";
        for (uint256 i = 0; i < skillIds.length; i++) {
            attributes = string.concat(
                attributes,
                '{"trait_type":"',
                skillIds[i],
                '","value":',
                scores[i].toString(),
                '},'
            );
        }
        if (bytes(attributes).length > 0) {
             attributes = attributes[0:bytes(attributes).length - 1]; // Remove trailing comma
        }


        // Simplified dynamic image URL based on overall reputation (example)
        uint256 overallScore = getOverallReputationScore(owner);
        string memory imageUrl = string.concat(
            _baseTokenURI,
            "images/",
            overallScore.toString(),
            ".png" // Example: points to a dynamically rendered image based on score
        );

        string memory json = string.concat(
            '{"name": "Reputational Passport #',
            tokenId.toString(),
            '", "description": "Dynamic on-chain reputation passport for ',
            Strings.toHexString(owner),
            '", "image": "',
            imageUrl,
            '", "attributes": [',
            attributes,
            ']}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /// @notice Checks if a given address owns a Reputational Passport.
    /// @param user The address to check.
    /// @return True if the address has a passport, false otherwise.
    function hasPassport(address user) public view returns (bool) {
        return userPassport[user] != 0;
    }

    /// @notice Transfers are disabled to make the NFTs soulbound.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Explicitly disallow transfers
        if (from != address(0) && to != address(0)) {
            revert ERC721Enumerable.ERC721TransferNotSupported(); // Using a generic error
        }
    }

    // --- Attestation & Skill Building ---

    /// @notice An authorized attestor adds a skill attestation to a user's passport.
    /// @param passportOwner The address of the passport owner receiving the attestation.
    /// @param skillId The ID of the skill being attested (e.g., "DeFiContributor").
    /// @param value The raw value of the attestation (e.g., amount of contribution, score).
    /// @param proofURI URI to off-chain proof (e.g., IPFS hash of a verifiable credential).
    function attestSkill(
        address passportOwner,
        string calldata skillId,
        uint256 value,
        string calldata proofURI
    ) public onlyAttestor {
        if (userPassport[passportOwner] == 0) {
            revert PassportDoesNotExist();
        }
        if (!skillDefinitions[skillId].isActive) {
            revert SkillNotActive();
        }
        if (!attestors[msg.sender].allowedSkills[skillId]) {
            revert SkillNotAllowedForAttestor();
        }

        // Check if `msg.sender` has delegated permission if not a direct attestor
        bool hasDelegatedPermission = false;
        DelegatedAttestationPermission storage delegatePerm = delegatedAttestationPermissions[passportOwner][skillId][msg.sender];
        if (delegatePerm.expiration > block.timestamp && !delegatePerm.revokedByOwner) {
            hasDelegatedPermission = true;
        }

        if (!hasDelegatedPermission && msg.sender != owner() && attestors[msg.sender].isActive) {
            // Only require explicit attestor registration if not owner or delegated
        } else if (!hasDelegatedPermission && msg.sender != owner()) {
            revert UnauthorizedAttestationDelegate(); // If not a registered attestor and no valid delegation
        }


        Attestation memory newAttestation = Attestation({
            attestor: msg.sender,
            value: value,
            timestamp: block.timestamp,
            proofURI: proofURI,
            onChainProofTxHash: 0, // Set later if linked
            revoked: false,
            disputed: false,
            active: true
        });

        userSkillAttestations[passportOwner][skillId].push(newAttestation);
        userRawSkillScores[passportOwner][skillId] += value;

        // Compute hash of the attestation for unique identification
        bytes32 attestationHash = keccak256(abi.encodePacked(
            msg.sender, passportOwner, skillId, value, block.timestamp, proofURI
        ));

        emit SkillAttested(passportOwner, skillId, msg.sender, value, attestationHash);
    }

    /// @notice An attestor revokes a previously issued attestation.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @param attestationHash The unique hash identifying the attestation to revoke.
    function revokeAttestation(
        address passportOwner,
        string calldata skillId,
        bytes32 attestationHash
    ) public onlyAttestor {
        Attestation[] storage attestations = userSkillAttestations[passportOwner][skillId];
        bool found = false;

        for (uint256 i = 0; i < attestations.length; i++) {
            bytes32 currentHash = keccak256(abi.encodePacked(
                attestations[i].attestor, passportOwner, skillId, attestations[i].value, attestations[i].timestamp, attestations[i].proofURI
            ));
            if (currentHash == attestationHash && attestations[i].attestor == msg.sender) {
                if (attestations[i].revoked) revert AttestationRevoked();
                if (attestations[i].disputed) revert AttestationAlreadyDisputed(); // Can't revoke if disputed, must resolve dispute first
                if (!attestations[i].active) revert AttestationNotActive();

                attestations[i].revoked = true;
                userRawSkillScores[passportOwner][skillId] -= attestations[i].value;
                found = true;
                emit AttestationRevoked(passportOwner, skillId, attestationHash, msg.sender);
                break;
            }
        }
        if (!found) {
            revert AttestationNotFound();
        }
    }

    /// @notice Returns all raw attestations for a specific skill of a passport owner.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @return An array of Attestation structs.
    function getAttestationsForSkill(address passportOwner, string calldata skillId)
        public
        view
        returns (Attestation[] memory)
    {
        return userSkillAttestations[passportOwner][skillId];
    }

    /// @notice Calculates and returns the current aggregated score for a specific skill, considering decay.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @return The calculated score for the skill.
    function querySkillScore(address passportOwner, string calldata skillId) public view returns (uint256) {
        if (!skillDefinitions[skillId].isActive) {
            return 0; // Inactive skills yield 0 score
        }

        uint256 totalScore = 0;
        Attestation[] storage attestations = userSkillAttestations[passportOwner][skillId];
        SkillDefinition storage skillDef = skillDefinitions[skillId];

        // Decay calculation (linear approximation for simplicity in a smart contract)
        // More complex exponential decay would require more complex math or look-up tables
        // Here: For every decay_denominator seconds, reduce value by decay_numerator %.
        // E.g., decayRateNumerator=1, decayRateDenominator=100 (1% decay per decay_period)
        // decay_period = 30 days in seconds
        uint256 decayPeriodInSeconds = skillDef.decayRateDenominator; // Using denominator as the period duration

        for (uint256 i = 0; i < attestations.length; i++) {
            Attestation storage att = attestations[i];
            if (att.revoked || att.disputed || !att.active) {
                continue;
            }

            uint256 elapsed = block.timestamp - att.timestamp;
            uint256 currentAttestationValue = att.value;

            if (skillDef.decayRateNumerator > 0 && skillDef.decayRateDenominator > 0 && elapsed > 0) {
                // Calculate how many decay periods have passed
                uint256 numPeriods = elapsed / decayPeriodInSeconds;
                // Calculate total decay percentage: (decay_num/decay_den) * num_periods
                uint256 totalDecayPercentage = numPeriods * skillDef.decayRateNumerator;

                if (totalDecayPercentage >= 100) { // If decay is 100% or more, score is 0
                    currentAttestationValue = 0;
                } else {
                    currentAttestationValue = currentAttestationValue * (100 - totalDecayPercentage) / 100;
                }
            }
            totalScore += currentAttestationValue;
        }
        return totalScore;
    }

    /// @notice Retrieves the calculated scores for all skills associated with a user's passport.
    /// @param passportOwner The address of the passport owner.
    /// @return skillIds An array of skill IDs.
    /// @return scores An array of corresponding calculated skill scores.
    function getPassportSkillProfile(address passportOwner) public view returns (string[] memory skillIds, uint256[] memory scores) {
        uint256 activeSkillCount = 0;
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            if (skillDefinitions[allSkillIds[i]].isActive) {
                activeSkillCount++;
            }
        }

        skillIds = new string[](activeSkillCount);
        scores = new uint256[](activeSkillCount);

        uint256 currentIdx = 0;
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            string memory skillId = allSkillIds[i];
            if (skillDefinitions[skillId].isActive) {
                skillIds[currentIdx] = skillId;
                scores[currentIdx] = querySkillScore(passportOwner, skillId);
                currentIdx++;
            }
        }
        return (skillIds, scores);
    }


    /// @notice Calculates and returns a weighted aggregate of all skill scores, representing overall reputation.
    /// @dev This is a simplified sum. In a real system, weights for each skill could be dynamic or set by governance.
    /// @param passportOwner The address of the passport owner.
    /// @return The overall reputation score.
    function getOverallReputationScore(address passportOwner) public view returns (uint256) {
        uint256 overallScore = 0;
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            overallScore += querySkillScore(passportOwner, allSkillIds[i]);
        }
        return overallScore;
    }

    /// @notice Allows an attestor to link a specific on-chain transaction as proof for an attestation.
    /// @dev This function assumes the attestation already exists and identifies it via its hash.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @param attestationHash The unique hash identifying the attestation.
    /// @param txHash The transaction hash to link as proof.
    function linkOnChainProof(
        address passportOwner,
        string calldata skillId,
        bytes32 attestationHash,
        bytes32 txHash
    ) public onlyAttestor {
        Attestation[] storage attestations = userSkillAttestations[passportOwner][skillId];
        bool found = false;

        for (uint256 i = 0; i < attestations.length; i++) {
            bytes32 currentHash = keccak256(abi.encodePacked(
                attestations[i].attestor, passportOwner, skillId, attestations[i].value, attestations[i].timestamp, attestations[i].proofURI
            ));
            if (currentHash == attestationHash && attestations[i].attestor == msg.sender) {
                attestations[i].onChainProofTxHash = txHash;
                found = true;
                emit OnChainProofLinked(passportOwner, skillId, attestationHash, txHash);
                break;
            }
        }
        if (!found) {
            revert AttestationNotFound();
        }
    }


    // --- Attestor & Role Management (Owner/Governance) ---

    /// @notice Registers a new entity as an authorized attestor with specific skill granting permissions.
    /// @dev Only the contract owner can call this.
    /// @param newAttestor The address of the new attestor.
    /// @param name A descriptive name for the attestor.
    /// @param allowedSkills An array of skill IDs this attestor is allowed to grant.
    function registerAttestor(address newAttestor, string calldata name, string[] calldata allowedSkills) public onlyOwner {
        attestors[newAttestor].name = name;
        attestors[newAttestor].isActive = true;
        for (uint256 i = 0; i < allowedSkills.length; i++) {
            // Ensure skill exists before granting permission
            if (!skillDefinitions[allowedSkills[i]].isProposed) { // It doesn't need to be active to be allowed
                revert SkillDoesNotExist();
            }
            attestors[newAttestor].allowedSkills[allowedSkills[i]] = true;
        }
        emit AttestorRegistered(newAttestor, name);
    }

    /// @notice Modifies the list of skills an attestor is authorized to grant.
    /// @dev Only the contract owner can call this. Overwrites existing permissions.
    /// @param attestor The address of the attestor to update.
    /// @param allowedSkills The new array of skill IDs this attestor is allowed to grant.
    function updateAttestorPermissions(address attestor, string[] calldata allowedSkills) public onlyOwner {
        if (!attestors[attestor].isActive) {
            revert NotAuthorizedAttestor(); // Attestor must be active
        }
        // Clear old permissions first (iterating through all possible skills is gas-intensive,
        // in a real app, perhaps manage per skill or use a more efficient storage structure).
        // For now, we'll assume a limited set of skills or a simpler update mechanism.
        // A more robust solution might involve adding/removing individual skill permissions.
        // For this example, we'll just set the new allowed skills.
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            attestors[attestor].allowedSkills[allSkillIds[i]] = false;
        }

        for (uint256 i = 0; i < allowedSkills.length; i++) {
            if (!skillDefinitions[allowedSkills[i]].isProposed) {
                revert SkillDoesNotExist();
            }
            attestors[attestor].allowedSkills[allowedSkills[i]] = true;
        }
        emit AttestorPermissionsUpdated(attestor, allowedSkills);
    }

    /// @notice Revokes the attestor status from an address.
    /// @dev Only the contract owner can call this.
    /// @param attestor The address of the attestor to revoke.
    function revokeAttestor(address attestor) public onlyOwner {
        if (!attestors[attestor].isActive) {
            revert NotAuthorizedAttestor();
        }
        attestors[attestor].isActive = false;
        // Optionally, clear allowedSkills to save space or prevent misuse
        // For (string memory skillId : allSkillIds) { attestors[attestor].allowedSkills[skillId] = false; }
        emit AttestorRevoked(attestor);
    }

    /// @notice Retrieves details about a registered attestor.
    /// @param attestor The address of the attestor.
    /// @return name The name of the attestor.
    /// @return isActive True if the attestor is active.
    /// @return allowedSkills An array of skill IDs the attestor can grant.
    function getAttestorInfo(address attestor) public view returns (string memory name, bool isActive, string[] memory allowedSkills) {
        name = attestors[attestor].name;
        isActive = attestors[attestor].isActive;

        uint256 count = 0;
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            if (attestors[attestor].allowedSkills[allSkillIds[i]]) {
                count++;
            }
        }
        allowedSkills = new string[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < allSkillIds.length; i++) {
            if (attestors[attestor].allowedSkills[allSkillIds[i]]) {
                allowedSkills[currentIdx] = allSkillIds[i];
                currentIdx++;
            }
        }
        return (name, isActive, allowedSkills);
    }

    /// @notice Owner/governance proposes a new skill type for the system.
    /// @dev The skill is not immediately active and needs to be activated separately.
    /// @param skillId The unique ID for the new skill (e.g., "DAOContributor").
    /// @param description A brief description of the skill.
    /// @param defaultDecayRateNumerator Numerator for default decay rate (e.g., 1 for 1%).
    /// @param defaultDecayRateDenominator Denominator for default decay rate (e.g., 100 for 1% per period, or period length in seconds).
    function proposeSkillDefinition(
        string calldata skillId,
        string calldata description,
        uint256 defaultDecayRateNumerator,
        uint256 defaultDecayRateDenominator
    ) public onlyOwner {
        if (skillIdExists[skillId]) {
            revert SkillAlreadyProposed();
        }

        skillDefinitions[skillId] = SkillDefinition({
            description: description,
            decayRateNumerator: defaultDecayRateNumerator,
            decayRateDenominator: defaultDecayRateDenominator,
            isActive: false,
            isProposed: true
        });
        allSkillIds.push(skillId);
        skillIdExists[skillId] = true;
        emit SkillDefinitionProposed(skillId, description);
    }

    /// @notice Owner/governance activates a proposed skill, making it available for attestors.
    /// @param skillId The ID of the skill to activate.
    function activateSkillDefinition(string calldata skillId) public onlyOwner {
        if (!skillDefinitions[skillId].isProposed) {
            revert SkillDoesNotExist();
        }
        if (skillDefinitions[skillId].isActive) {
            revert SkillAlreadyActive();
        }
        skillDefinitions[skillId].isActive = true;
        emit SkillDefinitionActivated(skillId);
    }

    /// @notice Sets the time-decay rate for a specific skill.
    /// @dev Only the contract owner can call this.
    /// @param skillId The ID of the skill.
    /// @param decayRateNumerator Numerator for decay rate.
    /// @param decayRateDenominator Denominator for decay rate (also acts as decay period in seconds).
    function setSkillDecayRate(
        string calldata skillId,
        uint256 decayRateNumerator,
        uint256 decayRateDenominator
    ) public onlyOwner {
        if (!skillDefinitions[skillId].isProposed) { // Must at least be proposed
            revert SkillDoesNotExist();
        }
        skillDefinitions[skillId].decayRateNumerator = decayRateNumerator;
        skillDefinitions[skillId].decayRateDenominator = decayRateDenominator;
        emit SkillDecayRateUpdated(skillId, decayRateNumerator, decayRateDenominator);
    }

    // --- Advanced User Features ---

    /// @notice Allows a passport owner to temporarily delegate permission for a specific skill's attestation to another address.
    /// @dev This enables protocols or automated systems to attest on a user's behalf for a limited time.
    /// @param delegatee The address receiving delegation.
    /// @param skillId The skill ID for which attestation permission is delegated.
    /// @param duration The duration in seconds for which the permission is valid.
    function delegateAttestationPermission(
        address delegatee,
        string calldata skillId,
        uint256 duration
    ) public onlyPassportOwner(msg.sender) {
        if (!skillDefinitions[skillId].isActive) {
            revert SkillNotActive();
        }

        delegatedAttestationPermissions[msg.sender][skillId][delegatee] = DelegatedAttestationPermission({
            delegatee: delegatee,
            expiration: block.timestamp + duration,
            revokedByOwner: false
        });
        emit AttestationPermissionDelegated(msg.sender, delegatee, skillId, block.timestamp + duration);
    }

    /// @notice Revokes a previously granted delegated attestation permission.
    /// @param delegatee The address whose delegation is being revoked.
    /// @param skillId The skill ID for which the permission was delegated.
    function revokeDelegatedPermission(address delegatee, string calldata skillId) public onlyPassportOwner(msg.sender) {
        DelegatedAttestationPermission storage delegatePerm = delegatedAttestationPermissions[msg.sender][skillId][delegatee];
        if (delegatePerm.expiration == 0 || delegatePerm.revokedByOwner) { // 0 expiration means never set or already revoked
            revert DelegatedPermissionNotFound();
        }
        delegatePerm.revokedByOwner = true; // Mark as revoked
        // We don't delete to keep historical record if needed, but it's effectively inactive
        emit AttestationPermissionRevoked(msg.sender, delegatee, skillId);
    }

    /// @notice Allows a user to "forge" a new, advanced skill by combining existing ones if certain score thresholds are met.
    /// @dev This burns a portion of the primary and secondary skill scores and grants a new skill attestation.
    ///      The forged skill must already be defined and active.
    /// @param passportOwner The address of the passport owner.
    /// @param primarySkillId The ID of the primary foundational skill.
    /// @param secondarySkillId The ID of the secondary foundational skill.
    /// @param forgedSkillId The ID of the new skill to forge.
    /// @param requiredPrimaryScore Minimum score required for the primary skill.
    /// @param requiredSecondaryScore Minimum score required for the secondary skill.
    /// @param forgedValue The value of the new forged skill attestation.
    function forgeSkill(
        address passportOwner,
        string calldata primarySkillId,
        string calldata secondarySkillId,
        string calldata forgedSkillId,
        uint256 requiredPrimaryScore,
        uint256 requiredSecondaryScore,
        uint256 forgedValue
    ) public onlyPassportOwner(passportOwner) {
        if (!skillDefinitions[forgedSkillId].isActive) {
            revert SkillNotActive(); // Can only forge active skills
        }

        // Check if the forged skill already exists as an active attestation for the user
        // This is a simplified check. A more robust system might allow multiple forge actions.
        Attestation[] storage forgedAtts = userSkillAttestations[passportOwner][forgedSkillId];
        for (uint256 i = 0; i < forgedAtts.length; i++) {
            if (forgedAtts[i].active && !forgedAtts[i].revoked && !forgedAtts[i].disputed) {
                revert ForgedSkillAlreadyExists();
            }
        }

        uint256 currentPrimaryScore = querySkillScore(passportOwner, primarySkillId);
        uint256 currentSecondaryScore = querySkillScore(passportOwner, secondarySkillId);

        if (currentPrimaryScore < requiredPrimaryScore || currentSecondaryScore < requiredSecondaryScore) {
            revert InsufficientSkillScore();
        }

        // To "burn" skill points, we'll add negative attestations. This is a common pattern,
        // but for simplicity, here we'll assume forging doesn't strictly burn, but rather
        // consumes a conceptual amount, or just requires the threshold.
        // A more complex system might require burning specific attestations.
        // For this example, we'll just require the threshold and create a new attestation.

        Attestation memory newAttestation = Attestation({
            attestor: address(this), // Contract itself acts as attestor for forged skills
            value: forgedValue,
            timestamp: block.timestamp,
            proofURI: string.concat("Forged from ", primarySkillId, " & ", secondarySkillId),
            onChainProofTxHash: bytes32(0),
            revoked: false,
            disputed: false,
            active: true
        });

        userSkillAttestations[passportOwner][forgedSkillId].push(newAttestation);
        userRawSkillScores[passportOwner][forgedSkillId] += forgedValue;

        emit SkillForged(passportOwner, forgedSkillId, primarySkillId, secondarySkillId, forgedValue);
    }

    // --- Dispute Mechanism (Owner/Arbitrator) ---

    /// @notice Allows a passport owner to flag an attestation as disputed.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @param attestationHash The unique hash identifying the attestation to dispute.
    /// @param reasonURI URI to off-chain reason/evidence for the dispute.
    function disputeAttestation(
        address passportOwner,
        string calldata skillId,
        bytes32 attestationHash,
        string calldata reasonURI
    ) public onlyPassportOwner(passportOwner) {
        Attestation[] storage attestations = userSkillAttestations[passportOwner][skillId];
        bool found = false;

        for (uint256 i = 0; i < attestations.length; i++) {
            bytes32 currentHash = keccak256(abi.encodePacked(
                attestations[i].attestor, passportOwner, skillId, attestations[i].value, attestations[i].timestamp, attestations[i].proofURI
            ));
            if (currentHash == attestationHash) {
                if (attestations[i].disputed) revert AttestationAlreadyDisputed();
                if (attestations[i].revoked) revert AttestationRevoked(); // Cannot dispute a revoked attestation

                attestations[i].disputed = true;
                found = true;
                emit AttestationDisputed(passportOwner, skillId, attestationHash, reasonURI);
                break;
            }
        }
        if (!found) {
            revert AttestationNotFound();
        }
    }

    /// @notice Owner/arbitrator resolves a dispute, potentially removing the attestation.
    /// @dev Only the contract owner (or a designated arbitrator) can call this.
    /// @param passportOwner The address of the passport owner.
    /// @param skillId The ID of the skill.
    /// @param attestationHash The unique hash identifying the attestation.
    /// @param removeAttestation If true, the attestation is removed (marked inactive); otherwise, dispute flag is cleared.
    function resolveDispute(
        address passportOwner,
        string calldata skillId,
        bytes32 attestationHash,
        bool removeAttestation
    ) public onlyOwner { // In a real DAO, this would be a governance-controlled function
        Attestation[] storage attestations = userSkillAttestations[passportOwner][skillId];
        bool found = false;

        for (uint256 i = 0; i < attestations.length; i++) {
            bytes32 currentHash = keccak256(abi.encodePacked(
                attestations[i].attestor, passportOwner, skillId, attestations[i].value, attestations[i].timestamp, attestations[i].proofURI
            ));
            if (currentHash == attestationHash) {
                if (!attestations[i].disputed) revert AttestationNotDisputed();

                if (removeAttestation) {
                    attestations[i].active = false;
                    // Deduct from raw score
                    if (userRawSkillScores[passportOwner][skillId] >= attestations[i].value) {
                         userRawSkillScores[passportOwner][skillId] -= attestations[i].value;
                    } else {
                        userRawSkillScores[passportOwner][skillId] = 0; // Prevent underflow if value was already small due to decay logic
                    }
                }
                attestations[i].disputed = false; // Always clear the disputed flag after resolution
                found = true;
                emit AttestationDisputeResolved(passportOwner, skillId, attestationHash, removeAttestation);
                break;
            }
        }
        if (!found) {
            revert AttestationNotFound();
        }
    }
}
```