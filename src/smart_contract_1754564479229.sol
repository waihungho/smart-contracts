This smart contract, **ChronoCaster**, introduces a novel protocol for conditional, time-anchored, and event-driven asset locking and release. It combines elements of DeFi, NFTs, and dynamic governance, allowing users to create "Chronospores"—unique digital constructs that encapsulate locked assets and release them only when a set of predefined, multi-faceted conditions are met. These conditions can range from simple time locks to complex external data triggers, internal contract state milestones, or even community votes.

The contract aims to be a foundation for decentralized escrow, programmatic vesting, conditional grants, and even speculative game theory, where participants can influence or contribute to the unlocking of assets.

---

## ChronoCaster Smart Contract Outline & Function Summary

**Contract Name:** `ChronoCaster`

**Core Concept:** A protocol for creating conditional asset locks (Chronospores) that release assets (ERC20, ERC721, ERC1155) based on time, external data feeds (oracles), internal contract state, or community governance. Each ChronoSpore is represented by an ERC721 NFT, allowing for transferable ownership of the locked asset's claim rights.

---

### **Outline**

1.  **State Variables & Constants:**
    *   Contract configuration (fees, addresses).
    *   Mapping for ChronoSpore data.
    *   NFT references (ChronoSpore NFT, Catalyst NFT).
    *   Access control roles.

2.  **Enums & Structs:**
    *   `ChronoSporeStatus`: `Pending`, `Active`, `Fulfilled`, `Cancelled`.
    *   `ConditionType`: `TimeBased`, `ExternalDataTrigger`, `InternalStateTrigger`, `VoteBased`.
    *   `ComparisonOperator`: `EQ`, `GT`, `LT`, `GTE`, `LTE`.
    *   `LockedAsset`: `tokenType`, `tokenAddress`, `amount`, `tokenId`.
    *   `Condition`: `conditionType`, `operator`, `value`, `targetAddress`, `isMet`, `metAt`.
    *   `ChronoSpore`: `owner`, `sporeNFTId`, `status`, `lockedAssets`, `conditions`, `isAllConditionsMet`, `createdAt`, `lastUpdate`, `totalERC20ValueLocked`, `isActive`.

3.  **Events:** For all significant state changes.

4.  **Modifiers:** For access control and state checks.

5.  **Constructor:** Initializes core contract parameters.

6.  **Core ChronoSpore Management Functions:**
    *   Creation, modification, and claiming.

7.  **Condition Management Functions:**
    *   Adding, updating, and checking conditions.
    *   Oracle integration (simulated).

8.  **Asset Management Functions:**
    *   Contributing, transferring assets.

9.  **Influence & Governance Functions:**
    *   Staking, voting, proposing overrides.

10. **Catalyst NFT Functions:**
    *   Minting, using special powers.

11. **Admin & Utility Functions:**
    *   Pausing, setting fees, whitelisting.

12. **View Functions:**
    *   Retrieving ChronoSpore and condition details.

---

### **Function Summary (22 Functions)**

1.  **`constructor(address _chronoSporeNFT, address _catalystNFT, address _initialOracleFeeder, address _initialFeeRecipient)`**
    *   Initializes the contract with addresses for the ChronoSpore NFT, Catalyst NFT, and initial roles.

2.  **`createChronoSpore(address[] calldata _tokenAddresses, uint256[] calldata _amountsOrTokenIds, uint8[] calldata _tokenTypes, Condition[] calldata _initialConditions, string calldata _metadataURI)`**
    *   **Concept:** Allows a user to lock ERC20, ERC721, or ERC1155 assets by defining an array of `LockedAsset` structs and an array of `Condition` structs. A unique `ChronoSpore` (ERC721 NFT) is minted to the creator, representing ownership of the locked assets and their claim rights.
    *   **Advanced:** Supports multiple asset types and multiple complex conditions defined at creation.

3.  **`addConditionToChronoSpore(uint256 _sporeId, Condition calldata _newCondition)`**
    *   **Concept:** The owner of a ChronoSpore can add new conditions to an existing spore, provided the spore is not yet fulfilled or cancelled.
    *   **Advanced:** Enables dynamic modification of release terms.

4.  **`updateOracleData(uint256 _sporeId, address _oracleAddress, uint256 _newValue)`**
    *   **Concept:** A designated `ORACLE_FEEDER_ROLE` (or contract owner in this simplified example) can push new data from a simulated oracle for a specific ChronoSpore. This updates `ExternalDataTrigger` conditions.
    *   **Advanced:** Simulates external oracle integration, allowing for real-world event-triggered releases.

5.  **`checkChronoSporeConditions(uint256 _sporeId)`**
    *   **Concept:** Iterates through all conditions of a specific ChronoSpore to determine if they are all met. Updates the `isAllConditionsMet` flag. Can be called by anyone.
    *   **Advanced:** A public audit function that triggers internal state updates, critical for the claim process.

6.  **`claimChronoSporeAssets(uint256 _sporeId)`**
    *   **Concept:** Allows the current owner of a ChronoSpore NFT to claim the locked assets if all conditions for that spore are met. Transfers fees to the recipient before releasing assets.
    *   **Advanced:** Handles multi-asset type distribution and includes a fee mechanism.

7.  **`contributeToChronoSpore(uint256 _sporeId, address _tokenAddress, uint256 _amount)`**
    *   **Concept:** Allows other users to contribute additional ERC20 tokens to an existing ChronoSpore, increasing the pool of assets to be released. This could be used for crowd-funded conditional grants.
    *   **Advanced:** Enables collaborative conditional asset pools.

8.  **`proposeConditionOverride(uint256 _sporeId, uint256 _conditionIndex, bool _newMetStatus, string calldata _reason)`**
    *   **Concept:** Users who have staked the influence token can propose to override a specific condition's `isMet` status (force true or false), initiating a governance vote.
    *   **Advanced:** Introduces a decentralized governance mechanism for condition resolution, akin to dispute resolution.

9.  **`voteOnConditionOverride(uint256 _sporeId, uint256 _proposalId, bool _vote)`**
    *   **Concept:** Stakers can vote on active condition override proposals.
    *   **Advanced:** Implements a basic voting system for governance.

10. **`resolveConditionOverride(uint256 _sporeId, uint256 _proposalId)`**
    *   **Concept:** After a voting period, anyone can call this to finalize the override proposal based on vote outcome, updating the condition's status if passed.
    *   **Advanced:** Finalizes the governance process.

11. **`stakeInfluenceTokens(uint256 _amount)`**
    *   **Concept:** Users can stake a specific `_influenceTokenAddress` (e.g., a governance token) to gain voting power and propose overrides.
    *   **Advanced:** Introduces a staking mechanism tied to governance influence.

12. **`unstakeInfluenceTokens(uint256 _amount)`**
    *   **Concept:** Allows users to withdraw their staked influence tokens.
    *   **Advanced:** Standard unstaking functionality.

13. **`mintCatalystNFT(address _to, string calldata _tokenURI)`**
    *   **Concept:** A privileged role (e.g., `CATALYST_MINTER_ROLE`) can mint special `CatalystNFT`s. These NFTs grant unique abilities within the ChronoCaster system.
    *   **Advanced:** Introduces utility NFTs with special powers.

14. **`useCatalystPower_OverrideSingleCondition(uint256 _sporeId, uint256 _conditionIndex)`**
    *   **Concept:** A holder of a `CatalystNFT` can use its power to force a single condition of a ChronoSpore to be met, bypassing its original criteria. This could be a one-time use per NFT or a limited use.
    *   **Advanced:** Shows a powerful, non-duplicable ability tied to an NFT, adding strategic depth.

15. **`transferChronoSporeOwnership(uint256 _sporeId, address _newOwner)`**
    *   **Concept:** As Chronospores are ERC721 NFTs, their ownership can be transferred using standard ERC721 `transferFrom` or `safeTransferFrom` functions. This function provides a wrapper.
    *   **Advanced:** Enables a secondary market for conditional asset claims.

16. **`setChronoSporeFee(uint256 _newFeeBasisPoints)`**
    *   **Concept:** Admin function to adjust the percentage fee taken from claimed assets.
    *   **Admin:** Standard administrative control.

17. **`setFeeRecipient(address _newRecipient)`**
    *   **Concept:** Admin function to change the address where fees are sent.
    *   **Admin:** Standard administrative control.

18. **`pause()`**
    *   **Concept:** Admin function to pause all critical contract operations (creation, claiming, contributions) in case of emergency.
    *   **Security:** Standard `Pausable` pattern.

19. **`unpause()`**
    *   **Concept:** Admin function to unpause the contract.
    *   **Security:** Standard `Pausable` pattern.

20. **`getChronoSporeDetails(uint256 _sporeId)`**
    *   **Concept:** A view function to retrieve all details of a specific ChronoSpore.
    *   **Utility:** For off-chain querying.

21. **`getConditionStatus(uint256 _sporeId, uint256 _conditionIndex)`**
    *   **Concept:** A view function to check the status (`isMet`) of a particular condition within a ChronoSpore.
    *   **Utility:** For off-chain querying.

22. **`getTotalValueLocked(uint256 _sporeId, address _tokenAddress)`**
    *   **Concept:** A view function to get the total amount of a specific ERC20 token currently locked within a ChronoSpore.
    *   **Utility:** For off-chain querying.

---
**Note on "Don't Duplicate Any Open Source":** While this contract uses standard interfaces (`IERC20`, `IERC721`, `IERC1155`, `Ownable`, `Pausable`) and common Solidity patterns, the combination of conditional multi-asset locking, dynamic external/internal/vote-based conditions, NFT representation of locks, influence staking, and "Catalyst NFT" powers creates a unique, advanced protocol not directly replicated by common open-source projects like simple timelocks, standard escrow, or basic NFT marketplaces. The focus is on the *composition* and *interaction* of these features in a novel way.
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Dummy Interfaces for ChronoSporeNFT and CatalystNFT for compilation
interface IChronoSporeNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ICatalystNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title ChronoCaster
 * @dev A protocol for creating conditional, time-anchored, and event-driven asset locks.
 *      Users can lock ERC20, ERC721, and ERC1155 assets, defining complex release conditions
 *      based on time, external oracle data, internal contract state, or community governance.
 *      Each conditional lock is represented by a unique ERC721 NFT ("ChronoSpore").
 *
 * Outline:
 * 1. State Variables & Constants: Contract configuration, ChronoSpore data mappings, NFT addresses, access roles.
 * 2. Enums & Structs: Definitions for ChronoSpore status, condition types, locked asset details.
 * 3. Events: To signal important state changes for off-chain monitoring.
 * 4. Modifiers: For access control and state checks.
 * 5. Constructor: Initializes core contract parameters.
 * 6. Core ChronoSpore Management: Functions for creating, checking, and claiming Chronospores.
 * 7. Condition Management: Adding, updating, and verifying conditions, including oracle integration (simulated).
 * 8. Asset Management: Contributing additional assets to Chronospores.
 * 9. Influence & Governance: Staking, proposing, and voting on condition overrides.
 * 10. Catalyst NFT Integration: Minting and utilizing special powers from Catalyst NFTs.
 * 11. Admin & Utility: Pausing, setting fees, getting contract details.
 * 12. View Functions: For querying ChronoSpore and condition data.
 *
 * Function Summary (22 Functions):
 * 1. constructor: Initializes contract with NFT and role addresses.
 * 2. createChronoSpore: Locks assets with multi-faceted conditions, mints a ChronoSpore NFT.
 * 3. addConditionToChronoSpore: Allows ChronoSpore owner to add new conditions dynamically.
 * 4. updateOracleData: (Simulated) Pushes new data from an oracle to trigger external conditions.
 * 5. checkChronoSporeConditions: Verifies if all conditions for a spore are met.
 * 6. claimChronoSporeAssets: Allows ChronoSpore NFT owner to claim assets if conditions are met.
 * 7. contributeToChronoSpore: Enables users to add more assets to an existing ChronoSpore.
 * 8. proposeConditionOverride: Stakers can propose a vote to override a condition.
 * 9. voteOnConditionOverride: Stakers vote on an active condition override proposal.
 * 10. resolveConditionOverride: Finalizes a condition override proposal based on votes.
 * 11. stakeInfluenceTokens: Users stake tokens to gain governance influence.
 * 12. unstakeInfluenceTokens: Users withdraw their staked influence tokens.
 * 13. mintCatalystNFT: Admin/privileged role mints special utility Catalyst NFTs.
 * 14. useCatalystPower_OverrideSingleCondition: Catalyst NFT holder can force a condition to be met.
 * 15. transferChronoSporeOwnership: Wrapper for transferring ChronoSpore NFT ownership.
 * 16. setChronoSporeFee: Admin function to set the fee percentage on claimed assets.
 * 17. setFeeRecipient: Admin function to change the address receiving fees.
 * 18. pause: Admin function to pause contract operations.
 * 19. unpause: Admin function to unpause contract operations.
 * 20. getChronoSporeDetails: View function to retrieve all details of a ChronoSpore.
 * 21. getConditionStatus: View function to check the status of a specific condition.
 * 22. getTotalValueLocked: View function to get the total amount of a specific ERC20 token locked.
 */
contract ChronoCaster is Ownable, Pausable, ReentrancyGuard, ERC721Holder, ERC1155Holder {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IChronoSporeNFT public immutable CHRONO_SPORE_NFT;
    ICatalystNFT public immutable CATALYST_NFT;
    IERC20 public influenceToken; // Token used for staking and governance influence

    address public feeRecipient;
    uint256 public chronoSporeFeeBasisPoints; // 100 = 1%, 1 = 0.01%

    Counters.Counter private _chronoSporeIdCounter;
    Counters.Counter private _catalystIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Access Control Roles ---
    bytes32 public constant ORACLE_FEEDER_ROLE = keccak256("ORACLE_FEEDER_ROLE");
    bytes32 public constant CATALYST_MINTER_ROLE = keccak256("CATALYST_MINTER_ROLE");

    // --- Enums ---
    enum ChronoSporeStatus { Pending, Active, Fulfilled, Cancelled }
    enum ConditionType { TimeBased, ExternalDataTrigger, InternalStateTrigger, VoteBased }
    enum ComparisonOperator { EQ, GT, LT, GTE, LTE } // Equal, Greater Than, Less Than, Greater Than or Equal, Less Than or Equal
    enum TokenType { ERC20, ERC721, ERC1155 }

    // --- Structs ---
    struct LockedAsset {
        TokenType tokenType;
        address tokenAddress;
        uint256 amountOrId; // amount for ERC20, tokenId for ERC721, amount for ERC1155
    }

    struct Condition {
        ConditionType conditionType;
        ComparisonOperator operator;
        uint256 value; // Target value for comparison (e.g., timestamp, price, count)
        address targetAddress; // Relevant address (e.g., oracle address, specific token for price)
        bool isMet;
        uint64 metAt; // Timestamp when condition was met
    }

    struct ChronoSpore {
        address owner; // The owner of the ChronoSpore NFT
        ChronoSporeStatus status;
        LockedAsset[] lockedAssets;
        Condition[] conditions;
        bool isAllConditionsMet;
        uint64 createdAt;
        uint64 lastUpdate;
        mapping(address => uint256) erc20ValueLocked; // Track total ERC20 value locked per token
        bool isActive; // Can new conditions be added, or assets contributed?
    }

    struct ConditionOverrideProposal {
        uint256 sporeId;
        uint256 conditionIndex;
        bool newMetStatus; // The proposed status for the condition (true or false)
        uint64 createdAt;
        uint64 votingEndsAt;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        bool resolved;
        mapping(address => bool) hasVoted; // User => Voted
    }

    // --- Mappings ---
    mapping(uint256 => ChronoSpore) public chronoSpores; // sporeId => ChronoSpore
    mapping(address => uint256) public stakedInfluenceTokens; // user => amount staked
    mapping(uint256 => ConditionOverrideProposal) public proposals; // proposalId => Proposal
    mapping(address => uint256) public lastOracleDataReport; // oracleAddress => lastReportedValue (simulated)

    // --- Events ---
    event ChronoSporeCreated(uint256 indexed sporeId, address indexed creator, uint256 numAssets, uint256 numConditions, string metadataURI);
    event ConditionAdded(uint256 indexed sporeId, uint256 conditionIndex, ConditionType conditionType);
    event ChronoSporeConditionsChecked(uint256 indexed sporeId, bool allConditionsMet);
    event ChronoSporeClaimed(uint256 indexed sporeId, address indexed claimant, uint256 feeAmount);
    event ChronoSporeContributed(uint256 indexed sporeId, address indexed contributor, address tokenAddress, uint256 amount);
    event OracleDataUpdated(address indexed oracleAddress, uint256 newValue);
    event InfluenceTokensStaked(address indexed staker, uint256 amount);
    event InfluenceTokensUnstaked(address indexed unstaker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed sporeId, uint256 conditionIndex, bool newMetStatus);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalResolved(uint256 indexed proposalId, bool passed);
    event CatalystNFTMinted(address indexed to, uint256 indexed catalystId);
    event CatalystPowerUsed(address indexed user, uint256 indexed catalystId, uint256 indexed sporeId, uint256 conditionIndex);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ChronoSporeFeeUpdated(uint256 oldFeeBasisPoints, uint256 newFeeBasisPoints);

    // --- Modifiers ---
    modifier onlyChronoSporeOwner(uint256 _sporeId) {
        require(CHRONO_SPORE_NFT.ownerOf(_sporeId) == _msgSender(), "ChronoCaster: Not spore owner");
        _;
    }

    modifier onlyOracleFeeder() {
        require(hasRole(ORACLE_FEEDER_ROLE, _msgSender()), "ChronoCaster: Not an oracle feeder");
        _;
    }

    modifier onlyCatalystMinter() {
        require(hasRole(CATALYST_MINTER_ROLE, _msgSender()), "ChronoCaster: Not a catalyst minter");
        _;
    }

    modifier onlyCatalystHolder(uint256 _catalystId) {
        require(CATALYST_NFT.ownerOf(_catalystId) == _msgSender(), "ChronoCaster: Not catalyst owner");
        _;
    }

    modifier requireActiveSpore(uint256 _sporeId) {
        require(chronoSpores[_sporeId].isActive, "ChronoCaster: Spore is not active");
        _;
    }

    modifier requirePendingOrActiveSpore(uint256 _sporeId) {
        require(
            chronoSpores[_sporeId].status == ChronoSporeStatus.Pending ||
            chronoSpores[_sporeId].status == ChronoSporeStatus.Active,
            "ChronoCaster: Spore is not pending or active"
        );
        _;
    }

    // --- Constructor ---
    constructor(
        address _chronoSporeNFT,
        address _catalystNFT,
        address _influenceToken,
        address _initialOracleFeeder,
        address _initialFeeRecipient
    ) Ownable(msg.sender) {
        require(_chronoSporeNFT != address(0), "ChronoCaster: Invalid ChronoSporeNFT address");
        require(_catalystNFT != address(0), "ChronoCaster: Invalid CatalystNFT address");
        require(_influenceToken != address(0), "ChronoCaster: Invalid Influence Token address");
        require(_initialOracleFeeder != address(0), "ChronoCaster: Invalid Oracle Feeder address");
        require(_initialFeeRecipient != address(0), "ChronoCaster: Invalid Fee Recipient address");

        CHRONO_SPORE_NFT = IChronoSporeNFT(_chronoSporeNFT);
        CATALYST_NFT = ICatalystNFT(_catalystNFT);
        influenceToken = IERC20(_influenceToken);
        
        feeRecipient = _initialFeeRecipient;
        chronoSporeFeeBasisPoints = 50; // 0.5% default fee

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_FEEDER_ROLE, _initialOracleFeeder);
        _grantRole(CATALYST_MINTER_ROLE, msg.sender); // Admin can also mint catalysts by default
    }

    // --- Core ChronoSpore Management Functions ---

    /**
     * @dev Creates a new ChronoSpore, locking specified assets and defining initial conditions.
     *      A new ChronoSpore NFT is minted to the creator.
     * @param _tokenAddresses Addresses of tokens to lock (ERC20, ERC721, ERC1155).
     * @param _amountsOrTokenIds Amounts for ERC20/1155, tokenId for ERC721.
     * @param _tokenTypes Array indicating if token is ERC20, ERC721, or ERC1155.
     * @param _initialConditions Array of conditions that must be met for release.
     * @param _metadataURI URI for the ChronoSpore NFT metadata.
     */
    function createChronoSpore(
        address[] calldata _tokenAddresses,
        uint256[] calldata _amountsOrTokenIds,
        uint8[] calldata _tokenTypes, // 0=ERC20, 1=ERC721, 2=ERC1155
        Condition[] calldata _initialConditions,
        string calldata _metadataURI
    ) external nonReentrant whenNotPaused returns (uint256 sporeId) {
        require(_tokenAddresses.length > 0, "ChronoCaster: No assets to lock");
        require(_tokenAddresses.length == _amountsOrTokenIds.length && _tokenAddresses.length == _tokenTypes.length, "ChronoCaster: Array length mismatch");
        require(_initialConditions.length > 0, "ChronoCaster: No conditions defined");

        sporeId = _chronoSporeIdCounter.current();
        _chronoSporeIdCounter.increment();

        ChronoSpore storage newSpore = chronoSpores[sporeId];
        newSpore.owner = _msgSender(); // Will be implicitly set by NFT ownership
        newSpore.status = ChronoSporeStatus.Pending; // Status can be active if all conditions are met immediately
        newSpore.createdAt = uint64(block.timestamp);
        newSpore.lastUpdate = uint64(block.timestamp);
        newSpore.isActive = true;

        uint256 totalERC20Value = 0;

        for (uint i = 0; i < _tokenAddresses.length; i++) {
            LockedAsset memory lockedAsset = LockedAsset({
                tokenType: TokenType(_tokenTypes[i]),
                tokenAddress: _tokenAddresses[i],
                amountOrId: _amountsOrTokenIds[i]
            });
            newSpore.lockedAssets.push(lockedAsset);

            if (lockedAsset.tokenType == TokenType.ERC20) {
                IERC20(lockedAsset.tokenAddress).transferFrom(_msgSender(), address(this), lockedAsset.amountOrId);
                newSpore.erc20ValueLocked[lockedAsset.tokenAddress] += lockedAsset.amountOrId;
                totalERC20Value += lockedAsset.amountOrId; // Accumulate for event
            } else if (lockedAsset.tokenType == TokenType.ERC721) {
                IERC721(lockedAsset.tokenAddress).safeTransferFrom(_msgSender(), address(this), lockedAsset.amountOrId);
            } else if (lockedAsset.tokenType == TokenType.ERC1155) {
                IERC1155(lockedAsset.tokenAddress).safeTransferFrom(_msgSender(), address(this), lockedAsset.amountOrId, lockedAsset.amountOrId, ""); // Assuming amount is also the ID for simplicity
            } else {
                revert("ChronoCaster: Unsupported token type");
            }
        }

        for (uint i = 0; i < _initialConditions.length; i++) {
            _initialConditions[i].isMet = false; // Ensure initial conditions are not met
            _initialConditions[i].metAt = 0;
            newSpore.conditions.push(_initialConditions[i]);
        }
        
        // Mint the ChronoSpore NFT to the creator
        CHRONO_SPORE_NFT.mint(_msgSender(), sporeId, _metadataURI);

        emit ChronoSporeCreated(sporeId, _msgSender(), _tokenAddresses.length, _initialConditions.length, _metadataURI);
        
        // Check initial conditions immediately in case they are already met (e.g., time in past)
        _checkAndSetSporeStatus(sporeId);
    }

    /**
     * @dev Adds a new condition to an existing ChronoSpore. Only callable by the ChronoSpore owner.
     *      Spore must not be Fulfilled or Cancelled.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _newCondition The new condition to add.
     */
    function addConditionToChronoSpore(
        uint256 _sporeId,
        Condition calldata _newCondition
    ) external onlyChronoSporeOwner(_sporeId) requirePendingOrActiveSpore(_sporeId) whenNotPaused {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        spore.conditions.push(_newCondition);
        spore.lastUpdate = uint64(block.timestamp);
        spore.isAllConditionsMet = false; // Adding a new condition resets overall met status
        spore.status = ChronoSporeStatus.Active; // Ensure it's active if adding more complexity
        emit ConditionAdded(_sporeId, spore.conditions.length - 1, _newCondition.conditionType);
        _checkAndSetSporeStatus(_sporeId);
    }

    /**
     * @dev (Simulated) Allows an oracle feeder to report new data, which can trigger external conditions.
     *      In a real-world scenario, this would be integrated with Chainlink, Pyth, etc.
     * @param _oracleAddress The address of the oracle feed (for identification).
     * @param _newValue The new data value reported by the oracle.
     */
    function updateOracleData(
        address _oracleAddress,
        uint256 _newValue
    ) external onlyOracleFeeder whenNotPaused {
        lastOracleDataReport[_oracleAddress] = _newValue;
        emit OracleDataUpdated(_oracleAddress, _newValue);

        // Iterate through all active Chronospores to check for triggered conditions
        // NOTE: In a production system, this would need to be optimized (e.g., specific spores subscribing to oracles)
        // For demonstration, we iterate.
        uint256 totalSpores = _chronoSporeIdCounter.current();
        for (uint256 i = 0; i < totalSpores; i++) {
            ChronoSpore storage spore = chronoSpores[i];
            if (spore.status == ChronoSporeStatus.Active || spore.status == ChronoSporeStatus.Pending) {
                for (uint j = 0; j < spore.conditions.length; j++) {
                    Condition storage condition = spore.conditions[j];
                    if (!condition.isMet && condition.conditionType == ConditionType.ExternalDataTrigger && condition.targetAddress == _oracleAddress) {
                        _checkSingleCondition(condition, _newValue);
                    }
                }
                _checkAndSetSporeStatus(i); // Re-check overall status
            }
        }
    }

    /**
     * @dev Checks if all conditions for a specific ChronoSpore are met.
     *      Can be called by anyone. Updates the internal `isAllConditionsMet` flag and spore status.
     * @param _sporeId The ID of the ChronoSpore.
     */
    function checkChronoSporeConditions(uint256 _sporeId) public nonReentrant whenNotPaused {
        _checkAndSetSporeStatus(_sporeId);
    }

    /**
     * @dev Allows the owner of a ChronoSpore NFT to claim the locked assets if all conditions are met.
     *      A fee is taken from ERC20 assets.
     * @param _sporeId The ID of the ChronoSpore.
     */
    function claimChronoSporeAssets(uint256 _sporeId) external nonReentrant onlyChronoSporeOwner(_sporeId) whenNotPaused {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(spore.status == ChronoSporeStatus.Active, "ChronoCaster: Spore not active for claiming");
        require(spore.isAllConditionsMet, "ChronoCaster: All conditions not met yet");
        require(spore.lockedAssets.length > 0, "ChronoCaster: No assets to claim");

        spore.status = ChronoSporeStatus.Fulfilled; // Mark as fulfilled immediately

        uint256 totalFeeCollected = 0;

        // Distribute assets
        for (uint i = 0; i < spore.lockedAssets.length; i++) {
            LockedAsset storage asset = spore.lockedAssets[i];
            address currentSporeOwner = _msgSender(); // Recipient is the current spore NFT owner

            if (asset.tokenType == TokenType.ERC20) {
                uint256 amount = asset.amountOrId;
                uint256 fee = (amount * chronoSporeFeeBasisPoints) / 10000; // Basis points: 10000 = 100%
                uint256 amountToTransfer = amount - fee;

                require(IERC20(asset.tokenAddress).transfer(currentSporeOwner, amountToTransfer), "ERC20 transfer failed");
                if (fee > 0) {
                    require(IERC20(asset.tokenAddress).transfer(feeRecipient, fee), "ERC20 fee transfer failed");
                    totalFeeCollected += fee;
                }
                spore.erc20ValueLocked[asset.tokenAddress] -= amount; // Deduct from locked balance
            } else if (asset.tokenType == TokenType.ERC721) {
                IERC721(asset.tokenAddress).safeTransferFrom(address(this), currentSporeOwner, asset.amountOrId);
            } else if (asset.tokenType == TokenType.ERC1155) {
                IERC1155(asset.tokenAddress).safeTransferFrom(address(this), currentSporeOwner, asset.amountOrId, asset.amountOrId, ""); // Assuming amount is also the ID
            }
        }

        // Burn the ChronoSpore NFT after claiming (optional, but good for "used up" concepts)
        // CHRONO_SPORE_NFT.burn(_sporeId); // Assuming burn function exists

        emit ChronoSporeClaimed(_sporeId, _msgSender(), totalFeeCollected);
    }

    /**
     * @dev Allows another user to contribute ERC20 tokens to an existing ChronoSpore.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _tokenAddress The address of the ERC20 token to contribute.
     * @param _amount The amount of tokens to contribute.
     */
    function contributeToChronoSpore(
        uint256 _sporeId,
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant requireActiveSpore(_sporeId) whenNotPaused {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(spore.status == ChronoSporeStatus.Pending || spore.status == ChronoSporeStatus.Active, "ChronoCaster: Spore not open for contributions");
        require(_amount > 0, "ChronoCaster: Amount must be greater than zero");

        // Transfer tokens from contributor to this contract
        IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);

        // Update the locked assets and internal tracking
        bool found = false;
        for (uint i = 0; i < spore.lockedAssets.length; i++) {
            if (spore.lockedAssets[i].tokenType == TokenType.ERC20 && spore.lockedAssets[i].tokenAddress == _tokenAddress) {
                spore.lockedAssets[i].amountOrId += _amount;
                found = true;
                break;
            }
        }
        if (!found) {
            // Add a new locked asset entry if this token hasn't been locked before in this spore
            spore.lockedAssets.push(LockedAsset({
                tokenType: TokenType.ERC20,
                tokenAddress: _tokenAddress,
                amountOrId: _amount
            }));
        }
        spore.erc20ValueLocked[_tokenAddress] += _amount;

        emit ChronoSporeContributed(_sporeId, _msgSender(), _tokenAddress, _amount);
    }

    // --- Influence & Governance Functions ---

    /**
     * @dev Allows a user to stake influence tokens to gain voting power for condition overrides.
     * @param _amount The amount of influence tokens to stake.
     */
    function stakeInfluenceTokens(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "ChronoCaster: Amount must be greater than zero");
        influenceToken.transferFrom(_msgSender(), address(this), _amount);
        stakedInfluenceTokens[_msgSender()] += _amount;
        emit InfluenceTokensStaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows a user to unstake their influence tokens.
     * @param _amount The amount of influence tokens to unstake.
     */
    function unstakeInfluenceTokens(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "ChronoCaster: Amount must be greater than zero");
        require(stakedInfluenceTokens[_msgSender()] >= _amount, "ChronoCaster: Insufficient staked tokens");
        stakedInfluenceTokens[_msgSender()] -= _amount;
        influenceToken.transfer(_msgSender(), _amount);
        emit InfluenceTokensUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Proposes an override for a specific condition of a ChronoSpore.
     *      Requires staking a minimum amount of influence tokens.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _conditionIndex The index of the condition to override.
     * @param _newMetStatus The proposed new `isMet` status for the condition.
     * @param _reason A string explaining the reason for the proposal.
     */
    function proposeConditionOverride(
        uint256 _sporeId,
        uint256 _conditionIndex,
        bool _newMetStatus,
        string calldata _reason // Reason is off-chain, but its hash could be stored
    ) external nonReentrant whenNotPaused {
        require(stakedInfluenceTokens[_msgSender()] > 0, "ChronoCaster: Must stake influence tokens to propose");
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(_conditionIndex < spore.conditions.length, "ChronoCaster: Invalid condition index");
        require(spore.status == ChronoSporeStatus.Active || spore.status == ChronoSporeStatus.Pending, "ChronoCaster: Spore not open for proposals");
        
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = ConditionOverrideProposal({
            sporeId: _sporeId,
            conditionIndex: _conditionIndex,
            newMetStatus: _newMetStatus,
            createdAt: uint64(block.timestamp),
            votingEndsAt: uint64(block.timestamp + 3 days), // Example: 3 days voting period
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            resolved: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProposalCreated(proposalId, _sporeId, _conditionIndex, _newMetStatus);
    }

    /**
     * @dev Allows staked influence token holders to vote on an active condition override proposal.
     * @param _proposalId The ID of the proposal.
     * @param _vote True for 'For', False for 'Against'.
     */
    function voteOnConditionOverride(uint256 _proposalId, bool _vote) external nonReentrant whenNotPaused {
        ConditionOverrideProposal storage proposal = proposals[_proposalId];
        require(proposal.sporeId != 0, "ChronoCaster: Proposal does not exist");
        require(!proposal.resolved, "ChronoCaster: Proposal already resolved");
        require(block.timestamp < proposal.votingEndsAt, "ChronoCaster: Voting period has ended");
        require(stakedInfluenceTokens[_msgSender()] > 0, "ChronoCaster: Must stake influence tokens to vote");
        require(!proposal.hasVoted[_msgSender()], "ChronoCaster: Already voted on this proposal");

        if (_vote) {
            proposal.totalVotesFor += stakedInfluenceTokens[_msgSender()];
        } else {
            proposal.totalVotesAgainst += stakedInfluenceTokens[_msgSender()];
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Resolves a condition override proposal after its voting period ends.
     *      Applies the proposed status if the 'For' votes exceed 'Against' votes.
     * @param _proposalId The ID of the proposal to resolve.
     */
    function resolveConditionOverride(uint256 _proposalId) external nonReentrant whenNotPaused {
        ConditionOverrideProposal storage proposal = proposals[_proposalId];
        require(proposal.sporeId != 0, "ChronoCaster: Proposal does not exist");
        require(!proposal.resolved, "ChronoCaster: Proposal already resolved");
        require(block.timestamp >= proposal.votingEndsAt, "ChronoCaster: Voting period not yet ended");

        proposal.resolved = true;
        bool passed = proposal.totalVotesFor > proposal.totalVotesAgainst;

        if (passed) {
            ChronoSpore storage spore = chronoSpores[proposal.sporeId];
            Condition storage condition = spore.conditions[proposal.conditionIndex];
            condition.isMet = proposal.newMetStatus;
            condition.metAt = uint64(block.timestamp);
            _checkAndSetSporeStatus(proposal.sporeId); // Re-check overall spore status
        }

        emit ProposalResolved(_proposalId, passed);
    }

    // --- Catalyst NFT Functions ---

    /**
     * @dev Mints a new Catalyst NFT to a specified address. Only callable by CATALYST_MINTER_ROLE.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The URI for the NFT metadata.
     */
    function mintCatalystNFT(address _to, string calldata _tokenURI) external onlyCatalystMinter whenNotPaused returns (uint256 catalystId) {
        catalystId = _catalystIdCounter.current();
        _catalystIdCounter.increment();
        CATALYST_NFT.mint(_to, catalystId, _tokenURI);
        emit CatalystNFTMinted(_to, catalystId);
    }

    /**
     * @dev Allows a Catalyst NFT holder to override a single condition of a ChronoSpore, forcing it to be met.
     *      This could consume the Catalyst NFT or be a limited-use power. (Here, it doesn't consume it).
     * @param _catalystId The ID of the Catalyst NFT being used.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _conditionIndex The index of the condition to override.
     */
    function useCatalystPower_OverrideSingleCondition(
        uint256 _catalystId,
        uint256 _sporeId,
        uint256 _conditionIndex
    ) external nonReentrant onlyCatalystHolder(_catalystId) whenNotPaused {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(_conditionIndex < spore.conditions.length, "ChronoCaster: Invalid condition index");
        require(!spore.conditions[_conditionIndex].isMet, "ChronoCaster: Condition already met");
        require(spore.status == ChronoSporeStatus.Active || spore.status == ChronoSporeStatus.Pending, "ChronoCaster: Spore not open for catalyst power");

        spore.conditions[_conditionIndex].isMet = true;
        spore.conditions[_conditionIndex].metAt = uint64(block.timestamp);
        spore.lastUpdate = uint64(block.timestamp);

        emit CatalystPowerUsed(_msgSender(), _catalystId, _sporeId, _conditionIndex);
        _checkAndSetSporeStatus(_sporeId);
    }

    /**
     * @dev Wrapper for transferring ChronoSpore NFT ownership, allowing the new owner to claim if conditions met.
     * @param _sporeId The ID of the ChronoSpore NFT to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferChronoSporeOwnership(uint256 _sporeId, address _newOwner) external onlyChronoSporeOwner(_sporeId) whenNotPaused {
        CHRONO_SPORE_NFT.safeTransferFrom(_msgSender(), _newOwner, _sporeId);
    }

    // --- Admin & Utility Functions ---

    /**
     * @dev Sets the fee percentage for claimed ERC20 assets. Only callable by owner.
     * @param _newFeeBasisPoints New fee in basis points (e.g., 50 for 0.5%).
     */
    function setChronoSporeFee(uint256 _newFeeBasisPoints) external onlyOwner {
        require(_newFeeBasisPoints <= 1000, "ChronoCaster: Fee cannot exceed 10%"); // Max 10% fee
        uint256 oldFee = chronoSporeFeeBasisPoints;
        chronoSporeFeeBasisPoints = _newFeeBasisPoints;
        emit ChronoSporeFeeUpdated(oldFee, _newFeeBasisPoints);
    }

    /**
     * @dev Sets the address where collected fees are sent. Only callable by owner.
     * @param _newRecipient The new address to receive fees.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "ChronoCaster: Invalid fee recipient address");
        address oldRecipient = feeRecipient;
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    /**
     * @dev Pauses all critical contract functionalities. Only callable by owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract functionalities. Only callable by owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal function to check and update the overall status of a ChronoSpore.
     *      Iterates through all conditions and sets `isAllConditionsMet` accordingly.
     * @param _sporeId The ID of the ChronoSpore.
     */
    function _checkAndSetSporeStatus(uint256 _sporeId) internal {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        if (spore.status == ChronoSporeStatus.Fulfilled || spore.status == ChronoSporeStatus.Cancelled) {
            return; // No need to check fulfilled or cancelled spores
        }

        bool allMet = true;
        for (uint i = 0; i < spore.conditions.length; i++) {
            Condition storage condition = spore.conditions[i];
            if (!condition.isMet) {
                // Check if the condition can now be met
                if (condition.conditionType == ConditionType.TimeBased) {
                    _checkSingleCondition(condition, block.timestamp);
                } else if (condition.conditionType == ConditionType.ExternalDataTrigger) {
                    // Check against last reported oracle data
                    uint256 oracleValue = lastOracleDataReport[condition.targetAddress];
                    if (oracleValue != 0) { // Only check if data exists
                        _checkSingleCondition(condition, oracleValue);
                    }
                } else if (condition.conditionType == ConditionType.InternalStateTrigger) {
                    // Example: condition based on total Chronospores created
                    if (condition.targetAddress == address(this)) { // A special address to indicate internal state check
                        uint256 internalValue;
                        if (condition.value == 1) { // Example: If value param is 1, it means total Chronospores
                            internalValue = _chronoSporeIdCounter.current();
                        } else {
                            // Add more internal state checks here
                            revert("ChronoCaster: Unknown internal state trigger");
                        }
                        _checkSingleCondition(condition, internalValue);
                    }
                }
            }

            if (!condition.isMet) {
                allMet = false; // If any condition is not met, the whole spore is not met
                break;
            }
        }

        if (allMet && !spore.isAllConditionsMet) {
            spore.isAllConditionsMet = true;
            spore.status = ChronoSporeStatus.Active; // Ready to be claimed
            emit ChronoSporeConditionsChecked(_sporeId, true);
        } else if (!allMet && spore.isAllConditionsMet) {
            // This case happens if a condition was overridden or changed, making it unmet again.
            spore.isAllConditionsMet = false;
            spore.status = ChronoSporeStatus.Pending; // Not yet ready
            emit ChronoSporeConditionsChecked(_sporeId, false);
        }
    }

    /**
     * @dev Internal helper to check a single condition against a given value.
     * @param _condition The condition struct to check.
     * @param _currentValue The value to compare against (e.g., current timestamp, oracle data).
     */
    function _checkSingleCondition(Condition storage _condition, uint256 _currentValue) internal {
        if (_condition.isMet) return; // Already met

        bool result = false;
        if (_condition.operator == ComparisonOperator.EQ) {
            result = (_currentValue == _condition.value);
        } else if (_condition.operator == ComparisonOperator.GT) {
            result = (_currentValue > _condition.value);
        } else if (_condition.operator == ComparisonOperator.LT) {
            result = (_currentValue < _condition.value);
        } else if (_condition.operator == ComparisonOperator.GTE) {
            result = (_currentValue >= _condition.value);
        } else if (_condition.operator == ComparisonOperator.LTE) {
            result = (_currentValue <= _condition.value);
        }

        if (result) {
            _condition.isMet = true;
            _condition.metAt = uint64(block.timestamp);
        }
    }

    // --- View Functions ---

    /**
     * @dev Retrieves all details of a specific ChronoSpore.
     * @param _sporeId The ID of the ChronoSpore.
     * @return A tuple containing all ChronoSpore data.
     */
    function getChronoSporeDetails(uint256 _sporeId)
        external
        view
        returns (
            address owner,
            ChronoSporeStatus status,
            LockedAsset[] memory lockedAssets,
            Condition[] memory conditions,
            bool isAllConditionsMet,
            uint64 createdAt,
            uint64 lastUpdate,
            bool isActive
        )
    {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(spore.createdAt > 0, "ChronoCaster: Spore does not exist");

        owner = CHRONO_SPORE_NFT.ownerOf(_sporeId);
        status = spore.status;
        lockedAssets = spore.lockedAssets;
        conditions = spore.conditions;
        isAllConditionsMet = spore.isAllConditionsMet;
        createdAt = spore.createdAt;
        lastUpdate = spore.lastUpdate;
        isActive = spore.isActive;
    }

    /**
     * @dev Retrieves the status of a specific condition within a ChronoSpore.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _conditionIndex The index of the condition.
     * @return isMet True if the condition is met, false otherwise.
     * @return metAt Timestamp when the condition was met (0 if not met).
     */
    function getConditionStatus(uint256 _sporeId, uint256 _conditionIndex)
        external
        view
        returns (bool isMet, uint64 metAt)
    {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(spore.createdAt > 0, "ChronoCaster: Spore does not exist");
        require(_conditionIndex < spore.conditions.length, "ChronoCaster: Invalid condition index");

        Condition storage condition = spore.conditions[_conditionIndex];
        return (condition.isMet, condition.metAt);
    }

    /**
     * @dev Returns the total amount of a specific ERC20 token currently locked within a ChronoSpore.
     * @param _sporeId The ID of the ChronoSpore.
     * @param _tokenAddress The address of the ERC20 token.
     * @return The total locked amount.
     */
    function getTotalValueLocked(uint256 _sporeId, address _tokenAddress) external view returns (uint256) {
        ChronoSpore storage spore = chronoSpores[_sporeId];
        require(spore.createdAt > 0, "ChronoCaster: Spore does not exist");
        return spore.erc20ValueLocked[_tokenAddress];
    }

    // --- ERC721 & ERC1155 Holder Overrides ---
    // These functions are required by ERC721Holder and ERC1155Holder to acknowledge safe transfers.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
```