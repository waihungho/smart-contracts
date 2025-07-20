This Solidity smart contract, named `AetherweaveGenesis`, is designed around the concept of decentralized AI-driven generative art with dynamic evolution and fractional ownership. It combines several advanced concepts like ERC721 for unique digital art pieces ("Aetherlooms"), ERC1155 for their fractional shares, an oracle pattern for AI interaction, and a DAO-like governance system.

The core idea is that Aetherlooms are not static NFTs; they can evolve over time based on owner-voted mutations or autonomous triggers, with their history preserved on-chain. Fractional ownership allows multiple users to co-own and influence a single evolving artwork.

---

## AetherweaveGenesis Smart Contract Outline & Function Summary

**I. Core Aetherloom Management & Ownership (ERC721 + Fractional ERC1155)**

1.  **`createAetherloomRequest(string _initialPrompt, string _aestheticTags)`**: Initiates the creation of a new Aetherloom. Users provide a prompt and aesthetic tags, which are then sent to an off-chain AI oracle for generation. Emits an `AetherloomCreationRequested` event.
2.  **`finalizeAetherloomCreation(uint256 _requestId, string _ipfsHash, uint256 _totalShares, address _creator)`**: Callable by the designated oracle. After the off-chain AI generates the artwork, this function finalizes the creation by minting the ERC721 token for the Aetherloom and distributing ERC1155 fractional shares (e.g., to the creator). It sets the initial metadata URI and total shares.
3.  **`buyAetherloomFractions(uint256 _loomId, uint256 _amount)`**: Allows users to purchase fractional shares of an Aetherloom. Requires `msg.value` to match the cost based on the current share price. For simplicity in this example, it assumes buying from the creator's initial allocation.
4.  **`sellAetherloomFractions(uint256 _loomId, uint256 _amount)`**: Allows fractional owners to "return" or "divest" their shares. For simplicity, these shares are transferred back to the original creator's pool (not an ETH payout from the contract, simulating a reduction in circulating supply).
5.  **`setFractionSalePrice(uint256 _loomId, uint256 _newPrice)`**: Allows the creator of an Aetherloom to set or update the base price for its fractional shares.
6.  **`requestFullRedemption(uint256 _loomId)`**: Allows a user to initiate a buyout process. The caller deposits enough ETH to cover the current market value of all outstanding fractional shares, indicating intent to acquire the full ERC721 NFT.
7.  **`fulfillFullRedemption(uint256 _loomId)`**: Callable by a user who holds all fractional shares of a given Aetherloom. This function burns their fractional shares and transfers the full ERC721 NFT to them, completing the redemption.

**II. Dynamic Evolution & Mutation Engine**

8.  **`proposeLoomMutation(uint256 _loomId, string _mutationPrompt, uint256 _intensityWeight)`**: Allows fractional owners to propose a new mutation for an Aetherloom, potentially altering its visual properties based on a new AI prompt and intensity. Requires a small ETH fee.
9.  **`voteForLoomMutation(uint256 _loomId, uint256 _mutationProposalId)`**: Allows fractional owners to cast their votes on proposed mutations. Voting power is weighted by the number of shares held for that Aetherloom.
10. **`finalizeLoomMutation(uint256 _loomId, uint256 _mutationProposalId, string _newIpfsHash)`**: Callable by the oracle. If a mutation proposal passes its vote, this function finalizes it by updating the Aetherloom's ERC721 metadata URI to the new IPFS hash and increments its version history.
11. **`initiateAutonomousEvolution(uint256 _loomId, uint256 _evolutionTriggerId)`**: Allows anyone to trigger an autonomous evolution if predefined on-chain conditions are met (e.g., elapsed time since last evolution). Pays a small reward to the triggerer.
12. **`recordAutonomousEvolution(uint256 _loomId, uint256 _evolutionTriggerId, string _newIpfsHash)`**: Callable by the oracle. Records the outcome of an autonomous evolution, updating the Aetherloom's metadata and history.
13. **`setUpAutonomousEvolutionTrigger(uint256 _loomId, string _triggerType, uint256 _triggerThreshold, uint256 _triggerReward)`**: Allows the contract owner (or governance) to define parameters for new autonomous evolution triggers for specific Aetherlooms.

**III. AI Integration & Oracle Management**

14. **`setOracleAddress(address _newOracle)`**: Sets the address of the trusted oracle. This is a critical administrative function, typically controlled by governance in a production system.
15. **`_requestAIGeneration(uint256 _requestId, string _prompt, bytes _parameters)`**: (Internal helper function) Simulates an interaction with an off-chain AI oracle for initial art generation.
16. **`_requestAIMutation(uint256 _requestId, string _prompt, bytes _parameters)`**: (Internal helper function) Simulates an interaction with an off-chain AI oracle for art mutation requests.

**IV. Governance & DAO Features (Global governance uses a separate token)**

17. **`submitGovernanceProposal(bytes _callData, string _description)`**: Allows `governanceToken` holders (a hypothetical separate ERC20 token) to propose global changes to the contract's parameters or functions.
18. **`voteOnGovernanceProposal(uint256 _proposalId, bool _support)`**: Allows `governanceToken` holders to vote on active governance proposals.
19. **`executeGovernanceProposal(uint256 _proposalId)`**: Executes a governance proposal that has successfully passed its voting period and met quorum requirements.

**V. Financials & Royalties**

20. **`setCreatorRoyaltyRate(uint256 _loomId, uint256 _newRateBasisPoints)`**: Allows the original creator of an Aetherloom to set a royalty rate (in basis points) that will be applied to future secondary sales of its fractions.
21. **`claimRoyalties()`**: Allows creators to claim accumulated royalties from the sales of their Aetherloom fractions.
22. **`claimPlatformFees()`**: Allows the platform treasury to sweep any remaining ETH in the contract not explicitly held for other purposes (e.g., redemption deposits), representing platform fees or excess funds.

**VI. Advanced Concepts**

23. **`stakeForInfluence(uint256 _loomId, uint256 _amount)`**: Allows users to stake ETH or another designated collateral token to gain weighted influence when voting on a specific Aetherloom's mutation proposals.
24. **`unstakeInfluence(uint256 _loomId, uint256 _amount)`**: Allows users to withdraw their previously staked influence, returning their collateral.
25. **`challengeAetherloomIntegrity(uint256 _loomId, string _reason)`**: Allows users to challenge the integrity, appropriateness, or legitimacy of an Aetherloom's content. Requires a security deposit.
26. **`resolveChallenge(uint256 _challengeId, bool _isValid)`**: Callable by the oracle/DAO. Resolves an integrity challenge, determining if it's valid. If valid, the challenger's stake is returned; if invalid, the stake is forfeited to the treasury.
27. **`getLoomEvolutionHistory(uint256 _loomId, uint256 _version)`**: A view function to retrieve the IPFS hash for any historical version of an Aetherloom, allowing users to trace its complete evolution.
28. **`emergencyPause()`**: Inherited from `Pausable`, allows the owner (or multi-sig) to pause critical contract functionalities in case of an emergency or exploit, providing a safety mechanism.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AetherweaveGenesis
 * @dev A decentralized platform for AI-driven generative art pieces ("Aetherlooms")
 *      that are created, fractionalized, owned, and dynamically evolve.
 *      Combines ERC721 for the whole art piece, ERC1155 for fractional ownership,
 *      on-chain dynamic evolution logic, oracle integration for AI interaction,
 *      and a DAO-like governance system.
 *
 * This contract showcases advanced concepts like:
 * - Hybrid ERC721 (whole art) and ERC1155 (fractional shares) ownership.
 * - Dynamic NFT evolution/mutation based on on-chain voting and triggers.
 * - Integration points for off-chain AI generation via oracle pattern.
 * - Decentralized governance for contract parameters.
 * - Staking for influence on art evolution.
 * - Integrity challenging mechanism for content curation.
 * - Comprehensive history tracking of evolving art.
 */
contract AetherweaveGenesis is ERC721Enumerable, ERC721URIStorage, ERC1155, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _loomIds; // Counter for unique Aetherloom NFTs
    Counters.Counter private _creationRequestIds; // Counter for AI creation requests
    Counters.Counter private _mutationProposalIds; // Counter for loom mutation proposals
    Counters.Counter private _autonomousEvolutionTriggerIds; // Counter for autonomous evolution setups
    Counters.Counter private _governanceProposalIds; // Counter for global governance proposals
    Counters.Counter private _challengeIds; // Counter for integrity challenges

    address public oracleAddress; // Address of the trusted oracle for AI interactions
    address public platformTreasury; // Address where platform fees are sent
    address public governanceToken; // Address of a hypothetical ERC20 governance token
    uint256 public constant MAX_CREATOR_ROYALTY_BPS = 1000; // Max 10% (1000 basis points) for creator royalties
    uint256 public platformFeeBPS = 200; // 2% (200 basis points) platform fee on fractional sales

    // --- Structs ---

    // Aetherloom details (ERC721 token's on-chain data)
    struct Aetherloom {
        uint256 id;
        string initialPrompt; // Original prompt given to AI
        string aestheticTags; // Initial aesthetic keywords
        address creator; // Original creator of the Aetherloom
        uint256 creationTime; // Timestamp of creation
        uint256[] evolutionHistoryIndices; // Indices into `allIpfsHashes` tracking evolution history
        uint256 currentVersion; // Tracks how many times the loom has evolved
        uint256 totalShares; // Total supply of ERC1155 fractions for this loom
        uint256 currentFractionPrice; // Current selling price per ERC1155 share in wei
        uint256 creatorRoyaltyBPS; // Royalty rate (basis points) for creator on secondary fractional sales
        mapping(address => uint256) fractionalBalances; // ERC1155 balances for this specific loom (mirror of ERC1155 storage)
        uint256 totalRoyaltiesAccrued; // Royalties accumulated for this loom's creator
    }

    // AI creation request details
    struct CreationRequest {
        bool exists;
        string initialPrompt;
        string aestheticTags;
        address requester; // Address that initiated the request
        bool fulfilled; // True if the AI generation and minting is complete
    }

    // Loom mutation proposal details
    struct LoomMutationProposal {
        bool exists;
        uint256 loomId;
        string mutationPrompt; // New prompt for AI mutation
        uint256 intensityWeight; // How strongly AI should apply this mutation (e.g., 1-100)
        address proposer; // Address that proposed the mutation
        uint256 totalVotes; // Sum of fractional shares voted for this proposal
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool passed; // True if the proposal met voting threshold
        bool finalized; // True if the mutation has been applied by oracle
        uint256 proposalFee; // Fee paid to propose
        uint256 creationTime; // Timestamp when proposal was created, for voting period
    }

    // Autonomous Evolution Trigger configuration
    struct AutonomousEvolutionTrigger {
        bool exists;
        uint256 loomId;
        string triggerType; // e.g., "Time", "InteractionCount", "Sentiment"
        uint256 triggerThreshold; // e.g., timestamp, vote count, accumulated fees
        bool triggered; // True if trigger conditions met and initiated
        bool finalized; // True if autonomous evolution has been applied by oracle
        uint256 triggerReward; // Reward for the address that successfully initiates the trigger
    }

    // Global Governance Proposal details
    struct GovernanceProposal {
        bool exists;
        string description; // Description of the proposed change
        bytes callData; // Encoded function call for the target contract (often `address(this)`)
        uint256 startBlock; // Block number when voting starts
        uint256 endBlock; // Block number when voting ends
        uint256 votesFor; // Total votes in favor
        uint256 votesAgainst; // Total votes against
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed; // True if the proposal has been executed
        bool passed; // True if the proposal passed the voting
    }

    // Integrity Challenge details
    struct IntegrityChallenge {
        bool exists;
        uint256 loomId;
        address challenger; // Address that submitted the challenge
        string reason; // Reason for challenging the Aetherloom's integrity
        uint256 stakeAmount; // ETH staked by the challenger
        bool resolved; // True if the challenge has been resolved
        bool isValid; // True if the challenge was upheld, false if dismissed
    }

    // --- Mappings & Arrays ---

    mapping(uint256 => Aetherloom) public aetherlooms; // Maps Aetherloom ID to its details
    mapping(uint256 => CreationRequest) public creationRequests; // Maps request ID to creation request details
    mapping(uint256 => LoomMutationProposal) public loomMutationProposals; // Maps proposal ID to mutation proposal details
    mapping(uint256 => AutonomousEvolutionTrigger) public autonomousEvolutionTriggers; // Maps trigger ID to auto-evolution details
    mapping(uint256 => GovernanceProposal) public governanceProposals; // Maps proposal ID to governance proposal details
    mapping(uint256 => IntegrityChallenge) public integrityChallenges; // Maps challenge ID to integrity challenge details
    mapping(uint256 => mapping(address => uint256)) public influenceStakes; // loomId => staker => staked ETH amount

    string[] private allIpfsHashes; // Global array to store all unique IPFS hashes, referenced by index

    // --- Events ---

    event AetherloomCreationRequested(uint256 indexed requestId, address indexed requester, string initialPrompt, string aestheticTags);
    event AetherloomCreated(uint256 indexed loomId, address indexed creator, string ipfsHash, uint256 totalShares);
    event FractionsPurchased(uint256 indexed loomId, address indexed buyer, uint256 amount, uint256 ethPaid);
    event FractionsSold(uint256 indexed loomId, address indexed seller, uint256 amount); // No ETH paid by contract
    event FractionPriceSet(uint256 indexed loomId, uint256 newPrice);
    event FullRedemptionRequested(uint256 indexed loomId, address indexed redeemer, uint256 depositAmount);
    event FullRedemptionFulfilled(uint256 indexed loomId, address indexed redeemer);

    event LoomMutationProposed(uint256 indexed loomId, uint256 indexed proposalId, address indexed proposer, string mutationPrompt, uint256 intensityWeight);
    event LoomMutationVoted(uint256 indexed loomId, uint256 indexed proposalId, address indexed voter, uint256 voteWeight);
    event LoomMutationFinalized(uint256 indexed loomId, uint256 indexed proposalId, string newIpfsHash, uint256 newVersion);
    event AutonomousEvolutionInitiated(uint256 indexed loomId, uint256 indexed triggerId, string triggerType);
    event AutonomousEvolutionRecorded(uint256 indexed loomId, uint256 indexed triggerId, string newIpfsHash, uint256 newVersion);
    event AutonomousEvolutionTriggerSetup(uint256 indexed triggerId, uint256 indexed loomId, string triggerType, uint256 triggerThreshold);

    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    event CreatorRoyaltyRateSet(uint256 indexed loomId, uint256 newRateBasisPoints);
    event RoyaltiesClaimed(address indexed creator, uint256 amount);
    event PlatformFeesClaimed(address indexed treasury, uint256 amount);

    event InfluenceStaked(uint256 indexed loomId, address indexed staker, uint256 amount);
    event InfluenceUnstaked(uint256 indexed loomId, address indexed staker, uint256 amount);
    event AetherloomIntegrityChallenged(uint256 indexed challengeId, uint256 indexed loomId, address indexed challenger, string reason, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, bool isValid);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetherweaveGenesis: Only the designated oracle can call this function.");
        _;
    }

    modifier onlyLoomCreator(uint256 _loomId) {
        require(aetherlooms[_loomId].creator == msg.sender, "AetherweaveGenesis: Only the loom creator can perform this action.");
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Governance: Proposal voting is not active.");
        _;
    }

    modifier loomMutationVotingActive(uint256 _loomId, uint256 _proposalId) {
        LoomMutationProposal storage proposal = loomMutationProposals[_proposalId];
        // Example: 7-day voting window
        require(block.timestamp <= proposal.creationTime + 7 days, "Mutation: Voting period for this proposal has ended.");
        _;
    }

    // --- Constructor ---

    constructor(address _oracleAddress, address _platformTreasury, address _governanceToken)
        ERC721("AetherweaveGenesis", "AETHERLOOM")
        ERC1155("https://aetherweave.xyz/loom/") // Base URI for ERC1155 fractional shares
        Ownable(msg.sender) // Owner is initially the deployer
    {
        require(_oracleAddress != address(0), "Oracle address cannot be zero.");
        require(_platformTreasury != address(0), "Platform treasury address cannot be zero.");
        require(_governanceToken != address(0), "Governance token address cannot be zero.");

        oracleAddress = _oracleAddress;
        platformTreasury = _platformTreasury;
        governanceToken = _governanceToken;
    }

    // --- ERC1155 Required Overrides ---
    function uri(uint256 _id) public view override returns (string memory) {
        // The ERC1155 URI typically points to metadata for the *type* of token (the loom)
        // rather than a specific fraction.
        // The `_id` here refers to the `loomId`.
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC721Enumerable, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- I. Core Aetherloom Management & Ownership ---

    /**
     * @dev 1. Initiates the creation of a new Aetherloom.
     *      Sends a request to the off-chain AI oracle.
     * @param _initialPrompt User's text prompt for the AI.
     * @param _aestheticTags Keywords or styles to guide the AI's aesthetic.
     */
    function createAetherloomRequest(string calldata _initialPrompt, string calldata _aestheticTags)
        external
        whenNotPaused
        nonReentrant
    {
        _creationRequestIds.increment();
        uint256 requestId = _creationRequestIds.current();

        creationRequests[requestId] = CreationRequest({
            exists: true,
            initialPrompt: _initialPrompt,
            aestheticTags: _aestheticTags,
            requester: msg.sender,
            fulfilled: false
        });

        // Simulate sending a request to the oracle for AI generation.
        // In a real dApp, this would trigger an off-chain oracle service (e.g., Chainlink External Adapters).
        _requestAIGeneration(requestId, _initialPrompt, abi.encodePacked(_aestheticTags));

        emit AetherloomCreationRequested(requestId, msg.sender, _initialPrompt, _aestheticTags);
    }

    /**
     * @dev 2. Callable by Oracle. Finalizes Aetherloom creation after AI generation.
     *      Mints the ERC721 token and associated ERC1155 fractional shares.
     * @param _requestId The ID of the initial creation request.
     * @param _ipfsHash IPFS hash of the generated artwork metadata.
     * @param _totalShares Total number of fractional shares to mint.
     * @param _creator Address of the original requester (creator).
     */
    function finalizeAetherloomCreation(
        uint256 _requestId,
        string calldata _ipfsHash,
        uint256 _totalShares,
        address _creator
    )
        external
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        CreationRequest storage request = creationRequests[_requestId];
        require(request.exists, "AetherweaveGenesis: Request does not exist.");
        require(!request.fulfilled, "AetherweaveGenesis: Request already fulfilled.");
        require(_totalShares > 0, "AetherweaveGenesis: Total shares must be greater than 0.");
        require(_creator == request.requester, "AetherweaveGenesis: Creator must match requester.");

        _loomIds.increment();
        uint256 loomId = _loomIds.current();

        // Store IPFS hash in global array and get its index
        uint256 ipfsIndex = allIpfsHashes.length;
        allIpfsHashes.push(_ipfsHash);

        aetherlooms[loomId] = Aetherloom({
            id: loomId,
            initialPrompt: request.initialPrompt,
            aestheticTags: request.aestheticTags,
            creator: _creator,
            creationTime: block.timestamp,
            evolutionHistoryIndices: new uint256[](0), // Initialize empty
            currentVersion: 0,
            totalShares: _totalShares,
            currentFractionPrice: 0, // Price needs to be set separately by creator or initial listing
            creatorRoyaltyBPS: 0,
            totalRoyaltiesAccrued: 0
        });

        // Add the initial IPFS hash to the loom's evolution history
        aetherlooms[loomId].evolutionHistoryIndices.push(ipfsIndex);

        // Mint the ERC721 token, owned by the contract initially to manage fractional ownership
        _safeMint(address(this), loomId);
        _setTokenURI(loomId, _ipfsHash); // URI for the full NFT's metadata

        // Mint ERC1155 fractional shares to the creator
        _mint(_creator, loomId, _totalShares, ""); // `_id` in ERC1155 is the loomId
        aetherlooms[loomId].fractionalBalances[_creator] = _totalShares; // Update internal balance tracking

        request.fulfilled = true; // Mark request as fulfilled

        emit AetherloomCreated(loomId, _creator, _ipfsHash, _totalShares);
    }

    /**
     * @dev 3. Allows users to purchase fractional shares of an Aetherloom.
     *      Assumes buying from the creator's initial allocated shares held within the contract.
     * @param _loomId The ID of the Aetherloom.
     * @param _amount The number of shares to purchase.
     */
    function buyAetherloomFractions(uint256 _loomId, uint256 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(loom.currentFractionPrice > 0, "AetherweaveGenesis: Price not set for fractions.");
        require(_amount > 0, "AetherweaveGenesis: Amount must be greater than 0.");
        require(loom.fractionalBalances[loom.creator] >= _amount, "AetherweaveGenesis: Not enough shares available from creator.");

        uint256 totalCost = loom.currentFractionPrice.mul(_amount);
        require(msg.value >= totalCost, "AetherweaveGenesis: Insufficient ETH sent.");

        uint256 platformFee = totalCost.mul(platformFeeBPS).div(10000);
        uint256 netToCreator = totalCost.sub(platformFee);

        // Transfer ETH for fees and to creator
        payable(platformTreasury).transfer(platformFee);
        payable(loom.creator).transfer(netToCreator);

        // Transfer ERC1155 shares from creator to buyer
        _transferSingle(loom.creator, msg.sender, _loomId, _amount);
        loom.fractionalBalances[loom.creator] = loom.fractionalBalances[loom.creator].sub(_amount);
        loom.fractionalBalances[msg.sender] = loom.fractionalBalances[msg.sender].add(_amount);

        // Refund any excess ETH
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value.sub(totalCost));
        }

        emit FractionsPurchased(_loomId, msg.sender, _amount, totalCost);
    }

    /**
     * @dev 4. Allows fractional owners to divest their shares by returning them to the creator.
     *      This function does NOT involve an ETH payout from the contract. It's for divesting.
     * @param _loomId The ID of the Aetherloom.
     * @param _amount The number of shares to return.
     */
    function sellAetherloomFractions(uint256 _loomId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(_amount > 0, "AetherweaveGenesis: Amount must be greater than 0.");
        require(loom.fractionalBalances[msg.sender] >= _amount, "AetherweaveGenesis: Insufficient shares to return.");

        // Transfer ERC1155 shares back to the creator
        _transferSingle(msg.sender, loom.creator, _loomId, _amount);
        loom.fractionalBalances[msg.sender] = loom.fractionalBalances[msg.sender].sub(_amount);
        loom.fractionalBalances[loom.creator] = loom.fractionalBalances[loom.creator].add(_amount);

        emit FractionsSold(_loomId, msg.sender, _amount);
    }

    /**
     * @dev 5. Allows the creator to set the current sale price per share for their Aetherloom.
     * @param _loomId The ID of the Aetherloom.
     * @param _newPrice The new price per fractional share in wei.
     */
    function setFractionSalePrice(uint256 _loomId, uint256 _newPrice)
        external
        onlyLoomCreator(_loomId)
        whenNotPaused
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        // Allow 0 to indicate no active sale price
        loom.currentFractionPrice = _newPrice;
        emit FractionPriceSet(_loomId, _newPrice);
    }

    /**
     * @dev 6. Allows a user to initiate a buyout process to acquire all fractional shares
     *      and ultimately receive the full ERC721 NFT. Requires a deposit.
     *      The deposit amount is proportional to the total outstanding shares at current price.
     *      Funds are held in the contract, and can be claimed by fraction holders later.
     * @param _loomId The ID of the Aetherloom.
     */
    function requestFullRedemption(uint256 _loomId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        // Ensure the ERC721 is still owned by the contract, not already transferred out
        require(ownerOf(_loomId) == address(this), "AetherweaveGenesis: ERC721 is no longer managed by contract.");

        uint256 totalOutstandingShares = loom.totalShares.sub(loom.fractionalBalances[msg.sender]); // Shares not owned by msg.sender
        uint256 requiredDeposit = totalOutstandingShares.mul(loom.currentFractionPrice);

        require(msg.value >= requiredDeposit, "AetherweaveGenesis: Insufficient ETH deposit for full redemption.");

        // For simplicity, we assume the deposit amount covers what's needed for other fraction holders.
        // Funds are now locked in the contract awaiting `fulfillFullRedemption`.
        // In a more complex system, these funds would be mapped to the redemption request.
        // For now, they sit in the contract balance until paid out or refunded.
        // The contract's balance implicitly acts as the holding escrow.

        emit FullRedemptionRequested(_loomId, msg.sender, msg.value);
    }

    /**
     * @dev 7. Callable by the user who initiated `requestFullRedemption`, once they
     *      have successfully acquired *all* fractional shares (ERC1155) of the Aetherloom.
     *      This transfers the full ERC721 NFT to the redeemer and burns their fractional shares.
     * @param _loomId The ID of the Aetherloom.
     */
    function fulfillFullRedemption(uint256 _loomId)
        external
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(ownerOf(_loomId) == address(this), "AetherweaveGenesis: ERC721 is not managed by this contract.");

        // Ensure the caller (redeemer) now holds ALL fractional shares for this loom.
        require(aetherlooms[_loomId].fractionalBalances[msg.sender] == loom.totalShares, "AetherweaveGenesis: Redeemer must own all fractional shares.");

        // Transfer the full ERC721 NFT to the redeemer
        _transfer(address(this), msg.sender, _loomId);

        // Burn all fractional shares held by the redeemer (they no longer need them)
        _burn(msg.sender, _loomId, loom.totalShares);
        loom.fractionalBalances[msg.sender] = 0; // Clear internal balance tracking

        // At this point, any ETH deposited in `requestFullRedemption` would be handled.
        // In this simplified model, that ETH would be manually distributed or claimed by past fraction holders.
        // A more robust system would track individual outstanding claims from the redemption deposit.

        emit FullRedemptionFulfilled(_loomId, msg.sender);
    }

    // --- II. Dynamic Evolution & Mutation Engine ---

    /**
     * @dev 8. Allows fractional owners to propose a new mutation for an Aetherloom.
     *      Requires a small ETH fee to prevent spamming proposals.
     * @param _loomId The ID of the Aetherloom.
     * @param _mutationPrompt A text prompt for the AI to guide the mutation.
     * @param _intensityWeight How strongly the AI should apply the mutation (e.g., 1-100).
     */
    function proposeLoomMutation(
        uint256 _loomId,
        string calldata _mutationPrompt,
        uint256 _intensityWeight
    )
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(aetherlooms[_loomId].fractionalBalances[msg.sender] > 0, "AetherweaveGenesis: Must own fractions to propose.");
        require(msg.value >= 0.01 ether, "AetherweaveGenesis: Requires 0.01 ETH proposal fee."); // Example fee

        _mutationProposalIds.increment();
        uint256 proposalId = _mutationProposalIds.current();

        loomMutationProposals[proposalId] = LoomMutationProposal({
            exists: true,
            loomId: _loomId,
            mutationPrompt: _mutationPrompt,
            intensityWeight: _intensityWeight,
            proposer: msg.sender,
            totalVotes: aetherlooms[_loomId].fractionalBalances[msg.sender], // Proposer's votes count immediately
            hasVoted: new mapping(address => bool)(), // Initialize mapping for voters
            passed: false,
            finalized: false,
            proposalFee: msg.value,
            creationTime: block.timestamp // Use timestamp for voting period
        });
        loomMutationProposals[proposalId].hasVoted[msg.sender] = true;

        // Transfer proposal fee to treasury
        payable(platformTreasury).transfer(msg.value);

        // Simulate request to oracle for AI mutation preview or calculation
        _requestAIMutation(proposalId, _mutationPrompt, abi.encodePacked(_loomId, _intensityWeight));

        emit LoomMutationProposed(_loomId, proposalId, msg.sender, _mutationPrompt, _intensityWeight);
    }

    /**
     * @dev 9. Allows fractional owners to vote on proposed mutations.
     *      Voting power is weighted by the number of shares held.
     * @param _loomId The ID of the Aetherloom.
     * @param _mutationProposalId The ID of the mutation proposal.
     */
    function voteForLoomMutation(uint256 _loomId, uint256 _mutationProposalId)
        external
        whenNotPaused
    {
        LoomMutationProposal storage proposal = loomMutationProposals[_mutationProposalId];
        require(proposal.exists, "AetherweaveGenesis: Proposal does not exist.");
        require(proposal.loomId == _loomId, "AetherweaveGenesis: Proposal ID mismatch for loom.");
        require(aetherlooms[_loomId].fractionalBalances[msg.sender] > 0, "AetherweaveGenesis: Must own fractions to vote.");
        require(!proposal.hasVoted[msg.sender], "AetherweaveGenesis: Already voted on this proposal.");
        require(!proposal.finalized, "AetherweaveGenesis: Proposal already finalized.");
        loomMutationVotingActive(_loomId, _mutationProposalId); // Check voting window

        uint256 voteWeight = aetherlooms[_loomId].fractionalBalances[msg.sender];
        proposal.totalVotes = proposal.totalVotes.add(voteWeight);
        proposal.hasVoted[msg.sender] = true;

        // Check if mutation passes (e.g., >50% of total shares voted yes)
        if (proposal.totalVotes >= aetherlooms[_loomId].totalShares.div(2)) { // Simple majority of total shares
            proposal.passed = true;
        }

        emit LoomMutationVoted(_loomId, _mutationProposalId, msg.sender, voteWeight);
    }

    /**
     * @dev 10. Callable by Oracle. Finalizes a mutation if it passed the voting threshold.
     *      Updates the Aetherloom's metadata (IPFS hash) and version.
     * @param _loomId The ID of the Aetherloom.
     * @param _mutationProposalId The ID of the mutation proposal.
     * @param _newIpfsHash The new IPFS hash for the mutated artwork metadata.
     */
    function finalizeLoomMutation(
        uint256 _loomId,
        uint256 _mutationProposalId,
        string calldata _newIpfsHash
    )
        external
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        LoomMutationProposal storage proposal = loomMutationProposals[_mutationProposalId];
        Aetherloom storage loom = aetherlooms[_loomId];
        require(proposal.exists, "AetherweaveGenesis: Proposal does not exist.");
        require(proposal.loomId == _loomId, "AetherweaveGenesis: Proposal ID mismatch for loom.");
        require(proposal.passed, "AetherweaveGenesis: Mutation proposal did not pass.");
        require(!proposal.finalized, "AetherweaveGenesis: Proposal already finalized.");
        // Ensure voting period has ended before finalization to prevent race conditions
        require(block.timestamp > proposal.creationTime + 7 days, "Mutation: Voting period not ended.");

        // Store new IPFS hash in global array and get its index
        uint256 newIpfsIndex = allIpfsHashes.length;
        allIpfsHashes.push(_newIpfsHash);

        loom.evolutionHistoryIndices.push(newIpfsIndex); // Add to history
        loom.currentVersion = loom.currentVersion.add(1); // Increment version
        _setTokenURI(_loomId, _newIpfsHash); // Update ERC721 metadata URI for current state

        proposal.finalized = true;

        emit LoomMutationFinalized(_loomId, _mutationProposalId, _newIpfsHash, loom.currentVersion);
    }

    /**
     * @dev 11. Allows anyone to trigger an autonomous evolution if certain on-chain conditions are met.
     *      (e.g., elapsed time since last evolution, cumulative fees, etc.).
     *      Pays a small reward to the triggerer.
     * @param _loomId The ID of the Aetherloom.
     * @param _evolutionTriggerId The ID of the predefined autonomous evolution trigger.
     */
    function initiateAutonomousEvolution(uint256 _loomId, uint256 _evolutionTriggerId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        AutonomousEvolutionTrigger storage trigger = autonomousEvolutionTriggers[_evolutionTriggerId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(trigger.exists, "AetherweaveGenesis: Autonomous trigger does not exist.");
        require(trigger.loomId == _loomId, "AetherweaveGenesis: Trigger ID mismatch for loom.");
        require(!trigger.triggered, "AetherweaveGenesis: Autonomous evolution already triggered.");

        // Example trigger condition: time-based (e.g., 30 days since last evolution per version)
        require(block.timestamp >= loom.creationTime + (trigger.triggerThreshold * loom.currentVersion), "AetherweaveGenesis: Autonomous evolution conditions not met yet.");
        // `trigger.triggerThreshold` could represent days, or accumulated interaction count etc.

        trigger.triggered = true;

        // Pay a small reward to the caller for initiating
        uint256 reward = trigger.triggerReward; // Use predefined reward from trigger setup
        require(address(this).balance >= reward, "AetherweaveGenesis: Insufficient contract balance for reward.");
        payable(msg.sender).transfer(reward);

        // Simulate request to oracle for AI to generate next autonomous state
        _requestAIMutation(_evolutionTriggerId, "Autonomous Evolution", abi.encodePacked(_loomId, "auto"));

        emit AutonomousEvolutionInitiated(_loomId, _evolutionTriggerId, trigger.triggerType);
    }

    /**
     * @dev 12. Callable by Oracle. Records the outcome of an autonomous evolution.
     *      Updates the Aetherloom's metadata (IPFS hash) and version.
     * @param _loomId The ID of the Aetherloom.
     * @param _evolutionTriggerId The ID of the autonomous evolution trigger.
     * @param _newIpfsHash The new IPFS hash for the autonomously evolved artwork metadata.
     */
    function recordAutonomousEvolution(
        uint256 _loomId,
        uint256 _evolutionTriggerId,
        string calldata _newIpfsHash
    )
        external
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        AutonomousEvolutionTrigger storage trigger = autonomousEvolutionTriggers[_evolutionTriggerId];
        Aetherloom storage loom = aetherlooms[_loomId];
        require(trigger.exists, "AetherweaveGenesis: Autonomous trigger does not exist.");
        require(trigger.loomId == _loomId, "AetherweaveGenesis: Trigger ID mismatch for loom.");
        require(trigger.triggered, "AetherweaveGenesis: Autonomous evolution not triggered yet.");
        require(!trigger.finalized, "AetherweaveGenesis: Autonomous evolution already finalized.");

        // Store new IPFS hash in global array and get its index
        uint256 newIpfsIndex = allIpfsHashes.length;
        allIpfsHashes.push(_newIpfsHash);

        loom.evolutionHistoryIndices.push(newIpfsIndex);
        loom.currentVersion = loom.currentVersion.add(1);
        _setTokenURI(_loomId, _newIpfsHash); // Update ERC721 metadata URI

        trigger.finalized = true;

        emit AutonomousEvolutionRecorded(_loomId, _evolutionTriggerId, _newIpfsHash, loom.currentVersion);
    }

    /**
     * @dev 13. Allows the contract owner (or governance) to define parameters for new autonomous evolution triggers.
     * @param _loomId The ID of the Aetherloom to configure.
     * @param _triggerType A string describing the type of trigger (e.g., "TimeElapsed", "InteractionsCount").
     * @param _triggerThreshold The numerical threshold for the trigger (e.g., number of days, or interactions).
     * @param _triggerReward The ETH reward for the address successfully initiating this trigger.
     */
    function setUpAutonomousEvolutionTrigger(
        uint256 _loomId,
        string calldata _triggerType,
        uint256 _triggerThreshold,
        uint256 _triggerReward
    )
        external
        onlyOwner // For simplicity, only owner. In production, this would be via governance.
        whenNotPaused
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        _autonomousEvolutionTriggerIds.increment();
        uint256 triggerId = _autonomousEvolutionTriggerIds.current();
        autonomousEvolutionTriggers[triggerId] = AutonomousEvolutionTrigger({
            exists: true,
            loomId: _loomId,
            triggerType: _triggerType,
            triggerThreshold: _triggerThreshold,
            triggered: false,
            finalized: false,
            triggerReward: _triggerReward
        });
        emit AutonomousEvolutionTriggerSetup(triggerId, _loomId, _triggerType, _triggerThreshold);
    }

    // --- III. AI Integration & Oracle Management ---

    /**
     * @dev 14. Sets the address of the trusted oracle. Only callable by contract owner (or governance).
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetherweaveGenesis: Oracle address cannot be zero.");
        emit OracleAddressSet(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @dev 15. Internal function to simulate requesting AI generation from the oracle.
     *      In a real system, this would involve a Chainlink VRF, custom oracle network, or off-chain API calls.
     * @param _requestId The ID of the request (creation or mutation proposal ID).
     * @param _prompt The text prompt for the AI.
     * @param _parameters Additional encoded parameters for the AI.
     */
    function _requestAIGeneration(uint256 _requestId, string memory _prompt, bytes memory _parameters) internal view {
        // This is a placeholder for actual oracle interaction.
        // Example: `IOracle(oracleAddress).requestGeneration(_requestId, _prompt, _parameters);`
        // For this example, we just simulate the intent.
        // A production system would implement robust request-response patterns with the oracle.
    }

    /**
     * @dev 16. Internal function to simulate requesting AI mutation from the oracle.
     * @param _requestId The ID of the request (mutation proposal ID or autonomous trigger ID).
     * @param _prompt The text prompt for the AI.
     * @param _parameters Additional encoded parameters for the AI.
     */
    function _requestAIMutation(uint252 _requestId, string memory _prompt, bytes memory _parameters) internal view {
        // Placeholder for AI mutation request.
        // Similar to `_requestAIGeneration`.
    }

    // --- IV. Governance & DAO Features (Global governance uses a separate token) ---

    /**
     * @dev 17. Allows any `governanceToken` holder to propose changes to contract parameters or functions.
     *      (Requires a minimum stake of governance tokens, not implemented for brevity).
     * @param _callData Encoded function call for the target contract (e.g., `setOracleAddress`).
     * @param _description A detailed description of the proposal.
     */
    function submitGovernanceProposal(bytes calldata _callData, string calldata _description)
        external
        whenNotPaused
    {
        // In a real DAO, `require(IERC20(governanceToken).balanceOf(msg.sender) >= MIN_PROPOSAL_STAKE, "Insufficient governance token stake.");`
        // Simplified: anyone can propose for demo.
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();

        // Example: 7 days voting period (approx. blocks, assuming 12-sec block time)
        uint256 votingPeriodBlocks = 7 * 24 * 60 * 60 / 12;

        governanceProposals[proposalId] = GovernanceProposal({
            exists: true,
            description: _description,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false,
            passed: false
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev 18. Allows `governanceToken` holders to vote on proposals.
     *      Voting power is typically based on `governanceToken` balance.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for "yes" (support), false for "no" (against).
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        proposalVotingActive(_proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Governance: Already voted on this proposal.");

        // In a real DAO, voting power from governance token: `uint256 votingPower = IERC20(governanceToken).balanceOf(msg.sender);`
        // For simplicity: 1 vote per unique address for demo.
        uint256 votingPower = 1;
        require(votingPower > 0, "Governance: No voting power.");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev 19. Executes a passed governance proposal.
     *      Requires the voting period to be over and the proposal to have passed the vote.
     *      A timelock might be implemented in a real system for security.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeGovernanceProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.exists, "Governance: Proposal does not exist.");
        require(!proposal.executed, "Governance: Proposal already executed.");
        require(block.number > proposal.endBlock, "Governance: Voting period not ended.");

        // Simple passing condition: more "for" votes than "against".
        // A real DAO would include quorum checks, minimum vote participation, etc.
        proposal.passed = proposal.votesFor > proposal.votesAgainst;
        require(proposal.passed, "Governance: Proposal did not pass.");

        // Execute the proposed call on this contract
        (bool success,) = address(this).call(proposal.callData);
        require(success, "Governance: Proposal execution failed.");

        proposal.executed = true;

        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- V. Financials & Royalties ---

    /**
     * @dev 20. Creator can set a royalty rate for secondary sales of fractions.
     *      Rate is in basis points (10000 BPS = 100%).
     * @param _loomId The ID of the Aetherloom.
     * @param _newRateBasisPoints The new royalty rate in basis points.
     */
    function setCreatorRoyaltyRate(uint256 _loomId, uint256 _newRateBasisPoints)
        external
        onlyLoomCreator(_loomId)
        whenNotPaused
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(_newRateBasisPoints <= MAX_CREATOR_ROYALTY_BPS, "AetherweaveGenesis: Royalty rate exceeds max allowed.");

        loom.creatorRoyaltyBPS = _newRateBasisPoints;
        emit CreatorRoyaltyRateSet(_loomId, _newRateBasisPoints);
    }

    /**
     * @dev 21. Allows creators to claim accumulated royalties from their Aetherlooms.
     *      Royalties are typically accrued from fractional sales (not fully implemented in `buyAetherloomFractions` for simplicity).
     *      For this example, assume `totalRoyaltiesAccrued` is populated by some off-chain mechanism,
     *      or a more complex fee distribution within the contract.
     */
    function claimRoyalties() external nonReentrant {
        uint256 totalClaimable = 0;
        for (uint256 i = 1; i <= _loomIds.current(); i++) {
            Aetherloom storage loom = aetherlooms[i];
            if (loom.creator == msg.sender && loom.totalRoyaltiesAccrued > 0) {
                totalClaimable = totalClaimable.add(loom.totalRoyaltiesAccrued);
                loom.totalRoyaltiesAccrued = 0; // Reset for this loom after adding to claimable
            }
        }
        require(totalClaimable > 0, "AetherweaveGenesis: No royalties to claim.");
        payable(msg.sender).transfer(totalClaimable);
        emit RoyaltiesClaimed(msg.sender, totalClaimable);
    }

    /**
     * @dev 22. Allows the platform treasury/DAO to claim accumulated platform fees
     *      or sweep any excess ETH from the contract's balance not designated for specific uses (like redemption deposits).
     *      In `buyAetherloomFractions`, fees are sent directly to `platformTreasury`.
     *      This function would primarily be for sweeping any ETH that might get stuck or accumulated via other means.
     */
    function claimPlatformFees() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        // In a production system, this would explicitly exclude any funds held for specific liabilities (e.g., redemption deposits).
        // For this example, assuming any ETH here that isn't for immediate redemption is 'fees'.
        require(contractBalance > 0, "AetherweaveGenesis: No funds to claim.");
        payable(platformTreasury).transfer(contractBalance); // Transfers entire contract ETH balance to treasury
        // WARNING: In production, ensure this doesn't transfer user-deposited funds.
        // A dedicated fee tracking variable (`uint256 public accumulatedPlatformFees;`) would be safer.
        emit PlatformFeesClaimed(platformTreasury, contractBalance);
    }

    // --- VI. Advanced Concepts ---

    /**
     * @dev 23. Stake a collateral token (e.g., ETH, as simulated here) to gain weighted influence
     *      in specific Aetherloom's mutation votes or autonomous evolution triggers.
     * @param _loomId The ID of the Aetherloom to stake for.
     * @param _amount The amount of ETH to stake.
     */
    function stakeForInfluence(uint256 _loomId, uint256 _amount)
        external
        payable
        whenNotPaused
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(_amount > 0, "AetherweaveGenesis: Stake amount must be greater than 0.");
        require(msg.value == _amount, "AetherweaveGenesis: Sent ETH must match stake amount.");

        influenceStakes[_loomId][msg.sender] = influenceStakes[_loomId][msg.sender].add(_amount);

        emit InfluenceStaked(_loomId, msg.sender, _amount);
    }

    /**
     * @dev 24. Unstake previously staked influence.
     * @param _loomId The ID of the Aetherloom.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeInfluence(uint256 _loomId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(_amount > 0, "AetherweaveGenesis: Unstake amount must be greater than 0.");
        require(influenceStakes[_loomId][msg.sender] >= _amount, "AetherweaveGenesis: Insufficient staked influence.");

        influenceStakes[_loomId][msg.sender] = influenceStakes[_loomId][msg.sender].sub(_amount);
        payable(msg.sender).transfer(_amount);

        emit InfluenceUnstaked(_loomId, msg.sender, _amount);
    }

    /**
     * @dev 25. Allows users to challenge the integrity or legitimacy of an Aetherloom.
     *      (e.g., if content is inappropriate, violates terms, or duplicates existing art).
     *      Requires a stake which is locked during the challenge.
     * @param _loomId The ID of the Aetherloom.
     * @param _reason A description of the reason for the challenge.
     */
    function challengeAetherloomIntegrity(uint256 _loomId, string calldata _reason)
        external
        payable
        whenNotPaused
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(msg.value >= 0.05 ether, "AetherweaveGenesis: Requires 0.05 ETH challenge stake."); // Example stake

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();

        integrityChallenges[challengeId] = IntegrityChallenge({
            exists: true,
            loomId: _loomId,
            challenger: msg.sender,
            reason: _reason,
            stakeAmount: msg.value,
            resolved: false,
            isValid: false
        });

        emit AetherloomIntegrityChallenged(challengeId, _loomId, msg.sender, _reason, msg.value);
    }

    /**
     * @dev 26. Callable by Oracle/DAO. Resolves an integrity challenge.
     *      If challenge is valid, stake might be returned to challenger, and a penalty could apply.
     *      If invalid, challenger's stake is forfeited (e.g., to treasury).
     * @param _challengeId The ID of the challenge.
     * @param _isValid True if the challenge is upheld (valid), false if dismissed (invalid).
     */
    function resolveChallenge(uint256 _challengeId, bool _isValid)
        external
        onlyOracle // Could also be a governance function
        whenNotPaused
        nonReentrant
    {
        IntegrityChallenge storage challenge = integrityChallenges[_challengeId];
        require(challenge.exists, "AetherweaveGenesis: Challenge does not exist.");
        require(!challenge.resolved, "AetherweaveGenesis: Challenge already resolved.");

        challenge.resolved = true;
        challenge.isValid = _isValid;

        if (_isValid) {
            // Challenge upheld: Return stake to challenger.
            // Further logic could apply penalties to the Aetherloom or its creator (e.g., burn shares, delist).
            payable(challenge.challenger).transfer(challenge.stakeAmount);
        } else {
            // Challenge dismissed: Challenger forfeits stake to platform treasury.
            payable(platformTreasury).transfer(challenge.stakeAmount);
        }

        emit ChallengeResolved(_challengeId, _isValid);
    }

    /**
     * @dev 27. Retrieves the IPFS hash of a specific historical version of an Aetherloom.
     * @param _loomId The ID of the Aetherloom.
     * @param _version The specific version number (0 for initial creation).
     * @return string The IPFS hash for that version.
     */
    function getLoomEvolutionHistory(uint256 _loomId, uint256 _version)
        external
        view
        returns (string memory)
    {
        Aetherloom storage loom = aetherlooms[_loomId];
        require(loom.exists, "AetherweaveGenesis: Loom does not exist.");
        require(_version < loom.evolutionHistoryIndices.length, "AetherweaveGenesis: Version does not exist for this loom.");
        return allIpfsHashes[loom.evolutionHistoryIndices[_version]];
    }

    /**
     * @dev 28. Emergency pause function.
     *      Inherited from Pausable. The `owner()` can call `pause()` or `unpause()`.
     *      This function can pause most state-changing user interactions for safety.
     *      Example usage: `_owner.pause();` or `_owner.unpause();`
     */
    // function emergencyPause() is inherited. No explicit function body needed here.

    // Fallback and Receive functions to prevent accidental ETH transfers
    receive() external payable {
        revert("AetherweaveGenesis: Direct ETH transfers are not allowed. Use specific functions.");
    }
    fallback() external payable {
        revert("AetherweaveGenesis: Direct ETH transfers are not allowed. Use specific functions.");
    }
}
```