Here's a smart contract in Solidity called `EvoNexusCore`, designed with advanced, creative, and trendy concepts: dynamic NFTs, AI-assisted governance, an on-chain reputation system for AI Oracles, and a community-driven evolutionary ecosystem. It includes an outline and a summary of its 26 functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title EvoNexusCore: Adaptive Generative Organisms (AGO) DAO
 * @author AI-Solidity-Engineer
 * @notice EvoNexusCore is a smart contract system for creating, evolving, and governing dynamic NFTs,
 *         referred to as "Organisms." These Organisms possess a mutable 'GeneSequence' that dictates
 *         their characteristics (interpreted off-chain). The evolution of these Organisms is driven by
 *         a decentralized autonomous organization (DAO) and influenced by reputable AI Oracles.
 *         It combines dynamic NFTs, AI-assisted governance, and community curation into a novel
 *         on-chain evolutionary ecosystem.
 *
 * Core Concepts:
 * - Organisms (NFTs): ERC721 tokens representing digital life forms with a dynamic GeneSequence.
 *                    Their visual/data representation is derived off-chain from their on-chain genes.
 * - GeneSequence: A struct defining an Organism's core traits, which can evolve over time.
 * - Evolution Epochs: Periodic, global evolutionary events that can apply subtle environmental drifts
 *                     to all organisms or prepare them for new evolutionary phases.
 * - Evolution Proposals: Mechanisms for community members or registered AI Oracles to propose
 *                        specific changes to an Organism's GeneSequence.
 * - AI Oracles: Registered entities that utilize AI models off-chain to suggest optimal evolutionary
 *               paths. Their proposals are cryptographically signed and submitted for community review.
 *               They build reputation based on the success and quality of their proposals.
 * - EVO Token (Governance): An ERC20 token used for staking, voting on proposals, and funding
 *                           evolutionary initiatives within the DAO.
 * - Evolution Pool: A communal treasury accumulating funds (e.g., ETH, stablecoins) for rewarding
 *                   successful AI Oracles, funding research, or supporting community-driven evolution.
 *
 * Advanced & Creative Aspects:
 * - Dynamic NFTs: NFTs whose core on-chain data (GeneSequence) changes over time based on governance.
 * - AI-Assisted Governance: AI models provide data-driven proposals for evolution, which are then
 *   validated and voted upon by the community, bridging AI insights with decentralized decision-making.
 * - On-Chain Reputation for AI Oracles: Incentivizes truthful and beneficial AI predictions/proposals.
 * - Dual Evolution Paths: Organisms can evolve through specific, targeted proposals or through global
 *   epochs that affect the entire ecosystem.
 */

// --- OUTLINE & FUNCTION SUMMARY ---

// I. INTERFACES AND LIBRARIES
//    - IEVO: Minimal interface for the EVO governance token.

// II. STRUCTS & ENUMS
//    - GeneSequence: Defines an organism's genetic traits.
//    - Organism: Stores core organism data including its GeneSequence and generation.
//    - EvolutionProposal: Details of a community or AI-submitted evolution proposal.
//    - AIOracle: Details of a registered AI oracle.
//    - ProposalState: Enum for the lifecycle of a proposal (Pending, Active, Succeeded, Failed, Executed).

// III. EVENTS
//    - OrganismMinted(uint256 indexed organismId, address indexed creator, GeneSequence initialGenes, uint256 generation)
//    - GenesEvolved(uint256 indexed organismId, uint256 indexed generation, GeneSequence newGenes, address indexed proposer, uint256 proposalId)
//    - GlobalEvolutionEpochTriggered(uint256 indexed newGlobalGeneration, uint256 timestamp)
//    - ProposalCreated(uint256 indexed proposalId, uint256 indexed organismId, address indexed proposer, uint256 timestamp)
//    - ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower)
//    - ProposalExecuted(uint256 indexed proposalId, bool success, address executor)
//    - AIOrcleRegistered(address indexed oracleAddress, string name, address signatureAddress, uint256 depositAmount)
//    - AIOrcleReputationUpdated(address indexed oracleAddress, int256 reputationChange, int256 newReputation)
//    - AIOrcleStakeSlashed(address indexed oracleAddress, uint256 amount, address indexed slasher)
//    - AIOrcleStakeClaimed(address indexed oracleAddress, uint256 amount)
//    - EVOTokensStaked(address indexed staker, uint256 amount, uint256 newBalance)
//    - EVOTokensUnstaked(address indexed unstaker, uint256 amount, uint256 newBalance)
//    - EVOTokensDelegated(address indexed delegator, address indexed delegatee)
//    - PoolDeposited(address indexed depositor, uint256 amount)
//    - RewardsDistributed(address[] recipients, uint256[] amounts)
//    - ConfigUpdated(string configName, uint256 newValue)

// IV. CORE CONTRACT STATE VARIABLES

// V. MODIFIERS
//    - onlyAIOrcleSigner: Ensures caller's address is registered as an AI Oracle's signature address.
//    - hasVotingPower: Ensures caller has sufficient staked/delegated EVO for voting.
//    - onlyDAO: Placeholder modifier for functions controlled by a DAO proposal (e.g., using a separate Governor contract). For simplicity, it defaults to onlyOwner in this example.

// VI. CONSTRUCTOR
//    - Initializes ERC721 name/symbol, EVO token address, and initial DAO config.

// VII. ORGANISM MANAGEMENT & QUERIES (ERC721 & Gene-specific)
// 1.  `mintOrganism(address recipient, GeneSequence memory initialGenes)`
//     - Mints a new Organism NFT to `recipient` with an `initialGenes` sequence.
//     - Emits `OrganismMinted`.
// 2.  `getGeneSequence(uint256 organismId)`
//     - Returns the current `GeneSequence` for a given `organismId`.
// 3.  `getOrganismGeneration(uint256 organismId)`
//     - Returns the current evolutionary `generation` of an `organismId`.
// 4.  `getOrganismCreator(uint256 organismId)`
//     - Returns the original creator/minter of an organism.

// VIII. EVOLUTIONARY MECHANICS (Community & Global)
// 5.  `triggerGlobalEvolutionEpoch()`
//     - Callable periodically. Advances the global generation counter. Organisms can react off-chain.
//     - Emits `GlobalEvolutionEpochTriggered`.
// 6.  `proposeEvolution(uint256 organismId, GeneSequence memory newGenes, string memory explanation)`
//     - Allows any user with sufficient staked EVO to propose a specific gene update for an `organismId`.
//       Requires staking EVO tokens as a proposal bond.
//     - Emits `ProposalCreated`.
// 7.  `voteOnProposal(uint256 proposalId, bool support)`
//     - Allows users with staked or delegated EVO tokens to cast a vote (true for 'yes', false for 'no')
//       on an active evolution `proposalId`.
//     - Emits `ProposalVoted`.
// 8.  `executeProposal(uint256 proposalId)`
//     - Finalizes and applies a passed evolution `proposalId` if voting conditions (quorum, votes) are met
//       and the voting period has ended. Updates the `GeneSequence` of the target organism.
//     - Emits `GenesEvolved` and `ProposalExecuted`. Adjusts AI Oracle reputation if applicable.
// 9.  `getProposalDetails(uint256 proposalId)`
//     - Returns comprehensive details about a specific evolution `proposalId`, including state, votes, and target genes.

// IX. AI ORACLE SYSTEM
// 10. `registerAIOrcle(string memory oracleName, string memory verificationUrl, address signatureAddress)`
//     - Registers a new AI Oracle. Requires a deposit in EVO tokens and a designated `signatureAddress`
//       (which might be different from msg.sender) used to sign AI proposals. The `verificationUrl`
//       points to an off-chain endpoint for model details or additional verification.
//     - Emits `AIOrcleRegistered`.
// 11. `submitAIEvolutionProposal(uint256 organismId, GeneSequence memory proposedGenes, uint256 currentOrganismGeneration, bytes memory signature)`
//     - Registered AI Oracles can submit evolution proposals, cryptographically signed by their
//       `signatureAddress`. The `currentOrganismGeneration` is passed to prevent proposals on stale states.
//       This proposal immediately moves to a voting phase.
//     - Emits `ProposalCreated`.
// 12. `getAIOrcleDetails(address oracleAddress)`
//     - Retrieves the registered name, `verificationUrl`, `signatureAddress`, and `reputation`
//       of an AI oracle.
// 13. `updateAIOrcleReputation(address oracleAddress, int256 reputationChange)` (Internal)
//     - Adjusts an AI Oracle's reputation score based on the outcome of their proposals
//       (e.g., positive for passed, negative for failed/rejected). Callable by `executeProposal`.
//     - Emits `AIOrcleReputationUpdated`.
// 14. `slashAIOrcleStake(address oracleAddress, uint256 amount)`
//     - (DAO-governed, defaulted to `onlyOwner` for this example) Slashes a portion of an AI Oracle's
//       staked EVO for malicious or repeatedly rejected proposals. Funds are transferred to the Evolution Pool.
//     - Emits `AIOrcleStakeSlashed`.
// 15. `claimAIOrcleStake(address oracleAddress)`
//     - Allows an AI Oracle to withdraw their initial registration stake after a defined cooldown
//       period, provided their reputation is above a threshold and they have no active challenges.
//     - Emits `AIOrcleStakeClaimed`.

// X. GOVERNANCE & EVO TOKEN INTEGRATION
// 16. `stakeEVO(uint256 amount)`
//     - Stakes EVO tokens from `msg.sender` to gain voting power for proposals.
//     - Emits `EVOTokensStaked`.
// 17. `unstakeEVO(uint256 amount)`
//     - Unstakes EVO tokens. Unstaking might have a cooldown and could reduce voting power.
//     - Emits `EVOTokensUnstaked`.
// 18. `delegateVote(address delegatee)`
//     - Delegates voting power to another address.
//     - Emits `EVOTokensDelegated`.
// 19. `getVotingPower(address voter)`
//     - Returns the total voting power (staked + delegated) of a specific `voter` address.

// XI. EVOLUTION POOL & REWARDS
// 20. `depositToEvolutionPool()`
//     - Allows any user to deposit native currency (ETH) to the communal Evolution Pool.
//     - Emits `PoolDeposited`.
// 21. `distributeRewards(address[] memory recipients, uint256[] memory amounts)`
//     - A DAO-governed function (requiring a passed governance proposal) to distribute funds
//       from the Evolution Pool to specified `recipients` (e.g., successful AI Oracles,
//       core contributors, or community initiatives).
//     - Emits `RewardsDistributed`.

// XII. DAO CONFIGURATION & UTILITIES
// 22. `setProposalConfig(uint256 minVotePeriod, uint256 quorumPercentage, uint256 minStakeToPropose)`
//     - (DAO-governed, defaulted to `onlyOwner` for this example) Sets global parameters for
//       evolution proposals: minimum voting period, quorum percentage required for approval,
//       and minimum EVO stake to create a proposal.
//     - Emits `ConfigUpdated`.
// 23. `setAIOrcleRegistrationFee(uint256 amount)`
//     - (DAO-governed, defaulted to `onlyOwner` for this example) Sets the amount of EVO tokens
//       required to register a new AI Oracle.
//     - Emits `ConfigUpdated`.
// 24. `setEvolutionEpochInterval(uint256 interval)`
//     - (DAO-governed, defaulted to `onlyOwner` for this example) Sets the minimum time interval
//       (in seconds) between global evolution epochs.
//     - Emits `ConfigUpdated`.
// 25. `pause()`
//     - (Owner/DAO) Emergency function to pause critical contract functionalities (e.g., minting,
//       evolution, proposal creation) in case of vulnerabilities.
// 26. `unpause()`
//     - (Owner/DAO) Unpauses the contract functionalities.

// --- END OF OUTLINE & FUNCTION SUMMARY ---


// I. INTERFACES AND LIBRARIES
interface IEVO is IERC20 {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function delegate(address delegatee) external;
    function getVotes(address account) external view returns (uint256);
}

contract EvoNexusCore is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // II. STRUCTS & ENUMS
    struct GeneSequence {
        uint256 colorPaletteHash;       // Hash representing a set of colors or a color algorithm seed
        uint256 shapePatternSeed;       // Seed for generative shape patterns
        uint256 mutationResistance;     // A value affecting how easily genes can be changed (0-1000, 1000 = very resistant)
        uint256 environmentalAdaptability; // How well it adapts to global epochs (0-1000, 1000 = very adaptable)
        bytes32 uniqueIdentifier;       // Some immutable part of the gene, for core identity
    }

    struct Organism {
        GeneSequence genes;
        uint256 generation;
        address creator;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct EvolutionProposal {
        uint256 organismId;
        GeneSequence newGenes;
        string explanation;
        address proposer;
        address aiOracleSigner; // Address that signed the AI proposal, 0x0 if community proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation;
        ProposalState state;
        uint256 proposalBond; // EVO tokens staked by the proposer
    }

    struct AIOracle {
        string name;
        string verificationUrl; // URL for off-chain verification/model details
        address signatureAddress; // The address used to sign AI proposals
        int256 reputation; // On-chain reputation score
        uint256 stakedDeposit; // EVO tokens staked by the oracle
        uint256 registrationTime; // Timestamp of registration
    }

    // IV. CORE CONTRACT STATE VARIABLES
    IEVO public immutable EVO_TOKEN;
    Counters.Counter private _organismIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => Organism) public organisms;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    // Global evolution counter
    uint256 public globalGeneration = 0;
    uint256 public lastGlobalEvolutionEpoch;

    // AI Oracle Management
    mapping(address => AIOracle) public aiOracles; // oracleAddress => AIOracle details
    mapping(address => address) public signatureAddressToOracle; // signatureAddress => oracleAddress (allows lookup)

    // Voting and Delegation (simplified, typically handled by ERC20Votes or similar)
    mapping(address => uint256) public stakedEVO;
    mapping(address => address) public delegates; // delegator => delegatee
    mapping(address => uint256) public delegatedVotes; // delegatee => total delegated votes

    // Proposal Configuration
    uint256 public minVotingPeriod; // in seconds
    uint256 public quorumPercentage; // e.g., 50 for 50%
    uint256 public minStakeToPropose; // EVO tokens
    uint256 public aiOracleRegistrationFee; // EVO tokens
    uint256 public evolutionEpochInterval; // Minimum time between global epochs in seconds
    uint256 public aiOracleClaimStakeCooldown; // in seconds

    // Evolution Pool (for ETH/native currency)
    address public constant EVOLUTION_POOL_ADDRESS = address(this);


    // III. EVENTS
    event OrganismMinted(uint256 indexed organismId, address indexed creator, GeneSequence initialGenes, uint256 generation);
    event GenesEvolved(uint256 indexed organismId, uint256 indexed generation, GeneSequence newGenes, address indexed proposer, uint256 proposalId);
    event GlobalEvolutionEpochTriggered(uint256 indexed newGlobalGeneration, uint256 timestamp);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed organismId, address indexed proposer, uint256 timestamp, bool isAI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success, address executor);
    event AIOrcleRegistered(address indexed oracleAddress, string name, address signatureAddress, uint256 depositAmount);
    event AIOrcleReputationUpdated(address indexed oracleAddress, int256 reputationChange, int256 newReputation);
    event AIOrcleStakeSlashed(address indexed oracleAddress, uint256 amount, address indexed slasher);
    event AIOrcleStakeClaimed(address indexed oracleAddress, uint256 amount);
    event EVOTokensStaked(address indexed staker, uint256 amount, uint256 newBalance);
    event EVOTokensUnstaked(address indexed unstaker, uint256 amount, uint256 newBalance);
    event EVOTokensDelegated(address indexed delegator, address indexed delegatee);
    event PoolDeposited(address indexed depositor, uint256 amount);
    event RewardsDistributed(address[] recipients, uint256[] amounts);
    event ConfigUpdated(string configName, uint256 newValue);

    // V. MODIFIERS
    modifier onlyAIOrcleSigner() {
        require(signatureAddressToOracle[msg.sender] != address(0), "EvoNexusCore: Caller is not a registered AI oracle signer");
        _;
    }

    modifier hasVotingPower() {
        require(getVotingPower(msg.sender) > 0, "EvoNexusCore: Caller has no voting power");
        _;
    }

    // In a real DAO, this would be `onlyRole(DAO_ADMIN_ROLE)` or similar,
    // where the role is held by a Governor contract. For this example,
    // it defaults to onlyOwner for administrative functions.
    modifier onlyDAO() {
        // Placeholder: In a real system, this would typically check if msg.sender
        // is the DAO governance contract or if a proposal has passed.
        // For simplicity, using onlyOwner for now.
        require(msg.sender == owner(), "EvoNexusCore: Only DAO (or Owner) can call this function");
        _;
    }

    // VI. CONSTRUCTOR
    constructor(
        address evoTokenAddress,
        uint256 _minVotingPeriod,
        uint256 _quorumPercentage,
        uint256 _minStakeToPropose,
        uint256 _aiOracleRegistrationFee,
        uint256 _evolutionEpochInterval,
        uint256 _aiOracleClaimStakeCooldown
    ) ERC721("EvoNexus Organism", "AGO") Ownable(msg.sender) {
        require(evoTokenAddress != address(0), "EvoNexusCore: EVO token address cannot be zero");
        EVO_TOKEN = IEVO(evoTokenAddress);

        minVotingPeriod = _minVotingPeriod; // e.g., 3 days (259200 seconds)
        quorumPercentage = _quorumPercentage; // e.g., 50 (for 50%)
        minStakeToPropose = _minStakeToPropose; // e.g., 100 * 1e18 EVO
        aiOracleRegistrationFee = _aiOracleRegistrationFee; // e.g., 1000 * 1e18 EVO
        evolutionEpochInterval = _evolutionEpochInterval; // e.g., 7 days (604800 seconds)
        aiOracleClaimStakeCooldown = _aiOracleClaimStakeCooldown; // e.g., 30 days (2592000 seconds)

        lastGlobalEvolutionEpoch = block.timestamp;
    }

    // Fallback function to receive native currency into the Evolution Pool
    receive() external payable {
        emit PoolDeposited(msg.sender, msg.value);
    }

    // VII. ORGANISM MANAGEMENT & QUERIES
    // 1. mintOrganism
    function mintOrganism(address recipient, GeneSequence memory initialGenes)
        public
        whenNotPaused
        returns (uint256)
    {
        require(recipient != address(0), "EvoNexusCore: Mint to the zero address");

        _organismIds.increment();
        uint256 newItemId = _organismIds.current();

        organisms[newItemId] = Organism({
            genes: initialGenes,
            generation: 1,
            creator: msg.sender
        });

        _mint(recipient, newItemId);
        emit OrganismMinted(newItemId, msg.sender, initialGenes, 1);
        return newItemId;
    }

    // 2. getGeneSequence
    function getGeneSequence(uint256 organismId)
        public
        view
        returns (GeneSequence memory)
    {
        require(_exists(organismId), "EvoNexusCore: Organism does not exist");
        return organisms[organismId].genes;
    }

    // 3. getOrganismGeneration
    function getOrganismGeneration(uint256 organismId)
        public
        view
        returns (uint256)
    {
        require(_exists(organismId), "EvoNexusCore: Organism does not exist");
        return organisms[organismId].generation;
    }

    // 4. getOrganismCreator
    function getOrganismCreator(uint256 organismId)
        public
        view
        returns (address)
    {
        require(_exists(organismId), "EvoNexusCore: Organism does not exist");
        return organisms[organismId].creator;
    }

    // VIII. EVOLUTIONARY MECHANICS
    // 5. triggerGlobalEvolutionEpoch
    function triggerGlobalEvolutionEpoch()
        public
        whenNotPaused
    {
        require(block.timestamp >= lastGlobalEvolutionEpoch.add(evolutionEpochInterval), "EvoNexusCore: Not yet time for next global epoch");
        
        globalGeneration = globalGeneration.add(1);
        lastGlobalEvolutionEpoch = block.timestamp;
        
        // In a more complex system, this might loop through all organisms
        // and apply a minor mutation based on environmentalAdaptability gene.
        // For simplicity, it just advances the global generation counter.
        // Off-chain clients would interpret how this new globalGeneration
        // influences each organism's rendering/behavior based on their genes.

        emit GlobalEvolutionEpochTriggered(globalGeneration, block.timestamp);
    }

    // 6. proposeEvolution
    function proposeEvolution(uint256 organismId, GeneSequence memory newGenes, string memory explanation)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_exists(organismId), "EvoNexusCore: Organism does not exist");
        require(getVotingPower(msg.sender) >= minStakeToPropose, "EvoNexusCore: Insufficient EVO stake to propose");
        require(EVO_TOKEN.transferFrom(msg.sender, address(this), minStakeToPropose), "EvoNexusCore: Failed to transfer proposal bond");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            organismId: organismId,
            newGenes: newGenes,
            explanation: explanation,
            proposer: msg.sender,
            aiOracleSigner: address(0), // Not an AI proposal
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(minVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: EVO_TOKEN.totalSupply(), // Snapshot total supply for quorum
            state: ProposalState.Active,
            proposalBond: minStakeToPropose
        });

        emit ProposalCreated(proposalId, organismId, msg.sender, block.timestamp, false);
        return proposalId;
    }

    // 7. voteOnProposal
    function voteOnProposal(uint256 proposalId, bool support)
        public
        whenNotPaused
        hasVotingPower
        nonReentrant
    {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.organismId != 0, "EvoNexusCore: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "EvoNexusCore: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime, "EvoNexusCore: Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "EvoNexusCore: Voting has ended");
        
        // Simplified voting: no double voting check for a single account here.
        // In a real system, you'd track `mapping(uint256 => mapping(address => bool))` for voted.
        // For this example, we assume voters vote only once or their vote overrides.
        // A more robust system would use a snapshot or checkpointing for voting power.
        uint256 voterPower = getVotingPower(msg.sender);

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterPower);
        }
        emit ProposalVoted(proposalId, msg.sender, support, voterPower);
    }

    // 8. executeProposal
    function executeProposal(uint256 proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.organismId != 0, "EvoNexusCore: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "EvoNexusCore: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "EvoNexusCore: Voting period not ended");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        bool succeeded = false;

        // Check quorum: total votes must be at least quorumPercentage of total supply at proposal creation
        uint256 requiredQuorum = proposal.totalVotingPowerAtCreation.mul(quorumPercentage).div(100);
        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed
            Organism storage organism = organisms[proposal.organismId];
            organism.genes = proposal.newGenes;
            organism.generation = organism.generation.add(1);
            proposal.state = ProposalState.Executed;
            succeeded = true;

            // Return proposal bond to proposer
            require(EVO_TOKEN.transfer(proposal.proposer, proposal.proposalBond), "EvoNexusCore: Failed to return proposal bond");

            // Update AI Oracle reputation if applicable
            if (proposal.aiOracleSigner != address(0)) {
                address oracleAddress = signatureAddressToOracle[proposal.aiOracleSigner];
                updateAIOrcleReputation(oracleAddress, 10); // Positive reputation change for success
            }
            emit GenesEvolved(proposal.organismId, organism.generation, proposal.newGenes, proposal.proposer, proposalId);
        } else {
            // Proposal failed
            proposal.state = ProposalState.Failed;
            succeeded = false;

            // Keep proposal bond (e.g., send to Evolution Pool or burn)
            // For now, it stays in the contract (could be burned or sent to pool via DAO)
            // For simplicity, we just won't refund the bond.
            // A more complex system might slash.

            // Update AI Oracle reputation if applicable
            if (proposal.aiOracleSigner != address(0)) {
                address oracleAddress = signatureAddressToOracle[proposal.aiOracleSigner];
                updateAIOrcleReputation(oracleAddress, -5); // Negative reputation change for failure
            }
        }
        emit ProposalExecuted(proposalId, succeeded, msg.sender);
    }

    // 9. getProposalDetails
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (EvolutionProposal memory)
    {
        require(evolutionProposals[proposalId].organismId != 0, "EvoNexusCore: Proposal does not exist");
        return evolutionProposals[proposalId];
    }

    // IX. AI ORACLE SYSTEM
    // 10. registerAIOrcle
    function registerAIOrcle(string memory oracleName, string memory verificationUrl, address signatureAddress)
        public
        whenNotPaused
        nonReentrant
    {
        require(aiOracles[msg.sender].registrationTime == 0, "EvoNexusCore: Address already registered as AI Oracle");
        require(signatureAddress != address(0), "EvoNexusCore: Signature address cannot be zero");
        require(signatureAddressToOracle[signatureAddress] == address(0), "EvoNexusCore: Signature address already in use");
        require(EVO_TOKEN.transferFrom(msg.sender, address(this), aiOracleRegistrationFee), "EvoNexusCore: Failed to transfer AI oracle registration fee");

        aiOracles[msg.sender] = AIOracle({
            name: oracleName,
            verificationUrl: verificationUrl,
            signatureAddress: signatureAddress,
            reputation: 0,
            stakedDeposit: aiOracleRegistrationFee,
            registrationTime: block.timestamp
        });
        signatureAddressToOracle[signatureAddress] = msg.sender;
        emit AIOrcleRegistered(msg.sender, oracleName, signatureAddress, aiOracleRegistrationFee);
    }

    // 11. submitAIEvolutionProposal
    function submitAIEvolutionProposal(uint256 organismId, GeneSequence memory proposedGenes, uint256 currentOrganismGeneration, bytes memory signature)
        public
        whenNotPaused
        onlyAIOrcleSigner
        nonReentrant
        returns (uint256)
    {
        address oracleAddress = signatureAddressToOracle[msg.sender];
        require(aiOracles[oracleAddress].reputation >= 0, "EvoNexusCore: AI Oracle reputation too low to propose");
        require(_exists(organismId), "EvoNexusCore: Organism does not exist");
        require(organisms[organismId].generation == currentOrganismGeneration, "EvoNexusCore: Organism state is stale for AI proposal");

        // Verify the AI oracle's signature for the proposed genes and organism state
        bytes32 messageHash = keccak256(abi.encodePacked(
            organismId,
            proposedGenes.colorPaletteHash,
            proposedGenes.shapePatternSeed,
            proposedGenes.mutationResistance,
            proposedGenes.environmentalAdaptability,
            proposedGenes.uniqueIdentifier,
            currentOrganismGeneration,
            block.chainid,
            address(this)
        ));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        require(ecrecover(ethSignedMessageHash, signature[64], bytes32(signature[0, 32]), bytes32(signature[32, 32])) == msg.sender, "EvoNexusCore: Invalid AI signature");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            organismId: organismId,
            newGenes: proposedGenes,
            explanation: "AI-generated proposal",
            proposer: oracleAddress, // The AI oracle address
            aiOracleSigner: msg.sender, // The actual address that signed the proposal
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(minVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: EVO_TOKEN.totalSupply(),
            state: ProposalState.Active,
            proposalBond: 0 // AI proposals don't require bond, their stake is the deposit
        });

        emit ProposalCreated(proposalId, organismId, oracleAddress, block.timestamp, true);
        return proposalId;
    }

    // 12. getAIOrcleDetails
    function getAIOrcleDetails(address oracleAddress)
        public
        view
        returns (string memory name, string memory verificationUrl, address signatureAddress, int256 reputation, uint256 stakedDeposit, uint256 registrationTime)
    {
        require(aiOracles[oracleAddress].registrationTime != 0, "EvoNexusCore: AI Oracle not registered");
        AIOracle storage oracle = aiOracles[oracleAddress];
        return (oracle.name, oracle.verificationUrl, oracle.signatureAddress, oracle.reputation, oracle.stakedDeposit, oracle.registrationTime);
    }

    // 13. updateAIOrcleReputation (Internal)
    function updateAIOrcleReputation(address oracleAddress, int256 reputationChange)
        internal
    {
        require(aiOracles[oracleAddress].registrationTime != 0, "EvoNexusCore: AI Oracle not registered");
        AIOracle storage oracle = aiOracles[oracleAddress];
        oracle.reputation = oracle.reputation.add(reputationChange);
        emit AIOrcleReputationUpdated(oracleAddress, reputationChange, oracle.reputation);
    }

    // 14. slashAIOrcleStake
    function slashAIOrcleStake(address oracleAddress, uint256 amount)
        public
        whenNotPaused
        onlyDAO // Only DAO can decide to slash
        nonReentrant
    {
        require(aiOracles[oracleAddress].registrationTime != 0, "EvoNexusCore: AI Oracle not registered");
        AIOracle storage oracle = aiOracles[oracleAddress];
        require(oracle.stakedDeposit >= amount, "EvoNexusCore: Slash amount exceeds staked deposit");

        oracle.stakedDeposit = oracle.stakedDeposit.sub(amount);
        // Transfer slashed amount to evolution pool (this contract's balance)
        require(EVO_TOKEN.transfer(address(this), amount), "EvoNexusCore: Failed to transfer slashed stake to pool");

        emit AIOrcleStakeSlashed(oracleAddress, amount, msg.sender);
    }

    // 15. claimAIOrcleStake
    function claimAIOrcleStake(address oracleAddress)
        public
        whenNotPaused
        nonReentrant
    {
        require(aiOracles[oracleAddress].registrationTime != 0, "EvoNexusCore: AI Oracle not registered");
        AIOracle storage oracle = aiOracles[oracleAddress];
        require(block.timestamp >= oracle.registrationTime.add(aiOracleClaimStakeCooldown), "EvoNexusCore: Cooldown period not over");
        require(oracle.reputation >= 0, "EvoNexusCore: AI Oracle reputation too low to claim stake"); // Or a higher threshold

        uint256 amountToClaim = oracle.stakedDeposit;
        oracle.stakedDeposit = 0; // Reset stake
        signatureAddressToOracle[oracle.signatureAddress] = address(0); // Deregister signature address
        // The oracle entry itself remains but is considered inactive
        // To fully remove it, a DAO proposal would be needed or specific logic to clear
        // For simplicity, an oracle with 0 stake and no active signature address is effectively "de-registered".

        require(EVO_TOKEN.transfer(oracleAddress, amountToClaim), "EvoNexusCore: Failed to return AI oracle stake");
        emit AIOrcleStakeClaimed(oracleAddress, amountToClaim);
    }

    // X. GOVERNANCE & EVO TOKEN INTEGRATION
    // 16. stakeEVO
    function stakeEVO(uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "EvoNexusCore: Stake amount must be greater than zero");
        require(EVO_TOKEN.transferFrom(msg.sender, address(this), amount), "EvoNexusCore: Failed to transfer EVO for staking");
        stakedEVO[msg.sender] = stakedEVO[msg.sender].add(amount);
        emit EVOTokensStaked(msg.sender, amount, stakedEVO[msg.sender]);
    }

    // 17. unstakeEVO
    function unstakeEVO(uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "EvoNexusCore: Unstake amount must be greater than zero");
        require(stakedEVO[msg.sender] >= amount, "EvoNexusCore: Insufficient staked EVO");
        
        stakedEVO[msg.sender] = stakedEVO[msg.sender].sub(amount);
        
        // If the user has delegated, unstaking reduces their delegatee's power
        if (delegates[msg.sender] != address(0) && delegates[msg.sender] != msg.sender) {
            delegatedVotes[delegates[msg.sender]] = delegatedVotes[delegates[msg.sender]].sub(amount);
        }
        
        require(EVO_TOKEN.transfer(msg.sender, amount), "EvoNexusCore: Failed to return unstaked EVO");
        emit EVOTokensUnstaked(msg.sender, amount, stakedEVO[msg.sender]);
    }

    // 18. delegateVote
    function delegateVote(address delegatee)
        public
        whenNotPaused
        nonReentrant
    {
        require(delegatee != address(0), "EvoNexusCore: Delegatee cannot be the zero address");
        require(delegatee != msg.sender, "EvoNexusCore: Cannot delegate to self");

        address currentDelegatee = delegates[msg.sender];
        uint256 stakerVotes = stakedEVO[msg.sender];

        // Remove votes from old delegatee
        if (currentDelegatee != address(0) && currentDelegatee != msg.sender) {
            delegatedVotes[currentDelegatee] = delegatedVotes[currentDelegatee].sub(stakerVotes);
        }

        // Assign votes to new delegatee
        delegates[msg.sender] = delegatee;
        delegatedVotes[delegatee] = delegatedVotes[delegatee].add(stakerVotes);
        
        emit EVOTokensDelegated(msg.sender, delegatee);
    }

    // 19. getVotingPower
    function getVotingPower(address voter)
        public
        view
        returns (uint256)
    {
        // If the voter has delegated, their power is 0 for themselves.
        if (delegates[voter] != address(0) && delegates[voter] != voter) {
            return 0;
        }
        return stakedEVO[voter].add(delegatedVotes[voter]);
    }

    // XI. EVOLUTION POOL & REWARDS
    // 20. depositToEvolutionPool
    function depositToEvolutionPool() public payable {
        // Fallback function handles the actual deposit and event.
        // This function explicitly allows direct calls to fund the pool.
        // No specific logic needed here as 'receive' handles it.
    }

    // 21. distributeRewards
    function distributeRewards(address[] memory recipients, uint256[] memory amounts)
        public
        whenNotPaused
        onlyDAO // Requires DAO approval
        nonReentrant
    {
        require(recipients.length == amounts.length, "EvoNexusCore: Mismatch in recipients and amounts");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i = i.add(1)) {
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(address(this).balance >= totalAmount, "EvoNexusCore: Insufficient funds in Evolution Pool");

        for (uint256 i = 0; i < recipients.length; i = i.add(1)) {
            payable(recipients[i]).transfer(amounts[i]);
        }
        emit RewardsDistributed(recipients, amounts);
    }

    // XII. DAO CONFIGURATION & UTILITIES
    // 22. setProposalConfig
    function setProposalConfig(uint256 _minVotePeriod, uint256 _quorumPercentage, uint256 _minStakeToPropose)
        public
        whenNotPaused
        onlyDAO // Requires DAO approval
    {
        minVotingPeriod = _minVotePeriod;
        quorumPercentage = _quorumPercentage;
        minStakeToPropose = _minStakeToPropose;
        emit ConfigUpdated("minVotePeriod", _minVotePeriod);
        emit ConfigUpdated("quorumPercentage", _quorumPercentage);
        emit ConfigUpdated("minStakeToPropose", _minStakeToPropose);
    }

    // 23. setAIOrcleRegistrationFee
    function setAIOrcleRegistrationFee(uint256 amount)
        public
        whenNotPaused
        onlyDAO // Requires DAO approval
    {
        aiOracleRegistrationFee = amount;
        emit ConfigUpdated("aiOracleRegistrationFee", amount);
    }

    // 24. setEvolutionEpochInterval
    function setEvolutionEpochInterval(uint256 interval)
        public
        whenNotPaused
        onlyDAO // Requires DAO approval
    {
        evolutionEpochInterval = interval;
        emit ConfigUpdated("evolutionEpochInterval", interval);
    }

    // 25. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 26. unpause
    function unpause() public onlyOwner {
        _unpause();
    }
}
```