Okay, here is a Solidity smart contract implementing a concept called "The Generative Nexus".

This contract combines several advanced and trendy concepts:
1.  **Dynamic NFTs:** Artifact traits are not static but calculated based on the NFT's "Nourishment" and the global "Nexus State". Metadata should ideally be dynamic as well (off-chain service pointed to by `tokenURI`).
2.  **Internal Point System:** Uses an internal balance ("Nourishment Points") earned via contributions (ETH/ERC20) to gate actions like generation and evolution.
3.  **Staking on NFTs:** Users can stake their Nourishment Points *on* specific Artifacts to facilitate their evolution.
4.  **Generative Mechanics:** Artifact traits are derived algorithmically based on input parameters (seed, nourishment, global state) potentially incorporating randomness.
5.  **Global State Influence:** A "Nexus State" variable changes based on total activity or admin actions, influencing the generation/evolution process for *all* artifacts.
6.  **Simple Decentralized Influence:** A basic voting mechanism allows users (based on Nourishment/Artifact ownership) to propose and vote on changes to Nexus parameters.
7.  **Delegation:** Users can delegate their Nourishment points (which grant voting power) to others.
8.  **Randomness Integration:** Designed to integrate with an oracle like Chainlink VRF for truly unpredictable trait generation or evolution outcomes.
9.  **Burning Mechanics:** Burning an artifact yields a partial return or other unique effect.

It aims to be distinct from standard ERC-20/ERC-721 implementations or simple staking/farming pools by focusing on a creative, interactive generative process tied to token mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary ---
/*
Contract: The Generative Nexus

Purpose: Manages user contributions to a shared "Nexus State" via Nourishment Points,
         enabling the generation and dynamic evolution of unique "Artifact" NFTs.

State Variables:
- owner: Contract deployer.
- paused: System wide pause flag.
- totalNourishment: Global pool of accumulated nourishment.
- nourishmentBalance: User's current free nourishment points.
- stakedNourishment: Nourishment points staked on specific artifacts.
- nexusState: Global parameters influencing generation/evolution.
- artifactData: Stores non-standard data for each artifact (evolution state, last nourished time).
- artifactEvolutionHistory: Stores history of evolution events per artifact.
- userArtifacts: Maps user addresses to lists of their artifact TokenIds (for easy query).
- vrfCoordinator, keyHash, fee: Chainlink VRF configuration (simplified).
- requests: Maps VRF request IDs to context data (tokenId, action type).
- artifactCount: Counter for unique token IDs.
- genesisTimestamp: Timestamp of contract deployment.
- traitMetadataMapping: Mapping for simple trait -> description (conceptual).
- nourishmentContributionRate: Rate for converting ETH/ERC20 to nourishment.
- artifactGenerationCost: Nourishment cost to mint an artifact.
- artifactEvolutionCostBase: Base nourishment cost to evolve.
- artifactBurnRefundRate: Percentage of staked nourishment returned on burn.
- delegatedNourishment: Tracks delegated nourishment/voting power.
- voteProposals: Tracks open vote proposals.
- userVotes: Tracks user votes on proposals.

Events:
- NourishmentContributed: Log when a user contributes.
- ArtifactGenerated: Log when an artifact is minted.
- ArtifactNourished: Log when nourishment is staked on an artifact.
- ArtifactEvolutionRequested: Log when evolution is requested (potentially includes VRF request ID).
- ArtifactEvolved: Log when evolution is finalized (usually after randomness fulfillment).
- ArtifactBurned: Log when an artifact is burned.
- NexusStateShift: Log when global Nexus state changes.
- VoteProposed: Log when a vote proposal is created.
- Voted: Log when a user casts a vote.
- VoteExecuted: Log when a vote proposal is executed.
- NourishmentDelegated: Log when delegation occurs.
- FundsWithdrawn: Log owner withdrawals.
- ParametersUpdated: Log changes to system parameters.

Functions (27+ total, including standard ERC721 mocks):

// --- Standard ERC721 Mock (Basic Implementation for Example) ---
- balanceOf(owner): Get balance of NFTs for an address.
- ownerOf(tokenId): Get owner of an NFT.
- safeTransferFrom(from, to, tokenId): Transfer NFT safely.
- transferFrom(from, to, tokenId): Transfer NFT (less safe version).
- approve(to, tokenId): Approve transfer for a specific token.
- setApprovalForAll(operator, approved): Set approval for all tokens to an operator.
- getApproved(tokenId): Get approved address for a token.
- isApprovedForAll(owner, operator): Check if operator is approved for all.

// --- Core User Interaction ---
- contributeNourishment(): User sends ETH to earn nourishment points.
- withdrawContribution(amount): User withdraws unused deposited ETH.
- generateArtifact(seed): User mints a new Artifact NFT using nourishment points, potentially requiring randomness.
- nourishArtifact(tokenId, amount): User stakes nourishment points on their artifact.
- claimStakedNourishment(tokenId): User unstakes nourishment from their artifact.
- requestArtifactEvolution(tokenId): User initiates the evolution process for their artifact, potentially requiring randomness.
- burnArtifact(tokenId): User burns their artifact for a benefit.

// --- Oracle Callbacks (e.g., Chainlink VRF) ---
- fulfillRandomness(requestId, randomWords): Callback to finalize operations needing randomness (generation, evolution).

// --- Querying Data ---
- getUserNourishment(user): Get a user's free nourishment balance.
- getArtifactNourishment(tokenId): Get nourishment staked on an artifact.
- getArtifactTraits(tokenId): Get the CURRENT (dynamic) traits of an artifact.
- getTokenURI(tokenId): Get the metadata URI for an artifact (should point to dynamic metadata).
- getNexusState(): Get the current global nexus state parameters.
- getUserArtifacts(user): List token IDs owned by a user.
- getTotalArtifactsMinted(): Get the total number of artifacts minted.
- predictArtifactTraits(seed, nourishmentAmount): View function to simulate trait generation.
- getArtifactEvolutionHistory(tokenId): Retrieve the evolution history of an artifact.
- getRequiredNourishmentForNextEvolution(tokenId): Get nourishment needed for the next evolution stage.
- getTimeSinceLastNourishment(tokenId): Get time elapsed since last nourishment action on an artifact.
- getTraitDescription(traitType, traitValue): Get a human-readable description for a trait value.
- getVotingPower(user): Get user's current voting power (tied to nourishment).
- getVoteProposal(proposalId): Get details of a specific vote proposal.

// --- Decentralized Influence / Voting ---
- voteOnNexusParameter(proposalId, supports): User casts a vote on a proposal.
- delegateNourishment(delegatee): User delegates their voting power.

// --- System Management (Owner Functions) ---
- setNourishmentContributionRate(rate): Set the rate for converting ETH to nourishment.
- setArtifactCosts(generationCost, evolutionCostBase, burnRefundRate): Set costs and refunds.
- setNexusStateParameter(paramIndex, value): Manually update a specific Nexus state parameter.
- pauseContract(state): Pause/unpause core contract functions.
- withdrawProtocolFunds(tokenAddress, amount): Owner withdraws protocol revenue (e.g., collected ETH).
- grantNourishment(to, amount): Owner grants nourishment points.
- revokeNourishment(from, amount): Owner revokes nourishment points.
- triggerGlobalNexusShift(): Owner or system triggers a global Nexus state update based on accumulated activity.
- setRandomnessConfig(vrfCoordinator, keyHash, fee): Configure VRF oracle.
- executeNexusParameterVote(proposalId): Owner or authorized entity executes a passed vote proposal.
- createNexusParameterVoteProposal(paramIndex, newValue, description): Owner creates a vote proposal.
- cancelVoteProposal(proposalId): Owner cancels an active vote proposal.
- setBaseTokenURI(uri): Set the base URI for metadata.

// --- Internal Helper Functions ---
- _mint(to, tokenId): Internal minting logic.
- _transfer(from, to, tokenId): Internal transfer logic.
- _burn(tokenId): Internal burn logic.
- _generateInitialTraits(seed, userNourishment, currentNexusState): Internal trait generation logic.
- _calculateDynamicTraits(tokenId): Internal logic to calculate traits based on artifact state and global state.
- _updateNexusState(totalNourishmentAdded): Internal logic to update global state based on activity.
- _getArtifactVotingPower(tokenId): Internal function to calculate voting power from an artifact.
- _getUserContributionValue(user): Internal function to track user's total ETH/value contributed. (Needs state variable: `userTotalContributions`)
*/

// Mock or include interfaces for external contracts like ERC721 and Chainlink VRF
// In a real scenario, you'd use OpenZeppelin for ERC721 and Chainlink interfaces.

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface LinkTokenInterface {
    function transferAndCall(address _receiver, uint256 _amount, bytes calldata _data) external returns (bool);
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint32 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        bytes calldata extraArgs
    ) external returns (uint256 requestId);

    function addConsumer(uint32 subId, address consumer) external;
    function removeConsumer(uint32 subId, address consumer) external;
}

abstract contract VRFConsumerBaseV2 {
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;
}


contract GenerativeNexus is IERC721, VRFConsumerBaseV2 {

    // --- State Variables ---

    address public owner;
    bool public paused = false;

    // Nexus State Parameters (example: influences rarity, visuals, required evolution actions)
    // Use a simple array or struct for parameters
    uint256[5] public nexusState; // Example: [EntropyLevel, MutationFactor, StabilityThreshold, GrowthFactor, ReservedParameter]

    // Nourishment System
    mapping(address => uint256) private nourishmentBalance; // User's free nourishment points
    mapping(uint256 => uint256) private stakedNourishment; // Nourishment staked on artifact tokenId
    uint256 public totalNourishment = 0; // Global accumulated nourishment
    mapping(address => uint256) private userTotalContributions; // Track user's total ETH/value contributed

    // Artifact Data (ERC721 extensions)
    struct ArtifactData {
        uint256 creationSeed; // Seed used for initial generation
        uint8 evolutionStage; // Current evolution stage (0 = Genesis)
        uint256 lastNourishedTimestamp; // When nourishment was last added or removed
        uint256 totalNourishmentStakedHistory; // Sum of all nourishment ever staked (can influence traits)
        // Add other dynamic state relevant to this artifact
    }
    mapping(uint256 => ArtifactData) private artifactData;
    mapping(uint256 => uint256[]) private artifactEvolutionHistory; // Store timestamps or states of evolution events

    // ERC721 Basic Mappings (simplified, real impl would be more robust)
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _baseTokenURI;
    uint256 private _artifactCount;

    // Randomness (Chainlink VRF simplified integration)
    VRFCoordinatorV2Interface public vrfCoordinator;
    bytes32 public keyHash;
    uint32 public s_subId; // Subscription ID
    uint16 public requestConfirmations = 3;
    uint32 public callbackGasLimit = 300000;
    uint32 public numWords = 1; // Number of random words needed

    struct RandomRequest {
        uint256 targetTokenId; // 0 for generation, tokenId for evolution
        address requestor;
        uint8 actionType; // 1: Generate, 2: Evolve
        // Add other context data needed after randomness
    }
    mapping(uint256 => RandomRequest) private requests; // request ID -> context

    // Costs & Rates
    uint256 public nourishmentContributionRate = 1 ether / 100; // 1 ETH gives 100 nourishment points
    uint256 public artifactGenerationCost = 500; // Nourishment points to generate
    uint256 public artifactEvolutionCostBase = 200; // Base cost to attempt evolution
    uint256 public artifactBurnRefundRate = 50; // Percentage of STAKED nourishment refunded on burn (50%)

    // Voting System (Simplified)
    struct VoteProposal {
        uint256 proposalId;
        uint8 targetNexusParameterIndex; // Index in the nexusState array
        uint256 newValue; // Proposed value
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted; // To track if a user has voted
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => VoteProposal) public voteProposals;
    // Need a way to get active proposals -> maybe store IDs in an array or iterate map (gas cost)
    // For simplicity, accessing by ID is assumed.
    uint256 public voteDuration = 7 days; // Duration for voting

    // Delegation System
    mapping(address => address) public delegatedNourishment; // delegatee => delegator (incorrect mapping) -> delegator => delegatee

    mapping(address => address) private _delegations; // delegator => delegatee


    // Read-only mappings for user artifacts (can be gas-intensive for large lists)
    mapping(address => uint256[]) private userArtifactTokenIds;


    // Genesis / Initial State
    uint256 public genesisTimestamp;

    // Trait Mapping (Conceptual - actual generation logic is complex)
    mapping(bytes32 => string) public traitMetadataMapping; // hash of trait data -> descriptive string


    // --- Events ---

    event NourishmentContributed(address indexed user, uint256 amountETH, uint256 nourishmentGained);
    event ContributionWithdrawn(address indexed user, uint256 amountETH);
    event ArtifactGenerated(address indexed owner, uint256 indexed tokenId, uint256 generationSeed, uint256 requestId);
    event ArtifactNourished(address indexed user, uint256 indexed tokenId, uint256 amount);
    event StakedNourishmentClaimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event ArtifactEvolutionRequested(address indexed user, uint256 indexed tokenId, uint256 requestId);
    event ArtifactEvolved(uint256 indexed tokenId, uint8 newStage, uint256 randomness);
    event ArtifactBurned(address indexed user, uint256 indexed tokenId, uint256 nourishmentRefunded);
    event NexusStateShift(uint256[5] newNexusState);
    event VoteProposed(uint256 indexed proposalId, address indexed proposer, uint8 indexed paramIndex, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool supports);
    event VoteExecuted(uint256 indexed proposalId, bool success, bool passed);
    event NourishmentDelegated(address indexed delegator, address indexed delegatee);
    event FundsWithdrawn(address indexed owner, address indexed token, uint256 amount);
    event ParametersUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event RandomnessConfigUpdated(address vrfCoordinator, bytes32 keyHash, uint32 subId, uint16 requestConfirmations, uint32 callbackGasLimit, uint32 numWords);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _subId,
        string memory initialBaseURI
    ) payable VRFConsumerBaseV2(address(_vrfCoordinator)) {
        owner = msg.sender;
        genesisTimestamp = block.timestamp;

        // Set initial Nexus state (example values)
        nexusState = [100, 50, 200, 10, 0];

        // Configure VRF
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subId = _subId;

        // Set base URI for metadata
        _baseTokenURI = initialBaseURI;

        // Note: In a real VRF setup, you'd need to fund the subscription ID (s_subId)
        // and add this contract as a consumer using a separate transaction.
    }

    // --- Core User Interaction Functions ---

    // 1. contributeNourishment()
    /// @notice User sends ETH to earn nourishment points based on the current rate.
    function contributeNourishment() public payable whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        uint256 nourishmentGained = (msg.value * nourishmentContributionRate) / 1 ether;
        require(nourishmentGained > 0, "Contribution too small");

        nourishmentBalance[msg.sender] += nourishmentGained;
        totalNourishment += nourishmentGained;
        userTotalContributions[msg.sender] += msg.value; // Track ETH value

        // Simple Nexus state update based on total nourishment
        _updateNexusState(nourishmentGained);

        emit NourishmentContributed(msg.sender, msg.value, nourishmentGained);
    }

    // 2. withdrawContribution()
    /// @notice Allows user to withdraw deposited ETH that has NOT been spent on generation or evolution.
    // This is a simplified model; a real system needs careful tracking of 'spent' ETH value vs points.
    function withdrawContribution(uint256 amount) public whenNotPaused {
         // Simplified logic: allow withdrawing up to total contribution minus value of spent points
         // A more robust system would track value spent per point or action.
         // For this example, we'll just track total contributed and assume withdrawal <= contributed - (spent_points * rate)
         // This is complex to track perfectly on-chain. A simpler model just consumes ETH directly or uses an ERC20 deposit.
         // Let's simplify: User can withdraw *any* amount up to their total contributions. This implies points are separate from the underlying value once earned.
         // Reverting to: User can withdraw unused *deposited* value. The points are earned and spent separately.

         uint256 userCurrentContributionValue = userTotalContributions[msg.sender]; // ETH value contributed
         // To determine 'unused', we need to know how much of the contributed ETH value was 'spent' via points.
         // This requires tracking the ETH-value-equivalent of points spent on generation/evolution.
         // This is too complex for this example. Let's make Nourishment a resource earned from contributions,
         // and withdrawal is just withdrawing *any* ETH from the contract balance that isn't reserved.
         // Or, let's track deposited ETH and let them withdraw up to that amount, regardless of points.

         // Let's assume a simpler model: Nourishment is earned, and ETH deposited sits in the contract.
         // User can withdraw UP TO their initial deposit amount if they haven't spent the corresponding points?
         // This is tricky. Let's make the withdrawal function for the owner to withdraw *protocol* revenue,
         // and user 'spending' points just consumes the points, not necessarily tied to a specific deposited ETH amount anymore.
         // Let's remove user withdrawal of *contribution* and add owner withdrawal of *protocol fees*. (Done in Admin section)

         revert("Contribution withdrawal not implemented in this simplified model. Points are consumed, not exchanged back for ETH.");
    }


    // 3. generateArtifact()
    /// @notice Mints a new artifact NFT for the caller using nourishment points. Requires randomness.
    /// @param seed A user-provided seed to influence generation (combined with randomness).
    function generateArtifact(uint256 seed) public whenNotPaused {
        require(nourishmentBalance[msg.sender] >= artifactGenerationCost, "Not enough nourishment to generate");
        require(_balances[msg.sender] < 100, "Max 100 artifacts per user (example limit)"); // Example limit

        // Deduct cost
        nourishmentBalance[msg.sender] -= artifactGenerationCost;

        // Request randomness for generation
        uint256 requestId = requestRandomWords(keyHash, s_subId, requestConfirmations, callbackGasLimit, numWords);

        // Store request context
        requests[requestId] = RandomRequest({
            targetTokenId: 0, // 0 signifies new generation
            requestor: msg.sender,
            actionType: 1 // 1: Generate
             // potentially include the seed here too
        });

        // Note: The actual minting happens in fulfillRandomness after getting the random word.
        // This prevents front-running the randomness.

        emit ArtifactGenerationRequested(msg.sender, 0, seed, requestId); // Emit early event
    }

    // 4. nourishArtifact()
    /// @notice Stakes nourishment points on a specific artifact NFT owned by the caller.
    /// @param tokenId The ID of the artifact to nourish.
    /// @param amount The amount of nourishment points to stake.
    function nourishArtifact(uint256 tokenId, uint256 amount) public whenNotPaused {
        require(_owners[tokenId] == msg.sender, "Not artifact owner");
        require(amount > 0, "Amount must be positive");
        require(nourishmentBalance[msg.sender] >= amount, "Not enough free nourishment");

        nourishmentBalance[msg.sender] -= amount;
        stakedNourishment[tokenId] += amount;
        artifactData[tokenId].lastNourishedTimestamp = block.timestamp;
        artifactData[tokenId].totalNourishmentStakedHistory += amount; // Track total ever staked

        emit ArtifactNourished(msg.sender, tokenId, amount);
    }

    // 5. claimStakedNourishment()
    /// @notice Unstakes nourishment points from a specific artifact NFT owned by the caller.
    /// @param tokenId The ID of the artifact to claim from.
    function claimStakedNourishment(uint256 tokenId) public whenNotPaused {
        require(_owners[tokenId] == msg.sender, "Not artifact owner");
        uint256 staked = stakedNourishment[tokenId];
        require(staked > 0, "No nourishment staked on this artifact");

        stakedNourishment[tokenId] = 0;
        nourishmentBalance[msg.sender] += staked;
        // Don't update lastNourishedTimestamp here, it tracks nourishment ADDED/STAKED
        // Don't clear totalNourishmentStakedHistory, it's cumulative history.

        emit StakedNourishmentClaimed(msg.sender, tokenId, staked);
    }

    // 6. requestArtifactEvolution()
    /// @notice Initiates an evolution attempt for an artifact, consuming nourishment and potentially requiring randomness.
    /// @param tokenId The ID of the artifact to evolve.
    function requestArtifactEvolution(uint256 tokenId) public whenNotPaused {
        require(_owners[tokenId] == msg.sender, "Not artifact owner");
        uint256 requiredNourishment = getRequiredNourishmentForNextEvolution(tokenId); // Dynamic cost
        require(stakedNourishment[tokenId] >= requiredNourishment, "Not enough nourishment staked on artifact for evolution");

        // Deduct required nourishment (from staked pool)
        stakedNourishment[tokenId] -= requiredNourishment;

        // Request randomness for evolution outcome
        uint256 requestId = requestRandomWords(keyHash, s_subId, requestConfirmations, callbackGasLimit, numWords);

        // Store request context
        requests[requestId] = RandomRequest({
            targetTokenId: tokenId,
            requestor: msg.sender,
            actionType: 2 // 2: Evolve
        });

        emit ArtifactEvolutionRequested(msg.sender, tokenId, requestId);
    }

    // 7. burnArtifact()
    /// @notice Burns an artifact NFT owned by the caller, providing a partial refund of staked nourishment.
    /// @param tokenId The ID of the artifact to burn.
    function burnArtifact(uint256 tokenId) public whenNotPaused {
        require(_owners[tokenId] == msg.sender, "Not artifact owner");

        uint256 staked = stakedNourishment[tokenId];
        uint256 refundAmount = (staked * artifactBurnRefundRate) / 100;

        if (refundAmount > 0) {
            nourishmentBalance[msg.sender] += refundAmount;
            stakedNourishment[tokenId] = 0; // Clear staked nourishment
        }

        _burn(tokenId); // Internal ERC721 burn

        emit ArtifactBurned(msg.sender, tokenId, refundAmount);
    }

    // --- Oracle Callbacks (e.g., Chainlink VRF) ---

    // 8. fulfillRandomWords()
    /// @notice Callback function from the VRF oracle once random words are available.
    /// Finalizes artifact generation or evolution.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(randomWords.length == numWords, "Incorrect number of random words");

        RandomRequest storage req = requests[requestId];
        require(req.requestor != address(0), "Request not found"); // Ensure request exists

        uint256 randomWord = randomWords[0]; // Use the first random word

        if (req.actionType == 1) { // Generation
            address recipient = req.requestor;
            uint256 newTokenId = _artifactCount + 1;

            // Mint the new artifact
            _mint(recipient, newTokenId);
            _artifactCount = newTokenId;

            // Initialize artifact data
            // Note: The generationSeed was not stored in RandomRequest in generateArtifact
            // A better pattern would be to pass it via extraArgs or store it in the request struct.
            // For this example, we'll use the randomWord as the seed for initial traits.
            artifactData[newTokenId] = ArtifactData({
                creationSeed: randomWord, // Using randomness as creation seed
                evolutionStage: 0,
                lastNourishedTimestamp: block.timestamp,
                totalNourishmentStakedHistory: 0
            });

            // Add to user's artifact list (can be gas heavy)
            userArtifactTokenIds[recipient].push(newTokenId);

            emit ArtifactGenerated(recipient, newTokenId, randomWord, requestId); // Use randomWord as effective seed
            // Note: Initial traits are calculated on demand via getArtifactTraits
        } else if (req.actionType == 2) { // Evolution
            uint256 tokenId = req.targetTokenId;
            address artifactOwner = _owners[tokenId];

            // Check if the artifact still exists and is owned by the requestor (important safety check)
            if (artifactOwner != req.requestor || _owners[tokenId] == address(0)) {
                 // Handle error: Artifact transferred or burned before fulfillment
                 // Potentially refund staked nourishment or mark as failed evolution
                 // For simplicity, we'll just log and skip
                 emit ArtifactEvolutionFailed(tokenId, "Owner changed or artifact burned");
                 delete requests[requestId]; // Clean up request
                 return;
            }


            // Check if artifact is ready to evolve based on randomness and state
            // Example logic: Requires randomness to be below a threshold influenced by Nexus State and staked nourishment
            bool evolutionSuccess = (randomWord % 1000) < (stakedNourishment[tokenId] / 10 + nexusState[1] * 5); // Example formula

            if (evolutionSuccess) {
                artifactData[tokenId].evolutionStage++;
                 // Log evolution success
                 artifactEvolutionHistory[tokenId].push(block.timestamp);
                 emit ArtifactEvolved(tokenId, artifactData[tokenId].evolutionStage, randomWord);
            } else {
                // Log evolution failure (optional, or just no event)
                 emit ArtifactEvolutionFailed(tokenId, "Evolution attempt failed based on randomness and state");
            }

            // Artifact state update (regardless of success, time progresses)
            artifactData[tokenId].lastNourishedTimestamp = block.timestamp;

        }
        // Clear the request mapping to save gas
        delete requests[requestId];
    }

     // Example event for failed evolution (add to events list)
     event ArtifactEvolutionFailed(uint256 indexed tokenId, string reason);


    // --- Querying Data Functions ---

    // 9. getUserNourishment()
    /// @notice Gets the current free nourishment point balance for a user.
    /// @param user The address of the user.
    /// @return The user's nourishment balance.
    function getUserNourishment(address user) public view returns (uint256) {
        return nourishmentBalance[user];
    }

    // 10. getArtifactNourishment()
    /// @notice Gets the amount of nourishment points currently staked on an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return The amount of staked nourishment.
    function getArtifactNourishment(uint256 tokenId) public view returns (uint256) {
        return stakedNourishment[tokenId];
    }

    // 11. getArtifactTraits()
    /// @notice Gets the CURRENT dynamic traits for an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return An array of uint256 representing the trait values.
    function getArtifactTraits(uint256 tokenId) public view returns (uint256[5] memory) {
        require(_owners[tokenId] != address(0), "Invalid artifact ID");
        return _calculateDynamicTraits(tokenId);
    }

    // 12. getTokenURI()
    /// @notice Gets the metadata URI for an artifact. Should point to a dynamic metadata service.
    /// @param tokenId The ID of the artifact.
    /// @return The metadata URI.
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Invalid artifact ID");
        // In a real dynamic NFT, this URI would include parameters
        // that an off-chain service uses to generate metadata/image on the fly
        // based on the current state from getArtifactTraits.
        // Example: `_baseTokenURI + "/metadata/" + tokenId.toString() + "?state=" + buildStateString(tokenId)`
        // This example returns a static base + ID.
        return string(abi.encodePacked(_baseTokenURI, "/", toString(tokenId)));
    }

    // 13. getNexusState()
    /// @notice Gets the current global nexus state parameters.
    /// @return An array containing the current nexus state parameters.
    function getNexusState() public view returns (uint256[5] memory) {
        return nexusState;
    }

    // 14. getUserArtifacts()
    /// @notice Lists all artifact token IDs owned by a user.
    /// @param user The address of the user.
    /// @return An array of token IDs.
    function getUserArtifacts(address user) public view returns (uint256[] memory) {
         // Note: Iterating over this array can become expensive if a user owns many tokens.
         // This pattern is acceptable for small-scale examples or off-chain indexing.
        return userArtifactTokenIds[user];
    }

    // 15. getTotalArtifactsMinted()
    /// @notice Gets the total number of artifacts ever minted.
    /// @return The total count of artifacts.
    function getTotalArtifactsMinted() public view returns (uint256) {
        return _artifactCount;
    }

    // 16. predictArtifactTraits()
    /// @notice Predicts what traits an artifact *might* have if generated with given parameters.
    /// Does NOT mint an artifact. Uses current Nexus state.
    /// @param seed The potential seed value.
    /// @param nourishmentAmount The potential user nourishment level at generation.
    /// @return An array representing the predicted trait values.
    function predictArtifactTraits(uint256 seed, uint256 nourishmentAmount) public view returns (uint256[5] memory) {
        // Simulate initial trait generation based on provided params and current nexus state
        return _generateInitialTraits(seed, nourishmentAmount, nexusState);
    }

    // 17. getArtifactEvolutionHistory()
    /// @notice Retrieves the timestamps of successful evolution events for an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return An array of timestamps.
    function getArtifactEvolutionHistory(uint256 tokenId) public view returns (uint256[] memory) {
        require(_owners[tokenId] != address(0), "Invalid artifact ID");
        return artifactEvolutionHistory[tokenId];
    }

    // 18. getRequiredNourishmentForNextEvolution()
    /// @notice Calculates the nourishment required for the next evolution stage of an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return The required nourishment amount.
    function getRequiredNourishmentForNextEvolution(uint256 tokenId) public view returns (uint256) {
        require(_owners[tokenId] != address(0), "Invalid artifact ID");
        // Example logic: Cost increases with stage
        return artifactEvolutionCostBase + (artifactData[tokenId].evolutionStage * 100);
    }

    // 19. getTimeSinceLastNourishment()
    /// @notice Gets the time elapsed in seconds since nourishment was last added or removed from an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return Time in seconds.
    function getTimeSinceLastNourishment(uint256 tokenId) public view returns (uint256) {
        require(_owners[tokenId] != address(0), "Invalid artifact ID");
        uint256 lastTime = artifactData[tokenId].lastNourishedTimestamp;
        if (lastTime == 0) return 0; // Or block.timestamp - genesisTimestamp if creation also counts
        return block.timestamp - lastTime;
    }

     // 20. getTraitDescription()
    /// @notice Gets a human-readable description for a trait type and value (conceptually).
    /// This mapping would likely be more complex, maybe using string keys or enums for trait types.
    /// @param traitTypeHash A hash or identifier for the trait type.
    /// @param traitValue The value of the trait.
    /// @return A descriptive string.
    function getTraitDescription(bytes32 traitTypeHash, uint256 traitValue) public view returns (string memory) {
        // This is a placeholder. A real system would use a more robust mapping or oracle.
        // Example: Combine type and value hash for lookup
        bytes32 key = keccak256(abi.encodePacked(traitTypeHash, traitValue));
        string memory description = traitMetadataMapping[key];
        if (bytes(description).length == 0) {
            return string(abi.encodePacked("Trait Type: ", toHexString(traitTypeHash), ", Value: ", toString(traitValue)));
        }
        return description;
    }

    // 21. getVotingPower()
    /// @notice Gets the current voting power for a user.
    /// @param user The address of the user.
    /// @return The voting power.
    function getVotingPower(address user) public view returns (uint256) {
        address delegatee = _delegations[user];
        if (delegatee != address(0) && delegatee != user) {
            // If user has delegated, they have 0 power, the delegatee has it.
            return 0;
        }

        // Voting power could be based on free nourishment + staked nourishment on owned NFTs + owned artifacts themselves.
        // Simple model: Based on free nourishment only.
        uint256 power = nourishmentBalance[user];

        // More complex model: Add staked nourishment on owned NFTs
        // This would require iterating userArtifactTokenIds and summing stakedNourishment - gas heavy.
        // Let's stick to free nourishment for simplicity in this example's on-chain voting.
        // Alternatively, bake voting power into the NFT itself and use artifact ownership.

        return power;
    }

     // 22. getVoteProposal()
    /// @notice Gets the details of a specific vote proposal.
    /// @param proposalId The ID of the proposal.
    /// @return VoteProposal struct details.
    function getVoteProposal(uint256 proposalId) public view returns (
        uint256, uint8, uint256, string memory, uint256, uint256, uint256, uint256, bool, bool
        ) {
        VoteProposal storage proposal = voteProposals[proposalId];
        require(proposal.proposalId != 0, "Invalid proposal ID");
        return (
            proposal.proposalId,
            proposal.targetNexusParameterIndex,
            proposal.newValue,
            proposal.description,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.canceled
        );
    }


    // --- Decentralized Influence / Voting Functions ---

    // 23. voteOnNexusParameter()
    /// @notice Allows a user to vote on an active Nexus state parameter proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param supports True if voting for the proposal, false if voting against.
    function voteOnNexusParameter(uint256 proposalId, bool supports) public whenNotPaused {
        VoteProposal storage proposal = voteProposals[proposalId];
        require(proposal.proposalId != 0 && !proposal.executed && !proposal.canceled, "Proposal not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period not active");

        address voter = msg.sender;
        address delegatee = _delegations[voter];
        if (delegatee != address(0) && delegatee != voter) {
             voter = delegatee; // Use delegatee's address for vote tracking if delegated FROM this sender
        }

        require(!proposal.hasVoted[voter], "Already voted on this proposal");

        uint256 votingPower = getVotingPower(voter); // Calculate voting power
        require(votingPower > 0, "No voting power");

        if (supports) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        proposal.hasVoted[voter] = true;

        emit Voted(proposalId, msg.sender, supports); // Emit with msg.sender for tracking
    }

     // 24. delegateNourishment()
     /// @notice Delegates the caller's voting power (based on nourishment) to another address.
     /// @param delegatee The address to delegate voting power to. address(0) to undelegate.
    function delegateNourishment(address delegatee) public whenNotPaused {
        require(delegatee != msg.sender, "Cannot delegate to yourself");
         _delegations[msg.sender] = delegatee;
         emit NourishmentDelegated(msg.sender, delegatee);
     }


    // --- System Management (Owner Functions) ---

    // 25. setNourishmentContributionRate()
    /// @notice Sets the rate for converting received ETH to nourishment points.
    /// @param rate The new rate (e.g., 100 for 1 ETH = 100 points, scaled by 1e18).
    function setNourishmentContributionRate(uint256 rate) public onlyOwner {
        uint256 oldRate = nourishmentContributionRate;
        nourishmentContributionRate = rate;
        emit ParametersUpdated("NourishmentContributionRate", oldRate, nourishmentContributionRate);
    }

    // 26. setArtifactCosts()
    /// @notice Sets the nourishment costs for generation and evolution, and the burn refund rate.
    function setArtifactCosts(uint256 generationCost, uint256 evolutionCostBase, uint256 burnRefundRate) public onlyOwner {
        artifactGenerationCost = generationCost;
        artifactEvolutionCostBase = evolutionCostBase;
        artifactBurnRefundRate = burnRefundRate; // Ensure valid percentage (0-100)
        emit ParametersUpdated("ArtifactCosts", 0, 0); // Simplified event
    }

    // 27. setNexusStateParameter()
    /// @notice Manually sets a specific global Nexus state parameter. Use with caution or via voting.
    /// @param paramIndex The index of the parameter to set (0-4).
    /// @param value The new value for the parameter.
    function setNexusStateParameter(uint8 paramIndex, uint256 value) public onlyOwner {
        require(paramIndex < nexusState.length, "Invalid parameter index");
        nexusState[paramIndex] = value;
        emit NexusStateShift(nexusState); // Emit general shift event
    }

    // 28. pauseContract()
    /// @notice Pauses core user interaction functions (generation, nourishment, voting).
    /// @param state True to pause, false to unpause.
    function pauseContract(bool state) public onlyOwner {
        paused = state;
         // Consider adding more granular pause states if needed
    }

    // 29. withdrawProtocolFunds()
    /// @notice Allows the owner to withdraw accumulated ETH or ERC20 tokens.
    /// @param token Address of the token (address(0) for ETH).
    /// @param amount The amount to withdraw.
    function withdrawProtocolFunds(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient contract balance");
            // Use transfer for simplicity, consider call or send for production to handle reentrancy
            (bool success, ) = payable(owner).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Assuming IERC20 interface is available and token allows transferFrom(address(this), owner, amount)
            // In a real contract accepting ERC20, you'd need to implement deposit/withdrawal logic
            // and ensure the contract has approval or holds the tokens.
            // This is a placeholder for ERC20 withdrawal.
             revert("ERC20 withdrawal not fully implemented in this example");
        }
        emit FundsWithdrawn(owner, token, amount);
    }

    // 30. grantNourishment()
    /// @notice Owner can grant nourishment points to a user.
    /// @param to The recipient address.
    /// @param amount The amount of nourishment points to grant.
    function grantNourishment(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid recipient");
        nourishmentBalance[to] += amount;
        totalNourishment += amount; // Also update global pool
         // Note: This doesn't update userTotalContributions as no ETH was sent by user.
         // Doesn't trigger _updateNexusState as it's not a user contribution.
        emit ParametersUpdated("NourishmentGranted", 0, amount); // Simplified event
    }

    // 31. revokeNourishment()
    /// @notice Owner can revoke nourishment points from a user.
    /// @param from The address to revoke from.
    /// @param amount The amount of nourishment points to revoke.
    function revokeNourishment(address from, uint256 amount) public onlyOwner {
        require(from != address(0), "Invalid address");
        require(nourishmentBalance[from] >= amount, "User does not have enough nourishment");
        nourishmentBalance[from] -= amount;
        totalNourishment -= amount; // Also update global pool
        emit ParametersUpdated("NourishmentRevoked", amount, 0); // Simplified event
    }

     // 32. triggerGlobalNexusShift()
    /// @notice Owner or system can trigger a global Nexus state update based on accumulated total nourishment.
    /// Example: Shifts state based on total Nourishment reaching milestones.
    function triggerGlobalNexusShift() public onlyOwner {
        // Example logic: Periodically shift state based on total nourishment / time
        // This could be more complex, e.g., triggered by a threshold or time elapsed.
        uint256 shiftFactor = totalNourishment / 10000; // Example calculation
        nexusState[0] = (nexusState[0] + shiftFactor) % 256; // Modulo for wrapping
        nexusState[1] = (nexusState[1] + shiftFactor / 2) % 256;
        // ... other parameter updates based on shiftFactor or other criteria ...

        emit NexusStateShift(nexusState);
    }

    // 33. setRandomnessConfig()
    /// @notice Configures the Chainlink VRF oracle settings.
    function setRandomnessConfig(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _subId,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) public onlyOwner {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subId = _subId;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
        // Note: Ensure the contract is added as a consumer to the subscription ID off-chain.
        emit RandomnessConfigUpdated(_vrfCoordinator, _keyHash, _subId, _requestConfirmations, _callbackGasLimit, _numWords);
    }


    // 34. createNexusParameterVoteProposal()
    /// @notice Owner can create a proposal for users to vote on a Nexus state parameter change.
    /// @param paramIndex The index of the parameter (0-4).
    /// @param newValue The proposed new value.
    /// @param description A description of the proposal.
    function createNexusParameterVoteProposal(uint8 paramIndex, uint256 newValue, string memory description) public onlyOwner {
        require(paramIndex < nexusState.length, "Invalid parameter index");
        uint256 proposalId = nextProposalId++;
        voteProposals[proposalId] = VoteProposal({
            proposalId: proposalId,
            targetNexusParameterIndex: paramIndex,
            newValue: newValue,
            description: description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + voteDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });
        emit VoteProposed(proposalId, msg.sender, paramIndex, newValue);
    }

     // 35. cancelVoteProposal()
    /// @notice Owner can cancel an active vote proposal.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelVoteProposal(uint256 proposalId) public onlyOwner {
        VoteProposal storage proposal = voteProposals[proposalId];
        require(proposal.proposalId != 0 && !proposal.executed && !proposal.canceled, "Proposal not active or already ended");
        proposal.canceled = true;
        // Consider refunding gas to voters if possible (complex) or just cancelling effect.
         emit VoteExecuted(proposalId, false, false); // Indicate cancellation
    }


    // 36. executeNexusParameterVote()
    /// @notice Owner or authorized entity can execute a vote proposal if the voting period is over.
    /// Requires a simple majority of votes (votesFor > votesAgainst).
    /// @param proposalId The ID of the proposal to execute.
    function executeNexusParameterVote(uint256 proposalId) public onlyOwner { // Or could be a permissioned role
        VoteProposal storage proposal = voteProposals[proposalId];
        require(proposal.proposalId != 0 && !proposal.executed && !proposal.canceled, "Proposal not active or already executed/canceled");
        require(block.timestamp > proposal.voteEndTime, "Voting period not over");

        bool passed = proposal.votesFor > proposal.votesAgainst;

        if (passed) {
             uint8 paramIndex = proposal.targetNexusParameterIndex;
             uint256 newValue = proposal.newValue;
             require(paramIndex < nexusState.length, "Invalid parameter index in proposal"); // Double check index
             nexusState[paramIndex] = newValue;
             emit NexusStateShift(nexusState);
        }

        proposal.executed = true;
        emit VoteExecuted(proposalId, true, passed);
    }


     // 37. setBaseTokenURI()
     /// @notice Sets the base URI for artifact metadata.
     function setBaseTokenURI(string memory uri) public onlyOwner {
         _baseTokenURI = uri;
     }


    // --- ERC721 Standard Functions (Simplified Mock) ---
    // These are basic implementations to fulfill the interface.
    // A production contract would inherit from a battle-tested library like OpenZeppelin.

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC165 (0x01ffc9a7) and ERC721 (0x80ac58cd) interfaces
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd;
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "Balance query for zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for nonexistent token");
        return owner_;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
     }


    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    // --- Internal Helper Functions ---

    // Internal ERC721 mint logic
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // Internal ERC721 transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Update user artifact list (can be gas heavy)
        _removeArtifactFromUserList(from, tokenId);
        userArtifactTokenIds[to].push(tokenId);


        emit Transfer(from, to, tokenId);
    }

    // Internal ERC721 burn logic
     function _burn(uint256 tokenId) internal {
         address owner_ = ownerOf(tokenId);

         // Clear approvals
         _approve(address(0), tokenId);

         _balances[owner_]--;
         _owners[tokenId] = address(0); // Set owner to zero address

         // Clean up associated data
         delete artifactData[tokenId];
         delete stakedNourishment[tokenId];
         // Keep history or clear? Let's clear for simplicity.
         delete artifactEvolutionHistory[tokenId];

         // Remove from user artifact list (can be gas heavy)
         _removeArtifactFromUserList(owner_, tokenId);

         emit Transfer(owner_, address(0), tokenId);
     }


    // Internal ERC721 approval logic
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    // Internal helper to check if an address is approved or the owner
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    // Internal helper for safe transfer check
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer for contract");
                } else {
                    /// @solidity using `ErrorMessage.trim` from the next release of solidity.
                    // revert(string(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer for contract with reason: ", reason)));
                     revert("ERC721: transfer to non ERC721Receiver implementer for contract"); // Simplified
                }
            }
        } else {
            return true; // It's an EOA, safe to transfer
        }
    }

    // Internal safe transfer logic
     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
         _transfer(from, to, tokenId);
         require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
     }


    // Internal helper to remove artifact from user's list (gas heavy, linear scan)
    function _removeArtifactFromUserList(address user, uint256 tokenId) internal {
        uint256[] storage tokenIds = userArtifactTokenIds[user];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                // Replace with last element and pop
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break; // Assuming tokenId is unique per user list
            }
        }
    }


    // Internal logic for initial trait generation (Conceptual)
    /// @dev This is a placeholder function. Real generative logic is complex.
    /// Traits are derived from seed, user state, and global state.
    function _generateInitialTraits(uint256 seed, uint256 userNourishmentAtGen, uint256[5] memory currentNexusState) internal pure returns (uint256[5] memory) {
        uint256[5] memory traits;
        // Example simple derivation:
        traits[0] = (seed + userNourishmentAtGen + currentNexusState[0]) % 255; // Trait 1 influenced by all
        traits[1] = (seed % 100) + (currentNexusState[1] % 100); // Trait 2 influenced by seed & nexus param 1
        traits[2] = (userNourishmentAtGen / 10) % 50; // Trait 3 by user nourishment
        traits[3] = (seed / 50) % 75; // Trait 4 by seed
        traits[4] = (currentNexusState[2] + currentNexusState[3]) % 150; // Trait 5 by nexus params

        // Add more complex logic here involving bit manipulation, hashing, etc.
        // Actual generative art logic is usually off-chain, this only provides parameters.

        return traits;
    }

    // Internal logic to calculate dynamic traits (Conceptual)
    /// @dev This is a placeholder function. Dynamic traits change based on artifact state and global state.
    function _calculateDynamicTraits(uint256 tokenId) internal view returns (uint256[5] memory) {
        ArtifactData storage data = artifactData[tokenId];
        uint256 currentStaked = stakedNourishment[tokenId];
        uint8 evolutionStage = data.evolutionStage;
        uint256 timeSinceNourished = block.timestamp - data.lastNourishedTimestamp;
        uint256 totalStakedHistory = data.totalNourishmentStakedHistory;

        // Start with initial traits (can be re-derived or stored if _generateInitialTraits is pure)
        // If _generateInitialTraits wasn't pure, we'd need to store initial traits.
        // Assuming for this example we *can* re-derive or that dynamic traits are entirely separate.
        // Let's make dynamic traits based on current state only.
        uint256[5] memory dynamicTraits;

        // Example dynamic derivation:
        dynamicTraits[0] = (evolutionStage * 10 + currentStaked / 50 + nexusState[0]) % 255;
        dynamicTraits[1] = (timeSinceNourished / 1 hours + nexusState[1]) % 100;
        dynamicTraits[2] = (totalStakedHistory / 100 + evolutionStage * 20) % 150;
        dynamicTraits[3] = (nexusState[2] + nexusState[3]) % 200;
        dynamicTraits[4] = (currentStaked % 100); // Trait based purely on current staked amount

        // Note: This logic determines the *numerical* values of traits.
        // The `getTokenURI` and off-chain metadata service would translate these numbers
        // into visual properties (colors, shapes, accessories, etc.).

        return dynamicTraits;
    }


    // Internal logic to update global Nexus state based on total nourishment (Conceptual)
    function _updateNexusState(uint256 nourishmentAdded) internal {
        // This function could implement complex rules for Nexus state shifts.
        // Example: Every 10000 total nourishment points, increment a state parameter.
        uint256 oldTotalNourishment = totalNourishment - nourishmentAdded; // Total before this addition
        uint256 newTotalNourishment = totalNourishment;

        // Check if a threshold was crossed
        uint256 oldThresholdLevel = oldTotalNourishment / 10000;
        uint256 newThresholdLevel = newTotalNourishment / 10000;

        if (newThresholdLevel > oldThresholdLevel) {
            // Perform a minor shift for each threshold crossed
            uint256 levelsCrossed = newThresholdLevel - oldThresholdLevel;
            for (uint i = 0; i < levelsCrossed; i++) {
                // Example shift logic: increment a parameter
                 nexusState[0] = (nexusState[0] + 1) % 256;
                 nexusState[1] = (nexusState[1] + 1) % 256;
                 // More complex logic would live here...
            }
            emit NexusStateShift(nexusState); // Emit after any shifts occur
        }

        // Could also shift based on time, number of artifacts, etc.
        // For this example, it's just based on total nourishment added by users.
    }


    // Helper function to convert uint256 to string (basic)
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert bytes32 to hex string (basic)
     function toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[i * 2 + 1] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

}

// Interface for ERC721 Receiver (required for safeTransferFrom to contracts)
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```