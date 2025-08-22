This smart contract, `VerifiableReputationNetwork` (VRN), is designed to be a cutting-edge decentralized platform for managing on-chain verifiable identities, skills, and reputation. It introduces novel concepts such as AI-assisted claim verification, dynamic Soulbound Tokens (SBTs) for skill progression, reputation-weighted decentralized autonomous organization (DAO) governance, and a reputation-aware quadratic funding mechanism for public goods. The core philosophy is to build a trusted, transparent, and evolving on-chain identity for users based on their verifiable achievements and contributions.

---

## VerifiableReputationNetwork Contract Outline and Function Summary

**Contract Name:** `VerifiableReputationNetwork` (VRN)

**Key Concepts:**
*   **ClaimSBTs:** Non-transferable ERC721 tokens representing verified achievements, credentials, or attestations.
*   **SkillSBTs:** Non-transferable, dynamic ERC721 tokens that represent a user's proficiency in a specific skill. These tokens can "level up" or "decay" based on continuous engagement and new verified claims, reflecting a more dynamic and current representation of ability.
*   **AI Oracle Integration:** An off-chain AI model processes evidence for claims and submits verification proofs (e.g., confidence scores, attestations) on-chain. This provides a scalable and objective layer for initial claim validation.
*   **Reputation Score:** A quantitative metric derived from a user's verified claims and the levels of their skill proficiencies. This score is central to a user's influence within the network.
*   **Reputation-Weighted DAO:** The governance model where voting power is directly proportional to a user's reputation score, ensuring that trusted and active community members have greater influence over platform evolution.
*   **Quadratic Public Goods Funding:** A mechanism to fund public good projects, leveraging both direct contributions and a reputation-weighted matching pool to prioritize projects with broad community support and high-reputation backing.

---

### Function Summary:

**I. Core Infrastructure & Access Control**
1.  **`constructor(address _aiOracleAddress)`**: Initializes the contract owner, sets the initial AI Oracle address, and deploys the `ClaimSBT` and `SkillSBT` helper contracts.
2.  **`renounceOwnership()`**: Allows the current owner to relinquish ownership of the contract. (Standard OpenZeppelin)
3.  **`transferOwnership(address newOwner)`**: Transfers ownership of the contract to a new address. (Standard OpenZeppelin)
4.  **`setAIOracleAddress(address _newAIOracleAddress)`**: Updates the address of the trusted AI Oracle contract. Callable by the DAO (or initial owner).

**II. Claim Management (Reputation SBTs)**
5.  **`registerClaimType(string memory _name, string memory _description, uint256 _baseReputationImpact, address _issuer)`**: Defines a new category for claims, specifying its name, description, the base impact it has on reputation, and an optional specific issuer address. Callable by the DAO.
6.  **`issueReputationClaim(address _recipient, uint256 _claimTypeId, string memory _metadataURI, bytes32 _evidenceHash, uint256 _requiredAIConfidence)`**: Mints a new non-transferable `ClaimSBT` for a recipient. This claim is initially `PendingAIVerification` and requires AI Oracle input. Callable by designated issuers or the DAO.
7.  **`submitAIProofForClaim(uint256 _claimId, uint256 _aiConfidenceScore, bytes memory _proofData)`**: Called by the AI Oracle to submit verification results (a confidence score and optional proof data) for a pending claim.
8.  **`verifyClaim(uint256 _claimId, bool _isValid)`**: Finalizes a claim's status as `Verified` or `Invalid` after AI verification. This decision is made by the DAO, considering the AI's confidence score.
9.  **`getClaimDetails(uint256 _claimId)`**: Retrieves all stored details (including associated `ClaimType`) for a specific `ClaimSBT`.
10. **`getClaimsByOwner(address _owner)`**: Returns an array of `ClaimSBT` IDs owned by a specific address.
11. **`updateClaimMetadataURI(uint252 _claimId, string memory _newMetadataURI)`**: Allows the claimant, original issuer, or DAO to update the URI pointing to evidence or metadata for a claim.
12. **`revokeClaim(uint256 _claimId)`**: Allows the DAO to invalidate and burn a previously `Verified` claim (e.g., if found to be fraudulent).

**III. Skill Proficiency Management (Dynamic SBTs)**
13. **`registerSkillType(string memory _name, string memory _description, uint256 _initialReputationImpact)`**: Defines a new type of skill, specifying its name, description, and initial reputation impact. Callable by the DAO.
14. **`mintSkillProficiency(address _recipient, uint256 _skillTypeId, string memory _metadataURI)`**: Mints a new non-transferable `SkillSBT` for a recipient. Each user can only have one `SkillSBT` per skill type. Callable by the DAO.
15. **`levelUpSkillProficiency(uint256 _skillTokenId, uint256 _levelIncrease)`**: Increases the level of a `SkillSBT`. This could be triggered by new verified claims, on-chain challenges, or DAO decisions. Callable by the owner for demonstration, ideally integrated with claim verification.
16. **`getSkillProficiencyDetails(uint256 _skillTokenId)`**: Retrieves all stored details (including associated `SkillType`) for a specific `SkillSBT`.
17. **`getSkillsByOwner(address _owner)`**: Returns an array of `SkillSBT` IDs owned by a specific address.
18. **`decaySkillProficiency(uint256 _skillTokenId, uint256 _decayAmount)`**: Allows the DAO to reduce a skill's level over time if not actively updated or used, promoting the recency and relevance of skills.

**IV. Reputation Scoring**
19. **`calculateUserReputationScore(address _user)`**: Recalculates and updates a user's total reputation score based on their verified claims and skill levels, applying configured weights. This function is automatically called upon claim verification/revocation or skill updates.
20. **`getUserReputationScore(address _user)`**: Retrieves the current reputation score for a specific user.
21. **`setClaimTypeWeight(uint256 _claimTypeId, uint256 _newWeight)`**: Allows the DAO to adjust how much a specific claim type contributes to the overall reputation score (e.g., to prioritize certain types of achievements).
22. **`setSkillTypeWeight(uint256 _skillTypeId, uint256 _newWeight)`**: Allows the DAO to adjust how a specific skill type's level contributes to the overall reputation score.

**V. Decentralized Autonomous Organization (DAO) Governance**
23. **`createProposal(string memory _description, bytes memory _callData, uint256 _votingPeriodDays)`**: Allows users (with a minimum reputation score) to propose changes to the network. Proposals include a description and an encoded function call (`_callData`) to be executed if passed.
24. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Users cast a reputation-weighted vote (`yay` or `nay`) on an active proposal.
25. **`delegateVote(address _delegatee)`**: Users can delegate their reputation-based voting power to another address, enabling liquid democracy.
26. **`undelegateVote()`**: Reverts a previous vote delegation, returning voting power to the delegator.
27. **`executeProposal(uint256 _proposalId)`**: Triggered by the DAO after a proposal's voting period ends and it has passed. Executes the `_callData` associated with the proposal.

**VI. Public Goods Funding (Reputation-Weighted Quadratic Funding)**
28. **`proposePublicGood(string memory _projectTitle, string memory _descriptionURI, address _recipient)`**: Allows users (with sufficient reputation) to propose a public good project for community funding.
29. **`contributeToPublicGood(uint256 _projectId)`**: Users can contribute Ether to a specific public good project. These contributions also feed into a general match pool.
30. **`allocateQuadraticFunds(uint22 _projectId, uint256 _matchAmountFromDAO)`**: A simplified quadratic funding distribution mechanism. The DAO allocates direct contributions plus a specified match amount to a public good project. (Note: A full on-chain quadratic funding calculation is gas-intensive; this function simplifies distribution based on DAO-approved match amounts, leveraging the collected contributions and potentially an external match pool).
31. **`receive()`**: A fallback function allowing direct Ether contributions to the general `publicGoodFundingMatchPool`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// Outline and Function Summary:
// This contract, VerifiableReputationNetwork (VRN), is a decentralized platform for managing on-chain verifiable claims,
// skill proficiencies, and reputation scores. It leverages Soulbound Tokens (SBTs) for claims and dynamic SBTs for
// skills, integrates with an off-chain AI oracle for claim verification, and features a robust, reputation-weighted
// DAO governance model. It also includes a unique mechanism for reputation-weighted quadratic funding of public goods.
// The core idea is to build a trusted, transparent, and dynamic on-chain identity for users based on verifiable achievements.

// Key Concepts:
// - ClaimSBTs: Non-transferable ERC721 tokens representing verified achievements or credentials.
// - SkillSBTs: Non-transferable, dynamic ERC721 tokens representing skills that can level up or decay.
// - AI Oracle Integration: Off-chain AI model processes evidence, submits verification proof on-chain.
// - Reputation Score: Derived from verified claims and skill levels, influencing governance power.
// - Reputation-Weighted DAO: Governance where voting power is proportional to a user's reputation score.
// - Quadratic Public Goods Funding: A mechanism to fund public goods, leveraging reputation and quadratic voting principles.

// I. Core Infrastructure & Access Control
// 1.  constructor(): Initializes contract owner, AI oracle address, and initial parameters.
// 2.  renounceOwnership(): Allows the current owner to relinquish ownership. (Standard OpenZeppelin)
// 3.  transferOwnership(): Transfers ownership of the contract to a new address. (Standard OpenZeppelin)
// 4.  setAIOracleAddress(): Updates the address of the trusted AI Oracle contract. Callable by owner/DAO.

// II. Claim Management (Reputation SBTs - ERC721-like, but non-transferable)
// 5.  registerClaimType(): Defines a new category for claims, specifying its base reputation impact.
// 6.  issueReputationClaim(): Mints a new ClaimSBT for a recipient, pending AI verification.
// 7.  submitAIProofForClaim(): Called by the AI Oracle to submit verification results (confidence score, proof).
// 8.  verifyClaim(): Finalizes a claim's status as verified or invalid, based on AI proof. Callable by DAO.
// 9.  getClaimDetails(): Retrieves all stored details for a specific ClaimSBT.
// 10. getClaimsByOwner(): Returns an array of ClaimSBT IDs owned by a specific address.
// 11. updateClaimMetadataURI(): Allows the claimant or issuer to update the evidence URI for a claim.
// 12. revokeClaim(): Allows the original issuer or DAO to invalidate a claim.

// III. Skill Proficiency Management (Dynamic SBTs)
// 13. registerSkillType(): Defines a new type of skill, specifying its initial reputation impact.
// 14. mintSkillProficiency(): Mints a new SkillSBT for a recipient.
// 15. levelUpSkillProficiency(): Increases the level of a SkillSBT, based on defined criteria (e.g., new claims).
// 16. getSkillProficiencyDetails(): Retrieves all stored details for a specific SkillSBT.
// 17. getSkillsByOwner(): Returns an array of SkillSBT IDs owned by a specific address.
// 18. decaySkillProficiency(): Allows the DAO to reduce a skill's level over time if not actively updated, promoting recency.

// IV. Reputation Scoring
// 19. calculateUserReputationScore(): Recalculates and updates a user's reputation score based on their verified claims and skill levels.
// 20. getUserReputationScore(): Retrieves the current reputation score for a user.
// 21. setClaimTypeWeight(): DAO function to adjust how a specific claim type contributes to the overall reputation score.
// 22. setSkillTypeWeight(): DAO function to adjust how a specific skill type contributes to the overall reputation score.

// V. Decentralized Autonomous Organization (DAO) Governance
// 23. createProposal(): Allows users (with sufficient reputation) to propose changes to the network.
// 24. voteOnProposal(): Users cast a reputation-weighted vote on an active proposal.
// 25. delegateVote(): Users can delegate their reputation-based voting power to another address.
// 26. undelegateVote(): Reverts a previous vote delegation.
// 27. executeProposal(): Executes the on-chain action associated with a passed proposal.

// VI. Public Goods Funding (Reputation-Weighted Quadratic Funding)
// 28. proposePublicGood(): Allows users (with sufficient reputation) to propose a public good project for funding.
// 29. contributeToPublicGood(): Users can contribute Ether to a specific public good project.
// 30. allocateQuadraticFunds(): The DAO distributes collected funds to public good projects based on quadratic funding principles,
//     considering the reputation of contributors. (Note: Full quadratic funding logic is complex for on-chain, this simplifies to distribution based on votes/contributions).
// 31. receive(): Fallback function to allow direct Ether contributions to the match pool.


// --- Helper Contracts (SBTs) ---

// ClaimSBT: Non-transferable ERC721 for verifiable claims
contract ClaimSBT is ERC721, Ownable {
    constructor(address _owner) ERC721("Claim SBT", "CLMSBT") {
        // The VRN contract itself is the owner of this SBT contract
        _transferOwnership(_owner);
    }

    // Override _beforeTokenTransfer to make tokens non-transferable
    // Only allows minting (from address(0)) or burning (to address(0))
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("ClaimSBT: Token is non-transferable");
        }
    }

    // Allow the main contract to mint tokens
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    // Allow the main contract to burn tokens (e.g., for revocation)
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}

// SkillSBT: Non-transferable, dynamic ERC721 for skill proficiencies
contract SkillSBT is ERC721, Ownable {
    constructor(address _owner) ERC721("Skill SBT", "SKLSBT") {
        // The VRN contract itself is the owner of this SBT contract
        _transferOwnership(_owner);
    }

    // Override _beforeTokenTransfer to make tokens non-transferable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("SkillSBT: Token is non-transferable");
        }
    }

    // Allow the main contract to mint tokens
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    // Allow the main contract to burn tokens
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}

// --- Main Contract ---

contract VerifiableReputationNetwork is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // SBT Contracts
    ClaimSBT public claimSBT;
    SkillSBT public skillSBT;

    // AI Oracle
    address public aiOracleAddress;

    // Claim Types
    struct ClaimType {
        string name;
        string description;
        uint256 baseReputationImpact; // Base impact on reputation score
        uint256 currentWeight;        // Current weighting factor for reputation calculation (DAO configurable, 0-1000, 100 = 100%)
        address issuer;               // Optional: specific issuer for this type, or address(0) for general
        bool isActive;
    }
    mapping(uint256 => ClaimType) public claimTypes;
    Counters.Counter private _claimTypeIds;

    // Claims (SBTs)
    enum ClaimStatus { PendingAIVerification, PendingDAOVerification, Verified, Invalid, Revoked }
    struct Claim {
        uint256 claimTypeId;
        address recipient;
        string metadataURI;       // URI pointing to evidence/details (e.g., IPFS)
        bytes32 evidenceHash;     // Hash of the evidence for AI verification
        uint256 aiConfidenceScore; // Score from AI Oracle (0-1000)
        uint256 requiredAIConfidence; // Minimum score required for initial AI verification (0-1000)
        ClaimStatus status;
        uint256 issuanceTimestamp;
        address issuer; // The address that initiated the claim issuance
    }
    mapping(uint256 => Claim) public claims;
    Counters.Counter private _claimTokenIds;
    mapping(address => uint256[]) public userClaims; // Stores ClaimSBT IDs for each user

    // Skill Types
    struct SkillType {
        string name;
        string description;
        uint256 initialReputationImpact;
        uint256 currentWeight;        // Current weighting factor for reputation calculation (DAO configurable, 0-1000, 100 = 100%)
        bool isActive;
    }
    mapping(uint256 => SkillType) public skillTypes;
    Counters.Counter private _skillTypeIds;

    // Skills (Dynamic SBTs)
    struct SkillProficiency {
        uint256 skillTypeId;
        address recipient;
        string metadataURI;
        uint256 level;           // Current skill level
        uint256 experiencePoints; // XP towards next level (can be used for more granular leveling logic)
        uint256 lastUpdated;     // Timestamp of last update/levelUp
    }
    mapping(uint256 => SkillProficiency) public skillProficiencies;
    Counters.Counter private _skillTokenIds;
    mapping(address => uint256[]) public userSkills; // Stores SkillSBT IDs for each user

    // Reputation Scores
    mapping(address => uint256) public userReputationScores;
    uint256 public minReputationForProposal = 1000; // Minimum reputation to create a DAO proposal

    // DAO Governance
    struct Proposal {
        uint256 id;
        string description;
        bytes callData;         // The function call to execute if proposal passes
        address proposer;
        uint256 createdTimestamp;
        uint256 expirationTimestamp;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // user => proposalId => voted
    mapping(address => address) public delegatedVotes; // user => delegatee (stores the address to which votes are delegated)

    // Public Goods Funding
    struct PublicGoodProject {
        uint256 id;
        string title;
        string descriptionURI;
        address recipient; // Address to receive funds
        uint256 totalContributions; // ETH contributed directly
        mapping(address => uint256) contributions; // Individual contributions
        bool funded;
        bool active;
    }
    mapping(uint256 => PublicGoodProject) public publicGoodProjects;
    Counters.Counter private _publicGoodProjectIds;
    uint256 public publicGoodFundingMatchPool; // ETH collected for match funding (from DAO or external contributions)

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newAddress);

    event ClaimTypeRegistered(uint256 indexed claimTypeId, string name, uint256 baseReputationImpact);
    event ClaimIssued(uint256 indexed claimId, uint256 indexed claimTypeId, address indexed recipient, address indexed issuer, string metadataURI);
    event AIProofSubmitted(uint256 indexed claimId, uint256 aiConfidenceScore, bytes proofData);
    event ClaimVerified(uint256 indexed claimId, ClaimStatus newStatus);
    event ClaimMetadataUpdated(uint256 indexed claimId, string newMetadataURI);
    event ClaimRevoked(uint256 indexed claimId, address revoker);

    event SkillTypeRegistered(uint256 indexed skillTypeId, string name, uint256 initialReputationImpact);
    event SkillProficiencyMinted(uint256 indexed skillTokenId, uint256 indexed skillTypeId, address indexed recipient, string metadataURI);
    event SkillProficiencyLeveledUp(uint256 indexed skillTokenId, uint256 newLevel, uint256 levelIncrease);
    event SkillProficiencyDecayed(uint256 indexed skillTokenId, uint256 newLevel, uint256 decayAmount);

    event ReputationScoreCalculated(address indexed user, uint256 newScore);
    event ClaimTypeWeightSet(uint256 indexed claimTypeId, uint256 newWeight);
    event SkillTypeWeightSet(uint256 indexed skillTypeId, uint256 newWeight);

    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationPower);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event PublicGoodProposed(uint256 indexed projectId, string title, address indexed recipient, address indexed proposer);
    event PublicGoodContributed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event PublicGoodFundsAllocated(uint256 indexed projectId, uint256 allocatedAmount, uint256 matchPoolUsed);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(_msgSender() == aiOracleAddress, "VRN: Only AI Oracle can call this function");
        _;
    }

    modifier onlyDAO() {
        // In a full DAO setup, this would check if the call comes from the DAO's Governor contract.
        // For this example, 'owner()' simulates the initial centralized DAO controller.
        // Once a proper Governor contract is deployed, this should be updated to `require(_msgSender() == DAO_GOVERNOR_ADDRESS)`.
        require(_msgSender() == owner(), "VRN: Only DAO (or Owner for simulation) can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress) Ownable(_msgSender()) {
        require(_aiOracleAddress != address(0), "VRN: AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;

        // Deploy the SBT helper contracts and set this VRN contract as their owner.
        // This grants VRN the permission to mint/burn SBTs.
        claimSBT = new ClaimSBT(address(this));
        skillSBT = new SkillSBT(address(this));
    }

    // --- I. Core Infrastructure & Access Control ---

    // 4. setAIOracleAddress
    function setAIOracleAddress(address _newAIOracleAddress) external onlyDAO {
        require(_newAIOracleAddress != address(0), "VRN: New AI Oracle address cannot be zero");
        aiOracleAddress = _newAIOracleAddress;
        emit AIOracleAddressUpdated(_newAIOracleAddress);
    }

    // --- II. Claim Management ---

    // 5. registerClaimType
    function registerClaimType(string memory _name, string memory _description, uint256 _baseReputationImpact, address _issuer) external onlyDAO returns (uint256) {
        _claimTypeIds.increment();
        uint256 newId = _claimTypeIds.current();
        claimTypes[newId] = ClaimType({
            name: _name,
            description: _description,
            baseReputationImpact: _baseReputationImpact,
            currentWeight: 100, // Default weight 100% (value of 100 means 100/100 = 1x impact)
            issuer: _issuer,
            isActive: true
        });
        emit ClaimTypeRegistered(newId, _name, _baseReputationImpact);
        return newId;
    }

    // 6. issueReputationClaim
    // Can be called by any registered issuer, or the DAO.
    function issueReputationClaim(
        address _recipient,
        uint256 _claimTypeId,
        string memory _metadataURI,
        bytes32 _evidenceHash,
        uint256 _requiredAIConfidence
    ) external nonReentrant {
        ClaimType storage cType = claimTypes[_claimTypeId];
        require(cType.isActive, "VRN: Claim type is not active");
        require(_recipient != address(0), "VRN: Recipient cannot be zero address");
        require(_requiredAIConfidence <= 1000, "VRN: Required AI confidence must be 0-1000");

        // If a specific issuer is designated for this claim type, only they can issue.
        // Otherwise, allow the DAO (owner in this example) to issue.
        if (cType.issuer != address(0)) {
            require(_msgSender() == cType.issuer, "VRN: Only designated issuer can issue this claim type");
        } else {
            // For general claim types, only the DAO (owner) can issue them.
            // A more advanced system might have a whitelist of 'proposers' or a DAO vote for issuance.
            require(_msgSender() == owner(), "VRN: Only owner can issue this general claim type for now.");
        }
        
        _claimTokenIds.increment();
        uint256 newClaimId = _claimTokenIds.current();

        claims[newClaimId] = Claim({
            claimTypeId: _claimTypeId,
            recipient: _recipient,
            metadataURI: _metadataURI,
            evidenceHash: _evidenceHash,
            aiConfidenceScore: 0, // Awaiting AI verification
            requiredAIConfidence: _requiredAIConfidence,
            status: ClaimStatus.PendingAIVerification,
            issuanceTimestamp: block.timestamp,
            issuer: _msgSender() // Store the actual issuer
        });

        userClaims[_recipient].push(newClaimId);
        claimSBT.mint(_recipient, newClaimId); // Mint the SBT immediately, status is 'pending'

        emit ClaimIssued(newClaimId, _claimTypeId, _recipient, _msgSender(), _metadataURI);
    }

    // 7. submitAIProofForClaim
    function submitAIProofForClaim(
        uint256 _claimId,
        uint256 _aiConfidenceScore,
        bytes memory _proofData // e.g., hash of ZK-proof, or AI attestation
    ) external onlyAIOracle {
        Claim storage claim = claims[_claimId];
        require(claim.createdTimestamp != 0, "VRN: Claim does not exist");
        require(claim.status == ClaimStatus.PendingAIVerification, "VRN: Claim not in pending AI verification state");
        require(claim.evidenceHash != 0, "VRN: Claim has no evidence hash for AI verification");
        require(_aiConfidenceScore <= 1000, "VRN: AI confidence score must be 0-1000");

        claim.aiConfidenceScore = _aiConfidenceScore;
        // _proofData can be stored for auditability, or just its hash if too large for on-chain.
        // For simplicity, we assume _proofData is verifiable by the AI Oracle off-chain.
        // On-chain verification of a ZK-proof would be a separate, more complex step.

        if (_aiConfidenceScore >= claim.requiredAIConfidence) {
            claim.status = ClaimStatus.PendingDAOVerification; // AI passed, now needs DAO review
        } else {
            claim.status = ClaimStatus.Invalid; // AI failed
            claimSBT.burn(_claimId); // Burn the SBT if AI failed
            calculateUserReputationScore(claim.recipient); // Recalculate if SBT burned
        }
        emit AIProofSubmitted(_claimId, _aiConfidenceScore, _proofData);
    }

    // 8. verifyClaim
    function verifyClaim(uint256 _claimId, bool _isValid) external onlyDAO {
        Claim storage claim = claims[_claimId];
        require(claim.createdTimestamp != 0, "VRN: Claim does not exist");
        require(claim.status == ClaimStatus.PendingDAOVerification || claim.status == ClaimStatus.Invalid, "VRN: Claim not in pending DAO verification or already invalid/verified/revoked");

        if (_isValid) {
            require(claim.aiConfidenceScore >= claim.requiredAIConfidence, "VRN: AI confidence not met for valid verification");
            claim.status = ClaimStatus.Verified;
            // No need to mint again, as it was minted as 'pending'
        } else {
            claim.status = ClaimStatus.Invalid;
            // Only burn if the SBT exists and is currently owned by recipient (prevent double burn if AI already failed)
            if (claimSBT.ownerOf(_claimId) == claim.recipient) {
                 claimSBT.burn(_claimId); // Burn the SBT if DAO decides invalid
            }
        }
        // Recalculate recipient's reputation score if status changed to Verified/Invalid
        calculateUserReputationScore(claim.recipient);
        emit ClaimVerified(_claimId, claim.status);
    }

    // 9. getClaimDetails
    function getClaimDetails(uint256 _claimId) external view returns (ClaimType memory, Claim memory) {
        require(claims[_claimId].createdTimestamp != 0, "VRN: Claim does not exist");
        return (claimTypes[claims[_claimId].claimTypeId], claims[_claimId]);
    }

    // 10. getClaimsByOwner
    function getClaimsByOwner(address _owner) external view returns (uint256[] memory) {
        return userClaims[_owner];
    }

    // 11. updateClaimMetadataURI
    function updateClaimMetadataURI(uint256 _claimId, string memory _newMetadataURI) external {
        Claim storage claim = claims[_claimId];
        require(claim.createdTimestamp != 0, "VRN: Claim does not exist");
        require(claim.recipient == _msgSender() || claim.issuer == _msgSender() || _msgSender() == owner(), "VRN: Only recipient, issuer, or owner can update URI");
        claim.metadataURI = _newMetadataURI;
        emit ClaimMetadataUpdated(_claimId, _newMetadataURI);
    }

    // 12. revokeClaim
    function revokeClaim(uint256 _claimId) external onlyDAO {
        Claim storage claim = claims[_claimId];
        require(claim.createdTimestamp != 0, "VRN: Claim does not exist");
        require(claim.status == ClaimStatus.Verified, "VRN: Only verified claims can be revoked");
        
        claim.status = ClaimStatus.Revoked;
        claimSBT.burn(_claimId); // Burn the SBT upon revocation
        calculateUserReputationScore(claim.recipient);
        emit ClaimRevoked(_claimId, _msgSender());
    }

    // --- III. Skill Proficiency Management (Dynamic SBTs) ---

    // 13. registerSkillType
    function registerSkillType(string memory _name, string memory _description, uint256 _initialReputationImpact) external onlyDAO returns (uint256) {
        _skillTypeIds.increment();
        uint256 newId = _skillTypeIds.current();
        skillTypes[newId] = SkillType({
            name: _name,
            description: _description,
            initialReputationImpact: _initialReputationImpact,
            currentWeight: 100, // Default weight 100%
            isActive: true
        });
        emit SkillTypeRegistered(newId, _name, _initialReputationImpact);
        return newId;
    }

    // 14. mintSkillProficiency
    function mintSkillProficiency(address _recipient, uint256 _skillTypeId, string memory _metadataURI) external onlyDAO nonReentrant {
        SkillType storage sType = skillTypes[_skillTypeId];
        require(sType.isActive, "VRN: Skill type is not active");
        require(_recipient != address(0), "VRN: Recipient cannot be zero address");

        // Ensure user doesn't already have this skill proficiency
        for (uint256 i = 0; i < userSkills[_recipient].length; i++) {
            if (skillProficiencies[userSkills[_recipient][i]].skillTypeId == _skillTypeId) {
                revert("VRN: User already has this skill proficiency");
            }
        }

        _skillTokenIds.increment();
        uint256 newSkillTokenId = _skillTokenIds.current();

        skillProficiencies[newSkillTokenId] = SkillProficiency({
            skillTypeId: _skillTypeId,
            recipient: _recipient,
            metadataURI: _metadataURI,
            level: 1, // Start at level 1
            experiencePoints: 0,
            lastUpdated: block.timestamp
        });

        userSkills[_recipient].push(newSkillTokenId);
        skillSBT.mint(_recipient, newSkillTokenId);

        calculateUserReputationScore(_recipient);
        emit SkillProficiencyMinted(newSkillTokenId, _skillTypeId, _recipient, _metadataURI);
    }

    // 15. levelUpSkillProficiency
    function levelUpSkillProficiency(uint256 _skillTokenId, uint256 _levelIncrease) external nonReentrant {
        SkillProficiency storage skill = skillProficiencies[_skillTokenId];
        require(skill.skillTypeId != 0, "VRN: Skill proficiency does not exist");
        require(skill.recipient == _msgSender() || _msgSender() == owner(), "VRN: Only recipient or owner can level up skill");
        require(_levelIncrease > 0, "VRN: Level increase must be positive");

        // Advanced logic could be here, e.g.:
        // - require(hasSufficientNewClaims(_msgSender(), skill.skillTypeId, skill.lastUpdated));
        // - require(daoVotedForLevelUp(_skillTokenId, _levelIncrease));
        // For this example, we'll allow the owner to trigger, simplifying the complex validation for brevity.
        require(_msgSender() == owner(), "VRN: Only owner can manually level up skill for now.");

        skill.level += _levelIncrease;
        skill.lastUpdated = block.timestamp;

        calculateUserReputationScore(skill.recipient);
        emit SkillProficiencyLeveledUp(_skillTokenId, skill.level, _levelIncrease);
    }

    // 16. getSkillProficiencyDetails
    function getSkillProficiencyDetails(uint256 _skillTokenId) external view returns (SkillType memory, SkillProficiency memory) {
        require(skillProficiencies[_skillTokenId].skillTypeId != 0, "VRN: Skill proficiency does not exist");
        return (skillTypes[skillProficiencies[_skillTokenId].skillTypeId], skillProficiencies[_skillTokenId]);
    }

    // 17. getSkillsByOwner
    function getSkillsByOwner(address _owner) external view returns (uint256[] memory) {
        return userSkills[_owner];
    }

    // 18. decaySkillProficiency
    function decaySkillProficiency(uint256 _skillTokenId, uint256 _decayAmount) external onlyDAO nonReentrant {
        SkillProficiency storage skill = skillProficiencies[_skillTokenId];
        require(skill.skillTypeId != 0, "VRN: Skill proficiency does not exist");
        require(_decayAmount > 0, "VRN: Decay amount must be positive");
        require(skill.level > _decayAmount, "VRN: Decay amount too high, would result in negative or zero level");

        // This function could be called periodically by a Keeper network or DAO
        // to simulate skill decay over time if not actively updated or used.
        skill.level -= _decayAmount;
        skill.lastUpdated = block.timestamp; // Update last updated timestamp even for decay

        calculateUserReputationScore(skill.recipient);
        emit SkillProficiencyDecayed(_skillTokenId, skill.level, _decayAmount);
    }

    // --- IV. Reputation Scoring ---

    // 19. calculateUserReputationScore
    function calculateUserReputationScore(address _user) public nonReentrant {
        uint256 score = 0;

        // Sum contributions from verified claims
        uint256[] memory userClaimIds = userClaims[_user];
        for (uint256 i = 0; i < userClaimIds.length; i++) {
            uint256 claimId = userClaimIds[i];
            Claim storage claim = claims[claimId];
            if (claim.status == ClaimStatus.Verified) {
                ClaimType storage cType = claimTypes[claim.claimTypeId];
                score += (cType.baseReputationImpact * cType.currentWeight) / 100; // Apply weight
            }
        }

        // Sum contributions from skill proficiencies
        uint256[] memory userSkillIds = userSkills[_user];
        for (uint256 i = 0; i < userSkillIds.length; i++) {
            uint256 skillTokenId = userSkillIds[i];
            SkillProficiency storage skill = skillProficiencies[skillTokenId];
            SkillType storage sType = skillTypes[skill.skillTypeId];
            score += (sType.initialReputationImpact * skill.level * sType.currentWeight) / 100; // Level and weight impact
        }

        userReputationScores[_user] = score;
        emit ReputationScoreCalculated(_user, score);
    }

    // 20. getUserReputationScore
    function getUserReputationScore(address _user) public view returns (uint256) {
        return userReputationScores[_user];
    }

    // 21. setClaimTypeWeight
    function setClaimTypeWeight(uint256 _claimTypeId, uint256 _newWeight) external onlyDAO {
        require(claimTypes[_claimTypeId].isActive, "VRN: Claim type is not active");
        require(_newWeight <= 1000, "VRN: Weight must be 0-1000 (1000 = 10x impact)");
        claimTypes[_claimTypeId].currentWeight = _newWeight;
        emit ClaimTypeWeightSet(_claimTypeId, _newWeight);
    }

    // 22. setSkillTypeWeight
    function setSkillTypeWeight(uint256 _skillTypeId, uint256 _newWeight) external onlyDAO {
        require(skillTypes[_skillTypeId].isActive, "VRN: Skill type is not active");
        require(_newWeight <= 1000, "VRN: Weight must be 0-1000 (1000 = 10x impact)");
        skillTypes[_skillTypeId].currentWeight = _newWeight;
        emit SkillTypeWeightSet(_skillTypeId, _newWeight);
    }

    // --- V. Decentralized Autonomous Organization (DAO) Governance ---

    // Internal helper to get voter's actual reputation power (considering delegation)
    function _getVotingPower(address _voter) internal view returns (uint256) {
        address trueVoter = delegatedVotes[_voter] == address(0) ? _voter : delegatedVotes[_voter];
        return userReputationScores[trueVoter];
    }

    // 23. createProposal
    function createProposal(string memory _description, bytes memory _callData, uint256 _votingPeriodDays) external nonReentrant returns (uint256) {
        require(getUserReputationScore(_msgSender()) >= minReputationForProposal, "VRN: Insufficient reputation to create proposal");
        require(_votingPeriodDays > 0, "VRN: Voting period must be positive");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId] = Proposal({
            id: newId,
            description: _description,
            callData: _callData,
            proposer: _msgSender(),
            createdTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + (_votingPeriodDays * 1 days),
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(newId, _description, _msgSender());
        return newId;
    }

    // 24. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.createdTimestamp != 0, "VRN: Proposal does not exist");
        require(block.timestamp <= proposal.expirationTimestamp, "VRN: Voting period has ended");
        require(!hasVoted[_msgSender()][_proposalId], "VRN: Already voted on this proposal");

        uint256 voterPower = _getVotingPower(_msgSender());
        require(voterPower > 0, "VRN: Voter has no reputation power or is not delegated");

        if (_support) {
            proposal.yayVotes += voterPower;
        } else {
            proposal.nayVotes += voterPower;
        }

        hasVoted[_msgSender()][_proposalId] = true;
        emit VoteCast(_proposalId, _msgSender(), _support, voterPower);
    }

    // 25. delegateVote
    function delegateVote(address _delegatee) external {
        require(_delegatee != _msgSender(), "VRN: Cannot delegate to self");
        require(delegatedVotes[_msgSender()] == address(0), "VRN: Already delegated votes. Undelegate first.");
        delegatedVotes[_msgSender()] = _delegatee;
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    // 26. undelegateVote
    function undelegateVote() external {
        require(delegatedVotes[_msgSender()] != address(0), "VRN: No active delegation to undelegate");
        delete delegatedVotes[_msgSender()];
        emit VoteUndelegated(_msgSender());
    }

    // 27. executeProposal
    function executeProposal(uint256 _proposalId) external nonReentrant onlyDAO { // Only DAO can trigger execution after check
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.createdTimestamp != 0, "VRN: Proposal does not exist");
        require(block.timestamp > proposal.expirationTimestamp, "VRN: Voting period not yet ended");
        require(!proposal.executed, "VRN: Proposal already executed");

        bool passed = proposal.yayVotes > proposal.nayVotes;
        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            // Execute the proposed callData by calling itself with the encoded data
            (bool success, bytes memory result) = address(this).call(proposal.callData);
            emit ProposalExecuted(_proposalId, success);
            require(success, string(abi.encodePacked("VRN: Proposal execution failed: ", result)));
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // --- VI. Public Goods Funding (Reputation-Weighted Quadratic Funding) ---

    // 28. proposePublicGood
    function proposePublicGood(string memory _projectTitle, string memory _descriptionURI, address _recipient) external returns (uint256) {
        require(getUserReputationScore(_msgSender()) >= minReputationForProposal, "VRN: Insufficient reputation to propose public good");
        require(_recipient != address(0), "VRN: Recipient cannot be zero address");

        _publicGoodProjectIds.increment();
        uint256 newId = _publicGoodProjectIds.current();

        publicGoodProjects[newId] = PublicGoodProject({
            id: newId,
            title: _projectTitle,
            descriptionURI: _descriptionURI,
            recipient: _recipient,
            totalContributions: 0,
            funded: false,
            active: true
        });

        emit PublicGoodProposed(newId, _projectTitle, _recipient, _msgSender());
        return newId;
    }

    // 29. contributeToPublicGood
    function contributeToPublicGood(uint256 _projectId) external payable nonReentrant {
        PublicGoodProject storage project = publicGoodProjects[_projectId];
        require(project.id != 0, "VRN: Project does not exist");
        require(project.active, "VRN: Project is not active");
        require(msg.value > 0, "VRN: Contribution must be greater than zero");

        project.contributions[_msgSender()] += msg.value;
        project.totalContributions += msg.value;
        publicGoodFundingMatchPool += msg.value; // Add to a general pool that can be used for match funding later

        emit PublicGoodContributed(_projectId, _msgSender(), msg.value);
    }

    // 30. allocateQuadraticFunds
    // This is a simplified allocation for demonstration purposes. A full, gas-efficient on-chain quadratic funding
    // implementation for a large number of contributors is highly complex and often involves off-chain computation
    // with on-chain verification/execution.
    // Here, we simulate by allowing the DAO to allocate the collected direct contributions plus a specified
    // 'match amount' from the general `publicGoodFundingMatchPool`. The DAO's decision to allocate
    // `_matchAmountFromDAO` would ideally be informed by off-chain quadratic funding calculations
    // based on `project.contributions` and `userReputationScores`.
    function allocateQuadraticFunds(uint256 _projectId, uint256 _matchAmountFromDAO) external payable onlyDAO nonReentrant {
        PublicGoodProject storage project = publicGoodProjects[_projectId];
        require(project.id != 0, "VRN: Project does not exist");
        require(project.active, "VRN: Project is not active");
        require(!project.funded, "VRN: Project already funded");
        
        // If additional ETH is sent with this call, add it to the match pool
        if (msg.value > 0) {
            publicGoodFundingMatchPool += msg.value;
        }

        require(publicGoodFundingMatchPool >= _matchAmountFromDAO, "VRN: Insufficient match pool for specified match amount");
        
        uint256 amountToTransfer = project.totalContributions + _matchAmountFromDAO;
        
        // Decrement the match pool by the allocated match amount
        publicGoodFundingMatchPool -= _matchAmountFromDAO;

        project.funded = true;
        project.active = false; // Project is now funded and no longer active for contributions

        (bool sent, ) = project.recipient.call{value: amountToTransfer}("");
        require(sent, "VRN: Failed to send funds to project recipient");

        emit PublicGoodFundsAllocated(_projectId, amountToTransfer, _matchAmountFromDAO);
    }

    // 31. Fallback function to receive Ether for the general match pool
    receive() external payable {
        publicGoodFundingMatchPool += msg.value;
    }
}
```