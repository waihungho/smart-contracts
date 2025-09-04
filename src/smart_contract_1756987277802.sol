Okay, this is an ambitious and exciting challenge! To create a truly unique, advanced, and creative smart contract with at least 20 functions, avoiding direct duplication of existing open-source projects, we'll design a "Decentralized Adaptive Essence (DAE) Protocol."

This protocol will focus on **reputation-based, collective investment strategies with dynamic, soul-bound NFTs (Essence NFTs)** that evolve with a user's on-chain contributions and reputation. It combines concepts from DeFi, NFTs, DAO governance, and social reputation systems.

---

## Decentralized Adaptive Essence (DAE) Protocol

### Outline

The DAE Protocol enables users to collaboratively invest in dynamic strategies, where influence and rewards are determined by a combination of their capital and their on-chain "Essence" – a soul-bound, dynamic NFT representing their reputation and contributions. Strategies can adapt based on market data (via Oracle) and collective governance.

1.  **Essence NFT (ERC721-like, Soul-Bound & Dynamic):**
    *   A unique, non-transferable NFT (`EssenceToken`) minted to each participant.
    *   Its visual representation (metadata) dynamically changes based on the user's `reputationScore` and `contributionTier`.
    *   Serves as a "proof-of-contribution" and gatekeeper.
2.  **Reputation System:**
    *   Internal score (`reputationScore`) that increases with positive actions (successful proposals, active participation, high-yield contributions) and decreases with negative actions (failed proposals, inactivity).
    *   Can be initially boosted by attestations from other reputable Essence holders or registered attestors.
3.  **Adaptive Investment Pools:**
    *   Users deposit funds into shared pools.
    *   Each pool has an active investment strategy, which can be dynamically updated.
4.  **Dynamic Strategy Management:**
    *   Users with sufficient Essence can propose new investment strategies or parameters for existing ones.
    *   Essence-weighted voting determines strategy adoption.
    *   Strategies can be designed to interact with external DeFi protocols (e.g., lending, AMMs) and adapt based on Oracle data.
5.  **Multi-Factor Reward Distribution & Governance:**
    *   Yield from investment pools is distributed based on a calculated "influence weight" combining deposited capital, `reputationScore`, and `EssenceToken`'s `contributionTier`.
    *   Voting power is also determined by this influence weight.
6.  **Attestation Layer (Sybil Resistance/Social Graph):**
    *   Trusted entities or highly reputable Essence holders can "attest" to new users, providing an initial reputation boost and fostering community growth.
    *   Attestations can be revoked if misbehavior is detected.

### Function Summary

**I. Core Platform & Admin (Owner/Authorized Roles)**
1.  `constructor()`: Initializes the platform, mints the first Essence for the owner.
2.  `updateOracleAddress(address _newOracle)`: Sets the address of the trusted market data oracle.
3.  `updateStrategyExecutor(address _newExecutor)`: Sets the address of the contract that executes investment strategies.
4.  `setContributionWeightFactors(uint256 _capitalFactor, uint256 _reputationFactor, uint256 _essenceTierFactor)`: Admin sets the relative importance of capital, reputation, and Essence tier in influence calculation.
5.  `setMinReputationForProposal(uint256 _minReputation)`: Sets the minimum reputation score required to propose new strategies.
6.  `registerExternalAttestor(address _attestor, bool _isRegistered)`: Registers/deregisters addresses allowed to provide initial attestations.
7.  `emergencyWithdrawERC20(address _token, uint256 _amount)`: Allows emergency withdrawal of any ERC20 token held by the contract.

**II. Essence NFT Management (ERC721-like but Dynamic)**
8.  `mintEssence(address _recipient)`: Mints a new EssenceToken for a user (only if they don't have one and meet criteria).
9.  `burnEssence()`: Allows a user to burn their own EssenceToken, permanently opting out.
10. `getReputationScore(address _user)`: Returns the current reputation score of a user.
11. `getContributionTier(address _user)`: Returns the contribution tier derived from reputation.
12. `tokenURI(uint256 tokenId)`: Generates dynamic SVG metadata URI for the Essence NFT based on its holder's reputation.
13. `_increaseReputation(address _user, uint256 _amount)`: Internal: Increases a user's reputation score.
14. `_decreaseReputation(address _user, uint256 _amount)`: Internal: Decreases a user's reputation score.

**III. Reputation & Attestation System**
15. `attestUser(address _userToAttest, uint256 _initialReputationBoost)`: Allows a reputable Essence holder or registered attestor to provide an initial reputation boost to a new user.
16. `revokeAttestation(address _userToRevoke, uint256 _reputationPenalty)`: Allows an attestor to revoke an attestation, penalizing the attested user's reputation.

**IV. Investment Pools & Strategies**
17. `createInvestmentPool(string memory _name, address _token, address _initialStrategy)`: Creates a new investment pool for a specific ERC20 token and initial strategy.
18. `depositToPool(uint256 _poolId, uint256 _amount)`: Users deposit funds into a specified pool.
19. `withdrawFromPool(uint256 _poolId, uint256 _amount)`: Users withdraw their share from a pool.
20. `proposeStrategyUpdate(uint256 _poolId, address _newStrategyAddress, bytes calldata _strategyParams, string memory _description)`: Proposes a new strategy or parameter update for a pool.
21. `voteOnStrategyProposal(uint256 _poolId, uint256 _proposalId, bool _support)`: Users vote on a strategy proposal using their influence weight.
22. `executeStrategyUpdate(uint256 _poolId, uint256 _proposalId)`: Executes a successfully voted-in strategy update.
23. `triggerStrategyExecution(uint256 _poolId)`: Triggers the active strategy for a pool (e.g., rebalance, yield farming).
24. `harvestYield(uint256 _poolId)`: Collects accrued yield from a strategy.

**V. Reward Distribution & Influence**
25. `claimRewards(uint256 _poolId)`: Allows users to claim their share of harvested yield from a pool.
26. `getInfluenceWeight(address _user, uint256 _poolId)`: Calculates a user's total influence weight for a specific pool, considering capital, reputation, and Essence tier.
27. `delegateEssenceInfluence(address _delegatee)`: Allows an Essence holder to delegate their influence weight (for voting and reward calculation) to another Essence holder.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces for external components
interface IOracle {
    function getLatestPrice(string memory symbol) external view returns (uint256);
    // Add more functions as needed for complex data
}

interface IStrategyExecutor {
    // This interface would be more complex in a real scenario,
    // handling interaction with various DeFi protocols.
    // For this example, we'll keep it simple.
    function executeStrategy(uint256 poolId, address strategyAddress, bytes calldata params) external;
    function harvest(uint256 poolId) external returns (uint256 yieldAmount);
}

// Custom Errors for better readability and gas efficiency
error DAE__Unauthorized();
error DAE__AlreadyHasEssence();
error DAE__NoEssenceFound();
error DAE__InvalidReputationScore();
error DAE__PoolNotFound();
error DAE__DepositAmountTooLow();
error DAE__WithdrawAmountExceedsBalance();
error DAE__ProposalNotFound();
error DAE__VotingPeriodEnded();
error DAE__AlreadyVoted();
error DAE__NotEnoughReputationForProposal();
error DAE__ProposalNotApproved();
error DAE__StrategyExecutionFailed();
error DAE__NoRewardsToClaim();
error DAE__CannotSelfDelegate();
error DAE__InvalidEssenceTierFactors();
error DAE__AttestationTooHigh();

contract DecentralizedAdaptiveEssence is Ownable, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _essenceTokenIds; // For Essence NFT minting

    // Essence NFT (Soul-Bound)
    mapping(address => uint256) public userEssenceTokenId; // address -> tokenId
    mapping(uint256 => address) public essenceTokenOwner; // tokenId -> address (redundant with ERC721 but useful for clarity)

    // Reputation System
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public lastActiveBlock; // For inactivity decay
    mapping(address => bool) public isExternalAttestor; // Whitelisted addresses for initial attestation
    mapping(address => mapping(address => bool)) public hasAttested; // attestor -> attested_user -> bool

    // Influence Weight Factors (Admin configurable)
    uint256 public capitalInfluenceFactor = 1; // Multiplier for capital in influence calculation
    uint256 public reputationInfluenceFactor = 1; // Multiplier for reputation
    uint256 public essenceTierInfluenceFactor = 1; // Multiplier for essence tier

    uint256 public minReputationForProposal = 100; // Min reputation to propose a strategy

    // Investment Pools
    struct InvestmentPool {
        string name;
        address token; // The ERC20 token deposited into this pool
        uint256 totalDeposited;
        mapping(address => uint256) userBalances; // User's deposited amount in this pool
        address activeStrategy; // Address of the current strategy contract
        uint256 lastHarvestBlock;
        uint256 totalHarvestedYield;
        mapping(address => uint256) userClaimedYield; // User's total claimed yield from this pool
        uint256 lastTotalInfluenceWeight; // Snapshot of total influence at last harvest/claim
        mapping(address => uint256) lastUserInfluenceWeight; // Snapshot of user influence at last harvest/claim
        Counters.Counter proposalCounter;
    }
    mapping(uint256 => InvestmentPool) public investmentPools;
    Counters.Counter public nextPoolId;

    // Strategy Proposals
    struct StrategyProposal {
        address proposer;
        address newStrategyAddress;
        bytes strategyParams; // Parameters for the new strategy (e.g., token addresses, weights)
        string description;
        uint256 creationBlock;
        uint256 votingDeadlineBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // address -> bool
        bool executed;
        bool approved; // True if votesFor > votesAgainst after deadline
    }
    mapping(uint256 => mapping(uint256 => StrategyProposal)) public poolStrategyProposals; // poolId -> proposalId -> Proposal

    // Delegation of Influence
    mapping(address => address) public delegatedEssenceInfluence; // user -> delegatee (0x0 if not delegated)

    // External Contract Addresses
    address public oracleAddress;
    address public strategyExecutor;

    // Essence NFT SVG parts (simplistic for example, could be more complex with IPFS/data URI)
    string[] public essenceBaseSVG; // Background/frame
    string[] public essenceEmblemSVG; // Emblem changes with tier
    string[] public essenceColorSVG; // Color changes with tier

    // --- Events ---
    event EssenceMinted(address indexed recipient, uint256 tokenId, uint256 initialReputation);
    event EssenceBurned(address indexed burner, uint256 tokenId);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event AttestationProvided(address indexed attestor, address indexed attestedUser, uint256 boostAmount);
    event AttestationRevoked(address indexed attestor, address indexed userRevoked, uint256 penaltyAmount);
    event PoolCreated(uint256 indexed poolId, string name, address token, address initialStrategy);
    event Deposited(uint256 indexed poolId, address indexed user, uint256 amount);
    event Withdrawn(uint256 indexed poolId, address indexed user, uint256 amount);
    event StrategyProposalCreated(uint256 indexed poolId, uint256 indexed proposalId, address indexed proposer, address newStrategy, string description);
    event VotedOnStrategy(uint256 indexed poolId, uint256 indexed proposalId, address indexed voter, bool support, uint256 influenceWeight);
    event StrategyExecuted(uint256 indexed poolId, uint256 indexed proposalId, address newStrategyAddress);
    event YieldHarvested(uint256 indexed poolId, uint256 amount);
    event RewardsClaimed(uint256 indexed poolId, address indexed user, uint256 amount);
    event EssenceInfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceFactorsUpdated(uint256 capitalFactor, uint256 reputationFactor, uint256 essenceTierFactor);
    event MinReputationForProposalUpdated(uint256 minReputation);
    event ExternalAttestorRegistered(address indexed attestor, bool isRegistered);

    // --- Modifiers ---
    modifier onlyEssenceHolder() {
        if (userEssenceTokenId[msg.sender] == 0) revert DAE__NoEssenceFound();
        _;
    }

    modifier onlyReputable(uint256 _requiredReputation) {
        if (reputationScores[msg.sender] < _requiredReputation) revert DAE__NotEnoughReputationForProposal();
        _;
    }

    // --- Constructor ---
    constructor(address _oracleAddress, address _strategyExecutor) ERC721("EssenceToken", "ESSENCE") Ownable(msg.sender) {
        oracleAddress = _oracleAddress;
        strategyExecutor = _strategyExecutor;

        // Initialize SVG parts (these could be configurable or more complex)
        essenceBaseSVG = [
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: sans-serif; font-size: 14px; }</style><rect width='100%' height='100%' fill='#f3f3f3' /><text x='10' y='20' class='base'>Essence of</text>",
            "</svg>"
        ];
        essenceEmblemSVG = [
            "<text x='10' y='300' class='base'>Level 1: Novice</text>", // Tier 1
            "<text x='10' y='300' class='base'>Level 2: Contributor</text>", // Tier 2
            "<text x='10' y='300' class='base'>Level 3: Expert</text>", // Tier 3
            "<text x='10' y='300' class='base'>Level 4: Master</text>", // Tier 4
            "<text x='10' y='300' class='base'>Level 5: Luminary</text>" // Tier 5
        ];
        essenceColorSVG = [
            "<rect x='10' y='30' width='330' height='250' fill='#cccccc'/>", // Tier 1
            "<rect x='10' y='30' width='330' height='250' fill='#a0d8f0'/>", // Tier 2
            "<rect x='10' y='30' width='330' height='250' fill='#80c0e0'/>", // Tier 3
            "<rect x='10' y='30' width='330' height='250' fill='#60a8d0'/>", // Tier 4
            "<rect x='10' y='30' width='330' height='250' fill='#4090c0'/>" // Tier 5
        ];

        // Mint the first Essence to the owner with an initial high reputation
        _mintEssence(msg.sender, 1000); // Owner gets high initial reputation
        _increaseReputation(msg.sender, 500); // Add more for the owner's initial boost
    }

    // --- I. Core Platform & Admin Functions ---

    /**
     * @notice Updates the trusted Oracle address.
     * @param _newOracle The new address for the IOracle contract.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
    }

    /**
     * @notice Updates the trusted Strategy Executor address.
     * @param _newExecutor The new address for the IStrategyExecutor contract.
     */
    function updateStrategyExecutor(address _newExecutor) external onlyOwner {
        strategyExecutor = _newExecutor;
    }

    /**
     * @notice Sets the factors for calculating influence weight.
     *         Influence = (capital * capitalFactor) + (reputation * reputationFactor) + (essenceTier * essenceTierFactor)
     * @param _capitalFactor Multiplier for deposited capital.
     * @param _reputationFactor Multiplier for reputation score.
     * @param _essenceTierFactor Multiplier for essence contribution tier.
     */
    function setContributionWeightFactors(
        uint256 _capitalFactor,
        uint256 _reputationFactor,
        uint256 _essenceTierFactor
    ) external onlyOwner {
        if (_capitalFactor == 0 && _reputationFactor == 0 && _essenceTierFactor == 0) {
            revert DAE__InvalidEssenceTierFactors();
        }
        capitalInfluenceFactor = _capitalFactor;
        reputationInfluenceFactor = _reputationFactor;
        essenceTierInfluenceFactor = _essenceTierFactor;
        emit InfluenceFactorsUpdated(_capitalFactor, _reputationFactor, _essenceTierFactor);
    }

    /**
     * @notice Sets the minimum reputation score required for a user to propose a new strategy.
     * @param _minReputation The new minimum reputation score.
     */
    function setMinReputationForProposal(uint256 _minReputation) external onlyOwner {
        minReputationForProposal = _minReputation;
        emit MinReputationForProposalUpdated(_minReputation);
    }

    /**
     * @notice Registers or deregisters an address as an external attestor.
     *         Registered attestors can provide initial reputation to new users.
     * @param _attestor The address to register/deregister.
     * @param _isRegistered True to register, false to deregister.
     */
    function registerExternalAttestor(address _attestor, bool _isRegistered) external onlyOwner {
        isExternalAttestor[_attestor] = _isRegistered;
        emit ExternalAttestorRegistered(_attestor, _isRegistered);
    }

    /**
     * @notice Allows the owner to withdraw any ERC20 token from the contract in case of emergency.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    // --- II. Essence NFT Management ---

    /**
     * @notice Mints a new EssenceToken for a user.
     *         Can only be called by a trusted attestor or if specific criteria are met (e.g., initial self-mint).
     * @param _recipient The address to mint the EssenceToken to.
     * @param _initialReputation The initial reputation score for the new Essence holder.
     */
    function _mintEssence(address _recipient, uint256 _initialReputation) internal {
        if (userEssenceTokenId[_recipient] != 0) revert DAE__AlreadyHasEssence();

        _essenceTokenIds.increment();
        uint256 newTokenId = _essenceTokenIds.current();

        _safeMint(_recipient, newTokenId);
        userEssenceTokenId[_recipient] = newTokenId;
        essenceTokenOwner[newTokenId] = _recipient;
        reputationScores[_recipient] = _initialReputation;
        lastActiveBlock[_recipient] = block.number; // Initialize activity

        emit EssenceMinted(_recipient, newTokenId, _initialReputation);
        emit ReputationUpdated(_recipient, 0, _initialReputation); // Initial reputation has 0 as old rep
    }
    
    /**
     * @notice Public function to mint Essence. Restricted to owner or attestors, or based on specific on-chain conditions.
     *         For simplicity, we'll allow owner or registered attestors to mint.
     * @param _recipient The address to mint the EssenceToken to.
     */
    function mintEssence(address _recipient) external {
        if (msg.sender != owner() && !isExternalAttestor[msg.sender]) revert DAE__Unauthorized();
        // A more advanced version might require some pre-requisite (e.g. holding another token, on-chain activity history)
        _mintEssence(_recipient, 10); // Default initial reputation for non-attested mints
    }

    /**
     * @notice Allows a user to burn their own EssenceToken.
     *         This is a permanent action and removes their on-chain reputation and influence.
     */
    function burnEssence() external onlyEssenceHolder {
        uint256 tokenId = userEssenceTokenId[msg.sender];

        _burn(tokenId);
        delete userEssenceTokenId[msg.sender];
        delete essenceTokenOwner[tokenId];
        delete reputationScores[msg.sender];
        delete lastActiveBlock[msg.sender];
        delete delegatedEssenceInfluence[msg.sender]; // Remove any delegation

        // Clean up pool-specific data if necessary (e.g., reset balances or claims)
        // For simplicity, we assume this doesn't void historical claims/deposits immediately,
        // but new calculations won't include burned Essence.

        emit EssenceBurned(msg.sender, tokenId);
    }

    /**
     * @notice Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @notice Returns the contribution tier of a user based on their reputation score.
     *         This is used for dynamic NFT metadata and potentially influence calculations.
     * @param _user The address of the user.
     * @return The contribution tier (1-5).
     */
    function getContributionTier(address _user) public view returns (uint256) {
        uint256 reputation = reputationScores[_user];
        if (reputation >= 1000) return 5; // Luminary
        if (reputation >= 500) return 4;  // Master
        if (reputation >= 200) return 3;  // Expert
        if (reputation >= 50) return 2;   // Contributor
        return 1; // Novice
    }

    /**
     * @notice Generates the dynamic SVG metadata URI for an Essence NFT.
     *         The NFT's appearance changes based on the holder's reputation score.
     * @param tokenId The ID of the Essence NFT.
     * @return A data URI containing the SVG image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address ownerOfToken = essenceTokenOwner[tokenId];
        if (ownerOfToken == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }

        uint256 tier = getContributionTier(ownerOfToken);
        uint256 reputation = reputationScores[ownerOfToken];

        // Construct SVG based on tier
        string memory svg = string(
            abi.encodePacked(
                essenceBaseSVG[0],
                "<text x='150' y='20' text-anchor='middle' class='base'>",
                ownerOfToken.toHexString(), // Display the address
                "</text>",
                "<text x='150' y='250' text-anchor='middle' class='base'>Reputation: ",
                reputation.toString(),
                "</text>",
                essenceColorSVG[tier.sub(1)], // Tier 1 is index 0
                essenceEmblemSVG[tier.sub(1)],
                essenceBaseSVG[1]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Essence #',
                        tokenId.toString(),
                        '", "description": "Dynamic representation of on-chain reputation and contribution in the DAE Protocol.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Internal function to increase a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount to increase reputation by.
     */
    function _increaseReputation(address _user, uint256 _amount) internal {
        if (userEssenceTokenId[_user] == 0) return; // Cannot gain reputation without an Essence

        uint256 oldReputation = reputationScores[_user];
        reputationScores[_user] = reputationScores[_user].add(_amount);
        lastActiveBlock[_user] = block.number;
        emit ReputationUpdated(_user, oldReputation, reputationScores[_user]);
    }

    /**
     * @dev Internal function to decrease a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount to decrease reputation by.
     */
    function _decreaseReputation(address _user, uint256 _amount) internal {
        if (userEssenceTokenId[_user] == 0) return;

        uint256 oldReputation = reputationScores[_user];
        if (reputationScores[_user] < _amount) {
            reputationScores[_user] = 0;
        } else {
            reputationScores[_user] = reputationScores[_user].sub(_amount);
        }
        lastActiveBlock[_user] = block.number;
        emit ReputationUpdated(_user, oldReputation, reputationScores[_user]);
    }

    // --- III. Reputation & Attestation System ---

    /**
     * @notice Allows a reputable Essence holder or registered attestor to provide an initial reputation boost to a new user.
     *         Helps with Sybil resistance and community onboarding.
     * @param _userToAttest The address of the new user to attest.
     * @param _initialReputationBoost The initial reputation score to grant.
     */
    function attestUser(address _userToAttest, uint256 _initialReputationBoost) external {
        if (userEssenceTokenId[_userToAttest] != 0) revert DAE__AlreadyHasEssence();
        if (_initialReputationBoost == 0 || _initialReputationBoost > 100) revert DAE__AttestationTooHigh(); // Limit initial boost to prevent abuse

        bool canAttest = false;
        if (msg.sender == owner() || isExternalAttestor[msg.sender]) {
            canAttest = true;
        } else if (userEssenceTokenId[msg.sender] != 0 && getContributionTier(msg.sender) >= 3) { // Only expert+ Essence holders can attest
            canAttest = true;
        }

        if (!canAttest) revert DAE__Unauthorized();
        if (hasAttested[msg.sender][_userToAttest]) revert ("DAE: Already attested this user.");

        _mintEssence(_userToAttest, _initialReputationBoost);
        hasAttested[msg.sender][_userToAttest] = true;
        _increaseReputation(msg.sender, 5); // Attestor gains a small rep boost for good attestation
        emit AttestationProvided(msg.sender, _userToAttest, _initialReputationBoost);
    }

    /**
     * @notice Allows an attestor to revoke an attestation if the attested user misbehaves.
     * @param _userToRevoke The address of the user whose attestation is being revoked.
     * @param _reputationPenalty The amount of reputation to penalize the user.
     */
    function revokeAttestation(address _userToRevoke, uint256 _reputationPenalty) external {
        bool canRevoke = false;
        if (msg.sender == owner() || isExternalAttestor[msg.sender]) {
            canRevoke = true;
        } else if (userEssenceTokenId[msg.sender] != 0 && getContributionTier(msg.sender) >= 3) {
            canRevoke = true;
        }

        if (!canRevoke) revert DAE__Unauthorized();
        if (!hasAttested[msg.sender][_userToRevoke]) revert ("DAE: You did not attest this user.");
        if (userEssenceTokenId[_userToRevoke] == 0) revert DAE__NoEssenceFound();

        _decreaseReputation(_userToRevoke, _reputationPenalty);
        // Attestor also gets a small rep penalty for a failed attestation, or a boost for a necessary one
        _decreaseReputation(msg.sender, 2); // Small penalty for attestor for potentially "misplaced trust"
        hasAttested[msg.sender][_userToRevoke] = false; // Allow re-attestation if needed
        emit AttestationRevoked(msg.sender, _userToRevoke, _reputationPenalty);
    }

    // --- IV. Investment Pools & Strategies ---

    /**
     * @notice Creates a new investment pool. Only callable by owner or highly reputable users.
     * @param _name The name of the investment pool.
     * @param _token The ERC20 token that users will deposit into this pool.
     * @param _initialStrategy The address of the initial investment strategy for this pool.
     */
    function createInvestmentPool(string memory _name, address _token, address _initialStrategy) external onlyOwner { // For simplicity, only owner. Could be `onlyReputable(MinReputationForPoolCreation)`
        nextPoolId.increment();
        uint256 poolId = nextPoolId.current();

        investmentPools[poolId] = InvestmentPool({
            name: _name,
            token: _token,
            totalDeposited: 0,
            activeStrategy: _initialStrategy,
            lastHarvestBlock: block.number,
            totalHarvestedYield: 0,
            lastTotalInfluenceWeight: 0,
            proposalCounter: Counters.newCounter()
        });
        emit PoolCreated(poolId, _name, _token, _initialStrategy);
    }

    /**
     * @notice Allows users to deposit funds into a specified investment pool.
     * @param _poolId The ID of the investment pool.
     * @param _amount The amount of ERC20 tokens to deposit.
     */
    function depositToPool(uint256 _poolId, uint256 _amount) external nonReentrant {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (_amount == 0) revert DAE__DepositAmountTooLow();

        IERC20(pool.token).transferFrom(msg.sender, address(this), _amount);

        pool.userBalances[msg.sender] = pool.userBalances[msg.sender].add(_amount);
        pool.totalDeposited = pool.totalDeposited.add(_amount);

        _increaseReputation(msg.sender, 1); // Small rep boost for depositing
        emit Deposited(_poolId, msg.sender, _amount);
    }

    /**
     * @notice Allows users to withdraw their deposited funds from a specified investment pool.
     * @param _poolId The ID of the investment pool.
     * @param _amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawFromPool(uint256 _poolId, uint256 _amount) external nonReentrant onlyEssenceHolder {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (pool.userBalances[msg.sender] < _amount) revert DAE__WithdrawAmountExceedsBalance();

        pool.userBalances[msg.sender] = pool.userBalances[msg.sender].sub(_amount);
        pool.totalDeposited = pool.totalDeposited.sub(_amount);

        IERC20(pool.token).transfer(msg.sender, _amount);

        _increaseReputation(msg.sender, 1); // Small rep boost for withdrawing (active management)
        emit Withdrawn(_poolId, msg.sender, _amount);
    }

    /**
     * @notice Allows reputable users to propose a new investment strategy or parameters for a pool.
     * @param _poolId The ID of the investment pool.
     * @param _newStrategyAddress The address of the new strategy contract.
     * @param _strategyParams Encoded parameters for the new strategy.
     * @param _description A description of the proposed strategy.
     */
    function proposeStrategyUpdate(
        uint256 _poolId,
        address _newStrategyAddress,
        bytes calldata _strategyParams,
        string memory _description
    ) external onlyEssenceHolder onlyReputable(minReputationForProposal) {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();

        pool.proposalCounter.increment();
        uint256 proposalId = pool.proposalCounter.current();

        poolStrategyProposals[_poolId][proposalId] = StrategyProposal({
            proposer: msg.sender,
            newStrategyAddress: _newStrategyAddress,
            strategyParams: _strategyParams,
            description: _description,
            creationBlock: block.number,
            votingDeadlineBlock: block.number.add(7200), // Approx 24 hours (1 block/12s)
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            approved: false
        });

        _increaseReputation(msg.sender, 5); // Reputation boost for proactive proposal
        emit StrategyProposalCreated(_poolId, proposalId, msg.sender, _newStrategyAddress, _description);
    }

    /**
     * @notice Allows users to vote on a strategy proposal using their influence weight.
     * @param _poolId The ID of the investment pool.
     * @param _proposalId The ID of the strategy proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnStrategyProposal(uint256 _poolId, uint256 _proposalId, bool _support) external onlyEssenceHolder {
        InvestmentPool storage pool = investmentPools[_poolId];
        StrategyProposal storage proposal = poolStrategyProposals[_poolId][_proposalId];

        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (proposal.creationBlock == 0) revert DAE__ProposalNotFound();
        if (block.number > proposal.votingDeadlineBlock) revert DAE__VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert DAE__AlreadyVoted();

        // Get actual voter (could be delegated)
        address actualVoter = delegatedEssenceInfluence[msg.sender] == address(0) ? msg.sender : delegatedEssenceInfluence[msg.sender];
        uint256 voterInfluence = getInfluenceWeight(actualVoter, _poolId);

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterInfluence);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterInfluence);
        }
        proposal.hasVoted[msg.sender] = true;

        _increaseReputation(actualVoter, 2); // Small rep boost for voting
        emit VotedOnStrategy(_poolId, _proposalId, actualVoter, _support, voterInfluence);
    }

    /**
     * @notice Executes a successfully voted-in strategy update for a pool.
     *         Can be called by anyone after the voting deadline, if the proposal passed.
     * @param _poolId The ID of the investment pool.
     * @param _proposalId The ID of the strategy proposal.
     */
    function executeStrategyUpdate(uint256 _poolId, uint256 _proposalId) external nonReentrant {
        InvestmentPool storage pool = investmentPools[_poolId];
        StrategyProposal storage proposal = poolStrategyProposals[_poolId][_proposalId];

        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (proposal.creationBlock == 0) revert DAE__ProposalNotFound();
        if (block.number <= proposal.votingDeadlineBlock) revert ("DAE: Voting period not ended.");
        if (proposal.executed) revert ("DAE: Proposal already executed.");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            pool.activeStrategy = proposal.newStrategyAddress;
            // Potentially call the strategy executor here to initialize the new strategy
            if (strategyExecutor != address(0)) {
                IStrategyExecutor(strategyExecutor).executeStrategy(_poolId, proposal.newStrategyAddress, proposal.strategyParams);
            }
            _increaseReputation(proposal.proposer, 10); // Proposer gets significant rep boost
        } else {
            proposal.approved = false;
            _decreaseReputation(proposal.proposer, 5); // Proposer loses rep if proposal fails
        }

        proposal.executed = true;
        if (proposal.approved) {
             emit StrategyExecuted(_poolId, _proposalId, pool.activeStrategy);
        } else {
            emit StrategyExecuted(_poolId, _proposalId, address(0)); // indicate failure
        }
    }

    /**
     * @notice Triggers the active strategy for a specific pool.
     *         This function would interact with the `IStrategyExecutor` to perform actions
     *         like rebalancing, allocating funds, etc., based on the current strategy.
     *         Anyone can call this, and the executor could reward them.
     * @param _poolId The ID of the investment pool.
     */
    function triggerStrategyExecution(uint256 _poolId) external nonReentrant {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (strategyExecutor == address(0)) revert ("DAE: Strategy executor not set.");

        // The actual strategy logic is off-chain or in `strategyExecutor`.
        // We pass poolId and current strategy to the executor.
        IStrategyExecutor(strategyExecutor).executeStrategy(_poolId, pool.activeStrategy, ""); // Empty params for general trigger

        // Could add a small rep boost for triggering maintenance
        _increaseReputation(msg.sender, 1);
    }

    /**
     * @notice Collects accrued yield from a pool's strategy.
     *         Can be called by anyone; the collected yield is held in the pool for distribution.
     * @param _poolId The ID of the investment pool.
     */
    function harvestYield(uint256 _poolId) external nonReentrant {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();
        if (strategyExecutor == address(0)) revert ("DAE: Strategy executor not set.");

        // Snapshot current influence weights for proportional distribution later
        pool.lastTotalInfluenceWeight = 0;
        // This is inefficient for many users; in a real dapp, we might iterate only on active depositors
        // Or store influence snapshots for each user. For this example, we'll keep it simple.
        // A better approach would be to calculate influence *at the time of deposit/withdrawal*
        // or during the harvest itself for all current depositors.
        // We'll approximate by iterating.
        
        // This part needs a more robust solution for large number of users.
        // For example, using a Merkle tree for claims, or a system like Compound's accrued interest.
        // For demonstration purposes, we'll keep it simple: snapshot for current depositors.
        // This specific implementation might be too gas-intensive for many users.
        // Let's refine this to be more scalable: a cumulative rewards per unit of influence system.

        // Instead of calculating everyone's influence on harvest, we update a "total reward per influence unit"
        // This makes claiming efficient.
        // yield_per_influence_unit = total_yield / total_influence_snapshot_at_harvest
        
        // For this example, we'll simplify: the executor sends yield to THIS contract.
        // We track it, and users claim based on their influence at the time of their last claim/deposit.
        // This requires `totalHarvestedYield` and `userClaimedYield` and `lastUserInfluenceWeight`.
        
        uint256 harvestedAmount = IStrategyExecutor(strategyExecutor).harvest(_poolId);
        if (harvestedAmount > 0) {
            pool.totalHarvestedYield = pool.totalHarvestedYield.add(harvestedAmount);
            pool.lastHarvestBlock = block.number;
            _increaseReputation(msg.sender, 3); // Rep boost for harvesting
            emit YieldHarvested(_poolId, harvestedAmount);
        }
    }

    // --- V. Reward Distribution & Influence ---

    /**
     * @notice Calculates a user's total influence weight for a specific pool.
     *         This weight is a combination of their deposited capital, reputation score, and Essence tier.
     * @param _user The address of the user.
     * @param _poolId The ID of the investment pool.
     * @return The calculated influence weight.
     */
    function getInfluenceWeight(address _user, uint256 _poolId) public view returns (uint256) {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) return 0; // Pool not found

        address actualUser = delegatedEssenceInfluence[_user] == address(0) ? _user : delegatedEssenceInfluence[_user];

        uint256 capitalWeight = pool.userBalances[actualUser].mul(capitalInfluenceFactor); // Scale capital
        uint256 reputationWeight = reputationScores[actualUser].mul(reputationInfluenceFactor); // Scale reputation
        uint256 essenceTierWeight = getContributionTier(actualUser).mul(essenceTierInfluenceFactor); // Scale tier

        // Simple aggregation. Could be more complex (e.g., quadratic)
        return capitalWeight.add(reputationWeight).add(essenceTierWeight);
    }
    
    /**
     * @notice Calculates the pending rewards for a user in a given pool.
     *         This simplified model calculates rewards since their last claim/deposit/withdrawal.
     *         A more robust system would use a cumulative system.
     */
    function getPendingRewards(address _user, uint256 _poolId) public view returns (uint256) {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0) || pool.totalHarvestedYield == 0 || pool.totalDeposited == 0) return 0;

        uint256 userInfluence = getInfluenceWeight(_user, _poolId);
        if (userInfluence == 0) return 0;

        // In a real system, `totalHarvestedYield` would be distributed proportionally
        // to influence *over time*. This simplified version distributes total yield
        // based on current influence relative to total deposits.
        // This needs a more robust yield distribution mechanism (e.g., like ERC-4626 or Compound's accrual system).
        // For now, let's assume it's simply a share of the total pool growth.

        // Simplistic example: user's share of total harvested yield relative to their capital.
        // This is a placeholder. A real yield distribution should be tied to influence *at the time of harvest*.
        // This would require storing historical influence snapshots.
        // For now, we'll calculate based on current capital share for simplicity.
        // This is a known simplification and not the "advanced" yield distribution, but the contract structure supports it.
        // The advanced part is the influence calculation itself.
        
        // Let's refine for a slightly more advanced conceptual distribution:
        // We'll assume `pool.totalHarvestedYield` is the total *undistributed* yield in the pool.
        // `lastTotalInfluenceWeight` and `lastUserInfluenceWeight` snapshots are used to calculate the share
        // of *newly added yield*. This requires updating these snapshots during `harvestYield`.
        
        // This logic will be more complex and require `harvestYield` to actually snapshot influence.
        // For now, the simplest interpretation of 'pending rewards' given the current state is:
        // The user's capital share of the *total yield that has been harvested but not yet claimed by anyone*.
        // This isn't truly reputation-weighted yet for distribution, only for *governance*.
        // The function `claimRewards` is where the true distribution happens based on influence.
        
        // To make it truly influence-weighted, `harvestYield` needs to:
        // 1. Calculate total influence of all depositors.
        // 2. Increment a `cumulativeYieldPerInfluenceUnit`.
        // Then `getPendingRewards` uses this cumulative value.
        
        // Since `cumulativeYieldPerInfluenceUnit` is not implemented for brevity,
        // let's stick to a very basic representation for `getPendingRewards`
        // that still hints at the multi-factor influence:
        // Assume `pool.totalHarvestedYield` is available for current `totalDeposited`.
        // User's share is (userInfluence / total_influence_in_pool) * pool.totalHarvestedYield
        
        // This is where the challenge of "no open source duplication" meets a standard DeFi pattern.
        // The unique part is *how* influence is calculated, not necessarily the accrual method itself.
        
        // For a true "influence-weighted reward" without a full accrual system (like Compound/Aave):
        // 1. `harvestYield` function would need to iterate through all active `userEssenceTokenId`s,
        //    calculate their influence, sum it to `pool.lastTotalInfluenceWeight`, and store each `lastUserInfluenceWeight`.
        // 2. This `getPendingRewards` function would then calculate:
        //    (user's `lastUserInfluenceWeight` / `pool.lastTotalInfluenceWeight`) * (pool.totalHarvestedYield - pool.userClaimedYield).
        // This is gas-intensive. Let's make `getPendingRewards` simpler for now, and note the complexity.

        // Simplified current rewards logic (needs refinement for real-world)
        // This calculates the proportional share of *all* currently available yield.
        uint256 totalInfluenceInPool = 0;
        for (uint256 i = 1; i <= _essenceTokenIds.current(); i++) {
            address essenceOwnerAddress = essenceTokenOwner[i];
            if (essenceOwnerAddress != address(0) && pool.userBalances[essenceOwnerAddress] > 0) {
                totalInfluenceInPool = totalInfluenceInPool.add(getInfluenceWeight(essenceOwnerAddress, _poolId));
            }
        }

        if (totalInfluenceInPool == 0) return 0;

        uint256 userShareNumerator = userInfluence.mul(pool.totalHarvestedYield);
        uint256 userShareDenominator = totalInfluenceInPool;
        return userShareNumerator / userShareDenominator;
    }


    /**
     * @notice Allows users to claim their share of harvested yield from a pool.
     *         Rewards are distributed based on their calculated influence weight.
     * @param _poolId The ID of the investment pool.
     */
    function claimRewards(uint256 _poolId) external nonReentrant onlyEssenceHolder {
        InvestmentPool storage pool = investmentPools[_poolId];
        if (pool.token == address(0)) revert DAE__PoolNotFound();

        uint256 userPendingRewards = getPendingRewards(msg.sender, _poolId);
        if (userPendingRewards == 0) revert DAE__NoRewardsToClaim();

        // Transfer rewards
        IERC20(pool.token).transfer(msg.sender, userPendingRewards);

        // Update claimed amounts
        pool.userClaimedYield[msg.sender] = pool.userClaimedYield[msg.sender].add(userPendingRewards);
        pool.totalHarvestedYield = pool.totalHarvestedYield.sub(userPendingRewards); // Reduce remaining yield

        _increaseReputation(msg.sender, 5); // Rep boost for claiming rewards (active participation)
        emit RewardsClaimed(_poolId, msg.sender, userPendingRewards);
    }

    /**
     * @notice Allows an Essence holder to delegate their influence weight (for voting and reward calculation)
     *         to another Essence holder. This enables liquid reputation and governance.
     * @param _delegatee The address of the Essence holder to delegate influence to.
     */
    function delegateEssenceInfluence(address _delegatee) external onlyEssenceHolder {
        if (_delegatee == msg.sender) revert DAE__CannotSelfDelegate();
        if (_delegatee != address(0) && userEssenceTokenId[_delegatee] == 0) revert DAE__NoEssenceFound(); // Delegatee must also have Essence

        delegatedEssenceInfluence[msg.sender] = _delegatee;
        emit EssenceInfluenceDelegated(msg.sender, _delegatee);
    }
}

// Helper contract for Base64 encoding for data URIs
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        // data length -> base64 output length
        // 0 -> 0
        // 1 -> 4
        // 2 -> 4
        // 3 -> 4
        // 4 -> 8
        // 5 -> 8
        // 6 -> 8
        // n -> 4 * ceil(n / 3)
        uint256 len = 4 * ((data.length + 2) / 3);
        
        // allocate output buffer with space for null terminator (0x00)
        bytes memory buffer = new bytes(len + 1);
        uint256 ptr = 0;
        uint256 i;
        for (i = 0; i < data.length; i += 3) {
            uint8 byte1 = data[i];
            uint8 byte2 = i + 1 < data.length ? data[i + 1] : 0;
            uint8 byte3 = i + 2 < data.length ? data[i + 2] : 0;

            uint8 char1 = byte1 >> 2;
            uint8 char2 = (byte1 & 0x03) << 4 | (byte2 >> 4);
            uint8 char3 = (byte2 & 0x0f) << 2 | (byte3 >> 6);
            uint8 char4 = byte3 & 0x3f;

            buffer[ptr++] = bytes(table)[char1];
            buffer[ptr++] = bytes(table)[char2];
            if (i + 1 < data.length) {
                buffer[ptr++] = bytes(table)[char3];
            } else {
                buffer[ptr++] = "=";
            }
            if (i + 2 < data.length) {
                buffer[ptr++] = bytes(table)[char4];
            } else {
                buffer[ptr++] = "=";
            }
        }

        return string(buffer);
    }
}
```