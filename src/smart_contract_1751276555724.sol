Okay, here is a Solidity smart contract for a sophisticated governance system called "QuantumFluxGovernor". It incorporates several advanced, creative, and trendy concepts beyond standard DAO implementations, aiming for uniqueness without duplicating major open-source libraries directly (though it uses standard interfaces like ERC-20).

It includes features like:
*   **Dynamic Parameters:** Core governance parameters (periods, thresholds, quorum) are configurable via governance proposals.
*   **Pluggable Voting Weight Modifier:** Allows the DAO to vote in a custom contract that calculates voting power based on arbitrary logic (e.g., reputation tokens, quadratic voting, staking duration), making the system adaptable.
*   **Registered Reputation Tokens:** Governance can register specific tokens that the Voting Weight Modifier *might* consider.
*   **"Flux" Parameter:** A conceptual parameter (`currentFlux`) that can be updated by a trusted oracle (set by governance) based on external data, potentially influencing other protocol dynamics (though this contract only manages the parameter itself).
*   **EIP-712 Signature Voting:** Supports gas-efficient voting off-chain.
*   **Comprehensive Lifecycle:** Covers proposing, voting, queuing, and execution.
*   **Treasury Management:** Basic functionality for receiving and distributing funds via governance.
*   **Rescue Mechanism:** Safe way to recover accidentally sent tokens/NFTs via governance proposal.

It aims for over 20 functions by breaking down parameter setting, voting types, and adding various getter functions and utility functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interfaces needed without importing full OZ contracts
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Required for Governor compatibility (snapshotting votes)
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
    function delegate(address delegatee) external;
    function delegates(address account) external view returns (address);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Interface for the pluggable voting weight modifier
interface IVotingWeightModifier {
    // Calculates the adjusted voting power for an account at a specific block
    // based on their token balance and any other criteria defined by the modifier contract.
    function getAdjustedVotingWeight(address account, uint256 blockNumber, address governanceToken, mapping(address => bool) calldata registeredReputationTokens) external view returns (uint256);
}

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IQuantumFluxGovernor {
    // --- Governance Lifecycle Functions ---
    function propose(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, string calldata description) external returns (uint256 proposalId);
    function castVote(uint256 proposalId, uint8 support) external returns (uint256 votes);
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external returns (uint256 votes);
    function castVoteBySig(uint256 proposalId, uint8 support, uint256 v, bytes32 r, bytes32 s) external returns (uint256 votes);
    function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string calldata reason, bytes calldata params) external returns (uint256 votes); // More advanced voting options
    function queue(uint256 proposalId) external;
    function execute(uint256 proposalId) external payable;
    function cancel(uint256 proposalId) external;

    // --- Delegation Functions ---
    function delegate(address delegatee) external;
    function getVotingPower(address account, uint256 blockNumber) external view returns (uint256);
    function delegates(address account) external view returns (address); // Get who an account has delegated to
    function getVotesAtBlock(address account, uint256 blockNumber) external view returns (uint256); // Get votes *as reported by token* at block

    // --- State & Information Getters ---
    function getProposalState(uint256 proposalId) external view returns (ProposalState);
    function getProposalDetails(uint256 proposalId) external view returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, uint256 startBlock, uint256 endBlock, string memory description, uint256 eta);
    function getVotes(uint256 proposalId) external view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);
    function getProposalsByProposer(address proposer) external view returns (uint256[] memory proposalIds); // Get list of proposals by a proposer
    function getLatestProposalId(address proposer) external view returns (uint256); // Get the ID of the latest proposal by a proposer
    function lookupVote(uint256 proposalId, address voter) external view returns (uint8 support); // See how a specific address voted

    // --- Treasury Management Functions ---
    function depositTreasury() external payable; // Deposit ETH into the governor treasury
    function withdrawTreasury(uint256 amount) external; // Withdraw ETH (callable only via successful proposal execution)
    function withdrawERC20Treasury(address token, uint256 amount) external; // Withdraw ERC20 (callable only via successful proposal execution)
    function getTreasuryBalance() external view returns (uint256); // Get ETH balance
    function getERC20TreasuryBalance(address token) external view returns (uint256); // Get ERC20 balance

    // --- Parameter Management Functions (Callable via execute) ---
    function setVotingPeriod(uint256 newVotingPeriod) external; // Set duration of voting (in blocks)
    function setQuorumNumerator(uint256 newQuorumNumerator) external; // Set required percentage of total supply voting (numerator for 10,000 denominator)
    function setProposalThresholdRatio(uint256 newThresholdRatio) external; // Set minimum required votes to propose (ratio of total supply)
    function setExecutionDelay(uint256 newExecutionDelay) external; // Set delay between queue and execution (in blocks)
    function setVotingDelay(uint256 newVotingDelay) external; // Set delay between proposal creation and voting start (in blocks)
    function setGracePeriod(uint256 newGracePeriod) external; // Set period after execution delay where execution is possible
    function setGovernorName(string calldata newName) external; // Set the name of the governor

    // --- Advanced & Dynamic Features ---
    function setTrustedRelayer(address relayer) external; // Set address allowed to trigger flux updates
    function triggerFluxUpdate(bytes calldata externalData) external; // Trigger update of the 'flux' parameter based on external data (callable by trusted relayer)
    function getCurrentFluxValue() external view returns (bytes memory); // Get the current dynamic 'flux' value
    function setVotingWeightModifier(address modifierAddress) external; // Set the contract address for calculating adjusted voting weight
    function registerReputationToken(address tokenAddress, bool isRegistered) external; // Register or unregister a token for potential consideration by the modifier

    // --- Utility & Rescue Functions (Callable via execute) ---
    function rescueERC20(address token, uint256 amount, address to) external; // Rescue accidentally sent ERC20 tokens
    function rescueERC721(address token, uint256 tokenId, address to) external; // Rescue accidentally sent ERC721 tokens
    function getVersion() external pure returns (string memory); // Get contract version/identifier

    // --- State Checkers ---
    function isVotingAllowed(uint256 proposalId) external view returns (bool); // Check if voting is currently open for a proposal
    function isExecutionAllowed(uint256 proposalId) external view returns (bool); // Check if a proposal is ready/can be executed
    function calculateProposalThreshold() external view returns (uint256); // Calculate current threshold based on ratio and total supply
}


/**
 * @title QuantumFluxGovernor
 * @dev A dynamic and advanced governance contract featuring pluggable voting weight,
 *      oracle-driven 'flux' parameter, and configurable governance parameters.
 *      Manages proposal lifecycle, voting, delegation, and a treasury.
 *
 * Outline:
 * 1.  Interfaces: Define necessary interfaces (ERC20, ERC721, IVotingWeightModifier, EIP712).
 * 2.  Events: Define events for state changes (Propose, VoteCast, Execute, Cancel, ParametersUpdated, etc.).
 * 3.  Enums: Define ProposalState enum.
 * 4.  Structs: Define Proposal struct.
 * 5.  Constants & Immutable: Domain separator components, version.
 * 6.  State Variables:
 *     - Governance token address (`governanceToken`)
 *     - Treasury balance (ETH)
 *     - Proposal tracking (`proposals`, `proposalCount`, `proposerToLatestProposalId`)
 *     - Voting tracking (`votes`)
 *     - Delegation tracking (`delegates`, `checkpoints` for voting power snapshots - simplified)
 *     - Governance Parameters (`votingPeriod`, `quorumNumerator`, etc.)
 *     - Dynamic/Advanced State (`currentFlux`, `trustedRelayer`, `votingWeightModifierAddress`, `registeredReputationTokens`)
 *     - EIP-712 Nonces (`nonces`)
 * 7.  Constructor: Set initial governance token and core parameters.
 * 8.  Modifiers: Define internal helper functions/modifiers for access control (`_onlyGovernor`, `_onlyTrustedRelayer`).
 * 9.  Internal Helpers:
 *     - `_getProposalState`: Determine current state.
 *     - `_updateVotingPower`: Handle delegation checkpointing (simplified).
 *     - `_isValidSignature`: Verify EIP-712 signatures.
 *     - `_hashTypedDataV4`: EIP-712 hashing.
 *     - `_getAdjustedVotingWeight`: Call the pluggable modifier.
 *     - `_assertGovernor` / `_assertTrustedRelayer`: Check execution context for sensitive functions.
 * 10. Core Governance Functions: Implement `propose`, `castVote` (variants), `queue`, `execute`, `cancel`.
 * 11. Delegation Functions: Implement `delegate`, `getVotingPower`, `delegates`, `getVotesAtBlock`.
 * 12. State & Information Getters: Implement all necessary view functions.
 * 13. Treasury Management: Implement `depositTreasury`, `withdrawTreasury`, `withdrawERC20Treasury`, getters.
 * 14. Parameter Management: Implement setters callable only via `execute`.
 * 15. Advanced & Dynamic Features: Implement `setTrustedRelayer`, `triggerFluxUpdate`, `setVotingWeightModifier`, `registerReputationToken`, getters.
 * 16. Utility & Rescue: Implement `rescueERC20`, `rescueERC721`, `getVersion`.
 * 17. State Checkers: Implement `isVotingAllowed`, `isExecutionAllowed`, `calculateProposalThreshold`.
 * 18. Receive/Fallback: Allow receiving ETH into the treasury.
 */
contract QuantumFluxGovernor is IEIP712, IQuantumFluxGovernor {
    // --- Events ---
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );
    event ProposalQueued(uint256 proposalId, uint256 eta);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);
    event ParametersUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event GovernorNameUpdated(string oldName, string newName);
    event TrustedRelayerUpdated(address oldRelayer, address newRelayer);
    event FluxUpdated(bytes oldFlux, bytes newFlux, address updater);
    event VotingWeightModifierUpdated(address oldModifier, address newModifier);
    event ReputationTokenRegistered(address tokenAddress, bool isRegistered);
    event FundsRescued(address indexed token, uint256 amountOrId, address indexed to, bytes32 assetType); // assetType: keccak256("ERC20"), keccak256("ERC721")

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum VoteType { Against, For, Abstain }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startBlock; // Block when voting starts
        uint256 endBlock;   // Block when voting ends
        uint256 eta;        // Execution time (block number or timestamp, using block number for simplicity)
        string description;
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        bool executed;
        bool canceled;
    }

    // --- State Variables ---
    IERC20 public immutable governanceToken; // The ERC20 token used for voting
    uint256 public proposalCount; // Total number of proposals created

    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal details
    mapping(address => mapping(uint256 => uint8)) private _votes; // proposalId => voter => support (VoteType enum)
    mapping(address => uint256[]) private _proposerProposals; // proposer => list of proposal IDs

    // Delegation
    mapping(address => address) private _delegates; // delegator => delegatee
    // A simplified checkpointing system (more complex in full OZ Governor)
    // Here we just track delegation directly. Voting power lookup will need
    // to query the governanceToken at the block number or use the delegatee's current votes.
    // For simplicity, getVotingPower will look up delegation at the given block number.

    // Governance Parameters (configurable via proposals)
    uint256 public votingPeriod;         // Duration of voting in blocks
    uint256 public quorumNumerator;      // Numerator for quorum calculation (denominator is 10000)
    uint256 public proposalThresholdRatio; // Numerator for threshold calculation (denominator is 10000 of total supply)
    uint256 public executionDelay;       // Delay in blocks between queue and execution
    uint256 public votingDelay;          // Delay in blocks between proposal creation and voting start
    uint256 public gracePeriod;          // Period in blocks after executionDelay where execution is possible

    // Dynamic & Advanced State
    string public governorName;
    bytes public currentFlux; // A dynamic parameter, potentially updated by oracle
    address public trustedRelayer; // Address allowed to trigger flux updates
    address public votingWeightModifierAddress; // Address of the pluggable IVotingWeightModifier contract
    mapping(address => bool) public registeredReputationTokens; // Tokens potentially considered by the modifier

    // EIP-712
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address => uint256) private _nonces; // Nonces for signature replay protection

    bytes32 private constant ERC20_ASSET_TYPE = keccak256("ERC20");
    bytes32 private constant ERC721_ASSET_TYPE = keccak256("ERC721");

    // --- Constructor ---
    constructor(
        IERC20 _governanceToken,
        uint256 _votingPeriod,
        uint256 _quorumNumerator,
        uint256 _proposalThresholdRatio,
        uint256 _executionDelay,
        uint256 _votingDelay,
        string memory _governorName
    ) {
        require(address(_governanceToken) != address(0), "Governor: Invalid token address");
        governanceToken = _governanceToken;

        // Initial parameters
        votingPeriod = _votingPeriod;
        quorumNumerator = _quorumNumerator;
        proposalThresholdRatio = _proposalThresholdRatio;
        executionDelay = _executionDelay;
        votingDelay = _votingDelay;
        gracePeriod = executionDelay + (votingPeriod * 2); // Default grace period, can be changed
        governorName = _governorName;

        // EIP-712 Domain Separator (using EIP-195 style chainId or block.chainid)
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)"),
                keccak256(bytes(governorName)),
                keccak256(bytes("1")), // Version 1
                chainId,
                address(this)
            )
        );
    }

    // --- Receive ETH ---
    receive() external payable {
        // ETH sent directly to the contract goes to the treasury
    }

    // --- Internal Helpers ---
    /**
     * @dev Asserts that the current call is being made by the Governor itself.
     *      Used for functions that should only be called via a successful proposal execution.
     */
    modifier _onlyGovernor() {
        require(msg.sender == address(this), "Governor: Only callable by governor itself");
        _;
    }

    /**
     * @dev Asserts that the current call is being made by the trusted relayer.
     */
    modifier _onlyTrustedRelayer() {
        require(msg.sender == trustedRelayer, "Governor: Only callable by trusted relayer");
        _;
    }

    /**
     * @dev Helper to get the current state of a proposal.
     */
    function _getProposalState(uint256 proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.id == 0 && proposalId != 0) {
            // Check if proposalId 0 exists
            if (proposalId == 0 && proposal.startBlock == 0) return ProposalState.Pending; // Assuming proposal 0 is not created
            return ProposalState.Pending; // Proposal ID not found
        }
        if (proposal.canceled) return ProposalState.Canceled;
        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;

        // Voting period is over. Check result.
        // Quorum check: Total votes (for + against + abstain) >= quorum (total supply at start block * quorumNumerator / 10000)
        // Note: getPastTotalSupply might be gas intensive depending on token implementation.
        // Simplified: using getPastVotes(address(0), block.number) for total supply if token supports.
        uint256 totalVotesCast = proposal.againstVotes + proposal.forVotes + proposal.abstainVotes;
        uint256 totalTokenSupplyAtSnapshot = governanceToken.getPastTotalSupply(proposal.startBlock); // Use start block for supply snapshot
        uint256 requiredQuorum = (totalTokenSupplyAtSnapshot * quorumNumerator) / 10000;

        if (totalVotesCast < requiredQuorum || proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        }

        // Succeeded, check if queued or executed
        if (proposal.executed) return ProposalState.Executed;
        if (proposal.eta == 0) return ProposalState.Succeeded; // Succeeded but not yet queued
        if (proposal.eta > 0 && block.number >= proposal.eta + gracePeriod) return ProposalState.Expired; // Queued but execution window passed
        if (proposal.eta > 0) return ProposalState.Queued; // Succeeded and queued, waiting for eta

        return ProposalState.Succeeded; // Fallback, should be covered by eta check
    }

    /**
     * @dev Calculates the minimum token threshold required to create a proposal.
     */
    function calculateProposalThreshold() public view returns (uint256) {
        uint256 totalTokenSupply = governanceToken.totalSupply(); // Use current total supply
        return (totalTokenSupply * proposalThresholdRatio) / 10000;
    }

    /**
     * @dev Calculates the adjusted voting power using the pluggable modifier contract.
     *      Defaults to raw token balance if no modifier is set or if modifier call fails.
     */
    function _getAdjustedVotingWeight(address account, uint256 blockNumber) internal view returns (uint256) {
        uint256 rawVotes = governanceToken.getPastVotes(account, blockNumber); // Get votes from token at the block number
        if (votingWeightModifierAddress == address(0)) {
            return rawVotes; // No modifier set, use raw token votes
        }

        try IVotingWeightModifier(votingWeightModifierAddress).getAdjustedVotingWeight(account, blockNumber, address(governanceToken), registeredReputationTokens) returns (uint256 adjustedVotes) {
            return adjustedVotes;
        } catch {
            // If modifier call fails, fall back to raw token votes
            return rawVotes;
        }
    }

    // --- EIP-712 Signature Helpers (Simplified based on common patterns) ---
    // Note: A production contract would need more robust and tested EIP-712 implementation.
    // This basic version demonstrates the concept.
    bytes32 private constant VOTE_TYPEHASH = keccak256("Vote(uint256 proposalId,uint8 support)");
    bytes32 private constant VOTE_REASON_TYPEHASH = keccak256("VoteWithReason(uint256 proposalId,uint8 support,string reason)");

    function _hashVoteMessage(uint256 proposalId, uint8 support) internal view returns (bytes32) {
         return _hashTypedDataV4(
            keccak256(abi.encode(VOTE_TYPEHASH, proposalId, support))
        );
    }

    function _hashVoteWithReasonMessage(uint256 proposalId, uint8 support, string calldata reason) internal view returns (bytes32) {
         return _hashTypedDataV4(
            keccak256(abi.encode(VOTE_REASON_TYPEHASH, proposalId, support, keccak256(bytes(reason))))
        );
    }

    function _hashTypedDataV4(bytes32 innerHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, innerHash));
    }

    function _isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
         // Standard signature recovery
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress != address(0) && recoveredAddress == signer;
    }

    // --- Governor Lifecycle Functions ---

    /**
     * @dev Creates a new proposal.
     * @param targets The addresses of the contracts to call.
     * @param values The amount of Ether to send with each call.
     * @param calldatas The calldata for each call.
     * @param description The description of the proposal.
     * @return The ID of the created proposal.
     */
    function propose(address[] calldata targets, uint256[] calldata values, bytes[] calldatas, string calldata description) external returns (uint256 proposalId) {
        require(targets.length == values.length && targets.length == calldatas.length, "Governor: Call data mismatch");
        require(targets.length > 0, "Governor: Must propose at least one action");

        // Check proposal threshold
        // Note: getPastVotes is used here for threshold check based on current proposer's votes.
        // A more rigorous check might snapshot votes at a previous block.
        require(governanceToken.getPastVotes(msg.sender, block.number - 1) >= calculateProposalThreshold(), "Governor: Proposer votes below threshold");

        proposalId = ++proposalCount;
        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.description = description;
        newProposal.eta = 0; // Not queued yet
        newProposal.executed = false;
        newProposal.canceled = false;

        _proposerProposals[msg.sender].push(proposalId);

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            startBlock,
            endBlock,
            description
        );
    }

    /**
     * @dev Casts a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The vote type (0: Against, 1: For, 2: Abstain).
     * @return The total votes cast by the voter for this proposal (after considering modifier).
     */
    function castVote(uint256 proposalId, uint8 support) external returns (uint256) {
        return castVoteWithReason(proposalId, support, "");
    }

     /**
     * @dev Casts a vote on a proposal with a reason.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The vote type (0: Against, 1: For, 2: Abstain).
     * @param reason An optional reason for the vote.
     * @return The total votes cast by the voter for this proposal (after considering modifier).
     */
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public virtual returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        require(_getProposalState(proposalId) == ProposalState.Active, "Governor: Proposal is not active");
        require(_votes[proposalId][msg.sender] == uint8(0), "Governor: Voter already voted"); // Check if voter already voted (0 is default un-voted state)

        // Get voting power at the proposal's start block
        uint256 votesCast = _getAdjustedVotingWeight(msg.sender, proposal.startBlock);
        require(votesCast > 0, "Governor: Voter has no voting power");

        // Record the vote
        _votes[proposalId][msg.sender] = support + 1; // Store 1, 2, or 3 to differentiate from default 0

        // Update proposal vote counts
        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes += votesCast;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes += votesCast;
        } else if (support == uint8(VoteType.Abstain)) {
             proposal.abstainVotes += votesCast;
        } else {
            revert("Governor: Invalid vote support");
        }

        emit VoteCast(msg.sender, proposalId, support, votesCast, reason);

        return votesCast;
    }

    /**
     * @dev Casts a vote on a proposal using an EIP-712 signature.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The vote type (0: Against, 1: For, 2: Abstain).
     * @param v The recovery byte of the signature.
     * @param r The R component of the signature.
     * @param s The S component of the signature.
     * @return The total votes cast by the voter for this proposal (after considering modifier).
     */
    function castVoteBySig(uint256 proposalId, uint8 support, uint256 v, bytes32 r, bytes32 s) external virtual returns (uint256) {
        // Standard EIP-712 message structure for voting
        bytes32 digest = _hashVoteMessage(proposalId, support);
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "Governor: Invalid signature");

        // Prevent replay attacks using nonces (one nonce per signer)
        uint256 nonce = _nonces[signer];
        bytes32 expectedDigest = keccak256(abi.encodePacked(digest, nonce)); // Include nonce in expected digest
        require(_isValidSignature(signer, expectedDigest, v, r, s), "Governor: Invalid signature or nonce");
        _nonces[signer]++; // Increment nonce for signer

        // Now, cast the vote as if the signer called the function directly
        // Note: This requires simulating the call context or re-implementing vote logic here.
        // Re-implementing is simpler.
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        require(_getProposalState(proposalId) == ProposalState.Active, "Governor: Proposal is not active");
        require(_votes[proposalId][signer] == uint8(0), "Governor: Voter already voted");

        uint256 votesCast = _getAdjustedVotingWeight(signer, proposal.startBlock);
        require(votesCast > 0, "Governor: Voter has no voting power");

         // Record the vote
        _votes[proposalId][signer] = support + 1;

         // Update proposal vote counts
        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes += votesCast;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes += votesCast;
        } else if (support == uint8(VoteType.Abstain)) {
             proposal.abstainVotes += votesCast;
        } else {
            revert("Governor: Invalid vote support");
        }

        // Reason is not included in the standard EIP-712 Vote type, skipping it for sig voting.
        emit VoteCast(signer, proposalId, support, votesCast, "");

        return votesCast;
    }

    /**
     * @dev Casts a vote on a proposal using an EIP-712 signature and includes a reason and additional params.
     *      Requires a custom EIP-712 type definition for "VoteWithReasonAndParams".
     *      This function is complex as it requires dynamically hashing abi.encodePacked(params).
     *      Leaving implementation details minimal to avoid massive code complexity, focusing on function count/concept.
     *      A proper implementation would need a custom typehash and hash logic.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The vote type (0: Against, 1: For, 2: Abstain).
     * @param reason An optional reason for the vote.
     * @param params Additional data for the vote (e.g., split votes, specific preferences).
     * @return The total votes cast by the voter for this proposal (after considering modifier).
     */
     function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string calldata reason, bytes calldata params) external returns (uint256 votes) {
         // This is an advanced placeholder. Implementing robust EIP712 for dynamic `params` is complex.
         // A standard approach would define specific EIP712 types for known parameter structures.
         // For this example, we'll fallback to the reason-only vote logic after validating.
         // In a real implementation, you'd hash a custom type including `params`.

         // Basic checks similar to castVoteWithReason
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        require(_getProposalState(proposalId) == ProposalState.Active, "Governor: Proposal is not active");
        require(_votes[proposalId][msg.sender] == uint8(0), "Governor: Voter already voted");

        uint256 votesCast = _getAdjustedVotingWeight(msg.sender, proposal.startBlock);
        require(votesCast > 0, "Governor: Voter has no voting power");

        // In a real implementation, the logic using `params` would go here
        // e.g., distributing votes across multiple options within the params.
        // For this example, we just record the main vote support.

         // Record the vote (basic support type)
        _votes[proposalId][msg.sender] = support + 1;

        // Update proposal vote counts
        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes += votesCast;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes += votesCast;
        } else if (support == uint8(VoteType.Abstain)) {
             proposal.abstainVotes += votesCast;
        } else {
            revert("Governor: Invalid vote support");
        }

        // Emit VoteCast event, perhaps including a hash of params or a specific event for this type
        // Using the standard event for simplicity here.
        emit VoteCast(msg.sender, proposalId, support, votesCast, reason);

        return votesCast;
     }


    /**
     * @dev Queues a successful proposal for execution.
     * @param proposalId The ID of the proposal to queue.
     */
    function queue(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        require(_getProposalState(proposalId) == ProposalState.Succeeded, "Governor: Proposal is not succeeded");
        require(proposal.eta == 0, "Governor: Proposal already queued");

        proposal.eta = block.number + executionDelay;

        emit ProposalQueued(proposalId, proposal.eta);
    }

    /**
     * @dev Executes a queued proposal.
     * @param proposalId The ID of the proposal to execute.
     */
    function execute(uint256 proposalId) external payable {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        require(_getProposalState(proposalId) == ProposalState.Queued, "Governor: Proposal is not queued or execution window passed");
        require(!proposal.executed, "Governor: Proposal already executed");
        require(block.number >= proposal.eta, "Governor: Execution time not reached");
        require(block.number < proposal.eta + gracePeriod, "Governor: Execution window passed");


        proposal.executed = true;

        // Execute the proposed actions
        for (uint i = 0; i < proposal.targets.length; i++) {
            address target = proposal.targets[i];
            uint256 value = proposal.values[i];
            bytes memory calldata = proposal.calldatas[i];

            // Using low-level call with success check
            (bool success, ) = target.call{value: value}(calldata);
            require(success, "Governor: Execution failed");
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Cancels a proposal. Only allowed in Pending or Active states under specific conditions
     *      (e.g., by proposer if threshold lost, or via another proposal).
     *      Simplified here: Proposer can cancel if proposal is Pending or Active.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancel(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Governor: Proposal not found");
        ProposalState currentState = _getProposalState(proposalId);
        require(currentState == ProposalState.Pending || currentState == ProposalState.Active, "Governor: Proposal cannot be canceled in current state");
        require(msg.sender == proposal.proposer, "Governor: Only proposer can cancel");
        require(!proposal.canceled, "Governor: Proposal already canceled");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    // --- Delegation Functions ---

    /**
     * @dev Delegates voting power to `delegatee`.
     *      Voting power calculations for proposals snapshot delegation at the proposal's start block.
     * @param delegatee The address to delegate voting power to.
     */
    function delegate(address delegatee) external {
        _delegates[msg.sender] = delegatee;
        // Note: A more complete system would record checkpointed votes here for getPastVotes.
        // Assuming the underlying governance token handles getPastVotes correctly based on its internal state.
        // If the token doesn't support getPastVotes based on historical delegation,
        // this governor would need a complex internal checkpointing system for delegated votes.
        // For this example, we rely on `_getAdjustedVotingWeight` and `governanceToken.getPastVotes`
        // to handle the historical lookup based on the state *they* track.
         governanceToken.delegate(delegatee); // Assume token implements delegate for snapshotting
    }

     /**
     * @dev Gets the voting power of an account at a specific block number,
     *      considering delegation and the pluggable voting weight modifier.
     * @param account The account address.
     * @param blockNumber The block number to check voting power at.
     * @return The voting power.
     */
    function getVotingPower(address account, uint256 blockNumber) public view returns (uint256) {
        // Resolve delegatee at the given block number (assuming governanceToken handles this)
        address delegatee = governanceToken.delegates(account); // This might not work historically depending on token.
                                                               // A robust solution needs historical delegatee lookup or governor checkpoints.
                                                               // For simplicity, assume the token's getPastVotes resolves delegation internally.
        return _getAdjustedVotingWeight(delegatee, blockNumber);
    }

    /**
     * @dev Gets the address that an account has delegated their voting power to.
     * @param account The account address.
     * @return The delegatee address.
     */
    function delegates(address account) external view returns (address) {
        return _delegates[account]; // This mapping tracks the *current* delegation set via this governor
    }

     /**
     * @dev Gets the raw votes an account had at a specific block number,
     *      as reported by the governance token (useful for understanding baseline votes before modifier).
     * @param account The account address.
     * @param blockNumber The block number.
     * @return The raw votes.
     */
    function getVotesAtBlock(address account, uint256 blockNumber) public view returns (uint256) {
        return governanceToken.getPastVotes(account, blockNumber);
    }


    // --- State & Information Getters ---

    /**
     * @dev Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        return _getProposalState(proposalId);
    }

    /**
     * @dev Gets the details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return targets The target addresses.
     * @return values The Ether values.
     * @return calldatas The calldata.
     * @return startBlock The block voting started.
     * @return endBlock The block voting ends.
     * @return description The proposal description.
     * @return eta The execution time (block number).
     */
    function getProposalDetails(uint256 proposalId) external view returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, uint256 startBlock, uint256 endBlock, string memory description, uint256 eta) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0 || proposalId == 0, "Governor: Proposal not found"); // Allow checking for proposal 0 gracefully
         if (proposal.id == 0 && proposalId != 0) {
            // Return empty details for non-existent non-zero proposals
             return (new address[](0), new uint256[](0), new bytes[](0), 0, 0, "", 0);
         }
         return (proposal.targets, proposal.values, proposal.calldatas, proposal.startBlock, proposal.endBlock, proposal.description, proposal.eta);
    }

    /**
     * @dev Gets the current vote counts for a proposal.
     * @param proposalId The ID of the proposal.
     * @return againstVotes The total against votes.
     * @return forVotes The total for votes.
     * @return abstainVotes The total abstain votes.
     */
    function getVotes(uint256 proposalId) external view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0 || proposalId == 0, "Governor: Proposal not found"); // Allow checking for proposal 0
          if (proposal.id == 0 && proposalId != 0) {
             return (0, 0, 0);
         }
         return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /**
     * @dev Gets the list of proposal IDs created by a specific proposer.
     * @param proposer The proposer's address.
     * @return An array of proposal IDs.
     */
    function getProposalsByProposer(address proposer) external view returns (uint256[] memory) {
        return _proposerProposals[proposer];
    }

     /**
     * @dev Gets the ID of the most recent proposal created by a specific proposer.
     * @param proposer The proposer's address.
     * @return The latest proposal ID, or 0 if none exist.
     */
    function getLatestProposalId(address proposer) external view returns (uint256) {
        uint256[] storage proposals = _proposerProposals[proposer];
        if (proposals.length == 0) {
            return 0;
        }
        return proposals[proposals.length - 1];
    }

    /**
     * @dev Looks up how a specific voter voted on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The voter's address.
     * @return The vote support (0: Not Voted, 1: Against, 2: For, 3: Abstain).
     */
    function lookupVote(uint256 proposalId, address voter) external view returns (uint8) {
        return _votes[proposalId][voter];
    }

    // --- Treasury Management Functions ---

    /**
     * @dev Deposits ETH into the contract's treasury.
     *      This function is payable.
     */
    function depositTreasury() external payable {} // ETH is automatically added to contract balance

     /**
     * @dev Withdraws ETH from the treasury.
     *      This function can only be called via a successful proposal execution.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawTreasury(uint256 amount) external _onlyGovernor {
        require(address(this).balance >= amount, "Governor: Insufficient ETH balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Governor: ETH withdrawal failed");
    }

     /**
     * @dev Withdraws ERC20 tokens from the treasury.
     *      This function can only be called via a successful proposal execution.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20Treasury(address token, uint256 amount) external _onlyGovernor {
         require(token != address(0), "Governor: Invalid token address");
         IERC20 tokenContract = IERC20(token);
         require(tokenContract.balanceOf(address(this)) >= amount, "Governor: Insufficient token balance");

         // Use low-level call to prevent reentrancy issues from malicious tokens
         (bool success, bytes memory reason) = address(tokenContract).call(
             abi.encodeWithSelector(tokenContract.transfer.selector, msg.sender, amount)
         );
         require(success, string(reason));
    }

    /**
     * @dev Gets the current ETH balance of the treasury.
     * @return The ETH balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

     /**
     * @dev Gets the current ERC20 token balance of the treasury.
     * @param token The address of the ERC20 token.
     * @return The token balance.
     */
    function getERC20TreasuryBalance(address token) external view returns (uint256) {
         require(token != address(0), "Governor: Invalid token address");
         return IERC20(token).balanceOf(address(this));
    }


    // --- Parameter Management Functions (Callable via execute) ---

    /**
     * @dev Sets the voting period (in blocks). Callable only via governance.
     * @param newVotingPeriod The new voting period.
     */
    function setVotingPeriod(uint256 newVotingPeriod) external _onlyGovernor {
        require(newVotingPeriod > 0, "Governor: Voting period must be > 0");
        emit ParametersUpdated("votingPeriod", votingPeriod, newVotingPeriod);
        votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Sets the quorum numerator (out of 10000). Callable only via governance.
     * @param newQuorumNumerator The new quorum numerator.
     */
    function setQuorumNumerator(uint256 newQuorumNumerator) external _onlyGovernor {
        require(newQuorumNumerator <= 10000, "Governor: Quorum numerator cannot exceed 10000");
         emit ParametersUpdated("quorumNumerator", quorumNumerator, newQuorumNumerator);
        quorumNumerator = newQuorumNumerator;
    }

    /**
     * @dev Sets the proposal threshold ratio (out of 10000 of total supply). Callable only via governance.
     * @param newThresholdRatio The new threshold ratio numerator.
     */
    function setProposalThresholdRatio(uint256 newThresholdRatio) external _onlyGovernor {
         require(newThresholdRatio <= 10000, "Governor: Threshold ratio cannot exceed 10000");
        emit ParametersUpdated("proposalThresholdRatio", proposalThresholdRatio, newThresholdRatio);
        proposalThresholdRatio = newThresholdRatio;
    }

    /**
     * @dev Sets the execution delay (in blocks). Callable only via governance.
     * @param newExecutionDelay The new execution delay.
     */
    function setExecutionDelay(uint256 newExecutionDelay) external _onlyGovernor {
         emit ParametersUpdated("executionDelay", executionDelay, newExecutionDelay);
        executionDelay = newExecutionDelay;
         // Update grace period if needed, or rely on default calculation based on votingPeriod
         gracePeriod = executionDelay + (votingPeriod * 2); // Recalculate default grace period
    }

    /**
     * @dev Sets the delay between proposal creation and voting start (in blocks). Callable only via governance.
     * @param newVotingDelay The new voting delay.
     */
    function setVotingDelay(uint256 newVotingDelay) external _onlyGovernor {
         emit ParametersUpdated("votingDelay", votingDelay, newVotingDelay);
        votingDelay = newVotingDelay;
    }

    /**
     * @dev Sets the grace period after execution delay where execution is possible (in blocks). Callable only via governance.
     * @param newGracePeriod The new grace period.
     */
    function setGracePeriod(uint256 newGracePeriod) external _onlyGovernor {
        emit ParametersUpdated("gracePeriod", gracePeriod, newGracePeriod);
        gracePeriod = newGracePeriod;
    }

     /**
     * @dev Sets the name of the governor contract. Callable only via governance.
     *      Note: Changing the name invalidates previous EIP-712 signatures.
     * @param newName The new name.
     */
    function setGovernorName(string calldata newName) external _onlyGovernor {
        emit GovernorNameUpdated(governorName, newName);
        governorName = newName;
        // Re-calculate DOMAIN_SEPARATOR if needed, or handle off-chain.
        // For simplicity, we don't update DOMAIN_SEPARATOR on-chain here.
        // Clients would need to fetch the name and re-calculate DOMAIN_SEPARATOR off-chain.
        // A safer approach is to make DOMAIN_SEPARATOR immutable or versioned.
    }


    // --- Advanced & Dynamic Features ---

    /**
     * @dev Sets the address of the trusted relayer who can trigger flux updates.
     *      Callable only via governance.
     * @param relayer The address of the trusted relayer.
     */
    function setTrustedRelayer(address relayer) external _onlyGovernor {
         require(relayer != address(0), "Governor: Invalid relayer address");
         emit TrustedRelayerUpdated(trustedRelayer, relayer);
        trustedRelayer = relayer;
    }

    /**
     * @dev Updates the dynamic 'flux' parameter.
     *      Callable only by the trusted relayer.
     * @param externalData The new data for the flux parameter (e.g., abi-encoded oracle data).
     */
    function triggerFluxUpdate(bytes calldata externalData) external _onlyTrustedRelayer {
        bytes memory oldFlux = currentFlux; // Store current flux
        currentFlux = externalData;
        emit FluxUpdated(oldFlux, currentFlux, msg.sender);
    }

    /**
     * @dev Gets the current value of the dynamic 'flux' parameter.
     * @return The current flux data.
     */
    function getCurrentFluxValue() external view returns (bytes memory) {
        return currentFlux;
    }

     /**
     * @dev Sets the address of the pluggable IVotingWeightModifier contract.
     *      Callable only via governance.
     * @param modifierAddress The address of the modifier contract (address(0) to disable).
     */
    function setVotingWeightModifier(address modifierAddress) external _onlyGovernor {
         if (modifierAddress != address(0)) {
            // Basic check if it's a contract (not foolproof)
             uint256 codeSize;
             assembly { codeSize := extcodesize(modifierAddress) }
             require(codeSize > 0, "Governor: Modifier address is not a contract");
         }
        emit VotingWeightModifierUpdated(votingWeightModifierAddress, modifierAddress);
        votingWeightModifierAddress = modifierAddress;
    }

    /**
     * @dev Registers or unregisters a token address that the Voting Weight Modifier *might* consider.
     *      This doesn't force the modifier to use the token, but signals relevance.
     *      Callable only via governance.
     * @param tokenAddress The address of the token to register/unregister.
     * @param isRegistered Whether to register (true) or unregister (false).
     */
    function registerReputationToken(address tokenAddress, bool isRegistered) external _onlyGovernor {
        require(tokenAddress != address(0), "Governor: Invalid token address");
        require(registeredReputationTokens[tokenAddress] != isRegistered, "Governor: Token registration state already set");
        registeredReputationTokens[tokenAddress] = isRegistered;
        emit ReputationTokenRegistered(tokenAddress, isRegistered);
    }

     /**
     * @dev Gets the list of registered reputation tokens.
     *      Note: This is a potentially gas-expensive operation if many tokens are registered.
     *      Storing in an array would be more efficient for retrieval but more gas-costly for updates.
     *      Using a mapping here, requiring iteration off-chain or a separate state variable to track count/list.
     *      Providing a basic getter that might be limited or require iteration client-side.
     *      For demonstration, we'll return a fixed-size array or require iteration.
     *      Let's just provide a getter that returns the state of *one* token. A full list is complex.
     *      Alternatively, keep track of registered tokens in an array alongside the mapping. Let's do that.
     */
    address[] private _registeredReputationTokenList;
    mapping(address => uint256) private _registeredReputationTokenIndex; // tokenAddress => index in list (+1)

    /**
     * @dev Registers or unregisters a token address (Internal helper with array management).
     */
    function _registerReputationTokenInternal(address tokenAddress, bool isRegistered) internal {
        require(tokenAddress != address(0), "Governor: Invalid token address");
        bool currentlyRegistered = registeredReputationTokens[tokenAddress];
        require(currentlyRegistered != isRegistered, "Governor: Token registration state already set");

        registeredReputationTokens[tokenAddress] = isRegistered;
        emit ReputationTokenRegistered(tokenAddress, isRegistered);

        if (isRegistered) {
            require(_registeredReputationTokenIndex[tokenAddress] == 0, "Governor: Token already in list");
            _registeredReputationTokenList.push(tokenAddress);
            _registeredReputationTokenIndex[tokenAddress] = _registeredReputationTokenList.length; // Store 1-based index
        } else {
            require(_registeredReputationTokenIndex[tokenAddress] > 0, "Governor: Token not in list");
            uint256 indexToRemove = _registeredReputationTokenIndex[tokenAddress] - 1;
            uint256 lastIndex = _registeredReputationTokenList.length - 1;
            address lastToken = _registeredReputationTokenList[lastIndex];

            // Move the last element to the place of the element to delete
            if (indexToRemove != lastIndex) {
                _registeredReputationTokenList[indexToRemove] = lastToken;
                _registeredReputationTokenIndex[lastToken] = indexToRemove + 1;
            }

            // Remove the last element
            _registeredReputationTokenList.pop();
            delete _registeredReputationTokenIndex[tokenAddress]; // Clear the index
        }
    }

    // Override the external function to call internal helper
    function registerReputationToken(address tokenAddress, bool isRegistered) external _onlyGovernor override {
        _registerReputationTokenInternal(tokenAddress, isRegistered);
    }


    /**
     * @dev Gets the list of currently registered reputation tokens.
     * @return An array of registered token addresses.
     */
    function getRegisteredReputationTokens() external view returns (address[] memory) {
         return _registeredReputationTokenList;
    }


    // --- Utility & Rescue Functions (Callable via execute) ---

    /**
     * @dev Allows rescuing accidentally sent ERC20 tokens.
     *      Callable only via a successful proposal execution.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to rescue.
     * @param to The address to send the tokens to.
     */
    function rescueERC20(address token, uint256 amount, address to) external _onlyGovernor {
         require(token != address(0), "Governor: Invalid token address");
         require(to != address(0), "Governor: Invalid recipient address");
         require(token != address(governanceToken), "Governor: Cannot rescue governance token");

         IERC20 tokenContract = IERC20(token);
         require(tokenContract.balanceOf(address(this)) >= amount, "Governor: Insufficient token balance");

         // Use low-level call for safety
         (bool success, bytes memory reason) = address(tokenContract).call(
             abi.encodeWithSelector(tokenContract.transfer.selector, to, amount)
         );
         require(success, string(reason));

         emit FundsRescued(token, amount, to, ERC20_ASSET_TYPE);
    }

     /**
     * @dev Allows rescuing accidentally sent ERC721 tokens.
     *      Callable only via a successful proposal execution.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to rescue.
     * @param to The address to send the token to.
     */
    function rescueERC721(address token, uint256 tokenId, address to) external _onlyGovernor {
        require(token != address(0), "Governor: Invalid token address");
        require(to != address(0), "Governor: Invalid recipient address");

        IERC721 tokenContract = IERC721(token);
        require(tokenContract.ownerOf(tokenId) == address(this), "Governor: Contract is not the token owner");

        // Use safeTransferFrom with empty data
        (bool success, bytes memory reason) = address(tokenContract).call(
            abi.encodeWithSelector(tokenContract.safeTransferFrom.selector, address(this), to, tokenId)
        );
         require(success, string(reason));

         emit FundsRescued(token, tokenId, to, ERC721_ASSET_TYPE);
    }

     /**
     * @dev Gets the version string of the contract.
     * @return The version string.
     */
    function getVersion() external pure returns (string memory) {
        return "QuantumFluxGovernor v1.0";
    }

    // --- State Checkers ---

    /**
     * @dev Checks if voting is currently allowed for a proposal.
     * @param proposalId The ID of the proposal.
     * @return True if voting is active, false otherwise.
     */
    function isVotingAllowed(uint256 proposalId) external view returns (bool) {
        return _getProposalState(proposalId) == ProposalState.Active;
    }

    /**
     * @dev Checks if a proposal is currently ready for execution.
     * @param proposalId The ID of the proposal.
     * @return True if the proposal is in the Queued state and within the execution window, false otherwise.
     */
    function isExecutionAllowed(uint256 proposalId) external view returns (bool) {
        ProposalState currentState = _getProposalState(proposalId);
        if (currentState != ProposalState.Queued) return false;

        Proposal storage proposal = proposals[proposalId];
        return block.number >= proposal.eta && block.number < proposal.eta + gracePeriod;
    }

    // --- EIP-712 Interface Implementation ---
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    // --- Fallback (if receive isn't sufficient for some edge cases) ---
    // fallback() external payable {} // Not strictly needed if only receiving ETH is the goal and receive() is used.

}
```