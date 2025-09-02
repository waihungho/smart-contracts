Here's a smart contract written in Solidity, incorporating advanced, creative, and trendy concepts while ensuring it doesn't duplicate existing open-source projects. This contract, named `DecentralizedSkillForge`, establishes a novel framework for on-chain skill verification and reputation building.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety

// Contract Name: DecentralizedSkillForge
//
// Description:
// DecentralizedSkillForge is a cutting-edge smart contract platform designed to foster a verifiable, on-chain
// reputation system for user skills and knowledge. It introduces a novel "Knowledge Capsule" mechanism
// where users commit to possessing specific knowledge or skills without immediately revealing the content.
// This commitment is then validated through a series of "Challenges" that users must complete by submitting
// verifiable "Proofs." These proofs demonstrate the skill or knowledge in a simulated zero-knowledge fashion,
// without exposing the original committed secret. Successful validation earns reputation points and allows
// users to mint Soulbound Skill NFTs (SBTs), which are non-transferable tokens representing proven expertise.
// The platform also incorporates a decentralized curation system for proposing and voting on new challenges,
// and a simplified dispute resolution mechanism.
//
// Key Advanced Concepts:
// 1.  Commitment-Reveal with Proof-of-Knowledge: Users commit a hash of private knowledge (Knowledge Capsule).
//     Verification occurs through "Challenges" where users submit "Proofs" that validate a property of their
//     knowledge (e.g., hash of a computation result) without revealing the original content, simulating ZK principles.
// 2.  Dynamic, Proof-Based Soulbound Tokens (SBTs): Skill NFTs are non-transferable and are minted only upon
//     accumulating sufficient reputation derived from successfully completing verifiable challenges. These SBTs
//     serve as verifiable, on-chain credentials of proven expertise.
// 3.  Decentralized Curation & Challenge Lifecycle: A community-driven (or curator-driven) process for proposing,
//     voting on, and deploying new skill challenges, enabling the platform to evolve dynamically.
// 4.  Reputation-Weighted Access & Governance (Simplified): Reputation points not only unlock SBTs but also
//     potentially grant privileges within the system (e.g., voting power on challenges, curator roles).
// 5.  Future AI/Oracle Integration Potential: The flexible `proofData` and `solutionHash` design allows for
//     conceptual integration with future AI oracles for automated challenge generation or complex proof evaluation.
//
// Outline:
// I. Core Data Structures & Enumerations
// II. Access Control & Modifiers
// III. ERC721 Soulbound Skill NFTs (Internal)
// IV. Knowledge Capsule Management
// V. Challenge Proposal & Curation
// VI. Challenge Execution & Proof Submission
// VII. Proof Verification & Dispute Resolution
// VIII. Reputation & Skill NFT Minting
// IX. Access Control & Configuration
// X. Utility & Getter Functions
// XI. Withdrawals
//
// Function Summary (24 Functions):
//
// I. Knowledge Capsule Management
// 1.  `commitKnowledgeCapsule(bytes32 capsuleHash, uint256 categoryId)`: Allows a user to commit to a piece of knowledge/skill by submitting its hash.
// 2.  `requestCapsuleContentUnlock(uint256 capsuleId)`: Initiates a request for a proven capsule's content to be revealed.
// 3.  `revealKnowledgeCapsule(uint256 capsuleId, bytes calldata originalContent)`: Allows the committer to reveal the original content of a verified capsule.
//
// II. Challenge Proposal & Curation
// 4.  `proposeChallenge(string memory name, string memory description, uint256 categoryId, bytes32 solutionHash, uint256 proposerRewardBPS)`: A curator proposes a new challenge with a solution hash and potential reward.
// 5.  `voteOnChallengeProposal(uint256 proposalId, bool approve)`: High-reputation users or curators vote on proposed challenges.
// 6.  `finalizeChallengeProposal(uint256 proposalId)`: Owner/Admin finalizes a challenge proposal if it meets voting criteria.
//
// III. Challenge Execution & Proof Submission
// 7.  `submitProofForChallenge(uint256 challengeId, uint256 capsuleId, bytes calldata proofData)`: A user submits a proof for a specific challenge, linking it to their knowledge capsule.
// 8.  `verifySubmittedProof(uint256 proofId)`: Owner/Curator function to verify a submitted proof against the challenge's solution hash.
//
// IV. Proof Verification & Dispute Resolution
// 9.  `disputeProof(uint256 proofId, string memory reason)`: Allows any user to dispute the validity of a submitted proof.
// 10. `resolveDispute(uint256 disputeId, bool isValidProof)`: Owner/Admin resolves a proof dispute, updating proof status and reputation.
//
// V. Reputation & Skill NFT Minting
// 11. `getReputation(address user)`: Retrieves the reputation score of a given user.
// 12. `mintSkillNFT(uint256 categoryId)`: Allows a user to mint a Soulbound Skill NFT if they meet the reputation threshold for a category.
// 13. `isSkillNFTMinted(address user, uint256 categoryId)`: Checks if a user has minted the Skill NFT for a specific category.
//
// VI. Access Control & Configuration
// 14. `setCurator(address _curator, bool _isCurator)`: Owner function to assign or revoke curator roles.
// 15. `setCategoryConfiguration(uint256 categoryId, uint256 minReputationForNFT, uint256 nftMintFee, uint256 challengeRewardReputation)`: Owner sets parameters for a skill category.
// 16. `setChallengeVerificationReward(uint256 rewardAmount)`: Owner sets the reward for curators who verify proofs.
//
// VII. Utility & Getter Functions
// 17. `getTotalChallenges()`: Returns the total number of challenges created.
// 18. `getTotalCapsules()`: Returns the total number of knowledge capsules committed.
// 19. `getChallengeDetails(uint256 challengeId)`: Retrieves detailed information about a challenge.
// 20. `getCapsuleDetails(uint256 capsuleId)`: Retrieves detailed information about a knowledge capsule.
// 21. `getProofDetails(uint256 proofId)`: Retrieves detailed information about a submitted proof.
// 22. `getChallengeProposalDetails(uint256 proposalId)`: Retrieves details of a challenge proposal.
// 23. `getDisputeDetails(uint256 disputeId)`: Retrieves details of a dispute.
//
// VIII. Withdrawals
// 24. `withdrawFees()`: Allows the owner to withdraw accumulated contract fees (e.g., NFT minting fees, dispute fees).
contract DecentralizedSkillForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for arithmetic operations

    // I. Core Data Structures & Enumerations

    // Represents a user's commitment to possessing certain knowledge or skill.
    // The actual content is kept private (off-chain) and only its hash is stored.
    struct KnowledgeCapsule {
        address committer;         // Address of the user who committed the capsule
        bytes32 capsuleHash;       // Hash of the private knowledge content
        uint256 categoryId;        // Category this knowledge belongs to (e.g., "Solidity", "AI Prompt Engineering")
        bool isRevealed;           // True if the original content has been revealed
        bool unlockRequested;      // True if the committer requested to reveal the content
        uint256 verifiedProofsCount; // Number of proofs successfully verified against this capsule
    }

    // Represents a skill challenge that users can attempt to prove their knowledge.
    struct Challenge {
        string name;               // Name of the challenge
        string description;        // Description of what the challenge entails
        uint256 categoryId;        // Category this challenge belongs to
        bytes32 solutionHash;      // Hash of the expected valid proof output
        address creator;           // Address of the curator who created the challenge
        bool isActive;             // True if the challenge is active and accepting proofs
        uint256 rewardReputation;  // Reputation points awarded for successful completion
        uint256 proposerRewardBPS; // Basis points for reward to original proposer (e.g. 100 = 1%)
    }

    // Represents a user's submission to a challenge.
    enum ProofStatus { Pending, Verified, Invalid, Disputed }
    struct Proof {
        address prover;            // Address of the user who submitted the proof
        uint256 challengeId;       // The challenge this proof is for
        uint256 capsuleId;         // The knowledge capsule this proof relates to
        bytes32 proofDataHash;     // Hash of the proof data submitted by the user (keccak256(_proofData))
        ProofStatus status;        // Current status of the proof
        address verifier;          // Address of the curator/admin who verified the proof
        uint256 submittedTimestamp;
    }

    // Represents a proposal for a new challenge, awaiting community/curator approval.
    enum ProposalStatus { Pending, Approved, Rejected, Finalized }
    struct ChallengeProposal {
        address proposer;
        string name;
        string description;
        uint256 categoryId;
        bytes32 solutionHash;
        uint256 proposerRewardBPS;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // Represents a dispute filed against a submitted proof.
    enum DisputeStatus { Open, ResolvedValid, ResolvedInvalid }
    struct ProofDispute {
        uint256 proofId;
        address disputer;
        string reason;
        DisputeStatus status;
        address resolver;
        uint256 filedTimestamp;
    }

    // Configuration for skill categories.
    struct CategoryConfig {
        uint256 minReputationForNFT; // Minimum reputation required to mint an NFT for this category
        uint256 nftMintFee;          // Fee in wei to mint the NFT for this category
        uint256 challengeRewardReputation; // Default reputation reward for challenges in this category
    }

    // II. Access Control & Modifiers

    mapping(address => bool) private _isCurator;
    uint256 public challengeVerificationReward; // Reward for curators who verify proofs

    modifier onlyCurator() {
        require(_isCurator[msg.sender] || owner() == msg.sender, "Caller is not a curator or owner");
        _;
    }

    // III. ERC721 Soulbound Skill NFTs (Internal)

    // Using OpenZeppelin's ERC721, but making tokens non-transferable (Soulbound)
    constructor() ERC721("SkillForgeNFT", "SFN") Ownable(msg.sender) {
        // Owner is automatically a curator initially
        _isCurator[msg.sender] = true;
        challengeVerificationReward = 0.01 ether; // Default reward for verifiers
    }

    // Override _beforeTokenTransfer to make NFTs non-transferable (Soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from == address(0)) and burning (to == address(0))
        // but disallow any other transfers.
        require(from == address(0) || to == address(0), "SkillForgeNFTs are soulbound and cannot be transferred.");
    }

    // IV. Knowledge Capsule Management

    Counters.Counter private _capsuleIds;
    mapping(uint256 => KnowledgeCapsule) public capsules;
    mapping(address => mapping(uint256 => uint256)) private _userCapsuleByCategory; // Track one capsule per user per category
    mapping(address => mapping(uint256 => bool)) private _userHasMintedNFT; // Track minted NFTs per user per category

    event KnowledgeCapsuleCommitted(uint256 indexed capsuleId, address indexed committer, uint256 indexed categoryId, bytes32 capsuleHash);
    event CapsuleUnlockRequested(uint256 indexed capsuleId, address indexed committer);
    event KnowledgeCapsuleRevealed(uint256 indexed capsuleId, address indexed committer);

    /**
     * @notice Allows a user to commit to a piece of knowledge/skill by submitting its hash.
     *         A user can only commit one capsule per category.
     * @param _capsuleHash The keccak256 hash of the private knowledge content.
     * @param _categoryId The ID representing the category of this knowledge.
     */
    function commitKnowledgeCapsule(bytes32 _capsuleHash, uint256 _categoryId) external {
        require(_userCapsuleByCategory[msg.sender][_categoryId] == 0, "User already has a capsule in this category.");

        _capsuleIds.increment();
        uint256 newCapsuleId = _capsuleIds.current();

        capsules[newCapsuleId] = KnowledgeCapsule({
            committer: msg.sender,
            capsuleHash: _capsuleHash,
            categoryId: _categoryId,
            isRevealed: false,
            unlockRequested: false,
            verifiedProofsCount: 0
        });
        _userCapsuleByCategory[msg.sender][_categoryId] = newCapsuleId;

        emit KnowledgeCapsuleCommitted(newCapsuleId, msg.sender, _categoryId, _capsuleHash);
    }

    /**
     * @notice Initiates a request for a proven capsule's content to be revealed.
     *         Requires a certain number of verified proofs associated with the capsule.
     * @param _capsuleId The ID of the knowledge capsule to unlock.
     */
    function requestCapsuleContentUnlock(uint256 _capsuleId) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        require(capsule.committer == msg.sender, "Only committer can request unlock.");
        require(!capsule.isRevealed, "Capsule content already revealed.");
        require(!capsule.unlockRequested, "Unlock already requested.");
        // Example: require at least 3 verified proofs to request unlock
        require(capsule.verifiedProofsCount >= 3, "Not enough verified proofs to unlock capsule.");

        capsule.unlockRequested = true;
        emit CapsuleUnlockRequested(_capsuleId, msg.sender);
    }

    /**
     * @notice Allows the committer to reveal the original content of a verified capsule.
     *         Can only be called after an unlock request has been approved (conceptually by verified proofs count).
     * @param _capsuleId The ID of the knowledge capsule to reveal.
     * @param _originalContent The original content of the knowledge capsule.
     */
    function revealKnowledgeCapsule(uint256 _capsuleId, bytes calldata _originalContent) external {
        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        require(capsule.committer == msg.sender, "Only committer can reveal capsule.");
        require(!capsule.isRevealed, "Capsule content already revealed.");
        require(capsule.unlockRequested, "Capsule unlock not requested or conditions not met.");
        require(keccak256(_originalContent) == capsule.capsuleHash, "Original content hash mismatch.");

        capsule.isRevealed = true;
        emit KnowledgeCapsuleRevealed(_capsuleId, msg.sender);
    }

    // V. Challenge Proposal & Curation

    Counters.Counter private _challengeProposalIds;
    mapping(uint256 => ChallengeProposal) public challengeProposals;
    mapping(uint256 => mapping(address => bool)) private _hasVotedOnProposal;

    event ChallengeProposed(uint256 indexed proposalId, address indexed proposer, uint256 indexed categoryId);
    event ChallengeProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ChallengeProposalFinalized(uint256 indexed proposalId, uint256 indexed challengeId, ProposalStatus status);

    /**
     * @notice A curator proposes a new challenge with a solution hash and potential reward.
     * @param _name Name of the challenge.
     * @param _description Detailed description of the challenge.
     * @param _categoryId The category this challenge belongs to.
     * @param _solutionHash The keccak256 hash of the expected valid proof output.
     * @param _proposerRewardBPS Basis points (e.g., 100 = 1%) for the challenge proposer's reward from total fees collected for the challenge.
     */
    function proposeChallenge(
        string memory _name,
        string memory _description,
        uint256 _categoryId,
        bytes32 _solutionHash,
        uint256 _proposerRewardBPS
    ) external onlyCurator {
        require(bytes(_name).length > 0, "Challenge name cannot be empty.");
        require(_proposerRewardBPS <= 10000, "Proposer reward BPS cannot exceed 10000 (100%)."); // 10000 BPS = 100%

        _challengeProposalIds.increment();
        uint256 newProposalId = _challengeProposalIds.current();

        challengeProposals[newProposalId] = ChallengeProposal({
            proposer: msg.sender,
            name: _name,
            description: _description,
            categoryId: _categoryId,
            solutionHash: _solutionHash,
            proposerRewardBPS: _proposerRewardBPS,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0
        });

        emit ChallengeProposed(newProposalId, msg.sender, _categoryId);
    }

    /**
     * @notice High-reputation users or curators vote on proposed challenges.
     *         Requires a minimum reputation to vote, or being a curator.
     * @param _proposalId The ID of the challenge proposal to vote on.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnChallengeProposal(uint256 _proposalId, bool _approve) external {
        ChallengeProposal storage proposal = challengeProposals[_proposalId];
        require(proposal.proposer != address(0), "Challenge proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending status.");
        require(!_hasVotedOnProposal[_proposalId][msg.sender], "User has already voted on this proposal.");

        // Example: Only curators or users with > 100 reputation can vote
        require(_isCurator[msg.sender] || userReputation[msg.sender] > 100, "Insufficient reputation or not a curator to vote.");

        _hasVotedOnProposal[_proposalId][msg.sender] = true;

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }

        emit ChallengeProposalVoted(_proposalId, msg.sender, _approve);
    }

    Counters.Counter private _challengeIds;
    mapping(uint256 => Challenge) public challenges;

    /**
     * @notice Owner/Admin finalizes a challenge proposal if it meets voting criteria.
     *         If approved, a new challenge is created.
     * @param _proposalId The ID of the challenge proposal to finalize.
     */
    function finalizeChallengeProposal(uint256 _proposalId) external onlyOwner {
        ChallengeProposal storage proposal = challengeProposals[_proposalId];
        require(proposal.proposer != address(0), "Challenge proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending status.");

        // Example: Requires more 'for' votes than 'against', and at least 3 'for' votes
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= 3) {
            proposal.status = ProposalStatus.Approved;

            _challengeIds.increment();
            uint256 newChallengeId = _challengeIds.current();

            // Use category's default reward or a custom one from proposal, if desired.
            // For simplicity, we'll use a default from category config if exists, otherwise a baseline.
            uint256 rewardReputation = categoryConfigs[proposal.categoryId].challengeRewardReputation;
            if (rewardReputation == 0) rewardReputation = 50; // Baseline if not configured

            challenges[newChallengeId] = Challenge({
                name: proposal.name,
                description: proposal.description,
                categoryId: proposal.categoryId,
                solutionHash: proposal.solutionHash,
                creator: proposal.proposer,
                isActive: true,
                rewardReputation: rewardReputation,
                proposerRewardBPS: proposal.proposerRewardBPS
            });

            emit ChallengeProposalFinalized(_proposalId, newChallengeId, ProposalStatus.Approved);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ChallengeProposalFinalized(_proposalId, 0, ProposalStatus.Rejected);
        }
    }

    // VI. Challenge Execution & Proof Submission

    Counters.Counter private _proofIds;
    mapping(uint256 => Proof) public proofs;

    event ProofSubmitted(uint256 indexed proofId, address indexed prover, uint256 indexed challengeId, uint256 capsuleId);
    event ProofVerified(uint256 indexed proofId, address indexed verifier, bool isValid);

    /**
     * @notice A user submits a proof for a specific challenge, linking it to their knowledge capsule.
     *         The `proofData` must hash to the `solutionHash` defined in the challenge.
     * @param _challengeId The ID of the challenge being attempted.
     * @param _capsuleId The ID of the knowledge capsule this proof is associated with.
     * @param _proofData The raw data of the proof. `keccak256(_proofData)` must match `challenge.solutionHash`.
     */
    function submitProofForChallenge(uint256 _challengeId, uint256 _capsuleId, bytes calldata _proofData) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.creator != address(0), "Challenge does not exist.");
        require(challenge.isActive, "Challenge is not active.");

        KnowledgeCapsule storage capsule = capsules[_capsuleId];
        require(capsule.committer == msg.sender, "Capsule not owned by sender.");
        require(capsule.categoryId == challenge.categoryId, "Capsule category must match challenge category.");

        _proofIds.increment();
        uint256 newProofId = _proofIds.current();

        proofs[newProofId] = Proof({
            prover: msg.sender,
            challengeId: _challengeId,
            capsuleId: _capsuleId,
            proofDataHash: keccak256(_proofData), // Store hash of proof data, not data itself for gas/privacy
            status: ProofStatus.Pending,
            verifier: address(0),
            submittedTimestamp: block.timestamp
        });

        emit ProofSubmitted(newProofId, msg.sender, _challengeId, _capsuleId);
    }

    // VII. Proof Verification & Dispute Resolution

    mapping(address => uint256) public userReputation;
    Counters.Counter private _disputeIds;
    mapping(uint256 => ProofDispute) public disputes;

    event DisputeFiled(uint256 indexed disputeId, uint256 indexed proofId, address indexed disputer);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed proofId, bool isValidProof, address indexed resolver);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    /**
     * @notice Owner/Curator function to verify a submitted proof against the challenge's solution hash.
     *         This is the core "proof-of-knowledge" verification step.
     * @param _proofId The ID of the proof to verify.
     */
    function verifySubmittedProof(uint256 _proofId) external payable onlyCurator {
        Proof storage proof = proofs[_proofId];
        require(proof.prover != address(0), "Proof does not exist.");
        require(proof.status == ProofStatus.Pending, "Proof is not in pending status.");
        require(msg.value >= challengeVerificationReward, "Insufficient verification reward sent.");

        Challenge storage challenge = challenges[proof.challengeId];
        require(challenge.creator != address(0), "Associated challenge does not exist.");

        // The core "simulated ZK" part: check if the submitted proof data hash matches the challenge's solution hash.
        // In a real ZK system, this would involve verifying a complex ZK proof.
        // Here, it's a simple hash comparison, representing a pre-agreed verifiable output.
        bool isValid = (proof.proofDataHash == challenge.solutionHash);

        proof.status = isValid ? ProofStatus.Verified : ProofStatus.Invalid;
        proof.verifier = msg.sender;

        if (isValid) {
            // Reward the prover
            userReputation[proof.prover] = userReputation[proof.prover].add(challenge.rewardReputation);
            emit ReputationUpdated(proof.prover, userReputation[proof.prover]);

            // Increment verified proofs count for the associated capsule
            capsules[proof.capsuleId].verifiedProofsCount = capsules[proof.capsuleId].verifiedProofsCount.add(1);
        }
        
        // Reward the verifier
        if (challengeVerificationReward > 0) {
            payable(msg.sender).transfer(challengeVerificationReward);
        }
        
        emit ProofVerified(_proofId, msg.sender, isValid);
    }

    /**
     * @notice Allows any user to dispute the validity of a submitted proof.
     *         Requires a small fee to prevent spam.
     * @param _proofId The ID of the proof to dispute.
     * @param _reason A string explaining why the proof is disputed.
     */
    function disputeProof(uint256 _proofId, string memory _reason) external payable {
        Proof storage proof = proofs[_proofId];
        require(proof.prover != address(0), "Proof does not exist.");
        require(proof.status != ProofStatus.Disputed, "Proof is already under dispute.");
        require(proof.status != ProofStatus.Invalid, "Cannot dispute an already invalid proof.");
        require(msg.value >= 0.01 ether, "Minimum 0.01 ETH required to file a dispute."); // Small fee for dispute

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = ProofDispute({
            proofId: _proofId,
            disputer: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            resolver: address(0),
            filedTimestamp: block.timestamp
        });

        proof.status = ProofStatus.Disputed; // Set proof status to disputed
        emit DisputeFiled(newDisputeId, _proofId, msg.sender);
    }

    /**
     * @notice Owner/Admin resolves a proof dispute, updating proof status and reputation.
     *         The fee from the dispute is either returned or kept based on resolution.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isValidProof True if the proof is ultimately deemed valid, false if invalid.
     */
    function resolveDispute(uint256 _disputeId, bool _isValidProof) external onlyOwner {
        ProofDispute storage dispute = disputes[_disputeId];
        require(dispute.disputer != address(0), "Dispute does not exist.");
        require(dispute.status == DisputeStatus.Open, "Dispute is not open.");

        Proof storage proof = proofs[dispute.proofId];
        require(proof.prover != address(0), "Associated proof does not exist.");

        dispute.status = _isValidProof ? DisputeStatus.ResolvedValid : DisputeStatus.ResolvedInvalid;
        dispute.resolver = msg.sender;

        if (_isValidProof) {
            // Proof is valid: If it was previously pending/disputed, mark as verified and grant reputation.
            if (proof.status != ProofStatus.Verified) {
                userReputation[proof.prover] = userReputation[proof.prover].add(challenges[proof.challengeId].rewardReputation);
                emit ReputationUpdated(proof.prover, userReputation[proof.prover]);
                capsules[proof.capsuleId].verifiedProofsCount = capsules[proof.capsuleId].verifiedProofsCount.add(1);
            }
            proof.status = ProofStatus.Verified;
            // Disputer was wrong, their fee is kept by the contract.
        } else {
            // Proof is invalid: If it was previously verified, remove reputation.
            if (proof.status == ProofStatus.Verified) {
                userReputation[proof.prover] = userReputation[proof.prover].sub(challenges[proof.challengeId].rewardReputation);
                emit ReputationUpdated(proof.prover, userReputation[proof.prover]);
                capsules[proof.capsuleId].verifiedProofsCount = capsules[proof.capsuleId].verifiedProofsCount.sub(1);
            }
            proof.status = ProofStatus.Invalid;
            // Disputer was correct, return their fee.
            payable(dispute.disputer).transfer(0.01 ether); // Assuming the fixed dispute fee
        }

        emit DisputeResolved(_disputeId, dispute.proofId, _isValidProof, msg.sender);
    }

    // VIII. Reputation & Skill NFT Minting

    mapping(uint256 => CategoryConfig) public categoryConfigs;

    event SkillNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 indexed categoryId);

    /**
     * @notice Allows a user to mint a Soulbound Skill NFT if they meet the reputation threshold for a category.
     *         Requires payment of the `nftMintFee` set for the category.
     * @param _categoryId The category ID for which to mint the NFT.
     */
    function mintSkillNFT(uint256 _categoryId) external payable {
        CategoryConfig storage config = categoryConfigs[_categoryId];
        require(config.minReputationForNFT > 0, "Category configuration not set or invalid.");
        require(userReputation[msg.sender] >= config.minReputationForNFT, "Insufficient reputation to mint NFT for this category.");
        require(msg.value >= config.nftMintFee, "Insufficient ETH sent for NFT minting fee.");
        require(!_userHasMintedNFT[msg.sender][_categoryId], "You have already minted this category's Skill NFT.");

        _userHasMintedNFT[msg.sender][_categoryId] = true;

        // Mint a new ERC721 token
        uint256 newTokenId = super.totalSupply().add(1); // Simple sequential token IDs
        _safeMint(msg.sender, newTokenId);

        // Refund any excess ETH
        if (msg.value > config.nftMintFee) {
            payable(msg.sender).transfer(msg.value.sub(config.nftMintFee));
        }

        emit SkillNFTMinted(newTokenId, msg.sender, _categoryId);
    }

    /**
     * @notice Checks if a user has minted the Skill NFT for a specific category.
     * @param _user The address of the user.
     * @param _categoryId The category ID to check.
     * @return True if the user has minted the NFT, false otherwise.
     */
    function isSkillNFTMinted(address _user, uint256 _categoryId) external view returns (bool) {
        return _userHasMintedNFT[_user][_categoryId];
    }

    // IX. Access Control & Configuration

    event CuratorStatusUpdated(address indexed curator, bool isCurator);
    event CategoryConfigUpdated(uint256 indexed categoryId, uint256 minReputationForNFT, uint256 nftMintFee, uint256 challengeRewardReputation);
    event ChallengeVerificationRewardUpdated(uint256 newRewardAmount);

    /**
     * @notice Owner function to assign or revoke curator roles.
     * @param _curator The address of the curator.
     * @param _isCurator True to assign, false to revoke.
     */
    function setCurator(address _curator, bool _isCurator) external onlyOwner {
        require(_curator != address(0), "Curator address cannot be zero.");
        _isCurator[_curator] = _isCurator;
        emit CuratorStatusUpdated(_curator, _isCurator);
    }

    /**
     * @notice Owner sets parameters for a skill category.
     * @param _categoryId The ID of the category.
     * @param _minReputationForNFT Minimum reputation required to mint an NFT for this category.
     * @param _nftMintFee Fee in wei to mint the NFT for this category.
     * @param _challengeRewardReputation Default reputation reward for challenges in this category.
     */
    function setCategoryConfiguration(
        uint256 _categoryId,
        uint256 _minReputationForNFT,
        uint256 _nftMintFee,
        uint256 _challengeRewardReputation
    ) external onlyOwner {
        categoryConfigs[_categoryId] = CategoryConfig({
            minReputationForNFT: _minReputationForNFT,
            nftMintFee: _nftMintFee,
            challengeRewardReputation: _challengeRewardReputation
        });
        emit CategoryConfigUpdated(_categoryId, _minReputationForNFT, _nftMintFee, _challengeRewardReputation);
    }

    /**
     * @notice Owner sets the reward amount sent to curators for verifying proofs.
     * @param _rewardAmount The new reward amount in wei.
     */
    function setChallengeVerificationReward(uint256 _rewardAmount) external onlyOwner {
        challengeVerificationReward = _rewardAmount;
        emit ChallengeVerificationRewardUpdated(_rewardAmount);
    }

    // X. Utility & Getter Functions

    /**
     * @notice Retrieves the reputation score of a given user.
     * @param user The address of the user.
     * @return The user's current reputation score.
     */
    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @notice Returns the total number of challenges created.
     */
    function getTotalChallenges() external view returns (uint256) {
        return _challengeIds.current();
    }

    /**
     * @notice Returns the total number of knowledge capsules committed.
     */
    function getTotalCapsules() external view returns (uint256) {
        return _capsuleIds.current();
    }

    /**
     * @notice Retrieves detailed information about a challenge.
     * @param _challengeId The ID of the challenge.
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (
        string memory name,
        string memory description,
        uint256 categoryId,
        bytes32 solutionHash,
        address creator,
        bool isActive,
        uint256 rewardReputation,
        uint256 proposerRewardBPS
    ) {
        Challenge storage c = challenges[_challengeId];
        require(c.creator != address(0), "Challenge does not exist.");
        return (c.name, c.description, c.categoryId, c.solutionHash, c.creator, c.isActive, c.rewardReputation, c.proposerRewardBPS);
    }

    /**
     * @notice Retrieves detailed information about a knowledge capsule.
     * @param _capsuleId The ID of the capsule.
     */
    function getCapsuleDetails(uint256 _capsuleId) external view returns (
        address committer,
        bytes32 capsuleHash,
        uint256 categoryId,
        bool isRevealed,
        bool unlockRequested,
        uint256 verifiedProofsCount
    ) {
        KnowledgeCapsule storage k = capsules[_capsuleId];
        require(k.committer != address(0), "Capsule does not exist.");
        return (k.committer, k.capsuleHash, k.categoryId, k.isRevealed, k.unlockRequested, k.verifiedProofsCount);
    }

    /**
     * @notice Retrieves detailed information about a submitted proof.
     * @param _proofId The ID of the proof.
     */
    function getProofDetails(uint256 _proofId) external view returns (
        address prover,
        uint256 challengeId,
        uint256 capsuleId,
        bytes32 proofDataHash,
        ProofStatus status,
        address verifier,
        uint256 submittedTimestamp
    ) {
        Proof storage p = proofs[_proofId];
        require(p.prover != address(0), "Proof does not exist.");
        return (p.prover, p.challengeId, p.capsuleId, p.proofDataHash, p.status, p.verifier, p.submittedTimestamp);
    }

    /**
     * @notice Retrieves details of a challenge proposal.
     * @param _proposalId The ID of the proposal.
     */
    function getChallengeProposalDetails(uint256 _proposalId) external view returns (
        address proposer,
        string memory name,
        string memory description,
        uint256 categoryId,
        bytes32 solutionHash,
        uint256 proposerRewardBPS,
        ProposalStatus status,
        uint256 votesFor,
        uint256 votesAgainst
    ) {
        ChallengeProposal storage cp = challengeProposals[_proposalId];
        require(cp.proposer != address(0), "Challenge proposal does not exist.");
        return (cp.proposer, cp.name, cp.description, cp.categoryId, cp.solutionHash, cp.proposerRewardBPS, cp.status, cp.votesFor, cp.votesAgainst);
    }

    /**
     * @notice Retrieves details of a dispute.
     * @param _disputeId The ID of the dispute.
     */
    function getDisputeDetails(uint256 _disputeId) external view returns (
        uint256 proofId,
        address disputer,
        string memory reason,
        DisputeStatus status,
        address resolver,
        uint256 filedTimestamp
    ) {
        ProofDispute storage d = disputes[_disputeId];
        require(d.disputer != address(0), "Dispute does not exist.");
        return (d.proofId, d.disputer, d.reason, d.status, d.resolver, d.filedTimestamp);
    }

    // XI. Withdrawals

    /**
     * @notice Allows the owner to withdraw accumulated contract fees (e.g., NFT minting fees, dispute fees).
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        // Ensure enough balance remains to cover at least one verification reward
        require(balance >= challengeVerificationReward, "Insufficient balance to withdraw after reserving verification reward.");
        uint256 amountToWithdraw = balance.sub(challengeVerificationReward);
        
        if (amountToWithdraw > 0) {
            payable(owner()).transfer(amountToWithdraw);
        }
    }
}
```