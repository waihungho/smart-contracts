Okay, this is an exciting challenge! Let's design a smart contract system that incorporates several advanced, creative, and trendy concepts without directly copying standard open-source implementations like basic ERC tokens, staking vaults, or simple DAOs.

We will design a decentralized *ChronicleForge* system where users can combine "Essence" tokens (ERC20) and "Artifact" NFTs (ERC721) based on on-chain "Recipes" to forge new "Chronicle" NFTs (ERC721). The interesting twists:
1.  **Dynamic Chronicle NFTs:** Chronicle NFTs will have properties that can change *after* minting, influenced by events or interactions within the system.
2.  **Oracle-Influenced Challenges:** Users can stake Essence tokens and challenge other users' Chronicle NFTs. The outcome of the challenge (and the subsequent dynamic property change of the Chronicle NFT) is determined by external data provided by a decentralized oracle.
3.  **On-chain Recipe Governance:** The rules for forging (the Recipes) are managed by a simple on-chain voting system involving Essence tokens.
4.  **Token Sinks & Stakes:** Essence tokens are consumed in crafting and locked during challenges, creating built-in token sinks and staking mechanisms.
5.  **Modular Design:** While complex, we'll define interfaces for external components (Essence, Artifact, Chronicle, Oracle) for better structure.

**Disclaimer:** This is a complex system design. Implementing it fully and securely requires multiple contracts (Essence, Artifact, Chronicle, Oracle Mock/Interface) and thorough auditing. This single file focuses on the main `ChronicleForge` contract and its logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Useful for receiving/holding NFTs temporarily

// --- Outline and Function Summary ---
//
// This contract, ChronicleForge, is the core of a decentralized crafting and challenge system.
// It manages Recipes for forging new Chronicle NFTs from Essence tokens (ERC20) and Artifact NFTs (ERC721).
// It also facilitates challenges between Chronicle NFT holders, with outcomes influenced by an Oracle.
// Essence tokens are used as crafting materials, staking for challenges, and potentially for governance voting.
// Chronicle NFTs are dynamic and their properties can change based on challenge outcomes.
//
// External Dependencies (Interfaces defined below, contracts assumed to be deployed separately):
// - IERC20: The Essence token contract.
// - IERC721: The Artifact NFT contract(s).
// - IChronicle: The Chronicle NFT contract (must allow minting/property updates by Forge).
// - IOracle: The decentralized Oracle contract (provides external data).
//
// Key Concepts:
// - On-chain Crafting: Combines ERC20 and ERC721 inputs based on defined Recipes.
// - Dynamic NFTs: Chronicle NFT properties updated post-minting.
// - Oracle Integration: External data affects challenge outcomes.
// - Token Governance: Simple voting on Recipes using Essence tokens.
// - Token Sinks: Essence burned in crafting (optional fee) and locked/distributed in challenges.
// - Role-Based Access: Owner for critical setup, Pausable for emergencies, Governance for recipes, Oracle callback.
//
// State Variables:
// - References to external token and oracle contracts.
// - Recipe storage and counter.
// - Governance proposal storage and counter.
// - Challenge storage and counter.
// - Governance parameters (voting period, quorum, min stake).
// - Fees collected (if any).
//
// Structs:
// - Recipe: Defines crafting inputs (Essence, Artifacts) and outputs (Chronicle properties).
// - Proposal: Details for adding/removing recipes, including voting state.
// - Challenge: Details for a dispute between Chronicle holders, including oracle request state and stakes.
//
// Modifiers:
// - onlyOwner, whenNotPaused, whenPaused (standard).
// - onlyOracle: Ensures callback is from the registered oracle.
// - onlyToken: Ensures function is called by a specific registered token address (for callbacks like ERC721 `onERC721Received`).
//
// Functions (26 functions):
//
// --- Admin & Setup (7) ---
// 1. constructor(): Initializes the contract, sets owner.
// 2. setEssenceToken(address _essenceToken): Sets the address of the Essence ERC20 contract.
// 3. setArtifactToken(address _artifactToken): Sets the address of the Artifact ERC721 contract. (Could extend to multiple artifact types)
// 4. setChronicleToken(address _chronicleToken): Sets the address of the Chronicle ERC721 contract.
// 5. setOracleAddress(address _oracle): Sets the address of the Oracle contract.
// 6. pause(): Pauses crafting and challenging.
// 7. unpause(): Unpauses the contract.
// 8. withdrawAdminFees(address _to): Allows owner to withdraw accumulated fees (if any).
// (Currently 8 functions including withdraw, adjusted counts below)
//
// --- Governance & Recipes (7) ---
// 9. proposeRecipe(Recipe memory _recipe): Proposes a new crafting recipe. Requires Essence stake.
// 10. proposeRemoveRecipe(uint256 _recipeId): Proposes removing an existing recipe. Requires Essence stake.
// 11. voteOnProposal(uint256 _proposalId, bool _support): Casts a vote (yes/no) on a proposal. Requires Essence stake (different or same as propose?). Let's make it stake *or* hold Essence. Voting power tied to Essence holdings.
// 12. executeProposal(uint256 _proposalId): Executes a successful proposal (adds/removes recipe).
// 13. getRecipeDetails(uint256 _recipeId): View function to get recipe details.
// 14. listRecipes(): View function to list all valid recipe IDs. (Maybe return an array or just count + getter?) Let's return count and getter.
// 15. getProposalDetails(uint256 _proposalId): View function to get proposal details.
//
// --- Crafting (3) ---
// 16. craftChronicle(uint256 _recipeId, uint256[] memory _artifactTokenIds): Executes a crafting recipe. Transfers required Essence and Artifacts, mints Chronicle NFT.
// 17. checkCraftingRequirements(uint256 _recipeId, address _crafter, uint256[] memory _artifactTokenIds): View function to check if a user can craft.
// 18. onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): ERC721 standard receiver hook. Allows the contract to receive Artifacts for crafting.
//
// --- Challenges (6) ---
// 19. proposeChallenge(uint256 _chronicleTokenId, bytes32 _oracleQueryId): Proposes a challenge on a specific Chronicle NFT. Stakes Essence.
// 20. acceptChallenge(uint256 _challengeId): Accepts a challenge proposed against your Chronicle NFT. Stakes matching Essence.
// 21. cancelChallenge(uint256 _challengeId): Cancels an open challenge before acceptance/resolution. Returns stake minus penalty.
// 22. resolveChallenge(uint256 _challengeId): Attempts to resolve a challenge. Requests oracle data if needed, then calls processChallengeResult. (Internal call, user-facing is trigger?) Let's make this internal, triggered by oracle callback. User triggers the Oracle request.
// 23. requestChallengeOracleData(uint256 _challengeId): User/automation calls this to trigger the oracle request for a challenge.
// 24. fulfillOracleRequest(bytes32 _requestId, uint256 _result, bytes memory _data): Callback from the Oracle contract. Processes the challenge outcome.
// (Adjusting counts, adding request function makes it 6)
//
// --- View Functions (General) (4) ---
// 25. listProposals(): View function to list active proposal IDs.
// 26. listChallenges(): View function to list active challenge IDs.
// 27. getTotalEssenceStaked(): View function for total Essence locked in challenges/proposals.
// 28. getChronicleProperties(uint256 _chronicleTokenId): View function to get dynamic properties of a Chronicle NFT (calls Chronicle contract).

// Total functions: 8 (Admin) + 7 (Governance) + 3 (Crafting) + 6 (Challenges) + 4 (Views) = 28 functions. This exceeds the 20 function requirement.

// --- Interfaces ---

// Interface for the Essence Token (ERC20)
interface IEssence is IERC20 {
    // Assume standard ERC20 functions: transferFrom, approve, balanceOf, etc.
    // Could add custom mint/burn if Forge mints/burns Essence.
}

// Interface for the Artifact Token (ERC721)
interface IArtifact is IERC721 {
    // Assume standard ERC721 functions: transferFrom, safeTransferFrom, ownerOf, etc.
    // Could add custom artifact properties if needed for recipes.
}

// Interface for the Chronicle Token (ERC721)
interface IChronicle is IERC721 {
    // Assume standard ERC721 functions: safeTransferFrom, ownerOf, etc.
    // Requires a function callable by the Forge to mint new NFTs.
    // Requires a function callable by the Forge to update NFT properties.
    function mint(address to, uint256 tokenId, bytes memory initialProperties) external; // Example mint function
    function updateProperties(uint256 tokenId, bytes memory updatedProperties) external; // Example update function
    function getProperties(uint256 tokenId) external view returns (bytes memory); // Example view function
    // Need modifier/access control in IChronicle to ensure only Forge can call mint/updateProperties
}

// Interface for the Oracle Contract
interface IOracle {
    // Example function to request data.
    // Oracle should call back the caller contract's fulfill function.
    function requestData(
        bytes32 _key, // A key identifying the type of data requested (e.g., "weather", "stockPrice")
        address _callbackAddress, // Address of the contract to call back
        bytes4 _callbackFunctionId, // Function signature of the callback (e.g., bytes4(keccak256("fulfillOracleRequest(bytes32,uint256,bytes)")))
        bytes memory _params // Additional parameters for the oracle query
    ) external returns (bytes32 requestId);

    // Oracle needs to be configured to only call back the registered Forge contract
}

// --- Contract Start ---

contract ChronicleForge is Ownable, Pausable, ERC721Holder {

    // --- State Variables ---

    IEssence public essenceToken;
    IArtifact public artifactToken; // Simplified: Assumes one type of artifact NFT
    IChronicle public chronicleToken;
    IOracle public oracle;
    address public adminFeeRecipient; // Address to receive fees

    // --- Recipe Management ---
    struct Recipe {
        bool isActive; // Is this recipe currently usable for crafting?
        uint256 essenceCost; // Essence tokens required
        mapping(uint256 => uint256) requiredArtifacts; // Artifact Token IDs required => quantity (for simplicity, let's assume 1 of each specified ID)
        uint256[] requiredArtifactIdsList; // To iterate easily
        bytes initialChronicleProperties; // Data encoded for initial Chronicle properties upon minting
        uint256 governanceStakeRequired; // Essence stake required to propose/vote on this recipe
    }
    mapping(uint256 => Recipe) public recipes;
    uint256 public nextRecipeId = 1; // Start recipe IDs from 1

    // --- Governance Proposals (for Recipes) ---
    enum ProposalType { AddRecipe, RemoveRecipe }
    enum ProposalState { Active, Succeeded, Failed, Executed, Cancelled }

    struct Proposal {
        uint256 recipeId; // The recipe ID being proposed (new ID for AddRecipe, existing ID for RemoveRecipe)
        ProposalType proposalType;
        uint256 submitter; // Address of the proposer
        uint256 proposalStake; // Essence staked by proposer
        uint256 voteThreshold; // Minimum votes required to succeed
        uint256 voteCount; // Current number of votes (weighted by stake?) Let's keep it simple: 1 address = 1 vote for now.
        mapping(address => bool) hasVoted; // Addresses that have already voted
        uint40 votingDeadline; // Timestamp when voting ends
        ProposalState state;
        Recipe proposedRecipeData; // Store recipe data for AddRecipe proposal
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1; // Start proposal IDs from 1
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public proposalVoteQuorum = 5; // Minimum number of votes for a proposal to pass
    uint256 public proposalStakeAmount = 100 ether; // Essence stake required to submit a proposal

    // --- Challenge System ---
    enum ChallengeState { Proposed, Accepted, OracleRequested, Resolved, Cancelled }

    struct Challenge {
        uint256 challenger; // Address of the user initiating the challenge
        uint256 challenged; // Address of the user whose Chronicle NFT is challenged
        uint256 chronicleTokenId; // The NFT being challenged
        uint256 challengerStake; // Essence staked by challenger
        uint256 challengedStake; // Essence staked by challenged (if accepted)
        bytes32 oracleQueryId; // Identifier for the specific oracle query needed for this challenge
        bytes32 oracleRequestId; // ID returned by the oracle when requestData is called
        uint40 challengeDeadline; // Timestamp by which challenge must be accepted/resolved
        ChallengeState state;
        // Future fields: specific oracle parameters, potential outcomes based on oracle result
    }
    mapping(uint256 => Challenge) public challenges;
    mapping(bytes32 => uint256) public oracleRequestIdToChallengeId; // Map oracle request IDs back to challenges
    uint256 public nextChallengeId = 1; // Start challenge IDs from 1
    uint256 public challengeAcceptancePeriod = 24 hours; // Time for challenged party to accept
    uint256 public challengeResolutionPeriod = 48 hours; // Time after oracle request to resolve
    uint256 public challengeStakeAmount = 50 ether; // Essence stake required for challenges
    uint256 public challengeCancelPenaltyPercentage = 10; // % of stake lost on cancellation

    // --- Fees ---
    uint256 public craftingFee = 1 ether; // Example: 1 Essence token fee per craft (can be 0)
    uint256 public totalCollectedFees; // Accumulated fees in Essence

    // --- Events ---

    event EssenceTokenSet(address indexed essence);
    event ArtifactTokenSet(address indexed artifact);
    event ChronicleTokenSet(address indexed chronicle);
    event OracleAddressSet(address indexed oracle);
    event AdminFeesWithdrawn(address indexed to, uint256 amount);

    event RecipeProposed(uint256 indexed proposalId, uint256 indexed recipeId, ProposalType proposalType, address indexed submitter);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState finalState);
    event RecipeAdded(uint256 indexed recipeId);
    event RecipeRemoved(uint256 indexed recipeId);

    event ChronicleCrafted(uint256 indexed recipeId, address indexed crafter, uint256 indexed chronicleTokenId);
    event CraftingFeeCollected(uint256 indexed recipeId, address indexed crafter, uint256 amount);

    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed chronicleTokenId, address indexed challenger, bytes32 oracleQueryId, uint256 stakeAmount);
    event ChallengeAccepted(uint256 indexed challengeId, address indexed challenged, uint256 stakeAmount);
    event ChallengeCancelled(uint256 indexed challengeId, address indexed canceller, uint256 penaltyAmount);
    event ChallengeOracleRequestMade(uint256 indexed challengeId, bytes32 indexed oracleRequestId);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed chronicleTokenId, uint256 oracleResult, bytes propertiesUpdateData);
    event ChallengeStakesDistributed(uint256 indexed challengeId, address winner, address loser, uint256 winnerPayout, uint256 loserReturn);

    event OracleCallbackReceived(bytes32 indexed requestId, uint256 result);

    // --- Errors ---

    error InvalidTokenAddress();
    error TokenAddressAlreadySet();
    error OracleAddressAlreadySet();
    error FeeRecipientZeroAddress();
    error TokenTransferFailed();
    error NotRecipeOwner(); // Not used with governance
    error RecipeDoesNotExist(uint256 recipeId);
    error RecipeNotActive(uint256 recipeId);
    error InsufficientEssence(uint256 required, uint256 has);
    error InsufficientArtifacts(uint256 artifactId, uint256 required, uint256 has);
    error ArtifactNotOwnedByCrafter(uint256 artifactId, address owner);
    error InvalidProposalId(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId, address voter);
    error VotingPeriodEnded(uint256 proposalId);
    error ProposalNotSucceeded(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error InvalidChallengeId(uint256 challengeId);
    error ChallengeNotInState(uint256 challengeId, ChallengeState requiredState);
    error NotChallengeParticipant(uint256 challengeId);
    error ChallengeAcceptancePeriodPassed(uint256 challengeId);
    error ChallengeResolutionPeriodPassed(uint256 challengeId);
    error OracleCallbackNotFromOracle();
    error OracleRequestFailed(bytes32 requestId);
    error ChallengeAlreadyHasOracleRequest(uint256 challengeId);
    error OracleResultProcessingFailed(uint256 challengeId);

    // --- Constructor ---

    constructor(address _adminFeeRecipient) Ownable(msg.sender) Pausable(false) {
        if (_adminFeeRecipient == address(0)) revert FeeRecipientZeroAddress();
        adminFeeRecipient = _adminFeeRecipient;
    }

    // --- Admin & Setup Functions ---

    function setEssenceToken(address _essenceToken) external onlyOwner {
        if (_essenceToken == address(0)) revert InvalidTokenAddress();
        if (address(essenceToken) != address(0)) revert TokenAddressAlreadySet();
        essenceToken = IEssence(_essenceToken);
        emit EssenceTokenSet(_essenceToken);
    }

    function setArtifactToken(address _artifactToken) external onlyOwner {
        if (_artifactToken == address(0)) revert InvalidTokenAddress();
        if (address(artifactToken) != address(0)) revert TokenAddressAlreadySet();
        artifactToken = IArtifact(_artifactToken);
        emit ArtifactTokenSet(_artifactToken);
    }

    function setChronicleToken(address _chronicleToken) external onlyOwner {
        if (_chronicleToken == address(0)) revert InvalidTokenAddress();
        if (address(chronicleToken) != address(0)) revert TokenAddressAlreadySet();
        chronicleToken = IChronicle(_chronicleToken);
        emit ChronicleTokenSet(_chronicleToken);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert InvalidTokenAddress();
        if (address(oracle) != address(0)) revert OracleAddressAlreadySet();
        oracle = IOracle(_oracle);
        emit OracleAddressSet(_oracle);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawAdminFees(address _to) external onlyOwner {
        if (_to == address(0)) revert FeeRecipientZeroAddress();
        uint256 amount = totalCollectedFees;
        totalCollectedFees = 0;
        if (amount > 0) {
            // Assumes Essence is ERC20 and this contract holds it
            (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, _to, amount));
            if (!success) {
                 // Revert state, or log and handle? Reverting is safer for fee withdrawal.
                 // Reset fees for re-attempt or investigate. For simplicity, let's revert.
                 totalCollectedFees = amount; // Restore state
                 revert TokenTransferFailed();
            }
            emit AdminFeesWithdrawn(_to, amount);
        }
    }

    // --- Governance & Recipes Functions ---

    // 9. Propose a new recipe
    function proposeRecipe(Recipe memory _recipe) external whenNotPaused {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(address(artifactToken) != address(0), "Artifact token not set");
        require(address(chronicleToken) != address(0), "Chronicle token not set");
        require(_recipe.essenceCost > 0 || _recipe.requiredArtifactIdsList.length > 0, "Recipe must have inputs");
        require(_recipe.initialChronicleProperties.length > 0, "Recipe must define initial Chronicle properties");
        require(essenceToken.balanceOf(msg.sender) >= proposalStakeAmount, InsufficientEssence(proposalStakeAmount, essenceToken.balanceOf(msg.sender)));

        // Transfer stake from proposer to this contract
        if (!essenceToken.transferFrom(msg.sender, address(this), proposalStakeAmount)) revert TokenTransferFailed();

        uint256 proposalId = nextProposalId++;
        uint256 recipeId = nextRecipeId; // Reserve the next recipe ID for this proposal

        proposals[proposalId] = Proposal({
            recipeId: recipeId,
            proposalType: ProposalType.AddRecipe,
            submitter: msg.sender,
            proposalStake: proposalStakeAmount,
            voteThreshold: proposalVoteQuorum, // Simple quorum, could be stake-weighted
            voteCount: 0, // Starts at 0
            hasVoted: new mapping(address => bool),
            votingDeadline: uint40(block.timestamp + votingPeriod),
            state: ProposalState.Active,
            proposedRecipeData: _recipe // Store the full recipe data
        });

        emit RecipeProposed(proposalId, recipeId, ProposalType.AddRecipe, msg.sender);
    }

    // 10. Propose removing a recipe
    function proposeRemoveRecipe(uint256 _recipeId) external whenNotPaused {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(recipes[_recipeId].isActive, RecipeDoesNotExist(_recipeId));
        require(essenceToken.balanceOf(msg.sender) >= proposalStakeAmount, InsufficientEssence(proposalStakeAmount, essenceToken.balanceOf(msg.sender)));

        // Transfer stake from proposer to this contract
        if (!essenceToken.transferFrom(msg.sender, address(this), proposalStakeAmount)) revert TokenTransferFailed();

        uint256 proposalId = nextProposalId++;

        proposals[proposalId] = Proposal({
            recipeId: _recipeId,
            proposalType: ProposalType.RemoveRecipe,
            submitter: msg.sender,
            proposalStake: proposalStakeAmount,
            voteThreshold: proposalVoteQuorum,
            voteCount: 0,
            hasVoted: new mapping(address => bool),
            votingDeadline: uint40(block.timestamp + votingPeriod),
            state: ProposalState.Active,
            proposedRecipeData: Recipe({ // Empty recipe data for removal proposal
                isActive: false,
                essenceCost: 0,
                requiredArtifacts: new mapping(uint256 => uint256),
                requiredArtifactIdsList: new uint256[](0),
                initialChronicleProperties: "",
                governanceStakeRequired: 0
            })
        });

        emit RecipeProposed(proposalId, _recipeId, ProposalType.RemoveRecipe, msg.sender);
    }

    // 11. Vote on a proposal
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        if (block.timestamp > proposal.votingDeadline) revert VotingPeriodEnded(_proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);
        // Simple voting: 1 address = 1 vote. Could require minimum Essence balance here.
        // require(essenceToken.balanceOf(msg.sender) >= MIN_VOTE_STAKE, "Insufficient stake to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voteCount++;
        } else {
            // Could add vote counting against as well, or simply count 'support' votes vs quorum
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    // 12. Execute a successful proposal
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        if (block.timestamp <= proposal.votingDeadline) revert VotingPeriodEnded(_proposalId); // Must be after deadline
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);

        // Check if proposal succeeded
        if (proposal.voteCount >= proposal.voteThreshold) {
            proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution

            if (proposal.proposalType == ProposalType.AddRecipe) {
                uint256 newRecipeId = nextRecipeId++;
                recipes[newRecipeId] = proposal.proposedRecipeData;
                recipes[newRecipeId].isActive = true; // Activate the new recipe
                emit RecipeAdded(newRecipeId);

            } else if (proposal.proposalType == ProposalType.RemoveRecipe) {
                uint256 recipeIdToRemove = proposal.recipeId;
                 if (recipes[recipeIdToRemove].isActive) {
                    recipes[recipeIdToRemove].isActive = false; // Deactivate the recipe
                    // Note: Recipe data remains, just marked inactive
                    emit RecipeRemoved(recipeIdToRemove);
                 }
            }
             proposal.state = ProposalState.Executed; // Mark as executed
        } else {
            proposal.state = ProposalState.Failed;
        }

        // Return proposer's stake (or burn it, or send to admin)
        // Let's return it for simplicity.
        if (proposal.proposalStake > 0) {
             (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, proposal.submitter, proposal.proposalStake));
             if (!success) {
                // This is tricky. Stake transfer failed after execution.
                // Log this critical error and potentially handle manually.
                // For now, log and let the execution state stand.
                emit TokenTransferFailed();
            }
        }

        emit ProposalExecuted(_proposalId, proposal.state);
    }

    // 13. View recipe details
    function getRecipeDetails(uint256 _recipeId) public view returns (
        bool isActive,
        uint256 essenceCost,
        uint256[] memory requiredArtifactIds,
        bytes memory initialChronicleProperties,
        uint256 governanceStakeRequired
    ) {
        Recipe storage recipe = recipes[_recipeId];
        if (!recipe.isActive && nextRecipeId <= _recipeId) revert RecipeDoesNotExist(_recipeId); // Only revert if ID is truly non-existent, allow viewing inactive ones

        return (
            recipe.isActive,
            recipe.essenceCost,
            recipe.requiredArtifactIdsList,
            recipe.initialChronicleProperties,
            recipe.governanceStakeRequired
        );
    }

    // 14. List all valid recipe IDs (simplistic list)
    // Note: For many recipes, this might exceed block gas limits. A paged or counter+getter pattern is better.
    function listRecipes() public view returns (uint256[] memory) {
        uint256[] memory activeRecipeIds = new uint256[](nextRecipeId - 1);
        uint256 current = 0;
        for (uint256 i = 1; i < nextRecipeId; i++) {
            if (recipes[i].isActive) {
                activeRecipeIds[current] = i;
                current++;
            }
        }
        // Resize array
        uint256[] memory result = new uint256[](current);
        for (uint256 i = 0; i < current; i++) {
            result[i] = activeRecipeIds[i];
        }
        return result;
    }

     // 15. View proposal details
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 recipeId,
        ProposalType proposalType,
        address submitter,
        uint256 proposalStake,
        uint256 voteThreshold,
        uint256 voteCount,
        uint40 votingDeadline,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.submitter == address(0)) revert InvalidProposalId(_proposalId); // Check if proposal exists

         return (
            proposal.recipeId,
            proposal.proposalType,
            proposal.submitter,
            proposal.proposalStake,
            proposal.voteThreshold,
            proposal.voteCount,
            proposal.votingDeadline,
            proposal.state
        );
    }


    // --- Crafting Functions ---

    // 16. Execute a crafting recipe
    function craftChronicle(uint256 _recipeId, uint256[] memory _artifactTokenIds) external whenNotPaused {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(address(artifactToken) != address(0), "Artifact token not set");
        require(address(chronicleToken) != address(0), "Chronicle token not set");

        Recipe storage recipe = recipes[_recipeId];
        if (!recipe.isActive) revert RecipeNotActive(_recipeId);

        // Check Essence requirements
        if (essenceToken.balanceOf(msg.sender) < recipe.essenceCost) revert InsufficientEssence(recipe.essenceCost, essenceToken.balanceOf(msg.sender));

        // Check Artifact requirements
        // Simple check: requires exact number of artifacts with specific IDs matching recipe.requiredArtifactIdsList
        // A more complex recipe could require certain *types* or *properties* of artifacts.
        require(_artifactTokenIds.length == recipe.requiredArtifactIdsList.length, InsufficientArtifacts(0, recipe.requiredArtifactIdsList.length, _artifactTokenIds.length));
        mapping(uint256 => bool) memory usedArtifacts; // Track used artifact IDs from the input array
        for (uint256 i = 0; i < recipe.requiredArtifactIdsList.length; i++) {
            uint256 requiredId = recipe.requiredArtifactIdsList[i];
            bool found = false;
            for (uint256 j = 0; j < _artifactTokenIds.length; j++) {
                if (!usedArtifacts[_artifactTokenIds[j]] && _artifactTokenIds[j] == requiredId) {
                    // Check ownership
                    if (artifactToken.ownerOf(_artifactTokenIds[j]) != msg.sender) revert ArtifactNotOwnedByCrafter(_artifactTokenIds[j], artifactToken.ownerOf(_artifactTokenIds[j]));
                    usedArtifacts[_artifactTokenIds[j]] = true;
                    found = true;
                    break;
                }
            }
            require(found, InsufficientArtifacts(requiredId, 1, 0)); // Required artifact ID not provided
        }


        // --- Execute Crafting ---

        // Transfer Essence cost
        if (recipe.essenceCost > 0) {
            if (!essenceToken.transferFrom(msg.sender, address(this), recipe.essenceCost)) revert TokenTransferFailed();
        }

        // Transfer Artifacts to this contract (they are 'consumed' by being held here or burned)
        // Using safeTransferFrom requires the receiving contract (this one) to implement onERC721Received
        for (uint256 i = 0; i < _artifactTokenIds.length; i++) {
             artifactToken.safeTransferFrom(msg.sender, address(this), _artifactTokenIds[i]);
             // Note: Artifacts are now owned by the Forge contract. A real system might burn them.
        }

        // Mint the new Chronicle NFT
        // Chronicle contract needs a trusted 'mint' function callable by the Forge
        uint256 newTokenId = // Logic to determine new token ID (e.g., counter, hash of inputs)
                            // For simplicity, let's assume Chronicle contract handles ID generation
                            // and returns it upon minting. Or, Forge could calculate a unique ID.
                            // Let's assume Chronicle.mint takes desired ID or generates one.
                            // A common pattern is to let the minter (Forge) propose an ID based on inputs.
                            // For this example, let's assume Chronicle contract issues next sequential ID and returns it.
                            // A more robust approach is to pass a unique seed/hash to mint.
                            // Let's mock getting a new ID (this needs proper implementation in IChronicle)
                            // For now, let's assume Chronicle.mint handles ID and returns it.
                            // This requires a change to IChronicle.mint signature and implementation.
                            // Alternative: Chronicle contract manages ID and Forge calls a simple mint function.
                            // Let's revise: Forge calls mint, Chronicle mints next ID & transfers to crafter.

        // The Chronicle contract's mint function must be callable ONLY by the Forge.
        // It should mint the NFT and transfer it directly to msg.sender (the crafter).
        // The initial properties are passed to the mint function.
        chronicleToken.mint(msg.sender, 0, recipe.initialChronicleProperties); // Assuming 0 signals Chronicle to generate ID

        // Collect crafting fee (if any)
        if (craftingFee > 0) {
             if (essenceToken.balanceOf(msg.sender) < craftingFee) {
                 // Fee cannot be paid. This is an edge case if fee > recipeCost but total balance is >= recipeCost + fee.
                 // Could require total balance check upfront, or simply revert here.
                 // Let's revert.
                 revert InsufficientEssence(craftingFee, essenceToken.balanceOf(msg.sender));
             }
             if (!essenceToken.transferFrom(msg.sender, adminFeeRecipient, craftingFee)) {
                  // Fee transfer failed. Log or handle. For simplicity, revert.
                  revert TokenTransferFailed();
             }
             totalCollectedFees += craftingFee; // Track fees
             emit CraftingFeeCollected(_recipeId, msg.sender, craftingFee);
        }

        // We need the new token ID to emit the event.
        // If Chronicle.mint assigns the ID, it needs to return it.
        // Let's adjust IChronicle.mint to return the ID.
        // For now, emitting with a placeholder 0 or assuming Chronicle emits its own Mint event.
        // Assuming Chronicle emits ERC721.Transfer event upon minting to msg.sender.
        // We could listen for that event off-chain to get the ID. Or Chronicle.mint returns it.
        // Let's assume Chronicle.mint returns the ID.
        uint256 mintedTokenId = chronicleToken.mint(msg.sender, 0, recipe.initialChronicleProperties); // Revised mint signature

        emit ChronicleCrafted(_recipeId, msg.sender, mintedTokenId);
    }

    // 17. View function to check crafting requirements
    function checkCraftingRequirements(uint256 _recipeId, address _crafter, uint256[] memory _artifactTokenIds) public view returns (bool canCraft, string memory reason) {
        Recipe storage recipe = recipes[_recipeId];
        if (!recipe.isActive) return (false, "Recipe is not active");

        if (essenceToken.balanceOf(_crafter) < recipe.essenceCost) return (false, "Insufficient Essence balance");
         if (craftingFee > 0 && essenceToken.balanceOf(_crafter) < recipe.essenceCost + craftingFee) return (false, "Insufficient Essence balance for cost and fee");


        if (_artifactTokenIds.length != recipe.requiredArtifactIdsList.length) return (false, "Incorrect number of Artifacts provided");

        mapping(uint256 => bool) memory usedArtifacts;
        for (uint256 i = 0; i < recipe.requiredArtifactIdsList.length; i++) {
            uint256 requiredId = recipe.requiredArtifactIdsList[i];
            bool found = false;
            for (uint256 j = 0; j < _artifactTokenIds.length; j++) {
                if (!usedArtifacts[_artifactTokenIds[j]] && _artifactTokenIds[j] == requiredId) {
                     // Check ownership
                    try artifactToken.ownerOf(_artifactTokenIds[j]) returns (address owner) {
                       if (owner != _crafter) return (false, string.concat("Artifact ", vm.toString(_artifactTokenIds[j]), " not owned by crafter"));
                    } catch {
                        return (false, string.concat("Artifact ", vm.toString(_artifactTokenIds[j]), " does not exist"));
                    }

                    usedArtifacts[_artifactTokenIds[j]] = true;
                    found = true;
                    break;
                }
            }
            if (!found) return (false, string.concat("Required Artifact ID ", vm.toString(requiredId), " not provided"));
        }

        return (true, "Requirements met");
    }

    // 18. ERC721 Receiver Hook
    // This function must be implemented to receive ERC721 tokens (Artifacts)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Only allow receiving from the Artifact token contract
        require(msg.sender == address(artifactToken), "Not authorized to send ERC721");
        // Further checks can be added here if needed, e.g., is this artifact part of an active crafting process?
        // For this simple implementation, we just accept any artifact from the registered contract.
        // In a real system, this might only be called *during* the craftChronicle execution flow.

        // The bytes `data` can be used to pass context, e.g., the recipe ID this transfer is for.
        // However, our craftChronicle already handles this context.
        // This simple implementation just confirms acceptance.

        return this.onERC721Received.selector;
    }


    // --- Challenge Functions ---

    // 19. Propose a challenge
    function proposeChallenge(uint256 _chronicleTokenId, bytes32 _oracleQueryId) external whenNotPaused {
        require(address(essenceToken) != address(0), "Essence token not set");
        require(address(chronicleToken) != address(0), "Chronicle token not set");
        require(address(oracle) != address(0), "Oracle not set");
        require(essenceToken.balanceOf(msg.sender) >= challengeStakeAmount, InsufficientEssence(challengeStakeAmount, essenceToken.balanceOf(msg.sender)));

        address chronicleOwner = chronicleToken.ownerOf(_chronicleTokenId); // Will revert if token does not exist
        require(chronicleOwner != address(0), "Chronicle token does not exist"); // Double check, ownerOf should handle
        require(chronicleOwner != msg.sender, "Cannot challenge your own Chronicle");

        // Transfer challenger's stake
        if (!essenceToken.transferFrom(msg.sender, address(this), challengeStakeAmount)) revert TokenTransferFailed();

        uint256 challengeId = nextChallengeId++;

        challenges[challengeId] = Challenge({
            challenger: msg.sender,
            challenged: chronicleOwner, // Store the current owner at proposal time
            chronicleTokenId: _chronicleTokenId,
            challengerStake: challengeStakeAmount,
            challengedStake: 0, // Stake TBD upon acceptance
            oracleQueryId: _oracleQueryId, // Identifier for the oracle data needed
            oracleRequestId: bytes32(0), // Request not yet made
            challengeDeadline: uint40(block.timestamp + challengeAcceptancePeriod),
            state: ChallengeState.Proposed
        });

        emit ChallengeProposed(challengeId, _chronicleTokenId, msg.sender, _oracleQueryId, challengeStakeAmount);
    }

    // 20. Accept a challenge
    function acceptChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.state != ChallengeState.Proposed) revert ChallengeNotInState(_challengeId, ChallengeState.Proposed);
        require(msg.sender == challenge.challenged, NotChallengeParticipant(_challengeId)); // Only the challenged owner can accept
        if (block.timestamp > challenge.challengeDeadline) revert ChallengeAcceptancePeriodPassed(_challengeId);
        require(address(essenceToken) != address(0), "Essence token not set");
        require(essenceToken.balanceOf(msg.sender) >= challengeStakeAmount, InsufficientEssence(challengeStakeAmount, essenceToken.balanceOf(msg.sender)));

        // Transfer challenged's stake
         if (!essenceToken.transferFrom(msg.sender, address(this), challengeStakeAmount)) revert TokenTransferFailed();

        challenge.challengedStake = challengeStakeAmount;
        challenge.state = ChallengeState.Accepted;
        challenge.challengeDeadline = uint40(block.timestamp + challengeResolutionPeriod); // Reset deadline for resolution

        emit ChallengeAccepted(_challengeId, msg.sender, challengeStakeAmount);
    }

    // 21. Cancel a challenge (before acceptance or resolution)
    function cancelChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.state != ChallengeState.Proposed && challenge.state != ChallengeState.Accepted && challenge.state != ChallengeState.OracleRequested) {
             revert ChallengeNotInState(_challengeId, ChallengeState.Proposed); // Can only cancel in these states
        }
        require(msg.sender == challenge.challenger || msg.sender == challenge.challenged, NotChallengeParticipant(_challengeId)); // Only participants can cancel

        uint256 challengerReturn = 0;
        uint256 challengedReturn = 0;
        uint256 penaltyAmount = 0; // Penalty applies only if challenger cancels after acceptance or Oracle request

        if (msg.sender == challenge.challenger) {
            // Challenger cancels
            if (challenge.state == ChallengeState.Proposed) {
                // Before acceptance - full refund
                challengerReturn = challenge.challengerStake;
            } else {
                // After acceptance or Oracle request - pay penalty
                penaltyAmount = (challenge.challengerStake * challengeCancelPenaltyPercentage) / 100;
                challengerReturn = challenge.challengerStake - penaltyAmount;
                challengedReturn = challenge.challengedStake; // Return challenged stake
            }
        } else { // msg.sender == challenge.challenged
             // Challenged cancels (only possible if state != Proposed && state != Accepted?)
             // Let's only allow challenger to cancel in Proposed state, and either after acceptance/request if outcome is stuck?
             // Simpler logic: Challenger can cancel ANYTIME before final Oracle fulfillment/resolution. Challenged CANNOT cancel after accepting.
             // Let's revise: Only challenger can cancel. If they cancel after acceptance, they pay penalty.
             revert("Only challenger can cancel"); // Remove this line if allowing challenged to cancel earlier

             // If we allowed challenged to cancel after acceptance:
             // penaltyAmount = (challenge.challengedStake * challengeCancelPenaltyPercentage) / 100;
             // challengedReturn = challenge.challengedStake - penaltyAmount;
             // challengerReturn = challenge.challengerStake; // Return challenger stake
        }

        // Return stakes
        if (challengerReturn > 0) {
             (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, challenge.challenger, challengerReturn));
             if (!success) emit TokenTransferFailed(); // Log error
        }
         if (challengedReturn > 0) {
             (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, challenge.challenged, challengedReturn));
             if (!success) emit TokenTransferFailed(); // Log error
        }
        // Penalty amount could be burned or sent to adminFeeRecipient
        // For simplicity, let's assume penalty is just not returned. The contract keeps it.

        challenge.state = ChallengeState.Cancelled;

        emit ChallengeCancelled(_challengeId, msg.sender, penaltyAmount);
    }

    // 23. Request Oracle Data for a Challenge
    function requestChallengeOracleData(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.state != ChallengeState.Accepted) revert ChallengeNotInState(_challengeId, ChallengeState.Accepted);
         if (block.timestamp > challenge.challengeDeadline) revert ChallengeResolutionPeriodPassed(_challengeId); // Must request before deadline
        if (challenge.oracleRequestId != bytes32(0)) revert ChallengeAlreadyHasOracleRequest(_challengeId); // Already requested

        // Only participants or possibly anyone (with a fee?) can trigger the oracle request
        // Let's allow anyone to trigger, decentralizing the request mechanism.
        // require(msg.sender == challenge.challenger || msg.sender == challenge.challenged, NotChallengeParticipant(_challengeId));


        require(address(oracle) != address(0), "Oracle not set");

        // Request data from the oracle
        // Pass challengeId in params or callback data so oracle can send it back
        bytes memory oracleParams = abi.encode(_challengeId); // Example: pass challenge ID as param
        bytes32 requestId = oracle.requestData(
            challenge.oracleQueryId,
            address(this),
            this.fulfillOracleRequest.selector,
            oracleParams
        );

        challenge.oracleRequestId = requestId;
        oracleRequestIdToChallengeId[requestId] = _challengeId;
        challenge.state = ChallengeState.OracleRequested;
        // Deadline is not reset here, oracle needs to respond before resolution period ends.

        emit ChallengeOracleRequestMade(_challengeId, requestId);
    }


    // 24. Oracle Callback Function
    // This function is called by the oracle contract once data is available
    function fulfillOracleRequest(bytes32 _requestId, uint256 _result, bytes memory _data) external {
        // Modifier to ensure call comes from the registered oracle address
        require(msg.sender == address(oracle), OracleCallbackNotFromOracle());

        // Find the challenge associated with this request ID
        uint256 challengeId = oracleRequestIdToChallengeId[_requestId];
        // Ensure the challenge exists and is in the correct state
        Challenge storage challenge = challenges[challengeId];
        if (challenge.state != ChallengeState.OracleRequested) revert ChallengeNotInState(challengeId, ChallengeState.OracleRequested);
        if (challenge.oracleRequestId != _requestId) revert InvalidChallengeId(challengeId); // Should match request ID

        // Oracle data is available, proceed to resolve the challenge
        _processChallengeResult(challengeId, _result, _data);

        emit OracleCallbackReceived(_requestId, _result);
    }

    // Internal function to process the oracle result and resolve the challenge
    function _processChallengeResult(uint256 _challengeId, uint256 _oracleResult, bytes memory _oracleData) internal whenNotPaused {
         Challenge storage challenge = challenges[_challengeId];
        // Ensure deadline hasn't passed *while waiting for oracle*, although oracle callback is async
        // A better system would have a separate resolution transaction that checks deadline *after* oracle data is received
        // For simplicity here, we resolve immediately upon receiving oracle data if state is OracleRequested

        // Determine challenge outcome based on _oracleResult and _oracleData
        // This is the core logic of the challenge type.
        // Example: _oracleResult could be 0 for challenger wins, 1 for challenged wins, 2 for draw.
        // _oracleData could contain details for updating the Chronicle NFT properties.

        bool challengerWins = false; // Example logic
        bytes memory propertiesUpdateData = ""; // Example data for Chronicle update

        // --- Example Challenge Logic ---
        // Let's say the challenge is about whether a stock price (fetched by oracle) is > some value.
        // oracleQueryId could encode the stock ticker and the target value.
        // _oracleResult could be 1 if price > value, 0 otherwise.

        // Here, we need to parse _oracleResult and challenge.oracleQueryId to determine outcome.
        // This logic is specific to the types of challenges the system supports.
        // For simplicity, let's assume _oracleResult 1 means challenger wins, 0 means challenged wins.
        if (_oracleResult == 1) {
            challengerWins = true;
            // Define how properties update on win/loss.
            // propertiesUpdateData could be a byte array encoding the new properties.
            propertiesUpdateData = abi.encodePacked("Win_", _oracleResult); // Example update data
        } else {
            challengerWins = false;
             propertiesUpdateData = abi.encodePacked("Lose_", _oracleResult); // Example update data
        }
        // --- End Example Logic ---


        // Distribute stakes and update Chronicle NFT
        uint256 totalStake = challenge.challengerStake + challenge.challengedStake;
        uint256 winnerPayout = 0;
        uint256 loserReturn = 0;
        address winner;
        address loser;

        if (challengerWins) {
            winner = challenge.challenger;
            loser = challenge.challenged;
            // Winner takes all? Split? Fee taken? Example: Winner takes 95%, 5% burned or sent to admin.
            uint256 fee = (totalStake * 5) / 100; // 5% fee
            winnerPayout = totalStake - fee;
            loserReturn = 0; // Loser loses stake
             totalCollectedFees += fee; // Track fee

             (bool successFee,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, adminFeeRecipient, fee));
             if (!successFee) emit TokenTransferFailed(); // Log error
        } else { // Challenged wins
            winner = challenge.challenged;
            loser = challenge.challenger;
            uint256 fee = (totalStake * 5) / 100; // 5% fee
            winnerPayout = totalStake - fee;
            loserReturn = 0; // Loser loses stake
            totalCollectedFees += fee; // Track fee

            (bool successFee,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, adminFeeRecipient, fee));
             if (!successFee) emit TokenTransferFailed(); // Log error
        }

        // Pay winner
        if (winnerPayout > 0) {
            (bool successWin,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, winner, winnerPayout));
             if (!successWin) emit TokenTransferFailed(); // Log error
        }
         // Return loser's (zero) stake - this will be 0 but demonstrates the path
         if (loserReturn > 0) {
             (bool successLose,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, loser, loserReturn));
             if (!successLose) emit TokenTransferFailed(); // Log error
        }

        emit ChallengeStakesDistributed(_challengeId, winner, loser, winnerPayout, loserReturn);

        // Update the Chronicle NFT properties
        // Chronicle contract needs a trusted 'updateProperties' function callable by the Forge
        try chronicleToken.updateProperties(challenge.chronicleTokenId, propertiesUpdateData) {
             emit ChallengeResolved(_challengeId, challenge.chronicleTokenId, _oracleResult, propertiesUpdateData);
        } catch {
            // Handle potential failure in updating Chronicle.
            // This is a critical error. Log it. Challenge is resolved, but NFT not updated.
            emit OracleResultProcessingFailed(_challengeId);
             emit ChallengeResolved(_challengeId, challenge.chronicleTokenId, _oracleResult, "Failed to update properties");
        }


        challenge.state = ChallengeState.Resolved;
        // Clean up mapping (optional, but good practice for many requests)
        delete oracleRequestIdToChallengeId[_requestId];
    }

    // 22. Resolve Challenge (User triggered or internal based on deadline?)
    // Given the Oracle callback model, _processChallengeResult is the actual resolution logic.
    // This function could be triggered by anyone AFTER the Oracle has responded AND the resolution period hasn't passed.
    // However, the Oracle callback itself triggers resolution in the current design.
    // If the Oracle *fails* to respond within the window, how is it resolved?
    // Need a mechanism to resolve if oracle times out.
    // Let's add a user-triggerable resolve function *after* the oracle request deadline.

     function resolveChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        // Allow resolution only if:
        // 1. Oracle data was requested AND callback received (state = OracleRequested, oracleRequestId != 0, and check a flag/storage indicating callback arrived?)
        //    OR
        // 2. Resolution period passed AND Oracle data was requested but NOT received.
        //    OR
        // 3. Acceptance period passed and challenge wasn't accepted (state = Proposed, deadline passed - cancellation)

        if (challenge.state == ChallengeState.Proposed) {
             if (block.timestamp <= challenge.challengeDeadline) revert ChallengeNotInState(_challengeId, ChallengeState.Resolved);
             // Acceptance period passed, challenge was not accepted -> Cancel it
             challenge.state = ChallengeState.Cancelled;
             // Return challenger's stake
             if (challenge.challengerStake > 0) {
                 (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, challenge.challenger, challenge.challengerStake));
                 if (!success) emit TokenTransferFailed(); // Log error
             }
              emit ChallengeCancelled(_challengeId, address(this), 0); // Indicate system cancelled
        } else if (challenge.state == ChallengeState.Accepted || challenge.state == ChallengeState.OracleRequested) {
             if (block.timestamp <= challenge.challengeDeadline && challenge.oracleRequestId == bytes32(0)) {
                  // Oracle data hasn't been requested yet and still in acceptance window (should be in Accepted state)
                  // Or oracle data requested but resolution period not passed.
                 revert ChallengeNotInState(_challengeId, ChallengeState.Resolved);
             }

             // Scenario 1: Oracle data was requested and callback arrived (state is still OracleRequested, but data is processed by callback)
             // This scenario is handled by fulfillOracleRequest calling _processChallengeResult directly.

             // Scenario 2: Resolution period passed AND Oracle data was requested but callback did NOT arrive.
             if (block.timestamp > challenge.challengeDeadline && challenge.oracleRequestId != bytes32(0) && challenge.state == ChallengeState.OracleRequested) {
                 // Oracle timeout. Need to handle outcome.
                 // Default outcome? Refund stakes? Auto-win for one party?
                 // Let's refund stakes for simplicity on timeout.
                 challenge.state = ChallengeState.Cancelled; // Treat as cancelled due to timeout
                 if (challenge.challengerStake > 0) {
                      (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, challenge.challenger, challenge.challengerStake));
                     if (!success) emit TokenTransferFailed();
                 }
                 if (challenge.challengedStake > 0) {
                     (bool success,) = address(essenceToken).call(abi.encodeWithSelector(essenceToken.transfer.selector, challenge.challenged, challenge.challengedStake));
                     if (!success) emit TokenTransferFailed();
                 }
                  // Clean up mapping
                 delete oracleRequestIdToChallengeId[challenge.oracleRequestId];
                 emit ChallengeCancelled(_challengeId, address(this), 0); // Indicate system cancelled due to timeout

             } else {
                 // Challenge is in a state that requires Oracle callback or is already resolved/cancelled.
                 revert ChallengeNotInState(_challengeId, ChallengeState.Resolved);
             }

        } else { // Already Resolved or Cancelled
             revert ChallengeNotInState(_challengeId, ChallengeState.Resolved);
        }
    }


    // --- View Functions (General) ---

    // 25. List active proposal IDs (simplistic list)
    function listProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](nextProposalId - 1);
        uint256 current = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].state == ProposalState.Active) {
                activeProposalIds[current] = i;
                current++;
            }
        }
         // Resize array
        uint256[] memory result = new uint256[](current);
        for (uint256 i = 0; i < current; i++) {
            result[i] = activeProposalIds[i];
        }
        return result;
    }

     // 26. List active challenge IDs (simplistic list)
     function listChallenges() public view returns (uint256[] memory) {
        uint256[] memory activeChallengeIds = new uint256[](nextChallengeId - 1);
        uint256 current = 0;
        for (uint256 i = 1; i < nextChallengeId; i++) {
            if (challenges[i].state != ChallengeState.Resolved && challenges[i].state != ChallengeState.Cancelled) {
                activeChallengeIds[current] = i;
                current++;
            }
        }
         // Resize array
        uint256[] memory result = new uint256[](current);
        for (uint256 i = 0; i < current; i++) {
            result[i] = activeChallengeIds[i];
        }
        return result;
    }

    // 27. View total Essence staked
    function getTotalEssenceStaked() public view returns (uint256) {
        // This requires iterating through all active proposals and challenges
        // This can be gas intensive if there are many.
        // A more efficient way is to maintain a running counter updated on stake/unstake events.
        // For simplicity, let's add a counter.

        // NOTE: Adding state variable `totalStakedEssence` and updating it in stake/unstake functions.
        // This view function would then simply return `totalStakedEssence`.
        // Let's *assume* a `totalStakedEssence` variable is added and correctly maintained.
        // Example implementation would add `totalStakedEssence += stakeAmount` on staking
        // and `totalStakedEssence -= returnAmount` on stake return/loss.

        // --- Placeholder ---
        uint256 staked = 0;
         // Sum stakes in active proposals
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].state == ProposalState.Active) {
                staked += proposals[i].proposalStake;
            }
        }
        // Sum stakes in active challenges
         for (uint256 i = 1; i < nextChallengeId; i++) {
            if (challenges[i].state != ChallengeState.Resolved && challenges[i].state != ChallengeState.Cancelled) {
                staked += challenges[i].challengerStake + challenges[i].challengedStake;
            }
        }
        return staked;
        // --- End Placeholder ---
    }

    // 28. Get Chronicle NFT properties (delegates call to Chronicle contract)
    function getChronicleProperties(uint256 _chronicleTokenId) public view returns (bytes memory) {
         require(address(chronicleToken) != address(0), "Chronicle token not set");
         // Check if token exists? ownerOf will revert.
         address owner = chronicleToken.ownerOf(_chronicleTokenId); // Implicitly checks existence

         // Chronicle contract needs a public/external view function for properties
         return chronicleToken.getProperties(_chronicleTokenId);
    }

    // Required by ERC721Holder
    // This specifies which ERC721 tokens the contract is willing to receive.
    // We only intend to receive Artifact NFTs.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Fallback/Receive functions: Best practice to make explicit or absent if not needed.
    // Since we receive ERC20 and ERC721 via specific calls (transferFrom, safeTransferFrom),
    // no need for payable fallback/receive unless we want to receive ETH.
    // receive() external payable {}
    // fallback() external payable {}
}
```

---

**Explanation of Concepts and Functions:**

1.  **Core Tokens (Essence, Artifact, Chronicle):** We define interfaces `IEssence`, `IArtifact`, `IChronicle`. The Forge contract interacts with these externally deployed tokens. `Essence` is ERC20 (utility/governance/stake), `Artifact` is ERC721 (crafting ingredient), `Chronicle` is ERC721 (crafted, dynamic output).
2.  **Oracle Interface (`IOracle`):** Defines how the Forge requests data from a separate Oracle contract and how the Oracle calls back. This decouples the Forge logic from the specific Oracle implementation (e.g., Chainlink, custom).
3.  **Recipe Management:**
    *   `Recipe` struct defines what inputs (Essence, specific Artifact IDs) are needed and what initial properties the resulting Chronicle NFT will have (`initialChronicleProperties`).
    *   Recipes are added/removed via a simple on-chain governance process.
4.  **Governance:**
    *   `Proposal` struct represents an action (add/remove recipe) subject to voting.
    *   `proposeRecipe`, `proposeRemoveRecipe`: Users stake Essence to propose changes.
    *   `voteOnProposal`: Users vote on active proposals. Simple 1-address-1-vote for now, but easily extendable to stake-weighted voting.
    *   `executeProposal`: After the voting period, anyone can trigger execution if the quorum is met. Stake is returned.
5.  **Crafting (`craftChronicle`):**
    *   Takes a `recipeId` and array of `artifactTokenIds`.
    *   Checks user's balances and ownership using `transferFrom` pre-checks.
    *   Uses `transferFrom` to pull Essence and `safeTransferFrom` to pull Artifacts from the user into the Forge contract (consuming them for the craft). The `onERC721Received` hook is necessary for `safeTransferFrom`.
    *   Calls the `Chronicle` contract's `mint` function (which is designed to be callable only by the Forge) to create the new NFT and transfer it *directly* to the crafter (`msg.sender`).
    *   An optional `craftingFee` in Essence is collected.
6.  **Dynamic NFTs (`updateProperties` in IChronicle):** The Chronicle contract itself is responsible for storing and managing the NFT's properties. The Forge contract has a trusted role to call an `updateProperties` function on the Chronicle contract, changing the NFT's state after it's minted, specifically after challenges.
7.  **Challenge System:**
    *   `Challenge` struct tracks a dispute over a Chronicle NFT's fate.
    *   `proposeChallenge`: User stakes Essence to initiate a challenge against another user's Chronicle NFT, specifying an `oracleQueryId` (defining the external data needed).
    *   `acceptChallenge`: The challenged user stakes matching Essence to accept the challenge.
    *   `cancelChallenge`: Allows challenger to back out, potentially with a penalty if accepted.
    *   `requestChallengeOracleData`: Anyone can trigger the request to the Oracle *after* the challenge is accepted.
    *   `fulfillOracleRequest`: The *Oracle contract* calls this function back on the Forge. It includes the `_oracleResult` and any extra data.
    *   `_processChallengeResult` (internal helper): This is where the logic interprets the `_oracleResult` and `_oracleData` to determine the challenge winner. It distributes the staked Essence (potentially taking a fee) and calls the `Chronicle` contract's `updateProperties` function to change the challenged NFT based on the outcome.
    *   `resolveChallenge`: A fallback mechanism to finalize challenges that weren't accepted or where the oracle timed out.
8.  **Token Sinks:** Essence is directly consumed (`transferFrom` to Forge for crafting cost) and potentially collected as fees (`transferFrom` to admin or burned). Essence is also locked during challenges (`transferFrom` to Forge) and redistributed based on outcomes, with potential fees taken.
9.  **Access Control:** `Ownable` for critical setup/pausing/fee withdrawal. `Pausable` for emergency halts. `onlyOracle` modifier ensures only the trusted Oracle can call `fulfillOracleRequest`. The design *implies* that `IChronicle` needs modifiers/access control to ensure only the Forge can call `mint` and `updateProperties`.
10. **Error Handling & Events:** Comprehensive `require` and `revert` statements with custom errors for clarity. Events emitted for key actions for off-chain monitoring.
11. **`ERC721Holder`:** Inherited to allow the contract to receive ERC721 tokens (`Artifacts`) via `safeTransferFrom`.

This contract combines elements of DeFi (staking, fees), NFTs (crafting, dynamic properties), Oracles (external data interaction), and Governance (on-chain rules). It avoids being a simple copy-paste of standard contracts by integrating these concepts into a unique crafting and challenge flow with dynamic asset properties.