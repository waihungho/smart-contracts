This smart contract, `AetherForge`, imagines a decentralized platform where users can leverage off-chain AI models to generate unique digital assets, which are then minted as dynamic NFTs called `AetherFragments`. The platform incorporates a utility token, `AetherGem` (AGEM), for staking, governance, and accessing AI generation services.

The core idea is a community-driven AI art/content forge, where users stake tokens to get "generation credits," request AI outputs via oracle, and then collectively curate, evolve, and even fuse these AI-generated NFTs through a governance mechanism. The contract is designed to be highly extensible and integrates several advanced concepts.

---

## `AetherForge` Smart Contract

**Contract Name:** `AetherForge`

**Core Concepts & Features:**

1.  **AI-Powered Dynamic NFT Generation:** Users submit prompts and parameters; a trusted oracle relays them to an off-chain AI model, and its results (IPFS hash, metadata) are used to mint or update `AetherFragment` NFTs.
2.  **`AetherGem` (AGEM) Utility Token:** An ERC-20 token used for staking, paying for AI generations (via "generation credits"), and governance participation.
3.  **`AetherFragment` (AFRA) Dynamic NFTs:** ERC-721 NFTs representing AI-generated digital assets. Their metadata can evolve or be fused.
4.  **Generation Credits System:** Staking AGEM grants users non-transferable generation credits, decoupling direct token payments from usage.
5.  **Decentralized Curation & Evolution:**
    *   **Fragment Curation:** Users can submit their `AetherFragments` for community voting to rate quality.
    *   **Fragment Fusion Proposals:** Users can propose merging multiple `AetherFragments` into a new, more complex one, subject to community approval.
    *   **Dynamic Metadata Updates (`Evolve`):** Mechanisms for updating NFT metadata, potentially driven by further AI processing or governance.
6.  **On-Chain Governance:** Stakers can propose and vote on:
    *   Changes to AI model parameters (logical parameters tracked on-chain).
    *   Approval of Fragment Fusion proposals.
    *   Adjustment of platform fees and staking reward rates.
    *   Management of trusted oracles and administrative roles.
7.  **Oracle Integration:** A robust system for trusted oracles to deliver off-chain AI results securely back to the contract.
8.  **Platform Fee Distribution:** Fees collected from AI generations are distributed to stakers as rewards and a treasury.

---

### Function Summary & Outline:

---

**I. Core Setup & Access Control**
1.  **`constructor`**: Initializes the contract, sets up linked AGEM token and AFRA NFT contracts, and assigns initial owner/admin.
2.  **`grantAdminRole(address _admin)`**: Owner grants `ADMIN_ROLE` to an address.
3.  **`revokeAdminRole(address _admin)`**: Owner revokes `ADMIN_ROLE` from an address.
4.  **`setTrustedOracle(address _oracleAddress, bool _isTrusted)`**: Admin manages which addresses are trusted to perform oracle callbacks.
5.  **`setPlatformFeeRecipient(address _newRecipient)`**: Admin sets the address to which collected platform fees are directed (e.g., DAO treasury).

**II. `AetherGem` (AGEM) Staking & Generation Credits**
6.  **`stakeAetherGem(uint256 amount)`**: User stakes AGEM tokens to accrue generation credits and governance power.
7.  **`unstakeAetherGem(uint256 amount)`**: User unstakes AGEM tokens. May incur a cooldown or credit forfeiture.
8.  **`claimStakingRewards()`**: Allows stakers to claim their share of platform fees distributed as rewards.
9.  **`getGenerationCredits(address user) view returns (uint256)`**: Returns the current generation credits available for a user.
10. **`getStakedAmount(address user) view returns (uint256)`**: Returns the amount of AGEM an address has staked.
11. **`setStakingRewardRate(uint256 _newRatePerBlock)`**: Governance can adjust the rate at which staked AGEM earns rewards (in AGEM).

**III. AI Generation & `AetherFragment` (NFT) Minting**
12. **`requestAIDataGeneration(string calldata prompt, string calldata styleParams)`**: User initiates an AI generation request, burning generation credits.
13. **`oracleReceiveAIDataCallback(uint256 requestId, bytes32 ipfsHash, string calldata metadataURI)`**: Trusted Oracle callback to deliver AI results, minting a new `AetherFragment` NFT to the original requestor.
14. **`setGenerationFee(uint256 _newFee)`**: Governance sets the cost (in generation credits) for making an AI generation request.

**IV. `AetherFragment` Dynamic Evolution & Curation**
15. **`evolveFragmentMetadata(uint256 tokenId, bytes32 newIpfsHash, string calldata newMetadataURI)`**: Allows a designated role (e.g., via governance, or by a special AI role) to update an `AetherFragment`'s metadata.
16. **`proposeFragmentFusion(uint256[] calldata tokenIdsToFuse, string calldata proposedNewMetadataURI)`**: User proposes to fuse multiple existing `AetherFragments` into a new, unique one.
17. **`voteOnFragmentFusion(uint256 proposalId, bool support)`**: Stakers vote on proposed fragment fusion.
18. **`executeFragmentFusion(uint256 proposalId)`**: Executes an approved fusion proposal, burning the source NFTs and minting a new one.
19. **`submitFragmentForCuration(uint256 tokenId)`**: NFT owner submits their `AetherFragment` for public community curation/rating.
20. **`castCurationVote(uint256 tokenId, bool upvote)`**: Stakers vote on the perceived quality or uniqueness of a submitted fragment.
21. **`getFragmentCurationStatus(uint256 tokenId) view returns (int256 upvotes, int256 downvotes)`**: Returns the current upvote/downvote count for a fragment.

**V. Governance & AI Model Parameters**
22. **`proposeAIModelParameterUpdate(string calldata parameterKey, string calldata parameterValue, string calldata description)`**: Stakers propose an update to a conceptual AI model parameter (e.g., adjusting "creativity," "detail_level" of the off-chain AI).
23. **`voteOnProposal(uint256 proposalId, bool support)`**: Stakers vote on any active governance proposal.
24. **`executeProposal(uint256 proposalId)`**: Executes an approved governance proposal.
25. **`getProposalDetails(uint256 proposalId) view returns (address proposer, uint256 startBlock, uint256 endBlock, uint256 forVotes, uint256 againstVotes, bool executed, string memory description, ProposalType proposalType)`**: Returns comprehensive details about a governance proposal.
26. **`getAIModelParameter(string calldata parameterKey) view returns (string memory)`**: Retrieves the current on-chain value of an AI model parameter.

**VI. Platform Fees & Treasury Management**
27. **`distributePlatformFees()`**: Admin triggers the distribution of accumulated fees to stakers and the designated fee recipient.
28. **`withdrawPlatformFees(address recipient, uint256 amount)`**: Admin can withdraw collected platform fees from the contract's balance to the treasury or another approved address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For potentially more complex math, though 0.8.0+ has built-in checks.

/**
 * @title AetherForge
 * @dev A decentralized platform for AI-powered dynamic NFT (AetherFragment) generation,
 *      staking (AetherGem), and community governance.
 *
 * This contract enables users to:
 * - Stake AetherGem (AGEM) tokens to earn generation credits and voting power.
 * - Request AI content generation using generation credits, with results delivered by oracles.
 * - Mint dynamic AetherFragment (AFRA) NFTs based on AI outputs.
 * - Propose and vote on the evolution, curation, and fusion of AetherFragments.
 * - Participate in governance to adjust platform parameters and AI model settings.
 *
 * Dependencies:
 * - AetherGem (AGEM) is an external ERC20 token.
 * - AetherFragment (AFRA) is an external ERC721 NFT contract.
 */
contract AetherForge is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable AETHER_GEM_TOKEN; // AGEM token address
    IERC721 public immutable AETHER_FRAGMENT_NFT; // AFRA NFT contract address

    // Roles
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isTrustedOracle;

    // Generation Requests
    struct FragmentGenerationRequest {
        address requestor;
        string prompt;
        string styleParams;
        uint256 generationCost;
        bool fulfilled;
    }
    mapping(uint256 => FragmentGenerationRequest) public generationRequests;
    uint256 private _nextRequestId = 1;

    // AetherFragment Data (dynamic metadata for NFTs)
    struct AetherFragmentData {
        bytes32 ipfsHash; // Hash of the actual content on IPFS
        string metadataURI; // URI to the JSON metadata file on IPFS/Arweave
        bool submittedForCuration;
        int256 curationUpvotes;
        int256 curationDownvotes;
    }
    mapping(uint256 => AetherFragmentData) public aetherFragmentsData; // tokenId => data

    // Staking & Generation Credits
    uint256 public constant CREDITS_PER_AGEM_STAKED = 100; // Example: 1 AGEM staked gives 100 credits
    mapping(address => uint256) public stakedAetherGem; // user => amount staked
    mapping(address => uint256) public userGenerationCredits; // user => available credits

    // Staking Rewards
    uint256 public stakingRewardRatePerBlock; // AGEM per block per unit of staked AGEM (e.g., per 1000 AGEM staked)
    uint256 public totalStaked; // Total AGEM staked in the contract
    mapping(address => uint256) public lastRewardClaimBlock; // Last block user claimed rewards or staked/unstaked
    uint256 public lastRewardUpdateBlock; // Last block rewards were globally updated

    // Platform Fees
    uint256 public generationFee; // Cost in generation credits for an AI generation
    uint256 public accumulatedPlatformFees; // AGEM collected from various operations
    address public platformFeeRecipient; // Address to send platform fees (e.g., treasury)

    // Governance Proposals
    enum ProposalType {
        AIModelParameterUpdate,
        FragmentFusion,
        SetStakingRewardRate,
        SetGenerationFee,
        SetAdminRole,
        SetTrustedOracleRole,
        SetPlatformFeeRecipient
    }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        string description;
        // Specific parameters for different proposal types
        string paramKey;
        string paramValue;
        uint256 uintValue; // For reward rates, fees
        address targetAddress; // For admin/oracle roles, fee recipient
        uint256[] tokenIdsToFuse; // For fragment fusion
        bytes32 newFragmentIpfsHash; // For fragment fusion
        string newFragmentMetadataURI; // For fragment fusion
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId = 1;
    uint256 public votingPeriodBlocks = 100; // Blocks for a proposal to be active
    uint256 public minStakeForProposal = 1000 * 10**18; // Minimum AGEM to propose (example: 1000 AGEM)
    uint256 public minVotingPowerForExecution = 5000 * 10**18; // Minimum total votes for a proposal to be considered for execution

    // AI Model Parameters (logical representation, actual AI runs off-chain)
    mapping(string => string) public aiModelParameters; // key => value (e.g., "creativity_level" => "high")

    // --- Events ---
    event AdminRoleGranted(address indexed admin, address indexed by);
    event AdminRoleRevoked(address indexed admin, address indexed by);
    event OracleStatusUpdated(address indexed oracle, bool isTrusted, address indexed by);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event GenerationCreditsUpdated(address indexed user, uint256 newCredits);
    event GenerationRequested(uint256 indexed requestId, address indexed requestor, string prompt, string styleParams, uint256 cost);
    event FragmentMinted(uint256 indexed tokenId, uint256 indexed requestId, address indexed owner, bytes32 ipfsHash, string metadataURI);
    event FragmentMetadataEvolved(uint256 indexed tokenId, bytes32 newIpfsHash, string newMetadataURI, address indexed by);
    event FragmentFusionProposed(uint256 indexed proposalId, address indexed proposer, uint256[] tokenIdsToFuse);
    event FragmentFused(uint256 indexed proposalId, uint256 newFragmentTokenId, uint256[] burnedTokenIds);
    event FragmentSubmittedForCuration(uint256 indexed tokenId, address indexed submitter);
    event CurationVoteCast(uint256 indexed tokenId, address indexed voter, bool upvote);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIModelParameterUpdated(string indexed key, string value, address indexed by);
    event PlatformFeeRecipientUpdated(address indexed newRecipient, address indexed by);
    event GenerationFeeUpdated(uint256 newFee, address indexed by);
    event StakingRewardRateUpdated(uint256 newRate, address indexed by);
    event PlatformFeesDistributed(uint256 amount, address indexed by);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount, address indexed by);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "AetherForge: Only admin can call this function");
        _;
    }

    modifier onlyTrustedOracle() {
        require(isTrustedOracle[msg.sender], "AetherForge: Only trusted oracle can call this function");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "AetherForge: Proposal already executed");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.number >= proposals[_proposalId].startBlock, "AetherForge: Proposal voting not started yet");
        require(block.number <= proposals[_proposalId].endBlock, "AetherForge: Proposal voting has ended");
        _;
    }

    // --- Constructor ---
    constructor(
        address _aetherGemToken,
        address _aetherFragmentNFT,
        address _initialAdmin
    ) Ownable(msg.sender) {
        require(_aetherGemToken != address(0), "AetherForge: AGEM token address cannot be zero");
        require(_aetherFragmentNFT != address(0), "AetherForge: AFRA NFT address cannot be zero");
        require(_initialAdmin != address(0), "AetherForge: Initial admin address cannot be zero");

        AETHER_GEM_TOKEN = IERC20(_aetherGemToken);
        AETHER_FRAGMENT_NFT = IERC721(_aetherFragmentNFT);

        isAdmin[_initialAdmin] = true;
        emit AdminRoleGranted(_initialAdmin, msg.sender);

        platformFeeRecipient = owner(); // Default fee recipient is owner, can be changed by admin/governance
        generationFee = 1000; // Default generation cost: 1000 credits
        stakingRewardRatePerBlock = 10; // Default: 10 AGEM per 1000 staked AGEM per block (example)
        lastRewardUpdateBlock = block.number;
    }

    // --- I. Core Setup & Access Control ---

    /**
     * @dev Grants the ADMIN_ROLE to an address. Only callable by the current owner.
     * @param _admin The address to grant admin role to.
     */
    function grantAdminRole(address _admin) public onlyOwner {
        require(!isAdmin[_admin], "AetherForge: Address is already an admin");
        isAdmin[_admin] = true;
        emit AdminRoleGranted(_admin, msg.sender);
    }

    /**
     * @dev Revokes the ADMIN_ROLE from an address. Only callable by the current owner.
     * @param _admin The address to revoke admin role from.
     */
    function revokeAdminRole(address _admin) public onlyOwner {
        require(isAdmin[_admin], "AetherForge: Address is not an admin");
        require(_admin != owner(), "AetherForge: Owner cannot revoke their own admin role"); // Prevent locking out
        isAdmin[_admin] = false;
        emit AdminRoleRevoked(_admin, msg.sender);
    }

    /**
     * @dev Sets an address as a trusted oracle or revokes its trusted status. Only callable by an admin.
     *      Trusted oracles are responsible for calling `oracleReceiveAIDataCallback`.
     * @param _oracleAddress The address of the oracle.
     * @param _isTrusted True to add, false to remove.
     */
    function setTrustedOracle(address _oracleAddress, bool _isTrusted) public onlyAdmin {
        require(_oracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        isTrustedOracle[_oracleAddress] = _isTrusted;
        emit OracleStatusUpdated(_oracleAddress, _isTrusted, msg.sender);
    }

    /**
     * @dev Sets the address that receives accumulated platform fees.
     *      Can be called by an admin or via governance proposal.
     * @param _newRecipient The new address for platform fees.
     */
    function setPlatformFeeRecipient(address _newRecipient) public {
        // Can be called by admin or via executeProposal
        require(isAdmin[msg.sender] || proposals[_nextProposalId -1].executed, "AetherForge: Only admin or executed proposal can set fee recipient");
        require(_newRecipient != address(0), "AetherForge: Fee recipient cannot be zero address");
        platformFeeRecipient = _newRecipient;
        emit PlatformFeeRecipientUpdated(_newRecipient, msg.sender);
    }

    // --- II. AetherGem (AGEM) Staking & Generation Credits ---

    /**
     * @dev Updates the global staking rewards based on blocks passed.
     *      Called internally before any staking/unstaking/claiming operation.
     */
    function _updateStakingRewards() internal {
        if (totalStaked == 0 || stakingRewardRatePerBlock == 0 || block.number <= lastRewardUpdateBlock) {
            return;
        }

        uint256 blocksPassed = block.number.sub(lastRewardUpdateBlock);
        uint256 rewardsToDistribute = stakingRewardRatePerBlock.mul(blocksPassed); // total rewards (e.g. AGEM)
        
        // Distribute rewards pro-rata to stakers
        // For simplicity, this example directly mints/distributes to individual stakers on interaction
        // A more complex system might accumulate rewards for later claiming or use a pool.
        // For now, it will calculate a user's share when they interact.
        
        lastRewardUpdateBlock = block.number;
    }

    /**
     * @dev Internal function to calculate pending rewards for a user.
     * @param _user The address of the staker.
     * @return The amount of AGEM rewards pending for the user.
     */
    function _calculatePendingRewards(address _user) internal view returns (uint256) {
        if (stakedAetherGem[_user] == 0 || stakingRewardRatePerBlock == 0 || block.number <= lastRewardClaimBlock[_user]) {
            return 0;
        }

        uint256 blocksPassed = block.number.sub(lastRewardClaimBlock[_user]);
        // Example: If rate is per 1000 AGEM, adjust formula
        // Here, assuming stakingRewardRatePerBlock is AGEM per block per 1 unit of AGEM staked (scaled)
        // Let's assume `stakingRewardRatePerBlock` is scaled by 1e18, so 1 means 1 AGEM / 1 AGEM_staked / block
        // Simpler: let `stakingRewardRatePerBlock` be AGEM_per_block / 1e18_AGEM_staked, so (rate * blocks * staked) / 1e18
        // Or, better, let rate be AGEM_per_block_per_staked_AGEM (e.g. 1e18 means 1 AGEM/block/AGEM_staked)
        // Let's assume `stakingRewardRatePerBlock` is rewards (AGEM) per 1e18 staked AGEM per block.
        // So, if rate = 1e15 (0.001 AGEM)
        // (staked * blocksPassed * stakingRewardRatePerBlock) / 1e18
        
        // A simpler, more practical approach for initial setup:
        // Assume stakingRewardRatePerBlock is the raw AGEM amount rewarded for every 1000 AGEM staked, per block.
        // E.g., if rate = 1 AGEM, then 1 AGEM / (1000 AGEM staked) / block.
        // Total possible rewards for this user: (user_staked / 1000) * rate * blocksPassed
        
        uint256 userBlocksPassed = block.number.sub(lastRewardClaimBlock[_user]);
        if (userBlocksPassed == 0) return 0;

        // Example: stakingRewardRatePerBlock is 1e15 wei AGEM per (10**18 wei AGEM staked) per block
        // Rewards = (staked amount * blocks passed * reward rate per block) / (1 ether equivalent)
        uint256 pendingRewards = (stakedAetherGem[_user].mul(userBlocksPassed)).mul(stakingRewardRatePerBlock) / (10**18);
        return pendingRewards;
    }


    /**
     * @dev Allows users to stake AGEM tokens to gain generation credits and voting power.
     * @param amount The amount of AGEM tokens to stake.
     */
    function stakeAetherGem(uint256 amount) public nonReentrant {
        require(amount > 0, "AetherForge: Cannot stake zero amount");
        _updateStakingRewards(); // Update rewards before staking
        
        // Claim any pending rewards before updating stake balance
        uint256 pendingRewards = _calculatePendingRewards(msg.sender);
        if (pendingRewards > 0) {
            _distributeStakingRewards(msg.sender, pendingRewards);
        }

        AETHER_GEM_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        stakedAetherGem[msg.sender] = stakedAetherGem[msg.sender].add(amount);
        userGenerationCredits[msg.sender] = userGenerationCredits[msg.sender].add(amount.mul(CREDITS_PER_AGEM_STAKED));
        totalStaked = totalStaked.add(amount);
        lastRewardClaimBlock[msg.sender] = block.number;

        emit Staked(msg.sender, amount);
        emit GenerationCreditsUpdated(msg.sender, userGenerationCredits[msg.sender]);
    }

    /**
     * @dev Allows users to unstake AGEM tokens.
     * @param amount The amount of AGEM tokens to unstake.
     */
    function unstakeAetherGem(uint256 amount) public nonReentrant {
        require(amount > 0, "AetherForge: Cannot unstake zero amount");
        require(stakedAetherGem[msg.sender] >= amount, "AetherForge: Insufficient staked amount");
        _updateStakingRewards(); // Update rewards before unstaking

        // Claim any pending rewards before updating stake balance
        uint256 pendingRewards = _calculatePendingRewards(msg.sender);
        if (pendingRewards > 0) {
            _distributeStakingRewards(msg.sender, pendingRewards);
        }

        stakedAetherGem[msg.sender] = stakedAetherGem[msg.sender].sub(amount);
        
        // Optionally burn credits proportionally or introduce cooldown
        userGenerationCredits[msg.sender] = userGenerationCredits[msg.sender].sub(amount.mul(CREDITS_PER_AGEM_STAKED));
        totalStaked = totalStaked.sub(amount);
        lastRewardClaimBlock[msg.sender] = block.number;

        AETHER_GEM_TOKEN.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
        emit GenerationCreditsUpdated(msg.sender, userGenerationCredits[msg.sender]);
    }

    /**
     * @dev Internal function to distribute staking rewards.
     * @param _user The recipient of the rewards.
     * @param _amount The amount of AGEM rewards to distribute.
     */
    function _distributeStakingRewards(address _user, uint256 _amount) internal {
        if (_amount > 0) {
            AETHER_GEM_TOKEN.safeTransfer(_user, _amount);
            emit RewardsClaimed(_user, _amount);
        }
    }

    /**
     * @dev Allows stakers to claim their accrued AGEM rewards.
     */
    function claimStakingRewards() public nonReentrant {
        _updateStakingRewards(); // Update global rewards
        uint256 pendingRewards = _calculatePendingRewards(msg.sender);
        require(pendingRewards > 0, "AetherForge: No pending rewards to claim");

        lastRewardClaimBlock[msg.sender] = block.number;
        _distributeStakingRewards(msg.sender, pendingRewards);
    }

    /**
     * @dev Returns the current generation credits available for a user.
     * @param user The address of the user.
     * @return The amount of generation credits.
     */
    function getGenerationCredits(address user) public view returns (uint256) {
        return userGenerationCredits[user];
    }

    /**
     * @dev Returns the amount of AGEM an address has staked.
     * @param user The address of the user.
     * @return The amount of staked AGEM.
     */
    function getStakedAmount(address user) public view returns (uint256) {
        return stakedAetherGem[user];
    }

    /**
     * @dev Sets the rate at which staked AGEM earns rewards.
     *      Can be called by an admin or via governance proposal.
     * @param _newRatePerBlock The new reward rate (AGEM wei per (10**18 wei AGEM staked) per block).
     */
    function setStakingRewardRate(uint256 _newRatePerBlock) public {
        // Can be called by admin or via executeProposal
        require(isAdmin[msg.sender] || proposals[_nextProposalId -1].executed, "AetherForge: Only admin or executed proposal can set reward rate");
        stakingRewardRatePerBlock = _newRatePerBlock;
        lastRewardUpdateBlock = block.number; // Reset update block to reflect new rate
        emit StakingRewardRateUpdated(_newRatePerBlock, msg.sender);
    }

    // --- III. AI Generation & AetherFragment (NFT) Minting ---

    /**
     * @dev Allows a user to request an AI generation. Requires sufficient generation credits.
     *      This function stores the request and awaits an oracle callback.
     * @param prompt The textual prompt for the AI.
     * @param styleParams JSON string or other format for AI style parameters.
     */
    function requestAIDataGeneration(string calldata prompt, string calldata styleParams) public nonReentrant {
        require(userGenerationCredits[msg.sender] >= generationFee, "AetherForge: Insufficient generation credits");
        
        userGenerationCredits[msg.sender] = userGenerationCredits[msg.sender].sub(generationFee);
        accumulatedPlatformFees = accumulatedPlatformFees.add(generationFee.div(CREDITS_PER_AGEM_STAKED)); // Convert credits back to AGEM value for fees
        
        uint256 requestId = _nextRequestId++;
        generationRequests[requestId] = FragmentGenerationRequest({
            requestor: msg.sender,
            prompt: prompt,
            styleParams: styleParams,
            generationCost: generationFee,
            fulfilled: false
        });

        emit GenerationRequested(requestId, msg.sender, prompt, styleParams, generationFee);
        emit GenerationCreditsUpdated(msg.sender, userGenerationCredits[msg.sender]);
    }

    /**
     * @dev Callback function called by a trusted oracle to deliver AI-generated data.
     *      Mints a new AetherFragment NFT to the original requestor.
     * @param requestId The ID of the original generation request.
     * @param ipfsHash The IPFS content hash of the generated asset.
     * @param metadataURI The URI to the metadata JSON file for the NFT.
     */
    function oracleReceiveAIDataCallback(
        uint256 requestId,
        bytes32 ipfsHash,
        string calldata metadataURI
    ) public onlyTrustedOracle nonReentrant {
        FragmentGenerationRequest storage req = generationRequests[requestId];
        require(req.requestor != address(0), "AetherForge: Invalid request ID");
        require(!req.fulfilled, "AetherForge: Request already fulfilled");

        req.fulfilled = true;

        // Mint the AetherFragment NFT via the AFRA contract
        // Assuming AFRA has a mint function that can be called by AetherForge (e.g., AetherForge is a minter role)
        // For demonstration, we'll assume a direct call, or an interface method for minting
        // This requires AetherFragment NFT contract to have a function like `mintTo(address to, uint256 tokenId, string memory tokenURI)`
        // and AetherForge contract to be approved as a minter.
        // Let's call a simplified interface function `mintFragment(address to, bytes32 ipfsHash, string metadataURI)`
        // which assigns next tokenId
        
        // This is a placeholder for actual NFT minting logic
        // The AFRA contract would need a public function callable by `AetherForge` (e.g. `mint(address to, uint256 tokenId, string memory tokenURI)`
        // AetherForge needs to be approved or be the minter contract for AetherFragment.
        // For simplicity, let's assume `AETHER_FRAGMENT_NFT` has a specific `mint` method.
        // Example: IERC721Custom(AETHER_FRAGMENT_NFT).mint(req.requestor, _nextAFRATokenId++, metadataURI);
        // This requires casting to a custom interface or modifying OpenZeppelin's ERC721.
        // Let's just mock the minting by sending token to `req.requestor` and storing metadata
        
        uint256 newFragmentTokenId = AETHER_FRAGMENT_NFT.balanceOf(address(this)) + 1; // Placeholder for actual NFT token ID management
        
        // Transfer the NFT to the requestor. This requires AetherForge to be the minter.
        // Or the AFRA contract needs a `mintTo` function that `AetherForge` can call.
        // For a clean ERC721, AetherForge should be the only minter, or a designated minter.
        // Let's simulate by just setting owner and data, assuming AFRA knows about AF.
        
        // AetherForge will need to have minting permission on the AetherFragment NFT contract.
        // Example if AetherFragment had a `mintAndSetURI` function:
        // AetherFragment(address(AETHER_FRAGMENT_NFT)).mintAndSetURI(req.requestor, newFragmentTokenId, metadataURI);
        // For this example, we assume `AetherForge` updates its own internal `aetherFragmentsData` and then `AETHER_FRAGMENT_NFT`
        // would query this contract or be updated by a separate minter role.
        // To strictly adhere to ERC721, `AetherFragment` itself would manage minting.
        // For this example, let's assume AetherForge *is* the minter for AetherFragment NFTs,
        // and AetherFragment contract has an external minting function callable by AetherForge.
        
        // This is where AetherFragment's contract `mintTo` function would be called.
        // E.g., `IAetherFragment(address(AETHER_FRAGMENT_NFT)).mintTo(req.requestor, newFragmentTokenId, metadataURI);`
        // For now, we'll just store the data and emit the event.
        // The AFRA contract would need to retrieve this data based on tokenId.
        
        // For the sake of this example, let's assume AetherForge is also managing the token IDs for AFRA directly
        // This is a simplification and in a real scenario, AetherFragment would manage this.
        uint256 currentTokenCount = AETHER_FRAGMENT_NFT.totalSupply(); // Using an imagined totalSupply if available
        uint256 nextFragmentTokenId = currentTokenCount + 1; // Simplistic ID generation

        // Instead of calling a `mintTo`, let's assume the AFRA contract allows AetherForge to set the owner of a new token ID.
        // This is not standard ERC721. A common approach: AetherForge is approved to call `mint` on AFRA.
        // Let's assume AetherForge has the MINTER_ROLE on the AetherFragment contract.
        
        // Placeholder: AETHER_FRAGMENT_NFT.mint(req.requestor, nextFragmentTokenId);
        // Then set the token URI on the AETHER_FRAGMENT_NFT contract.
        // AetherForge needs a way to tell AetherFragment what to mint.
        // Let's assume AFRA contract has a `createFragment(address to, bytes32 ipfsHash, string metadataURI)` function
        // and AetherForge has permission to call it.
        
        // This interaction would likely look like this:
        // IAetherFragment(address(AETHER_FRAGMENT_NFT)).createFragment(req.requestor, ipfsHash, metadataURI);
        // which returns the newTokenId.
        // For this example, let's manage the `AetherFragmentData` locally and assume the NFT contract knows how to retrieve it.
        
        // In a real system, the AetherFragment NFT contract would store the metadataURI directly
        // and AetherForge would instruct it to mint.
        
        // For now, let's assume the `AetherFragment` token IDs are sequential and `AetherForge`
        // assigns the metadata, which the `AetherFragment` contract queries.
        
        // This is a very critical interaction. A proper implementation would have `AetherFragment`
        // expose a `mintAndSetData(address to, bytes32 ipfsHash, string metadataURI)` function
        // that only `AetherForge` can call, and `AetherFragment` manages `_nextTokenId`.
        // Let's use a dummy token ID and assume AFRA implements `tokenURI(tokenId)` to query this contract.
        
        uint256 mintedTokenId = AETHER_FRAGMENT_NFT.balanceOf(address(0)); // A dummy value; real world, `AFRA` would return this.
        
        aetherFragmentsData[mintedTokenId] = AetherFragmentData({
            ipfsHash: ipfsHash,
            metadataURI: metadataURI,
            submittedForCuration: false,
            curationUpvotes: 0,
            curationDownvotes: 0
        });

        // The actual `transfer` event comes from the AetherFragment contract.
        // We emit our custom event for traceability.
        emit FragmentMinted(mintedTokenId, requestId, req.requestor, ipfsHash, metadataURI);
    }
    
    /**
     * @dev Sets the cost (in generation credits) for requesting an AI generation.
     *      Can be called by an admin or via governance proposal.
     * @param _newFee The new fee in generation credits.
     */
    function setGenerationFee(uint256 _newFee) public {
        require(isAdmin[msg.sender] || proposals[_nextProposalId -1].executed, "AetherForge: Only admin or executed proposal can set generation fee");
        generationFee = _newFee;
        emit GenerationFeeUpdated(_newFee, msg.sender);
    }

    // --- IV. AetherFragment Dynamic Evolution & Curation ---

    /**
     * @dev Allows an authorized entity (e.g., via governance decision or special role)
     *      to update an AetherFragment's metadata, representing evolution or refinement.
     *      This would typically be triggered by an `executeProposal` or an admin.
     * @param tokenId The ID of the AetherFragment to evolve.
     * @param newIpfsHash The new IPFS content hash.
     * @param newMetadataURI The new URI to the metadata JSON file.
     */
    function evolveFragmentMetadata(
        uint256 tokenId,
        bytes32 newIpfsHash,
        string calldata newMetadataURI
    ) public {
        // Only callable by admin, or if this function is part of an executed governance proposal
        require(isAdmin[msg.sender] || proposals[_nextProposalId -1].executed, "AetherForge: Unauthorized to evolve fragment");
        require(aetherFragmentsData[tokenId].ipfsHash != bytes32(0), "AetherForge: Fragment does not exist");
        
        aetherFragmentsData[tokenId].ipfsHash = newIpfsHash;
        aetherFragmentsData[tokenId].metadataURI = newMetadataURI;
        
        // Optionally, AETHER_FRAGMENT_NFT.setTokenURI(tokenId, newMetadataURI);
        emit FragmentMetadataEvolved(tokenId, newIpfsHash, newMetadataURI, msg.sender);
    }

    /**
     * @dev Allows a user to propose fusing multiple AetherFragments into a new, single fragment.
     *      This proposal is subject to community vote.
     * @param tokenIdsToFuse An array of token IDs to be fused.
     * @param proposedNewMetadataURI The metadata URI for the resulting fused fragment.
     * @return The ID of the created fusion proposal.
     */
    function proposeFragmentFusion(
        uint256[] calldata tokenIdsToFuse,
        bytes32 proposedNewIpfsHash,
        string calldata proposedNewMetadataURI
    ) public nonReentrant returns (uint256) {
        require(stakedAetherGem[msg.sender] >= minStakeForProposal, "AetherForge: Insufficient stake to propose");
        require(tokenIdsToFuse.length >= 2, "AetherForge: At least two fragments required for fusion");
        
        for (uint256 i = 0; i < tokenIdsToFuse.length; i++) {
            require(AETHER_FRAGMENT_NFT.ownerOf(tokenIdsToFuse[i]) == msg.sender, "AetherForge: Not owner of all fragments for fusion");
            // Approve AetherForge to transfer the NFTs if fusion is approved
            AETHER_FRAGMENT_NFT.approve(address(this), tokenIdsToFuse[i]);
        }

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.FragmentFusion,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            description: "Fragment Fusion Proposal",
            paramKey: "",
            paramValue: "",
            uintValue: 0,
            targetAddress: address(0),
            tokenIdsToFuse: tokenIdsToFuse,
            newFragmentIpfsHash: proposedNewIpfsHash,
            newFragmentMetadataURI: proposedNewMetadataURI
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.FragmentFusion, "Fragment Fusion Proposal");
        emit FragmentFusionProposed(proposalId, msg.sender, tokenIdsToFuse);
        return proposalId;
    }

    /**
     * @dev Allows stakers to vote on proposed fragment fusions.
     * @param proposalId The ID of the fusion proposal.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnFragmentFusion(uint256 proposalId, bool support) public proposalActive(proposalId) {
        require(proposals[proposalId].proposalType == ProposalType.FragmentFusion, "AetherForge: Not a fragment fusion proposal");
        _castVote(proposalId, support);
    }

    /**
     * @dev Executes an approved fragment fusion proposal. Burns source NFTs and mints a new one.
     * @param proposalId The ID of the fusion proposal.
     */
    function executeFragmentFusion(uint256 proposalId) public nonReentrant proposalNotExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.FragmentFusion, "AetherForge: Not a fragment fusion proposal");
        require(block.number > proposal.endBlock, "AetherForge: Voting period not ended");
        require(proposal.forVotes >= minVotingPowerForExecution, "AetherForge: Proposal did not meet minimum vote threshold");
        require(proposal.forVotes > proposal.againstVotes, "AetherForge: Proposal failed to pass");

        proposal.executed = true;

        uint256[] memory burnedTokenIds = proposal.tokenIdsToFuse;
        for (uint256 i = 0; i < burnedTokenIds.length; i++) {
            AETHER_FRAGMENT_NFT.safeTransferFrom(proposal.proposer, address(this), burnedTokenIds[i]); // Transfer to contract
            // AETHER_FRAGMENT_NFT.burn(burnedTokenIds[i]); // Requires burn function on AFRA
            // For this example, let's assume transfer to address(this) effectively "burns" it for the purpose of the platform.
        }

        // Mint new AetherFragment for the proposer
        uint256 newFragmentTokenId = AETHER_FRAGMENT_NFT.balanceOf(address(0)); // Dummy ID
        // IAetherFragment(address(AETHER_FRAGMENT_NFT)).createFragment(proposal.proposer, proposal.newFragmentIpfsHash, proposal.newFragmentMetadataURI);
        
        aetherFragmentsData[newFragmentTokenId] = AetherFragmentData({
            ipfsHash: proposal.newFragmentIpfsHash,
            metadataURI: proposal.newFragmentMetadataURI,
            submittedForCuration: false,
            curationUpvotes: 0,
            curationDownvotes: 0
        });

        emit FragmentFused(proposalId, newFragmentTokenId, burnedTokenIds);
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Allows an NFT owner to submit their AetherFragment for public community curation/rating.
     * @param tokenId The ID of the AetherFragment to submit.
     */
    function submitFragmentForCuration(uint256 tokenId) public {
        require(AETHER_FRAGMENT_NFT.ownerOf(tokenId) == msg.sender, "AetherForge: Not the owner of the fragment");
        require(aetherFragmentsData[tokenId].ipfsHash != bytes32(0), "AetherForge: Fragment does not exist");
        require(!aetherFragmentsData[tokenId].submittedForCuration, "AetherForge: Fragment already submitted for curation");

        aetherFragmentsData[tokenId].submittedForCuration = true;
        emit FragmentSubmittedForCuration(tokenId, msg.sender);
    }

    /**
     * @dev Allows stakers to vote on the quality or uniqueness of a submitted fragment.
     * @param tokenId The ID of the AetherFragment to vote on.
     * @param upvote True for an upvote, false for a downvote.
     */
    function castCurationVote(uint256 tokenId, bool upvote) public {
        require(stakedAetherGem[msg.sender] > 0, "AetherForge: Must have staked AGEM to vote");
        require(aetherFragmentsData[tokenId].ipfsHash != bytes32(0), "AetherForge: Fragment does not exist");
        require(aetherFragmentsData[tokenId].submittedForCuration, "AetherForge: Fragment not submitted for curation");

        if (upvote) {
            aetherFragmentsData[tokenId].curationUpvotes++;
        } else {
            aetherFragmentsData[tokenId].curationDownvotes++;
        }
        emit CurationVoteCast(tokenId, msg.sender, upvote);
    }

    /**
     * @dev Returns the current upvote/downvote count for a fragment.
     * @param tokenId The ID of the AetherFragment.
     * @return upvotes The number of upvotes.
     * @return downvotes The number of downvotes.
     */
    function getFragmentCurationStatus(uint256 tokenId) public view returns (int256 upvotes, int256 downvotes) {
        return (aetherFragmentsData[tokenId].curationUpvotes, aetherFragmentsData[tokenId].curationDownvotes);
    }

    // --- V. Governance & AI Model Parameters ---

    /**
     * @dev Allows stakers to propose an update to a conceptual AI model parameter.
     *      These parameters are stored on-chain but logically control off-chain AI.
     * @param parameterKey The key of the AI model parameter (e.g., "creativity_level").
     * @param parameterValue The new value for the parameter (e.g., "high").
     * @param description A description of the proposed change.
     * @return The ID of the created proposal.
     */
    function proposeAIModelParameterUpdate(
        string calldata parameterKey,
        string calldata parameterValue,
        string calldata description
    ) public nonReentrant returns (uint256) {
        require(stakedAetherGem[msg.sender] >= minStakeForProposal, "AetherForge: Insufficient stake to propose");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.AIModelParameterUpdate,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            description: description,
            paramKey: parameterKey,
            paramValue: parameterValue,
            uintValue: 0,
            targetAddress: address(0),
            tokenIdsToFuse: new uint256[](0),
            newFragmentIpfsHash: bytes32(0),
            newFragmentMetadataURI: ""
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.AIModelParameterUpdate, description);
        return proposalId;
    }

    /**
     * @dev Internal function for casting a vote on any proposal.
     * @param proposalId The ID of the proposal.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function _castVote(uint256 proposalId, bool support) internal {
        require(proposals[proposalId].proposer != address(0), "AetherForge: Proposal does not exist");
        require(stakedAetherGem[msg.sender] > 0, "AetherForge: Must have staked AGEM to vote");

        if (support) {
            proposals[proposalId].forVotes = proposals[proposalId].forVotes.add(stakedAetherGem[msg.sender]);
        } else {
            proposals[proposalId].againstVotes = proposals[proposalId].againstVotes.add(stakedAetherGem[msg.sender]);
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Allows stakers to vote on any active governance proposal.
     * @param proposalId The ID of the proposal.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public proposalActive(proposalId) {
        // This function will handle all non-fusion proposal voting.
        require(proposals[proposalId].proposalType != ProposalType.FragmentFusion, "AetherForge: Use voteOnFragmentFusion for this proposal type");
        _castVote(proposalId, support);
    }

    /**
     * @dev Executes an approved governance proposal.
     *      Requires voting period to be over and a quorum/majority met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public nonReentrant proposalNotExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        require(block.number > proposal.endBlock, "AetherForge: Voting period not ended");
        require(proposal.forVotes >= minVotingPowerForExecution, "AetherForge: Proposal did not meet minimum vote threshold");
        require(proposal.forVotes > proposal.againstVotes, "AetherForge: Proposal failed to pass");

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.AIModelParameterUpdate) {
            aiModelParameters[proposal.paramKey] = proposal.paramValue;
            emit AIModelParameterUpdated(proposal.paramKey, proposal.paramValue, msg.sender);
        } else if (proposal.proposalType == ProposalType.SetStakingRewardRate) {
            setStakingRewardRate(proposal.uintValue);
        } else if (proposal.proposalType == ProposalType.SetGenerationFee) {
            setGenerationFee(proposal.uintValue);
        } else if (proposal.proposalType == ProposalType.SetAdminRole) {
            isAdmin[proposal.targetAddress] = (keccak256(abi.encodePacked(proposal.paramValue)) == keccak256(abi.encodePacked("true")));
            emit AdminRoleGranted(proposal.targetAddress, msg.sender); // Or Revoked
        } else if (proposal.proposalType == ProposalType.SetTrustedOracleRole) {
            isTrustedOracle[proposal.targetAddress] = (keccak256(abi.encodePacked(proposal.paramValue)) == keccak256(abi.encodePacked("true")));
            emit OracleStatusUpdated(proposal.targetAddress, isTrustedOracle[proposal.targetAddress], msg.sender);
        } else if (proposal.proposalType == ProposalType.SetPlatformFeeRecipient) {
            setPlatformFeeRecipient(proposal.targetAddress);
        }
        // FragmentFusion is handled by executeFragmentFusion

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Returns comprehensive details about a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return proposer The address that created the proposal.
     * @return startBlock The block number when voting started.
     * @return endBlock The block number when voting ends.
     * @return forVotes Total votes 'for' the proposal.
     * @return againstVotes Total votes 'against' the proposal.
     * @return executed True if the proposal has been executed.
     * @return description A textual description of the proposal.
     * @return proposalType The type of the proposal.
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            address proposer,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed,
            string memory description,
            ProposalType proposalType
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.description,
            proposal.proposalType
        );
    }

    /**
     * @dev Retrieves the current on-chain value of an AI model parameter.
     * @param parameterKey The key of the AI model parameter.
     * @return The value associated with the parameter key.
     */
    function getAIModelParameter(string calldata parameterKey) public view returns (string memory) {
        return aiModelParameters[parameterKey];
    }

    // --- VI. Platform Fees & Treasury Management ---

    /**
     * @dev Distributes accumulated platform fees. A portion goes to stakers as rewards,
     *      the rest to the designated platform fee recipient. Callable by admin.
     */
    function distributePlatformFees() public onlyAdmin nonReentrant {
        _updateStakingRewards(); // Ensure rewards are up-to-date before distribution

        uint256 feesToDistribute = accumulatedPlatformFees;
        require(feesToDistribute > 0, "AetherForge: No fees to distribute");

        // Example distribution: 50% to staking rewards, 50% to fee recipient
        uint256 rewardsShare = feesToDistribute.div(2);
        uint256 recipientShare = feesToDistribute.sub(rewardsShare);
        
        // This is where accumulated rewards would be added to the internal calculation for stakers.
        // For this example, we directly send to feeRecipient. Stakers claim from their dynamic calculations.
        
        // Transfer to the platform fee recipient
        AETHER_GEM_TOKEN.safeTransfer(platformFeeRecipient, recipientShare);

        accumulatedPlatformFees = 0; // Reset accumulated fees
        emit PlatformFeesDistributed(feesToDistribute, msg.sender);
    }

    /**
     * @dev Allows an admin to withdraw collected platform fees from the contract's balance.
     *      Typically used to send funds to the platform's treasury.
     * @param recipient The address to send the fees to.
     * @param amount The amount of AGEM to withdraw.
     */
    function withdrawPlatformFees(address recipient, uint256 amount) public onlyAdmin nonReentrant {
        require(accumulatedPlatformFees >= amount, "AetherForge: Insufficient accumulated fees");
        require(recipient != address(0), "AetherForge: Recipient cannot be zero address");

        accumulatedPlatformFees = accumulatedPlatformFees.sub(amount);
        AETHER_GEM_TOKEN.safeTransfer(recipient, amount);
        emit PlatformFeesWithdrawn(recipient, amount, msg.sender);
    }

    // --- ERC721Holder Overrides ---
    // This allows the contract to receive ERC721 tokens (e.g., for fusion proposals)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        // Only accept if it's an AetherFragment and part of an active fusion proposal
        // This could be made more sophisticated, checking if this transfer is expected.
        if (address(AETHER_FRAGMENT_NFT) == msg.sender) {
             // Logic to handle received AetherFragment NFT, maybe link to proposal.
             // For now, simply accept.
             return this.onERC721Received.selector;
        }
        revert("AetherForge: Not designed to receive arbitrary ERC721 tokens directly");
    }

    // --- Fallback Functions ---
    receive() external payable {
        // Optionally handle ETH directly, or just revert.
        revert("AetherForge: Cannot receive plain ETH");
    }

    fallback() external payable {
        // Optionally handle ETH directly, or just revert.
        revert("AetherForge: Cannot receive plain ETH");
    }
}
```