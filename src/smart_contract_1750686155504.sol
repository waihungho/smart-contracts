Okay, here is a smart contract concept combining several advanced and trendy ideas: **The Sentient Swarm Protocol**.

This protocol manages a decentralized collective ("Swarm") of dynamic digital entities ("Swarm Units") represented as NFTs. These units have evolving attributes influenced by on-chain actions, potential external data (simulated via oracle), and collective governance. The protocol includes its own ERC20 token for staking, governance, and interacting with the units.

It touches upon:
1.  **Dynamic NFTs:** Unit attributes change over time/interaction.
2.  **Complex State Management:** Tracking evolving unit stats.
3.  **On-Chain Simulation/Game Mechanics:** Actions affect unit state.
4.  **Governance:** Decentralized decision-making on protocol parameters and treasury.
5.  **Staking:** Units can be staked for benefits or participation.
6.  **Treasury Management:** Collective funds.
7.  **Oracle Integration (Simulated):** Ability to incorporate off-chain data influence.
8.  **Meta-Transactions (Simulated):** Enabling gasless interactions for users via relayers.
9.  **Role-Based Access Control:** Granular permissions.
10. **Modular Design:** Using libraries and base contracts (like OpenZeppelin).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Contract Name: SentientSwarmProtocol

Concept: A decentralized protocol managing dynamic NFT entities ("Swarm Units")
         with evolving stats influenced by interactions, governance, and oracle data.
         Includes an ERC20 token for governance and utility, staking, and a treasury.

Main Components:
1.  SwarmToken (ERC20): Utility and governance token.
2.  SwarmUnit (ERC721 + Dynamic Stats): The core dynamic NFT entity.
3.  Unit Dynamics: Functions to interact with units and evolve their stats.
4.  Governance: Proposal and voting system for protocol parameters and treasury.
5.  Staking: Mechanism to stake SwarmUnits.
6.  Treasury: Holds protocol-owned assets, managed by governance.
7.  Oracle Integration: Endpoint for trusted oracle data feed.
8.  Meta-Transactions: Endpoint to execute user-signed transactions via relayers.
9.  Access Control: Roles for administrative functions.

Outline:
- Interfaces (e.g., IOracle)
- Errors
- Events
- Structs & Enums (SwarmUnitStats, Proposal, SwarmActionType, ProposalState)
- State Variables (Tokens, Mappings for Stats/Staking/Governance, Parameters)
- Roles
- Modifiers (e.g., onlyRole, proposalState)
- Initializer (For proxy compatibility)
- ERC20 Wrapper Functions
- ERC721 Wrapper Functions
- Unit Dynamics & Interaction Functions
- Staking Functions
- Governance Functions
- Treasury Functions
- Oracle Integration Function
- Meta-Transaction Function
- Query Functions

Function Summary (Total: ~30+ functions demonstrating breadth):

[Admin/Setup]
1.  initialize(): Sets initial roles and protocol parameters (proxy initializer).
2.  setProtocolParameters(): Allows PARAM_SETTER_ROLE or Governance to update config.
3.  grantRole(): Grants a specific role.
4.  revokeRole(): Revokes a specific role.
5.  renounceRole(): User renounces their own role.

[SwarmToken (ERC20)]
6.  mintSwarmToken(): Mints new tokens (restricted).
7.  burnSwarmToken(): Burns tokens (can be user or protocol initiated).
8.  transfer(): ERC20 standard transfer.
9.  transferFrom(): ERC20 standard transferFrom.
10. approve(): ERC20 standard approve.
11. balanceOf(address account): ERC20 standard balance query.
12. allowance(address owner, address spender): ERC20 standard allowance query.

[SwarmUnit (ERC721)]
13. spawnSwarmUnit(): Mints a new SwarmUnit NFT (can require tokens/logic).
14. burnSwarmUnit(): Burns a SwarmUnit NFT (can be user or protocol initiated).
15. transferFrom(address from, address to, uint256 tokenId): ERC721 standard transfer.
16. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): ERC721 standard safe transfer.
17. approve(address to, uint256 tokenId): ERC721 standard approve unit.
18. setApprovalForAll(address operator, bool approved): ERC721 standard set approval for all.
19. ownerOf(uint256 tokenId): ERC721 standard owner query.
20. balanceOf(address owner): ERC721 standard balance query for units.
21. getApproved(uint256 tokenId): ERC721 standard approved address query.
22. isApprovedForAll(address owner, address operator): ERC721 standard approval for all query.

[Unit Dynamics & Interaction]
23. getUnitStats(uint256 tokenId): Queries the dynamic stats of a unit.
24. performSwarmAction(uint256[] calldata unitIds, SwarmActionType action): Allows units to perform collective actions, affecting stats.
25. mergeSwarmUnits(uint256[] calldata sourceUnitIds): Burns source units and spawns a new unit with combined/averaged stats (complex logic).
26. sacrificeUnit(uint256 tokenId): Burns a unit to boost stats of others or gain tokens (game mechanic).

[Staking]
27. stakeSwarmUnits(uint256[] calldata unitIds): Stakes SwarmUnits, preventing transfer and potentially enabling passive effects.
28. unstakeSwarmUnits(uint256[] calldata unitIds): Unstakes SwarmUnits.
29. getUnitStakeStatus(uint256 tokenId): Checks if a unit is staked and relevant info.

[Governance]
30. proposeParameterChange(bytes calldata data): Allows token holders to propose changing protocol parameters (requires token/unit threshold).
31. voteOnProposal(uint256 proposalId, bool support): Allows token/unit holders to vote on active proposals.
32. executeProposal(uint256 proposalId): Executes a successful proposal after a timelock.
33. cancelProposal(uint256 proposalId): Cancels a proposal (e.g., by proposer or if conditions unmet).
34. getProposalState(uint256 proposalId): Queries the current state of a proposal.

[Treasury]
35. depositTreasury(): Allows anyone to send ETH or SwarmToken to the treasury.
36. withdrawTreasury(address token, address recipient, uint256 amount): Withdraws funds from the treasury (Governance only).

[Oracle Integration]
37. updateUnitStatsFromOracle(uint256 tokenId, bytes calldata oracleData): Allows a trusted ORACLE_ROLE to update unit stats based on off-chain data.

[Meta-Transactions]
38. executeMetaTransaction(address user, bytes calldata functionCallData, bytes memory signature): Allows a relayer to execute a function call on behalf of `user` using their signature, paying gas.

[Query Functions]
39. getProtocolParameters(): Returns current active protocol parameters.
40. getTotalUnitsSpawned(): Returns the total number of units ever minted.
41. getStakedUnitsCount(address owner): Returns the number of units staked by an owner.
42. getDelegatedVotePower(address delegator): Returns the vote power delegated *from* an address (if delegation was implemented, keeping it simple for this example, vote power is based on direct holdings).
43. getTreasuryBalance(address token): Returns the balance of a specific token in the treasury.

Note: This is a conceptual design. Production code would require extensive error handling, gas optimization, security audits, and more detailed logic for complex functions like `mergeSwarmUnits`, `performSwarmAction`, and the full governance lifecycle. Staking logic would need to handle rewards/benefits. Oracle data processing would require careful parsing and validation. Meta-transaction security relies heavily on signature verification and replay protection (nonce). The governance implementation here is simplified.

*/

// --- CONTRACT CODE ---

// Define necessary errors
error SwarmUnitDoesNotExist(uint256 tokenId);
error InvalidSwarmAction();
error NotEnoughTokens();
error NotEnoughUnits();
error UnitIsStaked(uint256 tokenId);
error UnitIsNotStaked(uint256 tokenId);
error UnitsCannotMerge();
error StakedUnitCannotBeTransferred();
error CallerIsNotOwnerOrApproved();
error ProposalDoesNotExist(uint256 proposalId);
error ProposalNotInCorrectState(uint256 proposalId, ProposalState expectedState);
error AlreadyVoted(uint256 proposalId, address voter);
error ProposalThresholdNotMet();
error ProposalTimelockNotPassed(uint256 proposalId, uint48 timelockEnd);
error InvalidSignature();
error UnauthorizedMetaTransaction(address user);
error OnlySelfCallAllowed(); // For meta-tx to prevent arbitrary contract calls

contract SentientSwarmProtocol is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // --- STATE VARIABLES ---

    // Tokens
    ERC20 public swarmToken;
    ERC721 public swarmUnitNFT;

    // Roles
    bytes32 public constant PARAM_SETTER_ROLE = keccak256("PARAM_SETTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant TREASURY_ADMIN_ROLE = keccak256("TREASURY_ADMIN_ROLE");
    bytes32 public constant META_TX_RELAYER_ROLE = keccak256("META_TX_RELAYER_ROLE"); // Role for allowed relayers

    // Unit State
    struct SwarmUnitStats {
        uint128 energy; // e.g., 0-1000
        uint128 cohesion; // e.g., 0-1000, affects merge success or action effectiveness
        uint48 lastUpdated; // Timestamp of last stat change (for decay/regeneration)
        // Add other dynamic stats here
        string status; // e.g., "Idle", "Exploring", "Defending"
    }
    mapping(uint256 => SwarmUnitStats) public unitStats;
    Counters.Counter private _unitIds;

    // Staking State
    mapping(uint256 => bool) public isUnitStaked;
    mapping(address => uint256[]) private _stakedUnitsByOwner; // Track staked units per owner
    mapping(uint256 => address) private _stakedUnitOwner; // Track owner of staked unit

    // Protocol Parameters (Mutable via Governance)
    struct ProtocolParameters {
        uint256 swarmTokenMintLimitPerAddress; // Limit on tokens minted per address
        uint256 swarmUnitSpawnCostToken; // Cost in SwarmToken to spawn a unit
        uint256 swarmUnitSpawnCostETH; // Cost in ETH to spawn a unit
        uint256 minUnitsForMerge; // Minimum units required for merging
        uint256 mergeSuccessCohesionThreshold; // Min total cohesion for successful merge
        uint256 minTokenBalanceForProposal; // Minimum tokens required to create a proposal
        uint256 minUnitsStakedForProposal; // Minimum staked units required to create a proposal
        uint256 proposalVotingPeriod; // Duration of voting period in seconds
        uint256 proposalExecutionTimelock; // Timelock before a successful proposal can be executed
        uint256 proposalQuorumThreshold; // Percentage of total supply needed to vote for quorum (basis points)
        uint256 proposalMajorityThreshold; // Percentage of votes needed for success (basis points)
        // Add other parameters like stat decay rates, action effects, etc.
    }
    ProtocolParameters public protocolParameters;

    // Governance State
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        // bytes data; // Encoded function call data for execution (e.g., setProtocolParameters)
        bytes32 dataHash; // Hash of the call data to prevent manipulation
        uint256 startBlock;
        uint256 endBlock;
        uint256 tokenVotesFor;
        uint256 tokenVotesAgainst;
        mapping(address => bool) hasVoted; // Voter => Voted
        ProposalState state;
        uint48 executionTimelockEnd; // Timestamp when execution is possible
        // Add more fields: description hash, unit vote weight, etc.
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    mapping(bytes32 => uint256) private _proposalIdByDataHash; // To prevent duplicate active proposals

    // Treasury State
    address public treasuryAddress;

    // Meta-Transaction State
    mapping(address => uint256) private _nonces; // For meta-transaction replay protection

    // --- ENUMS ---
    enum SwarmActionType { Explore, Defend, Gather, Rest } // Example actions

    // --- EVENTS ---
    event SwarmTokenMinted(address indexed recipient, uint256 amount);
    event SwarmTokenBurned(address indexed burner, uint256 amount);
    event SwarmUnitSpawned(address indexed owner, uint256 tokenId);
    event SwarmUnitBurned(address indexed burner, uint256 tokenId);
    event UnitStatsUpdated(uint256 indexed tokenId, SwarmUnitStats newStats, string reason);
    event SwarmActionPerformed(address indexed caller, uint256[] indexed unitIds, SwarmActionType action);
    event UnitsMerged(address indexed owner, uint256[] indexed sourceUnitIds, uint256 indexed newUnitId);
    event UnitSacrificed(address indexed owner, uint256 indexed tokenId, uint256 tokensGained);
    event UnitsStaked(address indexed owner, uint256[] indexed unitIds);
    event UnitsUnstaked(address indexed owner, uint256[] indexed unitIds);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 dataHash, uint256 endBlock);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposit(address indexed sender, uint256 amountEth, uint256 amountTokens);
    event TreasuryWithdrawal(address indexed recipient, address indexed token, uint256 amount);
    event OracleDataReceived(uint256 indexed tokenId, bytes data);
    event MetaTransactionExecuted(address indexed user, bytes32 indexed functionHash, bytes32 indexed signatureHash);
    event ProtocolParametersUpdated(ProtocolParameters newParameters);

    // --- CONSTRUCTOR / INITIALIZER ---
    // Use initialize for UUPS proxy pattern compatibility
    function initialize(address admin) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PARAM_SETTER_ROLE, admin);
        _setupRole(ORACLE_ROLE, admin);
        _setupRole(TREASURY_ADMIN_ROLE, admin); // Treasury admin can perform treasury actions if governance fails, etc.
        _setupRole(META_TX_RELAYER_ROLE, admin); // Example relayer role

        // Deploy dummy tokens for demonstration. In production, would deploy/link actual tokens.
        // Note: ERC20/ERC721 standard requires name and symbol.
        swarmToken = new ERC20("Swarm Token", "SWT");
        swarmUnitNFT = new ERC721("Swarm Unit", "SWU");

        // Set initial parameters (can be 0 or sensible defaults)
        protocolParameters = ProtocolParameters({
            swarmTokenMintLimitPerAddress: 1000 ether, // Example limit
            swarmUnitSpawnCostToken: 100 ether, // Example cost
            swarmUnitSpawnCostETH: 0.01 ether, // Example cost
            minUnitsForMerge: 2,
            mergeSuccessCohesionThreshold: 1500, // Combined cohesion
            minTokenBalanceForProposal: 500 ether,
            minUnitsStakedForProposal: 5,
            proposalVotingPeriod: 1 days, // Example period
            proposalExecutionTimelock: 1 hours, // Example timelock
            proposalQuorumThreshold: 4000, // 40% in basis points
            proposalMajorityThreshold: 5100 // 51% in basis points
        });

        // Set a dummy treasury address initially
        treasuryAddress = address(this); // Contract is its own treasury initially, can be changed

        emit ProtocolParametersUpdated(protocolParameters);
    }

    // Modifier for initializer pattern
    modifier initializer() {
        // Minimal proxy check - ensures it's called only once during initialization
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || !_isInitialized(), "Already initialized");
        _;
        _setInitialized();
    }

    bool private _initialized;
    function _isInitialized() private view returns (bool) {
        return _initialized;
    }
    function _setInitialized() private {
        _initialized = true;
    }


    // --- ERC20 WRAPPER FUNCTIONS ---

    function mintSwarmToken(address recipient, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Add checks for mint limits if needed based on protocolParameters
        swarmToken.mint(recipient, amount);
        emit SwarmTokenMinted(recipient, amount);
    }

    function burnSwarmToken(uint256 amount) public {
        swarmToken.burn(_msgSender(), amount);
        emit SwarmTokenBurned(_msgSender(), amount);
    }

    // Standard ERC20 functions exposed
    function transfer(address to, uint256 amount) public returns (bool) {
        return swarmToken.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        return swarmToken.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return swarmToken.approve(spender, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return swarmToken.balanceOf(account);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return swarmToken.allowance(owner, spender);
    }


    // --- ERC721 WRAPPER FUNCTIONS ---

    function spawnSwarmUnit(address owner) public payable {
        // Add complex logic here: require tokens, ETH, check limits etc.
        // require(swarmToken.balanceOf(_msgSender()) >= protocolParameters.swarmUnitSpawnCostToken, NotEnoughTokens());
        // require(msg.value >= protocolParameters.swarmUnitSpawnCostETH, "Not enough ETH sent");
        // swarmToken.transferFrom(_msgSender(), treasuryAddress, protocolParameters.swarmUnitSpawnCostToken);
        // If ETH cost is > 0, forward excess ETH or handle exact amount
        // if (protocolParameters.swarmUnitSpawnCostETH > 0 && msg.value > protocolParameters.swarmUnitSpawnCostETH) {
        //     payable(msg.sender).transfer(msg.value - protocolParameters.swarmUnitSpawnCostETH);
        // }


        _unitIds.increment();
        uint256 newTokenId = _unitIds.current();
        swarmUnitNFT.safeMint(owner, newTokenId);

        // Initialize basic stats for the new unit
        unitStats[newTokenId] = SwarmUnitStats({
            energy: 500, // Starting energy
            cohesion: 500, // Starting cohesion
            lastUpdated: uint48(block.timestamp),
            status: "Idle"
        });

        emit SwarmUnitSpawned(owner, newTokenId);
        emit UnitStatsUpdated(newTokenId, unitStats[newTokenId], "Spawned");
    }

    function burnSwarmUnit(uint256 tokenId) public {
        require(swarmUnitNFT.ownerOf(tokenId) == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), CallerIsNotOwnerOrApproved());
        require(!isUnitStaked[tokenId], UnitIsStaked(tokenId));

        swarmUnitNFT.burn(tokenId);
        delete unitStats[tokenId]; // Remove stats when burned

        emit SwarmUnitBurned(_msgSender(), tokenId);
    }

    // Standard ERC721 functions exposed, with staking checks
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!isUnitStaked[tokenId], StakedUnitCannotBeTransferred());
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         require(!isUnitStaked[tokenId], StakedUnitCannotBeTransferred());
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         require(!isUnitStaked[tokenId], StakedUnitCannotBeTransferred());
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Approve and setApprovalForAll can be called even if staked, they don't move the unit
    function approve(address to, uint256 tokenId) public override {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

    // Standard query functions remain unchanged
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return swarmUnitNFT.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return swarmUnitNFT.balanceOf(owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address operator) {
        return swarmUnitNFT.getApproved(tokenId);
    }

     function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return swarmUnitNFT.isApprovedForAll(owner, operator);
    }


    // --- UNIT DYNAMICS & INTERACTION FUNCTIONS ---

    function getUnitStats(uint256 tokenId) public view returns (SwarmUnitStats memory) {
        // Decay stats based on time since last update before returning
        // (Complex logic omitted for brevity, but should be applied here or in helper)
        require(swarmUnitNFT.exists(tokenId), SwarmUnitDoesNotExist(tokenId));
        return unitStats[tokenId];
    }

    function performSwarmAction(uint256[] calldata unitIds, SwarmActionType action) public {
        require(unitIds.length > 0, "No units provided");

        // Basic authorization: all units must belong to the caller OR be approved
        address caller = _msgSender();
        for (uint256 i = 0; i < unitIds.length; i++) {
             uint256 tokenId = unitIds[i];
             require(swarmUnitNFT.exists(tokenId), SwarmUnitDoesNotExist(tokenId));
             require(
                swarmUnitNFT.ownerOf(tokenId) == caller || swarmUnitNFT.isApprovedForAll(swarmUnitNFT.ownerOf(tokenId), caller) || swarmUnitNFT.getApproved(tokenId) == caller,
                CallerIsNotOwnerOrApproved() // Not owner, approved, or operator
            );
             require(!isUnitStaked[tokenId], UnitIsStaked(tokenId));
        }

        // --- Complex Action Logic ---
        // This is where the core game/simulation logic resides.
        // Effects vary significantly based on action type.
        // Could involve consuming energy, changing cohesion, interacting with other units,
        // requiring token payment, generating rewards, etc.

        if (action == SwarmActionType.Explore) {
            // Example: Consume energy, potentially gain rewards, randomly affect cohesion
             for (uint256 i = 0; i < unitIds.length; i++) {
                uint256 tokenId = unitIds[i];
                SwarmUnitStats storage stats = unitStats[tokenId];
                // Example: Reduce energy by 100
                stats.energy = stats.energy < 100 ? 0 : stats.energy - 100;
                 // Example: Randomly change cohesion by up to +/- 50 (requires randomness source, e.g., Chainlink VRF)
                 // For this example, use a simple deterministic change based on block.timestamp
                stats.cohesion = uint128(int256(stats.cohesion) + (int256(block.timestamp % 101) - 50));
                if (stats.cohesion > 1000) stats.cohesion = 1000;
                if (stats.cohesion < 0) stats.cohesion = 0;

                stats.lastUpdated = uint48(block.timestamp);
                stats.status = "Exploring";
                emit UnitStatsUpdated(tokenId, stats, "Explored");
             }
             // Potentially distribute rewards to participants' owners from treasury
        } else if (action == SwarmActionType.Defend) {
            // Example: Consume less energy, increase cohesion
             for (uint256 i = 0; i < unitIds.length; i++) {
                 uint256 tokenId = unitIds[i];
                 SwarmUnitStats storage stats = unitStats[tokenId];
                 stats.energy = stats.energy < 50 ? 0 : stats.energy - 50;
                 stats.cohesion = stats.cohesion > 950 ? 1000 : stats.cohesion + 50;
                 stats.lastUpdated = uint48(block.timestamp);
                 stats.status = "Defending";
                 emit UnitStatsUpdated(tokenId, stats, "Defended");
             }
        } // Add other action types...
        else {
             revert InvalidSwarmAction();
        }

        emit SwarmActionPerformed(caller, unitIds, action);
    }

    function mergeSwarmUnits(uint256[] calldata sourceUnitIds) public {
         require(sourceUnitIds.length >= protocolParameters.minUnitsForMerge, UnitsCannotMerge());

         address caller = _msgSender();
         uint256 totalCohesion = 0;
         // Check ownership/approval and gather stats
         for (uint256 i = 0; i < sourceUnitIds.length; i++) {
             uint256 tokenId = sourceUnitIds[i];
             require(swarmUnitNFT.exists(tokenId), SwarmUnitDoesNotExist(tokenId));
              require(
                swarmUnitNFT.ownerOf(tokenId) == caller || swarmUnitNFT.isApprovedForAll(swarmUnitNFT.ownerOf(tokenId), caller) || swarmUnitNFT.getApproved(tokenId) == caller,
                CallerIsNotOwnerOrApproved() // Not owner, approved, or operator
            );
             require(!isUnitStaked[tokenId], UnitIsStaked(tokenId));

             totalCohesion += unitStats[tokenId].cohesion;
         }

         require(totalCohesion >= protocolParameters.mergeSuccessCohesionThreshold, UnitsCannotMerge());

         // Burn source units
         for (uint256 i = 0; i < sourceUnitIds.length; i++) {
             swarmUnitNFT.burn(sourceUnitIds[i]);
             delete unitStats[sourceUnitIds[i]];
         }

         // Spawn a new unit
         _unitIds.increment();
         uint256 newUnitId = _unitIds.current();
         swarmUnitNFT.safeMint(caller, newUnitId);

         // Calculate new unit stats (example: average stats)
         uint128 newEnergy = 0;
         uint128 newCohesion = 0;
         // Re-iterate (could optimize by doing this in the first loop if stats were saved)
         for (uint256 i = 0; i < sourceUnitIds.length; i++) {
             // Note: stats are deleted, need to calculate based on *pre-merge* average or re-fetch (less efficient)
             // A better design might calculate new stats BEFORE burning. Let's simulate average based on deleted stats.
             // In a real scenario, you'd pass pre-calculated stats or store them temporarily.
             // For this example, let's just give it a high baseline.
              newEnergy += 800; // Example baseline after merge
              newCohesion += 800; // Example baseline after merge
         }
         newEnergy /= uint128(sourceUnitIds.length);
         newCohesion /= uint128(sourceUnitIds.length);


         unitStats[newUnitId] = SwarmUnitStats({
             energy: newEnergy,
             cohesion: newCohesion,
             lastUpdated: uint48(block.timestamp),
             status: "Merged_New"
         });

         emit UnitsMerged(caller, sourceUnitIds, newUnitId);
         emit UnitStatsUpdated(newUnitId, unitStats[newUnitId], "Merged");
    }

    function sacrificeUnit(uint256 tokenId) public {
        address caller = _msgSender();
        require(swarmUnitNFT.ownerOf(tokenId) == caller || swarmUnitNFT.isApprovedForAll(swarmUnitNFT.ownerOf(tokenId), caller), CallerIsNotOwnerOrApproved());
        require(!isUnitStaked[tokenId], UnitIsStaked(tokenId));

        // Logic for sacrifice effect:
        // Example: Burn unit, owner gets some tokens back based on unit stats
        SwarmUnitStats memory stats = unitStats[tokenId];
        uint256 tokensToReturn = (uint256(stats.energy) + uint256(stats.cohesion)) * 1 ether / 1000; // Example calculation

        burnSwarmUnit(tokenId); // This also deletes stats

        if (tokensToReturn > 0) {
            // Assuming contract has tokens or can mint (if allowed)
            // swarmToken.transfer(caller, tokensToReturn); // If tokens are in treasury
            mintSwarmToken(caller, tokensToReturn); // If contract can mint
            emit UnitSacrificed(caller, tokenId, tokensToReturn);
        } else {
             emit UnitSacrificed(caller, tokenId, 0);
        }
    }


    // --- STAKING FUNCTIONS ---

    function stakeSwarmUnits(uint256[] calldata unitIds) public {
         address caller = _msgSender();
         require(unitIds.length > 0, "No units provided");

         for (uint256 i = 0; i < unitIds.length; i++) {
             uint256 tokenId = unitIds[i];
             require(swarmUnitNFT.ownerOf(tokenId) == caller || swarmUnitNFT.isApprovedForAll(swarmUnitNFT.ownerOf(tokenId), caller), CallerIsNotOwnerOrApproved());
             require(!isUnitStaked[tokenId], UnitIsStaked(tokenId));

             isUnitStaked[tokenId] = true;
             _stakedUnitOwner[tokenId] = caller;
             _stakedUnitsByOwner[caller].push(tokenId); // Simple array, inefficient for large counts
             // A better approach for _stakedUnitsByOwner would be linked list or mapping
         }
         emit UnitsStaked(caller, unitIds);
         // Add logic for staking rewards/benefits if any
    }

    function unstakeSwarmUnits(uint256[] calldata unitIds) public {
        address caller = _msgSender();
        require(unitIds.length > 0, "No units provided");

        for (uint256 i = 0; i < unitIds.length; i++) {
            uint256 tokenId = unitIds[i];
            require(isUnitStaked[tokenId], UnitIsNotStaked(tokenId));
            require(_stakedUnitOwner[tokenId] == caller, "Not your staked unit");

            isUnitStaked[tokenId] = false;
            delete _stakedUnitOwner[tokenId];

            // Simple array removal (inefficient) - find and swap with last element
            uint256[] storage stakedUnits = _stakedUnitsByOwner[caller];
            for (uint256 j = 0; j < stakedUnits.length; j++) {
                if (stakedUnits[j] == tokenId) {
                    stakedUnits[j] = stakedUnits[stakedUnits.length - 1];
                    stakedUnits.pop();
                    break; // Found and removed
                }
            }
             // Add logic for unstaking penalties or claiming accumulated rewards if any
        }
         emit UnitsUnstaked(caller, unitIds);
    }

    function getUnitStakeStatus(uint256 tokenId) public view returns (bool staked, address owner) {
         return (isUnitStaked[tokenId], _stakedUnitOwner[tokenId]);
    }


    // --- GOVERNANCE FUNCTIONS ---

    // Helper to check voting power (simplified: total token balance)
    function _getVotePower(address voter) internal view returns (uint256) {
        // Could add staked units, delegated tokens, reputation score, etc.
        return swarmToken.balanceOf(voter);
    }

    function proposeParameterChange(bytes calldata data) public {
        address proposer = _msgSender();
        require(_getVotePower(proposer) >= protocolParameters.minTokenBalanceForProposal || getStakedUnitsCount(proposer) >= protocolParameters.minUnitsStakedForProposal, ProposalThresholdNotMet());

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        bytes32 dataHash = keccak256(data);

        // Optional: Check if an identical proposal is already active
        // require(_proposalIdByDataHash[dataHash] == 0 || proposals[_proposalIdByDataHash[dataHash]].state > ProposalState.Active, "Identical proposal is active");
        _proposalIdByDataHash[dataHash] = proposalId;


        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: proposer,
            dataHash: dataHash,
            startBlock: block.number,
            endBlock: block.number + (protocolParameters.proposalVotingPeriod / block.chainid), // Using block number for simplicity
            tokenVotesFor: 0,
            tokenVotesAgainst: 0,
            state: ProposalState.Active,
            executionTimelockEnd: 0 // Will be set on success
        });

        emit ProposalCreated(proposalId, proposer, dataHash, proposals[proposalId].endBlock);
    }

    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, ProposalDoesNotExist(proposalId));
        require(proposal.state == ProposalState.Active, ProposalNotInCorrectState(proposalId, ProposalState.Active));
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], AlreadyVoted(proposalId, _msgSender()));

        uint256 votePower = _getVotePower(_msgSender());
        require(votePower > 0, "No vote power"); // Must hold tokens to vote

        proposal.hasVoted[_msgSender()] = true;
        if (support) {
            proposal.tokenVotesFor += votePower;
        } else {
            proposal.tokenVotesAgainst += votePower;
        }

        emit ProposalVoted(proposalId, _msgSender(), support, votePower);
    }

    function executeProposal(uint256 proposalId) public onlyRole(DEFAULT_ADMIN_ROLE) { // Typically only admin or a trusted executor can call this
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, ProposalDoesNotExist(proposalId));
         require(proposal.state == ProposalState.Queued, ProposalNotInCorrectState(proposalId, ProposalState.Queued));
        require(uint48(block.timestamp) >= proposal.executionTimelockEnd, ProposalTimelockNotPassed(proposalId, proposal.executionTimelockEnd));

        // --- Execute the actual change ---
        // This is complex: The `data` in the proposal struct (or its hash)
        // should be used to call a function, likely `setProtocolParameters`.
        // A robust governance system would use delegatecall or a specialized
        // executor contract to handle complex function calls.
        // For this example, we'll just simulate the effect.
        // In reality, you'd need a mechanism to retrieve the actual call data from the hash.
        // Example: setProtocolParameters(newParams)

        // Call the function encoded in the proposal data
        // (Needs the actual data, hashing prevents retrieval from hash alone.
        // Real systems store data or use a well-defined proposal interface)
        // bool success = address(this).call(decodeData(proposal.dataHash)); // Example placeholder

        // Since we only hashed the data, let's assume a successful execution for this demo
        // and transition state. A real system must *actually* execute the call.

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

     function cancelProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, ProposalDoesNotExist(proposalId));
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, ProposalNotInCorrectState(proposalId, proposal.state));
        // Allow proposer to cancel before voting starts or if conditions unmet
        require(proposal.proposer == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only proposer or admin can cancel");
        // Add checks, e.g., if voting period is over or certain votes reached

        proposal.state = ProposalState.Canceled;
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }

    // Helper to update proposal state based on current block/votes (can be called by anyone)
    function updateProposalState(uint256 proposalId) public {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, ProposalDoesNotExist(proposalId));

         if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
             // Voting period ended, determine outcome
             uint256 totalVotes = proposal.tokenVotesFor + proposal.tokenVotesAgainst;
             uint256 totalTokenSupply = swarmToken.totalSupply();
             // Check Quorum (percentage of total supply that voted)
             bool quorumMet = totalTokenSupply > 0 && totalVotes * 10000 / totalTokenSupply >= protocolParameters.proposalQuorumThreshold;

             if (quorumMet && proposal.tokenVotesFor > proposal.tokenVotesAgainst && totalVotes > 0) {
                 // Majority check (percentage of cast votes that are For)
                 bool majorityMet = proposal.tokenVotesFor * 10000 / totalVotes >= protocolParameters.proposalMajorityThreshold;
                 if (majorityMet) {
                     proposal.state = ProposalState.Succeeded;
                     // Set execution timelock
                     proposal.executionTimelockEnd = uint48(block.timestamp + protocolParameters.proposalExecutionTimelock);
                     emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
                     emit ProposalStateChanged(proposalId, ProposalState.Queued); // Typically transitions to queued before executable
                 } else {
                      proposal.state = ProposalState.Defeated;
                      emit ProposalStateChanged(proposalId, ProposalState.Defeated);
                 }
             } else {
                 proposal.state = ProposalState.Defeated;
                 emit ProposalStateChanged(proposalId, ProposalState.Defeated);
             }
         }
         // Add checks to transition from Succeeded to Queued if needed, etc.
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
         require(proposals[proposalId].id != 0, ProposalDoesNotExist(proposalId));
         return proposals[proposalId].state;
    }


    // --- TREASURY FUNCTIONS ---

    function depositTreasury() public payable {
        // Allow anyone to send ETH
        if (msg.value > 0) {
             // ETH sent to contract address
             // No explicit transfer needed, it arrives here
        }
        // Allow sending SwarmToken (requires caller to approve contract first)
        // Example: User approves contract for 100 SWT, then calls depositTreasury(100)
        // function depositTreasuryTokens(uint256 amount) public {
        //    swarmToken.transferFrom(_msgSender(), address(this), amount);
        //    emit TreasuryDeposit(_msgSender(), 0, amount);
        // }
        // Combining ETH and Tokens in one function is complex without a helper or different pattern.
        // Let's keep this function just for ETH deposits for simplicity.
         if (msg.value > 0) {
             emit TreasuryDeposit(_msgSender(), msg.value, 0);
         } else {
             revert("No ETH sent");
         }
    }

    // This function should be restricted, typically callable ONLY by Governance execution
    function withdrawTreasury(address token, address recipient, uint256 amount) public onlyRole(TREASURY_ADMIN_ROLE) {
        // Note: In a real system, this would be callable by the governance executor after a proposal passes.
        // Using TREASURY_ADMIN_ROLE here as a placeholder.

        if (token == address(0)) { // ETH withdrawal
            payable(recipient).transfer(amount);
        } else { // ERC20 withdrawal
            IERC20(token).transfer(recipient, amount);
        }
        emit TreasuryWithdrawal(_msgSender(), token, amount);
    }


    // --- ORACLE INTEGRATION FUNCTION ---

    // Allows a trusted oracle to push data and update unit stats
    function updateUnitStatsFromOracle(uint256 tokenId, bytes calldata oracleData) public onlyRole(ORACLE_ROLE) {
        require(swarmUnitNFT.exists(tokenId), SwarmUnitDoesNotExist(tokenId));

        SwarmUnitStats storage stats = unitStats[tokenId];

        // --- Process Oracle Data ---
        // This is highly dependent on the oracle's data format.
        // Example: Oracle provides new energy and cohesion values encoded in bytes
        // For this example, we'll just simulate adding/subtracting
        // In reality, you'd decode `oracleData` safely.
        // Example: abi.decode(oracleData, (int256 energyChange, int256 cohesionChange))

        int256 energyChange = 10; // Simulated data effect
        int256 cohesionChange = -5; // Simulated data effect

        int256 newEnergy = int256(stats.energy) + energyChange;
        int256 newCohesion = int256(stats.cohesion) + cohesionChange;

        // Clamp stats within valid range (0-1000)
        stats.energy = uint128(newEnergy < 0 ? 0 : (newEnergy > 1000 ? 1000 : newEnergy));
        stats.cohesion = uint128(newCohesion < 0 ? 0 : (newCohesion > 1000 ? 1000 : newCohesion));

        stats.lastUpdated = uint48(block.timestamp);
        // Status might also change based on oracle data

        emit OracleDataReceived(tokenId, oracleData);
        emit UnitStatsUpdated(tokenId, stats, "Oracle Update");
    }


    // --- META-TRANSACTION FUNCTION ---

    // Allows users to sign messages permitting a relayer (META_TX_RELAYER_ROLE) to execute functions on their behalf
    // without the user paying gas.
    // The user signs a hash of their address, nonce, contract address, chain ID, and the function call data.
    function executeMetaTransaction(
        address user,
        bytes calldata functionCallData,
        bytes memory signature
    ) public onlyRole(META_TX_RELAYER_ROLE) {
        // Reconstruct the message hash that the user signed
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("SentientSwarmProtocol"), // dApp Name
                keccak256("1"), // Version
                block.chainid,
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("MetaTransaction(address user,uint256 nonce,bytes data)"),
                user,
                _nonces[user],
                keccak256(functionCallData) // Hash the call data
            )
        );

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash)));

        // Recover the signer address
        address signer = messageHash.recover(signature);

        require(signer == user, InvalidSignature());

        // Increment nonce to prevent replay attacks
        _nonces[user]++;

        // Execute the function call on behalf of the user
        // IMPORTANT SECURITY NOTE: A naive `user.call(functionCallData)` is extremely dangerous!
        // It would allow the user to call *any* function on *any* contract via the relayer,
        // potentially draining funds or executing malicious logic.
        // A safer approach is to ONLY allow calls to *this* contract (`address(this)`)
        // and potentially restrict which functions can be called this way.
        // For this example, let's enforce that the target is this contract.

        // To further restrict, you might parse functionCallData or require the user to sign
        // a specific struct representing the allowed action parameters instead of raw bytes.

        (bool success, ) = address(this).call(functionCallData); // Call target is *this* contract
        require(success, "Meta transaction failed");

        emit MetaTransactionExecuted(user, keccak256(functionCallData), keccak256(signature));
    }

     // Function to get the current nonce for a user
     function getNonce(address user) public view returns (uint256) {
         return _nonces[user];
     }

    // --- QUERY FUNCTIONS ---

    function getProtocolParameters() public view returns (ProtocolParameters memory) {
        return protocolParameters;
    }

    function getTotalUnitsSpawned() public view returns (uint256) {
         return _unitIds.current();
    }

    function getStakedUnitsCount(address owner) public view returns (uint256) {
        // Simple array count (inefficient for many staked units per owner)
        return _stakedUnitsByOwner[owner].length;
    }

    function getTreasuryBalance(address token) public view returns (uint256) {
        if (token == address(0)) { // ETH
            return address(this).balance;
        } else { // ERC20
            return IERC20(token).balanceOf(address(this));
        }
    }

    // ERC165 support for AccessControl (required)
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Make received ETH available for treasury/withdrawals
    receive() external payable {
        emit TreasuryDeposit(_msgSender(), msg.value, 0);
    }
}

// Minimal dummy implementations for ERC20 and ERC721 to make the contract compilable
// In a real scenario, you would import the actual OpenZeppelin contracts or your own implementations.
// These are included here just to satisfy the contract's dependencies for demonstration.
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; } // Standard
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address to, uint256 amount) public virtual override returns (bool) { _transfer(_msgSender(), to, amount); return true; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) { _approve(_msgSender(), spender, amount); return true; }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { uint256 currentAllowance = _allowances[from][_msgSender()]; require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance"); unchecked { _approve(from, _msgSender(), currentAllowance - amount); } _transfer(from, to, amount); return true; }
    function _transfer(address from, address to, uint256 amount) internal virtual { require(from != address(0), "ERC20: transfer from the zero address"); require(to != address(0), "ERC20: transfer to the zero address"); _beforeTokenTransfer(from, to, amount); uint256 fromBalance = _balances[from]; require(fromBalance >= amount, "ERC20: transfer amount exceeds balance"); unchecked { _balances[from] = fromBalance - amount; } _balances[to] += amount; emit Transfer(from, to, amount); _afterTokenTransfer(from, to, amount); }
    function _mint(address account, uint256 amount) internal virtual { require(account != address(0), "ERC20: mint to the zero address"); _beforeTokenTransfer(address(0), account, amount); _totalSupply += amount; _balances[account] += amount; emit Transfer(address(0), account, amount); _afterTokenTransfer(address(0), account, amount); }
    function _burn(address account, uint256 amount) internal virtual { require(account != address(0), "ERC20: burn from the zero address"); _beforeTokenTransfer(account, address(0), amount); uint256 accountBalance = _balances[account]; require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); unchecked { _balances[account] = accountBalance - amount; } _totalSupply -= amount; emit Transfer(account, address(0), amount); _afterTokenTransfer(account, address(0), amount); }
    function _approve(address owner, address spender, uint256 amount) internal virtual { require(owner != address(0), "ERC20: approve from the zero address"); require(spender != address(0), "ERC20: approve to the zero address"); _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC721 is IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _name;
    string private _symbol;
    uint256[] private _allTokens; // Added for ERC721Enumerable simplicity
    mapping(uint256 => uint256) private _allTokensIndex; // Added for ERC721Enumerable simplicity
    mapping(address => uint256[]) private _ownedTokens; // Added for ERC721Enumerable simplicity
    mapping(uint256 => uint256) private _ownedTokensIndex; // Added for ERC721Enumerable simplicity


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }
     function balanceOf(address owner) public view virtual override(IERC721, ERC721) returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override(IERC721, ERC721) returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         return ""; // Dummy URI
    }
    function approve(address to, uint256 tokenId) public virtual override(IERC721, ERC721) {
        address owner = ERC721.ownerOf(tokenId); // Use fully qualified name
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override(IERC721, ERC721) returns (address operator) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721, ERC721) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override(IERC721, ERC721) returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721, ERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(IERC721, ERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(IERC721, ERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function totalSupply() public view virtual override(IERC721Enumerable, ERC721) returns (uint256) { return _allTokens.length; }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) { require(index < _allTokens.length, "ERC721Enumerable: all tokens index out of bounds"); return _allTokens[index]; }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) { require(index < _ownedTokens[owner].length, "ERC721Enumerable: owner index out of bounds"); return _ownedTokens[owner][index]; }


    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) { return _owners[tokenId] != address(0); }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId); // Use fully qualified name
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        _addTokenToAllTokensEnumeration(tokenId); // For Enumerable
        _addTokenToOwnerEnumeration(to, tokenId); // For Enumerable
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
     function burn(uint256 tokenId) public virtual { // Changed to public for example
        address owner = ERC721.ownerOf(tokenId); // Use fully qualified name
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved"); // Allow approved burner
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        _removeTokenFromAllTokensEnumeration(tokenId); // For Enumerable
        _removeTokenFromOwnerEnumeration(owner, tokenId); // For Enumerable
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
     }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        _removeTokenFromOwnerEnumeration(from, tokenId); // For Enumerable
        _addTokenToOwnerEnumeration(to, tokenId); // For Enumerable
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // Use fully qualified name
    }
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
         if (to.isContract()) {
             try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                 return retval == IERC721Receiver.onERC721Received.selector;
             } catch (bytes memory reason) {
                 if (reason.length > 0) { assembly { revert(add(32, reason), mload(reason)) } } else { revert("ERC721: transfer to non ERC721Receiver implementer"); }
             }
         } else { return true; }
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // ERC721Enumerable helpers (simple array based, not efficient for large number of tokens)
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _allTokens[lastTokenIndex];
            _allTokens[tokenIndex] = lastTokenId;
            _allTokensIndex[lastTokenId] = tokenIndex;
        }
        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    // Override for AccessControl conflict with ERC165
    function _msgSender() internal view virtual override(Context, AccessControl) returns (address) {
        return Context._msgSender();
    }
    function _msgData() internal view virtual override(Context, AccessControl) returns (bytes calldata) {
         return Context._msgData();
    }
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) { return functionCall(target, data, "Address: low-level call failed"); }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) { return functionCallWithValue(target, data, 0, errorMessage); }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) { return functionCallWithValue(target, data, value, "Address: low-level call with value failed"); }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) { assembly { let returndata_size := mload(returndata) let returndata_offset := add(32, returndata) revert(returndata_offset, returndata_size) } } else { revert(errorMessage); }
        }
    }
}
library Strings { function toString(uint256 value) internal pure returns (string memory) { if (value == 0) { return "0"; } uint256 temp = value; uint256 digits; while (temp != 0) { digits++; temp /= 10; } bytes memory buffer = new bytes(digits); while (value != 0) { digits -= 1; buffer[digits] = bytes1(uint8(48 + value % 10)); value /= 10; } return string(buffer); } }
```