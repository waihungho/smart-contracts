```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AetherForge
 * @dev A Decentralized Autonomous Creative & Curation Engine (DACCE)
 *
 * This contract enables the creation, curation, and incentivization of generative digital assets.
 * It integrates advanced concepts such as:
 * - **ZK Proof Verification:** To verify off-chain asset generation and provenance.
 * - **Dynamic NFTs:** Metadata changes based on on-chain curation scores and challenge participation.
 * - **Reputation-Based Curation:** A decentralized community of curators votes on asset quality, with voting power and rewards tied to their on-chain reputation.
 * - **AI Oracle Integration (Conceptual):** Allows for integration with decentralized AI models for initial quality assessment or suggestion.
 * - **Creative Challenges:** Time-bound events to foster specific types of asset creation and reward participants.
 * - **Permissionless Generative Minting:** Users can mint assets by providing parameters and a ZK proof.
 *
 * The goal is to provide a unique platform for verifiable and community-driven digital art/content creation,
 * moving beyond simple NFT minting to a system that emphasizes quality, provenance, and active community participation.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---
/**
 * @dev OUTLINE:
 * 1.  Interfaces (ERC721, ZK Verifier, AI Oracle)
 * 2.  Errors & Events
 * 3.  Core State Variables
 * 4.  Structs (Challenge, AssetDetails)
 * 5.  Constructor
 * 6.  ERC721 Minimal Implementation (Adapted for Dynamic NFTs)
 * 7.  Asset Generation & ZK Proof Functions
 * 8.  Curator & Reputation Management Functions
 * 9.  Curation & Voting Functions
 * 10. Creative Challenge & Submission Functions
 * 11. AI Oracle & Dynamic Metadata Functions
 * 12. Tokenomics & Reward Distribution Functions
 * 13. Governance & Administrative Functions
 */

/**
 * @dev FUNCTION SUMMARY (28 functions):
 *
 * Core ERC721 (Minimal & Adapted for AetherForge):
 * 1.  `balanceOf(address owner) returns (uint256)`: Returns the number of assets an owner has.
 * 2.  `ownerOf(uint256 tokenId) returns (address)`: Returns the current owner of an asset.
 * 3.  `_exists(uint256 tokenId) returns (bool)`: Internal helper to check if a token ID exists.
 * 4.  `getApproved(uint256 tokenId) returns (address)`: Returns the approved address for a specific asset.
 * 5.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes an operator for all assets of `msg.sender`.
 * 6.  `isApprovedForAll(address owner, address operator) returns (bool)`: Checks if an operator is approved for all assets of an owner.
 * 7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an asset from one address to another.
 * 8.  `approve(address to, uint256 tokenId)`: Approves an address to take ownership of a specific asset.
 * 9.  `tokenURI(uint256 tokenId) returns (string memory)`: **Dynamic NFT - Generates a metadata URI reflecting the asset's current on-chain state (e.g., curation score, challenge status).**
 *
 * Asset Generation & ZK Proof Functions:
 * 10. `mintGenerativeAsset(address recipient, bytes32 generationParamsHash, bytes32 zkProofHash, bytes calldata zkProofData)`: **Advanced - Mints a new generative asset. Requires a hash of off-chain generation parameters, a ZK proof hash, and the actual ZK proof data which is verified on-chain.**
 *
 * Curator & Reputation Management Functions:
 * 11. `stakeForCuratorRole(uint256 amount)`: **Advanced - Allows an address to stake a minimum amount to become a curator, gaining initial reputation and voting rights.**
 * 12. `unstakeCuratorRole()`: **Advanced - Allows a curator to unstake their tokens and relinquish their role. May incur penalties if reputation is low or during an active challenge.**
 * 13. `_updateCuratorReputation(address curator, int256 change)`: **Internal - Adjusts a curator's reputation score based on their performance (e.g., voting accuracy).**
 * 14. `delegateReputation(address delegatee)`: **Advanced - Enables a curator to delegate their reputation and voting power to another address (e.g., a trusted expert).**
 *
 * Curation & Voting Functions:
 * 15. `submitAssetForCuration(uint256 tokenId)`: Marks a minted asset as ready for community curation by qualified curators.
 * 16. `voteOnAssetQuality(uint256 tokenId, uint8 score)`: **Advanced - Curators submit a quality score for an asset. Their vote's weight is proportional to their reputation. Influences asset's overall curation score and their own reputation.**
 * 17. `finalizeCuration(uint256 tokenId)`: **Advanced - Calculates the final average curation score for an asset, updates its dynamic attributes, and potentially distributes rewards to contributing curators. Can trigger AI oracle if needed.**
 *
 * Creative Challenge & Submission Functions:
 * 18. `createChallenge(string memory _theme, uint256 _duration, uint256 _requiredReputation, uint256 _entryFee, uint256 _rewardPool)`: **Creative - Allows authorized entities to define and initiate new themed creative challenges, setting parameters like duration, required reputation for entry, and reward pool.**
 * 19. `submitChallengeEntry(uint256 _challengeId, uint256 _assetId)`: **Creative - Users submit their owned and relevant assets as entries for active challenges, provided they meet the challenge's reputation requirements.**
 * 20. `finalizeChallenge(uint256 _challengeId)`: **Creative - Determines winners of a challenge based on the curation scores of submitted entries and distributes rewards from the challenge's dedicated pool.**
 *
 * AI Oracle & Dynamic Metadata Functions:
 * 21. `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI Oracle contract used for initial quality assessments.
 * 22. `requestAIQualityScore(uint256 _tokenId)`: **Advanced - Initiates a request to the configured AI Oracle for an initial quality assessment of a specific asset. (Interaction is conceptual and simplified for this example).**
 *
 * Tokenomics & Reward Distribution Functions:
 * 23. `claimCurationRewards()`: Allows curators to claim their accumulated rewards for successfully participating in asset curation.
 * 24. `claimChallengeRewards(uint256 _challengeId)`: Allows winners of a specific challenge to claim their designated prizes.
 * 25. `fundContract()`: A payable function allowing anyone to send ETH (or a native token) to the contract's general reward pool.
 *
 * Governance & Administrative Functions:
 * 26. `setMinimumCuratorStake(uint256 _newStake)`: Allows the owner to adjust the minimum stake required for new curators.
 * 27. `pauseContract()`: **Administrative - Pauses critical functionalities of the contract (e.g., minting, voting) in case of an emergency or upgrade.**
 * 28. `unpauseContract()`: **Administrative - Unpauses the contract, restoring full functionality.**
 */

// --- INTERFACES ---

/**
 * @dev Minimal ERC721 interface for interoperability.
 */
interface IAetherForgeERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Interface for a ZK-SNARK Verifier contract.
 * A real ZK-SNARK verifier would be generated specifically for its circuit.
 */
interface IZkVerifier {
    function verifyProof(
        bytes calldata _proof,
        bytes32[2] calldata _publicInputs // Example: [commitment_hash, input_hash]
    ) external view returns (bool);
}

/**
 * @dev Interface for an AI Oracle contract.
 * In a real scenario, this would involve more complex verifiable computation or a decentralized oracle network.
 */
interface IAIOracle {
    function getQualityScore(uint256 _assetId) external returns (uint256); // Simplified direct call
    // A more robust system would use a request/fulfill pattern with callbacks.
}

// --- CONTRACT IMPLEMENTATION ---

contract AetherForge is IAetherForgeERC721 {

    // --- ERRORS ---
    error NotOwner();
    error NotApprovedOrOwner();
    error InvalidRecipient();
    error TokenDoesNotExist();
    error ZeroAddress();
    error AlreadyExists();
    error InvalidAmount();
    error InsufficientStake();
    error NotACurator();
    error AlreadyCurator();
    error NotSubmittedForCuration();
    error AlreadyVoted();
    error InsufficientReputation();
    error InvalidScore();
    error CurationNotReady();
    error CurationAlreadyFinalized();
    error ChallengeNotFound();
    error ChallengeNotActive();
    error ChallengeExpired();
    error ChallengeNotYetStarted();
    error AlreadySubmittedToChallenge();
    error ChallengeNotFinalized();
    error NotChallengeWinner();
    error NoRewardsToClaim();
    error Paused();
    error NotPaused();
    error DelegationFailed();
    error NoPermission();
    error InvalidDuration();
    error ChallengeEntryTooLate();
    error AssetNotOwnedBySender();
    error AssetAlreadyInChallenge();


    // --- EVENTS ---
    event AssetMinted(uint256 indexed tokenId, address indexed recipient, bytes32 generationParamsHash, bytes32 zkProofHash);
    event CuratorStaked(address indexed curator, uint256 amount, uint256 newReputation);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event ReputationUpdated(address indexed curator, int256 change, uint256 newReputation);
    event AssetSubmittedForCuration(uint256 indexed tokenId);
    event AssetVoted(uint256 indexed tokenId, address indexed curator, uint8 score, uint256 reputationWeight);
    event CurationFinalized(uint256 indexed tokenId, uint256 finalScore);
    event ChallengeCreated(uint256 indexed challengeId, string theme, address indexed creator, uint256 startTime, uint256 endTime);
    event ChallengeEntrySubmitted(uint256 indexed challengeId, uint256 indexed tokenId, address indexed submitter);
    event ChallengeFinalized(uint256 indexed challengeId, address[] winners, uint256[] rewardAmounts);
    event RewardsClaimed(address indexed receiver, uint256 amount);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event AIOracleRequested(uint256 indexed tokenId, address indexed oracleAddress);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);


    // --- CORE STATE VARIABLES ---
    uint256 private _nextTokenId; // Counter for unique token IDs
    address private _owner;       // Contract owner

    bool public paused;           // Pause mechanism

    // ERC721 Mappings
    mapping(uint256 => address) private _owners;              // tokenId => owner address
    mapping(address => uint256) private _balances;            // owner address => token count
    mapping(uint256 => address) private _tokenApprovals;      // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // AetherForge Specific Mappings
    address public zkVerifierAddress;
    address public aiOracleAddress;
    string public baseTokenURI; // Base URI for metadata server

    // Asset details
    struct AssetDetails {
        address creator;
        bytes32 generationParamsHash; // Hash of parameters used for generation (e.g., AI prompt, seed)
        bytes32 zkProofHash;          // Hash of the ZK proof submitted
        uint256 creationTime;
        bool isSubmittedForCuration;
        uint256 curationScoreSum;     // Sum of weighted scores from curators
        uint256 totalReputationVoted; // Total reputation weight that voted
        uint256 finalCurationScore;   // Calculated final score (0-100)
        bool curationFinalized;
        uint256 aiQualityScore;       // Score from AI oracle (if requested)
    }
    mapping(uint256 => AssetDetails) public assetDetails;

    // Curator & Reputation System
    uint256 public minCuratorStake; // Minimum ETH/token required to stake for curator role
    uint256 public curatorRewardPool; // Pool for distributing curation rewards
    uint256 public constant INITIAL_REPUTATION = 100; // Starting reputation for new curators
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 10; // Minimum reputation to vote
    uint256 public constant MIN_CURATION_VOTES_FOR_FINALIZATION = 3; // Minimum unique curator votes before finalization

    mapping(address => uint256) public curatorStake;      // curator address => staked amount
    mapping(address => uint256) public curatorReputation; // curator address => reputation score
    mapping(address => address) public reputationDelegates; // delegator => delegatee
    mapping(address => uint256) public curatorPendingRewards; // curator => accumulated rewards

    // Curation Tracking
    mapping(uint256 => mapping(address => bool)) public hasCuratorVoted; // tokenId => curator address => has voted

    // Creative Challenges
    struct Challenge {
        uint256 id;
        string theme;
        address creator;
        uint256 startTime;
        uint256 endTime;
        uint256 requiredReputation; // Minimum reputation to submit an entry
        uint256 entryFee;           // Fee to enter challenge (can be 0)
        uint256 rewardPool;         // Specific pool for this challenge
        uint256[] submittedEntries; // Token IDs submitted
        mapping(uint256 => bool) isEntry; // tokenId => is an entry for this challenge
        bool finalized;
        address[] winners;
        mapping(address => uint256) winnerRewards; // winner => reward amount
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 private _nextChallengeId; // Counter for unique challenge IDs

    // --- MODIFIERS ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(address _zkVerifierAddress, address _aiOracleAddress, string memory _baseTokenURI, uint256 _minCuratorStake) {
        _owner = msg.sender;
        zkVerifierAddress = _zkVerifierAddress;
        aiOracleAddress = _aiOracleAddress;
        baseTokenURI = _baseTokenURI;
        minCuratorStake = _minCuratorStake;
        _nextTokenId = 1; // Token IDs start from 1
        _nextChallengeId = 1;
        paused = false;
    }

    // --- ERC721 MINIMAL IMPLEMENTATION (Adapted for AetherForge) ---

    /**
     * @dev Returns the number of assets owned by `owner`.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` asset.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    /**
     * @dev Internal function to check if a token exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns the approved address for `tokenId`, or the zero address if no address set.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Approves or revokes an operator to manage all of `msg.sender`'s assets.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert InvalidRecipient(); // Cannot approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Checks if `operator` is an approved operator for `owner`.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers ownership of `tokenId` from `from` to `to`.
     * Requires the `msg.sender` to be the owner, approved, or an operator.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (ownerOf(tokenId) != from) revert NotOwner();
        if (to == address(0)) revert InvalidRecipient();

        _checkTransferPermissions(from, tokenId);

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Approves `to` to operate on `tokenId`.
     * The `msg.sender` must be the owner of the token.
     */
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner) revert NotOwner();
        if (to == tokenOwner) revert InvalidRecipient();

        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev Internal function to check if `msg.sender` has permission to transfer `tokenId`.
     */
    function _checkTransferPermissions(address from, uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender == tokenOwner) return; // Owner can always transfer
        if (getApproved(tokenId) == msg.sender) return; // Approved address can transfer
        if (isApprovedForAll(tokenOwner, msg.sender)) return; // Approved operator can transfer
        revert NotApprovedOrOwner();
    }

    /**
     * @dev Internal function to actually transfer the asset.
     * Clears approvals upon transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;
        _clearApproval(tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to clear the approval for a given token ID.
     */
    function _clearApproval(uint256 tokenId) internal {
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
            emit Approval(ownerOf(tokenId), address(0), tokenId);
        }
    }

    /**
     * @dev Returns the URI for the given token ID.
     * This is a dynamic URI that includes relevant on-chain data to be interpreted by an off-chain metadata service.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        AssetDetails storage details = assetDetails[tokenId];
        
        // Example dynamic metadata structure
        // The off-chain service would interpret this URI:
        // {baseURI}/{tokenId}?curationScore={score}&aiScore={aiScore}&challengeCount={count}
        
        string memory curationScoreStr = _uint256ToString(details.finalCurationScore);
        string memory aiScoreStr = _uint256ToString(details.aiQualityScore);
        
        uint256 challengeCount = 0;
        for (uint256 i = 1; i < _nextChallengeId; i++) {
            if (challenges[i].isEntry[tokenId]) {
                challengeCount++;
            }
        }
        string memory challengeCountStr = _uint256ToString(challengeCount);

        // Concatenate using abi.encodePacked for efficiency (though it's not truly memory-efficient for many concatenations)
        return string(abi.encodePacked(
            baseTokenURI,
            _uint256ToString(tokenId),
            "?curationScore=", curationScoreStr,
            "&aiScore=", aiScoreStr,
            "&challengeCount=", challengeCountStr
            // Add other dynamic attributes as needed
        ));
    }

    /**
     * @dev Helper function to convert uint256 to string.
     */
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }


    // --- ASSET GENERATION & ZK PROOF FUNCTIONS ---

    /**
     * @dev Mints a new generative asset, requiring a ZK proof of off-chain generation.
     * @param recipient The address to receive the new asset.
     * @param generationParamsHash A hash of the parameters used to generate the asset (e.g., AI prompt, seed).
     * @param zkProofHash A hash of the full ZK proof.
     * @param zkProofData The actual ZK proof data to be verified on-chain.
     */
    function mintGenerativeAsset(address recipient, bytes32 generationParamsHash, bytes32 zkProofHash, bytes calldata zkProofData)
        public
        whenNotPaused
    returns (uint256) {
        if (recipient == address(0)) revert InvalidRecipient();
        if (generationParamsHash == bytes32(0)) revert InvalidAmount(); // Must provide some params hash

        // --- ZK Proof Verification ---
        // In a real scenario, IZkVerifier.verifyProof would take more specific public inputs
        // derived from generationParamsHash and zkProofHash.
        // For this example, we'll assume a simplified public input structure.
        IZkVerifier verifier = IZkVerifier(zkVerifierAddress);
        bytes32[2] memory publicInputs = [generationParamsHash, zkProofHash];
        if (!verifier.verifyProof(zkProofData, publicInputs)) {
            revert ZKProofFailed(); // Custom error for ZK proof failure
        }
        // --- End ZK Proof Verification ---

        uint256 newTokenId = _nextTokenId++;
        _owners[newTokenId] = recipient;
        _balances[recipient]++;

        assetDetails[newTokenId] = AssetDetails({
            creator: msg.sender,
            generationParamsHash: generationParamsHash,
            zkProofHash: zkProofHash,
            creationTime: block.timestamp,
            isSubmittedForCuration: false,
            curationScoreSum: 0,
            totalReputationVoted: 0,
            finalCurationScore: 0,
            curationFinalized: false,
            aiQualityScore: 0 // Default to 0, can be updated by AI oracle
        });

        emit AssetMinted(newTokenId, recipient, generationParamsHash, zkProofHash);
        return newTokenId;
    }

    // --- CURATOR & REPUTATION MANAGEMENT FUNCTIONS ---

    /**
     * @dev Allows an address to stake tokens to become a curator.
     * @param amount The amount of tokens to stake. Must be at least `minCuratorStake`.
     */
    function stakeForCuratorRole(uint256 amount) public payable whenNotPaused {
        if (curatorStake[msg.sender] > 0) revert AlreadyCurator();
        if (amount < minCuratorStake) revert InsufficientStake();
        if (msg.value < amount) revert InvalidAmount(); // Ensure enough ETH is sent if using native token

        curatorStake[msg.sender] = amount;
        curatorReputation[msg.sender] = INITIAL_REPUTATION; // Assign initial reputation
        curatorRewardPool += msg.value; // Add stake to the reward pool (simplified)

        emit CuratorStaked(msg.sender, amount, INITIAL_REPUTATION);
    }

    /**
     * @dev Allows a curator to unstake their tokens and relinquish their role.
     * May incur penalties if reputation is very low.
     * Not allowed during an active challenge participation (simplified for now).
     */
    function unstakeCuratorRole() public whenNotPaused {
        if (curatorStake[msg.sender] == 0) revert NotACurator();
        if (curatorReputation[msg.sender] < 0) revert InsufficientReputation(); // Example of reputation penalty

        uint256 amountToReturn = curatorStake[msg.sender];
        delete curatorStake[msg.sender];
        delete curatorReputation[msg.sender];
        delete reputationDelegates[msg.sender]; // Clear any delegation

        // Simplified: return stake directly. In a real system, there might be cooldowns, slashing conditions.
        payable(msg.sender).transfer(amountToReturn);
        curatorRewardPool -= amountToReturn; // Deduct from simplified pool

        emit CuratorUnstaked(msg.sender, amountToReturn);
    }

    /**
     * @dev Internal function to adjust a curator's reputation score.
     * @param curator The address of the curator.
     * @param change The amount to change the reputation by (can be negative).
     */
    function _updateCuratorReputation(address curator, int256 change) internal {
        if (curatorStake[curator] == 0) return; // Only update reputation for active curators

        // Prevent underflow/overflow for reputation
        uint256 currentRep = curatorReputation[curator];
        if (change < 0) {
            uint256 absChange = uint256(-change);
            curatorReputation[curator] = (currentRep > absChange) ? currentRep - absChange : 0;
        } else {
            curatorReputation[curator] = currentRep + uint256(change);
        }

        emit ReputationUpdated(curator, change, curatorReputation[curator]);
    }

    /**
     * @dev Allows a curator to delegate their reputation and voting power to another address.
     * The delegatee must also be a curator.
     * @param delegatee The address to delegate reputation to.
     */
    function delegateReputation(address delegatee) public whenNotPaused {
        if (curatorStake[msg.sender] == 0) revert NotACurator();
        if (delegatee != address(0) && curatorStake[delegatee] == 0) revert NotACurator(); // Delegatee must be a curator
        if (delegatee == msg.sender) revert InvalidRecipient();

        reputationDelegates[msg.sender] = delegatee;
        emit ReputationDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Internal function to get the effective reputation of an address, considering delegation.
     */
    function _getEffectiveReputation(address _address) internal view returns (uint256) {
        address current = _address;
        // Follow delegation chain (up to a reasonable limit to prevent loops, simplified for brevity)
        for (uint256 i = 0; i < 5; i++) { // Max 5 hops for delegation
            address delegatedTo = reputationDelegates[current];
            if (delegatedTo == address(0) || delegatedTo == current) break; // No further delegation or self-delegation
            current = delegatedTo;
        }
        return curatorReputation[current];
    }

    // --- CURATION & VOTING FUNCTIONS ---

    /**
     * @dev Marks an asset as ready for community curation.
     * Only the asset owner can submit it for curation.
     * @param tokenId The ID of the asset to submit.
     */
    function submitAssetForCuration(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert AssetNotOwnedBySender();
        if (assetDetails[tokenId].isSubmittedForCuration) revert AlreadyExists(); // Already submitted
        if (assetDetails[tokenId].curationFinalized) revert CurationAlreadyFinalized();

        assetDetails[tokenId].isSubmittedForCuration = true;
        emit AssetSubmittedForCuration(tokenId);
    }

    /**
     * @dev Allows a qualified curator to vote on an asset's quality.
     * @param tokenId The ID of the asset to vote on.
     * @param score The quality score (0-100).
     */
    function voteOnAssetQuality(uint256 tokenId, uint8 score) public whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!assetDetails[tokenId].isSubmittedForCuration) revert NotSubmittedForCuration();
        if (assetDetails[tokenId].curationFinalized) revert CurationAlreadyFinalized();
        if (hasCuratorVoted[tokenId][msg.sender]) revert AlreadyVoted();
        if (score > 100) revert InvalidScore();

        uint256 effectiveRep = _getEffectiveReputation(msg.sender);
        if (effectiveRep < MIN_REPUTATION_FOR_VOTE) revert InsufficientReputation();

        // Register the vote
        assetDetails[tokenId].curationScoreSum += score * effectiveRep;
        assetDetails[tokenId].totalReputationVoted += effectiveRep;
        hasCuratorVoted[tokenId][msg.sender] = true;

        // Simplified reputation update: small reward for voting, larger for accurate finalization
        _updateCuratorReputation(msg.sender, 1); // Small reputation gain for participation

        emit AssetVoted(tokenId, msg.sender, score, effectiveRep);
    }

    /**
     * @dev Finalizes the curation process for an asset, calculating its final score
     * and potentially updating dynamic attributes.
     * Can only be called if enough votes have been accumulated.
     * @param tokenId The ID of the asset to finalize curation for.
     */
    function finalizeCuration(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!assetDetails[tokenId].isSubmittedForCuration) revert NotSubmittedForCuration();
        if (assetDetails[tokenId].curationFinalized) revert CurationAlreadyFinalized();
        if (assetDetails[tokenId].totalReputationVoted == 0) revert CurationNotReady(); // No votes yet

        // Check if enough unique curators have voted
        // (This would require iterating `hasCuratorVoted` which is expensive.
        // A more practical solution would be to track unique voters in `AssetDetails` struct.)
        // For simplicity, we'll just check total reputation weight for now, assuming sufficient unique voters for it to be non-zero.
        if (assetDetails[tokenId].totalReputationVoted < MIN_CURATION_VOTES_FOR_FINALIZATION * MIN_REPUTATION_FOR_VOTE) { // Simplified
             revert CurationNotReady();
        }

        uint256 finalScore = assetDetails[tokenId].curationScoreSum / assetDetails[tokenId].totalReputationVoted;
        assetDetails[tokenId].finalCurationScore = finalScore;
        assetDetails[tokenId].curationFinalized = true;

        // Distribute curation rewards to those who voted
        // (Simplified: all who voted get a share proportional to their rep, but only after finalization logic is decided)
        // More advanced: Rewards based on how close their vote was to the final consensus.
        // For now, let's keep it simple: a small reward for all participants after finalization
        // This is complex and usually requires a separate mechanism, just demonstrating the intent.
        // uint256 rewardPerReputationPoint = (curatorRewardPool * 100) / assetDetails[tokenId].totalReputationVoted; // Example

        // This would iterate over all curators that voted, which is not feasible in Solidity.
        // A more advanced design uses a Merkle drop or allows curators to claim specific asset rewards.
        // For this example, let's assume `claimCurationRewards` handles general rewards.

        emit CurationFinalized(tokenId, finalScore);
    }

    // --- CREATIVE CHALLENGE & SUBMISSION FUNCTIONS ---

    /**
     * @dev Allows authorized users (e.g., owner) to propose new creative challenges.
     * @param _theme The theme or prompt for the challenge.
     * @param _duration The duration of the challenge in seconds.
     * @param _requiredReputation The minimum reputation needed to submit an entry.
     * @param _entryFee The fee (in contract's native token or ETH) to enter the challenge.
     * @param _rewardPool The total reward pool for this specific challenge.
     */
    function createChallenge(
        string memory _theme,
        uint256 _duration,
        uint256 _requiredReputation,
        uint256 _entryFee,
        uint256 _rewardPool
    ) public payable onlyOwner whenNotPaused returns (uint256) {
        if (_duration == 0) revert InvalidDuration();
        if (msg.value < _rewardPool) revert InvalidAmount(); // Ensure enough ETH for reward pool

        uint256 challengeId = _nextChallengeId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        challenges[challengeId] = Challenge({
            id: challengeId,
            theme: _theme,
            creator: msg.sender,
            startTime: startTime,
            endTime: endTime,
            requiredReputation: _requiredReputation,
            entryFee: _entryFee,
            rewardPool: _rewardPool,
            submittedEntries: new uint256[](0),
            isEntry: new mapping(uint256 => bool)(), // Initialize mapping
            finalized: false,
            winners: new address[](0),
            winnerRewards: new mapping(address => uint256)() // Initialize mapping
        });

        emit ChallengeCreated(challengeId, _theme, msg.sender, startTime, endTime);
        return challengeId;
    }

    /**
     * @dev Allows users to submit their minted assets as entries for active challenges.
     * @param _challengeId The ID of the challenge to submit to.
     * @param _assetId The ID of the asset to submit.
     */
    function submitChallengeEntry(uint256 _challengeId, uint256 _assetId) public payable whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (block.timestamp < challenge.startTime) revert ChallengeNotYetStarted();
        if (block.timestamp > challenge.endTime) revert ChallengeExpired();
        if (ownerOf(_assetId) != msg.sender) revert AssetNotOwnedBySender();
        if (challenge.isEntry[_assetId]) revert AlreadySubmittedToChallenge();
        if (assetDetails[_assetId].curationFinalized) revert AssetAlreadyInChallenge(); // Prevents double-dipping for finalized assets

        if (_getEffectiveReputation(msg.sender) < challenge.requiredReputation) revert InsufficientReputation();
        if (msg.value < challenge.entryFee) revert InvalidAmount(); // Ensure entry fee is paid

        challenge.submittedEntries.push(_assetId);
        challenge.isEntry[_assetId] = true;
        // If there's an entry fee, it should go to a general pool or specific challenge pool
        if (challenge.entryFee > 0) {
            // Simplified: Add to a general pool. A real implementation might add to challenge.rewardPool or burn.
            curatorRewardPool += msg.value;
        }

        emit ChallengeEntrySubmitted(_challengeId, _assetId, msg.sender);
    }

    /**
     * @dev Finalizes a challenge, determines winners based on curation scores, and distributes rewards.
     * Only the challenge creator or owner can finalize.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (msg.sender != challenge.creator && msg.sender != _owner) revert NoPermission();
        if (block.timestamp <= challenge.endTime) revert ChallengeNotExpired();
        if (challenge.finalized) revert ChallengeAlreadyFinalized();

        challenge.finalized = true;

        // Determine winners based on finalCurationScore of submitted entries
        // This is a simplified logic. A real contest might have more complex ranking.
        uint256 highestScore = 0;
        address[] memory potentialWinners = new address[](challenge.submittedEntries.length);
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < challenge.submittedEntries.length; i++) {
            uint256 tokenId = challenge.submittedEntries[i];
            // Ensure curation is finalized for challenge entries, or finalize it here
            if (!assetDetails[tokenId].curationFinalized) {
                // We should ideally call finalizeCuration for each entry if not done already.
                // For simplicity, we'll skip assets not finalized, or assume a separate process.
                // This would be a place to ensure all challenge entries get curated automatically.
                // For this example, let's assume they *must* be finalized by this point for scoring.
                // Or, we could call `finalizeCuration(tokenId)` here.
            }
            
            uint256 score = assetDetails[tokenId].finalCurationScore; // Use final score
            address assetOwner = ownerOf(tokenId);

            if (score > highestScore) {
                highestScore = score;
                winnerCount = 0; // Reset for new highest score
                potentialWinners[winnerCount++] = assetOwner;
            } else if (score == highestScore && score > 0) {
                // Check if already in potentialWinners to avoid duplicates (if an owner has multiple highest-score assets)
                bool alreadyAdded = false;
                for (uint256 j = 0; j < winnerCount; j++) {
                    if (potentialWinners[j] == assetOwner) {
                        alreadyAdded = true;
                        break;
                    }
                }
                if (!alreadyAdded) {
                    potentialWinners[winnerCount++] = assetOwner;
                }
            }
        }

        // Distribute rewards (example: equally among top scorers)
        if (highestScore > 0 && winnerCount > 0) {
            uint256 rewardPerWinner = challenge.rewardPool / winnerCount;
            for (uint256 i = 0; i < winnerCount; i++) {
                address winner = potentialWinners[i];
                if (winner != address(0)) {
                    challenge.winners.push(winner);
                    challenge.winnerRewards[winner] += rewardPerWinner;
                }
            }
        }
        
        emit ChallengeFinalized(_challengeId, challenge.winners, new uint256[](0)); // Placeholder for reward amounts
    }

    // --- AI ORACLE & DYNAMIC METADATA FUNCTIONS ---

    /**
     * @dev Sets the address of the trusted AI Oracle contract.
     * Only the contract owner can do this.
     * @param _newOracle The address of the new AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        aiOracleAddress = _newOracle;
    }

    /**
     * @dev Requests an AI oracle to provide an initial quality assessment for an asset.
     * This is a simplified direct call. In a real system, it would be an async request/fulfill pattern.
     * @param _tokenId The ID of the asset to get an AI quality score for.
     */
    function requestAIQualityScore(uint256 _tokenId) public whenNotPaused {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();
        if (aiOracleAddress == address(0)) revert ZeroAddress(); // AI Oracle not set

        // Simulate interaction with AI Oracle
        // A real system would have the AI Oracle call back to update `aiQualityScore`
        // For demonstration, we'll assume it's set directly, but this is highly simplified.
        IAIOracle oracle = IAIOracle(aiOracleAddress);
        uint256 score = oracle.getQualityScore(_tokenId); // Direct call - in real, this would be `request`
        assetDetails[_tokenId].aiQualityScore = score;

        emit AIOracleRequested(_tokenId, aiOracleAddress);
    }

    // --- TOKENOMICS & REWARD DISTRIBUTION FUNCTIONS ---

    /**
     * @dev Allows curators to claim their accumulated rewards from the general curation reward pool.
     */
    function claimCurationRewards() public whenNotPaused {
        uint256 rewards = curatorPendingRewards[msg.sender];
        if (rewards == 0) revert NoRewardsToClaim();

        curatorPendingRewards[msg.sender] = 0;
        curatorRewardPool -= rewards; // Deduct from the main pool

        payable(msg.sender).transfer(rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Allows challenge winners to claim their prizes from a specific challenge's reward pool.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeRewards(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (!challenge.finalized) revert ChallengeNotFinalized();

        uint256 rewards = challenge.winnerRewards[msg.sender];
        if (rewards == 0) revert NoRewardsToClaim();

        challenge.winnerRewards[msg.sender] = 0;
        // Direct transfer from challenge.rewardPool is needed, but we're tracking a single pool here.
        // In a real system, each challenge would have a dedicated balance.
        // For simplicity, assume challenge.rewardPool is deducted from the contract's total balance
        // when the reward is set, and this function transfers from the contract itself.
        payable(msg.sender).transfer(rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev A payable function allowing anyone to send ETH to the contract,
     * funding the general reward pool.
     */
    function fundContract() public payable {
        if (msg.value == 0) revert InvalidAmount();
        curatorRewardPool += msg.value; // Add to the general curation reward pool
    }


    // --- GOVERNANCE & ADMINISTRATIVE FUNCTIONS ---

    /**
     * @dev Allows the owner to adjust the minimum stake required for new curators.
     * @param _newStake The new minimum stake amount.
     */
    function setMinimumCuratorStake(uint256 _newStake) public onlyOwner {
        minCuratorStake = _newStake;
    }

    /**
     * @dev Pauses critical contract functionalities in case of an emergency or upgrade.
     * Only the contract owner can call this.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring full functionality.
     * Only the contract owner can call this.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Custom error for ZK proof failure
    error ZKProofFailed();
    error ChallengeNotExpired();
    error ChallengeAlreadyFinalized();
}
```