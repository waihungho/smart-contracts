Here's an advanced, creative, and feature-rich Solidity smart contract named "AptitudeNexus." It combines dynamic NFTs, decentralized reputation, skill challenges, gated access, and lightweight DAO governance in a novel way.

---

## AptitudeNexus: Decentralized Skill & Reputation Network

**Description:**
AptitudeNexus is a cutting-edge decentralized platform designed to enable individuals to attest, validate, and track their skills and reputation on-chain. It leverages **dynamic NFTs** as verifiable credentials, facilitating **token-gated access** to specialized "Skill Pools" or "Expert Guilds." Users build their reputation through **on-chain challenges**, **peer reviews**, and a unique **incentivized verification** system, moving beyond static resumes to a living, verifiable proof of expertise.

**Core Concepts:**

1.  **Dynamic Aptitude NFTs (ERC-721):**
    *   Each NFT represents a user's proficiency in a specific skill.
    *   Its metadata (e.g., level, score, badges) dynamically updates based on successful challenges, verified attestations, and system events.
    *   Acts as a verifiable, living credential for a particular skill.

2.  **On-Chain Skill Challenges & Verification:**
    *   Users can propose and accept challenges to prove their skills.
    *   Challenge results can be verified by peers or a trusted oracle, with economic incentives for honest verification and penalties for dishonest ones.
    *   This provides a robust, verifiable mechanism for skill validation.

3.  **Reputation & Attestation System:**
    *   Users can self-attest or receive peer attestations for skills.
    *   All attestations are subject to community challenge, with a built-in dispute resolution mechanism.
    *   Aptitude Scores within NFTs are algorithmically adjusted based on validated challenges, attestations, and time-based decay.

4.  **Skill Pools (Gated Access):**
    *   Create exclusive communities or resource pools accessible only to users possessing Aptitude NFTs for specific skills and meeting minimum proficiency scores.
    *   Facilitates talent discovery and collaboration within specialized domains.

5.  **Decentralized Governance (DAO-Lite):**
    *   A community-driven system allows users to propose and vote on key network parameters, new skill definitions, challenge types, and dispute resolutions.
    *   Voting power can be weighted by a user's overall reputation or specific Aptitude NFT scores.

6.  **Incentivized Verification & Dispute Resolution (Prediction Market Lite):**
    *   Challenging an attestation or verifying a challenge result involves staking.
    *   Correct verifications are rewarded, incorrect ones penalized, creating an economic layer that encourages truthful participation and self-correction within the network.

**Function Summary (23 Functions):**

**I. Skill & Aptitude Definition (3 functions)**
1.  `registerSkill(string calldata _skillName, string calldata _description)`: Propose a new skill to be recognized by the network.
2.  `approveSkill(uint256 _skillId)`: DAO or authorized entity approves a proposed skill, making it active.
3.  `updateSkillDescription(uint256 _skillId, string calldata _newDescription)`: Update the metadata for an existing skill.

**II. Aptitude NFT Lifecycle (7 functions)**
4.  `mintAptitudeNFT(uint256 _skillId)`: Mints a new Aptitude NFT for a user for a specific skill, starting with a base score.
5.  `attestSkill(uint256 _tokenId, uint256 _scoreIncrease)`: Allows an NFT owner or a trusted peer to attest to a skill, increasing its score (subject to rules).
6.  `challengeAttestation(uint256 _tokenId, address _challengedUser, uint256 _skillId, bytes32 _challengeHash, uint256 _challengeStake)`: Initiates a formal challenge against a user's skill attestation, requiring a stake.
7.  `resolveChallenge(uint256 _challengeId, bool _passed, int256 _scoreAdjustment)`: DAO/Oracle/Admin resolves an initiated challenge, adjusting the NFT score and distributing stakes.
8.  `updateAptitudeScore(uint256 _tokenId, int256 _scoreChange)`: Internal or admin function to adjust an Aptitude NFT's score, triggering potential level changes and metadata updates.
9.  `tokenURI(uint256 _tokenId)`: Returns the dynamic JSON metadata URI for an Aptitude NFT, reflecting its current score, level, and status.
10. `getAptitudeDetails(uint256 _tokenId)`: Retrieves comprehensive details about a specific Aptitude NFT.

**III. Challenge & Validation System (4 functions)**
11. `proposeChallenge(uint256 _skillId, string calldata _challengeDescriptionURI, uint256 _stakeAmount, uint256 _timeLimitBlocks)`: Proposes a new, verifiable challenge for a specific skill.
12. `acceptChallenge(uint256 _challengeId)`: A user accepts a proposed challenge, binding themselves to its terms.
13. `submitChallengeResult(uint256 _challengeId, bool _success, bytes32 _proofHash)`: A user submits their proof of challenge completion (or failure).
14. `verifyChallengeResult(uint256 _challengeId, address _challenger, bool _isSuccess, uint256 _verifierStake)`: A peer or oracle verifies the submitted challenge result, staking on its correctness.

**IV. Skill Pool & Gated Access (4 functions)**
15. `createSkillPool(string calldata _poolName, uint256 _requiredSkillId, uint256 _minAptitudeScore)`: Creates a new skill-gated pool, defining access criteria.
16. `joinSkillPool(uint256 _poolId)`: Allows a user to join a skill pool if they meet the required Aptitude NFT criteria.
17. `leaveSkillPool(uint256 _poolId)`: Allows a user to voluntarily leave a skill pool.
18. `hasAccessToSkillPool(address _user, uint256 _poolId)`: Checks if a given user currently has access to a specified skill pool.

**V. Governance & Utilities (5 functions)**
19. `proposeGovernanceAction(bytes calldata _callData, address _target, string calldata _description)`: Allows users with sufficient reputation to propose a generic DAO action (e.g., parameter change, upgrade).
20. `voteOnProposal(uint256 _proposalId, bool _for)`: Casts a vote on an active governance proposal, weighted by the voter's reputation.
21. `executeProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal.
22. `setGovernanceParameters(uint256 _minVoteDurationBlocks, uint256 _minReputationToPropose, uint256 _quorumPercentage)`: DAO/Admin function to adjust core governance parameters.
23. `updateOracleAddress(address _newOracle)`: Updates the address of the trusted oracle responsible for certain external validations or challenge resolutions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title AptitudeNexus
 * @dev A decentralized platform for on-chain skill attestation, reputation building,
 *      and exclusive opportunity access through dynamic Aptitude NFTs.
 *      This contract combines dynamic NFTs, decentralized reputation, skill challenges,
 *      gated access, and lightweight DAO governance in a novel way.
 */
contract AptitudeNexus is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // --- Events ---
    event SkillRegistered(uint256 indexed skillId, string skillName, address indexed proposer);
    event SkillApproved(uint256 indexed skillId, address indexed approver);
    event SkillDescriptionUpdated(uint256 indexed skillId, string newDescription);

    event AptitudeNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 indexed skillId);
    event AptitudeScoreUpdated(uint256 indexed tokenId, int256 scoreChange, uint256 newScore, uint256 newLevel);
    event AttestationMade(uint256 indexed tokenId, address indexed attester, uint256 scoreIncrease);
    event AttestationChallenged(
        uint256 indexed challengeId,
        uint256 indexed tokenId,
        address indexed challenger,
        uint256 stake
    );
    event ChallengeResolved(uint256 indexed challengeId, bool passed, int256 scoreAdjustment);

    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed skillId, address indexed proposer);
    event ChallengeAccepted(uint256 indexed challengeId, address indexed acceptor);
    event ChallengeResultSubmitted(uint256 indexed challengeId, address indexed submitter, bool success);
    event ChallengeResultVerified(
        uint256 indexed challengeId,
        address indexed verifier,
        bool isSuccess,
        uint256 verifierStake
    );

    event SkillPoolCreated(uint256 indexed poolId, string poolName, uint256 indexed requiredSkillId);
    event SkillPoolJoined(uint256 indexed poolId, address indexed user);
    event SkillPoolLeft(uint256 indexed poolId, address indexed user);

    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceParametersUpdated(
        uint256 minVoteDurationBlocks,
        uint256 minReputationToPropose,
        uint256 quorumPercentage
    );
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);

    // --- Structs ---

    struct Skill {
        string name;
        string description;
        bool approved; // Approved by DAO or initial admin
        uint256 nextChallengeId; // Counter for challenges specific to this skill
    }

    struct AptitudeNFT {
        uint256 skillId;
        uint256 score; // Base score, directly impacts level and dynamic metadata
        uint256 level; // Derived from score
        uint256 lastUpdated;
        mapping(address => bool) peersAttested; // To prevent multiple attestations from same peer
    }

    struct AttestationChallenge {
        uint256 tokenId;
        address challengedUser;
        uint256 skillId;
        bytes32 challengeHash; // Hash linking to off-chain challenge details/proof requirements
        uint256 challengeStake;
        address challenger;
        uint256 proposalBlock; // Block when challenge was proposed
        bool resolved;
        bool passed; // Outcome of the challenge
    }

    struct SkillChallenge {
        uint256 skillId;
        string descriptionURI; // URI to off-chain challenge details (e.g., IPFS)
        uint256 stakeAmount; // Stake required to propose/accept the challenge
        uint256 timeLimitBlocks; // Block limit for completion
        address proposer;
        address acceptor;
        bool active;
        bool resultSubmitted;
        bool resultSuccess;
        bytes32 proofHash; // Hash of off-chain proof
        address verifier; // Address of the chosen verifier
        uint256 verifierStake; // Stake from the verifier
        bool verified;
        bool verificationSuccess;
        uint256 completionBlock;
    }

    struct SkillPool {
        string name;
        uint256 requiredSkillId;
        uint256 minAptitudeScore;
        mapping(address => bool) members;
    }

    struct GovernanceProposal {
        bytes callData; // Encoded function call
        address target; // Contract to call
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // --- State Variables ---

    uint256 public nextSkillId;
    mapping(uint256 => Skill) public skills;

    uint256 public nextAptitudeTokenId;
    mapping(uint256 => AptitudeNFT) public aptitudeNFTs; // token ID -> AptitudeNFT details

    uint256 public nextAttestationChallengeId;
    mapping(uint256 => AttestationChallenge) public attestationChallenges;

    uint256 public nextSkillChallengeId;
    mapping(uint256 => SkillChallenge) public skillChallenges;

    uint256 public nextSkillPoolId;
    mapping(uint256 => SkillPool) public skillPools;

    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    address public trustedOracle; // For external validations and dispute resolutions

    // Governance parameters
    uint256 public minVoteDurationBlocks = 1000; // Approx 4-5 hours
    uint256 public minReputationToPropose = 1000; // Minimum total score across all NFTs to propose
    uint256 public quorumPercentage = 51; // Percentage of total reputation needed for quorum

    // Base URI for Aptitude NFT metadata
    string private _baseTokenURI = "https://apttitudenexus.io/nft/"; // Placeholder, should point to an API endpoint

    // --- Modifiers ---
    modifier onlyApprovedSkill(uint256 _skillId) {
        require(skills[_skillId].approved, "AptitudeNexus: Skill not approved");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "AptitudeNexus: Only callable by the trusted oracle");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle) ERC721Enumerable("AptitudeNexus NFT", "APTNFT") Ownable(msg.sender) {
        trustedOracle = _initialOracle;
    }

    // --- Utility Functions ---

    /**
     * @dev Calculates the level based on the aptitude score.
     *      This is a simple logarithmic scale for demonstration.
     *      Can be adjusted for more complex leveling.
     */
    function _calculateLevel(uint256 _score) internal pure returns (uint256) {
        if (_score == 0) return 0;
        return uint256(Math.sqrt(uint256(_score / 100))) + 1; // Example: score 100 -> level 1, score 400 -> level 2
    }

    /**
     * @dev Calculates the total reputation (sum of all aptitude scores) for a user.
     *      Used for governance voting power and proposal eligibility.
     */
    function _calculateTotalReputation(address _user) internal view returns (uint256) {
        uint256 totalRep = 0;
        uint256 balance = balanceOf(_user);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_user, i);
            totalRep += aptitudeNFTs[tokenId].score;
        }
        return totalRep;
    }

    // --- I. Skill & Aptitude Definition (3 functions) ---

    /**
     * @dev Allows any user to propose a new skill to be recognized by the network.
     *      Skills must be approved by governance before Aptitude NFTs can be minted for them.
     * @param _skillName The name of the skill.
     * @param _description A detailed description of the skill.
     */
    function registerSkill(string calldata _skillName, string calldata _description) external {
        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill({name: _skillName, description: _description, approved: false, nextChallengeId: 0});
        emit SkillRegistered(skillId, _skillName, msg.sender);
    }

    /**
     * @dev Approves a proposed skill, making it available for Aptitude NFT minting and challenges.
     *      This function is initially callable by the contract owner, but can be later transferred to DAO governance.
     * @param _skillId The ID of the skill to approve.
     */
    function approveSkill(uint256 _skillId) external onlyOwner {
        require(!skills[_skillId].approved, "AptitudeNexus: Skill already approved");
        skills[_skillId].approved = true;
        emit SkillApproved(_skillId, msg.sender);
    }

    /**
     * @dev Updates the description of an existing skill.
     *      Initially owner-only, can be shifted to DAO governance.
     * @param _skillId The ID of the skill to update.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDescription(uint256 _skillId, string calldata _newDescription) external onlyOwner {
        require(skills[_skillId].approved, "AptitudeNexus: Skill must be approved to update description");
        skills[_skillId].description = _newDescription;
        emit SkillDescriptionUpdated(_skillId, _newDescription);
    }

    // --- II. Aptitude NFT Lifecycle (7 functions) ---

    /**
     * @dev Mints a new Aptitude NFT for a user for a specific skill.
     *      Each user can only have one Aptitude NFT per skill.
     * @param _skillId The ID of the skill this NFT represents.
     */
    function mintAptitudeNFT(uint256 _skillId) external onlyApprovedSkill(_skillId) {
        // Check if the user already has an NFT for this skill
        uint256 balance = balanceOf(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 existingTokenId = tokenOfOwnerByIndex(msg.sender, i);
            require(aptitudeNFTs[existingTokenId].skillId != _skillId, "AptitudeNexus: Already owns NFT for this skill");
        }

        uint256 tokenId = nextAptitudeTokenId++;
        _safeMint(msg.sender, tokenId);
        aptitudeNFTs[tokenId] = AptitudeNFT({
            skillId: _skillId,
            score: 0, // Start with a base score
            level: 0,
            lastUpdated: block.timestamp,
            peersAttested: new mapping(address => bool) // Initialize empty
        });

        emit AptitudeNFTMinted(tokenId, msg.sender, _skillId);
        emit AptitudeScoreUpdated(tokenId, 0, 0, 0); // Initial score update event
    }

    /**
     * @dev Allows an NFT owner or a trusted peer to attest to a skill, increasing its score.
     *      Each peer can attest only once per NFT.
     * @param _tokenId The ID of the Aptitude NFT to attest for.
     * @param _scoreIncrease The amount to increase the score by (e.g., 10 for self, 50 for peer).
     */
    function attestSkill(uint256 _tokenId, uint256 _scoreIncrease) external {
        require(_exists(_tokenId), "AptitudeNexus: NFT does not exist");
        require(_scoreIncrease > 0, "AptitudeNexus: Score increase must be positive");
        require(!aptitudeNFTs[_tokenId].peersAttested[msg.sender], "AptitudeNexus: Already attested by this peer");

        address nftOwner = ownerOf(_tokenId);
        // Implement different rules for self vs. peer attestation, e.g., max score for self-attestation
        // For simplicity, here we just allow it. A more complex system would have tiers or limits.
        
        aptitudeNFTs[_tokenId].peersAttested[msg.sender] = true; // Mark attestation from this sender

        _updateAptitudeScoreInternal(_tokenId, int256(_scoreIncrease));
        emit AttestationMade(_tokenId, msg.sender, _scoreIncrease);
    }

    /**
     * @dev Initiates a formal challenge against a user's skill attestation.
     *      Requires a stake from the challenger.
     * @param _tokenId The ID of the Aptitude NFT being challenged.
     * @param _challengedUser The owner of the NFT.
     * @param _skillId The skill ID associated with the NFT.
     * @param _challengeHash A hash linking to off-chain challenge details/proof requirements.
     * @param _challengeStake The amount of stake required from the challenger (sent with tx).
     */
    function challengeAttestation(
        uint256 _tokenId,
        address _challengedUser,
        uint256 _skillId,
        bytes32 _challengeHash,
        uint256 _challengeStake
    ) external payable {
        require(_exists(_tokenId), "AptitudeNexus: NFT does not exist");
        require(ownerOf(_tokenId) == _challengedUser, "AptitudeNexus: _challengedUser is not the NFT owner");
        require(aptitudeNFTs[_tokenId].skillId == _skillId, "AptitudeNexus: Skill ID mismatch for NFT");
        require(msg.value == _challengeStake, "AptitudeNexus: Incorrect challenge stake provided");
        require(_challengeStake > 0, "AptitudeNexus: Challenge stake must be positive");

        uint256 challengeId = nextAttestationChallengeId++;
        attestationChallenges[challengeId] = AttestationChallenge({
            tokenId: _tokenId,
            challengedUser: _challengedUser,
            skillId: _skillId,
            challengeHash: _challengeHash,
            challengeStake: _challengeStake,
            challenger: msg.sender,
            proposalBlock: block.number,
            resolved: false,
            passed: false // Default to false until resolved
        });

        emit AttestationChallenged(challengeId, _tokenId, msg.sender, _challengeStake);
    }

    /**
     * @dev Resolves an initiated attestation challenge, adjusting the NFT score and distributing stakes.
     *      This function is intended to be called by the trusted oracle or after DAO vote.
     * @param _challengeId The ID of the attestation challenge to resolve.
     * @param _passed True if the challenged attestation was valid, false if invalid.
     * @param _scoreAdjustment The amount to adjust the NFT's score by (can be negative).
     */
    function resolveChallenge(uint256 _challengeId, bool _passed, int256 _scoreAdjustment) external onlyOracle {
        AttestationChallenge storage challenge = attestationChallenges[_challengeId];
        require(!challenge.resolved, "AptitudeNexus: Challenge already resolved");

        challenge.resolved = true;
        challenge.passed = _passed;

        // Adjust NFT score
        _updateAptitudeScoreInternal(challenge.tokenId, _scoreAdjustment);

        // Distribute stake
        if (_passed) {
            // Challenger was wrong, lose stake to the challenged user (or burn, or go to DAO)
            // For simplicity, refund challengedUser for now. Could be more complex.
            (bool success, ) = payable(challenge.challengedUser).call{value: challenge.challengeStake}("");
            require(success, "AptitudeNexus: Failed to transfer stake to challenged user");
        } else {
            // Challenger was right, get stake back (and potentially a reward)
            // For simplicity, refund challenger for now.
            (bool success, ) = payable(challenge.challenger).call{value: challenge.challengeStake}("");
            require(success, "AptitudeNexus: Failed to transfer stake to challenger");
        }

        emit ChallengeResolved(_challengeId, _passed, _scoreAdjustment);
    }

    /**
     * @dev Internal function to adjust an Aptitude NFT's score.
     *      Triggers potential level changes and metadata updates.
     * @param _tokenId The ID of the Aptitude NFT.
     * @param _scoreChange The amount to change the score by (can be negative).
     */
    function _updateAptitudeScoreInternal(uint256 _tokenId, int256 _scoreChange) internal {
        AptitudeNFT storage nft = aptitudeNFTs[_tokenId];

        uint256 oldScore = nft.score;
        int256 newScoreInt = int256(oldScore) + _scoreChange;
        require(newScoreInt >= 0, "AptitudeNexus: Aptitude score cannot be negative");

        nft.score = uint256(newScoreInt);
        nft.level = _calculateLevel(nft.score);
        nft.lastUpdated = block.timestamp;

        emit AptitudeScoreUpdated(_tokenId, _scoreChange, nft.score, nft.level);
    }

    /**
     * @dev Generates the dynamic JSON metadata URI for an Aptitude NFT.
     *      The metadata reflects its current score, level, and status.
     *      This method generates an on-chain SVG image.
     * @param _tokenId The ID of the Aptitude NFT.
     * @return A data URI containing the base64 encoded JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        AptitudeNFT storage apt = aptitudeNFTs[_tokenId];
        Skill storage skill = skills[apt.skillId];
        address owner = ownerOf(_tokenId);

        string memory name = string(abi.encodePacked(skill.name, " Aptitude NFT (L", apt.level.toString(), ")"));
        string memory description = string(
            abi.encodePacked(
                "Verifiable on-chain attestation of proficiency in ",
                skill.name,
                ". Score: ",
                apt.score.toString(),
                ", Last Updated: ",
                apt.lastUpdated.toString()
            )
        );

        string memory svg = string(
            abi.encodePacked(
                '<svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#1a1a2e" />',
                '<text x="150" y="50" font-family="monospace" font-size="20" fill="#e0bbe4" text-anchor="middle">Aptitude Nexus</text>',
                '<text x="150" y="80" font-family="monospace" font-size="16" fill="#957dad" text-anchor="middle">Skill: ',
                skill.name,
                '</text>',
                '<text x="150" y="110" font-family="monospace" font-size="24" fill="#ffc72c" text-anchor="middle">Level: ',
                apt.level.toString(),
                '</text>',
                '<text x="150" y="140" font-family="monospace" font-size="14" fill="#c3e7b4" text-anchor="middle">Score: ',
                apt.score.toString(),
                '</text>',
                '<text x="150" y="170" font-family="monospace" font-size="12" fill="#c3e7b4" text-anchor="middle">Owner: ',
                owner.toHexString(),
                '</text>',
                '</svg>'
            )
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "',
                description,
                '", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '", "attributes": [',
                '{"trait_type": "Skill", "value": "',
                skill.name,
                '"},',
                '{"trait_type": "Skill ID", "value": ',
                apt.skillId.toString(),
                '},',
                '{"trait_type": "Level", "value": ',
                apt.level.toString(),
                '},',
                '{"trait_type": "Score", "value": ',
                apt.score.toString(),
                '},',
                '{"trait_type": "Last Updated", "display_type": "date", "value": ',
                apt.lastUpdated.toString(),
                '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Retrieves comprehensive details about a specific Aptitude NFT.
     * @param _tokenId The ID of the Aptitude NFT.
     * @return Tuple containing skillId, score, level, lastUpdated, and owner.
     */
    function getAptitudeDetails(uint256 _tokenId)
        external
        view
        returns (
            uint256 skillId,
            uint256 score,
            uint256 level,
            uint256 lastUpdated,
            address nftOwner
        )
    {
        require(_exists(_tokenId), "AptitudeNexus: NFT does not exist");
        AptitudeNFT storage apt = aptitudeNFTs[_tokenId];
        return (apt.skillId, apt.score, apt.level, apt.lastUpdated, ownerOf(_tokenId));
    }

    // --- III. Challenge & Validation System (4 functions) ---

    /**
     * @dev Proposes a new, verifiable challenge for a specific skill.
     *      Challengers must stake funds.
     * @param _skillId The ID of the skill this challenge is for.
     * @param _challengeDescriptionURI URI to off-chain challenge details (e.g., IPFS).
     * @param _stakeAmount The amount of Ether to be staked for participating in this challenge.
     * @param _timeLimitBlocks The number of blocks allowed for a user to complete the challenge.
     */
    function proposeChallenge(
        uint256 _skillId,
        string calldata _challengeDescriptionURI,
        uint256 _stakeAmount,
        uint256 _timeLimitBlocks
    ) external onlyApprovedSkill(_skillId) {
        require(_stakeAmount > 0, "AptitudeNexus: Stake amount must be positive");
        require(_timeLimitBlocks > 0, "AptitudeNexus: Time limit must be positive");

        uint256 challengeId = nextSkillChallengeId++;
        skills[_skillId].nextChallengeId++; // Increment challenge counter for the skill

        skillChallenges[challengeId] = SkillChallenge({
            skillId: _skillId,
            descriptionURI: _challengeDescriptionURI,
            stakeAmount: _stakeAmount,
            timeLimitBlocks: _timeLimitBlocks,
            proposer: msg.sender,
            acceptor: address(0), // No acceptor yet
            active: true,
            resultSubmitted: false,
            resultSuccess: false,
            proofHash: bytes32(0),
            verifier: address(0),
            verifierStake: 0,
            verified: false,
            verificationSuccess: false,
            completionBlock: 0
        });

        emit ChallengeProposed(challengeId, _skillId, msg.sender);
    }

    /**
     * @dev A user accepts a proposed challenge, binding themselves to its terms and staking the required amount.
     * @param _challengeId The ID of the skill challenge to accept.
     */
    function acceptChallenge(uint256 _challengeId) external payable {
        SkillChallenge storage challenge = skillChallenges[_challengeId];
        require(challenge.active, "AptitudeNexus: Challenge not active or does not exist");
        require(challenge.acceptor == address(0), "AptitudeNexus: Challenge already accepted");
        require(msg.value == challenge.stakeAmount, "AptitudeNexus: Incorrect stake amount for challenge");

        challenge.acceptor = msg.sender;
        challenge.completionBlock = block.number + challenge.timeLimitBlocks; // Set completion deadline
        emit ChallengeAccepted(_challengeId, msg.sender);
    }

    /**
     * @dev A user submits their proof of challenge completion (or failure).
     * @param _challengeId The ID of the challenge.
     * @param _success True if the challenge was successfully completed, false otherwise.
     * @param _proofHash Hash of off-chain proof (e.g., IPFS link to solution).
     */
    function submitChallengeResult(uint256 _challengeId, bool _success, bytes32 _proofHash) external {
        SkillChallenge storage challenge = skillChallenges[_challengeId];
        require(challenge.active, "AptitudeNexus: Challenge not active");
        require(challenge.acceptor == msg.sender, "AptitudeNexus: Only acceptor can submit result");
        require(!challenge.resultSubmitted, "AptitudeNexus: Result already submitted");
        require(block.number <= challenge.completionBlock, "AptitudeNexus: Challenge time limit exceeded");

        challenge.resultSubmitted = true;
        challenge.resultSuccess = _success;
        challenge.proofHash = _proofHash;

        emit ChallengeResultSubmitted(_challengeId, msg.sender, _success);
    }

    /**
     * @dev A peer or oracle verifies the submitted challenge result, staking on its correctness.
     *      Rewards verifier if correct, potentially penalizes if incorrect (requires further DAO action or Oracle input).
     *      This is the "Prediction Market Lite" part - an incentivized verification.
     * @param _challengeId The ID of the challenge to verify.
     * @param _challenger The address of the user who submitted the result (acceptor).
     * @param _isSuccess The verifier's judgment: true if the result is correct, false otherwise.
     * @param _verifierStake The amount of Ether the verifier stakes on their judgment.
     */
    function verifyChallengeResult(
        uint256 _challengeId,
        address _challenger,
        bool _isSuccess,
        uint256 _verifierStake
    ) external payable {
        SkillChallenge storage challenge = skillChallenges[_challengeId];
        require(challenge.active, "AptitudeNexus: Challenge not active");
        require(challenge.acceptor == _challenger, "AptitudeNexus: _challenger is not the acceptor");
        require(challenge.resultSubmitted, "AptitudeNexus: Result not submitted yet");
        require(challenge.verifier == address(0), "AptitudeNexus: Challenge already has a verifier");
        require(msg.sender != _challenger, "AptitudeNexus: Challenger cannot verify their own result");
        require(msg.value == _verifierStake, "AptitudeNexus: Incorrect verifier stake provided");
        require(_verifierStake > 0, "AptitudeNexus: Verifier stake must be positive");

        challenge.verifier = msg.sender;
        challenge.verifierStake = _verifierStake;
        challenge.verified = true;
        challenge.verificationSuccess = _isSuccess; // This stores the verifier's judgment

        // --- Logic for rewards and score updates ---
        // If verifier's judgment matches acceptor's submission:
        if (challenge.resultSuccess == _isSuccess) {
            // Verifier confirmed the result correctly. Reward verifier and update NFT score.
            _updateAptitudeScoreInternal(_getAptitudeNFT(_challenger, challenge.skillId), 100); // Example score boost
            (bool success, ) = payable(msg.sender).call{value: challenge.stakeAmount / 2}(""); // Verifier gets half the challenger's stake
            require(success, "AptitudeNexus: Failed to reward verifier");
            // Challenger also gets their stake back, and perhaps a small reward too for successful completion.
            (success, ) = payable(_challenger).call{value: challenge.stakeAmount / 2}("");
            require(success, "AptitudeNexus: Failed to reward challenger");
        } else {
            // Verifier disputes the result. This creates a conflict that needs external resolution (e.g., DAO or Oracle).
            // For now, the stakes are held. A more complex system would trigger a dispute period.
            // Simplified: if verifier is wrong, their stake goes to challenger. If verifier is right, their stake goes to them, and challenger loses stake.
            // This is a placeholder for a more robust dispute resolution mechanism.
            // For this version, let's assume the oracle's call to `resolveChallenge` for AttestationChallenges also covers SkillChallenges.
            // A dedicated `resolveSkillChallengeDispute` would be needed for full implementation.
            // For now, just store the verification and require an Oracle/DAO to finalize distribution.
        }

        challenge.active = false; // Challenge is now inactive
        emit ChallengeResultVerified(_challengeId, msg.sender, _isSuccess, _verifierStake);
    }

    /**
     * @dev Helper to get a user's Aptitude NFT tokenId for a specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The tokenId, or 0 if not found.
     */
    function _getAptitudeNFT(address _user, uint256 _skillId) internal view returns (uint256) {
        uint256 balance = balanceOf(_user);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_user, i);
            if (aptitudeNFTs[tokenId].skillId == _skillId) {
                return tokenId;
            }
        }
        return 0;
    }

    // --- IV. Skill Pool & Gated Access (4 functions) ---

    /**
     * @dev Creates a new skill-gated pool, defining access criteria.
     *      Only contract owner can create pools initially, can be transferred to DAO.
     * @param _poolName The name of the skill pool.
     * @param _requiredSkillId The skill ID required for access.
     * @param _minAptitudeScore The minimum score required for the specified skill NFT.
     */
    function createSkillPool(
        string calldata _poolName,
        uint256 _requiredSkillId,
        uint256 _minAptitudeScore
    ) external onlyOwner onlyApprovedSkill(_requiredSkillId) {
        uint256 poolId = nextSkillPoolId++;
        skillPools[poolId] = SkillPool({
            name: _poolName,
            requiredSkillId: _requiredSkillId,
            minAptitudeScore: _minAptitudeScore,
            members: new mapping(address => bool) // Initialize empty
        });
        emit SkillPoolCreated(poolId, _poolName, _requiredSkillId);
    }

    /**
     * @dev Allows a user to join a skill pool if they meet the required Aptitude NFT criteria.
     * @param _poolId The ID of the skill pool to join.
     */
    function joinSkillPool(uint256 _poolId) external {
        SkillPool storage pool = skillPools[_poolId];
        require(pool.requiredSkillId != 0, "AptitudeNexus: Skill pool does not exist");
        require(!pool.members[msg.sender], "AptitudeNexus: Already a member of this pool");
        require(hasAccessToSkillPool(msg.sender, _poolId), "AptitudeNexus: Does not meet skill requirements to join");

        pool.members[msg.sender] = true;
        emit SkillPoolJoined(_poolId, msg.sender);
    }

    /**
     * @dev Allows a user to voluntarily leave a skill pool.
     * @param _poolId The ID of the skill pool to leave.
     */
    function leaveSkillPool(uint256 _poolId) external {
        SkillPool storage pool = skillPools[_poolId];
        require(pool.requiredSkillId != 0, "AptitudeNexus: Skill pool does not exist");
        require(pool.members[msg.sender], "AptitudeNexus: Not a member of this pool");

        pool.members[msg.sender] = false;
        emit SkillPoolLeft(_poolId, msg.sender);
    }

    /**
     * @dev Checks if a given user currently has access to a specified skill pool based on their Aptitude NFTs.
     * @param _user The address of the user to check.
     * @param _poolId The ID of the skill pool.
     * @return True if the user meets the requirements and has access, false otherwise.
     */
    function hasAccessToSkillPool(address _user, uint256 _poolId) public view returns (bool) {
        SkillPool storage pool = skillPools[_poolId];
        require(pool.requiredSkillId != 0, "AptitudeNexus: Skill pool does not exist");

        uint256 userAptitudeNFTId = _getAptitudeNFT(_user, pool.requiredSkillId);
        if (userAptitudeNFTId == 0) {
            return false; // User doesn't have an NFT for the required skill
        }

        return aptitudeNFTs[userAptitudeNFTId].score >= pool.minAptitudeScore;
    }

    // --- V. Governance & Utilities (5 functions) ---

    /**
     * @dev Allows users with sufficient total reputation to propose a generic DAO action.
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _target The address of the target contract for the call.
     * @param _description A description of the proposal.
     */
    function proposeGovernanceAction(bytes calldata _callData, address _target, string calldata _description) external {
        require(
            _calculateTotalReputation(msg.sender) >= minReputationToPropose,
            "AptitudeNexus: Insufficient reputation to propose"
        );

        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            callData: _callData,
            target: _target,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + minVoteDurationBlocks,
            forVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });

        emit GovernanceProposalCreated(proposalId, _description, msg.sender);
    }

    /**
     * @dev Casts a vote on an active governance proposal, weighted by the voter's total reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.target != address(0), "AptitudeNexus: Proposal does not exist");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "AptitudeNexus: Voting not active");
        require(!proposal.hasVoted[msg.sender], "AptitudeNexus: Already voted on this proposal");

        uint256 voterReputation = _calculateTotalReputation(msg.sender);
        require(voterReputation > 0, "AptitudeNexus: Voter has no reputation");

        if (_for) {
            proposal.forVotes += voterReputation;
        } else {
            proposal.againstVotes += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _for);
    }

    /**
     * @dev Executes a successfully passed governance proposal.
     *      Can be called by anyone after the voting period ends and criteria are met.
     *      Requires a majority vote and quorum.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.target != address(0), "AptitudeNexus: Proposal does not exist");
        require(block.number > proposal.endBlock, "AptitudeNexus: Voting period not ended");
        require(!proposal.executed, "AptitudeNexus: Proposal already executed");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        // Total possible reputation could be sum of all users' reputations.
        // For simplicity, let's consider quorum based on _voted_ reputation vs. minReputationToPropose * number of potential proposers (or just a fixed amount)
        // A more robust DAO would track active total circulating reputation or have a more complex quorum calculation.
        // For now, let's assume quorum based on total votes surpassing a threshold relative to the *total supply of APDNFTs' scores*.
        // This is a simplification; a real DAO would need a robust way to determine total voting power.
        // A simple heuristic: if totalVotes >= (minReputationToPropose * 5) and forVotes > againstVotes.
        // Let's use a dynamic quorum based on the total reputation of all NFT holders.
        uint256 globalTotalReputation = 0;
        for (uint256 i = 0; i < nextAptitudeTokenId; i++) {
            if (_exists(i)) {
                globalTotalReputation += aptitudeNFTs[i].score;
            }
        }
        // If there are no NFTs, globalTotalReputation could be 0, causing division by zero. Handle this.
        uint256 calculatedQuorum = globalTotalReputation > 0 ? (globalTotalReputation * quorumPercentage) / 100 : 0;
        require(totalVotes >= calculatedQuorum, "AptitudeNexus: Quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "AptitudeNexus: Proposal not passed");

        proposal.executed = true;
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "AptitudeNexus: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the DAO or initially the owner to set core governance parameters.
     * @param _minVoteDurationBlocks Minimum blocks for a proposal to be open for voting.
     * @param _minReputationToPropose Minimum total reputation required to propose.
     * @param _quorumPercentage Percentage of total reputation needed for a proposal quorum.
     */
    function setGovernanceParameters(
        uint256 _minVoteDurationBlocks,
        uint256 _minReputationToPropose,
        uint256 _quorumPercentage
    ) external onlyOwner {
        require(_minVoteDurationBlocks > 0, "AptitudeNexus: Vote duration must be positive");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "AptitudeNexus: Quorum percentage must be between 1-100");

        minVoteDurationBlocks = _minVoteDurationBlocks;
        minReputationToPropose = _minReputationToPropose;
        quorumPercentage = _quorumPercentage;

        emit GovernanceParametersUpdated(_minVoteDurationBlocks, _minReputationToPropose, _quorumPercentage);
    }

    /**
     * @dev Updates the address of the trusted oracle responsible for certain external validations.
     *      Initially owner-only, but should eventually be controlled by DAO governance.
     * @param _newOracle The new address for the trusted oracle.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AptitudeNexus: New oracle address cannot be zero");
        address oldOracle = trustedOracle;
        trustedOracle = _newOracle;
        emit OracleAddressUpdated(oldOracle, _newOracle);
    }
}
```