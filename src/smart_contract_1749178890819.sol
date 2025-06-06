Okay, let's design a smart contract around an advanced, creative, and trendy concept: **Dynamic, Oracle-Driven NFTs with Community Governance and Interaction Mechanics.**

We'll call this contract `EpochGlyph`. Each `EpochGlyph` will be a unique NFT representing a point in time or an event influenced by external data feeds. Its visual traits or internal "score" can change based on data delivered by registered oracles. The community holding `EpochGlyphs` can propose and vote on which data feeds are tracked, parameters, or even future features. It also includes basic interaction mechanics like staking and combining Glyphs.

This concept incorporates:
1.  **Dynamic NFTs:** NFT state changes based on external factors.
2.  **Oracle Integration:** Relying on off-chain data (simulated via callback for this example).
3.  **On-chain Governance:** Token-weighted voting (using NFT count) for key decisions.
4.  **Interaction Mechanics:** Staking and combining Glyphs.

---

## Smart Contract: EpochGlyph

**Concept:** A dynamic NFT contract where each token represents an 'Epoch Glyph'. These Glyphs track external data feeds (via oracles), and their internal 'score' or state evolves based on this data. Governance is handled by NFT holders, allowing them to influence contract parameters and approved data feeds.

**Outline:**

1.  **Interfaces:** Define interfaces for expected Oracle interactions.
2.  **Errors:** Custom error definitions for clarity.
3.  **Events:** Emit events for key actions (Minting, Updates, Governance, Staking, etc.).
4.  **Structs:** Define data structures for Glyphs, Data Feeds, Governance Proposals.
5.  **Enums:** Define states for Proposals.
6.  **State Variables:** Store contract configuration, Oracle registry, Glyph data, Governance data, Staking data.
7.  **Modifiers:** Access control and state checks.
8.  **Constructor:** Initialize contract state.
9.  **Core ERC721 Functions (Overridden/Wrapped):** Custom minting, potential custom burning.
10. **Oracle Management:** Registering, unregistering, setting feed mappings.
11. **Glyph Data Management:** Adding/removing feeds from a Glyph, requesting data updates, processing oracle callbacks, recalculating Glyph scores.
12. **Governance Mechanism:** Proposing changes (feeds, parameters), voting, executing proposals.
13. **Glyph Interaction Mechanics:** Staking Glyphs, Unstaking, Claiming rewards, Combining Glyphs.
14. **Query/View Functions:** Read contract state, Glyph data, proposal details, staking info.
15. **Administrative Functions:** Pause/unpause, withdraw fees (if added).

**Function Summary:**

*   `constructor()`: Initializes contract, sets owner, base URI, and initial governance parameters.
*   `registerOracle(address _oracleAddress, string memory _name)`: Registers a trusted oracle contract address.
*   `unregisterOracle(address _oracleAddress)`: Removes a registered oracle address.
*   `setGlobalFeedMapping(uint256 _feedId, address _oracleAddress, bytes32 _oracleSpecificId, string memory _description)`: Maps a global `feedId` used within the contract to a specific oracle and its internal feed identifier.
*   `removeGlobalFeedMapping(uint256 _feedId)`: Removes a global feed mapping.
*   `mintGlyphWithFeeds(address _to, uint256[] memory _initialFeedIds)`: Mints a new `EpochGlyph` token to `_to`, assigning it initial data feeds specified by `_initialFeedIds`.
*   `burnGlyph(uint256 _tokenId)`: Burns an `EpochGlyph` token. Includes checks for staked tokens.
*   `addFeedToGlyph(uint256 _tokenId, uint256 _feedId, uint256 _initialWeight)`: Adds a specified global feed to an existing Glyph, setting its initial weight for scoring. Requires token ownership or approval.
*   `removeFeedFromGlyph(uint256 _tokenId, uint256 _feedId)`: Removes a feed from a Glyph's tracking list. Requires token ownership or approval.
*   `updateGlyphMetadataURI(uint256 _tokenId, string memory _newURI)`: Allows owner/governance (or potentially logic based on score) to update a Glyph's metadata URI.
*   `requestFeedUpdateForGlyph(uint256 _tokenId, uint256 _feedId)`: Triggers an oracle data request for a specific feed associated with a Glyph. Can potentially require payment or specific role.
*   `callbackOracleData(address _oracleAddress, uint256 _requestId, int256 _value, uint256 _timestamp)`: Internal/Callback function called by a registered oracle to deliver data. Processes the data, updates the Glyph's state, and recalculates the score.
*   `recalculateGlyphScore(uint256 _tokenId)`: Manually triggers the score calculation for a Glyph based on its current feed values and weights.
*   `setGlyphFeedWeight(uint256 _tokenId, uint256 _feedId, uint256 _newWeight)`: Allows the token owner/approved address to adjust the weight of a specific feed *for their specific Glyph*, influencing its score calculation.
*   `proposeConfigChange(string memory _description, bytes memory _calldata)`: Creates a governance proposal to call another function (e.g., set governance parameters, update base URI, add/remove global feeds). Requires holding Glyphs to propose.
*   `proposeNewGlobalFeedMapping(uint256 _feedId, address _oracleAddress, bytes32 _oracleSpecificId, string memory _description, uint256 _initialWeight)`: Creates a specific proposal type to add a new global feed mapping and its default weight.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows Glyph holders to cast a vote (Yes/No) on an active proposal. Voting weight is based on the number of Glyphs held at the start of the voting period.
*   `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting period and met the quorum/threshold requirements.
*   `cancelProposal(uint256 _proposalId)`: Allows the proposer or governance to cancel a proposal under specific conditions (e.g., before voting starts).
*   `stakeGlyph(uint256 _tokenId)`: Stakes a Glyph token, removing it from the owner's direct wallet control and placing it into a staking pool. Requires token approval.
*   `unstakeGlyph(uint256 _tokenId)`: Unstakes a staked Glyph token, returning it to the owner.
*   `claimStakingRewards()`: Allows a user to claim accumulated rewards from their staked Glyphs (Reward mechanism simplified for this example - could be yield, other tokens, etc.).
*   `combineGlyphs(uint256 _tokenId1, uint256 _tokenId2)`: A creative function allowing two Glyphs to be 'combined'. This could result in burning the originals and minting a new one with combined feeds, averaged/summed score logic, or a new trait based on inputs. (Simplified implementation: burns originals, mints new with combined feeds and recalculated score).
*   `getGlyphData(uint256 _tokenId)`: View function returning detailed data about a specific Glyph (feeds, values, weights, score, update times).
*   `getGlobalFeedDetails(uint256 _feedId)`: View function returning details about a globally registered feed mapping.
*   `getProposalDetails(uint256 _proposalId)`: View function returning the state, details, and vote counts for a specific proposal.
*   `getStakingInfo(address _owner)`: View function returning information about Glyphs staked by a specific address.
*   `calculateCurrentGlyphScore(uint256 _tokenId)`: View function to calculate and return the current score of a Glyph *without* updating the on-chain state (useful for UI).
*   `pause()`: Allows the owner to pause core contract functionality (minting, transfers, staking, combining).
*   `unpause()`: Allows the owner to unpause the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For individual metadata URI

// Minimal interface for expected oracle functionality
interface IEpochGlyphOracle {
    // Function for EpochGlyph to request data
    function requestData(bytes32 _oracleSpecificId, uint256 _requestId, address _callbackContract) external;

    // Function for the oracle to call back with data
    // NOTE: Real Chainlink/similar oracles use different patterns (fulfill),
    // this is a simplified model for demonstration.
    // Actual implementation would integrate with specific oracle network.
    // function fulfill(bytes32 requestId, int256 value) external; // Chainlink pattern
}

/**
 * @title EpochGlyph
 * @dev Dynamic, Oracle-Driven NFT with Governance and Interaction
 *
 * Concept: ERC721 tokens (Glyphs) whose state (score) is influenced by external data feeds
 * delivered by registered oracles. NFT holders participate in governance to manage feeds
 * and contract parameters. Includes staking and combining mechanics.
 */
contract EpochGlyph is ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    // --- Errors ---
    error EpochGlyph__OracleNotRegistered(address _oracleAddress);
    error EpochGlyph__FeedMappingDoesNotExist(uint256 _feedId);
    error EpochGlyph__FeedAlreadyExistsOnGlyph(uint256 _tokenId, uint256 _feedId);
    error EpochGlyph__FeedNotOnGlyph(uint256 _tokenId, uint256 _feedId);
    error EpochGlyph__NotOracleCallback(address _caller);
    error EpochGlyph__InvalidCallbackData(uint256 _requestId);
    error EpochGlyph__GlyphNotOwnedOrApproved(uint256 _tokenId);
    error EpochGlyph__CannotVoteOnInactiveProposal(uint256 _proposalId);
    error EpochGlyph__AlreadyVoted(uint256 _proposalId, address _voter);
    error EpochGlyph__CannotExecuteProposal(uint256 _proposalId, string reason);
    error EpochGlyph__CannotCancelProposal(uint256 _proposalId, string reason);
    error EpochGlyph__GlyphAlreadyStaked(uint256 _tokenId);
    error EpochGlyph__GlyphNotStaked(uint256 _tokenId);
    error EpochGlyph__StakingRewardsNotAvailable();
    error EpochGlyph__CannotCombineSameGlyph(uint256 _tokenId);
    error EpochGlyph__CombinationRequiresOwnedGlyphs();
    error EpochGlyph__OracleSpecificIdAlreadyUsedForFeed(address _oracleAddress, bytes32 _oracleSpecificId);
    error EpochGlyph__ProposalRequiresGlyphs();
    error EpochGlyph__InvalidProposalCalldata();

    // --- Events ---
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleUnregistered(address indexed oracleAddress);
    event GlobalFeedMappingSet(uint256 indexed feedId, address indexed oracleAddress, bytes32 oracleSpecificId, string description);
    event GlobalFeedMappingRemoved(uint256 indexed feedId);
    event GlyphMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialFeedIds);
    event GlyphBurned(uint256 indexed tokenId);
    event FeedAddedToGlyph(uint256 indexed tokenId, uint256 indexed feedId, uint256 weight);
    event FeedRemovedFromGlyph(uint256 indexed tokenId, uint256 indexed feedId);
    event GlyphMetadataUpdated(uint256 indexed tokenId, string newURI);
    event FeedUpdateRequestSent(uint256 indexed tokenId, uint256 indexed feedId, uint256 requestId);
    event OracleDataCallbackReceived(uint256 indexed requestId, int256 value, uint256 timestamp);
    event GlyphScoreRecalculated(uint256 indexed tokenId, int256 newScore, uint256 lastCalculationTimestamp);
    event GlyphFeedWeightUpdated(uint256 indexed tokenId, uint256 indexed feedId, uint256 newWeight);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 startBlock, uint256 endBlock, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votes, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event GlyphStaked(uint256 indexed tokenId, address indexed owner);
    event GlyphUnstaked(uint256 indexed tokenId, address indexed owner);
    event StakingRewardsClaimed(address indexed owner, uint256 amount); // Amount based on internal reward logic
    event GlyphsCombined(uint256[] indexed inputTokenIds, uint256 indexed outputTokenId, address indexed owner);
    event Paused(address account);
    event Unpaused(address account);

    // --- Structs ---
    struct FeedData {
        int256 latestValue;
        uint256 lastUpdatedTimestamp;
    }

    struct Glyph {
        uint256[] feedIds; // Global feed IDs associated with this specific glyph
        mapping(uint256 => uint256) feedWeights; // Weight for each feed on this specific glyph
        mapping(uint256 => FeedData) feedData; // Latest data per feed for this glyph
        int256 score;
        uint256 lastScoreCalculationTimestamp;
    }

    struct GlobalFeedMapping {
        address oracleAddress;
        bytes32 oracleSpecificId; // ID used by the external oracle system
        string description;
        uint256 defaultWeight; // Default weight when adding to a Glyph
        bool exists; // Flag to check if mapping exists
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed,
        Expired
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        string description;
        bytes calldata; // Data to execute if proposal passes (e.g., function call)
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => has voted
        ProposalState state;
        uint256 quorumRequired; // Minimum votes required for proposal to pass
        uint256 voteThreshold; // Percentage of votesFor needed to pass (e.g., 51%)
    }

    struct StakingInfo {
        bool isStaked;
        uint256 stakedTimestamp;
        // Add fields here for reward tracking if implementing complex rewards
        // uint256 accumulatedRewards;
    }

    // --- State Variables ---
    uint256 private _nextTokenId; // Counter for unique token IDs

    // Oracle Management
    mapping(address => string) public registeredOracles; // Address => Name
    mapping(address => mapping(bytes32 => uint256)) private _oracleSpecificIdToGlobalFeedId; // Map external oracle ID to internal global feed ID
    mapping(uint256 => GlobalFeedMapping) public globalFeedMappings; // Internal feed ID => Global details
    uint256 public nextGlobalFeedId = 1; // Counter for global feed IDs

    // Glyph Data
    mapping(uint256 => Glyph) public glyphs; // tokenId => Glyph data

    // Oracle Request Tracking (Simplified)
    uint256 private _nextRequestId = 1;
    mapping(uint256 => address) private _requestInitiator; // request ID => address who initiated
    mapping(uint256 => uint256) private _requestTokenId; // request ID => tokenId
    mapping(uint256 => uint256) private _requestFeedId; // request ID => feedId

    // Governance
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal data
    uint256 public governanceVotingPeriodBlocks; // How many blocks voting is open
    uint256 public governanceQuorumPercent; // Percentage of total supply needed to vote for quorum (e.g., 4%)
    uint256 public governanceVoteThresholdPercent; // Percentage of votesFor out of total votes (for + against) to pass (e.g., 51%)
    uint256 public proposalCreationTokenStake; // Number of Glyphs required to create a proposal (optional, but good for spam prevention)

    // Staking
    mapping(uint256 => StakingInfo) private _stakedGlyphs; // tokenId => Staking info
    mapping(address => uint256[]) private _stakedGlyphsByOwner; // owner => list of staked tokenIds (basic list for retrieval)
    // Note: Reward logic is simplified/placeholder. Complex reward pools would need more state.

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        uint256 initialVotingPeriodBlocks,
        uint256 initialQuorumPercent,
        uint256 initialVoteThresholdPercent,
        uint256 initialProposalStake
    ) ERC721(name, symbol) ERC721URIStorage(baseUri) Ownable(msg.sender) {
        governanceVotingPeriodBlocks = initialVotingPeriodBlocks;
        governanceQuorumPercent = initialQuorumPercent;
        governanceVoteThresholdPercent = initialVoteThresholdPercent;
        proposalCreationTokenStake = initialProposalStake;
    }

    // --- Modifiers ---
    modifier onlyRegisteredOracle() {
        if (bytes(registeredOracles[msg.sender]).length == 0) {
             revert EpochGlyph__NotOracleCallback(msg.sender);
        }
        _;
    }

    modifier onlyGlyphOwnerOrApproved(uint256 _tokenId) {
        if (_exists(_tokenId) && (ownerOf(_tokenId) == msg.sender || getApproved(_tokenId) == msg.sender || isApprovedForAll(ownerOf(_tokenId), msg.sender))) {
            _;
        } else {
             revert EpochGlyph__GlyphNotOwnedOrApproved(_tokenId);
        }
    }

    // --- Core ERC721 Overrides (Minimal for custom logic) ---

    // We don't need to override _transfer, _approve etc. as OpenZeppelin handles that.
    // Custom minting logic is in `mintGlyphWithFeeds`.
    // Custom burning logic is in `burnGlyph`.

    // --- Oracle Management (5 functions) ---

    /**
     * @dev Registers an oracle contract address. Only owner can register.
     * @param _oracleAddress Address of the oracle contract.
     * @param _name Name of the oracle for identification.
     */
    function registerOracle(address _oracleAddress, string memory _name) external onlyOwner {
        registeredOracles[_oracleAddress] = _name;
        emit OracleRegistered(_oracleAddress, _name);
    }

    /**
     * @dev Unregisters an oracle contract address. Only owner can unregister.
     * @param _oracleAddress Address of the oracle contract to unregister.
     */
    function unregisterOracle(address _oracleAddress) external onlyOwner {
        require(bytes(registeredOracles[_oracleAddress]).length > 0, "Oracle not registered"); // Use require for simple admin checks
        delete registeredOracles[_oracleAddress];
        // NOTE: Removing an oracle doesn't automatically invalidate existing feed mappings or glyph data.
        // This might need governance or manual cleanup depending on desired behavior.
        emit OracleUnregistered(_oracleAddress);
    }

    /**
     * @dev Sets or updates a global mapping for a data feed.
     * This links an internal `feedId` to an external oracle and its specific feed identifier.
     * Can be called by owner or via governance.
     * @param _feedId Internal ID for the feed. 0 to get a new ID.
     * @param _oracleAddress Address of the registered oracle.
     * @param _oracleSpecificId Identifier used by the specific oracle for this data feed.
     * @param _description Description of the data feed (e.g., "ETH/USD Price").
     * @param _defaultWeight Default weight for this feed when added to a Glyph.
     * @return The global feed ID that was set.
     */
    function setGlobalFeedMapping(
        uint256 _feedId,
        address _oracleAddress,
        bytes32 _oracleSpecificId,
        string memory _description,
        uint256 _defaultWeight
    ) public onlyOwnerOrGovernance { // Assume onlyOwnerOrGovernance is implemented elsewhere or handled via msg.sender checks
        // If _feedId is 0, assign a new ID
        uint256 currentFeedId = _feedId == 0 ? nextGlobalFeedId++ : _feedId;

        // Check if oracle is registered
        require(bytes(registeredOracles[_oracleAddress]).length > 0, "EpochGlyph__OracleNotRegistered");

        // Prevent adding a duplicate oracle-specific ID for the same oracle
        if (_oracleSpecificIdToGlobalFeedId[_oracleAddress][_oracleSpecificId] != 0 && _oracleSpecificIdToGlobalFeedId[_oracleAddress][_oracleSpecificId] != currentFeedId) {
             revert EpochGlyph__OracleSpecificIdAlreadyUsedForFeed(_oracleAddress, _oracleSpecificId);
        }

        globalFeedMappings[currentFeedId] = GlobalFeedMapping({
            oracleAddress: _oracleAddress,
            oracleSpecificId: _oracleSpecificId,
            description: _description,
            defaultWeight: _defaultWeight,
            exists: true
        });
        _oracleSpecificIdToGlobalFeedId[_oracleAddress][_oracleSpecificId] = currentFeedId;

        emit GlobalFeedMappingSet(currentFeedId, _oracleAddress, _oracleSpecificId, _description);
        // If using a new feedId, increment the counter *after* setting the mapping
        if (_feedId == 0) {
             // nextGlobalFeedId is already incremented
        }
    }

    /**
     * @dev Removes a global mapping for a data feed. Can be called by owner or via governance.
     * Note: This doesn't remove the feed from existing Glyphs.
     * @param _feedId Internal ID of the feed to remove.
     */
    function removeGlobalFeedMapping(uint256 _feedId) external onlyOwnerOrGovernance {
        GlobalFeedMapping storage mappingData = globalFeedMappings[_feedId];
        if (!mappingData.exists) {
            revert EpochGlyph__FeedMappingDoesNotExist(_feedId);
        }

        // Remove reverse mapping
        delete _oracleSpecificIdToGlobalFeedId[mappingData.oracleAddress][mappingData.oracleSpecificId];
        // Remove the mapping struct
        delete globalFeedMappings[_feedId];

        emit GlobalFeedMappingRemoved(_feedId);
    }

    // --- Glyph Lifecycle (4 functions + ERC721 base) ---

    /**
     * @dev Mints a new EpochGlyph token and assigns initial data feeds.
     * @param _to The address to mint the token to.
     * @param _initialFeedIds Array of global feed IDs to initially associate with the Glyph.
     */
    function mintGlyphWithFeeds(address _to, uint256[] memory _initialFeedIds) external whenNotPaused nonReentrant {
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);

        Glyph storage glyph = glyphs[tokenId];
        glyph.score = 0; // Initial score
        glyph.lastScoreCalculationTimestamp = block.timestamp;

        for (uint i = 0; i < _initialFeedIds.length; i++) {
            uint256 feedId = _initialFeedIds[i];
            GlobalFeedMapping storage globalMapping = globalFeedMappings[feedId];
            if (!globalMapping.exists) {
                 // Skip invalid feeds or potentially revert
                 // For this example, we'll skip invalid feeds to allow partial success
                 continue;
            }
             // Check if feed is already added (shouldn't happen on mint, but good practice)
            bool alreadyAdded = false;
            for(uint j=0; j < glyph.feedIds.length; j++) {
                if (glyph.feedIds[j] == feedId) {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded) {
                 glyph.feedIds.push(feedId);
                 glyph.feedWeights[feedId] = globalMapping.defaultWeight;
                 // Optionally request initial data here, or rely on user to trigger `requestFeedUpdateForGlyph`
            }
        }

        // Set default metadata URI initially
        _setTokenURI(tokenId, _baseURI());

        emit GlyphMinted(tokenId, _to, _initialFeedIds);
    }

    /**
     * @dev Burns an EpochGlyph token.
     * Includes logic to handle staked tokens.
     * @param _tokenId The token ID to burn.
     */
    function burnGlyph(uint256 _tokenId) external whenNotPaused {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "Not owner or approved");

        // Check if staked
        if (_stakedGlyphs[_tokenId].isStaked) {
            // Implement logic: unstake first, or burn and forfeit staking data
            // For simplicity, require unstaking first.
            revert EpochGlyph__GlyphAlreadyStaked(_tokenId);
        }

        // Clean up glyph-specific data before burning
        // No need to explicitly delete mappings for `feedData` and `feedWeights`
        // as they are tied to the glyph struct which will be removed.
        // Explicitly clear the dynamic array `feedIds`
        delete glyphs[_tokenId].feedIds;
        delete glyphs[_tokenId]; // Cleans up the struct and nested mappings

        _burn(_tokenId); // Burns the NFT token

        emit GlyphBurned(_tokenId);
    }

    /**
     * @dev Adds a specified global feed to an existing Glyph.
     * Requires token ownership or approval.
     * @param _tokenId The token ID.
     * @param _feedId The global feed ID to add.
     * @param _initialWeight The weight to assign to this feed for the Glyph's score calculation.
     */
    function addFeedToGlyph(uint256 _tokenId, uint256 _feedId, uint256 _initialWeight) external whenNotPaused onlyGlyphOwnerOrApproved(_tokenId) {
        GlobalFeedMapping storage globalMapping = globalFeedMappings[_feedId];
        if (!globalMapping.exists) {
            revert EpochGlyph__FeedMappingDoesNotExist(_feedId);
        }

        Glyph storage glyph = glyphs[_tokenId];

        // Check if feed is already added
        for(uint i=0; i < glyph.feedIds.length; i++) {
            if (glyph.feedIds[i] == _feedId) {
                revert EpochGlyph__FeedAlreadyExistsOnGlyph(_tokenId, _feedId);
            }
        }

        glyph.feedIds.push(_feedId);
        glyph.feedWeights[_feedId] = _initialWeight;

        // Optional: Request initial data update immediately
        // requestFeedUpdateForGlyph(_tokenId, _feedId); // This would need to be called from client or internal logic if we pass ownership checks

        emit FeedAddedToGlyph(_tokenId, _feedId, _initialWeight);
    }

    /**
     * @dev Removes a feed from a Glyph's tracking list.
     * Requires token ownership or approval.
     * @param _tokenId The token ID.
     * @param _feedId The global feed ID to remove.
     */
    function removeFeedFromGlyph(uint256 _tokenId, uint256 _feedId) external whenNotPaused onlyGlyphOwnerOrApproved(_tokenId) {
        Glyph storage glyph = glyphs[_tokenId];
        bool found = false;
        uint256 indexToRemove = type(uint256).max;

        for (uint i = 0; i < glyph.feedIds.length; i++) {
            if (glyph.feedIds[i] == _feedId) {
                indexToRemove = i;
                found = true;
                break;
            }
        }

        if (!found) {
            revert EpochGlyph__FeedNotOnGlyph(_tokenId, _feedId);
        }

        // Remove from dynamic array (swap with last element and pop)
        if (indexToRemove != glyph.feedIds.length - 1) {
            glyph.feedIds[indexToRemove] = glyph.feedIds[glyph.feedIds.length - 1];
        }
        glyph.feedIds.pop();

        // Delete associated data for this feed on this glyph
        delete glyph.feedWeights[_feedId];
        delete glyph.feedData[_feedId];

        // Recalculate score as feed was removed
        _recalculateGlyphScore(_tokenId); // Internal call

        emit FeedRemovedFromGlyph(_tokenId, _feedId);
    }

    /**
     * @dev Allows updating the metadata URI for a specific token.
     * Can be restricted (e.g., owner only, governance, or based on score/state).
     * For this example, let's make it owner only initially, can be extended via governance.
     * @param _tokenId The token ID.
     * @param _newURI The new metadata URI.
     */
    function updateGlyphMetadataURI(uint256 _tokenId, string memory _newURI) public whenNotPaused onlyGlyphOwnerOrApproved(_tokenId) {
         _setTokenURI(_tokenId, _newURI);
         emit GlyphMetadataUpdated(_tokenId, _newURI);
    }


    // --- Data & Update Mechanisms (4 functions) ---

    /**
     * @dev Triggers an oracle data request for a specific feed associated with a Glyph.
     * Can be called by the Glyph owner/approved address, or potentially automatically.
     * @param _tokenId The token ID.
     * @param _feedId The global feed ID to request data for.
     */
    function requestFeedUpdateForGlyph(uint256 _tokenId, uint256 _feedId) external whenNotPaused nonReentrant onlyGlyphOwnerOrApproved(_tokenId) {
        GlobalFeedMapping storage globalMapping = globalFeedMappings[_feedId];
         if (!globalMapping.exists) {
            revert EpochGlyph__FeedMappingDoesNotExist(_feedId);
        }

        Glyph storage glyph = glyphs[_tokenId];
        bool feedFoundOnGlyph = false;
         for(uint i=0; i < glyph.feedIds.length; i++) {
            if (glyph.feedIds[i] == _feedId) {
                feedFoundOnGlyph = true;
                break;
            }
        }
        if (!feedFoundOnGlyph) {
            revert EpochGlyph__FeedNotOnGlyph(_tokenId, _feedId);
        }

        address oracleAddress = globalMapping.oracleAddress;
        bytes32 oracleSpecificId = globalMapping.oracleSpecificId;
        uint256 requestId = _nextRequestId++;

        // Store request context to process callback
        _requestInitiator[requestId] = msg.sender; // Store who initiated (for potential rewards/fees later)
        _requestTokenId[requestId] = _tokenId;
        _requestFeedId[requestId] = _feedId;

        // Call the oracle contract to request data
        // Note: Actual oracle interaction might be more complex (e.g., Chainlink fulfill)
        // Ensure the oracle contract implements `IEpochGlyphOracle` or compatible logic.
        IEpochGlyphOracle oracle = IEpochGlyphOracle(oracleAddress);
        oracle.requestData(oracleSpecificId, requestId, address(this));

        emit FeedUpdateRequestSent(_tokenId, _feedId, requestId);
    }

    /**
     * @dev Callback function for registered oracles to deliver data.
     * Only callable by registered oracles.
     * @param _oracleAddress The address of the oracle calling back.
     * @param _requestId The request ID associated with the original request.
     * @param _value The data value provided by the oracle.
     * @param _timestamp The timestamp the data is valid for (as provided by oracle).
     */
    function callbackOracleData(
        address _oracleAddress,
        uint256 _requestId,
        int256 _value,
        uint256 _timestamp
    ) external onlyRegisteredOracle {
        // Verify the callback corresponds to a pending request
        uint256 tokenId = _requestTokenId[_requestId];
        uint256 feedId = _requestFeedId[_requestId];

        if (tokenId == 0 || feedId == 0) { // Assuming 0 is an invalid token/feed ID in this context
             revert EpochGlyph__InvalidCallbackData(_requestId);
        }

        // Clear the request data to prevent replay/double processing
        delete _requestInitiator[_requestId];
        delete _requestTokenId[_requestId];
        delete _requestFeedId[_requestId];

        // Update the feed data for the specific glyph
        Glyph storage glyph = glyphs[tokenId];
        glyph.feedData[feedId] = FeedData({
            latestValue: _value,
            lastUpdatedTimestamp: _timestamp
        });

        // Recalculate the glyph's score after receiving new data
        _recalculateGlyphScore(tokenId); // Internal call

        emit OracleDataCallbackReceived(_requestId, _value, _timestamp);
    }

    /**
     * @dev Internal function to recalculate a Glyph's score based on its current feed data and weights.
     * This logic can be complex. For simplicity, let's use a weighted sum.
     * @param _tokenId The token ID.
     */
    function _recalculateGlyphScore(uint256 _tokenId) internal {
        Glyph storage glyph = glyphs[_tokenId];
        int256 totalWeightedValue = 0;
        uint256 totalWeight = 0;

        // Iterate through feeds associated with this glyph
        for (uint i = 0; i < glyph.feedIds.length; i++) {
            uint256 feedId = glyph.feedIds[i];
            uint256 weight = glyph.feedWeights[feedId];
            FeedData storage data = glyph.feedData[feedId];

            // Only use data if it's relatively recent and exists
            // Add checks for data.lastUpdatedTimestamp if needed
            if (data.lastUpdatedTimestamp > 0) {
                 totalWeightedValue += data.latestValue * int256(weight);
                 totalWeight += weight;
            }
        }

        if (totalWeight > 0) {
            glyph.score = totalWeightedValue / int256(totalWeight);
        } else {
            glyph.score = 0; // Default score if no valid weighted feeds
        }

        glyph.lastScoreCalculationTimestamp = block.timestamp;

        emit GlyphScoreRecalculated(_tokenId, glyph.score, glyph.lastScoreCalculationTimestamp);
    }

    /**
     * @dev Allows the token owner/approved address to adjust the weight of a specific feed
     * for their specific Glyph. This affects how that feed contributes to the Glyph's score.
     * @param _tokenId The token ID.
     * @param _feedId The global feed ID.
     * @param _newWeight The new weight to set.
     */
    function setGlyphFeedWeight(uint256 _tokenId, uint256 _feedId, uint256 _newWeight) external whenNotPaused onlyGlyphOwnerOrApproved(_tokenId) {
        Glyph storage glyph = glyphs[_tokenId];

        // Check if feed is on the glyph
        bool feedFound = false;
        for(uint i=0; i < glyph.feedIds.length; i++) {
            if (glyph.feedIds[i] == _feedId) {
                feedFound = true;
                break;
            }
        }
        if (!feedFound) {
            revert EpochGlyph__FeedNotOnGlyph(_tokenId, _feedId);
        }

        glyph.feedWeights[_feedId] = _newWeight;

        // Recalculate score as weight changed
        _recalculateGlyphScore(_tokenId); // Internal call

        emit GlyphFeedWeightUpdated(_tokenId, _feedId, _newWeight);
    }

    // --- Governance Mechanism (5 functions) ---
    // Note: Requires a separate contract or careful implementation for complex execution (`calldata`)
    // This example includes a placeholder modifier `onlyOwnerOrGovernance`
    // which in a real DAO would check if the call is originating from a successfully executed proposal.

    // Placeholder modifier for functions callable by owner or successful governance proposal
    modifier onlyOwnerOrGovernance() {
        // In a real DAO, this would check if msg.sender is the owner OR
        // if the current call is being made as part of a successful proposal execution.
        // For this example, we'll just allow owner calls.
        // A real implementation would use delegatecall inside executeProposal.
        require(msg.sender == owner(), "Not owner or governance");
        _;
    }

    /**
     * @dev Creates a governance proposal to change a contract configuration parameter.
     * Requires the proposer to hold a minimum number of Glyphs (`proposalCreationTokenStake`).
     * @param _description A description of the proposal.
     * @param _calldata The encoded function call and parameters to execute if the proposal passes.
     */
    function proposeConfigChange(string memory _description, bytes memory _calldata) external whenNotPaused nonReentrant {
        if (balanceOf(msg.sender) < proposalCreationTokenStake) {
             revert EpochGlyph__ProposalRequiresGlyphs();
        }
        // Basic check if calldata is reasonable - could add more specific checks
        if (_calldata.length < 4) { // Minimum 4 bytes for function signature
             revert EpochGlyph__InvalidProposalCalldata();
        }


        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            startBlock: block.number,
            endBlock: block.number + governanceVotingPeriodBlocks,
            description: _description,
            calldata: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            state: ProposalState.Active,
            quorumRequired: (totalSupply() * governanceQuorumPercent) / 100, // Quorum based on total supply at proposal creation
            voteThreshold: governanceVoteThresholdPercent
        });

        emit ProposalCreated(proposalId, msg.sender, block.number, block.number + governanceVotingPeriodBlocks, _description);
    }

     /**
     * @dev Creates a governance proposal specifically to add a new global feed mapping.
     * This is a convenience function wrapping `proposeConfigChange`.
     * Requires the proposer to hold a minimum number of Glyphs.
     * @param _feedId Internal ID for the feed. 0 to get a new ID.
     * @param _oracleAddress Address of the registered oracle.
     * @param _oracleSpecificId Identifier used by the specific oracle.
     * @param _description Description of the data feed.
     * @param _initialWeight Default weight for the feed.
     */
    function proposeNewGlobalFeedMapping(
        uint256 _feedId,
        address _oracleAddress,
        bytes32 _oracleSpecificId,
        string memory _description,
        uint256 _initialWeight
    ) external whenNotPaused nonReentrant {
         // Encode the call to setGlobalFeedMapping
        bytes memory calldataPayload = abi.encodeWithSelector(
            this.setGlobalFeedMapping.selector,
            _feedId,
            _oracleAddress,
            _oracleSpecificId,
            _description,
            _initialWeight
        );

        string memory proposalDescription = string(abi.encodePacked("Propose new global feed: ", _description, " (ID: ", uint256ToString(_feedId == 0 ? nextGlobalFeedId : _feedId), ")"));

        proposeConfigChange(proposalDescription, calldataPayload);
    }


    /**
     * @dev Allows a Glyph holder to cast a vote on an active proposal.
     * Voting weight is based on the number of Glyphs held by the voter.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'Yes' vote, False for a 'No' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Active) {
            revert EpochGlyph__CannotVoteOnInactiveProposal(_proposalId);
        }
        if (block.number > proposal.endBlock) {
             // Update state if voting period has ended
             _updateProposalState(_proposalId);
             // Re-check state
             if (proposal.state != ProposalState.Active) {
                revert EpochGlyph__CannotVoteOnInactiveProposal(_proposalId);
            }
        }
        if (proposal.hasVoted[msg.sender]) {
            revert EpochGlyph__AlreadyVoted(_proposalId, msg.sender);
        }

        // Voting power is 1 Glyph = 1 Vote
        uint256 votes = balanceOf(msg.sender);
        if (votes == 0) {
             revert EpochGlyph__ProposalRequiresGlyphs(); // Cannot vote if no Glyphs held
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += votes;
        } else {
            proposal.votesAgainst += votes;
        }

        emit VoteCast(_proposalId, msg.sender, votes, _support);
    }

    /**
     * @dev Internal helper to update proposal state based on current block and vote counts.
     * @param _proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 _proposalId) internal {
         Proposal storage proposal = proposals[_proposalId];

        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 totalTokenSupplyAtVoteEnd = totalSupply(); // Approximation, ideally snapshot supply at start

            if (totalVotes < proposal.quorumRequired) {
                proposal.state = ProposalState.Defeated;
            } else {
                // Calculate threshold percentage (using 10000 for precision)
                // votesFor / totalVotes >= voteThreshold / 100
                // votesFor * 100 >= totalVotes * voteThreshold
                if (proposal.votesFor * 100 >= totalVotes * proposal.voteThreshold) {
                    proposal.state = ProposalState.Succeeded;
                } else {
                    proposal.state = ProposalState.Defeated;
                }
            }
            // If voting period is over, but state is still active (e.g., called directly before vote), mark expired
        } else if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
             proposal.state = ProposalState.Expired;
        }
        // Other state transitions handled by execute/cancel
    }


    /**
     * @dev Executes a proposal that has passed its voting period and met the requirements.
     * Anyone can call execute, but only successful proposals can be executed.
     * Uses `delegatecall` or similar mechanism to execute `calldata`.
     * Note: Implementing safe execution via `calldata` requires careful handling,
     * potentially a separate executor contract or strict checks on target/signature.
     * For this example, we will simulate execution by marking as executed.
     * A real implementation would use `(bool success, bytes memory returndata) = address(this).delegatecall(proposal.calldata);`
     * and check `success`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        _updateProposalState(_proposalId); // Ensure state is up-to-date

        if (proposal.state != ProposalState.Succeeded) {
            string memory reason;
            if (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active) reason = "Voting not ended or not succeeded yet";
            else if (proposal.state == ProposalState.Canceled) reason = "Proposal canceled";
            else if (proposal.state == ProposalState.Defeated) reason = "Proposal defeated";
            else if (proposal.state == ProposalState.Executed) reason = "Proposal already executed";
             else reason = "Proposal state prevents execution";
             revert EpochGlyph__CannotExecuteProposal(_proposalId, reason);
        }

        // --- REAL EXECUTION WOULD HAPPEN HERE ---
        // (bool success, bytes memory returndata) = address(this).delegatecall(proposal.calldata);
        // require(success, string(abi.encodePacked("Execution failed: ", returndata)));
        // For this example, we just mark it executed.

        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the proposer or governance to cancel a proposal under specific conditions.
     * E.g., before voting starts, or by a specific governance majority.
     * For simplicity, only the proposer can cancel if voting hasn't started.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
         Proposal storage proposal = proposals[_proposalId];

         if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.Active) {
              revert EpochGlyph__CannotCancelProposal(_proposalId, "Proposal not in Pending or Active state");
         }

         // Allow proposer to cancel before voting starts
         if (msg.sender != proposal.proposer) {
             // Add governance check here if governance can also cancel
             // require(isGovernanceExecutor(msg.sender), "Not proposer or governance executor");
             revert EpochGlyph__CannotCancelProposal(_proposalId, "Only proposer can cancel");
         }

         if (block.number > proposal.startBlock) {
              revert EpochGlyph__CannotCancelProposal(_proposalId, "Voting has already started");
         }

         proposal.state = ProposalState.Canceled;

         emit ProposalCanceled(_proposalId);
    }


    // --- Glyph Interaction Mechanics (3 functions) ---
    // Simplified staking without complex rewards calculation logic

    /**
     * @dev Stakes a Glyph token. The token is transferred to the contract's control.
     * Requires the sender to own the token or be approved.
     * @param _tokenId The token ID to stake.
     */
    function stakeGlyph(uint256 _tokenId) external whenNotPaused nonReentrant {
        address owner = ownerOf(_tokenId);
        if (msg.sender != owner && getApproved(_tokenId) != msg.sender && !isApprovedForAll(owner, msg.sender)) {
             revert EpochGlyph__GlyphNotOwnedOrApproved(_tokenId);
        }

        if (_stakedGlyphs[_tokenId].isStaked) {
            revert EpochGlyph__GlyphAlreadyStaked(_tokenId);
        }

        // Transfer token to the contract itself
        _transfer(owner, address(this), _tokenId);

        // Update staking state
        _stakedGlyphs[_tokenId] = StakingInfo({
            isStaked: true,
            stakedTimestamp: block.timestamp
            // accumulatedRewards: 0 // Initialize if using this field
        });

        // Add to owner's list of staked tokens (basic)
        _stakedGlyphsByOwner[owner].push(_tokenId);

        emit GlyphStaked(_tokenId, owner);
    }

    /**
     * @dev Unstakes a Glyph token, returning it to the original staker.
     * @param _tokenId The token ID to unstake.
     */
    function unstakeGlyph(uint256 _tokenId) external whenNotPaused nonReentrant {
        StakingInfo storage stakingInfo = _stakedGlyphs[_tokenId];
        if (!stakingInfo.isStaked) {
             revert EpochGlyph__GlyphNotStaked(_tokenId);
        }
        address staker = ownerOf(_tokenId); // ownerOf will be this contract, need to track original staker
        // We need to track the original staker. Let's update the StakingInfo struct.
        // Alternative: Require msg.sender to be the *current* owner (this contract) AND prove they were the staker.
        // Let's modify StakingInfo to store the staker address.
        // struct StakingInfo { bool isStaked; uint256 stakedTimestamp; address stakerAddress; }
        // and update the stake function. Assuming this change...

        // If StakingInfo struct is updated with stakerAddress:
        // require(msg.sender == stakingInfo.stakerAddress, "Not the staker");

        // If not tracking stakerAddress in struct, require msg.sender to be the owner
        // of the token *before* it was staked (which is hard to prove on-chain).
        // Simplest for this example: allow the address that *currently owns* (this contract)
        // to be instructed by the original staker (msg.sender) to unstake.
        // This requires the user to call from the same address that staked.
        address presumedStaker = msg.sender;

        // Find _tokenId in _stakedGlyphsByOwner[presumedStaker] and remove it
        uint256 indexToRemove = type(uint256).max;
        uint256[] storage stakedTokens = _stakedGlyphsByOwner[presumedStaker];
        for(uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == _tokenId) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != type(uint256).max, "Glyph not staked by this address"); // Ensure it was staked by msg.sender

        // Remove from list
        if (indexToRemove != stakedTokens.length - 1) {
             stakedTokens[indexToRemove] = stakedTokens[stakedTokens.length - 1];
        }
        stakedTokens.pop();


        // Update staking state
        delete _stakedGlyphs[_tokenId]; // Cleans up the struct

        // Transfer token back to the staker
        _transfer(address(this), presumedStaker, _tokenId);

        emit GlyphUnstaked(_tokenId, presumedStaker);
    }

    /**
     * @dev Allows a user to claim accumulated rewards from their staked Glyphs.
     * Reward logic is a placeholder here.
     */
    function claimStakingRewards() external whenNotPaused nonReentrance {
        // Placeholder for reward calculation and distribution.
        // Needs a reward pool, emission logic, and calculation based on time staked,
        // possibly Glyph score, number of staked tokens, etc.
        // Example: uint256 rewards = calculateClaimableRewards(msg.sender);
        // if (rewards == 0) revert EpochGlyph__StakingRewardsNotAvailable();
        // Transfer rewards (e.g., ERC20 tokens) to msg.sender.
        // Update reward state (e.g., reset accumulatedRewards for staked tokens).

        // For this example, just emit an event indicating a claim attempt.
         revert EpochGlyph__StakingRewardsNotAvailable(); // No rewards implemented yet

        // emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Combines two Glyphs into a new one.
     * This function showcases a creative mechanic. The logic of combination
     * can be complex (e.g., average scores, combine feeds, create new traits).
     * Simplified logic: burns the two input Glyphs and mints a new one
     * that tracks all unique feeds from the inputs. Recalculates the score.
     * Requires the caller to own or be approved for both input Glyphs.
     * @param _tokenId1 The ID of the first Glyph.
     * @param _tokenId2 The ID of the second Glyph.
     */
    function combineGlyphs(uint256 _tokenId1, uint256 _tokenId2) external whenNotPaused nonReentrant {
        if (_tokenId1 == _tokenId2) {
             revert EpochGlyph__CannotCombineSameGlyph(_tokenId1);
        }

        // Check ownership/approval for both tokens
        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);
        if (owner1 != owner2 || msg.sender != owner1 && getApproved(_tokenId1) != msg.sender && !isApprovedForAll(owner1, msg.sender)) {
             revert EpochGlyph__CombinationRequiresOwnedGlyphs();
        }
         if (msg.sender != owner2 && getApproved(_tokenId2) != msg.sender && !isApprovedForAll(owner2, msg.sender)) {
             revert EpochGlyph__CombinationRequiresOwnedGlyphs();
        }
         address finalOwner = owner1; // Should be the same address

        // Burn the input Glyphs
        _burn(_tokenId1);
        _burn(_tokenId2);
        emit GlyphBurned(_tokenId1);
        emit GlyphBurned(_tokenId2);


        // Collect unique feeds from both Glyphs
        Glyph storage glyph1 = glyphs[_tokenId1]; // Data might still be accessible briefly
        Glyph storage glyph2 = glyphs[_tokenId2];
        uint256[] memory combinedFeedIds = new uint256[](glyph1.feedIds.length + glyph2.feedIds.length);
        uint256 uniqueCount = 0;
        mapping(uint256 => bool) tempFeedCheck;

        // Add feeds from Glyph 1
        for(uint i = 0; i < glyph1.feedIds.length; i++) {
            uint256 feedId = glyph1.feedIds[i];
            if (!tempFeedCheck[feedId]) {
                combinedFeedIds[uniqueCount++] = feedId;
                tempFeedCheck[feedId] = true;
            }
        }
         // Add feeds from Glyph 2
        for(uint i = 0; i < glyph2.feedIds.length; i++) {
            uint256 feedId = glyph2.feedIds[i];
            if (!tempFeedCheck[feedId]) {
                combinedFeedIds[uniqueCount++] = feedId;
                tempFeedCheck[feedId] = true;
            }
        }
        // Resize array to unique count
        uint224(combinedFeedIds.length) = uniqueCount;


        // Mint a new Glyph with combined feeds
        uint256 newGlyphId = _nextTokenId++;
        _safeMint(finalOwner, newGlyphId);

        Glyph storage newGlyph = glyphs[newGlyphId];
        newGlyph.score = 0; // Initial score before recalculation
        newGlyph.lastScoreCalculationTimestamp = block.timestamp;

        // Add combined feeds and use default weights or average weights from inputs
        for (uint i = 0; i < combinedFeedIds.length; i++) {
            uint256 feedId = combinedFeedIds[i];
             GlobalFeedMapping storage globalMapping = globalFeedMappings[feedId];
             if (!globalMapping.exists) continue; // Should not happen if original feeds were valid

            newGlyph.feedIds.push(feedId);
            // Simple: use default weight from global mapping
            newGlyph.feedWeights[feedId] = globalMapping.defaultWeight;

             // More complex: try to average weights if feed was on both original glyphs
             // uint256 weight1 = glyph1.feedWeights[feedId]; // This will be 0 if not on glyph1
             // uint256 weight2 = glyph2.feedWeights[feedId]; // This will be 0 if not on glyph2
             // newGlyph.feedWeights[feedId] = (weight1 + weight2) / ( (weight1 > 0 ? 1 : 0) + (weight2 > 0 ? 1 : 0) ); // Handle division by zero

            // Copy latest data if available from either burned glyph
            if (glyph1.feedData[feedId].lastUpdatedTimestamp > glyph2.feedData[feedId].lastUpdatedTimestamp) {
                 newGlyph.feedData[feedId] = glyph1.feedData[feedId];
            } else {
                 newGlyph.feedData[feedId] = glyph2.feedData[feedId];
            }
        }

         // Recalculate score for the new Glyph
        _recalculateGlyphScore(newGlyphId);

        // Set default metadata URI
        _setTokenURI(newGlyphId, _baseURI());

        emit GlyphsCombined(new uint256[](2){_tokenId1, _tokenId2}, newGlyphId, finalOwner);
        emit GlyphMinted(newGlyphId, finalOwner, combinedFeedIds); // Also emit mint event
    }


    // --- Query/View Functions (6 functions + ERC721 base) ---

    /**
     * @dev Returns detailed data about a specific Glyph.
     * @param _tokenId The token ID.
     * @return feedIds The global feed IDs associated with this glyph.
     * @return feedWeights The weights for each associated feed.
     * @return feedValues The latest data values for each associated feed.
     * @return feedUpdateTimestamps The timestamps of the latest data updates for each feed.
     * @return score The current calculated score of the glyph.
     * @return lastScoreCalculationTimestamp The timestamp of the last score calculation.
     */
    function getGlyphData(uint256 _tokenId) public view returns (
        uint256[] memory feedIds,
        uint256[] memory feedWeights,
        int256[] memory feedValues,
        uint256[] memory feedUpdateTimestamps,
        int256 score,
        uint256 lastScoreCalculationTimestamp
    ) {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        Glyph storage glyph = glyphs[_tokenId];

        feedIds = new uint256[](glyph.feedIds.length);
        feedWeights = new uint256[](glyph.feedIds.length);
        feedValues = new int256[](glyph.feedIds.length);
        feedUpdateTimestamps = new uint256[](glyph.feedIds.length);

        for(uint i = 0; i < glyph.feedIds.length; i++) {
            uint256 feedId = glyph.feedIds[i];
            feedIds[i] = feedId;
            feedWeights[i] = glyph.feedWeights[feedId];
            feedValues[i] = glyph.feedData[feedId].latestValue;
            feedUpdateTimestamps[i] = glyph.feedData[feedId].lastUpdatedTimestamp;
        }

        score = glyph.score;
        lastScoreCalculationTimestamp = glyph.lastScoreCalculationTimestamp;
    }

    /**
     * @dev Returns details about a globally registered feed mapping.
     * @param _feedId The global feed ID.
     * @return oracleAddress Address of the oracle.
     * @return oracleSpecificId Identifier used by the oracle.
     * @return description Description of the feed.
     * @return defaultWeight Default weight for this feed.
     * @return exists True if the mapping exists.
     */
    function getGlobalFeedDetails(uint256 _feedId) public view returns (
        address oracleAddress,
        bytes32 oracleSpecificId,
        string memory description,
        uint256 defaultWeight,
        bool exists
    ) {
        GlobalFeedMapping storage mappingData = globalFeedMappings[_feedId];
        return (
            mappingData.oracleAddress,
            mappingData.oracleSpecificId,
            mappingData.description,
            mappingData.defaultWeight,
            mappingData.exists
        );
    }

     /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return id Proposal ID.
     * @return proposer Address that created the proposal.
     * @return startBlock Block when voting started.
     * @return endBlock Block when voting ends.
     * @return description Description of the proposal.
     * @return votesFor Number of votes for the proposal.
     * @return votesAgainst Number of votes against the proposal.
     * @return state Current state of the proposal.
     * @return quorumRequired Minimum votes required for quorum.
     * @return voteThreshold Percentage threshold for passing.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        uint256 quorumRequired,
        uint256 voteThreshold
    ) {
        Proposal storage proposal = proposals[_proposalId];
        // Note: Proposal state might be outdated if _updateProposalState hasn't been called recently.
        // A helper view function could calculate the *current* state.
        return (
            proposal.id,
            proposal.proposer,
            proposal.startBlock,
            proposal.endBlock,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state, // Potential to be outdated
            proposal.quorumRequired,
            proposal.voteThreshold
        );
    }

    /**
     * @dev Returns info about Glyphs staked by a specific address.
     * Note: This is a basic implementation. Tracking stakes by address
     * using a dynamic array can be expensive to iterate fully.
     * @param _owner The address to check.
     * @return tokenIds Array of token IDs staked by this address.
     */
    function getStakingInfo(address _owner) public view returns (uint256[] memory tokenIds) {
        return _stakedGlyphsByOwner[_owner];
    }

     /**
     * @dev View function to calculate and return the current score of a Glyph
     * based on stored data and weights, without modifying state.
     * Useful for UIs to preview score changes.
     * @param _tokenId The token ID.
     * @return The calculated score.
     */
    function calculateCurrentGlyphScore(uint256 _tokenId) public view returns (int256) {
         require(_exists(_tokenId), "ERC721: invalid token ID");
        Glyph storage glyph = glyphs[_tokenId];

        int256 totalWeightedValue = 0;
        uint256 totalWeight = 0;

        for (uint i = 0; i < glyph.feedIds.length; i++) {
            uint256 feedId = glyph.feedIds[i];
            uint256 weight = glyph.feedWeights[feedId];
            FeedData storage data = glyph.feedData[feedId];

            if (data.lastUpdatedTimestamp > 0) {
                 totalWeightedValue += data.latestValue * int256(weight);
                 totalWeight += weight;
            }
        }

        if (totalWeight > 0) {
            return totalWeightedValue / int256(totalWeight);
        } else {
            return 0;
        }
    }

    /**
     * @dev Helper view to get the current state of a proposal, taking into account the current block.
     * @param _proposalId The ID of the proposal.
     * @return The current ProposalState.
     */
    function getCurrentProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 totalTokenSupplyAtVoteEnd = totalSupply(); // Approximation

            if (totalVotes < proposal.quorumRequired) {
                return ProposalState.Defeated;
            } else {
                 if (proposal.votesFor * 100 >= totalVotes * proposal.voteThreshold) {
                     return ProposalState.Succeeded;
                 } else {
                     return ProposalState.Defeated;
                 }
            }
        }
        return proposal.state;
    }


    // --- Administrative Functions (3 functions) ---

    /**
     * @dev Pauses the contract. Emergency measure.
     */
    function pause() external onlyOwner whenNotNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the base URI for token metadata.
     */
    function _setBaseURI(string memory baseURI) internal override onlyOwnerOrGovernance {
        super._setBaseURI(baseURI);
    }

    // Override _burn to handle internal state cleanup
    function _burn(uint256 tokenId) internal override {
         // Clear token URI storage before burning
         _deleteTokenURI(tokenId);
         super._burn(tokenId);
    }


    // --- Internal Helpers ---
     // Helper to convert uint256 to string (basic implementation)
    function uint256ToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}
```