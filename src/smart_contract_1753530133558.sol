Okay, this is an exciting challenge! Let's design a smart contract system that goes beyond typical DeFi or NFT projects, focusing on *dynamic assets*, *AI integration (via oracles)*, *decentralized curation*, and *reputation-weighted governance*.

I'll call this protocol **"ChronoGenesis Protocol"**. It manages unique, evolving digital assets called "ChronoTokens" which represent curated, adaptive artifacts, influenced by AI, community feedback, and user interaction.

---

## ChronoGenesis Protocol: Outline & Function Summary

**Concept:** The ChronoGenesis Protocol enables the creation and management of *ChronoTokens* – dynamic, adaptive digital assets (ERC721) whose attributes and visual representation evolve over time, in response to on-chain actions, off-chain data feeds (e.g., AI analysis results), and community consensus. It features a decentralized AI oracle selection process, a community-driven challenge mechanism for AI outputs, and a reputation system that influences governance and token evolution.

**Core Components:**

1.  **ChronoToken (ERC721):** The primary evolving asset.
2.  **ESSENCE Token (ERC20):** A utility and governance token used for fees, staking, and participation.
3.  **AI Oracles:** Trusted entities (or protocols) providing curated data and analysis.
4.  **Decentralized Curation & Governance:** Community-driven processes to maintain integrity and evolve the protocol.
5.  **Reputation System:** Tracks and rewards positive participation.

---

### Function Summary

**I. Core ChronoToken Management (ERC721 & Evolution)**

1.  `constructor()`: Initializes the contract, sets up roles (ADMIN_ROLE, ORACLE_ROLE, GOVERNOR_ROLE).
2.  `mintChronoToken(string calldata initialMetadataURI)`: Mints a new ChronoToken with an initial state and metadata. Requires ESSENCE payment.
3.  `burnChronoToken(uint256 tokenId)`: Allows ChronoToken owner to burn their token.
4.  `evolveChronoTokenState(uint256 tokenId)`: Triggers an evolution step for a ChronoToken, potentially changing its internal state and metadata URI based on predefined rules or accumulated activity.
5.  `requestAI_CuratedTraitUpdate(uint256 tokenId, string calldata traitKey, bytes calldata contextData)`: Owner requests an AI oracle to provide a curated trait value for their token based on context.
6.  `setAI_CuratedTrait(uint256 tokenId, string calldata traitKey, string calldata traitValue, uint256 timestamp, bytes calldata signature)`: **(Oracle-only)** Callback function for registered AI oracles to submit curated trait data, potentially signed to verify authenticity.
7.  `getChronoTokenMetadataURI(uint256 tokenId) view returns (string memory)`: Returns the current dynamic metadata URI for a ChronoToken, reflecting its latest state and AI-curated traits.

**II. ESSENCE Token & Staking**

8.  `mintESSENCE(address to, uint256 amount)`: **(Admin/Governor-only)** Mints new ESSENCE tokens.
9.  `burnESSENCE(uint256 amount)`: Allows users to burn their own ESSENCE tokens.
10. `stakeESSENCE_ForEvolutionBoost(uint256 tokenId, uint256 amount)`: Staking ESSENCE on a ChronoToken to accelerate its evolution or unlock premium AI curation features.
11. `unstakeESSENCE_FromEvolution(uint256 tokenId)`: Unstakes ESSENCE from a ChronoToken.

**III. AI Oracle Management & Challenges**

12. `registerAIOracle(address oracleAddress, string calldata description)`: **(Admin/Governor-only)** Registers a new AI oracle, making it eligible to submit data.
13. `deregisterAIOracle(address oracleAddress)`: **(Admin/Governor-only)** Deregisters an AI oracle.
14. `submitAIOpinionChallenge(uint256 tokenId, string calldata traitKey, string calldata reason)`: Allows any ESSENCE holder to challenge an AI-curated trait submitted by an oracle for a specific token, triggering a community vote.
15. `voteOnAIOpinionChallenge(uint256 challengeId, bool supportChallenge)`: ESSENCE holders vote on whether to uphold or reject an AI opinion challenge.
16. `resolveAIOpinionChallenge(uint256 challengeId)`: **(Governor-only or automated based on quorum)** Resolves a challenge, potentially invalidating the AI's trait and punishing the oracle, or penalizing the challenger.

**IV. Decentralized Governance (Protocol Evolution)**

17. `proposeProtocolChange(string calldata description, address target, bytes calldata callData, uint256 value)`: ESSENCE holders can propose changes to protocol parameters (e.g., fees, oracle registration rules, evolution logic).
18. `voteOnProposal(uint256 proposalId, bool support)`: ESSENCE holders vote on active proposals.
19. `executeProposal(uint256 proposalId)`: Executes a passed proposal.
20. `setProposalThreshold(uint256 newThreshold)`: **(Governor-only)** Sets the minimum ESSENCE required to create a proposal.

**V. Reputation System**

21. `updateUserReputation(address user, int256 change)`: **(Internal/Governor-only)** Adjusts a user's reputation score based on positive (e.g., successful challenges, active voting) or negative (e.g., failed challenges, malicious proposals) actions.
22. `getUserReputation(address user) view returns (int256)`: Retrieves a user's current reputation score.

**VI. Protocol Fees & Rewards**

23. `setMintingFee(uint256 newFee)`: **(Governor-only)** Sets the ESSENCE fee for minting new ChronoTokens.
24. `distributeProtocolRewards(address[] calldata recipients, uint256[] calldata amounts)`: **(Governor-only)** Distributes collected fees or newly minted ESSENCE as rewards to participants (e.g., voters, successful challengers, active stakers).

**VII. Administrative & Utility**

25. `pause()`: **(Admin-only)** Pauses critical contract functions in an emergency.
26. `unpause()`: **(Admin-only)** Unpauses the contract.
27. `setBaseChronoTokenURI(string calldata newBaseURI)`: **(Admin-only)** Sets the base URI where ChronoToken metadata is hosted (e.g., IPFS gateway).

---

## Solidity Smart Contract: ChronoGenesisProtocol.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ChronoGenesisProtocol
 * @dev A dynamic NFT (ChronoToken) system with AI-driven curation, decentralized oracle management,
 *      community challenges, and reputation-weighted governance.
 *
 * Outline & Function Summary:
 *
 * I. Core ChronoToken Management (ERC721 & Evolution)
 *    1. constructor(): Initializes roles (ADMIN_ROLE, ORACLE_ROLE, GOVERNOR_ROLE).
 *    2. mintChronoToken(string calldata initialMetadataURI): Mints a new ChronoToken.
 *    3. burnChronoToken(uint256 tokenId): Allows ChronoToken owner to burn.
 *    4. evolveChronoTokenState(uint256 tokenId): Triggers evolution based on rules/activity.
 *    5. requestAI_CuratedTraitUpdate(uint256 tokenId, string calldata traitKey, bytes calldata contextData): Owner requests AI trait update.
 *    6. setAI_CuratedTrait(uint256 tokenId, string calldata traitKey, string calldata traitValue, uint256 timestamp, bytes calldata signature): (Oracle-only) AI oracle callback.
 *    7. getChronoTokenMetadataURI(uint256 tokenId) view returns (string memory): Returns dynamic metadata URI.
 *
 * II. ESSENCE Token & Staking
 *    8. mintESSENCE(address to, uint256 amount): (Admin/Governor-only) Mints ESSENCE.
 *    9. burnESSENCE(uint256 amount): Allows users to burn ESSENCE.
 *    10. stakeESSENCE_ForEvolutionBoost(uint256 tokenId, uint256 amount): Stakes ESSENCE on ChronoToken for boost.
 *    11. unstakeESSENCE_FromEvolution(uint256 tokenId): Unstakes ESSENCE from ChronoToken.
 *
 * III. AI Oracle Management & Challenges
 *    12. registerAIOracle(address oracleAddress, string calldata description): (Admin/Governor-only) Registers new AI oracle.
 *    13. deregisterAIOracle(address oracleAddress): (Admin/Governor-only) Deregisters AI oracle.
 *    14. submitAIOpinionChallenge(uint256 tokenId, string calldata traitKey, string calldata reason): Challenges AI-curated trait.
 *    15. voteOnAIOpinionChallenge(uint256 challengeId, bool supportChallenge): Votes on an AI challenge.
 *    16. resolveAIOpinionChallenge(uint256 challengeId): (Governor-only/Automated) Resolves challenge.
 *
 * IV. Decentralized Governance (Protocol Evolution)
 *    17. proposeProtocolChange(string calldata description, address target, bytes calldata callData, uint256 value): Proposes protocol change.
 *    18. voteOnProposal(uint256 proposalId, bool support): Votes on proposals.
 *    19. executeProposal(uint256 proposalId): Executes passed proposals.
 *    20. setProposalThreshold(uint256 newThreshold): (Governor-only) Sets proposal creation threshold.
 *
 * V. Reputation System
 *    21. updateUserReputation(address user, int256 change): (Internal/Governor-only) Adjusts user reputation.
 *    22. getUserReputation(address user) view returns (int256): Retrieves reputation score.
 *
 * VI. Protocol Fees & Rewards
 *    23. setMintingFee(uint256 newFee): (Governor-only) Sets ChronoToken minting fee.
 *    24. distributeProtocolRewards(address[] calldata recipients, uint256[] calldata amounts): (Governor-only) Distributes rewards.
 *
 * VII. Administrative & Utility
 *    25. pause(): (Admin-only) Pauses contract.
 *    26. unpause(): (Admin-only) Unpauses contract.
 *    27. setBaseChronoTokenURI(string calldata newBaseURI): (Admin-only) Sets base URI for metadata.
 */
contract ChronoGenesisProtocol is ERC721, ERC20, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- ChronoToken Data Structures ---
    struct ChronoTokenData {
        uint256 lastEvolutionTimestamp;
        uint256 evolutionStage; // e.g., 0, 1, 2... higher stages unlock new features/traits
        uint256 stakedESSENCE; // ESSENCE staked on this token
        address stakedBy;      // Address that staked ESSENCE (can be token owner or another)
        mapping(string => string) aiCuratedTraits; // key-value pairs for AI-generated traits
        mapping(string => uint256) aiTraitLastUpdated; // Timestamp of last AI update for a trait
    }

    mapping(uint256 => ChronoTokenData) private _chronoTokens;
    Counters.Counter private _tokenIdCounter;
    string private _baseChronoTokenURI;

    // --- ESSENCE Token & Fees ---
    uint256 public mintingFeeESSENCE; // Fee to mint a ChronoToken, paid in ESSENCE

    // --- AI Oracle Management ---
    struct AIOracle {
        bool isRegistered;
        string description;
        uint256 lastSubmissionTimestamp;
        uint256 successfulSubmissions;
        uint256 failedSubmissions; // e.g., challenged and overturned
    }

    mapping(address => AIOracle) public aiOracles;

    // --- AI Opinion Challenges ---
    struct AIOpinionChallenge {
        uint256 tokenId;
        string traitKey;
        address challenger;
        string reason;
        uint256 creationTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool resolved;
        bool challengerWon; // True if challenge was upheld (AI trait invalidated)
        mapping(address => bool) hasVoted; // Tracks who has voted on this challenge
    }

    Counters.Counter private _challengeIdCounter;
    mapping(uint256 => AIOpinionChallenge) public aiOpinionChallenges;
    uint256 public constant CHALLENGE_VOTING_PERIOD = 3 days; // Period for community to vote on a challenge
    uint256 public constant CHALLENGE_QUORUM_PERCENT = 5; // 5% of total ESSENCE supply needed to pass/fail challenge

    // --- Governance (Proposals) ---
    struct Proposal {
        uint256 id;
        string description;
        address target;
        bytes callData;
        uint256 value;
        uint256 creationTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks who has voted on this proposal
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalThresholdESSENCE; // Minimum ESSENCE required to propose
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 10; // 10% of total ESSENCE supply needed for proposals

    // --- Reputation System ---
    mapping(address => int256) public userReputation; // Can be negative for bad actors

    // --- Events ---
    event ChronoTokenMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event ChronoTokenBurned(uint256 indexed tokenId, address indexed owner);
    event ChronoTokenEvolved(uint256 indexed tokenId, uint256 newEvolutionStage);
    event AI_CuratedTraitRequested(uint256 indexed tokenId, string traitKey, address indexed requester);
    event AI_CuratedTraitUpdated(uint256 indexed tokenId, string traitKey, string traitValue, address indexed oracleAddress);
    event ESSENCEStakedForEvolution(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ESSENCEUnstakedFromEvolution(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event AIOracleRegistered(address indexed oracleAddress, string description);
    event AIOracleDeregistered(address indexed oracleAddress);
    event AIOpinionChallengeSubmitted(uint256 indexed challengeId, uint256 indexed tokenId, string traitKey, address indexed challenger);
    event AIOpinionChallengeVoted(uint256 indexed challengeId, address indexed voter, bool supportChallenge);
    event AIOpinionChallengeResolved(uint256 indexed challengeId, bool challengerWon, address indexed resolvedBy);
    event ProtocolChangeProposed(uint256 indexed proposalId, string description, address indexed proposer);
    event ProtocolChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProtocolChangeExecuted(uint256 indexed proposalId);
    event UserReputationUpdated(address indexed user, int256 change, int256 newReputation);
    event MintingFeeUpdated(uint256 newFee);
    event ProtocolRewardsDistributed(address[] recipients, uint256[] amounts);
    event BaseChronoTokenURIUpdated(string newBaseURI);

    /**
     * @dev Constructor initializes ERC721 and ERC20 tokens, sets up roles, and initial parameters.
     * @param name_ ChronoToken name
     * @param symbol_ ChronoToken symbol
     * @param essenceName_ ESSENCE token name
     * @param essenceSymbol_ ESSENCE token symbol
     * @param initialAdmin The address to grant ADMIN_ROLE, ORACLE_ROLE, and GOVERNOR_ROLE.
     * @param initialESSENCESupply Initial supply of ESSENCE tokens to `initialAdmin`.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory essenceName_,
        string memory essenceSymbol_,
        address initialAdmin,
        uint256 initialESSENCESupply
    ) ERC721(name_, symbol_) ERC20(essenceName_, essenceSymbol_) {
        // Grant initial admin all core roles
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin);
        _grantRole(ORACLE_ROLE, initialAdmin);
        _grantRole(GOVERNOR_ROLE, initialAdmin);

        // Set initial ESSENCE supply (can be used for liquidity, initial staking, etc.)
        _mint(initialAdmin, initialESSENCESupply);

        mintingFeeESSENCE = 100 * (10 ** decimals()); // Default 100 ESSENCE fee
        proposalThresholdESSENCE = 1000 * (10 ** decimals()); // Default 1000 ESSENCE to propose
        _baseChronoTokenURI = "ipfs://QmbzG4d5eH7fG8c9kF0jL1qM2o3p4r5s6t7u8v9wXyZ/"; // Example base URI
    }

    // --- I. Core ChronoToken Management (ERC721 & Evolution) ---

    /**
     * @dev Mints a new ChronoToken.
     * Requires the caller to approve `mintingFeeESSENCE` worth of ESSENCE tokens to this contract.
     * @param initialMetadataURI The initial metadata URI for the token, usually pointing to an IPFS JSON.
     */
    function mintChronoToken(string calldata initialMetadataURI)
        external
        nonReentrant
        whenNotPaused
    {
        require(ERC20.balanceOf(msg.sender) >= mintingFeeESSENCE, "CronoGenesis: Insufficient ESSENCE balance");
        require(ERC20.allowance(msg.sender, address(this)) >= mintingFeeESSENCE, "CronoGenesis: Approve ESSENCE transfer first");

        _spendAllowance(msg.sender, address(this), mintingFeeESSENCE);

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);

        _chronoTokens[newItemId].lastEvolutionTimestamp = block.timestamp;
        _chronoTokens[newItemId].evolutionStage = 0; // Initial stage
        _chronoTokens[newItemId].aiCuratedTraits["initial_uri"] = initialMetadataURI; // Store initial URI

        emit ChronoTokenMinted(newItemId, msg.sender, initialMetadataURI);
    }

    /**
     * @dev Allows ChronoToken owner to burn their token.
     * @param tokenId The ID of the ChronoToken to burn.
     */
    function burnChronoToken(uint256 tokenId) external nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CronoGenesis: Not owner or approved");
        
        // Ensure any staked ESSENCE is returned before burning
        if (_chronoTokens[tokenId].stakedESSENCE > 0) {
            _unstakeESSENCE(tokenId, _chronoTokens[tokenId].stakedBy, _chronoTokens[tokenId].stakedESSENCE);
        }

        _burn(tokenId);
        delete _chronoTokens[tokenId]; // Clean up token data
        emit ChronoTokenBurned(tokenId, msg.sender);
    }

    /**
     * @dev Triggers an evolution step for a ChronoToken.
     * This function can incorporate various rules for evolution:
     * - Time-based: After a certain period since last evolution.
     * - Activity-based: Based on number of interactions, challenges, or staked ESSENCE.
     * - AI-driven: AI traits could influence evolution path.
     * For simplicity, this example uses a time-based condition and staking boost.
     * @param tokenId The ID of the ChronoToken to evolve.
     */
    function evolveChronoTokenState(uint256 tokenId) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoGenesis: Not owner or approved");

        ChronoTokenData storage tokenData = _chronoTokens[tokenId];
        uint256 timeSinceLastEvolution = block.timestamp - tokenData.lastEvolutionTimestamp;

        // Base evolution interval (e.g., 30 days)
        uint256 baseEvolutionInterval = 30 days;
        // Staking boost: Each 1000 ESSENCE staked reduces interval by 1 day, up to a limit
        uint256 stakingBoostDays = tokenData.stakedESSENCE.div(1000 * (10 ** decimals()));
        uint256 maxBoostDays = 20; // Max 20 days reduction
        if (stakingBoostDays > maxBoostDays) {
            stakingBoostDays = maxBoostDays;
        }
        uint256 effectiveEvolutionInterval = baseEvolutionInterval - (stakingBoostDays * 1 days);

        require(timeSinceLastEvolution >= effectiveEvolutionInterval, "ChronoGenesis: Not enough time for evolution or insufficient boost");

        tokenData.evolutionStage = tokenData.evolutionStage.add(1);
        tokenData.lastEvolutionTimestamp = block.timestamp;

        // Potentially trigger new AI requests or alter metadata based on new stage
        // For example, if stage 1, request a "rarity" trait; if stage 2, request "utility" trait.
        // This logic can be complex and depends on the specific design.
        
        emit ChronoTokenEvolved(tokenId, tokenData.evolutionStage);
    }

    /**
     * @dev Allows a ChronoToken owner to request an AI oracle to update a specific trait for their token.
     * The actual update happens via the `setAI_CuratedTrait` function called by an oracle.
     * @param tokenId The ID of the ChronoToken.
     * @param traitKey The key for the trait (e.g., "aestheticScore", "utilityFactor").
     * @param contextData Optional arbitrary data for the AI to consider (e.g., historical user interactions).
     */
    function requestAI_CuratedTraitUpdate(uint256 tokenId, string calldata traitKey, bytes calldata contextData)
        external
        whenNotPaused
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoGenesis: Not owner or approved");
        // Could add a small ESSENCE fee for requests here, or require staking ESSENCE on the token

        // In a real system, this would trigger an off-chain oracle request (e.g., Chainlink external adapter)
        // For this contract, it primarily serves as a signal and event.
        emit AI_CuratedTraitRequested(tokenId, traitKey, msg.sender);
    }

    /**
     * @dev (Oracle-only) Allows a registered AI oracle to submit a curated trait value for a ChronoToken.
     * This function would typically be called by an oracle service in response to `requestAI_CuratedTraitUpdate`.
     * @param tokenId The ID of the ChronoToken.
     * @param traitKey The key for the trait being updated.
     * @param traitValue The new value for the trait.
     * @param timestamp The timestamp of the oracle's assessment.
     * @param signature Cryptographic signature of the oracle, for advanced verification (not fully implemented here for brevity).
     */
    function setAI_CuratedTrait(uint256 tokenId, string calldata traitKey, string calldata traitValue, uint256 timestamp, bytes calldata signature)
        external
        onlyRole(ORACLE_ROLE)
        whenNotPaused
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        require(aiOracles[msg.sender].isRegistered, "ChronoGenesis: Caller is not a registered AI oracle");
        // In a real system, verify `signature` against `msg.sender` and the data.

        _chronoTokens[tokenId].aiCuratedTraits[traitKey] = traitValue;
        _chronoTokens[tokenId].aiTraitLastUpdated[traitKey] = timestamp;
        aiOracles[msg.sender].successfulSubmissions++;

        emit AI_CuratedTraitUpdated(tokenId, traitKey, traitValue, msg.sender);
    }

    /**
     * @dev Returns the current dynamic metadata URI for a ChronoToken.
     * This URI would point to an off-chain JSON file describing the token's current state,
     * including its evolution stage, staked ESSENCE, and all AI-curated traits.
     * @param tokenId The ID of the ChronoToken.
     * @return The dynamic metadata URI.
     */
    function getChronoTokenMetadataURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        
        // Construct a dynamic URI based on token ID and internal state hash/version
        // In a real application, this would pass parameters to an off-chain service
        // that generates the JSON metadata on-the-fly or retrieves a pre-generated one.
        // For simplicity, we just append a unique identifier.
        // E.g., ipfs://baseURI/tokenID_evolutionStage_checksum.json
        
        string memory tokenStateHash = keccak256(abi.encodePacked(
            _chronoTokens[tokenId].evolutionStage,
            _chronoTokens[tokenId].stakedESSENCE,
            _chronoTokens[tokenId].lastEvolutionTimestamp
            // Could include all AI traits here for a more precise hash
        )).toHexString();

        // This is a simplified approach. A full implementation would involve:
        // 1. Storing trait updates directly on IPFS/Arweave.
        // 2. The base URI pointing to a gateway that can dynamically compose JSON.
        // For now, it's just a placeholder reflecting dynamism.
        return string(abi.encodePacked(
            _baseChronoTokenURI,
            tokenId.toString(),
            "/state/",
            tokenStateHash,
            ".json"
        ));
    }

    // Overrides required by ERC721 to use our custom _tokenURI
    function _baseURI() internal view override returns (string memory) {
        return _baseChronoTokenURI;
    }

    // --- II. ESSENCE Token & Staking ---

    /**
     * @dev Mints new ESSENCE tokens. Callable only by ADMIN_ROLE or GOVERNOR_ROLE.
     * This might be used for initial distribution, rewards, or liquidity provisions.
     * @param to The recipient address.
     * @param amount The amount of ESSENCE to mint.
     */
    function mintESSENCE(address to, uint256 amount) external onlyRole(ADMIN_ROLE) onlyRole(GOVERNOR_ROLE) {
        // This function has two roles, meaning *either* ADMIN or GOVERNOR can call it.
        // If meant to be *both* (AND logic), it needs a custom modifier.
        // For simplicity, let's assume either can mint for now.
        _mint(to, amount);
    }

    /**
     * @dev Allows a user to burn their own ESSENCE tokens.
     * This can be used for deflationary mechanics or to remove voting power.
     * @param amount The amount of ESSENCE to burn.
     */
    function burnESSENCE(uint256 amount) external nonReentrant whenNotPaused {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Stakes ESSENCE on a ChronoToken. Staking boosts the token's evolution rate.
     * Requires the caller to approve the ESSENCE amount to this contract first.
     * @param tokenId The ID of the ChronoToken to stake on.
     * @param amount The amount of ESSENCE to stake.
     */
    function stakeESSENCE_ForEvolutionBoost(uint256 tokenId, uint256 amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        require(amount > 0, "ChronoGenesis: Amount must be greater than zero");
        require(ERC20.balanceOf(msg.sender) >= amount, "CronoGenesis: Insufficient ESSENCE balance");
        require(ERC20.allowance(msg.sender, address(this)) >= amount, "CronoGenesis: Approve ESSENCE transfer first");

        _spendAllowance(msg.sender, address(this), amount);

        _chronoTokens[tokenId].stakedESSENCE = _chronoTokens[tokenId].stakedESSENCE.add(amount);
        _chronoTokens[tokenId].stakedBy = msg.sender; // Tracks the last staker
        
        emit ESSENCEStakedForEvolution(tokenId, msg.sender, amount);
    }

    /**
     * @dev Unstakes ESSENCE from a ChronoToken. Only the original staker can unstake.
     * @param tokenId The ID of the ChronoToken to unstake from.
     */
    function unstakeESSENCE_FromEvolution(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        ChronoTokenData storage tokenData = _chronoTokens[tokenId];
        require(tokenData.stakedBy == msg.sender, "ChronoGenesis: Not the original staker for this token");
        require(tokenData.stakedESSENCE > 0, "ChronoGenesis: No ESSENCE staked on this token");

        _unstakeESSENCE(tokenId, msg.sender, tokenData.stakedESSENCE);
    }

    /**
     * @dev Internal function to handle ESSENCE unstaking logic.
     */
    function _unstakeESSENCE(uint255 tokenId, address staker, uint256 amount) internal {
        _chronoTokens[tokenId].stakedESSENCE = 0; // Clear staked amount
        _chronoTokens[tokenId].stakedBy = address(0); // Clear staker
        _transfer(address(this), staker, amount); // Transfer ESSENCE back

        emit ESSENCEUnstakedFromEvolution(tokenId, staker, amount);
    }

    // --- III. AI Oracle Management & Challenges ---

    /**
     * @dev Registers a new AI oracle. Only ADMIN_ROLE or GOVERNOR_ROLE.
     * Registered oracles can call `setAI_CuratedTrait`.
     * @param oracleAddress The address of the new AI oracle.
     * @param description A description of the oracle (e.g., "OpenAI Integration", "Custom ML Model").
     */
    function registerAIOracle(address oracleAddress, string calldata description)
        external
        onlyRole(ADMIN_ROLE)
        onlyRole(GOVERNOR_ROLE)
        whenNotPaused
    {
        require(!aiOracles[oracleAddress].isRegistered, "ChronoGenesis: Oracle already registered");
        _grantRole(ORACLE_ROLE, oracleAddress); // Grant the ORACLE_ROLE
        aiOracles[oracleAddress] = AIOracle({
            isRegistered: true,
            description: description,
            lastSubmissionTimestamp: 0,
            successfulSubmissions: 0,
            failedSubmissions: 0
        });
        emit AIOracleRegistered(oracleAddress, description);
    }

    /**
     * @dev Deregisters an AI oracle. Only ADMIN_ROLE or GOVERNOR_ROLE.
     * @param oracleAddress The address of the AI oracle to deregister.
     */
    function deregisterAIOracle(address oracleAddress)
        external
        onlyRole(ADMIN_ROLE)
        onlyRole(GOVERNOR_ROLE)
    {
        require(aiOracles[oracleAddress].isRegistered, "ChronoGenesis: Oracle not registered");
        _revokeRole(ORACLE_ROLE, oracleAddress); // Revoke the ORACLE_ROLE
        delete aiOracles[oracleAddress]; // Clear oracle data
        emit AIOracleDeregistered(oracleAddress);
    }

    /**
     * @dev Allows any ESSENCE holder to challenge an AI-curated trait.
     * This initiates a community vote on the validity of the AI's output.
     * Requires a small ESSENCE stake to prevent spam (not implemented here for brevity).
     * @param tokenId The ID of the ChronoToken with the challenged trait.
     * @param traitKey The key of the trait being challenged.
     * @param reason A brief explanation for the challenge.
     */
    function submitAIOpinionChallenge(uint256 tokenId, string calldata traitKey, string calldata reason)
        external
        nonReentrant
        whenNotPaused
    {
        require(_exists(tokenId), "ChronoGenesis: Token does not exist");
        require(bytes(_chronoTokens[tokenId].aiCuratedTraits[traitKey]).length > 0, "ChronoGenesis: Trait not found or not AI-curated");
        require(balanceOf(msg.sender) >= 1, "ChronoGenesis: Must hold ESSENCE to challenge"); // Simple check

        _challengeIdCounter.increment();
        uint256 challengeId = _challengeIdCounter.current();

        aiOpinionChallenges[challengeId] = AIOpinionChallenge({
            tokenId: tokenId,
            traitKey: traitKey,
            challenger: msg.sender,
            reason: reason,
            creationTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            resolved: false,
            challengerWon: false
        });

        emit AIOpinionChallengeSubmitted(challengeId, tokenId, traitKey, msg.sender);
    }

    /**
     * @dev Allows ESSENCE holders to vote on an active AI opinion challenge.
     * Voting power is proportional to ESSENCE holdings.
     * @param challengeId The ID of the challenge.
     * @param supportChallenge True if supporting the challenger (i.e., AI output is wrong), false otherwise.
     */
    function voteOnAIOpinionChallenge(uint256 challengeId, bool supportChallenge)
        external
        nonReentrant
        whenNotPaused
    {
        AIOpinionChallenge storage challenge = aiOpinionChallenges[challengeId];
        require(challenge.challenger != address(0), "ChronoGenesis: Challenge does not exist");
        require(!challenge.resolved, "ChronoGenesis: Challenge already resolved");
        require(block.timestamp <= challenge.creationTimestamp + CHALLENGE_VOTING_PERIOD, "ChronoGenesis: Voting period ended");
        require(!challenge.hasVoted[msg.sender], "ChronoGenesis: Already voted on this challenge");
        uint256 voterESSENCE = balanceOf(msg.sender);
        require(voterESSENCE > 0, "ChronoGenesis: Must hold ESSENCE to vote");

        challenge.hasVoted[msg.sender] = true;
        if (supportChallenge) {
            challenge.votesFor = challenge.votesFor.add(voterESSENCE);
        } else {
            challenge.votesAgainst = challenge.votesAgainst.add(voterESSENCE);
        }
        emit AIOpinionChallengeVoted(challengeId, msg.sender, supportChallenge);
    }

    /**
     * @dev Resolves an AI opinion challenge once the voting period ends or quorum is met.
     * If the challenger wins, the AI trait is invalidated and the oracle's reputation is affected.
     * Callable by GOVERNOR_ROLE or automatically after voting period.
     * @param challengeId The ID of the challenge to resolve.
     */
    function resolveAIOpinionChallenge(uint256 challengeId)
        external
        nonReentrant
        onlyRole(GOVERNOR_ROLE) // Or add automated logic
    {
        AIOpinionChallenge storage challenge = aiOpinionChallenges[challengeId];
        require(challenge.challenger != address(0), "ChronoGenesis: Challenge does not exist");
        require(!challenge.resolved, "ChronoGenesis: Challenge already resolved");
        require(block.timestamp > challenge.creationTimestamp + CHALLENGE_VOTING_PERIOD, "ChronoGenesis: Voting period not ended");

        uint256 totalESSENCESupply = totalSupply();
        uint256 requiredQuorum = totalESSENCESupply.mul(CHALLENGE_QUORUM_PERCENT).div(100);

        // Check if enough votes were cast to meet quorum
        require(challenge.votesFor.add(challenge.votesAgainst) >= requiredQuorum, "ChronoGenesis: Quorum not met");

        challenge.resolved = true;
        address oracleAddress = _getOracleForTrait(challenge.tokenId, challenge.traitKey); // Helper to get the oracle who set the trait

        if (challenge.votesFor > challenge.votesAgainst) {
            // Challenger wins: Invalidate AI trait, penalize oracle, reward challenger
            challenge.challengerWon = true;
            delete _chronoTokens[challenge.tokenId].aiCuratedTraits[challenge.traitKey]; // Remove the disputed trait
            if (oracleAddress != address(0) && aiOracles[oracleAddress].isRegistered) {
                aiOracles[oracleAddress].failedSubmissions++;
                updateUserReputation(oracleAddress, -10); // Penalize oracle reputation
            }
            updateUserReputation(challenge.challenger, 10); // Reward challenger reputation
        } else {
            // Challenger loses: AI trait remains, penalize challenger (optional)
            challenge.challengerWon = false;
            updateUserReputation(challenge.challenger, -5); // Penalize challenger reputation
        }
        emit AIOpinionChallengeResolved(challengeId, challenge.challengerWon, msg.sender);
    }

    /**
     * @dev Internal helper to find which oracle set a specific trait.
     * This is a simplification; a real system might store oracle ID with each trait.
     */
    function _getOracleForTrait(uint256 tokenId, string memory traitKey) internal view returns (address) {
        // This is a placeholder. A robust system would need to store which oracle submitted which trait.
        // For example, by mapping (tokenId, traitKey) => oracleAddress or storing `oracleAddress` inside ChronoTokenData.aiCuratedTraits
        // As it stands, it's not directly possible without more detailed storage.
        // For demonstration, we'll return a dummy address or require an external mapping.
        // Let's assume for this example that the `aiTraitLastUpdated` could be used to infer,
        // but it's not a direct mapping to the oracle.
        // For now, it will return address(0), implying no direct oracle punishment without explicit tracking.
        return address(0);
    }


    // --- IV. Decentralized Governance (Protocol Evolution) ---

    /**
     * @dev ESSENCE holders can propose changes to protocol parameters or actions.
     * @param description A description of the proposed change.
     * @param target The contract address that the proposal will call.
     * @param callData The encoded function call (e.g., `abi.encodeWithSignature("setMintingFee(uint256)", newFee)`).
     * @param value The amount of ETH (or other native token) to send with the call (0 for most proposals).
     */
    function proposeProtocolChange(string calldata description, address target, bytes calldata callData, uint256 value)
        external
        nonReentrant
        whenNotPaused
    {
        require(balanceOf(msg.sender) >= proposalThresholdESSENCE, "ChronoGenesis: Not enough ESSENCE to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            target: target,
            callData: callData,
            value: value,
            creationTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProtocolChangeProposed(proposalId, description, msg.sender);
    }

    /**
     * @dev ESSENCE holders vote on active governance proposals.
     * Voting power is proportional to ESSENCE holdings.
     * @param proposalId The ID of the proposal.
     * @param support True to vote for the proposal, false to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool support)
        external
        nonReentrant
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ChronoGenesis: Proposal does not exist");
        require(!proposal.executed, "ChronoGenesis: Proposal already executed");
        require(block.timestamp <= proposal.creationTimestamp + PROPOSAL_VOTING_PERIOD, "ChronoGenesis: Voting period ended");
        require(!proposal.hasVoted[msg.sender], "ChronoGenesis: Already voted on this proposal");
        uint256 voterESSENCE = balanceOf(msg.sender);
        require(voterESSENCE > 0, "ChronoGenesis: Must hold ESSENCE to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterESSENCE);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterESSENCE);
        }
        emit ProtocolChangeVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a passed governance proposal. Only callable by GOVERNOR_ROLE.
     * Requires the voting period to have ended and the proposal to have passed quorum.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId)
        external
        nonReentrant
        onlyRole(GOVERNOR_ROLE)
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ChronoGenesis: Proposal does not exist");
        require(!proposal.executed, "ChronoGenesis: Proposal already executed");
        require(block.timestamp > proposal.creationTimestamp + PROPOSAL_VOTING_PERIOD, "ChronoGenesis: Voting period not ended");

        uint256 totalESSENCESupply = totalSupply();
        uint256 requiredQuorum = totalESSENCESupply.mul(PROPOSAL_QUORUM_PERCENT).div(100);

        require(proposal.votesFor.add(proposal.votesAgainst) >= requiredQuorum, "ChronoGenesis: Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "ChronoGenesis: Proposal did not pass");

        proposal.passed = true;
        proposal.executed = true;

        // Execute the proposed action
        (bool success,) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "ChronoGenesis: Proposal execution failed");

        emit ProtocolChangeExecuted(proposalId);
    }

    /**
     * @dev Sets the minimum ESSENCE required to create a new governance proposal.
     * Only callable by GOVERNOR_ROLE.
     * @param newThreshold The new ESSENCE threshold.
     */
    function setProposalThreshold(uint256 newThreshold) external onlyRole(GOVERNOR_ROLE) {
        proposalThresholdESSENCE = newThreshold;
    }

    // --- V. Reputation System ---

    /**
     * @dev Updates a user's reputation score. This function is typically called internally
     * after specific protocol actions (e.g., successful votes, challenge outcomes).
     * Can also be called by GOVERNOR_ROLE for manual adjustments.
     * @param user The address of the user whose reputation is being updated.
     * @param change The amount to add to the reputation (can be negative).
     */
    function updateUserReputation(address user, int256 change)
        internal
        // Only internal calls or specific roles can modify
        // For external access, it should be `onlyRole(GOVERNOR_ROLE)`
        // `external` if `onlyRole(GOVERNOR_ROLE)` else `internal`
    {
        userReputation[user] += change;
        emit UserReputationUpdated(user, change, userReputation[user]);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) external view returns (int256) {
        return userReputation[user];
    }

    // --- VI. Protocol Fees & Rewards ---

    /**
     * @dev Sets the ESSENCE fee for minting new ChronoTokens.
     * Only callable by GOVERNOR_ROLE.
     * @param newFee The new minting fee in ESSENCE.
     */
    function setMintingFee(uint256 newFee) external onlyRole(GOVERNOR_ROLE) {
        mintingFeeESSENCE = newFee;
        emit MintingFeeUpdated(newFee);
    }

    /**
     * @dev Distributes collected protocol fees or newly minted ESSENCE as rewards.
     * Only callable by GOVERNOR_ROLE.
     * This allows the DAO to manage the protocol's treasury and incentivize participation.
     * @param recipients An array of addresses to receive rewards.
     * @param amounts An array of corresponding amounts for each recipient.
     */
    function distributeProtocolRewards(address[] calldata recipients, uint256[] calldata amounts)
        external
        nonReentrant
        onlyRole(GOVERNOR_ROLE)
    {
        require(recipients.length == amounts.length, "ChronoGenesis: Mismatched array lengths");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(address(this), recipients[i], amounts[i]); // Transfer from contract's ESSENCE balance
        }
        emit ProtocolRewardsDistributed(recipients, amounts);
    }

    // --- VII. Administrative & Utility ---

    /**
     * @dev Pauses the contract, preventing certain critical functions from being called.
     * Only callable by ADMIN_ROLE.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling critical functions.
     * Only callable by ADMIN_ROLE.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Sets the base URI for ChronoToken metadata.
     * This allows for updating the IPFS gateway or hosting service without changing token IDs.
     * @param newBaseURI The new base URI string (e.g., "ipfs://new_hash/").
     */
    function setBaseChronoTokenURI(string calldata newBaseURI) external onlyRole(ADMIN_ROLE) {
        _baseChronoTokenURI = newBaseURI;
        emit BaseChronoTokenURIUpdated(newBaseURI);
    }

    // --- ERC721 & ERC20 Overrides for AccessControl & Pausability ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are required by AccessControl and ERC721/ERC20.
    // They are automatically included from OpenZeppelin contracts but listed here for clarity.
    // function hasRole(bytes32 role, address account) public view virtual override returns (bool)
    // function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32)
    // function grantRole(bytes32 role, address account) public virtual override
    // function revokeRole(bytes32 role, address account) public virtual override
    // function renounceRole(bytes32 role, address account) public virtual override
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
}
```