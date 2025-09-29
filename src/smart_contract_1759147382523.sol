The contract outlined below presents a **Decentralized Autonomous Content & Reputation Network (DACRN)**. This system integrates concepts from SocialFi, DAO governance, Dynamic NFTs, and token-curated registries, all powered by its native `DACR` token.

**Core Idea:** Users stake `DACR` tokens to gain reputation and publish content as NFTs. Content engagement, moderation, and staking dynamically influence a user's reputation, which in turn grants governance power, content visibility, and access to exclusive features. The system is designed to incentivize quality content creation, community moderation, and active participation.

---

### **Contract Name: DACR_Network_Core**

**Outline & Function Summary:**

This contract manages the core functionalities of the DACRN, including its native token (`DACR`), user profiles, content NFTs, reputation system, and basic governance.

**I. Native Token Management (DACR Token - ERC20-like with staking features)**
1.  **`constructor(string memory name, string memory symbol, uint256 initialSupply)`**: Initializes the DACR token, assigns initial supply to the deployer, and sets up initial platform parameters.
2.  **`transfer(address recipient, uint256 amount)`**: Transfers DACR tokens between users.
3.  **`approve(address spender, uint256 amount)`**: Allows a spender to withdraw a set amount of tokens from the caller's account.
4.  **`transferFrom(address sender, address recipient, uint256 amount)`**: Transfers tokens from one account to another using the allowance mechanism.
5.  **`balanceOf(address account)`**: Returns the token balance of an account.
6.  **`stakeDACR(uint256 amount)`**: Allows a user to stake DACR tokens, contributing to their reputation score and content visibility.
7.  **`unstakeDACR(uint256 amount)`**: Allows a user to retrieve staked DACR tokens.
8.  **`getAvailableStake(address user)`**: Returns the currently staked amount for a specific user.

**II. User Profiles & Reputation System (Dynamic SBT-like & NFTs)**
9.  **`registerProfile(string memory _metadataURI)`**: Allows a user to register their profile on the network, potentially minting a Soulbound Token (SBT) or initial reputation NFT.
10. **`updateProfileMetadata(string memory _newMetadataURI)`**: Updates the URI for a user's profile, allowing for dynamic changes.
11. **`getProfileDetails(address user)`**: Retrieves the current metadata URI and reputation score for a user.
12. **`_calculateReputationScore(address user)` (Internal/View Helper)**: Calculates a user's reputation based on staked tokens, content engagement, moderation history, and activity. (Not a direct external function, but integral to the system).
13. **`updateReputationBadgeNFT(address user)`**: Triggers an update to a user's dynamic Reputation Badge NFT metadata based on their current reputation score, reflecting their tier. (Simulated/conceptual dynamic NFT update).
14. **`getReputationScore(address user)`**: Returns the current, calculated reputation score for a user.

**III. Content Management (ERC721 ContentNFTs)**
15. **`publishContent(string memory _contentURI, string memory _category, uint256 _requiredStake)`**: Mints a new `ContentNFT` representing a piece of content. Requires a minimum DACR stake from the creator, which locks the tokens.
16. **`retireContent(uint256 _contentId)`**: Allows the creator to burn their `ContentNFT`, reclaiming the initial stake and removing the content from active visibility.
17. **`upvoteContent(uint256 _contentId)`**: Registers an upvote for content. Increases content's engagement score and can boost creator's reputation. Requires a small DACR fee or stake.
18. **`downvoteContent(uint256 _contentId)`**: Registers a downvote for content. Decreases content's engagement score and may penalize creator's reputation. Requires higher reputation or stake to prevent abuse.
19. **`reportContent(uint256 _contentId, string memory _reason)`**: Allows users to flag content for moderation.
20. **`moderateContent(uint256 _contentId, bool _isApproved, string memory _moderationNote)`**: Designated moderators (or DAO vote) review reported content. Impacts creator and reporter reputation.
21. **`distributeContentRewards(uint256 _contentId)`**: Distributes a portion of protocol fees or treasury funds to content creators based on their content's engagement score, triggered periodically or manually.
22. **`getContentDetails(uint256 _contentId)`**: Retrieves all relevant details for a specific content NFT (URI, creator, engagement score, moderation status).

**IV. Community & Governance (Lightweight DAO-like)**
23. **`createProposal(string memory _description, bytes memory _calldata, address _targetContract)`**: Allows users with sufficient reputation/stake to propose changes to contract parameters, upgrades, or treasury spending.
24. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Users vote on proposals using their weighted reputation and staked DACR.
25. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it has passed the voting period and threshold.
26. **`setPlatformFeePercentage(uint256 _newFee)`**: Governance-approved function to adjust the platform fee percentage on certain transactions (e.g., upvotes).
27. **`withdrawTreasuryFunds(address _recipient, uint256 _amount)`**: Governance-approved function to withdraw funds from the protocol treasury.
28. **`grantModeratorRole(address _newModerator)`**: Governance-approved function to assign the `MODERATOR_ROLE` to a user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // For role management
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces for our custom tokens (simplified for this example)
interface IDACRToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IContentNFT {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function burn(uint256 tokenId) external;
    function setTokenURI(uint256 tokenId, string memory newURI) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 tokenId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}

interface IReputationBadgeNFT {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function setTokenURI(uint256 tokenId, string memory newURI) external;
    function exists(uint256 tokenId) external view returns (bool);
}


contract DACR_Network_Core is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // --- DACR Token Properties (Simplified ERC20-like implementation) ---
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- Staking ---
    mapping(address => uint256) public stakedBalances;

    // --- User Profiles ---
    struct UserProfile {
        string metadataURI;
        uint256 reputationScore;
        uint256 lastReputationUpdate; // Timestamp of last reputation update
        uint256 profileSBTId; // Unique ID for their profile NFT/SBT
        bool registered;
    }
    mapping(address => UserProfile) public userProfiles;
    Counters.Counter private _profileSBTIdCounter; // For unique profile NFTs

    // --- Content NFTs ---
    struct Content {
        uint256 contentId;
        address creator;
        string contentURI;
        string category;
        uint256 stakeAmount;
        uint256 creationTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        bool moderated;
        bool approvedByModerator;
        string moderationNote;
        uint252 engagementScore; // Derived from upvotes, downvotes, time, etc.
        mapping(address => bool) hasUpvoted;
        mapping(address => bool) hasDownvoted;
    }
    mapping(uint256 => Content) public contents;
    Counters.Counter private _contentIdCounter;

    // --- Reputation Badge NFTs (Dynamic NFTs) ---
    mapping(address => uint256) public userReputationBadgeNFTId; // User's dynamic reputation badge NFT

    // --- Governance ---
    struct Proposal {
        uint256 id;
        string description;
        bytes calldataPayload; // Data to be sent to target contract
        address targetContract; // Contract to call if proposal passes
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public constant MIN_REP_TO_PROPOSE = 500; // Minimum reputation to create a proposal
    uint256 public constant VOTING_PERIOD = 3 days; // How long a proposal is open for voting
    uint224 public constant VOTE_QUORUM_PERCENT = 40; // Percentage of total staked/reputation needed to pass (out of 10000)

    // --- Platform Parameters ---
    uint256 public platformFeePercentage; // e.g., 500 for 5% (500/10000)
    address public treasuryAddress;

    // --- External Contract Addresses (Conceptual, in a real scenario these would be separate deployed contracts) ---
    IERC721 public contentNFTContract; // Address of the actual ContentNFT contract
    IERC721 public reputationBadgeNFTContract; // Address of the actual ReputationBadgeNFT contract
    IERC721 public profileSBTContract; // Address of the actual ProfileSBT contract

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ProfileRegistered(address indexed user, uint256 profileSBTId, string metadataURI);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);
    event ReputationBadgeUpdated(address indexed user, uint256 badgeNFTId, uint256 newReputationScore);
    event ContentPublished(address indexed creator, uint256 contentId, string contentURI, uint256 stakeAmount);
    event ContentRetired(address indexed creator, uint256 contentId);
    event ContentUpvoted(address indexed user, uint256 contentId);
    event ContentDownvoted(address indexed user, uint256 contentId);
    event ContentReported(address indexed reporter, uint256 contentId, string reason);
    event ContentModerated(address indexed moderator, uint256 contentId, bool approved, string note);
    event ContentRewardsDistributed(uint256 contentId, uint256 amountDistributed);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event PlatformFeePercentageSet(uint256 newFee);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyRegisteredUser() {
        require(userProfiles[_msgSender()].registered, "DACR: User not registered");
        _;
    }

    /**
     * @dev Constructor: Initializes the DACR token, assigns initial supply,
     * sets up initial platform parameters, and grants admin role.
     * @param _name Name of the DACR token.
     * @param _symbol Symbol of the DACR token.
     * @param _initialSupply Initial supply of DACR tokens.
     * @param _treasuryAddress Address for the protocol treasury.
     * @param _contentNFT The address of the ContentNFT contract.
     * @param _reputationBadgeNFT The address of the ReputationBadgeNFT contract.
     * @param _profileSBT The address of the ProfileSBT contract.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _treasuryAddress,
        address _contentNFT,
        address _reputationBadgeNFT,
        address _profileSBT
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender()); // Initial deployer is admin
        _grantRole(MODERATOR_ROLE, _msgSender()); // Initial deployer is also a moderator for testing

        name = _name;
        symbol = _symbol;
        _totalSupply = _initialSupply.mul(10**uint256(decimals));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        require(_treasuryAddress != address(0), "DACR: Treasury address cannot be zero");
        treasuryAddress = _treasuryAddress;
        platformFeePercentage = 500; // 5% initially (500/10000)

        // Set external contract addresses (these would be deployed separately)
        require(_contentNFT != address(0), "DACR: ContentNFT contract address cannot be zero");
        require(_reputationBadgeNFT != address(0), "DACR: ReputationBadgeNFT contract address cannot be zero");
        require(_profileSBT != address(0), "DACR: ProfileSBT contract address cannot be zero");
        contentNFTContract = IContentNFT(_contentNFT);
        reputationBadgeNFTContract = IReputationBadgeNFT(_reputationBadgeNFT);
        profileSBTContract = IERC721(_profileSBT); // Use IERC721 as a generic interface for SBTs
    }

    // --- I. Native Token Management (DACR Token - ERC20-like with staking features) ---

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate transaction
     * ordering. One possible solution to mitigate this race condition is to first
     * reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "DACR: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }

    /**
     * @dev Internal function that transfers `amount` of tokens from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "DACR: transfer from the zero address");
        require(recipient != address(0), "DACR: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "DACR: transfer amount exceeds balance");
        
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`'s tokens.
     *
     * Emits an {Approval} event.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "DACR: approve from the zero address");
        require(spender != address(0), "DACR: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Allows a user to stake DACR tokens, contributing to their reputation score and content visibility.
     * @param amount The amount of DACR tokens to stake.
     */
    function stakeDACR(uint256 amount) public onlyRegisteredUser nonReentrant {
        require(amount > 0, "DACR: Cannot stake zero tokens");
        _transfer(_msgSender(), address(this), amount); // Transfer to contract
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(amount);
        _updateReputation(_msgSender(), true); // Update reputation after staking
        emit Staked(_msgSender(), amount);
    }

    /**
     * @dev Allows a user to retrieve staked DACR tokens.
     * @param amount The amount of DACR tokens to unstake.
     */
    function unstakeDACR(uint256 amount) public onlyRegisteredUser nonReentrant {
        require(amount > 0, "DACR: Cannot unstake zero tokens");
        require(stakedBalances[_msgSender()] >= amount, "DACR: Insufficient staked tokens");

        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(amount);
        _transfer(address(this), _msgSender(), amount); // Transfer from contract
        _updateReputation(_msgSender(), true); // Update reputation after unstaking
        emit Unstaked(_msgSender(), amount);
    }

    /**
     * @dev Returns the currently staked amount for a specific user.
     * @param user The address of the user.
     * @return The amount of DACR tokens staked by the user.
     */
    function getAvailableStake(address user) public view returns (uint256) {
        return stakedBalances[user];
    }

    // --- II. User Profiles & Reputation System (Dynamic SBT-like & NFTs) ---

    /**
     * @dev Allows a user to register their profile on the network, minting a Profile SBT.
     * @param _metadataURI The URI for the user's profile metadata.
     */
    function registerProfile(string memory _metadataURI) public nonReentrant {
        require(!userProfiles[_msgSender()].registered, "DACR: User already registered");

        _profileSBTIdCounter.increment();
        uint256 newSBTId = _profileSBTIdCounter.current();
        
        // Mint the Profile SBT (assumes ProfileSBT contract handles unique IDs)
        profileSBTContract.mint(_msgSender(), newSBTId);

        userProfiles[_msgSender()] = UserProfile({
            metadataURI: _metadataURI,
            reputationScore: 100, // Starting reputation
            lastReputationUpdate: block.timestamp,
            profileSBTId: newSBTId,
            registered: true
        });

        // Mint initial reputation badge NFT
        userReputationBadgeNFTId[_msgSender()] = newSBTId; // Reusing SBT ID for simplicity, could be separate counter
        reputationBadgeNFTContract.mint(_msgSender(), newSBTId, _getReputationBadgeURI(100)); // Initial badge
        
        emit ProfileRegistered(_msgSender(), newSBTId, _metadataURI);
    }

    /**
     * @dev Updates the URI for a user's profile metadata.
     * @param _newMetadataURI The new URI for the user's profile.
     */
    function updateProfileMetadata(string memory _newMetadataURI) public onlyRegisteredUser {
        userProfiles[_msgSender()].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(_msgSender(), _newMetadataURI);
    }

    /**
     * @dev Retrieves the current metadata URI and reputation score for a user.
     * @param user The address of the user.
     * @return metadataURI The URI for the user's profile.
     * @return reputationScore The current reputation score of the user.
     * @return profileSBTId The ID of the user's Profile SBT.
     */
    function getProfileDetails(address user) public view returns (string memory metadataURI, uint256 reputationScore, uint256 profileSBTId, bool registered) {
        UserProfile storage profile = userProfiles[user];
        return (profile.metadataURI, profile.reputationScore, profile.profileSBTId, profile.registered);
    }

    /**
     * @dev Internal helper to calculate a user's reputation based on various factors.
     * @param user The address of the user.
     * @return The calculated reputation score.
     */
    function _calculateReputationScore(address user) internal view returns (uint256) {
        if (!userProfiles[user].registered) return 0; // Unregistered users have no reputation

        uint256 baseRep = 100; // Starting reputation
        uint256 stakeFactor = stakedBalances[user].div(100 * (10**uint256(decimals))); // 1 rep per 100 DACR staked
        uint256 contentEngagementFactor = 0; // This would be more complex, summing upvotes/downvotes across content
        // For simplicity, let's just use stake for now. In a real system, you'd iterate/store content stats.

        return baseRep.add(stakeFactor);
    }
    
    /**
     * @dev Internal function to update a user's reputation score and trigger badge update.
     * @param user The address of the user whose reputation is to be updated.
     * @param forceBadgeUpdate If true, forces an update to the reputation badge NFT.
     */
    function _updateReputation(address user, bool forceBadgeUpdate) internal {
        uint256 oldRep = userProfiles[user].reputationScore;
        uint256 newRep = _calculateReputationScore(user);

        if (newRep != oldRep) {
            userProfiles[user].reputationScore = newRep;
            userProfiles[user].lastReputationUpdate = block.timestamp;

            // Trigger dynamic NFT update if score changes meaningfully or forced
            if (forceBadgeUpdate || (newRep / 100 != oldRep / 100)) { // Update badge if tier changes (e.g., every 100 rep points)
                updateReputationBadgeNFT(user);
            }
        }
    }

    /**
     * @dev Triggers an update to a user's dynamic Reputation Badge NFT metadata based on their current reputation score.
     * (Simulates dynamic NFT metadata update by setting a new URI).
     * @param user The address of the user.
     */
    function updateReputationBadgeNFT(address user) public onlyRegisteredUser {
        uint256 currentRep = _calculateReputationScore(user);
        uint256 badgeNFTId = userReputationBadgeNFTId[user];

        if (reputationBadgeNFTContract.exists(badgeNFTId)) {
            reputationBadgeNFTContract.setTokenURI(badgeNFTId, _getReputationBadgeURI(currentRep));
            emit ReputationBadgeUpdated(user, badgeNFTId, currentRep);
        } else {
             // If for some reason the badge NFT doesn't exist (e.g., initial registration flow change), mint it
            userReputationBadgeNFTId[user] = userProfiles[user].profileSBTId; // Reusing SBT ID
            reputationBadgeNFTContract.mint(user, userReputationBadgeNFTId[user], _getReputationBadgeURI(currentRep));
            emit ReputationBadgeUpdated(user, userReputationBadgeNFTId[user], currentRep);
        }
    }

    /**
     * @dev Internal helper to determine the metadata URI for a reputation badge based on score.
     * @param reputationScore The user's current reputation score.
     * @return The URI pointing to the appropriate badge metadata.
     */
    function _getReputationBadgeURI(uint256 reputationScore) internal pure returns (string memory) {
        if (reputationScore >= 1000) return "ipfs://Qmbadge_gold";
        if (reputationScore >= 500) return "ipfs://Qmbadge_silver";
        if (reputationScore >= 200) return "ipfs://Qmbadge_bronze";
        return "ipfs://Qmbadge_basic";
    }

    /**
     * @dev Returns the current, calculated reputation score for a user.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address user) public view returns (uint256) {
        return userProfiles[user].reputationScore;
    }

    // --- III. Content Management (ERC721 ContentNFTs) ---

    /**
     * @dev Mints a new `ContentNFT` representing a piece of content. Requires a minimum DACR stake from the creator.
     * @param _contentURI The URI pointing to the content's metadata.
     * @param _category The category of the content.
     * @param _requiredStake The amount of DACR tokens to stake for this content.
     */
    function publishContent(string memory _contentURI, string memory _category, uint256 _requiredStake) public onlyRegisteredUser nonReentrant {
        require(_requiredStake > 0, "DACR: Content requires a positive stake");
        require(stakedBalances[_msgSender()] >= _requiredStake, "DACR: Insufficient staked tokens for content");

        // "Lock" the required stake by reducing available balance, but it stays staked
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(_requiredStake);
        _transfer(address(this), treasuryAddress, _requiredStake.div(2)); // Half goes to treasury as fee
        
        _contentIdCounter.increment();
        uint256 newContentId = _contentIdCounter.current();

        contents[newContentId] = Content({
            contentId: newContentId,
            creator: _msgSender(),
            contentURI: _contentURI,
            category: _category,
            stakeAmount: _requiredStake,
            creationTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            moderated: false,
            approvedByModerator: false,
            moderationNote: "",
            engagementScore: 0
        });

        // Mint the Content NFT (assumes ContentNFT contract handles unique IDs)
        contentNFTContract.mint(_msgSender(), newContentId, _contentURI);

        emit ContentPublished(_msgSender(), newContentId, _contentURI, _requiredStake);
    }

    /**
     * @dev Allows the creator to burn their `ContentNFT`, reclaiming the initial stake and removing the content.
     * @param _contentId The ID of the content NFT to retire.
     */
    function retireContent(uint256 _contentId) public onlyRegisteredUser nonReentrant {
        Content storage content = contents[_contentId];
        require(content.creator == _msgSender(), "DACR: Only content creator can retire it");
        require(content.contentId != 0, "DACR: Content does not exist");
        
        // Return original stake minus half fee (which went to treasury)
        uint256 returnAmount = content.stakeAmount.div(2); 
        _transfer(address(this), _msgSender(), returnAmount); 
        
        delete contents[_contentId]; // Remove content data
        contentNFTContract.burn(_contentId); // Burn the NFT

        emit ContentRetired(_msgSender(), _contentId);
    }

    /**
     * @dev Registers an upvote for content. Increases content's engagement score and can boost creator's reputation.
     * Requires a small DACR fee which goes to treasury.
     * @param _contentId The ID of the content to upvote.
     */
    function upvoteContent(uint256 _contentId) public onlyRegisteredUser nonReentrant {
        Content storage content = contents[_contentId];
        require(content.contentId != 0, "DACR: Content does not exist");
        require(!content.hasUpvoted[_msgSender()], "DACR: Already upvoted this content");
        require(content.creator != _msgSender(), "DACR: Cannot upvote your own content");

        // Small fee for upvoting (e.g., 0.1 DACR)
        uint256 upvoteFee = 100000000000000000; // 0.1 DACR (with 18 decimals)
        _transfer(_msgSender(), treasuryAddress, upvoteFee);
        
        content.upvotes = content.upvotes.add(1);
        content.hasUpvoted[_msgSender()] = true;
        _updateEngagementScore(_contentId);
        _updateReputation(content.creator, false); // Potentially boost creator rep
        
        emit ContentUpvoted(_msgSender(), _contentId);
    }

    /**
     * @dev Registers a downvote for content. Decreases content's engagement score and may penalize creator's reputation.
     * Requires higher reputation or stake to prevent abuse.
     * @param _contentId The ID of the content to downvote.
     */
    function downvoteContent(uint256 _contentId) public onlyRegisteredUser nonReentrant {
        Content storage content = contents[_contentId];
        require(content.contentId != 0, "DACR: Content does not exist");
        require(!content.hasDownvoted[_msgSender()], "DACR: Already downvoted this content");
        require(content.creator != _msgSender(), "DACR: Cannot downvote your own content");
        require(userProfiles[_msgSender()].reputationScore >= 200, "DACR: Insufficient reputation to downvote");

        // Small fee for downvoting, possibly higher than upvote fee
        uint256 downvoteFee = 200000000000000000; // 0.2 DACR
        _transfer(_msgSender(), treasuryAddress, downvoteFee);

        content.downvotes = content.downvotes.add(1);
        content.hasDownvoted[_msgSender()] = true;
        _updateEngagementScore(_contentId);
        _updateReputation(content.creator, false); // Potentially penalize creator rep
        
        emit ContentDownvoted(_msgSender(), _contentId);
    }
    
    /**
     * @dev Internal function to update the engagement score of content.
     * @param _contentId The ID of the content.
     */
    function _updateEngagementScore(uint256 _contentId) internal {
        Content storage content = contents[_contentId];
        // Simple formula: (upvotes - downvotes) * time_decay_factor
        uint256 score = content.upvotes.sub(content.downvotes);
        uint256 timeElapsed = block.timestamp.sub(content.creationTimestamp);
        // This decay factor is simplified, can be more complex (e.g., logarithmic)
        uint256 decayFactor = (timeElapsed > 1 days) ? 1 : 100; // No decay for first day, then 100x decay
        content.engagementScore = score.div(decayFactor);
    }

    /**
     * @dev Allows users to flag content for moderation.
     * @param _contentId The ID of the content to report.
     * @param _reason The reason for reporting.
     */
    function reportContent(uint256 _contentId, string memory _reason) public onlyRegisteredUser {
        Content storage content = contents[_contentId];
        require(content.contentId != 0, "DACR: Content does not exist");
        // Logic to store reports. For simplicity, just emit event.
        // In a real system, multiple reports could trigger automatic flagging.
        emit ContentReported(_msgSender(), _contentId, _reason);
    }

    /**
     * @dev Designated moderators (or DAO vote) review reported content. Impacts creator and reporter reputation.
     * @param _contentId The ID of the content to moderate.
     * @param _isApproved Whether the content is approved or rejected by the moderator.
     * @param _moderationNote An optional note from the moderator.
     */
    function moderateContent(uint256 _contentId, bool _isApproved, string memory _moderationNote) public onlyRole(MODERATOR_ROLE) nonReentrant {
        Content storage content = contents[_contentId];
        require(content.contentId != 0, "DACR: Content does not exist");
        require(!content.moderated, "DACR: Content already moderated");

        content.moderated = true;
        content.approvedByModerator = _isApproved;
        content.moderationNote = _moderationNote;

        if (!_isApproved) {
            // Penalize creator, potentially reduce engagement score further
            userProfiles[content.creator].reputationScore = userProfiles[content.creator].reputationScore.div(2); // Harsh penalty
            _updateReputation(content.creator, true);
        } else {
            // Potentially reward creator if falsely reported, or if moderation improves it
            // No direct reward here for simplicity.
        }
        
        emit ContentModerated(_msgSender(), _contentId, _isApproved, _moderationNote);
    }

    /**
     * @dev Distributes a portion of protocol fees or treasury funds to content creators based on their content's engagement score.
     * Can be triggered periodically or manually by admin/DAO.
     * @param _contentId The ID of the content for which to distribute rewards.
     */
    function distributeContentRewards(uint256 _contentId) public onlyRole(ADMIN_ROLE) nonReentrant {
        Content storage content = contents[_contentId];
        require(content.contentId != 0, "DACR: Content does not exist");
        require(content.engagementScore > 0, "DACR: No engagement to reward");

        // Simplified reward calculation: 1 DACR per 100 engagement score from treasury
        uint256 rewardAmount = content.engagementScore.div(100); 
        require(rewardAmount > 0, "DACR: Reward amount too small");

        // Transfer from treasury (represented by this contract's balance initially, or a separate treasury)
        // In a real system, the treasuryAddress would hold funds and call this contract to send rewards.
        _transfer(address(this), content.creator, rewardAmount); 
        
        emit ContentRewardsDistributed(_contentId, rewardAmount);
    }

    /**
     * @dev Retrieves all relevant details for a specific content NFT.
     * @param _contentId The ID of the content.
     * @return Content struct details.
     */
    function getContentDetails(uint256 _contentId) public view returns (Content memory) {
        return contents[_contentId];
    }

    // --- IV. Community & Governance (Lightweight DAO-like) ---

    /**
     * @dev Allows users with sufficient reputation/stake to propose changes.
     * @param _description Description of the proposal.
     * @param _calldataPayload The calldata for the target contract function (e.g., `setPlatformFeePercentage`).
     * @param _targetContract The contract address to call if the proposal passes.
     */
    function createProposal(string memory _description, bytes memory _calldataPayload, address _targetContract) public onlyRegisteredUser {
        require(userProfiles[_msgSender()].reputationScore >= MIN_REP_TO_PROPOSE, "DACR: Insufficient reputation to propose");
        require(_targetContract != address(0), "DACR: Target contract cannot be zero address");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _description,
            calldataPayload: _calldataPayload,
            targetContract: _targetContract,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(newProposalId, _msgSender(), _description);
    }

    /**
     * @dev Users vote on proposals using their weighted reputation and staked DACR.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for Yes, False for No.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredUser nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DACR: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "DACR: Voting not started yet");
        require(block.timestamp < proposal.voteEndTime, "DACR: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "DACR: Already voted on this proposal");

        // Voting power based on staked DACR (scaled) + reputation
        uint256 voteWeight = stakedBalances[_msgSender()].div(10**uint256(decimals)).add(userProfiles[_msgSender()].reputationScore.div(10)); // 1 DACR = 1 vote, 10 reputation = 1 vote

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voteWeight);
        } else {
            proposal.noVotes = proposal.noVotes.add(voteWeight);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit Voted(_proposalId, _msgSender(), _support, voteWeight);
    }

    /**
     * @dev Executes a proposal if it has passed the voting period and threshold.
     * Requires the `ADMIN_ROLE` to trigger execution.
     * In a fully decentralized DAO, this would be callable by anyone after the period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyRole(ADMIN_ROLE) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DACR: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "DACR: Voting period not ended");
        require(!proposal.executed, "DACR: Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        require(totalVotes > 0, "DACR: No votes cast for this proposal");

        // Quorum check: requires a minimum percentage of total 'potential' voting power
        // For simplicity, let's use a dynamic quorum based on actual votes cast.
        // In a real DAO, this would be based on total staked DACR or total registered users.
        require(proposal.yesVotes.mul(10000).div(totalVotes) >= VOTE_QUORUM_PERCENT, "DACR: Proposal did not meet quorum");
        
        // Check if majority voted 'yes'
        require(proposal.yesVotes > proposal.noVotes, "DACR: Proposal did not pass majority vote");

        proposal.executed = true;

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
        require(success, "DACR: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Governance-approved function to adjust the platform fee percentage.
     * This function is intended to be called via a successful proposal execution.
     * @param _newFee The new platform fee percentage (e.g., 500 for 5%).
     */
    function setPlatformFeePercentage(uint256 _newFee) public onlyRole(ADMIN_ROLE) {
        require(_newFee <= 1000, "DACR: Fee percentage cannot exceed 10%"); // Max 10%
        platformFeePercentage = _newFee;
        emit PlatformFeePercentageSet(_newFee);
    }

    /**
     * @dev Governance-approved function to withdraw funds from the protocol treasury.
     * This function is intended to be called via a successful proposal execution.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_recipient != address(0), "DACR: Recipient cannot be zero address");
        // For this example, treasury funds are implicitly held by the contract itself.
        // In a real system, the `treasuryAddress` would be a separate contract.
        _transfer(address(this), _recipient, _amount);
        emit TreasuryWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Governance-approved function to assign the `MODERATOR_ROLE` to a user.
     * This function is intended to be called via a successful proposal execution.
     * @param _newModerator The address of the user to grant moderator role.
     */
    function grantModeratorRole(address _newModerator) public onlyRole(ADMIN_ROLE) {
        require(_newModerator != address(0), "DACR: Moderator address cannot be zero");
        _grantRole(MODERATOR_ROLE, _newModerator);
    }
}
```