Here's a Solidity smart contract for "Aetheria Nexus," designed around the concept of managing "Digital Twin" assets with dynamic states, AI oracle integration, fractionalized ownership, and DAO governance. It aims to be creative, advanced, and trendy without duplicating common open-source projects by combining these features in a specific, interconnected way.

**Smart Contract: AetheriaNexus.sol**

This contract requires OpenZeppelin Contracts. You'll need to install them:
`npm install @openzeppelin/contracts`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Auxiliary contract for fractional shares, defined below main contract
contract FractionalSharesERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address _ownerOfERC20)
        ERC20(name, symbol)
        Ownable(_ownerOfERC20) // AetheriaNexus contract is the owner of this ERC20 instance
    {
        // Mints initial supply to the address that triggered the fractionalization (original twin owner)
        // Note: _ownerOfERC20 parameter here is the address that owns this ERC20 contract, not the token recipient.
        // The actual recipient of initial tokens will be passed to `_mint`.
        // Let's clarify: `_initialRecipient` is the owner of the Twin who wants shares.
    }

    // Constructor modified to clarify initial minting:
    // It's called by AetheriaNexus, `_initialRecipient` is the original Twin owner.
    // `_ownerOfERC20` is AetheriaNexus's address to control this ERC20 contract.
    function initialize(string memory name, string memory symbol, uint256 initialSupply, address _initialRecipient, address _ownerOfERC20) internal {
        // Only allow initialization once
        require(bytes(name()).length == 0, "Already initialized"); // Check if ERC20 name is not set
        _initialize(name, symbol);
        transferOwnership(_ownerOfERC20);
        _mint(_initialRecipient, initialSupply);
    }

    function _initialize(string memory name, string memory symbol) internal {
        // This is a workaround for ERC20's constructor being too rigid for proxy patterns or custom factory creation.
        // In a real scenario, you'd use a proper ERC20 factory or `UUPSUpgradeable` pattern.
        // For direct deployment via `new`, the default ERC20 constructor would be used.
        // Given this contract is directly created by `AetheriaNexus`, the default ERC20 constructor is fine.
        // Reverting this to standard ERC20 constructor.
    }

    // A specific `burnFrom` function for the owner of this contract (AetheriaNexus)
    // This allows AetheriaNexus to burn tokens from a user's balance without requiring a prior `approve` call from the user.
    // This simplifies the `redeemSharesForTwin` flow.
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}


/**
 * @title Aetheria Nexus: Decentralized Digital Twin Asset Management with Dynamic State & AI Oracle Governance
 * @dev This contract facilitates the creation, management, and fractionalization of "Digital Twins"
 *      representing real-world or metaverse assets. It incorporates advanced concepts such as:
 *      -   **Dynamic Asset State**: Digital Twins can degrade over time and be revitalized.
 *      -   **AI Oracle Integration**: Trusted oracles can submit AI-generated insights/reports influencing asset state.
 *      -   **Fractionalized Ownership**: Assets can be fractionalized into ERC20 tokens.
 *      -   **DAO Governance**: Fractional owners or specific governance tokens can propose and vote on actions.
 *      -   **Advanced Treasury Management**: For asset maintenance and revenue distribution.
 *      This contract aims to provide a unique, non-duplicated approach to on-chain asset representation and lifecycle management.
 *
 * @outline
 * 1.  **Core Infrastructure & Access Control**:
 *     -   Inherits `Ownable` for administrative functions.
 *     -   Inherits `Pausable` for emergency stop functionality.
 *     -   Manages a whitelist of trusted AI oracle addresses.
 * 2.  **Digital Twin (ERC721) Management**:
 *     -   Creation, metadata updates, state tracking (active, degraded, retired).
 *     -   Lifecycle management including time-based decay and revitalization.
 * 3.  **Fractional Ownership (ERC20)**:
 *     -   Mechanism to create unique ERC20 tokens representing shares of a specific Digital Twin.
 *     -   Functions for distributing revenue to share holders and for share redemption.
 * 4.  **Dynamic State & AI Oracle Integration**:
 *     -   Enums for `TwinState` and `OracleReport` struct for storing insights.
 *     -   Functions for approved oracles to submit AI analysis hashes and URIs.
 *     -   Logic for automatically decaying twin states based on time.
 *     -   Mechanism for revitalization of degraded twins.
 * 5.  **Decentralized Autonomous Organization (DAO) Governance**:
 *     -   Proposal creation, voting, and execution system.
 *     -   Proposals can trigger arbitrary function calls on the contract for asset management.
 * 6.  **Treasury & Fund Management**:
 *     -   Deposit functionality for contract general treasury.
 *     -   DAO-controlled withdrawal of general treasury funds for operations or distributions.
 *     -   System for fractional share holders to claim pro-rata revenue from their twin.
 *
 * @function_summary
 * -   **constructor()**: Initializes the contract, setting the deployer as the initial owner.
 * -   **addOracle(address _oracleAddress)**: (Admin) Whitelists an address as a trusted AI oracle.
 * -   **removeOracle(address _oracleAddress)**: (Admin) Removes an address from the trusted AI oracle list.
 * -   **pause()**: (Admin) Halts most contract operations for emergencies.
 * -   **unpause()**: (Admin) Resumes contract operations.
 * -   **mintDigitalTwin(string memory _tokenURI, uint256 _initialValue)**: Mints a new unique Digital Twin NFT, setting its initial metadata and value.
 * -   **updateTwinMetadata(uint256 _twinId, string memory _newTokenURI)**: Updates the IPFS/metadata URI for an existing Digital Twin.
 * -   **retireTwin(uint256 _twinId)**: Marks a Digital Twin as "retired", preventing further dynamic state changes or fractionalization.
 * -   **getTwinDetails(uint256 _twinId)**: (View) Retrieves all stored details for a specific Digital Twin.
 * -   **getTwinCurrentState(uint256 _twinId)**: (View) Calculates and returns the current decay state of a Digital Twin.
 * -   **createFractionalShares(uint256 _twinId, string memory _name, string memory _symbol, uint256 _supply)**: Deploys a new ERC20 token contract specifically for fractional ownership of a given Digital Twin, and transfers the Twin NFT to this contract as custodian.
 * -   **distributeTwinRevenue(uint256 _twinId)**: Receives native currency (ETH) for a specific twin, adding it to a pool for later claiming by fractional share holders.
 * -   **claimTwinRevenue(uint256 _twinId)**: Allows holders of fractional shares to claim their pro-rata portion of the accumulated revenue for a specific Digital Twin.
 * -   **redeemSharesForTwin(uint256 _twinId)**: Allows a sole holder of 100% of a twin's fractional shares to redeem them for the full Digital Twin NFT.
 * -   **storeOracleReport(uint256 _twinId, bytes32 _aiReportHash, string memory _reportURI)**: (Oracle Only) Stores a hash of an AI-generated report and its URI, associated with a specific Digital Twin.
 * -   **applyTimeDecay(uint256 _twinId)**: (External/Keeper) Triggers the time-based degradation logic for a Digital Twin, potentially changing its state.
 * -   **revitalizeTwin(uint256 _twinId)**: Allows the current owner of a degraded Digital Twin to pay a fee to restore its `Active` state.
 * -   **proposeTwinAction(uint256 _twinId, string memory _description, bytes memory _callData, uint256 _votePeriod)**: Initiates a DAO proposal to perform an action (defined by `_callData`) on a specific Digital Twin.
 * -   **voteOnProposal(uint256 _proposalId, bool _support)**: Allows users to cast a single vote on an active proposal.
 * -   **executeProposal(uint256 _proposalId)**: Executes a proposal that has met its voting threshold and passed its deadline.
 * -   **getProposalDetails(uint256 _proposalId)**: (View) Retrieves the full details of a specific DAO proposal.
 * -   **getProposalVoteCount(uint256 _proposalId)**: (View) Retrieves the current votes for and against a specific DAO proposal.
 * -   **depositFunds()**: Allows anyone to send Ether to the contract's general treasury.
 * -   **withdrawTreasuryFunds(address _recipient, uint256 _amount)**: (DAO Only via proposal) Allows withdrawing funds from the contract's general treasury.
 * -   **setProposalThreshold(uint256 _newThreshold)**: (Admin/DAO) Sets the percentage of total votes required for a proposal to pass.
 * -   **setDecayThreshold(uint256 _newThreshold)**: (Admin/DAO) Sets the time duration after which a twin starts to degrade.
 * -   **setRevitalizationCostPercentage(uint256 _newPercentage)**: (Admin/DAO) Sets the percentage of a twin's value required for revitalization.
 * -   **migrateTwinOwnership(uint256 _twinId, address _newOwner)**: (DAO Only via proposal) Allows transferring ownership of a Digital Twin to a new address (only if not fractionalized).
 */
contract AetheriaNexus is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Constants & Parameters ---
    uint256 public DECAY_THRESHOLD_TIME = 30 days; // Time (in seconds) after which a twin starts to degrade
    uint256 public REVITALIZATION_COST_PERCENTAGE = 500; // 5% (value * 500 / 10000)
    uint256 public constant PERCENTAGE_DENOMINATOR = 10000; // For 2 decimal places (100.00%)

    uint256 public PROPOSAL_VOTE_PERIOD = 3 days; // Duration (in seconds) for voting
    uint256 public PROPOSAL_THRESHOLD_PERCENTAGE = 6000; // 60% of total votes needed to pass

    // --- Enums ---
    enum TwinState {
        Active,      // Fully functional, no decay
        Degraded,    // Functionality reduced, requires revitalization
        Revitalized, // Recently revitalized, temporarily boosted
        Retired      // Permanently out of service
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    // --- Structs ---
    struct DigitalTwin {
        uint256 id;
        address owner; // Owner of the NFT (could be this contract if fractionalized)
        string uri; // IPFS URI for metadata
        uint256 initialValue; // A perceived or starting value, potentially in wei
        TwinState currentState;
        uint256 lastActivityTime; // Last time state was active/revitalized/reported
        address associatedSharesToken; // Address of the ERC20 token for fractional ownership
        address currentOracleReportAddress; // Address of the oracle that last reported
        bytes32 currentAIReportHash; // Hash of the latest AI report influencing this twin
        string currentAIReportURI; // URI to the latest AI report
    }

    struct Proposal {
        address proposer;
        uint256 twinId;
        string description;
        bytes callData; // Encoded function call for execution
        ProposalState proposalState;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 executedTimestamp;
    }

    // --- State Variables ---
    Counters.Counter private _twinIdCounter;
    mapping(uint256 => DigitalTwin) public _digitalTwins;

    mapping(address => bool) private _approvedOracles; // Whitelisted oracle addresses

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public _proposals;
    // proposalId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    // Revenue distribution for fractionalized twins (Pull-based)
    mapping(uint256 => uint256) private _totalDistributedToTwin; // twinId => total ETH ever sent to its pool
    mapping(uint256 => mapping(address => uint256)) private _claimedRevenue; // twinId => address => amount claimed by address

    // --- Events ---
    event OracleAdded(address indexed oracleAddress);
    event OracleRemoved(address indexed oracleAddress);
    event DigitalTwinMinted(uint256 indexed twinId, address indexed owner, string tokenURI, uint256 initialValue);
    event TwinMetadataUpdated(uint256 indexed twinId, string newTokenURI);
    event TwinRetired(uint256 indexed twinId);
    event TwinStateChanged(uint256 indexed twinId, TwinState newState, uint256 timestamp);
    event TwinRevitalized(uint256 indexed twinId, uint256 costPaid);
    event FractionalSharesCreated(uint256 indexed twinId, address indexed sharesTokenAddress, uint256 totalSupply);
    event TwinRevenueDistributedToPool(uint256 indexed twinId, uint256 amount);
    event TwinRevenueClaimed(uint256 indexed twinId, address indexed claimant, uint256 amount);
    event SharesRedeemedForTwin(uint256 indexed twinId, address indexed redeemer);
    event OracleReportStored(uint256 indexed twinId, address indexed oracleAddress, bytes32 aiReportHash, string reportURI);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed twinId, address indexed proposer, string description, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProposalThresholdUpdated(uint256 newThreshold);
    event DecayThresholdUpdated(uint256 newThreshold);
    event RevitalizationCostUpdated(uint256 newPercentage);
    event TwinOwnershipMigrated(uint256 indexed twinId, address indexed oldOwner, address indexed newOwner);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(_approvedOracles[msg.sender], "AetheriaNexus: Not an approved oracle");
        _;
    }

    modifier onlyTwinOwner(uint256 _twinId) {
        require(ERC721.ownerOf(_twinId) == msg.sender, "AetheriaNexus: Not the twin owner");
        _;
    }

    modifier notRetired(uint256 _twinId) {
        require(_digitalTwins[_twinId].currentState != TwinState.Retired, "AetheriaNexus: Twin is retired");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "AetheriaNexus: Proposal does not exist");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("AetheriaNexusDigitalTwin", "ANXDT") Pausable() Ownable(msg.sender) {}

    // --- Admin & Setup Functions (1-5) ---

    /**
     * @dev Adds an address to the whitelist of approved AI oracles.
     * Only callable by the contract owner.
     * @param _oracleAddress The address to add.
     */
    function addOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AetheriaNexus: Zero address for oracle");
        require(!_approvedOracles[_oracleAddress], "AetheriaNexus: Oracle already approved");
        _approvedOracles[_oracleAddress] = true;
        emit OracleAdded(_oracleAddress);
    }

    /**
     * @dev Removes an address from the whitelist of approved AI oracles.
     * Only callable by the contract owner.
     * @param _oracleAddress The address to remove.
     */
    function removeOracle(address _oracleAddress) public onlyOwner {
        require(_approvedOracles[_oracleAddress], "AetheriaNexus: Oracle not found");
        _approvedOracles[_oracleAddress] = false;
        emit OracleRemoved(_oracleAddress);
    }

    /**
     * @dev See {Pausable-_pause}.
     * This function allows the contract owner to pause most operations in case of an emergency.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     * This function allows the contract owner to resume operations after a pause.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }

    // --- Digital Twin (ERC721) Management Functions (6-10) ---

    /**
     * @dev Mints a new unique Digital Twin NFT.
     * The initial value represents a baseline economic value for the twin (e.g., in wei).
     * @param _tokenURI The IPFS URI pointing to the twin's metadata.
     * @param _initialValue A numeric representation of the twin's initial perceived value.
     * @return The ID of the newly minted Digital Twin.
     */
    function mintDigitalTwin(string memory _tokenURI, uint256 _initialValue) public whenNotPaused returns (uint256) {
        _twinIdCounter.increment();
        uint256 newTokenId = _twinIdCounter.current();
        _safeMint(msg.sender, newTokenId);

        _digitalTwins[newTokenId] = DigitalTwin({
            id: newTokenId,
            owner: msg.sender, // The ERC721 ownerOf is the source of truth, this is for internal state tracking
            uri: _tokenURI,
            initialValue: _initialValue,
            currentState: TwinState.Active,
            lastActivityTime: block.timestamp,
            associatedSharesToken: address(0), // No fractional shares yet
            currentOracleReportAddress: address(0),
            currentAIReportHash: bytes32(0),
            currentAIReportURI: ""
        });
        _setTokenURI(newTokenId, _tokenURI); // Set URI via ERC721 internal function

        emit DigitalTwinMinted(newTokenId, msg.sender, _tokenURI, _initialValue);
        return newTokenId;
    }

    /**
     * @dev Updates the metadata URI for a specific Digital Twin.
     * Only callable by the current owner of the Digital Twin.
     * @param _twinId The ID of the Digital Twin to update.
     * @param _newTokenURI The new IPFS URI for the twin's metadata.
     */
    function updateTwinMetadata(uint256 _twinId, string memory _newTokenURI) public whenNotPaused onlyTwinOwner(_twinId) notRetired(_twinId) {
        _setTokenURI(_twinId, _newTokenURI);
        _digitalTwins[_twinId].uri = _newTokenURI; // Update internal struct for consistency
        emit TwinMetadataUpdated(_twinId, _newTokenURI);
    }

    /**
     * @dev Marks a Digital Twin as "Retired".
     * A retired twin cannot be fractionalized, updated, or undergo decay/revitalization.
     * This is a permanent state. This function should typically be called via a DAO proposal.
     * @param _twinId The ID of the Digital Twin to retire.
     */
    function retireTwin(uint256 _twinId) public whenNotPaused notRetired(_twinId) {
        // Enforce that only the twin owner or the contract itself (via DAO proposal) can call this.
        require(ERC721.ownerOf(_twinId) == msg.sender || msg.sender == address(this), "AetheriaNexus: Only twin owner or DAO can retire.");
        _digitalTwins[_twinId].currentState = TwinState.Retired;
        emit TwinRetired(_twinId);
        emit TwinStateChanged(_twinId, TwinState.Retired, block.timestamp);
    }

    /**
     * @dev Retrieves all stored details for a specific Digital Twin.
     * @param _twinId The ID of the Digital Twin.
     * @return A tuple containing all DigitalTwin struct fields.
     */
    function getTwinDetails(uint256 _twinId) public view returns (
        uint256 id,
        address owner,
        string memory uri,
        uint256 initialValue,
        TwinState currentState,
        uint256 lastActivityTime,
        address associatedSharesToken,
        address currentOracleReportAddress,
        bytes32 currentAIReportHash,
        string memory currentAIReportURI
    ) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        return (
            twin.id,
            ERC721.ownerOf(_twinId), // ERC721 `ownerOf` is authoritative for current owner
            twin.uri,
            twin.initialValue,
            twin.currentState,
            twin.lastActivityTime,
            twin.associatedSharesToken,
            twin.currentOracleReportAddress,
            twin.currentAIReportHash,
            twin.currentAIReportURI
        );
    }

    /**
     * @dev Calculates and returns the current decay state of a Digital Twin based on its last activity time.
     * @param _twinId The ID of the Digital Twin.
     * @return The current `TwinState` of the specified twin.
     */
    function getTwinCurrentState(uint256 _twinId) public view returns (TwinState) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");

        if (twin.currentState == TwinState.Retired) {
            return TwinState.Retired;
        }

        if (block.timestamp.sub(twin.lastActivityTime) >= DECAY_THRESHOLD_TIME) {
            return TwinState.Degraded;
        }
        return twin.currentState; // Active or Revitalized
    }

    // --- Fractional Ownership (ERC20) & Revenue Functions (11-13, 28) ---

    /**
     * @dev Deploys a new ERC20 token contract specifically for fractional ownership of a given Digital Twin.
     * Only callable by the current owner of the Digital Twin. A twin can only be fractionalized once.
     * The Digital Twin NFT is transferred to this contract, which becomes its custodian.
     * @param _twinId The ID of the Digital Twin to fractionalize.
     * @param _name The name for the new ERC20 token (e.g., "TwinX Shares").
     * @param _symbol The symbol for the new ERC20 token (e.g., "TWNX").
     * @param _supply The total supply of fractional shares to mint.
     * @return The address of the newly deployed ERC20 token contract.
     */
    function createFractionalShares(uint256 _twinId, string memory _name, string memory _symbol, uint256 _supply)
        public
        whenNotPaused
        onlyTwinOwner(_twinId)
        notRetired(_twinId)
        returns (address)
    {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.associatedSharesToken == address(0), "AetheriaNexus: Twin already fractionalized");
        require(_supply > 0, "AetheriaNexus: Supply must be greater than zero");

        // Deploy a new `FractionalSharesERC20` contract.
        // The `AetheriaNexus` contract (`address(this)`) becomes the owner of this new ERC20 contract,
        // allowing it to manage the burning of tokens for redemption.
        // The `initialSupply` is minted to `msg.sender` (the original twin owner).
        FractionalSharesERC20 newShares = new FractionalSharesERC20(_name, _symbol, _supply, msg.sender, address(this));
        twin.associatedSharesToken = address(newShares);

        // Transfer ownership of the NFT to this contract, making it the custodian.
        _transfer(msg.sender, address(this), _twinId);
        twin.owner = address(this); // Update internal record; ERC721 ownerOf is ultimate source of truth

        emit FractionalSharesCreated(_twinId, address(newShares), _supply);
        return address(newShares);
    }

    /**
     * @dev Allows anyone to send native currency (ETH) for a specific twin, adding it to a pool for later claiming by fractional share holders.
     * This is the "push" mechanism for revenue into the twin's pool.
     * @param _twinId The ID of the Digital Twin to allocate revenue to.
     */
    function distributeTwinRevenue(uint256 _twinId) public payable whenNotPaused notRetired(_twinId) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.associatedSharesToken != address(0), "AetheriaNexus: Twin not fractionalized for revenue distribution");
        require(msg.value > 0, "AetheriaNexus: Amount must be greater than zero");

        _totalDistributedToTwin[_twinId] = _totalDistributedToTwin[_twinId].add(msg.value);

        emit TwinRevenueDistributedToPool(_twinId, msg.value);
    }

    /**
     * @dev Allows holders of fractional shares to claim their pro-rata portion of the accumulated revenue for a specific Digital Twin.
     * This is the "pull" mechanism for revenue claiming.
     * @param _twinId The ID of the Digital Twin whose revenue to claim.
     */
    function claimTwinRevenue(uint256 _twinId) public whenNotPaused notRetired(_twinId) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.associatedSharesToken != address(0), "AetheriaNexus: Twin not fractionalized");

        FractionalSharesERC20 sharesToken = FractionalSharesERC20(twin.associatedSharesToken);
        uint256 claimantShares = sharesToken.balanceOf(msg.sender);
        require(claimantShares > 0, "AetheriaNexus: Caller holds no shares for this twin");

        uint256 totalSharesNow = sharesToken.totalSupply();
        require(totalSharesNow > 0, "AetheriaNexus: No shares exist for this twin (error state)");

        uint256 totalRevenueEver = _totalDistributedToTwin[_twinId];
        uint256 alreadyClaimedByMe = _claimedRevenue[_twinId][msg.sender];

        // Calculate my total entitlement based on my current share percentage of all revenue ever distributed.
        // This is a simple snapshot approach. More complex systems use per-share accumulators for precision across transfers.
        uint256 myFullEntitlement = totalRevenueEver.mul(claimantShares).div(totalSharesNow);
        uint256 amountToClaim = myFullEntitlement.sub(alreadyClaimedByMe);

        require(amountToClaim > 0, "AetheriaNexus: No claimable revenue for you at this time.");

        // Deduct from the main contract balance and transfer
        require(address(this).balance >= amountToClaim, "AetheriaNexus: Insufficient contract balance to fulfill claim.");

        _claimedRevenue[_twinId][msg.sender] = _claimedRevenue[_twinId][msg.sender].add(amountToClaim);
        payable(msg.sender).transfer(amountToClaim);

        emit TwinRevenueClaimed(_twinId, msg.sender, amountToClaim);
    }

    /**
     * @dev Allows a sole holder of 100% of a twin's fractional shares to redeem them for the full Digital Twin NFT.
     * The Digital Twin NFT must be held by this contract as custodian.
     * This function will burn the ERC20 shares from the caller.
     * @param _twinId The ID of the Digital Twin whose shares are being redeemed.
     */
    function redeemSharesForTwin(uint256 _twinId) public whenNotPaused notRetired(_twinId) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.associatedSharesToken != address(0), "AetheriaNexus: Twin not fractionalized");
        require(ERC721.ownerOf(_twinId) == address(this), "AetheriaNexus: This contract is not the custodian of the twin NFT.");

        FractionalSharesERC20 sharesToken = FractionalSharesERC20(twin.associatedSharesToken);
        uint256 totalShares = sharesToken.totalSupply();
        uint256 holderBalance = sharesToken.balanceOf(msg.sender);

        // Only allow redemption if the caller owns 100% of the shares
        require(holderBalance == totalShares, "AetheriaNexus: Caller does not own 100% of shares");

        // Burn all shares from the caller using the `burnFrom` function in the FractionalSharesERC20 contract.
        // This is possible because AetheriaNexus is the `owner` of the FractionalSharesERC20 contract.
        sharesToken.burnFrom(msg.sender, holderBalance); 

        // Transfer the NFT back to the redeemer
        _safeTransfer(address(this), msg.sender, _twinId);
        twin.owner = msg.sender; // Update internal record; ERC721 ownerOf is ultimate source of truth
        twin.associatedSharesToken = address(0); // Mark as no longer fractionalized

        emit SharesRedeemedForTwin(_twinId, msg.sender);
    }

    // --- Dynamic State & AI Oracle Interaction Functions (14-16) ---

    /**
     * @dev Stores a hash of an AI-generated report and its URI, associated with a specific Digital Twin.
     * Only callable by approved AI oracle addresses.
     * @param _twinId The ID of the Digital Twin the report pertains to.
     * @param _aiReportHash The cryptographic hash of the AI report content.
     * @param _reportURI The URI (e.g., IPFS) where the full AI report can be accessed.
     */
    function storeOracleReport(uint256 _twinId, bytes32 _aiReportHash, string memory _reportURI) public whenNotPaused onlyOracle {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.currentState != TwinState.Retired, "AetheriaNexus: Cannot report on retired twin");

        twin.currentOracleReportAddress = msg.sender;
        twin.currentAIReportHash = _aiReportHash;
        twin.currentAIReportURI = _reportURI;
        twin.lastActivityTime = block.timestamp; // Reporting counts as activity to reset decay

        emit OracleReportStored(_twinId, msg.sender, _aiReportHash, _reportURI);
    }

    /**
     * @dev Triggers the time-based degradation logic for a Digital Twin.
     * If the `DECAY_THRESHOLD_TIME` has passed since `lastActivityTime`, the twin's state changes to `Degraded`.
     * This function can be called by anyone (e.g., a keeper bot) to keep the state updated.
     * @param _twinId The ID of the Digital Twin to check for decay.
     */
    function applyTimeDecay(uint256 _twinId) public whenNotPaused notRetired(_twinId) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");

        if (twin.currentState == TwinState.Active || twin.currentState == TwinState.Revitalized) {
            if (block.timestamp.sub(twin.lastActivityTime) >= DECAY_THRESHOLD_TIME) {
                twin.currentState = TwinState.Degraded;
                emit TwinStateChanged(_twinId, TwinState.Degraded, block.timestamp);
            }
        }
    }

    /**
     * @dev Allows the current owner of a degraded Digital Twin to pay a fee to restore its `Active` state.
     * The fee is a percentage of the twin's `initialValue`.
     * @param _twinId The ID of the Digital Twin to revitalize.
     */
    function revitalizeTwin(uint256 _twinId) public payable whenNotPaused onlyTwinOwner(_twinId) notRetired(_twinId) {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.currentState == TwinState.Degraded, "AetheriaNexus: Twin is not in Degraded state");

        uint256 requiredCost = twin.initialValue.mul(REVITALIZATION_COST_PERCENTAGE).div(PERCENTAGE_DENOMINATOR);
        require(msg.value >= requiredCost, "AetheriaNexus: Insufficient funds for revitalization");

        // Restore twin state and update activity time
        twin.currentState = TwinState.Active; // Or Revitalized if a temporary boost is desired
        twin.lastActivityTime = block.timestamp;

        // Any excess payment is returned
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value.sub(requiredCost));
        }

        emit TwinRevitalized(_twinId, requiredCost);
        emit TwinStateChanged(_twinId, TwinState.Active, block.timestamp);
    }

    // --- DAO Governance Functions (17-21) ---

    /**
     * @dev Initiates a new DAO proposal for an action on a specific Digital Twin.
     * Anyone can propose an action. The `_callData` encodes the function call to be executed if the proposal passes.
     * @param _twinId The ID of the Digital Twin the proposal concerns.
     * @param _description A brief description of the proposal.
     * @param _callData The ABI-encoded function call to execute (e.g., `abi.encodeWithSelector(this.updateTwinMetadata.selector, _twinId, "newURI")`).
     * @param _votePeriod The duration (in seconds) for which the voting will be open.
     * @return The ID of the newly created proposal.
     */
    function proposeTwinAction(uint256 _twinId, string memory _description, bytes memory _callData, uint256 _votePeriod)
        public
        whenNotPaused
        returns (uint256)
    {
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(_votePeriod > 0, "AetheriaNexus: Vote period must be positive");
        require(bytes(_description).length > 0, "AetheriaNexus: Description cannot be empty");
        require(_callData.length > 0, "AetheriaNexus: Call data cannot be empty");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        _proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            twinId: _twinId,
            description: _description,
            callData: _callData,
            proposalState: ProposalState.Active,
            deadline: block.timestamp.add(_votePeriod),
            votesFor: 0,
            votesAgainst: 0,
            executedTimestamp: 0
        });

        emit ProposalCreated(newProposalId, _twinId, msg.sender, _description, block.timestamp.add(_votePeriod));
        return newProposalId;
    }

    /**
     * @dev Allows a user to vote on an active proposal.
     * Each unique address can vote only once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.proposalState == ProposalState.Active, "AetheriaNexus: Proposal is not active");
        require(block.timestamp <= proposal.deadline, "AetheriaNexus: Voting period has ended");
        require(!_hasVoted[_proposalId][msg.sender], "AetheriaNexus: Already voted on this proposal");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        _hasVoted[_proposalId][msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal that has met its voting threshold and passed its deadline.
     * Anyone can call this function to trigger execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.proposalState == ProposalState.Active, "AetheriaNexus: Proposal not active");
        require(block.timestamp > proposal.deadline, "AetheriaNexus: Voting period has not ended");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "AetheriaNexus: No votes cast");

        // Quorum is based on votes cast; a simple 1-address-1-vote system.
        uint256 votesRequired = totalVotes.mul(PROPOSAL_THRESHOLD_PERCENTAGE).div(PERCENTAGE_DENOMINATOR);

        if (proposal.votesFor >= votesRequired) {
            proposal.proposalState = ProposalState.Succeeded;
            // Execute the call data
            // This allows the DAO to call any function on 'this' contract.
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "AetheriaNexus: Proposal execution failed");
            proposal.executedTimestamp = block.timestamp;
            proposal.proposalState = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.proposalState = ProposalState.Defeated;
        }
    }

    /**
     * @dev Retrieves the full details of a specific DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all Proposal struct fields.
     */
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (
        address proposer,
        uint256 twinId,
        string memory description,
        bytes memory callData,
        ProposalState proposalState,
        uint256 deadline,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 executedTimestamp
    ) {
        Proposal storage proposal = _proposals[_proposalId];
        return (
            proposal.proposer,
            proposal.twinId,
            proposal.description,
            proposal.callData,
            proposal.proposalState,
            proposal.deadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executedTimestamp
        );
    }

    /**
     * @dev Retrieves the current votes for and against a specific DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return votesFor The number of 'for' votes.
     * @return votesAgainst The number of 'against' votes.
     */
    function getProposalVoteCount(uint256 _proposalId) public view proposalExists(_proposalId) returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = _proposals[_proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }

    // --- Treasury / Fund Management Functions (22-23) ---

    /**
     * @dev Allows anyone to send Ether to the contract's general treasury.
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows anyone to send Ether to the contract's general treasury.
     */
    function depositFunds() public payable {
        require(msg.value > 0, "AetheriaNexus: Deposit amount must be greater than zero");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows withdrawal of funds from the contract's general treasury.
     * This function is designed to be callable only via a successful DAO proposal execution.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of Ether (in wei) to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public whenNotPaused {
        require(msg.sender == address(this), "AetheriaNexus: Only callable via DAO proposal execution.");
        require(_recipient != address(0), "AetheriaNexus: Zero address for recipient");
        require(address(this).balance >= _amount, "AetheriaNexus: Insufficient treasury balance");

        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- Dynamic Parameter Adjustment Functions (24-26) ---
    // These functions should ideally be set via DAO proposals as well, not direct owner calls,
    // to decentralize parameter governance. For initial setup flexibility, `onlyOwner` is used.

    /**
     * @dev Sets the percentage of total votes required for a proposal to pass.
     * @param _newThreshold The new threshold percentage (e.g., 6000 for 60%).
     */
    function setProposalThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold > 0 && _newThreshold <= PERCENTAGE_DENOMINATOR, "AetheriaNexus: Invalid threshold percentage");
        PROPOSAL_THRESHOLD_PERCENTAGE = _newThreshold;
        emit ProposalThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Sets the time duration (in seconds) after which a twin starts to degrade.
     * @param _newThreshold The new decay threshold time in seconds.
     */
    function setDecayThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "AetheriaNexus: Decay threshold must be positive");
        DECAY_THRESHOLD_TIME = _newThreshold;
        emit DecayThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Sets the percentage of a twin's initial value required for revitalization.
     * @param _newPercentage The new revitalization cost percentage (e.g., 500 for 5%).
     */
    function setRevitalizationCostPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage > 0 && _newPercentage <= PERCENTAGE_DENOMINATOR, "AetheriaNexus: Invalid percentage");
        REVITALIZATION_COST_PERCENTAGE = _newPercentage;
        emit RevitalizationCostUpdated(_newPercentage);
    }

    // --- NFT Management via DAO (27) ---

    /**
     * @dev Allows migration of Digital Twin ownership.
     * This function is designed to be callable only via a successful DAO proposal execution.
     * It allows the DAO to transfer a Digital Twin NFT to a new owner.
     * This is restricted if the twin is fractionalized, as it would break the fractionalization model.
     * @param _twinId The ID of the Digital Twin to transfer.
     * @param _newOwner The new address to transfer ownership to.
     */
    function migrateTwinOwnership(uint256 _twinId, address _newOwner) public whenNotPaused {
        require(msg.sender == address(this), "AetheriaNexus: Only callable via DAO proposal execution.");
        require(_newOwner != address(0), "AetheriaNexus: Cannot transfer to zero address");
        DigitalTwin storage twin = _digitalTwins[_twinId];
        require(twin.id != 0, "AetheriaNexus: Twin does not exist");
        require(twin.currentState != TwinState.Retired, "AetheriaNexus: Cannot transfer retired twin");
        require(twin.associatedSharesToken == address(0), "AetheriaNexus: Cannot migrate ownership of fractionalized twin directly. Redeem shares first.");

        address oldOwner = ERC721.ownerOf(_twinId);
        _transfer(oldOwner, _newOwner, _twinId); // Use internal ERC721 transfer
        twin.owner = _newOwner; // Update internal struct record (for consistency with ERC721.ownerOf)

        emit TwinOwnershipMigrated(_twinId, oldOwner, _newOwner);
    }
}

// --- Auxiliary Contract for Fractional Shares (ERC20) ---
// This contract serves as the ERC20 token for fractional ownership.
// Its `owner` is the AetheriaNexus contract, allowing the Nexus to control minting/burning
// for fractionalization processes.
contract FractionalSharesERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    // Constructor: _name, _symbol are for the ERC20. _initialSupply is minted to _initialRecipient.
    // _ownerOfERC20 is the address that will be set as the owner of this ERC20 contract (AetheriaNexus).
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_, address initialRecipient_, address ownerOfERC20_)
        ERC20(name_, symbol_)
        Ownable(ownerOfERC20_) // The AetheriaNexus contract becomes the owner of this ERC20 contract
    {
        _mint(initialRecipient_, initialSupply_); // Mints initial supply to the original twin owner
    }

    /**
     * @dev Burns `amount` tokens from `account`.
     * Only callable by the `owner` of this ERC20 contract (which is AetheriaNexus).
     * This allows AetheriaNexus to burn tokens from a user's balance for redemption.
     * @param account The address whose tokens are to be burned.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
```