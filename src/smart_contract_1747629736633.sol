Okay, let's design a smart contract that incorporates several advanced, creative, and trendy concepts. We'll create a system for "Programmable Rights Tokens" or "Covenants", which are NFTs representing dynamic claims or benefits, whose parameters can change based on governance, external data (simulated oracle), or internal logic.

This contract won't duplicate common open-source patterns directly. We'll combine ERC721 (NFTs), governance, oracles, staking, and dynamic state in a specific way.

**Concept: CovenantBoundAsset**

This contract manages a collection of non-fungible tokens (NFTs), where each NFT (a "Covenant") represents a unique, programmable right or claim. The specific parameters defining the value or nature of this right are not static but can change over time based on:

1.  **Governance:** Holders of a separate governance token (`CovenantVoteToken`) can propose and vote on parameter updates.
2.  **Oracle Data:** The contract can reference external data (simulated via a simple function call) to influence parameters.
3.  **Internal Logic:** Parameters can change automatically based on factors like time elapsed, usage count, or other internal state transitions.

Furthermore, holders can "stake" their Covenant NFTs to potentially amplify their rights or gain additional benefits, and the staking status might also influence parameters.

---

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721Enumerable, Ownable, Pausable, necessary interfaces.
3.  **Interfaces:**
    *   `ICovenantVoteToken`: Basic interface for the governance token (balance, transfer, potentially staking).
    *   `ISimulatedOracle`: Basic interface for getting external data.
4.  **Events:** Minting, Parameter Updates, Right Exercised, Staking, Governance (Proposal, Vote, Execution), Oracle/Logic Triggered, Pause/Unpause.
5.  **Structs:**
    *   `Covenant`: Represents an individual NFT/Right, including dynamic parameters and staking info.
    *   `Proposal`: Represents a governance proposal to change parameters.
6.  **State Variables:**
    *   Covenant data mapping.
    *   Governance token contract address.
    *   Oracle contract address.
    *   Governance proposal counter and mapping.
    *   Mapping for votes on proposals.
    *   Staked covenant tracking.
    *   Base parameters, thresholds, timing constants.
7.  **Modifiers:** Custom modifiers (e.g., `onlyOracle`, `onlyGovernanceExecution`).
8.  **Constructor:** Initializes base parameters, sets contract addresses.
9.  **Core NFT Functions (Overridden/Standard):** `supportsInterface`, `tokenURI`, `_beforeTokenTransfer`.
10. **Covenant Management Functions:**
    *   `mintCovenant`: Creates a new Covenant NFT with initial parameters.
    *   `burnCovenant`: Destroys a Covenant NFT.
    *   `getCovenantDetails`: View details of a specific Covenant.
11. **Dynamic Parameter Logic Functions:**
    *   `getCurrentClaimValue`: Calculates the current value/magnitude of the right based on dynamic parameters.
    *   `exerciseCovenantRight`: Executes the right, potentially transferring assets or granting access, and updates state.
    *   `triggerOracleParameterUpdate`: Callable by trusted source/keeper to check oracle and update parameters.
    *   `triggerInternalLogicUpdate`: Callable to apply time-based or state-based parameter changes.
    *   `_applyGovernanceParameters`: Internal function to set parameters based on executed proposal.
    *   `_applyOracleData`: Internal function to set parameters based on oracle data.
    *   `_applyInternalLogic`: Internal function to set parameters based on contract state/time.
12. **Staking Functions:**
    *   `stakeCovenant`: Locks a Covenant NFT in the contract.
    *   `unstakeCovenant`: Unlocks a staked Covenant NFT.
    *   `isCovenantStaked`: Check staking status.
    *   `getStakedCovenantIds`: Get all staked Covenant IDs for an owner.
13. **Governance Functions (using `CovenantVoteToken`):**
    *   `proposeParameterUpdate`: Initiate a new governance proposal.
    *   `voteOnProposal`: Cast a vote for or against a proposal.
    *   `executeProposal`: Finalize voting and apply changes if successful.
    *   `getProposalDetails`: View details of a proposal.
    *   `getActiveProposals`: View currently active proposal IDs.
14. **Admin/Setup Functions:**
    *   `setVoteTokenAddress`: Set the address of the governance token contract.
    *   `setOracleAddress`: Set the address of the oracle contract.
    *   `pauseContract`: Pause core functionality (using Pausable).
    *   `unpauseContract`: Unpause contract.
    *   `transferOwnership`: Transfer contract ownership (using Ownable).
15. **View/Utility Functions:**
    *   `getTotalStakedCovenants`: Get total count of staked NFTs.
    *   `getUserVotePower`: Get the user's voting power from the CVT contract.
    *   `getlastUpdateTime`: Get the last time parameters were updated for a covenant.
    *   `getContractStateSummary`: Get a summary of key contract states (active proposals, total covenants, etc.).

---

**Function Summary (Counting 24 custom functions + ERC721 standards):**

1.  `constructor()`: Deploys/Initializes contract, sets basic state.
2.  `mintCovenant(address to, uint96 initialBaseClaimRate, int96 initialDynamicParam1, uint96 initialDynamicParam2)`: Mints a new Covenant NFT to an address with initial parameters.
3.  `burnCovenant(uint256 tokenId)`: Destroys a Covenant NFT (only if not staked).
4.  `getCovenantDetails(uint256 tokenId)`: View function to retrieve struct data for a given Covenant.
5.  `getCurrentClaimValue(uint256 tokenId)`: Calculates the dynamic value/claim amount associated with a Covenant based on its current parameters and state (e.g., staking).
6.  `exerciseCovenantRight(uint256 tokenId)`: Executes the right associated with the Covenant. This function implements the logic of what the right *does* (e.g., calculates and transfers a token amount, updates an access control list, etc.) based on `getCurrentClaimValue`.
7.  `triggerOracleParameterUpdate(uint256 tokenId)`: Callable by a designated role/keeper to fetch data from the oracle and potentially update a Covenant's dynamic parameters based on that data.
8.  `triggerInternalLogicUpdate(uint256 tokenId)`: Callable to trigger the internal algorithm that modifies a Covenant's parameters based on factors like time or usage count.
9.  `stakeCovenant(uint256 tokenId)`: Transfers the Covenant NFT into the contract's custody, marking it as staked. May start a staking timer or apply staking bonuses.
10. `unstakeCovenant(uint256 tokenId)`: Transfers a staked Covenant NFT back to the owner, ending the staking period.
11. `isCovenantStaked(uint256 tokenId)`: View function to check if a specific Covenant is currently staked.
12. `getStakedCovenantIds(address owner)`: View function listing all Covenant token IDs currently staked by a specific owner.
13. `proposeParameterUpdate(string memory description, uint256 targetTokenId, int96 newDynamicParam1, uint96 newDynamicParam2, uint256 votingPeriodSeconds)`: Allows a minimum threshold of CVT holders (or staked Covenant holders) to propose a change to a specific Covenant's dynamic parameters.
14. `voteOnProposal(uint256 proposalId, bool support)`: Allows CVT holders to cast their vote on an active proposal.
15. `executeProposal(uint256 proposalId)`: Finalizes voting for a proposal after the voting period ends and applies the proposed parameter changes if the proposal passes.
16. `getProposalDetails(uint256 proposalId)`: View details of a specific governance proposal.
17. `getActiveProposals()`: View function listing IDs of currently active governance proposals.
18. `setVoteTokenAddress(address _voteTokenAddress)`: Owner/governance function to set or update the address of the CovenantVoteToken contract.
19. `setOracleAddress(address _oracleAddress)`: Owner/governance function to set or update the address of the SimulatedOracle contract.
20. `pauseContract()`: Owner/governance function to pause critical contract operations (using Pausable).
21. `unpauseContract()`: Owner/governance function to unpause the contract.
22. `getTotalStakedCovenants()`: View function returning the total number of NFTs currently staked within the contract.
23. `getUserVotePower(address user)`: View function fetching the user's voting power from the linked CovenantVoteToken contract.
24. `getContractStateSummary()`: View function providing a summary of overall contract metrics (e.g., total covenants, active proposals count, total staked).

**(Plus standard ERC721Enumerable functions: `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `totalSupply`, `tokenOfOwnerByIndex`, `tokenByIndex`)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports (ERC721Enumerable, Ownable, Pausable, SafeMath, Counters)
// 3. Interfaces (ICovenantVoteToken, ISimulatedOracle)
// 4. Events
// 5. Structs (Covenant, Proposal)
// 6. State Variables (Covenant Data, Governance, Oracle, Constants)
// 7. Modifiers (Placeholder for future complex access control)
// 8. Constructor
// 9. Core NFT Functions (Overrides)
// 10. Covenant Management Functions (Mint, Burn, Get Details)
// 11. Dynamic Parameter Logic (Get Value, Exercise, Triggers, Apply Internals)
// 12. Staking Functions
// 13. Governance Functions (Propose, Vote, Execute, Views)
// 14. Admin/Setup Functions
// 15. View/Utility Functions

// --- Function Summary ---
// constructor()
// mintCovenant()
// burnCovenant()
// getCovenantDetails()
// getCurrentClaimValue()
// exerciseCovenantRight()
// triggerOracleParameterUpdate()
// triggerInternalLogicUpdate()
// stakeCovenant()
// unstakeCovenant()
// isCovenantStaked()
// getStakedCovenantIds()
// proposeParameterUpdate()
// voteOnProposal()
// executeProposal()
// getProposalDetails()
// getActiveProposals()
// setVoteTokenAddress()
// setOracleAddress()
// pauseContract()
// unpauseContract()
// getTotalStakedCovenants()
// getUserVotePower()
// getContractStateSummary()
// + Standard ERC721Enumerable functions

// Basic Interface for a Governance Token (ERC20-like needed for voting power)
interface ICovenantVoteToken {
    function balanceOf(address account) external view returns (uint256);
    // Add more functions if needed for transferring voting power or staking CVT itself
}

// Basic Interface for a Simulated Oracle
// In a real scenario, this would likely be Chainlink or a similar decentralized oracle
interface ISimulatedOracle {
    function getData() external view returns (int256 data); // Example: returns a price, temperature, etc.
}

contract CovenantBoundAsset is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- State Variables ---

    // Represents a unique Covenant (NFT) and its dynamic parameters
    struct Covenant {
        uint40 creationTime;       // Timestamp of creation (gas efficient)
        uint96 baseClaimRate;      // A base rate for calculating claim value (e.g., basis points)
        int96 dynamicParam1;       // A dynamic parameter (can be positive or negative)
        uint96 dynamicParam2;       // Another dynamic parameter
        uint40 lastParamUpdateTime; // Timestamp of the last update via oracle or logic
        bool isStaked;             // True if the Covenant is currently staked
        uint48 stakedUntil;        // Timestamp when staking ends (0 if not time-based or not staked)
        uint32 usageCount;         // How many times the right has been exercised
    }

    mapping(uint256 => Covenant) private _covenants;
    mapping(address => uint256[]) private _stakedCovenantIds; // Track staked NFTs per owner

    // Governance
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 targetTokenId;      // Which Covenant this proposal targets
        int96 proposedDynamicParam1;
        uint96 proposedDynamicParam2;
        uint40 votingStartTime;      // Timestamp voting starts
        uint40 votingEndTime;        // Timestamp voting ends
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool executed;               // True if the proposal has been executed
        bool cancelled;              // True if the proposal was cancelled
    }

    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voterAddress => hasVoted

    address public covenantVoteToken; // Address of the governance token contract
    address public simulatedOracle;   // Address of the simulated oracle contract

    // Governance Constants
    uint256 public minVotePowerToPropose;
    uint256 public votingPeriodDuration;
    uint256 public proposalQuorumBasisPoints; // e.g., 400 (4%) of total vote token supply

    // Internal Logic Constants
    uint256 public internalLogicDecayRateBasisPoints; // e.g., 10 (0.1%) per update cycle
    uint40 public internalLogicUpdateCooldown;       // Minimum time between internal logic updates per token

    // --- Events ---
    event CovenantMinted(uint256 indexed tokenId, address indexed owner, uint96 baseClaimRate, int96 dynamicParam1, uint96 dynamicParam2);
    event CovenantBurned(uint256 indexed tokenId);
    event ParametersUpdated(uint256 indexed tokenId, string source, int96 newDynamicParam1, uint96 newDynamicParam2, uint32 usageCount);
    event RightExercised(uint256 indexed tokenId, address indexed user, uint256 claimValue, uint32 newUsageCount);
    event CovenantStaked(uint256 indexed tokenId, address indexed owner, uint48 stakedUntil);
    event CovenantUnstaked(uint256 indexed tokenId, address indexed owner);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 indexed targetTokenId, uint40 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event OracleUpdateTriggered(uint256 indexed tokenId, address indexed caller);
    event InternalLogicUpdateTriggered(uint256 indexed tokenId, address indexed caller);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event VoteTokenAddressSet(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers ---
    // Example: modifier onlyOracle { require(msg.sender == simulatedOracle, "Not oracle"); _; }
    // Example: modifier onlyGovernanceExecution { require(msg.sender == address(this), "Not contract self-call"); _; }
    // For simplicity in this example, we'll use explicit checks rather than complex modifiers.

    // --- Constructor ---
    constructor(
        address _voteTokenAddress,
        address _simulatedOracle,
        uint256 _minVotePowerToPropose,
        uint256 _votingPeriodDuration,
        uint256 _proposalQuorumBasisPoints,
        uint256 _internalLogicDecayRateBasisPoints,
        uint40 _internalLogicUpdateCooldown
    ) ERC721Enumerable("CovenantBoundAsset", "CBA") Ownable(msg.sender) Pausable() {
        require(_voteTokenAddress != address(0), "Invalid vote token address");
        require(_simulatedOracle != address(0), "Invalid oracle address");
        covenantVoteToken = _voteTokenAddress;
        simulatedOracle = _simulatedOracle;

        minVotePowerToPropose = _minVotePowerToPropose;
        votingPeriodDuration = _votingPeriodDuration;
        proposalQuorumBasisPoints = _proposalQuorumBasisPoints;
        internalLogicDecayRateBasisPoints = _internalLogicDecayRateBasisPoints;
        internalLogicUpdateCooldown = _internalLogicUpdateCooldown;
    }

    // --- Core NFT Functions (Overrides) ---
    // Override to prevent transfer of staked tokens
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && _covenants[tokenId].isStaked) {
             revert("Covenant is staked");
        }
    }

    // --- Covenant Management Functions ---

    /// @notice Mints a new Covenant NFT
    /// @param to The address to mint the Covenant to
    /// @param initialBaseClaimRate The initial base rate for claims (e.g., basis points)
    /// @param initialDynamicParam1 An initial value for dynamic parameter 1
    /// @param initialDynamicParam2 An initial value for dynamic parameter 2
    function mintCovenant(address to, uint96 initialBaseClaimRate, int96 initialDynamicParam1, uint96 initialDynamicParam2)
        public onlyOwner whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(to, newItemId);

        _covenants[newItemId] = Covenant({
            creationTime: uint40(block.timestamp),
            baseClaimRate: initialBaseClaimRate,
            dynamicParam1: initialDynamicParam1,
            dynamicParam2: initialDynamicParam2,
            lastParamUpdateTime: uint40(block.timestamp),
            isStaked: false,
            stakedUntil: 0,
            usageCount: 0
        });

        emit CovenantMinted(newItemId, to, initialBaseClaimRate, initialDynamicParam1, initialDynamicParam2);
    }

     /// @notice Burns a Covenant NFT
     /// @param tokenId The ID of the Covenant to burn
    function burnCovenant(uint256 tokenId) public virtual {
        require(_exists(tokenId), "Covenant does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!_covenants[tokenId].isStaked, "Covenant is staked");

        _burn(tokenId);
        delete _covenants[tokenId];

        emit CovenantBurned(tokenId);
    }


    /// @notice Get details of a specific Covenant
    /// @param tokenId The ID of the Covenant
    /// @return Covenant struct data
    function getCovenantDetails(uint256 tokenId) public view returns (Covenant memory) {
        require(_exists(tokenId), "Covenant does not exist");
        return _covenants[tokenId];
    }

    // --- Dynamic Parameter Logic Functions ---

    /// @notice Calculates the current effective claim value of a Covenant
    /// @dev This function contains the core logic combining base rate, dynamic params, and state (like staking)
    /// @param tokenId The ID of the Covenant
    /// @return The calculated claim value (example in wei or basis points)
    function getCurrentClaimValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Covenant does not exist");
        Covenant memory covenant = _covenants[tokenId];

        // Example Logic:
        // Value = baseClaimRate + dynamicParam1 (adjusted by state) + dynamicParam2 (adjusted by state)
        // Staking might apply a multiplier or additive bonus
        // Usage count might apply a penalty or bonus
        // Time since last update might apply decay or growth

        int256 calculatedValue = int256(covenant.baseClaimRate);

        // Example: DynamicParam1 applies directly
        calculatedValue = calculatedValue + covenant.dynamicParam1;

        // Example: DynamicParam2 is a multiplier applied after other calcs
        uint256 param2Multiplier = uint256(covenant.dynamicParam2); // Assume param2 is in basis points (10000 = 1x)
        if (param2Multiplier > 0) {
             calculatedValue = (calculatedValue * int256(param2Multiplier)) / 10000;
        }


        // Example: Staking provides a bonus
        if (covenant.isStaked) {
            calculatedValue = calculatedValue + (int256(covenant.baseClaimRate) / 10); // 10% staking bonus example
            // Or check covenant.stakedUntil for time-based bonus
        }

        // Example: Usage count applies a penalty
        if (covenant.usageCount > 0) {
             calculatedValue = calculatedValue - int256(covenant.usageCount * 5); // 5 units penalty per usage example
        }


        // Ensure the value doesn't go below zero (unless negative value is intended)
        return calculatedValue > 0 ? uint256(calculatedValue) : 0;

        // NOTE: The actual calculation logic needs to be defined based on the specific use case
    }

    /// @notice Executes the right associated with a Covenant
    /// @dev This function should implement the specific action of the Covenant (e.g., transfer tokens)
    /// @param tokenId The ID of the Covenant to exercise
    function exerciseCovenantRight(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Covenant does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!_covenants[tokenId].isStaked, "Covenant is staked and cannot be exercised directly");

        uint256 claimValue = getCurrentClaimValue(tokenId);

        // --- Implement the specific "right" logic here ---
        // Example: Transfer an ERC20 token based on the claimValue
        // IERC20 someToken = IERC20(address(0x...)); // Replace with actual token address
        // require(someToken.transfer(msg.sender, claimValue), "Token transfer failed");
        // Example: Update an access control list based on the claim value
        // Example: Mint a different token or NFT

        // For this example, we'll just simulate the action and update usage count
        // In a real contract, replace this with the actual right implementation
        emit RightExercised(tokenId, msg.sender, claimValue, _covenants[tokenId].usageCount + 1);
        // --- End specific "right" logic ---

        // Update usage count and potentially other state
        _covenants[tokenId].usageCount = _covenants[tokenId].usageCount.add(1);

        // Optionally trigger internal logic update after exercise
        _applyInternalLogic(tokenId);
    }

    /// @notice Triggers an update check with the oracle for a specific Covenant
    /// @dev Designed to be called by a trusted relayer or keeper, potentially permissioned
    /// @param tokenId The ID of the Covenant to update
    function triggerOracleParameterUpdate(uint256 tokenId) public whenNotPaused {
         require(_exists(tokenId), "Covenant does not exist");
         // Add access control here, e.g., only certain addresses or roles can call this
         // require(msg.sender == oracleRelayerAddress, "Not authorized");

         // Simulate fetching data from the oracle
         int256 oracleData = ISimulatedOracle(simulatedOracle).getData();

         _applyOracleData(tokenId, oracleData);

         emit OracleUpdateTriggered(tokenId, msg.sender);
    }

    /// @notice Triggers the internal logic update for a specific Covenant
    /// @dev Can be called by anyone, but logic only applies if cooldown has passed
    /// @param tokenId The ID of the Covenant to update
    function triggerInternalLogicUpdate(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Covenant does not exist");
        _applyInternalLogic(tokenId);
        emit InternalLogicUpdateTriggered(tokenId, msg.sender);
    }

    /// @dev Internal function to apply parameter changes from governance proposal
    /// @param tokenId The ID of the Covenant
    /// @param proposedParam1 New value for dynamicParam1
    /// @param proposedParam2 New value for dynamicParam2
    function _applyGovernanceParameters(uint256 tokenId, int96 proposedParam1, uint96 proposedParam2) internal {
         require(_exists(tokenId), "Covenant does not exist"); // Should not happen if called correctly
         _covenants[tokenId].dynamicParam1 = proposedParam1;
         _covenants[tokenId].dynamicParam2 = proposedParam2;
         _covenants[tokenId].lastParamUpdateTime = uint40(block.timestamp);
         emit ParametersUpdated(tokenId, "Governance", proposedParam1, proposedParam2, _covenants[tokenId].usageCount);
    }

    /// @dev Internal function to apply parameter changes based on oracle data
    /// @param tokenId The ID of the Covenant
    /// @param oracleData Data fetched from the oracle
    function _applyOracleData(uint256 tokenId, int256 oracleData) internal {
        require(_exists(tokenId), "Covenant does not exist"); // Should not happen

        // Example Logic: Adjust dynamicParam1 based on oracle data
        // If oracleData > 100, increase dynamicParam1; If < 100, decrease.
        if (oracleData > 100) {
            _covenants[tokenId].dynamicParam1 = _covenants[tokenId].dynamicParam1 + int96((oracleData - 100) / 10);
        } else if (oracleData < 100) {
             _covenants[tokenId].dynamicParam1 = _covenants[tokenId].dynamicParam1 - int96((100 - oracleData) / 10);
        }

        // Example Logic: Adjust dynamicParam2 based on oracle data
        // If oracleData is even, increase dynamicParam2; If odd, decrease.
        if (oracleData % 2 == 0) {
             _covenants[tokenId].dynamicParam2 = _covenants[tokenId].dynamicParam2.add(10);
        } else {
            _covenants[tokenId].dynamicParam2 = _covenants[tokenId].dynamicParam2.sub(10, "Param2 cannot go below 0"); // Use SafeMath with custom error
        }


        _covenants[tokenId].lastParamUpdateTime = uint40(block.timestamp);
        emit ParametersUpdated(tokenId, "Oracle", _covenants[tokenId].dynamicParam1, _covenants[tokenId].dynamicParam2, _covenants[tokenId].usageCount);
    }

    /// @dev Internal function to apply parameter changes based on internal logic (e.g., time decay)
    /// @param tokenId The ID of the Covenant
    function _applyInternalLogic(uint256 tokenId) internal {
        require(_exists(tokenId), "Covenant does not exist"); // Should not happen

        Covenant storage covenant = _covenants[tokenId];

        // Only apply logic if cooldown period has passed since last internal/oracle update
        if (block.timestamp < covenant.lastParamUpdateTime + internalLogicUpdateCooldown) {
            return; // Cooldown active
        }

        // Example Logic: Decay dynamicParam1 over time
        uint256 timeElapsed = block.timestamp - covenant.lastParamUpdateTime;
        // Simplify: Assume decay is linear per cooldown period passed
        uint256 updateCycles = timeElapsed / internalLogicUpdateCooldown;

        if (updateCycles > 0 && internalLogicDecayRateBasisPoints > 0) {
            int256 decayAmount = (int256(covenant.baseClaimRate) * int256(internalLogicDecayRateBasisPoints) * int256(updateCycles)) / 10000;
            covenant.dynamicParam1 = covenant.dynamicParam1 - decayAmount;
        }

        // Example Logic: Param2 increases slightly with usage
        covenant.dynamicParam2 = covenant.dynamicParam2.add(covenant.usageCount / 10); // +1 to param2 for every 10 uses

        covenant.lastParamUpdateTime = uint40(block.timestamp);
        emit ParametersUpdated(tokenId, "Internal Logic", covenant.dynamicParam1, covenant.dynamicParam2, covenant.usageCount);
    }

    // --- Staking Functions ---

    /// @notice Stakes a Covenant NFT in the contract
    /// @param tokenId The ID of the Covenant to stake
    function stakeCovenant(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Covenant does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!_covenants[tokenId].isStaked, "Covenant is already staked");

        Covenant storage covenant = _covenants[tokenId];
        covenant.isStaked = true;
        // Set stakedUntil if time-based staking is implemented
        // covenant.stakedUntil = uint48(block.timestamp + STAKING_DURATION); // Example

        // Transfer NFT from owner to contract
        _transfer(msg.sender, address(this), tokenId);

        // Add to staked list (simple array for example, more gas efficient ways exist)
        _stakedCovenantIds[msg.sender].push(tokenId);

        emit CovenantStaked(tokenId, msg.sender, covenant.stakedUntil);
    }

    /// @notice Unstakes a Covenant NFT from the contract
    /// @param tokenId The ID of the Covenant to unstake
    function unstakeCovenant(uint256 tokenId) public whenNotPaused {
        // Owner check is implicit via stakedCovenantIds lookup, or add explicit check
        // require(ownerOf(tokenId) == address(this), "Covenant not held by contract"); // Could be owned by contract even if not staked
        require(_covenants[tokenId].isStaked, "Covenant is not staked");
        address originalOwner = address(0); // Need to find original owner from staked list

        // Find and remove from staked list - Note: Array removal is gas expensive
        uint256[] storage stakedIds = _stakedCovenantIds[msg.sender];
        bool found = false;
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == tokenId) {
                // Simple remove by swapping with last element
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                found = true;
                originalOwner = msg.sender; // Assuming unstaker is the staker
                break;
            }
        }
        require(found, "Covenant not found in sender's staked list");

        Covenant storage covenant = _covenants[tokenId];
        covenant.isStaked = false;
        covenant.stakedUntil = 0; // Reset staking timer

        // Transfer NFT from contract back to owner
        _transfer(address(this), originalOwner, tokenId);

        emit CovenantUnstaked(tokenId, originalOwner, 0);
    }

    /// @notice Check if a specific Covenant is currently staked
    /// @param tokenId The ID of the Covenant
    /// @return bool True if staked, false otherwise
    function isCovenantStaked(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Covenant does not exist");
         return _covenants[tokenId].isStaked;
    }

     /// @notice Get all Covenant token IDs currently staked by a specific owner
     /// @param owner The address of the owner
     /// @return An array of staked Covenant token IDs
    function getStakedCovenantIds(address owner) public view returns (uint256[] memory) {
        return _stakedCovenantIds[owner];
    }


    // --- Governance Functions ---

    /// @notice Creates a proposal to update a Covenant's dynamic parameters
    /// @param description Description of the proposal
    /// @param targetTokenId The Covenant NFT ID targeted by this proposal
    /// @param newDynamicParam1 The proposed new value for dynamicParam1
    /// @param newDynamicParam2 The proposed new value for dynamicParam2
    /// @param votingPeriodSeconds The duration the voting period will last
    function proposeParameterUpdate(
        string memory description,
        uint256 targetTokenId,
        int96 newDynamicParam1,
        uint96 newDynamicParam2,
        uint256 votingPeriodSeconds
    ) public whenNotPaused {
        require(_exists(targetTokenId), "Target Covenant does not exist");
        require(votingPeriodSeconds > 0, "Voting period must be positive");
        // Check minimum proposal power (e.g., based on CVT balance or staked NFTs)
        // Example: require(getUserVotePower(msg.sender) >= minVotePowerToPropose, "Not enough vote power to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            targetTokenId: targetTokenId,
            proposedDynamicParam1: newDynamicParam1,
            proposedDynamicParam2: newDynamicParam2,
            votingStartTime: uint40(block.timestamp),
            votingEndTime: uint40(block.timestamp + votingPeriodSeconds),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, msg.sender, targetTokenId, _proposals[proposalId].votingEndTime);
    }

    /// @notice Casts a vote on an active proposal
    /// @param proposalId The ID of the proposal
    /// @param support True for 'for', False for 'against'
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp >= proposal.votingStartTime, "Voting has not started");
        require(block.timestamp <= proposal.votingEndTime, "Voting has ended");
        require(!_hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        uint256 votePower = getUserVotePower(msg.sender);
        require(votePower > 0, "Must have vote power to vote");

        _hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(votePower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(votePower);
        }

        emit VoteCast(proposalId, msg.sender, support, votePower);
    }

    /// @notice Executes a proposal if the voting period is over and it passed quorum/thresholds
    /// @param proposalId The ID of the proposal to execute
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp > proposal.votingEndTime, "Voting period is not over");

        uint256 totalVotes = proposal.totalVotesFor.add(proposal.totalVotesAgainst);
        uint256 totalVoteSupply = ICovenantVoteToken(covenantVoteToken).totalSupply(); // Assuming CVT is ERC20-like with totalSupply

        // Check Quorum: Total votes cast must meet a percentage of total supply
        bool quorumReached = totalVotes.mul(10000) / totalVoteSupply >= proposalQuorumBasisPoints;

        // Check Passing Threshold: More 'for' votes than 'against' (simple majority)
        bool majorityPassed = proposal.totalVotesFor > proposal.totalVotesAgainst;

        bool passed = quorumReached && majorityPassed;

        proposal.executed = true;

        if (passed) {
            _applyGovernanceParameters(
                proposal.targetTokenId,
                proposal.proposedDynamicParam1,
                proposal.proposedDynamicParam2
            );
        }

        emit ProposalExecuted(proposalId, passed);
    }

    /// @notice Get details of a specific governance proposal
    /// @param proposalId The ID of the proposal
    /// @return Proposal struct data
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(_proposals[proposalId].id != 0, "Proposal does not exist");
        return _proposals[proposalId];
    }

    /// @notice Get the IDs of all currently active proposals
    /// @dev Iterating through all proposals can be gas intensive if there are many. Consider pagination or alternative storage.
    /// @return An array of active proposal IDs
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](_proposalIdCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            Proposal storage proposal = _proposals[i];
            if (proposal.id != 0 && !proposal.executed && !proposal.cancelled && block.timestamp <= proposal.votingEndTime) {
                 activeProposalIds[count] = i;
                 count++;
            }
        }
        // Resize the array to the actual number of active proposals
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeProposalIds[i];
        }
        return result;
    }


    // --- Admin/Setup Functions ---

    /// @notice Sets the address of the CovenantVoteToken contract
    /// @dev Can only be called by the owner or via governance
    /// @param _voteTokenAddress The new address for the Vote Token contract
    function setVoteTokenAddress(address _voteTokenAddress) public onlyOwner { // Or add governance check
        require(_voteTokenAddress != address(0), "Invalid vote token address");
        address oldAddress = covenantVoteToken;
        covenantVoteToken = _voteTokenAddress;
        emit VoteTokenAddressSet(oldAddress, _voteTokenAddress);
    }

    /// @notice Sets the address of the SimulatedOracle contract
    /// @dev Can only be called by the owner or via governance
    /// @param _oracleAddress The new address for the Oracle contract
    function setOracleAddress(address _oracleAddress) public onlyOwner { // Or add governance check
        require(_oracleAddress != address(0), "Invalid oracle address");
        address oldAddress = simulatedOracle;
        simulatedOracle = _oracleAddress;
        emit OracleAddressSet(oldAddress, _oracleAddress);
    }

    // pauseContract and unpauseContract inherited from Pausable

    // transferOwnership inherited from Ownable

    // --- View/Utility Functions ---

    /// @notice Gets the total number of Covenants currently staked in the contract
    /// @dev This uses the total supply of NFTs owned by the contract, which includes staked ones.
    /// @return The total number of staked Covenants
    function getTotalStakedCovenants() public view returns (uint256) {
        // ERC721Enumerable's balance of contract address gives total NFTs owned by contract
        // If contract owned other NFTs, this would need a separate counter.
        return balanceOf(address(this));
    }

    /// @notice Gets the user's voting power from the connected CovenantVoteToken contract
    /// @param user The address of the user
    /// @return The user's vote power (based on their CVT balance or stake)
    function getUserVotePower(address user) public view returns (uint256) {
        // In a real scenario, this might check a staking contract for staked CVT
        // or just the ERC20 balance of the user.
        return ICovenantVoteToken(covenantVoteToken).balanceOf(user); // Example: Vote power is just CVT balance
    }

    /// @notice Gets the last timestamp parameters were updated for a covenant via Oracle/Logic
    /// @param tokenId The ID of the Covenant
    /// @return The last update timestamp
    function getLastParamUpdateTime(uint256 tokenId) public view returns (uint40) {
        require(_exists(tokenId), "Covenant does not exist");
        return _covenants[tokenId].lastParamUpdateTime;
    }

     /// @notice Provides a summary of key contract state variables
     /// @return totalCovenants - total number of NFTs minted
     /// @return totalStaked - total number of NFTs staked
     /// @return activeProposalsCount - number of currently active governance proposals
     /// @return voteTokenAddr - address of the CVT contract
     /// @return oracleAddr - address of the oracle contract
    function getContractStateSummary() public view returns (uint256 totalCovenants, uint256 totalStaked, uint256 activeProposalsCount, address voteTokenAddr, address oracleAddr) {
        uint256 _activeProposalsCount = 0;
         for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            Proposal storage proposal = _proposals[i];
            if (proposal.id != 0 && !proposal.executed && !proposal.cancelled && block.timestamp <= proposal.votingEndTime) {
                 _activeProposalsCount++;
            }
        }

        return (
            totalSupply(), // From ERC721Enumerable
            getTotalStakedCovenants(),
            _activeProposalsCount,
            covenantVoteToken,
            simulatedOracle
        );
    }

    // Required ERC721 functions
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Implement custom token URI logic here, perhaps linking to metadata describing the specific Covenant type and its current dynamic state
        // Example: string memory base = _baseURI(); return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId)) : "";
         return string(abi.encodePacked("ipfs://YOUR_METADATA_CID/", Strings.toString(tokenId))); // Placeholder
    }
}
```

**Explanation of Concepts and Why They Are Advanced/Interesting:**

1.  **Dynamic NFT Parameters:** Unlike typical static NFTs representing art or collectibles, these NFTs have parameters (`dynamicParam1`, `dynamicParam2`) that are designed to change. This opens possibilities for NFTs that evolve, represent fluctuating values, or adapt to external conditions.
2.  **Multiple Parameter Update Vectors:** The parameters aren't just set by an admin. They can be influenced by three distinct sources:
    *   **Governance:** Decentralized control via a vote token allows the community to collectively decide on changes, making the assets politically programmable.
    *   **Oracle Data:** Connecting to an oracle (even simulated here) allows the asset's properties to react to real-world events or data feeds (prices, weather, sports scores, etc.), creating "phygital" links or data-driven assets.
    *   **Internal Logic:** Autonomous, on-chain rules (like time decay or usage counts) add a layer of organic evolution or wear-and-tear to the asset's value/right.
3.  **Programmable Rights vs. Simple Ownership:** The NFT represents a "Covenant" or "Right," not just an item. The `exerciseCovenantRight` function embodies the *action* or *claim* associated with owning the NFT, whose outcome is determined by the dynamic parameters. This shifts focus from passive ownership to active utilization of an on-chain right.
4.  **NFT Staking with State Influence:** Staking the Covenant NFT isn't just about locking it; the `isStaked` status directly influences the `getCurrentClaimValue` calculation. This creates a direct utility and incentive for staking beyond passive rewards – it enhances the very nature of the owned right.
5.  **On-chain Governance Integration:** A full governance module (proposals, voting, execution) is integrated to control key aspects of the assets, specifically parameter updates. This is a complex pattern often found in DAOs or DeFi protocols, applied here to a specific type of NFT. The quorum and voting power logic adds robustness.
6.  **Modular Design (Interfaces):** Using interfaces for `ICovenantVoteToken` and `ISimulatedOracle` makes the contract more modular. You could plug in a real Chainlink oracle or a sophisticated voting escrow token contract without changing the core `CovenantBoundAsset` logic significantly.
7.  **Gas Optimization Considerations (Implicit):** Use of `uint40`, `uint96`, `uint48` where possible instead of full `uint256` helps save gas, particularly in the `Covenant` struct. Packing the struct is also implicitly handled by Solidity. Array operations for staked IDs and active proposals are noted as potential gas sinks in a large-scale deployment, which is an important consideration in advanced contract design.
8.  **Pausable and Ownable:** Standard safety and administrative patterns are included, crucial for managing a complex contract system.
9.  **Usage Tracking:** The `usageCount` adds another dimension, allowing rights to potentially degrade or change based on how often they are exercised.

This contract provides a framework for creating NFTs that are not just static collectibles, but dynamic, interactive, and community-influenced digital assets representing evolving rights or claims in a decentralized ecosystem.