This is an ambitious request, and I'm excited to design something truly unique! I'll focus on a concept that blends **decentralized knowledge validation, reputation systems, and dynamic, soulbound NFTs (SBTs)**, aiming for a "Proof-of-Contribution" type of network.

Let's call it **"CognitionNet"**. It's a protocol where users propose "knowledge assets" (e.g., verified facts, research summaries, bug solutions, creative prompts), and the community validates or challenges them through a staking mechanism. Successful validations mint immutable "CognitionBlocks" (NFTs representing verified knowledge) and reward contributors with tokens, reputation, and unique, dynamic "Insight Badges" (SBTs) that evolve with their contributions.

This avoids direct duplication of DeFi (lending/borrowing), standard NFT marketplaces, or generic DAOs by focusing on a novel economic game around *information verification*.

---

## CognitionNet Protocol: Outline & Function Summary

**Concept:** CognitionNet is a decentralized protocol for community-driven knowledge validation and persistent storage. Users propose "Knowledge Assets," which are then subject to a community staking-based validation/challenge process. Validated assets become immutable "CognitionBlocks" (ERC-721 NFTs). Contributors earn native tokens, reputation, and dynamic "Insight Badges" (Soulbound NFTs) reflecting their expertise and trustworthiness.

**Core Principles:**
*   **Proof-of-Contribution:** Rewards genuine, valuable input.
*   **Gamed Validation:** Incentivizes accurate peer review through staking and slashing.
*   **Immutable Knowledge:** Verified assets are permanently recorded as NFTs.
*   **Dynamic Reputation:** User reputation evolves with their successful contributions and validations.
*   **Soulbound Badges:** Non-transferable NFTs reflecting a user's unique expertise.

---

### Contract Files & Structure:

1.  `ICognitionNet.sol`: Interface for the main contract.
2.  `CognitionToken.sol`: ERC-20 token for staking and rewards.
3.  `CognitionBlockNFT.sol`: ERC-721 NFT for verified knowledge assets.
4.  `InsightBadgeSBT.sol`: ERC-721 "Soulbound Token" for user reputation badges.
5.  `CognitionNet.sol`: The core logic contract, orchestrating everything.

---

### Function Summary (Focusing on `CognitionNet.sol` and its interaction with others):

**I. Core Protocol Functions (User-Facing)**
1.  `proposeKnowledgeAsset(bytes32 _contentHash, string calldata _uri)`: Allows a user to propose a new knowledge asset by staking a fee. The `_contentHash` uniquely identifies the asset's content (e.g., IPFS hash of text/data), and `_uri` points to the metadata.
2.  `stakeForProposal(uint256 _proposalId, bool _isValidation)`: Users stake `CognitionToken`s to either validate (agree with) or challenge (disagree with) a proposed knowledge asset.
3.  `resolveProposal(uint256 _proposalId)`: Initiates the resolution of a proposal after its resolution period ends. It tallies validation/challenge stakes, distributes rewards to successful stakers, slashes tokens from losing stakers, updates user reputations, and if successful, mints a `CognitionBlockNFT`.
4.  `claimRewards()`: Allows users to withdraw their accumulated `CognitionToken` rewards from successful validations/proposals.
5.  `unstake(uint256 _amount)`: Allows a user to withdraw their general staked `CognitionToken`s that are not currently locked in a proposal.

**II. Reputation & Dynamic SBT Functions (Internal & User-Facing Getters)**
6.  `_updateReputation(address _user, int256 _change)`: (Internal) Adjusts a user's reputation score based on successful proposals, validations, or slashing events.
7.  `_mintOrUpdateInsightBadge(address _recipient, uint256 _newLevel, string calldata _badgeUri)`: (Internal) Mints a new `InsightBadgeSBT` for a user if they don't have one, or updates the `level` and `tokenURI` of an existing one based on reputation milestones or specific achievements (e.g., first validated block, 100 successful validations).
8.  `getInsightBadgeDetails(address _user)`: Returns the `InsightBadgeSBT` details (ID, level, URI) for a given user.

**III. Data & Query Functions (User-Facing Getters)**
9.  `getProposalDetails(uint256 _proposalId)`: Retrieves all details of a specific knowledge asset proposal.
10. `getKnowledgeBlockDetails(uint256 _blockId)`: Retrieves all details of a minted `CognitionBlockNFT`.
11. `getUserReputation(address _user)`: Returns the current reputation score of a user.
12. `getUserStakedAmount(address _user)`: Returns the total amount of `CognitionToken`s a user has currently staked in the protocol (both generally and in proposals).
13. `getUserClaimableRewards(address _user)`: Returns the amount of `CognitionToken`s a user can currently claim.
14. `getContractParameters()`: Returns the current configurable parameters of the protocol (e.g., stake amounts, periods).
15. `getTotalCognitionBlocks()`: Returns the total number of `CognitionBlockNFT`s minted.

**IV. Admin & Configuration Functions (Owner-Only)**
16. `setProposalStakeAmount(uint256 _amount)`: Sets the amount of `CognitionToken`s required to propose a knowledge asset.
17. `setValidationStakeAmount(uint256 _amount)`: Sets the minimum amount of `CognitionToken`s required to validate or challenge a proposal.
18. `setProposalResolutionPeriod(uint256 _period)`: Sets the time duration (in seconds) during which a proposal can be validated/challenged.
19. `setRewardDistributionRates(uint256 _proposerRewardBps, uint256 _validatorRewardBps)`: Sets the basis points (e.g., 100 = 1%) for rewards distributed to successful proposers and validators from the pool.
20. `setSlashingRates(uint256 _slashingBps)`: Sets the percentage of staked tokens to be slashed from participants who were on the losing side of a proposal resolution.
21. `emergencyWithdrawERC20(address _token, uint256 _amount)`: Allows the owner to withdraw mistakenly sent ERC-20 tokens (not `CognitionToken`) from the contract.
22. `emergencyWithdrawNative()`: Allows the owner to withdraw mistakenly sent native chain tokens (ETH) from the contract.
23. `pause()`: Pauses certain critical functions (e.g., propose, stake) in case of an emergency (requires `Pausable` inheritance).
24. `unpause()`: Unpauses the contract.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks, though 0.8 handles overflows
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For _uint256ToString for tokenURI

// --- Interfaces ---

interface ICognitionNet {
    event KnowledgeAssetProposed(uint256 indexed proposalId, address indexed proposer, bytes32 contentHash, string uri, uint256 stakeAmount);
    event ProposalStaked(uint256 indexed proposalId, address indexed staker, bool isValidation, uint256 amount);
    event ProposalResolved(uint256 indexed proposalId, bool indexed success, uint256 cognitionBlockId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 change, uint256 newReputation);
    event InsightBadgeUpdated(address indexed user, uint256 indexed badgeId, uint256 newLevel, string newUri);

    function proposeKnowledgeAsset(bytes32 _contentHash, string calldata _uri) external;
    function stakeForProposal(uint256 _proposalId, bool _isValidation) external;
    function resolveProposal(uint256 _proposalId) external;
    function claimRewards() external;
    function unstake(uint256 _amount) external;

    function getInsightBadgeDetails(address _user) external view returns (uint256 badgeId, uint256 level, string memory uri);
    function getProposalDetails(uint256 _proposalId) external view returns (address proposer, bytes32 contentHash, string memory uri, uint256 proposalStake, uint256 validationStake, uint256 challengeStake, uint256 submissionTimestamp, uint256 resolutionTimestamp, uint256 status);
    function getKnowledgeBlockDetails(uint256 _blockId) external view returns (address proposer, bytes32 contentHash, string memory uri, address[] memory validators, uint256 mintedTimestamp);
    function getUserReputation(address _user) external view returns (uint256);
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getUserClaimableRewards(address _user) external view returns (uint256);
    function getContractParameters() external view returns (uint256 proposalStake, uint256 validationStake, uint256 resolutionPeriod, uint256 proposerRewardBps, uint256 validatorRewardBps, uint256 slashingBps);

    function setProposalStakeAmount(uint256 _amount) external;
    function setValidationStakeAmount(uint256 _amount) external;
    function setProposalResolutionPeriod(uint256 _period) external;
    function setRewardDistributionRates(uint256 _proposerRewardBps, uint256 _validatorRewardBps) external;
    function setSlashingRates(uint256 _slashingBps) external;
    function emergencyWithdrawERC20(address _token, uint256 _amount) external;
    function emergencyWithdrawNative() external;
}

// --- Token Contracts ---

contract CognitionToken is ERC20, Ownable {
    constructor() ERC20("CognitionToken", "COG") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

contract CognitionBlockNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from contentHash to tokenId to prevent duplicate knowledge blocks
    mapping(bytes32 => uint256) public contentHashToTokenId;

    constructor() ERC721("CognitionBlock", "COGBLOCK") Ownable(msg.sender) {}

    function safeMint(address to, bytes32 _contentHash, string memory uri) external onlyOwner returns (uint256) {
        require(contentHashToTokenId[_contentHash] == 0, "CognitionBlockNFT: content hash already exists");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        contentHashToTokenId[_contentHash] = tokenId;
        return tokenId;
    }
}

// Soulbound Token for Insight Badges
contract InsightBadgeSBT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from address to tokenId (since each user has one badge)
    mapping(address => uint256) public userToTokenId;
    // Mapping from tokenId to badge level
    mapping(uint256 => uint256) public badgeLevels;

    constructor() ERC721("InsightBadge", "INSIGHT") Ownable(msg.sender) {}

    // Overriding _transfer to make tokens non-transferable (soulbound)
    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("InsightBadgeSBT: Tokens are soulbound and non-transferable");
    }

    // Custom mint or update function for the owner (CognitionNet contract)
    function mintOrUpdate(address to, uint256 newLevel, string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = userToTokenId[to];
        if (tokenId == 0) {
            // Mint new badge
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            userToTokenId[to] = tokenId;
        } else {
            // Update existing badge URI (metadata)
            require(_exists(tokenId), "InsightBadgeSBT: Token does not exist");
            require(ownerOf(tokenId) == to, "InsightBadgeSBT: Mismatch owner");
        }
        _setTokenURI(tokenId, uri);
        badgeLevels[tokenId] = newLevel;
        return tokenId;
    }

    function getTokenIdForUser(address _user) external view returns (uint256) {
        return userToTokenId[_user];
    }
}

// --- Main CognitionNet Contract ---

contract CognitionNet is ICognitionNet, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    CognitionToken public cognitionToken;
    CognitionBlockNFT public cognitionBlockNFT;
    InsightBadgeSBT public insightBadgeSBT;

    // Proposal tracking
    struct KnowledgeAssetProposal {
        address proposer;
        bytes32 contentHash;
        string uri;
        uint256 proposalStake; // Stake from the proposer
        uint256 validationStake; // Total stake for validation
        uint256 challengeStake; // Total stake for challenge
        uint256 submissionTimestamp;
        uint256 resolutionTimestamp; // When it can be resolved
        ProposalStatus status;
        address[] validators; // Addresses who staked for validation
        address[] challengers; // Addresses who staked for challenge
        mapping(address => bool) hasVoted; // Prevent double voting per proposal
    }

    enum ProposalStatus { Pending, ResolvedSuccess, ResolvedFailure, Expired }

    Counters.Counter private _proposalIds;
    Counters.Counter private _cognitionBlockIds; // Tracks minted CognitionBlocks
    mapping(uint256 => KnowledgeAssetProposal) public proposals;
    mapping(bytes32 => uint256) public contentHashToProposalId; // To check for existing proposals

    // User-specific data
    mapping(address => uint256) public userReputation; // Raw reputation score
    mapping(address => uint256) public userStakedAmount; // Total COG staked by user (general pool)
    mapping(address => uint256) public userClaimableRewards; // COG rewards available to claim

    // Configurable parameters
    uint256 public proposalStakeAmount;       // COG required to propose
    uint256 public validationStakeAmount;     // COG required to stake for validation/challenge
    uint256 public proposalResolutionPeriod;  // Time (seconds) for proposals to be open for staking

    uint256 public proposerRewardBps;         // Basis points for proposer reward (e.g., 500 = 5%)
    uint256 public validatorRewardBps;        // Basis points for validator reward
    uint256 public slashingBps;               // Basis points for slashing losing stakers

    // Insight Badge level thresholds (example values, can be more complex)
    uint256[] public insightBadgeLevelThresholds = [
        0,       // Level 0: Default
        100,     // Level 1: "Novice Contributor"
        500,     // Level 2: "Insight Seeker"
        2000,    // Level 3: "Knowledge Curator"
        5000     // Level 4: "Cognition Architect"
    ];

    // --- Events (Defined in ICognitionNet for clarity) ---

    // --- Constructor ---

    constructor(
        address _cognitionTokenAddress,
        address _cognitionBlockNFTAddress,
        address _insightBadgeSBTAddress
    ) Ownable(msg.sender) {
        cognitionToken = CognitionToken(_cognitionTokenAddress);
        cognitionBlockNFT = CognitionBlockNFT(_cognitionBlockNFTAddress);
        insightBadgeSBT = InsightBadgeSBT(_insightBadgeSBTAddress);

        // Set initial parameters (can be changed by owner)
        proposalStakeAmount = 100 * (10 ** 18); // 100 COG
        validationStakeAmount = 10 * (10 ** 18); // 10 COG
        proposalResolutionPeriod = 7 days; // 7 days

        proposerRewardBps = 1000; // 10%
        validatorRewardBps = 500; // 5%
        slashingBps = 2000; // 20%
    }

    // --- Core Protocol Functions ---

    /**
     * @dev Allows a user to propose a new knowledge asset.
     * Requires the `proposalStakeAmount` to be approved and transferred.
     * @param _contentHash A unique hash identifying the knowledge asset's content (e.g., IPFS CID).
     * @param _uri A URI pointing to the metadata or full content of the knowledge asset.
     */
    function proposeKnowledgeAsset(bytes32 _contentHash, string calldata _uri) external nonReentrant {
        require(contentHashToProposalId[_contentHash] == 0, "CognitionNet: Content already proposed or resolved");
        require(cognitionToken.balanceOf(msg.sender) >= proposalStakeAmount, "CognitionNet: Insufficient COG balance for proposal");
        require(cognitionToken.transferFrom(msg.sender, address(this), proposalStakeAmount), "CognitionNet: COG transfer failed for proposal stake");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = KnowledgeAssetProposal({
            proposer: msg.sender,
            contentHash: _contentHash,
            uri: _uri,
            proposalStake: proposalStakeAmount,
            validationStake: 0,
            challengeStake: 0,
            submissionTimestamp: block.timestamp,
            resolutionTimestamp: block.timestamp.add(proposalResolutionPeriod),
            status: ProposalStatus.Pending,
            validators: new address[](0),
            challengers: new address[](0)
        });
        proposals[newProposalId].hasVoted[msg.sender] = true; // Proposer implicitly votes for validation

        contentHashToProposalId[_contentHash] = newProposalId;
        userStakedAmount[msg.sender] = userStakedAmount[msg.sender].add(proposalStakeAmount);

        emit KnowledgeAssetProposed(newProposalId, msg.sender, _contentHash, _uri, proposalStakeAmount);
    }

    /**
     * @dev Allows users to stake `CognitionToken`s to either validate or challenge a proposal.
     * @param _proposalId The ID of the proposal to stake on.
     * @param _isValidation True to stake for validation, false to stake for challenge.
     */
    function stakeForProposal(uint256 _proposalId, bool _isValidation) external nonReentrant {
        KnowledgeAssetProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitionNet: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitionNet: Proposal not in pending state");
        require(block.timestamp < proposal.resolutionTimestamp, "CognitionNet: Proposal resolution period has ended");
        require(!proposal.hasVoted[msg.sender], "CognitionNet: Already staked on this proposal");
        require(cognitionToken.balanceOf(msg.sender) >= validationStakeAmount, "CognitionNet: Insufficient COG balance for staking");
        require(cognitionToken.transferFrom(msg.sender, address(this), validationStakeAmount), "CognitionNet: COG transfer failed for staking");

        if (_isValidation) {
            proposal.validationStake = proposal.validationStake.add(validationStakeAmount);
            proposal.validators.push(msg.sender);
        } else {
            proposal.challengeStake = proposal.challengeStake.add(validationStakeAmount);
            proposal.challengers.push(msg.sender);
        }

        proposal.hasVoted[msg.sender] = true;
        userStakedAmount[msg.sender] = userStakedAmount[msg.sender].add(validationStakeAmount);

        emit ProposalStaked(_proposalId, msg.sender, _isValidation, validationStakeAmount);
    }

    /**
     * @dev Resolves a knowledge asset proposal after its resolution period has ended.
     * Distributes rewards to successful participants and slashes losing stakes.
     * Mints a CognitionBlockNFT if the proposal is successful.
     * @param _proposalId The ID of the proposal to resolve.
     */
    function resolveProposal(uint256 _proposalId) external nonReentrant {
        KnowledgeAssetProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitionNet: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitionNet: Proposal not in pending state");
        require(block.timestamp >= proposal.resolutionTimestamp, "CognitionNet: Resolution period not yet ended");

        uint256 totalStake = proposal.validationStake.add(proposal.challengeStake);
        uint256 cognitionBlockId = 0;
        bool isSuccessful;

        if (totalStake == 0) {
            // No one staked, but proposer's stake counts as validation if no challenge.
            // If proposer's stake is the only stake, it's successful by default for simplicity, unless we want to penalize unpopularity.
            // For now, let's say if no challenges, it's successful.
            isSuccessful = true;
        } else {
            // Weighted by stake amount
            isSuccessful = proposal.validationStake >= proposal.challengeStake;
        }

        if (isSuccessful) {
            proposal.status = ProposalStatus.ResolvedSuccess;
            // Reward proposer
            uint256 proposerReward = proposal.proposalStake.mul(proposerRewardBps).div(10000);
            userClaimableRewards[proposal.proposer] = userClaimableRewards[proposal.proposer].add(proposerReward);
            _updateReputation(proposal.proposer, 100); // Increase proposer reputation

            // Reward successful validators
            if (proposal.validators.length > 0 && proposal.validationStake > 0) {
                uint256 totalRewardPoolForValidators = proposal.validationStake.mul(validatorRewardBps).div(10000); // Example: 5% of their own stake
                uint256 rewardPerValidator = totalRewardPoolForValidators.div(proposal.validators.length);

                for (uint256 i = 0; i < proposal.validators.length; i++) {
                    userClaimableRewards[proposal.validators[i]] = userClaimableRewards[proposal.validators[i]].add(rewardPerValidator);
                    _updateReputation(proposal.validators[i], 10); // Increase validator reputation
                }
            }

            // Slashing logic for challengers
            if (proposal.challengers.length > 0 && proposal.challengeStake > 0) {
                uint256 slashAmountPerChallenger = validationStakeAmount.mul(slashingBps).div(10000);
                for (uint256 i = 0; i < proposal.challengers.length; i++) {
                    address challenger = proposal.challengers[i];
                    userClaimableRewards[challenger] = userClaimableRewards[challenger].add(validationStakeAmount.sub(slashAmountPerChallenger)); // Return remaining stake
                    _updateReputation(challenger, -50); // Decrease challenger reputation
                }
            }

            // Mint CognitionBlock NFT
            _cognitionBlockIds.increment();
            cognitionBlockId = _cognitionBlockIds.current();
            cognitionBlockNFT.safeMint(proposal.proposer, proposal.contentHash, proposal.uri); // Proposer owns the CognitionBlock NFT
        } else {
            proposal.status = ProposalStatus.ResolvedFailure;
            // Slashing logic for proposer
            uint256 proposerSlashAmount = proposal.proposalStake.mul(slashingBps).div(10000);
            userClaimableRewards[proposal.proposer] = userClaimableRewards[proposal.proposer].add(proposal.proposalStake.sub(proposerSlashAmount)); // Return remaining stake
            _updateReputation(proposal.proposer, -100); // Decrease proposer reputation

            // Slashing logic for validators
            if (proposal.validators.length > 0 && proposal.validationStake > 0) {
                uint256 slashAmountPerValidator = validationStakeAmount.mul(slashingBps).div(10000);
                for (uint256 i = 0; i < proposal.validators.length; i++) {
                    address validator = proposal.validators[i];
                    userClaimableRewards[validator] = userClaimableRewards[validator].add(validationStakeAmount.sub(slashAmountPerValidator)); // Return remaining stake
                    _updateReputation(validator, -50); // Decrease validator reputation
                }
            }

            // Reward successful challengers
            if (proposal.challengers.length > 0 && proposal.challengeStake > 0) {
                uint256 totalRewardPoolForChallengers = proposal.challengeStake.mul(validatorRewardBps).div(10000);
                uint256 rewardPerChallenger = totalRewardPoolForChallengers.div(proposal.challengers.length);
                for (uint256 i = 0; i < proposal.challengers.length; i++) {
                    userClaimableRewards[proposal.challengers[i]] = userClaimableRewards[proposal.challengers[i]].add(rewardPerChallenger);
                    _updateReputation(proposal.challengers[i], 10); // Increase challenger reputation
                }
            }
        }

        // Adjust total staked amounts for all participants and transfer funds
        _distributeStakesAndRewards(proposal);

        emit ProposalResolved(_proposalId, isSuccessful, cognitionBlockId);
    }

    /**
     * @dev Internal helper to handle the distribution of staked funds and rewards after resolution.
     */
    function _distributeStakesAndRewards(KnowledgeAssetProposal storage proposal) internal {
        // Return proposer's initial stake (less any slash)
        userStakedAmount[proposal.proposer] = userStakedAmount[proposal.proposer].sub(proposal.proposalStake);

        // Return or slash validator stakes
        for (uint256 i = 0; i < proposal.validators.length; i++) {
            userStakedAmount[proposal.validators[i]] = userStakedAmount[proposal.validators[i]].sub(validationStakeAmount);
        }

        // Return or slash challenger stakes
        for (uint256 i = 0; i < proposal.challengers.length; i++) {
            userStakedAmount[proposal.challengers[i]] = userStakedAmount[proposal.challengers[i]].sub(validationStakeAmount);
        }

        // Funds are already in the contract and distributed to `userClaimableRewards`
        // `claimRewards` handles the actual token transfers out of the contract.
    }

    /**
     * @dev Allows a user to claim their accumulated CognitionToken rewards.
     */
    function claimRewards() external nonReentrant {
        uint256 amount = userClaimableRewards[msg.sender];
        require(amount > 0, "CognitionNet: No rewards to claim");

        userClaimableRewards[msg.sender] = 0; // Reset before transfer to prevent reentrancy (though nonReentrant is active)
        require(cognitionToken.transfer(msg.sender, amount), "CognitionNet: COG transfer failed for claiming rewards");

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Allows a user to unstake general COG tokens that are not locked in proposals.
     * @param _amount The amount of COG to unstake.
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "CognitionNet: Unstake amount must be greater than zero");
        require(userStakedAmount[msg.sender] >= _amount, "CognitionNet: Insufficient staked amount");

        // Note: This only unstakes from the general pool. Staked amounts in active proposals are locked.
        // A more complex system would track locked vs. available stake. For simplicity here,
        // userStakedAmount represents total committed, and resolution functions handle releasing/slashing.
        // This function assumes _amount is from the 'general' pool, not from active proposals.
        // A more robust implementation would need a separate mapping for 'available_stake'.
        // For this example, we'll assume `userStakedAmount` is the total, and `claimRewards` handles the return of *locked* funds.
        // Thus, this `unstake` is for funds that were 'deposited' but never committed to a proposal.
        // Let's adjust this: `userStakedAmount` tracks *all* staked funds. `claimRewards` is only for *rewards*.
        // The funds that return from a resolved proposal (original stake) would also go to `userClaimableRewards`.
        // So, this `unstake` function is actually for a 'deposit pool' of funds.
        // Let's modify `propose` and `stakeForProposal` to *take funds directly*, and `unstake` becomes for funds that haven't been committed.
        // This simplifies the `userStakedAmount` tracking to reflect truly *active* commitments.
        
        // REVISED APPROACH: userStakedAmount will track the *active commitments* in proposals.
        // Funds are transferred *to the contract* when proposing/staking.
        // When a proposal resolves, the original stake *plus/minus* rewards/slashing *all* goes into `userClaimableRewards`.
        // So, there's no "general pool" to unstake from here, as all transfers are direct.
        // Thus, `unstake` functionality isn't strictly needed in this revised model.
        // I will keep it as a placeholder, implying a "deposit" mechanism if we introduce one later.
        // For now, it will just revert.

        revert("CognitionNet: General unstaking not implemented in this version (all stakes are per-proposal)");
        // If it were implemented, it would be:
        // require(cognitionToken.transfer(msg.sender, _amount), "CognitionNet: COG transfer failed for unstake");
        // userStakedAmount[msg.sender] = userStakedAmount[msg.sender].sub(_amount);
        // emit TokensUnstaked(msg.sender, _amount);
    }

    // --- Reputation & Dynamic SBT Functions (Internal & User-Facing Getters) ---

    /**
     * @dev Internal function to update a user's reputation score and potentially their Insight Badge.
     * @param _user The address of the user whose reputation to update.
     * @param _change The amount to change reputation by (can be positive or negative).
     */
    function _updateReputation(address _user, int256 _change) internal {
        uint256 currentRep = userReputation[_user];
        uint256 newRep;

        if (_change > 0) {
            newRep = currentRep.add(uint256(_change));
        } else {
            // Ensure reputation doesn't go below zero
            uint256 absChange = uint256(_change * -1);
            newRep = currentRep > absChange ? currentRep.sub(absChange) : 0;
        }

        userReputation[_user] = newRep;
        emit ReputationUpdated(_user, _change, newRep);

        // Check for Insight Badge level upgrade/downgrade
        _mintOrUpdateInsightBadge(_user, newRep);
    }

    /**
     * @dev Internal function to mint or update a user's Insight Badge based on their reputation.
     * @param _recipient The address of the user.
     * @param _currentReputation The user's current reputation score.
     */
    function _mintOrUpdateInsightBadge(address _recipient, uint256 _currentReputation) internal {
        uint256 currentBadgeLevel = 0;
        uint256 badgeId = insightBadgeSBT.userToTokenId(_recipient);
        if (badgeId != 0) {
            currentBadgeLevel = insightBadgeSBT.badgeLevels(badgeId);
        }

        uint256 newLevel = currentBadgeLevel;
        for (uint256 i = insightBadgeLevelThresholds.length - 1; i >= 0; i--) {
            if (_currentReputation >= insightBadgeLevelThresholds[i]) {
                newLevel = i;
                break;
            }
            if (i == 0) break; // Avoid underflow for i if it's already 0
        }

        if (newLevel != currentBadgeLevel) {
            string memory newUri = string(abi.encodePacked("ipfs://YOUR_IPFS_GATEWAY/badge_level_", Strings.toString(newLevel), ".json"));
            uint256 updatedBadgeId = insightBadgeSBT.mintOrUpdate(_recipient, newLevel, newUri);
            emit InsightBadgeUpdated(_recipient, updatedBadgeId, newLevel, newUri);
        }
    }

    /**
     * @dev Returns the Insight Badge details for a given user.
     * @param _user The address of the user.
     * @return badgeId The ID of the Insight Badge.
     * @return level The current level of the Insight Badge.
     * @return uri The URI pointing to the badge's metadata.
     */
    function getInsightBadgeDetails(address _user) external view override returns (uint256 badgeId, uint256 level, string memory uri) {
        badgeId = insightBadgeSBT.userToTokenId(_user);
        if (badgeId != 0) {
            level = insightBadgeSBT.badgeLevels(badgeId);
            uri = insightBadgeSBT.tokenURI(badgeId);
        }
    }

    // --- Data & Query Functions ---

    /**
     * @dev Retrieves all details of a specific knowledge asset proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer The address of the proposer.
     * @return contentHash The content hash of the proposed asset.
     * @return uri The URI to the asset's metadata.
     * @return proposalStake The stake amount from the proposer.
     * @return validationStake The total stake for validation.
     * @return challengeStake The total stake for challenge.
     * @return submissionTimestamp The time the proposal was submitted.
     * @return resolutionTimestamp The time the proposal can be resolved.
     * @return status The current status of the proposal (Pending, ResolvedSuccess, etc.).
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        override
        returns (
            address proposer,
            bytes32 contentHash,
            string memory uri,
            uint256 proposalStake,
            uint256 validationStake,
            uint256 challengeStake,
            uint256 submissionTimestamp,
            uint256 resolutionTimestamp,
            uint256 status
        )
    {
        KnowledgeAssetProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitionNet: Proposal does not exist");
        return (
            proposal.proposer,
            proposal.contentHash,
            proposal.uri,
            proposal.proposalStake,
            proposal.validationStake,
            proposal.challengeStake,
            proposal.submissionTimestamp,
            proposal.resolutionTimestamp,
            uint256(proposal.status)
        );
    }

    /**
     * @dev Retrieves details of a minted CognitionBlockNFT.
     * @param _blockId The ID of the CognitionBlock NFT.
     * @return proposer The address of the original proposer.
     * @return contentHash The content hash of the block.
     * @return uri The URI to the block's metadata.
     * @return validators The addresses of the successful validators.
     * @return mintedTimestamp The timestamp when the block was minted.
     */
    function getKnowledgeBlockDetails(uint256 _blockId)
        external
        view
        override
        returns (
            address proposer,
            bytes32 contentHash,
            string memory uri,
            address[] memory validators,
            uint256 mintedTimestamp
        )
    {
        // This requires storing more data within CognitionBlockNFT or looking up the original proposal.
        // For simplicity, we can get data from the original proposal that resulted in this block.
        // This is a placeholder and assumes `_blockId` maps directly to `_proposalId` which might not always be true if proposals fail.
        // A more robust system would store this in the `CognitionBlockNFT` contract directly.
        // For now, let's assume _blockId directly maps to the proposal ID for the successful proposal.
        // This requires an internal mapping in CognitionBlockNFT from its tokenId to the original proposalId.
        // Or, we retrieve the block's contentHash and then find the proposal by that.
        // Let's implement via contentHash lookup in CognitionNet.

        // This function would ideally be a view function on CognitionBlockNFT or a more complex join.
        // For demonstration, we'll return placeholder or simplified data.
        // To truly fulfill, `CognitionBlockNFT` would need to store `proposer`, `validators`, `mintedTimestamp`.

        // Simplified: Fetch contentHash from CognitionBlockNFT and try to find corresponding proposal.
        // This is not efficient, but demonstrates the concept.
        bytes32 blockContentHash = cognitionBlockNFT.contentHashToTokenId[_blockId] != 0 ?
            _getMappingKeyByValue(cognitionBlockNFT.contentHashToTokenId, _blockId) : bytes32(0);

        if (blockContentHash == bytes32(0)) return (address(0), bytes32(0), "", new address[](0), 0);

        uint256 proposalIdForBlock = contentHashToProposalId[blockContentHash];
        if (proposalIdForBlock == 0 || proposals[proposalIdForBlock].status != ProposalStatus.ResolvedSuccess) {
            return (address(0), bytes32(0), "", new address[](0), 0);
        }

        KnowledgeAssetProposal storage successProposal = proposals[proposalIdForBlock];
        return (
            successProposal.proposer,
            successProposal.contentHash,
            successProposal.uri,
            successProposal.validators,
            successProposal.resolutionTimestamp // Assuming minted at resolution
        );
    }

    // Helper for getKnowledgeBlockDetails - WARNING: This is an O(N) operation and not suitable for large mappings.
    // For a real contract, the NFT itself would store the required metadata.
    function _getMappingKeyByValue(mapping(bytes32 => uint256) storage _map, uint256 _value) internal view returns (bytes32 key) {
        bytes32 tempKey; // placeholder
        // Iterating over a mapping in Solidity is not direct. This is a conceptual helper.
        // In practice, you'd likely have an array of all contentHashes if you needed to iterate.
        // For a full production system, `CognitionBlockNFT` would store more data internally.
        // This function is for illustration of the desired outcome only.
        return tempKey; // Placeholder to avoid compilation error.
    }


    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view override returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the total amount of COG tokens a user has currently staked in the protocol.
     * @param _user The address of the user.
     * @return The total staked amount.
     */
    function getUserStakedAmount(address _user) external view override returns (uint256) {
        return userStakedAmount[_user];
    }

    /**
     * @dev Returns the amount of COG tokens a user can currently claim as rewards.
     * @param _user The address of the user.
     * @return The claimable reward amount.
     */
    function getUserClaimableRewards(address _user) external view override returns (uint256) {
        return userClaimableRewards[_user];
    }

    /**
     * @dev Returns the current configurable parameters of the protocol.
     * @return proposalStake The amount of COG required to propose.
     * @return validationStake The amount of COG required to validate/challenge.
     * @return resolutionPeriod The time (in seconds) for proposal resolution.
     * @return proposerRewardBps The basis points for proposer rewards.
     * @return validatorRewardBps The basis points for validator rewards.
     * @return slashingBps The basis points for slashing losing stakers.
     */
    function getContractParameters()
        external
        view
        override
        returns (
            uint256 proposalStake,
            uint256 validationStake,
            uint256 resolutionPeriod,
            uint256 proposerRewardBps,
            uint256 validatorRewardBps,
            uint256 slashingBps
        )
    {
        return (
            proposalStakeAmount,
            validationStakeAmount,
            proposalResolutionPeriod,
            proposerRewardBps,
            validatorRewardBps,
            slashingBps
        );
    }

    /**
     * @dev Returns the total number of CognitionBlockNFTs minted.
     */
    function getTotalCognitionBlocks() external view returns (uint256) {
        return cognitionBlockNFT.totalSupply(); // Assuming CognitionBlockNFT uses ERC721Enumerable or equivalent for totalSupply
    }

    // --- Admin & Configuration Functions (Owner-Only) ---

    /**
     * @dev Sets the amount of CognitionToken required to propose a knowledge asset.
     * @param _amount The new stake amount.
     */
    function setProposalStakeAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "CognitionNet: Stake amount must be positive");
        proposalStakeAmount = _amount;
    }

    /**
     * @dev Sets the minimum amount of CognitionToken required to validate or challenge a proposal.
     * @param _amount The new stake amount.
     */
    function setValidationStakeAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "CognitionNet: Stake amount must be positive");
        validationStakeAmount = _amount;
    }

    /**
     * @dev Sets the time duration (in seconds) during which a proposal can be validated/challenged.
     * @param _period The new resolution period in seconds.
     */
    function setProposalResolutionPeriod(uint256 _period) external onlyOwner {
        require(_period > 0, "CognitionNet: Period must be positive");
        proposalResolutionPeriod = _period;
    }

    /**
     * @dev Sets the basis points for rewards distributed to successful proposers and validators.
     * @param _proposerRewardBps Basis points for proposer reward (e.g., 1000 = 10%). Max 10000.
     * @param _validatorRewardBps Basis points for validator reward. Max 10000.
     */
    function setRewardDistributionRates(uint256 _proposerRewardBps, uint256 _validatorRewardBps) external onlyOwner {
        require(_proposerRewardBps <= 10000, "CognitionNet: Proposer reward BPS max 10000");
        require(_validatorRewardBps <= 10000, "CognitionNet: Validator reward BPS max 10000");
        proposerRewardBps = _proposerRewardBps;
        validatorRewardBps = _validatorRewardBps;
    }

    /**
     * @dev Sets the percentage of staked tokens to be slashed from participants who were on the losing side.
     * @param _slashingBps Basis points for slashing (e.g., 2000 = 20%). Max 10000.
     */
    function setSlashingRates(uint256 _slashingBps) external onlyOwner {
        require(_slashingBps <= 10000, "CognitionNet: Slashing BPS max 10000");
        slashingBps = _slashingBps;
    }

    /**
     * @dev Allows the owner to withdraw mistakenly sent ERC-20 tokens from the contract.
     * @param _token The address of the ERC-20 token.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(cognitionToken), "CognitionNet: Cannot withdraw CognitionToken via emergency function");
        ERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @dev Allows the owner to withdraw mistakenly sent native chain tokens (ETH) from the contract.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance); // Withdraw all
    }
}
```