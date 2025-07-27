Here's a Solidity smart contract for a "CognitoSphere DAO," a decentralized platform for collective knowledge validation and curation. It incorporates several advanced, creative, and trendy concepts:

*   **Dynamic NFTs (ThoughtCapsuleNFTs):** NFTs whose on-chain properties (`veracityScore`, `aiAffinityScore`, `resonanceScore`) evolve based on community interaction and AI insights.
*   **AI Oracle Integration:** The DAO can request and receive AI-generated assessments (e.g., `aiAffinityScore`) for knowledge capsules from a trusted off-chain oracle.
*   **Reputation System:** Contributors earn and lose on-chain reputation based on the quality of their submissions and challenges, influencing their governance power and rewards.
*   **Adaptive Governance:** Voting power is derived from a combination of staked tokens and earned reputation, and proposals involve a dynamic quorum concept.
*   **Time-Decay Mechanism:** Knowledge capsules' scores can degrade over time, promoting continuous re-validation and relevance.
*   **Challenge System:** A mechanism for users to dispute the veracity of knowledge contributions, with stakes and reputation implications.

This design aims to be novel by combining these elements into a unique use case for building a verifiable, community-curated knowledge base.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// --- CONTRACT OUTLINE ---
// CognitoSphere DAO: A Decentralized Collective Knowledge Validation & Curation Platform
// Objective: To create a self-governing ecosystem for verifiable knowledge contributions,
//            leveraging reputation, AI-informed validation (via oracle), and adaptive
//            governance to build a robust, dynamic information repository.
// Core Components:
// 1. ThoughtCapsuleNFT (ERC-721): Represents a unique knowledge contribution, with dynamic
//    `veracityScore`, `aiAffinityScore`, and `resonanceScore`.
// 2. CognitoToken (ERC-20): The utility and governance token for staking, rewards, and participation.
// 3. Reputation System: On-chain score for contributors, influencing voting power and rewards.
// 4. Challenge & Resolution: Mechanism for disputing knowledge capsule veracity.
// 5. AI Oracle Integration: A trusted oracle provides external AI insights to influence capsule scores.
// 6. Adaptive Governance: Reputation-weighted, stake-augmented voting with dynamic thresholds.
// 7. Treasury: Manages funds for rewards, development, and operational costs.

// --- FUNCTION SUMMARY ---

// I. Core Setup & Administration (`CognitoSphereDAO.sol`)
// 1.  constructor(): Initializes the contract with linked token/NFT addresses, sets initial oracle address.
// 2.  pause(): Pauses core operations (emergency). Callable by contract owner.
// 3.  unpause(): Unpauses core operations. Callable by contract owner.
// 4.  setModuleAddress(uint8 _moduleId, address _newAddress): Allows the DAO owner (initially deployer, later potentially governance)
//     to upgrade/set addresses for modules like Oracle or future extensions.

// II. Thought Capsule Management (Interacts with `ThoughtCapsuleNFT.sol`)
// 5.  submitThoughtCapsule(string calldata _ipfsHash, string calldata _metadataURI, string[] calldata _tags):
//     Mints a new ThoughtCapsuleNFT for the contributor. Assigns an initial veracityScore.
// 6.  updateThoughtCapsuleMetadata(uint256 _tokenId, string calldata _newMetadataURI):
//     Allows the owner of a ThoughtCapsuleNFT to update its associated metadata URI.
// 7.  getThoughtCapsuleDetails(uint256 _tokenId): Returns all relevant details of a capsule, including its scores and IPFS content hash.

// III. Veracity & Resonance System (`CognitoSphereDAO.sol` interacts with `ThoughtCapsuleNFT.sol`'s state)
// 8.  challengeThoughtCapsule(uint256 _tokenId, string calldata _reason, uint256 _stakeAmount):
//     Initiates a challenge against a capsule's veracity, requiring a stake in CognitoToken.
// 9.  resolveChallenge(uint256 _challengeId, bool _isVeracious, uint256 _oracleAIAffinityScore):
//     Callable by the DAO owner (acting as governance/resolver) to conclude a challenge. Updates veracityScore
//     and aiAffinityScore, distributing/slashing challenge stakes and updating reputations.
// 10. upvoteThoughtCapsule(uint256 _tokenId): Allows users to signal approval, incrementally increasing
//     `resonanceScore` (a component of `veracityScore`) and granting a minor reputation boost.
// 11. decayCapsuleScores(uint256[] calldata _tokenIds): A callable function (e.g., by a keeper network or governance)
//     to apply time-decay to `veracityScore` and `resonanceScore` for specified capsules, promoting active curation.

// IV. Reputation System (`CognitoSphereDAO.sol`)
// 12. getContributorReputation(address _contributor): Retrieves a contributor's on-chain reputation score.
// 13. claimReputationRewards(): Allows high-reputation contributors to claim periodic CognitoToken rewards based on their score.

// V. AI Oracle Integration (`CognitoSphereDAO.sol`)
// 14. requestAIAffinityScore(uint256 _tokenId): Initiates an off-chain oracle request for an AI's
//     assessment of a capsule's content, emitting an event for the oracle to pick up.
// 15. receiveAIAffinityScore(uint256 _queryId, uint256 _tokenId, uint256 _score):
//     Callback function, callable only by the designated oracle, to update a capsule's aiAffinityScore after an assessment.

// VI. Adaptive Governance (`CognitoSphereDAO.sol` - Simplified, integrated for this demo)
// 16. proposeGovernanceAction(address _targetContract, bytes calldata _callData, string calldata _description):
//     Creates a new governance proposal for arbitrary contract interactions (e.g., upgrades, treasury ops, parameter changes),
//     requiring minimum voting power from the proposer.
// 17. voteOnProposal(uint256 _proposalId, bool _support): Allows staked token holders and
//     high-reputation contributors to cast votes on a proposal during its active period.
// 18. executeProposal(uint256 _proposalId): Executes a passed proposal if the voting period has ended,
//     quorum is met, and the approval threshold is reached.
// 19. delegateVotingPower(address _delegate): Allows users to delegate their combined token + reputation
//     voting power to another address.

// VII. Treasury & Token Management (`CognitoSphereDAO.sol` & `CognitoToken.sol`)
// 20. stakeTokens(uint256 _amount): Allows users to stake CognitoToken to gain voting power and earn rewards.
// 21. unstakeTokens(uint256 _amount): Allows users to unstake tokens from their staked balance.
// 22. distributeProtocolRewards(address[] calldata _recipients, uint256[] calldata _amounts):
//     Governance-controlled function to mint and distribute rewards from the DAO's treasury to specified recipients.

// --- Smart Contracts ---

// CognitoToken.sol
// A simple ERC-20 token for utility, staking, and rewards.
contract CognitoToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("CognitoToken", "CGT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Only the DAO contract (which will become owner via transferOwnership) or initial owner can mint new tokens for rewards.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Prevent direct transfers from the DAO contract itself. Ensure only DAO's internal logic dictates movement.
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(msg.sender != address(this), "CGT: DAO cannot transfer directly via this function");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(msg.sender != address(this), "CGT: DAO cannot transferFrom directly via this function");
        return super.transferFrom(from, to, amount);
    }
}

// ThoughtCapsuleNFT.sol
// Represents a knowledge contribution with dynamic on-chain scores.
contract ThoughtCapsuleNFT is ERC721, Ownable {
    using SafeCast for uint256;

    // Struct to hold dynamic scores for each NFT
    struct CapsuleScores {
        uint16 veracityScore;  // 0-1000, e.g., 500 initial, affected by challenges & decay
        uint16 aiAffinityScore; // 0-1000, set by AI oracle
        uint16 resonanceScore;  // 0-1000, affected by upvotes and decay
    }

    // Mapping from tokenId to its dynamic scores
    mapping(uint256 => CapsuleScores) public capsuleScores;
    // Mapping from tokenId to its content IPFS hash (e.g., hash of the actual knowledge content)
    mapping(uint256 => string) public capsuleContentHashes;

    // Event for score updates
    event VeracityScoreUpdated(uint256 indexed tokenId, uint16 oldScore, uint16 newScore);
    event AIAffinityScoreUpdated(uint256 indexed tokenId, uint16 oldScore, uint16 newScore);
    event ResonanceScoreUpdated(uint256 indexed tokenId, uint16 oldScore, uint16 newScore);

    // The address of the controlling DAO contract, which will be the owner
    address public cognitoSphereDAO;

    constructor(address _cognitoSphereDAOAddress) ERC721("ThoughtCapsule", "THOUGHT") Ownable(msg.sender) {
        cognitoSphereDAO = _cognitoSphereDAOAddress;
    }

    // Modifier to restrict calls to the current owner, which should be the CognitoSphereDAO
    modifier onlyDAOOwner() {
        require(msg.sender == owner(), "Only the owner (CognitoSphereDAO) can call this function");
        require(owner() == cognitoSphereDAO, "CognitoSphereDAO must be the owner of this contract.");
        _;
    }

    // Function to mint a new capsule, callable only by the DAO owner
    // This allows the DAO to control the creation and initial state of ThoughtCapsule NFTs.
    function mintCapsule(address to, uint256 tokenId, string calldata ipfsHash, string calldata metadataURI) external onlyDAOOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, metadataURI); // NFT metadata URI (e.g., JSON file with image, description)
        capsuleContentHashes[tokenId] = ipfsHash; // Store the content hash itself
        capsuleScores[tokenId] = CapsuleScores({
            veracityScore: 500, // Initial neutral score
            aiAffinityScore: 0, // Awaiting AI assessment
            resonanceScore: 0   // Awaiting community engagement
        });
    }

    // Overridden ERC721's setTokenURI to allow the token's owner OR the DAO to update it.
    function setTokenURI(uint256 _tokenId, string calldata _newURI) public override {
        // Allows the token's current owner OR the DAO to update the URI
        require(_isApprovedOrOwner(_msgSender(), _tokenId) || _msgSender() == cognitoSphereDAO, "ERC721: caller is not token owner, nor approved, nor DAO");
        _setTokenURI(_tokenId, _newURI);
    }

    // Functions to update scores, callable only by the DAO owner.
    function updateVeracityScore(uint256 _tokenId, uint16 _newScore) external onlyDAOOwner {
        require(_newScore <= 1000, "Score must be <= 1000");
        uint16 oldScore = capsuleScores[_tokenId].veracityScore;
        capsuleScores[_tokenId].veracityScore = _newScore;
        emit VeracityScoreUpdated(_tokenId, oldScore, _newScore);
    }

    function updateAIAffinityScore(uint256 _tokenId, uint16 _newScore) external onlyDAOOwner {
        require(_newScore <= 1000, "Score must be <= 1000");
        uint16 oldScore = capsuleScores[_tokenId].aiAffinityScore;
        capsuleScores[_tokenId].aiAffinityScore = _newScore;
        emit AIAffinityScoreUpdated(_tokenId, oldScore, _newScore);
    }

    function updateResonanceScore(uint256 _tokenId, uint16 _newScore) external onlyDAOOwner {
        require(_newScore <= 1000, "Score must be <= 1000");
        uint16 oldScore = capsuleScores[_tokenId].resonanceScore;
        capsuleScores[_tokenId].resonanceScore = _newScore;
        emit ResonanceScoreUpdated(_tokenId, oldScore, _newScore);
    }
}


// CognitoSphereDAO.sol
contract CognitoSphereDAO is Ownable, Pausable {
    using SafeCast for uint256;

    // --- Linked Contracts ---
    CognitoToken public cognitoToken;
    ThoughtCapsuleNFT public thoughtCapsuleNFT;
    address public aiOracleAddress;

    // --- Module IDs for generic setter ---
    // These IDs are used with setModuleAddress to specify which external address is being set.
    uint8 public constant MODULE_ORACLE = 1; // ID for the AI oracle address

    // --- State Variables ---

    // Reputation System
    mapping(address => int256) public contributorReputation; // Can be negative for bad actors
    uint256 public constant REPUTATION_SCALE_FACTOR = 1e12; // Used to allow fractional reputation internally (e.g., 1.5 reputation = 1.5e12)
    uint256 public constant BASE_REPUTATION_FOR_SUBMISSION = 10 * REPUTATION_SCALE_FACTOR; // Initial reputation boost for submitting a valid capsule

    // Challenge System
    struct Challenge {
        uint256 tokenId;
        address challenger;
        uint256 stakeAmount;
        string reason;
        bool resolved;
        bool challengerWon; // True if challenge was successful (capsule found non-veracious)
    }
    Challenge[] public challenges; // Stores all initiated challenges
    mapping(uint256 => bool) public activeChallenges; // tokenId => true if under active challenge
    uint256 public challengeFeePercentage = 5; // % of stake taken as fee on failed challenge
    uint256 public constant MIN_CHALLENGE_STAKE = 100 * (10 ** 18); // Example: 100 CGT minimum stake

    // Oracle System
    uint256 private nextOracleQueryId = 1; // Counter for unique oracle request IDs
    mapping(uint256 => uint256) public oracleQueryToTokenId; // Maps queryId to tokenId being queried
    mapping(uint256 => bool) public oracleQueryPending; // tokenId => true if an oracle request is pending for it

    // Governance System (simplified for this contract to demonstrate adaptive governance)
    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Contract to interact with if proposal passes
        bytes callData;         // Data for the function call on the targetContract
        uint256 quorumThreshold; // Minimum total voting power required to consider the proposal valid (dynamic)
        uint256 approvalThreshold; // Percentage of 'yes' votes needed (e.g., 51 for 51%)
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;
    }
    Proposal[] public proposals; // Stores all governance proposals
    uint256 public nextProposalId = 0;
    uint256 public votingPeriodDuration = 3 days; // Default duration for proposals
    uint256 public minimumVotingPowerForProposal = 50 * (10 ** 18); // Minimum combined voting power to propose
    uint256 public reputationVotingWeight = 1 * (10 ** 18); // 1 CGT equivalent voting power per 1 (scaled) unit of reputation
    mapping(address => address) public votingDelegates; // Delegate voting power

    // Staking
    mapping(address => uint256) public stakedBalances; // User's staked CognitoToken balance

    // Reward System (simplified)
    uint256 public constant REWARD_PERIOD_SECONDS = 30 days; // Interval for potential reputation-based reward claims
    mapping(address => uint256) public lastReputationRewardClaimTime; // Tracks last claim time for each user
    uint256 public reputationRewardPerScaledUnit = 1; // Amount of CGT (unscaled) per REPUTATION_SCALE_FACTOR unit of reputation per period

    // --- Events ---
    event ThoughtCapsuleSubmitted(uint256 indexed tokenId, address indexed contributor, string ipfsHash);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed tokenId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed tokenId, bool isVeracious, address resolver);
    event AIAffinityRequested(uint256 indexed queryId, uint256 indexed tokenId);
    event AIAffinityReceived(uint256 indexed queryId, uint256 indexed tokenId, uint256 score);
    event ReputationUpdated(address indexed contributor, int256 newReputation);
    event ReputationRewardsClaimed(address indexed recipient, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event Delegated(address indexed delegator, address indexed delegatee);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed unstaker, uint256 amount);
    event ProtocolRewardsDistributed(address[] recipients, uint256[] amounts);
    event ModuleAddressUpdated(uint8 indexed moduleId, address newAddress);


    // --- Constructor ---
    // Initializes the DAO with addresses of the CognitoToken and ThoughtCapsuleNFT contracts,
    // and an initial AI oracle address. Transfers NFT contract ownership to the DAO.
    constructor(address _cognitoTokenAddress, address _thoughtCapsuleNFTAddress, address _initialOracleAddress) Ownable(msg.sender) Pausable() {
        cognitoToken = CognitoToken(_cognitoTokenAddress);
        thoughtCapsuleNFT = ThoughtCapsuleNFT(_thoughtCapsuleNFTAddress);
        aiOracleAddress = _initialOracleAddress;

        // Transfer ownership of the ThoughtCapsuleNFT contract to this DAO.
        // This allows the DAO to control minting and score updates for NFTs.
        thoughtCapsuleNFT.transferOwnership(address(this));
    }

    // --- I. Core Setup & Administration ---

    /// @notice Pauses core operations. Only callable by the current contract owner.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses core operations. Only callable by the current contract owner.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the DAO owner to set/update addresses for linked modules (e.g., Oracle).
    /// @param _moduleId An identifier for the module (e.g., `MODULE_ORACLE`).
    /// @param _newAddress The new address for the module.
    function setModuleAddress(uint8 _moduleId, address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        if (_moduleId == MODULE_ORACLE) {
            aiOracleAddress = _newAddress;
        } else {
            revert("Unknown module ID");
        }
        emit ModuleAddressUpdated(_moduleId, _newAddress);
    }


    // --- II. Thought Capsule Management ---

    /// @notice Submits a new knowledge capsule and mints a ThoughtCapsuleNFT for the caller.
    /// A base reputation boost is granted for the submission.
    /// @param _ipfsHash The IPFS hash pointing to the raw content of the capsule.
    /// @param _metadataURI The URI for the NFT metadata (e.g., IPFS link to JSON describing the capsule).
    /// @param _tags An array of tags for classification (on-chain storage of tags not fully implemented for gas efficiency).
    /// @return The ID of the newly minted NFT.
    function submitThoughtCapsule(string calldata _ipfsHash, string calldata _metadataURI, string[] calldata _tags)
        public whenNotPaused returns (uint256)
    {
        uint256 tokenId = thoughtCapsuleNFT.totalSupply(); // Simple sequential ID for new NFT
        thoughtCapsuleNFT.mintCapsule(msg.sender, tokenId, _ipfsHash, _metadataURI);

        // Grant initial reputation boost to the submitter
        _updateReputation(msg.sender, BASE_REPUTATION_FOR_SUBMISSION);

        emit ThoughtCapsuleSubmitted(tokenId, msg.sender, _ipfsHash);
        return tokenId;
    }

    /// @notice Allows the owner of a ThoughtCapsuleNFT to update its metadata URI.
    /// This function calls the `setTokenURI` on the `ThoughtCapsuleNFT` contract.
    /// @param _tokenId The ID of the ThoughtCapsuleNFT.
    /// @param _newMetadataURI The new URI for the NFT metadata.
    function updateThoughtCapsuleMetadata(uint256 _tokenId, string calldata _newMetadataURI) public whenNotPaused {
        require(thoughtCapsuleNFT.ownerOf(_tokenId) == msg.sender, "Caller must be capsule owner");
        thoughtCapsuleNFT.setTokenURI(_tokenId, _newMetadataURI);
    }

    /// @notice Retrieves detailed information about a ThoughtCapsule, including its dynamic scores.
    /// @param _tokenId The ID of the ThoughtCapsuleNFT.
    /// @return owner The owner address of the NFT.
    /// @return ipfsHash The IPFS content hash associated with the capsule.
    /// @return metadataURI The NFT metadata URI.
    /// @return veracityScore The current veracity score (0-1000).
    /// @return aiAffinityScore The current AI affinity score (0-1000).
    /// @return resonanceScore The current resonance score (0-1000).
    function getThoughtCapsuleDetails(uint256 _tokenId)
        public view returns (address owner, string memory ipfsHash, string memory metadataURI, uint16 veracityScore, uint16 aiAffinityScore, uint16 resonanceScore)
    {
        owner = thoughtCapsuleNFT.ownerOf(_tokenId);
        ipfsHash = thoughtCapsuleNFT.capsuleContentHashes(_tokenId);
        metadataURI = thoughtCapsuleNFT.tokenURI(_tokenId);

        ThoughtCapsuleNFT.CapsuleScores memory scores = thoughtCapsuleNFT.capsuleScores(_tokenId);
        veracityScore = scores.veracityScore;
        aiAffinityScore = scores.aiAffinityScore;
        resonanceScore = scores.resonanceScore;
        return (owner, ipfsHash, metadataURI, veracityScore, aiAffinityScore, resonanceScore);
    }


    // --- III. Veracity & Resonance System ---

    /// @notice Initiates a challenge against a capsule's veracity, requiring a stake.
    /// The challenge proceeds to a resolution phase (via `resolveChallenge`).
    /// @param _tokenId The ID of the ThoughtCapsuleNFT to challenge.
    /// @param _reason A brief description for the challenge.
    /// @param _stakeAmount The amount of CognitoToken to stake for the challenge.
    function challengeThoughtCapsule(uint256 _tokenId, string calldata _reason, uint256 _stakeAmount) public whenNotPaused {
        require(thoughtCapsuleNFT.ownerOf(_tokenId) != address(0), "Capsule does not exist");
        require(!activeChallenges[_tokenId], "Capsule already under active challenge");
        require(_stakeAmount >= MIN_CHALLENGE_STAKE, "Stake amount too low");
        
        // Transfer challenge stake from msg.sender to the DAO contract's balance
        require(cognitoToken.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer for stake failed");

        uint256 challengeId = challenges.length;
        challenges.push(Challenge({
            tokenId: _tokenId,
            challenger: msg.sender,
            stakeAmount: _stakeAmount,
            reason: _reason,
            resolved: false,
            challengerWon: false
        }));
        activeChallenges[_tokenId] = true;

        emit ChallengeInitiated(challengeId, _tokenId, msg.sender, _stakeAmount);
    }

    /// @notice Resolves a pending challenge. Only callable by the DAO owner (acting as dispute resolver).
    /// Updates capsule scores and distributes/slashes stakes based on resolution outcome.
    /// Adjusts challenger's and capsule owner's reputations.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _isVeracious True if the capsule is deemed veracious (challenger loses), false otherwise (challenger wins).
    /// @param _oracleAIAffinityScore The AI affinity score for the capsule provided by an oracle (0-1000).
    function resolveChallenge(uint256 _challengeId, bool _isVeracious, uint256 _oracleAIAffinityScore) public onlyOwner whenNotPaused {
        require(_challengeId < challenges.length, "Invalid challenge ID");
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.resolved, "Challenge already resolved");
        require(_oracleAIAffinityScore <= 1000, "AI affinity score must be <= 1000");

        challenge.resolved = true;
        activeChallenges[challenge.tokenId] = false;

        thoughtCapsuleNFT.updateAIAffinityScore(challenge.tokenId, _oracleAIAffinityScore.toUint16());

        if (_isVeracious) {
            // Challenger loses: A portion of stake is taken as fee, remaining to DAO treasury.
            uint256 fee = (challenge.stakeAmount * challengeFeePercentage) / 100;
            uint256 remainingStake = challenge.stakeAmount - fee;
            
            // Transfer remaining stake to DAO treasury (held by this contract)
            // No need to transfer as it's already on this contract's balance from challenge initiation
            // But if it was held by a separate escrow, it would be transferred here.
            // For now, it stays with DAO, and fee is effectively burned/lost.
            // A more explicit burn: cognitoToken.transfer(address(0xdead), fee);

            // Reduce challenger's reputation for a failed challenge
            _updateReputation(challenge.challenger, -int256(BASE_REPUTATION_FOR_SUBMISSION)); 
            
            // Optionally increase capsule owner's reputation if their capsule was upheld
            address capsuleOwner = thoughtCapsuleNFT.ownerOf(challenge.tokenId);
            if (capsuleOwner != challenge.challenger) {
                _updateReputation(capsuleOwner, int256(BASE_REPUTATION_FOR_SUBMISSION / 2));
            }
            // Small veracity boost for the capsule
            thoughtCapsuleNFT.updateVeracityScore(challenge.tokenId, (thoughtCapsuleNFT.capsuleScores(challenge.tokenId).veracityScore + 100).toUint16());
        } else {
            // Challenger wins: stake is returned to the challenger.
            challenge.challengerWon = true;
            require(cognitoToken.transfer(challenge.challenger, challenge.stakeAmount), "Failed to return stake to challenger");

            // Boost challenger's reputation for a successful challenge
            _updateReputation(challenge.challenger, int256(BASE_REPUTATION_FOR_SUBMISSION * 2));
            
            // Significantly reduce capsule owner's reputation and capsule veracity
            address capsuleOwner = thoughtCapsuleNFT.ownerOf(challenge.tokenId);
            _updateReputation(capsuleOwner, -int256(BASE_REPUTATION_FOR_SUBMISSION * 2));
            thoughtCapsuleNFT.updateVeracityScore(challenge.tokenId, (thoughtCapsuleNFT.capsuleScores(challenge.tokenId).veracityScore >= 200 ? thoughtCapsuleNFT.capsuleScores(challenge.tokenId).veracityScore - 200 : 0).toUint16());
        }

        emit ChallengeResolved(_challengeId, challenge.tokenId, _isVeracious, msg.sender);
    }

    /// @notice Allows users to upvote a ThoughtCapsule, incrementally increasing its resonance score.
    /// Also grants a small reputation boost to the upvoter.
    /// @param _tokenId The ID of the ThoughtCapsuleNFT to upvote.
    function upvoteThoughtCapsule(uint256 _tokenId) public whenNotPaused {
        require(thoughtCapsuleNFT.ownerOf(_tokenId) != address(0), "Capsule does not exist");
        // Could implement per-user cooldown or unique vote per capsule using a mapping:
        // mapping(uint256 => mapping(address => bool)) public hasUpvoted;
        // require(!hasUpvoted[_tokenId][msg.sender], "Already upvoted this capsule");
        // hasUpvoted[_tokenId][msg.sender] = true;

        ThoughtCapsuleNFT.CapsuleScores memory currentScores = thoughtCapsuleNFT.capsuleScores(_tokenId);
        uint16 newResonance = currentScores.resonanceScore + 10; // Increment by a small amount
        if (newResonance > 1000) newResonance = 1000; // Cap at max score
        thoughtCapsuleNFT.updateResonanceScore(_tokenId, newResonance);

        // Small reputation boost for engaging positively with content
        _updateReputation(msg.sender, 1 * REPUTATION_SCALE_FACTOR);
    }

    /// @notice Applies a time-decay to specified capsule scores (veracity and resonance).
    /// This function is typically called periodically by a decentralized keeper network or DAO governance.
    /// @param _tokenIds An array of token IDs for which to apply decay.
    function decayCapsuleScores(uint256[] calldata _tokenIds) public onlyOwner whenNotPaused {
        uint16 decayAmountVeracity = 10; // Example decay amount for veracity
        uint16 decayAmountResonance = 50; // Resonance decays faster

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            ThoughtCapsuleNFT.CapsuleScores memory currentScores = thoughtCapsuleNFT.capsuleScores(tokenId);

            // Apply decay, ensuring scores don't go below zero
            uint16 newVeracity = currentScores.veracityScore >= decayAmountVeracity ? currentScores.veracityScore - decayAmountVeracity : 0;
            uint16 newResonance = currentScores.resonanceScore >= decayAmountResonance ? currentScores.resonanceScore - decayAmountResonance : 0;

            thoughtCapsuleNFT.updateVeracityScore(tokenId, newVeracity);
            thoughtCapsuleNFT.updateResonanceScore(tokenId, newResonance);
        }
    }


    // --- IV. Reputation System ---

    /// @notice Retrieves a contributor's on-chain reputation score.
    /// The score is scaled internally by `REPUTATION_SCALE_FACTOR`.
    /// @param _contributor The address of the contributor.
    /// @return The reputation score.
    function getContributorReputation(address _contributor) public view returns (int256) {
        return contributorReputation[_contributor];
    }

    /// @dev Internal function to update a contributor's reputation score.
    /// Emits a `ReputationUpdated` event.
    /// @param _contributor The address whose reputation to update.
    /// @param _reputationChange The amount to add or subtract from reputation (scaled by `REPUTATION_SCALE_FACTOR`).
    function _updateReputation(address _contributor, int256 _reputationChange) internal {
        contributorReputation[_contributor] += _reputationChange;
        emit ReputationUpdated(_contributor, contributorReputation[_contributor]);
    }

    /// @notice Allows high-reputation contributors to claim periodic CognitoToken rewards.
    /// Rewards are calculated based on their reputation and the time elapsed since their last claim.
    function claimReputationRewards() public whenNotPaused {
        require(contributorReputation[msg.sender] > 0, "No positive reputation to claim rewards");
        require(block.timestamp >= lastReputationRewardClaimTime[msg.sender] + REWARD_PERIOD_SECONDS, "Reward cooldown not over");

        uint256 reputation = contributorReputation[msg.sender].toUint256();
        // Calculate reward based on reputation (scaled) and number of full reward periods passed
        uint256 numPeriods = (block.timestamp - lastReputationRewardClaimTime[msg.sender]) / REWARD_PERIOD_SECONDS;
        if (lastReputationRewardClaimTime[msg.sender] == 0) { // First claim ever
            numPeriods = 1; // Or some initial setup period
        }

        uint256 rewardAmount = (reputation / REPUTATION_SCALE_FACTOR) * reputationRewardPerScaledUnit * numPeriods * (10 ** 18); // Example: 1 CGT per reputation unit per period
        
        require(rewardAmount > 0, "No rewards accrued to claim");

        // Mint and transfer rewards from the DAO contract's balance
        // Assumes DAO is the owner of CognitoToken and can mint
        cognitoToken.mint(msg.sender, rewardAmount);
        lastReputationRewardClaimTime[msg.sender] = block.timestamp; // Update last claim time

        // Emit simplified rewards distributed event (can be more detailed)
        emit ReputationRewardsClaimed(msg.sender, rewardAmount);
    }


    // --- V. AI Oracle Integration ---

    /// @notice Initiates an off-chain oracle request for an AI's assessment of a capsule's content.
    /// This function emits an event that an off-chain oracle client is expected to monitor and respond to.
    /// @param _tokenId The ID of the ThoughtCapsuleNFT to be assessed by AI.
    function requestAIAffinityScore(uint256 _tokenId) public whenNotPaused {
        require(thoughtCapsuleNFT.ownerOf(_tokenId) != address(0), "Capsule does not exist");
        require(!activeChallenges[_tokenId], "Cannot request AI affinity during active challenge"); // Avoid conflicts
        require(!oracleQueryPending[_tokenId], "AI affinity request already pending for this capsule");

        uint256 queryId = nextOracleQueryId++;
        oracleQueryToTokenId[queryId] = _tokenId;
        oracleQueryPending[_tokenId] = true;

        emit AIAffinityRequested(queryId, _tokenId);
    }

    /// @notice Callback function from the designated AI oracle to update a capsule's AI affinity score.
    /// This function must only be callable by the pre-set `aiOracleAddress`.
    /// @param _queryId The ID of the original oracle request.
    /// @param _tokenId The ID of the ThoughtCapsuleNFT for which the score is received.
    /// @param _score The AI affinity score (0-1000) provided by the oracle.
    function receiveAIAffinityScore(uint256 _queryId, uint256 _tokenId, uint256 _score) public whenNotPaused {
        require(msg.sender == aiOracleAddress, "Only the designated AI oracle can call this");
        require(oracleQueryToTokenId[_queryId] == _tokenId, "Mismatched query ID and token ID");
        require(oracleQueryPending[_tokenId], "No pending AI affinity request for this capsule");
        require(_score <= 1000, "AI affinity score must be <= 1000");

        thoughtCapsuleNFT.updateAIAffinityScore(_tokenId, _score.toUint16());
        delete oracleQueryToTokenId[_queryId];
        delete oracleQueryPending[_tokenId]; // Clear pending status for this tokenId

        emit AIAffinityReceived(_queryId, _tokenId, _score);
    }


    // --- VI. Adaptive Governance ---

    /// @notice Creates a new governance proposal for arbitrary contract interactions.
    /// Requires the proposer to have a minimum combined voting power.
    /// @param _targetContract The address of the contract that the proposal aims to call.
    /// @param _callData The encoded function call data for the target contract.
    /// @param _description A detailed description of the proposal.
    function proposeGovernanceAction(address _targetContract, bytes calldata _callData, string calldata _description) public whenNotPaused {
        require(getVotingPower(msg.sender) >= minimumVotingPowerForProposal, "Insufficient voting power to propose");

        uint256 proposalId = nextProposalId++;
        proposals.push(Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            quorumThreshold: 0, // Calculated dynamically during execution check
            approvalThreshold: 51, // Default 51% 'yes' votes needed
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        }));
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows staked token holders and high-reputation contributors to cast votes on a proposal.
    /// Each voter's power is determined by `getVotingPower`.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'Yes' vote, False for a 'No' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period not active");
        
        address effectiveVoter = votingDelegates[msg.sender] != address(0) ? votingDelegates[msg.sender] : msg.sender;
        require(!proposal.hasVoted[effectiveVoter], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(effectiveVoter);
        require(voterPower > 0, "No voting power");

        if (_support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        proposal.hasVoted[effectiveVoter] = true;

        emit Voted(_proposalId, effectiveVoter, _support);
    }

    /// @notice Executes a passed governance proposal.
    /// Checks if the voting period has ended, quorum is met, and the approval threshold is reached.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast for this proposal");

        // Dynamic quorum check: e.g., require 10% of total staked tokens + reputation power to have voted.
        // For simplicity, let's use a fixed base combined with total supply for a more dynamic feel.
        uint256 dynamicQuorum = (cognitoToken.totalSupply() / 10) + (100 * REPUTATION_SCALE_FACTOR * reputationVotingWeight); // Example: 10% of total tokens + 100 units of reputation-based power
        require(totalVotes >= dynamicQuorum, "Quorum not met for this proposal");

        // Check if 'yes' votes meet the approval threshold
        require((proposal.yesVotes * 100) / totalVotes >= proposal.approvalThreshold, "Proposal not approved by majority");

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows a user to delegate their combined token + reputation voting power to another address.
    /// @param _delegate The address to delegate voting power to. Set to `address(0)` to undelegate.
    function delegateVotingPower(address _delegate) public {
        require(_delegate != msg.sender, "Cannot delegate to self");
        votingDelegates[msg.sender] = _delegate;
        emit Delegated(msg.sender, _delegate);
    }

    /// @dev Calculates the combined voting power of an address based on staked tokens and reputation.
    /// If an address has delegated their power, this function will return the delegated power.
    /// @param _voter The address of the voter.
    /// @return The total voting power (scaled).
    function getVotingPower(address _voter) public view returns (uint256) {
        address currentVoter = _voter;
        // Follow delegation chain (simplified, only one level for this example)
        if (votingDelegates[currentVoter] != address(0)) {
            currentVoter = votingDelegates[currentVoter];
        }

        uint256 tokenVotingPower = stakedBalances[currentVoter]; // Every staked token gives 1 voting power
        // Convert reputation (scaled) into an equivalent CGT voting power
        uint256 reputationPower = contributorReputation[currentVoter].toUint256() / REPUTATION_SCALE_FACTOR * reputationVotingWeight;
        return tokenVotingPower + reputationPower;
    }


    // --- VII. Treasury & Token Management ---

    /// @notice Allows users to stake CognitoToken to gain voting power and earn rewards.
    /// Tokens are transferred from the user to the DAO contract's balance.
    /// @param _amount The amount of CognitoToken to stake.
    function stakeTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Stake amount must be positive");
        cognitoToken.transferFrom(msg.sender, address(this), _amount);
        stakedBalances[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake tokens from their staked balance.
    /// Tokens are transferred back from the DAO contract to the user.
    /// @param _amount The amount of CognitoToken to unstake.
    function unstakeTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Unstake amount must be positive");
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance");

        stakedBalances[msg.sender] -= _amount;
        require(cognitoToken.transfer(msg.sender, _amount), "Unstake transfer failed"); // Transfer back to user
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Governance-controlled function to mint and distribute rewards.
    /// Assumes the DAO contract is the owner of `CognitoToken` and can call its `mint` function.
    /// @param _recipients An array of recipient addresses.
    /// @param _amounts An array of amounts to distribute, corresponding to recipients.
    function distributeProtocolRewards(address[] calldata _recipients, uint256[] calldata _amounts) public onlyOwner whenNotPaused {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must match length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        // Mint tokens to the DAO's own balance first
        cognitoToken.mint(address(this), totalAmount);
        
        // Then transfer from the DAO's balance to the recipients
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(cognitoToken.transfer(_recipients[i], _amounts[i]), "Reward transfer failed for a recipient");
        }
        emit ProtocolRewardsDistributed(_recipients, _amounts);
    }
}
```