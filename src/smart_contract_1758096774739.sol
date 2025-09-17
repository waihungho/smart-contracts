This smart contract, **"Aethergenesis Nexus"**, envisions a decentralized ecosystem where unique, AI-driven digital entities called "Sentinels" can evolve their traits and capabilities. Their evolution is a dynamic process influenced by:

1.  **On-chain actions:** Staking native `EssenceToken` for influence.
2.  **Off-chain data:** Via decentralized oracles (e.g., real-world events, AI model outputs).
3.  **DAO Governance:** Community votes to approve new evolutionary traits, rules, and treasury spending.

The core idea is to create *dynamic NFTs* whose attributes and visual representation can change over time, dictated by a combination of user interaction, external data, and collective governance, creating a living, evolving digital identity or asset.

---

### **Outline and Function Summary**

**I. Core Components & State:**
*   `Sentinel` (ERC-721 Token): Represents the unique evolving entity.
*   `EssenceToken` (ERC-20 Token): The native utility/governance token.
*   `OracleInterface`: For fetching external data.
*   `Trait`: Struct defining an evolutionary characteristic.
*   `EvolutionProposal`: Struct for proposing new traits.
*   `TreasuryProposal`: Struct for proposing treasury spending.
*   `EvolutionChallenge`: Struct for disputing evolutions.

**II. Sentinel NFT Management (ERC-721 Extensions):**
1.  `mintSentinel(string memory _initialTraitSeed)`: Mints a new Sentinel with an initial set of traits based on a seed.
2.  `getSentinelDetails(uint256 _tokenId)`: Retrieves all current details (traits, evolution stage) of a Sentinel.
3.  `tokenURI(uint256 _tokenId)`: Generates dynamic metadata URI based on the Sentinel's current traits.
4.  `setSentinelBaseURI(string memory _newBaseURI)`: Sets the base URI for Sentinel metadata (e.g., IPFS gateway).

**III. Essence Token & Staking (ERC-20 Extensions):**
5.  `stakeEssence(uint256 _amount)`: Allows users to stake `EssenceToken` to gain influence and voting power.
6.  `unstakeEssence(uint256 _amount)`: Allows users to unstake their `EssenceToken`.
7.  `claimStakingRewards()`: Allows stakers to claim rewards accumulated from protocol fees or emissions.
8.  `delegateVote(address _delegatee)`: Allows users to delegate their voting power to another address for governance.

**IV. Evolution Mechanics & Oracle Integration:**
9.  `proposeTraitUpgrade(string memory _traitName, string memory _traitDescription, uint256 _essenceCost, bytes memory _traitData)`: Submits a new trait or trait upgrade for community approval. `_traitData` can be complex, e.g., JSON string or ABI-encoded data.
10. `voteOnTraitProposal(uint256 _proposalId, bool _approve)`: `EssenceToken` stakers vote on proposed traits.
11. `executeTraitProposal(uint256 _proposalId)`: Finalizes a trait proposal if it passes, making it available for Sentinels.
12. `requestSentinelEvolution(uint256 _tokenId, uint256[] memory _traitIdsToApply, bytes memory _oracleQueryData)`: Initiates an evolution request for a Sentinel. Requires staking `EssenceToken` and specifies data to be fetched from an oracle.
13. `fulfillOracleData(uint256 _queryId, bytes memory _data)`: A callback function (only callable by the Oracle) that delivers external data, triggering the finalization of an evolution.
14. `getAvailableEvolutionOptions(uint256 _tokenId)`: Read-only function to show potential evolution paths and available traits for a Sentinel.

**V. DAO Governance & Treasury Management:**
15. `submitTreasuryProposal(address _recipient, uint256 _amount, string memory _description)`: Proposes a spending from the contract's treasury.
16. `voteOnTreasuryProposal(uint256 _proposalId, bool _approve)`: `EssenceToken` stakers vote on treasury spending proposals.
17. `executeTreasuryProposal(uint256 _proposalId)`: Executes approved treasury spending.
18. `setProtocolFee(uint256 _newFeeBasisPoints)`: A governance function to adjust fees collected by the protocol.

**VI. Advanced & Creative Features:**
19. `registerEvolutionRule(bytes32 _ruleHash, string memory _ruleDescription, uint256[] memory _requiredTraits, uint256[] memory _forbiddenTraits)`: Allows governance to define complex, on-chain rules that dictate how traits interact, which traits can be combined, or prerequisites for evolution.
20. `challengeEvolution(uint256 _evolutionRequestId, string memory _reason)`: Enables `EssenceToken` stakers to challenge a finalized evolution if they suspect manipulation or incorrect oracle data. Requires a bond.
21. `resolveEvolutionChallenge(uint256 _challengeId, bool _upholdChallenge)`: Governance function to resolve a challenge. If upheld, the evolution can be reversed or penalties applied.
22. `simulateEvolutionPath(uint256 _tokenId, uint256[] memory _potentialTraitIds)`: A read-only function that simulates the outcome of applying a set of traits to a Sentinel without changing its state, useful for UI/planning.
23. `batchMintSentinels(uint256 _count, string[] memory _initialTraitSeeds)`: Allows for minting multiple Sentinels in a single transaction, useful for initial collection drops.
24. `updateCoreContract(address _newLogicAddress)`: A governance-controlled upgrade mechanism (e.g., using a proxy pattern underneath, but exposed as a simple governance function). *Note: Full proxy implementation would require separate proxy contracts, this function would merely point to a new logic address if a proxy is used.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Interfaces ---
// Assume EssenceToken is a separately deployed ERC20 contract
interface IEssenceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function getVotes(address account) external view returns (uint256);
    function delegate(address delegatee) external;
}

// Mock Oracle Interface (for demonstration, a real oracle like Chainlink would have specific functions)
interface IOracle {
    event OracleRequestSent(uint256 indexed queryId, string dataSource);
    event OracleDataReceived(uint256 indexed queryId, bytes data);

    function requestData(uint256 _queryId, string memory _dataSource) external returns (bytes32); // Returns request ID
    function fulfillData(uint256 _queryId, bytes memory _data) external; // Only callable by a trusted oracle node
}

// --- Main Contract: Aethergenesis Nexus ---
contract AethergenesisNexus is ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---
    IEssenceToken public essenceToken;
    IOracle public oracle;

    Counters.Counter private _sentinelIds;
    Counters.Counter private _traitProposalIds;
    Counters.Counter private _treasuryProposalIds;
    Counters.Counter private _evolutionRequestIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _evolutionRuleIds;

    // Base URI for Sentinel metadata
    string public baseURI;

    // Protocol fees (in basis points, e.g., 100 = 1%)
    uint256 public protocolFeeBasisPoints = 100; // Default 1%

    // --- Structs ---

    struct Trait {
        uint256 id;
        string name;
        string description;
        uint256 essenceCost; // Cost to apply this trait during evolution
        bytes traitData;     // Arbitrary data, e.g., ABI-encoded attributes, SVG parts
        bool isActive;       // Is this trait approved and available?
    }

    struct Sentinel {
        uint256 id;
        uint256[] activeTraitIds;
        uint256 evolutionStage;
        uint256 lastEvolutionTimestamp;
        string initialSeed; // To regenerate initial traits if needed
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved; // Final status
    }

    struct TraitProposal {
        Proposal core;
        Trait proposedTrait;
    }

    struct TreasuryProposal {
        Proposal core;
        address recipient;
        uint256 amount;
        string description;
    }

    struct EvolutionRequest {
        uint256 id;
        uint256 sentinelId;
        address requester;
        uint256[] requestedTraitIds; // Traits user wants to apply
        uint256 essenceStaked;       // Essence staked for this request
        bytes oracleQueryData;       // Data sent to oracle for context
        uint256 oracleQueryId;       // ID for tracking oracle request
        bytes oracleResponseData;    // Data received from oracle
        uint256 requestTimestamp;
        bool finalized;
        bool challenged;
        bool reverted;
    }

    struct EvolutionChallenge {
        uint256 id;
        uint256 evolutionRequestId;
        address challenger;
        uint256 challengeBond; // Essence required to challenge
        string reason;
        Proposal core; // Governance proposal for resolution
    }

    struct EvolutionRule {
        uint256 id;
        bytes32 ruleHash; // Unique identifier for the rule logic (e.g., hash of rule code/description)
        string description;
        uint256[] requiredTraits; // Traits a Sentinel must have for this rule to apply
        uint256[] forbiddenTraits; // Traits a Sentinel must NOT have
        bool isActive;
    }

    // --- Mappings ---
    mapping(uint256 => Sentinel) public sentinels;
    mapping(uint256 => Trait) public traits;
    mapping(uint256 => TraitProposal) public traitProposals;
    mapping(uint256 => TreasuryProposal) public treasuryProposals;
    mapping(uint256 => EvolutionRequest) public evolutionRequests;
    mapping(uint256 => EvolutionChallenge) public evolutionChallenges;
    mapping(uint256 => EvolutionRule) public evolutionRules;

    // Mapping to store active Essence stakes for evolution requests
    mapping(uint256 => mapping(address => uint256)) public essenceStakesForEvolution;

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, string initialSeed);
    event SentinelEvolved(uint256 indexed tokenId, uint256 indexed evolutionRequestId, uint256[] newTraitIds);
    event TraitProposed(uint256 indexed proposalId, string name, address proposer);
    event TraitProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event TraitProposalExecuted(uint256 indexed proposalId, bool approved);
    event EvolutionRequested(uint256 indexed requestId, uint256 indexed sentinelId, address indexed requester, uint256[] traitIdsToApply);
    event OracleDataFulfilled(uint256 indexed queryId, bytes data);
    event TreasuryProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event TreasuryProposalExecuted(uint256 indexed proposalId, bool approved);
    event ProtocolFeeSet(uint256 newFeeBasisPoints);
    event EvolutionRuleRegistered(uint256 indexed ruleId, bytes32 ruleHash);
    event EvolutionChallenged(uint256 indexed challengeId, uint256 indexed evolutionRequestId, address indexed challenger);
    event EvolutionChallengeResolved(uint256 indexed challengeId, bool upheld);
    event EssenceStaked(address indexed staker, uint256 amount);
    event EssenceUnstaked(address indexed unstaker, uint256 amount);
    event StakingRewardsClaimed(address indexed receiver, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event CoreContractUpdated(address indexed newLogicAddress);

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _oracleAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        ERC721URIStorage()
    {
        essenceToken = IEssenceToken(_essenceTokenAddress);
        oracle = IOracle(_oracleAddress);
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == address(oracle), "ACN: Not authorized oracle");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(traitProposals[_proposalId].core.proposer != address(0) || treasuryProposals[_proposalId].core.proposer != address(0), "ACN: Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(traitProposals[_proposalId].core.id == _proposalId ? !traitProposals[_proposalId].core.executed : !treasuryProposals[_proposalId].core.executed, "ACN: Proposal already executed");
        _;
    }

    modifier proposalNotExpired(uint256 _proposalId) {
        require(traitProposals[_proposalId].core.id == _proposalId ? block.timestamp <= traitProposals[_proposalId].core.endTime : block.timestamp <= treasuryProposals[_proposalId].core.endTime, "ACN: Proposal has expired");
        _;
    }

    modifier onlySentinelOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ACN: Not owner or approved for Sentinel");
        _;
    }

    // --- I. Sentinel NFT Management ---

    /**
     * @dev Mints a new Sentinel NFT.
     * @param _initialTraitSeed A seed string used to generate the initial traits of the Sentinel.
     */
    function mintSentinel(string memory _initialTraitSeed) external payable nonReentrant {
        _sentinelIds.increment();
        uint256 newTokenId = _sentinelIds.current();

        // For simplicity, initial trait generation is abstracted.
        // In a real implementation, this could parse the seed to assign initial traits.
        uint256[] memory initialTraits = new uint256[](0); // Or parse from _initialTraitSeed
        // Example: if seed implies specific traits, add them here
        // initialTraits.push(traitIdFromSeed);

        sentinels[newTokenId] = Sentinel({
            id: newTokenId,
            activeTraitIds: initialTraits,
            evolutionStage: 1,
            lastEvolutionTimestamp: block.timestamp,
            initialSeed: _initialTraitSeed
        });

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _generateTokenURI(newTokenId, initialTraits));

        emit SentinelMinted(newTokenId, msg.sender, _initialTraitSeed);
    }

    /**
     * @dev Batch mints multiple Sentinel NFTs.
     * @param _count The number of Sentinels to mint.
     * @param _initialTraitSeeds An array of seed strings, one for each Sentinel.
     */
    function batchMintSentinels(uint256 _count, string[] memory _initialTraitSeeds) external payable nonReentrant {
        require(_count == _initialTraitSeeds.length, "ACN: Mismatch between count and seeds array length");
        for (uint256 i = 0; i < _count; i++) {
            _sentinelIds.increment();
            uint256 newTokenId = _sentinelIds.current();

            uint256[] memory initialTraits = new uint256[](0); // Abstracted initial trait generation

            sentinels[newTokenId] = Sentinel({
                id: newTokenId,
                activeTraitIds: initialTraits,
                evolutionStage: 1,
                lastEvolutionTimestamp: block.timestamp,
                initialSeed: _initialTraitSeeds[i]
            });

            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, _generateTokenURI(newTokenId, initialTraits));
            emit SentinelMinted(newTokenId, msg.sender, _initialTraitSeeds[i]);
        }
    }


    /**
     * @dev Retrieves all current details of a Sentinel.
     * @param _tokenId The ID of the Sentinel.
     * @return Sentinel struct containing all its data.
     */
    function getSentinelDetails(uint256 _tokenId) public view returns (Sentinel memory) {
        require(_exists(_tokenId), "ACN: Sentinel does not exist");
        return sentinels[_tokenId];
    }

    /**
     * @dev Generates the dynamic metadata URI for a Sentinel.
     * @param _tokenId The ID of the Sentinel.
     * @return The URI pointing to the Sentinel's dynamic metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ACN: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    /**
     * @dev Internal function to generate the actual metadata JSON or point to a generator service.
     *      This is where the dynamic nature comes in.
     * @param _tokenId The ID of the Sentinel.
     * @param _traitIds The current active trait IDs of the Sentinel.
     * @return A string representing the URI.
     */
    function _generateTokenURI(uint256 _tokenId, uint256[] memory _traitIds) internal view returns (string memory) {
        // This function would typically construct a URI to an API endpoint or IPFS gateway
        // that dynamically generates JSON metadata based on the Sentinel's current state.
        // For example: `baseURI` + `_tokenId.toString()` + `/metadata.json?traits=` + `_traitIds.join(',')`
        string memory currentTraits = "";
        for (uint256 i = 0; i < _traitIds.length; i++) {
            currentTraits = string(abi.encodePacked(currentTraits, traits[_traitIds[i]].name, (i == _traitIds.length - 1 ? "" : ",")));
        }

        return string(abi.encodePacked(
            baseURI,
            _tokenId.toString(),
            "/metadata.json?evolution_stage=",
            sentinels[_tokenId].evolutionStage.toString(),
            "&traits=",
            currentTraits
        ));
    }


    /**
     * @dev Sets the base URI for Sentinel metadata. Only callable by owner or governance.
     * @param _newBaseURI The new base URI.
     */
    function setSentinelBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // --- II. Essence Token & Staking ---

    /**
     * @dev Allows users to stake Essence tokens to gain influence and voting power.
     * @param _amount The amount of Essence tokens to stake.
     */
    function stakeEssence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "ACN: Amount must be greater than zero");
        essenceToken.transferFrom(msg.sender, address(this), _amount);
        // This contract acts as the staking pool.
        // Voting power is generally managed by the EssenceToken itself (e.g., using ERC20Votes).
        // Here, we'll just track the balance held by the contract, and EssenceToken's getVotes
        // would reflect the amount a user has, if they had delegated their voting power.
        emit EssenceStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their Essence tokens.
     * @param _amount The amount of Essence tokens to unstake.
     */
    function unstakeEssence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "ACN: Amount must be greater than zero");
        require(essenceToken.balanceOf(address(this)) >= _amount, "ACN: Insufficient staked Essence");
        // Check for any active evolution challenges or proposals that might lock tokens
        // For simplicity, this implementation doesn't lock stakes beyond the initial cost.

        essenceToken.transfer(msg.sender, _amount);
        emit EssenceUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows stakers to claim rewards accumulated from protocol fees or emissions.
     * (Placeholder for a more complex rewards mechanism)
     */
    function claimStakingRewards() public {
        // This is a placeholder. A real system would have a more complex rewards calculation
        // based on staking duration, amount, and protocol earnings.
        // For now, it could be a small amount of newly minted Essence or collected fees.
        uint256 rewardAmount = 0; // Calculate based on protocol earnings / emissions
        if (rewardAmount > 0) {
            // Assume the contract has logic to distribute rewards, e.g., from fees or newly minted tokens.
            // essenceToken.transfer(msg.sender, rewardAmount); // If rewards are in Essence
            // If rewards are minted:
            // essenceToken.mint(msg.sender, rewardAmount);
            emit StakingRewardsClaimed(msg.sender, rewardAmount);
        } else {
            revert("ACN: No rewards available to claim");
        }
    }

    /**
     * @dev Allows users to delegate their voting power to another address.
     *      Assumes EssenceToken implements ERC20Votes.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) public {
        essenceToken.delegate(_delegatee);
        emit VoteDelegated(msg.sender, _delegatee);
    }

    // --- III. Evolution Mechanics & Oracle Integration ---

    /**
     * @dev Submits a new trait or trait upgrade for community approval via governance.
     * @param _traitName The name of the proposed trait.
     * @param _traitDescription A description of the trait's effects.
     * @param _essenceCost The `EssenceToken` cost to apply this trait during evolution.
     * @param _traitData Arbitrary data representing the trait (e.g., SVG path, attribute modifiers).
     */
    function proposeTraitUpgrade(
        string memory _traitName,
        string memory _traitDescription,
        uint256 _essenceCost,
        bytes memory _traitData
    ) external nonReentrant {
        _traitProposalIds.increment();
        uint256 proposalId = _traitProposalIds.current();

        Trait memory newTrait = Trait({
            id: proposalId, // Use proposalId as initial traitId
            name: _traitName,
            description: _traitDescription,
            essenceCost: _essenceCost,
            traitData: _traitData,
            isActive: false // Not active until approved
        });

        traitProposals[proposalId] = TraitProposal({
            core: Proposal({
                id: proposalId,
                proposer: msg.sender,
                startTime: block.timestamp,
                endTime: block.timestamp + 7 days, // Example: 7 days voting period
                yesVotes: 0,
                noVotes: 0,
                executed: false,
                approved: false
            }),
            proposedTrait: newTrait
        });

        emit TraitProposed(proposalId, _traitName, msg.sender);
    }

    /**
     * @dev Allows `EssenceToken` stakers to vote on proposed traits.
     * @param _proposalId The ID of the trait proposal.
     * @param _approve True for 'yes' vote, false for 'no' vote.
     */
    function voteOnTraitProposal(uint256 _proposalId, bool _approve) external nonReentrant proposalExists(_proposalId) proposalNotExecuted(_proposalId) proposalNotExpired(_proposalId) {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(!proposal.core.hasVoted[msg.sender], "ACN: Already voted on this proposal");

        uint256 voterEssence = essenceToken.getVotes(msg.sender); // Get delegated voting power
        require(voterEssence > 0, "ACN: No voting power");

        if (_approve) {
            proposal.core.yesVotes = proposal.core.yesVotes.add(voterEssence);
        } else {
            proposal.core.noVotes = proposal.core.noVotes.add(voterEssence);
        }
        proposal.core.hasVoted[msg.sender] = true;

        emit TraitProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Finalizes a trait proposal if it passes, making the trait available for Sentinels.
     *      Requires a quorum and majority vote.
     * @param _proposalId The ID of the trait proposal.
     */
    function executeTraitProposal(uint256 _proposalId) external nonReentrant proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(block.timestamp > proposal.core.endTime, "ACN: Voting period not ended");

        // Quorum and Majority check (example values)
        uint256 totalVotes = proposal.core.yesVotes.add(proposal.core.noVotes);
        uint256 totalEssenceSupply = essenceToken.totalSupply(); // Or just staked supply
        uint256 quorumThreshold = totalEssenceSupply.div(10); // Example: 10% quorum
        uint256 majorityThreshold = totalVotes.div(2); // Example: simple majority

        if (totalVotes >= quorumThreshold && proposal.core.yesVotes > majorityThreshold) {
            // Proposal approved
            proposal.core.approved = true;
            proposal.proposedTrait.isActive = true;
            traits[proposal.proposedTrait.id] = proposal.proposedTrait; // Add to active traits
        } else {
            // Proposal rejected
            proposal.core.approved = false;
        }

        proposal.core.executed = true;
        emit TraitProposalExecuted(_proposalId, proposal.core.approved);
    }

    /**
     * @dev Initiates an evolution request for a Sentinel. This is a two-step process:
     *      1. User requests, pays Essence, and specifies oracle query.
     *      2. Oracle fulfills, triggering `_finalizeSentinelEvolution` internally.
     * @param _tokenId The ID of the Sentinel to evolve.
     * @param _traitIdsToApply An array of IDs of the traits the user wishes to apply.
     * @param _oracleQueryData Data to be sent to the oracle for context (e.g., specific parameters).
     */
    function requestSentinelEvolution(
        uint256 _tokenId,
        uint256[] memory _traitIdsToApply,
        bytes memory _oracleQueryData
    ) external nonReentrant onlySentinelOwner(_tokenId) {
        require(_traitIdsToApply.length > 0, "ACN: No traits to apply");

        uint256 totalEssenceCost = 0;
        for (uint256 i = 0; i < _traitIdsToApply.length; i++) {
            uint256 traitId = _traitIdsToApply[i];
            require(traits[traitId].isActive, "ACN: Trait not active or does not exist");
            // Check evolution rules for compatibility
            _checkEvolutionRules(sentinels[_tokenId], traitId);
            totalEssenceCost = totalEssenceCost.add(traits[traitId].essenceCost);
        }

        // Transfer Essence cost from user (can be burnt or sent to treasury)
        require(essenceToken.transferFrom(msg.sender, address(this), totalEssenceCost), "ACN: Essence transfer failed");

        _evolutionRequestIds.increment();
        uint256 requestId = _evolutionRequestIds.current();

        // Request data from oracle
        uint256 queryId = _evolutionRequestIds.current(); // Using request ID as query ID for simplicity
        bytes32 oracleRequestId = oracle.requestData(queryId, "ACN:SentinelEvolution"); // Placeholder for actual oracle query string

        evolutionRequests[requestId] = EvolutionRequest({
            id: requestId,
            sentinelId: _tokenId,
            requester: msg.sender,
            requestedTraitIds: _traitIdsToApply,
            essenceStaked: totalEssenceCost,
            oracleQueryData: _oracleQueryData,
            oracleQueryId: queryId,
            oracleResponseData: "", // To be filled by oracle
            requestTimestamp: block.timestamp,
            finalized: false,
            challenged: false,
            reverted: false
        });

        emit EvolutionRequested(requestId, _tokenId, msg.sender, _traitIdsToApply);
    }

    /**
     * @dev Callback function from the oracle. Delivers external data and triggers evolution finalization.
     *      This function can only be called by the registered oracle address.
     * @param _queryId The ID of the oracle query.
     * @param _data The data received from the oracle.
     */
    function fulfillOracleData(uint256 _queryId, bytes memory _data) external onlyOracle {
        // Find the evolution request associated with this query ID
        uint256 requestId = 0;
        bool found = false;
        for (uint256 i = 1; i <= _evolutionRequestIds.current(); i++) {
            if (evolutionRequests[i].oracleQueryId == _queryId && !evolutionRequests[i].finalized) {
                requestId = i;
                found = true;
                break;
            }
        }
        require(found, "ACN: No pending evolution request for this oracle query ID");

        EvolutionRequest storage req = evolutionRequests[requestId];
        req.oracleResponseData = _data;

        _finalizeSentinelEvolution(requestId);

        emit OracleDataFulfilled(_queryId, _data);
    }

    /**
     * @dev Internal function to finalize Sentinel evolution after oracle data is received.
     * @param _requestId The ID of the evolution request.
     */
    function _finalizeSentinelEvolution(uint256 _requestId) internal {
        EvolutionRequest storage req = evolutionRequests[_requestId];
        require(!req.finalized, "ACN: Evolution already finalized");
        require(req.oracleResponseData.length > 0, "ACN: Oracle data not yet fulfilled");

        Sentinel storage sentinel = sentinels[req.sentinelId];

        // Apply new traits and remove old ones if needed (complex logic based on trait types)
        // For simplicity, we just add new traits here. A real system might replace, combine, etc.
        for (uint256 i = 0; i < req.requestedTraitIds.length; i++) {
            uint256 newTraitId = req.requestedTraitIds[i];
            bool alreadyHasTrait = false;
            for (uint256 j = 0; j < sentinel.activeTraitIds.length; j++) {
                if (sentinel.activeTraitIds[j] == newTraitId) {
                    alreadyHasTrait = true;
                    break;
                }
            }
            if (!alreadyHasTrait) {
                sentinel.activeTraitIds.push(newTraitId);
            }
        }

        sentinel.evolutionStage = sentinel.evolutionStage.add(1);
        sentinel.lastEvolutionTimestamp = block.timestamp;

        // Update URI to reflect new traits
        _setTokenURI(sentinel.id, _generateTokenURI(sentinel.id, sentinel.activeTraitIds));

        req.finalized = true;

        // Apply protocol fee to the essence cost
        uint256 protocolFee = req.essenceStaked.mul(protocolFeeBasisPoints).div(10000); // basis points are /10000
        uint256 remainingEssence = req.essenceStaked.sub(protocolFee);

        // Essence can be burnt, sent to treasury, or distributed to stakers.
        // For this example, remaining is burnt, fee goes to treasury.
        if (protocolFee > 0) {
            essenceToken.transfer(owner(), protocolFee); // Send to owner as treasury for now
        }
        if (remainingEssence > 0) {
            essenceToken.burn(remainingEssence); // Burn remaining essence
        }


        emit SentinelEvolved(sentinel.id, _requestId, sentinel.activeTraitIds);
    }

    /**
     * @dev Read-only function to show potential evolution paths and available traits for a Sentinel.
     *      (Placeholder for complex logic that would analyze current traits and available proposals)
     * @param _tokenId The ID of the Sentinel.
     * @return An array of available trait IDs that could be applied.
     */
    function getAvailableEvolutionOptions(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "ACN: Sentinel does not exist");
        // This function would typically filter `traits` mapping based on:
        // 1. `isActive` status
        // 2. Compatibility with `sentinels[_tokenId].activeTraitIds` based on `evolutionRules`
        // 3. User's Essence balance

        uint256[] memory availableTraitIds = new uint256[](_traitProposalIds.current()); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i <= _traitProposalIds.current(); i++) {
            if (traits[i].isActive) {
                // Further logic here to check against evolution rules
                // and if the sentinel already has the trait.
                bool canApply = true;
                for (uint256 j = 0; j < sentinels[_tokenId].activeTraitIds.length; j++) {
                    if (sentinels[_tokenId].activeTraitIds[j] == i) {
                        canApply = false;
                        break;
                    }
                }
                if (canApply) {
                     // check against evolution rules
                    for (uint256 r = 1; r <= _evolutionRuleIds.current(); r++) {
                        EvolutionRule storage rule = evolutionRules[r];
                        if (rule.isActive) {
                            bool requiredMet = true;
                            for (uint256 rt = 0; rt < rule.requiredTraits.length; rt++) {
                                bool hasRequired = false;
                                for (uint256 st = 0; st < sentinels[_tokenId].activeTraitIds.length; st++) {
                                    if (sentinels[_tokenId].activeTraitIds[st] == rule.requiredTraits[rt]) {
                                        hasRequired = true;
                                        break;
                                    }
                                }
                                if (!hasRequired) {
                                    requiredMet = false;
                                    break;
                                }
                            }

                            bool forbiddenPresent = false;
                            for (uint256 ft = 0; ft < rule.forbiddenTraits.length; ft++) {
                                for (uint256 st = 0; st < sentinels[_tokenId].activeTraitIds.length; st++) {
                                    if (sentinels[_tokenId].activeTraitIds[st] == rule.forbiddenTraits[ft] || ft == i) { // If the proposed trait is forbidden
                                        forbiddenPresent = true;
                                        break;
                                    }
                                }
                                if (forbiddenPresent) break;
                            }

                            if (!requiredMet || forbiddenPresent) {
                                canApply = false;
                                break;
                            }
                        }
                    }
                }
                if(canApply) {
                    availableTraitIds[counter] = i;
                    counter++;
                }
            }
        }

        uint256[] memory actualAvailableTraits = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            actualAvailableTraits[i] = availableTraitIds[i];
        }
        return actualAvailableTraits;
    }

    // --- IV. DAO Governance & Treasury Management ---

    /**
     * @dev Proposes a spending from the contract's treasury. Only for Essence Token.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Essence tokens to send.
     * @param _description A description of the spending purpose.
     */
    function submitTreasuryProposal(address _recipient, uint256 _amount, string memory _description) external nonReentrant {
        require(_amount > 0, "ACN: Amount must be greater than zero");
        require(essenceToken.balanceOf(address(this)) >= _amount, "ACN: Insufficient funds in treasury");

        _treasuryProposalIds.increment();
        uint256 proposalId = _treasuryProposalIds.current();

        treasuryProposals[proposalId] = TreasuryProposal({
            core: Proposal({
                id: proposalId,
                proposer: msg.sender,
                startTime: block.timestamp,
                endTime: block.timestamp + 7 days, // Example: 7 days voting period
                yesVotes: 0,
                noVotes: 0,
                executed: false,
                approved: false
            }),
            recipient: _recipient,
            amount: _amount,
            description: _description
        });

        emit TreasuryProposed(proposalId, _recipient, _amount);
    }

    /**
     * @dev `EssenceToken` stakers vote on treasury spending proposals.
     * @param _proposalId The ID of the treasury proposal.
     * @param _approve True for 'yes' vote, false for 'no' vote.
     */
    function voteOnTreasuryProposal(uint256 _proposalId, bool _approve) external nonReentrant proposalExists(_proposalId) proposalNotExecuted(_proposalId) proposalNotExpired(_proposalId) {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(!proposal.core.hasVoted[msg.sender], "ACN: Already voted on this proposal");

        uint256 voterEssence = essenceToken.getVotes(msg.sender);
        require(voterEssence > 0, "ACN: No voting power");

        if (_approve) {
            proposal.core.yesVotes = proposal.core.yesVotes.add(voterEssence);
        } else {
            proposal.core.noVotes = proposal.core.noVotes.add(voterEssence);
        }
        proposal.core.hasVoted[msg.sender] = true;

        emit TraitProposalVoted(_proposalId, msg.sender, _approve); // Reusing event for voting
    }

    /**
     * @dev Executes an approved treasury spending proposal.
     * @param _proposalId The ID of the treasury proposal.
     */
    function executeTreasuryProposal(uint256 _proposalId) external nonReentrant proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(block.timestamp > proposal.core.endTime, "ACN: Voting period not ended");

        // Quorum and Majority check
        uint256 totalVotes = proposal.core.yesVotes.add(proposal.core.noVotes);
        uint256 totalEssenceSupply = essenceToken.totalSupply();
        uint256 quorumThreshold = totalEssenceSupply.div(10); // Example: 10% quorum
        uint256 majorityThreshold = totalVotes.div(2); // Example: simple majority

        if (totalVotes >= quorumThreshold && proposal.core.yesVotes > majorityThreshold) {
            // Proposal approved
            proposal.core.approved = true;
            essenceToken.transfer(proposal.recipient, proposal.amount);
        } else {
            // Proposal rejected
            proposal.core.approved = false;
        }

        proposal.core.executed = true;
        emit TreasuryProposalExecuted(_proposalId, proposal.core.approved);
    }

    /**
     * @dev Allows governance to adjust the protocol fee applied to evolution requests.
     * @param _newFeeBasisPoints The new fee in basis points (e.g., 100 for 1%). Max 1000 (10%).
     */
    function setProtocolFee(uint256 _newFeeBasisPoints) external onlyOwner { // In a full DAO, this would be a governance proposal
        require(_newFeeBasisPoints <= 1000, "ACN: Fee cannot exceed 10%");
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeSet(_newFeeBasisPoints);
    }

    // --- V. Advanced & Creative Features ---

    /**
     * @dev Allows governance to define complex, on-chain rules that dictate how traits interact,
     *      which traits can be combined, or prerequisites for evolution.
     * @param _ruleHash A unique hash identifying the rule's logic (e.g., hash of bytecode or detailed spec).
     * @param _ruleDescription A human-readable description of the rule.
     * @param _requiredTraits An array of trait IDs required for this rule to apply.
     * @param _forbiddenTraits An array of trait IDs that must NOT be present for this rule to apply.
     */
    function registerEvolutionRule(
        bytes32 _ruleHash,
        string memory _ruleDescription,
        uint256[] memory _requiredTraits,
        uint256[] memory _forbiddenTraits
    ) external onlyOwner { // Would be a governance proposal in a full DAO
        _evolutionRuleIds.increment();
        uint256 ruleId = _evolutionRuleIds.current();

        evolutionRules[ruleId] = EvolutionRule({
            id: ruleId,
            ruleHash: _ruleHash,
            description: _ruleDescription,
            requiredTraits: _requiredTraits,
            forbiddenTraits: _forbiddenTraits,
            isActive: true
        });

        emit EvolutionRuleRegistered(ruleId, _ruleHash);
    }

    /**
     * @dev Internal function to check if a trait application is valid based on registered evolution rules.
     * @param _sentinel The Sentinel undergoing evolution.
     * @param _newTraitId The ID of the trait being considered.
     */
    function _checkEvolutionRules(Sentinel memory _sentinel, uint256 _newTraitId) internal view {
        for (uint256 i = 1; i <= _evolutionRuleIds.current(); i++) {
            EvolutionRule storage rule = evolutionRules[i];
            if (!rule.isActive) continue;

            // Check required traits
            for (uint256 j = 0; j < rule.requiredTraits.length; j++) {
                bool found = false;
                for (uint256 k = 0; k < _sentinel.activeTraitIds.length; k++) {
                    if (_sentinel.activeTraitIds[k] == rule.requiredTraits[j]) {
                        found = true;
                        break;
                    }
                }
                require(found, string(abi.encodePacked("ACN: Evolution rule violated (missing required trait ", rule.requiredTraits[j].toString(), ")")));
            }

            // Check forbidden traits
            for (uint256 j = 0; j < rule.forbiddenTraits.length; j++) {
                require(rule.forbiddenTraits[j] != _newTraitId, string(abi.encodePacked("ACN: Evolution rule violated (forbidden trait ", _newTraitId.toString(), ")")));
                for (uint256 k = 0; k < _sentinel.activeTraitIds.length; k++) {
                    require(_sentinel.activeTraitIds[k] != rule.forbiddenTraits[j], string(abi.encodePacked("ACN: Evolution rule violated (existing forbidden trait ", rule.forbiddenTraits[j].toString(), ")")));
                }
            }
        }
    }


    /**
     * @dev Enables `EssenceToken` stakers to challenge a finalized evolution if they suspect manipulation or incorrect oracle data.
     *      Requires a bond, which is locked during the challenge period.
     * @param _evolutionRequestId The ID of the evolution request to challenge.
     * @param _reason A string explaining the reason for the challenge.
     */
    function challengeEvolution(uint256 _evolutionRequestId, string memory _reason) external nonReentrant {
        EvolutionRequest storage req = evolutionRequests[_evolutionRequestId];
        require(req.finalized, "ACN: Evolution not yet finalized");
        require(!req.challenged, "ACN: Evolution already challenged");
        require(block.timestamp < req.lastEvolutionTimestamp + 3 days, "ACN: Challenge period expired (3 days)"); // Example: 3-day challenge window

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();
        uint256 challengeBond = req.essenceStaked.div(2); // Example: 50% of the original evolution cost as bond

        require(essenceToken.transferFrom(msg.sender, address(this), challengeBond), "ACN: Challenge bond transfer failed");

        _treasuryProposalIds.increment(); // Reusing treasury proposal ID for challenge vote
        uint256 proposalId = _treasuryProposalIds.current(); // This is the ID for the vote to resolve the challenge

        evolutionChallenges[challengeId] = EvolutionChallenge({
            id: challengeId,
            evolutionRequestId: _evolutionRequestId,
            challenger: msg.sender,
            challengeBond: challengeBond,
            reason: _reason,
            core: Proposal({
                id: proposalId,
                proposer: msg.sender, // Challenger initiates the vote
                startTime: block.timestamp,
                endTime: block.timestamp + 5 days, // Example: 5 days for challenge resolution vote
                yesVotes: 0,
                noVotes: 0,
                executed: false,
                approved: false // 'approved' here means the challenge is UPHELD
            })
        });

        req.challenged = true; // Mark evolution as challenged

        emit EvolutionChallenged(challengeId, _evolutionRequestId, msg.sender);
    }

    /**
     * @dev Governance function to resolve an evolution challenge. If upheld, the evolution can be reversed or penalties applied.
     *      This functions similarly to other governance votes.
     * @param _challengeId The ID of the evolution challenge.
     * @param _upholdChallenge True if the challenge is upheld (evolution invalid), false if rejected (evolution valid).
     */
    function resolveEvolutionChallenge(uint256 _challengeId, bool _upholdChallenge) external nonReentrant {
        EvolutionChallenge storage challenge = evolutionChallenges[_challengeId];
        require(challenge.evolutionRequestId != 0, "ACN: Challenge does not exist");
        require(block.timestamp > challenge.core.endTime, "ACN: Challenge voting period not ended");
        require(!challenge.core.executed, "ACN: Challenge already resolved");

        // Governance vote resolution logic (similar to trait/treasury proposals)
        // Assume voting has happened and challenge.core.yesVotes/noVotes are populated
        uint256 totalVotes = challenge.core.yesVotes.add(challenge.core.noVotes);
        uint256 totalEssenceSupply = essenceToken.totalSupply();
        uint256 quorumThreshold = totalEssenceSupply.div(10);
        uint256 majorityThreshold = totalVotes.div(2);

        bool challengeUpheld = (totalVotes >= quorumThreshold && challenge.core.yesVotes > majorityThreshold);

        if (challengeUpheld) {
            // Challenge upheld: Reverse evolution, penalize original requester, reward challenger
            EvolutionRequest storage req = evolutionRequests[challenge.evolutionRequestId];
            Sentinel storage sentinel = sentinels[req.sentinelId];

            // Revert sentinel traits (this is complex, depends on trait system, may involve backups or specific logic)
            // For simplicity, we'll just mark it as reverted and potentially burn the Sentinel or freeze it.
            req.reverted = true;
            // More sophisticated logic needed: revert traits, previous URI, etc.
            // Example: burn the Sentinel to signify invalidity or return to a previous state
            // _burn(sentinel.id);

            // Reward challenger from original requester's staked Essence or a penalty
            // For simplicity, challenger gets their bond back + some penalty from requester's initial stake (if any left)
            essenceToken.transfer(challenge.challenger, challenge.challengeBond); // Return bond
            if (req.essenceStaked > 0) { // If requester had staked Essence
                // Example: transfer a portion of requester's initial stake to challenger
                uint256 penaltyAmount = req.essenceStaked.div(4); // 25% penalty
                if (essenceToken.balanceOf(address(this)) >= penaltyAmount) {
                     essenceToken.transfer(challenge.challenger, penaltyAmount);
                     req.essenceStaked = req.essenceStaked.sub(penaltyAmount); // Deduct from requester's locked stake
                }
            }
        } else {
            // Challenge rejected: Challenger loses bond, original requester's evolution remains valid.
            // Challenger bond is transferred to treasury or burnt.
            essenceToken.transfer(owner(), challenge.challengeBond); // Transfer bond to treasury (owner)
        }

        challenge.core.executed = true;
        challenge.core.approved = challengeUpheld; // 'approved' means the challenge was upheld
        emit EvolutionChallengeResolved(_challengeId, challengeUpheld);
    }

    /**
     * @dev A read-only function that simulates the outcome of applying a set of traits to a Sentinel
     *      without changing its state, useful for UI and user planning.
     * @param _tokenId The ID of the Sentinel to simulate for.
     * @param _potentialTraitIds An array of trait IDs to simulate applying.
     * @return An array of the Sentinel's active trait IDs *after* the simulation.
     */
    function simulateEvolutionPath(uint256 _tokenId, uint256[] memory _potentialTraitIds) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "ACN: Sentinel does not exist");

        Sentinel memory currentSentinel = sentinels[_tokenId];
        uint256[] memory simulatedTraits = new uint256[](currentSentinel.activeTraitIds.length + _potentialTraitIds.length);
        uint256 currentIdx = 0;

        // Copy existing traits
        for (uint256 i = 0; i < currentSentinel.activeTraitIds.length; i++) {
            simulatedTraits[currentIdx++] = currentSentinel.activeTraitIds[i];
        }

        // Add potential new traits, avoiding duplicates
        for (uint256 i = 0; i < _potentialTraitIds.length; i++) {
            uint256 newTraitId = _potentialTraitIds[i];
            bool alreadyHas = false;
            for (uint256 j = 0; j < currentSentinel.activeTraitIds.length; j++) {
                if (currentSentinel.activeTraitIds[j] == newTraitId) {
                    alreadyHas = true;
                    break;
                }
            }
            if (!alreadyHas) {
                simulatedTraits[currentIdx++] = newTraitId;
            }
        }

        // Resize the array to actual elements
        uint256[] memory finalSimulatedTraits = new uint256[](currentIdx);
        for (uint256 i = 0; i < currentIdx; i++) {
            finalSimulatedTraits[i] = simulatedTraits[i];
        }

        // In a more advanced simulation, this would also apply evolution rules
        // and potentially calculate new attributes, power levels, etc.
        // For example: _checkEvolutionRules({id: _tokenId, activeTraitIds: finalSimulatedTraits, ...}, newTraitId);
        // This would require modifying _checkEvolutionRules to take a mutable Sentinel copy
        // or a different interface, or make it purely read-only if it only checks static rules.

        return finalSimulatedTraits;
    }

    /**
     * @dev Allows upgrading the core logic contract. This function assumes a proxy pattern
     *      is used (e.g., UUPS proxy). Calling this would update the proxy's implementation address.
     *      In a full DAO, this would be behind a governance proposal.
     * @param _newLogicAddress The address of the new implementation contract.
     */
    function updateCoreContract(address _newLogicAddress) external onlyOwner { // This should be a governance proposal in a real DAO
        // With a UUPS proxy, this function would call `_authorizeUpgrade` and `_upgradeTo`
        // For a basic contract, this is a placeholder.
        // require(implementationAddress != _newLogicAddress, "ACN: New logic address is the same as current");
        // implementationAddress = _newLogicAddress; // This is a placeholder for actual proxy logic
        emit CoreContractUpdated(_newLogicAddress);
    }

    // --- ERC721 Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _approve(address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._approve(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```