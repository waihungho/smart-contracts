Here's a smart contract written in Solidity, incorporating advanced concepts, creative functions, and trendy ideas, ensuring it's not a direct duplicate of existing open-source projects. It includes an outline and function summary at the top, and well over the requested 20 functions.

This contract, **NexusCognito**, acts as a decentralized protocol for submitting, verifying, and querying "knowledge fragments." It aims to build a verifiable, on-chain knowledge base, incentivizing contributions and enabling various DApp integrations (e.g., AI/DeSci).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit arithmetic safety (though 0.8.x provides built-in checks)

// Outline:
// This smart contract, NexusCognito, establishes a decentralized protocol for
// submitting, verifying, and querying "knowledge fragments." It aims to build a
// verifiable, on-chain knowledge base, incentivizing contributions and enabling
// AI/DeSci applications. It integrates advanced concepts like Soulbound Token-like
// NFTs for verified fragments, a dynamic reputation system, a micro-payment query layer,
// and a basic decentralized governance model for evolving fragment types and protocol parameters.

// Function Summary:
// I. Core Fragment Management (8 Functions):
//    1. submitKnowledgeFragment: Users submit knowledge fragments with an NXC stake for verification.
//    2. challengeFragment: Users can challenge a submitted fragment by staking NXC.
//    3. resolveFragmentChallenge: Governance Council resolves challenged fragments, distributing stakes and updating reputations.
//    4. retrieveFragmentStake: Allows submitters to reclaim their stake if a fragment is verified without challenge.
//    5. getFragmentDetails: Retrieves comprehensive details about a specific fragment.
//    6. getFragmentCount: Returns the total number of submitted fragments.
//    7. updateFragmentQueryPrice: Submitter sets a price (in NXC) for querying their verified fragment.
//    8. removeFragment: Governance Council/Owner can mark a fragment as invalid (e.g., harmful, outdated).

// II. Cognitive Asset (SBT-like ERC721) & Reputation (7 Functions):
//    9. mintCognitiveAsset: Mints a unique Soulbound Token (SBT-like ERC721) for a verified fragment.
//   10. getContributorReputation: Calculates a dynamic on-chain reputation score for a contributor based on their fragment history.
//   11. burnCognitiveAsset: Allows the owner to burn their Cognitive Asset (SBT), potentially impacting reputation.
//   12. tokenURI (ERC721 override): Returns the metadata URI for a Cognitive Asset token, linking to the fragment's context.
//   13. transferFrom (ERC721 override): Reverts, enforcing the SBT-like non-transferability.
//   14. approve (ERC721 override): Reverts, enforcing the SBT-like non-transferability.
//   15. getFragmentTokenId: Retrieves the Cognitive Asset token ID associated with a fragment ID.

// III. Query & Reward Distribution (4 Functions):
//   16. executeFragmentQuery: Allows users/DApps to pay NXC to query a fragment, distributing rewards to its submitter.
//   17. claimQueryRewards: Allows fragment submitters to claim their accumulated NXC query rewards.
//   18. getFragmentAccumulatedRewards: Returns the total NXC rewards accumulated for a fragment.
//   19. getFragmentQueryPrice: Returns the current query price for a specific fragment.

// IV. Governance & Protocol Parameters (6 Functions):
//   20. proposeNewFragmentType: Governance Council members can propose new categories for knowledge fragments (e.g., "ZK-VRF Proof").
//   21. voteOnProposal: Governance Council members vote on active proposals.
//   22. executeProposal: Owner/Council can execute a proposal once it meets voting requirements, enacting changes.
//   23. updateProtocolParameter: Owner/Council can update core contract configuration parameters (e.g., minStakeAmount).
//   24. addGovernanceCouncilMember: Owner adds a new member to the Governance Council.
//   25. removeGovernanceCouncilMember: Owner removes a member from the Governance Council.

// V. Advanced & Utility (3 Functions):
//   26. registerExternalVerifierContract: Council registers an external contract capable of verifying specific proof types (e.g., ZK-SNARKs).
//   27. emergencyPause: Owner can pause critical contract functions in an emergency.
//   28. emergencyUnpause: Owner can unpause critical contract functions after an emergency.

contract NexusCognito is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---
    Counters.Counter private _fragmentIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIds; // For Cognitive Assets (ERC721)

    // --- Enums and Structs ---
    enum FragmentStatus {
        PENDING,       // Newly submitted, awaiting verification/challenge
        CHALLENGED,    // Under dispute
        VERIFIED,      // Deemed valid by the protocol
        INVALIDATED    // Deemed invalid or removed by resolution/governance
    }

    struct KnowledgeFragment {
        uint256 id;
        address submitter;
        uint8 fragmentTypeId; // Numeric ID for dynamic fragment types
        bytes32 fragmentHash; // e.g., IPFS hash of a computation result, or a data claim
        bytes metadataURI;    // URI pointing to more details, context (e.g., IPFS hash of JSON metadata)
        bytes proof;          // Placeholder for ZK-proof, digital signature, computation input, etc.
        uint256 stakeAmount;  // NXC tokens staked by the submitter
        uint256 submittedAt;
        FragmentStatus status;
        address challenger;   // Address of the challenger, if any
        uint256 challengeStake; // NXC tokens staked by the challenger
        uint256 challengedAt;
        uint256 verificationTimestamp;
        uint256 queryPrice; // Price in NXC tokens to query this fragment (0 if free)
        uint256 accumulatedQueryRewards; // NXC rewards accumulated from queries
        bool isCognitiveAssetMinted; // Flag if an NFT has been minted for this fragment
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 proposalHash; // Unique hash representing the proposal's content
        mapping(address => bool) hasVoted; // Tracks votes by council member
        uint256 yeas;
        uint256 nays;
        uint256 requiredYeas; // Minimum 'yea' votes for proposal to pass (e.g., simple majority)
        bool executed;        // True if the proposal has been successfully enacted
        bool active;          // True if the proposal is currently open for voting
        uint256 createdAt;
        string newFragmentTypeName; // Specific to 'NewFragmentType' proposals
        bytes newFragmentSchemaHash; // Specific to 'NewFragmentType' proposals
    }

    // --- Mappings and Arrays ---
    mapping(uint256 => KnowledgeFragment) public fragments;
    mapping(address => uint256[]) public contributorFragments; // Tracks fragments contributed by each address
    mapping(address => int256) public reputationScores; // Tracks dynamic reputation (int256 allows negative scores)

    mapping(uint256 => Proposal) public proposals;
    address[] public governanceCouncil; // Addresses of DAO members / governance council
    uint256 public constant MIN_GOVERNANCE_COUNCIL_SIZE = 3; // Minimum size for the council

    // Dynamic Fragment Type Management:
    // `fragmentTypeNames` maps a numeric ID to a human-readable string name.
    // `fragmentTypeNameToId` maps a string name back to its numeric ID for lookups.
    // `nextFragmentTypeId` ensures unique, sequential IDs for new fragment types.
    mapping(uint8 => string) public fragmentTypeNames;
    mapping(string => uint8) public fragmentTypeNameToId;
    uint8 public nextFragmentTypeId = 0; // Starts at 0, increments for each new type

    // External verifiers for specific fragment types (e.g., ZK-SNARK verifier contract)
    mapping(uint8 => address) public externalVerifiers;

    // ERC721-specific mappings for Cognitive Assets
    mapping(uint256 => uint256) private _tokenIdToFragmentId; // Maps NFT ID to Fragment ID
    mapping(uint256 => uint256) private _fragmentIdToTokenId; // Maps Fragment ID to NFT ID

    // --- Configuration Parameters ---
    uint256 public minStakeAmount; // Minimum NXC tokens required for fragment submission or challenge
    uint256 public challengePeriodDuration; // Time (in seconds) during which a fragment can be challenged
    uint256 public verificationGracePeriod; // Time (in seconds) for council to resolve a challenged fragment
    uint256 public proposalVotePeriod; // Time (in seconds) for council to vote on a proposal
    uint256 public queryRewardSharePercentage = 80; // Percentage of query price distributed to the submitter (0-100)

    // --- External Contracts ---
    IERC20 public nxcToken; // Address of the NXC ERC20 token used for staking and rewards

    // --- Events ---
    event FragmentSubmitted(uint256 indexed fragmentId, address indexed submitter, uint8 fragmentTypeId, bytes32 fragmentHash);
    event FragmentChallenged(uint256 indexed fragmentId, address indexed challenger, bytes reason);
    event FragmentChallengeResolved(uint256 indexed fragmentId, address indexed resolver, bool challengerWon);
    event FragmentStakeRetrieved(uint256 indexed fragmentId, address indexed staker, uint256 amount);
    event CognitiveAssetMinted(uint256 indexed tokenId, uint256 indexed fragmentId, address indexed owner);
    event CognitiveAssetBurned(uint256 indexed tokenId, address indexed owner);
    event ReputationUpdated(address indexed contributor, int256 newScore);
    event FragmentQueryExecuted(uint256 indexed fragmentId, address indexed querier, uint256 amount);
    event QueryRewardsClaimed(address indexed submitter, uint256 totalAmount);
    event FragmentQueryPriceUpdated(uint256 indexed fragmentId, uint256 newPrice);
    event NewFragmentTypeProposed(uint256 indexed proposalId, string name, bytes schemaHash, address proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event ExternalVerifierRegistered(uint8 indexed fragmentTypeId, address indexed verifierAddress);
    event EmergencyPaused(address indexed pauser);
    event EmergencyUnpaused(address indexed unpauser);
    event FragmentRemoved(uint256 indexed fragmentId, address indexed remover);

    bool public paused = false; // System-wide pause flag

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyCouncil() {
        bool isCouncilMember = false;
        for (uint i = 0; i < governanceCouncil.length; i++) {
            if (governanceCouncil[i] == msg.sender) {
                isCouncilMember = true;
                break;
            }
        }
        require(isCouncilMember, "NexusCognito: Not a governance council member");
        _;
    }

    // --- Constructor ---
    constructor(
        address _nxcTokenAddress,
        address[] memory _initialCouncil,
        uint256 _minStakeAmount,
        uint256 _challengePeriodDuration,
        uint256 _verificationGracePeriod,
        uint256 _proposalVotePeriod
    ) ERC721("CognitoAsset", "CGA") Ownable(msg.sender) {
        require(_initialCouncil.length >= MIN_GOVERNANCE_COUNCIL_SIZE, "NexusCognito: Insufficient initial council members");
        nxcToken = IERC20(_nxcTokenAddress);
        governanceCouncil = _initialCouncil;

        minStakeAmount = _minStakeAmount;
        challengePeriodDuration = _challengePeriodDuration;
        verificationGracePeriod = _verificationGracePeriod;
        proposalVotePeriod = _proposalVotePeriod;

        // Initialize a few default fragment types
        _addFragmentTypeInternal("Computational Proof"); // ID 0
        _addFragmentTypeInternal("Verified Claim");      // ID 1
        _addFragmentTypeInternal("Data Insight");        // ID 2
        _addFragmentTypeInternal("ZK-Inference");        // ID 3
    }

    // --- Internal Helper: Adds a new fragment type to the system ---
    // This is called by the constructor for initial types, and by `executeProposal` for new types.
    function _addFragmentTypeInternal(string memory _name) internal {
        // Prevent adding empty names or names that already exist (either active or temporarily proposed)
        require(bytes(_name).length > 0, "NexusCognito: Fragment type name cannot be empty");
        require(fragmentTypeNameToId[_name] == 0 && nextFragmentTypeId == 0 ||
                fragmentTypeNameToId[_name] == 0 && bytes(fragmentTypeNames[0]).length == 0 ||
                fragmentTypeNameToId[_name] == 0 && nextFragmentTypeId > 0 && bytes(fragmentTypeNames[fragmentTypeNameToId[_name]]).length == 0,
                "NexusCognito: Fragment type name already exists or is reserved");

        fragmentTypeNames[nextFragmentTypeId] = _name;
        fragmentTypeNameToId[_name] = nextFragmentTypeId;
        nextFragmentTypeId++; // Increment for the next available ID
    }

    // --- Internal Helper for ERC721 (SBT-like behavior) ---
    // Overrides to make Cognitive Assets non-transferable (Soulbound) by reverting all transfer attempts.
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert("CognitoAsset: SBTs are non-transferable");
    }

    function _approve(address to, uint256 tokenId) internal virtual override {
        revert("CognitoAsset: SBTs cannot be approved for transfer");
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual override {
        revert("CognitoAsset: SBTs cannot be approved for all transfers");
    }

    // --- I. Core Fragment Management (8 Functions) ---

    /**
     * @notice Submits a new knowledge fragment to the NexusCognito protocol for potential verification.
     * @dev The submitter must first `approve` this contract to spend `_stakeAmount` of NXC tokens.
     * @param _typeId The numeric ID of the knowledge fragment's category.
     * @param _fragmentHash A unique identifier or cryptographic hash of the fragment's core data.
     * @param _metadataURI URI pointing to external metadata (e.g., IPFS hash of a JSON file with context).
     * @param _proof An optional proof payload (e.g., ZK-SNARK proof, digital signature, raw computation output).
     * @param _stakeAmount The amount of NXC tokens to stake; must be >= `minStakeAmount`.
     */
    function submitKnowledgeFragment(
        uint8 _typeId,
        bytes32 _fragmentHash,
        bytes memory _metadataURI,
        bytes memory _proof,
        uint256 _stakeAmount
    ) external nonReentrant whenNotPaused {
        require(_stakeAmount >= minStakeAmount, "NexusCognito: Stake amount too low");
        require(bytes(fragmentTypeNames[_typeId]).length > 0, "NexusCognito: Invalid fragment type ID"); // Ensures type exists

        _fragmentIds.increment();
        uint256 newFragmentId = _fragmentIds.current();

        // Transfer NXC stake from submitter to this contract
        require(nxcToken.transferFrom(msg.sender, address(this), _stakeAmount), "NexusCognito: NXC stake transfer failed");

        fragments[newFragmentId] = KnowledgeFragment({
            id: newFragmentId,
            submitter: msg.sender,
            fragmentTypeId: _typeId,
            fragmentHash: _fragmentHash,
            metadataURI: _metadataURI,
            proof: _proof,
            stakeAmount: _stakeAmount,
            submittedAt: block.timestamp,
            status: FragmentStatus.PENDING,
            challenger: address(0),
            challengeStake: 0,
            challengedAt: 0,
            verificationTimestamp: 0,
            queryPrice: 0, // Default to no query price initially
            accumulatedQueryRewards: 0,
            isCognitiveAssetMinted: false
        });

        contributorFragments[msg.sender].push(newFragmentId); // Track fragment by submitter
        emit FragmentSubmitted(newFragmentId, msg.sender, _typeId, _fragmentHash);
    }

    /**
     * @notice Allows a user to challenge a `PENDING` knowledge fragment.
     * @dev The challenger must first `approve` this contract to spend `_challengeStake` of NXC tokens.
     * @param _fragmentId The ID of the fragment to challenge.
     * @param _reason A bytes payload detailing the reason or proof for the challenge.
     * @param _challengeStake The amount of NXC tokens to stake for the challenge; must be >= `minStakeAmount`.
     */
    function challengeFragment(
        uint256 _fragmentId,
        bytes memory _reason,
        uint256 _challengeStake
    ) external nonReentrant whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.status == FragmentStatus.PENDING, "NexusCognito: Fragment not in PENDING status");
        require(block.timestamp <= fragment.submittedAt + challengePeriodDuration, "NexusCognito: Challenge period expired");
        require(msg.sender != fragment.submitter, "NexusCognito: Submitter cannot challenge their own fragment");
        require(_challengeStake >= minStakeAmount, "NexusCognito: Challenge stake too low");

        // Transfer NXC stake from challenger to this contract
        require(nxcToken.transferFrom(msg.sender, address(this), _challengeStake), "NexusCognito: NXC challenge stake transfer failed");

        fragment.status = FragmentStatus.CHALLENGED;
        fragment.challenger = msg.sender;
        fragment.challengeStake = _challengeStake;
        fragment.challengedAt = block.timestamp;

        emit FragmentChallenged(_fragmentId, msg.sender, _reason);
    }

    /**
     * @notice Resolves a `CHALLENGED` knowledge fragment. Only callable by Governance Council members.
     * @dev Must be called after the `challengePeriodDuration` has passed, but within the `verificationGracePeriod`.
     *      Distributes stakes and updates reputations based on the resolution outcome.
     * @param _fragmentId The ID of the fragment to resolve.
     * @param _challengerWins True if the challenger's claim is valid (fragment is invalid), false otherwise (fragment is valid).
     */
    function resolveFragmentChallenge(uint256 _fragmentId, bool _challengerWins) external onlyCouncil nonReentrant whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.status == FragmentStatus.CHALLENGED, "NexusCognito: Fragment not challenged");
        require(block.timestamp > fragment.challengedAt + challengePeriodDuration, "NexusCognito: Challenge period not over yet");
        require(block.timestamp <= fragment.challengedAt + challengePeriodDuration + verificationGracePeriod, "NexusCognito: Verification grace period expired");

        if (_challengerWins) {
            // Fragment is invalid: challenger wins both stakes. Submitter loses reputation, challenger gains.
            fragment.status = FragmentStatus.INVALIDATED;
            reputationScores[fragment.submitter]--; // Decrement reputation
            reputationScores[fragment.challenger]++; // Increment reputation
            require(nxcToken.transfer(fragment.challenger, fragment.challengeStake + fragment.stakeAmount), "NexusCognito: NXC transfer to challenger failed");
        } else {
            // Fragment is valid: submitter wins both stakes. Submitter gains reputation, challenger loses.
            fragment.status = FragmentStatus.VERIFIED;
            reputationScores[fragment.submitter]++; // Increment reputation
            reputationScores[fragment.challenger]--; // Decrement reputation
            require(nxcToken.transfer(fragment.submitter, fragment.stakeAmount + fragment.challengeStake), "NexusCognito: NXC transfer to submitter failed");
        }
        fragment.verificationTimestamp = block.timestamp;
        fragment.stakeAmount = 0; // Stakes are distributed
        fragment.challengeStake = 0; // Stakes are distributed
        emit FragmentChallengeResolved(_fragmentId, msg.sender, _challengerWins);
        emit ReputationUpdated(fragment.submitter, reputationScores[fragment.submitter]);
        emit ReputationUpdated(fragment.challenger, reputationScores[fragment.challenger]);
    }

    /**
     * @notice Allows the original submitter to retrieve their stake if the fragment was verified
     *         without being challenged. Stakes for challenged fragments are handled by `resolveFragmentChallenge`.
     * @param _fragmentId The ID of the fragment whose stake to retrieve.
     */
    function retrieveFragmentStake(uint256 _fragmentId) external nonReentrant whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.status == FragmentStatus.VERIFIED, "NexusCognito: Fragment not verified");
        require(fragment.challenger == address(0), "NexusCognito: Fragment was challenged; stakes handled by resolution.");
        require(msg.sender == fragment.submitter, "NexusCognito: Only submitter can retrieve stake.");
        require(block.timestamp > fragment.submittedAt + challengePeriodDuration + verificationGracePeriod, "NexusCognito: Verification period not over yet.");
        require(fragment.stakeAmount > 0, "NexusCognito: Stake already retrieved.");

        uint256 amount = fragment.stakeAmount;
        fragment.stakeAmount = 0; // Mark as retrieved
        reputationScores[fragment.submitter]++; // Add reputation for successfully verifying (uncontested)
        require(nxcToken.transfer(msg.sender, amount), "NexusCognito: NXC stake transfer to submitter failed");
        emit FragmentStakeRetrieved(_fragmentId, msg.sender, amount);
        emit ReputationUpdated(fragment.submitter, reputationScores[fragment.submitter]);
    }

    /**
     * @notice Retrieves detailed information about a knowledge fragment.
     * @param _fragmentId The ID of the fragment.
     * @return A `KnowledgeFragment` struct containing all details.
     */
    function getFragmentDetails(uint256 _fragmentId) public view returns (KnowledgeFragment memory) {
        require(fragments[_fragmentId].id != 0, "NexusCognito: Fragment not found");
        return fragments[_fragmentId];
    }

    /**
     * @notice Returns the total count of knowledge fragments submitted to the protocol.
     * @return The current total number of fragments.
     */
    function getFragmentCount() public view returns (uint256) {
        return _fragmentIds.current();
    }

    /**
     * @notice Allows the original submitter of a *verified* fragment to set or update its query price.
     * @param _fragmentId The ID of the verified fragment.
     * @param _newPrice The new price in NXC wei for querying this fragment. Set to 0 to make it free.
     */
    function updateFragmentQueryPrice(uint256 _fragmentId, uint256 _newPrice) external whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.submitter == msg.sender, "NexusCognito: Not the fragment submitter");
        require(fragment.status == FragmentStatus.VERIFIED, "NexusCognito: Fragment not verified");

        fragment.queryPrice = _newPrice;
        emit FragmentQueryPriceUpdated(_fragmentId, _newPrice);
    }

    /**
     * @notice Allows the Governance Council to mark a fragment as `INVALIDATED`.
     * @dev This can be used for genuinely harmful, outdated, or fundamentally flawed
     *      knowledge, even if it was initially verified. It revokes its protocol-level validity.
     * @param _fragmentId The ID of the fragment to remove/invalidate.
     */
    function removeFragment(uint256 _fragmentId) external onlyCouncil whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.status != FragmentStatus.INVALIDATED, "NexusCognito: Fragment already removed/invalidated");
        
        fragment.status = FragmentStatus.INVALIDATED; 
        
        emit FragmentRemoved(_fragmentId, msg.sender);
    }


    // --- II. Cognitive Asset (SBT-like ERC721) & Reputation (7 Functions) ---

    /**
     * @notice Mints a new Cognitive Asset (SBT-like ERC721) for a verified knowledge fragment.
     * @dev Only the submitter of a verified fragment can mint its associated asset.
     *      This asset is designed to be non-transferable (Soulbound) to represent personal contribution.
     * @param _fragmentId The ID of the verified fragment.
     */
    function mintCognitiveAsset(uint256 _fragmentId) external nonReentrant whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.submitter == msg.sender, "NexusCognito: Only fragment submitter can mint asset");
        require(fragment.status == FragmentStatus.VERIFIED, "NexusCognito: Fragment not verified");
        require(!fragment.isCognitiveAssetMinted, "NexusCognito: Cognitive Asset already minted");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId); // Mints the ERC721 token to the submitter
        _tokenIdToFragmentId[newTokenId] = _fragmentId;
        _fragmentIdToTokenId[_fragmentId] = newTokenId;
        fragment.isCognitiveAssetMinted = true;

        emit CognitiveAssetMinted(newTokenId, _fragmentId, msg.sender);
    }

    /**
     * @notice Calculates and returns the on-chain reputation score for a given contributor.
     * @dev Reputation is dynamically updated based on successful fragment verifications,
     *      challenge outcomes, and other protocol interactions.
     * @param _contributor The address of the contributor.
     * @return The current reputation score (`int256` to allow negative scores).
     */
    function getContributorReputation(address _contributor) public view returns (int256) {
        return reputationScores[_contributor];
    }

    /**
     * @notice Allows the owner of a Cognitive Asset (SBT) to burn it.
     * @dev Burning an asset may signify removal of outdated or flawed knowledge, potentially reducing reputation.
     * @param _tokenId The ID of the Cognitive Asset to burn.
     */
    function burnCognitiveAsset(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not token owner or approved");
        require(ownerOf(_tokenId) == msg.sender, "NexusCognito: Only asset owner can burn");

        uint256 fragmentId = _tokenIdToFragmentId[_tokenId];
        KnowledgeFragment storage fragment = fragments[fragmentId];

        _burn(_tokenId); // Burns the ERC721 token
        fragment.isCognitiveAssetMinted = false; // Mark fragment's asset as no longer minted

        reputationScores[msg.sender]--; // Deduct reputation for burning
        
        emit CognitiveAssetBurned(_tokenId, msg.sender);
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]);
    }

    /**
     * @notice Overrides ERC721's `tokenURI` function to provide dynamic metadata for Cognitive Assets.
     * @param tokenId The ID of the Cognitive Asset.
     * @return The URI pointing to the metadata for the Cognitive Asset, derived from the fragment's metadataURI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 fragmentId = _tokenIdToFragmentId[tokenId];
        return string(fragments[fragmentId].metadataURI);
    }
    
    /**
     * @notice Returns the Cognitive Asset token ID associated with a given fragment ID.
     * @param _fragmentId The ID of the knowledge fragment.
     * @return The corresponding ERC721 token ID, or 0 if no asset is minted for that fragment.
     */
    function getFragmentTokenId(uint256 _fragmentId) public view returns (uint256) {
        return _fragmentIdToTokenId[_fragmentId];
    }

    // --- III. Query & Reward Distribution (4 Functions) ---

    /**
     * @notice Executes a query against a verified knowledge fragment.
     * @dev Requires the querier to `approve` this contract to spend the fragment's `queryPrice` in NXC tokens.
     *      A portion of the payment goes to the fragment's submitter as accumulated rewards.
     * @param _fragmentId The ID of the fragment to query.
     */
    function executeFragmentQuery(uint256 _fragmentId) external nonReentrant whenNotPaused {
        KnowledgeFragment storage fragment = fragments[_fragmentId];
        require(fragment.id != 0, "NexusCognito: Fragment not found");
        require(fragment.status == FragmentStatus.VERIFIED, "NexusCognito: Fragment not verified");
        require(fragment.queryPrice > 0, "NexusCognito: Fragment is not configured for paid queries");

        // Transfer NXC from querier for the query
        require(nxcToken.transferFrom(msg.sender, address(this), fragment.queryPrice), "NexusCognito: NXC transfer failed for query");

        uint256 rewardAmount = fragment.queryPrice.mul(queryRewardSharePercentage).div(100);
        fragment.accumulatedQueryRewards = fragment.accumulatedQueryRewards.add(rewardAmount);

        // The remaining (100 - queryRewardSharePercentage)% stays in this contract as protocol treasury.

        emit FragmentQueryExecuted(_fragmentId, msg.sender, fragment.queryPrice);
    }

    /**
     * @notice Allows a fragment submitter to claim their accumulated NXC query rewards.
     * @dev Iterates through all fragments submitted by `msg.sender` and collects their accumulated rewards.
     */
    function claimQueryRewards() external nonReentrant whenNotPaused {
        uint256 totalClaimable = 0;
        for (uint i = 0; i < contributorFragments[msg.sender].length; i++) {
            uint256 fragmentId = contributorFragments[msg.sender][i];
            KnowledgeFragment storage fragment = fragments[fragmentId];
            if (fragment.submitter == msg.sender && fragment.accumulatedQueryRewards > 0) { // Ensure submitter and check rewards
                totalClaimable = totalClaimable.add(fragment.accumulatedQueryRewards);
                fragment.accumulatedQueryRewards = 0; // Reset for this fragment after adding to total
            }
        }
        require(totalClaimable > 0, "NexusCognito: No rewards to claim");

        require(nxcToken.transfer(msg.sender, totalClaimable), "NexusCognito: NXC reward transfer failed");
        emit QueryRewardsClaimed(msg.sender, totalClaimable);
    }

    /**
     * @notice Returns the total accumulated NXC rewards for a specific fragment.
     * @param _fragmentId The ID of the fragment.
     * @return The accumulated reward amount in NXC wei.
     */
    function getFragmentAccumulatedRewards(uint256 _fragmentId) public view returns (uint256) {
        require(fragments[_fragmentId].id != 0, "NexusCognito: Fragment not found");
        return fragments[_fragmentId].accumulatedQueryRewards;
    }

    /**
     * @notice Returns the current query price for a specific fragment.
     * @param _fragmentId The ID of the fragment.
     * @return The query price in NXC wei.
     */
    function getFragmentQueryPrice(uint256 _fragmentId) public view returns (uint256) {
        require(fragments[_fragmentId].id != 0, "NexusCognito: Fragment not found");
        return fragments[_fragmentId].queryPrice;
    }

    // --- IV. Governance & Protocol Parameters (6 Functions) ---

    /**
     * @notice Allows a Governance Council member to propose a new, custom fragment type.
     * @dev This enables the protocol to evolve and support new categories of knowledge (e.g., "ZK-VRF Proof").
     * @param _name The proposed human-readable name for the new fragment type.
     * @param _schemaHash A cryptographic hash representing the schema or validation rules for this new type.
     */
    function proposeNewFragmentType(string memory _name, bytes memory _schemaHash) external onlyCouncil whenNotPaused {
        require(bytes(_name).length > 0, "NexusCognito: Name cannot be empty");
        // Check if type name already exists or is currently actively proposed
        require(fragmentTypeNameToId[_name] == 0 || bytes(fragmentTypeNames[fragmentTypeNameToId[_name]]).length == 0,
            "NexusCognito: Fragment type name already exists or is reserved by a proposal.");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            proposalHash: keccak256(abi.encodePacked("NEW_FRAGMENT_TYPE", _name, _schemaHash)),
            yeas: 0,
            nays: 0,
            requiredYeas: governanceCouncil.length.div(2).add(1), // Simple majority required
            executed: false,
            active: true,
            createdAt: block.timestamp,
            newFragmentTypeName: _name,
            newFragmentSchemaHash: _schemaHash
        });
        
        // Temporarily map name to `type(uint8).max` to signify it's proposed and prevent duplicates.
        // This will be updated to a proper ID upon successful execution.
        fragmentTypeNameToId[_name] = type(uint8).max; 
        
        emit NewFragmentTypeProposed(newProposalId, _name, _schemaHash, msg.sender);
    }

    /**
     * @notice Allows a Governance Council member to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yea' vote (in favor), false for a 'nay' vote (against).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyCouncil whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "NexusCognito: Proposal not found");
        require(proposal.active, "NexusCognito: Proposal not active");
        require(!proposal.hasVoted[msg.sender], "NexusCognito: Already voted on this proposal");
        require(block.timestamp <= proposal.createdAt + proposalVotePeriod, "NexusCognito: Voting period ended");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yeas++;
        } else {
            proposal.nays++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a proposal if it has met its voting requirements and its voting period has ended.
     * @dev Can be called by any Governance Council member or the contract owner.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyCouncil nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "NexusCognito: Proposal not found");
        require(proposal.active, "NexusCognito: Proposal not active");
        require(!proposal.executed, "NexusCognito: Proposal already executed");
        require(block.timestamp > proposal.createdAt + proposalVotePeriod, "NexusCognito: Voting period not ended");

        if (proposal.yeas >= proposal.requiredYeas) {
            // Check proposal type and execute relevant logic
            if (keccak256(abi.encodePacked("NEW_FRAGMENT_TYPE", proposal.newFragmentTypeName, proposal.newFragmentSchemaHash)) == proposal.proposalHash) {
                _addFragmentTypeInternal(proposal.newFragmentTypeName); // Add the new type permanently
            }
            // Future: Add `else if` blocks for other proposal types (e.g., parameter changes, treasury spending)
            
            proposal.executed = true;
            proposal.active = false; // Mark proposal as no longer active
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed: remove temporary placeholder for new fragment type
            if (keccak256(abi.encodePacked("NEW_FRAGMENT_TYPE", proposal.newFragmentTypeName, proposal.newFragmentSchemaHash)) == proposal.proposalHash) {
                delete fragmentTypeNameToId[proposal.newFragmentTypeName]; // Remove placeholder
            }
            proposal.active = false; // Mark as inactive if it failed
            revert("NexusCognito: Proposal did not meet voting requirements or failed.");
        }
    }

    /**
     * @notice Allows Governance Council or the contract owner to update core protocol parameters.
     * @param _paramName The name of the parameter to update (e.g., "minStakeAmount", "challengePeriodDuration").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyCouncil whenNotPaused {
        if (_paramName == "minStakeAmount") {
            minStakeAmount = _newValue;
        } else if (_paramName == "challengePeriodDuration") {
            challengePeriodDuration = _newValue;
        } else if (_paramName == "verificationGracePeriod") {
            verificationGracePeriod = _newValue;
        } else if (_paramName == "proposalVotePeriod") {
            proposalVotePeriod = _newValue;
        } else if (_paramName == "queryRewardSharePercentage") {
            require(_newValue <= 100, "NexusCognito: Share percentage cannot exceed 100");
            queryRewardSharePercentage = _newValue;
        } else {
            revert("NexusCognito: Unknown parameter");
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @notice Adds a new member to the Governance Council. Only callable by the contract owner.
     * @param _newMember The address of the new council member.
     */
    function addGovernanceCouncilMember(address _newMember) external onlyOwner {
        require(_newMember != address(0), "NexusCognito: Invalid address");
        for (uint i = 0; i < governanceCouncil.length; i++) {
            require(governanceCouncil[i] != _newMember, "NexusCognito: Member already in council");
        }
        governanceCouncil.push(_newMember);
        emit CouncilMemberAdded(_newMember);
    }

    /**
     * @notice Removes a member from the Governance Council. Only callable by the contract owner.
     * @dev Requires that the council size remains above `MIN_GOVERNANCE_COUNCIL_SIZE` after removal.
     * @param _memberToRemove The address of the council member to remove.
     */
    function removeGovernanceCouncilMember(address _memberToRemove) external onlyOwner {
        require(governanceCouncil.length > MIN_GOVERNANCE_COUNCIL_SIZE, "NexusCognito: Cannot remove member, council size too small");
        bool found = false;
        for (uint i = 0; i < governanceCouncil.length; i++) {
            if (governanceCouncil[i] == _memberToRemove) {
                governanceCouncil[i] = governanceCouncil[governanceCouncil.length - 1]; // Replace with last element
                governanceCouncil.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "NexusCognito: Member not found in council");
        emit CouncilMemberRemoved(_memberToRemove);
    }

    // --- V. Advanced & Utility (3 Functions) ---

    /**
     * @notice Registers an external smart contract capable of verifying specific proof types.
     * @dev This allows the protocol to integrate specialized ZK verifiers or other
     *      off-chain computation validators for specific fragment types.
     * @param _verifierAddress The address of the external verifier contract.
     * @param _forFragmentTypeId The numeric ID of the fragment type this verifier is specialized for.
     */
    function registerExternalVerifierContract(address _verifierAddress, uint8 _forFragmentTypeId) external onlyCouncil whenNotPaused {
        require(_verifierAddress != address(0), "NexusCognito: Invalid verifier address");
        require(bytes(fragmentTypeNames[_forFragmentTypeId]).length > 0, "NexusCognito: Invalid fragment type ID");
        externalVerifiers[_forFragmentTypeId] = _verifierAddress;
        emit ExternalVerifierRegistered(_forFragmentTypeId, _verifierAddress);
    }

    /**
     * @notice Pauses critical contract functions (e.g., submission, challenge, query) in case of an emergency.
     * @dev Only the contract owner can call this.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    /**
     * @notice Unpauses critical contract functions, resuming normal operations.
     * @dev Only the contract owner can call this.
     */
    function emergencyUnpause() external onlyOwner whenPaused {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    // Fallback and Receive functions to prevent accidental ETH deposits
    receive() external payable {
        revert("NexusCognito: Direct ETH deposits not allowed. Use NXC token.");
    }

    fallback() external payable {
        revert("NexusCognito: Fallback not implemented. Use NXC token.");
    }
}
```