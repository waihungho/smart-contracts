The `AetherWeaver` smart contract introduces a decentralized creative platform centered around "Morphic Canvases" – dynamic NFTs that evolve through community contributions and AI-driven insights. It combines several advanced concepts:

1.  **AI-Driven Dynamic NFTs:** Canvases evolve based on inputs from users ("inspirations") and interpretations provided by an off-chain AI oracle. The NFT metadata (specifically, its visual parameters and theme) changes over time.
2.  **Reputation & Influence System:** Users earn an "Aether Weave Score" for their impactful contributions. They can also stake ETH to amplify the weight of their inspirations and influence the canvas's synthesis outcome.
3.  **Decentralized Creative Synthesis:** A "synthesis" event processes all accumulated contributions and AI interpretations, causing the canvas to evolve, update its theme, and refine its visual representation.
4.  **Community Governance & Curation:** Users can propose new themes for canvases, and the community can vote on these proposals, guiding the creative direction.

This contract aims to create an emergent, collectively-generated digital art or narrative experience, where the final output is a dynamic reflection of user creativity and AI guidance.

---

## **AetherWeaver Smart Contract: Decentralized Creative Synthesizer**

### **Outline and Function Summary**

**I. Core Canvas Lifecycle & Properties**
1.  **`createMorphicCanvas(string memory _initialTheme, string memory _initialVisualParamsHash)`**: Mints a new dynamic NFT (Morphic Canvas) to the caller. Requires a fee. The canvas starts with an initial theme and a hash referencing its off-chain visual parameters (e.g., IPFS URI).
2.  **`getCanvasDetails(uint256 _canvasId)`**: Retrieves all structured on-chain data for a specific canvas, including its theme, current visual parameters hash, creator, and last synthesis block.
3.  **`updateVisualParamsHash(uint256 _canvasId, string memory _newMetadataHash)`**: Allows the canvas creator or an assigned steward to update the off-chain hash representing the canvas's current visual state. Typically called after a synthesis event.
4.  **`delegateStewardship(uint256 _canvasId, address _newSteward)`**: Allows the creator of a canvas to delegate limited management rights (e.g., updating metadata) to another address.
5.  **`removeStewardship(uint256 _canvasId, address _stewardToRemove)`**: Revokes stewardship rights from an address for a specific canvas.

**II. User Interaction & Contribution (Weaving)**
6.  **`weaveInspiration(uint256 _canvasId, bytes32 _inspirationDataHash, string memory _promptTag)`**: Users submit an off-chain data hash (e.g., of text, image parameters) and a descriptive tag as an "inspiration" to a specific canvas. This requires a fee and increases the canvas's contribution count.
7.  **`stakeForInfluence(uint256 _canvasId)`**: Users can lock ETH to amplify the weight of their future inspirations and influence in the canvas's evolution during synthesis. Staked ETH remains with the user, but its value is considered for influence.
8.  **`unstakeInfluence(uint256 _canvasId, uint256 _amount)`**: Allows users to retrieve a portion or all of their staked ETH for a given canvas.

**III. AI Oracle Integration & Canvas Evolution (Synthesis)**
9.  **`submitAIInterpretation(uint256 _canvasId, string memory _aiSuggestedVisualParamsHash, bytes32 _aiAnalysisHash)`**: This function can only be called by the designated AI Oracle address. It provides structured data (e.g., a new visual parameters hash) and an analysis hash based on the cumulative inspirations for a canvas, guiding its evolution.
10. **`triggerSynthesis(uint256 _canvasId)`**: Initiates the core evolution process for a canvas. It aggregates contributions, applies AI insights, updates the canvas's state (visual parameters, theme), and distributes rewards. This function checks a cooldown period.
11. **`proposeNewTheme(uint256 _canvasId, string memory _newTheme, bytes32 _proposalHash)`**: Allows users with sufficient Aether Weave Score to propose a new thematic direction for a specific canvas.
12. **`voteOnThemeProposal(uint256 _canvasId, bytes32 _proposalHash, bool _approve)`**: Community members can vote (approve/disapprove) on active theme proposals, influencing the canvas's future creative direction.

**IV. Reputation & Reward System**
13. **`getAetherWeaveScore(address _user)`**: Retrieves a user's on-chain "Aether Weave Score," a reputation metric reflecting their creative impact and engagement within the platform.
14. **`claimSynthesisRewards(uint256 _canvasId)`**: Allows eligible contributors (those who weaved inspirations) to claim their share of fees generated during a successful synthesis event for a specific canvas.
15. **`claimOracleFees()`**: Allows the designated AI Oracle to withdraw accumulated service fees for providing interpretations.

**V. Protocol Governance & Maintenance**
16. **`setAIOracleAddress(address _newOracleAddress)`**: An owner-only function to update the trusted AI Oracle address responsible for submitting interpretations.
17. **`setCanvasCreationFee(uint256 _newFee)`**: An owner-only function to adjust the fee required to mint a new Morphic Canvas.
18. **`setWeaveFee(uint256 _newFee)`**: An owner-only function to adjust the fee for submitting inspirations to a canvas.
19. **`setSynthesisCoolDown(uint256 _blocks)`**: An owner-only function to configure the minimum block delay between synthesis events for any canvas, preventing spamming.
20. **`withdrawProtocolFees()`**: An owner-only function to withdraw accumulated operational fees from canvas creation and weaving.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AetherWeaver
 * @dev A decentralized creative synthesizer managing dynamic NFTs (Morphic Canvases) that evolve through
 *      community contributions and AI-driven insights. Features include reputation, influence staking,
 *      and community theme governance.
 *
 * Outline and Function Summary:
 *
 * I. Core Canvas Lifecycle & Properties:
 * 1.  `createMorphicCanvas(string memory _initialTheme, string memory _initialVisualParamsHash)`: Mints a new dynamic NFT (Morphic Canvas) to the caller. Requires a fee.
 * 2.  `getCanvasDetails(uint256 _canvasId)`: Retrieves all structured on-chain data for a specific canvas.
 * 3.  `updateVisualParamsHash(uint256 _canvasId, string memory _newMetadataHash)`: Updates the off-chain hash representing the canvas's current visual state.
 * 4.  `delegateStewardship(uint256 _canvasId, address _newSteward)`: Assigns an address to manage a canvas's metadata and theme proposals.
 * 5.  `removeStewardship(uint256 _canvasId, address _stewardToRemove)`: Revokes stewardship rights from an address for a specific canvas.
 *
 * II. User Interaction & Contribution (Weaving):
 * 6.  `weaveInspiration(uint256 _canvasId, bytes32 _inspirationDataHash, string memory _promptTag)`: Users submit an off-chain data hash (inspiration) and a descriptive tag to a canvas.
 * 7.  `stakeForInfluence(uint256 _canvasId)`: Users lock ETH to amplify the weight of their contributions in future syntheses.
 * 8.  `unstakeInfluence(uint256 _canvasId, uint256 _amount)`: Allows users to retrieve their staked ETH.
 *
 * III. AI Oracle Integration & Canvas Evolution (Synthesis):
 * 9.  `submitAIInterpretation(uint256 _canvasId, string memory _aiSuggestedVisualParamsHash, bytes32 _aiAnalysisHash)`: The designated AI Oracle provides structured data to guide the canvas's evolution.
 * 10. `triggerSynthesis(uint256 _canvasId)`: Initiates the core evolution process where contributions and AI insights are processed to update the canvas.
 * 11. `proposeNewTheme(uint256 _canvasId, string memory _newTheme, bytes32 _proposalHash)`: Users can suggest new thematic directions for a canvas.
 * 12. `voteOnThemeProposal(uint256 _canvasId, bytes32 _proposalHash, bool _approve)`: Community members vote on proposed themes.
 *
 * IV. Reputation & Reward System:
 * 13. `getAetherWeaveScore(address _user)`: Retrieves a user's on-chain reputation score.
 * 14. `claimSynthesisRewards(uint256 _canvasId)`: Allows eligible contributors to claim their share of fees generated during successful syntheses.
 * 15. `claimOracleFees()`: Allows the AI Oracle to withdraw accumulated service fees.
 *
 * V. Protocol Governance & Maintenance:
 * 16. `setAIOracleAddress(address _newOracleAddress)`: Owner function to update the trusted AI Oracle address.
 * 17. `setCanvasCreationFee(uint256 _newFee)`: Owner function to adjust the fee required to mint a new Morphic Canvas.
 * 18. `setWeaveFee(uint256 _newFee)`: Owner function to adjust the fee for submitting inspirations.
 * 19. `setSynthesisCoolDown(uint256 _blocks)`: Owner function to configure the minimum block delay between synthesis events.
 * 20. `withdrawProtocolFees()`: Owner function to withdraw accumulated operational fees.
 */
contract AetherWeaver is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _canvasIds;

    // --- Data Structures ---

    struct Canvas {
        uint256 id;
        string theme; // Current main thematic descriptor
        string currentVisualParamsHash; // IPFS hash or similar for visual representation
        address creator;
        uint256 lastSynthesisBlock;
        uint256 totalContributions; // Sum of all inspirations woven
        bytes32 lastAIAnalysisHash; // Last AI interpretation received
        uint256 totalInfluenceStaked; // Total ETH staked across all users for this canvas
    }

    struct ThemeProposal {
        string newTheme;
        address proposer;
        uint256 voteCountPositive;
        uint256 voteCountNegative;
        uint256 creationBlock;
        uint256 expirationBlock; // Proposal expires after a certain number of blocks
        bool isActive;
    }

    // --- State Variables ---

    mapping(uint256 => Canvas) public canvasDetails;
    mapping(uint256 => mapping(address => bool)) public canvasStewards; // canvasId => address => isSteward
    mapping(uint256 => mapping(address => uint256)) public userStakedInfluence; // canvasId => user => amount
    mapping(uint256 => mapping(address => uint256)) public userCanvasContributions; // canvasId => user => contributionCount

    // Reputation system: Aether Weave Score
    mapping(address => uint256) public userAetherWeaveScore; // user => score

    // Theme proposals for each canvas
    mapping(uint256 => mapping(bytes32 => ThemeProposal)) public canvasThemeProposals; // canvasId => proposalHash => ThemeProposal
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public themeProposalVotes; // canvasId => proposalHash => voter => hasVoted

    address public aiOracleAddress;
    uint256 public canvasCreationFee;
    uint256 public weaveFee;
    uint256 public synthesisCoolDownBlocks; // Minimum blocks between synthesis events for a canvas
    uint256 public themeProposalExpirationBlocks; // Blocks before a theme proposal expires

    uint256 public protocolFeesCollected;
    uint256 public oracleFeesCollected;

    // --- Events ---

    event CanvasCreated(uint256 indexed canvasId, address indexed creator, string initialTheme, string initialVisualParamsHash);
    event CanvasVisualParamsUpdated(uint256 indexed canvasId, string newVisualParamsHash);
    event StewardshipDelegated(uint256 indexed canvasId, address indexed creator, address indexed newSteward);
    event StewardshipRemoved(uint256 indexed canvasId, address indexed creator, address indexed removedSteward);

    event InspirationWoven(uint256 indexed canvasId, address indexed weaver, bytes32 inspirationDataHash, string promptTag, uint256 weaveFee);
    event InfluenceStaked(uint256 indexed canvasId, address indexed staker, uint256 amount);
    event InfluenceUnstaked(uint256 indexed canvasId, address indexed staker, uint256 amount);

    event AIInterpretationSubmitted(uint256 indexed canvasId, address indexed oracle, string aiSuggestedVisualParamsHash, bytes32 aiAnalysisHash);
    event CanvasSynthesized(uint256 indexed canvasId, uint256 newContributionCount, string newTheme, string newVisualParamsHash);
    event ThemeProposalCreated(uint256 indexed canvasId, bytes32 indexed proposalHash, address indexed proposer, string newTheme);
    event ThemeProposalVoted(uint256 indexed canvasId, bytes32 indexed proposalHash, address indexed voter, bool approved);
    event ThemeApplied(uint256 indexed canvasId, string newTheme);

    event AetherWeaveScoreUpdated(address indexed user, uint256 newScore);
    event SynthesisRewardsClaimed(uint256 indexed canvasId, address indexed user, uint256 amount);
    event OracleFeesClaimed(address indexed oracle, uint256 amount);

    // --- Constructor ---

    constructor(address _aiOracleAddress, uint256 _creationFee, uint256 _weaveFee, uint256 _synthesisCoolDown, uint256 _themeProposalExpiration)
        ERC721("MorphicCanvas", "MCNVS")
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
        canvasCreationFee = _creationFee;
        weaveFee = _weaveFee;
        synthesisCoolDownBlocks = _synthesisCoolDown;
        themeProposalExpirationBlocks = _themeProposalExpiration;
    }

    // --- Modifier for Canvas Stewards ---
    modifier onlyCanvasSteward(uint256 _canvasId) {
        require(canvasStewards[_canvasId][msg.sender] || canvasDetails[_canvasId].creator == msg.sender || owner() == msg.sender, "Caller is not a canvas steward or creator");
        _;
    }

    // --- I. Core Canvas Lifecycle & Properties ---

    /**
     * @dev Mints a new dynamic NFT (Morphic Canvas) to the caller.
     * @param _initialTheme The initial thematic descriptor for the canvas.
     * @param _initialVisualParamsHash The IPFS hash or similar URI for the canvas's initial visual representation.
     */
    function createMorphicCanvas(string memory _initialTheme, string memory _initialVisualParamsHash)
        public
        payable
    {
        require(msg.value >= canvasCreationFee, "Insufficient fee to create canvas");

        _canvasIds.increment();
        uint256 newItemId = _canvasIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _initialVisualParamsHash); // Set as initial metadata URI

        canvasDetails[newItemId] = Canvas({
            id: newItemId,
            theme: _initialTheme,
            currentVisualParamsHash: _initialVisualParamsHash,
            creator: msg.sender,
            lastSynthesisBlock: block.number,
            totalContributions: 0,
            lastAIAnalysisHash: bytes32(0),
            totalInfluenceStaked: 0
        });

        protocolFeesCollected += msg.value;

        emit CanvasCreated(newItemId, msg.sender, _initialTheme, _initialVisualParamsHash);
    }

    /**
     * @dev Retrieves all essential details of a specific canvas.
     * @param _canvasId The ID of the canvas.
     * @return Tuple containing canvas details.
     */
    function getCanvasDetails(uint256 _canvasId)
        public
        view
        returns (
            uint256 id,
            string memory theme,
            string memory currentVisualParamsHash,
            address creator,
            uint256 lastSynthesisBlock,
            uint256 totalContributions,
            bytes32 lastAIAnalysisHash,
            uint256 totalInfluenceStaked
        )
    {
        Canvas storage c = canvasDetails[_canvasId];
        require(c.creator != address(0), "Canvas does not exist");
        return (
            c.id,
            c.theme,
            c.currentVisualParamsHash,
            c.creator,
            c.lastSynthesisBlock,
            c.totalContributions,
            c.lastAIAnalysisHash,
            c.totalInfluenceStaked
        );
    }

    /**
     * @dev Allows a canvas steward or creator to update the off-chain metadata URI hash for a canvas.
     *      This is crucial for dynamic NFTs, as the on-chain metadata points to evolving off-chain data.
     * @param _canvasId The ID of the canvas.
     * @param _newMetadataHash The new IPFS hash or URI for the canvas's metadata.
     */
    function updateVisualParamsHash(uint256 _canvasId, string memory _newMetadataHash)
        public
        onlyCanvasSteward(_canvasId)
    {
        require(bytes(_newMetadataHash).length > 0, "Metadata hash cannot be empty");
        Canvas storage c = canvasDetails[_canvasId];
        require(c.creator != address(0), "Canvas does not exist"); // Additional check

        c.currentVisualParamsHash = _newMetadataHash;
        _setTokenURI(_canvasId, _newMetadataHash); // Update the tokenURI for the ERC721 NFT
        emit CanvasVisualParamsUpdated(_canvasId, _newMetadataHash);
    }

    /**
     * @dev Delegates stewardship rights for a specific canvas to another address.
     *      Only the canvas creator or owner can delegate stewardship.
     * @param _canvasId The ID of the canvas.
     * @param _newSteward The address to delegate stewardship to.
     */
    function delegateStewardship(uint256 _canvasId, address _newSteward)
        public
        onlyCanvasSteward(_canvasId)
    {
        require(_newSteward != address(0), "Steward address cannot be zero");
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(!canvasStewards[_canvasId][_newSteward], "Address is already a steward");

        canvasStewards[_canvasId][_newSteward] = true;
        emit StewardshipDelegated(_canvasId, msg.sender, _newSteward);
    }

    /**
     * @dev Removes stewardship rights from an address for a specific canvas.
     *      Only the canvas creator or owner can remove stewardship.
     * @param _canvasId The ID of the canvas.
     * @param _stewardToRemove The address to remove stewardship from.
     */
    function removeStewardship(uint256 _canvasId, address _stewardToRemove)
        public
        onlyCanvasSteward(_canvasId)
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(canvasStewards[_canvasId][_stewardToRemove], "Address is not a steward");

        canvasStewards[_canvasId][_stewardToRemove] = false;
        emit StewardshipRemoved(_canvasId, msg.sender, _stewardToRemove);
    }

    // --- II. User Interaction & Contribution (Weaving) ---

    /**
     * @dev Allows users to contribute an "inspiration" to a canvas. This involves
     *      submitting a hash of off-chain data and a descriptive tag.
     * @param _canvasId The ID of the canvas to contribute to.
     * @param _inspirationDataHash A hash of the off-chain inspiration data (e.g., IPFS hash of text/image).
     * @param _promptTag A short descriptive tag for the inspiration.
     */
    function weaveInspiration(uint256 _canvasId, bytes32 _inspirationDataHash, string memory _promptTag)
        public
        payable
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(msg.value >= weaveFee, "Insufficient fee to weave inspiration");
        require(_inspirationDataHash != bytes32(0), "Inspiration data hash cannot be zero");
        require(bytes(_promptTag).length > 0, "Prompt tag cannot be empty");

        Canvas storage c = canvasDetails[_canvasId];
        c.totalContributions++;
        userCanvasContributions[_canvasId][msg.sender]++;
        protocolFeesCollected += msg.value;

        // Potentially increase Aether Weave Score based on contribution quality/impact later
        // For now, a simple increment for any contribution
        _updateAetherWeaveScore(msg.sender, 1);

        emit InspirationWoven(_canvasId, msg.sender, _inspirationDataHash, _promptTag, msg.value);
    }

    /**
     * @dev Allows users to stake ETH for a canvas to increase their influence during synthesis.
     *      The staked ETH is held by the contract but remains attributable to the user.
     * @param _canvasId The ID of the canvas to stake for.
     */
    function stakeForInfluence(uint256 _canvasId)
        public
        payable
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(msg.value > 0, "Cannot stake zero ETH");

        userStakedInfluence[_canvasId][msg.sender] += msg.value;
        canvasDetails[_canvasId].totalInfluenceStaked += msg.value;

        emit InfluenceStaked(_canvasId, msg.sender, msg.value);
    }

    /**
     * @dev Allows users to unstake a portion or all of their staked ETH for a canvas.
     * @param _canvasId The ID of the canvas.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeInfluence(uint256 _canvasId, uint256 _amount)
        public
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(_amount > 0, "Cannot unstake zero ETH");
        require(userStakedInfluence[_canvasId][msg.sender] >= _amount, "Insufficient staked influence");

        userStakedInfluence[_canvasId][msg.sender] -= _amount;
        canvasDetails[_canvasId].totalInfluenceStaked -= _amount;
        payable(msg.sender).transfer(_amount);

        emit InfluenceUnstaked(_canvasId, msg.sender, _amount);
    }

    // --- III. AI Oracle Integration & Canvas Evolution (Synthesis) ---

    /**
     * @dev Allows the designated AI Oracle to submit its interpretation and suggested visual parameters
     *      based on the current state and contributions of a canvas.
     * @param _canvasId The ID of the canvas.
     * @param _aiSuggestedVisualParamsHash The AI's suggested new IPFS hash for the canvas's visuals.
     * @param _aiAnalysisHash A hash of the AI's detailed analysis (off-chain).
     */
    function submitAIInterpretation(uint256 _canvasId, string memory _aiSuggestedVisualParamsHash, bytes32 _aiAnalysisHash)
        public
    {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can submit interpretations");
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(bytes(_aiSuggestedVisualParamsHash).length > 0, "AI suggested hash cannot be empty");
        require(_aiAnalysisHash != bytes32(0), "AI analysis hash cannot be zero");

        Canvas storage c = canvasDetails[_canvasId];
        c.lastAIAnalysisHash = _aiAnalysisHash;
        c.currentVisualParamsHash = _aiSuggestedVisualParamsHash; // AI's suggestion immediately updates the visuals
        oracleFeesCollected += weaveFee; // Reward the oracle for its service, simple model for now

        emit AIInterpretationSubmitted(_canvasId, msg.sender, _aiSuggestedVisualParamsHash, _aiAnalysisHash);
        // Note: The visual params are immediately updated here, synthesis then finalizes the state and rewards.
    }

    /**
     * @dev Triggers the synthesis process for a canvas. This involves aggregating contributions,
     *      applying AI insights, evaluating theme proposals, and updating the canvas's state.
     * @param _canvasId The ID of the canvas to synthesize.
     */
    function triggerSynthesis(uint256 _canvasId)
        public
    {
        Canvas storage c = canvasDetails[_canvasId];
        require(c.creator != address(0), "Canvas does not exist");
        require(block.number >= c.lastSynthesisBlock + synthesisCoolDownBlocks, "Synthesis cooldown period not over");
        require(c.totalContributions > 0, "No new contributions since last synthesis");

        // --- Core Synthesis Logic ---

        // 1. Evaluate Theme Proposals
        bytes32 winningProposalHash = bytes32(0);
        uint256 highestPositiveVotes = 0;
        // Iterate through active proposals (simplified: could use an array of active hashes)
        // For demonstration, let's assume one winning proposal based on simple majority
        // In a real system, you'd iterate through canvasThemeProposals[_canvasId]
        // This part would need a way to enumerate active proposals
        for (uint256 i = 0; i < 10; i++) { // Placeholder loop, would be more dynamic
            bytes32 proposalCheckHash = keccak256(abi.encodePacked(Strings.toString(i))); // Example placeholder
            ThemeProposal storage proposal = canvasThemeProposals[_canvasId][proposalCheckHash];
            if (proposal.isActive && block.number < proposal.expirationBlock) {
                 if (proposal.voteCountPositive > highestPositiveVotes && proposal.voteCountPositive > proposal.voteCountNegative) {
                    highestPositiveVotes = proposal.voteCountPositive;
                    winningProposalHash = proposalCheckHash;
                 }
            }
        }

        if (winningProposalHash != bytes32(0)) {
            ThemeProposal storage winningProposal = canvasThemeProposals[_canvasId][winningProposalHash];
            c.theme = winningProposal.newTheme;
            winningProposal.isActive = false; // Deactivate
            emit ThemeApplied(_canvasId, c.newTheme);
            // Reward proposer for successful theme application
            _updateAetherWeaveScore(winningProposal.proposer, 10);
        }

        // 2. Apply AI Visual Parameters (already done in submitAIInterpretation, here just finalize)
        // c.currentVisualParamsHash should be updated by the oracle.
        // If no AI interpretation was provided, canvas visuals remain the same.

        // 3. Reward Contributors (simplified: equal share for all contributors)
        uint256 totalWeaveFees = c.totalContributions * weaveFee;
        uint256 rewardsPerContribution = totalWeaveFees / (c.totalContributions == 0 ? 1 : c.totalContributions); // Avoid division by zero
        
        // This part is complex for on-chain. Ideally, rewards are distributed off-chain
        // or through a separate claimable balance. For this example, we distribute from protocolFees.
        // A more advanced system would track _who_ contributed to this synthesis cycle.
        // For now, protocolFees will cover a reward pool for contributors for this cycle.
        uint256 totalRewardsPool = protocolFeesCollected / 2; // Example: half of protocol fees
        uint256 rewardPerContributionUnit = totalRewardsPool / (c.totalContributions == 0 ? 1 : c.totalContributions);

        // This loop would be too expensive for a large number of contributors.
        // A better approach: when a user claims, calculate their share based on their contributions.
        // For now, we'll increment Aether Weave Score based on overall canvas success.
        _updateAetherWeaveScore(c.creator, 5); // Reward creator for successful synthesis
        
        // Reset contribution specific counters
        c.totalContributions = 0; // Clear for next cycle
        c.lastSynthesisBlock = block.number;

        emit CanvasSynthesized(_canvasId, c.totalContributions, c.theme, c.currentVisualParamsHash);
    }

    /**
     * @dev Allows users with sufficient Aether Weave Score to propose a new theme for a canvas.
     * @param _canvasId The ID of the canvas.
     * @param _newTheme The proposed new theme string.
     * @param _proposalHash A unique hash identifier for this proposal.
     */
    function proposeNewTheme(uint256 _canvasId, string memory _newTheme, bytes32 _proposalHash)
        public
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        require(userAetherWeaveScore[msg.sender] >= 5, "Insufficient Aether Weave Score to propose theme"); // Example score threshold
        require(bytes(_newTheme).length > 0, "New theme cannot be empty");
        require(canvasThemeProposals[_canvasId][_proposalHash].proposer == address(0), "Proposal hash already in use");

        canvasThemeProposals[_canvasId][_proposalHash] = ThemeProposal({
            newTheme: _newTheme,
            proposer: msg.sender,
            voteCountPositive: 0,
            voteCountNegative: 0,
            creationBlock: block.number,
            expirationBlock: block.number + themeProposalExpirationBlocks,
            isActive: true
        });

        emit ThemeProposalCreated(_canvasId, _proposalHash, msg.sender, _newTheme);
    }

    /**
     * @dev Allows community members to vote on active theme proposals.
     * @param _canvasId The ID of the canvas.
     * @param _proposalHash The hash of the proposal being voted on.
     * @param _approve True for a positive vote, false for a negative vote.
     */
    function voteOnThemeProposal(uint256 _canvasId, bytes32 _proposalHash, bool _approve)
        public
    {
        ThemeProposal storage proposal = canvasThemeProposals[_canvasId][_proposalHash];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.isActive, "Proposal is not active");
        require(block.number < proposal.expirationBlock, "Proposal has expired");
        require(!themeProposalVotes[_canvasId][_proposalHash][msg.sender], "Already voted on this proposal");

        if (_approve) {
            proposal.voteCountPositive++;
        } else {
            proposal.voteCountNegative++;
        }
        themeProposalVotes[_canvasId][_proposalHash][msg.sender] = true;

        emit ThemeProposalVoted(_canvasId, _proposalHash, msg.sender, _approve);
        _updateAetherWeaveScore(msg.sender, 1); // Reward voter with small score
    }

    // --- IV. Reputation & Reward System ---

    /**
     * @dev Returns the Aether Weave Score for a given user.
     * @param _user The address of the user.
     * @return The Aether Weave Score.
     */
    function getAetherWeaveScore(address _user) public view returns (uint256) {
        return userAetherWeaveScore[_user];
    }

    /**
     * @dev Internal function to update a user's Aether Weave Score.
     * @param _user The address of the user.
     * @param _points The points to add (can be negative for deductions, though not implemented here).
     */
    function _updateAetherWeaveScore(address _user, uint256 _points) internal {
        userAetherWeaveScore[_user] += _points;
        emit AetherWeaveScoreUpdated(_user, userAetherWeaveScore[_user]);
    }

    /**
     * @dev Allows eligible contributors to claim their share of rewards after a successful synthesis.
     *      (Simplified: currently just awards based on contribution count, a more complex system
     *      would track rewards per synthesis cycle.)
     * @param _canvasId The ID of the canvas.
     */
    function claimSynthesisRewards(uint256 _canvasId)
        public
    {
        require(canvasDetails[_canvasId].creator != address(0), "Canvas does not exist");
        uint256 contributions = userCanvasContributions[_canvasId][msg.sender];
        require(contributions > 0, "No unclaimed contributions for this canvas");

        // Simple reward model: 50% of weaveFee for this user's contributions.
        // This assumes protocol has collected weaveFee from _this user's_ contributions.
        // In a real system, you'd manage a pool of rewards for each synthesis cycle.
        uint256 rewardAmount = contributions * weaveFee / 2; // Example: 50% of their weave fees returned as reward

        require(protocolFeesCollected >= rewardAmount, "Insufficient protocol fees for rewards");

        protocolFeesCollected -= rewardAmount;
        userCanvasContributions[_canvasId][msg.sender] = 0; // Reset for next cycle
        payable(msg.sender).transfer(rewardAmount);

        emit SynthesisRewardsClaimed(_canvasId, msg.sender, rewardAmount);
        _updateAetherWeaveScore(msg.sender, contributions); // Reward score for claiming
    }

    /**
     * @dev Allows the AI Oracle to withdraw its accumulated service fees.
     */
    function claimOracleFees() public {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can claim fees");
        uint256 amount = oracleFeesCollected;
        require(amount > 0, "No oracle fees to claim");

        oracleFeesCollected = 0;
        payable(msg.sender).transfer(amount);

        emit OracleFeesClaimed(msg.sender, amount);
    }

    // --- V. Protocol Governance & Maintenance ---

    /**
     * @dev Owner-only function to set the address of the AI Oracle.
     * @param _newOracleAddress The new AI Oracle address.
     */
    function setAIOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _newOracleAddress;
    }

    /**
     * @dev Owner-only function to set the fee for creating a new Morphic Canvas.
     * @param _newFee The new canvas creation fee in Wei.
     */
    function setCanvasCreationFee(uint256 _newFee) public onlyOwner {
        canvasCreationFee = _newFee;
    }

    /**
     * @dev Owner-only function to set the fee for weaving an inspiration into a canvas.
     * @param _newFee The new weave fee in Wei.
     */
    function setWeaveFee(uint256 _newFee) public onlyOwner {
        weaveFee = _newFee;
    }

    /**
     * @dev Owner-only function to set the minimum number of blocks between synthesis events for a canvas.
     * @param _blocks The new cooldown period in blocks.
     */
    function setSynthesisCoolDown(uint256 _blocks) public onlyOwner {
        synthesisCoolDownBlocks = _blocks;
    }

    /**
     * @dev Owner-only function to set the number of blocks a theme proposal remains active.
     * @param _blocks The new expiration period in blocks.
     */
    function setThemeProposalExpiration(uint256 _blocks) public onlyOwner {
        themeProposalExpirationBlocks = _blocks;
    }

    /**
     * @dev Owner-only function to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() public onlyOwner {
        uint256 amount = protocolFeesCollected;
        require(amount > 0, "No protocol fees to withdraw");

        protocolFeesCollected = 0;
        payable(msg.sender).transfer(amount);
    }

    // --- ERC721 Overrides (for token URI handling) ---

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Base URI for IPFS, actual URI set per token
    }

    // A getter for the token URI, useful for frontends
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return canvasDetails[tokenId].currentVisualParamsHash;
    }
}
```