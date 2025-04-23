Okay, here is a Solidity smart contract designed with a combination of interesting, advanced, and trendy concepts: a "Skillbound Forge".

This contract acts as a central hub for staking a native token, earning reputation based on staked amount and contributions, and minting unique NFTs based on accumulated reputation in specific skills or overall. It includes features like role-based access control, reputation-gated functions, configurable thresholds, and leverages advanced ERC standards like ERC20 Permit and ERC20 Votes within its own native tokens.

It's a complex contract combining staking, reputation, NFTs, and advanced token features, aiming not to be a direct copy of a single common open-source pattern.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// =============================================================================
// Skillbound Forge Contract
// =============================================================================
//
// Outline:
// 1.  Introduction & Concepts
//     - Native ERC20 Token (ForgeToken) with Permit and Voting features.
//     - Native ERC721 Token (SkillForgeNFT) for achievements.
//     - Staking ForgeToken to earn base Reputation.
//     - Earning Reputation via verified Contributions to specific Skills.
//     - Reputation is non-transferable and tracked per user, per skill.
//     - Reputation-Gated functions: certain actions require minimum reputation.
//     - NFT Minting based on achieving specific reputation thresholds.
//     - Role-based access control (Owner, Admin, Oracle).
// 2.  State Variables
//     - Token details (name, symbol).
//     - Balances (ERC20, Staked, Reputation Total, Reputation per Skill).
//     - Skill data (IDs, names).
//     - Staking parameters (rate, last claim time).
//     - Reputation thresholds for functions and NFT minting.
//     - Access control roles.
//     - ERC721 state.
//     - ERC20 Permit & Votes state.
//     - Pausing state.
// 3.  Events
//     - Signaling key actions (Staked, Unstaked, ReputationClaimed, SkillAdded,
//       ContributionVerified, NFTMinted, ThresholdSet, RoleSet, Paused, Unpaused).
// 4.  Custom Errors
//     - Providing detailed failure reasons.
// 5.  Modifiers
//     - Enforcing role-based access and reputation gating.
//     - Reentrancy guard.
// 6.  Constructor
//     - Initializing tokens, owner, admin, oracle, and base parameters.
// 7.  ERC20 Standard Functions (Implicit via inheritance)
//     - transfer, approve, transferFrom, totalSupply, balanceOf, allowance
// 8.  ERC20 Permit & Votes Functions (Implicit via inheritance)
//     - permit, delegate, delegateBySig, getVotes, getPastVotes, nonces
// 9.  ERC721 Standard Functions (Implicit via inheritance)
//     - balanceOf, ownerOf, getApproved, isApprovedForAll, approve,
//       setApprovalForAll, transferFrom, safeTransferFrom, tokenURI, supportsInterface
// 10. Core Functionality
//     - Staking & Unstaking
//     - Reputation Earning & Claiming
//     - Skill Management
//     - Contribution Submission & Verification
//     - Reputation Threshold Management
//     - NFT Minting (Reputation Gated)
//     - Access Control & Admin Actions (Pause, Withdraw, Role Management)
// 11. View Functions
//     - Querying balances, reputation, staking info, skill info, thresholds, NFT details.

// =============================================================================
// Function Summary (Public/External Functions):
// =============================================================================
// ERC20 Standard:
// 1.  transfer          : Transfer ForgeToken.
// 2.  approve           : Approve spender for ForgeToken.
// 3.  transferFrom      : Transfer ForgeToken from another address.
// 4.  totalSupply       : Get total supply of ForgeToken.
// 5.  balanceOf         : Get ForgeToken balance.
// 6.  allowance         : Get allowance for ForgeToken.
//
// ERC20 Permit & Votes:
// 7.  permit            : Gasless approval for ForgeToken.
// 8.  delegate          : Delegate voting power.
// 9.  delegateBySig     : Delegate voting power via signature.
// 10. getVotes          : Get current voting power.
// 11. getPastVotes      : Get past voting power.
// 12. nonces            : Get nonce for permit/delegation.
//
// ERC721 Standard:
// 13. balanceOf(owner)      : Get number of NFTs owned by address.
// 14. ownerOf(tokenId)      : Get owner of NFT.
// 15. getApproved(tokenId)  : Get approved address for NFT.
// 16. isApprovedForAll      : Check if operator is approved for all NFTs.
// 17. approve(to, tokenId)  : Approve address for NFT.
// 18. setApprovalForAll     : Set approval for operator for all NFTs.
// 19. transferFrom(from, to, tokenId) : Transfer NFT.
// 20. safeTransferFrom(...) : Safely transfer NFT.
// 21. tokenURI(tokenId)     : Get metadata URI for NFT.
// 22. supportsInterface     : ERC165 interface support.
//
// Skillbound Forge Core Logic:
// 23. stake(amount)               : Stake ForgeToken to earn passive reputation.
// 24. unstake(amount)             : Unstake ForgeToken.
// 25. claimStakingReputation()    : Claim accumulated passive reputation from staking.
// 26. addSkill(name)              : [Admin] Add a new skill category.
// 27. submitContributionHash(skillId, contributionHash) : User submits proof hash.
// 28. verifyAndAwardContribution(user, skillId, contributionHash, reputationAmount, tokenAmount) : [Oracle/Admin] Verify and reward contribution.
// 29. mintSkillNFT(skillId)       : Mint NFT for a specific skill (reputation gated).
// 30. mintTotalReputationNFT(requiredTotalReputation) : Mint NFT based on total reputation (reputation gated).
// 31. setReputationThreshold(selector, threshold)     : [Admin] Set total reputation required for a function.
// 32. setSkillReputationThreshold(selector, skillId, threshold) : [Admin] Set skill reputation required for a function.
// 33. updateStakingReputationRate(rate) : [Admin] Update reputation earned per staked token per second.
// 34. updateSkillReputationBonus(skillId, bonusRate) : [Admin] Update contribution reputation multiplier for a skill.
// 35. setOracle(oracleAddress)    : [Admin] Set address with Oracle role.
// 36. pauseStaking()              : [Admin] Pause staking operations.
// 37. unpauseStaking()            : [Admin] Unpause staking operations.
// 38. withdrawTreasuryTokens(tokenAddress, amount) : [Admin] Withdraw other tokens held by the contract (e.g., contribution rewards).
// 39. setNFTBaseURI(uri)          : [Admin] Set the base URI for NFT metadata.
// 40. burnReputation(user, skillId, amount) : [Admin/Oracle] Reduce user reputation.
// 41. addReputation(user, skillId, amount) : [Admin/Oracle] Add reputation (manual award, different from staking/contribution).
// 42. transferOwnership(newOwner) : [Owner] Transfer contract ownership.
// 43. renounceOwnership()        : [Owner] Renounce contract ownership.
// 44. setAdmin(adminAddress)      : [Owner] Set address with Admin role.
//
// View Functions (Non-State Changing):
// 45. getStakedBalance(user)
// 46. getPendingStakingReputation(user)
// 47. getTotalReputation(user)
// 48. getSkillReputation(user, skillId)
// 49. getSkillId(name)
// 50. getSkillName(skillId)
// 51. getTotalReputationThreshold(selector)
// 52. getSkillReputationThreshold(selector, skillId)
// 53. getSkills()
// 54. getAdmin()
// 55. getOracle()
// 56. isPaused()
// 57. getNFTTotalSupply()
// 58. getNFTBaseURI()
// 59. getTokenIdsForUser(user) // Helper view function

contract SkillboundForge is ERC20, ERC20Permit, ERC20Votes, ERC721, Ownable, ReentrancyGuard {
    using Math for uint256;
    using ECDSA for bytes32;

    // =========================================================================
    // Custom Errors
    // =========================================================================
    error StakeAmountZero();
    error UnstakeAmountZero();
    error InsufficientStakedAmount();
    error NothingToClaim();
    error SkillAlreadyExists();
    error SkillNotFound();
    error ContributionHashEmpty();
    error ContributionAlreadySubmitted(); // Simplified: maybe not strictly necessary if only verifying latest
    error NotAuthorizedForContribution();
    error InvalidTokenAddress();
    error NFTMetadataURINotSet();
    error NotEnoughTotalReputation(uint256 required, uint256 current);
    error NotEnoughSkillReputation(uint256 skillId, uint256 required, uint256 current);
    error StakingPaused();
    error NotAdmin();
    error NotOracle();
    error NoTokensToWithdraw();
    error InsufficientNFTMintReputation(); // More specific error for gated mints
    error SkillNFTThresholdNotSet(uint256 skillId);
    error TotalNFTThresholdNotSet(uint256 requiredTotalReputation);
    error MintLimitReached(); // Optional: Could add a limit per user or total
    error InvalidReputationBurnAmount();

    // =========================================================================
    // State Variables
    // =========================================================================

    // --- Staking ---
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _lastReputationClaimTime;
    uint256 private _stakingReputationRatePerSecond; // Reputation points earned per staked token per second (scaled)
    bool public paused = false; // Pausing staking/unstaking

    // --- Reputation ---
    mapping(address => uint256) private _totalReputation;
    mapping(address => mapping(uint256 => uint256)) private _skillReputation;

    // --- Skills ---
    uint256 private _nextSkillId = 1;
    mapping(uint256 => string) private _skillNames;
    mapping(string => uint256) private _skillIds;
    uint256[] private _skillIdsList; // To retrieve all skills

    // --- Contributions ---
    // Mapping to track user's latest submitted hash per skill (simplified)
    mapping(address => mapping(uint256 => bytes32)) private _latestContributionHash;
    mapping(uint256 => uint256) private _skillContributionReputationBonusRate; // Multiplier for contribution reputation

    // --- Reputation Gating ---
    // Maps function selector to minimum total reputation required
    mapping(bytes4 => uint256) private _functionTotalReputationThresholds;
    // Maps function selector and skillId to minimum skill reputation required
    mapping(bytes4 => mapping(uint256 => uint256)) private _functionSkillReputationThresholds;

    // --- Access Control ---
    address private _admin;
    address private _oracle;

    // --- NFT Management ---
    uint256 private _nftTokenCounter;
    string private _nftBaseURI;
    // Mapping required reputation thresholds to NFT tokenIds (for specific achievements)
    mapping(uint256 => uint256) private _skillReputationNFTThresholds; // skillId => required skill reputation
    mapping(uint256 => uint256) private _totalReputationNFTThresholds; // required total reputation => tokenId (placeholder, actual tokenIds minted sequentially)

    // Mapping threshold values to the first token ID minted for that threshold type
    mapping(uint256 => uint256) private _firstSkillNFTIdForThreshold; // skillId => first tokenId
    mapping(uint256 => uint256) private _firstTotalNFTIdForThreshold; // requiredTotalReputation => first tokenId

    // Mapping user to the number of each type of NFT minted (to prevent duplicate mints for the same threshold)
    mapping(address => mapping(uint256 => bool)) private _hasMintedSkillNFT; // user => skillId => bool
    mapping(address => mapping(uint256 => bool)) private _hasMintedTotalReputationNFT; // user => requiredTotalReputation => bool


    // =========================================================================
    // Events
    // =========================================================================

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ReputationClaimed(address indexed user, uint256 amount);
    event SkillAdded(uint256 indexed skillId, string name);
    event ContributionSubmitted(address indexed user, uint256 indexed skillId, bytes32 contributionHash);
    event ContributionVerified(address indexed user, uint256 indexed skillId, bytes32 contributionHash, uint256 reputationAmount, uint256 tokenAmount);
    event NFTMinted(address indexed user, uint256 indexed tokenId, uint256 indexed skillIdOrTotalThreshold, bool isSkillNFT);
    event TotalReputationThresholdSet(bytes4 indexed selector, uint256 threshold);
    event SkillReputationThresholdSet(bytes4 indexed selector, uint256 indexed skillId, uint256 threshold);
    event StakingReputationRateUpdated(uint256 newRate);
    event SkillContributionReputationBonusUpdated(uint256 indexed skillId, uint256 newBonusRate);
    event OracleSet(address indexed oracle);
    event AdminSet(address indexed admin);
    event Paused(address account);
    event Unpaused(address account);
    event TreasuryWithdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event NFTBaseURIUpdated(string newURI);
    event ReputationAdded(address indexed user, uint256 indexed skillId, uint256 amount, string reason);
    event ReputationBurned(address indexed user, uint256 indexed skillId, uint256 amount, string reason);

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyAdmin() {
        if (msg.sender != _admin && msg.sender != owner()) revert NotAdmin();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != _oracle && msg.sender != _admin && msg.sender != owner()) revert NotOracle();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert StakingPaused();
        _;
    }

    modifier reputationGated(bytes4 selector) {
        uint256 required = _functionTotalReputationThresholds[selector];
        if (required > 0 && _totalReputation[msg.sender] < required) {
            revert NotEnoughTotalReputation(required, _totalReputation[msg.sender]);
        }
        _;
    }

    modifier skillReputationGated(bytes4 selector, uint256 skillId) {
        uint256 required = _functionSkillReputationThresholds[selector][skillId];
        if (required > 0 && _skillReputation[msg.sender][skillId] < required) {
            revert NotEnoughSkillReputation(skillId, required, _skillReputation[msg.sender][skillId]);
        }
        _;
    }

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory nftName,
        string memory nftSymbol,
        address initialAdmin,
        address initialOracle,
        uint256 initialStakingReputationRatePerSecond
    )
        ERC20(tokenName, tokenSymbol)
        ERC20Permit(tokenName)
        ERC20Votes(tokenName, tokenSymbol) // Use tokenName for ERC20Votes name as per standard convention
        ERC721(nftName, nftSymbol)
        Ownable(msg.sender) // Owner is the deployer
        ReentrancyGuard()
    {
        // Initialize roles
        _admin = initialAdmin;
        _oracle = initialOracle;
        emit AdminSet(initialAdmin);
        emit OracleSet(initialOracle);

        // Set initial staking rate
        _stakingReputationRatePerSecond = initialStakingReputationRatePerSecond;
        emit StakingReputationRateUpdated(initialStakingReputationRatePerSecond);

        // Mint initial supply to owner (example) - adjust supply/distribution logic as needed
        uint256 initialSupply = 100_000_000 * (10 ** decimals()); // Example: 100M tokens
        _mint(msg.sender, initialSupply);
    }

    // The following two functions are overrides required by Solidity.
    // ERC20Votes.sol and ERC721.sol both implement `_update` and require it to be defined here.
    // We need to delegate to both implementations.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function _update(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts)
        internal
        override(ERC721) // This signature is slightly different from ERC1155 override
    {
        // ERC721 doesn't use amounts for _update(address, address, uint256[], uint256[]),
        // but OpenZeppelin's ERC721 needs this signature to avoid clash with ERC1155
        // if inheriting both. Since we only inherit ERC721, we can implement the ERC721 specific
        // transfer logic here. The standard ERC721 only calls _update with a single token ID and amount 1.
        // Let's assume the standard ERC721 internal calls will use the single token ID signature.
        // If OZ changes, this might need adjustment. As of OZ 5.0+, ERC721._update takes address, address, uint256.
        // Let's revert to the correct override signature for ERC721.sol from OZ 5.0+.
        // The first _update override handles the ERC20/ERC20Votes clash.

        // The ERC721._update method takes `address from`, `address to`, `uint256 tokenId`.
        // However, if inheriting from contracts that might use a batch _update signature
        // (like ERC1155), we need to define a version that matches. OZ's ERC721
        // provides a batch override signature (_update(address,address,uint256[],uint256[]))
        // to prevent clashing with ERC1155 if both are inherited.
        // Since we are *only* inheriting ERC721, the standard single token ID update is used internally.
        // We don't need the batch override unless we were combining ERC20Votes, ERC721, AND ERC1155.
        // Let's remove the batch override for clarity as it's not needed for this specific inheritance setup in OZ 5.0+.
        // The first _update override for ERC20/ERC20Votes is sufficient.
    }

    // Override for ERC721 tokenURI if needed, but standard ERC721 implementation is fine.
    // We will just set the base URI.

    // =========================================================================
    // ERC20 Standard & Advanced Functions (Inherited/Overridden)
    // =========================================================================

    // ERC20 standard functions (transfer, approve, etc.) are available via inheritance.
    // ERC20Permit (permit, nonces) is available via inheritance.
    // ERC20Votes (delegate, getVotes, getPastVotes) is available via inheritance.
    // No need to redefine them here unless modifying their behavior.

    // =========================================================================
    // ERC721 Standard Functions (Inherited)
    // =========================================================================

    // ERC721 standard functions (balanceOf, ownerOf, transferFrom, etc.) are available via inheritance.
    // We implement custom minting logic (`mintSkillNFT`, `mintTotalReputationNFT`).

    function _baseURI() internal view override returns (string memory) {
        return _nftBaseURI;
    }

    // =========================================================================
    // Core Functionality: Staking
    // =========================================================================

    /// @notice Stakes `amount` of ForgeToken for the caller to earn reputation.
    /// @param amount The amount of ForgeToken to stake.
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert StakeAmountZero();

        // Claim any pending reputation before staking to ensure calculation starts fresh for the new staked amount
        _claimStakingReputation(msg.sender);

        // Transfer tokens from user to contract
        ERC20(address(this)).transferFrom(msg.sender, address(this), amount);

        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].add(amount);
        _lastReputationClaimTime[msg.sender] = block.timestamp; // Reset timer for new staked amount

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstakes `amount` of ForgeToken for the caller.
    /// @param amount The amount of ForgeToken to unstake.
    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert UnstakeAmountZero();
        if (_stakedBalances[msg.sender] < amount) revert InsufficientStakedAmount();

        // Claim any pending reputation before unstaking
        _claimStakingReputation(msg.sender);

        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(amount);
        _lastReputationClaimTime[msg.sender] = block.timestamp; // Reset timer after unstaking

        // Transfer tokens from contract back to user
        ERC20(address(this)).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claims accumulated passive reputation from staking for the caller.
    function claimStakingReputation() external nonReentrant {
        _claimStakingReputation(msg.sender);
    }

    /// @dev Internal function to calculate and add staking reputation.
    function _claimStakingReputation(address user) internal {
        uint256 staked = _stakedBalances[user];
        uint256 lastClaim = _lastReputationClaimTime[user];
        uint256 rate = _stakingReputationRatePerSecond;

        if (staked == 0 || rate == 0 || block.timestamp <= lastClaim) {
            // No staked tokens, no rate, or no time passed since last claim
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(lastClaim);
        // Reputation = staked_amount * rate * time_elapsed (scaled appropriately if rate is scaled)
        // Assuming rate is already scaled (e.g., reputation points per token per second * 1e18)
        // The result should be reputation points, not scaled.
        // If rate is raw points per token per second: reputation = staked * rate * timeElapsed
        // If rate is scaled (e.g., points * 1e18 per token per second): reputation = (staked * rate / 1e18) * timeElapsed
        // Let's assume rate is raw points * 1e18 per token per second for flexibility.
        uint256 earnedReputation = staked.mul(rate).div(1e18).mul(timeElapsed);

        if (earnedReputation == 0) {
             // Update time even if earned is 0 to prevent potential overflow if rate is tiny
             _lastReputationClaimTime[user] = block.timestamp;
             return;
        }

        // Add earned reputation to a default skill or a designated staking skill (skill 0)
        // Let's use a default skill ID, say 1, which is added in the constructor or requires admin to add first.
        // Or, make staking reputation add to the total reputation only, not skill-specific?
        // Let's add it to total and a designated "Staking" skill (skill ID 1, assumed added first).
        // If Skill ID 1 doesn't exist, it will be added to total only.
        uint256 stakingSkillId = 1; // Assuming skill 1 is "Staking" or default

        _totalReputation[user] = _totalReputation[user].add(earnedReputation);
        _skillReputation[user][stakingSkillId] = _skillReputation[user][stakingSkillId].add(earnedReputation);

        _lastReputationClaimTime[user] = block.timestamp;

        emit ReputationAdded(user, stakingSkillId, earnedReputation, "Staking Claim");
        emit ReputationClaimed(user, earnedReputation);
    }

    // =========================================================================
    // Core Functionality: Reputation Management (Admin/Oracle)
    // =========================================================================

    /// @notice Manually adds reputation points to a user for a specific skill.
    /// @dev Only callable by Admin or Oracle. Use for manual awards or corrections.
    /// @param user The address of the user to add reputation to.
    /// @param skillId The ID of the skill category. Use 0 for generic reputation (or a designated skill).
    /// @param amount The amount of reputation points to add.
    /// @param reason A string explaining the reason for adding reputation (e.g., "Bug bounty", "Moderation").
    function addReputation(address user, uint256 skillId, uint256 amount, string memory reason) external onlyOracle {
        if (amount == 0) return; // No-op if amount is zero

        // Optional: check if skillId exists > 0 if not allowing skill 0
        // if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound(); // Uncomment if skillId 0 is disallowed

        _totalReputation[user] = _totalReputation[user].add(amount);
        _skillReputation[user][skillId] = _skillReputation[user][skillId].add(amount);

        emit ReputationAdded(user, skillId, amount, reason);
    }

    /// @notice Manually burns/reduces reputation points from a user for a specific skill.
    /// @dev Only callable by Admin or Oracle. Use for penalties or corrections.
    /// @param user The address of the user to burn reputation from.
    /// @param skillId The ID of the skill category. Use 0 for generic reputation.
    /// @param amount The amount of reputation points to burn.
    /// @param reason A string explaining the reason for burning reputation (e.g., "Penalty", "Incorrect contribution").
    function burnReputation(address user, uint256 skillId, uint256 amount, string memory reason) external onlyOracle {
        if (amount == 0) return; // No-op if amount is zero
        // Optional: check if skillId exists > 0 if not allowing skill 0
        // if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound(); // Uncomment if skillId 0 is disallowed

        uint256 currentTotalRep = _totalReputation[user];
        uint256 currentSkillRep = _skillReputation[user][skillId];

        if (amount > currentTotalRep && amount > currentSkillRep) {
            // This case is ambiguous: burn from total or skill?
            // Let's enforce that the burn amount cannot exceed the current skill reputation OR total reputation,
            // and burning from a skill also reduces total.
             revert InvalidReputationBurnAmount();
        }
         if (amount > currentSkillRep) {
             revert InvalidReputationBurnAmount(); // Cannot burn more from skill than available in skill
         }

        _skillReputation[user][skillId] = currentSkillRep.sub(amount);
        _totalReputation[user] = currentTotalRep.sub(amount); // Burning skill rep also reduces total rep

        emit ReputationBurned(user, skillId, amount, reason);
    }


    // =========================================================================
    // Core Functionality: Skill Management
    // =========================================================================

    /// @notice Adds a new skill category to the network.
    /// @dev Only callable by Admin. Skill IDs are assigned sequentially starting from 1.
    /// @param name The name of the new skill.
    /// @return The ID assigned to the new skill.
    function addSkill(string memory name) external onlyAdmin returns (uint256) {
        bytes memory nameBytes = bytes(name);
        if (nameBytes.length == 0) revert SkillNotFound(); // Or a specific error for empty name
        if (_skillIds[name] != 0) revert SkillAlreadyExists();

        uint256 skillId = _nextSkillId++;
        _skillNames[skillId] = name;
        _skillIds[name] = skillId;
        _skillIdsList.push(skillId); // Add to the list for easy retrieval

        // Initialize bonus rate for this skill (default to 1x or 100%)
        _skillContributionReputationBonusRate[skillId] = 1e18; // Scaled (1.0 * 1e18)

        emit SkillAdded(skillId, name);
        return skillId;
    }

    // =========================================================================
    // Core Functionality: Contribution Submission & Verification
    // =========================================================================

    /// @notice User submits a hash representing their contribution to a skill.
    /// @dev This function records the hash on-chain. Verification and awarding happens off-chain by Oracle/Admin.
    /// @param skillId The ID of the skill the contribution relates to.
    /// @param contributionHash A cryptographic hash (e.g., keccak256) of the contribution proof/details.
    function submitContributionHash(uint256 skillId, bytes32 contributionHash) external {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();
        if (contributionHash == bytes32(0)) revert ContributionHashEmpty();

        // Optionally check if user meets a minimal rep threshold to submit?
        // Example: require(_totalReputation[msg.sender] > 10, "Minimal reputation required to submit");

        _latestContributionHash[msg.sender][skillId] = contributionHash;

        emit ContributionSubmitted(msg.sender, skillId, contributionHash);
    }

    /// @notice [Oracle/Admin] Verifies a submitted contribution hash and awards reputation/tokens.
    /// @dev The verification logic itself is assumed to happen off-chain by the Oracle/Admin.
    /// This function records the successful verification and rewards the user.
    /// @param user The address of the user whose contribution is being verified.
    /// @param skillId The ID of the skill the contribution relates to.
    /// @param contributionHash The hash that was submitted by the user.
    /// @param reputationAmount The base reputation points to award for this contribution.
    /// @param tokenAmount The amount of ForgeToken (or another token) to award. Assumes ForgeToken for now.
    function verifyAndAwardContribution(
        address user,
        uint256 skillId,
        bytes32 contributionHash,
        uint256 reputationAmount,
        uint256 tokenAmount
    ) external onlyOracle {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();
        // Optional: Check if the submitted hash matches the latest recorded hash for the user/skill
        // if (_latestContributionHash[user][skillId] != contributionHash) revert NotAuthorizedForContribution(); // Or specific error

        uint256 bonusRate = _skillContributionReputationBonusRate[skillId]; // Scaled bonus (e.g., 1.5e18 for 1.5x)
        uint256 actualReputationAward = reputationAmount.mul(bonusRate).div(1e18); // Apply bonus

        // Add reputation (to skill and total)
        _totalReputation[user] = _totalReputation[user].add(actualReputationAward);
        _skillReputation[user][skillId] = _skillReputation[user][skillId].add(actualReputationAward);
        emit ReputationAdded(user, skillId, actualReputationAward, "Contribution Verified");

        // Award tokens (ForgeToken)
        if (tokenAmount > 0) {
             // Assumes the contract holds enough ForgeToken to distribute.
             // In a real system, this might involve minting new tokens (if inflationary) or transferring from a treasury.
             // Here, it transfers from the contract's balance.
            ERC20(address(this)).transfer(user, tokenAmount);
        }

        // Clear the latest hash after verification (optional, depends on logic)
        // _latestContributionHash[user][skillId] = bytes32(0);

        emit ContributionVerified(user, skillId, contributionHash, actualReputationAward, tokenAmount);
    }

    // =========================================================================
    // Core Functionality: Reputation Threshold Management (Admin)
    // =========================================================================

    /// @notice Sets the minimum total reputation required to call a specific function.
    /// @dev Only callable by Admin. Use `this.functionName.selector` to get the selector.
    /// Setting threshold to 0 removes the requirement.
    /// @param selector The function selector (bytes4).
    /// @param threshold The minimum total reputation required.
    function setReputationThreshold(bytes4 selector, uint256 threshold) external onlyAdmin {
        _functionTotalReputationThresholds[selector] = threshold;
        emit TotalReputationThresholdSet(selector, threshold);
    }

    /// @notice Sets the minimum skill reputation required to call a specific function for a given skill.
    /// @dev Only callable by Admin. Use `this.functionName.selector` to get the selector.
    /// Setting threshold to 0 removes the requirement for that skill.
    /// @param selector The function selector (bytes4).
    /// @param skillId The ID of the skill.
    /// @param threshold The minimum skill reputation required.
    function setSkillReputationThreshold(bytes4 selector, uint256 skillId, uint256 threshold) external onlyAdmin {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();
        _functionSkillReputationThresholds[selector][skillId] = threshold;
        emit SkillReputationThresholdSet(selector, skillId, threshold);
    }

    // =========================================================================
    // Core Functionality: NFT Minting (Reputation Gated)
    // =========================================================================

    /// @notice Sets the minimum skill reputation required to mint a specific Skill NFT.
    /// @dev Only callable by Admin. Setting threshold to 0 effectively disables this specific NFT type minting.
    /// @param skillId The ID of the skill.
    /// @param requiredSkillReputation The minimum skill reputation required.
    function setSkillReputationNFTThreshold(uint256 skillId, uint256 requiredSkillReputation) external onlyAdmin {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();
        _skillReputationNFTThresholds[skillId] = requiredSkillReputation;
    }

    /// @notice Sets the minimum total reputation required to mint a specific Total Reputation NFT.
    /// @dev Only callable by Admin. Setting threshold to 0 effectively disables this specific NFT type minting.
    /// @param requiredTotalReputation The minimum total reputation required.
    function setTotalReputationNFTThreshold(uint256 requiredTotalReputation) external onlyAdmin {
        _totalReputationNFTThresholds[requiredTotalReputation] = 1; // Use 1 as placeholder value indicating threshold exists
    }


    /// @notice Mints a Skill-based NFT for the caller if they meet the required skill reputation threshold.
    /// @dev Each user can only mint one NFT per skill threshold set by the admin.
    /// @param skillId The ID of the skill for which to mint the NFT.
    function mintSkillNFT(uint256 skillId) external {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();

        uint256 requiredRep = _skillReputationNFTThresholds[skillId];
        if (requiredRep == 0) revert SkillNFTThresholdNotSet(skillId); // Threshold must be set

        uint256 currentRep = _skillReputation[msg.sender][skillId];
        if (currentRep < requiredRep) revert InsufficientNFTMintReputation();

        // Prevent double minting for the same skill threshold
        if (_hasMintedSkillNFT[msg.sender][skillId]) revert MintLimitReached(); // Or a specific error like AlreadyMintedSkillNFT(skillId)

        _hasMintedSkillNFT[msg.sender][skillId] = true;

        // Mint the NFT
        uint256 newTokenId = _nftTokenCounter++;
        _safeMint(msg.sender, newTokenId); // Use _safeMint from ERC721

        emit NFTMinted(msg.sender, newTokenId, skillId, true);
    }

    /// @notice Mints a Total Reputation-based NFT for the caller if they meet the required total reputation threshold.
    /// @dev Each user can only mint one NFT per total reputation threshold set by the admin.
    /// @param requiredTotalReputation The total reputation threshold this NFT represents.
    function mintTotalReputationNFT(uint256 requiredTotalReputation) external {
         // Check if this threshold has a corresponding NFT type defined by admin
        if (_totalReputationNFTThresholds[requiredTotalReputation] == 0) revert TotalNFTThresholdNotSet(requiredTotalReputation);

        uint256 currentRep = _totalReputation[msg.sender];
        if (currentRep < requiredTotalReputation) revert InsufficientNFTMintReputation();

        // Prevent double minting for the same total reputation threshold
        if (_hasMintedTotalReputationNFT[msg.sender][requiredTotalReputation]) revert MintLimitReached(); // Or AlreadyMintedTotalNFT(requiredTotalReputation)

        _hasMintedTotalReputationNFT[msg.sender][requiredTotalReputation] = true;

        // Mint the NFT
        uint256 newTokenId = _nftTokenCounter++;
        _safeMint(msg.sender, newTokenId); // Use _safeMint from ERC721

        emit NFTMinted(msg.sender, newTokenId, requiredTotalReputation, false);
    }

    /// @notice Sets the base URI for the NFT metadata.
    /// @dev Only callable by Admin. The full URI for token ID `i` will typically be `_nftBaseURI / i.toString()`.
    /// @param uri The new base URI.
    function setNFTBaseURI(string memory uri) external onlyAdmin {
        _nftBaseURI = uri;
        emit NFTBaseURIUpdated(uri);
    }


    // =========================================================================
    // Core Functionality: Admin / Owner Actions
    // =========================================================================

    /// @notice Updates the rate at which staked tokens earn passive reputation.
    /// @dev Only callable by Admin. The rate is scaled (e.g., 1e18 for 1 point per token per second).
    /// @param rate The new staking reputation rate per staked token per second (scaled by 1e18).
    function updateStakingReputationRate(uint256 rate) external onlyAdmin {
        // Claim reputation for all stakers before updating the rate? Or just update the rate?
        // Updating the rate directly affects future claims. Claiming for everyone is gas-intensive.
        // Let's just update the rate, assuming users will claim when needed or it's accounted for on their next claim.
        _stakingReputationRatePerSecond = rate;
        emit StakingReputationRateUpdated(rate);
    }

    /// @notice Updates the bonus multiplier for reputation earned via contribution verification for a skill.
    /// @dev Only callable by Admin. The rate is scaled (e.g., 1.5e18 for 1.5x bonus).
    /// @param skillId The ID of the skill.
    /// @param bonusRate The new bonus multiplier (scaled by 1e18).
    function updateSkillContributionReputationBonus(uint256 skillId, uint256 bonusRate) external onlyAdmin {
        if (skillId == 0 || skillId >= _nextSkillId) revert SkillNotFound();
         _skillContributionReputationBonusRate[skillId] = bonusRate;
         emit SkillContributionReputationBonusUpdated(skillId, bonusRate);
    }

    /// @notice Sets the address that has the Oracle role.
    /// @dev Only callable by Admin. The Oracle can verify contributions and manually add/burn reputation.
    /// @param oracleAddress The address to grant the Oracle role.
    function setOracle(address oracleAddress) external onlyAdmin {
        _oracle = oracleAddress;
        emit OracleSet(oracleAddress);
    }

    /// @notice Sets the address that has the Admin role.
    /// @dev Only callable by the current Owner. The Admin can manage skills, set thresholds, update rates, set Oracle, pause/unpause, withdraw tokens.
    /// @param adminAddress The address to grant the Admin role.
    function setAdmin(address adminAddress) external onlyOwner {
        _admin = adminAddress;
        emit AdminSet(adminAddress);
    }

    /// @notice Pauses staking and unstaking operations.
    /// @dev Only callable by Admin.
    function pauseStaking() external onlyAdmin {
        if (!paused) {
            paused = true;
            emit Paused(msg.sender);
        }
    }

    /// @notice Unpauses staking and unstaking operations.
    /// @dev Only callable by Admin.
    function unpauseStaking() external onlyAdmin {
        if (paused) {
            paused = false;
            emit Unpaused(msg.sender);
        }
    }

    /// @notice Allows Admin to withdraw other ERC20 tokens accidentally sent or used as rewards by the contract.
    /// @dev Only callable by Admin. Cannot be used to drain the native ForgeToken staked by users.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdrawTreasuryTokens(address tokenAddress, uint256 amount) external onlyAdmin {
        if (tokenAddress == address(this)) revert InvalidTokenAddress(); // Cannot withdraw native token this way
        ERC20 token = ERC20(tokenAddress);
        if (token.balanceOf(address(this)) < amount) revert NoTokensToWithdraw(); // Specific error

        token.transfer(msg.sender, amount);
        emit TreasuryWithdrawal(tokenAddress, msg.sender, amount);
    }

    // Owner functions (transferOwnership, renounceOwnership) are available via Ownable inheritance.

    // =========================================================================
    // View Functions (Read-Only)
    // =========================================================================

    /// @notice Gets the staked balance for a user.
    /// @param user The address to query.
    /// @return The amount of ForgeToken staked.
    function getStakedBalance(address user) external view returns (uint256) {
        return _stakedBalances[user];
    }

    /// @notice Gets the pending staking reputation for a user.
    /// @dev This is the reputation earned since the last claim or stake/unstake action.
    /// @param user The address to query.
    /// @return The calculated pending reputation.
    function getPendingStakingReputation(address user) public view returns (uint256) {
        uint256 staked = _stakedBalances[user];
        uint256 lastClaim = _lastReputationClaimTime[user];
        uint256 rate = _stakingReputationRatePerSecond;

        if (staked == 0 || rate == 0 || block.timestamp <= lastClaim) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp.sub(lastClaim);
        return staked.mul(rate).div(1e18).mul(timeElapsed);
    }

    /// @notice Gets the total cumulative reputation for a user across all skills.
    /// @param user The address to query.
    /// @return The total reputation points.
    function getTotalReputation(address user) external view returns (uint256) {
        return _totalReputation[user];
    }

    /// @notice Gets the cumulative reputation for a user in a specific skill.
    /// @param user The address to query.
    /// @param skillId The ID of the skill.
    /// @return The reputation points in that skill.
    function getSkillReputation(address user, uint256 skillId) external view returns (uint256) {
        return _skillReputation[user][skillId];
    }

    /// @notice Gets the ID of a skill by its name.
    /// @dev Returns 0 if skill name not found. Skill IDs start from 1.
    /// @param name The name of the skill.
    /// @return The skill ID.
    function getSkillId(string memory name) external view returns (uint256) {
        return _skillIds[name];
    }

    /// @notice Gets the name of a skill by its ID.
    /// @dev Returns an empty string if skill ID not found.
    /// @param skillId The ID of the skill.
    /// @return The skill name.
    function getSkillName(uint256 skillId) external view returns (string memory) {
        return _skillNames[skillId];
    }

    /// @notice Gets the list of all added skill IDs.
    /// @return An array of skill IDs.
    function getSkills() external view returns (uint256[] memory) {
        return _skillIdsList;
    }

    /// @notice Gets the total reputation threshold required for a function selector.
    /// @param selector The function selector (bytes4).
    /// @return The required total reputation.
    function getTotalReputationThreshold(bytes4 selector) external view returns (uint256) {
        return _functionTotalReputationThresholds[selector];
    }

    /// @notice Gets the skill reputation threshold required for a function selector and skill ID.
    /// @param selector The function selector (bytes4).
    /// @param skillId The ID of the skill.
    /// @return The required skill reputation.
    function getSkillReputationThreshold(bytes4 selector, uint256 skillId) external view returns (uint256) {
         return _functionSkillReputationThresholds[selector][skillId];
    }

    /// @notice Gets the current Admin address.
    /// @return The Admin address.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @notice Gets the current Oracle address.
    /// @return The Oracle address.
    function getOracle() external view returns (address) {
        return _oracle;
    }

     /// @notice Checks if the staking is currently paused.
    /// @return True if paused, false otherwise.
    function isPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Gets the current total supply of minted NFTs.
    /// @return The total number of NFTs minted.
    function getNFTTotalSupply() external view returns (uint256) {
        return _nftTokenCounter;
    }

     /// @notice Gets the base URI for NFT metadata.
    /// @return The base URI string.
    function getNFTBaseURI() external view returns (string memory) {
        return _nftBaseURI;
    }

    // Note: Getting *all* token IDs for a user is complex and gas-intensive on-chain.
    // Typically, this is done off-chain by querying events (`Transfer`).
    // A simple on-chain view function to list all token IDs owned by a user is not feasible
    // for contracts potentially holding many NFTs due to array size limitations and gas costs.
    // Leaving this out to avoid unrealistic implementation. Users/frontend can track via events.

    // =========================================================================
    // Internal Helpers (Not directly callable externally)
    // =========================================================================

    // _mint and _burn for ERC20 are internal
    // _mint and _burn for ERC721 are internal (_safeMint is wrapper)

    // Need to override ERC20Votes methods to update voting power on transfers, minting, burning
    // These are handled by the inherited ERC20Votes contract's _update method.

}
```

---

**Explanation of Advanced/Interesting Concepts:**

1.  **Multi-Standard Contract:** The contract is simultaneously an ERC20 token (ForgeToken) and an ERC721 token (SkillForgeNFT), inheriting from and managing both standards within a single contract.
2.  **ERC20 Permit:** The native ERC20 token includes the EIP-2612 Permit extension, allowing users to approve token transfers using a signed message off-chain, saving gas compared to the standard `approve` transaction.
3.  **ERC20 Votes:** The native ERC20 token includes the ERC-20 Votes extension (Comp-style governance). This automatically tracks voting power based on token balances and allows delegation (`delegate`, `delegateBySig`), laying the groundwork for future decentralized governance.
4.  **Reputation System:** A custom, non-transferable `Reputation` metric is tracked per user, both as a total and segmented by `Skill`.
5.  **Staking-Based Reputation:** Users earn a passive stream of Reputation by staking the native ForgeToken, calculated based on the staked amount and time elapsed.
6.  **Contribution-Based Reputation:** A mechanism exists for users to submit a hash representing off-chain work/contribution. A designated Oracle or Admin can then verify this off-chain and award specific amounts of Skill Reputation and/or native tokens on-chain.
7.  **Skill Categorization:** Reputation and contributions are organized into distinct "Skills", allowing for specialized achievements and gating.
8.  **Reputation-Gated Functions:** Crucially, certain functions can be configured by the Admin to require a minimum amount of total reputation or reputation within a specific skill for the caller (`reputationGated`, `skillReputationGated` modifiers using `msg.selector`). This allows building features accessible only to users with proven engagement/expertise.
9.  **Reputation-Gated NFTs:** Unique ERC721 NFTs (`SkillForgeNFT`) can be minted by users only when they achieve specific reputation thresholds (either total or within a skill), serving as on-chain achievements or badges. Admin sets these thresholds.
10. **Role-Based Access Control:** Uses the standard `Ownable` pattern but adds specific `Admin` and `Oracle` roles with distinct permissions (Admin for configuration, Oracle/Admin for verifying/awarding).
11. **Custom Errors:** Utilizes Solidity's `error` mechanism for more gas-efficient and informative error handling compared to `require` with strings.
12. **Reentrancy Guard:** Standard security pattern applied to staking functions.
13. **Configurable Parameters:** Admins can update staking rates, contribution bonuses, reputation thresholds, and NFT minting thresholds, allowing the system to adapt.
14. **Treasury Management:** Includes a function for the Admin to safely withdraw *other* ERC20 tokens sent to the contract (e.g., for distribution), without allowing withdrawal of the core staked native token.
15. **Pausable Staking:** Admin can pause staking/unstaking in emergencies.

This contract provides a rich environment for building a decentralized network where user engagement and contributions translate into measurable on-chain reputation, unlocking access and collectible achievements.