Okay, this is an exciting challenge! Let's craft a smart contract that blends concepts like *collective intelligence*, *dynamic NFTs*, *reputation systems*, and *on-chain evolutionary algorithms*, with hooks for future *verifiable off-chain computation*.

I'll call this contract `NexusWeaver`. It's designed as a protocol where a community collaboratively "trains" or "evolves" a generative algorithm ("The Weave") by submitting "Pattern Data". This evolution then influences the traits of dynamic "Nexus NFTs" that users can mint. These NFTs themselves can further evolve based on their owner's specific input, tied to their on-chain reputation and staked influence.

---

### Contract Outline and Function Summary

**Contract Name:** `NexusWeaver`

**Description:**
`NexusWeaver` is a decentralized protocol for generating and evolving unique digital assets (Nexus NFTs) through a community-driven, on-chain generative algorithm ("The Weave"). Participants contribute "Pattern Data" to influence the global Weave's evolution, with their impact weighted by reputation and staked influence. Minted Nexus NFTs capture a snapshot of the Weave, and owners can further evolve their individual NFTs within defined windows. The protocol includes a soulbound-like reputation system, a staking mechanism for influence, and an on-chain governance module for key protocol parameters.

---

**Function Summary:**

**I. Core Weave Algorithm Management & Evolution (Collective Intelligence)**
1.  `submitPatternData(uint256[] calldata dataPoints)`: Allows users to submit data points that collectively influence the global Weave algorithm. Their reputation and staked influence determine the weight of their submission.
2.  `evolveGlobalWeave()`: Triggers the evolution of the global Weave algorithm based on aggregated submitted data and a time-based decay. Callable by anyone, incentivized via a small reward.
3.  `getGlobalWeaveState() view returns (uint256[] memory currentWeaveParameters, uint256 lastEvolutionBlock)`: Retrieves the current parameters and state of the global Weave algorithm.
4.  `setEvolutionInterval(uint256 _blocks)`: Admin function to set the minimum block interval between global Weave evolutions.
5.  `setWeaveParameterWeight(uint256 paramIndex, uint256 weight)`: Admin function to adjust the influence weight of specific parameters within the global Weave algorithm.

**II. Reputation & Influence System (Soulbound-like & Staked)**
6.  `grantReputation(address user, uint256 amount)`: Admin/DAO function to issue reputation points (soulbound-like, non-transferable) to a user for their contributions.
7.  `revokeReputation(address user, uint256 amount)`: Admin/DAO function to deduct reputation points from a user.
8.  `getReputation(address user) view returns (uint256)`: Retrieves the reputation score of a specific user.
9.  `stakeInfluence(uint256 amount)`: Allows users to stake an ERC-20 token (e.g., `NW_InfluenceToken`) to gain additional influence weight on their pattern data submissions and governance votes.
10. `unstakeInfluence(uint256 amount)`: Allows users to unstake their `NW_InfluenceToken`.
11. `getStakedInfluence(address user) view returns (uint256)`: Retrieves the amount of `NW_InfluenceToken` staked by a user.

**III. Nexus NFTs (Dynamic & Owner-Evolvable ERC-721)**
12. `mintNexusNFT(string calldata initialMetadataURI)`: Mints a new Nexus NFT, capturing a immutable snapshot of the global Weave's state at the time of minting as its "genesis traits".
13. `evolveNexusNFT(uint256 tokenId, uint256[] calldata evolutionParams)`: Allows the owner of a Nexus NFT to introduce their own pattern data to evolve their specific NFT's *dynamic traits* within its designated evolution window.
14. `setNFTEvolutionWindow(uint256 tokenId, uint256 endBlock)`: Allows a Nexus NFT owner to define a block number until which their NFT can be evolved.
15. `lockNFTEvolution(uint256 tokenId)`: Allows a Nexus NFT owner to permanently lock their NFT's dynamic traits, preventing further evolution.
16. `getNexusNFTData(uint256 tokenId) view returns (NexusNFTData memory)`: Retrieves all the internal, dynamic data associated with a specific Nexus NFT.
17. `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates a dynamic metadata URI for a Nexus NFT, reflecting its current genesis and evolved traits.

**IV. Decentralized Governance & Protocol Evolution**
18. `proposeGlobalWeaveAmendment(string calldata description, uint256[] calldata newWeaveParams)`: Allows users with sufficient reputation to propose direct amendments to the global Weave's core parameters.
19. `voteOnProposal(uint256 proposalId, bool support)`: Allows reputation and influence holders to vote on active proposals.
20. `executeProposal(uint256 proposalId)`: Executes a proposal that has passed its voting period and met quorum.
21. `setMintFee(uint256 fee)`: Admin/DAO function to set the fee for minting a Nexus NFT.
22. `setMinimumInfluenceForProposal(uint256 amount)`: Admin/DAO function to set the minimum staked influence required to create a governance proposal.

**V. Rewards & Configuration**
23. `claimWeaveEvolutionReward()`: Allows the user who successfully calls `evolveGlobalWeave()` to claim a small reward.
24. `withdrawProtocolFees()`: Admin/DAO function to withdraw collected fees (e.g., minting fees) from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NexusWeaver
 * @dev A decentralized protocol for generating and evolving unique digital assets (Nexus NFTs)
 *      through a community-driven, on-chain generative algorithm ("The Weave").
 *      Participants contribute "Pattern Data" to influence the global Weave's evolution,
 *      with their impact weighted by reputation and staked influence.
 *      Minted Nexus NFTs capture a snapshot of the Weave, and owners can further evolve their
 *      individual NFTs within defined windows. The protocol includes a soulbound-like
 *      reputation system, a staking mechanism for influence, and an on-chain governance module
 *      for key protocol parameters.
 */
contract NexusWeaver is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Events ---
    event PatternDataSubmitted(address indexed sender, uint256 influenceWeight, uint256[] dataPoints);
    event GlobalWeaveEvolved(uint256[] newWeaveParameters, uint256 indexed evolutionBlock);
    event ReputationGranted(address indexed user, uint256 amount);
    event ReputationRevoked(address indexed user, uint256 amount);
    event InfluenceStaked(address indexed user, uint256 amount);
    event InfluenceUnstaked(address indexed user, uint256 amount);
    event NexusNFTMinted(address indexed minter, uint256 indexed tokenId, uint256[] genesisWeaveSnapshot);
    event NexusNFTEvolved(uint256 indexed tokenId, uint256[] evolutionParams, uint256 indexed evolutionBlock);
    event NFTEvolutionWindowSet(uint256 indexed tokenId, uint256 endBlock);
    event NFTEvolutionLocked(uint256 indexed tokenId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 creationBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event MintFeeSet(uint256 newFee);
    event MinimumInfluenceForProposalSet(uint256 amount);

    // --- State Variables ---

    // I. Core Weave Algorithm Management
    uint256[] public globalWeaveParameters; // The current state of the global generative algorithm
    uint256 public lastGlobalWeaveEvolutionBlock;
    uint256 public globalWeaveEvolutionIntervalBlocks; // Min blocks between evolutions
    mapping(uint256 => uint256) public weaveParameterWeights; // Weights for individual parameters during evolution
    uint256[] private _pendingPatternData; // Aggregated data awaiting next evolution
    uint256 private _pendingPatternDataInfluence; // Total influence weight for _pendingPatternData
    uint256 public constant WEAVE_PARAMETER_COUNT = 16; // Number of parameters in the global weave

    // II. Reputation & Influence System
    mapping(address => uint256) public userReputation; // Non-transferable reputation points
    IERC20 public nwInfluenceToken; // The ERC-20 token used for staking influence
    mapping(address => uint256) public stakedInfluence; // Amount of nwInfluenceToken staked by user

    // III. Nexus NFTs (ERC-721)
    Counters.Counter private _tokenIdCounter;
    struct NexusNFTData {
        uint256[] genesisWeaveSnapshot; // Snapshot of globalWeaveParameters at minting (immutable base traits)
        uint256[] currentDynamicTraits;   // Traits evolved by the owner (mutable)
        uint256 evolutionWindowEndBlock;  // Block number until which owner can evolve traits
        bool evolutionLocked;             // True if owner has locked evolution
    }
    mapping(uint256 => NexusNFTData) public nexusNFTs;

    // IV. Decentralized Governance
    struct Proposal {
        string description;
        uint224 creationBlock;
        uint224 startBlock;
        uint224 endBlock;
        uint256[] proposedWeaveParams; // New weave parameters if proposal passes
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodBlocks = 100; // Default voting period
    uint256 public proposalExecutionDelayBlocks = 10; // Delay before a passed proposal can be executed
    uint256 public minStakedInfluenceForProposal; // Minimum staked influence to create a proposal
    uint256 public quorumPercentage = 4; // % of total staked influence required for proposal to pass (e.g., 4% = 400 basis points)

    // V. Rewards & Configuration
    uint256 public nexusMintFee; // Fee in native currency (ETH/MATIC) to mint a Nexus NFT
    uint256 public weaveEvolutionReward; // Reward for calling evolveGlobalWeave()

    // --- Modifiers ---
    modifier onlyReputationCouncil() {
        // In a more complex DAO, this would be a multi-sig or a DAO vote result.
        // For this example, only the owner can grant/revoke reputation.
        require(msg.sender == owner(), "NexusWeaver: Only owner can manage reputation");
        _;
    }

    modifier onlyWeaveParamSubmitter(uint256[] calldata dataPoints) {
        require(dataPoints.length == WEAVE_PARAMETER_COUNT, "NexusWeaver: Invalid number of pattern data points");
        for (uint256 i = 0; i < dataPoints.length; i++) {
            require(dataPoints[i] <= type(uint128).max, "NexusWeaver: Pattern data point exceeds max value");
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _influenceTokenAddress,
        uint256 _initialMintFee,
        uint256 _initialEvolutionReward,
        uint256 _initialMinInfluenceForProposal
    ) ERC721("Nexus Weaver", "NEXUS") Ownable(msg.sender) {
        nwInfluenceToken = IERC20(_influenceTokenAddress);
        nexusMintFee = _initialMintFee;
        weaveEvolutionReward = _initialEvolutionReward;
        globalWeaveEvolutionIntervalBlocks = 20; // Default: every 20 blocks
        minStakedInfluenceForProposal = _initialMinInfluenceForProposal;

        // Initialize global weave parameters (e.g., random values or a predefined seed)
        globalWeaveParameters = new uint256[](WEAVE_PARAMETER_COUNT);
        _pendingPatternData = new uint256[](WEAVE_PARAMETER_COUNT);
        for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
            globalWeaveParameters[i] = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % 1000) + 1; // Initial random values
            weaveParameterWeights[i] = 100; // Default weight for each parameter (e.g., 100%)
            _pendingPatternData[i] = 0;
        }
        lastGlobalWeaveEvolutionBlock = block.number;
    }

    // --- I. Core Weave Algorithm Management & Evolution ---

    /**
     * @dev Allows users to submit data points that collectively influence the global Weave algorithm.
     *      Their reputation and staked influence determine the weight of their submission.
     *      Each data point is capped at uint128 to prevent overflow issues during aggregation.
     * @param dataPoints An array of uint256 representing the pattern data. Must be WEAVE_PARAMETER_COUNT long.
     */
    function submitPatternData(uint256[] calldata dataPoints)
        external
        nonReentrant
        onlyWeaveParamSubmitter(dataPoints)
    {
        uint256 currentInfluence = _calculateUserInfluence(msg.sender);
        require(currentInfluence > 0, "NexusWeaver: No influence to submit pattern data");

        // Aggregate data with influence weighting
        for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
            _pendingPatternData[i] += dataPoints[i] * currentInfluence;
        }
        _pendingPatternDataInfluence += currentInfluence;

        emit PatternDataSubmitted(msg.sender, currentInfluence, dataPoints);
    }

    /**
     * @dev Triggers the evolution of the global Weave algorithm based on aggregated submitted data and a time-based decay.
     *      Callable by anyone, incentivized via a small reward.
     */
    function evolveGlobalWeave() external nonReentrant {
        require(block.number >= lastGlobalWeaveEvolutionBlock + globalWeaveEvolutionIntervalBlocks, "NexusWeaver: Not enough blocks have passed for global weave evolution");

        uint256 totalInfluence = _pendingPatternDataInfluence;
        if (totalInfluence == 0) {
            // If no new data, apply a slight decay or random perturbation to keep it "alive"
            for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
                uint256 currentVal = globalWeaveParameters[i];
                if (currentVal > 1) { // Prevent reducing to 0 or negative
                    globalWeaveParameters[i] = currentVal - (currentVal / (1000 + (block.number % 100))); // Small decay
                }
            }
        } else {
            for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
                uint256 weightedAvg = (_pendingPatternData[i] * weaveParameterWeights[i]) / (totalInfluence * 100); // Normalize by total influence and weight
                globalWeaveParameters[i] = (globalWeaveParameters[i] + weightedAvg) / 2; // Average with current state
            }
        }

        // Reset pending data
        for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
            _pendingPatternData[i] = 0;
        }
        _pendingPatternDataInfluence = 0;

        lastGlobalWeaveEvolutionBlock = block.number;

        // Reward the caller
        if (weaveEvolutionReward > 0) {
            (bool success,) = msg.sender.call{value: weaveEvolutionReward}("");
            require(success, "NexusWeaver: Failed to send evolution reward");
        }

        emit GlobalWeaveEvolved(globalWeaveParameters, block.number);
    }

    /**
     * @dev Retrieves the current parameters and state of the global Weave algorithm.
     * @return currentWeaveParameters The current values of the global Weave parameters.
     * @return lastEvolutionBlock The block number of the last global Weave evolution.
     */
    function getGlobalWeaveState()
        external
        view
        returns (uint256[] memory currentWeaveParameters, uint256 lastEvolutionBlock)
    {
        return (globalWeaveParameters, lastGlobalWeaveEvolutionBlock);
    }

    /**
     * @dev Admin function to set the minimum block interval between global Weave evolutions.
     * @param _blocks The new minimum block interval.
     */
    function setEvolutionInterval(uint256 _blocks) external onlyOwner {
        require(_blocks > 0, "NexusWeaver: Interval must be positive");
        globalWeaveEvolutionIntervalBlocks = _blocks;
    }

    /**
     * @dev Admin function to adjust the influence weight of specific parameters within the global Weave algorithm.
     *      Weights are percentage based (e.g., 100 for 100%).
     * @param paramIndex The index of the parameter to adjust.
     * @param weight The new weight for the parameter (e.g., 100 for 100%).
     */
    function setWeaveParameterWeight(uint256 paramIndex, uint256 weight) external onlyOwner {
        require(paramIndex < WEAVE_PARAMETER_COUNT, "NexusWeaver: Invalid parameter index");
        require(weight <= 200 && weight >= 0, "NexusWeaver: Weight must be between 0 and 200%"); // Cap to prevent excessive influence
        weaveParameterWeights[paramIndex] = weight;
    }

    // --- II. Reputation & Influence System ---

    /**
     * @dev Admin/DAO function to issue reputation points (soulbound-like, non-transferable) to a user for their contributions.
     *      These points cannot be transferred or explicitly traded, acting as a verifiable credential of participation.
     * @param user The address to grant reputation to.
     * @param amount The amount of reputation points to grant.
     */
    function grantReputation(address user, uint256 amount) external onlyReputationCouncil {
        require(user != address(0), "NexusWeaver: Invalid address");
        userReputation[user] += amount;
        emit ReputationGranted(user, amount);
    }

    /**
     * @dev Admin/DAO function to deduct reputation points from a user.
     * @param user The address to revoke reputation from.
     * @param amount The amount of reputation points to revoke.
     */
    function revokeReputation(address user, uint256 amount) external onlyReputationCouncil {
        require(userReputation[user] >= amount, "NexusWeaver: Insufficient reputation to revoke");
        userReputation[user] -= amount;
        emit ReputationRevoked(user, amount);
    }

    /**
     * @dev Retrieves the reputation score of a specific user.
     * @param user The address of the user.
     * @return The user's current reputation points.
     */
    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Allows users to stake an ERC-20 token (e.g., `NW_InfluenceToken`) to gain additional influence
     *      weight on their pattern data submissions and governance votes.
     * @param amount The amount of `nwInfluenceToken` to stake.
     */
    function stakeInfluence(uint256 amount) external nonReentrant {
        require(amount > 0, "NexusWeaver: Amount must be greater than zero");
        require(nwInfluenceToken.transferFrom(msg.sender, address(this), amount), "NexusWeaver: Token transfer failed");
        stakedInfluence[msg.sender] += amount;
        emit InfluenceStaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to unstake their `NW_InfluenceToken`.
     * @param amount The amount of `nwInfluenceToken` to unstake.
     */
    function unstakeInfluence(uint256 amount) external nonReentrant {
        require(amount > 0, "NexusWeaver: Amount must be greater than zero");
        require(stakedInfluence[msg.sender] >= amount, "NexusWeaver: Insufficient staked influence");
        stakedInfluence[msg.sender] -= amount;
        require(nwInfluenceToken.transfer(msg.sender, amount), "NexusWeaver: Token transfer failed");
        emit InfluenceUnstaked(msg.sender, amount);
    }

    /**
     * @dev Retrieves the amount of `nwInfluenceToken` staked by a user.
     * @param user The address of the user.
     * @return The amount of staked influence.
     */
    function getStakedInfluence(address user) external view returns (uint256) {
        return stakedInfluence[user];
    }

    /**
     * @dev Internal helper to calculate a user's total influence weight.
     * @param user The address of the user.
     * @return The calculated influence weight.
     */
    function _calculateUserInfluence(address user) internal view returns (uint256) {
        // Example: Influence = Reputation + (StakedInfluence / 10)
        // This scaling factor can be adjusted.
        return userReputation[user] + (stakedInfluence[user] / 10);
    }

    // --- III. Nexus NFTs (Dynamic & Owner-Evolvable ERC-721) ---

    /**
     * @dev Mints a new Nexus NFT, capturing an immutable snapshot of the global Weave's state
     *      at the time of minting as its "genesis traits".
     * @param initialMetadataURI A base URI for metadata, which will be dynamically enriched.
     * @return The tokenId of the newly minted NFT.
     */
    function mintNexusNFT(string calldata initialMetadataURI) external payable nonReentrant returns (uint256) {
        require(msg.value >= nexusMintFee, "NexusWeaver: Insufficient mint fee");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Capture a deep copy of the current global weave state as genesis traits
        uint256[] memory genesisSnapshot = new uint256[](WEAVE_PARAMETER_COUNT);
        for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
            genesisSnapshot[i] = globalWeaveParameters[i];
        }

        nexusNFTs[newTokenId] = NexusNFTData({
            genesisWeaveSnapshot: genesisSnapshot,
            currentDynamicTraits: genesisSnapshot, // Initially, dynamic traits are same as genesis
            evolutionWindowEndBlock: 0, // No evolution window by default, owner sets it
            evolutionLocked: false
        });

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, initialMetadataURI); // Base URI, augmented by dynamic logic

        emit NexusNFTMinted(msg.sender, newTokenId, genesisSnapshot);
        return newTokenId;
    }

    /**
     * @dev Allows the owner of a Nexus NFT to introduce their own pattern data to evolve their
     *      specific NFT's *dynamic traits* within its designated evolution window.
     *      This only affects the individual NFT, not the global Weave.
     * @param tokenId The ID of the Nexus NFT to evolve.
     * @param evolutionParams An array of uint256 representing the evolution parameters.
     */
    function evolveNexusNFT(uint256 tokenId, uint256[] calldata evolutionParams)
        external
        nonReentrant
        onlyWeaveParamSubmitter(evolutionParams)
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NexusWeaver: Caller is not owner nor approved");
        NexusNFTData storage nft = nexusNFTs[tokenId];
        require(!nft.evolutionLocked, "NexusWeaver: NFT evolution is locked");
        require(nft.evolutionWindowEndBlock > 0 && block.number <= nft.evolutionWindowEndBlock, "NexusWeaver: NFT evolution window has expired or not set");

        // Simple evolution logic: average owner's params with current dynamic traits
        for (uint256 i = 0; i < WEAVE_PARAMETER_COUNT; i++) {
            nft.currentDynamicTraits[i] = (nft.currentDynamicTraits[i] + evolutionParams[i]) / 2;
        }

        // Emit an event that the tokenURI might be updated
        emit NexusNFTEvolved(tokenId, evolutionParams, block.number);
    }

    /**
     * @dev Allows a Nexus NFT owner to define a block number until which their NFT can be evolved.
     *      Setting to 0 essentially closes the window until reset.
     * @param tokenId The ID of the Nexus NFT.
     * @param endBlock The block number at which the evolution window closes. Must be in the future.
     */
    function setNFTEvolutionWindow(uint256 tokenId, uint256 endBlock) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NexusWeaver: Caller is not owner nor approved");
        NexusNFTData storage nft = nexusNFTs[tokenId];
        require(!nft.evolutionLocked, "NexusWeaver: NFT evolution is locked");
        require(endBlock == 0 || endBlock > block.number, "NexusWeaver: Evolution window end block must be in the future");
        nft.evolutionWindowEndBlock = endBlock;
        emit NFTEvolutionWindowSet(tokenId, endBlock);
    }

    /**
     * @dev Allows a Nexus NFT owner to permanently lock their NFT's dynamic traits, preventing further evolution.
     *      This action is irreversible.
     * @param tokenId The ID of the Nexus NFT.
     */
    function lockNFTEvolution(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NexusWeaver: Caller is not owner nor approved");
        NexusNFTData storage nft = nexusNFTs[tokenId];
        require(!nft.evolutionLocked, "NexusWeaver: NFT evolution already locked");
        nft.evolutionLocked = true;
        emit NFTEvolutionLocked(tokenId);
    }

    /**
     * @dev Retrieves all the internal, dynamic data associated with a specific Nexus NFT.
     * @param tokenId The ID of the Nexus NFT.
     * @return A struct containing the NFT's genesis snapshot, current dynamic traits, evolution window, and lock status.
     */
    function getNexusNFTData(uint256 tokenId) external view returns (NexusNFTData memory) {
        return nexusNFTs[tokenId];
    }

    /**
     * @dev Generates a dynamic metadata URI for a Nexus NFT, reflecting its current genesis and evolved traits.
     *      This URI points to an off-chain service that interprets the on-chain NFT data.
     * @param tokenId The ID of the Nexus NFT.
     * @return The dynamic metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        NexusNFTData storage nft = nexusNFTs[tokenId];

        // Example: Base URI + token ID + current dynamic traits (encoded) + genesis traits (encoded) + evolution status
        // In a real scenario, this would likely point to an API endpoint that queries the contract
        // or IPFS/Arweave CID that contains a template + a resolver.
        string memory baseURI = _baseURI();
        string memory encodedDynamicTraits = _encodeUintArray(nft.currentDynamicTraits);
        string memory encodedGenesisTraits = _encodeUintArray(nft.genesisWeaveSnapshot);

        return string(abi.encodePacked(
            baseURI,
            Strings.toString(tokenId),
            "?",
            "dynamic=", encodedDynamicTraits,
            "&genesis=", encodedGenesisTraits,
            "&locked=", nft.evolutionLocked ? "true" : "false",
            "&evolutionWindowEnd=", Strings.toString(nft.evolutionWindowEndBlock)
        ));
    }

    /**
     * @dev Internal helper to encode a uint256 array into a string for URI parameters.
     *      Highly simplified for example. A real implementation might use more efficient base64 or custom encoding.
     */
    function _encodeUintArray(uint256[] memory arr) internal pure returns (string memory) {
        bytes memory encoded = abi.encodePacked(arr);
        // This is a very basic representation, in a real DApp, you'd convert this to hex or base64.
        // For demonstration, let's just make a very basic string representation.
        string memory result = "";
        for (uint256 i = 0; i < arr.length; i++) {
            result = string(abi.encodePacked(result, Strings.toString(arr[i]), i == arr.length - 1 ? "" : ","));
        }
        return result;
    }


    // --- IV. Decentralized Governance & Protocol Evolution ---

    /**
     * @dev Allows users with sufficient staked influence to propose direct amendments to the global Weave's core parameters.
     *      Proposals enter a voting period.
     * @param description A descriptive string for the proposal.
     * @param newWeaveParams The proposed new values for `globalWeaveParameters`. Must be WEAVE_PARAMETER_COUNT long.
     */
    function proposeGlobalWeaveAmendment(string calldata description, uint256[] calldata newWeaveParams)
        external
        onlyWeaveParamSubmitter(newWeaveParams)
    {
        require(stakedInfluence[msg.sender] >= minStakedInfluenceForProposal, "NexusWeaver: Not enough staked influence to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            description: description,
            creationBlock: uint224(block.number),
            startBlock: uint224(block.number),
            endBlock: uint224(block.number + votingPeriodBlocks),
            proposedWeaveParams: newWeaveParams,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty
        });

        emit ProposalCreated(proposalId, msg.sender, description, block.number);
    }

    /**
     * @dev Allows reputation and influence holders to vote on active proposals.
     *      Votes are weighted by the user's total influence (_calculateUserInfluence).
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationBlock != 0, "NexusWeaver: Proposal does not exist");
        require(block.number >= proposal.startBlock, "NexusWeaver: Voting has not started");
        require(block.number <= proposal.endBlock, "NexusWeaver: Voting period has ended");
        require(!proposal.executed, "NexusWeaver: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "NexusWeaver: User has already voted on this proposal");

        uint224 currentInfluence = uint224(_calculateUserInfluence(msg.sender));
        require(currentInfluence > 0, "NexusWeaver: User has no influence to vote");

        if (support) {
            proposal.forVotes += currentInfluence;
        } else {
            proposal.againstVotes += currentInfluence;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal that has passed its voting period, met quorum, and passed the execution delay.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationBlock != 0, "NexusWeaver: Proposal does not exist");
        require(block.number > proposal.endBlock + proposalExecutionDelayBlocks, "NexusWeaver: Voting period not over or execution delay not passed");
        require(!proposal.executed, "NexusWeaver: Proposal already executed");

        uint256 totalStakedInfluence = nwInfluenceToken.balanceOf(address(this)); // Use total staked influence as denominator for quorum
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;

        // Check quorum: total votes must exceed a percentage of total influence.
        require(totalVotes * 10000 >= totalStakedInfluence * quorumPercentage, "NexusWeaver: Quorum not met");
        require(proposal.forVotes > proposal.againstVotes, "NexusWeaver: Proposal did not pass");

        // Execute the proposed changes
        globalWeaveParameters = proposal.proposedWeaveParams;
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
        emit GlobalWeaveEvolved(globalWeaveParameters, block.number); // Treat as an evolution as well
    }

    /**
     * @dev Admin/DAO function to set the fee for minting a Nexus NFT.
     * @param fee The new minting fee in native currency.
     */
    function setMintFee(uint256 fee) external onlyOwner {
        nexusMintFee = fee;
        emit MintFeeSet(fee);
    }

    /**
     * @dev Admin/DAO function to set the minimum staked influence required to create a governance proposal.
     * @param amount The new minimum staked influence.
     */
    function setMinimumInfluenceForProposal(uint256 amount) external onlyOwner {
        minStakedInfluenceForProposal = amount;
        emit MinimumInfluenceForProposalSet(amount);
    }

    // --- V. Rewards & Configuration ---

    /**
     * @dev Allows the user who successfully calls `evolveGlobalWeave()` to claim a small reward.
     *      (Reward is sent directly within `evolveGlobalWeave`).
     *      This function is a placeholder to mention the reward mechanism explicitly.
     */
    function claimWeaveEvolutionReward() external pure {
        revert("NexusWeaver: Reward for evolution is sent automatically by `evolveGlobalWeave`");
    }

    /**
     * @dev Admin/DAO function to withdraw collected fees (e.g., minting fees) from the contract.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance - weaveEvolutionReward; // Exclude pending evolution rewards
        require(balance > 0, "NexusWeaver: No fees to withdraw");
        (bool success,) = owner().call{value: balance}("");
        require(success, "NexusWeaver: Failed to withdraw fees");
    }

    // --- Internal/Helper Functions ---
    // (Existing ERC721 internal functions are already handled by OpenZeppelin)
}
```