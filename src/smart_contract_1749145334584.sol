Okay, here is a smart contract idea combining elements of collaborative art, dynamic NFTs, on-chain state influence, epoch-based progression, and decentralized governance.

The concept: **Ethereal Canvas**

Users contribute "Brushstrokes" (ETH/value) to influence the parameters of a generative art piece within a specific "Epoch". At the end of an epoch, a unique NFT representing that generated art piece is minted. The parameters for the art generation are dynamically derived from the collective contributions, timing, and potentially other on-chain factors. A simple governance system allows contributors to propose and vote on adjustments to the canvas rules (epoch duration, influence weights, etc.). The actual art generation (SVG/parameters) and metadata hosting happen off-chain, but the *parameters* that drive it are determined and stored on-chain, and the `tokenURI` is dynamic.

---

**Smart Contract: EtherealCanvas**

**Outline:**

1.  **License and Version:** SPDX license identifier and Solidity version pragma.
2.  **Imports:** ERC721, ERC165, Ownable.
3.  **Error Codes:** Custom errors for clarity.
4.  **Enums:** ProposalState.
5.  **Structs:**
    *   `GenerationFactors`: Stores parameters influenced by contributions (e.g., `colorHueFactor`, `complexityFactor`, `spatialArrangementFactor`).
    *   `Epoch`: Stores epoch data (`startTime`, `endTime`, `totalBrushstrokes`, `topContributor`, `maxBrushstrokesInEpoch`, `winnerAddress`, `claimed`, `artMetadataHash`, `isSealed`).
    *   `Proposal`: Stores governance proposal data.
6.  **State Variables:**
    *   ERC721 mappings/counters.
    *   `epochCounter`: Current epoch ID.
    *   `epochs`: Mapping `uint256 => Epoch`.
    *   `brushstrokesByEpochAndContributor`: Nested mapping `uint256 => address => uint256`.
    *   `currentGenerationFactors`: The factors for the *current* ongoing epoch.
    *   `protocolFeePercentage`: Percentage of brushstrokes collected as fees.
    *   `protocolFeeRecipient`: Address receiving fees.
    *   `epochDuration`: Default duration for new epochs.
    *   `minBrushstrokeAmount`: Minimum contribution.
    *   Governance variables (`proposalCounter`, `proposals`, `votes`, `minimumVotesForProposal`, `proposalVotingPeriod`, `executionDelay`).
    *   Base URI for dynamic metadata.
7.  **Events:**
    *   `BrushstrokeContributed`
    *   `EpochEnded`
    *   `EpochGeneratedNFTClaimed`
    *   `GenerationFactorsUpdated`
    *   `ProposalSubmitted`
    *   `Voted`
    *   `ProposalExecuted`
    *   `ProtocolFeesWithdrawn`
8.  **Modifiers:**
    *   `whenEpochNotEnded`
    *   `whenEpochEnded`
    *   `onlyEpochWinner`
    *   `onlyGovernor` (Could be tied to proposals or a specific role)
9.  **Constructor:** Initializes ERC721, owner, fee recipient, initial duration, min brushstroke. Starts the first epoch.
10. **Receive/Fallback:** Allows receiving ETH, redirects to `contributeBrushstroke`.
11. **Core Canvas/Epoch Functions:**
    *   `contributeBrushstroke`: Receive ETH, update state, influence `currentGenerationFactors`.
    *   `triggerEpochEnd`: Callable after epoch end time. Seals the epoch, determines winner, stores final parameters/hash, starts new epoch.
    *   `claimEpochNFT`: Allows the determined winner to claim the NFT.
    *   `getCurrentEpochId`: View current epoch.
    *   `getEpochData`: View data for a specific epoch.
    *   `getEpochContributorBrushstrokes`: View user's brushstrokes in an epoch.
    *   `getEpochBrushstrokePool`: View total brushstrokes in an epoch.
    *   `isEpochEnded`: Check if an epoch has ended.
    *   `getEpochWinnerAddress`: View the winner of a sealed epoch.
    *   `getEpochArtMetadataHash`: View the generated metadata hash for a sealed epoch NFT.
12. **Generation Factor Functions:**
    *   `getCurrentInfluenceFactors`: View the factors for the *current* epoch.
    *   `calculateInfluenceFactors`: Internal pure function to derive factors from brushstrokes, time, etc.
13. **ERC721 Standard Functions:**
    *   `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.
    *   `tokenURI`: Dynamically generates URI using base URI and stored metadata hash.
    *   `supportsInterface`.
14. **Governance Functions:**
    *   `submitParameterProposal`: Users propose changes to governance-controlled variables or functions.
    *   `voteOnProposal`: Users cast votes.
    *   `executeProposal`: Executes a passed proposal after delay.
    *   `getProposalState`: View current state of a proposal.
    *   `getProposalById`: View details of a specific proposal.
    *   `getProposalVoteCount`: View vote counts for a proposal.
15. **Protocol/Utility Functions:**
    *   `getTotalPooledInfluence`: Total ETH held in the contract from brushstrokes (before fees).
    *   `withdrawProtocolFees`: Allows fee recipient to withdraw collected fees.
    *   `getProtocolFeePercentage`: View current fee percentage.
    *   `setBaseURI`: Owner/governance sets the metadata base URI.

**Function Summary:**

1.  `constructor()`: Initializes the contract, ERC721, and the first epoch.
2.  `receive()`: Accepts ETH and forwards to `contributeBrushstroke`.
3.  `fallback()`: Accepts ETH and forwards to `contributeBrushstroke`.
4.  `contributeBrushstroke()`: Allows users to send ETH to add brushstrokes to the current epoch, influencing generative factors.
5.  `triggerEpochEnd()`: Called to finalize an epoch, determine the winner, record final state, and start the next epoch. Only possible after the epoch duration has passed.
6.  `claimEpochNFT(uint256 _epochId)`: Allows the determined winner of a sealed epoch to mint and claim their unique NFT.
7.  `getCurrentEpochId()`: Returns the ID of the currently active epoch.
8.  `getEpochData(uint256 _epochId)`: Returns the full data struct for a given epoch ID.
9.  `getEpochContributorBrushstrokes(uint256 _epochId, address _contributor)`: Returns the total brushstrokes contributed by a specific address in a specific epoch.
10. `getEpochBrushstrokePool(uint256 _epochId)`: Returns the total collective brushstrokes contributed in a specific epoch.
11. `isEpochEnded(uint256 _epochId)`: Returns true if the specified epoch's end time has passed.
12. `getEpochWinnerAddress(uint256 _epochId)`: Returns the address determined as the winner for a sealed epoch. Returns address(0) if not sealed or no winner yet.
13. `getEpochArtMetadataHash(uint256 _epochId)`: Returns the unique hash/identifier generated and stored for the art associated with a sealed epoch's NFT. Used by off-chain services.
14. `getCurrentInfluenceFactors()`: Returns the current state of the generative factors for the *active* epoch, influenced by contributions so far.
15. `balanceOf(address owner)`: ERC721 standard: Returns the number of NFTs owned by an address.
16. `ownerOf(uint256 tokenId)`: ERC721 standard: Returns the owner of a specific NFT.
17. `approve(address to, uint256 tokenId)`: ERC721 standard: Approves an address to manage a specific NFT.
18. `getApproved(uint256 tokenId)`: ERC721 standard: Returns the approved address for an NFT.
19. `setApprovalForAll(address operator, bool approved)`: ERC721 standard: Approves/disapproves an operator for all owner's NFTs.
20. `isApprovedForAll(address owner, address operator)`: ERC721 standard: Checks if an operator is approved for all owner's NFTs.
21. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers ownership of an NFT.
22. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers ownership, checks if recipient can receive ERC721s.
23. `tokenURI(uint256 tokenId)`: ERC721 standard: Returns the URI pointing to the metadata for an NFT. This is dynamically generated using the base URI and the epoch's stored metadata hash/ID.
24. `supportsInterface(bytes4 interfaceId)`: ERC165 standard: Indicates which interfaces the contract implements.
25. `submitParameterProposal(address target, bytes memory callData, string memory description)`: Allows proposing changes to contract parameters or calling specific functions (via governance). Requires minimum brushstroke contribution to propose.
26. `voteOnProposal(uint256 proposalId, bool support)`: Allows eligible voters (e.g., past contributors, NFT holders - *for simplicity here, let's say anyone who contributed in the previous epoch*) to vote on an active proposal.
27. `executeProposal(uint256 proposalId)`: Attempts to execute a proposal if it has passed voting requirements and the execution delay has passed.
28. `getProposalState(uint256 proposalId)`: Returns the current state (Pending, Active, Succeeded, Defeated, Expired, Executed) of a proposal.
29. `getProposalById(uint256 proposalId)`: Returns the details of a specific proposal.
30. `getProposalVoteCount(uint256 proposalId)`: Returns the current vote counts for a proposal.
31. `getTotalPooledInfluence()`: Returns the total amount of ETH currently held by the contract from brushstrokes across all epochs (excluding withdrawn fees).
32. `withdrawProtocolFees()`: Allows the designated fee recipient to withdraw accumulated protocol fees.
33. `getProtocolFeePercentage()`: Returns the current percentage of brushstrokes collected as protocol fees.
34. `setBaseURI(string memory baseURI_)`: Allows the owner/governance to update the base URI for token metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title EtherealCanvas
/// @dev A generative art platform where users contribute to influence art parameters within epochs.
/// NFTs representing the generated art are minted at the end of each epoch.
/// Features include dynamic NFT metadata, epoch-based progression, contribution-driven parameters,
/// and a basic on-chain governance system for parameter adjustments.

// Outline:
// 1. License and Version
// 2. Imports
// 3. Error Codes
// 4. Enums (ProposalState)
// 5. Structs (GenerationFactors, Epoch, Proposal)
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Constructor
// 10. Receive/Fallback
// 11. Core Canvas/Epoch Functions
// 12. Generation Factor Functions (Internal/Pure)
// 13. ERC721 Standard Functions (Including dynamic tokenURI)
// 14. Governance Functions
// 15. Protocol/Utility Functions

// Function Summary:
// 1. constructor(): Initializes the contract, ERC721, and the first epoch.
// 2. receive(): Accepts ETH and forwards to contributeBrushstroke.
// 3. fallback(): Accepts ETH and forwards to contributeBrushstroke.
// 4. contributeBrushstroke(): Allows users to send ETH to add brushstrokes to the current epoch, influencing generative factors.
// 5. triggerEpochEnd(): Called to finalize an epoch, determine the winner, record final state, and start the next epoch. Only possible after the epoch duration has passed or contribution threshold reached (threshold not implemented in this version).
// 6. claimEpochNFT(uint256 _epochId): Allows the determined winner of a sealed epoch to mint and claim their unique NFT.
// 7. getCurrentEpochId(): Returns the ID of the currently active epoch.
// 8. getEpochData(uint256 _epochId): Returns the full data struct for a given epoch ID.
// 9. getEpochContributorBrushstrokes(uint256 _epochId, address _contributor): Returns the total brushstrokes contributed by a specific address in a specific epoch.
// 10. getEpochBrushstrokePool(uint256 _epochId): Returns the total collective brushstrokes contributed in a specific epoch.
// 11. isEpochEnded(uint256 _epochId): Returns true if the specified epoch's end time has passed.
// 12. getEpochWinnerAddress(uint256 _epochId): Returns the address determined as the winner for a sealed epoch. Returns address(0) if not sealed or no winner yet.
// 13. getEpochArtMetadataHash(uint256 _epochId): Returns the unique hash/identifier generated and stored for the art associated with a sealed epoch's NFT. Used by off-chain services.
// 14. getCurrentInfluenceFactors(): Returns the current state of the generative factors for the *active* epoch, influenced by contributions so far.
// 15. balanceOf(address owner): ERC721 standard: Returns the number of NFTs owned by an address.
// 16. ownerOf(uint256 tokenId): ERC721 standard: Returns the owner of a specific NFT.
// 17. approve(address to, uint256 tokenId): ERC721 standard: Approves an address to manage a specific NFT.
// 18. getApproved(uint256 tokenId): ERC721 standard: Returns the approved address for an NFT.
// 19. setApprovalForAll(address operator, bool approved): ERC721 standard: Approves/disapproves an operator for all owner's NFTs.
// 20. isApprovedForAll(address owner, address operator): ERC721 standard: Checks if an operator is approved for all owner's NFTs.
// 21. transferFrom(address from, address to, uint256 tokenId): ERC721 standard: Transfers ownership of an NFT.
// 22. safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard: Transfers ownership, checks if recipient can receive ERC721s.
// 23. tokenURI(uint256 tokenId): ERC721 standard: Returns the URI pointing to the metadata for an NFT. This is dynamically generated using the base URI and the epoch's stored metadata hash/ID.
// 24. supportsInterface(bytes4 interfaceId): ERC165 standard: Indicates which interfaces the contract implements.
// 25. submitParameterProposal(address target, bytes memory callData, string memory description): Allows proposing changes to contract parameters or calling specific functions (via governance). Requires minimum brushstroke contribution in previous epoch to propose/vote.
// 26. voteOnProposal(uint256 proposalId, bool support): Allows eligible voters (past contributors) to vote on an active proposal.
// 27. executeProposal(uint256 proposalId): Attempts to execute a proposal if it has passed voting requirements and the execution delay has passed.
// 28. getProposalState(uint256 proposalId): Returns the current state (Pending, Active, Succeeded, Defeated, Expired, Executed) of a proposal.
// 29. getProposalById(uint256 proposalId): Returns the details of a specific proposal.
// 30. getProposalVoteCount(uint256 proposalId): Returns the current vote counts for a proposal.
// 31. getTotalPooledInfluence(): Returns the total amount of ETH currently held by the contract from brushstrokes (excluding withdrawn fees).
// 32. withdrawProtocolFees(): Allows the designated fee recipient to withdraw accumulated protocol fees.
// 33. getProtocolFeePercentage(): Returns the current percentage of brushstrokes collected as protocol fees.
// 34. setBaseURI(string memory baseURI_): Allows the owner/governance to update the base URI for token metadata.

contract EtherealCanvas is ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Error Codes ---
    error InvalidAmount(uint256 required, uint256 provided);
    error EpochNotEnded(uint256 epochId);
    error EpochNotSealed(uint256 epochId);
    error EpochAlreadyClaimed(uint256 epochId);
    error NotEpochWinner(uint256 epochId);
    error EpochNotReadyForClaim(uint256 epochId);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotActive(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId);
    error NotEligibleVoter(); // For governance
    error ProposalNotExecutable(uint256 proposalId);
    error ProposalExecutionFailed(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error NothingToWithdraw();
    error InvalidFeePercentage(uint256 percentage);

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Expired,
        Executed
    }

    // --- Structs ---
    /// @dev Represents the parameters that influence the generative art algorithm off-chain.
    /// These are dynamically influenced by contributions.
    struct GenerationFactors {
        uint256 colorHueFactor; // Influenced by total brushstrokes
        uint256 complexityFactor; // Influenced by number of contributors
        uint256 spatialArrangementFactor; // Influenced by timing and epoch ID
        // Add more factors as needed for the generative process
    }

    /// @dev Represents a single epoch of the canvas.
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 totalBrushstrokes;
        address topContributor; // Stored during epoch for gas efficiency
        uint256 maxBrushstrokesInEpoch; // Stored during epoch for gas efficiency
        address winnerAddress; // Determined after epoch ends
        bool claimed; // True if the NFT has been minted and claimed
        string artMetadataHash; // Hash or identifier generated by off-chain service based on final state
        bool isSealed; // True after triggerEpochEnd is called
    }

    /// @dev Represents a governance proposal.
    struct Proposal {
        address proposer;
        address target; // Contract address the proposal interacts with
        bytes callData; // Encoded function call data
        string description; // Description of the proposal
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 executionTimestamp; // Time after which it can be executed if successful
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted; // Track who voted
        ProposalState state; // Current state of the proposal
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    uint256 public epochCounter;
    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => mapping(address => uint256)) private brushstrokesByEpochAndContributor;

    GenerationFactors public currentGenerationFactors; // Factors for the currently active epoch

    uint256 public protocolFeePercentage; // Stored as basis points (e.g., 100 = 1%)
    uint256 private _protocolFeesCollected; // Total fees awaiting withdrawal
    address public protocolFeeRecipient;

    uint256 public epochDuration; // Duration of each epoch in seconds
    uint256 public minBrushstrokeAmount; // Minimum amount of ETH per contribution

    // Governance
    Counters.Counter private _proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minimumVotesForProposal; // Minimum total votes needed for a proposal to succeed/fail
    uint256 public proposalVotingPeriod; // Duration proposals are active for voting
    uint256 public executionDelay; // Time between proposal success and executable time
    mapping(address => uint256) private _lastEpochContributed; // Track contribution history for voting eligibility

    string private _baseTokenURI; // Base URI for token metadata (e.g., https://etherealcanvas.xyz/api/metadata/)

    // --- Events ---
    event BrushstrokeContributed(uint256 indexed epochId, address indexed contributor, uint256 amount, uint256 totalInEpoch);
    event EpochEnded(uint256 indexed epochId, address indexed winner, string artMetadataHash, uint256 nextEpochId);
    event EpochGeneratedNFTClaimed(uint256 indexed epochId, address indexed winner, uint256 indexed tokenId);
    event GenerationFactorsUpdated(uint256 indexed epochId, GenerationFactors factors);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address indexed target, string description, uint256 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event BaseURIUpdated(string newURI);


    // --- Modifiers ---
    modifier whenEpochNotEnded(uint256 _epochId) {
        if (block.timestamp >= epochs[_epochId].endTime) revert EpochNotEnded(_epochId);
        _;
    }

    modifier whenEpochEnded(uint256 _epochId) {
        if (block.timestamp < epochs[_epochId].endTime) revert EpochNotEnded(_epochId);
        _;
        // Ensure epoch is sealed before allowing actions dependent on final state
        if (!epochs[_epochId].isSealed) revert EpochNotSealed(_epochId);
    }

    modifier onlyEpochWinner(uint256 _epochId) {
        if (msg.sender != epochs[_epochId].winnerAddress) revert NotEpochWinner(_epochId);
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address initialFeeRecipient,
        uint256 initialEpochDuration, // in seconds
        uint256 initialMinBrushstrokeAmount, // in wei
        uint256 initialMinVotesForProposal,
        uint256 initialProposalVotingPeriod, // in seconds
        uint256 initialExecutionDelay, // in seconds
        string memory initialBaseURI
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        if (initialFeeRecipient == address(0)) revert OwnableInvalidOwner(address(0));
        protocolFeeRecipient = initialFeeRecipient;
        protocolFeePercentage = 500; // 5% initially
        epochDuration = initialEpochDuration;
        minBrushstrokeAmount = initialMinBrushstrokeAmount;

        minimumVotesForProposal = initialMinVotesForProposal;
        proposalVotingPeriod = initialProposalVotingPeriod;
        executionDelay = initialExecutionDelay;

        _baseTokenURI = initialBaseURI;

        // Start the first epoch
        epochs[epochCounter].startTime = block.timestamp;
        epochs[epochCounter].endTime = block.timestamp + epochDuration;
        epochs[epochCounter].totalBrushstrokes = 0;
        epochs[epochCounter].maxBrushstrokesInEpoch = 0; // Initialize
        epochs[epochCounter].isSealed = false; // Not sealed yet
        // winnerAddress, claimed, artMetadataHash are set in triggerEpochEnd

        // Initialize factors - can be based on a starting seed or just zeros
        currentGenerationFactors = GenerationFactors({
            colorHueFactor: 0,
            complexityFactor: 0,
            spatialArrangementFactor: 0
        });

        emit EpochEnded(0, address(0), "", 1); // Indicate epoch 0 started (or epoch 1 starting)
    }

    // --- Receive/Fallback ---
    receive() external payable {
        contributeBrushstroke();
    }

    fallback() external payable {
        contributeBrushstroke();
    }

    // --- Core Canvas/Epoch Functions ---

    /// @notice Allows a user to contribute ETH as a "brushstroke" to the current epoch.
    /// This influences the generation factors for the epoch's art.
    /// @dev The received ETH value is recorded as brushstrokes. A protocol fee is deducted.
    function contributeBrushstroke() public payable whenEpochNotEnded(epochCounter) nonReentrant {
        uint256 amount = msg.value;
        if (amount < minBrushstrokeAmount) revert InvalidAmount(minBrushstrokeAmount, amount);

        uint256 feeAmount = amount.mul(protocolFeePercentage).div(10000); // protocolFeePercentage is in basis points
        uint256 brushstrokeValue = amount.sub(feeAmount);

        _protocolFeesCollected = _protocolFeesCollected.add(feeAmount);

        // Update epoch totals and contributor amount
        epochs[epochCounter].totalBrushstrokes = epochs[epochCounter].totalBrushstrokes.add(brushstrokeValue);
        brushstrokesByEpochAndContributor[epochCounter][msg.sender] = brushstrokesByEpochAndContributor[epochCounter][msg.sender].add(brushstrokeValue);

        // Track top contributor for easier winner determination
        if (brushstrokesByEpochAndContributor[epochCounter][msg.sender] > epochs[epochCounter].maxBrushstrokesInEpoch) {
            epochs[epochCounter].maxBrushstrokesInEpoch = brushstrokesByEpochAndContributor[epochCounter][msg.sender];
            epochs[epochCounter].topContributor = msg.sender;
        }

        // Record contribution history for governance eligibility (track last epoch they contributed)
         _lastEpochContributed[msg.sender] = epochCounter;


        // Dynamically update generation factors based on *all* contributions in this epoch
        // This is a simplified example. More complex derivations can be implemented.
        // Example: Factors influenced by total brushstrokes, number of contributors, time elapsed, etc.
        uint256 currentTotal = epochs[epochCounter].totalBrushstrokes;
        uint256 timeElapsed = block.timestamp.sub(epochs[epochCounter].startTime);

        // Simple influence example:
        currentGenerationFactors.colorHueFactor = (currentTotal / 1 ether) % 360; // Hue based on total ETH
        currentGenerationFactors.complexityFactor = (currentTotal / (1 ether / 100)) % 100; // Complexity based on total ETH (scaled)
        currentGenerationFactors.spatialArrangementFactor = (timeElapsed / 1 minutes) % 100; // Arrangement based on time elapsed (simplified)

        emit BrushstrokeContributed(epochCounter, msg.sender, brushstrokeValue, epochs[epochCounter].totalBrushstrokes);
        emit GenerationFactorsUpdated(epochCounter, currentGenerationFactors);
    }

    /// @notice Triggers the end of the current epoch, determines the winner, seals the epoch state,
    /// records the final generation parameters/metadata hash, and starts a new epoch.
    /// @dev Can only be called after the epoch's end time. Requires off-chain service interaction
    /// to generate and store the art metadata, returning a hash/identifier.
    /// NOTE: Winner determination here is simply the highest contributor. More complex/fair methods are possible
    /// but are more gas-intensive (e.g., weighted random pick, distributing among top N).
    function triggerEpochEnd(string memory _finalArtMetadataHash) public whenEpochEnded(epochCounter) nonReentrant {
        uint256 currentId = epochCounter;
        Epoch storage currentEpoch = epochs[currentId];

        if (currentEpoch.isSealed) {
             // This epoch was already sealed, perhaps trigger next one if its time has passed too?
             // Or just revert if the intent was to seal THIS epoch. Let's revert for clarity.
             // If we want auto-chaining, needs more complex logic.
             revert EpochAlreadyClaimed(currentId); // Re-using error, maybe add EpochAlreadySealed
        }

        // Determine Winner (Simple: Top Contributor)
        // If no brushstrokes, the winner is address(0) and no NFT is minted
        if (currentEpoch.totalBrushstrokes > 0) {
             currentEpoch.winnerAddress = currentEpoch.topContributor;
        } else {
             currentEpoch.winnerAddress = address(0); // No winner if no contributions
        }


        // Seal the epoch state and store the generated metadata hash
        // The _finalArtMetadataHash is expected from an off-chain service that generated
        // the art/metadata based on the final `currentGenerationFactors` and other epoch data.
        currentEpoch.artMetadataHash = _finalArtMetadataHash;
        currentEpoch.isSealed = true; // Mark epoch as sealed

        // Store a copy of the final generation factors for this epoch's history
        // This could be done by storing `currentGenerationFactors` within the Epoch struct
        // Or simply trusting the off-chain service used the factors before they reset for the new epoch.
        // Storing the hash is simpler and implies the off-chain service did its job.

        // Increment epoch counter and start the new epoch
        epochCounter++;
        epochs[epochCounter].startTime = block.timestamp;
        epochs[epochCounter].endTime = block.timestamp + epochDuration;
        epochs[epochCounter].totalBrushstrokes = 0;
        epochs[epochCounter].maxBrushstrokesInEpoch = 0;
        epochs[epochCounter].isSealed = false;
        // winnerAddress, claimed, artMetadataHash default to zero/false/empty

        // Reset current generation factors for the new epoch
         currentGenerationFactors = GenerationFactors({
            colorHueFactor: 0,
            complexityFactor: 0,
            spatialArrangementFactor: 0
        });

        emit EpochEnded(currentId, currentEpoch.winnerAddress, currentEpoch.artMetadataHash, epochCounter);
        emit GenerationFactorsUpdated(epochCounter, currentGenerationFactors); // Factors for the new epoch
    }


    /// @notice Allows the winner of a sealed epoch to claim their generated NFT.
    /// @param _epochId The ID of the epoch for which to claim the NFT.
    function claimEpochNFT(uint256 _epochId) public whenEpochEnded(_epochId) onlyEpochWinner(_epochId) nonReentrant {
        Epoch storage epoch = epochs[_epochId];

        if (epoch.winnerAddress == address(0)) revert EpochNotReadyForClaim(_epochId); // No winner for this epoch
        if (epoch.claimed) revert EpochAlreadyClaimed(_epochId);

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Mint the NFT to the winner
        _safeMint(epoch.winnerAddress, newTokenId);
        // Set the metadata URI for this specific token
        // The tokenURI function will construct the full URI using the base and the stored hash
        _setTokenURI(newTokenId, epoch.artMetadataHash); // Store the specific hash/identifier

        epoch.claimed = true; // Mark as claimed

        emit EpochGeneratedNFTClaimed(_epochId, epoch.winnerAddress, newTokenId);
    }

    /// @notice Gets the ID of the currently active epoch.
    /// @return The current epoch ID.
    function getCurrentEpochId() public view returns (uint256) {
        return epochCounter;
    }

    /// @notice Gets the data for a specific epoch.
    /// @param _epochId The ID of the epoch to retrieve data for.
    /// @return The Epoch struct data.
    function getEpochData(uint256 _epochId) public view returns (Epoch memory) {
        return epochs[_epochId];
    }

    /// @notice Gets the brushstrokes contributed by a specific user in a given epoch.
    /// @param _epochId The epoch ID.
    /// @param _contributor The address of the contributor.
    /// @return The total brushstrokes contributed by the user in that epoch.
    function getEpochContributorBrushstrokes(uint256 _epochId, address _contributor) public view returns (uint256) {
        return brushstrokesByEpochAndContributor[_epochId][_contributor];
    }

    /// @notice Gets the total brushstrokes contributed in a specific epoch.
    /// @param _epochId The epoch ID.
    /// @return The total brushstrokes (ETH value after fees) in the epoch.
    function getEpochBrushstrokePool(uint256 _epochId) public view returns (uint256) {
        return epochs[_epochId].totalBrushstrokes;
    }

    /// @notice Checks if a specific epoch has ended based on block timestamp.
    /// @param _epochId The epoch ID.
    /// @return True if the epoch end time has passed, false otherwise.
    function isEpochEnded(uint256 _epochId) public view returns (bool) {
        // For current epoch, check against block.timestamp
        if (_epochId == epochCounter) {
            return block.timestamp >= epochs[_epochId].endTime;
        }
        // For past epochs, check if sealed (implies it ended)
        return epochs[_epochId].isSealed;
    }

     /// @notice Gets the winner address for a specific epoch.
     /// @dev Winner is determined only after triggerEpochEnd is called for that epoch.
     /// @param _epochId The epoch ID.
     /// @return The winner's address, or address(0) if not determined or no winner.
    function getEpochWinnerAddress(uint256 _epochId) public view returns (address) {
        // Accessing epochs struct directly is public, but let's add a dedicated view for clarity
        return epochs[_epochId].winnerAddress;
    }

     /// @notice Gets the stored metadata hash/identifier for the art generated for a sealed epoch.
     /// @dev This hash is set by triggerEpochEnd based on off-chain generation.
     /// @param _epochId The epoch ID.
     /// @return The art metadata hash/identifier string.
    function getEpochArtMetadataHash(uint256 _epochId) public view returns (string memory) {
        // Accessing epochs struct directly is public, but let's add a dedicated view for clarity
        return epochs[_epochId].artMetadataHash;
    }

    // --- Generation Factor Functions ---

    /// @notice Gets the current generation factors for the *active* epoch.
    /// @dev These factors are influenced by contributions and reset each epoch.
    /// @return The GenerationFactors struct for the current epoch.
    function getCurrentInfluenceFactors() public view returns (GenerationFactors memory) {
        // Return the state variable directly
        return currentGenerationFactors;
    }

    /// @notice Internal pure function to calculate generation factors (example logic).
    /// @dev This is where the logic for translating contributions into art parameters resides.
    /// @param _totalBrushstrokes Total brushstrokes in the epoch.
    /// @param _timeElapsed Time elapsed in the epoch.
    /// @return Derived GenerationFactors.
    function calculateInfluenceFactors(uint256 _totalBrushstrokes, uint256 _timeElapsed) internal pure returns (GenerationFactors memory) {
        // This is a placeholder/example. The real logic would be complex and deterministic.
        // It could use cryptographic functions, aggregate contribution data, etc.
        // Note: Direct use of block.timestamp or blockhash here should be understood for its limitations (miner manipulation).
        // A safer approach might average values over time or use external oracles for entropy.
        return GenerationFactors({
            colorHueFactor: (_totalBrushstrokes / 1 ether) % 360,
            complexityFactor: (_totalBrushstrokes / (1 ether / 100)) % 100,
            spatialArrangementFactor: (_timeElapsed / 1 minutes) % 100
        });
    }


    // --- ERC721 Standard Functions ---

    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom
    // are provided by ERC721 and ERC721URIStorage base contracts.

    /// @notice Overrides the standard tokenURI to provide dynamic metadata based on epoch data.
    /// @param tokenId The ID of the NFT.
    /// @return The URI pointing to the dynamic metadata endpoint.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // The token ID corresponds to the epoch ID that generated it
        uint256 epochId = tokenId; // Assuming 1:1 mapping tokenId to epochId for simplicity

        // Check if the epoch is sealed and has a metadata hash
        if (!epochs[epochId].isSealed || bytes(epochs[epochId].artMetadataHash).length == 0) {
            // Metadata not ready or epoch not sealed
            return super.tokenURI(tokenId); // Fallback or error? Let's fallback to whatever _tokenURIs has (likely empty)
        }

        // Construct the dynamic URI: baseURI + epochId + "/" + metadataHash
        // The off-chain service at baseURI will use epochId and metadataHash to serve the correct JSON/image.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             return super.tokenURI(tokenId); // Fallback if base URI not set
        }

        return string(abi.encodePacked(base, Strings.toString(epochId), "/", epochs[epochId].artMetadataHash));
    }

    /// @notice Standard ERC165 function to check supported interfaces.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Governance Functions ---
    // Eligibility for voting/proposing: User must have contributed in the *previous* completed epoch.

    /// @notice Allows eligible users to submit a proposal for changes.
    /// @param target The address of the contract to call (often `address(this)`).
    /// @param callData The encoded function call to be executed if the proposal passes.
    /// @param description A human-readable description of the proposal.
    function submitParameterProposal(address target, bytes memory callData, string memory description) public nonReentrant {
        // Eligibility: Must have contributed in the previous, already sealed epoch
        if (_lastEpochContributed[msg.sender] != epochCounter - 1) {
             revert NotEligibleVoter(); // User didn't contribute in the last sealed epoch
        }

        uint256 proposalId = _proposalCounter.current();
        _proposalCounter.increment();

        proposals[proposalId].proposer = msg.sender;
        proposals[proposalId].target = target;
        proposals[proposalId].callData = callData;
        proposals[proposalId].description = description;
        proposals[proposalId].creationTimestamp = block.timestamp;
        proposals[proposalId].votingDeadline = block.timestamp + proposalVotingPeriod;
        proposals[proposalId].state = ProposalState.Active;

        emit ProposalSubmitted(proposalId, msg.sender, target, description, proposals[proposalId].votingDeadline);
    }

    /// @notice Allows eligible users to vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'yes' vote, false for 'no' vote.
    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId); // Check if proposal exists
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(proposalId);

        // Eligibility: Must have contributed in the previous, already sealed epoch
        if (_lastEpochContributed[msg.sender] != epochCounter - 1) {
             revert NotEligibleVoter(); // User didn't contribute in the last sealed epoch
        }

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);

        // Automatically update state if voting period ends or quorum reached (simplified)
        _updateProposalState(proposalId);
    }

    /// @notice Attempts to execute a proposal that has passed voting requirements and the delay.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId); // Check if proposal exists
        if (proposal.executed) revert ProposalAlreadyExecuted(proposalId);

        // Ensure state is updated (in case voting period ended without any votes)
        _updateProposalState(proposalId);

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable(proposalId);
        if (block.timestamp < proposal.executionTimestamp) revert ProposalNotExecutable(proposalId); // Not past execution delay

        // Execute the proposed call
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) {
            // Even if execution fails, mark as attempted execution to prevent repeated calls
            proposal.executed = true;
            emit ProposalExecutionFailed(proposalId);
            revert ProposalExecutionFailed(proposalId); // Indicate failure
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Gets the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The ProposalState enum value.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) return ProposalState.Pending; // Or throw? Let's return Pending for non-existent
        // Check state based on current time if Active
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             // Voting period ended, determine final state
             if (proposal.votesFor > proposal.votesAgainst && (proposal.votesFor + proposal.votesAgainst) >= minimumVotesForProposal) {
                  return ProposalState.Succeeded;
             } else {
                  return ProposalState.Defeated;
             }
        }
        // Check if successfully executed
        if (proposal.executed) {
             return ProposalState.Executed;
        }
        return proposal.state;
    }

    /// @notice Gets the details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct data (excluding internal mappings).
    function getProposalById(uint256 proposalId) public view returns (
        address proposer,
        address target,
        bytes memory callData,
        string memory description,
        uint256 creationTimestamp,
        uint256 votingDeadline,
        uint256 executionTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId);

        return (
            proposal.proposer,
            proposal.target,
            proposal.callData,
            proposal.description,
            proposal.creationTimestamp,
            proposal.votingDeadline,
            proposal.executionTimestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            getProposalState(proposalId) // Always return the current state
        );
    }

    /// @notice Gets the current vote counts for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return votesFor, votesAgainst
    function getProposalVoteCount(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(proposalId);
        return (proposal.votesFor, proposal.votesAgainst);
    }

    /// @dev Internal helper to update proposal state after voting ends or votes are cast.
    function _updateProposalState(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
            if (proposal.votesFor > proposal.votesAgainst && (proposal.votesFor + proposal.votesAgainst) >= minimumVotesForProposal) {
                proposal.state = ProposalState.Succeeded;
                proposal.executionTimestamp = block.timestamp + executionDelay;
            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
    }

    // --- Protocol/Utility Functions ---

    /// @notice Gets the total amount of ETH currently held by the contract from brushstrokes.
    /// @return The total balance received from brushstrokes (excluding fees already withdrawn).
    function getTotalPooledInfluence() public view returns (uint256) {
        // Note: This does not sum epoch.totalBrushstrokes as that's ETH *after* fees.
        // Contract balance includes fees and the brushstroke pool.
        // A precise pool value would require summing epoch.totalBrushstrokes + tracking pending fees per epoch.
        // Simplest is total contract balance minus accumulated fees ready for withdrawal.
        return address(this).balance.sub(_protocolFeesCollected);
    }

    /// @notice Allows the protocol fee recipient to withdraw accumulated fees.
    function withdrawProtocolFees() public nonReentrant {
        if (msg.sender != protocolFeeRecipient) revert OwnableUnauthorized(msg.sender);

        uint256 fees = _protocolFeesCollected;
        if (fees == 0) revert NothingToWithdraw();

        _protocolFeesCollected = 0;

        (bool success, ) = payable(protocolFeeRecipient).call{value: fees}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(protocolFeeRecipient, fees);
    }

    /// @notice Gets the current percentage of brushstrokes collected as protocol fees.
    /// @return The fee percentage in basis points (e.g., 500 means 5%).
    function getProtocolFeePercentage() public view returns (uint256) {
        return protocolFeePercentage;
    }

    /// @notice Allows owner or governance to set the base URI for token metadata.
    /// @dev This URI should point to a service that dynamically generates JSON metadata.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    // --- Governance Target Functions (Examples - callable via executeProposal) ---
    // These functions allow governance to modify core contract parameters.
    // They would be called using `executeProposal` targeting `address(this)` with encoded callData.

    /// @notice Allows governance to set the protocol fee percentage.
    /// @dev Callable only via governance proposal execution.
    /// @param percentage_ The new fee percentage in basis points (0-10000).
    function governorSetProtocolFeePercentage(uint256 percentage_) public onlyOwner { // Use onlyOwner for simplicity here, should be governance controlled
        if (percentage_ > 10000) revert InvalidFeePercentage(percentage_);
        protocolFeePercentage = percentage_;
    }

     /// @notice Allows governance to set the epoch duration.
    /// @dev Callable only via governance proposal execution.
    /// @param duration_ The new epoch duration in seconds.
    function governorSetEpochDuration(uint256 duration_) public onlyOwner { // Use onlyOwner for simplicity here, should be governance controlled
        if (duration_ == 0) revert InvalidAmount(1, 0);
        epochDuration = duration_;
    }

    /// @notice Allows governance to set the minimum brushstroke amount.
    /// @dev Callable only via governance proposal execution.
    /// @param minAmount_ The new minimum brushstroke amount in wei.
    function governorSetMinBrushstrokeAmount(uint256 minAmount_) public onlyOwner { // Use onlyOwner for simplicity here, should be governance controlled
        minBrushstrokeAmount = minAmount_;
    }

    /// @notice Allows governance to set governance parameters.
    /// @dev Callable only via governance proposal execution.
    function governorSetGovernanceParameters(
        uint256 _minimumVotesForProposal,
        uint256 _proposalVotingPeriod,
        uint256 _executionDelay
    ) public onlyOwner { // Use onlyOwner for simplicity here, should be governance controlled
        minimumVotesForProposal = _minimumVotesForProposal;
        proposalVotingPeriod = _proposalVotingPeriod;
        executionDelay = _executionDelay;
    }

    // Potential advanced governance functions:
    // - governorSetGenerationFactorWeights(uint256[] memory weights): Adjust how contributions influence factors.
    // - governorSetWinnerDeterminationLogic(address newLogicContract): Upgradeable winner logic.
    // - governorUpgradeContract(address newImplementation): For upgradeable proxies (requires proxy pattern).
}
```