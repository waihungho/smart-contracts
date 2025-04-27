Okay, here is a Solidity smart contract demonstrating a complex system for tokenized fractional real estate ownership, incorporating concepts like linking NFTs to fungible tokens, oracle integration for dynamic valuation/rent, development project funding, staking for yield boost, and role-based access control.

This contract, named `EtherealEstateNexus`, acts as a platform where real-world properties (represented by NFTs) can be fractionalized into fungible tokens (ERC-20). Investors can buy and sell these fractional tokens, earn rental income, potentially participate in property development funding rounds, and stake their tokens for boosted yield.

**Disclaimer:** This contract is a complex example for educational purposes. A real-world implementation would require significant security audits, more robust oracle integration (e.g., Chainlink), potentially a factory pattern for ERC-20 tokens, sophisticated on-chain trading mechanisms (like an AMM or order book), legal wrappers for RWA tokenization, and potentially upgradeability patterns (like Proxies). Gas costs for some operations (like distribution) could be high depending on implementation details and holder count.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // For potential downcasting if needed, although uint256 is preferred
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// --- Contract Outline ---
// 1. Inheritances: ERC721, AccessControl, Pausable, ReentrancyGuard
// 2. State Variables:
//    - Counters for Property & Development Project IDs
//    - Mappings for Property details (NFT ID -> Struct)
//    - Mapping for linking Property NFT ID to its Fractional ERC20 Address
//    - Mappings for Development Project details (Project ID -> Struct)
//    - Mapping for Oracle Address per Property
//    - Mapping for User's Claimable Rental Income per Property
//    - Mapping for User's Staked Fractional Tokens per Property
//    - Roles (Admin, Manager, Oracle)
// 3. Structs: Property, DevelopmentProject
// 4. Events: PropertyCreated, FractionalTokensRegistered, RentalIncomeRecorded, RentalIncomeDistributed, IncomeClaimed, DevelopmentProjectStarted, InvestmentMade, ProjectFinalized, TokensStaked, TokensUnstaked, OracleUpdated, Paused, Unpaused, EmergencyWithdrawal
// 5. Modifiers: Standard role/pause modifiers from inherited contracts
// 6. Constructor: Sets up initial roles (Admin)
// 7. Core Property Management:
//    - createProperty: Mints a new Property NFT, defines initial parameters.
//    - registerFractionalToken: Links a pre-deployed ERC20 address to a Property NFT.
//    - updatePropertyDetails: Allows managers to update non-critical property info.
//    - deactivateProperty: Marks a property as inactive (e.g., sold, under major renovation).
// 8. Fractional Token Management & Query:
//    - getFractionalTokenAddress: Returns the ERC20 address for a given Property NFT.
//    - getPropertyTokenId: Returns the Property NFT ID for a given fractional ERC20 address. (Requires mapping)
//    - getPropertyDetails: Returns details of a Property NFT.
// 9. Investment & Trading (Simplified - assumes external trading or internal basic exchange):
//    - buyFractionalTokensWithETH: Allows buying fractional tokens using ETH based on oracle price.
//    - sellFractionalTokensForETH: Allows selling fractional tokens for ETH based on oracle price.
// 10. Revenue Distribution:
//    - recordRentalIncome: Records income received for a property. Requires Oracle or Manager role.
//    - distributeRentalIncome: Triggers distribution calculation (or makes income available to claim).
//    - claimRentalIncome: Allows investors to claim their share of distributed income.
// 11. Staking:
//    - stakeFractionalTokens: Locks fractional tokens to potentially earn boosted yield (logic for boost is conceptual here).
//    - unstakeFractionalTokens: Unlocks staked fractional tokens.
//    - getStakedBalance: Returns the amount of fractional tokens staked by a user for a property.
// 12. Development Projects:
//    - startDevelopmentProject: Creates a new funding round for a property project.
//    - investInDevelopmentProject: Allows users to invest ETH in a project.
//    - finalizeDevelopmentProject: Distributes tokens/profits after a project finishes.
// 13. Oracle Integration:
//    - setPropertyOracle: Sets or updates the oracle address for a specific property.
//    - requestValuationUpdate (Conceptual): Represents calling an external oracle service.
//    - processValuationUpdate (Conceptual Callback): Represents receiving data from an oracle.
// 14. Access Control & Admin:
//    - grantManagerRole: Grants the manager role.
//    - revokeManagerRole: Revokes the manager role.
//    - grantOracleRole: Grants the oracle role (for trusted oracle addresses).
//    - revokeOracleRole: Revokes the oracle role.
//    - isAdmin, isManager, isOracle: View functions for role check.
// 15. Pausing: pause, unpause (from Pausable)
// 16. Emergency: emergencyWithdraw (Allows admin to pull funds in emergency)

// --- Function Summary ---
// - ERC721 Interface (Inherited): name(), symbol(), balanceOf(), ownerOf(), safeTransferFrom(), transferFrom(), approve(), setApprovalForAll(), getApproved(), isApprovedForAll()
// - AccessControl Interface (Inherited): hasRole(), getRoleAdmin(), grantRole(), revokeRole(), renounceRole()
// - Pausable Interface (Inherited): paused()
// - ReentrancyGuard Interface (Inherited): nonReentrant modifier
// - Counters.sol: Used internally for unique property and project IDs.
// - SafeERC20.sol: Used for safe interactions with ERC20 tokens.
// - SafeCast.sol: Used for explicit type casting if necessary.

// --- Custom Functions (28 total + inherited) ---
// 1. supportsInterface(bytes4 interfaceId): ERC165 standard for interface detection. (Inherited/Overridden)
// 2. createProperty(string calldata uri, uint256 totalShares, address fractionalTokenAddress): Mints a new Property NFT, sets initial parameters, and registers the associated fractional token contract. Requires ADMIN_ROLE.
// 3. registerFractionalToken(uint256 propertyId, address fractionalTokenAddress): Links a pre-deployed fractional ERC20 token contract to a Property NFT. Requires ADMIN_ROLE.
// 4. updatePropertyDetails(uint256 propertyId, string calldata uri): Updates the NFT URI for a property. Requires MANAGER_ROLE.
// 5. deactivateProperty(uint256 propertyId): Marks a property as inactive. Requires MANAGER_ROLE.
// 6. getFractionalTokenAddress(uint256 propertyId): Returns the address of the fractional ERC20 contract associated with a property. View function.
// 7. getPropertyTokenId(address fractionalTokenAddress): Returns the Property NFT ID associated with a fractional ERC20 address. View function.
// 8. getPropertyDetails(uint256 propertyId): Returns the details (URI, shares, state) of a property. View function.
// 9. setPropertyOracle(uint256 propertyId, address oracleAddress): Sets the trusted oracle address for a specific property's valuation/data. Requires ADMIN_ROLE.
// 10. buyFractionalTokensWithETH(uint256 propertyId): Allows users to send ETH to buy fractional tokens. Price determined by oracle data. Requires the property to have a registered oracle.
// 11. sellFractionalTokensForETH(uint256 propertyId, uint256 amount): Allows users to sell fractional tokens for ETH. Price determined by oracle data. Requires the property to have a registered oracle and the user to approve token transfer.
// 12. recordRentalIncome(uint256 propertyId, uint256 amount): Records incoming rental revenue for a property. Requires ORACLE_ROLE or MANAGER_ROLE.
// 13. distributeRentalIncome(uint256 propertyId): Calculates and makes available the recorded rental income for claiming by fractional token holders. Requires MANAGER_ROLE. (Simplified: Marks income as 'available', claiming done separately).
// 14. claimRentalIncome(uint256 propertyId): Allows a user to claim their share of available rental income for a property. Non-reentrant.
// 15. stakeFractionalTokens(uint256 propertyId, uint256 amount): Locks fractional tokens of a specific property to earn staking rewards/boosts. Requires user to approve token transfer. Non-reentrant.
// 16. unstakeFractionalTokens(uint256 propertyId, uint256 amount): Unlocks staked fractional tokens. Non-reentrant.
// 17. getStakedBalance(uint256 propertyId, address user): Returns the amount of fractional tokens staked by a user for a specific property. View function.
// 18. startDevelopmentProject(uint256 propertyId, uint256 fundingGoal, uint64 deadline, string calldata detailsUri): Initiates a development funding round for a property. Requires MANAGER_ROLE.
// 19. investInDevelopmentProject(uint256 projectId): Allows users to invest ETH into a development project.
// 20. finalizeDevelopmentProject(uint256 projectId): Finalizes a development project based on its state (funded/failed) and distributes outcomes (e.g., new tokens, refunds). Requires MANAGER_ROLE. Non-reentrant.
// 21. getDevelopmentProjectDetails(uint256 projectId): Returns the details of a development project. View function.
// 22. getTotalClaimableIncome(uint256 propertyId): Calculates the total claimable income accumulated for a property. View function.
// 23. getUserClaimableIncome(uint256 propertyId, address user): Calculates the claimable income for a specific user for a property. View function.
// 24. grantManagerRole(address account): Grants the MANAGER_ROLE. Requires ADMIN_ROLE.
// 25. revokeManagerRole(address account): Revokes the MANAGER_ROLE. Requires ADMIN_ROLE.
// 26. grantOracleRole(address account): Grants the ORACLE_ROLE. Requires ADMIN_ROLE.
// 27. revokeOracleRole(address account): Revokes the ORACLE_ROLE. Requires ADMIN_ROLE.
// 28. emergencyWithdraw(address tokenAddress, uint256 amount): Allows ADMIN_ROLE to withdraw funds in case of emergency (e.g., trapped tokens). Requires PAUSED state.

contract EtherealEstateNexus is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For trusted oracle addresses

    // --- Counters ---
    Counters.Counter private _propertyIds;
    Counters.Counter private _developmentProjectIds;

    // --- Structs ---
    enum PropertyState { Active, Inactive, UnderDevelopment }
    struct Property {
        uint256 id;
        address owner; // Owner of the NFT (likely the platform or a DAO in a real system)
        string uri; // Metadata URI for the property (e.g., IPFS link)
        uint256 totalShares; // Total supply of fractional tokens for this property
        address fractionalTokenAddress; // Address of the corresponding ERC20 token
        uint256 totalRentalIncomeRecorded; // Total income recorded for this property
        uint256 totalRentalIncomeClaimed; // Total income claimed across all holders
        PropertyState state;
    }

    enum ProjectState { Funding, Active, Finalized_Success, Finalized_Failed }
    struct DevelopmentProject {
        uint256 id;
        uint256 propertyId; // Property NFT ID the project is related to
        string detailsUri; // Metadata URI for the project details
        uint256 fundingGoal; // ETH required for the project
        uint256 amountRaised; // ETH raised so far
        uint64 deadline; // Timestamp when funding ends
        ProjectState state;
        // Future fields could include: result tokens/shares, distribution logic
    }

    // --- State Variables ---
    mapping(uint256 => Property) public properties;
    mapping(address => uint256) private _fractionalTokenToPropertyId; // Map fractional token address to property NFT ID
    mapping(uint256 => address) private _propertyIdToFractionalToken; // Map property NFT ID to fractional token address

    mapping(uint256 => DevelopmentProject) public developmentProjects;

    mapping(uint256 => address) private _propertyOracles; // Mapping from property ID to trusted oracle address

    // State to track claimable rental income per user per property
    // This is simplified: actual distribution requires tracking income per share over time.
    // A more advanced system would use snapshots or complex accounting.
    // This version assumes income is recorded and then made 'available' proportionally.
    mapping(uint256 => uint256) private _propertyAvailableIncome; // Income available to be claimed for a property
    mapping(uint256 => mapping(address => uint256)) private _userClaimedIncome; // Income already claimed by a user for a property

    // State to track staked fractional tokens per user per property
    mapping(uint256 => mapping(address => uint256)) private _stakedBalances;

    // --- Events ---
    event PropertyCreated(uint256 indexed propertyId, address indexed owner, string uri, uint256 totalShares);
    event FractionalTokensRegistered(uint256 indexed propertyId, address indexed fractionalTokenAddress);
    event PropertyDetailsUpdated(uint256 indexed propertyId, string uri);
    event PropertyStateChanged(uint256 indexed propertyId, PropertyState newState);
    event PropertyOracleUpdated(uint256 indexed propertyId, address indexed oracleAddress);

    event RentalIncomeRecorded(uint256 indexed propertyId, uint256 amount, address indexed recorder);
    event RentalIncomeDistributed(uint256 indexed propertyId, uint256 distributedAmount);
    event IncomeClaimed(uint256 indexed propertyId, address indexed user, uint256 amount);

    event TokensStaked(uint256 indexed propertyId, address indexed user, uint256 amount);
    event TokensUnstaked(uint256 indexed propertyId, address indexed user, uint256 amount);

    event DevelopmentProjectStarted(uint256 indexed projectId, uint256 indexed propertyId, uint256 fundingGoal, uint64 deadline);
    event InvestmentMade(uint256 indexed projectId, address indexed investor, uint256 amount);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectFinalized(uint256 indexed projectId, ProjectState finalState); // FinalState is likely Finalized_Success or Finalized_Failed

    event EmergencyWithdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor() ERC721("EtherealEstateProperty", "EEP") Pausable() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant deployer the default admin role
        _grantRole(ADMIN_ROLE, msg.sender);       // Grant deployer the custom admin role
        // In a real system, ADMIN_ROLE might be transferred to a multisig or DAO
    }

    // --- Access Control & Roles ---
    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isManager(address account) public view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    function isOracle(address account) public view returns (bool) {
        return hasRole(ORACLE_ROLE, account);
    }

    function grantManagerRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(MANAGER_ROLE, account);
    }

    function revokeManagerRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(MANAGER_ROLE, account);
    }

    function grantOracleRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, account);
    }

    function revokeOracleRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(ORACLE_ROLE, account);
    }

    // Required override for AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Helpers ---
    function _getFractionalTokenContract(uint256 propertyId) internal view returns (IERC20) {
        address tokenAddress = _propertyIdToFractionalToken[propertyId];
        require(tokenAddress != address(0), "Fractional token not registered for property");
        return IERC20(tokenAddress);
    }

    // --- Core Property Management (7 functions) ---

    /// @notice Creates a new Property NFT and records initial details.
    /// @param uri The metadata URI for the property.
    /// @param totalShares The total number of fractional shares this property will have.
    /// @param fractionalTokenAddress The address of the pre-deployed ERC20 contract for these shares.
    /// @return The ID of the newly created property.
    function createProperty(
        string calldata uri,
        uint256 totalShares,
        address fractionalTokenAddress
    ) external onlyRole(ADMIN_ROLE) whenNotPaused returns (uint256) {
        _propertyIds.increment();
        uint256 newPropertyId = _propertyIds.current();

        // Mint the Property NFT to this contract or a trusted owner
        // Minting to msg.sender or a platform owner might be more appropriate
        // For simplicity, let's mint to the contract address itself initially,
        // or a designated platform wallet. Let's mint to msg.sender.
        _safeMint(msg.sender, newPropertyId); // Owner of the NFT can be platform admin

        properties[newPropertyId] = Property({
            id: newPropertyId,
            owner: msg.sender, // Owner of the NFT
            uri: uri,
            totalShares: totalShares,
            fractionalTokenAddress: fractionalTokenAddress,
            totalRentalIncomeRecorded: 0,
            totalRentalIncomeClaimed: 0,
            state: PropertyState.Active
        });

        // Register the fractional token address link
        require(fractionalTokenAddress != address(0), "Invalid fractional token address");
        require(_fractionalTokenToPropertyId[fractionalTokenAddress] == 0, "Fractional token already registered");

        _fractionalTokenToPropertyId[fractionalTokenAddress] = newPropertyId;
        _propertyIdToFractionalToken[newPropertyId] = fractionalTokenAddress;

        emit PropertyCreated(newPropertyId, msg.sender, uri, totalShares);
        emit FractionalTokensRegistered(newPropertyId, fractionalTokenAddress);

        return newPropertyId;
    }

    /// @notice Links a pre-deployed fractional ERC20 token contract to an existing Property NFT.
    ///         Only needed if the token wasn't registered during creation.
    /// @param propertyId The ID of the property NFT.
    /// @param fractionalTokenAddress The address of the pre-deployed ERC20 contract.
    function registerFractionalToken(uint256 propertyId, address fractionalTokenAddress)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress == address(0), "Fractional token already registered for property");
        require(fractionalTokenAddress != address(0), "Invalid fractional token address");
        require(_fractionalTokenToPropertyId[fractionalTokenAddress] == 0, "Fractional token already registered");

        property.fractionalTokenAddress = fractionalTokenAddress;
        _fractionalTokenToPropertyId[fractionalTokenAddress] = propertyId;
        _propertyIdToFractionalToken[propertyId] = fractionalTokenAddress;

        emit FractionalTokensRegistered(propertyId, fractionalTokenAddress);
    }


    /// @notice Updates the metadata URI for a property.
    /// @param propertyId The ID of the property.
    /// @param uri The new metadata URI.
    function updatePropertyDetails(uint256 propertyId, string calldata uri)
        external
        onlyRole(MANAGER_ROLE)
        whenNotPaused
    {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        // Add potential checks like requiring property.state == Active etc.
        property.uri = uri;
        _setTokenURI(propertyId, uri); // Update the NFT URI
        emit PropertyDetailsUpdated(propertyId, uri);
    }

    /// @notice Marks a property as inactive (e.g., preparing for sale, long-term renovation).
    /// @param propertyId The ID of the property.
    function deactivateProperty(uint256 propertyId)
        external
        onlyRole(MANAGER_ROLE)
        whenNotPaused
    {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.state == PropertyState.Active, "Property is not active");
        property.state = PropertyState.Inactive;
        emit PropertyStateChanged(propertyId, PropertyState.Inactive);
    }

    /// @notice Returns the address of the fractional ERC20 contract for a property.
    /// @param propertyId The ID of the property.
    /// @return The address of the fractional token contract.
    function getFractionalTokenAddress(uint256 propertyId) public view returns (address) {
        return _propertyIdToFractionalToken[propertyId];
    }

     /// @notice Returns the Property NFT ID for a given fractional ERC20 token address.
     /// @param fractionalTokenAddress The address of the fractional ERC20 token contract.
     /// @return The ID of the associated property NFT.
    function getPropertyTokenId(address fractionalTokenAddress) public view returns (uint256) {
        return _fractionalTokenToPropertyId[fractionalTokenAddress];
    }

    /// @notice Returns details of a property.
    /// @param propertyId The ID of the property.
    /// @return id The property ID.
    /// @return owner The NFT owner address.
    /// @return uri The metadata URI.
    /// @return totalShares The total supply of fractional tokens.
    /// @return fractionalTokenAddress The address of the fractional token contract.
    /// @return totalRentalIncomeRecorded Total income recorded.
    /// @return totalRentalIncomeClaimed Total income claimed.
    /// @return state The current state of the property.
    function getPropertyDetails(uint256 propertyId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory uri,
            uint256 totalShares,
            address fractionalTokenAddress,
            uint256 totalRentalIncomeRecorded,
            uint256 totalRentalIncomeClaimed,
            PropertyState state
        )
    {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        return (
            property.id,
            property.owner,
            property.uri,
            property.totalShares,
            property.fractionalTokenAddress,
            property.totalRentalIncomeRecorded,
            property.totalRentalIncomeClaimed,
            property.state
        );
    }

    // --- Oracle Integration & Dynamic Value/Trading (3 functions) ---

    /// @notice Sets the trusted oracle address for a specific property.
    ///         This oracle is responsible for providing data like market value or rental income.
    /// @param propertyId The ID of the property.
    /// @param oracleAddress The address of the trusted oracle contract/entity.
    function setPropertyOracle(uint256 propertyId, address oracleAddress)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        require(properties[propertyId].id != 0, "Property does not exist");
        require(oracleAddress != address(0), "Invalid oracle address");
        // In a real system, you'd likely check if the oracleAddress has the ORACLE_ROLE or is a registered oracle contract
        _propertyOracles[propertyId] = oracleAddress;
        emit PropertyOracleUpdated(propertyId, oracleAddress);
    }

    /// @notice Allows buying fractional tokens using ETH based on the property's current oracle valuation.
    ///         Assumes oracle provides ETH/Share price or total ETH value.
    ///         This is a simplified model. Real trading would use AMMs or order books.
    /// @param propertyId The ID of the property.
    function buyFractionalTokensWithETH(uint256 propertyId) external payable whenNotPaused nonReentrant {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.state == PropertyState.Active, "Property is not active for trading");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");
        require(_propertyOracles[propertyId] != address(0), "Oracle not set for property");

        // --- CONCEPTUAL ORACLE CALL ---
        // In a real contract, this would be a call to a trusted oracle contract:
        // uint256 sharesPerEth = OracleContract(_propertyOracles[propertyId]).getSharesPerEth(propertyId);
        // uint256 purchaseAmount = msg.value * sharesPerEth;

        // --- SIMULATION (Replace with actual oracle integration) ---
        // Simulate oracle returning a fixed price for demonstration
        // Example: 1 ETH buys 100 shares (replace with dynamic logic)
        uint256 simulatedSharesPerEth = 100 * 1e18; // Assume ERC20 has 18 decimals
        require(msg.value > 0, "Must send ETH");
        uint256 purchaseAmount = (msg.value * simulatedSharesPerEth) / 1e18; // Adjust for actual ETH value

        // Ensure the contract has enough shares to sell (e.g., from initial mint or buybacks)
        // This simplified version assumes tokens are minted on demand or held by the contract
        // For demonstration, let's assume tokens are held by the contract address (e.g., minted initially to it)
        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        require(fractionalToken.balanceOf(address(this)) >= purchaseAmount, "Not enough tokens in reserve");

        fractionalToken.safeTransfer(msg.sender, purchaseAmount);

        // ETH sent to the contract's balance
        // A real system might send ETH to a liquidity pool or a reserve managed elsewhere

        // Event for trading could be added here
    }

     /// @notice Allows selling fractional tokens for ETH based on the property's current oracle valuation.
     ///         Assumes oracle provides ETH/Share price.
     ///         Requires user to approve tokens for transfer to this contract first.
     /// @param propertyId The ID of the property.
     /// @param amount The amount of fractional tokens to sell.
    function sellFractionalTokensForETH(uint256 propertyId, uint256 amount) external whenNotPaused nonReentrant {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.state == PropertyState.Active, "Property is not active for trading");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");
        require(_propertyOracles[propertyId] != address(0), "Oracle not set for property");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        require(fractionalToken.allowance(msg.sender, address(this)) >= amount, "Token allowance not set");
        require(fractionalToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // --- CONCEPTUAL ORACLE CALL ---
        // uint256 ethPerShare = OracleContract(_propertyOracles[propertyId]).getEthPerShare(propertyId);
        // uint256 refundAmount = amount * ethPerShare / 1e18; // Adjust for decimals

        // --- SIMULATION (Replace with actual oracle integration) ---
        // Simulate oracle returning a fixed price for demonstration
        // Example: 100 shares sell for 1 ETH (replace with dynamic logic)
        uint256 simulatedEthPerShare = 1e18 / 100; // Assume ERC20 has 18 decimals
        uint256 refundAmount = (amount * simulatedEthPerShare) / 1e18; // Adjust for actual share amount

        require(address(this).balance >= refundAmount, "Not enough ETH in contract reserve");

        // Transfer tokens from user to contract
        fractionalToken.safeTransferFrom(msg.sender, address(this), amount);

        // Transfer ETH to user
        payable(msg.sender).transfer(refundAmount);

        // Event for trading could be added here
    }


    // --- Revenue Distribution (3 functions) ---

    /// @notice Records incoming rental or other revenue for a property.
    ///         ETH is sent to the contract address.
    /// @param propertyId The ID of the property.
    /// @param amount The amount of ETH received.
    function recordRentalIncome(uint256 propertyId, uint256 amount)
        external
        payable // Must send ETH with this call
        onlyRole(ORACLE_ROLE) // Or MANAGER_ROLE, depending on trust model
        whenNotPaused
        nonReentrant
    {
        require(properties[propertyId].id != 0, "Property does not exist");
        require(properties[propertyId].state == PropertyState.Active, "Property is not active");
        require(msg.value == amount, "Sent amount must match specified amount");
        require(amount > 0, "Amount must be greater than zero");

        Property storage property = properties[propertyId];
        property.totalRentalIncomeRecorded += amount;
        // Note: ETH is now in the contract balance. Distribution happens separately.
        emit RentalIncomeRecorded(propertyId, amount, msg.sender);
    }

    /// @notice Makes recorded rental income available for fractional token holders to claim.
    ///         This function essentially marks income as 'distributed' internally.
    /// @param propertyId The ID of the property.
    function distributeRentalIncome(uint256 propertyId)
        external
        onlyRole(MANAGER_ROLE)
        whenNotPaused
    {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");
        // Only distribute income that hasn't been made available yet
        uint256 newIncomeToDistribute = property.totalRentalIncomeRecorded - property.totalRentalIncomeClaimed - _propertyAvailableIncome[propertyId];

        if (newIncomeToDistribute > 0) {
             _propertyAvailableIncome[propertyId] += newIncomeToDistribute;
            emit RentalIncomeDistributed(propertyId, newIncomeToDistribute);
        }
        // Note: This is a simplified push model (income becomes available to pull).
        // A true "distribute" would involve complex gas-intensive token payouts or snapshotting.
        // The 'claim' function handles the actual ETH transfer.
    }


    /// @notice Allows a user to claim their share of available rental income for a property.
    /// @param propertyId The ID of the property.
    function claimRentalIncome(uint256 propertyId) external whenNotPaused nonReentrant {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");

        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        uint256 userBalance = fractionalToken.balanceOf(msg.sender);
        uint256 totalShares = property.totalShares;

        if (userBalance == 0 || totalShares == 0 || _propertyAvailableIncome[propertyId] == 0) {
            // No shares, no total shares, or no income available
            return;
        }

        // Calculate total income available to claim since the user last claimed
        // This requires tracking user's share *at the time of each distribution*.
        // SIMPLIFICATION: Calculate based on user's *current* balance against *all* available income.
        // This is prone to issues if users buy/sell shares between record/distribute and claim.
        // A robust system needs per-distribution accounting or snapshots.
        uint256 totalIncomeAvailable = _propertyAvailableIncome[propertyId];
        uint256 userAlreadyClaimed = _userClaimedIncome[propertyId][msg.sender];

        // Calculate theoretical total income this user is entitled to based on their CURRENT shares
        // This is a rough model! A better model would calculate entitlement at the time of distribution events.
        uint256 userTheoreticalTotalEntitlement = (userBalance * totalIncomeAvailable) / totalShares;

        // Calculate amount to claim now (total entitlement minus what's already claimed)
        uint256 amountToClaim = userTheoreticalTotalEntitlement - userAlreadyClaimed;

        require(amountToClaim > 0, "No claimable income");

        // Transfer ETH to the user
        require(address(this).balance >= amountToClaim, "Insufficient contract balance for claim");
        payable(msg.sender).transfer(amountToClaim);

        // Update claimed amount for the user and globally for the property
        _userClaimedIncome[propertyId][msg.sender] += amountToClaim;
        property.totalRentalIncomeClaimed += amountToClaim; // Global claimed counter

        emit IncomeClaimed(propertyId, msg.sender, amountToClaim);
    }

    // --- Staking (3 functions) ---

    /// @notice Locks fractional tokens to participate in staking, potentially for boosted yield.
    ///         The yield boost logic is conceptual and needs to be implemented in distribution or elsewhere.
    /// @param propertyId The ID of the property whose tokens are being staked.
    /// @param amount The amount of fractional tokens to stake.
    function stakeFractionalTokens(uint256 propertyId, uint256 amount) external whenNotPaused nonReentrant {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        require(fractionalToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(fractionalToken.allowance(msg.sender, address(this)) >= amount, "Allowance not set");

        // Transfer tokens from user to this contract
        fractionalToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update staked balance
        _stakedBalances[propertyId][msg.sender] += amount;

        emit TokensStaked(propertyId, msg.sender, amount);

        // Note: Logic for calculating and applying staking yield boost needs to be added
        // This could be done by giving staked balances a higher "weight" during income distribution
        // or by distributing separate reward tokens.
    }

    /// @notice Unlocks previously staked fractional tokens.
    /// @param propertyId The ID of the property whose tokens are staked.
    /// @param amount The amount of staked tokens to unlock.
    function unstakeFractionalTokens(uint256 propertyId, uint256 amount) external whenNotPaused nonReentrant {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");
        require(amount > 0, "Amount must be greater than zero");
        require(_stakedBalances[propertyId][msg.sender] >= amount, "Insufficient staked balance");

        // Update staked balance
        _stakedBalances[propertyId][msg.sender] -= amount;

        // Transfer tokens back to user from this contract
        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        fractionalToken.safeTransfer(msg.sender, amount);

        emit TokensUnstaked(propertyId, msg.sender, amount);
    }

    /// @notice Returns the amount of fractional tokens staked by a user for a specific property.
    /// @param propertyId The ID of the property.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getStakedBalance(uint256 propertyId, address user) public view returns (uint256) {
        return _stakedBalances[propertyId][user];
    }

    // --- Development Projects (4 functions) ---

    /// @notice Initiates a funding round for a development project related to a property.
    /// @param propertyId The ID of the property.
    /// @param fundingGoal The ETH funding goal.
    /// @param deadline The timestamp by which funding must be met.
    /// @param detailsUri Metadata URI for project details.
    /// @return The ID of the new development project.
    function startDevelopmentProject(
        uint256 propertyId,
        uint256 fundingGoal,
        uint64 deadline,
        string calldata detailsUri
    ) external onlyRole(MANAGER_ROLE) whenNotPaused returns (uint256) {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.state == PropertyState.Active, "Property is not active"); // Or allow funding inactive? Design decision.
        require(fundingGoal > 0, "Funding goal must be greater than zero");
        require(deadline > block.timestamp, "Deadline must be in the future");

        _developmentProjectIds.increment();
        uint256 newProjectId = _developmentProjectIds.current();

        developmentProjects[newProjectId] = DevelopmentProject({
            id: newProjectId,
            propertyId: propertyId,
            detailsUri: detailsUri,
            fundingGoal: fundingGoal,
            amountRaised: 0,
            deadline: deadline,
            state: ProjectState.Funding
        });

        // Optional: Change property state to UnderDevelopment during funding
        // property.state = PropertyState.UnderDevelopment; // Could be added here or on success

        emit DevelopmentProjectStarted(newProjectId, propertyId, fundingGoal, deadline);
        // emit PropertyStateChanged(propertyId, PropertyState.UnderDevelopment); // If state changes

        return newProjectId;
    }

    /// @notice Allows users to invest ETH into an ongoing development project funding round.
    /// @param projectId The ID of the development project.
    function investInDevelopmentProject(uint256 projectId) external payable whenNotPaused nonReentrant {
        DevelopmentProject storage project = developmentProjects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.state == ProjectState.Funding, "Project is not in funding state");
        require(block.timestamp < project.deadline, "Funding deadline passed");
        require(msg.value > 0, "Must send ETH to invest");

        project.amountRaised += msg.value;

        emit InvestmentMade(projectId, msg.sender, msg.value);

        // Check if goal is met exactly here to potentially transition state early
        // if (project.amountRaised >= project.fundingGoal) {
        //     project.state = ProjectState.Active; // Or straight to Finalized_Success, depending on flow
        //     emit ProjectStateChanged(projectId, ProjectState.Active);
        // }
    }

    /// @notice Finalizes a development project after its deadline.
    ///         Handles distribution of raised funds (refund or use) and potential outcomes.
    ///         Refund logic is simplified - a real system needs to track individual investor contributions.
    /// @param projectId The ID of the development project.
    function finalizeDevelopmentProject(uint256 projectId) external onlyRole(MANAGER_ROLE) whenNotPaused nonReentrant {
        DevelopmentProject storage project = developmentProjects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.state == ProjectState.Funding || project.state == ProjectState.Active, "Project is not active or funding");
        require(block.timestamp >= project.deadline || project.amountRaised >= project.fundingGoal, "Funding period not ended or goal not met");

        Property storage property = properties[project.propertyId];

        if (project.amountRaised >= project.fundingGoal) {
            // Project funded successfully
            project.state = ProjectState.Finalized_Success;

            // --- SUCCESS LOGIC ---
            // Here you would implement what happens on success:
            // - Potentially mint new fractional tokens for investors?
            // - Potentially distribute a share of future profits?
            // - The raised ETH (project.amountRaised) remains in the contract.
            //   It should be used for the development work, managed by the platform/managers.
            //   A real system needs a way to disburse these funds securely.
            //   For this example, we'll leave it in the contract, requiring emergencyWithdraw by admin if needed.

             if (property.state == PropertyState.UnderDevelopment) {
                property.state = PropertyState.Active; // Move back to active state if it was set to UnderDevelopment
             }

        } else {
            // Project failed to meet funding goal
            project.state = ProjectState.Finalized_Failed;

            // --- FAILURE LOGIC ---
            // Refund investors. This requires tracking individual investments.
            // SIMPLIFICATION: A real contract needs a mapping of projectId -> investor -> amount.
            // This simplified version cannot refund correctly without that tracking.
            // In this dummy implementation, the ETH raised will just stay in the contract
            // unless the admin uses emergencyWithdraw, which is NOT a proper refund.
            // A proper implementation MUST iterate through investors and transfer ETH back.
            // Example (conceptual):
            // for investor in investors[projectId]:
            //     payable(investor).transfer(investments[projectId][investor]);
            //     investments[projectId][investor] = 0;
            // project.amountRaised = 0; // Set to zero after refunding

             if (property.state == PropertyState.UnderDevelopment) {
                property.state = PropertyState.Active; // Move back to active state if it was set to UnderDevelopment
             }
        }

        emit ProjectStateChanged(projectId, project.state);
        emit ProjectFinalized(projectId, project.state);
        // emit PropertyStateChanged(property.id, property.state); // If property state changed
    }

    /// @notice Returns the details of a development project.
    /// @param projectId The ID of the project.
    /// @return id The project ID.
    /// @return propertyId The associated property ID.
    /// @return detailsUri The project details URI.
    /// @return fundingGoal The ETH funding goal.
    /// @return amountRaised The ETH raised.
    /// @return deadline The funding deadline.
    /// @return state The current state of the project.
    function getDevelopmentProjectDetails(uint256 projectId)
        public
        view
        returns (
            uint256 id,
            uint256 propertyId,
            string memory detailsUri,
            uint256 fundingGoal,
            uint256 amountRaised,
            uint64 deadline,
            ProjectState state
        )
    {
        DevelopmentProject storage project = developmentProjects[projectId];
        require(project.id != 0, "Project does not exist");
        return (
            project.id,
            project.propertyId,
            project.detailsUri,
            project.fundingGoal,
            project.amountRaised,
            project.deadline,
            project.state
        );
    }

    // --- Query Functions (3 functions) ---

    /// @notice Gets the total accumulated income available for claiming for a property.
    /// @param propertyId The ID of the property.
    /// @return The total available income in wei.
    function getTotalClaimableIncome(uint256 propertyId) public view returns (uint256) {
         require(properties[propertyId].id != 0, "Property does not exist");
        return _propertyAvailableIncome[propertyId];
    }

    /// @notice Calculates the amount of rental income a specific user can claim for a property.
    ///         Based on their current fractional token balance relative to total shares, minus what they've already claimed.
    ///         NOTE: This calculation is simplified and may not be perfectly accurate if tokens are traded frequently.
    /// @param propertyId The ID of the property.
    /// @param user The address of the user.
    /// @return The claimable income in wei.
    function getUserClaimableIncome(uint256 propertyId, address user) public view returns (uint256) {
        Property storage property = properties[propertyId];
        require(property.id != 0, "Property does not exist");
        require(property.fractionalTokenAddress != address(0), "Fractional token not registered");

        IERC20 fractionalToken = _getFractionalTokenContract(propertyId);
        uint256 userBalance = fractionalToken.balanceOf(user);
        uint256 totalShares = property.totalShares;
        uint256 totalIncomeAvailable = _propertyAvailableIncome[propertyId];
        uint256 userAlreadyClaimed = _userClaimedIncome[propertyId][user];

        if (userBalance == 0 || totalShares == 0 || totalIncomeAvailable == 0) {
            return 0;
        }

        // Calculate theoretical total entitlement based on current share
        uint256 userTheoreticalTotalEntitlement = (userBalance * totalIncomeAvailable) / totalShares;

        // Amount to claim is entitlement minus already claimed
        return userTheoreticalTotalEntitlement > userAlreadyClaimed ? userTheoreticalTotalEntitlement - userAlreadyClaimed : 0;
    }


    // --- Pausing & Emergency (3 functions) ---

    /// @notice Pauses the contract, preventing most operations.
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract, allowing operations again.
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Allows the admin to withdraw trapped tokens or ETH from the contract in an emergency.
    ///         Only possible when the contract is paused.
    /// @param tokenAddress The address of the token to withdraw (address(0) for ETH).
    /// @param amount The amount to withdraw.
    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyRole(ADMIN_ROLE) whenPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        if (tokenAddress == address(0)) {
            // Withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH balance");
            payable(msg.sender).transfer(amount);
        } else {
            // Withdraw ERC20 token
            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
            token.safeTransfer(msg.sender, amount);
        }

        emit EmergencyWithdrawal(tokenAddress, msg.sender, amount);
    }

    // --- Internal Override for ERC721 URI ---
    function _baseURI() internal view override returns (string memory) {
        // Base URI is handled per-token via the struct
        // You might return a default base URI here if needed
        return "";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721: URI query for nonexistent token");
         return properties[tokenId].uri;
    }

    // Optional: Implement tokenById to get NFT ID from fractional token (already have getPropertyTokenId)
    // Optional: Implement staking yield distribution logic
    // Optional: Implement individual investor tracking for project refunds
}
```