This smart contract, **AetherialForge**, introduces a novel decentralized platform for creative collaboration, AI-augmented content, and reputation building. It combines concepts like Soulbound Tokens for reputation, AI insight attestation, on-chain lineage tracking for derivative works ("forging"), and a dynamic staking/challenge system for originality and quality. The aim is to create a self-sustaining ecosystem where creativity is fostered, validated, and rewarded, using AI as an augmentation tool rather than a central authority.

---

### **Contract: AetherialForge**

**Outline:**

*   **I. Core System & Access Control:** Manages contract ownership, guardian roles, and emergency pausing.
*   **II. Aetherium Token Integration:** Sets up interaction with a utility ERC-20 token for staking and rewards.
*   **III. Artifact Management:** Handles the submission, metadata updates, and retrieval of creative works.
*   **IV. AI Insight Integration:** Allows users to submit AI-generated insights related to artifacts, which can then be attested to by the community.
*   **V. Reputation (Soulbound Token):** Implements a non-transferable ERC-721 token to track and display user reputation based on their contributions and attestations.
*   **VI. Forging & Derivative Works:** Enables the creation of new artifacts by combining existing ones, with on-chain lineage tracking.
*   **VII. Dynamic Bounties & Rewards:** Facilitates the creation and fulfillment of creative tasks with `Aetherium` token rewards.
*   **VIII. Staking & Challenge System:** A mechanism for users to stake tokens on the originality/validity of artifacts, which can be challenged by others, and resolved by guardians.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the deployer as the owner.
2.  `setGuardian(address _newGuardian)`: Owner-only function to assign a guardian address for emergency actions and moderation.
3.  `pauseContract()`: Owner or guardian can pause critical contract functions in an emergency.
4.  `unpauseContract()`: Owner or guardian can unpause the contract.
5.  `setAetheriumTokenAddress(address _tokenAddress)`: Owner-only function to set the address of the ERC-20 Aetherium token used for staking and rewards.
6.  `submitArtifact(string memory _metadataURI, bytes32 _contentHash, uint256 _stakeAmount)`: Allows users to submit a new creative artifact (e.g., concept, design, code snippet), link its off-chain metadata, provide a content hash for integrity, and stake Aetherium tokens to assert its originality/value.
7.  `getArtifactDetails(uint256 _artifactId)`: Retrieves comprehensive details about a specific artifact, including its owner, URI, content hash, and current status.
8.  `updateArtifactMetadata(uint256 _artifactId, string memory _newMetadataURI)`: Allows the owner of an artifact to update its metadata URI.
9.  `submitAIInsight(uint256 _artifactId, string memory _insightURI, bytes32 _aiProofHash)`: Contributors submit an AI-generated insight (e.g., analysis, enhancement, derivative suggestion) related to an existing artifact. Includes its metadata URI and a verifiable hash (simulating a ZK-proof or verifiable output) of the AI's contribution.
10. `attestAIInsightValidity(uint256 _insightId, bool _isValid)`: Users can attest to the validity or quality of an AI insight. Valid attestations positively affect the attester's reputation and the insight's trust score; invalid ones have negative effects.
11. `getInsightDetails(uint256 _insightId)`: Retrieves detailed information about a specific AI insight.
12. `mintReputationNFT(address _recipient, string memory _tokenURI)`: A guardian-only function to mint a new non-transferable Soulbound Token (Reputation NFT) to a user, signifying initial achievement or entry into the community.
13. `getReputationScore(address _user)`: Retrieves a user's current reputation score associated with their Soulbound Token.
14. `forgeDerivativeArtifact(uint256[] memory _parentArtifactIds, string memory _derivativeURI, bytes32 _derivativeContentHash, uint256 _stakeAmount)`: Users can "forge" a new artifact by creatively combining or deriving from existing artifacts. This tracks the lineage on-chain, and also requires a stake.
15. `getDerivativeLineage(uint256 _derivativeId)`: Traces and returns the parent artifacts that contributed to a specified derivative work, providing transparency and attribution.
16. `createAetherialBounty(string memory _taskDescriptionURI, uint256 _rewardAmount, uint256 _deadline)`: Allows users to create a bounty for a specific creative task, depositing `Aetherium` tokens as a reward, and setting a deadline.
17. `submitBountySolution(uint256 _bountyId, uint256 _artifactId)`: Users can submit an existing, or newly created, artifact as a solution to an open bounty.
18. `judgeBountySolution(uint256 _bountyId, uint256 _solutionArtifactId, bool _isAccepted)`: The bounty creator (or a delegated judge) evaluates submitted solutions. If accepted, the reward is released, and reputation is adjusted.
19. `challengeArtifactOriginality(uint256 _artifactId, uint256 _challengeStakeAmount)`: Any user can challenge the originality, validity, or quality of a staked artifact by placing a counter-stake, initiating a dispute.
20. `resolveChallenge(uint256 _artifactId, bool _challengerWins)`: Owner or guardian resolves an artifact challenge. The stake is awarded to the winner, and reputation scores of both parties are adjusted.
21. `withdrawStakedAetherium(uint256 _artifactId)`: Allows an artifact owner to withdraw their initial stake if no challenges exist after a cool-off period, or after a challenge is resolved in their favor.
22. `claimBountyReward(uint256 _bountyId)`: Allows the accepted bounty solution provider to claim their `Aetherium` reward.
23. `rescindBounty(uint256 _bountyId)`: Allows the bounty creator to cancel an unfulfilled bounty and reclaim their `Aetherium` tokens before the deadline.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AetherialForge
 * @dev A decentralized platform for creative collaboration, AI-augmented content, and reputation building.
 *      It integrates Soulbound Tokens for reputation, AI insight attestation, on-chain lineage
 *      tracking for derivative works ("forging"), and a dynamic staking/challenge system for originality and quality.
 */
contract AetherialForge is Ownable, Pausable, ERC721 {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- Core System & Access Control ---
    address public guardian;
    uint256 public constant MIN_STAKE_AMOUNT = 0.01 ether; // Example minimum stake
    uint256 public constant CHALLENGE_RESOLUTION_FEE_PERCENT = 5; // 5% fee for guardian resolving challenges

    // --- Aetherium Token Integration ---
    IERC20 public aetheriumToken;

    // --- Artifact Management ---
    struct Artifact {
        address owner;
        string metadataURI; // IPFS or similar link to detailed metadata (title, description, tags)
        bytes32 contentHash; // Hash of the actual creative content (e.g., AI prompt, code snippet, image hash)
        uint256 stakeAmount; // Aetherium tokens staked for originality/value
        bool isChallenged;
        bool isDeleted; // Soft delete
        uint256 challengeId; // ID of the current active challenge if any
        uint256 createdAt;
        uint256 lastUpdated;
    }
    mapping(uint256 => Artifact) public artifacts;
    Counters.Counter private _artifactIds;
    uint256 public constant ARTIFACT_STAKE_GRACE_PERIOD = 7 days; // Period before stake can be withdrawn if no challenge

    // --- AI Insight Integration ---
    struct AIInsight {
        uint256 artifactId;
        address contributor;
        string insightURI; // IPFS or similar link to detailed AI insight (e.g., AI model output, analysis)
        bytes32 aiProofHash; // Verifiable hash (e.g., ZK-proof output, hash of critical AI params/results)
        int256 trustScore; // Aggregated score from community attestations
        uint256 createdAt;
    }
    mapping(uint256 => AIInsight) public aiInsights;
    Counters.Counter private _insightIds;

    // Mapping for user's attestation status on a specific insight
    mapping(uint256 => mapping(address => bool)) public userInsightAttestations; // insightId => user => hasAttested

    // --- Reputation (Soulbound Token) ---
    // ERC721 already handles token ownership. We add a reputation score per SBT.
    mapping(uint256 => int256) public reputationScores; // tokenId => score
    Counters.Counter private _sbtTokenIds; // For SBT token IDs

    // --- Forging & Derivative Works ---
    mapping(uint256 => uint256[]) public derivativeLineage; // derivativeArtifactId => parentArtifactIds

    // --- Dynamic Bounties & Rewards ---
    enum BountyStatus { Open, Solved, Accepted, Rejected, Cancelled }
    struct Bounty {
        address creator;
        string taskDescriptionURI; // Link to bounty details, requirements
        uint256 rewardAmount; // Aetherium tokens
        uint256 deadline;
        BountyStatus status;
        uint256 solutionArtifactId; // Artifact ID that solved the bounty
        address solver; // Address of the user whose solution was accepted
        uint256 createdAt;
    }
    mapping(uint256 => Bounty) public bounties;
    Counters.Counter private _bountyIds;

    // --- Staking & Challenge System ---
    struct Challenge {
        uint256 artifactId;
        address challenger;
        uint256 challengerStake;
        uint256 createdAt;
        bool isActive;
        bool resolved;
        bool challengerWon; // True if challenger won, false if original staker won
    }
    mapping(uint256 => Challenge) public challenges;
    Counters.Counter private _challengeIds;

    // --- Events ---
    event GuardianSet(address indexed newGuardian);
    event AetheriumTokenSet(address indexed tokenAddress);
    event ArtifactSubmitted(uint256 indexed artifactId, address indexed owner, string metadataURI, bytes32 contentHash, uint256 stakeAmount);
    event ArtifactMetadataUpdated(uint256 indexed artifactId, string newMetadataURI);
    event AIInsightSubmitted(uint256 indexed insightId, uint256 indexed artifactId, address indexed contributor, string insightURI, bytes32 aiProofHash);
    event AIInsightAttested(uint256 indexed insightId, address indexed attester, bool isValid, int256 newTrustScore);
    event ReputationNFTMinted(address indexed recipient, uint256 indexed tokenId, int256 initialScore);
    event ReputationScoreUpdated(address indexed user, uint256 indexed tokenId, int256 newScore);
    event DerivativeArtifactForged(uint256 indexed derivativeId, address indexed creator, uint256[] parentArtifactIds, string derivativeURI);
    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, uint256 deadline, string taskDescriptionURI);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed solutionArtifactId, address indexed solver);
    event BountyJudged(uint256 indexed bountyId, uint256 indexed solutionArtifactId, address indexed judge, bool isAccepted);
    event BountyClaimed(uint256 indexed bountyId, address indexed claimant, uint256 rewardAmount);
    event BountyRescinded(uint256 indexed bountyId, address indexed rescinder, uint256 refundAmount);
    event ArtifactChallengeInitiated(uint256 indexed artifactId, uint256 indexed challengeId, address indexed challenger, uint256 challengerStake);
    event ArtifactChallengeResolved(uint256 indexed artifactId, uint256 indexed challengeId, address indexed resolver, bool challengerWon);
    event AetheriumStakedWithdrawn(uint256 indexed artifactId, address indexed owner, uint256 amount);

    // --- Modifiers ---
    modifier onlyGuardian() {
        require(msg.sender == guardian, "AetherialForge: Not guardian");
        _;
    }

    modifier onlyArtifactOwner(uint256 _artifactId) {
        require(artifacts[_artifactId].owner == msg.sender, "AetherialForge: Not artifact owner");
        _;
    }

    modifier onlyBountyCreator(uint256 _bountyId) {
        require(bounties[_bountyId].creator == msg.sender, "AetherialForge: Not bounty creator");
        _;
    }

    modifier onlyReputationOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "AetherialForge: Not SBT owner");
        _;
    }

    /**
     * @dev Initializes the contract, setting the deployer as the owner and the initial guardian.
     */
    constructor() Ownable(msg.sender) ERC721("ForgeReputationNFT", "FORGE_REP") {
        guardian = msg.sender;
        emit GuardianSet(msg.sender);
    }

    // --- I. Core System & Access Control ---

    /**
     * @dev Sets a new guardian address. Only the current owner can call this.
     * @param _newGuardian The address of the new guardian.
     */
    function setGuardian(address _newGuardian) external onlyOwner {
        require(_newGuardian != address(0), "AetherialForge: New guardian cannot be zero address");
        guardian = _newGuardian;
        emit GuardianSet(_newGuardian);
    }

    /**
     * @dev Pauses the contract. Can be called by the owner or guardian.
     *      Prevents most state-changing operations during an emergency.
     */
    function pauseContract() external whenNotPaused {
        require(msg.sender == owner() || msg.sender == guardian, "AetherialForge: Not owner or guardian");
        _pause();
    }

    /**
     * @dev Unpauses the contract. Can be called by the owner or guardian.
     */
    function unpauseContract() external onlyPauser {
        require(msg.sender == owner() || msg.sender == guardian, "AetherialForge: Not owner or guardian");
        _unpause();
    }

    // --- II. Aetherium Token Integration ---

    /**
     * @dev Sets the address of the ERC-20 Aetherium token.
     *      This token is used for staking, challenges, and bounty rewards.
     *      Only the owner can set this, and it can only be set once for security.
     * @param _tokenAddress The address of the Aetherium ERC-20 token.
     */
    function setAetheriumTokenAddress(address _tokenAddress) external onlyOwner {
        require(address(aetheriumToken) == address(0), "AetherialForge: Aetherium token address already set");
        require(_tokenAddress != address(0), "AetherialForge: Token address cannot be zero");
        aetheriumToken = IERC20(_tokenAddress);
        emit AetheriumTokenSet(_tokenAddress);
    }

    // --- III. Artifact Management ---

    /**
     * @dev Allows users to submit a new creative artifact to the AetherialForge.
     *      Requires staking Aetherium tokens to assert originality/value.
     * @param _metadataURI A URI pointing to the artifact's detailed metadata (e.g., IPFS hash).
     * @param _contentHash A unique hash representing the core content of the artifact.
     * @param _stakeAmount The amount of Aetherium tokens to stake for this artifact.
     */
    function submitArtifact(
        string memory _metadataURI,
        bytes32 _contentHash,
        uint256 _stakeAmount
    ) external whenNotPaused {
        require(address(aetheriumToken) != address(0), "AetherialForge: Aetherium token not set");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "AetherialForge: Stake amount too low");
        require(bytes(_metadataURI).length > 0, "AetherialForge: Metadata URI cannot be empty");
        require(_contentHash != bytes32(0), "AetherialForge: Content hash cannot be empty");

        _artifactIds.increment();
        uint256 newId = _artifactIds.current();

        aetheriumToken.safeTransferFrom(msg.sender, address(this), _stakeAmount);

        artifacts[newId] = Artifact({
            owner: msg.sender,
            metadataURI: _metadataURI,
            contentHash: _contentHash,
            stakeAmount: _stakeAmount,
            isChallenged: false,
            isDeleted: false,
            challengeId: 0,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        emit ArtifactSubmitted(newId, msg.sender, _metadataURI, _contentHash, _stakeAmount);
    }

    /**
     * @dev Retrieves comprehensive details about a specific artifact.
     * @param _artifactId The ID of the artifact to query.
     * @return artifact The Artifact struct containing all details.
     */
    function getArtifactDetails(uint256 _artifactId) external view returns (Artifact memory) {
        require(_artifactId > 0 && _artifactId <= _artifactIds.current(), "AetherialForge: Invalid artifact ID");
        return artifacts[_artifactId];
    }

    /**
     * @dev Allows the owner of an artifact to update its metadata URI.
     * @param _artifactId The ID of the artifact to update.
     * @param _newMetadataURI The new URI for the artifact's metadata.
     */
    function updateArtifactMetadata(uint256 _artifactId, string memory _newMetadataURI)
        external
        onlyArtifactOwner(_artifactId)
        whenNotPaused
    {
        require(bytes(_newMetadataURI).length > 0, "AetherialForge: New metadata URI cannot be empty");
        Artifact storage artifact = artifacts[_artifactId];
        require(!artifact.isChallenged, "AetherialForge: Cannot update metadata while challenged");
        artifact.metadataURI = _newMetadataURI;
        artifact.lastUpdated = block.timestamp;
        emit ArtifactMetadataUpdated(_artifactId, _newMetadataURI);
    }

    // --- IV. AI Insight Integration ---

    /**
     * @dev Allows contributors to submit an AI-generated insight related to an existing artifact.
     *      Includes a URI to the insight details and a verifiable hash of the AI's contribution.
     * @param _artifactId The ID of the artifact this insight is related to.
     * @param _insightURI A URI pointing to the AI insight's detailed metadata/output.
     * @param _aiProofHash A verifiable hash (e.g., ZK-proof output, hash of critical AI params/results).
     */
    function submitAIInsight(
        uint256 _artifactId,
        string memory _insightURI,
        bytes32 _aiProofHash
    ) external whenNotPaused {
        require(_artifactId > 0 && _artifactId <= _artifactIds.current(), "AetherialForge: Invalid artifact ID");
        require(!artifacts[_artifactId].isDeleted, "AetherialForge: Artifact is deleted");
        require(bytes(_insightURI).length > 0, "AetherialForge: Insight URI cannot be empty");
        require(_aiProofHash != bytes32(0), "AetherialForge: AI proof hash cannot be empty");

        _insightIds.increment();
        uint256 newId = _insightIds.current();

        aiInsights[newId] = AIInsight({
            artifactId: _artifactId,
            contributor: msg.sender,
            insightURI: _insightURI,
            aiProofHash: _aiProofHash,
            trustScore: 0, // Initial trust score
            createdAt: block.timestamp
        });

        emit AIInsightSubmitted(newId, _artifactId, msg.sender, _insightURI, _aiProofHash);
    }

    /**
     * @dev Users can attest to the validity or quality of an AI insight.
     *      This affects the attester's reputation and the insight's trust score.
     *      Each user can only attest once per insight.
     * @param _insightId The ID of the AI insight to attest to.
     * @param _isValid True if the attester believes the insight is valid/high quality, false otherwise.
     */
    function attestAIInsightValidity(uint256 _insightId, bool _isValid) external whenNotPaused {
        require(_insightId > 0 && _insightId <= _insightIds.current(), "AetherialForge: Invalid insight ID");
        require(!userInsightAttestations[_insightId][msg.sender], "AetherialForge: Already attested to this insight");
        require(aiInsights[_insightId].contributor != msg.sender, "AetherialForge: Cannot attest to your own insight");

        AIInsight storage insight = aiInsights[_insightId];
        userInsightAttestations[_insightId][msg.sender] = true;

        if (_isValid) {
            insight.trustScore += 1;
            _updateReputationScore(msg.sender, 5); // Reward for positive attestation
        } else {
            insight.trustScore -= 1;
            _updateReputationScore(msg.sender, -2); // Small penalty for potentially negative attestation (to prevent spam)
        }

        emit AIInsightAttested(_insightId, msg.sender, _isValid, insight.trustScore);
    }

    /**
     * @dev Retrieves detailed information about a specific AI insight.
     * @param _insightId The ID of the AI insight to query.
     * @return insight The AIInsight struct containing all details.
     */
    function getInsightDetails(uint256 _insightId) external view returns (AIInsight memory) {
        require(_insightId > 0 && _insightId <= _insightIds.current(), "AetherialForge: Invalid insight ID");
        return aiInsights[_insightId];
    }

    // --- V. Reputation (Soulbound Token) ---

    /**
     * @dev Mints a new non-transferable Soulbound Token (Reputation NFT) to a user.
     *      This is typically triggered by initial achievements or guardian discretion.
     *      Only the guardian can mint these tokens.
     * @param _recipient The address to receive the SBT.
     * @param _tokenURI A URI for the SBT's metadata (e.g., initial achievement description).
     */
    function mintReputationNFT(address _recipient, string memory _tokenURI) external onlyGuardian {
        require(_recipient != address(0), "AetherialForge: Recipient cannot be zero address");
        _sbtTokenIds.increment();
        uint256 newSBTId = _sbtTokenIds.current();
        _mint(_recipient, newSBTId);
        _setTokenURI(newSBTId, _tokenURI);
        reputationScores[newSBTId] = 100; // Initial reputation score
        emit ReputationNFTMinted(_recipient, newSBTId, reputationScores[newSBTId]);
    }

    /**
     * @dev Internal function to update a user's reputation score.
     *      Finds the user's SBT and adjusts its associated score.
     * @param _user The address of the user whose reputation to update.
     * @param _delta The amount to add to or subtract from the reputation score.
     */
    function _updateReputationScore(address _user, int256 _delta) internal {
        // Find the SBT owned by the user
        uint256 sbtId = 0;
        for (uint256 i = 1; i <= _sbtTokenIds.current(); i++) {
            if (ownerOf(i) == _user) {
                sbtId = i;
                break;
            }
        }

        if (sbtId == 0) {
            // User doesn't have an SBT yet, consider minting one or handling this case
            // For now, if no SBT, no score update.
            return;
        }

        int256 currentScore = reputationScores[sbtId];
        int256 newScore = currentScore + _delta;

        // Optional: clamp score between min/max values
        if (newScore < 0) newScore = 0;
        // if (newScore > 1000) newScore = 1000;

        reputationScores[sbtId] = newScore;
        emit ReputationScoreUpdated(_user, sbtId, newScore);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The reputation score associated with the user's SBT.
     */
    function getReputationScore(address _user) public view returns (int256) {
        for (uint256 i = 1; i <= _sbtTokenIds.current(); i++) {
            if (ownerOf(i) == _user) {
                return reputationScores[i];
            }
        }
        return 0; // If user has no SBT, reputation is 0
    }

    /**
     * @dev Prevents Soulbound Tokens from being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("AetherialForge: Soulbound tokens are non-transferable");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Overrides ERC721's `supportsInterface` to indicate non-transferability.
     * @param interfaceId The interface ID to check.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- VI. Forging & Derivative Works ---

    /**
     * @dev Allows users to "forge" a new artifact by creatively combining or deriving from existing ones.
     *      This new artifact will have its lineage tracked on-chain.
     * @param _parentArtifactIds An array of IDs of the parent artifacts used to create this derivative.
     * @param _derivativeURI A URI pointing to the detailed metadata of the new derivative artifact.
     * @param _derivativeContentHash A hash representing the core content of the derivative.
     * @param _stakeAmount The amount of Aetherium tokens to stake for this derivative artifact.
     */
    function forgeDerivativeArtifact(
        uint256[] memory _parentArtifactIds,
        string memory _derivativeURI,
        bytes32 _derivativeContentHash,
        uint256 _stakeAmount
    ) external whenNotPaused {
        require(_parentArtifactIds.length > 0, "AetherialForge: Must specify at least one parent artifact");
        for (uint256 i = 0; i < _parentArtifactIds.length; i++) {
            require(artifacts[_parentArtifactIds[i]].owner != address(0), "AetherialForge: Invalid parent artifact ID");
            require(!artifacts[_parentArtifactIds[i]].isDeleted, "AetherialForge: Parent artifact is deleted");
        }
        require(bytes(_derivativeURI).length > 0, "AetherialForge: Derivative URI cannot be empty");
        require(_derivativeContentHash != bytes32(0), "AetherialForge: Derivative content hash cannot be empty");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "AetherialForge: Stake amount too low");
        require(address(aetheriumToken) != address(0), "AetherialForge: Aetherium token not set");

        _artifactIds.increment();
        uint256 newId = _artifactIds.current();

        aetheriumToken.safeTransferFrom(msg.sender, address(this), _stakeAmount);

        artifacts[newId] = Artifact({
            owner: msg.sender,
            metadataURI: _derivativeURI,
            contentHash: _derivativeContentHash,
            stakeAmount: _stakeAmount,
            isChallenged: false,
            isDeleted: false,
            challengeId: 0,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        derivativeLineage[newId] = _parentArtifactIds;

        emit DerivativeArtifactForged(newId, msg.sender, _parentArtifactIds, _derivativeURI);
    }

    /**
     * @dev Traces and returns the parent artifacts that contributed to a specified derivative work.
     * @param _derivativeId The ID of the derivative artifact.
     * @return An array of parent artifact IDs.
     */
    function getDerivativeLineage(uint256 _derivativeId) external view returns (uint256[] memory) {
        require(_derivativeId > 0 && _derivativeId <= _artifactIds.current(), "AetherialForge: Invalid derivative ID");
        return derivativeLineage[_derivativeId];
    }

    // --- VII. Dynamic Bounties & Rewards ---

    /**
     * @dev Allows users to create a bounty for a specific creative task, depositing Aetherium tokens as a reward.
     * @param _taskDescriptionURI A URI pointing to the detailed description and requirements of the bounty.
     * @param _rewardAmount The amount of Aetherium tokens offered as a reward.
     * @param _deadline The timestamp by which solutions must be submitted.
     */
    function createAetherialBounty(
        string memory _taskDescriptionURI,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external whenNotPaused {
        require(address(aetheriumToken) != address(0), "AetherialForge: Aetherium token not set");
        require(bytes(_taskDescriptionURI).length > 0, "AetherialForge: Task description URI cannot be empty");
        require(_rewardAmount > 0, "AetherialForge: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "AetherialForge: Deadline must be in the future");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        aetheriumToken.safeTransferFrom(msg.sender, address(this), _rewardAmount);

        bounties[newBountyId] = Bounty({
            creator: msg.sender,
            taskDescriptionURI: _taskDescriptionURI,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            status: BountyStatus.Open,
            solutionArtifactId: 0,
            solver: address(0),
            createdAt: block.timestamp
        });

        emit BountyCreated(newBountyId, msg.sender, _rewardAmount, _deadline, _taskDescriptionURI);
    }

    /**
     * @dev Users can submit an existing artifact as a solution to an open bounty.
     * @param _bountyId The ID of the bounty to submit a solution for.
     * @param _solutionArtifactId The ID of the artifact being submitted as a solution.
     */
    function submitBountySolution(uint256 _bountyId, uint256 _solutionArtifactId) external whenNotPaused {
        require(_bountyId > 0 && _bountyId <= _bountyIds.current(), "AetherialForge: Invalid bounty ID");
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.status == BountyStatus.Open, "AetherialForge: Bounty is not open");
        require(block.timestamp <= bounty.deadline, "AetherialForge: Bounty deadline passed");
        require(artifacts[_solutionArtifactId].owner == msg.sender, "AetherialForge: Must be owner of solution artifact");
        require(artifacts[_solutionArtifactId].owner != address(0), "AetherialForge: Invalid solution artifact ID");
        require(!artifacts[_solutionArtifactId].isDeleted, "AetherialForge: Solution artifact is deleted");
        require(bounty.creator != msg.sender, "AetherialForge: Bounty creator cannot submit a solution");

        // Solutions are implicitly linked by the submitter's artifact.
        // The creator will judge which artifact is suitable via `judgeBountySolution`.
        // We don't update solutionArtifactId here, but could have a separate mapping if multiple solutions were allowed.
        // For simplicity, we just log the submission.
        emit BountySolutionSubmitted(_bountyId, _solutionArtifactId, msg.sender);
    }

    /**
     * @dev The bounty creator evaluates submitted solutions. If accepted, the reward is released, and reputation is adjusted.
     *      Requires the solution to be an existing artifact.
     * @param _bountyId The ID of the bounty being judged.
     * @param _solutionArtifactId The ID of the artifact submitted as a solution.
     * @param _isAccepted True to accept the solution, false to reject.
     */
    function judgeBountySolution(
        uint256 _bountyId,
        uint256 _solutionArtifactId,
        bool _isAccepted
    ) external onlyBountyCreator(_bountyId) whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.status == BountyStatus.Open, "AetherialForge: Bounty is not open");
        require(block.timestamp > bounty.deadline, "AetherialForge: Bounty deadline not passed yet"); // Must judge after deadline
        require(artifacts[_solutionArtifactId].owner != address(0), "AetherialForge: Invalid solution artifact ID");
        require(!artifacts[_solutionArtifactId].isDeleted, "AetherialForge: Solution artifact is deleted");

        bounty.solutionArtifactId = _solutionArtifactId;
        bounty.solver = artifacts[_solutionArtifactId].owner;

        if (_isAccepted) {
            bounty.status = BountyStatus.Accepted;
            _updateReputationScore(bounty.solver, 20); // Reward for accepted solution
        } else {
            bounty.status = BountyStatus.Rejected;
            _updateReputationScore(bounty.solver, -5); // Small penalty for rejected solution (if too many low quality submissions)
        }
        emit BountyJudged(_bountyId, _solutionArtifactId, msg.sender, _isAccepted);
    }

    /**
     * @dev Allows the accepted bounty solution provider to claim their Aetherium reward.
     * @param _bountyId The ID of the bounty to claim the reward for.
     */
    function claimBountyReward(uint256 _bountyId) external whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.status == BountyStatus.Accepted, "AetherialForge: Bounty not accepted or already claimed");
        require(bounty.solver == msg.sender, "AetherialForge: Only the solver can claim the reward");

        uint256 reward = bounty.rewardAmount;
        bounty.status = BountyStatus.Solved; // Mark as solved to prevent re-claiming
        bounty.rewardAmount = 0; // Clear reward amount

        aetheriumToken.safeTransfer(msg.sender, reward);
        emit BountyClaimed(_bountyId, msg.sender, reward);
    }

    /**
     * @dev Allows the bounty creator to cancel an unfulfilled bounty and reclaim their Aetherium tokens before the deadline.
     * @param _bountyId The ID of the bounty to rescind.
     */
    function rescindBounty(uint256 _bountyId) external onlyBountyCreator(_bountyId) whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.status == BountyStatus.Open, "AetherialForge: Bounty is not open");
        require(block.timestamp < bounty.deadline, "AetherialForge: Cannot rescind bounty after deadline");

        uint256 refundAmount = bounty.rewardAmount;
        bounty.status = BountyStatus.Cancelled;
        bounty.rewardAmount = 0;

        aetheriumToken.safeTransfer(msg.sender, refundAmount);
        emit BountyRescinded(_bountyId, msg.sender, refundAmount);
    }

    // --- VIII. Staking & Challenge System ---

    /**
     * @dev Any user can challenge the originality or validity of a staked artifact by placing a counter-stake.
     * @param _artifactId The ID of the artifact to challenge.
     * @param _challengeStakeAmount The amount of Aetherium tokens to stake for the challenge.
     */
    function challengeArtifactOriginality(uint256 _artifactId, uint256 _challengeStakeAmount) external whenNotPaused {
        require(address(aetheriumToken) != address(0), "AetherialForge: Aetherium token not set");
        require(_artifactId > 0 && _artifactId <= _artifactIds.current(), "AetherialForge: Invalid artifact ID");
        Artifact storage artifact = artifacts[_artifactId];
        require(!artifact.isDeleted, "AetherialForge: Cannot challenge a deleted artifact");
        require(artifact.owner != msg.sender, "AetherialForge: Cannot challenge your own artifact");
        require(!artifact.isChallenged, "AetherialForge: Artifact is already under challenge");
        require(_challengeStakeAmount >= artifact.stakeAmount, "AetherialForge: Challenge stake must be at least the artifact's stake");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        aetheriumToken.safeTransferFrom(msg.sender, address(this), _challengeStakeAmount);

        challenges[newChallengeId] = Challenge({
            artifactId: _artifactId,
            challenger: msg.sender,
            challengerStake: _challengeStakeAmount,
            createdAt: block.timestamp,
            isActive: true,
            resolved: false,
            challengerWon: false
        });

        artifact.isChallenged = true;
        artifact.challengeId = newChallengeId;

        emit ArtifactChallengeInitiated(_artifactId, newChallengeId, msg.sender, _challengeStakeAmount);
    }

    /**
     * @dev Owner or guardian resolves an artifact challenge. The stake is awarded to the winner, and reputation scores of both parties are adjusted.
     * @param _artifactId The ID of the artifact whose challenge is being resolved.
     * @param _challengerWins True if the challenger's claim is valid (original artifact is not original/valid), false otherwise.
     */
    function resolveChallenge(uint256 _artifactId, bool _challengerWins) external whenNotPaused {
        require(msg.sender == owner() || msg.sender == guardian, "AetherialForge: Not owner or guardian to resolve challenges");
        require(_artifactId > 0 && _artifactId <= _artifactIds.current(), "AetherialForge: Invalid artifact ID");
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.isChallenged, "AetherialForge: Artifact is not under challenge");

        Challenge storage challenge = challenges[artifact.challengeId];
        require(challenge.isActive, "AetherialForge: Challenge already resolved or inactive");

        challenge.resolved = true;
        challenge.isActive = false;
        challenge.challengerWon = _challengerWins;
        artifact.isChallenged = false; // Mark artifact as no longer challenged

        uint256 artifactStake = artifact.stakeAmount;
        uint256 challengerStake = challenge.challengerStake;
        uint256 totalPool = artifactStake + challengerStake;
        uint256 guardianFee = (totalPool * CHALLENGE_RESOLUTION_FEE_PERCENT) / 100;

        if (_challengerWins) {
            // Challenger wins: challenger gets their stake back + artifact owner's stake (minus fee)
            aetheriumToken.safeTransfer(challenge.challenger, challengerStake + artifactStake - guardianFee);
            _updateReputationScore(challenge.challenger, 30); // Challenger wins reputation
            _updateReputationScore(artifact.owner, -50); // Artifact owner loses significant reputation
            artifact.isDeleted = true; // Mark challenged artifact as deleted/invalidated
        } else {
            // Artifact owner wins: artifact owner gets their stake back + challenger's stake (minus fee)
            aetheriumToken.safeTransfer(artifact.owner, artifactStake + challengerStake - guardianFee);
            _updateReputationScore(artifact.owner, 15); // Artifact owner wins reputation
            _updateReputationScore(challenge.challenger, -25); // Challenger loses reputation
        }
        
        // Guardian collects fee
        if (guardianFee > 0) {
            aetheriumToken.safeTransfer(guardian, guardianFee);
        }

        emit ArtifactChallengeResolved(_artifactId, artifact.challengeId, msg.sender, _challengerWins);
    }

    /**
     * @dev Allows an artifact owner to withdraw their initial stake if no challenges exist
     *      and a grace period has passed, or after a challenge is resolved in their favor.
     * @param _artifactId The ID of the artifact to withdraw stake from.
     */
    function withdrawStakedAetherium(uint256 _artifactId) external onlyArtifactOwner(_artifactId) whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        require(!artifact.isChallenged, "AetherialForge: Cannot withdraw stake while challenged");
        require(artifact.stakeAmount > 0, "AetherialForge: No stake to withdraw");

        // Case 1: No challenge, grace period passed
        bool noActiveChallenge = artifact.challengeId == 0 || !challenges[artifact.challengeId].isActive;
        require(noActiveChallenge, "AetherialForge: Challenge is still active");
        require(block.timestamp >= artifact.createdAt + ARTIFACT_STAKE_GRACE_PERIOD, "AetherialForge: Grace period not over yet");

        // Case 2: Challenge resolved in owner's favor (handled by resolveChallenge, which transfers funds directly)
        // If funds were not transferred by resolveChallenge, it means it's case 1.

        uint256 amountToWithdraw = artifact.stakeAmount;
        artifact.stakeAmount = 0; // Clear stake

        aetheriumToken.safeTransfer(msg.sender, amountToWithdraw);
        emit AetheriumStakedWithdrawn(_artifactId, msg.sender, amountToWithdraw);
    }
}
```